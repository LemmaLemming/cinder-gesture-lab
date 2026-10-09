class_name Act2CanisterTenderVisual
extends "res://scripts/acts/act2/ray_scout_visual.gd"
## Original C102/A2-E2 adaptation of G16/T05; not a named novel machine caste.
## Two grounded skids carry one hollow tube and a low reload mount.
## Parent supplies phases/direction/progress/flash; no hazard, timer or processing.

const TENDER_TUBE_PIVOT: Vector3 = Vector3(0.0, 0.635, -0.13)
const TENDER_RAISED_ANGLE: float = -0.54
const TENDER_SUPPORT_BOUND: float = 0.895
const TENDER_TOP_BOUND: float = 1.10

var _tender_tube: Node3D
var _tender_mount: Node3D
var _tender_mount_left: Node3D
var _tender_mount_right: Node3D


func present(phase: String, progress: float, direction: Vector3, hit_flash: bool = false) -> void:
	pose(phase, progress, direction, hit_flash)


func pose_snapshot() -> Dictionary:
	# Portable cosmetics only; the actor/consumer owns the actual saved clock.
	return {"phase": _requested_phase, "phase_progress": _requested_progress, "direction": [_direction.x, _direction.y, _direction.z], "body_yaw": _body_yaw, "hit_flash": _requested_flash}


func _build() -> void:
	_plate = _textured_material(Color(0.24, 0.23, 0.20), Color(0.39, 0.22, 0.13), 32, false)
	_rust = _textured_material(Color(0.28, 0.14, 0.09), Color(0.43, 0.24, 0.13), 32, false)
	_black = _material(Color(0.055, 0.052, 0.047))
	_brass = _material(Color(0.44, 0.35, 0.22))
	_rubber = _textured_material(Color(0.10, 0.10, 0.09), Color(0.16, 0.15, 0.13), 16, true)
	_pale = _material(Color(0.58, 0.55, 0.45))
	_chassis = _pivot(self, "TwoSkidCradle", Vector3.ZERO)
	_case = _pivot(_chassis, "LowReloadDeck", Vector3(0.0, 0.22, -0.06))
	var deck: MeshInstance3D = _cylinder(_case, "FacetedLoadDeck", 0.46, 0.19, _plate, 0.39, 10)
	deck.scale.z = 0.76
	_readability_panel(deck)
	var rim: MeshInstance3D = _cylinder(_case, "DeckRetainingRim", 0.48, 0.032, _black, 0.48, 10)
	rim.position.y = -0.080
	rim.scale.z = 0.76
	_readability_panel(rim)
	for side: float in [-1.0, 1.0]:
		var side_id: String = "Left" if side < 0.0 else "Right"
		_readability_panel(_box(_chassis, side_id + "GroundSkid", Vector3(0.15, 0.10, 1.22), Vector3(side * 0.43, 0.05, 0.0), _black))
		_readability_panel(_box(_chassis, side_id + "SkidSpine", Vector3(0.10, 0.08, 1.12), Vector3(side * 0.43, 0.14, 0.0), _plate))
		for front: float in [-1.0, 1.0]:
			var brace_id: String = side_id + ("Rear" if front < 0.0 else "Front")
			var heel: Vector3 = Vector3(side * 0.60, 0.045, front * 0.46)
			_readability_panel(_box(_chassis, brace_id + "OutriggerPad", Vector3(0.18, 0.09, 0.20), heel, _rust))
			var brace: MeshInstance3D = _cylinder(_chassis, brace_id + "ShortBrace", 0.045, 1.0, _plate, 0.038, 6)
			_fit_segment(brace, Vector3(side * 0.28, 0.31, front * 0.23), heel + Vector3(0.0, 0.045, 0.0))
			_readability_panel(brace)
			_box(_chassis, brace_id + "PadFastener", Vector3(0.028, 0.024, 0.028), heel + Vector3(0.0, 0.057, 0.0), _brass)
		var journal: MeshInstance3D = _cylinder(_chassis, side_id + "TubeJournal", 0.13, 0.055, _rust, 0.13, 10)
		journal.position = Vector3(side * 0.245, 0.57, -0.13)
		journal.rotation.z = PI * 0.5
		_readability_panel(journal)
		_readability_panel(_box(_chassis, side_id + "JournalPedestal", Vector3(0.09, 0.31, 0.17), Vector3(side * 0.245, 0.40, -0.13), _plate))
		_tender_canister(side_id, Vector3(side * 0.29, 0.44, -0.43))
	_build_tender_tube()
	_build_tender_mount()
	_built = true


func _tender_canister(node_name: String, at: Vector3) -> void:
	var pod: Node3D = _pivot(_chassis, node_name + "CanisterRack", at)
	var canister: MeshInstance3D = _cylinder(pod, "DarkCanister", 0.106, 0.40, _black, 0.098, 10)
	_readability_panel(canister)
	for y: float in [-0.145, 0.145]:
		var band: MeshInstance3D = _cylinder(pod, "LowerCanisterBand" if y < 0.0 else "UpperCanisterBand", 0.113, 0.035, _rust, 0.113, 10)
		band.position.y = y
		_readability_panel(band)
	var valve: MeshInstance3D = _cylinder(pod, "ValveStem", 0.027, 0.055, _brass, 0.027, 6)
	valve.position.y = 0.221
	_box(pod, "ValveCrossbar", Vector3(0.12, 0.024, 0.035), Vector3(0.0, 0.253, 0.0), _brass)
	_readability_panel(_box(pod, "RackRetainer", Vector3(0.14, 0.045, 0.045), Vector3(0.0, -0.08, 0.10), _plate))


func _build_tender_tube() -> void:
	_tender_tube = _pivot(_chassis, "LaunchTubeElevation", TENDER_TUBE_PIVOT)
	var tube: MeshInstance3D = _cylinder(_tender_tube, "HollowOxidisedLaunchTube", 0.162, 0.82, _plate, 0.162, 12)
	(tube.mesh as CylinderMesh).cap_top = false
	(tube.mesh as CylinderMesh).cap_bottom = false
	tube.position.z = 0.13
	tube.rotation.x = PI * 0.5
	_readability_panel(tube)
	for index: int in range(3):
		var ring: MeshInstance3D = _cylinder(_tender_tube, "TubeReinforcement_%d" % index, 0.178, 0.055, _rust, 0.178, 12)
		(ring.mesh as CylinderMesh).cap_top = false
		(ring.mesh as CylinderMesh).cap_bottom = false
		ring.position.z = -0.22 + float(index) * 0.33
		ring.rotation.x = PI * 0.5
		_readability_panel(ring)
	var breech: MeshInstance3D = _cylinder(_tender_tube, "ClosedBreechDrum", 0.195, 0.075, _black, 0.195, 12)
	breech.position.z = -0.292
	breech.rotation.x = PI * 0.5
	_readability_panel(breech)
	var lip: TorusMesh = TorusMesh.new()
	lip.inner_radius = 0.135
	lip.outer_radius = 0.185
	lip.rings = 12
	lip.ring_segments = 6
	var muzzle: MeshInstance3D = _part(_tender_tube, "RivetedMuzzleLip", lip, _rust, Vector3(0.0, 0.0, 0.54))
	muzzle.rotation.x = PI * 0.5
	_readability_panel(muzzle)
	var recess: MeshInstance3D = _cylinder(_tender_tube, "ShallowDarkMuzzleRecess", 0.136, 0.024, _black, 0.136, 12)
	recess.position.z = 0.44
	recess.rotation.x = PI * 0.5
	_readability_panel(recess)
	for index: int in range(8):
		var angle: float = TAU * float(index) / 8.0
		_box(_tender_tube, "MuzzleFastener_%02d" % index, Vector3(0.024, 0.024, 0.030), Vector3(cos(angle) * 0.167, sin(angle) * 0.167, 0.537), _brass)
	_readability_panel(_box(_tender_tube, "ReloadFeedHousing", Vector3(0.21, 0.11, 0.18), Vector3(0.0, 0.17, -0.18), _plate))
	_box(_tender_tube, "FeedSeam", Vector3(0.13, 0.017, 0.020), Vector3(0.0, 0.236, -0.19), _black)


func _build_tender_mount() -> void:
	_tender_mount = _pivot(_chassis, "LowTubeMount", Vector3(0.0, 0.22, 0.25))
	_readability_panel(_box(_tender_mount, "GroundedMountBlock", Vector3(0.31, 0.25, 0.21), Vector3(0.0, 0.0, -0.055), _plate))
	var coupler: MeshInstance3D = _cylinder(_tender_mount, "LowReloadCoupler", 0.102, 0.052, _pale, 0.086, 10)
	coupler.position = Vector3(0.0, 0.005, 0.075)
	coupler.rotation.x = PI * 0.5
	_readability_panel(coupler)
	var cavity: MeshInstance3D = _cylinder(_tender_mount, "CouplerDarkCore", 0.057, 0.014, _black, 0.057, 10)
	cavity.position = Vector3(0.0, 0.005, 0.108)
	cavity.rotation.x = PI * 0.5
	_readability_panel(cavity)
	_tender_mount_left = _pivot(_tender_mount, "LeftMountShutter", Vector3(-0.15, 0.0, 0.12))
	_tender_mount_right = _pivot(_tender_mount, "RightMountShutter", Vector3(0.15, 0.0, 0.12))
	_readability_panel(_box(_tender_mount_left, "LeftShutterPlate", Vector3(0.15, 0.22, 0.027), Vector3(0.075, 0.0, 0.0), _rust))
	_readability_panel(_box(_tender_mount_right, "RightShutterPlate", Vector3(0.15, 0.22, 0.027), Vector3(-0.075, 0.0, 0.0), _rust))


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
	var elevation: float = -0.04
	var tube_height: float = TENDER_TUBE_PIVOT.y
	var tube_recoil: float = 0.0
	var opening: float = 0.0
	var spent: float = 0.0
	match phase:
		"warning": elevation = lerpf(-0.12, TENDER_RAISED_ANGLE, smoothstep(0.0, 1.0, p))
		"lock": elevation = TENDER_RAISED_ANGLE
		"active":
			elevation = TENDER_RAISED_ANGLE + sin(p * PI) * 0.035
			tube_recoil = sin(p * PI) * 0.035
		"recovery":
			# The actual actor gate alone decides vulnerability. Keep the low
			# mount visibly exposed for every recovery progress, including0.
			elevation = -0.05
			tube_height = 0.455
			opening = 1.0
		"defeated":
			elevation = 0.14
			tube_height = 0.395
			opening = 1.0
			spent = 1.0
	_case.position = Vector3(0.0, 0.22 - spent * 0.055, -0.06)
	_tender_tube.position = Vector3(0.0, tube_height, TENDER_TUBE_PIVOT.z - tube_recoil)
	_tender_tube.rotation.x = elevation
	_tender_mount_left.rotation.y = -opening * 1.10
	_tender_mount_right.rotation.y = opening * 1.10
	for material: StandardMaterial3D in _materials:
		material.emission_enabled = hit_flash
		material.emission = Color(0.62, 0.52, 0.39) if hit_flash else Color.BLACK
	_recompute_readability()
