extends "res://tests/acts/act1/a1_o2_campaign.gd"
## SOURCE ONLY. Explicit --terminal-case=retry|completion|replay and genuine
## --groups-report=... --campaign-report=... are required. Replay also requires
## --completion-report=<genuine successful completion-case report>. No invented
## packets, completion flags, stamp, proof, clock or cross-process ID comparison.
## Public Attempts/Store assembles their unchanged native CP/hatch and protected
## Story into an isolated TEST side Session; this is not earned traversal.

const TerminalSweep = preload("res://scripts/combat/body_sweep.gd")
const PREFINAL_LABEL: String = "actual pre-final checkpoint"
const HATCH_LABEL: String = "actual incomplete hatch before contact"
const CAMPAIGN_ENTRANCE_LABEL: String = "actual pristine optional entrance"
const COMPLETION_LABEL: String = "actual terminal contact completion and protected Story return"
const TERMINAL_WATCHDOG_MS: int = 120000

var prefinal: Dictionary = {}
var hatch: Dictionary = {}
var original_attempts: Dictionary = {}
var source_reports: Array[Dictionary] = []
var observation_overruns: Array[Dictionary] = []
var pause_registration_barriers: Array[Dictionary] = []
var terminal_case: String = ""
var original_report_sha256: Dictionary = {}
var completed_session: Dictionary = {}
var registration_observation_barriers: Array[Dictionary] = []


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	test_root = "user://test-act1-o2-terminal-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	report_path = "res://.cinder/a1-o2-terminal-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	old_fps = Engine.max_fps
	old_audio = AudioServer.generate_bus_layout()
	process_frame.connect(_watchdog)
	node_added.connect(_observe_added)
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	var groups_path: String = ""
	var campaign_path: String = ""
	var completion_path: String = ""
	var seen: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		var key: String = argument.get_slice("=", 0)
		if key not in ["--terminal-case", "--groups-report", "--campaign-report", "--completion-report"] or seen.has(key) or argument.find("=") < 0:
			_expect(false, "terminal requires unique named case/source-report paths and no preview/unknown flags"); await _finish(); return
		seen[key] = true
		match key:
			"--terminal-case": terminal_case = argument.trim_prefix("--terminal-case=")
			"--groups-report": groups_path = argument.trim_prefix("--groups-report=")
			"--campaign-report": campaign_path = argument.trim_prefix("--campaign-report=")
			"--completion-report": completion_path = argument.trim_prefix("--completion-report=")
	if not _expect(terminal_case in ["retry", "completion", "replay"] and not groups_path.is_empty() and not campaign_path.is_empty() and ((terminal_case == "replay" and not completion_path.is_empty()) or (terminal_case != "replay" and completion_path.is_empty())), "explicit terminal case and both original successful reports required; only replay requires a genuine successful completion report"):
		await _finish(); return
	var groups: Dictionary = _read_report(groups_path, "groups")
	var campaign: Dictionary = _read_report(campaign_path, "campaign")
	if groups.is_empty() or campaign.is_empty(): await _finish(); return
	prefinal = _read_unit(_unique_receipt(groups.native_units, PREFINAL_LABEL), "exact_snapshot", PREFINAL_LABEL)
	hatch = _read_unit(_unique_receipt(groups.native_units, HATCH_LABEL), "exact_snapshot", HATCH_LABEL)
	var original: Dictionary = _unique_receipt(campaign.receipts, CAMPAIGN_ENTRANCE_LABEL)
	original_attempts = _read_exact_dictionary(original.get("exact_attempts"), "original campaign entrance Attempt session")
	protected_story = _read_exact_dictionary(original.get("exact_protected_story"), "original exact protected L3 Story Attempt")
	if not _expect(_terminal_shape(prefinal, true) and _terminal_shape(hatch, false) and not original_attempts.is_empty() and not protected_story.is_empty() and _same(original_attempts.get("story"), protected_story) and original_attempts.get("completed_main") == PREFIX and original_attempts.get("completed_optional") == [] and original_attempts.get("reward_ids") == [], "original successful reports contain genuine exact native pre-final/hatch packets and unchanged protected Story without a pregranted stamp"):
		await _finish(); return
	unlocked_before = original_attempts.unlocked_equipment.duplicate()
	if not _configure_test_registry(): await _finish(); return
	if terminal_case == "replay":
		if not _restore_completed_session(completion_path) or not await _new_shell(): await _finish(); return
		if not _expect(_same(game.attempts.state(), completed_session) and _completed_state(game.attempts.state()) and _durable(), "fresh actual disk Title preserves the complete original successful completion Session without manufacturing a stamp"):
			await _finish(); return
		await _run_replay()
		return
	if not _assemble_hatch_session(terminal_case + " case original hatch Session; no earlier case replay") or not await _new_shell() or not await _load_hatch(terminal_case + " case original hatch Title Continue"):
		await _finish(); return
	if terminal_case == "retry":
		if not await _pause("actual hatch RetryButton page") or not await _retry_prefinal(): await _finish(); return
		await _finish()
		return
	await _run_completion()


func _run_completion() -> void:
	# Preserve actual native recovery and public Save coverage. The original
	# hatch is stable but retains a real .0833s primary cooldown; never seed it.
	if not await _resume("genuine terminal contact") or not await _wait_live(_primary_ready, "actual healthy hatch Hero settles naturally", 4.0):
		await _finish(); return
	if not await _pause("settled hatch before disclosed TEST contact pose"):
		await _finish(); return
	var terminal_level_id: String = str(game.active_level.get_instance_id())
	var terminal_refs: Array[WeakRef] = _refs(game.world)
	var contact_requested_ms: int = Time.get_ticks_msec()
	if not _place_contact_while_paused() or not await _resume("actual real Area contact"):
		await _finish(); return
	operation = "real deferred native hatch contact completion and protected Story return"
	# Both publications must be the actual installed O2's original signals.
	# A predicate-first observation retains any synchronous wall overrun.
	if not await _await_operation(func() -> bool: return _progress_kinds(terminal_level_id) == ["completion", "exit"], "actual target O2 publishes genuine completion then exit", 16.0):
		await _finish(); return
	if not await _observe_paused_registration("actual contact completion/exit/Story installation", 3, contact_requested_ms, func() -> bool: return _story_returned()): await _finish(); return
	if not await _await_operation(func() -> bool: return _story_returned(), "real native Area contact records completion/exit/stamp and restores protected Story", 16.0):
		await _finish(); return
	var completed: Dictionary = game.attempts.state()
	if not _expect(_freed(terminal_refs) and _completed_state(completed) and _progress_kinds(terminal_level_id) == ["completion", "exit"] and _same(game.capture_campaign_snapshot(), protected_story.snapshot) and _durable(), "actual contact emits one genuine completion then exit, frees O2, records one existing stamp without main/equipment growth and restores exact protected Story"):
		await _finish(); return
	receipts.append({"label": COMPLETION_LABEL, "terminal_case": terminal_case, "process_id": OS.get_process_id(), "exact_attempts": Exact.stringify(completed), "exact_snapshot": Exact.stringify(game.capture_campaign_snapshot()), "exact_protected_story": Exact.stringify(completed.story), "native_progress": _progress_kinds(terminal_level_id), "original_hatch_snapshot_sha256": Exact.stringify(hatch).sha256_text(), "source_report_sha256": original_report_sha256.duplicate(true)})
	await _finish()


func _observe_paused_registration(label: String, maximum_scopes: int, requested_ms: int, done: Callable) -> bool:
	# Source-derived public operations have these bounded native registrations:
	# contact3: complete, exit/live record, protected Story installation;
	# Title Replay3: load active Story, live record, fresh side installation;
	# Replay Leave1: protected Story installation. Each registration permits one
	# process signal plus one same-counter fallback. Signals are observation
	# budget only, never claimed as private phase transitions or mutation rights.
	var observed_ms: int = Time.get_ticks_msec()
	var signals: Array[Dictionary] = []
	if not _expect(maximum_scopes in [1, 3], "source-pinned finite native registration observation budget"): return false
	if not _operation_healthy() or not _expect(paused, "public Shell operation retains paused custody before registration observation: " + label): return false
	for scope_budget: int in range(maximum_scopes):
		if done.call() == true: break
		for signal_budget: int in range(2):
			if done.call() == true: break
			await process_frame
			if not _operation_healthy(): return false
			if not _expect(paused, "actual paused custody during registration observation %d/%d: " % [scope_budget + 1, signal_budget + 1] + label): return false
			signals.append({"scope_budget": scope_budget + 1, "signal_budget": signal_budget + 1, "elapsed_from_public_request_ms": Time.get_ticks_msec() - requested_ms, "actual_final_predicate": done.call() == true})
	registration_observation_barriers.append({"label": label, "source_derived_maximum_registration_scopes": maximum_scopes, "maximum_process_signals_per_scope": 2, "actual_process_signals": signals.size(), "signals": signals, "request_to_barrier_observation_start_wall_ms": observed_ms - requested_ms, "barrier_observation_wall_ms": Time.get_ticks_msec() - observed_ms, "request_to_barrier_wall_ms": Time.get_ticks_msec() - requested_ms, "scope": "actual bounded paused process-signal observation of source-pinned public operation; native validators/2s registration custody and120s fixture watchdog unchanged; full synchronous cost retained, no latency/performance pass"})
	return true


func _restore_completed_session(path: String) -> bool:
	var report: Dictionary = _read_report(path, "completion")
	if report.is_empty(): return false
	if not _expect(report.get("terminal_case") == "completion" and _same(report.get("source_report_sha256"), original_report_sha256), "only a genuine successful completion-case report from identical original groups/campaign byte hashes can supply Replay"):
		return false
	var row: Dictionary = _unique_receipt(report.receipts, COMPLETION_LABEL)
	completed_session = _read_exact_dictionary(row.get("exact_attempts"), "original successful completion exact Attempts")
	var returned: Dictionary = _read_exact_dictionary(row.get("exact_snapshot"), "original successful completion exact protected Story snapshot")
	var registry: CinderCampaignRegistry = Registry.new(raw)
	var model: CinderCampaignAttempts = Attempts.new(registry)
	if not _expect(not completed_session.is_empty() and model.state_error(completed_session).is_empty() and _completed_state(completed_session) and row.get("terminal_case") == "completion" and row.get("native_progress") == ["completion", "exit"] and row.get("original_hatch_snapshot_sha256") == Exact.stringify(hatch).sha256_text() and _same(row.get("source_report_sha256"), original_report_sha256) and row.get("exact_protected_story") == Exact.stringify(protected_story) and _same(returned, protected_story.snapshot), "original completed receipt preserves exact whole protected Story/PREFIX/unlocked equipment, one actual stamp, no side attempt, genuine hatch SHA and original report provenance"):
		return false
	if not _expect(model.restore_session(completed_session) and _same(model.state(), completed_session), "public Attempts restores the original successful completed Session without sanitization or manufactured completion"):
		return false
	var store: CinderSaveStore = Store.new(test_root + "campaign.json")
	store.payload_validator = model.saved_payload_error
	if not _expect(store.write_payload(completed_session), "public validated isolated Store persists the unchanged genuine completed Session for fresh Title Replay"):
		return false
	setups.append({"kind": "TEST original genuine successful completion Session loaded unchanged through public Attempts/Store; no earned completion replay or stamp manufacture", "source_report": path, "source_report_sha256": FileAccess.get_sha256(path), "exact_attempts_sha256": Exact.stringify(completed_session).sha256_text(), "original_hatch_snapshot_sha256": Exact.stringify(hatch).sha256_text()})
	return true


func _run_replay() -> void:
	# Public Replay from Title is supported: Shell's side operation first loads
	# protected Story when no level is live, then normally records it and enters
	# a fresh Replay. No private load/registration/candidate entry is invoked.
	operation = "public completed optional Replay from fresh Title"
	var replay_requested_ms: int = Time.get_ticks_msec()
	game.menu.replay_requested.emit(Bloom.LEVEL_ID, Equipment.STARTER)
	if not await _observe_paused_registration("public Title Replay load/record/fresh side", 3, replay_requested_ms, func() -> bool: return _live(Bloom.LEVEL_ID) and paused and game.attempts.active_kind() == "replay" and game.menu.page_name() == "resume"):
		await _finish(); return
	if not await _await_operation(func() -> bool: return _live(Bloom.LEVEL_ID) and paused and game.attempts.active_kind() == "replay" and game.menu.page_name() == "resume", "public Replay installs a pristine isolated O2", 12.0):
		await _finish(); return
	var replay: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_pristine(replay) and _bindings() and game.player.hp == game.player.max_hp and game.player.shells == game.player.max_shells and game.attempts.state().completed_optional == [Bloom.LEVEL_ID] and game.attempts.state().reward_ids == [REWARD_ID] and _same(game.attempts.state().story, protected_story) and _durable(), "actual pristine Replay keeps only the existing stamp and protected Story, with no borrowed terminal state"):
		await _finish(); return
	receipts.append({"label": "actual pristine completed-optional Replay", "exact_snapshot": Exact.stringify(replay), "exact_attempts": Exact.stringify(game.attempts.state()), "native_identities": _ids(), "process_id": OS.get_process_id()})
	var replay_refs: Array[WeakRef] = _refs(game.world)
	operation = "public Replay Leave"
	var leave_requested_ms: int = Time.get_ticks_msec()
	game.menu.leave_side_requested.emit()
	if not await _observe_paused_registration("public Replay Leave protected Story installation", 1, leave_requested_ms, func() -> bool: return _story_returned()):
		await _finish(); return
	if not await _await_operation(func() -> bool: return _story_returned(), "public Replay Leave restores original Story", 12.0):
		await _finish(); return
	_expect(_freed(replay_refs) and _completed_state(game.attempts.state()) and _same(game.capture_campaign_snapshot(), protected_story.snapshot) and _durable(), "normal pristine Replay Leave frees its world and retains one stamp and exact protected Story")
	await _finish()


func _read_report(path: String, kind: String) -> Dictionary:
	var content: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var parsed: Variant = JSON.parse_string(content.get_string_from_utf8())
	if not _expect(not content.is_empty() and parsed is Dictionary and Codec.is_number(parsed.get("checks")) and parsed.checks > 0 and parsed.get("failures", -1) == 0 and parsed.get("native_units" if kind == "groups" else "receipts") is Array and parsed.get("first_failure") is Dictionary and parsed.first_failure.is_empty(), "actual " + kind + " report is present and successful; original failures cannot be relabeled"):
		return {}
	source_reports.append({"kind": kind, "path": path, "sha256": FileAccess.get_sha256(path), "checks": parsed.checks, "failures": parsed.failures, "scope": parsed.get("scope", ""), "elapsed_ms": parsed.get("elapsed_ms")})
	if kind in ["groups", "campaign"]: original_report_sha256[kind] = FileAccess.get_sha256(path)
	return parsed


func _unique_receipt(rows: Array, label: String) -> Dictionary:
	var matches: Array[Dictionary] = []
	for row: Variant in rows:
		if row is Dictionary and row.get("label") == label: matches.append(row)
	if not _expect(matches.size() == 1, "one original uniquely labeled receipt required: " + label): return {}
	return matches[0]


func _read_exact_dictionary(value: Variant, label: String) -> Dictionary:
	if not _expect(value is String and not value.is_empty(), "original exact typed wire required: " + label): return {}
	var parsed: Dictionary = Exact.parse(value)
	if not _expect(parsed.get("accepted") == true and parsed.get("value") is Dictionary and not parsed.value.is_empty() and Exact.stringify(parsed.value) == value, "original typed wire parses and preserves exact scalar bits: " + label): return {}
	return parsed.value


func _read_unit(row: Dictionary, key: String, label: String) -> Dictionary:
	var unit: Dictionary = _read_exact_dictionary(row.get(key), label)
	if unit.is_empty(): return {}
	if not _expect(row.get("snapshot_sha256") == Exact.stringify(unit).sha256_text() and row.get("exact_player") == Exact.stringify(unit.get("player")) and row.get("exact_level") == Exact.stringify(unit.get("level")), "original native-unit receipt hashes and separately recorded Player/level packets agree: " + label): return {}
	source_reports.append({"receipt_label": label, "wire_sha256": Exact.stringify(unit).sha256_text()})
	return unit


func _terminal_shape(unit: Dictionary, checkpoint: bool) -> bool:
	if not _closed(unit) or unit.get("level_id") != Bloom.LEVEL_ID or unit.get("scene_path") != O2_PATH or unit.get("paused") != true or not unit.level.get("local") is Dictionary: return false
	var local: Dictionary = unit.level.local
	if not BloomCodec.metadata_error(local).is_empty() or not BloomCodec.progress_error(unit.level).is_empty() or local.beat_index != (2 if checkpoint else 3) or local.room_stage != ("approach" if checkpoint else "hatch") or not local.checkpoint_published or unit.level.progress.completed or unit.level.progress.checkpoint_id != Bloom.CHECKPOINT_ID: return false
	for id: String in Bloom.SOURCE_IDS:
		var source: Dictionary = local.sources[id]
		var future: bool = checkpoint and id in Bloom.group_ids(2)
		if source.dead == future or source.dormant != future or source.hp != ((24.0 if id == "bloom-final-guard" else 16.0) if future else 0.0) or source.schema_version != (1 if future else 3): return false
	for id: String in Bloom.FIELD_IDS:
		var field: Variant = local.fields[id]
		if not field is Dictionary or field.schema_version != 1 or field.generation != 2 or field.phase != "spent" or field.spent_ids.size() != 2: return false
	for index: int in range(3):
		var consumer: Variant = local.consumers[Bloom.consumer_id(index)]
		if checkpoint and index == 2:
			if consumer != null: return false
		elif not consumer is Dictionary or consumer.schema_version != 2: return false
	return true


func _configure_test_registry() -> bool:
	registry_bytes = FileAccess.get_file_as_bytes(Registry.DATA_PATH)
	var parsed: Variant = JSON.parse_string(registry_bytes.get_string_from_utf8())
	if not _expect(parsed is Dictionary and parsed.get("levels") is Array, "actual canonical Registry is available for one isolated TEST override"): return false
	raw = parsed.duplicate(true)
	var changed: int = 0
	for row: Dictionary in raw.levels:
		if row.id == Bloom.LEVEL_ID:
			setups.append({"kind": "TEST in-memory O2 Registry row only", "before": row.duplicate(true)})
			row.scene_path = O2_PATH; row.readiness = "accepted"; row.accepted_commit = "f".repeat(40); row.api_revision = Registry.API_REVISION
			changed += 1
	var registry: CinderCampaignRegistry = Registry.new(raw)
	return _expect(changed == 1 and registry.last_error.is_empty() and registry.scene_error(Bloom.LEVEL_ID).is_empty() and registry.scene_error("A1-L3").is_empty() and registry.entry(Bloom.LEVEL_ID).reward_id == REWARD_ID, "only O2 scene/readiness is TEST enabled; original accepted Story and once-only stamp identity remain authoritative")


func _assemble_hatch_session(label: String) -> bool:
	var registry: CinderCampaignRegistry = Registry.new(raw)
	var model: CinderCampaignAttempts = Attempts.new(registry)
	if not _expect(model.restore_session(original_attempts) and _same(model.state(), original_attempts), "public Attempts restores unchanged original successful campaign session without sanitizing packets"): return false
	if not _expect(model.record_snapshot(prefinal, true) and model.record_snapshot(hatch, false), "public validated Attempts assembles original genuine pre-final checkpoint and later incomplete hatch without packet manufacture"): return false
	var payload: Dictionary = model.state()
	var store: CinderSaveStore = Store.new(test_root + "campaign.json")
	store.payload_validator = model.saved_payload_error
	if not _expect(model.state_error(payload).is_empty() and _same(payload.story, protected_story) and _same(payload.side_attempt.snapshot, hatch) and _same(payload.side_attempt.checkpoint, prefinal) and payload.completed_optional.is_empty() and payload.reward_ids.is_empty() and store.write_payload(payload), "public isolated Store persists exact assembled original native Session without pregranting completion or stamp"): return false
	setups.append({"kind": "TEST representative Session assembly from successful genuine reports; no earned route or group replay", "label": label, "prefinal_sha256": Exact.stringify(prefinal).sha256_text(), "hatch_sha256": Exact.stringify(hatch).sha256_text(), "protected_story_sha256": Exact.stringify(protected_story).sha256_text()})
	return true


func _load_hatch(label: String) -> bool:
	operation = label
	if not _expect(paused and game.active_level == null and game.player == null and game.menu.page_name() == "title", "fresh actual disk Title has no installed Hero/level before this case's independent original hatch Continue"): return false
	game.menu.resume_requested.emit()
	if not await _await_operation(func() -> bool: return _live(Bloom.LEVEL_ID) and paused and game.menu.page_name() == "resume" and game.attempts.active_kind() == "optional", "actual Title active-side Continue installs original hatch", 12.0): return false
	var captured: Dictionary = game.capture_campaign_snapshot()
	var callbacks: Array[Dictionary] = _recipient_callbacks()
	if not _expect(_terminal_shape(captured, false) and _same(captured, hatch) and callbacks.is_empty() and _bindings() and _same(game.attempts.state().side_attempt.checkpoint, prefinal) and _same(game.attempts.state().story, protected_story) and _durable(), "actual current installed hatch preserves all nine dead packets, two spent fields, three consumers and exact Story/CP with zero recipient callbacks: " + label): return false
	receipts.append({"label": label, "exact_snapshot": Exact.stringify(captured), "exact_attempts": Exact.stringify(game.attempts.state()), "native_identities": _ids(), "new_installed_recipient_callbacks": callbacks, "process_id": OS.get_process_id(), "fresh_title_no_installed_hero_or_level": true})
	return true


func _pause(label: String) -> bool:
	operation = "public Pause: " + label
	var generation_before: int = _save_generation()
	var requested_ms: int = Time.get_ticks_msec()
	game.request_pause()
	# Public Pause defers its drain. Native registration constructs every raw
	# candidate synchronously, then requires one process signal (or one extra
	# same-counter signal). Observe those actual paused signals before starting
	# the asynchronous completion wait, so an expired observer cannot free the
	# Shell before its registration continuation runs. Preserve the full cost.
	for signal_index: int in range(2):
		await process_frame
		if not _operation_healthy(): return false
		if not _expect(paused, "public Pause retains paused custody during registration signal %d: " % (signal_index + 1) + label): return false
	pause_registration_barriers.append({"label": label, "actual_process_signals": 2, "request_to_barrier_wall_ms": Time.get_ticks_msec() - requested_ms, "scope": "actual paused registration observation; full synchronous cost retained, no latency/performance pass"})
	if not await _await_operation(func() -> bool: return paused and game.menu.page_name() == "pause" and _save_generation() > generation_before, "deferred public Pause commits a new whole-unit Save generation", 8.0): return false
	return _expect(game.campaign_error.is_empty() and _durable(), "normal public Pause persists actual native unit: " + label)


func _retry_prefinal() -> bool:
	var button := game.menu.find_child("RetryButton", true, false) as Button
	if not _expect(button != null and button.is_visible_in_tree() and not button.disabled and game.menu.page_name() == "pause", "actual production pause Menu exposes enabled RetryButton"): return false
	var before: Dictionary = _ids()
	var refs: Array[WeakRef] = _refs(game.world)
	operation = "actual RetryButton signal restores original genuine pre-final checkpoint"
	button.pressed.emit()
	if not await _await_operation(func() -> bool: return _live(Bloom.LEVEL_ID) and paused and game.menu.page_name() == "resume" and _ids() != before, "real GUI-to-Shell Retry installs original earlier pre-final unit", 16.0): return false
	var captured: Dictionary = game.capture_campaign_snapshot()
	var callbacks: Array[Dictionary] = _recipient_callbacks()
	if not _expect(_terminal_shape(captured, true) and _same(captured, prefinal) and _all_new(before, _ids()) and _freed(refs) and callbacks.is_empty() and _bindings() and _same(game.attempts.state().story, protected_story) and _same(game.attempts.state().side_attempt.checkpoint, prefinal) and _durable(), "actual Retry frees hatch donor and quietly restores original dead-prefix/final-dormant/two-consumer native checkpoint without refreshing spent fields"): return false
	receipts.append({"label": "actual RetryButton restores original pre-final checkpoint", "exact_snapshot": Exact.stringify(captured), "exact_attempts": Exact.stringify(game.attempts.state()), "before_identities": before, "native_identities": _ids(), "new_installed_recipient_callbacks": callbacks, "scope": "actual Button pressed signal wiring; no OS click or input recognizer claim"})
	return true


func _place_contact_while_paused() -> bool:
	if not _expect(paused and _live(Bloom.LEVEL_ID) and game.player.velocity == Vector3.ZERO and game.active_level.call("bloom_state").room_stage == "hatch", "actual paused healthy stationary hatch recipient precedes TEST contact pose"): return false
	var point := Vector3(Bloom.EXIT.x, game.player.global_position.y, Bloom.EXIT.z)
	var floors: Array = (game.active_level.call("scheduler_bindings") as Dictionary).floors.values()
	var measured: Dictionary = TerminalSweep.sweep(game.player, Transform3D(game.player.global_basis, point), Vector3.ZERO, floors)
	if not _expect(not measured.has("error") and not measured.get("collided", true) and measured.get("end") is Vector3 and measured.end.distance_to(point) <= TerminalSweep.position_rounding_bound(point, point), "disclosed TEST contact pose has actual full native floor/scenery capsule clearance"): return false
	setups.append({"kind": "TEST same-floor Hero contact position only; no earned route or direct progress", "before": _encode(game.player.global_position), "after": _encode(point)})
	game.player.global_position = point
	return true


func _story_returned() -> bool:
	return _live("A1-L3") and paused and game.attempts.active_kind() == "story" and game.menu.page_name() == "journey"


func _completed_state(state: Dictionary) -> bool:
	return state.completed_main == PREFIX and state.completed_optional == [Bloom.LEVEL_ID] and state.reward_ids == [REWARD_ID] and state.unlocked_equipment == unlocked_before and _same(state.story, protected_story) and state.side_attempt == null


func _progress_kinds(level_instance_id: String) -> Array[String]:
	var kinds: Array[String] = []
	for row: Dictionary in observations:
		if row.level_instance_id == level_instance_id and row.kind in ["completion", "exit"]: kinds.append(row.kind)
	return kinds


func _await_operation(predicate: Callable, label: String, seconds: float) -> bool:
	# A synchronous native validation may return after the wall deadline with
	# the operation already complete. Observe actual state before deadline; keep
	# the original waiting limit and report every observed synchronous overrun.
	var begin: int = Time.get_ticks_msec()
	var deadline: int = begin + int(seconds * 1000.0)
	while not finishing:
		if not _operation_healthy(): return false
		if predicate.call() == true:
			await process_frame
			if not _operation_healthy() or predicate.call() != true: return false
			if Time.get_ticks_msec() > deadline: observation_overruns.append({"operation": operation, "label": label, "waiting_limit_s": seconds, "observed_wall_ms": Time.get_ticks_msec() - begin, "scope": "completed actual synchronous operation observed after deadline; no total wall-time performance pass"})
			return true
		if Time.get_ticks_msec() > deadline: return _expect(false, "bounded waiting operation did not complete: " + label)
		await process_frame
	return false


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > TERMINAL_WATCHDOG_MS:
		_expect(false, "actual O2 terminal watchdog reached120 wall seconds")
		_finish.call_deferred()


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true; operation = "normal terminal final cleanup"
	var refs: Array[WeakRef] = []
	if is_instance_valid(game):
		if is_instance_valid(game.active_level): game.active_level.exit_level()
		refs.append_array(_refs(game)); game.free(); game = null
	paused = false
	await create_timer(.5, true).timeout
	await process_frame
	_expect((refs.is_empty() or _freed(refs)) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("environment_attack_targets").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal terminal public level exit/Shell cleanup frees native descendants and groups")
	if not registry_bytes.is_empty(): _expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH) == registry_bytes, "isolated terminal Session never changes canonical Registry bytes")
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	var exact_receipts: Array[String] = []
	var exact_observations: Array[String] = []
	var exact_ok: bool = true
	for row: Dictionary in receipts:
		var wire: String = Exact.stringify(_encode(row))
		exact_ok = exact_ok and not wire.is_empty(); exact_receipts.append(wire)
	for row: Dictionary in observations:
		var wire: String = Exact.stringify(_encode(row))
		exact_ok = exact_ok and not wire.is_empty(); exact_observations.append(wire)
	_expect(exact_ok, "original terminal observations retain exact finite scalar transport")
	var output := FileAccess.open(report_path, FileAccess.WRITE)
	if output == null: _expect(false, "unique terminal report is writable")
	else:
		output.store_string(JSON.stringify({"checks": checks, "failures": failures, "first_failure": first_failure, "elapsed_ms": Time.get_ticks_msec() - started_ms, "terminal_case": terminal_case, "process_id": OS.get_process_id(), "source_report_sha256": original_report_sha256, "isolated_store_path": test_root + "campaign.json", "isolated_store_absolute_path": ProjectSettings.globalize_path(test_root + "campaign.json"), "source_reports": source_reports, "setups": setups, "receipts": receipts, "observations": observations, "exact_receipts": exact_receipts, "exact_observations": exact_observations, "synchronous_observation_overruns": observation_overruns, "pause_registration_barriers": pause_registration_barriers, "registration_observation_barriers": registration_observation_barriers, "scope": _case_scope()}, "\t"))
		output.close()
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-O2 TERMINAL: %d checks, %d failures; report=%s" % [checks, failures, report_path])
	quit(1 if failures > 0 else 0)


func _case_scope() -> String:
	var shared: String = "Explicit isolated terminal case; original exact genuine groups/campaign packets and protected Story, O2-only in-memory TEST Registry metadata, public validated Attempts/Store, original120s watchdog and unchanged native guards, full wall costs and original failures retained, normal in-tree level/Shell/group cleanup and canonical Registry preservation. No cross-process object-ID inequality, OS click/recognizer, earned traversal/group replay, full-route/all-kit/balance/portrait/performance/mobile claim. "
	match terminal_case:
		"retry": return shared + "Retry case only: actual fresh Title active-side Continue of original dead9/two-spent-field/three-consumer hatch, exact quiet installed recipient/current native ownership; actual public Pause Save and production RetryButton pressed signal to original dead5/final4-dormant/two-consumer pre-final checkpoint, same-process distinct identities and donor cleanup. No completion/stamp/Replay acceptance from this case."
		"completion": return shared + "Completion case only: same original incomplete hatch from an independent fresh Title, actual Resume and natural primary readiness, public Pause Save, measured disclosed same-floor Hero-position-only contact setup, public Resume, genuine Area/deferred completion then exit, bounded paused observation of three native registration scopes, once-only existing stamp/no equipment or main growth, exact protected Story return and complete original exact Attempts receipt. No prior Retry loop or Replay acceptance from this case."
		"replay": return shared + "Replay case only: successful completion-case report must match both original producer report hashes, original hatch SHA and exact completed Attempts/whole protected Story/PREFIX/unlocked IDs/one stamp/no side. Unchanged exact Session through public Attempts/Store to fresh Title, public Replay normally loads/records protected Story before pristine O2 creation, then public Leave preserves stamp and exact Story and frees Replay. No manufactured completion or rerun of contact/Retry."
	return shared + "Invalid/missing case; no terminal case acceptance."
