class_name Act2SmokeBankVisual
extends Node3D
## Original low pooling vapour only. Parent owns source/circle/cue/clock/damage.
## Never changes this source-relative root transform or decides a bank lifetime.

const Heath: Script = preload("res://scripts/acts/act2/heath_kit.gd")
const ART_REVISION: String = "a2-smoke-bank-visual-4"
const WispShader: Shader = preload("res://assets/acts/act2/shaders/smoke_wisp.gdshader")
const Footprint: Script = preload("res://scripts/attack_footprint.gd")
const MASK_BOUNDARY_COUNT: int = 64
const MAX_MASK_INPUT_POINTS: int = 512
const MASK_PIXEL_MARGIN: float = 1.5
const WISP_ALPHA: float = 0.86
const DEFAULT_RADIUS: float = 1.05
const MAX_AUTHORED_RADIUS_FRACTION: float = 0.94
const MAX_HEIGHT: float = 0.20
const FLOOR_CLEARANCE: float = 0.010
const ACTIVE_ALPHA: float = 0.64
const INACTIVE_ALPHA: float = 0.018
const PHASES: Array[String] = ["idle", "warning", "lock", "active", "recovery", "clear", "spent"]
# Offsets and horizontal semiaxes are fractions of the parent's fixed radius.
# offset.length + max(semiaxes) <=.94, including every cached sphere vertex.
const PARTS: Array[Dictionary] = [
	# Unequal offsets, elongated overlaps and different heights form one soot
	# bank. No ring of equally spaced lobes or repeated radial petal silhouette.
	{"center": Vector2(-0.12, 0.04), "radii": Vector2(0.68, 0.60), "height": 0.080, "yaw": 0.16, "weight": 1.00},
	{"center": Vector2(0.31, -0.17), "radii": Vector2(0.49, 0.42), "height": 0.095, "yaw": -0.47, "weight": 0.91},
	{"center": Vector2(-0.37, -0.24), "radii": Vector2(0.40, 0.48), "height": 0.075, "yaw": 0.72, "weight": 0.82},
	{"center": Vector2(0.13, 0.37), "radii": Vector2(0.51, 0.40), "height": 0.060, "yaw": -0.29, "weight": 0.76},
	{"center": Vector2(-0.47, 0.29), "radii": Vector2(0.34, 0.35), "height": 0.092, "yaw": 0.48, "weight": 0.58},
	{"center": Vector2(0.51, 0.20), "radii": Vector2(0.32, 0.37), "height": 0.110, "yaw": -0.62, "weight": 0.62},
	{"center": Vector2(-0.05, -0.52), "radii": Vector2(0.40, 0.36), "height": 0.067, "yaw": 0.14, "weight": 0.55},
	{"center": Vector2(0.39, -0.39), "radii": Vector2(0.30, 0.33), "height": 0.052, "yaw": 0.58, "weight": 0.48},
	{"center": Vector2(-0.58, -0.02), "radii": Vector2(0.27, 0.32), "height": 0.085, "yaw": -0.38, "weight": 0.52},
]
# Sparse upper masses, not a ring; every offset.length+max(semiaxes)<.94.
# Geometry is fixed; only supplied phase/progress derives quiet poses.
const WISPS: Array[Dictionary] = [
	{"center": Vector2(-0.30, -0.17), "radii": Vector2(0.45, 0.36), "height": 0.140, "floor": 0.020, "yaw": 0.24, "weight": 1.00},
	{"center": Vector2(0.29, -0.08), "radii": Vector2(0.39, 0.33), "height": 0.180, "floor": 0.010, "yaw": -0.38, "weight": 0.86},
	{"center": Vector2(-0.05, 0.31), "radii": Vector2(0.43, 0.28), "height": 0.120, "floor": 0.025, "yaw": 0.56, "weight": 0.78},
	{"center": Vector2(-0.48, 0.17), "radii": Vector2(0.24, 0.31), "height": 0.160, "floor": 0.016, "yaw": -0.64, "weight": 0.72},
]
var _radius: float = DEFAULT_RADIUS
var _phase: String = "clear"
var _progress: float = 0.0
var _built: bool = false
var _parts: Array[MeshInstance3D] = []
var _materials: Array[StandardMaterial3D] = []
var _wisps: Array[MeshInstance3D] = []
var _wisp_materials: Array[ShaderMaterial] = []
var _masks_ready: bool = false
var _mask_camera: WeakRef
var _mask_camera_transform: Transform3D = Transform3D.IDENTITY
var _mask_camera_projection: Projection = Projection.IDENTITY
var _mask_viewport_size: Vector2 = Vector2.ZERO
var _mask_geometry: Dictionary = {}



func configure_radius(radius: float) -> bool:
	# Immutable after construction. This is only a matching art envelope,
	# never a circle factory or authority to change the parent's footprint.
	if _built or not is_finite(radius) or radius <= 0.0 or radius > DEFAULT_RADIUS:
		return false
	_radius = radius
	return true


func pose(phase: String, normalized_progress: float) -> bool:
	# Reject malformed input before touching the last quiet pose.
	if phase not in PHASES or not is_finite(normalized_progress):
		return false
	_phase = phase
	_progress = clampf(normalized_progress, 0.0, 1.0)
	if _built:
		_apply_pose()
	return true


func _ready() -> void:
	if not _built:
		_build()
	_apply_pose()


func _build() -> void:
	set_meta("art_revision", ART_REVISION)
	set_meta("asset_id", "a2-l3-low-black-vapour")
	set_meta("source_ids", ["G07", "G16", "T05"])
	set_meta("cosmetic_only", true)
	set_meta("collision_role", "none; parent owns fixed circle and exposure")
	for index: int in range(PARTS.size()):
		var material: StandardMaterial3D = Heath._material("cavity").duplicate() as StandardMaterial3D
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		material.no_depth_test = false
		material.cull_mode = BaseMaterial3D.CULL_BACK
		# All nine layers precede default-priority shared cue alpha. Back
		# culling avoids double smoke surfaces; depth tests still respect walls.
		material.render_priority = -12 + index
		# Compensate the cavity texture's muted green channels toward neutral
		# charcoal. The texture stays immutable; opacity belongs to this copy.
		material.albedo_color = Color(0.72, 0.62, 0.66, 0.0)
		var part: MeshInstance3D = Heath._sphere(self, "LowVapourParcel_%02d" % index, Vector3.ZERO, material)
		part.set_meta("smoke_parcel_index", index)
		part.visible = false
		_parts.append(part)
		_materials.append(material)
	for index: int in range(WISPS.size()):
		var material := ShaderMaterial.new()
		material.shader = WispShader
		material.render_priority = 1
		material.set_shader_parameter("masks_ready", false)
		material.set_shader_parameter("wisp_alpha", 0.0)
		var part: MeshInstance3D = Heath._sphere(self, "CharcoalUpperWisp_%02d" % index, Vector3.ZERO, material)
		part.set_meta("smoke_wisp_index", index)
		part.visible = false
		_wisps.append(part)
		_wisp_materials.append(material)
	_built = true


func _apply_pose() -> void:
	_invalidate_readability()
	var growth: float = 0.32
	var vertical: float = 0.55
	var alpha: float = INACTIVE_ALPHA
	var hidden: bool = _phase in ["clear", "idle", "spent"]
	var curl: float = 0.0
	match _phase:
		"active":
			# Full shared circle was already previewed. Smaller cosmetic growth
			# never means that the rest of that circle is safe or uncommitted.
			growth = lerpf(0.32, 1.0, smoothstep(0.0, 0.52, _progress))
			vertical = lerpf(0.84, 1.0, growth)
			alpha = ACTIVE_ALPHA * lerpf(0.82, 1.0, smoothstep(0.0, 0.40, _progress))
			curl = sin(_progress * PI) * 0.04
		"recovery":
			growth = lerpf(1.0, 0.70, smoothstep(0.0, 1.0, _progress))
			vertical = lerpf(1.0, 0.40, smoothstep(0.0, 1.0, _progress))
			# Retain a charcoal core while the existing geometry thins; reach
			# exact zero at the parent's original recovery deadline.
			alpha = ACTIVE_ALPHA * sqrt(1.0 - smoothstep(0.0, 1.0, _progress))
			curl = sin(_progress * PI) * 0.04
		"clear", "idle", "spent":
			alpha = 0.0
	# Warning and lock intentionally share the same inactive faint bank.
	# Required outline/source/tell geometry remains the shared cue's job.
	for index: int in range(_parts.size()):
		var data: Dictionary = PARTS[index]
		var center: Vector2 = data["center"]
		var radii: Vector2 = data["radii"]
		var height: float = float(data["height"]) * vertical
		var part: MeshInstance3D = _parts[index]
		part.position = Vector3(center.x * _radius * growth, FLOOR_CLEARANCE + height * 0.5, center.y * _radius * growth)
		part.scale = Vector3(radii.x * _radius * growth * 2.0, height, radii.y * _radius * growth * 2.0)
		part.rotation = Vector3(0.0, float(data["yaw"]) + curl * (1.0 if index % 2 == 0 else -1.0), 0.0)
		var parcel_alpha: float = alpha * float(data["weight"])
		var tint: Color = _materials[index].albedo_color
		tint.a = parcel_alpha
		_materials[index].albedo_color = tint
		part.visible = not hidden and parcel_alpha > 0.0
	for index: int in range(_wisps.size()):
		var data: Dictionary = WISPS[index]
		var center: Vector2 = data["center"]
		var radii: Vector2 = data["radii"]
		var height: float = float(data["height"]) * vertical
		var part: MeshInstance3D = _wisps[index]
		part.position = Vector3(center.x * _radius * growth, float(data["floor"]) + height * 0.5, center.y * _radius * growth)
		part.scale = Vector3(radii.x * _radius * growth * 2.0, height, radii.y * _radius * growth * 2.0)
		part.rotation = Vector3(0.0, float(data["yaw"]) + curl * (1.0 if index % 2 == 0 else -1.0), 0.0)
		var phase_alpha: float = alpha / ACTIVE_ALPHA if _phase in ["active", "recovery"] else 0.0
		_wisp_materials[index].set_shader_parameter("wisp_alpha", WISP_ALPHA * phase_alpha * float(data["weight"]))
		# Even active meshes stay hidden until this exact pose gets native masks.
		part.visible = false
	set_meta("visual_phase", _phase)
	set_meta("visual_progress", _progress)


func _invalidate_readability() -> void:
	_masks_ready = false
	_mask_camera = null
	_mask_geometry.clear()
	for index: int in range(_wisps.size()):
		_wisps[index].visible = false
		_wisp_materials[index].set_shader_parameter("masks_ready", false)


func apply_readability(camera: Camera3D, hero_points: Array[Vector3], source_points: Array[Vector3], boundary_points: Array[Vector3]) -> bool:
	# Derived presentation only. Parent supplies the current actual Hero vertices,
	# actual native source-glyph vertices, and ordered 64-point circle centerline
	# at the native outline plane. No retained point substitutes for a new pose.
	_invalidate_readability()
	if not _built or not is_inside_tree() or not is_instance_valid(camera) or camera.is_queued_for_deletion() or not camera.is_inside_tree():
		return false
	if camera.projection != Camera3D.PROJECTION_ORTHOGONAL: return false
	if camera.get_world_3d() != get_world_3d() or camera.get_viewport() != get_viewport() or camera.get_viewport().get_camera_3d() != camera:
		return false
	var viewport_size: Vector2 = camera.get_viewport().get_visible_rect().size
	if not viewport_size.is_finite() or viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or boundary_points.size() != MASK_BOUNDARY_COUNT:
		return false
	var hero_projected: PackedVector2Array = _project_points(camera, hero_points, viewport_size)
	var source_projected: PackedVector2Array = _project_points(camera, source_points, viewport_size)
	var boundary_projected: PackedVector2Array = _project_points(camera, boundary_points, viewport_size)
	if hero_projected.is_empty() or source_projected.is_empty() or boundary_projected.size() != MASK_BOUNDARY_COUNT:
		return false
	var hero_rect: Rect2 = _convex_rect(hero_projected)
	var source_rect: Rect2 = _convex_rect(source_projected)
	if not hero_rect.has_area() or not source_rect.has_area() or not _ordered_convex_boundary(boundary_projected):
		return false
	var rim_padding: float = MASK_PIXEL_MARGIN
	var first_height: float = to_local(boundary_points[0]).y
	for index: int in range(MASK_BOUNDARY_COUNT):
		var local: Vector3 = to_local(boundary_points[index])
		if not local.is_finite() or absf(Vector2(local.x, local.z).length() - _radius) > 0.0005 or absf(local.y - first_height) > 0.0005:
			return false
		var next: Vector3 = boundary_points[(index + 1) % MASK_BOUNDARY_COUNT]
		var delta: Vector3 = next - boundary_points[index]
		delta.y = 0.0
		if delta.length_squared() <= 0.00000001:
			return false
		var side: Vector3 = Vector3(-delta.z, 0.0, delta.x).normalized() * float(Footprint.EDGE_WIDTH) * 0.5
		for sign_value: float in [-1.0, 1.0]:
			var edge: Vector3 = boundary_points[index] + side * sign_value
			if camera.is_position_behind(edge): return false
			var projected: Vector2 = camera.unproject_position(edge)
			if not projected.is_finite() or projected.x < 0.0 or projected.y < 0.0 or projected.x > viewport_size.x or projected.y > viewport_size.y: return false
			rim_padding = maxf(rim_padding, projected.distance_to(boundary_projected[index]) + MASK_PIXEL_MARGIN)
	# Padding is in the same native 3D viewport pixel space as SCREEN_UV.
	hero_rect = hero_rect.grow(MASK_PIXEL_MARGIN)
	source_rect = source_rect.grow(MASK_PIXEL_MARGIN)
	var native_transform: Transform3D = camera.get_camera_transform()
	var native_projection: Projection = camera.get_camera_projection()
	_mask_camera = weakref(camera)
	_mask_camera_transform = native_transform
	_mask_camera_projection = native_projection
	_mask_viewport_size = viewport_size
	_mask_geometry = {"hero_rect_pixels": hero_rect, "source_rect_pixels": source_rect, "boundary_pixels": boundary_projected.duplicate(), "rim_padding_pixels": rim_padding, "boundary_count": MASK_BOUNDARY_COUNT}
	for index: int in range(_wisps.size()):
		var material: ShaderMaterial = _wisp_materials[index]
		material.set_shader_parameter("viewport_size_pixels", viewport_size)
		material.set_shader_parameter("hero_rect_pixels", Vector4(hero_rect.position.x, hero_rect.position.y, hero_rect.end.x, hero_rect.end.y))
		material.set_shader_parameter("source_rect_pixels", Vector4(source_rect.position.x, source_rect.position.y, source_rect.end.x, source_rect.end.y))
		material.set_shader_parameter("rim_points_pixels", boundary_projected)
		material.set_shader_parameter("rim_padding_pixels", rim_padding)
		material.set_shader_parameter("mask_camera_origin", native_transform.origin)
		material.set_shader_parameter("mask_camera_right", native_transform.basis.x)
		material.set_shader_parameter("mask_camera_up", native_transform.basis.y)
		material.set_shader_parameter("mask_camera_back", native_transform.basis.z)
		material.set_shader_parameter("mask_projection_scale", Vector2(absf(native_projection.x.x), absf(native_projection.y.y)))
		material.set_shader_parameter("mask_projection_offset", Vector2(absf(native_projection.w.x), absf(native_projection.w.y)))
		material.set_shader_parameter("mask_clip_planes", Vector2(camera.near, camera.far))
		material.set_shader_parameter("masks_ready", true)
		_wisps[index].visible = _phase in ["active", "recovery"] and float(material.get_shader_parameter("wisp_alpha")) > 0.0
	_masks_ready = true
	return true


func _project_points(camera: Camera3D, points: Array[Vector3], viewport_size: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	if points.size() < 3 or points.size() > MAX_MASK_INPUT_POINTS: return result
	for point: Vector3 in points:
		if not point.is_finite() or camera.is_position_behind(point): return PackedVector2Array()
		var projected: Vector2 = camera.unproject_position(point)
		if not projected.is_finite() or projected.x < 0.0 or projected.y < 0.0 or projected.x > viewport_size.x or projected.y > viewport_size.y:
			return PackedVector2Array()
		result.append(projected)
	return result


func _convex_rect(points: PackedVector2Array) -> Rect2:
	var hull: PackedVector2Array = Geometry2D.convex_hull(points)
	if hull.size() < 4 or hull.size() > MASK_BOUNDARY_COUNT + 1: return Rect2()
	var area: float = 0.0
	var low: Vector2 = hull[0]
	var high: Vector2 = hull[0]
	for index: int in range(hull.size() - 1):
		area += hull[index].cross(hull[index + 1])
		low = low.min(hull[index])
		high = high.max(hull[index])
	if absf(area) <= 0.01: return Rect2()
	return Rect2(low, high - low)


func _ordered_convex_boundary(points: PackedVector2Array) -> bool:
	# Reject duplicate, crossed or shuffled triangle vertices. The actual circle
	# centerline is a closed convex polygon in its authored plane/projection.
	var winding: float = 0.0
	for index: int in range(points.size()):
		var along: Vector2 = points[(index + 1) % points.size()] - points[index]
		var next: Vector2 = points[(index + 2) % points.size()] - points[(index + 1) % points.size()]
		var turn: float = along.cross(next)
		if along.length_squared() <= 0.00000001 or absf(turn) <= 0.00000001: return false
		if winding == 0.0: winding = signf(turn)
		elif signf(turn) != winding: return false
	var hull: PackedVector2Array = Geometry2D.convex_hull(points)
	if hull.size() != points.size() + 1: return false
	var first_index: int = -1
	for index: int in range(points.size()):
		if hull[index].distance_squared_to(points[0]) <= 0.00000001:
			first_index = index
			break
	if first_index < 0: return false
	var direction: int = 1 if hull[(first_index + 1) % points.size()].distance_squared_to(points[1]) <= 0.00000001 else -1
	for index: int in range(points.size()):
		var hull_index: int = posmod(first_index + direction * index, points.size())
		if hull[hull_index].distance_squared_to(points[index]) > 0.00000001: return false
	return true


func readability_state() -> Dictionary:
	# Inspection only; no opacity/mask/camera state is transported or replayed.
	return {"masks_ready": _masks_ready, "camera_current": _masks_current(), "geometry": _mask_geometry.duplicate(true)}


func _masks_current() -> bool:
	if not _masks_ready or _mask_camera == null: return false
	var camera: Camera3D = _mask_camera.get_ref() as Camera3D
	if not is_instance_valid(camera) or not camera.is_inside_tree() or camera.is_queued_for_deletion(): return false
	if camera.get_viewport() != get_viewport() or camera.get_viewport().get_camera_3d() != camera or camera.projection != Camera3D.PROJECTION_ORTHOGONAL: return false
	return camera.get_camera_transform().is_equal_approx(_mask_camera_transform) and _projection_equal(camera.get_camera_projection(), _mask_camera_projection) and camera.get_viewport().get_visible_rect().size.is_equal_approx(_mask_viewport_size)


func _projection_equal(a: Projection, b: Projection) -> bool:
	return a.x.is_equal_approx(b.x) and a.y.is_equal_approx(b.y) and a.z.is_equal_approx(b.z) and a.w.is_equal_approx(b.w)


func geometry_stats() -> Dictionary:
	# Native inspection only, including hidden geometry; no proof/transport.
	var base_stats: Dictionary = _mesh_stats(_parts)
	var wisp_stats: Dictionary = _mesh_stats(_wisps)
	return {"constructed": _built, "configured_radius_m": _radius, "part_count": _parts.size() + _wisps.size(), "base_part_count": _parts.size(), "wisp_part_count": _wisps.size(), "distinct_materials": int(base_stats.materials) + int(wisp_stats.materials), "native_vertex_count": int(base_stats.vertices) + int(wisp_stats.vertices), "max_planar_radius_m": maxf(float(base_stats.radius), float(wisp_stats.radius)), "min_height_m": minf(float(base_stats.bottom), float(wisp_stats.bottom)), "max_height_m": maxf(float(base_stats.top), float(wisp_stats.top)), "base_geometry": base_stats, "wisp_geometry": wisp_stats, "authored_radius_ceiling_m": _radius * MAX_AUTHORED_RADIUS_FRACTION, "authored_height_ceiling_m": MAX_HEIGHT, "phase": _phase, "normalized_progress": _progress, "readability": readability_state()}


func _mesh_stats(parts: Array[MeshInstance3D]) -> Dictionary:
	var radius: float = 0.0
	var top: float = 0.0
	var bottom: float = INF
	var vertices_count: int = 0
	var material_ids: Dictionary = {}
	for part: MeshInstance3D in parts:
		var material: Material = part.material_override
		if material != null: material_ids[material.get_instance_id()] = true
		for surface: int in range(part.mesh.get_surface_count()):
			var arrays: Array = part.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for vertex: Vector3 in vertices:
				var point: Vector3 = part.transform * vertex
				radius = maxf(radius, Vector2(point.x, point.z).length())
				top = maxf(top, point.y)
				bottom = minf(bottom, point.y)
				vertices_count += 1
	return {"radius": radius, "bottom": bottom if vertices_count > 0 else 0.0, "top": top, "vertices": vertices_count, "materials": material_ids.size()}
