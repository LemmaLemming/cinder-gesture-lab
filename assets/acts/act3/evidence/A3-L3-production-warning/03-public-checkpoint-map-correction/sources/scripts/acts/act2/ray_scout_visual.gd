class_name Act2RayScoutVisual
extends Node3D
## Original Act 2 cosmetic rig. The parent actor supplies every phase clock.
## +Z is the mirror's local forward; the root is the low housing attack point.
## No collision, target groups, warning geometry, damage, timers or processing.

const BODY_CENTER: Vector3 = Vector3(0.0, 0.79, -0.20)
const HIP_HEIGHT: float = 0.74
const MIRROR_RADIUS: float = 0.285
const MIRROR_SECTORS: int = 16
const MIRROR_HINGE_HALF_SPAN: float = 0.31
const POSE_PHASES: Array[String] = ["idle", "approach", "warning", "lock", "active", "recovery", "defeated"]
const BODY_YAW_TOLERANCE: float = 0.000001
const READABILITY_ALPHA: float = 0.14
const READABILITY_EPSILON: float = 0.00001
const MAX_HERO_BOUND_POINTS: int = 16

var _built: bool = false
var _last_phase: String = ""
var _body_yaw: float = 0.0
var _direction: Vector3 = Vector3.BACK
var _requested_phase: String = "idle"
var _requested_progress: float = 0.0
var _requested_flash: bool = false
var _requested_has_body_yaw: bool = false
var _requested_body_yaw: float = 0.0
var _chassis: Node3D
var _case: Node3D
var _mirror_swivel: Node3D
var _mirror_hinge: Node3D
var _left_door: Node3D
var _right_door: Node3D
var _release_shutter: MeshInstance3D
var _aperture_cover: MeshInstance3D
var _mirror_links: Array[MeshInstance3D] = []
var _legs: Array[Dictionary] = []
var _materials: Array[StandardMaterial3D] = []
var _plate: StandardMaterial3D
var _black: StandardMaterial3D
var _rust: StandardMaterial3D
var _brass: StandardMaterial3D
var _rubber: StandardMaterial3D
var _pale: StandardMaterial3D
var _actuator: MeshInstance3D
var _actuator_ribs: Array[MeshInstance3D] = []
var last_readability_error: String = ""
var _readability_panels: Array[Dictionary] = []
var _readability_camera: WeakRef
var _readability_hero_bounds: Array[Vector3] = []


func _ready() -> void:
	if not _built:
		_build()
	_apply_pose(_requested_phase, _requested_progress, _direction, _requested_flash, _requested_has_body_yaw, _requested_body_yaw)


func pose(phase: String, progress: float, direction: Vector3, hit_flash: bool = false) -> void:
	_apply_pose(phase, progress, direction, hit_flash, false, 0.0)


func apply_readability(camera: Camera3D, hero_bounds: Array[Vector3]) -> bool:
	## Derived cosmetics only. Camera-facing world quad points give the exact
	## shared billboard depth; volumetric bounds use their farthest depth.
	## The caller refreshes actual bounds after movement/camera updates. Retained
	## points also reapply after pose/restore; the camera reference is weak.
	last_readability_error = _readability_error(camera, hero_bounds)
	if not last_readability_error.is_empty():
		return false
	_readability_camera = weakref(camera)
	_readability_hero_bounds = hero_bounds.duplicate()
	_recompute_readability()
	return true


func clear_readability() -> void:
	_readability_camera = null
	_readability_hero_bounds.clear()
	for panel: Dictionary in _readability_panels:
		_set_panel_readability(panel, false)
	last_readability_error = ""


func readability_state() -> Dictionary:
	var faded: Array[String] = []
	for panel: Dictionary in _readability_panels:
		var part: MeshInstance3D = panel["part"] as MeshInstance3D
		if not is_instance_valid(part):
			continue
		for entry: Dictionary in panel["materials"]:
			var material: StandardMaterial3D = entry["material"] as StandardMaterial3D
			if material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and material.albedo_color.a < 1.0:
				faded.append(String(get_path_to(part)))
				break
	return {"panel_count": _readability_panels.size(), "faded_panels": faded, "alpha": READABILITY_ALPHA, "context_available": _readability_camera != null and is_instance_valid(_readability_camera.get_ref()) and not _readability_hero_bounds.is_empty()}


func _exit_tree() -> void:
	clear_readability()


func _readability_error(camera: Camera3D, hero_bounds: Array[Vector3]) -> String:
	if not _built or not is_inside_tree() or not is_instance_valid(camera) or not camera.is_inside_tree() or camera.get_world_3d() != get_world_3d():
		return "Readability requires a built rig and live same-world camera"
	if camera.projection != Camera3D.PROJECTION_ORTHOGONAL or not camera.global_position.is_finite() or not camera.global_basis.x.is_finite() or not camera.global_basis.y.is_finite() or not camera.global_basis.z.is_finite():
		return "Readability requires the finite shared orthographic camera"
	if hero_bounds.size() < 3 or hero_bounds.size() > MAX_HERO_BOUND_POINTS:
		return "Readability requires bounded world silhouette points"
	for point: Vector3 in hero_bounds:
		if not point.is_finite() or camera.is_position_behind(point):
			return "Readability world silhouette points must be finite and in front of the camera"
	if _projected_hull(camera, hero_bounds).is_empty():
		return "Readability world silhouette must have positive projected area"
	return ""


func _recompute_readability() -> void:
	if _readability_camera == null:
		return
	var camera: Camera3D = _readability_camera.get_ref() as Camera3D
	if not _readability_error(camera, _readability_hero_bounds).is_empty():
		clear_readability()
		return
	var hero_hull: PackedVector2Array = _projected_hull(camera, _readability_hero_bounds)
	var hero_depth: float = -INF
	for point: Vector3 in _readability_hero_bounds:
		hero_depth = maxf(hero_depth, -camera.to_local(point).z)
	for panel: Dictionary in _readability_panels:
		# Existing segment posing changes only this eligible cylinder's height.
		# Refresh its derived triangles without reallocating any material.
		if panel["part"] == _actuator:
			panel.merge(_readability_geometry(_actuator), true)
		_set_panel_readability(panel, _panel_occludes(camera, panel, hero_hull, hero_depth))


func _projected_hull(camera: Camera3D, world_points: Array[Vector3]) -> PackedVector2Array:
	var screen_points := PackedVector2Array()
	for point: Vector3 in world_points:
		if not point.is_finite() or camera.is_position_behind(point):
			return PackedVector2Array()
		var screen: Vector2 = camera.unproject_position(point)
		if not screen.is_finite():
			return PackedVector2Array()
		screen_points.append(screen)
	var hull: PackedVector2Array = Geometry2D.convex_hull(screen_points)
	if hull.size() > 1 and hull[0].is_equal_approx(hull[hull.size() - 1]):
		hull.remove_at(hull.size() - 1)
	return hull if hull.size() >= 3 and _polygon_area(hull) > READABILITY_EPSILON else PackedVector2Array()


func _polygon_area(polygon: PackedVector2Array) -> float:
	var area: float = 0.0
	for index: int in range(polygon.size()):
		area += polygon[index].cross(polygon[(index + 1) % polygon.size()])
	return absf(area) * 0.5


func _panel_occludes(camera: Camera3D, panel: Dictionary, hero_hull: PackedVector2Array, hero_depth: float) -> bool:
	var part: MeshInstance3D = panel["part"] as MeshInstance3D
	if not is_instance_valid(part) or not part.is_visible_in_tree():
		return false
	var world_points: Array[Vector3] = []
	for vertex: Vector3 in panel["vertices"]:
		world_points.append(part.global_transform * vertex)
	var panel_hull: PackedVector2Array = _projected_hull(camera, world_points)
	if panel_hull.is_empty():
		return false
	var overlaps: Array[PackedVector2Array] = Geometry2D.intersect_polygons(hero_hull, panel_hull)
	for polygon: PackedVector2Array in overlaps:
		if polygon.size() < 3 or _polygon_area(polygon) <= READABILITY_EPSILON:
			continue
		var center := Vector2.ZERO
		for point: Vector2 in polygon:
			center += point
		center /= float(polygon.size())
		if _panel_before_hero(camera, panel, center, hero_depth):
			return true
		# Interior samples avoid edge-only contacts and find tilted panels whose
		# nearer portion differs from the overlap centroid. Actual mesh triangles
		# establish foreground depth, rather than an unrelated AABB corner.
		for point: Vector2 in polygon:
			if _panel_before_hero(camera, panel, center.lerp(point, 0.75), hero_depth):
				return true
	return false


func _panel_before_hero(camera: Camera3D, panel: Dictionary, screen: Vector2, hero_depth: float) -> bool:
	var part: MeshInstance3D = panel["part"] as MeshInstance3D
	var inverse: Transform3D = part.global_transform.affine_inverse()
	var origin: Vector3 = inverse * camera.project_ray_origin(screen)
	var direction: Vector3 = inverse.basis * camera.project_ray_normal(screen)
	var vertices: PackedVector3Array = panel["vertices"]
	var indices: PackedInt32Array = panel["indices"]
	for index: int in range(0, indices.size(), 3):
		var hit: Variant = Geometry3D.ray_intersects_triangle(origin, direction, vertices[indices[index]], vertices[indices[index + 1]], vertices[indices[index + 2]])
		if hit is Vector3:
			var depth: float = -camera.to_local(part.global_transform * hit).z
			if depth > 0.0 and depth < hero_depth - READABILITY_EPSILON:
				return true
	return false


func _set_panel_readability(panel: Dictionary, faded: bool) -> void:
	for entry: Dictionary in panel["materials"]:
		var material: StandardMaterial3D = entry["material"] as StandardMaterial3D
		var color: Color = entry["base_color"]
		color.a = minf(color.a, READABILITY_ALPHA) if faded else color.a
		material.albedo_color = color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if faded else int(entry["base_transparency"])


func _readability_panel(part: MeshInstance3D) -> MeshInstance3D:
	# Once per mesh: isolate each effective material while keeping its palette
	# and immutable textures. Surface overrides preserve the mirror's four-color
	# mesh resource; material ALPHA remains supported by Compatibility.
	var materials: Array[Dictionary] = []
	var override_source: StandardMaterial3D = part.material_override as StandardMaterial3D
	if override_source != null:
		var override_entry: Dictionary = _readability_material(override_source)
		part.material_override = override_entry["material"] as StandardMaterial3D
		materials.append(override_entry)
	for surface: int in range(part.mesh.get_surface_count()):
		if override_source == null:
			var surface_source: StandardMaterial3D = part.get_surface_override_material(surface) as StandardMaterial3D
			if surface_source == null:
				surface_source = part.mesh.surface_get_material(surface) as StandardMaterial3D
			var surface_entry: Dictionary = _readability_material(surface_source)
			part.set_surface_override_material(surface, surface_entry["material"] as StandardMaterial3D)
			materials.append(surface_entry)
	var panel: Dictionary = {"part": part, "materials": materials}
	panel.merge(_readability_geometry(part))
	_readability_panels.append(panel)
	return part


func _readability_geometry(part: MeshInstance3D) -> Dictionary:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	for surface: int in range(part.mesh.get_surface_count()):
		var arrays: Array = part.mesh.surface_get_arrays(surface)
		var surface_vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var surface_indices := PackedInt32Array()
		if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array:
			surface_indices = arrays[Mesh.ARRAY_INDEX]
		# The authored mirror palette surfaces are unindexed triangles.
		if surface_indices.is_empty():
			for index: int in range(surface_vertices.size()):
				surface_indices.append(index)
		var vertex_offset: int = vertices.size()
		vertices.append_array(surface_vertices)
		for index: int in surface_indices:
			indices.append(vertex_offset + index)
	return {"vertices": vertices, "indices": indices}


func _readability_material(source: StandardMaterial3D) -> Dictionary:
	var material: StandardMaterial3D = source.duplicate() as StandardMaterial3D
	_materials.append(material) # Retain the existing parent-supplied hit flash.
	return {"material": material, "base_color": source.albedo_color, "base_transparency": source.transparency}


func get_body_yaw() -> float:
	return _body_yaw


func restore_pose_error(phase: String, progress: float, direction: Vector3, body_yaw: float) -> String:
	if not POSE_PHASES.has(phase) or not is_finite(progress) or progress < 0.0 or progress > 1.0:
		return "Invalid restored Scout visual phase/progress"
	if not direction.is_finite() or direction.y != 0.0 or absf(direction.length_squared() - 1.0) > 0.00001:
		return "Restored Scout visual direction must be normalized and planar"
	# atan2 produces [-PI, PI]; permit only a tiny JSON parser boundary error.
	# Retain the saved value rather than wrapping it into a different latch.
	if not is_finite(body_yaw) or absf(body_yaw) > PI + BODY_YAW_TOLERANCE:
		return "Restored Scout visual body yaw must be finite in [-PI, PI] within transport tolerance"
	return ""


func restore_pose(phase: String, progress: float, direction: Vector3, body_yaw: float, hit_flash: bool = false) -> bool:
	if not restore_pose_error(phase, progress, direction, body_yaw).is_empty():
		return false
	_apply_pose(phase, progress, direction, hit_flash, true, body_yaw)
	return true


func _apply_pose(phase: String, progress: float, direction: Vector3, hit_flash: bool, restore_heading: bool, saved_body_yaw: float) -> void:
	_requested_phase = phase
	_requested_progress = clampf(progress, 0.0, 1.0) if is_finite(progress) else 0.0
	_requested_flash = hit_flash
	_requested_has_body_yaw = restore_heading
	_requested_body_yaw = saved_body_yaw
	if restore_heading:
		_body_yaw = saved_body_yaw
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if flat.is_finite() and flat.length_squared() > 0.000001:
		_direction = flat.normalized()
	if not _built:
		return
	var local_direction: Vector3 = _direction
	local_direction = global_basis.inverse() * _direction
	local_direction.y = 0.0
	var target_yaw: float = atan2(local_direction.x, local_direction.z)
	# Plant the support orientation at warning entry. The mirror alone follows
	# subsequent warning calls; the parent's locked direction holds it still.
	# Explicit restoration preserves the warning-entry plant even on a fresh
	# rig. Normal first-pose facing retains its original initialization rule;
	# restored and subsequent locked/active/recovery poses retain their plant.
	if not restore_heading:
		if phase != _last_phase and (phase == "warning" or _last_phase.is_empty()):
			_body_yaw = target_yaw
		if phase == "idle" or phase == "approach":
			_body_yaw = target_yaw
	_last_phase = phase
	_chassis.rotation.y = _body_yaw
	_mirror_swivel.rotation.y = wrapf(target_yaw - _body_yaw, -PI, PI)
	var p: float = _requested_progress
	var fold: float = 0.0
	var collapse: float = 0.0
	var plant: float = 0.0
	var case_tilt: float = 0.0
	var mirror_tilt: float = -0.62
	match phase:
		"warning":
			plant = 0.45 + p * 0.45
			mirror_tilt = lerpf(-0.40, -0.24, p)
		"lock":
			plant = 1.0
			mirror_tilt = 0.0
		"active":
			plant = 1.0
			mirror_tilt = -0.045
			case_tilt = 0.025
		"recovery":
			plant = 1.0
			fold = 1.0
			mirror_tilt = -1.27
			case_tilt = -0.025 * (1.0 - p)
		"defeated":
			collapse = 0.85 + 0.15 * p
			fold = 0.70
			mirror_tilt = -1.08
			case_tilt = 0.20
	_case.position = BODY_CENTER - Vector3.UP * 0.31 * collapse
	_case.rotation = Vector3(case_tilt, 0.0, 0.12 * collapse)
	var mirror_forward: float = 0.30 if fold > 0.0 else 0.54
	_mirror_swivel.position = Vector3(0.0, 0.65 - 0.10 * collapse, mirror_forward)
	_mirror_hinge.rotation.x = mirror_tilt
	_left_door.rotation.y = -1.18 * fold
	_right_door.rotation.y = 1.18 * fold
	_release_shutter.visible = phase == "active"
	# A physical camera shutter covers the idle aperture; warning exposes the
	# pale mirror immediately. This is body articulation, not a shared cue.
	_aperture_cover.visible = phase == "idle" or phase == "approach"
	for index: int in range(_mirror_links.size()):
		var side: float = -1.0 if index == 0 else 1.0
		var link_start: Vector3 = Vector3(side * 0.37, 0.59 - collapse * 0.31, 0.13)
		var link_end: Vector3 = _mirror_swivel.position + _mirror_swivel.basis * Vector3(side * MIRROR_HINGE_HALF_SPAN, 0.0, -0.015)
		_fit_segment(_mirror_links[index], link_start, link_end)
	for leg: Dictionary in _legs:
		_pose_leg(leg, plant, collapse)
	var actuator_start: Vector3 = Vector3(0.0, 0.32, -0.16)
	var actuator_end: Vector3 = Vector3(0.12, 0.67 - collapse * 0.26, -0.30)
	_fit_segment(_actuator, actuator_start, actuator_end)
	for index: int in range(_actuator_ribs.size()):
		var rib: MeshInstance3D = _actuator_ribs[index]
		rib.position = actuator_start.lerp(actuator_end, (float(index) + 0.5) / _actuator_ribs.size())
		rib.basis = _actuator.basis
	for material: StandardMaterial3D in _materials:
		material.emission_enabled = hit_flash
		material.emission = Color(0.62, 0.52, 0.39) if hit_flash else Color.BLACK
	_recompute_readability()


func _build() -> void:
	_plate = _textured_material(Color(0.25, 0.23, 0.20), Color(0.38, 0.20, 0.12), 32, false)
	_rust = _textured_material(Color(0.28, 0.14, 0.09), Color(0.42, 0.23, 0.13), 32, false)
	_black = _material(Color(0.075, 0.071, 0.067))
	_brass = _material(Color(0.48, 0.38, 0.23))
	_rubber = _textured_material(Color(0.10, 0.10, 0.092), Color(0.17, 0.16, 0.14), 16, true)
	_pale = _material(Color(0.66, 0.63, 0.53))
	_chassis = _pivot(self, "ThreeLegChassis", Vector3.ZERO)
	_case = _pivot(_chassis, "RivetedCameraCase", BODY_CENTER)
	_readability_panel(_box(_case, "CameraCase", Vector3(1.01, 0.45, 0.59), Vector3.ZERO, _plate))
	_readability_panel(_box(_case, "Undercase", Vector3(0.77, 0.13, 0.48), Vector3(0.0, -0.26, -0.015), _black))
	_readability_panel(_box(_case, "FrontBracket", Vector3(0.82, 0.035, 0.06), Vector3(0.0, -0.20, 0.33), _brass))
	for sign_value: float in [-1.0, 1.0]:
		_readability_panel(_box(_case, "SideArmour", Vector3(0.04, 0.32, 0.42), Vector3(sign_value * 0.525, 0.0, -0.025), _rust))
		_box(_case, "CornerBracket", Vector3(0.055, 0.44, 0.065), Vector3(sign_value * 0.455, 0.0, 0.31), _black)
		for row: int in range(3):
			_box(_case, "CornerRivet", Vector3(0.043, 0.043, 0.030), Vector3(sign_value * 0.455, -0.145 + row * 0.145, 0.348), _brass)
		var cap: MeshInstance3D = _cylinder(_case, "SidePivotCap", 0.10, 0.045, _black)
		cap.position = Vector3(sign_value * 0.57, -0.035, -0.005)
		cap.rotation.z = PI * 0.5
	var roof: MeshInstance3D = _cylinder(_case, "FacetedSurveyHood", 0.39, 0.12, _plate, 0.205, 12)
	_readability_panel(roof)
	roof.position.y = 0.275
	var roof_cap: MeshInstance3D = _cylinder(_case, "HoodRim", 0.22, 0.035, _black, 0.22, 12)
	_readability_panel(roof_cap)
	roof_cap.position.y = 0.352
	var mast: MeshInstance3D = _cylinder(_case, "ShortSurveyMast", 0.026, 0.18, _black, 0.020, 6)
	mast.position.y = 0.47
	_box(_case, "MastCap", Vector3(0.05, 0.035, 0.05), Vector3(0.0, 0.575, 0.0), _brass)
	for index: int in range(5):
		_readability_panel(_box(_case, "RearCoolingRib", Vector3(0.045, 0.26, 0.08), Vector3(-0.24 + index * 0.12, -0.015, -0.33), _black))
	_build_housing()
	_build_mirror()
	_legs.append(_build_leg("LeftSupport", -1.0, false))
	_legs.append(_build_leg("RightSupport", 1.0, false))
	_legs.append(_build_leg("RearSupport", 0.0, true))
	_actuator = _cylinder(_chassis, "FlexibleHousingActuator", 0.067, 0.30, _rubber, 0.067, 8)
	_readability_panel(_actuator)
	for index: int in range(6):
		var rib: MeshInstance3D = _cylinder(_chassis, "ActuatorRib", 0.086, 0.025, _black, 0.086, 8)
		_readability_panel(rib)
		_actuator_ribs.append(rib)
	_built = true


func _build_housing() -> void:
	var housing: Node3D = _pivot(_chassis, "FixedLowMirrorHousing", Vector3(0.0, 0.30, 0.0))
	_readability_panel(_box(housing, "HousingBlock", Vector3(0.66, 0.32, 0.42), Vector3.ZERO, _black))
	_readability_panel(_box(housing, "HousingTopPlate", Vector3(0.70, 0.045, 0.43), Vector3(0.0, 0.18, 0.0), _rust))
	_readability_panel(_box(housing, "LowCouplerInterior", Vector3(0.42, 0.18, 0.035), Vector3(0.0, 0.0, 0.226), _pale))
	for index: int in range(4):
		_readability_panel(_box(housing, "CouplerInteriorRib", Vector3(0.037, 0.15, 0.055), Vector3(-0.135 + index * 0.09, 0.0, 0.255), _black))
	_left_door = _pivot(housing, "LeftHousingDoor", Vector3(-0.30, 0.0, 0.21))
	_right_door = _pivot(housing, "RightHousingDoor", Vector3(0.30, 0.0, 0.21))
	_readability_panel(_box(_left_door, "LeftDoorPlate", Vector3(0.30, 0.25, 0.040), Vector3(0.15, 0.0, 0.015), _rust))
	_readability_panel(_box(_right_door, "RightDoorPlate", Vector3(0.30, 0.25, 0.040), Vector3(-0.15, 0.0, 0.015), _rust))
	_box(_left_door, "LeftDoorRivet", Vector3(0.045, 0.045, 0.035), Vector3(0.06, 0.075, 0.045), _brass)
	_box(_right_door, "RightDoorRivet", Vector3(0.045, 0.045, 0.035), Vector3(-0.06, 0.075, 0.045), _brass)


func _build_mirror() -> void:
	_mirror_swivel = _pivot(_chassis, "TrackingMirrorSwivel", Vector3(0.0, 0.65, 0.54))
	_mirror_hinge = _pivot(_mirror_swivel, "FoldingMirrorHinge", Vector3.ZERO)
	var dish: Node3D = _pivot(_mirror_hinge, "SegmentedParabolicMirror", Vector3(0.0, 0.285, 0.0))
	var palette: Array[StandardMaterial3D] = [
		_material(Color(0.56, 0.55, 0.49)), _material(Color(0.73, 0.71, 0.61)),
		_material(Color(0.85, 0.83, 0.72)), _material(Color(0.64, 0.66, 0.62))
	]
	for material: StandardMaterial3D in palette:
		material.roughness = 0.28
		material.metallic = 0.35
	var batches: Array = [[], [], [], []]
	for sector: int in range(MIRROR_SECTORS):
		var a: float = TAU * float(sector) / MIRROR_SECTORS
		var b: float = TAU * float(sector + 1) / MIRROR_SECTORS
		var shade: int = 2 if sector >= 2 and sector <= 6 else (sector % 4)
		for ring_index: int in range(3):
			var inner: float = MIRROR_RADIUS * float(ring_index) / 3.0
			var outer: float = MIRROR_RADIUS * float(ring_index + 1) / 3.0
			var v0: Vector3 = _dish_point(a, inner)
			var v1: Vector3 = _dish_point(a, outer)
			var v2: Vector3 = _dish_point(b, outer)
			var v3: Vector3 = _dish_point(b, inner)
			(batches[shade] as Array).append_array([v0, v1, v2])
			if ring_index > 0:
				(batches[shade] as Array).append_array([v0, v2, v3])
	var mesh: ArrayMesh = ArrayMesh.new()
	for shade: int in range(batches.size()):
		var vertices: Array = batches[shade]
		if vertices.is_empty():
			continue
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
		var normals: PackedVector3Array = PackedVector3Array()
		for _vertex: Variant in vertices:
			normals.append(Vector3.BACK)
		arrays[Mesh.ARRAY_NORMAL] = normals
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, palette[shade])
	_readability_panel(_part(dish, "PolishedMirrorFacets", mesh, null, Vector3.ZERO))
	for sector: int in range(MIRROR_SECTORS):
		var a: float = TAU * float(sector) / MIRROR_SECTORS
		var b: float = TAU * float(sector + 1) / MIRROR_SECTORS
		var rim: MeshInstance3D = _cylinder(dish, "MirrorRetainingRim", 0.014, 0.10, _black, 0.014, 6)
		_fit_segment(rim, _dish_point(a, MIRROR_RADIUS), _dish_point(b, MIRROR_RADIUS))
	for index: int in range(4):
		var angle: float = TAU * float(index) / 4.0
		_box(dish, "MirrorRetainingClip", Vector3(0.064, 0.055, 0.055), _dish_point(angle, MIRROR_RADIUS), _brass)
	_box(dish, "MirrorHub", Vector3(0.060, 0.060, 0.060), Vector3(0.0, 0.0, -0.014), _black)
	_release_shutter = _box(dish, "PhysicalReleaseShutter", Vector3(0.041, 0.041, 0.025), Vector3(0.0, 0.0, 0.023), _pale)
	_release_shutter.visible = false
	_aperture_cover = _cylinder(dish, "PhysicalIdleApertureCover", 0.235, 0.025, _black, 0.235, 12)
	_aperture_cover.position.z = 0.035
	_aperture_cover.rotation.x = PI * 0.5
	for x_sign: float in [-1.0, 1.0]:
		for z_sign: float in [-1.0, 1.0]:
			_box(_aperture_cover, "ApertureCoverRivet", Vector3(0.028, 0.012, 0.028), Vector3(x_sign * 0.105, 0.021, z_sign * 0.105), _brass)
	for sign_value: float in [-1.0, 1.0]:
		_box(_mirror_hinge, "MirrorFork", Vector3(0.040, 0.32, 0.075), Vector3(sign_value * MIRROR_HINGE_HALF_SPAN, 0.12, -0.015), _plate)
		var hinge_pin: MeshInstance3D = _cylinder(_mirror_hinge, "MirrorHingePin", 0.075, 0.085, _brass)
		hinge_pin.position = Vector3(sign_value * MIRROR_HINGE_HALF_SPAN, 0.0, -0.015)
		hinge_pin.rotation.z = PI * 0.5
		_mirror_links.append(_cylinder(_chassis, "MirrorSaddleLink", 0.030, 0.4, _plate, 0.030, 8))


func _build_leg(node_name: String, side: float, rear: bool) -> Dictionary:
	var rig: Node3D = _pivot(_chassis, node_name, Vector3.ZERO)
	var upper: MeshInstance3D = _cylinder(rig, "UpperSupport", 0.065, 0.40, _plate, 0.065, 8)
	var lower: MeshInstance3D = _cylinder(rig, "LowerSupport", 0.047, 0.43, _black, 0.047, 8)
	var piston: MeshInstance3D = _cylinder(rig, "PistonSleeve", 0.028, 0.28, _rust, 0.028, 6)
	var rod: MeshInstance3D = _cylinder(rig, "PistonRod", 0.016, 0.28, _pale, 0.016, 6)
	var knee: MeshInstance3D = _box(rig, "KneeHinge", Vector3(0.15, 0.13, 0.16), Vector3.ZERO, _rust)
	var knee_pin: MeshInstance3D = _cylinder(rig, "KneePin", 0.045, 0.19, _brass, 0.045, 6)
	knee_pin.rotation.z = PI * 0.5
	var foot: Vector3 = Vector3(0.0, 0.045, -0.85) if rear else Vector3(side * 0.82, 0.045, 0.42)
	_box(rig, "GroundedFoot", Vector3(0.16, 0.09, 0.27), foot, _black)
	_box(rig, "FootToePlate", Vector3(0.14, 0.025, 0.13), foot + Vector3(0.0, 0.055, 0.06), _rust)
	var result: Dictionary = {"side": side, "rear": rear, "foot": foot, "upper": upper, "lower": lower, "piston": piston, "rod": rod, "knee": knee, "pin": knee_pin}
	return result


func _pose_leg(leg: Dictionary, plant: float, collapse: float) -> void:
	var side: float = float(leg["side"])
	var rear: bool = bool(leg["rear"])
	var hip: Vector3 = Vector3(0.0, HIP_HEIGHT, -0.40) if rear else Vector3(side * 0.44, HIP_HEIGHT, -0.16)
	hip.y -= collapse * 0.29
	var knee: Vector3 = Vector3(0.0, 0.38, -0.65) if rear else Vector3(side * (0.67 + collapse * 0.045), 0.40, 0.17)
	knee.y -= plant * 0.025 + collapse * 0.19
	var foot: Vector3 = leg["foot"]
	_fit_segment(leg["upper"] as MeshInstance3D, hip, knee)
	_fit_segment(leg["lower"] as MeshInstance3D, knee, foot)
	(leg["knee"] as Node3D).position = knee
	(leg["pin"] as Node3D).position = knee + Vector3(0.0, 0.0, 0.005)
	var piston_start: Vector3 = hip + Vector3(side * 0.045, -0.05, 0.065)
	var piston_end: Vector3 = knee.lerp(foot, 0.45) + Vector3(side * 0.045, 0.0, 0.065)
	_fit_segment(leg["piston"] as MeshInstance3D, piston_start, piston_start.lerp(piston_end, 0.56))
	_fit_segment(leg["rod"] as MeshInstance3D, piston_start.lerp(piston_end, 0.40), piston_end)


func _dish_point(angle: float, radius: float) -> Vector3:
	var depth: float = -0.050 * (1.0 - pow(radius / MIRROR_RADIUS, 2.0))
	return Vector3(cos(angle) * radius, sin(angle) * radius, depth)


func _fit_segment(node: MeshInstance3D, start: Vector3, finish: Vector3) -> void:
	var along: Vector3 = finish - start
	var length: float = maxf(along.length(), 0.0001)
	var axis: Vector3 = along / length
	var reference: Vector3 = Vector3.RIGHT if absf(axis.x) < 0.90 else Vector3.FORWARD
	var side: Vector3 = axis.cross(reference).normalized()
	var forward: Vector3 = side.cross(axis).normalized()
	node.position = (start + finish) * 0.5
	node.basis = Basis(side, axis, forward)
	(node.mesh as CylinderMesh).height = length


func _pivot(parent: Node3D, node_name: String, at: Vector3) -> Node3D:
	var node: Node3D = Node3D.new()
	node.name = node_name
	node.position = at
	parent.add_child(node)
	return node


func _part(parent: Node3D, node_name: String, mesh: Mesh, material: StandardMaterial3D, at: Vector3) -> MeshInstance3D:
	var part: MeshInstance3D = MeshInstance3D.new()
	part.name = node_name
	part.mesh = mesh
	part.material_override = material
	part.position = at
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)
	return part


func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	return _part(parent, node_name, mesh, material, at)


func _cylinder(parent: Node3D, node_name: String, radius: float, height: float, material: StandardMaterial3D, top_radius: float = -1.0, segments: int = 8) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return _part(parent, node_name, mesh, material, Vector3.ZERO)


func _material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	material.metallic = 0.12
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials.append(material)
	return material


func _textured_material(base: Color, oxidation: Color, pixels: int, rubber: bool) -> StandardMaterial3D:
	var image: Image = Image.create(pixels, pixels, false, Image.FORMAT_RGBA8)
	for y: int in range(pixels):
		for x: int in range(pixels):
			var cluster_x: int = x >> 2
			var cluster_y: int = y >> 2
			var cluster: int = (cluster_x * 11 + cluster_y * 7 + cluster_x * cluster_y * 3) % 17
			var color: Color = base
			if cluster == 2 or cluster == 5:
				color = oxidation
			elif cluster == 9:
				color = base.lightened(0.09)
			if rubber and y % 4 == 0:
				color = base.darkened(0.28)
			elif not rubber and y % 12 == 0 and x > 3 and x < pixels - 4:
				color = base.darkened(0.18)
			image.set_pixel(x, y, color)
	var material: StandardMaterial3D = _material(Color.WHITE)
	material.albedo_texture = ImageTexture.create_from_image(image)
	return material
