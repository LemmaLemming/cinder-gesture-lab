extends SceneTree
## Narrow aggregate callback-pause regression through the actual L2 Main scene.
## Hero approaches are explicitly staged on the real floor, not traversal proof.
## Landing resolution, solo input/primary, chosen-source activation and companion
## admission are native. No consumer sample/phase/clock or lease is fabricated.

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
var finishing: bool = false
var watching: bool = false
var intercepted: bool = false
var inside_capture_rejected: bool = false
var intercepted_phase: String = ""
var callback_clock_s: float = 0.0
var no_ammo_primary: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(35.0, true).timeout.connect(func() -> void:
		if not finishing:
			_expect(false, "bounded compound callback fixture completes within35 seconds")
			_finish())
	root.size = Vector2i(540, 1170)
	game = MainScene.instantiate()
	game.set("level_scene_path", LEVEL_PATH)
	root.add_child(game)
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	if not _expect(level != null and hero != null and level.hero == hero and level.scene_file_path == LEVEL_PATH and level.contract_error().is_empty(), "actual main L2 enters with its single shared Player"):
		_finish(); return
	game.call("resume_lab")
	if not _expect(await _wait_for(func() -> bool: return level.get("beat_index") == 1, 800), "real native landing danger resolves before the solo boundary"):
		_diagnose_setup("landing"); _finish(); return
	var sources: Dictionary = level.get("sources")
	var solo: Act1RushSelenite = sources["solo"]
	# Fixture-only floor staging mirrors the frozen route-choice fixture.
	_stage_approach(Vector3(0, 0.005, 9.5))
	game.call("resume_lab")
	if not _expect(await _wait_for(func() -> bool: return not solo.dormant, 200), "actual solo source activates at its fresh authored boundary"):
		_diagnose_setup("solo activation"); _finish(); return
	var sequence: int = _last_action_sequence()
	if not _send_solo_primary():
		_finish(); return
	if not _expect(await _wait_for(func() -> bool: return solo.dead and level.get("beat_index") == 2, 200), "real ordinary primary clears the solo and establishes the fork beat"):
		_diagnose_setup("solo primary"); _finish(); return
	var actions: Array[Dictionary] = hero.get_world_action_records(sequence)
	_expect(actions.size() == 1 and actions[0].kind == "primary" and actions[0].hits == 1 and no_ammo_primary, "one real first-tap primary hits the solo with zero starting shells")
	scheduler = level.get("scheduler") as CinderThreatScheduler
	source = sources["open"]
	circle = (level.get("circles") as Dictionary)["open-impact"]
	source.state_changed.connect(_pause_from_source)
	# Fixture-only placement three units in front of the existing open source.
	# Native Main chooses the open route, activates it, and requests both leases.
	_stage_approach(Layout.OPEN_SOURCE + Vector3.BACK * 3.0)
	game.call("resume_lab")
	if not _expect(await _wait_for(func() -> bool: return level.get("chosen_route") == "open" and level.get("encounter_started") and not source.dormant, 200), "actual staged open approach establishes its genuine fresh activation"):
		_diagnose_setup("open activation"); _finish(); return
	if not _expect(await _wait_for(func() -> bool: return not source.state().reservation_id.is_empty() and circle.state().status == "running", 450), "Main naturally admits the actual rusher and its companion circle together"):
		_diagnose_setup("compound admission"); _finish(); return
	paused = true
	await process_frame
	var before: Dictionary = _pair()
	if not _expect(not before.player.is_empty() and not before.level.is_empty(), "ordinary deferred compound barrier captures before the observer pause: " + level.last_snapshot_error):
		_diagnose_setup("ordinary compound capture"); _finish(); return
	_expect(before.level.local.sources.open.sample.clock_s == before.level.local.scheduler.clock_s and before.level.local.circles["open-impact"].hero_samples.hero.clock_s == before.level.local.scheduler.clock_s, "both native consumers initially share the exact paired scheduler tick")
	watching = true
	game.call("resume_lab")
	if not _expect(await _wait_for(func() -> bool: return intercepted, 450), "an earlier actual C30 phase observer pauses while its companion is running"):
		_diagnose_setup("phase observer"); _finish(); return
	await process_frame
	_expect(paused and inside_capture_rejected and intercepted_phase in ["lock", "active", "recovery"], "held callback pause rejects capture inside the originating native transaction")
	_assert_deferred_capture()
	_finish()


func _pause_from_source(state: Dictionary) -> void:
	if not watching or intercepted or state.phase not in ["lock", "active", "recovery"] or circle.state().status != "running": return
	intercepted = true
	intercepted_phase = state.phase
	callback_clock_s = scheduler.get_clock()
	paused = true
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
	# Exact transported native endpoints/clock plus diagnostics are logged even if
	# aggregate capture rejects; no guessed stale sample or private state is read.
	var diagnostic: Dictionary = {"phase": intercepted_phase, "callback_clock_s": callback_clock_s, "source_tree_index": source.get_index(), "circle_tree_index": circle.get_index(), "source_physics_priority": source.process_physics_priority, "circle_physics_priority": circle.process_physics_priority, "player": player, "scheduler": paired, "source": saved_source, "circle": saved_circle, "level": saved_level, "source_error": source_error, "circle_error": circle_error, "level_error": level_error, "level_capture_error": String(level.get("last_capture_error")), "circle_public_state": {"status": state.status, "phase": state.phase, "cycle": state.cycle, "reservation_id": state.reservation_id, "source_position": Codec.vector3(state.source_position), "hit_ids": state.hit_ids}}
	print("COMPOUND CALLBACK PAUSE DIAGNOSTIC ", Exact.stringify(diagnostic))
	_expect(not player.is_empty() and not paired.is_empty() and paired.clock_s == callback_clock_s, "deferred held pause preserves the actual Player and exact callback scheduler tick")
	if _expect(not saved_source.is_empty(), "originating C30 retains its complete native sample/pending path after the observer returns: " + source_error):
		_expect(saved_source.sample.clock_s == paired.clock_s and saved_source.sample.hero_position == player.motion.position and saved_source.sample.source_position == saved_source.motion.position, "originating source matches the current saved actor/scheduler endpoints exactly")
	_expect(not saved_circle.is_empty(), "later companion retains the same actual completed actor/scheduler tick after earlier callback pause: " + circle_error)
	if _expect(not saved_level.is_empty(), "whole Player/Level native compound unit captures at the deferred callback-pause barrier: " + level_error):
		_expect(level.snapshot_error_with_player(saved_level, player).is_empty(), "whole captured compound unit prevalidates purely against the same saved Player")
		var wire: String = Exact.stringify({"player": player, "level": saved_level})
		var decoded: Dictionary = Exact.parse(wire)
		_expect(decoded.get("accepted", false) and Exact.stringify(decoded.value) == wire, "complete conditional native envelopes retain every bit through exact JSON")


func _send_solo_primary() -> bool:
	var tap: Vector2 = (game.call("get_aim_anchor") as Vector2) + Vector2(0, -180)
	if not _expect((game.call("aim_direction", tap) as Vector3).dot(Vector3.FORWARD) > 0.9999, "ordinary tap direction derives from the real shared release anchor"): return false
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
	# No physics yield occurs between setting zero shells and actual input delivery;
	# subsequent passive shared reload remains enabled throughout the encounter.
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


func _diagnose_setup(stage: String) -> void:
	print("COMPOUND SETUP DIAGNOSTIC ", stage, " ", level.call("encounter_state"), " admission=", level.get("last_admission"), " circle_admission=", level.get("last_circle_admission"), " camera=", game.get("last_camera_framing_error"), " paused=", paused)


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
	if is_instance_valid(source) and source.state_changed.is_connected(_pause_from_source): source.state_changed.disconnect(_pause_from_source)
	if is_instance_valid(level): level.exit_level()
	await create_timer(0.5, true).timeout
	if is_instance_valid(game): game.free()
	paused = false
	await process_frame
	print("A1-L2 COMPOUND PAUSE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
