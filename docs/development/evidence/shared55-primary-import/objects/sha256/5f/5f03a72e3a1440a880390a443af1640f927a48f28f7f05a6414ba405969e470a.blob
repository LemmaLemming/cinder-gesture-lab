extends "res://tests/acts/act3/garden_mixed_component_smoke.gd"
## TEST ONLY graphical derivative: one unchanged actual root branch.
## Captures attach after the real public roundtrip labels; no repeated exchanges.
## Actual Sun16 corners/current Camera plus whole pair/input/events freeze.
## Public Resume clears the overlay, then a disclosed no-tick render freeze.
## No source/Player/HP/pose/clock/camera write or canonical late-route/art claim.

const PORTRAIT_FOLDER: String = "res://.cinder/a3-l4-mixed-root-portrait-placement-output"
const PORTRAIT_LABELS: Dictionary = {
	"held-phase2-Enclose": "01-held-phase2-enclose.png",
	"settled-native-release": "02-settled-native-release.png",
}
var _captured_labels: Dictionary = {}
var _draw_seen: bool = false


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not _expect(args.is_empty() or (args.size() == 1 and args[0] == "--root-only"), "graphical derivative supports only its one living-helper root branch", str(args)):
		await _finish()
		return
	if not _expect(DisplayServer.get_name() != "headless", "root portraits require actual graphical rendering"):
		await _finish()
		return
	# Same declared native root-cell program as the tested --root-only branch.
	# Only test selector state changes; no Player/source/earned-state seed.
	_root_only = true
	_pair_only = false
	_echo_only = false
	_helper_dead_branch = false
	_canonical_registry = FileAccess.get_file_as_string(CampaignRegistry.DATA_PATH)
	if not node_added.is_connected(_watch_mixed_node): node_added.connect(_watch_mixed_node)
	if await _open_cell(ROOT_CELL): await _root_component()
	await _finish()


func _roundtrip_and_abort(label: String, abort: bool) -> bool:
	var accepted: bool = await super._roundtrip_and_abort(label, abort)
	if not accepted or not PORTRAIT_LABELS.has(label): return accepted
	return await _portrait(label)


func _portrait(label: String) -> bool:
	if not _expect(not _captured_labels.has(label) and paused and not _production.is_pause_requested() and not _level.is_restore_candidate(), "one actual installed paused receiver is captured once: " + label): return false
	var state: Dictionary = _level.call("component_state")
	var actual_phase: bool = _tether.get("hp") == 30.0 and _tether.get("phase") == 2 and _source("enclose").state().status == "running" if label == "held-phase2-Enclose" else _tether.get("hp") == 0.0 and _tether.get("phase") == 3 and state.released and not state.pending_release and not state.helper_retired.is_empty() and state.helper_death.is_empty()
	if not _expect(actual_phase and state.sun.started, "capture label matches the actual earned phase/helper/Sun state: " + label, str(state)): return false
	var camera: Camera3D = _hero.get_viewport().get_camera_3d()
	var sun: Node3D = _level.get("sun_art") as Node3D
	if not _expect(camera != null and sun != null and camera == _game.get("camera") and String(sun.call("runtime_error")).is_empty(), "actual current same-world Camera and native Sun reader are retained: " + label): return false
	var sunlight: Dictionary = _level.call("optional_sun_bounds", camera)
	var union: Dictionary = _level.call("framing_union", camera)
	if not _expect(String(sunlight.get("error", "native Sun bound required")).is_empty() and sunlight.get("points") is Array and sunlight.points.size() == 16 and String(union.get("error", "native full union required")).is_empty() and union.get("points") is Array, "actual displayed two-sun16 corners and full root/source/Hero union are available: " + label, str(sunlight.get("error", "")) + "; " + str(union.get("error", ""))): return false
	# These are two CURRENT projection checks on the same actual Camera/HUD,
	# not separate proposed-fit plans. Every corner must pass this one view.
	var view_error: String = String(_game.call("camera_framing_error", union.points))
	var sun_error: String = String(_game.call("camera_framing_error", sunlight.points))
	if view_error.is_empty() and not sun_error.is_empty(): view_error = "Actual Sun16: " + sun_error
	var before: Dictionary = _production.capture_campaign_snapshot()
	var wire: String = PairExact.stringify(before)
	var input_before: PackedByteArray = var_to_bytes(_game.call("get_input_observation_state"))
	var camera_before: PackedByteArray = var_to_bytes(_camera_record(camera))
	var events_before: PackedByteArray = var_to_bytes({"events": _events, "quiet": _quiet_events, "negative": _negative_native_events})
	var sun_before: String = PairExact.stringify(_level.call("sun_presentation_state"))
	if not _expect(not before.is_empty() and not wire.is_empty() and not sun_before.is_empty(), "complete actual paused pair/model can guard the render operation: " + label, _production.campaign_error): return false
	_game.call("resume_lab")
	if not _expect(not paused and not _production.menu.is_open(), "public Resume removes the actual overlay: " + label): return false
	paused = true # TEST ONLY render freeze. No await/physics between Resume/freeze.
	_draw_seen = false
	var draw_before: Dictionary = _draw_diagnostic()
	var observer: Callable = _on_portrait_draw
	RenderingServer.frame_post_draw.connect(observer)
	for _i: int in range(32):
		await process_frame
		if _draw_seen: break
	if RenderingServer.frame_post_draw.is_connected(observer): RenderingServer.frame_post_draw.disconnect(observer)
	var image: Image = root.get_texture().get_image() if _draw_seen else null
	var after: Dictionary = _production.capture_campaign_snapshot()
	var same: bool = paused and not _production.is_pause_requested() and not _production.menu.is_open() and not after.is_empty() and PairExact.stringify(after) == wire and var_to_bytes(_game.call("get_input_observation_state")) == input_before and var_to_bytes(_camera_record(camera)) == camera_before and var_to_bytes({"events": _events, "quiet": _quiet_events, "negative": _negative_native_events}) == events_before and PairExact.stringify(_level.call("sun_presentation_state")) == sun_before and String(sun.call("runtime_error")).is_empty()
	var directory: String = ProjectSettings.globalize_path(PORTRAIT_FOLDER)
	var destination: String = directory.path_join(String(PORTRAIT_LABELS[label]))
	var saved: bool = image != null and image.get_size() == Vector2i(339,736) and same and DirAccess.make_dir_recursive_absolute(directory) == OK and image.save_png(destination) == OK
	if saved:
		_captured_labels[label] = destination
		print("PORTRAIT: " + destination)
		# If the Sun native current-view check fails, retain the exact unchanged
		# diagnostic pixels before failing; never move/zoom the camera to pass.
		var receipt: Dictionary = {"schema_version": 1, "test_only": true, "label": label, "native_size": [339,736], "png_sha256": FileAccess.get_sha256(destination), "sun_corners": sunlight.points.size(), "required_union_corners": union.points.size(), "actual_camera_error": view_error, "whole_campaign_wire_sha256": wire.sha256_text(), "sun_model": _level.call("sun_presentation_state"), "frozen_pair_input_camera_events": same, "render_freeze_without_tick": true, "native_ticks": _native_ticks, "canonical_route_credit": false}
		var record: FileAccess = FileAccess.open(destination + ".json", FileAccess.WRITE)
		if record == null: return _expect(false, "native portrait receipt can be saved: " + label)
		record.store_string(JSON.stringify(receipt, "  ") + "\n")
		record.close()
	print("ROOT_DRAW_DIAGNOSTIC: " + JSON.stringify({"label": label, "before": draw_before, "after": _draw_diagnostic(), "draw_seen": _draw_seen, "frozen_pair_input_camera_events": same, "actual_framing_error": view_error, "image_available": image != null}))
	if not _expect(saved and _draw_seen, "actual339x736 root portrait preserves exact pair/input/camera/events/model: " + label, "size=" + str(image.get_size()) if image != null else "bounded native draw unavailable"): return false
	return _expect(view_error.is_empty(), "actual Camera/HUD contains the complete root/source/Hero union plus two native suns: " + label, view_error)


func _draw_diagnostic() -> Dictionary:
	return {"wall_ticks_ms": Time.get_ticks_msec(), "physics_frames": Engine.get_physics_frames(), "process_frames": Engine.get_process_frames(), "frames_drawn": Engine.get_frames_drawn(), "render_loop_enabled": RenderingServer.is_render_loop_enabled(), "render_server_has_changed": RenderingServer.has_changed(), "rendering_driver": RenderingServer.get_current_rendering_driver_name(), "low_processor_usage_mode": OS.is_in_low_processor_usage_mode(), "window_can_draw": DisplayServer.window_can_draw(root.get_window_id()), "window_mode": root.mode, "window_visible": root.visible, "window_has_focus": root.has_focus(), "display_window_focused": DisplayServer.window_is_focused(root.get_window_id()), "window_size": str(root.size), "logical_visible_rect": str(root.get_visible_rect()), "tree_paused": paused}


func _camera_record(camera: Camera3D) -> Dictionary:
	return {"transform": camera.global_transform, "projection": camera.projection, "keep_aspect": camera.keep_aspect, "size": camera.size, "near": camera.near, "far": camera.far, "h_offset": camera.h_offset, "v_offset": camera.v_offset}


func _on_portrait_draw() -> void:
	_draw_seen = true


func _finish() -> void:
	if _failures == 0: _expect(_captured_labels.size() == 2, "both actual held-phase2 and settled-release root portraits were reached once")
	print("TEST ONLY mixed-root portraits: %d/%d original frames; actual Sun16/current-Camera and no-tick whole-pair freeze only. No new art/route/OS/human/acceptance claim." % [_captured_labels.size(), PORTRAIT_LABELS.size()])
	await super._finish()
