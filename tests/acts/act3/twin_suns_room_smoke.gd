extends SceneTree
## Scenery-only acceptance: actual floor/movement, local state, pause and cleanup.
## This cannot establish Stalker combat, campaign completion or checkpoint retry.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const SunScript: GDScript = preload("res://scripts/acts/act3/twin_suns.gd")
const RoomPath: String = "res://scenes/acts/act3/a3_l1_sun_room.tscn"
const FullPath: String = "res://scenes/acts/act3/a3_l1.tscn"
const PlayerRadius: float = 0.32

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game: Node = MainScene.instantiate()
	game.set("level_scene_path", RoomPath)
	root.add_child(game)
	await _ticks(12)
	var level: CinderLevel = game.get("active_level") as CinderLevel
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	_expect(level != null and level.level_id == "A3-L1" and level.contract_error().is_empty(), "room enters through the shared shell with its canonical level identity")
	if level == null or hero == null:
		game.queue_free()
		await process_frame
		_finish()
		return
	var floor_body: StaticBody3D = _floor(level)
	var collisions_before: Dictionary = _collision_signature(level)
	_expect(floor_body != null and _floor_hit(hero.global_position, hero, floor_body) and hero.is_on_floor(), "room spawn settles on the actual authored floor collider")
	_expect(_continuous_box_floor(floor_body, Vector3(-3.1, 0, 4.5), Vector3(3.1, 0, -5.0)), "room pockets share continuous supported ground with capsule clearance")
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("practice_targets").is_empty(), "scenery preparation introduces no substitute combat targets")
	if OS.get_cmdline_user_args().has("--restore-dependencies-only"):
		await _restore_dependency_checks(game)
		game.queue_free()
		paused = false
		await process_frame
		_finish()
		return

	await _dash(hero, Vector3.LEFT, floor_body, "west pocket")
	await _dash(hero, Vector3.RIGHT, floor_body, "return from west pocket")
	await _dash(hero, Vector3.RIGHT, floor_body, "east pocket")
	await _dash(hero, Vector3.LEFT, floor_body, "return from east pocket")
	_expect(absf(hero.global_position.x) < 0.03, "ordinary swipes can reach both pockets and return to their shared approach")
	await _pause_check(game, level, hero, collisions_before)
	var preview_snapshot: Dictionary = await _full_sun_cycle(level, hero, collisions_before)
	await _local_state_checks(game, level, hero, preview_snapshot)
	_expect(not level.is_completed() and level.current_checkpoint()["id"].is_empty(), "harmless room remains an incomplete prototype without a checkpoint allocation")

	var old_room: CinderLevel = level
	var old_floor: StaticBody3D = floor_body
	var old_hero: CinderPlayer = hero
	_expect(game.call("load_level_scene", FullPath), "authored full layout loads through the same scene-selection contract")
	await _ticks(12)
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	floor_body = _floor(level)
	_expect(not is_instance_valid(old_room) and not is_instance_valid(old_floor) and not is_instance_valid(old_hero), "room replacement frees its floor, local scenery and shared actor")
	_expect(_continuous_box_floor(floor_body, Vector3(-2.7, 0, 43), Vector3(-2.7, 0, -43.4)) and _continuous_box_floor(floor_body, Vector3(2.7, 0, 43), Vector3(2.7, 0, -43.4)), "both full-route side corridors lie over one continuous solid floor")
	_expect(_registered_corridor(floor_body, hero, -2.7) and _registered_corridor(floor_body, hero, 2.7), "physics rays confirm support along both authored approach corridors")
	var full_collisions: Dictionary = _collision_signature(level)
	var west_join: Vector3 = await _walk_full_route(game, Vector3.LEFT, "west")
	_expect(_collision_signature(level) == full_collisions, "ordinary full-route traversal changes no terrain or trunk collision")
	var previous_level: CinderLevel = level
	var previous_floor: StaticBody3D = floor_body
	game.call("reset_lab")
	await _ticks(12)
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	_expect(not is_instance_valid(previous_level) and not is_instance_valid(previous_floor), "preview reset replaces the whole full-layout instance and its collision children")
	var east_join: Vector3 = await _walk_full_route(game, Vector3.RIGHT, "east")
	_expect(west_join.distance_to(east_join) < 0.04 and absf(east_join.x) < 0.03, "the two usable approaches rejoin on the same grounded return pocket")
	_expect(not level.is_completed() and level.current_checkpoint()["id"].is_empty() and hero.hp == hero.max_hp, "walking the unfinished full layout grants no encounter completion or checkpoint and causes no scenic damage")
	previous_level = level
	previous_floor = _floor(level)
	_expect(game.call("load_level_scene", RoomPath), "the room can replace the authored layout after traversal")
	await _ticks(2)
	_expect(not is_instance_valid(previous_level) and not is_instance_valid(previous_floor) and _level_count(game.get("world") as Node) == 1, "returning to the room leaves exactly one active level without full-route collision remnants")
	game.queue_free()
	paused = false
	await process_frame
	_finish()


func _pause_check(game: Node, level: CinderLevel, hero: CinderPlayer, collision_state: Dictionary) -> void:
	game.call("open_bench")
	var local_before: Dictionary = level.snapshot_state()
	var actor_clock: float = hero.get_world_action_clock()
	await create_timer(0.08, true).timeout
	_expect(paused and level.snapshot_state() == local_before and hero.get_world_action_clock() == actor_clock and _collision_signature(level) == collision_state, "shared pause freezes scenic state, actor simulation and collision together")
	game.call("resume_lab")
	await _ticks(2)
	_expect(not paused and hero.get_world_action_clock() > actor_clock, "shared resume continues the existing scene clocks")


func _restore_dependency_checks(game: Node) -> void:
	for required_name: String in ["Branchspell", "WestLowTreeScenicCast"]:
		if required_name != "Branchspell":
			_expect(game.call("load_level_scene", RoomPath), "dependency case reloads a healthy room through the public shell")
			game.call("resume_lab")
			await _ticks(12)
		var level: CinderLevel = game.get("active_level") as CinderLevel
		var hero: CinderPlayer = game.get("player") as CinderPlayer
		game.call("open_bench")
		var saved: Dictionary = level.snapshot_state()
		_expect(not saved.is_empty() and level.restore_state(saved), "healthy scenery validates and commits its saved local state")
		var fields_before: Array = [level.get("sun_state"), level.get("sun_elapsed_s"), level.get("sun_stage"), level.get("beat_index"), level.is_completed(), level.current_checkpoint()]
		var actor_before: Dictionary = _hero_resources(hero)
		var required: Node = level.find_child(required_name, true, false)
		_expect(required != null, "dependency test finds the authored " + required_name)
		if required == null:
			continue
		# Simulate a retired required rendering node at the paused barrier. The
		# requested valid values would mutate sun state if commit were reached.
		required.free()
		var candidate: Dictionary = saved.duplicate(true)
		candidate["local"]["sun_state"] = 1 - int(fields_before[0])
		candidate["local"]["sun_elapsed_s"] = SunScript.SUN_STABLE_S + 0.5
		var error: String = level.snapshot_error(candidate)
		var accepted: bool = level.restore_state(candidate)
		var fields_after: Array = [level.get("sun_state"), level.get("sun_elapsed_s"), level.get("sun_stage"), level.get("beat_index"), level.is_completed(), level.current_checkpoint()]
		_expect(not error.is_empty() and not accepted and fields_after == fields_before and _hero_resources(hero) == actor_before, "missing " + required_name + " rejects before local/progress/actor mutation")


func _full_sun_cycle(level: CinderLevel, hero: CinderPlayer, collision_state: Dictionary) -> Dictionary:
	var starting_state: int = int(level.get("sun_state"))
	var previous_state: int = starting_state
	var changes: int = 0
	var observed: Dictionary = {}
	var safe: bool = true
	var hp_before: float = hero.hp
	var preview: Dictionary = {}
	# Observe both states through their actual complete clocks. No clock edits or
	# synthetic state forcing can establish the harmless-cycle requirement.
	var frame_limit: int = int(Engine.physics_ticks_per_second * (2.0 * SunScript.SUN_PERIOD_S + 4.0))
	for _index: int in range(frame_limit):
		await _ticks(1)
		var state: int = int(level.get("sun_state"))
		var stage: String = String(level.get("sun_stage"))
		observed["%d:%s" % [state, stage]] = true
		safe = safe and hero.hp == hp_before and _collision_signature(level) == collision_state and _floor_hit(hero.global_position, hero, _floor(level))
		if preview.is_empty() and stage == "preview":
			preview = level.snapshot_state()
		if state != previous_state:
			changes += 1
			previous_state = state
		if changes >= 2 and state == starting_state:
			break
	_expect(changes == 2 and observed.size() == 6 and not preview.is_empty(), "a real complete sun cycle includes both stable, preview and lock states")
	_expect(safe, "the entire sun cycle preserves HP, collider identity/geometry and occupied floor support")
	return preview


func _local_state_checks(game: Node, level: CinderLevel, hero: CinderPlayer, preview: Dictionary) -> void:
	game.call("open_bench")
	hero.hp = 37.25
	hero.shells = 0
	var resources: Dictionary = _hero_resources(hero)
	var later: Dictionary = level.snapshot_state()
	_expect(not preview.is_empty() and not _same_local(later, preview), "preview snapshot differs from the later live cycle state")
	if preview.is_empty():
		game.call("resume_lab")
		return
	_expect(level.restore_state(preview) and _same_local(level.snapshot_state(), preview) and String(level.get("sun_stage")) == "preview", "local restore returns the actual earlier preview clock and its visible stage")
	var transported: Variant = JSON.parse_string(JSON.stringify(preview))
	_expect(transported is Dictionary and level.restore_state(transported) and _same_local(level.snapshot_state(), preview), "finite JSON transport preserves the saved sun state and clock")
	_expect(_hero_resources(hero) == resources and not level.is_completed() and level.current_checkpoint()["id"].is_empty(), "local restoration grants no health/ammo, gear change, completion or checkpoint")
	var valid: Dictionary = level.snapshot_state()
	var rejected: Array[Dictionary] = []
	for field: String in ["sun_state", "beat_index"]:
		var invalid: Dictionary = valid.duplicate(true)
		invalid["local"][field] = 0.5
		rejected.append(invalid)
	for elapsed: float in [-1.0, SunScript.SUN_PERIOD_S, INF]:
		var invalid: Dictionary = valid.duplicate(true)
		invalid["local"]["sun_elapsed_s"] = elapsed
		rejected.append(invalid)
	var unknown: Dictionary = valid.duplicate(true)
	unknown["local"]["extra"] = "undeclared"
	rejected.append(unknown)
	var missing: Dictionary = valid.duplicate(true)
	missing["local"].erase("sun_elapsed_s")
	rejected.append(missing)
	var wrong_scene: Dictionary = valid.duplicate(true)
	wrong_scene["scene_path"] = FullPath
	rejected.append(wrong_scene)
	var foreign_object: Dictionary = valid.duplicate(true)
	foreign_object["local"]["sun_elapsed_s"] = hero
	rejected.append(foreign_object)
	for index: int in range(rejected.size()):
		var invalid: Dictionary = rejected[index]
		var error: String = level.snapshot_error(invalid)
		var accepted: bool = level.restore_state(invalid)
		_expect(not error.is_empty() and not accepted and _same_local(level.snapshot_state(), valid) and _hero_resources(hero) == resources, "malformed local snapshot %d rejects before local or actor mutation" % index)
	_expect(level.restore_state(later), "local test restores the later live cycle state without a preview reset")
	game.call("resume_lab")


func _walk_full_route(game: Node, side: Vector3, label: String) -> Vector3:
	var level: CinderLevel = game.get("active_level") as CinderLevel
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	var floor_body: StaticBody3D = _floor(level)
	for _step: int in range(11):
		await _dash(hero, Vector3.FORWARD, floor_body, label + " arrival approach")
	await _dash(hero, side, floor_body, label + " branch")
	for _step: int in range(4):
		await _dash(hero, Vector3.FORWARD, floor_body, label + " beside the low trunk")
	await _dash(hero, -side, floor_body, label + " rejoin")
	var rejoined: Vector3 = hero.global_position
	_expect(rejoined.z < 5.0 and rejoined.z > 0.0 and _floor_hit(rejoined, hero, floor_body), label + " approach passes the z8 trunk and rejoins beyond it")
	await _dash(hero, Vector3.LEFT, floor_body, label + " crossing approach")
	for _step: int in range(17):
		await _dash(hero, Vector3.FORWARD, floor_body, label + " crossing and departure")
	await _dash(hero, Vector3.RIGHT, floor_body, label + " departure pocket")
	_expect(hero.global_position.z < -40.0 and _floor_hit(hero.global_position, hero, floor_body), label + " full route reaches the grounded departure beyond both trunks")
	return rejoined


func _dash(hero: CinderPlayer, direction: Vector3, floor_body: StaticBody3D, label: String) -> void:
	var history: Array[Dictionary] = hero.get_world_action_records()
	var sequence: int = int(history[-1]["sequence"]) if not history.is_empty() else 0
	var stats: Dictionary = hero.equipment.resolved_stats()
	var before_clock: float = hero.get_world_action_clock()
	var before: Vector3 = hero.global_position
	var accepted: bool = hero.request_dash(direction)
	await _wait_simulation(hero, float(stats["dash_cooldown"]) + 0.035)
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	var valid: bool = accepted and records.size() == 1
	if valid:
		var record: Dictionary = records[0]
		valid = record["kind"] == "dash" and not bool(record["blocked"]) and not bool(record["collision_shortened"]) and float(record["completed_at_s"]) > before_clock and (record["world_origin"] as Vector3).distance_to(before) < 0.01 and (record["landing"] as Vector3).distance_to(hero.global_position) < 0.01 and absf(float(record["distance"]) - float(stats["dash_distance"])) < 0.02
		for sample: Dictionary in record["path"]:
			valid = valid and _floor_hit(sample["position"], hero, floor_body)
	_expect(valid, label + ": one ordinary dash completes at full distance with a grounded recorded world path")


func _wait_simulation(hero: CinderPlayer, duration: float) -> void:
	var deadline: float = hero.get_world_action_clock() + duration
	var limit: int = int(ceilf(duration * Engine.physics_ticks_per_second)) + 8
	for _index: int in range(limit):
		if hero.get_world_action_clock() >= deadline:
			return
		await _ticks(1)
	_expect(false, "expected active simulation clock advance before the bounded wait expires")


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame


func _floor(level: CinderLevel) -> StaticBody3D:
	var scenery: Node = level.get("scenery") as Node
	return scenery.get("floor_body") as StaticBody3D if is_instance_valid(scenery) else null


func _floor_hit(point: Vector3, hero: CinderPlayer, floor_body: StaticBody3D) -> bool:
	if not is_instance_valid(floor_body):
		return false
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.25, point - Vector3.UP * 0.25, 1)
	var hit: Dictionary = hero.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == floor_body and absf((hit["position"] as Vector3).y) < 0.001


func _continuous_box_floor(body: StaticBody3D, start: Vector3, finish: Vector3) -> bool:
	if not is_instance_valid(body) or not body.global_basis.is_equal_approx(Basis.IDENTITY):
		return false
	var colliders: Array[Node] = body.find_children("*", "CollisionShape3D", false, false)
	if colliders.size() != 1:
		return false
	var collision: CollisionShape3D = colliders[0] as CollisionShape3D
	if collision.disabled or not collision.shape is BoxShape3D or not collision.global_basis.is_equal_approx(Basis.IDENTITY) or (body.collision_layer & 1) == 0:
		return false
	var size: Vector3 = (collision.shape as BoxShape3D).size
	var center: Vector3 = collision.global_position
	var clearance: float = PlayerRadius + 0.02
	for point: Vector3 in [start, finish]:
		if absf(point.x - center.x) + clearance >= size.x * 0.5 or absf(point.z - center.z) + clearance >= size.z * 0.5:
			return false
	return absf(center.y + size.y * 0.5) < 0.001


func _registered_corridor(body: StaticBody3D, hero: CinderPlayer, x: float) -> bool:
	for index: int in range(174):
		if not _floor_hit(Vector3(x, 0.02, 43.0 - float(index) * 0.5), hero, body):
			return false
	return true


func _collision_signature(level: CinderLevel) -> Dictionary:
	var signature: Dictionary = {}
	for node: Node in level.find_children("*", "CollisionShape3D", true, false):
		var collision: CollisionShape3D = node as CollisionShape3D
		var body: CollisionObject3D = collision.get_parent() as CollisionObject3D
		var shape: Shape3D = collision.shape
		signature[String(level.get_path_to(collision))] = {"node_id": collision.get_instance_id(), "shape_id": shape.get_instance_id(), "transform": collision.global_transform, "disabled": collision.disabled, "layer": body.collision_layer, "mask": body.collision_mask, "box_size": (shape as BoxShape3D).size if shape is BoxShape3D else Vector3.ZERO}
	return signature


func _hero_resources(hero: CinderPlayer) -> Dictionary:
	return {"hp": hero.hp, "max_hp": hero.max_hp, "shells": hero.shells, "max_shells": hero.max_shells, "dead": hero.dead, "gear": hero.equipment.snapshot(), "actions": hero.get_world_action_records()}


func _same_local(left: Dictionary, right: Dictionary) -> bool:
	if left.is_empty() or right.is_empty() or left.get("progress") != right.get("progress") or left.get("scene_path") != right.get("scene_path"):
		return false
	var a: Dictionary = left["local"]
	var b: Dictionary = right["local"]
	return a["sun_state"] == b["sun_state"] and a["beat_index"] == b["beat_index"] and absf(float(a["sun_elapsed_s"]) - float(b["sun_elapsed_s"])) < 0.000001


func _level_count(world: Node) -> int:
	var count: int = 0
	for child: Node in world.get_children():
		if child is CinderLevel:
			count += 1
	return count


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)


func _finish() -> void:
	print("Twin Suns scenery smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
