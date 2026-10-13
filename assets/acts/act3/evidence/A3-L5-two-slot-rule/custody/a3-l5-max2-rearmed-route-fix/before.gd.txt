extends "res://tests/acts/act3/crystalman_rule_room_smoke.gd"
## DRAFT V2, UNEXECUTED focused two-slot extension with original native recovery.
## Uses the same routed input, post-actor barrier and actual completed observer.
## No whole-parent transport, campaign phase transition or production art claim.

const TwoSlotRoomPath: String = "res://scenes/acts/act3/a3_l5_crystalman_two_slot_rule_room.tscn"

var _expected_slots: Array[Dictionary] = []
var _opportunities: Array[Dictionary] = []
var _trace_scope: String = "capture"
var _trace_segment: Dictionary = {}
var _trace_proof: Dictionary = {}
var _trace_lease: Dictionary = {}
var _completed_prefix: Array = []


func _room_path() -> String:
	return TwoSlotRoomPath


func _expected_capture_slots() -> int:
	return 2


func _run() -> void:
	# The inherited four response rows are mandatory in this new focused case.
	_clock_join_only = true
	if await _open():
		await _two_slot_ordinary_case()
	await _close()
	if _failures == 0 and await _open():
		await _invalid_second_slot_and_rearm_case()
	await _close()
	print("Crystalman two-slot rule draft: %d checks; failures: %d; actual post-actor ticks: %d. No whole-parent transport/art/campaign phase acceptance." % [_checks, _failures, _ticks])
	quit(0 if _failures == 0 else 1)


func _two_slot_ordinary_case() -> bool:
	_expected_slots.clear()
	_opportunities.clear()
	_completed_prefix.clear()
	if not await _record_combo(Vector3.BACK, 1): return false
	var one: Dictionary = _gate.state().capture
	if not _expect(one.max_slots == 2 and one.allocated == 1 and one.sealed == 1 and one.pending == 0 and _room.call("state").joins == 0 and _scheduler.reservations().is_empty() and _gate.retirement_state().is_empty() and _room.get("playback") == null, "one sealed recording never becomes a partial two-slot lease/retirement/replay"): return false
	if not await _record_combo(Vector3.FORWARD, 2): return false
	return await _resolve_two_slots(1, true)


func _record_combo(direction: Vector3, slot_number: int) -> bool:
	_trace_scope = "capture_slot_" + str(slot_number)
	_trace_segment.clear()
	_trace_proof.clear()
	_trace_lease.clear()
	var sequence_before: int = _latest_sequence()
	var error: String = _swipe(direction)
	if not _expect(error.is_empty(), "slot %d starts a genuine routed voluntary dash" % slot_number, error): return false
	if not await _wait_capture_dash(sequence_before): return false
	if not await _wait_stable(): return false
	var records: Array[Dictionary] = _hero.get_world_action_records(sequence_before)
	if not _expect(records.size() == 1 and records[0].kind == "dash" and records[0].distance > 0.0 and not records[0].collision_shortened and not records[0].movement_damage and records[0].equipment_ids == _kit, "slot %d uses the actual complete harmless route and resolved kit" % slot_number): return false
	var dash: Dictionary = Player.encode_world_action_record(records[0], _hero.get_world_action_clock())
	var release: Vector2 = _game.call("get_aim_anchor_normalized")
	error = _tap(Vector3.RIGHT)
	records = _hero.get_world_action_records(sequence_before)
	if not _expect(error.is_empty() and records.size() == 2 and records[1].kind == "primary" and _game.call("get_aim_anchor_normalized") == release and _room.call("state").tether_hits == 0, "slot %d next real primary retains the routed release and cannot hit closed tether" % slot_number, error): return false
	var primary: Dictionary = Player.encode_world_action_record(records[1], _hero.get_world_action_clock())
	_expected_slots.append({"dash": dash, "primary": primary})
	print("READONLY CAPTURE PRIMARY JOIN " + var_to_str({"slot_number": slot_number, "player_clock_s": _hero.get_world_action_clock(), "scheduler_clock_s": _scheduler.get_clock(), "motion": _hero.get_threat_response_state().motion, "committed_dash": _hero.get_committed_dash_state(), "sequence_before": sequence_before, "new_actual_records": records, "gate": _gate.state()}))
	# The final slot may already join at the next deferred barrier; do not use
	# an intermediate consumed Gate state as a fabricated sealed observation.
	if slot_number == 1: return await _wait_sealed_one()
	return true


func _wait_capture_dash(sequence_before: int) -> bool:
	for _i: int in range(60):
		if float(_hero.get_threat_response_state().motion.dash_left_s) == 0.0:
			var records: Array[Dictionary] = _hero.get_world_action_records(sequence_before)
			_trace_public_swipe("actual_capture_completed", sequence_before)
			return _expect(records.size() == 1 and records[0].kind == "dash" and _hero.is_on_floor(), "captured dash publishes only after the actual final physics tick")
		if not await _tick(): return false
	return _expect(false, "bounded actual capture dash completion")


func _wait_sealed_one() -> bool:
	for _i: int in range(180):
		var capture: Dictionary = _gate.state().capture
		if capture.sealed == 1 and capture.pending == 0: return true
		if not await _tick(): return false
	return _expect(false, "first actual primary combo settles before next voluntary recording", str(_gate.state()))


func _resolve_two_slots(expected_generation: int, pause_active: bool) -> bool:
	if not await _wait_phase("warning", 240): return false
	if not _check_two_join(expected_generation): return false
	if not await _pause_resume("two-slot warning"): return false
	var playback: CinderReplayPlayback = _room.get("playback") as CinderReplayPlayback
	playback.event_dispatched.connect(_on_replay_event)
	if not await _wait_locked(): return false
	var state: Dictionary = _room.call("state")
	var proof: Dictionary = state.proof
	var escapes: Array[Dictionary] = []
	for segment: Dictionary in proof.get("path", []):
		if segment.kind in ["first_escape_dash", "second_escape_dash"]: escapes.append(segment)
	var cooldown: float = float(_hero.get_threat_response_state().stats.dash_cooldown)
	if not _expect(proof.get("accepted", false) and proof.get("at_lock", false) and proof.get("slot_count", 0) == 2 and proof.get("event_count", 0) == 2 and not proof.get("uses_blast", true) and not proof.get("uses_invulnerability", true) and escapes.size() == 2 and escapes[0].kind == "first_escape_dash" and escapes[1].kind == "second_escape_dash" and float(escapes[1].start_s) >= float(escapes[0].start_s) + cooldown, "fresh actual lock jointly proves both finite events, genuine second escape, cooldown and ordinary-primary full recovery"): return false
	if not await _follow_proof(proof, pause_active): return false
	return await _sever_two_with_actual_recovery()


func _check_two_join(expected_generation: int) -> bool:
	var state: Dictionary = _room.call("state")
	var slots: Array = state.sequence.capture_snapshot.slots
	var timeline: Array = state.sequence.timeline.slots
	var projection: Array = state.projection.events
	var receipt: Dictionary = state.join_receipt
	var playback: CinderReplayPlayback = _room.get("playback") as CinderReplayPlayback
	var exact_slots: bool = slots.size() == 2 and timeline.size() == 2 and projection.size() == 2 and _expected_slots.size() == 2
	if exact_slots:
		for index: int in range(2):
			var original: Dictionary = _expected_slots[index]
			var slot: Dictionary = slots[index]
			var event: Dictionary = timeline[index].events[0]
			exact_slots = exact_slots and slot.slot_id == index + 1 and _wire_exact(slot.dash, original.dash) and _wire_exact(slot.primary, original.primary) and slot.blast.is_empty() and timeline[index].events.size() == 1 and event.kind == "primary" and event.record_sequence == original.primary.sequence and projection[index].event_id == event.event_id and projection[index].slot_id == slot.slot_id and projection[index].record_sequence == event.record_sequence and _wire_exact(projection[index].record, original.primary)
	var camera_error: String = _game.call("camera_framing_error", _room.call("camera_framing_points"))
	return _expect(state.capture_slots == 2 and state.generation == expected_generation and state.joins == 1 and _retirements.size() == 1 and _reentrant_rejected and _retirements[0].slot_ids == [1, 2] and _gate.retirement_state().slot_ids == [1, 2] and not _gate.state().capture.armed and receipt.actor_unchanged and receipt.bound_before_tick and receipt.prepared_actor_sha256 == receipt.after_admission_actor_sha256 and receipt.prepared_actor_sha256 == receipt.after_consumption_actor_sha256, "one sole Gate atomically retires both exact FIFO slots without actor mutation or recursive consumption") and _expect(exact_slots and float(timeline[1].from_s) == float(timeline[0].end_s) + float(state.sequence.authored.inter_echo_gap_s) and float(state.sequence.authored.inter_echo_gap_s) == 1.0 and _scheduler.reservations().size() == 1 and state.lease.adapter.kind == "replay" and not state.lease.adapter.locked and playback.state().status == "running" and playback.get_apparition() != null and playback.get_enemy_apparition() == null and playback.get_footprint_projection().get("accepted", false) and camera_error.is_empty(), "both immutable completed routes/primary events share one numbered finite plan, actual Traveller/projection and current portrait", camera_error)


func _invalid_second_slot_and_rearm_case() -> bool:
	_expected_slots.clear()
	_opportunities.clear()
	_completed_prefix.clear()
	if not await _record_combo(Vector3.BACK, 1): return false
	var first: Dictionary = _expected_slots[0].duplicate(true)
	_trace_scope = "invalid_second_completed_capture"
	var before: int = _latest_sequence()
	if not _expect(_swipe(Vector3.FORWARD).is_empty(), "invalid second slot first executes an actual completed return dash"): return false
	if not await _wait_capture_dash(before) or not await _wait_stable(): return false
	var second_dash: Dictionary = Player.encode_world_action_record(_hero.get_world_action_records(before)[0], _hero.get_world_action_clock())
	_trace_scope = "invalid_second_unpaired_live_dash"
	if not _expect(_swipe(Vector3.RIGHT).is_empty(), "invalid second slot starts another actual dash without replacing recorded geometry"): return false
	if not await _tick(): return false
	var during: Dictionary = _hero.get_threat_response_state()
	var primary_before: int = _latest_sequence()
	var error: String = _tap(Vector3.RIGHT)
	var native: Array[Dictionary] = _hero.get_world_action_records(primary_before)
	if not _expect(error.is_empty() and float(during.motion.dash_left_s) > 0.0 and native.size() == 1 and native[0].kind == "primary" and native[0].world_origin.distance_to(_hero.get_world_action_records(before)[0].landing) > 0.01, "second actual mid-live-dash primary differs from preceding completed capture landing", error): return false
	var second_primary: Dictionary = Player.encode_world_action_record(native[0], _hero.get_world_action_clock())
	if not await _wait_phase("rejected", 180): return false
	var rejected: Dictionary = _room.call("state")
	var capture: Dictionary = rejected.last_rejected_capture
	if not _expect(rejected.rejections == 1 and rejected.joins == 0 and rejected.last_rejection.contains("origin") and capture.slots.size() == 2 and _wire_exact(capture.slots[0].dash, first.dash) and _wire_exact(capture.slots[0].primary, first.primary) and _wire_exact(capture.slots[1].dash, second_dash) and _wire_exact(capture.slots[1].primary, second_primary) and capture.slots[1].primary.world_origin != capture.slots[1].dash.landing and _gate.retirement_state().is_empty() and _scheduler.reservations().is_empty() and _events.is_empty() and _retirements.is_empty() and not _gate.state().capture.armed and _hero.hp == _hp, "invalid second slot rejects the entire untouched two-recording unit with no first-slot replay/retirement", rejected.last_rejection): return false
	if not await _wait_phase("recording", 180): return false
	if not _expect(_gate.state().capture.generation == 2 and _gate.state().capture.allocated == 0 and _hero.global_position.x > 2.0, "visible fresh two-slot generation rearms at actual actor position without rewind"): return false
	if not await _wait_stable(): return false
	_expected_slots.clear()
	_opportunities.clear()
	_completed_prefix.clear()
	if not await _record_combo(Vector3.LEFT, 1): return false
	if not await _record_combo(Vector3.BACK, 2): return false
	return await _resolve_two_slots(2, false)


func _before_response_swipe(segment: Dictionary, proof: Dictionary) -> void:
	_trace_scope = "response/" + String(segment.kind)
	_trace_segment = segment.duplicate(true)
	_trace_proof = proof.duplicate(true)
	_trace_lease = _room.call("state").lease.duplicate(true)


func _swipe(direction: Vector3) -> String:
	var sequence_before: int = _latest_sequence()
	_trace_public_swipe("immediately_before_swipe", sequence_before)
	var error: String = super._swipe(direction)
	_trace_public_swipe("immediately_after_swipe", sequence_before)
	return error


func _trace_public_swipe(label: String, sequence_before: int) -> void:
	print("READONLY TWO-SLOT PUBLIC CLOCK JOIN " + var_to_str({"label": label, "scope": _trace_scope, "player_clock_s": _hero.get_world_action_clock(), "scheduler_clock_s": _scheduler.get_clock(), "motion": _hero.get_threat_response_state().motion, "committed_dash": _hero.get_committed_dash_state(), "sequence_before": sequence_before, "new_actual_records": _hero.get_world_action_records(sequence_before), "original_segment": _trace_segment, "original_proof": _trace_proof, "original_lease": _trace_lease, "live_lease": _room.call("state").lease, "gate": _gate.state()}))


func _complete_response_dash(sequence_before: int, deadline: float) -> bool:
	var completed: bool = await super._complete_response_dash(sequence_before, deadline)
	_trace_public_swipe("actual_response_completed_at_original_deadline", sequence_before)
	print("READONLY ORIGINAL RESPONSE DEADLINE " + var_to_str({"deadline_s": deadline, "original_timeline_origin_s": _trace_proof.get("timeline_origin_s"), "original_segment": _trace_segment, "new_actual_records": _hero.get_world_action_records(sequence_before), "player_clock_s": _hero.get_world_action_clock(), "scheduler_clock_s": _scheduler.get_clock()}))
	return completed


func _on_replay_event(event: Dictionary, opportunity: Dictionary) -> void:
	_events.append(event.duplicate(true))
	_opportunities.append(opportunity.duplicate(true))
	print("READONLY EXACT TWO-SLOT EVENT " + var_to_str({"event": event, "opportunity": opportunity, "original_proof": _room.call("state").proof, "original_lease": _room.call("state").lease}))


func _sever_two_with_actual_recovery() -> bool:
	var before: int = _latest_sequence()
	var original: Dictionary = _room.call("state")
	var original_deadline: float = float(original.lease.adapter.timeline_origin_s) + float(original.sequence.timeline.tether_until_s) - _scheduler.TIME_MARGIN
	var original_events: Array = [original.sequence.timeline.slots[0].events[0], original.sequence.timeline.slots[1].events[0]]
	var tether: Node3D = _room.get("tether") as Node3D
	var direction: Vector3 = tether.global_position - _hero.global_position
	direction.y = 0.0
	var input_player_clock: float = _hero.get_world_action_clock()
	var input_scheduler_clock: float = _scheduler.get_clock()
	var error: String = _tap(direction.normalized() if not direction.is_zero_approx() else Vector3.RIGHT)
	var records: Array[Dictionary] = _hero.get_world_action_records(before)
	if not _expect(error.is_empty() and records.size() == 1 and records[0].kind == "primary" and records[0].hits == 0 and _room.call("state").tether_hits == 1 and _room.call("state").cleared and not _blast_seen, "actual ordinary primary severs the low tether once after both exact replay slots", error): return false
	var primary: Dictionary = records[0].duplicate(true)
	var recovery_budget: float = maxf(float(primary.cooldown_s), float(primary.commitment_duration_s))
	print("READONLY TWO-SLOT ACTUAL PRIMARY FULL RECOVERY " + var_to_str({"actual_primary": primary, "input_player_clock_s": input_player_clock, "input_scheduler_clock_s": input_scheduler_clock, "original_deadline_s": original_deadline, "original_proof": original.proof, "original_lease": original.lease, "original_timeline": original.sequence.timeline}))
	if not _expect(float(primary.started_at_s) == input_player_clock and float(primary.started_at_s) + recovery_budget <= original_deadline and input_scheduler_clock + recovery_budget <= original_deadline, "actual primary start plus actual full cooldown/commitment fits unchanged original tether deadline"): return false
	if not await _wait_phase("spent", 30): return false
	if not _expect(_room.call("state").cleared and _room.call("state").tether_hits == 1 and not tether.is_in_group("environment_attack_targets"), "two-slot tether is spent immediately without waiting for native recovery"): return false
	# Observe actual public Player cooldown/commitment to zero while the
	# original Scheduler continues, against the preserved original deadline.
	var recovered: bool = false
	for _i: int in range(120):
		var response: Dictionary = _hero.get_threat_response_state()
		if float(response.primary_cooldown_left_s) == 0.0 and float(response.commitment_remaining_s) == 0.0:
			recovered = true
			break
		if not await _tick(): return false
	# Diagnostic copy: never Variant-serialize a live actor Object/scene graph.
	# Preserve every other public motion/resource/clock operand exactly.
	var observed_response: Dictionary = _hero.get_threat_response_state()
	observed_response.erase("actor")
	observed_response["actor_instance_id"] = _hero.get_instance_id()
	print("READONLY TWO-SLOT OBSERVED PRIMARY RECOVERY " + var_to_str({"recovered": recovered, "player_clock_s": _hero.get_world_action_clock(), "scheduler_clock_s": _scheduler.get_clock(), "actual_primary": primary, "public_response": observed_response, "original_deadline_s": original_deadline, "original_proof": original.proof, "original_lease": original.lease}))
	if not _expect(recovered and _hero.get_world_action_clock() <= original_deadline and _latest_sequence() == int(primary.sequence), "actual ordinary primary fully settles before unchanged deadline without extra action, clock freeze or recovery extension"): return false
	var clear_history: int = _latest_sequence()
	if not await _drain_original_replay_recovery(float(original.lease.recovery_until_s), clear_history, 2): return false
	if not await _check_completed_two_slot_leaves(original): return false
	var exact_events: bool = _events.size() == 2 and _opportunities.size() == 2 and _completed_prefix.size() == 2
	if exact_events:
		for index: int in range(2):
			var event: Dictionary = _events[index]
			var expected: Dictionary = original_events[index]
			var opportunity: Dictionary = _opportunities[index]
			var scheduled: float = float(original.lease.adapter.timeline_origin_s) + float(expected.at_s)
			# Canonical Cursor validator enforces its existing derived-deadline
			# precision contract. Keep exact original scheduled/dispatch bits and
			# late bound; do not impose a contradictory raw float >= comparator.
			var delivered: Dictionary = {"event_id": event.event_id, "scheduled_at_s": event.scheduled_at_s, "dispatch_clock_s": event.dispatch_clock_s}
			var receipt: Dictionary = {"event_id": opportunity.event_id, "scheduled_at_s": opportunity.scheduled_at_s, "dispatch_clock_s": opportunity.dispatch_clock_s}
			exact_events = exact_events and event.event_id == expected.event_id and event.slot_id == index + 1 and event.kind == "primary" and event.record_sequence == _expected_slots[index].primary.sequence and opportunity.event_id == expected.event_id and float(opportunity.scheduled_at_s) == scheduled and _wire_exact(delivered, _completed_prefix[index]) and _wire_exact(receipt, _completed_prefix[index]) and float(opportunity.dispatch_clock_s) - scheduled <= float(original.proof.dispatch_delay_bound_s) and not opportunity.contact and not opportunity.damage_attempted
	if not _expect(exact_events and _retirements.size() == 1 and _retirements[0].slot_ids == [1, 2] and _scheduler.reservations().is_empty() and not tether.is_in_group("environment_attack_targets") and _hero.hp == _hp and _hero.equipment.snapshot() == _kit, "both exact once-only events preserve original times/FIFO identity; neither contacts hero; finite consumer retires"): return false
	var history: int = _latest_sequence()
	for _i: int in range(30):
		if not await _tick(): return false
	return _expect(_events.size() == 2 and _retirements.size() == 1 and _latest_sequence() == history and _room.call("state").joins == 1 and _room.call("state").tether_hits == 1 and _gate.state().capture.allocated == 2 and not _gate.state().capture.armed, "later real ticks cannot allocate a third slot, recurse, replay, hit or clear twice")


func _check_completed_two_slot_leaves(original: Dictionary) -> bool:
	# Real public Pause after original native recovery has already completed.
	# No whole-level codec or fake overlay is used to obtain these leaf states.
	_game.call("open_bench")
	await process_frame
	var playback: CinderReplayPlayback = _room.get("playback") as CinderReplayPlayback
	var bindings: Dictionary = _room.call("scheduler_bindings")
	var schedule: Dictionary = _scheduler.snapshot_state(bindings)
	var terminal: Dictionary = playback.snapshot_state(schedule, bindings)
	var aggregate: Dictionary = {"player": _hero.snapshot_state(), "gate": _gate.snapshot_state(), "scheduler": schedule, "playback": terminal}
	var cues: Array[Node3D] = playback.get_cues()
	var quiet_cues: bool = cues.size() == 2
	if quiet_cues:
		for index: int in range(2):
			var observed: Dictionary = cues[index].call("state")
			quiet_cues = quiet_cues and observed.phase == "clear" and not observed.source_visible and not observed.footprint_visible and not observed.active_fill_visible and String(cues[index].call("projection_error", original.projection.events[index])).is_empty()
	var camera_error: String = _game.call("camera_framing_error", _room.call("camera_framing_points"))
	print("READONLY TWO-SLOT STRICT COMPLETED LEAF JOIN " + var_to_str({"aggregate": aggregate, "original_proof": original.proof, "original_lease": original.lease, "original_timeline": original.sequence.timeline, "quiet_cues": quiet_cues, "camera_error": camera_error}))
	if not _expect(paused and not aggregate.player.is_empty() and not aggregate.gate.is_empty() and not schedule.is_empty() and not terminal.is_empty() and terminal.status == "complete" and terminal.schema_version == 3 and terminal.cursor.armed and terminal.cursor.phase == "complete" and terminal.cursor.next_event_index == 2 and terminal.cursor.executed_events.size() == 2 and terminal.cursor.last_advanced_clock_s == schedule.clock_s and terminal.clock_s == schedule.clock_s and float(schedule.clock_s) > float(original.lease.recovery_until_s) and schedule.reservations.is_empty() and not schedule.has("replay_cancellations") and schedule.profile.id == original.lease.profile_id and terminal.reason.is_empty() and terminal.cancelled_at_s == null and terminal.cancellation.is_empty() and _wire_exact(terminal.sequence, original.sequence) and _wire_exact(terminal.projection, original.projection) and _wire_exact(terminal.opportunities, _opportunities) and _gate.retirement_state().slot_ids == [1, 2] and quiet_cues and not playback.get_apparition().visible and not playback.get_apparition_root().visible and playback.global_position == original.lease.source_position and not _hero.dead and _hero.hp == _hp and _hero.equipment.snapshot() == _kit and camera_error.is_empty() and _room.call("snapshot_state").is_empty() and not _room.last_snapshot_error.is_empty(), "actual completed schema3 leaves retain original profile/full prefix/current native quiet cues without claiming room transport", playback.last_snapshot_error): return false
	# Correct the observed expectation with the PUBLIC original cursor codec,
	# whose strict prefix validation uses the same declared deadline precision
	# as actual advance. Immutable schedule/clock/type/identity stay exact.
	var cursor_reader := CinderReplayCursor.new()
	var prefix_error: String = cursor_reader.snapshot_error(terminal.cursor, original.sequence, String(original.sequence.source_epoch), int(original.generation), float(schedule.clock_s))
	var too_early: Dictionary = terminal.cursor.duplicate(true)
	too_early.executed_events[0].dispatch_clock_s = float(too_early.executed_events[0].scheduled_at_s) - 2.0 * CinderReplayCursor.TIME_EPSILON_S
	var altered_schedule: Dictionary = terminal.cursor.duplicate(true)
	altered_schedule.executed_events[0].scheduled_at_s = float(altered_schedule.executed_events[0].scheduled_at_s) + 0.0001
	if not _expect(prefix_error.is_empty() and not cursor_reader.snapshot_error(too_early, original.sequence, String(original.sequence.source_epoch), int(original.generation), float(schedule.clock_s)).is_empty() and not cursor_reader.snapshot_error(altered_schedule, original.sequence, String(original.sequence.source_epoch), int(original.generation), float(schedule.clock_s)).is_empty(), "original public cursor accepts native exact prefix and rejects dispatch before declared precision or altered scheduled bits", prefix_error): return false
	_completed_prefix = terminal.cursor.executed_events.duplicate(true)
	var input_before: PackedByteArray = var_to_bytes(_game.call("get_input_observation_state"))
	var camera: Camera3D = _game.get("camera") as Camera3D
	var camera_before: PackedByteArray = var_to_bytes(camera.global_transform)
	var history: int = _latest_sequence()
	var actor_clock: float = _hero.get_world_action_clock()
	for _i: int in range(4): await process_frame
	schedule = _scheduler.snapshot_state(bindings)
	var after: Dictionary = {"player": _hero.snapshot_state(), "gate": _gate.snapshot_state(), "scheduler": schedule, "playback": playback.snapshot_state(schedule, bindings)}
	if not _expect(_wire_exact(aggregate, after) and _events.size() == 2 and _latest_sequence() == history and input_before == var_to_bytes(_game.call("get_input_observation_state")) and camera_before == var_to_bytes(camera.global_transform), "actual public paused completed aggregate remains exact without redelivery, input or clock advance"): return false
	var button: Button = _find_resume(_game.get("hud") as Node)
	if not _expect(button != null and button.is_visible_in_tree(), "actual completed Resume GUI control is visible"): return false
	_touch(button.get_global_rect().get_center(), 91)
	return _expect(not paused and _latest_sequence() == history and _hero.get_world_action_clock() == actor_clock and _events.size() == 2 and input_before == var_to_bytes(_game.call("get_input_observation_state")), "actual completed GUI Resume is consumed without action, recapture or tick")
