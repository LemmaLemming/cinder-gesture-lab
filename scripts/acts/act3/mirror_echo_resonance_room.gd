extends CinderLevel
## Mechanical composition only: pulse1 -> one own Echo -> pulse2.
## Published finite actors share one continuously running Scheduler. No saves.

const Shore = preload("res://scripts/acts/act3/mirror_sea_scenery.gd")
const EchoSource = preload("res://scripts/acts/act3/mirror_echo.gd")
const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const MechanismScript = preload("res://scripts/combat/lane_mechanism.gd")
const Shape = preload("res://scripts/combat/threat_geometry.gd")
const CueMeshes = preload("res://scripts/cues/cue_mesh.gd")
const ReplayFloor = preload("res://scripts/combat/replay_footprint.gd")
const Witness = preload("res://scripts/combat/replay_witness.gd")
const API: String = "act3-echo-resonance-room-1"
const ENCOUNTER_ID: String = "A3-L3/echo-resonance-room"
const ECHO_ID: String = "mirror-mixed/real-knot"
const ECHO_EPOCH: String = "A3-L3/resonance-mixed-echo"
const PULSE_ID: String = "mirror-mixed/pulse"
const PULSE_ORIGIN: Vector3 = Vector3(2.6, 0, 0)
const PULSE_RADIUS: float = 1.15
const FIRST_OPENING: Vector3 = Vector3(1.9, 0, 0.65)
const FLOOR_RECT: Rect2 = Rect2(-7, -11, 14, 22)
const SAVE_LIMIT: String = "Mixed finite room whole-unit persistence is unsupported: idle Echo and later cancelled/dead custody require published lifecycle support"

var scenery: Node3D
var echo: Node3D
var mechanism: CinderLaneMechanism
var threat_scheduler: CinderThreatScheduler
var last_configuration_error: String = ""
var last_admission_reason: String = ""
var last_camera_error: String = ""
var _floor: Dictionary = {}
var _context: Dictionary = {}
var _projection: Dictionary = {}
var _pulse_bounds: Array = []
var _echo_footprint_bounds: Array = []
var _pulse_view: Array[Vector3] = []
var _echo_view: Array[Vector3] = []
var _pulse_proofs: Dictionary = {}
var _pulse_exchanges: Dictionary = {}
var _echo_proof: Dictionary = {}
var _echo_lease: Dictionary = {}
var _echo_locked: bool = false
var _stage: String = "unentered"
var _stage_history: Array[Dictionary] = []
var _active: bool = false
var _mineral: MeshInstance3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 90 # Before actual mechanism100 and Playback110.
	scenery = Shore.new()
	scenery.name = "MirrorSeaScenery"
	add_child(scenery)
	scenery.call("build", true)
	var body: StaticBody3D = scenery.get("floor_body") as StaticBody3D
	var solid: CollisionShape3D = body.get_node_or_null("Solid") as CollisionShape3D if body != null else null
	if solid == null:
		last_configuration_error = "Mixed room requires the actual continuous shore floor"
		return
	_floor = {"collision": solid, "safe_rect": FLOOR_RECT}
	threat_scheduler = SchedulerScript.new()
	threat_scheduler.name = "ContinuousMixedScheduler"
	add_child(threat_scheduler)
	mechanism = MechanismScript.new()
	mechanism.name = "SameBoundedPulseSource"
	mechanism.position = PULSE_ORIGIN
	add_child(mechanism)
	_mineral = MeshInstance3D.new()
	_mineral.name = "QuietMineralPulseSource"
	var box := BoxMesh.new()
	box.size = Vector3(0.22, 0.12, 0.22)
	_mineral.mesh = box
	_mineral.position.y = 0.06
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.albedo_color = Color("787184")
	_mineral.material_override = material
	mechanism.add_child(_mineral)
	echo = EchoSource.new()
	echo.name = "SameActualMirrorKnot"
	add_child(echo)
	_build_reflection()
	var disk: Dictionary = Shape.circle(PULSE_ORIGIN, PULSE_RADIUS)
	for filled: bool in [false, true]:
		_append_mesh(_pulse_bounds, CueMeshes.geometry_mesh(disk, filled), Transform3D(Basis.IDENTITY, PULSE_ORIGIN + Vector3.UP * (CinderThreatCue.FLOOR_OFFSET if not filled else CinderThreatCue.FLOOR_OFFSET - 0.004)))
	for phase: String in ["warning", "lock", "active", "recovery"]:
		_append_mesh(_pulse_bounds, CueMeshes.source_mesh(phase), Transform3D(Basis.IDENTITY, PULSE_ORIGIN + Vector3.UP * (CinderThreatCue.FLOOR_OFFSET + 0.004)))
	var slash: Dictionary = native_definition().slash
	var geometry: Dictionary = Shape.cone(slash.world_origin, slash.direction, slash.reach, slash.cone_min_dot, slash.origin_disk_radius)
	for filled: bool in [false, true]:
		_append_mesh(_echo_footprint_bounds, CueMeshes.geometry_mesh(geometry, filled), Transform3D(Basis.IDENTITY, slash.world_origin + Vector3.UP * (CinderThreatCue.FLOOR_OFFSET if not filled else CinderThreatCue.FLOOR_OFFSET - 0.004)))
	for phase: String in ["warning", "lock", "active", "recovery"]:
		_append_mesh(_echo_footprint_bounds, CueMeshes.source_mesh(phase), Transform3D(Basis.IDENTITY, slash.world_origin + Vector3.UP * (CinderThreatCue.FLOOR_OFFSET + 0.004)))


func _build_reflection() -> void:
	var reflection := Node3D.new()
	reflection.name = "HarmlessOutlinedReflection"
	reflection.position = Vector3(-1.4, 0.02, -2.1)
	var parts: Array = [[Vector3(0.055, 0.90, 0.06), Vector3(-0.23, 0.56, 0)], [Vector3(0.055, 0.90, 0.06), Vector3(0.23, 0.56, 0)], [Vector3(0.51, 0.055, 0.06), Vector3(0, 1.04, 0)], [Vector3(0.51, 0.055, 0.06), Vector3(0, 0.26, 0)], [Vector3(0.055, 0.23, 0.06), Vector3(-0.17, 1.25, 0)], [Vector3(0.055, 0.23, 0.06), Vector3(0.17, 1.25, 0)], [Vector3(0.39, 0.05, 0.06), Vector3(0, 1.39, 0)], [Vector3(0.39, 0.05, 0.06), Vector3(0, 1.12, 0)]]
	for part: Array in parts:
		var visual := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = part[0]
		visual.mesh = mesh
		visual.position = part[1]
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.albedo_color = Color(0.48, 0.47, 0.56)
		visual.material_override = material
		reflection.add_child(visual)
	add_child(reflection) # No HP/collider/group/cue; open interior is decorative.


func _on_enter_level() -> void:
	if not last_configuration_error.is_empty():
		return
	var profile: String = shared_shell.call("get_difficulty_preference")
	if not threat_scheduler.begin_encounter(profile, ENCOUNTER_ID, 1) or not mechanism.configure(PULSE_ID, Shape.circle(PULSE_ORIGIN, PULSE_RADIUS), FIRST_OPENING) or not mechanism.bind(threat_scheduler, {"hero": hero}):
		last_configuration_error = threat_scheduler.last_error + "; " + mechanism.last_error
		return
	var floors: Dictionary = ReplayFloor.floor_signature(get_parent() as Node3D, [_floor])
	if not floors.get("accepted", false):
		last_configuration_error = String(floors.get("reason", "Actual floor signature unavailable"))
		return
	_context = {"world_root": get_parent() as Node3D, "source_id": ECHO_ID, "source_epoch": ECHO_EPOCH, "generation": 1, "world_collision_fingerprint": threat_scheduler.pure_collision_fingerprint(get_parent() as Node3D), "world_floor_signature": floors.signature}
	var prepared: Dictionary = {"world_revision": 1, "collision_fingerprint": _context.world_collision_fingerprint, "floor_signature": _context.world_floor_signature}
	if not echo.call("configure_source", ECHO_ID, ECHO_EPOCH, 1, native_definition(), profile, prepared, threat_scheduler):
		last_configuration_error = String(echo.get("source_snapshot_error"))
		return
	mechanism.state_changed.connect(_on_pulse_phase)
	_active = true
	_set_stage("pulse1_wait")
	_follow_scenery()
	_update_guidance()


func native_definition() -> Dictionary:
	var travel_s: float = 0.30
	var slash_s: float = 0.18
	return {"definition_id": "act3/mirror-mixed/straight-return", "definition_revision": 1, "role_id": "C52", "raw_role": {"raw_damage": 18.0, "windup_s": 2.2, "lock_s": 1.1, "active_s": travel_s + slash_s, "recovery_s": 2.2, "attack_interval_s": 4.2, "max_hp": 36.0, "move_speed": 0.0}, "timing_floors": {"windup_s": 2.2, "lock_s": 1.1, "recovery_s": 1.8}, "recognition_s": 0.25, "route": [{"position": Vector3(0, 0, -2.5), "at_s": 0.0}, {"position": Vector3(0, 0, -0.5), "at_s": travel_s}], "travel_clearance": {"radius_m": 0.65, "height_m": 1.45}, "slash": {"world_origin": Vector3(0, 0, -0.5), "direction": Vector3.BACK, "reach": 2.2, "cone_min_dot": 0.2, "origin_disk_radius": 0.25, "max_vertical_distance": 0.75, "los_height": 0.5, "commitment_duration_s": slash_s, "visual_duration_s": 0.28}, "presentation": {"presentation_id": "act3/porcelain-mirror-echo", "presentation_revision": 1}}


func pulse_response(cycle: int) -> Dictionary:
	var escaping: Array[Vector3] = [Vector3.LEFT]
	var returning: Array[Vector3] = [Vector3.RIGHT]
	if cycle == 2:
		# Same controls. A finite rear pocket avoids spreading the required
		# native source/landing envelope across both portrait edges.
		escaping = [Vector3(1, 0, 1).normalized(), Vector3.BACK, Vector3.RIGHT, Vector3.LEFT]
		returning = [Vector3(-1, 0, -1).normalized(), Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT]
	return {"encounter_id": ENCOUNTER_ID, "world_revision": 1, "recognition_s": 0.25, "attack_input_margin_s": 0.06, "escape_directions": escaping, "return_directions": returning, "floor_regions": [_floor]}


func echo_response() -> Dictionary:
	var response: Dictionary = hero.get_threat_response_state()
	var directions: Array[Vector3] = [Vector3.BACK, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD]
	if hero.global_position.x < 0.0:
		directions[1] = Vector3.RIGHT
		directions[2] = Vector3.LEFT
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			directions.append(Vector3(x, 0, z).normalized())
	response.merge({"world_revision": 1, "recognition_s": 0.25, "attack_input_margin_s": 0.06, "escape_directions": directions, "return_directions": directions.duplicate(), "floor_regions": [_floor]})
	return response


func _physics_process(_delta: float) -> void:
	if not _active or _stage == "failed":
		return
	var error: String = runtime_error()
	if not error.is_empty():
		_fail(error)
		return
	_follow_scenery()
	var pulse: Dictionary = mechanism.state()
	var phase: String = echo.call("source_phase")
	if pulse.status == "cancelled" or phase == "cancelled":
		_fail("A required finite source cancelled; reset this unsupported-save prototype")
		return
	match _stage:
		"pulse1_wait":
			_try_pulse(1)
		"pulse1":
			if pulse.status == "complete" and threat_scheduler.reservations().is_empty():
				_pulse_view.clear()
				_set_stage("echo_wait")
		"echo_wait":
			_try_echo()
		"echo":
			if phase == "defeated":
				_fail("Early Echo defeat retires the finite exchange; no replacement cycle is manufactured")
				return
			if not _echo_locked and threat_scheduler.get_clock() >= float(_echo_lease.lock_from_s):
				if not _view_ok(true):
					_fail("Actual Echo lock view: " + last_camera_error)
					return
				var answer: Dictionary = threat_scheduler.commit_authored_replay(String(_echo_lease.id), echo_response())
				_echo_locked = true
				if not answer.get("accepted", false):
					_fail(String(answer.get("reason", "Actual Echo lock rejected")))
					return
				_echo_lease = answer.reservation.duplicate(true)
				_echo_proof = answer.proof.duplicate(true)
				_echo_view = _proof_positions(_echo_proof)
			if phase == "complete" and threat_scheduler.reservations().is_empty():
				_echo_view.clear()
				_set_stage("pulse2_wait")
		"pulse2_wait":
			_try_pulse(2)
		"pulse2":
			if pulse.status == "complete" and threat_scheduler.reservations().is_empty():
				_pulse_view.clear()
				_set_stage("complete")
	if _stage in ["pulse1", "echo", "pulse2"] and not _view_ok(true):
		_fail("Actual required exchange view: " + last_camera_error)
	_update_guidance()


func _try_pulse(cycle: int) -> void:
	if not hero.is_on_floor() or not hero.get_threat_response_state().stable or not threat_scheduler.reservations().is_empty():
		return
	if cycle == 2 and (echo.call("source_phase") != "complete" or bool(echo.get("dead"))):
		_fail("Second pulse requires the same genuinely completed living Echo knot")
		return
	var opening: Vector3 = FIRST_OPENING if cycle == 1 else echo.global_position
	var preview: Dictionary = mechanism.preview_start("hero", pulse_response(cycle), opening)
	if not preview.get("accepted", false):
		last_admission_reason = String(preview.get("reason", "Actual pulse preview rejected"))
		return
	_pulse_view = _proof_positions(preview.proof)
	if not _view_ok(false) or not _view_ok(true):
		return # Normal shared camera settles this complete forecast before lease.
	var answer: Dictionary = mechanism.start("hero", pulse_response(cycle), opening, null, preview)
	if not answer.get("accepted", false):
		last_admission_reason = String(answer.get("reason", "Actual pulse admission rejected"))
		return
	_pulse_proofs[str(cycle)] = answer.proof.duplicate(true)
	_pulse_exchanges[str(cycle)] = answer.reservation.duplicate(true)
	_pulse_view = _proof_positions(answer.proof)
	last_admission_reason = ""
	_set_stage("pulse%d" % cycle)


func _try_echo() -> void:
	if not hero.is_on_floor() or not hero.get_threat_response_state().stable or not threat_scheduler.reservations().is_empty():
		return
	var candidate: Dictionary = Witness.new().prove_authored(threat_scheduler, echo, echo.call("source_program"), echo_response(), _context)
	if not candidate.get("accepted", false):
		last_admission_reason = String(candidate.get("reason", "Actual Echo response rejected"))
		return
	_echo_view = _proof_positions(candidate)
	if _projection.is_empty():
		_projection = ReplayFloor.plan_authored(threat_scheduler, echo.call("source_program"), get_parent() as Node3D, [_floor], _context)
		if not _projection.get("accepted", false):
			_fail(String(_projection.get("reason", "Complete required projection rejected")))
			return
	if not _view_ok(false) or not _view_ok(true):
		return
	var answer: Dictionary = threat_scheduler.request_authored_replay(echo, echo.call("source_program"), echo_response(), _context)
	if not answer.get("accepted", false):
		last_admission_reason = String(answer.get("reason", "Actual authored admission rejected"))
		return
	_echo_lease = answer.reservation.duplicate(true)
	_echo_proof = answer.proof.duplicate(true)
	_echo_view = _proof_positions(answer.proof)
	if not echo.call("bind_projected", threat_scheduler, String(answer.reservation_id), {"hero": hero}, [_floor], _projection, _context):
		threat_scheduler.cancel(String(answer.reservation_id), "mixed_required_projection_binding_failed")
		_fail(String(echo.get("last_error")))
		return
	last_admission_reason = ""
	_set_stage("echo")


func _on_pulse_phase(current: Dictionary) -> void:
	if _active and current.status == "running" and current.phase in ["lock", "active", "recovery"] and not _view_ok(true):
		mechanism.cancel("mixed_actual_pulse_view_unreadable")


func _view_ok(current: bool) -> bool:
	var points: Array = camera_framing_points()
	if points.is_empty():
		last_camera_error = last_camera_framing_error if not last_camera_framing_error.is_empty() else "Complete mixed framing unavailable"
		return false
	if current:
		last_camera_error = String(shared_shell.call("camera_framing_error", points))
	else:
		var plan: Dictionary = shared_shell.call("camera_framing_plan", points, hero.global_position + Vector3.UP * 0.75)
		last_camera_error = "" if plan.get("accepted", false) else String(plan.get("reason", "Complete mixed forecast cannot fit"))
	return last_camera_error.is_empty()


func _camera_framing_points() -> Array:
	if not _active:
		return []
	var error: String = runtime_error()
	if not error.is_empty():
		last_camera_framing_error = error
		return []
	var points: Array = []
	var art: Dictionary = echo.call("framing_points")
	if not String(art.get("error", "Missing native Echo art bounds")).is_empty() or art.get("points", []).is_empty():
		last_camera_framing_error = String(art.get("error", "Missing native Echo art bounds"))
		return []
	_append_enclosure(points, art.points)
	var pulse: Array = []
	_append_mesh(pulse, _mineral.mesh, _mineral.global_transform)
	if _stage in ["pulse1_wait", "pulse1", "pulse2_wait", "pulse2"]:
		pulse.append_array(_pulse_bounds)
	_append_cue_meshes(pulse, mechanism.get_cue())
	_append_enclosure(points, pulse)
	var required_echo: Array = []
	if _stage in ["echo_wait", "echo"]:
		required_echo.append_array(_echo_footprint_bounds)
	for cue: Node3D in echo.call("get_cues"):
		_append_cue_meshes(required_echo, cue)
	var route: MeshInstance3D = echo.get_node_or_null("ExactHarmlessRoutes") as MeshInstance3D
	if route != null and route.is_visible_in_tree() and route.mesh != null:
		_append_mesh(required_echo, route.mesh, route.global_transform)
	_append_enclosure(points, required_echo)
	var native_hero: Array = shared_shell.call("player_camera_framing_points")
	if native_hero.is_empty():
		last_camera_framing_error = "Complete actual Hero presentation/capsule bounds required"
		return []
	var views: Array[Vector3] = _pulse_view if _stage.begins_with("pulse") else _echo_view
	for pivot: Vector3 in views:
		var landing: Array = []
		for corner: Vector3 in native_hero:
			landing.append(corner + pivot - hero.global_position)
		_append_enclosure(points, landing)
	return points # Shell adds complete actual Hero; no mechanical proof is replaced.


func _append_cue_meshes(points: Array, cue: Node3D) -> void:
	if not is_instance_valid(cue):
		return
	for name: String in ["RequiredSourceMarker", "RequiredFootprintOutline", "RequiredFootprintFill"]:
		var visual: MeshInstance3D = cue.get_node_or_null(name) as MeshInstance3D
		if visual != null and visual.is_visible_in_tree() and visual.mesh != null:
			_append_mesh(points, visual.mesh, visual.global_transform)


func _append_mesh(points: Array, mesh: Mesh, transform: Transform3D) -> void:
	var box: AABB = mesh.get_aabb()
	for i: int in range(8):
		points.append(transform * box.get_endpoint(i))


func _append_enclosure(points: Array, complete: Array) -> void:
	if complete.is_empty():
		return
	var low: Vector3 = complete[0]
	var high: Vector3 = complete[0]
	for point: Vector3 in complete:
		low = low.min(point)
		high = high.max(point)
	var box := AABB(low, high - low)
	for i: int in range(8):
		points.append(box.get_endpoint(i))


func _proof_positions(proof: Dictionary) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for segment: Dictionary in proof.get("path", []):
		for key: String in ["from", "to"]:
			var point: Variant = segment.get(key)
			if point is Vector3 and not result.has(point):
				result.append(point)
	return result


func runtime_error() -> String:
	if not is_instance_valid(hero) or not is_instance_valid(shared_shell) or not is_instance_valid(scenery) or not is_instance_valid(echo) or not is_instance_valid(mechanism) or not is_instance_valid(threat_scheduler):
		return "Actual shared World/Hero/source/camera bindings required"
	var error: String = scenery.call("runtime_error")
	if not error.is_empty():
		return error
	if echo.get_script() != EchoSource or mechanism.get_script() != MechanismScript or threat_scheduler.get_script() != SchedulerScript or echo.get_parent() != self or mechanism.get_parent() != self or threat_scheduler.get_parent() != self or not echo.is_visible_in_tree() or not mechanism.is_visible_in_tree() or mechanism.global_transform != Transform3D(Basis.IDENTITY, PULSE_ORIGIN):
		return "Retained actual native owners/scripts/fixed pulse origin required"
	if not is_instance_valid(_mineral) or _mineral.get_parent() != mechanism or not _mineral.is_visible_in_tree() or not _mineral.mesh is BoxMesh:
		return "Actual visible fixed mineral pulse source required"
	return ""


func _set_stage(stage: String) -> void:
	_stage = stage
	_stage_history.append({"id": stage, "clock_s": threat_scheduler.get_clock()})


func _fail(reason: String) -> void:
	last_configuration_error = reason
	_stage = "failed"
	if is_instance_valid(mechanism):
		mechanism.cancel("mixed_parent_failed")
	if is_instance_valid(echo) and echo.call("source_phase") not in ["idle", "complete", "cancelled", "defeated"]:
		echo.call("cancel", "mixed_parent_failed")
	_update_guidance()


func _follow_scenery() -> void:
	scenery.call("follow_landmarks", Vector3(hero.global_position.x, 0, 0.4))


func _update_guidance() -> void:
	if _stage == "failed":
		objective_text = "MIXED ROOM STOPPED / RESET TO TRY AGAIN"
	elif _stage.begins_with("pulse1"):
		objective_text = "ONE BOUNDED DISK / ESCAPE THEN RETURN"
	elif _stage.begins_with("echo"):
		objective_text = "ONE REAL ECHO / RETURN TO ITS LOW KNOT"
	elif _stage.begins_with("pulse2"):
		objective_text = "SECOND BOUNDED DISK / THE SAME KNOT REMAINS"
	else:
		objective_text = "PULSES ENDED / ORDINARY ATTACKS QUIET THE KNOT"


func state() -> Dictionary:
	return {"api_revision": API, "stage": _stage, "stage_history": _stage_history.duplicate(true), "configuration_error": last_configuration_error, "admission_reason": last_admission_reason, "camera_error": last_camera_error, "clock_s": threat_scheduler.get_clock() if is_instance_valid(threat_scheduler) else -1.0, "pulse": mechanism.state() if is_instance_valid(mechanism) else {}, "pulse_proofs": _pulse_proofs.duplicate(true), "pulse_exchanges": _pulse_exchanges.duplicate(true), "echo": echo.call("get_source_state") if is_instance_valid(echo) else {}, "playback": echo.call("state") if is_instance_valid(echo) else {}, "echo_lease": _echo_lease.duplicate(true), "echo_proof": _echo_proof.duplicate(true), "echo_locked": _echo_locked, "persistence_supported": false}


func scheduler_bindings() -> Dictionary:
	return {"world_root": get_parent() as Node3D, "owners": {PULSE_ID: mechanism, ECHO_ID: echo}, "actors": {"hero": hero}, "floors": {"firm-shore": _floor}}


func snapshot_state() -> Dictionary:
	last_snapshot_error = SAVE_LIMIT
	return {} # Never publish a partial Scheduler/source pair omitting mechanism.


func snapshot_error(_snapshot: Dictionary) -> String:
	return SAVE_LIMIT


func snapshot_error_with_player(_snapshot: Dictionary, _saved_player: Dictionary) -> String:
	return SAVE_LIMIT


func restore_state(_snapshot: Dictionary) -> bool:
	last_snapshot_error = SAVE_LIMIT
	return false


func _on_exit_level() -> void:
	_active = false
	if is_instance_valid(threat_scheduler):
		threat_scheduler.end_encounter("mixed_room_exit")
