extends "res://scripts/campaign/level.gd"
## O3 functional greybox source. UNPARSED/UNEXECUTED.
## One shared Player/Scheduler and six unchanged finite C32 guards.
## Whole campaign transport deliberately refuses until its owned codec is wired.

signal native_admission_published(source_id: String, answer: Dictionary)

const Layout = preload("res://scripts/acts/act1/royal_rehearsal_layout.gd")
const Guard = preload("res://scripts/acts/act1/mushroom_selenite.gd")
const CourtArt = preload("res://scripts/acts/act1/selenite_court_art.gd")
const Arrangement = preload("res://scripts/combat/encounter_arrangement.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Interaction = preload("res://scripts/cues/interaction_cue.gd")
const WORLD_REVISION: int = Layout.WORLD_REVISION
const CONTACT_VIEW_DISTANCE: float = 3.6
const SNAPSHOT_PENDING: String = "A1-O3 greybox whole native aggregate is not integrated"

var scheduler: CinderThreatScheduler
var sources: Dictionary = {}
# Stable owned metadata agreed with royal_rehearsal_codec.gd.
var exercise_index: int = 0
var stage: String = "awaiting_bell"
var completed_exercises: Array[String] = []
var checkpoint_published: bool = false
var bell_armed: bool = true
var recipes: Dictionary = {}
var admission_cursor: int = 0
var admission_gate: Dictionary = {}
var last_encounter_error: String = ""
var last_admission: Dictionary = {}

var _running: bool = false
var _changing: bool = false
var _construction_error: String = ""
var _fresh_entitlement: String = ""
var _progress_entitlement: String = ""
var _pending_bell: bool = false
var _pending_bell_exercise: int = -1
var _pending_exit: bool = false
var _contact_epoch: int = 0
var _retained: Dictionary = {}
var _trusted_configurations: Dictionary = {}
var _configuration_hashes: Dictionary = {}
var _authored_positions: Dictionary = {}
var _frames: Dictionary = {}
var _forecast: Array = []
var _forecast_frames: Dictionary = {}
var _floor: CollisionShape3D
var _floor_shape: BoxShape3D
var _floor_frame: Transform3D
var _bell_area: Area3D
var _exit_area: Area3D
var _bell_cue: CinderInteractionCue
var _exit_cue: CinderInteractionCue
var _contact_pins: Dictionary = {}
var _court_art: Node3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 200
	_floor = get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
	_floor_shape = _floor.shape as BoxShape3D if is_instance_valid(_floor) else null
	_floor_frame = _floor.global_transform if is_instance_valid(_floor) else Transform3D.IDENTITY
	_construction_error = _floor_error()
	if not _construction_error.is_empty(): return
	scheduler = CinderThreatScheduler.new()
	scheduler.name = "RehearsalThreatScheduler"
	add_child(scheduler)
	for id: String in Layout.SOURCE_IDS:
		var actor: Act1MushroomSelenite = Guard.new()
		actor.name = id
		actor.position = Layout.SOURCES[id].position
		if not actor.configure("C32", id, true, false):
			_construction_error = actor.last_error; actor.free(); return
		add_child(actor)
		actor.activation_guard = Callable(self, "_fresh_activation_entitled")
		actor.presentation_guard = Callable(self, "presentation_error")
		sources[id] = actor
		_retained[id] = actor
	_bell_area = get_node_or_null("BellArea") as Area3D
	_exit_area = get_node_or_null("ExitArea") as Area3D
	if not is_instance_valid(_bell_area) or not is_instance_valid(_exit_area):
		_construction_error = "Actual bell and exit contact Areas required"; return
	for area: Area3D in [_bell_area, _exit_area]:
		var collision := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if collision == null or not collision.shape is BoxShape3D:
			_construction_error = "Actual native upright contact BOX required"; return
		_contact_pins[area.name] = {"area": area, "frame": area.global_transform, "collision": collision, "shape": collision.shape, "collision_frame": collision.transform, "size": (collision.shape as BoxShape3D).size, "layer": area.collision_layer, "mask": area.collision_mask}
	_bell_area.body_entered.connect(_bell_contact)
	_exit_area.body_entered.connect(_exit_contact)
	_bell_cue = Interaction.new(); _bell_cue.name = "BellContactCue"
	_bell_cue.position = Layout.BELL_POSITION + Vector3(0, 0.035, 0); add_child(_bell_cue)
	_exit_cue = Interaction.new(); _exit_cue.name = "ExitContactCue"
	_exit_cue.position = Layout.EXIT_POSITION + Vector3(0, 0.035, 0); add_child(_exit_cue)
	_court_art = CourtArt.build_geometry_art(self)
	if not is_instance_valid(_court_art):
		_construction_error = "Actual unchanged 14x16 entrance CourtArt refused its floor binding"; return
	_refresh_objective()


func _on_enter_level() -> void:
	if not _construction_error.is_empty(): return
	for id: String in Layout.SOURCE_IDS:
		var actor: Act1MushroomSelenite = sources[id]
		if not actor.bind(scheduler, hero):
			_construction_error = actor.last_error; return
		var native: Dictionary = actor.get_spore_native_bindings()
		if native.get("player") != hero or native.get("scheduler") != scheduler:
			_construction_error = "Retain actual shared Player/Scheduler before rehearsal entry"; return
		_trusted_configurations[id] = native.configuration.duplicate(true)
		_configuration_hashes[id] = Exact.stringify(native.configuration).sha256_text()
		_authored_positions[id] = Codec.vector3(actor.global_position)
	_running = true
	# No synthetic epoch, activation or field before the first real bell contact.
	_sync_contact_presentation()
	_refresh_objective()


func _physics_process(_delta: float) -> void:
	if not _live_boundary(): return
	var error: String = _native_runtime_error()
	if not error.is_empty(): _fail_native(error); return
	_refresh_frames()
	if stage == "awaiting_bell":
		# A cleared exercise cannot reuse an old overlap. The first genuine
		# outside observation makes the next fresh contact available.
		if not bell_armed and not _bell_area.overlaps_body(hero): bell_armed = true
		_sync_contact_presentation()
		if bell_armed and not _pending_bell and _bell_area.monitoring and _bell_area.overlaps_body(hero): _bell_contact(hero)
	elif stage == "active":
		_sync_contact_presentation()
		if _current_pair_dead(): _retire_exercise(); return
		if hero.get_threat_response_state().stable: _offer_one_admission()
	elif stage == "complete":
		_sync_contact_presentation()
		if not _pending_exit and _exit_area.monitoring and _exit_area.overlaps_body(hero): _exit_contact(hero)
	_refresh_objective()


func _bell_contact(body: Node3D) -> void:
	if _pending_bell or body != hero or not _live_boundary() or stage != "awaiting_bell" or not bell_armed or not _bell_area.monitoring or not _bell_area.overlaps_body(hero): return
	if not _contact_error().is_empty(): return
	_pending_bell = true
	_pending_bell_exercise = exercise_index
	_commit_bell_contact.call_deferred(body, exercise_index, _contact_epoch)


func _commit_bell_contact(body: Node3D, expected_exercise: int, epoch: int) -> void:
	if not _pending_bell or expected_exercise != _pending_bell_exercise or epoch != _contact_epoch: return
	_pending_bell = false; _pending_bell_exercise = -1
	if body != hero or not _live_boundary() or stage != "awaiting_bell" or exercise_index != expected_exercise or not bell_armed or not _bell_area.monitoring or not _bell_area.overlaps_body(hero): return
	var cue: Dictionary = _bell_cue.state()
	if cue.state != "available" or cue.trigger != "contact" or not cue.visible or not _contact_error().is_empty() or not _framing_ready(): return
	# All collision/lifecycle writes occur after native query delivery.
	var admitted_hero: CinderPlayer = hero
	bell_armed = false
	stage = "active"
	_changing = true
	_bell_cue.present("active", "contact")
	if not _live_boundary(true, true) or hero != admitted_hero:
		_changing = false; return
	var preference: String = String(shared_shell.call("get_difficulty_preference")) if shared_shell.has_method("get_difficulty_preference") else "standard"
	if not scheduler.begin_encounter(preference, Layout.encounter_id(exercise_index), WORLD_REVISION):
		_changing = false; _fail_native(scheduler.last_error); return
	var helper: CinderEncounterArrangement = Arrangement.new(Layout.arrangement_definition(exercise_index))
	var selected: Dictionary = helper.select_fresh(String(scheduler.encounter_profile().get("id", "")))
	if selected.is_empty():
		_changing = false; _fail_native(helper.last_error); return
	recipes[Layout.EXERCISE_IDS[exercise_index]] = selected
	admission_cursor = 0; admission_gate.clear(); _frames.clear(); _clear_forecast()
	for id: String in Layout.group_ids(exercise_index):
		_fresh_entitlement = id
		var accepted: bool = (sources[id] as Act1MushroomSelenite).activate()
		_fresh_entitlement = ""
		if not accepted:
			_changing = false; _fail_native((sources[id] as Act1MushroomSelenite).last_error); return
		if not _live_boundary(true, true) or hero != admitted_hero:
			_changing = false; return
	_changing = false
	_sync_contact_presentation()
	_refresh_objective()


func _fresh_activation_entitled(id: String) -> bool:
	return _running and _changing and stage == "active" and id == _fresh_entitlement and id in Layout.group_ids(exercise_index) and scheduler.get_clock() == 0.0 and not scheduler.encounter_profile().is_empty() and not scheduler.has_committed_exchange()


func _offer_one_admission() -> void:
	var recipe: Dictionary = recipes.get(Layout.EXERCISE_IDS[exercise_index], {})
	if recipe.is_empty() or recipe.get("order", []).size() != 2:
		_fail_native("Current actual exercise lost its retained recipe"); return
	var order: Array = recipe.order
	var id: String = order[admission_cursor]
	if (sources[id] as Act1MushroomSelenite).dead: id = order[1 - admission_cursor]
	if (sources[id] as Act1MushroomSelenite).dead or not _gate_released(): return
	# Exactly one candidate per parent tick. The next cursor changes only after
	# a genuine admission; a tight loop cannot repeatedly starve the peer.
	_admit_actor(id, recipe)


func _gate_released() -> bool:
	if admission_gate.is_empty(): return true
	var id: String = admission_gate.source_id
	var actor := sources.get(id) as Act1MushroomSelenite
	if not is_instance_valid(actor) or actor != _retained.get(id):
		_fail_native("Retained admission gate lost its actual source"); return false
	if actor.dead: return true
	# These are original admitted native deadlines, never an extra timer. A
	# cancelled lease cannot emit a future phase, but its committed gate remains.
	var release: float = admission_gate.lock_from_s if admission_gate.release_phase == "lock" else admission_gate.active_until_s
	return scheduler.get_clock() >= release


func _admit_actor(id: String, recipe: Dictionary) -> void:
	var actor := sources.get(id) as Act1MushroomSelenite
	if not _retained_source(actor, id): _fail_native("Admission lost its actual retained C32"); return
	var state: Dictionary = actor.pure_presentation_state()
	if state.dead or state.dormant or not String(state.reservation_id).is_empty() or actor.global_position.distance_to(hero.global_position) > 4.5:
		_clear_forecast(); return
	var context: Dictionary = response_context()
	var target: Vector3 = Layout.target_for(id, actor.global_position)
	var preview: Dictionary = actor.preview_start(target, context)
	if preview.get("accepted") != true:
		last_encounter_error = String(preview.get("reason", "Native preview refused")); _clear_forecast(); return
	var proof: Dictionary = preview.proof
	if proof.get("uses_blast") != false or proof.get("uses_invulnerability") != false or not Codec.is_number(proof.get("primary_time_s")) or not Codec.is_number(proof.get("response_complete_s")) or float(proof.primary_time_s) < float(preview.candidate.active_until_s) or float(proof.response_complete_s) >= float(preview.candidate.recovery_until_s):
		last_encounter_error = "Retain ordinary recovery response"; _clear_forecast(); return
	if not _retained_responses_avoid(preview.candidate):
		last_encounter_error = "New warning would cut an earlier original response"; _clear_forecast(); return
	_forecast = _actor_points(id, preview.candidate.opening_position) + _geometry_points(preview.candidate.geometry) + _response_points(proof.landing, proof.attack_position)
	_forecast_frames = {"id": id, "source": actor.global_transform, "hero": hero.global_transform}
	if not _framing_ready(): return
	var admitted_hero: CinderPlayer = hero
	var admitted_shell: Node = shared_shell
	var answer: Dictionary = actor.start(target, context, preview)
	if answer.get("accepted") != true:
		last_encounter_error = String(answer.get("reason", "Native commit refused")); _clear_forecast(); return
	var error: String = _admission_custody_error(id, actor, answer, admitted_hero, admitted_shell)
	if not error.is_empty():
		_clear_forecast(); _fail_native(error); return
	# Preserve the actual accepted native history even if the following current
	# optical check has to cancel it. Cancellation never erases a real cycle.
	_record_gate(id, recipe, actor.pure_presentation_state(), answer.reservation)
	_frames[id] = {"reservation_id": answer.reservation_id, "landing": answer.proof.landing, "attack_position": answer.proof.attack_position, "proof": answer.proof.duplicate(true)}
	last_admission = answer.duplicate(true)
	_clear_forecast()
	if not _retained_responses_avoid(answer.reservation) or not presentation_error().is_empty():
		actor.cancel("rehearsal_current_response_or_view_lost")
		_frames.erase(id)
		last_encounter_error = "Actual admission cancelled without erasing native cooldown/gate"
		return
	error = _admission_custody_error(id, actor, answer, admitted_hero, admitted_shell)
	if not error.is_empty(): _fail_native(error); return
	last_encounter_error = ""
	native_admission_published.emit(id, answer.duplicate(true))


func _record_gate(id: String, recipe: Dictionary, actual: Dictionary, record: Dictionary) -> void:
	admission_cursor = (int(recipe.order.find(id)) + 1) % 2
	admission_gate = {"source_id": id, "reservation_id": String(record.id), "cycle": int(actual.cycle), "encounter_id": Layout.encounter_id(exercise_index), "profile_id": String(record.profile_id), "release_phase": Layout.release_phase(exercise_index, recipe, id)}
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		admission_gate[key] = record[key]


func _admission_custody_error(id: String, actor: Act1MushroomSelenite, answer: Dictionary, expected_hero: CinderPlayer, expected_shell: Node) -> String:
	if not _live_boundary() or hero != expected_hero or shared_shell != expected_shell or stage != "active" or id not in Layout.group_ids(exercise_index) or not _retained_source(actor, id) or actor.dead or actor.dormant: return "Actual admitted source/Player/level lifecycle changed inside callback"
	var native: Dictionary = actor.get_spore_native_bindings()
	var control: Dictionary = scheduler.source_control_state(actor)
	var response: Dictionary = actor.get_spore_response_state()
	if native.get("player") != hero or native.get("scheduler") != scheduler or control.get("outside_transaction") != true or response.get("outside_transaction") != true or control.get("encounter_id") != Layout.encounter_id(exercise_index) or control.get("world_revision") != WORLD_REVISION or control.get("reservations", []).size() != 1: return "Actual admitted native correspondence changed"
	var record: Dictionary = control.reservations[0]
	if actor.pure_presentation_state().reservation_id != answer.reservation_id or record.get("id") != answer.reservation_id or record.get("source_instance_id") != actor.get_instance_id() or var_to_bytes(record) != var_to_bytes(answer.reservation): return "Returned reservation differs from its actual current retained native lease"
	return ""


func _retained_responses_avoid(candidate: Dictionary) -> bool:
	for id: String in _frames:
		var actor := sources.get(id) as Act1MushroomSelenite
		if not _retained_source(actor, id): return false
		var control: Dictionary = scheduler.source_control_state(actor)
		if control.get("outside_transaction") != true or control.get("clock_s") != scheduler.get_clock(): return false
		for record: Dictionary in control.get("reservations", []):
			if record.id != _frames[id].reservation_id: continue
			var path: Array[Dictionary] = []
			for segment: Dictionary in _frames[id].proof.path: path.append(segment)
			if Geometry.timed_path_hits(candidate.geometry, path, candidate.active_from_s, candidate.active_until_s, CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN): return false
	return true


func _current_pair_dead() -> bool:
	for id: String in Layout.group_ids(exercise_index):
		if not (sources[id] as Act1MushroomSelenite).dead: return false
	return true


func _retire_exercise() -> void:
	if not _live_boundary() or stage != "active" or not _current_pair_dead(): return
	_changing = true
	scheduler.end_encounter("rehearsal_exercise_clear")
	if not scheduler.encounter_profile().is_empty() or scheduler.has_committed_exchange():
		_changing = false; _fail_native("Actual cleared exercise did not retire its native epoch"); return
	completed_exercises.append(Layout.EXERCISE_IDS[exercise_index])
	admission_cursor = 0; admission_gate.clear(); _frames.clear(); _clear_forecast()
	bell_armed = false
	if exercise_index < 2:
		exercise_index += 1
		stage = "awaiting_bell"
		_changing = false
		_sync_contact_presentation(); _refresh_objective()
		if exercise_index == 2:
			checkpoint_published = true
			_progress_entitlement = Layout.CHECKPOINT_ID
			var accepted: bool = request_checkpoint(Layout.CHECKPOINT_ID, "encounter")
			_progress_entitlement = ""
			if not accepted and _running: _fail_native("Actual pre-final checkpoint publication refused")
	else:
		stage = "complete"
		_changing = false
		_sync_contact_presentation(); _refresh_objective()
		_progress_entitlement = Layout.COMPLETION_ID
		var accepted: bool = request_completion(Layout.COMPLETION_ID)
		_progress_entitlement = ""
		if not accepted and _running: _fail_native("Actual finite rehearsal completion publication refused")


func request_checkpoint(checkpoint_id: String, boundary_kind: String = "encounter") -> bool:
	if _progress_entitlement != Layout.CHECKPOINT_ID or checkpoint_id != Layout.CHECKPOINT_ID or boundary_kind != "encounter" or not _running or stage != "awaiting_bell" or exercise_index != 2 or completed_exercises != ["parallel", "inward"] or not checkpoint_published or not scheduler.encounter_profile().is_empty(): return false
	return super.request_checkpoint(checkpoint_id, boundary_kind)


func request_completion(completion_id: String = "complete") -> bool:
	if _progress_entitlement != Layout.COMPLETION_ID or completion_id != Layout.COMPLETION_ID or not _running or stage != "complete" or completed_exercises != Layout.EXERCISE_IDS or not checkpoint_published or not scheduler.encounter_profile().is_empty() or not _current_pair_dead(): return false
	return super.request_completion(completion_id)


func _exit_contact(body: Node3D) -> void:
	if _pending_exit or body != hero or not _live_boundary() or stage != "complete" or not is_completed() or not _contact_exit_id.is_empty() or not _exit_area.monitoring or not _exit_area.overlaps_body(hero): return
	_pending_exit = true
	_commit_exit_contact.call_deferred(body, _contact_epoch)


func _commit_exit_contact(body: Node3D, epoch: int) -> void:
	if not _pending_exit or epoch != _contact_epoch: return
	_pending_exit = false
	if body != hero or not _live_boundary() or stage != "complete" or not is_completed() or not _exit_area.monitoring or not _exit_area.overlaps_body(hero) or not _contact_error().is_empty() or not _framing_ready(): return
	var cue: Dictionary = _exit_cue.state()
	if cue.state != "available" or cue.trigger != "contact" or not cue.visible: return
	_progress_entitlement = Layout.EXIT_ID
	var accepted: bool = request_contact_exit(Layout.EXIT_ID, body)
	_progress_entitlement = ""
	if not accepted or not _live_boundary(true): return
	_exit_area.set_deferred("monitoring", false)
	_court_art.call("set_exit_open", true)
	if not String(_court_art.call("binding_error")).is_empty(): _fail_native("Original entrance curtain art failed after actual exit"); return
	_sync_contact_presentation()


func request_contact_exit(exit_id: String, body: Node3D) -> bool:
	if _progress_entitlement != Layout.EXIT_ID or exit_id != Layout.EXIT_ID or body != hero or not _running or stage != "complete" or completed_exercises != Layout.EXERCISE_IDS or not checkpoint_published or not _exit_area.overlaps_body(body) or not _contact_error().is_empty(): return false
	return super.request_contact_exit(exit_id, body)


func _sync_contact_presentation() -> void:
	if not _running or not is_instance_valid(hero): return
	if _near(Layout.BELL_POSITION):
		var visual: String = "active" if stage == "active" else ("available" if stage == "awaiting_bell" and bell_armed else "spent")
		_bell_cue.present(visual, "contact")
	else: _bell_cue.clear()
	var available: bool = stage == "complete" and is_completed() and _contact_exit_id.is_empty() and _near(Layout.EXIT_POSITION)
	_exit_area.set_deferred("monitoring", available)
	if available: _exit_cue.present("available", "contact")
	elif stage == "complete" and not _contact_exit_id.is_empty() and _near(Layout.EXIT_POSITION): _exit_cue.present("spent", "contact")
	else: _exit_cue.clear()


func _near(position: Vector3) -> bool:
	return is_instance_valid(hero) and Vector2(hero.global_position.x - position.x, hero.global_position.z - position.z).length() <= CONTACT_VIEW_DISTANCE


func _refresh_objective() -> void:
	if stage == "complete": objective_text = "REHEARSAL COMPLETE\nCONTACT THE OPEN CURTAIN"
	elif stage == "active": objective_text = Layout.EXERCISE_IDS[exercise_index].to_upper() + " GUARDS\nCHOOSE THE GAP · PRIMARY AT RECOVERY"
	else: objective_text = "EXERCISE %d / 3\n" % (exercise_index + 1) + ("CONTACT THE PRACTICE BELL" if bell_armed else "STEP CLEAR · RETURN TO THE BELL")


func response_context() -> Dictionary:
	var directions: Array[Vector3] = []
	for index: int in 16: directions.append(Vector3(cos(float(index) * TAU / 16), 0, sin(float(index) * TAU / 16)))
	return {"encounter_id": Layout.encounter_id(exercise_index), "world_revision": WORLD_REVISION, "recognition_s": 0.18, "attack_input_margin_s": 0.08, "escape_directions": directions, "return_directions": directions, "floor_regions": [{"collision": _floor, "safe_rect": Layout.SAFE_RECT}], "world_root": _world_root()}


func scheduler_bindings() -> Dictionary:
	return {"world_root": _world_root(), "owners": sources.duplicate(), "floors": {"rehearsal_floor": {"collision": _floor, "safe_rect": Layout.SAFE_RECT}}}


func _world_root() -> Node3D:
	var node: Node = get_parent()
	while is_instance_valid(node):
		if node is Node3D and node.is_ancestor_of(hero) and node.is_ancestor_of(scheduler) and (node as Node3D).get_world_3d() == get_world_3d(): return node as Node3D
		node = node.get_parent()
	return null


func _live_boundary(allow_paused: bool = false, allow_changing: bool = false) -> bool:
	return _construction_error.is_empty() and _running and is_inside_tree() and not is_queued_for_deletion() and not is_restore_candidate() and (allow_changing or not _changing) and (allow_paused or not get_tree().paused) and is_instance_valid(hero) and hero.is_inside_tree() and not hero.is_queued_for_deletion() and not hero.dead and is_instance_valid(shared_shell) and shared_shell.is_inside_tree() and not shared_shell.is_queued_for_deletion()


func _retained_source(actor: Act1MushroomSelenite, id: String) -> bool:
	return is_instance_valid(actor) and actor == _retained.get(id) and actor.get_script() == Guard and actor.get_parent() == self and actor.is_inside_tree() and not actor.is_queued_for_deletion() and actor.get_world_3d() == get_world_3d()


func _refresh_frames() -> void:
	for id: String in _frames.keys():
		var actor := sources.get(id) as Act1MushroomSelenite
		if not _retained_source(actor, id): _frames.erase(id); continue
		var found: bool = false
		for record: Dictionary in scheduler.source_control_state(actor).get("reservations", []):
			if record.id == _frames[id].reservation_id: found = true
		if not found: _frames.erase(id)


func _clear_forecast() -> void:
	_forecast.clear(); _forecast_frames.clear()


func _framing_ready() -> bool:
	var points: Array = _camera_framing_points()
	if points.is_empty() or points.size() > 224: return false
	var plan: Dictionary = shared_shell.call("camera_framing_plan", points, hero.global_position + Vector3(0, 0.65, 0))
	if plan.get("accepted") != true:
		_clear_forecast(); return false
	return String(shared_shell.call("camera_framing_error", points)).is_empty()


func presentation_error() -> String:
	if not _construction_error.is_empty(): return _construction_error
	if not _running: return ""
	var error: String = _floor_error()
	if error.is_empty(): error = _contact_error()
	if not error.is_empty(): return error
	return String(shared_shell.call("camera_framing_error", _camera_framing_points())) if is_instance_valid(shared_shell) else "Actual shared rehearsal Shell required"


func _camera_framing_points() -> Array:
	if not _running or not is_instance_valid(hero) or not is_instance_valid(shared_shell): return []
	var points: Array = _hero_points()
	if _bell_cue.state().visible or (stage == "awaiting_bell" and _near(Layout.BELL_POSITION)):
		points.append_array(_contact_points(_bell_area, _bell_cue))
	if _exit_cue.state().visible or (stage == "complete" and _near(Layout.EXIT_POSITION)):
		points.append_array(_contact_points(_exit_area, _exit_cue))
	var prospective: bool = stage == "awaiting_bell" and _near(Layout.BELL_POSITION)
	for id: String in Layout.group_ids(exercise_index):
		var actor := sources.get(id) as Act1MushroomSelenite
		if not _retained_source(actor, id): return [Vector3.INF]
		var state: Dictionary = actor.pure_presentation_state()
		if state.dead or (state.dormant and not prospective): continue
		points.append_array(_actor_points(id, actor.global_position, prospective))
		if not String(state.reservation_id).is_empty():
			points.append_array(_geometry_points(state.geometry)); points.append_array(_cue_points(actor.get_cue()))
	for id: String in _frames:
		var actor := sources.get(id) as Act1MushroomSelenite
		if not _retained_source(actor, id): return [Vector3.INF]
		for record: Dictionary in scheduler.source_control_state(actor).get("reservations", []):
			if record.id == _frames[id].reservation_id: points.append_array(_response_points(_frames[id].landing, _frames[id].attack_position))
	if not _forecast.is_empty() and _forecast_frames.get("hero") == hero.global_transform:
		var actor := sources.get(_forecast_frames.get("id", "")) as Act1MushroomSelenite
		if is_instance_valid(actor) and actor.global_transform == _forecast_frames.get("source"): points.append_array(_forecast)
	var dash: Dictionary = hero.get_committed_dash_state()
	if dash.get("active", false):
		for point: Vector3 in _hero_points(): points.append(point + dash.origin + dash.direction * float(dash.distance) - hero.global_position)
	return _unique_points(points)


func _actor_points(id: String, endpoint: Vector3, prospective: bool = false) -> Array:
	var actor := sources.get(id) as Act1MushroomSelenite
	if not _retained_source(actor, id) or not actor.art_binding_error().is_empty(): return [Vector3.INF]
	var collision := actor.get_node_or_null("BodyCollision") as CollisionShape3D
	if collision == null or not collision.shape is CapsuleShape3D: return [Vector3.INF]
	var capsule := collision.shape as CapsuleShape3D
	var points: Array = _box_points(AABB(Vector3(-capsule.radius, -capsule.height * 0.5, -capsule.radius), Vector3(capsule.radius * 2, capsule.height, capsule.radius * 2)), collision.global_transform)
	var art: Node3D = actor.get_art()
	for node: Node in art.find_children("*", "Sprite3D", true, false):
		if node.is_visible_in_tree() or (prospective and node.visible): points.append_array(shared_shell.call("camera_billboard_points", node))
	for node: Node in art.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh != null and (mesh.is_visible_in_tree() or (prospective and mesh.visible)): points.append_array(_box_points(mesh.get_aabb(), mesh.global_transform))
	if endpoint != actor.global_position:
		for point: Vector3 in points.duplicate(): points.append(point + endpoint - actor.global_position)
	return _unique_points(points)


func _hero_points() -> Array:
	return shared_shell.call("player_camera_framing_points") if is_instance_valid(shared_shell) and shared_shell.get("player") == hero else [Vector3.INF]


func _contact_points(area: Area3D, cue: CinderInteractionCue) -> Array:
	if not is_instance_valid(area) or not is_instance_valid(cue): return [Vector3.INF]
	var collision := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null or not collision.shape is BoxShape3D or collision.disabled: return [Vector3.INF]
	var shape := collision.shape as BoxShape3D
	var points: Array = _box_points(AABB(-shape.size * 0.5, shape.size), collision.global_transform)
	for node: Node in cue.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh != null and mesh.is_visible_in_tree(): points.append_array(_box_points(mesh.get_aabb(), mesh.global_transform))
	return _unique_points(points)


func _cue_points(cue: CinderThreatCue) -> Array:
	var points: Array = []
	for node: Node in cue.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh != null and mesh.is_visible_in_tree(): points.append_array(_box_points(mesh.get_aabb(), mesh.global_transform))
	return points


func _geometry_points(shape: Dictionary) -> Array:
	if shape.get("kind") != "lane": return [Vector3.INF]
	var points: Array = []
	for centre: Vector3 in [shape["from"], shape["to"]]:
		points.append_array(_box_points(AABB(Vector3(-shape.radius, 0, -shape.radius), Vector3(shape.radius * 2, 0.08, shape.radius * 2)), Transform3D(Basis.IDENTITY, centre)))
	return points


func _response_points(landing: Vector3, attack: Vector3) -> Array:
	var points: Array = []
	for point: Vector3 in _hero_points():
		points.append(point + landing - hero.global_position)
		points.append(point + attack - hero.global_position)
	return points


func _box_points(bounds: AABB, frame: Transform3D) -> Array:
	var points: Array = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]: points.append(frame * Vector3(x, y, z))
	return points


func _unique_points(points: Array) -> Array:
	var result: Array = []
	for point: Vector3 in points:
		if not result.has(point): result.append(point)
	return result


func _floor_error() -> String:
	if not is_instance_valid(_floor) or _floor != get_node_or_null("Floor/CollisionShape3D") or _floor.shape != _floor_shape or not is_instance_valid(_floor_shape) or _floor_shape.size != Layout.FLOOR_SIZE or _floor.global_transform != _floor_frame or _floor.disabled: return "Retain actual rehearsal BOX floor"
	var floor := _floor.get_parent() as StaticBody3D
	if floor == null or floor.get_parent() != self or floor.global_transform != Transform3D(Basis.IDENTITY, Layout.FLOOR_CENTRE) or floor.collision_layer != 1 or floor.collision_mask != 0: return "Retain exact static court support"
	return ""


func _contact_error() -> String:
	for name: String in _contact_pins:
		var pin: Dictionary = _contact_pins[name]
		var area: Area3D = pin.area
		var collision: CollisionShape3D = pin.collision
		if not is_instance_valid(area) or not is_instance_valid(collision) or area.get_parent() != self or area.is_queued_for_deletion() or area.global_transform != pin.frame or area.get_node_or_null("CollisionShape3D") != collision or collision.shape != pin.shape or collision.transform != pin.collision_frame or (collision.shape as BoxShape3D).size != pin.size or collision.disabled or area.collision_layer != pin.layer or area.collision_mask != pin.mask: return "Retain actual contact Area/frame/shape/masks"
	return ""


func _native_runtime_error() -> String:
	if not _construction_error.is_empty(): return _construction_error
	if not _running or not is_instance_valid(hero) or not is_instance_valid(scheduler) or scheduler.get_parent() != self: return "Actual entered native rehearsal required"
	var error: String = _floor_error()
	if error.is_empty(): error = _contact_error()
	if not error.is_empty(): return error
	if not is_instance_valid(_court_art) or _court_art.get_parent() != self or get_node_or_null("CourtArt") != _court_art: return "Retain actual entrance court art"
	error = String(_court_art.call("binding_error"))
	if not error.is_empty(): return error
	if not Codec.keys_error(sources, Layout.SOURCE_IDS).is_empty() or not Codec.keys_error(_trusted_configurations, Layout.SOURCE_IDS).is_empty(): return "Retain exactly six finite source/configuration identities"
	for id: String in Layout.SOURCE_IDS:
		var actor := sources.get(id) as Act1MushroomSelenite
		if not _retained_source(actor, id): return "Retain original C32 source: " + id
		var native: Dictionary = actor.get_spore_native_bindings()
		if native.get("player") != hero or native.get("scheduler") != scheduler or Exact.stringify(native.get("configuration", {})) != Exact.stringify(_trusted_configurations[id]): return "Retain actual native source aliases and configuration: " + id
	return ""


func rehearsal_state() -> Dictionary:
	var actors: Dictionary = {}
	for id: String in Layout.SOURCE_IDS:
		var actor := sources.get(id) as Act1MushroomSelenite
		actors[id] = actor.pure_presentation_state() if is_instance_valid(actor) else {}
	return {"exercise_index": exercise_index, "stage": stage, "completed_exercises": completed_exercises.duplicate(), "checkpoint_published": checkpoint_published, "bell_armed": bell_armed, "recipes": recipes.duplicate(true), "admission_cursor": admission_cursor, "admission_gate": admission_gate.duplicate(true), "source_states": actors, "running": _running, "construction_error": _construction_error, "last_encounter_error": last_encounter_error}


func contract_error() -> String:
	return _construction_error if not _construction_error.is_empty() else super.contract_error()


func snapshot_state() -> Dictionary:
	last_snapshot_error = SNAPSHOT_PENDING
	return {}


func snapshot_state_for_presentation(_camera: Camera3D, _hud: GameHUD) -> Dictionary:
	last_snapshot_error = SNAPSHOT_PENDING
	return {}


func _local_snapshot_error(_state: Dictionary) -> String:
	return SNAPSHOT_PENDING


func _local_snapshot_error_with_player(_state: Dictionary, _saved_player: Dictionary) -> String:
	return SNAPSHOT_PENDING


func _fail_native(error: String) -> void:
	_construction_error = error
	last_encounter_error = error
	_clear_forecast()
	# Stop future host offers. Existing guard damage guards see this error and
	# refuse; ordinary exit still owns normal native cancellation and disposal.
	set_physics_process(false)


func _on_exit_level() -> void:
	_running = false; _changing = false
	_contact_epoch += 1
	_pending_bell = false; _pending_bell_exercise = -1; _pending_exit = false
	_fresh_entitlement = ""; _progress_entitlement = ""
	for id: String in sources:
		var actor := sources.get(id) as Act1MushroomSelenite
		if not is_instance_valid(actor): continue
		if actor.is_inside_tree(): actor.cancel("royal_rehearsal_exit")
		actor.remove_from_group("enemies"); actor.set_physics_process(false)
	if is_instance_valid(scheduler):
		if scheduler.is_inside_tree(): scheduler.end_encounter("royal_rehearsal_exit")
		scheduler.set_physics_process(false)
	if is_instance_valid(_bell_area): _bell_area.set_deferred("monitoring", false)
	if is_instance_valid(_exit_area): _exit_area.set_deferred("monitoring", false)
	if is_instance_valid(_bell_cue): _bell_cue.clear()
	if is_instance_valid(_exit_cue): _exit_cue.clear()
	_frames.clear(); _clear_forecast()
	set_physics_process(false)
