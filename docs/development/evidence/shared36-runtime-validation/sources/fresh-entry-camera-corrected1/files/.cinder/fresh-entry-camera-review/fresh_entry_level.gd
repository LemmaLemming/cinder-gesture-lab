extends "res://scripts/campaign/level.gd"
## TEST ONLY fixed native source/opportunity bounds at a genuinely displaced
## scene-authored spawn. No enemy, damage, admission or act acceptance.
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
@export var source_width: float = 0.6
var source: MeshInstance3D
var source_mesh: BoxMesh
var return_bad_snapshot: bool = false
var context_captures: int = 0
var last_context_safe_rect: Rect2
var last_context_pixels: Vector2
var last_context_objective: String = ""


func _on_enter_level() -> void:
	_build_source()


func _build_source() -> void:
	source = MeshInstance3D.new()
	source.name = "ActualSourceAndOpeningBounds"
	source_mesh = BoxMesh.new()
	source_mesh.size = Vector3(source_width, 1.0, 0.6)
	source.mesh = source_mesh
	source.position = spawn_position() + Vector3(1.0, 0.4, 0.8)
	add_child(source)


func _camera_framing_points() -> Array:
	if not is_instance_valid(source) or source.mesh != source_mesh: return [Vector3.INF]
	var bounds: AABB = source.get_aabb()
	var points: Array = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]:
				points.append(source.global_transform * Vector3(x, y, z))
	return points


func _capture_checked(framing_camera: Camera3D, framing_hud: GameHUD) -> Dictionary:
	last_snapshot_error = _mechanical_error()
	if last_snapshot_error.is_empty():
		last_snapshot_error = shared_shell.camera_framing_error_for_context(camera_framing_points(), hero, framing_camera, framing_hud)
	if not last_snapshot_error.is_empty(): return {}
	# Same writer and whole-envelope validation in BOTH ordinary and explicit
	# capture paths. The supplied actual HUD replaces no installed aliases.
	var result: Dictionary = super.snapshot_state()
	if result.is_empty(): return {}
	last_snapshot_error = snapshot_error(result)
	return result if last_snapshot_error.is_empty() else {}


func snapshot_state() -> Dictionary:
	# This is the original independently guarded live writer: actual level
	# current camera, actual installed HUD. It honestly rejects stale entry.
	if is_restore_candidate():
		last_snapshot_error = "A nonplayable restored recipient is not live capture"
		return {}
	return _capture_checked(hero.get_viewport().get_camera_3d(), shared_shell.hud)


func snapshot_state_for_presentation(framing_camera: Camera3D, framing_hud: GameHUD) -> Dictionary:
	# New explicit opt-in only. Script exists even in the original reproduction,
	# whose original Shell never calls it. No missing-method assertion is used.
	if is_restore_candidate():
		last_snapshot_error = "Fresh explicit capture cannot be saved restoration"
		return {}
	var result: Dictionary = _capture_checked(framing_camera, framing_hud)
	if not result.is_empty():
		# Diagnostic observations only, not saved authority or a pass stamp.
		context_captures += 1
		last_context_safe_rect = framing_hud.combat_safe_rect()
		last_context_pixels = framing_hud.get_viewport().get_visible_rect().size
		last_context_objective = framing_hud._objective_label.text
	if return_bad_snapshot and not result.is_empty(): result.schema_version = 999
	return result


func _mechanical_error() -> String:
	if not is_instance_valid(hero) or not is_instance_valid(shared_shell) or not is_instance_valid(source) or source.get_parent() != self or source.mesh != source_mesh or source_mesh.size != Vector3(source_width, 1.0, 0.6) or source.position != spawn_position() + Vector3(1.0, 0.4, 0.8):
		return "Actual TEST ONLY native source/Player bindings changed"
	return ""


func _capture_local_state() -> Dictionary:
	return {"native_source_width": source_width}


func _local_snapshot_error(state: Dictionary) -> String:
	if not Value.keys_error(state, ["native_source_width"]).is_empty() or not state.get("native_source_width") is float or state.native_source_width != source_width:
		return "Closed actual scene-authored source width required"
	return _mechanical_error()


func _local_snapshot_error_with_player(state: Dictionary, _saved_player: Dictionary) -> String:
	# Pure mechanics only; original saved optical gate measures actual physical
	# recipient AFTER Player->local commit, without refitting saved focus.
	return _local_snapshot_error(state)


func _restore_candidate_presentation_error(framing_camera: Camera3D, framing_hud: GameHUD) -> String:
	var error: String = _mechanical_error()
	return shared_shell.camera_framing_error_for_context(camera_framing_points(), hero, framing_camera, framing_hud) if error.is_empty() else error


func _restore_local_state(_state: Dictionary) -> void:
	pass
