extends SceneTree
## Uses the actual shared portrait renderer. Repositioning is a framing fixture,
## not evidence of gesture play or combat completion. Run without --headless.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const LevelPath: String = "res://scenes/acts/act2/a2_l1.tscn"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(540, 1170)
	var game: Node = MainScene.instantiate()
	game.set("level_scene_path", LevelPath)
	root.add_child(game)
	game.call("resume_lab")
	await create_timer(0.25).timeout
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures/act2"))
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	var level: CinderLevel = game.get("active_level") as CinderLevel
	var scouts: Dictionary = level.get("_scouts")
	var requested_frame: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--frame="):
			requested_frame = argument.trim_prefix("--frame=")
	for frame: Dictionary in [
		{"name": "arrival-idle", "position": Vector3(-1.0, 0.1, 2.6), "phase": "idle", "progress": 0.0, "actors": ["arrival"]},
		{"name": "arrival-left-vignette", "position": Vector3(-1.0, 0.1, 2.6), "phase": "warning", "progress": 0.65, "actors": ["arrival"]},
		{"name": "arrival-warning", "position": Vector3(-1.0, 0.1, 2.6), "phase": "warning", "progress": 0.65, "actors": ["arrival"]},
		{"name": "road-lock", "position": Vector3(0, 0.1, -5.8), "phase": "lock", "progress": 0.5, "actors": ["road_east"]},
		{"name": "common-recovery", "position": Vector3(0.8, 0.1, -12.0), "phase": "recovery", "progress": 0.55, "actors": ["common_left"]},
		{"name": "departure-active", "position": Vector3(0, 0.1, -22.4), "phase": "active", "progress": 0.5, "actors": ["departure_a", "departure_b"]},
		{"name": "woking-defeated", "position": Vector3(0, 0.1, -28.8), "phase": "defeated", "progress": 1.0, "actors": ["departure_a", "departure_b"]},
	]:
		if not requested_frame.is_empty() and frame["name"] != requested_frame:
			continue
		hero.global_position = frame["position"]
		hero.velocity = Vector3.ZERO
		game.call("_update_camera", 0.0, true)
		for actor_id: String in scouts:
			var visual: Node3D = scouts[actor_id]
			visual.visible = actor_id in frame["actors"]
			visual.call("pose", frame["phase"], frame["progress"], (hero.global_position - visual.global_position).normalized())
		await process_frame
		await RenderingServer.frame_post_draw
		var path: String = "res://captures/act2/a2-l1-" + frame["name"] + ".png"
		var error: Error = root.get_texture().get_image().save_png(path)
		if error != OK:
			push_error("Portrait save failed: " + path)
			game.queue_free()
			quit(1)
			return
		print("Portrait fixture: " + path)
	game.queue_free()
	await process_frame
	quit(0)
