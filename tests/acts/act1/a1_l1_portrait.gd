extends SceneTree
## Graphical opening evidence only; always exits its own queued engine session.
## Workshop composition is staged; first swipe/hall hit are actual from spawn.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const LevelPath: String = "res://scenes/acts/act1/a1_l1.tscn"
const CaptureDirectory: String = "res://captures/act1"
const PortraitSize: Vector2i = Vector2i(540, 1170)

var _checks: int = 0
var _failures: int = 0
var _shots: Array[Dictionary] = []
var _finished: bool = false
var _game: Node


func _initialize() -> void:
	create_timer(45.0, true).timeout.connect(_watchdog)
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_expect(false, "portrait harness requires a graphical renderer")
		quit(2)
		return
	root.size = PortraitSize
	var game: Node = MainScene.instantiate()
	_game = game
	game.set("level_scene_path", LevelPath)
	root.add_child(game)
	var level: CinderLevel = game.get("active_level") as CinderLevel
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	if level == null or hero == null:
		_expect(false, "A1-L1 starts through the shared graphical shell")
		quit(1)
		return
	var focused: bool = await _wait_for_focus()
	if not _require(focused, "actual game window gains stable focus before resume", game):
		return
	game.call("resume_lab")
	await create_timer(0.3, true).timeout
	if not _require(root.has_focus() and not paused, "focused launch stays resumed before the first capture", game):
		return
	if not _require(root.get_visible_rect().size.is_equal_approx(Vector2(PortraitSize)), "touch coordinates use the actual540x1170 portrait viewport", game):
		return
	if not _require(hero.global_position.distance_to(level.spawn_position()) < 0.2 and _beat(level) == 0, "first gesture begins at the actual authored spawn", game):
		return
	_expect(hero.presentation_id == "act1_expedition", "shared shell selects the G07 expedition presentation for Act1")
	await _capture("01-opening.png", game, level, hero)
	var camera: Camera3D = game.get("camera") as Camera3D
	var camera_before: Vector3 = camera.global_position
	if not _require(root.has_focus() and not paused, "first touch swipe begins with real focus and active simulation", game):
		return
	await _swipe(Vector2(140, 700), Vector2(140, 380))
	var anchor: Vector2 = game.call("get_aim_anchor")
	if not _require(anchor.distance_to(Vector2(140, 380)) < 0.5, "final upper-left release becomes the exact screen aim anchor", game):
		return
	var swipe_observation: Dictionary = game.call("get_input_observation_state")
	_expect((swipe_observation["anchor_normalized"] as Vector2).is_equal_approx(Vector2(140, 380) / Vector2(PortraitSize)) and swipe_observation["last_observation"].get("kind") == "swipe_release", "public input observation reports the actual normalized final release")
	await create_timer(0.25).timeout
	var records: Array[Dictionary] = hero.get_world_action_records()
	if not _require(not records.is_empty() and records[-1].kind == "dash" and float(records[-1].distance) > 2.6, "literal touch swipe executes one full world dash", game):
		return
	if not _require(_beat(level) == 1 and hero.global_position.distance_to(level.call("dash_marker_position")) < 0.2, "real dash landing immediately completes the first exercise", game):
		return
	_expect(camera.global_position.distance_to(camera_before) > 0.1 and (game.call("get_aim_anchor") as Vector2).is_equal_approx(anchor), "camera following the dash leaves the final screen anchor unchanged")
	await _capture("02-completed-dash-hall-target.png", game, level, hero)

	var direction: Vector3 = game.call("aim_direction", Vector2(300, 600))
	_expect(direction.x > 0.0 and direction.z > 0.0, "upper-left release then centre tap points down-right")
	hero.shells = 0
	var attack_sequence: int = _last_sequence(hero)
	await _tap(Vector2(300, 600))
	records = hero.get_world_action_records(attack_sequence)
	var targets: Dictionary = level.get("targets")
	if not _require(not records.is_empty() and records[-1].kind == "primary" and int(records[-1].hits) == 1 and (targets["hall"] as PracticeTarget).hp == 0.0, "centre touch tap executes a genuine immediate hall primary with empty shells", game):
		return
	var tap_observation: Dictionary = game.call("get_input_observation_state")
	_expect(tap_observation["last_observation"].get("kind") == "primary_tap" and tap_observation["last_observation"].get("accepted") == true and tap_observation["last_observation"].get("world_action_sequence") == records[-1].sequence, "public tap observation links this accepted literal aiming example to its real world attack")
	_expect(_beat(level) == 2, "hall hit advances without a lecture timer")
	await _capture("03-hall-primary.png", game, level, hero)
	await create_timer(0.4).timeout
	var facing_before: Vector3 = hero.facing
	hero.shells = 0
	attack_sequence = _last_sequence(hero)
	await _tap(anchor)
	records = hero.get_world_action_records(attack_sequence)
	if not _require(not records.is_empty() and records[-1].kind == "primary" and hero.facing.dot(facing_before) > 0.999, "touching the exact release point retains the preceding facing", game):
		return
	_expect(_beat(level) == 2, "zero-direction miss does not skip the workshop")

	var clock_before: float = hero.get_world_action_clock()
	var position_before: Vector3 = hero.global_position
	var actions_before: int = hero.get_world_action_records().size()
	game.call("open_bench")
	await create_timer(0.25, true).timeout
	_expect(paused and is_equal_approx(hero.get_world_action_clock(), clock_before) and hero.global_position.is_equal_approx(position_before), "pause freezes the shared action clock and actor")
	_expect((game.call("get_aim_anchor") as Vector2).is_equal_approx(anchor), "pause preserves the screen anchor")
	await _capture("04-paused.png", game, level, hero)
	var resume_button: Button = _resume_button(game.get("hud") as Node)
	if not _require(resume_button != null and root.has_focus(), "focused shared pause exposes a visible RESUME button", game):
		return
	await _click(resume_button.get_global_rect().get_center())
	if not _require(not paused and hero.get_world_action_records().size() == actions_before and (game.call("get_aim_anchor") as Vector2).is_equal_approx(anchor), "resume UI click is consumed without combat or anchor reset", game):
		return

	await create_timer(0.4).timeout
	await _swipe(Vector2(350, 700), Vector2(515, 700))
	await create_timer(0.4).timeout
	_expect((game.call("get_aim_anchor") as Vector2).distance_to(Vector2(515, 700)) < 0.5, "ordinary swipe may release at the right screen edge")
	await _capture("05-screen-edge-release.png", game, level, hero)
	var world_before: Vector3 = hero.global_position
	var sequence_before: int = _last_sequence(hero)
	await _swipe(Vector2(515, 700), Vector2(270, 650))
	await create_timer(0.4).timeout
	records = hero.get_world_action_records(sequence_before)
	if not _require(not records.is_empty() and records[-1].kind == "dash" and hero.global_position.distance_to(world_before) > 2.6, "edge-anchor remedy performs another ordinary world dash", game):
		return
	_expect((game.call("get_aim_anchor") as Vector2).distance_to(Vector2(270, 650)) < 0.5, "that dash restores a useful central release point without hidden recentering")
	await _capture("06-repositioned-anchor.png", game, level, hero)

	# This teleport is explicitly composition staging, not traversal evidence.
	var workshop: PracticeTarget = targets["workshop"] as PracticeTarget
	hero.global_position = workshop.global_position + Vector3(0.0, 0.1, 1.25)
	await create_timer(0.9).timeout
	var staged_note: String = "Shared hero teleported beside workshop for framing; subsequent touch attack is genuine."
	await _capture("07-workshop-staged-available.png", game, level, hero, staged_note)
	direction = game.call("aim_direction", Vector2(270, 400))
	_expect(direction.dot(Vector3.FORWARD) > 0.999, "workshop tap aims from the most recent ordinary swipe release")
	hero.shells = 0
	attack_sequence = _last_sequence(hero)
	await _tap(Vector2(270, 400))
	records = hero.get_world_action_records(attack_sequence)
	if not _require(not records.is_empty() and records[-1].kind == "primary" and int(records[-1].hits) == 1 and workshop.hp == 0.0 and _beat(level) == 3, "genuine empty-shell primary clears the staged workshop and advances immediately", game):
		return
	_expect(not level.is_completed(), "portrait opening evidence does not claim arm-dependent full completion")
	await _capture("08-workshop-staged-primary.png", game, level, hero, staged_note)
	if not _require(_failures == 0 and _shots.size() == 8, "eight opening shots succeed before staged scenery captures", game):
		return
	var scenery_note: String = "layout/scenery only; no arm/hatch gameplay or full traversal"
	if not _require(root.has_focus() and not paused, "roof staging begins with real focus and active simulation", game):
		return
	hero.global_position = Vector3(0.0, 0.1, -6.0)
	await create_timer(0.7, true).timeout
	if not _require(root.has_focus() and not paused, "roof scenery capture retains real focus and active simulation", game):
		return
	await _capture("09-roof-staged.png", game, level, hero, scenery_note)
	if not _require(root.has_focus() and not paused, "hatch staging begins with real focus and active simulation", game):
		return
	hero.global_position = Vector3(0.0, 0.1, -13.5)
	await create_timer(0.7, true).timeout
	if not _require(root.has_focus() and not paused, "hatch scenery capture retains real focus and active simulation", game):
		return
	await _capture("10-hatch-staged.png", game, level, hero, scenery_note)
	var output: FileAccess = FileAccess.open(CaptureDirectory + "/a1_l1_portrait_evidence.json", FileAccess.WRITE)
	_expect(output != null, "capture evidence file opens")
	var evidence: Dictionary = {
		"scope": "opening only; arm/full completion/campaign retry/transition excluded",
		"portrait_size": [PortraitSize.x, PortraitSize.y],
		"checks": _checks, "failures": _failures, "shots": _shots,
		"first_gesture": {"start": [140, 700], "release": [140, 380], "tap": [300, 600], "staged": false},
		"pause_scope": "idle opening; no loading-arm warning exists yet",
	}
	if output != null:
		output.store_string(JSON.stringify(evidence, "  ") + "\n")
		output.close()
	game.queue_free()
	paused = false
	await process_frame
	print("A1-L1 opening portrait: %d checks, %d failures; %d captures" % [_checks, _failures, _shots.size()])
	_finished = true
	quit(0 if _failures == 0 else 1)


func _capture(filename: String, game: Node, level: CinderLevel, hero: CinderPlayer, staged_note: String = "") -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	_expect(image != null and image.get_size() == PortraitSize, "capture is actual540x1170: " + filename)
	if image == null:
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CaptureDirectory))
	var path: String = CaptureDirectory + "/a1_l1_" + filename
	var save_error: Error = image.save_png(path)
	_expect(save_error == OK, "portrait image saves: " + filename)
	if save_error != OK:
		return
	var anchor: Vector2 = game.call("get_aim_anchor")
	var input_observation: Dictionary = game.call("get_input_observation_state")
	_shots.append({
		"path": path, "staged": not staged_note.is_empty(), "staging_note": staged_note,
		"beat_index": _beat(level), "hero_world_position": [hero.global_position.x, hero.global_position.y, hero.global_position.z],
		"anchor_screen_position": [anchor.x, anchor.y], "action_clock_s": hero.get_world_action_clock(),
		"presentation_id": hero.presentation_id, "input_observation_sequence": input_observation["sequence"],
		"last_input_kind": input_observation["last_observation"].get("kind", ""),
	})


func _swipe(start: Vector2, finish: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.index = 7
	press.pressed = true
	press.position = start
	Input.parse_input_event(press)
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.index = 7
	drag.position = finish
	drag.relative = finish - start
	Input.parse_input_event(drag)
	await process_frame
	var release := InputEventScreenTouch.new()
	release.index = 7
	release.position = finish
	Input.parse_input_event(release)
	await process_frame


func _tap(point: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.index = 7
	press.pressed = true
	press.position = point
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventScreenTouch.new()
	release.index = 7
	release.position = point
	Input.parse_input_event(release)
	await process_frame


func _click(point: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = point
	press.global_position = point
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = point
	release.global_position = point
	Input.parse_input_event(release)
	await process_frame


func _resume_button(node: Node) -> Button:
	if node is Button and (node as Button).is_visible_in_tree() and (node as Button).text.begins_with("RESUME"):
		return node as Button
	for child: Node in node.get_children():
		var found: Button = _resume_button(child)
		if found != null:
			return found
	return null


func _beat(level: CinderLevel) -> int:
	return int(level.get("beat_index"))


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	print("PASS: " if condition else "FAIL: ", description)
	if not condition:
		_failures += 1


func _wait_for_focus() -> bool:
	print("WAITING: Focus the actual game window; launch resumes only after stable real focus.")
	var deadline_ms: int = Time.get_ticks_msec() + 30000
	var focused_since_ms: int = -1
	while Time.get_ticks_msec() < deadline_ms:
		var now_ms: int = Time.get_ticks_msec()
		if root.has_focus() and DisplayServer.window_is_focused(root.get_window_id()):
			if focused_since_ms < 0:
				focused_since_ms = now_ms
			if now_ms - focused_since_ms >= 300:
				return true
		else:
			focused_since_ms = -1
		await create_timer(0.1, true).timeout
	return false


func _last_sequence(hero: CinderPlayer) -> int:
	var records: Array[Dictionary] = hero.get_world_action_records()
	return 0 if records.is_empty() else int(records[-1].sequence)


func _require(condition: bool, description: String, game: Node) -> bool:
	_expect(condition, description)
	if not condition:
		_stop(game, description)
	return condition


func _stop(game: Node, reason: String) -> void:
	_finished = true
	print("ABORT: ", reason, "; focused=", root.has_focus(), "; paused=", paused)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CaptureDirectory))
	var output: FileAccess = FileAccess.open(CaptureDirectory + "/a1_l1_portrait_evidence.json", FileAccess.WRITE)
	if output != null:
		output.store_string(JSON.stringify({"scope": "opening only", "aborted": true, "reason": reason, "focused": root.has_focus(), "paused": paused, "checks": _checks, "failures": _failures, "shots": _shots}, "  ") + "\n")
		output.close()
	if is_instance_valid(game):
		game.queue_free()
	paused = false
	quit(1)


func _watchdog() -> void:
	if not _finished:
		_expect(false, "bounded portrait harness timeout45s")
		_stop(_game, "bounded harness timeout")
