extends "res://tests/acts/act1/a1_o2_terminal.gd"
## Producer first: literal pre-amendment API1 pre-final unit -> real Challenge
## final admission -> public Save. No new-runtime API, synthetic metadata,
## actor/field/clock/order edit, engine bypass or contact/reward/replay exercise.

const GROUPS_SHA: String = "726ba709eab75de92e15faffbb11e7299a10d2cf5367ad5f26791e6a04a7c5ec"
const RETRY_SHA: String = "0ca626cf87f9dc0244485debff6f3fb5a992e4dd447752f497ebcdd964b73e72"
const RETRY_ATTEMPTS_SHA: String = "b0b7992da7a5d1df15ce813ed1c17fa444750d979d937e54bb0be8855ecf4f42"
const PREFINAL_SHA: String = "89362ffe46810d719700fb664aaebde20678b27ec3ce30789fc27a0327ee2c6d"
const PROBE_IDS: Array[String] = ["bloom-final-west", "bloom-final-guard"]
const PRODUCER_INPUTS: Array[String] = [
	"scripts/acts/act1/spore_bloom.gd", "scripts/acts/act1/spore_bloom_layout.gd", "scripts/acts/act1/spore_bloom_codec.gd",
	"scripts/acts/act1/mushroom_caverns.gd", "scripts/acts/act1/mushroom_selenite.gd",
	"scripts/combat/threat_scheduler.gd", "scripts/environment/spore_field.gd", "scripts/environment/spore_repulsion.gd",
	"scripts/campaign/shell.gd", "scripts/campaign/level.gd", "scripts/campaign/attempts.gd", "scripts/campaign/save_store.gd",
	"tests/acts/act1/a1_o2_campaign.gd", "tests/acts/act1/a1_o2_terminal.gd", "tests/acts/act1/a1_o2_difficulty.gd",
]

class AdmissionProbe extends Node:
	var inspect: Callable
	func _physics_process(delta: float) -> void:
		if inspect.is_valid(): inspect.call(delta)

var difficulty_case: String = ""
var producer_sources: Dictionary = {}
var latest_probe: Dictionary = {}
var eligibility_rows: Array[Dictionary] = []
var first_admission: Dictionary = {}
var probe_node: AdmissionProbe


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	test_root = "user://test-act1-o2-difficulty-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	report_path = "res://.cinder/a1-o2-difficulty-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	old_fps = Engine.max_fps; old_audio = AudioServer.generate_bus_layout()
	for path: String in PRODUCER_INPUTS: producer_sources[path] = FileAccess.get_sha256("res://" + path)
	process_frame.connect(_watchdog); node_added.connect(_observe_added)
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	var options: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		var key: String = argument.get_slice("=", 0)
		if key not in ["--case", "--groups-report", "--retry-report"] or options.has(key) or argument.find("=") < 0:
			_expect(false, "producer requires unique named case/report arguments only"); await _finish(); return
		options[key] = argument.substr(argument.find("=") + 1)
	difficulty_case = String(options.get("--case", ""))
	if not _expect(difficulty_case == "legacy-producer" and options.has_all(["--groups-report", "--retry-report"]), "explicit legacy-producer and both genuine source reports required"):
		await _finish(); return
	var groups_path: String = options["--groups-report"]
	var retry_path: String = options["--retry-report"]
	if not _expect(FileAccess.get_sha256(groups_path) == GROUPS_SHA and FileAccess.get_sha256(retry_path) == RETRY_SHA, "literal original successful groups01/terminal-retry01 reports match supplied hashes"):
		await _finish(); return
	var groups: Dictionary = _read_report(groups_path, "groups")
	var retry: Dictionary = _read_report(retry_path, "retry")
	original_report_sha256["retry"] = RETRY_SHA
	if groups.is_empty() or retry.is_empty(): await _finish(); return
	prefinal = _read_unit(_unique_receipt(groups.native_units, PREFINAL_LABEL), "exact_snapshot", PREFINAL_LABEL)
	var original: Dictionary = _unique_receipt(retry.receipts, "actual RetryButton restores original pre-final checkpoint")
	original_attempts = _read_exact_dictionary(original.get("exact_attempts"), "original complete successful Retry Attempts")
	protected_story = original_attempts.get("story", {}).duplicate(true)
	if not _expect(_terminal_shape(prefinal, true) and Exact.stringify(prefinal).sha256_text() == PREFINAL_SHA and prefinal.level.local.api_revision == "act1-spore-bloom-1" and prefinal.level.local.schema_version == 1 and not prefinal.level.local.has("final_arrangement") and Exact.stringify(original_attempts).sha256_text() == RETRY_ATTEMPTS_SHA and original.get("exact_snapshot") == Exact.stringify(prefinal) and not protected_story.is_empty(), "literal API1 pre-final unit retains original native dead prefix, dormant final four, spent fields and protected Story"):
		await _finish(); return
	unlocked_before = original_attempts.unlocked_equipment.duplicate()
	if not _configure_test_registry() or not _assemble_prefinal() or not await _new_shell(): await _finish(); return
	game.menu.difficulty_preference_requested.emit("challenge")
	if not _expect(game.get_difficulty_preference() == "challenge", "public future preference is Challenge before original final epoch begins"):
		await _finish(); return
	operation = "literal original pre-final Title Resume Side"
	game.menu.resume_requested.emit()
	if not await _await_operation(func() -> bool: return _live(Bloom.LEVEL_ID) and paused and game.menu.page_name() == "resume", "actual fresh Title installs original API1 pre-final", 12.0): await _finish(); return
	if not _expect(_same(game.capture_campaign_snapshot(), prefinal) and _recipient_callbacks().is_empty() and _bindings() and _same(game.attempts.state().story, protected_story), "quiet actual recipient restores exact original whole unit before any TEST placement or new epoch"):
		await _finish(); return
	if not _place_final_probe(): await _finish(); return
	game.active_level.connect("native_admission_published", _admission_observed)
	probe_node = AdmissionProbe.new(); probe_node.name = "ReadOnlyFinalAdmissionProbe"
	probe_node.process_mode = Node.PROCESS_MODE_PAUSABLE; probe_node.process_physics_priority = 199
	probe_node.inspect = Callable(self, "_probe_final"); root.add_child(probe_node)
	if not _expect(game.active_level.process_physics_priority == 200 and PROBE_IDS.all(func(id: String) -> bool: return _source(id).process_physics_priority < 199), "read-only observation runs after real actor physics and before actual parent admission"):
		await _finish(); return
	if not await _resume("actual legacy final under future Challenge") or not await _wait_live(func() -> bool: return not first_admission.is_empty(), "first actual native final admission", 16.0): await _finish(); return
	if not _expect(first_admission.source_id == "bloom-final-west" and first_admission.profile.id == "challenge" and first_admission.both_eligible_same_tick, "old-source Challenge genuinely admits west first while west and guard both pass same-tick native/current-view eligibility"):
		await _finish(); return
	if not await _pause("genuine legacy Challenge final Save"): await _finish(); return
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _expect(not saved.is_empty() and saved.level.local.api_revision == "act1-spore-bloom-1" and saved.level.local.schema_version == 1 and not saved.level.local.has("final_arrangement") and saved.level.local.beat_index == 2 and saved.level.local.room_stage == "active" and saved.level.local.scheduler.profile.id == "challenge" and _same(game.attempts.state().side_attempt.checkpoint, prefinal) and _same(game.attempts.state().story, protected_story) and _durable(), "public Save produces genuine unchanged-format API1 final Challenge unit with original earlier checkpoint and protected Story"):
		await _finish(); return
	receipts.append({"label": "actual legacy Challenge final first admission", "exact_snapshot": Exact.stringify(saved), "snapshot_sha256": Exact.stringify(saved).sha256_text(), "exact_player": Exact.stringify(saved.player), "exact_level": Exact.stringify(saved.level), "exact_earlier_checkpoint": Exact.stringify(prefinal), "exact_attempts": Exact.stringify(game.attempts.state()), "saved_envelope_json": FileAccess.get_file_as_string(test_root + "campaign.json"), "first_admission": first_admission.duplicate(true), "native_identities": _ids()})
	await _finish()


func _assemble_prefinal() -> bool:
	var model := Attempts.new(Registry.new(raw))
	if not _expect(model.restore_session(original_attempts) and _same(model.state(), original_attempts) , "public Attempts restores complete original successful Retry Session without editing its bytes"): return false
	var payload: Dictionary = model.state()
	var store := Store.new(test_root + "campaign.json"); store.payload_validator = model.saved_payload_error
	setups.append({"kind": "TEST original whole successful Retry Session; no earned prefix or group replay", "prefinal_sha256": PREFINAL_SHA, "groups_report_sha256": GROUPS_SHA, "retry_report_sha256": RETRY_SHA, "original_attempts_sha256": RETRY_ATTEMPTS_SHA})
	return _expect(model.state_error(payload).is_empty() and _same(payload.side_attempt.snapshot, prefinal) and _same(payload.side_attempt.checkpoint, prefinal) and _same(payload.story, protected_story) and payload.completed_optional.is_empty() and payload.reward_ids.is_empty() and store.write_payload(payload), "public isolated Store persists exact original pre-final Session without completion or reward")


func _place_final_probe() -> bool:
	var before: Vector3 = game.player.global_position
	var proposed := Vector3(-2.2, before.y, -3.0)
	var measured: Dictionary = TerminalSweep.sweep(game.player, Transform3D(game.player.global_basis, proposed), Vector3.ZERO, game.active_level.call("scheduler_bindings").floors.values())
	if not _expect(paused and game.player.velocity == Vector3.ZERO and not measured.has("error") and not measured.get("collided", true), "only same-floor TEST Hero pose has real capsule support before final activation"): return false
	game.player.global_position = proposed
	setups.append({"kind": "TEST Hero position only; no source, phase, velocity, clock, camera or save-packet edit", "before": _encode(before), "after": _encode(proposed), "earned_traversal": false})
	return true


func _probe_final(delta: float) -> void:
	if finishing or paused or not first_admission.is_empty() or not _live(Bloom.LEVEL_ID): return
	var host: CinderLevel = game.active_level
	var state: Dictionary = host.call("bloom_state")
	if state.beat_index != 2 or state.room_stage != "active" or not game.player.get_threat_response_state().stable: return
	var row: Dictionary = {"clock_s": _scheduler().get_clock(), "physics_frame": Engine.get_physics_frames(), "hero_position": _encode(game.player.global_position), "sources": {}, "both_eligible": true}
	for id: String in PROBE_IDS:
		var actor: Act1MushroomSelenite = _source(id)
		var actual: Dictionary = actor.pure_presentation_state()
		var control: Dictionary = _scheduler().source_control_state(actor)
		var distance: float = _distance(actor.global_position, game.player.global_position)
		var candidate: Dictionary = actor.preview_start(game.player.global_position, host.call("response_context", actual.role_id))
		var basic: bool = not actor.dead and not actor.dormant and actual.reservation_id.is_empty() and float(actual.hurt_left_s) == 0.0 and distance >= .1 and distance <= 4.5 and candidate.get("accepted", false)
		var gap: String = "native preview unavailable"
		var window: bool = false
		var optics: String = "native preview unavailable"
		if basic:
			gap = String(host.call("_source_path_gap_error", id, actor.global_position, candidate.candidate.opening_position, delta))
			window = host.call("_proof_window", candidate.proof, candidate.candidate) == true
			var points: Array = host.camera_framing_points()
			points.append_array(host.call("_actor_points", id, candidate.candidate.opening_position))
			points.append_array(host.call("_lane_points", candidate.candidate.geometry))
			points.append_array(host.call("_response_points", candidate.proof.landing, candidate.proof.attack_position))
			# Conservative union of the real current union and this genuine proposed
			# source/footprint/response. Pure read only; does not move the camera.
			optics = game.camera_framing_error(host.call("_bounded_union", points))
		var eligible: bool = basic and gap.is_empty() and window and optics.is_empty()
		row.sources[id] = {"eligible": eligible, "distance": distance, "presentation": _encode(actual), "control": _encode(control), "preview": _encode(candidate), "gap_error": gap, "ordinary_window": window, "current_view_error": optics}
		row.both_eligible = row.both_eligible and eligible
	latest_probe = row
	if eligibility_rows.size() < 180: eligibility_rows.append(row.duplicate(true))


func _admission_observed(id: String, answer: Dictionary) -> void:
	if not first_admission.is_empty() or game.active_level.call("bloom_state").beat_index != 2: return
	var same_tick: bool = not latest_probe.is_empty() and latest_probe.clock_s == _scheduler().get_clock() and latest_probe.physics_frame == Engine.get_physics_frames()
	first_admission = {"source_id": id, "answer": _encode(answer), "profile": _scheduler().encounter_profile(), "clock_s": _scheduler().get_clock(), "both_eligible_same_tick": same_tick and latest_probe.get("both_eligible", false), "pre_admission": latest_probe.duplicate(true), "control": _encode(_scheduler().source_control_state(_source(id)))}


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > TERMINAL_WATCHDOG_MS:
		_expect(false, "actual bounded O2 producer reached120 wall seconds"); _finish.call_deferred()


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true; operation = "normal difficulty producer cleanup"
	if is_instance_valid(probe_node): probe_node.free(); probe_node = null
	var refs: Array[WeakRef] = []
	if is_instance_valid(game):
		if is_instance_valid(game.active_level): game.active_level.exit_level()
		refs.append_array(_refs(game)); game.free(); game = null
	paused = false; await create_timer(.5, true).timeout; await process_frame
	_expect((refs.is_empty() or _freed(refs)) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("environment_attack_targets").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal public exit/Shell cleanup frees every native descendant and group")
	if not registry_bytes.is_empty(): _expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH) == registry_bytes, "canonical Registry bytes remain unchanged")
	for path: String in producer_sources: _expect(FileAccess.get_sha256("res://" + path) == producer_sources[path], "producer source remains frozen: " + path)
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	var output := FileAccess.open(report_path, FileAccess.WRITE)
	if output == null: _expect(false, "unique actual producer report is writable")
	else:
		output.store_string(JSON.stringify({"checks": checks, "failures": failures, "first_failure": first_failure, "elapsed_ms": Time.get_ticks_msec() - started_ms, "case": difficulty_case, "process_id": OS.get_process_id(), "source_report_sha256": original_report_sha256, "source_reports": source_reports, "source_sha256": producer_sources, "setups": setups, "receipts": receipts, "first_admission": first_admission, "eligibility_rows": eligibility_rows, "observations": observations, "synchronous_observation_overruns": observation_overruns, "pause_registration_barriers": pause_registration_barriers, "isolated_store_path": test_root + "campaign.json", "scope": "Pre-amendment producer only: literal genuine API1 pre-final unit and original protected Story through public Attempts/isolated Store/fresh Title active-side Continue; future public Challenge preference; measured disclosed Hero-only same-floor setup; actual native final activation and first admission with same-tick west/guard preview/proof/gap/current optics observations; public Pause Save of exact genuine API1 Challenge final; normal cleanup. No native packet, source, field, clock, order, camera or metadata fabrication. No new API2, finite-use, exhausted ordinary, fresh Continue of produced final, Retry, contact/reward/replay, earned route, balance, portrait or performance credit."}, "\t")); output.close()
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-O2 DIFFICULTY: %d checks, %d failures; report=%s" % [checks, failures, report_path])
	quit(1 if failures > 0 else 0)
