extends CinderLevel
## O3 three retained own-route Echo arrangements, independent scenic pulse
## and familiar final Stalker. All progression derives from native source hits;
## harmless reflections/pips/shell decoration have no combat authority.
const Shore = preload("res://scripts/acts/act3/mirror_sea_scenery.gd")
const StalkerSource = preload("res://scripts/acts/act3/sunbound_stalker.gd")
const InteractionCue = preload("res://scripts/cues/interaction_cue.gd")
const InteractionMesh = preload("res://scripts/cues/cue_mesh.gd")
const EchoSource = preload("res://scripts/acts/act3/mirror_echo.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Mechanism = preload("res://scripts/combat/lane_mechanism.gd")
const Shape = preload("res://scripts/combat/threat_geometry.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Witness = preload("res://scripts/combat/replay_witness.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/combat/authored_enemy_sequence.gd")
const UnitCodec = preload("res://scripts/acts/act3/irontick_reflection_codec.gd")
const API: String = "act3-irontick-reflection-2"
const ENCOUNTER_ID: String = "A3-O3/irontick-reflection"
const ECHO_ID: String = "o3-first-echo"
const ECHO_EPOCH: String = "A3-O3/o3-first-echo/own-sequence"
const PULSE_ID: String = "o3-first-pulse"
const DATA_PATH: String = "res://data/campaign/act3/a3_o3_encounters.json"
const LOCAL_VERSION: int = 2
const WORLD_REVISION: int = 1
const FLOOR_RECT: Rect2 = Rect2(-7,-11,14,22)
const ECHO_KNOT: Vector3 = Vector3(0,0,6)
const PULSE_ORIGIN: Vector3 = Vector3(0.7,0,6.65)
const PULSE_RADIUS: float = 1.15
const PULSE_DUE_S: float = 0.65
const RETRY_S: float = 0.25
const ECHO_IDS: Array[String] = ["o3-first-echo","o3-rearranged-echo","o3-final-echo"]
const STALKER_ID: String = "o3-final-stalker"
const SOURCE_IDS: Array[String] = ["o3-first-echo","o3-rearranged-echo","o3-final-echo","o3-final-stalker"]
const STAGE_IDS: Array[String] = ["first-reflection","rearranged-endpoint","final-resonant-apron"]
const CHECKPOINT_IDS: Array[String] = ["first-reflection-cleared","rearranged-endpoint-cleared"]
const COMPLETION_ID: String = "three-reflections-cleared"
const EXIT_ID: String = "irontick-return-threshold"
const EXIT_POSITION: Vector3 = Vector3(0,0,-9)
const EXIT_RECT: Rect2 = Rect2(-1.2,-9.65,2.4,1.3)
const SOURCE_POSITIONS: Dictionary = {"o3-first-echo":Vector3(0,0,6),"o3-rearranged-echo":Vector3(0.6,0,-0.4),"o3-final-echo":Vector3(0,0,-4.5),"o3-final-stalker":Vector3(1.8,0.1,-5.6)}
const ROUTE_STARTS: Dictionary = {"o3-first-echo":Vector3(0,0,4),"o3-rearranged-echo":Vector3(-0.6,0,1),"o3-final-echo":Vector3(0,0,-6.5)}
const STONE_POSITIONS: Array[Vector3] = [Vector3(-1.9,0.8,0.3),Vector3(2.9,0.8,-1.4)]
const STONE_SIZE: Vector3 = Vector3(0.8,1.6,1.2)
const PROP_VIEW_DISTANCE: float = 2.7

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
var _contexts: Dictionary = {}
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
var _echo_retry_at_s: Dictionary = {}
var _pulse_retry_at_s: float = 0.0
var _echo_records: Dictionary = {}
var sources: Dictionary = {}
var reflections: Dictionary = {}
var exit_cue: CinderInteractionCue
var _active_stage: int = 0
var _clears: Array[Dictionary] = []
var _deaths: Dictionary = {}
var _callbacks: Dictionary = {}
var _stones: Array[MeshInstance3D] = []
var _pips: Array[MeshInstance3D] = []
var _pip_materials: Array[StandardMaterial3D] = []
var _shell_views: Array[MeshInstance3D] = []
var _pip_clear_count: int = -1
var _exit_state: String = "clear"
var _contact: Dictionary = {}
var _exit_generation: int = 0
var _exit_queued: bool = false
var _prospective_exit_mesh: ArrayMesh
var _pulse_record: Dictionary = {"proof":{},"positions":[]}
var _pending_view: Dictionary = {}
var _codec = UnitCodec.new()

func _ready() -> void:
	local_snapshot_version = LOCAL_VERSION
	process_physics_priority = 130
	scenery=Shore.new(); scenery.name="IrontickFirmShore"; add_child(scenery); scenery.call("build",true)
	var floor_body: StaticBody3D=scenery.get("floor_body") as StaticBody3D
	var solid: CollisionShape3D=floor_body.get_node_or_null("Solid") as CollisionShape3D if is_instance_valid(floor_body) else null
	if not is_instance_valid(solid) or not solid.shape is BoxShape3D or (solid.shape as BoxShape3D).size!=Vector3(14,1,22): last_configuration_error="Actual unchanged 14x22 permanent shore required"; return
	_floor={"collision":solid,"safe_rect":FLOOR_RECT}
	for index: int in range(STONE_POSITIONS.size()): _build_stone(index)
	threat_scheduler=Scheduler.new(); threat_scheduler.name="IrontickThreatScheduler"; add_child(threat_scheduler)
	for id: String in SOURCE_IDS:
		var source: Node3D=EchoSource.new() if ECHO_IDS.has(id) else StalkerSource.new()
		source.name=id.replace("-","_"); add_child(source); sources[id]=source
		if ECHO_IDS.has(id):
			_echo_records[id]=_empty_echo_record(); _echo_retry_at_s[id]=0.0
			_build_reflection(id,ROUTE_STARTS[id]+Vector3(-1.4,0.02,0.4))
		else: source.position=SOURCE_POSITIONS[id]; source.set_physics_process(false)
	echo=sources[ECHO_ID]
	mechanism=Mechanism.new(); mechanism.name="IndependentScenicPulse"; mechanism.position=PULSE_ORIGIN; add_child(mechanism)
	_pulse_marker=MeshInstance3D.new(); _pulse_marker.name="QuietMineralPulseSource"
	var mesh:=BoxMesh.new(); mesh.size=Vector3(0.22,0.12,0.22)
	_pulse_marker.mesh=mesh; _pulse_marker.position.y=0.06; _pulse_marker.material_override=_material(Color("787184")); mechanism.add_child(_pulse_marker)
	_observer=ViewObserver.new(); _observer.name="IrontickBeforeConsumers"; _observer.observe=_guard_before_consumers; add_child(_observer)
	exit_cue=InteractionCue.new(); exit_cue.name="IrontickReturnContactCue"; exit_cue.position=EXIT_POSITION; add_child(exit_cue)
	_prospective_exit_mesh=InteractionMesh.interaction_mesh("available","contact")
	_build_stage_art()
	last_configuration_error=_authoring_error()

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.albedo_color = color
	return material

func _build_reflection(id: String, at: Vector3) -> void:
	var reflection:=Node3D.new()
	reflection.name="HarmlessOutlinedReflection" if id==ECHO_ID else "HarmlessOutline_"+id.replace("-","_")
	reflection.position=at; add_child(reflection); reflections[id]=reflection
	if id==ECHO_ID: _reflection=reflection
	var pieces: Array=[[Vector3(0.055,0.9,0.06),Vector3(-0.23,0.56,0)],[Vector3(0.055,0.9,0.06),Vector3(0.23,0.56,0)],[Vector3(0.51,0.055,0.06),Vector3(0,1.04,0)],[Vector3(0.51,0.055,0.06),Vector3(0,0.26,0)],[Vector3(0.055,0.23,0.06),Vector3(-0.17,1.25,0)],[Vector3(0.055,0.23,0.06),Vector3(0.17,1.25,0)],[Vector3(0.39,0.05,0.06),Vector3(0,1.39,0)],[Vector3(0.39,0.05,0.06),Vector3(0,1.12,0)]]
	for index: int in range(pieces.size()):
		var view:=MeshInstance3D.new(); view.name="QuietOutlinePart%d"%index
		var mesh:=BoxMesh.new(); mesh.size=pieces[index][0]
		view.mesh=mesh; view.position=pieces[index][1]; view.material_override=_material(Color(0.48,0.47,0.56)); view.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; reflection.add_child(view)

func native_definition(id: String = ECHO_ID) -> Dictionary:
	if not ECHO_IDS.has(id): return {}
	var knot: Vector3=SOURCE_POSITIONS[id]
	return {"definition_id":"act3/irontick/"+id+"/straight-return","definition_revision":1,"role_id":"C52","raw_role":{"raw_damage":18.0,"windup_s":2.2,"lock_s":1.1,"active_s":0.48,"recovery_s":2.2,"attack_interval_s":4.2,"max_hp":36.0,"move_speed":0.0},"timing_floors":{"windup_s":2.2,"lock_s":1.1,"recovery_s":1.8},"recognition_s":0.25,"route":[{"position":ROUTE_STARTS[id],"at_s":0.0},{"position":knot,"at_s":0.30}],"travel_clearance":{"radius_m":0.65,"height_m":1.45},"slash":{"world_origin":knot,"direction":Vector3.BACK,"reach":2.2,"cone_min_dot":0.2,"origin_disk_radius":0.25,"max_vertical_distance":0.75,"los_height":0.5,"commitment_duration_s":0.18,"visual_duration_s":0.28},"presentation":{"presentation_id":"act3/porcelain-mirror-echo","presentation_revision":1}}

func _authoring_error() -> String:
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not data is Dictionary or data.get("level_id")!="A3-O3" or data.get("prototype")!=false or data.get("encounter_id")!=ENCOUNTER_ID or data.get("stage_ids")!=STAGE_IDS or data.get("source_ids")!=SOURCE_IDS or data.get("checkpoint_ids")!=CHECKPOINT_IDS or data.get("completion_id")!=COMPLETION_ID or data.get("exit_id")!=EXIT_ID: return "Exact three-stage O3 canonical source/progress identity required"
	for key: String in ["floor_size","spawn","pulse_origin","pulse_opening","exit_position"]:
		if not Value.is_vector3(data.get(key)): return "Finite authored vector required: "+key
	if Value.read_vector3(data.floor_size)!=Vector3(14,1,22) or Value.read_vector3(data.spawn)!=Vector3(0,0.1,8) or Value.read_vector3(data.pulse_origin)!=PULSE_ORIGIN or Value.read_vector3(data.pulse_opening)!=ECHO_KNOT or Value.read_vector3(data.exit_position)!=EXIT_POSITION or data.get("pulse_radius")!=PULSE_RADIUS or data.get("pulse_eligible_at_s")!=PULSE_DUE_S: return "Original floor/spawn/pulse/return position required"
	if not data.get("source_positions") is Dictionary or not Value.keys_error(data.source_positions,SOURCE_IDS).is_empty() or not data.get("route_starts") is Dictionary or not Value.keys_error(data.route_starts,ECHO_IDS).is_empty() or not data.get("stones") is Array or data.stones.size()!=STONE_POSITIONS.size(): return "Complete immutable route/home/stone recipe required"
	for id: String in SOURCE_IDS:
		if not Value.is_vector3(data.source_positions[id]) or Value.read_vector3(data.source_positions[id])!=SOURCE_POSITIONS[id]: return "Native source home differs: "+id
	for id: String in ECHO_IDS:
		if not Value.is_vector3(data.route_starts[id]) or Value.read_vector3(data.route_starts[id])!=ROUTE_STARTS[id]: return "Native own-route differs: "+id
	for index: int in range(STONE_POSITIONS.size()):
		var row: Variant=data.stones[index]
		if not row is Dictionary or not Value.is_vector3(row.get("position")) or not Value.is_vector3(row.get("size")) or Value.read_vector3(row.position)!=STONE_POSITIONS[index] or Value.read_vector3(row.size)!=STONE_SIZE: return "Actual fixed stone differs"
	return ""

func contract_error() -> String:
	var error: String = super.contract_error()
	if not error.is_empty(): return error
	if level_id != "A3-O3" or transform != Transform3D.IDENTITY or (get_node(spawn_path) as Marker3D).position != Vector3(0,0.1,8): return "O3 identity/root/spawn differs from first-court authoring"
	return last_configuration_error

func _configure(profile_id: String, managed: bool) -> String:
	if not last_configuration_error.is_empty(): return last_configuration_error
	_profile=profile_id
	if not threat_scheduler.begin_encounter(_profile,ENCOUNTER_ID,WORLD_REVISION): return threat_scheduler.last_error
	var signature: Dictionary=Footprint.floor_signature(get_parent() as Node3D,[_floor])
	if not signature.get("accepted",false): return String(signature.get("reason","Actual full permanent shore unavailable"))
	_world={"data_sha256":FileAccess.get_sha256(DATA_PATH),"encounter_id":ENCOUNTER_ID,"world_revision":WORLD_REVISION,"profile_id":_profile,"collision_fingerprint":threat_scheduler.pure_collision_fingerprint(get_parent() as Node3D),"floor_signature":signature.signature.duplicate(true)}
	var prepared: Dictionary={"world_revision":WORLD_REVISION,"collision_fingerprint":_world.collision_fingerprint.duplicate(true),"floor_signature":_world.floor_signature.duplicate(true)}
	for id: String in ECHO_IDS:
		var context: Dictionary={"world_root":get_parent() as Node3D,"source_id":id,"source_epoch":source_epoch(id),"generation":1,"world_collision_fingerprint":_world.collision_fingerprint.duplicate(true),"world_floor_signature":_world.floor_signature.duplicate(true)}
		_contexts[id]=context
		var source: Node3D=sources[id]
		if not source.call("configure_source",id,source_epoch(id),1,native_definition(id),_profile,prepared,threat_scheduler) or not source.call("retain_source_environment",get_parent() as Node3D,[_floor]): return id+": "+String(source.get("source_snapshot_error"))+"; "+String(source.get("last_error"))
		if managed and not source.call("enable_authored_cycle_tracking",threat_scheduler,{"hero":hero},[_floor],context): return id+": "+String(source.get("source_snapshot_error"))
		var callback: Callable=_on_echo_died.bind(id); _callbacks[id]=callback; source.connect("died",callback)
	var stalker: CinderAct3SunboundStalker=sources[STALKER_ID]
	if not stalker.configure(STALKER_ID,hero,effects,threat_scheduler,combat_response.bind(STALKER_ID)): return stalker.last_error
	stalker.set_sun_visual(0); stalker.set_physics_process(false)
	var callback: Callable=_on_stalker_died.bind(STALKER_ID); _callbacks[STALKER_ID]=callback; stalker.died.connect(callback)
	if not mechanism.configure(PULSE_ID,Shape.circle(PULSE_ORIGIN,PULSE_RADIUS),ECHO_KNOT) or not mechanism.bind(threat_scheduler,{"hero":hero}) or not mechanism.set_presentation_guard(_pulse_presentation_guard): return mechanism.last_error
	return ""

func _on_enter_level() -> void:
	var profile_id: String = String(shared_shell.call("get_difficulty_preference")) if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference") else "standard"
	last_configuration_error = _configure(profile_id,true)
	_active = last_configuration_error.is_empty()
	_present()

func scheduler_bindings() -> Dictionary:
	var owners: Dictionary={PULSE_ID:mechanism}
	for id: String in SOURCE_IDS: owners[id]=sources[id]
	return {"world_root":get_parent() as Node3D,"owners":owners,"actors":{"hero":hero},"floors":{"firm-shore":_floor}}

func native_world() -> Dictionary:
	return _world.duplicate(true)

func echo_context(id: String = ECHO_ID, generation: int = 1) -> Dictionary:
	var result: Dictionary=_contexts[id].duplicate(true)
	result.generation=generation
	return result

func combat_response(id: String = ECHO_ID) -> Dictionary:
	var response: Dictionary=hero.get_threat_response_state()
	var directions: Array[Vector3]=[Vector3.BACK,Vector3.LEFT,Vector3.RIGHT,Vector3.FORWARD]
	if id==STALKER_ID:
		var away: Vector3=hero.global_position-(sources[id] as Node3D).global_position; away.y=0
		if away.length_squared()>0.0001:
			var side: Vector3=Vector3.UP.cross(away.normalized()); directions.insert(0,side); directions.insert(1,-side)
	elif hero.global_position.x<0: directions.assign([Vector3.BACK,Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD])
	for x: float in [-1.0,1.0]:
		for z: float in [-1.0,1.0]: directions.append(Vector3(x,0,z).normalized())
	response.merge({"world_root":get_parent() as Node3D,"world_revision":WORLD_REVISION,"encounter_id":ENCOUNTER_ID,"recognition_s":0.25,"attack_input_margin_s":0.06,"escape_directions":directions,"return_directions":directions.duplicate(),"floor_regions":[_floor]},true)
	return response

func pulse_response() -> Dictionary:
	return {"encounter_id":ENCOUNTER_ID,"world_revision":WORLD_REVISION,"recognition_s":0.25,"attack_input_margin_s":0.06,"escape_directions":[Vector3.FORWARD,Vector3.BACK,Vector3.LEFT,Vector3.RIGHT],"return_directions":[Vector3.BACK,Vector3.FORWARD,Vector3.RIGHT,Vector3.LEFT],"floor_regions":[_floor]}

func _physics_process(_delta: float) -> void:
	if not _active or get_tree().paused or not is_instance_valid(hero) or hero.dead or not last_configuration_error.is_empty(): return
	_present()
	var waiting_for_clear: bool=_active_stage<STAGE_IDS.size() and _deaths.has(ECHO_IDS[_active_stage])
	if waiting_for_clear: _pending_view.clear() # Unadmitted old-stage forecasts cannot delay the earned transition.
	if _advance_stage(): return
	if waiting_for_clear: return # Held sources keep their native ticks; no new first-stage pulse while framing.
	if _active_stage<STAGE_IDS.size() and hero.is_on_floor() and hero.get_threat_response_state().get("stable",false):
		_step_echo(ECHO_IDS[_active_stage])
		var now: float=threat_scheduler.get_clock()
		if _active_stage==0 and int(mechanism.state().cycle)==0 and now>=PULSE_DUE_S and now>=_pulse_retry_at_s: _try_pulse()
	if not is_completed() or _exit_state=="spent": return
	if _exit_state=="available" and _at_exit(hero.global_position) and _live_presentation_error().is_empty():
		_contact={"clock_s":threat_scheduler.get_clock(),"hero_position":Value.vector3(hero.global_position)}; _exit_state="active"; _present()
	if _exit_state=="active" and not _exit_queued:
		_exit_queued=true; _dispatch_exit.bind(_exit_generation).call_deferred()

func _try_echo(id: String) -> void:
	var source: Node3D=sources[id]
	_echo_retry_at_s[id]=threat_scheduler.get_clock()+RETRY_S
	var program: Dictionary=source.call("source_program")
	var response: Dictionary=combat_response(id)
	var context: Dictionary=_contexts[id]
	var proof: Dictionary=Witness.new().prove_authored(threat_scheduler,source,program,response,context)
	if not proof.get("accepted",false): last_admission_reason=id+": "+String(proof.get("reason","Actual response unavailable")); return
	var projection: Dictionary=Footprint.plan_authored(threat_scheduler,program,get_parent() as Node3D,[_floor],context)
	if not projection.get("accepted",false): last_admission_reason=String(projection.get("reason","Actual full route unavailable")); return
	_pending_view={"id":id,"kind":"echo","projection":projection,"positions":_proof_positions(proof)}
	if not _prospective_view_ok(): return
	var answer: Dictionary=threat_scheduler.request_authored_replay(source,program,response,context)
	if not answer.get("accepted",false): last_admission_reason=String(answer.get("reason","Native admission rejected")); return
	_echo_records[id]={"projection":projection.duplicate(true),"lease":answer.reservation.duplicate(true),"proof":answer.proof.duplicate(true),"positions":_proof_positions(answer.proof),"locked":false}
	_pending_view.clear()
	if not source.call("bind_projected",threat_scheduler,String(answer.reservation_id),{"hero":hero},[_floor],projection,context): threat_scheduler.cancel(String(answer.reservation_id),"irontick_projection_binding_failed"); last_configuration_error=id+": "+String(source.get("last_error")); return
	last_admission_reason=""

func _try_pulse() -> void:
	_pulse_retry_at_s = threat_scheduler.get_clock()+RETRY_S
	var preview: Dictionary = mechanism.preview_start("hero",pulse_response())
	if not preview.get("accepted",false): last_admission_reason = String(preview.get("reason","Actual pulse preview rejected")); return
	_pending_view = {"id":PULSE_ID,"kind":"pulse","positions":_proof_positions(preview.proof)}
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
	_guard_busy=true
	var union: Dictionary=framing_union(null,false)
	last_camera_error=String(union.error)
	if last_camera_error.is_empty(): last_camera_error=String(shared_shell.call("camera_framing_error",union.points))
	if not last_camera_error.is_empty():
		for id: String in ECHO_IDS:
			if not _active: break
			if sources[id].call("state").get("status")=="running": sources[id].call("cancel","irontick_actual_required_view_unsafe")
		var stalker: Dictionary=sources[STALKER_ID].call("state")
		if _active and not String(stalker.reservation_id).is_empty(): threat_scheduler.cancel(String(stalker.reservation_id),"irontick_actual_required_view_unsafe")
		if _active and mechanism.state().status=="running": mechanism.cancel("irontick_actual_required_view_unsafe")
	else:
		for id: String in ECHO_IDS:
			if not _active or hero.dead: break
			_commit_due_echo(id)
	_guard_busy=false

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
	return camera_framing_union("",[],false,camera,include_pending)

func camera_framing_union(candidate_id: String = "", candidate_points: Array = [], current_view: bool = false, framing_camera: Camera3D = null, include_pending: bool = false) -> Dictionary:
	if not is_instance_valid(hero) or not is_instance_valid(shared_shell): return {"error":"Actual configured Hero/Shell required","points":[]}
	var explicit: bool=framing_camera!=null
	var camera: Camera3D=framing_camera if explicit else get_viewport().get_camera_3d()
	if not is_instance_valid(camera) or camera!=get_viewport().get_camera_3d() or camera.get_world_3d()!=hero.get_world_3d(): return {"error":"Actual current native Camera required","points":[]}
	if (not candidate_id.is_empty() and (candidate_id!=STALKER_ID or candidate_points.is_empty())) or (candidate_id.is_empty() and not candidate_points.is_empty()): return {"error":"Prospective C50 bounds require this actual source","points":[]}
	var hero_points: Array=shared_shell.call("player_camera_framing_points_for",hero,camera)
	if hero_points.is_empty(): return {"error":"Actual native Hero bounds unavailable","points":[]}
	var points: Array=[]; _enclose(points,hero_points)
	if not candidate_id.is_empty(): _enclose(points,candidate_points)
	for id: String in ECHO_IDS:
		var source: Node3D=sources[id]; var record: Dictionary=_echo_records[id]
		var running: bool=source.call("state").get("status")=="running"
		var current: bool=_active_stage<STAGE_IDS.size() and id==ECHO_IDS[_active_stage]
		var pending: bool=include_pending and candidate_id.is_empty() and _pending_view.get("id")==id
		if not running and not current and not pending and source.global_position.distance_to(hero.global_position)>PROP_VIEW_DISTANCE: continue
		var art: Dictionary=source.call("framing_points")
		if not String(art.get("error","Native Echo bounds missing")).is_empty(): return art
		var raw: Array=art.points.duplicate()
		for child: Node in reflections[id].get_children():
			if child is MeshInstance3D: _append_mesh(raw,child)
		var projection: Dictionary=_pending_view.get("projection",{}) if pending else record.projection
		if running or pending:
			for event: Dictionary in projection.get("events",[]):
				for x: float in [float(event.bounds[0]),float(event.bounds[2])]:
					for z: float in [float(event.bounds[1]),float(event.bounds[3])]: raw.append(Vector3(x,float(event.floor_y)+0.035,z))
		for cue: Node3D in source.call("get_cues"):
			for child: Node in cue.get_children():
				if child is MeshInstance3D: _append_mesh(raw,child)
		_append_mesh(raw,source.get_node_or_null("ExactHarmlessRoutes") as MeshInstance3D)
		_enclose(points,raw)
		var forecasts: Array=record.positions.duplicate() if running else []
		if pending: forecasts.append_array(_pending_view.get("positions",[]))
		_append_hero_forecasts(points,hero_points,forecasts)
	var stalker: CinderAct3SunboundStalker=sources[STALKER_ID]
	if candidate_id!=STALKER_ID:
		var held: bool=not String(stalker.state().reservation_id).is_empty()
		if held:
			var live: bool=not explicit and not get_tree().paused and not is_restore_candidate() and shared_shell.get("player")==hero and shared_shell.get("camera")==camera
			var group: Dictionary=stalker.camera_framing_points(shared_shell,{}, {},current_view) if live else stalker.camera_framing_points_for_context(shared_shell,hero,camera,{}, {},current_view)
			if not String(group.error).is_empty(): return group
			_enclose(points,group.points)
		elif stalker.global_position.distance_to(hero.global_position)<=PROP_VIEW_DISTANCE:
			var group: Dictionary=stalker.current_render_framing_points_for_context(shared_shell,hero,camera)
			if not String(group.error).is_empty(): return group
			_enclose(points,group.points)
	var pulse_pending: bool=include_pending and candidate_id.is_empty() and _pending_view.get("id")==PULSE_ID
	if mechanism.state().status=="running" or pulse_pending or mechanism.global_position.distance_to(hero.global_position)<=PROP_VIEW_DISTANCE:
		var raw: Array=[]; _append_mesh(raw,_pulse_marker)
		if mechanism.state().status=="running" or pulse_pending:
			for x: float in [PULSE_ORIGIN.x-PULSE_RADIUS,PULSE_ORIGIN.x+PULSE_RADIUS]:
				for z: float in [PULSE_ORIGIN.z-PULSE_RADIUS,PULSE_ORIGIN.z+PULSE_RADIUS]: raw.append(Vector3(x,0.035,z))
		for child: Node in mechanism.get_cue().get_children():
			if child is MeshInstance3D: _append_mesh(raw,child)
		_enclose(points,raw)
		var forecasts: Array=_pulse_record.positions.duplicate() if mechanism.state().status=="running" else []
		if pulse_pending: forecasts.append_array(_pending_view.get("positions",[]))
		_append_hero_forecasts(points,hero_points,forecasts)
	if _active_stage==1:
		for stone: MeshInstance3D in _stones:
			var raw: Array=[]; _append_mesh(raw,stone); _enclose(points,raw)
	for index: int in range(_pips.size()):
		if floori(float(index)/3.0)==mini(_active_stage,STAGE_IDS.size()-1):
			var raw: Array=[]; _append_mesh(raw,_pips[index]); _enclose(points,raw)
	if _exit_state!="clear" and hero.global_position.distance_to(EXIT_POSITION)<=PROP_VIEW_DISTANCE:
		var raw: Array=[]
		var marker: MeshInstance3D=exit_cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
		if marker==null or not marker.is_visible_in_tree() or marker.mesh==null: return {"error":"Actual enabled native contact marker required","points":[]}
		_append_mesh(raw,marker)
		for view: MeshInstance3D in _shell_views: _append_mesh(raw,view)
		for x: float in [EXIT_RECT.position.x,EXIT_RECT.end.x]:
			for z: float in [EXIT_RECT.position.y,EXIT_RECT.end.y]: raw.append(Vector3(x,0.035,z))
		_enclose(points,raw)
	# Planning may anticipate a real earned transition while capture/current
	# guards retain the unchanged current stage. Keep all current/held groups.
	var next_stage: int=_transition_stage() if include_pending else -1
	if next_stage>=0:
		var error: String=_append_prospective_stage_bounds(points,next_stage,camera)
		if not error.is_empty(): return {"error":error,"points":[]}
	if points.is_empty() or points.size()>224: return {"error":"Complete native union exceeds bounded224 corners","points":[]}
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite(): return {"error":"Finite native corners required","points":[]}
	return {"error":"","points":points}

func _append_prospective_stage_bounds(points: Array, stage: int, camera: Camera3D) -> String:
	if stage<STAGE_IDS.size():
		var id: String=ECHO_IDS[stage]
		var art: Dictionary=sources[id].call("framing_points")
		var source_error: String=String(art.get("error","Native next-stage Echo bounds required"))
		if not source_error.is_empty(): return source_error
		var raw: Array=art.points.duplicate()
		for child: Node in reflections[id].get_children():
			if child is MeshInstance3D: _append_mesh(raw,child)
		_enclose(points,raw)
		if stage==1:
			for stone: MeshInstance3D in _stones:
				var bounds: Array=[]; _append_mesh(bounds,stone); _enclose(points,bounds)
		for index: int in range(_pips.size()):
			if floori(float(index)/3.0)==stage:
				var bounds: Array=[]; _append_mesh(bounds,_pips[index]); _enclose(points,bounds)
		if stage==2:
			var stalker: CinderAct3SunboundStalker=sources[STALKER_ID]
			if String(stalker.state().reservation_id).is_empty() and stalker.global_position.distance_to(hero.global_position)<=PROP_VIEW_DISTANCE:
				var group: Dictionary=stalker.current_render_framing_points_for_context(shared_shell,hero,camera)
				if not String(group.error).is_empty(): return String(group.error)
				_enclose(points,group.points)
	elif hero.global_position.distance_to(EXIT_POSITION)<=PROP_VIEW_DISTANCE:
		# Prospective contact geometry only: the actual marker remains hidden,
		# with no mesh/state/visibility change until genuine completion.
		var marker: MeshInstance3D=exit_cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
		if not is_instance_valid(marker) or not is_instance_valid(_prospective_exit_mesh): return "Native prospective contact recipe/actual marker transform required"
		var raw: Array=[]
		var bounds: AABB=_prospective_exit_mesh.get_aabb()
		for corner: int in range(8): raw.append(marker.global_transform*bounds.get_endpoint(corner))
		for view: MeshInstance3D in _shell_views: _append_mesh(raw,view)
		for x: float in [EXIT_RECT.position.x,EXIT_RECT.end.x]:
			for z: float in [EXIT_RECT.position.y,EXIT_RECT.end.y]: raw.append(Vector3(x,0.035,z))
		_enclose(points,raw)
	return ""

func _camera_framing_points() -> Array:
	if not _active: return []
	var union: Dictionary = framing_union(null,true)
	last_camera_framing_error = String(union.error)
	return union.points if last_camera_framing_error.is_empty() else []

func runtime_error() -> String:
	if not last_configuration_error.is_empty(): return last_configuration_error
	if not is_instance_valid(hero) or not is_instance_valid(threat_scheduler) or not is_instance_valid(mechanism) or not is_instance_valid(_observer) or not Value.keys_error(sources,SOURCE_IDS).is_empty(): return "Actual complete retained shore source topology required"
	if threat_scheduler.get_parent()!=self or mechanism.get_parent()!=self or _observer.get_parent()!=self or _observer.observe!=_guard_before_consumers or _observer.process_physics_priority!=90 or _observer.process_mode!=Node.PROCESS_MODE_PAUSABLE or not _observer.is_physics_processing(): return "Original retained native guard/consumer ordering required"
	var error: String=scenery.call("runtime_error")
	if not error.is_empty(): return error
	for id: String in SOURCE_IDS:
		if not is_instance_valid(sources[id]) or sources[id].get_parent()!=self or sources[id].get_world_3d()!=hero.get_world_3d(): return "Actual source/world custody required: "+id
		if ECHO_IDS.has(id):
			error=sources[id].call("source_native_error")
			if not error.is_empty(): return id+": "+error
	return ""

func state() -> Dictionary:
	var actual: Dictionary={}
	for id: String in SOURCE_IDS:
		actual[id]={"kind":"echo","actor":sources[id].call("get_source_state"),"playback":sources[id].call("state")} if ECHO_IDS.has(id) else {"kind":"stalker","actor":sources[id].call("state")}
	return {"api_revision":API,"active":_active,"configuration_error":last_configuration_error,"admission_reason":last_admission_reason,"camera_error":last_camera_error,"clock_s":threat_scheduler.get_clock(),"profile_id":_profile,"sources":actual,"echo_records":_echo_records.duplicate(true),"pulse":mechanism.state(),"pulse_record":_pulse_record.duplicate(true),"route":capture_route(),"checkpoint":current_checkpoint(),"completed":is_completed(),"prototype":false}

func _present(quiet: bool = false) -> void:
	if is_instance_valid(hero): scenery.call("follow_landmarks",hero.global_position)
	if sources.has(STALKER_ID): sources[STALKER_ID].set_physics_process(_active_stage>=2 and not sources[STALKER_ID].dead)
	if is_instance_valid(exit_cue):
		var blocked: bool=exit_cue.is_blocking_signals()
		if quiet: exit_cue.set_block_signals(true)
		if _exit_state=="clear": exit_cue.clear()
		else: exit_cue.present(_exit_state,"contact")
		if quiet: exit_cue.set_block_signals(blocked)
	if _pip_clear_count!=_clears.size():
		for index: int in range(_pip_materials.size()):
			var material: StandardMaterial3D=_pip_materials[index]
			var blocked: bool=material.is_blocking_signals()
			if quiet: material.set_block_signals(true)
			material.albedo_color=Color("aaa396") if index%3<_clears.size() else Color("544d62")
			if quiet: material.set_block_signals(blocked)
		_pip_clear_count=_clears.size()
	objective_text="IRONTICK'S LAST REFLECTION\nCONTACT THE NORTH RETURN" if is_completed() else "IRONTICK'S LAST REFLECTION\nSTAGE %d/3; RETURN TO THE REAL ENDPOINT"%mini(_active_stage+1,3)

func capture_view() -> Dictionary:
	var result: Dictionary={"echoes":{},"pulse":[]}
	for id: String in ECHO_IDS:
		result.echoes[id]=[]
		for at: Vector3 in _echo_records[id].positions: result.echoes[id].append(Value.vector3(at))
	for at: Vector3 in _pulse_record.positions: result.pulse.append(Value.vector3(at))
	return result

func capture_retry_times() -> Dictionary:
	return {"echoes":_echo_retry_at_s.duplicate(true),"pulse":_pulse_retry_at_s}

func apply_codec_control(local: Dictionary) -> void:
	_active_stage=int(local.route.active_stage); _clears.assign(local.route.clears); _deaths=local.route.deaths.duplicate(true); _exit_state=local.route.exit_state; _contact=local.route.contact.duplicate(true)
	_pulse_retry_at_s=local.pulse.retry_at_s
	for id: String in ECHO_IDS:
		var packet: Dictionary=local.sources[id]
		_contexts[id].generation=packet.actor.generation; _echo_retry_at_s[id]=packet.retry_at_s
		_echo_records[id]=_empty_echo_record(); _echo_records[id].projection=packet.playback.get("projection",{}).duplicate(true); _echo_records[id].lease=packet.playback.get("exchange",{}).duplicate(true); _echo_records[id].locked=bool(packet.playback.get("exchange",{}).get("adapter",{}).get("locked",false))
		for value: Array in local.view.echoes[id]: _echo_records[id].positions.append(Value.read_vector3(value))
	_pulse_record={"proof":{},"positions":[]}
	for value: Array in local.view.pulse: _pulse_record.positions.append(Value.read_vector3(value))
	_pending_view.clear(); _exit_queued=false; _exit_generation+=1; _active=true; _present(true)

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
	last_snapshot_error=_codec.progress_error(packet.local,packet.progress,self)
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
	return error if not error.is_empty() else _codec.progress_error(saved.local,saved.progress,self)

func snapshot_error_with_player(saved: Dictionary, player: Dictionary) -> String:
	var error: String = super.snapshot_error_with_player(saved,player)
	return error if not error.is_empty() else _codec.progress_error(saved.local,saved.progress,self)

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
	_active=false; _guard_busy=false; _pending_view.clear(); _exit_generation+=1; _exit_queued=false
	if is_instance_valid(_observer): _observer.set_physics_process(false)
	for id: String in sources:
		var source: Node3D=sources[id]; source.set_physics_process(false)
		if _callbacks.has(id) and source.is_connected("died",_callbacks[id]): source.disconnect("died",_callbacks[id])
	_callbacks.clear()
	if is_instance_valid(mechanism): mechanism.set_physics_process(false)
	if not is_instance_valid(threat_scheduler) or not threat_scheduler.is_inside_tree(): return
	for id: String in SOURCE_IDS:
		var owner: Node3D=sources.get(id)
		if not is_instance_valid(owner) or not owner.is_inside_tree(): continue
		var control: Dictionary=threat_scheduler.source_control_state(owner)
		if control.is_empty() or control.reservations.is_empty(): continue
		if not control.outside_transaction: push_error("Whole O3 retirement requires outside native transaction"); continue
		if id==STALKER_ID: threat_scheduler.cancel_owner(owner,"irontick_whole_parent_exit"); continue
		var unfinished: bool=discarded and not owner.call("get_authored_cycle_restore_recipe").is_empty()
		if owner.call("state").get("status")=="running": owner.call("cancel","irontick_whole_parent_exit")
		var remaining: Dictionary=threat_scheduler.source_control_state(owner)
		if not remaining.is_empty() and not remaining.reservations.is_empty():
			if unfinished and remaining.outside_transaction: threat_scheduler.cancel_owner(owner,"irontick_discard_unfinished_candidate")
			else: push_error("Actual committed Echo must retire inside its native whole parent")
	if is_instance_valid(mechanism):
		var pulse: Dictionary=threat_scheduler.source_control_state(mechanism)
		if not pulse.is_empty() and not pulse.reservations.is_empty(): mechanism.cancel("irontick_whole_parent_exit")
	if is_instance_valid(exit_cue): exit_cue.clear()
	threat_scheduler.end_encounter("irontick_whole_parent_exit")


func _empty_echo_record() -> Dictionary:
	return {"projection":{},"lease":{},"proof":{},"positions":[],"locked":false}

func source_epoch(id: String) -> String:
	return "A3-O3/"+id+"/own-sequence"

func _step_echo(id: String) -> void:
	var source: Node3D=sources[id]
	if source.get("dead") or threat_scheduler.get_clock()<float(_echo_retry_at_s[id]): return
	var status: String=String(source.call("state").get("status"))
	if status in ["complete","cancelled"]:
		_echo_retry_at_s[id]=threat_scheduler.get_clock()+RETRY_S
		if source.call("get_authored_cycle_terminal_receipt").is_empty(): return
		var generation: int=int(source.call("get_authored_cycle_generation"))+1
		if generation>64: last_configuration_error="Supported retained Echo generation bound reached"; return
		var reader:=Exact.new()
		if not reader.configure(id+"/own-sequence/g%d"%generation,source.call("source_definition"),id,source_epoch(id),generation,source.call("source_profile"),source.call("prepared_world")): last_configuration_error=reader.last_error; return
		if not source.call("prepare_next_authored_cycle",id+"/playback/g%d"%generation,reader.snapshot_state()): last_admission_reason=id+": "+String(source.get("last_error")); return
		_contexts[id].generation=generation; _echo_records[id]=_empty_echo_record()
		if _pending_view.get("id")==id: _pending_view.clear()
		return
	if status=="cycle_ready": _try_echo(id)

func _commit_due_echo(id: String) -> void:
	var source: Node3D=sources[id]
	if source.get("dead") or source.call("state").get("status")!="running": return
	var record: Dictionary=_echo_records[id]
	var lease: Dictionary=threat_scheduler.replay_reservation_state(String(record.lease.get("id","")))
	if lease.is_empty() or record.locked or threat_scheduler.get_clock()<float(lease.lock_from_s): return
	var answer: Dictionary=threat_scheduler.commit_authored_replay(String(lease.id),combat_response(id))
	if not _active or not is_instance_valid(source) or source.is_queued_for_deletion() or not is_instance_valid(hero) or hero.dead: return
	if not answer.get("accepted",false): last_admission_reason=id+": "+String(answer.get("reason","Actual lock rejected")); return
	record.lease=answer.reservation.duplicate(true); record.proof=answer.proof.duplicate(true); record.positions=_proof_positions(answer.proof); record.locked=true
	var union: Dictionary=framing_union(null,false)
	last_camera_error=String(union.error)
	if last_camera_error.is_empty(): last_camera_error=String(shared_shell.call("camera_framing_error",union.points))
	if not last_camera_error.is_empty() and _active: source.call("cancel","irontick_locked_view_unsafe")

func _on_echo_died(id: String) -> void:
	if not _active or _deaths.has(id) or not sources.has(id) or not sources[id].get("dead"): return
	_deaths[id]={"clock_s":threat_scheduler.get_clock(),"source_position":Value.vector3(sources[id].global_position)}

func _on_stalker_died(where: Vector3, id: String) -> void:
	if not _active or _deaths.has(id) or not sources[id].get("dead") or where!=sources[id].global_position: return
	_deaths[id]={"clock_s":threat_scheduler.get_clock(),"source_position":Value.vector3(where)}

func _transition_stage() -> int:
	if not _active or get_tree().paused or _active_stage>=STAGE_IDS.size() or not is_instance_valid(hero) or hero.dead or not hero.is_on_floor(): return -1
	var id: String=ECHO_IDS[_active_stage]
	if not _deaths.has(id) or not sources[id].get("dead"): return -1
	# Retire only a genuinely existing first-pulse exchange. A refused or
	# unadmitted environmental cycle is never forced as a progression wait.
	if _active_stage==0 and not threat_scheduler.source_control_state(mechanism).get("reservations",[]).is_empty(): return -1
	return _active_stage+1

func _advance_stage() -> bool:
	if _transition_stage()<0: return false
	# A future fit is not authority. Main fits this complete anticipated union
	# normally; commit progress only once the actual Camera contains it.
	var anticipated: Dictionary=framing_union(null,true)
	last_camera_error=String(anticipated.error)
	if last_camera_error.is_empty(): last_camera_error=String(shared_shell.call("camera_framing_error",anticipated.points))
	if not last_camera_error.is_empty(): return false
	var index: int=_active_stage
	_clears.append({"stage_id":STAGE_IDS[index],"clock_s":threat_scheduler.get_clock(),"hero_position":Value.vector3(hero.global_position)})
	_active_stage+=1
	_pending_view.clear() # Past-stage unadmitted forecasts have no next-stage authority.
	if _active_stage==STAGE_IDS.size(): _exit_state="available"
	_present()
	var accepted: bool=request_checkpoint(CHECKPOINT_IDS[index],"encounter") if index<CHECKPOINT_IDS.size() else request_completion(COMPLETION_ID)
	if not accepted: last_configuration_error="Actual native Echo stage progression rejected"
	return true

func capture_route() -> Dictionary:
	return {"active_stage":_active_stage,"clears":_clears.duplicate(true),"deaths":_deaths.duplicate(true),"exit_state":_exit_state,"contact":_contact.duplicate(true)}

func _at_exit(at: Vector3) -> bool:
	return at.is_finite() and hero.is_on_floor() and absf(at.y)<=0.2 and EXIT_RECT.has_point(Vector2(at.x,at.z))

func _dispatch_exit(generation: int) -> void:
	if generation!=_exit_generation: return
	_exit_queued=false
	if not _active or not is_instance_valid(hero) or hero.dead or not is_completed() or _exit_state!="active": return
	_exit_state="spent"; _present()
	if not request_contact_exit(EXIT_ID,hero): _exit_state="available"; _contact.clear(); _present()

func _append_hero_forecasts(points: Array, actual: Array, positions: Array) -> void:
	for at: Vector3 in positions:
		var corners: Array=[]
		for corner: Vector3 in actual: corners.append(corner+at-hero.global_position)
		_enclose(points,corners)

func _build_stone(index: int) -> void:
	var body:=StaticBody3D.new(); body.name="FixedReturnStone%d"%index; body.position=STONE_POSITIONS[index]; body.collision_layer=1; body.collision_mask=0
	var collision:=CollisionShape3D.new(); collision.name="Solid"
	var shape:=BoxShape3D.new(); shape.size=STONE_SIZE; collision.shape=shape; body.add_child(collision)
	var view:=MeshInstance3D.new(); view.name="VisibleMineralBase"; var mesh:=BoxMesh.new(); mesh.size=STONE_SIZE
	view.mesh=mesh; view.material_override=_material(Color("504556")); body.add_child(view); add_child(body); _stones.append(view)

func _build_stage_art() -> void:
	for stage: int in range(STAGE_IDS.size()):
		var anchor: Vector3=SOURCE_POSITIONS[ECHO_IDS[stage]]+Vector3(0,0.015,0.75)
		for pip: int in range(3):
			var view:=MeshInstance3D.new(); view.name="Stage%dFlatPip%d"%[stage,pip]
			var mesh:=BoxMesh.new(); mesh.size=Vector3(0.11,0.018,0.14)
			view.mesh=mesh; view.position=anchor+Vector3(float(pip-1)*0.22,0,0)
			var material: StandardMaterial3D=_material(Color("544d62")); view.material_override=material; view.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(view); _pips.append(view); _pip_materials.append(material)
	for rib: int in range(5):
		var view:=MeshInstance3D.new(); view.name="HarmlessShellRib%d"%rib
		var mesh:=BoxMesh.new(); mesh.size=Vector3(0.035,0.045,0.30)
		view.mesh=mesh; view.position=EXIT_POSITION+Vector3(float(rib-2)*0.055,0.03,0); view.rotation.y=float(rib-2)*0.20
		view.material_override=_material(Color("8f8992")); view.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(view); _shell_views.append(view)

func _snapshot_envelope_error(saved: Dictionary) -> String:
	var error: String=super._snapshot_envelope_error(saved)
	if not error.is_empty(): return error
	error=Value.keys_error(saved,["api_revision","schema_version","level_id","scene_path","local_snapshot_version","progress","local"])
	return error if not error.is_empty() else _codec.progress_error(saved.local,saved.progress,self)
