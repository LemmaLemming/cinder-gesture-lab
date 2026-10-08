extends SceneTree
## Integration of accepted authored entries through the actual Title/Journey
## and persistent shared shell. No injected registry or future-level fixture.
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const TEST_ROOT: String = "user://test-campaign-registration/"
var checks: int = 0
var failures: int = 0
var game: CinderCampaignShell
var graphical: bool = false

func _initialize() -> void:
	graphical = "--portrait" in OS.get_cmdline_user_args()
	create_timer(60.0, true).timeout.connect(func() -> void:
		_expect(false, "production registration fixture completes within its watchdog")
		_finish())
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_cleanup()
	var registry := Registry.new()
	_expect(registry.last_error.is_empty() and registry.ids().size() == 24, "actual production registry retains all canonical level identities")
	_expect(registry.entry("A1-L1").accepted_commit == "06628abb3f38020f1b958562a367811173e556de" and registry.scene_error("A1-L1").is_empty(), "accepted exact authored A1-L1 scene validates through the production registry")
	var available: Array[String] = []
	for id: String in registry.ids():
		if registry.is_playable(id):
			available.append(id)
	_expect(available == ["A1-L1"], "only independently accepted opening is playable; all future scenes stay gated")
	game = _new_shell()
	await _settle()
	_expect(paused and game.menu.page_name() == "title" and game.active_level == null, "actual campaign begins at paused Title without inventing a live actor")
	var begin := _find("BeginStoryButton") as Button
	_expect(begin != null and not begin.disabled, "accepted production opening enables Begin Story")
	await _capture("title")
	await _click(_find("JourneyButton") as Control)
	_expect(game.menu.page_name() == "journey" and paused, "actual Journey GUI click stays paused")
	_expect((_find("Node_A1_L1") as Button).get_meta("campaign_state") == "available" and (_find("Node_A1_L2") as Button).get_meta("campaign_state") == "locked" and registry.entry("A1-L2").readiness == "unimplemented", "winding Journey exposes accepted opening while next level stays progression-locked and unimplemented")
	_expect(not (_find("LevelCardAction") as Button).disabled, "selected accepted opening has an enabled Journey action")
	await _capture("journey")
	await _click(_find("LevelCardAction") as Control)
	_expect(game.campaign_error.is_empty() and game.active_level != null and game.active_level.level_id == "A1-L1", "Journey action loads actual authored opening through shared shell: " + game.campaign_error)
	if game.active_level == null:
		_finish()
		return
	_expect(game.active_level.scene_file_path == "res://scenes/acts/act1/a1_l1.tscn" and game.player.presentation_id == "act1_expedition", "accepted scene uses the common Act1 presented player")
	_expect(paused and game.menu.is_open() and game.player.get_world_action_records().is_empty(), "beginning menu click creates no combat action and waits for Resume")
	var entry: Dictionary = game.capture_campaign_snapshot()
	_expect(not entry.is_empty() and FileAccess.file_exists(TEST_ROOT + "campaign.json"), "accepted fresh opening publishes a coherent format2 story save")
	var entry_anchor: Vector2 = game.get_aim_anchor_normalized()
	await _click(_find("ResumeButton") as Control)
	_expect(not paused and game.get_aim_anchor_normalized() == entry_anchor and game.player.get_world_action_records().is_empty(), "actual Resume click is consumed without aim or attack publication")
	await create_timer(0.1).timeout
	game.request_pause()
	await _settle()
	_expect(paused and game.menu.is_open(), "actual authored story can pause through the shared deferred boundary")
	var saved: Dictionary = game.capture_campaign_snapshot()
	var encoded: String = Exact.stringify(saved)
	_expect(not encoded.is_empty() and saved.level.level_id == "A1-L1", "actual opening paused aggregate includes exact actor/local/shell state")
	game.free()
	game = _new_shell()
	await _settle()
	_expect(paused and game.active_level == null and game.menu.page_name() == "title", "reopening production campaign loads durable state at Title")
	var continuing := _find("ContinueStoryButton") as Button
	_expect(continuing != null and not continuing.disabled, "accepted durable story enables Continue Story")
	await _click(continuing)
	_expect(game.campaign_error.is_empty() and game.active_level != null and Exact.stringify(game.capture_campaign_snapshot()) == encoded, "Continue restores exact real opening in a fresh world without advancing clocks: " + game.campaign_error)
	if game.active_level == null:
		_finish()
		return
	_expect(paused and game.menu.is_open(), "continued opening resumes paused until its own consumed menu gesture")
	game.request_retry()
	await _settle()
	_expect(game.campaign_error.is_empty() and Exact.stringify(game.capture_campaign_snapshot()) == Exact.stringify(entry), "actual Retry restores coherent initial checkpoint, including exact shell state")
	await _click(_find("ResumeButton") as Control)
	await _settle()
	await _capture("opening")
	_expect(game.active_level.camera_framing_points().is_empty() and not game.get_camera_framing_state().get("enabled", true), "accepted opening retains its default close following camera without an opt-in framing hook")
	_finish()

func _new_shell() -> CinderCampaignShell:
	var result: CinderCampaignShell = Shell.new()
	_expect(result.configure_runtime({}, TEST_ROOT + "campaign.json", TEST_ROOT + "settings.json", TEST_ROOT + "preferences.json"), "real registry runtime configures isolated test save paths")
	root.add_child(result)
	return result

func _find(name: String) -> Node:
	return game.menu.find_child(name, true, false)

func _click(control: Control) -> void:
	if control == null:
		_expect(false, "required actual GUI control exists")
		return
	await _settle()
	var at: Vector2 = control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	root.push_input(motion, true)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = at
	click.global_position = at
	click.pressed = true
	root.push_input(click, true)
	click = click.duplicate() as InputEventMouseButton
	click.pressed = false
	root.push_input(click, true)
	await _settle()

func _capture(label: String) -> void:
	if not graphical:
		return
	await RenderingServer.frame_post_draw
	var path: String = "res://captures/campaign-registration-" + label + ".png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	_expect(root.get_texture().get_image().save_png(path) == OK, "actual portrait capture saved: " + label)

func _settle() -> void:
	for index: int in range(8):
		await process_frame

func _cleanup() -> void:
	for file: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT + file))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT))

func _finish() -> void:
	if is_instance_valid(game):
		game.free()
	paused = false
	_cleanup()
	print("Production campaign registration: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)
