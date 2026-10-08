extends SceneTree
## Actual authored L3 scene entry and dry-floor traversal only. Required smoke
## and full aggregate are pending; no target defeat/route/checkpoint credited.
const Main: PackedScene = preload("res://scenes/main.tscn")
var _checks: int = 0
var _failures: int = 0
var _game: Node
var _hero: CinderPlayer
var _actions: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(540, 1170)
	_game = Main.instantiate()
	_game.set("level_scene_path", "res://scenes/acts/act2/a2_l3.tscn")
	root.add_child(_game)
	_game.call("resume_lab")
	await _settle(12)
	var level: CinderLevel = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _expect(is_instance_valid(level) and is_instance_valid(_hero) and level.level_id == "A2-L3" and level.contract_error().is_empty(), "actual shared Game installs the authored L3 scene/identity/spawn"):
		await _release(); quit(1); return
	_expect(String(level.get("runtime_error")).is_empty(), "actual actor/tool/scenery assembly has no runtime fault: " + String(level.get("runtime_error")))
	_expect(_hero.presentation_id == "act2_survivor" and _hero.is_on_floor(), "same shared Act2 Hero settles on native dry support")
	var actors: Dictionary = level.get("_actors")
	_expect(actors.size() == 7 and level.get("_mechanisms").size() == 4 and get_nodes_in_group("enemies").size() == 7, "actual finite seven-source roster and four true stationary tools")
	var identities: Dictionary = {}
	for id: String in actors:
		var actor: Node3D = actors[id]
		identities[actor.get_instance_id()] = true
		_expect(actor.call("is_armed") and actor.get("actor_id") == id and actor.get("hp") == 30.0 and actor.get_world_3d() == _hero.get_world_3d(), "actual anchored HP30 target binds the shared native world " + id)
	_expect(identities.size() == 7 and (actors.handling_machine as Node3D).get_node_or_null("BossRig") != null and (actors.road_tender as Node3D).get_node_or_null("TenderRig") != null, "distinct B02/Tender native rigs, no duplicate target proxy")
	_hero.world_action_executed.connect(func(record: Dictionary) -> void: _actions.append(record))
	var shortened: bool = false
	for ignored: int in range(7):
		if not await _dash(Vector3.FORWARD): break
		var record: Dictionary = _actions.back()
		if float(record.distance) < float(_hero.stats.dash_distance) - 0.05:
			shortened = true
			break
	_expect(shortened and absf(_hero.global_position.x) < 0.05 and _hero.global_position.z > -13.4 and _hero.global_position.z < -12.4, "actual completed central dash stops against the authored low wall without jump/climb")
	if shortened:
		await _dash(Vector3.LEFT)
		await _dash(Vector3.FORWARD)
		_expect(_hero.global_position.x < -1.6 and _hero.global_position.z < -13.4 and _hero.is_on_floor(), "actual left side dash reaches continuous ground beyond the wall")
		await _dash(Vector3.RIGHT)
		await _dash(Vector3.RIGHT)
		await _dash(Vector3.BACK)
		_expect(_hero.global_position.x > 1.6 and _hero.global_position.z > -13.4 and _hero.is_on_floor(), "actual right side also passes the low wall on continuous dry ground")
	var state: Dictionary = level.call("encounter_state")
	_expect(state.beat == "smoke_edge" and level.current_checkpoint().id.is_empty() and not level.is_completed(), "floor-only future travel earns no fabricated encounter defeat/checkpoint/clear")
	_expect(_hero.hp == 100.0 and not state.smoke_api_ready, "required unpublished bank emits no assumed/private damage authority")
	var before: int = _actions.size()
	_expect(_game.call("request_pause_deferred"), "supported full native pause before unfinished aggregate check")
	for ignored: int in range(3): await process_frame
	_expect(paused and level.snapshot_state().is_empty() and level.last_snapshot_error.contains("unimplemented"), "incomplete whole aggregate visibly rejects instead of pretending checkpoint/save readiness")
	_expect(_actions.size() == before, "pause publishes no extra completed floor dash")
	await _release()
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "actual authored target/cue subtree is completely released")
	print("A2-L3 actual entry/floor smoke: %d checks, %d failures; real dry-floor dashes only, smoke/aggregate/route unimplemented" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _dash(direction: Vector3) -> bool:
	var ready: bool = false
	for ignored: int in range(180):
		var response: Dictionary = _hero.get_threat_response_state()
		if response.stable and float(response.dash_cooldown_left_s) <= 0.00001:
			ready = true
			break
		await physics_frame
	if not _expect(ready and _hero.request_dash(direction), "real shared ground dash accepts after actual cooldown"): return false
	var before: int = _actions.size()
	for ignored: int in range(180):
		await physics_frame
		if _actions.size() > before:
			var record: Dictionary = _actions.back()
			return _expect(record.kind == "dash" and record.landing is Vector3 and record.path.size() >= 2 and record.landing.y > -0.05, "actual completed world dash publishes its supported path and landing")
	return _expect(false, "actual accepted ground dash did not finish")

func _release() -> void:
	if not is_instance_valid(_game): return
	var level: CinderLevel = _game.get("active_level") as CinderLevel
	if is_instance_valid(level): level.exit_level()
	_game.get("fx").clear()
	paused = false
	await create_timer(0.15).timeout
	_game.queue_free()
	await _settle(3)

func _settle(count: int) -> void:
	for ignored: int in range(count): await physics_frame
	await process_frame

func _expect(ok: bool, label: String) -> bool:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("FAIL: " + label)
	return ok
