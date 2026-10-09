#!/usr/bin/env python3
"""OFFLINE candidate generation. Never installs, mutates live inputs or runs Godot."""
from pathlib import Path
import difflib


directory = Path(__file__).resolve().parent
shell = (directory / "shell.original.gd").read_text()
level = (directory / "level.original.gd").read_text()
assert 'func snapshot_state_for_presentation(' not in level
level_hook = '''## Explicit native capture context for FRESH ordinary Shell entry only.
## Default preserves every existing writer. An opted owner overrides this
## virtual method and factors its normal snapshot_state writer so both paths
## retain complete live mechanical/optical guards; supplied HUD is actual,
## not an accepted stamp. Hooks must not mutate, emit, yield or reenter Shell.
func snapshot_state_for_presentation(_framing_camera: Camera3D, _framing_hud: GameHUD) -> Dictionary:
	return snapshot_state()


'''
level = level.replace('func snapshot_state() -> Dictionary:', level_hook + 'func snapshot_state() -> Dictionary:', 1)
(directory / "level.gd").write_text(level)
shell = shell.replace('const Difficulty = preload("res://scripts/combat/difficulty.gd")\n', 'const Difficulty = preload("res://scripts/combat/difficulty.gd")\nconst FreshCaptureExact = preload("res://scripts/campaign/exact_json.gd")\nconst FreshCapturePlayer = preload("res://scripts/player.gd")\n', 1)
assert shell.count('_capture(candidate.player, candidate.level, ') == 4
shell = shell.replace('_capture(candidate.player, candidate.level, ', '_capture_fresh_candidate(candidate, ')
for operation in ['begin_story', 'advance_story', 'begin_side', 'restart_replay']:
    arguments = {
        'begin_story': 'snapshot',
        'advance_story': 'snapshot',
        'begin_side': 'operation.kind, operation.level_id, snapshot',
        'restart_replay': 'snapshot',
    }[operation]
    old = f'\t\t\tif snapshot.is_empty() or not attempts.{operation}({arguments}):\n'
    new = '\t\t\tif snapshot.is_empty():\n\t\t\t\t_dispose(candidate)\n\t\t\t\treturn false\n' + f'\t\t\tif not attempts.{operation}({arguments}):\n'
    assert shell.count(old) == 1
    shell = shell.replace(old, new, 1)

helper = '''## Only begin/exit/side/restart fresh constructors use this path.
## Saved restoration retains its independent quiet commit + saved-focus gate.
func _capture_fresh_candidate(candidate: Dictionary, shell_state: Dictionary) -> Dictionary:
	var error: String = _fresh_capture_binding_error(candidate)
	if not error.is_empty():
		_fail("Fresh candidate presentation failed: " + error)
		return {}
	var original_bindings: Dictionary = candidate.duplicate()
	var actor: CinderPlayer = candidate.player
	var level: CinderLevel = candidate.level
	var actual_camera: Camera3D = candidate.camera
	var actor_script: Script = actor.get_script()
	var level_script: Script = level.get_script()
	var effects_script: Script = candidate.fx.get_script()
	var player_state: Dictionary = actor.snapshot_state()
	var actor_before: String = FreshCaptureExact.stringify(player_state)
	if player_state.is_empty() or actor_before.is_empty():
		_fail("Fresh candidate capture requires a complete bounded actual Player snapshot")
		return {}
	error = _shell_state_error(shell_state, player_state)
	if not error.is_empty() or Codec.read_vector3(shell_state.camera_focus) != Vector3.ZERO:
		_fail("Fresh candidate capture requires original fresh Shell state, never a saved focus")
		return {}
	var outer_size: Vector2 = hud.get_viewport().get_visible_rect().size
	if not outer_size.is_finite() or outer_size.x < 1.0 or outer_size.y < 1.0 or outer_size.x > 16384.0 or outer_size.y > 16384.0 or Vector2(Vector2i(outer_size)) != outer_size:
		_fail("Fresh candidate requires bounded integral outer HUD pixels")
		return {}
	var hud_viewport := SubViewport.new()
	hud_viewport.name = "FreshCaptureHUDViewport"
	hud_viewport.size = Vector2i(outer_size)
	hud_viewport.disable_3d = true
	hud_viewport.handle_input_locally = false
	hud_viewport.gui_disable_input = true
	hud_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(hud_viewport)
	var framing_hud: GameHUD = HUDScript.new()
	framing_hud.name = "FreshCaptureHUD"
	framing_hud.visible = false
	hud_viewport.add_child(framing_hud)
	framing_hud.set_campaign_mode()
	framing_hud.hide_overlay()
	var objective: String = level.objective_text
	framing_hud.update_status(actor.hp, actor.max_hp, actor.shells, actor.max_shells, 0, objective)
	var hud_before: String = _fresh_capture_hud_wire(framing_hud)
	if hud_before.is_empty(): error = "Actual canonical staging HUD shape unavailable"
	var points: Array = level.camera_framing_points()
	if not level.last_camera_framing_error.is_empty(): error = level.last_camera_framing_error
	var mandatory: Array = player_camera_framing_points_for(actor, actual_camera)
	var points_before: String = _fresh_capture_points_wire(points)
	var mandatory_before: String = _fresh_capture_points_wire(mandatory)
	if points_before.is_empty() or mandatory_before.is_empty() or mandatory.is_empty(): error = "Bounded actual required source/Player corners unavailable"
	var plan: Dictionary = {}
	if error.is_empty():
		plan = camera_framing_plan_for_context(points, actor.global_position + Vector3.UP * 0.75, actor, actual_camera, framing_hud)
		if not plan.get("accepted", false): error = String(plan.get("reason", "Actual fresh full-union framing rejected"))
	var focus: Vector3 = Vector3.ZERO
	var prepared_state: Dictionary = shell_state.duplicate(true)
	var local_state: Dictionary = {}
	# All writes stay in this hidden candidate, never installed Game aliases.
	if error.is_empty():
		focus = plan.focus
		actual_camera.global_position = focus + CAMERA_OFFSET
		prepared_state.camera_focus = Codec.vector3(focus)
		var contained: Array = points if not points.is_empty() else mandatory
		error = camera_framing_error_for_context(contained, actor, actual_camera, framing_hud)
	if error.is_empty():
		local_state = level.snapshot_state_for_presentation(actual_camera, framing_hud)
		if local_state.is_empty(): error = level.last_snapshot_error if not level.last_snapshot_error.is_empty() else "Actual fresh local capture refused"
	if error.is_empty(): error = _fresh_capture_binding_error(candidate)
	if error.is_empty():
		for key: String in original_bindings:
			if candidate[key] != original_bindings[key]:
				error = "Fresh hook replaced an original native constructor node"
				break
	if error.is_empty() and (candidate.player != actor or candidate.level != level or candidate.camera != actual_camera or actor.get_script() != actor_script or level.get_script() != level_script or candidate.fx.get_script() != effects_script): error = "Fresh capture replaced actual retained native bindings or Scripts"
	# Preserve ordinary whole-level validation before any Attempts/disk commit.
	# This runs outside the writer, with no wider busy/reentry allowance.
	if error.is_empty(): error = level.snapshot_error(local_state)
	if error.is_empty(): error = _fresh_capture_binding_error(candidate)
	if error.is_empty():
		for key: String in original_bindings:
			if candidate[key] != original_bindings[key]:
				error = "Fresh hook replaced an original native constructor node"
				break
	if error.is_empty() and (candidate.player != actor or candidate.level != level or candidate.camera != actual_camera or actor.get_script() != actor_script or level.get_script() != level_script or candidate.fx.get_script() != effects_script): error = "Fresh validator replaced actual retained bindings or Scripts"
	if error.is_empty() and _fresh_capture_hud_wire(framing_hud) != hud_before: error = "Fresh hook changed actual canonical HUD pixels, objective or safe rectangle"
	if error.is_empty():
		var actor_after: String = FreshCaptureExact.stringify(actor.snapshot_state())
		var actual_points: Array = level.camera_framing_points()
		var actual_mandatory: Array = player_camera_framing_points_for(actor, actual_camera)
		if actor_after.is_empty() or actor_after != actor_before or level.objective_text != objective or _fresh_capture_points_wire(actual_points) != points_before or _fresh_capture_points_wire(actual_mandatory) != mandatory_before or not level.last_camera_framing_error.is_empty() or actual_camera.global_position != focus + CAMERA_OFFSET:
			error = "Fresh capture hook changed actual Player, required bounds, objective or planned camera"
		else:
			error = camera_framing_error_for_context(actual_points if not actual_points.is_empty() else actual_mandatory, actor, actual_camera, framing_hud)
	# No callbacks/yields are authorized in the trusted capture method. A broken
	# hook is rejected, never healed; its candidate is disposed by the caller.
	if is_instance_valid(hud_viewport): hud_viewport.free()
	if not error.is_empty():
		_fail("Fresh candidate presentation failed: " + error)
		return {}
	return {"schema_version": 1, "level_id": level.level_id, "scene_path": level.scene_file_path, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": player_state, "level": local_state, "shell": prepared_state}

func _fresh_capture_binding_error(candidate: Dictionary) -> String:
	if not get_tree().paused or not is_instance_valid(hud) or not hud.is_inside_tree() or not hud.is_node_ready() or hud.is_queued_for_deletion() or hud.get_script() != HUDScript or hud.custom_viewport != null:
		return "Paused Shell and actual canonical outer HUD required"
	if not Codec.keys_error(candidate, ["container", "viewport", "stage", "camera", "level", "player", "fx"]).is_empty(): return "Complete original fresh constructor required"
	for key: String in ["container", "viewport", "stage", "camera", "level", "player", "fx"]:
		var value: Variant = candidate[key]
		if not is_instance_valid(value) or not value is Node or not value.is_inside_tree() or not value.is_node_ready() or value.is_queued_for_deletion() or value.get_tree() != get_tree(): return "Fresh constructor lost a ready native binding"
	if not candidate.container is SubViewportContainer or not candidate.viewport is SubViewport or not candidate.stage is Node3D or not candidate.camera is Camera3D or not candidate.level is CinderLevel or not candidate.player is CinderPlayer or not candidate.fx is PixelEffects: return "Actual typed fresh constructor required"
	if candidate.container.get_parent() != self or candidate.container.visible or candidate.viewport.get_parent() != candidate.container or not candidate.viewport.own_world_3d or candidate.stage.get_parent() != candidate.viewport or candidate.camera.get_parent() != candidate.stage or candidate.level.get_parent() != candidate.stage or candidate.player.get_parent() != candidate.stage or candidate.fx.get_parent() != candidate.stage: return "Original hidden fresh World3D constructor hierarchy required"
	if candidate.container.get_script() != null or candidate.viewport.get_script() != null or candidate.stage.get_script() != null: return "Original native Script-free constructor container/viewport/stage required"
	if candidate.player.get_script() != FreshCapturePlayer or candidate.fx.get_script() != EffectsScript or candidate.level.get_script() == null: return "Actual canonical Player/effects and retained authored level Script required"
	if candidate.level.is_restore_candidate() or candidate.level.hero != candidate.player or candidate.level.effects != candidate.fx or candidate.level.shared_shell != self or candidate.player.fx != candidate.fx or candidate.camera == camera or candidate.player == player or candidate.level == active_level: return "Fresh ordinary bindings cannot substitute saved recipients or installed aliases"
	return _camera_player_binding_error(candidate.player, candidate.camera)

func _fresh_capture_hud_wire(framing_hud: GameHUD) -> String:
	if not is_instance_valid(framing_hud) or not framing_hud.is_inside_tree() or not framing_hud.is_node_ready() or framing_hud.is_queued_for_deletion() or framing_hud.get_script() != HUDScript or framing_hud.custom_viewport != null or not is_instance_valid(framing_hud._objective_label): return ""
	var pixels: Vector2 = framing_hud.get_viewport().get_visible_rect().size
	var safe: Rect2 = framing_hud.combat_safe_rect()
	return FreshCaptureExact.stringify({"pixels": [float(pixels.x), float(pixels.y)], "objective": framing_hud._objective_label.text, "safe_rect": [float(safe.position.x), float(safe.position.y), float(safe.size.x), float(safe.size.y)]})

func _fresh_capture_points_wire(points: Array) -> String:
	if points.size() > 256: return ""
	var encoded: Array = []
	for value: Variant in points:
		if not value is Vector3 or not value.is_finite() or maxf(absf(value.x), maxf(absf(value.y), absf(value.z))) > 1024.0: return ""
		encoded.append(Codec.vector3(value))
	return FreshCaptureExact.stringify(encoded)

'''
assert 'func _capture_fresh_candidate(' not in shell
shell = shell.replace('func _prepare(id: String,', helper + 'func _prepare(id: String,', 1)
(directory / "shell.gd").write_text(shell)
patch = ''
for name in ['level', 'shell']:
    patch += ''.join(difflib.unified_diff((directory/(name+'.original.gd')).read_text().splitlines(keepends=True), (directory/(name+'.gd')).read_text().splitlines(keepends=True), fromfile='a/scripts/campaign/'+name+'.gd', tofile='b/scripts/campaign/'+name+'.gd'))
(directory/'fresh-entry-camera.patch').write_text(patch)
print('OFFLINE two-core draft generated; no live writes or engine')
