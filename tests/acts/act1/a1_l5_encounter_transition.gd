extends "res://tests/acts/act1/a1_l5_shell_transport.gd"
## SOURCE ONLY. Reuses isolated TEST Shell/store/prefix and normal cleanup.
## Real production parent phases, native source leases/cues, actual Player
## primary attacks and native Area contact. No phase/eye-HP/sample/clock seed.
## Public TEST rusher injury and same-floor placements replace earned travel.
## No additional Player, controller, camera or private recovery provider.

const Sweep = preload("res://scripts/combat/body_sweep.gd")
const EncounterWatchdogMs: int = 180000
var moon: CinderLevel
var eye_ref: WeakRef
var eye_collision_ref: WeakRef
var eye_shape_ref: WeakRef
var circle_cycles: Dictionary = {}
var plans: Dictionary = {}
var dash_requests: Dictionary = {}
var recovery_captures: Dictionary = {}
var warning_captures: Dictionary = {}
var hp_boundaries: Array[float] = []
var phase_observers: Array[Dictionary] = []
var terminal_observers: Array[Dictionary] = []
var hatch_entries: Array[Dictionary] = []
var primary_receipts: Array[Dictionary] = []
var witnessed_final_pair: bool = false
var drive_diagnostics: Array[Dictionary] = []
var first_primary_only: bool = false


func _initialize() -> void:
	super._initialize()
	test_root = "user://test-act1-moon-encounter-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]


func _run() -> void:
	root.size = Vector2i(540, 1170)
	first_primary_only = OS.get_cmdline_user_args().has("--first-primary-only")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--level-scene") or argument in ["--capture", "--capture-polish"]:
			_expect(false, "actual Shell encounter cannot enter preview mode"); await _finish(); return
	registry_bytes = FileAccess.get_file_as_bytes(Registry.DATA_PATH)
	var parsed: Variant = JSON.parse_string(registry_bytes.get_string_from_utf8())
	if not _expect(parsed is Dictionary and parsed.get("levels") is Array, "actual registry supplies isolated TEST L5 metadata"):
		await _finish(); return
	raw = parsed.duplicate(true)
	for entry: Dictionary in raw.levels:
		if entry.id == Layout.LEVEL_ID:
			setups.append({"kind": "TEST in-memory L5 override", "canonical_readiness_before": entry.readiness, "canonical_scene_before": entry.scene_path, "canonical_commit_before": entry.accepted_commit})
			entry.scene_path = ScenePath; entry.readiness = "accepted"; entry.accepted_commit = "f".repeat(40); entry.api_revision = Registry.API_REVISION
	var registry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A2-L1").is_empty(), "only candidate L5 is TEST-enabled; next-level transition uses the existing actual accepted A2-L1"): await _finish(); return
	probe = NativeTickProbe.new(); probe.process_physics_priority = 3000; root.add_child(probe)
	if not await _seed_actual_pristine_story(registry): await _finish(); return
	game = _new_shell()
	if game == null or not await _settle() or not await _click(game, "ContinueStoryButton") or not _bindings(game): await _finish(); return
	moon = game.active_level
	var eye: CharacterBody3D = moon.get("eye") as CharacterBody3D
	eye_ref = weakref(eye)
	var collision: CollisionShape3D = eye.call("get_collision")
	eye_collision_ref = weakref(collision); eye_shape_ref = weakref(collision.shape)
	eye.connect("phase_changed", _phase_observer)
	eye.connect("defeated", _defeat_observer)
	moon.completion_requested.connect(_completion_observer)
	moon.contact_exit_requested.connect(_contact_observer)
	moon.get("_hatch").connect("body_entered", _hatch_observer)
	var initial: Dictionary = game.capture_campaign_snapshot()
	if not _closed(initial) or not _expect(initial.level.local.eye.hp == 240.0 and initial.level.local.stage == "return" and initial.level.local.blink.cycle == 0 and initial.level.progress.checkpoint_ids.is_empty() and game.attempts.state().completed_main == Prefix, "real initial HP240 and unearned four-predecessor TEST prefix; no Moon progress fabricated"): await _finish(); return
	if not _expect(game.player.equipment.snapshot() == Equipment.STARTER and float(game.player.equipment.resolved_stats().primary_damage) == 20.0, "actual unchanged starter primary provides four ordinary20HP hits per original80HP phase interval"): await _finish(); return
	if not await _enter_actual_boss(): await _finish(); return
	hp_boundaries.append(240.0)
	if first_primary_only:
		if not await _drive_to_hp(220.0, "blink"): await _finish(); return
		if not _expect(primary_receipts.size() == 1 and eye.get("hp") == 220.0 and eye.get("phase") == 1 and moon.get("stage") == "blink" and phase_observers.is_empty() and moon.current_checkpoint().id == "capsule-ready", "first-primary-only diagnostic observes one real recovery hit240-to220 without claiming later phase/exit coverage"): await _finish(); return
		receipts.append({"stage": "first-primary-only actual genuine recovery primary; later phases/final/hatch/successor unexecuted", "eye_hp": eye.get("hp"), "clock_s": _scheduler().get_clock()})
		await _finish(); return
	if not await _drive_to_hp(160.0, "blink") or not await _phase_checkpoint("moon-phase-2", "sneeze", 160.0): await _finish(); return
	if not await _drive_to_hp(80.0, "sneeze") or not await _phase_checkpoint("moon-phase-3", "final", 80.0): await _finish(); return
	if not await _drive_to_hp(0.0, "final"): await _finish(); return
	hp_boundaries.append(0.0)
	if not _expect(phase_observers.size() == 2 and phase_observers[0].phase == 2 and phase_observers[0].hp == 160.0 and phase_observers[1].phase == 3 and phase_observers[1].hp == 80.0 and hp_boundaries == [240.0, 160.0, 80.0, 0.0] and primary_receipts.size() == 12 and witnessed_final_pair, "actual ordinary primary reaches original240/160/80/0; two committed phase observers and real staggered final pair"): await _finish(); return
	if not await _hatch_and_transition(): await _finish(); return
	await _finish()


func _enter_actual_boss() -> bool:
	if not await _click(game, "ResumeButton") or not await _wait(func() -> bool: return moon.get("impact_demonstrated") == true, "actual return impact active interval completes naturally", 12.0): return false
	var rusher: CharacterBody3D = moon.get("rusher") as CharacterBody3D
	var amount: float = rusher.get("hp")
	var answer: Dictionary = rusher.call("take_damage", amount, Vector3.ZERO)
	setups.append({"kind": "TEST public rusher lethal injury, not earned combat", "amount": amount, "result": _encode(answer), "clock_s": _scheduler().get_clock()})
	if not _expect(answer.get("accepted") == true and rusher.get("dead") == true, "real native return rusher commits its public injury/defeat/cleanup"): return false
	if not await _place(-6.3) or not await _wait(func() -> bool: return moon.current_checkpoint().id == "capsule-ready", "actual authored capsule checkpoint", 10.0, true) or not await _settle(): return false
	var checkpoint: Dictionary = game.attempts.state().story.checkpoint
	if not _closed(checkpoint) or not _expect(checkpoint.level.local.stage == "capsule" and checkpoint.level.local.impact_demonstrated and checkpoint.level.local.actors[Layout.RUSHER_ID].dead and checkpoint.level.progress.checkpoint_ids == {"capsule-ready": "encounter"} and checkpoint.level.local.eye.hp == 240.0 and _durable(game), "public parent publishes genuine capsule history/HP240 and actual durable checkpoint"): return false
	receipts.append({"stage": "actual capsule checkpoint", "exact_snapshot": Exact.stringify(checkpoint)})
	if paused and not await _click(game, "ResumeButton"): return false
	if not await _place(Layout.EYE_APPROACH_POSITION.z): return false
	return await _wait(func() -> bool: return moon.get("stage") == "blink", "authored threshold enters actual first Blink phase", 10.0)


func _drive_to_hp(target_hp: float, expected_stage: String) -> bool:
	var end: int = Time.get_ticks_msec() + 30000
	var excluded_capture_wall_ms: int = 0
	while not finishing and not aborted and Time.get_ticks_msec() < end:
		if not _live() or game.player.dead: return _expect(false, "actual living Hero/production parent lost during " + expected_stage)
		var eye: CharacterBody3D = eye_ref.get_ref() as CharacterBody3D
		if eye == null: return _expect(false, "real eye removed before native contact exit")
		if eye.get("hp") == target_hp: return true
		if paused: return _expect(false, "unexpected native pause during phase; no forced Resume")
		if eye.get("hp") < target_hp or moon.get("stage") != expected_stage: return _expect(false, "actual HP/parent phase passed the expected boundary")
		if not _retain_real_samples(): return false
		var records: Array[Dictionary] = _boss_records()
		if expected_stage == "final" and records.size() == 2 and not witnessed_final_pair:
			var stagger: float = absf(float(records[0].active_from_s) - float(records[1].active_from_s))
			if not _expect(stagger >= float(_scheduler().encounter_profile().commit_stagger_s) - 0.00001, "real final Eye/Nose native active intervals preserve the shared visible stagger"): return false
			witnessed_final_pair = true
		var uncaptured: bool = false
		for record: Dictionary in records:
			if not warning_captures.has(record.id) and record.state in ["warning", "lock"]: uncaptured = true
		if uncaptured:
			var preparing_started_ms: int = Time.get_ticks_msec()
			if not await _capture_real_window(expected_stage + " preparing", true): return false
			var preparing_wall_ms: int = Time.get_ticks_msec() - preparing_started_ms
			end += preparing_wall_ms; excluded_capture_wall_ms += preparing_wall_ms
			var preparing_diagnostic: Dictionary = _drive_observation("after preparing capture/GUI Resume", expected_stage, end)
			preparing_diagnostic["capture_wall_ms"] = preparing_wall_ms; preparing_diagnostic["excluded_capture_wall_ms"] = excluded_capture_wall_ms
			drive_diagnostics.append(preparing_diagnostic)
			continue
		if not _request_real_escape(records): return false
		if _all_active_intervals_ended(records) and _genuine_recovery(records):
			var response: Dictionary = game.player.get_threat_response_state()
			if response.stable and response.primary_cooldown_left_s == 0.0 and response.dash_cooldown_left_s == 0.0:
				if not recovery_captures.has(expected_stage):
					drive_diagnostics.append(_drive_observation("before genuine recovery capture", expected_stage, end))
					var recovery_started_ms: int = Time.get_ticks_msec()
					if not await _capture_real_window(expected_stage + " genuine recovery", false): return false
					var recovery_wall_ms: int = Time.get_ticks_msec() - recovery_started_ms
					end += recovery_wall_ms; excluded_capture_wall_ms += recovery_wall_ms
					var recovery_diagnostic: Dictionary = _drive_observation("after genuine recovery capture/GUI Resume", expected_stage, end)
					recovery_diagnostic["capture_wall_ms"] = recovery_wall_ms; recovery_diagnostic["excluded_capture_wall_ms"] = excluded_capture_wall_ms
					drive_diagnostics.append(recovery_diagnostic)
					recovery_captures[expected_stage] = true
					continue
				if not _place_at_actual_low_rim(): return false
				if not await _wait(func() -> bool: return game.camera_framing_error(moon.camera_framing_points()).is_empty(), "actual current low-rim/cue/source/landing view", 4.0): return false
				# Framing advances the real clock. Re-read genuine recovery before hit.
				records = _boss_records()
				if not _all_active_intervals_ended(records) or not _genuine_recovery(records): continue
				var before_hp: float = eye.get("hp")
				var history_size: int = game.player.get_world_action_records().size()
				var shells_before: int = game.player.shells
				drive_diagnostics.append(_drive_observation("before actual ordinary primary", expected_stage, end))
				var result: int = game.player.slash((eye.global_position - game.player.global_position).normalized())
				var history: Array[Dictionary] = game.player.get_world_action_records()
				var action: Dictionary = history.back() if not history.is_empty() else {}
				if not _expect(result == 1 and eye.get("hp") == maxf(0.0, before_hp - 20.0) and history.size() == history_size + 1 and action.get("kind") == "primary" and action.get("origin") == "player_direct" and action.get("hits") == 1 and game.player.shells >= shells_before, "actual public ordinary primary pays normal timing, damages genuine recovery once and spends no blast ammo: " + expected_stage): return false
				primary_receipts.append({"phase": expected_stage, "before_hp": before_hp, "after_hp": eye.get("hp"), "clock_s": _scheduler().get_clock(), "action": _encode(action), "sources": _encode(records)})
				if not _eye_registration_intact(): return false
		await probe.tick_finished
	var timeout_diagnostic: Dictionary = _drive_observation("phase observation wall deadline", expected_stage, end)
	timeout_diagnostic["excluded_capture_wall_ms"] = excluded_capture_wall_ms
	drive_diagnostics.append(timeout_diagnostic)
	var observation_result: bool = _expect(false, "bounded real recovery/ordinary-primary observation: " + expected_stage)
	first_failure["drive_diagnostic"] = timeout_diagnostic
	return observation_result


func _drive_observation(label: String, expected_stage: String, deadline_ms: int) -> Dictionary:
	# Primitive public live observations only; no provider call or opening latch.
	var row: Dictionary = {"label": label, "expected_stage": expected_stage, "wall_elapsed_ms": Time.get_ticks_msec() - started_ms, "observation_wall_ms_left": deadline_ms - Time.get_ticks_msec(), "paused": paused}
	if not _live(): return row
	var response: Dictionary = game.player.get_threat_response_state().duplicate(true)
	response.erase("actor"); response.erase("stats")
	row["clock_s"] = _scheduler().get_clock(); row["stage"] = moon.get("stage")
	row["hero_response"] = _encode(response); row["hero_hp"] = game.player.hp
	row["eye_hp"] = eye_ref.get_ref().get("hp"); row["eye_last_error"] = eye_ref.get_ref().get("last_error")
	var records: Array[Dictionary] = _boss_records()
	row["all_active_intervals_ended"] = _all_active_intervals_ended(records)
	row["genuine_recovery_predicate"] = _genuine_recovery(records)
	var sources: Array[Dictionary] = []
	for record: Dictionary in records:
		var source: Node3D = moon.get("blink") if record.source_id == Layout.EYE_ID else moon.get("nose")
		var state: Dictionary = source.call("state")
		var cue: CinderThreatCue = source.call("get_cue")
		var cue_state: Dictionary = cue.state() if is_instance_valid(cue) else {}
		sources.append({"source_id": record.source_id, "reservation_id": record.id, "status": state.status, "phase": state.phase, "record_state": record.state, "armed": record.armed, "opening_position": _encode(state.get("opening_position")), "record_opening_position": _encode(record.opening_position), "lock_from_s": record.lock_from_s, "active_from_s": record.active_from_s, "active_until_s": record.active_until_s, "recovery_until_s": record.recovery_until_s, "cue_phase": cue_state.get("phase"), "cue_source_visible": cue_state.get("source_visible"), "cue_visible_in_tree": is_instance_valid(cue) and cue.is_visible_in_tree()})
	row["sources"] = sources
	return row


func _boss_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for pair: Array in [[Layout.EYE_ID, eye_ref.get_ref()], [Layout.NOSE_ID, moon.get("nose")]]:
		for actual: Dictionary in _scheduler().source_control_state(pair[1]).get("reservations", []):
			var value: Dictionary = actual.duplicate(true)
			value["source_id"] = pair[0] # actual owner mapping; public wire-only ID
			records.append(value)
	return records


func _retain_real_samples() -> bool:
	var state: Dictionary = moon.get("blink").state()
	if state.status != "running": return true
	var cycle: String = str(state.cycle)
	var geometry: Variant = _encode(state.geometry)
	if not circle_cycles.has(cycle):
		circle_cycles[cycle] = {"sample": state.sample.duplicate(true), "geometry": geometry, "opening": Codec.vector3(state.opening_position)}
		return _expect(not state.sample.is_empty() and state.sample.source_id == Layout.EYE_ID and state.opening_position == Layout.EYE_POSITION, "native Blink warning-start sample belongs to the real stationary HP eye")
	return _expect(false, "actual warning sample/footprint/opening retargeted during native cycle") if not _same(circle_cycles[cycle], {"sample": state.sample, "geometry": geometry, "opening": Codec.vector3(state.opening_position)}) else true


func _capture_real_window(label: String, preparing: bool) -> bool:
	if not await _pause(): return false
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _closed(saved) or not _expect(moon.snapshot_error_with_player(saved.level, saved.player).is_empty(), "pure public complete paused parent/Player validation: " + label): return false
	var wire: String = Exact.stringify(saved)
	await create_timer(0.04, true).timeout
	if not _expect(Exact.stringify(game.capture_campaign_snapshot()) == wire, "paused original native sample/deadlines/HP/phase/clock freeze: " + label): return false
	for record: Dictionary in saved.level.local.scheduler.reservations:
		if record.source_id not in [Layout.EYE_ID, Layout.NOSE_ID]: continue
		plans[record.id] = {"source_id": record.source_id, "proof": saved.level.local.framing[record.source_id].proof.duplicate(true)}
		if preparing: warning_captures[record.id] = true
	receipts.append({"stage": label, "exact_snapshot": wire})
	return await _click(game, "ResumeButton")


func _request_real_escape(records: Array[Dictionary]) -> bool:
	var response: Dictionary = game.player.get_threat_response_state()
	if not response.stable or response.dash_cooldown_left_s > 0.0: return true
	for record: Dictionary in records:
		if not plans.has(record.id) or dash_requests.has(record.id) or _scheduler().get_clock() >= float(record.active_from_s): continue
		var path: Array = plans[record.id].proof.path
		var segment: Dictionary = path[1]
		if _scheduler().get_clock() < float(segment.start_s): continue
		var direction: Vector3 = Codec.read_vector3(segment.to) - Codec.read_vector3(segment.from)
		direction.y = 0.0
		var actual_clock: float = _scheduler().get_clock()
		var actual_origin: Vector3 = game.player.global_position
		if not _expect(direction.length() > 0.0 and actual_clock < float(record.active_from_s) and game.player.request_dash(direction.normalized()), "actual public Hero performs a retained native proof escape direction before active"): return false
		dash_requests[record.id] = {"actual_clock_s": actual_clock, "actual_origin": Codec.vector3(actual_origin), "direction": Codec.vector3(direction.normalized()), "original_segment": segment.duplicate(true), "lateness_s": actual_clock - float(segment.start_s), "origin_distance": actual_origin.distance_to(Codec.read_vector3(segment.from)), "scope": "Actual pre-active public dash in retained direction; exact proof schedule/origin was not asserted"}
		return true
	return true


func _all_active_intervals_ended(records: Array[Dictionary]) -> bool:
	if records.is_empty(): return false
	for record: Dictionary in records:
		if _scheduler().get_clock() <= float(record.active_until_s): return false
	return true


func _genuine_recovery(records: Array[Dictionary]) -> bool:
	for record: Dictionary in records:
		var source: Node3D = moon.get("blink") if record.source_id == Layout.EYE_ID else moon.get("nose")
		var state: Dictionary = source.call("state")
		var cue: CinderThreatCue = source.call("get_cue")
		if state.status == "running" and state.phase == "recovery" and state.reservation_id == record.id and record.opening_position == Layout.EYE_POSITION and record.state == "recovery" and record.armed == true and _scheduler().get_clock() > record.active_until_s and _scheduler().get_clock() < record.recovery_until_s and cue.state().phase == "recovery" and cue.state().source_visible and cue.is_visible_in_tree(): return true
	return false


func _place_at_actual_low_rim() -> bool:
	var eye: CharacterBody3D = eye_ref.get_ref() as CharacterBody3D
	var goal: Vector3 = eye.global_position + Vector3.BACK * 0.6
	goal.y = game.player.global_position.y
	if game.player.global_position.distance_to(goal) <= 0.01: return true
	var regions: Array = [moon.call("floor_region")]
	var supported: Dictionary = Sweep.step(game.player, Transform3D(Basis.IDENTITY, goal), Vector3.ZERO, regions)
	if not _expect(not supported.has("error") and not supported.get("collided", true), "disclosed low-rim TEST placement has genuine actual floor/full capsule support"): return false
	var before: Vector3 = game.player.global_position
	game.player.global_position = goal
	setups.append({"kind": "TEST recovery-only low-rim Hero placement, not earned return movement", "from": Codec.vector3(before), "to": Codec.vector3(goal), "clock_s": _scheduler().get_clock()})
	return true


func _eye_registration_intact() -> bool:
	var eye: CharacterBody3D = eye_ref.get_ref() as CharacterBody3D
	var collision: CollisionShape3D = eye.call("get_collision")
	return _expect(eye.global_position == Layout.EYE_POSITION and eye.velocity == Vector3.ZERO and collision == eye_collision_ref.get_ref() and collision.shape == eye_shape_ref.get_ref() and not collision.disabled and eye.collision_layer == 2 and eye.collision_mask == 1 and not moon.get("nose").is_in_group("enemies"), "ordinary impulse preserves the original fixed native box and one eye HP target")


func _phase_checkpoint(id: String, stage: String, hp: float) -> bool:
	if not await _wait(func() -> bool: return moon.current_checkpoint().id == id and moon.get("stage") == stage, "actual deferred body/Player phase checkpoint " + id, 8.0, true) or not await _settle(): return false
	var saved: Dictionary = game.attempts.state().story.checkpoint
	if not _closed(saved) or not _expect(saved.level.local.eye.hp == hp and saved.level.local.stage == stage and saved.level.progress.checkpoint_id == id and saved.level.progress.checkpoint_kind == "boss_phase" and saved.level.local.pending_phase == 0 and _durable(game), "real parent settles committed HP/phase then publishes exact durable checkpoint outside hit callbacks"): return false
	hp_boundaries.append(hp)
	receipts.append({"stage": "actual " + id, "exact_snapshot": Exact.stringify(saved)})
	if paused: return await _click(game, "ResumeButton")
	return true


func _phase_observer(id: String, phase: int) -> void:
	var eye: CharacterBody3D = eye_ref.get_ref() as CharacterBody3D
	phase_observers.append({"source_id": id, "phase": phase, "hp": eye.get("hp"), "dead": eye.get("dead"), "clock_s": _scheduler().get_clock()})


func _defeat_observer(id: String) -> void:
	var eye: CharacterBody3D = eye_ref.get_ref() as CharacterBody3D
	terminal_observers.append({"kind": "eye-defeated", "source_id": id, "hp": eye.get("hp"), "dead": eye.get("dead"), "phase": eye.get("phase"), "lease_count": _scheduler().source_control_state(eye).reservations.size(), "cooldown": _scheduler().source_control_state(eye).cooldown, "clock_s": _scheduler().get_clock()})


func _hatch_and_transition() -> bool:
	if not _expect(moon.get("stage") == "hatch" and eye_ref.get_ref().get("dead") == true and _scheduler().source_control_state(eye_ref.get_ref()).reservations.is_empty() and _scheduler().source_control_state(eye_ref.get_ref()).cooldown == null and not moon.get("escape").started and terminal_observers.size() == 1 and terminal_observers[0].lease_count == 0 and terminal_observers[0].cooldown == null, "genuine committed eye defeat retires its own lease before observers and exposes unstarted hatch"): return false
	if not await _pause(): return false
	var hatch: Dictionary = game.capture_campaign_snapshot()
	if not _closed(hatch) or not _expect(hatch.level.local.eye.hp == 0.0 and hatch.level.local.eye.dead and hatch.level.local.stage == "hatch" and not hatch.level.progress.completed and hatch.level.progress.contact_exit_id == "", "pure actual hatch snapshot has HP0 without premature completion/contact"): return false
	receipts.append({"stage": "actual defeated hatch", "exact_snapshot": Exact.stringify(hatch)})
	if not await _click(game, "ResumeButton") or not await _wait(func() -> bool: return game.player.get_threat_response_state().stable and game.player.velocity == Vector3.ZERO, "actual stopped Hero before native hatch contact placement", 5.0): return false
	var before: Vector3 = game.player.global_position
	var goal: Vector3 = Layout.HATCH_POSITION; goal.y = before.y
	var support: Dictionary = Sweep.step(game.player, Transform3D(Basis.IDENTITY, goal), Vector3.ZERO, [moon.call("floor_region")])
	if not _expect(not support.has("error") and not support.get("collided", true), "actual x-2.75 hatch contact TEST placement has full native floor support"): return false
	game.player.global_position = goal
	setups.append({"kind": "TEST actual Hero placement into retained native hatch Area, not earned travel", "from": Codec.vector3(before), "to": Codec.vector3(goal)})
	if not await _wait(func() -> bool: return moon.get("stage") == "escape" and moon.get("escape").started, "real native Area overlap starts authored first-contact escape", 10.0): return false
	var original: Dictionary = moon.get("escape").duplicate(true)
	if not _expect(not hatch_entries.is_empty() and moon.get("_hatch").overlaps_body(game.player) and original.until_s == original.from_s + 0.75 and original.until_s == original.from_s + Layout.ESCAPE_DURATION_S and not original.finished, "actual first hatch contact starts exactly the original .75s shared-clock escape"): return false
	if not await _pause(): return false
	var escape: Dictionary = game.capture_campaign_snapshot()
	if not _closed(escape) or not _expect(escape.level.local.stage == "escape" and _same(escape.level.local.escape, original) and escape.level.local.scheduler.clock_s < original.until_s and not escape.level.progress.completed, "public Pause captures the original unfinished contact/deadline without publishing the next level"): return false
	var frozen: String = Exact.stringify(escape)
	await create_timer(0.06, true).timeout
	if not _expect(Exact.stringify(game.capture_campaign_snapshot()) == frozen, "paused actual escape clock/vignette/contact metadata freezes without reset"): return false
	receipts.append({"stage": "actual contact escape paused", "exact_snapshot": frozen})
	var carried: Dictionary = escape.player.resources.duplicate(true)
	var gear: Dictionary = escape.equipment_ids.duplicate(true)
	var old_hero_id: int = game.player.get_instance_id()
	var refs: Array[WeakRef] = _refs(game.world)
	if not await _click(game, "ResumeButton"): return false
	var end: int = Time.get_ticks_msec() + 12000
	while not finishing and not aborted and Time.get_ticks_msec() < end:
		if is_instance_valid(game.active_level) and game.active_level.level_id == "A2-L1": break
		if not game.campaign_error.is_empty(): return _expect(false, "real shared next-level transition refused: " + game.campaign_error)
		await process_frame
	if not _expect(game.active_level != null and game.active_level.level_id == "A2-L1" and paused and game.player.get_instance_id() != old_hero_id and game.active_level.hero == game.player and _count_players(game.world) == 1 and _freed(refs) and game.player.equipment.snapshot() == gear and game.player.hp == carried.hp and game.player.shells >= carried.shells and game.attempts.state().completed_main == Prefix + [Layout.LEVEL_ID] and _durable(game), "real shared completion/contact loads actual A2-L1 with one canonical Hero, carried resources/equipment and freed Moon world"): return false
	var next: Dictionary = game.capture_campaign_snapshot()
	if not _expect(not next.is_empty() and next.level_id == "A2-L1" and next.scene_path == game.registry.entry("A2-L1").scene_path and not next.level.progress.completed, "actual successor snapshot is a fresh uncompleted accepted scene, not a TEST destination substitute"): return false
	var completed: Array[Dictionary] = []
	var contacts: Array[Dictionary] = []
	for row: Dictionary in terminal_observers:
		if row.kind == "complete": completed.append(row)
		if row.kind == "contact": contacts.append(row)
	if not _expect(completed.size() == 1 and contacts.size() == 1 and completed[0].clock_s >= original.until_s and contacts[0].clock_s >= original.until_s and completed[0].escape_from_s == original.from_s and contacts[0].escape_until_s == original.until_s and completed[0].hp == 0.0 and contacts[0].hp == 0.0, "one real completion and contact follow the same original finished shared-clock escape"): return false
	receipts.append({"stage": "actual shared A1-L5 to A2-L1 transition", "next_snapshot": Exact.stringify(next), "original_escape": original, "terminal_observers": terminal_observers.duplicate(true)})
	return true


func _hatch_observer(body: Node3D) -> void:
	if body != game.player: return
	hatch_entries.append({"hero_id": str(body.get_instance_id()), "position": Codec.vector3(body.global_position), "clock_s": _scheduler().get_clock(), "parent_stage": moon.get("stage")})


func _completion_observer(id: String, completion: String) -> void:
	terminal_observers.append(_terminal_row("complete", id, completion))


func _contact_observer(id: String, contact: String) -> void:
	terminal_observers.append(_terminal_row("contact", id, contact))


func _terminal_row(kind: String, id: String, event: String) -> Dictionary:
	var value: Dictionary = moon.get("escape")
	return {"kind": kind, "level_id": id, "event_id": event, "stage": moon.get("stage"), "hp": eye_ref.get_ref().get("hp"), "clock_s": _scheduler().get_clock(), "escape_from_s": value.from_s, "escape_until_s": value.until_s, "escape_finished": value.finished}


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > EncounterWatchdogMs:
		_expect(false, "bounded focused actual Moon encounter/transition watchdog"); aborted = true; _finish.call_deferred()


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true; _end_watch("normal encounter final cleanup")
	# The test may resume from probe.tick_finished; retire outside its emitter callback.
	await process_frame
	if is_instance_valid(game) and not candidate.is_empty(): game._dispose(candidate); candidate = {}
	var refs: Array[WeakRef] = []
	for shell: CinderCampaignShell in [fresh, game]:
		if is_instance_valid(shell): refs.append_array(_refs(shell)); shell.free()
	fresh = null; game = null
	if is_instance_valid(probe): refs.append_array(_refs(probe)); probe.free()
	paused = false
	await create_timer(0.5, true).timeout; await process_frame
	_expect(_freed(refs) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal final Shell/successor/native-node/cue cleanup releases all descendants/groups")
	_expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH) == registry_bytes, "focused TEST prefix/metadata never change canonical campaign registration")
	var report: String = "res://.cinder/a1-l5-encounter-transition-%d.json" % Time.get_ticks_usec()
	var file := FileAccess.open(report, FileAccess.WRITE)
	if file == null: _expect(false, "focused encounter report is writable")
	else:
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "first_failure": first_failure, "setups": setups, "receipts": receipts, "circle_cycles": circle_cycles, "dash_requests": dash_requests, "drive_diagnostics": drive_diagnostics, "first_primary_only": first_primary_only, "execution_selection": "First actual genuine recovery primary only; later phase/final/hatch/successor paths unexecuted" if first_primary_only else "Original twelve ordinary hits, two phase checkpoints, final pair, hatch and actual successor", "hp_boundaries": hp_boundaries, "phase_observers": phase_observers, "primary_receipts": primary_receipts, "hatch_entries": hatch_entries, "terminal_observers": terminal_observers, "observations": observations, "wall_ms": Time.get_ticks_msec() - started_ms, "scope": "First-primary-only diagnostic: actual TEST return/capsule entry, native Blink sample/dash/recovery/pure transport, one ordinary primary240-to220 and normal cleanup. Later HP phases/final pair/hatch/escape/successor remain unexecuted. No earned route, private opening or new gameplay gate." if first_primary_only else "Actual production Moon parent/native source grammar/ordinary Player primary HP240-160-80-0/deferred phase checkpoints/pure paused snapshots/fixed warning sample/real staggered final/retained native hatch first contact/original shared-clock .75s escape/actual shared A2-L1 transition/normal cleanup. Isolated TEST L5 registration/four unearned predecessor IDs, public rusher injury and supported same-floor Hero placements; recovery-only low-rim placements are not earned return movement. No private state/provider/eye-HP/sample/clock/checkpoint seed, extra gameplay actor/controller/camera, blast/ammo requirement or resource refill. Not an earned route, full-playthrough acceptance gate, gesture/art/all-kit/balance/mobile proof."}, "\t")); file.close()
	var directory := DirAccess.open(test_root)
	if directory != null:
		for name: String in directory.get_files(): DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L5 ENCOUNTER TRANSITION: %d checks/%d failures; report=%s; focused TEST mechanics/transition only" % [checks, failures, report])
	quit(1 if failures > 0 else 0)
