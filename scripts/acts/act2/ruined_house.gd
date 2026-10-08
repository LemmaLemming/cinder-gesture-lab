extends "res://scripts/acts/act2/weybridge.gd"
## L3 authored assembly. Reuses owned static/readability/player helpers only.
## Integration owns the required finite smoke consumer. Full aggregate hookup
## is intentionally unavailable until that supported API is published.
const HouseSequence: Script = preload("res://scripts/acts/act2/ruined_house_sequence.gd")
const HouseFloor: Script = preload("res://scripts/acts/act2/ruined_house_floor.gd")
const HouseKit: Script = preload("res://scripts/acts/act2/ruined_house_kit.gd")
const TenderActor: Script = preload("res://scripts/acts/act2/canister_tender_actor.gd")
const BossActor: Script = preload("res://scripts/acts/act2/handling_machine_boss_actor.gd")
const HOUSE_EPOCH: String = "A2-L3-ruined-house"
const BREAKOUT: Rect2 = Rect2(-2.7, -40.7, 5.4, 1.3)
const BANK_TO_TENDER: Dictionary = {"road_bank": "road_tender", "house_bank": "house_tender", "boss_bank": "side_tender"}
var _clouds: Dictionary = {}
var _boss_phase_pending: bool = false
var _boss_next_action: String = "reach"
# Original admitted Scheduler deadline shared across the two selected tools.
# Read its existing clock; never advance, shorten or refresh a private clock.
var _boss_ready_s: float = 0.0
var _smoke_api_ready: bool = false
var _forecast_points: Dictionary = {}

func _ready() -> void:
	_art_preview = false
	_crossing = HouseSequence.new()
	process_physics_priority = 110
	_floors = HouseFloor.build(self)
	_kit = HouseKit.build(self)
	var kit_root: Node3D = _kit.root
	for path: NodePath in kit_root.get_meta("optional_cutaway_paths", []):
		var mesh: MeshInstance3D = kit_root.get_node_or_null(path) as MeshInstance3D
		if is_instance_valid(mesh): _bank_visuals.append(mesh)
	set_physics_process(false)

func _on_enter_level() -> void:
	if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference"):
		_profile_id = shared_shell.call("get_difficulty_preference")
	_scheduler = Scheduler.new()
	_scheduler.name = "RuinedHouseThreatScheduler"
	add_child(_scheduler)
	if not _scheduler.call("begin_encounter", _profile_id, HOUSE_EPOCH, WORLD_REVISION):
		runtime_error = _scheduler.get("last_error")
		return
	for id: String in HouseSequence.ACTORS:
		var actor_script: Script = TenderActor if HouseSequence.TENDERS.has(id) else (BossActor if id == "handling_machine" else (HandlerActor if HouseSequence.HANDLERS.has(id) else WeybridgeScoutActor))
		var actor: Node3D = actor_script.new() as Node3D
		actor.name = "RuinedHouse_" + id
		actor.position = HouseSequence.ACTORS[id]
		add_child(actor)
		if not actor.call("configure", hero, effects, id):
			runtime_error = "Cannot bind actual L3 actor " + id
			return
		_actors[id] = actor
		if id == "apron_scout":
			_ray_actors[id] = actor
			continue
		actor.connect("defeated", _on_scout_defeated)
		if id == "handling_machine":
			actor.connect("phase_boundary_reached", _on_boss_phase_boundary)
			_new_mechanism("boss_reach", actor.position, Geometry.lane(actor.position, actor.position + Vector3.BACK * 3.8, 0.31), actor.position, TOOL_ROLE, TOOL_FLOORS)
			_new_mechanism("boss_place", actor.position, Geometry.circle(actor.position, 1.10), actor.position, TOOL_ROLE, TOOL_FLOORS)
		elif HouseSequence.HANDLERS.has(id):
			_new_mechanism("tool_" + id, actor.position, Geometry.lane(actor.position, actor.position + Vector3.BACK * 3.8, 0.31), actor.position, TOOL_ROLE, TOOL_FLOORS)
		if not actor.call("bind_damage_window", Callable(self, "_handler_window").bind(id)):
			runtime_error = "Cannot bind actual L3 recovery target " + id
			return
		var opening: Node3D = InteractionCue.new() as Node3D
		opening.name = "LowMountOpening_" + id
		opening.position = actor.position
		add_child(opening)
		opening.call("clear")
		_opening_cues[id] = opening
	_exchange = Exchange.new() as Node3D
	_exchange.name = "OneFamiliarApronRay"
	add_child(_exchange)
	if not _exchange.call("configure", hero, effects, _scheduler, _ray_actors, _profile_id, _response_context()):
		runtime_error = _exchange.get("last_error")
		return
	_exchange.call("set_response_context_provider", _response_context)
	_exchange.call("set_presentation_guard", _presentation_guard)
	_exchange.connect("scout_defeated", _on_scout_defeated)
	_exit_cue = InteractionCue.new() as Node3D
	_exit_cue.name = "ExcavationBreakoutContact"
	_exit_cue.position = Vector3(0, 0, BREAKOUT.get_center().y)
	add_child(_exit_cue)
	_exit_cue.call("clear")
	hero.world_action_executed.connect(_on_world_action)
	hero.died.connect(_on_hero_died)
	_update_actor_visibility()
	_update_objective()
	_apply_tableau()
	_smoke_api_ready = _configure_clouds()
	set_physics_process(true)

func _configure_clouds() -> bool:
	# No private replacement, assumed interface or unpublished source copy.
	# This is the one remaining supported shared-consumer integration seam.
	_admission_errors["smoke_dependency"] = {"reason": "published finite smoke API pending; no emission/damage authority"}
	return false

func _new_mechanism(id: String, at: Vector3, shape: Dictionary, opening: Vector3, role: Dictionary = Mechanism.DEFAULT_RAW_ROLE, floors: Dictionary = Mechanism.DEFAULT_TIMING_FLOORS) -> Node3D:
	var node: Node3D = Mechanism.new() as Node3D
	node.name = id
	node.position = at
	add_child(node)
	if not node.call("configure", id, shape, opening, role, floors) or not node.call("bind", _scheduler, {"hero": hero}):
		runtime_error = "Cannot bind actual L3 tool " + id
		return null
	node.connect("state_changed", Callable(self, "_on_mechanism_state").bind(id))
	node.connect("hit_resolved", Callable(self, "_on_mechanism_hit").bind(id))
	_mechanisms[id] = node
	return node

func _physics_process(delta: float) -> void:
	if not _entered or get_tree().paused or not is_instance_valid(hero) or not runtime_error.is_empty(): return
	_update_mechanism_poses()
	if hero.dead: return
	_scenic_clock += delta
	_flush_boss_phase()
	_flush_progress_requests()
	_update_actor_visibility()
	_apply_tableau()
	_apply_readability()
	if not _smoke_api_ready: return
	var beat: String = _crossing.call("current_beat")
	if beat == "clear":
		if is_completed() and not _exit_requested and _hero_contacts(BREAKOUT):
			_exit_requested = true
			_exit_cue.call("present", "active", "contact")
			request_contact_exit("excavation-breakout", hero)
		return
	if HouseSequence.CONTACTS.has(beat):
		if _hero_contacts(HouseSequence.CONTACTS[beat].region): _contact_seen = beat
		var response: Dictionary = hero.get_threat_response_state()
		if _contact_seen == beat and response.get("stable", false) and float(response.get("commitment_remaining_s", 1.0)) <= 0.00001:
			if not _crossing.call("commit_contact", beat): runtime_error = "Invalid earned L3 contact"; return
			_contact_seen = ""
			_pending_checkpoints.append(HouseSequence.CONTACTS[beat].checkpoint)
			_flush_progress_requests()
			_update_actor_visibility()
			_update_objective()
		return
	for id: String in _crossing.call("current_active_ids"):
		if HouseSequence.TENDERS.has(id): continue # supported smoke hookup pending
		var actor: Node3D = _actors[id]
		if id == "apron_scout":
			var state: Dictionary = _exchange.call("state", id)
			if state.status == "running":
				if not _exchange_framed(actor, state): _exchange.call("cancel", id, "l3_required_presentation_unavailable")
			elif hero.global_position.distance_to(actor.global_position) <= 3.8:
				var bearing: Vector3 = hero.global_position - actor.global_position
				bearing.y = 0
				if bearing.length_squared() < 0.000001: bearing = Vector3.BACK
				var shape: Dictionary = Geometry.lane(actor.global_position, actor.global_position + bearing.normalized() * 3.8, 0.31)
				if _exchange_framed(actor, {"geometry": shape}):
					var answer: Dictionary = _exchange.call("activate", id)
					_admission_errors[id] = {} if answer.get("accepted", false) else {"reason": answer.get("reason", "rejected")}
		else:
			_activate_mechanism("boss_" + _boss_next_action if id == "handling_machine" else "tool_" + id, id)

func _activate_mechanism(id: String, target_id: String) -> void:
	var node: Node3D = _mechanisms[id]
	var bound_player: CinderPlayer = hero
	var bound_scheduler: Node = _scheduler
	var bound_actor: Node3D = _actors.get(target_id)
	var state: Dictionary = node.call("state")
	if state.status == "running":
		if not _mechanism_framed(id, state): node.call("cancel", "l3_required_presentation_unavailable")
		return
	if id.begins_with("boss_"):
		if float(_scheduler.call("get_clock")) < _boss_ready_s: return
		for other: String in ["boss_reach", "boss_place"]:
			if other != id and _mechanisms[other].call("state").status == "running": return
		if _actors.handling_machine.get("transition_pending"): return
	if hero.global_position.distance_to(node.global_position) > 3.8: return
	if id.begins_with("boss_") and not _actors.handling_machine.call("set_tool_action", id.substr(5)): return
	var context: Dictionary = _response_context()
	var preview: Dictionary = node.call("preview_start", "hero", context)
	if not preview.get("accepted", false):
		_admission_errors[id] = {"reason": preview.get("reason", "preview_rejected")}
		_forecast_points.erase(id)
		return
	var points: Array[Vector3] = _source_points(id)
	points.append_array(_lane_points(state.geometry))
	for key: String in ["landing", "attack_position"]: points.append_array(_landing_points(preview.proof[key]))
	_forecast_points[id] = points
	if not is_instance_valid(shared_shell) or not shared_shell.has_method("camera_framing_error") or not String(shared_shell.call("camera_framing_error", points)).is_empty(): return
	# The actual Game's camera settles this forecast; recalculate preview every
	# real tick rather than retaining a stale clock/source/union guard.
	var answer: Dictionary = node.call("start", "hero", context, null, null, preview)
	# Warning publication can synchronously cancel, pause or remove this unit.
	# Never repopulate a cleared view from a stale accepted return dictionary.
	if not is_instance_valid(self) or not is_inside_tree() or is_queued_for_deletion() or not _entered: return
	for item: Node in [node, bound_actor, bound_player, bound_scheduler]:
		if not is_instance_valid(item) or not item.is_inside_tree() or item.is_queued_for_deletion(): return
	if _mechanisms.get(id) != node or _actors.get(target_id) != bound_actor or hero != bound_player or _scheduler != bound_scheduler: return
	_admission_errors[id] = {} if answer.get("accepted", false) else {"reason": answer.get("reason", "rejected")}
	if not answer.get("accepted", false): return
	var current: Dictionary = node.call("state")
	if int(current.cycle) != int(state.cycle) + 1: return
	# Even a same-callback cancellation consumes its actual original cooldown.
	# Retain that admitted deadline across the distinct Reach/Place owners.
	if id.begins_with("boss_"): _boss_ready_s = maxf(_boss_ready_s, float(answer.reservation.cooldown_until_s))
	if current.status != "running" or current.reservation_id != answer.reservation_id or current.geometry != answer.reservation.geometry or current.opening_position != bound_actor.global_position or bound_player.dead or not bound_actor.is_visible_in_tree():
		_views.erase(id)
		_mechanism_proofs.erase(id)
		_forecast_points.erase(id)
		return
	_mechanism_proofs[id] = answer.proof.duplicate(true)
	_views[id] = {"reservation_id": answer.reservation_id, "landing": Codec.vector3(answer.proof.landing), "attack_position": Codec.vector3(answer.proof.attack_position), "target_id": target_id, "primary_time_s": answer.proof.primary_time_s, "response_complete_s": answer.proof.response_complete_s, "equipment_ids": hero.equipment.snapshot()}
	_forecast_points.erase(id)

func _response_context(_actor_id: String = "", _shape: Dictionary = {}) -> Dictionary:
	return {"encounter_id": HOUSE_EPOCH, "world_revision": WORLD_REVISION, "recognition_s": 0.30, "attack_input_margin_s": 0.10, "escape_directions": RESPONSE_DIRECTIONS.duplicate(), "return_directions": RESPONSE_DIRECTIONS.duplicate(), "floor_regions": floor_regions()}

func _tool_target(id: String) -> String:
	return "handling_machine" if id.begins_with("boss_") else id.substr(5)

func _actor_exchange(id: String) -> Dictionary:
	if id == "apron_scout": return _exchange.call("state", id)
	if HouseSequence.TENDERS.has(id): return {}
	if id == "handling_machine":
		for key: String in ["boss_reach", "boss_place"]:
			if _mechanisms[key].call("state").status == "running": return _mechanisms[key].call("state")
		return _mechanisms["boss_" + _boss_next_action].call("state")
	return _mechanisms["tool_" + id].call("state")

func _tool_context_live(id: String, tool_id: String, actor: Node3D, tool: Node3D, player: CinderPlayer, scheduler: Node, marker: Node3D) -> bool:
	if not is_instance_valid(self) or not is_inside_tree() or is_queued_for_deletion(): return false
	if not _entered or _restoring or _validating or _snapshotting or get_tree().paused: return false
	for node: Node in [actor, tool, player, scheduler, marker]:
		if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion(): return false
	if hero != player or _scheduler != scheduler or _actors.get(id) != actor or _mechanisms.get(tool_id) != tool or _opening_cues.get(id) != marker or player.dead: return false
	return _crossing.call("current_active_ids").has(id) and actor.is_visible_in_tree() and tool.is_visible_in_tree() and marker.is_visible_in_tree() and float(actor.get("hp")) > 0.0 and actor.get_world_3d() == player.get_world_3d() and tool.get_world_3d() == player.get_world_3d() and scheduler.get_world_3d() == player.get_world_3d()

func _handler_window(id: String) -> bool:
	var player: CinderPlayer = hero
	var scheduler: Node = _scheduler
	var actor: Node3D = _actors.get(id)
	var marker: Node3D = _opening_cues.get(id)
	if not is_instance_valid(actor): return false
	var tool_id: String = "boss_" + String(actor.get("tool_action")) if id == "handling_machine" else "tool_" + id
	var tool: Node3D = _mechanisms.get(tool_id)
	if not _tool_context_live(id, tool_id, actor, tool, player, scheduler, marker): return false
	var before: Dictionary = tool.call("state")
	if before.get("status") != "running" or before.get("phase") != "recovery": return false
	var lease: Dictionary = scheduler.call("reservation_state", before.reservation_id)
	# Cleanup may publish observer callbacks. Recheck the entire native parent
	# and sample this actual consumer/cue again before dereferencing the Hero.
	if not is_instance_valid(self) or not _tool_context_live(id, tool_id, actor, tool, player, scheduler, marker): return false
	var current: Dictionary = tool.call("state")
	if current.status != "running" or current.phase != "recovery" or current.reservation_id != before.reservation_id or current.cycle != before.cycle: return false
	if lease.is_empty() or lease.state != "recovery" or lease.source_instance_id != tool.get_instance_id() or lease.geometry != current.geometry or lease.opening_position != actor.global_position: return false
	var clock: float = scheduler.call("get_clock")
	return clock > float(lease.active_until_s) and clock <= float(lease.recovery_until_s) and _mechanism_framed(tool_id, current) and marker.call("state").state == "available"

func _on_mechanism_state(state: Dictionary, id: String) -> void:
	if not _entered or _restoring or _validating or _snapshotting: return
	_pose_mechanism(id, state)
	if state.status != "running":
		_views.erase(id)
		_mechanism_proofs.erase(id)
		if state.status == "complete" and id.begins_with("boss_"):
			_boss_next_action = "place" if id == "boss_reach" else "reach"
	elif not _mechanism_framed(id, state):
		_mechanisms[id].call("cancel", "l3_same_callback_presentation_unavailable")

func _on_mechanism_hit(_hero_id: String, _cycle: int, _result: Dictionary, _id: String) -> void:
	if _entered and not _restoring and not _validating and not _snapshotting: _update_mechanism_poses()

func _pose_mechanism(id: String, state: Dictionary) -> void:
	var target: String = _tool_target(id)
	var actor: Node3D = _actors.get(target)
	if not is_instance_valid(actor): return
	if id.begins_with("boss_") and actor.get("tool_action") != id.substr(5): return
	if float(actor.get("hp")) > 0.0: actor.call("present_phase", state.phase if state.status == "running" else "idle", _phase_progress(state) if state.status == "running" else 0.0, Vector3.BACK)
	var cue: Node3D = _opening_cues.get(target)
	if not is_instance_valid(cue): return
	if state.status == "running" and state.phase == "recovery" and float(actor.get("hp")) > 0.0: cue.call("present", "available", "attack")
	else: cue.call("clear")

func _on_ray_state(_actor_id: String, _state: Dictionary) -> void:
	pass # L3 has no crossing foot/paired source wrapper.

func _on_boss_phase_boundary(_actor_id: String) -> void:
	_boss_phase_pending = true
	_flush_boss_phase.call_deferred()

func _flush_boss_phase() -> void:
	if not _boss_phase_pending or not _entered or _restoring or _validating or _snapshotting or get_tree().paused or hero.dead: return
	if _crossing.call("current_beat") != "boss_phase_one" or _actors.handling_machine.get("boss_phase") != 1 or not _actors.handling_machine.get("transition_pending") or _actors.handling_machine.get("hp") != 15.0:
		runtime_error = "B02 phase boundary differs from actual threshold/current sequence"
		return
	if not _actors.handling_machine.call("commit_phase_two") or not _crossing.call("commit_boss_phase_two"):
		runtime_error = "Actual B02 threshold/sequence phase commit failed"
		return
	_boss_phase_pending = false
	_pending_checkpoints.append("handling-machine-phase-two")
	_update_actor_visibility()
	_update_objective()
	_flush_progress_requests()

func _flush_defeats() -> void:
	_defeat_flush_queued = false
	if not _entered or _restoring or _validating or _snapshotting: return
	var ids: Array[String] = _pending_defeats.duplicate()
	_pending_defeats.clear()
	# One primary can disable both. Commit the optional side source first so
	# the required boss clear never discards its already earned defeat.
	if ids.has("handling_machine"):
		ids.erase("handling_machine")
		ids.append("handling_machine")
	for id: String in ids:
		if not _crossing.call("commit_defeat", id): runtime_error = "Invalid actual L3 defeat " + id; return
		if HouseSequence.HANDLERS.has(id): _mechanisms["tool_" + id].call("cancel", "real_handler_defeated")
		if id == "handling_machine":
			for key: String in ["boss_reach", "boss_place"]: _mechanisms[key].call("cancel", "local_arm_disengaged")
		# Tender defeat must only stop future emissions. The independent bank
		# keeps its original active/recovery lease and exposure history.
		if _opening_cues.has(id): _opening_cues[id].call("clear")
	_update_actor_visibility()
	_update_objective()
	if _crossing.call("exit_is_open"):
		_completion_pending = true
		_exit_cue.call("present", "available", "contact")
	_flush_progress_requests()

func _flush_progress_requests() -> void:
	if hero.dead or not _entered or _restoring or _validating or _snapshotting: return
	while not _pending_checkpoints.is_empty():
		var id: String = _pending_checkpoints.pop_front()
		if not request_checkpoint(id, "boss_phase" if id == "handling-machine-phase-two" else "encounter"):
			runtime_error = "Cannot request actual earned L3 checkpoint " + id
			return
	if _completion_pending and _clouds_quiet():
		_exchange.call("cancel_all", "ruined_house_clear")
		_scheduler.call("end_encounter", "ruined_house_clear")
		_completion_pending = false
		if not request_completion("ruined-house-escape"): runtime_error = "Cannot complete actual L3 local escape"

func _clouds_quiet() -> bool:
	return _smoke_api_ready and _clouds.is_empty() # replace only with published consumer state

func _on_world_action(record: Dictionary) -> void:
	if not _entered or _restoring or _validating or _snapshotting or int(record.get("sequence", 0)) <= _last_action_sequence: return
	_last_action_sequence = int(record.sequence)
	var beat: String = _crossing.call("current_beat")
	if record.kind == "dash" and record.get("landing") is Vector3 and HouseSequence.CONTACTS.has(beat):
		for index: int in range(1, record.get("path", []).size()):
			var a: Vector3 = record.path[index - 1].position
			var b: Vector3 = record.path[index].position
			if _segment_contacts(Vector2(a.x, a.z), Vector2(b.x, b.z), HouseSequence.CONTACTS[beat].region): _contact_seen = beat

func _update_actor_visibility() -> void:
	var active: Array = _crossing.call("current_active_ids")
	var defeated: Array = _crossing.get("defeated_ids")
	for id: String in _actors: _actors[id].visible = active.has(id) or defeated.has(id)
	for id: String in _forecast_points.keys():
		if not active.has(_tool_target(id)): _forecast_points.erase(id)

func _update_objective() -> void:
	match _crossing.call("current_beat"):
		"smoke_edge": objective_text = "FIND CLEAR GROUND\nLET THE BANK THIN. STRIKE THE LOW RELOAD MOUNT."
		"clear_ground": objective_text = "FOLLOW THE CLEAR ROAD\nCROSS THE PALE GROUND BEYOND THE SMOKE."
		"ruined_house": objective_text = "BREAK THROUGH THE RUINED HOUSE\nCHOOSE A DRY SIDE OF THE LOW WALL."
		"wall_opening": objective_text = "LEAVE THE EXPOSED HOUSE\nCROSS THROUGH THE OPEN WALL."
		"work_apron": objective_text = "PASS THE OCCUPIED WORK APRON\nREAD THE MIRROR AND THE PLANTED TOOL."
		"boss_entry": objective_text = "REACH THE EXCAVATION OPENING\nKEEP THE LOW MACHINERY AND DRY FLOOR IN VIEW."
		"boss_phase_one", "boss_phase_two": objective_text = "DISENGAGE THE HANDLING ARM\nREAD REACH OR PLACE. STRIKE THE OPEN LOW JOINT."
		"clear": objective_text = "THE LOCAL ESCAPE IS OPEN\nLEAVE THROUGH THE PALE GROUND MARKER."

func _apply_tableau() -> void:
	HouseKit.set_work_tableau(_kit, _crossing.call("current_beat") in ["wall_opening", "work_apron", "boss_entry"], fmod(_scenic_clock / 7.0, 1.0))

func _required_source_points(actor: Node3D) -> Array[Vector3]:
	var all: Array[Vector3] = []
	_append_mesh_points(actor, all)
	return _conservative_corners(all)

func _conservative_corners(all: Array[Vector3]) -> Array[Vector3]:
	var points: Array[Vector3] = []
	if all.is_empty(): return points
	var bounds := AABB(all[0], Vector3.ZERO)
	for point: Vector3 in all: bounds = bounds.expand(point)
	for index: int in range(8): points.append(bounds.get_endpoint(index))
	return points

func _source_points(id: String) -> Array[Vector3]:
	if _actors.has(id): return _required_source_points(_actors[id])
	if _mechanisms.has(id): return _required_source_points(_actors[_tool_target(id)])
	return []

func _exchange_framed(actor: Node3D, state: Dictionary) -> bool:
	# Reuse the original independent Scout guard; L2's foot coupling is absent.
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(actor) or not actor.is_visible_in_tree() or not is_instance_valid(camera): return false
	var points: Array[Vector3] = _required_source_points(actor)
	if state.get("phase") != "recovery": points.append_array(_lane_points(_state_geometry(state)))
	var proof: Dictionary = state.get("proof", {})
	if not proof.get("landing") is Vector3: proof = state.get("presentation_witness", {})
	if state.get("phase") != "recovery":
		for key: String in ["landing", "attack_position"]:
			if proof.get(key) is Vector3: points.append_array(_landing_points(proof[key]))
	return _points_framed(camera, points)

func _mechanism_framed(id: String, state: Dictionary) -> bool:
	var target: String = _tool_target(id)
	var actor: Node3D = _actors.get(target)
	var tool: Node3D = _mechanisms.get(id)
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(actor) or not is_instance_valid(tool) or not is_instance_valid(camera) or not actor.is_inside_tree() or actor.is_queued_for_deletion() or not actor.is_visible_in_tree() or not tool.is_inside_tree() or tool.is_queued_for_deletion() or not tool.is_visible_in_tree(): return false
	var points: Array[Vector3] = _source_points(id)
	if points.is_empty(): return false
	if state.get("phase") != "recovery": points.append_array(_lane_points(state.geometry))
	if state.get("status") == "running" and _views.has(id):
		for key: String in ["landing", "attack_position"]: points.append_array(_landing_points(Codec.read_vector3(_views[id][key])))
	return _points_framed(camera, points)

func _apply_readability(_guard_actor_id: String = "", _guard_state: Dictionary = {}) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(camera) or not is_instance_valid(hero): return
	var hero_points: Array[Vector3] = _hero_readability_points(camera)
	var protected: Array[Vector3] = hero_points.duplicate()
	for id: String in _actors:
		var rig: Node3D = _actors[id].get("_visual") as Node3D
		if not is_instance_valid(rig): continue
		if _actors[id].is_visible_in_tree():
			rig.call("apply_readability", camera, hero_points)
			protected.append_array(_required_source_points(_actors[id]))
		else: rig.call("clear_readability")
	for id: String in _mechanisms:
		var state: Dictionary = _mechanisms[id].call("state")
		if state.status == "running": protected.append_array(_lane_readability_points(state.geometry) if state.geometry.kind == "lane" else _lane_points(state.geometry))
	for mesh: MeshInstance3D in _bank_visuals:
		var obscures: bool = false
		for point: Vector3 in protected:
			if _bank_blocks_point(mesh, camera.project_ray_origin(camera.unproject_position(point)), point): obscures = true; break
		var material: StandardMaterial3D = mesh.material_override as StandardMaterial3D
		var tint: Color = material.albedo_color
		tint.a = 0.12 if obscures else 1.0
		material.albedo_color = tint
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if obscures else BaseMaterial3D.TRANSPARENCY_DISABLED

func _camera_framing_points() -> Array:
	if not _entered or not is_instance_valid(hero): return []
	var points: Array[Vector3] = []
	for id: String in _mechanisms:
		var state: Dictionary = _mechanisms[id].call("state")
		if state.status == "running":
			points.append_array(_source_points(id))
			if state.phase != "recovery": points.append_array(_lane_points(state.geometry))
			if _views.has(id):
				for key: String in ["landing", "attack_position"]: points.append_array(_landing_points(Codec.read_vector3(_views[id][key])))
		elif _forecast_points.has(id): points.append_array(_forecast_points[id])
	if is_instance_valid(_exchange):
		var scout: Dictionary = _exchange.call("state", "apron_scout")
		if scout.get("status") == "running":
			points.append_array(_source_points("apron_scout"))
			if scout.phase != "recovery":
				points.append_array(_lane_points(_state_geometry(scout)))
				var proof: Dictionary = scout.get("proof", {})
				if not proof.get("landing") is Vector3: proof = scout.get("presentation_witness", {})
				for key: String in ["landing", "attack_position"]:
					if proof.get(key) is Vector3: points.append_array(_landing_points(proof[key]))
	return points

func _scheduler_bindings() -> Dictionary:
	var owners: Dictionary = _ray_actors.duplicate()
	owners.merge(_mechanisms)
	owners.merge(_clouds)
	return {"world_root": self, "owners": owners, "floors": floor_bindings()}

func encounter_state() -> Dictionary:
	var exchanges: Dictionary = {}
	for id: String in _actors: exchanges[id] = _actor_exchange(id)
	return {"beat": _crossing.call("current_beat"), "active_ids": _crossing.call("current_active_ids"), "boss_phase": _crossing.call("current_boss_phase"), "boss_phase_pending": _boss_phase_pending, "boss_ready_s": _boss_ready_s, "clock_s": _scheduler.call("get_clock") if is_instance_valid(_scheduler) else 0.0, "exchanges": exchanges, "runtime_error": runtime_error, "admission_errors": _admission_errors.duplicate(true), "smoke_api_ready": _smoke_api_ready, "exit_open": _crossing.call("exit_is_open")}

func _capture_local_state() -> Dictionary:
	return {"error": "L3 whole aggregate/Smoke API hookup is unimplemented; no checkpoint/pass claimed"}

func _local_snapshot_error_for_bindings(_state: Dictionary, _bindings: Dictionary) -> String:
	return "L3 whole aggregate/Smoke API hookup is unimplemented"

func _progress_snapshot_error(_state: Dictionary) -> String:
	return "L3 whole aggregate/Smoke API hookup is unimplemented"

func _restore_local_state(_state: Dictionary) -> void:
	runtime_error = "L3 whole aggregate restore is unimplemented"

func _on_exit_level() -> void:
	super._on_exit_level()
	_forecast_points.clear()
	_boss_phase_pending = false
