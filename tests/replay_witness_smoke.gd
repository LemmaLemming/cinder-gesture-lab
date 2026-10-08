extends SceneTree
## Actual player/capture + physical floor fixtures. Pure proof, no boss acceptance.
const Player = preload("res://scripts/player.gd")
const Capture = preload("res://scripts/combat/action_capture.gd")
const Sequence = preload("res://scripts/combat/replay_sequence.gd")
const Witness = preload("res://scripts/combat/replay_witness.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
var _checks: int = 0
var _failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await _single()
	await _actual_blast_union()
	await _shortened_route()
	await _two()
	await _floors_and_collision()
	print("Replay witness smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _single() -> void:
	var arena: Dictionary = await _arena()
	var captured: Dictionary = await _record(arena, 1)
	var sequence: Dictionary = _sequence(captured, arena.player.global_position)
	arena.scheduler.begin_encounter("standard", "one")
	var response: Dictionary = _response(arena)
	var witness = Witness.new()
	var before: Dictionary = _actor_snapshot(arena.player)
	var result: Dictionary = witness.prove(arena.scheduler, sequence, response, _context(arena))
	_expect(result.get("accepted", false), "one actual captured slash has a whole finite escape and primary tether witness: " + witness.last_error)
	_expect(before == _actor_snapshot(arena.player) and arena.scheduler.reservations().is_empty(), "pure proof leaves actual actor/resources/clocks and reservation table unchanged")
	var native_context: Dictionary = _context(arena)
	var native_fingerprint: Dictionary = native_context.capture_collision_fingerprint.duplicate(true)
	var forged_context: Dictionary = native_context.duplicate(true)
	var original_priority: float = float(native_fingerprint.colliders[0].priority)
	var forged_priority: float = _one_bit_float(original_priority)
	forged_context.capture_collision_fingerprint.colliders[0].priority = forged_priority
	_expect(forged_priority != original_priority and absf(forged_priority - original_priority) < 0.000000001, "forged static collision priority differs by one native bit inside the former guard tolerance")
	_expect(not witness.prove(arena.scheduler, sequence, response, forged_context).get("accepted", false) and witness.last_error.contains("capture fingerprint"), "one-bit static collision fingerprint forgery rejects before whole-route admission")
	_expect(native_fingerprint == arena.scheduler.collision_fingerprint(arena.root) and before == _actor_snapshot(arena.player) and arena.scheduler.reservations().is_empty(), "fingerprint rejection leaves measured world, actual actor and scheduler reservations unchanged")
	var fingerprint_wire: String = ExactJson.stringify(native_fingerprint)
	var transported: Dictionary = ExactJson.parse(fingerprint_wire)
	var exact_fingerprint: bool = transported.get("accepted", false) and transported.get("value") is Dictionary and not fingerprint_wire.is_empty() and ExactJson.stringify(transported.value) == fingerprint_wire
	_expect(exact_fingerprint, "tagged JSON preserves the actual static capture fingerprint's exact scalar values and types")
	if exact_fingerprint:
		var transported_context: Dictionary = native_context.duplicate(true)
		transported_context.capture_collision_fingerprint = transported.value
		_expect(witness.prove(arena.scheduler, sequence, response, transported_context).get("accepted", false), "unchanged exact-tagged native collision fingerprint retains a positive whole-sequence witness: " + witness.last_error)
	if result.get("accepted", false):
		_expect(result.slot_count == 1 and result.event_count == 1 and not result.uses_blast and not result.uses_invulnerability and not result.reserves_threat, "single proof reports its bounded scope without ammo, tanking or a fabricated reservation")
		_expect(_kind_count(result.path, "first_escape_dash") == 1 and _kind_count(result.path, "ordinary_primary_full_recovery") == 1, "witness includes finite ordinary travel and full primary recovery")
		var copied: Dictionary = result.duplicate(true)
		copied.path[0].from = Vector3(99, 0, 99)
		_expect(witness.prove(arena.scheduler, sequence, response, _context(arena)).get("accepted", false), "returned diagnostic path cannot mutate a later proof")
	var lock_proof: Dictionary = witness.prove(arena.scheduler, sequence, response, _context(arena), true)
	_expect(lock_proof.get("accepted", false) and absf(float(lock_proof.get("timeline_origin_s", 0.0)) - (arena.scheduler.get_clock() - 0.5)) < 0.00001, "fresh lock proof retains full authored locked lead from the actual current clock")
	_expect(result.get("dispatch_delay_bound_s", -1.0) == Witness.MAX_DISPATCH_DELAY_S, "whole proof reports the shared mandatory bounded damage-dispatch interval")
	var crossing: Array[Dictionary] = [{"from": Vector3(-2, 0, 0), "to": Vector3.ZERO, "start_s": 1.0, "end_s": 1.0 + Witness.MAX_DISPATCH_DELAY_S}]
	var nominal: Array[Dictionary] = [{"geometry": Geometry.circle(Vector3.ZERO, 0.2), "at_s": 1.0, "until_s": 1.0}]
	var delayed: Array[Dictionary] = nominal.duplicate(true)
	delayed[0].until_s += Witness.MAX_DISPATCH_DELAY_S
	_expect(witness._safe_path(arena.scheduler, crossing, arena.player, response.floor_regions, nominal) and not witness._safe_path(arena.scheduler, crossing, arena.player, response.floor_regions, delayed), "a path safe at the nominal instant but inside during bounded late dispatch cannot receive a safety witness")
	var edge_slot := {"end_s": 2.0, "events": [{"at_s": 2.0}]}
	_expect(absf(witness._slot_safe_end(edge_slot, arena.scheduler.TIME_MARGIN) - (2.0 + Witness.MAX_DISPATCH_DELAY_S + arena.scheduler.TIME_MARGIN)) < 0.000000001, "inter-echo recovery cannot begin before the latest possible dispatch plus the ordinary timing skin")
	var forged: Dictionary = response.duplicate(true)
	forged.stats.dash_speed += 1.0
	forged.stats.dash_duration = forged.stats.dash_distance / forged.stats.dash_speed
	_expect(not witness.prove(arena.scheduler, sequence, forged, _context(arena)).get("accepted", false), "internally consistent invented gear stats cannot replace the actual player loadout")
	forged = response.duplicate(true)
	forged.commitment_remaining_s += 0.1
	_expect(not witness.prove(arena.scheduler, sequence, forged, _context(arena)).get("accepted", false), "forged current commitment is rejected against actual public actor state")
	forged = response.duplicate(true)
	forged.recognition_s = 0.01
	_expect(not witness.prove(arena.scheduler, sequence, forged, _context(arena)).get("accepted", false), "caller cannot shorten authored recognition budget")
	paused = true
	_expect(not witness.prove(arena.scheduler, sequence, response, _context(arena)).get("accepted", false), "paused UI cannot initiate a live response proof")
	paused = false
	var source := Node3D.new()
	arena.root.add_child(source)
	var raw := {"raw_damage": 5.0, "max_hp": 20.0, "move_speed": 0.0, "windup_s": 2.0, "lock_s": 0.2, "active_s": 0.1, "recovery_s": 3.0, "attack_interval_s": 4.0}
	var difficulty = Difficulty.new()
	var role: Dictionary = difficulty.resolve_role(raw, "standard", {"windup_s": 0.5, "lock_s": 0.2, "recovery_s": 1.0})
	var threat := {"role": role, "geometry": Geometry.circle(Vector3(8, 0, 8), 0.3), "opening_position": arena.player.global_position, "source_stationary": true, "opening_stationary": true, "cooldown_remaining_s": 0.0}
	var ordinary: Dictionary = arena.scheduler.request_attack(source, threat, response)
	_expect(ordinary.get("accepted", false), "exclusive exchange fixture first admits a harmless distant ordinary source: " + String(ordinary.get("reason", "")))
	_expect(not witness.prove(arena.scheduler, sequence, response, _context(arena)).get("accepted", false) and witness.last_error.contains("exclusive"), "whole replay proof rejects another preparing source even below ordinary budget")
	var cancellations: Array[String] = []
	arena.scheduler.reservation_invalidated.connect(func(_id: String, reason: String) -> void: cancellations.append(reason))
	source.position.x += 0.1
	var saved_keys: Array = arena.scheduler.get("_reservations").keys()
	_expect(not witness.prove(arena.scheduler, sequence, response, _context(arena)).get("accepted", false) and arena.scheduler.get("_reservations").keys() == saved_keys and cancellations.is_empty(), "pure exclusive check does not prune an invalidated source or emit cancellation callbacks")
	arena.scheduler.end_encounter()
	arena.scheduler.begin_encounter("standard", "long-ready")
	# Actual primary imposes real commitment and cooldown; recognition plus those
	# must fit the full lead. No fabricated response timers are supplied.
	arena.player.slash(Vector3.RIGHT)
	response = _response(arena)
	var tight: Dictionary = _sequence(captured, arena.player.global_position, 0.01, 0.01)
	_expect(not witness.prove(arena.scheduler, tight, response, _context(arena), true).get("accepted", false), "actual current primary commitment and insufficient locked lead fail closed")
	_expect(arena.player.equip_item("WEAPON-03"), "real in-progress primary queues another legal weapon")
	var queued_response: Dictionary = _response(arena)
	_expect(not String(queued_response.get("pending_weapon_id", "")).is_empty() and not witness.prove(arena.scheduler, sequence, queued_response, _context(arena)).get("accepted", false) and witness.last_error.contains("pending weapon"), "real pending weapon cannot be treated as a stable future loadout")
	await _dispose(arena)

func _actual_blast_union() -> void:
	var arena: Dictionary = await _arena()
	var capture = Capture.new()
	paused = true
	await process_frame
	capture.arm("replay/witness", 1, 0, arena.player.get_world_action_clock())
	paused = false
	arena.player.shells = 1
	arena.player.world_action_executed.connect(func(record: Dictionary) -> void:
		capture.ingest(record, "replay/witness")
		if record.kind == "dash":
			arena.player.slash(Vector3.RIGHT)
			arena.player.blast(Vector3.LEFT)
	)
	arena.player.request_dash(Vector3.RIGHT)
	for _tick: int in range(50):
		await _ticks(1)
		capture.advance(arena.player.get_world_action_clock())
	paused = true
	await process_frame
	capture.advance(arena.player.get_world_action_clock())
	var captured: Dictionary = capture.snapshot_state()
	arena["capture_fingerprint"] = arena.scheduler.collision_fingerprint(arena.root)
	_expect(capture.slots().size() == 1 and not capture.slots()[0].blast.is_empty() and arena.player.shells == 0, "union fixture uses an actual independently aimed optional blast and its ammo cost")
	var with_blast: Dictionary = _sequence(captured, arena.player.global_position)
	paused = false
	arena.scheduler.begin_encounter("standard", "blast-union")
	var response: Dictionary = _response(arena)
	response.escape_directions = [Vector3.LEFT]
	response.return_directions = [Vector3.RIGHT]
	var witness = Witness.new()
	_expect(not witness.prove(arena.scheduler, with_blast, response, _context(arena)).get("accepted", false), "recorded left blast closes the only west escape even though the primary points right")
	# Labeled test-only transport variant removes optional blast from the actual
	# capture envelope and regenerates derived timetable. Original stays exact.
	var slash_only: Dictionary = captured.duplicate(true)
	slash_only.slots[0].blast = {}
	var without_blast: Dictionary = _sequence(slash_only, arena.player.global_position)
	_expect(witness.prove(arena.scheduler, without_blast, response, _context(arena)).get("accepted", false), "same sole west pocket is valid for the labeled slash-only capture variant")
	await _dispose(arena)

func _shortened_route() -> void:
	var arena: Dictionary = await _arena(true)
	var captured: Dictionary = await _record(arena, 1)
	_expect(captured.slots[0].dash.collision_shortened and captured.slots[0].dash.distance > 0.0, "preexisting actual wall produces a positive shortened captured route")
	var tether: Vector3 = arena.player.global_position
	var sequence: Dictionary = _sequence(captured, tether)
	# Actual new movement after freezing the immutable capture places the live
	# hero away from contact padding before lock; recorded coordinates stay put.
	arena.player.request_dash(Vector3.LEFT)
	await _ticks(50)
	arena.scheduler.begin_encounter("standard", "shortened")
	var witness = Witness.new()
	_expect(witness.prove(arena.scheduler, sequence, _response(arena), _context(arena)).get("accepted", false), "actual contact-shortened route remains valid in unchanged scenery at fresh lock: " + witness.last_error)
	await _dispose(arena)

func _two() -> void:
	var arena: Dictionary = await _arena()
	var captured: Dictionary = await _record(arena, 2)
	var tether: Vector3 = arena.player.global_position
	var sequence: Dictionary = _sequence(captured, tether)
	arena.scheduler.begin_encounter("standard", "two")
	var witness = Witness.new()
	var response: Dictionary = _response(arena)
	var result: Dictionary = witness.prove(arena.scheduler, sequence, response, _context(arena))
	_expect(result.get("accepted", false), "two real recorded combinations receive one whole-union route: " + witness.last_error)
	if result.get("accepted", false):
		_expect(result.slot_count == 2 and result.event_count == 2 and _kind_count(result.path, "second_escape_dash") == 1, "second echo uses a distinct actual full-distance escape in the same proof")
		var starts: Array[float] = []
		for segment: Dictionary in result.path:
			if segment.kind in ["first_escape_dash", "second_escape_dash"]:
				starts.append(segment.start_s)
		_expect(starts.size() == 2 and starts[1] - starts[0] >= float(response.stats.dash_cooldown) - 0.00001, "inter-echo travel retains the normal dash cooldown")
	var short_gap: Dictionary = _sequence(captured, tether, 0.5, 0.8, 0.01)
	_expect(not witness.prove(arena.scheduler, short_gap, response, _context(arena)).get("accepted", false), "tiny second-echo gap cannot bypass recognition and full ordinary travel")
	var unreachable: Dictionary = _sequence(captured, Vector3(8, 0, 8))
	_expect(not witness.prove(arena.scheduler, unreachable, response, _context(arena)).get("accepted", false), "clearing both attacks is insufficient when no ordinary-primary tether is reachable")
	var short_recovery: Dictionary = _sequence(captured, tether, 0.5, 0.8, 0.7, 0.01)
	_expect(not witness.prove(arena.scheduler, short_recovery, response, _context(arena)).get("accepted", false), "short tether window cannot omit full primary recovery")
	var malformed: Dictionary = sequence.duplicate(true)
	malformed.timeline.slots[0].events[0].record.direction = [0, 0, 0]
	_expect(not witness.prove(arena.scheduler, malformed, response, _context(arena)).get("accepted", false), "forged canonical event rejects before path enumeration")
	await _dispose(arena)

func _floors_and_collision() -> void:
	var arena: Dictionary = await _arena()
	var captured: Dictionary = await _record(arena, 1)
	var sequence: Dictionary = _sequence(captured, arena.player.global_position)
	arena.scheduler.begin_encounter("standard", "collision")
	var witness = Witness.new()
	var response: Dictionary = _response(arena)
	_expect(witness.prove(arena.scheduler, sequence, response, _context(arena)).get("accepted", false), "collision fixture has a valid unobstructed recorded route and response")
	var wall: StaticBody3D = _box(arena.root, Vector3(1.2, 1.0, 0), Vector3(0.2, 2, 12))
	await _ticks(2)
	response = _response(arena)
	_expect(not witness.prove(arena.scheduler, sequence, response, _context(arena)).get("accepted", false) and witness.last_error.contains("capture fingerprint"), "new actual wall crossing recorded absolute travel cancels rather than translating the ghost: " + witness.last_error)
	wall.queue_free()
	await _ticks(2)
	# A hole in the authored support cannot be concealed by physical floor or
	# endpoint rays. Keep actual floor as fixture, narrow proof-only rectangles.
	response = _response(arena)
	response.floor_regions = [{"collision": arena.floor, "safe_rect": Rect2(-10, -10, 10.8, 20)}, {"collision": arena.floor, "safe_rect": Rect2(1.1, -10, 8.9, 20)}]
	_expect(not witness.prove(arena.scheduler, sequence, response, _context(arena)).get("accepted", false), "continuous support rejects a proof gap between recorded route endpoints")
	response = _response(arena)
	arena.player.set_axis_lock(PhysicsServer3D.BODY_AXIS_LINEAR_X, true)
	_expect(not witness.prove(arena.scheduler, sequence, response, _context(arena)).get("accepted", false) and witness.last_error.contains("axis"), "actual axis lock cannot silently shorten an ordinary dash witness")
	arena.player.set_axis_lock(PhysicsServer3D.BODY_AXIS_LINEAR_X, false)
	var large: StaticBody3D = _box(arena.root, Vector3.ZERO, Vector3(1500, 1, 1))
	_expect(not witness.prove(arena.scheduler, sequence, _response(arena), _context(arena)).get("accepted", false) and witness.last_error.contains("precision"), "finite huge collider dimensions reject before precision can invalidate contact skin")
	large.queue_free()
	await _ticks(2)
	arena.scheduler.set("_clock", 1000001.0)
	_expect(not witness.prove(arena.scheduler, sequence, _response(arena), _context(arena)).get("accepted", false) and witness.last_error.contains("numerical"), "finite out-of-envelope scheduler clock is explicitly unsupported")
	await _dispose(arena)

func _arena(with_wall: bool = false) -> Dictionary:
	var world := Node3D.new()
	world.name = "WitnessWorld"
	root.add_child(world)
	var floor_body: StaticBody3D = _box(world, Vector3(0, -0.5, 0), Vector3(20, 1, 20))
	floor_body.name = "Floor"
	var floor: CollisionShape3D = floor_body.get_child(0)
	floor.name = "Shape"
	if with_wall:
		_box(world, Vector3(1.5, 1, 0), Vector3(0.3, 2, 20))
	var player: CinderPlayer = Player.new()
	player.name = "Hero"
	world.add_child(player)
	var scheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	world.add_child(scheduler)
	await _ticks(8)
	return {"root": world, "player": player, "scheduler": scheduler, "floor": floor}

func _record(arena: Dictionary, count: int) -> Dictionary:
	var capture = Capture.new()
	paused = true
	await process_frame
	_expect(capture.arm("replay/witness", count, 0, arena.player.get_world_action_clock()), "actual capture arms at a stable paused boundary")
	paused = false
	arena.player.shells = 0
	arena.player.world_action_executed.connect(func(record: Dictionary) -> void:
		capture.ingest(record, "replay/witness")
		if record.kind == "dash":
			arena.player.slash(Vector3.RIGHT)
	)
	for index: int in range(count):
		arena.player.request_dash(Vector3.RIGHT if index == 0 else Vector3.LEFT)
		for _tick: int in range(50):
			await _ticks(1)
			capture.advance(arena.player.get_world_action_clock())
	paused = true
	await process_frame
	capture.advance(arena.player.get_world_action_clock())
	var snapshot: Dictionary = capture.snapshot_state()
	arena["capture_fingerprint"] = arena.scheduler.collision_fingerprint(arena.root)
	_expect(capture.slots().size() == count, "fixture contains the required actual completed empty-ammo primary combinations")
	paused = false
	return snapshot

func _sequence(capture: Dictionary, tether: Vector3, warning: float = 0.5, lock: float = 0.8, gap: float = 0.7, recovery: float = 2.0) -> Dictionary:
	var sequence = Sequence.new()
	_expect(sequence.configure("crystalman/witness", capture, {"recognition_s": 0.12, "warning_s": warning, "locked_lead_s": lock, "inter_echo_gap_s": gap, "final_recovery_s": recovery, "tether_position": tether}, "replay/witness", 1), "actual sequence data configures before physical witness: " + sequence.last_error)
	return sequence.snapshot_state()

func _response(arena: Dictionary) -> Dictionary:
	var response: Dictionary = arena.player.get_threat_response_state()
	response.merge({"world_revision": 1, "recognition_s": 0.12, "attack_input_margin_s": 0.02, "escape_directions": _directions(), "return_directions": _directions(), "floor_regions": [{"collision": arena.floor, "safe_rect": Rect2(-10, -10, 20, 20)}]})
	return response

func _directions() -> Array[Vector3]:
	var result: Array[Vector3] = [Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3.RIGHT]
	for direction: Vector3 in [Vector3(-1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, -1), Vector3(1, 0, 1)]:
		result.append(direction.normalized())
	return result

func _context(arena: Dictionary) -> Dictionary:
	return {"world_root": arena.root, "source_epoch": "replay/witness", "generation": 1, "capture_collision_fingerprint": arena.get("capture_fingerprint", {})}

func _actor_snapshot(player: CinderPlayer) -> Dictionary:
	paused = true
	var result: Dictionary = player.snapshot_state()
	paused = false
	return result

func _box(parent: Node3D, point: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.name = "Box%d" % parent.get_child_count()
	var collision := CollisionShape3D.new()
	collision.name = "Shape"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.position = point
	return body

func _kind_count(path: Array, kind: String) -> int:
	var result: int = 0
	for segment: Dictionary in path:
		result += int(segment.kind == kind)
	return result

func _one_bit_float(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes[0] = bytes[0] ^ 1
	return bytes.decode_double(0)

func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame

func _dispose(arena: Dictionary) -> void:
	paused = false
	arena.root.queue_free()
	await process_frame

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
