extends "res://tests/acts/act2/a2_o3_loading_side_smoke.gd"
## Focused actual canonical O3 registration and latest-checkpoint Retry.
## The inherited 136-check suite is not executed. Existing mechanics,
## completion/replay/stamp/contact and seven inspected portraits are reused.
## TEST ONLY: prior main prefix, supported Hero feet and two public gated
## Actor injuries. No encounter/phase/proof/resource/clock/history setters.


func _initialize() -> void:
	_test_root = "user://test-a2-o3-canonical-registration-%d/" % OS.get_process_id()
	_old_audio = AudioServer.generate_bus_layout()
	_old_fps = Engine.max_fps
	_run.call_deferred()


func _run() -> void:
	create_timer(150.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "bounded actual canonical O3 registration watchdog")
			_finish()
	)
	root.size = Vector2i(540, 1170)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_probe = NativeTickProbe.new()
	root.add_child(_probe)
	node_added.connect(_observe_added)
	_registry_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	_raw = JSON.parse_string(_registry_bytes)
	var registry: CinderCampaignRegistry = Registry.new()
	var accepted: Dictionary = registry.entry("A2-O3")
	if not _expect(registry.last_error.is_empty() and registry.ids().size() == 24 and accepted.get("readiness") == "accepted" and accepted.get("accepted_commit") == "f142bb5152f9733996a91dd1497d4463b7cb5aad" and accepted.get("scene_path") == O3_PATH and accepted.get("api_revision") == Registry.API_REVISION and registry.scene_error("A2-O3").is_empty(), "actual canonical O3 submitted content/scene/API validates"):
		_finish(); return
	if not _expect(accepted.get("parent_level_id") == "A2-L4" and not registry.is_unlocked("A2-O3", []) and not registry.is_unlocked("A2-O3", ["A2-L3"]) and registry.is_unlocked("A2-O3", ["A2-L4"]) and registry.entry("A2-L4").get("readiness") == "accepted", "only actual accepted parent A2-L4 unlocks O3"):
		_finish(); return
	_expect(accepted.get("reward_id") == "A2-O3-completion-stamp" and accepted.get("reward_policy") == "once_only_completion_stamp_no_stat_growth" and registry.next_main("A2-L4") == "A2-L5", "optional once-only stamp remains separate from canonical main progression")
	if not await _seed_story(registry) or not await _new_shell():
		_finish(); return
	_shell.menu.continue_story_requested.emit()
	await _settle()
	var protected: Dictionary = _shell.capture_campaign_snapshot()
	if not _expect(paused and not protected.is_empty() and protected.level_id == "A2-L5", "actual protected Story is a pristine real A2-L5 unit with disclosed TEST prefix"):
		_finish(); return
	_shell.menu.optional_requested.emit("A2-O3")
	await _settle()
	if not _expect(_live() and paused and _shell.attempts.active_kind() == "optional", "actual canonical optional entry installs O3 paused"):
		_finish(); return
	var entrance: Dictionary = _shell.capture_campaign_snapshot()
	_expect(entrance.level.local.size() == LOCAL_KEYS.size() and entrance.level.local.has_all(LOCAL_KEYS) and entrance.level.local.stage_index == 0 and entrance.level.local.defeated_ids.is_empty(), "actual untouched entrance has exact seventeen-key finite local state")
	_expect(_same(_shell.attempts.story_snapshot(), protected) and _same(_shell.attempts.state().side_attempt.checkpoint, entrance), "optional entry protects the complete original Story and genuine entrance checkpoint")
	var input: Dictionary = _shell.get_input_observation_state()
	_shell.handle_tap(root.get_visible_rect().size * 0.5)
	_expect(_shell.get_input_observation_state() == input and _same(_shell.capture_campaign_snapshot(), entrance), "paused menu consumes a tap without action/aim/motion mutation")
	_expect(not _shell.active_level.request_contact_exit(EXIT_ID, _shell.player), "actual uncleared exit refuses")
	_shell.menu.resume_requested.emit()
	for _tick: int in range(8): await _probe.tick_finished
	_shell.request_pause()
	await _settle()
	var quiet: Dictionary = _shell.capture_campaign_snapshot()
	if not _expect(paused and not quiet.is_empty() and quiet.level.local.scheduler.clock_s > 0.0, "genuine native clocks advance before coherent public Pause"):
		_finish(); return
	if not await _disk_restore(quiet, "actual canonical initial optional unit"):
		_finish(); return
	# Arrange only the two earlier required actor defeats through their existing
	# public recovery gates; no final-pocket clear or full route is required.
	for id: String in ["first_scout", "second_handler"]:
		if not await _test_defeat(id) or not await _wait_quiet(id):
			_finish(); return
	# Reuse the original passing loading fixture's supported pre-CP approach.
	# This lets the native following camera approach the final pocket; no
	# camera setter, widened bounds, new source cycle or gate bypass is used.
	if not await _test_contact(Vector3(0, 0.04, -21.8)):
		_finish(); return
	_expect(_state().stage_index == 2 and not _state().checkpoint_committed and int(_native("final_scout").cycle) == 0 and int(_native("final_handler").cycle) == 0, "pre-checkpoint approach cannot admit either final source")
	if not await _test_contact(CP_AT):
		_finish(); return
	_shell.request_pause()
	await _settle()
	var checkpoint: Dictionary = _shell.attempts.state().side_attempt.checkpoint
	var original_input: Dictionary = _shell.get_input_observation_state()
	print("O3 actual canonical checkpoint framing: ", Exact.stringify({"camera_focus": checkpoint.shell.camera_focus, "hero": _encode(_shell.player.global_position), "camera": _encode(_shell.camera.global_position), "level_points": _encode(_shell.active_level.camera_framing_points())}))
	if not _expect(paused and checkpoint.level.progress.checkpoint_id == CP_ID and checkpoint.level.local.stage_index == 3 and checkpoint.level.local.defeated_ids == ["first_scout", "second_handler"] and int(checkpoint.level.local.exchange.records.final_scout.cycle) == 0 and int(checkpoint.level.local.tools.final_handler.cycle) == 0 and not _same(checkpoint, entrance), "actual latest before-third contact durably captures a whole earlier unit before final admissions"):
		_finish(); return
	_shell.menu.resume_requested.emit()
	for _tick: int in range(4): await _probe.tick_finished
	if not await _later_primary_before_retry(["canonical-registration"]):
		_finish(); return
	_shell.player.take_damage(_shell.player.max_hp * 4.0, Vector3.ZERO)
	await _settle()
	if not _expect(paused and _shell.player.dead and _shell.campaign_error.is_empty(), "public labelled TEST lethal injury freezes a genuinely later optional unit"):
		_finish(); return
	var later: Dictionary = _shell.capture_campaign_snapshot()
	_expect(not later.is_empty() and not _same(later, checkpoint), "later input/death state differs from the retained whole checkpoint")
	var retired: Array = _refs(_shell.active_level)
	retired.append_array(_refs(_shell.player))
	retired.append_array(_refs(_shell.fx))
	_events.clear(); _watch = true
	var disposal_start: int = _disposal_observations.size()
	_expected_retry_donor = weakref(_shell.active_level)
	var clicked: bool = await _click("RetryButton")
	_expected_retry_donor = null
	_watch = false
	if not clicked:
		_finish(); return
	var restored: Dictionary = _shell.capture_campaign_snapshot()
	_expect(_live() and paused and not _shell.player.dead and _shell.menu.page_name() == "resume" and _shell.attempts.active_kind() == "optional", "supported real GUI Retry installs a living paused canonical optional recipient")
	_expect(_same(restored, checkpoint) and _same(_shell.attempts.state().side_attempt.checkpoint, checkpoint), "Retry restores the exact earlier whole Player/actors/consumers/Scheduler/camera/input/resources unit")
	_expect(_shell.get_input_observation_state() == original_input and _events.is_empty(), "quiet recipient restores input and emits no gameplay/cue/action/progression event")
	var donor_flags: bool = true
	for record: Dictionary in _disposal_observations.slice(disposal_start):
		if not record.get("donor_match", false): continue
		donor_flags = donor_flags and record.boundary == "expected_retry_donor" and record.emitter_inside_tree == true and record.nearest_level_entered == false and record.nearest_level_lifecycle_busy == true and record.nearest_level_restore_candidate == false
	_expect(donor_flags, "every observed retired-donor notification retains the strict exact WeakRef/lifecycle classification")
	_expect(_refs_freed(retired), "normal Retry frees every later native actor/Player/effect descendant")
	_expect(_same(_shell.attempts.story_snapshot(), protected) and _shell.attempts.state().completed_main == PREFIX and _shell.attempts.state().completed_optional.is_empty() and _shell.attempts.state().reward_ids.is_empty(), "Retry protects Story/progression/resources without completion or a stat/reward grant")
	var optional_refs: Array = _refs(_shell.active_level)
	optional_refs.append_array(_refs(_shell.player))
	_shell.menu.leave_side_requested.emit()
	await _settle()
	_expect(paused and _shell.menu.page_name() == "journey" and _shell.attempts.active_kind() == "story" and _same(_shell.capture_campaign_snapshot(), protected), "Leave Side restores the exact protected Story to Journey")
	_expect(_refs_freed(optional_refs) and _shell.attempts.state().completed_optional.is_empty() and _shell.attempts.state().reward_ids.is_empty(), "normal abandon retires O3 without an optional stamp")
	_finish()


func _new_shell() -> bool:
	_events.clear(); _watch = true
	_shell = Shell.new() as CinderCampaignShell
	if not _expect(_shell.configure_runtime({}, _test_root + "campaign.json", _test_root + "settings.json", _test_root + "preferences.json"), "actual canonical Shell configuration without substitute registry"):
		return false
	root.add_child(_shell)
	await _settle()
	_watch = false
	return _expect(paused and _shell.player == null and _shell.menu.page_name() == "title" and _shell.campaign_error.is_empty() and _events.is_empty(), "genuine fresh NULL-Player Title quietly validates real canonical disk state")


func _finish() -> void:
	if _finished: return
	_finished = true; _watch = false; _expected_retry_donor = null
	if is_instance_valid(_preview):
		var level: CinderLevel = _preview.get("active_level") as CinderLevel
		if is_instance_valid(level): level.exit_level()
		_preview.free()
	if is_instance_valid(_shell):
		var refs: Array = _refs(_shell)
		_shell.free()
		_expect(_refs_freed(refs), "complete canonical Shell/native descendants free through normal disposal")
	_shell = null; _preview = null
	if is_instance_valid(_probe): _probe.free()
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_bytes, "actual canonical Registry stays byte-exact during the focused check")
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		var path: String = ProjectSettings.globalize_path(_test_root + name)
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	AudioServer.set_bus_layout(_old_audio)
	Engine.max_fps = _old_fps
	print("O3 canonical TEST public setup: ", Exact.stringify(_setups))
	print("O3 canonical actual later input: ", Exact.stringify(_later_actions))
	print("O3 canonical retired-donor observations: ", Exact.stringify(_encode(_disposal_observations)))
	print("A2-O3 canonical registration smoke: %d checks, %d failures; actual parent/optional/quiet disk/latest checkpoint GUI Retry/protected Story/abandon/cleanup. TEST prefix/feet/two public gated injuries/lethal injury; no earned route/final clear/art or inherited full-suite claim" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
