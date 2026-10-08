class_name Act2SmokeBankVisual
extends Node3D
## Original low pooling vapour only. Parent owns source/circle/cue/clock/damage.
## Never changes this source-relative root transform or decides a bank lifetime.

const Heath: Script = preload("res://scripts/acts/act2/heath_kit.gd")
const ART_REVISION: String = "a2-smoke-bank-visual-3"
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
var _radius: float = DEFAULT_RADIUS
var _phase: String = "clear"
var _progress: float = 0.0
var _built: bool = false
var _parts: Array[MeshInstance3D] = []
var _materials: Array[StandardMaterial3D] = []


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
	_built = true


func _apply_pose() -> void:
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
	set_meta("visual_phase", _phase)
	set_meta("visual_progress", _progress)


func geometry_stats() -> Dictionary:
	# Optional native inspection, not a proof/authority/snapshot. Reports this
	# current cosmetic pose in source-local metres, including hidden parcels.
	var radius: float = 0.0
	var top: float = 0.0
	var bottom: float = INF
	var vertices_count: int = 0
	var material_ids: Dictionary = {}
	for part: MeshInstance3D in _parts:
		var material := part.material_override as StandardMaterial3D
		if material != null:
			material_ids[material.get_instance_id()] = true
		for surface: int in range(part.mesh.get_surface_count()):
			var arrays: Array = part.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for vertex: Vector3 in vertices:
				var point: Vector3 = part.transform * vertex
				radius = maxf(radius, Vector2(point.x, point.z).length())
				top = maxf(top, point.y)
				bottom = minf(bottom, point.y)
				vertices_count += 1
	return {"constructed": _built, "configured_radius_m": _radius, "part_count": _parts.size(), "distinct_materials": material_ids.size(), "native_vertex_count": vertices_count, "max_planar_radius_m": radius, "min_height_m": bottom if vertices_count > 0 else 0.0, "max_height_m": top, "authored_radius_ceiling_m": _radius * MAX_AUTHORED_RADIUS_FRACTION, "authored_height_ceiling_m": MAX_HEIGHT, "phase": _phase, "normalized_progress": _progress}
