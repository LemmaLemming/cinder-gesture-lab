class_name Act2HandlingMachineBossVisual
extends "res://scripts/acts/act2/salvage_handler_visual.gd"
## B02's stationary five-legged work machine. Only parent-owned Reach/Place
## and normalized shared phases move the cosmetic arm. No clock or collision.

const BOSS_ACTIONS: Array[String] = ["reach", "place"]
const BOSS_CASE_CENTER: Vector3 = Vector3(0.0, 0.81, -0.23)
const BOSS_SHOULDER: Vector3 = Vector3(0.0, 0.71, 0.03)
const BOSS_REACH_ELBOW: Vector3 = Vector3(0.12, 0.36, 1.76)
const BOSS_REACH_WRIST: Vector3 = Vector3(0.0, 0.08, 3.50)
const BOSS_PLACE_ELBOW: Vector3 = Vector3(0.40, 0.57, 0.29)
const BOSS_PLACE_WRIST: Vector3 = Vector3(0.0, 0.04, 0.0)

var _boss_action: String = "reach"
var _boss_plate: Node3D
var _boss_disengaged_cap: MeshInstance3D


func set_action(action: String) -> bool:
	# Parent selects an actual cycle before posing it. Retain pre-ready selection
	# and preserve it across pose/restore; this setter creates no phase/event.
	if not BOSS_ACTIONS.has(action): return false
	if _boss_action == action: return true
	_boss_action = action
	if _built:
		_apply_pose(_requested_phase, _requested_progress, _direction, _requested_flash, _requested_has_body_yaw, _requested_body_yaw)
	return true


func get_action() -> String:
	return _boss_action


func restore_pose_error(phase: String, progress: float, direction: Vector3, body_yaw: float) -> String:
	var error: String = super.restore_pose_error(phase, progress, direction, body_yaw)
	if not error.is_empty(): return error
	if direction != Vector3.BACK or body_yaw != 0.0:
		return "B02 visual retains its authored local +Z direction and zero body yaw"
	return ""


func restore_boss_pose(action: String, phase: String, progress: float, direction: Vector3, body_yaw: float = 0.0, hit_flash: bool = false) -> bool:
	# Optional whole visual commit. Gameplay transport owns and validates action;
	# rejected input changes neither its retained action nor any existing pose.
	if not BOSS_ACTIONS.has(action) or not restore_pose_error(phase, progress, direction, body_yaw).is_empty(): return false
	_boss_action = action
	_apply_pose(phase, progress, direction, hit_flash, true, body_yaw)
	return true


func _build() -> void:
	# Reuse the corrected Handler's native materials, parts, support and dynamic
	# triangle-cache helpers; build no compact rig or Scout mirror underneath.
	_plate = _textured_material(Color(0.25, 0.23, 0.20), Color(0.38, 0.20, 0.12), 32, false)
	_rust = _textured_material(Color(0.28, 0.14, 0.09), Color(0.42, 0.23, 0.13), 32, false)
	_black = _material(Color(0.075, 0.071, 0.067))
	_brass = _material(Color(0.48, 0.38, 0.23))
	_rubber = _textured_material(Color(0.10, 0.10, 0.092), Color(0.17, 0.16, 0.14), 16, true)
	_pale = _material(Color(0.57, 0.55, 0.47))
	_chassis = _pivot(self, "FiveSupportBossChassis", Vector3.ZERO)
	_case = _pivot(_chassis, "BroadIndustrialCase", BOSS_CASE_CENTER)
	_build_boss_case()
	_build_boss_operator()
	_build_boss_mount()
	_legs.append(_build_handler_leg("FrontLeftSupport", Vector3(-0.48, 0.77, 0.0), Vector3(-0.80, 0.42, 0.28), Vector3(-0.98, 0.045, 0.59)))
	_legs.append(_build_handler_leg("FrontRightSupport", Vector3(0.48, 0.77, 0.0), Vector3(0.80, 0.42, 0.24), Vector3(0.98, 0.045, 0.58)))
	_legs.append(_build_handler_leg("MiddleLeftSupport", Vector3(-0.51, 0.73, -0.44), Vector3(-0.94, 0.35, -0.32), Vector3(-1.07, 0.045, -0.30)))
	_legs.append(_build_handler_leg("MiddleRightSupport", Vector3(0.51, 0.73, -0.44), Vector3(0.94, 0.35, -0.35), Vector3(1.07, 0.045, -0.33)))
	_legs.append(_build_handler_leg("RearSupport", Vector3(0.0, 0.78, -0.60), Vector3(0.0, 0.40, -0.89), Vector3(0.0, 0.045, -1.12)))
	_build_parked_manipulators()
	_handler_upper = _handler_segment(_chassis, "MainUpperLever", 0.068, _plate, 8)
	_handler_lower = _handler_segment(_chassis, "MainSlidingLever", 0.051, _black, 8)
	_handler_sleeve = _handler_segment(_chassis, "MainDiscMuscleSleeve", 0.044, _rubber, 8)
	_handler_rod = _handler_segment(_chassis, "MainBrassPiston", 0.022, _brass, 6)
	_handler_elbow = _handler_sphere(_chassis, "MainManipulatorJoint", 0.105, Vector3.ZERO, _rust)
	_readability_panel(_handler_elbow)
	_build_boss_claw()
	_build_boss_plate()
	_built = true


func _build_boss_case() -> void:
	var belly: MeshInstance3D = _cylinder(_case, "RivetedWorkBelly", 0.61, 0.28, _plate, 0.69, 10)
	belly.scale.z = 0.82
	_readability_panel(belly)
	var rim: MeshInstance3D = _cylinder(_case, "WorkBellyRim", 0.63, 0.032, _black, 0.63, 10)
	rim.position.y = -0.15
	rim.scale.z = 0.82
	_readability_panel(rim)
	var hood: MeshInstance3D = _cylinder(_case, "BroadFacetedCanopy", 0.88, 0.19, _plate, 0.59, 12)
	hood.position.y = 0.35
	hood.scale.z = 0.84
	_readability_panel(hood)
	var hood_rim: MeshInstance3D = _cylinder(_case, "CanopyRetainingEdge", 0.895, 0.032, _black, 0.895, 12)
	hood_rim.position.y = 0.245
	hood_rim.scale.z = 0.84
	_readability_panel(hood_rim)
	for index: int in range(12):
		var angle: float = TAU * float(index) / 12.0
		_box(_case, "CanopyRivet_%02d" % index, Vector3(0.029, 0.022, 0.029), Vector3(cos(angle) * 0.80, 0.278, sin(angle) * 0.67), _brass)
	for side: float in [-1.0, 1.0]:
		_readability_panel(_box(_case, "AngledSideArmorLeft" if side < 0.0 else "AngledSideArmorRight", Vector3(0.06, 0.30, 0.73), Vector3(side * 0.60, -0.015, -0.03), _rust))
		var post: MeshInstance3D = _cylinder(_case, "CanopyPostLeft" if side < 0.0 else "CanopyPostRight", 0.029, 0.37, _brass, 0.029, 6)
		post.position = Vector3(side * 0.56, 0.16, -0.36)
		for row: int in range(4):
			_box(_case, "SideFastener_%s_%d" % ["L" if side < 0.0 else "R", row], Vector3(0.025, 0.027, 0.029), Vector3(side * 0.643, -0.115 + row * 0.075, 0.16), _brass)
		var manifold: MeshInstance3D = _cylinder(_case, "DiscManifoldLeft" if side < 0.0 else "DiscManifoldRight", 0.105, 0.11, _rubber, 0.105, 8)
		manifold.position = Vector3(side * 0.45, -0.23, 0.08)
		manifold.rotation.z = PI * 0.5
		_readability_panel(manifold)
	_readability_panel(_box(_case, "RearCylinderPanel", Vector3(0.83, 0.23, 0.055), Vector3(0.0, -0.025, -0.51), _plate))


func _build_boss_operator() -> void:
	# G10 selected v2: exposed round head-body, dark eyes, beak and two groups
	# of eight short tentacles. No humanoid pilot or anatomical death animation.
	var operator: Node3D = _pivot(_case, "ExposedRoundedOperator", Vector3(0.0, 0.11, 0.90))
	var skin: StandardMaterial3D = _material(Color(0.45, 0.38, 0.29))
	var flesh: StandardMaterial3D = _material(Color(0.44, 0.29, 0.19))
	var head: MeshInstance3D = _handler_sphere(operator, "RoundedMartianHeadBody", 0.25, Vector3.ZERO, skin)
	head.scale.y = 0.80
	_readability_panel(head)
	for side: float in [-1.0, 1.0]:
		_handler_sphere(operator, "LeftDarkEye" if side < 0.0 else "RightDarkEye", 0.042, Vector3(side * 0.097, 0.033, 0.217), _black)
		for index: int in range(8):
			var root_point: Vector3 = Vector3(side * 0.14, -0.10, 0.085 + index * 0.006)
			var bend: Vector3 = Vector3(side * (0.23 + index * 0.015), -0.21 + index * 0.017, 0.27 - index * 0.018)
			var finish: Vector3 = Vector3(side * (0.30 + index * 0.018), -0.34 + index * 0.024, 0.23 - index * 0.018)
			var first: MeshInstance3D = _cylinder(operator, "Tentacle_%s_%02d_A" % ["L" if side < 0.0 else "R", index], 0.020, 0.2, flesh, 0.015, 6)
			_fit_segment(first, root_point, bend)
			var end: MeshInstance3D = _cylinder(operator, "Tentacle_%s_%02d_B" % ["L" if side < 0.0 else "R", index], 0.015, 0.2, flesh, 0.009, 6)
			_fit_segment(end, bend, finish)
	var beak: MeshInstance3D = _cylinder(operator, "ShortFleshyBeak", 0.035, 0.060, flesh, 0.005, 6)
	beak.position = Vector3(0.0, -0.060, 0.246)
	beak.rotation.x = PI * 0.5


func _build_boss_mount() -> void:
	var mount: Node3D = _pivot(_chassis, "LowPlantedToolJoint", Vector3(0.0, 0.18, 0.0))
	_readability_panel(_box(mount, "LowJointCase", Vector3(0.64, 0.24, 0.34), Vector3.ZERO, _black))
	_readability_panel(_box(mount, "JointRustLip", Vector3(0.67, 0.018, 0.36), Vector3(0.0, 0.131, 0.0), _rust))
	_readability_panel(_box(mount, "ExposedLowCoupler", Vector3(0.40, 0.13, 0.040), Vector3(0.0, 0.055, 0.194), _pale))
	for index: int in range(5):
		_readability_panel(_box(mount, "CouplerDisc_%d" % index, Vector3(0.025, 0.12, 0.043), Vector3(-0.145 + index * 0.0725, 0.055, 0.213), _rubber))
	_left_door = _pivot(mount, "LeftJointGuard", Vector3(-0.30, 0.0, 0.19))
	_right_door = _pivot(mount, "RightJointGuard", Vector3(0.30, 0.0, 0.19))
	_readability_panel(_box(_left_door, "LeftGuardPlate", Vector3(0.30, 0.21, 0.039), Vector3(0.15, 0.0, 0.019), _rust))
	_readability_panel(_box(_right_door, "RightGuardPlate", Vector3(0.30, 0.21, 0.039), Vector3(-0.15, 0.0, 0.019), _rust))
	for side: float in [-1.0, 1.0]:
		_box(mount, "JointFastenerLeft" if side < 0.0 else "JointFastenerRight", Vector3(0.034, 0.034, 0.027), Vector3(side * 0.28, 0.075, 0.214), _brass)
	_boss_disengaged_cap = _readability_panel(_box(mount, "DisengagedArmSocket", Vector3(0.22, 0.065, 0.10), Vector3(0.0, -0.02, 0.225), _rust))
	_boss_disengaged_cap.visible = false


func _build_parked_manipulators() -> void:
	# Short folded secondary tools give the working-machine silhouette. These
	# fixed scenic appendages do not preview, sweep or make another attack.
	for side: float in [-1.0, 1.0]:
		var rig: Node3D = _pivot(_chassis, "ParkedManipulatorLeft" if side < 0.0 else "ParkedManipulatorRight", Vector3.ZERO)
		var shoulder: Vector3 = Vector3(side * 0.50, 0.83, -0.17)
		var elbow: Vector3 = Vector3(side * 0.91, 0.95, -0.32)
		var end: Vector3 = Vector3(side * 0.74, 0.73, -0.58)
		var upper: MeshInstance3D = _handler_segment(rig, "ParkedUpperLever", 0.040, _plate, 8)
		var lower: MeshInstance3D = _handler_segment(rig, "ParkedSlidingLever", 0.026, _black, 6)
		_fit_segment(upper, shoulder, elbow)
		_fit_segment(lower, elbow, end)
		_readability_panel(_handler_sphere(rig, "ParkedRoundJoint", 0.063, elbow, _rust))
		_readability_panel(_box(rig, "ParkedRodClamp", Vector3(0.13, 0.075, 0.15), end, _brass))


func _build_boss_claw() -> void:
	_handler_claw = _pivot(_chassis, "ReachGrabClaws", Vector3.ZERO)
	_readability_panel(_box(_handler_claw, "ClawPalm", Vector3(0.30, 0.105, 0.14), Vector3(0.0, 0.0, 0.04), _plate))
	_readability_panel(_box(_handler_claw, "GroundPlantSkid", Vector3(0.15, 0.045, 0.12), Vector3(0.0, -0.0575, 0.16), _black))
	for side: float in [-1.0, 0.0, 1.0]:
		var finger: Node3D = _pivot(_handler_claw, "GrabFinger_%d" % _handler_fingers.size(), Vector3(side * 0.11, 0.0, 0.03))
		var first: MeshInstance3D = _handler_segment(finger, "FingerLever", 0.024, _rust, 6)
		_fit_segment(first, Vector3.ZERO, Vector3(side * 0.032, -0.012, 0.13))
		var tip: MeshInstance3D = _handler_segment(finger, "InturnedClawTip", 0.016, _black, 6)
		_fit_segment(tip, Vector3(side * 0.032, -0.012, 0.13), Vector3(side * 0.012, -0.052, 0.23))
		_handler_fingers.append(finger)


func _build_boss_plate() -> void:
	_boss_plate = _pivot(_chassis, "PlaceWorkPlate", Vector3.ZERO)
	_readability_panel(_box(_boss_plate, "GroundedWorkPlate", Vector3(0.88, 0.08, 0.88), Vector3.ZERO, _plate))
	_readability_panel(_box(_boss_plate, "OxidizedPlateInset", Vector3(0.71, 0.010, 0.71), Vector3(0.0, 0.045, 0.0), _rust))
	for x: float in [-0.35, 0.35]:
		for z: float in [-0.35, 0.35]:
			var rivet: MeshInstance3D = _cylinder(_boss_plate, "PlateRivet_%d" % _boss_plate.get_child_count(), 0.029, 0.018, _brass, 0.029, 6)
			rivet.position = Vector3(x, 0.051, z)
	_readability_panel(_box(_boss_plate, "PlateGripSocket", Vector3(0.16, 0.11, 0.18), Vector3(0.0, 0.085, -0.20), _black))


func _apply_pose(phase: String, progress: float, direction: Vector3, hit_flash: bool, restore_heading: bool, saved_body_yaw: float) -> void:
	# Both authoritative shapes use the same fixed +Z source. No warning-entry
	# heading latch, arbitrary swivel or phase-dependent body/root displacement.
	if not restore_pose_error(phase, progress, direction, saved_body_yaw).is_empty(): return
	_requested_phase = phase
	_requested_progress = progress
	_requested_flash = hit_flash
	_requested_has_body_yaw = restore_heading
	_requested_body_yaw = 0.0
	_body_yaw = 0.0
	_direction = Vector3.BACK
	if not _built: return
	_last_phase = phase
	_chassis.rotation = Vector3.ZERO
	_case.position = BOSS_CASE_CENTER
	_case.rotation = Vector3.ZERO
	var p: float = progress
	var plant: float = 0.15
	var opening: float = 0.0
	var elbow: Vector3 = Vector3(0.28, 0.79, 0.38)
	var wrist: Vector3 = Vector3(0.0, 0.57, 0.75)
	var grip: float = 0.28
	var plate_tilt: float = -0.22
	match phase:
		"warning":
			plant = 0.45 + p * 0.45
			elbow = Vector3(0.28, lerpf(0.87, 1.10, p), 0.30)
			wrist = Vector3(0.0, lerpf(0.75, 1.04, p), lerpf(0.58, 0.29, p))
			grip = 0.45
		"lock":
			plant = 1.0
			elbow = Vector3(0.28, 1.10, 0.30)
			wrist = Vector3(0.0, 1.04, 0.29)
			grip = 0.45
		"active", "recovery":
			# Plant the complete selected endpoint immediately; hold that ground
			# plant throughout recovery instead of inheriting regular-arm retraction.
			plant = 1.0
			elbow = BOSS_REACH_ELBOW if _boss_action == "reach" else BOSS_PLACE_ELBOW
			wrist = BOSS_REACH_WRIST if _boss_action == "reach" else BOSS_PLACE_WRIST
			grip = 0.0
			plate_tilt = 0.0
			opening = 1.0 if phase == "recovery" else 0.0
		"defeated":
			# Local tool disengagement opens the house. The living operator,
			# canopy and five supports remain standing; no Martian death tableau.
			plant = 0.65
			elbow = Vector3(0.46, 0.30, 0.36)
			wrist = Vector3(0.32, 0.08, 0.79) if _boss_action == "reach" else BOSS_PLACE_WRIST
			grip = 0.10
			plate_tilt = 0.0
			opening = 1.0
	_left_door.rotation.y = -opening * 1.15
	_right_door.rotation.y = opening * 1.15
	_boss_disengaged_cap.visible = phase == "defeated"
	_handler_upper.visible = phase != "defeated"
	_handler_sleeve.visible = phase != "defeated"
	_handler_rod.visible = phase != "defeated"
	for leg: Dictionary in _legs: _pose_handler_leg(leg, plant, 0.0)
	_fit_segment(_handler_upper, BOSS_SHOULDER, elbow)
	_fit_segment(_handler_lower, elbow, wrist)
	var muscle_start: Vector3 = BOSS_SHOULDER + Vector3(0.080, -0.055, 0.0)
	var muscle_finish: Vector3 = elbow + Vector3(0.080, -0.02, 0.0)
	_fit_segment(_handler_sleeve, muscle_start, muscle_start.lerp(muscle_finish, 0.62))
	_fit_segment(_handler_rod, muscle_start.lerp(muscle_finish, 0.43), muscle_finish)
	_handler_elbow.position = elbow
	_handler_claw.position = wrist
	_handler_claw.visible = _boss_action == "reach"
	for index: int in range(_handler_fingers.size()):
		_handler_fingers[index].rotation.y = grip * float(index - 1)
	_boss_plate.position = wrist
	_boss_plate.rotation.x = plate_tilt
	_boss_plate.visible = _boss_action == "place"
	for material: StandardMaterial3D in _materials:
		material.emission_enabled = hit_flash
		material.emission = Color(0.62, 0.52, 0.39) if hit_flash else Color.BLACK
	_refresh_handler_segment_geometry()
	_recompute_readability()
