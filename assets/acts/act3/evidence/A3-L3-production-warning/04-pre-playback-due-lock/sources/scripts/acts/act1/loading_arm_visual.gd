class_name Act1LoadingArmVisual
extends Node3D
## Source art only. A tested shared mechanism adapter must drive set_phase().
## This module never owns clocks, reservations, damage, warning footprints or input.

const JIB_LENGTH: float = 2.24
const JIB_PIVOT: Vector3 = Vector3(0, 1.35, 0)
const REST_ANGLE_DEG: float = 34.0
const LOCK_ANGLE_DEG: float = 12.0
const STRIKE_ANGLE_DEG: float = -14.0
const PARKED_AZIMUTH_RAD: float = PI * 0.5
const PARKED_ASSEMBLY_OFFSET: Vector3 = Vector3(-4.4, 0, 0)
const INK: Color = Color("272727")
const SHADE: Color = Color("555555")
const SILVER: Color = Color("939393")
const LIGHT: Color = Color("c1c1c1")

var _built: bool = false
var _phase: String = "inactive"
var _progress: float = 0.0
var _parked: bool = false
var _assembly: Node3D
var _jib: Node3D
var _cable: MeshInstance3D
var _payload: Node3D
var _crank: Node3D
var _materials: Dictionary = {}


func build(parent: Node3D, origin: Vector3) -> void:
	if _built or not is_instance_valid(parent):
		return
	name = "LoadingArmSourceVisual"
	position = origin
	if get_parent() == null:
		parent.add_child(self)
	_built = true
	_assembly = _node(self, "SourceArtAssembly", Vector3.ZERO)
	_build_planted_support()
	_build_jib()
	_build_suspended_load()
	set_phase(_phase, _progress)


func set_parked(parked: bool) -> void:
	# The owner requests this quiet pose only after the shared source is cleared.
	# Live phases always retain their original +Z source geometry and poses.
	_parked = parked
	set_phase(_phase, _progress)


func set_phase(phase: String, progress: float = 0.0) -> void:
	# State and elapsed progress are supplied by the same shared adapter that owns
	# the actual lane and active interval. Unknown state fails to the quiet pose.
	_phase = phase if phase in ["inactive", "warning", "lock", "active", "recovery"] else "inactive"
	_progress = clampf(progress, 0.0, 1.0) if is_finite(progress) else 0.0
	if not _built:
		return
	var angle_deg: float = REST_ANGLE_DEG
	var nose_tilt_deg: float = 0.0
	var cable_length: float = 0.55
	var crank_angle_deg: float = 20.0
	match _phase:
		"warning":
			angle_deg = lerpf(REST_ANGLE_DEG, LOCK_ANGLE_DEG, _progress)
			nose_tilt_deg = lerpf(0.0, -90.0, _progress)
			cable_length = lerpf(0.55, 0.40, _progress)
			crank_angle_deg = lerpf(20.0, -90.0, _progress)
		"lock":
			# Lock is an absolutely held source pose; progress cannot add drift.
			angle_deg = LOCK_ANGLE_DEG
			nose_tilt_deg = -90.0
			cable_length = 0.40
			crank_angle_deg = -90.0
		"active":
			angle_deg = lerpf(LOCK_ANGLE_DEG, STRIKE_ANGLE_DEG, _progress)
			nose_tilt_deg = -90.0
			cable_length = 0.40
			crank_angle_deg = -90.0
		"recovery":
			angle_deg = lerpf(STRIKE_ANGLE_DEG, REST_ANGLE_DEG, _progress)
			nose_tilt_deg = lerpf(-90.0, 0.0, _progress)
			cable_length = lerpf(0.40, 0.55, _progress)
			crank_angle_deg = lerpf(-90.0, 20.0, _progress)
	var angle: float = deg_to_rad(angle_deg)
	# A cleared source parks only its internal artwork at the quiet left edge.
	# Mechanism/art roots keep their original transforms; every live phase puts
	# the assembly back at ZERO and retains the exact original +Z source pose.
	var quiet_parked: bool = _parked and _phase == "inactive"
	_assembly.position = PARKED_ASSEMBLY_OFFSET if quiet_parked else Vector3.ZERO
	var azimuth: float = PARKED_AZIMUTH_RAD if quiet_parked else 0.0
	var side_fold: Basis = Basis(Vector3.UP, azimuth)
	_jib.basis = side_fold * Basis(Vector3.RIGHT, -angle)
	# Rope remains vertical; its attachment and load follow the same azimuth.
	var cable_top: Vector3 = JIB_PIVOT + side_fold * Vector3(0, sin(angle) * JIB_LENGTH, cos(angle) * JIB_LENGTH)
	_cable.position = cable_top + Vector3.DOWN * cable_length * 0.5
	_cable.scale.y = cable_length
	_payload.position = cable_top + Vector3.DOWN * cable_length
	_payload.basis = side_fold * Basis(Vector3.RIGHT, deg_to_rad(nose_tilt_deg))
	_crank.rotation.x = deg_to_rad(crank_angle_deg)


func _build_planted_support() -> void:
	# Keep the required ground source glyph at local origin unobstructed.
	# Its outer ticks reach0.31; feet start at |x|0.36 and the rear brace
	# ends at z-0.37. This opens the base without changing cue depth/geometry.
	var base := _node(_assembly, "HeavyPlantedBase", Vector3.ZERO)
	for side: float in [-1.0, 1.0]:
		var foot_name: String = "PlantedFootLeft" if side < 0.0 else "PlantedFootRight"
		_box(base, foot_name, Vector3(side * 0.45, 0.08, -0.10), Vector3(0.18, 0.16, 0.66), SHADE)
		_box(_assembly, "UprightFrame", Vector3(side * 0.40, 0.74, -0.08), Vector3(0.11, 1.30, 0.14), INK)
		_box(_assembly, "PalePostEdge", Vector3(side * 0.40 - 0.027, 0.77, 0.0), Vector3(0.032, 1.13, 0.02), SILVER)
		_beam(_assembly, "GroundBrace", Vector3(side * 0.45, 0.16, -0.34), Vector3(side * 0.40, 1.10, -0.08), 0.075, SHADE)
	_box(base, "RearPlantedBrace", Vector3(0, 0.08, -0.43), Vector3(1.08, 0.16, 0.12), SHADE)
	_box(_assembly, "TopBearingBeam", JIB_PIVOT, Vector3(0.96, 0.18, 0.23), SILVER)
	var axle := _cylinder(_assembly, "JibAxle", JIB_PIVOT, 0.075, 0.075, 1.02, LIGHT)
	axle.rotation.z = PI * 0.5
	var drum := _cylinder(_assembly, "SideWinchDrum", Vector3(-0.35, 0.87, -0.08), 0.15, 0.15, 0.22, SHADE)
	drum.rotation.z = PI * 0.5
	for x: float in [-0.25, -0.48]:
		var flange := _cylinder(_assembly, "WinchFlange", Vector3(x, 0.87, -0.08), 0.21, 0.21, 0.035, SILVER)
		flange.rotation.z = PI * 0.5
	_crank = _node(_assembly, "CrankPose", Vector3(-0.51, 0.87, -0.08))
	_box(_crank, "CrankLever", Vector3(0, 0.12, 0), Vector3(0.042, 0.28, 0.052), LIGHT)
	_box(_crank, "CrankGrip", Vector3(-0.08, 0.26, 0), Vector3(0.17, 0.062, 0.062), INK)


func _build_jib() -> void:
	_jib = _node(_assembly, "CommittedJibPose", JIB_PIVOT)
	_box(_jib, "LoadingBeam", Vector3(0, 0, JIB_LENGTH * 0.5), Vector3(0.14, 0.16, JIB_LENGTH), SHADE)
	_box(_jib, "BeamPaintedEdge", Vector3(-0.071, 0.046, JIB_LENGTH * 0.5), Vector3(0.012, 0.036, JIB_LENGTH), SILVER)
	_beam(_jib, "TriangularJibStay", Vector3(0, 0.39, 0.03), Vector3(0, 0.08, JIB_LENGTH - 0.1), 0.045, SILVER)
	_box(_jib, "StayRootPlate", Vector3(0, 0.19, 0), Vector3(0.18, 0.46, 0.11), INK)
	var pulley := _cylinder(_jib, "EndPulley", Vector3(0, 0.04, JIB_LENGTH), 0.105, 0.105, 0.20, INK)
	pulley.rotation.z = PI * 0.5
	for x: float in [-0.11, 0.11]:
		var rim := _cylinder(_jib, "PulleyRim", Vector3(x, 0.04, JIB_LENGTH), 0.12, 0.12, 0.025, SILVER)
		rim.rotation.z = PI * 0.5
	# A single thin cable, never a floor marker or attackable weak-point cue.
	_cable = _cylinder(_assembly, "GravityHangingRope", Vector3.ZERO, 0.016, 0.016, 1.0, SILVER)


func _build_suspended_load() -> void:
	_payload = _node(_assembly, "SuspendedLoadingHead", Vector3.ZERO)
	var collar := _cylinder(_payload, "LoadCollar", Vector3(0, -0.10, 0), 0.105, 0.14, 0.16, INK)
	collar.rotation.y = PI * 0.125
	_cylinder(_payload, "LoadBody", Vector3(0, -0.34, 0), 0.16, 0.22, 0.34, SILVER)
	_cylinder(_payload, "BulletLoadNose", Vector3(0, -0.66, 0), 0.22, 0.025, 0.30, LIGHT)
	for y: float in [-0.2, -0.49]:
		_cylinder(_payload, "DarkLoadBand", Vector3(0, y, 0), 0.23, 0.23, 0.045, SHADE)
	for side: float in [-1.0, 1.0]:
		_box(_payload, "LoadSideClamp", Vector3(side * 0.18, -0.35, 0), Vector3(0.085, 0.18, 0.26), INK)


func _node(parent: Node3D, node_name: String, origin: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = node_name
	node.position = origin
	parent.add_child(node)
	return node


func _material(color: Color) -> StandardMaterial3D:
	var key: String = color.to_html()
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.9
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_materials[key] = material
	return _materials[key] as StandardMaterial3D


func _mesh(parent: Node3D, node_name: String, origin: Vector3, shape: Mesh, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	node.position = origin
	node.mesh = shape
	node.material_override = _material(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node


func _box(parent: Node3D, node_name: String, origin: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return _mesh(parent, node_name, origin, shape, color)


func _cylinder(parent: Node3D, node_name: String, origin: Vector3, top: float, bottom: float, height: float, color: Color) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = top
	shape.bottom_radius = bottom
	shape.height = height
	shape.radial_segments = 12
	shape.rings = 1
	return _mesh(parent, node_name, origin, shape, color)


func _beam(parent: Node3D, node_name: String, from: Vector3, to: Vector3, thickness: float, color: Color) -> void:
	var direction: Vector3 = to - from
	var beam := _box(parent, node_name, (from + to) * 0.5, Vector3(thickness, direction.length(), thickness), color)
	beam.quaternion = Quaternion(Vector3.UP, direction.normalized())
