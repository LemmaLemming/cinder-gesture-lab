extends SceneTree
## Targeted real-floor/owned-lifecycle checks for the initial art-preview scene.
## Does not certify combat, campaign checkpoints, human balance, or art fidelity.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const LevelPath: String = "res://scenes/acts/act2/a2_l1.tscn"
var _checks: int = 0
var _failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var game: Node = MainScene.instantiate()
	game.set("level_scene_path", LevelPath)
	root.add_child(game)
	game.call("resume_lab")
	await _physics_steps(8)
	var level: CinderLevel = game.get("active_level") as CinderLevel
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	_expect(level != null and level.level_id == "A2-L1" and level.contract_error().is_empty(), "registered shared shell accepts canonical Horsell root and spawn")
	_expect(level.hero == hero and not game.call("is_lab_level"), "level uses the shell's one shared player")
	_expect(hero.global_position.y >= -0.05 and hero.global_position.y < 0.2 and absf(hero.global_position.z - 2.6) < 0.02 and absf(hero.global_position.x + 1.0) < 0.02, "spawn settles on reachable dry floor without lateral correction")
	var floors: Array = level.call("floor_regions")
	_expect(floors.size() == 6, "six authored actual static floor rectangles are exposed")
	var bodies: Array = []
	for floor: Dictionary in floors:
		var body: StaticBody3D = floor["body"] as StaticBody3D
		bodies.append(body)
		_expect(body != null and body.collision_layer == 1 and body.rotation.is_zero_approx(), "floor witness refers to live same-height unrotated scenery collision")
	var space: PhysicsDirectSpaceState3D = (game.get("world") as Node3D).get_world_3d().direct_space_state
	# Downward probes establish dry support; actual capsule travel is tested below.
	for z_index: int in range(67):
		var z: float = 3.3 - float(z_index) * 0.5
		for x: float in [-2.55, 0.0, 2.55]:
			if Vector2(x + 1.2, z + 10.8).length() < 0.65:
				continue # one intentional visible trunk, not a floor gap
			var query := PhysicsRayQueryParameters3D.create(Vector3(x, 2.0, z), Vector3(x, -0.7, z), 1)
			var hit: Dictionary = space.intersect_ray(query)
			_expect(not hit.is_empty() and bodies.has(hit.get("collider")) and absf((hit["position"] as Vector3).y) < 0.001, "dry ground and dash-body clearance at (%0.2f,%0.2f)" % [x, z])
	var initial: Dictionary = level.snapshot_state()
	_expect(not initial.is_empty() and level.snapshot_error(initial).is_empty(), "entered scene captures validated local scenic state")
	paused = true
	var frozen: Dictionary = level.snapshot_state()
	await create_timer(0.12, true).timeout
	_expect(level.snapshot_state() == frozen, "pause freezes the owned scenic clock")
	var roundtrip: Dictionary = JSON.parse_string(JSON.stringify(frozen, "", true, true))
	_expect(level.restore_state(roundtrip), "finite scenic state survives JSON transport")
	var posed: Dictionary = roundtrip.duplicate(true)
	posed["local"]["scenic_clock"] = 0.8
	posed["local"]["witness_state"] = "retreat"
	posed["local"]["eruption_visible"] = true
	_expect(level.restore_state(posed), "valid independent retreat and eruption state restores")
	var kit: Dictionary = level.get("_kit")
	_expect((kit["eruption"] as Node3D).visible and (kit["witnesses"][0] as Node3D).visible, "witness posing does not overwrite independently visible harmless eruption")
	_expect(level.restore_state(roundtrip) and not (kit["eruption"] as Node3D).visible, "earlier scene snapshot returns eruption to hidden without resources/events")
	# Atomic rejection compares the exact accepted runtime state immediately
	# before the rejected input, independent of JSON parser rounding.
	var canonical_before_rejection: Dictionary = level.snapshot_state()
	var invalid: Dictionary = roundtrip.duplicate(true)
	invalid["local"]["scenic_clock"] = -1.0
	var rejected_time: bool = not level.restore_state(invalid)
	_expect(rejected_time and level.snapshot_state() == canonical_before_rejection, "invalid scenic time rejects before any mutation")
	invalid = roundtrip.duplicate(true)
	invalid["local"]["witness_state"] = "hostile"
	_expect(not level.restore_state(invalid) and level.snapshot_state() == canonical_before_rejection, "unknown tableau state rejects atomically")
	paused = false
	var completed_dashes: int = 0
	var last_sequence: int = 0
	for dash_index: int in range(13):
		# Four forward dashes approach the trunk; one ordinary right dash
		# chooses the open route before continuing down the dry road.
		hero.request_dash(Vector3.RIGHT if dash_index == 4 else Vector3.FORWARD)
		await create_timer(0.4).timeout
		var records: Array[Dictionary] = hero.get_world_action_records(last_sequence)
		for record: Dictionary in records:
			last_sequence = maxi(last_sequence, int(record["sequence"]))
			if record["kind"] == "dash":
				completed_dashes += 1
		_expect(hero.global_position.y > -0.05 and absf(hero.global_position.x) < 2.5, "actual shared dash stays on continuous floor at segment %d" % dash_index)
		if hero.global_position.z < -28.3:
			break
	_expect(hero.global_position.z < -28.3 and completed_dashes >= 12, "ordinary shared dashes reach Woking approach through the open trunk flank without walking/jumping or a floor seam trap")
	# Exercise real collision-shortened corner dashes at narrowing/widening joins.
	for join_z: float in [-17.6, -19.2, -27.6]:
		for side: float in [-1.0, 1.0]:
			hero.global_position = Vector3(side * 2.3, 0.1, join_z + 0.8)
			hero.velocity = Vector3.ZERO
			await _physics_steps(3)
			hero.request_dash(Vector3(side, 0, -1).normalized())
			await create_timer(0.4).timeout
			var supported: bool = false
			for floor: Dictionary in floors:
				var rectangle: Rect2 = floor["rect"]
				if rectangle.has_point(Vector2(hero.global_position.x, hero.global_position.z)):
					supported = true
			_expect(supported and hero.global_position.y > -0.05, "actual outward corner dash remains on dry supported floor at join %0.1f side %0.0f" % [join_z, side])
	var old_level: CinderLevel = level
	var old_kit: Node = level.get_node("HorsellHeathKit")
	var old_floor: Node = level.get_node("DryGround")
	hero.hp = 43.0
	hero.shells = 0
	game.call("reset_lab")
	level = game.get("active_level") as CinderLevel
	_expect(level != old_level and old_level.hero == null and old_level.effects == null, "shared development reset exits the old owned level")
	_expect(not old_level.request_completion() and old_level.snapshot_state().is_empty(), "exited scene cannot dispatch or capture stale state")
	await process_frame
	_expect(not is_instance_valid(old_level) and not is_instance_valid(old_kit) and not is_instance_valid(old_floor), "reset frees prior floor/scenery ownership without surviving nodes")
	var candidate: Dictionary = level.snapshot_state()
	var lost_floor: StaticBody3D = (level.call("floor_regions") as Array)[0]["body"]
	lost_floor.queue_free()
	await process_frame
	_expect(not level.snapshot_error(candidate).is_empty() and not level.restore_state(candidate), "missing required floor rejects restore before scenic mutation")
	game.queue_free()
	paused = false
	await process_frame
	print("Horsell layout smoke: %d checks, %d failures; art-preview scope only" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _physics_steps(count: int) -> void:
	for index: int in range(count):
		await physics_frame

func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
