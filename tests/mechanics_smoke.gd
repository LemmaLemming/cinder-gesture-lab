extends SceneTree

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const PlayerScript: GDScript = preload("res://scripts/player.gd")
const EnemyScript: GDScript = preload("res://scripts/enemy.gd")
const EffectsScript: GDScript = preload("res://scripts/effects.gd")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game: Node = MainScene.instantiate()
	root.add_child(game)
	await process_frame
	for enemy: Node in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	_expect(game.get("world") is Node3D, "main scene creates its 3D arena")
	_expect(game.get("player") is CinderPlayer, "main scene creates its player")
	_expect(game.get("fx") is PixelEffects, "main scene creates its effects")
	_expect(game.has_method("handle_tap"), "main scene routes tap gestures")
	_expect(game.has_method("screen_to_direction"), "main scene converts screen swipes into arena directions")
	if game.has_method("screen_to_direction"):
		var right: Vector3 = game.call("screen_to_direction", Vector2.RIGHT * 100.0)
		var left: Vector3 = game.call("screen_to_direction", Vector2.LEFT * 100.0)
		var up: Vector3 = game.call("screen_to_direction", Vector2.UP * 100.0)
		var down: Vector3 = game.call("screen_to_direction", Vector2.DOWN * 100.0)
		var diagonal: Vector3 = game.call("screen_to_direction", Vector2(100.0, 100.0))
		_expect(absf(right.length() - 1.0) < 0.01 and absf(up.length() - 1.0) < 0.01, "cardinal swipes produce normalized directions")
		_expect(right.dot(left) < -0.99 and up.dot(down) < -0.99, "opposite swipes produce opposite arena directions")
		_expect(absf(diagonal.y) < 0.001 and absf(diagonal.length() - 1.0) < 0.01, "diagonal swipes remain on X/Z with unit length")
	var gesture_player: CinderPlayer = game.get("player") as CinderPlayer
	var gesture_events: Array[String] = []
	gesture_player.fired.connect(func(kind: String) -> void: gesture_events.append(kind))
	await create_timer(0.15).timeout
	var gesture_start: Vector3 = gesture_player.global_position
	var swipe_start: Vector2 = Vector2(620.0, 400.0)
	await _mouse_swipe(swipe_start, swipe_start + Vector2(120.0, 0.0))
	await create_timer(0.75).timeout
	_expect(gesture_events == ["dash"] and _planar(gesture_player.global_position - gesture_start).length() > 2.4, "mouse press/drag/release dispatches through the scene and produces one dash without an attack")
	var touch_start: Vector3 = gesture_player.global_position
	await _touch_swipe(Vector2(640.0, 360.0), Vector2(640.0, 470.0))
	await create_timer(0.75).timeout
	_expect(gesture_events == ["dash", "dash"] and _planar(gesture_player.global_position - touch_start).length() > 2.4, "screen touch/drag/release dispatches through the scene and produces one dash without an attack")
	var tap_at: Vector2 = Vector2(400.0, 350.0)
	game.call("_begin_pointer", 100, tap_at)
	game.call("_end_pointer", 100, tap_at)
	_expect(gesture_events == ["dash", "dash", "slash"] and gesture_player.shells == 2, "a single tap slashes without using a shell")
	game.call("_begin_pointer", 101, tap_at)
	game.call("_end_pointer", 101, tap_at)
	_expect(gesture_events == ["dash", "dash", "slash", "blast"] and gesture_player.shells == 1, "a second quick tap fires a shotgun shell")
	game.queue_free()
	await process_frame

	var arena: Node3D = Node3D.new()
	root.add_child(arena)
	_world_box(arena, Vector3(0.0, -0.5, 0.0), Vector3(40.0, 1.0, 40.0))
	var fx: PixelEffects = EffectsScript.new() as PixelEffects
	arena.add_child(fx)

	var player: CinderPlayer = _player(arena, fx)
	await create_timer(0.3).timeout
	var idle_start: Vector3 = player.global_position
	await create_timer(0.25).timeout
	_expect(_planar(player.global_position - idle_start).length() < 0.01, "player stays stationary without a gesture")
	_expect(player.max_hp == 100.0 and player.hp == 100.0 and player.max_shells == 2 and player.shells == 2, "player starts with 100 health and two shells")
	player.queue_free()
	await process_frame

	var directions: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3(1.0, 0.0, 1.0)]
	var labels: Array[String] = ["right", "left", "up", "down", "diagonal"]
	var single_dash_length: float = 0.0
	for index: int in range(directions.size()):
		player = _player(arena, fx)
		await create_timer(0.12).timeout
		var start: Vector3 = player.global_position
		var accepted: bool = player.call("request_dash", directions[index] * 4.0)
		_expect(accepted, "%s swipe begins a dash" % labels[index])
		await create_timer(0.8).timeout
		var travel: Vector3 = _planar(player.global_position - start)
		_expect(travel.length() > 0.8 and travel.normalized().dot(directions[index].normalized()) > 0.99, "%s dash follows the requested X/Z direction" % labels[index])
		if index == 0:
			single_dash_length = travel.length()
			_expect(absf(single_dash_length - 2.7) < 0.1, "a completed swipe travels 2.7 world units")
		else:
			_expect(absf(travel.length() - single_dash_length) < 0.18, "%s dash has the same fixed distance as a cardinal dash" % labels[index])
		var stopped_at: Vector3 = player.global_position
		await create_timer(0.12).timeout
		_expect(_planar(player.global_position - stopped_at).length() < 0.02, "%s dash stops without continued movement" % labels[index])
		player.queue_free()
		await process_frame

	player = _player(arena, fx)
	await create_timer(0.12).timeout
	var wall: StaticBody3D = _world_box(arena, Vector3(1.8, 1.5, 0.0), Vector3(0.5, 3.0, 12.0))
	await physics_frame
	player.call("request_dash", Vector3.RIGHT)
	await create_timer(0.8).timeout
	_expect(player.global_position.x > 0.5 and player.global_position.x < 1.55, "dash reaches a wall and cannot tunnel through it")
	player.queue_free()
	wall.queue_free()
	await process_frame

	player = _player(arena, fx)
	await create_timer(0.12).timeout
	var queue_start: Vector3 = player.global_position
	var first_accepted: bool = player.call("request_dash", Vector3.RIGHT)
	for index: int in range(40):
		player.call("request_dash", Vector3.RIGHT)
	await create_timer(1.6).timeout
	var queued_travel: float = _planar(player.global_position - queue_start).length()
	_expect(first_accepted and queued_travel >= single_dash_length * 0.85 and queued_travel <= single_dash_length * 2.15, "repeated swipe requests produce at most one buffered dash")
	var queue_stopped_at: Vector3 = player.global_position
	await create_timer(0.4).timeout
	_expect(_planar(player.global_position - queue_stopped_at).length() < 0.02, "queued gestures finish and do not cause indefinite movement")
	player.queue_free()
	await process_frame

	player = _player(arena, fx)
	await create_timer(0.12).timeout
	var sword_direction: Vector3 = Vector3(1.0, 0.0, 1.0).normalized()
	var sword_target: AshEnemy = _enemy(arena, player, fx, Vector3(1.2, 0.0, 1.2))
	var sword_start_hp: float = sword_target.hp
	var sword_hits: int = player.call("slash", sword_direction)
	_expect(sword_hits == 1 and sword_target.hp < sword_start_hp, "sword damages a close diagonal target")
	_expect(_planar(sword_target.velocity).dot(sword_direction) > 0.1, "sword pushes the target along the attack direction")
	var hp_after_slash: float = sword_target.hp
	var repeated_slash: int = player.call("slash", sword_direction)
	_expect(repeated_slash == 0 and sword_target.hp == hp_after_slash, "sword cooldown prevents duplicate immediate hits")
	sword_target.queue_free()
	player.queue_free()
	await process_frame

	player = _player(arena, fx)
	await create_timer(0.12).timeout
	var blast_direction: Vector3 = Vector3.BACK
	var shotgun_target: AshEnemy = _enemy(arena, player, fx, Vector3(0.0, 0.0, 1.7))
	var shotgun_start_hp: float = shotgun_target.hp
	var shells_before: int = player.shells
	var blast_hits: int = player.call("blast", blast_direction)
	_expect(blast_hits == 1 and shotgun_target.hp < shotgun_start_hp, "shotgun damages a close target along Z")
	_expect(player.shells == shells_before - 1, "shotgun consumes one shell")
	_expect(_planar(shotgun_target.velocity).dot(blast_direction) > 2.0, "shotgun knocks the target away in the arena plane")
	var immediate_blast: int = player.call("blast", blast_direction)
	_expect(immediate_blast == 0 and player.shells == shells_before - 1, "shotgun cooldown prevents spending an extra shell")
	shotgun_target.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	var far_target: AshEnemy = _enemy(arena, player, fx, Vector3(0.0, 0.0, 4.5))
	var far_start_hp: float = far_target.hp
	var far_hits: int = player.call("blast", blast_direction)
	_expect(far_hits == 0 and far_target.hp == far_start_hp, "shotgun misses a target at 4.5 units")
	_expect(player.shells == 0, "second blast spends the remaining shell")
	await create_timer(1.6).timeout
	_expect(player.shells >= 1, "shotgun reloads automatically after its reload interval")
	far_target.queue_free()
	player.queue_free()
	await process_frame

	fx.burst(Vector3(0.0, 1.0, 0.0), Color(1.0, 0.05, 0.1), 180, 7.0)
	_expect(fx.active_chunk_count() == PixelEffects.MAX_CHUNKS, "large burst stays within and fills its debris budget")
	await _debris_trajectory(fx)
	await create_timer(3.0).timeout
	_expect(fx.active_chunk_count() == 0, "debris retires after its real-time lifetime")

	arena.queue_free()
	await process_frame
	print("Gesture mechanics smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _mouse_swipe(start: Vector2, finish: Vector2) -> void:
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = start
	press.global_position = start
	Input.parse_input_event(press)
	await process_frame
	var drag: InputEventMouseMotion = InputEventMouseMotion.new()
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	drag.position = finish
	drag.global_position = finish
	drag.relative = finish - start
	Input.parse_input_event(drag)
	await process_frame
	var release: InputEventMouseButton = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = finish
	release.global_position = finish
	Input.parse_input_event(release)
	await process_frame


func _touch_swipe(start: Vector2, finish: Vector2) -> void:
	var press: InputEventScreenTouch = InputEventScreenTouch.new()
	press.index = 7
	press.pressed = true
	press.position = start
	Input.parse_input_event(press)
	await process_frame
	var drag: InputEventScreenDrag = InputEventScreenDrag.new()
	drag.index = 7
	drag.position = finish
	drag.relative = finish - start
	Input.parse_input_event(drag)
	await process_frame
	var release: InputEventScreenTouch = InputEventScreenTouch.new()
	release.index = 7
	release.pressed = false
	release.position = finish
	Input.parse_input_event(release)
	await process_frame


func _debris_trajectory(fx: PixelEffects) -> void:
	var chunks: Array[RigidBody3D] = []
	var starts: Dictionary = {}
	for child: Node in fx.get_children():
		if child is RigidBody3D:
			var chunk: RigidBody3D = child as RigidBody3D
			if chunk.is_queued_for_deletion():
				continue
			chunks.append(chunk)
			starts[chunk.get_instance_id()] = chunk.global_position
	await create_timer(0.12).timeout
	var early_spread: float = 0.0
	var has_risen: bool = false
	for chunk: RigidBody3D in chunks:
		if not is_instance_valid(chunk):
			continue
		var start: Vector3 = starts[chunk.get_instance_id()]
		early_spread = maxf(early_spread, _planar(chunk.global_position - start).length())
		has_risen = has_risen or chunk.global_position.y > start.y + 0.08
	_expect(early_spread > 0.25 and has_risen, "debris spreads radially and rises during the first 0.12 seconds")
	var falling: Dictionary = {}
	var bounced: Dictionary = {}
	var max_spread: float = early_spread
	var min_height: float = INF
	for index: int in range(54):
		await physics_frame
		for chunk: RigidBody3D in chunks:
			if not is_instance_valid(chunk):
				continue
			var id: int = chunk.get_instance_id()
			var start: Vector3 = starts[id]
			max_spread = maxf(max_spread, _planar(chunk.global_position - start).length())
			min_height = minf(min_height, chunk.global_position.y)
			if chunk.linear_velocity.y < -0.7:
				falling[id] = true
			if falling.has(id) and chunk.global_position.y < 0.4 and chunk.linear_velocity.y > 0.2:
				bounced[id] = true
	_expect(falling.size() > 0 and max_spread > 1.0, "gravity pulls launched debris down while it continues spreading")
	_expect(bounced.size() > 0 and min_height > -0.1, "falling debris collides with the world floor and bounces upward")
	print("Debris trajectory: %.2f units at 0.12 s; %.2f maximum spread; %d chunks bounced" % [early_spread, max_spread, bounced.size()])


func _player(arena: Node3D, fx: PixelEffects) -> CinderPlayer:
	var player: CinderPlayer = PlayerScript.new() as CinderPlayer
	player.fx = fx
	player.position = Vector3(0.0, 0.02, 0.0)
	arena.add_child(player)
	return player


func _enemy(arena: Node3D, player: CinderPlayer, fx: PixelEffects, at: Vector3) -> AshEnemy:
	var enemy: AshEnemy = EnemyScript.new() as AshEnemy
	enemy.configure(player, fx, 1)
	arena.add_child(enemy)
	enemy.global_position = at
	enemy.hp = 120.0
	enemy.max_hp = 120.0
	enemy.set_physics_process(false)
	return enemy


func _world_box(arena: Node3D, at: Vector3, size: Vector3) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = at
	var collider: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	arena.add_child(body)
	return body


func _planar(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
