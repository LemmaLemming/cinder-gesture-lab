extends SceneTree
## Queued GRAPHICAL scripted shared fixture. Not authored campaign, native
## gesture testing, GPU presentation latency, thermal testing or device proof.
## Run only through scripts/dev/dev.py engine (without --headless).
const PlayerScene = preload("res://scenes/player.tscn")
const Effects = preload("res://scripts/effects.gd")
const Settings = preload("res://scripts/settings/game_settings.gd")
const Game = preload("res://scripts/game.gd")
const WARMUP_S: float = 0.7
const SAMPLE_S: float = 2.3
const WATCHDOG_S: float = 25.0
const ACTOR_PRESENTATION: String = "act2_survivor"

var _old_max_fps: int
var _started_usec: int
var _cell_started_usec: int
var _sample_started_usec: int
var _last_render_usec: int = 0
var _sample_actor_clock: float
var _sample_physics_frames: int
var _sample_render_frames: int
var _sampling: bool = false
var _changing: bool = true
var _finished: bool = false
var _cell_index: int = -1
var _event_index: int = 0
var _next_decoration_s: float = 0.2
var _world: Node3D
var _camera: Camera3D
var _focus := Vector3.ZERO
var _viewport: SubViewport
var _actor: CinderPlayer
var _fx: PixelEffects
var _settings: CinderGameSettings
var _label: Label
var _frame_ms := PackedFloat64Array()
var _monitor_samples: Dictionary = {}
var _actions: Dictionary = {}
var _cell_errors: Array[String] = []
var _cells: Array[Dictionary] = []
var _plan: Array[Dictionary] = []
var _output_path: String
var _metadata: Dictionary

func _initialize() -> void:
	_old_max_fps = Engine.max_fps
	_started_usec = Time.get_ticks_usec()
	var stamp: String = Time.get_datetime_string_from_system().replace(":", "-")
	_output_path = "res://.cinder/desktop-profile-%s-%d.json" % [stamp, OS.get_process_id()]
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--profile-output="):
			var requested: String = argument.trim_prefix("--profile-output=")
			if not requested.begins_with("res://.cinder/") or not requested.ends_with(".json") or requested.contains("..") or requested.contains("\\"):
				push_error("Profile output must be an ignored res://.cinder/*.json path")
				quit(2)
				return
			_output_path = requested
	_setup.call_deferred()

func _setup() -> void:
	_metadata = {
		"engine": Engine.get_version_info(), "os": OS.get_name(),
		"cpu_name": OS.get_processor_name(), "logical_cpu_count": OS.get_processor_count(),
		"display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"rendering_driver": RenderingServer.get_current_rendering_driver_name(),
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"video_vendor": RenderingServer.get_video_adapter_vendor(),
		"video_api_version": RenderingServer.get_video_adapter_api_version(),
		"debug_build": OS.is_debug_build(), "physics_ticks_per_second": Engine.physics_ticks_per_second,
		"time_scale": Engine.time_scale, "vsync_mode": int(DisplayServer.window_get_vsync_mode()),
		"original_max_fps": _old_max_fps, "timestamp": Time.get_datetime_string_from_system(),
		"docs_api_reference": "Godot4.6 official Performance/RenderingServer/Engine/OS APIs; actual engine version above is authoritative",
	}
	if DisplayServer.get_name() == "headless" or paused:
		_finish("Graphical unpaused fixture required; no active-performance claim from headless/paused execution")
		return
	root.size = Vector2i(540, 1170)
	_build_world()
	_settings = Settings.new("user://test-desktop-profile/unused-settings.json")
	for quality: String in Settings.QUALITY_IDS:
		for cap: int in [30, 60]:
			_plan.append({"quality": quality, "target_fps": cap})
	RenderingServer.frame_post_draw.connect(_rendered_frame)
	physics_frame.connect(_physics_workload)
	create_timer(WATCHDOG_S).timeout.connect(func() -> void: _finish("25 second watchdog: incomplete cells are not accepted measurements"))
	_start_next_cell()

func _build_world() -> void:
	var container := SubViewportContainer.new()
	root.add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.stretch_shrink = 2
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(270, 585)
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.handle_input_locally = false
	container.add_child(_viewport)
	_world = Node3D.new()
	_world.name = "ScriptedSharedDesktopProfile"
	_viewport.add_child(_world)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.04, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.76, 0.78, 0.80)
	env.ambient_light_energy = 0.7
	environment.environment = env
	_world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -25, 0)
	light.light_color = Color(0.96, 0.98, 1.0)
	light.light_energy = 1.0
	_world.add_child(light)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.keep_aspect = Camera3D.KEEP_WIDTH
	_camera.size = 7.2
	_world.add_child(_camera)
	_camera.position = Game.CAMERA_OFFSET
	_camera.look_at(Vector3.ZERO)
	_camera.current = true
	_box(Vector3(0, -0.5, 0), Vector3(24, 1, 24), Color("50545a"))
	_box(Vector3(1.4, 0.7, 0), Vector3(0.25, 1.4, 1.2), Color("777e85"))
	_box(Vector3(-2.2, 0.3, -2.2), Vector3(0.6, 0.6, 0.6), Color("69716e"))
	var canvas := CanvasLayer.new()
	root.add_child(canvas)
	_label = Label.new()
	_label.position = Vector2(16, 16)
	_label.add_theme_font_size_override("font_size", 18)
	canvas.add_child(_label)

func _box(position: Vector3, size: Vector3, colour: Color) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	_world.add_child(body)
	body.position = position
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var mesh := BoxMesh.new()
	mesh.size = size
	var display := MeshInstance3D.new()
	display.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1.0
	display.material_override = material
	body.add_child(display)

func _start_next_cell() -> void:
	if _finished:
		return
	if is_instance_valid(_fx):
		_fx.clear()
		_fx.free()
	if is_instance_valid(_actor):
		_actor.free()
	_cell_index += 1
	if _cell_index >= _plan.size():
		_finish()
		return
	var preset: Dictionary = _plan[_cell_index]
	if not _settings.update({"quality": preset.quality, "target_fps": preset.target_fps, "reduced_motion": false}, false):
		_finish("Settings rejected benchmark preset")
		return
	_settings.apply_runtime()
	_fx = Effects.new()
	_world.add_child(_fx)
	if not _fx.configure_policy(_settings.cosmetic_policy()):
		_finish("Effects rejected canonical settings policy")
		return
	_actor = PlayerScene.instantiate()
	_actor.set_presentation(ACTOR_PRESENTATION)
	_world.add_child(_actor)
	_actor.position = Vector3(0, 0.02, 0)
	_actor.fx = _fx
	_actor.world_action_executed.connect(_executed)
	_focus = _actor.global_position + Vector3.UP * 0.75
	_camera.position = _focus + Game.CAMERA_OFFSET
	# Warm the required materials without spending actor ammo or changing clocks.
	_fx.slash(Vector3(0, 0.65, 0), Vector3.RIGHT, Color("f0ddd1"))
	_fx.muzzle(Vector3(0, 0.65, 0), Vector3.RIGHT)
	_fx.dash_trail(Vector3.ZERO, Vector3.RIGHT)
	_fx.optional_decoration_smoke(Vector3(-1, 0.05, -1), Vector3.LEFT)
	_frame_ms = PackedFloat64Array()
	_monitor_samples = {}
	for key: String in ["process_ms", "physics_process_ms", "render_objects", "draw_calls", "physics_active_objects", "optional_chunks", "optional_flecks", "transients"]:
		_monitor_samples[key] = PackedFloat64Array()
	_actions = {"dash": 0, "primary": 0, "blast": 0, "collision_shortened_dash": 0, "impact_emissions": 0, "decoration_attempts": 0}
	_cell_errors.clear()
	_sampling = false
	_changing = false
	_event_index = 0
	_next_decoration_s = 0.2
	_last_render_usec = 0
	_cell_started_usec = Time.get_ticks_usec()
	_label.text = "SCRIPTED SHARED FIXTURE\n%s · %d FPS · warming\nNo authored campaign/input acceptance" % [preset.quality, preset.target_fps]

func _rendered_frame() -> void:
	if _finished or _changing:
		return
	var now: int = Time.get_ticks_usec()
	if paused:
		_finish("Tree paused during fixture; render-only frames are not active gameplay measurements")
		return
	if not _sampling:
		if float(now - _cell_started_usec) / 1000000.0 < WARMUP_S:
			return
		_sampling = true
		_sample_started_usec = now
		_sample_actor_clock = _actor.get_world_action_clock()
		_sample_physics_frames = Engine.get_physics_frames()
		_sample_render_frames = Engine.get_frames_drawn()
		_last_render_usec = now
		_label.text = "SCRIPTED SHARED FIXTURE\n%s · %d FPS · sampling\nNo authored campaign/input acceptance" % [_plan[_cell_index].quality, _plan[_cell_index].target_fps]
		return
	_frame_ms.append(float(now - _last_render_usec) / 1000.0)
	_last_render_usec = now
	_monitor("process_ms", Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	_monitor("physics_process_ms", Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	_monitor("render_objects", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	_monitor("draw_calls", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_monitor("physics_active_objects", Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS))
	_monitor("optional_chunks", _fx.active_chunk_count())
	_monitor("optional_flecks", _fx.active_blood_count())
	_monitor("transients", _fx.active_transient_count())
	var elapsed: float = float(now - _sample_started_usec) / 1000000.0
	if elapsed >= SAMPLE_S:
		_end_cell(elapsed)

func _physics_workload() -> void:
	if _finished or _changing or not is_instance_valid(_actor) or paused:
		return
	var dt: float = 1.0 / float(Engine.physics_ticks_per_second)
	_focus = _focus.lerp(_actor.global_position + Vector3.UP * 0.75, 1.0 - exp(-dt / Game.CAMERA_FOLLOW_TIME_S))
	_camera.global_position = _focus + Game.CAMERA_OFFSET
	if not _sampling:
		return
	var age: float = _actor.get_world_action_clock() - _sample_actor_clock
	var deadlines: Array[float] = [0.1, 0.4, 0.7, 1.1, 1.4, 1.7, 2.1, 2.2]
	while _event_index < deadlines.size() and age >= deadlines[_event_index]:
		match _event_index:
			0, 6: _actor.request_dash(Vector3.RIGHT)
			3: _actor.request_dash(Vector3.LEFT)
			1, 4, 7: _actor.slash(Vector3.FORWARD)
			2, 5:
				_actor.blast(Vector3.FORWARD)
				_fx.burst(_actor.global_position + Vector3.FORWARD, Color("adb5bc"), 24)
				_fx.tiny_bleed(_actor.global_position + Vector3.FORWARD, 5)
				_actions.impact_emissions += 1
		_event_index += 1
	if age >= _next_decoration_s:
		_fx.optional_decoration_smoke(_actor.global_position + Vector3(-0.8, 0.04, -1.2), Vector3.LEFT)
		_actions.decoration_attempts += 1
		_next_decoration_s += 0.2

func _executed(record: Dictionary) -> void:
	if not _sampling or _changing:
		return
	if _actions.has(record.kind):
		_actions[record.kind] += 1
	if record.kind == "dash" and record.get("collision_shortened") == true:
		_actions.collision_shortened_dash += 1

func _monitor(key: String, value: float) -> void:
	var values: PackedFloat64Array = _monitor_samples[key]
	values.append(value)
	_monitor_samples[key] = values

func _end_cell(elapsed: float) -> void:
	var actor_seconds: float = _actor.get_world_action_clock() - _sample_actor_clock
	var physics_frames: int = Engine.get_physics_frames() - _sample_physics_frames
	var rendered_frames: int = Engine.get_frames_drawn() - _sample_render_frames
	if _frame_ms.size() < 15 or rendered_frames < 15:
		_cell_errors.append("Insufficient rendered samples")
	if actor_seconds < elapsed * 0.85:
		_cell_errors.append("Actor simulation did not advance alongside wall time")
	if int(_actions.dash) < 2 or int(_actions.primary) < 2 or int(_actions.blast) != 2:
		_cell_errors.append("Required repeated real actor workload did not execute")
	var diagnostics: Dictionary = {}
	for key: String in _monitor_samples:
		diagnostics[key] = _statistics(_monitor_samples[key])
	if float(diagnostics.draw_calls.max) <= 0.0:
		_cell_errors.append("Renderer reported no draw calls; no active graphical-performance claim")
	_cells.append({
		"quality": _plan[_cell_index].quality, "target_fps": _plan[_cell_index].target_fps,
		"valid_active_scripted_fixture": _cell_errors.is_empty(), "invalid_reasons": _cell_errors.duplicate(),
		"wall_sample_seconds": elapsed, "actor_simulation_seconds": actor_seconds,
		"physics_frames": physics_frames, "rendered_frames": rendered_frames,
		"frame_intervals_ms": _statistics(_frame_ms),
		"mean_fps": float(_frame_ms.size()) / elapsed,
		"raw_frame_intervals_ms": Array(_frame_ms), "diagnostic_monitors": diagnostics,
		"actions": _actions.duplicate(true), "policy": _fx.policy_snapshot(),
		"window_focused_at_end": root.has_focus(), "window_size": [root.size.x, root.size.y],
		"raster_size": [_viewport.size.x, _viewport.size.y], "tree_paused": paused,
	})
	print("Desktop scripted profile %s/%d: %.2f FPS, p95 %.2f ms, valid=%s" % [_plan[_cell_index].quality, _plan[_cell_index].target_fps, float(_frame_ms.size()) / elapsed, _statistics(_frame_ms).p95, str(_cell_errors.is_empty())])
	_sampling = false
	_changing = true
	_start_next_cell.call_deferred()

func _statistics(values: PackedFloat64Array) -> Dictionary:
	if values.is_empty():
		return {"samples": 0, "mean": 0.0, "p50": 0.0, "p95": 0.0, "max": 0.0}
	var sorted: PackedFloat64Array = values.duplicate()
	sorted.sort()
	var total: float = 0.0
	for value: float in values:
		total += value
	return {"samples": values.size(), "mean": total / values.size(), "p50": sorted[maxi(ceili(values.size() * 0.50) - 1, 0)], "p95": sorted[maxi(ceili(values.size() * 0.95) - 1, 0)], "max": sorted[-1]}

func _finish(error: String = "") -> void:
	if _finished:
		return
	_finished = true
	_sampling = false
	Engine.max_fps = _old_max_fps
	if is_instance_valid(_fx):
		_fx.clear()
	var valid: bool = error.is_empty() and _cells.size() == 6
	for cell: Dictionary in _cells:
		valid = valid and cell.valid_active_scripted_fixture
	var report: Dictionary = {
		"schema_version": 1, "scope": "scripted_shared_desktop_fixture_only",
		"complete_and_valid": valid, "error": error, "metadata": _metadata,
		"elapsed_total_seconds": float(Time.get_ticks_usec() - _started_usec) / 1000000.0,
		"warmup_seconds_per_cell": WARMUP_S, "sample_seconds_per_cell": SAMPLE_S,
		"measurement": "Monotonic wall intervals between RenderingServer.frame_post_draw signals, including cap/VSync/OS scheduling; not GPU duration or physical screen presentation latency. Nearest-rank p50/p95. Mean FPS is interval count / sampled wall time.",
		"counter_limits": "Performance monitors are diagnostics, may lag by up to1second or be unavailable; process/physics timings are engine frame timings, not measured CPU utilization or GPU costs. Draw calls are observed engine counts. No VSync override or manual force_draw/readback.",
		"fixture": {"output_pixels": [540, 1170], "world_raster_pixels": [270, 585], "nearest_filter": true, "camera": "Shared orthographic7.2 KEEP_WIDTH; offset(0,18,13), fixed angle, exponential0.16s follow", "presentation": ACTOR_PRESENTATION, "equipment": "canonical starter four", "scene": "Original plain floor plus two static boxes; no accepted authored campaign scene", "schedule": "Public simulation-clock dash0.1/1.1/2.1; primary0.4/1.4/2.2; blast0.7/1.7; optional24-piece impacts+5flecks at blasts, decoration attempts every0.2s. Fresh actor per cell; no ammo refresh during sampling.", "focus": "Standalone fixture has no shell/app-focus pause callback; no native gestures injected, no macOS lock/UI bypass. Paused/nonadvancing simulation invalidates the run."},
		"limitations": ["Single short run with fixed sequential order; no confidence interval, thermal or sustained-load conclusion", "Startup/source construction and warmup excluded; effects created during sampled actions remain included; no loading or complete first-use-stutter measurement", "Frame caps/VSync and locked/background OS scheduling may dominate; window focus recorded", "No campaign fairness, authored scenery/enemy/scheduler/menu/save workload or all24-level measurement", "No human input, mobile, physical-device or release-build performance claim"],
		"cells": _cells, "restored_max_fps": Engine.max_fps,
	}
	var directory: String = ProjectSettings.globalize_path(_output_path.get_base_dir())
	DirAccess.make_dir_recursive_absolute(directory)
	var file: FileAccess = FileAccess.open(_output_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write ignored profile JSON: " + _output_path)
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t", true, true))
	file.close()
	print("Desktop profile JSON: " + ProjectSettings.globalize_path(_output_path))
	if not error.is_empty():
		push_error(error)
	quit(0 if valid else 1)

func _finalize() -> void:
	Engine.max_fps = _old_max_fps
