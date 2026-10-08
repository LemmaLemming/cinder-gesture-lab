extends SceneTree
## Affected physical-layout check: both actual swipe routes rejoin on one floor.
## No enemy/circle/full-level/progression or authored-art acceptance follows.

const MainScene = preload("res://scenes/main.tscn")
const LEVEL_PATH: String = "res://scenes/acts/act1/a1_l2_layout_greybox.tscn"
var game: Node
var hero: CinderPlayer
var checks: int = 0
var failures: int = 0
var portrait: bool = false
var capture_dir: String = ""
var captures: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	portrait = "--portrait" in OS.get_cmdline_user_args()
	if portrait:
		if not _expect(DisplayServer.get_name() != "headless", "scenery review requires the actual graphical renderer"):
			_finish(); return
		capture_dir = "res://.cinder/captures/l2-lunar-layout-%d" % Time.get_ticks_usec()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
		print("SCRIPTED LUNAR PORTRAIT: native_focus_observed=", DisplayServer.window_is_focused(), "; normal guards unchanged; ", capture_dir)
	for side: float in [-1.0, 1.0]:
		game = MainScene.instantiate()
		game.set("level_scene_path", LEVEL_PATH)
		root.add_child(game)
		hero = game.get("player") as CinderPlayer
		var level: CinderLevel = game.get("active_level") as CinderLevel
		_expect(level != null and hero != null and level.hero == hero and level.contract_error().is_empty(), "layout uses actual shared shell/hero and reachable spawn")
		if side < 0.0: await _capture("landing")
		game.call("resume_lab")
		for step: int in 5:
			if not await _swipe(Vector3.FORWARD):
				_finish(); return
		_expect(absf(hero.global_position.z - 2.5) < 0.03, "actual forward approach reaches the broad split before its physical rock")
		if side < 0.0: await _capture("split")
		if not await _swipe(Vector3(side, 0, 0)):
			_finish(); return
		for step: int in 4:
			if not await _swipe(Vector3.FORWARD):
				_finish(); return
			if step == 0: await _capture("rock-approach" if side < 0.0 else "open-approach")
		_expect(absf(hero.global_position.x - side * 2.7) < 0.03 and hero.global_position.z < -8.2 and hero.is_on_floor(), "rock/open approach has native capsule clearance and rejoins without a long backtrack")
		if not await _swipe(Vector3(-side, 0, 0)):
			_finish(); return
		if side < 0.0: await _capture("camp")
		for step: int in 5:
			if not await _swipe(Vector3.FORWARD):
				_finish(); return
		_expect(absf(hero.global_position.x) < 0.03 and absf(hero.global_position.z + 21.8) < 0.05 and hero.hp == 100.0 and not level.is_completed(), "both routes reach the grotto site on supported floor without claiming campaign completion")
		if side < 0.0: await _capture("grotto")
		level.exit_level()
		game.queue_free()
		await process_frame
	_finish()


func _swipe(direction: Vector3) -> bool:
	var camera: Camera3D = game.get("camera") as Camera3D
	var origin: Vector3 = hero.global_position
	var projected: Vector2 = camera.unproject_position(origin + direction) - camera.unproject_position(origin)
	var finish := Vector2(270, 650)
	var drag_vector: Vector2 = projected.normalized() * 180.0
	var records: Array[Dictionary] = hero.get_world_action_records()
	var sequence: int = 0 if records.is_empty() else records[-1].sequence
	var press := InputEventScreenTouch.new()
	press.index = 8; press.pressed = true; press.position = finish - drag_vector
	Input.parse_input_event(press)
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.index = 8; drag.position = finish; drag.relative = drag_vector
	Input.parse_input_event(drag)
	await process_frame
	var release := InputEventScreenTouch.new()
	release.index = 8; release.position = finish
	Input.parse_input_event(release)
	await process_frame
	for attempt: int in 100:
		if hero.get_threat_response_state().stable and not hero.get_world_action_records(sequence).is_empty(): break
		await create_timer(0.01, true).timeout
	var executed: Array[Dictionary] = hero.get_world_action_records(sequence)
	var valid: bool = executed.size() == 1 and executed[0].kind == "dash" and executed[0].direction.dot(direction) > 0.9999 and executed[0].distance > 2.65 and game.call("get_aim_anchor_normalized") == finish / root.get_visible_rect().size
	if not valid: print("LAYOUT SWIPE DIAGNOSTIC ", hero.global_position, " records=", executed)
	return _expect(valid, "literal recognizer swipe retains full supported dash and release-point aim")


func _expect(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	return ok


func _capture(stage: String) -> void:
	if not portrait: return
	# Static scenery review waits for the ordinary shared camera to finish its
	# following response after the completed swipe; gameplay gains no delay.
	await create_timer(0.5, true).timeout
	await process_frame
	await RenderingServer.frame_post_draw
	var pixels: Image = root.get_texture().get_image()
	var path: String = capture_dir.path_join(stage + ".png")
	_expect(pixels.get_size() == Vector2i(540, 1170) and pixels.save_png(ProjectSettings.globalize_path(path)) == OK, "actual portrait image saved: " + stage)
	captures.append({"stage": stage, "path": path, "hero": str(hero.global_position), "native_focus": DisplayServer.window_is_focused()})


func _finish() -> void:
	if portrait and not capture_dir.is_empty():
		var metadata := FileAccess.open(capture_dir.path_join("evidence.json"), FileAccess.WRITE)
		metadata.store_string(JSON.stringify({"checks": checks, "failures": failures, "captures": captures, "scope": "scripted static lunar scenery and actual neutral floor routes; no encounters/fullL2/campaign progression/human/performance"}, "\t"))
		metadata.close()
	if is_instance_valid(game):
		game.queue_free()
	await process_frame
	print("A1-L2 LAYOUT GREYBOX: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
