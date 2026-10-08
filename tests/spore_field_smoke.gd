extends SceneTree
## Real shared-actor environmental attacks and local clock/supply restoration.
## No enemy retreat, authored Selenite acceptance or physical replay is claimed.

const Field = preload("res://scripts/environment/spore_field.gd")
const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")

var _checks: int = 0
var _failures: int = 0
var _capture_path: String = ""


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--spore-capture=res://.cinder/") and argument.ends_with(".png") and not argument.contains("..") and not argument.contains("\\"):
			_capture_path = argument.trim_prefix("--spore-capture=")
	_run.call_deferred()


func _run() -> void:
	_configuration_checks()
	await _actual_attack_checks()
	await _geometry_checks()
	await _snapshot_checks()
	paused = false
	print("Spore field smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _configuration_checks() -> void:
	var field = Field.new()
	_expect(not field.configure("", _specs()) and not field.configure("mushroom", [_specs()[0]]) and not field.configure("mushroom", _specs(), {"damage": 1}), "unknown parameter, missing cluster and unstable instance ID reject before binding")
	for parameters: Dictionary in [{"duration_s": NAN}, {"radius": INF}, {"radius": -1}, {"thinning_s": 3.0}, {"duration_s": 0}, {"thinning_s": -0.1}]:
		_expect(not field.configure("mushroom", _specs(), parameters), "nonfinite or out-of-range provisional field parameters reject atomically")
	_expect(not field.configure("mushroom", [{"id": "same", "offset": Vector3.ZERO}, {"id": "same", "offset": Vector3.RIGHT}]), "duplicate environmental supply IDs reject")
	_expect(not field.configure("mushroom", [{"id": "one", "offset": Vector3.ZERO}, {"id": "two", "offset": Vector3(0.01, 0, 0)}]), "two clusters require visibly distinct anchors")
	_expect(field.configure("mushroom", _specs()) and not field.configure("renamed", _specs()), "complete immutable definition configures once before binding")
	field.free()


func _actual_attack_checks() -> void:
	var arena: Dictionary = await _arena()
	var player: CinderPlayer = arena.player
	var first = _field(arena.world, "first", Vector3(0, 0, -0.65))
	var second = _field(arena.world, "second", Vector3(0.5, 0, -0.65))
	var distant = _field(arena.world, "distant", Vector3(6, 0, -0.65))
	var activations: Array[Dictionary] = []
	var reentrant: Array[bool] = []
	first.activated.connect(func(domain: Dictionary) -> void:
		activations.append(domain.duplicate(true))
		reentrant.append(first.activate_cluster("two"))
		domain.radius = 0.01
	)
	var a: Node3D = first.get_node("one")
	var b: Node3D = first.get_node("two")
	_expect(a.is_in_group("environment_attack_targets") and b.is_in_group("environment_attack_targets") and not a.is_in_group("enemies") and not a.is_in_group("practice_targets") and a.get("hp") == null and not a.has_method("take_damage"), "both separate anchors are environmental receivers without fabricated HP or damage methods")
	player.shells = 1
	player.set("_reload", 0.11)
	var hp: float = player.hp
	var velocity: Vector3 = player.velocity
	var invulnerable: float = player.get("_invulnerable")
	_expect(player.slash(Vector3.FORWARD) == 0 and player.get("_accepted_enemy_hits") == 0 and player.shells == 1 and player.get("_reload") == 0.11, "real primary releases spores but earns zero damage hits/enemy reload credit")
	var deadline: float = first.state().deadline_s
	_expect(first.state().phase == "releasing" and first.state().generation == 1 and first.state().remaining_clusters == 1 and first.active_domain().remaining_s == 3.0 and first.active_domain().radius == 2.025, "hit commits one immediately active finite generation with fixed gear-independent radius")
	_expect(second.state().generation == 1 and distant.state().generation == 0 and activations.size() == 1 and reentrant == [false], "one slash hitting multiple anchors spends once per mushroom; separate mushrooms remain independent and callbacks cannot reenter")
	_expect(player.blast(Vector3.FORWARD) == 0 and player.shells == 0 and player.get("_reload") == 0.0 and first.state().generation == 1 and first.state().deadline_s == deadline and second.state().generation == 1, "real slash-then-blast spends its ordinary shell/reset cost without spending or refreshing any active mushroom")
	_expect(player.hp == hp and player.velocity == velocity and player.get("_invulnerable") == invulnerable and not player.dead, "field activation applies no player HP loss, hurt, invulnerability or impulse")
	var actions: Array[Dictionary] = player.get_world_action_records()
	_expect(actions.size() == 2 and actions[0].kind == "primary" and actions[1].kind == "blast" and actions[0].hits == 0 and actions[1].hits == 0 and not Player.encode_world_action_record(actions[0], player.get_world_action_clock()).is_empty() and not Player.encode_world_action_record(actions[1], player.get_world_action_clock()).is_empty(), "environment interaction produces only the existing canonical primary/blast publications with zero damage hits")
	_expect(first.get_cue_state().clusters[0].state == "spent" and not first.get_cue_state().clusters[0].full and first.get_cue_state().clusters[1].state == "active" and first.get_cue_state().clusters[1].full, "spent supply leaves an empty patch while remaining full supply shows field-active gating")
	var boundary: MeshInstance3D = first.get_node("RequiredBrokenSporeBoundary")
	var material: StandardMaterial3D = boundary.material_override
	var vertices: PackedVector3Array = boundary.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var perimeter_only: bool = true
	for point: Vector3 in vertices:
		perimeter_only = perimeter_only and Vector2(point.x, point.z).length() > 1.9
	_expect(first.is_in_group("required_cues") and not first.is_in_group("cosmetic_effects") and boundary.visible and vertices.size() == 32 * 6 and perimeter_only and material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST and not material.no_depth_test and not first.get_cue_state().danger_fill and not first.get_cue_state().countdown, "required broken boundary has separated perimeter arcs, nearest filtering/depth occlusion and no danger fill/countdown")
	var getter: Dictionary = first.state()
	getter.spent_ids.clear()
	var cue: Dictionary = first.get_cue_state()
	cue.clusters[0].cue.clear()
	_expect(first.state().generation == 1 and first.state().spent_ids.size() == 1 and first.active_domain().radius == 2.025 and not first.get_cue_state().clusters[0].cue.is_empty(), "state/domain/cue/signal copies cannot mutate supplies or logical radius")
	for bad: Dictionary in [{"kind": "primary", "origin": "apparition"}, {"kind": "primary", "origin": "player_direct", "damage": 1}, {"kind": "touch", "origin": "player_direct"}]:
		_expect(not distant.get_node("one").receive_attack(bad).interaction_accepted and distant.state().generation == 0, "only ordinary executed direct-player attack context can activate an environmental anchor")
	await _capture(arena)
	# Confirm an environmental hit is not an extra live enemy or death event.
	var enemy: AshEnemy = Enemy.new()
	arena.world.add_child(enemy)
	enemy.configure(player, null, 0)
	enemy.position = Vector3(0, 0.02, -1.0)
	var deaths: Array = []
	enemy.died.connect(func(_position: Vector3) -> void: deaths.append(true))
	await _ticks(20)
	player.shells = 0
	player.set("_reload", 0.0)
	var old_enemy_hp: float = enemy.hp
	_expect(player.slash(Vector3.FORWARD) == 1 and player.get("_accepted_enemy_hits") == 1 and enemy.hp < old_enemy_hp and enemy.hp > 0.0 and deaths.is_empty() and player.get("_reload") == player.stats.primary_hit_reload_credit, "mixed real-enemy/spore primary counts only direct living-enemy damage and one existing reload credit")
	_expect(first.state().generation == 1 and first.state().deadline_s == deadline, "later ordinary attack during the same active field cannot refresh or spend the other supply")
	await _dispose(arena)


func _geometry_checks() -> void:
	var arena: Dictionary = await _arena()
	var player: CinderPlayer = arena.player
	var forward = _field(arena.world, "forward", Vector3(0, 0, -0.7))
	var behind = _field(arena.world, "behind", Vector3(0, 0, 0.7))
	var high = _field(arena.world, "high", Vector3(0, 2.0, -0.7))
	var far = _field(arena.world, "far", Vector3(0, 0, -6))
	var near_origin = _field(arena.world, "origin-disk", Vector3(0, 0, 0.05), [{"id": "one", "offset": Vector3.ZERO}, {"id": "two", "offset": Vector3(0.25, 0, 0)}])
	player.slash(Vector3.FORWARD)
	_expect(forward.state().generation == 1 and behind.state().generation == 0 and high.state().generation == 0 and far.state().generation == 0 and near_origin.state().spent_ids == ["one"], "environment dispatch shares the actual primary cone, vertical limit, range and near-origin disk exception")
	await _dispose(arena)
	arena = await _arena()
	player = arena.player
	var blocked = _field(arena.world, "blocked", Vector3(0, 0, -1.0))
	_box(arena.world, Vector3(0, 0.8, -0.5), Vector3(2, 1.6, 0.15))
	await _ticks(3)
	player.slash(Vector3.FORWARD)
	player.blast(Vector3.FORWARD)
	_expect(blocked.state().generation == 0 and blocked.active_domain().is_empty(), "actual scenery LOS blocks both real primary and blast environmental activation")
	await _dispose(arena)


func _snapshot_checks() -> void:
	var arena: Dictionary = await _arena()
	var field = _field(arena.world, "restore", Vector3(0, 0, -0.7))
	var separate = _field(arena.world, "separate", Vector3(4, 0, 0))
	_expect(field.snapshot_state().is_empty() and not field.last_snapshot_error.is_empty(), "unpaused field snapshot rejects rather than mixing simulation generations")
	var activation_count: Array[int] = [0]
	var state_count: Array[int] = [0]
	field.activated.connect(func(_domain: Dictionary) -> void: activation_count[0] += 1)
	field.state_changed.connect(func(_state: Dictionary) -> void: state_count[0] += 1)
	arena.player.slash(Vector3.FORWARD)
	paused = true
	await process_frame
	var releasing: Dictionary = _json(field.snapshot_state())
	_expect(releasing.phase == "releasing" and releasing.generation == 1 and field.restore_state(releasing), "immediate release snapshots and silently restores its actual consumed cluster and active deadline")
	var saved_count: int = state_count[0]
	await create_timer(0.1, true).timeout
	_expect(field.state().clock_s == releasing.clock_s and field.state().deadline_s == releasing.deadline_s and separate.state().clock_s == releasing.clock_s and field.active_domain().remaining_s == 3.0, "background pause freezes every independent mushroom clock and field lifetime")
	var copied: Dictionary = field.snapshot_state()
	copied.definition.parameters.radius = 9
	copied.spent_ids.clear()
	_expect(field.snapshot_state().generation == 1 and field.active_domain().radius == 2.025, "snapshot getters protect nested immutable definitions and spent supplies")
	_expect(not field.activate_cluster("two") and not field.configure("new", _specs()), "paused activation and reconfiguration after bind reject without spending")
	paused = false
	await _ticks(156)
	paused = true
	await process_frame
	var thinning: Dictionary = _json(field.snapshot_state())
	_expect(thinning.phase == "thinning" and field.active_domain().remaining_s > 0.0 and field.active_domain().remaining_s <= 0.5 and field.active_domain().radius == 2.025, "actual simulation reaches thinning while full logical radius remains predictable")
	var before: Dictionary = field.snapshot_state()
	for mutation: String in ["radius", "origin", "definition", "duplicates", "unknown_supply", "fractional_generation", "nan_clock", "deadline", "phase", "unknown", "early_second"]:
		var bad: Dictionary = thinning.duplicate(true)
		match mutation:
			"radius": bad.geometry.radius += 0.01
			"origin": bad.geometry.origin[0] += 0.1
			"definition": bad.definition.parameters.duration_s += 0.1
			"duplicates": bad.generation = 2; bad.spent_ids = ["one", "one"]
			"unknown_supply": bad.spent_ids = ["invented"]
			"fractional_generation": bad.generation = 1.5
			"nan_clock": bad.clock_s = NAN
			"deadline": bad.deadline_s += 0.01
			"phase": bad.phase = "spent"
			"unknown": bad.hp_damage = 1
			"early_second": bad.generation = 2; bad.spent_ids = ["one", "two"]
		_expect(not field.restore_state(bad) and Codec.same_values(before, field.snapshot_state()), "malformed field identity/supply/clock/phase rejects atomically: " + mutation)
	var cue_count: Array[int] = [0]
	field.get_node("two").get_child(field.get_node("two").get_child_count() - 1).state_changed.connect(func(_value: Dictionary) -> void: cue_count[0] += 1)
	var counts: Array = [activation_count[0], state_count[0], cue_count[0]]
	_expect(field.restore_state(releasing) and field.state().phase == "releasing" and field.restore_state(thinning) and field.state().phase == "thinning" and counts == [activation_count[0], state_count[0], cue_count[0]], "restore commits release/thinning silently without field, cue or activation callbacks")
	_expect(not separate.restore_state(thinning) and separate.state().generation == 0, "one mushroom snapshot cannot spend another instance's supplies")
	paused = false
	await _ticks(30)
	_expect(field.state().phase == "available" and field.state().remaining_clusters == 1 and field.active_domain().is_empty() and not field.get_cue_state().visible, "field expires on simulation deadline and remaining supply becomes usable without replenishment")
	_expect(field.get_node("two").receive_attack({"kind": "primary", "origin": "player_direct"}).interaction_accepted and field.state().generation == 2 and field.state().remaining_clusters == 0, "ordinary attack on the second distinct supply starts one new finite field after expiry")
	var second_deadline: float = field.state().deadline_s
	_expect(not field.get_node("one").receive_attack({"kind": "blast", "origin": "player_direct"}).interaction_accepted and field.state().deadline_s == second_deadline, "spent cluster cannot refresh a later field")
	await _ticks(183)
	_expect(field.state().phase == "spent" and field.active_domain().is_empty() and field.state().generation == 2 and not field.activate_cluster("two"), "both finite supplies remain spent after the second field; no automatic replenishment")
	paused = true
	await process_frame
	var spent: Dictionary = _json(field.snapshot_state())
	_expect(field.restore_state(spent) and field.state().phase == "spent" and field.state().spent_ids.size() == 2 and activation_count[0] == 2 and state_count[0] > saved_count, "spent JSON roundtrip never resurrects supply or replays activation")
	var original_position: Vector3 = field.position
	field.position += Vector3.RIGHT * 0.01
	_expect(field.snapshot_state().is_empty() and not field.restore_state(spent), "changed actual world anchor rejects immutable field snapshot and restore")
	field.position = original_position
	_expect(field.restore_state(releasing) and field.state().remaining_clusters == 1, "explicit coherent checkpoint restoration can restore earlier recorded supply without another activation")
	await _dispose(arena)


func _arena() -> Dictionary:
	root.size = Vector2i(540, 1170)
	var container := SubViewportContainer.new()
	root.add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.stretch_shrink = 2
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new()
	viewport.size = Vector2i(270, 585)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	container.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var lighting := Environment.new()
	lighting.background_mode = Environment.BG_COLOR
	lighting.background_color = Color(0.04, 0.045, 0.05)
	lighting.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	lighting.ambient_light_color = Color(0.8, 0.81, 0.78)
	lighting.ambient_light_energy = 0.8
	environment.environment = lighting
	world.add_child(environment)
	_box(world, Vector3(0, -0.5, 0), Vector3(30, 1, 30))
	var player: CinderPlayer = Player.new()
	world.add_child(player)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7.2
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	world.add_child(camera)
	camera.position = Vector3(0, 18, 13)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.current = true
	await _ticks(5)
	return {"container": container, "world": world, "player": player}


func _field(world: Node3D, id: String, point: Vector3, specs: Array = []) -> Node3D:
	var field = Field.new()
	field.position = point
	var configured: bool = field.configure(id, _specs() if specs.is_empty() else specs)
	assert(configured)
	world.add_child(field)
	return field


func _specs() -> Array:
	return [{"id": "one", "offset": Vector3(-0.18, 0, 0)}, {"id": "two", "offset": Vector3(0.18, 0, 0)}]


func _box(parent: Node3D, point: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.position = point
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.22, 0.24, 0.25)
	visual.material_override = material
	body.add_child(visual)


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame


func _json(value: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(value, "", true, true))


func _capture(_arena: Dictionary) -> void:
	if _capture_path.is_empty():
		return
	if DisplayServer.get_name() == "headless":
		print("Spore portrait capture unavailable with headless display; run queued graphical fixture")
		return
	paused = true
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var result: Error = image.save_png(_capture_path)
	_expect(result == OK and image.get_width() == 540 and image.get_height() == 1170, "actual graphical portrait cue capture saves at 540x1170: " + _capture_path)
	paused = false


func _dispose(arena: Dictionary) -> void:
	paused = false
	arena.container.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
