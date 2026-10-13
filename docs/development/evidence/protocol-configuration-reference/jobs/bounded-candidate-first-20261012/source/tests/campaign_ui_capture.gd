extends SceneTree
## Queued graphical review only. Fixture scenes are never accepted real content.
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const TEST_ROOT: String = "user://test-campaign-ui-capture/"
var game: CinderCampaignShell
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	root.size = Vector2i(540,1170)
	root.content_scale_size = Vector2i(540,1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	create_timer(45.0, true).timeout.connect(func() -> void: quit(1))
	_cleanup()
	var restart_only: bool = OS.get_cmdline_user_args().has("--capture-replay-restart")
	if not restart_only:
		game = _shell({})
		await _capture("campaign-title")
		game.menu.show_journey()
		await _capture("campaign-journey")
		game.menu.show_settings()
		await _capture("campaign-settings")
		game.free()
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Registry.DATA_PATH))
	for info: Dictionary in raw.levels:
		if ["A1-L1", "A1-L2", "A1-O1"].has(info.id):
			info.scene_path = "res://tests/fixtures/campaign/live_" + String(info.id).to_lower().replace("-", "_") + ".tscn"
			info.readiness = "accepted"
			info.accepted_commit = "a".repeat(40)
			info.api_revision = Registry.API_REVISION
	game = _shell(raw)
	game.menu.begin_story_requested.emit()
	await _settle()
	if game.active_level == null:
		push_error(game.campaign_error)
		quit(1)
		return
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(40,0.1,40)
	floor_mesh.mesh = box
	floor_mesh.position.y = -0.05
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("303744")
	material.roughness = 1.0
	floor_mesh.material_override = material
	game.active_level.add_child(floor_mesh)
	game.active_level.guard.hide()
	game.menu.hide_menu()
	game.hud.visible = true
	game.hud.hide_overlay()
	game.active_level.objective_text = "TEST ONLY · SHARED PORTRAIT PRESENTATION"
	game._update_status()
	if restart_only:
		game.active_level.request_completion("test")
		await _settle()
		game.attempts.grant_equipment(["WEAPON-02"])
		game.menu.replay_requested.emit("A1-L1",CinderEquipment.STARTER)
		await _settle()
		game.menu.show_pause()
		await _capture("test-replay-pause")
		(game.menu.find_child("RestartReplayButton",true,false) as Button).pressed.emit()
		await _capture("test-replay-restart-chooser")
		var scroll: ScrollContainer = game.menu.find_child("PageScroll",true,false) as ScrollContainer
		scroll.ensure_control_visible(game.menu.find_child("StartReplayButton",true,false) as Control)
		await _capture("test-replay-restart-action")
		game.free()
		paused = false
		_cleanup()
		print("Replay restart capture: three targeted540x1170 rendered UI images; no campaign acceptance")
		quit()
		return
	game.hud.show_pause()
	await _capture("test-shared-preview-paused")
	game.hud.hide_overlay()
	for id: String in ["act1_expedition", "act2_survivor", "act3_traveller"]:
		game.player.set_presentation(id)
		await _capture("test-shared-"+id)
	game.active_level.request_completion("test")
	await _settle()
	game.attempts.grant_equipment(["WEAPON-02"])
	game.menu.show_replay_setup("A1-L1")
	await _capture("test-campaign-replay")
	game.free()
	paused = false
	_cleanup()
	print("Campaign UI/presentation capture: eight 540x1170 rendered images; fixture gameplay, no campaign acceptance")
	quit()
func _shell(raw: Dictionary) -> CinderCampaignShell:
	var result: CinderCampaignShell = Shell.new()
	result.configure_runtime(raw, TEST_ROOT+"campaign.json",TEST_ROOT+"settings.json",TEST_ROOT+"preferences.json")
	root.add_child(result)
	return result
func _capture(label: String) -> void:
	await _settle()
	await RenderingServer.frame_post_draw
	var path: String = "res://captures/"+label+".png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	var error: Error = root.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Capture failed: "+label)
		quit(1)
	print("Rendered "+ProjectSettings.globalize_path(path))
func _settle() -> void:
	for index: int in range(4):
		await process_frame
func _cleanup() -> void:
	for name: String in ["campaign.json","campaign.json.bak","settings.json","settings.json.bak","preferences.json","preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT+name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT))
