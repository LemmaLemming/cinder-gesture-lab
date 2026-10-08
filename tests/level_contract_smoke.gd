extends SceneTree

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const FixturePath: String = "res://tests/fixtures/levels/contract_level.tscn"

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game: Node = MainScene.instantiate()
	root.add_child(game)
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	_expect(game.call("is_lab_level") and String(game.get("level_scene_path")).is_empty(), "default launch selects the existing character lab")
	_expect(hero.global_position.is_equal_approx(game.get("player_start")), "default lab retains its exact authored spawn")
	_expect(get_nodes_in_group("practice_targets").size() == 3 and get_nodes_in_group("lab_weapons").size() == 3, "default lab retains three targets and three weapon candidates")
	game.call("choose_exercise", "duel")
	_expect(get_nodes_in_group("enemies").size() == 1, "default lab still switches to its one-enemy exercise")
	game.call("choose_exercise", "targets")

	_expect(game.call("load_level_scene", FixturePath), "custom level passes the scene contract")
	var level: CinderLevel = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	var effects: PixelEffects = game.get("fx") as PixelEffects
	var camera: Camera3D = game.get("camera") as Camera3D
	var locked_basis: Basis = camera.global_basis
	var spawn_camera_offset: Vector3 = camera.global_position - hero.global_position
	_expect(not game.call("is_lab_level") and game.get("level_scene_path") == FixturePath, "custom scene replaces only the level selection")
	_expect(hero.global_position.is_equal_approx(Vector3(3.5, 0.1, -3.0)), "spawn uses the marker's world position, including the level transform")
	_expect(level.hero == hero and level.effects == effects and int(level.get("enter_count")) == 1, "entry receives the one shared player and effects exactly once")
	level.enter_level(hero, effects)
	_expect(int(level.get("enter_count")) == 1, "duplicate lifecycle entry does not duplicate content or callbacks")
	_expect(get_nodes_in_group("practice_targets").is_empty() and get_nodes_in_group("lab_weapons").is_empty(), "custom preview omits all lab targets and weapon stands")
	var enemy: AshEnemy = level.get_node("LevelEnemy") as AshEnemy
	_expect(get_nodes_in_group("enemies").size() == 1 and enemy.get("_hero") == hero and enemy.get("_fx") == effects, "level-owned enemy is configured against shared systems")
	game.call("choose_exercise", "arena")
	_expect(game.get("active_level") == level and get_nodes_in_group("enemies").size() == 1, "lab exercise requests cannot replace a custom level")

	var screen_center: Vector2 = root.get_visible_rect().size * 0.5
	game.call("_record_swipe_end", screen_center - Vector2(30, 20))
	var expected_aim: Vector3 = game.call("aim_direction", screen_center)
	var actions: Array[String] = []
	hero.fired.connect(func(kind: String) -> void: actions.append(kind))
	game.call("handle_tap", screen_center)
	game.call("handle_tap", screen_center)
	_expect(actions == ["slash", "blast"] and hero.facing.dot(expected_aim) > 0.999, "custom preview preserves immediate slash, one second-tap blast and release-point aim")

	# An explicit preview reset restores supplies but carries existing gear.
	hero.equip_item("WEAPON-02")
	await create_timer(0.25).timeout
	hero.hp = 35.0
	hero.shells = 0
	effects.burst(hero.global_position + Vector3.UP, Color.WHITE, 2, 2.0)
	var old_hero: CinderPlayer = hero
	var old_level: CinderLevel = level
	var old_prop: Node = level.get_node("RuntimeProp")
	var observed_before_exit: int = int(level.get("observed_actions"))
	game.call("reset_lab")
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	_expect(level != old_level and hero != old_hero and int(level.get("enter_count")) == 1, "reset creates fresh level and player instances")
	_expect(int(old_level.get("exit_count")) == 1 and old_level.hero == null and old_level.effects == null, "reset exits once and releases shared references")
	old_hero.fired.emit("slash")
	_expect(int(old_level.get("observed_actions")) == observed_before_exit, "exit disconnects the level's shared-player callback")
	_expect(hero.hp == hero.max_hp and hero.shells == hero.max_shells and hero.equipment.snapshot()["weapon"] == "WEAPON-02", "reset restores HP/ammo and preserves carried static weapon")
	_expect(hero.global_position.is_equal_approx(Vector3(3.5, 0.1, -3.0)) and (game.call("get_aim_anchor") as Vector2).is_equal_approx(screen_center), "reset restores the selected spawn and center aim anchor")
	_expect(camera.global_basis.is_equal_approx(locked_basis) and camera.global_position.is_equal_approx(hero.global_position + spawn_camera_offset), "reset snaps the shared camera without changing its angle")
	_expect(effects.active_chunk_count() == 0 and get_nodes_in_group("enemies").size() == 1, "reset clears old effects and replaces level-owned enemies")
	await process_frame
	_expect(not is_instance_valid(old_level) and not is_instance_valid(old_prop) and not is_instance_valid(old_hero), "old level, runtime children and player are freed after reset")

	# Failures preserve the selected scene and carry an inspectable reason.
	for invalid_path: String in ["res://tests/fixtures/levels/absent.tscn", "res://tests/fixtures/levels/wrong_root.tscn", "res://tests/fixtures/levels/missing_spawn.tscn", "user://outside.tscn"]:
		_expect(not game.call("load_level_scene", invalid_path) and not String(game.get("level_load_error")).is_empty() and game.get("active_level") == level, "invalid scene is rejected explicitly without silently selecting the lab: " + invalid_path)

	game.call("open_bench")
	var hud: GameHUD = game.get("hud") as GameHUD
	_expect(paused and not (game.get("bench") as LabBench).visible and (hud.get("_card_button") as Button).text.begins_with("RESUME"), "custom pause offers resume without lab loadout/exercise controls")
	var resumed_actions: Array[String] = []
	hero.fired.connect(func(kind: String) -> void: resumed_actions.append(kind))
	await _click((hud.get("_card_button") as Button).get_global_rect().get_center())
	_expect(not paused and resumed_actions.is_empty(), "custom resume tap is consumed before combat input")
	await process_frame
	_expect(String(hud.get("_objective_text")) == "CONTRACT FIXTURE" and not (hud.get("_telemetry_label") as Label).visible, "preview HUD uses the level objective and suppresses lab telemetry")

	_expect(game.call("load_level_scene", "") and game.call("is_lab_level"), "explicit empty selection returns to the default lab")
	_expect(get_nodes_in_group("practice_targets").size() == 3 and get_nodes_in_group("lab_weapons").size() == 3 and get_nodes_in_group("enemies").is_empty(), "returning to lab restores its fixtures without retaining custom enemies")
	game.queue_free()
	paused = false
	await process_frame

	# A scene path set before startup uses the same interface as the CLI argument.
	game = MainScene.instantiate()
	game.set("level_scene_path", FixturePath)
	root.add_child(game)
	_expect(not game.call("is_lab_level") and get_nodes_in_group("lab_weapons").is_empty(), "startup scene injection bypasses lab fixtures")
	game.queue_free()
	await process_frame
	print("Level contract smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _click(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	root.push_input(motion, true)
	await process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = at
	press.global_position = at
	root.push_input(press, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = at
	release.global_position = at
	root.push_input(release, true)
	await process_frame


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
