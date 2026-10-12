extends Node3D
## IGNORED/UNEXECUTED authored-parent core draft; not a campaign level.
## The parent supplies the one actual Scheduler and immutable native floor.
## Never enters/starts an encounter, dispatches progression, or allocates a kit.

signal phase_boundary(crossing: Dictionary)

const MechanismScript = preload("res://scripts/combat/lane_mechanism.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const CueMeshes = preload("res://scripts/cues/cue_mesh.gd")
const TetherScript = preload("res://scripts/acts/act3/garden_root_tether.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const LOCAL_API: String = "act3-garden-root-network-1"
const RAW_ROLE: Dictionary = {"raw_damage": 8.0, "max_hp": 1.0, "windup_s": 2.2, "lock_s": 1.1, "active_s": 0.2, "recovery_s": 1.8, "attack_interval_s": 4.0, "move_speed": 0.0}
const TIMING_FLOORS: Dictionary = {"windup_s": 2.2, "lock_s": 1.1, "recovery_s": 1.8}
const SOURCE_IDS: Dictionary = {"draw": "l4-garden-draw", "enclose": "l4-garden-enclose"}
const KINDS: Array[String] = ["draw", "enclose"]
const UNIT_KEYS: Array[String] = ["api_revision", "schema_version", "tether", "mechanisms", "control"]

var threat_scheduler: CinderThreatScheduler
var mechanisms: Dictionary = {}
var tether: CinderAct3GardenRootTether
var last_configuration_error: String = ""
var last_admission_reason: String = ""
var last_view_error: String = ""
var last_snapshot_error: String = ""
var _parent_level: CinderLevel
var _hero: CinderPlayer
var _effects: PixelEffects
var _shell: Node
var _world_root: Node3D
var _floors: Dictionary = {}
var _floor_signature: Dictionary = {}
var _floor_native: Array = []
var _response_provider: Callable
var _framing_guard: Callable
var _encounter_id: String = ""
var _world_revision: int = 0
var _configured: bool = false
var _active: bool = false
var _retired: bool = false
var _control_busy: bool = false
var _capture_busy: bool = false
var _views: Dictionary = {}
var _proofs: Dictionary = {}
var _cycle_records: Dictionary = {}
var _view_history: Dictionary = {}
var _boundaries: Array = []
var _next_kind: String = "draw"
var _retry_at_s: float = 0.0
var _pending: Dictionary = {}
var _root_views: Array[MeshInstance3D] = []
var _root_specs: Array = []
var _cue_meshes: Dictionary = {}
# Owned staging is outside the wire. Stage1 has not mutated a native body;
# stage2/3 failures require whole candidate disposal, not a fabricated rollback.
var _quiet_stage: int = 0
var _staged_unit: Dictionary = {}
var _staged_bindings: Dictionary = {}
var _staged_scheduler: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	# Derive the band after Mechanism100 without autonomous admissions.
	process_physics_priority = 110
	for kind: String in KINDS:
		var source: CinderLaneMechanism = MechanismScript.new()
		source.name = "DrawRoots" if kind == "draw" else "EncloseRoots"
		source.position = Vector3(-1, 0, 1.25) if kind == "draw" else Vector3.ZERO
		add_child(source)
		mechanisms[kind] = source
		for sun_choice: int in [0, 1]:
			var shape: Dictionary = _shape(kind, sun_choice)
			var meshes: Dictionary = {"outline": CueMeshes.geometry_mesh(shape, false), "fill": CueMeshes.geometry_mesh(shape, true), "sources": {}}
			for phase_name: String in ["warning", "lock", "active", "recovery"]:
				meshes.sources[phase_name] = CueMeshes.source_mesh(phase_name)
			_cue_meshes[_mesh_key(kind, sun_choice)] = meshes
	for at: Vector3 in [Vector3(-1, 0.08, 1.25), Vector3(1, 0.08, 1.25), Vector3(0, 0.08, 0)]:
		var view := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.22, 0.16, 0.22)
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.albedo_color = Color("68516d")
		view.name = "PhysicalRootEnd" + str(_root_views.size())
		view.mesh = box
		view.material_override = material
		view.position = at
		add_child(view)
		_root_views.append(view)
		_root_specs.append({"size": box.size, "at": at, "material": material, "color": material.albedo_color})
	tether = TetherScript.new()
	tether.name = "ExternalRootTether"
	tether.position = TetherScript.FIXED_POSITION
	add_child(tether)


func configure(actual_parent: CinderLevel, actual_hero: CinderPlayer, actual_effects: PixelEffects, actual_shell: Node, actual_scheduler: CinderThreatScheduler, actual_world_root: Node3D, floors: Dictionary, response_provider: Callable, framing_guard: Callable, encounter_id: String, world_revision: int) -> bool:
	if _configured or not is_inside_tree() or not is_node_ready() or not is_instance_valid(actual_parent) or not actual_parent.is_ancestor_of(self) or not is_instance_valid(actual_hero) or not is_instance_valid(actual_effects) or not is_instance_valid(actual_shell) or not is_instance_valid(actual_scheduler) or not actual_parent.is_ancestor_of(actual_scheduler) or not is_instance_valid(actual_world_root) or not actual_world_root.is_ancestor_of(actual_parent) or not actual_world_root.is_ancestor_of(actual_hero) or not actual_world_root.is_ancestor_of(actual_scheduler):
		return _reject_configuration("Actual parent, single supplied Scheduler, Hero, shell, effects and world ancestry required")
	if actual_parent.hero != actual_hero or actual_parent.effects != actual_effects or actual_parent.shared_shell != actual_shell or actual_scheduler.get_world_3d() != get_world_3d() or actual_hero.get_world_3d() != get_world_3d() or not response_provider.is_valid() or response_provider.get_argument_count() != 2 or not framing_guard.is_valid() or framing_guard.get_argument_count() != 2 or encounter_id.is_empty() or world_revision < 1 or floors.is_empty():
		return _reject_configuration("Actual entered parent bindings, floor and two-argument public response/framing providers required")
	var signature: Dictionary = actual_scheduler.authored_floor_signature(actual_world_root, floors.values())
	if not signature.get("accepted", false):
		return _reject_configuration(String(signature.get("reason", "Actual immutable native floors required")))
	_parent_level = actual_parent
	_hero = actual_hero
	_effects = actual_effects
	_shell = actual_shell
	threat_scheduler = actual_scheduler
	_world_root = actual_world_root
	_floors = floors.duplicate(true)
	_floor_signature = signature.duplicate(true)
	for region: Dictionary in _floors.values():
		var collision: CollisionShape3D = region.collision
		var body: StaticBody3D = collision.get_parent() as StaticBody3D
		_floor_native.append({"collision": collision, "shape": collision.shape, "body": body, "transform": collision.global_transform, "size": (collision.shape as BoxShape3D).size, "layer": body.collision_layer, "mask": body.collision_mask})
	_response_provider = response_provider
	_framing_guard = framing_guard
	_encounter_id = encounter_id
	_world_revision = world_revision
	if not tether.configure(exposure_open, _on_phase_boundary):
		return _reject_configuration("Actual retained tether configuration failed")
	for kind: String in KINDS:
		var source: CinderLaneMechanism = mechanisms[kind]
		if not source.configure(SOURCE_IDS[kind], _shape(kind, 0), tether.global_position, RAW_ROLE, TIMING_FLOORS) or not source.bind(threat_scheduler, {"hero": actual_hero}) or not source.set_presentation_guard(_parent_presentation_guard):
			return _reject_configuration(source.last_error)
	_configured = true
	last_configuration_error = runtime_error()
	return last_configuration_error.is_empty()


func _reject_configuration(reason: String) -> bool:
	last_configuration_error = reason
	return false


func set_active(enabled: bool) -> bool:
	if not _configured or _retired or _control_busy or _quiet_stage != 0 or not runtime_error().is_empty():
		return false
	if not enabled:
		for source: CinderLaneMechanism in mechanisms.values():
			if not threat_scheduler.source_control_state(source).get("reservations", []).is_empty():
				return false # Retire the actual held union before disabling it.
	_active = enabled
	return true


func try_start(kind: String, escape_direction: Vector3, sun_choice: int = 0) -> Dictionary:
	if _control_busy or _quiet_stage != 0 or _capture_busy:
		return {"accepted": false, "reason": "Root-network admission and phase control cannot reenter"}
	_control_busy = true
	var answer: Dictionary = _try_start(kind, escape_direction, sun_choice)
	_control_busy = false
	return answer


func _try_start(kind: String, escape_direction: Vector3, sun_choice: int) -> Dictionary:
	if not _active or _retired or get_tree().paused or tether.dead or kind not in KINDS or sun_choice not in [0, 1] or (tether.phase == 1 and sun_choice != 0) or escape_direction not in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK] or threat_scheduler.get_clock() < _retry_at_s or not runtime_error().is_empty():
		return {"accepted": false, "reason": "Actual live root phase, settled retry boundary and ordinary authored approach required"}
	# Preserve phase1 teaching. Phase2 delegates concurrent roots/helper to the
	# actual common preparing budget and measured timed committed union.
	if tether.phase == 1:
		for sibling: CinderLaneMechanism in mechanisms.values():
			if sibling.state().status == "running":
				return {"accepted": false, "reason": "Phase1 root teachings remain separate"}
	var context_value: Variant = _response_provider.call(kind, escape_direction)
	var context_error: String = _response_error(context_value, escape_direction)
	if not context_error.is_empty():
		return {"accepted": false, "reason": context_error}
	var context: Dictionary = context_value
	var mechanism: CinderLaneMechanism = mechanisms[kind]
	var bearing: Variant = (Vector3.BACK if sun_choice == 0 else Vector3.FORWARD) if kind == "enclose" else null
	var preview: Dictionary = mechanism.preview_start("hero", context, null, bearing)
	if not preview.get("accepted", false):
		last_admission_reason = String(preview.get("reason", "Native root preview rejected"))
		return preview
	var frame: Dictionary = {"landing": preview.proof.landing, "attack_position": preview.proof.attack_position}
	var prospective: Dictionary = {"kind": kind, "sun_choice": sun_choice, "geometry": _shape(kind, sun_choice), "framing": frame.duplicate(true)}
	last_view_error = _guard_error(false, prospective)
	if last_view_error.is_empty():
		last_view_error = _guard_error(true, prospective)
	if not last_view_error.is_empty() or not _active or _retired or get_tree().paused or not runtime_error().is_empty():
		return {"accepted": false, "reason": last_view_error if not last_view_error.is_empty() else "Actual root custody changed during pure view proof"}
	var admitted_phase: int = tether.phase
	# The pending receipt exists only through native synchronous warning/guard
	# callbacks; it does not earn history or replace any sibling's held frame.
	_pending = prospective.duplicate(true)
	var answer: Dictionary = mechanism.start("hero", context, null, bearing, preview)
	_pending.clear()
	last_admission_reason = "" if answer.get("accepted", false) else String(answer.get("reason", "Native root admission rejected"))
	if answer.get("accepted", false):
		_cycle_records[kind] = {"cycle": mechanism.state().cycle, "exchange_id": String(answer.reservation_id), "tether_phase": admitted_phase, "sun_choice": sun_choice}
		_view_history[kind] = frame.duplicate(true)
		_views[kind] = frame.duplicate(true)
		_proofs[kind] = answer.proof.duplicate(true)
		_next_kind = "enclose" if kind == "draw" else "draw"
	return answer


func _response_error(value: Variant, direction: Vector3) -> String:
	if not value is Dictionary or not Codec.keys_error(value, CinderLaneMechanism.RESPONSE_KEYS).is_empty():
		return "Closed public native response context required"
	if value.encounter_id != _encounter_id or value.world_revision != _world_revision or not Codec.in_range(value.recognition_s, 0.0, 10.0) or not Codec.in_range(value.attack_input_margin_s, 0.0, 10.0) or value.escape_directions != [direction] or value.return_directions != [-direction] or value.floor_regions != _floors.values():
		return "Response must retain this actual encounter, floor and selected ordinary escape/return"
	return ""


func _guard_error(current_view: bool, prospective: Dictionary = {}) -> String:
	if not _framing_guard.is_valid():
		return "Actual parent complete-union framing provider required"
	var result: Variant = _framing_guard.call(current_view, prospective.duplicate(true))
	return result if result is String else "Parent native framing provider must return a String"


func _parent_presentation_guard(_mechanism_id: String, _current: Dictionary) -> bool:
	if not _active or _retired or not runtime_error().is_empty():
		return false
	last_view_error = _guard_error(true, _pending)
	return last_view_error.is_empty() and _active and not _retired and not get_tree().paused and runtime_error().is_empty()


func exposure_open() -> bool:
	if not _active or _retired or _control_busy or _quiet_stage != 0 or get_tree().paused or tether.dead or not runtime_error().is_empty():
		return false
	var exposure: Dictionary = logical_exposure()
	if exposure.is_empty() or not _guard_error(true).is_empty():
		return false
	# A parent callback cannot authorize damage after synchronous retirement.
	return _active and not _retired and not get_tree().paused and not tether.dead and runtime_error().is_empty() and logical_exposure() == exposure


func logical_exposure(target_phase: int = 0) -> Dictionary:
	# Pure/non-pruning. Quiet candidate presentation does not enable damage.
	var required_phase: int = tether.phase if target_phase == 0 else target_phase
	if not _configured or _retired or required_phase not in [1, 2]:
		return {}
	for kind: String in KINDS:
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


func _on_phase_boundary() -> void:
	var was_busy: bool = _control_busy
	_control_busy = true
	var triggering: Dictionary = logical_exposure(tether.phase - 1)
	var crossing: Dictionary = {}
	if triggering.is_empty():
		last_configuration_error = "Genuine accepted native recovery must precede a root phase crossing"
	else:
		crossing = {"from_phase": tether.phase - 1, "to_phase": tether.phase, "clock_s": threat_scheduler.get_clock(), "kind": triggering.kind, "cycle": triggering.cycle, "exchange_id": triggering.exchange_id}
		_boundaries.append(crossing.duplicate(true))
	for source: CinderLaneMechanism in mechanisms.values():
		source.cancel("garden_phase_boundary")
	_retry_at_s = threat_scheduler.get_clock() + 0.25
	if not crossing.is_empty() and not _retired:
		# Parent may genuinely install one phase2 helper, update sun/route and
		# queue a checkpoint here; it cannot reenter native root admission.
		phase_boundary.emit(crossing.duplicate(true))
	_control_busy = was_busy


func _physics_process(_delta: float) -> void:
	if not _configured or not _active or _retired or _quiet_stage != 0:
		return
	var error: String = runtime_error()
	if not error.is_empty():
		last_configuration_error = error
		retire("garden_required_parent_unavailable")
		return
	for source: CinderLaneMechanism in mechanisms.values():
		if source.state().status == "running" and not _parent_presentation_guard("", {}):
			source.cancel("garden_actual_view_unreadable")
	# Keep the original live damage-provider-derived appearance; the checked
	# palette seam below is exclusively for paused quiet restoration.
	tether.present()


func retire(reason: String = "garden_parent_exit") -> void:
	if _retired:
		return
	var was_busy: bool = _control_busy
	_control_busy = true
	_active = false
	_retired = true
	for source: CinderLaneMechanism in mechanisms.values():
		if is_instance_valid(source) and source.is_inside_tree():
			source.cancel(reason)
	# Do not reset/end the parent encounter or erase any managed history.
	_control_busy = was_busy


func scheduler_owners() -> Dictionary:
	return {SOURCE_IDS.draw: mechanisms.draw, SOURCE_IDS.enclose: mechanisms.enclose} if _configured else {}


func get_tether() -> CinderAct3GardenRootTether:
	return tether


func get_mechanisms() -> Dictionary:
	return mechanisms.duplicate()


func get_selected_response(kind: String) -> Dictionary:
	return (_views.get(kind, {}) as Dictionary).duplicate(true)


func state() -> Dictionary:
	var sources: Dictionary = {}
	for kind: String in KINDS:
		sources[kind] = (mechanisms[kind] as CinderLaneMechanism).state()
	return {"active": _active, "retired": _retired, "configuration_error": last_configuration_error, "admission_reason": last_admission_reason, "camera_error": last_view_error, "mechanisms": sources, "hp": tether.hp, "phase": tether.phase, "dead": tether.dead, "proofs": _proofs.duplicate(true), "next_kind": _next_kind, "retry_at_s": _retry_at_s, "clock_s": threat_scheduler.get_clock() if is_instance_valid(threat_scheduler) else 0.0}


func runtime_error() -> String:
	if not _configured or not is_inside_tree() or not is_node_ready() or is_queued_for_deletion() or not is_visible_in_tree() or global_transform != Transform3D.IDENTITY or top_level or process_mode != Node.PROCESS_MODE_PAUSABLE or process_physics_priority != 110 or not is_instance_valid(_parent_level) or not _parent_level.is_ancestor_of(self) or not is_instance_valid(_hero) or _parent_level.hero != _hero or not is_instance_valid(_effects) or _parent_level.effects != _effects or not is_instance_valid(_shell) or _parent_level.shared_shell != _shell or not is_instance_valid(threat_scheduler) or not _parent_level.is_ancestor_of(threat_scheduler) or not is_instance_valid(_world_root):
		return "Actual configured identity-transform parent/core/Hero/Scheduler/effects/shell bindings required"
	for node: Node3D in [_parent_level, _hero, threat_scheduler, _world_root]:
		if not node.is_inside_tree() or not node.is_node_ready() or node.is_queued_for_deletion() or node.get_world_3d() != get_world_3d():
			return "Core dependencies must remain in their actual ready native world"
	if _parent_level.global_transform != Transform3D.IDENTITY or not _world_root.is_ancestor_of(_parent_level) or not _world_root.is_ancestor_of(_hero) or not _world_root.is_ancestor_of(threat_scheduler):
		return "Original identity-transform parent and shared world ancestry required"
	if threat_scheduler.process_physics_priority >= 100 or _hero.process_physics_priority >= 100:
		return "Actual Scheduler and Hero must precede native Mechanism100"
	var signature: Dictionary = threat_scheduler.authored_floor_signature(_world_root, _floors.values())
	if not signature.get("accepted", false) or signature != _floor_signature:
		return "Original supplied immutable native parent floor signature required"
	for stamp: Dictionary in _floor_native:
		var collision: CollisionShape3D = stamp.collision
		var body: StaticBody3D = stamp.body
		if not is_instance_valid(collision) or not is_instance_valid(body) or collision.get_parent() != body or collision.shape != stamp.shape or collision.global_transform != stamp.transform or not collision.shape is BoxShape3D or (collision.shape as BoxShape3D).size != stamp.size or body.collision_layer != stamp.layer or body.collision_mask != stamp.mask:
			return "Actual supplied floor shape, transform, layer and mask custody changed"
	for kind: String in KINDS:
		var source: CinderLaneMechanism = mechanisms.get(kind) as CinderLaneMechanism
		var at: Vector3 = Vector3(-1, 0, 1.25) if kind == "draw" else Vector3.ZERO
		if not is_instance_valid(source) or source.get_parent() != self or source.global_transform != Transform3D(Basis.IDENTITY, at) or source.top_level or source.process_mode != Node.PROCESS_MODE_PAUSABLE or source.process_physics_priority != 100 or not source.is_visible_in_tree() or source.get_cue() == null or not source.get_cue().is_visible_in_tree():
			return "Both fixed native sources and their required cues must remain present"
		var control: Dictionary = threat_scheduler.source_control_state(source)
		if control.is_empty() or (not String(control.encounter_id).is_empty() and (control.encounter_id != _encounter_id or control.world_revision != _world_revision)):
			return "Source must retain the parent actual encounter/world epoch"
		var cue_error: String = _cue_error(kind, source.state())
		if not cue_error.is_empty():
			return cue_error
	for index: int in range(_root_views.size()):
		var view: MeshInstance3D = _root_views[index]
		var spec: Dictionary = _root_specs[index]
		if not is_instance_valid(view) or not view.is_visible_in_tree() or view.get_parent() != self or view.global_transform != Transform3D(Basis.IDENTITY, spec.at) or not view.mesh is BoxMesh or (view.mesh as BoxMesh).size != spec.size or view.material_override != spec.material or view.layers != 1 or view.transparency != 0.0 or view.material_overlay != null or view.visibility_range_begin != 0.0 or view.visibility_range_end != 0.0 or view.top_level:
			return "All three complete root ends must stay fixed and visible"
		var material: StandardMaterial3D = spec.material as StandardMaterial3D
		if material == null or material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.no_depth_test or material.albedo_color != spec.color or material.albedo_texture != null or material.next_pass != null or material.grow or material.proximity_fade_enabled or material.distance_fade_mode != BaseMaterial3D.DISTANCE_FADE_DISABLED:
			return "Opaque nearest restrained native root ends required"
		for surface: int in range(view.mesh.get_surface_count()):
			if view.get_surface_override_material(surface) != null or view.mesh.surface_get_material(surface) != null:
				return "Root-end native surfaces cannot replace the retained opaque material"
	if not is_instance_valid(tether) or tether.get_parent() != self:
		return "Actual fixed low tether required"
	return tether.runtime_error()


func capture(bindings: Dictionary, paired_scheduler: Dictionary) -> Dictionary:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty():
		return {}
	_capture_busy = true
	var player: Dictionary = _hero.snapshot_state()
	var error: String = _binding_error(bindings)
	if error.is_empty():
		error = threat_scheduler.snapshot_error(paired_scheduler, bindings)
	if error.is_empty():
		var actual_pair: Dictionary = threat_scheduler.snapshot_state(bindings)
		if actual_pair.is_empty():
			error = threat_scheduler.last_snapshot_error
		elif not _same_exact(actual_pair, paired_scheduler):
			error = "Capture must retain the independently captured full current native Scheduler unit"
	if error.is_empty():
		error = tether.presentation_error(not logical_exposure().is_empty())
	var parts: Dictionary = {}
	if error.is_empty():
		for kind: String in KINDS:
			parts[kind] = (mechanisms[kind] as CinderLaneMechanism).snapshot_state(bindings)
			if parts[kind].is_empty():
				error = (mechanisms[kind] as CinderLaneMechanism).last_snapshot_error
				break
	var target: Dictionary = tether.snapshot_state(float(paired_scheduler.clock_s)) if error.is_empty() else {}
	if error.is_empty() and target.is_empty():
		error = tether.snapshot_access_error()
	var history: Dictionary = {}
	for kind: String in _view_history:
		history[kind] = {"landing": Codec.vector3(_view_history[kind].landing), "attack_position": Codec.vector3(_view_history[kind].attack_position)}
	var unit: Dictionary = {"api_revision": LOCAL_API, "schema_version": 1, "tether": target, "mechanisms": parts, "control": {"next_kind": _next_kind, "retry_at_s": _retry_at_s, "cycle_records": _cycle_records.duplicate(true), "framing": history, "boundaries": _boundaries.duplicate(true)}} if error.is_empty() else {}
	_capture_busy = false
	if error.is_empty():
		error = snapshot_error(unit, player, bindings, paired_scheduler)
	last_snapshot_error = error
	return unit if error.is_empty() else {}


func _snapshot_access_error() -> String:
	if not _configured or _retired or not get_tree().paused or _control_busy or _capture_busy or _quiet_stage != 0:
		return "Root core transport requires settled paused configured native topology outside callbacks/staging"
	return runtime_error()


func _binding_error(bindings: Dictionary) -> String:
	if bindings.get("world_root") != _world_root or not bindings.get("owners") is Dictionary or not bindings.get("actors") is Dictionary or bindings.actors.get("hero") != _hero or not bindings.get("floors") is Dictionary:
		return "Parent complete actual world/owner/single-Hero/floor bindings required"
	for kind: String in KINDS:
		if bindings.owners.get(SOURCE_IDS[kind]) != mechanisms[kind]:
			return "Parent owner map must retain both actual core sources"
	for id: String in _floors:
		if bindings.floors.get(id) != _floors[id]:
			return "Actual supplied root-court floors must remain in the full parent map"
	return ""


func snapshot_error(unit: Dictionary, saved_player: Dictionary, bindings: Dictionary, paired_scheduler: Dictionary) -> String:
	var error: String = _snapshot_access_error()
	if error.is_empty():
		error = Codec.value_error(unit)
	if error.is_empty():
		error = Codec.keys_error(unit, UNIT_KEYS)
	if not error.is_empty():
		return error
	if unit.api_revision != LOCAL_API or not Codec.is_integer(unit.schema_version, 1, 1) or not unit.tether is Dictionary or not unit.mechanisms is Dictionary or not unit.control is Dictionary or not Codec.keys_error(unit.mechanisms, KINDS).is_empty():
		return "Closed complete tether/two-mechanism/control core schema required"
	error = _hero.snapshot_error(saved_player)
	if error.is_empty():
		error = _binding_error(bindings)
	if not error.is_empty():
		return error
	var staged: Dictionary = bindings.duplicate(true)
	staged["hero_positions"] = {"hero": Codec.read_vector3(saved_player.motion.position)}
	error = threat_scheduler.snapshot_error(paired_scheduler, staged)
	if not error.is_empty():
		return error
	if paired_scheduler.encounter_id != _encounter_id or int(paired_scheduler.world_revision) != _world_revision:
		return "Actual original parent encounter/world epoch required"
	error = tether.snapshot_error(unit.tether, float(paired_scheduler.clock_s))
	if not error.is_empty():
		return error
	for kind: String in KINDS:
		if not unit.mechanisms[kind] is Dictionary:
			return "Both complete actual native mechanism packets required"
		error = (mechanisms[kind] as CinderLaneMechanism).snapshot_error(unit.mechanisms[kind], staged, paired_scheduler)
		if not error.is_empty():
			return error
	return _control_error(unit, paired_scheduler, staged)


func stage_quiet_restore(unit: Dictionary, saved_player: Dictionary, bindings: Dictionary, paired_scheduler: Dictionary) -> bool:
	# Whole parent validation precedes this extra pure leaf preflight. No native
	# state changes here; admissions/capture are blocked until commit/disposal.
	last_snapshot_error = snapshot_error(unit, saved_player, bindings, paired_scheduler)
	if not last_snapshot_error.is_empty():
		return false
	_staged_unit = unit.duplicate(true)
	_staged_bindings = bindings.duplicate(true)
	_staged_scheduler = paired_scheduler.duplicate(true)
	_quiet_stage = 1
	return true


func abort_uncommitted_restore() -> bool:
	if _quiet_stage != 1 or not get_tree().paused:
		return false
	_clear_staging()
	return true


func apply_staged_target() -> bool:
	if _quiet_stage != 1 or not get_tree().paused or _control_busy or _retired:
		return false
	var committed: bool = tether.apply_validated_state(_staged_unit.tether)
	if committed:
		_quiet_stage = 2
	return committed


func restore_staged_mechanisms() -> bool:
	# Parent has restored Hero/all physical bodies, full Scheduler and each
	# managed Playback. Native Mech restore independently reads that Scheduler.
	if _quiet_stage != 2 or not get_tree().paused or _control_busy or _retired or threat_scheduler.get_clock() != float(_staged_scheduler.clock_s):
		return false
	for kind: String in KINDS:
		var committed: bool = (mechanisms[kind] as CinderLaneMechanism).restore_state(_staged_unit.mechanisms[kind], _staged_bindings)
		if not committed:
			last_snapshot_error = (mechanisms[kind] as CinderLaneMechanism).last_snapshot_error
			return false
	_quiet_stage = 3
	return true


func finish_staged_restore() -> bool:
	if _quiet_stage != 3 or not get_tree().paused or _control_busy or _retired:
		return false
	var control: Dictionary = _staged_unit.control
	_cycle_records = control.cycle_records.duplicate(true)
	_view_history.clear()
	_views.clear()
	for kind: String in control.framing:
		_view_history[kind] = {"landing": Codec.read_vector3(control.framing[kind].landing), "attack_position": Codec.read_vector3(control.framing[kind].attack_position)}
		if (mechanisms[kind] as CinderLaneMechanism).state().status == "running":
			_views[kind] = (_view_history[kind] as Dictionary).duplicate(true)
	_proofs.clear() # Saved historical render points do not authenticate witnesses.
	_boundaries = control.boundaries.duplicate(true)
	_next_kind = control.next_kind
	_retry_at_s = float(control.retry_at_s)
	var presented: bool = tether.present_checked_exposure(not logical_exposure().is_empty())
	if not presented:
		last_snapshot_error = "Quiet restored target palette failed actual native custody"
		return false
	_clear_staging()
	return true


func _clear_staging() -> void:
	_quiet_stage = 0
	_staged_unit.clear()
	_staged_bindings.clear()
	_staged_scheduler.clear()


func presentation_error() -> String:
	var error: String = runtime_error()
	return tether.presentation_error(not logical_exposure().is_empty()) if error.is_empty() else error


func framing_points_for_context(camera: Camera3D, prospective: Dictionary = {}) -> Dictionary:
	var error: String = runtime_error()
	if not error.is_empty():
		return {"accepted": false, "reason": error, "points": []}
	if not prospective.is_empty():
		error = _prospective_error(prospective)
		if not error.is_empty():
			return {"accepted": false, "reason": error, "points": []}
	var native_player: Array = _shell.call("player_camera_framing_points_for", _hero, camera) if is_instance_valid(camera) and _shell.has_method("player_camera_framing_points_for") else []
	if native_player.is_empty():
		return {"accepted": false, "reason": "Actual native current Camera and configured Hero corners required", "points": []}
	var points: Array = _enclosing_corners(native_player)
	for view: MeshInstance3D in _root_views:
		points.append_array(_mesh_corners(view.mesh, view.global_transform))
	points.append_array(tether.framing_points())
	var frames: Dictionary = {}
	for kind: String in KINDS:
		var current: Dictionary = (mechanisms[kind] as CinderLaneMechanism).state()
		var choice: int = int((_cycle_records.get(kind, {}) as Dictionary).get("sun_choice", 0))
		if _pending.get("kind") == kind:
			choice = int(_pending.sun_choice)
		var shape: Dictionary = current.geometry if current.status == "running" else _shape(kind, choice)
		if prospective.get("kind") == kind:
			shape = prospective.geometry
			choice = int(prospective.sun_choice)
		points.append_array(_forecast_corners(kind, choice, shape))
		if current.status == "running" and _view_history.has(kind):
			frames[kind] = (_view_history[kind] as Dictionary).duplicate(true)
		if _pending.get("kind") == kind:
			frames[kind] = (_pending.framing as Dictionary).duplicate(true)
		if prospective.get("kind") == kind:
			frames[kind] = (prospective.framing as Dictionary).duplicate(true)
	for frame: Dictionary in frames.values():
		for key: String in ["landing", "attack_position"]:
			var shifted: Array = []
			for point: Vector3 in native_player:
				shifted.append(point + (frame[key] as Vector3) - _hero.global_position)
			points.append_array(_enclosing_corners(shifted))
	if points.size() > 224:
		return {"accepted": false, "reason": "Complete native root/current-Hero union exceeds public corner budget", "points": []}
	return {"accepted": true, "reason": "", "points": points}


func _prospective_error(value: Dictionary) -> String:
	if not Codec.keys_error(value, ["kind", "sun_choice", "geometry", "framing"]).is_empty() or value.kind not in KINDS or not Codec.is_integer(value.sun_choice, 0, 1) or not value.geometry is Dictionary or value.geometry != _shape(value.kind, int(value.sun_choice)) or not value.framing is Dictionary or not Codec.keys_error(value.framing, ["landing", "attack_position"]).is_empty():
		return "Exactly one native chosen root shape and its measured response frame required"
	for key: String in ["landing", "attack_position"]:
		if not value.framing[key] is Vector3 or not value.framing[key].is_finite():
			return "Prospective render points must be actual finite native vectors"
	return ""


func _forecast_corners(kind: String, sun_choice: int, shape: Dictionary) -> Array:
	var meshes: Dictionary = _cue_meshes[_mesh_key(kind, sun_choice)]
	var bounds: Array = []
	for filled: bool in [false, true]:
		bounds.append_array(_mesh_corners(meshes.fill if filled else meshes.outline, Transform3D(Basis.IDENTITY, CueMeshes.anchor(shape) + Vector3.UP * (CinderThreatCue.FLOOR_OFFSET - (0.004 if filled else 0.0)))))
	for phase_name: String in ["warning", "lock", "active", "recovery"]:
		bounds.append_array(_mesh_corners(meshes.sources[phase_name], Transform3D(Basis.IDENTITY, (mechanisms[kind] as Node3D).global_position + Vector3.UP * (CinderThreatCue.FLOOR_OFFSET + 0.004))))
	return _enclosing_corners(bounds)


func _shape(kind: String, sun_choice: int = 0) -> Dictionary:
	return Geometry.lane(Vector3(-1, 0, 1.25), Vector3(1, 0, 1.25), 0.28) if kind == "draw" else Geometry.crescent(Vector3.ZERO, Vector3.BACK if sun_choice == 0 else Vector3.FORWARD, 0.75, 1.65, 0.5)


func _mesh_key(kind: String, sun_choice: int) -> String:
	return kind + ":" + str(sun_choice)


func _encoded_shape(kind: String, sun_choice: int) -> Dictionary:
	var shape: Dictionary = _shape(kind, sun_choice)
	if kind == "draw":
		return {"kind": "lane", "from": Codec.vector3(shape.from), "to": Codec.vector3(shape.to), "radius": shape.radius}
	return {"kind": "crescent", "origin": Codec.vector3(shape.origin), "direction": Codec.vector3(shape.direction), "inner_radius": shape.inner_radius, "outer_radius": shape.outer_radius, "min_dot": shape.min_dot}


func _history_supported(point: Vector3, bindings: Dictionary) -> bool:
	if not point.is_finite() or absf(point.y) > 0.1:
		return false
	for region: Dictionary in bindings.floors.values():
		if region.safe_rect.grow(-CinderThreatScheduler.CAPSULE_RADIUS).has_point(Vector2(point.x, point.z)):
			return true
	return false


func _control_error(data: Dictionary, paired_scheduler: Dictionary, bindings: Dictionary) -> String:
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
	var total_cycles: int = 0
	var seen_serials: Dictionary = {}
	for kind: String in ["draw", "enclose"]:
		var packet: Dictionary = data.mechanisms[kind]
		total_cycles += int(packet.cycle)
		if int(packet.cycle) == 0:
			if control.cycle_records.has(kind) or control.framing.has(kind):
				return "Idle source cannot invent accepted cycle or response presentation"
			continue
		executed.append(kind)
		var earned: Variant = control.cycle_records.get(kind)
		if not earned is Dictionary or not Codec.keys_error(earned, ["cycle", "exchange_id", "tether_phase", "sun_choice"]).is_empty() or not Codec.is_integer(earned.cycle, 1) or earned.cycle != packet.cycle or earned.exchange_id != packet.exchange.id or not Codec.is_integer(earned.tether_phase, 1, 2) or not Codec.is_integer(earned.sun_choice, 0, 1) or (int(earned.tether_phase) == 1 and int(earned.sun_choice) != 0):
			return "Latest genuine cycle, exchange identity and phase association must agree"
		if packet.exchange_encounter_id != _encounter_id or packet.exchange.profile_id != paired_scheduler.profile.id or int(packet.exchange.world_revision) != int(paired_scheduler.world_revision) or float(packet.exchange.start_s) > float(paired_scheduler.clock_s) or not _exact_position(packet.exchange.opening_position, TetherScript.FIXED_POSITION) or int(earned.tether_phase) > int(data.tether.phase):
			return "Every executed garden exchange retains the actual fixed external tether"
		if not _same_exact(packet.exchange.geometry, _encoded_shape(kind, int(earned.sun_choice))):
			return "Accepted native geometry must retain this actual source and selected sun bearing"
		if packet.status == "running":
			held += 1
			if int(earned.tether_phase) != int(data.tether.phase) or int(data.tether.phase) == 3:
				return "An older phase cannot reopen the current tether"
		var serial: int = int(String(earned.exchange_id).substr(7))
		if serial < 1 or serial > int(paired_scheduler.serial) or int(packet.cycle) > serial or seen_serials.has(serial) or earned.exchange_id != "threat-%d" % serial:
			return "Distinct consumed source cycles cannot exceed the paired native serial"
		seen_serials[serial] = true
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
			if not _history_supported(point, bindings):
				return "Historical render points must retain firm native capsule support"
	if control.cycle_records.size() != executed.size() or control.framing.size() != executed.size() or held > (1 if int(data.tether.phase) == 1 else 2) or total_cycles > int(paired_scheduler.serial):
		return "Root phases retain exactly their genuinely consumed source records"
	var expected_next: String = "draw" if latest_kind.is_empty() or latest_kind == "enclose" else "enclose"
	if control.next_kind != expected_next:
		return "Next teaching preference must follow the last actual accepted serial"
	var prior_clock: float = 0.0
	var prior_serial: int = 0
	for index: int in range(control.boundaries.size()):
		var crossing: Variant = control.boundaries[index]
		if not crossing is Dictionary or not Codec.keys_error(crossing, ["from_phase", "to_phase", "clock_s", "kind", "cycle", "exchange_id"]).is_empty() or not Codec.is_integer(crossing.from_phase, index + 1, index + 1) or not Codec.is_integer(crossing.to_phase, index + 2, index + 2) or not Codec.in_range(crossing.clock_s, prior_clock, float(paired_scheduler.clock_s)) or crossing.kind not in executed or not Codec.is_integer(crossing.cycle, 1):
			return "Exactly the recorded two-step phase prefix and monotonic clocks required"
		var packet: Dictionary = data.mechanisms[crossing.kind]
		if int(crossing.cycle) > int(packet.cycle) or not crossing.exchange_id is String or not crossing.exchange_id.begins_with("threat-") or not crossing.exchange_id.substr(7).is_valid_int():
			return "Boundary must reference an already accepted finite native cycle"
		var serial: int = int(crossing.exchange_id.substr(7))
		if serial <= prior_serial or serial > int(paired_scheduler.serial) or crossing.exchange_id != "threat-%d" % serial or (index > 0 and float(crossing.clock_s) <= prior_clock):
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
		return "Admission retry preference must retain the exact last crossing clock"
	for kind: String in executed:
		var admitted_phase: int = 1
		var start_s: float = float(data.mechanisms[kind].exchange.start_s)
		for crossing: Dictionary in control.boundaries:
			if start_s >= float(crossing.clock_s):
				admitted_phase = int(crossing.to_phase)
		if int(control.cycle_records[kind].tether_phase) != admitted_phase or admitted_phase > 2:
			return "Accepted source phase must agree with admission time and the real boundary prefix"
	return ""


func _exact_position(value: Array, expected: Vector3) -> bool:
	var encoded: Array = Codec.vector3(expected)
	for index: int in range(3):
		if float(value[index]) != float(encoded[index]):
			return false
	return true


func _cue_error(kind: String, current: Dictionary) -> String:
	if current.status != "running":
		return ""
	var cue: CinderThreatCue = (mechanisms[kind] as CinderLaneMechanism).get_cue()
	var phase_name: String = String(current.phase)
	var cue_state: Dictionary = cue.state()
	var choice: int = int((_cycle_records.get(kind, {}) as Dictionary).get("sun_choice", 0))
	if _pending.get("kind") == kind:
		choice = int(_pending.sun_choice)
	if current.geometry != _shape(kind, choice):
		return "Held root geometry cannot retarget or substitute another sun bearing"
	var anchor: Vector3 = CueMeshes.anchor(current.geometry)
	var expected_meshes: Dictionary = _cue_meshes[_mesh_key(kind, choice)]
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
		var expected: ArrayMesh = expected_meshes.sources[phase_name] if marker else (expected_meshes.fill if filled else expected_meshes.outline)
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


func _same_exact(left: Variant, right: Variant) -> bool:
	if Codec.is_number(left) and Codec.is_number(right):
		return float(left) == float(right)
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size():
			return false
		for key: String in left:
			if not right.has(key) or not _same_exact(left[key], right[key]):
				return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size():
			return false
		for index: int in range(left.size()):
			if not _same_exact(left[index], right[index]):
				return false
		return true
	return typeof(left) == typeof(right) and left == right
