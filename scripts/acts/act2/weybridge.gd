extends "res://scripts/acts/act2/horsell_common.gd"
## L2 reuses the frozen owned Scout adapter and geometry/readability helpers.
## All L2 authored order, ground, actor mixture and local aggregate live here.
## One shared player/scheduler/camera/HUD/cue/input/persistence; no gear rewards.
const WeybridgeKit: Script = preload("res://scripts/acts/act2/weybridge_kit.gd")
const HandlerActor: Script = preload("res://scripts/acts/act2/salvage_handler_actor.gd")
const CrossingSequence: Script = preload("res://scripts/acts/act2/weybridge_sequence.gd")
const Mechanism: Script = preload("res://scripts/combat/lane_mechanism.gd")
const FootVisual: Script = preload("res://scripts/acts/act2/giant_foot_visual.gd")
const ExactJson: Script = preload("res://scripts/campaign/exact_json.gd")
const CROSSING_EPOCH: String = "A2-L2-weybridge"
const SHELTER_EXIT: Rect2 = Rect2(-2.7, -38.8, 5.4, 1.3)
const CROSSING_FLOORS: Array[Dictionary] = [
	{"id": "village", "rect": Rect2(-3.4, -8.8, 6.8, 12.4)},
	{"id": "lock_apron", "rect": Rect2(-3.4, -18.8, 6.8, 11.0)},
	{"id": "grounded_crossing", "rect": Rect2(-3.4, -30.0, 6.8, 12.2)},
	{"id": "shelter_courtyard", "rect": Rect2(-3.4, -39.0, 6.8, 10.0)},
]
const TOOL_ROLE: Dictionary = {"raw_damage": 10.0, "windup_s": 2.2, "lock_s": 1.1, "active_s": 0.2, "recovery_s": 1.9, "attack_interval_s": 1.9, "max_hp": 30.0, "move_speed": 0.0}
const TOOL_FLOORS: Dictionary = {"windup_s": 2.2, "lock_s": 1.1, "recovery_s": 1.9}
const CROSSING_LOCAL_KEYS: Array[String] = ["sequence", "scheduler", "rays", "handlers", "mechanisms", "views", "profile_id", "scenic_clock", "witness_started_s", "collapse_started_s", "last_action_sequence", "contact_seen", "pending_checkpoints", "completion_pending", "exit_requested"]
var _crossing: RefCounted = CrossingSequence.new()
var _ray_actors: Dictionary = {}
var _mechanisms: Dictionary = {}
var _views: Dictionary = {}
## Transient defensive observation of the actual shared response; never saved
## or accepted as authority. A fresh restored cycle can wait for its real end.
var _mechanism_proofs: Dictionary = {}
var _opening_cues: Dictionary = {}
var _foot_visual: Node3D
var _contact_seen: String = ""
var _collapse_started_s: float = 0.0

func _ready() -> void:
	_art_preview = false
	process_physics_priority = 110
	_build_ground()
	_kit = WeybridgeKit.build(self)
	_foot_visual = FootVisual.new() as Node3D
	_foot_visual.name = "OneVisibleGiantFoot"
	add_child(_foot_visual)
	_foot_visual.visible = false
	set_physics_process(false)

func _on_enter_level() -> void:
	if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference"):
		_profile_id = shared_shell.call("get_difficulty_preference")
	_scheduler = Scheduler.new()
	_scheduler.name = "WeybridgeThreatScheduler"
	add_child(_scheduler)
	if not _scheduler.call("begin_encounter", _profile_id, CROSSING_EPOCH, WORLD_REVISION):
		runtime_error = _scheduler.get("last_error")
		return
	for id: String in CrossingSequence.ACTORS:
		var is_handler: bool = CrossingSequence.HANDLERS.has(id)
		var actor: Node3D = (HandlerActor.new() if is_handler else ScoutActor.new()) as Node3D
		actor.name = ("Handler_" if is_handler else "Scout_") + id
		actor.position = CrossingSequence.ACTORS[id]
		add_child(actor)
		if not actor.call("configure", hero, effects, id):
			runtime_error = "Cannot bind L2 actor " + id
			return
		_actors[id] = actor
		if not is_handler:
			_ray_actors[id] = actor
		else:
			var mechanism: Node3D = _new_mechanism("tool_" + id, actor.position, Geometry.lane(actor.position, actor.position + Vector3.BACK * 3.8, 0.31), actor.position, TOOL_ROLE, TOOL_FLOORS)
			if mechanism == null or not actor.call("bind_damage_window", Callable(self, "_handler_window").bind(id)):
				runtime_error = "Cannot bind L2 tool and ordinary attack gate " + id
				return
			actor.connect("defeated", _on_scout_defeated)
			var opening: Node3D = InteractionCue.new() as Node3D
			opening.name = "LowToolOpening_" + id
			opening.position = actor.position
			add_child(opening)
			opening.call("clear")
			_opening_cues[id] = opening
	_exchange = Exchange.new() as Node3D
	_exchange.name = "ReusedRayExchanges"
	add_child(_exchange)
	if not _exchange.call("configure", hero, effects, _scheduler, _ray_actors, _profile_id, _response_context()):
		runtime_error = _exchange.get("last_error")
		return
	_exchange.call("set_response_context_provider", _response_context)
	_exchange.call("set_presentation_guard", _presentation_guard)
	_exchange.connect("scout_defeated", _on_scout_defeated)
	_exchange.connect("state_changed", _on_ray_state)
	for id: String in CrossingSequence.FEET:
		var at: Vector3 = CrossingSequence.FEET[id]
		if _new_mechanism(id, at, Geometry.circle(at, 1.10), at + Vector3(1.55 if at.x <= 0.0 else -1.55, 0, 0)) == null:
			return
	_exit_cue = InteractionCue.new() as Node3D
	_exit_cue.name = "ShelterContactExit"
	_exit_cue.position = Vector3(0, 0, SHELTER_EXIT.get_center().y)
	add_child(_exit_cue)
	_exit_cue.call("clear")
	hero.world_action_executed.connect(_on_world_action)
	_update_actor_visibility()
	_update_objective()
	_apply_tableau()
	set_physics_process(true)

func _new_mechanism(id: String, at: Vector3, shape: Dictionary, opening: Vector3, role: Dictionary = Mechanism.DEFAULT_RAW_ROLE, floors: Dictionary = Mechanism.DEFAULT_TIMING_FLOORS) -> Node3D:
	var node: Node3D = Mechanism.new() as Node3D
	node.name = id
	node.position = at
	add_child(node)
	if not node.call("configure", id, shape, opening, role, floors) or not node.call("bind", _scheduler, {"hero": hero}):
		runtime_error = "Cannot bind L2 mechanism %s: %s" % [id, node.get("last_error")]
		return null
	node.connect("state_changed", Callable(self, "_on_mechanism_state").bind(id))
	_mechanisms[id] = node
	return node

func _physics_process(delta: float) -> void:
	if not _entered or get_tree().paused or not is_instance_valid(hero) or hero.dead or not runtime_error.is_empty():
		return
	_scenic_clock += delta
	_flush_progress_requests()
	if get_tree().paused: return
	_apply_tableau()
	_update_actor_visibility()
	_apply_readability()
	_update_mechanism_poses()
	var beat: String = _crossing.call("current_beat")
	if _crossing.call("exit_is_open"):
		if is_completed() and not _exit_requested and _hero_contacts(SHELTER_EXIT):
			_exit_requested = true
			_exit_cue.call("present", "active", "contact")
			request_contact_exit("weybridge-shelter", hero)
		return
	if CrossingSequence.CONTACTS.has(beat):
		var region: Rect2 = CrossingSequence.CONTACTS[beat].region
		if _hero_contacts(region): _contact_seen = beat
		var response: Dictionary = hero.get_threat_response_state()
		if _contact_seen == beat and response.get("stable", false) and float(response.get("commitment_remaining_s", 1.0)) <= 0.00001:
			if not _crossing.call("commit_contact", beat):
				runtime_error = "Invalid earned L2 contact " + beat
				return
			_contact_seen = ""
			_pending_checkpoints.append(CrossingSequence.CONTACTS[beat].checkpoint)
			_flush_progress_requests()
			_update_actor_visibility()
			_update_objective()
		return
	for id: String in _crossing.call("current_active_ids"):
		var actor: Node3D = _actors[id]
		if _ray_actors.has(id):
			var state: Dictionary = _exchange.call("state", id)
			if state.get("status") == "running":
				if not _exchange_framed(actor, state): _exchange.call("cancel", id, "l2_required_presentation_unavailable")
				continue
			if hero.global_position.distance_to(actor.global_position) > 3.8: continue
			var bearing: Vector3 = hero.global_position - actor.global_position
			bearing.y = 0.0
			if bearing.length_squared() < 0.000001: bearing = Vector3.BACK
			var shape: Dictionary = Geometry.lane(actor.global_position, actor.global_position + bearing.normalized() * 3.8, 0.31)
			if _exchange_framed(actor, {"geometry": shape}):
				var answer: Dictionary = _exchange.call("activate", id)
				_admission_errors[id] = {} if answer.get("accepted", false) else {"reason": answer.get("reason", "rejected")}
		else:
			_activate_mechanism("tool_" + id, id)
	var foot: String = _crossing.call("current_foot_id")
	if not foot.is_empty():
		var foot_state: Dictionary = _mechanisms[foot].call("state")
		if foot_state.status == "complete":
			if not _crossing.call("commit_foot", foot):
				runtime_error = "Invalid actual completed footfall " + foot
				return
			_views.erase(foot)
			_update_actor_visibility()
			_update_objective()
		else:
			_activate_mechanism(foot, "")

func _activate_mechanism(id: String, target_id: String) -> void:
	var node: Node3D = _mechanisms[id]
	var state: Dictionary = node.call("state")
	if state.status == "running":
		if not _paired_view_valid(id):
			node.call("cancel", "paired_real_opening_lost")
			return
		if not _mechanism_framed(id, state): node.call("cancel", "l2_required_presentation_unavailable")
		return
	if hero.global_position.distance_to(node.global_position) > 3.8: return
	if not _mechanism_framed(id, state): return
	var opening: Variant = null
	var counterpart: String = ""
	if id == "foot_apron" and float(_actors.apron_handler.get("hp")) > 0.0:
		counterpart = "apron_handler"
	elif id in ["foot_left", "foot_right"] and float(_actors.crossing_scout.get("hp")) > 0.0:
		counterpart = "crossing_scout"
	var other_reservation: Dictionary = {}
	if not counterpart.is_empty():
		var other: Dictionary = _actor_exchange(counterpart)
		if other.get("status") != "running": return
		other_reservation = _scheduler.call("reservation_state", other.get("reservation_id", ""))
		# A tracking Scout pays its actual full lock/reproof first. Its tentative
		# warning is not the actual stationary ordinary-primary recovery promise.
		if other_reservation.is_empty() or not other_reservation.get("armed", false): return
		opening = _actors[counterpart].global_position
	var shape: Dictionary = state.geometry
	var context: Dictionary = _response_context_for(id, shape, opening if opening is Vector3 else state.opening_position)
	var answer: Dictionary = node.call("start", "hero", context, opening)
	_admission_errors[id] = {} if answer.get("accepted", false) else {"reason": answer.get("reason", "rejected")}
	if not answer.get("accepted", false): return
	if not counterpart.is_empty() and (float(answer.proof.primary_time_s) <= float(other_reservation.active_until_s) or float(answer.proof.response_complete_s) > float(other_reservation.recovery_until_s)):
		node.call("cancel", "paired_real_target_recovery_does_not_cover_response")
		_admission_errors[id] = {"reason": "paired_real_target_recovery_does_not_cover_response"}
		return
	_mechanism_proofs[id] = answer.proof.duplicate(true)
	_views[id] = {"reservation_id": answer.reservation_id, "landing": Codec.vector3(answer.proof.landing), "attack_position": Codec.vector3(answer.proof.attack_position), "target_id": counterpart, "primary_time_s": answer.proof.primary_time_s, "response_complete_s": answer.proof.response_complete_s}

func _actor_exchange(id: String) -> Dictionary:
	if _ray_actors.has(id): return _exchange.call("state", id)
	var state: Dictionary = _mechanisms["tool_" + id].call("state")
	state["proof"] = mechanism_proof("tool_" + id)
	return state

func mechanism_proof(id: String) -> Dictionary:
	if not _mechanisms.has(id) or not _mechanism_proofs.has(id) or _mechanisms[id].call("state").status != "running": return {}
	return _mechanism_proofs[id].duplicate(true)

func _handler_window(id: String) -> bool:
	if get_tree().paused or hero.dead or not _crossing.call("current_active_ids").has(id) or not _actors[id].is_visible_in_tree(): return false
	var node: Node3D = _mechanisms["tool_" + id]
	var state: Dictionary = node.call("state")
	if state.status != "running" or state.phase != "recovery" or not _mechanism_framed("tool_" + id, state): return false
	var marker: Node3D = _opening_cues[id]
	if not marker.is_visible_in_tree() or marker.call("state").state not in ["available", "active"]: return false
	var reservation: Dictionary = _scheduler.call("reservation_state", state.reservation_id)
	return not get_tree().paused and not reservation.is_empty() and reservation.state == "recovery" and _scheduler.call("get_clock") > float(reservation.active_until_s) and _scheduler.call("get_clock") <= float(reservation.recovery_until_s)

func _paired_view_valid(id: String) -> bool:
	if not _views.has(id) or _views[id].target_id.is_empty(): return true
	var target: String = _views[id].target_id
	var paired: Dictionary = _actor_exchange(target)
	var retained: Dictionary = _scheduler.call("reservation_state", paired.get("reservation_id", ""))
	return float(_actors[target].get("hp")) > 0.0 and paired.get("status") == "running" and not retained.is_empty() and retained.get("armed", false) and retained.opening_position == _actors[target].global_position and float(_views[id].primary_time_s) > float(retained.active_until_s) and float(_views[id].response_complete_s) <= float(retained.recovery_until_s)

func _on_ray_state(actor_id: String, _state: Dictionary) -> void:
	if not _entered or _restoring or _validating or _snapshotting: return
	_cancel_invalid_coupled(actor_id)

func _cancel_invalid_coupled(target_id: String) -> void:
	for id: String in _views.keys():
		if _views[id].target_id == target_id and not _paired_view_valid(id):
			_mechanisms[id].call("cancel", "paired_real_opening_lost")

func _on_mechanism_state(state: Dictionary, id: String) -> void:
	if not _entered or _restoring or _validating or _snapshotting: return
	_pose_mechanism(id, state)
	if id.begins_with("tool_"): _cancel_invalid_coupled(id.substr(5))
	if state.status != "running":
		_views.erase(id)
		_mechanism_proofs.erase(id)
	elif not _paired_view_valid(id):
		_mechanisms[id].call("cancel", "paired_real_opening_lost")
	elif not _mechanism_framed(id, state):
		_mechanisms[id].call("cancel", "l2_same_callback_presentation_unavailable")

func _phase_progress(state: Dictionary) -> float:
	var key: String = {"warning": "windup_s", "lock": "lock_s", "active": "active_s", "recovery": "recovery_s"}.get(state.phase, "")
	if key.is_empty() or state.resolved_role.is_empty(): return 0.0
	var duration: float = float(state.resolved_role[key])
	if state.phase == "warning": duration -= float(state.resolved_role.lock_s)
	return clampf(1.0 - float(state.remaining_s) / maxf(duration, 0.000001), 0.0, 1.0)

func _pose_mechanism(id: String, state: Dictionary) -> void:
	var phase: String = state.phase if state.phase != "clear" else "idle"
	if id.begins_with("tool_"):
		var actor_id: String = id.substr(5)
		var actor: Node3D = _actors.get(actor_id)
		if is_instance_valid(actor) and float(actor.get("hp")) > 0.0:
			actor.call("present_phase", phase, _phase_progress(state), Vector3.BACK)
		var marker: Node3D = _opening_cues.get(actor_id)
		if is_instance_valid(marker):
			if state.status == "running" and phase == "recovery" and float(actor.get("hp")) > 0.0:
				marker.call("present", "available", "attack")
			else: marker.call("clear")
	elif id == _crossing.call("current_foot_id"):
		_foot_visual.position = CrossingSequence.FEET[id]
		_foot_visual.call("pose", phase, _phase_progress(state), Vector3.BACK)

func _update_mechanism_poses() -> void:
	for id: String in _mechanisms:
		_pose_mechanism(id, _mechanisms[id].call("state"))

func _on_scout_defeated(id: String) -> void:
	if not _pending_defeats.has(id): _pending_defeats.append(id)
	if not _defeat_flush_queued:
		_defeat_flush_queued = true
		_flush_defeats.call_deferred()

func _flush_defeats() -> void:
	_defeat_flush_queued = false
	if not _entered or _restoring or _validating or _snapshotting: return
	var ids: Array[String] = _pending_defeats.duplicate()
	_pending_defeats.clear()
	for id: String in ids:
		if not _crossing.call("commit_defeat", id):
			runtime_error = "Invalid L2 actual defeat " + id
			return
		if _mechanisms.has("tool_" + id):
			_mechanisms["tool_" + id].call("cancel", "real_handler_defeated")
			_actors[id].call("present_phase", "defeated", 1.0, Vector3.BACK)
		for mechanism_id: String in _views.keys():
			if _views[mechanism_id].target_id == id:
				_mechanisms[mechanism_id].call("cancel", "paired_real_opening_defeated")
		if id == "village_scout": _witness_started_s = _scenic_clock
	_update_actor_visibility()
	_update_objective()
	if _crossing.call("exit_is_open"):
		_collapse_started_s = _scenic_clock
		_completion_pending = true
		_exchange.call("cancel_all", "weybridge_clear")
		for mechanism: Node3D in _mechanisms.values(): mechanism.call("clear", "weybridge_clear")
		_scheduler.call("end_encounter", "weybridge_clear")
		_exit_cue.call("present", "available", "contact")
	_flush_progress_requests()

func _flush_progress_requests() -> void:
	if hero.dead or not _entered or _restoring or _validating or _snapshotting: return
	while not _pending_checkpoints.is_empty():
		var id: String = _pending_checkpoints.pop_front()
		if not request_checkpoint(id):
			runtime_error = "Cannot request earned L2 checkpoint " + id
			return
	if _completion_pending:
		_completion_pending = false
		if not request_completion("weybridge-crossing-clear"): runtime_error = "Cannot complete earned L2 crossing"

func _on_world_action(record: Dictionary) -> void:
	if not _entered or _restoring or _validating or _snapshotting or int(record.get("sequence", 0)) <= _last_action_sequence: return
	_last_action_sequence = int(record.sequence)
	var beat: String = _crossing.call("current_beat")
	if record.kind == "dash" and record.get("landing") is Vector3 and CrossingSequence.CONTACTS.has(beat):
		var region: Rect2 = CrossingSequence.CONTACTS[beat].region
		var path: Array = record.get("path", [])
		for index: int in range(1, path.size()):
			var a: Vector3 = path[index - 1].position
			var b: Vector3 = path[index].position
			if _segment_contacts(Vector2(a.x, a.z), Vector2(b.x, b.z), region):
				_contact_seen = beat

func _segment_contacts(a: Vector2, b: Vector2, region: Rect2) -> bool:
	if region.has_point(a) or region.has_point(b): return true
	var corners: Array[Vector2] = [region.position, region.position + Vector2(region.size.x, 0), region.end, region.position + Vector2(0, region.size.y)]
	for index: int in range(4):
		if Geometry2D.segment_intersects_segment(a, b, corners[index], corners[(index + 1) % 4]) != null: return true
	return false

func _update_actor_visibility() -> void:
	var alive: Array = _crossing.call("current_active_ids")
	var defeated: Array = _crossing.get("defeated_ids")
	for id: String in _actors: _actors[id].visible = alive.has(id) or defeated.has(id)
	var foot: String = _crossing.call("current_foot_id")
	_foot_visual.visible = not foot.is_empty()
	if not foot.is_empty(): _foot_visual.position = CrossingSequence.FEET[foot]
	for id: String in _mechanisms:
		_mechanisms[id].visible = (id == foot) or (id.begins_with("tool_") and alive.has(id.substr(5)))

func _update_objective() -> void:
	match _crossing.call("current_beat"):
		"village": objective_text = "WEYBRIDGE / FOLLOW THE VILLAGE
LET THE MIRROR LOCK. STRIKE ITS HOUSING."
		"yard": objective_text = "CLEAR THE OPEN YARD
DASH ROUND THE ARM. STRIKE THE LOW MOUNT."
		"yard_exit": objective_text = "REACH THE LOCK APPROACH
CROSS THE DRY YARD EXIT."
		"foot_demo": objective_text = "READ THE VISIBLE FOOT
LET THE PATCH LOCK. LAND ON DRY GROUND."
		"apron_pair": objective_text = "CROSS THE LOCK APRON
KEEP A LANDING THROUGH THE ARM AND FOOT."
		"before_crossing": objective_text = "THE BRIDGE APPROACH IS OPEN
CROSS THE BROAD DRY APRON."
		"crossing_left", "crossing_right": objective_text = "CROSS BETWEEN THE TWO POCKETS
BAIT ONE THREAT. KEEP THE OTHER IN VIEW."
		"far_apron": objective_text = "REACH THE FAR APRON
THE WATER REMAINS OUTSIDE THE ROAD."
		"before_shelter": objective_text = "REACH THE SHELTER COURTYARD
KEEP AN EXIT FOR THE LAST PAIR."
		"shelter_pair": objective_text = "CLEAR THE SHELTER APPROACH
STRIKE THE RECOVERING HOUSING OR TOOL."
		"clear": objective_text = "SHELTER IS OPEN
LEAVE THROUGH THE PALE DOORWAY MARKER."

func _apply_tableau() -> void:
	var stage: int = int(_crossing.get("stage_index"))
	WeybridgeKit.set_tableau(_kit, "arrival" if stage == 0 else ("retreat" if stage < 3 else "absent"), clampf((_scenic_clock - _witness_started_s) / 1.6, 0.0, 1.0))
	WeybridgeKit.set_collapse(_kit, stage == 11, clampf((_scenic_clock - _collapse_started_s) / 2.0, 0.0, 1.0))

func _build_ground() -> void:
	var floor_root := Node3D.new()
	floor_root.name = "DryGround"
	add_child(floor_root)
	for spec: Dictionary in CROSSING_FLOORS:
		var rect: Rect2 = spec.rect
		var body := StaticBody3D.new()
		body.name = spec.id
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = Vector3(0, -0.25, rect.get_center().y)
		floor_root.add_child(body)
		var shape := BoxShape3D.new()
		shape.size = Vector3(rect.size.x, 0.5, rect.size.y)
		var collision := CollisionShape3D.new()
		collision.name = "DrySupport"
		collision.shape = shape
		body.add_child(collision)
		_floors.append({"id": spec.id, "rect": rect, "body": body, "collision": collision, "safe_rect": rect.grow(-FLOOR_PROOF_INSET)})
	_build_bank("VillageEnd", Vector3(0, 0.25, 3.9), Vector3(7.8, 0.6, 0.6), floor_root)
	_build_bank("ShelterEnd", Vector3(0, 0.25, -39.3), Vector3(7.8, 0.6, 0.6), floor_root)
	for side: float in [-1.0, 1.0]:
		_build_bank("QuayWest" if side < 0.0 else "QuayEast", Vector3(side * 3.65, 0.25, -17.7), Vector3(0.5, 0.6, 42.6), floor_root)

func _required_source_points(actor: Node3D) -> Array[Vector3]:
	var handler: Node = actor.get_node_or_null("HandlerRig")
	if handler == null: return super._required_source_points(actor)
	var points: Array[Vector3] = []
	_append_mesh_points(handler, points)
	points.append_array(_landing_points(actor.global_position))
	return points

func _source_points(id: String) -> Array[Vector3]:
	if _actors.has(id): return _required_source_points(_actors[id])
	if id.begins_with("tool_"): return _required_source_points(_actors[id.substr(5)])
	var points: Array[Vector3] = []
	if id == _crossing.call("current_foot_id"):
		_append_mesh_points(_foot_visual, points)
	return points

func _lane_points(shape: Dictionary) -> Array[Vector3]:
	if shape.get("kind") != "circle": return super._lane_points(shape)
	var points: Array[Vector3] = []
	for x: float in [-float(shape.radius), float(shape.radius)]:
		for z: float in [-float(shape.radius), float(shape.radius)]: points.append(shape.origin + Vector3(x, 0.03, z))
	return points

func _response_context(actor_id: String = "", shape: Dictionary = {}) -> Dictionary:
	return _response_context_for(actor_id, shape, _actors[actor_id].global_position if _actors.has(actor_id) else Vector3.ZERO)

func _response_context_for(id: String, shape: Dictionary, opening: Vector3) -> Dictionary:
	var escapes: Array[Vector3] = RESPONSE_DIRECTIONS.duplicate()
	var returns: Array[Vector3] = RESPONSE_DIRECTIONS.duplicate()
	if not id.is_empty():
		escapes.clear()
		returns.clear()
		var camera: Camera3D = get_viewport().get_camera_3d()
		if is_instance_valid(camera):
			var required: Array[Vector3] = _source_points(id)
			required.append_array(_lane_points(shape))
			for other_id: String in _mechanisms:
				var other: Dictionary = _mechanisms[other_id].call("state")
				if other_id != id and other.status == "running":
					required.append_array(_source_points(other_id))
					if other.phase != "recovery": required.append_array(_lane_points(other.geometry))
			for other_id: String in _ray_actors:
				var other: Dictionary = _exchange.call("state", other_id) if is_instance_valid(_exchange) else {}
				if other_id != id and other.get("status") == "running":
					required.append_array(_source_points(other_id))
					if other.phase != "recovery": required.append_array(_lane_points(_state_geometry(other)))
			var distance: float = float(hero.stats.dash_distance)
			for direction: Vector3 in RESPONSE_DIRECTIONS:
				var landing: Vector3 = hero.global_position + direction * distance
				var points: Array[Vector3] = required.duplicate()
				points.append_array(_landing_points(landing))
				if _points_framed(camera, points) and _points_framed(camera, points, _settled_follow_delta(camera, landing)): escapes.append(direction)
			for returning: Vector3 in RESPONSE_DIRECTIONS:
				var reaches: bool = false
				var framed: bool = true
				for escaping: Vector3 in escapes:
					var at: Vector3 = hero.global_position + (escaping + returning) * distance
					if Vector2(at.x - opening.x, at.z - opening.z).length() > float(hero.stats.primary_range) + 0.00001: continue
					reaches = true
					var points: Array[Vector3] = _source_points(id)
					points.append_array(_landing_points(at))
					if not _points_framed(camera, points) or not _points_framed(camera, points, _settled_follow_delta(camera, at)): framed = false
				if reaches and framed: returns.append(returning)
	return {"encounter_id": CROSSING_EPOCH, "world_revision": WORLD_REVISION, "recognition_s": 0.30, "attack_input_margin_s": 0.10, "escape_directions": escapes, "return_directions": returns, "floor_regions": floor_regions()}

func _mechanism_framed(id: String, state: Dictionary) -> bool:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(camera) or not _mechanisms[id].is_visible_in_tree(): return false
	var points: Array[Vector3] = _source_points(id)
	if state.get("phase") != "recovery": points.append_array(_lane_points(state.geometry))
	if state.get("status") == "running" and _views.has(id):
		for key: String in ["landing", "attack_position"]: points.append_array(_landing_points(Codec.read_vector3(_views[id][key])))
	return _points_framed(camera, points)

func _apply_readability(guard_actor_id: String = "", guard_state: Dictionary = {}) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(camera) or not is_instance_valid(hero): return
	var points: Array[Vector3] = _hero_readability_points(camera)
	for actor: Node3D in _actors.values():
		var rig: Node3D = actor.get_node_or_null("HandlerRig") as Node3D
		if rig == null: rig = actor.get_node_or_null("ScoutRig") as Node3D
		if is_instance_valid(rig):
			if actor.is_visible_in_tree(): rig.call("apply_readability", camera, points)
			else: rig.call("clear_readability")
	if _foot_visual.visible: _foot_visual.call("apply_readability", camera, points)
	else: _foot_visual.call("clear_readability")
	for id: String in _mechanisms:
		var state: Dictionary = _mechanisms[id].call("state")
		if state.status == "running": points.append_array(_lane_points(state.geometry))
	for bank: MeshInstance3D in _bank_visuals:
		var obscures: bool = false
		for point: Vector3 in points:
			if _bank_blocks_point(bank, camera.project_ray_origin(camera.unproject_position(point)), point): obscures = true; break
		var material: StandardMaterial3D = bank.material_override as StandardMaterial3D
		var tint: Color = material.albedo_color
		tint.a = 0.12 if obscures else 1.0
		material.albedo_color = tint
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if obscures else BaseMaterial3D.TRANSPARENCY_DISABLED

func _scheduler_bindings() -> Dictionary:
	var owners: Dictionary = _ray_actors.duplicate()
	owners.merge(_mechanisms)
	return {"world_root": self, "owners": owners, "floors": floor_bindings()}

func encounter_state() -> Dictionary:
	var exchanges: Dictionary = {}
	for id: String in _actors: exchanges[id] = _actor_exchange(id)
	var mechanisms: Dictionary = {}
	for id: String in _mechanisms: mechanisms[id] = _mechanisms[id].call("state")
	return {"beat": _crossing.call("current_beat"), "active_ids": _crossing.call("current_active_ids"), "foot_id": _crossing.call("current_foot_id"), "clock_s": _scheduler.call("get_clock") if is_instance_valid(_scheduler) else 0.0, "exchanges": exchanges, "mechanisms": mechanisms, "runtime_error": runtime_error, "admission_errors": _admission_errors.duplicate(true), "exit_open": _crossing.call("exit_is_open")}

func _capture_local_state() -> Dictionary:
	if not get_tree().paused or _defeat_flush_queued or not _pending_defeats.is_empty(): return {"error": "L2 capture requires deferred paused commit barrier"}
	var bindings: Dictionary = _scheduler_bindings()
	var handlers: Dictionary = {}
	for id: String in CrossingSequence.HANDLERS: handlers[id] = _actors[id].call("snapshot_state")
	var mechanisms: Dictionary = {}
	for id: String in _mechanisms: mechanisms[id] = _mechanisms[id].call("snapshot_state", bindings)
	return {"sequence": _crossing.call("snapshot_state"), "scheduler": _scheduler.call("snapshot_state", bindings), "rays": _exchange.call("snapshot_state", bindings), "handlers": handlers, "mechanisms": mechanisms, "views": _views.duplicate(true), "profile_id": _profile_id, "scenic_clock": _scenic_clock, "witness_started_s": _witness_started_s, "collapse_started_s": _collapse_started_s, "last_action_sequence": _last_action_sequence, "contact_seen": _contact_seen, "pending_checkpoints": _pending_checkpoints.duplicate(), "completion_pending": _completion_pending, "exit_requested": _exit_requested}

func _local_snapshot_error_for_bindings(state: Dictionary, bindings: Dictionary) -> String:
	if not get_tree().paused or _defeat_flush_queued or not _pending_defeats.is_empty() or not runtime_error.is_empty(): return "L2 snapshot requires paused healthy committed unit"
	if _floors.size() != CROSSING_FLOORS.size() or not is_instance_valid(_kit.get("root")) or not is_instance_valid(_kit.get("collapse")) or not is_instance_valid(_foot_visual) or not is_instance_valid(_exit_cue): return "Missing required owned L2 scenery/ground/source"
	var error: String = Codec.keys_error(state, CROSSING_LOCAL_KEYS)
	if not error.is_empty(): return error
	for key: String in ["sequence", "scheduler", "rays", "handlers", "mechanisms", "views"]:
		if not state[key] is Dictionary: return "L2 requires paired dictionary " + key
	error = _crossing.call("snapshot_error", state.sequence)
	if not error.is_empty(): return error
	if state.profile_id not in ["assisted", "standard", "challenge"] or not Codec.is_integer(state.last_action_sequence) or not Codec.in_range(state.scenic_clock, 0, 1000000000.0) or not Codec.in_range(state.witness_started_s, 0, float(state.scenic_clock)) or not Codec.in_range(state.collapse_started_s, 0, float(state.scenic_clock)) or not state.contact_seen is String or not state.pending_checkpoints is Array or not state.completion_pending is bool or not state.exit_requested is bool:
		return "Invalid L2 finite clock/profile/progress"
	var beat: String = CrossingSequence.STAGES[state.sequence.stage_index]
	if not state.contact_seen.is_empty() and state.contact_seen != beat: return "L2 retained contact differs from current boundary"
	if (state.completion_pending or state.exit_requested) and beat != "clear": return "L2 final intent precedes earned clear"
	error = _scheduler.call("snapshot_error", state.scheduler, bindings)
	if not error.is_empty(): return error
	if state.scheduler.world_revision != WORLD_REVISION or (beat != "clear" and (state.scheduler.encounter_id != CROSSING_EPOCH or state.scheduler.profile.id != state.profile_id)) or (beat == "clear" and (not state.scheduler.encounter_id.is_empty() or not state.scheduler.reservations.is_empty())):
		return "L2 scheduler epoch/profile differs from objective"
	error = _exchange.call("snapshot_error", state.rays, bindings, state.scheduler)
	if not error.is_empty(): return error
	if not Codec.keys_error(state.handlers, CrossingSequence.HANDLERS).is_empty() or not Codec.keys_error(state.mechanisms, _mechanisms.keys()).is_empty(): return "L2 requires every actual Handler/mechanism"
	for id: String in _actors:
		var actor: Dictionary = state.handlers[id] if CrossingSequence.HANDLERS.has(id) else state.rays.actors[id]
		error = _actors[id].call("snapshot_error", actor)
		if not error.is_empty(): return error
		if CrossingSequence.HANDLERS.has(id):
			if float(actor.max_hp) != float(TOOL_ROLE.max_hp) or actor.direction != [0.0, 0.0, 1.0] or float(actor.body_yaw) != 0.0: return "L2 fixed Handler must retain canonical HP/direction/yaw"
			var tool: Dictionary = state.mechanisms.get("tool_" + id, {})
			if tool.is_empty(): return "L2 Handler requires its complete actual tool consumer"
			var expected_phase: String = "defeated" if float(actor.hp) <= 0.0 else (String(tool.phase) if tool.status == "running" else "idle")
			if actor.phase != expected_phase: return "L2 Handler pose differs from actual tool phase"
		if (float(actor.hp) <= 0.0) != state.sequence.defeated_ids.has(id): return "L2 HP differs from earned defeat prefix"
		if not state.sequence.active_ids.has(id) and not state.sequence.defeated_ids.has(id) and actor.phase != "idle": return "Dormant L2 target must stay idle"
	for id: String in _mechanisms:
		error = _mechanisms[id].call("snapshot_error", state.mechanisms[id], bindings, state.scheduler)
		if not error.is_empty(): return error
		var saved: Dictionary = state.mechanisms[id]
		if saved.status == "running":
			if id.begins_with("tool_") and not state.sequence.active_ids.has(id.substr(5)): return "Inactive Handler cannot retain an attack"
			if not id.begins_with("tool_") and state.sequence.foot_id != id: return "Only the current single visible foot may run"
			if not state.views.has(id): return "Running L2 mechanism needs its view witness"
	for id: Variant in state.views:
		if not id is String or not state.mechanisms.has(id) or state.mechanisms[id].status != "running" or not state.views[id] is Dictionary: return "Invalid L2 view witness owner"
		var view: Dictionary = state.views[id]
		if not Codec.keys_error(view, ["reservation_id", "landing", "attack_position", "target_id", "primary_time_s", "response_complete_s"]).is_empty() or view.reservation_id != state.mechanisms[id].exchange.id or not Codec.is_vector3(view.landing) or not Codec.is_vector3(view.attack_position) or not view.target_id is String or not Codec.in_range(view.primary_time_s, 0, 1000000000.0) or not Codec.in_range(view.response_complete_s, float(view.primary_time_s), 1000000000.0): return "Invalid finite L2 framing witness"
		var counterpart: String = "apron_handler" if id == "foot_apron" else ("crossing_scout" if id in ["foot_left", "foot_right"] else "")
		if not counterpart.is_empty() and state.sequence.defeated_ids.has(counterpart): counterpart = ""
		if view.target_id != counterpart: return "Foot view must retain its authored living counterpart custody"
		var foot_exchange: Dictionary = state.mechanisms[id].exchange
		if float(view.primary_time_s) <= float(foot_exchange.active_until_s) or float(view.response_complete_s) > float(foot_exchange.recovery_until_s): return "L2 accepted view response must fit its actual consumer recovery"
		if not counterpart.is_empty():
			if not state.sequence.active_ids.has(counterpart): return "Paired L2 real target must remain alive/current"
			var target: Dictionary = state.handlers[counterpart] if CrossingSequence.HANDLERS.has(counterpart) else state.rays.actors[counterpart]
			var target_consumer: Dictionary = state.mechanisms["tool_" + counterpart] if CrossingSequence.HANDLERS.has(counterpart) else state.rays.records[counterpart]
			if float(target.hp) <= 0.0 or target_consumer.status != "running" or (not CrossingSequence.HANDLERS.has(counterpart) and not target_consumer.exchange.adapter.locked): return "Paired foot requires a living armed real target"
			var owned: Dictionary = {}
			for reservation: Dictionary in state.scheduler.reservations:
				if reservation.id == target_consumer.exchange.id: owned = reservation
			if owned.is_empty() or foot_exchange.opening_position != target.root_position or owned.opening_position != target.root_position or float(view.primary_time_s) <= float(owned.active_until_s) or float(view.response_complete_s) > float(owned.recovery_until_s): return "Foot response must fit the actual paired target position and recovery"
	return ""

func _progress_snapshot_error(state: Dictionary) -> String:
	var local: Dictionary = state.local
	var progress: Dictionary = state.progress
	var clear: bool = local.sequence.stage_index == 11
	if progress.completed != (clear and not local.completion_pending) or (progress.completed and progress.completion_id != "weybridge-crossing-clear") or (not progress.contact_exit_id.is_empty()) != local.exit_requested or (local.exit_requested and progress.contact_exit_id != "weybridge-shelter"): return "L2 completion/contact differs from objective"
	var expected: Dictionary = {}
	var ordered: Array[String] = []
	for contact: String in local.sequence.crossed_contacts:
		var id: String = CrossingSequence.CONTACTS[contact].checkpoint
		expected[id] = "encounter"
		ordered.append(id)
	if local.pending_checkpoints.size() > 1: return "L2 has at most one pending earned boundary"
	for id: Variant in local.pending_checkpoints:
		if not expected.has(id) or ordered.back() != id: return "L2 pending boundary must be current ordered tail"
		expected.erase(id)
	if progress.checkpoint_ids != expected or progress.checkpoint_id != (ordered[expected.size() - 1] if not expected.is_empty() else ""): return "L2 checkpoint history differs from earned contacts"
	return ""

func _restore_local_state(state: Dictionary) -> void:
	_crossing.call("restore_state", state.sequence)
	_profile_id = state.profile_id
	_scenic_clock = float(state.scenic_clock)
	_witness_started_s = float(state.witness_started_s)
	_collapse_started_s = float(state.collapse_started_s)
	_last_action_sequence = int(state.last_action_sequence)
	_contact_seen = state.contact_seen
	_pending_checkpoints.assign(state.pending_checkpoints)
	_completion_pending = state.completion_pending
	_exit_requested = state.exit_requested
	_views = state.views.duplicate(true)
	_mechanism_proofs.clear()
	for id: String in _actors:
		var saved: Dictionary = state.handlers[id] if CrossingSequence.HANDLERS.has(id) else state.rays.actors[id]
		if not _actors[id].call("restore_state", saved): runtime_error = "L2 actual actor commit failed " + id; return
	var bindings: Dictionary = _scheduler_bindings()
	if not _scheduler.call("restore_state", state.scheduler, bindings): runtime_error = "L2 scheduler commit failed"; return
	if not _exchange.call("restore_state", state.rays, bindings): runtime_error = "L2 ray commit failed"; return
	for id: String in _mechanisms:
		if not _mechanisms[id].call("restore_state", state.mechanisms[id], bindings): runtime_error = "L2 mechanism commit failed " + id; return
	_update_actor_visibility()
	var marker_blocks: Dictionary = {}
	for id: String in _opening_cues:
		marker_blocks[id] = _opening_cues[id].is_blocking_signals()
		_opening_cues[id].set_block_signals(true)
	_update_mechanism_poses()
	for id: String in _opening_cues: _opening_cues[id].set_block_signals(marker_blocks[id])
	_apply_tableau()
	_apply_readability()
	_update_objective()
	var blocked: bool = _exit_cue.is_blocking_signals()
	_exit_cue.set_block_signals(true)
	_exit_cue.call("clear")
	if _crossing.call("exit_is_open"): _exit_cue.call("present", "active" if _exit_requested else "available", "contact")
	_exit_cue.set_block_signals(blocked)

func _on_exit_level() -> void:
	set_physics_process(false)
	if is_instance_valid(hero) and hero.world_action_executed.is_connected(_on_world_action): hero.world_action_executed.disconnect(_on_world_action)
	for mechanism: Node3D in _mechanisms.values():
		if is_instance_valid(mechanism): mechanism.call("clear", "l2_exit")
	if is_instance_valid(_exchange): _exchange.call("cleanup")
	if is_instance_valid(_scheduler): _scheduler.call("end_encounter", "l2_exit")
	for actor: Node3D in _actors.values():
		if is_instance_valid(actor): actor.call("disarm")
	_pending_defeats.clear()
	_defeat_flush_queued = false
	_views.clear()
	_mechanism_proofs.clear()
	if is_instance_valid(_exit_cue): _exit_cue.call("clear")
