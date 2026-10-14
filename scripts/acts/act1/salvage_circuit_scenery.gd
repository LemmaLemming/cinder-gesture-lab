class_name Act1SalvageCircuitScenery
extends "res://scripts/acts/act1/lunar_scenery.gd"
## SOURCE ONLY: compact reuse adapter; accepted L2/L5 renderers stay unchanged.
## No source, cue, physics, player, camera movement, clock or reward authority.

const CapsuleScript = preload("res://scripts/acts/act1/living_moon_capsule.gd")
const O1_FLOOR_SIZE: Vector2 = Vector2(14, 16)
const O1_CAPSULE_POSITION: Vector3 = Vector3(0, 0, 2)

var _capsule: Act1LivingMoonCapsule
var _damage_seams: Node3D
var _repaired: bool = false
var _actual_view: Camera3D


func build(level: Node3D) -> void:
	if _built or not is_instance_valid(level) or level.is_queued_for_deletion() or (get_parent() != null and get_parent() != level): return
	name = "Scenery"
	if get_parent() == null: level.add_child(self)
	_built = true
	set_meta("readiness", "source_only_unparsed_unexecuted_portrait_unverified")
	_build_floor_overlay()
	# Existing L2 cutout helper retains complete textures, pivot/depth/filtering.
	for side: float in [-1.0, 1.0]:
		for index: int in range(2):
			var flat: Sprite3D = _cutout("QuietEdgeFlat_%s_%d" % ["West" if side < 0 else "East", index], "rock_a" if index == 0 else "rock_b", Vector3(side * 7.2, 0.005, -5.8 if index == 0 else 5.8), 0.024)
			flat.flip_h = side > 0
	_capsule = CapsuleScript.new()
	_capsule.name = "ExistingFinlessCapsule"
	_capsule.position = O1_CAPSULE_POSITION
	add_child(_capsule)
	_damage_seams = Node3D.new()
	_damage_seams.name = "DamagedLatchSeams"
	_damage_seams.position = O1_CAPSULE_POSITION + Vector3(0, 1.02, 1.57)
	_damage_seams.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(_damage_seams)
	for angle: float in [-0.32, 0.32]:
		var visual := MeshInstance3D.new()
		visual.name = "DamagedHatchSeam"
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.1, 0.065, 0.025)
		visual.mesh = mesh
		visual.rotation.z = angle
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("272727")
		material.roughness = 0.9
		visual.material_override = material
		_damage_seams.add_child(visual)
	set_repaired(false)


func _build_floor_overlay() -> void:
	# L2 tile/palette/1.536-world tile repeat, adapted only to this 14x16 floor.
	_floor_overlay = MeshInstance3D.new()
	_floor_overlay.name = "QuietSilverFloorOverlay"
	_floor_overlay.position = Vector3(0, 0.002, 0)
	var plane := PlaneMesh.new()
	plane.size = O1_FLOOR_SIZE
	_floor_overlay.mesh = plane
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.WHITE
	material.albedo_texture = TEXTURES.floor
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.texture_repeat = true
	material.uv1_scale = Vector3(O1_FLOOR_SIZE.x / FLOOR_TILE_WORLD_SIZE, O1_FLOOR_SIZE.y / FLOOR_TILE_WORLD_SIZE, 1)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.5
	material.no_depth_test = false
	_floor_overlay.material_override = material
	_floor_overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_floor_overlay)


func set_repaired(repaired: bool) -> bool:
	if not is_instance_valid(_capsule) or not is_instance_valid(_damage_seams): return false
	_repaired = repaired
	_damage_seams.visible = not repaired
	_capsule.set_hatch_open(repaired)
	return true


func set_presentation_camera(camera: Camera3D) -> bool:
	if not is_instance_valid(_capsule) or not _capsule.set_presentation_camera(camera): return false
	_actual_view = camera
	return true


func presentation_state() -> Dictionary:
	return {"family": "act1_lunar_theatre_salvage", "repaired": _repaired,
		"damage_seams_visible": is_instance_valid(_damage_seams) and _damage_seams.visible,
		"capsule": _capsule.presentation_state() if is_instance_valid(_capsule) else {}}


func capsule_world_corners() -> Array[Vector3]:
	if not is_inside_tree() or not is_instance_valid(_capsule): return [Vector3.INF]
	var points: Array[Vector3] = _capsule.world_corners()
	if _damage_seams.is_visible_in_tree():
		for child: Node in _damage_seams.get_children():
			if child is MeshInstance3D: points.append_array(_box_points((child as MeshInstance3D).get_aabb(), (child as MeshInstance3D).global_transform))
	return _complete_world_aabb(points)


func world_corners() -> Array[Vector3]:
	# Complete scenic reserves may crop; these are not the required local union.
	if not is_inside_tree() or not is_instance_valid(_actual_view) or _actual_view.get_viewport() != get_viewport() or get_viewport().get_camera_3d() != _actual_view: return [Vector3.INF]
	var points: Array[Vector3] = capsule_world_corners()
	points.append_array(_box_points(_floor_overlay.get_aabb(), _floor_overlay.global_transform))
	for sprite: Sprite3D in _sprites:
		if not sprite.is_visible_in_tree(): continue
		var size: Vector2 = Vector2(sprite.texture.get_size()) * sprite.pixel_size
		var native_scale: Vector3 = sprite.global_basis.get_scale()
		var centre: Vector3 = sprite.global_position + _actual_view.global_basis.x * sprite.offset.x * sprite.pixel_size * native_scale.x + _actual_view.global_basis.y * sprite.offset.y * sprite.pixel_size * native_scale.y
		for x: float in [-0.5, 0.5]:
			for y: float in [-0.5, 0.5]:
				for depth: float in [-0.001, 0.001]: points.append(centre + _actual_view.global_basis.x * size.x * native_scale.x * x + _actual_view.global_basis.y * size.y * native_scale.y * y + _actual_view.global_basis.z * depth)
	return points


static func _box_points(bounds: AABB, frame: Transform3D) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]: points.append(frame * Vector3(x, y, z))
	return points


static func _complete_world_aabb(points: Array[Vector3]) -> Array[Vector3]:
	if points.is_empty(): return []
	var minimum: Vector3 = points[0]
	var maximum: Vector3 = points[0]
	for point: Vector3 in points:
		if not point.is_finite(): return [Vector3.INF]
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return _box_points(AABB(minimum, maximum - minimum), Transform3D.IDENTITY)
