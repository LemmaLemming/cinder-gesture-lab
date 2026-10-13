extends SceneTree

const PlayerScene: PackedScene = preload("res://scenes/player.tscn")
const MainScene: PackedScene = preload("res://scenes/main.tscn")
const EnemyScript: GDScript = preload("res://scripts/enemy.gd")
const TargetScript: GDScript = preload("res://scripts/practice_target.gd")
const EffectsScript: GDScript = preload("res://scripts/effects.gd")

class RejectedTarget:
	extends Node3D
	var hp: float = 100.0
	func take_damage(_amount: float, _impulse: Vector3) -> Dictionary:
		return {"accepted": false, "hp_damage": 0.0, "target_id": get_instance_id(), "target_alive_before_hit": true}

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var arena: Node3D = Node3D.new()
	root.add_child(arena)
	_floor(arena)
	var player: CinderPlayer = _player(arena)
	await create_timer(0.10).timeout
	_expect(player.equipment.snapshot() == {"jacket": "CLOTH-J0", "pants": "CLOTH-P0", "shoes": "CLOTH-S0", "weapon": "WEAPON-01"}, "reusable player scene starts in the canonical neutral kit")
	_expect(player.get_node("BodyCollision") is CollisionShape3D and player.get_node("ActorSprite") is LabSprite, "reusable scene exposes one body and foot-anchored shared sprite")
	_expect(not player.equip_item("CLOTH-J1"), "clothing cannot change during active play")
	paused = true
	_expect(player.equip_item("CLOTH-J1"), "paused safe-boundary bench can equip static clothing")
	paused = false
	player.take_damage(20.0, Vector3.ZERO)
	_expect(_near(player.hp, 100.0 - 20.0 / 1.2), "real player damage uses fractional armour mitigation")
	player.queue_free()
	await process_frame

	player = _player(arena)
	player.hp = 70.0
	paused = true
	_expect(player.equip_item("CLOTH-P2") and _near(player.max_hp, 110.0) and _near(player.hp, 70.0), "equipping higher health capacity does not heal")
	player.hp = 100.0
	_expect(player.equip_item("CLOTH-J2") and _near(player.max_hp, 100.0) and _near(player.hp, 100.0), "static health deltas combine before applying capacity")
	_expect(player.equip_item("CLOTH-P0") and _near(player.max_hp, 90.0) and _near(player.hp, 90.0), "lower capacity discards only HP above the new maximum")
	paused = false
	player.queue_free()
	await process_frame

	# Compare unobstructed travel with stat-only shoes, using actual physics ticks.
	player = _player(arena)
	await create_timer(0.08).timeout
	var start: Vector3 = player.global_position
	player.request_dash(Vector3.RIGHT)
	var neutral_duration: float = float(player.get("_dash_total"))
	await create_timer(0.40).timeout
	var neutral_distance: float = _planar(player.global_position - start).length()
	_expect(absf(neutral_distance - 2.7) < 0.04 and _near(neutral_duration, 0.18), "starter dash travels its fixed distance in its baseline duration")
	player.queue_free()
	await process_frame

	player = _player(arena)
	paused = true
	player.equip_item("CLOTH-S1")
	paused = false
	await create_timer(0.08).timeout
	start = player.global_position
	player.request_dash(Vector3.RIGHT)
	var fast_duration: float = float(player.get("_dash_total"))
	await create_timer(0.40).timeout
	_expect(absf(_planar(player.global_position - start).length() - neutral_distance) < 0.04 and fast_duration < neutral_duration, "faster dash arrives sooner at the same landing")
	player.queue_free()
	await process_frame

	player = _player(arena)
	paused = true
	player.equip_item("CLOTH-S2")
	paused = false
	await create_timer(0.08).timeout
	start = player.global_position
	player.request_dash(Vector3.RIGHT)
	var long_duration: float = float(player.get("_dash_total"))
	await create_timer(0.40).timeout
	_expect(absf(_planar(player.global_position - start).length() - 2.97) < 0.04 and long_duration > neutral_duration, "longer shoes change both landing and committed duration")
	player.queue_free()
	await process_frame

	player = _player(arena)
	await create_timer(0.08).timeout
	start = player.global_position
	player.request_dash(Vector3.RIGHT)
	await physics_frame
	# Simulate a stat-source change while the action is in progress. Public
	# clothing UI remains restricted; the active dash must retain its snapshot.
	player.equipment.equip("CLOTH-S2")
	player.call("_refresh_equipment")
	await create_timer(0.40).timeout
	_expect(absf(_planar(player.global_position - start).length() - neutral_distance) < 0.04, "mid-dash stat changes cannot alter an action's snapshotted destination")
	player.queue_free()
	await process_frame

	player = _player(arena)
	await create_timer(0.08).timeout
	player.slash(Vector3.RIGHT)
	player.shells = 1
	player.set("_reload", 0.31)
	player.set("_blast_cd", 0.40)
	var slash_deadline: float = float(player.get("_slash_cd"))
	var blast_deadline: float = float(player.get("_blast_cd"))
	_expect(player.equip_item("WEAPON-02") and player.equipment.snapshot()["weapon"] == "WEAPON-01", "contact replacement waits until the current attack phase ends")
	_expect(player.equip_item("WEAPON-03") and String(player.get("_pending_weapon")) == "WEAPON-03", "only the newest requested weapon occupies the pending replacement")
	_expect(player.shells == 1 and _near(player.get("_reload"), 0.31) and _near(player.get("_slash_cd"), slash_deadline) and _near(player.get("_blast_cd"), blast_deadline), "queued replacement preserves ammo, reload progress and outstanding deadlines")
	await create_timer(0.18).timeout
	_expect(player.equipment.snapshot()["weapon"] == "WEAPON-03" and float(player.get("_slash_cd")) > 0.0, "replacement commits at action end before primary cooldown expiry")
	_expect(not player.action_in_progress() and float(player.get("_visual_phase_left")) > 0.0, "slower cosmetic settling does not extend the action or delay a queued weapon")
	_expect(player.shells == 1 and float(player.get("_reload")) > 0.31 and float(player.get("_blast_cd")) > 0.0, "replacement leaves ongoing reload and blast cooldown running")
	_expect(player.slash(Vector3.RIGHT) == 0, "replacement cannot immediately repeat a cooling-down attack")
	player.queue_free()
	await process_frame

	# Hit acceptance and reload credit: real enemies versus safe practice props.
	player = _player(arena)
	await create_timer(0.08).timeout
	var enemy: AshEnemy = _enemy(arena, player, Vector3(1.0, 0.0, 0.0))
	var rejected: Dictionary = enemy.take_damage(0.0, Vector3.ZERO)
	_expect(not rejected["accepted"] and _near(rejected["hp_damage"], 0.0), "enemy damage result rejects zero damage")
	var enemy_hp: float = enemy.hp
	var accepted: Dictionary = enemy.take_damage(2.5, Vector3.ZERO)
	_expect(accepted["accepted"] and accepted["target_alive_before_hit"] and accepted["target_id"] == enemy.get_instance_id() and _near(accepted["hp_damage"], 2.5) and _near(enemy.hp, enemy_hp - 2.5), "enemy damage returns accepted HP loss and a stable target identity")
	paused = true
	_expect(not player.equip_item("CLOTH-J1"), "pausing a dangerous encounter does not make clothing replacement safe")
	paused = false
	player.set("_reload", 0.0)
	_expect(player.slash(Vector3.RIGHT) == 1 and _near(player.get("_reload"), 0.0), "landed primary stores no reload credit while shells are full")
	enemy.hp = 3.0
	var lethal: Dictionary = enemy.take_damage(10.0, Vector3.ZERO)
	_expect(lethal["accepted"] and lethal["target_alive_before_hit"] and _near(lethal["hp_damage"], 3.0), "lethal accepted damage reports actual remaining HP loss")
	_expect(not enemy.take_damage(10.0, Vector3.ZERO)["accepted"], "defeated targets cannot award another accepted hit")
	enemy.queue_free()
	player.queue_free()
	await process_frame

	player = _player(arena)
	await create_timer(0.08).timeout
	player.shells = 0
	var enemies: Array[AshEnemy] = []
	for index: int in range(8):
		enemies.append(_enemy(arena, player, Vector3(1.0 + float(index) * 0.02, 0.0, 0.0)))
	_expect(player.slash(Vector3.RIGHT) == 8 and _near(player.get("_reload"), 0.45), "eight accepted living targets grant one base reload credit per primary action")
	player.set("_slash_cd", 0.0)
	player.set("_reload", 1.0)
	player.slash(Vector3.RIGHT)
	_expect(player.shells == 1 and _near(player.get("_reload"), 0.0), "earned credit completes at most one shell and discards excess")
	for target: AshEnemy in enemies:
		target.queue_free()
	player.queue_free()
	await process_frame

	player = _player(arena)
	await create_timer(0.08).timeout
	player.shells = 0
	var prop: Node3D = TargetScript.new() as Node3D
	arena.add_child(prop)
	prop.position = Vector3(1.0, 0.0, 0.0)
	_expect(player.slash(Vector3.RIGHT) == 1 and _near(player.get("_reload"), 0.0), "practice prop damage gives feedback without enemy reload rewards")
	prop.queue_free()
	player.queue_free()
	await process_frame

	player = _player(arena)
	await create_timer(0.08).timeout
	player.shells = 0
	var immune: RejectedTarget = RejectedTarget.new()
	arena.add_child(immune)
	immune.add_to_group("enemies")
	immune.position = Vector3(1.0, 0.0, 0.0)
	_expect(player.slash(Vector3.RIGHT) == 0 and _near(player.get("_reload"), 0.0), "overlap with a rejected damage result does not count as a hit")
	immune.queue_free()
	player.queue_free()
	await process_frame

	# Pause the actual physics bodies and tween-driven effects together.
	player = _player(arena)
	await create_timer(0.08).timeout
	enemy = _enemy(arena, player, Vector3(6.0, 0.0, 0.0))
	enemy.set_physics_process(true)
	var effects: PixelEffects = EffectsScript.new() as PixelEffects
	arena.add_child(effects)
	player.fx = effects
	player.shells = 1
	player.request_dash(Vector3.RIGHT)
	player.slash(Vector3.RIGHT)
	enemy.set("_windup_left", 0.5)
	effects.burst(Vector3(0.0, 1.0, 0.0), Color.WHITE, 1, 3.0)
	await physics_frame
	paused = true
	var frozen_player: Vector3 = player.global_position
	var frozen_enemy: Vector3 = enemy.global_position
	var dash_left: float = float(player.get("_dash_left"))
	var dash_cooldown: float = float(player.get("_dash_cooldown"))
	var invulnerability_left: float = float(player.get("_invulnerable"))
	var reload_elapsed: float = float(player.get("_reload"))
	var visual_left: float = float(player.get("_visual_phase_left"))
	var windup_left: float = float(enemy.get("_windup_left"))
	var chunk: RigidBody3D = (effects.get("_chunks") as Array)[0] as RigidBody3D
	var frozen_chunk: Vector3 = chunk.global_position
	await create_timer(0.18).timeout
	_expect(player.global_position.is_equal_approx(frozen_player) and _near(player.get("_dash_left"), dash_left) and _near(player.get("_dash_cooldown"), dash_cooldown) and _near(player.get("_invulnerable"), invulnerability_left) and _near(player.get("_reload"), reload_elapsed), "pause freezes player travel, action deadlines and reload progress")
	_expect(visual_left > 0.0 and _near(player.get("_visual_phase_left"), visual_left), "pause freezes the slower cosmetic animation clock")
	_expect(enemy.global_position.is_equal_approx(frozen_enemy) and _near(enemy.get("_windup_left"), windup_left), "pause freezes enemy movement and warning deadlines")
	_expect(is_instance_valid(chunk) and chunk.global_position.is_equal_approx(frozen_chunk) and effects.active_chunk_count() == 1, "pause freezes debris motion and lifetime")
	paused = false
	arena.queue_free()
	await process_frame

	await _test_main_lab()
	print("Character lab smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_main_lab() -> void:
	var game: Node = MainScene.instantiate()
	root.add_child(game)
	await process_frame
	var has_api: bool = game.has_method("open_bench") and game.has_method("resume_lab") and game.has_method("choose_exercise")
	_expect(has_api, "main lab exposes safe bench, resume and bounded exercises")
	if not has_api:
		game.queue_free()
		await process_frame
		return
	_expect(get_nodes_in_group("enemies").is_empty() and not get_nodes_in_group("practice_targets").is_empty(), "first launch provides calm reachable practice targets")
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	var events: Array[String] = []
	hero.fired.connect(func(kind: String) -> void: events.append(kind))
	game.call("open_bench")
	await process_frame
	_expect(paused, "equipment bench pauses the entire scene tree")
	var bench: Node = game.get("bench") as Node
	var resume_button: Button = _find_button(bench, "RESUME")
	_expect(resume_button != null and resume_button.is_visible_in_tree(), "paused bench displays a touch-sized resume control")
	if resume_button != null:
		await _click(resume_button.get_global_rect().get_center())
		_expect(not paused and events.is_empty(), "resume UI click is consumed before slash/blast processing")
	else:
		game.call("resume_lab")
	game.call("choose_exercise", "duel")
	_expect(get_nodes_in_group("enemies").size() == 1, "single-threat exercise introduces one bounded enemy")
	game.queue_free()
	paused = false
	await process_frame


func _find_button(node: Node, prefix: String) -> Button:
	if node == null:
		return null
	if node is Button and String(node.text).to_upper().begins_with(prefix):
		return node as Button
	for child: Node in node.get_children():
		var found: Button = _find_button(child, prefix)
		if found != null:
			return found
	return null


func _click(at: Vector2) -> void:
	# Dispatch viewport-local pixels through the native GUI/unhandled-input path;
	# this is independent of the desktop window's presentation scale.
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	root.push_input(motion, true)
	await process_frame
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = at
	press.global_position = at
	root.push_input(press, true)
	await process_frame
	var release: InputEventMouseButton = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = at
	release.global_position = at
	root.push_input(release, true)
	await process_frame


func _player(arena: Node3D) -> CinderPlayer:
	var player: CinderPlayer = PlayerScene.instantiate() as CinderPlayer
	player.position = Vector3(0.0, 0.02, 0.0)
	arena.add_child(player)
	return player


func _enemy(arena: Node3D, player: CinderPlayer, at: Vector3) -> AshEnemy:
	var enemy: AshEnemy = EnemyScript.new() as AshEnemy
	enemy.configure(player, null, 0)
	arena.add_child(enemy)
	enemy.position = at
	enemy.hp = 120.0
	enemy.max_hp = 120.0
	enemy.set_physics_process(false)
	return enemy


func _floor(arena: Node3D) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position.y = -0.5
	var collider: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(40.0, 1.0, 40.0)
	collider.shape = shape
	body.add_child(collider)
	arena.add_child(body)


func _planar(value: Vector3) -> Vector3:
	return Vector3(value.x, 0.0, value.z)


func _near(actual: Variant, expected: Variant) -> bool:
	return absf(float(actual) - float(expected)) < 0.00001


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
