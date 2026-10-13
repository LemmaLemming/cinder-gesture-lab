extends SceneTree
## GRAPHICAL actual accepted-scene opening profile, run only through dev.py.
## Native routed scripted input; no focus override, actor/state writes or saves.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const Settings: GDScript = preload("res://scripts/settings/game_settings.gd")
const Registry: GDScript = preload("res://scripts/campaign/registry.gd")
const WARMUP_S: float = 1.5
const SAMPLE_S: float = 8.0
const WATCHDOG_S: float = 180.0
const LEVEL_IDS: Array[String] = ["A1-L1", "A2-L1"]
const DEADLINES: Array[float] = [0.2, 0.7, 2.2, 2.7, 4.2, 4.7, 6.2, 6.7]

var _old_max_fps: int
var _old_audio_layout: AudioBusLayout
var _started_usec: int
var _output_path: String
var _metadata: Dictionary = {}
var _plan: Array[Dictionary] = []
var _cells: Array[Dictionary] = []
var _cell_index: int = -1
var _game: Node
var _actor: CinderPlayer
var _settings: CinderGameSettings
var _registry: CinderCampaignRegistry
var _registry_text: String
var _changing: bool = true
var _sampling: bool = false
var _finished: bool = false
var _cell_started_usec: int
var _sample_started_usec: int
var _last_render_usec: int
var _sample_actor_clock: float
var _sample_physics_frames: int
var _sample_drawn_frames: int
var _sample_hp: float
var _event_index: int
var _frame_ms := PackedFloat64Array()
var _monitors: Dictionary = {}
var _actions: Dictionary = {}
var _input_counts: Dictionary = {}
var _phase_counts: Dictionary = {}
var _stages: Array[Dictionary] = []
var _focus_samples: Array[Dictionary] = []
var _last_focus: Variant = null
var _errors: Array[String] = []
var _root_rid: RID
var _world_rid: RID
var _native_timing_supported: bool = false
var _settings_path: String = "user://test-campaign-desktop-profile/unused-settings.json"
var _settings_existed: bool
var _settings_before: PackedByteArray


func _initialize() -> void:
	_started_usec = Time.get_ticks_usec()
	_old_max_fps = Engine.max_fps
	_old_audio_layout = AudioServer.generate_bus_layout()
	_output_path = "res://.cinder/campaign-desktop-profile-%d-%d.json" % [OS.get_process_id(), _started_usec]
	var scripted: bool = false
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--scripted-background":
			scripted = true
		elif argument.begins_with("--profile-output="):
			_output_path = argument.trim_prefix("--profile-output=")
		elif argument.begins_with("--capture") or argument.begins_with("--level-scene") or argument == "--a2-art-preview":
			_finish("Capture/art/scene override flags would change the ordinary accepted-scene workload")
			return
	if not scripted or not _safe_output(_output_path):
		_finish("Explicit --scripted-background and an ignored res://.cinder/*.json output are required")
		return
	_ensure_uid()
	_setup.call_deferred()


func _setup() -> void:
	_metadata = {
		"engine": Engine.get_version_info(), "os": OS.get_name(),
		"cpu_name": OS.get_processor_name(), "logical_cpu_count": OS.get_processor_count(),
		"display_server": DisplayServer.get_name(), "rendering_method": RenderingServer.get_current_rendering_method(),
		"rendering_driver": RenderingServer.get_current_rendering_driver_name(), "video_adapter": RenderingServer.get_video_adapter_name(),
		"video_vendor": RenderingServer.get_video_adapter_vendor(), "video_api_version": RenderingServer.get_video_adapter_api_version(),
		"debug_build": OS.is_debug_build(), "physics_ticks_per_second": Engine.physics_ticks_per_second,
		"time_scale": Engine.time_scale, "vsync_mode": int(DisplayServer.window_get_vsync_mode()),
		"original_max_fps": _old_max_fps, "timestamp": Time.get_datetime_string_from_system(),
		"scope": "Explicit scripted background/possibly locked Mac; native focus sampled, lock state not inspected or changed",
		"native_timing_api_reference": "Godot4.6 RenderingServer; installed engine metadata and observed availability are authoritative",
	}
	if DisplayServer.get_name() == "headless" or paused:
		_finish("Graphical initially unpaused process required; headless or paused rendering is not an active measurement")
		return
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_registry_text = FileAccess.get_file_as_string(Registry.DATA_PATH)
	_registry = Registry.new()
	if not _registry.last_error.is_empty():
		_finish(_registry.last_error)
		return
	for level_id: String in LEVEL_IDS:
		if not _registry.is_playable(level_id) or not _registry.scene_error(level_id).is_empty():
			_finish("An opening profile requires its actual canonical accepted scene: " + level_id)
			return
		for quality: String in Settings.QUALITY_IDS:
			for cap: int in [30, 60]:
				_plan.append({"level_id": level_id, "quality": quality, "target_fps": cap, "reduced_motion": false})
	_settings_existed = FileAccess.file_exists(_settings_path)
	if _settings_existed:
		_settings_before = FileAccess.get_file_as_bytes(_settings_path)
	_settings = Settings.new(_settings_path)
	_native_timing_supported = RenderingServer.has_method("viewport_set_measure_render_time") and RenderingServer.has_method("viewport_get_measured_render_time_cpu") and RenderingServer.has_method("viewport_get_measured_render_time_gpu")
	RenderingServer.frame_post_draw.connect(_rendered_frame)
	physics_frame.connect(_physics_workload)
	create_timer(WATCHDOG_S, true).timeout.connect(func() -> void: _finish("180-second watchdog; incomplete cells are invalid"))
	_start_next_cell()


func _start_next_cell() -> void:
	if _finished:
		return
	_changing = true
	_sampling = false
	_cell_index += 1
	if _cell_index >= _plan.size():
		# The last real viewport must stay alive until _finish disables timing.
		_finish()
		return
	if is_instance_valid(_game):
		if _native_timing_supported and _world_rid.is_valid():
			RenderingServer.viewport_set_measure_render_time(_world_rid, false)
		_world_rid = RID()
		_game.active_level.exit_level()
		_game.fx.clear_lab()
		_game.free()
	_actor = null
	var preset: Dictionary = _plan[_cell_index]
	if not _settings.update({"quality": preset.quality, "target_fps": preset.target_fps, "reduced_motion": preset.reduced_motion}, false):
		_finish("Settings rejected an actual-scene benchmark preset")
		return
	_settings.apply_runtime()
	_game = MainScene.instantiate()
	_game.level_scene_path = _registry.entry(preset.level_id).scene_path
	root.add_child(_game)
	_actor = _game.player
	if not is_instance_valid(_actor) or not is_instance_valid(_game.active_level) or _game.active_level.level_id != preset.level_id or _game.active_level.scene_file_path != _registry.entry(preset.level_id).scene_path or not _game.level_load_error.is_empty():
		_finish("The unchanged shared Game did not load the exact accepted scene")
		return
	var world_viewport: SubViewport = _actor.get_viewport() as SubViewport
	if world_viewport == null or root.size != Vector2i(540, 1170) or world_viewport.size != Vector2i(270, 585) or (_game.get_child(0) as CanvasItem).texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_finish("Actual production portrait output/raster/filtering differs from the declared benchmark")
		return
	if not _game.fx.configure_policy(_settings.cosmetic_policy()):
		_finish("Actual shared effects rejected the canonical cosmetic policy")
		return
	_root_rid = root.get_viewport_rid()
	_world_rid = world_viewport.get_viewport_rid()
	if _native_timing_supported:
		RenderingServer.viewport_set_measure_render_time(_root_rid, true)
		RenderingServer.viewport_set_measure_render_time(_world_rid, true)
	_actions = {"dash": 0, "primary": 0, "blast": 0, "collision_shortened_dash": 0, "primary_hits": 0}
	_input_counts = {"swipe_release": 0, "primary_tap": 0, "blast_tap": 0}
	_actor.world_action_executed.connect(_executed)
	_game.input_observed.connect(_observed_input)
	_frame_ms = PackedFloat64Array()
	_monitors.clear()
	for key: String in ["process_ms", "physics_process_ms", "render_objects", "draw_calls", "physics_active_objects", "optional_chunks", "optional_flecks", "transients", "root_render_cpu_ms", "world_render_cpu_ms", "root_render_gpu_ms", "world_render_gpu_ms"]:
		_monitors[key] = PackedFloat64Array()
	_phase_counts.clear()
	_stages.clear()
	_focus_samples.clear()
	_last_focus = null
	_errors.clear()
	_event_index = 0
	_last_render_usec = 0
	# The only explicit unpause is the ordinary public initial resume. Normal
	# focus/application pause handlers remain active throughout warmup/sample.
	paused = true
	_game.resume_lab()
	_cell_started_usec = Time.get_ticks_usec()
	_changing = false
	_record_stage_and_focus()
	print("Campaign opening profile START %s %s/%d; native_focus=%s" % [preset.level_id, preset.quality, preset.target_fps, str(root.has_focus())])


func _rendered_frame() -> void:
	if _finished or _changing or not is_instance_valid(_actor):
		return
	var now: int = Time.get_ticks_usec()
	if not _live_cell_valid():
		_end_cell(float(now - _sample_started_usec) / 1000000.0 if _sampling else 0.0)
		_finish("Actual opening became paused/dead/invalid; no repeated unpause or manufactured workload")
		return
	_record_stage_and_focus()
	if not _sampling:
		if float(now - _cell_started_usec) / 1000000.0 < WARMUP_S:
			return
		_sampling = true
		_sample_started_usec = now
		_last_render_usec = now
		_sample_actor_clock = _actor.get_world_action_clock()
		_sample_physics_frames = Engine.get_physics_frames()
		_sample_drawn_frames = Engine.get_frames_drawn()
		_sample_hp = _actor.hp
		return
	_frame_ms.append(float(now - _last_render_usec) / 1000.0)
	_last_render_usec = now
	_monitor("process_ms", Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	_monitor("physics_process_ms", Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	_monitor("render_objects", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	_monitor("draw_calls", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_monitor("physics_active_objects", Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS))
	_monitor("optional_chunks", _game.fx.active_chunk_count())
	_monitor("optional_flecks", _game.fx.active_blood_count())
	_monitor("transients", _game.fx.active_transient_count())
	if _native_timing_supported:
		_monitor("root_render_cpu_ms", RenderingServer.viewport_get_measured_render_time_cpu(_root_rid))
		_monitor("world_render_cpu_ms", RenderingServer.viewport_get_measured_render_time_cpu(_world_rid))
		_monitor("root_render_gpu_ms", RenderingServer.viewport_get_measured_render_time_gpu(_root_rid))
		_monitor("world_render_gpu_ms", RenderingServer.viewport_get_measured_render_time_gpu(_world_rid))
	var elapsed: float = float(now - _sample_started_usec) / 1000000.0
	if elapsed >= SAMPLE_S:
		_end_cell(elapsed)
		if not _errors.is_empty():
			_finish("Opening workload validity failed; see the cell's exact reasons")
		else:
			_start_next_cell.call_deferred()


func _physics_workload() -> void:
	if _finished or _changing or not _sampling or not is_instance_valid(_actor) or paused or _actor.dead:
		return
	var age: float = _actor.get_world_action_clock() - _sample_actor_clock
	if _event_index >= DEADLINES.size() or age < DEADLINES[_event_index]:
		return
	var ordinal: int = floori(_event_index / 2.0)
	if _event_index % 2 == 0:
		var direction: Vector3 = Vector3.FORWARD if _plan[_cell_index].level_id == "A1-L1" else Vector3.RIGHT
		if ordinal % 2 == 1:
			direction = -direction
		_swipe(direction)
	else:
		var source: Node3D = _game.active_level.get_node_or_null("HallTarget" if _plan[_cell_index].level_id == "A1-L1" else "Scout_arrival") as Node3D
		var direction: Vector3 = Vector3.FORWARD
		if is_instance_valid(source):
			direction = source.global_position - _actor.global_position
			direction.y = 0.0
			if direction.length_squared() > 0.000001:
				direction = direction.normalized()
			else:
				direction = Vector3.FORWARD
		_tap(direction)
	_event_index += 1


func _screen_delta(direction: Vector3) -> Vector2:
	var right: Vector3 = _game.camera.global_basis.x
	var down: Vector3 = _game.camera.global_basis.z
	right.y = 0.0
	down.y = 0.0
	return Vector2(direction.dot(right.normalized()), direction.dot(down.normalized())).normalized()


func _swipe(direction: Vector3) -> void:
	var finish := Vector2(270.0, 640.0)
	var delta: Vector2 = _screen_delta(direction) * 160.0
	var start: Vector2 = finish - delta
	if not _input_safe(start) or not _input_safe(finish) or _game.screen_to_direction(delta).dot(direction) < 0.9999:
		_errors.append("Opening swipe cannot use the real bounded portrait recognizer")
		return
	var press := InputEventScreenTouch.new()
	press.index = 7
	press.pressed = true
	press.position = start
	root.push_input(press, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 7
	drag.position = finish
	drag.relative = delta
	root.push_input(drag, true)
	var release := InputEventScreenTouch.new()
	release.index = 7
	release.position = finish
	root.push_input(release, true)


func _tap(direction: Vector3) -> void:
	var position: Vector2 = _game.get_aim_anchor() + _screen_delta(direction) * 120.0
	if not _input_safe(position):
		_errors.append("Opening tap cannot use the real bounded portrait recognizer")
		return
	var press := InputEventScreenTouch.new()
	press.index = 8
	press.pressed = true
	press.position = position
	root.push_input(press, true)
	var release := InputEventScreenTouch.new()
	release.index = 8
	release.position = position
	root.push_input(release, true)


func _input_safe(point: Vector2) -> bool:
	return point.is_finite() and point.x >= 44.0 and point.x <= 496.0 and point.y >= 120.0 and point.y <= 950.0


func _executed(record: Dictionary) -> void:
	if not _sampling or _changing or _finished:
		return
	if _actions.has(record.kind):
		_actions[record.kind] += 1
	if record.kind == "dash" and record.get("collision_shortened", false):
		_actions.collision_shortened_dash += 1
	if record.kind == "primary":
		_actions.primary_hits += int(record.get("hits", 0))


func _observed_input(record: Dictionary) -> void:
	if _sampling and not _changing and not _finished and _input_counts.has(record.get("kind", "")):
		_input_counts[record.kind] += 1


func _live_cell_valid() -> bool:
	if paused:
		_errors.append("Normal shared app/focus/menu handling paused the actual tree")
	if _actor.dead:
		_errors.append("The real opening actor died")
	if not _game.level_load_error.is_empty() or _game.active_level.level_id != _plan[_cell_index].level_id:
		_errors.append("Actual accepted scene binding changed")
	if _game.active_level.get("runtime_error") is String and not _game.active_level.get("runtime_error").is_empty():
		_errors.append("Actual level runtime_error: " + _game.active_level.get("runtime_error"))
	if FileAccess.get_file_as_string(Registry.DATA_PATH) != _registry_text:
		_errors.append("Canonical registry changed during the measurement")
	if Engine.physics_ticks_per_second != _metadata.physics_ticks_per_second or Engine.time_scale != _metadata.time_scale or int(DisplayServer.window_get_vsync_mode()) != _metadata.vsync_mode:
		_errors.append("Normal physics/time scale/VSync changed")
	return _errors.is_empty()


func _record_stage_and_focus() -> void:
	var now_s: float = float(Time.get_ticks_usec() - _cell_started_usec) / 1000000.0
	var focused: bool = root.has_focus()
	if _last_focus == null or _last_focus != focused:
		_focus_samples.append({"cell_wall_s": now_s, "focused": focused, "sampling": _sampling})
		_last_focus = focused
	var stage: Dictionary = {"objective": _game.active_level.objective_text, "completed": _game.active_level.is_completed()}
	var phases: Dictionary = {}
	if _game.active_level.has_method("encounter_state"):
		var observed: Dictionary = _game.active_level.encounter_state()
		stage["beat"] = observed.get("beat", "")
		stage["route"] = observed.get("route", "")
		stage["active_ids"] = observed.get("active_ids", []).duplicate()
		stage["scheduler_clock_s"] = observed.get("clock_s", 0.0)
		for id: String in observed.get("exchanges", {}):
			var state: Dictionary = observed.exchanges[id]
			phases[id] = {"status": state.get("status", ""), "phase": state.get("phase", ""), "cycle": state.get("cycle", 0), "reservation_id": state.get("reservation_id", "")}
	else:
		stage["beat_index"] = _game.active_level.get("beat_index")
		for name: String in ["RoofLoadingArm", "BoardingLoadingArm"]:
			var source: Node = _game.active_level.get_node_or_null(name)
			if is_instance_valid(source) and source.has_method("state"):
				var state: Dictionary = source.state()
				phases[name] = {"phase": state.get("phase", ""), "cycle": state.get("cycle", 0)}
	var phase_key: String = JSON.stringify(phases)
	if _sampling:
		_phase_counts[phase_key] = int(_phase_counts.get(phase_key, 0)) + 1
	# The continuously advancing public scheduler clock is recorded at endpoints,
	# not used to manufacture a distinct stage on every rendered frame.
	var stage_identity: Dictionary = stage.duplicate(true)
	stage_identity.erase("scheduler_clock_s")
	if _stages.is_empty() or _stages[-1].identity != stage_identity:
		_stages.append({"cell_wall_s": now_s, "sampling": _sampling, "identity": stage_identity, "observed": stage})


func _monitor(key: String, value: float) -> void:
	var values: PackedFloat64Array = _monitors[key]
	values.append(value)
	_monitors[key] = values


func _end_cell(elapsed: float) -> void:
	if _changing:
		return
	var actor_seconds: float = _actor.get_world_action_clock() - _sample_actor_clock if _sampling else 0.0
	if not _sampling or elapsed < SAMPLE_S:
		_errors.append("The complete8-second sample was not observed")
	if _frame_ms.size() < 100:
		_errors.append("Insufficient actual graphical frame samples")
	if actor_seconds < elapsed * 0.85:
		_errors.append("Actual actor simulation did not advance alongside wall time")
	if _event_index != DEADLINES.size() or _actions.dash != 4 or _actions.primary != 4 or _actions.blast != 0 or _input_counts.swipe_release != 4 or _input_counts.primary_tap != 4:
		_errors.append("Four real routed completed dashes and four ordinary primaries were not observed exactly")
	var diagnostics: Dictionary = {}
	for key: String in _monitors:
		var values: PackedFloat64Array = _monitors[key]
		diagnostics[key] = _statistics(values)
		if key.contains("render_cpu") or key.contains("render_gpu"):
			diagnostics[key]["available"] = not values.is_empty() and float(diagnostics[key].max) > 0.0
			if not diagnostics[key].available:
				diagnostics[key]["unavailable_reason"] = "Native timing API unsupported or no positive native samples; zero is not zero rendering cost"
	if float(diagnostics.draw_calls.max) <= 0.0:
		_errors.append("No actual renderer draw calls; invalid graphical measurement")
	var entry: Dictionary = _registry.entry(_plan[_cell_index].level_id)
	var state_end: Dictionary = {}
	if _game.active_level.has_method("encounter_state"):
		var state: Dictionary = _game.active_level.encounter_state()
		state_end = {"beat": state.get("beat", ""), "route": state.get("route", ""), "active_ids": state.get("active_ids", []).duplicate(), "scheduler_clock_s": state.get("clock_s", 0.0), "runtime_error": state.get("runtime_error", "")}
	_cells.append({
		"level_id": entry.id, "scene_path": entry.scene_path, "accepted_commit": entry.accepted_commit,
		"quality": _plan[_cell_index].quality, "target_fps": _plan[_cell_index].target_fps, "reduced_motion": _plan[_cell_index].reduced_motion,
		"valid_actual_opening": _errors.is_empty(), "invalid_reasons": _errors.duplicate(),
		"wall_sample_seconds": elapsed, "actor_simulation_seconds": actor_seconds,
		"physics_frames": Engine.get_physics_frames() - _sample_physics_frames if _sampling else 0,
		"drawn_frames": Engine.get_frames_drawn() - _sample_drawn_frames if _sampling else 0,
		"frame_intervals_ms": _statistics(_frame_ms), "raw_frame_intervals_ms": Array(_frame_ms),
		"mean_fps": float(_frame_ms.size()) / elapsed if elapsed > 0.0 else 0.0,
		"diagnostics": diagnostics, "actions": _actions.duplicate(), "routed_inputs": _input_counts.duplicate(),
		"settings": _settings.snapshot(), "actual_fx_policy": _game.fx.policy_snapshot(),
		"hp_at_sample_start": _sample_hp, "hp_at_end": _actor.hp, "shells_at_end": _actor.shells,
		"position_at_end": [_actor.global_position.x, _actor.global_position.y, _actor.global_position.z],
		"stage_transitions": _stages.duplicate(true), "actual_threat_phase_frame_counts": _phase_counts.duplicate(), "encounter_at_end": state_end,
		"native_focus_transitions": _focus_samples.duplicate(true), "native_focus_at_end": root.has_focus(),
		"output_pixels": [root.size.x, root.size.y], "world_raster_pixels": [(_actor.get_viewport() as SubViewport).size.x, (_actor.get_viewport() as SubViewport).size.y], "tree_paused": paused,
	})
	print("Campaign opening profile %s %s/%d: %.2f FPS, p95 %.2f ms, valid=%s, actions=%s" % [entry.id, _plan[_cell_index].quality, _plan[_cell_index].target_fps, float(_frame_ms.size()) / elapsed if elapsed > 0.0 else 0.0, _statistics(_frame_ms).p95, str(_errors.is_empty()), str(_actions)])
	_sampling = false
	_changing = true


func _statistics(values: PackedFloat64Array) -> Dictionary:
	if values.is_empty():
		return {"samples": 0, "mean": 0.0, "p50": 0.0, "p95": 0.0, "max": 0.0}
	var sorted: PackedFloat64Array = values.duplicate()
	sorted.sort()
	var sum: float = 0.0
	for value: float in values:
		sum += value
	return {"samples": values.size(), "mean": sum / values.size(), "p50": sorted[maxi(ceili(values.size() * 0.50) - 1, 0)], "p95": sorted[maxi(ceili(values.size() * 0.95) - 1, 0)], "max": sorted[-1]}


func _finish(error: String = "") -> void:
	if _finished:
		return
	_finished = true
	_sampling = false
	if is_instance_valid(_game) and is_instance_valid(_game.fx):
		_game.fx.clear_lab()
	Engine.max_fps = _old_max_fps
	if _old_audio_layout != null:
		AudioServer.set_bus_layout(_old_audio_layout)
	if _native_timing_supported:
		if _root_rid.is_valid():
			RenderingServer.viewport_set_measure_render_time(_root_rid, false)
		if _world_rid.is_valid():
			RenderingServer.viewport_set_measure_render_time(_world_rid, false)
	var valid: bool = error.is_empty() and _cells.size() == 12
	for cell: Dictionary in _cells:
		valid = valid and cell.valid_actual_opening
	var untouched_settings: bool = FileAccess.file_exists(_settings_path) == _settings_existed and (not _settings_existed or FileAccess.get_file_as_bytes(_settings_path) == _settings_before)
	valid = valid and untouched_settings
	var report: Dictionary = {
		"schema_version": 1, "scope": "actual_accepted_A1_L1_A2_L1_scripted_openings_only",
		"complete_and_valid": valid, "error": error, "metadata": _metadata, "cells": _cells,
		"elapsed_total_seconds": float(Time.get_ticks_usec() - _started_usec) / 1000000.0,
		"warmup_seconds_per_cell": WARMUP_S, "sample_seconds_per_cell": SAMPLE_S,
		"restored_max_fps": Engine.max_fps, "audio_layout_restored": _old_audio_layout != null, "isolated_settings_file_unchanged": untouched_settings,
		"measurement": "Monotonic frame_post_draw wall intervals include cap/VSync/OS scheduling; not physical screen presentation latency. Native viewport timings, if positive/available, are separate engine render diagnostics.",
		"workload": "Unchanged Game and actual accepted authored scenes, starter four gear, normal physics/resources. Four alternating routed swipes at sample actor ages0.2/2.2/4.2/6.2; four aimed primary taps0.7/2.7/4.7/6.7. No blasts, staged encounters, actor/resource/clock mutation or extra artificial cosmetics.",
		"limits": ["Opening slices only; observed stage/threat phases are reported, not invented full encounter coverage", "Single fixed sequential quality/cap order, no confidence interval, thermal/sustained or release-build conclusion", "Native540x1170 output with actual production nearest270x585 world raster; GPU APIs may be unavailable", "Explicit unfocused/possibly locked Mac scripted scope; no focus grab/unlock/notification suppression/repeated unpause; actual focus observed, OS lock not inspected", "No production saves/settings, all24-level claim, human-input playtest, campaign fairness or mobile/export measurement", "Performance monitors may lag and engine times are not CPU utilization; zero/unavailable GPU timings do not prove zero GPU cost", "Source construction/1.5s warmup excluded; actual effects during8s sample included; no complete loading/first-use stutter measurement"],
	}
	if _safe_output(_output_path):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_path.get_base_dir()))
		var file := FileAccess.open(_output_path, FileAccess.WRITE)
		if file == null:
			push_error("Cannot write the ignored opening performance report")
			quit(2)
			return
		file.store_string(JSON.stringify(report, "\t", true, true))
		file.close()
		print("Campaign desktop profile JSON: " + ProjectSettings.globalize_path(_output_path))
	if not error.is_empty():
		push_error(error)
	quit(0 if valid else 1)


func _safe_output(path: String) -> bool:
	return path.begins_with("res://.cinder/") and path.ends_with(".json") and not path.contains("..") and not path.contains("\\")


func _ensure_uid() -> void:
	var path: String = "res://scripts/dev/campaign_desktop_profile.gd.uid"
	if not FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_line(ResourceUID.id_to_text(ResourceUID.create_id()))


func _finalize() -> void:
	Engine.max_fps = _old_max_fps
	if _old_audio_layout != null:
		AudioServer.set_bus_layout(_old_audio_layout)
