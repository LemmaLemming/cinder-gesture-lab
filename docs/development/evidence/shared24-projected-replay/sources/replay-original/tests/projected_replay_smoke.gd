extends SceneTree
## Native consumer fixture. Records come only from real shared Player actions.
## The original selector intentionally exposes the ordinary, unclipped meshes.
const Player = preload("res://scripts/player.gd")
const Capture = preload("res://scripts/combat/action_capture.gd")
const Sequence = preload("res://scripts/combat/replay_sequence.gd")
const Playback = preload("res://scripts/combat/replay_playback.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const EPOCH: String = "projected/actual"
var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if "--original-warning" in OS.get_cmdline_user_args():
		await _original_warning()
	else:
		_expect(false, "Final projected consumer selector is not yet released")
	print("Projected replay smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _original_warning() -> void:
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena)
	var installed: Dictionary = _install(arena, recorded, false)
	if installed.is_empty():
		await _dispose(arena)
		return
	var cue: Node3D = installed.playback.get_cues()[0]
	var outline: MeshInstance3D = cue.get_node("RequiredFootprintOutline")
	var fill: MeshInstance3D = cue.get_node("RequiredFootprintFill")
	var record: Dictionary = recorded.native.timeline.slots[0].events[0].record
	_expect(cue.state().phase == "warning" and outline.is_visible_in_tree() and not fill.is_visible_in_tree(), "original actual bound owner presents visible warning outline and retains its future active fill")
	var hole_fill: bool = _native_intersects_rect(fill, arena.hole)
	var shadow_fill: bool = _native_covers(fill, record.world_origin + Vector3(1.5, 0, 1.0))
	var blocked_outline: int = _blocked_vertices(outline, arena, record)
	print("ORIGINAL native warning: hole_fill=%s shadow_fill=%s blocked_visible_outline_vertices=%d" % [hole_fill, shadow_fill, blocked_outline])
	_expect(not hole_fill, "required recorded warning/future-active native fill must exclude the actual physical floor hole")
	_expect(not shadow_fill, "required recorded warning/future-active native fill must exclude the wall's full native LOS shadow")
	_expect(blocked_outline == 0, "visible warning outline must not extend into scenery-blocked floor")
	var projected: Dictionary = Footprint.plan(arena.scheduler, recorded.sequence, arena.world, arena.floors, arena.context)
	_expect(projected.get("accepted", false), "same actual recorded sequence/world has a supported clipped projection: " + str(projected.get("reason", "")))
	await _lock(arena, installed)
	var active_seen: Array[bool] = []
	cue.state_changed.connect(func(value: Dictionary) -> void:
		if value.phase == "active":
			active_seen.append(true)
			_expect(not _native_intersects_rect(fill, arena.hole), "actual original active callback still exposes the missing physical-hole clipping")
			_expect(not _native_covers(fill, record.world_origin + Vector3(1.5, 0, 1.0)), "actual original active callback still exposes the missing native wall-shadow clipping")
			paused = true
	)
	var at_s: float = float(installed.lease.adapter.timeline_origin_s) + float(recorded.native.timeline.slots[0].events[0].at_s)
	await _until(arena.scheduler, at_s)
	installed.playback.advance()
	await process_frame
	_expect(active_seen == [true] and paused, "original regression reaches the actual active event callback once without fabricated actions or missing-API assertions")
	await _dispose(arena)


func _arena() -> Dictionary:
	paused = false
	var world := Node3D.new()
	world.name = "ProjectedWorld"
	root.add_child(world)
	var player: CinderPlayer = Player.new()
	player.name = "Hero"
	world.add_child(player)
	var d: float = float(player.get_threat_response_state().stats.dash_distance)
	var edge: float = ceilf(d * 4.0) / 4.0 + 0.5
	var hole := Rect2(edge, -1.0, 0.8, 0.7)
	var floors: Array = []
	floors.append(_region(_box(world, "FloorLeft", Vector3((edge - 10) * 0.5, -0.5, 0), Vector3(edge + 10, 1, 20))))
	floors.append(_region(_box(world, "FloorRight", Vector3((edge + 0.8 + 10) * 0.5, -0.5, 0), Vector3(10 - edge - 0.8, 1, 20))))
	floors.append(_region(_box(world, "FloorTop", Vector3(edge + 0.4, -0.5, 4.85), Vector3(0.8, 1, 10.3))))
	floors.append(_region(_box(world, "FloorBottom", Vector3(edge + 0.4, -0.5, -5.5), Vector3(0.8, 1, 9))))
	var wall: StaticBody3D = _box(world, "Wall", Vector3(d + 0.8, 1, 0.65), Vector3(0.25, 3, 0.5))
	var scheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	world.add_child(scheduler)
	await _ticks(8)
	return {"world": world, "player": player, "scheduler": scheduler, "floors": floors, "hole": hole, "wall": wall}


func _record(arena: Dictionary, blast: bool = false) -> Dictionary:
	paused = true
	await process_frame
	var capture = Capture.new()
	_expect(capture.arm(EPOCH, 1, 0, arena.player.get_world_action_clock()), "capture arms at real paused shared-player boundary")
	var signature: Dictionary = Footprint.floor_signature(arena.world, arena.floors)
	_expect(signature.get("accepted", false), "actual immutable four-Box floor ring has a supported capture signature")
	arena.context = {"source_epoch": EPOCH, "generation": 1, "capture_collision_fingerprint": arena.scheduler.pure_collision_fingerprint(arena.world), "capture_floor_signature": signature.get("signature", [])}
	arena.player.shells = 1 if blast else 0 # Explicit isolated fixture supply, not replay consumption.
	var callback: Callable = func(record: Dictionary) -> void:
		_expect(capture.ingest(record, EPOCH), "capture ingests actual contiguous " + record.kind)
		if record.kind == "dash":
			arena.player.slash(Vector3.RIGHT)
			if blast:
				arena.player.blast(Vector3.LEFT)
	arena.player.world_action_executed.connect(callback)
	paused = false
	arena.player.request_dash(Vector3.RIGHT)
	for _tick: int in range(65):
		await _ticks(1)
		capture.advance(arena.player.get_world_action_clock())
	paused = true
	await process_frame
	capture.advance(arena.player.get_world_action_clock())
	arena.player.world_action_executed.disconnect(callback)
	_expect(capture.slots().size() == 1 and capture.snapshot_state().pending.is_empty(), "completed native dash and real primary seal exactly one immutable slot")
	var sequence = Sequence.new()
	_expect(sequence.configure("projected/sequence", capture.snapshot_state(), {"recognition_s": 0.12, "warning_s": 0.5, "locked_lead_s": 1.1, "inter_echo_gap_s": 0.9, "final_recovery_s": 2.2, "tether_position": arena.player.global_position}, EPOCH, 1), "sealed Sequence derives its unchanged original event order/deadlines: " + sequence.last_error)
	_expect(arena.context.capture_collision_fingerprint == arena.scheduler.pure_collision_fingerprint(arena.world), "original capture and present admission use exactly the same real scenery")
	arena.player.shells = 0
	# Contact controls later arrange this same actual body; history is immutable.
	arena.player.set_physics_process(false)
	paused = false
	return {"capture": capture, "sequence": sequence.snapshot_state(), "native": sequence.state()}


func _install(arena: Dictionary, recorded: Dictionary, projected: bool) -> Dictionary:
	var playback = Playback.new()
	playback.name = "Playback"
	arena.world.add_child(playback)
	playback.set_physics_process(false)
	_expect(playback.configure("projected/owner", recorded.sequence, EPOCH, 1), "actual Playback configures exact sealed Sequence")
	playback.global_position = recorded.native.authored.tether_position
	_expect(arena.scheduler.begin_encounter("standard", "projected/encounter", 1), "real Scheduler starts the shared Standard profile")
	var context := {"world_root": arena.world, "source_epoch": EPOCH, "generation": 1, "capture_collision_fingerprint": arena.context.capture_collision_fingerprint}
	var answer: Dictionary = arena.scheduler.request_replay(playback, recorded.sequence, _response(arena), context)
	_expect(answer.get("accepted", false), "actual complete-union full-cone witness admits the native ring/wall world: " + str(answer.get("reason", "")))
	if not answer.get("accepted", false):
		return {}
	var retired: Dictionary = recorded.capture.take_next()
	_expect(not retired.is_empty() and recorded.capture.take_next().is_empty(), "fixture parent retires its one original current sealed slot once before bind")
	var projection: Dictionary = {}
	var accepted: bool
	if projected:
		projection = Footprint.plan(arena.scheduler, recorded.sequence, arena.world, arena.floors, arena.context)
		accepted = playback.call("bind_projected", arena.scheduler, answer.reservation_id, {"hero": arena.player}, arena.floors, projection, arena.context)
	else:
		accepted = playback.bind(arena.scheduler, answer.reservation_id, {"hero": arena.player})
	_expect(accepted, "actual consumer binds exactly its admitted player/lease: " + playback.last_error)
	if not accepted:
		return {}
	return {"playback": playback, "id": answer.reservation_id, "lease": arena.scheduler.replay_reservation_state(answer.reservation_id), "projection": projection, "recorded": recorded}


func _lock(arena: Dictionary, installed: Dictionary) -> void:
	await _until(arena.scheduler, float(installed.lease.lock_from_s))
	var answer: Dictionary = arena.scheduler.commit_replay(installed.id, _response(arena))
	_expect(answer.get("accepted", false), "actual lock freshly reproves original full-cone complete union: " + str(answer.get("reason", "")))
	installed.lease = arena.scheduler.replay_reservation_state(installed.id)
	_expect(installed.playback.advance().accepted, "consumer observes exact real immutable lock deadlines")


func _response(arena: Dictionary) -> Dictionary:
	var response: Dictionary = arena.player.get_threat_response_state()
	response.merge({"world_revision": 1, "recognition_s": 0.12, "attack_input_margin_s": 0.02, "escape_directions": [Vector3.LEFT], "return_directions": [Vector3.RIGHT], "floor_regions": arena.floors})
	return response


func _native_vertices(mesh: MeshInstance3D) -> Array[Vector3]:
	var result: Array[Vector3] = []
	if mesh.mesh == null:
		return result
	for surface: int in range(mesh.mesh.get_surface_count()):
		var local: PackedVector3Array = mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		for vertex: Vector3 in local:
			result.append(mesh.global_transform * vertex)
	return result


func _native_covers(mesh: MeshInstance3D, point: Vector3) -> bool:
	var vertices: Array[Vector3] = _native_vertices(mesh)
	for index: int in range(0, vertices.size(), 3):
		if Geometry2D.point_is_inside_triangle(Vector2(point.x, point.z), Vector2(vertices[index].x, vertices[index].z), Vector2(vertices[index + 1].x, vertices[index + 1].z), Vector2(vertices[index + 2].x, vertices[index + 2].z)):
			return true
	return false


func _native_intersects_rect(mesh: MeshInstance3D, rect: Rect2) -> bool:
	var polygon := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var vertices: Array[Vector3] = _native_vertices(mesh)
	for index: int in range(0, vertices.size(), 3):
		var triangle := PackedVector2Array([Vector2(vertices[index].x, vertices[index].z), Vector2(vertices[index + 1].x, vertices[index + 1].z), Vector2(vertices[index + 2].x, vertices[index + 2].z)])
		for intersection: PackedVector2Array in Geometry2D.intersect_polygons(triangle, polygon):
			if intersection.size() >= 3:
				return true
	return false


func _blocked_vertices(mesh: MeshInstance3D, arena: Dictionary, record: Dictionary) -> int:
	var count: int = 0
	for vertex: Vector3 in _native_vertices(mesh):
		var from: Vector3 = record.world_origin + Vector3.UP * float(record.geometry.los.height)
		var to: Vector3 = Vector3(vertex.x, record.world_origin.y, vertex.z) + Vector3.UP * float(record.geometry.los.height)
		if not arena.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, int(record.geometry.los.collision_mask))).is_empty():
			count += 1
	return count


func _region(body: StaticBody3D) -> Dictionary:
	var collision: CollisionShape3D = body.get_child(0)
	var size: Vector3 = (collision.shape as BoxShape3D).size
	return {"collision": collision, "safe_rect": Rect2(Vector2(body.position.x - size.x * 0.5, body.position.z - size.z * 0.5), Vector2(size.x, size.z))}


func _box(parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
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


func _until(scheduler: Node3D, clock_s: float) -> void:
	for _tick: int in range(900):
		if scheduler.get_clock() >= clock_s:
			return
		await _ticks(1)
	_expect(false, "bounded real simulation reaches required deadline")


func _ticks(count: int) -> void:
	for _index: int in range(count):
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
