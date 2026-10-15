extends "res://tests/acts/act1/a1_l4_whole_entry.gd"
## Focused actual Main / whole A1-L4 portrait, never an earned-route gate.
## Reuses the actual eight-source/floor/native progression setup and disposal
## fixture. Every later public injury/Hero placement is explicitly TEST.
## Input comes only from literal shared recognizer touch events. No equipment,
## source transforms, parent room/entry records, private timers or cue edits.
## Author source-only; root must run the renderer and personally inspect PNGs.

const ArtScriptPath: String = "res://scripts/acts/act1/selenite_court_whole_art.gd"
const CourtCodec = preload("res://scripts/acts/act1/selenite_court_codec.gd")
const SourceID: String = "court-curtain-guard"
const PositionTolerance: float = 0.035
const KingIntroDistance: float = 0.7
const KingIntroSpeed: float = 1.4
const KingIntroDuration: float = 0.5

class FocusObserver:
	extends Node
	var receive: Callable
	func _notification(what: int) -> void:
		if not receive.is_valid(): return
		if what == NOTIFICATION_APPLICATION_FOCUS_IN: receive.call("application-focus-in")
		elif what == NOTIFICATION_APPLICATION_FOCUS_OUT: receive.call("application-focus-out")
		elif what == NOTIFICATION_APPLICATION_PAUSED: receive.call("application-paused")
		elif what == NOTIFICATION_APPLICATION_RESUMED: receive.call("application-resumed")

var art: Node3D
var capture_dir: String = ""
var shots: Array[Dictionary] = []
var focus_receipts: Array[Dictionary] = []
var input_receipts: Array[Dictionary] = []
var action_receipts: Array[Dictionary] = []
var hit_receipts: Array[Dictionary] = []
var focus_observer: Node
var expected_pause: bool = false
var representative_only: bool = false
var terminal_views_only: bool = false
var swipes: int = 0
var primaries: int = 0
var gui_resumes: int = 0
var gesture_unit: Dictionary = {}
var pause_receipt: Dictionary = {}
var king_intro_original: Dictionary = {}


func _run() -> void:
	scope = "whole-court-brief-portrait"
	terminal_views_only = "--terminal-views-only" in OS.get_cmdline_user_args()
	representative_only = terminal_views_only or "--representative-only" in OS.get_cmdline_user_args()
	root.size = PortraitSize
	report_path = "res://.cinder/a1-l4-whole-portrait-%d.json" % Time.get_ticks_usec()
	if not _require(DisplayServer.get_name() != "headless" and "--capture" not in OS.get_cmdline_user_args() and "--capture-polish" not in OS.get_cmdline_user_args(), "whole portrait requires the actual renderer and ordinary focus handling"):
		await _finish(); return
	var observer := FocusObserver.new()
	observer.name = "WholeCourtPortraitFocusObserver"
	observer.process_mode = Node.PROCESS_MODE_ALWAYS
	observer.receive = Callable(self, "_record_focus")
	focus_observer = observer
	root.add_child(observer)
	root.focus_entered.connect(_record_focus.bind("window-focus-entered"))
	root.focus_exited.connect(_record_focus.bind("window-focus-exited"))
	if not await _prepare_focus(): await _finish(); return
	capture_dir = "res://.cinder/captures/l4-whole-%d" % Time.get_ticks_usec()
	if not _require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir)) == OK, "whole portrait output directory is writable"):
		await _finish(); return
	print("A1-L4 WHOLE PORTRAIT SETUP: later public injuries and Hero placements are labelled TEST; native parent boundaries/contact/birth only; representative_only=", representative_only, "; no earned-route/full-playthrough/Save/fidelity claim")
	if not _open(): await _finish(); return
	if not _require(CourtCodec.API_REVISION == "act1-court-aggregate-3" and CourtCodec.SCHEMA_VERSION == 3 and CourtCodec.LEGACY_SCHEMA_VERSION == 2 and CourtCodec.WORLD_REVISION == 2 and level.get("king_intro") == {"stage": "unborn", "record": {}, "outcome": {}}, "current court retains the untouched King introduction and legacy2 reader under aggregate3/world2"):
		await _finish(); return
	art = level.get_node_or_null("WholeCourtArt") as Node3D
	if not _require(is_instance_valid(art) and art.get_script().resource_path == ArtScriptPath and String(art.call("binding_error")).is_empty() and art.call("presentation_state") == {"stage": "curtain", "helpers_open": false, "exterior_state": "closed"}, "actual whole leaf retains its own native resources and default scenic state"):
		await _finish(); return
	hero.world_action_executed.connect(func(record: Dictionary) -> void: action_receipts.append(record.duplicate(true)))
	game.connect("input_observed", func(record: Dictionary) -> void: input_receipts.append(record.duplicate(true)))
	for id: String in sources:
		sources[id].connect("hit_resolved", Callable(self, "_notice_portrait_hit").bind(id))
	if terminal_views_only:
		setups.append({"scope": scope, "kind": "explicit_mode", "label": "TEST terminal-only visual regression; earlier unchanged views and gestures are not rerun or claimed"})
		if not await _terminal_views() or not _require(shots.size() == 3 and swipes == 0 and primaries == 0 and gui_resumes == 0 and _retained_identities(), "three actual terminal views retain the original cast and declared zero-input scope") or not await _contact_exit_and_cleanup(): await _finish(); return
		await _finish(); return
	if not await _wait(func() -> bool: return _current_framing_error().is_empty(), "actual current camera contains the complete opening cast", 3.0) or not await _capture("opening-real-view"):
		await _finish(); return
	if not await _wait(func() -> bool: return _native_warning(SourceID) and (level.get("_frames") as Dictionary).get(SourceID, {}).has("proof"), "real curtain warning retains the parent's actual native proof", 4.0) or not await _capture("curtain-native-warning") or not await _pause_probe():
		await _finish(); return
	if not representative_only and not await _curtain_gesture(): await _finish(); return
	if representative_only:
		setups.append({"scope": scope, "kind": "explicit_mode", "label": "TEST --representative-only omits actual gesture sequence; no swipe/primary credit"})
	if not await _representative_courts(): await _finish(); return
	if not _require(shots.size() >= (14 if representative_only else 16) and gui_resumes == 1 and _retained_identities() and (swipes == 0 and primaries == 0 if representative_only else swipes == 2 and primaries == 1), "focused views retain the original finite cast, real King step/summon and exact declared GUI/input scope"):
		await _finish(); return
	if not await _contact_exit_and_cleanup(): await _finish(); return
	await _finish()


func _curtain_gesture() -> bool:
	var actor: CharacterBody3D = sources[SourceID]
	var frame: Dictionary = (level.get("_frames") as Dictionary).get(SourceID, {}).duplicate(true)
	var state: Dictionary = actor.call("pure_presentation_state")
	var control: Dictionary = scheduler.source_control_state(actor)
	if not _require(frame.has("proof") and control.reservations.size() == 1 and frame.reservation_id == state.reservation_id and control.reservations[0].id == frame.reservation_id, "genuine response reads the same parent's retained proof and actual native lease"): return false
	var proof: Dictionary = frame.proof
	var reservation: Dictionary = control.reservations[0].duplicate(true)
	if not _require(proof.uses_blast == false and proof.uses_invulnerability == false and proof.primary_time_s >= reservation.active_until_s and proof.response_complete_s < reservation.recovery_until_s, "first native response proves an ordinary escape and primary with unchanged legal controls"): return false
	gesture_unit = {"reservation": _portable(reservation), "proof": _portable(proof), "hero_hp_before": hero.hp, "source_hp_before": actor.get("hp"), "shells_before": hero.shells}
	var escape: Vector3 = proof.landing - hero.global_position
	if not _require(absf(Vector2(escape.x, escape.z).length() - float(hero.equipment.resolved_stats().dash_distance)) <= PositionTolerance, "retained native escape is one complete normal dash") or not await _swipe(escape, "real curtain escape") or not await _capture("curtain-real-safe-landing"): return false
	var return_start: float = float(proof.primary_time_s)
	for segment: Dictionary in proof.path:
		if segment.kind == "positioning_dash": return_start = float(segment.start_s)
	if not await _wait(func() -> bool: return scheduler.get_clock() >= return_start, "same native response reaches its actual return boundary", 4.0): return false
	var returning: Vector3 = proof.attack_position - hero.global_position
	returning.y = 0.0
	if returning.length() > PositionTolerance:
		if not _require(absf(returning.length() - float(hero.equipment.resolved_stats().dash_distance)) <= PositionTolerance, "ordinary opening return is a complete normal dash") or not await _swipe(returning, "real curtain return"): return false
	if not await _wait(func() -> bool: return scheduler.get_clock() >= float(proof.primary_time_s), "same native response reaches its ordinary primary time", 3.0) or not await _primary(actor, reservation, proof): return false
	var after: Dictionary = actor.call("pure_presentation_state")
	if not _require(after.hp > 0.0 and after.hp < float(gesture_unit.source_hp_before) and after.last_cancel_reason == "actual_player_damage" and String(after.reservation_id).is_empty() and hero.hp == float(gesture_unit.hero_hp_before) and hit_receipts.is_empty() and action_receipts.size() == input_receipts.size(), "one genuine nonlethal primary changes real enemy HP without a Hero hit or forged action"): return false
	gesture_unit["hero_hp_after"] = hero.hp
	gesture_unit["source_hp_after"] = after.hp
	gesture_unit["shells_after"] = hero.shells
	gesture_unit["world_actions"] = _portable(hero.get_world_action_records())
	return await _capture("curtain-real-surviving-primary")


func _terminal_views() -> bool:
	# Use real parent progression and public TEST injuries/placements to reach
	# only the changed completion/contact view; no room, clock or source writes.
	if not _test_damage(SourceID, 24.0, "TEST curtain defeat for terminal visual regression") or not await _wait(func() -> bool: return level.current_checkpoint().id == "court-after-curtain", "actual cleared curtain boundary", 3.0) or not await _test_position(Vector3(0, 0.1, -7), "TEST actual formation approach"): return false
	if not await _wait(func() -> bool: return int(level.get("room")) == 1 and not sources["court-formation-west"].get("dormant") and not sources["court-formation-east"].get("dormant"), "actual original formation pair activates", 3.0): return false
	for id: String in Layout.ROOM_SOURCE_IDS[1]:
		if not _test_damage(id, 24.0, "TEST formation defeat for terminal visual regression"): return false
	if not await _wait(func() -> bool: return level.current_checkpoint().id == "court-after-formation", "actual cleared formation boundary", 3.0) or not await _test_position(Vector3(0, 0.1, -17), "TEST actual royal approach"): return false
	if not await _wait(func() -> bool: return int(level.get("room")) == 2 and level.get("_roundel_demonstrated") == true and not sources["court-approach-west"].get("dormant") and not sources["court-approach-east"].get("dormant"), "actual quiet roundel completes before familiar approach sources activate", 10.0): return false
	for id: String in Layout.ROOM_SOURCE_IDS[2]:
		if not _test_damage(id, 24.0, "TEST approach defeat for terminal visual regression"): return false
	if not await _wait(func() -> bool: return level.current_checkpoint().id == "court-after-approach", "actual cleared approach boundary", 3.0) or not await _test_position(Vector3(0, 0.1, -24.5), "TEST supported local throne approach"): return false
	if not await _wait(func() -> bool: return (level.get_node("BossContactArea") as Area3D).monitoring and _current_framing_error().is_empty(), "actual local throne contact has full current view", 3.0) or not await _test_position(Vector3(0, 0.1, -26), "TEST actual native boss contact"): return false
	if not await _wait(func() -> bool: return int(level.get("room")) == 3 and (level.get("king_intro") as Dictionary).stage == "done", "actual original finite King introduction completes", 4.0) or not await _test_position(Vector3(0, 0.1, -28.2), "TEST central supported helper view") or not _test_damage("court-king", 40.0, "TEST actual half-HP helper threshold"): return false
	if not await _wait(func() -> bool: return int(level.get("room")) == 4 and level.get("helper_stage") == "done", "actual once-born helper pair completes original entry", 4.0) or not _test_damage("court-king", 40.0, "TEST terminal native King injury"): return false
	if not await _wait(func() -> bool: return level.is_completed() and _current_framing_error().is_empty(), "completed distant court retains a coherent actual view", 3.0): return false
	if not _require(not (level.get_node("ExitArea") as Area3D).monitoring and level.get("_exit_cue").state().state == "clear", "completed distant exit remains inactive with no off-screen available cue") or not await _capture("TEST-completed-distant-contact-clear"): return false
	if not await _test_position(Vector3(0, 0.1, -33.8), "TEST supported local exterior approach") or not await _wait(func() -> bool: return (level.get_node("ExitArea") as Area3D).monitoring and level.get("_exit_cue").state().state == "available" and _current_framing_error().is_empty(), "actual local full view exposes available contact", 3.0) or not await _capture("TEST-exterior-available-contact-cue"): return false
	if not await _test_position(Vector3(0, 0.1, -35), "TEST supported actual exterior contact") or not await _wait(func() -> bool: return _event_count("contact") == 1 and art.call("presentation_state").exterior_state == "open" and level.get("_exit_cue").state().state == "spent", "actual guarded contact opens cloth and becomes spent exactly once", 3.0): return false
	return await _capture("TEST-exterior-open-after-real-contact")


func _representative_courts() -> bool:
	if not _test_damage(SourceID, float(sources[SourceID].get("hp")), "TEST remaining curtain injury for representative formation") or not await _wait(func() -> bool: return level.current_checkpoint().id == "court-after-curtain", "public curtain defeat requests the native encounter boundary", 2.0): return false
	if not await _test_position(Vector3(0, 0.1, -7), "TEST supported Hero placement across actual formation boundary") or not await _wait(func() -> bool: return int(level.get("room")) == 1 and (_native_warning("court-formation-west") or _native_warning("court-formation-east")), "actual same-pair parallel native warning is visible", 5.0): return false
	if not _require(level.get("formation") == "parallel" and art.call("presentation_state").stage == "formation", "native parallel arrangement selects the real formation scenery") or not await _capture("TEST-formation-parallel-warning"): return false
	if not await _wait(func() -> bool: return level.get("formation") == "inward" and (_native_warning("court-formation-west") or _native_warning("court-formation-east")), "same pair naturally changes to inward with a genuine native warning", 10.0): return false
	if not _require(sources["court-formation-west"] == retained["court-formation-west"] and sources["court-formation-east"] == retained["court-formation-east"] and sources["court-formation-west"].get("hp") == 24.0 and sources["court-formation-east"].get("hp") == 24.0, "inward view retains both actual original full-HP guards") or not await _capture("TEST-same-pair-inward-warning"): return false
	for id: String in Layout.ROOM_SOURCE_IDS[1]:
		if not _test_damage(id, float(sources[id].get("hp")), "TEST formation defeat for representative royal approach"): return false
	if not await _wait(func() -> bool: return level.current_checkpoint().id == "court-after-formation", "actual formation boundary is requested", 2.0) or not await _test_position(Vector3(0, 0.1, -17), "TEST supported Hero placement across actual royal-approach boundary"): return false
	if not await _wait(func() -> bool: return int(level.get("room")) == 2 and roundel.state().status == "running" and roundel.state().phase == "warning", "genuine known quiet roundel warning precedes the approach guards", 5.0): return false
	if not _require(sources["court-approach-west"].get("dormant") and sources["court-approach-east"].get("dormant"), "quiet impact view leaves future approach sources dormant") or not await _capture("TEST-known-roundel-quiet-warning"): return false
	if not await _wait(func() -> bool: return level.get("_roundel_demonstrated") == true and (_native_warning("court-approach-west") or _native_warning("court-approach-east")), "actual completed demonstration admits familiar approach warning", 10.0) or not await _capture("TEST-royal-approach-native-warning"): return false
	for id: String in Layout.ROOM_SOURCE_IDS[2]:
		if not _test_damage(id, float(sources[id].get("hp")), "TEST approach defeat for actual boss contact"): return false
	if not await _wait(func() -> bool: return level.current_checkpoint().id == "court-after-approach", "actual parent requests the cleared approach checkpoint", 3.0) or not await _test_position(Vector3(0, 0.1, -24.5), "TEST supported local throne approach before actual contact"): return false
	if not await _wait(func() -> bool: return (level.get_node("BossContactArea") as Area3D).monitoring and _current_framing_error().is_empty(), "actual local4.5 approach exposes the full native throne contact Area/cue", 3.0) or not await _capture("TEST-boss-contact-available-local-view"): return false
	if not await _test_position(Vector3(0, 0.1, -26), "TEST supported Hero placement inside actual boss contact Area"): return false
	if not await _wait(func() -> bool: return _king_intro_stepping(), "real boss contact exposes the actual unleased King moving away from the throne", 3.0) or not await _capture("TEST-King-real-intro-step-away-from-throne"): return false
	king_intro_original = (level.get("king_intro") as Dictionary).record.duplicate(true)
	if not await _wait(func() -> bool: return (level.get("king_intro") as Dictionary).stage == "done" and _native_warning("court-king"), "the original nonattack step completes before a genuine native King warning", 5.0) or not _king_intro_history_unchanged() or not await _capture("TEST-King-native-warning-low-side-throne"): return false
	if not await _test_position(Vector3(0, 0.1, -28.2), "TEST supported central view outside the actual helper entry corridors") or not _test_damage("court-king", 40.0, "TEST actual King80-to40 phase threshold"): return false
	if not await _wait(func() -> bool: return level.get("helper_stage") == "entering" and _helpers_moving() and _king_summoning(), "actual once-born helpers enter while the unharmed unleased King derives its summon gesture", 3.0): return false
	entry_originals = (level.get("_entry_records") as Dictionary).duplicate(true)
	if not _require(art.call("presentation_state").helpers_open == true and art.call("presentation_state").stage == "king2", "parent once-history opens the two genuine scenic helper curtains") or not await _capture("TEST-real-finite-helper-entry-King-summon"): return false
	if not await _wait(func() -> bool: return level.get("helper_stage") == "done", "original finite native helper deadline reaches its phase boundary", 2.0): return false
	var outcomes: Dictionary = level.get("_entry_outcomes")
	for id: String in HelperIds:
		if not _require(outcomes.get(id, {}).get("outcome") == "complete" and sources[id] == retained[id] and sources[id].get("hp") == 24.0 and sources[id].velocity == Vector3.ZERO and _planar_distance(sources[id].global_position, entry_originals[id].to) <= Motion.ENDPOINT_TOLERANCE, "representative full entry retains actual stopped endpoint/full HP/original helper " + id): return false
	if not _entry_history_unchanged() or not await _capture("TEST-same-finite-helper-pair-stopped"): return false
	if not _test_damage("court-king", float(sources["court-king"].get("hp")), "TEST terminal King injury for representative exterior cloth"): return false
	if not await _wait(func() -> bool: return level.is_completed(), "actual completion retires native court danger", 3.0) or not await _test_position(Vector3(0, 0.1, -33.8), "TEST supported local Hero approach before exterior contact"): return false
	if not await _wait(func() -> bool: return (level.get_node("ExitArea") as Area3D).monitoring and _current_framing_error().is_empty(), "local full current view exposes the actual exterior contact", 3.0): return false
	if not _require(art.call("presentation_state") == {"stage": "exterior", "helpers_open": true, "exterior_state": "available"} and _event_count("contact") == 0, "available cloth is backed by real completion and remains distinct from contact") or not await _capture("TEST-exterior-available-contact-cue"): return false
	if not await _test_position(Vector3(0, 0.1, -35), "TEST supported Hero placement across actual exterior contact Area") or not await _wait(func() -> bool: return _event_count("contact") == 1 and art.call("presentation_state").exterior_state == "open", "real native contact selects the open exterior cloth", 2.0): return false
	return await _capture("TEST-exterior-open-after-real-contact")


func _king_intro_stepping() -> bool:
	if paused or int(level.get("room")) != 3: return false
	var intro: Dictionary = level.get("king_intro") as Dictionary
	if intro.get("stage") != "entering" or not intro.get("record") is Dictionary or not intro.get("outcome") is Dictionary or not intro.outcome.is_empty(): return false
	var record: Dictionary = intro.record
	if record.get("active") != true or not record.get("from") is Vector3 or not record.get("to") is Vector3 or not record.get("start_s") is float or not record.get("end_s") is float or record.get("speed") != KingIntroSpeed: return false
	if record.to != record.from + Vector3(0, 0, KingIntroDistance) or record.from.x != Layout.SOURCES["court-king"].position.x or record.from.z != Layout.SOURCES["court-king"].position.z or record.end_s != float(record.start_s) + KingIntroDuration: return false
	var king: CharacterBody3D = sources["court-king"]
	var actual: Dictionary = king.call("pure_presentation_state")
	var control: Dictionary = scheduler.source_control_state(king)
	var king_art: Node3D = king.call("get_art") as Node3D
	return king == retained["court-king"] and is_instance_valid(king_art) and king_art.call("pose_name") == "step" and level.call("court_king_presentation", king) == "step" and actual.hp == 80.0 and not actual.dead and not actual.dormant and actual.hurt_left_s == 0.0 and actual.cycle == 0 and String(actual.reservation_id).is_empty() and control.reservations.is_empty() and king.velocity.z > 0.0 and king.global_position.z > record.from.z and king.global_position.z < record.to.z and scheduler.get_clock() >= float(record.start_s) and scheduler.get_clock() < float(record.end_s)


func _king_intro_history_unchanged() -> bool:
	var intro: Dictionary = level.get("king_intro") as Dictionary
	var record: Dictionary = intro.get("record", {})
	if not _require(not king_intro_original.is_empty() and intro.get("stage") == "done", "actual King step retires once before native lunge admission"): return false
	for key: String in ["active", "from", "to", "start_s", "end_s", "speed"]:
		if not _require(record.get(key) == king_intro_original.get(key), "King intro retains its original measured history " + key): return false
	return _require(intro.get("outcome", {}).get("outcome") == "complete", "actual native King introduction preserves its complete terminal outcome")


func _king_summoning() -> bool:
	if paused or int(level.get("room")) != 4 or level.get("helper_stage") not in ["settling", "entering"]: return false
	var king: CharacterBody3D = sources["court-king"]
	var actual: Dictionary = king.call("pure_presentation_state")
	var control: Dictionary = scheduler.source_control_state(king)
	var king_art: Node3D = king.call("get_art") as Node3D
	return king == retained["court-king"] and is_instance_valid(king_art) and king_art.call("pose_name") == "summon" and level.call("court_king_presentation", king) == "summon" and actual.hp > 0.0 and actual.hp <= 40.0 and not actual.dead and not actual.dormant and actual.hurt_left_s == 0.0 and String(actual.reservation_id).is_empty() and control.reservations.is_empty()


func _helpers_moving() -> bool:
	if level.get("helper_stage") != "entering": return false
	# Read the actual current records before their historical copy is captured;
	# the inherited helper assumes that copy was already populated by its caller.
	var records: Dictionary = level.get("_entry_records") as Dictionary
	for id: String in HelperIds:
		var record: Dictionary = records.get(id, {})
		if not record.get("from") is Vector3 or record.get("active") != true or sources[id].velocity.z <= 0.0 or sources[id].global_position.z <= (record.from as Vector3).z + Motion.EPSILON: return false
	return true


func _pause_probe() -> bool:
	expected_pause = true
	if not _require(game.call("request_pause_deferred"), "real warning requests the public coherent pause barrier") or not await _wait(func() -> bool: return paused, "shared pause closes outside native callback delivery", 2.0): return false
	var frozen: Dictionary = _pause_unit()
	var until: int = Time.get_ticks_msec() + 120
	while not aborted and Time.get_ticks_msec() < until:
		if not _guard(): return false
		await process_frame
	if not _require(_pause_unit() == frozen, "actual pause freezes native HP/clock/entry/leases/input/action/progress without Save or rewind") or not await _capture("curtain-native-warning-paused-UI"): return false
	pause_receipt = _portable(frozen)
	return await _gui_resume()


func _pause_unit() -> Dictionary:
	var controls: Dictionary = {}
	var states: Dictionary = {}
	for id: String in sources:
		controls[id] = scheduler.source_control_state(sources[id])
		states[id] = sources[id].call("pure_presentation_state")
	return {"hero_position": hero.global_position, "hero_velocity": hero.velocity, "hero_hp": hero.hp, "hero_shells": hero.shells, "hero_clock": hero.get_world_action_clock(), "scheduler_clock": scheduler.get_clock(), "profile": scheduler.encounter_profile(), "source_states": states, "source_controls": controls, "roundel": roundel.state(), "king_intro": (level.get("king_intro") as Dictionary).duplicate(true), "helper_stage": level.get("helper_stage"), "entry_records": (level.get("_entry_records") as Dictionary).duplicate(true), "entry_outcomes": (level.get("_entry_outcomes") as Dictionary).duplicate(true), "art": art.call("presentation_state"), "input": game.call("get_input_observation_state"), "actions": hero.get_world_action_records(), "native_events": native_events.size(), "progress_events": progress_events.size(), "checkpoint": level.current_checkpoint(), "completed": level.is_completed()}


func _gui_resume() -> bool:
	if not _guard(): return false
	var button: Button = _resume_button(game.get("hud") as Node)
	if not _require(paused and is_instance_valid(button), "actual shared pause UI exposes Resume"): return false
	var before: Dictionary = game.call("get_input_observation_state")
	var actions: Array[Dictionary] = hero.get_world_action_records()
	var point: Vector2 = button.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = point; press.global_position = point
	Input.parse_input_event(press)
	await process_frame
	if not _guard(): return false
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT; release.position = point; release.global_position = point
	Input.parse_input_event(release)
	await process_frame
	expected_pause = false
	gui_resumes += 1
	_record_focus("after-genuine-GUI-Resume")
	return _require(not paused and game.call("get_input_observation_state") == before and hero.get_world_action_records() == actions, "actual GUI press/frame/release/frame resumes with no gameplay tap/dash/anchor change") and _guard()


func _primary(actor: CharacterBody3D, reservation: Dictionary, proof: Dictionary) -> bool:
	if not await _ready_input("real curtain primary"): return false
	var offset: Vector3 = actor.global_position - hero.global_position
	offset.y = 0.0
	var direction: Vector3 = offset.normalized()
	var anchor: Vector2 = game.call("get_aim_anchor")
	var anchor_normalized: Vector2 = game.call("get_aim_anchor_normalized")
	var tap: Vector2 = anchor + _screen_delta(direction) * 160.0
	if not _require(actor.is_in_group("enemies") and offset.length() <= float(hero.equipment.resolved_stats().primary_range) and _input_safe(tap) and (game.call("aim_direction", tap) as Vector3).dot(direction) > 0.9999, "ordinary primary reach/aim derive from the actual source and last swipe release"): return false
	var hp_before: float = float(actor.get("hp"))
	var sequence: int = _last_sequence()
	var press := InputEventScreenTouch.new()
	press.index = 7; press.pressed = true; press.position = tap
	Input.parse_input_event(press)
	await process_frame
	if not _guard(): return false
	var actual: Dictionary = actor.call("pure_presentation_state")
	if not _require(actual.reservation_id == reservation.id and actual.phase == "recovery" and scheduler.get_clock() >= float(proof.primary_time_s) and scheduler.get_clock() < float(reservation.recovery_until_s), "literal first-tap release lies inside the same original native recovery"): return false
	var release := InputEventScreenTouch.new()
	release.index = 7; release.position = tap
	gesture_unit["primary_release_clock_s"] = scheduler.get_clock()
	Input.parse_input_event(release)
	await process_frame
	if not _guard(): return false
	primaries += 1
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	var observed: Dictionary = game.call("get_input_observation_state")
	return _require(records.size() == 1 and records[0].kind == "primary" and records[0].hits == 1 and float(actor.get("hp")) < hp_before and records[0].direction.dot(direction) > 0.9999 and observed.last_observation.kind == "primary_tap" and observed.last_observation.accepted and observed.last_observation.world_action_sequence == records[0].sequence and game.call("get_aim_anchor_normalized") == anchor_normalized, "one immediate ordinary first tap hits through the real recognizer with natural ammo and unchanged aim")


func _notice_portrait_hit(hero_id: String, cycle: int, hit: Dictionary, source_id: String) -> void:
	hit_receipts.append({"source_id": source_id, "hero_id": hero_id, "cycle": cycle, "result": hit.duplicate(true)})


func _ready_input(label: String) -> bool:
	return await _wait(func() -> bool:
		var state: Dictionary = hero.get_threat_response_state()
		return state.stable and state.dash_cooldown_left_s == 0.0 and state.primary_cooldown_left_s == 0.0 and state.commitment_remaining_s == 0.0, label + " reaches actual native input readiness", 4.0)


func _guard() -> bool:
	if aborted or finishing: return false
	var valid: bool = root.has_focus() and DisplayServer.window_is_focused(root.get_window_id()) and is_instance_valid(level) and is_instance_valid(hero) and is_instance_valid(scheduler) and not hero.dead and (not paused or expected_pause) and level.contract_error().is_empty()
	return true if valid else _require(false, "unexpected native focus/pause/Hero death/alias or court contract failure; no forced resume")


func _current_framing_error() -> String:
	var points: Array = level.camera_framing_points()
	if points.is_empty() or not level.last_camera_framing_error.is_empty(): return level.last_camera_framing_error if not level.last_camera_framing_error.is_empty() else "Actual full points are unavailable"
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite(): return "Actual full native points are not finite"
	return String(game.call("camera_framing_error", points))


func _capture(stage: String) -> bool:
	if not _guard(): return false
	await RenderingServer.frame_post_draw
	if not _guard() or not _require(_current_framing_error().is_empty() and String(art.call("binding_error")).is_empty(), "actual full actor/body/cue/Hero/landing/contact and retained scenery binding at " + stage): return false
	if stage == "TEST-King-real-intro-step-away-from-throne" and not _require(_king_intro_stepping(), "intro portrait actually catches the unharmed unleased King moving with its derived step pixels"): return false
	if stage.begins_with("TEST-real-finite-helper-entry") and not _require(level.get("helper_stage") == "entering" and _helpers_moving() and _king_summoning(), "entry portrait actually catches native helper motion and the derived King summon before their original deadline"): return false
	if stage.contains("warning"):
		var seen: bool = false
		if stage.contains("roundel"): seen = roundel.state().status == "running" and roundel.state().phase == "warning"
		elif stage.contains("King"): seen = int(level.get("room")) == 3 and _native_warning("court-king")
		elif stage.contains("formation") or stage.contains("inward"):
			seen = int(level.get("room")) == 1 and level.get("formation") == ("inward" if stage.contains("inward") else "parallel") and (_native_warning("court-formation-west") or _native_warning("court-formation-east"))
		elif stage.contains("approach"): seen = int(level.get("room")) == 2 and (_native_warning("court-approach-west") or _native_warning("court-approach-east"))
		else: seen = int(level.get("room")) == 0 and _native_warning(SourceID)
		if not _require(seen, "warning portrait contains its labelled actual current armed native source/arrangement"): return false
	var image: Image = root.get_texture().get_image()
	var path: String = capture_dir.path_join("%02d-whole-%s.png" % [shots.size() + 1, stage])
	if not _require(image != null and image.get_size() == PortraitSize and image.save_png(path) == OK, "actual540x1170 renderer saves " + stage): return false
	var ids: Array[String] = []
	ids.assign(["exterior"] if level.is_completed() else (["entrance"] if int(level.get("room")) == 0 else (["formation"] if int(level.get("room")) == 1 else (["approach", "roundel"] if int(level.get("room")) == 2 else ["throne", "helper-entries"]))))
	if stage.contains("boss-contact"): ids.assign(["throne", "helper-entries"])
	var bounds: Dictionary = {}
	for id: String in ids:
		var corners: Array = art.call("landmark_world_corners", id)
		if not _require(corners.size() == 8, "relevant actual scenery exposes complete eight-corner bounds " + id): return false
		for point: Variant in corners:
			if not _require(point is Vector3 and point.is_finite(), "relevant scenery retains finite native full geometry " + id): return false
		bounds[id] = _portable(corners)
	var source_states: Dictionary = {}
	for id: String in sources:
		source_states[id] = sources[id].call("pure_presentation_state")
	var king: CharacterBody3D = sources["court-king"]
	var king_art: Node3D = king.call("get_art") as Node3D
	shots.append({"stage": stage, "path": ProjectSettings.globalize_path(path), "size_px": [540, 1170], "scope": "labelled TEST representative progression" if stage.begins_with("TEST-") else "actual unchanged opening/recognizer response", "paused": paused, "native_focus": DisplayServer.window_is_focused(root.get_window_id()), "room": level.get("room"), "formation": level.get("formation"), "king_intro": _portable(level.get("king_intro")), "king_art_pose": king_art.call("pose_name") if is_instance_valid(king_art) else "unavailable", "helper_stage": level.get("helper_stage"), "hero_position": _portable(hero.global_position), "hero_hp": hero.hp, "sources": _portable(source_states), "roundel": _portable(roundel.state()), "entry_originals": _portable(level.get("_entry_records")), "entry_outcomes": _portable(level.get("_entry_outcomes")), "art_presentation": art.call("presentation_state"), "scenery_full_bounds": bounds, "camera": _portable(game.call("get_camera_framing_state")), "completed": level.is_completed(), "checkpoint": level.current_checkpoint(), "optical_review": "pending root personal image inspection; native containment is not scenery-overlap or fidelity acceptance"})
	_record_focus("capture/" + stage)
	_observe(stage)
	return true


func _prepare_focus() -> bool:
	# One declared TEST foreground request before Main; later native focus-out
	# behavior remains unchanged and any unexpected pause aborts the fixture.
	setups.append({"scope": scope, "kind": "startup_foreground_request", "label": "TEST one supported native foreground request before Main; later focus handling unchanged"})
	DisplayServer.window_move_to_foreground(root.get_window_id())
	var deadline: int = Time.get_ticks_msec() + 4000
	var stable: int = -1
	while Time.get_ticks_msec() < deadline and not finishing:
		if root.has_focus() and DisplayServer.window_is_focused(root.get_window_id()):
			if stable < 0: stable = Time.get_ticks_msec()
			if Time.get_ticks_msec() - stable >= 200: _record_focus("genuine-startup-focus-stable"); return _require(true, "actual startup native focus remains stable200ms")
		else: stable = -1
		await process_frame
	return _require(false, "graphical fixture requires actual startup focus before Main")


func _record_focus(label: String) -> void:
	if focus_receipts.size() >= 128: return
	focus_receipts.append({"label": label, "wall_usec": Time.get_ticks_usec(), "window_has_focus": root.has_focus(), "native_focus": DisplayServer.window_is_focused(root.get_window_id()), "paused": paused, "expected_pause": expected_pause, "action_clock_s": hero.get_world_action_clock() if is_instance_valid(hero) else null})


func _finish() -> void:
	if finishing: return
	finishing = true
	_record_focus("whole-portrait-finish")
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(game):
		var fx: PixelEffects = game.get("fx") as PixelEffects
		if is_instance_valid(fx): fx.clear()
		game.queue_free()
	if is_instance_valid(focus_observer): focus_observer.queue_free()
	paused = false
	await process_frame
	var report: Dictionary = {"scope": "brief actual Main540x1170 whole-court renderer; actual curtain recognizer response unless explicitly representative-only; later native boundaries/birth/contact reached through labelled TEST public injuries/placements; actual unpaused King step and derived summon observed without source/phase/clock writes", "aggregate_api_revision": CourtCodec.API_REVISION, "aggregate_schema_version": CourtCodec.SCHEMA_VERSION, "world_revision": CourtCodec.WORLD_REVISION, "checks": checks, "failures": failures, "first_failure": first_failure, "labelled_test_setups": setups, "cases": scenarios, "representative_only": representative_only, "terminal_views_only": terminal_views_only, "actual_swipes": swipes, "actual_primaries": primaries, "actual_GUI_resumes": gui_resumes, "gesture_unit": gesture_unit, "pause_unit": pause_receipt, "king_intro_original": _portable(king_intro_original), "normal_focus_out_preserved": true, "captures": shots, "focus_receipts": focus_receipts, "input_observations": _portable(input_receipts), "action_receipts": _portable(action_receipts), "hit_receipts": _portable(hit_receipts), "native_events": native_events, "progress_events": progress_events, "observations": observations, "wall_elapsed_ms": Time.get_ticks_msec() - started_ms, "no_claims": ["earned route/kills/contact", "defeat-all", "full natural playthrough", "Save/Continue/Retry", "registered campaign traversal", "portrait fidelity before root image review", "all-kit balance", "performance", "mobile"]}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(report, "\t")); file.close()
	else: checks += 1; failures += 1; push_error("whole portrait report cannot be written")
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L4 WHOLE PORTRAIT: %d checks, %d failures; %d captures; %d real swipes, %d ordinary primaries; report=%s;" % [checks, failures, shots.size(), swipes, primaries, report_path])
	quit(0 if failures == 0 else 1)


func _swipe(direction: Vector3, label: String) -> bool:
	if not await _ready_input(label): return false
	var horizontal := Vector3(direction.x, 0, direction.z).normalized()
	var finish := Vector2(270, 650)
	var delta: Vector2 = _screen_delta(horizontal) * 180.0
	if not _require(_input_safe(finish - delta) and _input_safe(finish) and (game.call("screen_to_direction", delta) as Vector3).dot(horizontal) > 0.9999, label + " uses actual camera axes and literal safe coordinates"): return false
	var sequence: int = _last_sequence()
	var before: Dictionary = game.call("get_input_observation_state")
	var origin: Vector3 = hero.global_position
	var press := InputEventScreenTouch.new()
	press.index = 7; press.pressed = true; press.position = finish - delta
	Input.parse_input_event(press); await process_frame
	if not _guard(): return false
	var drag := InputEventScreenDrag.new()
	drag.index = 7; drag.position = finish; drag.relative = delta
	Input.parse_input_event(drag); await process_frame
	if not _guard(): return false
	var release := InputEventScreenTouch.new()
	release.index = 7; release.position = finish
	Input.parse_input_event(release); await process_frame
	if not _guard(): return false
	swipes += 1
	if not await _ready_input(label + " stopped landing"): return false
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	var observed: Dictionary = game.call("get_input_observation_state")
	var distance: float = float(hero.equipment.resolved_stats().dash_distance)
	var normalized: Vector2 = finish / Vector2(PortraitSize)
	return _require(records.size() == 1 and records[0].kind == "dash" and not records[0].collision_shortened and absf(float(records[0].distance) - distance) <= PositionTolerance and records[0].direction.dot(horizontal) > 0.9999 and Vector2(hero.global_position.x - origin.x, hero.global_position.z - origin.z).length() > distance - PositionTolerance and records[0].landing.distance_to(hero.global_position) <= PositionTolerance and records[0].path.size() >= 2 and observed.sequence == before.sequence + 1 and observed.last_observation.kind == "swipe_release" and observed.anchor_normalized == normalized and game.call("get_aim_anchor_normalized") == normalized, label + " has one full actual world dash and the exact final release anchor")


func _resume_button(node: Node) -> Button:
	if node == null: return null
	if node is Button and (node as Button).is_visible_in_tree() and (node as Button).text.begins_with("RESUME"): return node as Button
	for child: Node in node.get_children():
		var found: Button = _resume_button(child)
		if found != null: return found
	return null


func _screen_delta(direction: Vector3) -> Vector2:
	var camera: Camera3D = game.get("camera") as Camera3D
	var right := Vector3(camera.global_basis.x.x, 0, camera.global_basis.x.z).normalized()
	var down := Vector3(camera.global_basis.z.x, 0, camera.global_basis.z.z).normalized()
	var determinant: float = right.x * down.z - right.z * down.x
	return Vector2((direction.x * down.z - direction.z * down.x) / determinant, (right.x * direction.z - right.z * direction.x) / determinant).normalized()


func _input_safe(point: Vector2) -> bool:
	return point.is_finite() and Rect2(20, 300, 500, 670).has_point(point)


func _last_sequence() -> int:
	var records: Array[Dictionary] = hero.get_world_action_records()
	return 0 if records.is_empty() else int(records.back().sequence)
