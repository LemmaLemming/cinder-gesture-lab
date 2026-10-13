extends CinderLevel
## Whole L4 gameplay draft. Unregistered/unexecuted; aggregate codec unfinished.
## One real Hero and shared Scheduler. No private input/camera/HUD/save system.

const Layout = preload("res://scripts/acts/act1/selenite_court_layout.gd")
const Guard = preload("res://scripts/acts/act1/mushroom_selenite.gd")
const King = preload("res://scripts/acts/act1/selenite_king.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const BodySweep = preload("res://scripts/combat/body_sweep.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Cue = preload("res://scripts/cues/interaction_cue.gd")
const WORLD_REVISION: int = 1
const COMPLETE_ID: String = "court-clear"
const EXIT_ID: String = "court-exterior"

var scheduler: CinderThreatScheduler
var sources: Dictionary = {}
var roundel: CinderLaneMechanism
var room: int = 0
var formation: String = "parallel"
var helper_stage: String = "unborn"
var last_encounter_error: String = ""
var _running: bool = false
var _construction_error: String = ""
var _fresh_entitlement: String = ""
var _phase_entitlements: Dictionary = {}
var _entry_records: Dictionary = {}
var _entry_outcomes: Dictionary = {}
var _frames: Dictionary = {}
var _forecast: Array = []
var _forecast_frames: Dictionary = {}
var _retained: Dictionary = {}
var _floor: CollisionShape3D
var _floor_shape: BoxShape3D
var _floor_frame: Transform3D
var _boss_area: Area3D
var _exit_area: Area3D
var _boss_cue: CinderInteractionCue
var _exit_cue: CinderInteractionCue
var _awaiting_room: int = -1
var _roundel_demonstrated: bool = false
var _roundel_cycle: int = 0
var _helpers_once: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 200
	_floor = get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
	_floor_shape = _floor.shape as BoxShape3D if is_instance_valid(_floor) else null
	_floor_frame = _floor.global_transform if is_instance_valid(_floor) else Transform3D.IDENTITY
	if not _floor_error().is_empty(): _construction_error = _floor_error(); return
	scheduler = CinderThreatScheduler.new()
	scheduler.name = "CourtThreatScheduler"
	add_child(scheduler)
	for id: String in Layout.SOURCES:
		var spec: Dictionary = Layout.SOURCES[id]
		var actor: CharacterBody3D = King.new() if spec.role == "B01" else Guard.new()
		actor.name = id
		actor.position = spec.position
		var configured: bool = actor.call("configure", id, King.DEFAULT_RAW_ROLE, King.DEFAULT_TIMING_FLOORS, King.DEFAULT_LUNGE, true) if spec.role == "B01" else actor.call("configure", "C32", id, true, false)
		if not configured: _construction_error = String(actor.get("last_error")); actor.free(); return
		add_child(actor)
		sources[id] = actor
		_retained[id] = actor
		actor.set("activation_guard", Callable(self, "_fresh_activation_entitled"))
		actor.set("presentation_guard", Callable(self, "presentation_error"))
	roundel = CinderLaneMechanism.new()
	roundel.name = "CourtRoundel"
	roundel.position = Layout.ROUND_EL_POSITION
	if not roundel.configure(Layout.ROUND_EL_ID, Geometry.circle(Layout.ROUND_EL_POSITION, Layout.ROUND_EL_RADIUS), Layout.ROUND_EL_POSITION + Vector3(0, 0, 2)):
		_construction_error = roundel.last_error; roundel.free(); return
	add_child(roundel)
	_boss_area = get_node_or_null("BossContactArea") as Area3D
	_exit_area = get_node_or_null("ExitArea") as Area3D
	if not is_instance_valid(_boss_area) or not is_instance_valid(_exit_area): _construction_error = "Retain actual boss and exit contact Areas"; return
	_boss_area.body_entered.connect(_boss_contact)
	_exit_area.body_entered.connect(_exit_contact)
	_boss_cue = Cue.new(); _boss_cue.name = "BossContactCue"; _boss_cue.position = Layout.BOSS_CONTACT_POSITION + Vector3(0, 0.035, 0); add_child(_boss_cue)
	_exit_cue = Cue.new(); _exit_cue.name = "ExteriorContactCue"; _exit_cue.position = Layout.EXIT_POSITION + Vector3(0, 0.035, 0); add_child(_exit_cue)


func _on_enter_level() -> void:
	if not _construction_error.is_empty(): return
	for actor: CharacterBody3D in sources.values():
		if actor.call("bind", scheduler, hero) != true: _construction_error = String(actor.get("last_error")); return
	if not roundel.bind(scheduler, {"hero": hero}) or not roundel.set_presentation_guard(Callable(self, "_roundel_presentation")):
		_construction_error = roundel.last_error; return
	_running = true
	_begin_room(0)


func _begin_room(next: int) -> void:
	if not _running or next < 0 or next > 3 or not _live_boundary(null, null, next == 0 and scheduler.encounter_profile().is_empty()): return
	room = next
	_awaiting_room = -1
	var profile: String = String(shared_shell.call("get_difficulty_preference")) if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference") else "standard"
	if not scheduler.begin_encounter(profile, _encounter_id(), WORLD_REVISION): _construction_error = scheduler.last_error; return
	_frames.clear(); _forecast.clear()
	for id: String in ([] if room == 2 and not _roundel_demonstrated else Layout.ROOM_SOURCE_IDS[room]):
		_fresh_entitlement = id
		var accepted: bool = sources[id].call("activate")
		_fresh_entitlement = ""
		if not accepted: _construction_error = String(sources[id].get("last_error")); return
	_refresh_objective()


func _fresh_activation_entitled(id: String) -> bool:
	return _running and id == _fresh_entitlement and Layout.ROOM_SOURCE_IDS[room].has(id) and scheduler.get_clock() == 0.0 and scheduler.encounter_profile().get("id", "") != "" and not scheduler.has_committed_exchange()


func _physics_process(_delta: float) -> void:
	if not _running or not _construction_error.is_empty() or not is_instance_valid(hero) or hero.dead or get_tree().paused: return
	_refresh_frames()
	if _awaiting_room >= 0:
		if _awaiting_room == 3:
			_boss_area.set_deferred("monitoring", true)
			_boss_cue.present("available", "contact")
		elif hero.global_position.z <= (-6.0 if _awaiting_room == 1 else -14.0): _begin_room(_awaiting_room)
		return
	if room == 1 and formation == "parallel" and _parallel_demonstrated():
		# Same identities/HP/cycle/profile. Ordinary cancel retains native cooldown.
		for id: String in Layout.ROOM_SOURCE_IDS[1]:
			if not sources[id].get("dead"): sources[id].call("cancel", "court_formation_inward")
		formation = "inward"
		_frames.clear()
	if room == 2 and not _roundel_demonstrated:
		var state: Dictionary = roundel.state()
		if state.cycle > 0 and state.status == "complete":
			# The quiet known impact ends before the guard combination begins.
			# This is an explicit new encounter boundary, not a formation reset.
			_roundel_demonstrated = true
			scheduler.end_encounter("court_roundel_demonstration_complete")
			_begin_room(2)
		else: _admit_roundel(); return
	if room == 3 and float(sources["court-king"].get("hp")) <= 40.0 and not sources["court-king"].get("dead"):
		_enter_helper_phase()
	if room >= 3 and sources["court-king"].get("dead"):
		_finish_king_defeat()
		return
	if room == 4 and helper_stage in ["settling", "entering"]:
		_update_helper_entry()
		return
	if room <= 2 and _room_dead():
		if room == 2: roundel.cancel("approach_complete")
		scheduler.end_encounter("court_boundary")
		request_checkpoint("court-after-" + Layout.ROOM_IDS[room], "encounter")
		_awaiting_room = room + 1
		_refresh_objective()
		return
	if not hero.get_threat_response_state().stable: return
	# Known helper thrusts get admission priority before the continuing King.
	for id: String in _current_ids(): _admit_actor(id)
	if room == 2: _admit_roundel()
	_refresh_objective()


func _parallel_demonstrated() -> bool:
	var living: bool = false
	for id: String in Layout.ROOM_SOURCE_IDS[1]:
		var state: Dictionary = sources[id].call("pure_presentation_state")
		if state.dead: continue
		living = true
		if int(state.cycle) < 1 or not String(state.reservation_id).is_empty(): return false
	return living


func _room_dead() -> bool:
	for id: String in Layout.ROOM_SOURCE_IDS[room]:
		if not sources[id].get("dead"): return false
	return true


func _current_ids() -> Array:
	if room == 4: return ["court-helper-west", "court-helper-east", "court-king"]
	return Layout.ROOM_SOURCE_IDS[room].duplicate()


func _admit_actor(id: String) -> void:
	var actual_source: Variant = sources.get(id)
	if not is_instance_valid(actual_source) or not actual_source is CharacterBody3D or actual_source != _retained.get(id) or actual_source.is_queued_for_deletion() or not actual_source.is_inside_tree() or actual_source.get_parent() != self:
		_construction_error = "Court admission lost its retained actual source"
		return
	var actor: CharacterBody3D = actual_source
	var state: Dictionary = actor.call("pure_presentation_state")
	if state.dead or state.dormant or not String(state.reservation_id).is_empty() or actor.global_position.distance_to(hero.global_position) > 4.5: return
	var target: Vector3 = hero.global_position
	if room == 1:
		target = actor.global_position + Vector3(0, 0, 2) if formation == "parallel" else Vector3(0, actor.global_position.y, actor.global_position.z + 1.6)
	var context: Dictionary = response_context()
	var preview: Dictionary
	var direction := Vector3(target.x - actor.global_position.x, 0, target.z - actor.global_position.z).normalized()
	if id == "court-king": preview = actor.call("preview_lunge", context, direction, _world_root())
	else:
		context["world_root"] = _world_root()
		preview = actor.call("preview_start", target, context)
	if preview.get("accepted") != true: return
	var proof: Dictionary = preview.proof
	if proof.get("uses_blast") != false or proof.get("uses_invulnerability") != false or not Codec.is_number(proof.get("primary_time_s")) or not Codec.is_number(proof.get("response_complete_s")) or float(proof.primary_time_s) < float(preview.candidate.active_until_s) or float(proof.response_complete_s) >= float(preview.candidate.recovery_until_s): return
	_forecast = _actor_points(id, preview.candidate.opening_position) + _geometry_points(preview.candidate.geometry) + _response_points(proof.landing, proof.attack_position)
	_forecast_frames = {"source": actor.global_transform, "hero": hero.global_transform, "id": id}
	if not _framing_ready(): return
	var admitted_hero: CinderPlayer = hero
	var admitted_shell: Node = shared_shell
	var answer: Dictionary = actor.call("start", context, direction, _world_root(), preview) if id == "court-king" else actor.call("start", target, context, preview)
	if answer.get("accepted") == true:
		if not _live_boundary(admitted_hero, admitted_shell) or not is_instance_valid(actor) or actor.is_queued_for_deletion() or not actor.is_inside_tree() or sources.get(id) != actor or _retained.get(id) != actor or actor.get_parent() != self:
			if is_instance_valid(actor) and actor.is_inside_tree(): actor.call("cancel", "court_admission_handle_lost")
			_frames.erase(id); _forecast.clear(); return
		var control: Dictionary = scheduler.source_control_state(actor)
		var actual: Dictionary = actor.call("pure_presentation_state")
		var actor_control: Dictionary = actual if id == "court-king" else actor.call("get_spore_response_state")
		var matching: Dictionary = {}
		for record: Dictionary in control.get("reservations", []):
			if record.get("id") == answer.reservation_id: matching = record
		if not _live_boundary(admitted_hero, admitted_shell) or sources.get(id) != actor or _retained.get(id) != actor or actor.get_parent() != self or actor.is_queued_for_deletion() or not control.get("outside_transaction", false) or not actor_control.get("outside_transaction", false) or actual.get("reservation_id") != answer.reservation_id or matching.is_empty() or var_to_bytes(matching) != var_to_bytes(answer.reservation):
			actor.call("cancel", "court_admission_custody_lost")
		else:
			_frames[id] = {"reservation_id": answer.reservation_id, "landing": answer.proof.landing, "attack_position": answer.proof.attack_position, "proof": answer.proof.duplicate(true)}
	_forecast.clear()
	if not presentation_error().is_empty(): actor.call("cancel", "court_current_view_lost"); _frames.erase(id)


func _admit_roundel() -> void:
	if hero.global_position.distance_to(Layout.ROUND_EL_POSITION) > 4.5 or not hero.get_threat_response_state().stable: return
	var preview: Dictionary = roundel.preview_start("hero", response_context())
	if preview.get("accepted") != true: return
	_forecast = _geometry_points(preview.candidate.geometry) + _response_points(preview.proof.landing, preview.proof.attack_position)
	_forecast_frames = {"source": roundel.global_transform, "hero": hero.global_transform, "id": Layout.ROUND_EL_ID}
	if not _framing_ready(): return
	var admitted_hero: CinderPlayer = hero
	var admitted_shell: Node = shared_shell
	var admitted_roundel: CinderLaneMechanism = roundel
	var answer: Dictionary = roundel.start("hero", response_context(), null, null, preview)
	if answer.get("accepted") == true:
		if not _live_boundary(admitted_hero, admitted_shell) or not is_instance_valid(roundel) or roundel != admitted_roundel or roundel.is_queued_for_deletion() or not roundel.is_inside_tree() or roundel.get_parent() != self:
			if is_instance_valid(roundel) and roundel.is_inside_tree(): roundel.cancel("court_roundel_returned_handle_lost")
			_frames.erase(Layout.ROUND_EL_ID); _forecast.clear(); return
		var control: Dictionary = scheduler.source_control_state(roundel)
		var matching: Dictionary = {}
		for record: Dictionary in control.get("reservations", []):
			if record.get("id") == answer.reservation_id: matching = record
		if not _live_boundary(admitted_hero, admitted_shell) or roundel != admitted_roundel or roundel.get_parent() != self or roundel.is_queued_for_deletion() or not control.get("outside_transaction", false) or matching.is_empty() or var_to_bytes(matching) != var_to_bytes(answer.reservation) or roundel.state().get("reservation_id") != answer.reservation_id: roundel.cancel("court_roundel_returned_admission_lost")
		else:
			_frames[Layout.ROUND_EL_ID] = {"reservation_id": answer.reservation_id, "landing": answer.proof.landing, "attack_position": answer.proof.attack_position, "proof": answer.proof.duplicate(true)}
			_roundel_cycle = int(roundel.state().cycle)
	_forecast.clear()


func _enter_helper_phase() -> void:
	var king: CharacterBody3D = sources["court-king"]
	king.call("cancel", "court_phase_two_entry")
	_frames.clear()
	room = 4
	_helpers_once = true
	helper_stage = "settling"
	for id: String in Layout.ROOM_SOURCE_IDS[4]: _phase_entitlements[id] = true
	for id: String in Layout.ROOM_SOURCE_IDS[4]:
		var accepted: bool = sources[id].call("activate_court_entry", self, _encounter_id())
		_phase_entitlements.erase(id)
		if not accepted: _construction_error = String(sources[id].get("last_error")); return
	_refresh_objective()


func court_entry_activation_error(actor: CharacterBody3D, encounter: String) -> String:
	if not _running or room != 4 or helper_stage != "settling" or not _helpers_once or is_restore_candidate() or get_tree().paused or encounter != _encounter_id(): return "Court helper birth entitlement is closed"
	for id: String in _phase_entitlements:
		if sources.get(id) == actor and _retained.get(id) == actor and actor.get_parent() == self: return ""
	return "Only the two actual once-entitled helpers may enter"


func _update_helper_entry() -> void:
	if helper_stage == "settling":
		for id: String in Layout.ROOM_SOURCE_IDS[4]:
			var actor: CharacterBody3D = sources[id]
			if actor.get("dead") or actor.get("hp") < actor.get("max_hp"):
				_entry_outcomes[id] = {"outcome": "defeated" if actor.get("dead") else "injured", "endpoint": actor.global_position}
				continue
			if not actor.is_on_floor() or actor.velocity != Vector3.ZERO: return
		var start: float = scheduler.get_clock()
		for id: String in Layout.ROOM_SOURCE_IDS[4]:
			if _entry_outcomes.has(id): continue
			var from: Vector3 = sources[id].global_position
			_entry_records[id] = {"active": true, "from": from, "to": from + Vector3(0, 0, Layout.HELPER_ENTRY_DISTANCE), "start_s": start, "end_s": start + Layout.HELPER_ENTRY_DISTANCE / Layout.HELPER_ENTRY_SPEED, "speed": Layout.HELPER_ENTRY_SPEED}
		helper_stage = "entering"
		return
	for id: String in Layout.ROOM_SOURCE_IDS[4]:
		if _entry_outcomes.has(id): continue
		var actor: CharacterBody3D = sources[id]
		if actor.get("dead") or actor.get("hp") < actor.get("max_hp"):
			_entry_outcomes[id] = {"outcome": "defeated" if actor.get("dead") else "injured", "endpoint": actor.global_position}
			continue
		if not _entry_clear(id) or _entry_deadline_missed(id):
			var stopped: Dictionary = actor.call("stop_court_entry_motion", self, _entry_records[id], "blocked")
			if stopped.get("accepted") != true: _construction_error = String(stopped.get("reason", "Native court entry stop refused")); return
			_entry_outcomes[id] = {"outcome": "blocked", "endpoint": actor.global_position}
			continue
		var goal: Vector3 = _entry_records[id].to
		if actor.velocity != Vector3.ZERO or Vector2(actor.global_position.x - goal.x, actor.global_position.z - goal.z).length() > Motion.ENDPOINT_TOLERANCE: return
		_entry_outcomes[id] = {"outcome": "complete", "endpoint": actor.global_position}
	helper_stage = "done"
	request_checkpoint("court-king-phase-two", "boss_phase")
	_refresh_objective()


func court_entry_motion_context(actor: CharacterBody3D) -> Dictionary:
	if not _running or room != 4 or helper_stage != "entering" or is_restore_candidate() or not _helpers_once: return {}
	for id: String in _entry_records:
		if sources.get(id) != actor or _retained.get(id) != actor or actor.get_parent() != self: continue
		if _entry_outcomes.has(id) or not _entry_clear(id): return {}
		return _entry_records[id].duplicate(true)
	return {}


func _entry_clear(id: String) -> bool:
	if not _entry_records.has(id) or not _floor_error().is_empty() or not presentation_error().is_empty(): return false
	var actor: CharacterBody3D = sources[id]
	var record: Dictionary = _entry_records[id]
	var move := Vector3(0, 0, maxf(0.0, record.to.z - actor.global_position.z))
	var sweep: Dictionary = BodySweep.sweep(actor, actor.global_transform, move, response_context().floor_regions)
	if sweep.has("error") or sweep.get("collided", true): return false
	var lane: Dictionary = Geometry.lane(actor.global_position, actor.global_position + move, 0.32)
	if Geometry.segment_hits(lane, hero.global_position, hero.global_position, CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN): return false
	for other: CharacterBody3D in sources.values():
		if other != actor and not other.get("dead") and not other.get("dormant") and Geometry.segment_hits(lane, other.global_position, other.global_position, 0.32 + CinderThreatScheduler.SKIN): return false
	return true


func court_entry_stop_error(actor: CharacterBody3D, original: Dictionary, reason: String) -> String:
	if not _running or not _helpers_once or room != 4 or helper_stage != "entering" or reason not in ["blocked", "king_defeated"]: return "Actual court entry stop entitlement is closed"
	for id: String in _entry_records:
		if sources.get(id) == actor and _retained.get(id) == actor and actor.get_parent() == self and not _entry_outcomes.has(id) and var_to_bytes(original) == var_to_bytes(_entry_records[id]):
			if reason == "king_defeated" and sources["court-king"].get("dead") != true: return "King is still alive"
			if reason == "blocked" and _entry_clear(id) and not _entry_deadline_missed(id): return "Actual entry remains clear and has not missed its original deadline"
			return ""
	return "Retain the exact original entry record and actual once-born helper"


func _entry_deadline_missed(id: String) -> bool:
	if not _entry_records.has(id): return false
	var record: Dictionary = _entry_records[id]
	var endpoint: Vector3 = record.to
	var actor: CharacterBody3D = sources[id]
	return scheduler.get_clock() > float(record.end_s) + 1.0 / float(Engine.physics_ticks_per_second) and Vector2(actor.global_position.x - endpoint.x, actor.global_position.z - endpoint.z).length() > Motion.ENDPOINT_TOLERANCE


func _live_boundary(expected_hero: CinderPlayer = null, expected_shell: Node = null, initial_paused_install: bool = false) -> bool:
	return _running and is_inside_tree() and not is_queued_for_deletion() and (not get_tree().paused or initial_paused_install) and is_instance_valid(hero) and (expected_hero == null or hero == expected_hero) and not hero.dead and hero.is_inside_tree() and not hero.is_queued_for_deletion() and is_instance_valid(shared_shell) and (expected_shell == null or shared_shell == expected_shell) and shared_shell.is_inside_tree() and not shared_shell.is_queued_for_deletion() and is_instance_valid(scheduler) and scheduler.is_inside_tree() and not scheduler.is_queued_for_deletion() and scheduler.get_parent() == self


func _finish_king_defeat() -> void:
	if is_completed(): return
	if helper_stage == "entering":
		for id: String in _entry_records:
			if _entry_outcomes.has(id): continue
			var actor: CharacterBody3D = sources[id]
			if not actor.get("dead") and actor.get("hp") == actor.get("max_hp"):
				var stopped: Dictionary = actor.call("stop_court_entry_motion", self, _entry_records[id], "king_defeated")
				if stopped.get("accepted") != true: _construction_error = String(stopped.get("reason", "Native court terminal entry stop refused")); return
			_entry_outcomes[id] = {"outcome": "king_defeated", "endpoint": actor.global_position}
	for id: String in _current_ids():
		if not sources[id].get("dead"): sources[id].call("cancel", "king_defeated")
	scheduler.end_encounter("king_defeated")
	request_completion(COMPLETE_ID)
	_exit_area.set_deferred("monitoring", true)
	_exit_cue.present("available", "contact")
	_refresh_objective()


func _boss_contact(body: Node3D) -> void:
	if body != hero or not _running or hero.dead or get_tree().paused or _awaiting_room != 3 or not _boss_area.overlaps_body(hero): return
	_boss_cue.present("spent", "contact")
	_boss_area.set_deferred("monitoring", false)
	request_checkpoint("court-boss-entry", "boss_phase")
	_begin_room(3)


func _exit_contact(body: Node3D) -> void:
	if body == hero and _running and not hero.dead and not get_tree().paused and is_completed() and _exit_area.overlaps_body(hero): request_contact_exit(EXIT_ID, hero)


func _encounter_id() -> String:
	if room == 2 and not _roundel_demonstrated: return "court-roundel-demonstration"
	return "court-king" if room >= 3 else "court-" + Layout.ROOM_IDS[room]


func _refresh_objective() -> void:
	if is_completed(): objective_text = "THE COURT IS OPEN\nCONTACT THE EXTERIOR CURTAIN"; return
	if _awaiting_room == 3: objective_text = "THE KING AWAITS\nCONTACT THE THRONE APPROACH"; return
	if _awaiting_room >= 0: objective_text = "COURT CLEARED\nDASH TO THE NEXT OPEN COURT"; return
	match room:
		0: objective_text = "CURTAIN GUARD\nDASH BESIDE THE THRUST · PRIMARY AT RECOVERY"
		1: objective_text = "TWO GUARDS · " + formation.to_upper() + "\nCHOOSE THE GAP AND EARLIER RECOVERY"
		2: objective_text = "ROYAL ROUNDEL\n" + ("OBSERVE ONE KNOWN IMPACT" if not _roundel_demonstrated else "REMOVE A GUARD · KEEP A DRY LANDING")
		3: objective_text = "SELENITE KING\nREAD THE LUNGE · PRIMARY AT RECOVERY"
		4: objective_text = "ONE FINITE GUARD PAIR\n" + ("VISIBLE ENTRY · NO REPLACEMENT WAVE" if helper_stage != "done" else "SIMPLIFY THE GUARDS OR PUNISH THE KING")


func response_context() -> Dictionary:
	var directions: Array[Vector3] = []
	for index: int in 16: directions.append(Vector3(cos(float(index) * TAU / 16), 0, sin(float(index) * TAU / 16)))
	return {"encounter_id": _encounter_id(), "world_revision": WORLD_REVISION, "recognition_s": 0.18, "attack_input_margin_s": 0.08, "escape_directions": directions, "return_directions": directions, "floor_regions": [{"collision": _floor, "safe_rect": Layout.SAFE_RECT}]}


func _world_root() -> Node3D:
	var node: Node = get_parent()
	while is_instance_valid(node):
		if node is Node3D and node.is_ancestor_of(hero) and node.is_ancestor_of(scheduler) and (node as Node3D).get_world_3d() == get_world_3d(): return node as Node3D
		node = node.get_parent()
	return null


func scheduler_bindings() -> Dictionary:
	var owners: Dictionary = sources.duplicate()
	owners[Layout.ROUND_EL_ID] = roundel
	return {"world_root": _world_root(), "owners": owners, "floors": {"court_floor": {"collision": _floor, "safe_rect": Layout.SAFE_RECT}}}


func _refresh_frames() -> void:
	for id: String in _frames.keys():
		var retained_owner: Variant = roundel if id == Layout.ROUND_EL_ID else sources.get(id)
		if not is_instance_valid(retained_owner) or not retained_owner is Node3D or retained_owner.is_queued_for_deletion() or not retained_owner.is_inside_tree():
			_frames.erase(id); continue
		var owner: Node3D = retained_owner
		var found: bool = false
		for record: Dictionary in scheduler.source_control_state(owner).reservations:
			if record.id == _frames[id].reservation_id: found = true
		if not found: _frames.erase(id)


func _framing_ready() -> bool:
	var points: Array = _camera_framing_points()
	if points.is_empty() or points.size() > 224: return false
	var plan: Dictionary = shared_shell.call("camera_framing_plan", points, hero.global_position + Vector3(0, 0.65, 0))
	if plan.get("accepted") != true:
		_forecast.clear(); _forecast_frames.clear()
		return false
	# Retain a feasible actual owner/Player premise until the shared camera has
	# read its full lookahead and the current projection genuinely contains it.
	return String(shared_shell.call("camera_framing_error", points)).is_empty()


func presentation_error() -> String:
	if not _running: return ""
	var error: String = _floor_error()
	if not error.is_empty(): return error
	return String(shared_shell.call("camera_framing_error", _camera_framing_points())) if is_instance_valid(shared_shell) else "Actual shared court shell is unavailable"


func _roundel_presentation(_id: String, _state: Dictionary) -> bool:
	return presentation_error().is_empty()


func _camera_framing_points() -> Array:
	if not _running or not is_instance_valid(hero) or not is_instance_valid(shared_shell): return []
	var points: Array = []
	if is_completed(): return _contact_points(_exit_area, _exit_cue)
	if _awaiting_room == 3: points.append_array(_contact_points(_boss_area, _boss_cue))
	for id: String in _current_ids():
		var retained: Variant = sources.get(id)
		if not is_instance_valid(retained) or not retained is CharacterBody3D or retained != _retained.get(id) or retained.is_queued_for_deletion() or retained.get_parent() != self or not retained.is_inside_tree(): return [Vector3.INF]
		var actor: CharacterBody3D = retained
		var state: Dictionary = actor.call("pure_presentation_state")
		if state.dead or state.dormant: continue
		points.append_array(_actor_points(id, state.opening_position))
		if not String(state.reservation_id).is_empty(): points.append_array(_geometry_points(state.geometry)); points.append_array(_cue_points(actor.call("get_cue")))
	if helper_stage == "entering":
		for id: String in _entry_records:
			if not _entry_outcomes.has(id): points.append_array(_actor_points(id, _entry_records[id].to))
	if room == 2:
		var state: Dictionary = roundel.state()
		if state.status == "running": points.append_array(_geometry_points(state.geometry)); points.append_array(_cue_points(roundel.get_cue()))
	for frame: Dictionary in _frames.values(): points.append_array(_response_points(frame.landing, frame.attack_position))
	if not _forecast.is_empty() and _forecast_frames.get("hero") == hero.global_transform:
		var id: String = _forecast_frames.id
		var owner: Node3D = roundel if id == Layout.ROUND_EL_ID else sources.get(id) as Node3D
		if is_instance_valid(owner) and owner.global_transform == _forecast_frames.source: points.append_array(_forecast)
	var dash: Dictionary = hero.get_committed_dash_state()
	if dash.get("active", false):
		for point: Vector3 in shared_shell.call("player_camera_framing_points"): points.append(point + dash.origin + dash.direction * float(dash.distance) - hero.global_position)
	return _unique_points(points)


func _actor_points(id: String, endpoint: Vector3) -> Array:
	var actor: CharacterBody3D = sources[id]
	if not String(actor.call("art_binding_error")).is_empty(): return [Vector3.INF]
	var collision := actor.get_node_or_null("BodyCollision") as CollisionShape3D
	if not is_instance_valid(collision) or not collision.shape is CapsuleShape3D: return [Vector3.INF]
	var capsule := collision.shape as CapsuleShape3D
	var points: Array = _box_points(AABB(Vector3(-capsule.radius, -capsule.height * 0.5, -capsule.radius), Vector3(2 * capsule.radius, capsule.height, 2 * capsule.radius)), collision.global_transform)
	if id == "court-king": points.append_array(actor.call("camera_art_points", shared_shell.get("camera") as Camera3D))
	else:
		var art: Node3D = actor.call("get_art")
		for node: Node in art.find_children("*", "Sprite3D", true, false):
			if node.is_visible_in_tree(): points.append_array(shared_shell.call("camera_billboard_points", node))
		for node: Node in art.find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			if mesh.mesh != null and mesh.is_visible_in_tree(): points.append_array(_box_points(mesh.get_aabb(), mesh.global_transform))
	for point: Vector3 in points.duplicate(): points.append(point + endpoint - actor.global_position)
	return _unique_points(points)


func _contact_points(area: Area3D, cue: CinderInteractionCue) -> Array:
	if not is_instance_valid(area) or not area.is_inside_tree() or area.is_queued_for_deletion() or area.get_parent() != self or not is_instance_valid(cue) or not cue.is_inside_tree() or cue.is_queued_for_deletion() or cue.get_parent() != self: return [Vector3.INF]
	var collision := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if not is_instance_valid(collision) or not collision.shape is BoxShape3D or collision.disabled: return [Vector3.INF]
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
	var points: Array = []
	if shape.get("kind") == "lane":
		for centre: Vector3 in [shape["from"], shape["to"]]: points.append_array(_box_points(AABB(Vector3(-shape.radius, 0, -shape.radius), Vector3(shape.radius * 2, 0.08, shape.radius * 2)), Transform3D(Basis.IDENTITY, centre)))
	elif shape.get("kind") == "circle": points.append_array(_box_points(AABB(Vector3(-shape.radius, 0, -shape.radius), Vector3(shape.radius * 2, 0.08, shape.radius * 2)), Transform3D(Basis.IDENTITY, shape.origin)))
	else: return [Vector3.INF]
	return points


func _response_points(landing: Vector3, attack: Vector3) -> Array:
	var points: Array = []
	for point: Vector3 in shared_shell.call("player_camera_framing_points"): points.append(point + landing - hero.global_position); points.append(point + attack - hero.global_position)
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
	return "Retain the actual court BOX floor" if not is_instance_valid(_floor) or _floor != get_node_or_null("Floor/CollisionShape3D") or _floor.shape != _floor_shape or not is_instance_valid(_floor_shape) or _floor_shape.size != Vector3(14, 1, 44) or _floor.global_transform != _floor_frame or _floor.disabled else ""


func contract_error() -> String:
	return _construction_error if not _construction_error.is_empty() else super.contract_error()


func _capture_local_state() -> Dictionary:
	# Honest refusal until the complete cast/phase/roundel/entry aggregate exists.
	return {}


func _local_snapshot_error(_state: Dictionary) -> String:
	return "Whole court aggregate/fresh candidate persistence is unfinished"


func _on_enter_restore_candidate(_local: Dictionary, _saved_player: Dictionary) -> String:
	return "Whole court candidate construction/codec is unfinished"


func _on_exit_level() -> void:
	_running = false
	for actor: CharacterBody3D in sources.values():
		if is_instance_valid(actor):
			if actor.is_inside_tree(): actor.call("cancel", "court_exit")
			actor.set_physics_process(false)
			actor.remove_from_group("enemies")
	if is_instance_valid(roundel):
		if roundel.is_inside_tree(): roundel.cancel("court_exit")
		roundel.set_physics_process(false)
	if is_instance_valid(scheduler):
		if scheduler.is_inside_tree(): scheduler.end_encounter("court_exit")
		scheduler.set_physics_process(false)
	if is_instance_valid(_boss_area): _boss_area.set_deferred("monitoring", false)
	if is_instance_valid(_exit_area): _exit_area.set_deferred("monitoring", false)
	if is_instance_valid(_boss_cue): _boss_cue.clear()
	if is_instance_valid(_exit_cue): _exit_cue.clear()
	_frames.clear(); _forecast.clear(); _phase_entitlements.clear()
	set_physics_process(false)
