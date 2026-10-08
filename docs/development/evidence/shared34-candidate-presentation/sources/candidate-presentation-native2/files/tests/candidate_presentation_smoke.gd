extends SceneTree
## TEST ONLY real later-room Player actions and native candidate optical gate.
## No act acceptance, synthetic saved body, pose translation or current alias swap.
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const LEVEL_PATH: String = "res://tests/fixtures/candidate_presentation_level.tscn"
var game: CinderCampaignShell
var candidate: Dictionary = {}
var checks: int = 0
var failures: int = 0
var finished: bool = false
var test_root: String
var old_fps: int
var old_audio: AudioBusLayout

func _initialize() -> void:
	old_fps = Engine.max_fps
	old_audio = AudioServer.generate_bus_layout()
	test_root = "user://test-candidate-presentation-%d/" % OS.get_process_id()
	_run.call_deferred()

func _run() -> void:
	create_timer(40.0, true).timeout.connect(func() -> void:
		if not finished:
			_expect(false, "bounded native fixture watchdog")
			_finish())
	root.size = Vector2i(540, 1170)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Registry.DATA_PATH))
	for entry: Dictionary in raw.levels:
		if entry.id == "A1-L1":
			entry.scene_path = LEVEL_PATH
			entry.readiness = "accepted"
			entry.accepted_commit = "a".repeat(40)
			entry.api_revision = Registry.API_REVISION
	game = Shell.new()
	if not _guard(game.configure_runtime(raw, test_root + "campaign.json", test_root + "settings.json", test_root + "preferences.json"), "isolated TEST ONLY native Shell registry/configuration"):
		_finish(); return
	root.add_child(game)
	await _frames(4)
	if not _guard(paused and game.player == null, "fresh native Title has no installed Player"):
		_finish(); return
	game.menu.begin_story_requested.emit()
	await _frames(6)
	if not _guard(is_instance_valid(game.player) and game.campaign_error.is_empty(), "public Begin creates the genuine first room: " + game.campaign_error):
		_finish(); return
	var first: Dictionary = game.attempts.active_snapshot()
	game.menu.resume_requested.emit()
	await create_timer(0.15).timeout
	for index: int in range(4):
		if not _guard(game.player.request_dash(Vector3.BACK), "genuine ordinary dash %d advances toward the later room" % (index + 1)):
			_finish(); return
		await create_timer(0.8).timeout
		if not _guard(not paused and not game.player.get_committed_dash_state().active, "native dash %d finishes through ordinary simulation" % (index + 1)):
			_finish(); return
	_expect(game.player.global_position.z > 10.0 and game.active_level.room_index == 2, "real actions earn later topology and Player position, without a saved body seed")
	game.request_pause()
	await _frames(6)
	if not _guard(paused and game.campaign_error.is_empty(), "public deferred Pause captures the actual later-room unit: " + game.campaign_error):
		_finish(); return
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _guard(not saved.is_empty(), "current physical capture includes actual wrapped HUD/full Player framing"):
		_finish(); return
	var donor: Dictionary = _donor_receipt()
	var hidden: Dictionary = game._prepare(saved.level_id, saved.equipment_ids, {}, saved)
	if not _guard(not hidden.is_empty(), "pure factory builds actual pristine room-two recipients at the original Player spawn"):
		_finish(); return
	_expect(hidden.player.global_position.z < 0.1 and hidden.level.quiet_commits == 0, "constructor applies no saved Player motion or local simulation clock")
	var native_before: String = Exact.stringify(hidden.player.snapshot_state())
	_expect(hidden.player.snapshot_error(saved.player).is_empty() and hidden.level.snapshot_error_with_player(saved.level, saved.player).is_empty(), "pure saved mechanical/context validation succeeds before quiet commit")
	_expect(Exact.stringify(hidden.player.snapshot_state()) == native_before and _donor_receipt() == donor, "pure prevalidation leaves actual fresh Player and installed donor unchanged")
	var old_plan: Dictionary = game.camera_framing_plan_for_player(hidden.level.camera_framing_points(), game.player.global_position + Vector3.UP * 0.75, hidden.player, hidden.camera)
	_expect(not old_plan.accepted, "current-spawn optical plan honestly cannot represent the later saved Player pose")
	game._dispose(hidden)
	candidate = game._prepare_snapshot(saved)
	if not _guard(not candidate.is_empty(), "post-quiet native saved-pose optical gate accepts the actual later room: " + game.campaign_error):
		_finish(); return
	_expect(not candidate.container.visible and candidate.level.is_restore_candidate() and candidate.level.quiet_commits == 1, "accepted recipient stays hidden, paused and nonplayable after one quiet commit")
	_expect(Exact.stringify(candidate.player.snapshot_state()) == Exact.stringify(saved.player), "gate measured the exact actual restored full Player, not translated bounds")
	_expect(candidate.camera.global_position == Vector3(saved.shell.camera_focus[0], saved.shell.camera_focus[1], saved.shell.camera_focus[2]) + game.CAMERA_OFFSET, "only candidate camera is positioned at the saved actual focus before the optical gate")
	_expect(_donor_receipt() == donor, "successful candidate optical assessment changes no donor/UI/attempt/disk state")
	game._dispose(candidate); candidate = {}

	# Negative saved camera transport is TEST ONLY. Player/local resources and
	# action history remain exact genuine captures; no physical pose is seeded.
	var wrong_focus: Dictionary = saved.duplicate(true)
	wrong_focus.shell.camera_focus[0] += 100.0
	_expect(game._snapshot_problem(wrong_focus).is_empty(), "mechanical pure validation alone does not fabricate optical acceptance")
	candidate = game._prepare_snapshot(wrong_focus)
	_expect(candidate.is_empty() and not game.campaign_error.is_empty(), "actual restored candidate refuses clipped saved native projection and is disposed")
	_expect(_donor_receipt() == donor and game._validation_candidates.is_empty(), "failed optical gate retains donor resources/UI/aliases, attempt generations and disk bytes with no hidden candidate leak")
	game.campaign_error = ""
	candidate = game._prepare_snapshot(saved)
	_expect(not candidate.is_empty(), "same original valid native save still accepts after rejected optical transport")
	if not candidate.is_empty(): game._dispose(candidate)
	candidate = {}
	game._dispose_validation_candidates()

	# Fresh Title/disk Continue measures the saved later-room unit independently
	# while the genuine installed donor remains paused in its original world.
	var fresh: CinderCampaignShell = Shell.new()
	if not _guard(fresh.configure_runtime(raw, test_root + "campaign.json", test_root + "settings.json", test_root + "preferences.json"), "fresh actual Shell opens the existing exact disk generation"):
		fresh.free(); _finish(); return
	root.add_child(fresh)
	await _frames(5)
	_expect(paused and fresh.player == null and fresh.menu.page_name() == "title", "independent disk recipient starts at real Title with no installed Player")
	fresh.menu.continue_story_requested.emit()
	await _frames(7)
	_expect(fresh.campaign_error.is_empty() and is_instance_valid(fresh.player) and fresh.active_level.room_index == 2, "public fresh disk Continue installs the actual later-room quiet-gated candidate: " + fresh.campaign_error)
	if is_instance_valid(fresh.player):
		_expect(Exact.stringify(fresh.player.snapshot_state()) == Exact.stringify(saved.player), "fresh disk Continue retains exact original Player resources/actions/native pose")
	_expect(_donor_receipt() == donor, "fresh disk Continue preserves the original paused donor and existing disk generation")
	fresh.free()

	# Actual public checkpoint Retry uses the earlier first room, while the
	# installed donor was physically later-room. The old checkpoint is genuine.
	game.menu.retry_requested.emit()
	await _frames(7)
	_expect(game.campaign_error.is_empty() and game.active_level.room_index == 1 and game.player.global_position.z < 0.1, "public Retry installs genuine earlier-room checkpoint only after its native gate: " + game.campaign_error)
	_expect(Exact.stringify(game.attempts.active_snapshot().player) == Exact.stringify(first.player), "Retry retains the exact protected earlier Player resources/action unit")
	_finish()

func _donor_receipt() -> Dictionary:
	var disk: Dictionary = {}
	for name: String in ["campaign.json", "campaign.json.bak"]:
		var path: String = test_root + name
		disk[name] = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else null
	return {"player_id": game.player.get_instance_id(), "level_id": game.active_level.get_instance_id(), "world_id": game.world.get_instance_id(), "camera_id": game.camera.get_instance_id(), "camera": game.camera.global_transform, "player": Exact.stringify(game.player.snapshot_state()), "level": Exact.stringify(game.active_level.snapshot_state()), "attempts": Exact.stringify(game.attempts.state()), "safe_rect": game.hud.combat_safe_rect(), "objective": game.hud._objective_label.text, "anchor": game._swipe_end_normalized, "input": game._input_sequence, "focus": game._camera_focus, "shake": game._shake, "disk": disk}

func _frames(count: int) -> void:
	for _index: int in range(count): await process_frame

func _guard(ok: bool, note: String) -> bool:
	_expect(ok, note)
	return ok

func _expect(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + note)

func _finish() -> void:
	if finished: return
	finished = true
	if is_instance_valid(game):
		if not candidate.is_empty(): game._dispose(candidate)
		game.free()
	paused = false
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root + name))
	Engine.max_fps = old_fps
	AudioServer.set_bus_layout(old_audio)
	print("Candidate presentation smoke: %d checks, %d failures; actual native later-room Player/current camera/HUD, no act acceptance" % [checks, failures])
	quit(0 if failures == 0 else 1)
