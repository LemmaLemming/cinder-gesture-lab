extends SceneTree
## Actual 4.7.2 floor-contact physics and execution parity; no campaign acceptance.

const Sweep = preload("res://scripts/combat/body_sweep.gd")

var _checks: int = 0
var _failures: int = 0
var _floor_recovery_seen: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("Body sweep engine: ", Engine.get_version_info())
	for kind: String in ["capsule", "box"]:
		await _body_case(kind)
	_expect(_floor_recovery_seen, "actual nonpenetrating floor contact exercised the guarded recovery cancellation")
	print("Body sweep smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _body_case(kind: String) -> void:
	var world := Node3D.new()
	world.name = "SweepWorld_" + kind
	root.add_child(world)
	# A3's diagnosed floor dimensions and shared capsule placement reproduce
	# the real finite solver contact without changing any native collision.
	var floor: Dictionary = _static_box(world, "Floor", Vector3(0, -0.5, 0), Vector3(14, 1, 22))
	var wall: Dictionary = _static_box(world, "Wall", Vector3(7, 1, 0), Vector3(0.3, 2, 20))
	var floors: Array = [{"collision": floor.collision, "safe_rect": Rect2(-7, -11, 14, 22)}]
	var body := CharacterBody3D.new()
	body.name = "Actual_" + kind
	body.collision_layer = 4
	body.collision_mask = 1
	body.floor_snap_length = 0.18
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	if kind == "capsule":
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.32
		capsule.height = 1.45
		collision.shape = capsule
		collision.position.y = 0.73
	else:
		var box := BoxShape3D.new()
		# Existing AshEnemy native BOX, not a collider retune.
		box.size = Vector3(0.75, 1.45, 0.65)
		collision.shape = box
		collision.position.y = 0.725
	body.add_child(collision)
	world.add_child(body)
	body.position = Vector3(0, 0, -0.5)
	for frame: int in range(24):
		await physics_frame
		if not body.is_on_floor():
			body.velocity.y -= 24.0 / 60.0
		elif body.velocity.y < 0.0:
			body.velocity.y = 0.0
		body.move_and_slide()
	body.velocity = Vector3(0.7, 0.2, -0.3)
	_expect(body.is_on_floor(), kind + " is genuinely grounded by move_and_slide before querying")
	var start: Transform3D = body.global_transform
	var velocity: Vector3 = body.velocity
	var exceptions: Array[PhysicsBody3D] = body.get_collision_exceptions()
	var description: Dictionary = Sweep.source_description(body)
	_expect(not description.has("error"), kind + " measures its real centred native collider")
	if description.has("error"):
		world.queue_free()
		await process_frame
		return
	var clearance: float = start.origin.y + float(description.foot_offset)
	print("Natural grounded %s source_y=%.12f feet_clearance=%.12f normal=%s" % [kind, start.origin.y, clearance, body.get_floor_normal()])
	_expect(clearance >= -Sweep.SAFE_MARGIN and clearance <= Sweep.STANDING_HEIGHT and body.get_floor_normal().dot(Vector3.UP) >= 0.999, kind + " natural solver contact stays inside source-specific safe-margin envelope")
	if kind == "capsule":
		_expect(clearance < -Sweep.EPSILON, "shared-size capsule naturally reproduces negative resting clearance without pose raising")
	var staged := CharacterBody3D.new()
	staged.name = "FreshSnapshotRecipient"
	staged.collision_layer = 4
	staged.collision_mask = 1
	var staged_collision := CollisionShape3D.new()
	staged_collision.shape = collision.shape.duplicate()
	staged_collision.position = collision.position
	staged.add_child(staged_collision)
	world.add_child(staged)
	staged.position = Vector3(4, 0.1, 2)
	staged.velocity = Vector3(0.4, 0, 0)
	await physics_frame
	var staged_pose: Transform3D = staged.global_transform
	var staged_velocity: Vector3 = staged.velocity
	var saved_pose_query: Dictionary = Sweep.sweep(staged, start, Vector3.RIGHT * 0.15, floors)
	_expect(not staged.is_on_floor() and not saved_pose_query.has("error"), kind + " saved resting pose validates in actual world without recipient floor-history cache: " + str(saved_pose_query.get("error", "")))
	_expect(staged.global_transform == staged_pose and staged.velocity == staged_velocity, kind + " staged snapshot query leaves fresh recipient untouched")
	staged.queue_free()
	await physics_frame
	var free: Dictionary = Sweep.sweep(body, start, Vector3.RIGHT * 1.2, floors)
	_expect(not free.has("error"), kind + " grounded source supports a pure straight sweep: " + str(free.get("error", "")))
	_expect(body.global_transform == start and body.velocity == velocity and body.get_collision_exceptions() == exceptions, kind + " preflight preserves pose, moving-source velocity and collision exceptions")
	if not free.has("error"):
		_expect(not free.collided and free.travel.distance_to(Vector3.RIGHT * 1.2) <= 0.00002 and free.steps.size() == 24, kind + " free sweep uses bounded steps without ghost vertical motion")
		await _execute(body, free, kind + " grounded free lane")
	# Exact touching feet are not an embedding; this exposes real floor margin
	# recovery even if move_and_slide happened to settle above it this run.
	body.global_position = Vector3(-3, -float(description.foot_offset), 0)
	body.velocity = Vector3.ZERO
	await physics_frame
	var contact_start: Transform3D = body.global_transform
	var contact: Dictionary = Sweep.step(body, contact_start, Vector3.RIGHT * 0.05, floors)
	_expect(not contact.has("error"), kind + " nonpenetrating exact floor contact is accepted: " + str(contact.get("error", "")))
	_expect(body.global_transform == contact_start and body.velocity == Vector3.ZERO, kind + " exact-contact probe never lifts the actual source")
	if not contact.has("error"):
		_floor_recovery_seen = _floor_recovery_seen or contact.floor_recovery.length() > Sweep.EPSILON
		var actual: KinematicCollision3D = body.move_and_collide(contact.motion, false, Sweep.SAFE_MARGIN, false, 1)
		_expect(body.global_position.distance_to(contact.end) <= 0.00002 and (actual != null) == contact.collided, kind + " guarded floor cancellation matches real move_and_collide")
	var tiny_start: Transform3D = body.global_transform
	var tiny: Dictionary = Sweep.sweep(body, tiny_start, Vector3.RIGHT * 0.000002, floors)
	_expect(not tiny.has("error") and body.global_transform == tiny_start, kind + " sub-epsilon query preserves original requested motion and remains pure")
	if not tiny.has("error"):
		var tiny_contact: KinematicCollision3D = body.move_and_collide(tiny.motion, false, Sweep.SAFE_MARGIN, false, 1)
		_expect(body.global_position == tiny.end and (tiny_contact != null) == tiny.collided, kind + " installed zero-normal cancellation also matches sub-epsilon execution")
	# Virtual coordinates differ from the live source. Queries still use this
	# actual body RID and native collider, without moving it to the virtual pose.
	var virtual: Transform3D = contact_start
	virtual.origin.x += 0.4
	var before_virtual: Transform3D = body.global_transform
	var virtual_result: Dictionary = Sweep.step(body, virtual, Vector3.RIGHT * 0.04, floors)
	_expect(not virtual_result.has("error") and body.global_transform == before_virtual, kind + " virtual from transform is pure and independent of current origin")
	# A thin actual wall must shorten the planned route, then real execution
	# must arrive at that measured opening with the same collision return.
	wall.body.position.x = 1.5
	body.global_position = Vector3(-2, start.origin.y, 0)
	body.velocity = Vector3.ZERO
	await physics_frame
	var wall_start: Transform3D = body.global_transform
	var shortened: Dictionary = Sweep.sweep(body, wall_start, Vector3.RIGHT * 4.0, floors)
	_expect(not shortened.has("error") and shortened.get("collided", false), kind + " actual thin wall is reported before movement: " + str(shortened.get("error", "")))
	_expect(body.global_transform == wall_start, kind + " wall-shortening preflight leaves actual pose untouched")
	if not shortened.has("error"):
		var expected_x: float = 1.35 - float(description.footprint_half.x) - Sweep.SAFE_MARGIN
		_expect(absf(shortened.end.x - expected_x) <= 0.005 and shortened.collider_rid == wall.body.get_rid(), kind + " measured native width determines wall contact")
		await _execute(body, shortened, kind + " shortened wall lane")
		body.global_transform = wall_start
		var new_wall: Dictionary = _static_box(world, "NewWall", Vector3(-0.2, 1, 0), Vector3(0.2, 2, 20))
		await physics_frame
		var changed: Dictionary = Sweep.sweep(body, wall_start, Vector3.RIGHT * 4.0, floors)
		_expect(not changed.has("error") and changed.get("collided", false) and changed.end.x < shortened.end.x - 0.5 and changed.collider_rid == new_wall.body.get_rid(), kind + " newly added wall invalidates the former endpoint before execution")
		_expect(body.global_transform == wall_start and body.velocity == Vector3.ZERO, kind + " changed-wall query preserves actor state")
		new_wall.body.queue_free()
		await physics_frame
	# Real floor penetration is rejected even if it fits a broader scheduler
	# standing envelope. No recovery is ever applied to the real body here.
	body.global_position = Vector3(-2, -float(description.foot_offset) - 0.005, 0)
	await physics_frame
	var embedded: Transform3D = body.global_transform
	var deep: Dictionary = Sweep.sweep(body, embedded, Vector3.RIGHT * 0.5, floors)
	_expect(deep.has("error") and body.global_transform == embedded and body.velocity == Vector3.ZERO, kind + " actual floor embedding rejects without depenetrating the source")
	# A shallow side-wall embedding must never be normalized as floor settling.
	body.global_position = Vector3(1.35 - float(description.footprint_half.x) + 0.0005, start.origin.y, 0)
	await physics_frame
	var side_start: Transform3D = body.global_transform
	var side: Dictionary = Sweep.step(body, side_start, Vector3.LEFT * 0.04, floors)
	_expect(side.has("error") and body.global_transform == side_start, kind + " side-wall depenetration rejects even when requested motion points away")
	body.global_position = Vector3(-3, start.origin.y, 0)
	await physics_frame
	var narrow: Array = [{"collision": floor.collision, "safe_rect": Rect2(-3.2, -0.2, 1.0, 0.4)}]
	_expect(Sweep.step(body, body.global_transform, Vector3.RIGHT * 0.04, narrow).has("error"), kind + " support rectangle must contain the entire measured body footprint")
	var holes: Array = [{"collision": floor.collision, "safe_rect": Rect2(-7, -11, 4.1, 22)}, {"collision": floor.collision, "safe_rect": Rect2(-2.3, -11, 9.3, 22)}]
	body.global_position.x = -4
	await physics_frame
	_expect(Sweep.sweep(body, body.global_transform, Vector3.RIGHT * 3.0, holes).has("error"), kind + " analytic support union rejects a gap between safe floor rectangles")
	var pose: Transform3D = body.global_transform
	_expect(Sweep.step(body, pose, Vector3.RIGHT * 0.051, floors).has("error") and Sweep.sweep(body, pose, Vector3.RIGHT * 16.1, floors).has("error") and body.global_transform == pose, kind + " bounded query work rejects oversized step and sweep without mutation")
	body.add_collision_exception_with(floor.body)
	_expect(Sweep.step(body, pose, Vector3.RIGHT * 0.04, floors).has("error") and body.global_transform == pose and body.get_collision_exceptions().size() == 1, kind + " hidden scenery exception rejects without changing the exception")
	body.remove_collision_exception_with(floor.body)
	floor.body.constant_linear_velocity = Vector3.RIGHT
	_expect(Sweep.step(body, pose, Vector3.RIGHT * 0.04, floors).has("error") and body.global_transform == pose, kind + " constant moving support rejects before motion")
	floor.body.constant_linear_velocity = Vector3.ZERO
	floor.body.constant_angular_velocity = Vector3.UP
	_expect(Sweep.step(body, pose, Vector3.RIGHT * 0.04, floors).has("error"), kind + " rotating support rejects fixed-world prediction")
	floor.body.constant_angular_velocity = Vector3.ZERO
	var animatable := AnimatableBody3D.new()
	animatable.collision_layer = 1
	animatable.collision_mask = 0
	var animated_collision := CollisionShape3D.new()
	animated_collision.shape = (floor.collision as CollisionShape3D).shape.duplicate()
	animatable.add_child(animated_collision)
	world.add_child(animatable)
	animatable.position.y = -0.5
	var animated_floors: Array = [{"collision": animated_collision, "safe_rect": Rect2(-7, -11, 14, 22)}]
	_expect(Sweep.step(body, pose, Vector3.RIGHT * 0.04, animated_floors).has("error") and body.global_transform == pose, kind + " animatable support cannot masquerade as a static floor")
	world.queue_free()
	await process_frame


func _execute(body: CharacterBody3D, prediction: Dictionary, label: String) -> void:
	var matches: bool = true
	var actual_collided: bool = false
	for record: Dictionary in prediction.steps:
		var contact: KinematicCollision3D = body.move_and_collide(record.motion, false, Sweep.SAFE_MARGIN, false, 1)
		actual_collided = contact != null
		if body.global_position.distance_to(record.end) > 0.00002 or actual_collided != record.collided:
			print("Parity diagnostic %s actual=%s predicted=%s real_contact=%s predicted_contact=%s raw=%s floor=%s" % [label, body.global_position, record.end, actual_collided, record.collided, record.raw_travel, record.floor_recovery])
			matches = false
			break
	_expect(matches and body.global_position.distance_to(prediction.end) <= 0.00002 and actual_collided == prediction.collided, label + " every pure step matches real native motion and collision return")
	await physics_frame


func _static_box(world: Node3D, label: String, position: Vector3, size: Vector3) -> Dictionary:
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	body.add_child(collision)
	world.add_child(body)
	body.position = position
	return {"body": body, "collision": collision}


func _expect(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", label)
	else:
		_failures += 1
		push_error("FAIL: " + label)
