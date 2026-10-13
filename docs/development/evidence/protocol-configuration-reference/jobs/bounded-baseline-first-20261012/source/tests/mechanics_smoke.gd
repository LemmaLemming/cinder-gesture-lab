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
	# Check the spawn snap before the first physics step lowers the capsule to
	# the floor. Its subsequent translation correctly uses the eased follow.
	var launch_centered: bool = _camera_centers_on(game.get("camera") as Camera3D, game.get("player") as CinderPlayer)
	await process_frame
	for enemy: Node in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	_expect(game.get("world") is Node3D, "main scene creates its 3D arena")
	_expect(game.get("player") is CinderPlayer, "main scene creates its player")
	_expect(game.get("fx") is PixelEffects, "main scene creates its effects")
	_expect(game.has_method("handle_tap"), "main scene routes tap gestures")
	_expect(game.has_method("screen_to_direction"), "main scene converts screen swipes into arena directions")
	_expect(game.has_method("get_aim_anchor") and game.has_method("aim_direction"), "main scene exposes swipe-anchored aim")
	_expect(game.has_method("_record_swipe_end") and game.has_method("_update_camera"), "main scene updates the final swipe anchor and fixed-angle camera")
	var view_size: Vector2 = game.get_viewport().get_visible_rect().size
	var view_center: Vector2 = view_size * 0.5
	var swipe_span: float = minf(view_size.x, view_size.y) * 0.18
	_expect(view_size.y > view_size.x and int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 540 and int(ProjectSettings.get_setting("display/window/size/viewport_height")) == 1170, "project uses a portrait 540 x 1170 viewport")
	_expect(int(ProjectSettings.get_setting("display/window/handheld/orientation")) == 1, "handheld orientation is portrait")
	var gesture_player: CinderPlayer = game.get("player") as CinderPlayer
	var camera: Camera3D = game.get("camera") as Camera3D
	var locked_basis: Basis = camera.global_basis
	_expect(camera.projection == Camera3D.PROJECTION_ORTHOGONAL and camera.keep_aspect == Camera3D.KEEP_WIDTH and absf(camera.size - 7.2) < 0.01, "portrait camera is orthographic with locked width and close framing")
	_expect(launch_centered, "camera centers the player at launch")
	var initial_anchor: Vector2 = game.call("get_aim_anchor")
	_expect(initial_anchor.distance_to(view_center) < 1.0, "aim anchor defaults to screen center before a swipe")
	gesture_player.facing = Vector3.BACK
	game.call("handle_tap", view_center)
	_expect(gesture_player.facing.dot(Vector3.BACK) > 0.99, "tapping the exact center before a swipe uses last facing")
	if game.has_method("screen_to_direction"):
		var right: Vector3 = game.call("screen_to_direction", Vector2.RIGHT * 100.0)
		var left: Vector3 = game.call("screen_to_direction", Vector2.LEFT * 100.0)
		var up: Vector3 = game.call("screen_to_direction", Vector2.UP * 100.0)
		var down: Vector3 = game.call("screen_to_direction", Vector2.DOWN * 100.0)
		var diagonal: Vector3 = game.call("screen_to_direction", Vector2(100.0, 100.0))
		_expect(absf(right.length() - 1.0) < 0.01 and absf(up.length() - 1.0) < 0.01, "cardinal swipes produce normalized directions")
		_expect(right.dot(left) < -0.99 and up.dot(down) < -0.99, "opposite swipes produce opposite arena directions")
		_expect(absf(diagonal.y) < 0.001 and absf(diagonal.length() - 1.0) < 0.01, "diagonal swipes remain on X/Z with unit length")
	var gesture_events: Array[String] = []
	gesture_player.fired.connect(func(kind: String) -> void: gesture_events.append(kind))
	await create_timer(0.15).timeout
	var gesture_start: Vector3 = gesture_player.global_position
	var swipe_start: Vector2 = view_center + Vector2(-swipe_span * 0.5, 0.0)
	await _mouse_swipe(swipe_start, swipe_start + Vector2(swipe_span, 0.0))
	await create_timer(0.06).timeout
	var mid_dash_focus: Vector3 = game.get("_camera_focus")
	var mid_dash_lag: float = _planar(gesture_player.global_position + Vector3.UP * 0.75 - mid_dash_focus).length()
	var mid_dash_camera_travel: float = _planar(mid_dash_focus - gesture_start).length()
	_expect(mid_dash_lag > 0.3 and mid_dash_camera_travel > 0.1, "camera follows partway through a dash with visible lag instead of instant lock")
	_expect(_basis_matches(camera.global_basis, locked_basis), "mid-dash camera lag preserves its fixed viewing angle")
	await create_timer(0.69).timeout
	_expect(gesture_events == ["dash"] and _planar(gesture_player.global_position - gesture_start).length() > 2.4, "mouse press/drag/release dispatches through the scene and produces one dash without an attack")
	_expect(_camera_centers_on(camera, gesture_player) and _basis_matches(camera.global_basis, locked_basis), "camera settles close to the stopped player without changing its viewing angle")
	var touch_start: Vector3 = gesture_player.global_position
	await _touch_swipe(view_center + Vector2(0.0, -swipe_span * 0.5), view_center + Vector2(0.0, swipe_span * 0.5))
	await create_timer(0.75).timeout
	_expect(gesture_events == ["dash", "dash"] and _planar(gesture_player.global_position - touch_start).length() > 2.4, "screen touch/drag/release dispatches through the scene and produces one dash without an attack")
	var tap_at: Vector2 = view_center
	game.call("_begin_pointer", 100, tap_at)
	game.call("_end_pointer", 100, tap_at)
	_expect(gesture_events == ["dash", "dash", "slash"] and gesture_player.shells == 2, "a single tap slashes without using a shell")
	game.call("_begin_pointer", 101, tap_at)
	game.call("_end_pointer", 101, tap_at)
	_expect(gesture_events == ["dash", "dash", "slash", "blast"] and gesture_player.shells == 1, "a second quick tap fires a shotgun shell")
	var long_swipe_start: Vector2 = view_size * Vector2(0.75, 0.40)
	var threshold_crossing: Vector2 = view_size * Vector2(0.55, 0.38)
	var upper_left_end: Vector2 = view_size * Vector2(0.38, 0.36)
	game.call("_begin_pointer", 202, long_swipe_start)
	game.call("_drag_pointer", 202, threshold_crossing)
	game.call("_end_pointer", 202, upper_left_end)
	await create_timer(0.75).timeout
	_expect(gesture_events == ["dash", "dash", "slash", "blast", "dash"], "a longer drag still triggers exactly one dash")
	var release_anchor: Vector2 = game.call("get_aim_anchor")
	_expect(release_anchor.distance_to(upper_left_end) < 1.0, "the aim anchor is the final swipe release, not the first threshold crossing")
	var bottom_right_aim: Vector3 = game.call("aim_direction", view_center)
	_expect(bottom_right_aim.x > 0.05 and bottom_right_aim.z > 0.05, "upper-left swipe release then center tap aims down-right in world X/Z")
	var opposite_tap: Vector2 = upper_left_end * 2.0 - view_center
	var upper_left_aim: Vector3 = game.call("aim_direction", opposite_tap)
	_expect(_planar(bottom_right_aim).normalized().dot(_planar(upper_left_aim).normalized()) < -0.99, "taps on opposite sides of one anchor produce opposite attack directions")
	gesture_player.facing = Vector3.LEFT
	game.call("handle_tap", upper_left_end)
	_expect(gesture_player.facing.dot(Vector3.LEFT) > 0.99, "a tap exactly on the last swipe end keeps last facing")
	var focus_before_move: Vector3 = game.get("_camera_focus")
	gesture_player.global_position += Vector3(1.4, 0.0, -1.2)
	game.call("_update_camera", 1.0 / 60.0)
	await process_frame
	var moved_aim: Vector3 = game.call("aim_direction", view_center)
	_expect(_planar(moved_aim).normalized().dot(_planar(bottom_right_aim).normalized()) > 0.999 and (game.call("get_aim_anchor") as Vector2).distance_to(release_anchor) < 0.01, "tap aim and final release anchor are unchanged while camera follow lags")
	_expect((game.get("_camera_focus") as Vector3).distance_to(focus_before_move) > 0.01 and not _camera_centers_on(camera, gesture_player) and _basis_matches(camera.global_basis, locked_basis), "ordinary repositioning catches up smoothly without snapping or rotating")
	await _camera_easing_checks(game, gesture_player, camera, locked_basis)
	game.call("reset_lab")
	var reset_player: CinderPlayer = game.get("player") as CinderPlayer
	var reset_anchor: Vector2 = game.call("get_aim_anchor")
	_expect(reset_anchor.distance_to(view_center) < 1.0, "reset restores the aim anchor to screen center")
	_expect(_camera_centers_on(camera, reset_player) and _basis_matches(camera.global_basis, locked_basis), "reset immediately recenters the portrait camera without rotating it")
	await process_frame
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
	var off_axis_target: AshEnemy = _enemy(arena, player, fx, Vector3(1.0, 0.0, 0.65))
	player.call("slash", Vector3.RIGHT)
	_expect(player.facing.dot(Vector3.RIGHT) > 0.999, "a nearby off-axis target does not redirect the intended attack")
	off_axis_target.queue_free()
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


func _camera_centers_on(camera: Camera3D, player: CinderPlayer) -> bool:
	var world_target: Vector3 = player.global_position + Vector3.UP * 0.75
	var viewport_center: Vector2 = Vector2(camera.get_viewport().size) * 0.5
	return camera.unproject_position(world_target).distance_to(viewport_center) < 2.0


func _camera_easing_checks(game: Node, player: CinderPlayer, camera: Camera3D, locked_basis: Basis) -> void:
	# Freeze autonomous updates to compare equal elapsed time across frame sizes.
	game.set_process(false)
	player.set_physics_process(false)
	var target: Vector3 = player.global_position + Vector3.UP * 0.75
	var initial: Vector3 = target + Vector3(-4.0, 0.0, 0.0)
	game.set("_camera_focus", initial)
	game.call("_update_camera", 0.2)
	var one_step: Vector3 = game.get("_camera_focus")
	game.set("_camera_focus", initial)
	for index: int in range(20):
		game.call("_update_camera", 0.01)
	var split_steps: Vector3 = game.get("_camera_focus")
	_expect(one_step.distance_to(split_steps) < 0.0001, "camera exponential follow is independent of render frame subdivision")
	game.set("_camera_focus", initial)
	game.call("_update_camera", 1.0 / 60.0)
	var far_step: float = (game.get("_camera_focus") as Vector3).distance_to(initial)
	var near_initial: Vector3 = target + Vector3(-1.0, 0.0, 0.0)
	game.set("_camera_focus", near_initial)
	game.call("_update_camera", 1.0 / 60.0)
	var near_step: float = (game.get("_camera_focus") as Vector3).distance_to(near_initial)
	_expect(far_step > near_step * 3.99 and near_step > 0.0, "camera catch-up is faster far away and slower near the player")
	game.set("_camera_focus", initial)
	var previous_error: float = initial.distance_to(target)
	var monotonic: bool = true
	for index: int in range(60):
		game.call("_update_camera", 1.0 / 60.0)
		var focus: Vector3 = game.get("_camera_focus")
		var error: float = focus.distance_to(target)
		monotonic = monotonic and error <= previous_error and focus.x <= target.x
		previous_error = error
	_expect(monotonic and previous_error < 0.01, "camera approaches without overshoot and settles within one second")
	_expect(_basis_matches(camera.global_basis, locked_basis), "camera easing keeps exact screen-direction basis")
	game.set("_camera_focus", initial)
	game.call("_update_camera", 0.0)
	game.set_process(true)
	game.call("open_bench")
	await create_timer(0.10).timeout
	_expect((game.get("_camera_focus") as Vector3).distance_to(initial) < 0.0001, "loadout pause freezes a pending camera catch-up")
	game.call("resume_lab")
	player.set_physics_process(true)


func _basis_matches(current: Basis, original: Basis) -> bool:
	return current.x.dot(original.x) > 0.9999 and current.y.dot(original.y) > 0.9999 and current.z.dot(original.z) > 0.9999


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
