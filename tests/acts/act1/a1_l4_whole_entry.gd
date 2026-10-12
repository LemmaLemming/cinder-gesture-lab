extends SceneTree
## Focused actual Main custom-scene whole-court progression/entry fixture.
## Every actor injury and Hero relocation is explicit TEST setup. No gesture,
## earned route/kill, campaign registration or whole Save acceptance is claimed.

const MainScene = preload("res://scenes/main.tscn")
const Layout = preload("res://scripts/acts/act1/selenite_court_layout.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const ScenePath: String = "res://scenes/acts/act1/a1_l4.tscn"
const RuntimePath: String = "res://scripts/acts/act1/selenite_court.gd"
const PortraitSize := Vector2i(540, 1170)
const WatchdogMs: int = 70000
const HelperIds: Array[String] = ["court-helper-west", "court-helper-east"]
const ScenarioIds: Array[String] = ["full_entry", "injured_and_blocked_entry", "king_before_entry", "king_during_entry"]

var game: Node
var level: CinderLevel
var hero: CinderPlayer
var scheduler: CinderThreatScheduler
var roundel: CinderLaneMechanism
var sources: Dictionary = {}
var retained: Dictionary = {}
var entry_originals: Dictionary = {}
var scope: String = "startup"
var report_path: String = ""
var checks: int = 0
var failures: int = 0
var started_ms: int = 0
var aborted: bool = false
var finishing: bool = false
var setups: Array[Dictionary] = []
var observations: Array[Dictionary] = []
var progress_events: Array[Dictionary] = []
var native_events: Array[Dictionary] = []
var scenarios: Array[Dictionary] = []
var first_failure: Dictionary = {}
var registry_record: Dictionary = {}


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	process_frame.connect(_watchdog)
	_run.call_deferred()


func _run() -> void:
	root.size = PortraitSize
	report_path = "res://.cinder/a1-l4-whole-entry-%d.json" % Time.get_ticks_usec()
	registry_record = Registry.new().entry("A1-L4")
	print("A1-L4 WHOLE ENTRY TEST SETUP: public take_damage(amount, ZERO) and stationary Hero relocation only; NO EARNED ROUTE, GESTURE, REGISTERED TRANSITION OR SAVE CLAIM")
	for selected: String in ScenarioIds:
		scope = selected
		if not _open() or not await _reach_king(selected == "full_entry"):
			await _finish(); return
		var ok: bool = false
		if selected == "king_before_entry": ok = await _king_before_entry()
		elif selected == "king_during_entry": ok = await _king_during_entry()
		elif selected == "injured_and_blocked_entry": ok = await _injured_and_blocked_entry()
		else: ok = await _full_entry()
		if not ok or not await _contact_exit_and_cleanup():
			await _finish(); return
	await _finish()


func _open() -> bool:
	if not _require(game == null and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "fresh scenario begins after actual prior group cleanup"): return false
	retained.clear(); entry_originals.clear()
	game = MainScene.instantiate()
	game.set("level_scene_path", ScenePath)
	root.add_child(game)
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	if not _require(level != null and hero != null and level.get_script().resource_path == RuntimePath and String(game.get("level_load_error")).is_empty(), "actual Main loads the exact authored whole court script"): return false
	scheduler = level.get("scheduler") as CinderThreatScheduler
	roundel = level.get("roundel") as CinderLaneMechanism
	sources = level.get("sources") as Dictionary
	if not _require(level.level_id == "A1-L4" and level.contract_error().is_empty() and level.hero == hero and level.shared_shell == game and not game.call("is_lab_level") and not level.is_restore_candidate(), "custom court has the actual one-player shared shell contract"): return false
	if not _require(scheduler != null and roundel != null and scheduler.get_parent() == level and roundel.get_parent() == level and _count_type(game, "hero") == 1 and _count_type(game, "scheduler") == 1, "whole scene retains exactly one actual Hero and native Scheduler"): return false
	var floor: CollisionShape3D = level.get_node("Floor/CollisionShape3D") as CollisionShape3D
	if not _require(floor.shape is BoxShape3D and (floor.shape as BoxShape3D).size == Layout.FLOOR_SIZE and floor.get_parent() is StaticBody3D and floor.global_position == Layout.FLOOR_CENTRE and not floor.disabled and (floor.get_parent() as StaticBody3D).collision_layer == 1, "actual continuous14x44 native BOX floor matches the authored world footprint"): return false
	if not _require(sources.size() == 8 and hero.global_position == Layout.SPAWN_POSITION and hero.hp == 100.0 and not hero.dead and level.current_checkpoint() == {"id": "", "kind": ""} and not level.is_completed(), "pristine Main has eight authored identities and no submitted progress"): return false
	for id: String in Layout.SOURCES:
		var actor: CharacterBody3D = sources.get(id) as CharacterBody3D
		if not _require(actor != null and actor.get_parent() == level and actor.name == id and actor.global_position == Layout.SOURCES[id].position, "pristine retained authored source " + id): return false
		retained[id] = actor
		var state: Dictionary = actor.call("pure_presentation_state")
		if not _require(state.source_id == id and state.hp == (80.0 if id == "court-king" else 24.0) and not state.dead and state.cycle == 0 and String(state.reservation_id).is_empty() and state.dormant == (id != "court-curtain-guard") and String(actor.call("art_binding_error")).is_empty(), "full-HP source has its actual pristine native lifecycle/art " + id): return false
		actor.connect("state_changed", Callable(self, "_notice_actor").bind(id))
		actor.connect("defeated", Callable(self, "_notice_defeat"))
	roundel.state_changed.connect(_notice_roundel)
	level.checkpoint_requested.connect(_notice_checkpoint)
	level.completion_requested.connect(_notice_completion)
	level.contact_exit_requested.connect(_notice_contact)
	if not _require(scheduler.encounter_profile().id == "standard" and scheduler.get_clock() == 0.0, "actual default Standard encounter is freshly installed without a second clock"): return false
	game.call("resume_lab") # One public initial preview resume per fresh Main.
	return _require(not paused, "public initial resume exposes normal whole-court physics")


func _reach_king(review_arrangement_and_cancel: bool) -> bool:
	if not await _wait(func() -> bool: return _native_warning("court-curtain-guard"), "initial guard receives its real armed native warning", 4.0): return false
	var initial: Dictionary = scheduler.source_control_state(sources["court-curtain-guard"])
	var lease: Dictionary = initial.reservations[0]
	if not _require(lease.source_instance_id == sources["court-curtain-guard"].get_instance_id() and lease.geometry.kind == "lane" and float(lease.geometry.radius) == 0.38 and not lease.has("adapter") and sources["court-curtain-guard"].velocity == Vector3.ZERO, "native initial C32 lease remains stationary and retains its original lane role"): return false
	_observe("initial-native-admission")
	if not _test_damage("court-curtain-guard", 24.0, "TEST complete entrance boundary") or not await _wait(func() -> bool: return level.current_checkpoint().id == "court-after-curtain", "public defeated curtain requests its actual encounter checkpoint", 2.0): return false
	if not await _test_position(Vector3(0, 0.1, -7), "TEST cross actual formation threshold") or not await _wait(func() -> bool: return int(level.get("room")) == 1, "actual parent threshold enters formation", 2.0): return false
	if review_arrangement_and_cancel:
		var west: CharacterBody3D = sources["court-formation-west"]
		var east: CharacterBody3D = sources["court-formation-east"]
		if not await _wait(func() -> bool: return level.get("formation") == "inward", "same real formation pair completes its first known native arrangements", 7.0): return false
		if not _require(sources["court-formation-west"] == west and sources["court-formation-east"] == east and west.get("hp") == 24.0 and east.get("hp") == 24.0 and int(west.call("pure_presentation_state").cycle) >= 1 and int(east.call("pure_presentation_state").cycle) >= 1, "inward arrangement retains both original bodies, HP and native cycles"): return false
		_observe("same-pair-inward")
	for id: String in Layout.ROOM_SOURCE_IDS[1]:
		if not _test_damage(id, 24.0, "TEST complete formation boundary"): return false
	if not await _wait(func() -> bool: return level.current_checkpoint().id == "court-after-formation", "actual parent requests formation checkpoint", 2.0) or not await _test_position(Vector3(0, 0.1, -17), "TEST cross actual royal-approach threshold"): return false
	if not await _wait(func() -> bool: return int(level.get("room")) == 2 and roundel.state().status == "running", "genuine quiet roundel warning starts before the approach guards", 4.0): return false
	if not _require(sources["court-approach-west"].get("dormant") and sources["court-approach-east"].get("dormant"), "quiet known impact precedes living approach guard activation"): return false
	if review_arrangement_and_cancel:
		var cancelled_cycle: int = int(roundel.state().cycle)
		var before: Dictionary = scheduler.source_control_state(roundel)
		if not _require(before.reservations.size() == 1 and before.cooldown is Dictionary, "real quiet demonstration has its own actual lease/readiness before cancellation"): return false
		setups.append({"scope": scope, "kind": "public_mechanism_cancel", "label": "TEST cancel one actual quiet roundel warning", "cycle": cancelled_cycle, "clock_s": scheduler.get_clock()})
		if not _require(roundel.cancel("TEST_cancel_quiet_warning"), "public TEST roundel cancellation succeeds"): return false
		await process_frame
		if not _guard() or not _require(level.get("_roundel_demonstrated") == false and sources["court-approach-west"].get("dormant") and sources["court-approach-east"].get("dormant") and scheduler.source_control_state(roundel).cooldown == before.cooldown and roundel.state().cycle == cancelled_cycle, "cancelled warning earns no quiet completion or guard birth and retains its real cooldown"): return false
		_observe("quiet-cancellation-not-completion")
	if not await _wait(func() -> bool: return level.get("_roundel_demonstrated") == true and not sources["court-approach-west"].get("dormant") and not sources["court-approach-east"].get("dormant"), "actual completed quiet cycle activates the familiar approach guards", 10.0): return false
	if not _require(_roundel_completed_seen(), "genuine roundel complete event, rather than cancelled status, was observed"): return false
	_observe("native-quiet-demonstration-complete")
	for id: String in Layout.ROOM_SOURCE_IDS[2]:
		if not _test_damage(id, 24.0, "TEST complete approach boundary"): return false
	if not await _wait(func() -> bool: return level.current_checkpoint().id == "court-after-approach", "actual approach checkpoint precedes boss contact", 2.0): return false
	# Approach clearance enables the genuine broad Area; relocation does not call
	# the boss callback or submit a room, phase, checkpoint or activation record.
	if not await _wait(func() -> bool: return (level.get_node("BossContactArea") as Area3D).monitoring, "actual boss contact Area becomes available", 2.0) or not await _test_position(Vector3(0, 0.1, -26), "TEST enter actual boss contact Area"): return false
	if not await _wait(func() -> bool: return int(level.get("room")) == 3 and level.current_checkpoint().id == "court-boss-entry", "genuine contact enters the existing King phase", 2.0): return false
	return _require(not sources["court-king"].get("dormant") and sources["court-king"].get("hp") == 80.0 and level.get("helper_stage") == "unborn" and sources[HelperIds[0]].get("dormant") and sources[HelperIds[1]].get("dormant"), "real King birth precedes its still-unborn retained helper pair")


func _begin_entry() -> bool:
	var epoch: String = String(scheduler.source_control_state(sources["court-king"]).encounter_id)
	var profile: Dictionary = scheduler.encounter_profile()
	var clock: float = scheduler.get_clock()
	if not _test_damage("court-king", 40.0, "TEST phase threshold from80 to40"): return false
	if not await _wait(func() -> bool: return level.get("helper_stage") == "entering" and (level.get("_entry_records") as Dictionary).size() == 2, "actual half-health phase exposes and settles its once-only finite pair", 3.0): return false
	entry_originals = (level.get("_entry_records") as Dictionary).duplicate(true)
	if not _require(int(level.get("room")) == 4 and level.get("_helpers_once") == true and epoch == "court-king" and scheduler.source_control_state(sources[HelperIds[0]]).encounter_id == epoch and scheduler.encounter_profile() == profile and scheduler.get_clock() >= clock, "phase entry retains the original King epoch/profile and monotonically advancing shared clock"): return false
	for id: String in HelperIds:
		var actor: CharacterBody3D = sources[id]
		var record: Dictionary = entry_originals[id]
		var control: Dictionary = scheduler.source_control_state(actor)
		if not _require(actor == retained[id] and not actor.get("dormant") and actor.get("hp") == 24.0 and not actor.get("dead") and control.reservations.is_empty() and control.cooldown == null and int(actor.call("pure_presentation_state").cycle) == 0, "once-born helper has no invented lease, cooldown or combat history " + id): return false
		if not _require(record.keys().size() == 6 and record.active == true and record.from is Vector3 and record.to == record.from + Vector3.BACK * 0.7 and record.speed == 1.4 and record.end_s == record.start_s + 0.5 and record.start_s >= clock, "parent records the original fixed half-second native entry " + id): return false
	_observe("once-entry-start")
	return true


func _full_entry() -> bool:
	if not await _begin_entry(): return false
	if not await _wait(func() -> bool: return _helpers_moving(), "both helpers visibly move through native nonattack entry", 0.45): return false
	_observe("actual-finite-entry-motion")
	if not await _wait(func() -> bool: return level.get("helper_stage") == "done", "original finite helper entry stops and reaches its phase boundary", 2.0): return false
	var outcomes: Dictionary = level.get("_entry_outcomes")
	for id: String in HelperIds:
		var actor: CharacterBody3D = sources[id]
		var original: Dictionary = entry_originals[id]
		if not _require(outcomes.has(id) and outcomes[id].outcome == "complete" and actor.velocity == Vector3.ZERO and _planar_distance(actor.global_position, original.to) <= Motion.ENDPOINT_TOLERANCE and scheduler.get_clock() >= float(original.end_s), "actual complete entry has its stopped endpoint and original deadline " + id): return false
	if not _entry_history_unchanged() or not _require(level.current_checkpoint().id == "court-king-phase-two", "actual entry completion requests the phase checkpoint"): return false
	for id: String in HelperIds:
		var actor: CharacterBody3D = sources[id]
		var before: Dictionary = actor.call("pure_presentation_state")
		var control: Dictionary = scheduler.source_control_state(actor)
		if not _require(actor.call("activate_court_entry", level, "court-king") == false and actor.call("pure_presentation_state") == before and scheduler.source_control_state(actor) == control, "repeated helper birth is rejected without native state/readiness mutation " + id): return false
	if not _test_damage(HelperIds[0], 24.0, "TEST defeat one finite helper after full entry") or not await _test_position(Vector3(0, 0.1, -28.2), "TEST observe remaining learned helper threat"): return false
	if not await _wait(func() -> bool: return int(sources[HelperIds[1]].call("pure_presentation_state").cycle) > 0, "the same remaining guard can admit its learned thrust", 4.0): return false
	if not await _no_replacement() or not _test_damage("court-king", float(sources["court-king"].get("hp")), "TEST terminal King injury after full entry"): return false
	return await _wait(func() -> bool: return level.is_completed(), "King defeat completes the full-entry parent", 2.0)


func _injured_and_blocked_entry() -> bool:
	if not await _begin_entry() or not await _wait(func() -> bool: return _helpers_moving(), "real entry has begun before injury/block setup", 0.45): return false
	if not _test_damage(HelperIds[0], 20.0, "TEST nonlethal helper injury during native entry"): return false
	var east: CharacterBody3D = sources[HelperIds[1]]
	var goal: Vector3 = entry_originals[HelperIds[1]].to
	var blocker := Vector3(east.global_position.x, 0.1, minf(east.global_position.z + 0.15, goal.z - 0.05))
	var occupied: Dictionary = Geometry.lane(east.global_position, goal, 0.32)
	if not _require(Geometry.segment_hits(occupied, blocker, blocker, CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN), "labelled Hero blocker occupies the actual remaining native helper corridor"): return false
	if not await _test_position(blocker, "TEST Hero occupies remaining east helper corridor"): return false
	if not await _wait(func() -> bool: return level.get("helper_stage") == "done", "injury and occupied corridor terminate entry without a stalled phase", 2.0): return false
	var outcomes: Dictionary = level.get("_entry_outcomes")
	if not _require(outcomes.get(HelperIds[0], {}).get("outcome") == "injured" and outcomes.get(HelperIds[1], {}).get("outcome") == "blocked" and sources[HelperIds[0]].get("hp") == 4.0 and east.get("hp") == 24.0 and east.velocity == Vector3.ZERO and _planar_distance(east.global_position, goal) > Motion.ENDPOINT_TOLERANCE, "real injured HP and shortened blocked endpoint are retained without a full-entry fiction"): return false
	if not _entry_history_unchanged(): return false
	_observe("real-injured-and-blocked-outcomes")
	if not await _test_position(Vector3(0, 0.1, -28.2), "TEST leave occupied corridor for native settling") or not _test_damage(HelperIds[0], 4.0, "TEST defeat the previously injured helper"): return false
	if not await _no_replacement() or not _test_damage("court-king", float(sources["court-king"].get("hp")), "TEST terminal King injury after shortened entry"): return false
	return await _wait(func() -> bool: return level.is_completed(), "shortened entry still permits actual parent completion", 2.0)


func _king_before_entry() -> bool:
	if not _test_damage("court-king", 80.0, "TEST King defeat before phase-two helper birth") or not await _wait(func() -> bool: return level.is_completed(), "King defeat before helper birth cannot stall completion", 2.0): return false
	if not _require(level.get("helper_stage") == "unborn" and level.get("_helpers_once") == false and (level.get("_entry_records") as Dictionary).is_empty(), "pre-entry defeat does not invent the finite pair's birth/history"): return false
	for id: String in HelperIds:
		if not _require(sources[id] == retained[id] and sources[id].get("dormant") and sources[id].get("hp") == 24.0, "unborn helper remains the same pristine dormant identity " + id): return false
	_observe("king-defeated-before-entry")
	return true


func _king_during_entry() -> bool:
	if not await _begin_entry() or not await _wait(func() -> bool: return _helpers_moving(), "finite pair is genuinely moving before terminal King injury", 0.45): return false
	if not _test_damage("court-king", 40.0, "TEST King defeat during actual finite helper motion") or not await _wait(func() -> bool: return level.is_completed(), "King defeat during entry stops its own helper motion and completes", 2.0): return false
	var outcomes: Dictionary = level.get("_entry_outcomes")
	for id: String in HelperIds:
		var actor: CharacterBody3D = sources[id]
		if not _require(outcomes.get(id, {}).get("outcome") == "king_defeated" and actor == retained[id] and actor.get("hp") == 24.0 and not actor.get("dead") and actor.velocity == Vector3.ZERO and _planar_distance(actor.global_position, entry_originals[id].to) > Motion.ENDPOINT_TOLERANCE, "King terminal event retains the actual shortened living helper " + id): return false
	if not _entry_history_unchanged(): return false
	_observe("king-defeated-during-real-entry")
	return true


func _helpers_moving() -> bool:
	if level.get("helper_stage") != "entering": return false
	for id: String in HelperIds:
		if sources[id].velocity.z <= 0.0 or sources[id].global_position.z <= (entry_originals[id].from as Vector3).z + Motion.EPSILON: return false
	return true


func _planar_distance(left: Vector3, right: Vector3) -> float:
	return Vector2(left.x - right.x, left.z - right.z).length()


func _entry_history_unchanged() -> bool:
	return _require(var_to_bytes(level.get("_entry_records")) == var_to_bytes(entry_originals) and _retained_identities(), "outcomes preserve the original six-key paths/deadlines and all eight source handles")


func _no_replacement() -> bool:
	var until: float = scheduler.get_clock() + 0.25
	# .25 native seconds is a functional observation, not a 1s wall-performance
	# promise on this shared Mac. Keep native duration and the 70s global cap.
	if not await _wait(func() -> bool: return scheduler.get_clock() >= until, "ordinary shared clock advances after helper defeat", 3.0): return false
	return _require(_retained_identities() and sources[HelperIds[0]].get("dead") and sources[HelperIds[0]].get("hp") == 0.0 and not sources[HelperIds[0]].is_in_group("enemies") and scheduler.source_control_state(sources[HelperIds[0]]).reservations.is_empty() and scheduler.source_control_state(sources[HelperIds[0]]).cooldown == null and level.get("_helpers_once") == true, "defeated helper remains defeated without replacement, new identity or owner cooldown")


func _test_damage(id: String, amount: float, label: String) -> bool:
	if not _guard(): return false
	var actor: CharacterBody3D = sources[id]
	var before: float = float(actor.get("hp"))
	var result: Dictionary = actor.call("take_damage", amount, Vector3.ZERO)
	setups.append({"scope": scope, "kind": "public_actor_damage", "label": label, "source_id": id, "amount": amount, "impulse": [0, 0, 0], "before_hp": before, "after_hp": actor.get("hp"), "clock_s": scheduler.get_clock(), "result": _portable(result)})
	return _require(result.get("accepted") == true and actor == retained[id] and float(actor.get("hp")) == maxf(0.0, before - amount) and float(result.get("hp_damage", -1.0)) == minf(before, amount), label + " uses the actual public native injury path")


func _test_position(position: Vector3, label: String) -> bool:
	if not await _wait(func() -> bool: return hero.get_threat_response_state().stable and hero.velocity == Vector3.ZERO, "TEST relocation starts from the actual stopped living Hero", 2.0): return false
	if not _require(Layout.SAFE_RECT.has_point(Vector2(position.x, position.z)), label + " remains on supported authored floor"): return false
	var before: Vector3 = hero.global_position
	hero.global_position = position # Explicit TEST setup only; no room/timer edits.
	setups.append({"scope": scope, "kind": "hero_position", "label": label, "from": _portable(before), "to": _portable(position), "clock_s": scheduler.get_clock(), "hp": hero.hp})
	return await _wait(func() -> bool: return hero.get_threat_response_state().stable, "actual native floor settles after labelled Hero placement", 2.0)


func _native_warning(id: String) -> bool:
	var actor: CharacterBody3D = sources[id]
	var state: Dictionary = actor.call("pure_presentation_state")
	var control: Dictionary = scheduler.source_control_state(actor)
	return state.phase == "warning" and state.cycle > 0 and not String(state.reservation_id).is_empty() and control.reservations.size() == 1 and control.reservations[0].id == state.reservation_id and control.reservations[0].armed == true


func _roundel_completed_seen() -> bool:
	for item: Dictionary in native_events:
		if item.scope == scope and item.kind == "roundel" and item.state.status == "complete": return true
	return false


func _retained_identities() -> bool:
	if sources.size() != 8: return false
	for id: String in retained:
		if sources.get(id) != retained[id] or not is_instance_valid(retained[id]) or retained[id].get_parent() != level: return false
	return true


func _notice_actor(state: Dictionary, id: String) -> void:
	if native_events.size() < 512:
		native_events.append({"scope": scope, "kind": "actor", "id": id, "state": _portable(state), "clock_s": scheduler.get_clock()})


func _notice_defeat(id: String) -> void:
	if native_events.size() < 512: native_events.append({"scope": scope, "kind": "defeat", "id": id, "clock_s": scheduler.get_clock()})


func _notice_roundel(state: Dictionary) -> void:
	if native_events.size() < 512: native_events.append({"scope": scope, "kind": "roundel", "state": _portable(state), "clock_s": scheduler.get_clock()})


func _notice_checkpoint(id: String, checkpoint: String, kind: String) -> void:
	progress_events.append({"scope": scope, "kind": "checkpoint", "level_id": id, "id": checkpoint, "boundary_kind": kind})


func _notice_completion(id: String, completion: String) -> void:
	progress_events.append({"scope": scope, "kind": "completion", "level_id": id, "id": completion})


func _notice_contact(id: String, contact: String) -> void:
	progress_events.append({"scope": scope, "kind": "contact", "level_id": id, "id": contact})


func _event_count(kind: String) -> int:
	var result: int = 0
	for item: Dictionary in progress_events:
		if item.scope == scope and item.kind == kind: result += 1
	return result


func _observe(label: String) -> void:
	var states: Dictionary = {}
	for id: String in sources: states[id] = sources[id].call("pure_presentation_state")
	observations.append({"scope": scope, "label": label, "room": level.get("room"), "formation": level.get("formation"), "helper_stage": level.get("helper_stage"), "clock_s": scheduler.get_clock(), "profile": scheduler.encounter_profile(), "hero_position": _portable(hero.global_position), "hero_hp": hero.hp, "sources": _portable(states), "entry_records": _portable(level.get("_entry_records")), "entry_outcomes": _portable(level.get("_entry_outcomes")), "completed": level.is_completed()})


func _contact_exit_and_cleanup() -> bool:
	if not _require(level.is_completed() and _event_count("completion") == 1 and scheduler.encounter_profile().is_empty(), "one native completion retires the King epoch"): return false
	if not await _wait(func() -> bool: return (level.get_node("ExitArea") as Area3D).monitoring, "deferred native contact exit becomes available", 2.0): return false
	if not await _test_position(Vector3(0, 0.1, -35), "TEST cross actual exterior contact Area") or not await _wait(func() -> bool: return _event_count("contact") == 1, "actual contact emits the declared exterior exit request", 2.0): return false
	if not _require(level.get("_contact_exit_id") == "court-exterior" and _event_count("completion") == 1 and _retained_identities(), "contact remains distinct and preserves the original finite cast"): return false
	_observe("actual-contact-before-disposal")
	scenarios.append({"scope": scope, "result": "focused_sequence_complete", "completion_events": _event_count("completion"), "contact_events": _event_count("contact"), "checkpoint_events": _event_count("checkpoint"), "stage_observations": _scope_observations()})
	var refs: Array[WeakRef] = []
	_retain_descendants(game, refs)
	level.exit_level()
	if not _require(level.hero == null and level.shared_shell == null and not level.is_physics_processing() and not scheduler.is_physics_processing() and not roundel.is_physics_processing(), "public level exit stops actual owner/roundel/Scheduler physics and releases aliases"): return false
	for id: String in sources:
		if not _require(not sources[id].is_physics_processing() and not sources[id].is_in_group("enemies") and scheduler.source_control_state(sources[id]).reservations.is_empty(), "public exit disarms retained source " + id): return false
	var fx: PixelEffects = game.get("fx") as PixelEffects
	if fx != null: fx.clear()
	game.queue_free()
	await process_frame
	for ref: WeakRef in refs:
		if not _require(ref.get_ref() == null, "ordinary queued disposal releases retained descendant"): return false
	game = null; level = null; hero = null; scheduler = null; roundel = null
	sources.clear(); retained.clear(); entry_originals.clear()
	return _require(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "actual court teardown leaves no enemies or required cues")


func _scope_observations() -> Array:
	var selected: Array = []
	for observation: Dictionary in observations:
		if observation.scope == scope: selected.append(observation.duplicate(true))
	return selected


func _count_type(node: Node, kind: String) -> int:
	var result: int = 1 if (kind == "hero" and node is CinderPlayer) or (kind == "scheduler" and node is CinderThreatScheduler) else 0
	for child: Node in node.get_children(): result += _count_type(child, kind)
	return result


func _retain_descendants(node: Node, refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child: Node in node.get_children(): _retain_descendants(child, refs)


func _wait(predicate: Callable, label: String, seconds: float) -> bool:
	var deadline: int = mini(started_ms + WatchdogMs, Time.get_ticks_msec() + int(seconds * 1000.0))
	while not aborted and not finishing and Time.get_ticks_msec() < deadline:
		if not _guard(): return false
		if predicate.call(): return _require(true, label)
		await process_frame
	return false if aborted or finishing else _require(false, label + " within focused bounded window")


func _guard() -> bool:
	if aborted or finishing: return false
	return true if is_instance_valid(level) and is_instance_valid(hero) and is_instance_valid(scheduler) and not hero.dead and not paused and level.contract_error().is_empty() else _require(false, "unexpected pause, Hero death, native alias loss or actual court contract failure")


func _portable(value: Variant) -> Variant:
	if value is Vector3: return [value.x, value.y, value.z]
	if value is Vector2: return [value.x, value.y]
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_portable(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _portable(value[key])
		return result
	if value is Object: return "native object omitted: " + value.get_class()
	return value


func _require(condition: bool, label: String) -> bool:
	checks += 1
	if condition: return true
	failures += 1; aborted = true
	if first_failure.is_empty():
		first_failure = {"scope": scope, "label": label, "paused": paused, "room": level.get("room") if is_instance_valid(level) else null, "helper_stage": level.get("helper_stage") if is_instance_valid(level) else null, "contract_error": level.contract_error() if is_instance_valid(level) else "missing level", "clock_s": scheduler.get_clock() if is_instance_valid(scheduler) else null, "camera": _portable(game.call("get_camera_framing_state")) if is_instance_valid(game) else {}, "entry_records": _portable(level.get("_entry_records")) if is_instance_valid(level) else {}, "entry_outcomes": _portable(level.get("_entry_outcomes")) if is_instance_valid(level) else {}, "entry_stop_diagnostics": _portable(level.get("entry_stop_diagnostics")) if is_instance_valid(level) else {}}
		print("FIRST WHOLE COURT ENTRY FAILURE ", JSON.stringify(first_failure))
	push_error(label)
	return false


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > WatchdogMs:
		if not aborted: _require(false, "whole court focused fixture closes within70wall seconds")
		_finish.call_deferred()


func _finish() -> void:
	if finishing: return
	finishing = true
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(game):
		var fx: PixelEffects = game.get("fx") as PixelEffects
		if fx != null: fx.clear()
		game.queue_free()
	paused = false
	await process_frame
	var report: Dictionary = {"scope": "actual Main custom whole-court preview; eight retained actors/continuous floor/native admissions/finite entry/real completion/contact/disposal; all damage and relocation explicitly TEST", "no_claims": ["earned route", "natural boss defeat", "genuine gesture attacks", "whole Save/Continue/Retry", "registered campaign transitions", "art/portrait fidelity", "all-kit balance", "performance", "mobile"], "checks": checks, "failures": failures, "cases": scenarios, "registry_record": registry_record, "first_failure": first_failure, "labelled_test_setups": setups, "observations": observations, "native_events": native_events, "progress_events": progress_events, "wall_elapsed_ms": Time.get_ticks_msec() - started_ms}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(report, "\t")); file.close()
	else: checks += 1; failures += 1; push_error("Whole court entry report cannot be written")
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L4 WHOLE ENTRY: %d checks, %d failures; report=%s;" % [checks, failures, report_path])
	quit(0 if failures == 0 else 1)
