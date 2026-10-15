extends CinderLevel
## O3 first-court prototype: actual managed own-route Echo and independently
## previewed native scenic pulse. No campaign clear/checkpoint/reward/exit yet.
const Shore = preload("res://scripts/acts/act3/mirror_sea_scenery.gd")
const EchoSource = preload("res://scripts/acts/act3/mirror_echo.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Mechanism = preload("res://scripts/combat/lane_mechanism.gd")
const Shape = preload("res://scripts/combat/threat_geometry.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Witness = preload("res://scripts/combat/replay_witness.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/combat/authored_enemy_sequence.gd")
const UnitCodec = preload("res://scripts/acts/act3/irontick_reflection_codec.gd")
const API: String = "act3-irontick-reflection-1"
const ENCOUNTER_ID: String = "A3-O3/irontick-reflection"
const ECHO_ID: String = "o3-first-echo"
const ECHO_EPOCH: String = "A3-O3/o3-first-echo/own-sequence"
const PULSE_ID: String = "o3-first-pulse"
const DATA_PATH: String = "res://data/campaign/act3/a3_o3_encounters.json"
const LOCAL_VERSION: int = 1
const WORLD_REVISION: int = 1
const FLOOR_RECT: Rect2 = Rect2(-7,-11,14,22)
const ECHO_KNOT: Vector3 = Vector3(0,0,6)
const PULSE_ORIGIN: Vector3 = Vector3(0.7,0,6.65)
const PULSE_RADIUS: float = 1.15
const PULSE_DUE_S: float = 0.65
const RETRY_S: float = 0.25

class ViewObserver extends Node:
	var observe: Callable
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 90
	func _physics_process(_delta: float) -> void:
		if observe.is_valid(): observe.call()

var scenery: Node3D
var echo: Node3D
var mechanism: CinderLaneMechanism
var threat_scheduler: CinderThreatScheduler
var last_configuration_error: String = ""
var last_admission_reason: String = ""
var last_camera_error: String = ""
var _floor: Dictionary = {}
var _context: Dictionary = {}
var _world: Dictionary = {}
var _profile: String = "standard"
var _active: bool = false
var _guard_busy: bool = false
var _capture_busy: bool = false
var _capture_camera: Camera3D
var _capture_hud: GameHUD
var _capture_error: String = ""
var _restore_error: String = ""
var _observer: ViewObserver
var _pulse_marker: MeshInstance3D
var _reflection: Node3D
var _echo_retry_at_s: float = 0.0
var _pulse_retry_at_s: float = 0.0
var _echo_record: Dictionary = {"projection":{},"lease":{},"proof":{},"positions":[],"locked":false}
var _pulse_record: Dictionary = {"proof":{},"positions":[]}
var _pending_view: Dictionary = {}
var _codec = UnitCodec.new()

func _ready() -> void:
	local_snapshot_version = LOCAL_VERSION
	process_physics_priority = 130
	scenery = Shore.new()
	scenery.name = "IrontickFirmShore"
	add_child(scenery)
	scenery.call("build",true)
	var floor_body: StaticBody3D = scenery.get("floor_body") as StaticBody3D
	var solid: CollisionShape3D = floor_body.get_node_or_null("Solid") as CollisionShape3D if is_instance_valid(floor_body) else null
	if not is_instance_valid(solid) or not solid.shape is BoxShape3D or (solid.shape as BoxShape3D).size != Vector3(14,1,22):
		last_configuration_error = "Actual unchanged permanent 14x22 firm shore required"
		return
	_floor = {"collision":solid,"safe_rect":FLOOR_RECT}
	threat_scheduler = Scheduler.new()
	threat_scheduler.name = "IrontickThreatScheduler"
	add_child(threat_scheduler)
	echo = EchoSource.new()
	echo.name = "IrontickRealEndpoint"
	add_child(echo)
	mechanism = Mechanism.new()
	mechanism.name = "IndependentScenicPulse"
	mechanism.position = PULSE_ORIGIN
	add_child(mechanism)
	_pulse_marker = MeshInstance3D.new()
	_pulse_marker.name = "QuietMineralPulseSource"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.22,0.12,0.22)
	_pulse_marker.mesh = mesh
	_pulse_marker.position.y = 0.06
	_pulse_marker.material_override = _material(Color("787184"))
	mechanism.add_child(_pulse_marker)
	_build_reflection()
	_observer = ViewObserver.new()
	_observer.name = "IrontickBeforeConsumers"
	_observer.observe = _guard_before_consumers
	add_child(_observer)
	last_configuration_error = _authoring_error()

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.albedo_color = color
	return material

func _build_reflection() -> void:
	_reflection = Node3D.new()
	_reflection.name = "HarmlessOutlinedReflection"
	_reflection.position = Vector3(-1.4,0.02,4.4)
	add_child(_reflection)
	# Parent-family open porcelain silhouette: no CollisionObject, HP, group,
	# damage callback or required action cue. The filled endpoint stays real.
	var pieces: Array = [[Vector3(0.055,0.9,0.06),Vector3(-0.23,0.56,0)],[Vector3(0.055,0.9,0.06),Vector3(0.23,0.56,0)],[Vector3(0.51,0.055,0.06),Vector3(0,1.04,0)],[Vector3(0.51,0.055,0.06),Vector3(0,0.26,0)],[Vector3(0.055,0.23,0.06),Vector3(-0.17,1.25,0)],[Vector3(0.055,0.23,0.06),Vector3(0.17,1.25,0)],[Vector3(0.39,0.05,0.06),Vector3(0,1.39,0)],[Vector3(0.39,0.05,0.06),Vector3(0,1.12,0)]]
	for index: int in range(pieces.size()):
		var visual := MeshInstance3D.new()
		visual.name = "QuietOutlinePart%d" % index
		var box := BoxMesh.new()
		box.size = pieces[index][0]
		visual.mesh = box
		visual.position = pieces[index][1]
		visual.material_override = _material(Color(0.48,0.47,0.56))
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_reflection.add_child(visual)

func native_definition() -> Dictionary:
	return {"definition_id":"act3/irontick/first-straight-return","definition_revision":1,"role_id":"C52","raw_role":{"raw_damage":18.0,"windup_s":2.2,"lock_s":1.1,"active_s":0.48,"recovery_s":2.2,"attack_interval_s":4.2,"max_hp":36.0,"move_speed":0.0},"timing_floors":{"windup_s":2.2,"lock_s":1.1,"recovery_s":1.8},"recognition_s":0.25,"route":[{"position":Vector3(0,0,4),"at_s":0.0},{"position":ECHO_KNOT,"at_s":0.30}],"travel_clearance":{"radius_m":0.65,"height_m":1.45},"slash":{"world_origin":ECHO_KNOT,"direction":Vector3.BACK,"reach":2.2,"cone_min_dot":0.2,"origin_disk_radius":0.25,"max_vertical_distance":0.75,"los_height":0.5,"commitment_duration_s":0.18,"visual_duration_s":0.28},"presentation":{"presentation_id":"act3/porcelain-mirror-echo","presentation_revision":1}}

func _authoring_error() -> String:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not raw is Dictionary or raw.get("level_id") != "A3-O3" or raw.get("prototype") != true or raw.get("encounter_id") != ENCOUNTER_ID or raw.get("echo_id") != ECHO_ID or raw.get("pulse_id") != PULSE_ID or not Value.is_vector3(raw.get("spawn")) or Value.read_vector3(raw.spawn) != Vector3(0,0.1,8) or not Value.is_vector3(raw.get("pulse_origin")) or Value.read_vector3(raw.pulse_origin) != PULSE_ORIGIN or raw.get("pulse_radius") != PULSE_RADIUS or raw.get("pulse_eligible_at_s") != PULSE_DUE_S:
		return "Exact first-court O3 authoring/independent pulse schedule required"
	for key: String in ["floor_size","fixed_endpoint","pulse_opening"]:
		if not Value.is_vector3(raw.get(key)): return "Finite authored first-court vector required: "+key
	if Value.read_vector3(raw.floor_size)!=Vector3(14,1,22) or Value.read_vector3(raw.fixed_endpoint)!=ECHO_KNOT or Value.read_vector3(raw.pulse_opening)!=ECHO_KNOT or not raw.get("echo_own_route") is Array or raw.echo_own_route.size()!=2 or not Value.is_vector3(raw.echo_own_route[0]) or not Value.is_vector3(raw.echo_own_route[1]) or Value.read_vector3(raw.echo_own_route[0])!=Vector3(0,0,4) or Value.read_vector3(raw.echo_own_route[1])!=ECHO_KNOT or raw.get("echo_cycles")!=1.0 or raw.get("pulse_cycles")!=1.0 or raw.get("pulse_damage_area")!="filled_disk": return "Exact fixed floor/own-route/endpoint and finite native pulse required"
	return ""

func contract_error() -> String:
	var error: String = super.contract_error()
	if not error.is_empty(): return error
	if level_id != "A3-O3" or transform != Transform3D.IDENTITY or (get_node(spawn_path) as Marker3D).position != Vector3(0,0.1,8): return "O3 identity/root/spawn differs from first-court authoring"
	return last_configuration_error

func _configure(profile_id: String, managed: bool) -> String:
	if not last_configuration_error.is_empty(): return last_configuration_error
	_profile = profile_id
	if not threat_scheduler.begin_encounter(_profile,ENCOUNTER_ID,WORLD_REVISION): return threat_scheduler.last_error
	var signature: Dictionary = Footprint.floor_signature(get_parent() as Node3D,[_floor])
	if not signature.get("accepted",false): return String(signature.get("reason","Full native firm-shore signature unavailable"))
	_world = {"data_sha256":FileAccess.get_sha256(DATA_PATH),"encounter_id":ENCOUNTER_ID,"world_revision":WORLD_REVISION,"profile_id":_profile,"collision_fingerprint":threat_scheduler.pure_collision_fingerprint(get_parent() as Node3D),"floor_signature":signature.signature.duplicate(true)}
	_context = {"world_root":get_parent() as Node3D,"source_id":ECHO_ID,"source_epoch":ECHO_EPOCH,"generation":1,"world_collision_fingerprint":_world.collision_fingerprint.duplicate(true),"world_floor_signature":_world.floor_signature.duplicate(true)}
	var prepared: Dictionary = {"world_revision":WORLD_REVISION,"collision_fingerprint":_world.collision_fingerprint.duplicate(true),"floor_signature":_world.floor_signature.duplicate(true)}
	if not echo.call("configure_source",ECHO_ID,ECHO_EPOCH,1,native_definition(),_profile,prepared,threat_scheduler) or not echo.call("retain_source_environment",get_parent() as Node3D,[_floor]): return String(echo.get("source_snapshot_error"))+"; "+String(echo.get("last_error"))
	if not mechanism.configure(PULSE_ID,Shape.circle(PULSE_ORIGIN,PULSE_RADIUS),ECHO_KNOT) or not mechanism.bind(threat_scheduler,{"hero":hero}) or not mechanism.set_presentation_guard(_pulse_presentation_guard): return mechanism.last_error
	if managed and not echo.call("enable_authored_cycle_tracking",threat_scheduler,{"hero":hero},[_floor],_context): return String(echo.get("source_snapshot_error"))+"; "+String(echo.get("last_error"))
	return ""

func _on_enter_level() -> void:
	var profile_id: String = String(shared_shell.call("get_difficulty_preference")) if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference") else "standard"
	last_configuration_error = _configure(profile_id,true)
	_active = last_configuration_error.is_empty()
	_present()

func scheduler_bindings() -> Dictionary:
	return {"world_root":get_parent() as Node3D,"owners":{ECHO_ID:echo,PULSE_ID:mechanism},"actors":{"hero":hero},"floors":{"firm-shore":_floor}}

func native_world() -> Dictionary:
	return _world.duplicate(true)

func echo_context(generation: int = 1) -> Dictionary:
	var result: Dictionary = _context.duplicate(true)
	result.generation = generation
	return result

func combat_response() -> Dictionary:
	var response: Dictionary = hero.get_threat_response_state()
	var directions: Array[Vector3] = [Vector3.BACK,Vector3.LEFT,Vector3.RIGHT,Vector3.FORWARD]
	if hero.global_position.x < 0.0: directions.assign([Vector3.BACK,Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD])
	for x: float in [-1.0,1.0]:
		for z: float in [-1.0,1.0]: directions.append(Vector3(x,0,z).normalized())
	response.merge({"world_root":get_parent() as Node3D,"world_revision":WORLD_REVISION,"encounter_id":ENCOUNTER_ID,"recognition_s":0.25,"attack_input_margin_s":0.06,"escape_directions":directions,"return_directions":directions.duplicate(),"floor_regions":[_floor]},true)
	return response

func pulse_response() -> Dictionary:
	return {"encounter_id":ENCOUNTER_ID,"world_revision":WORLD_REVISION,"recognition_s":0.25,"attack_input_margin_s":0.06,"escape_directions":[Vector3.FORWARD,Vector3.BACK,Vector3.LEFT,Vector3.RIGHT],"return_directions":[Vector3.BACK,Vector3.FORWARD,Vector3.RIGHT,Vector3.LEFT],"floor_regions":[_floor]}

func _physics_process(_delta: float) -> void:
	if not _active or get_tree().paused or not is_instance_valid(hero) or hero.dead or not last_configuration_error.is_empty(): return
	_present()
	if not hero.is_on_floor() or not hero.get_threat_response_state().get("stable",false): return
	var now: float = threat_scheduler.get_clock()
	if not bool(echo.get("dead")) and echo.call("state").get("status") == "cycle_ready" and now >= _echo_retry_at_s: _try_echo()
	# An independent eligible source still proves against ALL retained responses;
	# no global-empty-lease shortcut, hidden overlap or deadline alignment.
	if int(mechanism.state().cycle) == 0 and now >= PULSE_DUE_S and now >= _pulse_retry_at_s: _try_pulse()

func _try_echo() -> void:
	_echo_retry_at_s = threat_scheduler.get_clock()+RETRY_S
	var program: Dictionary = echo.call("source_program")
	var response: Dictionary = combat_response()
	var proof: Dictionary = Witness.new().prove_authored(threat_scheduler,echo,program,response,_context)
	if not proof.get("accepted",false): last_admission_reason = String(proof.get("reason","Actual Echo response unavailable")); return
	var projection: Dictionary = Footprint.plan_authored(threat_scheduler,program,get_parent() as Node3D,[_floor],_context)
	if not projection.get("accepted",false): last_admission_reason = String(projection.get("reason","Actual route projection unavailable")); return
	_pending_view = {"kind":"echo","projection":projection,"positions":_proof_positions(proof)}
	if not _prospective_view_ok(): return
	var answer: Dictionary = threat_scheduler.request_authored_replay(echo,program,response,_context)
	if not answer.get("accepted",false): last_admission_reason = String(answer.get("reason","Actual Echo admission rejected")); return
	_echo_record = {"projection":projection.duplicate(true),"lease":answer.reservation.duplicate(true),"proof":answer.proof.duplicate(true),"positions":_proof_positions(answer.proof),"locked":false}
	_pending_view.clear()
	if not echo.call("bind_projected",threat_scheduler,String(answer.reservation_id),{"hero":hero},[_floor],projection,_context):
		threat_scheduler.cancel(String(answer.reservation_id),"irontick_projection_binding_failed")
		last_configuration_error = String(echo.get("last_error"))
		return
	last_admission_reason = ""

func _try_pulse() -> void:
	_pulse_retry_at_s = threat_scheduler.get_clock()+RETRY_S
	var preview: Dictionary = mechanism.preview_start("hero",pulse_response())
	if not preview.get("accepted",false): last_admission_reason = String(preview.get("reason","Actual pulse preview rejected")); return
	_pending_view = {"kind":"pulse","positions":_proof_positions(preview.proof)}
	if not _prospective_view_ok(): return
	var answer: Dictionary = mechanism.start("hero",pulse_response(),null,null,preview)
	if not answer.get("accepted",false): last_admission_reason = String(answer.get("reason","Actual independent pulse admission rejected")); return
	_pulse_record = {"proof":answer.proof.duplicate(true),"positions":_proof_positions(answer.proof)}
	_pending_view.clear()
	last_admission_reason = ""

func _prospective_view_ok() -> bool:
	var union: Dictionary = framing_union(null,true)
	if not String(union.error).is_empty(): last_camera_error = String(union.error); return false
	var plan: Dictionary = shared_shell.call("camera_framing_plan",union.points,hero.global_position+Vector3.UP*0.75)
	last_camera_error = "" if plan.get("accepted",false) else String(plan.get("reason","Complete future view unavailable"))
	if last_camera_error.is_empty(): last_camera_error = String(shared_shell.call("camera_framing_error",union.points))
	return last_camera_error.is_empty()

func _guard_before_consumers() -> void:
	if not _active or _guard_busy or get_tree().paused or not is_instance_valid(hero) or hero.dead or not last_configuration_error.is_empty(): return
	_guard_busy = true
	var union: Dictionary = framing_union(null,false)
	last_camera_error = String(union.error)
	if last_camera_error.is_empty(): last_camera_error = String(shared_shell.call("camera_framing_error",union.points))
	if not last_camera_error.is_empty():
		if echo.call("state").get("status") == "running": echo.call("cancel","irontick_actual_required_view_unsafe")
		if _active and mechanism.state().status == "running": mechanism.cancel("irontick_actual_required_view_unsafe")
	elif _active and echo.call("state").get("status") == "running" and not bool(echo.get("dead")):
		var lease: Dictionary = threat_scheduler.replay_reservation_state(String(_echo_record.lease.get("id","")))
		if not lease.is_empty() and not _echo_record.locked and threat_scheduler.get_clock() >= float(lease.lock_from_s):
			var answer: Dictionary = threat_scheduler.commit_authored_replay(String(lease.id),combat_response())
			if answer.get("accepted",false):
				_echo_record.lease = answer.reservation.duplicate(true)
				_echo_record.proof = answer.proof.duplicate(true)
				_echo_record.positions = _proof_positions(answer.proof)
				_echo_record.locked = true
				var committed: Dictionary = framing_union(null,false)
				last_camera_error = String(committed.error)
				if last_camera_error.is_empty(): last_camera_error = String(shared_shell.call("camera_framing_error",committed.points))
				if not last_camera_error.is_empty() and _active: echo.call("cancel","irontick_locked_view_unsafe")
			else: last_admission_reason = String(answer.get("reason","Actual same-clock lock rejected"))
	_guard_busy = false

func _pulse_presentation_guard(_id: String, _current: Dictionary) -> bool:
	if not _active or not is_instance_valid(hero) or hero.dead: return false
	var union: Dictionary = framing_union(null,false)
	return String(union.error).is_empty() and String(shared_shell.call("camera_framing_error",union.points)).is_empty()

func _proof_positions(proof: Dictionary) -> Array:
	var points: Array = []
	for segment: Dictionary in proof.get("path",[]):
		for point: Vector3 in [segment.from,segment.to]:
			if not points.has(point): points.append(point)
	return points

func _append_mesh(points: Array, visual: MeshInstance3D) -> void:
	if visual == null or not visual.is_visible_in_tree() or visual.mesh == null: return
	var bounds: AABB = visual.get_aabb()
	for corner: int in range(8): points.append(visual.global_transform*bounds.get_endpoint(corner))

func _enclose(points: Array, raw: Array) -> void:
	if raw.is_empty(): return
	var low: Vector3 = raw[0]
	var high: Vector3 = raw[0]
	for point: Vector3 in raw: low=low.min(point); high=high.max(point)
	var box := AABB(low,high-low)
	for corner: int in range(8): points.append(box.get_endpoint(corner))

func framing_union(camera: Camera3D = null, include_pending: bool = false) -> Dictionary:
	if not is_instance_valid(hero) or not is_instance_valid(shared_shell) or not is_instance_valid(echo): return {"error":"Actual configured Hero/source/Shell required","points":[]}
	if camera == null: camera = get_viewport().get_camera_3d()
	if not is_instance_valid(camera) or camera != get_viewport().get_camera_3d() or camera.get_world_3d() != hero.get_world_3d(): return {"error":"Actual current native Camera in this Hero world required","points":[]}
	var hero_points: Array = shared_shell.call("player_camera_framing_points_for",hero,camera)
	var source: Dictionary = echo.call("framing_points")
	if hero_points.is_empty() or not String(source.get("error","Missing native source bounds")).is_empty(): return {"error":String(source.get("error","Actual Hero bounds unavailable")),"points":[]}
	var points: Array = []
	_enclose(points,hero_points)
	_enclose(points,source.points)
	var danger: Array = []
	var running: bool = echo.call("state").get("status") == "running"
	var projected: Dictionary = _pending_view.get("projection",{}) if include_pending and _pending_view.get("kind") == "echo" else _echo_record.projection
	if running or (include_pending and _pending_view.get("kind") == "echo"):
		for event: Dictionary in projected.get("events",[]):
			for x: float in [float(event.bounds[0]),float(event.bounds[2])]:
				for z: float in [float(event.bounds[1]),float(event.bounds[3])]: danger.append(Vector3(x,float(event.floor_y)+0.035,z))
	for cue: Node3D in echo.call("get_cues"):
		for child: Node in cue.get_children():
			if child is MeshInstance3D: _append_mesh(danger,child)
	var route: MeshInstance3D = echo.get_node_or_null("ExactHarmlessRoutes") as MeshInstance3D
	_append_mesh(danger,route)
	_enclose(points,danger)
	var pulse_points: Array = []
	_append_mesh(pulse_points,_pulse_marker)
	if mechanism.state().status == "running" or (include_pending and _pending_view.get("kind") == "pulse"):
		for x: float in [PULSE_ORIGIN.x-PULSE_RADIUS,PULSE_ORIGIN.x+PULSE_RADIUS]:
			for z: float in [PULSE_ORIGIN.z-PULSE_RADIUS,PULSE_ORIGIN.z+PULSE_RADIUS]: pulse_points.append(Vector3(x,0.035,z))
	for child: Node in mechanism.get_cue().get_children():
		if child is MeshInstance3D: _append_mesh(pulse_points,child)
	_enclose(points,pulse_points)
	var forecasts: Array = []
	if running: forecasts.append_array(_echo_record.positions)
	if mechanism.state().status == "running": forecasts.append_array(_pulse_record.positions)
	if include_pending: forecasts.append_array(_pending_view.get("positions",[]))
	for at: Vector3 in forecasts:
		var translated: Array = []
		for corner: Vector3 in hero_points: translated.append(corner+at-hero.global_position)
		_enclose(points,translated)
	if points.is_empty() or points.size()>224: return {"error":"Bounded complete native source/cue/Hero/response union required","points":[]}
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite(): return {"error":"Finite native framing corners required","points":[]}
	return {"error":"","points":points}

func _camera_framing_points() -> Array:
	if not _active: return []
	var union: Dictionary = framing_union(null,true)
	last_camera_framing_error = String(union.error)
	return union.points if last_camera_framing_error.is_empty() else []

func runtime_error() -> String:
	if not last_configuration_error.is_empty(): return last_configuration_error
	if not is_instance_valid(hero) or not is_instance_valid(threat_scheduler) or not is_instance_valid(echo) or not is_instance_valid(mechanism) or not is_instance_valid(_observer): return "Actual retained prototype native units required"
	if echo.get_parent()!=self or mechanism.get_parent()!=self or threat_scheduler.get_parent()!=self or _observer.get_parent()!=self or _observer.observe!=_guard_before_consumers or _observer.process_physics_priority!=90 or _observer.process_mode!=Node.PROCESS_MODE_PAUSABLE or not _observer.is_physics_processing(): return "Original same-world source/mechanism/guard ordering required"
	var error: String = scenery.call("runtime_error")
	return error if not error.is_empty() else String(echo.call("source_native_error"))

func state() -> Dictionary:
	return {"api_revision":API,"active":_active,"configuration_error":last_configuration_error,"admission_reason":last_admission_reason,"camera_error":last_camera_error,"clock_s":threat_scheduler.get_clock() if is_instance_valid(threat_scheduler) else 0.0,"profile_id":_profile,"echo":echo.call("get_source_state") if is_instance_valid(echo) else {},"playback":echo.call("state") if is_instance_valid(echo) else {},"pulse":mechanism.state() if is_instance_valid(mechanism) else {},"echo_record":_echo_record.duplicate(true),"pulse_record":_pulse_record.duplicate(true),"pulse_eligible_at_s":PULSE_DUE_S,"echo_retry_at_s":_echo_retry_at_s,"pulse_retry_at_s":_pulse_retry_at_s,"prototype":true}

func _present() -> void:
	if is_instance_valid(hero): scenery.call("follow_landmarks",hero.global_position)
	objective_text = "IRONTICK'S FIRST REFLECTION\nRETURN TO THE REAL ENDPOINT; THE OUTLINE IS HARMLESS"

func capture_view() -> Dictionary:
	var result: Dictionary = {"echo":[],"pulse":[]}
	for key: String in ["echo","pulse"]:
		var positions: Array = _echo_record.positions if key=="echo" else _pulse_record.positions
		for at: Vector3 in positions: result[key].append(Value.vector3(at))
	return result

func capture_retry_times() -> Dictionary:
	return {"echo":_echo_retry_at_s,"pulse":_pulse_retry_at_s}

func apply_codec_control(local: Dictionary) -> void:
	_context.generation = local.echo.actor.generation
	_echo_retry_at_s = local.echo.retry_at_s
	_pulse_retry_at_s = local.pulse.retry_at_s
	_echo_record = {"projection":local.echo.playback.get("projection",{}).duplicate(true),"lease":local.echo.playback.get("exchange",{}).duplicate(true),"proof":{},"positions":[],"locked":bool(local.echo.playback.get("exchange",{}).get("adapter",{}).get("locked",false))}
	_pulse_record = {"proof":{},"positions":[]}
	for value: Array in local.view.echo: _echo_record.positions.append(Value.read_vector3(value))
	for value: Array in local.view.pulse: _pulse_record.positions.append(Value.read_vector3(value))
	_pending_view.clear()
	_active = true
	_present()

func snapshot_state() -> Dictionary:
	return _checked_capture(null,null)

func snapshot_state_for_presentation(camera: Camera3D, hud: GameHUD) -> Dictionary:
	if is_restore_candidate(): last_snapshot_error="Fresh capture cannot replace saved candidate restoration"; return {}
	if not is_instance_valid(camera) or not is_instance_valid(hud): last_snapshot_error="Actual fresh Camera/HUD context required"; return {}
	return _checked_capture(camera,hud)

func _checked_capture(camera: Camera3D, hud: GameHUD) -> Dictionary:
	if _capture_busy: last_snapshot_error="Owned whole writer cannot reenter"; return {}
	if (camera==null)!=(hud==null): last_snapshot_error="Complete actual native presentation context required"; return {}
	_capture_busy=true
	_capture_camera=camera
	_capture_hud=hud
	_capture_error=""
	var packet: Dictionary = super.snapshot_state()
	var error: String = _capture_error
	_capture_camera=null
	_capture_hud=null
	_capture_busy=false
	if packet.is_empty():
		if not error.is_empty(): last_snapshot_error=error
		return {}
	last_snapshot_error=_codec.progress_error(packet.progress)
	if last_snapshot_error.is_empty(): last_snapshot_error=candidate_presentation_error(camera,hud) if camera!=null else _live_presentation_error()
	return packet if last_snapshot_error.is_empty() else {}

func _capture_local_state() -> Dictionary:
	var local: Dictionary = _codec.capture(self,hero.snapshot_state())
	_capture_error=_codec.last_error
	return local

func _local_snapshot_error(local: Dictionary) -> String:
	return _codec.record_error(local,self,hero.snapshot_state())

func _local_snapshot_error_with_player(local: Dictionary, player: Dictionary) -> String:
	return _codec.record_error(local,self,player)

func snapshot_error(saved: Dictionary) -> String:
	var error: String = super.snapshot_error(saved)
	return error if not error.is_empty() else _codec.progress_error(saved.progress)

func snapshot_error_with_player(saved: Dictionary, player: Dictionary) -> String:
	var error: String = super.snapshot_error_with_player(saved,player)
	return error if not error.is_empty() else _codec.progress_error(saved.progress)

func restore_state(saved: Dictionary) -> bool:
	_restore_error=""
	var accepted: bool = super.restore_state(saved)
	if accepted and not _restore_error.is_empty(): last_snapshot_error=_restore_error; return false
	return accepted

func _restore_local_state(local: Dictionary) -> void:
	if not _codec.restore_local(local,self,hero.snapshot_state()): _restore_error=_codec.last_error

func restore_candidate_construction_required() -> bool:
	return true

func restore_candidate_physics_registration_required() -> bool:
	return true

func _on_enter_restore_candidate(local: Dictionary, player: Dictionary) -> String:
	_active=false
	if not local.get("world") is Dictionary or not local.world.get("profile_id") is String: return "Saved canonical profile/world recipe required"
	last_configuration_error=_configure(local.world.profile_id,false)
	if not last_configuration_error.is_empty(): return last_configuration_error
	return _codec.prepare_sources(local,self,player)

func _live_presentation_error() -> String:
	var union: Dictionary = framing_union(null,false)
	return String(union.error) if not String(union.error).is_empty() else String(shared_shell.call("camera_framing_error",union.points))

func candidate_presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	if not is_instance_valid(camera) or not is_instance_valid(hud): return "Actual native Camera/HUD pair required"
	var error: String=runtime_error()
	if not error.is_empty(): return error
	var union: Dictionary=framing_union(camera,false)
	return String(union.error) if not String(union.error).is_empty() else String(shared_shell.call("camera_framing_error_for_context",union.points,hero,camera,hud))

func _restore_candidate_presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	return candidate_presentation_error(camera,hud)

func _on_exit_level() -> void:
	var discarded: bool=is_restore_candidate()
	_active=false
	_guard_busy=false
	_pending_view.clear()
	if is_instance_valid(_observer): _observer.set_physics_process(false)
	if is_instance_valid(echo): echo.set_physics_process(false)
	if is_instance_valid(mechanism): mechanism.set_physics_process(false)
	if not is_instance_valid(threat_scheduler) or not threat_scheduler.is_inside_tree(): return
	if is_instance_valid(echo) and echo.is_inside_tree():
		var control: Dictionary=threat_scheduler.source_control_state(echo)
		if not control.is_empty() and not control.reservations.is_empty():
			var recipe: Dictionary=echo.call("get_authored_cycle_restore_recipe")
			var unfinished: bool=discarded and not recipe.is_empty()
			if control.outside_transaction and echo.call("state").get("status")=="running": echo.call("cancel","irontick_whole_parent_exit")
			var remaining: Dictionary=threat_scheduler.source_control_state(echo)
			if not remaining.is_empty() and not remaining.reservations.is_empty():
				if unfinished and remaining.outside_transaction: threat_scheduler.cancel_owner(echo,"irontick_discard_unfinished_candidate")
				else: push_error("Original held managed Echo must retire inside its whole parent")
	if is_instance_valid(mechanism) and mechanism.is_inside_tree():
		var pulse: Dictionary=threat_scheduler.source_control_state(mechanism)
		if not pulse.is_empty() and not pulse.reservations.is_empty(): mechanism.cancel("irontick_whole_parent_exit")
	threat_scheduler.end_encounter("irontick_whole_parent_exit")
