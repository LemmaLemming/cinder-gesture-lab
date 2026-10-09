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
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const LOCAL_API: String = "act3-garden-rule-pair-1"
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
var _cue_meshes: Dictionary = {}
var _root_specs: Array = []
var _next_kind: String = "draw"
var _retry_at_s: float = 0.0
var _cycle_records: Dictionary = {}
var _view_history: Dictionary = {}
var _boundaries: Array = []
var _capture_camera: Camera3D
var _capture_hud: GameHUD
var _capture_error: String = ""


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
		var native: Dictionary = {"outline": CueMeshes.geometry_mesh(shape, false), "fill": CueMeshes.geometry_mesh(shape, true), "sources": {}}
		for phase_name: String in ["warning", "lock", "active", "recovery"]:
			native.sources[phase_name] = CueMeshes.source_mesh(phase_name)
		_cue_meshes[kind] = native
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
	if not threat_scheduler.begin_encounter(profile, ENCOUNTER_ID, 1):
		last_configuration_error = "Actual garden encounter and low tether bindings required"
		return
	last_configuration_error = _bind_sources()
	if not last_configuration_error.is_empty():
		return
	_active = true
	_update_guidance()


func _bind_sources() -> String:
	if not tether.configure(exposure_open, _on_phase_boundary):
		return "Actual retained garden target providers required"
	for kind: String in mechanisms:
		var source: CinderLaneMechanism = mechanisms[kind]
		if not source.configure("l4-garden-" + kind, _shape(kind), tether.global_position, RAW_ROLE, TIMING_FLOORS) or not source.bind(threat_scheduler, {"hero": hero}) or not source.set_presentation_guard(_parent_presentation_guard):
			return source.last_error
	return ""


func restore_candidate_construction_required() -> bool:
	return true


func _on_enter_restore_candidate(local: Dictionary, _saved_player: Dictionary) -> String:
	if not Codec.keys_error(local, ["api_revision", "schema_version", "scheduler", "tether", "mechanisms", "control"]).is_empty() or local.get("api_revision") != LOCAL_API or not Codec.is_integer(local.get("schema_version"), 1, 1):
		return "Closed small garden pair construction descriptor required"
	var error: String = _bind_sources()
	if error.is_empty():
		_active = true # Native topology only; no encounter/admission/history earned.
	return error


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
	var previous_views: Dictionary = _views.duplicate(true)
	_views.clear()
	_views[kind] = {"landing": preview.proof.landing, "attack_position": preview.proof.attack_position}
	var points: Array = camera_framing_points()
	var plan: Dictionary = shared_shell.call("camera_framing_plan", points, hero.global_position + Vector3.UP * 0.75)
	last_view_error = String(plan.get("reason", "Fixed garden view rejected")) if not plan.get("accepted", false) else String(shared_shell.call("camera_framing_error", points))
	if not last_view_error.is_empty():
		_views = previous_views
		return {"accepted": false, "reason": last_view_error}
	var admitted_phase: int = tether.phase
	var answer: Dictionary = mechanism.start("hero", response_context(escape_direction), null, bearing, preview)
	last_admission_reason = "" if answer.get("accepted", false) else String(answer.get("reason", "Native garden admission rejected"))
	if answer.get("accepted", false):
		_cycle_phases[kind] = admitted_phase
		_cycle_records[kind] = {"cycle": mechanism.state().cycle, "exchange_id": String(answer.reservation_id), "tether_phase": admitted_phase}
		_view_history[kind] = (_views[kind] as Dictionary).duplicate(true)
		_proofs[kind] = answer.proof.duplicate(true)
		_next_kind = "enclose" if kind == "draw" else "draw"
	else:
		_views = previous_views
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
			# Lease lookup can prune another source and synchronously notify observers.
			# Recheck actual art/optics and this unchanged exposure after that call.
			if not _active or get_tree().paused or tether.dead or int(_cycle_phases.get(kind, 0)) != tether.phase or (mechanisms[kind] as CinderLaneMechanism).state() != current or not runtime_error().is_empty():
				return false
			return String(shared_shell.call("camera_framing_error", camera_framing_points())).is_empty()
	return false


func _on_phase_boundary() -> void:
	# Called after HP/phase commit, before damage/phase observers. No HP reset.
	var triggering: Dictionary = _logical_exposure(tether.phase - 1)
	if triggering.is_empty():
		last_configuration_error = "A genuine accepted recovery must precede a root phase crossing"
	else:
		_boundaries.append({"from_phase": tether.phase - 1, "to_phase": tether.phase, "clock_s": threat_scheduler.get_clock(), "kind": triggering.kind, "cycle": triggering.cycle, "exchange_id": triggering.exchange_id})
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
	return _framing_points_for(get_viewport().get_camera_3d())


func _framing_points_for(camera: Camera3D) -> Array:
	if not _active:
		return []
	var points: Array = _static_points.duplicate()
	points.append_array(tether.framing_points())
	# Fresh ordinary entry has no historical shifts. Game adds that actual
	# candidate Player independently, before installed aliases exist.
	if _views.is_empty():
		return points
	var native_player: Array = shared_shell.call("player_camera_framing_points_for", hero, camera) if is_instance_valid(shared_shell) and is_instance_valid(camera) else []
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
		var cue_error: String = _cue_error(kind, source.state())
		if not cue_error.is_empty():
			return cue_error
	for index: int in range(_root_views.size()):
		var view: MeshInstance3D = _root_views[index]
		var spec: Dictionary = _root_specs[index]
		if not is_instance_valid(view) or not view.is_visible_in_tree() or view.get_parent() != scenery or view.global_transform != Transform3D(Basis.IDENTITY, spec.at) or not view.mesh is BoxMesh or (view.mesh as BoxMesh).size != spec.size or view.material_override != spec.material or view.layers != 1 or view.transparency != 0.0 or view.material_overlay != null or view.visibility_range_begin != 0.0 or view.visibility_range_end != 0.0 or view.top_level:
			return "Complete physical root ends must stay fixed and visible"
		var material: StandardMaterial3D = spec.material as StandardMaterial3D
		if material == null or material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.no_depth_test or material.albedo_color != spec.color:
			return "Opaque nearest root ends with restrained presentation required"
	return tether.runtime_error()


func _cue_error(kind: String, current: Dictionary) -> String:
	if current.status != "running":
		return ""
	var cue: CinderThreatCue = (mechanisms[kind] as CinderLaneMechanism).get_cue()
	var phase_name: String = String(current.phase)
	var cue_state: Dictionary = cue.state()
	var anchor: Vector3 = CueMeshes.anchor(_shape(kind))
	if cue_state.phase != phase_name or cue_state.geometry != current.geometry or cue_state.source_position != anchor or cue.global_transform != Transform3D(Basis.IDENTITY, anchor):
		return "Actual garden cue state must match its native committed geometry/phase"
	var colors: Dictionary = {"warning": Color(1.0, 0.90, 0.63, 0.95), "lock": Color(1.0, 0.76, 0.35, 1.0), "active": Color(1.0, 0.43, 0.26, 1.0), "recovery": Color(0.77, 0.88, 0.90, 0.70)}
	if not colors.has(phase_name):
		return "Actual garden cue requires a native held phase"
	for label: String in ["RequiredSourceMarker", "RequiredFootprintOutline", "RequiredFootprintFill"]:
		var part: MeshInstance3D = cue.get_node_or_null(label) as MeshInstance3D
		var filled: bool = label == "RequiredFootprintFill"
		var marker: bool = label == "RequiredSourceMarker"
		var visible_required: bool = true if marker else (phase_name == "active" if filled else phase_name != "recovery")
		var expected: ArrayMesh = _cue_meshes[kind].sources[phase_name] if marker else (_cue_meshes[kind].fill if filled else _cue_meshes[kind].outline)
		var at: Vector3 = Vector3.UP * (CinderThreatCue.FLOOR_OFFSET + (0.004 if marker else (-0.004 if filled else 0.0)))
		if not is_instance_valid(part) or part.is_queued_for_deletion() or part.get_parent() != cue or part.transform != Transform3D(Basis.IDENTITY, at) or part.visible != visible_required or (visible_required and not part.is_visible_in_tree()) or not part.mesh is ArrayMesh or part.layers != 1 or part.transparency != 0.0 or part.material_overlay != null or part.top_level:
			return "Complete native garden cue parts must retain their actual phase presentation"
		var mesh: ArrayMesh = part.mesh as ArrayMesh
		if mesh.get_surface_count() != expected.get_surface_count() or mesh.get_aabb() != expected.get_aabb():
			return "Native garden cue bounds must retain their complete generated geometry"
		for surface: int in range(expected.get_surface_count()):
			if mesh.surface_get_primitive_type(surface) != expected.surface_get_primitive_type(surface) or mesh.surface_get_arrays(surface) != expected.surface_get_arrays(surface) or part.get_surface_override_material(surface) != null:
				return "Native garden cue triangles/indices/material custody changed"
		var material: StandardMaterial3D = part.material_override as StandardMaterial3D
		var color: Color = colors[phase_name]
		if filled:
			color.a = 0.22
		if material == null or material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA or material.no_depth_test or material.cull_mode != BaseMaterial3D.CULL_DISABLED or material.albedo_color != color or material.albedo_texture != null or material.next_pass != null:
			return "Actual garden cue material must retain the shared phase grammar"
	return ""


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


func _logical_exposure(target_phase: int = 0) -> Dictionary:
	# Non-pruning logical presentation view. Paused input still cannot damage.
	var required_phase: int = tether.phase if target_phase == 0 else target_phase
	if not _active or required_phase not in [1, 2]:
		return {}
	for kind: String in mechanisms:
		var source: CinderLaneMechanism = mechanisms[kind]
		var current: Dictionary = source.state()
		var earned: Dictionary = _cycle_records.get(kind, {})
		if current.status != "running" or current.phase != "recovery" or earned.get("tether_phase") != required_phase or earned.get("cycle") != current.cycle or earned.get("exchange_id") != current.reservation_id:
			continue
		var retained: Dictionary = threat_scheduler.source_control_state(source)
		for lease: Dictionary in retained.get("reservations", []):
			if lease.id == earned.exchange_id and lease.state == "recovery" and lease.opening_position == tether.global_position and lease.source_instance_id == source.get_instance_id() and threat_scheduler.get_clock() <= float(lease.recovery_until_s):
				return {"kind": kind, "cycle": earned.cycle, "exchange_id": earned.exchange_id}
	return {}


func scheduler_bindings() -> Dictionary:
	return {"world_root": get_parent() as Node3D, "owners": {"l4-garden-draw": mechanisms.draw, "l4-garden-enclose": mechanisms.enclose}, "floors": {"garden-rule-floor": _floor}, "actors": {"hero": hero}}


func snapshot_state() -> Dictionary:
	if not is_instance_valid(shared_shell):
		last_snapshot_error = "Entered actual garden shell required"
		return {}
	return _capture_for_context(get_viewport().get_camera_3d(), shared_shell.get("hud") as GameHUD)


func snapshot_state_for_presentation(camera: Camera3D, hud: GameHUD) -> Dictionary:
	return _capture_for_context(camera, hud)


func _capture_for_context(camera: Camera3D, hud: GameHUD) -> Dictionary:
	if is_instance_valid(_capture_camera) or is_instance_valid(_capture_hud):
		last_snapshot_error = "Garden capture cannot reenter its actual context"
		return {}
	_capture_camera = camera
	_capture_hud = hud
	_capture_error = _presentation_error(camera, hud)
	var snapshot: Dictionary = super.snapshot_state() if _capture_error.is_empty() else {}
	if not snapshot.is_empty():
		_capture_error = _snapshot_envelope_error(snapshot)
		if not _capture_error.is_empty():
			snapshot = {}
	_capture_camera = null
	_capture_hud = null
	if not _capture_error.is_empty():
		last_snapshot_error = _capture_error
	return snapshot


func _capture_local_state() -> Dictionary:
	var bindings: Dictionary = scheduler_bindings()
	var paired: Dictionary = threat_scheduler.snapshot_state(bindings)
	if paired.is_empty():
		_capture_error = threat_scheduler.last_snapshot_error
		return {}
	var parts: Dictionary = {}
	for kind: String in mechanisms:
		parts[kind] = (mechanisms[kind] as CinderLaneMechanism).snapshot_state(bindings)
		if parts[kind].is_empty():
			_capture_error = (mechanisms[kind] as CinderLaneMechanism).last_snapshot_error
			return {}
	var target: Dictionary = tether.snapshot_state(float(paired.clock_s))
	if target.is_empty():
		_capture_error = tether.snapshot_access_error()
		return {}
	var framing: Dictionary = {}
	for kind: String in _view_history:
		framing[kind] = {"landing": Codec.vector3(_view_history[kind].landing), "attack_position": Codec.vector3(_view_history[kind].attack_position)}
	return {"api_revision": LOCAL_API, "schema_version": 1, "scheduler": paired, "tether": target, "mechanisms": parts, "control": {"next_kind": _next_kind, "retry_at_s": _retry_at_s, "cycle_records": _cycle_records.duplicate(true), "framing": framing, "boundaries": _boundaries.duplicate(true)}}


func _snapshot_envelope_error(snapshot: Dictionary) -> String:
	var error: String = super._snapshot_envelope_error(snapshot)
	if not error.is_empty():
		return error
	var expected: Dictionary = {"completed": false, "completion_id": "", "contact_exit_id": "", "checkpoint_id": "", "checkpoint_kind": "", "checkpoint_ids": {}}
	return "Small garden prototype has no earned campaign progress" if snapshot.progress != expected else ""


func _local_snapshot_error(data: Dictionary) -> String:
	return _local_snapshot_error_with_player(data, hero.snapshot_state())


func _local_snapshot_error_with_player(data: Dictionary, player: Dictionary) -> String:
	if not get_tree().paused or not _active:
		return "Garden pair requires the completed paused barrier"
	var error: String = runtime_error()
	if error.is_empty():
		error = Codec.value_error(data)
	if error.is_empty():
		error = Codec.keys_error(data, ["api_revision", "schema_version", "scheduler", "tether", "mechanisms", "control"])
	if not error.is_empty():
		return error
	if data.api_revision != LOCAL_API or not Codec.is_integer(data.schema_version, 1, 1) or not data.scheduler is Dictionary or not data.tether is Dictionary or not data.mechanisms is Dictionary or not data.control is Dictionary or not Codec.keys_error(data.mechanisms, ["draw", "enclose"]).is_empty():
		return "Closed garden pair identity and complete two-source schema required"
	error = hero.snapshot_error(player)
	if not error.is_empty():
		return error
	var bindings: Dictionary = scheduler_bindings()
	bindings["hero_positions"] = {"hero": Codec.read_vector3(player.motion.position)}
	error = threat_scheduler.snapshot_error(data.scheduler, bindings)
	if not error.is_empty():
		return error
	if data.scheduler.encounter_id != ENCOUNTER_ID or int(data.scheduler.world_revision) != 1:
		return "Original garden encounter identity and world revision required"
	error = tether.snapshot_error(data.tether, float(data.scheduler.clock_s))
	if not error.is_empty():
		return error
	for kind: String in mechanisms:
		if not data.mechanisms[kind] is Dictionary:
			return "Both actual native mechanism packets required"
		error = (mechanisms[kind] as CinderLaneMechanism).snapshot_error(data.mechanisms[kind], bindings, data.scheduler)
		if not error.is_empty():
			return error
	return _control_error(data)


func _control_error(data: Dictionary) -> String:
	var control: Dictionary = data.control
	var error: String = Codec.keys_error(control, ["next_kind", "retry_at_s", "cycle_records", "framing", "boundaries"])
	if not error.is_empty():
		return error
	if control.next_kind not in ["draw", "enclose"] or not Codec.in_range(control.retry_at_s, 0.0, 1000000000.25) or not control.cycle_records is Dictionary or not control.framing is Dictionary or not control.boundaries is Array or control.boundaries.size() != int(data.tether.phase) - 1:
		return "Bounded earned garden control and phase-crossing prefix required"
	var executed: Array = []
	var latest_serial: int = 0
	var latest_kind: String = ""
	var held: int = 0
	for kind: String in ["draw", "enclose"]:
		var packet: Dictionary = data.mechanisms[kind]
		if int(packet.cycle) == 0:
			if control.cycle_records.has(kind) or control.framing.has(kind):
				return "Idle source cannot invent accepted cycle or response presentation"
			continue
		executed.append(kind)
		var earned: Variant = control.cycle_records.get(kind)
		if not earned is Dictionary or not Codec.keys_error(earned, ["cycle", "exchange_id", "tether_phase"]).is_empty() or not Codec.is_integer(earned.cycle, 1) or earned.cycle != packet.cycle or earned.exchange_id != packet.exchange.id or not Codec.is_integer(earned.tether_phase, 1, 2):
			return "Latest genuine cycle, exchange identity and phase association must agree"
		if packet.exchange_encounter_id != ENCOUNTER_ID or not _exact_position(packet.exchange.opening_position, TetherScript.FIXED_POSITION) or int(earned.tether_phase) > int(data.tether.phase):
			return "Every executed garden exchange retains the actual fixed external tether"
		if packet.status == "running":
			held += 1
			if int(earned.tether_phase) != int(data.tether.phase) or int(data.tether.phase) == 3:
				return "An older phase cannot reopen the current tether"
		var serial: int = int(String(earned.exchange_id).substr(7))
		if serial > latest_serial:
			latest_serial = serial
			latest_kind = kind
		var view: Variant = control.framing.get(kind)
		if not view is Dictionary or not Codec.keys_error(view, ["landing", "attack_position"]).is_empty():
			return "Exactly the accepted source's historical render points required"
		for key: String in ["landing", "attack_position"]:
			if not Codec.is_vector3(view[key]):
				return "Historical render points must be finite native vectors"
			var point: Vector3 = Codec.read_vector3(view[key])
			if not FLOOR_RECT.grow(-CinderThreatScheduler.CAPSULE_RADIUS).has_point(Vector2(point.x, point.z)) or absf(point.y) > 0.1:
				return "Historical render points must retain firm native capsule support"
	if control.cycle_records.size() != executed.size() or control.framing.size() != executed.size() or held > 1:
		return "Separate teachings retain exactly their genuinely consumed source records"
	var expected_next: String = "draw" if latest_kind.is_empty() or latest_kind == "enclose" else "enclose"
	if control.next_kind != expected_next:
		return "Next teaching preference must follow the last actual accepted serial"
	var prior_clock: float = 0.0
	var prior_serial: int = 0
	for index: int in range(control.boundaries.size()):
		var crossing: Variant = control.boundaries[index]
		if not crossing is Dictionary or not Codec.keys_error(crossing, ["from_phase", "to_phase", "clock_s", "kind", "cycle", "exchange_id"]).is_empty() or not Codec.is_integer(crossing.from_phase, index + 1, index + 1) or not Codec.is_integer(crossing.to_phase, index + 2, index + 2) or not Codec.in_range(crossing.clock_s, prior_clock, float(data.scheduler.clock_s)) or crossing.kind not in executed or not Codec.is_integer(crossing.cycle, 1):
			return "Exactly the recorded two-step phase prefix and monotonic clocks required"
		var packet: Dictionary = data.mechanisms[crossing.kind]
		if int(crossing.cycle) > int(packet.cycle) or not crossing.exchange_id is String or not crossing.exchange_id.begins_with("threat-") or not crossing.exchange_id.substr(7).is_valid_int():
			return "Boundary must reference an already accepted finite native cycle"
		var serial: int = int(crossing.exchange_id.substr(7))
		if serial <= prior_serial or serial > int(data.scheduler.serial) or crossing.exchange_id != "threat-%d" % serial or (index > 0 and float(crossing.clock_s) <= prior_clock):
			return "Boundary must retain a consumed canonical native exchange ID"
		if int(crossing.cycle) == int(packet.cycle):
			var earned: Dictionary = control.cycle_records[crossing.kind]
			if crossing.exchange_id != packet.exchange.id or int(earned.tether_phase) != index + 1 or not Codec.in_range(crossing.clock_s, float(packet.exchange.active_until_s), float(packet.exchange.recovery_until_s)) or float(crossing.clock_s) == float(packet.exchange.active_until_s):
				return "Retained boundary cycle must agree with its actual native recovery"
		elif serial >= int(String(packet.exchange.id).substr(7)) or float(crossing.clock_s) >= float(packet.exchange.start_s):
			return "Replaced boundary cycle must precede the later actual source admission"
		prior_clock = float(crossing.clock_s)
		prior_serial = serial
	var expected_retry: float = 0.0 if control.boundaries.is_empty() else prior_clock + 0.25
	if float(control.retry_at_s) != expected_retry:
		return "Auto-admission retry preference must retain the exact last crossing clock"
	return ""


func _exact_position(value: Array, expected: Vector3) -> bool:
	var encoded: Array = Codec.vector3(expected)
	for index: int in range(3):
		if float(value[index]) != float(encoded[index]):
			return false
	return true


func _restore_local_state(data: Dictionary) -> void:
	# Prevalidation has proved every field. No events, providers, gameplay calls,
	# yields or deferred writes occur in the physical -> native -> control commit.
	var bindings: Dictionary = scheduler_bindings()
	assert(tether.apply_validated_state(data.tether))
	assert(threat_scheduler.restore_state(data.scheduler, bindings))
	for kind: String in mechanisms:
		assert((mechanisms[kind] as CinderLaneMechanism).restore_state(data.mechanisms[kind], bindings))
	_cycle_records = data.control.cycle_records.duplicate(true)
	_cycle_phases.clear()
	for kind: String in _cycle_records:
		_cycle_phases[kind] = int(_cycle_records[kind].tether_phase)
	_views.clear()
	_view_history.clear()
	for kind: String in data.control.framing:
		_view_history[kind] = {"landing": Codec.read_vector3(data.control.framing[kind].landing), "attack_position": Codec.read_vector3(data.control.framing[kind].attack_position)}
	_proofs.clear() # Native transport never authenticates a historical witness.
	_boundaries = data.control.boundaries.duplicate(true)
	_next_kind = data.control.next_kind
	var last_kind: String = "enclose" if _next_kind == "draw" else "draw"
	if _view_history.has(last_kind):
		_views[last_kind] = (_view_history[last_kind] as Dictionary).duplicate(true)
	_retry_at_s = float(data.control.retry_at_s)
	assert(tether.present_checked_exposure(not _logical_exposure().is_empty()))
	_update_guidance()


func _presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	var error: String = runtime_error()
	if not error.is_empty():
		return error
	if not is_instance_valid(camera) or not is_instance_valid(hud):
		return "Actual garden capture Camera and canonical HUD required"
	return String(shared_shell.call("camera_framing_error_for_context", _framing_points_for(camera), hero, camera, hud))


func _restore_candidate_presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	return _presentation_error(camera, hud)


func _update_guidance() -> void:
	objective_text = "ROOT NETWORK SEVERED / RULE PROTOTYPE" if tether.dead else ("LOW TETHER EXPOSED / ORDINARY SLASH" if not _logical_exposure().is_empty() else "ROOT ENDS / READ LOCKED LANE OR BROKEN RING")


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
