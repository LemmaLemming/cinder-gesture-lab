extends SceneTree

const EffectsScript: GDScript = preload("res://scripts/effects.gd")
const FlareScript: GDScript = preload("res://scripts/shotgun_flare.gd")
const PlayerScript: GDScript = preload("res://scripts/player.gd")
const EnemyScript: GDScript = preload("res://scripts/enemy.gd")

var _failures: int = 0
var _checks: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var arena := Node3D.new()
	root.add_child(arena)
	_world_box(arena, Vector3(0, -0.5, 0), Vector3(40, 1, 40))
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 7.2
	arena.add_child(camera)
	camera.global_position = Vector3(0, 18, 13)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var effects: PixelEffects = EffectsScript.new()
	arena.add_child(effects)
	await _dash_checks(arena, effects, camera)
	await _arc_checks(effects)
	await _flare_checks(arena, effects, camera)
	await _blood_checks(arena, effects)
	await _gameplay_checks(arena, effects)
	for index: int in range(80):
		effects.dash_trail(Vector3.ZERO, Vector3.RIGHT)
		effects.slash(Vector3.ZERO, Vector3.RIGHT, Color.WHITE)
		effects.muzzle(Vector3.ZERO, Vector3.RIGHT)
	_expect(effects.active_transient_count() <= PixelEffects.MAX_TRANSIENTS, "rapid mixed plume/arc/flare effects stay within the shared transient budget")
	await create_timer(0.95).timeout
	_expect(effects.active_transient_count() == 0 and get_nodes_in_group("decorative_smoke").is_empty() and get_nodes_in_group("cosmetic_slash_arcs").is_empty() and get_nodes_in_group("shotgun_flares").is_empty(), "all bounded decorative effects retire after active-simulation deadlines")
	effects.dash_trail(Vector3.ZERO, Vector3.RIGHT)
	effects.slash(Vector3.ZERO, Vector3.RIGHT, Color.WHITE)
	effects.muzzle(Vector3.ZERO, Vector3.RIGHT)
	effects.tiny_bleed(Vector3.ZERO)
	effects.clear_lab()
	await process_frame
	_expect(effects.active_transient_count() == 0 and get_nodes_in_group("decorative_smoke").is_empty() and get_nodes_in_group("shotgun_flares").is_empty() and get_nodes_in_group("tiny_blood_particles").is_empty(), "exercise reset coherently removes plumes, arcs, flares and blood")
	arena.queue_free()
	await process_frame
	print("Visual effects smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _dash_checks(arena: Node3D, effects: PixelEffects, camera: Camera3D) -> void:
	var directions: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3(1, 0, 1), Vector3(-1, 0, 1), Vector3(1, 0, -1), Vector3(-1, 0, -1)]
	for index: int in range(directions.size()):
		var player: CinderPlayer = _player(arena, effects)
		await create_timer(0.06).timeout
		var start: Vector3 = player.global_position
		var accepted: bool = player.request_dash(directions[index])
		var plumes: Array[Node] = get_nodes_in_group("decorative_dash_plume")
		_expect(accepted and plumes.size() == 1, "dash%d creates exactly one plume at acceptance" % index)
		if plumes.size() != 1:
			player.queue_free()
			effects.clear_lab()
			await process_frame
			continue
		var plume: Node3D = plumes[0] as Node3D
		var plume_id: int = plume.get_instance_id()
		var single_through_ticks: bool = true
		for tick: int in range(12):
			await physics_frame
			var live: Array[Node] = get_nodes_in_group("decorative_dash_plume")
			single_through_ticks = single_through_ticks and live.size() == 1 and live[0].get_instance_id() == plume_id
		await create_timer(0.025).timeout
		_expect(single_through_ticks, "dash%d never adds short-puff emitters across physics ticks" % index)
		var travel: Vector3 = player.global_position - start
		travel.y = 0.0
		var trail_length: float = float(plume.get("trail_length_world"))
		_expect(absf(travel.length() - 2.7) < 0.03 and absf(trail_length - travel.length()) < 0.04, "dash%d long plume spans the actual fixed dash path" % index)
		var path: Vector3 = -travel
		var projected: Vector3 = camera.global_basis.x * path.dot(camera.global_basis.x) + camera.global_basis.y * path.dot(camera.global_basis.y)
		var axis: Vector3 = plume.get("projected_axis")
		_expect(axis.dot(projected.normalized()) > 0.999 and absf(float(plume.get("projected_length_world")) - projected.length()) < 0.04, "dash%d plume aligns with projected travel including vertical and diagonal swipes" % index)
		var sprite: Sprite3D = plume.get_node("PixelSmoke") as Sprite3D
		var texture: Image = sprite.texture.get_image()
		_expect(texture.get_width() == 80 and texture.get_height() == 32 and _largest_connected_ratio(texture) > 0.90, "dash%d is one connected long pixel volume rather than isolated puffs" % index)
		_expect(sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST and not sprite.no_depth_test and sprite.render_priority < 0 and not _has_collision(plume), "dash%d decorative plume preserves nearest filtering, world occlusion and collision-free cue order" % index)
		if index == 0:
			paused = true
			var frozen_elapsed: float = float(plume.get("elapsed"))
			var frozen_frame: int = int(plume.get("frame_index"))
			var frozen_head: Vector3 = plume.get("head_world")
			await create_timer(0.12).timeout
			_expect(_near(plume.get("elapsed"), frozen_elapsed) and int(plume.get("frame_index")) == frozen_frame and (plume.get("head_world") as Vector3).is_equal_approx(frozen_head), "pause freezes plume flow, tracking and dissipation")
			paused = false
			player.request_dash(Vector3.LEFT)
			await create_timer(0.20).timeout
			_expect(get_nodes_in_group("decorative_dash_plume").size() == 2 and (plume.get("head_world") as Vector3).distance_to(frozen_head) < 0.01, "one buffered dash adds one new plume while the earlier plume keeps its latched landing")
		player.queue_free()
		effects.clear_lab()
		await process_frame
	# Simulate one long render frame before the physics controller has completed
	# its dash. Rendering may advance the artwork, but cannot latch the landing.
	var slow_render_player: CinderPlayer = _player(arena, effects)
	await create_timer(0.06).timeout
	slow_render_player.request_dash(Vector3.RIGHT)
	var slow_render_plume: Node3D = get_nodes_in_group("decorative_dash_plume")[0] as Node3D
	var attachment_offset: Vector3 = (slow_render_plume.get("head_world") as Vector3) - slow_render_player.global_position
	slow_render_plume.set_process(false)
	slow_render_plume.call("_process", 0.30)
	_expect(bool(slow_render_plume.get("emitter_tracking")), "a long render frame cannot retire physics-owned plume tracking before dash completion")
	await create_timer(0.24).timeout
	# The assertion concerns the actual final physics sample. Under load a
	# render timer can elapse while bounded physics catch-up is still in progress.
	for tick: int in range(24):
		if not slow_render_player.action_in_progress():
			break
		await physics_frame
	var final_head: Vector3 = slow_render_plume.get("head_world")
	_expect(not bool(slow_render_plume.get("emitter_tracking")) and final_head.distance_to(slow_render_player.global_position + attachment_offset) < 0.01 and absf(float(slow_render_plume.get("trail_length_world")) - 2.7) < 0.03, "final physics sample latches the real full landing after a long render frame")
	slow_render_player.queue_free()
	effects.clear_lab()
	await process_frame
	# A wall must shorten the visual path to the collision stop.
	var player: CinderPlayer = _player(arena, effects)
	var wall: StaticBody3D = _world_box(arena, Vector3(1.5, 1, 0), Vector3(0.25, 2, 4))
	await create_timer(0.06).timeout
	player.request_dash(Vector3.RIGHT)
	await create_timer(0.24).timeout
	var clipped: Node3D = get_nodes_in_group("decorative_dash_plume")[0] as Node3D
	_expect(player.global_position.x < 1.2 and absf(float(clipped.get("trail_length_world")) - player.global_position.x) < 0.04, "blocked dash plume ends at the real collision stop instead of inventing a full-length landing")
	player.queue_free()
	wall.queue_free()
	effects.clear_lab()
	await process_frame

func _arc_checks(effects: PixelEffects) -> void:
	effects.slash(Vector3(0, 0.65, 0), Vector3(1, 0, -1).normalized(), Color(0.94, 0.86, 0.82))
	var arcs: Array[Node] = get_nodes_in_group("cosmetic_slash_arcs")
	_expect(arcs.size() == 1 and get_nodes_in_group("decorative_smoke").is_empty(), "slash restores one eight-segment arc without emitting three smoke puffs")
	if arcs.is_empty():
		return
	var arc: Node3D = arcs[0] as Node3D
	var segments: int = 0
	for child: Node in arc.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh is BoxMesh:
			segments += 1
	_expect(segments == 8 and not _has_collision(arc), "restored slash arc contains the original eight cosmetic prism segments and no collider")
	var original_rotation: Vector3 = arc.rotation
	await create_timer(0.15).timeout
	_expect(is_instance_valid(arc) and float(arc.get_meta("lifetime")) >= 0.28 and arc.rotation.distance_to(original_rotation) > 0.08, "arc visibly sweeps and remains active beyond the old short slash lifetime")
	paused = true
	var frozen_rotation: Vector3 = arc.rotation
	var frozen_scale: Vector3 = arc.scale
	await create_timer(0.12).timeout
	_expect(arc.rotation.is_equal_approx(frozen_rotation) and arc.scale.is_equal_approx(frozen_scale), "pause freezes the slower arc sweep and return")
	paused = false
	await create_timer(0.18).timeout
	_expect(get_nodes_in_group("cosmetic_slash_arcs").is_empty(), "slower slash arc still retires within its bounded lifetime")

func _flare_checks(arena: Node3D, effects: PixelEffects, camera: Camera3D) -> void:
	var frames: Array[Texture2D] = FlareScript.frames()
	_expect(frames.size() == 10 and frames[0].get_width() == 36 and frames[0].get_height() == 24, "shotgun flare has ten crisp native36x24 animation frames")
	var first: Image = frames[0].get_image()
	var expanded: Image = frames[3].get_image()
	var core: Color = first.get_pixel(2, 12)
	_expect(core.r > 0.95 and core.g > 0.90 and core.b > 0.80 and core.a > 0.95, "shot begins with a brilliant warm-white barrel core")
	_expect(int(_image_stats(expanded)["max_x"]) > int(_image_stats(first)["max_x"]) + 5 and int(_image_stats(expanded)["min_x"]) >= 2 and float(_image_stats(frames[9].get_image())["mass"]) == 0.0, "flare expands and fans away from its fixed source, then fully disappears")
	var directions: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3(1, 0, 1), Vector3(-0.37, 0, 0.93)]
	for index: int in range(directions.size()):
		var player: CinderPlayer = _player(arena, effects)
		player.position = Vector3(1.7 + float(index) * 0.2, 0.02, -1.1)
		player.set_physics_process(false)
		# Begin the shot after resource creation has crossed a frame boundary.
		# A constructor's work is not part of the accepted shot's visual clock.
		await create_timer(0.04).timeout
		player.blast(directions[index])
		var flares: Array[Node] = get_nodes_in_group("shotgun_flares")
		_expect(flares.size() == 1, "shot%d emits exactly one animated flare" % index)
		if flares.is_empty():
			player.queue_free()
			effects.clear_lab()
			await process_frame
			continue
		var flare: Node3D = flares[0] as Node3D
		var actor: LabSprite = player.get_node("ActorSprite") as LabSprite
		var tip: Vector3 = actor.get_muzzle_world_position(camera)
		var pixel: Vector2i = actor.get_muzzle_pixel_position()
		var native_offset: Vector2 = Vector2(float(pixel.x) + 0.5 - 24.0, 64.0 - float(pixel.y) - 0.5) * 0.0225
		var delta: Vector3 = tip - actor.global_position
		var projected_offset: Vector2 = Vector2(delta.dot(camera.global_basis.x), delta.dot(camera.global_basis.y))
		var endpoint_visible: bool = actor.texture.get_image().get_pixel(pixel.x, pixel.y).a > 0.9
		_expect(projected_offset.distance_to(native_offset) < 0.001 and endpoint_visible and (flare.get("origin") as Vector3).distance_to(tip) < 0.001, "shot%d starts at the actual rendered barrel pixel for its front/back/left/right pose" % index)
		var expected: Vector3 = directions[index].normalized()
		var direction: Vector3 = flare.get("direction")
		var screen_delta: Vector2 = camera.unproject_position(tip + expected) - camera.unproject_position(tip)
		var screen_direction: Vector2 = flare.get("screen_direction")
		var expected_screen: Vector2 = Vector2(screen_delta.x, -screen_delta.y).normalized()
		_expect(direction.dot(expected) > 0.99999 and screen_direction.dot(expected_screen) > 0.99999, "shot%d flare follows exact continuous aim without snapping to artwork facing" % index)
		var sprite: Sprite3D = flare.get_node("FlareSprite") as Sprite3D
		var source_local: Vector3 = Vector3((2.5 - 18.0 + sprite.offset.x) * sprite.pixel_size, (12.0 - 12.5 + sprite.offset.y) * sprite.pixel_size, 0.0)
		var source_world: Vector3 = sprite.global_transform * source_local
		_expect(camera.unproject_position(source_world).distance_to(camera.unproject_position(tip)) < 0.01 and sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST and not sprite.no_depth_test and not _has_collision(flare), "shot%d visible flare origin stays on the barrel with depth-tested collision-free artwork" % index)
		if index == 0:
			player.position.x += 0.12
			await create_timer(0.030).timeout
			var source_error: float = (flare.get("origin") as Vector3).distance_to(actor.get_muzzle_world_position(camera))
			if source_error >= 0.002 or int(flare.get("frame_index")) == 0:
				print("Flare tracking diagnostic: elapsed=", flare.get("elapsed"), "; source error=", source_error, "; frame=", flare.get("frame_index"))
			_expect(source_error < 0.002 and int(flare.get("frame_index")) > 0, "early recoil tracking follows the real attached barrel while animation advances")
			paused = true
			var frozen_elapsed: float = float(flare.get("elapsed"))
			var frozen_frame: int = int(flare.get("frame_index"))
			var frozen_origin: Vector3 = flare.get("origin")
			await create_timer(0.12).timeout
			_expect(_near(flare.get("elapsed"), frozen_elapsed) and int(flare.get("frame_index")) == frozen_frame and (flare.get("origin") as Vector3).is_equal_approx(frozen_origin), "pause freezes barrel tracking, flare frames and cleanup")
			paused = false
			await create_timer(0.05).timeout
			var released_origin: Vector3 = flare.get("origin")
			player.position.x += 0.3
			await create_timer(0.035).timeout
			_expect((flare.get("origin") as Vector3).distance_to(released_origin) < 0.001 and (flare.get("direction") as Vector3).dot(expected) > 0.99999, "released flare retains its sampled source and exact direction when the actor moves again")
		player.queue_free()
		effects.clear_lab()
		await process_frame

func _blood_checks(arena: Node3D, effects: PixelEffects) -> void:
	effects.tiny_bleed(Vector3(0, 0.8, 0), 3, Vector3.RIGHT * 20)
	_expect(effects.active_blood_count() == 3 and effects.active_chunk_count() == 0, "blood remains three tiny flecks rather than an explosive debris burst")
	var tiny_dimensions: bool = true
	for particle: Node in get_nodes_in_group("tiny_blood_particles"):
		var visual: MeshInstance3D = particle.get_child(0) as MeshInstance3D
		var mesh: BoxMesh = visual.mesh as BoxMesh
		tiny_dimensions = tiny_dimensions and mesh.size.x >= 0.024 and mesh.size.x <= 0.046 and not _has_collision(particle)
	_expect(tiny_dimensions, "blood stays at one source-pixel scale and never collides")
	paused = true
	var blood: Node3D = get_nodes_in_group("tiny_blood_particles")[0] as Node3D
	var frozen_blood: Vector3 = blood.global_position
	await create_timer(0.12).timeout
	_expect(blood.global_position.is_equal_approx(frozen_blood), "pause freezes tiny blood motion and cleanup")
	paused = false
	await create_timer(0.45).timeout
	_expect(effects.active_blood_count() == 0, "tiny blood retires promptly")
	var enemy: AshEnemy = EnemyScript.new()
	enemy.configure(null, effects, 0)
	arena.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.hp = 100
	enemy.take_damage(10, Vector3.RIGHT * 4)
	_expect(effects.active_blood_count() == 3 and effects.active_chunk_count() == 0, "enemy nonlethal damage emits only three tiny flecks")
	effects.clear_lab()
	await process_frame
	enemy.hp = 5
	enemy.take_damage(10, Vector3.RIGHT * 8)
	_expect(effects.active_blood_count() == 5 and effects.active_chunk_count() == 0, "enemy defeat emits five flecks without doubling the hurt effect")
	for index: int in range(10):
		effects.tiny_bleed(Vector3.ZERO, 999, Vector3.ZERO)
	_expect(effects.active_blood_count() <= PixelEffects.MAX_BLOOD_PARTICLES, "repeated bleeding stays within its dedicated small budget")
	effects.clear_lab()
	await process_frame

func _gameplay_checks(arena: Node3D, effects: PixelEffects) -> void:
	var player: CinderPlayer = _player(arena, effects)
	player.set_physics_process(false)
	var enemy: AshEnemy = EnemyScript.new()
	enemy.configure(player, effects, 0)
	arena.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.position = Vector3(1.5, 0.02, 0)
	enemy.hp = 100
	effects.slash(Vector3.ZERO, Vector3.RIGHT, Color.WHITE)
	effects.muzzle(Vector3.ZERO, Vector3.RIGHT)
	_expect(enemy.hp == 100 and player.shells == 2, "cosmetic arc and flare alone never inflict damage or spend ammo")
	var slash_hits: int = player.slash(Vector3.RIGHT)
	_expect(slash_hits == 1 and enemy.hp == 80 and player.shells == 2, "primary damage remains immediate while the restored arc animates")
	var blast_hits: int = player.blast(Vector3.RIGHT)
	_expect(blast_hits == 1 and enemy.hp == 38 and player.shells == 1, "blast damage and one-shell cost remain immediate at flare creation")
	await create_timer(0.34).timeout
	_expect(enemy.hp == 38 and player.shells == 1, "effect animation and retirement never add delayed or repeated damage")
	player.queue_free()
	enemy.queue_free()
	effects.clear_lab()
	await process_frame

func _player(arena: Node3D, effects: PixelEffects) -> CinderPlayer:
	var player: CinderPlayer = PlayerScript.new()
	player.fx = effects
	player.position = Vector3(0, 0.02, 0)
	arena.add_child(player)
	return player

func _world_box(parent: Node3D, pos: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.position = pos
	return body

func _image_stats(image: Image) -> Dictionary:
	var mass: float = 0.0
	var min_x: int = image.get_width()
	var max_x: int = -1
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var alpha: float = image.get_pixel(x, y).a
			mass += alpha
			if alpha > 0.05:
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
	return {"mass": mass, "min_x": min_x, "max_x": max_x}

func _largest_connected_ratio(image: Image) -> float:
	var live: Dictionary = {}
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.08:
				live[Vector2i(x, y)] = true
	var total: int = live.size()
	var largest: int = 0
	while not live.is_empty():
		var first: Vector2i = live.keys()[0]
		var queue: Array[Vector2i] = [first]
		live.erase(first)
		var size: int = 0
		while not queue.is_empty():
			var point: Vector2i = queue.pop_back()
			size += 1
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					var next: Vector2i = point + Vector2i(dx, dy)
					if live.has(next):
						live.erase(next)
						queue.append(next)
		largest = maxi(largest, size)
	return float(largest) / maxf(float(total), 1.0)

func _has_collision(node: Node) -> bool:
	if node is CollisionObject3D or node is CollisionShape3D:
		return true
	for child: Node in node.get_children():
		if _has_collision(child):
			return true
	return false

func _near(actual: Variant, expected: Variant) -> bool:
	return absf(float(actual) - float(expected)) < 0.00001

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
