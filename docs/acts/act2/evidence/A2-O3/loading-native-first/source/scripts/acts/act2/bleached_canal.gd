extends CinderLevel
## TMP source draft: three familiar arrangements over unchanged public consumers.
## One shared Player/Scheduler; no resource grant, copied kernel or new controls.
## Shell owns durable checkpoint/optional return. Geometry and mixed framing are
## provisional until focused native loading/mechanics/transport/portraits run.

const CanalKit: Script = preload("res://scripts/acts/act2/bleached_canal_kit.gd")
const ScoutActor: Script = preload("res://scripts/acts/act2/weybridge_scout_actor.gd")
const HandlerActor: Script = preload("res://scripts/acts/act2/salvage_handler_actor.gd")
const Exchange: Script = preload("res://scripts/acts/act2/ray_scout_exchange.gd")
const Scheduler: Script = preload("res://scripts/combat/threat_scheduler.gd")
const Lane: Script = preload("res://scripts/combat/lane_mechanism.gd")
const InteractionCue: Script = preload("res://scripts/cues/interaction_cue.gd")
const Geometry: Script = preload("res://scripts/combat/threat_geometry.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const AdmissionEquipment: Script = preload("res://scripts/equipment.gd")
const SharedGame: Script = preload("res://scripts/game.gd")
const SceneryMaterials: Script = preload("res://scripts/acts/act2/ruined_house_kit.gd")
const ENCOUNTER_ID: String = "A2-O3-bleached-canal"
const WORLD_REVISION: int = 1
const FLOOR_RECT: Rect2 = Rect2(-3.4, -27.0, 6.8, 30.6)
const SPAWN: Vector3 = Vector3(0, 0.1, 2.6)
const FLOOR_PROOF_INSET: float = 0.002
const WALL_POSITION: Vector3 = Vector3(-1.1, 0.225, -10.0)
const WALL_SIZE: Vector3 = Vector3(1.5, 0.45, 0.45)
const ACTOR_IDS: Array[String] = ["first_scout", "second_handler", "final_scout", "final_handler"]
const SCOUT_IDS: Array[String] = ["first_scout", "final_scout"]
const HANDLER_IDS: Array[String] = ["second_handler", "final_handler"]
const ACTOR_POSITIONS: Dictionary = {"first_scout": Vector3(-0.65,0,-3), "second_handler": Vector3(0.65,0,-12), "final_scout": Vector3(-0.65,0,-21.2), "final_handler": Vector3(0.65,0,-23.5)}
const TOOL_IDS: Dictionary = {"second_handler": "tool_second_handler", "final_handler": "tool_final_handler"}
const TOOL_ROLE: Dictionary = {"raw_damage":10.0,"windup_s":2.2,"lock_s":1.1,"active_s":0.2,"recovery_s":1.9,"attack_interval_s":1.9,"max_hp":30.0,"move_speed":0.0}
const TOOL_FLOORS: Dictionary = {"windup_s":2.2,"lock_s":1.1,"recovery_s":1.9}
const CHECKPOINT_REGION: Rect2 = Rect2(-3.1,-18.9,6.2,1.2)
const CHECKPOINT_ID: String = "bleached-canal-before-final-pocket"
const COMPLETION_ID: String = "bleached-canal-complete"
const EXIT_ID: String = "bleached-canal-return"
const EXIT_REGION: Rect2 = Rect2(-0.65,-26.55,1.3,1.1)
const EXIT_AT: Vector3 = Vector3(0,0,-26)
const LOCAL_KEYS: Array[String] = ["scenic_clock","profile_id","world_revision","stage_index","defeated_ids","defeat_times","pending_defeats","checkpoint_contact_seen","checkpoint_requested","pending_checkpoint","completion_pending","exit_requested","scheduler","actors","exchange","tools","views"]
const VIEW_KEYS: Array[String] = ["reservation_id","landing","attack_position","target_id","primary_time_s","response_complete_s","equipment_ids"]
const RESPONSE_DIRECTIONS: Array[Vector3] = [
	Vector3(1,0,0),Vector3(0.9238795325,0,0.3826834324),Vector3(0.7071067812,0,0.7071067812),Vector3(0.3826834324,0,0.9238795325),
	Vector3(0,0,1),Vector3(-0.3826834324,0,0.9238795325),Vector3(-0.7071067812,0,0.7071067812),Vector3(-0.9238795325,0,0.3826834324),
	Vector3(-1,0,0),Vector3(-0.9238795325,0,-0.3826834324),Vector3(-0.7071067812,0,-0.7071067812),Vector3(-0.3826834324,0,-0.9238795325),
	Vector3(0,0,-1),Vector3(0.3826834324,0,-0.9238795325),Vector3(0.7071067812,0,-0.7071067812),Vector3(0.9238795325,0,-0.3826834324)]

var runtime_error: String = ""
var _floor: Dictionary = {}
var _blockers: Dictionary = {}
var _kit: Dictionary = {}
var _scenery_cutaways: Array[MeshInstance3D] = []
var _actors: Dictionary = {}
var _scheduler: CinderThreatScheduler
var _exchange: Node3D
var _tools: Dictionary = {}
var _opening_cues: Dictionary = {}
var _tool_cue_bytes: Dictionary = {}
var _proofs: Dictionary = {}
var _views: Dictionary = {}
var _forecasts: Dictionary = {}
var _admission_errors: Dictionary = {}
var _exit_cue: Node3D
var _scenic_clock: float = 0.0
var _profile_id: String = "standard"
var _stage_index: int = 0
var _defeated_ids: Array[String] = []
var _defeat_times: Dictionary = {}
var _pending_defeats: Array[Dictionary] = []
var _defeat_flush_queued: bool = false
var _checkpoint_contact_seen: bool = false
var _checkpoint_requested: bool = false
var _pending_checkpoint: bool = false
var _completion_pending: bool = false
var _exit_requested: bool = false

func _ready() -> void:
	process_physics_priority = 110
	level_id = "A2-O3"
	local_snapshot_version = 1
	# PlayerSpawn is authored by the scene. Missing/moved markers fail the
	# CinderLevel contract/native reader; do not repair a malformed recipient.
	_build_ground()
	_kit = CanalKit.build(self)
	var kit_root: Node3D = _kit["root"]
	for path: Variant in kit_root.get_meta("optional_cutaway_paths", []):
		var mesh: MeshInstance3D = kit_root.get_node_or_null(NodePath(String(path))) as MeshInstance3D
		if is_instance_valid(mesh): _scenery_cutaways.append(mesh)
	_exit_cue = InteractionCue.new() as Node3D
	_exit_cue.name = "BleachedCanalContactExit"
	_exit_cue.position = EXIT_AT
	add_child(_exit_cue)
	_apply_progress_presentation()
	_update_objective()
	set_physics_process(false)

func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.name = "CanalDryGround"
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector3(FLOOR_RECT.get_center().x,-0.25,FLOOR_RECT.get_center().y)
	add_child(body)
	var box := BoxShape3D.new()
	box.size = Vector3(FLOOR_RECT.size.x,0.5,FLOOR_RECT.size.y)
	var collision := CollisionShape3D.new()
	collision.name = "CanalDrySupport"
	collision.shape = box
	body.add_child(collision)
	_floor = {"body":body,"collision":collision,"safe_rect":FLOOR_RECT.grow(-FLOOR_PROOF_INSET)}
	_build_blocker("LowVillaWall", WALL_POSITION, WALL_SIZE, false)
	_build_blocker("WestDryBank",Vector3(-3.65,0.325,-11.7),Vector3(0.5,0.65,30.6),true)
	_build_blocker("EastDryBank",Vector3(3.65,0.325,-11.7),Vector3(0.5,0.65,30.6),true)
	_build_blocker("ArrivalDryBank",Vector3(0,0.325,3.85),Vector3(6.8,0.65,0.5),true)
	_build_blocker("DepartureDryBank",Vector3(0,0.325,-27.25),Vector3(6.8,0.65,0.5),true)

func _build_blocker(id: String, at: Vector3, dimensions: Vector3, visible_match: bool) -> void:
	var body := StaticBody3D.new()
	body.name = id
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = at
	add_child(body)
	var box := BoxShape3D.new()
	box.size = dimensions
	var collision := CollisionShape3D.new()
	collision.name = id + "Shape"
	collision.shape = box
	body.add_child(collision)
	if visible_match:
		var mesh := MeshInstance3D.new()
		mesh.name = "ExactVisibleBank"
		var volume := BoxMesh.new()
		volume.size = dimensions
		mesh.mesh = volume
		mesh.material_override = SceneryMaterials._material("stone").duplicate()
		body.add_child(mesh)
		_scenery_cutaways.append(mesh)
	_blockers[id] = {"body":body,"collision":collision,"position":at,"dimensions":dimensions,"visible_match":visible_match}

func _on_enter_level() -> void:
	if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference"):
		_profile_id = String(shared_shell.call("get_difficulty_preference"))
	_scheduler = Scheduler.new() as CinderThreatScheduler
	_scheduler.name = "CanalThreatScheduler"
	add_child(_scheduler)
	if not _scheduler.begin_encounter(_profile_id,ENCOUNTER_ID,WORLD_REVISION): runtime_error = _scheduler.last_error; return
	for id: String in ACTOR_IDS:
		var actor: Node3D = (ScoutActor.new() if SCOUT_IDS.has(id) else HandlerActor.new()) as Node3D
		actor.name = id
		actor.position = ACTOR_POSITIONS[id]
		add_child(actor)
		if not actor.call("configure",hero,effects,id): runtime_error = "Cannot bind original Canal actor " + id; return
		_actors[id] = actor
	var scouts: Dictionary = {}
	for id: String in SCOUT_IDS: scouts[id] = _actors[id]
	_exchange = Exchange.new() as Node3D
	_exchange.name = "CanalScoutExchange"
	add_child(_exchange)
	if not _exchange.call("configure",hero,effects,_scheduler,scouts,_profile_id,_response_context()) or not _exchange.call("set_response_context_provider",_response_context) or not _exchange.call("set_presentation_guard",_ray_presentation_guard):
		runtime_error = "Cannot bind original Canal Scout exchange: " + String(_exchange.get("last_error")); return
	_exchange.connect("scout_defeated",_on_actor_defeated)
	_exchange.connect("state_changed",_on_ray_state)
	for id: String in HANDLER_IDS:
		_actors[id].connect("defeated",_on_actor_defeated)
		var cue: Node3D = InteractionCue.new() as Node3D
		cue.name = "LowToolOpening_" + id
		cue.position = ACTOR_POSITIONS[id]
		add_child(cue)
		_opening_cues[id] = cue
		if not _actors[id].call("bind_damage_window",Callable(self,"_handler_window").bind(id)): runtime_error = "Cannot bind original Handler recovery gate " + id; return
		var tool: Node3D = Lane.new() as Node3D
		tool.name = TOOL_IDS[id]
		tool.position = ACTOR_POSITIONS[id]
		add_child(tool)
		_tools[id] = tool
		if not tool.call("configure",TOOL_IDS[id],_tool_geometry(id),_actors[id].global_position,TOOL_ROLE,TOOL_FLOORS) or not tool.call("bind",_scheduler,{"hero":hero}) or not tool.call("set_presentation_guard",_tool_presentation_guard): runtime_error = "Cannot bind original Handler Lane " + id; return
		tool.connect("state_changed",Callable(self,"_on_tool_state").bind(id))
		tool.connect("hit_resolved",Callable(self,"_on_tool_hit").bind(id))
	hero.died.connect(_on_hero_died)
	RenderingServer.frame_pre_draw.connect(_refresh_readability)
	_update_actor_visibility()
	_pose_tools()
	_update_objective()
	set_physics_process(true)

func _node_live(value: Variant) -> bool:
	return is_instance_valid(value) and value is Node3D and value.is_inside_tree() and not value.is_queued_for_deletion() and value.get_world_3d() == get_world_3d()

func _live_level(require_unpaused: bool = true) -> bool:
	return _entered and is_inside_tree() and not is_queued_for_deletion() and runtime_error.is_empty() and not _restoring and not _validating and not _snapshotting and _node_live(hero) and _node_live(_scheduler) and (not require_unpaused or not get_tree().paused)

func _physics_process(delta: float) -> void:
	if not _live_level() or hero.dead: return
	_scenic_clock += delta
	_flush_defeats()
	_flush_progress_requests()
	if not _live_level() or hero.dead: return
	_update_actor_visibility()
	_pose_tools()
	_apply_progress_presentation()
	var response: Dictionary = hero.get_threat_response_state()
	var stable: bool = response.get("stable",false) and response.get("motion",{}).get("grounded",false) and float(response.get("commitment_remaining_s",1.0)) <= 0.00001
	if _stage_index == 2 and not _checkpoint_requested and _all_consumers_quiet() and stable and _hero_contacts(CHECKPOINT_REGION):
		_checkpoint_contact_seen = true
		_checkpoint_requested = true
		_pending_checkpoint = true
		_flush_progress_requests()
		return
	if _defeated_ids.size() == 4 and _pending_defeats.is_empty() and _all_consumers_quiet() and stable and _stage_index != 4:
		_scheduler.end_encounter("bleached_canal_complete")
		_stage_index = 4
		_completion_pending = true
		_flush_progress_requests()
		return
	if is_completed():
		if not _exit_requested and stable and _hero_contacts(EXIT_REGION):
			_exit_requested = true
			_apply_progress_presentation()
			if not request_contact_exit(EXIT_ID,hero): runtime_error = "Cannot request actual Canal contact return"
		return
	for id: String in ACTOR_IDS:
		if not _actor_admission_allowed(id): continue
		var actor: Variant = _actors.get(id)
		if not _node_live(actor): runtime_error = "Canal actual actor custody lost"; return
		if not actor.is_visible_in_tree() or hero.global_position.distance_to(actor.global_position) > 3.8 or float(actor.get("hp")) <= 0.0: continue
		if SCOUT_IDS.has(id):
			var state: Dictionary = _exchange.call("state",id)
			if state.status != "running" and _cycle_ready(state):
				var answer: Dictionary = _exchange.call("activate",id)
				_admission_errors[id] = {} if answer.get("accepted",false) else {"reason":String(answer.get("reason","rejected"))}
		elif _tools[id].call("state").status != "running": _activate_tool(id)
		if not _live_level() or hero.dead: return

func _cycle_ready(state: Dictionary) -> bool:
	return state.get("status") != "running" and _scheduler.get_clock() >= float(state.get("exchange",{}).get("cooldown_until_s",0.0))

func _actor_stage_allowed(id: String) -> bool:
	return (_stage_index == 0 and id == "first_scout") or (_stage_index == 1 and id == "second_handler") or (_stage_index == 3 and id in ["final_scout","final_handler"])

func _actor_admission_allowed(id: String) -> bool:
	return _actor_stage_allowed(id) and (_stage_index != 3 or _checkpoint_is_committed())

func _update_actor_visibility() -> void:
	for id: String in ACTOR_IDS:
		var actor: Variant = _actors.get(id)
		if not _node_live(actor): continue
		var state: Dictionary = _source_state(id)
		actor.visible = float(actor.get("hp")) <= 0.0 or state.get("status") == "running" or (_actor_stage_allowed(id) and _node_live(hero) and hero.global_position.distance_to(actor.global_position) <= 5.1)

func _checkpoint_is_committed() -> bool:
	if not _checkpoint_requested or _pending_checkpoint or current_checkpoint().get("id") != CHECKPOINT_ID: return false
	if not is_instance_valid(shared_shell) or not shared_shell.has_method("capture_campaign_snapshot"): return true
	var attempts: Variant = shared_shell.get("attempts")
	if not is_instance_valid(attempts): return false
	var model: Dictionary = attempts.call("state")
	var attempt: Variant = model.get("side_attempt")
	if not attempt is Dictionary: return false
	var checkpoint: Variant = attempt.get("checkpoint")
	if not checkpoint is Dictionary: return false
	return attempt.get("level_id") == "A2-O3" and checkpoint.get("level",{}).get("progress",{}).get("checkpoint_id") == CHECKPOINT_ID and checkpoint.get("level",{}).get("progress",{}).get("checkpoint_kind") == "encounter"

func _flush_progress_requests() -> void:
	if not _live_level(false) or hero.dead or get_tree().paused: return
	if _pending_checkpoint:
		_pending_checkpoint = false
		_stage_index = 3
		if not request_checkpoint(CHECKPOINT_ID): runtime_error = "Cannot request earned Canal before-third checkpoint"; return
	if _completion_pending:
		_completion_pending = false
		if not request_completion(COMPLETION_ID): runtime_error = "Cannot request earned Canal completion"
	_update_objective()

func _on_actor_defeated(id: String) -> void:
	if not _entered or _restoring or _validating or _snapshotting or _defeated_ids.has(id): return
	if not ACTOR_IDS.has(id): runtime_error = "Unknown actual Canal defeat"; return
	for row: Dictionary in _pending_defeats:
		if row.id == id: return
	_pending_defeats.append({"id":id,"at_s":_scenic_clock})
	_defeat_times[id] = _scenic_clock
	if HANDLER_IDS.has(id): _cancel_tool(id,"actual_handler_defeated")
	if not _defeat_flush_queued:
		_defeat_flush_queued = true
		_flush_defeats.call_deferred()

func _flush_defeats() -> void:
	_defeat_flush_queued = false
	if not _live_level() or hero.dead: return
	for row: Dictionary in _pending_defeats:
		var id: String = row.id
		if not _node_live(_actors.get(id)) or float(_actors[id].get("hp")) > 0.0: runtime_error = "Canal pending defeat lost its actual dead actor"; return
		if not _defeated_ids.has(id): _defeated_ids.append(id)
	_pending_defeats.clear()
	if _defeated_ids.size() == 1: _stage_index = 1
	elif _defeated_ids.size() == 2 and not _checkpoint_requested: _stage_index = 2
	_update_actor_visibility()
	_pose_tools()
	_update_objective()

func _all_consumers_quiet() -> bool:
	if not _node_live(_exchange): return false
	for id: String in SCOUT_IDS:
		if _exchange.call("state",id).status == "running": return false
	for id: String in HANDLER_IDS:
		if not _node_live(_tools.get(id)) or _tools[id].call("state").status == "running": return false
	return true

func _earned_complete() -> bool:
	return _stage_index == 4 and _defeated_ids.size() == 4 and _pending_defeats.is_empty() and is_instance_valid(_scheduler) and _scheduler.encounter_profile().is_empty() and not _completion_pending

func _apply_progress_presentation() -> void:
	if not is_instance_valid(_exit_cue): return
	if _earned_complete(): _exit_cue.call("present","active" if _exit_requested else "available","contact")
	else: _exit_cue.call("clear")

func _update_objective() -> void:
	match _stage_index:
		0: objective_text = "BLEACHED CANAL / FIRST POCKET\nREAD THE TRACKING MIRROR; RETURN TO THE LOW HOUSING."
		1: objective_text = "SECOND DRY POCKET\nPASS THE VISIBLE LOW WALL AND RETURN TO THE TOOL MOUNT."
		2: objective_text = "BEFORE THE LAST POCKET\nCROSS THE QUIET CHECKPOINT BY CONTACT."
		3: objective_text = "LAST DRY POCKET\nCHOOSE EITHER FAMILIAR SOURCE; KEEP BOTH RESPONSES READABLE."
		_: objective_text = "BLEACHED CANAL COMPLETE\nRETURN THROUGH THE PALE CONTACT MARKER."

func _source_state(id: String) -> Dictionary:
	if SCOUT_IDS.has(id): return _exchange.call("state",id) if _node_live(_exchange) else {}
	return _tools[id].call("state") if _node_live(_tools.get(id)) else {}

func _tool_geometry(id: String) -> Dictionary:
	var at: Vector3 = ACTOR_POSITIONS[id]
	return Geometry.lane(at,at + Vector3.BACK * 3.8,0.31)

func _handler_for_tool(id: String) -> String:
	if HANDLER_IDS.has(id): return id
	for target: String in HANDLER_IDS:
		if TOOL_IDS[target] == id: return target
	return ""

func _activate_tool(id: String) -> void:
	var tool: Variant = _tools.get(id)
	var actor: Variant = _actors.get(id)
	if not _tool_context_live(id,actor,tool) or not _cycle_ready(tool.call("state")): return
	var context: Dictionary = _response_context(id,_tool_geometry(id))
	var preview: Dictionary = tool.call("preview_start","hero",context)
	if not preview.get("accepted",false): _admission_errors[id] = {"reason":String(preview.get("reason","preview_rejected"))}; return
	var proposal: Dictionary = {"status":"running","phase":"warning","geometry":_tool_geometry(id),"proof":preview.proof}
	if not _proposal_framed(id,proposal) or not _proposal_preserves_running_responses(id,proposal):
		_admission_errors[id] = {"reason":"prospective_union_clips_original_response"}; return
	var before: Dictionary = tool.call("state")
	_forecasts[id] = {"cycle":int(before.cycle)+1,"geometry":proposal.geometry.duplicate(true),"proof":preview.proof.duplicate(true)}
	var answer: Dictionary = tool.call("start","hero",context,null,null,preview)
	if not _tool_context_live(id,actor,tool): _cancel_tool(id,"canal_native_binding_lost_after_start"); _forecasts.erase(id); return
	_admission_errors[id] = {} if answer.get("accepted",false) else {"reason":String(answer.get("reason","rejected"))}
	if not answer.get("accepted",false): _forecasts.erase(id); return
	var current: Dictionary = tool.call("state")
	if current.status != "running" or current.cycle != int(before.cycle)+1 or current.reservation_id != answer.reservation_id or current.geometry != answer.reservation.geometry or current.opening_position != actor.global_position:
		_cancel_tool(id,"canal_cycle_or_opening_lost_after_start"); _forecasts.erase(id); return
	_proofs[id] = answer.proof.duplicate(true)
	_views[id] = {"reservation_id":String(answer.reservation_id),"landing":Codec.vector3(answer.proof.landing),"attack_position":Codec.vector3(answer.proof.attack_position),"target_id":id,"primary_time_s":answer.proof.primary_time_s,"response_complete_s":answer.proof.response_complete_s,"equipment_ids":hero.equipment.snapshot()}
	_forecasts.erase(id)
	if not _proposal_framed(id,current): _cancel_tool(id,"canal_original_response_view_lost_after_start")

func _tool_context_live(id: String,actor: Variant,tool: Variant) -> bool:
	return _live_level() and not hero.dead and HANDLER_IDS.has(id) and _actors.get(id) == actor and _tools.get(id) == tool and _node_live(actor) and _node_live(tool) and actor.is_visible_in_tree() and tool.is_visible_in_tree() and float(actor.get("hp")) > 0.0 and _actor_admission_allowed(id)

func _cancel_tool(id: String,reason: String) -> void:
	var tool: Variant = _tools.get(id)
	if _node_live(tool) and tool.call("state").status == "running": tool.call("cancel",reason)

func _handler_window(id: String) -> bool:
	var actor: Variant = _actors.get(id)
	var tool: Variant = _tools.get(id)
	var cue: Variant = _opening_cues.get(id)
	if not _tool_context_live(id,actor,tool) or not _frame_visible(cue): return false
	var before: Dictionary = tool.call("state")
	if before.status != "running" or before.phase != "recovery": return false
	var lease: Dictionary = _scheduler.reservation_state(String(before.reservation_id))
	# Public query may prune another source and synchronously invalidate custody.
	if not _tool_context_live(id,actor,tool) or not _frame_visible(cue) or _opening_cues.get(id) != cue: return false
	var current: Dictionary = tool.call("state")
	if current.status != "running" or current.phase != "recovery" or current.cycle != before.cycle or current.reservation_id != before.reservation_id: return false
	if lease.is_empty() or lease.state != "recovery" or int(lease.source_instance_id) != tool.get_instance_id() or lease.geometry != current.geometry or lease.opening_position != actor.global_position: return false
	var clock: float = _scheduler.get_clock()
	if clock <= float(lease.active_until_s) or clock > float(lease.recovery_until_s) or cue.call("state").state != "available" or not _tool_cue_current(id) or not _proposal_framed(id,current): return false
	return _tool_context_live(id,actor,tool) and _frame_visible(cue) and cue.call("state").state == "available"

func _phase_progress(state: Dictionary) -> float:
	if state.get("status") != "running": return 0.0
	var key: String = {"warning":"windup_s","lock":"lock_s","active":"active_s","recovery":"recovery_s"}.get(state.phase,"")
	if key.is_empty() or state.resolved_role.is_empty(): return 0.0
	var duration: float = float(state.resolved_role[key])
	if state.phase == "warning": duration -= float(state.resolved_role.lock_s)
	return clampf(1.0-float(state.remaining_s)/maxf(duration,0.000001),0.0,1.0)

func _pose_tools(pose_actors: bool = true) -> void:
	for id: String in HANDLER_IDS:
		var tool: Variant = _tools.get(id)
		var actor: Variant = _actors.get(id)
		var cue: Variant = _opening_cues.get(id)
		if not _node_live(tool) or not _node_live(actor) or not _node_live(cue): continue
		var state: Dictionary = tool.call("state")
		var living: bool = float(actor.get("hp")) > 0.0
		if pose_actors and living: actor.call("present_phase",String(state.phase) if state.status == "running" else "idle",_phase_progress(state),Vector3.BACK)
		if not living: cue.call("present","spent","attack")
		elif state.status == "running" and state.phase == "recovery" and _actor_stage_allowed(id): cue.call("present","available","attack")
		else: cue.call("clear")

func _on_ray_state(_id: String,_state: Dictionary) -> void:
	if _entered and not _restoring and not _validating and not _snapshotting: _pose_tools()

func _on_tool_state(state: Dictionary,id: String) -> void:
	if not _entered or _restoring or _validating or _snapshotting: return
	_tool_cue_bytes[id] = _native_cue_signature(id)
	_pose_tools()
	if state.status != "running": _views.erase(id); _proofs.erase(id); _forecasts.erase(id)

func _on_tool_hit(_hero_id: String,_cycle: int,_result: Dictionary,_id: String) -> void:
	if _entered and not _restoring and not _validating and not _snapshotting: _pose_tools()


func _hero_contacts(region: Rect2) -> bool:
	return _node_live(hero) and not hero.dead and hero.global_position.y > -0.05 and hero.global_position.y < 0.2 and region.has_point(Vector2(hero.global_position.x, hero.global_position.z))


func _native_view(id: String) -> Dictionary:
	var view: Dictionary = _views.get(id, {}).duplicate(true)
	for key: String in ["landing", "attack_position"]:
		if view.has(key): view[key] = Codec.read_vector3(view[key])
	return view


func _proof_points(proof: Dictionary) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for key: String in ["landing", "attack_position"]:
		if not proof.get(key) is Vector3 or not proof[key].is_finite(): return []
		points.append_array(_landing_points(proof[key]))
	return points


func _geometry_points(shape: Dictionary) -> Array[Vector3]:
	var points: Array[Vector3] = []
	if not Geometry.error(shape).is_empty(): return points
	var radius: float = float(shape.radius)
	var ends: Array[Vector3] = []
	if shape.kind == "circle": ends.append(shape.origin)
	elif shape.kind == "lane": ends.assign([shape.from, shape.to])
	else: return points
	for at: Vector3 in ends:
		for x: float in [-radius, radius]:
			for z: float in [-radius, radius]: points.append(at + Vector3(x, 0.025, z))
	return points


func _landing_points(at: Vector3) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for x: float in [-0.32, 0.32]:
		for z: float in [-0.32, 0.32]:
			points.append(at + Vector3(x, 0.03, z))
			points.append(at + Vector3(x, 1.46, z))
	return points


func _bounded_mesh_points(node: Node) -> Array[Vector3]:
	var native: Array[Vector3] = []
	_append_mesh_points(node, native)
	if native.is_empty(): return []
	var bounds := AABB(native[0], Vector3.ZERO)
	for point: Vector3 in native: bounds = bounds.expand(point)
	var points: Array[Vector3] = []
	for index: int in range(8): points.append(bounds.get_endpoint(index))
	return points


func _append_mesh_points(node: Node, points: Array[Vector3]) -> void:
	if node is MeshInstance3D and is_instance_valid(node.mesh) and _frame_visible(node):
		for index: int in range(8): points.append(node.global_transform * node.mesh.get_aabb().get_endpoint(index))
	for child: Node in node.get_children(): _append_mesh_points(child, points)


func _frame_visible(value: Variant) -> bool:
	if not _node_live(value) or not value.global_position.is_finite() or not value.global_basis.is_finite(): return false
	var world: Variant = _scheduler_bindings().get("world_root")
	if not is_instance_valid(world) or not world.is_ancestor_of(value): return false
	var cursor: Node = value
	while cursor != world:
		if cursor is Node3D and not cursor.visible: return false
		cursor = cursor.get_parent()
		if cursor == null: return false
	# Only the real nonplayable Shell recipient may have a hidden ancestor
	# outside its native world. Never repair visibility or admit live damage.
	return value.is_visible_in_tree() or is_restore_candidate()


func _hero_points(camera: Camera3D) -> Array[Vector3]:
	var points: Array[Vector3] = []
	if is_instance_valid(shared_shell) and shared_shell.has_method("player_camera_framing_points_for"):
		points.assign(shared_shell.call("player_camera_framing_points_for", hero, camera))
	return points


func _hero_cosmetic_points(camera: Camera3D) -> Array[Vector3]:
	var native: Array[Vector3] = _hero_points(camera)
	if native.is_empty(): return []
	# Existing Handler/Scout cosmetic helper accepts <=16; enclose every one
	# of the actual shared Hero's points, without reducing mechanical framing.
	var bounds := AABB(native[0], Vector3.ZERO)
	for point: Vector3 in native: bounds = bounds.expand(point)
	var points: Array[Vector3] = []
	for index: int in range(8): points.append(bounds.get_endpoint(index))
	return points


func _settled_follow_delta(camera: Camera3D, at: Vector3) -> Vector3:
	return at + Vector3.UP * 0.75 + SharedGame.CAMERA_OFFSET - camera.global_position


func _points_framed(camera: Camera3D, points: Array[Vector3], follow_delta: Vector3 = Vector3.ZERO) -> bool:
	if not is_instance_valid(camera) or points.is_empty() or points.size() > 224 or not is_instance_valid(shared_shell) or not shared_shell.has_method("camera_framing_error"): return false
	var projected: Array[Vector3] = []
	for point: Vector3 in points:
		if not point.is_finite(): return false
		projected.append(point - follow_delta)
	return String(shared_shell.call("camera_framing_error", projected)).is_empty()


func _scenery_blocks_point(mesh: MeshInstance3D, origin: Vector3, point: Vector3) -> bool:
	# Segment/slab intersection uses actual transformed native mesh bounds. A scenery mesh
	# beyond the protected point cannot fade, nor can a mere screen rectangle.
	var inverse: Transform3D = mesh.global_transform.affine_inverse()
	var start: Vector3 = inverse * origin
	var end: Vector3 = inverse * point
	var ray: Vector3 = end - start
	var bounds: AABB = mesh.mesh.get_aabb()
	var near: float = 0.0
	var far: float = 1.0
	for axis: int in range(3):
		if absf(ray[axis]) <= 0.000000001:
			if start[axis] < bounds.position[axis] or start[axis] > bounds.end[axis]:
				return false
			continue
		var first: float = (bounds.position[axis] - start[axis]) / ray[axis]
		var second: float = (bounds.end[axis] - start[axis]) / ray[axis]
		near = maxf(near, minf(first, second))
		far = minf(far, maxf(first, second))
		if near > far:
			return false
	return near < 1.0 and far > 0.0


func _encode_geometry(shape: Dictionary) -> Dictionary:
	var copy: Dictionary = shape.duplicate(true)
	for key: String in ["origin", "from", "to"]:
		if copy.has(key): copy[key] = Codec.vector3(copy[key])
	return copy


func _saved_progress(saved: Dictionary) -> float:
	if saved.status != "running": return 0.0
	var deadline: String = {"warning": "lock_from_s", "lock": "active_from_s", "active": "active_until_s", "recovery": "recovery_until_s"}[saved.phase]
	var state: Dictionary = {"status": saved.status, "phase": saved.phase, "resolved_role": saved.resolved_role, "remaining_s": maxf(float(saved.exchange[deadline]) - float(saved.clock_s), 0.0)}
	return _phase_progress(state)


func _cue_storage_bytes(object: Object) -> PackedByteArray:
	var values: Array = []
	for property: Dictionary in object.get_property_list():
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0: continue
		var value: Variant = object.get(String(property.name))
		values.append([property.name,["object",value.get_instance_id()] if value is Object else value])
	return var_to_bytes(values)

func _native_cue_signature(id: String) -> PackedByteArray:
	var tool: Variant = _tools.get(id)
	if not _node_live(tool): return PackedByteArray()
	var state: Dictionary = tool.call("state")
	var cue: Variant = tool.call("get_cue")
	if not _frame_visible(cue) or cue.get_parent() != tool: return PackedByteArray()
	var value: Dictionary = cue.call("state")
	if value.phase != state.phase or (state.status == "running" and (value.geometry != state.geometry or value.source_position != tool.global_position or cue.global_transform != Transform3D(Basis.IDENTITY,tool.global_position))): return PackedByteArray()
	var parts: Array = [cue.get_instance_id(),cue.global_transform,value]
	for name: String in ["RequiredFootprintOutline","RequiredFootprintFill","RequiredSourceMarker"]:
		var part: MeshInstance3D = cue.get_node_or_null(name) as MeshInstance3D
		if not _node_live(part) or part.get_parent() != cue or part.material_override == null: return PackedByteArray()
		if state.status == "running":
			var expected_visible: bool = name == "RequiredSourceMarker" or (state.phase != "recovery" and (name != "RequiredFootprintFill" or state.phase == "active"))
			if part.visible != expected_visible or (expected_visible and not _frame_visible(part)) or not part.mesh is ArrayMesh: return PackedByteArray()
		parts.append([part.get_instance_id(),part.mesh.get_instance_id() if part.mesh != null else 0,part.material_override.get_instance_id(),_cue_storage_bytes(part),_cue_storage_bytes(part.material_override),part.mesh.get("_surfaces") if part.mesh is ArrayMesh else null])
	return var_to_bytes(parts)

func _tool_cue_current(id: String) -> bool:
	var bytes: PackedByteArray = _native_cue_signature(id)
	return not bytes.is_empty() and bytes == _tool_cue_bytes.get(id,PackedByteArray())

func _tool_presentation_guard(mechanism_id: String,state: Dictionary) -> bool:
	var id: String = _handler_for_tool(mechanism_id)
	if id.is_empty() or not _live_level(false) or hero.dead or not _actor_admission_allowed(id): return false
	var actor: Variant = _actors.get(id)
	var tool: Variant = _tools.get(id)
	if not _frame_visible(actor) or not _frame_visible(tool) or float(actor.get("hp")) <= 0.0: return false
	return (state.get("status") != "running" or _tool_cue_current(id)) and _proposal_framed(id,state) and _proposal_preserves_running_responses(id,state)

func _ray_presentation_guard(id: String,state: Dictionary) -> bool:
	if not SCOUT_IDS.has(id) or not _live_level(false) or hero.dead or not _actor_admission_allowed(id): return false
	var actor: Variant = _actors.get(id)
	if not _frame_visible(actor) or float(actor.get("hp")) <= 0.0: return false
	return _proposal_framed(id,state) and _proposal_preserves_running_responses(id,state)

func _view_for_source(id: String,state: Dictionary) -> Dictionary:
	var proof: Dictionary = state.get("proof",{})
	if SCOUT_IDS.has(id):
		return proof if not proof.is_empty() else state.get("presentation_witness",{})
	if not proof.is_empty(): return proof
	if _views.has(id): return _native_view(id)
	if _forecasts.has(id):
		var current: Dictionary = _source_state(id)
		var forecast: Dictionary = _forecasts[id]
		if current.get("status") == "running" and current.get("cycle") == forecast.cycle and current.get("geometry") == forecast.geometry: return forecast.proof
	return {}

func _required_source_points(id: String,proposal: Dictionary = {}) -> Array[Vector3]:
	var actor: Variant = _actors.get(id)
	var node: Variant = _exchange if SCOUT_IDS.has(id) else _tools.get(id)
	if not _frame_visible(actor) or not _frame_visible(node): return []
	var points: Array[Vector3] = _bounded_mesh_points(actor)
	if points.is_empty(): return []
	points.append_array(_landing_points(actor.global_position))
	var cue: Variant = _exchange.call("get_cue",id) if SCOUT_IDS.has(id) else node.call("get_cue")
	var opening: Variant = _exchange.call("get_opening_cue",id) if SCOUT_IDS.has(id) else _opening_cues.get(id)
	if not _frame_visible(cue) or not _frame_visible(opening): return []
	var cue_points: Array[Vector3] = _bounded_mesh_points(cue)
	points.append_array(cue_points)
	if opening.call("state").get("state") != "clear":
		var opening_points: Array[Vector3] = _bounded_mesh_points(opening)
		if opening_points.is_empty(): return []
		points.append_array(opening_points)
	var state: Dictionary = _source_state(id) if proposal.is_empty() else proposal
	var shape: Dictionary = state.get("geometry",{})
	if shape.is_empty(): shape = state.get("exchange",{}).get("geometry",{})
	if shape.is_empty() or not Geometry.error(shape).is_empty(): return []
	# Recovery's original spent lane is harmless; its low source/opening remains.
	if state.get("phase") != "recovery": points.append_array(_geometry_points(shape))
	var witness: Dictionary = _view_for_source(id,state)
	if not witness.is_empty():
		var response: Array[Vector3] = _proof_points(witness)
		if response.is_empty(): return []
		points.append_array(response)
	elif state.get("status") == "running" and (HANDLER_IDS.has(id) or state.get("armed",false)): return []
	return points

func _other_running_points(exclude: String = "") -> Array[Vector3]:
	var points: Array[Vector3] = []
	for id: String in ACTOR_IDS:
		if id == exclude: continue
		var state: Dictionary = _source_state(id)
		if state.get("status") != "running": continue
		var required: Array[Vector3] = _required_source_points(id,state)
		if required.is_empty(): return [Vector3(INF,INF,INF)]
		points.append_array(required)
	return points

func _proposal_framed(id: String,state: Dictionary) -> bool:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(camera): return false
	var points: Array[Vector3] = _required_source_points(id,state)
	if points.is_empty(): return false
	points.append_array(_other_running_points(id))
	if not _points_framed(camera,points): return false
	var witness: Dictionary = _view_for_source(id,state)
	# A tracking warning has no accepted lock witness yet. Never freeze or use
	# obsolete warning-time proof; the shared commit then supplies real witness.
	if witness.is_empty(): return SCOUT_IDS.has(id) and not state.get("armed",false)
	for key: String in ["landing","attack_position"]:
		if not witness.get(key) is Vector3 or not _points_framed(camera,points,_settled_follow_delta(camera,witness[key])): return false
	return true

func _proposal_preserves_running_responses(id: String,proposal: Dictionary) -> bool:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(camera): return false
	var points: Array[Vector3] = _required_source_points(id,proposal)
	if points.is_empty(): return false
	points.append_array(_other_running_points(id))
	for other: String in ACTOR_IDS:
		if other == id: continue
		var current: Dictionary = _source_state(other)
		if current.get("status") != "running": continue
		var retained: Dictionary = _view_for_source(other,current)
		if retained.is_empty():
			if SCOUT_IDS.has(other) and not current.get("armed",false): continue
			return false
		for key: String in ["landing","attack_position"]:
			if not retained.get(key) is Vector3 or not _points_framed(camera,points,_settled_follow_delta(camera,retained[key])): return false
	return true

func _response_context(id: String = "",shape: Dictionary = {}) -> Dictionary:
	var escapes: Array[Vector3] = RESPONSE_DIRECTIONS.duplicate()
	var returns: Array[Vector3] = RESPONSE_DIRECTIONS.duplicate()
	var target: String = _handler_for_tool(id) if not SCOUT_IDS.has(id) else id
	if not target.is_empty():
		escapes.clear()
		returns.clear()
		var camera: Camera3D = get_viewport().get_camera_3d()
		var actor: Variant = _actors.get(target)
		if is_instance_valid(camera) and _frame_visible(actor) and _node_live(hero):
			var base_points: Array[Vector3] = _bounded_mesh_points(actor)
			base_points.append_array(_landing_points(actor.global_position))
			base_points.append_array(_geometry_points(shape))
			base_points.append_array(_other_running_points(target))
			var stats: Dictionary = hero.equipment.resolved_stats()
			var distance: float = float(stats.dash_distance)
			for direction: Vector3 in RESPONSE_DIRECTIONS:
				var landing: Vector3 = hero.global_position + direction * distance
				var points: Array[Vector3] = base_points.duplicate()
				points.append_array(_landing_points(landing))
				if _points_framed(camera,points) and _points_framed(camera,points,_settled_follow_delta(camera,landing)) and _candidate_preserves_running_views(target,points,camera): escapes.append(direction)
			for direction: Vector3 in RESPONSE_DIRECTIONS:
				var reaches: bool = false
				var framed: bool = true
				for escape: Vector3 in escapes:
					var at: Vector3 = hero.global_position + (escape+direction) * distance
					if Vector2(at.x-actor.global_position.x,at.z-actor.global_position.z).length() > float(stats.primary_range)+0.00001: continue
					reaches = true
					var points: Array[Vector3] = base_points.duplicate()
					points.append_array(_landing_points(at))
					if not _points_framed(camera,points) or not _points_framed(camera,points,_settled_follow_delta(camera,at)) or not _candidate_preserves_running_views(target,points,camera): framed = false
				if reaches and framed: returns.append(direction)
	return {"encounter_id":ENCOUNTER_ID,"world_revision":WORLD_REVISION,"recognition_s":0.30,"attack_input_margin_s":0.10,"escape_directions":escapes,"return_directions":returns,"floor_regions":floor_bindings().values()}

func _candidate_preserves_running_views(exclude: String,points: Array[Vector3],camera: Camera3D) -> bool:
	for id: String in ACTOR_IDS:
		if id == exclude: continue
		var state: Dictionary = _source_state(id)
		if state.get("status") != "running": continue
		var witness: Dictionary = _view_for_source(id,state)
		if witness.is_empty():
			if SCOUT_IDS.has(id) and not state.get("armed",false): continue
			return false
		for key: String in ["landing","attack_position"]:
			if not witness.get(key) is Vector3 or not _points_framed(camera,points,_settled_follow_delta(camera,witness[key])): return false
	return true

func _camera_framing_points() -> Array:
	return _current_required_points() if _entered and runtime_error.is_empty() else []

func _current_required_points() -> Array[Vector3]:
	var points: Array[Vector3] = _other_running_points()
	if not _node_live(hero): return points
	for id: String in ACTOR_IDS:
		var actor: Variant = _actors.get(id)
		if not _frame_visible(actor) or float(actor.get("hp")) <= 0.0 or not _actor_stage_allowed(id) or hero.global_position.distance_to(actor.global_position) > 3.8 or _source_state(id).get("status") == "running": continue
		var actual: Array[Vector3] = _bounded_mesh_points(actor)
		if actual.is_empty(): return [Vector3(INF,INF,INF)]
		points.append_array(actual)
	var wall: Variant = _kit.get("root").get_node_or_null("ReusedLowVillaWall") if _node_live(_kit.get("root")) else null
	if _frame_visible(wall) and hero.global_position.distance_to(WALL_POSITION) <= 3.8: points.append_array(_bounded_mesh_points(wall))
	if _earned_complete() and _frame_visible(_exit_cue) and hero.global_position.distance_to(EXIT_AT) <= 3.1: points.append_array(_bounded_mesh_points(_exit_cue))
	# Quiet signs/outboard canal scenery are not actionable threat authority.
	return points

func _restore_candidate_presentation_error(camera: Camera3D,framing_hud: GameHUD) -> String:
	if not is_instance_valid(shared_shell) or not shared_shell.has_method("camera_framing_error_for_context"): return "Canal recipient requires actual shared camera/HUD context"
	var points: Array[Vector3] = _hero_points(camera)
	if points.is_empty(): return "Canal recipient requires actual full shared Hero bounds"
	points.append_array(_current_required_points())
	return String(shared_shell.call("camera_framing_error_for_context",points,hero,camera,framing_hud))

func _refresh_readability() -> void:
	if not _entered or not _node_live(hero) or not runtime_error.is_empty(): return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(camera): return
	var actual: Array[Vector3] = _hero_points(camera)
	var cosmetic: Array[Vector3] = _hero_cosmetic_points(camera)
	var protected: Array[Vector3] = actual.duplicate()
	protected.append_array(_current_required_points())
	for mesh: MeshInstance3D in _scenery_cutaways:
		if not _frame_visible(mesh) or mesh.mesh == null or not mesh.material_override is StandardMaterial3D: continue
		var obscures: bool = false
		for point: Vector3 in protected:
			if point.is_finite() and _scenery_blocks_point(mesh,camera.global_position,point): obscures = true; break
		var material: StandardMaterial3D = mesh.material_override as StandardMaterial3D
		var color: Color = material.albedo_color
		color.a = 0.12 if obscures else 1.0
		material.albedo_color = color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if obscures else BaseMaterial3D.TRANSPARENCY_DISABLED
	for id: String in ACTOR_IDS:
		var actor: Variant = _actors.get(id)
		if not _node_live(actor): continue
		var rig: Node3D = actor.get_node_or_null("ScoutRig" if SCOUT_IDS.has(id) else "HandlerRig") as Node3D
		if _node_live(rig):
			if actor.is_visible_in_tree(): rig.call("apply_readability",camera,cosmetic)
			else: rig.call("clear_readability")

func floor_bindings() -> Dictionary:
	return {"canal":{"collision":_floor.get("collision"),"safe_rect":_floor.get("safe_rect")}}

func floor_regions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.append({"id":"canal","rect":FLOOR_RECT,"body":_floor.get("body"),"collision":_floor.get("collision"),"safe_rect":_floor.get("safe_rect")})
	return result

func _scheduler_bindings() -> Dictionary:
	var owners: Dictionary = {}
	for id: String in SCOUT_IDS: owners[id] = _actors.get(id)
	for id: String in HANDLER_IDS: owners[TOOL_IDS[id]] = _tools.get(id)
	var world: Node = self
	while world != null:
		if world is Node3D and _node_live(hero) and is_instance_valid(_scheduler) and world.is_ancestor_of(hero) and world.is_ancestor_of(_scheduler) and is_instance_valid(_floor.get("body")) and world.is_ancestor_of(_floor.body): return {"world_root":world,"owners":owners,"floors":floor_bindings()}
		world = world.get_parent()
	return {"world_root":null,"owners":owners,"floors":floor_bindings()}

func get_actor(id: String) -> Node3D:
	var actor: Variant = _actors.get(id)
	return actor if _node_live(actor) else null

func get_scheduler() -> Node:
	return _scheduler if is_instance_valid(_scheduler) and _scheduler.is_inside_tree() else null

func get_exchange() -> Node3D:
	return _exchange if _node_live(_exchange) else null

func get_tool(id: String) -> Node3D:
	var target: String = _handler_for_tool(id)
	var tool: Variant = _tools.get(target)
	return tool if _node_live(tool) else null

func get_tool_proof(id: String) -> Dictionary:
	return _proofs.get(_handler_for_tool(id),{}).duplicate(true)

func encounter_state() -> Dictionary:
	var actors: Dictionary = {}
	var exchanges: Dictionary = {}
	var tools: Dictionary = {}
	for id: String in ACTOR_IDS:
		var actor: Variant = _actors.get(id)
		actors[id] = {"hp":actor.get("hp"),"max_hp":actor.get("max_hp"),"phase":actor.get("phase"),"progress":actor.get("phase_progress"),"direction":actor.get("direction"),"visible":actor.is_visible_in_tree(),"armed":actor.call("is_armed")} if _node_live(actor) else {"missing":true}
	for id: String in SCOUT_IDS: exchanges[id] = _source_state(id)
	for id: String in HANDLER_IDS:
		tools[id] = _source_state(id)
		tools[id]["proof"] = get_tool_proof(id)
		tools[id]["presentation_witness"] = _native_view(id)
	return {"stage_index":_stage_index,"clock_s":_scheduler.get_clock() if is_instance_valid(_scheduler) else 0.0,"defeated_ids":_defeated_ids.duplicate(),"pending_defeats":_pending_defeats.duplicate(true),"checkpoint_requested":_checkpoint_requested,"checkpoint_committed":_checkpoint_is_committed(),"exchanges":exchanges,"tools":tools,"views":_views.duplicate(true),"actors":actors,"admission_errors":_admission_errors.duplicate(true),"exit_open":_earned_complete(),"runtime_error":runtime_error}


func _runtime_content_error() -> String:
	if not is_inside_tree() or is_queued_for_deletion() or global_transform != Transform3D.IDENTITY or _actors.size() != 4 or _tools.size() != 2 or _opening_cues.size() != 2 or not _node_live(hero) or not _node_live(_scheduler) or not _node_live(_exchange) or not _node_live(_exit_cue): return "Canal requires its original native runtime unit"
	var spawn: Variant = get_node_or_null(spawn_path)
	if not _node_live(spawn) or not spawn is Marker3D or spawn.get_parent() != self or spawn.position != SPAWN or spawn.basis != Basis.IDENTITY: return "Canal original reachable feet spawn differs"
	var body: Variant = _floor.get("body")
	var collision: Variant = _floor.get("collision")
	if not _node_live(body) or not body is StaticBody3D or body.get_script() != null or body.get_parent() != self or body.position != Vector3(FLOOR_RECT.get_center().x,-0.25,FLOOR_RECT.get_center().y) or body.basis != Basis.IDENTITY or body.collision_layer != 1 or body.collision_mask != 0: return "Canal original upright continuous dry floor differs"
	if not _node_live(collision) or not collision is CollisionShape3D or collision.get_script() != null or collision.get_parent() != body or collision.disabled or collision.transform != Transform3D.IDENTITY or not collision.shape is BoxShape3D or collision.shape.size != Vector3(FLOOR_RECT.size.x,0.5,FLOOR_RECT.size.y) or _floor.get("safe_rect") != FLOOR_RECT.grow(-FLOOR_PROOF_INSET): return "Canal original native dry support differs"
	var expected_blocks: Dictionary = {"LowVillaWall":[WALL_POSITION,WALL_SIZE],"WestDryBank":[Vector3(-3.65,0.325,-11.7),Vector3(0.5,0.65,30.6)],"EastDryBank":[Vector3(3.65,0.325,-11.7),Vector3(0.5,0.65,30.6)],"ArrivalDryBank":[Vector3(0,0.325,3.85),Vector3(6.8,0.65,0.5)],"DepartureDryBank":[Vector3(0,0.325,-27.25),Vector3(6.8,0.65,0.5)]}
	if not Codec.keys_error(_blockers,expected_blocks.keys()).is_empty(): return "Canal fixed boundary/wall identities differ"
	for id: String in expected_blocks:
		var row: Dictionary = _blockers[id]
		var block: Variant = row.get("body")
		var shape: Variant = row.get("collision")
		if not _node_live(block) or not block is StaticBody3D or block.get_script() != null or block.get_parent() != self or block.name != id or block.position != expected_blocks[id][0] or block.basis != Basis.IDENTITY or block.collision_layer != 1 or block.collision_mask != 0: return "Canal original native boundary body differs: " + id
		if not _node_live(shape) or not shape is CollisionShape3D or shape.get_script() != null or shape.get_parent() != block or shape.disabled or shape.transform != Transform3D.IDENTITY or not shape.shape is BoxShape3D or shape.shape.size != expected_blocks[id][1]: return "Canal original native wall/bank Box differs: " + id
		if id != "LowVillaWall":
			var visible_mesh: Variant = block.get_node_or_null("ExactVisibleBank")
			if not _node_live(visible_mesh) or not visible_mesh is MeshInstance3D or visible_mesh.transform != Transform3D.IDENTITY or not visible_mesh.mesh is BoxMesh or visible_mesh.mesh.size != expected_blocks[id][1]: return "Canal visible bank must match its actual collider: " + id
	if _scheduler.get_script() != Scheduler or _scheduler.get_parent() != self or _scheduler.transform != Transform3D.IDENTITY or _exchange.get_script() != Exchange or _exchange.get_parent() != self or _exchange.transform != Transform3D.IDENTITY: return "Canal original Scheduler/Scout consumer custody differs"
	if _exit_cue.get_script() != InteractionCue or _exit_cue.get_parent() != self or _exit_cue.position != EXIT_AT or _exit_cue.basis != Basis.IDENTITY: return "Canal original contact exit cue differs"
	for id: String in ACTOR_IDS:
		var actor: Variant = _actors.get(id)
		var expected: Script = ScoutActor if SCOUT_IDS.has(id) else HandlerActor
		if not _node_live(actor) or actor.get_script() != expected or actor.get_parent() != self or actor.global_position != ACTOR_POSITIONS[id] or actor.global_basis != Basis.IDENTITY or String(actor.get("actor_id")) != id or not actor.call("is_armed"): return "Canal fixed native actor custody differs: " + id
		if HANDLER_IDS.has(id):
			var tool: Variant = _tools.get(id)
			var cue: Variant = _opening_cues.get(id)
			if not String(actor.call("damage_window_gate_error",Callable(self,"_handler_window").bind(id))).is_empty(): return "Canal fixed original recovery gate differs: " + id
			if not _node_live(tool) or tool.get_script() != Lane or tool.get_parent() != self or tool.global_position != ACTOR_POSITIONS[id] or tool.global_basis != Basis.IDENTITY: return "Canal fixed original Lane custody differs: " + id
			if not _node_live(cue) or cue.get_script() != InteractionCue or cue.get_parent() != self or cue.position != ACTOR_POSITIONS[id] or cue.basis != Basis.IDENTITY: return "Canal actual low tool opening differs: " + id
	if not _node_live(_kit.get("root")) or _kit.root.get_parent() != self or not _kit.get("signs") is Dictionary or not Codec.keys_error(_kit.signs,["first","second","third"]).is_empty() or not _node_live(_kit.get("canal_prop")) or not is_ancestor_of(_kit.canal_prop): return "Canal actual three quiet signs/scenic prop are missing"
	return ""

func _capture_local_state() -> Dictionary:
	if not get_tree().paused or not runtime_error.is_empty() or not _forecasts.is_empty(): return {"error":"Canal requires a healthy paused native commit barrier"}
	var custody: String = _runtime_content_error()
	if not custody.is_empty(): return {"error":custody}
	var bindings: Dictionary = _scheduler_bindings()
	var actors: Dictionary = {}
	var tools: Dictionary = {}
	for id: String in ACTOR_IDS: actors[id] = _actors[id].call("snapshot_state")
	for id: String in HANDLER_IDS: tools[id] = _tools[id].call("snapshot_state",bindings)
	return {"scenic_clock":_scenic_clock,"profile_id":_profile_id,"world_revision":WORLD_REVISION,"stage_index":_stage_index,"defeated_ids":_defeated_ids.duplicate(),"defeat_times":_defeat_times.duplicate(),"pending_defeats":_pending_defeats.duplicate(true),"checkpoint_contact_seen":_checkpoint_contact_seen,"checkpoint_requested":_checkpoint_requested,"pending_checkpoint":_pending_checkpoint,"completion_pending":_completion_pending,"exit_requested":_exit_requested,"scheduler":_scheduler.snapshot_state(bindings),"actors":actors,"exchange":_exchange.call("snapshot_state",bindings),"tools":tools,"views":_views.duplicate(true)}

func _local_snapshot_error(state: Dictionary) -> String:
	var player: Dictionary = hero.snapshot_state() if _node_live(hero) else {}
	return _whole_snapshot_error(state,player)

func _local_snapshot_error_with_player(state: Dictionary,saved_player: Dictionary) -> String:
	return _whole_snapshot_error(state,saved_player)

func _whole_snapshot_error(state: Dictionary,player: Dictionary) -> String:
	if not get_tree().paused or not runtime_error.is_empty() or not _forecasts.is_empty(): return "Canal transport requires the paused native commit barrier"
	var error: String = _runtime_content_error()
	if error.is_empty(): error = Codec.value_error(state)
	if error.is_empty(): error = Codec.keys_error(state,LOCAL_KEYS)
	if not error.is_empty(): return error
	if player.is_empty(): return "Canal requires the complete staged native Player"
	error = hero.snapshot_error(player)
	if not error.is_empty(): return error
	if not Codec.in_range(state.scenic_clock,0.0,1000000000.0) or state.profile_id not in ["assisted","standard","challenge"] or not Codec.is_integer(state.world_revision,WORLD_REVISION,WORLD_REVISION) or not Codec.is_integer(state.stage_index,0,4): return "Canal saved clock/profile/world/stage differs"
	for key: String in ["checkpoint_contact_seen","checkpoint_requested","pending_checkpoint","completion_pending","exit_requested"]:
		if not state[key] is bool: return "Canal progress latches must be Boolean"
	for key: String in ["defeat_times","scheduler","actors","exchange","tools","views"]:
		if not state[key] is Dictionary: return "Canal missing exact local dictionary: " + key
	if not state.defeated_ids is Array or not state.pending_defeats is Array or not Codec.keys_error(state.actors,ACTOR_IDS).is_empty() or not Codec.keys_error(state.tools,HANDLER_IDS).is_empty(): return "Canal requires exact four actors/two tools/history maps"
	var earned: Array[String] = []
	var previous_time: float = 0.0
	for id: Variant in state.defeated_ids:
		if not id is String or not ACTOR_IDS.has(id) or earned.has(id) or not Codec.in_range(state.defeat_times.get(id),previous_time,float(state.scenic_clock)): return "Canal committed defeats need unique native IDs and chronological times"
		earned.append(id)
		previous_time = float(state.defeat_times[id])
	for row: Variant in state.pending_defeats:
		if not row is Dictionary or not Codec.keys_error(row,["id","at_s"]).is_empty() or not row.id is String or not ACTOR_IDS.has(row.id) or earned.has(row.id) or not Codec.in_range(row.at_s,previous_time,float(state.scenic_clock)) or state.defeat_times.get(row.id) != row.at_s: return "Canal pending defeat must retain the exact actual ordered receipt"
		earned.append(row.id)
		previous_time = float(row.at_s)
	if earned.size() > 4 or not Codec.keys_error(state.defeat_times,earned).is_empty(): return "Canal defeat times differ from committed/pending identities"
	if earned.size() > 0 and earned[0] != "first_scout": return "Canal first arrangement must precede later sources"
	if earned.size() > 1 and earned[1] != "second_handler": return "Canal second arrangement must precede the final pair"
	for index: int in range(2,earned.size()):
		if earned[index] not in ["final_scout","final_handler"]: return "Canal final pair defeat order is invalid"
	var count: int = state.defeated_ids.size()
	var expected_stage: int = 0 if count == 0 else (1 if count == 1 else (2 if not state.checkpoint_requested or state.pending_checkpoint else 3))
	if state.stage_index == 4:
		if count != 4 or not state.pending_defeats.is_empty(): return "Canal clear requires all four committed defeats"
	elif state.stage_index != expected_stage: return "Canal finite stage must match its committed prefix and checkpoint"
	if state.checkpoint_contact_seen and count < 2: return "Canal checkpoint contact cannot precede its two arrangements"
	if state.checkpoint_requested != state.checkpoint_contact_seen or (state.pending_checkpoint and not state.checkpoint_requested): return "Canal checkpoint intent differs from actual quiet contact"
	if earned.size() > 2 and (not state.checkpoint_requested or state.pending_checkpoint): return "Canal final pair cannot precede the before-third checkpoint"
	var bindings: Dictionary = _scheduler_bindings()
	bindings["hero_positions"] = {"hero":Codec.read_vector3(player.motion.position)}
	error = _scheduler.snapshot_error(state.scheduler,bindings)
	if not error.is_empty(): return error
	var ended: bool = String(state.scheduler.encounter_id).is_empty()
	if int(state.scheduler.world_revision) != WORLD_REVISION: return "Canal paired Scheduler world differs"
	if ended:
		if state.stage_index != 4 or count != 4 or not state.pending_defeats.is_empty() or not state.scheduler.reservations.is_empty() or not state.scheduler.profile.is_empty(): return "Canal ended encounter requires exact clear and no leases"
	elif state.stage_index == 4 or state.scheduler.encounter_id != ENCOUNTER_ID or state.scheduler.profile.get("id") != state.profile_id: return "Canal fixed Scheduler encounter/profile differs"
	if (state.completion_pending or state.exit_requested) and not ended: return "Canal completion/exit precedes quiet ended encounter"
	if state.exit_requested and state.completion_pending: return "Canal exit precedes committed completion"
	for id: String in ACTOR_IDS:
		if not state.actors[id] is Dictionary: return "Canal actor requires its complete exact public snapshot"
		error = _actors[id].call("snapshot_error",state.actors[id])
		if not error.is_empty(): return id + ": " + error
		var actor: Dictionary = state.actors[id]
		if actor.root_position != Codec.vector3(ACTOR_POSITIONS[id]) or float(actor.max_hp) != 30.0 or (float(actor.hp) <= 0.0) != earned.has(id): return "Canal actual fixed actor root/HP/history differs: " + id
	error = _exchange.call("snapshot_error",state.exchange,bindings,state.scheduler)
	if not error.is_empty(): return error
	# The ended Scheduler has no encounter/profile; retain the authored Ray epoch.
	if state.exchange.configuration.encounter_id != ENCOUNTER_ID or state.exchange.configuration.world_revision != WORLD_REVISION or state.exchange.configuration.profile_id != state.profile_id: return "Canal fixed original Scout encounter/world/profile differs"
	for id: String in SCOUT_IDS:
		if state.exchange.actors[id] != state.actors[id]: return "Canal duplicate Scout actor envelope must be exact: " + id
	for id: String in HANDLER_IDS:
		if not state.tools[id] is Dictionary: return "Canal requires full native Lane snapshots"
		error = _tools[id].call("snapshot_error",state.tools[id],bindings,state.scheduler)
		if not error.is_empty(): return id + ": " + error
		error = _saved_tool_error(id,state.tools[id],state)
		if not error.is_empty(): return error
	for id: Variant in state.views:
		if not id is String or not HANDLER_IDS.has(id) or not state.views[id] is Dictionary: return "Canal original view has an unknown source"
		error = _saved_view_error(id,state.views[id],state.tools[id])
		if not error.is_empty(): return error
	# Inactive source types must remain pristine; do not serialize a hidden cycle.
	if count == 0 and (int(state.tools.second_handler.cycle) != 0 or float(state.actors.second_handler.hp) != 30.0): return "Canal second source cannot precede the first committed arrangement"
	if count < 2 or not state.checkpoint_requested or state.pending_checkpoint:
		if int(state.exchange.records.final_scout.cycle) != 0 or int(state.tools.final_handler.cycle) != 0 or float(state.actors.final_scout.hp) != 30.0 or float(state.actors.final_handler.hp) != 30.0: return "Canal final cycles cannot precede the recorded before-third checkpoint"
	if count >= 1 and state.exchange.records.first_scout.status == "running": return "Canal prior defeated Scout must have no live authority"
	if count >= 2 and state.tools.second_handler.status == "running": return "Canal prior defeated Handler must have no live authority"
	if ended:
		for id: String in SCOUT_IDS:
			if state.exchange.records[id].status == "running": return "Canal clear cannot discard a running Ray"
		for id: String in HANDLER_IDS:
			if state.tools[id].status == "running": return "Canal clear cannot discard a running Lane"
	return ""

func _saved_tool_error(id: String,saved: Dictionary,state: Dictionary) -> String:
	var actor: Dictionary = state.actors[id]
	if float(saved.clock_s) != float(state.scheduler.clock_s): return "Canal consumers must preserve one exact paired clock"
	if saved.configuration.raw_role != TOOL_ROLE or saved.configuration.timing_floors != TOOL_FLOORS or saved.configuration.geometry != _encode_geometry(_tool_geometry(id)) or saved.configuration.opening_position != actor.root_position: return "Canal unchanged original Handler shape/opening/role/floors differ"
	if int(saved.cycle) > 0:
		var lease: Dictionary = saved.exchange
		if lease.source_position != Codec.vector3(ACTOR_POSITIONS[id]) or lease.opening_position != actor.root_position or lease.geometry != _encode_geometry(_tool_geometry(id)) or lease.profile_id != state.profile_id or int(lease.world_revision) != WORLD_REVISION or saved.exchange_encounter_id != ENCOUNTER_ID: return "Canal original Lane source/profile/epoch differs"
	if saved.status == "running" and not state.views.has(id): return "Canal running Handler needs its original accepted view"
	if saved.status != "running" and state.views.has(id): return "Canal view cannot outlive its original running Handler"
	if float(actor.hp) <= 0.0 and saved.status == "running": return "Canal defeated Handler must cancel its original Lane"
	if float(actor.hp) < 30.0 and int(saved.cycle) < 1: return "Canal Handler HP change requires an actual original cycle"
	var phase: String = "defeated" if float(actor.hp) <= 0.0 else (String(saved.phase) if saved.status == "running" else "idle")
	var progress: float = 1.0 if float(actor.hp) <= 0.0 else _saved_progress(saved)
	if actor.phase != phase or float(actor.phase_progress) != progress or actor.direction != Codec.vector3(Vector3.BACK) or float(actor.body_yaw) != 0.0: return "Canal Handler pose must retain original phase clock and planted heading"
	return ""

func _saved_view_error(id: String,view: Dictionary,saved: Dictionary) -> String:
	if saved.status != "running" or not Codec.keys_error(view,VIEW_KEYS).is_empty() or view.target_id != id or not view.reservation_id is String or view.reservation_id != saved.exchange.id or not Codec.is_vector3(view.landing) or not Codec.is_vector3(view.attack_position) or not view.equipment_ids is Dictionary or not Codec.in_range(view.primary_time_s,0.0,1000000000.0) or not Codec.in_range(view.response_complete_s,float(view.primary_time_s),1000000000.0): return "Canal view must preserve the finite original admitted tuple"
	if float(view.primary_time_s) <= float(saved.exchange.active_until_s) or float(view.response_complete_s) > float(saved.exchange.recovery_until_s): return "Canal ordinary primary must fit the original full recovery"
	var gear: CinderEquipment = AdmissionEquipment.new() as CinderEquipment
	if not gear.restore(view.equipment_ids): return "Canal original view requires canonical admitted equipment"
	var stats: Dictionary = gear.resolved_stats()
	if float(view.response_complete_s) != float(view.primary_time_s)+float(stats.primary_cooldown): return "Canal response retains full ordinary primary cadence"
	var landing: Vector3 = Codec.read_vector3(view.landing)
	var attack: Vector3 = Codec.read_vector3(view.attack_position)
	var opening: Vector3 = Codec.read_vector3(saved.exchange.opening_position)
	if not _saved_point_supported(landing) or not _saved_point_supported(attack): return "Canal view needs actually supported unobstructed landing and return"
	if Vector2(attack.x,attack.z).distance_to(Vector2(opening.x,opening.z)) > float(stats.primary_range)-CinderThreatScheduler.SKIN: return "Canal original primary cannot reach the low mount"
	var ray := PhysicsRayQueryParameters3D.create(attack+Vector3.UP*CinderPlayer.ATTACK_LOS_HEIGHT,opening+Vector3.UP*CinderPlayer.ATTACK_LOS_HEIGHT,CinderPlayer.ATTACK_SCENERY_MASK)
	if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return "Canal original ordinary primary sight is obstructed"
	return ""

func _saved_point_supported(point: Vector3) -> bool:
	if not point.is_finite() or point.y < -0.05 or point.y > 0.2: return false
	var safe: Rect2 = (_floor.safe_rect as Rect2).grow(-(CinderThreatScheduler.CAPSULE_RADIUS+CinderThreatScheduler.SKIN))
	if point.x < safe.position.x-CinderThreatScheduler.EPSILON or point.x > safe.end.x+CinderThreatScheduler.EPSILON or point.z < safe.position.y-CinderThreatScheduler.EPSILON or point.z > safe.end.y+CinderThreatScheduler.EPSILON: return false
	# Pure native endpoint custody, not a new timed proof or private kernel copy.
	var capsule := CapsuleShape3D.new()
	capsule.radius = CinderThreatScheduler.CAPSULE_RADIUS+CinderThreatScheduler.SKIN
	capsule.height = CinderThreatScheduler.CAPSULE_HEIGHT + 2.0 * (CinderThreatScheduler.SKIN + CinderThreatScheduler.FEET_TOLERANCE)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY,point+Vector3.UP*CinderThreatScheduler.CAPSULE_CENTER_Y)
	query.collision_mask = 1
	query.exclude = [hero.get_rid(),(_floor.body as StaticBody3D).get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func snapshot_state() -> Dictionary:
	var state: Dictionary = super.snapshot_state()
	if not state.is_empty():
		last_snapshot_error = _progress_snapshot_error(state)
		if not last_snapshot_error.is_empty(): return {}
	return state

func snapshot_error(state: Dictionary) -> String:
	var error: String = super.snapshot_error(state)
	return error if not error.is_empty() else _progress_snapshot_error(state)

func snapshot_error_with_player(state: Dictionary,saved_player: Dictionary) -> String:
	var error: String = super.snapshot_error_with_player(state,saved_player)
	return error if not error.is_empty() else _progress_snapshot_error(state)

func restore_state(state: Dictionary) -> bool:
	var player: Dictionary = hero.snapshot_state() if _node_live(hero) else {}
	last_snapshot_error = "Canal restore requires actual restored paused Player" if player.is_empty() else snapshot_error_with_player(state,player)
	if not last_snapshot_error.is_empty(): return false
	var accepted: bool = super.restore_state(state)
	if accepted and not runtime_error.is_empty(): last_snapshot_error = runtime_error; return false
	return accepted

func _progress_snapshot_error(outer: Dictionary) -> String:
	var local: Dictionary = outer.local
	var progress: Dictionary = outer.progress
	var complete: bool = local.stage_index == 4 and not local.completion_pending
	if progress.completed != complete or progress.completion_id != (COMPLETION_ID if complete else "") or progress.contact_exit_id != (EXIT_ID if local.exit_requested else ""): return "Canal completion/contact history differs from actual earned three arrangements"
	var expected: Dictionary = {}
	if local.checkpoint_requested and not local.pending_checkpoint: expected[CHECKPOINT_ID] = "encounter"
	if progress.checkpoint_ids != expected or progress.checkpoint_id != (CHECKPOINT_ID if not expected.is_empty() else "") or progress.checkpoint_kind != ("encounter" if not expected.is_empty() else ""): return "Canal protected before-third checkpoint history differs"
	return ""

func _restore_local_state(state: Dictionary) -> void:
	# Entire pure preflight already passed. Shell commits the actual Player first.
	# Restore Actor yaw once, then ONE Scheduler and existing independent consumers.
	var bindings: Dictionary = _scheduler_bindings()
	for id: String in ACTOR_IDS:
		if not _actors[id].call("restore_state",state.actors[id]): runtime_error = "Unexpected Canal actor commit refusal: " + id; return
	if not _scheduler.restore_state(state.scheduler,bindings): runtime_error = "Unexpected Canal Scheduler commit refusal"; return
	if not _exchange.call("restore_state",state.exchange,bindings): runtime_error = "Unexpected Canal Scout consumer commit refusal"; return
	for id: String in HANDLER_IDS:
		if not _tools[id].call("restore_state",state.tools[id],bindings): runtime_error = "Unexpected Canal Lane commit refusal: " + id; return
	_scenic_clock = float(state.scenic_clock)
	_profile_id = state.profile_id
	_stage_index = int(state.stage_index)
	_defeated_ids.assign(state.defeated_ids)
	_defeat_times = state.defeat_times.duplicate()
	_pending_defeats.assign(state.pending_defeats)
	_defeat_flush_queued = false
	_checkpoint_contact_seen = state.checkpoint_contact_seen
	_checkpoint_requested = state.checkpoint_requested
	_pending_checkpoint = state.pending_checkpoint
	_completion_pending = state.completion_pending
	_exit_requested = state.exit_requested
	_views = state.views.duplicate(true)
	_proofs.clear()
	_forecasts.clear()
	_update_actor_visibility()
	for id: String in HANDLER_IDS: _tool_cue_bytes[id] = _native_cue_signature(id)
	var blocked: Dictionary = {}
	for id: String in HANDLER_IDS:
		blocked[id] = _opening_cues[id].is_blocking_signals()
		_opening_cues[id].set_block_signals(true)
	var exit_blocked: bool = _exit_cue.is_blocking_signals()
	_exit_cue.set_block_signals(true)
	_pose_tools(false)
	_apply_progress_presentation()
	for id: String in HANDLER_IDS: _opening_cues[id].set_block_signals(blocked[id])
	_exit_cue.set_block_signals(exit_blocked)
	_update_objective()
	_refresh_readability()

func _on_hero_died() -> void:
	if not _entered or _restoring or _validating or _snapshotting: return
	if _node_live(_exchange): _exchange.call("cancel_all","hero_defeated")
	for id: String in HANDLER_IDS: _cancel_tool(id,"hero_defeated")
	_views.clear()
	_proofs.clear()
	_forecasts.clear()
	_pose_tools()
	# Preserve actual earned pending defeats; no corpse-driven progression.

func _on_exit_level() -> void:
	set_physics_process(false)
	if RenderingServer.frame_pre_draw.is_connected(_refresh_readability): RenderingServer.frame_pre_draw.disconnect(_refresh_readability)
	if is_instance_valid(hero) and hero.died.is_connected(_on_hero_died): hero.died.disconnect(_on_hero_died)
	if is_instance_valid(_exchange):
		if _exchange.is_connected("scout_defeated",_on_actor_defeated): _exchange.disconnect("scout_defeated",_on_actor_defeated)
		if _exchange.is_connected("state_changed",_on_ray_state): _exchange.disconnect("state_changed",_on_ray_state)
		# Its own _exit_tree retires callbacks while native bindings are still live.
		# Detached fallback never queries/publishes a lost native world.
		if _exchange.is_inside_tree(): _exchange.call("cleanup")
	for id: String in HANDLER_IDS:
		var tool: Variant = _tools.get(id)
		if is_instance_valid(tool):
			if tool.is_connected("state_changed",Callable(self,"_on_tool_state").bind(id)): tool.disconnect("state_changed",Callable(self,"_on_tool_state").bind(id))
			if tool.is_connected("hit_resolved",Callable(self,"_on_tool_hit").bind(id)): tool.disconnect("hit_resolved",Callable(self,"_on_tool_hit").bind(id))
			if tool.is_inside_tree(): tool.call("clear","canal_level_exit")
		var cue: Variant = _opening_cues.get(id)
		if is_instance_valid(cue) and cue.is_inside_tree(): cue.call("clear")
	if is_instance_valid(_scheduler) and _scheduler.is_inside_tree(): _scheduler.end_encounter("canal_level_exit")
	for id: String in ACTOR_IDS:
		var actor: Variant = _actors.get(id)
		if not is_instance_valid(actor): continue
		if HANDLER_IDS.has(id):
			if actor.is_connected("defeated",_on_actor_defeated): actor.disconnect("defeated",_on_actor_defeated)
			actor.call("release_damage_window",Callable(self,"_handler_window").bind(id))
		actor.call("cleanup")
	if is_instance_valid(_exit_cue) and _exit_cue.is_inside_tree(): _exit_cue.call("clear")
	_views.clear()
	_proofs.clear()
	_forecasts.clear()
	_tool_cue_bytes.clear()
	_scenery_cutaways.clear()


