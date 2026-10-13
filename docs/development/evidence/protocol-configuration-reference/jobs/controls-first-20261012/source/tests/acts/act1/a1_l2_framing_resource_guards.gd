extends SceneTree
## Narrow actual Main framing-resource regression. Landing admission/resolution
## and solo admission are native. Only the second world's solo floor approach
## is explicitly staged; this is neither full traversal nor portrait evidence.
## Reversible art mutations never yield. Collider detachment is final in a
## fresh world: no reattachment or private native shape-owner identity repair.

const MainScene = preload("res://scenes/main.tscn")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const LEVEL_PATH: String = "res://scenes/acts/act1/a1_l2.tscn"
var game: Node
var level: CinderLevel
var hero: CinderPlayer
var scheduler: CinderThreatScheduler
var detached_collision: CollisionShape3D
var checks: int = 0
var failures: int = 0
var events: int = 0
var finishing: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(35.0, true).timeout.connect(func() -> void:
		if not finishing:
			_expect(false, "bounded framing-resource fixture completes within35 seconds")
			_finish())
	root.size = Vector2i(540, 1170)
	if not _new_game():
		_finish(); return
	var landing: CinderLaneMechanism = (level.get("circles") as Dictionary)["landing-impact"]
	game.call("resume_lab")
	if not _expect(await _wait_for(func() -> bool: return landing.state().status == "running", 450), "actual Main admits its native landing source and selected response"):
		_finish(); return
	game.call("open_bench")
	await process_frame
	var baseline: Dictionary = _baseline("running landing")
	if baseline.is_empty():
		_finish(); return
	var puff := landing.get_node("SquareImpactFragments") as MeshInstance3D
	var parent: Node = puff.get_parent()
	var index: int = puff.get_index()
	# Retain exactly the original art node, transform and mesh. No native tick,
	# source callback or snapshot commit occurs while this binding is absent.
	parent.remove_child(puff)
	_rejected_observation(baseline, "detached actual landing puff")
	parent.add_child(puff)
	parent.move_child(puff, index)
	_recovered(baseline, "reattached same actual landing puff")
	var original_mesh: Mesh = puff.mesh
	puff.mesh = original_mesh.duplicate(true) as Mesh
	_rejected_observation(baseline, "equivalent replacement puff mesh resource")
	puff.mesh = original_mesh
	_recovered(baseline, "restored original native puff mesh resource")
	await _dispose_game()
	if finishing: return
	# Fresh real world isolates the destructive collider case. Its new native
	# registration is created normally; no saved/private owner ID is installed.
	if not _new_game():
		_finish(); return
	game.call("resume_lab")
	if not _expect(await _wait_for(func() -> bool: return level.get("beat_index") == 1, 800), "fresh world genuinely resolves its landing danger before solo"):
		_finish(); return
	# Test-only floor approach; no phase, clock, actor pose or lease is forced.
	game.call("open_bench")
	hero.global_position = Vector3(0, 0.005, 9.5)
	hero.velocity = Vector3.ZERO
	game.call("resume_lab")
	var solo: Act1RushSelenite = (level.get("sources") as Dictionary)["solo"]
	if not _expect(await _wait_for(func() -> bool: return not solo.dormant and not solo.state().reservation_id.is_empty(), 450), "actual solo activates and admits its real leased source in the fresh world"):
		_finish(); return
	game.call("open_bench")
	await process_frame
	baseline = _baseline("actual solo native exchange", solo)
	if baseline.is_empty():
		_finish(); return
	detached_collision = solo.get_node("BodyCollision") as CollisionShape3D
	solo.remove_child(detached_collision)
	_rejected_observation(baseline, "detached actual solo capsule node")
	var captured: Dictionary = level.snapshot_state()
	var capture_error: String = level.last_snapshot_error
	_expect(captured.is_empty() and not capture_error.is_empty() and Exact.stringify(hero.snapshot_state()) == baseline.player_wire and scheduler.get_clock() == baseline.clock_s and events == baseline.events, "missing actual collider rejects native capture purely without resource/clock/lease events")
	print("A1-L2 FRAMING RESOURCE DIAGNOSTIC ", Exact.stringify({"case": "final fresh-world collider detach", "camera_error": level.last_camera_framing_error, "capture_error": capture_error, "clock_s": scheduler.get_clock(), "hp": hero.hp, "shells": hero.shells, "original_reservations": baseline.pair.level.local.scheduler.reservations.size(), "no_shape_owner_restore_claim": true}))
	# The detached collider remains absent until ordinary local exit. Readding it
	# could recreate shape-owner identity and is deliberately not called recovery.
	_finish()


func _new_game() -> bool:
	game = MainScene.instantiate()
	game.set("level_scene_path", LEVEL_PATH)
	root.add_child(game)
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	scheduler = level.get("scheduler") as CinderThreatScheduler if is_instance_valid(level) else null
	if not _expect(is_instance_valid(level) and is_instance_valid(hero) and is_instance_valid(scheduler) and level.scene_file_path == LEVEL_PATH and level.hero == hero and level.contract_error().is_empty(), "fresh actual Main retains its native level, shared Hero and scheduler"):
		return false
	hero.world_action_executed.connect(func(_record: Dictionary) -> void: events += 1)
	hero.died.connect(func() -> void: events += 1)
	scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: events += 1)
	level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: events += 1)
	level.completion_requested.connect(func(_id: String, _completion: String) -> void: events += 1)
	for collection: String in ["sources", "circles"]:
		for actor: Node in (level.get(collection) as Dictionary).values():
			actor.connect("state_changed", func(_state: Dictionary) -> void: events += 1)
			var cue: CinderThreatCue = actor.call("get_cue") as CinderThreatCue
			cue.state_changed.connect(func(_state: Dictionary) -> void: events += 1)
	return true


func _baseline(label: String, actor: Act1RushSelenite = null) -> Dictionary:
	var pair: Dictionary = _pair()
	var points: Array = level.camera_framing_points()
	var presentation_ok: bool = actor == null or (actor.presentation_guard.is_valid() and String(actor.presentation_guard.call()).is_empty())
	if not _expect(paused and not pair.player.is_empty() and not pair.level.is_empty() and level.snapshot_error_with_player(pair.level, pair.player).is_empty() and _finite_points(points) and level.last_camera_framing_error.is_empty() and String(game.call("camera_framing_error", points)).is_empty() and presentation_ok, label + " has coherent native pair, complete finite current framing and valid presentation guard: " + level.last_snapshot_error):
		return {}
	return {"pair": pair, "pair_wire": Exact.stringify(pair), "player_wire": Exact.stringify(pair.player), "points": points, "clock_s": scheduler.get_clock(), "events": events}


func _rejected_observation(baseline: Dictionary, label: String) -> void:
	# Query the shared public wrapper. It must refuse the owned hook's nonfinite
	# rejection rather than silently accepting incomplete geometry or throwing.
	var points: Array = level.camera_framing_points()
	_expect(points.is_empty() and not level.last_camera_framing_error.is_empty() and Exact.stringify(hero.snapshot_state()) == baseline.player_wire and scheduler.get_clock() == baseline.clock_s and events == baseline.events, label + " rejects framing without changing actual Hero, clock or lease/cue/progress events")


func _recovered(baseline: Dictionary, label: String) -> void:
	var points: Array = level.camera_framing_points()
	_expect(_finite_points(points) and points == baseline.points and level.last_camera_framing_error.is_empty() and Exact.stringify(_pair()) == baseline.pair_wire and scheduler.get_clock() == baseline.clock_s and events == baseline.events, label + " recovers the exact original pointset and complete native snapshot with unchanged leases/resources")


func _finite_points(points: Array) -> bool:
	if points.is_empty(): return false
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite(): return false
	return true


func _pair() -> Dictionary:
	return {"player": hero.snapshot_state(), "level": level.snapshot_state()}


func _wait_for(predicate: Callable, attempts: int) -> bool:
	for attempt: int in range(attempts):
		if finishing: return false
		if predicate.call() == true: return true
		await create_timer(0.01, true).timeout
	return false


func _dispose_game() -> void:
	paused = true
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(scheduler):
		_expect(not scheduler.is_physics_processing() and scheduler.reservations().is_empty() and get_nodes_in_group("enemies").is_empty(), "ordinary local exit retires native leases, processing and live target groups")
	if is_instance_valid(game):
		var effects: PixelEffects = game.get("fx") as PixelEffects
		if is_instance_valid(effects): effects.clear()
	if is_instance_valid(detached_collision):
		detached_collision.free()
		detached_collision = null
	await create_timer(0.5, true).timeout
	if is_instance_valid(game): game.free()
	game = null
	level = null
	hero = null
	scheduler = null
	paused = false
	await process_frame


func _expect(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	return ok


func _finish() -> void:
	if finishing: return
	finishing = true
	await _dispose_game()
	print("A1-L2 FRAMING RESOURCE GUARDS: %d checks, %d failures (staged solo approach; no shape-owner repair or route acceptance)" % [checks, failures])
	quit(1 if failures else 0)
