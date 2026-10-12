extends SceneTree
## TEST ONLY first whole-codec producer/pure validator; actual Main/native entry.
## No disk, CampaignShell, fresh quiet restore, full route or art credit.
const Main = preload("res://scenes/main.tscn")
const LevelScript = preload("res://scripts/acts/act3/false_paradise_level.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const ROOM: String = "res://scenes/acts/act3/a3_l4_false_paradise.tscn"
var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _checks: int = 0
var _failures: int = 0
var _events: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_game = Main.instantiate()
	root.add_child(_game)
	_game.call("open_bench")
	if not _expect(paused and _game.call("load_level_scene", ROOM), "public Main loads actual authored room before any tick"):
		await _finish()
		return
	_game.call("open_bench")
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	for _i: int in range(5): await process_frame
	if not _expect(_level != null and _hero != null and _level.get_script() == LevelScript and _level.scene_file_path == ROOM and not _level.is_restore_candidate() and paused and String(_level.call("runtime_error")).is_empty(), "genuine fresh zero-tick actual parent/Hero configure", _level.last_snapshot_error if _level != null else "missing parent"):
		await _finish()
		return
	_level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: _events.append("checkpoint"))
	var zero: Dictionary = _pair()
	if not _expect(_positive(zero) and zero.level.local.route.entries.is_empty() and zero.level.local.sources.is_empty() and zero.level.local.scheduler.schema_version == 1 and zero.level.local.scheduler.clock_s == 0.0 and zero.hero.world_actions.clock_s == 0.0, "complete current zero-clock native whole local1 pair validates", _level.last_snapshot_error):
		await _finish()
		return
	var before: String = Exact.stringify(zero)
	var rejected: Dictionary = _level.snapshot_state_for_presentation(null, null)
	if not _expect(rejected.is_empty() and _level.last_snapshot_error.contains("actual native Camera/HUD") and Exact.stringify(_pair()) == before, "public fresh-context writer refuses missing Camera/HUD atomically"):
		await _finish()
		return
	_game.call("resume_lab")
	var entered: bool = false
	for _i: int in range(90):
		await physics_frame
		if paused: break
		if _level.call("seen_entry", "offered-rest"):
			entered = true
			break
	if not _expect(entered and not paused and not _hero.dead, "actual ordinary ticks earn only the first grounded court entry"):
		await _finish()
		return
	if not _expect(_game.call("request_pause_deferred"), "public Main requests settled native pause after entry"):
		await _finish()
		return
	for _i: int in range(5): await process_frame
	if not _expect(paused and not _game.call("is_pause_requested"), "whole capture waits until real deferred pause settles"):
		await _finish()
		return
	var first: Dictionary = _pair()
	if not _expect(_positive(first) and first.level.local.route.entries.size() == 1 and first.level.local.sources.size() == 1 and first.level.local.sources.has("l4-rest-stalker") and first.level.local.core.is_empty() and first.level.local.route.deaths.is_empty(), "first genuine Stalker and delivered/pending checkpoint prefix capture coherently", _level.last_snapshot_error):
		await _finish()
		return
	var bad: Dictionary = first.duplicate(true)
	bad.level.local.sources.erase("l4-rest-stalker")
	if not _negative(first, bad, "omitted entitled living source"):
		await _finish()
		return
	bad = first.duplicate(true)
	bad.level.local.scheduler.clock_s = float(bad.level.local.scheduler.clock_s) + 0.25
	if not _negative(first, bad, "whole clock differs from saved Hero"):
		await _finish()
		return
	bad = first.duplicate(true)
	bad.level.local.route.entries[0].id = "invented-entry"
	if not _negative(first, bad, "invented route receipt"):
		await _finish()
		return
	var stable: String = Exact.stringify(_pair())
	var events: Array[String] = _events.duplicate()
	for _i: int in range(3): await process_frame
	_expect(stable == Exact.stringify(_pair()) and _events == events, "native whole pair and checkpoint events remain frozen while paused")
	await _finish()

func _pair() -> Dictionary:
	return {"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}

func _positive(pair: Dictionary) -> bool:
	if pair.hero.is_empty() or pair.level.is_empty(): return false
	var parsed: Dictionary = Exact.parse(Exact.stringify(pair))
	return parsed.get("accepted", false) and parsed.get("value") is Dictionary and Exact.stringify(parsed.value) == Exact.stringify(pair) and _level.snapshot_error_with_player(parsed.value.level, parsed.value.hero).is_empty()

func _negative(original: Dictionary, bad: Dictionary, label: String) -> bool:
	var before: String = Exact.stringify(_pair())
	var supplied: String = Exact.stringify(bad)
	var events: Array[String] = _events.duplicate()
	var error: String = _level.snapshot_error_with_player(bad.level, bad.hero)
	var restored: bool = _level.restore_state(bad.level)
	return _expect(not error.is_empty() and not restored and before == Exact.stringify(_pair()) and supplied == Exact.stringify(bad) and _events == events and _positive(original), "pure rejection/live restore refusal preserves actual native state: " + label, error)

func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	if ok: print("PASS: " + label)
	else:
		_failures += 1
		print("FAIL: " + label + (" / " + detail if not detail.is_empty() else ""))
	return ok

func _refs(node: Node, refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child: Node in node.get_children(): _refs(child, refs)

func _finish() -> void:
	if is_instance_valid(_game):
		var refs: Array[WeakRef] = []
		_refs(_game, refs)
		if is_instance_valid(_level): _level.exit_level()
		_game.queue_free()
		paused = false
		for _i: int in range(5): await process_frame
		var released: bool = true
		for ref: WeakRef in refs: released = released and ref.get_ref() == null
		_expect(released and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal whole Main/native sources/cues dispose completely")
	await create_timer(0.15, true, false, true).timeout
	print("False Paradise whole codec entry: %d checks; failures: %d. Actual zero/first entry capture and pure negatives only; no disk/production Continue/Retry/quiet candidate/helper/sun/full route/art acceptance." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
