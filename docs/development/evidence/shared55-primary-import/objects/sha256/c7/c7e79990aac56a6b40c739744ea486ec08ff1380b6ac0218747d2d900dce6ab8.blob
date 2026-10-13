extends SceneTree
## Real shared Player publications only. This validates capture custody and
## retirement, never physical playback, safety witnesses or boss fairness.

const Player = preload("res://scripts/player.gd")
const Gate = preload("res://scripts/combat/replay_capture_gate.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const AUTHORED: Dictionary = {"recognition_s": 0.35, "warning_s": 0.9, "locked_lead_s": 1.1, "inter_echo_gap_s": 0.8, "final_recovery_s": 1.6, "tether_position": Vector3(0.3, 0.0, -0.4)}

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_ensure_owned_uids()
	await _test_real_nested_one_slot_and_retirement()
	await _test_two_slots_and_new_generation()
	await _test_pending_motion_restore_and_clock_drift()
	await _test_actual_publication_inside_consumer()
	await _test_unpublished_actor_changes_inside_consumer()
	print("Replay capture gate smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_real_nested_one_slot_and_retirement() -> void:
	var arena: Dictionary = await _arena(true)
	var player: CinderPlayer = arena.player
	var gate = arena.gate
	player.shells = 0
	# Connected before gate: the actual primary publishes recursively before
	# this gate's outer dash notification. The authoritative history is FIFO.
	player.world_action_executed.connect(func(record: Dictionary) -> void:
		if record.kind == "dash": player.slash(Vector3(0.37, 0.0, -0.91))
	)
	await _pause()
	_expect(gate.configure("crystalman", "hero", player, "attempt-a/capture"), "bind exact ready actual shared actor at paused deferred barrier: " + gate.last_error)
	_expect(not gate.configure("another", "hero", player, "attempt-a/capture"), "immutable custodian cannot bind another owner")
	_expect(gate.arm(1), "stable real grounded actor arms one private slot: " + gate.last_error)
	var arm_snapshot: Dictionary = gate.snapshot_state()
	_expect(not arm_snapshot.is_empty(), "armed paired snapshot validates before any samples: " + gate.last_snapshot_error)
	paused = false
	_expect(not gate.arm(1), "running actor cannot arm at an arbitrary historical clock")
	_expect(player.request_dash(Vector3.RIGHT), "real Player accepts dash into actual wall")
	await _ticks(36)
	await _pause()
	_expect(gate.synchronize(), "all real contiguous publications drain before exact clock advancement: " + gate.last_error)
	var source: Dictionary = player.snapshot_state()
	var current: Dictionary = gate.snapshot_state()
	_expect(not current.is_empty() and current.capture.slots.size() == 1 and current.capture.cursor == 2 and source.world_actions.sequence == 2, "nested actual dash and primary seal one FIFO slot: " + gate.last_snapshot_error)
	if current.is_empty() or current.capture.slots.size() != 1:
		await _dispose(arena)
		return
	var slot: Dictionary = current.capture.slots[0]
	_expect(slot.dash.blocked and slot.dash.collision_shortened and slot.dash.distance > 0.0 and slot.blast.is_empty(), "wall-shortened positive actual route plus empty-ammo primary is retained")
	_expect(_same(slot.dash, source.world_actions.history[0]) and _same(slot.primary, source.world_actions.history[1]), "captured canonical samples exactly equal bound actor's authoritative history")
	var before_rejection: Dictionary = gate.snapshot_state()
	var bad_authored: Dictionary = AUTHORED.duplicate(true)
	bad_authored.locked_lead_s = 0.0
	_expect(gate.prepare_sequence("phase-one", bad_authored).is_empty() and _same(before_rejection, gate.snapshot_state()), "invalid preparation never retires or alters private capture")
	var plan: Dictionary = gate.prepare_sequence("phase-one", AUTHORED)
	_expect(not plan.is_empty() and gate.state().prepared and gate.state().capture.retired.is_empty(), "complete current frozen native capture prepares without consumption: " + gate.last_error)
	if plan.is_empty():
		await _dispose(arena)
		return
	_expect(_same(plan.capture_snapshot, current.capture), "sequence carries unchanged original one-slot world route and records")
	var prepared_unit: Dictionary = _roundtrip({"player": source, "gate": gate.snapshot_state()})
	_expect(not prepared_unit.is_empty() and gate.snapshot_error(prepared_unit.gate, prepared_unit.player).is_empty(), "exact tagged native actor/capture/proposal aggregate transports without clock drift")
	_expect(gate.restore_state(prepared_unit.gate, prepared_unit.player) and gate.state().prepared, "idempotent exact current prepared restore retains original proposal without new authority")
	var forged: Dictionary = plan.duplicate(true)
	forged.timeline.slots[0].events[0].at_s = _next_float(float(forged.timeline.slots[0].events[0].at_s))
	_expect(not gate.consume_sequence(forged).accepted and gate.state().capture.retired.is_empty() and gate.state().prepared, "one-bit derived timing forgery cannot consume private proposal")
	forged = plan.duplicate(true)
	forged.capture_snapshot.slots[0].dash.path[0].position[0] += 0.01
	_expect(not gate.consume_sequence(forged).accepted and gate.state().capture.retired.is_empty(), "reconstructed altered historical world path cannot authorize consumption")
	var callbacks: Array[Dictionary] = []
	gate.sequence_retired.connect(func(emitted: Dictionary, receipt: Dictionary) -> void:
		callbacks.append({"already_retired": gate.state().capture.retired.duplicate(), "duplicate": gate.consume_sequence(emitted), "prepared": gate.prepare_sequence("callback", AUTHORED), "snapshot": gate.snapshot_state(), "arm": gate.arm(1), "restore": gate.restore_state(prepared_unit.gate, prepared_unit.player)})
		emitted.capture_snapshot.slots.clear()
		receipt.slot_ids.clear()
	)
	var consumed: Dictionary = gate.consume_sequence(plan)
	_expect(consumed.accepted and callbacks.size() == 1 and callbacks[0].already_retired == [1], "whole FIFO retirement commits before consumer callback")
	_expect(not callbacks[0].duplicate.accepted and callbacks[0].prepared.is_empty() and callbacks[0].snapshot.is_empty() and not callbacks[0].arm and not callbacks[0].restore, "callback cannot reauthorize, arm, prepare, restore or snapshot the consumed capture")
	_expect(consumed.sequence.capture_snapshot.slots.size() == 1 and consumed.retirement.slot_ids == [1] and gate.retirement_state().slot_ids == [1], "external callback mutation cannot corrupt committed retirement or returned sequence")
	_expect(_same(source, player.snapshot_state()) and player.shells == 0, "preparation and complete retirement leave actual player actions/resources/clocks untouched")
	_expect(not gate.consume_sequence(plan).accepted and gate.prepare_sequence("historical", AUTHORED).is_empty(), "duplicate or consumed historical capture cannot prepare/consume again")
	var consumed_unit: Dictionary = _roundtrip({"player": player.snapshot_state(), "gate": gate.snapshot_state()})
	_expect(not consumed_unit.is_empty() and consumed_unit.gate.retired_generation == 1 and consumed_unit.gate.capture.retired == [1], "exact consumed aggregate retains retired generation, FIFO receipt and original sequence")
	_expect(not gate.restore_state(prepared_unit.gate, prepared_unit.player) and gate.state().capture.retired == [1], "existing actual custodian rejects pre-consume rewind even at identical actor clock")
	_expect(gate.restore_state(consumed_unit.gate, consumed_unit.player) and callbacks.size() == 1, "idempotent quiet exact consumed restore emits no second consumer")
	var pause_before: Dictionary = gate.snapshot_state()
	await _ticks_paused(4)
	_expect(_same(pause_before, gate.snapshot_state()) and _same(source, player.snapshot_state()), "pause freezes actor, capture clock and retirement together")
	await _test_restoration_context(consumed_unit, plan)
	await _dispose(arena)


func _test_restoration_context(unit: Dictionary, old_plan: Dictionary) -> void:
	var recipient: Dictionary = await _arena(true)
	await _pause()
	var player: CinderPlayer = recipient.player
	var gate = recipient.gate
	_expect(gate.configure("crystalman", "hero", player, "attempt-a/capture"), "fresh whole-unit recipient binds same authored owner/actor/epoch")
	var empty_before: Dictionary = gate.state()
	_expect(gate.snapshot_error(unit.gate, unit.player).is_empty() and _same(empty_before, gate.state()), "pure aggregate prevalidation uses saved actor context without mutating fresh live actor")
	_expect(not gate.restore_state(unit.gate, unit.player) and _same(empty_before, gate.state()), "gate commit before actual saved-player restoration rejects atomically")
	var moved: Dictionary = unit.player.duplicate(true)
	moved.motion.position[2] += 0.25
	_expect(player.snapshot_error(moved).is_empty() and not gate.snapshot_error(unit.gate, moved).is_empty(), "individually legal cross-forged saved actor pose fails exact whole-player binding")
	for mutation: String in ["epoch", "clock", "watermark", "receipt", "sequence", "unknown", "reopened"]:
		var bad: Dictionary = unit.gate.duplicate(true)
		match mutation:
			"epoch": bad.source_epoch = "another-attempt"
			"clock": bad.clock_s = _next_float(float(bad.clock_s))
			"watermark": bad.retired_generation = 0
			"receipt": bad.retirement.slot_ids = []
			"sequence": bad.consumed_sequence.timeline.tether_until_s = _next_float(float(bad.consumed_sequence.timeline.tether_until_s))
			"unknown": bad.historical_authorization = true
			"reopened":
				bad.capture.allocated = 0
				bad.capture.retired = []
		_expect(not gate.snapshot_error(bad, unit.player).is_empty() and not gate.restore_state(bad, unit.player) and _same(empty_before, gate.state()), "malformed " + mutation + " rejects before private capture/retirement commit")
	_expect(player.restore_state(unit.player), "actual shared player independently restores exact saved unit: " + player.last_snapshot_error)
	var emissions: Array[int] = []
	gate.sequence_retired.connect(func(_sequence: Dictionary, _receipt: Dictionary) -> void: emissions.append(1))
	_expect(gate.restore_state(unit.gate, unit.player) and emissions.is_empty() and _same(unit.gate, gate.snapshot_state()), "fresh paired gate restore commits exactly and quietly after actual actor restore: " + gate.last_snapshot_error)
	_expect(not gate.consume_sequence(old_plan).accepted and gate.prepare_sequence("old-capture", AUTHORED).is_empty() and gate.state().capture.retired == [1], "fresh consumed retry preserves retirement and cannot regrant historical slot")
	await _dispose(recipient)


func _test_two_slots_and_new_generation() -> void:
	paused = false
	var arena: Dictionary = await _arena()
	var player: CinderPlayer = arena.player
	var gate = arena.gate
	await _pause()
	_expect(gate.configure("parent-two", "hero", player, "attempt-two/capture") and gate.arm(2), "two-slot parent owns exact same live source epoch")
	paused = false
	_expect(player.request_dash(Vector3.RIGHT), "first real two-slot dash executes")
	await _ticks(18)
	player.slash(Vector3.FORWARD)
	# Both are real public actor calls. Deliver the optional followup inside
	# the actual clock window instead of assuming one render await advances
	# exactly one physics tick under headless load/catch-up.
	var ammo: int = player.shells
	player.blast(Vector3.RIGHT)
	await _ticks(22)
	await _pause()
	_expect(gate.state().capture.sealed == 1 and player.shells == ammo - 1, "actual optional blast belongs to first captured slot without manufactured resource changes")
	var incomplete: Dictionary = gate.snapshot_state()
	_expect(gate.prepare_sequence("subset", AUTHORED).is_empty() and _same(incomplete, gate.snapshot_state()), "one sealed slot cannot bypass configured two-slot whole-generation FIFO")
	paused = false
	_expect(player.request_dash(Vector3.LEFT), "second real combination starts at actual current landing")
	await _ticks(18)
	player.slash(Vector3(0.4, 0.0, -0.9))
	await _ticks(22)
	await _pause()
	var plan: Dictionary = gate.prepare_sequence("phase-two", AUTHORED)
	_expect(not plan.is_empty() and plan.capture_snapshot.slots.size() == 2, "two actual sealed slots prepare complete immutable sequence: " + gate.last_error)
	if plan.is_empty():
		await _dispose(arena)
		return
	_expect(not plan.capture_snapshot.slots[0].blast.is_empty() and plan.capture_snapshot.slots[1].blast.is_empty(), "actual optional blast then ordinary-primary-only source records retain independent footprints")
	var actor_before: Dictionary = player.snapshot_state()
	var result: Dictionary = gate.consume_sequence(plan)
	_expect(result.accepted and result.retirement.slot_ids == [1, 2] and gate.state().capture.retired == [1, 2] and gate.state().capture.sealed == 0, "both selected slots retire atomically once in FIFO order")
	_expect(_same(actor_before, player.snapshot_state()), "complete two-slot consumption never executes or reconstructs world actions")
	_expect(gate.arm(1) and gate.state().capture.generation == 2 and gate.retirement_state().generation == 1, "explicit new capture generation preserves previous retirement receipt")
	_expect(not gate.consume_sequence(plan).accepted and gate.state().capture.allocated == 0, "old sealed sequence cannot consume freshly armed new generation")
	_expect(gate.cancel("visible phase interruption") and not gate.state().capture.armed and gate.state().retired_generation == 2, "visible cancellation retires partial generation without clearing prior consumed receipt")
	var cancelled: Dictionary = _roundtrip({"player": player.snapshot_state(), "gate": gate.snapshot_state()})
	_expect(not cancelled.is_empty() and gate.snapshot_error(cancelled.gate, cancelled.player).is_empty(), "cancelled generation and previous complete retirement serialize coherently")
	_expect(gate.arm(1) and gate.state().capture.generation == 3, "later new generation is distinct from consumed and cancelled captures")
	await _dispose(arena)


func _test_pending_motion_restore_and_clock_drift() -> void:
	paused = false
	var arena: Dictionary = await _arena()
	var player: CinderPlayer = arena.player
	var gate = arena.gate
	await _pause()
	_expect(gate.configure("pending-parent", "hero", player, "pending-attempt/capture") and gate.arm(1), "pending fixture arms a real stable source")
	paused = false
	player.request_dash(Vector3.BACK)
	await _ticks(2)
	await _pause()
	_expect(not gate.arm(1), "actual unfinished motion cannot be rearmed through historical stopped state")
	var unit: Dictionary = _roundtrip({"player": player.snapshot_state(), "gate": gate.snapshot_state()})
	_expect(not unit.is_empty() and not unit.player.world_actions.pending_dash.is_empty() and unit.gate.capture.dash_candidate.is_empty(), "pending actual motion saves whole actor/capture pair before completion publication")
	if unit.is_empty():
		await _dispose(arena)
		return
	var recipient: Dictionary = await _arena()
	await _pause()
	var restored_player: CinderPlayer = recipient.player
	var restored_gate = recipient.gate
	_expect(restored_gate.configure("pending-parent", "hero", restored_player, "pending-attempt/capture") and restored_gate.snapshot_error(unit.gate, unit.player).is_empty(), "pending saved actor context prevalidates on fresh exact source without live pose mutation")
	_expect(restored_player.restore_state(unit.player) and restored_gate.restore_state(unit.gate, unit.player), "actual pending actor then quiet gate restore keeps exact clock/cursor: " + restored_gate.last_snapshot_error)
	# Dispose old actor before resuming the saved source: no duplicate actor owns
	# this encounter unit. Only the receiving actual Player publishes onward.
	await _dispose(arena)
	paused = false
	await _ticks(20)
	_expect(restored_player.get_world_action_records().size() == 1 and restored_gate.state().capture.cursor == 1 and restored_gate.state().capture.has_dash_candidate, "restored actual dash completes exactly once and joins contiguous source stream")
	restored_player.slash(Vector3.RIGHT)
	await _ticks(2)
	await _pause()
	var pending: Dictionary = restored_gate.snapshot_state()
	_expect(pending.capture.pending.size() == 1 and restored_gate.prepare_sequence("too-early", AUTHORED).is_empty() and restored_gate.state().capture.retired.is_empty(), "unsealed full combo window cannot authorize sequence or retirement")
	paused = false
	await _ticks(22)
	await _pause()
	var proposal: Dictionary = restored_gate.prepare_sequence("after-pending", AUTHORED)
	_expect(not proposal.is_empty(), "actual clock seals pending restored combination before preparation: " + restored_gate.last_error)
	paused = false
	await _ticks(1)
	await _pause()
	_expect(not restored_gate.state().prepared and not restored_gate.consume_sequence(proposal).accepted and restored_gate.state().capture.retired.is_empty(), "real source-clock advance invalidates frozen proposal without retiring original capture")
	proposal = restored_gate.prepare_sequence("after-pending", AUTHORED)
	_expect(not proposal.is_empty() and restored_gate.consume_sequence(proposal).accepted, "fresh current-clock reproof can consume same unchanged current sealed records once")
	await _dispose(recipient)


func _arena(with_wall: bool = false) -> Dictionary:
	# Preserve a paused old aggregate while building its candidate. Physics
	# frames still register shapes; paused actor clocks never advance here.
	var world := Node3D.new()
	root.add_child(world)
	_box(world, Vector3(0, -0.5, 0), Vector3(40, 1, 40))
	if with_wall: _box(world, Vector3(1.5, 1, 0), Vector3(0.3, 2, 10))
	var player: CinderPlayer = Player.new()
	world.add_child(player)
	var gate = Gate.new()
	world.add_child(gate)
	await _ticks(5)
	return {"root": world, "player": player, "gate": gate}


func _test_actual_publication_inside_consumer() -> void:
	paused = false
	var arena: Dictionary = await _arena()
	var player: CinderPlayer = arena.player
	var gate = arena.gate
	await _pause()
	_expect(gate.configure("callback-parent", "hero", player, "callback-attempt/capture") and gate.arm(1), "callback failure fixture binds real stable actor")
	paused = false
	player.request_dash(Vector3.RIGHT)
	await _ticks(18)
	player.slash(Vector3.FORWARD)
	await _ticks(24)
	await _pause()
	var plan: Dictionary = gate.prepare_sequence("callback-sequence", AUTHORED)
	_expect(not plan.is_empty(), "actual callback failure fixture has complete sealed current sequence: " + gate.last_error)
	var faults: Array[String] = []
	gate.gate_failed.connect(func(reason: String) -> void: faults.append(reason))
	gate.sequence_retired.connect(func(_sequence: Dictionary, _receipt: Dictionary) -> void: player.slash(Vector3.LEFT))
	var result: Dictionary = gate.consume_sequence(plan)
	_expect(result.accepted and not result.reason.is_empty() and faults.size() == 1 and player.get_world_action_records().size() == 3, "improper actual callback action reports visible failure without manufacturing world actions")
	_expect(gate.state().capture.retired == [1] and gate.snapshot_state().is_empty() and not gate.consume_sequence(plan).accepted, "changed frozen actor fails closed while retirement stays committed once")
	_expect(gate.cancel("visible consumer violation") and gate.state().fault.is_empty() and gate.state().retired_generation == 1, "deferred visible cancellation clears fault without resurrecting consumed capture")
	await _dispose(arena)


func _test_unpublished_actor_changes_inside_consumer() -> void:
	for mutation: String in ["damage", "deferred_dash", "buffered_dash", "equipment", "unpause", "actor_queued"]:
		paused = false
		var arena: Dictionary = await _arena()
		var player: CinderPlayer = arena.player
		var gate = arena.gate
		await _pause()
		_expect(gate.configure("boundary-parent", "hero", player, "boundary-" + mutation) and gate.arm(1), mutation + " binds a real stable actor")
		paused = false
		_expect(player.request_dash(Vector3.RIGHT), mutation + " records an actual first dash")
		await _ticks(18)
		player.slash(Vector3.FORWARD)
		await _ticks(24)
		if mutation == "buffered_dash":
			# The generation is full: this later real completion only advances
			# its publication cursor. Its normal cooldown still permits a
			# stopped actor but queues the callback's subsequent dash request.
			_expect(player.request_dash(Vector3.BACK), "buffered regression starts an actual later dash")
			await _ticks(14)
		await _pause()
		var plan: Dictionary = gate.prepare_sequence("boundary-sequence", AUTHORED)
		_expect(not plan.is_empty(), mutation + " prepares the current sealed whole sequence: " + gate.last_error)
		if plan.is_empty():
			await _dispose(arena)
			continue
		var before: Dictionary = player.snapshot_state()
		var prepared: Dictionary = gate.snapshot_state()
		var records: Array = before.world_actions.history
		var observed: Array[Dictionary] = []
		var faults: Array[String] = []
		var reentrant: Array[Dictionary] = []
		gate.gate_failed.connect(func(reason: String) -> void:
			faults.append(reason)
			reentrant.append({"retired": gate.state().capture.retired, "consume": gate.consume_sequence(plan), "prepare": gate.prepare_sequence("failed-callback", AUTHORED), "arm": gate.arm(1), "cancel": gate.cancel("reentrant cancellation"), "discard": gate.discard_preparation(), "sync": gate.synchronize(), "snapshot": gate.snapshot_state(), "validate": gate.snapshot_error(prepared, before), "restore": gate.restore_state(prepared, before)})
		)
		gate.sequence_retired.connect(func(_sequence: Dictionary, _receipt: Dictionary) -> void:
			match mutation:
				"damage":
					player.take_damage(1.0, Vector3.ZERO)
					observed.append({"changed": player.hp < float(before.resources.hp)})
				"deferred_dash":
					var started: bool = player.request_dash(Vector3.LEFT)
					observed.append({"changed": started and float(player.get_threat_response_state().motion.dash_left_s) > 0.0})
				"buffered_dash":
					var started: bool = player.request_dash(Vector3.LEFT)
					observed.append({"changed": not started and not (player.get_threat_response_state().motion.queued_dash as Vector3).is_zero_approx()})
				"equipment":
					observed.append({"changed": player.equip_item("WEAPON-02") and player.equipment.snapshot().weapon == "WEAPON-02"})
				"unpause":
					paused = false
					observed.append({"changed": not paused})
				"actor_queued":
					player.queue_free()
					observed.append({"changed": player.is_queued_for_deletion()})
		)
		var result: Dictionary = gate.consume_sequence(plan)
		_expect(observed.size() == 1 and observed[0].changed and _same(records, _encoded_history(player)), mutation + " actually changes the frozen boundary without a completed world-action publication")
		_expect(result.accepted and not result.reason.is_empty() and faults.size() == 1 and faults[0] == result.reason and gate.state().capture.retired == [1] and gate.state().retired_generation == 1, mutation + " reports one visible fault after irreversible whole retirement")
		_expect(reentrant.size() == 1 and reentrant[0].retired == [1] and not reentrant[0].consume.accepted and reentrant[0].prepare.is_empty() and not reentrant[0].arm and not reentrant[0].cancel and not reentrant[0].discard and not reentrant[0].sync and reentrant[0].snapshot.is_empty() and not reentrant[0].validate.is_empty() and not reentrant[0].restore, mutation + " holds the transaction guard through gate_failed reentrancy")
		_expect(not gate.consume_sequence(plan).accepted and gate.state().capture.retired == [1], mutation + " cannot regrant retired samples after the callback fault")
		await _dispose(arena)


func _encoded_history(player: CinderPlayer) -> Array:
	var records: Array = []
	for record: Dictionary in player.get_world_action_records():
		records.append(Player.encode_world_action_record(record, player.get_world_action_clock()))
	return records


func _box(parent: Node3D, point: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.position = point


func _pause() -> void:
	paused = true
	await process_frame


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame


func _ticks_paused(count: int) -> void:
	for _index: int in range(count): await process_frame


func _dispose(arena: Dictionary) -> void:
	arena.root.queue_free()
	await process_frame


func _roundtrip(value: Dictionary) -> Dictionary:
	var wire: String = Exact.stringify(value)
	var decoded: Dictionary = Exact.parse(wire)
	return decoded.value if decoded.accepted and decoded.value is Dictionary else {}


func _same(left: Variant, right: Variant) -> bool:
	var wire: String = Exact.stringify(left)
	return not wire.is_empty() and wire == Exact.stringify(right)


func _next_float(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes.encode_u64(0, bytes.decode_u64(0) + 1)
	return bytes.decode_double(0)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)


func _ensure_owned_uids() -> void:
	for path: String in ["res://scripts/combat/replay_capture_gate.gd.uid", "res://tests/replay_capture_gate_smoke.gd.uid"]:
		if not FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_line(ResourceUID.id_to_text(ResourceUID.create_id()))
