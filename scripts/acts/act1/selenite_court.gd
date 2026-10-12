extends CinderLevel
## Whole L4 authored gameplay. Unregistered; whole persistence checks remain due.
## One real Hero and shared Scheduler. No private input/camera/HUD/save system.

const Layout = preload("res://scripts/acts/act1/selenite_court_layout.gd")
const Guard = preload("res://scripts/acts/act1/mushroom_selenite.gd")
const King = preload("res://scripts/acts/act1/selenite_king.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const BodySweep = preload("res://scripts/combat/body_sweep.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const CourtCodec = preload("res://scripts/acts/act1/selenite_court_codec.gd")
const WholeArt = preload("res://scripts/acts/act1/selenite_court_whole_art.gd")
const Cue = preload("res://scripts/cues/interaction_cue.gd")
const WORLD_REVISION: int = 2
const COMPLETE_ID: String = "court-clear"
const EXIT_ID: String = "court-exterior"
const CONTACT_APPROACH_DISTANCE: float = 4.5

var scheduler: CinderThreatScheduler
var sources: Dictionary = {}
var roundel: CinderLaneMechanism
var room: int = 0
var formation: String = "parallel"
var helper_stage: String = "unborn"
var king_intro: Dictionary = {"stage": "unborn", "record": {}, "outcome": {}}
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
var _pending_boss_contact: bool = false
var entry_stop_diagnostics: Dictionary = {}
var _trusted_configurations: Dictionary = {}
var _configuration_hashes: Dictionary = {}
var _authored_positions: Dictionary = {}
var _constructor_open: bool = false
var _constructor_entitlements: Dictionary = {}
var _quiet_commit_error: String = ""
var _quiet_commit: bool = false
var _capture_error: String = ""
var _contact_pins: Dictionary = {}
var _whole_art: Node3D
var _art_stage_key: String = ""
var _exterior_open: bool = false


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
	for area: Area3D in [_boss_area, _exit_area]:
		var collision := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if collision == null or not collision.shape is BoxShape3D:
			_construction_error = "Actual upright native contact boxes required"; return
		_contact_pins[area.name] = {"area": area, "frame": area.global_transform, "collision": collision, "shape": collision.shape, "collision_frame": collision.transform, "size": (collision.shape as BoxShape3D).size, "layer": area.collision_layer, "mask": area.collision_mask}
	# Replace only the earlier scenic placeholders. Their authored anchors and
	# every actual floor/contact/collision resource remain the original scene.
	for path: String in ["CompactSideThrone", "HelperDoorWest", "HelperDoorEast"]:
		for node: Node in get_node(path).find_children("*", "MeshInstance3D", true, false): (node as MeshInstance3D).visible = false
	_whole_art = WholeArt.build_whole_art(self)
	if not is_instance_valid(_whole_art): _construction_error = "Authored whole court art could not bind its actual original floor/skin"; return


func _on_enter_level() -> void:
	if not _construction_error.is_empty(): return
	for actor: CharacterBody3D in sources.values():
		if actor.call("bind", scheduler, hero) != true: _construction_error = String(actor.get("last_error")); return
	if not roundel.bind(scheduler, {"hero": hero}) or not roundel.set_presentation_guard(Callable(self, "_roundel_presentation")):
		_construction_error = roundel.last_error; return
	_construction_error = _pin_native_bindings()
	if not _construction_error.is_empty(): return
	_running = true
	_begin_room(0)


func _begin_room(next: int) -> void:
	if not _running or next < 0 or next > 3 or not _live_boundary(null, null, next == 0 and scheduler.encounter_profile().is_empty()): return
	room = next
	_awaiting_room = -1
	if room == 3: king_intro = {"stage": "settling", "record": {}, "outcome": {}}
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
	if is_completed():
		_update_exterior_contact()
		_refresh_objective()
		return
	if _awaiting_room >= 0:
		if _awaiting_room == 3:
			# The cleared approach checkpoint precedes the local throne approach.
			# Expose its full contact box/glyph only in that reachable local view;
			# no distant available cue is omitted from an accepted optical unit.
			var near: bool = _boss_contact_near()
			_boss_area.set_deferred("monitoring", near)
			if near: _boss_cue.present("available", "contact")
			else: _boss_cue.clear()
			if near and not _pending_boss_contact and _boss_area.monitoring and _boss_area.overlaps_body(hero): _boss_contact(hero)
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
	if room >= 3 and sources["court-king"].get("dead"):
		_finish_king_defeat()
		return
	if room == 3 and king_intro.stage in ["settling", "entering"]:
		_update_king_intro()
		return
	if room == 3 and float(sources["court-king"].get("hp")) <= 40.0:
		_enter_helper_phase()
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


func _update_king_intro() -> void:
	var king: CharacterBody3D = sources["court-king"]
	if king.get("dead") or king.get("hp") < king.get("max_hp"):
		king_intro.outcome = {"outcome": "defeated" if king.get("dead") else "injured", "endpoint": king.global_position}
		king_intro.stage = "done"
		_refresh_objective()
		return
	if king_intro.stage == "settling":
		if not king.is_on_floor() or king.velocity != Vector3.ZERO or not _framing_ready(): return
		var start: float = scheduler.get_clock()
		var from: Vector3 = king.global_position
		king_intro.record = {"active": true, "from": from, "to": from + Vector3.BACK * Layout.KING_INTRO_DISTANCE, "start_s": start, "end_s": start + Layout.KING_INTRO_DURATION, "speed": Layout.KING_INTRO_SPEED}
		king_intro.stage = "entering"
		_refresh_objective()
		return
	if not _king_intro_clear() or _king_intro_deadline_missed():
		var stopped: Dictionary = king.call("stop_court_intro_motion", self, king_intro.record, "blocked")
		if stopped.get("accepted") != true: _construction_error = String(stopped.get("reason", "Native King intro stop refused")); return
		king_intro.outcome = {"outcome": "blocked", "endpoint": king.global_position}
		king_intro.stage = "done"
		_refresh_objective()
		return
	var goal: Vector3 = king_intro.record.to
	if king.velocity != Vector3.ZERO or Vector2(king.global_position.x - goal.x, king.global_position.z - goal.z).length() > Motion.ENDPOINT_TOLERANCE: return
	king_intro.outcome = {"outcome": "complete", "endpoint": king.global_position}
	king_intro.stage = "done"
	_refresh_objective()


func court_intro_motion_context(actor: CharacterBody3D) -> Dictionary:
	if not _running or room != 3 or king_intro.stage != "entering" or is_restore_candidate() or sources.get("court-king") != actor or _retained.get("court-king") != actor or actor.get_parent() != self or not _king_intro_clear(): return {}
	return king_intro.record.duplicate(true)


func _king_intro_clear() -> bool:
	if king_intro.record.is_empty() or not _floor_error().is_empty() or not presentation_error().is_empty(): return false
	var actor: CharacterBody3D = sources["court-king"]
	var move := Vector3(0, 0, maxf(0.0, king_intro.record.to.z - actor.global_position.z))
	var sweep: Dictionary = BodySweep.sweep(actor, actor.global_transform, move, response_context().floor_regions)
	if sweep.has("error") or sweep.get("collided", true): return false
	var lane: Dictionary = Geometry.lane(actor.global_position, actor.global_position + move, 0.32)
	if Geometry.segment_hits(lane, hero.global_position, hero.global_position, CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN): return false
	for other: CharacterBody3D in sources.values():
		if other != actor and not other.get("dead") and not other.get("dormant") and Geometry.segment_hits(lane, other.global_position, other.global_position, 0.32 + CinderThreatScheduler.SKIN): return false
	return true


func _king_intro_deadline_missed() -> bool:
	if king_intro.record.is_empty(): return false
	var goal: Vector3 = king_intro.record.to
	var actor: CharacterBody3D = sources["court-king"]
	return scheduler.get_clock() > float(king_intro.record.end_s) + 1.0 / float(Engine.physics_ticks_per_second) and Vector2(actor.global_position.x - goal.x, actor.global_position.z - goal.z).length() > Motion.ENDPOINT_TOLERANCE


func court_intro_stop_error(actor: CharacterBody3D, original: Dictionary, reason: String) -> String:
	if not _running or room != 3 or king_intro.stage != "entering" or is_restore_candidate() or sources.get("court-king") != actor or _retained.get("court-king") != actor or actor.get_parent() != self or reason != "blocked" or var_to_bytes(original) != var_to_bytes(king_intro.record): return "Actual original King intro stop entitlement is closed"
	return "Actual intro remains clear within its original deadline" if _king_intro_clear() and not _king_intro_deadline_missed() else ""


func court_king_presentation(actor: CharacterBody3D) -> String:
	if not _running or sources.get("court-king") != actor or _retained.get("court-king") != actor or actor.get_parent() != self: return "idle"
	if room == 3 and king_intro.stage == "entering": return "step"
	if room == 4 and helper_stage in ["settling", "entering"]: return "summon"
	return "idle"


func _refresh_king_presentation() -> bool:
	var actor: CharacterBody3D = sources.get("court-king")
	if not is_instance_valid(actor) or not actor.has_method("refresh_court_presentation"): return false
	return actor.call("refresh_court_presentation") == true


func _enter_helper_phase() -> void:
	# Publish the retained dormant pair's full body/art and finite route before
	# birth. The actual shared camera must contain it, alongside the continuing
	# King and every live response proof, before these helpers become visible.
	if not _framing_ready(): return
	var king: CharacterBody3D = sources["court-king"]
	king.call("cancel", "court_phase_two_entry")
	_frames.clear()
	room = 4
	_helpers_once = true
	helper_stage = "settling"
	if not _refresh_king_presentation(): _construction_error = "Actual King summon presentation could not refresh"; return
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
		# Settlement may finish before the render-owned camera reads the complete
		# entry lookahead. Establish actual containment before starting its clock;
		# an already started interval is never postponed or rebased.
		if not _framing_ready(): return
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
			entry_stop_diagnostics[id] = {"native_error": String(actor.get("last_error")), "view_error": presentation_error(), "clock_s": scheduler.get_clock(), "position": actor.global_position, "velocity": actor.velocity, "original": _entry_records[id].duplicate(true), "deadline_missed": _entry_deadline_missed(id)}
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
	if king_intro.stage in ["settling", "entering"]:
		king_intro.outcome = {"outcome": "defeated", "endpoint": sources["court-king"].global_position}
		king_intro.stage = "done"
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
	_update_exterior_contact()
	_refresh_objective()


func _boss_contact(body: Node3D) -> void:
	if _pending_boss_contact or body != hero or not _live_boundary() or _awaiting_room != 3 or not _boss_contact_near() or not _boss_area.monitoring or not _boss_area.overlaps_body(hero): return
	_pending_boss_contact = true
	_commit_boss_contact.call_deferred(body)


func _commit_boss_contact(body: Node3D) -> void:
	_pending_boss_contact = false
	if not _live_boundary() or body != hero or _awaiting_room != 3 or not _boss_contact_near() or not _boss_area.monitoring or not _boss_area.overlaps_body(hero) or not presentation_error().is_empty(): return
	# Native source lifecycle changes run after Area query delivery has ended.
	_boss_cue.present("spent", "contact")
	_boss_area.set_deferred("monitoring", false)
	_begin_room(3)
	if _construction_error.is_empty(): request_checkpoint("court-boss-entry", "boss_phase")


func _exit_contact(body: Node3D) -> void:
	if body != hero or not _live_boundary() or not is_completed() or not _exit_area.monitoring or not _exit_contact_near() or not _exit_area.overlaps_body(hero): return
	if not _native_runtime_error().is_empty() or not _framing_ready(): return
	var cue_state: Dictionary = _exit_cue.state()
	if cue_state.state != "available" or cue_state.trigger != "contact" or not cue_state.visible: return
	var admitted_hero: CinderPlayer = hero
	var admitted_shell: Node = shared_shell
	if not request_contact_exit(EXIT_ID, admitted_hero): return
	# A synchronous contact observer may legally exit or dispose the court.
	# The ordinary Shell pauses while deferring its transition; retain that
	# pause, but never re-show a cue after observer-owned exit/disposal.
	if not _live_boundary(admitted_hero, admitted_shell, true) or not is_instance_valid(_exit_area) or _exit_area.is_queued_for_deletion() or _exit_area.get_parent() != self or not is_instance_valid(_exit_cue) or _exit_cue.is_queued_for_deletion() or _exit_cue.get_parent() != self: return
	_exterior_open = true
	_exit_area.set_deferred("monitoring", false)
	if _exit_contact_near() and _framing_ready(): _exit_cue.present("spent", "contact")
	else: _exit_cue.clear()
	_sync_art_presentation()


func _exit_contact_near() -> bool:
	return is_instance_valid(hero) and Vector2(hero.global_position.x - Layout.EXIT_POSITION.x, hero.global_position.z - Layout.EXIT_POSITION.z).length() <= CONTACT_APPROACH_DISTANCE


func _update_exterior_contact() -> void:
	# Completion can pause/save immediately at the King's ordinary attack range.
	# Expose this distant contact only after local approach and actual full-view
	# containment, without changing the shared camera or moving the native Area.
	var near: bool = _exit_contact_near()
	var available: bool = near and _contact_exit_id.is_empty() and _framing_ready()
	_exit_area.set_deferred("monitoring", available)
	if available: _exit_cue.present("available", "contact")
	elif near and not _contact_exit_id.is_empty(): _exit_cue.present("spent", "contact")
	else: _exit_cue.clear()
	if available and _exit_area.monitoring and _exit_area.overlaps_body(hero): _exit_contact(hero)


func _encounter_id() -> String:
	if room == 2 and not _roundel_demonstrated: return "court-roundel-demonstration"
	return "court-king" if room >= 3 else "court-" + Layout.ROOM_IDS[room]


func _boss_contact_near() -> bool:
	return _awaiting_room == 3 and is_instance_valid(hero) and Vector2(hero.global_position.x - Layout.BOSS_CONTACT_POSITION.x, hero.global_position.z - Layout.BOSS_CONTACT_POSITION.z).length() <= CONTACT_APPROACH_DISTANCE


func _refresh_objective() -> void:
	_sync_art_presentation()
	# Native fatal damage draws the final defeat pose before emitting its guarded
	# callback. Completion needs no parent-derived step/summon refresh, which
	# must still refuse reentry into that native damage transaction.
	if _running and not is_completed() and not _refresh_king_presentation(): _construction_error = "Actual King presentation could not refresh"; return
	if is_completed(): objective_text = "THE COURT IS OPEN\n" + ("CONTACT THE EXTERIOR CURTAIN" if _exit_contact_near() else "DASH TO THE EXTERIOR CURTAIN"); return
	if _awaiting_room == 3: objective_text = "THE KING AWAITS\n" + ("CONTACT THE THRONE APPROACH" if _boss_contact_near() else "DASH TO THE THRONE APPROACH"); return
	if _awaiting_room >= 0: objective_text = "COURT CLEARED\nDASH TO THE NEXT OPEN COURT"; return
	match room:
		0: objective_text = "CURTAIN GUARD\nDASH BESIDE THE THRUST · PRIMARY AT RECOVERY"
		1: objective_text = "TWO GUARDS · " + formation.to_upper() + "\nCHOOSE THE GAP AND EARLIER RECOVERY"
		2: objective_text = "ROYAL ROUNDEL\n" + ("OBSERVE ONE KNOWN IMPACT" if not _roundel_demonstrated else "REMOVE A GUARD · KEEP A DRY LANDING")
		3: objective_text = "SELENITE KING\n" + ("THE KING STEPS FROM HIS THRONE" if king_intro.stage in ["settling", "entering"] else "READ THE LUNGE · PRIMARY AT RECOVERY")
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
	if is_completed():
		points.append_array(_hero_points())
		# Include any still-visible native marker as well as local lookahead,
		# including a held pause at the instant the Hero crosses the range edge.
		if _exit_contact_near() or _exit_cue.state().visible: points.append_array(_contact_points(_exit_area, _exit_cue))
		return _unique_points(points)
	if _boss_contact_near():
		points.append_array(_contact_points(_boss_area, _boss_cue))
		# Retain the actual dormant King's full native body/art before exposing
		# it. Contact cannot birth a newly clipped source or checkpoint while
		# the shared fixed camera is still approaching this local court.
		points.append_array(_actor_points("court-king", sources["court-king"].global_position + Vector3.BACK * Layout.KING_INTRO_DISTANCE))
	if room == 3 and not _helpers_once and not sources["court-king"].get("dead") and float(sources["court-king"].get("hp")) <= 40.0:
		for id: String in Layout.ROOM_SOURCE_IDS[4]:
			var endpoint: Vector3 = sources[id].global_position + Vector3(0, 0, Layout.HELPER_ENTRY_DISTANCE)
			points.append_array(_actor_points(id, endpoint, true))
	for id: String in _current_ids():
		var retained: Variant = sources.get(id)
		if not is_instance_valid(retained) or not retained is CharacterBody3D or retained != _retained.get(id) or retained.is_queued_for_deletion() or retained.get_parent() != self or not retained.is_inside_tree(): return [Vector3.INF]
		var actor: CharacterBody3D = retained
		var state: Dictionary = actor.call("pure_presentation_state")
		if state.dead or state.dormant: continue
		points.append_array(_actor_points(id, state.opening_position))
		if not String(state.reservation_id).is_empty(): points.append_array(_geometry_points(state.geometry)); points.append_array(_cue_points(actor.call("get_cue")))
	if helper_stage in ["settling", "entering"]:
		for id: String in Layout.ROOM_SOURCE_IDS[4]:
			if _entry_outcomes.has(id): continue
			var endpoint: Vector3 = _entry_records[id].to if helper_stage == "entering" else sources[id].global_position + Vector3(0, 0, Layout.HELPER_ENTRY_DISTANCE)
			points.append_array(_actor_points(id, endpoint))
	if room == 3 and king_intro.stage in ["settling", "entering"]:
		var endpoint: Vector3 = king_intro.record.to if king_intro.stage == "entering" else sources["court-king"].global_position + Vector3.BACK * Layout.KING_INTRO_DISTANCE
		points.append_array(_actor_points("court-king", endpoint))
	if room == 2:
		var state: Dictionary = roundel.state()
		if state.status == "running": points.append_array(_geometry_points(state.geometry)); points.append_array(_cue_points(roundel.get_cue()))
	for id: String in _frames:
		var owner: Node3D = roundel if id == Layout.ROUND_EL_ID else sources.get(id) as Node3D
		if not is_instance_valid(owner): return [Vector3.INF]
		for record: Dictionary in scheduler.source_control_state(owner).get("reservations", []):
			if record.id == _frames[id].reservation_id: points.append_array(_response_points(_frames[id].landing, _frames[id].attack_position))
	if not _forecast.is_empty() and _forecast_frames.get("hero") == hero.global_transform:
		var id: String = _forecast_frames.id
		var owner: Node3D = roundel if id == Layout.ROUND_EL_ID else sources.get(id) as Node3D
		if is_instance_valid(owner) and owner.global_transform == _forecast_frames.source: points.append_array(_forecast)
	var dash: Dictionary = hero.get_committed_dash_state()
	if dash.get("active", false):
		for point: Vector3 in _hero_points(): points.append(point + dash.origin + dash.direction * float(dash.distance) - hero.global_position)
	# A genuinely cleared court has no living threat. Keep the actual Hero
	# bounds at this deferred checkpoint instead of inventing a future source.
	return _unique_points(points if not points.is_empty() else _hero_points())


func _actor_points(id: String, endpoint: Vector3, prospective_helper: bool = false) -> Array:
	var actor: CharacterBody3D = sources[id]
	if prospective_helper and (id not in Layout.ROOM_SOURCE_IDS[4] or not actor.get("dormant") or actor.get("dead")): return [Vector3.INF]
	var camera: Camera3D = _actual_camera()
	var shared_camera: Camera3D = shared_shell.get("camera") as Camera3D if is_instance_valid(shared_shell) else null
	# The shared billboard helper uses its fixed camera basis. A fresh candidate
	# must first retain that exact basis; its world/focus belongs to this viewport.
	if not is_instance_valid(camera) or not is_instance_valid(shared_camera) or camera.global_basis != shared_camera.global_basis: return [Vector3.INF]
	if not String(actor.call("art_binding_error")).is_empty(): return [Vector3.INF]
	var collision := actor.get_node_or_null("BodyCollision") as CollisionShape3D
	if not is_instance_valid(collision) or not collision.shape is CapsuleShape3D: return [Vector3.INF]
	var capsule := collision.shape as CapsuleShape3D
	var points: Array = _box_points(AABB(Vector3(-capsule.radius, -capsule.height * 0.5, -capsule.radius), Vector3(2 * capsule.radius, capsule.height, 2 * capsule.radius)), collision.global_transform)
	if id == "court-king": points.append_array(actor.call("camera_art_points", _actual_camera()))
	else:
		var art: Node3D = actor.call("get_art")
		for node: Node in art.find_children("*", "Sprite3D", true, false):
			if node.is_visible_in_tree() or (prospective_helper and node.visible): points.append_array(shared_shell.call("camera_billboard_points", node))
		for node: Node in art.find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			if mesh.mesh != null and (mesh.is_visible_in_tree() or (prospective_helper and mesh.visible)): points.append_array(_box_points(mesh.get_aabb(), mesh.global_transform))
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
	for point: Vector3 in _hero_points(): points.append(point + landing - hero.global_position); points.append(point + attack - hero.global_position)
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


func restore_candidate_construction_required() -> bool:
	return true


func _pin_native_bindings() -> String:
	if global_transform != Transform3D.IDENTITY or not is_instance_valid(hero) or hero.get_world_3d() != get_world_3d(): return "Actual fixed authored court and same-world Hero required"
	for id: String in Layout.SOURCES:
		var actor: CharacterBody3D = sources[id]
		var native: Dictionary = actor.call("get_court_native_bindings" if id == "court-king" else "get_spore_native_bindings")
		if native.is_empty() or native.get("source_id") != id or native.get("player") != hero or native.get("scheduler") != scheduler or actor.global_position != Layout.SOURCES[id].position: return "Retain actual immutable authored source/Player/Scheduler: " + id
		_trusted_configurations[id] = native.configuration.duplicate(true)
		_configuration_hashes[id] = Exact.stringify(native.configuration).sha256_text()
		_authored_positions[id] = Codec.vector3(actor.global_position)
	return ""


func _native_runtime_error() -> String:
	if not _construction_error.is_empty(): return _construction_error
	if not _quiet_commit_error.is_empty(): return _quiet_commit_error
	if not _running or not is_instance_valid(hero) or not is_instance_valid(shared_shell) or not is_instance_valid(scheduler) or scheduler.get_parent() != self or not is_instance_valid(roundel) or roundel.get_parent() != self: return "Actual entered court native bindings required"
	var error: String = _floor_error()
	if not error.is_empty(): return error
	if not is_instance_valid(_whole_art) or _whole_art.get_parent() != self or get_node_or_null("WholeCourtArt") != _whole_art: return "Retain actual authored whole court art"
	error = String(_whole_art.call("binding_error"))
	if not error.is_empty(): return error
	if not _same(_whole_art.call("presentation_state"), _expected_art_state()): return "Actual scenic presentation differs from the court's native stage/helper/completion state"
	if not Codec.keys_error(sources, Layout.SOURCES.keys()).is_empty() or not Codec.keys_error(_trusted_configurations, Layout.SOURCES.keys()).is_empty(): return "Retain the exact eight native identities/configurations"
	for id: String in Layout.SOURCES:
		var raw: Variant = sources.get(id)
		if not is_instance_valid(raw) or not raw is CharacterBody3D or raw != _retained.get(id) or raw.get_parent() != self or not raw.is_inside_tree() or raw.is_queued_for_deletion(): return "Retained actual source unavailable: " + id
		var native: Dictionary = raw.call("get_court_native_bindings" if id == "court-king" else "get_spore_native_bindings")
		if native.is_empty() or native.get("player") != hero or native.get("scheduler") != scheduler or not _same(native.configuration, _trusted_configurations[id]): return "Actual native source aliases/configuration changed: " + id
	for key: String in _contact_pins:
		var pin: Dictionary = _contact_pins[key]
		var area: Area3D = pin.area
		var collision: CollisionShape3D = pin.collision
		if not is_instance_valid(area) or not is_instance_valid(collision) or area.get_parent() != self or area.is_queued_for_deletion() or area.global_transform != pin.frame or area.get_node_or_null("CollisionShape3D") != collision or collision.shape != pin.shape or collision.transform != pin.collision_frame or (collision.shape as BoxShape3D).size != pin.size or collision.disabled or area.collision_layer != pin.layer or area.collision_mask != pin.mask: return "Retain actual contact Area/frame/shape/masks"
	return ""


func _on_enter_restore_candidate(local: Dictionary, _saved_player: Dictionary) -> String:
	if not is_restore_candidate() or not _construction_error.is_empty(): return "Fresh paused actual court required"
	for actor: CharacterBody3D in sources.values():
		if actor.call("bind", scheduler, hero) != true: return String(actor.get("last_error"))
	if not roundel.bind(scheduler, {"hero": hero}) or not roundel.set_presentation_guard(Callable(self, "_roundel_presentation")): return roundel.last_error
	var error: String = _pin_native_bindings()
	if not error.is_empty(): return error
	var plan: Dictionary = CourtCodec.construction_plan(local, _configuration_hashes, _authored_positions)
	if plan.get("accepted") != true: return String(plan.get("error", "Court construction plan refused"))
	_constructor_entitlements = plan.descriptors.duplicate(true)
	_constructor_open = true
	for id: String in plan.activated_source_ids:
		var actor: CharacterBody3D = sources[id]
		var accepted: Variant = actor.call("construct_restore_recipient", self, _constructor_entitlements[id].duplicate(true))
		_constructor_entitlements.erase(id)
		if accepted != true:
			_constructor_open = false; _constructor_entitlements.clear()
			return String(actor.get("last_error")) if is_instance_valid(actor) else "Native recipient disappeared"
	_constructor_open = false; _constructor_entitlements.clear()
	_running = true
	return _native_runtime_error()


func restore_recipient_construction_error(actor: CharacterBody3D, descriptor: Dictionary) -> String:
	if not _constructor_open or not is_restore_candidate() or _quiet_commit or not _quiet_commit_error.is_empty(): return "Court native construction entitlement is closed"
	var id: Variant = descriptor.get("source_id")
	if not id is String or not _constructor_entitlements.has(id) or not is_instance_valid(actor) or sources.get(id) != actor or _retained.get(id) != actor or actor.get_parent() != self or actor.get_world_3d() != get_world_3d(): return "Only the actual retained entitled native recipient may be constructed"
	return "" if _same(descriptor, _constructor_entitlements[id]) else "Descriptor differs from the closed copied court-prefix plan"


func snapshot_state() -> Dictionary:
	return _snapshot_in_context(_actual_camera(), shared_shell.get("hud") as GameHUD if is_instance_valid(shared_shell) else null)


func snapshot_state_for_presentation(camera: Camera3D, hud: GameHUD) -> Dictionary:
	return _snapshot_in_context(camera, hud)


func _snapshot_in_context(camera: Camera3D, hud: GameHUD) -> Dictionary:
	if is_restore_candidate(): last_snapshot_error = "Nonplayable candidate cannot supply live capture"; return {}
	last_snapshot_error = _current_presentation_error(camera, hud)
	if not last_snapshot_error.is_empty(): return {}
	_capture_error = ""
	var saved: Dictionary = super.snapshot_state()
	if saved.is_empty():
		if not _capture_error.is_empty(): last_snapshot_error = _capture_error
		return {}
	last_snapshot_error = snapshot_error(saved)
	return saved if last_snapshot_error.is_empty() else {}


func _capture_local_state() -> Dictionary:
	_capture_error = _native_runtime_error()
	if _capture_error.is_empty() and (_pending_boss_contact or _constructor_open or _quiet_commit): _capture_error = "Capture requires the settled deferred boundary outside construction/commit"
	if not _capture_error.is_empty(): return {}
	var paired: Dictionary = scheduler.snapshot_state(scheduler_bindings())
	if paired.is_empty(): _capture_error = scheduler.last_snapshot_error; return {}
	var actors: Dictionary = {}
	for id: String in Layout.SOURCES:
		actors[id] = sources[id].call("snapshot_state", paired)
		if actors[id].is_empty(): _capture_error = String(sources[id].get("last_snapshot_error")); return {}
	var lane: Dictionary = roundel.snapshot_state(scheduler_bindings())
	if lane.is_empty(): _capture_error = roundel.last_snapshot_error; return {}
	var frames: Dictionary = {}
	for record: Dictionary in paired.reservations:
		if not _frames.has(record.source_id) or _frames[record.source_id].reservation_id != record.id: _capture_error = "Actual live lease lost its original response witness"; return {}
		frames[record.source_id] = _frames[record.source_id].duplicate(true)
	return {"api_revision": CourtCodec.API_REVISION, "schema_version": CourtCodec.SCHEMA_VERSION, "world_revision": WORLD_REVISION, "room": room, "formation": formation, "awaiting_room": _awaiting_room, "roundel_demonstrated": _roundel_demonstrated, "helpers_once": _helpers_once, "helper_stage": helper_stage, "king_intro": _encode_native(king_intro), "entry_records": _encode_native(_entry_records), "entry_outcomes": _encode_native(_entry_outcomes), "actors": actors, "scheduler": paired, "roundel": lane, "framing": _encode_native(frames)}


func _local_snapshot_error(state: Dictionary) -> String:
	return _local_snapshot_error_with_player(state, hero.snapshot_state())


func _local_snapshot_error_with_player(state: Dictionary, saved_player: Dictionary) -> String:
	var error: String = _native_runtime_error()
	if error.is_empty(): error = CourtCodec.metadata_error(state)
	if not error.is_empty(): return error
	for id: String in Layout.SOURCES:
		if not _same(state.actors[id].configuration, _trusted_configurations[id]): return "Saved actor differs from immutable actual native configuration: " + id
		error = String(sources[id].call("actor_snapshot_error", state.actors[id], state.scheduler, saved_player))
		if not error.is_empty(): return id + ": " + error
	var bindings: Dictionary = _staged_bindings(state, saved_player)
	if bindings.is_empty(): return "Complete native staging maps unavailable"
	error = scheduler.snapshot_error(state.scheduler, bindings)
	if error.is_empty(): error = roundel.snapshot_error(state.roundel, bindings, state.scheduler)
	if error.is_empty(): error = _saved_entry_support_error(state)
	if error.is_empty(): error = _saved_response_error(state, saved_player)
	return error


func _saved_entry_support_error(state: Dictionary) -> String:
	if state.king_intro.stage == "entering":
		var king: Dictionary = state.actors["court-king"]
		if not king.dead and king.hp == king.configuration.raw_role.max_hp:
			var position: Vector3 = Codec.read_vector3(king.motion.position)
			var support: Dictionary = BodySweep.sweep(sources["court-king"], Transform3D(Basis.IDENTITY, position), Vector3.ZERO, scheduler_bindings().floors.values())
			if support.has("error") or support.get("collided", true): return "Unfinished King intro lacks actual native floor/body support"
	for id: String in state.entry_records:
		if state.entry_outcomes.has(id): continue
		var saved: Dictionary = state.actors[id]
		# Hurt/death before the parent callback is genuine native state. The next
		# parent tick records its retirement; it must not resume pristine entry.
		if saved.dead or saved.hp < saved.configuration.raw_role.max_hp: continue
		var position: Vector3 = Codec.read_vector3(saved.motion.position)
		var support: Dictionary = BodySweep.sweep(sources[id], Transform3D(Basis.IDENTITY, position), Vector3.ZERO, scheduler_bindings().floors.values())
		if support.has("error") or support.get("collided", true): return "Unfinished helper entry lacks its actual static native floor/body support"
	return ""


func _staged_bindings(state: Dictionary, saved_player: Dictionary) -> Dictionary:
	var bindings: Dictionary = scheduler_bindings()
	for key: String in ["owner_positions", "owner_velocities", "owner_collision_states"]: bindings[key] = {}
	for id: String in Layout.SOURCES:
		var maps: Dictionary = sources[id].call("staged_actor_bindings", state.actors[id])
		if not Codec.keys_error(maps, ["owner_positions", "owner_velocities", "owner_collision_states"]).is_empty(): return {}
		for key: String in maps:
			for owner_id: String in maps[key]:
				if owner_id != id or bindings[key].has(owner_id): return {}
				bindings[key][owner_id] = maps[key][owner_id]
	bindings["hero_positions"] = {"hero": Codec.read_vector3(saved_player.motion.position)}
	return bindings


func snapshot_error(saved: Dictionary) -> String:
	var error: String = super.snapshot_error(saved)
	return _whole_progress_error(saved, hero.snapshot_state()) if error.is_empty() else error


func snapshot_error_with_player(saved: Dictionary, saved_player: Dictionary) -> String:
	var error: String = super.snapshot_error_with_player(saved, saved_player)
	return _whole_progress_error(saved, saved_player) if error.is_empty() else error


func _whole_progress_error(saved: Dictionary, saved_player: Dictionary) -> String:
	var local: Dictionary = saved.local
	var progress: Dictionary = saved.progress
	var allowed: Dictionary = {}
	for index: int in 3:
		var id: String = "court-after-" + Layout.ROOM_IDS[index]
		if index < local.room: allowed[id] = "encounter"
		elif index == local.room and _saved_room_dead(local, index) and local.scheduler.encounter_id.is_empty():
			if progress.checkpoint_ids.has(id): allowed[id] = "encounter" # legitimate pre-parent callback
	if local.room >= 3: allowed["court-boss-entry"] = "boss_phase"
	if local.room == 4 and local.helper_stage == "done": allowed["court-king-phase-two"] = "boss_phase"
	if not _same(progress.checkpoint_ids, allowed): return "Checkpoint history must match genuine ordered court boundaries"
	var latest: String = "" if allowed.is_empty() else String(allowed.keys().back())
	if progress.checkpoint_id != latest or progress.checkpoint_kind != allowed.get(latest, ""): return "Current checkpoint must retain the latest genuine ordered boundary"
	if local.awaiting_room >= 0 and not progress.checkpoint_ids.has("court-after-" + Layout.ROOM_IDS[local.room]): return "Awaiting the next court requires the actual preceding checkpoint"
	if progress.completed:
		if local.room < 3 or not local.actors["court-king"].dead or not local.scheduler.encounter_id.is_empty() or progress.completion_id != COMPLETE_ID: return "Completion requires actual King defeat and retired native danger"
	elif not progress.completion_id.is_empty() or not progress.contact_exit_id.is_empty(): return "Uncompleted court cannot carry terminal progress"
	if not progress.contact_exit_id.is_empty():
		if progress.contact_exit_id != EXIT_ID or not progress.completed: return "Exact exterior contact follows genuine court completion"
		var body := hero.get_node_or_null("BodyCollision") as CollisionShape3D
		if body == null or not body.shape is CapsuleShape3D: return "Actual retained Hero capsule required for saved contact"
		var capsule := body.shape as CapsuleShape3D
		var pin: Dictionary = _contact_pins[_exit_area.name]
		var collision: CollisionShape3D = pin.collision
		var box := AABB(collision.global_position - pin.size * 0.5, pin.size)
		var centre: Vector3 = Codec.read_vector3(saved_player.motion.position) + body.position
		var half_line: float = capsule.height * 0.5 - capsule.radius
		var nearest := Vector3(clampf(centre.x, box.position.x, box.end.x), clampf(centre.y, box.position.y - half_line, box.end.y + half_line), clampf(centre.z, box.position.z, box.end.z))
		if centre.distance_squared_to(nearest) > capsule.radius * capsule.radius: return "Saved exterior progress lacks actual native capsule/box overlap"
	return ""


func _saved_room_dead(local: Dictionary, index: int) -> bool:
	for id: String in Layout.ROOM_SOURCE_IDS[index]:
		if not local.actors[id].dead: return false
	return true


func restore_state(saved: Dictionary) -> bool:
	if not _quiet_commit_error.is_empty(): last_snapshot_error = _quiet_commit_error; return false
	last_snapshot_error = snapshot_error(saved)
	if not last_snapshot_error.is_empty(): return false
	var accepted: bool = super.restore_state(saved)
	if not _quiet_commit_error.is_empty(): last_snapshot_error = _quiet_commit_error; return false
	if accepted:
		_exterior_open = not String(saved.progress.contact_exit_id).is_empty()
		_exit_area.monitoring = is_completed() and String(saved.progress.contact_exit_id).is_empty() and _exit_contact_near()
		var contact_state: String = "available" if _exit_area.monitoring else ("spent" if _exit_contact_near() and not String(saved.progress.contact_exit_id).is_empty() else "clear")
		if not _present_contact_quiet(_exit_cue, contact_state):
			_fail_quiet_commit(_exit_cue.last_error); last_snapshot_error = _quiet_commit_error; return false
		_refresh_objective()
	return accepted


func _sync_art_presentation() -> void:
	if not is_instance_valid(_whole_art): return
	var expected: Dictionary = _expected_art_state()
	var stage: String = expected.stage
	var exterior: String = expected.exterior_state
	var key: String = stage + ":" + str(_helpers_once) + ":" + exterior
	if key == _art_stage_key:
		if not _same(_whole_art.call("presentation_state"), expected): _construction_error = "Scenic state changed outside the actual court stage transition"
		return
	if _whole_art.call("set_presentation", stage, _helpers_once, exterior) != true:
		_construction_error = "Actual whole court scenic presentation refused retained bindings"; return
	_art_stage_key = key


func _expected_art_state() -> Dictionary:
	return {"stage": "exterior" if is_completed() else Layout.ROOM_IDS[room], "helpers_open": _helpers_once, "exterior_state": "open" if _exterior_open else ("available" if is_completed() else "closed")}


func _restore_local_state(state: Dictionary) -> void:
	_quiet_commit = true
	for id: String in Layout.SOURCES:
		if sources[id].call("restore_actor_state", state.actors[id]) != true:
			_fail_quiet_commit(id + ": " + String(sources[id].get("last_snapshot_error"))); return
	if not scheduler.restore_state(state.scheduler, scheduler_bindings()): _fail_quiet_commit(scheduler.last_snapshot_error); return
	for id: String in Layout.SOURCES:
		if sources[id].call("restore_exchange_state", state.actors[id]) != true:
			_fail_quiet_commit(id + ": " + String(sources[id].get("last_snapshot_error"))); return
	if not roundel.restore_state(state.roundel, scheduler_bindings()): _fail_quiet_commit(roundel.last_snapshot_error); return
	room = state.room; formation = state.formation; _awaiting_room = state.awaiting_room
	_roundel_demonstrated = state.roundel_demonstrated; _helpers_once = state.helpers_once; helper_stage = state.helper_stage
	king_intro = _decode_native(state.king_intro)
	_entry_records = _decode_native(state.entry_records); _entry_outcomes = _decode_native(state.entry_outcomes); _frames = _decode_native(state.framing)
	_roundel_cycle = state.roundel.cycle
	_forecast.clear(); _forecast_frames.clear(); _phase_entitlements.clear(); entry_stop_diagnostics.clear(); _pending_boss_contact = false
	_boss_area.monitoring = _boss_contact_near()
	if not _present_contact_quiet(_boss_cue, "available" if _boss_area.monitoring else ("clear" if _awaiting_room == 3 else "spent")):
		_fail_quiet_commit(_boss_cue.last_error); return
	var terminal: bool = room >= 3 and state.actors["court-king"].dead and state.scheduler.encounter_id.is_empty()
	_exit_area.monitoring = terminal and _exit_contact_near()
	if not _present_contact_quiet(_exit_cue, "available" if _exit_area.monitoring else "clear"):
		_fail_quiet_commit(_exit_cue.last_error); return
	_refresh_objective()
	_quiet_commit = false


func _present_contact_quiet(cue: CinderInteractionCue, state: String) -> bool:
	if not is_instance_valid(cue) or cue.get_parent() != self or cue.is_queued_for_deletion(): return false
	var blocked: bool = cue.is_blocking_signals()
	cue.set_block_signals(true)
	var accepted: bool = cue.clear() if state == "clear" else cue.present(state, "contact")
	cue.set_block_signals(blocked)
	return accepted


func _fail_quiet_commit(error: String) -> void:
	_quiet_commit_error = error if not error.is_empty() else "Unexpected whole native quiet commit refusal"
	_quiet_commit = false; _running = false
	for actor: CharacterBody3D in sources.values(): actor.set_physics_process(false)
	scheduler.set_physics_process(false); roundel.set_physics_process(false); set_physics_process(false)


func finish_restore_candidate() -> bool:
	if _quiet_commit or _constructor_open or not _quiet_commit_error.is_empty(): return false
	var accepted: bool = super.finish_restore_candidate()
	if accepted: _refresh_objective()
	return accepted


func _restore_candidate_presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	if _quiet_commit or _constructor_open or not _quiet_commit_error.is_empty(): return "Discard incomplete native quiet candidate"
	return _current_presentation_error(camera, hud)


func _actual_camera() -> Camera3D:
	if not is_inside_tree(): return null
	var camera: Camera3D = get_viewport().get_camera_3d()
	return camera if is_instance_valid(camera) and camera.get_script() == null and camera.get_world_3d() == get_world_3d() and camera.get_viewport() == get_viewport() else null


func _hero_points() -> Array:
	return shared_shell.call("player_camera_framing_points_for", hero, _actual_camera()) if is_instance_valid(shared_shell) else []


func _current_presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	var error: String = _native_runtime_error()
	if not error.is_empty(): return error
	if camera != _actual_camera() or not is_instance_valid(camera) or not is_instance_valid(hud): return "Actual current court camera and canonical HUD required"
	var points: Array = _camera_framing_points()
	if points.is_empty() or points.size() > 224 or points.has(Vector3.INF) or _hero_points().size() != 22: return "Complete actual source/footprint/landing/contact/Hero corners required"
	return String(shared_shell.call("camera_framing_error_for_context", points, hero, camera, hud))


func _saved_response_error(state: Dictionary, saved_player: Dictionary) -> String:
	if not _same(hero.equipment.snapshot(), saved_player.equipment): return "Actual candidate equipment must match saved complete Player"
	var stats: Dictionary = hero.equipment.resolved_stats()
	var threats: Array[Dictionary] = []
	for record: Dictionary in state.scheduler.reservations:
		var shape: Dictionary = _decode_native(record.geometry)
		var error: String = Geometry.error(shape)
		if not error.is_empty(): return error
		threats.append({"record": record, "shape": shape})
	for item: Dictionary in threats:
		var record: Dictionary = item.record
		var proof: Dictionary = state.framing[record.source_id].proof
		var path: Array[Dictionary] = []
		for segment: Dictionary in proof.path: path.append(_decode_native(segment))
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
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return "Static court scenery blocks the original primary"
		if proof.response_complete_s < proof.primary_time_s + float(stats.primary_cooldown): return "Saved response truncates ordinary primary recovery"
	return ""


func _encode_native(value: Variant) -> Variant:
	if value is Vector3: return Codec.vector3(value)
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_encode_native(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key: String in value: result[key] = _encode_native(value[key])
		return result
	return value


func _decode_native(value: Variant) -> Variant:
	# Decode only explicitly documented native coordinate fields, never arbitrary
	# length-three arrays (hit histories and deadline groups remain literal).
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_decode_native(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key: String in value:
			result[key] = Codec.read_vector3(value[key]) if key in ["from", "to", "endpoint", "landing", "attack_position", "origin", "direction", "source_position"] and Codec.is_vector3(value[key]) else _decode_native(value[key])
		return result
	return value


func _same(left: Variant, right: Variant) -> bool:
	var text: String = Exact.stringify(left)
	return not text.is_empty() and text == Exact.stringify(right)


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
