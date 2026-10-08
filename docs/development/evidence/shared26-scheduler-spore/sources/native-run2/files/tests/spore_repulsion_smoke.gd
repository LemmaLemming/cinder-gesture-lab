extends SceneTree
## Shared opt-in real AshEnemy BOX consumer; no Act 1 encounter/art acceptance.
const Enemy = preload("res://scripts/enemy.gd")
const Field = preload("res://scripts/environment/spore_field.gd")
const Consumer = preload("res://scripts/environment/spore_repulsion.gd")
const Route = preload("res://scripts/combat/repulsion_route.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
var checks: int = 0
var failures: int = 0

class Hero:
	extends Node3D
	var dead: bool = false
	var hits: int = 0
	func take_damage(_amount: float, _impulse: Vector3) -> void:
		hits += 1

class Effects:
	extends Node
	var bleeds: int = 0
	func tiny_bleed(_at: Vector3, _count: int, _impulse: Vector3) -> void:
		bleeds += 1


class GroundedCapsule:
	extends CharacterBody3D
	func _physics_process(delta: float) -> void:
		if not is_on_floor():
			velocity.y -= 24.0 * delta
		elif velocity.y < 0.0:
			velocity.y = 0.0
		move_and_slide()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _real_cancellation()
	await _paired_retry(false)
	await _paired_retry(true)
	await _placement_failures()
	await _continuation_failure()
	await _capsule_route_snapshot()
	await _death_pair()
	await _binding_retry()
	await _live_binding_failure()
	await _missing_owner_hurt()
	await _punctuated_failure_id()
	print("Spore repulsion smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _real_cancellation() -> void:
	var world: Dictionary = _world()
	await _ticks(5)
	_expect(world.enemy.get_spore_response_state().grounded, "fixture uses real move_and_slide grounded BOX contact")
	_expect(world.consumer.bind_environment(world.bindings), "immutable actual living source/fields bind: " + world.consumer.last_error)
	var reactions: Array = []
	world.consumer.reaction_started.connect(func(id: String, episode: String) -> void: reactions.append([id, episode]))
	var rejection: Array = []
	world.consumer.placement_rejected.connect(func(id: String, error: String) -> void: rejection.append([id, error]))
	var deaths: Array = []
	world.enemy.died.connect(func(at: Vector3) -> void: deaths.append(at))
	_expect(world.enemy.get_attack_state() in ["warning", "lock"], "ordinary source actually prepares its attack before spore activation")
	var actual_shape: Shape3D = world.enemy.get_node("BodyCollision").shape
	var hp: float = world.enemy.hp
	var basis: Basis = world.enemy.global_basis
	var origin: Vector3 = world.enemy.global_position
	var callback_guard: Array = []
	world.consumer.reaction_started.connect(func(_id: String, _episode: String) -> void: callback_guard.append(world.enemy.snapshot_state().is_empty() and world.consumer.snapshot_error({}, {}).contains("boundary")))
	_expect(world.first.activate_cluster("left"), "ordinary field activation starts the opt-in reaction")
	_expect(reactions.size() == 1 and world.enemy.get_attack_state() == "spore_recoil" and callback_guard == [true], "one actual attack cancellation precedes reaction callback and callback snapshots reject")
	_expect(world.enemy.hp == hp and world.effects.bleeds == 0 and deaths.is_empty() and world.hero.hits == 0, "spores neither damage living actor/player nor emit bleed/death")
	_expect(world.enemy.global_position == origin and world.enemy.global_basis == basis and world.enemy.get_node("BodyCollision").shape == actual_shape, "recoil is sprite feedback with unchanged actual BOX and collision basis")
	await _wait_phase(world, "retreat")
	var first_record: Dictionary = world.consumer.source_state("grunt")
	_expect(first_record.phase == "retreat" and first_record.route.leased, "full recoil and turn precede real leased retreat")
	_expect(world.second.activate_cluster("left"), "a newly overlapping active generation joins the current episode")
	await _ticks(2)
	var joined: Dictionary = world.consumer.source_state("grunt")
	_expect(joined.members == ["mushroom-a/field-1", "mushroom-b/field-1"] and reactions.size() == 1 and joined.episode_id == first_record.episode_id and joined.original_endpoint == first_record.original_endpoint, "connected union joins without new recoil, reset or changed landing")
	await _wait_phase(world, "hold")
	var held: Dictionary = world.consumer.source_state("grunt")
	var response: Dictionary = world.enemy.get_spore_response_state()
	_expect(held.phase == "hold" and response.velocity == Vector3.ZERO and response.position.distance_to(held.original_endpoint) <= 0.005, "actual measured BOX reaches and deliberately stops at its fixed endpoint")
	for field: Node3D in [world.first, world.second]:
		_expect(Vector2(response.position.x - field.global_position.x, response.position.z - field.global_position.z).length() > 2.025 + float(response.support_radius) + 0.08, "landing lies outside entire registered field union with measured radius/skin")
	var held_position: Vector3 = response.position
	await _ticks(15)
	_expect(world.enemy.global_position == held_position and world.hero.hits == 0 and rejection.is_empty() and world.consumer.placement_accepted(), "held source avoids active-field reentry without an expired attack firing")
	await _wait_phase(world, "none", 300)
	_expect(reactions.size() == 1 and world.enemy.get_spore_response_state().episode_id.is_empty(), "full field expiry plus explicit regroup releases the same episode")
	await _wait_attack(world.enemy, "warning", 300)
	_expect(world.enemy.get_attack_state() == "warning" and world.hero.hits == 0, "returning actor uses a fresh complete ordinary tell, never resumes cancelled strike")
	_expect(world.first.activate_cluster("right") and reactions.size() == 2, "a genuinely separate later field generation grants a new reaction rather than global immunity")
	await _dispose(world)
	# Real active state already paid its damage and has a nonzero cooldown.
	world = _world()
	await _wait_attack(world.enemy, "active")
	_expect(world.hero.hits == 1 and world.consumer.bind_environment(world.bindings), "second fixture binds a real active strike after its already-resolved player hit")
	var cooldown: float = world.enemy.get_spore_response_state().cooldown_remaining_s
	_expect(cooldown > 0.0 and world.first.activate_cluster("left") and is_equal_approx(world.enemy.get_spore_response_state().cooldown_remaining_s, cooldown), "environmental cancellation preserves the real source cooldown exactly")
	await _ticks(8)
	_expect(is_equal_approx(world.enemy.get_spore_response_state().cooldown_remaining_s, maxf(0, cooldown - 8.0 / 60.0)) and world.hero.hits == 1, "ordinary source cooldown continues once per simulation tick during environmental phase")
	await _dispose(world)


func _paired_retry(interrupt: bool) -> void:
	var original: Dictionary = _world()
	await _ticks(5)
	_expect(original.consumer.bind_environment(original.bindings) and original.first.activate_cluster("left"), "paired fixture commits actual source cancellation")
	await _wait_phase(original, "retreat")
	await _ticks(5)
	if interrupt:
		var owned_velocity: Vector3 = original.enemy.velocity
		var hp: float = original.enemy.hp
		var hit: Dictionary = original.enemy.take_damage(2.0, Vector3(0.5, 2.0, 0))
		_expect(hit.accepted and original.enemy.hp == hp - 2.0 and original.enemy.velocity == owned_velocity + Vector3(0.5, 2, 0) and original.effects.bleeds == 1, "actual damage interruption retains real HP loss, bleed and airborne impulse")
		_expect(original.consumer.source_state("grunt").phase == "interrupted" and original.consumer.source_state("grunt").route.is_empty(), "interruption disarms environmental route without clobbering new damage velocity")
		await _ticks(2)
	paused = true
	var context: Dictionary = _context(original)
	var value: Dictionary = _json(original.consumer.snapshot_state(context))
	_expect(not value.is_empty(), "paused %s consumer captures exact paired state: %s" % ["hurt" if interrupt else "mid-retreat", original.consumer.last_error])
	if value.is_empty():
		await _dispose(original)
		return
		await create_timer(0.035, true).timeout
	_expect(Codec.same_values(value, original.consumer.snapshot_state(context)), "pause freezes field generation/deadline and actual episode/route clocks")
	# Separate actual World3D, same stable authored paths, deliberately fresh pose.
	var restored: Dictionary = _world(Vector3(9, 0.002, 0))
	_expect(restored.consumer.bind_environment(restored.bindings), "fresh recipient binds the identical physical world while paused: " + restored.consumer.last_error)
	var fresh_context: Dictionary = _context(restored)
	var fresh: Dictionary = restored.consumer.snapshot_state(fresh_context)
	var fresh_pose: Vector3 = restored.enemy.global_position
	_expect(restored.consumer.snapshot_error(value, context).is_empty() and restored.enemy.global_position == fresh_pose and restored.first.state().generation == 0, "whole paired preflight validates saved actor pose without mutating fresh actor/field units: " + restored.consumer.snapshot_error(value, context))
	var changed: Dictionary = value.duplicate(true)
	changed.records.grunt.progress = 0.95
	var cross_actor: Dictionary = context.duplicate(true)
	cross_actor.sources.grunt.repulsion.progress = 0.95
	_expect(not restored.consumer.snapshot_error(changed, cross_actor).is_empty(), "cross-forged actor and environmental progress still reject inconsistent phase clocks")
	changed = value.duplicate(true)
	changed.field_references["mushroom-a"].clock_s += 0.2
	_expect(not restored.consumer.snapshot_error(changed, context).is_empty(), "cross-forged field clock/deadline unit is rejected")
	changed = value.duplicate(true)
	changed.records.grunt.direction = [0, 0, 1]
	_expect(not restored.consumer.snapshot_error(changed, context).is_empty(), "cross-forged actor/episode direction is rejected")
	if not interrupt:
		changed = value.duplicate(true)
		changed.records.grunt.route.route.current_position[0] += 0.25
		_expect(not restored.consumer.snapshot_error(changed, context).is_empty(), "route cannot disagree with staged saved actor motion")
		changed = value.duplicate(true)
		changed.records.grunt.route.route.elapsed_s += 0.1
		_expect(not restored.consumer.snapshot_error(changed, context).is_empty(), "route deadline/progress cannot invisibly reset on retry")
	_expect(not restored.consumer.restore_state(value, context) and restored.enemy.global_position == fresh_pose and Codec.same_values(fresh, restored.consumer.snapshot_state(fresh_context)), "commit rejects until actual external units are restored and leaves coordinator unchanged")
	var reactions: Array = []
	var activations: Array = []
	restored.consumer.reaction_started.connect(func(_id: String, episode: String) -> void: reactions.append(episode))
	restored.first.activated.connect(func(domain: Dictionary) -> void: activations.append(domain))
	_expect(restored.first.restore_state(context.fields["mushroom-a"]) and restored.second.restore_state(context.fields["mushroom-b"]) and restored.enemy.restore_state(context.sources.grunt) and restored.consumer.restore_state(value, context), "silent external field -> actor -> exact leased route/coordinator commit: " + restored.consumer.last_error)
	_expect(reactions.is_empty() and activations.is_empty() and restored.effects.bleeds == 0 and restored.hero.hits == 0 and restored.enemy.hp == original.enemy.hp, "retry creates no activation, recoil, damage, bleed, heal or resource regrant")
	_expect(Codec.same_values(value, restored.consumer.snapshot_state(_context(restored))) and Codec.same_values(context.sources.grunt, restored.enemy.snapshot_state()), "full-precision JSON mid-episode restore exactly matches actor and coordinator")
	paused = false
	await _ticks(15 if not interrupt else 80)
	paused = true
	var continued_original: Dictionary = original.consumer.snapshot_state(_context(original))
	var continued_restored: Dictionary = restored.consumer.snapshot_state(_context(restored))
	if continued_original.is_empty() or continued_restored.is_empty() or not Codec.same_values(continued_original, continued_restored):
		print("Capture problems original=", original.consumer.last_error, " restored=", restored.consumer.last_error, " actorOriginal=", original.enemy.last_snapshot_error, " actorRestored=", restored.enemy.last_snapshot_error)
		print("Continuation original=", continued_original, " restored=", continued_restored)
	_expect(not continued_original.is_empty() and Codec.same_values(continued_original, continued_restored) and Codec.same_values(original.enemy.snapshot_state(), restored.enemy.snapshot_state()), "uninterrupted and paired retry follow the same actual motion/phase/cooldown clock")
	if interrupt:
		var record: Dictionary = original.consumer.source_state("grunt")
		_expect(record.route_revision == 2 and record.episode_id == value.records.grunt.episode_id and record.original_endpoint == Codec.read_vector3(value.records.grunt.original_endpoint) and record.age_s > value.records.grunt.age_s and original.consumer.placement_accepted(), "hurt ends grounded before explicit same-episode route revision toward original outside endpoint")
	var wall: StaticBody3D = _box(restored.root, "LateWall", Vector3(14, 1, 0), Vector3(0.1, 2, 1))
	_expect(not restored.consumer.snapshot_error(continued_original, _context(original)).is_empty(), "changed actual static collision fingerprint rejects old paired checkpoint before mutation")
	wall.free()
	await _dispose(original)
	await _dispose(restored)


func _placement_failures() -> void:
	var world: Dictionary = _world(Vector3(2.1, 0.002, 0), [Vector3.RIGHT], false)
	var wall: StaticBody3D = _box(world.root, "Wall", Vector3(2.85, 1.0, 0), Vector3(0.1, 2, 4))
	await _ticks(5)
	_expect(world.consumer.bind_environment(world.bindings), "wall outside full expanded field domain is supported for endpoint rejection fixture: " + world.consumer.last_error)
	var before: Dictionary = world.enemy.get_spore_response_state()
	var state: String = world.enemy.get_attack_state()
	_expect(world.first.activate_cluster("left") and not world.consumer.placement_accepted() and world.enemy.get_spore_response_state().episode_id.is_empty() and world.enemy.global_position == before.position and world.enemy.velocity == before.velocity and world.enemy.get_attack_state() == state and world.consumer.get_node("Blocked_grunt") is Label3D, "blocked wall-shortened endpoint still inside field visibly rejects before real cancellation/motion")
	await _dispose(world)
	world = _world(Vector3.ZERO, [Vector3.RIGHT], false)
	_box(world.root, "SeparatingWall", Vector3(0.8, 1, 0), Vector3(0.1, 2, 4))
	await _ticks(5)
	_expect(not world.consumer.bind_environment(world.bindings) and world.consumer.last_error.contains("wall-separated"), "full-circle propagation through/wall-separated scenery rejects author placement")
	await _dispose(world)
	world = _world(Vector3.ZERO, [Vector3.RIGHT], false, true)
	await _ticks(5)
	_expect(world.consumer.bind_environment(world.bindings), "full field circle fits actual floor but its outside landing faces a hole: " + world.consumer.last_error)
	var hp: float = world.enemy.hp
	_expect(world.first.activate_cluster("left") and not world.consumer.placement_accepted() and world.enemy.get_spore_response_state().episode_id.is_empty() and world.enemy.hp == hp, "reachable-looking endpoint across unsupported floor rejects with no fabricated retreat/damage")
	await _dispose(world)


func _continuation_failure() -> void:
	var world: Dictionary = _world(Vector3.ZERO, [Vector3.LEFT], false)
	await _ticks(5)
	_expect(world.consumer.bind_environment(world.bindings) and world.first.activate_cluster("left"), "interruption failure fixture starts valid actual route")
	await _wait_phase(world, "retreat")
	world.enemy.take_damage(1.0, Vector3(0, 2, 0))
	# Actual new scenery outside the circle blocks the ORIGINAL fixed landing.
	_box(world.root, "NewWall", Vector3(-2.75, 1, 0), Vector3(0.1, 2, 4))
	await _ticks(80)
	var response: Dictionary = world.enemy.get_spore_response_state()
	_expect(not world.consumer.placement_accepted() and world.enemy.hp == 31.0 and world.effects.bleeds == 1 and response.episode_id != "" and response.phase == "interrupted", "blocked original endpoint after real hurt rejects continuation without HP reset/second recoil")
	await _dispose(world)


func _capsule_route_snapshot() -> void:
	var original: Dictionary = _capsule_world(Vector3(0, 0.01, 0))
	await _ticks(6)
	var source: CharacterBody3D = original.source
	source.set_physics_process(false)
	source.velocity = Vector3.RIGHT * 1.5
	var route := Route.new()
	var prepared: Dictionary = route.plan(source, {"direction": Vector3.RIGHT, "speed": 4.0, "distance": 3.0}, original.bindings)
	_expect(source.is_on_floor() and not prepared.has("error"), "native actual grounded CAPSULE can preflight through bounded floor-only wrapper recovery")
	if prepared.has("error"):
		await _dispose(original)
		return
	_expect(route.acquire(source) and not route.advance(source, 0.2).has("error"), "capsule executes real partial route before paired motion snapshot")
	paused = true
	var saved: Dictionary = _json(route.snapshot_state(source))
	_expect(not saved.is_empty() and saved.route.leased and saved.route.elapsed_s == 0.2, "capsule route captures measured collider and exact remaining timeline")
	var restored: Dictionary = _capsule_world(Vector3(9, 0.01, 0))
	restored.source.set_physics_process(false)
	var resumed := Route.new()
	var staged_motion: Dictionary = {"position": Codec.read_vector3(saved.route.current_position), "velocity": Codec.read_vector3(saved.route.current_velocity)}
	var before: Vector3 = restored.source.position
	_expect(resumed.snapshot_error(saved, restored.source, restored.bindings, staged_motion).is_empty() and restored.source.position == before, "fresh capsule pure staged saved contact/route proof does not need cached grounded history")
	_expect(not resumed.restore_state(saved, restored.source, restored.bindings) and restored.source.position == before and resumed.state().is_empty(), "capsule commit rejects actual source pose disagreement atomically")
	restored.source.position = staged_motion.position
	restored.source.velocity = staged_motion.velocity
	_expect(resumed.restore_state(saved, restored.source, restored.bindings) and Codec.same_values(saved, resumed.snapshot_state(restored.source)), "externally committed exact capsule pose silently restores existing route lease without acquiring/stopping velocity")
	paused = false
	var a: Dictionary = route.advance(source, 0.4)
	var b: Dictionary = resumed.advance(restored.source, 0.4)
	_expect(not a.has("error") and not b.has("error") and source.position.distance_to(restored.source.position) <= 0.00001 and source.velocity == restored.source.velocity, "grounded capsule original/restored routes advance identically through actual move_and_collide")
	await _dispose(original)
	await _dispose(restored)


func _capsule_world(at: Vector3) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = Vector2i(64, 64)
	root.add_child(viewport)
	var arena := Node3D.new()
	arena.name = "World"
	viewport.add_child(arena)
	var floor_body: StaticBody3D = _box(arena, "Floor", Vector3(0, -0.5, 0), Vector3(40, 1, 40))
	var source := GroundedCapsule.new()
	source.name = "Capsule"
	source.position = at
	source.collision_mask = 1
	source.collision_layer = 2
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.45
	collision.shape = shape
	collision.position.y = 0.73
	source.add_child(collision)
	arena.add_child(source)
	return {"viewport": viewport, "source": source, "bindings": {"world_root": arena, "floors": {"ground": {"collision": floor_body.get_node("Shape"), "safe_rect": Rect2(-20, -20, 40, 40)}}}}


func _death_pair() -> void:
	var original: Dictionary = _world()
	await _ticks(5)
	_expect(original.consumer.bind_environment(original.bindings) and original.first.activate_cluster("left"), "death cleanup fixture has an actual acquired environmental source")
	var actual: Dictionary = original.enemy.take_damage(100.0, Vector3.UP)
	paused = true
	var context: Dictionary = _context(original)
	var value: Dictionary = original.consumer.snapshot_state(context)
	_expect(actual.accepted and original.enemy.dead and value.records.is_empty() and not value.is_empty(), "real lethal damage releases route; paused pre-free capture keeps external dead unit without environmental resurrection: " + original.consumer.last_error)
	if value.is_empty():
		await _dispose(original)
		return
	var restored: Dictionary = _world()
	_expect(restored.consumer.bind_environment(restored.bindings) and restored.consumer.snapshot_error(value, context).is_empty(), "ready replacement prevalidates paired external defeat before any restore")
	var deaths: Array = []
	restored.enemy.died.connect(func(at: Vector3) -> void: deaths.append(at))
	_expect(restored.first.restore_state(context.fields["mushroom-a"]) and restored.second.restore_state(context.fields["mushroom-b"]) and restored.enemy.restore_state(context.sources.grunt) and restored.consumer.restore_state(value, context), "external defeated actor and field units silently commit with no new environmental route")
	_expect(restored.enemy.hp == 0.0 and restored.enemy.dead and deaths.is_empty() and restored.effects.bleeds == 0 and restored.consumer.source_state("grunt").is_empty() and Codec.same_values(value, restored.consumer.snapshot_state(_context(restored))), "paired defeated retry does not duplicate damage, death/drop events or spore resources")
	await process_frame
	var tombstone: Dictionary = {"fields": {"mushroom-a": original.first.snapshot_state(), "mushroom-b": original.second.snapshot_state()}, "sources": {"grunt": context.sources.grunt}}
	var after_free: Dictionary = original.consumer.snapshot_state(tombstone)
	_expect(not is_instance_valid(original.enemy) and not after_free.is_empty() and Enemy.spore_record_error(context.sources.grunt, "spore-test", "grunt").is_empty(), "after actual node removal the level-owned real defeat tombstone validates without creating a new actor/resource")
	var forged: Dictionary = tombstone.duplicate(true)
	forged.sources.grunt.resources.hp = 2.0
	_expect(not original.consumer.snapshot_error(after_free, forged).is_empty(), "freed source cannot be replaced by a forged live resource unit")
	_expect(original.consumer.restore_state(after_free, tombstone) and original.consumer.source_state("grunt").is_empty(), "consumer retry of an externally owned missing defeat emits nothing and never instantiates a replacement")
	await _dispose(original)
	await _dispose(restored)


func _binding_retry() -> void:
	var world: Dictionary = _world()
	await _ticks(5)
	var rejected: Dictionary = world.bindings.duplicate(true)
	rejected.fields = {"mushroom-a": world.first, "wrong-id": world.second}
	_expect(not world.consumer.bind_environment(rejected) and world.enemy.get_spore_response_state().source_id == "" and not world.consumer.placement_accepted(), "valid first field then invalid middle field rejects without binding any actor")
	var required_boundary: MeshInstance3D = world.second.get_node("RequiredBrokenSporeBoundary")
	var required_position: Vector3 = required_boundary.position
	required_boundary.position.x += 0.02
	_expect(not world.consumer.bind_environment(world.bindings) and world.enemy.get_spore_response_state().source_id == "", "inactive required field cue drift rejects full bind before any source commit")
	required_boundary.position = required_position
	var unsupported := CharacterBody3D.new()
	unsupported.name = "Unsupported"
	world.root.add_child(unsupported)
	rejected = world.bindings.duplicate(true)
	rejected.sources["unsupported"] = unsupported
	_expect(not world.consumer.bind_environment(rejected) and world.enemy.get_spore_response_state().source_id == "", "valid first AshEnemy then unsupported middle source rejects pure whole binding preflight")
	unsupported.free()
	var second = Enemy.new()
	second.name = "SecondEnemy"
	second.configure(world.hero, world.effects)
	second.position = Vector3(6, 0.002, 0)
	world.root.add_child(second)
	second.set_physics_process(false)
	second.axis_lock_linear_x = true
	rejected = world.bindings.duplicate(true)
	rejected.sources["stale-source"] = second
	_expect(not world.consumer.bind_environment(rejected) and world.enemy.get_spore_response_state().source_id == "" and second.get_spore_response_state().source_id == "", "a supported later source with invalid actual body rejects before earlier source commit")
	second.free()
	_expect(world.consumer.bind_environment(world.bindings) and world.consumer.placement_accepted(), "same coordinator retries valid author binding after all mid-preflight rejections: " + world.consumer.last_error)
	paused = true
	var snapshot: Dictionary = world.consumer.snapshot_state(_context(world))
	_expect(snapshot.source_environments.keys() == ["grunt"] and snapshot.field_geometry.keys() == ["mushroom-a", "mushroom-b"], "rejected bind maps cannot leak stale source/field IDs into accepted snapshot")
	await _dispose(world)


func _live_binding_failure() -> void:
	var world: Dictionary = _world()
	await _ticks(5)
	_expect(world.consumer.bind_environment(world.bindings) and world.first.activate_cluster("left"), "live required-binding failure fixture acquires a real source route")
	await _wait_phase(world, "retreat")
	var required: MeshInstance3D = world.second.get_node("RequiredBrokenSporeBoundary")
	required.position.x += 0.02
	await _ticks(2)
	_expect(not world.consumer.placement_accepted() and world.enemy.get_spore_response_state().phase == "failed" and world.enemy.velocity == Vector3.ZERO and world.enemy.hp == 32.0 and world.consumer.get_node("Blocked_grunt") is Label3D, "drifted inactive required cue stops only owned retreat and visibly rejects encounter acceptance")
	await _dispose(world)


func _missing_owner_hurt() -> void:
	var world: Dictionary = _world()
	await _ticks(5)
	_expect(world.consumer.bind_environment(world.bindings) and world.first.activate_cluster("left"), "missing-owner hurt fixture has a real environmental lease")
	await _wait_phase(world, "retreat")
	world.enemy.take_damage(1.0, Vector3(0, 2, 0))
	var before: Dictionary = world.enemy.get_spore_response_state()
	world.consumer.free()
	await _ticks(3)
	var after: Dictionary = world.enemy.get_spore_response_state()
	_expect(after.position.y > before.position.y and after.hurt_remaining_s < before.hurt_remaining_s and world.enemy.hp == 31.0 and world.effects.bleeds == 1 and after.phase == "interrupted", "missing environmental owner preserves actual damage impulse/hurt/gravity without new spore recoil/attack")
	await _dispose(world)


func _punctuated_failure_id() -> void:
	var world: Dictionary = _world(Vector3(2.1, 0.002, 0), [Vector3.RIGHT], false)
	_box(world.root, "Wall", Vector3(2.85, 1, 0), Vector3(0.1, 2, 4))
	world.bindings.sources = {"act1.l3/grunt:01": world.enemy}
	await _ticks(5)
	_expect(world.consumer.bind_environment(world.bindings), "canonical punctuation source ID binds independently of Godot node-name restrictions")
	var rejected: Array = []
	world.consumer.placement_rejected.connect(func(id: String, _reason: String) -> void: rejected.append(id))
	_expect(world.first.activate_cluster("left") and rejected == ["act1.l3/grunt:01"] and world.consumer.get_node("Blocked_act1_l3_grunt_01") is Label3D, "visible blocked feedback sanitizes only node name while retaining exact canonical source ID")
	await _dispose(world)


func _world(source_position: Vector3 = Vector3(0, 0.002, 0), directions: Array = [Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3.RIGHT], two_fields: bool = true, hole: bool = false) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.name = "PhysicsFixture"
	viewport.own_world_3d = true
	viewport.size = Vector2i(64, 64)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var arena := Node3D.new()
	arena.name = "World"
	viewport.add_child(arena)
	var floor_body: StaticBody3D = _box(arena, "Floor", Vector3(-8.65 if hole else 0.0, -0.5, 0), Vector3(22.7 if hole else 40, 1, 40))
	var floor_shape: CollisionShape3D = floor_body.get_node("Shape")
	var hero := Hero.new()
	hero.name = "Hero"
	hero.position = Vector3(0, 0.002, 1.4)
	arena.add_child(hero)
	var effects := Effects.new()
	effects.name = "Effects"
	arena.add_child(effects)
	var enemy = Enemy.new()
	enemy.name = "Enemy"
	enemy.configure(hero, effects, 0)
	enemy.position = source_position
	arena.add_child(enemy)
	var first = _field(arena, "mushroom-a", Vector3.ZERO)
	var second = _field(arena, "mushroom-b", Vector3(2.5, 0, 0) if two_fields else Vector3(-9, 0, 0))
	var consumer = Consumer.new()
	consumer.name = "Repulsion"
	consumer.configure("spore-test", directions)
	arena.add_child(consumer)
	var safe := Rect2(-20, -20, 22.7 if hole else 40, 40)
	return {"viewport": viewport, "root": arena, "enemy": enemy, "hero": hero, "effects": effects, "first": first, "second": second, "consumer": consumer, "bindings": {"world_root": arena, "floors": {"ground": {"collision": floor_shape, "safe_rect": safe}}, "fields": {"mushroom-a": first, "mushroom-b": second}, "sources": {"grunt": enemy}}}


func _field(arena: Node3D, id: String, origin: Vector3):
	var field = Field.new()
	field.name = id
	field.configure(id, [{"id": "left", "offset": Vector3(-0.5, 0.7, 0)}, {"id": "right", "offset": Vector3(0.5, 0.7, 0)}])
	field.position = origin
	arena.add_child(field)
	return field


func _context(world: Dictionary) -> Dictionary:
	return {"fields": {"mushroom-a": _json(world.first.snapshot_state()), "mushroom-b": _json(world.second.snapshot_state())}, "sources": {"grunt": _json(world.enemy.snapshot_state())}}


func _box(parent: Node3D, label: String, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "Shape"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body


func _wait_phase(world: Dictionary, phase: String, maximum: int = 180) -> void:
	for _tick: int in range(maximum):
		var actual: String = world.enemy.get_spore_response_state().phase
		if actual == phase:
			return
		await _ticks(1)
	_expect(false, "phase %s timed out: %s / %s" % [phase, world.enemy.get_spore_response_state(), world.consumer.source_state("grunt")])


func _wait_attack(enemy: AshEnemy, state: String, maximum: int = 120) -> void:
	for _tick: int in range(maximum):
		if enemy.get_attack_state() == state:
			return
		await _ticks(1)
	_expect(false, "attack %s timed out: %s" % [state, enemy.get_attack_state()])


func _ticks(count: int) -> void:
	for _tick: int in range(count):
		await physics_frame
		await process_frame


func _dispose(world: Dictionary) -> void:
	paused = false
	world.viewport.free()
	await process_frame


func _json(value: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(value, "", true, true))


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
