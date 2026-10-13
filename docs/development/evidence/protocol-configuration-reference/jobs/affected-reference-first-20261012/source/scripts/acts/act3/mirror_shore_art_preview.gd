extends CinderLevel
## Quiet native art fixture using the real shared traveller/camera/controls.
## No enemy, hazard, interaction, progress, checkpoint, save or resource grant.
## Sun selection is explicit still presentation, never a transition clock.

const SceneryScript: GDScript = preload("res://scripts/acts/act3/mirror_sea_scenery.gd")
const WitnessScript: GDScript = preload("res://scripts/acts/act3/mirror_shore_witnesses.gd")
const OWNED_API: String = "act3-mirror-shore-art-preview-1"
const WITNESS_POSITION: Vector3 = Vector3.ZERO

var scenery: Node3D
var witnesses: Node3D
var last_configuration_error: String = ""
var _sun_state: int = 0


func _ready() -> void:
	process_physics_priority = 130
	scenery = SceneryScript.new() as Node3D
	scenery.name = "QuietMirrorShore"
	add_child(scenery)
	scenery.call("build", true)
	witnesses = WitnessScript.new() as Node3D
	witnesses.name = "PolecrabAndGleameilScenery"
	witnesses.position = WITNESS_POSITION
	add_child(witnesses)
	last_configuration_error = _dependency_error()


func _on_enter_level() -> void:
	set_sun_presentation(0)


func _physics_process(_delta: float) -> void:
	# This tail only follows the actual traveller. It has no local clock.
	if is_instance_valid(hero) and is_instance_valid(scenery):
		scenery.call("follow_landmarks", hero.global_position)
	var error: String = _dependency_error()
	if not error.is_empty():
		last_configuration_error = error


func set_sun_presentation(value: int) -> bool:
	if value not in [0, 1] or not is_instance_valid(hero):
		return false
	var error: String = _dependency_error()
	if not error.is_empty():
		last_configuration_error = error
		return false
	_sun_state = value
	# These are the actual scenery's public sun meshes and stable pose API.
	scenery.call("show_sun", value, "stable")
	scenery.call("follow_landmarks", hero.global_position)
	return true


func state() -> Dictionary:
	return {"api_revision": OWNED_API, "sun_state": _sun_state, "sun_stage": "stable", "configuration_error": runtime_error()}


func runtime_error() -> String:
	return last_configuration_error if not last_configuration_error.is_empty() else _dependency_error()


func _dependency_error() -> String:
	if not is_instance_valid(scenery) or scenery.get_parent() != self or not is_instance_valid(witnesses) or witnesses.get_parent() != self:
		return "Quiet shore requires its actual scenery and two-figure builder"
	if witnesses.transform != Transform3D(Basis.IDENTITY, WITNESS_POSITION) or global_transform != Transform3D.IDENTITY:
		return "Quiet shore requires its fixed untransformed authored floor and cast"
	if witnesses.get_child_count() != 2:
		return "Quiet shore requires exactly its two authored native figures"
	var error: String = String(scenery.call("runtime_error"))
	if not error.is_empty():
		return error
	return String(witnesses.call("runtime_error"))


## Exact complete native still quads. The shared shell adds Hero bounds and
## owns all camera translation. No alpha contour or physical proxy is used.
## Narrowly supports this builder's identity-basis, zero-margin AtlasTextures.
func art_framing_points() -> Dictionary:
	var error: String = runtime_error()
	if not error.is_empty():
		return {"error": error, "points": []}
	if not is_instance_valid(shared_shell):
		return {"error": "Quiet art framing requires its actual shared shell", "points": []}
	var camera: Camera3D = shared_shell.get("camera") as Camera3D
	if not is_instance_valid(camera) or camera.projection != Camera3D.PROJECTION_ORTHOGONAL or not camera.global_basis.is_finite():
		return {"error": "Quiet art requires its actual fixed orthographic camera", "points": []}
	if not camera.global_basis.is_equal_approx(camera.global_basis.orthonormalized()) or camera.global_basis.determinant() <= 0.0:
		return {"error": "Quiet art requires an unscaled right-handed camera basis", "points": []}
	var points: Array = []
	var count: int = 0
	for child: Node in witnesses.get_children():
		var sprite: Sprite3D = child as Sprite3D
		if sprite == null or not sprite.is_visible_in_tree() or sprite.global_basis != Basis.IDENTITY or sprite.billboard != BaseMaterial3D.BILLBOARD_ENABLED or sprite.axis != Vector3.AXIS_Z or sprite.fixed_size or not sprite.centered or sprite.region_enabled or sprite.hframes != 1 or sprite.vframes != 1 or sprite.frame != 0 or sprite.flip_h or sprite.flip_v or sprite.material_override != null or sprite.material_overlay != null:
			return {"error": "Unsupported quiet witness sprite transform or draw settings", "points": []}
		var atlas: AtlasTexture = sprite.texture as AtlasTexture
		if atlas == null or atlas.margin != Rect2() or not atlas.filter_clip or atlas.get_size() != WitnessScript.CROPS[count].size:
			return {"error": "Quiet witness requires its complete native zero-margin atlas crop", "points": []}
		var mesh: TriangleMesh = sprite.generate_triangle_mesh()
		if mesh == null or mesh.get_faces().size() != 6:
			return {"error": "Quiet witness native triangle quad unavailable", "points": []}
		var native_corners: Array[Vector3] = []
		for vertex: Vector3 in mesh.get_faces():
			if not vertex.is_finite() or vertex.z != 0.0:
				return {"error": "Unsupported quiet witness native quad", "points": []}
			if not native_corners.has(vertex):
				native_corners.append(vertex)
		if native_corners.size() != 4:
			return {"error": "Quiet witness requires four distinct native quad corners", "points": []}
		# The generated triangle mesh is snapped to .0001WU; item-rectangle
		# corners retain the actual unsnapped Sprite3D drawing extents.
		# Godot4.7.2 sprite_3d.cpp draw_texture_rect/get_item_rect map top
		# raster UV to maximum nativeY; full billboards use camera X/Y axes.
		var rect: Rect2 = sprite.get_item_rect()
		if rect.size != atlas.get_size() or not rect.position.is_finite():
			return {"error": "Quiet witness native sprite rectangle changed", "points": []}
		for x: float in [rect.position.x, rect.end.x]:
			for y: float in [rect.position.y, rect.end.y]:
				var corner := Vector3(x * sprite.pixel_size, y * sprite.pixel_size, 0)
				if not native_corners.has(corner.snapped(Vector3.ONE * 0.0001)):
					return {"error": "Quiet native mesh differs from its rendered rectangle", "points": []}
				points.append(sprite.global_position + camera.global_basis.x * corner.x + camera.global_basis.y * corner.y)
		count += 1
	if count != 2 or points.size() != 8:
		return {"error": "Quiet framing requires both complete native figures", "points": []}
	return {"error": "", "points": points}


func _camera_framing_points() -> Array:
	# The shell asks once during initial construction before enter_level.
	if not is_instance_valid(shared_shell):
		return []
	var result: Dictionary = art_framing_points()
	last_camera_framing_error = String(result.error)
	return result.points


func _capture_local_state() -> Dictionary:
	return {"api_revision": OWNED_API, "sun_state": _sun_state, "sun_stage": "stable"}


func _local_snapshot_error(data: Dictionary) -> String:
	var error: String = runtime_error()
	if not error.is_empty():
		return error
	if data.size() != 3 or data.get("api_revision") != OWNED_API or data.get("sun_stage") != "stable":
		return "Quiet shore snapshot requires its declared static presentation schema"
	var value: Variant = data.get("sun_state")
	if not (value is int or value is float) or value not in [0, 1]:
		return "Quiet shore snapshot requires actual sun presentation0 or1"
	return ""


func _restore_local_state(data: Dictionary) -> void:
	# Only an already validated scenery still is restored; no events/resources.
	_sun_state = int(data.sun_state)
	scenery.call("show_sun", _sun_state, "stable")
	scenery.call("follow_landmarks", hero.global_position)
