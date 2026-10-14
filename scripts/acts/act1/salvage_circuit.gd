extends CinderLevel
## SOURCE ONLY. Independent optional FSM over the existing native C30/Lane
## leaves. One shared Hero/Scheduler/clock/controller; contact parts are finite.
## Layout, source placement and camera feasibility are unexecuted hypotheses.

signal native_admission_published(source_id: String, answer: Dictionary)
signal part_collected(part_id: String, actual_order: Array[String])

const Layout = preload("res://scripts/acts/act1/salvage_circuit_layout.gd")
const LocalCodec = preload("res://scripts/acts/act1/salvage_circuit_codec.gd")
const Rusher = preload("res://scripts/acts/act1/rush_selenite.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const BodySweep = preload("res://scripts/combat/body_sweep.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const WORLD_REVISION: int = 1
const LOOKAHEAD: float = 4.5
const CIRCUIT_RECOVERY_S: float = 3.4 # Exact existing L2 rock/open role/floor.
const CIRCUIT_EPOCH: String = "salvage-circuit-encounter"
const FINAL_EPOCH: String = "salvage-final-encounter"
const COMPOUND_REFUSAL: String = "compound_response_outside_rusher_recovery"

var stage: String = "circuit"
var collected_ids: Array[String] = []
var checkpoint_published: bool = false
var final_started: bool = false
var final_defeated: bool = false
var scheduler: CinderThreatScheduler
var sources: Dictionary = {}
var circuit: Act1RushSelenite
var final_rusher: Act1RushSelenite
var impact: CinderLaneMechanism
var parts: Dictionary = {}
var hatch: Area3D
var hatch_cue: CinderInteractionCue
var scenery: Node3D
var last_encounter_error: String = ""
var last_admission: Dictionary = {}
var last_capture_error: String = ""

var _running: bool = false
var _quiet_commit: bool = false
var _quiet_error: String = ""
var _construction_error: String = ""
var _publishing: bool = false
var _callback_depth: int = 0
var _collecting_id: String = ""
var _parts_ready_pending: bool = false
var _final_clear_pending: bool = false
var _contact_pending: bool = false
var _settle_queued: bool = false
var _activation_entitlement: String = ""
var _frames: Dictionary = {}
var _impact_host: Dictionary = {}
var _forecast: Array = []
var _forecast_hero: Transform3D
var _pending_start: Dictionary = {}
var _floor: CollisionShape3D
var _floor_shape: BoxShape3D
var _floor_frame: Transform3D
var _hatch_collision: CollisionShape3D
var _hatch_shape: BoxShape3D
var _hatch_frame: Transform3D
var _retained: Dictionary = {}
var _part_callbacks: Dictionary = {}
var _part_contacts: Dictionary = {}
var _part_cues: Dictionary = {}
var _part_shapes: Dictionary = {}
var _part_meshes: Dictionary = {}
var _capture_camera: Camera3D
var _capture_hud: GameHUD


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 200
	var built: Dictionary = Layout.build_geometry(self)
	if built.is_empty(): _construction_error = "Actual salvage layout construction failed"; return
	_floor = built.floor_collision; _floor_shape = _floor.shape as BoxShape3D; _floor_frame = _floor.global_transform
	parts = built.parts; hatch = built.hatch; _hatch_collision = built.hatch_collision
	_hatch_shape = _hatch_collision.shape as BoxShape3D; _hatch_frame = hatch.global_transform
	hatch_cue = built.hatch_cue; scenery = built.scenery
	if not _floor_error().is_empty(): _construction_error = _floor_error(); return
	scheduler = CinderThreatScheduler.new(); scheduler.name = "SalvageThreatScheduler"; add_child(scheduler)
	for id: String in [Layout.CIRCUIT_SOURCE_ID, Layout.FINAL_SOURCE_ID]:
		var actor: Act1RushSelenite = Rusher.new(); actor.name = id
		actor.position = Layout.CIRCUIT_SOURCE_POSITION if id == Layout.CIRCUIT_SOURCE_ID else Layout.FINAL_SOURCE_POSITION
		var raw: Dictionary = Rusher.DEFAULT_RAW_ROLE.duplicate(true)
		var floors: Dictionary = Rusher.DEFAULT_TIMING_FLOORS.duplicate(true)
		if id == Layout.CIRCUIT_SOURCE_ID: raw.recovery_s = CIRCUIT_RECOVERY_S; floors.recovery_s = CIRCUIT_RECOVERY_S
		if not actor.configure(id, raw, floors, Rusher.DEFAULT_LUNGE, id == Layout.FINAL_SOURCE_ID):
			_construction_error = actor.last_error; actor.free(); return
		add_child(actor); sources[id] = actor; _retained[id] = actor
		actor.activation_guard = Callable(self, "_activation_permitted")
		actor.presentation_guard = Callable(self, "_source_presentation_error").bind(id)
	circuit = sources[Layout.CIRCUIT_SOURCE_ID]; final_rusher = sources[Layout.FINAL_SOURCE_ID]
	impact = CinderLaneMechanism.new(); impact.name = Layout.IMPACT_ID; impact.position = Layout.IMPACT_POSITION
	if not impact.configure(Layout.IMPACT_ID, Geometry.circle(Layout.IMPACT_POSITION, Layout.IMPACT_RADIUS), Layout.CIRCUIT_SOURCE_POSITION):
		_construction_error = impact.last_error; impact.free(); return
	add_child(impact)
	_retained[Layout.IMPACT_ID] = impact; _retained["scheduler"] = scheduler; _retained["scenery"] = scenery
	for id: String in Layout.PART_IDS:
		var part: Node3D = parts[id]; var area: Area3D = part.call("contact_area")
		var collision: CollisionShape3D = part.call("contact_collision")
		_part_contacts[id] = area; _part_shapes[id] = collision.shape; _part_cues[id] = part.call("get_cue")
		_part_meshes[id] = _part_mesh_signature(part)
		var callback: Callable = Callable(self, "_part_contact").bind(id)
		area.body_entered.connect(callback); _part_callbacks[id] = callback
	hatch.body_entered.connect(_hatch_contact)


func contract_error() -> String:
	return _construction_error if not _construction_error.is_empty() else super.contract_error()


func restore_candidate_physics_registration_required() -> bool:
	return true # Actual immutable query floor is present in _ready.


func restore_candidate_construction_required() -> bool:
	return true


func _bind_level() -> String:
	if not _construction_error.is_empty(): return _construction_error
	for id: String in sources:
		var actor: Act1RushSelenite = sources[id]
		if not actor.bind(scheduler, hero): return actor.last_error
		actor.state_changed.connect(_on_source_state); actor.defeated.connect(_on_source_defeated)
	if not impact.bind(scheduler, {"hero": hero}) or not impact.set_presentation_guard(Callable(self, "_impact_presentation")): return impact.last_error
	impact.state_changed.connect(_on_source_state); hero.died.connect(_on_hero_died)
	_running = true; _sync_presentation(false)
	return _runtime_error()


func _on_enter_level() -> void:
	_construction_error = _bind_level()
	if not _construction_error.is_empty(): _running = false; return
	if not scheduler.begin_encounter(_selected_profile(), CIRCUIT_EPOCH, WORLD_REVISION): _construction_error = scheduler.last_error; _running = false


func _on_enter_restore_candidate(_local: Dictionary, _saved_player: Dictionary) -> String:
	return _bind_level() # No begin/activation/sample/progress/clock reconstruction.


func _selected_profile() -> String:
	return String(shared_shell.call("get_difficulty_preference")) if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference") else "standard"


func _physics_process(_delta: float) -> void:
	if not _running or _quiet_commit or not is_instance_valid(hero): return
	_prune_frames(); _sync_presentation()
	if hero.dead: return
	if stage == "circuit":
		for id: String in Layout.PART_IDS:
			if not collected_ids.has(id) and (_part_contacts[id] as Area3D).overlaps_body(hero): _collect_part(id)
		if _parts_ready_pending: _queue_settle(); return
		if not circuit.dead: _attack_tick(circuit)
	elif stage == "final":
		if _final_clear_pending or final_rusher.dead: _final_clear_pending = true; _queue_settle(); return
		if not final_started:
			if hero.get_threat_response_state().stable and hero.global_position.distance_to(final_rusher.global_position) <= LOOKAHEAD:
				_begin_final()
		elif not final_rusher.dead: _attack_tick(final_rusher)
	elif stage == "hatch" and hatch.overlaps_body(hero): _hatch_contact(hero)


func _part_contact(body: Node3D, id: String) -> void:
	if body == hero and _running and stage == "circuit" and not hero.dead and not collected_ids.has(id):
		# Native overlap itself is re-read by the late parent tick. No free/save
		# or synchronous gameplay mutation occurs inside the Area emitter.
		pass


func _collect_part(id: String) -> void:
	if stage != "circuit" or collected_ids.has(id) or hero.dead or get_tree().paused or not (_part_contacts[id] as Area3D).overlaps_body(hero): return
	var part: Node3D = parts[id]; var cue: CinderInteractionCue = part.call("get_cue")
	if cue.state().state != "available" or not _framing_ready(_part_points(id)): return
	_collecting_id = id; collected_ids.append(id) # Consume before all observers.
	part.call("set_state", "active"); cue.present("active", "contact")
	_callback_depth += 1; part_collected.emit(id, collected_ids.duplicate()); _callback_depth -= 1
	part.call("set_state", "spent"); cue.present("spent", "contact"); _collecting_id = ""
	if collected_ids.size() == Layout.PART_IDS.size(): _parts_ready_pending = true; _queue_settle()
	_refresh_objective()


func _queue_settle() -> void:
	if not _settle_queued: _settle_queued = true; _settle_progress.call_deferred()


func _settle_progress() -> void:
	_settle_queued = false
	if not _running or _quiet_commit or not is_instance_valid(hero) or hero.dead: return
	if _parts_ready_pending:
		# Last contact has completed, with its actual source/Player callbacks over.
		circuit.cancel("salvage_parts_collected")
		if impact.state().status == "running": impact.cancel("salvage_parts_collected")
		_frames.clear(); _forecast.clear(); _pending_start.clear()
		stage = "final"; checkpoint_published = true; _parts_ready_pending = false
		_sync_presentation(); _publishing = true
		if not request_checkpoint(Layout.CHECKPOINT_ID, "encounter"): _construction_error = "Genuine three-part checkpoint was refused"
		_publishing = false
	if _final_clear_pending:
		if not final_rusher.dead: return
		if impact.state().status == "running": impact.cancel("final_source_defeated")
		_frames.clear(); _forecast.clear(); _pending_start.clear()
		final_defeated = true; stage = "hatch"; _final_clear_pending = false; _sync_presentation()
	if _contact_pending:
		_contact_pending = false
		if stage != "hatch" or not hatch.overlaps_body(hero) or not _framing_ready(_hatch_points()): return
		stage = "departed"; _sync_presentation(); _publishing = true
		if request_completion(Layout.COMPLETION_ID): request_contact_exit(Layout.HATCH_EXIT_ID, hero)
		else: _construction_error = "Genuine repaired-hatch completion was refused"
		_publishing = false


func _begin_final() -> void:
	if not checkpoint_published or final_started or _parts_ready_pending or get_tree().paused: return
	if scheduler.has_committed_exchange(): return
	# This is a real new boundary; cancelled circuit history is kept in packets.
	scheduler.end_encounter("salvage_final_boundary")
	if not scheduler.begin_encounter(_selected_profile(), FINAL_EPOCH, WORLD_REVISION): last_encounter_error = scheduler.last_error; return
	_activation_entitlement = Layout.FINAL_SOURCE_ID
	var accepted: bool = final_rusher.activate(); _activation_entitlement = ""
	if not accepted: _construction_error = final_rusher.last_error; return
	final_started = true; _sync_presentation()


func _activation_permitted(id: String) -> bool:
	return _running and not _quiet_commit and stage == "final" and checkpoint_published and not final_started and id == Layout.FINAL_SOURCE_ID and _activation_entitlement == id


func _attack_tick(actor: Act1RushSelenite) -> void:
	var state: Dictionary = actor.state()
	if state.reservation_id.is_empty():
		if not hero.get_threat_response_state().stable or state.hurt_left_s > 0.0: return
		var direction: Vector3 = hero.global_position - actor.global_position; direction.y = 0
		if direction.length() < 0.1 or direction.length() > LOOKAHEAD: return
		var preview: Dictionary = actor.preview_lunge(response_context(), direction.normalized(), _world_root())
		if not _prepare_forecast(String(actor.name), preview): return
		_finish_admission(String(actor.name), actor.start(response_context(), direction.normalized(), _world_root(), preview))
	elif actor == circuit and state.phase in ["lock", "active", "recovery"]: _compound_impact(state)


func _compound_impact(host: Dictionary) -> void:
	if not hero.get_threat_response_state().stable or impact.state().status == "running" or _impact_host.get("host_reservation_id", "") == host.reservation_id: return
	var preview: Dictionary = impact.preview_start("hero", response_context(), host.opening_position)
	if not preview.get("accepted", false): last_encounter_error = String(preview.get("reason", "Impact preview refused")); return
	if not _proof_window(preview.proof, host): last_encounter_error = "Current companion proof lacks genuine rusher recovery"; return
	if not _prepare_forecast(Layout.IMPACT_ID, preview): return
	var answer: Dictionary = impact.start("hero", response_context(), host.opening_position, null, preview)
	if answer.get("accepted", false):
		var supported: bool = _proof_window(answer.proof, host)
		_impact_host = {"host_id": Layout.CIRCUIT_SOURCE_ID, "host_cycle": int(host.cycle), "host_reservation_id": String(host.reservation_id), "host_start_s": float(host.start_s), "host_active_until_s": float(host.active_until_s), "host_recovery_until_s": float(host.recovery_until_s), "opening_position": host.opening_position, "primary_time_s": float(answer.proof.primary_time_s), "response_complete_s": float(answer.proof.response_complete_s), "supported": supported}
		if not supported:
			impact.cancel(COMPOUND_REFUSAL); circuit.cancel(COMPOUND_REFUSAL)
			_pending_start.clear(); _forecast.clear(); last_encounter_error = COMPOUND_REFUSAL; return
	_finish_admission(Layout.IMPACT_ID, answer)


func _proof_window(proof: Dictionary, host: Dictionary) -> bool:
	return not proof.uses_blast and not proof.uses_invulnerability and proof.primary_time_s >= host.active_until_s and proof.response_complete_s < host.recovery_until_s


func _prepare_forecast(id: String, preview: Dictionary) -> bool:
	if not preview.get("accepted", false): last_encounter_error = String(preview.get("reason", "Native preview refused")); return false
	_forecast = _source_points(id, preview.candidate.opening_position)
	_forecast.append_array(_geometry_points(preview.candidate.geometry)); _forecast.append_array(_response_points(preview.proof.landing, preview.proof.attack_position))
	_forecast_hero = hero.global_transform; _pending_start = {"source_id": id, "proof": preview.proof.duplicate(true)}
	if not _framing_ready(_camera_framing_points()): _pending_start.clear(); return false
	return true


func _finish_admission(id: String, answer: Dictionary) -> void:
	if answer.get("accepted", false):
		_frames[id] = {"reservation_id": String(answer.reservation_id), "proof": answer.proof.duplicate(true)}
		if not _framing_ready(_camera_framing_points(false)): _source(id).call("cancel", "complete_response_not_visible"); _frames.erase(id)
		else:
			_callback_depth += 1; native_admission_published.emit(id, answer.duplicate(true)); _callback_depth -= 1
	else: last_encounter_error = String(answer.get("reason", "Actual native admission refused"))
	last_admission = answer.duplicate(true); _pending_start.clear(); _forecast.clear()


func _on_source_state(_value: Dictionary) -> void:
	if _running and not _quiet_commit: _prune_frames()


func _on_source_defeated(id: String) -> void:
	if not _running or _quiet_commit: return
	if id == Layout.CIRCUIT_SOURCE_ID and impact.state().status == "running": impact.cancel("circuit_source_defeated")
	if id == Layout.FINAL_SOURCE_ID: _final_clear_pending = true; _queue_settle()


func _on_hero_died() -> void:
	if not _running or _quiet_commit: return
	for actor: Act1RushSelenite in sources.values(): actor.cancel("hero_defeated")
	if impact.state().status == "running": impact.cancel("hero_defeated")
	_frames.clear(); _forecast.clear(); _pending_start.clear(); _sync_presentation()


func _hatch_contact(body: Node3D) -> void:
	if body != hero or not _running or _quiet_commit or stage != "hatch" or hero.dead or get_tree().paused or not hatch.overlaps_body(hero): return
	if hatch_cue.state().state != "available" or not _framing_ready(_hatch_points()): return
	_contact_pending = true; _queue_settle()


func request_checkpoint(id: String, kind: String = "encounter") -> bool:
	if not _publishing or stage != "final" or not checkpoint_published or final_started or id != Layout.CHECKPOINT_ID or kind != "encounter": return false
	return super.request_checkpoint(id, kind)


func request_completion(id: String = "complete") -> bool:
	if not _publishing or stage != "departed" or not final_defeated or collected_ids.size() != 3 or id != Layout.COMPLETION_ID: return false
	return super.request_completion(id)


func request_contact_exit(id: String, body: Node3D) -> bool:
	if not _publishing or stage != "departed" or body != hero or id != Layout.HATCH_EXIT_ID or not hatch.overlaps_body(body): return false
	return super.request_contact_exit(id, body)


func _sync_presentation(notify: bool = true) -> void:
	if not is_instance_valid(scenery) or not is_instance_valid(hero): return
	var camera: Camera3D = _actual_camera()
	if camera == null or not scenery.call("set_presentation_camera", camera) or not scenery.call("set_repaired", checkpoint_published): _construction_error = "Actual salvage presentation refused its retained camera/state"; return
	for id: String in Layout.PART_IDS:
		var state: String = "active" if _collecting_id == id else ("spent" if collected_ids.has(id) else "available")
		var part: Node3D = parts[id]; part.call("set_state", state); _cue_state(part.call("get_cue"), state, notify)
	_cue_state(hatch_cue, "available" if stage == "hatch" else ("spent" if stage == "departed" else "clear"), notify)
	_refresh_objective()


func _cue_state(cue: CinderInteractionCue, state: String, notify: bool) -> void:
	var blocked: bool = cue.is_blocking_signals()
	if not notify: cue.set_block_signals(true)
	if state == "clear": cue.clear()
	else: cue.present(state, "contact")
	if not notify: cue.set_block_signals(blocked)


func _refresh_objective() -> void:
	if stage == "circuit": objective_text = "SALVAGE · %d / 3 PARTS\nCONTACT THEM IN ANY ORDER · KEEP A RETURN LANDING" % collected_ids.size()
	elif stage == "final": objective_text = "CAPSULE REPAIRED · FAMILIAR RUSHER\nREAD ITS COMMITMENT · AIM AN ORDINARY PRIMARY"
	elif stage == "hatch": objective_text = "REPAIRED HATCH AVAILABLE\nSWIPE INTO THE CONTACT CHEVRON"
	else: objective_text = "SALVAGE CIRCUIT COMPLETE"


func encounter_state() -> Dictionary:
	return {"stage": stage, "collected_ids": collected_ids.duplicate(), "checkpoint_published": checkpoint_published, "final_started": final_started, "final_defeated": final_defeated, "impact_host": _encode(_impact_host)}


func floor_region() -> Dictionary:
	return {"collision": _floor, "safe_rect": Layout.SAFE_RECT}


func scheduler_bindings() -> Dictionary:
	var owners: Dictionary = sources.duplicate(); owners[Layout.IMPACT_ID] = impact
	return {"world_root": _world_root(), "owners": owners, "floors": {"salvage-floor": floor_region()}}


func response_context() -> Dictionary:
	var directions: Array[Vector3] = []
	for index: int in 16: directions.append(Vector3(cos(float(index) * TAU / 16.0), 0, sin(float(index) * TAU / 16.0)))
	return {"encounter_id": FINAL_EPOCH if final_started else CIRCUIT_EPOCH, "world_revision": WORLD_REVISION, "recognition_s": 0.18, "attack_input_margin_s": 0.08, "escape_directions": directions, "return_directions": directions, "floor_regions": [floor_region()]}


func _world_root() -> Node3D:
	if not is_instance_valid(hero) or not is_inside_tree(): return null
	var ancestor: Node = get_parent()
	while is_instance_valid(ancestor):
		if ancestor is Node3D and ancestor.is_ancestor_of(hero) and ancestor.is_ancestor_of(self) and (ancestor as Node3D).get_world_3d() == get_world_3d(): return ancestor as Node3D
		ancestor = ancestor.get_parent()
	return null


func _actual_camera() -> Camera3D:
	return _capture_camera if is_instance_valid(_capture_camera) else (get_viewport().get_camera_3d() if is_inside_tree() else null)


func _source(id: String) -> Node3D:
	return impact if id == Layout.IMPACT_ID else sources.get(id) as Node3D


func _live_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for id: String in [Layout.CIRCUIT_SOURCE_ID, Layout.FINAL_SOURCE_ID, Layout.IMPACT_ID]:
		for record: Dictionary in scheduler.source_control_state(_source(id)).get("reservations", []):
			var copy: Dictionary = record.duplicate(true); copy["source_id"] = id; records.append(copy)
	return records


func _prune_frames() -> void:
	var ids: Array = []
	for record: Dictionary in _live_records(): ids.append(record.source_id)
	for id: String in _frames.keys():
		if not ids.has(id): _frames.erase(id)


func _source_presentation_error(id: String) -> String:
	return "Actual complete salvage source/footprint/response is not visible" if not _source_guard(id) else ""


func _impact_presentation(id: String, _state: Dictionary) -> bool:
	return id == Layout.IMPACT_ID and _source_guard(id)


func _source_guard(id: String) -> bool:
	if not _running or _quiet_commit or hero.dead or get_tree().paused or not _runtime_error().is_empty(): return false
	for record: Dictionary in _live_records():
		if record.source_id != id: continue
		var frame: Dictionary = _frames.get(id, {})
		if frame.is_empty() and _pending_start.get("source_id", "") == id: frame = _pending_start
		if frame.is_empty() or not frame.get("proof") is Dictionary or (frame.has("reservation_id") and frame.reservation_id != record.id): return false
		if frame.proof.primary_time_s < record.active_until_s or frame.proof.response_complete_s >= record.recovery_until_s: return false
	return _framing_error(_camera_framing_points(false)).is_empty()


func _camera_framing_points(include_forecast: bool = true) -> Array:
	if not is_instance_valid(hero) or not _floor_error().is_empty(): return [Vector3.INF]
	var points: Array = []
	for record: Dictionary in _live_records():
		points.append_array(_source_points(record.source_id, record.opening_position)); points.append_array(_geometry_points(record.geometry))
		points.append_array(_mesh_bounds(_source(record.source_id).call("get_cue")))
		var frame: Dictionary = _frames.get(record.source_id, {})
		if frame.is_empty() and _pending_start.get("source_id", "") == record.source_id: frame = _pending_start
		if not frame.is_empty(): points.append_array(_response_points(frame.proof.landing, frame.proof.attack_position))
	for id: String in Layout.PART_IDS:
		if hero.global_position.distance_to((parts[id] as Node3D).global_position) <= LOOKAHEAD: points.append_array(_part_points(id))
	if hero.global_position.distance_to(Layout.HATCH_POSITION) <= LOOKAHEAD or stage in ["hatch", "departed"]: points.append_array(_hatch_points())
	var actor: Act1RushSelenite = circuit if stage == "circuit" else final_rusher
	if is_instance_valid(actor) and not actor.dead and not actor.dormant and hero.global_position.distance_to(actor.global_position) <= LOOKAHEAD: points.append_array(_source_points(String(actor.name), actor.global_position))
	if include_forecast and not _forecast.is_empty() and hero.global_transform == _forecast_hero: points.append_array(_forecast)
	var dash: Dictionary = hero.get_committed_dash_state()
	if dash.get("active", false):
		var endpoint: Vector3 = dash.origin + dash.direction * float(dash.distance)
		for point: Vector3 in _hero_points(): points.append(point + endpoint - hero.global_position)
	return _unique(points)


func _hero_points() -> Array:
	return shared_shell.call("player_camera_framing_points_for", hero, _actual_camera()) if is_instance_valid(shared_shell) else []


func _source_points(id: String, opening: Vector3) -> Array:
	if id == Layout.IMPACT_ID: return _geometry_points(Geometry.circle(Layout.IMPACT_POSITION, Layout.IMPACT_RADIUS))
	var actor: Act1RushSelenite = sources.get(id) as Act1RushSelenite
	if not is_instance_valid(actor) or not actor.art_binding_error().is_empty(): return [Vector3.INF]
	var collision := actor.get_node_or_null("BodyCollision") as CollisionShape3D
	if collision == null or not collision.shape is CapsuleShape3D: return [Vector3.INF]
	if _actual_camera() == null or _actual_camera().global_basis != (shared_shell.get("camera") as Camera3D).global_basis: return [Vector3.INF]
	var points: Array = _box_points(collision.shape.get_debug_mesh().get_aabb(), collision.global_transform)
	for node: Node in actor.get_art().find_children("*", "Sprite3D", true, false):
		if node.is_visible_in_tree(): points.append_array(shared_shell.call("camera_billboard_points", node))
	var future: Array = points.duplicate()
	for point: Vector3 in future: points.append(point + opening - actor.global_position)
	return _bounds_points(points)


func _part_points(id: String) -> Array:
	if not parts.has(id) or _part_mesh_signature(parts[id]) != _part_meshes.get(id): return [Vector3.INF]
	return _bounds_points(parts[id].call("world_corners"))


func _hatch_points() -> Array:
	var points: Array = _bounds_points(scenery.call("capsule_world_corners"))
	points.append_array(_box_points(AABB(-Layout.HATCH_CONTACT_SIZE * 0.5, Layout.HATCH_CONTACT_SIZE), _hatch_collision.global_transform))
	points.append_array(_mesh_bounds(hatch_cue)); return _unique(points)


func _mesh_bounds(node: Node3D) -> Array:
	if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion(): return [Vector3.INF]
	var points: Array = []
	for child: Node in node.find_children("*", "MeshInstance3D", true, false):
		if child.is_visible_in_tree() and child.mesh != null: points.append_array(_box_points(child.get_aabb(), child.global_transform))
	return _bounds_points(points)


func _geometry_points(shape: Dictionary) -> Array:
	if not Geometry.error(shape).is_empty() or shape.kind not in ["lane", "circle"]: return [Vector3.INF]
	var radius: float = float(shape.radius); var points: Array = []
	var origins: Array = [shape.origin] if shape.kind == "circle" else [shape["from"], shape["to"]]
	for origin: Vector3 in origins: points.append_array(_box_points(AABB(Vector3(-radius, 0, -radius), Vector3(radius * 2, 0.08, radius * 2)), Transform3D(Basis.IDENTITY, origin)))
	return _unique(points)


func _response_points(landing: Vector3, attack: Vector3) -> Array:
	var actual: Array = _hero_points()
	if actual.is_empty(): return [Vector3.INF]
	var points: Array = []
	for point: Vector3 in actual: points.append(point + landing - hero.global_position); points.append(point + attack - hero.global_position)
	return _bounds_points(points) # Complete native AABB; no extent is dropped.


func _framing_error(points: Array) -> String:
	if points.is_empty() or points.has(Vector3.INF) or points.size() > 224 or not is_instance_valid(shared_shell): return "Complete actual bounded salvage points required"
	var camera: Camera3D = _actual_camera()
	var plan: Dictionary = shared_shell.call("camera_framing_plan_for_context", points, hero.global_position + Vector3.UP * 0.65, hero, camera, _capture_hud) if is_instance_valid(_capture_hud) else shared_shell.call("camera_framing_plan", points, hero.global_position + Vector3.UP * 0.65)
	if not plan.get("accepted", false): return String(plan.get("reason", "Current plan refused"))
	return String(shared_shell.call("camera_framing_error_for_context", points, hero, camera, _capture_hud)) if is_instance_valid(_capture_hud) else String(shared_shell.call("camera_framing_error", points))


func _framing_ready(points: Array) -> bool:
	last_encounter_error = _framing_error(points); return last_encounter_error.is_empty()


func _floor_error() -> String:
	if not is_instance_valid(_floor) or _floor != get_node_or_null("Floor/CollisionShape3D") or _floor.shape != _floor_shape or _floor.disabled or _floor.global_transform != _floor_frame or _floor_shape.size != Layout.FLOOR_SIZE: return "Retained actual salvage floor changed"
	var body := _floor.get_parent() as StaticBody3D
	if body == null or body.position != Layout.FLOOR_CENTRE or body.collision_layer != 1 or body.collision_mask != 0: return "Immutable actual salvage support body required"
	return ""


func _runtime_error() -> String:
	if not _construction_error.is_empty(): return _construction_error
	var error: String = _floor_error()
	if not error.is_empty(): return error
	if global_transform != Transform3D.IDENTITY or _world_root() == null or not is_instance_valid(hero) or hero.get_world_3d() != get_world_3d(): return "One actual shared world and Hero required"
	for id: String in _retained:
		var node: Node = _retained[id]
		if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion() or node.get_parent() != self: return "Retained salvage native node lost: " + id
	for id: String in sources:
		var actor: Act1RushSelenite = sources[id]
		if actor != _retained[id] or not actor.art_binding_error().is_empty(): return "Original native C30 body/art required"
	if scheduler != _retained.scheduler or impact != _retained[Layout.IMPACT_ID] or impact.global_position != Layout.IMPACT_POSITION: return "Original Scheduler/impact bindings required"
	if not is_instance_valid(hatch) or hatch != get_node_or_null("HatchContact") or hatch.global_transform != _hatch_frame or _hatch_collision.get_parent() != hatch or _hatch_collision.transform != Transform3D.IDENTITY or not hatch.monitoring or _hatch_collision.shape != _hatch_shape or _hatch_shape.size != Layout.HATCH_CONTACT_SIZE or _hatch_collision.disabled or hatch.collision_layer != 0 or hatch.collision_mask != 4: return "Actual retained hatch Area/collision required"
	var hatch_state: String = "available" if stage == "hatch" else ("spent" if stage == "departed" else "clear")
	if hatch_cue != hatch.get_node_or_null("HatchInteractionCue") or hatch_cue.get_parent() != hatch or hatch_cue.position != Vector3(0, -0.65, 0) or not _interaction_error(hatch_cue, hatch_state).is_empty(): return "Actual hatch contact cue disagrees with current stage"
	for id: String in Layout.PART_IDS:
		var part: Node3D = parts[id]; var area: Area3D = part.call("contact_area"); var collision: CollisionShape3D = part.call("contact_collision")
		if part != get_node_or_null("Parts/" + id) or part.position != Layout.PART_POSITIONS[id] or part.basis != Basis.IDENTITY or area != _part_contacts[id] or not area.monitoring or area.collision_layer != 0 or area.collision_mask != 4 or area.position != Vector3(0, 0.6, 0) or area.basis != Basis.IDENTITY or collision.shape != _part_shapes[id] or not collision.shape is BoxShape3D or (collision.shape as BoxShape3D).size != Vector3(0.9, 1.2, 0.9) or collision.transform != Transform3D.IDENTITY or collision.disabled or collision.get_parent() != area or area.get_parent() != part: return "Actual finite part/contact geometry and identity changed"
		if _part_mesh_signature(part) != _part_meshes[id]: return "Actual retained fragment geometry changed"
		var state: String = "active" if _collecting_id == id else ("spent" if collected_ids.has(id) else "available")
		var cue: CinderInteractionCue = part.call("get_cue")
		if cue != _part_cues[id] or cue.get_parent() != part or cue.position != Vector3.ZERO or not _interaction_error(cue, state).is_empty() or part.call("presentation_state").state != state or part.call("presentation_state").fragment_visible != (state != "spent"): return "Part/cue state disagrees with actual collection history"
	if scenery.call("presentation_state").repaired != checkpoint_published: return "Repaired art must follow genuine three-part checkpoint"
	return _quiet_error


func _part_mesh_signature(part: Node3D) -> String:
	if not is_instance_valid(part): return ""
	var rows: Array = []
	var art: Node3D = part.get_node_or_null("FragmentPresentation")
	if art == null: return ""
	rows.append({"art_id": str(art.get_instance_id()), "parent_id": str(art.get_parent().get_instance_id()), "transform": _encode_transform(art.transform)})
	for node: Node in art.find_children("*", "MeshInstance3D", true, false):
		if node.mesh == null: return ""
		rows.append({"node": str(node.get_instance_id()), "parent": str(node.get_parent().get_instance_id()), "mesh": str(node.mesh.get_instance_id()), "bounds": _encode_bounds(node.get_aabb()), "transform": _encode_transform(node.transform), "visible": node.visible, "material": _material_signature(node.material_override)})
	return Exact.stringify(rows)


func _on_exit_level() -> void:
	_running = false; _parts_ready_pending = false; _final_clear_pending = false; _contact_pending = false; _settle_queued = false
	_frames.clear(); _forecast.clear(); _pending_start.clear(); _activation_entitlement = ""
	if is_instance_valid(hero) and hero.died.is_connected(_on_hero_died): hero.died.disconnect(_on_hero_died)
	for actor: Act1RushSelenite in sources.values():
		if actor.state_changed.is_connected(_on_source_state): actor.state_changed.disconnect(_on_source_state)
		if actor.defeated.is_connected(_on_source_defeated): actor.defeated.disconnect(_on_source_defeated)
		actor.cancel("salvage_level_exit"); actor.remove_from_group("enemies"); actor.set_physics_process(false)
	if is_instance_valid(impact):
		if impact.state_changed.is_connected(_on_source_state): impact.state_changed.disconnect(_on_source_state)
		if impact.state().status == "running": impact.cancel("salvage_level_exit")
		impact.set_physics_process(false)
	for id: String in Layout.PART_IDS:
		var area: Area3D = _part_contacts.get(id) as Area3D; var callback: Callable = _part_callbacks.get(id, Callable())
		if is_instance_valid(area) and area.body_entered.is_connected(callback): area.body_entered.disconnect(callback)
		if parts.has(id): (parts[id].call("get_cue") as CinderInteractionCue).clear()
	if is_instance_valid(hatch) and hatch.body_entered.is_connected(_hatch_contact): hatch.body_entered.disconnect(_hatch_contact)
	if is_instance_valid(hatch_cue): hatch_cue.clear()
	if is_instance_valid(scheduler): scheduler.end_encounter("salvage_level_exit"); scheduler.set_physics_process(false)
	set_physics_process(false)


func snapshot_state_for_presentation(camera: Camera3D, hud: GameHUD) -> Dictionary:
	if _capture_camera != null or _capture_hud != null: return {}
	_capture_camera = camera; _capture_hud = hud
	var saved: Dictionary = snapshot_state(); _capture_camera = null; _capture_hud = null; return saved


func snapshot_state() -> Dictionary:
	if _publishing or _callback_depth > 0 or not _collecting_id.is_empty() or _parts_ready_pending or _final_clear_pending or _contact_pending or not _activation_entitlement.is_empty():
		last_snapshot_error = "Capture O1 only after its actual deferred native/progression barrier"; return {}
	var saved: Dictionary = super.snapshot_state()
	if saved.is_empty(): return saved
	last_snapshot_error = LocalCodec.progress_error(saved)
	return saved if last_snapshot_error.is_empty() else {}


func _capture_local_state() -> Dictionary:
	last_capture_error = _runtime_error()
	if last_capture_error.is_empty(): last_capture_error = _framing_error(_camera_framing_points(false))
	if not last_capture_error.is_empty(): return {}
	var bindings: Dictionary = scheduler_bindings(); var paired: Dictionary = scheduler.snapshot_state(bindings)
	if paired.is_empty(): last_capture_error = scheduler.last_snapshot_error; return {}
	var actors: Dictionary = {}
	for id: String in sources:
		var packet: Dictionary = (sources[id] as Act1RushSelenite).snapshot_state(paired)
		if packet.is_empty(): last_capture_error = (sources[id] as Act1RushSelenite).last_snapshot_error; return {}
		actors[id] = packet
	var circle: Dictionary = impact.snapshot_state(bindings)
	if circle.is_empty(): last_capture_error = impact.last_snapshot_error; return {}
	var frames: Dictionary = {}
	for record: Dictionary in paired.reservations:
		if not _frames.has(record.source_id) or _frames[record.source_id].reservation_id != record.id: last_capture_error = "Actual O1 lease lost its whole original response proof"; return {}
		frames[record.source_id] = _encode(_frames[record.source_id])
	return {"api_revision": LocalCodec.API_REVISION, "schema_version": LocalCodec.SCHEMA_VERSION, "world_revision": WORLD_REVISION, "stage": stage, "collected_ids": collected_ids.duplicate(), "checkpoint_published": checkpoint_published, "final_started": final_started, "final_defeated": final_defeated, "sources": actors, "impact": circle, "impact_host": _encode(_impact_host), "scheduler": paired, "framing": frames}


func _local_snapshot_error(saved: Dictionary) -> String:
	return _local_snapshot_error_with_player(saved, hero.snapshot_state())


func _local_snapshot_error_with_player(saved: Dictionary, player: Dictionary) -> String:
	var error: String = _runtime_error()
	if error.is_empty(): error = LocalCodec.metadata_error(saved)
	if error.is_empty(): error = hero.snapshot_error(player)
	if not error.is_empty(): return error
	for id: String in sources:
		error = (sources[id] as Act1RushSelenite).actor_snapshot_error(saved.sources[id], saved.scheduler, player)
		if not error.is_empty(): return error
	if saved.sources[Layout.FINAL_SOURCE_ID].dormant and not _same(saved.sources[Layout.FINAL_SOURCE_ID].motion.position, Codec.vector3(Layout.FINAL_SOURCE_POSITION)): return "Unstarted final source must retain its exact actual dormant placement"
	var bindings: Dictionary = _staged_bindings(saved, player)
	error = scheduler.snapshot_error(saved.scheduler, bindings)
	if error.is_empty(): error = impact.snapshot_error(saved.impact, bindings, saved.scheduler)
	if error.is_empty(): error = _host_error(saved)
	if error.is_empty(): error = _saved_response_error(saved, player)
	return error


func _staged_bindings(saved: Dictionary, player: Dictionary) -> Dictionary:
	var result: Dictionary = scheduler_bindings()
	for key: String in ["owner_positions", "owner_velocities", "owner_collision_states"]:
		result[key] = {}
		for id: String in sources:
			var staged: Dictionary = (sources[id] as Act1RushSelenite).staged_actor_bindings(saved.sources[id])
			for owner: String in staged.get(key, {}): result[key][owner] = staged[key][owner]
	result.owner_positions[Layout.IMPACT_ID] = Layout.IMPACT_POSITION
	result["hero_positions"] = {"hero": Codec.read_vector3(player.motion.position)}
	return result


func _host_error(saved: Dictionary) -> String:
	if saved.impact_host.is_empty(): return ""
	var host: Dictionary = saved.impact_host; var actor: Dictionary = saved.sources[Layout.CIRCUIT_SOURCE_ID]
	var role: Dictionary = actor.resolved_role; var exchange: Dictionary = saved.impact.exchange
	if actor.role_encounter_id != CIRCUIT_EPOCH or saved.impact.exchange_encounter_id != CIRCUIT_EPOCH: return "Companion history requires the original real circuit epoch"
	if role.is_empty() or host.host_active_until_s != host.host_start_s + float(role.windup_s) + float(role.active_s) or host.host_recovery_until_s != host.host_active_until_s + float(role.recovery_s): return "Impact custody must retain the host's exact original resolved recovery arithmetic"
	if not _same(host.opening_position, exchange.opening_position): return "Impact cannot refresh its original native host opening"
	if saved.impact.status == "running":
		if actor.dead or actor.dormant or actor.cycle != host.host_cycle or actor.reservation_id != host.host_reservation_id: return "A live companion requires its actual live same-cycle C30 host"
		var actual: Dictionary = {}
		for record: Dictionary in saved.scheduler.reservations:
			if record.source_id == Layout.CIRCUIT_SOURCE_ID: actual = record
		if actual.is_empty() or actual.start_s != host.host_start_s or actual.active_until_s != host.host_active_until_s or actual.recovery_until_s != host.host_recovery_until_s: return "Actual native host lease/deadlines cannot be replaced"
		var planned: Vector3 = Codec.read_vector3(actual.opening_position); var retained: Vector3 = Codec.read_vector3(host.opening_position)
		var tolerance: float = Motion.ENDPOINT_TOLERANCE if actual.get("adapter", {}).get("finished", false) else 0.0
		if planned.distance_to(retained) > tolerance: return "Companion opening must retain the native planned or authenticated stopped host endpoint"
		var proof: Dictionary = saved.framing[Layout.IMPACT_ID].proof
		if proof.primary_time_s != host.primary_time_s or proof.response_complete_s != host.response_complete_s: return "Live companion proof must be the original accepted host-custody proof"
	return ""


func snapshot_error(saved: Dictionary) -> String:
	var error: String = super.snapshot_error(saved)
	return LocalCodec.progress_error(saved) if error.is_empty() else error


func snapshot_error_with_player(saved: Dictionary, player: Dictionary) -> String:
	var error: String = super.snapshot_error_with_player(saved, player)
	return LocalCodec.progress_error(saved) if error.is_empty() else error


func restore_state(saved: Dictionary) -> bool:
	last_snapshot_error = snapshot_error(saved)
	if not last_snapshot_error.is_empty(): return false
	var accepted: bool = super.restore_state(saved)
	if not _quiet_error.is_empty(): last_snapshot_error = _quiet_error; return false
	return accepted


func _restore_local_state(saved: Dictionary) -> void:
	_quiet_commit = true
	for id: String in sources:
		if not (sources[id] as Act1RushSelenite).restore_actor_state(saved.sources[id]): _fail_quiet((sources[id] as Act1RushSelenite).last_snapshot_error); return
	if not scheduler.restore_state(saved.scheduler, scheduler_bindings()): _fail_quiet(scheduler.last_snapshot_error); return
	for id: String in sources:
		if not (sources[id] as Act1RushSelenite).restore_exchange_state(saved.sources[id]): _fail_quiet((sources[id] as Act1RushSelenite).last_snapshot_error); return
	if not impact.restore_state(saved.impact, scheduler_bindings()): _fail_quiet(impact.last_snapshot_error); return
	stage = saved.stage; collected_ids.assign(saved.collected_ids); checkpoint_published = saved.checkpoint_published
	final_started = saved.final_started; final_defeated = saved.final_defeated
	_frames = _decode(saved.framing); _impact_host = _decode(saved.impact_host)
	_forecast.clear(); _pending_start.clear(); _activation_entitlement = ""; _collecting_id = ""
	_parts_ready_pending = false; _final_clear_pending = false; _contact_pending = false; _settle_queued = false
	_sync_presentation(false); _quiet_commit = false


func _fail_quiet(reason: String) -> void:
	_quiet_error = reason if not reason.is_empty() else "Incomplete prevalidated O1 native commit"
	_quiet_commit = false; _running = false; set_physics_process(false)
	for node: Node in [circuit, final_rusher, impact, scheduler]: node.set_physics_process(false)


func _restore_candidate_presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	var error: String = _runtime_error()
	if not error.is_empty(): return error
	return String(shared_shell.call("camera_framing_error_for_context", _camera_framing_points(false), hero, camera, hud))


static func _encode_bounds(bounds: AABB) -> Dictionary:
	return {"position": Codec.vector3(bounds.position), "size": Codec.vector3(bounds.size)}


static func _encode_transform(frame: Transform3D) -> Dictionary:
	return {"origin": Codec.vector3(frame.origin), "x": Codec.vector3(frame.basis.x), "y": Codec.vector3(frame.basis.y), "z": Codec.vector3(frame.basis.z)}


func _saved_response_error(state: Dictionary, saved_player: Dictionary) -> String:
	if not _same(hero.equipment.snapshot(), saved_player.equipment): return "Actual candidate equipment must match saved complete Player"
	var stats: Dictionary = hero.equipment.resolved_stats()
	var threats: Array[Dictionary] = []
	for record: Dictionary in state.scheduler.reservations:
		var shape: Dictionary = _decode(record.geometry)
		var error: String = Geometry.error(shape)
		if not error.is_empty(): return error
		threats.append({"record": record, "shape": shape})
	for item: Dictionary in threats:
		var record: Dictionary = item.record
		var proof: Dictionary = state.framing[record.source_id].proof
		var path: Array[Dictionary] = []
		for segment: Dictionary in proof.path: path.append(_decode(segment))
		if path[0].end_s < record.start_s + 0.18: return "Saved response removes the original recognition margin"
		if path.size() == 6 and path[3].start_s < maxf(maxf(path[1].end_s, record.active_until_s + CinderThreatScheduler.TIME_MARGIN), path[1].start_s + float(stats.dash_cooldown)): return "Saved positioning dash skips the actual dash cooldown/recovery boundary"
		var input_ready: float = path[3].end_s if path.size() == 6 else maxf(path[1].end_s, record.active_until_s + CinderThreatScheduler.TIME_MARGIN)
		if proof.primary_time_s < input_ready + 0.08: return "Saved ordinary primary removes the original input margin"
		for segment: Dictionary in path:
			var move: Vector3 = segment.to - segment.from
			if segment.kind in ["escape_dash", "positioning_dash"]:
				if absf(move.y) > BodySweep.EPSILON or absf(move.length() - float(stats.dash_distance)) > BodySweep.position_rounding_bound(segment.from, segment.to) or segment.end_s != segment.start_s + float(stats.dash_duration): return "Retain actual full native response dash distance/duration"
			elif move != Vector3.ZERO: return "Stationary response cannot hide travel"
			var sweep: Dictionary = BodySweep.sweep(hero, Transform3D(Basis.IDENTITY, segment.from), move, scheduler_bindings().floors.values())
			if sweep.has("error") or sweep.get("collided", true) or not sweep.get("end") is Vector3 or sweep.end.distance_to(segment.to) > BodySweep.position_rounding_bound(segment.from, segment.to): return "Saved response lacks actual static floor/full capsule support"
		for threat: Dictionary in threats:
			if Geometry.timed_path_hits(threat.shape, path, threat.record.active_from_s, threat.record.active_until_s, CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN): return "Saved response crosses the committed danger union"
		var opening: Vector3 = Codec.read_vector3(record.opening_position)
		var attack: Vector3 = Codec.read_vector3(proof.attack_position)
		var reserve: float = Motion.ENDPOINT_TOLERANCE if record.get("adapter", {}).get("kind") == "lunge" and not record.adapter.get("finished", false) else 0.0
		if Vector2(opening.x - attack.x, opening.z - attack.z).length() > float(stats.primary_range) - reserve - CinderThreatScheduler.SKIN or absf(opening.y - attack.y) > 1.4: return "Saved ordinary primary cannot reach its actual native opening"
		var ray := PhysicsRayQueryParameters3D.create(attack + Vector3.UP * 0.7, opening + Vector3.UP * 0.7, 1)
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return "Static salvage scenery blocks the original primary"
		if proof.response_complete_s < proof.primary_time_s + float(stats.primary_cooldown): return "Saved response truncates ordinary primary recovery"
	return ""




static func _box_points(bounds: AABB, frame: Transform3D) -> Array:
	var result: Array = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]: result.append(frame * Vector3(x, y, z))
	return result




func _bounds_points(points: Array) -> Array:
	if points.is_empty(): return []
	var bounds := AABB(points[0], Vector3.ZERO)
	for point: Vector3 in points:
		if not point.is_finite(): return [Vector3.INF]
		bounds = bounds.expand(point)
	return _box_points(bounds, Transform3D.IDENTITY)




static func _unique(points: Array) -> Array:
	var result: Array = []
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite(): return [Vector3.INF]
		if not result.has(point): result.append(point)
	return result




static func _encode(value: Variant) -> Variant:
	if value is Vector3: return Codec.vector3(value)
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_encode(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _encode(value[key])
		return result
	return value




static func _decode(value: Variant) -> Variant:
	# Only named coordinate fields decode; numeric histories/deadline arrays
	# keep their exact literal types and cannot become inferred positions.
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_decode(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key: String in value:
			result[key] = Codec.read_vector3(value[key]) if key in ["from", "to", "endpoint", "landing", "attack_position", "origin", "direction", "source_position", "opening_position"] and Codec.is_vector3(value[key]) else _decode(value[key])
		return result
	return value




static func _same(left: Variant, right: Variant) -> bool:
	var wire: String = Exact.stringify(left)
	return not wire.is_empty() and wire == Exact.stringify(right)


static func _material_signature(material: Material) -> Dictionary:
	if material == null: return {"id": "none"}
	var value: Dictionary = {"id": str(material.get_instance_id()), "class": material.get_class()}
	if material is StandardMaterial3D:
		value["albedo"] = [material.albedo_color.r, material.albedo_color.g, material.albedo_color.b, material.albedo_color.a]
		value["texture"] = str(material.albedo_texture.get_instance_id()) if material.albedo_texture != null else "none"
		value["shading_mode"] = material.shading_mode; value["transparency"] = material.transparency
		value["no_depth_test"] = material.no_depth_test; value["cull_mode"] = material.cull_mode
		value["roughness"] = material.roughness; value["texture_filter"] = material.texture_filter
	return value


static func _interaction_error(cue: CinderInteractionCue, expected: String) -> String:
	if not is_instance_valid(cue) or not cue.is_inside_tree() or cue.is_queued_for_deletion() or cue.basis != Basis.IDENTITY: return "Retained actual interaction cue required"
	var state: Dictionary = cue.state()
	if state.state != expected or state.required != true or state.visible != (expected != "clear"): return "Actual interaction state/visibility differs"
	var marker := cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
	if marker == null or marker.get_parent() != cue or marker.position != Vector3(0, 0.025, 0): return "Actual native interaction marker required"
	if expected == "clear": return "" if not marker.visible and marker.mesh == null else "Clear interaction cannot impersonate an available contact"
	if state.trigger != "contact" or not cue.is_visible_in_tree() or not marker.is_visible_in_tree() or marker.mesh == null or not marker.material_override is StandardMaterial3D: return "Visible actual contact marker required"
	var material := marker.material_override as StandardMaterial3D
	if material.albedo_color.a <= 0.0 or material.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA or material.no_depth_test: return "Actual contact material must remain visible with ordinary depth"
	return ""
