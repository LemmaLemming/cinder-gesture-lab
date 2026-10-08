extends SceneTree
## First narrow main-scene check: real shell construction, dormant ownership,
## initial exact aggregate and one native landing-circle warning/restore.
## Full route, gesture combat, profiles, campaign persistence and art remain separate.

const MainScene = preload("res://scenes/main.tscn")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const LEVEL_PATH: String = "res://scenes/acts/act1/a1_l2.tscn"
var game: Node
var level: CinderLevel
var hero: CinderPlayer
var checks: int = 0
var failures: int = 0
var events: int = 0
var finishing: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(30.0, true).timeout.connect(func() -> void:
		if not finishing:
			_expect(false, "bounded main opening finishes within30 seconds")
			_finish())
	root.size = Vector2i(540, 1170)
	game = MainScene.instantiate()
	game.set("level_scene_path", LEVEL_PATH)
	root.add_child(game)
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	if not _expect(level != null and hero != null and level.scene_file_path == LEVEL_PATH, "actual shared Game enters the authored main L2 scene"):
		_finish(); return
	if not _expect(level.level_id == "A1-L2" and level.hero == hero and level.contract_error().is_empty(), "main construction and single shared Player satisfy the level contract: " + level.contract_error()):
		_finish(); return
	_expect(hero.global_position == level.spawn_position() and hero.global_position.z == 16.0, "main uses its reachable portrait spawn16")
	var sources: Dictionary = level.get("sources")
	var circles: Dictionary = level.get("circles")
	if not _expect(sources.size() == 4 and circles.size() == 5, "main retains four authored C30s and five native stationary impacts"):
		_finish(); return
	for id: String in ["solo", "rock", "open", "finale"]:
		var actor: Act1RushSelenite = sources[id]
		_expect(actor.dormant and actor.hp == 20.0 and not actor.visible and not actor.is_in_group("enemies"), "future source remains pristine and untargetable: " + id)
	_expect(get_nodes_in_group("enemies").is_empty(), "entry activates no automatic enemy or unchosen route")
	paused = true
	await process_frame
	var initial: Dictionary = _pair()
	if not _expect(not initial.player.is_empty() and not initial.level.is_empty(), "initial main aggregate captures at the actual paused barrier: " + String(level.get("last_capture_error")) + "; " + level.last_snapshot_error):
		_finish(); return
	_expect(level.snapshot_error_with_player(initial.level, initial.player).is_empty(), "complete pristine aggregate prevalidates against retained native bindings")
	var malformed: Dictionary = initial.level.duplicate(true)
	malformed.local.sources.open.dormant = false
	_expect(not level.snapshot_error_with_player(malformed, initial.player).is_empty(), "initial parent composition rejects forged future route activation")
	malformed = initial.level.duplicate(true)
	malformed.progress.completed = true
	malformed.progress.completion_id = "crater-gardens-clear"
	_expect(not level.snapshot_error_with_player(malformed, initial.player).is_empty() and not level.restore_state(malformed), "initial parent rejects forged campaign completion before mutation")
	_expect(Exact.stringify(_pair()) == Exact.stringify(initial), "negative initial checks preserve every actual aggregate bit")
	game.call("resume_lab")
	var impact: CinderLaneMechanism = circles["landing-impact"]
	for attempt: int in 300:
		if impact.state().status == "running": break
		await create_timer(0.01, true).timeout
	if not _expect(impact.state().status == "running" and impact.state().phase == "warning", "actual main admits the landing warning: " + String(level.get("last_encounter_error"))):
		_finish(); return
	_expect(hero.hp == 100.0 and get_nodes_in_group("enemies").is_empty(), "landing warning creates no early damage or hostile celestial performer")
	var answer: Dictionary = level.get("last_circle_admission")
	_expect(answer.get("accepted", false) and not answer.proof.uses_blast and not answer.proof.uses_invulnerability, "landing uses a native ordinary response proof without pickups or blast")
	paused = true
	await process_frame
	var warning: Dictionary = _pair()
	if not _expect(not warning.level.is_empty(), "running landing warning captures its whole native envelope: " + String(level.get("last_capture_error")) + "; " + level.last_snapshot_error):
		_finish(); return
	_expect(level.snapshot_error_with_player(warning.level, warning.player).is_empty(), "landing warning and all dormant sources prevalidate together")
	var frozen: String = Exact.stringify(warning)
	var decoded: Dictionary = Exact.parse(frozen)
	_expect(decoded.get("accepted", false) and Exact.stringify(decoded.value) == frozen, "native main warning survives exact tagged transport")
	impact.state_changed.connect(func(_state: Dictionary) -> void: events += 1)
	impact.get_cue().state_changed.connect(func(_state: Dictionary) -> void: events += 1)
	var before: int = events
	if not _expect(hero.restore_state(decoded.value.player) and level.restore_state(decoded.value.level), "quiet whole main warning restores actors then scheduler then native mechanisms"):
		_finish(); return
	_expect(events == before and Exact.stringify(_pair()) == frozen, "main warning restoration emits no callbacks and preserves all exact bits")
	var old_source: Act1RushSelenite = sources.solo
	var old_scheduler: CinderThreatScheduler = level.get("scheduler")
	level.exit_level()
	_expect(not old_source.is_physics_processing() and not old_source.is_in_group("enemies") and old_scheduler.reservations().is_empty() and not impact.is_physics_processing(), "exit retires all retained sources, native impacts and leases")
	_finish()


func _pair() -> Dictionary:
	return {"player": hero.snapshot_state(), "level": level.snapshot_state()}


func _expect(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	return ok


func _finish() -> void:
	if finishing: return
	finishing = true
	paused = true
	if is_instance_valid(game): game.free()
	print("A1-L2 MAIN OPENING: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
