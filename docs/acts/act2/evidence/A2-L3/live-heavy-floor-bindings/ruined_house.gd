extends "res://scripts/acts/act2/weybridge.gd"
## L3 authored assembly. Reuses owned static/readability/player helpers only.
## Shared SmokeBank owns native grace, ticks and transport; this level owns
## its three fixed placements, Tender lifetime, presentation and aggregate.
const BankGuard: Script = preload("res://scripts/acts/act2/ruined_house_bank_guard.gd")
const SmokeBank: Script = preload("res://scripts/combat/smoke_bank.gd")
const SmokeVisual: Script = preload("res://scripts/acts/act2/smoke_bank_visual.gd")
const SmokeCueMesh: Script = preload("res://scripts/cues/cue_mesh.gd")
const SmokeSnapshotRules: Script = preload("res://scripts/acts/act2/ruined_house_smoke_rules.gd")
const KnownSnapshotRules: Script = preload("res://scripts/acts/act2/ruined_house_snapshot_rules.gd")
const HouseSequence: Script = preload("res://scripts/acts/act2/ruined_house_sequence.gd")
const HouseFloor: Script = preload("res://scripts/acts/act2/ruined_house_floor.gd")
const HouseKit: Script = preload("res://scripts/acts/act2/ruined_house_kit.gd")
const TenderActor: Script = preload("res://scripts/acts/act2/canister_tender_actor.gd")
const BossActor: Script = preload("res://scripts/acts/act2/handling_machine_boss_actor.gd")
const HOUSE_EPOCH: String = "A2-L3-ruined-house"
const BREAKOUT: Rect2 = Rect2(-2.7, -40.7, 5.4, 1.3)
const BANK_TO_TENDER: Dictionary = {"road_bank": "road_tender", "house_bank": "house_tender", "boss_bank": "side_tender"}
var _clouds: Dictionary = {}
var _cloud_art: Dictionary = {}
var _bank_views: Dictionary = {}
var _bank_proofs: Dictionary = {}
var _bank_cue_bytes: Dictionary = {}
var _bank_guard: Node
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
		if not actor.call("bind_damage_window", Callable(self, "_tender_window" if HouseSequence.TENDERS.has(id) else "_handler_window").bind(id)):
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
	if not _smoke_api_ready: return
	_bank_guard = BankGuard.new()
	_bank_guard.name = "SmokePresentationBeforeContact"
	_bank_guard.call("configure", Callable(self, "_guard_banks_before_contact"))
	add_child(_bank_guard)
	if not RenderingServer.frame_pre_draw.is_connected(_refresh_smoke_masks): RenderingServer.frame_pre_draw.connect(_refresh_smoke_masks)
	set_physics_process(true)

func _configure_clouds() -> bool:
	for id: String in BANK_TO_TENDER:
		var bank: Node3D = SmokeBank.new() as Node3D
		bank.name = id
		bank.position = HouseSequence.CLOUDS[id]
		add_child(bank)
		if not bank.call("configure", id, Geometry.circle(bank.position, 1.05), HouseSequence.ACTORS[BANK_TO_TENDER[id]]) or not bank.call("bind", _scheduler, {"hero": hero}):
			runtime_error = "Cannot bind actual L3 smoke bank " + id + ": " + String(bank.get("last_error"))
			return false
		_clouds[id] = bank
		# Cosmetic sibling: neither Tender death nor guarded native cue edits
		# may remove this source or impersonate its shared required children.
		var visual: Node3D = SmokeVisual.new() as Node3D
		visual.name = "LowBlackSmoke_" + id
		visual.position = bank.position
		add_child(visual)
		visual.call("pose", "clear", 0.0)
		_cloud_art[id] = visual
		bank.connect("state_changed", Callable(self, "_on_bank_state").bind(id))
		bank.connect("tick_resolved", Callable(self, "_on_bank_tick").bind(id))
	return true

func _bank_id(target: String) -> String:
	for id: String in BANK_TO_TENDER:
		if BANK_TO_TENDER[id] == target: return id
	return ""

func _bank_state(id: String) -> Dictionary:
	var state: Dictionary = _clouds[id].call("state")
	state["opening_position"] = state.exchange.get("opening_position", HouseSequence.ACTORS[BANK_TO_TENDER[id]])
	state["remaining_s"] = 0.0
	if state.status == "running":
		var deadline: String = {"warning": "lock_from_s", "lock": "active_from_s", "active": "active_until_s", "recovery": "recovery_until_s"}[state.phase]
		state.remaining_s = maxf(0.0, float(state.exchange[deadline]) - float(_scheduler.call("get_clock")))
	state["proof"] = _bank_proofs.get(id, {}).duplicate(true)
	state["presentation_witness"] = {}
	if _bank_views.has(id):
		state.presentation_witness = _bank_views[id].duplicate(true)
		for key: String in ["landing", "attack_position"]: state.presentation_witness[key] = Codec.read_vector3(_bank_views[id][key])
	return state

func _activate_bank(id: String) -> void:
	var bank: Node3D = _clouds[id]
	var actor: Node3D = _actors[BANK_TO_TENDER[id]]
	var player: CinderPlayer = hero
	var scheduler: Node = _scheduler
	var state: Dictionary = _bank_state(id)
	if state.status == "running": return
	if player.global_position.distance_to(actor.global_position) > 3.8: return
	var context: Dictionary = _response_context()
	# Published bank domain is closed to these two actual binding fields.
	context.floor_regions = floor_bindings().values()
	var preview: Dictionary = bank.call("preview_start", "hero", context)
	if not preview.get("accepted", false):
		_admission_errors[id] = {"reason": preview.get("reason", "preview_rejected")}
		_forecast_points.erase(id)
		return
	var points: Array[Vector3] = _required_source_points(actor)
	points.append_array(_lane_points(state.geometry))
	points.append(bank.global_position + Vector3.UP * 0.10)
	for key: String in ["landing", "attack_position"]: points.append_array(_landing_points(preview.proof[key]))
	_forecast_points[id] = points
	if not is_instance_valid(shared_shell) or not shared_shell.has_method("camera_framing_error") or not String(shared_shell.call("camera_framing_error", points)).is_empty(): return
	var answer: Dictionary = bank.call("start", "hero", context, null, preview)
	if not is_instance_valid(self) or not is_inside_tree() or is_queued_for_deletion() or not _entered:
		_cancel_admitted_bank(bank, "l3_smoke_parent_lost_after_start")
		return
	for node: Node in [bank, actor, player, scheduler]:
		if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion():
			_cancel_admitted_bank(bank, "l3_smoke_binding_lost_after_start")
			return
	if _clouds.get(id) != bank or _actors.get(BANK_TO_TENDER[id]) != actor or hero != player or _scheduler != scheduler:
		_cancel_admitted_bank(bank, "l3_smoke_binding_replaced_after_start")
		return
	_admission_errors[id] = {} if answer.get("accepted", false) else {"reason": answer.get("reason", "rejected")}
	var current: Dictionary = bank.call("state")
	if not answer.get("accepted", false): return
	if current.status != "running" or current.cycle != int(state.cycle) + 1 or current.reservation_id != answer.reservation_id or current.geometry != answer.reservation.geometry or current.exchange.opening_position != actor.global_position or player.dead or not actor.is_visible_in_tree():
		_cancel_admitted_bank(bank, "l3_smoke_correspondence_lost_after_start")
		return
	_bank_proofs[id] = answer.proof.duplicate(true)
	_bank_views[id] = {"reservation_id": answer.reservation_id, "landing": Codec.vector3(answer.proof.landing), "attack_position": Codec.vector3(answer.proof.attack_position), "target_id": BANK_TO_TENDER[id], "primary_time_s": answer.proof.primary_time_s, "response_complete_s": answer.proof.response_complete_s, "equipment_ids": player.equipment.snapshot()}
	_forecast_points.erase(id)
	if not _bank_framed(id): _cancel_admitted_bank(bank, "l3_smoke_response_lost_after_start")

func _cancel_admitted_bank(bank: Node3D, reason: String) -> void:
	if is_instance_valid(bank) and bank.is_inside_tree() and not bank.is_queued_for_deletion() and bank.call("state").status == "running": bank.call("cancel", reason)

func _bank_framed(id: String) -> bool:
	var bank: Node3D = _clouds.get(id)
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(bank) or not bank.is_inside_tree() or bank.is_queued_for_deletion() or not bank.is_visible_in_tree() or not is_instance_valid(camera): return false
	if not _bank_cue_current(id): return false
	var points: Array[Vector3] = []
	points.assign(bank.call("get_required_camera_points"))
	var actor: Node3D = _actors.get(BANK_TO_TENDER[id])
	if not is_instance_valid(actor) or not actor.is_visible_in_tree(): return false
	points.append_array(_required_source_points(actor))
	if _bank_views.has(id):
		for key: String in ["landing", "attack_position"]: points.append_array(_landing_points(Codec.read_vector3(_bank_views[id][key])))
	return not points.is_empty() and _points_framed(camera, points)

func _guard_banks_before_contact() -> void:
	# Actual Player/Scheduler precede this child at99; native contact consumer
	# runs at100. Root110 still derives all poses after its final native tick.
	if not _entered or get_tree().paused or _restoring or _validating or _snapshotting: return
	for id: String in _clouds:
		if _clouds[id].call("state").status == "running" and not _bank_framed(id): _clouds[id].call("cancel", "l3_smoke_required_presentation_before_contact")

func _cue_storage_bytes(object: Object) -> PackedByteArray:
	var values: Array = []
	for property: Dictionary in object.get_property_list():
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0: continue
		var value: Variant = object.get(String(property.name))
		values.append([property.name, ["object", value.get_instance_id()] if value is Object else value])
	return var_to_bytes(values)

func _bank_cue_signature(id: String) -> PackedByteArray:
	var bank: Node3D = _clouds.get(id)
	if not is_instance_valid(bank): return PackedByteArray()
	var state: Dictionary = bank.call("state")
	var cue: Node3D = bank.call("get_cue")
	if not is_instance_valid(cue) or not cue.is_visible_in_tree() or cue.is_queued_for_deletion() or cue.get_parent() != bank: return PackedByteArray()
	var value: Dictionary = cue.call("state")
	if value.phase != state.phase or (state.status == "running" and (value.geometry != state.geometry or value.source_position != bank.global_position or cue.global_transform != Transform3D(Basis.IDENTITY, bank.global_position))): return PackedByteArray()
	var parts: Array = [cue.get_instance_id(), cue.global_transform, value]
	for name: String in ["RequiredFootprintOutline", "RequiredFootprintFill", "RequiredSourceMarker"]:
		var part: MeshInstance3D = cue.get_node_or_null(name) as MeshInstance3D
		if not is_instance_valid(part) or part.is_queued_for_deletion() or part.get_parent() != cue or part.material_override == null: return PackedByteArray()
		if state.status == "running":
			var expected_visible: bool = name == "RequiredSourceMarker" or (state.phase != "recovery" and (name != "RequiredFootprintFill" or state.phase == "active"))
			if part.visible != expected_visible or (expected_visible and not part.is_visible_in_tree()) or not part.mesh is ArrayMesh: return PackedByteArray()
		parts.append([part.get_instance_id(), part.mesh.get_instance_id() if part.mesh != null else 0, part.material_override.get_instance_id(), _cue_storage_bytes(part), _cue_storage_bytes(part.material_override), part.mesh.get("_surfaces") if part.mesh is ArrayMesh else null])
	return var_to_bytes(parts)

func _remember_bank_cue(id: String) -> void:
	_bank_cue_bytes[id] = _bank_cue_signature(id)

func _bank_cue_current(id: String) -> bool:
	var bytes: PackedByteArray = _bank_cue_signature(id)
	return not bytes.is_empty() and bytes == _bank_cue_bytes.get(id, PackedByteArray())

func _tender_context_live(target: String, id: String, actor: Node3D, bank: Node3D, player: CinderPlayer, scheduler: Node, marker: Node3D) -> bool:
	if not is_instance_valid(self) or not is_inside_tree() or is_queued_for_deletion() or not _entered or _restoring or _validating or _snapshotting or get_tree().paused: return false
	for node: Node in [actor, bank, player, scheduler, marker]:
		if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion(): return false
	return hero == player and _scheduler == scheduler and _actors.get(target) == actor and _clouds.get(id) == bank and _opening_cues.get(target) == marker and not player.dead and _crossing.call("current_active_ids").has(target) and actor.is_visible_in_tree() and bank.is_visible_in_tree() and marker.is_visible_in_tree() and float(actor.get("hp")) > 0.0 and actor.get_world_3d() == player.get_world_3d() and bank.get_world_3d() == player.get_world_3d() and scheduler.get_world_3d() == player.get_world_3d()

func _tender_window(target: String) -> bool:
	var id: String = _bank_id(target)
	var actor: Node3D = _actors.get(target)
	var bank: Node3D = _clouds.get(id)
	var player: CinderPlayer = hero
	var scheduler: Node = _scheduler
	var marker: Node3D = _opening_cues.get(target)
	if not _tender_context_live(target, id, actor, bank, player, scheduler, marker): return false
	var before: Dictionary = bank.call("state")
	if before.status != "running" or before.phase != "recovery": return false
	var lease: Dictionary = scheduler.call("reservation_state", before.reservation_id)
	if not _tender_context_live(target, id, actor, bank, player, scheduler, marker): return false
	var current: Dictionary = bank.call("state")
	if current.status != "running" or current.phase != "recovery" or current.cycle != before.cycle or current.reservation_id != before.reservation_id: return false
	if lease.is_empty() or lease.state != "recovery" or lease.source_instance_id != bank.get_instance_id() or lease.geometry != current.geometry or lease.opening_position != actor.global_position: return false
	var clock: float = scheduler.call("get_clock")
	return clock > float(lease.active_until_s) and clock <= float(lease.recovery_until_s) and _bank_framed(id) and marker.call("state").state == "available" and _tender_context_live(target, id, actor, bank, player, scheduler, marker)

func _on_bank_state(_state: Dictionary, id: String) -> void:
	if not _entered or _restoring or _validating or _snapshotting: return
	_remember_bank_cue(id)
	var state: Dictionary = _bank_state(id)
	_pose_bank(id, state)
	if state.status != "running":
		_bank_views.erase(id)
		_bank_proofs.erase(id)
		_forecast_points.erase(id)
	elif not _bank_framed(id): _clouds[id].call("cancel", "l3_same_callback_smoke_presentation_unavailable")

func _on_bank_tick(_hero_id: String, _cycle: int, _result: Dictionary, id: String) -> void:
	if _entered and not _restoring and not _validating and not _snapshotting: _pose_bank(id, _bank_state(id))

func _pose_bank(id: String, state: Dictionary) -> void:
	var target: String = BANK_TO_TENDER[id]
	var actor: Node3D = _actors[target]
	if float(actor.get("hp")) > 0.0: actor.call("present_phase", state.phase if state.status == "running" else "idle", _phase_progress(state) if state.status == "running" else 0.0, Vector3.BACK)
	var cue: Node3D = _opening_cues[target]
	if state.status == "running" and state.phase == "recovery" and float(actor.get("hp")) > 0.0 and _crossing.call("current_active_ids").has(target): cue.call("present", "available", "attack")
	else: cue.call("clear")
	_cloud_art[id].call("pose", state.phase if state.status == "running" else "clear", _phase_progress(state) if state.status == "running" else 0.0)

func _refresh_smoke_masks() -> void:
	if not _entered or not is_instance_valid(hero): return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(camera): return
	# Rendering callback follows the normal Game camera update. Rebuild every
	# mask from this actual camera and current native vertices, never a cache.
	_apply_readability()
	var hero_points: Array[Vector3] = []
	if is_instance_valid(shared_shell) and shared_shell.has_method("player_camera_framing_points"): hero_points.assign(shared_shell.call("player_camera_framing_points"))
	for id: String in _clouds:
		var cue: Node3D = _clouds[id].call("get_cue")
		var sources: Array[Vector3] = []
		var marker: MeshInstance3D = cue.get_node_or_null("RequiredSourceMarker") as MeshInstance3D
		if is_instance_valid(marker) and marker.is_visible_in_tree() and marker.mesh != null:
			for surface: int in range(marker.mesh.get_surface_count()):
				var arrays: Array = marker.mesh.surface_get_arrays(surface)
				for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]: sources.append(marker.global_transform * vertex)
		var boundary: Array[Vector3] = []
		var value: Dictionary = cue.call("state")
		var outline: MeshInstance3D = cue.get_node_or_null("RequiredFootprintOutline") as MeshInstance3D
		if is_instance_valid(outline) and value.get("geometry", {}).get("kind") == "circle" and outline.transform == Transform3D(Basis.IDENTITY, Vector3.UP * CinderThreatCue.FLOOR_OFFSET):
			for point: Vector3 in SmokeCueMesh.boundary(value.geometry): boundary.append(cue.global_transform * (point + Vector3.UP * CinderThreatCue.FLOOR_OFFSET))
		_cloud_art[id].call("apply_readability", camera, hero_points, sources, boundary)

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
	for id: String in _clouds:
		_pose_bank(id, _bank_state(id))
		if _clouds[id].call("state").status == "running" and not _bank_framed(id): _clouds[id].call("cancel", "l3_smoke_required_presentation_unavailable")
	if hero.dead: return
	_scenic_clock += delta
	_flush_boss_phase()
	_flush_progress_requests()
	_update_actor_visibility()
	_apply_tableau()
	_apply_readability()
	if not _smoke_api_ready: return
	# A requested deferred pause still completes the native tick, but cannot
	# re-admit a just-cancelled source before its checkpoint barrier.
	if is_instance_valid(shared_shell) and shared_shell.has_method("is_pause_requested") and shared_shell.call("is_pause_requested"): return
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
		if HouseSequence.TENDERS.has(id):
			_activate_bank(_bank_id(id))
			continue
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
	if HouseSequence.TENDERS.has(id): return _bank_state(_bank_id(id))
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
	if not _smoke_api_ready: return false
	for id: String in _clouds:
		if _clouds[id].call("state").status == "running": return false
	return true

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
		if not active.has(BANK_TO_TENDER[id] if BANK_TO_TENDER.has(id) else _tool_target(id)): _forecast_points.erase(id)

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
	for id: String in _clouds:
		if _clouds[id].call("state").status == "running":
			points.append_array(_required_source_points(_actors[BANK_TO_TENDER[id]]))
			points.append_array(_clouds[id].call("get_required_camera_points"))
			if _bank_views.has(id):
				for key: String in ["landing", "attack_position"]: points.append_array(_landing_points(Codec.read_vector3(_bank_views[id][key])))
		elif _forecast_points.has(id): points.append_array(_forecast_points[id])
	return points

func _scheduler_bindings() -> Dictionary:
	var owners: Dictionary = _ray_actors.duplicate()
	owners.merge(_mechanisms)
	owners.merge(_clouds)
	return {"world_root": self, "owners": owners, "floors": floor_bindings()}

func encounter_state() -> Dictionary:
	var exchanges: Dictionary = {}
	for id: String in _actors: exchanges[id] = _actor_exchange(id)
	var banks: Dictionary = {}
	for id: String in _clouds: banks[id] = _bank_state(id)
	return {"banks": banks, "beat": _crossing.call("current_beat"), "active_ids": _crossing.call("current_active_ids"), "boss_phase": _crossing.call("current_boss_phase"), "boss_phase_pending": _boss_phase_pending, "boss_ready_s": _boss_ready_s, "clock_s": _scheduler.call("get_clock") if is_instance_valid(_scheduler) else 0.0, "exchanges": exchanges, "runtime_error": runtime_error, "admission_errors": _admission_errors.duplicate(true), "smoke_api_ready": _smoke_api_ready, "exit_open": _crossing.call("exit_is_open")}

# This component-only seam never supplies CinderLevel's complete local state.
# It retains the original supported-component evidence seam. Complete
# checkpoints below also retain every bank and bank framing witness.
func _capture_known_state() -> Dictionary:
	if not get_tree().paused or _defeat_flush_queued or not _pending_defeats.is_empty() or not runtime_error.is_empty():
		return {"error": "Known L3 components require the healthy native paused commit barrier"}
	var bindings: Dictionary = _scheduler_bindings()
	var targets: Dictionary = {}
	for id: String in KnownSnapshotRules.TARGET_IDS:
		targets[id] = _actors[id].call("snapshot_state")
	var mechanisms: Dictionary = {}
	for id: String in _mechanisms:
		mechanisms[id] = _mechanisms[id].call("snapshot_state", bindings)
	return {"sequence": _crossing.call("snapshot_state"), "scheduler": _scheduler.call("snapshot_state", bindings), "rays": _exchange.call("snapshot_state", bindings), "targets": targets, "mechanisms": mechanisms, "views": _views.duplicate(true), "profile_id": _profile_id, "world_revision": WORLD_REVISION, "scenic_clock": _scenic_clock, "last_action_sequence": _last_action_sequence, "contact_seen": _contact_seen, "pending_checkpoints": _pending_checkpoints.duplicate(), "completion_pending": _completion_pending, "exit_requested": _exit_requested, "boss_phase_pending": _boss_phase_pending, "boss_next_action": _boss_next_action, "boss_ready_s": _boss_ready_s}

func _known_snapshot_error(state: Dictionary, saved_player: Dictionary = {}) -> String:
	if not get_tree().paused or _defeat_flush_queued or not _pending_defeats.is_empty() or not runtime_error.is_empty():
		return "Known L3 components require a healthy native paused commit barrier"
	if _floors.size() != HouseFloor.SPECS.size() or not is_instance_valid(_kit.get("root")) or not is_instance_valid(_exit_cue):
		return "Known L3 components require their actual authored floor/scenery/exit unit"
	var error: String = Codec.value_error(state)
	if error.is_empty(): error = Codec.keys_error(state, KnownSnapshotRules.KNOWN_KEYS)
	if not error.is_empty(): return error
	for key: String in ["sequence", "scheduler", "rays", "targets", "mechanisms", "views"]:
		if not state[key] is Dictionary: return "Known L3 transport requires dictionary " + key
	if not Codec.keys_error(state.targets, KnownSnapshotRules.TARGET_IDS).is_empty() or not Codec.keys_error(state.mechanisms, KnownSnapshotRules.TOOL_IDS).is_empty():
		return "Known L3 transport requires every actual non-Ray target and tool"
	if not is_instance_valid(hero) or not hero.is_inside_tree() or hero.is_queued_for_deletion() or hero.get_world_3d() != get_world_3d():
		return "Known L3 preflight requires its actual bound native Hero"
	var bindings: Dictionary = _scheduler_bindings()
	# Ray pure preflight checks sample correspondence only when supplied feet.
	# Default to the actual receiver, so commit cannot add a late Hero check.
	bindings["hero_positions"] = {"hero": hero.global_position}
	if not saved_player.is_empty():
		# The Shell prevalidates the complete actor first. This pure seam stages
		# only its authoritative feet; it never moves or restores another Hero.
		if not saved_player.get("motion") is Dictionary or not Codec.is_vector3(saved_player.motion.get("position")):
			return "Known L3 staged actor requires the prevalidated saved feet"
		bindings["hero_positions"] = {"hero": Codec.read_vector3(saved_player.motion.position)}
	error = _scheduler.call("snapshot_error", state.scheduler, bindings)
	if not error.is_empty(): return error
	error = _exchange.call("snapshot_error", state.rays, bindings, state.scheduler)
	if not error.is_empty(): return error
	for id: String in KnownSnapshotRules.TARGET_IDS:
		if not state.targets[id] is Dictionary: return "Known L3 target requires its public dictionary"
		error = _actors[id].call("snapshot_error", state.targets[id])
		if not error.is_empty(): return error
	for id: String in KnownSnapshotRules.TOOL_IDS:
		if not state.mechanisms[id] is Dictionary: return "Known L3 tool requires its public dictionary"
		error = _mechanisms[id].call("snapshot_error", state.mechanisms[id], bindings, state.scheduler)
		if not error.is_empty(): return error
		var saved: Dictionary = state.mechanisms[id]
		if int(saved.cycle) > 0:
			var target_id: String = _tool_target(id)
			var actor: Dictionary = state.targets[target_id].actor if target_id == "handling_machine" else state.targets[target_id]
			if saved.exchange.source_position != actor.root_position or saved.exchange.opening_position != actor.root_position or saved.exchange.profile_id != state.profile_id or int(saved.exchange.world_revision) != WORLD_REVISION:
				return "Known L3 executed tool retains its exact actual source/opening/profile/revision"
	error = KnownSnapshotRules.known_state_error(state)
	if not error.is_empty(): return error
	for id: String in state.views:
		var view: Dictionary = state.views[id]
		var admitted = AdmissionEquipment.new()
		if not admitted.restore(view.equipment_ids): return "Known L3 view requires canonical admitted equipment"
		var stats: Dictionary = admitted.resolved_stats()
		if float(view.response_complete_s) != float(view.primary_time_s) + float(stats.primary_cooldown):
			return "Known L3 view retains the full original ordinary-primary cadence"
		var landing: Vector3 = Codec.read_vector3(view.landing)
		var attack: Vector3 = Codec.read_vector3(view.attack_position)
		if not _saved_response_point_supported(landing) or not _saved_response_point_supported(attack):
			return "Known L3 view requires supported actual authored landing and attack points"
		var opening: Vector3 = Codec.read_vector3(state.mechanisms[id].exchange.opening_position)
		if Vector2(attack.x, attack.z).distance_to(Vector2(opening.x, opening.z)) > float(stats.primary_range) - CinderThreatScheduler.SKIN:
			return "Known L3 ordinary primary must reach its retained low opening"
	return ""

func _saved_response_point_supported(point: Vector3) -> bool:
	if not super._saved_response_point_supported(point): return false
	# L2's broad rectangles have no interior wall. L3 adds one actual native
	# Box, so a retained feet/attack point must also clear its measured volume.
	# This is authored static occupancy, not a copied dash solver or movement.
	var wall := get_node_or_null("RuinedHouseDryGround/RuinedHouseLowWall/GroundedWall") as CollisionShape3D
	if not is_instance_valid(wall) or wall.disabled or not wall.shape is BoxShape3D or wall.global_basis != Basis.IDENTITY or wall.global_position != HouseFloor.WALL_AT or (wall.shape as BoxShape3D).size != HouseFloor.WALL_SIZE:
		return false
	var size: Vector3 = (wall.shape as BoxShape3D).size
	var at: Vector3 = wall.global_position
	var feet := Vector2(point.x, point.z)
	var nearest := Vector2(clampf(point.x, at.x - size.x * 0.5, at.x + size.x * 0.5), clampf(point.z, at.z - size.z * 0.5, at.z + size.z * 0.5))
	var radius: float = CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN
	# The rounded capsule clears a Box corner by Euclidean distance. A
	# square-expanded rectangle would reject genuine supported corner feet.
	return feet.distance_squared_to(nearest) > radius * radius

# Private supported-component commit, never a whole CinderLevel restore.
# The shared actor must already be quietly restored by the containing owner.
func _restore_known_state(state: Dictionary) -> String:
	var error: String = _known_snapshot_error(state)
	if not error.is_empty(): return error
	var was_restoring: bool = _restoring
	_restoring = true
	error = _commit_known_state(state)
	_restoring = was_restoring
	return error

func _commit_known_state(state: Dictionary, derive_presentation: bool = true) -> String:
	if not _crossing.call("restore_state", state.sequence): return "Known L3 sequence commit failed"
	_profile_id = state.profile_id
	_scenic_clock = float(state.scenic_clock)
	_last_action_sequence = int(state.last_action_sequence)
	_contact_seen = state.contact_seen
	_pending_checkpoints.assign(state.pending_checkpoints)
	_completion_pending = state.completion_pending
	_exit_requested = state.exit_requested
	_boss_phase_pending = state.boss_phase_pending
	_boss_next_action = state.boss_next_action
	_boss_ready_s = float(state.boss_ready_s)
	_views = state.views.duplicate(true)
	_mechanism_proofs.clear()
	_forecast_points.clear()
	for id: String in KnownSnapshotRules.TARGET_IDS:
		if not _actors[id].call("restore_state", state.targets[id]): return "Known L3 target commit failed " + id
	# The owned Ray exchange restores only its driver/cue state and requires
	# its actual actor already equal to this saved actor. Keep that seventh
	# actor in the same quiet commit before the paired Scheduler/exchange.
	if not _actors.apron_scout.call("restore_state", state.rays.actors.apron_scout): return "Known L3 actual Ray actor commit failed"
	var bindings: Dictionary = _scheduler_bindings()
	if not _scheduler.call("restore_state", state.scheduler, bindings): return "Known L3 Scheduler commit failed"
	if not _exchange.call("restore_state", state.rays, bindings): return "Known L3 Ray commit failed"
	for id: String in KnownSnapshotRules.TOOL_IDS:
		if not _mechanisms[id].call("restore_state", state.mechanisms[id], bindings): return "Known L3 tool commit failed " + id
	if derive_presentation: _derive_restored_presentation()
	return ""

func _derive_restored_presentation() -> void:
	_update_actor_visibility()
	var marker_blocks: Dictionary = {}
	for id: String in _opening_cues:
		marker_blocks[id] = _opening_cues[id].is_blocking_signals()
		_opening_cues[id].set_block_signals(true)
	_update_mechanism_poses()
	for id: String in _clouds: _pose_bank(id, _bank_state(id))
	for id: String in _opening_cues: _opening_cues[id].set_block_signals(marker_blocks[id])
	_apply_tableau()
	_apply_readability()
	_update_objective()
	var blocked: bool = _exit_cue.is_blocking_signals()
	_exit_cue.set_block_signals(true)
	_exit_cue.call("clear")
	if _crossing.call("exit_is_open"): _exit_cue.call("present", "active" if _exit_requested else "available", "contact")
	_exit_cue.set_block_signals(blocked)
	_refresh_smoke_masks()

func _capture_local_state() -> Dictionary:
	var state: Dictionary = _capture_known_state()
	if state.has("error"): return state
	if not _smoke_api_ready or _clouds.size() != 3: return {"error": "Actual L3 requires all three supported banks"}
	var bindings: Dictionary = _scheduler_bindings()
	var banks: Dictionary = {}
	for id: String in BANK_TO_TENDER:
		banks[id] = _clouds[id].call("snapshot_state", bindings)
		if banks[id].is_empty(): return {"error": "L3 bank capture failed " + id + ": " + String(_clouds[id].get("last_snapshot_error"))}
	state["banks"] = banks
	state["bank_views"] = _bank_views.duplicate(true)
	return state

func _known_pack(state: Dictionary) -> Dictionary:
	var known: Dictionary = state.duplicate()
	known.erase("banks")
	known.erase("bank_views")
	return known

func _whole_snapshot_error(state: Dictionary, saved_player: Dictionary = {}) -> String:
	if not _smoke_api_ready or _clouds.size() != 3 or _cloud_art.size() != 3: return "L3 requires its actual supported bank/source/art bindings"
	if not is_instance_valid(_bank_guard) or _bank_guard.get_script() != BankGuard or _bank_guard.get_parent() != self or not _bank_guard.call("binding_matches", Callable(self, "_guard_banks_before_contact")): return "L3 requires its original active native pre-contact presentation guard"
	var error: String = Codec.value_error(state)
	if error.is_empty(): error = Codec.keys_error(state, SmokeSnapshotRules.LOCAL_KEYS)
	if not error.is_empty(): return error
	if not state.banks is Dictionary or not state.bank_views is Dictionary or not Codec.keys_error(state.banks, SmokeSnapshotRules.BANK_IDS).is_empty(): return "L3 requires three complete bank snapshots and their view dictionary"
	if not is_instance_valid(hero): return "L3 requires its actual shared Hero"
	var player: Dictionary = saved_player if not saved_player.is_empty() else hero.snapshot_state()
	if player.is_empty(): return "L3 requires the complete actual or staged saved Player"
	error = hero.snapshot_error(player)
	if not error.is_empty(): return error
	error = _known_snapshot_error(_known_pack(state), player)
	if not error.is_empty(): return error
	var bindings: Dictionary = _scheduler_bindings()
	bindings["hero_positions"] = {"hero": Codec.read_vector3(player.motion.position)}
	for id: String in BANK_TO_TENDER:
		var bank: Node3D = _clouds.get(id)
		var art: Node3D = _cloud_art.get(id)
		if not is_instance_valid(bank) or not is_instance_valid(art) or bank.get_script() != SmokeBank or art.get_script() != SmokeVisual or bank.get_parent() != self or art.get_parent() != self or art.position != HouseSequence.CLOUDS[id] or art.basis != Basis.IDENTITY or not state.banks[id] is Dictionary:
			return "L3 requires original independent native bank and cosmetic source " + id
		error = bank.call("snapshot_error", state.banks[id], bindings, state.scheduler, player)
		if not error.is_empty(): return id + ": " + error
	error = SmokeSnapshotRules.smoke_state_error(state)
	if not error.is_empty(): return error
	for id: String in state.bank_views:
		var view: Dictionary = state.bank_views[id]
		var admitted = AdmissionEquipment.new()
		if not admitted.restore(view.equipment_ids): return "L3 bank view requires canonical original admitted gear"
		var stats: Dictionary = admitted.resolved_stats()
		if float(view.response_complete_s) != float(view.primary_time_s) + float(stats.primary_cooldown): return "L3 bank view retains the full original ordinary-primary cadence"
		var landing: Vector3 = Codec.read_vector3(view.landing)
		var attack: Vector3 = Codec.read_vector3(view.attack_position)
		var opening: Vector3 = Codec.read_vector3(state.banks[id].exchange.opening_position)
		if not _saved_response_point_supported(landing) or not _saved_response_point_supported(attack): return "L3 bank view requires supported actual dry landing and return"
		if Vector2(attack.x, attack.z).distance_to(Vector2(opening.x, opening.z)) > float(stats.primary_range) - CinderThreatScheduler.SKIN: return "L3 bank response must reach the original low Tender mount"
		var ray := PhysicsRayQueryParameters3D.create(attack + Vector3.UP * CinderPlayer.ATTACK_LOS_HEIGHT, opening + Vector3.UP * CinderPlayer.ATTACK_LOS_HEIGHT, CinderPlayer.ATTACK_SCENERY_MASK)
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return "L3 bank response requires actual clear primary sight to its anchored mount"
	return ""

func _local_snapshot_error(state: Dictionary) -> String:
	return _whole_snapshot_error(state)

func _local_snapshot_error_with_player(state: Dictionary, saved_player: Dictionary) -> String:
	return _whole_snapshot_error(state, saved_player)

func _local_snapshot_error_for_bindings(state: Dictionary, _bindings: Dictionary) -> String:
	return _whole_snapshot_error(state)

func _progress_snapshot_error(state: Dictionary) -> String:
	return SmokeSnapshotRules.progress_error(state)

func _restore_local_state(state: Dictionary) -> void:
	# CinderLevel and Shell have prevalidated the complete pack and restored
	# actual Player first. No yield or gameplay observer enters this commit.
	var error: String = _commit_known_state(_known_pack(state), false)
	if not error.is_empty(): runtime_error = error; return
	_bank_views = state.bank_views.duplicate(true)
	_bank_proofs.clear()
	var bindings: Dictionary = _scheduler_bindings()
	for id: String in BANK_TO_TENDER:
		if not _clouds[id].call("restore_state", state.banks[id], bindings):
			runtime_error = "L3 actual bank commit failed " + id + ": " + String(_clouds[id].get("last_snapshot_error"))
			return
	for id: String in BANK_TO_TENDER: _remember_bank_cue(id)
	_derive_restored_presentation()

func _on_hero_died() -> void:
	super._on_hero_died()
	# Retire original banks through their public API; preserve bounded receipts
	# and cooldowns for the actual same-tick fatal checkpoint.
	for id: String in _clouds:
		if _clouds[id].call("state").status == "running": _clouds[id].call("cancel", "hero_defeated")
	_bank_views.clear()
	_bank_proofs.clear()
	_forecast_points.clear()
	for id: String in _clouds: _pose_bank(id, _bank_state(id))

func _on_exit_level() -> void:
	if is_instance_valid(_bank_guard): _bank_guard.set_physics_process(false)
	_bank_cue_bytes.clear()
	if RenderingServer.frame_pre_draw.is_connected(_refresh_smoke_masks): RenderingServer.frame_pre_draw.disconnect(_refresh_smoke_masks)
	for id: String in _clouds:
		if is_instance_valid(_clouds[id]): _clouds[id].call("cancel", "l3_exit")
	_bank_views.clear()
	_bank_proofs.clear()
	super._on_exit_level()
	_forecast_points.clear()
	_boss_phase_pending = false
