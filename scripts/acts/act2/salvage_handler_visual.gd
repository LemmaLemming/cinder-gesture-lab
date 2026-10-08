class_name Act2SalvageHandlerVisual
extends "res://scripts/acts/act2/ray_scout_visual.gd"
## Original compact five-legged work-machine, derived from selected G10 v2.
## The parent poses one fixed local +Z reach. No mirror or warning tracking.
## Shared lane, actor gate and parent clock remain the only combat authority.

const HANDLER_CASE_CENTER: Vector3 = Vector3(0.0, 0.69, -0.21)
const HANDLER_SHOULDER: Vector3 = Vector3(0.0, 0.60, 0.16)
const HANDLER_ACTIVE_WRIST: Vector3 = Vector3(0.0, 0.16, 3.52)

var _handler_upper: MeshInstance3D
var _handler_lower: MeshInstance3D
var _handler_sleeve: MeshInstance3D
var _handler_rod: MeshInstance3D
var _handler_elbow: MeshInstance3D
var _handler_claw: Node3D
var _handler_fingers: Array[Node3D] = []
var _handler_dynamic_segments: Array[MeshInstance3D] = []
var _handler_segment_heights: Dictionary = {}


func _build() -> void:
	_plate = _textured_material(Color(0.25, 0.23, 0.20), Color(0.38, 0.20, 0.12), 32, false)
	_rust = _textured_material(Color(0.28, 0.14, 0.09), Color(0.42, 0.23, 0.13), 32, false)
	_black = _material(Color(0.075, 0.071, 0.067))
	_brass = _material(Color(0.48, 0.38, 0.23))
	_rubber = _textured_material(Color(0.10, 0.10, 0.092), Color(0.17, 0.16, 0.14), 16, true)
	_pale = _material(Color(0.57, 0.55, 0.47))
	_chassis = _pivot(self, "FiveLegChassis", Vector3.ZERO)
	_case = _pivot(_chassis, "LowHandlerCase", HANDLER_CASE_CENTER)
	var belly: MeshInstance3D = _cylinder(_case, "FacetedWorkBelly", 0.48, 0.22, _plate, 0.40, 10)
	belly.scale.z = 0.83
	_readability_panel(belly)
	var belly_rim: MeshInstance3D = _cylinder(_case, "BellyRetainingRim", 0.49, 0.032, _black, 0.49, 10)
	belly_rim.scale.z = 0.83
	belly_rim.position.y = -0.115
	_readability_panel(belly_rim)
	var hood: MeshInstance3D = _cylinder(_case, "LowFacetedHood", 0.66, 0.135, _plate, 0.48, 12)
	hood.position.y = 0.345
	hood.scale.z = 0.84
	_readability_panel(hood)
	var hood_rim: MeshInstance3D = _cylinder(_case, "HandlerHoodRim", 0.675, 0.030, _black, 0.675, 12)
	hood_rim.position.y = 0.273
	hood_rim.scale.z = 0.84
	_readability_panel(hood_rim)
	for index: int in range(8):
		var angle: float = TAU * float(index) / 8.0
		_box(_case, "HoodRivet_%02d" % index, Vector3(0.026, 0.020, 0.026), Vector3(cos(angle) * 0.59, 0.297, sin(angle) * 0.49), _brass)
	for side: float in [-1.0, 1.0]:
		_readability_panel(_box(_case, "SidePlateLeft" if side < 0.0 else "SidePlateRight", Vector3(0.045, 0.23, 0.61), Vector3(side * 0.43, -0.015, -0.01), _rust))
		var post: MeshInstance3D = _cylinder(_case, "HoodPostLeft" if side < 0.0 else "HoodPostRight", 0.024, 0.28, _brass, 0.024, 6)
		post.position = Vector3(side * 0.39, 0.145, -0.27)
		for row: int in range(3):
			_box(_case, "SideFastener_%s_%d" % ["L" if side < 0.0 else "R", row], Vector3(0.018, 0.029, 0.029), Vector3(side * 0.46, -0.075 + row * 0.072, 0.16), _brass)
	_build_handler_operator()
	_build_handler_mount()
	_legs.append(_build_handler_leg("FrontLeftSupport", Vector3(-0.38, 0.60, -0.03), Vector3(-0.61, 0.31, 0.23), Vector3(-0.75, 0.045, 0.34)))
	_legs.append(_build_handler_leg("FrontRightSupport", Vector3(0.38, 0.60, -0.03), Vector3(0.61, 0.31, 0.23), Vector3(0.75, 0.045, 0.34)))
	_legs.append(_build_handler_leg("MiddleLeftSupport", Vector3(-0.36, 0.60, -0.37), Vector3(-0.62, 0.30, -0.36), Vector3(-0.75, 0.045, -0.35)))
	_legs.append(_build_handler_leg("MiddleRightSupport", Vector3(0.36, 0.60, -0.37), Vector3(0.62, 0.30, -0.36), Vector3(0.75, 0.045, -0.35)))
	_legs.append(_build_handler_leg("RearSupport", Vector3(0.0, 0.62, -0.47), Vector3(0.0, 0.32, -0.66), Vector3(0.0, 0.045, -0.84)))
	_handler_upper = _handler_segment(_chassis, "SlidingUpperLever", 0.059, _plate, 8)
	_handler_lower = _handler_segment(_chassis, "TelescopingToolLever", 0.044, _black, 8)
	_handler_sleeve = _handler_segment(_chassis, "ElasticToolSleeve", 0.037, _rubber, 8)
	_handler_rod = _handler_segment(_chassis, "ToolPistonRod", 0.019, _brass, 6)
	_handler_elbow = _handler_sphere(_chassis, "RoundToolElbow", 0.095, Vector3.ZERO, _rust)
	_readability_panel(_handler_elbow)
	_handler_claw = _pivot(_chassis, "GrappleClaw", Vector3.ZERO)
	_readability_panel(_box(_handler_claw, "ClawPalm", Vector3(0.25, 0.10, 0.10), Vector3(0.0, 0.0, 0.06), _plate))
	for side: float in [-1.0, 1.0]:
		var finger: Node3D = _pivot(_handler_claw, "LeftGrappleFinger" if side < 0.0 else "RightGrappleFinger", Vector3(side * 0.105, 0.0, 0.06))
		var first: MeshInstance3D = _cylinder(finger, "FingerLever", 0.023, 0.20, _rust, 0.017, 6)
		_fit_segment(first, Vector3.ZERO, Vector3(side * 0.032, -0.015, 0.13))
		_readability_panel(first)
		var tip: MeshInstance3D = _cylinder(finger, "InturnedClawTip", 0.018, 0.12, _black, 0.009, 6)
		_fit_segment(tip, Vector3(side * 0.032, -0.015, 0.13), Vector3(side * 0.012, -0.065, 0.22))
		_readability_panel(tip)
		_handler_fingers.append(finger)
	_built = true


func _build_handler_operator() -> void:
	# A rounded head-body with two bunches of eight tentacles, no human torso.
	var skin: StandardMaterial3D = _material(Color(0.30, 0.27, 0.22))
	var flesh: StandardMaterial3D = _material(Color(0.35, 0.26, 0.20))
	var head: MeshInstance3D = _handler_sphere(_case, "RoundedMartianHeadBody", 0.145, Vector3(0.0, 0.12, 0.025), skin)
	head.scale.y = 0.82
	_readability_panel(head)
	for side: float in [-1.0, 1.0]:
		_handler_sphere(_case, "LeftDarkEye" if side < 0.0 else "RightDarkEye", 0.027, Vector3(side * 0.061, 0.141, 0.146), _black)
		for index: int in range(8):
			var root_point: Vector3 = Vector3(side * 0.09, 0.058, 0.064 + index * 0.006)
			var bend: Vector3 = Vector3(side * (0.16 + index * 0.008), -0.040 + index * 0.012, 0.19)
			var finish: Vector3 = Vector3(side * (0.23 + index * 0.009), -0.11 + index * 0.010, 0.12)
			var strand: MeshInstance3D = _cylinder(_case, "Tentacle_%s_%02d_A" % ["L" if side < 0.0 else "R", index], 0.012, 0.2, flesh, 0.010, 6)
			_fit_segment(strand, root_point, bend)
			var end: MeshInstance3D = _cylinder(_case, "Tentacle_%s_%02d_B" % ["L" if side < 0.0 else "R", index], 0.010, 0.2, flesh, 0.006, 6)
			_fit_segment(end, bend, finish)
	var beak: MeshInstance3D = _cylinder(_case, "SmallFleshyBeak", 0.027, 0.045, flesh, 0.005, 6)
	beak.position = Vector3(0.0, 0.087, 0.163)
	beak.rotation.x = PI * 0.5


func _build_handler_mount() -> void:
	var mount: Node3D = _pivot(_chassis, "GroundedToolMount", Vector3(0.0, 0.30, 0.0))
	_readability_panel(_box(mount, "LowMountBody", Vector3(0.56, 0.28, 0.32), Vector3.ZERO, _black))
	_readability_panel(_box(mount, "MountRustTop", Vector3(0.59, 0.036, 0.34), Vector3(0.0, 0.156, 0.0), _rust))
	_readability_panel(_box(mount, "ExposedSlidingCoupler", Vector3(0.34, 0.15, 0.035), Vector3(0.0, -0.006, 0.186), _pale))
	for index: int in range(4):
		_readability_panel(_box(mount, "CouplerDisc_%d" % index, Vector3(0.025, 0.13, 0.042), Vector3(-0.115 + index * 0.077, -0.006, 0.205), _rubber))
	_left_door = _pivot(mount, "LeftMountGuard", Vector3(-0.26, 0.0, 0.17))
	_right_door = _pivot(mount, "RightMountGuard", Vector3(0.26, 0.0, 0.17))
	_readability_panel(_box(_left_door, "LeftGuardPlate", Vector3(0.26, 0.22, 0.038), Vector3(0.13, 0.0, 0.016), _rust))
	_readability_panel(_box(_right_door, "RightGuardPlate", Vector3(0.26, 0.22, 0.038), Vector3(-0.13, 0.0, 0.016), _rust))
	for side: float in [-1.0, 1.0]:
		_box(mount, "MountFastenerLeft" if side < 0.0 else "MountFastenerRight", Vector3(0.032, 0.032, 0.026), Vector3(side * 0.24, 0.085, 0.206), _brass)


func _build_handler_leg(node_name: String, hip: Vector3, knee: Vector3, foot: Vector3) -> Dictionary:
	var rig: Node3D = _pivot(_chassis, node_name, Vector3.ZERO)
	var upper: MeshInstance3D = _handler_segment(rig, "UpperSupport", 0.048, _plate, 8)
	var lower: MeshInstance3D = _handler_segment(rig, "LowerSupport", 0.035, _black, 8)
	var sleeve: MeshInstance3D = _handler_segment(rig, "DiscMuscleSleeve", 0.024, _rubber, 6)
	var rod: MeshInstance3D = _handler_segment(rig, "SlidingJointRod", 0.014, _brass, 6)
	var joint: MeshInstance3D = _handler_sphere(rig, "KneeJoint", 0.070, knee, _rust)
	_readability_panel(joint)
	var pin: MeshInstance3D = _cylinder(rig, "KneePin", 0.032, 0.16, _brass, 0.032, 6)
	pin.rotation.z = PI * 0.5
	_readability_panel(_box(rig, "GroundedFoot", Vector3(0.16, 0.09, 0.20), foot, _black))
	_box(rig, "ToePlate", Vector3(0.14, 0.022, 0.10), foot + Vector3(0.0, 0.051, 0.038), _rust)
	return {"hip": hip, "knee_origin": knee, "foot": foot, "upper": upper, "lower": lower, "sleeve": sleeve, "rod": rod, "joint": joint, "pin": pin}


func _handler_segment(parent: Node3D, node_name: String, radius: float, material: StandardMaterial3D, sides: int) -> MeshInstance3D:
	var part: MeshInstance3D = _cylinder(parent, node_name, radius, 0.25, material, radius, sides)
	_readability_panel(part)
	_handler_dynamic_segments.append(part)
	_handler_segment_heights[part.get_instance_id()] = 0.25
	return part


func _handler_sphere(parent: Node3D, node_name: String, radius: float, at: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 6
	return _part(parent, node_name, mesh, material, at)


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
	var local_direction: Vector3 = global_basis.inverse() * _direction
	local_direction.y = 0.0
	if not restore_heading and (phase == "idle" or phase == "approach" or (phase != _last_phase and (phase == "warning" or _last_phase.is_empty()))):
		_body_yaw = atan2(local_direction.x, local_direction.z)
	_last_phase = phase
	_chassis.rotation.y = _body_yaw
	var p: float = _requested_progress
	var plant: float = 0.0
	var collapse: float = 0.0
	var opening: float = 0.0
	var elbow: Vector3 = Vector3(0.19, 0.63, 0.39)
	var wrist: Vector3 = Vector3(0.0, 0.45, 0.69)
	var grip: float = 0.28
	match phase:
		"warning":
			plant = 0.45 + p * 0.45
			elbow = Vector3(0.23, lerpf(0.70, 0.80, p), 0.39)
			wrist = Vector3(0.0, lerpf(0.63, 0.84, p), lerpf(0.55, 0.34, p))
			grip = 0.46
		"lock":
			plant = 1.0
			elbow = Vector3(0.23, 0.80, 0.39)
			wrist = Vector3(0.0, 0.84, 0.34)
			grip = 0.46
		"active":
			# Every active pose reaches the full actual lane from its first tick.
			plant = 1.0
			elbow = Vector3(0.10, 0.38, 1.82)
			wrist = HANDLER_ACTIVE_WRIST
			grip = 0.0
		"recovery":
			var settling: float = smoothstep(0.0, 0.42, p)
			plant = 1.0 - settling * 0.65
			elbow = Vector3(0.10, 0.38, 1.82).lerp(Vector3(0.19, 0.59, 0.48), settling)
			wrist = HANDLER_ACTIVE_WRIST.lerp(Vector3(0.0, 0.32, 0.78), settling)
			opening = 1.0
			grip = 0.32
		"defeated":
			collapse = 1.0
			plant = 0.3
			elbow = Vector3(0.18, 0.18, 0.49)
			wrist = Vector3(0.0, 0.12, 0.76)
			opening = 1.0
			grip = 0.15
	_case.position = HANDLER_CASE_CENTER - Vector3(0.0, collapse * 0.28, 0.0)
	_case.rotation.x = collapse * 0.14
	_left_door.rotation.y = -opening * 1.10
	_right_door.rotation.y = opening * 1.10
	for leg: Dictionary in _legs:
		_pose_handler_leg(leg, plant, collapse)
	var shoulder: Vector3 = HANDLER_SHOULDER - Vector3(0.0, collapse * 0.27, 0.0)
	_fit_segment(_handler_upper, shoulder, elbow)
	_fit_segment(_handler_lower, elbow, wrist)
	var muscle_start: Vector3 = shoulder + Vector3(0.075, -0.06, 0.0)
	var muscle_finish: Vector3 = elbow + Vector3(0.075, -0.02, 0.0)
	_fit_segment(_handler_sleeve, muscle_start, muscle_start.lerp(muscle_finish, 0.62))
	_fit_segment(_handler_rod, muscle_start.lerp(muscle_finish, 0.43), muscle_finish)
	_handler_elbow.position = elbow
	_handler_claw.position = wrist
	for index: int in range(_handler_fingers.size()):
		_handler_fingers[index].rotation.y = -grip if index == 0 else grip
	for material: StandardMaterial3D in _materials:
		material.emission_enabled = hit_flash
		material.emission = Color(0.62, 0.52, 0.39) if hit_flash else Color.BLACK
	_refresh_handler_segment_geometry()
	_recompute_readability()


func _pose_handler_leg(leg: Dictionary, plant: float, collapse: float) -> void:
	var hip: Vector3 = leg["hip"]
	hip.y -= collapse * 0.24
	var knee: Vector3 = leg["knee_origin"]
	knee.y -= plant * 0.025 + collapse * 0.13
	var foot: Vector3 = leg["foot"]
	_fit_segment(leg["upper"] as MeshInstance3D, hip, knee)
	_fit_segment(leg["lower"] as MeshInstance3D, knee, foot)
	(leg["joint"] as MeshInstance3D).position = knee
	(leg["pin"] as MeshInstance3D).position = knee
	var offset: Vector3 = Vector3(0.035, -0.015, 0.025)
	var finish: Vector3 = knee.lerp(foot, 0.44) + offset
	var start: Vector3 = hip + offset
	_fit_segment(leg["sleeve"] as MeshInstance3D, start, start.lerp(finish, 0.58))
	_fit_segment(leg["rod"] as MeshInstance3D, start.lerp(finish, 0.43), finish)


func _refresh_handler_segment_geometry() -> void:
	# Height changes alter CylinderMesh vertices. Refresh only changed cached
	# triangle data, retaining each isolated material used by the shared cutaway.
	for part: MeshInstance3D in _handler_dynamic_segments:
		var height: float = (part.mesh as CylinderMesh).height
		var id: int = part.get_instance_id()
		if _handler_segment_heights[id] == height:
			continue
		_handler_segment_heights[id] = height
		for panel: Dictionary in _readability_panels:
			if panel["part"] == part:
				panel.merge(_readability_geometry(part), true)
				break
