extends SceneTree
## Actual player/capture + immutable static world fixtures; no replay damage,
## historical custody/slot retirement or campaign encounter acceptance claim.
const Player = preload("res://scripts/player.gd")
const Capture = preload("res://scripts/combat/action_capture.gd")
const Sequence = preload("res://scripts/combat/replay_sequence.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Witness = preload("res://scripts/combat/replay_witness.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
var _checks: int = 0
var _failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await _exclusive_and_commit()
	await _transport()
	await _cancellations()
	await _pure_failure()
	await _custody_and_contracts()
	await _lock_boundary()
	print("Replay scheduler smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _exclusive_and_commit() -> void:
	var arena: Dictionary = await _arena(1)
	var scheduler = arena.scheduler
	var player: CinderPlayer = arena.player
	_expect(scheduler.begin_encounter("standard", "replay-one"), "actual single capture starts a fixed encounter")
	var actor_before: Dictionary = await _player_snapshot(player)
	var request: Dictionary = scheduler.request_replay(arena.source, arena.sequence, _response(arena), _context(arena))
	_expect(request.get("accepted", false), "one actual empty-ammo slash receives an exclusive typed preview: " + scheduler.last_error)
	if not request.get("accepted", false):
		await _dispose(arena)
		return
	var id: String = request.reservation_id
	var record: Dictionary = scheduler.replay_reservation_state(id)
	_expect(record.adapter.kind == "replay" and not record.has("geometry") and not record.armed and record.state == "warning", "preview has immutable compound data and no ordinary proxy geometry")
	_expect(scheduler.replay_target(id) == player and record.response_actor_instance_id == player.get_instance_id(), "lease retains the exact actual proof player")
	_expect(actor_before == await _player_snapshot(player) and player.shells == 0, "reservation allocates no player action, HP or ammo changes")
	_expect(not scheduler.commit_replay(id, _response(arena)).get("accepted", false) and not scheduler.replay_reservation_state(id).armed, "early commit leaves the unarmed preview intact")
	var returned: Dictionary = record.duplicate(true)
	returned.adapter.sequence.authored.warning_s = 99.0
	_expect(scheduler.replay_reservation_state(id).adapter.sequence.authored.warning_s == 0.5, "native public record cannot mutate the immutable sequence")
	_expect(not scheduler.request_replay(arena.other, arena.sequence, _response(arena), _context(arena)).get("accepted", false), "a second replay cannot share preview budget")
	_expect(not scheduler.request_attack(arena.other, _threat(arena), _response(arena)).get("accepted", false), "ordinary request cannot intrude into exclusive replay preview")
	_expect(not scheduler.request_tracking(arena.other, _tracking(arena), _response(arena)).get("accepted", false), "unarmed tracking preview also cannot intrude")
	_expect(scheduler.replay_exchange_error(arena.sequence, _context(arena), id).is_empty(), "exact own unarmed reservation permits lock-only witness self-exclusion")
	var forged_context: Dictionary = _context(arena)
	forged_context.generation += 1
	_expect(not scheduler.replay_exchange_error(arena.sequence, forged_context, id).is_empty() and not scheduler.replay_exchange_error(arena.sequence, _context(arena), "threat-999").is_empty(), "self-exclusion cannot substitute identity/context or a different reservation ID")
	var tiny_sequence_drift: Dictionary = arena.sequence.duplicate(true)
	tiny_sequence_drift.authored.warning_s = _next_float(tiny_sequence_drift.authored.warning_s)
	_expect(not scheduler.replay_exchange_error(tiny_sequence_drift, _context(arena), id).is_empty(), "one-bit sequence drift cannot identify the exact own unarmed replay")
	await _until(scheduler, float(record.lock_from_s) + 0.05)
	var actual_lock: float = scheduler.get_clock()
	var committed: Dictionary = scheduler.commit_replay(id, _response(arena))
	_expect(committed.get("accepted", false), "actual delayed legal lock re-proves the entire sequence: " + scheduler.last_error)
	if committed.get("accepted", false):
		record = scheduler.replay_reservation_state(id)
		_expect(record.armed and absf(record.lock_from_s - actual_lock) < 0.000000001 and absf(record.active_from_s - actual_lock - 0.8) < 0.000000001, "full authored locked lead begins at actual successful commit clock")
		_expect(record.adapter.max_dispatch_delay_s == Witness.MAX_DISPATCH_DELAY_S and record.cooldown_until_s == record.recovery_until_s, "fixed dispatch grace cannot be caller-shortened and cooldown covers the whole exchange")
		_expect(not scheduler.commit_replay(id, _response(arena)).get("accepted", false) and scheduler.replay_reservation_state(id).armed, "duplicate commit cannot refresh an armed sequence")
		await _until(scheduler, record.active_from_s + 0.1)
		_expect(not scheduler.request_attack(arena.other, _threat(arena), _response(arena)).get("accepted", false), "ordinary request stays excluded during playback")
		await _until(scheduler, record.active_until_s + 0.05)
		_expect(not scheduler.replay_reservation_state(id).is_empty() and not scheduler.request_attack(arena.other, _threat(arena), _response(arena)).get("accepted", false), "exclusive reservation persists through stationary tether recovery")
		var cancellations: Array = []
		scheduler.reservation_invalidated.connect(func(_id: String, why: String) -> void: cancellations.append(why))
		await _until(scheduler, record.recovery_until_s + 0.05)
		_expect(scheduler.replay_reservation_state(id).is_empty() and cancellations.is_empty() and scheduler.replay_cancellation_state(id).is_empty(), "normal completion releases silently without manufacturing cancellation history")
		_expect(scheduler.request_attack(arena.other, _threat(arena), _response(arena)).get("accepted", false), "ordinary scheduling resumes after the whole replay recovery")
	await _dispose(arena)

func _transport() -> void:
	var arena: Dictionary = await _arena(2)
	var scheduler = arena.scheduler
	scheduler.begin_encounter("standard", "replay-two")
	var request: Dictionary = scheduler.request_replay(arena.source, arena.sequence, _response(arena), _context(arena))
	_expect(request.get("accepted", false), "two real captured combinations receive one compound reservation: " + scheduler.last_error)
	if not request.get("accepted", false):
		await _dispose(arena)
		return
	var id: String = request.reservation_id
	var bindings: Dictionary = _bindings(arena)
	var events: Array = []
	scheduler.reservation_invalidated.connect(func(_id: String, why: String) -> void: events.append(why))
	await _paused_barrier()
	var snapshot: Dictionary = scheduler.snapshot_state(bindings)
	_expect(not snapshot.is_empty(), "preview captures only at a paused deferred actor/world boundary: " + scheduler.last_snapshot_error)
	if snapshot.is_empty():
		await _dispose(arena)
		return
	_expect(not snapshot.has("replay_cancellations") and snapshot.reservations[0].response_actor_id == "hero" and not snapshot.reservations[0].has("geometry") and Codec.value_error(snapshot).is_empty(), "stable preview transport contains no objects, ordinary geometry or empty tombstone extension")
	var round_trip: Dictionary = _json(snapshot)
	_expect(_same(snapshot, round_trip) and typeof(round_trip.clock_s) == TYPE_FLOAT and typeof(round_trip.serial) == TYPE_INT, "tagged transport retains exact scalar bits/types, including native scheduler clock and serial")
	_expect(scheduler.snapshot_error(round_trip, bindings).is_empty() and scheduler.restore_state(round_trip, bindings), "exact tagged JSON transports two-slot preview and actual actor binding: " + scheduler.last_snapshot_error)
	_expect(_same(snapshot, scheduler.snapshot_state(bindings)) and events.is_empty(), "quiet restore preserves prefix-free preview clocks/cooldowns without callbacks")
	var bad: Dictionary = snapshot.duplicate(true)
	bad.reservations[0].adapter.max_dispatch_delay_s = 0.01
	_expect(_reject_unchanged(arena, bad), "caller cannot shorten mandatory dispatch grace in saved adapter")
	bad = snapshot.duplicate(true)
	bad.reservations[0].adapter.sequence.timeline.slots[0].events[0].at_s += 0.1
	_expect(_reject_unchanged(arena, bad), "canonical event timeline cannot drift from the actual sealed action records")
	bad = snapshot.duplicate(true)
	bad.reservations[0].adapter.timeline_origin_s += 0.01
	_expect(_reject_unchanged(arena, bad), "serialized origin cannot refresh or shorten derived deadlines")
	bad = snapshot.duplicate(true)
	bad.reservations[0].active_from_s = _next_float(bad.reservations[0].active_from_s)
	_expect(_reject_unchanged(arena, bad), "one-bit deadline drift cannot pass exact immutable replay timing validation")
	bad = snapshot.duplicate(true)
	bad.reservations[0].response_actor_id = "another-player"
	_expect(_reject_unchanged(arena, bad), "unknown response actor cannot replace proof custody")
	bad = snapshot.duplicate(true)
	bad.reservations[0]["geometry"] = {"kind": "circle", "origin": [0, 0, 0], "radius": 1.0}
	_expect(_reject_unchanged(arena, bad), "replay rejects additional ordinary proxy geometry atomically")
	bad = snapshot.duplicate(true)
	bad.reservations[0].adapter.locked = true
	_expect(_reject_unchanged(arena, bad), "preview cannot restore armed before its actual lock")
	bad = snapshot.duplicate(true)
	bad.reservations.append(bad.reservations[0].duplicate(true))
	bad.reservations[1].id = "threat-2"
	bad.reservations[1].source_id = "other"
	bad.serial = 2
	_expect(_reject_unchanged(arena, bad), "two replay reservations cannot smuggle an overlapping exclusive exchange into restore")
	_expect(events.is_empty(), "all failed replay snapshot validation remains quiet")
	var clock_before: float = scheduler.get_clock()
	await process_frame
	await process_frame
	_expect(scheduler.get_clock() == clock_before and _same(snapshot, scheduler.snapshot_state(bindings)), "pause keeps preview/world deadlines fixed across UI frames")
	paused = false
	await _until(scheduler, snapshot.reservations[0].lock_from_s)
	_expect(scheduler.commit_replay(id, _response(arena)).get("accepted", false), "two-slot lock re-proves actual current player before arming")
	var record: Dictionary = scheduler.replay_reservation_state(id)
	var timeline: Dictionary = arena.sequence.timeline
	var origin: float = record.adapter.timeline_origin_s
	for phase: String in ["lock", "first", "gap", "second", "recovery"]:
		var at: float = record.lock_from_s + 0.1
		match phase:
			"first": at = origin + timeline.slots[0].from_s + 0.05
			"gap": at = origin + (timeline.slots[0].end_s + timeline.slots[1].from_s) * 0.5
			"second": at = origin + timeline.slots[1].from_s + 0.05
			"recovery": at = record.active_until_s + 0.05
		await _until(scheduler, at)
		await _paused_barrier()
		var phase_snapshot: Dictionary = scheduler.snapshot_state(bindings)
		_expect(not phase_snapshot.is_empty() and scheduler.restore_state(_json(phase_snapshot), bindings), "quiet exact " + phase + " transport retains one armed whole-sequence lease: " + scheduler.last_snapshot_error)
		_expect(scheduler.replay_target(id) == arena.player and events.is_empty(), phase + " restore binds actual shared player and emits no event/cancellation")
		paused = false
	await _dispose(arena)

func _cancellations() -> void:
	var arena: Dictionary = await _arena(1)
	var scheduler = arena.scheduler
	scheduler.begin_encounter("standard", "cancel")
	var result: Dictionary = scheduler.request_replay(arena.source, arena.sequence, _response(arena), _context(arena))
	_expect(result.get("accepted", false), "cancel fixture obtains an actual preview: " + scheduler.last_error)
	if not result.get("accepted", false):
		await _dispose(arena)
		return
	var id: String = result.reservation_id
	var observed: Array = []
	scheduler.reservation_invalidated.connect(func(cancel_id: String, reason: String) -> void:
		var state: Dictionary = scheduler.replay_cancellation_state(cancel_id)
		observed.append(not state.is_empty() and state.reason == reason and state.cancelled_at_s == scheduler.get_clock() and scheduler.replay_reservation_state(cancel_id).is_empty())
	)
	_expect(scheduler.cancel(id, "fixture_cancel") and observed == [true], "cancel commits removed lease and exact tombstone BEFORE notifying a physical consumer")
	var tombstone: Dictionary = scheduler.replay_cancellation_state(id)
	_expect(not scheduler.request_replay(arena.source, arena.sequence, _response(arena), _context(arena)).get("accepted", false), "cancellation retains original source cooldown instead of refreshing replay")
	await _paused_barrier()
	var bindings: Dictionary = _bindings(arena)
	var snapshot: Dictionary = scheduler.snapshot_state(bindings)
	_expect(not snapshot.is_empty() and snapshot.reservations.is_empty() and snapshot.replay_cancellations.size() == 1, "canceled paused transport preserves inert exact provenance and retained cooldown: " + scheduler.last_snapshot_error)
	if not snapshot.is_empty():
		var stable: Dictionary = scheduler.replay_cancellation_state(id, bindings)
		_expect(stable.source_id == "source" and stable.response_actor_id == "hero" and _same(stable, snapshot.replay_cancellations[0]), "public stable tombstone exactly matches the paired scheduler envelope")
		_expect(scheduler.restore_state(_json(snapshot), bindings) and _same(tombstone, scheduler.replay_cancellation_state(id)), "quiet exact tagged JSON cancellation restore preserves original cancel clock/reason/source/actor/sequence")
		var bad: Dictionary = snapshot.duplicate(true)
		bad.replay_cancellations[0].sequence_id = "forged"
		_expect(_reject_unchanged(arena, bad), "canceled sequence identity cannot be rewritten independently")
		bad = snapshot.duplicate(true)
		bad.cooldowns[0].ready_s += 0.01
		_expect(_reject_unchanged(arena, bad), "canceled cooldown must agree exactly with retained immutable lease")
		bad = snapshot.duplicate(true)
		bad.replay_cancellations[0].cancelled_at_s = snapshot.clock_s + 1.0
		_expect(_reject_unchanged(arena, bad), "cancellation cannot be in the future of the paused scheduler clock")
		bad = snapshot.duplicate(true)
		bad.replay_cancellations.append(bad.replay_cancellations[0].duplicate(true))
		_expect(_reject_unchanged(arena, bad), "duplicate cancellation identities reject atomically")
		bad = snapshot.duplicate(true)
		bad.replay_cancellations[0].capture_collision_fingerprint = {}
		_expect(_reject_unchanged(arena, bad), "cancellation still requires the original typed capture-world fingerprint envelope")
		var tombstones_before: Dictionary = scheduler.get("_replay_cancellations").duplicate(true)
		for _read: int in range(3):
			scheduler.replay_cancellation_state(id)
			scheduler.replay_reservation_state(id)
			scheduler.snapshot_state(bindings)
		_expect(scheduler.get("_replay_cancellations") == tombstones_before and observed == [true], "pure getters and snapshot reads never age or re-emit cancellation history")
	paused = false
	await _until(scheduler, float(tombstone.cooldown_until_s) + 0.05)
	_expect(scheduler.replay_cancellation_state(id).is_empty() and scheduler.get("_replay_cancellations").is_empty(), "actual simulation expires tombstone after its retained cooldown")
	var request: Dictionary = scheduler.request_replay(arena.source, arena.sequence, _response(arena), _context(arena))
	_expect(request.get("accepted", false), "source may explicitly reserve a fresh exchange after cooldown; historical retirement belongs to parent capture gate")
	scheduler.end_encounter()
	_expect(scheduler.get("_replay_cancellations").is_empty() and scheduler.begin_encounter("standard", "new-epoch"), "encounter end clears bounded replay cancellation identity for the next epoch")
	await _dispose(arena)

func _pure_failure() -> void:
	var arena: Dictionary = await _arena(1)
	var scheduler = arena.scheduler
	scheduler.begin_encounter("standard", "pure")
	var ordinary: Dictionary = scheduler.request_attack(arena.other, _threat(arena), _response(arena))
	_expect(ordinary.get("accepted", false), "pure rejection fixture obtains a real ordinary lease")
	var events: Array = []
	scheduler.reservation_invalidated.connect(func(_id: String, reason: String) -> void: events.append(reason))
	arena.other.position.x += 0.1
	var before: Array = scheduler.get("_reservations").keys()
	var serial: int = scheduler.get("_serial")
	_expect(not scheduler.request_replay(arena.source, arena.sequence, _response(arena), _context(arena)).get("accepted", false) and scheduler.get("_reservations").keys() == before and events.is_empty() and scheduler.get("_serial") == serial, "failed compound preflight cannot prune a stale ordinary lease or allocate a serial")
	scheduler.end_encounter()
	scheduler.begin_encounter("standard", "actor-change")
	var request: Dictionary = scheduler.request_replay(arena.source, arena.sequence, _response(arena), _context(arena))
	if request.get("accepted", false):
		await _until(scheduler, request.reservation.lock_from_s)
		arena.player.slash(Vector3.RIGHT)
		arena.player.equip_item("WEAPON-03")
		_expect(not scheduler.commit_replay(request.reservation_id, _response(arena)).get("accepted", false) and not scheduler.replay_cancellation_state(request.reservation_id).is_empty(), "actual pending weapon swap at lock cancels rather than admitting future invented equipment")
	else:
		_expect(false, "pending weapon fixture preview: " + scheduler.last_error)
	await _dispose(arena)
	arena = await _arena(1)
	scheduler = arena.scheduler
	scheduler.begin_encounter("standard", "world-change")
	request = scheduler.request_replay(arena.source, arena.sequence, _response(arena), _context(arena))
	if request.get("accepted", false):
		var id: String = request.reservation_id
		var callbacks: Array = []
		scheduler.reservation_invalidated.connect(func(_id: String, reason: String) -> void: callbacks.append(reason))
		var wall: StaticBody3D = _box(arena.root, Vector3(0, 1, -4), Vector3(0.2, 2, 1))
		var table_before: Array = scheduler.get("_reservations").keys()
		_expect(not scheduler.replay_reservation_error(id).is_empty() and scheduler.replay_reservation_state(id).is_empty() and scheduler.get("_reservations").keys() == table_before and callbacks.is_empty(), "pure world guard rejects a new real wall without pruning or delivering callbacks")
		await _ticks(1)
		_expect(not scheduler.replay_cancellation_state(id).is_empty() and callbacks.size() == 1, "next actual simulation tick cancels changed-world replay exactly once")
		await _paused_barrier()
		var changed: Dictionary = scheduler.snapshot_state(_bindings(arena))
		_expect(not changed.is_empty() and scheduler.restore_state(_json(changed), _bindings(arena)), "canceled historical capture fingerprint may differ from current collision without licensing future attacks")
		wall.queue_free()
	else:
		_expect(false, "world guard fixture preview: " + scheduler.last_error)
	await _dispose(arena)


func _custody_and_contracts() -> void:
	var arena: Dictionary = await _arena(1)
	var scheduler = arena.scheduler
	var first: CinderPlayer = arena.player
	var second: CinderPlayer = Player.new()
	second.name = "SecondHero"
	arena.root.add_child(second)
	second.position = Vector3(-2, 0, -2)
	await _ticks(8)
	scheduler.begin_encounter("standard", "custody")
	var request: Dictionary = scheduler.request_replay(arena.source, arena.sequence, _response(arena), _context(arena))
	_expect(request.get("accepted", false), "actual player custody fixture reserves one shared hero")
	if not request.get("accepted", false):
		await _dispose(arena)
		return
	var id: String = request.reservation_id
	_expect(scheduler.replay_world_root(id) == arena.root, "pure admitted root accessor exposes actual world without weak references")
	await _until(scheduler, request.reservation.lock_from_s)
	arena.player = second
	_expect(not scheduler.commit_replay(id, _response(arena)).get("accepted", false) and not scheduler.replay_cancellation_state(id).is_empty(), "fresh valid response from a DIFFERENT actual CinderPlayer cannot replace the admitted actor at lock")
	arena.player = first
	scheduler.end_encounter()
	scheduler.begin_encounter("standard", "lock-missed")
	request = scheduler.request_replay(arena.source, arena.sequence, _response(arena), _context(arena))
	_expect(request.get("accepted", false), "missed-lock fixture starts a new typed preview")
	if request.get("accepted", false):
		id = request.reservation_id
		await _until(scheduler, request.reservation.active_from_s + 0.03)
		_expect(not scheduler.commit_replay(id, _response(arena)).get("accepted", false) and not scheduler.replay_cancellation_state(id).locked, "uncommitted warning cancels before first playback instead of silently arming at an old deadline")
	scheduler.end_encounter()
	scheduler.begin_encounter("standard", "source-moved")
	request = scheduler.request_replay(arena.source, arena.sequence, _response(arena), _context(arena))
	_expect(request.get("accepted", false), "stationary source guard fixture reserves actual tether")
	if request.get("accepted", false):
		id = request.reservation_id
		arena.source.position.x += 0.1
		var before: Array = scheduler.get("_reservations").keys()
		_expect(not scheduler.replay_reservation_error(id).is_empty() and scheduler.replay_world_root(id) == arena.root and scheduler.get("_reservations").keys() == before, "source displacement fails pure guard while admitted root remains available")
		await _ticks(1)
		_expect(not scheduler.replay_cancellation_state(id).is_empty(), "real tick cancels moved source and preserves cooldown identity")
		arena.source.position.x -= 0.1
	scheduler.end_encounter()
	scheduler.begin_encounter("standard", "floor-changed")
	request = scheduler.request_replay(arena.source, arena.sequence, _response(arena), _context(arena))
	_expect(request.get("accepted", false), "floor guard fixture reserves unchanged real world")
	if request.get("accepted", false):
		id = request.reservation_id
		arena.floor.disabled = true
		_expect(not scheduler.replay_reservation_error(id).is_empty(), "disabled actual floor invalidates captured route and response before dispatch")
		await _ticks(1)
		_expect(not scheduler.replay_cancellation_state(id).is_empty(), "floor invalidation cancels exactly the actual outstanding preview")
		arena.floor.disabled = false
	await _dispose(arena)


func _lock_boundary() -> void:
	var arena: Dictionary = await _arena(1)
	var scheduler = arena.scheduler
	scheduler.begin_encounter("standard", "lock-boundary")
	var request: Dictionary = scheduler.request_replay(arena.source, arena.sequence, _response(arena), _context(arena))
	_expect(request.get("accepted", false), "floating boundary fixture obtains a real exclusive preview")
	if not request.get("accepted", false):
		await _dispose(arena)
		return
	var id: String = request.reservation_id
	# Exact known 60Hz accumulation from the actual engine: commonly the 30th
	# tick is .49999999999999994. If a busy frame batches extra physical ticks,
	# reproduce that explicitly labeled arithmetic edge on scheduler clock only;
	# actual player records/geometry are never forged or moved for this test.
	await _ticks(30)
	var clock: float = scheduler.get_clock()
	var nominal_lock: float = request.reservation.lock_from_s
	if clock >= nominal_lock:
		var bytes := PackedByteArray()
		bytes.resize(8)
		bytes.encode_double(0, nominal_lock)
		bytes.encode_u64(0, bytes.decode_u64(0) - 1)
		clock = bytes.decode_double(0)
		scheduler.set("_clock", clock)
	_expect(clock < nominal_lock and nominal_lock - clock < 0.000000001, "fixture isolates the observed one-bit-before-warning clock boundary")
	_expect(not scheduler.commit_replay(id, _response(arena)).get("accepted", false) and not scheduler.replay_reservation_state(id).armed, "even one bit before the warning deadline cannot arm or create a negative cursor origin")
	await _until(scheduler, nominal_lock)
	var locked: Dictionary = scheduler.commit_replay(id, _response(arena))
	_expect(locked.get("accepted", false) and locked.reservation.adapter.timeline_origin_s >= 0.0 and locked.reservation.active_from_s > locked.reservation.lock_from_s, "first actual due tick commits a nonnegative origin and full unchanged locked lead")
	await _dispose(arena)

func _arena(count: int) -> Dictionary:
	var world := Node3D.new()
	world.name = "ReplaySchedulerWorld"
	root.add_child(world)
	var floor_body: StaticBody3D = _box(world, Vector3(0, -0.5, 0), Vector3(20, 1, 20))
	floor_body.name = "Floor"
	var player: CinderPlayer = Player.new()
	player.name = "Hero"
	world.add_child(player)
	var scheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	world.add_child(scheduler)
	await _ticks(8)
	var arena := {"root": world, "player": player, "scheduler": scheduler, "floor": floor_body.get_child(0)}
	var captured: Dictionary = await _record(arena, count)
	var sequence = Sequence.new()
	_expect(sequence.configure("crystalman/scheduler", captured, {"recognition_s": 0.12, "warning_s": 0.5, "locked_lead_s": 0.8, "inter_echo_gap_s": 0.7, "final_recovery_s": 2.0, "tether_position": player.global_position}, "replay/scheduler", 1), "actual sealed capture creates a canonical immutable plan")
	arena.sequence = sequence.snapshot_state()
	var source := Node3D.new()
	source.name = "Source"
	world.add_child(source)
	source.global_position = player.global_position
	var other := Node3D.new()
	other.name = "Other"
	world.add_child(other)
	arena.source = source
	arena.other = other
	arena.capture_fingerprint = scheduler.collision_fingerprint(world)
	return arena

func _record(arena: Dictionary, count: int) -> Dictionary:
	var capture = Capture.new()
	await _paused_barrier()
	_expect(capture.arm("replay/scheduler", count, 0, arena.player.get_world_action_clock()), "actual capture arms at a deferred paused boundary")
	paused = false
	arena.player.shells = 0
	arena.player.world_action_executed.connect(func(record: Dictionary) -> void:
		capture.ingest(record, "replay/scheduler")
		if record.kind == "dash":
			arena.player.slash(Vector3.RIGHT)
	)
	for index: int in range(count):
		arena.player.request_dash(Vector3.RIGHT if index == 0 else Vector3.LEFT)
		for _tick: int in range(50):
			await _ticks(1)
			capture.advance(arena.player.get_world_action_clock())
	await _paused_barrier()
	capture.advance(arena.player.get_world_action_clock())
	var result: Dictionary = capture.snapshot_state()
	_expect(capture.slots().size() == count and not result.is_empty(), "fixture seals the required actual completed empty-ammo primary combinations")
	paused = false
	return result

func _response(arena: Dictionary) -> Dictionary:
	var directions: Array[Vector3] = [Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3.RIGHT]
	for direction: Vector3 in [Vector3(-1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, -1), Vector3(1, 0, 1)]:
		directions.append(direction.normalized())
	var result: Dictionary = arena.player.get_threat_response_state()
	result.merge({"world_revision": 1, "recognition_s": 0.12, "attack_input_margin_s": 0.02, "escape_directions": directions, "return_directions": directions, "floor_regions": [{"collision": arena.floor, "safe_rect": Rect2(-10, -10, 20, 20)}]})
	return result

func _context(arena: Dictionary) -> Dictionary:
	return {"world_root": arena.root, "source_epoch": "replay/scheduler", "generation": 1, "capture_collision_fingerprint": arena.capture_fingerprint}

func _bindings(arena: Dictionary) -> Dictionary:
	return {"world_root": arena.root, "owners": {"source": arena.source, "other": arena.other}, "actors": {"hero": arena.player}, "floors": {"floor": {"collision": arena.floor, "safe_rect": Rect2(-10, -10, 20, 20)}}}

func _threat(arena: Dictionary) -> Dictionary:
	var raw := {"raw_damage": 5.0, "max_hp": 20.0, "move_speed": 0.0, "windup_s": 2.0, "lock_s": 0.2, "active_s": 0.1, "recovery_s": 3.0, "attack_interval_s": 4.0}
	var role: Dictionary = Difficulty.new().resolve_role(raw, "standard", {"windup_s": 0.5, "lock_s": 0.2, "recovery_s": 1.0})
	return {"role": role, "geometry": Geometry.circle(Vector3(8, 0, 8), 0.3), "opening_position": arena.player.global_position, "source_stationary": true, "opening_stationary": true, "cooldown_remaining_s": 0.0}

func _tracking(arena: Dictionary) -> Dictionary:
	var threat: Dictionary = _threat(arena)
	threat.geometry = Geometry.lane(arena.other.global_position, arena.other.global_position + Vector3.RIGHT * 2.0, 0.4)
	threat.opening_position = arena.other.global_position
	return threat

func _reject_unchanged(arena: Dictionary, bad: Dictionary) -> bool:
	var before: Dictionary = arena.scheduler.snapshot_state(_bindings(arena))
	return not arena.scheduler.restore_state(bad, _bindings(arena)) and _same(before, arena.scheduler.snapshot_state(_bindings(arena)))

func _next_float(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes.encode_u64(0, bytes.decode_u64(0) + 1)
	return bytes.decode_double(0)

func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = ExactJson.stringify(left)
	return not encoded.is_empty() and encoded == ExactJson.stringify(right)

func _json(value: Dictionary) -> Dictionary:
	var decoded: Dictionary = ExactJson.parse(ExactJson.stringify(value))
	return decoded.value if decoded.get("accepted", false) and decoded.value is Dictionary else {}

func _player_snapshot(player: CinderPlayer) -> Dictionary:
	await _paused_barrier()
	var result: Dictionary = player.snapshot_state()
	paused = false
	return result

func _until(scheduler: Node3D, clock_s: float) -> void:
	paused = false
	for _tick: int in range(1000):
		if scheduler.get_clock() >= clock_s:
			return
		await _ticks(1)
	_expect(false, "bounded fixture reached required scheduler time")

func _paused_barrier() -> void:
	paused = true
	await process_frame

func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame

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
