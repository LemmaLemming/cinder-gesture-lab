extends SceneTree
## TEST ONLY actual native Box worlds and a typed authored enemy program.
## Projection/required-cue custody only; no C52 actor, damage or campaign claim.
const Authored = preload("res://scripts/combat/authored_enemy_sequence.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const ProjectionPlan = preload("res://scripts/combat/replay_footprint.gd")
const Cue = preload("res://scripts/cues/threat_cue.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for kind: String in ["plain", "hole", "wall", "stone"]:
		await _native_projection(kind)
	await _negative_identity_and_world()
	await _native_custody()
	print("Authored echo projection smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _native_projection(kind: String) -> void:
	var arena: Dictionary = await _arena(kind)
	var program: Dictionary = _program(arena)
	if program.is_empty():
		await _dispose(arena)
		return
	var source_before: Transform3D = arena.source.global_transform
	var clock: float = arena.scheduler.get_clock()
	var events: Array = []
	arena.scheduler.reservation_invalidated.connect(func(id: String, reason: String) -> void: events.append([id, reason]))
	arena.scheduler.last_error = "pure request sentinel"
	arena.scheduler.last_snapshot_error = "pure snapshot sentinel"
	var plan: Dictionary = _plan(arena, program)
	_expect(plan.get("accepted", false), kind + " actual native floor/LOS projection accepts: " + str(plan.get("reason", "")))
	_expect(arena.source.global_transform == source_before and arena.scheduler.get_clock() == clock and arena.scheduler.reservations().is_empty() and events.is_empty() and arena.scheduler.last_error == "pure request sentinel" and arena.scheduler.last_snapshot_error == "pure snapshot sentinel", "pure authored planning changes no real source/controller clock, reservations, callbacks or diagnostics")
	if not plan.get("accepted", false):
		await _dispose(arena)
		return
	_expect(plan.api_revision == ProjectionPlan.AUTHORED_API_REVISION and plan.events.size() == 1 and plan.source_id == program.source_id and plan.profile_id == program.profile_id and plan.program_digest == Exact.stringify(program).sha256_text(), "separately typed plan retains exact source/profile/program identity")
	var event: Dictionary = plan.events[0]
	_expect(event.kind == "enemy_slash" and event.event_ordinal == 1 and event.slot_id == 1 and not event.has("record_sequence") and Exact.stringify(event.record) == Exact.stringify(program.timeline.slots[0].events[0].record), "one original enemy slash has ordinal custody with no Player/capture record")
	_expect(ProjectionPlan.projection_error_authored(plan, arena.scheduler, program, arena.world, arena.floors, arena.context).is_empty() and ProjectionPlan.current_world_error(plan, arena.scheduler, arena.world, arena.floors).is_empty(), "whole-program and actual current-world pure guards accept exact plan")
	var transport: Dictionary = Exact.parse(Exact.stringify(plan))
	_expect(transport.get("accepted", false) and ProjectionPlan.projection_error_authored(transport.get("value", {}), arena.scheduler, program, arena.world, arena.floors, arena.context).is_empty(), "tagged JSON retains exact authored header/record/mesh bytes")
	var parent := Node3D.new()
	parent.position = Vector3(12, 3, -5)
	parent.rotation.y = 0.6
	parent.scale = Vector3(2, 3, 4)
	arena.world.add_child(parent)
	var cue = Cue.new()
	parent.add_child(cue)
	var changes: Array = []
	cue.state_changed.connect(func(state: Dictionary) -> void: changes.append(state.duplicate(true)))
	cue.last_error = "pure cue sentinel"
	var cue_before: PackedByteArray = _native_state(cue)
	_expect(cue.projection_binding_error(event).is_empty() and cue_before == _native_state(cue) and cue.last_error == "pure cue sentinel", "all typed authored event/native construction preflight is pure")
	_expect(cue.bind_projection(event) and changes.is_empty() and cue.projection_error(event).is_empty(), "fresh authored binding stages immutable native receipts silently")
	var outline: MeshInstance3D = cue.get_node("RequiredFootprintOutline")
	var fill: MeshInstance3D = cue.get_node("RequiredFootprintFill")
	var outline_mesh: Mesh = outline.mesh
	var fill_mesh: Mesh = fill.mesh
	_expect(outline_mesh is ArrayMesh and fill_mesh is ArrayMesh and not _vertices(outline_mesh).is_empty() and _vertices(fill_mesh).size() == event.triangle_vertices.size(), "actual ArrayMesh fill and clipped boundary strips are present")
	for phase: String in ["warning", "lock", "active", "recovery"]:
		_expect(cue.present(_shape(event), phase) and cue.projection_error(event).is_empty(), "authored " + phase + " preserves native required custody and callback grammar")
		_expect(cue.state().geometry == _shape(event) and cue.state().source_position == Codec.read_vector3(event.record.world_origin) and outline.mesh == outline_mesh and fill.mesh == fill_mesh and cue.global_basis == Basis.IDENTITY, "raw logical source/cone and native mesh identities remain unchanged under transformed parent")
		var on_plane: bool = true
		for point: Vector3 in _vertices(fill.mesh):
			on_plane = on_plane and absf(fill.to_global(point).y - (float(event.floor_y) + Cue.FLOOR_OFFSET - 0.004)) <= 0.000001
		_expect(on_plane, "native fill retains encoded floor plane plus existing cosmetic lift")
	_expect(changes.size() == 4 and cue.clear() and changes.size() == 5 and cue.projection_error(event).is_empty(), "ordinary phase callbacks and clear preserve intact hidden receipts")
	cue.set_block_signals(true)
	_expect(cue.present(_shape(event), "active") and changes.size() == 5 and cue.projection_error(event).is_empty(), "quiet reconstruction presents actual authored meshes without callbacks")
	cue.set_block_signals(false)
	var holes: int = 0
	for contour: Dictionary in event.boundary_contours:
		holes += int(contour.hole)
		_expect(Exact.stringify(contour.vertices.front()) == Exact.stringify(contour.vertices.back()), "every original outer/hole boundary remains explicitly closed")
	if kind == "hole":
		_expect(holes == 1 and not _native_intersects_rect(fill, arena.hole) and not _native_intersects_rect(outline, arena.hole), "actual floor hole retains its contour and zero native triangle coverage")
		_expect(not ProjectionPlan.floor_contains(plan, Vector3(1.25, 0, 0)) and _native_covers(fill, Vector3(1.7, 0, 0)), "domain membership and native fill preserve separate floor beyond the hole")
	elif kind == "wall":
		_expect(not _native_covers(fill, Vector3(1.5, 0, 0)) and _native_covers(fill, Vector3(1.5, 0, 1.0)), "actual full-height wall clips its far LOS shadow while open ground stays readable")
		var clear_los: bool = true
		for node: MeshInstance3D in [fill, outline]:
			for point: Vector3 in _vertices(node.mesh):
				var actual: Vector3 = node.to_global(point)
				actual.y = float(event.floor_y)
				clear_los = clear_los and not _blocked(arena, Codec.read_vector3(event.record.world_origin), actual, float(event.record.geometry.los.height))
		_expect(clear_los, "zero native fill/outline vertices leak into actual scenery-ray LOS shadow")
	elif kind == "stone":
		_expect(_native_covers(fill, Vector3(1.5, 0, 0)) and not _blocked(arena, Vector3.ZERO, Vector3(1.5, 0, 0), float(event.record.geometry.los.height)), "actual low stone below original LOS height is not inflated into a false shadow")
	_expect(arena.source.global_transform == source_before and arena.scheduler.get_clock() == clock and events.is_empty(), "native cue creation/phase/clear leaves actual source and Scheduler untouched")
	await _dispose(arena)


func _negative_identity_and_world() -> void:
	var arena: Dictionary = await _arena()
	var program: Dictionary = _program(arena)
	var plan: Dictionary = _plan(arena, program)
	_expect(plan.get("accepted", false), "identity negatives start with a valid real-world authored program")
	if not plan.get("accepted", false):
		await _dispose(arena)
		return
	var bad: Dictionary = plan.duplicate(true)
	bad.events[0].at_s = _one_bit(float(bad.events[0].at_s))
	_expect(not ProjectionPlan.projection_error_authored(bad, arena.scheduler, program, arena.world, arena.floors, arena.context).is_empty(), "one copied event-clock bit refuses immutable whole-plan equality")
	bad = plan.duplicate(true)
	bad.events[0].triangle_vertices[0][0] += 0.000001
	_expect(not ProjectionPlan.projection_error_authored(bad, arena.scheduler, program, arena.world, arena.floors, arena.context).is_empty(), "caller-created authored mesh vertex cannot authenticate through current world only")
	for key: String in ["source_id", "source_epoch", "generation", "unknown", "world_collision_fingerprint", "world_floor_signature", "world_root"]:
		var context: Dictionary = arena.context.duplicate(true)
		match key:
			"source_id": context.source_id = "other-source"
			"source_epoch": context.source_epoch = "other-epoch"
			"generation": context.generation += 1
			"unknown": context.unknown = true
			"world_collision_fingerprint": context.world_collision_fingerprint.colliders[0].priority = _one_bit(float(context.world_collision_fingerprint.colliders[0].priority))
			"world_floor_signature": context.world_floor_signature[0].top_y = _one_bit(float(context.world_floor_signature[0].top_y))
			"world_root": context.world_root = arena.source
		_expect(not ProjectionPlan.plan_authored(arena.scheduler, program, arena.world, arena.floors, context).get("accepted", false), "changed typed " + key + " context rejects without fallback")
	_expect(not ProjectionPlan.plan(arena.scheduler, program, arena.world, arena.floors, {"source_epoch": program.source_epoch, "generation": program.generation, "capture_collision_fingerprint": arena.context.world_collision_fingerprint, "capture_floor_signature": arena.context.world_floor_signature}).get("accepted", false), "captured projection API does not reinterpret an enemy-authored program")
	var collision: CollisionShape3D = arena.floors[0].collision
	var box: BoxShape3D = collision.shape
	var size: Vector3 = box.size
	box.size.x += 0.125
	_expect(not ProjectionPlan.current_world_error(plan, arena.scheduler, arena.world, arena.floors).is_empty() and not _plan(arena, program).accepted, "changed actual native Box shape invalidates bound world and projection")
	box.size = size
	_expect(ProjectionPlan.current_world_error(plan, arena.scheduler, arena.world, arena.floors).is_empty(), "exact original native world restores its pure diagnostic")
	await _dispose(arena)


func _native_custody() -> void:
	var arena: Dictionary = await _arena()
	var plan: Dictionary = _plan(arena, _program(arena))
	_expect(plan.get("accepted", false), "custody checks start with valid authored projection")
	if not plan.get("accepted", false):
		await _dispose(arena)
		return
	var event: Dictionary = plan.events[0]
	for kind: String in ["ordinal", "record_sequence", "player_gear", "provenance", "null_record", "source_record", "floor", "nonfinite", "object", "cyclic"]:
		var bad: Dictionary = event.duplicate(true)
		match kind:
			"ordinal": bad.event_ordinal = 2
			"record_sequence": bad.record_sequence = 1
			"player_gear": bad.record.equipment = {}
			"provenance": bad.record.provenance = "player_direct"
			"null_record": bad.record = null
			"source_record": bad.record.kind = "primary"
			"floor": bad.triangle_vertices[0][1] += 0.01
			"nonfinite": bad.record.damage = INF
			"object": bad.record.owner = arena.source
			"cyclic": bad.triangle_vertices = [bad]
		var fresh = Cue.new()
		arena.world.add_child(fresh)
		var before: PackedByteArray = _native_state(fresh)
		fresh.last_error = "negative pure sentinel"
		_expect(not fresh.projection_binding_error(bad).is_empty() and before == _native_state(fresh) and fresh.last_error == "negative pure sentinel", kind + " malformed authored receipt rejects purely")
		_expect(not fresh.bind_projection(bad) and fresh.projection_state().is_empty() and before == _native_state(fresh), kind + " failed bind commits no resources/state")
		if kind == "cyclic":
			bad.triangle_vertices.clear()
		fresh.queue_free()
	for kind: String in ["hidden", "freed", "mesh_vertex", "material_depth", "transformed"]:
		var cue = Cue.new()
		arena.world.add_child(cue)
		_expect(cue.bind_projection(event) and cue.present(_shape(event), "active"), kind + " starts intact authored required cue")
		var fill: MeshInstance3D = cue.get_node("RequiredFootprintFill")
		match kind:
			"hidden": fill.visible = false
			"freed": fill.free()
			"mesh_vertex":
				var mesh: ArrayMesh = fill.mesh
				var arrays: Array = mesh.surface_get_arrays(0)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				vertices[0].x += 0.00001
				arrays[Mesh.ARRAY_VERTEX] = vertices
				mesh.clear_surfaces()
				mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			"material_depth": (fill.material_override as StandardMaterial3D).no_depth_test = true
			"transformed": fill.position.x += 0.001
		cue.last_error = "native pure sentinel"
		_expect(not cue.projection_error(event).is_empty() and cue.last_error == "native pure sentinel", kind + " actual native custody loss is a pure failure")
		_expect(not cue.present(_shape(event), "recovery") and cue.clear() and not cue.bind_projection(event) and not cue.present(_shape(event), "warning"), kind + " lost required cue remains latched across clear/present instead of healed")
		cue.queue_free()
	await _dispose(arena)


func _arena(kind: String = "plain") -> Dictionary:
	paused = false
	var world := Node3D.new()
	world.name = "AuthoredProjectionWorld"
	root.add_child(world)
	var source := Node3D.new()
	source.name = "StationarySource"
	world.add_child(source)
	var floors: Array = []
	var hole := Rect2(1.0, -0.25, 0.5, 0.5)
	if kind == "hole":
		floors.append(_region(_box(world, "FloorLeft", Vector3(-4.5, -0.5, 0), Vector3(11, 1, 20))))
		floors.append(_region(_box(world, "FloorRight", Vector3(5.75, -0.5, 0), Vector3(8.5, 1, 20))))
		floors.append(_region(_box(world, "FloorTop", Vector3(1.25, -0.5, 5.125), Vector3(0.5, 1, 9.75))))
		floors.append(_region(_box(world, "FloorBottom", Vector3(1.25, -0.5, -5.125), Vector3(0.5, 1, 9.75))))
	else:
		floors.append(_region(_box(world, "Floor", Vector3(0, -0.5, 0), Vector3(20, 1, 20))))
	if kind in ["wall", "stone"]:
		_box(world, "Scenery", Vector3(0.75, 1.0, 0) if kind == "wall" else Vector3(0.75, 0.15, 0), Vector3(0.25, 3.0, 0.5) if kind == "wall" else Vector3(0.25, 0.3, 0.5))
	var scheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	world.add_child(scheduler)
	_expect(scheduler.begin_encounter("standard", "authored-projection-leaf", 1), "actual Scheduler begins a fixed profile/world fixture")
	await physics_frame
	await process_frame
	paused = true
	var signature: Dictionary = ProjectionPlan.floor_signature(world, floors)
	_expect(signature.get("accepted", false), "actual Box floor signature is available")
	var fingerprint: Dictionary = scheduler.pure_collision_fingerprint(world)
	_expect(not fingerprint.is_empty(), "actual static native collision fingerprint is available")
	var context := {"world_root": world, "source_id": "test-mirror-source", "source_epoch": "test-mirror-epoch", "generation": 1, "world_collision_fingerprint": fingerprint, "world_floor_signature": signature.get("signature", [])}
	return {"world": world, "source": source, "scheduler": scheduler, "floors": floors, "hole": hole, "context": context}


func _program(arena: Dictionary) -> Dictionary:
	var definition := {"definition_id": "test-mirror-definition", "definition_revision": 1, "role_id": "C52", "raw_role": {"raw_damage": 12.0, "windup_s": 1.0, "lock_s": 0.2, "active_s": 0.5, "recovery_s": 0.3, "attack_interval_s": 0.8, "max_hp": 20.0, "move_speed": 0.0}, "timing_floors": {"windup_s": 0.3, "lock_s": 0.1, "recovery_s": 0.2}, "recognition_s": 0.25, "route": [{"position": Vector3.LEFT, "at_s": 0.0}, {"position": Vector3.ZERO, "at_s": 0.4}], "travel_clearance": {"radius_m": 0.3, "height_m": 1.2}, "slash": {"world_origin": Vector3.ZERO, "direction": Vector3.RIGHT, "reach": 3.0, "cone_min_dot": 0.0, "origin_disk_radius": 0.12, "max_vertical_distance": 1.2, "los_height": 0.45, "commitment_duration_s": 0.1, "visual_duration_s": 0.2}, "presentation": {"presentation_id": "test-echo", "presentation_revision": 1}}
	var reader = Authored.new()
	var prepared := {"world_revision": 1, "collision_fingerprint": arena.context.world_collision_fingerprint, "floor_signature": arena.context.world_floor_signature}
	_expect(reader.configure("test-mirror-cycle", definition, arena.context.source_id, arena.context.source_epoch, arena.context.generation, "standard", prepared), "typed source-owned TEST ONLY program resolves against real fixed world: " + reader.last_error)
	return reader.snapshot_state()


func _plan(arena: Dictionary, program: Dictionary) -> Dictionary:
	return ProjectionPlan.plan_authored(arena.scheduler, program, arena.world, arena.floors, arena.context)


func _shape(event: Dictionary) -> Dictionary:
	var record: Dictionary = Authored.decode_action_record(event.record)
	return Geometry.cone(record.world_origin, record.direction, float(record.geometry.reach), float(record.geometry.cone_min_dot), float(record.geometry.origin_disk_radius))


func _box(parent: Node3D, stable_name: String, position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = stable_name
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "Shape"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.position = position
	return body


func _region(body: StaticBody3D) -> Dictionary:
	var collision: CollisionShape3D = body.get_child(0)
	var size: Vector3 = (collision.shape as BoxShape3D).size
	return {"collision": collision, "safe_rect": Rect2(Vector2(collision.global_position.x - size.x * 0.5, collision.global_position.z - size.z * 0.5), Vector2(size.x, size.z))}


func _vertices(mesh: Mesh) -> PackedVector3Array:
	return PackedVector3Array() if mesh == null or mesh.get_surface_count() == 0 else mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]


func _native_covers(fill: MeshInstance3D, point: Vector3) -> bool:
	var vertices: PackedVector3Array = _vertices(fill.mesh)
	for index: int in range(0, vertices.size(), 3):
		var a: Vector3 = fill.to_global(vertices[index])
		var b: Vector3 = fill.to_global(vertices[index + 1])
		var c: Vector3 = fill.to_global(vertices[index + 2])
		if Geometry2D.point_is_inside_triangle(Vector2(point.x, point.z), Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z)):
			return true
	return false


func _native_intersects_rect(mesh: MeshInstance3D, rect: Rect2) -> bool:
	var vertices: PackedVector3Array = _vertices(mesh.mesh)
	var polygon := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	for index: int in range(0, vertices.size(), 3):
		var triangle := PackedVector2Array()
		for point: Vector3 in vertices.slice(index, index + 3):
			var actual: Vector3 = mesh.to_global(point)
			triangle.append(Vector2(actual.x, actual.z))
		for overlap: PackedVector2Array in Geometry2D.intersect_polygons(triangle, polygon):
			var area: float = 0.0
			for edge: int in range(overlap.size()):
				area += overlap[edge].cross(overlap[(edge + 1) % overlap.size()])
			if absf(area) > 0.00000001:
				return true
	return false


func _blocked(arena: Dictionary, origin: Vector3, point: Vector3, height: float) -> bool:
	var query := PhysicsRayQueryParameters3D.create(origin + Vector3.UP * height, point + Vector3.UP * height, 1)
	return not arena.world.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _native_state(cue: Node3D) -> PackedByteArray:
	var data: Array = [cue.state(), cue.projection_state(), cue.global_transform]
	for child: MeshInstance3D in cue.get_children():
		data.append([child.get_instance_id(), child.transform, child.visible, null if child.mesh == null else child.mesh.get_instance_id()])
	return var_to_bytes(data)


func _one_bit(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes[0] = bytes[0] ^ 1
	return bytes.decode_double(0)


func _dispose(arena: Dictionary) -> void:
	paused = false
	arena.world.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
