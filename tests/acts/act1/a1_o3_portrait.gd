extends SceneTree
## Two brief actual rendered Main views. No campaign/gesture/playthrough claim.
## TEST Hero same-floor placement starts one real bell/guard cycle; no native
## packet, HP, phase, proof, camera or clock rewriting. Public pause barrier.

const MainScene = preload("res://scenes/main.tscn")
const Layout = preload("res://scripts/acts/act1/royal_rehearsal_layout.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const SIZE: Vector2i = Vector2i(540, 1170)
var game: Node
var level: CinderLevel
var hero: CinderPlayer
var scheduler: CinderThreatScheduler
var checks: Array[Dictionary] = []
var failures: int = 0
var shots: Array[Dictionary] = []
var setups: Array[Dictionary] = []
var admissions: Array[Dictionary] = []
var began: int
var finishing: bool = false
var complete: bool = false
var directory: String
var report_path: String
var previous_fps: int
var previous_audio: AudioBusLayout

func _initialize() -> void:
	began = Time.get_ticks_msec()
	previous_fps = Engine.max_fps; previous_audio = AudioServer.generate_bus_layout()
	report_path = "res://.cinder/a1-o3-portrait-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	directory = "res://.cinder/captures/o3-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	process_frame.connect(_watchdog)
	_run.call_deferred()

func _run() -> void:
	root.size = SIZE
	if not _expect(DisplayServer.get_name() != "headless", "actual graphical renderer required"): await _finish(); return
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) == OK, "unique portrait directory created"): await _finish(); return
	paused = true
	game = MainScene.instantiate(); game.set("level_scene_path", "res://scenes/acts/act1/a1_o3.tscn")
	root.add_child(game); paused = true
	await process_frame; await process_frame
	level = game.get("active_level") as CinderLevel; hero = game.get("player") as CinderPlayer
	if not _expect(level != null and hero != null and level.level_id == Layout.LEVEL_ID and level.hero == hero and level.shared_shell == game and level.contract_error().is_empty(), "actual O3 Main/shared Player loads"): await _finish(); return
	scheduler = level.get("scheduler") as CinderThreatScheduler
	level.connect("native_admission_published", func(id: String, answer: Dictionary) -> void: admissions.append({"source_id": id, "answer": _portable(answer)}))
	game.call("resume_lab")
	if not await _wait(func() -> bool: return not paused and hero.get_threat_response_state().stable, "actual floor settlement", 8.0): await _finish(); return
	if not await _pause(): await _finish(); return
	if not _expect(level.call("rehearsal_state").stage == "awaiting_bell" and scheduler.encounter_profile().is_empty(), "quiet entrance precedes every bell activation"): await _finish(); return
	if not await _capture("01-entrance"): await _finish(); return
	game.call("resume_lab")
	var contact: Vector3 = Layout.BELL_POSITION + Vector3(0, 0.005, 0)
	hero.global_position = contact; hero.velocity = Vector3.ZERO
	setups.append({"kind": "TEST same-floor Hero position and zero velocity", "position": _portable(contact), "scope": "No earned navigation or gesture credit"})
	if not await _wait(_live_warning, "actual bell contact and published native warning", 15.0): await _finish(); return
	if not await _pause(): await _finish(); return
	if not _expect(_live_warning() and level.call("rehearsal_state").exercise_index == 0, "representative first-pair original warning survives public pause"): await _finish(); return
	if not await _capture("02-first-warning"): await _finish(); return
	complete = true
	await _finish()

func _live_warning() -> bool:
	if admissions.is_empty() or not is_instance_valid(level): return false
	for id: String in Layout.group_ids(0):
		var actor: Act1MushroomSelenite = level.get("sources")[id]
		var state: Dictionary = actor.pure_presentation_state()
		if not state.reservation_id.is_empty() and state.phase == "warning": return true
	return false

func _pause() -> bool:
	if not _expect(game.call("request_pause_deferred") == true, "public deferred pause accepted"): return false
	return await _wait(func() -> bool: return paused and not game.call("is_pause_requested"), "completed public pause barrier", 8.0)

func _capture(label: String) -> bool:
	var points: Array = level.camera_framing_points()
	if not _expect(paused and not points.is_empty() and level.last_camera_framing_error.is_empty() and String(game.call("camera_framing_error", points)).is_empty(), label + ": actual required source/footprint/Hero/response union contained"): return false
	var before: String = _wire()
	if not _expect(not before.is_empty(), label + ": exact whole level/Player plus observed camera/input state captured"): return false
	var hud: GameHUD = game.get("hud")
	hud.hide_overlay()
	await RenderingServer.frame_post_draw
	var okay: bool = _expect(paused and _wire() == before, label + ": rendering with only pause overlay hidden preserves native state")
	var picture: Image = root.get_texture().get_image() if okay else null
	var path: String = directory.path_join(label + ".png")
	var saved: bool = picture != null and picture.get_size() == SIZE and picture.save_png(path) == OK
	hud.show_pause()
	if not _expect(saved and _wire() == before, label + ": actual540x1170 PNG written and native state unchanged"): return false
	var loaded: Image = Image.load_from_file(path)
	if not _expect(loaded != null and not loaded.is_empty() and loaded.get_size() == SIZE, label + ": saved PNG decodes at original dimensions"): return false
	shots.append({"label": label, "path": ProjectSettings.globalize_path(path), "sha256": FileAccess.get_sha256(path), "native_before_after": before, "focus_observed": DisplayServer.window_is_focused(root.get_window_id()), "only_pause_overlay_hidden": true, "optical_review": "pending personal inspection"})
	return true

func _wire() -> String:
	if not paused or not is_instance_valid(level) or not is_instance_valid(hero): return ""
	var local: Dictionary = level.snapshot_state()
	if local.is_empty(): return ""
	var camera: Camera3D = game.get("camera")
	return Exact.stringify(_portable({"level": local, "player": hero.snapshot_state(), "host": level.call("rehearsal_state"), "camera": {"frame": camera.global_transform, "size": camera.size, "framing": game.call("get_camera_framing_state")}, "input": game.call("get_input_observation_state"), "scheduler_clock": scheduler.get_clock()}))

func _wait(predicate: Callable, label: String, seconds: float) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000)
	while not finishing:
		if predicate.call() == true: return true
		if Time.get_ticks_msec() > deadline: return _expect(false, "bounded observation failed: " + label)
		if is_instance_valid(level) and not level.contract_error().is_empty(): return _expect(false, level.contract_error())
		await process_frame
	return false

func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - began > 60000:
		_expect(false, "portrait watchdog reached60s"); _finish.call_deferred()

func _expect(value: bool, label: String) -> bool:
	checks.append({"passed": value, "label": label, "elapsed_ms": Time.get_ticks_msec() - began})
	if value: print("PASS ", checks.size(), ": ", label)
	else: failures += 1; push_error(label)
	return value

func _portable(value: Variant) -> Variant:
	if value is Vector3: return Codec.vector3(value)
	if value is Vector2: return [value.x, value.y]
	if value is Rect2: return {"native_type": "Rect2", "position": _portable(value.position), "size": _portable(value.size)}
	if value is Basis: return {"x": _portable(value.x), "y": _portable(value.y), "z": _portable(value.z)}
	if value is Transform3D: return {"basis": _portable(value.basis), "origin": _portable(value.origin)}
	if value is StringName: return String(value)
	if value is Object: return {"native_class": value.get_class(), "instance_id": value.get_instance_id()} if is_instance_valid(value) else null
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _portable(value[key])
		return result
	if value is Array:
		var result: Array = []
		for child: Variant in value: result.append(_portable(child))
		return result
	return value

func _finish() -> void:
	if finishing: return
	finishing = true; paused = true
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(game):
		var fx := game.get("fx") as PixelEffects
		if is_instance_valid(fx): fx.clear()
		game.free()
	game = null; hero = null; level = null; scheduler = null
	paused = false
	await process_frame; await process_frame
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal disposal retires enemy and required cue groups")
	Engine.max_fps = previous_fps; AudioServer.set_bus_layout(previous_audio)
	var output := FileAccess.open(report_path, FileAccess.WRITE)
	if output == null: _expect(false, "portrait report writable")
	else:
		output.store_string(JSON.stringify({"complete": complete and failures == 0 and shots.size() == 2, "checks": checks.size(), "passes": checks.size() - failures, "failures": failures, "check_rows": checks, "shots": shots, "setups": setups, "admissions": admissions, "elapsed_ms": Time.get_ticks_msec() - began, "execution": {"native_args": Array(OS.get_cmdline_args()), "user_args": Array(OS.get_cmdline_user_args())}, "scope": "Two actual paused540x1170 production Main views, entrance and first live warning; real public pause barrier and same-floor TEST Hero placement. Native source/response/camera containment and full before-after snapshot retention. No campaign Continue, gesture, human playthrough, balance, all-kit/preset or performance claim. Images require personal visual review."}, "\t")); output.close()
	process_frame.disconnect(_watchdog)
	print("A1-O3 PORTRAIT: %d checks, %d failures, %d shots; report=%s" % [checks.size(), failures, shots.size(), report_path])
	quit(1 if failures > 0 else 0)
