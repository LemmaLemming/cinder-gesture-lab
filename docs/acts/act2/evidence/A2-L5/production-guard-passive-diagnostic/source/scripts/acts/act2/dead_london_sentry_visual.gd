extends "res://scripts/acts/act2/ray_scout_visual.gd"
## TMP ART DRAFT, unimported/unexecuted. Original G11 three-legged Sentry.
## Root = the fixed reachable low brace; +Z = supplied ray heading.
## Existing parent clocks, actual joint cue and actual Foot pose own all state.
## No collision, groups, damage, warning geometry, process, timer or Shader TIME.
## Promotion needs an owned Sentry visual factory; accepted Scout stays exact.

const FootVisualScript: Script = preload("res://scripts/acts/act2/giant_foot_visual.gd")
const NEAR_FOOT_AT: Vector3 = Vector3(0.65, 0.0, -0.95)
const HOOD_AT: Vector3 = Vector3(0.0, 2.55, -1.03)
const BRACE_AT: Vector3 = Vector3(0.0, 0.34, 0.0)

var _brace: Node3D
var _generator: Node3D
var _hood_shell: MeshInstance3D
var _near_upper: MeshInstance3D
var _near_shin: MeshInstance3D
var _near_piston: MeshInstance3D
var _near_rod: MeshInstance3D
var _brace_ribs: Array[MeshInstance3D] = []
var _remote_supports: Array[Dictionary] = []
var _cosmetic_cables: Array[MeshInstance3D] = []
var _variable_segments: Array[MeshInstance3D] = []
var _internal_foot_preview: Node3D
var _external_foot: WeakRef
var _brace_stage: int = 1
var _brace_opening: String = "clear"
var _broken_guard: Node3D
var _ray_pose_bound: bool = false
var _ray_phase: String = "idle"
var _ray_progress: float = 0.0
var _ray_direction: Vector3 = Vector3.BACK


func set_ray_pose(phase: String, progress: float, direction: Vector3) -> bool:
	## Cosmetic projection from actual Ray.state(), including its immutable bait
	## direction. Actor composite pose may describe Foot recovery concurrently.
	## Quiet restore replays this projection after the actual Ray is restored;
	## there is no independent ray clock or additional authoritative saved field.
	if not restore_pose_error(phase, progress, direction, _body_yaw).is_empty():
		return false
	_ray_pose_bound = true
	_ray_phase = phase
	_ray_progress = progress
	_ray_direction = direction
	if _built:
		_apply_pose(_requested_phase, _requested_progress, _direction, _requested_flash, true, _body_yaw)
	return true


func set_brace_pose(boss_phase: int, opening_state: String) -> bool:
	## Derived cosmetic input only. Host reads actual actor.boss_phase and the
	## bound parent-owned InteractionCue.state(); this method creates no cue.
	if boss_phase not in [1, 2] or opening_state not in ["clear", "available", "active", "spent"]:
		return false
	_brace_stage = boss_phase
	_brace_opening = opening_state
	if _built:
		_pose_brace()
	return true


func bind_near_foot(visual: Node3D) -> bool:
	## Replace the standalone cosmetic preview with the ONE actual parent Foot.
	## Read only its posed ankle; never move, pose, hide or free that recipient.
	if not _built or not is_inside_tree() or not is_instance_valid(visual) or not visual.is_inside_tree() or not visual.is_node_ready() or visual.is_queued_for_deletion() or visual.get_world_3d() != get_world_3d():
		return false
	var ankle: Node3D = visual.get_node_or_null("VisibleTripodLimb/WidePlantedPad/AnkleSlidingJoint") as Node3D
	if not is_instance_valid(ankle) or not ankle.is_inside_tree() or ankle.is_queued_for_deletion() or not visual.global_position.is_finite() or not ankle.global_position.is_finite():
		return false
	# Presentation attachment check only; actual source coordinates/geometry are
	# independently validated by the parent and its native floor/owner bindings.
	if not to_local(visual.global_position).is_equal_approx(NEAR_FOOT_AT):
		return false
	_external_foot = weakref(visual)
	_internal_foot_preview.visible = false
	_apply_pose(_requested_phase, _requested_progress, _direction, _requested_flash, true, _body_yaw)
	return true


func release_near_foot() -> void:
	# Retirement does not resurrect the standalone preview over a freed source.
	_external_foot = null
	if is_instance_valid(_internal_foot_preview):
		_internal_foot_preview.visible = false


func required_source_nodes() -> Array[Node3D]:
	## Actual mesh containers for an owned host point gatherer, never authority.
	## Remote scenic supports are excluded; actual Foot is required separately.
	var result: Array[Node3D] = []
	if _built:
		result.assign([_case, _generator, _brace])
	return result


func _build() -> void:
	_plate = _textured_material(Color("514b42"), Color("8a4229"), 32, false)
	_rust = _textured_material(Color("65301e"), Color("a65330"), 24, false)
	_black = _textured_material(Color("1e1d1b"), Color("38312b"), 16, false)
	_brass = _material(Color("8b7959"))
	_rubber = _textured_material(Color("24211f"), Color("453a31"), 16, true)
	_pale = _material(Color("b5af99"))
	_chassis = _pivot(self, "DyingTripodChassis", Vector3.ZERO)
	_case = _pivot(_chassis, "FalteringUmbrellaHood", HOOD_AT)
	_hood_shell = _cylinder(_case, "OxidisedUmbrellaShell", 1.23, 0.43, _plate, 0.57, 16)
	_readability_panel(_hood_shell)
	var rim: MeshInstance3D = _cylinder(_case, "BlackOverhangingRim", 1.26, 0.075, _black, 1.26, 16)
	rim.position.y = -0.245
	_readability_panel(rim)
	var crown: MeshInstance3D = _cylinder(_case, "SteppedHoodCrown", 0.59, 0.18, _black, 0.29, 12)
	crown.position.y = 0.275
	_readability_panel(crown)
	var engine: MeshInstance3D = _cylinder(_case, "DarkUnderslungEngine", 0.67, 0.30, _black, 0.82, 12)
	engine.position.y = -0.42
	_readability_panel(engine)
	for index: int in range(12):
		var angle: float = TAU * float(index) / 12.0
		var spoke: MeshInstance3D = _cylinder(_case, "HoodPlateSeam", 0.018, 1.0, _black, 0.018, 6)
		_fit_segment(spoke, Vector3(cos(angle) * 0.56, 0.205, sin(angle) * 0.56), Vector3(cos(angle) * 1.20, -0.20, sin(angle) * 1.20))
		_readability_panel(spoke)
		_box(_case, "SparseHoodRivet", Vector3(0.055, 0.030, 0.055), Vector3(cos(angle) * 1.08, -0.125, sin(angle) * 1.08), _brass)
	# Reuse the pale segmented polished mirror geometry, not the Scout chassis.
	_build_mirror()
	# _build_mirror already supplies exactly TWO saddle links. Reuse and widen
	# them rather than appending duplicate right-hand suspension members.
	for arm: MeshInstance3D in _mirror_links:
		(arm.mesh as CylinderMesh).bottom_radius = 0.070
		(arm.mesh as CylinderMesh).top_radius = 0.060
		_variable_segments.append(arm)
		_readability_panel(arm)
	_generator = _pivot(_chassis, "LowArticulatedRayApparatus", Vector3.ZERO)
	_chassis.remove_child(_mirror_swivel)
	_generator.add_child(_mirror_swivel)
	_mirror_hinge.scale = Vector3.ONE * 1.50
	var barrel: MeshInstance3D = _cylinder(_generator, "RibbedGeneratorDrum", 0.24, 0.46, _black, 0.24, 12)
	barrel.position = Vector3(0.0, 1.02, 0.44)
	barrel.rotation.x = PI * 0.5
	for index: int in range(4):
		var collar: MeshInstance3D = _cylinder(_generator, "GeneratorCoolingCollar", 0.27, 0.035, _plate, 0.27, 12)
		collar.position = Vector3(0.0, 1.02, 0.26 + float(index) * 0.12)
		collar.rotation.x = PI * 0.5
	for side: float in [-1.0, 1.0]:
		_box(_generator, "MirrorArmClevis", Vector3(0.15, 0.14, 0.16), Vector3(side * 0.38, 1.04, 0.34), _rust)
	_build_low_brace()
	var near_leg: Node3D = _pivot(_chassis, "NearAttackingLeg", Vector3.ZERO)
	_near_upper = _cylinder(near_leg, "LongNearLegPlate", 0.145, 1.0, _plate, 0.12, 10)
	# The actual Foot visual owns its one sliding lower leg. This narrow stay
	# joins that limb to the reachable local brace; it is not a fourth support.
	_near_shin = _cylinder(near_leg, "ReachableBraceStay", 0.075, 1.0, _plate, 0.060, 10)
	_near_piston = _cylinder(near_leg, "RibbedNearActuator", 0.09, 1.0, _rubber, 0.09, 10)
	_near_rod = _cylinder(near_leg, "PaleNearPistonRod", 0.035, 1.0, _pale, 0.035, 8)
	for segment: MeshInstance3D in [_near_upper, _near_shin, _near_piston, _near_rod]:
		_variable_segments.append(segment)
		_readability_panel(segment)
	# Exactly two other support legs. They terminate on cosmetic broad feet.
	for side: float in [-1.0, 1.0]:
		_remote_supports.append(_build_remote_support(side))
	for index: int in range(6):
		var cable: MeshInstance3D = _cylinder(_chassis, "HangingFlexibleCable", 0.025, 1.0, _rubber, 0.025, 6)
		_cosmetic_cables.append(cable)
		_variable_segments.append(cable)
		_readability_panel(cable)
	_internal_foot_preview = FootVisualScript.new() as Node3D
	_internal_foot_preview.name = "StandaloneNearFootPreview"
	_internal_foot_preview.position = NEAR_FOOT_AT
	near_leg.add_child(_internal_foot_preview)
	# Standalone still pose only. Final host binds its actual independently
	# clocked Foot visual and this preview then remains hidden permanently.
	_internal_foot_preview.call("pose", "active", 0.0, Vector3.BACK, false)
	_built = true


func _build_low_brace() -> void:
	_brace = _pivot(_chassis, "ReachableLowBrace", BRACE_AT)
	var hub: MeshInstance3D = _cylinder(_brace, "RoundLowJoint", 0.29, 0.28, _black, 0.29, 12)
	hub.rotation.x = PI * 0.5
	var face: MeshInstance3D = _cylinder(_brace, "LowJointOxidisedRing", 0.31, 0.055, _rust, 0.31, 12)
	face.position.z = 0.17
	face.rotation.x = PI * 0.5
	_box(_brace, "OrdinaryPrimaryBraceInterior", Vector3(0.35, 0.22, 0.035), Vector3(0.0, 0.0, 0.215), _pale)
	for index: int in range(5):
		_brace_ribs.append(_box(_brace, "LowBraceRib", Vector3(0.025, 0.18, 0.032), Vector3(-0.14 + index * 0.07, 0.0, 0.24), _black))
	_left_door = _pivot(_brace, "LeftBraceGuard", Vector3(-0.26, 0.0, 0.22))
	_right_door = _pivot(_brace, "RightBraceGuard", Vector3(0.26, 0.0, 0.22))
	_box(_left_door, "LeftRivetedGuard", Vector3(0.26, 0.25, 0.055), Vector3(0.13, 0.0, 0.0), _rust)
	_box(_right_door, "RightRivetedGuard", Vector3(0.26, 0.25, 0.055), Vector3(-0.13, 0.0, 0.0), _rust)
	for side: float in [-1.0, 1.0]:
		_box(_brace, "BraceRetainingBolt", Vector3(0.05, 0.05, 0.035), Vector3(side * 0.20, 0.11, 0.265), _brass)
	_broken_guard = _pivot(_brace, "FirstBraceBrokenPhysicalPlate", Vector3(0.34, -0.17, 0.05))
	_box(_broken_guard, "BentBraceFragment", Vector3(0.22, 0.05, 0.18), Vector3.ZERO, _rust)
	_broken_guard.rotation.z = -0.24


func _build_remote_support(side: float) -> Dictionary:
	var root: Node3D = _pivot(_chassis, "LeftScenicSupport" if side < 0.0 else "RightScenicSupport", Vector3.ZERO)
	var foot: Vector3 = Vector3(side * 2.28, 0.06, -2.48)
	_readability_panel(_box(root, "RemoteBroadFoot", Vector3(0.65, 0.12, 0.52), foot, _black))
	var upper: MeshInstance3D = _cylinder(root, "OxidisedUpperSupport", 0.105, 1.0, _plate, 0.085, 10)
	var lower: MeshInstance3D = _cylinder(root, "OxidisedLowerSupport", 0.09, 1.0, _plate, 0.075, 10)
	var piston: MeshInstance3D = _cylinder(root, "RemoteFlexiblePiston", 0.065, 1.0, _rubber, 0.065, 8)
	var knee: MeshInstance3D = _cylinder(root, "RemoteRoundKnee", 0.18, 0.15, _black, 0.18, 10)
	knee.rotation.z = PI * 0.5
	for segment: MeshInstance3D in [upper, lower, piston]:
		_variable_segments.append(segment)
		_readability_panel(segment)
	_readability_panel(knee)
	return {"side": side, "foot": foot, "upper": upper, "lower": lower, "piston": piston, "knee": knee}


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
	var target_yaw: float = atan2(local_direction.x, local_direction.z)
	if not restore_heading:
		if phase != _last_phase and (phase == "warning" or _last_phase.is_empty()):
			_body_yaw = target_yaw
		if phase == "idle" or phase == "approach":
			_body_yaw = target_yaw
	_last_phase = phase
	# Cosmetic hood latch is saved by the existing actor body_yaw field. The
	# feet/low brace stay fixed; the exact supplied direction turns only mirror.
	var p: float = _requested_progress
	var collapse: float = 0.70 + 0.15 * p if phase == "defeated" else 0.0
	var recovery_drop: float = 0.13 if phase == "recovery" else 0.0
	_case.position = HOOD_AT - Vector3.UP * (collapse + recovery_drop)
	_case.rotation = Vector3(0.05 + collapse * 0.13, _body_yaw * 0.16, 0.06 + collapse * 0.20)
	_chassis.rotation = Vector3.ZERO
	_mirror_swivel.position = Vector3(0.0, 1.03 - collapse * 0.25, 0.62)
	var ray_local: Vector3 = global_basis.inverse() * (_ray_direction if _ray_pose_bound else _direction)
	ray_local.y = 0.0
	_mirror_swivel.rotation.y = atan2(ray_local.x, ray_local.z)
	var ray_phase: String = "defeated" if phase == "defeated" else (_ray_phase if _ray_pose_bound else phase)
	var ray_progress: float = _ray_progress if _ray_pose_bound else p
	var mirror_tilt: float = -0.38
	match ray_phase:
		"warning": mirror_tilt = lerpf(-0.24, -0.12, ray_progress)
		"lock": mirror_tilt = 0.0
		"active": mirror_tilt = -0.025
		"recovery": mirror_tilt = -1.20
		"defeated": mirror_tilt = -1.08
	_mirror_hinge.rotation.x = mirror_tilt
	_aperture_cover.visible = ray_phase in ["idle", "approach", "defeated"] or phase == "defeated"
	_release_shutter.visible = ray_phase == "active" and phase != "defeated"
	_pose_brace()
	var near_hip: Vector3 = _case.position + _case.basis * Vector3(0.27, -0.44, 0.20)
	_fit_segment(_near_upper, near_hip, _near_foot_upper())
	var ankle: Vector3 = _near_ankle()
	_fit_segment(_near_shin, BRACE_AT + Vector3(0.05, -0.07, -0.035), ankle)
	var piston_start: Vector3 = near_hip + Vector3(0.14, -0.16, 0.03)
	var piston_end: Vector3 = BRACE_AT + Vector3(0.22, 0.07, 0.06)
	_fit_segment(_near_piston, piston_start, piston_start.lerp(piston_end, 0.68))
	_fit_segment(_near_rod, piston_start.lerp(piston_end, 0.50), piston_end)
	for index: int in range(_mirror_links.size()):
		var side: float = -1.0 if index == 0 else 1.0
		_fit_segment(_mirror_links[index], _case.position + _case.basis * Vector3(side * 0.42, -0.46, 0.19), _mirror_swivel.position + _mirror_swivel.basis * Vector3(side * 0.42, 0.0, -0.02))
	for support: Dictionary in _remote_supports:
		var side: float = float(support.side)
		var hip: Vector3 = _case.position + _case.basis * Vector3(side * 0.61, -0.45, -0.20)
		var knee: Vector3 = Vector3(side * (1.55 + collapse * 0.18), 1.21 - collapse * 0.30, -1.98)
		_fit_segment(support.upper, hip, knee)
		_fit_segment(support.lower, knee, support.foot + Vector3.UP * 0.10)
		_fit_segment(support.piston, hip + Vector3(side * 0.07, 0.0, 0.04), knee + Vector3(side * 0.07, -0.13, 0.04))
		(support.knee as MeshInstance3D).position = knee
	# Two hanging loops, three linear segments each, body decoration only.
	for loop: int in range(2):
		var side: float = -1.0 if loop == 0 else 1.0
		var points: Array[Vector3] = [_case.position + _case.basis * Vector3(side * 0.42, -0.40, 0.16), Vector3(side * 0.47, 1.22 - collapse * 0.30, -0.48), Vector3(side * 0.36, 0.86 - collapse * 0.14, -0.21), Vector3(side * 0.25, 1.08, 0.26)]
		for segment: int in range(3):
			_fit_segment(_cosmetic_cables[loop * 3 + segment], points[segment], points[segment + 1])
	for material: StandardMaterial3D in _materials:
		material.emission_enabled = hit_flash
		material.emission = Color(0.62, 0.52, 0.39) if hit_flash else Color.BLACK
	_recompute_readability()


func _near_ankle() -> Vector3:
	var visual: Variant = _external_foot.get_ref() if _external_foot != null else null
	if is_instance_valid(visual) and visual is Node3D and visual.is_inside_tree() and not visual.is_queued_for_deletion() and visual.get_world_3d() == get_world_3d():
		var ankle: Node3D = visual.get_node_or_null("VisibleTripodLimb/WidePlantedPad/AnkleSlidingJoint") as Node3D
		if is_instance_valid(ankle) and ankle.is_inside_tree() and not ankle.is_queued_for_deletion() and ankle.global_position.is_finite():
			return _chassis.to_local(ankle.global_position)
	# A vanished external source cannot become an internal attacking foot. Host
	# independently cancels lost native source/cue custody before damage.
	return NEAR_FOOT_AT + Vector3(0.0, 0.38, -0.10)


func _near_foot_upper() -> Vector3:
	var visual: Variant = _external_foot.get_ref() if _external_foot != null else null
	if is_instance_valid(visual) and visual is Node3D and visual.is_inside_tree() and not visual.is_queued_for_deletion() and visual.get_world_3d() == get_world_3d():
		var upper: Vector3 = _chassis.to_local(visual.to_global(Vector3(0.16, 1.98, -0.22)))
		if upper.is_finite():
			return upper
	return NEAR_FOOT_AT + Vector3(0.16, 1.98, -0.22)


func _pose_brace() -> void:
	# Cosmetic opening follows actual composite cue, including Foot recovery.
	# Ray recovery alone never advertises available or heals the spent brace.
	var open: bool = _brace_opening in ["available", "active"]
	_left_door.rotation.y = -1.16 if open else -0.08
	_right_door.rotation.y = 1.16 if open else 0.08
	_broken_guard.visible = _brace_stage == 2 or _brace_opening == "spent"
	for index: int in range(_brace_ribs.size()):
		_brace_ribs[index].visible = _brace_stage == 1 or index % 2 == 0


func _recompute_readability() -> void:
	for panel: Dictionary in _readability_panels:
		if _variable_segments.has(panel.part):
			panel.merge(_readability_geometry(panel.part), true)
	super._recompute_readability()


func _exit_tree() -> void:
	release_near_foot()
	super._exit_tree()
