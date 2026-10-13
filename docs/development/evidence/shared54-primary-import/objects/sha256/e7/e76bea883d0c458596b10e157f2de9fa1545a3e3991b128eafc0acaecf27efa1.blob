extends SceneTree
## TEST ONLY direct native authored-render clearance queries. No physical C52,
## source admission, HP, pending delivery, portrait or campaign acceptance claim.
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Witness = preload("res://scripts/combat/replay_witness.gd")
const Renderer = preload("res://scripts/combat/authored_echo_renderer.gd")
const START := Vector3(-2.0, 0.0, 0.0)
const FINISH := Vector3.ZERO
const CLEARANCE: Dictionary = {"radius_m": 0.3, "height_m": 1.2}

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _clear_floor()
	await _low_stone("middle", Vector3(-1.0, 0.0, 0.0))
	await _low_stone("start", START)
	await _low_stone("end", FINISH)
	await _separated_stone()
	print("Authored echo clearance smoke: %d checks, %d failures (TEST ONLY native clearance helper)" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _clear_floor() -> void:
	var arena: Dictionary = await _arena(START)
	var witness = Witness.new()
	var before: Dictionary = _native_state(arena)
	_expect(_measured_silhouette_valid(arena.visual), "actual foot-pivot BoxMesh vertices fit the source-owned upright radial/height envelope")
	_expect(witness._authored_path_clear(arena.scheduler, START, START, arena.floors, CLEARANCE), "empty native floor permits the stationary render envelope")
	_expect(witness._authored_path_clear(arena.scheduler, START, FINISH, arena.floors, CLEARANCE), "empty native floor permits the unchanged straight authored -2 to 0 route")
	_expect(_old_capsule_clear(arena, START, FINISH), "TEST ONLY historical capsule query is clear on the same empty native floor")
	_expect(_native_state(arena) == before, "clearance queries leave real nodes, resources, diagnostics and Scheduler clock unchanged")
	await _dispose(arena)


func _low_stone(label: String, pivot: Vector3) -> void:
	# Native stone bottom is y0, top .02; near z edge .13 is inside the
	# actual BoxMesh's .15 bottom edge. Neither floor nor render pivot is raised.
	var arena: Dictionary = await _arena(pivot, Vector3(pivot.x, 0.01, 0.23))
	var witness = Witness.new()
	var before: Dictionary = _native_state(arena)
	_expect(_measured_silhouette_valid(arena.visual), label + " actual native silhouette remains within its immutable .3R/1.2H enclosing domain")
	_expect(_measured_mesh_overlaps_stone(arena), label + " actual BoxMesh-sized native box query intersects the real .02-high stone at its visible feet")
	_expect(_old_capsule_clear(arena, pivot, pivot), label + " TEST ONLY old .3R/1.2H capsule falsely clears that visible-foot overlap")
	_expect(not witness._authored_path_clear(arena.scheduler, pivot, pivot, arena.floors, CLEARANCE), label + " stationary authored render clearance rejects the actual visible-foot intersection")
	_expect(_old_capsule_clear(arena, START, FINISH), label + " TEST ONLY old capsule sweep falsely clears the same real straight route obstruction")
	_expect(not witness._authored_path_clear(arena.scheduler, START, FINISH, arena.floors, CLEARANCE), label + " full authored -2 to 0 clearance rejects the real low stone including start/end occupancy")
	if label == "middle":
		_expect(witness._authored_path_clear(arena.scheduler, START, START, arena.floors, CLEARANCE) and witness._authored_path_clear(arena.scheduler, FINISH, FINISH, arena.floors, CLEARANCE), "middle obstruction leaves both measured route endpoints clear; endpoint-only checks cannot license the intervening sweep")
	_expect(_native_state(arena) == before, label + " rejected proof and historical control remain pure without native source/body mutation")
	await _dispose(arena)


func _separated_stone() -> void:
	var arena: Dictionary = await _arena(Vector3(-1.0, 0.0, 0.0), Vector3(-1.0, 0.01, 1.5))
	var witness = Witness.new()
	var before: Dictionary = _native_state(arena)
	_expect(not _measured_mesh_overlaps_stone(arena), "clearly separated real stone does not intersect the measured foot-pivot silhouette")
	_expect(witness._authored_path_clear(arena.scheduler, START, FINISH, arena.floors, CLEARANCE), "conservative enclosing render query still permits a clearly separated stone beside the route")
	_expect(witness._authored_path_clear(arena.scheduler, START, START, arena.floors, CLEARANCE) and witness._authored_path_clear(arena.scheduler, FINISH, FINISH, arena.floors, CLEARANCE), "separated stone retains stationary clearance at both real route endpoints")
	_expect(_native_state(arena) == before, "positive separated-stone query preserves actual world and scheduler state")
	await _dispose(arena)


func _arena(pivot: Vector3, stone_position: Vector3 = Vector3.INF) -> Dictionary:
	var world := Node3D.new()
	world.name = "AuthoredRenderClearanceWorld"
	root.add_child(world)
	var floor_body: StaticBody3D = _box(world, "NativeFloor", Vector3(0.0, -0.5, 0.0), Vector3(16.0, 1.0, 16.0))
	var floor_collision: CollisionShape3D = floor_body.get_child(0)
	var scheduler = Scheduler.new()
	scheduler.name = "ActualSharedScheduler"
	world.add_child(scheduler)
	var visual := MeshInstance3D.new()
	visual.name = "ActualFootPivotSilhouette"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.3, 1.0, 0.3)
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	visual.material_override = material
	visual.position = pivot + Vector3.UP * 0.5
	world.add_child(visual)
	var stone: StaticBody3D = null
	if stone_position != Vector3.INF:
		stone = _box(world, "NativeLowStone", stone_position, Vector3(0.2, 0.02, 0.2))
	# Real SceneTree physics setup; no actor clocks, reservations or poses are
	# injected to turn a mathematical clearance into a native custody receipt.
	await physics_frame
	await process_frame
	await physics_frame
	await process_frame
	return {"world": world, "scheduler": scheduler, "floor": floor_collision, "floors": [{"collision": floor_collision, "safe_rect": Rect2(-8.0, -8.0, 16.0, 16.0)}], "visual": visual, "stone": stone}


func _box(world: Node3D, node_name: String, position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = position
	var collision := CollisionShape3D.new()
	collision.name = "NativeCollision"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	world.add_child(body)
	return body


func _measured_silhouette_valid(visual: MeshInstance3D) -> bool:
	var mesh: BoxMesh = visual.mesh
	var arrays: Array = mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if vertices.is_empty(): return false
	var minimum_y: float = INF
	var maximum_y: float = -INF
	for point: Vector3 in vertices:
		var actual: Vector3 = point + Vector3.UP * 0.5
		minimum_y = minf(minimum_y, actual.y)
		maximum_y = maxf(maximum_y, actual.y)
		if not actual.is_finite() or actual.y < -Renderer.NATIVE_MEASUREMENT_EPS or actual.y > float(CLEARANCE.height_m) + Renderer.NATIVE_MEASUREMENT_EPS or Vector2(actual.x, actual.z).length() > float(CLEARANCE.radius_m) + Renderer.NATIVE_MEASUREMENT_EPS:
			return false
	return minimum_y == 0.0 and maximum_y == 1.0


func _measured_mesh_overlaps_stone(arena: Dictionary) -> bool:
	# A BoxMesh has exactly this native box volume. Query its actual measured
	# AABB and transform, rather than claiming a physical enemy was instantiated.
	var visual: MeshInstance3D = arena.visual
	var measured: AABB = visual.get_aabb()
	var shape := BoxShape3D.new()
	shape.size = measured.size
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	query.collide_with_areas = false
	query.exclude = _floor_rids(arena)
	query.transform = visual.global_transform
	query.transform.origin += visual.global_basis * measured.get_center()
	for hit: Dictionary in arena.scheduler.get_world_3d().direct_space_state.intersect_shape(query, 8):
		if hit.get("collider") == arena.stone: return true
	return false


func _old_capsule_clear(arena: Dictionary, start: Vector3, finish: Vector3) -> bool:
	# Explicit TEST ONLY historical query control. Production must enclose the
	# validated upright silhouette; its implementation is intentionally separate.
	var shape := CapsuleShape3D.new()
	shape.radius = float(CLEARANCE.radius_m)
	shape.height = float(CLEARANCE.height_m)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	query.collide_with_areas = false
	query.exclude = _floor_rids(arena)
	query.transform = Transform3D(Basis.IDENTITY, start + Vector3.UP * float(CLEARANCE.height_m) * 0.5)
	var space: PhysicsDirectSpaceState3D = arena.scheduler.get_world_3d().direct_space_state
	if not space.intersect_shape(query, 1).is_empty(): return false
	query.motion = finish - start
	var fractions: PackedFloat32Array = space.cast_motion(query)
	if fractions.size() != 2 or fractions[0] < 1.0: return false
	query.transform.origin = finish + Vector3.UP * float(CLEARANCE.height_m) * 0.5
	query.motion = Vector3.ZERO
	return space.intersect_shape(query, 1).is_empty()


func _floor_rids(arena: Dictionary) -> Array[RID]:
	var result: Array[RID] = []
	for region: Dictionary in arena.floors:
		result.append((region.collision.get_parent() as StaticBody3D).get_rid())
	return result


func _native_state(arena: Dictionary) -> Dictionary:
	var state: Dictionary = {"clock": arena.scheduler.get_clock(), "error": arena.scheduler.last_error, "snapshot_error": arena.scheduler.last_snapshot_error, "world_transform": arena.world.global_transform, "floor_transform": arena.floor.global_transform, "floor_shape": arena.floor.shape.get_instance_id(), "visual_transform": arena.visual.global_transform, "visual_mesh": arena.visual.mesh.get_instance_id(), "visual_material": arena.visual.material_override.get_instance_id()}
	if is_instance_valid(arena.stone):
		var collision: CollisionShape3D = arena.stone.get_child(0)
		state["stone_transform"] = arena.stone.global_transform
		state["stone_shape"] = collision.shape.get_instance_id()
	return state


func _dispose(arena: Dictionary) -> void:
	arena.world.queue_free()
	await process_frame
	await physics_frame
	await process_frame


func _expect(accepted: bool, description: String) -> void:
	_checks += 1
	if accepted:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
