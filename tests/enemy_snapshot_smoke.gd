extends SceneTree

const EnemyScript: GDScript = preload("res://scripts/enemy.gd")
const Codec: GDScript = preload("res://scripts/campaign/snapshot_codec.gd")

class HeroStub:
	extends Node3D
	var hp: float = 100.0
	var dead: bool = false
	var hits: int = 0
	var on_hit: Callable
	func take_damage(amount: float, _impulse: Vector3) -> void:
		if on_hit.is_valid():
			on_hit.call()
		hp = maxf(0.0, hp - amount)
		hits += 1
		dead = hp == 0.0

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var arena := Node3D.new()
	root.add_child(arena)
	_world_box(arena, Vector3(0, -0.5, 0), Vector3(40, 1, 40))
	await _warning_and_lock_checks(arena)
	await _active_and_recovery_checks(arena)
	await _hurt_and_hop_checks(arena)
	await _invalid_checks(arena)
	await _death_and_callback_checks(arena)
	paused = false
	arena.queue_free()
	await process_frame
	print("Enemy snapshot smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _warning_and_lock_checks(arena: Node3D) -> void:
	for phase: String in ["warning", "lock"]:
		var wall: StaticBody3D = _world_box(arena, Vector3(0.85, 1.0, 0.65), Vector3(0.25, 2.0, 0.7))
		var hero: HeroStub = _hero(arena, Vector3(0, 0.02, 1.4))
		var original: AshEnemy = _enemy(arena, hero)
		await _wait_state(original, phase)
		_expect(original.snapshot_state().is_empty() and original.last_snapshot_error.contains("paused"), "enemy live capture rejects outside paused boundary")
		paused = true
		var snapshot: Dictionary = _json(original.snapshot_state())
		_expect(snapshot.clocks.windup_left_s > 0.0 and snapshot.attack_geometry.world_origin != null and snapshot.role.difficulty.is_empty(), "real %s snapshot includes committed source and unprofiled role data" % phase)
		var original_mesh: PackedVector3Array = _mesh_vertices(original.get("_warning"))
		var committed: Vector3 = original.get("_attack_facing")
		# Both live heroes move off the locked cone. Restore must not retarget.
		hero.position = Vector3(-1.4, 0.02, 0)
		var restored_hero: HeroStub = _hero(arena, hero.position)
		var restored: AshEnemy = _enemy(arena, restored_hero)
		var deaths: Array[Vector3] = []
		restored.died.connect(func(where: Vector3) -> void: deaths.append(where))
		_expect(restored.snapshot_error(snapshot).is_empty() and restored.restore_state(snapshot), "fresh actor restores during " + phase)
		_expect((restored.get("_attack_facing") as Vector3).is_equal_approx(committed) and _mesh_equal(original_mesh, _mesh_vertices(restored.get("_warning"))), "restored %s rebuilds the same scenery-clipped locked cone without aiming at the moved hero" % phase)
		_expect(restored.get_attack_state() == phase and (restored.get("_warning") as MeshInstance3D).visible and (restored.get("_countdown") as Node3D).visible and not (restored.get("_active_footprint") as MeshInstance3D).visible, "warning/lock cue state is restored immediately while paused")
		_expect(_same(original.snapshot_state(), restored.snapshot_state()) and deaths.is_empty() and restored_hero.hits == 0, "restore preserves %s HP/clocks/pose without damage or death" % phase)
		var stable: Dictionary = restored.snapshot_state()
		await create_timer(0.05).timeout
		_expect(_same(stable, restored.snapshot_state()), "paused warning/lock clocks and visual pose remain frozen")
		paused = false
		await _wait_state(original, "recovery")
		paused = true
		var original_after: Dictionary = original.snapshot_state()
		var restored_after: Dictionary = restored.snapshot_state()
		if not _same(original_after, restored_after):
			print("Continuation mismatch ", phase, ": source clocks=", original_after.get("clocks"), " restored clocks=", restored_after.get("clocks"), " source motion=", original_after.get("motion"), " restored motion=", restored_after.get("motion"), " source pose=", original_after.get("presentation"), " restored pose=", restored_after.get("presentation"))
		_expect(hero.hits == 0 and restored_hero.hits == 0 and _same(original_after, restored_after), "uninterrupted and restored locked exchanges both miss the moved hero and enter recovery on the same tick")
		original.queue_free()
		restored.queue_free()
		hero.queue_free()
		restored_hero.queue_free()
		wall.queue_free()
		paused = false
		await process_frame


func _active_and_recovery_checks(arena: Node3D) -> void:
	for phase: String in ["active", "recovery"]:
		var hero: HeroStub = _hero(arena, Vector3(0, 0.02, 1.4))
		var original: AshEnemy = _enemy(arena, hero, 1)
		await _wait_state(original, phase)
		_expect(hero.hits == 1 and _near(hero.hp, 85.0), "real armored strike resolves damage once before " + phase)
		paused = true
		var snapshot: Dictionary = _json(original.snapshot_state())
		var restored_hero: HeroStub = _hero(arena, hero.position)
		restored_hero.hp = hero.hp
		var restored: AshEnemy = _enemy(arena, restored_hero)
		var deaths: Array[Vector3] = []
		restored.died.connect(func(where: Vector3) -> void: deaths.append(where))
		_expect(restored.restore_state(snapshot) and restored_hero.hits == 0 and deaths.is_empty(), "restoring %s never calls strike/die/damage" % phase)
		_expect(restored.get_attack_state() == phase and _same(original.snapshot_state(), restored.snapshot_state()), "restored %s retains variant stats, clocks and visual pose" % phase)
		_expect((restored.get("_active_footprint") as MeshInstance3D).visible == (phase == "active") and (restored.get("_recovery_marker") as MeshInstance3D).visible == (phase == "recovery"), "active/recovery feedback restores without advancing a tick")
		paused = false
		await _ticks(12)
		paused = true
		_expect(hero.hits == 1 and restored_hero.hits == 0 and _near(restored_hero.hp, 85.0) and _same(original.snapshot_state(), restored.snapshot_state()), "resuming %s only advances existing clocks and creates no duplicate damage" % phase)
		original.queue_free()
		restored.queue_free()
		hero.queue_free()
		restored_hero.queue_free()
		paused = false
		await process_frame


func _hurt_and_hop_checks(arena: Node3D) -> void:
	var hero: HeroStub = _hero(arena, Vector3(0, 0.02, 1.4))
	var original: AshEnemy = _enemy(arena, hero)
	await _wait_state(original, "warning")
	# Authored raw retuning is actor state; restore cannot call configure and
	# silently replace it with a prototype variant or refill its HP.
	original.max_hp = 120.0
	original.hp = 18.25
	original.set("_move_speed", 2.9)
	original.take_damage(5.0, Vector3(4.0, 5.0, -2.0))
	await _ticks(2)
	paused = true
	var snapshot: Dictionary = _json(original.snapshot_state())
	_expect(snapshot.resources.hp == 13.25 and snapshot.resources.max_hp == 120.0 and snapshot.clocks.stagger_left_s > 0.0 and snapshot.clocks.hit_flash_left_s > 0.0 and snapshot.motion.velocity[1] > 0.0, "hurt snapshot preserves actual low HP, retuned raw role, airborne impulse, stagger and flash clocks")
	var restored_hero: HeroStub = _hero(arena, hero.position)
	var restored: AshEnemy = _enemy(arena, restored_hero)
	_expect(restored.restore_state(snapshot) and restored.restore_state(snapshot) and restored.hp == 13.25 and restored.max_hp == 120.0 and _near(restored.get("_move_speed"), 2.9), "repeated restore neither configures/heals the enemy nor compounds raw role values")
	# Neither mutation of input nor mutation of a returned nested view is live.
	var stable: Dictionary = restored.snapshot_state()
	snapshot.role.raw_stats["move_speed"] = 99.0
	snapshot.motion.velocity[0] = 99.0
	var view: Dictionary = restored.snapshot_state()
	view.role.resolved_stats["max_hp"] = 999.0
	view.presentation.modulate[0] = 99.0
	_expect(_same(stable, restored.snapshot_state()), "enemy snapshot and restore transport use defensive nested copies")
	paused = false
	await _ticks(18)
	paused = true
	_expect(_same(original.snapshot_state(), restored.snapshot_state()) and hero.hits == 0 and restored_hero.hits == 0, "airborne hurt/stagger motion, gravity and flash pose continue coherently")
	original.queue_free()
	restored.queue_free()
	hero.queue_free()
	restored_hero.queue_free()
	paused = false
	await process_frame

	hero = _hero(arena, Vector3(0, 0.02, 6.0))
	original = _enemy(arena, hero, 2)
	for _index: int in range(30):
		await _ticks(1)
		if float(original.get("_hop_left")) > 0.0 and original.velocity.y > 0.0:
			break
	paused = true
	snapshot = _json(original.snapshot_state())
	_expect(snapshot.kind == 2 and snapshot.clocks.hop_left_s > 0.0 and snapshot.motion.velocity[1] > 0.0, "real hopper leap supplies its airborne position/velocity and remaining hop interval")
	restored_hero = _hero(arena, hero.position)
	restored = _enemy(arena, restored_hero)
	_expect(restored.restore_state(snapshot) and _near(restored.max_hp, 23.0) and _near(restored.get("_move_speed"), 3.3), "hopper variant and resolved raw stats restore without configure")
	paused = false
	await _ticks(16)
	paused = true
	_expect(_same(original.snapshot_state(), restored.snapshot_state()), "hopper's actual airborne movement and cooldown continue like uninterrupted physics")
	original.queue_free()
	restored.queue_free()
	hero.queue_free()
	restored_hero.queue_free()
	paused = false
	await process_frame


func _invalid_checks(arena: Node3D) -> void:
	var hero: HeroStub = _hero(arena, Vector3(0, 0.02, 1.4))
	var enemy: AshEnemy = _enemy(arena, hero)
	await _wait_state(enemy, "warning")
	paused = true
	var valid: Dictionary = enemy.snapshot_state()
	var bad_cases: Array[Dictionary] = []
	var bad: Dictionary = valid.duplicate(true)
	bad["schema_version"] = true
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad["actor_type"] = "OtherEnemy"
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad["kind"] = 3
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.erase("motion")
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.resources["hp"] = 1000.0
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.lifecycle["dead"] = true
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.lifecycle["drop_spawned"] = true
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.motion["velocity"] = [0.0, INF, 0.0]
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.motion["attack_facing"] = [2.0, 0.0, 0.0]
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.motion["basis"] = [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.role.raw_stats["windup_s"] = -1.0
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.role.resolved_stats["attack_damage"] = 99.0
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.role.difficulty["profile_id"] = "Challenge"
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.clocks["windup_left_s"] = -1.0
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.clocks["active_left_s"] = 0.1
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.clocks["stagger_left_s"] = 0.1
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.clocks["hop_left_s"] = 5.0
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.attack_geometry["world_origin"] = null
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.attack_geometry["reach"] = 10.0
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.attack_geometry.los["collision_mask"] = 4
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.presentation["frame"] = 0.5
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad.presentation["sprite_kind"] = "hopper"
	bad_cases.append(bad)
	bad = valid.duplicate(true)
	bad["reservation_id"] = "unsupported-before-scheduler-migration"
	bad_cases.append(bad)
	var deaths: Array[Vector3] = []
	enemy.died.connect(func(where: Vector3) -> void: deaths.append(where))
	for index: int in range(bad_cases.size()):
		_expect(not enemy.snapshot_error(bad_cases[index]).is_empty() and not enemy.restore_state(bad_cases[index]) and not enemy.last_snapshot_error.is_empty() and _same(valid, enemy.snapshot_state()) and hero.hits == 0 and deaths.is_empty(), "malformed enemy snapshot %d rejects atomically without damage/death/state changes" % index)
	paused = false
	_expect(not enemy.restore_state(valid) and enemy.last_snapshot_error.contains("paused"), "live enemy restore rejects outside paused boundary")
	enemy.queue_free()
	hero.queue_free()
	await process_frame


func _death_and_callback_checks(arena: Node3D) -> void:
	var hero: HeroStub = _hero(arena, Vector3(0, 0.02, 1.4))
	var enemy: AshEnemy = _enemy(arena, hero)
	var guarded: Array[bool] = []
	hero.on_hit = func() -> void:
		paused = true
		guarded.append(enemy.snapshot_state().is_empty() and enemy.last_snapshot_error.contains("transactions"))
		paused = false
	await _wait_state(enemy, "active")
	_expect(guarded == [true] and hero.hits == 1, "paused hero-damage callback cannot snapshot inside enemy strike/physics transaction")
	paused = true
	var drops: Array[int] = [0]
	var death_guard: Array[bool] = []
	enemy.died.connect(func(_where: Vector3) -> void:
		death_guard.append(enemy.snapshot_state().is_empty() and enemy.last_snapshot_error.contains("transactions"))
		drops[0] += 1
		_expect(enemy.mark_drop_spawned() and not enemy.mark_drop_spawned(), "actual drop consumer acknowledges its one committed drop idempotently")
	)
	_expect(not enemy.mark_drop_spawned(), "live actor cannot acknowledge a death drop")
	enemy.take_damage(200.0, Vector3.ZERO)
	var defeated: Dictionary = _json(enemy.snapshot_state())
	_expect(death_guard == [true] and drops[0] == 1 and defeated.resources.hp == 0.0 and defeated.lifecycle.dead and defeated.lifecycle.death_emitted and defeated.lifecycle.drop_spawned, "defeated queued actor can be captured outside death callback with honest drop lifecycle")
	_expect(not enemy.restore_state(defeated) and enemy.last_snapshot_error.contains("queued"), "queued source cannot be silently resurrected by restore")
	var restored: AshEnemy = _enemy(arena, hero)
	var restored_deaths: Array[Vector3] = []
	restored.died.connect(func(where: Vector3) -> void: restored_deaths.append(where))
	_expect(restored.restore_state(defeated) and restored.restore_state(defeated), "ready replacement accepts the defeated tombstone repeatedly")
	_expect(restored.dead and restored.hp == 0.0 and not restored.is_queued_for_deletion() and not restored.is_in_group("enemies") and restored.collision_layer == 0 and not (restored.get("_sprite") as LabSprite).visible, "defeated restore is dormant, hidden and noncolliding without queueing another death")
	_expect(not restored.mark_drop_spawned() and not restored.take_damage(20.0, Vector3.ZERO).accepted and restored_deaths.is_empty() and drops[0] == 1, "restored defeat cannot damage, emit death or acknowledge a second drop")
	var stable: Dictionary = restored.snapshot_state()
	await create_timer(0.06).timeout
	_expect(_same(stable, restored.snapshot_state()), "paused defeated state retains all clocks without cleanup side effects")
	paused = false
	await _ticks(10)
	paused = true
	_expect(_same(stable, restored.snapshot_state()) and restored_deaths.is_empty() and drops[0] == 1, "unpaused defeated tombstone never resumes its former active damage or drop lifecycle")
	restored.queue_free()
	hero.queue_free()
	paused = false
	await process_frame


func _wait_state(enemy: AshEnemy, desired: String) -> void:
	for _index: int in range(150):
		await _ticks(1)
		if enemy.get_attack_state() == desired:
			return
	_expect(false, "actual enemy reaches expected phase: " + desired)


func _same(left: Variant, right: Variant) -> bool:
	if Codec.is_number(left) and Codec.is_number(right):
		return absf(float(left) - float(right)) < 0.0005
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size():
			return false
		for key: String in left:
			if not right.has(key) or not _same(left[key], right[key]):
				return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size():
			return false
		for index: int in range(left.size()):
			if not _same(left[index], right[index]):
				return false
		return true
	return typeof(left) == typeof(right) and left == right


func _mesh_vertices(node: MeshInstance3D) -> PackedVector3Array:
	if node.mesh.get_surface_count() == 0:
		return PackedVector3Array()
	return node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]


func _mesh_equal(left: PackedVector3Array, right: PackedVector3Array) -> bool:
	if left.size() != right.size():
		return false
	for index: int in range(left.size()):
		if left[index].distance_to(right[index]) > 0.0001:
			return false
	return true


func _json(snapshot: Dictionary) -> Dictionary:
	# Match save_store.write_payload: timer threshold decisions need exact float
	# transport, rather than stringify's default shortened decimal formatting.
	var decoded: Variant = JSON.parse_string(JSON.stringify(snapshot, "", true, true))
	_expect(not snapshot.is_empty() and decoded is Dictionary and Codec.value_error(decoded).is_empty(), "enemy snapshot survives real finite JSON transport")
	var exact_clocks: bool = decoded is Dictionary and not snapshot.is_empty()
	if exact_clocks:
		for key: String in snapshot.clocks:
			exact_clocks = exact_clocks and float(snapshot.clocks[key]) == float(decoded.clocks[key])
	_expect(exact_clocks, "save-store full precision preserves every enemy clock exactly across JSON")
	return decoded as Dictionary


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
	await process_frame


func _hero(arena: Node3D, at: Vector3) -> HeroStub:
	var hero := HeroStub.new()
	arena.add_child(hero)
	hero.position = at
	return hero


func _enemy(arena: Node3D, hero: HeroStub, kind: int = 0) -> AshEnemy:
	var enemy: AshEnemy = EnemyScript.new()
	enemy.configure(hero, null, kind)
	arena.add_child(enemy)
	enemy.position = Vector3(0, 0.02, 0)
	return enemy


func _world_box(parent: Node3D, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.position = at
	return body


func _near(left: Variant, right: Variant) -> bool:
	return absf(float(left) - float(right)) < 0.00001


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
