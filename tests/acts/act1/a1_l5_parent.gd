extends SceneTree
## Focused production-L5 loading, native ownership, paused complete capture,
## malformed refusal and normal cleanup. No earned route, fresh Shell Continue,
## GUI Retry, boss completion, gesture, full-art or balance credit.
const MainScene = preload("res://scenes/main.tscn")
const LevelScript = preload("res://scripts/acts/act1/living_moon.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
var game: Node
var level: CinderLevel
var checks: int = 0
var failures: int = 0
var started_ms: int = 0
var finished: bool = false


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	process_frame.connect(_watchdog)
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	game = MainScene.instantiate()
	game.set("level_scene_path", "res://scenes/acts/act1/a1_l5.tscn")
	root.add_child(game)
	level = game.get("active_level") as CinderLevel
	if not _expect(is_instance_valid(level) and level.get_script() == LevelScript, "shared Main loads the actual production L5 scene"):
		await _finish(); return
	if not _expect(level.contract_error().is_empty(), "actual floor/source construction succeeds: " + level.contract_error()):
		await _finish(); return
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	if not _expect(level.hero == hero and hero != null and game.get("camera") is Camera3D and game.get("hud") is GameHUD, "one shared Player, camera and HUD bind the actual level"):
		await _finish(); return
	var eye: CharacterBody3D = level.get("eye") as CharacterBody3D
	var blink: CinderNativeSampledCircle = level.get("blink") as CinderNativeSampledCircle
	_expect(eye != null and blink != null and blink.get_parent() == eye and eye.global_position == Vector3(0,0,-9) and eye.velocity == Vector3.ZERO, "genuine stationary native eye owns its child Blink")
	_expect(eye.call("get_sampled_circle_binding").get("hero") == hero, "native sampled binding contains the actual shared Player")
	_expect(level.level_id == "A1-L5" and level.spawn_position() == Vector3(0,0.1,4) and level.get("stage") == "return", "actual level identity, reachable spawn and first return stage")
	_expect(hero.slash(Vector3.FORWARD) == 0 and float(eye.get("hp")) == 240.0, "closed distant Moon grants no ordinary-primary hit credit")
	game.call("resume_lab")
	if not await _wait(func() -> bool: return hero.get_threat_response_state().stable, 4.0):
		_expect(false, "shared Player settles on real authored floor"); await _finish(); return
	if not await _wait(func() -> bool: return (level.get("impact") as CinderLaneMechanism).state().status == "running", 8.0):
		_expect(false, "real known return impact receives a supported native admission: " + String(level.get("last_encounter_error"))); await _finish(); return
	_expect((level.get("impact") as CinderLaneMechanism).state().cycle == 1, "return impact is one genuine first native cycle")
	if not _expect(game.call("request_pause_deferred") == true, "public shared pause request accepted"):
		await _finish(); return
	for index: int in 8:
		await process_frame
		if paused: break
	if not _expect(paused, "public pause settles outside native callbacks"):
		await _finish(); return
	var player: Dictionary = hero.snapshot_state()
	var saved: Dictionary = level.snapshot_state()
	if not _expect(not player.is_empty() and not saved.is_empty(), "whole production parent capture retains complete paused Player/native state: " + level.last_snapshot_error):
		await _finish(); return
	_expect(saved.local.scheduler.schema_version == 4 and saved.local.blink.source_binding.source_id == "moon-eye", "complete schema4/native sampled eye binding remains intact")
	_expect(level.snapshot_error_with_player(saved, player).is_empty(), "pure actual complete paired validation accepts unchanged state")
	var before: String = Exact.stringify(saved)
	var duplicate: Dictionary = Exact.parse(before).value
	_expect(Exact.stringify(duplicate) == before, "exact typed whole-parent transport preserves keys/floats/native pending data")
	var malformed: Dictionary = saved.duplicate(true); malformed.local.escape.until_s = 0.75
	_expect(not level.snapshot_error_with_player(malformed, player).is_empty(), "unstarted escape cannot manufacture a new deadline")
	malformed = saved.duplicate(true); malformed.local.eye.source_binding.generation += 1
	_expect(not level.snapshot_error_with_player(malformed, player).is_empty(), "forged eye incarnation fails complete native paired validation")
	malformed = saved.duplicate(true); malformed.progress.checkpoint_ids["capsule-ready"] = "encounter"
	_expect(not level.snapshot_error_with_player(malformed, player).is_empty(), "unearned return checkpoint is refused")
	_expect(Exact.stringify(level.snapshot_state()) == before and Exact.stringify(hero.snapshot_state()) == Exact.stringify(player), "all malformed validators leave actual state unchanged")
	await _finish()


func _wait(predicate: Callable, seconds: float) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline and not finished:
		if predicate.call(): return true
		await physics_frame
		await process_frame
	return false


func _expect(value: bool, message: String) -> bool:
	checks += 1
	if not value: failures += 1; push_error("L5 parent check: " + message)
	return value


func _watchdog() -> void:
	if not finished and Time.get_ticks_msec() - started_ms > 30000:
		_expect(false, "focused parent watchdog expired")
		_finish.call_deferred()


func _finish() -> void:
	if finished: return
	finished = true
	var descendants: Array[WeakRef] = []
	if is_instance_valid(game):
		for node: Node in game.find_children("*", "", true, false): descendants.append(weakref(node))
		game.queue_free()
	paused = false
	for index: int in 4: await process_frame
	var retained: int = 0
	for reference: WeakRef in descendants:
		if is_instance_valid(reference.get_ref()): retained += 1
	_expect(retained == 0, "normal Main disposal removes all actual level/native descendants")
	var report: String = ProjectSettings.globalize_path("res://.cinder/l5-parent-native-" + str(Time.get_ticks_usec()) + ".json")
	var stream := FileAccess.open(report, FileAccess.WRITE)
	if stream != null: stream.store_string(JSON.stringify({"checks": checks, "failures": failures, "scope": "actual L5 loading/native return admission/pause/whole capture/malformed refusal/cleanup only; no campaign Save/Continue/Retry, boss/hatch transition, full route or art acceptance"}, "\t")); stream.close()
	print("L5 parent native component: ", checks, "/", failures, "; report=", report)
	quit(0 if failures == 0 else 1)
