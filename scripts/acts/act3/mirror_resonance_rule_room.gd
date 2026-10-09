extends CinderLevel
## Isolated finite environmental pulse. Shared LaneMechanism owns all damage,
## deadlines and sampling; its circle is a FILLED DISK, not the proposed ring.

const Shore = preload("res://scripts/acts/act3/mirror_sea_scenery.gd")
const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const MechanismScript = preload("res://scripts/combat/lane_mechanism.gd")
const Shape = preload("res://scripts/combat/threat_geometry.gd")
const CueMeshes = preload("res://scripts/cues/cue_mesh.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const LOCAL_API: String = "act3-mirror-resonance-room-1"
const SOURCE_ID: String = "mirror-resonance/pulse"
const ENCOUNTER_ID: String = "A3-L3/resonance-rule-room"
const FLOOR_RECT: Rect2 = Rect2(-7, -11, 14, 22)
const DISK_RADIUS: float = 1.15

var scenery: Node3D
var threat_scheduler: CinderThreatScheduler
var mechanism: CinderLaneMechanism
var last_configuration_error: String = ""
var last_admission_reason: String = ""
var last_view_error: String = ""
var _floor: Dictionary = {}
var _active: bool = false
var _view: Dictionary = {}
var _proof: Dictionary = {}
var _static_bounds: Array = []
var _source_view: MeshInstance3D
var _source_mesh: BoxMesh
var _source_material: StandardMaterial3D
var _restore_error: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 90 # Actual current view guard precedes mechanism100.
	scenery = Shore.new()
	scenery.name = "MirrorSeaScenery"
	add_child(scenery)
	scenery.call("build", true)
	var floor_body: StaticBody3D = scenery.get("floor_body") as StaticBody3D
	var solid: CollisionShape3D = floor_body.get_node_or_null("Solid") as CollisionShape3D if floor_body != null else null
	if solid == null:
		last_configuration_error = "Resonance requires the actual continuous shore floor"
		return
	_floor = {"collision": solid, "safe_rect": FLOOR_RECT}
	threat_scheduler = SchedulerScript.new()
	threat_scheduler.name = "ResonanceScheduler"
	add_child(threat_scheduler)
	mechanism = MechanismScript.new()
	mechanism.name = "FixedResonanceSource"
	add_child(mechanism)
	_source_view = MeshInstance3D.new()
	_source_view.name = "QuietFixedMineralSource"
	_source_mesh = BoxMesh.new()
	_source_mesh.size = Vector3(0.22, 0.12, 0.22)
	_source_view.mesh = _source_mesh
	_source_material = StandardMaterial3D.new()
	_source_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_source_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_source_material.albedo_color = Color("787184")
	_source_view.material_override = _source_material
	_source_view.position.y = 0.06
	_source_view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mechanism.add_child(_source_view)
	var disk: Dictionary = Shape.circle(Vector3.ZERO, DISK_RADIUS)
	for filled: bool in [false, true]:
		_static_bounds.append_array(_mesh_corners(CueMeshes.geometry_mesh(disk, filled), Transform3D(Basis.IDENTITY, Vector3.UP * CinderThreatCue.FLOOR_OFFSET)))
	for phase: String in ["warning", "lock", "active", "recovery"]:
		_static_bounds.append_array(_mesh_corners(CueMeshes.source_mesh(phase), Transform3D(Basis.IDENTITY, Vector3.UP * (CinderThreatCue.FLOOR_OFFSET + 0.004))))
	_static_bounds.append_array(_mesh_corners(_source_mesh, _source_view.transform))


func _on_enter_level() -> void:
	if not last_configuration_error.is_empty():
		return
	var profile: String = "standard"
	if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference"):
		profile = String(shared_shell.call("get_difficulty_preference"))
	if not threat_scheduler.begin_encounter(profile, ENCOUNTER_ID, 1) or not mechanism.configure(SOURCE_ID, Shape.circle(Vector3.ZERO, DISK_RADIUS), Vector3.ZERO) or not mechanism.bind(threat_scheduler, {"hero": hero}):
		last_configuration_error = threat_scheduler.last_error + "; " + mechanism.last_error
		return
	mechanism.state_changed.connect(_on_mechanism_phase)
	_active = true
	scenery.call("follow_landmarks", hero.global_position)
	_update_guidance()


func _on_exit_level() -> void:
	_active = false
	if is_instance_valid(threat_scheduler):
		threat_scheduler.end_encounter("mirror_resonance_room_exit")


func response_context() -> Dictionary:
	return {"encounter_id": ENCOUNTER_ID, "world_revision": 1, "recognition_s": 0.25, "attack_input_margin_s": 0.06, "escape_directions": [Vector3.RIGHT], "return_directions": [Vector3.LEFT], "floor_regions": [_floor]}


func scheduler_bindings() -> Dictionary:
	return {"world_root": get_parent(), "owners": {SOURCE_ID: mechanism}, "actors": {"hero": hero}, "floors": {"firm-shore": _floor}}


func get_selected_response() -> Dictionary:
	return _view.duplicate(true)


func state() -> Dictionary:
	return {"api_revision": LOCAL_API, "configuration_error": last_configuration_error, "admission_reason": last_admission_reason, "camera_error": last_view_error, "mechanism": mechanism.state() if is_instance_valid(mechanism) else {}, "proof": _proof.duplicate(true), "clock_s": threat_scheduler.get_clock() if is_instance_valid(threat_scheduler) else -1.0}


func _physics_process(_delta: float) -> void:
	if not _active:
		return
	var error: String = runtime_error()
	if not error.is_empty():
		last_configuration_error = error
		mechanism.cancel("resonance_native_dependency_unavailable")
		return
	scenery.call("follow_landmarks", hero.global_position)
	var current: Dictionary = mechanism.state()
	if int(current.cycle) == 0 and hero.is_on_floor() and hero.get_threat_response_state().stable:
		_try_start()
	elif current.status == "running":
		_guard_current()
	_update_guidance()


func _try_start() -> void:
	var preview: Dictionary = mechanism.preview_start("hero", response_context())
	if not preview.get("accepted", false):
		last_admission_reason = String(preview.get("reason", "Stationary preview rejected"))
		return
	_view = {"landing": preview.proof.landing, "attack_position": preview.proof.attack_position}
	var points: Array = camera_framing_points()
	var plan: Dictionary = shared_shell.call("camera_framing_plan", points, hero.global_position + Vector3.UP * 0.75)
	last_view_error = "" if plan.get("accepted", false) else String(plan.get("reason", "Pulse cannot fit the fixed view"))
	if last_view_error.is_empty():
		last_view_error = String(shared_shell.call("camera_framing_error", points))
	if not last_view_error.is_empty():
		return # Normal shared idle camera translation settles the visible forecast.
	var answer: Dictionary = mechanism.start("hero", response_context(), null, null, preview)
	last_admission_reason = "" if answer.get("accepted", false) else String(answer.get("reason", "Actual admission rejected"))
	if answer.get("accepted", false):
		_proof = answer.proof.duplicate(true)
		_view = {"landing": _proof.landing, "attack_position": _proof.attack_position}


func _on_mechanism_phase(current: Dictionary) -> void:
	# A newly published active phase is checked before shared contact callbacks.
	if _active and current.status == "running" and current.phase in ["lock", "active", "recovery"]:
		_guard_current()


func _guard_current() -> void:
	last_view_error = String(shared_shell.call("camera_framing_error", camera_framing_points()))
	if not last_view_error.is_empty():
		mechanism.cancel("resonance_actual_view_unreadable")


func _camera_framing_points() -> Array:
	if not _active:
		return []
	var error: String = runtime_error()
	if not error.is_empty():
		last_camera_framing_error = error
		return []
	var points: Array = _static_bounds.duplicate()
	var native_player: Array = shared_shell.call("player_camera_framing_points")
	if native_player.is_empty():
		last_camera_framing_error = "Actual shared player render/capsule bounds required"
		return []
	for key: String in ["landing", "attack_position"]:
		if _view.has(key):
			for point: Vector3 in native_player:
				points.append(point + (_view[key] as Vector3) - hero.global_position)
	var cue: CinderThreatCue = mechanism.get_cue()
	for label: String in ["RequiredSourceMarker", "RequiredFootprintOutline", "RequiredFootprintFill"]:
		var part: MeshInstance3D = cue.get_node_or_null(label) as MeshInstance3D
		if part != null and part.is_visible_in_tree() and part.mesh != null:
			points.append_array(_mesh_corners(part.mesh, part.global_transform))
	return points # Shell appends the complete ACTUAL Hero bounds itself.


func _mesh_corners(mesh: Mesh, transform: Transform3D) -> Array:
	var box: AABB = mesh.get_aabb()
	var points: Array = []
	for index: int in range(8):
		points.append(transform * box.get_endpoint(index))
	return points


func runtime_error() -> String:
	if not is_instance_valid(scenery) or not is_instance_valid(mechanism) or not is_instance_valid(threat_scheduler) or not is_instance_valid(hero) or not is_instance_valid(shared_shell):
		return "Actual shared world/source/hero/camera bindings required"
	var error: String = String(scenery.call("runtime_error"))
	if not error.is_empty():
		return error
	if mechanism.get_script() != MechanismScript or threat_scheduler.get_script() != SchedulerScript or mechanism.get_parent() != self or threat_scheduler.get_parent() != self or mechanism.global_transform != Transform3D.IDENTITY or not mechanism.is_visible_in_tree() or mechanism.get_cue() == null:
		return "Fixed native pulse source/cue must remain present at its floor origin"
	if not is_instance_valid(_source_view) or _source_view.get_parent() != mechanism or not _source_view.is_visible_in_tree() or _source_view.transform != Transform3D(Basis.IDENTITY, Vector3(0, 0.06, 0)) or _source_view.mesh != _source_mesh or _source_view.material_override != _source_material or _source_mesh.size != Vector3(0.22, 0.12, 0.22):
		return "Quiet native source mineral must retain its complete fixed mesh"
	if _source_material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or _source_material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or _source_material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or _source_material.no_depth_test or _source_material.albedo_color != Color("787184"):
		return "Quiet source material must retain its opaque depth-tested native value"
	return ""


func _capture_local_state() -> Dictionary:
	var bindings: Dictionary = scheduler_bindings()
	var scheduler: Dictionary = threat_scheduler.snapshot_state(bindings)
	var child: Dictionary = mechanism.snapshot_state(bindings)
	return {"api_revision": LOCAL_API, "schema_version": 1, "scheduler": scheduler, "mechanism": child, "view": _encoded_view()} if not scheduler.is_empty() and not child.is_empty() else {}


func _local_snapshot_error(data: Dictionary) -> String:
	return _paired_error(data, hero.snapshot_state())


func _local_snapshot_error_with_player(data: Dictionary, player: Dictionary) -> String:
	return _paired_error(data, player)


func _paired_error(data: Dictionary, player: Dictionary) -> String:
	var error: String = runtime_error()
	if not error.is_empty():
		return error
	if not Value.keys_error(data, ["api_revision", "schema_version", "scheduler", "mechanism", "view"]).is_empty() or data.get("api_revision") != LOCAL_API or not data.get("schema_version") is int or data.schema_version != 1 or not data.get("scheduler") is Dictionary or not data.get("mechanism") is Dictionary or not data.get("view") is Dictionary:
		return "Closed resonance unit schema1 required"
	if data.scheduler.get("encounter_id") != ENCOUNTER_ID or not data.scheduler.get("world_revision") is int or data.scheduler.world_revision != 1:
		return "Saved pulse must retain its actual authored encounter and world revision"
	if not player.get("motion") is Dictionary or not Value.is_vector3(player.motion.get("position")) or not player.get("world_actions") is Dictionary or not player.world_actions.get("clock_s") is float or not data.scheduler.get("clock_s") is float or player.world_actions.clock_s != data.scheduler.clock_s:
		return "Independently validated saved Hero must share the exact Scheduler tick"
	var bindings: Dictionary = scheduler_bindings()
	bindings["hero_positions"] = {"hero": Value.read_vector3(player.motion.position)}
	error = threat_scheduler.snapshot_error(data.scheduler, bindings)
	if error.is_empty():
		error = mechanism.snapshot_error(data.mechanism, bindings, data.scheduler)
	if not error.is_empty():
		return error
	if not data.mechanism.cycle is int or data.mechanism.cycle not in [0, 1]:
		return "One admitted finite pulse only"
	if data.mechanism.cycle == 0:
		return "" if data.view.is_empty() else "Unadmitted snapshots cannot retain selected response history"
	if not Value.keys_error(data.view, ["landing", "attack_position"]).is_empty():
		return "Both historical view-only response points required"
	for key: String in ["landing", "attack_position"]:
		if not Value.is_vector3(data.view[key]):
			return "View points require finite native vector transport"
		var point: Vector3 = Value.read_vector3(data.view[key])
		if not FLOOR_RECT.grow(-0.33).has_point(Vector2(point.x, point.z)) or absf(point.y) > 0.02:
			return "Historical response bounds must remain on the firm shore"
	return ""


func _snapshot_envelope_error(snapshot: Dictionary) -> String:
	var error: String = super._snapshot_envelope_error(snapshot)
	if not error.is_empty():
		return error
	var empty_progress: Dictionary = {"completed": false, "completion_id": "", "contact_exit_id": "", "checkpoint_id": "", "checkpoint_kind": "", "checkpoint_ids": {}}
	return "" if Exact.stringify(snapshot.progress) == Exact.stringify(empty_progress) else "A resonance prototype grants no campaign progression"


func _encoded_view() -> Dictionary:
	# Pre-admission forecast is not committed history and is omitted at cycle0.
	if int(mechanism.state().cycle) == 0:
		return {}
	return {"landing": Value.vector3(_view.landing), "attack_position": Value.vector3(_view.attack_position)}


func restore_state(snapshot: Dictionary) -> bool:
	_restore_error = ""
	var accepted: bool = super.restore_state(snapshot)
	if accepted and not _restore_error.is_empty():
		last_snapshot_error = _restore_error
		return false # Caller disposes the failed candidate; no partial rollback.
	return accepted


func _restore_local_state(data: Dictionary) -> void:
	var bindings: Dictionary = scheduler_bindings()
	if not threat_scheduler.restore_state(data.scheduler, bindings) or not mechanism.restore_state(data.mechanism, bindings):
		_restore_error = threat_scheduler.last_snapshot_error + "; " + mechanism.last_snapshot_error
		return
	_view.clear()
	for key: String in data.view:
		_view[key] = Value.read_vector3(data.view[key])
	_proof.clear() # Diagnostic witness is not restore authority or reconstructed.
	scenery.call("follow_landmarks", hero.global_position)
	_update_guidance()


func _update_guidance() -> void:
	var current: Dictionary = mechanism.state()
	if not last_configuration_error.is_empty():
		objective_text = "RESONANCE: " + last_configuration_error
	elif current.status == "complete":
		objective_text = "PULSE ENDED / SEPARATE RULE ROOM"
	elif current.phase == "recovery":
		objective_text = "RETURN TO FIRM FLOOR / NO ATTACKABLE SOURCE"
	else:
		objective_text = "BOUNDED DISK / DASH OUT AFTER WARNING"
