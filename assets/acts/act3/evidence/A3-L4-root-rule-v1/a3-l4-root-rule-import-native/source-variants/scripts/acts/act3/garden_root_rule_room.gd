class_name CinderAct3GardenRootRuleRoom
extends CinderLevel
## Small native rule prototype, not the authored False Paradise campaign level.
## Shared Player/input/camera/Scheduler/LaneMechanism remain the sole authority.

const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const MechanismScript = preload("res://scripts/combat/lane_mechanism.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const CueMeshes = preload("res://scripts/cues/cue_mesh.gd")
const Kit = preload("res://scripts/acts/act3/twin_suns_scenery.gd")
const TetherScript = preload("res://scripts/acts/act3/garden_root_tether.gd")
const ENCOUNTER_ID: String = "false-paradise-rule"
const FLOOR_RECT: Rect2 = Rect2(-7, -6, 14, 12)
const RAW_ROLE: Dictionary = {"raw_damage": 8.0, "max_hp": 1.0, "windup_s": 2.2, "lock_s": 1.1, "active_s": 0.2, "recovery_s": 1.8, "attack_interval_s": 4.0, "move_speed": 0.0}
const TIMING_FLOORS: Dictionary = {"windup_s": 2.2, "lock_s": 1.1, "recovery_s": 1.8}

@export var auto_attack: bool = true
var threat_scheduler: CinderThreatScheduler
var mechanisms: Dictionary = {}
var tether: CinderAct3GardenRootTether
var scenery: Node3D
var last_configuration_error: String = ""
var last_admission_reason: String = ""
var last_view_error: String = ""
var _floor: Dictionary = {}
var _floor_body: StaticBody3D
var _active: bool = false
var _views: Dictionary = {}
var _proofs: Dictionary = {}
var _cycle_phases: Dictionary = {}
var _static_points: Array = []
var _root_views: Array[MeshInstance3D] = []
var _root_specs: Array = []
var _next_kind: String = "draw"
var _retry_at_s: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 90
	scenery = Kit.new()
	scenery.name = "GardenRuleFloor"
	add_child(scenery)
	# Reuse only the kit's floor/material helpers, without importing L1 walls.
	_floor_body = scenery.call("_solid_box", "FirmGardenFloor", Vector3(14, 1, 12), Vector3(0, -0.5, 0)) as StaticBody3D
	var floor_view: MeshInstance3D = scenery.call("_box", Vector3(14, 1, 12), Vector3(0, -0.5, 0), Color("332639")) as MeshInstance3D
	floor_view.name = "QuietGardenFloor"
	(floor_view.material_override as StandardMaterial3D).texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_floor = {"collision": _floor_body.get_node("Solid"), "safe_rect": FLOOR_RECT}
	threat_scheduler = SchedulerScript.new()
	threat_scheduler.name = "GardenScheduler"
	add_child(threat_scheduler)
	for kind: String in ["draw", "enclose"]:
		var source: CinderLaneMechanism = MechanismScript.new()
		source.name = "DrawRoots" if kind == "draw" else "EncloseRoots"
		source.position = Vector3(-1, 0, 1.25) if kind == "draw" else Vector3.ZERO
		add_child(source)
		mechanisms[kind] = source
		var shape: Dictionary = _shape(kind)
		var bounds: Array = []
		for filled: bool in [false, true]:
			bounds.append_array(_mesh_corners(CueMeshes.geometry_mesh(shape, filled), Transform3D(Basis.IDENTITY, CueMeshes.anchor(shape) + Vector3.UP * (CinderThreatCue.FLOOR_OFFSET - (0.004 if filled else 0.0)))))
		for phase_name: String in ["warning", "lock", "active", "recovery"]:
			bounds.append_array(_mesh_corners(CueMeshes.source_mesh(phase_name), Transform3D(Basis.IDENTITY, source.position + Vector3.UP * (CinderThreatCue.FLOOR_OFFSET + 0.004))))
		_static_points.append_array(_enclosing_corners(bounds))
	for at: Vector3 in [Vector3(-1, 0.08, 1.25), Vector3(1, 0.08, 1.25), Vector3(0, 0.08, 0)]:
		var size := Vector3(0.22, 0.16, 0.22)
		var view: MeshInstance3D = scenery.call("_box", size, at, Color("68516d")) as MeshInstance3D
		view.name = "PhysicalRootEnd" + str(_root_views.size())
		(view.material_override as StandardMaterial3D).texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_root_views.append(view)
		_root_specs.append({"size": size, "at": at, "material": view.material_override, "color": Color("68516d")})
		_static_points.append_array(_mesh_corners(view.mesh, view.global_transform))
	tether = TetherScript.new()
	tether.name = "ExternalRootTether"
	tether.position = TetherScript.FIXED_POSITION
	add_child(tether)


func _on_enter_level() -> void:
	var profile: String = String(shared_shell.call("get_difficulty_preference")) if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference") else "standard"
	if not threat_scheduler.begin_encounter(profile, ENCOUNTER_ID, 1) or not tether.configure(exposure_open, _on_phase_boundary):
		last_configuration_error = "Actual garden encounter and low tether bindings required"
		return
	for kind: String in mechanisms:
		var source: CinderLaneMechanism = mechanisms[kind]
		if not source.configure("l4-garden-" + kind, _shape(kind), tether.global_position, RAW_ROLE, TIMING_FLOORS) or not source.bind(threat_scheduler, {"hero": hero}) or not source.set_presentation_guard(_parent_presentation_guard):
			last_configuration_error = source.last_error
			return
	_active = true
	_update_guidance()


func _shape(kind: String) -> Dictionary:
	return Geometry.lane(Vector3(-1, 0, 1.25), Vector3(1, 0, 1.25), 0.28) if kind == "draw" else Geometry.crescent(Vector3.ZERO, Vector3.BACK, 0.75, 1.65, 0.5)


func response_context(direction: Vector3) -> Dictionary:
	return {"encounter_id": ENCOUNTER_ID, "world_revision": 1, "recognition_s": 0.25, "attack_input_margin_s": 0.06, "escape_directions": [direction], "return_directions": [-direction], "floor_regions": [_floor]}


func start_attack(kind: String, escape_direction: Vector3) -> Dictionary:
	if not _active or get_tree().paused or tether.dead or not mechanisms.has(kind) or escape_direction not in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK] or not runtime_error().is_empty():
		return {"accepted": false, "reason": "Actual unpaused garden and ordinary authored approach required"}
	for source: CinderLaneMechanism in mechanisms.values():
		if source.state().status == "running":
			return {"accepted": false, "reason": "Teach these two commitments separately"}
	var mechanism: CinderLaneMechanism = mechanisms[kind]
	var bearing: Variant = Vector3.BACK if kind == "enclose" else null
	var preview: Dictionary = mechanism.preview_start("hero", response_context(escape_direction), null, bearing)
	if not preview.get("accepted", false):
		last_admission_reason = String(preview.get("reason", "Native garden preview rejected"))
		return preview
	_views.clear()
	_views[kind] = {"landing": preview.proof.landing, "attack_position": preview.proof.attack_position}
	var points: Array = camera_framing_points()
	var plan: Dictionary = shared_shell.call("camera_framing_plan", points, hero.global_position + Vector3.UP * 0.75)
	last_view_error = String(plan.get("reason", "Fixed garden view rejected")) if not plan.get("accepted", false) else String(shared_shell.call("camera_framing_error", points))
	if not last_view_error.is_empty():
		return {"accepted": false, "reason": last_view_error}
	# Parent guard can run synchronously during admission. Set phase custody first.
	_cycle_phases[kind] = tether.phase
	var answer: Dictionary = mechanism.start("hero", response_context(escape_direction), null, bearing, preview)
	last_admission_reason = "" if answer.get("accepted", false) else String(answer.get("reason", "Native garden admission rejected"))
	if answer.get("accepted", false):
		_proofs[kind] = answer.proof.duplicate(true)
		_next_kind = "enclose" if kind == "draw" else "draw"
	return answer


func exposure_open() -> bool:
	if not _active or get_tree().paused or tether.dead or not runtime_error().is_empty() or not String(shared_shell.call("camera_framing_error", camera_framing_points())).is_empty():
		return false
	for kind: String in mechanisms:
		var current: Dictionary = (mechanisms[kind] as CinderLaneMechanism).state()
		if current.status != "running" or current.phase != "recovery" or int(_cycle_phases.get(kind, 0)) != tether.phase:
			continue
		var lease: Dictionary = threat_scheduler.reservation_state(String(current.reservation_id))
		if lease.get("state") == "recovery" and lease.get("source_instance_id") == (mechanisms[kind] as Node).get_instance_id() and lease.get("opening_position") == tether.global_position and threat_scheduler.get_clock() <= float(lease.get("recovery_until_s", -1.0)):
			return true
	return false


func _on_phase_boundary() -> void:
	# Called after HP/phase commit, before damage/phase observers. No HP reset.
	for source: CinderLaneMechanism in mechanisms.values():
		source.cancel("garden_phase_boundary")
	_retry_at_s = threat_scheduler.get_clock() + 0.25
	_update_guidance()


func _parent_presentation_guard(_mechanism_id: String, _current: Dictionary) -> bool:
	if not _active or not runtime_error().is_empty():
		return false
	last_view_error = String(shared_shell.call("camera_framing_error", camera_framing_points()))
	return last_view_error.is_empty()


func _physics_process(_delta: float) -> void:
	if not _active:
		return
	var error: String = runtime_error()
	if not error.is_empty():
		last_configuration_error = error
		for source: CinderLaneMechanism in mechanisms.values():
			source.cancel("garden_required_parent_unavailable")
		return
	for source: CinderLaneMechanism in mechanisms.values():
		if source.state().status == "running" and not _parent_presentation_guard("", {}):
			source.cancel("garden_actual_view_unreadable")
	if auto_attack and not tether.dead and threat_scheduler.get_clock() >= _retry_at_s and hero.get_threat_response_state().stable:
		start_attack(_next_kind, Vector3.RIGHT)
	tether.present()
	_update_guidance()


func _camera_framing_points() -> Array:
	if not _active:
		return []
	var points: Array = _static_points.duplicate()
	points.append_array(tether.framing_points())
	var native_player: Array = shared_shell.call("player_camera_framing_points") if is_instance_valid(shared_shell) else []
	if native_player.is_empty():
		last_camera_framing_error = "Actual shared player bounds required"
		return []
	for view: Dictionary in _views.values():
		for key: String in ["landing", "attack_position"]:
			for point: Vector3 in native_player:
				points.append(point + (view[key] as Vector3) - hero.global_position)
	return points


func runtime_error() -> String:
	if not is_instance_valid(hero) or not is_instance_valid(shared_shell) or not is_instance_valid(threat_scheduler) or not is_instance_valid(tether) or not is_visible_in_tree() or global_transform != Transform3D.IDENTITY or threat_scheduler.get_parent() != self or tether.get_parent() != self:
		return "Actual garden parent/hero/source/scheduler/camera bindings required"
	if not is_instance_valid(_floor_body) or _floor_body.get_parent() != scenery or _floor_body.global_transform != Transform3D(Basis.IDENTITY, Vector3(0, -0.5, 0)) or _floor_body.collision_layer != 1 or _floor_body.collision_mask != 0 or not is_instance_valid(_floor.collision) or _floor.collision.disabled or not _floor.collision.shape is BoxShape3D or (_floor.collision.shape as BoxShape3D).size != Vector3(14, 1, 12) or _floor.collision.get_parent() != _floor_body or _floor.collision.transform != Transform3D.IDENTITY:
		return "Permanent actual14 by12 firm garden floor required"
	for kind: String in mechanisms:
		var source: CinderLaneMechanism = mechanisms[kind]
		var at: Vector3 = Vector3(-1, 0, 1.25) if kind == "draw" else Vector3.ZERO
		if not is_instance_valid(source) or source.get_parent() != self or source.global_transform != Transform3D(Basis.IDENTITY, at) or not source.is_visible_in_tree() or source.get_cue() == null or not source.get_cue().is_visible_in_tree():
			return "Both fixed physical roots and required cues must remain present"
	for index: int in range(_root_views.size()):
		var view: MeshInstance3D = _root_views[index]
		var spec: Dictionary = _root_specs[index]
		if not is_instance_valid(view) or not view.is_visible_in_tree() or view.get_parent() != scenery or view.global_transform != Transform3D(Basis.IDENTITY, spec.at) or not view.mesh is BoxMesh or (view.mesh as BoxMesh).size != spec.size or view.material_override != spec.material:
			return "Complete physical root ends must stay fixed and visible"
		var material: StandardMaterial3D = spec.material as StandardMaterial3D
		if material == null or material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.no_depth_test or material.albedo_color != spec.color:
			return "Opaque nearest root ends with restrained presentation required"
	return tether.runtime_error()


func get_selected_response(kind: String) -> Dictionary:
	return (_views.get(kind, {}) as Dictionary).duplicate(true)


func state() -> Dictionary:
	var source_states: Dictionary = {}
	for kind: String in mechanisms:
		source_states[kind] = (mechanisms[kind] as CinderLaneMechanism).state()
	return {"configuration_error": last_configuration_error, "admission_reason": last_admission_reason, "camera_error": last_view_error, "mechanisms": source_states, "tether": tether.state(), "proofs": _proofs.duplicate(true), "clock_s": threat_scheduler.get_clock()}


func _on_exit_level() -> void:
	_active = false
	for source: CinderLaneMechanism in mechanisms.values():
		if is_instance_valid(source):
			source.cancel("garden_rule_room_exit")
	if is_instance_valid(threat_scheduler):
		threat_scheduler.end_encounter("garden_rule_room_exit")


func _local_snapshot_error(_data: Dictionary) -> String:
	return "Garden rule prototype persistence is unimplemented; no campaign save credit"


func _update_guidance() -> void:
	objective_text = "ROOT NETWORK SEVERED / RULE PROTOTYPE" if tether.dead else ("LOW TETHER EXPOSED / ORDINARY SLASH" if exposure_open() else "ROOT ENDS / READ LOCKED LANE OR BROKEN RING")


func _mesh_corners(mesh: Mesh, transform: Transform3D) -> Array:
	var points: Array = []
	var box: AABB = mesh.get_aabb()
	for index: int in range(8):
		points.append(transform * box.get_endpoint(index))
	return points


func _enclosing_corners(points: Array) -> Array:
	var box := AABB(points[0], Vector3.ZERO)
	for point: Vector3 in points:
		box = box.expand(point)
	var corners: Array = []
	for index: int in range(8):
		corners.append(box.get_endpoint(index))
	return corners
