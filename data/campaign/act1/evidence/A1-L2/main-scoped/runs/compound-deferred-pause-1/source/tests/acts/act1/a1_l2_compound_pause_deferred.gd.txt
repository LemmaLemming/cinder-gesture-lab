extends SceneTree
## Separate shared23 deferred-pause regression. The original direct tree-pause
## fixture and its 17/2 result remain unchanged. Hero approaches are explicitly
## staged on real floor; landing resolution, zero-ammo solo input, compound
## admission, native ticks and presentation are genuine. No sample/pose repair.

const MainScene = preload("res://scenes/main.tscn")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Layout = preload("res://scripts/acts/act1/crater_gardens_layout.gd")
const LEVEL_PATH: String = "res://scenes/acts/act1/a1_l2.tscn"
var game: Node
var level: CinderLevel
var hero: CinderPlayer
var scheduler: CinderThreatScheduler
var source: Act1RushSelenite
var circle: CinderLaneMechanism
var checks: int = 0
var failures: int = 0
var events: int = 0
var finishing: bool = false
var watching: bool = false
var intercepted: bool = false
var inside_capture_rejected: bool = false
var request_accepted: bool = false
var duplicate_accepted: bool = false
var pending_after_resume: bool = false
var unpaused_in_callback: bool = false
var pending_input_consumed: bool = false
var intercepted_phase: String = ""
var callback_clock_s: float = 0.0
var callback_hp: float = 0.0
var callback_shells: int = 0
var callback_sequence: int = 0
var callback_anchor: Vector2
var callback_input_state: Dictionary = {}
var no_ammo_primary: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(35.0, true).timeout.connect(func() -> void:
		if not finishing:
			_diagnose_setup("watchdog")
			_expect(false, "bounded deferred compound fixture completes within35 seconds")
			_finish())
	root.size = Vector2i(540, 1170)
	game = MainScene.instantiate()
	game.set("level_scene_path", LEVEL_PATH)
	root.add_child(game)
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	if not _expect(level != null and hero != null and level.hero == hero and level.scene_file_path == LEVEL_PATH and level.contract_error().is_empty(), "actual Main L2 enters with one shared Player"):
		_finish(); return
	game.call("resume_lab")
	if not _expect(await _wait_for(func() -> bool: return level.get("beat_index") == 1, 800), "real native landing resolves before the solo boundary"):
		_diagnose_setup("landing"); _finish(); return
	var sources: Dictionary = level.get("sources")
	var solo: Act1RushSelenite = sources["solo"]
	# Test approach staging only. Neither encounter phase nor sample is set.
	_stage_approach(Vector3(0, 0.005, 9.5))
	game.call("resume_lab")
	if not _expect(await _wait_for(func() -> bool: return not solo.dormant, 200), "actual solo activates at its authored boundary"):
		_diagnose_setup("solo activation"); _finish(); return
	var sequence: int = _last_action_sequence()
	if not _send_solo_primary():
		_finish(); return
	if not _expect(await _wait_for(func() -> bool: return solo.dead and level.get("beat_index") == 2, 200), "one genuine ordinary primary clears the solo and establishes the fork"):
		_diagnose_setup("solo primary"); _finish(); return
	var actions: Array[Dictionary] = hero.get_world_action_records(sequence)
	_expect(actions.size() == 1 and actions[0].kind == "primary" and actions[0].hits == 1 and no_ammo_primary, "actual first-tap solo primary starts with zero shells and publishes once")
	scheduler = level.get("scheduler") as CinderThreatScheduler
	source = sources["open"]
	circle = (level.get("circles") as Dictionary)["open-impact"]
	source.state_changed.connect(_request_pause_from_source)
	# Explicit fixture floor approach, matching the original narrow repro.
	_stage_approach(Layout.OPEN_SOURCE + Vector3.BACK * 3.0)
	game.call("resume_lab")
	if not _expect(await _wait_for(func() -> bool: return level.get("chosen_route") == "open" and level.get("encounter_started") and not source.dormant, 200), "native Main chooses and activates the real open compound approach"):
		_diagnose_setup("open activation"); _finish(); return
	if not _expect(await _wait_for(func() -> bool: return not source.state().reservation_id.is_empty() and circle.state().status == "running", 450), "actual C30 and companion circle are naturally admitted together"):
		_diagnose_setup("compound admission"); _finish(); return
	# Public ordinary pause after a completed frame, not inside an observer.
	game.call("open_bench")
	await process_frame
	var before: Dictionary = _pair()
	if not _expect(not before.player.is_empty() and not before.level.is_empty(), "ordinary completed-frame compound capture is initially valid: " + level.last_snapshot_error):
		_diagnose_setup("ordinary compound capture"); _finish(); return
	_expect(before.level.local.sources.open.sample.clock_s == before.level.local.scheduler.clock_s and before.level.local.circles["open-impact"].hero_samples.hero.clock_s == before.level.local.scheduler.clock_s, "both native consumers initially retain the same exact tick")
	_watch_events()
	watching = true
	game.call("resume_lab")
	if not _expect(await _wait_for(func() -> bool: return intercepted and paused and not bool(game.call("is_pause_requested")), 450), "early source callback requests one completed-tick public pause"):
		_diagnose_setup("deferred phase observer"); _finish(); return
	await process_frame
	_expect(request_accepted and not duplicate_accepted and pending_after_resume and unpaused_in_callback, "public request coalesces; early Resume retains pending pause and leaves later native consumers running")
	_expect(inside_capture_rejected and intercepted_phase in ["lock", "active", "recovery"], "capture inside the originating live native callback remains unavailable")
	_expect(pending_input_consumed and _last_action_sequence() == callback_sequence and game.call("get_aim_anchor") == callback_anchor and game.call("get_input_observation_state") == callback_input_state, "real recognizer swipe is consumed immediately without action or anchor/observer publication")
	await _assert_deferred_capture()
	_finish()


func _request_pause_from_source(state: Dictionary) -> void:
	if not watching or intercepted or state.phase not in ["lock", "active", "recovery"] or circle.state().status != "running": return
	intercepted = true
	intercepted_phase = String(state.phase)
	callback_clock_s = scheduler.get_clock()
	# Resources are observed here, after real passive reload, never assumed to
	# remain the initial zero-ammo value throughout the warning interval.
	callback_hp = hero.hp
	callback_shells = hero.shells
	callback_sequence = _last_action_sequence()
	callback_anchor = game.call("get_aim_anchor")
	callback_input_state = game.call("get_input_observation_state")
	request_accepted = bool(game.call("request_pause_deferred"))
	duplicate_accepted = bool(game.call("request_pause_deferred"))
	game.call("resume_lab")
	pending_after_resume = bool(game.call("is_pause_requested"))
	unpaused_in_callback = not paused
	_send_pending_swipe()
	pending_input_consumed = _last_action_sequence() == callback_sequence and game.call("get_aim_anchor") == callback_anchor and game.call("get_input_observation_state") == callback_input_state
	inside_capture_rejected = level.snapshot_state().is_empty()


func _assert_deferred_capture() -> void:
	var bindings: Dictionary = level.call("scheduler_bindings")
	var player: Dictionary = hero.snapshot_state()
	var paired: Dictionary = scheduler.snapshot_state(bindings)
	var saved_source: Dictionary = source.snapshot_state(paired) if not paired.is_empty() else {}
	var source_error: String = source.last_snapshot_error
	var saved_circle: Dictionary = circle.snapshot_state(bindings)
	var circle_error: String = circle.last_snapshot_error
	var saved_level: Dictionary = level.snapshot_state()
	var level_error: String = level.last_snapshot_error
	var state: Dictionary = circle.state()
	var puff := circle.get_node("SquareImpactFragments") as MeshInstance3D
	var diagnostic: Dictionary = {"phase": intercepted_phase, "callback_clock_s": callback_clock_s, "callback_hp": callback_hp, "callback_shells": callback_shells, "source_tree_index": source.get_index(), "circle_tree_index": circle.get_index(), "source_physics_priority": source.process_physics_priority, "circle_physics_priority": circle.process_physics_priority, "request_accepted": request_accepted, "duplicate_accepted": duplicate_accepted, "pending_after_resume": pending_after_resume, "unpaused_in_callback": unpaused_in_callback, "pending_input_consumed": pending_input_consumed, "player": player, "scheduler": paired, "source": saved_source, "circle": saved_circle, "level": saved_level, "source_error": source_error, "circle_error": circle_error, "level_error": level_error, "level_capture_error": String(level.get("last_capture_error")), "circle_public_state": {"status": String(state.status), "phase": String(state.phase), "cycle": state.cycle, "reservation_id": String(state.reservation_id), "source_position": Codec.vector3(state.source_position), "hit_ids": state.hit_ids}, "source_pose": String(source.get_art().call("pose_name")), "puff_visible": puff.visible, "puff_basis": [Codec.vector3(puff.basis.x), Codec.vector3(puff.basis.y), Codec.vector3(puff.basis.z)]}
	var diagnostic_wire: String = Exact.stringify(diagnostic)
	print("COMPOUND DEFERRED PAUSE DIAGNOSTIC ", diagnostic_wire)
	_expect(not diagnostic_wire.is_empty(), "bounded native compound diagnostic transports without unsupported values")
	if not _expect(not player.is_empty() and not paired.is_empty() and paired.clock_s == callback_clock_s, "completed deferred pause freezes the same actual Player and callback scheduler tick"):
		return
	_expect(player.resources.hp == callback_hp and player.resources.shells == callback_shells and not player.resources.dead, "deferred boundary retains actual injury and ammo without healing/refill or an extra tick")
	if _expect(not saved_source.is_empty(), "originating C30 finishes its actual native sample/path before pause: " + source_error):
		_expect(saved_source.sample.clock_s == paired.clock_s and saved_source.sample.hero_position == player.motion.position and saved_source.sample.source_position == saved_source.motion.position, "originating source retains exact current saved actor/scheduler endpoints")
	if _expect(not saved_circle.is_empty(), "later native companion completes the same tick before pause: " + circle_error):
		_expect(saved_circle.hero_samples.hero.clock_s == paired.clock_s and saved_circle.hero_samples.hero.position == player.motion.position, "later companion's saved sample is the exact same Player/tick")
	_expect(source.art_binding_error().is_empty() and String(circle.get_cue().state().phase) == String(state.phase) and puff.visible == (state.phase == "active"), "late Main and native consumers retain truthful source art, cue and puff presentation")
	if not _expect(not saved_level.is_empty(), "whole compound Level captures after late-parent presentation without repair: " + level_error):
		return
	var saved: Dictionary = {"player": player, "level": saved_level}
	var wire: String = Exact.stringify(saved)
	var identities: Dictionary = _identities()
	var before_events: int = events
	_expect(hero.snapshot_error(player).is_empty() and level.snapshot_error_with_player(saved_level, player).is_empty() and Exact.stringify(_pair()) == wire and events == before_events, "aggregate actor-context prevalidation is pure and preserves actual resources/presentation")
	var decoded: Dictionary = Exact.parse(wire)
	if not _expect(not wire.is_empty() and decoded.get("accepted", false) and Exact.stringify(decoded.value) == wire, "complete native paired envelopes preserve every bit through ExactJson"):
		return
	var restored: bool = _restore_pair(decoded.value)
	_expect(restored and Exact.stringify(_pair()) == wire and _identities() == identities and events == before_events and _last_action_sequence() == callback_sequence, "public paired restore is exact and quiet with the same retained native resources")
	await create_timer(0.08, true).timeout
	_expect(paused and not bool(game.call("is_pause_requested")) and Exact.stringify(_pair()) == wire and _identities() == identities and events == before_events, "held completed pause keeps all native clocks, resources and presentation exact")


func _watch_events() -> void:
	hero.fired.connect(func(_kind: String) -> void: events += 1)
	hero.died.connect(func() -> void: events += 1)
	hero.equipment_changed.connect(func(_id: String) -> void: events += 1)
	hero.action_resolved.connect(func(_kind: String, _hits: int, _damage: float) -> void: events += 1)
	hero.world_action_executed.connect(func(_record: Dictionary) -> void: events += 1)
	scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: events += 1)
	level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: events += 1)
	level.completion_requested.connect(func(_id: String, _completion: String) -> void: events += 1)
	level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: events += 1)
	for collection: String in ["sources", "circles"]:
		for actor: Node in (level.get(collection) as Dictionary).values():
			actor.connect("state_changed", func(_state: Dictionary) -> void: events += 1)
			var cue: CinderThreatCue = actor.call("get_cue") as CinderThreatCue
			cue.state_changed.connect(func(_state: Dictionary) -> void: events += 1)


func _identities() -> Dictionary:
	return {"game": game.get_instance_id(), "level": level.get_instance_id(), "hero": hero.get_instance_id(), "scheduler": scheduler.get_instance_id(), "source": source.get_instance_id(), "source_art": source.get_art().get_instance_id(), "source_cue": source.get_cue().get_instance_id(), "circle": circle.get_instance_id(), "circle_cue": circle.get_cue().get_instance_id(), "puff": circle.get_node("SquareImpactFragments").get_instance_id()}


func _send_pending_swipe() -> void:
	var press := InputEventScreenTouch.new()
	press.index = 9
	press.pressed = true
	press.position = Vector2(180, 650)
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	var drag := InputEventScreenDrag.new()
	drag.index = 9
	drag.position = Vector2(360, 650)
	drag.relative = Vector2(180, 0)
	Input.parse_input_event(drag)
	Input.flush_buffered_events()
	var release := InputEventScreenTouch.new()
	release.index = 9
	release.position = drag.position
	Input.parse_input_event(release)
	Input.flush_buffered_events()


func _send_solo_primary() -> bool:
	var tap: Vector2 = (game.call("get_aim_anchor") as Vector2) + Vector2(0, -180)
	if not _expect((game.call("aim_direction", tap) as Vector3).dot(Vector3.FORWARD) > 0.9999, "ordinary primary direction derives from the shared release anchor"): return false
	hero.shells = 0
	var press := InputEventScreenTouch.new()
	press.index = 8
	press.pressed = true
	press.position = tap
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	var release := InputEventScreenTouch.new()
	release.index = 8
	release.position = tap
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	no_ammo_primary = hero.shells == 0
	return true


func _last_action_sequence() -> int:
	var records: Array[Dictionary] = hero.get_world_action_records()
	return 0 if records.is_empty() else int(records.back().sequence)


func _stage_approach(position: Vector3) -> void:
	paused = true
	hero.global_position = position
	hero.velocity = Vector3.ZERO


func _wait_for(predicate: Callable, attempts: int) -> bool:
	for attempt: int in range(attempts):
		if finishing: return false
		if predicate.call() == true: return true
		await create_timer(0.01, true).timeout
	return false


func _pair() -> Dictionary:
	return {"player": hero.snapshot_state(), "level": level.snapshot_state()}


func _restore_pair(saved: Dictionary) -> bool:
	if not hero.snapshot_error(saved.player).is_empty() or not level.snapshot_error_with_player(saved.level, saved.player).is_empty(): return false
	if not hero.restore_state(saved.player): return false
	return level.restore_state(saved.level)


func _diagnose_setup(stage: String) -> void:
	if not is_instance_valid(level): return
	print("COMPOUND DEFERRED SETUP DIAGNOSTIC ", stage, " ", level.call("encounter_state"), " admission=", level.get("last_admission"), " circle_admission=", level.get("last_circle_admission"), " camera=", game.get("last_camera_framing_error"), " paused=", paused)


func _expect(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	return ok


func _finish() -> void:
	if finishing: return
	finishing = true
	watching = false
	paused = true
	if is_instance_valid(source) and source.state_changed.is_connected(_request_pause_from_source): source.state_changed.disconnect(_request_pause_from_source)
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(scheduler):
		_expect(not scheduler.is_physics_processing() and scheduler.reservations().is_empty() and get_nodes_in_group("enemies").is_empty(), "actual local exit retires native processing, leases and live target groups")
	if is_instance_valid(game) and is_instance_valid(game.get("fx")): game.get("fx").clear()
	await create_timer(0.5, true).timeout
	if is_instance_valid(game): game.free()
	paused = false
	await process_frame
	print("A1-L2 COMPOUND DEFERRED PAUSE: %d checks, %d failures (staged approaches; no traversal acceptance)" % [checks, failures])
	quit(1 if failures else 0)
