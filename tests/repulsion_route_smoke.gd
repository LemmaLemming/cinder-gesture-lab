extends SceneTree
## Real AshEnemy box plus a distinct capsule, motion helper only. These tests
## suspend the test source controller; no attack/field/spore consumer is built.
const Route = preload("res://scripts/combat/repulsion_route.gd")
const Enemy = preload("res://scripts/enemy.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for kind: String in ["box", "capsule"]:
		await _test_wall(kind)
		await _test_ground_failures(kind)
		await _test_lease_guards(kind)
	await _test_open_route()
	print("Repulsion route smoke: %d checks, %d failures (motion helper only)" % [checks, failures])
	quit(1 if failures else 0)


func _test_wall(kind: String) -> void:
	var arena: Dictionary = _world(kind)
	await physics_frame
	var source: CharacterBody3D = arena.source
	source.velocity = Vector3.LEFT * 1.75
	var original_shape: Shape3D = (source.get_node("BodyCollision") as CollisionShape3D).shape
	var original_velocity: Vector3 = source.velocity
	var route = Route.new()
	var planned: Dictionary = route.plan(source, _motion(), arena.bindings)
	_expect(not planned.has("error"), kind + " moving supported source preflights its actual collider: " + String(planned.get("error", "")))
	if planned.has("error"):
		await _dispose(arena)
		return
	_expect(source.global_position == Vector3(-3, 0.002, 0) and source.velocity == original_velocity and (source.get_node("BodyCollision") as CollisionShape3D).shape == original_shape, kind + " pure preflight leaves position/approach velocity and original collider unchanged")
	var measured: bool = is_equal_approx(float(planned.body_signature.shape.radius), 0.27) if kind == "capsule" else Vector3(planned.body_signature.shape.size[0], planned.body_signature.shape.size[1], planned.body_signature.shape.size[2]).is_equal_approx(Vector3(0.75, 1.45, 0.65))
	_expect(planned.body_signature.shape.type == ("BoxShape3D" if kind == "box" else "CapsuleShape3D") and measured, kind + " source dimensions are measured rather than replaced with hero capsule")
	var measured_radius: float = Vector2(0.75, 0.65).length() * 0.5 if kind == "box" else 0.27
	_expect(is_equal_approx(float(planned.support_radius), measured_radius + Route.FLOOR_SKIN), kind + " floor proof conservatively contains the measured footprint")
	var half_width: float = 0.375 if kind == "box" else 0.27
	var physical_contact: float = -0.6 - half_width
	_expect(planned.collision_shortened and absf(float(planned.planned_endpoint.x) - physical_contact) < 0.006 and planned.planned_endpoint.y == source.global_position.y, kind + " real thin wall shortens the route with its actual width/radius")
	var tampered: Dictionary = planned.duplicate(true)
	tampered.body_signature.shape.type = "FakeShape"
	tampered.distance = 999.0
	_expect(route.state().body_signature.shape.type != "FakeShape" and route.state().distance < 999.0, kind + " returned route cannot mutate the helper's private committed data")
	_expect(route.advance(source, 0.1).has("error") and source.velocity == original_velocity, kind + " unacquired route cannot stop or move approach velocity")
	_expect(route.acquire(source) and source.velocity == Vector3.ZERO and source.global_position == planned.start, kind + " explicit external controller barrier acquires lease only after full revalidation")
	_expect(not route.acquire(source) and route.plan(source, _motion(), arena.bindings).has("error"), kind + " active lease rejects duplicate acquisition and route replacement")
	paused = true
	_expect(route.advance(source, 0.2).has("error") and source.global_position == planned.start and source.velocity == Vector3.ZERO, kind + " paused tree cannot advance retreat from wall-clock time")
	paused = false
	var state: Dictionary = {}
	for tick: int in range(1, 50):
		await physics_frame
		state = route.advance(source, float(tick) / 60.0)
		if state.has("error") or state.finished:
			break
	_expect(not state.has("error") and state.get("finished", false) and state.get("actual_collided", false), kind + " bounded real move_and_collide reports shortening contact: " + String(state.get("error", "")))
	_expect(source.global_position.distance_to(planned.planned_endpoint) <= Route.ENDPOINT_TOLERANCE and source.velocity == Vector3.ZERO, kind + " actual supported wall endpoint matches the preflight and stops deliberately")
	var stopped: Vector3 = source.global_position
	_expect(not route.advance(source, 2.0).has("error") and source.global_position == stopped, kind + " finished route cannot drift during later ticks")
	if kind == "box":
		_expect(source is AshEnemy and (source as AshEnemy).hp == 32.0 and not (source as AshEnemy).dead, "actual AshEnemy retained HP and alive state throughout retreat")
	_expect(route.release(source) and not route.state().leased, kind + " explicit cleanup releases owned zero velocity")
	await _dispose(arena)


func _test_ground_failures(kind: String) -> void:
	var arena: Dictionary = _world(kind, true)
	await physics_frame
	var source: CharacterBody3D = arena.source
	var route = Route.new()
	var spec: Dictionary = _motion()
	spec.distance = 6.0
	var start: Vector3 = source.global_position
	_expect(route.plan(source, spec, arena.bindings).has("error") and source.global_position == start, kind + " analytic full-route footprint rejects a middle floor hole despite supported endpoints")
	arena.root.free()
	await process_frame
	arena = _world(kind)
	await physics_frame
	source = arena.source
	for axis: String in ["axis_lock_linear_x", "axis_lock_linear_y", "axis_lock_linear_z", "axis_lock_angular_x", "axis_lock_angular_y", "axis_lock_angular_z"]:
		source.set(axis, true)
		_expect(route.plan(source, _motion(), arena.bindings).has("error"), kind + " refuses " + axis + " before any physical motion")
		source.set(axis, false)
	source.position.y = -0.01
	_expect(route.plan(source, _motion(), arena.bindings).has("error") and source.position == Vector3(-3, -0.01, 0), kind + " initial floor depenetration rejects without lifting the body")
	source.position = Vector3(-3, 0.002, 0)
	arena.wall.position.x = -3
	await physics_frame
	_expect(route.plan(source, _motion(), arena.bindings).has("error") and source.position == Vector3(-3, 0.002, 0), kind + " overlapped actual wall rejects without recovery movement")
	arena.wall.position.x = -0.5
	source.rotation.y = 0.1
	_expect(route.plan(source, _motion(), arena.bindings).has("error"), kind + " rotated source cannot masquerade as an upright measured footprint")
	source.rotation = Vector3.ZERO
	source.scale = Vector3(1.1, 1, 1)
	_expect(route.plan(source, _motion(), arena.bindings).has("error"), kind + " source scale changes are unsupported")
	source.scale = Vector3.ONE
	source.velocity = Vector3.UP
	_expect(route.plan(source, _motion(), arena.bindings).has("error"), kind + " airborne vertical motion cannot claim a grounded retreat")
	source.velocity = Vector3.ZERO
	var unsupported: Dictionary = _motion()
	unsupported.direction = Vector3.RIGHT * 2
	_expect(route.plan(source, unsupported, arena.bindings).has("error"), kind + " rejects nonnormalized direction")
	unsupported = _motion()
	unsupported.distance = Route.MAX_DISTANCE + 1
	_expect(route.plan(source, unsupported, arena.bindings).has("error"), kind + " rejects unbounded route distance")
	unsupported = _motion()
	unsupported.speed = Route.MAX_SPEED + 1
	_expect(route.plan(source, unsupported, arena.bindings).has("error"), kind + " rejects unbounded route speed")
	_expect(route.plan(source, _motion(), {"world_root": arena.root, "floors": {}}).has("error"), kind + " cannot infer authored floor support from a decorative world")
	await _dispose(arena)


func _test_lease_guards(kind: String) -> void:
	var arena: Dictionary = _world(kind)
	await physics_frame
	var source: CharacterBody3D = arena.source
	var route = Route.new()
	var planned: Dictionary = route.plan(source, _motion(), arena.bindings)
	if planned.has("error"):
		_expect(false, kind + " guard fixture preflight: " + String(planned.error))
		await _dispose(arena)
		return
	arena.wall.position.x = 3.0
	var start: Vector3 = source.global_position
	source.velocity = Vector3.LEFT
	_expect(not route.acquire(source) and source.global_position == start and source.velocity == Vector3.LEFT, kind + " changed shortening wall rejects before stopping velocity at acquisition")
	arena.wall.position.x = -0.5
	await physics_frame
	planned = route.plan(source, _motion(), arena.bindings)
	_expect(not planned.has("error") and route.acquire(source), kind + " unchanged world supports a fresh validated lease")
	var first: Dictionary = route.advance(source, 0.05)
	_expect(not first.has("error") and source.position.x > start.x, kind + " guard fixture executes a real first motion segment")
	var current: Vector3 = source.global_position
	var owned_velocity: Vector3 = source.velocity
	_expect(route.advance(source, 0.04).has("error") and source.global_position == current and source.velocity == owned_velocity, kind + " backward simulation clock rejects before movement")
	arena.wall.position.x = 3.0
	_expect(route.advance(source, 0.1).has("error") and source.global_position == current and source.velocity == owned_velocity, kind + " removed shortening contact cannot extend an acquired route")
	_expect(route.release(source) and source.velocity == Vector3.ZERO, kind + " owner can safely stop still-owned motion after world-proof rejection")
	arena.wall.position.x = -0.5
	source.position = start
	await physics_frame
	planned = route.plan(source, _motion(), arena.bindings)
	_expect(not planned.has("error") and route.acquire(source), kind + " body-change guard starts a fresh lease")
	var collision: CollisionShape3D = source.get_node("BodyCollision") as CollisionShape3D
	if kind == "box":
		(collision.shape as BoxShape3D).size.x += 0.1
	else:
		(collision.shape as CapsuleShape3D).radius += 0.1
	_expect(route.advance(source, 0.1).has("error") and source.position == start, kind + " changed actual source shape rejects before moving")
	route.release(source)
	if kind == "box":
		(collision.shape as BoxShape3D).size.x -= 0.1
	else:
		(collision.shape as CapsuleShape3D).radius -= 0.1
	await physics_frame
	planned = route.plan(source, _motion(), arena.bindings)
	_expect(not planned.has("error") and route.acquire(source), kind + " external-velocity guard starts a fresh lease")
	source.velocity = Vector3.BACK * 3
	_expect(route.advance(source, 0.1).has("error") and source.position == start and source.velocity == Vector3.BACK * 3, kind + " external impulse is never overwritten by advancing owned retreat")
	_expect(not route.release(source) and source.velocity == Vector3.BACK * 3 and not route.state().leased, kind + " cleanup relinquishes ownership without clobbering external velocity")
	source.velocity = Vector3.ZERO
	planned = route.plan(source, _motion(), arena.bindings)
	_expect(not planned.has("error") and route.acquire(source), kind + " floor-change guard starts a fresh lease")
	(arena.floor.shape as BoxShape3D).size.x -= 1.0
	_expect(route.advance(source, 0.1).has("error") and source.position == start and source.velocity == Vector3.ZERO, kind + " changed actual floor invalidates the complete supported route before movement")
	route.release(source)
	(arena.floor.shape as BoxShape3D).size.x += 1.0
	await physics_frame
	planned = route.plan(source, _motion(), arena.bindings)
	_expect(not planned.has("error") and route.acquire(source) and not route.advance(source, 0.05).has("error"), kind + " orientation guard starts an actually moving owned segment")
	current = source.global_position
	owned_velocity = source.velocity
	source.rotation.y = 0.1
	_expect(route.advance(source, 0.1).has("error") and source.global_position == current and not route.release(source) and source.velocity == owned_velocity, kind + " external body rotation rejects movement and cleanup never clobbers its newly controlled velocity")
	await _dispose(arena)


func _test_open_route() -> void:
	var arena: Dictionary = _world("capsule")
	arena.wall.free()
	await physics_frame
	var source: CharacterBody3D = arena.source
	var route = Route.new()
	var planned: Dictionary = route.plan(source, _motion(), arena.bindings)
	_expect(not planned.has("error") and not planned.get("collision_shortened", true) and route.acquire(source), "clear route preserves exact intended full retreat distance")
	var result: Dictionary = route.advance(source, 0.5)
	_expect(not result.has("error") and result.get("finished", false) and not result.get("actual_collided", true) and source.global_position.distance_to(planned.planned_endpoint) < Route.ENDPOINT_TOLERANCE and source.velocity == Vector3.ZERO, "full-distance endpoint is actually executed without fabricated wall contact")
	route.release(source)
	var platform: StaticBody3D = arena.floor.get_parent() as StaticBody3D
	platform.constant_linear_velocity = Vector3.RIGHT
	_expect(route.plan(source, _motion(), arena.bindings).has("error"), "moving floor conveyor/platform cannot satisfy fixed support proof")
	platform.constant_linear_velocity = Vector3.ZERO
	var outside := StaticBody3D.new()
	outside.name = "OutsideAuthoredRoot"
	outside.collision_layer = 1
	root.add_child(outside)
	_expect(route.plan(source, _motion(), arena.bindings).has("error"), "same-world scenery outside authored root fails closed")
	outside.free()
	await _dispose(arena)


func _motion() -> Dictionary:
	return {"direction": Vector3.RIGHT, "speed": 8.0, "distance": 3.8}


func _world(kind: String, hole: bool = false) -> Dictionary:
	var world := Node3D.new()
	world.name = "RetreatWorld"
	root.add_child(world)
	var floor: CollisionShape3D = _box(world, "Floor", Vector3(-0.5, -0.5, 0) if hole else Vector3(0, -0.5, 0), Vector3(19, 1, 20) if hole else Vector3(20, 1, 20))
	var floors: Dictionary = {"main": {"collision": floor, "safe_rect": Rect2(-10, -10, 20, 20)}}
	if hole:
		(floor.shape as BoxShape3D).size.x = 9
		(floor.get_parent() as StaticBody3D).position.x = -5.5
		floors.main.safe_rect = Rect2(-10, -10, 9, 20)
		var right: CollisionShape3D = _box(world, "RightFloor", Vector3(5.5, -0.5, 0), Vector3(9, 1, 20))
		floors.right = {"collision": right, "safe_rect": Rect2(1, -10, 9, 20)}
	var wall: CollisionShape3D = _box(world, "Wall", Vector3(12, 1, 0) if hole else Vector3(-0.5, 1, 0), Vector3(0.2, 2, 6))
	var source: CharacterBody3D
	if kind == "box":
		source = Enemy.new()
		source.name = "ActualAshEnemy"
		world.add_child(source)
		source.set_physics_process(false)
	else:
		source = CharacterBody3D.new()
		source.name = "CapsuleEnemyFixture"
		source.collision_layer = 2
		source.collision_mask = 1
		var collision := CollisionShape3D.new()
		collision.name = "BodyCollision"
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.27
		capsule.height = 1.1
		collision.shape = capsule
		collision.position.y = 0.55
		source.add_child(collision)
		world.add_child(source)
	source.position = Vector3(-3, 0.002, 0)
	return {"root": world, "source": source, "floor": floor, "wall": wall.get_parent(), "bindings": {"world_root": world, "floors": floors}}


func _box(world: Node3D, name: String, position: Vector3, size: Vector3) -> CollisionShape3D:
	var body := StaticBody3D.new()
	body.name = name
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	world.add_child(body)
	body.position = position
	return collision


func _dispose(arena: Dictionary) -> void:
	arena.root.free()
	await process_frame


func _expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + message)
