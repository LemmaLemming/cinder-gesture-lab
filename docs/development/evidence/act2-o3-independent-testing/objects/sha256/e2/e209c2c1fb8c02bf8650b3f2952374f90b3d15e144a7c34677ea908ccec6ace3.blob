extends SceneTree
## Actual L2 entry/state composition fixture, not a route clear or art approval.
const Main: PackedScene = preload("res://scenes/main.tscn")
const Exact: Script = preload("res://scripts/campaign/exact_json.gd")
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	root.size = Vector2i(540, 1170)
	var game: Node = Main.instantiate()
	game.set("level_scene_path", "res://scenes/acts/act2/a2_l2.tscn")
	root.add_child(game)
	game.call("resume_lab")
	for frame: int in range(8): await physics_frame
	paused = true
	var level: CinderLevel = game.get("active_level") as CinderLevel
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	_expect(is_instance_valid(level) and level.level_id == "A2-L2" and level.get("runtime_error").is_empty(), "actual shared shell enters authored Weybridge: " + String(level.get("runtime_error")) if level != null else "L2 scene absent")
	if level == null:
		game.free(); paused = false; quit(1); return
	_expect(hero.presentation_id == "act2_survivor" and hero.global_position.y > -0.05 and hero.global_position.y < 0.2, "same shared Act2 protagonist settles on dry floor")
	_expect(level.call("floor_regions").size() == 4 and level.get("_actors").size() == 6 and level.get("_mechanisms").size() == 7, "four broad supports, six real targets and finite three tools/four circle stations")
	var snapshot: Dictionary = level.snapshot_state()
	_expect(not snapshot.is_empty(), "capture complete paused L2 unit: " + level.last_snapshot_error)
	if not snapshot.is_empty():
		var text: String = Exact.stringify(snapshot)
		var parsed: Dictionary = Exact.parse(text)
		_expect(parsed.get("accepted", false) and Exact.stringify(parsed.value) == text, "whole L2 transport retains scalar bits and native types")
		_expect(level.snapshot_error_with_player(parsed.value, hero.snapshot_state()).is_empty(), "pure saved-player aggregate preflight: " + level.snapshot_error_with_player(parsed.value, hero.snapshot_state()))
		_expect(level.restore_state(parsed.value), "quiet actual actor/scheduler/consumer paired commit: " + level.last_snapshot_error)
		var before: String = Exact.stringify(level.snapshot_state())
		var forged: Dictionary = parsed.value.duplicate(true)
		forged.local.handlers.yard_handler.hp = 0.0
		forged.local.handlers.yard_handler.phase = "defeated"
		_expect(not level.restore_state(forged) and Exact.stringify(level.snapshot_state()) == before, "future Handler defeat rejects the aggregate before mutation")
		forged = parsed.value.duplicate(true)
		forged.local.sequence.completed_feet = ["foot_demo"]
		_expect(not level.restore_state(forged) and Exact.stringify(level.snapshot_state()) == before, "unearned foot progression rejects before mutation")
		for value: Variant in [[], {}, {"status": "running"}]:
			forged = parsed.value.duplicate(true)
			forged.local.handlers.yard_handler = value
			_expect(not level.restore_state(forged) and Exact.stringify(level.snapshot_state()) == before, "malformed nested Handler rejects atomically before field access")
			forged = parsed.value.duplicate(true)
			forged.local.mechanisms.tool_yard_handler = value
			_expect(not level.restore_state(forged) and Exact.stringify(level.snapshot_state()) == before, "malformed nested tool rejects atomically before crosscheck")
		forged = parsed.value.duplicate(true)
		forged.local.handlers.yard_handler.phase_progress = 0.5
		_expect(not level.restore_state(forged) and Exact.stringify(level.snapshot_state()) == before, "idle Handler pose cannot disagree with its actual tool clock")
		for frame: int in range(4): await process_frame
		_expect(Exact.stringify(level.snapshot_state()) == before, "paused actor/scenery/consumer clocks and full state freeze")
	var retained: Array[Node] = [hero, level, game.get("fx"), level.get_node("DryGround"), level.get_node("OneVisibleGiantFoot")]
	game.free()
	for node: Node in retained: _expect(not is_instance_valid(node), "actual preview teardown frees owned and shared subtree")
	paused = false
	print("Weybridge entry smoke: %d checks, %d failures; entry/state only, no route/art acceptance" % [checks, failures])
	quit(0 if failures == 0 else 1)
func _expect(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
	return ok
