extends SceneTree
## Uses the actual shared portrait renderer. Repositioning is a framing fixture,
## not evidence of gesture play or combat completion. Single-Scout frames use
## the actual shared cue renderer with illustrative geometry, without scheduler
## admission/damage. Paired poses remain art-only. Run without --headless.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const LevelPath: String = "res://scenes/acts/act2/a2_l1.tscn"
const ThreatCue: Script = preload("res://scripts/cues/threat_cue.gd")
const Geometry: Script = preload("res://scripts/combat/threat_geometry.gd")

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
	var cues: Dictionary = {}
	for actor_id: String in scouts:
		var cue: Node3D = ThreatCue.new() as Node3D
		cue.name = "PortraitFixtureCue_" + actor_id
		level.add_child(cue)
		cues[actor_id] = cue
	var requested_frame: String = ""
	var requested_prefix: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--frame-prefix="):
			requested_prefix = argument.trim_prefix("--frame-prefix=")
		if argument.begins_with("--frame="):
			requested_frame = argument.trim_prefix("--frame=")
	paused = true
	for frame: Dictionary in [
		{"name": "arrival-idle", "position": Vector3(-1.0, 0.1, 2.6), "phase": "idle", "progress": 0.0, "actors": ["arrival"]},
		{"name": "arrival-left-vignette", "position": Vector3(-1.0, 0.1, 2.6), "phase": "warning", "progress": 0.65, "actors": ["arrival"]},
		{"name": "arrival-turn", "position": Vector3(-1.0, 0.1, 2.6), "phase": "defeated", "progress": 1.0, "actors": ["arrival"], "tableau": "retreat", "scenic_clock": 0.16},
		{"name": "arrival-step-a", "position": Vector3(-1.0, 0.1, 2.6), "phase": "defeated", "progress": 1.0, "actors": ["arrival"], "tableau": "retreat", "scenic_clock": 0.32},
		{"name": "arrival-step-b", "position": Vector3(-1.0, 0.1, 2.6), "phase": "defeated", "progress": 1.0, "actors": ["arrival"], "tableau": "retreat", "scenic_clock": 0.48},
		{"name": "arrival-retreat", "position": Vector3(-1.0, 0.1, 2.6), "phase": "defeated", "progress": 1.0, "actors": ["arrival"], "tableau": "retreat", "scenic_clock": 0.8},
		{"name": "arrival-empty", "position": Vector3(-1.0, 0.1, 2.6), "phase": "defeated", "progress": 1.0, "actors": ["arrival"], "tableau": "absent", "scenic_clock": 1.6},
		{"name": "arrival-warning", "position": Vector3(-1.0, 0.1, 2.6), "phase": "warning", "progress": 0.65, "actors": ["arrival"]},
		{"name": "road-lock", "position": Vector3(0, 0.1, -5.8), "phase": "lock", "progress": 0.5, "actors": ["road_east"]},
		{"name": "common-recovery", "position": Vector3(0.8, 0.1, -12.0), "phase": "recovery", "progress": 0.55, "actors": ["common_left"]},
		{"name": "departure-active", "position": Vector3(0, 0.1, -22.4), "phase": "active", "progress": 0.5, "actors": ["departure_a", "departure_b"]},
		{"name": "woking-defeated", "position": Vector3(0, 0.1, -28.8), "phase": "defeated", "progress": 1.0, "actors": ["departure_a", "departure_b"]},
	]:
		if not requested_prefix.is_empty() and not String(frame["name"]).begins_with(requested_prefix):
			continue
		if not requested_frame.is_empty() and frame["name"] != requested_frame:
			continue
		var tableau: Dictionary = level.snapshot_state()
		tableau["local"]["witness_state"] = frame.get("tableau", "arrival")
		tableau["local"]["scenic_clock"] = frame.get("scenic_clock", 0.0)
		tableau["local"]["eruption_visible"] = false
		if not level.restore_state(tableau):
			push_error("Portrait tableau failed: " + level.last_snapshot_error)
			game.queue_free()
			paused = false
			quit(1)
			return
		hero.global_position = frame["position"]
		hero.velocity = Vector3.ZERO
		game.call("_update_camera", 0.0, true)
		for actor_id: String in scouts:
			cues[actor_id].clear()
			var visual: Node3D = scouts[actor_id]
			visual.visible = actor_id in frame["actors"]
			var exact_direction := Vector3(hero.global_position.x - visual.global_position.x, 0, hero.global_position.z - visual.global_position.z).normalized()
			visual.call("pose", frame["phase"], frame["progress"], exact_direction)
			if visual.visible and frame["actors"].size() == 1 and frame["phase"] in ["warning", "lock", "recovery"]:
				var geometry: Dictionary = Geometry.lane(visual.global_position, visual.global_position + exact_direction * 3.8, 0.31)
				geometry["source_position"] = visual.global_position
				if not cues[actor_id].present(geometry, frame["phase"]):
					push_error("Portrait cue failed: " + cues[actor_id].last_error)
					game.queue_free()
					quit(1)
					return
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
	if OS.get_cmdline_user_args().has("--witness-atlas"):
		var gallery := Image.create(336, 288, false, Image.FORMAT_RGBA8)
		gallery.fill(Color("a49884"))
		var kit: Dictionary = level.get("_kit")
		for row: int in range(4):
			var state: Dictionary = level.snapshot_state()
			state["local"]["witness_state"] = "arrival" if row == 0 else "retreat"
			state["local"]["scenic_clock"] = [0.0, 0.16, 0.32, 0.48][row]
			state["local"]["eruption_visible"] = false
			if not level.restore_state(state):
				push_error("Witness gallery restore failed: " + level.last_snapshot_error)
				game.queue_free()
				paused = false
				quit(1)
				return
			for column: int in range(6):
				var costume: Sprite3D = (kit["witnesses"][column] as Node3D).get_node("FeetAnchoredCostume") as Sprite3D
				gallery.blit_rect(costume.texture.get_image(), Rect2i(0, 0, 48, 64), Vector2i(column * 56 + 4, row * 72 + 4))
		var atlas_path: String = "res://captures/act2/a2-l1-witness-pose-gallery.png"
		if gallery.save_png(atlas_path) != OK:
			push_error("Witness gallery save failed")
			game.queue_free()
			paused = false
			quit(1)
			return
		print("Witness runtime texture gallery: watch / turn / step-a / step-b; columns variants0..5: " + atlas_path)
	game.queue_free()
	paused = false
	await process_frame
	quit(0)
