extends "res://scripts/acts/act3/root_latcher_art.gd"
## IGNORED UNPUBLISHED PROPOSAL. Intended owned path:
## res://scripts/acts/act3/garden_root_latcher_art.gd
## Legacy framing_points(shell), atlas, poses and present() are inherited.
## No Game.camera alias and no Sprite3D/body/presentation changes.


## Explicit actual native Camera3D; complete unsnapped rendered rectangles.
## Default false preserves the four-still conservative forecast. true returns
## only the currently presented still plus the actual rooted contact shadow.
## A hidden staging ancestor is supported, but this art's local visibility and
## every original child pose/AtlasTexture setting must remain exact. The parent
## subsequently validates the supplied Hero/Camera/HUD through public Game APIs.
func framing_points_for_camera(framing_camera: Camera3D, current_only: bool = false) -> Dictionary:
	if not is_inside_tree() or not is_node_ready() or is_queued_for_deletion() or not visible or basis != Basis.IDENTITY or global_basis != Basis.IDENTITY or not global_position.is_finite():
		return _bounds_error("Ready translated-only locally visible actual Root Latcher art required")
	if not is_instance_valid(framing_camera) or not framing_camera.is_inside_tree() or not framing_camera.is_node_ready() or framing_camera.is_queued_for_deletion() or framing_camera.get_tree() != get_tree() or framing_camera.get_viewport() != get_viewport() or framing_camera.get_world_3d() != get_world_3d():
		return _bounds_error("Explicit ready native camera in this art's viewport/world required")
	if framing_camera.get_script() != null or get_viewport().get_script() != null or get_viewport().get_camera_3d() != framing_camera or framing_camera.projection != Camera3D.PROJECTION_ORTHOGONAL or not framing_camera.global_basis.is_finite():
		return _bounds_error("Actual script-free current orthographic Camera3D required")
	var camera_basis: Basis = framing_camera.global_basis
	if not camera_basis.is_equal_approx(camera_basis.orthonormalized()) or camera_basis.determinant() <= 0.0:
		return _bounds_error("Camera basis must be unscaled and right-handed")
	if _stills.size() != 4 or _textures.size() != 4 or get_child_count() != 5 or not POSES.has(_pose) or not PHASE_POSES.has(_phase) or PHASE_POSES[_phase] != _pose or ATLAS.get_size() != Vector2(1254, 1254):
		return _bounds_error("Original four-pose atlas, selected phase and one shadow required")
	var points: Array = []
	for key: String in POSE_ORDER:
		# Reject a freed native reference before typed conversion.
		var candidate: Variant = _stills.get(key)
		if not is_instance_valid(candidate) or not candidate is Sprite3D:
			return _bounds_error("Actual retained native atlas still required")
		var sprite: Sprite3D = candidate as Sprite3D
		var error: String = _settings_error(sprite, key)
		if not error.is_empty():
			return _bounds_error(error)
		if not sprite.is_inside_tree() or not sprite.is_node_ready() or sprite.is_queued_for_deletion() or sprite.get_child_count() != 0 or not sprite.get_groups().is_empty() or sprite.top_level or sprite.layers != 1 or sprite.transparency != 0.0 or sprite.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			return _bounds_error("Original native still hierarchy and render leaves required")
		if current_only and key != _pose:
			continue # Validate retained hidden poses, omit their old forecasts.
		if (framing_camera.cull_mask & sprite.layers) == 0:
			return _bounds_error("Actual camera must include the selected atlas render layer")
		var mesh: TriangleMesh = sprite.generate_triangle_mesh()
		if mesh == null:
			return _bounds_error("Native atlas quad unavailable")
		var faces: PackedVector3Array = mesh.get_faces()
		var snapped_corners: Array[Vector3] = []
		for vertex: Vector3 in faces:
			if not vertex.is_finite() or vertex.z != 0.0:
				return _bounds_error("Unsupported native atlas quad")
			if not snapped_corners.has(vertex):
				snapped_corners.append(vertex)
		if snapped_corners.size() != 4 or faces.size() != 6:
			return _bounds_error("Native atlas must provide four complete quad corners")
		# Retain the native pixel_size; the TriangleMesh vertices are snapped
		# checks only. Unsnapped native item rectangles bound rendered pixels.
		var rect: Rect2 = sprite.get_item_rect()
		for x: float in [rect.position.x, rect.end.x]:
			for y: float in [rect.position.y, rect.end.y]:
				var corner := Vector3(x * sprite.pixel_size, y * sprite.pixel_size, 0)
				if not snapped_corners.has(corner.snapped(Vector3.ONE * 0.0001)):
					return _bounds_error("Native atlas mesh differs from its rendered rectangle")
				points.append(sprite.global_position + camera_basis.x * corner.x + camera_basis.y * corner.y)
	if not is_instance_valid(_shadow) or _shadow.is_queued_for_deletion() or not _shadow.is_inside_tree() or _shadow.get_parent() != self or _shadow.transform != Transform3D(Basis.IDENTITY, Vector3(0, 0.009, 0)) or not _shadow.visible or _shadow.mesh != _shadow_mesh or _shadow.material_override != _shadow_material or _shadow.material_overlay != null or _shadow.layers != 1 or _shadow.transparency != 0.0 or _shadow.top_level or _shadow.get_child_count() != 0 or not _shadow.get_groups().is_empty() or (framing_camera.cull_mask & _shadow.layers) == 0:
		return _bounds_error("Actual rooted contact shadow unavailable")
	var disk: CylinderMesh = _shadow.mesh as CylinderMesh
	if disk == null or Vector3(disk.top_radius, disk.bottom_radius, disk.height) != Vector3(0.32, 0.32, 0.006) or disk.radial_segments != 12:
		return _bounds_error("Contact shadow geometry changed")
	if _shadow_material == null or _shadow_material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or _shadow_material.albedo_color != Color("17131f") or _shadow_material.grow or _shadow_material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
		return _bounds_error("Contact shadow material changed")
	var bounds: AABB = _shadow.get_aabb()
	for corner: int in range(8):
		points.append(_shadow.global_transform * bounds.get_endpoint(corner))
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite() or maxf(absf(point.x), maxf(absf(point.y), absf(point.z))) > 1024.0:
			return _bounds_error("Complete atlas/shadow bounds require finite bounded native corners")
	return {"error": "", "points": points}
