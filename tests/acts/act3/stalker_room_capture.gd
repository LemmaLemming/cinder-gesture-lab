extends SceneTree
## Actual GPU encounter views with routed Godot touches. This fixture does not
## operate native macOS input or accept final artwork/human encounter balance.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const ROOM: String = "res://scenes/acts/act3/a3_l1_stalker_room.tscn"
const OUTPUT: String = "res://captures/act3/stalker-room"
var _failed: bool = false
var _far_right_escape: bool = false
var _last_release: Vector2 = Vector2.ZERO


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_far_right_escape = OS.get_cmdline_user_args().has("--far-right-escape")
	for sun: int in [0, 1]:
		if OS.get_cmdline_user_args().has("--sun-one-only") and sun == 0:
			continue
		await _case(sun)
	print("Stalker room GPU study: %s; routed engine fixture, no native/human or final art acceptance" % ("failed" if _failed else "complete"))
	quit(1 if _failed else 0)


func _case(sun: int) -> void:
	var game: Node = MainScene.instantiate()
	game.set("level_scene_path", ROOM)
	root.add_child(game)
	await _ticks(game, 10)
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	var level: CinderLevel = game.get("active_level") as CinderLevel
	if hero == null or level == null:
		_fail("Shared room did not load")
		game.queue_free()
		await process_frame
		return
	hero.shells = 0
	var source: CharacterBody3D = level.get("stalker") as CharacterBody3D
	var scheduler: CinderThreatScheduler = level.get("threat_scheduler") as CinderThreatScheduler
	if source == null or scheduler == null:
		_fail("Real source/scheduler missing")
		game.queue_free()
		await process_frame
		return
	if sun == 1:
		paused = true
		await process_frame
		var snapshot: Dictionary = level.snapshot_state()
		if snapshot.is_empty():
			_fail("Configured sun study capture failed: " + level.last_snapshot_error)
		else:
			snapshot["local"]["scenery"]["sun_state"] = 1
			if not level.restore_state(snapshot):
				_fail("Configured sun study restore failed: " + level.last_snapshot_error)
		game.call("resume_lab")
	if OS.get_cmdline_user_args().has("--source-still-only"):
		# Real source/scenery/routed-input study while the grounded-lunge
		# dependency is being repaired. These views contain no accepted attack,
		# locked cue, primary opening or gameplay/art acceptance claim.
		await _ticks(game, 1)
		print("SOURCE STILL sun%d: body=%s art=%s" % [sun, source.global_position, source.call("get_art_state")])
		var view_camera: Camera3D = game.get("camera") as Camera3D
		for sun_name: String in ["Branchspell", "Alppain"]:
			var sun_node: MeshInstance3D = level.find_child(sun_name, true, false) as MeshInstance3D
			print("SUN FRAMING %s: world=%s screen=%s" % [sun_name, sun_node.global_position, view_camera.unproject_position(sun_node.global_position)])
		await _save("sun%d-source-idle.png" % sun)
		var before_x: float = hero.global_position.x
		await _swipe(game, 1.0)
		await _ticks(game, 14)
		if hero.global_position.x <= before_x + 0.1:
			_fail("Routed right swipe did not move the actual source-study hero")
		await _save("sun%d-source-lateral.png" % sun)
		print("SOURCE LATERAL sun%d: hero=%s source=%s art=%s actual records=%s" % [sun, hero.global_position, source.global_position, source.call("get_art_state"), hero.get_world_action_records()])
		game.queue_free()
		paused = false
		await process_frame
		await process_frame
		return
	var deadline: float = scheduler.get_clock() + 3.0
	while String(source.call("state").get("reservation_id", "")).is_empty() and scheduler.get_clock() < deadline:
		await _ticks(game, 1)
	var state: Dictionary = source.call("state")
	var id: String = state.get("reservation_id", "")
	var record: Dictionary = scheduler.reservation_state(id)
	if record.is_empty():
		_fail("No accepted real lunge: " + str(state))
		game.queue_free()
		await process_frame
		return
	print("GPU CASE sun%d: actual traveller=%s source=%s reservation=%s proof=%s" % [sun, hero.presentation_id, source.global_position, record, state.get("proof", {})])
	var escape_side: float = 1.0 if sun == 0 or _far_right_escape else -1.0
	_assert_view(game, level, source, id, "warning")
	await _save("sun%d-warning.png" % sun)
	while scheduler.get_clock() < float(record["lock_from_s"]) + 0.025:
		await _ticks(game, 1)
	_assert_view(game, level, source, id, "lock")
	await _save("sun%d-lock.png" % sun)
	await _swipe(game, escape_side)
	while scheduler.get_clock() < float(record["active_from_s"]) + 0.12:
		await _ticks(game, 1)
	_assert_view(game, level, source, id, "active")
	if source.global_position.distance_to(record.adapter.start) <= 0.1:
		_fail("The active portrait must show genuine native source travel")
	if game.call("get_aim_anchor") != _last_release:
		_fail("Camera translation changed the held final swipe-release aim anchor")
	await _save("sun%d-moving-active.png" % sun)
	while scheduler.get_clock() <= float(record["active_until_s"]) + 0.025:
		await _ticks(game, 1)
	_assert_view(game, level, source, id, "recovery")
	await _save("sun%d-recovery-side.png" % sun)
	await _swipe(game, -escape_side)
	await _ticks(game, 14)
	_assert_view(game, level, source, id, "recovery")
	await _save("sun%d-recovery-return.png" % sun)
	var before: float = float(source.call("state")["hp"])
	var toward: Vector3 = source.global_position - hero.global_position
	toward.y = 0.0
	toward = toward.normalized()
	var camera: Camera3D = game.get("camera") as Camera3D
	var right: Vector3 = camera.global_basis.x
	right.y = 0.0
	var down: Vector3 = camera.global_basis.z
	down.y = 0.0
	var delta_screen := Vector2(toward.dot(right.normalized()), toward.dot(down.normalized())) * 70.0
	var tap: Vector2 = game.call("get_aim_anchor") + delta_screen
	await _tap(game, tap)
	await _ticks(game, 2)
	if float(source.call("state")["hp"]) >= before:
		_fail("Routed ordinary primary failed to hit the actual recovery body in sun%d" % sun)
	if hero.hp != hero.max_hp:
		_fail("The routed escape must retain full actual hero HP")
	await _save("sun%d-primary-hit.png" % sun)
	print("GPU CASE sun%d: HP %s->%s; heroHP=%s shells=%s; real executed records=%s" % [sun, before, source.call("state")["hp"], hero.hp, hero.shells, hero.get_world_action_records()])
	game.queue_free()
	paused = false
	await process_frame
	await process_frame


func _ticks(game: Node, count: int) -> void:
	for _index: int in range(count):
		if paused:
			game.call("resume_lab")
		await physics_frame
		await process_frame


func _swipe(game: Node, side: float) -> void:
	var size: Vector2 = root.get_visible_rect().size
	var start: Vector2 = size * Vector2(0.5, 0.56)
	var finish: Vector2 = start + Vector2(side * size.x * 0.22, 0.0)
	var touch := InputEventScreenTouch.new()
	touch.index = 41
	touch.position = start
	touch.pressed = true
	root.push_input(touch, true)
	await _ticks(game, 1)
	var drag := InputEventScreenDrag.new()
	drag.index = 41
	drag.position = finish
	drag.relative = finish - start
	root.push_input(drag, true)
	touch = InputEventScreenTouch.new()
	touch.index = 41
	touch.position = finish
	touch.pressed = false
	root.push_input(touch, true)
	_last_release = finish
	await _ticks(game, 1)


func _tap(game: Node, point: Vector2) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 42
	touch.position = point
	touch.pressed = true
	root.push_input(touch, true)
	await _ticks(game, 1)
	touch = InputEventScreenTouch.new()
	touch.index = 42
	touch.position = point
	touch.pressed = false
	root.push_input(touch, true)


func _save(name: String) -> void:
	var previously_paused: bool = paused
	paused = true
	await RenderingServer.frame_post_draw
	var destination: String = OUTPUT.path_join("shared18-far-right") if _far_right_escape else OUTPUT
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination))
	var rendered: Image = root.get_texture().get_image()
	if rendered == null or rendered.is_empty() or rendered.save_png(destination.path_join(name)) != OK:
		_fail("Could not save actual GPU view: " + name)
	else:
		print("STALKER GPU CAPTURE: ", ProjectSettings.globalize_path(destination.path_join(name)))
	paused = previously_paused


func _assert_view(game: Node, level: CinderLevel, source: CharacterBody3D, reservation_id: String, phase: String) -> void:
	if not _far_right_escape:
		return
	var state: Dictionary = source.call("state")
	if String(state.get("reservation_id", "")) != reservation_id or String(state.get("phase", "")) != phase:
		_fail("Actual far-side %s lost its original lease/phase: %s" % [phase, state.get("last_cancel_reason", "")])
		return
	var points: Array = level.camera_framing_points()
	if points.is_empty() or not level.last_camera_framing_error.is_empty():
		_fail("Actual far-side %s has no complete valid level framing: %s" % [phase, level.last_camera_framing_error])
		return
	var current_error: String = game.call("camera_framing_error", points)
	if not current_error.is_empty():
		_fail("Actual far-side %s current protected view failed: %s" % [phase, current_error])
	print("FAR-SIDE VIEW %s: corners=%d current_error=%s source=%s hero=%s width=%s" % [phase, points.size(), current_error, source.global_position, (game.get("player") as CinderPlayer).global_position, (game.get("camera") as Camera3D).size])


func _fail(message: String) -> void:
	_failed = true
	push_error(message)
