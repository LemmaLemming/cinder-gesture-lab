extends "res://scripts/acts/act2/ray_scout_visual.gd"
## One local visible fighting-machine limb. Cosmetic only, from G11 planted
## foot/sliding-joint vocabulary. The shared circle is the authoritative patch.
## Every phase/progress is supplied by the level's actual mechanism clock.

var _pad: Node3D
var _shaft: MeshInstance3D
var _piston: MeshInstance3D
var _joint: Node3D

func _build() -> void:
	_plate = _textured_material(Color("615950"), Color("8d4228"), 24, false)
	_black = _textured_material(Color("242322"), Color("514338"), 16, false)
	_brass = _material(Color("86775d"))
	_rubber = _textured_material(Color("292724"), Color("4e453e"), 16, true)
	_chassis = _pivot(self, "VisibleTripodLimb", Vector3.ZERO)
	_pad = _pivot(_chassis, "WidePlantedPad", Vector3.ZERO)
	_readability_panel(_box(_pad, "RivetedFootPlate", Vector3(1.5, 0.16, 1.25), Vector3(0, 0.11, 0), _plate))
	_readability_panel(_box(_pad, "BlackSole", Vector3(1.62, 0.10, 1.36), Vector3(0, 0.035, 0), _black))
	for side: float in [-1.0, 1.0]:
		_box(_pad, "RetainingEdge", Vector3(0.035, 0.18, 1.33), Vector3(side * 0.79, 0.11, 0), _black)
		for z: float in [-0.5, -0.17, 0.17, 0.5]:
			_box(_pad, "FootRivet", Vector3(0.055, 0.026, 0.055), Vector3(side * 0.60, 0.205, z), _brass)
	_joint = _pivot(_pad, "AnkleSlidingJoint", Vector3(0, 0.38, -0.1))
	var ankle: MeshInstance3D = _cylinder(_joint, "AnkleHub", 0.23, 0.26, _black, 0.23, 12)
	ankle.rotation.z = PI * 0.5
	_readability_panel(ankle)
	_box(_joint, "AnklePin", Vector3(0.08, 0.08, 0.08), Vector3(-0.18, 0.0, 0.0), _brass)
	_shaft = _cylinder(_chassis, "SlidingOxidisedLeg", 0.14, 1.0, _plate, 0.105, 10)
	_readability_panel(_shaft)
	_piston = _cylinder(_chassis, "BlackFlexiblePiston", 0.085, 1.0, _rubber, 0.085, 8)
	_readability_panel(_piston)
	for y: float in [1.45, 1.65, 1.86]:
		var collar: MeshInstance3D = _cylinder(_chassis, "UpperRetainingCollar", 0.19, 0.055, _black, 0.19, 10)
		collar.position = Vector3(0.16, y, -0.22)
		_readability_panel(collar)
	_built = true

func _apply_pose(phase: String, progress: float, direction: Vector3, hit_flash: bool, restore_heading: bool, saved_body_yaw: float) -> void:
	_requested_phase = phase
	_requested_progress = clampf(progress, 0.0, 1.0)
	_requested_flash = hit_flash
	_requested_has_body_yaw = restore_heading
	_requested_body_yaw = saved_body_yaw
	_direction = direction
	if not _built:
		return
	_body_yaw = 0.0
	var lift: float = 0.95
	match phase:
		"warning": lift = lerpf(0.55, 0.95, _requested_progress)
		"lock": lift = 0.95
		"active": lift = 0.0
		"recovery": lift = lerpf(0.0, 0.95, smoothstep(0.0, 0.65, _requested_progress))
	_pad.position.y = lift
	_joint.rotation.x = -0.12 * lift
	_fit_segment(_shaft, Vector3(0.0, lift + 0.5, -0.10), Vector3(0.16, 1.98, -0.22))
	_fit_segment(_piston, Vector3(0.20, lift + 0.30, 0.02), Vector3(0.35, 1.77, -0.17))
	_last_phase = phase
	_recompute_readability()

func _recompute_readability() -> void:
	# Two real CylinderMesh heights are posed above. Only derived triangles are
	# refreshed; effective palette/material clones remain allocated once.
	for panel: Dictionary in _readability_panels:
		if panel.part == _shaft or panel.part == _piston:
			panel.merge(_readability_geometry(panel.part), true)
	super._recompute_readability()
