extends SceneTree
## Actual authored L1 through the shared shell. Registry acceptance below is
## isolated test metadata; L2/O1 are existing shared test fixtures, not authored
## future Act 1 content or a production acceptance claim.
const Shell: GDScript = preload("res://scripts/campaign/shell.gd")
const Registry: GDScript = preload("res://scripts/campaign/registry.gd")
const ExactJson: GDScript = preload("res://scripts/campaign/exact_json.gd")
const TEST_ROOT: String = "user://test-act1-launch-campaign/"
const LEVEL_PATH: String = "res://scenes/acts/act1/a1_l1.tscn"
var checks: int = 0
var failures: int = 0
var raw: Dictionary
var game: CinderCampaignShell

func _initialize() -> void:
	create_timer(60.0, true).timeout.connect(func() -> void:
		_expect(false, "authored campaign fixture must finish within its bounded watchdog")
		_finish()
	)
	_run.call_deferred()

func _run() -> void:
	_cleanup()
	raw = JSON.parse_string(FileAccess.get_file_as_string(Registry.DATA_PATH))
	for info: Dictionary in raw.levels:
		if info.id in ["A1-L1", "A1-L2", "A1-O1"]:
			info.scene_path = LEVEL_PATH if info.id == "A1-L1" else "res://tests/fixtures/campaign/live_" + String(info.id).to_lower().replace("-", "_") + ".tscn"
			info.readiness = "accepted"
			info.accepted_commit = "f".repeat(40)
			info.api_revision = Registry.API_REVISION
	game = _new_shell()
	await _settle()
	_expect(paused and game.active_level == null and game.menu.page_name() == "title", "test registry starts at actual paused desktop title")
	game.menu.begin_story_requested.emit()
	await _settle()
	_expect(game.campaign_error.is_empty() and game.active_level != null and game.active_level.scene_file_path == LEVEL_PATH, "actual authored L1 prepares in the shared campaign world: " + game.campaign_error)
	if game.active_level == null:
		_finish()
		return
	_expect(paused and game.player.hp == game.player.max_hp and game.player.shells == 2 and game.player.presentation_id == "act1_expedition", "fresh story has one shared G07 actor and explicit full initial resources")
	game.resume_campaign()
	await create_timer(0.2).timeout
	game.player.shells = 0
	game.player.hp = 22.0
	await _clear_opening()
	if int(game.active_level.get("beat_index")) != 3:
		_finish()
		return
	game.player.hp = 22.0
	game.request_pause()
	await _settle()
	var roof_boundary: Dictionary = game.attempts.state().story.checkpoint.duplicate(true)
	_expect(not roof_boundary.is_empty() and roof_boundary.level.local.beat_index == 3 and roof_boundary.level.local.arms.a1_l1_roof_arm.status == "idle" and roof_boundary.level.local.targets.roof.active == false, "workshop boundary saves a clear inactive roof without a fresh warning")
	game.resume_campaign()
	game.player.global_position = Vector3(1.2, 0.1, -6)
	await create_timer(0.2).timeout
	var arms: Dictionary = game.active_level.get("arms")
	var roof: CinderLaneMechanism = arms.a1_l1_roof_arm
	_expect(roof.state().status == "running" and roof.state().phase == "warning", "broad safe side approach starts a real shared roof warning")
	# Shared passive reload remains active. Stage the particular zero-shell
	# saved state immediately before its paused barrier, never disable reload.
	game.player.shells = 0
	game.request_pause()
	await _settle()
	var warning_save: Dictionary = game.capture_campaign_snapshot()
	_expect(not warning_save.is_empty() and warning_save.player.resources.hp == 22 and warning_save.player.resources.shells == 0 and warning_save.level.local.arms.a1_l1_roof_arm.status == "running", "pause saves exact injured actor and running arm as a paired aggregate: " + game.campaign_error)
	if warning_save.is_empty():
		_finish()
		return
	# Use the published exact transport for this whole actor/level/shell unit.
	# Ordinary decimal JSON is insufficient for authoritative scalar clocks.
	var warning_text: String = ExactJson.stringify(warning_save)
	var warning_decoded: Dictionary = ExactJson.parse(warning_text)
	_expect(not warning_text.is_empty() and warning_decoded.get("accepted", false) and warning_decoded.get("value") is Dictionary and ExactJson.stringify(warning_decoded.value) == warning_text, "whole running authored aggregate round-trips exact scalar bits and native types through the public transport")
	var durable_text: String = FileAccess.get_file_as_string(TEST_ROOT + "campaign.json")
	var durable_envelope: Variant = JSON.parse_string(durable_text)
	var durable_decoded: Dictionary = ExactJson.parse(String(durable_envelope.get("payload_json", ""))) if durable_envelope is Dictionary else {"accepted": false}
	_expect(durable_envelope is Dictionary and durable_envelope.get("format_version") == 2 and durable_decoded.get("accepted", false) and durable_decoded.get("value") is Dictionary and ExactJson.stringify(durable_decoded.value) == ExactJson.stringify(game.attempts.state()), "actual paused campaign generation is format2 with the complete exact authored attempt payload")
	var warning_clock: float = float(warning_save.level.local.scheduler.clock_s)
	await create_timer(0.1, true).timeout
	_expect(ExactJson.stringify(game.capture_campaign_snapshot()) == ExactJson.stringify(warning_save) and float(roof.state().remaining_s) > 0, "paused actor, arm, scheduler, target and screen-state remain exact")
	var malformed: Dictionary = warning_save.duplicate(true)
	malformed.player.motion.position[0] += 0.25
	_expect(not game.attempts.record_snapshot(malformed) and ExactJson.stringify(game.capture_campaign_snapshot()) == ExactJson.stringify(warning_save) and FileAccess.get_file_as_string(TEST_ROOT + "campaign.json") == durable_text, "cross-forged actor/sample mismatch rejects before live or durable mutation")
	# Normal close/reopen: validation now occurs in a fresh hidden World3D with
	# its hero at spawn. A saved running sample must use staged actor context.
	game.free()
	game = _new_shell()
	await _settle()
	_expect(game.menu.page_name() == "title" and paused and game.active_level == null, "interrupted running rehearsal loads paused at title")
	game.menu.continue_story_requested.emit()
	await _settle()
	_expect(game.campaign_error.is_empty() and game.active_level != null and ExactJson.stringify(game.capture_campaign_snapshot()) == ExactJson.stringify(warning_save), "Continue restores exact running actor/scheduler/arm in a fresh candidate: " + game.campaign_error)
	if game.active_level == null or not game.campaign_error.is_empty():
		_finish()
		return
	arms = game.active_level.get("arms")
	roof = arms.a1_l1_roof_arm
	_expect((game.active_level.get("scheduler") as CinderThreatScheduler).get_clock() == warning_clock and roof.get_cue().state().phase == "warning", "restored warning reuses its original clock and required footprint")
	game.request_retry()
	await _settle()
	_expect(game.campaign_error.is_empty() and ExactJson.stringify(game.capture_campaign_snapshot()) == ExactJson.stringify(roof_boundary), "Retry restores the complete clear roof checkpoint without healing, refill or retained warning: " + game.campaign_error)
	_expect(paused and game.menu.is_open() and (game.active_level.get("arms") as Dictionary).a1_l1_roof_arm.get_cue().state().phase == "clear", "retry waits for Resume with a visibly inactive roof")
	game.resume_campaign()
	game.player.hp = 22.0
	game.player.shells = 0
	game.player.global_position = Vector3(1.2, 0.1, -6)
	await create_timer(0.2).timeout
	_expect(game.player.request_dash(Vector3(0.6, 0, 0.8)), "ordinary diagonal roof escape is accepted")
	await create_timer(0.4).timeout
	var target: PracticeTarget = (game.active_level.get("targets") as Dictionary).roof
	game.player.shells = 0
	_expect(game.player.slash(target.global_position - game.player.global_position) == 1, "roof clears by actual ordinary primary after useful safe landing with no shells")
	await _settle()
	_expect(game.campaign_error.is_empty() and game.active_level.get("beat_index") == 4 and game.player.hp == 22 and game.player.shells == 0, "roof clear cancels danger and saves boarding boundary without changing attempt resources")
	var final_checkpoint: Dictionary = game.attempts.state().story.checkpoint.duplicate(true)
	_expect(final_checkpoint.level.local.arms.a1_l1_roof_arm.status == "cancelled" and final_checkpoint.level.local.arms.a1_l1_boarding_arm.status == "idle", "final rehearsal checkpoint retires the old arm and leaves the next warning inactive")
	game.player.global_position = Vector3(1.2, 0.1, -12)
	await create_timer(0.5).timeout
	var finale: CinderLaneMechanism = (game.active_level.get("arms") as Dictionary).a1_l1_boarding_arm
	_expect(finale.state().status == "running", "boarding side approach introduces only the familiar second arm")
	_expect(game.player.request_dash(Vector3(0.6, 0, 0.8)), "ordinary boarding escape is accepted")
	await create_timer(0.4).timeout
	target = (game.active_level.get("targets") as Dictionary).finale
	game.player.shells = 0
	_expect(game.player.slash(target.global_position - game.player.global_position) == 1, "boarding target clears by actual primary without a pickup or blast")
	await _settle()
	_expect(game.campaign_error.is_empty() and game.active_level.is_completed() and game.attempts.state().completed_main == ["A1-L1"], "final primary atomically commits completed local rehearsal and durable route access: " + game.campaign_error)
	_expect(game.attempts.active_snapshot().level.progress.checkpoint_ids.size() == 4 and game.attempts.active_snapshot().level.local.completed_exercises.size() == 5, "final completion does not enqueue an invalid fifth checkpoint")
	_expect(game.active_level.get("hatch_cue").state().trigger == "contact" and game.active_level.get("hatch_cue").state().state == "available" and finale.get_cue().state().phase == "clear", "completion opens a distinct contact hatch and visibly cancels the final arm")
	var old_level: CinderLevel = game.active_level
	game.player.global_position = Vector3(0, 0.1, -12.1)
	await create_timer(0.1).timeout
	_expect(game.player.request_dash(Vector3.FORWARD), "actual ordinary final dash enters broad capsule contact")
	await create_timer(0.4).timeout
	await _settle()
	_expect(game.campaign_error.is_empty() and game.active_level.level_id == "A1-L2" and game.active_level.scene_file_path.begins_with("res://tests/fixtures/"), "physical hatch contact transitions through canonical next-level flow to the existing test-only L2 fixture")
	_expect(paused and game.player.hp == 22 and game.player.shells == 0 and game.player.presentation_id == "act1_expedition" and not is_instance_valid(old_level), "transition preserves resources/G07, pauses for Resume and frees the retired authored level")
	var protected: Dictionary = game.capture_campaign_snapshot()
	game.menu.replay_requested.emit("A1-L1", game.player.equipment.snapshot())
	await _settle()
	_expect(game.attempts.active_kind() == "replay" and game.active_level.scene_file_path == LEVEL_PATH and game.player.hp == game.player.max_hp and game.player.shells == 2 and ExactJson.stringify(game.attempts.story_snapshot()) == ExactJson.stringify(protected), "actual L1 replay uses fresh isolated resources while protecting complete story")
	game.resume_campaign()
	await create_timer(0.2).timeout
	game.player.hp = 3
	game.player.shells = 0
	await _clear_opening()
	game.request_retry()
	await _settle()
	_expect(game.active_level.get("beat_index") == 3 and game.player.hp == 3 and game.player.shells == 0 and ExactJson.stringify(game.attempts.story_snapshot()) == ExactJson.stringify(protected), "replay checkpoint retry preserves its injured resources and does not alter protected story")
	game.menu.leave_side_requested.emit()
	await _settle()
	_expect(game.attempts.active_kind() == "story" and ExactJson.stringify(game.capture_campaign_snapshot()) == ExactJson.stringify(protected), "leaving authored L1 replay restores the entire protected story aggregate")
	_finish()

func _clear_opening() -> void:
	var marker: Vector3 = game.active_level.call("dash_marker_position")
	_expect(game.player.request_dash(marker - game.player.global_position), "real first dash begins through shared actor")
	await create_timer(0.4).timeout
	await _settle()
	_expect(game.active_level.get("beat_index") == 1, "completed marker landing advances the real first exercise")
	var targets: Dictionary = game.active_level.get("targets")
	game.player.shells = 0
	_expect(game.player.slash((targets.hall as PracticeTarget).global_position - game.player.global_position) == 1, "first hall target clears from actual marker landing")
	await _settle()
	_expect(game.active_level.get("beat_index") == 2 and game.campaign_error.is_empty(), "hall checkpoint commits and resumes the actual next exercise")
	# Explicit fixture staging isolates shared aggregate boundaries, not route
	# movement/gesture learning. Full traversal belongs to the portrait suite.
	game.player.global_position = Vector3(0, 0.1, 1.25)
	await create_timer(0.5).timeout
	game.player.shells = 0
	_expect(game.player.slash(Vector3.FORWARD) == 1, "staged workshop target clears through actual primary")
	await _settle()
	_expect(game.active_level.get("beat_index") == 3 and game.campaign_error.is_empty(), "workshop checkpoint prepares the inactive roof encounter")

func _new_shell() -> CinderCampaignShell:
	var result: CinderCampaignShell = Shell.new()
	result.configure_runtime(raw, TEST_ROOT + "campaign.json", TEST_ROOT + "settings.json", TEST_ROOT + "preferences.json")
	root.add_child(result)
	return result

func _settle() -> void:
	for index: int in range(6):
		await process_frame

func _finish() -> void:
	if is_instance_valid(game):
		game.free()
	paused = false
	_cleanup()
	print("A1-L1 authored campaign: %d checks, %d failures (TEST registry/next-level fixture; no production acceptance)" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _cleanup() -> void:
	for file: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT + file))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT))

func _expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + message)
