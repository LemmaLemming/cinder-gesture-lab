extends "res://tests/acts/act3/false_paradise_codec_entry_smoke.gd"
## TEST ONLY brief affected actual portrait; inherits normal cleanup helpers.
## Genuine first court; public Resume then disclosed render freeze without a tick.
## No late state, route clear, Sun clock manipulation or optical gameplay stamp.

func _run() -> void:
	_game = Main.instantiate()
	root.add_child(_game)
	_game.call("open_bench")
	if not _expect(paused and _game.call("load_level_scene", ROOM), "public actual garden loads for affected portrait"):
		await _finish()
		return
	_game.call("open_bench")
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	for _i: int in range(5): await process_frame
	if not _expect(_level != null and _hero != null and String(_level.call("runtime_error")).is_empty(), "actual new scenery and hidden two-sun consumer configure", String(_level.call("runtime_error"))):
		await _finish()
		return
	_game.call("resume_lab")
	var entered: bool = false
	for _i: int in range(90):
		await physics_frame
		if paused: break
		if int(_level.call("seen_entry", "offered-rest")) >= 0:
			entered = true
			break
	if not _expect(entered and not paused and not _hero.dead, "actual grounded first court is present"):
		await _finish()
		return
	if not _expect(_game.call("request_pause_deferred"), "real deferred pause precedes affected portrait"):
		await _finish()
		return
	for _i: int in range(5): await process_frame
	if not _expect(paused and not _game.call("is_pause_requested") and _positive(_pair()), "actual whole native pair settles before render freeze", _positive_error):
		await _finish()
		return
	_game.call("resume_lab")
	if not _expect(not paused, "public Resume clears the actual overlay"):
		await _finish()
		return
	paused = true # TEST ONLY cosmetic render freeze, no intervening physics.
	var before: String = Exact.stringify(_pair())
	var camera: Camera3D = _hero.get_viewport().get_camera_3d()
	var camera_before: Transform3D = camera.global_transform
	var input_before: Dictionary = _game.call("get_input_observation_state")
	var sun: Node3D = _level.get("sun_art") as Node3D
	var sun_before: Dictionary = _level.call("sun_presentation_state")
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var folder: String = ProjectSettings.globalize_path("res://.cinder/a3-l4-art-entry-portrait-output")
	var path: String = folder.path_join("offered-rest.png")
	var same: bool = Exact.stringify(_pair()) == before and camera.global_transform == camera_before and input_before == _game.call("get_input_observation_state") and sun_before == _level.call("sun_presentation_state") and String(sun.call("runtime_error")).is_empty()
	var ok: bool = image != null and image.get_size() == Vector2i(339, 736) and same and DirAccess.make_dir_recursive_absolute(folder) == OK and image.save_png(path) == OK
	_expect(ok, "actual339x736 affected portrait retains the native pair/input/camera and hidden suns", "size=" + str(image.get_size()) if image != null else "no image")
	if ok: print("PORTRAIT: " + path)
	await _finish()

func _finish() -> void:
	if is_instance_valid(_game):
		var refs: Array[WeakRef] = []
		_refs(_game, refs)
		if is_instance_valid(_level): _level.exit_level()
		_game.queue_free()
		paused = false
		for _i: int in range(5): await process_frame
		var released: bool = true
		for ref: WeakRef in refs: released = released and ref.get_ref() == null
		_expect(released and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal whole Main/native sources/cues dispose completely")
	await create_timer(0.15, true, false, true).timeout
	print("False Paradise affected art entry: %d checks; failures: %d. Actual first-court paused portrait and cleanup; no later sun/encounter/full-route or acceptance claim." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
