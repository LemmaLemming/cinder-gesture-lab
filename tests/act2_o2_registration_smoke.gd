extends "res://tests/acts/act2/a2_o2_loading_side_smoke.gd"
## Focused actual canonical O2 registration/latest checkpoint Retry.
## Overrides _run; the inherited complete 116-check suite is not executed.
## Reuses its real Shell/Attempts/Store, native recovery-gated TEST injuries,
## original smoke-tail/contact and active Lane transport helpers.
## No HP/clock/cue/phase/proof/history/checkpoint setters or earned-route claim.


func _initialize() -> void:
	_test_root = "user://test-a2-o2-before-final-retry-%d/" % OS.get_process_id()
	_old_audio = AudioServer.generate_bus_layout()
	_old_fps = Engine.max_fps
	_run.call_deferred()


func _run() -> void:
	create_timer(150.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "bounded focused before-final Retry watchdog")
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
	# Actual canonical scene/readiness is consumed; only earlier progress is TEST.
	var registry: CinderCampaignRegistry = Registry.new()
	var accepted: Dictionary = registry.entry("A2-O2")
	if not _expect(registry.last_error.is_empty() and registry.ids().size() == 24 and accepted.get("readiness") == "accepted" and accepted.get("accepted_commit") == "dadbf52ab13592a25fac1166d976e1e7f25c358c" and accepted.get("scene_path") == O2_PATH and accepted.get("api_revision") == Registry.API_REVISION and registry.scene_error("A2-O2").is_empty(), "actual canonical O2 scene/accepted content identity validates"):
		_finish(); return
	if not _expect(accepted.get("parent_level_id") == "A2-L3" and not registry.is_unlocked("A2-O2", []) and registry.is_unlocked("A2-O2", ["A2-L3"]) and registry.entry("A2-L3").get("readiness") == "accepted", "only the accepted canonical parent unlocks O2"):
		_finish(); return
	if not _expect(accepted.get("reward_id") == "A2-O2-completion-stamp" and accepted.get("reward_policy") == "once_only_completion_stamp_no_stat_growth" and registry.next_main("A2-L3") == "A2-L4" and registry.entry("A2-O3").get("readiness") == "unimplemented", "optional cosmetic stamp is separate from unchanged main progression and unfinished O3"):
		_finish(); return
	if not await _seed_story(registry) or not await _new_shell():
		_finish(); return
	_shell.menu.continue_story_requested.emit()
	await _settle()
	var protected: Dictionary = _shell.capture_campaign_snapshot()
	if not _expect(paused and not protected.is_empty() and protected.level_id == "A2-L4", "real protected earlier Story snapshot is captured before optional entry"):
		_finish(); return
	_shell.menu.optional_requested.emit("A2-O2")
	await _settle()
	if not _expect(_live() and paused and _shell.attempts.active_kind() == "optional", "real first optional attempt enters paused"):
		_finish(); return
	var entrance: Dictionary = _shell.attempts.state().side_attempt.checkpoint
	# Two legitimate representative defeats, not primary/route victory credit.
	for id: String in ["east_tender", "west_tender"]:
		if not await _test_gated_defeat(id) or not await _same_original_tail_finishes(id):
			_finish(); return
	if not await _test_contact(Vector3(0, 0, -6.7)):
		_finish(); return
	_shell.request_pause()
	await _settle()
	var checkpoint: Dictionary = _shell.attempts.state().side_attempt.checkpoint
	var input_at_checkpoint: Dictionary = _shell.get_input_observation_state()
	if not _expect(paused and checkpoint.level.progress.checkpoint_id == CP_ID and checkpoint.level.local.defeated_ids == ["east_tender", "west_tender"] and int(checkpoint.level.local.tool.cycle) == 0 and not _same(checkpoint, entrance), "actual stable contact durably earns the latest before-final checkpoint, not entrance or seeded history"):
		_finish(); return
	_expect(_same(_shell.attempts.story_snapshot(), protected), "earning optional checkpoint preserves the complete earlier Story")
	# This public native helper earns active Lane and a real independent disk
	# recipient. Its restored Attempts checkpoint must still be the earlier unit.
	if not await _final_active_transport():
		_finish(); return
	_expect(_same(_shell.attempts.state().side_attempt.checkpoint, checkpoint), "running Handler transport retains the original before-final checkpoint")
	_shell.menu.resume_requested.emit()
	for _tick: int in range(4): await _probe.tick_finished
	var before_tap: Dictionary = _shell.get_input_observation_state()
	_shell.handle_tap(root.get_visible_rect().size * 0.65)
	_expect(_shell.get_input_observation_state().sequence == before_tap.sequence + 1, "one real public tap changes live input history without assigning a saved observation")
	_shell.player.take_damage(_shell.player.max_hp * 4.0, Vector3.ZERO)
	await _settle()
	if not _expect(paused and _shell.player.dead and _shell.campaign_error.is_empty(), "public TEST lethal injury creates a later real dead unit for Retry, without enemy attribution"):
		_finish(); return
	var later: Dictionary = _shell.capture_campaign_snapshot()
	_expect(not later.is_empty() and not _same(later, checkpoint) and float(later.level.local.scheduler.clock_s) > float(checkpoint.level.local.scheduler.clock_s), "later native unit has genuinely advanced clock/state distinct from retained checkpoint")
	var retired: Array = _refs(_shell.active_level)
	retired.append_array(_refs(_shell.player))
	retired.append_array(_refs(_shell.fx))
	_events.clear(); _watch = true
	_shell.menu.retry_requested.emit()
	await _settle()
	_watch = false
	var restored: Dictionary = _shell.capture_campaign_snapshot()
	_expect(_live() and paused and not _shell.player.dead and _shell.menu.page_name() == "resume" and _shell.attempts.active_kind() == "optional", "supported public Retry installs a living paused optional unit")
	_expect(_same(restored, checkpoint) and _same(_shell.attempts.state().side_attempt.checkpoint, checkpoint), "Retry restores the exact earlier full Player/actors/Banks/Lane/Scheduler/source/geometry/resource/clock/input packet")
	_expect(_shell.get_input_observation_state() == input_at_checkpoint and _events.is_empty(), "checkpoint Retry restores original input and performs no action/equipment/death/cue/progression notifications")
	_expect(_same(_shell.attempts.story_snapshot(), protected) and _shell.attempts.state().completed_main == PREFIX and _shell.attempts.state().completed_optional.is_empty() and _shell.attempts.state().reward_ids.is_empty(), "Retry preserves protected Story/main prefix and grants no completion/reward/growth")
	_expect(_refs_freed(retired), "Retry frees the later native Player/effects/actors/consumers/Scheduler/cues before replacement")
	var optional_refs: Array = _refs(_shell.active_level)
	optional_refs.append_array(_refs(_shell.player))
	_shell.menu.leave_side_requested.emit()
	await _settle()
	_expect(paused and _shell.menu.page_name() == "journey" and _shell.attempts.active_kind() == "story" and _same(_shell.capture_campaign_snapshot(), protected), "real Leave Side returns the exact protected Story after latest-checkpoint Retry")
	_expect(_refs_freed(optional_refs) and _shell.attempts.state().completed_optional.is_empty() and _shell.attempts.state().reward_ids.is_empty(), "abandon retires the optional native unit without a stamp or permanent reward")
	_finish()


func _same_original_tail_finishes(id: String) -> bool:
	var bank_id: String = BANK_FOR[id]
	var original: Dictionary = _bank(bank_id).call("state")
	if not _expect(original.status == "running" and original.phase == "recovery" and original.last_cancel_reason.is_empty(), "actual HP0 Tender leaves its original recovery tail " + id): return false
	for _tick: int in range(MAX_TICKS):
		await _probe.tick_finished
		if not _live() or _shell.player.dead: break
		if _bank(bank_id).call("state").status == "complete": break
	var ended: Dictionary = _bank(bank_id).call("state")
	return _expect(ended.status == "complete" and ended.cycle == original.cycle and _same(_encode(ended.exchange), _encode(original.exchange)) and _same(ended.receipts, original.receipts) and ended.last_cancel_reason.is_empty(), "same original HP0 tail finishes before actual checkpoint without cancel/restart/refill " + id)


func _finish() -> void:
	if _finished: return
	_finished = true; _watch = false
	if is_instance_valid(_preview):
		var level: CinderLevel = _preview.get("active_level") as CinderLevel
		if is_instance_valid(level): level.exit_level()
		_preview.free()
	if is_instance_valid(_shell):
		var refs: Array = _refs(_shell)
		if is_instance_valid(_shell.active_level): _shell.active_level.exit_level()
		_shell.free()
		_expect(_refs_freed(refs), "final focused Shell/native descendants free through normal disposal")
	_shell = null; _preview = null
	if is_instance_valid(_probe): _probe.free()
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_bytes, "actual canonical readiness stays byte-exact")
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		var path: String = ProjectSettings.globalize_path(_test_root + name)
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	AudioServer.set_bus_layout(_old_audio)
	Engine.max_fps = _old_fps
	print("O2 focused before-final Retry TEST injuries: ", Exact.stringify(_injuries))
	print("A2-O2 before-final Retry smoke: %d checks, %d failures; actual contact checkpoint, later native Lane/input/death, exact public Retry/protected Story/cleanup only; no route/ordinary defeat/art/full-suite claim" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _new_shell() -> bool:
	_events.clear(); _watch = true
	_shell = Shell.new() as CinderCampaignShell
	if not _expect(_shell.configure_runtime({}, _test_root + "campaign.json", _test_root + "settings.json", _test_root + "preferences.json"), "actual Shell consumes the untouched canonical registry before tree entry"):
		return false
	root.add_child(_shell)
	await _settle()
	_watch = false
	return _expect(paused and _shell.player == null and _shell.menu.page_name() == "title" and _shell.campaign_error.is_empty() and _events.is_empty() and _shell.registry.entry("A2-O2").get("accepted_commit") == "dadbf52ab13592a25fac1166d976e1e7f25c358c", "independent disk Shell retains actual accepted O2 pin and quietly validates the complete session at Title: " + _shell.campaign_error + str(_events))
