extends SceneTree
## Real completed Player records and real native floor/blocker fixtures.
## This verifies a presentation leaf, not captured boss placement/fairness.
const Player = preload("res://scripts/player.gd")
const Capture = preload("res://scripts/combat/action_capture.gd")
const Sequence = preload("res://scripts/combat/replay_sequence.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _ordinary_and_purity()
	await _floor_topology("hole")
	await _floor_topology("disconnected")
	await _floor_topology("overlap")
	await _walls()
	await _unsupported()
	await _two_slots_and_extremes()
	print("Replay footprint smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _ordinary_and_purity() -> void:
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena, 1, true)
	var sequence: Dictionary = _sequence(recorded.capture, arena.player.global_position)
	var before: Dictionary = arena.player.snapshot_state()
	var capture_before: Dictionary = recorded.reader.snapshot_state()
	var clock: float = arena.scheduler.get_clock()
	var reservations: Array = arena.scheduler.reservations()
	var cancellations: Array = []
	arena.scheduler.reservation_invalidated.connect(func(id: String, reason: String) -> void: cancellations.append([id, reason]))
	arena.scheduler.last_error = "unchanged request diagnostic"
	arena.scheduler.last_snapshot_error = "unchanged snapshot diagnostic"
	var result: Dictionary = _plan(arena, sequence)
	_expect(result.accepted, "actual completed dash, primary and separately aimed blast project: " + str(result.get("reason", "")))
	_expect(arena.scheduler.last_error == "unchanged request diagnostic" and arena.scheduler.last_snapshot_error == "unchanged snapshot diagnostic", "successful pure world/projection queries retain both Scheduler diagnostics")
	_expect(before == arena.player.snapshot_state() and capture_before == recorded.reader.snapshot_state() and arena.scheduler.get_clock() == clock and arena.scheduler.reservations() == reservations and cancellations.is_empty(), "planning changes no native actor pose/velocity/HP/ammo/clock, capture retirement, reservation or callback")
	if result.accepted:
		_expect(result.events.size() == 2 and result.events[0].kind == "primary" and result.events[1].kind == "blast", "original primary/blast event order and IDs remain separate")
		_expect(result.events[0].record == sequence.timeline.slots[0].events[0].record and result.events[1].record == sequence.timeline.slots[0].events[1].record, "all original raw records/geometry/origins/aims remain unchanged")
		var origin: Vector3 = Codec.read_vector3(result.events[0].record.world_origin)
		_expect(_covered(result.events[0], origin + Vector3.RIGHT * 0.5) and not _covered(result.events[0], origin + Vector3.LEFT * 0.5), "primary retains its actual right-facing range")
		_expect(_covered(result.events[1], origin + Vector3.LEFT * 0.5) and not _covered(result.events[1], origin + Vector3.RIGHT * 0.5), "independently left-aimed blast is not rotated into primary aim")
		_expect(_covered(result.events[0], origin + Vector3.LEFT * 0.05), "original supplied origin disk survives behind the cone source")
		_expect(_closed(result) and Footprint.floor_contains(result, origin), "finite closed encoded outer contours and domain helper accept the original source")
		_expect(not Footprint.floor_contains(result, origin - Vector3.UP * 0.1) and Footprint.floor_contains(result, origin + Vector3.UP), "floor membership rejects below-floor targets while allowing airborne X/Z membership; original event height/LOS remain separate")
		var wire: String = ExactJson.stringify(result)
		var parsed: Dictionary = ExactJson.parse(wire)
		_expect(parsed.get("accepted", false) and not wire.is_empty() and Footprint.projection_error(parsed.get("value", {}), arena.scheduler, sequence, arena.world, arena.floors, arena.context).is_empty(), "exact tagged JSON validates by deterministic whole projection recomputation")
		var copied: Dictionary = result.duplicate(true)
		copied.events[0].triangle_vertices[0][0] += 0.000001
		_expect(not Footprint.projection_error(copied, arena.scheduler, sequence, arena.world, arena.floors, arena.context).is_empty(), "finite forged mesh vertex rejects against exact recomputation")
		copied = result.duplicate(true)
		copied.events.reverse()
		_expect(not Footprint.projection_error(copied, arena.scheduler, sequence, arena.world, arena.floors, arena.context).is_empty(), "reordered event projection rejects without renumbering or rewriting records")
		var forged_context: Dictionary = arena.context.duplicate(true)
		forged_context.capture_collision_fingerprint.colliders[0].priority = _one_bit(float(forged_context.capture_collision_fingerprint.colliders[0].priority))
		_expect(not Footprint.plan(arena.scheduler, sequence, arena.world, arena.floors, forged_context).accepted, "one tagged float64 bit of capture fingerprint forgery rejects without weak equality")
		var native_priority: float = arena.floor_body.collision_priority
		arena.floor_body.collision_priority = _one_bit32(native_priority)
		_expect(arena.floor_body.collision_priority != native_priority and not Footprint.current_world_error(result, arena.scheduler, arena.world, arena.floors).is_empty(), "one native float32 bit of actual immutable world fingerprint invalidates the current projection")
		arena.floor_body.collision_priority = native_priority
		_expect(Footprint.current_world_error(result, arena.scheduler, arena.world, arena.floors).is_empty(), "restoring the exact original world restores the pure current guard")
		var changed: Array = arena.floors.duplicate(true)
		changed[0].safe_rect = Rect2(-9, -9, 18, 18)
		_expect(not Footprint.current_world_error(result, arena.scheduler, arena.world, changed).is_empty() and not Footprint.plan(arena.scheduler, sequence, arena.world, changed, arena.context).accepted, "authored safe-floor change rejects even when native collision fingerprint is unchanged")
		paused = false
		var running_plan: Dictionary = _plan(arena, sequence)
		paused = true
		_expect(ExactJson.stringify(running_plan) == wire and before == arena.player.snapshot_state(), "same synchronous native world produces identical projection regardless of pause flag without advancing simulation")
		var wrong_epoch: Dictionary = arena.context.duplicate(true)
		wrong_epoch.generation += 1
		_expect(not Footprint.plan(arena.scheduler, sequence, arena.world, arena.floors, wrong_epoch).accepted, "wrong actual capture generation cannot authenticate sealed Sequence")
	await _dispose(arena)


func _floor_topology(kind: String) -> void:
	var arena: Dictionary = await _arena(kind)
	var recorded: Dictionary = await _record(arena)
	var sequence: Dictionary = _sequence(recorded.capture, arena.player.global_position)
	var result: Dictionary = _plan(arena, sequence)
	_expect(result.accepted, "actual native " + kind + " floor topology projects: " + str(result.get("reason", "")))
	if result.accepted:
		var event: Dictionary = result.events[0]
		var origin: Vector3 = Codec.read_vector3(event.record.world_origin)
		_expect(_closed(result), kind + " boundary contours are finite and explicitly closed")
		if kind == "hole":
			var hole: Rect2 = arena.hole
			_expect(_hole_count(event) == 1, "actual four-Box floor ring retains an inner hole contour")
			_expect(not _covered(event, Vector3(hole.get_center().x, 0, hole.get_center().y)) and not Footprint.floor_contains(result, Vector3(hole.get_center().x, 0, hole.get_center().y)), "actual floor hole has neither warning fill nor floor membership")
			_expect(not _intersects_rect(event, hole), "no triangle crosses or fills any part of the actual floor hole")
			_expect(_covered(event, Vector3(hole.end.x + 0.1, 0, 0)), "valid floor beyond the hole remains as its own reachable projection region")
		elif kind == "disconnected":
			_expect(event.boundary_contours.size() >= 2 and _hole_count(event) == 0, "disconnected floor pieces retain separate outer contours")
			_expect(not _intersects_rect(event, arena.hole) and not Footprint.floor_contains(result, Vector3(arena.hole.get_center().x, 0, 0)), "no triangle bridges the physical unsupported gap")
		else:
			_expect(event.boundary_contours.size() == 1 and _hole_count(event) == 0, "overlapping floor boxes form one outline without internal overlap seams")
			var without_overlap: Array = [arena.floors[0]]
			var context: Dictionary = arena.context.duplicate(true)
			context.capture_floor_signature = Footprint.floor_signature(arena.world, without_overlap).signature
			var single: Dictionary = Footprint.plan(arena.scheduler, sequence, arena.world, without_overlap, context)
			_expect(single.accepted and absf(_area(event) - _area(single.events[0])) < 0.000001, "overlapping support does not double-fill or double-count area")
		_expect(_covered(event, origin + Vector3.RIGHT * 0.123), kind + " preserves a supported source-side fill interior away from the declared subpixel decomposition seams")
	await _dispose(arena)


func _walls() -> void:
	var arena: Dictionary = await _arena("wall")
	var recorded: Dictionary = await _record(arena)
	var sequence: Dictionary = _sequence(recorded.capture, arena.player.global_position)
	var result: Dictionary = _plan(arena, sequence)
	_expect(result.accepted, "actual full-height axis-aligned native Box clips its complete LOS shadow: " + str(result.get("reason", "")))
	if result.accepted:
		var event: Dictionary = result.events[0]
		var origin: Vector3 = Codec.read_vector3(event.record.world_origin)
		var blocked: Vector3 = origin + Vector3(1.5, 0, 0)
		var open: Vector3 = origin + Vector3(1.5, 0, 0.8)
		var corner_blocked: Vector3 = origin + Vector3(1.25, 0, 0.3)
		var corner_clear: Vector3 = origin + Vector3(1.25, 0, 0.7)
		_expect(not _covered(event, blocked) and _blocked(arena, origin, blocked), "far floor behind the wall is shadowed, not merely the wall's Box footprint")
		_expect(_covered(event, open) and not _blocked(arena, origin, open), "open off-shadow floor remains visible and filled")
		_expect(not _covered(event, corner_blocked) and _blocked(arena, origin, corner_blocked) and _covered(event, corner_clear) and not _blocked(arena, origin, corner_clear), "analytic tangent corner separates actual blocked and open rays")
		_expect(_covered(event, origin + Vector3.RIGHT * 0.2), "floor in front of the blocker remains in the warning")
		_expect(_native_clear_fill(event, arena, origin), "every actual native-converted wall-clipped triangle vertex retains clear native LOS; inset never expands fill into the blocked shadow")
		_expect(_closed(result), "wall-clipped fill exposes only closed true boundary contours")
	await _dispose(arena)
	for kind: String in ["short", "overhead", "partial"]:
		arena = await _arena(kind)
		recorded = await _record(arena)
		sequence = _sequence(recorded.capture, arena.player.global_position)
		result = _plan(arena, sequence)
		if kind == "partial":
			_expect(not result.accepted and String(result.reason).contains("partially"), "partial-height blocker rejects rather than projecting a horizontal proxy for sloping native LOS")
		else:
			_expect(result.accepted and _covered(result.events[0], arena.player.global_position + Vector3.RIGHT * 1.5), kind + " Box wholly outside the supported LOS band does not cast a fake shadow")
		await _dispose(arena)


func _unsupported() -> void:
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena)
	var sequence: Dictionary = _sequence(recorded.capture, arena.player.global_position)
	var original: Dictionary = _plan(arena, sequence)
	var excessive: Array = []
	for _index: int in range(Footprint.MAX_FLOORS + 1):
		excessive.append(arena.floors[0])
	_expect(not Footprint.plan(arena.scheduler, sequence, arena.world, excessive, arena.context).accepted, "excessive actual floor bindings reject before arrangement expansion")
	arena.scheduler.last_error = "request sentinel"
	arena.scheduler.last_snapshot_error = "snapshot sentinel"
	arena.floor_body.constant_linear_velocity = Vector3.RIGHT
	_expect(arena.scheduler.pure_collision_fingerprint(arena.world).is_empty() and arena.scheduler.last_error == "request sentinel" and arena.scheduler.last_snapshot_error == "snapshot sentinel", "unsupported pure fingerprint leaves both previous diagnostics unchanged")
	_expect(not _plan(arena, sequence).accepted, "moving static floor fails closed")
	arena.floor_body.constant_linear_velocity = Vector3.ZERO
	arena.floor_body.rotation.y = 0.01
	_expect(not _plan(arena, sequence).accepted, "actually rotated floor fails closed")
	arena.floor_body.rotation = Vector3.ZERO
	var shape: CollisionShape3D = arena.floor_body.get_child(0)
	var previous: Shape3D = shape.shape
	shape.shape = SphereShape3D.new()
	_expect(not _plan(arena, sequence).accepted, "unsupported actual floor shape fails closed")
	shape.shape = previous
	var wall: StaticBody3D = _box(arena.world, "NewWall", arena.player.global_position + Vector3(0.8, 1, 0), Vector3(0.25, 3, 0.5))
	_expect(not _plan(arena, sequence).accepted and not Footprint.current_world_error(original, arena.scheduler, arena.world, arena.floors).is_empty(), "added real native blocker rejects old capture and current projection")
	arena.context.capture_collision_fingerprint = arena.scheduler.pure_collision_fingerprint(arena.world)
	wall.rotation.y = 0.1
	_expect(not _plan(arena, sequence).accepted, "rotated blocker is not approximated by an axis-aligned decorative Box")
	wall.rotation = Vector3.ZERO
	wall.constant_angular_velocity = Vector3.UP
	_expect(not _plan(arena, sequence).accepted, "moving blocker is rejected without changing it or pruning the scheduler")
	wall.constant_angular_velocity = Vector3.ZERO
	wall.position.x = arena.player.global_position.x
	arena.context.capture_collision_fingerprint = arena.scheduler.pure_collision_fingerprint(arena.world)
	_expect(not _plan(arena, sequence).accepted, "source inside/on a blocker rejects instead of inventing hit_from_inside semantics")
	wall.position.x += 0.8
	(wall.get_child(0) as CollisionShape3D).shape = CapsuleShape3D.new()
	arena.context.capture_collision_fingerprint = arena.scheduler.pure_collision_fingerprint(arena.world)
	_expect(not _plan(arena, sequence).accepted, "unsupported native Capsule blocker fails closed")
	var restored_box := BoxShape3D.new()
	restored_box.size = Vector3(0.25, 3, 0.5)
	(wall.get_child(0) as CollisionShape3D).shape = restored_box
	arena.context.capture_collision_fingerprint = arena.scheduler.pure_collision_fingerprint(arena.world)
	var fake := Node3D.new()
	arena.world.add_child(fake)
	_expect(not Footprint.plan(fake, sequence, arena.world, arena.floors, arena.context).accepted, "generic caller cannot impersonate the real shared Scheduler fingerprint authority")
	var malformed: Dictionary = sequence.duplicate(true)
	malformed.timeline.slots[0].events[0].record.direction[0] = NAN
	var rejected: Dictionary = _plan(arena, malformed)
	_expect(not rejected.accepted and String(rejected.reason).contains("Sequence"), "nonfinite malformed sealed record rejects specifically at Sequence validation before mesh expansion")
	await _dispose(arena)


func _two_slots_and_extremes() -> void:
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena, 2, true)
	var sequence: Dictionary = _sequence(recorded.capture, arena.player.global_position)
	var result: Dictionary = _plan(arena, sequence)
	_expect(result.accepted and result.events.size() == 4, "two actual sealed slots project all four independently ordered original attacks: " + str(result.get("reason", "")))
	if result.accepted:
		var ids: Array = []
		for event: Dictionary in result.events:
			ids.append(event.event_id)
		_expect(ids == ["footprint/sequence/slot-1/primary", "footprint/sequence/slot-1/blast", "footprint/sequence/slot-2/primary", "footprint/sequence/slot-2/blast"], "bounded FIFO record IDs survive projection without regrouping equal times")
	await _dispose(arena)
	var ranges: Array = []
	for kit: Array in [["CLOTH-J0", "CLOTH-P2", "CLOTH-S2", "WEAPON-03"], ["CLOTH-J0", "CLOTH-P1", "CLOTH-S0", "WEAPON-04"]]:
		arena = await _arena("plain", kit)
		recorded = await _record(arena, 1, true)
		sequence = _sequence(recorded.capture, arena.player.global_position)
		result = _plan(arena, sequence)
		_expect(result.accepted and _closed(result), "actual legal range/cone kit projects finite original curves: " + str(kit) + " " + str(result.get("reason", "")))
		if result.accepted:
			ranges.append([result.events[0].record.geometry.reach, result.events[0].record.geometry.cone_min_dot, result.events[1].record.geometry.reach])
		await _dispose(arena)
	_expect(ranges.size() == 2 and is_equal_approx(float(ranges[0][0]), 1.8) and is_equal_approx(float(ranges[1][0]), 2.3) and ranges[0][1] == 0.05 and ranges[1][1] == 0.05, "actual gear-only minimum/maximum reaches 1.8/2.3 retain the canonical primary cone; blast supplies its distinct narrower cone")


func _arena(kind: String = "plain", kit: Array = []) -> Dictionary:
	paused = false
	var world := Node3D.new()
	world.name = "FootprintWorld"
	root.add_child(world)
	var player: CinderPlayer = Player.new()
	player.name = "Hero"
	world.add_child(player)
	for item: String in kit:
		_expect(player.equip_item(item), "fixture equips actual legal item " + item)
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


func _covered(event: Dictionary, point: Vector3) -> bool:
	for index: int in range(0, event.triangle_vertices.size(), 3):
		var a: Array = event.triangle_vertices[index]
		var b: Array = event.triangle_vertices[index + 1]
		var c: Array = event.triangle_vertices[index + 2]
		if Geometry2D.point_is_inside_triangle(Vector2(point.x, point.z), Vector2(a[0], a[2]), Vector2(b[0], b[2]), Vector2(c[0], c[2])):
			return true
	return false


func _intersects_rect(event: Dictionary, rect: Rect2) -> bool:
	var polygon := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	for index: int in range(0, event.triangle_vertices.size(), 3):
		var triangle := PackedVector2Array()
		for vertex: Array in event.triangle_vertices.slice(index, index + 3):
			triangle.append(Vector2(vertex[0], vertex[2]))
		for clipped: PackedVector2Array in Geometry2D.intersect_polygons(triangle, polygon):
			if absf(_polygon_area(clipped)) > 0.000001:
				return true
	return false


func _polygon_area(points: PackedVector2Array) -> float:
	var area: float = 0.0
	for index: int in range(points.size()):
		area += points[index].cross(points[(index + 1) % points.size()])
	return area * 0.5


func _area(event: Dictionary) -> float:
	var area: float = 0.0
	for index: int in range(0, event.triangle_vertices.size(), 3):
		var a: Array = event.triangle_vertices[index]
		var b: Array = event.triangle_vertices[index + 1]
		var c: Array = event.triangle_vertices[index + 2]
		area += absf(Vector2(b[0] - a[0], b[2] - a[2]).cross(Vector2(c[0] - a[0], c[2] - a[2]))) * 0.5
	return area


func _hole_count(event: Dictionary) -> int:
	var count: int = 0
	for contour: Dictionary in event.boundary_contours:
		count += int(contour.hole)
	return count


func _closed(result: Dictionary) -> bool:
	if not Codec.value_error(result).is_empty():
		return false
	for event: Dictionary in result.events:
		if event.triangle_vertices.is_empty() or event.triangle_vertices.size() % 3 != 0:
			return false
		for contour: Dictionary in event.boundary_contours:
			if contour.vertices.size() < 4 or contour.vertices.front() != contour.vertices.back():
				return false
	return true


func _blocked(arena: Dictionary, origin: Vector3, point: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(origin + Vector3.UP * Player.ATTACK_LOS_HEIGHT, point + Vector3.UP * Player.ATTACK_LOS_HEIGHT, Player.ATTACK_SCENERY_MASK)
	return not arena.world.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _native_clear_fill(event: Dictionary, arena: Dictionary, origin: Vector3) -> bool:
	for encoded: Array in event.triangle_vertices:
		if _blocked(arena, origin, Vector3(encoded[0], encoded[1], encoded[2])):
			return false
	return true


func _one_bit(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes[0] = bytes[0] ^ 1
	return bytes.decode_double(0)


func _one_bit32(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(4)
	bytes.encode_float(0, value)
	bytes[0] = bytes[0] ^ 1
	return bytes.decode_float(0)


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
