extends SceneTree
## Actual Player records -> authenticated Footprint plans -> native ThreatCues.
## TEST ONLY fixture; no replay damage, authored boss or portrait acceptance.
const Player = preload("res://scripts/player.gd")
const Capture = preload("res://scripts/combat/action_capture.gd")
const Sequence = preload("res://scripts/combat/replay_sequence.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Cue = preload("res://scripts/cues/threat_cue.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _native_projection("hole")
	await _native_projection("wall")
	await _custody_checks()
	print("Projected cue smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _native_projection(kind: String) -> void:
	var arena: Dictionary = await _arena(kind)
	var recorded: Dictionary = await _record(arena, 1, true)
	var sequence: Dictionary = _sequence(recorded.capture, arena.player.global_position)
	var plan: Dictionary = _plan(arena, sequence)
	_expect(plan.get("accepted", false), kind + " actual native world projects its original primary/blast: " + str(plan.get("reason", "")))
	if not plan.get("accepted", false):
		await _dispose(arena)
		return
	_expect(Footprint.projection_error(plan, arena.scheduler, sequence, arena.world, arena.floors, arena.context).is_empty(), "whole original Sequence/current world authenticates event mesh before cue binding")
	var actor_before: Dictionary = arena.player.snapshot_state()
	var scheduler_clock: float = arena.scheduler.get_clock()
	for event: Dictionary in plan.events:
		var parent := Node3D.new()
		parent.position = Vector3(17, 3, -4)
		parent.rotation.y = 0.6
		parent.scale = Vector3(2, 3, 4)
		arena.world.add_child(parent)
		var cue = Cue.new()
		parent.add_child(cue)
		var changes: Array = []
		cue.state_changed.connect(func(state: Dictionary) -> void: changes.append(state.duplicate(true)))
		cue.last_error = "pure diagnostic sentinel"
		var before: PackedByteArray = _native_state(cue)
		_expect(cue.projection_binding_error(event).is_empty() and before == _native_state(cue) and cue.last_error == "pure diagnostic sentinel", "pure transaction prevalidation changes no cue, resource or diagnostic")
		_expect(cue.bind_projection(event) and changes.is_empty() and cue.state().phase == "clear", "explicit event bind silently stages native meshes while fresh/clear")
		_expect(cue.projection_error(event).is_empty(), "bound clear exposes intact hidden nonnull native receipts before first present")
		var outline: MeshInstance3D = cue.get_node("RequiredFootprintOutline")
		var fill: MeshInstance3D = cue.get_node("RequiredFootprintFill")
		var source: MeshInstance3D = cue.get_node("RequiredSourceMarker")
		_expect(outline.mesh is ArrayMesh and fill.mesh is ArrayMesh and source.mesh is ArrayMesh and not outline.visible and not fill.visible and not source.visible, "clear projection retains real outline/fill plus empty source ArrayMesh, no null fallback")
		var outline_mesh: Mesh = outline.mesh
		var fill_mesh: Mesh = fill.mesh
		var fill_vertices: PackedVector3Array = _vertices(fill_mesh)
		var contour_edges: int = 0
		var holes: int = 0
		for contour: Dictionary in event.boundary_contours:
			contour_edges += contour.vertices.size() - 1
			holes += int(contour.hole)
		_expect(fill_vertices.size() == event.triangle_vertices.size() and not _vertices(outline_mesh).is_empty() and _vertices(outline_mesh).size() % 3 == 0, "original fill triangles and all outer/hole contour edge ribbons stage inside accepted cells, without contour fan fill or seam outlines")
		if kind == "hole" and event.kind == "primary":
			_expect(holes == 1 and not _native_intersects_rect(fill, arena.hole) and not _native_intersects_rect(outline, arena.hole), "actual floor hole has its distinct contour and zero native active fill coverage")
		if kind == "wall" and event.kind == "primary":
			var origin: Vector3 = Codec.read_vector3(event.record.world_origin)
			_expect(not _native_covers(fill, origin + Vector3.RIGHT * 1.5) and _native_covers(fill, origin + Vector3(1.5, 0, 0.8)), "native fill excludes actual blocker shadow while preserving open off-shadow ground")
			var clear_los: bool = true
			for point: Vector3 in _vertices(fill.mesh) + _vertices(outline.mesh):
				var actual: Vector3 = fill.to_global(point) - Vector3.UP * (Cue.FLOOR_OFFSET - 0.004)
				var q := PhysicsRayQueryParameters3D.create(origin + Vector3.UP * float(event.record.geometry.los.height), actual + Vector3.UP * float(event.record.geometry.los.height), 1)
				clear_los = clear_los and arena.world.get_world_3d().direct_space_state.intersect_ray(q).is_empty()
			_expect(clear_los, "all actual native converted fill/outline vertices retain original scenery LOS")
		var copied: Dictionary = cue.projection_state()
		copied.bounds.clear()
		_expect(ExactJson.stringify(cue.projection_state()) == ExactJson.stringify(event), "projection_state returns an exact defensive event copy")
		for phase: String in ["warning", "lock", "active", "recovery"]:
			_expect(cue.present(_shape(event), phase) and cue.projection_error(event).is_empty(), "original raw shape follows shared " + phase + " grammar with intact projected custody")
			_expect(outline.mesh == outline_mesh and fill.mesh == fill_mesh and _vertices(fill.mesh) == fill_vertices, "phase changes preserve native projected fill/outline resource and bytes")
			var on_floor: bool = true
			for point: Vector3 in _vertices(outline.mesh):
				on_floor = on_floor and absf(outline.to_global(point).y - (float(event.floor_y) + Cue.FLOOR_OFFSET)) <= 0.000001
			_expect(on_floor and cue.global_basis == Basis.IDENTITY and cue.state().geometry == _shape(event), "encoded floor plane, actual source, raw logical shape and basis survive transformed parent")
		var notifications: int = changes.size()
		_expect(cue.present(_shape(event), "recovery") and changes.size() == notifications, "idempotent projected phase keeps existing callback semantics")
		_expect(cue.clear() and changes.size() == notifications + 1 and cue.projection_error(event).is_empty() and outline.mesh == outline_mesh and fill.mesh == fill_mesh and source.mesh is ArrayMesh, "explicit clear retains intact hidden binding and publishes ordinary clear state once")
		_expect(cue.bind_projection(event) and changes.size() == notifications + 1, "explicit clear permits silent fresh binding without an ordinary downgrade")
		cue.set_block_signals(true)
		_expect(cue.present(_shape(event), "active") and cue.projection_error(event).is_empty() and changes.size() == notifications + 1, "quiet signal blocking preserves exact projected native state without callbacks")
		cue.set_block_signals(false)
		_expect(cue.state().geometry == _shape(event) and cue.state().source_position == Codec.read_vector3(event.record.world_origin), "projected mesh never rewrites original geometry/source/state or damage timing")
	_expect(actor_before == arena.player.snapshot_state() and scheduler_clock == arena.scheduler.get_clock(), "all projection binding/guard/phase work leaves actual Player and Scheduler untouched")
	await _dispose(arena)


func _custody_checks() -> void:
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena)
	var sequence: Dictionary = _sequence(recorded.capture, arena.player.global_position)
	var plan: Dictionary = _plan(arena, sequence)
	_expect(plan.get("accepted", false), "actual completed one-slot attack supplies custody event")
	if not plan.get("accepted", false):
		await _dispose(arena)
		return
	var event: Dictionary = plan.events[0]
	var unready = Cue.new()
	_expect(not unready.projection_binding_error(event).is_empty() and not unready.bind_projection(event) and unready.projection_state().is_empty(), "unready projected binding rejects without receipts")
	unready.free()
	var invalids: Array = []
	var bad: Dictionary = event.duplicate(true)
	bad["unknown"] = 1
	invalids.append(bad)
	bad = event.duplicate(true)
	bad.floor_y = NAN
	invalids.append(bad)
	bad = event.duplicate(true)
	bad.triangle_vertices[0][1] += 0.01
	invalids.append(bad)
	bad = event.duplicate(true)
	bad.boundary_contours[0].vertices.pop_back()
	invalids.append(bad)
	bad = event.duplicate(true)
	bad.boundary_contours[0].hole = not bad.boundary_contours[0].hole
	invalids.append(bad)
	bad = event.duplicate(true)
	bad.record.origin = "replay"
	invalids.append(bad)
	bad = event.duplicate(true)
	bad.record_sequence += 1
	invalids.append(bad)
	bad = event.duplicate(true)
	bad.bounds[0] -= 0.000001
	invalids.append(bad)
	bad = event.duplicate(true)
	bad["object"] = arena.player
	invalids.append(bad)
	bad = event.duplicate(true)
	# Structural/native-precision refusal only; not authenticated clipping.
	bad.triangle_vertices = [[0.0, event.floor_y, 0.0], [1e-320, event.floor_y, 0.0], [1.0, event.floor_y, 1.0]]
	bad.boundary_contours = [{"hole": false, "vertices": [[0.0, event.floor_y, 0.0], [1e-320, event.floor_y, 0.0], [1.0, event.floor_y, 1.0], [0.0, event.floor_y, 0.0]]}]
	bad.bounds = [0.0, 0.0, 1.0, 1.0]
	invalids.append(bad)
	bad = event.duplicate(true)
	var count: int = 0
	for contour: Dictionary in bad.boundary_contours:
		count += contour.vertices.size() - 1
	var per_copy: int = count * int(bad.triangle_vertices.size() / 3)
	var copies: int = int(1048576.0 / maxf(1.0, float(per_copy))) + 2
	var repeated: Array = []
	for _copy: int in range(copies):
		repeated.append_array(bad.boundary_contours.duplicate(true))
	bad.boundary_contours = repeated
	invalids.append(bad)
	bad = event.duplicate(true)
	bad.triangle_vertices = [bad]
	invalids.append(bad)
	for invalid: Dictionary in invalids:
		var fresh = Cue.new()
		arena.world.add_child(fresh)
		var before: PackedByteArray = _native_state(fresh)
		fresh.last_error = "pure bad sentinel"
		_expect(not fresh.projection_binding_error(invalid).is_empty() and fresh.last_error == "pure bad sentinel" and before == _native_state(fresh), "malformed/cyclic/object/nonfinite record or mesh preflight rejects purely")
		_expect(not fresh.bind_projection(invalid) and fresh.projection_state().is_empty() and before == _native_state(fresh), "failed binding never partially projects or allocates an ordinary fallback")
		if invalid.get("triangle_vertices") is Array and invalid.triangle_vertices.size() == 1 and invalid.triangle_vertices[0] is Dictionary:
			invalid.triangle_vertices.clear()
		fresh.queue_free()
	var cue = _bound(arena.world, event)
	var altered: Dictionary = event.duplicate(true)
	altered.at_s = _one_bit(float(event.at_s))
	cue.last_error = "one-bit sentinel"
	_expect(not cue.projection_error(altered).is_empty() and cue.last_error == "one-bit sentinel", "one tagged float64 event bit rejects through pure expected-event guard")
	var wrong: Dictionary = _shape(event)
	wrong.reach += 0.000001
	_expect(not cue.present(wrong, "warning") and cue.state().phase == "clear", "raw range mismatch rejects before first projected warning")
	var source_override: Dictionary = _shape(event)
	source_override.source_position = source_override.origin + Vector3.RIGHT * 0.01
	_expect(not cue.present(source_override, "warning"), "source override cannot move original projected event")
	_expect(cue.present(_shape(event), "active") and not cue.projection_binding_error(event).is_empty() and not cue.bind_projection(event), "live phase prohibits rebinding without explicit clear")
	var nested: Array = []
	cue.state_changed.connect(func(state: Dictionary) -> void:
		nested.append(cue.clear())
		nested.append(cue.bind_projection(event))
		state.geometry.clear()
	)
	_expect(cue.present(_shape(event), "recovery") and nested == [false, false] and cue.projection_error(event).is_empty(), "state callback preserves reentrant rejection and defensive state without changing order")
	for kind: String in ["outline_hidden", "fill_hidden", "source_hidden", "cue_hidden", "parent_hidden", "child_transform", "cue_transform", "basis", "mesh_replaced", "mesh_null", "vertex", "index", "lod", "shadow", "source_vertex", "material_replaced", "material_depth", "material_color", "surface_override", "child_replaced", "child_freed", "parent_changed"]:
		var parent := Node3D.new()
		arena.world.add_child(parent)
		var item = _bound(parent, event)
		_expect(item.present(_shape(event), "active") and item.projection_error(event).is_empty(), kind + " starts actual intact projected active")
		_corrupt(item, parent, kind)
		var state: Dictionary = item.state()
		item.last_error = "native sentinel"
		_expect(not item.projection_error(event).is_empty() and item.last_error == "native sentinel" and item.state() == state, kind + " actual native mutation rejects purely without changing state")
		_expect(not item.present(_shape(event), "recovery") and item.state() == state, kind + " later present cannot heal lost required receipt")
		_expect(item.clear() and not item.projection_error(event).is_empty() and not item.bind_projection(event) and not item.present(_shape(event), "warning"), kind + " cancellation latches broken custody instead of resetting authority")
		parent.queue_free()
	# An empty event is a structural receipt test only: this caller-created
	# clipping must NOT authenticate through the whole real Footprint plan.
	var empty: Dictionary = event.duplicate(true)
	empty.triangle_vertices = []
	empty.boundary_contours = []
	empty.bounds = []
	var empty_cue = Cue.new()
	arena.world.add_child(empty_cue)
	_expect(empty_cue.bind_projection(empty) and empty_cue.present(_shape(empty), "active") and empty_cue.projection_error(empty).is_empty(), "TEST ONLY structural empty event retains native empty mesh receipts, not null")
	_expect(_vertices(empty_cue.get_node("RequiredFootprintFill").mesh).is_empty() and empty_cue.get_node("RequiredFootprintFill").mesh is ArrayMesh, "intact empty native fill is distinguishable from missing required resource")
	var forged: Dictionary = plan.duplicate(true)
	forged.events[0] = empty
	_expect(not Footprint.projection_error(forged, arena.scheduler, sequence, arena.world, arena.floors, arena.context).is_empty(), "caller-created empty clipping cannot pass actual whole-plan authentication")
	var ordinary = Cue.new()
	arena.world.add_child(ordinary)
	_expect(ordinary.present(Geometry.circle(Vector3.ZERO, 1.0), "active") and ordinary.clear() and ordinary.get_node("RequiredFootprintFill").mesh == null and ordinary.projection_state().is_empty(), "ordinary API1 cue behavior remains null clear and unprojected")
	await _dispose(arena)


func _bound(parent: Node3D, event: Dictionary) -> Node3D:
	var cue = Cue.new()
	parent.add_child(cue)
	_expect(cue.bind_projection(event), "actual native cue binds original event: " + cue.last_error)
	return cue


func _shape(event: Dictionary) -> Dictionary:
	var raw: Dictionary = event.record.geometry
	return Geometry.cone(Codec.read_vector3(event.record.world_origin), Codec.read_vector3(event.record.direction), float(raw.reach), float(raw.cone_min_dot), float(raw.origin_disk_radius))


func _corrupt(cue: Node3D, parent: Node3D, kind: String) -> void:
	var outline: MeshInstance3D = cue.get_node("RequiredFootprintOutline")
	var fill: MeshInstance3D = cue.get_node("RequiredFootprintFill")
	var source: MeshInstance3D = cue.get_node("RequiredSourceMarker")
	match kind:
		"outline_hidden": outline.visible = false
		"fill_hidden": fill.visible = false
		"source_hidden": source.visible = false
		"cue_hidden": cue.visible = false
		"parent_hidden": parent.visible = false
		"child_transform": outline.position.x += 0.001
		"cue_transform": cue.position.x += 0.001
		"basis": cue.rotation.y = 0.01
		"mesh_replaced": fill.mesh = fill.mesh.duplicate()
		"mesh_null": fill.mesh = null
		"shadow": (fill.mesh as ArrayMesh).shadow_mesh = ArrayMesh.new()
		"vertex", "index", "lod", "source_vertex":
			var mesh: ArrayMesh = source.mesh if kind == "source_vertex" else fill.mesh
			var arrays: Array = mesh.surface_get_arrays(0)
			var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			if kind in ["vertex", "source_vertex"]:
				points[0].x += 0.00001
				arrays[Mesh.ARRAY_VERTEX] = points
			elif kind == "index": arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([2, 1, 0])
			elif kind == "lod":
				# Installed RenderingServer accepts LODs only with a nonempty
				# base index array and fewer indices than that base surface.
				var base_indices := PackedInt32Array()
				for index: int in range(points.size()):
					base_indices.append(index)
				arrays[Mesh.ARRAY_INDEX] = base_indices
			mesh.clear_surfaces()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {1.0: PackedInt32Array([0, 1, 2])} if kind == "lod" else {})
			if kind == "lod":
				_expect(mesh.surface_get_lods(0).size() == 1 and mesh.get("_surfaces")[0].has("lods"), "LOD corruption actually reaches native surface storage with valid base indices")
		"material_replaced": outline.material_override = outline.material_override.duplicate()
		"material_depth": (outline.material_override as StandardMaterial3D).no_depth_test = true
		"material_color": (outline.material_override as StandardMaterial3D).albedo_color = Color.BLACK
		"surface_override": fill.set_surface_override_material(0, StandardMaterial3D.new())
		"child_replaced":
			cue.remove_child(source)
			source.free()
			var replacement := MeshInstance3D.new()
			replacement.name = "RequiredSourceMarker"
			# The replacement must be a valid native node for the identity
			# regression, not an unrelated dummy null-material diagnostic.
			replacement.material_override = StandardMaterial3D.new()
			cue.add_child(replacement)
		"child_freed": source.free()
		"parent_changed": cue.reparent(parent.get_parent())


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


func _arena(kind: String = "plain", kit: Array = []) -> Dictionary:
	paused = false
	var world := Node3D.new()
	world.name = "FootprintWorld"
	root.add_child(world)
	var player: CinderPlayer = Player.new()
	player.name = "Hero"
	world.add_child(player)
	var dash_distance: float = player.get_threat_response_state().stats.dash_distance
	var edge: float = ceilf(dash_distance * 4.0) / 4.0 + 0.5
	var floors: Array = []
	var floor_body: StaticBody3D
	var hole := Rect2(edge, -0.25, 0.5, 0.5)
	if kind in ["hole", "disconnected"]:
		floor_body = _box(world, "FloorLeft", Vector3((edge - 10) * 0.5, -0.5, 0), Vector3(edge + 10, 1, 20))
		floors.append(_region(floor_body))
		floors.append(_region(_box(world, "FloorRight", Vector3((edge + 0.5 + 10) * 0.5, -0.5, 0), Vector3(10 - edge - 0.5, 1, 20))))
		if kind == "hole":
			floors.append(_region(_box(world, "FloorTop", Vector3(edge + 0.25, -0.5, 5.125), Vector3(0.5, 1, 9.75))))
			floors.append(_region(_box(world, "FloorBottom", Vector3(edge + 0.25, -0.5, -5.125), Vector3(0.5, 1, 9.75))))
		else:
			hole = Rect2(edge, -10, 0.5, 20)
	else:
		floor_body = _box(world, "Floor", Vector3(0, -0.5, 0), Vector3(20, 1, 20))
		floors.append(_region(floor_body))
		if kind == "overlap":
			floors.append(_region(_box(world, "Overlap", Vector3(2, -0.5, 0), Vector3(8, 1, 8))))
	if kind in ["wall", "short", "overhead", "partial"]:
		var y: float = 1.0
		var height: float = 3.0
		if kind == "short":
			y = 0.15
			height = 0.3
		elif kind == "overhead":
			y = 3.25
			height = 0.5
		elif kind == "partial":
			y = 0.5
			height = 1.0
		_box(world, "Wall", Vector3(dash_distance + 0.75, y, 0), Vector3(0.25, height, 0.5))
	var scheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	world.add_child(scheduler)
	await _ticks(8)
	if not kit.is_empty():
		paused = true
		await process_frame
		_expect(player.get_threat_response_state().stable, "actual grounded paused bench permits clothing changes")
		for item: String in kit:
			_expect(player.equip_item(item), "fixture equips actual legal item " + item)
		paused = false
	return {"world": world, "player": player, "scheduler": scheduler, "floors": floors, "floor_body": floor_body, "hole": hole}


func _record(arena: Dictionary, count: int = 1, blast: bool = false) -> Dictionary:
	var capture = Capture.new()
	paused = true
	await process_frame
	_expect(capture.arm("footprint/source", count, 0, arena.player.get_world_action_clock()), "capture arms at actual paused stable Player boundary")
	var floors: Dictionary = Footprint.floor_signature(arena.world, arena.floors)
	_expect(floors.accepted, "actual supported floor bindings have a finite capture signature")
	arena.context = {"source_epoch": "footprint/source", "generation": 1, "capture_collision_fingerprint": arena.scheduler.pure_collision_fingerprint(arena.world), "capture_floor_signature": floors.get("signature", [])}
	paused = false
	arena.player.shells = count if blast else 0
	arena.player.world_action_executed.connect(func(record: Dictionary) -> void:
		_expect(capture.ingest(record, "footprint/source"), "capture ingests actual contiguous " + record.kind)
		if record.kind == "dash":
			arena.player.slash(Vector3.RIGHT)
			if blast:
				arena.player.blast(Vector3.LEFT)
	)
	for index: int in range(count):
		arena.player.request_dash(Vector3.RIGHT if index == 0 else Vector3.LEFT)
		for _tick: int in range(60):
			await _ticks(1)
			capture.advance(arena.player.get_world_action_clock())
	paused = true
	await process_frame
	capture.advance(arena.player.get_world_action_clock())
	var snapshot: Dictionary = capture.snapshot_state()
	_expect(capture.slots().size() == count and snapshot.pending.is_empty(), "actual completed capture contains exactly sealed requested slots")
	_expect(arena.context.capture_collision_fingerprint == arena.scheduler.pure_collision_fingerprint(arena.world), "actual capture completes against the same originally held immutable world")
	return {"capture": snapshot, "reader": capture}


func _sequence(capture: Dictionary, tether: Vector3) -> Dictionary:
	var sequence = Sequence.new()
	_expect(sequence.configure("footprint/sequence", capture, {"recognition_s": 0.12, "warning_s": 0.5, "locked_lead_s": 0.8, "inter_echo_gap_s": 0.7, "final_recovery_s": 2.0, "tether_position": tether}, "footprint/source", 1), "immutable Sequence derives its original event timetable: " + sequence.last_error)
	return sequence.snapshot_state()


func _plan(arena: Dictionary, sequence: Dictionary) -> Dictionary:
	return Footprint.plan(arena.scheduler, sequence, arena.world, arena.floors, arena.context)


func _region(body: StaticBody3D) -> Dictionary:
	var collision: CollisionShape3D = body.get_child(0)
	var size: Vector3 = (collision.shape as BoxShape3D).size
	return {"collision": collision, "safe_rect": Rect2(Vector2(collision.global_position.x - size.x * 0.5, collision.global_position.z - size.z * 0.5), Vector2(size.x, size.z))}


func _box(parent: Node3D, stable_name: String, position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = stable_name
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "Shape"
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	body.add_child(collision)
	parent.add_child(body)
	body.position = position
	return body


func _ticks(count: int) -> void:
	for _tick: int in range(count):
		await physics_frame
		await process_frame


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
