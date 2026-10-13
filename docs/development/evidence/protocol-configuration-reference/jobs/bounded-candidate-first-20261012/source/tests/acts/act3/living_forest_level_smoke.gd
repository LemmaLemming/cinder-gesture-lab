extends SceneTree
## Actual full-layout arrival and typed aggregate restoration. This first
## selector establishes no route clear, mixed fairness or campaign acceptance.

const MainScene = preload("res://scenes/main.tscn")
const FullPath: String = "res://scenes/acts/act3/a3_l2_living_forest.tscn"
const ExactJson = preload("res://scripts/campaign/exact_json.gd")

class PostActorBarrier:
	extends Node
	signal completed
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 1000
	func _physics_process(_delta: float) -> void:
		completed.emit()
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PAUSED:
			completed.emit.call_deferred()

var _game: Node
var _hero: CinderPlayer
var _level: CinderLevel
var _scheduler: CinderThreatScheduler
var _barrier: PostActorBarrier
var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not _expect(OS.get_cmdline_user_args().is_empty() or OS.get_cmdline_user_args() == PackedStringArray(["--arrival-only"]), "current selector is the bounded actual arrival/aggregate check"):
		await _finish()
		return
	if not await _open(false):
		await _finish()
		return
	var sources: Dictionary = _level.get("sources")
	var before: Dictionary = _level.call("state")
	_expect(sources.size() == 9 and before.entered.is_empty() and before.cleared.is_empty() and not before.completed and before.beat == 1, "actual arrival retains all nine sources dormant before the six entries")
	var kinds: Dictionary = {"stalker": 0, "root": 0}
	for source: Node in sources.values():
		kinds["stalker" if source is CharacterBody3D else "root"] += 1
	_expect(kinds == {"stalker": 4, "root": 5}, "actual native roster contains the four familiar Stalkers and five living Roots")
	var bindings: Dictionary = _level.call("scheduler_bindings")
	_expect(bindings.world_root == _game.get("world") and bindings.owners.size() == 9 and bindings.actors.hero == _hero and bindings.floors.has("forest-floor"), "typed aggregate binds the actual shared World, Hero, native sources and immutable floor")
	_expect(_hero.is_on_floor() and _hero.presentation_id == "act3_traveller" and _hero.global_position.z > 38.0 and _scheduler.reservations().is_empty(), "actual traveller starts on firm portrait floor with no premature threat or entry")
	_game.call("open_bench")
	await process_frame
	await process_frame
	if not _expect(paused, "public pause settles the complete actual arrival tick"):
		await _finish()
		return
	var saved: Dictionary = _capture()
	if saved.is_empty():
		await _finish()
		return
	var encoded: String = ExactJson.stringify(saved)
	var decoded: Dictionary = ExactJson.parse(encoded)
	if not _expect(not encoded.is_empty() and decoded.get("accepted", false) and _exact(saved, decoded.get("value")), "exact public JSON retains the whole Hero, sun, route and nine typed source envelopes"):
		await _finish()
		return
	saved = decoded.value
	_expect(_hero.snapshot_error(saved.hero).is_empty() and _level.snapshot_error_with_player(saved.level, saved.hero).is_empty(), "independently validated Hero and complete typed level unit agree at the paused arrival")
	var initial: Dictionary = _capture()
	var forged: Dictionary = saved.duplicate(true)
	forged.level.local.route.entries.append({"id": "root-promise"})
	_expect(not _level.snapshot_error_with_player(forged.level, forged.hero).is_empty() and _exact(initial, _capture()), "pure full-level validation rejects fabricated entry history without changing the unit")
	forged = saved.duplicate(true)
	forged.level.local.sources["l2-promise-root"].kind = "stalker"
	_expect(not _level.snapshot_error_with_player(forged.level, forged.hero).is_empty() and _exact(initial, _capture()), "pure full-level validation rejects crossing the Root and Stalker source types")
	var old_hero: WeakRef = weakref(_hero)
	var old_level: WeakRef = weakref(_level)
	await _close()
	_expect(old_hero.get_ref() == null and old_level.get_ref() == null, "old actual Hero and complete nine-source layout release before fresh reconstruction")
	if not await _open(true):
		await _finish()
		return
	var fresh: Dictionary = _capture()
	if not _expect(_hero.snapshot_error(saved.hero).is_empty() and _level.snapshot_error_with_player(saved.level, saved.hero).is_empty() and _exact(fresh, _capture()), "fresh complete typed prevalidation accepts saved arrival without advancing or mutating the new unit"):
		await _finish()
		return
	# One call stack: actual Player first, then level-owned actors/Scheduler/
	# mechanisms. No yield, new admission, event, heal or copied actor in between.
	if not _expect(_hero.restore_state(saved.hero) and _level.restore_state(saved.level), "actual Hero then complete typed level quietly restores the saved arrival"):
		print("RESTORE ERROR: ", _hero.last_snapshot_error, "; ", _level.last_snapshot_error)
		await _finish()
		return
	_expect(_exact(saved, _capture()), "fresh recapture retains exact route/sun/native clocks, resources and all typed source states")
	var frozen: Dictionary = _capture()
	await process_frame
	await process_frame
	_expect(_exact(frozen, _capture()) and _scheduler.reservations().is_empty() and not _level.is_completed(), "restored arrival stays frozen without manufacturing a threat, defeat or completion")
	_game.call("resume_lab")
	await _ticks(1)
	_expect(not paused and _scheduler.get_clock() > float(saved.level.local.scheduler.clock_s) and (_level.call("state") as Dictionary).entered.is_empty(), "public resume continues the same actual quiet arrival on the next native tick")
	await _finish()


func _open(quiet: bool) -> bool:
	paused = false
	_game = MainScene.instantiate()
	_game.set("level_scene_path", FullPath)
	root.add_child(_game)
	_barrier = PostActorBarrier.new()
	_game.add_child(_barrier)
	if quiet:
		_game.call("open_bench")
		await process_frame
		await process_frame
	else:
		await _ticks(12)
	_hero = _game.get("player") as CinderPlayer
	_level = _game.get("active_level") as CinderLevel
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler if _level != null else null
	if not _expect(_hero != null and _level != null and _scheduler != null and _level.scene_file_path == FullPath and _level.contract_error().is_empty(), "real MainScene opens the full authored Living Forest layout" + (" at a quiet zero-tick boundary" if quiet else "")):
		return false
	return _expect(String((_level.call("state") as Dictionary).configuration_error).is_empty(), "actual full-layout authoring and native source bindings configure without an error")


func _capture() -> Dictionary:
	var hero: Dictionary = _hero.snapshot_state()
	var level: Dictionary = _level.snapshot_state()
	if not _expect(not hero.is_empty() and not level.is_empty(), "public paused whole-unit writers retain complete native arrival state"):
		print("CAPTURE ERROR: ", _hero.last_snapshot_error, "; ", _level.last_snapshot_error)
		return {}
	return {"hero": hero, "level": level}


func _ticks(count: int) -> void:
	for _i: int in range(count):
		if paused:
			await process_frame
		else:
			await _barrier.completed


func _exact(left: Variant, right: Variant) -> bool:
	return ExactJson.stringify(left) == ExactJson.stringify(right)


func _expect(condition: bool, label: String) -> bool:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + label)
	else:
		print("PASS: " + label)
	return condition


func _close() -> void:
	if is_instance_valid(_level):
		_level.exit_level()
	if is_instance_valid(_scheduler):
		_expect(_scheduler.reservations().is_empty(), "actual full-layout exit releases every owned threat lease")
	if is_instance_valid(_game):
		_game.queue_free()
	for _i: int in range(5):
		await process_frame
	_game = null
	_hero = null
	_level = null
	_scheduler = null
	_barrier = null


func _finish() -> void:
	paused = false
	await _close()
	print("Living Forest arrival aggregate: %d checks; failures: %d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
