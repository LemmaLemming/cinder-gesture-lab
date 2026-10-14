extends "res://tests/acts/act1/a1_o1_campaign.gd"
## Root canonical registration. Exact owner handoff; execution is recorded separately.
## Overrides the owner's long _run; inherited mechanics/route are not executed.
## Actual canonical registry; TEST completed-main prefix comes from _seed_story.
## Reuses owner's pinned genuine completion result through --completed-session
## and --completed-sha256, never assigns collections/death/completion/rewards.
## Public menu signals are API evidence, not GUI or earned-route evidence.

const ACCEPTED_CONTENT: String = "a41ea5cd3d01aeb41cc320a721db95ecded95e06"
var _expected_disk: Dictionary = {}
var _registration_done: bool = false
var _registration_source_pins: Dictionary = {}
var _completed_receipt_pin: Dictionary = {}

func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	test_root = "user://test-a1-o1-canonical-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	report_path = "res://.cinder/a1-o1-registration-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	for path: String in [get_script().resource_path, "res://tests/acts/act1/a1_o1_campaign.gd", "res://scripts/campaign/shell.gd", "res://scripts/combat/repulsion_route.gd", Registry.DATA_PATH]:
		_registration_source_pins[path] = FileAccess.get_sha256(path)
	old_fps = Engine.max_fps
	old_audio = AudioServer.generate_bus_layout()
	process_frame.connect(_watchdog)
	node_added.connect(_observe_added)
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(540, 1170)
	registry_bytes = FileAccess.get_file_as_bytes(Registry.DATA_PATH)
	var canonical: CinderCampaignRegistry = Registry.new()
	var row: Dictionary = canonical.entry(Layout.LEVEL_ID)
	if not _expect(ACCEPTED_CONTENT.length() == 40 and canonical.last_error.is_empty() and canonical.ids().size() == 24 and row.get("readiness") == "accepted" and row.get("accepted_commit") == ACCEPTED_CONTENT and row.get("scene_path") == O1_PATH and row.get("api_revision") == Registry.API_REVISION and canonical.scene_error(Layout.LEVEL_ID).is_empty(), "actual canonical submitted O1 content/scene/API validates"):
		await _finish(); return
	if not _expect(row.get("parent_level_id") == "A1-L2" and canonical.entry("A1-L2").get("readiness") == "accepted" and not canonical.is_unlocked(Layout.LEVEL_ID, []) and not canonical.is_unlocked(Layout.LEVEL_ID, ["A1-L1"]) and canonical.is_unlocked(Layout.LEVEL_ID, PREFIX), "accepted A1-L2 alone unlocks canonical O1"):
		await _finish(); return
	if not _expect(row.get("reward_id") == REWARD_ID and row.get("reward_policy") == "once_only_completion_stamp_no_stat_growth" and canonical.next_main("A1-L2") == "A1-L3", "optional once-only stamp stays outside unchanged main route"):
		await _finish(); return
	# Existing helper captures real pristine L2; only prefix is TEST history.
	if not await _seed_story(canonical): await _finish(); return
	_expected_disk = Store.new(test_root + "campaign.json").read_payload()
	if not await _new_shell(): await _finish(); return
	game.menu.continue_story_requested.emit()
	if not await _await_operation(func() -> bool: return _live("A1-L2") and paused and game.menu.page_name() == "resume", "canonical public protected Story installation", 10.0):
		await _finish(); return
	protected_story = game.attempts.state().story.duplicate(true)
	unlocked_before = game.attempts.state().unlocked_equipment.duplicate()
	var protected_unit: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_closed(protected_unit) and _same(protected_unit, protected_story.snapshot) and _durable(), "initial protected Story capture closes and matches its durable snapshot before optional entry"):
		await _finish(); return
	var old_story_refs: Array[WeakRef] = _refs(game.world.get_parent().get_parent())
	game.menu.optional_requested.emit(Layout.LEVEL_ID)
	if not await _await_operation(func() -> bool: return _live(Layout.LEVEL_ID) and paused and game.menu.page_name() == "resume" and game.attempts.active_kind() == "optional", "canonical public optional installation", 10.0):
		await _finish(); return
	var entrance: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_closed(entrance) and game.active_level.get_script() == O1Script and _bindings() and _freed(old_story_refs) and _same(game.attempts.state().story, protected_story) and _same(game.attempts.state().side_attempt.checkpoint, entrance) and entrance.level.local.stage == "circuit" and entrance.level.local.collected_ids.is_empty() and not entrance.level.progress.completed and _durable(), "canonical pristine side entrance retires Story donor and protects its entire packet"):
		await _finish(); return
	if not _expect(not game.active_level.request_completion(Layout.COMPLETION_ID) and not game.active_level.request_contact_exit(Layout.HATCH_EXIT_ID, game.player) and _same(game.capture_campaign_snapshot(), entrance), "unearned completion/hatch refuses without state mutation"):
		await _finish(); return
	# This is entrance Retry only. Owner's genuine pre-final Retry is reused.
	if not await _retry_checkpoint(entrance): await _finish(); return
	var optional_refs: Array[WeakRef] = _refs(game.world.get_parent().get_parent())
	game.menu.leave_side_requested.emit()
	if not await _await_operation(func() -> bool: return _live("A1-L2") and paused and game.menu.page_name() == "journey" and game.attempts.active_kind() == "story", "canonical early Leave Side restores protected Story", 10.0):
		await _finish(); return
	if not _expect(_freed(optional_refs) and _same(game.capture_campaign_snapshot(), protected_unit) and _same(game.attempts.state().story, protected_story) and game.attempts.state().completed_main == PREFIX and game.attempts.state().completed_optional.is_empty() and game.attempts.state().reward_ids.is_empty() and game.attempts.state().unlocked_equipment == unlocked_before and _durable(), "canonical abandon frees optional world and grants no completion/reward/growth"):
		await _finish(); return
	if not await _completed_replay_boundary(canonical): await _finish(); return
	_registration_done = true
	await _finish()

func _new_shell() -> bool:
	operation = "actual canonical isolated disk Title"
	game = Shell.new() as CinderCampaignShell
	if not _expect(game.configure_runtime({}, test_root + "campaign.json", test_root + "settings.json", test_root + "preferences.json"), "canonical Shell has no substitute readiness registry"): return false
	root.add_child(game)
	return await _await_operation(func() -> bool: return paused and game.player == null and game.active_level == null and game.menu.page_name() == "title" and _same(game.attempts.state(), _expected_disk), "whole expected canonical startup session settles at Title", 10.0)

func _completed_replay_boundary(canonical: CinderCampaignRegistry) -> bool:
	var path: String = ""
	var digest: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--completed-session="): path = argument.trim_prefix("--completed-session=")
		if argument.begins_with("--completed-sha256="): digest = argument.trim_prefix("--completed-sha256=")
	if not _expect(not path.is_empty() and digest.length() == 64 and FileAccess.get_sha256(path) == digest, "actual owner's completed-return session is explicitly hash pinned"): return false
	_completed_receipt_pin = {"path": path, "sha256": digest, "producer_join": "Original owner report/receipt extraction is separately joined in Root's frozen integration evidence; this runtime checksum establishes supplied-file integrity only."}
	var decoded: Dictionary = Exact.parse(FileAccess.get_file_as_string(path))
	if not _expect(decoded.get("accepted", false) and decoded.get("value") is Dictionary, "complete finite owner session parses exactly"): return false
	var submitted: Dictionary = decoded.value
	var model: CinderCampaignAttempts = Attempts.new(canonical)
	if not _expect(model.state_error(submitted).is_empty() and submitted.side_attempt == null and submitted.completed_main == PREFIX and submitted.completed_optional == [Layout.LEVEL_ID] and submitted.reward_ids == [REWARD_ID] and submitted.story.level_id == "A1-L2" and submitted.unlocked_equipment == unlocked_before, "genuine owner completed-return session retains exact one stamp and protected main/equipment boundary"): return false
	# Reuse completed packet, never mint a stamp or synthesize local completion.
	var refs: Array[WeakRef] = _refs(game)
	if is_instance_valid(game.active_level): game.active_level.exit_level()
	game.free(); game = null
	await process_frame
	if not _expect(_freed(refs), "first canonical Shell frees before completed-session recipient"): return false
	var writer: CinderSaveStore = Store.new(test_root + "campaign.json")
	writer.payload_validator = model.saved_payload_error
	if not _expect(writer.write_payload(submitted), "exact owner completed session enters isolated format2 Store"): return false
	_expected_disk = submitted.duplicate(true)
	protected_story = submitted.story.duplicate(true)
	if not await _new_shell(): return false
	game.menu.continue_story_requested.emit()
	if not await _await_operation(func() -> bool: return _live("A1-L2") and paused and game.menu.page_name() == "resume" and _same(game.capture_campaign_snapshot(), protected_story.snapshot), "canonical Continue restores actual owner's protected Story", 10.0): return false
	game.menu.replay_requested.emit(Layout.LEVEL_ID, Equipment.STARTER)
	if not await _await_operation(func() -> bool: return _live(Layout.LEVEL_ID) and paused and game.attempts.active_kind() == "replay" and game.menu.page_name() == "resume", "canonical completed-optional Replay enters fresh O1", 10.0): return false
	var replay: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_closed(replay) and _bindings() and replay.level.local.stage == "circuit" and replay.level.local.collected_ids.is_empty() and not replay.level.progress.completed and game.attempts.state().completed_optional == [Layout.LEVEL_ID] and game.attempts.state().reward_ids == [REWARD_ID] and _same(game.attempts.state().story, protected_story) and _durable(), "fresh canonical Replay retains the one genuine existing stamp without fabricated contacts"): return false
	refs = _refs(game.world.get_parent().get_parent())
	game.menu.leave_side_requested.emit()
	if not await _await_operation(func() -> bool: return _live("A1-L2") and paused and game.attempts.active_kind() == "story" and game.menu.page_name() == "journey", "canonical Replay Leave returns protected Story", 10.0): return false
	return _expect(_freed(refs) and _same(game.capture_campaign_snapshot(), protected_story.snapshot) and _same(game.attempts.state().story, protected_story) and game.attempts.state().completed_main == submitted.completed_main and game.attempts.state().completed_optional == submitted.completed_optional and game.attempts.state().reward_ids == submitted.reward_ids and game.attempts.state().unlocked_equipment == submitted.unlocked_equipment and _durable(), "replay/return keeps exact once-only stamp and main/equipment/Story boundaries")

func _finish() -> void:
	if finishing: return
	finishing = true; paused = true; operation = "normal canonical registration cleanup"
	var refs: Array[WeakRef] = []
	if is_instance_valid(preview):
		var donor: CinderLevel = preview.get("active_level") as CinderLevel
		if donor != null: donor.exit_level()
		refs.append_array(_refs(preview)); preview.free(); preview = null
	if is_instance_valid(game):
		if is_instance_valid(game.active_level): game.active_level.exit_level()
		refs.append_array(_refs(game)); game.free(); game = null
	await create_timer(0.5, true).timeout
	await process_frame
	_expect(refs.is_empty() or _freed(refs), "normal canonical registration native descendants free")
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal canonical registration releases enemy/cue groups")
	_expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH) == registry_bytes, "canonical registry remains byte exact")
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		var path: String = test_root + name
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	paused = false
	var report := FileAccess.open(report_path, FileAccess.WRITE)
	if report == null: _expect(false, "unique canonical registration report is writable")
	else:
		report.store_string(JSON.stringify({"checks": checks, "failures": failures, "first_failure": first_failure, "registration_complete": _registration_done, "elapsed_ms": Time.get_ticks_msec() - started_ms, "accepted_content": ACCEPTED_CONTENT, "source_pins_observed_at_start": _registration_source_pins, "completed_receipt_pin": _completed_receipt_pin, "observations": observations, "receipts": receipts, "scope": "Actual canonical row/parent/unlock/entry, closed durable protected Story, entrance Retry, early Leave, supplied genuine completed session and pristine Replay/Leave with one-stamp retention, normal cleanup. TEST main prefix; public menu API signals. Original producer receipt and frozen inputs require their separate Root evidence join. No inherited mechanics run, new contact/completion execution, earned route, GUI, visual, full-playthrough, performance, mobile or broad balance credit."}, "\t")); report.close()
	print("A1-O1 canonical registration: %d checks/%d failures, complete=%s; report=%s; actual row/parent/entry/entrance Retry/early Leave/reused hash-pinned completed session/Replay one-stamp retention/protected Story/cleanup. TEST prefix; no inherited mechanics, new contact/completion execution, earned route, GUI, visual or broad balance credit." % [checks, failures, str(_registration_done), report_path])
	quit(0 if failures == 0 and _registration_done else 1)
