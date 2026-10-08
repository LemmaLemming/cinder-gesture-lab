extends Node

## Observation of this recognizer, separate from executed world-action records.
## Signals never change the release anchor, redirect an attack or gate controls.
signal input_observed(record: Dictionary)
signal aim_anchor_changed(normalized_release: Vector2)

const PlayerScript = preload("res://scripts/player.gd")
const PlayerScene = preload("res://scenes/player.tscn")
const TargetScene = preload("res://scenes/practice_target.tscn")
const BenchScript = preload("res://scripts/lab_bench.gd")
const WeaponPickupScript = preload("res://scripts/weapon_pickup.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const EffectsScript = preload("res://scripts/effects.gd")
const HUDScript = preload("res://scripts/hud.gd")
const LevelScript = preload("res://scripts/campaign/level.gd")
const CameraFraming = preload("res://scripts/presentation/camera_framing.gd")
const LabScene = preload("res://scenes/lab_arena.tscn")

var player: CinderPlayer
var fx: PixelEffects
var hud: GameHUD
var world: Node3D
var camera: Camera3D
var bench: LabBench
@export_file("*.tscn") var level_scene_path: String = ""
var active_level: CinderLevel
var level_load_error: String = ""
var _selected_level_scene: PackedScene
@export_enum("targets", "duel", "arena") var lab_mode: String = "targets"
@export var player_start: Vector3 = Vector3(0, 0.1, 1.0)
@export var practice_target_positions: Array[Vector3] = [Vector3(0, 0, -0.8), Vector3(4, 0, -2.2), Vector3(-4, 0, 1.0)]
@export var weapon_candidate_positions: Array[Vector3] = [Vector3(-2.7, 0, 5.2), Vector3(0, 0, 5.2), Vector3(2.7, 0, 5.2)]
var _enemy_count: int = 0
var cores: int = 0
var kills: int = 0
var _shake: float = 0.0
var _pickups: Array[Node3D] = []
var _pointers: Dictionary = {}
var _pause_request_pending: bool = false
var _last_tap_time: int = -1000
var _last_tap_position := Vector2.ZERO
# Store the completed swipe endpoint in viewport fractions so resizing stays consistent.
var _swipe_end_normalized := Vector2(0.5, 0.5)
var _input_sequence: int = 0
var _last_input_observation: Dictionary = {}
const CAMERA_OFFSET: Vector3 = Vector3(0, 18, 13)
# Exponential follow: a distant player pulls faster; approach eases without
# changing camera angle, controller motion or the screen-space aim anchor.
const CAMERA_FOLLOW_TIME_S: float = 0.16
var _camera_focus: Vector3 = Vector3.ZERO
var last_camera_framing_error: String = ""
var _camera_framing_state: Dictionary = {"enabled": false, "accepted": true, "reason": ""}

func _ready() -> void:
	_build_view()
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--level-scene":
			push_error("Use --level-scene=res://...tscn")
			get_tree().quit(2)
			return
		if argument.begins_with("--level-scene="):
			level_scene_path = argument.trim_prefix("--level-scene=")
			if level_scene_path.is_empty():
				push_error("--level-scene requires a res://...tscn path")
				get_tree().quit(2)
				return
	if not load_level_scene(level_scene_path):
		push_error(level_load_error)
		get_tree().quit(2)
		return
	hud = HUDScript.new()
	add_child(hud)
	hud.setup()
	hud.restart_requested.connect(reset_lab)
	hud.start_requested.connect(resume_lab)
	hud.bench_requested.connect(open_bench)
	bench = BenchScript.new()
	add_child(bench)
	bench.resume_requested.connect(resume_lab)
	bench.item_requested.connect(func(id: String) -> void: player.equip_item(id))
	bench.exercise_requested.connect(choose_exercise)
	reset_lab()
	if "--capture" in OS.get_cmdline_user_args():
		_capture_preview()
	elif "--capture-polish" in OS.get_cmdline_user_args():
		if not is_lab_level():
			push_error("--capture-polish requires the default lab; use --capture for a level preview")
			get_tree().quit(2)
			return
		_capture_polish()

func _build_view() -> void:
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.stretch_shrink = 2
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(270, 585)
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
	settings.background_color = Color(0.035, 0.04, 0.05)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.76, 0.78, 0.80)
	settings.ambient_light_energy = 0.7
	environment.environment = settings
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -25, 0)
	light.light_color = Color(0.96, 0.98, 1.0)
	light.light_energy = 1.0
	world.add_child(light)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 7.2
	camera.position = Vector3(0, 18, 13)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	fx = EffectsScript.new()
	world.add_child(fx)

func is_lab_level() -> bool:
	return _selected_level_scene == null

func load_level_scene(scene_path: String) -> bool:
	# Validate before changing selection, so a rejected request preserves the
	# current preview. Invalid startup CLI requests instead exit with code 2.
	level_load_error = ""
	var selected: PackedScene
	if not scene_path.is_empty():
		if not scene_path.begins_with("res://") or not scene_path.ends_with(".tscn") or not ResourceLoader.exists(scene_path, "PackedScene"):
			level_load_error = "Level scene must be an existing res://...tscn: " + scene_path
			return false
		selected = load(scene_path) as PackedScene
		if selected == null:
			level_load_error = "Could not load level scene: " + scene_path
			return false
		var candidate: Node = selected.instantiate()
		if not candidate is CinderLevel:
			level_load_error = "Level root must extend CinderLevel: " + scene_path
		else:
			level_load_error = (candidate as CinderLevel).contract_error()
		if candidate != null:
			candidate.free()
		if not level_load_error.is_empty():
			return false
	_selected_level_scene = selected
	level_scene_path = scene_path
	if is_instance_valid(hud):
		reset_lab()
	return true

func _create_level_instance() -> CinderLevel:
	if _selected_level_scene != null:
		return _selected_level_scene.instantiate() as CinderLevel
	# Adapt the existing lab without changing its authored floor or obstacles.
	var level := LevelScript.new() as CinderLevel
	level.name = "CharacterLab"
	level.add_child(LabScene.instantiate())
	var spawn := Marker3D.new()
	spawn.name = "PlayerSpawn"
	spawn.position = player_start
	level.add_child(spawn)
	return level

func reset_lab() -> void:
	var loadout: Dictionary = player.equipment.snapshot() if is_instance_valid(player) else {}
	get_tree().paused = false
	if is_instance_valid(bench):
		bench.visible = false
	if is_instance_valid(active_level):
		active_level.exit_level()
		world.remove_child(active_level)
		active_level.queue_free()
	fx.clear_lab()
	if is_instance_valid(player):
		world.remove_child(player)
		player.queue_free()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not world.is_ancestor_of(enemy):
			continue
		enemy.get_parent().remove_child(enemy)
		enemy.queue_free()
	for target in get_tree().get_nodes_in_group("practice_targets"):
		if not world.is_ancestor_of(target):
			continue
		target.get_parent().remove_child(target)
		target.queue_free()
	for candidate in get_tree().get_nodes_in_group("lab_weapons"):
		if not world.is_ancestor_of(candidate):
			continue
		candidate.get_parent().remove_child(candidate)
		candidate.queue_free()
	for pickup: Node3D in _pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()
	_pickups.clear()
	_pointers.clear()
	_last_tap_time = -1000
	_swipe_end_normalized = Vector2(0.5, 0.5)
	_input_sequence = 0
	_last_input_observation.clear()
	cores = 0
	kills = 0
	_enemy_count = 0
	active_level = _create_level_instance()
	world.add_child(active_level)
	player = PlayerScene.instantiate()
	if not active_level.level_id.is_empty():
		player.set_presentation(LabSprite.presentation_for_act(int(active_level.level_id.substr(1, 1))))
	if not loadout.is_empty():
		player.equipment.restore(loadout)
	player.name = "Player"
	player.fx = fx
	world.add_child(player)
	player.global_position = active_level.spawn_position()
	# RESET is an explicit fresh preview/exercise, with full HP/ammo and supplies.
	player.hp = player.max_hp
	_shake = 0.0
	_update_camera(0.0, true)
	player.fired.connect(_on_fired)
	player.died.connect(func() -> void: hud.show_end(false, cores))
	player.equipment_changed.connect(func(id: String) -> void: hud.flash_message("Equipped " + player.equipment.item_name(id)))
	active_level.enter_level(player, fx, self)
	hud.set_level_preview(not is_lab_level())
	if is_lab_level():
		_build_lab_exercise()
	hud.hide_overlay()

func _build_lab_exercise() -> void:
	match lab_mode:
		"duel":
			_enemy_count = 1
			_spawn_enemy(Vector3(0, 0.1, -2.8), 0)
		"arena":
			_enemy_count = 3
			_spawn_enemy(Vector3(-2.8, 0.1, -3.0), 0)
			_spawn_enemy(Vector3(3.0, 0.1, -3.0), 1)
			_spawn_enemy(Vector3(4, 0.1, 5.0), 2)
		_:
			_enemy_count = 0
			for point: Vector3 in practice_target_positions:
				var target := TargetScene.instantiate() as Node3D
				world.add_child(target)
				target.global_position = point
	_build_weapon_candidates()

func _build_weapon_candidates() -> void:
	for index: int in range(3):
		var pickup := WeaponPickupScript.new()
		pickup.item_id = "WEAPON-%02d" % (index + 2)
		pickup.title = player.equipment.item_name(pickup.item_id)
		pickup.hero = player
		world.add_child(pickup)
		pickup.add_to_group("lab_weapons")
		pickup.global_position = weapon_candidate_positions[index] if index < weapon_candidate_positions.size() else Vector3(-2.7 + float(index) * 2.7, 0, 5.2)

func request_pause_deferred() -> bool:
	## A callback may request a coherent pause, but must not stop later native
	## physics consumers/presentation in the same tick. Deferred flush freezes
	## after that tick; recognizer input is consumed immediately.
	if not is_inside_tree() or not is_instance_valid(player) or _pause_request_pending:
		return false
	_pause_request_pending = true
	_clear_gesture_chain()
	_finish_pause_request.call_deferred()
	return true

func is_pause_requested() -> bool:
	return _pause_request_pending

func _finish_pause_request() -> void:
	if not _pause_request_pending:
		return
	_pause_request_pending = false
	if is_inside_tree() and is_instance_valid(player):
		_pause_at_barrier()

func _pause_at_barrier() -> void:
	if player.dead:
		# The completed fatal tick remains dead; never replace its end UI or heal.
		get_tree().paused = true
		_clear_gesture_chain()
	else:
		open_bench()

func open_bench() -> void:
	if player.dead:
		return
	_clear_gesture_chain()
	get_tree().paused = true
	if is_lab_level():
		bench.show_bench(player, get_tree().get_nodes_in_group("enemies").is_empty())
	else:
		hud.show_pause()

func resume_lab() -> void:
	if _pause_request_pending:
		return
	_clear_gesture_chain()
	bench.visible = false
	hud.hide_overlay()
	get_tree().paused = false

func choose_exercise(mode: String) -> void:
	if not is_lab_level() or mode not in ["targets", "duel", "arena"]:
		return
	lab_mode = mode
	reset_lab()

func _clear_gesture_chain() -> void:
	_pointers.clear()
	_last_tap_time = -1000
	_last_tap_position = Vector2.ZERO

func _notification(what: int) -> void:
	if "--capture" in OS.get_cmdline_user_args() or "--capture-polish" in OS.get_cmdline_user_args():
		return
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_instance_valid(bench) and is_instance_valid(player) and not player.dead:
			open_bench()

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
	var objective: String = "SAFE TARGETS  /  LOADOUT TO COMPARE GEAR" if lab_mode == "targets" else "ENEMIES DOWN %d / %d" % [kills, _enemy_count]
	if not is_lab_level():
		objective = active_level.objective_text
	hud.update_status(player.hp, player.max_hp, player.shells, player.max_shells, cores, objective)
	hud.update_lab(player, get_aim_anchor(), is_lab_level() and lab_mode == "targets")
	# Fit against the HUD that this frame actually renders, including a newly
	# wrapped objective. Never use the previous frame's smaller protected area.
	_update_camera(delta)
	if _shake > 0.0:
		camera.position.x += randf_range(-0.035, 0.035)
		camera.position.z += randf_range(-0.035, 0.035)

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(player) or player.dead or get_tree().paused or _pause_request_pending:
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
	var is_swipe: bool = pointer["dashed"] or start.distance_to(pos) >= _swipe_threshold()
	if is_swipe:
		if not pointer["dashed"]:
			player.request_dash(screen_to_direction(pos - start))
		_record_swipe_end(pos)
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

func _record_swipe_end(screen_pos: Vector2) -> void:
	var size: Vector2 = get_viewport().get_visible_rect().size
	_swipe_end_normalized = screen_pos / size
	_last_tap_time = -1000
	aim_anchor_changed.emit(_swipe_end_normalized)
	_observe_input("swipe_release", screen_pos, Vector3.ZERO, false)

func get_input_observation_state() -> Dictionary:
	return {"schema_version": 1, "anchor_normalized": _swipe_end_normalized, "sequence": _input_sequence, "last_observation": _last_input_observation.duplicate(true)}

func get_aim_anchor_normalized() -> Vector2:
	return _swipe_end_normalized

func _observe_input(kind: String, screen_pos: Vector2, direction: Vector3, accepted: bool) -> void:
	_input_sequence += 1
	var records: Array[Dictionary] = player.get_world_action_records() if is_instance_valid(player) else []
	_last_input_observation = {
		"schema_version": 1, "sequence": _input_sequence, "kind": kind,
		"screen_position_normalized": screen_pos / get_viewport().get_visible_rect().size,
		"anchor_normalized": _swipe_end_normalized, "direction": direction,
		"accepted": accepted, "world_action_sequence": 0 if records.is_empty() else int(records.back().sequence),
		"action_clock_s": player.get_world_action_clock() if is_instance_valid(player) else 0.0,
	}
	input_observed.emit(_last_input_observation.duplicate(true))

func get_aim_anchor() -> Vector2:
	return _swipe_end_normalized * get_viewport().get_visible_rect().size

func aim_direction(tap_screen: Vector2) -> Vector3:
	return screen_to_direction(tap_screen - get_aim_anchor())

func _update_camera(delta: float, snap: bool = false) -> void:
	if not is_instance_valid(player):
		return
	var focus: Vector3 = player.global_position + Vector3.UP * 0.75
	if snap:
		_camera_focus = focus
	else:
		var follow_weight: float = 1.0 - exp(-maxf(delta, 0.0) / CAMERA_FOLLOW_TIME_S)
		_camera_focus = _camera_focus.lerp(focus, follow_weight)
	last_camera_framing_error = ""
	_camera_framing_state = {"enabled": false, "accepted": true, "reason": ""}
	if is_instance_valid(active_level):
		var points: Array = active_level.camera_framing_points()
		if not active_level.last_camera_framing_error.is_empty():
			last_camera_framing_error = active_level.last_camera_framing_error
			_camera_framing_state = {"enabled": true, "accepted": false, "reason": last_camera_framing_error}
		elif not points.is_empty():
			var planned: Dictionary = camera_framing_plan(points, _camera_focus)
			_camera_framing_state = planned.duplicate(true)
			_camera_framing_state.enabled = true
			if planned.accepted:
				_camera_focus = planned.focus
			else:
				last_camera_framing_error = planned.reason
	# Shake is applied after this unshaken position so it cannot accumulate into
	# follow lag. The orientation set in _build_view stays fixed throughout.
	camera.global_position = _camera_focus + CAMERA_OFFSET

## These views never alter camera, inputs, actor/resources, clocks or leases.
## A possible future fit does not authorize damage in a currently clipped view.
func camera_framing_plan(points: Array, desired_focus: Vector3) -> Dictionary:
	if not is_instance_valid(camera) or not is_instance_valid(player) or not is_instance_valid(hud):
		return {"accepted": false, "reason": "Ready shared camera/player/HUD required"}
	var projection_error: String = _camera_projection_error()
	if not projection_error.is_empty():
		return {"accepted": false, "reason": projection_error}
	var mandatory: Array = player_camera_framing_points()
	if mandatory.is_empty():
		return {"accepted": false, "reason": "Actual player render/collision bounds unavailable"}
	var required: Array = points.duplicate()
	required.append_array(mandatory)
	return CameraFraming.plan(required, desired_focus, _camera_framing_spec(0.055))

func camera_framing_error(points: Array) -> String:
	if not is_instance_valid(camera) or not is_instance_valid(player) or not is_instance_valid(hud):
		return "Ready shared camera/player/HUD required"
	var projection_error: String = _camera_projection_error()
	if not projection_error.is_empty():
		return projection_error
	var mandatory: Array = player_camera_framing_points()
	if points.is_empty() or mandatory.is_empty():
		return "Actual required source and player bounds must be supplied"
	var required: Array = points.duplicate()
	required.append_array(mandatory)
	# The plan reserves max shake + pixel margin. Current projection needs the
	# pixel margin, including any shake already present in camera.position.
	return CameraFraming.containment(required, camera.global_position - CAMERA_OFFSET, _camera_framing_spec(0.02))

func get_camera_framing_state() -> Dictionary:
	return _camera_framing_state.duplicate(true)

func _camera_framing_spec(margin: float) -> Dictionary:
	return {"basis": camera.global_basis, "offset": CAMERA_OFFSET, "width": camera.size, "viewport_size": Vector2(camera.get_viewport().size), "safe_rect": hud.combat_safe_rect(), "max_shift": 3.6, "safety_margin": margin, "near": camera.near, "far": camera.far}

func _camera_projection_error() -> String:
	if camera.projection != Camera3D.PROJECTION_ORTHOGONAL or camera.keep_aspect != Camera3D.KEEP_WIDTH or camera.h_offset != 0.0 or camera.v_offset != 0.0 or camera.frustum_offset != Vector2.ZERO:
		return "Shared orthographic KEEP_WIDTH camera with zero projection offsets required"
	return ""

## The common player uses one capsule and an enabled Z-axis billboard. Include
## its real full quad (not billboard's inflated culling sphere) and foot shadow.
func player_camera_framing_points() -> Array:
	if not is_instance_valid(player) or not is_instance_valid(camera):
		return []
	var collision := player.get_node_or_null("BodyCollision") as CollisionShape3D
	var sprite := player.get_node_or_null("ActorSprite") as Sprite3D
	var shadow := player.get_node_or_null("ContactShadow") as MeshInstance3D
	if collision == null or not collision.shape is CapsuleShape3D or sprite == null or shadow == null or shadow.mesh == null:
		return []
	var capsule := collision.shape as CapsuleShape3D
	var points: Array = _camera_box_points(AABB(Vector3(-capsule.radius, -capsule.height * 0.5, -capsule.radius), Vector3(capsule.radius * 2.0, capsule.height, capsule.radius * 2.0)), collision.global_transform)
	var quad: Array = camera_billboard_points(sprite)
	if quad.is_empty():
		return []
	points.append_array(quad)
	points.append_array(_camera_box_points(shadow.get_aabb(), shadow.global_transform))
	return points

## Standard enabled Z-axis Sprite3D only; full native quad is conservative.
## Atlas margins, fixed-size or custom-shader billboards need explicit verified
## owner corners. Empty is rejection, never a physical-proxy fallback.
func camera_billboard_points(sprite: Sprite3D) -> Array:
	if not is_instance_valid(camera) or not is_instance_valid(sprite) or not sprite.is_inside_tree() or sprite.texture == null or sprite.texture is AtlasTexture or sprite.billboard != BaseMaterial3D.BILLBOARD_ENABLED or sprite.axis != Vector3.AXIS_Z or sprite.fixed_size or sprite.region_enabled or sprite.hframes != 1 or sprite.vframes != 1 or sprite.material_override != null or sprite.material_overlay != null:
		return []
	var scale: Vector3 = sprite.global_basis.get_scale()
	if not scale.is_finite() or scale.x <= 0.0 or scale.y <= 0.0 or scale.z <= 0.0:
		return []
	var mesh: TriangleMesh = sprite.generate_triangle_mesh()
	if mesh == null:
		return []
	var result: Array = []
	for vertex: Vector3 in mesh.get_faces():
		result.append(sprite.global_position + camera.global_basis.x * vertex.x * scale.x + camera.global_basis.y * vertex.y * scale.y)
	return result

func _camera_box_points(bounds: AABB, transform: Transform3D) -> Array:
	var result: Array = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]:
				result.append(transform * Vector3(x, y, z))
	return result

func handle_tap(screen_pos: Vector2) -> void:
	if get_tree().paused or _pause_request_pending or not is_instance_valid(player) or player.dead:
		return
	# Aim is relative to the final finger position of the last completed swipe.
	var direction: Vector3 = aim_direction(screen_pos)
	var now: int = Time.get_ticks_msec()
	var before: Array[Dictionary] = player.get_world_action_records()
	var sequence_before: int = 0 if before.is_empty() else int(before.back().sequence)
	var kind: String = "primary_tap"
	if now - _last_tap_time <= 280 and screen_pos.distance_to(_last_tap_position) < 90:
		player.blast(direction)
		_last_tap_time = -1000
		kind = "blast_tap"
	else:
		player.slash(direction)
		_last_tap_time = now
		_last_tap_position = screen_pos
	var after: Array[Dictionary] = player.get_world_action_records()
	var accepted: bool = not after.is_empty() and int(after.back().sequence) > sequence_before
	_observe_input(kind, screen_pos, player.facing if direction.is_zero_approx() else direction, accepted)

func _on_fired(kind: String) -> void:
	_shake = 0.12 if kind == "blast" else 0.035

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
	if not is_lab_level():
		await get_tree().create_timer(0.5).timeout
		resume_lab()
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
		get_viewport().get_texture().get_image().save_png("res://captures/level-preview.png")
		get_tree().quit()
		return
	await get_tree().create_timer(0.5).timeout
	resume_lab()
	player.facing = Vector3.BACK
	player._sprite.face(player.facing)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	get_viewport().get_texture().get_image().save_png("res://captures/character-lab.png")
	player.slash(Vector3.FORWARD)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://captures/character-primary.png")
	await get_tree().create_timer(0.34).timeout
	player.blast(Vector3.FORWARD)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://captures/character-blast.png")
	await get_tree().create_timer(0.48).timeout
	player.request_dash(Vector3(1, 0, -0.5))
	await get_tree().create_timer(0.07).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://captures/mechanics-lab.png")
	await get_tree().create_timer(0.2).timeout
	open_bench()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://captures/loadout-bench.png")
	choose_exercise("duel")
	var enemy: AshEnemy = get_tree().get_nodes_in_group("enemies")[0]
	enemy.global_position = player.global_position + Vector3(0, 0, -1.7)
	await get_tree().create_timer(0.22).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://captures/enemy-warning.png")
	await get_tree().create_timer(0.80).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://captures/enemy-recovery.png")
	get_tree().quit()


func _capture_polish() -> void:
	# Run with --fixed-fps 30 -- --capture-polish. Every PNG is a rendered Godot
	# frame; real player physics, action clocks and effect simulation keep running.
	await get_tree().create_timer(0.5).timeout
	choose_exercise("targets")
	player.facing = Vector3.BACK
	player._sprite.face(player.facing)
	var output_dir: String = "res://captures/polish"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	for frame_index: int in range(120):
		if frame_index == 6:
			player.request_dash(Vector3.RIGHT)
		elif frame_index == 45:
			player.slash(Vector3.BACK)
		elif frame_index == 68:
			player.blast(Vector3.RIGHT)
		elif frame_index == 90:
			player.blast(Vector3.LEFT)
		await RenderingServer.frame_post_draw
		var rendered: Image = get_viewport().get_texture().get_image()
		rendered.save_png("%s/frame-%03d.png" % [output_dir, frame_index])
		if frame_index == 9:
			rendered.save_png("res://captures/dash-plume-mid.png")
		elif frame_index == 14:
			rendered.save_png("res://captures/dash-plume-end.png")
		elif frame_index == 47:
			rendered.save_png("res://captures/slash-arc.png")
		elif frame_index == 68:
			rendered.save_png("res://captures/shot-flare-right.png")
		elif frame_index == 90:
			rendered.save_png("res://captures/shot-flare-left.png")
		await get_tree().process_frame
	get_tree().quit()
