extends "res://scripts/campaign/level.gd"
## O3 Royal Rehearsal: one shared Player/Scheduler and six finite native C32s.
## Whole persistence uses the actual paused paired native unit and fresh
## recipient construction; restored optics use the real candidate context.

signal native_admission_published(source_id: String, answer: Dictionary)

const Layout = preload("res://scripts/acts/act1/royal_rehearsal_layout.gd")
const Guard = preload("res://scripts/acts/act1/mushroom_selenite.gd")
const CourtArt = preload("res://scripts/acts/act1/selenite_court_art.gd")
const RehearsalArt = preload("res://scripts/acts/act1/royal_rehearsal_art.gd")
const Arrangement = preload("res://scripts/combat/encounter_arrangement.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Interaction = preload("res://scripts/cues/interaction_cue.gd")
const WORLD_REVISION: int = Layout.WORLD_REVISION
const CONTACT_VIEW_DISTANCE: float = 3.6
const RehearsalCodec = preload("res://scripts/acts/act1/royal_rehearsal_codec.gd")
const ActorNativeCodec = preload("res://scripts/acts/act1/mushroom_selenite_codec.gd")
const NativeScheduler = preload("res://scripts/combat/threat_scheduler.gd")
const DifficultyData = preload("res://scripts/combat/difficulty.gd")
const BodySweep = preload("res://scripts/combat/body_sweep.gd")
const NativeCueMesh = preload("res://scripts/cues/cue_mesh.gd")
const PROOF_KEYS: Array[String] = ["accepted", "path", "landing", "attack_position", "primary_time_s", "response_complete_s", "uses_blast", "uses_invulnerability", "proof_scope"]
const SEGMENT_KEYS: Array[String] = ["from", "to", "start_s", "end_s", "kind"]

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
var _rehearsal_art: Node3D
var _constructor_open: bool = false
var _constructor_entitlements: Dictionary = {}
var _quiet_commit: bool = false
var _quiet_commit_error: String = ""
var _capture_error: String = ""
var _admission_open: bool = false
var _publication_open: bool = false
var _contact_presentation_busy: bool = false
var _accepted_frames: Dictionary = {}
var _retained_scheduler: CinderThreatScheduler
var _scheduler_script: Script
var _hero_script: Script
var _player_body: Dictionary = {}
var _hero_art: Dictionary = {}
var _source_callbacks: Dictionary = {}
var _retained_cues: Dictionary = {}
var _cue_parts: Dictionary = {}
var _contact_cue_pins: Dictionary = {}


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
	_rehearsal_art = RehearsalArt.build_geometry_art(self)
	if not is_instance_valid(_rehearsal_art):
		_construction_error = "Actual authored rehearsal bell/station art refused its binding"; return
	_construction_error = _pin_ready_transport()
	_refresh_objective()


func _on_enter_level() -> void:
	_construction_error = _bind_transport_entry()
	if not _construction_error.is_empty(): return
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
	admission_cursor = 0; admission_gate.clear(); _frames.clear(); _accepted_frames.clear(); _clear_forecast()
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
	_admission_open = true
	_admit_actor(id, recipe)
	_admission_open = false


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
	var original: Dictionary = _encode_frame(_frames[id])
	if original.is_empty(): _fail_native("Complete original native response receipt required"); return
	_accepted_frames[id] = original
	last_admission = answer.duplicate(true)
	_clear_forecast()
	if not _retained_responses_avoid(answer.reservation) or not presentation_error().is_empty():
		actor.cancel("rehearsal_current_response_or_view_lost")
		_frames.erase(id); _accepted_frames.erase(id)
		last_encounter_error = "Actual admission cancelled without erasing native cooldown/gate"
		return
	error = _admission_custody_error(id, actor, answer, admitted_hero, admitted_shell)
	if not error.is_empty(): _fail_native(error); return
	last_encounter_error = ""
	_publication_open = true
	native_admission_published.emit(id, answer.duplicate(true))
	_publication_open = false


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
	if not _live_boundary(true, true): _changing = false; return
	if not scheduler.encounter_profile().is_empty() or scheduler.has_committed_exchange():
		_changing = false; _fail_native("Actual cleared exercise did not retire its native epoch"); return
	completed_exercises.append(Layout.EXERCISE_IDS[exercise_index])
	admission_cursor = 0; admission_gate.clear(); _frames.clear(); _accepted_frames.clear(); _clear_forecast()
	bell_armed = false
	if exercise_index < 2:
		exercise_index += 1
		stage = "awaiting_bell"
		if exercise_index == 2:
			checkpoint_published = true
			_progress_entitlement = Layout.CHECKPOINT_ID
			var accepted: bool = request_checkpoint(Layout.CHECKPOINT_ID, "encounter")
			_progress_entitlement = ""
			if not accepted and _running: _fail_native("Actual pre-final checkpoint publication refused")
	else:
		stage = "complete"
		_progress_entitlement = Layout.COMPLETION_ID
		var accepted: bool = request_completion(Layout.COMPLETION_ID)
		_progress_entitlement = ""
		if not accepted and _running: _fail_native("Actual finite rehearsal completion publication refused")
	_changing = false
	if not _live_boundary(true): return
	_sync_contact_presentation(); _refresh_objective()


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
	if not _running or not is_instance_valid(hero) or _contact_presentation_busy: return
	_contact_presentation_busy = true
	var error: String = _apply_contact_presentation(false)
	_contact_presentation_busy = false
	if not error.is_empty(): _fail_native(error)


func _apply_contact_presentation(quiet: bool) -> String:
	if not is_instance_valid(_rehearsal_art): return "Retain actual rehearsal bell/station art"
	var art_state: String = "active" if stage == "active" else ("available" if stage == "awaiting_bell" and bell_armed else "spent")
	_rehearsal_art.call("apply_state", art_state, exercise_index, stage != "complete")
	var art_error: String = _rehearsal_art_state_error()
	if not art_error.is_empty(): return art_error
	var bell_state: String = "clear"
	if _near(Layout.BELL_POSITION):
		bell_state = "active" if stage == "active" else ("available" if stage == "awaiting_bell" and bell_armed else "spent")
	var available: bool = stage == "complete" and is_completed() and _contact_exit_id.is_empty() and _near(Layout.EXIT_POSITION)
	var exit_state: String = "available" if available else ("spent" if stage == "complete" and not _contact_exit_id.is_empty() and _near(Layout.EXIT_POSITION) else "clear")
	if quiet:
		_bell_area.monitoring = true
		_exit_area.monitoring = available
	else: _exit_area.set_deferred("monitoring", available)
	for item: Array in [[_bell_cue, bell_state], [_exit_cue, exit_state]]:
		var cue: CinderInteractionCue = item[0]
		var blocked: bool = cue.is_blocking_signals()
		if quiet: cue.set_block_signals(true)
		var accepted: bool = cue.clear() if item[1] == "clear" else cue.present(item[1], "contact")
		if quiet: cue.set_block_signals(blocked)
		if not accepted: return cue.last_error
		if not _running or not is_instance_valid(hero): return "Contact presentation lost the actual entered Player"
	return ""


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
	return _construction_error.is_empty() and _quiet_commit_error.is_empty() and not _quiet_commit and not _constructor_open and _running and is_inside_tree() and not is_queued_for_deletion() and not is_restore_candidate() and (allow_changing or not _changing) and (allow_paused or not get_tree().paused) and is_instance_valid(hero) and hero.is_inside_tree() and not hero.is_queued_for_deletion() and not hero.dead and is_instance_valid(shared_shell) and shared_shell.is_inside_tree() and not shared_shell.is_queued_for_deletion()


func _retained_source(actor: Act1MushroomSelenite, id: String) -> bool:
	return is_instance_valid(actor) and actor == _retained.get(id) and actor.get_script() == Guard and actor.get_parent() == self and actor.is_inside_tree() and not actor.is_queued_for_deletion() and actor.get_world_3d() == get_world_3d()


func _refresh_frames() -> void:
	for id: String in _frames.keys():
		var actor := sources.get(id) as Act1MushroomSelenite
		if not _retained_source(actor, id): _frames.erase(id); _accepted_frames.erase(id); continue
		var found: bool = false
		for record: Dictionary in scheduler.source_control_state(actor).get("reservations", []):
			if record.id == _frames[id].reservation_id: found = true
		if not found: _frames.erase(id); _accepted_frames.erase(id)


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
	var camera: Camera3D = _actual_presentation_camera()
	if camera == null or not is_instance_valid(shared_shell): return [Vector3.INF]
	var points: Variant = shared_shell.call("player_camera_framing_points_for", hero, camera)
	return points if points is Array and points.size() == 22 else [Vector3.INF]


func _contact_points(area: Area3D, cue: CinderInteractionCue) -> Array:
	if not is_instance_valid(area) or not is_instance_valid(cue): return [Vector3.INF]
	var collision := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null or not collision.shape is BoxShape3D or collision.disabled: return [Vector3.INF]
	var shape := collision.shape as BoxShape3D
	# One eight-corner world enclosure retains the unchanged contact BOX and all
	# actual bell art bounds. Every other cue/source/response point stays intact.
	var points: Array = _bell_frame_points(collision, shape) if area == _bell_area else _box_points(AABB(-shape.size * 0.5, shape.size), collision.global_transform)
	if points.has(Vector3.INF): return points
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
	if not Codec.keys_error(_contact_pins, ["BellArea", "ExitArea"]).is_empty(): return "Retain exact bell and exit contact identity maps"
	if _bell_area != get_node_or_null("BellArea") or _exit_area != get_node_or_null("ExitArea"): return "Retain original actual contact Area aliases"
	for name: String in _contact_pins:
		var pin: Dictionary = _contact_pins[name]
		var area: Area3D = pin.area
		var collision: CollisionShape3D = pin.collision
		if not is_instance_valid(area) or not is_instance_valid(collision) or area.get_parent() != self or get_node_or_null(name) != area or area.is_queued_for_deletion() or area.global_transform != pin.frame or area.get_node_or_null("CollisionShape3D") != collision or collision.shape != pin.shape or collision.transform != pin.collision_frame or (collision.shape as BoxShape3D).size != pin.size or collision.disabled or area.collision_layer != pin.layer or area.collision_mask != pin.mask: return "Retain actual contact Area/frame/shape/masks"
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
	if not is_instance_valid(_rehearsal_art) or _rehearsal_art != get_node_or_null("RehearsalArt") or _rehearsal_art.get_parent() != self: return "Retain original actual rehearsal art"
	error = String(_rehearsal_art.call("binding_error"))
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


func _pin_ready_transport() -> String:
	_retained_scheduler = scheduler
	_scheduler_script = scheduler.get_script() as Script
	for id: String in Layout.SOURCE_IDS:
		var cue: CinderThreatCue = (sources[id] as Act1MushroomSelenite).get_cue()
		_retained_cues[id] = cue
		var pins: Dictionary = {}
		for part_name: String in ["RequiredFootprintOutline", "RequiredFootprintFill", "RequiredSourceMarker"]:
			var part := cue.get_node_or_null(part_name) as MeshInstance3D
			if part == null or _cue_part_settings(part).is_empty(): return "Retain actual ready native threat-cue resources"
			pins[part_name] = {"node": part, "material": part.material_override, "settings": _cue_part_settings(part), "transform": part.transform}
		_cue_parts[id] = pins
	for cue: CinderInteractionCue in [_bell_cue, _exit_cue]:
		var marker := cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
		if marker == null or _cue_part_settings(marker).is_empty(): return "Retain actual ready contact-cue resources"
		_contact_cue_pins[cue.name] = {"cue": cue, "frame": cue.transform, "marker": marker, "frame_marker": marker.transform, "material": marker.material_override, "settings": _cue_part_settings(marker)}
	return ""


func _bind_transport_entry() -> String:
	if not _construction_error.is_empty(): return _construction_error
	for id: String in Layout.SOURCE_IDS:
		var actor: Act1MushroomSelenite = sources[id]
		if not actor.bind(scheduler, hero): return actor.last_error
		var native: Dictionary = actor.get_spore_native_bindings()
		if native.get("player") != hero or native.get("scheduler") != scheduler or not native.get("configuration") is Dictionary: return "Retain actual native Player/Scheduler/configuration aliases"
		_trusted_configurations[id] = native.configuration.duplicate(true)
		_configuration_hashes[id] = Exact.stringify(native.configuration).sha256_text()
		_authored_positions[id] = Codec.vector3(actor.global_position)
		var callback: Callable = Callable(self, "_on_source_state").bind(id)
		_source_callbacks[id] = callback
		actor.state_changed.connect(callback)
	_player_body = BodySweep.source_description(hero)
	if _player_body.has("error") or not _player_body.get("collision") is CollisionShape3D or not _player_body.collision.shape is CapsuleShape3D: return "Actual shared Player capsule required"
	_player_body["parent"] = hero.get_parent()
	_player_body["shape"] = _player_body.collision.shape
	_player_body["transform"] = _player_body.collision.transform
	_player_body["radius"] = _player_body.collision.shape.radius
	_player_body["height"] = _player_body.collision.shape.height
	_hero_script = hero.get_script() as Script
	var sprite := hero.get_node_or_null("ActorSprite") as Sprite3D
	var shadow := hero.get_node_or_null("ContactShadow") as MeshInstance3D
	if sprite == null or shadow == null or shadow.mesh == null: return "Actual full Player billboard and contact shadow required"
	_hero_art = {"sprite": sprite, "sprite_frame": sprite.transform, "shadow": shadow, "shadow_frame": shadow.transform, "shadow_mesh": shadow.mesh, "shadow_material": shadow.material_override}
	_running = true
	return ""


func _on_source_state(state: Dictionary, id: String) -> void:
	if state.get("dead", false) or String(state.get("reservation_id", "")).is_empty() or (_frames.has(id) and _frames[id].reservation_id != state.get("reservation_id")):
		_frames.erase(id); _accepted_frames.erase(id)


func restore_candidate_construction_required() -> bool:
	return true


func restore_candidate_physics_registration_required() -> bool:
	return true # Actual immutable floor exists in _ready before registration.


func _on_enter_restore_candidate(local: Dictionary, saved_player: Dictionary) -> String:
	if not is_restore_candidate() or _running or not _constructor_entitlements.is_empty(): return "Fresh paused nonplayable rehearsal candidate required"
	var error: String = _bind_transport_entry()
	if error.is_empty(): error = _pure_saved_preflight(local, saved_player)
	if not error.is_empty(): return error
	var plan: Dictionary = RehearsalCodec.construction_plan(local, _configuration_hashes, _authored_positions)
	if plan.get("accepted") != true: return String(plan.get("error", "Owned saved-prefix construction rejected"))
	_constructor_entitlements = plan.descriptors.duplicate(true)
	_constructor_open = true
	for id: String in plan.activated_source_ids:
		var actor: Act1MushroomSelenite = sources[id]
		var accepted: bool = actor.construct_restore_recipient(self, _constructor_entitlements[id].duplicate(true))
		_constructor_entitlements.erase(id)
		if not accepted:
			_constructor_open = false; _constructor_entitlements.clear()
			return actor.last_error
	_constructor_open = false; _constructor_entitlements.clear()
	# Only the unchanged native factory exposed this prefix. No gameplay epoch,
	# native HP/cycle/profile/pose/sample or saved Player write happened here.
	return _snapshot_runtime_error()


func restore_recipient_construction_error(source: Act1MushroomSelenite, descriptor: Dictionary) -> String:
	if not _constructor_open or not is_restore_candidate() or _quiet_commit or _admission_open or _publication_open or not _quiet_commit_error.is_empty() or not descriptor.get("source_id") is String: return "Owned exact native constructor entitlement is closed"
	var id: String = descriptor.source_id
	if not _constructor_entitlements.has(id) or not _retained_source(source, id) or sources.get(id) != source or scheduler != _retained_scheduler: return "Actual same-candidate retained native recipient required"
	return "" if _same(descriptor, _constructor_entitlements[id]) else "Descriptor differs from exact unused saved-prefix entitlement"


func _pure_saved_preflight(local: Dictionary, saved_player: Dictionary) -> String:
	var error: String = RehearsalCodec.metadata_error(local)
	if error.is_empty(): error = hero.snapshot_error(saved_player)
	if not error.is_empty(): return error
	var plan: Dictionary = RehearsalCodec.construction_plan(local, _configuration_hashes, _authored_positions)
	if plan.get("accepted") != true: return String(plan.get("error", "Owned construction plan rejected"))
	if local.stage == "active":
		var profile: Dictionary = DifficultyData.new().profile(String(local.scheduler.profile.get("id", "")))
		if profile.is_empty() or not _same(profile, local.scheduler.profile): return "Exact canonical saved native profile required"
	var decoder := ActorNativeCodec.new()
	for id: String in Layout.SOURCE_IDS:
		error = decoder.context_error(local.actors[id], local.scheduler, saved_player, _trusted_configurations[id])
		if not error.is_empty(): return id + ": " + error
	return ""


func _staged_scheduler_bindings(local: Dictionary, saved_player: Dictionary) -> Dictionary:
	var result: Dictionary = scheduler_bindings().duplicate(true)
	for key: String in ["owner_positions", "owner_velocities", "owner_collision_states"]: result[key] = {}
	for id: String in Layout.SOURCE_IDS:
		var staged: Dictionary = (sources[id] as Act1MushroomSelenite).staged_actor_bindings(local.actors[id])
		if staged.is_empty() or not Codec.keys_error(staged, ["owner_positions", "owner_velocities", "owner_collision_states"]).is_empty(): return {}
		for key: String in ["owner_positions", "owner_velocities", "owner_collision_states"]:
			if not staged[key] is Dictionary: return {}
			for owner_id: String in staged[key]:
				if owner_id != id or result[key].has(owner_id): return {}
				result[key][owner_id] = staged[key][owner_id]
		if not result.owner_positions.has(id) or not result.owner_velocities.has(id): return {}
	result["hero_positions"] = {"hero": Codec.read_vector3(saved_player.motion.position)}
	return result


func _native_state_error(local: Dictionary, saved_player: Dictionary, allow_quiet: bool = false) -> String:
	var error: String = _snapshot_runtime_error(allow_quiet)
	if error.is_empty(): error = _pure_saved_preflight(local, saved_player)
	if not error.is_empty(): return error
	for id: String in Layout.SOURCE_IDS:
		error = (sources[id] as Act1MushroomSelenite).actor_snapshot_error(local.actors[id], local.scheduler, saved_player)
		if not error.is_empty(): return id + ": " + error
	var current: Dictionary = scheduler.snapshot_state(scheduler_bindings())
	if current.is_empty() or not _same(current.collision, local.scheduler.collision): return "Saved static collision bytes differ from actual candidate world"
	var plan: Dictionary = RehearsalCodec.construction_plan(local, _configuration_hashes, _authored_positions)
	for id: String in Layout.SOURCE_IDS:
		if id in plan.activated_source_ids: continue
		var pristine: Dictionary = (sources[id] as Act1MushroomSelenite).capture_state(current)
		if pristine.is_empty() or not _same(pristine, local.actors[id]): return "Future source must retain its actual entire pristine dormant packet: " + id
	var staged: Dictionary = _staged_scheduler_bindings(local, saved_player)
	if staged.is_empty(): return "Complete native owner and saved Hero staging maps required"
	error = scheduler.snapshot_error(local.scheduler, staged)
	if error.is_empty(): error = _saved_response_error(local, saved_player)
	return error if not error.is_empty() else _snapshot_runtime_error(allow_quiet)


func _capture_local_state() -> Dictionary:
	_capture_error = _snapshot_runtime_error()
	if _capture_error.is_empty(): _capture_error = _current_framing_history_error()
	if not _capture_error.is_empty(): return {}
	var player: Dictionary = hero.snapshot_state()
	var control: Dictionary = scheduler.snapshot_state(scheduler_bindings())
	if player.is_empty() or control.is_empty():
		_capture_error = "Actual whole paused Player/Scheduler capture rejected"; return {}
	var local: Dictionary = {"api_revision": RehearsalCodec.API_REVISION, "schema_version": RehearsalCodec.SCHEMA_VERSION, "world_revision": WORLD_REVISION, "exercise_index": exercise_index, "stage": stage, "completed_exercises": completed_exercises.duplicate(), "checkpoint_published": checkpoint_published, "bell_armed": bell_armed, "recipes": recipes.duplicate(true), "admission_cursor": admission_cursor, "admission_gate": admission_gate.duplicate(true), "actors": {}, "scheduler": control, "framing": _accepted_frames.duplicate(true)}
	for id: String in Layout.SOURCE_IDS:
		local.actors[id] = (sources[id] as Act1MushroomSelenite).capture_state(control)
		if local.actors[id].is_empty():
			_capture_error = "Actual whole native actor capture rejected: " + id; return {}
	_capture_error = _native_state_error(local, player)
	return local if _capture_error.is_empty() else {}


func snapshot_state() -> Dictionary:
	var hud: GameHUD = shared_shell.get("hud") as GameHUD if is_instance_valid(shared_shell) else null
	return _snapshot_in_presentation(_actual_presentation_camera(), hud)


func snapshot_state_for_presentation(camera: Camera3D, hud: GameHUD) -> Dictionary:
	return _snapshot_in_presentation(camera, hud)


func _snapshot_in_presentation(camera: Camera3D, hud: GameHUD) -> Dictionary:
	if is_restore_candidate():
		last_snapshot_error = "Nonplayable candidate cannot supply live optical capture"; return {}
	last_snapshot_error = _current_presentation_error(camera, hud)
	if not last_snapshot_error.is_empty(): return {}
	var snapshot: Dictionary = super.snapshot_state()
	if snapshot.is_empty():
		if not _capture_error.is_empty(): last_snapshot_error = _capture_error
		return {}
	last_snapshot_error = _whole_progress_error(snapshot, hero.snapshot_state())
	return snapshot if last_snapshot_error.is_empty() else {}


func _local_snapshot_error(local: Dictionary) -> String:
	return _native_state_error(local, hero.snapshot_state())


func _local_snapshot_error_with_player(local: Dictionary, saved_player: Dictionary) -> String:
	return _native_state_error(local, saved_player)


func snapshot_error(snapshot: Dictionary) -> String:
	var error: String = super.snapshot_error(snapshot)
	return error if not error.is_empty() else _whole_progress_error(snapshot, hero.snapshot_state())


func snapshot_error_with_player(snapshot: Dictionary, saved_player: Dictionary) -> String:
	var error: String = super.snapshot_error_with_player(snapshot, saved_player)
	return error if not error.is_empty() else _whole_progress_error(snapshot, saved_player)


func _whole_progress_error(snapshot: Dictionary, saved_player: Dictionary) -> String:
	if Exact.stringify(snapshot).is_empty() or not Codec.keys_error(snapshot, ["api_revision", "schema_version", "level_id", "scene_path", "local_snapshot_version", "progress", "local"]).is_empty() or not snapshot.get("schema_version") is int or not snapshot.get("local_snapshot_version") is int: return "Closed exact original CinderLevel envelope required"
	var error: String = RehearsalCodec.progress_error(snapshot.local, snapshot.progress)
	if not error.is_empty() or snapshot.progress.contact_exit_id.is_empty(): return error
	var collision: CollisionShape3D = _contact_pins[_exit_area.name].collision
	var size: Vector3 = _contact_pins[_exit_area.name].size
	var box := AABB(collision.global_position - size * 0.5, size)
	var centre: Vector3 = Codec.read_vector3(saved_player.motion.position) + _player_body.collision.position
	var half_line: float = float(_player_body.height) * 0.5 - float(_player_body.radius)
	var nearest := Vector3(clampf(centre.x, box.position.x, box.end.x), clampf(centre.y, box.position.y - half_line, box.end.y + half_line), clampf(centre.z, box.position.z, box.end.z))
	return "" if centre.distance_squared_to(nearest) <= float(_player_body.radius) * float(_player_body.radius) else "Saved completed contact lies outside actual native exit capsule/box"


func restore_state(snapshot: Dictionary) -> bool:
	if not _quiet_commit_error.is_empty():
		last_snapshot_error = "Dispose failed native candidate: " + _quiet_commit_error; return false
	last_snapshot_error = snapshot_error(snapshot)
	if not last_snapshot_error.is_empty(): return false
	var accepted: bool = super.restore_state(snapshot)
	if not accepted or not _quiet_commit_error.is_empty():
		if not _quiet_commit_error.is_empty(): last_snapshot_error = _quiet_commit_error
		return false
	# Base progress has now committed too; presentation derives from that exact
	# aggregate and cannot accidentally show the fresh candidate's empty flags.
	_quiet_commit = true
	var error: String = _apply_contact_presentation(true)
	if error.is_empty():
		_court_art.call("set_exit_open", not _contact_exit_id.is_empty())
		error = String(_court_art.call("binding_error"))
	if error.is_empty(): error = _snapshot_runtime_error(true)
	if error.is_empty(): error = _current_framing_history_error()
	_quiet_commit = false
	if not error.is_empty():
		_fail_quiet_commit(error); last_snapshot_error = _quiet_commit_error; return false
	return true


func _restore_local_state(local: Dictionary) -> void:
	_quiet_commit = true
	var player: Dictionary = hero.snapshot_state() # Shell quietly committed Player first.
	var error: String = _native_state_error(local, player, true)
	if not error.is_empty(): _fail_quiet_commit(error); return
	var staged: Dictionary = _staged_scheduler_bindings(local, player)
	for id: String in Layout.SOURCE_IDS:
		if not (sources[id] as Act1MushroomSelenite).restore_actor_state(local.actors[id]):
			_fail_quiet_commit("Actor physical " + id + ": " + sources[id].last_snapshot_error); return
	if not scheduler.restore_state(local.scheduler, staged):
		_fail_quiet_commit("Scheduler: " + scheduler.last_snapshot_error); return
	for id: String in Layout.SOURCE_IDS:
		if not (sources[id] as Act1MushroomSelenite).restore_exchange_state(local.actors[id]):
			_fail_quiet_commit("Actor exchange " + id + ": " + sources[id].last_snapshot_error); return
	exercise_index = local.exercise_index; stage = local.stage
	completed_exercises.assign(local.completed_exercises)
	checkpoint_published = local.checkpoint_published; bell_armed = local.bell_armed
	recipes = local.recipes.duplicate(true)
	admission_cursor = local.admission_cursor; admission_gate = local.admission_gate.duplicate(true)
	_accepted_frames = local.framing.duplicate(true); _frames.clear()
	for id: String in local.framing: _frames[id] = _decode_frame(local.framing[id])
	_contact_epoch += 1
	_pending_bell = false; _pending_bell_exercise = -1; _pending_exit = false
	_fresh_entitlement = ""; _progress_entitlement = ""
	_clear_forecast(); last_admission.clear(); last_encounter_error = ""
	_refresh_objective()
	_quiet_commit = false


func _fail_quiet_commit(error: String) -> void:
	_quiet_commit_error = "Dispose unexpected partial native rehearsal commit: " + error
	_quiet_commit = false; _running = false
	for actor: Act1MushroomSelenite in sources.values():
		if is_instance_valid(actor): actor.set_physics_process(false)
	if is_instance_valid(scheduler): scheduler.set_physics_process(false)
	set_physics_process(false)


func finish_restore_candidate() -> bool:
	if _quiet_commit or _constructor_open or _publication_open or _admission_open or not _quiet_commit_error.is_empty(): return false
	return super.finish_restore_candidate()


func _snapshot_runtime_error(allow_quiet: bool = false) -> String:
	if not _running or not is_inside_tree() or not get_tree().paused or _changing or _constructor_open or not _constructor_entitlements.is_empty() or (_quiet_commit and not allow_quiet) or not _quiet_commit_error.is_empty() or _admission_open or _publication_open or _contact_presentation_busy or _pending_bell or _pending_exit or not _fresh_entitlement.is_empty() or not _progress_entitlement.is_empty(): return "Actual paused native boundary outside construction/publication/contact callbacks required"
	var error: String = _native_runtime_error()
	if not error.is_empty(): return error
	if global_transform != Transform3D.IDENTITY or scheduler != _retained_scheduler or scheduler.get_script() != _scheduler_script or get_node_or_null("RehearsalThreatScheduler") != scheduler or not scheduler.is_inside_tree() or scheduler.is_queued_for_deletion(): return "Retain original single actual native Scheduler/world frame"
	if hero.get_script() != _hero_script or not hero.is_inside_tree() or hero.is_queued_for_deletion() or hero.get_world_3d() != get_world_3d() or _world_root() == null: return "Retain actual same-world shared Player"
	var body: Dictionary = BodySweep.source_description(hero)
	if body.has("error") or _player_body.is_empty() or body.get("collision") != _player_body.collision or hero.get_parent() != _player_body.parent or _player_body.collision.shape != _player_body.shape or _player_body.collision.transform != _player_body.transform or _player_body.shape.radius != _player_body.radius or _player_body.shape.height != _player_body.height: return "Retain actual Player capsule resources/frame"
	if _hero_art.is_empty() or hero.get_node_or_null("ActorSprite") != _hero_art.sprite or hero.get_node_or_null("ContactShadow") != _hero_art.shadow or not is_instance_valid(_hero_art.sprite) or not is_instance_valid(_hero_art.shadow) or not _hero_art.sprite.is_visible_in_tree() or not _hero_art.shadow.is_visible_in_tree() or _hero_art.sprite.transform != _hero_art.sprite_frame or _hero_art.shadow.transform != _hero_art.shadow_frame or _hero_art.shadow.mesh != _hero_art.shadow_mesh or _hero_art.shadow.material_override != _hero_art.shadow_material: return "Retain actual Player billboard/contact-shadow resources"
	for id: String in Layout.SOURCE_IDS:
		var actor: Act1MushroomSelenite = sources[id]
		error = actor.body_binding_error()
		if error.is_empty(): error = actor.art_binding_error()
		if error.is_empty(): error = _native_cue_resources_error(id)
		if not error.is_empty(): return id + ": " + error
		var callback: Callable = Callable(self, "_on_source_state").bind(id)
		if _source_callbacks.get(id) != callback or not actor.state_changed.is_connected(callback) or actor.activation_guard != Callable(self, "_fresh_activation_entitled") or actor.presentation_guard != Callable(self, "presentation_error"): return "Retain original source observers/authorization guards"
	if not _bell_area.body_entered.is_connected(_bell_contact) or not _exit_area.body_entered.is_connected(_exit_contact): return "Retain original native contact observers"
	return _contact_cue_resources_error()


func _current_framing_history_error() -> String:
	if not Codec.keys_error(_frames, _accepted_frames.keys()).is_empty(): return "Current response anchors require exactly the original accepted history"
	var leased: Array[String] = []
	for id: String in Layout.SOURCE_IDS:
		var control: Dictionary = scheduler.source_control_state(sources[id])
		if control.get("outside_transaction") != true: return "Actual native source-control boundary required"
		for record: Dictionary in control.get("reservations", []):
			leased.append(id)
			if not _frames.has(id) or _frames[id].reservation_id != record.id: return "Original response receipt required for every actual native lease"
	if not Codec.keys_error(_frames, leased).is_empty(): return "Retired native leases cannot retain live response receipts"
	for id: String in _frames:
		var encoded: Dictionary = _encode_frame(_frames[id])
		if encoded.is_empty() or not _same(encoded, _accepted_frames[id]): return "Current framing differs from original native admitted receipt: " + id
	return ""


func _encode_frame(frame: Dictionary) -> Dictionary:
	if not Codec.keys_error(frame, RehearsalCodec.FRAME_KEYS).is_empty() or not frame.landing is Vector3 or not frame.attack_position is Vector3 or not frame.proof is Dictionary: return {}
	var proof: Dictionary = frame.proof
	if not Codec.keys_error(proof, PROOF_KEYS).is_empty() or not proof.landing is Vector3 or not proof.attack_position is Vector3 or not proof.path is Array: return {}
	var encoded: Dictionary = proof.duplicate(true)
	encoded.landing = Codec.vector3(proof.landing); encoded.attack_position = Codec.vector3(proof.attack_position)
	encoded.path = []
	for value: Variant in proof.path:
		if not value is Dictionary or not Codec.keys_error(value, SEGMENT_KEYS).is_empty() or not value.from is Vector3 or not value.to is Vector3: return {}
		var segment: Dictionary = value.duplicate(true)
		segment.from = Codec.vector3(value.from); segment.to = Codec.vector3(value.to)
		encoded.path.append(segment)
	var result: Dictionary = {"reservation_id": frame.reservation_id, "landing": Codec.vector3(frame.landing), "attack_position": Codec.vector3(frame.attack_position), "proof": encoded}
	return result if not Exact.stringify(result).is_empty() else {}


func _decode_frame(frame: Dictionary) -> Dictionary:
	var decoded: Dictionary = frame.duplicate(true)
	decoded.landing = Codec.read_vector3(frame.landing); decoded.attack_position = Codec.read_vector3(frame.attack_position)
	decoded.proof.landing = Codec.read_vector3(frame.proof.landing); decoded.proof.attack_position = Codec.read_vector3(frame.proof.attack_position)
	for segment: Dictionary in decoded.proof.path:
		segment.from = Codec.read_vector3(segment.from); segment.to = Codec.read_vector3(segment.to)
	return decoded


func _saved_response_error(local: Dictionary, saved_player: Dictionary) -> String:
	if not _same(hero.equipment.snapshot(), saved_player.equipment): return "Actual candidate equipment must match saved Player before ordinary response proof"
	var stats: Dictionary = hero.equipment.resolved_stats()
	var threats: Array[Dictionary] = []
	for record: Dictionary in local.scheduler.reservations:
		var shape: Dictionary = record.geometry.duplicate(true)
		for key: String in ["from", "to"]: shape[key] = Codec.read_vector3(shape[key])
		var error: String = Geometry.error(shape)
		if not error.is_empty(): return error
		threats.append({"record": record, "shape": shape})
	for item: Dictionary in threats:
		var record: Dictionary = item.record
		var frame: Dictionary = _decode_frame(local.framing[record.source_id])
		var proof: Dictionary = frame.proof
		var path: Array[Dictionary] = []
		for segment: Dictionary in proof.path: path.append(segment)
		if path[0].end_s < record.start_s + 0.18: return "Saved original response removes its recognition margin"
		if path.size() == 6 and path[3].start_s < maxf(maxf(path[1].end_s, record.active_until_s + CinderThreatScheduler.TIME_MARGIN), path[1].start_s + float(stats.dash_cooldown)): return "Saved positioning dash skips native cooldown/recovery"
		var input_ready: float = path[3].end_s if path.size() == 6 else maxf(path[1].end_s, record.active_until_s + CinderThreatScheduler.TIME_MARGIN)
		if proof.primary_time_s < input_ready + 0.08: return "Saved original primary removes its input margin"
		for segment: Dictionary in path:
			var move: Vector3 = segment.to - segment.from
			if segment.kind in ["escape_dash", "positioning_dash"]:
				if absf(move.y) > BodySweep.EPSILON or absf(move.length() - float(stats.dash_distance)) > BodySweep.position_rounding_bound(segment.from, segment.to) or segment.end_s != segment.start_s + float(stats.dash_duration): return "Retain original full native response dash distance/duration"
			elif move != Vector3.ZERO: return "Stationary original response cannot hide travel"
			var sweep: Dictionary = BodySweep.sweep(hero, Transform3D(Basis.IDENTITY, segment.from), move, scheduler_bindings().floors.values())
			if sweep.has("error") or sweep.get("collided", true) or not sweep.get("end") is Vector3 or sweep.end.distance_to(segment.to) > BodySweep.position_rounding_bound(segment.from, segment.to): return "Saved original response lacks actual static floor/full capsule support"
		for threat: Dictionary in threats:
			if Geometry.timed_path_hits(threat.shape, path, threat.record.active_from_s, threat.record.active_until_s, float(_player_body.radius) + CinderThreatScheduler.SKIN): return "Saved original response crosses the retained native threat union"
		var opening: Vector3 = Codec.read_vector3(record.opening_position)
		var attack: Vector3 = frame.attack_position
		if Vector2(opening.x - attack.x, opening.z - attack.z).length() > float(stats.primary_range) - CinderThreatScheduler.SKIN or absf(opening.y - attack.y) > 1.4: return "Saved original primary cannot reach the actual stationary native source"
		var ray := PhysicsRayQueryParameters3D.create(attack + Vector3.UP * 0.7, opening + Vector3.UP * 0.7, 1)
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return "Actual static scenery blocks the original primary"
		if proof.response_complete_s < proof.primary_time_s + float(stats.primary_cooldown): return "Saved original response truncates native primary recovery"
	return ""


func _actual_presentation_camera() -> Camera3D:
	if not is_inside_tree(): return null
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or camera.get_script() != null or not camera.is_inside_tree() or not camera.is_node_ready() or camera.is_queued_for_deletion() or camera.get_viewport() != get_viewport() or camera.get_world_3d() != get_world_3d(): return null
	return camera


func _current_presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	var error: String = _snapshot_runtime_error()
	if error.is_empty(): error = _current_framing_history_error()
	if not error.is_empty(): return error
	if camera == null or camera != _actual_presentation_camera() or not is_instance_valid(hud): return "Actual current native camera and canonical laid-out HUD required"
	var reference: Variant = shared_shell.get("camera")
	# The unchanged public native billboard helper uses the fixed shared basis;
	# candidate position, focus, Player and HUD always use this actual context.
	if not is_instance_valid(reference) or not reference is Camera3D or reference.get_script() != null or camera.global_basis != reference.global_basis: return "Actual candidate retains exact shared fixed billboard basis"
	error = _contact_presentation_error()
	if not error.is_empty(): return error
	var points: Array = _camera_framing_points()
	if _hero_points().size() != 22 or points.is_empty() or points.size() > 224 or points.has(Vector3.INF): return "Complete actual Player/source/cue/response bounds required"
	return String(shared_shell.call("camera_framing_error_for_context", points, hero, camera, hud))


func _restore_candidate_presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	if _quiet_commit or _constructor_open or not _quiet_commit_error.is_empty(): return "Dispose incomplete or failed native candidate"
	return _current_presentation_error(camera, hud)


func _contact_presentation_error() -> String:
	var error: String = _rehearsal_art_state_error()
	if not error.is_empty(): return error
	var expected_bell: String = "clear"
	if _near(Layout.BELL_POSITION): expected_bell = "active" if stage == "active" else ("available" if stage == "awaiting_bell" and bell_armed else "spent")
	var available: bool = stage == "complete" and is_completed() and _contact_exit_id.is_empty() and _near(Layout.EXIT_POSITION)
	var expected_exit: String = "available" if available else ("spent" if stage == "complete" and not _contact_exit_id.is_empty() and _near(Layout.EXIT_POSITION) else "clear")
	if _bell_cue.state().state != expected_bell or _exit_cue.state().state != expected_exit or not _bell_area.monitoring or _exit_area.monitoring != available: return "Actual contact presentation/monitoring differs from its settled native boundary"
	return ""


func _contact_cue_resources_error() -> String:
	for name: String in ["BellContactCue", "ExitContactCue"]:
		if not _contact_cue_pins.has(name): return "Retain both actual contact cue resource maps"
		var pin: Dictionary = _contact_cue_pins[name]
		var cue: CinderInteractionCue = pin.cue
		var marker: MeshInstance3D = pin.marker
		if not is_instance_valid(cue) or cue != get_node_or_null(name) or cue.get_parent() != self or cue.get_script() != Interaction or cue.is_queued_for_deletion() or cue.transform != pin.frame or not is_instance_valid(marker) or cue.get_node_or_null("RequiredInteractionMarker") != marker or marker.get_parent() != cue or marker.transform != pin.frame_marker or marker.material_override != pin.material or _cue_part_settings(marker) != pin.settings: return "Retain original contact cue node/material/settings"
		var shown: Dictionary = cue.state()
		if shown.state == "clear":
			if marker.mesh != null or marker.visible: return "Clear native contact retains null hidden mesh"
		else:
			if shown.trigger != "contact" or not shown.required or not shown.visible or not marker.is_visible_in_tree() or not _same_native_mesh(marker.mesh, NativeCueMesh.interaction_mesh(shown.state, "contact")): return "Actual native contact glyph differs from current logical state"
			var color := Color(0.88, 0.92, 0.82, 0.85)
			if shown.state == "active": color = Color(1.0, 0.98, 0.87, 1.0)
			elif shown.state == "spent": color = Color(0.64, 0.68, 0.65, 0.40)
			if (pin.material as StandardMaterial3D).albedo_color != color: return "Actual native contact color differs from its logical state"
	return ""


func _rehearsal_art_state_error() -> String:
	if not is_instance_valid(_rehearsal_art): return "Actual rehearsal art required"
	var error: String = String(_rehearsal_art.call("binding_error"))
	if not error.is_empty(): return error
	var bell_state: String = "active" if stage == "active" else ("available" if stage == "awaiting_bell" and bell_armed else "spent")
	var expected: Dictionary = {"api_revision": RehearsalArt.API_REVISION, "bell_state": bell_state, "exercise_index": exercise_index, "markers_visible": stage != "complete"}
	return "" if _same(_rehearsal_art.call("presentation_state"), expected) else "Actual clockless bell/marker pose differs from owned progress"


func _bell_frame_points(collision: CollisionShape3D, shape: BoxShape3D) -> Array:
	if not _contact_error().is_empty() or not _rehearsal_art_state_error().is_empty(): return [Vector3.INF]
	if collision != _contact_pins[_bell_area.name].collision or shape != _contact_pins[_bell_area.name].shape: return [Vector3.INF]
	var corners: Variant = _rehearsal_art.call("landmark_world_corners", "bell")
	if not corners is Array or corners.size() != 8: return [Vector3.INF]
	var actual_points: Array = _box_points(AABB(-shape.size * 0.5, shape.size), collision.global_transform)
	actual_points.append_array(corners)
	for value: Variant in actual_points:
		if not value is Vector3 or not value.is_finite(): return [Vector3.INF]
	# Derive the complete world union from current retained native geometry;
	# these are framing bounds only, never a replacement contact/collision shape.
	var bounds := AABB(actual_points[0], Vector3.ZERO)
	for point: Vector3 in actual_points: bounds = bounds.expand(point)
	if not bounds.position.is_finite() or not bounds.end.is_finite() or not bounds.size.is_finite() or bounds.size.x <= 0.0 or bounds.size.y <= 0.0 or bounds.size.z <= 0.0: return [Vector3.INF]
	for point: Vector3 in actual_points:
		if point.x < bounds.position.x or point.y < bounds.position.y or point.z < bounds.position.z or point.x > bounds.end.x or point.y > bounds.end.y or point.z > bounds.end.z: return [Vector3.INF]
	var enclosure: Array = _box_points(bounds, Transform3D.IDENTITY)
	for point: Vector3 in enclosure:
		if not point.is_finite(): return [Vector3.INF]
	return enclosure


func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = Exact.stringify(left)
	return not encoded.is_empty() and encoded == Exact.stringify(right)


func _cue_part_settings(part: MeshInstance3D) -> Array:
	var material := part.material_override as StandardMaterial3D
	if material == null or material.get_script() != null or material.next_pass != null: return []
	# Native phase owns color/visibility/mesh. Fixed required depth and renderer
	# settings remain the actual ready readbacks, never repaired during capture.
	return [part.get_script(), part.layers, part.cast_shadow, part.material_overlay, part.transparency, part.extra_cull_margin, part.visibility_range_begin, part.visibility_range_end, part.visibility_range_fade_mode, part.ignore_occlusion_culling, material.shading_mode, material.transparency, material.cull_mode, material.texture_filter, material.no_depth_test, material.albedo_texture]


func _native_cue_resources_error(id: String) -> String:
	var retained: Variant = _retained_cues.get(id)
	if not is_instance_valid(retained) or not retained is CinderThreatCue: return "Retain actual required native cue before typed validation: " + id
	var cue: CinderThreatCue = retained
	if not cue.is_inside_tree() or cue.is_queued_for_deletion() or cue.get_parent() != sources.get(id) or cue.get_script() != CinderThreatCue or not cue.is_in_group("required_cues") or not cue.is_set_as_top_level() or not cue.visible: return "Retain actual required native threat cue: " + id
	var shown: Dictionary = cue.state() # Pure logical read; no prune/presentation.
	var actual: Dictionary = (sources[id] as Act1MushroomSelenite).pure_presentation_state()
	if shown.phase != actual.phase: return "Actual required cue must show the current native exchange phase: " + id
	if shown.phase != "clear" and (shown.geometry != NativeCueMesh.canonical_geometry(actual.geometry) or shown.source_position != actual.source_position): return "Actual required cue must retain its current native geometry/source: " + id
	if cue.global_basis != Basis.IDENTITY: return "Retain the native identity threat-cue world basis: " + id
	if shown.phase != "clear":
		if not Geometry.error(shown.geometry).is_empty() or cue.global_position != NativeCueMesh.anchor(shown.geometry): return "Actual threat cue moved from its native logical geometry anchor: " + id
	var pins: Dictionary = _cue_parts.get(id, {})
	for part_name: String in ["RequiredFootprintOutline", "RequiredFootprintFill", "RequiredSourceMarker"]:
		if not pins.has(part_name): return "Actual ready native cue pins absent"
		var pin: Dictionary = pins[part_name]
		var part := cue.get_node_or_null(part_name) as MeshInstance3D
		if not is_instance_valid(part) or part != pin.node or not part.is_inside_tree() or part.is_queued_for_deletion() or part.get_parent() != cue or part.is_set_as_top_level() or part.material_override != pin.material or _cue_part_settings(part) != pin.settings: return "Retain actual native threat-cue node/material/settings: " + id
		if part_name != "RequiredSourceMarker" and part.transform != pin.transform: return "Retain actual native footprint local frame: " + id
		if part_name == "RequiredSourceMarker" and part.basis != pin.transform.basis: return "Retain actual native source glyph basis: " + id
		if shown.phase == "clear":
			if part.mesh != null or part.visible: return "Clear native cue cannot retain visible threat meshes: " + id
			continue
		var colors: Dictionary = {"warning": Color(1.0, 0.90, 0.63, 0.95), "lock": Color(1.0, 0.76, 0.35, 1.0), "active": Color(1.0, 0.43, 0.26, 1.0), "recovery": Color(0.77, 0.88, 0.90, 0.70)}
		if not colors.has(shown.phase): return "Actual supported native cue phase required"
		var color: Color = colors[shown.phase]
		var expected_color: Color = Color(color.r, color.g, color.b, 0.22) if part_name == "RequiredFootprintFill" else color
		if var_to_bytes((pin.material as StandardMaterial3D).albedo_color) != var_to_bytes(expected_color): return "Actual required cue phase color/alpha changed: " + id
		var expected: ArrayMesh
		var expected_visible: bool
		if part_name == "RequiredSourceMarker":
			expected = NativeCueMesh.source_mesh(shown.phase)
			expected_visible = true
			if part.position != shown.source_position - cue.global_position + Vector3.UP * pin.transform.origin.y: return "Actual source glyph moved from the native cue source"
		else:
			expected = NativeCueMesh.geometry_mesh(shown.geometry, part_name == "RequiredFootprintFill")
			expected_visible = shown.phase == "active" if part_name == "RequiredFootprintFill" else shown.phase != "recovery"
		if part.visible != expected_visible or not _same_native_mesh(part.mesh, expected): return "Required native phase mesh/visibility changed: " + id
	return ""


func _same_native_mesh(actual: Variant, expected: ArrayMesh) -> bool:
	if not is_instance_valid(actual) or not actual is ArrayMesh or not is_instance_valid(expected): return false
	var native: ArrayMesh = actual
	if native.get_aabb() != expected.get_aabb() or native.get_surface_count() != expected.get_surface_count(): return false
	for surface: int in range(expected.get_surface_count()):
		if native.surface_get_primitive_type(surface) != expected.surface_get_primitive_type(surface) or native.surface_get_arrays(surface) != expected.surface_get_arrays(surface): return false
	return true


func _fail_native(error: String) -> void:
	_construction_error = error
	last_encounter_error = error
	_clear_forecast()
	# Stop future host offers. Existing guard damage guards see this error and
	# refuse; ordinary exit still owns normal native cancellation and disposal.
	set_physics_process(false)


func _on_exit_level() -> void:
	_running = false; _changing = false
	_constructor_open = false; _constructor_entitlements.clear()
	_publication_open = false; _admission_open = false; _contact_presentation_busy = false
	_contact_epoch += 1
	_pending_bell = false; _pending_bell_exercise = -1; _pending_exit = false
	_fresh_entitlement = ""; _progress_entitlement = ""
	for id: String in sources:
		var actor := sources.get(id) as Act1MushroomSelenite
		if not is_instance_valid(actor): continue
		var callback: Callable = _source_callbacks.get(id, Callable())
		if callback.is_valid() and actor.state_changed.is_connected(callback): actor.state_changed.disconnect(callback)
		if actor.is_inside_tree(): actor.cancel("royal_rehearsal_exit")
		actor.remove_from_group("enemies"); actor.set_physics_process(false)
	if is_instance_valid(scheduler):
		if scheduler.is_inside_tree(): scheduler.end_encounter("royal_rehearsal_exit")
		scheduler.set_physics_process(false)
	if is_instance_valid(_bell_area): _bell_area.set_deferred("monitoring", false)
	if is_instance_valid(_exit_area): _exit_area.set_deferred("monitoring", false)
	if is_instance_valid(_bell_cue): _bell_cue.clear()
	if is_instance_valid(_exit_cue): _exit_cue.clear()
	_frames.clear(); _accepted_frames.clear(); _clear_forecast()
	set_physics_process(false)
