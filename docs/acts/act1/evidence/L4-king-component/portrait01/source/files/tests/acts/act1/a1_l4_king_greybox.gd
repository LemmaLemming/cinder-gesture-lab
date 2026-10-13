extends SceneTree
## One B01 native component, actual shared Main/input and exact paused pairs.
## TEST shells=0 occurs only immediately before the real primary. A separate
## public lethal injury exercises retained-source restore, not natural defeat.
## No King phases/helpers/full L4/campaign save/art fidelity/performance claim.

const MainScene = preload("res://scenes/main.tscn")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const C30 = preload("res://scripts/acts/act1/rush_selenite.gd")
const ScenePath: String = "res://scenes/acts/act1/a1_l4_king_greybox.tscn"
const SourceID: String = "a1_l4_greybox_king"
const ActorAPI: String = "act1-selenite-king-native-1"
const PortraitSize := Vector2i(540, 1170)
const PositionTolerance: float = 0.035
const WatchdogMs: int = 70000

var game: Node
var level: CinderLevel
var hero: CinderPlayer
var king: CharacterBody3D
var scheduler: CinderThreatScheduler
var portrait: bool = false
var report_path: String = ""
var capture_dir: String = ""
var checks: int = 0
var failures: int = 0
var events: int = 0
var swipes: int = 0
var primaries: int = 0
var test_lethal_injuries: int = 0
var started_ms: int = 0
var aborted: bool = false
var finishing: bool = false
var expected_pause: bool = false
var phases: Dictionary = {}
var cancellations: Array[Dictionary] = []
var hit_events: Array[Dictionary] = []
var action_events: Array[Dictionary] = []
var input_events: Array[Dictionary] = []
var quiet_units: Array[Dictionary] = []
var malformed_results: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var first_failure: Dictionary = {}
var first_answer: Dictionary = {}
var primary_release_clock_s: float = -1.0
var action_transport: Array[Dictionary] = []
var focus_receipts: Array[Dictionary] = []
var callback_pause_armed: bool = true
var callback_pause_seen: bool = false
var callback_pause_receipt: Dictionary = {}


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	process_frame.connect(_watchdog)
	_run.call_deferred()


func _run() -> void:
	portrait = "--portrait" in OS.get_cmdline_user_args()
	root.size = PortraitSize
	report_path = "res://.cinder/l4-king-greybox-%d.json" % Time.get_ticks_usec()
	if portrait:
		if not _require(DisplayServer.get_name() != "headless", "portrait uses the real graphical renderer") or not await _prepare_focus():
			await _finish(); return
		capture_dir = "res://.cinder/captures/l4-king-%d" % Time.get_ticks_usec()
		if not _require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir)) == OK, "portrait directory is writable"):
			await _finish(); return
	game = MainScene.instantiate()
	game.set("level_scene_path", ScenePath)
	root.add_child(game)
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	if not _require(level != null and hero != null, "King component loads through the actual shared Main shell"):
		await _finish(); return
	king = level.get("king") as CharacterBody3D
	scheduler = level.get("scheduler") as CinderThreatScheduler
	if not _require(king != null and scheduler != null and level.hero == hero and level.level_id == "A1-L4" and level.contract_error().is_empty(), "one shared Hero and actual B01/Scheduler retain the level contract"):
		await _finish(); return
	if not _require(hero.global_position == level.spawn_position() and level.spawn_position() == Vector3(0, 0.1, 3) and king.global_position == Vector3(0, 0.005, 0) and king.get("hp") == 80.0 and not king.get("dead"), "pristine authored spawn/source and live80HP King precede native simulation"):
		await _finish(); return
	if not _require(not level.is_completed() and not game.call("is_lab_level") and level.current_checkpoint() == {"id": "", "kind": ""}, "custom component claims no campaign checkpoint/completion or Character Lab"):
		await _finish(); return
	king.connect("state_changed", _notice_phase)
	king.connect("defeated", func(_id: String) -> void: events += 1)
	king.connect("hit_resolved", func(id: String, cycle: int, result: Dictionary) -> void:
		events += 1
		if result.get("accepted", false): hit_events.append({"hero_id": id, "cycle": cycle, "result": result.duplicate(true)}))
	(king.call("get_cue") as CinderThreatCue).state_changed.connect(func(_s: Dictionary) -> void: events += 1)
	scheduler.reservation_invalidated.connect(func(id: String, reason: String) -> void:
		events += 1
		cancellations.append({"id": id, "reason": reason, "clock_s": scheduler.get_clock()}))
	hero.world_action_executed.connect(func(record: Dictionary) -> void:
		events += 1; action_events.append(record.duplicate(true)))
	hero.fired.connect(func(_kind: String) -> void: events += 1)
	game.connect("input_observed", func(observation: Dictionary) -> void: input_events.append(observation.duplicate(true)))
	_record_focus("before-single-initial-resume")
	game.call("resume_lab") # One initial public resume; later resumes use the GUI.
	if not await _test_callback_pause():
		await _finish(); return
	if not await _wait_phase("warning"):
		await _finish(); return
	first_answer = (level.get("last_admission") as Dictionary).duplicate(true)
	var state: Dictionary = king.call("state")
	if not _require(first_answer.get("accepted") == true and first_answer.get("armed") == true and first_answer.get("reservation_id") == state.reservation_id and first_answer.reservation.source_instance_id == king.get_instance_id() and state.api_revision == ActorAPI and state.role_id == "B01" and state.cycle == callback_pause_receipt.state.cycle + 1 and state.reservation_id != callback_pause_receipt.state.reservation_id and scheduler.get_clock() >= float(callback_pause_receipt.retained_cooldown.ready_s), "new valid B01 warning owns its corroborated lease after the original native cooldown expires"):
		await _finish(); return
	var proof: Dictionary = first_answer.proof.duplicate(true)
	var reservation: Dictionary = first_answer.reservation.duplicate(true)
	if not _require(proof.uses_blast == false and proof.uses_invulnerability == false and reservation.adapter.kind == "lunge" and reservation.adapter.distance == 1.6 and reservation.adapter.speed == 4.0 and state.resolved_role.recovery_s == 2.4 and proof.primary_time_s >= reservation.active_until_s and proof.response_complete_s < reservation.recovery_until_s, "King has its own short1.6@4 lunge and ordinary-only recovery opportunity"):
		await _finish(); return
	if not _framing("warning") or not _art_pose("warning"):
		await _finish(); return
	var warning: Dictionary = await _pair("warning")
	if warning.is_empty() or not await _test_pair(warning) or not await _capture("paused-warning") or not await _gui_resume():
		await _finish(); return
	if not await _capture("warning") or not await _wait_phase("lock") or not _art_pose("lock") or not _framing("lock") or not await _capture("lock"):
		await _finish(); return
	var escape: Vector3 = proof.landing - hero.global_position
	if not _require(absf(Vector2(escape.x, escape.z).length() - float(hero.equipment.resolved_stats().dash_distance)) <= PositionTolerance, "accepted native escape is one complete legal ordinary dash") or not await _swipe(escape, "King escape"):
		await _finish(); return
	if not _require(hero.hp == 100.0 and hit_events.is_empty(), "actual stopped escape takes no native damage") or not _framing("safe landing") or not await _capture("safe-landing") or not await _wait_phase("active") or not _art_pose("active"):
		await _finish(); return
	if not await _capture("active"):
		await _finish(); return
	var active: Dictionary = await _pair("active")
	var live: Dictionary = king.call("state")
	if active.is_empty() or not _require(live.phase == "active" and live.reservation_id == reservation.id and not live.adapter.finished and king.velocity.length() > 0.0, "paused active unit is genuinely unfinished scheduler-owned capsule motion") or not _quiet_restore(active, "active same-unit") or not await _gui_resume():
		await _finish(); return
	if not await _wait_phase("recovery") or not _art_pose("recovery") or not _framing("recovery"):
		await _finish(); return
	if not _require(king.global_position.distance_to(reservation.opening_position) <= Motion.ENDPOINT_TOLERANCE and king.velocity == Vector3.ZERO, "actual King reaches its native stopped opening within the published physical bound") or not await _capture("recovery"):
		await _finish(); return
	var positioning: Vector3 = proof.attack_position - hero.global_position
	positioning.y = 0.0
	if positioning.length() > 0.1 and not await _swipe(positioning, "King return"):
		await _finish(); return
	if not await _wait(func() -> bool: return scheduler.get_clock() >= float(proof.primary_time_s), "retained native primary time is reached", 4.0) or not _framing("primary opening") or not await _capture("primary-opening") or not await _primary(reservation, proof):
		await _finish(); return
	if not _require(king.get("hp") == 60.0 and not king.get("dead") and king.is_in_group("enemies") and hero.hp == 100.0 and hit_events.is_empty(), "one genuine zero-starting-shell20damage primary leaves the same King alive at60HP"):
		await _finish(); return
	var after_hit: Dictionary = scheduler.source_control_state(king)
	if not _require(after_hit.reservations.is_empty() and cancellations.any(func(row: Dictionary) -> bool: return row.id == reservation.id and row.reason == "actual_player_damage") and (after_hit.cooldown == null if scheduler.get_clock() >= float(reservation.cooldown_until_s) else after_hit.cooldown != null and after_hit.cooldown.ready_s == reservation.cooldown_until_s), "real surviving injury cancels its lease and preserves the unexpired native cooldown"):
		await _finish(); return
	for record: Dictionary in hero.get_world_action_records():
		var encoded: Dictionary = CinderPlayer.encode_world_action_record(record, hero.get_world_action_clock())
		if not _require(not encoded.is_empty() and record.kind in ["dash", "primary"], "actual actions retain the exact public transport with no blast"):
			await _finish(); return
		action_transport.append(encoded)
	if not _require(primaries == 1 and swipes >= 1 and action_events.size() == action_transport.size(), "component has one world receipt per genuine action and one ordinary primary"):
		await _finish(); return
	# TEST admission control prevents a new cycle during the separate tombstone
	# restore probe. It changes no existing lease, actor HP, native clock or pose.
	level.set("admission_enabled", false)
	if not await _capture("surviving-primary"):
		await _finish(); return
	print("KING TEST CONTROL: separate public lethal injury after real80->60 primary; no natural boss-defeat claim")
	var injury: Dictionary = king.call("take_damage", 60.0, Vector3.ZERO)
	test_lethal_injuries += 1
	if not _require(injury.get("accepted") == true and injury.hp_damage == 60.0 and king.get("hp") == 0.0 and king.get("dead") and not king.is_in_group("enemies"), "labelled public injury produces a genuine retained dead capsule"):
		await _finish(); return
	# Let ordinary deferred collision flags and the parent presentation complete.
	await process_frame
	await process_frame
	var dead_pair: Dictionary = await _pair("TEST lethal tombstone")
	if dead_pair.is_empty(): await _finish(); return
	var before: Dictionary = _observation()
	var validation: String = level.snapshot_error_with_player(active.level, active.hero)
	if not _require(validation.is_empty() and _observation() == before, "earlier genuine live pair prevalidates against the dead retained body without healing/moving/events") or not _quiet_restore(active, "earlier-live tombstone"):
		await _finish(); return
	if not _require(king.get("hp") == 80.0 and not king.get("dead") and king.is_in_group("enemies") and (king.call("state") as Dictionary).phase == "active", "quiet native restore reconstructs the exact earlier live King rather than respawning") or not _art_pose("active") or not await _gui_resume():
		await _finish(); return
	if not await _wait_phase("recovery") or not _require(king.global_position.distance_to(reservation.opening_position) <= Motion.ENDPOINT_TOLERANCE and hero.hp == 100.0 and hit_events.is_empty(), "resumed earlier native lunge reaches its same opening without redamage") or not await _cleanup():
		await _finish(); return
	await _finish()


func _test_callback_pause() -> bool:
	# TEST fault injection only: the initial real Source Warning observer uses
	# public open_bench once. Observe after the complete start/cancel callback chain,
	# never capture inside it or manufacture a native tick/lease/clock.
	if not await _wait(func() -> bool: return callback_pause_seen and paused and _resume_button(game.get("hud") as Node) != null, "actual initial Warning callback pause reaches the completed shared GUI boundary", 2.0, true): return false
	var answer: Dictionary = level.get("last_admission")
	var control: Dictionary = scheduler.source_control_state(king)
	var state: Dictionary = king.call("pure_presentation_state")
	var pair: Dictionary = {"hero": hero.snapshot_state(), "level": level.snapshot_state()}
	if not _require(answer.get("accepted") == false and not String(answer.get("reason", "")).is_empty() and control.outside_transaction and control.reservations.is_empty() and state.outside_transaction and state.reservation_id == "" and state.phase == "clear" and (king.call("get_cue") as CinderThreatCue).state().phase == "clear", "synchronous callback pause refuses admission and leaves no retained King lease or required hazard"): return false
	if not _require(not pair.hero.is_empty() and not pair.level.is_empty() and pair.level.local.framing_witness.is_empty() and pair.level.local.king.reservation_id == "" and control.cooldown != null and control.cooldown.ready_s == callback_pause_receipt.state.cooldown_until_s and control.clock_s == callback_pause_receipt.clock_s, "post-callback coherent pair has no framing witness and preserves the original native cooldown/clock"): return false
	if not _require(king.get("hp") == 80.0 and not king.get("dead") and hero.hp == 100.0 and hero.get_world_action_records().is_empty() and action_events.is_empty() and input_events.is_empty() and hit_events.is_empty() and swipes == 0 and primaries == 0, "callback pause changes no HP and executes no gesture/action/hit"): return false
	callback_pause_receipt["post_callback_exact_pair"] = Exact.stringify(pair)
	callback_pause_receipt["refusal"] = answer.duplicate(true)
	callback_pause_receipt["retained_cooldown"] = control.cooldown.duplicate(true)
	var before: Dictionary = _observation()
	if not _require(level.snapshot_error_with_player(pair.level, pair.hero).is_empty() and _observation() == before, "post-callback unleased cooldown pair prevalidates purely"): return false
	return await _gui_resume() # No reset/begin/clock write; normal update expires cooldown.


func _pair(label: String) -> Dictionary:
	if not _guard(false): return {}
	expected_pause = true
	if not _require(game.call("request_pause_deferred"), label + " requests the public native-tick pause") or not await _wait(func() -> bool: return paused and _resume_button(game.get("hud") as Node) != null, label + " reaches the actual shared pause GUI", 2.0, true): return {}
	var pair: Dictionary = {"hero": hero.snapshot_state(), "level": level.snapshot_state()}
	if not _require(not pair.hero.is_empty() and not pair.level.is_empty() and not Exact.stringify(pair).is_empty(), label + " captures one coherent exact Player/King/Scheduler unit"):
		print("KING PAIR ERRORS player=", hero.last_snapshot_error, " level=", level.last_snapshot_error, " king=", king.get("last_snapshot_error"), " scheduler=", scheduler.last_snapshot_error)
		return {}
	quiet_units.append({"label": label, "exact_json": Exact.stringify(pair)})
	return pair


func _test_pair(pair: Dictionary) -> bool:
	if not _require(pair.level.local.keys().size() == 3 and pair.level.local.has("scheduler") and pair.level.local.has("king") and pair.level.local.has("framing_witness") and pair.level.local.king.api_revision == ActorAPI and pair.level.local.king.source_id == SourceID and pair.level.local.king.configuration.raw_role.max_hp == 80.0, "paused local schema distinguishes B01 from C30 and retains complete native identity"): return false
	var before: Dictionary = _observation()
	if not _require(level.snapshot_error(pair.level).is_empty() and level.snapshot_error_with_player(pair.level, pair.hero).is_empty() and _observation() == before, "both public pair validators are pure at the native warning barrier"): return false
	if not _test_wrong_pose(pair): return false
	var bad: Dictionary = pair.level.duplicate(true)
	bad.local.framing_witness.clear()
	if not _reject_pair(bad, pair.hero, before, "missing actual landing/opening witness"): return false
	bad = pair.level.duplicate(true); bad.local.king.api_revision = C30.API_REVISION
	if not _reject_pair(bad, pair.hero, before, "cross-C30 API envelope"): return false
	bad = pair.level.duplicate(true); bad.local.king.configuration.lunge = C30.DEFAULT_LUNGE.duplicate(true)
	if not _reject_pair(bad, pair.hero, before, "cross-C30 immutable lunge configuration"): return false
	bad = pair.level.duplicate(true); bad.local.king.source_id = "a1_l2_greybox_rusher"
	if not _reject_pair(bad, pair.hero, before, "different permanent source identity"): return false
	bad = pair.level.duplicate(true); bad.local.scheduler.clock_s += 1.0
	if not _reject_pair(bad, pair.hero, before, "forged paired native clock"): return false
	bad = pair.level.duplicate(true); bad.progress.completed = true; bad.progress.completion_id = "forged-king-completion"
	if not _reject_pair(bad, pair.hero, before, "forged campaign completion"): return false
	bad = pair.level.duplicate(true); bad.progress.checkpoint_id = "forged-king-checkpoint"; bad.progress.checkpoint_kind = "encounter"; bad.progress.checkpoint_ids = {"forged-king-checkpoint": "encounter"}
	if not _reject_pair(bad, pair.hero, before, "forged checkpoint history"): return false
	var until: int = Time.get_ticks_msec() + 120
	while Time.get_ticks_msec() < until and not aborted: await process_frame
	if not _require(_observation() == before, "actual pause freezes exact native clocks/HP/ammo/samples/geometry/cue/input/events"): return false
	return _quiet_restore(pair, "warning")


func _test_wrong_pose(pair: Dictionary) -> bool:
	# A supported art setter can still select the wrong native attack meaning.
	# Observe independent native state while the authored writer correctly denies
	# that presentation. Restore original pixels before reporting any failed check.
	var art: Node3D = king.call("get_art")
	var camera: Camera3D = game.get("camera") as Camera3D
	var actual: Dictionary = king.call("pure_presentation_state")
	var before: Dictionary = _pose_native_observation()
	art.call("set_pose", "recovery", actual.facing, camera)
	var supported: bool = art.call("pose_name") == "recovery" and String(art.call("binding_error")).is_empty()
	var actor_error: String = king.call("art_binding_error")
	var pair_error: String = level.snapshot_error_with_player(pair.level, pair.hero)
	var captured: Dictionary = level.snapshot_state()
	var capture_error: String = level.last_snapshot_error
	var restored: bool = level.restore_state(pair.level)
	var unchanged: bool = _pose_native_observation() == before
	art.call("set_pose", "warning", actual.facing, camera)
	var recovered: bool = String(king.call("art_binding_error")).is_empty() and level.snapshot_error_with_player(pair.level, pair.hero).is_empty() and Exact.stringify({"hero": hero.snapshot_state(), "level": level.snapshot_state()}) == Exact.stringify(pair) and _pose_native_observation() == before
	malformed_results.append({"label": "supported recovery pixels during native warning", "actor_error": actor_error, "pair_error": pair_error, "capture_error": capture_error, "restore_accepted": restored})
	return _require(supported and not actor_error.is_empty() and not pair_error.is_empty() and captured.is_empty() and not capture_error.is_empty() and not restored and unchanged, "supported wrong King pose refuses actor/paired capture/restore without native HP/clock/input/events mutation") and _require(recovered, "supported warning setter restores the exact original native/presentation unit")


func _pose_native_observation() -> Dictionary:
	return {"hero": hero.snapshot_state(), "scheduler": scheduler.snapshot_state(level.call("scheduler_bindings")), "source": (king.call("pure_presentation_state") as Dictionary).duplicate(true), "source_transform": king.global_transform, "source_velocity": king.velocity, "cue": (king.call("get_cue") as CinderThreatCue).state().duplicate(true), "events": events, "input": game.call("get_input_observation_state"), "world_actions": hero.get_world_action_records(), "completed": level.is_completed(), "checkpoint": level.current_checkpoint()}


func _reject_pair(saved: Dictionary, saved_player: Dictionary, before: Dictionary, label: String) -> bool:
	var error: String = level.snapshot_error_with_player(saved, saved_player)
	var accepted: bool = level.restore_state(saved)
	malformed_results.append({"label": label, "error": error, "restore_accepted": accepted})
	return _require(not error.is_empty() and not accepted and _observation() == before, label + " rejects atomically before native/progress/input/events change")


func _quiet_restore(pair: Dictionary, label: String) -> bool:
	var wire: String = Exact.stringify(pair)
	var parsed: Dictionary = Exact.parse(wire)
	if not _require(parsed.get("accepted") == true and Exact.stringify(parsed.value) == wire, label + " whole paired ExactJson transport roundtrips without numeric loss"): return false
	var event_count: int = events
	var input_before: Dictionary = game.call("get_input_observation_state")
	if not _require(hero.restore_state(parsed.value.hero) and level.restore_state(parsed.value.level), label + " quietly commits Player then retained King/Scheduler/exchange"): return false
	var recaptured: Dictionary = {"hero": hero.snapshot_state(), "level": level.snapshot_state()}
	return _require(events == event_count and game.call("get_input_observation_state") == input_before and Exact.stringify(recaptured) == wire, label + " restore emits no action/state/cue callback and reproduces every serialized bit")


func _observation() -> Dictionary:
	return {"hero": hero.snapshot_state(), "level": level.snapshot_state(), "cue": (king.call("get_cue") as CinderThreatCue).state().duplicate(true), "art_pose": (king.call("get_art") as Node).call("pose_name"), "events": events, "input": game.call("get_input_observation_state"), "world_actions": hero.get_world_action_records(), "source_transform": king.global_transform, "source_velocity": king.velocity, "completed": level.is_completed(), "checkpoint": level.current_checkpoint()}


func _gui_resume() -> bool:
	if not _guard(true): return false
	var button: Button = _resume_button(game.get("hud") as Node)
	if not _require(paused and button != null, "actual paused King component exposes shared GUI Resume"): return false
	var before: Dictionary = game.call("get_input_observation_state")
	var records: Array[Dictionary] = hero.get_world_action_records()
	var point: Vector2 = button.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = point; press.global_position = point
	Input.parse_input_event(press)
	await process_frame
	if not _guard(true): return false
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT; release.position = point; release.global_position = point
	Input.parse_input_event(release)
	await process_frame
	expected_pause = false
	_record_focus("after-genuine-gui-resume")
	return _require(not paused and game.call("get_input_observation_state") == before and hero.get_world_action_records() == records, "real GUI press/frame/release/frame resumes without a tap, dash or anchor change") and _guard(false)


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
	if not _guard(false): return false
	var drag := InputEventScreenDrag.new()
	drag.index = 7; drag.position = finish; drag.relative = delta
	Input.parse_input_event(drag); await process_frame
	if not _guard(false): return false
	var release := InputEventScreenTouch.new()
	release.index = 7; release.position = finish
	Input.parse_input_event(release); await process_frame
	if not _guard(false): return false
	swipes += 1
	if not await _ready_input(label + " stopped landing"): return false
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	var observed: Dictionary = game.call("get_input_observation_state")
	var distance: float = float(hero.equipment.resolved_stats().dash_distance)
	var normalized: Vector2 = finish / Vector2(PortraitSize)
	return _require(records.size() == 1 and records[0].kind == "dash" and not records[0].collision_shortened and absf(float(records[0].distance) - distance) <= PositionTolerance and records[0].direction.dot(horizontal) > 0.9999 and Vector2(hero.global_position.x - origin.x, hero.global_position.z - origin.z).length() > distance - PositionTolerance and records[0].landing.distance_to(hero.global_position) <= PositionTolerance and records[0].path.size() >= 2 and observed.sequence == before.sequence + 1 and observed.last_observation.kind == "swipe_release" and observed.anchor_normalized == normalized and game.call("get_aim_anchor_normalized") == normalized, label + " has one full actual world dash and the exact final release anchor")


func _primary(reservation: Dictionary, proof: Dictionary) -> bool:
	if not await _ready_input("King primary"): return false
	var offset: Vector3 = king.global_position - hero.global_position
	offset.y = 0.0
	var direction: Vector3 = offset.normalized()
	var anchor: Vector2 = game.call("get_aim_anchor")
	var anchor_normalized: Vector2 = game.call("get_aim_anchor_normalized")
	var tap: Vector2 = anchor + _screen_delta(direction) * 160.0
	if not _require(king.is_in_group("enemies") and offset.length() < float(hero.equipment.resolved_stats().primary_range) and _input_safe(tap) and (game.call("aim_direction", tap) as Vector3).dot(direction) > 0.9999, "ordinary primary reach and aim derive from the real King and last screen release"): return false
	var sequence: int = _last_sequence()
	var press := InputEventScreenTouch.new()
	press.index = 7; press.pressed = true; press.position = tap
	Input.parse_input_event(press); await process_frame
	if not _guard(false): return false
	var actual: Dictionary = king.call("state")
	if not _require(actual.reservation_id == reservation.id and actual.phase == "recovery" and scheduler.get_clock() >= float(proof.primary_time_s) and scheduler.get_clock() < float(reservation.recovery_until_s), "first-tap release is inside the same genuine native recovery after readiness awaits"): return false
	var release := InputEventScreenTouch.new()
	release.index = 7; release.position = tap
	primary_release_clock_s = scheduler.get_clock()
	hero.shells = 0 # TEST immediate release setup; passive reload remains native.
	Input.parse_input_event(release); await process_frame
	if not _guard(false): return false
	primaries += 1
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	var observed: Dictionary = game.call("get_input_observation_state")
	return _require(records.size() == 1 and records[0].kind == "primary" and records[0].hits == 1 and records[0].direction.dot(direction) > 0.9999 and observed.last_observation.kind == "primary_tap" and observed.last_observation.accepted and observed.last_observation.world_action_sequence == records[0].sequence and game.call("get_aim_anchor_normalized") == anchor_normalized, "real immediate first tap hits B01 with zero starting shells and unchanged release aiming")


func _notice_phase(state: Dictionary) -> void:
	events += 1
	var phase: String = String(state.get("phase", "clear"))
	if state.get("status") != "running" or phase not in ["warning", "lock", "active", "recovery"]: return
	var key: String = "%s/%s" % [state.reservation_id, phase]
	if phases.has(key): return
	var cue: Dictionary = (king.call("get_cue") as CinderThreatCue).state()
	phases[key] = {"source": state.duplicate(true), "clock_s": scheduler.get_clock(), "cue": cue.duplicate(true)}
	_require(cue.phase == phase and cue.geometry == state.geometry and cue.source_position == state.source_position and cue.source_visible and cue.footprint_visible == (phase != "recovery") and cue.active_fill_visible == (phase == "active"), "native " + phase + " cue matches the real King, committed footprint and damage phase")
	if callback_pause_armed and not aborted and phase == "warning":
		callback_pause_armed = false
		callback_pause_seen = true
		expected_pause = true
		callback_pause_receipt = {"scope": "TEST initial Source Warning callback public pause; no accepted baseline attack", "state": state.duplicate(true), "clock_s": scheduler.get_clock(), "hero_hp": hero.hp, "king_hp": king.get("hp")}
		game.call("open_bench")
		_record_focus("initial-warning-public-callback-pause")


func _wait_phase(phase: String) -> bool:
	return await _wait(func() -> bool:
		var state: Dictionary = king.call("state")
		return state.get("phase") == phase and state.get("status") == "running", "observed genuine King " + phase)


func _ready_input(label: String) -> bool:
	return await _wait(func() -> bool:
		var state: Dictionary = hero.get_threat_response_state()
		return state.stable and state.dash_cooldown_left_s == 0.0 and state.primary_cooldown_left_s == 0.0 and state.commitment_remaining_s == 0.0, label + " reaches native input readiness", 4.0)


func _wait(predicate: Callable, label: String, seconds: float = 8.0, allow_pause: bool = false) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while not aborted and not finishing and Time.get_ticks_msec() < deadline:
		if not _guard(allow_pause): return false
		if predicate.call(): return _require(true, label)
		await process_frame
	if aborted or finishing: return false
	return _require(false, label + " within the bounded component window")


func _guard(allow_pause: bool) -> bool:
	if aborted or finishing: return false
	var focused: bool = not portrait or (root.has_focus() and DisplayServer.window_is_focused(root.get_window_id()))
	return _require_unexpected(focused and is_instance_valid(hero) and not hero.dead and (not paused or (allow_pause and expected_pause)), "unexpected focus/pause/Hero death aborts; no forced resumption")


func _framing(label: String) -> bool:
	var points: Array = level.camera_framing_points()
	return _require(not points.is_empty() and points.size() <= 224 and level.last_camera_framing_error.is_empty() and String(game.call("camera_framing_error", points)).is_empty(), label + " retains complete actual King/art/body/lane/landing/opening and Hero framing")


func _art_pose(phase: String) -> bool:
	var art: Node3D = king.call("get_art")
	var camera: Camera3D = game.get("camera") as Camera3D
	if not _require(art != null and art.call("pose_name") == phase and String(art.call("binding_error")).is_empty() and String(king.call("art_binding_error")).is_empty(), "native King " + phase + " selects its distinct retained royal pose"): return false
	var corners: Array = art.call("world_corners", camera)
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for raw: Variant in corners:
		if not raw is Vector3 or not raw.is_finite(): return _require(false, "King full art corners remain finite")
		var projected := Vector2(raw.dot(camera.global_basis.x), raw.dot(camera.global_basis.y))
		low = low.min(projected); high = high.max(projected)
	return _require(corners.size() >= 8 and high.x - low.x >= 1.76 - Motion.EPSILON and high.y - low.y >= 2.112 - Motion.EPSILON, "King geometry keeps the complete80x96/.022 frame including blank margins")


func _prepare_focus() -> bool:
	# One supported TEST foreground request before Main, then real flag observation.
	# Both getters refer to the same native Window flag, not independent evidence.
	DisplayServer.window_move_to_foreground(root.get_window_id())
	var deadline: int = Time.get_ticks_msec() + 4000
	var stable_since: int = -1
	while Time.get_ticks_msec() < deadline and not finishing:
		if root.has_focus() and DisplayServer.window_is_focused(root.get_window_id()):
			if stable_since < 0: stable_since = Time.get_ticks_msec()
			if Time.get_ticks_msec() - stable_since >= 200:
				_record_focus("genuine-startup-focus-stable")
				return _require(true, "portrait observes200ms stable real focus before Main")
		else: stable_since = -1
		await process_frame
	return _require(false, "portrait requires genuine startup focus before gameplay")


func _record_focus(label: String) -> void:
	if not portrait or focus_receipts.size() >= 64: return
	focus_receipts.append({"label": label, "wall_usec": Time.get_ticks_usec(), "window_has_focus": root.has_focus(), "native_focus": DisplayServer.window_is_focused(root.get_window_id()), "paused": paused, "action_clock_s": hero.get_world_action_clock() if is_instance_valid(hero) else null})


func _capture(stage: String) -> bool:
	if not portrait: return not aborted and not finishing
	if not _guard(expected_pause): return false
	await RenderingServer.frame_post_draw
	if not _guard(expected_pause): return false
	var image: Image = root.get_texture().get_image()
	var path: String = capture_dir.path_join("%02d-king-%s.png" % [captures.size() + 1, stage])
	if not _require(image != null and image.get_size() == PortraitSize and image.save_png(path) == OK, "actual540x1170 renderer saves " + stage): return false
	_record_focus("capture/" + stage)
	captures.append({"stage": stage, "path": ProjectSettings.globalize_path(path), "paused": paused, "native_focus": DisplayServer.window_is_focused(root.get_window_id()), "hero_position": _portable(hero.global_position), "king_state": _portable(king.call("pure_presentation_state")), "art_pose": (king.call("get_art") as Node).call("pose_name"), "camera": _portable(game.call("get_camera_framing_state"))})
	return true


func _cleanup() -> bool:
	var descendants: Array[WeakRef] = []
	_retain_descendants(game, descendants)
	level.exit_level()
	if not _require(not king.is_physics_processing() and not king.is_in_group("enemies") and not scheduler.is_physics_processing() and scheduler.source_control_state(king).reservations.is_empty() and level.hero == null and level.shared_shell == null, "public exit disarms the actual King/lease/physics and releases shell aliases"): return false
	var fx: PixelEffects = game.get("fx") as PixelEffects
	if is_instance_valid(fx): fx.clear()
	game.queue_free()
	await process_frame
	for reference: WeakRef in descendants:
		if not _require(reference.get_ref() == null, "normal teardown releases actual descendant identity"): return false
	game = null; level = null; hero = null; king = null; scheduler = null
	return _require(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "disposed King component leaves no enemy or required-cue group")


func _retain_descendants(node: Node, refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child: Node in node.get_children(): _retain_descendants(child, refs)


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
	if not condition:
		failures += 1; aborted = true
		if first_failure.is_empty():
			first_failure = {"label": label, "paused": paused, "native_focus": DisplayServer.window_is_focused(), "king": _portable(king.call("pure_presentation_state")) if is_instance_valid(king) else {}, "last_admission": _portable(level.get("last_admission")) if is_instance_valid(level) else {}, "camera": _portable(game.call("get_camera_framing_state")) if is_instance_valid(game) else {}, "input": _portable(game.call("get_input_observation_state")) if is_instance_valid(game) else {}}
			print("FIRST KING COMPONENT FAILURE ", JSON.stringify(first_failure))
		push_error(label)
	return condition


func _require_unexpected(condition: bool, label: String) -> bool:
	return true if condition else (false if aborted else _require(false, label))


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > WatchdogMs:
		_require_unexpected(false, "King component exits within70wall seconds")
		_finish.call_deferred()


func _finish() -> void:
	if finishing: return
	finishing = true
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(game):
		var fx: PixelEffects = game.get("fx") as PixelEffects
		if is_instance_valid(fx): fx.clear()
		game.queue_free()
	paused = false
	await process_frame
	var report: Dictionary = {"scope": "one actual B01/Standard neutral King component; genuine input/paired native transport/retained capsule; no phases/helpers/natural boss defeat/fullL4/campaignSave/art fidelity/human/balance/performance/mobile claim", "checks": checks, "failures": failures, "actual_swipes": swipes, "actual_primaries": primaries, "labelled_public_lethal_injuries": test_lethal_injuries, "test_ammo_setup": "zero immediately before real primary; passive reload unchanged", "normal_focus_out_preserved": true, "initial_callback_pause_probe": _portable(callback_pause_receipt), "primary_release_clock_s": primary_release_clock_s, "first_failure": first_failure, "first_admission": _portable(first_answer), "native_phases": _portable(phases), "cancellations": cancellations, "native_hit_events": _portable(hit_events), "actual_action_transport_before_quiet_rewind": action_transport, "actual_action_events": _portable(action_events), "input_observations": _portable(input_events), "quiet_units": quiet_units, "malformed_results": malformed_results, "captures": captures, "focus_receipts": focus_receipts}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t")); file.close()
	else:
		checks += 1; failures += 1; push_error("King report cannot be written")
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L4 KING COMPONENT: %d checks, %d failures; %d real swipes, %d ordinary primaries; report=%s; NO FULL-L4 CLAIM" % [checks, failures, swipes, primaries, report_path])
	quit(0 if failures == 0 else 1)
