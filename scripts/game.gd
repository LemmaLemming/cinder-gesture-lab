extends Node

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const EffectsScript = preload("res://scripts/effects.gd")
const HUDScript = preload("res://scripts/hud.gd")

var player: CinderPlayer
var fx: PixelEffects
var hud: GameHUD
var world: Node3D
var camera: Camera3D
var cores: int = 0
var kills: int = 0
var _shake: float = 0.0
var _pickups: Array[Node3D] = []
var _pointers: Dictionary = {}
var _last_tap_time: int = -1000
var _last_tap_position := Vector2.ZERO

func _ready() -> void:
	_build_view()
	_build_arena()
	hud = HUDScript.new()
	add_child(hud)
	hud.setup()
	hud.restart_requested.connect(reset_lab)
	hud.start_requested.connect(func() -> void: hud.hide_overlay())
	reset_lab()
	if "--capture" in OS.get_cmdline_user_args():
		_capture_preview()

func _build_view() -> void:
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.stretch_shrink = 3
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(426, 240)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.own_world_3d = true
	viewport.handle_input_locally = false
	container.add_child(viewport)
	world = Node3D.new()
	world.name = "GestureArena"
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.028, 0.02, 0.035)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.7, 0.58, 0.64)
	settings.ambient_light_energy = 0.7
	environment.environment = settings
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -25, 0)
	light.light_color = Color(1, 0.8, 0.75)
	light.light_energy = 1.0
	world.add_child(light)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 17.0
	camera.position = Vector3(0, 18, 13)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	fx = EffectsScript.new()
	world.add_child(fx)

func _build_arena() -> void:
	_platform(Vector3(0, -0.4, 0), Vector3(24, 0.8, 16), Color(0.1, 0.07, 0.115))
	for x: int in range(-12, 12, 2):
		for z: int in range(-8, 8, 2):
			var checker: bool = (x + z) % 4 == 0
			_block(Vector3(x + 1, 0.008, z + 1), Vector3(1.97, 0.016, 1.97), Color(0.15, 0.105, 0.16) if checker else Color(0.12, 0.085, 0.13))
	_platform(Vector3(-12.2, 0.8, 0), Vector3(0.4, 2.4, 16.4), Color(0.21, 0.045, 0.075))
	_platform(Vector3(12.2, 0.8, 0), Vector3(0.4, 2.4, 16.4), Color(0.21, 0.045, 0.075))
	_platform(Vector3(0, 0.8, -8.2), Vector3(24, 2.4, 0.4), Color(0.21, 0.045, 0.075))
	_platform(Vector3(0, 0.3, 8.2), Vector3(24, 1.4, 0.4), Color(0.21, 0.045, 0.075))
	_platform(Vector3(-1.5, 0.65, -1.4), Vector3(2.2, 1.3, 2.2), Color(0.18, 0.12, 0.20))
	_platform(Vector3(4, 0.65, 2.4), Vector3(2.2, 1.3, 2.2), Color(0.18, 0.12, 0.20))
	for x: int in range(-11, 12, 2):
		_block(Vector3(x, 0.03, -7.5), Vector3(0.4, 0.04, 0.16), Color(0.73, 0.035, 0.08))
		_block(Vector3(x, 0.03, 7.5), Vector3(0.4, 0.04, 0.16), Color(0.73, 0.035, 0.08))

func reset_lab() -> void:
	if is_instance_valid(player):
		world.remove_child(player)
		player.queue_free()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.get_parent().remove_child(enemy)
		enemy.queue_free()
	for pickup: Node3D in _pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()
	_pickups.clear()
	_pointers.clear()
	_last_tap_time = -1000
	cores = 0
	kills = 0
	player = PlayerScript.new()
	player.name = "Player"
	player.fx = fx
	world.add_child(player)
	player.global_position = Vector3(-6, 0.1, 3.5)
	player.fired.connect(_on_fired)
	player.died.connect(func() -> void: hud.show_end(false, cores))
	_spawn_enemy(Vector3(-3.0, 0.1, -4.0), 0)
	_spawn_enemy(Vector3(6, 0.1, -3.0), 1)
	_spawn_enemy(Vector3(7, 0.1, 5.0), 2)
	hud.hide_overlay()

func _spawn_enemy(where: Vector3, kind: int = 0) -> AshEnemy:
	var enemy: AshEnemy = EnemyScript.new()
	enemy.configure(player, fx, kind)
	world.add_child(enemy)
	enemy.global_position = where
	enemy.died.connect(_enemy_died)
	return enemy

func _enemy_died(where: Vector3) -> void:
	kills += 1
	var pickup := Node3D.new()
	world.add_child(pickup)
	pickup.global_position = Vector3(where.x, 0.35, where.z)
	var visual := _block(Vector3.ZERO, Vector3(0.22, 0.22, 0.22), Color(1, 0.6, 0.51), pickup)
	visual.rotation.z = PI / 4.0
	_pickups.append(pickup)

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	_shake = maxf(_shake - delta, 0.0)
	camera.position = Vector3(0, 18, 13)
	if _shake > 0.0:
		camera.position.x += randf_range(-0.035, 0.035)
		camera.position.z += randf_range(-0.035, 0.035)
	for index: int in range(_pickups.size() - 1, -1, -1):
		var pickup: Node3D = _pickups[index]
		if not is_instance_valid(pickup):
			_pickups.remove_at(index)
			continue
		pickup.rotation.y += delta * 2.0
		var target: Vector3 = player.global_position + Vector3.UP * 0.45
		var distance: float = pickup.global_position.distance_to(target)
		if distance < 2.5:
			pickup.global_position = pickup.global_position.move_toward(target, delta * 8.0)
		if distance < 0.5:
			cores += 1
			fx.floating_text(target, "+1", Color(1, 0.8, 0.7))
			pickup.queue_free()
			_pickups.remove_at(index)
	hud.update_status(player.hp, player.max_hp, player.shells, player.max_shells, cores, "DASH IN ANY DIRECTION  //  ENEMIES DOWN %d / 3" % kills)

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(player) or player.dead:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_pointer(event.index, event.position)
		else:
			_end_pointer(event.index, event.position)
	elif event is InputEventScreenDrag:
		_drag_pointer(event.index, event.position)
	elif event is InputEventMouseButton and event.device != -1 and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_pointer(-1, event.position)
		else:
			_end_pointer(-1, event.position)
	elif event is InputEventMouseMotion and event.device != -1 and _pointers.has(-1):
		_drag_pointer(-1, event.position)

func _begin_pointer(id: int, pos: Vector2) -> void:
	if pos.y < 100:
		return
	_pointers[id] = {"start": pos, "dashed": false}

func _drag_pointer(id: int, pos: Vector2) -> void:
	if not _pointers.has(id):
		return
	var pointer: Dictionary = _pointers[id]
	var start: Vector2 = pointer["start"]
	if not pointer["dashed"] and start.distance_to(pos) >= _swipe_threshold():
		player.request_dash(screen_to_direction(pos - start))
		pointer["dashed"] = true

func _end_pointer(id: int, pos: Vector2) -> void:
	if not _pointers.has(id):
		return
	var pointer: Dictionary = _pointers[id]
	var start: Vector2 = pointer["start"]
	if not pointer["dashed"]:
		if start.distance_to(pos) >= _swipe_threshold():
			player.request_dash(screen_to_direction(pos - start))
		else:
			handle_tap(pos)
	_pointers.erase(id)

func _swipe_threshold() -> float:
	return clampf(get_viewport().get_visible_rect().size.y * 0.03, 18.0, 40.0)

func screen_to_direction(delta: Vector2) -> Vector3:
	var right: Vector3 = camera.global_basis.x
	right.y = 0.0
	var down: Vector3 = camera.global_basis.z
	down.y = 0.0
	return (right.normalized() * delta.x + down.normalized() * delta.y).normalized()

func handle_tap(screen_pos: Vector2) -> void:
	# Convert native UI coordinates into the pixel-rendered camera viewport.
	var view_size: Vector2 = Vector2(camera.get_viewport().size)
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var scaled: Vector2 = screen_pos * view_size / screen_size
	var origin: Vector3 = camera.project_ray_origin(scaled)
	var ray: Vector3 = camera.project_ray_normal(scaled)
	var point: Vector3 = origin + ray * (-origin.y / ray.y)
	var direction: Vector3 = point - player.global_position
	direction.y = 0.0
	var now: int = Time.get_ticks_msec()
	if now - _last_tap_time <= 280 and screen_pos.distance_to(_last_tap_position) < 90:
		player.blast(direction)
		_last_tap_time = -1000
	else:
		player.slash(direction)
		_last_tap_time = now
		_last_tap_position = screen_pos

func _on_fired(kind: String) -> void:
	_shake = 0.12 if kind == "blast" else 0.035

func _platform(pos: Vector3, dimensions: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	world.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	_block(Vector3.ZERO, dimensions, color, body)
	if dimensions.y > 1.0:
		_block(Vector3(0, dimensions.y / 2.0 + 0.025, 0), Vector3(dimensions.x, 0.05, dimensions.z), Color(0.32, 0.05, 0.09), body)

func _block(pos: Vector3, dimensions: Vector3, color: Color, parent: Node3D = null) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	(parent if parent else world).add_child(instance)
	return instance

func _capture_preview() -> void:
	await get_tree().create_timer(0.5).timeout
	player.request_dash(Vector3(1, 0, -0.5))
	await get_tree().create_timer(0.1).timeout
	fx.burst(Vector3(0.5, 0.8, 1), Color(0.98, 0.04, 0.10), 30, 6.0)
	await get_tree().create_timer(0.12).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	get_viewport().get_texture().get_image().save_png("res://captures/mechanics-lab.png")
	get_tree().quit()
