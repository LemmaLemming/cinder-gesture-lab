extends "res://tests/acts/act3/crystalman_rule_room_smoke.gd"
## SOURCE-ONLY DRAFT. Ordinary first case; no invalid case or native execution.
## Inherited real input/proof/tether/deadline/pause/disposal checks remain exact.
## After consumed public GUI Resume, a disclosed no-tick render freeze hides
## no gameplay UI itself. No pose, physics, floor, HP, kit, clock or art rewrite.

const PORTRAIT_DIRECTORY: String = "res://captures/act3/crystalman-rule-room"
const PORTRAIT_PHASES: Array[String] = ["warning", "active", "exposed", "spent"]
const EXPECTED_SMOKE_SHA: String = "12b6a11b02a9b3f1a7d8f1ec5e44a4febe28a1a9cdd117127b3ebdee313cba17"
const EXPECTED_RUNTIME_SHA: String = "d4bb3e237a75eb16f6c31f40d6ed38795c802e4c440ab2f3c9b29779ecdcaee2"
const REQUESTED_SIZE := Vector2i(340, 736)
const DRAW_LIMIT: int = 32

var _portraits: Dictionary = {}
var _portrait_draw_seen: bool = false


func _run() -> void:
	# Reuse the unchanged ordinary program; no replay of the invalid case.
	_clock_join_only = false
	if not _expect(OS.get_cmdline_user_args().is_empty(), "graphical fixture supports only its ordinary first case"):
		await _close()
		quit(1)
		return
	if not _expect(DisplayServer.get_name() != "headless", "mechanic portraits require real graphical rendering"):
		await _close()
		quit(1)
		return
	if not _expect(FileAccess.get_sha256("res://tests/acts/act3/crystalman_rule_room_smoke.gd") == EXPECTED_SMOKE_SHA and FileAccess.get_sha256("res://scripts/acts/act3/crystalman_rule_room.gd") == EXPECTED_RUNTIME_SHA, "graphical derivative uses its reviewed exact smoke/runtime bytes"):
		await _close()
		quit(1)
		return
	if await _open(): await _ordinary_case()
	await _close()
	if _failures == 0: _expect(_portraits.size() == PORTRAIT_PHASES.size(), "all four actual mechanic phases captured once")
	print("Crystalman ordinary graphical portraits: %d checks; failures: %d; actual post-actor ticks: %d; images: %d/4. Prototype mechanics only; no whole-parent transport/art/phase2/canonical history acceptance." % [_checks, _failures, _ticks, _portraits.size()])
	quit(0 if _failures == 0 else 1)


func _pause_resume(label: String) -> bool:
	var accepted: bool = await super._pause_resume(label)
	if not accepted: return false
	# The inherited consumed GUI Resume has returned without another physics
	# await; the render-only freeze below is separate from public Pause proof.
	return await _portrait(label)


func _sever_with_real_primary() -> bool:
	# The inherited whole proof has actually reached its attack position and
	# exposed phase. These public pause/resume operations add no combat action.
	if not await _pause_resume("exposed"): return false
	if not await super._sever_with_real_primary(): return false
	# After the inherited spent/once-only30-tick check and before disposal.
	return await _pause_resume("spent")


func _portrait(label: String) -> bool:
	if not _expect(label in PORTRAIT_PHASES and not _portraits.has(label) and not paused and not _game.call("is_pause_requested"), "one actual resumed deferred phase is captured once: " + label): return false
	var live: Dictionary = _room.call("state")
	var camera: Camera3D = _game.get("camera") as Camera3D
	var hud: GameHUD = _game.get("hud") as GameHUD
	var resume: Button = _find_resume(hud)
	var phase_ok: bool = live.phase == label and live.generation == 1 and live.joins == 1 and live.rejections == 0 and live.configuration_error.is_empty() and live.camera_error.is_empty()
	if label == "spent": phase_ok = phase_ok and live.cleared and live.tether_hits == 1 and _scheduler.reservations().is_empty()
	else: phase_ok = phase_ok and not live.cleared and live.tether_hits == 0 and _scheduler.reservations().size() == 1 and live.playback.status == "running"
	if not _expect(phase_ok and camera != null and hud != null and camera == _hero.get_viewport().get_camera_3d() and (resume == null or not resume.is_visible_in_tree()) and _hero.hp == _hp and _hero.equipment.snapshot() == _kit, "actual earned phase/shared current Camera/HUD/resources retained: " + label, str(live.phase)): return false
	paused = true # TEST ONLY render freeze, synchronous after consumed Resume.
	var before: Dictionary = _portrait_observation(camera, hud)
	var before_bytes: PackedByteArray = var_to_bytes(before)
	var leaf_wire: String = Exact.stringify(before.leaf_snapshots)
	if not _expect(_paused_observation_valid(before) and not leaf_wire.is_empty(), "complete native paused leaf/proof/input/camera guard available: " + label, str(before.snapshot_errors)):
		paused = false
		return false
	var points: Array = _room.call("camera_framing_points")
	var view_error: String = _game.call("camera_framing_error", points)
	_portrait_draw_seen = false
	var draw_before: Dictionary = _portrait_draw_diagnostic()
	var observer: Callable = _on_portrait_draw
	RenderingServer.frame_post_draw.connect(observer)
	for _i: int in range(DRAW_LIMIT):
		await process_frame
		if _portrait_draw_seen: break
	if RenderingServer.frame_post_draw.is_connected(observer): RenderingServer.frame_post_draw.disconnect(observer)
	var pixels: Image = root.get_texture().get_image() if _portrait_draw_seen else null
	var after: Dictionary = _portrait_observation(camera, hud)
	var same: bool = paused and _paused_observation_valid(after) and var_to_bytes(after) == before_bytes and Exact.stringify(after.leaf_snapshots) == leaf_wire
	var texture_metadata_size: Vector2 = root.get_texture().get_size()
	# Metadata may describe the logical/stretch target; the original root Image
	# is the native pixel evidence. Keep actual339/340x736 and window340x736.
	var size_ok: bool = pixels != null and pixels.get_size().y == REQUESTED_SIZE.y and pixels.get_size().x in [339, REQUESTED_SIZE.x] and root.size == REQUESTED_SIZE
	var directory: String = ProjectSettings.globalize_path(PORTRAIT_DIRECTORY)
	var destination: String = directory.path_join(label + ".png")
	var mkdir_error: int = DirAccess.make_dir_recursive_absolute(directory) if _portrait_draw_seen and size_ok and same else ERR_INVALID_DATA
	var png_error: int = pixels.save_png(destination) if mkdir_error == OK else ERR_INVALID_DATA
	var saved: bool = _portrait_draw_seen and size_ok and same and mkdir_error == OK and png_error == OK
	if saved:
		# A framing failure retains exact frozen diagnostic pixels; no moving
		# the camera, cropping, stretching, repainting or synthetic scene.
		var observation: FileAccess = FileAccess.open(destination + ".native.bin", FileAccess.WRITE)
		var text: FileAccess = FileAccess.open(destination + ".native.txt", FileAccess.WRITE)
		var record: FileAccess = FileAccess.open(destination + ".json", FileAccess.WRITE)
		if observation == null or text == null or record == null:
			paused = false
			return _expect(false, "native portrait original/receipt files open: " + label)
		observation.store_buffer(before_bytes)
		observation.close()
		text.store_string(var_to_str(before) + "\n")
		text.close()
		var receipt: Dictionary = {"schema_version": 1, "test_only": true, "label": label, "requested_resolution": [REQUESTED_SIZE.x, REQUESTED_SIZE.y], "actual_native_size": [pixels.get_size().x, pixels.get_size().y], "root_texture_metadata_size": [texture_metadata_size.x, texture_metadata_size.y], "png_sha256": FileAccess.get_sha256(destination), "native_observation_sha256": FileAccess.get_sha256(destination + ".native.bin"), "leaf_transport_sha256": leaf_wire.sha256_text(), "room_phase": live.phase, "generation": live.generation, "joins": live.joins, "tether_hits": live.tether_hits, "player_clock_s": _hero.get_world_action_clock(), "scheduler_clock_s": _scheduler.get_clock(), "whole_current_view_point_count": points.size(), "actual_camera_error": view_error, "unchanged_native_leaf_proof_input_camera_events_floor_kit": same, "render_freeze_without_gameplay_tick": true, "inherited_gui_pause_resume_preceded_capture": true, "actual_post_actor_ticks": _ticks, "smoke_sha256": EXPECTED_SMOKE_SHA, "runtime_sha256": EXPECTED_RUNTIME_SHA, "production_art_or_transport_credit": false}
		record.store_string(JSON.stringify(receipt, "  ") + "\n")
		record.close()
		_portraits[label] = destination
		print("PORTRAIT: " + destination)
	print("CRYSTALMAN_DRAW_DIAGNOSTIC: " + JSON.stringify({"label": label, "before": draw_before, "after": _portrait_draw_diagnostic(), "draw_seen": _portrait_draw_seen, "unchanged_native_observation": same, "actual_camera_error": view_error, "image_available": pixels != null, "size_policy_ok": size_ok, "root_texture_metadata_size": str(texture_metadata_size), "mkdir_error": mkdir_error, "png_error": png_error, "actual_image_size": str(pixels.get_size()) if pixels != null else "none"}))
	paused = false
	if not _expect(saved, "actual native portrait preserves paused state without a tick: " + label, "size=" + str(pixels.get_size()) if pixels != null else "bounded native draw unavailable"): return false
	return _expect(view_error.is_empty(), "actual current Camera/HUD contains complete Hero/source/footprint/whole-proof landing/tether union: " + label, view_error)


func _portrait_observation(camera: Camera3D, hud: GameHUD) -> Dictionary:
	var playback: CinderReplayPlayback = _room.get("playback") as CinderReplayPlayback
	var bindings: Dictionary = _room.call("scheduler_bindings")
	var schedule: Dictionary = _scheduler.snapshot_state(bindings)
	var leaf: Dictionary = {"player": _hero.snapshot_state(), "gate": _gate.snapshot_state(), "scheduler": schedule, "playback": playback.snapshot_state(schedule, bindings)}
	var tether: Node3D = _room.get("tether") as Node3D
	var response: Dictionary = _hero.get_threat_response_state()
	# Preserve the actual public actor's identity as its native integer ID;
	# archived observation buffers do not encode or recreate an Object.
	response.erase("actor")
	response["actor_instance_id"] = _hero.get_instance_id()
	return {"leaf_snapshots": leaf, "snapshot_errors": {"player": _hero.last_snapshot_error, "gate": _gate.last_snapshot_error, "scheduler": _scheduler.last_snapshot_error, "playback": playback.last_snapshot_error}, "room": _room.call("state"), "player_response": response, "world_actions": _hero.get_world_action_records(), "input": _game.call("get_input_observation_state"), "camera": {"transform": camera.global_transform, "projection": camera.projection, "keep_aspect": camera.keep_aspect, "size": camera.size, "near": camera.near, "far": camera.far, "h_offset": camera.h_offset, "v_offset": camera.v_offset, "framing_state": _game.call("get_camera_framing_state")}, "hud_safe_rect": hud.combat_safe_rect(), "events": _events.duplicate(true), "retirements": _retirements.duplicate(true), "latest_sequence": _latest_sequence(), "player_clock_s": _hero.get_world_action_clock(), "scheduler_clock_s": _scheduler.get_clock(), "hp": _hero.hp, "kit": _hero.equipment.snapshot(), "floor_transform": _floor_collision.global_transform, "floor_size": (_floor_collision.shape as BoxShape3D).size, "tether_transform": tether.global_transform, "tether_attackable": tether.is_in_group("environment_attack_targets"), "framing_points": _room.call("camera_framing_points"), "native_ticks": _ticks, "pause_requested": _game.call("is_pause_requested")}


func _paused_observation_valid(value: Dictionary) -> bool:
	var leaf: Dictionary = value.leaf_snapshots
	return paused and not leaf.player.is_empty() and not leaf.gate.is_empty() and not leaf.scheduler.is_empty() and not leaf.playback.is_empty() and value.snapshot_errors.values().all(func(error: Variant) -> bool: return error is String and error.is_empty()) and not value.pause_requested and value.hp == _hp and value.kit == _kit and value.floor_transform == _floor_transform and value.floor_size == _floor_size and value.room.configuration_error.is_empty()


func _portrait_draw_diagnostic() -> Dictionary:
	return {"wall_ticks_ms": Time.get_ticks_msec(), "physics_frames": Engine.get_physics_frames(), "process_frames": Engine.get_process_frames(), "frames_drawn": Engine.get_frames_drawn(), "render_loop_enabled": RenderingServer.is_render_loop_enabled(), "render_server_has_changed": RenderingServer.has_changed(), "rendering_driver": RenderingServer.get_current_rendering_driver_name(), "window_can_draw": DisplayServer.window_can_draw(root.get_window_id()), "window_mode": root.mode, "window_visible": root.visible, "window_has_focus": root.has_focus(), "window_size": str(root.size), "logical_visible_rect": str(root.get_visible_rect()), "tree_paused": paused}


func _on_portrait_draw() -> void:
	_portrait_draw_seen = true
