extends "res://tests/acts/act1/a1_l3_gui_capture_repro.gd"
## Owner-reviewed earned-prefix fixture; native evidence is recorded separately.
## Genuine Umbrella/Breathing -> first Crossed cycle only, with passive GUI
## receipts. Normal preview only; no whole-level/save/kit/profile acceptance.

const PrefixExpectedRouteSHA: String = "3784a019bfd5dec6e49b18e64e73ca00b7fd21dc6497258b9f948154762b18bb"
var prefix_crossed_cycle: Dictionary = {}
var prefix_done: bool = false


func _run() -> void:
	portrait = true
	root.size = PortraitSize
	if not _require(DisplayServer.get_name() != "headless" and "--capture" not in OS.get_cmdline_user_args() and "--capture-polish" not in OS.get_cmdline_user_args(), "earned prefix uses the real renderer with unchanged native focus handling"):
		await _finish(); return
	if not _require(FileAccess.get_sha256("res://scripts/acts/act1/mushroom_caverns_route.gd") == PrefixExpectedRouteSHA, "prefix requires the reviewed whole RightStalk geometry at fresh world construction"):
		await _finish(); return
	capture_dir = "res://.cinder/captures/l3-earned-crossed-prefix-%d" % Time.get_ticks_usec()
	if not _require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir)) == OK, "earned prefix evidence directory is writable"):
		await _finish(); return
	if not await _open_world(NormalOpeningPath, "earned-crossed-prefix", FullLayout.SPAWN):
		await _finish(); return
	full_spec = level.call("normal_route_spec")
	full_world_ids = {"game": str(game.get_instance_id()), "level": str(level.get_instance_id()), "player": str(hero.get_instance_id()), "scheduler": str(scheduler.get_instance_id()), "camera": str((game.get("camera") as Camera3D).get_instance_id())}
	# Original full-route setup predicate retained; no equipment/profile staging.
	if not _require(full_spec.sources == NormalIds and full_spec.room_sources.size() == 5 and full_spec.room_fields.size() == 5 and full_spec.thresholds == FullLayout.BEAT_THRESHOLDS and full_spec.checkpoint_ids == FullBeats.slice(0, 4) and full_spec.completion_id == "mushroom-caverns-clear" and full_spec.exit_id == "open-court" and initial_hp == 100.0 and hero.equipment.snapshot() == {"jacket": "CLOTH-J0", "pants": "CLOTH-P0", "shoes": "CLOTH-S0", "weapon": "WEAPON-01"}, "fresh normal route has the authored nineteen, five thresholds and actual neutral starter without resource staging"):
		await _finish(); return
	if not _install_passive_observers():
		await _finish(); return
	_record_repro("earned_prefix_genuine_spawn", {})
	for id: String in NormalIds:
		full_defeats[id] = 0
		sources[id].connect("defeated", _full_notice_defeat)
	level.completion_requested.connect(_full_notice_completion)
	level.contact_exit_requested.connect(_full_notice_contact)
	process_frame.connect(_sample_opening)
	process_frame.connect(_sample_crowd)
	physics_frame.connect(_full_phase_observer)
	if not await _full_quiet_capture("actual-pristine-nineteen"):
		await _finish(); return
	# These original helpers earn every preceding defeat, ordinary action,
	# field/consumer state and checkpoint. No shortcut activates Crossed.
	for room: int in range(2):
		if not await _full_enter_room(room) or not await _full_clear_room(room) or not await _full_room_boundary(room):
			_full_diagnostic("earned prefix preceding room %d failed" % room); await _finish(); return
	if not await _full_enter_room(2) or not await _full_opportunity(2):
		_full_diagnostic("earned Crossed entrance/opportunity failed"); await _finish(); return
	var id: String = _fresh_warning()
	if not _require(not id.is_empty() and not bool(full_room_cycle_seen.get(2, false)), "earned Crossed prefix selects the first actual accepted native warning, never a fabricated ordinary gap"):
		await _finish(); return
	if not await _prefix_crossed_first_cycle(id, false):
		_full_diagnostic("earned Crossed first-cycle capture/Resume failed"); await _finish(); return
	prefix_done = true
	if not _prefix_earned_truth() or not _full_action_history():
		_full_diagnostic("earned prefix final truth/history failed"); await _finish(); return
	_record_repro("earned_crossed_recovery_real_resume_completed", {"cycle": prefix_crossed_cycle.duplicate(true)})
	# No return dash/ordinary Crossed attack, room clear, later room or contact.
	await _finish()


func _gui_resume_pair() -> bool:
	repro_cycle += 1
	var result: bool = await super._gui_resume_pair()
	if result: repro_finished_cycles += 1
	return result


func _prefix_crossed_first_cycle(id: String, _unused_pair_pause: bool) -> bool:
	var actor: CharacterBody3D = sources[id]
	var state: Dictionary = actor.call("pure_presentation_state")
	var room: int = int(level.call("route_state").beat_index)
	var lease: String = String(state.reservation_id)
	var cycle: int = int(state.cycle)
	var answer: Dictionary = admissions.get(lease, {})
	var native: Dictionary = actor.call("get_spore_native_bindings")
	var is_guard: bool = native.configuration.entity_id == "C32"
	if not _require(id in _full_ids(room) and state.phase == "warning" and state.role_id == native.configuration.role_id and answer.get("accepted", false) and answer.get("armed", false) and answer.reservation.source_instance_id == actor.get_instance_id() and not answer.proof.uses_blast and not answer.proof.uses_invulnerability, id + " actual native current-room role/source owns this unchanged ordinary accepted response"):
		return false
	var proof: Dictionary = answer.proof.duplicate(true)
	var reservation: Dictionary = answer.reservation.duplicate(true)
	var length: float = (reservation.geometry["to"] as Vector3).distance_to(reservation.geometry["from"])
	if not _require(float(proof.primary_time_s) >= float(reservation.active_until_s) and float(proof.response_complete_s) < float(reservation.recovery_until_s) and reservation.geometry.kind == "lane" and absf(length - (2.0 if is_guard else 1.0)) <= PositionTolerance and absf(float(reservation.geometry.radius) - 0.38) <= CrowdEpsilon, id + " retains exact native C31/C32 lane and original ordinary timing proof"):
		return false
	# First cycle per room captures the still-living whole room at every actual
	# warning/active/recovery barrier; Crossed includes all eight plus both fields.
	var detailed: bool = not bool(full_room_cycle_seen.get(room, false))
	if detailed and not await _full_phase_barrier(id, lease, cycle, "warning"): return false
	var source_start: Vector3 = actor.global_position
	var escape: Vector3 = proof.landing - hero.global_position
	escape.y = 0.0
	if not _require(absf(escape.length() - float(hero.equipment.resolved_stats().dash_distance)) <= PositionTolerance, id + " native safe landing remains one full legal dash"): return false
	if not await _swipe(escape, id + " full native safe escape"): return false
	if detailed:
		if not await _full_phase_barrier(id, lease, cycle, "lock"): return false
		if not await _full_phase_barrier(id, lease, cycle, "active") or not await _full_phase_barrier(id, lease, cycle, "recovery"): return false
	else:
		for phase: String in ["lock", "active", "recovery"]:
			var key: String = _phase_key(id, cycle, lease, phase)
			if not await _wait(func() -> bool: return phase_observations.has(key), id + " actual retained native " + phase): return false
	state = actor.call("pure_presentation_state")
	if not _require(state.reservation_id == lease and state.cycle == cycle and state.status == "running", id + " completed native observation retains the same source cycle"): return false
	if is_guard:
		if not _require(_planar_distance(actor.global_position, source_start) <= PositionTolerance and actor.velocity.is_zero_approx(), id + " actual C32 role retains its stationary physical lane source"): return false
	else:
		if not _require(_planar_distance(actor.global_position, source_start) > .9 and actor.global_position.distance_to(reservation.opening_position) <= PositionTolerance and state.adapter.finished, id + " actual C31 lunge reaches its genuine finished ordinary opening"): return false
	# Original source-cycle/body-finish predicates above remain intact. Stop
	# before the parent's return/primary code, after Recovery's real GUI Resume.
	for phase: String in ["warning", "lock", "active", "recovery"]:
		var key: String = _phase_key(id, cycle, lease, phase)
		if not _require(phase_observations.has(key), id + " earned prefix retains this exact native cycle phase receipt"): return false
	if not _require(full_phase_barriers.size() >= 4 and full_phase_barriers.back().id == id and full_phase_barriers.back().lease == lease and full_phase_barriers.back().cycle == cycle and full_phase_barriers.back().phase == "recovery" and not paused and not bool(game.call("is_pause_requested")), "first Crossed Recovery completed the original real Resume predicate and cleared its phase pause request"):
		return false
	prefix_crossed_cycle = {"source_id": id, "lease": lease, "cycle": cycle, "original_proof": _portable(proof), "original_reservation": _portable(reservation), "state_after_real_recovery_resume": _portable(state), "actual_player_position": _portable(hero.global_position), "current_clock_s": scheduler.get_clock()}
	return true


func _prefix_earned_truth() -> bool:
	var route: Dictionary = level.call("route_state")
	var expected_checkpoints: Array[Dictionary] = []
	for id: String in FullBeats.slice(0, 2): expected_checkpoints.append({"level_id": "A1-L3", "checkpoint_id": id, "kind": "encounter"})
	if not _require(not repro_overflow and route.beat_index == 2 and route.room_stage == "active" and route.encounter_started and route.completed_beats == FullBeats.slice(0, 2) and opening_checkpoint_events == expected_checkpoints and full_checkpoint_guards.size() == 2 and full_room_receipts.size() == 2 and full_defeat_receipts.size() == 6 and opening_completion_events == 0 and opening_contact_events == 0 and not level.is_completed() and hero.hp == initial_hp and hit_events.is_empty() and opening_epochs == _full_expected_epochs(2) and level.call("current_source_ids") == _full_ids(2), "earned prefix retains six real preceding defeats/two checkpoints/eight current sources with no completion/contact or injury"):
		return false
	for id: String in _full_allowed(1):
		if not _require(full_defeats[id] == 1 and sources[id].get("dead") and float(sources[id].get("hp")) == 0.0, id + " prior real defeat is retained once at the Crossed prefix"): return false
	for id: String in _full_ids(2):
		var actor: CharacterBody3D = sources[id]
		var state: Dictionary = actor.call("pure_presentation_state")
		if not _require(full_defeats[id] == 0 and not state.dead and not state.dormant and state.hp == 16.0 and actor.is_in_group("enemies") and opening_activation_counts[id] == 1, id + " actual Crossed source remains alive after native first-cycle observation"): return false
	return _retained_truth("earned Crossed prefix") and _future_pristine(_full_allowed(2), "earned Crossed prefix retains five real future dormant") and _full_environment(2, false)


func _watchdog() -> void:
	# Same original full-route wall budget; every inherited native readiness,
	# phase/pause/input deadline is unchanged. No new native timing grant.
	if not finishing and Time.get_ticks_msec() - started_ms > FullWallWatchdogMs:
		_require_unexpected(false, "earned prefix stays inside the original full-route finite fifteen-minute wall budget")
		_finish.call_deferred()


func _finish() -> void:
	if finishing: return
	_record_repro("before_earned_prefix_cleanup", {})
	var final_route: Dictionary = level.call("route_state") if is_instance_valid(level) else {}
	var final_sources: Dictionary = _source_states() if is_instance_valid(level) else {}
	var final_observation: Dictionary = _opening_observation() if is_instance_valid(level) and is_instance_valid(hero) and is_instance_valid(scheduler) else {}
	_full_disconnect_observers()
	finishing = true
	if is_instance_valid(repro_observer):
		repro_observer.receiver = Callable()
		repro_observer.queue_free()
	if root.focus_entered.is_connected(_repro_window_focus_entered): root.focus_entered.disconnect(_repro_window_focus_entered)
	if root.focus_exited.is_connected(_repro_window_focus_exited): root.focus_exited.disconnect(_repro_window_focus_exited)
	# Existing full-route cleanup pauses only after the observed prefix ends,
	# exits native sources/fields and drains retired audio before actual free.
	paused = true
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(game):
		var effects: PixelEffects = game.get("fx") as PixelEffects
		if is_instance_valid(effects): effects.clear()
		var drain_until: int = Time.get_ticks_msec() + 500
		while Time.get_ticks_msec() < drain_until: await process_frame
		game.queue_free()
	paused = false
	await process_frame
	var path: String = capture_dir.path_join("evidence.json") if not capture_dir.is_empty() else "res://.cinder/l3-earned-crossed-prefix-%d.json" % Time.get_ticks_usec()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		var report: Dictionary = {"scope": "actual earned neutral/Standard Umbrella+Breathing defeats/checkpoints followed by first Crossed entrance/warning/lock/active/recovery and real GUI Resume only; nineteen retained/eight current; no Crossed defeat/clear, later rooms/contact, whole route/campaign Save, kit/profile/human/performance or optical acceptance inference", "checks": checks, "failures": failures, "prefix_done": prefix_done, "actual_swipes": swipes, "actual_primaries": primaries, "normal_focus_out_preserved": true, "world_ids": full_world_ids, "observed_epochs": opening_epochs, "activation_counts": opening_activation_counts, "defeat_receipts": full_defeat_receipts, "room_receipts": full_room_receipts, "checkpoint_guards": full_checkpoint_guards, "completion_receipts": full_completion_receipts, "contact_receipts": full_contact_receipts, "complete_action_signal_trace": _portable(world_records), "accepted_input_signal_trace": _portable(input_observations), "validated_encoded_history": full_evidence_history, "primary_receipts": crowd_primary_receipts, "native_phase_barriers": full_phase_barriers, "response_timing_receipts": _portable(full_response_timing_receipts), "diagnostics": full_diagnostics, "crossed_cycle": prefix_crossed_cycle, "receipt_overflow": repro_overflow, "real_gui_resumes_passed": repro_finished_cycles, "passive_gui_receipts": repro_receipts, "final_route": _portable(final_route), "final_sources": _portable(final_sources), "final_native_observation": _portable(final_observation), "captures": shots}
		file.store_string(JSON.stringify(report, "\t")); file.close()
	else:
		checks += 1; failures += 1
		push_error("earned Crossed prefix evidence file could not open")
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L3 EARNED CROSSED PREFIX: %d checks, %d failures; %d swipes, %d primaries; report=%s; NO FULL-ROUTE/SAVE ACCEPTANCE" % [checks, failures, swipes, primaries, path])
	quit(1 if failures else 0)
