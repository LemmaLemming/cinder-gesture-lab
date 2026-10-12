extends CinderLevel
## A2-O2: two original Tender/SmokeBank pairs, then one original Handler.
## The shared Player, Scheduler, Lane and SmokeBank own inputs/damage/clocks.
## New host progression, native bindings, presentation and closed local16 codec.
## Owned source; focused parser/native/portrait evidence is recorded separately.
## New Kit path must be installed with this host; accepted L3 leaves stay intact.

const CircuitKit: Script = preload("res://scripts/acts/act2/clear_air_circuit_kit.gd")
const TenderActor: Script = preload("res://scripts/acts/act2/canister_tender_actor.gd")
const HandlerActor: Script = preload("res://scripts/acts/act2/salvage_handler_actor.gd")
const Scheduler: Script = preload("res://scripts/combat/threat_scheduler.gd")
const Bank: Script = preload("res://scripts/combat/smoke_bank.gd")
const Lane: Script = preload("res://scripts/combat/lane_mechanism.gd")
const BankGuard: Script = preload("res://scripts/acts/act2/ruined_house_bank_guard.gd")
const SmokeVisual: Script = preload("res://scripts/acts/act2/smoke_bank_visual.gd")
const InteractionCue: Script = preload("res://scripts/cues/interaction_cue.gd")
const CueMesh: Script = preload("res://scripts/cues/cue_mesh.gd")
const Geometry: Script = preload("res://scripts/combat/threat_geometry.gd")
const Difficulty: Script = preload("res://scripts/combat/difficulty.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const AdmissionEquipment: Script = preload("res://scripts/equipment.gd")
const SharedGame: Script = preload("res://scripts/game.gd")

const ENCOUNTER_ID: String = "A2-O2-clear-air-circuit"
const WORLD_REVISION: int = 1
const FLOOR_RECT: Rect2 = Rect2(-3.4, -14.8, 6.8, 18.4)
const FLOOR_PROOF_INSET: float = 0.002
const ACTOR_IDS: Array[String] = ["west_tender", "east_tender", "final_handler"]
const TENDER_IDS: Array[String] = ["west_tender", "east_tender"]
const BANK_IDS: Array[String] = ["west_bank", "east_bank"]
const ACTOR_POSITIONS: Dictionary = {"west_tender": Vector3(-1.8, 0, -2.7), "east_tender": Vector3(1.8, 0, -2.7), "final_handler": Vector3(0, 0, -10.5)}
const BANK_POSITIONS: Dictionary = {"west_bank": Vector3(-1.5, 0, -4.3), "east_bank": Vector3(1.5, 0, -4.3)}
const BANK_TO_TENDER: Dictionary = {"west_bank": "west_tender", "east_bank": "east_tender"}
const TOOL_ID: String = "final_tool"
const TOOL_ROLE: Dictionary = {"raw_damage": 10.0, "windup_s": 2.2, "lock_s": 1.1, "active_s": 0.2, "recovery_s": 1.9, "attack_interval_s": 1.9, "max_hp": 30.0, "move_speed": 0.0}
const TOOL_FLOORS: Dictionary = {"windup_s": 2.2, "lock_s": 1.1, "recovery_s": 1.9}
const CHECKPOINT_REGION: Rect2 = Rect2(-3.1, -7.2, 6.2, 1.0)
const CHECKPOINT_ID: String = "clear-air-before-final-handler"
const EXIT_REGION: Rect2 = Rect2(-0.65, -14.45, 1.3, 1.1)
const EXIT_AT: Vector3 = Vector3(0, 0, -13.9)
const COMPLETION_ID: String = "clear-air-circuit-complete"
const EXIT_ID: String = "clear-air-circuit-return"
const LOCAL_KEYS: Array[String] = ["scenic_clock", "profile_id", "world_revision", "defeated_ids", "defeat_times", "pending_defeats", "checkpoint_contact_seen", "checkpoint_requested", "pending_checkpoint", "completion_pending", "exit_requested", "scheduler", "actors", "banks", "tool", "views"]
const VIEW_KEYS: Array[String] = ["reservation_id", "landing", "attack_position", "target_id", "primary_time_s", "response_complete_s", "equipment_ids"]
const RESPONSE_DIRECTIONS: Array[Vector3] = [
	Vector3(0.707106781187, 0, -0.707106781187), Vector3(-0.707106781187, 0, -0.707106781187),
	Vector3(0.707106781187, 0, 0.707106781187), Vector3(-0.707106781187, 0, 0.707106781187),
	Vector3.FORWARD, Vector3.BACK, Vector3.RIGHT, Vector3.LEFT,
	Vector3(0.3826834324, 0, -0.9238795325), Vector3(-0.3826834324, 0, -0.9238795325),
	Vector3(0.9238795325, 0, -0.3826834324), Vector3(-0.9238795325, 0, -0.3826834324),
	Vector3(0.3826834324, 0, 0.9238795325), Vector3(-0.3826834324, 0, 0.9238795325),
	Vector3(0.9238795325, 0, 0.3826834324), Vector3(-0.9238795325, 0, 0.3826834324),
]

var runtime_error: String = ""
var _floor: Dictionary = {}
var _kit: Dictionary = {}
var _scenery_cutaways: Array[MeshInstance3D] = []
var _actors: Dictionary = {}
var _banks: Dictionary = {}
var _smoke_art: Dictionary = {}
var _opening_cues: Dictionary = {}
var _scheduler: CinderThreatScheduler
var _tool: Node3D
var _bank_guard: Node
var _exit_cue: Node3D
var _scenic_clock: float = 0.0
var _profile_id: String = "standard"
var _defeated_ids: Array[String] = []
var _defeat_times: Dictionary = {}
var _pending_defeats: Array[String] = []
var _defeat_flush_queued: bool = false
var _checkpoint_contact_seen: bool = false
var _checkpoint_requested: bool = false
var _pending_checkpoint: bool = false
var _completion_pending: bool = false
var _exit_requested: bool = false
var _views: Dictionary = {}
var _proofs: Dictionary = {}
var _forecasts: Dictionary = {}
var _bank_cue_bytes: Dictionary = {}
var _tool_cue_bytes: PackedByteArray = PackedByteArray()
var _admission_errors: Dictionary = {}


func _ready() -> void:
	process_physics_priority = 110
	level_id = "A2-O2"
	local_snapshot_version = 1
	_build_ground()
	_kit = CircuitKit.build(self)
	var kit_root: Node3D = _kit["root"]
	for path: Variant in kit_root.get_meta("optional_cutaway_paths", []):
		var mesh: MeshInstance3D = kit_root.get_node_or_null(NodePath(String(path))) as MeshInstance3D
		if is_instance_valid(mesh): _scenery_cutaways.append(mesh)
	_exit_cue = InteractionCue.new() as Node3D
	_exit_cue.name = "CircuitContactExit"
	_exit_cue.position = EXIT_AT
	add_child(_exit_cue)
	_apply_progress_presentation()
	set_physics_process(false)


func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.name = "CircuitDryGround"
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector3(FLOOR_RECT.get_center().x, -0.25, FLOOR_RECT.get_center().y)
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = Vector3(FLOOR_RECT.size.x, 0.5, FLOOR_RECT.size.y)
	var collision := CollisionShape3D.new()
	collision.name = "CircuitDrySupport"
	collision.shape = shape
	body.add_child(collision)
	_floor = {"body": body, "collision": collision, "safe_rect": FLOOR_RECT.grow(-FLOOR_PROOF_INSET)}


func _on_enter_level() -> void:
	if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference"):
		_profile_id = String(shared_shell.call("get_difficulty_preference"))
	_scheduler = Scheduler.new() as CinderThreatScheduler
	_scheduler.name = "CircuitThreatScheduler"
	add_child(_scheduler)
	if not _scheduler.begin_encounter(_profile_id, ENCOUNTER_ID, WORLD_REVISION):
		runtime_error = _scheduler.last_error
		return
	for id: String in ACTOR_IDS:
		var actor: Node3D = (HandlerActor.new() if id == "final_handler" else TenderActor.new()) as Node3D
		actor.name = id
		actor.position = ACTOR_POSITIONS[id]
		add_child(actor)
		if not actor.call("configure", hero, effects, id):
			runtime_error = "Cannot bind original Circuit actor " + id
			return
		_actors[id] = actor
		actor.connect("defeated", _on_actor_defeated)
		var cue: Node3D = InteractionCue.new() as Node3D
		cue.name = "CircuitLowOpening_" + id
		cue.position = ACTOR_POSITIONS[id]
		add_child(cue)
		_opening_cues[id] = cue
		if not actor.call("bind_damage_window", Callable(self, "_actor_window").bind(id)):
			runtime_error = "Cannot bind Circuit original recovery gate " + id
			return
	for id: String in BANK_IDS:
		var bank: Node3D = Bank.new() as Node3D
		bank.name = id
		bank.position = BANK_POSITIONS[id]
		add_child(bank)
		if not bank.call("configure", id, Geometry.circle(bank.global_position, 1.05), _actors[BANK_TO_TENDER[id]].global_position) or not bank.call("bind", _scheduler, {"hero": hero}):
			runtime_error = "Cannot bind original Circuit Bank " + id + ": " + String(bank.get("last_error"))
			return
		_banks[id] = bank
		var art: Node3D = SmokeVisual.new() as Node3D
		art.name = "CircuitLowSmoke_" + id
		art.position = bank.position
		add_child(art)
		art.call("pose", "clear", 0.0)
		_smoke_art[id] = art
		bank.connect("state_changed", Callable(self, "_on_bank_state").bind(id))
		bank.connect("tick_resolved", Callable(self, "_on_bank_tick").bind(id))
	_tool = Lane.new() as Node3D
	_tool.name = TOOL_ID
	_tool.position = ACTOR_POSITIONS.final_handler
	add_child(_tool)
	if not _tool.call("configure", TOOL_ID, _tool_geometry(), _actors.final_handler.global_position, TOOL_ROLE, TOOL_FLOORS) or not _tool.call("bind", _scheduler, {"hero": hero}) or not _tool.call("set_presentation_guard", _tool_presentation_guard):
		runtime_error = "Cannot bind original Circuit Handler lane"
		return
	_tool.connect("state_changed", _on_tool_state)
	_tool.connect("hit_resolved", _on_tool_hit)
	_bank_guard = BankGuard.new()
	_bank_guard.name = "CircuitBeforeBankContact"
	if not _bank_guard.call("configure", _guard_banks_before_contact):
		runtime_error = "Cannot bind original Circuit pre-contact guard"
		return
	add_child(_bank_guard)
	hero.died.connect(_on_hero_died)
	RenderingServer.frame_pre_draw.connect(_refresh_readability)
	_update_actor_visibility()
	_pose_consumers()
	_update_objective()
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not _live_level(false) or get_tree().paused or hero.dead: return
	_scenic_clock += delta
	_flush_defeats()
	_flush_progress_requests()
	if get_tree().paused or not _live_level(false): return
	_update_actor_visibility()
	_pose_consumers()
	_apply_progress_presentation()
	var response: Dictionary = hero.get_threat_response_state()
	var stable: bool = response.get("stable", false) and response.get("motion", {}).get("grounded", false) and float(response.get("commitment_remaining_s", 1.0)) <= 0.00001
	if _tenders_cleared() and not _checkpoint_requested and _all_consumers_quiet() and stable and _hero_contacts(CHECKPOINT_REGION):
		_checkpoint_contact_seen = true
		_checkpoint_requested = true
		_pending_checkpoint = true
		_flush_progress_requests()
		return
	if _all_defeats_committed() and _all_consumers_quiet() and not is_completed() and not _completion_pending and stable:
		_scheduler.end_encounter("clear_air_circuit_complete")
		_completion_pending = true
		_flush_progress_requests()
		return
	if is_completed():
		if not _exit_requested and stable and _hero_contacts(EXIT_REGION):
			_exit_requested = true
			_apply_progress_presentation()
			if not request_contact_exit(EXIT_ID, hero): runtime_error = "Cannot request actual Circuit contact return"
		return
	for id: String in BANK_IDS:
		var bank: Variant = _banks.get(id)
		var actor: Variant = _actors.get(BANK_TO_TENDER[id])
		if not _node_live(bank) or not _node_live(actor):
			runtime_error = "Circuit original Bank/Tender custody lost"
			return
		if bank.call("state").status == "running":
			if not _bank_framed(id): bank.call("cancel", "circuit_required_bank_view_lost")
		elif float(actor.get("hp")) > 0.0 and actor.is_visible_in_tree() and hero.global_position.distance_to(actor.global_position) <= 3.8:
			_activate_consumer(id)
		if get_tree().paused or hero.dead: return
	if _checkpoint_is_committed() and float(_actors.final_handler.get("hp")) > 0.0 and _actors.final_handler.is_visible_in_tree() and hero.global_position.distance_to(_actors.final_handler.global_position) <= 3.8 and _tool.call("state").status != "running":
		_activate_consumer(TOOL_ID)


func _node_live(value: Variant) -> bool:
	return is_instance_valid(value) and value is Node3D and value.is_inside_tree() and not value.is_queued_for_deletion() and value.get_world_3d() == get_world_3d()


func _live_level(require_unpaused: bool = true) -> bool:
	return _entered and is_inside_tree() and not is_queued_for_deletion() and runtime_error.is_empty() and not _restoring and not _validating and not _snapshotting and _node_live(hero) and _node_live(_scheduler) and (not require_unpaused or not get_tree().paused)


func _actor_for_consumer(id: String) -> String:
	return "final_handler" if id == TOOL_ID else String(BANK_TO_TENDER.get(id, ""))


func _consumer(id: String) -> Variant:
	return _tool if id == TOOL_ID else _banks.get(id)


func _tool_geometry() -> Dictionary:
	var at: Vector3 = ACTOR_POSITIONS.final_handler
	return Geometry.lane(at, at + Vector3.BACK * 3.8, 0.31)


func _bank_id(target: String) -> String:
	for id: String in BANK_IDS:
		if BANK_TO_TENDER[id] == target: return id
	return ""


func _activate_consumer(id: String) -> void:
	var node: Variant = _consumer(id)
	var target: String = _actor_for_consumer(id)
	var actor: Variant = _actors.get(target)
	var player: CinderPlayer = hero
	var scheduler: CinderThreatScheduler = _scheduler
	if not _consumer_context_live(id, actor, node, player, scheduler): return
	if id == TOOL_ID and not _checkpoint_is_committed(): return
	var before: Dictionary = node.call("state")
	if before.status == "running": return
	var shape: Dictionary = _tool_geometry() if id == TOOL_ID else Geometry.circle(BANK_POSITIONS[id], 1.05)
	var context: Dictionary = _response_context(id, shape)
	var preview: Dictionary = node.call("preview_start", "hero", context)
	if not preview.get("accepted", false):
		_admission_errors[id] = {"reason": String(preview.get("reason", "preview_rejected"))}
		return
	var proposal: Dictionary = {"status": "running", "phase": "warning", "geometry": shape, "proof": preview.proof}
	if not _proposal_framed(id, proposal):
		_admission_errors[id] = {"reason": "actual_current_or_settled_portrait_rejects_response"}
		return
	_forecasts[id] = {"cycle": int(before.cycle) + 1, "geometry": shape.duplicate(true), "proof": preview.proof.duplicate(true)}
	var answer: Dictionary = node.call("start", "hero", context, null, null, preview) if id == TOOL_ID else node.call("start", "hero", context, null, preview)
	if not _consumer_context_live(id, actor, node, player, scheduler):
		_cancel_consumer(node, "circuit_native_binding_lost_after_start")
		_forecasts.erase(id)
		return
	_admission_errors[id] = {} if answer.get("accepted", false) else {"reason": String(answer.get("reason", "rejected"))}
	if not answer.get("accepted", false):
		_forecasts.erase(id)
		return
	var current: Dictionary = node.call("state")
	var opening: Vector3 = current.opening_position if id == TOOL_ID else current.exchange.opening_position
	if current.status != "running" or current.cycle != int(before.cycle) + 1 or current.reservation_id != answer.reservation_id or current.geometry != answer.reservation.geometry or opening != actor.global_position:
		_cancel_consumer(node, "circuit_cycle_or_opening_lost_after_start")
		_forecasts.erase(id)
		return
	_proofs[id] = answer.proof.duplicate(true)
	_views[id] = {"reservation_id": String(answer.reservation_id), "landing": Codec.vector3(answer.proof.landing), "attack_position": Codec.vector3(answer.proof.attack_position), "target_id": target, "primary_time_s": answer.proof.primary_time_s, "response_complete_s": answer.proof.response_complete_s, "equipment_ids": player.equipment.snapshot()}
	_forecasts.erase(id)
	if not _proposal_framed(id, current): _cancel_consumer(node, "circuit_original_response_view_lost_after_start")


func _cancel_consumer(node: Variant, reason: String) -> void:
	if _node_live(node) and node.call("state").status == "running": node.call("cancel", reason)


func _consumer_context_live(id: String, actor: Variant, node: Variant, player: CinderPlayer, scheduler: CinderThreatScheduler) -> bool:
	if not _live_level() or hero != player or _scheduler != scheduler or player.dead or _consumer(id) != node or _actors.get(_actor_for_consumer(id)) != actor: return false
	if not _node_live(actor) or not _node_live(node) or not actor.is_visible_in_tree() or not node.is_visible_in_tree() or float(actor.get("hp")) <= 0.0: return false
	return id != TOOL_ID or (_checkpoint_requested and not _pending_checkpoint)


func _actor_window(target: String) -> bool:
	var id: String = TOOL_ID if target == "final_handler" else _bank_id(target)
	var actor: Variant = _actors.get(target)
	var node: Variant = _consumer(id)
	var player: CinderPlayer = hero
	var scheduler: CinderThreatScheduler = _scheduler
	var marker: Variant = _opening_cues.get(target)
	if not _consumer_context_live(id, actor, node, player, scheduler) or not _node_live(marker) or not marker.is_visible_in_tree(): return false
	var before: Dictionary = node.call("state")
	if before.status != "running" or before.phase != "recovery": return false
	var lease: Dictionary = scheduler.reservation_state(String(before.reservation_id))
	# The public query can synchronously prune another owner and publish callbacks.
	if not _consumer_context_live(id, actor, node, player, scheduler) or not _node_live(marker) or _opening_cues.get(target) != marker or not marker.is_visible_in_tree(): return false
	var current: Dictionary = node.call("state")
	if current.status != "running" or current.phase != "recovery" or current.cycle != before.cycle or current.reservation_id != before.reservation_id: return false
	if lease.is_empty() or lease.state != "recovery" or int(lease.source_instance_id) != node.get_instance_id() or lease.geometry != current.geometry or lease.opening_position != actor.global_position: return false
	var clock: float = scheduler.get_clock()
	var framed: bool = _tool_cue_current() and _proposal_framed(id, current) if id == TOOL_ID else _bank_framed(id)
	if clock <= float(lease.active_until_s) or clock > float(lease.recovery_until_s) or marker.call("state").state != "available" or not framed: return false
	return _consumer_context_live(id, actor, node, player, scheduler) and _node_live(marker) and marker.is_visible_in_tree() and marker.call("state").state == "available"


func _on_actor_defeated(id: String) -> void:
	if not _entered or _restoring or _validating or _snapshotting or _defeated_ids.has(id) or _pending_defeats.has(id): return
	if not ACTOR_IDS.has(id): runtime_error = "Unknown actual Circuit defeat"; return
	_pending_defeats.append(id)
	_defeat_times[id] = _scenic_clock
	if id == "final_handler": _cancel_consumer(_tool, "actual_final_handler_defeated")
	# Tender defeat stops new starts via actual HP; existing bank tails survive.
	if not _defeat_flush_queued:
		_defeat_flush_queued = true
		_flush_defeats.call_deferred()


func _flush_defeats() -> void:
	_defeat_flush_queued = false
	if not _entered or _restoring or _validating or _snapshotting: return
	for id: String in _pending_defeats:
		if not _node_live(_actors.get(id)) or float(_actors[id].get("hp")) > 0.0: runtime_error = "Circuit defeat lost its actual dead actor"; return
		if not _defeated_ids.has(id): _defeated_ids.append(id)
	_pending_defeats.clear()
	_update_actor_visibility()
	_apply_progress_presentation()
	_update_objective()


func _tenders_cleared() -> bool:
	return _defeated_ids.has("west_tender") and _defeated_ids.has("east_tender") and _pending_defeats.is_empty()


func _all_defeats_committed() -> bool:
	return _defeated_ids.size() == 3 and _pending_defeats.is_empty()


func _all_consumers_quiet() -> bool:
	for id: String in BANK_IDS:
		if not _node_live(_banks.get(id)) or _banks[id].call("state").status == "running": return false
	return _node_live(_tool) and _tool.call("state").status != "running"


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
	return attempt.get("level_id") == "A2-O2" and checkpoint.get("level", {}).get("progress", {}).get("checkpoint_id") == CHECKPOINT_ID and checkpoint.get("level", {}).get("progress", {}).get("checkpoint_kind") == "encounter"


func _flush_progress_requests() -> void:
	if not _live_level(false) or hero.dead: return
	if _pending_checkpoint:
		_pending_checkpoint = false
		if not request_checkpoint(CHECKPOINT_ID): runtime_error = "Cannot request earned Circuit checkpoint"; return
	if _completion_pending:
		_completion_pending = false
		if not request_completion(COMPLETION_ID): runtime_error = "Cannot request earned Circuit completion"


func _hero_contacts(region: Rect2) -> bool:
	return _node_live(hero) and not hero.dead and hero.global_position.y > -0.05 and hero.global_position.y < 0.2 and region.has_point(Vector2(hero.global_position.x, hero.global_position.z))


func _update_actor_visibility() -> void:
	for id: String in ACTOR_IDS:
		var actor: Variant = _actors.get(id)
		if not _node_live(actor): continue
		var running: bool = _consumer(TOOL_ID if id == "final_handler" else _bank_id(id)).call("state").status == "running"
		var admitted_stage: bool = id != "final_handler" or (_checkpoint_requested and not _pending_checkpoint)
		actor.visible = running or float(actor.get("hp")) <= 0.0 or (admitted_stage and hero.global_position.distance_to(actor.global_position) <= 5.1)


func _apply_progress_presentation() -> void:
	var cleared: Array[String] = []
	for id: String in TENDER_IDS:
		if _node_live(_actors.get(id)) and float(_actors[id].get("hp")) <= 0.0: cleared.append(id)
	CircuitKit.set_progress(_kit, cleared, _earned_complete())
	if is_instance_valid(_exit_cue):
		if _earned_complete(): _exit_cue.call("present", "active" if _exit_requested else "available", "contact")
		else: _exit_cue.call("clear")


func _earned_complete() -> bool:
	return _all_defeats_committed() and is_instance_valid(_scheduler) and _scheduler.encounter_profile().is_empty() and not _completion_pending


func _stage() -> String:
	if _earned_complete() or _completion_pending: return "complete"
	if _checkpoint_requested and not _pending_checkpoint: return "handler"
	return "before-final" if _tenders_cleared() else "tenders"


func _update_objective() -> void:
	match _stage():
		"tenders": objective_text = "CLEAR AIR CIRCUIT / TWO TENDERS\nCHOOSE EITHER SOURCE. ATTACK THE LOW RELOAD MOUNT."
		"before-final": objective_text = "LET THE SMOKE FADE\nCROSS THE CHECKPOINT BY CONTACT."
		"handler": objective_text = "FINAL HANDLER\nESCAPE THE LOCKED REACH, THEN STRIKE THE LOW MOUNT."
		_: objective_text = "CLEAR AIR CIRCUIT COMPLETE\nRETURN THROUGH THE PALE CONTACT MARKER."


func _bank_state(id: String) -> Dictionary:
	var state: Dictionary = _banks[id].call("state")
	state["remaining_s"] = 0.0
	if state.status == "running":
		var deadline: String = {"warning": "lock_from_s", "lock": "active_from_s", "active": "active_until_s", "recovery": "recovery_until_s"}[state.phase]
		state.remaining_s = maxf(0.0, float(state.exchange[deadline]) - _scheduler.get_clock())
	state["proof"] = _proofs.get(id, {}).duplicate(true)
	state["presentation_witness"] = _native_view(id)
	return state


func _native_view(id: String) -> Dictionary:
	var view: Dictionary = _views.get(id, {}).duplicate(true)
	for key: String in ["landing", "attack_position"]:
		if view.has(key): view[key] = Codec.read_vector3(view[key])
	return view


func _phase_progress(state: Dictionary) -> float:
	if state.status != "running": return 0.0
	var key: String = {"warning": "windup_s", "lock": "lock_s", "active": "active_s", "recovery": "recovery_s"}.get(state.phase, "")
	if key.is_empty() or state.resolved_role.is_empty(): return 0.0
	var duration: float = float(state.resolved_role[key])
	if state.phase == "warning": duration -= float(state.resolved_role.lock_s)
	return clampf(1.0 - float(state.remaining_s) / maxf(duration, 0.000001), 0.0, 1.0)


func _pose_consumer(id: String, state: Dictionary, pose_actor: bool = true) -> void:
	var target: String = _actor_for_consumer(id)
	var actor: Variant = _actors.get(target)
	var living: bool = _node_live(actor) and float(actor.get("hp")) > 0.0
	var phase: String = String(state.phase) if state.status == "running" else "idle"
	if pose_actor and living: actor.call("present_phase", phase, _phase_progress(state), Vector3.BACK)
	var cue: Variant = _opening_cues.get(target)
	if _node_live(cue):
		if state.status == "running" and state.phase == "recovery" and living and (id != TOOL_ID or (_checkpoint_requested and not _pending_checkpoint)):
			cue.call("present", "available", "attack")
		else: cue.call("clear")
	if id != TOOL_ID and _node_live(_smoke_art.get(id)):
		_smoke_art[id].call("pose", phase if state.status == "running" else "clear", _phase_progress(state))


func _pose_consumers(pose_actors: bool = true) -> void:
	for id: String in BANK_IDS:
		if _node_live(_banks.get(id)): _pose_consumer(id, _bank_state(id), pose_actors)
	if _node_live(_tool): _pose_consumer(TOOL_ID, _tool.call("state"), pose_actors)


func _on_bank_state(_state: Dictionary, id: String) -> void:
	if not _entered or _restoring or _validating or _snapshotting: return
	_remember_bank_cue(id)
	_pose_consumers()
	var current: Dictionary = _banks[id].call("state")
	if current.status != "running":
		_views.erase(id)
		_proofs.erase(id)
		_forecasts.erase(id)
	elif not _bank_framed(id): _cancel_consumer(_banks[id], "circuit_same_callback_bank_view_lost")


func _on_bank_tick(_hero_id: String, _cycle: int, _result: Dictionary, _id: String) -> void:
	if _entered and not _restoring and not _validating and not _snapshotting: _pose_consumers()


func _on_tool_state(state: Dictionary) -> void:
	if not _entered or _restoring or _validating or _snapshotting: return
	_tool_cue_bytes = _native_cue_signature(TOOL_ID)
	_pose_consumers()
	if state.status != "running":
		_views.erase(TOOL_ID)
		_proofs.erase(TOOL_ID)
		_forecasts.erase(TOOL_ID)


func _on_tool_hit(_hero_id: String, _cycle: int, _result: Dictionary) -> void:
	if _entered and not _restoring and not _validating and not _snapshotting: _pose_consumers()


func _guard_banks_before_contact() -> void:
	if not _entered or get_tree().paused or _restoring or _validating or _snapshotting: return
	if not runtime_error.is_empty() or not _node_live(hero) or not _node_live(_scheduler):
		_retire_running_sources("circuit_runtime_bindings_unavailable")
		return
	for id: String in BANK_IDS:
		var bank: Variant = _banks.get(id)
		if not _node_live(bank):
			runtime_error = "Circuit Bank custody lost before contact"
			_retire_running_sources("circuit_bank_custody_lost")
			return
		if bank.call("state").status == "running" and not _bank_framed(id): bank.call("cancel", "circuit_required_presentation_before_contact")


func _retire_running_sources(reason: String) -> void:
	for id: String in BANK_IDS: _cancel_consumer(_banks.get(id), reason)
	_cancel_consumer(_tool, reason)


func _cue_storage_bytes(object: Object) -> PackedByteArray:
	var values: Array = []
	for property: Dictionary in object.get_property_list():
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0: continue
		var value: Variant = object.get(String(property.name))
		values.append([property.name, ["object", value.get_instance_id()] if value is Object else value])
	return var_to_bytes(values)


func _bank_cue_signature(id: String) -> PackedByteArray:
	return _native_cue_signature(id)


func _native_cue_signature(id: String) -> PackedByteArray:
	var bank: Variant = _consumer(id)
	if not _node_live(bank): return PackedByteArray()
	var state: Dictionary = bank.call("state")
	var cue: Variant = bank.call("get_cue")
	if not _frame_visible(cue) or cue.get_parent() != bank: return PackedByteArray()
	var value: Dictionary = cue.call("state")
	if value.phase != state.phase or (state.status == "running" and (value.geometry != state.geometry or value.source_position != bank.global_position or cue.global_transform != Transform3D(Basis.IDENTITY, bank.global_position))): return PackedByteArray()
	var parts: Array = [cue.get_instance_id(), cue.global_transform, value]
	for name: String in ["RequiredFootprintOutline", "RequiredFootprintFill", "RequiredSourceMarker"]:
		var part: MeshInstance3D = cue.get_node_or_null(name) as MeshInstance3D
		if not _node_live(part) or part.get_parent() != cue or part.material_override == null: return PackedByteArray()
		if state.status == "running":
			var expected_visible: bool = name == "RequiredSourceMarker" or (state.phase != "recovery" and (name != "RequiredFootprintFill" or state.phase == "active"))
			if part.visible != expected_visible or (expected_visible and not _frame_visible(part)) or not part.mesh is ArrayMesh: return PackedByteArray()
		parts.append([part.get_instance_id(), part.mesh.get_instance_id() if part.mesh != null else 0, part.material_override.get_instance_id(), _cue_storage_bytes(part), _cue_storage_bytes(part.material_override), part.mesh.get("_surfaces") if part.mesh is ArrayMesh else null])
	return var_to_bytes(parts)


func _remember_bank_cue(id: String) -> void:
	_bank_cue_bytes[id] = _bank_cue_signature(id)


func _bank_framed(id: String) -> bool:
	var signature: PackedByteArray = _bank_cue_signature(id)
	if signature.is_empty() or signature != _bank_cue_bytes.get(id, PackedByteArray()): return false
	return _proposal_framed(id, _banks[id].call("state"))


func _tool_cue_current() -> bool:
	var bytes: PackedByteArray = _native_cue_signature(TOOL_ID)
	return not bytes.is_empty() and bytes == _tool_cue_bytes


func _tool_presentation_guard(id: String, state: Dictionary) -> bool:
	if id != TOOL_ID or not _live_level() or hero.dead or not _checkpoint_is_committed(): return false
	var actor: Variant = _actors.get("final_handler")
	if not _node_live(actor) or not _node_live(_tool) or not actor.is_visible_in_tree() or not _tool.is_visible_in_tree() or float(actor.get("hp")) <= 0.0: return false
	return (state.get("status") != "running" or _tool_cue_current()) and _proposal_framed(id, state)


func _proof_points(proof: Dictionary) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for key: String in ["landing", "attack_position"]:
		if not proof.get(key) is Vector3 or not proof[key].is_finite(): return []
		points.append_array(_landing_points(proof[key]))
	return points


func _required_consumer_points(id: String, proposal: Dictionary = {}) -> Array[Vector3]:
	var node: Variant = _consumer(id)
	var actor: Variant = _actors.get(_actor_for_consumer(id))
	if not _frame_visible(node) or not _frame_visible(actor): return []
	var points: Array[Vector3] = _bounded_mesh_points(actor)
	if points.is_empty(): return []
	points.append_array(_landing_points(actor.global_position))
	var opening_cue: Variant = _opening_cues.get(_actor_for_consumer(id))
	if not _node_live(opening_cue): return []
	if opening_cue.call("state").get("state") != "clear":
		if not _frame_visible(opening_cue): return []
		points.append_array(_bounded_mesh_points(opening_cue))
	var state: Dictionary = node.call("state") if proposal.is_empty() else proposal
	var shape: Dictionary = state.get("geometry", {})
	if shape.is_empty() or not Geometry.error(shape).is_empty(): return []
	if id != TOOL_ID or state.get("phase") != "recovery": points.append_array(_geometry_points(shape))
	if id != TOOL_ID and node.call("state").status == "running": points.append_array(node.call("get_required_camera_points"))
	var proof: Dictionary = state.get("proof", {})
	if proof.is_empty() and _views.has(id): proof = _native_view(id)
	if proof.is_empty() and _forecasts.has(id):
		var native: Dictionary = node.call("state")
		var forecast: Dictionary = _forecasts[id]
		if native.status == "running" and native.cycle == forecast.cycle and native.geometry == forecast.geometry: proof = forecast.proof
	if not proof.is_empty():
		var witness: Array[Vector3] = _proof_points(proof)
		if witness.is_empty(): return []
		points.append_array(witness)
	elif state.get("status") == "running": return []
	return points


func _proposal_framed(id: String, state: Dictionary) -> bool:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(camera): return false
	var points: Array[Vector3] = _required_consumer_points(id, state)
	if points.is_empty(): return false
	points.append_array(_other_running_points(id))
	if not _points_framed(camera, points): return false
	var proof: Dictionary = state.get("proof", {})
	if proof.is_empty(): proof = _native_view(id)
	if proof.is_empty() and _forecasts.has(id): proof = _forecasts[id].proof
	if proof.is_empty(): return false
	for key: String in ["landing", "attack_position"]:
		if not proof.get(key) is Vector3 or not _points_framed(camera, points, _settled_follow_delta(camera, proof[key])): return false
	return true


func _other_running_points(exclude: String = "") -> Array[Vector3]:
	var points: Array[Vector3] = []
	var ids: Array[String] = BANK_IDS.duplicate()
	ids.append(TOOL_ID)
	for id: String in ids:
		if id == exclude: continue
		var node: Variant = _consumer(id)
		if _node_live(node) and node.call("state").status == "running":
			var required: Array[Vector3] = _required_consumer_points(id)
			if required.is_empty(): return [Vector3(INF, INF, INF)]
			points.append_array(required)
	return points


func _response_context(id: String = "", shape: Dictionary = {}) -> Dictionary:
	var escapes: Array[Vector3] = RESPONSE_DIRECTIONS.duplicate()
	var returns: Array[Vector3] = RESPONSE_DIRECTIONS.duplicate()
	if not id.is_empty():
		escapes.clear()
		returns.clear()
		var camera: Camera3D = get_viewport().get_camera_3d()
		var actor: Variant = _actors.get(_actor_for_consumer(id))
		if is_instance_valid(camera) and _node_live(actor) and _node_live(hero):
			var base: Array[Vector3] = _bounded_mesh_points(actor)
			base.append_array(_landing_points(actor.global_position))
			base.append_array(_geometry_points(shape))
			base.append_array(_other_running_points(id))
			var stats: Dictionary = hero.equipment.resolved_stats()
			var distance: float = float(stats.dash_distance)
			for direction: Vector3 in RESPONSE_DIRECTIONS:
				var landing: Vector3 = hero.global_position + direction * distance
				var points: Array[Vector3] = base.duplicate()
				points.append_array(_landing_points(landing))
				if _points_framed(camera, points) and _points_framed(camera, points, _settled_follow_delta(camera, landing)): escapes.append(direction)
			for direction: Vector3 in RESPONSE_DIRECTIONS:
				var reaches: bool = false
				var framed: bool = true
				for escape: Vector3 in escapes:
					var at: Vector3 = hero.global_position + (escape + direction) * distance
					if Vector2(at.x - actor.global_position.x, at.z - actor.global_position.z).length() > float(stats.primary_range) + 0.00001: continue
					reaches = true
					var points: Array[Vector3] = base.duplicate()
					points.append_array(_landing_points(at))
					if not _points_framed(camera, points) or not _points_framed(camera, points, _settled_follow_delta(camera, at)): framed = false
				if reaches and framed: returns.append(direction)
	# Smoke requires exactly collision/safe_rect regions, also valid for Lane.
	return {"encounter_id": ENCOUNTER_ID, "world_revision": WORLD_REVISION, "recognition_s": 0.30, "attack_input_margin_s": 0.10, "escape_directions": escapes, "return_directions": returns, "floor_regions": floor_bindings().values()}


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
	# Original Tender/Handler cosmetic helper accepts <=16; enclose every one
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


func _camera_framing_points() -> Array:
	if not _entered or not runtime_error.is_empty(): return []
	return _current_required_points()


func _current_required_points() -> Array[Vector3]:
	var points: Array[Vector3] = _other_running_points()
	if not _node_live(hero): return points
	# Outboard enemy stores are nonactionable decoration, not required threat
	# or contact targets. Their exact full/empty pixels are reviewed separately.
	var marker: Variant = _kit.get("marker")
	if _frame_visible(marker) and hero.global_position.distance_to(marker.global_position) <= 3.1: points.append_array(_bounded_mesh_points(marker))
	if _frame_visible(_exit_cue) and _earned_complete() and hero.global_position.distance_to(_exit_cue.global_position) <= 3.1: points.append_array(_bounded_mesh_points(_exit_cue))
	return points


func _restore_candidate_presentation_error(camera: Camera3D, framing_hud: GameHUD) -> String:
	if not is_instance_valid(shared_shell) or not shared_shell.has_method("camera_framing_error_for_context"): return "Circuit recipient requires actual shared camera/HUD context"
	var points: Array[Vector3] = _hero_points(camera)
	if points.is_empty(): return "Circuit recipient requires actual full shared Hero bounds"
	points.append_array(_current_required_points())
	return String(shared_shell.call("camera_framing_error_for_context", points, hero, camera, framing_hud))


func _refresh_readability() -> void:
	if not _entered or not _node_live(hero) or not runtime_error.is_empty(): return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(camera): return
	var cosmetic: Array[Vector3] = _hero_cosmetic_points(camera)
	var actual: Array[Vector3] = _hero_points(camera)
	var protected: Array[Vector3] = actual.duplicate()
	protected.append_array(_other_running_points())
	if _earned_complete() and _frame_visible(_exit_cue): protected.append_array(_bounded_mesh_points(_exit_cue))
	for mesh: MeshInstance3D in _scenery_cutaways:
		if not _frame_visible(mesh) or mesh.mesh == null or not mesh.material_override is StandardMaterial3D: continue
		var obscures: bool = false
		for point: Vector3 in protected:
			if _scenery_blocks_point(mesh, camera.global_position, point): obscures = true; break
		var material: StandardMaterial3D = mesh.material_override as StandardMaterial3D
		var alpha: float = 0.12 if obscures else 1.0
		if material.albedo_color.a != alpha:
			var color: Color = material.albedo_color
			color.a = alpha
			material.albedo_color = color
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if obscures else BaseMaterial3D.TRANSPARENCY_DISABLED
	for id: String in ACTOR_IDS:
		var actor: Variant = _actors.get(id)
		if not _node_live(actor): continue
		var rig: Node3D = actor.get_node_or_null("HandlerRig" if id == "final_handler" else "TenderRig") as Node3D
		if _node_live(rig):
			if actor.is_visible_in_tree(): rig.call("apply_readability", camera, cosmetic)
			else: rig.call("clear_readability")
	for id: String in BANK_IDS:
		if not _node_live(_banks.get(id)) or not _node_live(_smoke_art.get(id)): continue
		var cue: Variant = _banks[id].call("get_cue")
		var sources: Array[Vector3] = []
		var boundary: Array[Vector3] = []
		if _node_live(cue):
			var marker: MeshInstance3D = cue.get_node_or_null("RequiredSourceMarker") as MeshInstance3D
			if _node_live(marker) and marker.is_visible_in_tree() and marker.mesh != null:
				for surface: int in range(marker.mesh.get_surface_count()):
					var arrays: Array = marker.mesh.surface_get_arrays(surface)
					for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]: sources.append(marker.global_transform * vertex)
			var value: Dictionary = cue.call("state")
			var outline: MeshInstance3D = cue.get_node_or_null("RequiredFootprintOutline") as MeshInstance3D
			if _node_live(outline) and value.get("geometry", {}).get("kind") == "circle" and outline.transform == Transform3D(Basis.IDENTITY, Vector3.UP * CinderThreatCue.FLOOR_OFFSET):
				for point: Vector3 in CueMesh.boundary(value.geometry): boundary.append(cue.global_transform * (point + Vector3.UP * CinderThreatCue.FLOOR_OFFSET))
		_smoke_art[id].call("apply_readability", camera, actual, sources, boundary)


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



func floor_bindings() -> Dictionary:
	return {"circuit": {"collision": _floor.get("collision"), "safe_rect": _floor.get("safe_rect")}}


func floor_regions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.append({"id": "circuit", "rect": FLOOR_RECT, "body": _floor.get("body"), "collision": _floor.get("collision"), "safe_rect": _floor.get("safe_rect")})
	return result


func _scheduler_bindings() -> Dictionary:
	var owners: Dictionary = _banks.duplicate()
	owners[TOOL_ID] = _tool
	var world: Node = self
	while world != null:
		if world is Node3D and _node_live(hero) and is_instance_valid(_scheduler) and world.is_ancestor_of(hero) and world.is_ancestor_of(_scheduler) and is_instance_valid(_floor.get("body")) and world.is_ancestor_of(_floor.body):
			return {"world_root": world, "owners": owners, "floors": floor_bindings()}
		world = world.get_parent()
	return {"world_root": null, "owners": owners, "floors": floor_bindings()}


func get_actor(id: String) -> Node3D:
	var node: Variant = _actors.get(id)
	return node if _node_live(node) else null


func get_bank(id: String) -> Node3D:
	var node: Variant = _banks.get(id)
	return node if _node_live(node) else null


func get_tool() -> Node3D:
	return _tool if _node_live(_tool) else null


func get_scheduler() -> Node:
	return _scheduler if is_instance_valid(_scheduler) else null


func encounter_state() -> Dictionary:
	var targets: Dictionary = {}
	for id: String in ACTOR_IDS:
		var actor: Variant = _actors.get(id)
		if not _node_live(actor): targets[id] = {"missing": true}; continue
		targets[id] = {"hp": actor.get("hp"), "max_hp": actor.get("max_hp"), "phase": actor.get("phase"), "progress": actor.get("phase_progress"), "direction": actor.get("direction"), "visible": actor.is_visible_in_tree(), "armed": actor.call("is_armed")}
	var banks: Dictionary = {}
	for id: String in BANK_IDS:
		banks[id] = _bank_state(id) if _node_live(_banks.get(id)) else {"missing": true}
	var tool: Dictionary = _tool.call("state") if _node_live(_tool) else {"missing": true}
	tool["proof"] = _proofs.get(TOOL_ID, {}).duplicate(true)
	tool["presentation_witness"] = _native_view(TOOL_ID)
	return {"stage": _stage(), "clock_s": _scheduler.get_clock() if is_instance_valid(_scheduler) else 0.0, "cleared_ids": _defeated_ids.duplicate(), "pending_defeats": _pending_defeats.duplicate(), "checkpoint_requested": _checkpoint_requested, "checkpoint_pending": _pending_checkpoint, "checkpoint_committed": _checkpoint_is_committed(), "exit_open": _earned_complete(), "actors": targets, "banks": banks, "tool": tool, "proofs": _proofs.duplicate(true), "admission_errors": _admission_errors.duplicate(true), "runtime_error": runtime_error}


func _runtime_content_error() -> String:
	if not is_inside_tree() or is_queued_for_deletion() or global_transform != Transform3D.IDENTITY or _actors.size() != 3 or _banks.size() != 2 or _smoke_art.size() != 2 or _opening_cues.size() != 3 or not _node_live(hero) or not _node_live(_scheduler) or not _node_live(_tool) or not _node_live(_exit_cue): return "Circuit requires its original native runtime unit"
	var body: Variant = _floor.get("body")
	var collision: Variant = _floor.get("collision")
	if not _node_live(body) or not body is StaticBody3D or body.get_script() != null or body.get_parent() != self or body.position != Vector3(FLOOR_RECT.get_center().x, -0.25, FLOOR_RECT.get_center().y) or body.basis != Basis.IDENTITY or body.collision_layer != 1 or body.collision_mask != 0:
		return "Circuit original upright dry floor body differs"
	if not _node_live(collision) or not collision is CollisionShape3D or collision.get_script() != null or collision.get_parent() != body or collision.disabled or collision.transform != Transform3D.IDENTITY or not collision.shape is BoxShape3D or collision.shape.size != Vector3(FLOOR_RECT.size.x, 0.5, FLOOR_RECT.size.y) or _floor.get("safe_rect") != FLOOR_RECT.grow(-FLOOR_PROOF_INSET): return "Circuit original native dry support differs"
	if _scheduler.get_script() != Scheduler or _scheduler.get_parent() != self or _scheduler.transform != Transform3D.IDENTITY: return "Circuit original Scheduler custody differs"
	if _tool.get_script() != Lane or _tool.get_parent() != self or _tool.global_position != ACTOR_POSITIONS.final_handler or _tool.global_basis != Basis.IDENTITY: return "Circuit original fixed Lane custody differs"
	if not is_instance_valid(_bank_guard) or _bank_guard.get_script() != BankGuard or _bank_guard.get_parent() != self or not _bank_guard.call("binding_matches", _guard_banks_before_contact): return "Circuit requires the original pre-contact presentation guard"
	if _exit_cue.get_script() != InteractionCue or _exit_cue.get_parent() != self or _exit_cue.position != EXIT_AT or _exit_cue.basis != Basis.IDENTITY: return "Circuit original contact exit cue differs"
	for id: String in ACTOR_IDS:
		var actor: Variant = _actors.get(id)
		var expected: Script = HandlerActor if id == "final_handler" else TenderActor
		var marker: Variant = _opening_cues.get(id)
		if not _node_live(actor) or actor.get_script() != expected or actor.get_parent() != self or actor.global_position != ACTOR_POSITIONS[id] or actor.global_basis != Basis.IDENTITY or String(actor.get("actor_id")) != id or not actor.call("is_armed") or not String(actor.call("damage_window_gate_error", Callable(self, "_actor_window").bind(id))).is_empty(): return "Circuit original actor/gate custody differs: " + id
		if not _node_live(marker) or marker.get_script() != InteractionCue or marker.get_parent() != self or marker.position != ACTOR_POSITIONS[id] or marker.basis != Basis.IDENTITY: return "Circuit actual low opening cue differs: " + id
	for id: String in BANK_IDS:
		var bank: Variant = _banks.get(id)
		var art: Variant = _smoke_art.get(id)
		if not _node_live(bank) or bank.get_script() != Bank or bank.get_parent() != self or bank.global_position != BANK_POSITIONS[id] or bank.global_basis != Basis.IDENTITY or not _node_live(art) or art.get_script() != SmokeVisual or art.get_parent() != self or art.global_position != BANK_POSITIONS[id] or art.global_basis != Basis.IDENTITY: return "Circuit original independent bank/art custody differs: " + id
	if not _node_live(_kit.get("root")) or not is_ancestor_of(_kit.root) or not _kit.get("crates") is Dictionary or not Codec.keys_error(_kit.crates, TENDER_IDS).is_empty() or not _node_live(_kit.get("marker")) or not is_ancestor_of(_kit.marker): return "Circuit requires its actual decorative stores and circuit marker"
	for id: String in TENDER_IDS:
		var prop: Variant = _kit.crates[id]
		var at: Vector3 = Vector3(-3.85 if id == "west_tender" else 3.85, 0, -2.7)
		if not _node_live(prop) or not is_ancestor_of(prop) or prop.global_position != at or prop.global_basis != Basis.IDENTITY: return "Circuit original outboard store differs: " + id
	if _kit.marker.global_position != EXIT_AT or _kit.marker.global_basis != Basis.IDENTITY: return "Circuit original cosmetic marker differs"
	return ""


func _capture_local_state() -> Dictionary:
	if not get_tree().paused or not runtime_error.is_empty() or not _forecasts.is_empty(): return {"error": "Circuit requires a healthy paused native commit barrier"}
	var custody: String = _runtime_content_error()
	if not custody.is_empty(): return {"error": custody}
	var bindings: Dictionary = _scheduler_bindings()
	var actors: Dictionary = {}
	for id: String in ACTOR_IDS: actors[id] = _actors[id].call("snapshot_state")
	var banks: Dictionary = {}
	for id: String in BANK_IDS: banks[id] = _banks[id].call("snapshot_state", bindings)
	return {"scenic_clock": _scenic_clock, "profile_id": _profile_id, "world_revision": WORLD_REVISION, "defeated_ids": _defeated_ids.duplicate(), "defeat_times": _defeat_times.duplicate(), "pending_defeats": _pending_defeats.duplicate(), "checkpoint_contact_seen": _checkpoint_contact_seen, "checkpoint_requested": _checkpoint_requested, "pending_checkpoint": _pending_checkpoint, "completion_pending": _completion_pending, "exit_requested": _exit_requested, "scheduler": _scheduler.snapshot_state(bindings), "actors": actors, "banks": banks, "tool": _tool.call("snapshot_state", bindings), "views": _views.duplicate(true)}


func _local_snapshot_error(state: Dictionary) -> String:
	var player: Dictionary = hero.snapshot_state() if _node_live(hero) else {}
	return _whole_snapshot_error(state, player)


func _local_snapshot_error_with_player(state: Dictionary, saved_player: Dictionary) -> String:
	return _whole_snapshot_error(state, saved_player)


func _whole_snapshot_error(state: Dictionary, player: Dictionary) -> String:
	if not get_tree().paused or not runtime_error.is_empty() or not _forecasts.is_empty(): return "Circuit transport requires the paused native commit barrier"
	var error: String = _runtime_content_error()
	if error.is_empty(): error = Codec.value_error(state)
	if error.is_empty(): error = Codec.keys_error(state, LOCAL_KEYS)
	if not error.is_empty(): return error
	if player.is_empty(): return "Circuit requires the complete saved Player"
	error = hero.snapshot_error(player)
	if not error.is_empty(): return error
	if not Codec.in_range(state.scenic_clock, 0.0, 1000000000.0) or state.profile_id not in ["assisted", "standard", "challenge"] or not Codec.is_integer(state.world_revision, WORLD_REVISION, WORLD_REVISION): return "Circuit saved clock/profile/world differs"
	for key: String in ["checkpoint_contact_seen", "checkpoint_requested", "pending_checkpoint", "completion_pending", "exit_requested"]:
		if not state[key] is bool: return "Circuit progress latches must be Boolean"
	for key: String in ["defeat_times", "scheduler", "actors", "banks", "tool", "views"]:
		if not state[key] is Dictionary: return "Circuit local dictionary missing: " + key
	if not state.defeated_ids is Array or not state.pending_defeats is Array or not Codec.keys_error(state.actors, ACTOR_IDS).is_empty() or not Codec.keys_error(state.banks, BANK_IDS).is_empty(): return "Circuit requires exact actor/bank/history maps"
	var earned: Array[String] = []
	for list: Array in [state.defeated_ids, state.pending_defeats]:
		for id: Variant in list:
			if not id is String or not ACTOR_IDS.has(id) or earned.has(id): return "Circuit actual defeat order must be unique"
			earned.append(id)
	if earned.size() > 3 or not Codec.keys_error(state.defeat_times, earned).is_empty(): return "Circuit defeat times differ from earned/pending identities"
	var time: float = 0.0
	for id: String in earned:
		if not Codec.in_range(state.defeat_times[id], time, float(state.scenic_clock)): return "Circuit earned defeat chronology differs"
		time = float(state.defeat_times[id])
		if id == "final_handler" and (not earned.has("west_tender") or not earned.has("east_tender") or earned.find(id) != 2): return "Circuit Handler defeat must follow both actual Tenders"
	var both: bool = state.defeated_ids.has("west_tender") and state.defeated_ids.has("east_tender")
	if state.checkpoint_contact_seen and not both: return "Circuit contact checkpoint precedes both quiet Tender defeats"
	if state.checkpoint_requested != state.checkpoint_contact_seen or (state.pending_checkpoint and not state.checkpoint_requested): return "Circuit checkpoint intent differs from actual contact"
	var bindings: Dictionary = _scheduler_bindings()
	bindings["hero_positions"] = {"hero": Codec.read_vector3(player.motion.position)}
	error = _scheduler.snapshot_error(state.scheduler, bindings)
	if not error.is_empty(): return error
	var ended: bool = String(state.scheduler.encounter_id).is_empty()
	if int(state.scheduler.world_revision) != WORLD_REVISION: return "Circuit staged Scheduler world differs"
	if ended:
		if earned.size() != 3 or not state.pending_defeats.is_empty() or not state.scheduler.reservations.is_empty() or not state.scheduler.profile.is_empty(): return "Circuit ended encounter requires all actual defeats and no leases"
	elif state.scheduler.encounter_id != ENCOUNTER_ID or state.scheduler.profile.get("id") != state.profile_id: return "Circuit fixed Scheduler encounter/profile differs"
	if (state.completion_pending or state.exit_requested) and not ended: return "Circuit completion/exit precedes quiet ended encounter"
	if state.exit_requested and state.completion_pending: return "Circuit contact exit precedes committed completion"
	for id: String in ACTOR_IDS:
		if not state.actors[id] is Dictionary: return "Circuit actor requires its exact public snapshot"
		error = _actors[id].call("snapshot_error", state.actors[id])
		if not error.is_empty(): return id + ": " + error
		var actor: Dictionary = state.actors[id]
		if actor.root_position != Codec.vector3(ACTOR_POSITIONS[id]) or float(actor.max_hp) != 30.0 or (float(actor.hp) <= 0.0) != earned.has(id) or actor.direction != Codec.vector3(Vector3.BACK) or float(actor.body_yaw) != 0.0: return "Circuit actual actor root/HP/history/direction/yaw differs: " + id
	error = _tool.call("snapshot_error", state.tool, bindings, state.scheduler)
	if not error.is_empty(): return error
	if state.tool.configuration.raw_role != TOOL_ROLE or state.tool.configuration.timing_floors != TOOL_FLOORS: return "Circuit unchanged Handler role/floors differ"
	for id: String in BANK_IDS:
		if not state.banks[id] is Dictionary: return "Circuit Bank requires its full native snapshot"
		error = _banks[id].call("snapshot_error", state.banks[id], bindings, state.scheduler, player)
		if not error.is_empty(): return id + ": " + error
		if state.banks[id].configuration.raw_role != Bank.DEFAULT_RAW_ROLE or state.banks[id].configuration.timing_floors != Bank.DEFAULT_TIMING_FLOORS or state.banks[id].configuration.contact != Bank.DEFAULT_CONTACT: return "Circuit unchanged smoke configuration differs"
	for id: String in BANK_IDS:
		error = _consumer_saved_error(id, state.banks[id], state)
		if not error.is_empty(): return error
	error = _consumer_saved_error(TOOL_ID, state.tool, state)
	if not error.is_empty(): return error
	if (not state.checkpoint_requested or state.pending_checkpoint) and (int(state.tool.cycle) != 0 or float(state.actors.final_handler.hp) != 30.0): return "Circuit final Handler cannot precede the recorded before-final checkpoint"
	if ended and (state.tool.status == "running" or state.banks.west_bank.status == "running" or state.banks.east_bank.status == "running"): return "Circuit clear cannot discard original running tails"
	for id: Variant in state.views:
		if not id is String or id not in ["west_bank", "east_bank", TOOL_ID] or not state.views[id] is Dictionary: return "Circuit view has an unknown source"
		var saved: Dictionary = state.tool if id == TOOL_ID else state.banks[id]
		error = _saved_view_error(id, state.views[id], saved)
		if not error.is_empty(): return error
	return ""


func _consumer_saved_error(id: String, saved: Dictionary, state: Dictionary) -> String:
	if float(saved.clock_s) != float(state.scheduler.clock_s): return "Circuit consumers require one exact paired clock"
	var target: String = _actor_for_consumer(id)
	var actor: Dictionary = state.actors[target]
	var config: Dictionary = saved.configuration
	var geometry: Dictionary = _encode_geometry(_tool_geometry() if id == TOOL_ID else Geometry.circle(BANK_POSITIONS[id], 1.05))
	if config.geometry != geometry or config.opening_position != actor.root_position: return "Circuit authored consumer shape/opening differs: " + id
	if int(saved.cycle) > 0:
		var exchange: Dictionary = saved.exchange
		var source: Array = Codec.vector3(ACTOR_POSITIONS.final_handler if id == TOOL_ID else BANK_POSITIONS[id])
		var epoch: String = String(saved.exchange_encounter_id) if id == TOOL_ID else String(saved.encounter_id)
		if exchange.source_position != source or exchange.opening_position != actor.root_position or exchange.geometry != geometry or exchange.profile_id != state.profile_id or int(exchange.world_revision) != WORLD_REVISION or epoch != ENCOUNTER_ID: return "Circuit executed original source/opening/profile/epoch differs: " + id
	if saved.status == "running" and not state.views.has(id): return "Circuit running source needs its original response witness: " + id
	if state.views.has(id) and saved.status != "running": return "Circuit original witness cannot outlive its running source: " + id
	if id == TOOL_ID and float(actor.hp) <= 0.0 and saved.status == "running": return "Circuit defeated Handler must cancel its reach"
	if float(actor.hp) < 30.0 and int(saved.cycle) < 1: return "Circuit damage requires an actual original consumer cycle: " + target
	if id != TOOL_ID and float(actor.hp) < 30.0 and int(saved.cycle) == 1:
		var crossed: bool = false
		for segment: Dictionary in saved.trace:
			if float(segment.start_s) <= float(saved.exchange.active_until_s) and float(segment.end_s) > float(saved.exchange.active_until_s): crossed = true
		if not crossed: return "Circuit first-cycle Tender damage requires the retained native recovery boundary"
	var phase: String = "defeated" if float(actor.hp) <= 0.0 else (String(saved.phase) if saved.status == "running" else "idle")
	var progress: float = 1.0 if float(actor.hp) <= 0.0 else _saved_progress(saved)
	if actor.phase != phase or float(actor.phase_progress) != progress: return "Circuit actor pose differs from exact consumer clock: " + target
	return ""


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


func _saved_view_error(id: String, view: Dictionary, saved: Dictionary) -> String:
	if saved.status != "running" or not Codec.keys_error(view, VIEW_KEYS).is_empty() or view.target_id != _actor_for_consumer(id) or not view.reservation_id is String or view.reservation_id != saved.exchange.id or not Codec.is_vector3(view.landing) or not Codec.is_vector3(view.attack_position) or not view.equipment_ids is Dictionary or not Codec.in_range(view.primary_time_s, 0.0, 1000000000.0) or not Codec.in_range(view.response_complete_s, float(view.primary_time_s), 1000000000.0): return "Circuit view must preserve the finite original admitted source tuple"
	if float(view.primary_time_s) <= float(saved.exchange.active_until_s) or float(view.response_complete_s) > float(saved.exchange.recovery_until_s): return "Circuit ordinary primary response must fit the original full recovery"
	var equipment: CinderEquipment = AdmissionEquipment.new() as CinderEquipment
	if not equipment.restore(view.equipment_ids): return "Circuit original view requires canonical admitted equipment"
	var stats: Dictionary = equipment.resolved_stats()
	if float(view.response_complete_s) != float(view.primary_time_s) + float(stats.primary_cooldown): return "Circuit original response retains full ordinary primary cadence"
	var landing: Vector3 = Codec.read_vector3(view.landing)
	var attack: Vector3 = Codec.read_vector3(view.attack_position)
	var opening: Vector3 = Codec.read_vector3(saved.exchange.opening_position)
	if not _saved_point_supported(landing) or not _saved_point_supported(attack): return "Circuit original response needs supported dry landing and return"
	if Vector2(attack.x, attack.z).distance_to(Vector2(opening.x, opening.z)) > float(stats.primary_range) - CinderThreatScheduler.SKIN: return "Circuit original ordinary primary cannot reach its low opening"
	var ray := PhysicsRayQueryParameters3D.create(attack + Vector3.UP * CinderPlayer.ATTACK_LOS_HEIGHT, opening + Vector3.UP * CinderPlayer.ATTACK_LOS_HEIGHT, CinderPlayer.ATTACK_SCENERY_MASK)
	if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return "Circuit original ordinary primary sight is obstructed"
	return ""


func _saved_point_supported(point: Vector3) -> bool:
	if not point.is_finite() or point.y < -0.05 or point.y > 0.2: return false
	var safe: Rect2 = (_floor.safe_rect as Rect2).grow(-(CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN))
	return point.x >= safe.position.x - CinderThreatScheduler.EPSILON and point.x <= safe.end.x + CinderThreatScheduler.EPSILON and point.z >= safe.position.y - CinderThreatScheduler.EPSILON and point.z <= safe.end.y + CinderThreatScheduler.EPSILON


func snapshot_state() -> Dictionary:
	var state: Dictionary = super.snapshot_state()
	if not state.is_empty():
		last_snapshot_error = _progress_snapshot_error(state)
		if not last_snapshot_error.is_empty(): return {}
	return state


func snapshot_error(state: Dictionary) -> String:
	var error: String = super.snapshot_error(state)
	return error if not error.is_empty() else _progress_snapshot_error(state)


func snapshot_error_with_player(state: Dictionary, saved_player: Dictionary) -> String:
	var error: String = super.snapshot_error_with_player(state, saved_player)
	return error if not error.is_empty() else _progress_snapshot_error(state)


func restore_state(state: Dictionary) -> bool:
	var player: Dictionary = hero.snapshot_state() if _node_live(hero) else {}
	last_snapshot_error = "Circuit restore requires the actual restored paused Player" if player.is_empty() else snapshot_error_with_player(state, player)
	if not last_snapshot_error.is_empty(): return false
	var accepted: bool = super.restore_state(state)
	if accepted and not runtime_error.is_empty(): last_snapshot_error = runtime_error; return false
	return accepted


func _progress_snapshot_error(outer: Dictionary) -> String:
	var local: Dictionary = outer.local
	var progress: Dictionary = outer.progress
	var ended: bool = String(local.scheduler.encounter_id).is_empty()
	var complete: bool = ended and not local.completion_pending
	if progress.completed != complete or progress.completion_id != (COMPLETION_ID if complete else "") or progress.contact_exit_id != (EXIT_ID if local.exit_requested else ""): return "Circuit completion/contact progress differs from its exact earned objective"
	var expected: Dictionary = {}
	if local.checkpoint_requested and not local.pending_checkpoint: expected[CHECKPOINT_ID] = "encounter"
	if progress.checkpoint_ids != expected or progress.checkpoint_id != (CHECKPOINT_ID if not expected.is_empty() else "") or progress.checkpoint_kind != ("encounter" if not expected.is_empty() else ""): return "Circuit protected before-final checkpoint history differs"
	return ""


func _restore_local_state(state: Dictionary) -> void:
	# Whole preflight has validated complete Player; Shell commits it first.
	# Keep authored source positions fixed and do not relatch/repose actor yaw.
	var bindings: Dictionary = _scheduler_bindings()
	for id: String in ACTOR_IDS:
		if not _actors[id].call("restore_state", state.actors[id]): runtime_error = "Unexpected Circuit actor commit refusal: " + id; return
	if not _scheduler.restore_state(state.scheduler, bindings): runtime_error = "Unexpected Circuit Scheduler commit refusal"; return
	for id: String in BANK_IDS:
		if not _banks[id].call("restore_state", state.banks[id], bindings): runtime_error = "Unexpected Circuit Bank commit refusal: " + id; return
	if not _tool.call("restore_state", state.tool, bindings): runtime_error = "Unexpected Circuit Lane commit refusal"; return
	_scenic_clock = float(state.scenic_clock)
	_profile_id = state.profile_id
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
	for id: String in BANK_IDS: _remember_bank_cue(id)
	_tool_cue_bytes = _native_cue_signature(TOOL_ID)
	_update_actor_visibility()
	var blocked: Dictionary = {}
	for id: String in ACTOR_IDS:
		blocked[id] = _opening_cues[id].is_blocking_signals()
		_opening_cues[id].set_block_signals(true)
	var exit_blocked: bool = _exit_cue.is_blocking_signals()
	_exit_cue.set_block_signals(true)
	_pose_consumers(false)
	_apply_progress_presentation()
	for id: String in ACTOR_IDS: _opening_cues[id].set_block_signals(blocked[id])
	_exit_cue.set_block_signals(exit_blocked)
	_update_objective()
	_refresh_readability()


func _on_hero_died() -> void:
	if not _entered or _restoring or _validating or _snapshotting: return
	for id: String in BANK_IDS: _cancel_consumer(_banks.get(id), "hero_defeated")
	_cancel_consumer(_tool, "hero_defeated")
	_views.clear()
	_proofs.clear()
	_forecasts.clear()
	_pose_consumers()


func _on_exit_level() -> void:
	set_physics_process(false)
	if is_instance_valid(_bank_guard): _bank_guard.set_physics_process(false)
	if RenderingServer.frame_pre_draw.is_connected(_refresh_readability): RenderingServer.frame_pre_draw.disconnect(_refresh_readability)
	if is_instance_valid(hero) and hero.died.is_connected(_on_hero_died): hero.died.disconnect(_on_hero_died)
	for id: String in BANK_IDS:
		var bank: Variant = _banks.get(id)
		if is_instance_valid(bank):
			if bank.is_connected("state_changed", Callable(self, "_on_bank_state").bind(id)): bank.disconnect("state_changed", Callable(self, "_on_bank_state").bind(id))
			if bank.is_connected("tick_resolved", Callable(self, "_on_bank_tick").bind(id)): bank.disconnect("tick_resolved", Callable(self, "_on_bank_tick").bind(id))
			bank.call("cancel", "circuit_level_exit")
	if is_instance_valid(_tool):
		if _tool.is_connected("state_changed", _on_tool_state): _tool.disconnect("state_changed", _on_tool_state)
		if _tool.is_connected("hit_resolved", _on_tool_hit): _tool.disconnect("hit_resolved", _on_tool_hit)
		_tool.call("clear", "circuit_level_exit")
	if is_instance_valid(_scheduler): _scheduler.end_encounter("circuit_level_exit")
	for id: String in ACTOR_IDS:
		var actor: Variant = _actors.get(id)
		if is_instance_valid(actor):
			if actor.is_connected("defeated", _on_actor_defeated): actor.disconnect("defeated", _on_actor_defeated)
			actor.call("release_damage_window", Callable(self, "_actor_window").bind(id))
			actor.call("cleanup")
		var cue: Variant = _opening_cues.get(id)
		if is_instance_valid(cue): cue.call("clear")
	if is_instance_valid(_exit_cue): _exit_cue.call("clear")
	_views.clear()
	_proofs.clear()
	_forecasts.clear()
	_bank_cue_bytes.clear()
	_tool_cue_bytes = PackedByteArray()
	_scenery_cutaways.clear()
