extends SceneTree
## Actual shared-shell portrait evidence for the unfinished scenery stage.
## Launch with dev.py engine --path . --script this file; do not add --capture,
## whose shared startup helper would quit before this owned sequence completes.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const SunScript: GDScript = preload("res://scripts/acts/act3/twin_suns.gd")
const RoomPath: String = "res://scenes/acts/act3/a3_l1_sun_room.tscn"
const FullPath: String = "res://scenes/acts/act3/a3_l1.tscn"
const OutputPath: String = "res://captures/act3/twin-suns"

var _failed: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game: Node = MainScene.instantiate()
	var companion_only: bool = OS.get_cmdline_user_args().has("--companion-only")
	game.set("level_scene_path", FullPath if companion_only else RoomPath)
	root.add_child(game)
	game.call("resume_lab")
	await _ticks(game, 15)
	var level: CinderLevel = game.get("active_level") as CinderLevel
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	if level == null or hero == null:
		push_error("Twin Suns capture requires the shared shell's ready room and actor")
		_failed = true
	elif companion_only:
		await _dash(game, hero, Vector3.LEFT)
		for _index: int in range(4):
			await _dash(game, hero, Vector3.FORWARD)
		await _wait_simulation(game, hero, 0.4)
		await _save("08-full-compassion-alcove.png")
		for _index: int in range(int(Engine.physics_ticks_per_second * SunScript.SUN_PERIOD_S)):
			if int(level.get("sun_state")) == 1:
				break
			await _ticks(game, 1)
		if int(level.get("sun_state")) != 1:
			push_error("Companion review did not reach the second actual scenic sun state")
			_failed = true
		await _save("10-companions-alppain.png")
		await _dash(game, hero, Vector3.LEFT)
		await _dash(game, hero, Vector3.FORWARD)
		await _save("11-companions-lateral-pass.png")
		await _dash(game, hero, Vector3.FORWARD)
		await _save("12-companions-passed.png")
	else:
		await _save("01-room-branchspell.png")
		await _dash(game, hero, Vector3.LEFT)
		await _wait_simulation(game, hero, 0.35)
		await _save("02-room-west-pocket.png")
		for _index: int in range(int(Engine.physics_ticks_per_second * (SunScript.SUN_PERIOD_S + 2.0))):
			if int(level.get("sun_state")) == 1:
				break
			await _ticks(game, 1)
		if int(level.get("sun_state")) != 1:
			push_error("Twin Suns capture did not observe the actual Alppain state")
			_failed = true
		else:
			await _save("03-room-alppain.png")
		if not game.call("load_level_scene", FullPath):
			push_error("Twin Suns capture could not select the authored full layout")
			_failed = true
		else:
			await _ticks(game, 15)
			hero = game.get("player") as CinderPlayer
			await _save("04-full-arrival.png")
			# Travel by accepted ordinary swipes; no teleports or private clocks.
			await _dash(game, hero, Vector3.LEFT)
			for _index: int in range(4):
				await _dash(game, hero, Vector3.FORWARD)
			await _wait_simulation(game, hero, 0.4)
			await _save("08-full-compassion-alcove.png")
			for _index: int in range(17):
				await _dash(game, hero, Vector3.FORWARD)
			await _wait_simulation(game, hero, 0.4)
			if hero.global_position.z > -12.0:
				push_error("Twin Suns crossing capture failed to reach the authored crossing")
				_failed = true
			await _save("05-full-white-shadow-crossing.png")
	game.queue_free()
	paused = false
	await process_frame
	print("Twin Suns portrait capture: %s; outputs %s" % ["failed" if _failed else "complete", ProjectSettings.globalize_path(OutputPath)])
	quit(1 if _failed else 0)


func _dash(game: Node, hero: CinderPlayer, direction: Vector3) -> void:
	var history: Array[Dictionary] = hero.get_world_action_records()
	var sequence: int = int(history[-1]["sequence"]) if not history.is_empty() else 0
	var stats: Dictionary = hero.equipment.resolved_stats()
	game.call("resume_lab")
	if not hero.request_dash(direction):
		push_error("Portrait capture's ordinary swipe was not immediately accepted")
		_failed = true
	await _wait_simulation(game, hero, float(stats["dash_cooldown"]) + 0.035)
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	if records.size() != 1 or records[0].get("kind") != "dash" or bool(records[0].get("blocked", true)):
		push_error("Portrait capture ordinary swipe has no unobstructed completed world record")
		_failed = true


func _wait_simulation(game: Node, hero: CinderPlayer, duration: float) -> void:
	var deadline: float = hero.get_world_action_clock() + duration
	var limit: int = int(ceilf(duration * Engine.physics_ticks_per_second)) + 8
	for _index: int in range(limit):
		if hero.get_world_action_clock() >= deadline:
			return
		await _ticks(game, 1)
	push_error("Portrait capture simulation did not advance within its bounded wait")
	_failed = true


func _ticks(game: Node, count: int) -> void:
	for _index: int in range(count):
		# Automated capture owns this preview. A desktop focus notification may
		# open its normal pause overlay; resume through the public shell method.
		if paused:
			game.call("resume_lab")
		await physics_frame
		await process_frame


func _save(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OutputPath))
	if error != OK:
		push_error("Could not create owned portrait capture directory: %s" % error)
		_failed = true
		return
	var rendered: Image = root.get_texture().get_image()
	var path: String = OutputPath.path_join(filename)
	if rendered == null or rendered.is_empty() or rendered.save_png(path) != OK:
		push_error("Could not save actual portrait evidence: " + path)
		_failed = true
		return
	print("CAPTURE: ", ProjectSettings.globalize_path(path))
