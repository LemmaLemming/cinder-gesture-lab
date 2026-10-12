extends "res://scripts/acts/act3/root_latcher.gd"
## IGNORED UNPUBLISHED PROPOSAL. Intended owned path:
## res://scripts/acts/act3/garden_root_latcher.gd
## Publish the art subclass first/with this resource; this proposed preload
## deliberately names the intended owned path, not an ignored test dependency.
## Inherits exact existing native actor/schema2/configure/HP/death semantics.
## Legacy framing_points(shell, geometry) and default L2 callers stay unchanged.

const GardenLatcherArt = preload("res://scripts/acts/act3/garden_root_latcher_art.gd")


## Small owned presentation substitution; preserve original name/parent and
## inherited present(), phase-to-pose/AtlasTexture/runtime behavior.
func _attach_optional_art() -> void:
	if is_instance_valid(_art):
		return
	_art = GardenLatcherArt.new() as Node3D
	if is_instance_valid(_art):
		_art.name = "RootLatcherArt"
		add_child(_art)


## Prospective/held native crescent plus the complete four-still art forecast.
## Inactive or defeated sources use ONLY their actual current native render
## group. Parent appends historical response positions only for a live held
## exchange or an actual unchanged prospective preview, never a dead history.
func framing_points_for_camera(framing_camera: Camera3D, geometry: Dictionary = {}) -> Dictionary:
	var error: String = _garden_framing_context_error(framing_camera)
	if not error.is_empty():
		return {"error": error, "points": []}
	if dead or (geometry.is_empty() and _mechanism.state().status != "running"):
		return current_render_framing_points_for_camera(framing_camera)
	var result: Dictionary = camera_framing_points(geometry)
	if not String(result.get("error", "")).is_empty():
		return result
	var art: Dictionary = _art.call("framing_points_for_camera", framing_camera, false)
	if not String(art.get("error", "Unsupported current-camera atlas response")).is_empty():
		return art
	var points: Array = result.points.duplicate()
	points.append_array(art.points)
	return _garden_checked_points(points)


## Actual current pose/shadow, living body and locally visible cue leaves.
## No historic crescent, prospective marker palette, four-pose forecast,
## landing or attack_position survives into this current-only result.
func current_render_framing_points_for_camera(framing_camera: Camera3D) -> Dictionary:
	var error: String = _garden_framing_context_error(framing_camera)
	if not error.is_empty():
		return {"error": error, "points": []}
	if not is_instance_valid(_body) or _body.get_parent() != self or not _body.shape is CapsuleShape3D or _body.transform != Transform3D(Basis.IDENTITY, Vector3(0, float(TUNING.capsule_center_y), 0)) or collision_layer != (0 if dead else 2) or collision_mask != (0 if dead else 1) or _body.disabled != dead or is_in_group("enemies") == dead:
		return {"error": "Actual native living/dead root body flags required", "points": []}
	var capsule: CapsuleShape3D = _body.shape as CapsuleShape3D
	if Vector3(capsule.radius, capsule.height, _body.position.y) != Vector3(float(TUNING.capsule_radius), float(TUNING.capsule_height), float(TUNING.capsule_center_y)):
		return {"error": "Original assigned native capsule dimensions required", "points": []}
	var art: Dictionary = _art.call("framing_points_for_camera", framing_camera, true)
	if not String(art.get("error", "Unsupported current-camera atlas response")).is_empty():
		return art
	var current: Dictionary = _mechanism.state()
	var cue: CinderThreatCue = _mechanism.get_cue()
	if not is_instance_valid(cue) or not cue.is_inside_tree() or cue.is_queued_for_deletion() or not cue.is_visible_in_tree() or cue.get_child_count() != 3:
		return {"error": "Original actual ordinary cue mesh tree required", "points": []}
	if dead:
		var native_cue: Dictionary = cue.state()
		if hp != 0.0 or current.status != "cancelled" or current.phase != "clear" or current.last_cancel_reason != "source_defeated" or _art.call("state").pose_key != "spent" or native_cue.phase != "clear" or native_cue.source_visible or native_cue.footprint_visible or native_cue.active_fill_visible:
			return {"error": "Actual visible spent root with its preserved death cancellation and clear cue required", "points": []}
	var points: Array = art.points.duplicate()
	if not dead:
		var half := Vector3(capsule.radius, capsule.height * 0.5, capsule.radius)
		var bounds := AABB(-half, half * 2.0)
		for corner: int in range(8):
			points.append(_body.global_transform * bounds.get_endpoint(corner))
	for child: Node in cue.get_children():
		if not child is MeshInstance3D or not child.is_inside_tree() or not child.is_node_ready() or child.is_queued_for_deletion() or child.get_parent() != cue or child.get_child_count() != 0:
			return {"error": "Actual ordinary cue mesh leaves required", "points": []}
		var visual: MeshInstance3D = child as MeshInstance3D
		if not visual.is_visible_in_tree():
			continue # Omit only actual invisible current cue leaves.
		if visual.mesh == null or (framing_camera.cull_mask & visual.layers) == 0:
			return {"error": "Visible current cue must have actual included native mesh bounds", "points": []}
		var box: AABB = visual.get_aabb()
		for corner: int in range(8):
			points.append(visual.global_transform * box.get_endpoint(corner))
	return _garden_checked_points(points)


func _garden_framing_context_error(framing_camera: Camera3D) -> String:
	if not _configured or not _bindings_valid() or global_position != _fixed_position or not is_visible_in_tree() or basis != Basis.IDENTITY or global_basis != Basis.IDENTITY or not is_instance_valid(_art) or _art.is_queued_for_deletion() or not _art.is_inside_tree() or not _art.is_node_ready() or _art.get_parent() != self or _art.get_script() != GardenLatcherArt or not _art.has_method("framing_points_for_camera"):
		return "Ready retained fixed bulb and actual owned current-camera art required"
	if not is_instance_valid(framing_camera) or not framing_camera.is_inside_tree() or not framing_camera.is_node_ready() or framing_camera.is_queued_for_deletion() or framing_camera.get_tree() != get_tree() or framing_camera.get_viewport() != get_viewport() or framing_camera.get_world_3d() != get_world_3d() or framing_camera.get_script() != null or get_viewport().get_script() != null or get_viewport().get_camera_3d() != framing_camera:
		return "Explicit actual native current camera in this configured bulb's viewport/world required"
	return ""


func _garden_checked_points(points: Array) -> Dictionary:
	if points.is_empty() or points.size() > 224:
		return {"error": "Complete current native bulb view requires a bounded nonempty point set", "points": []}
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite() or maxf(absf(point.x), maxf(absf(point.y), absf(point.z))) > 1024.0:
			return {"error": "Complete current native bulb view requires finite bounded corners", "points": []}
	return {"error": "", "points": points}
