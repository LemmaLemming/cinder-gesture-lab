extends SceneTree
## Actual-body lifecycle transport. The retained source is a test-only actor
## with ordinary shared-player damage; its actor-state validator models the
## caller-owned paused aggregate hook without importing any Act 3 content.

const World = preload("res://tests/fixtures/threat_world.gd")
const Player = preload("res://scripts/player.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")

class RetainedLunger:
	extends CharacterBody3D
	signal defeated
	var hp: float = 12.0
	var dead: bool = false
	var damage_calls: int = 0
	var death_count: int = 0
	var scheduler: Node3D

	func _ready() -> void:
		add_to_group("enemies")

	func take_damage(amount: float, _impulse: Vector3) -> Dictionary:
		damage_calls += 1
		var was_alive: bool = not dead and hp > 0.0
		var result := {"accepted": false, "hp_damage": 0.0, "target_id": get_instance_id(), "target_alive_before_hit": was_alive}
		if not was_alive or amount <= 0.0:
			return result
		var before: float = hp
		hp = maxf(0.0, hp - amount)
		result["accepted"] = true
		result["hp_damage"] = before - hp
		if hp == 0.0:
			dead = true
			death_count += 1
			scheduler.call("cancel_owner", self, "source_defeated")
			velocity = Vector3.ZERO
			collision_layer = 0
			collision_mask = 0
			(get_node("BodyCollision") as CollisionShape3D).set_deferred("disabled", true)
			remove_from_group("enemies")
			visible = false
			defeated.emit()
		return result

var _checks: int = 0
var _failures: int = 0
var _events: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _retained_death_and_restore()
	print("Staged lunge collision smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _retained_death_and_restore() -> void:
	var arena: Dictionary = _create_arena()
	var source: RetainedLunger = arena["source"]
	var hero: CinderPlayer = arena["actor"]
	var scheduler: CinderThreatScheduler = arena["scheduler"]
	var collision: CollisionShape3D = source.get_node("BodyCollision")
	var plain: Dictionary = _bindings(arena)
	await _ticks(4)
	_expect(Motion.staged_source_description(source, _live_collision()).has("error"), "pure staged descriptor requires the paused aggregate boundary")
	hero.hp = 7.0
	hero.shells = 0
	_expect(scheduler.begin_encounter("standard", "retained-capsule"), "real source begins a standard encounter")
	var threat: Dictionary = World.threat(0.6, 0.5)
	threat["source_stationary"] = false
	threat["lunge"] = {"direction": Vector3.RIGHT, "speed": 8.0, "distance": 3.8, "damage_radius": 0.31}
	var response: Dictionary = World.response(arena)
	response["escape_directions"] = [Vector3.FORWARD, Vector3.BACK]
	response["return_directions"] = [Vector3.FORWARD, Vector3.BACK]
	var accepted: Dictionary = scheduler.request_lunge(source, threat, response)
	_expect(accepted.get("accepted", false), "actual retained body receives a wall-shortened lunge lease")
	if not accepted.get("accepted", false):
		print("Initial staged lunge diagnostic: ", accepted)
		await _dispose(arena)
		return
	var reservation_id: String = accepted["reservation_id"]
	var record: Dictionary = scheduler.reservation_state(reservation_id)
	await _until(scheduler, float(record["active_from_s"]) + 0.14)
	paused = true
	await process_frame
	var saved_actor: Dictionary = _actor_state(source)
	var saved_player: Dictionary = hero.snapshot_state()
	var saved_scheduler: Dictionary = scheduler.snapshot_state(plain)
	_expect(not saved_scheduler.is_empty() and saved_scheduler["reservations"][0]["adapter"]["collision_shortened"] and not saved_scheduler["reservations"][0]["adapter"]["finished"] and source.velocity == Vector3.RIGHT * 8.0, "capture is an actual mid-active shortened route with leased velocity")
	if saved_scheduler.is_empty():
		print("Mid-active diagnostic: ", scheduler.last_snapshot_error)
		await _dispose(arena)
		return
	var aggregate := {"actor": saved_actor, "player": saved_player, "scheduler": saved_scheduler}
	var parsed: Dictionary = ExactJson.parse(ExactJson.stringify(aggregate))
	_expect(parsed.get("accepted", false) and ExactJson.stringify(parsed.get("value", {})) == ExactJson.stringify(aggregate), "real actor/player/scheduler pair survives exact tagged JSON with all clocks and native number types")
	if not parsed.get("accepted", false):
		await _dispose(arena)
		return
	aggregate = parsed["value"]
	saved_actor = aggregate["actor"]
	saved_player = aggregate["player"]
	saved_scheduler = aggregate["scheduler"]
	var staged: Dictionary = _staged_bindings(plain, saved_actor)
	_expect(_actor_error(saved_actor).is_empty() and hero.snapshot_error(saved_player).is_empty() and scheduler.snapshot_error(saved_scheduler, staged).is_empty(), "all earlier live actor envelopes prevalidate together before any commit")
	# First establish the actual uninterrupted stopped endpoint and clocks.
	paused = false
	await _until(scheduler, float(record["active_until_s"]) + 0.1)
	paused = true
	await process_frame
	var uninterrupted: Dictionary = scheduler.snapshot_state(plain)
	var endpoint: Vector3 = source.global_position
	_expect(not uninterrupted.is_empty() and scheduler.reservation_state(reservation_id)["state"] == "recovery" and source.velocity == Vector3.ZERO, "uninterrupted actual capsule reaches its stationary recovery opening")
	_expect(_restore_actor(source, saved_actor) and hero.restore_state(saved_player) and scheduler.restore_state(saved_scheduler, plain), "existing live actor-before-scheduler restore remains supported without collision staging")
	# Real zero-ammo ordinary primary kills the retained body, rather than setting
	# HP or collision flags directly to fabricate a defeated lifecycle.
	paused = false
	_expect(hero.slash(Vector3.RIGHT) == 1, "ordinary shared-player primary kills the nearby moving source with zero blast ammo")
	await process_frame
	paused = true
	await process_frame
	_expect(source.dead and source.hp == 0.0 and source.death_count == 1 and source.damage_calls == 1 and source.is_inside_tree() and not source.is_queued_for_deletion(), "actual death leaves the source node retained without a second damage or removal")
	_expect(collision.disabled and source.collision_layer == 0 and source.collision_mask == 0 and source.get_shape_owners().size() == 1 and source.is_shape_owner_disabled(source.get_shape_owners()[0]), "defeated source retains its registered capsule while actual collision is disabled and layer/mask are zero")
	_expect(scheduler.reservations().is_empty() and scheduler.snapshot_state(plain)["cooldowns"].is_empty(), "actual death cancels the old lease and owner cooldown")
	_expect(Motion.source_description(source).has("error"), "strict live descriptor still rejects the defeated body")
	_expect(not scheduler.snapshot_error(saved_scheduler, _staged_motion_only(plain, saved_actor)).is_empty(), "unstaged earlier live lunge still rejects disabled actual collision")
	var before: String = _state_text(arena)
	var described: Dictionary = Motion.staged_source_description(source, _live_collision())
	_expect(not described.has("error") and described["collision"] == collision and described["radius"] == (collision.shape as CapsuleShape3D).radius, "staged descriptor derives geometry and registered collider from the actual retained body")
	_expect(scheduler.snapshot_error(saved_scheduler, staged).is_empty() and scheduler.snapshot_error(saved_scheduler, staged).is_empty() and before == _state_text(arena), "repeated earlier live prevalidation is pure: no re-enable, movement, HP, clock, table or callback mutation")
	_expect(not scheduler.restore_state(saved_scheduler, staged) and before == _state_text(arena), "prevalidation does not authorize commit before actual actor pose/velocity/collision restore")
	# Native lifecycle schema cannot carry replacement geometry, a caller hash,
	# an alias path, or another source identity.
	var malformed: Array[Dictionary] = []
	var bad: Dictionary = staged.duplicate(true)
	bad["owner_collision_states"] = []
	malformed.append(bad)
	bad = staged.duplicate(true)
	bad["owner_collision_states"]["stalker"] = []
	malformed.append(bad)
	for key: String in ["collision_path", "enabled", "layer", "mask"]:
		bad = staged.duplicate(true)
		bad["owner_collision_states"]["stalker"].erase(key)
		malformed.append(bad)
	for replacement: Dictionary in [{"enabled": false}, {"enabled": "true"}, {"layer": 1}, {"layer": 2.0}, {"layer": -2}, {"layer": 4294967296}, {"mask": 0}, {"mask": 1.0}, {"collision_path": "Missing"}, {"collision_path": "./BodyCollision"}, {"collision_path": "BodyCollision\n"}, {"geometry": {}}, {"body_signature": saved_scheduler["reservations"][0]["adapter"]["body_signature"]}, {"collision_hash": "caller-proxy"}]:
		bad = staged.duplicate(true)
		bad["owner_collision_states"]["stalker"].merge(replacement, true)
		malformed.append(bad)
	bad = staged.duplicate(true)
	bad["owner_collision_states"]["unknown-source"] = _live_collision()
	malformed.append(bad)
	bad = staged.duplicate(true)
	bad["owner_collision_states"]["scout-a"] = _live_collision()
	malformed.append(bad)
	bad = staged.duplicate(true)
	bad["owner_collision_states"] = {&"stalker": _live_collision()}
	malformed.append(bad)
	for index: int in range(malformed.size()):
		_expect_rejected(arena, saved_scheduler, malformed[index], "malformed lifecycle binding %d rejects before any scheduler/body/player mutation" % index)
	bad = saved_scheduler.duplicate(true)
	bad["reservations"][0]["adapter"]["body_signature"]["radius"] += 0.0000000001
	_expect_rejected(arena, bad, staged, "even tiny saved immutable capsule-radius drift rejects rather than using the old approximate signature comparison")
	bad = staged.duplicate(true)
	bad["owner_collision_states"]["stalker"]["layer"] = 8
	_expect_rejected(arena, saved_scheduler, bad, "valid non-scenery layer cannot replace the saved immutable layer identity")
	var alternate_layer: Dictionary = Motion.staged_source_description(source, {"collision_path": "BodyCollision", "enabled": true, "layer": 8, "mask": 1})
	_expect(not alternate_layer.has("error") and alternate_layer["signature"]["layer"] == 8, "descriptor supports a legal non-scenery actor layer without forcing layer two")
	await _extra_and_changed_geometry(arena, saved_scheduler, staged)
	# Exact actual lifecycle registration must be present at commit, even if a
	# caller has already applied only the saved pose and leased velocity.
	source.global_position = Codec.read_vector3(saved_actor["position"])
	source.velocity = Codec.read_vector3(saved_actor["velocity"])
	_expect_rejected_commit(arena, saved_scheduler, staged, "actual saved pose and velocity alone cannot bypass the disabled-capsule commit guard")
	var calls: int = source.damage_calls
	var deaths: int = source.death_count
	var event_count: int = _events.size()
	_expect(_restore_actor(source, saved_actor) and hero.restore_state(saved_player), "validated actor and player state applies first at the paused boundary")
	_expect(scheduler.restore_state(saved_scheduler, staged), "scheduler commits after actual restored enabled capsule, layer, mask, position and velocity match")
	_expect(_events.size() == event_count and source.damage_calls == calls and source.death_count == deaths and hero.hp == 7.0 and hero.shells == 0 and source.hp == 12.0, "paired commit emits no damage, death, action or invalidation and preserves exact saved resources")
	_expect(ExactJson.stringify(scheduler.snapshot_state(plain)) == ExactJson.stringify(saved_scheduler), "quiet commit restores exact exchange identity, deadlines, profile, geometry and serial without retiming")
	var paused_state: String = _state_text(arena)
	await create_timer(0.04, true).timeout
	_expect(_state_text(arena) == paused_state, "pause freezes restored physical motion and both actor/scheduler clocks")
	paused = false
	await _until(scheduler, float(record["active_until_s"]) + 0.1)
	paused = true
	await process_frame
	var resumed: Dictionary = scheduler.snapshot_state(plain)
	_expect(source.global_position.distance_to(endpoint) <= Motion.ENDPOINT_TOLERANCE and source.velocity == Vector3.ZERO and resumed["clock_s"] == uninterrupted["clock_s"], "restored real motion reaches the same collision-shortened endpoint on the same simulation tick")
	_expect(resumed["reservations"][0]["cooldown_until_s"] == uninterrupted["reservations"][0]["cooldown_until_s"] and resumed["cooldowns"] == uninterrupted["cooldowns"] and source.damage_calls == calls and source.death_count == deaths, "continued restore retains exact cooldown and never reexecutes damage or death")
	# A new actual world with its original live collision needs no staged state.
	await _dispose(arena)
	arena = _create_arena()
	paused = true
	await process_frame
	source = arena["source"]
	hero = arena["actor"]
	scheduler = arena["scheduler"]
	plain = _bindings(arena)
	_expect(_restore_actor(source, saved_actor) and hero.restore_state(saved_player) and scheduler.snapshot_error(saved_scheduler, plain).is_empty() and scheduler.restore_state(saved_scheduler, plain), "fresh-world existing live collision restore remains unchanged and needs no lifecycle binding")
	_expect(ExactJson.stringify(scheduler.snapshot_state(plain)) == ExactJson.stringify(saved_scheduler), "fresh actual world retains the original serialized snapshot schema and exact exchange")
	await _dispose(arena)


func _extra_and_changed_geometry(arena: Dictionary, snapshot: Dictionary, staged: Dictionary) -> void:
	var source: RetainedLunger = arena["source"]
	var collision: CollisionShape3D = source.get_node("BodyCollision")
	var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D
	var old_radius: float = capsule.radius
	capsule.radius = old_radius + 0.001
	_expect_rejected(arena, snapshot, staged, "actual retained capsule resource geometry drift rejects staged transport")
	capsule.radius = old_radius
	var original_position: Vector3 = collision.position
	collision.position.x = 0.000001
	_expect_rejected(arena, snapshot, staged, "actual tiny capsule-centre drift rejects exact saved geometry even inside motion tolerance")
	collision.position = original_position
	var extra := CollisionShape3D.new()
	extra.name = "ExtraEnabled"
	extra.shape = CapsuleShape3D.new()
	source.add_child(extra)
	_expect_rejected(arena, snapshot, staged, "extra actual enabled source collider rejects the closed single-capsule descriptor")
	extra.disabled = true
	_expect_rejected(arena, snapshot, staged, "extra disabled retained collider cannot hide from exact retained-registration validation")
	extra.free()
	var pending := CollisionShape3D.new()
	pending.name = "PendingEmptyCollider"
	source.add_child(pending)
	_expect_rejected(arena, snapshot, staged, "extra pending collider child with no shape cannot be silently omitted")
	pending.free()
	var shape_owner: int = source.get_shape_owners()[0]
	var original_transform: Transform3D = source.shape_owner_get_transform(shape_owner)
	source.shape_owner_set_transform(shape_owner, Transform3D(Basis.IDENTITY, original_transform.origin + Vector3(0.001, 0, 0)))
	_expect_rejected(arena, snapshot, staged, "registered transform mismatch rejects without substituting node geometry")
	source.shape_owner_set_transform(shape_owner, original_transform)
	source.shape_owner_set_disabled(shape_owner, false)
	_expect_rejected(arena, snapshot, staged, "pending registered/node lifecycle disagreement rejects before commit")
	source.shape_owner_set_disabled(shape_owner, true)
	var empty_owner: int = source.create_shape_owner(source)
	_expect_rejected(arena, snapshot, staged, "extra registered empty shape owner cannot impersonate the retained capsule")
	source.remove_shape_owner(empty_owner)
	_expect(arena["scheduler"].snapshot_error(snapshot, staged).is_empty(), "restoring actual fixture geometry leaves valid lifecycle staging supported")
	await process_frame


func _create_arena() -> Dictionary:
	var arena: Dictionary = World.create(self)
	(arena["actor"] as CharacterBody3D).free()
	var hero: CinderPlayer = Player.new()
	hero.name = "Hero"
	hero.position = Vector3(-2.5, 0.02, 0)
	(arena["root"] as Node3D).add_child(hero)
	arena["actor"] = hero
	var source := RetainedLunger.new()
	source.name = "RetainedStalker"
	source.collision_layer = 2
	source.collision_mask = 1
	source.position = Vector3(-3, 0, 0)
	source.scheduler = arena["scheduler"]
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.27
	capsule.height = 1.1
	collision.shape = capsule
	collision.position.y = 0.555
	source.add_child(collision)
	(arena["root"] as Node3D).add_child(source)
	arena["source"] = source
	(arena["wall"] as Node3D).position.x = -0.5
	source.defeated.connect(func() -> void: _events.append("death"))
	(arena["scheduler"] as CinderThreatScheduler).reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _events.append("invalidation"))
	hero.world_action_executed.connect(func(_value: Dictionary) -> void: _events.append("world-action"))
	hero.fired.connect(func(_kind: String) -> void: _events.append("fired"))
	return arena


func _bindings(arena: Dictionary) -> Dictionary:
	var result: Dictionary = World.bindings(arena)
	result["owners"]["stalker"] = arena["source"]
	return result


func _staged_motion_only(bindings: Dictionary, actor: Dictionary) -> Dictionary:
	var result: Dictionary = bindings.duplicate(true)
	result["owner_positions"] = {"stalker": Codec.read_vector3(actor["position"])}
	result["owner_velocities"] = {"stalker": Codec.read_vector3(actor["velocity"])}
	return result


func _staged_bindings(bindings: Dictionary, actor: Dictionary) -> Dictionary:
	var result: Dictionary = _staged_motion_only(bindings, actor)
	# This is an actor-derived hook after actor schema validation, never copied
	# from scheduler data or supplied immutable geometry.
	if _actor_error(actor).is_empty() and not actor["dead"]:
		result["owner_collision_states"] = {"stalker": _live_collision()}
	return result


func _live_collision() -> Dictionary:
	return {"collision_path": "BodyCollision", "enabled": true, "layer": 2, "mask": 1}


func _actor_state(source: RetainedLunger) -> Dictionary:
	return {"fixture_api": "retained-lunger-fixture-1", "hp": source.hp, "dead": source.dead, "position": Codec.vector3(source.global_position), "velocity": Codec.vector3(source.velocity)}


func _actor_error(state: Dictionary) -> String:
	if not Codec.value_error(state).is_empty() or not Codec.keys_error(state, ["fixture_api", "hp", "dead", "position", "velocity"]).is_empty() or state.get("fixture_api") != "retained-lunger-fixture-1" or not Codec.in_range(state.get("hp"), 0.0, 12.0) or not state.get("dead") is bool or state["dead"] != (state["hp"] == 0.0) or not Codec.is_vector3(state.get("position")) or not Codec.is_vector3(state.get("velocity")):
		return "Invalid retained test actor snapshot"
	return ""


func _restore_actor(source: RetainedLunger, state: Dictionary) -> bool:
	if not paused or not _actor_error(state).is_empty():
		return false
	source.global_position = Codec.read_vector3(state["position"])
	source.velocity = Codec.read_vector3(state["velocity"])
	source.hp = state["hp"]
	source.dead = state["dead"]
	source.collision_layer = 0 if source.dead else 2
	source.collision_mask = 0 if source.dead else 1
	(source.get_node("BodyCollision") as CollisionShape3D).disabled = source.dead
	source.visible = not source.dead
	if source.dead:
		source.remove_from_group("enemies")
	else:
		source.add_to_group("enemies")
	return true


func _state_text(arena: Dictionary) -> String:
	var source: RetainedLunger = arena["source"]
	var collision: CollisionShape3D = source.get_node("BodyCollision")
	var shapes: Array = []
	for owner_id: int in source.get_shape_owners():
		var transform: Transform3D = source.shape_owner_get_transform(owner_id)
		shapes.append({"id": owner_id, "count": source.shape_owner_get_shape_count(owner_id), "disabled": source.is_shape_owner_disabled(owner_id), "transform": [Codec.vector3(transform.basis.x), Codec.vector3(transform.basis.y), Codec.vector3(transform.basis.z), Codec.vector3(transform.origin)]})
	return ExactJson.stringify({"actor": _actor_state(source), "player": arena["actor"].snapshot_state(), "scheduler": arena["scheduler"].snapshot_state(_bindings(arena)), "layer": source.collision_layer, "mask": source.collision_mask, "disabled": collision.disabled, "visible": source.visible, "group": source.is_in_group("enemies"), "radius": (collision.shape as CapsuleShape3D).radius, "centre": Codec.vector3(collision.position), "registrations": shapes, "events": _events.duplicate(), "damage_calls": source.damage_calls, "death_count": source.death_count})


func _expect_rejected(arena: Dictionary, snapshot: Dictionary, bindings: Dictionary, description: String) -> void:
	var before: String = _state_text(arena)
	var error: String = arena["scheduler"].snapshot_error(snapshot, bindings)
	var accepted: bool = arena["scheduler"].restore_state(snapshot, bindings)
	_expect(not error.is_empty() and not accepted and _state_text(arena) == before, description)


func _expect_rejected_commit(arena: Dictionary, snapshot: Dictionary, bindings: Dictionary, description: String) -> void:
	var before: String = _state_text(arena)
	_expect(arena["scheduler"].snapshot_error(snapshot, bindings).is_empty() and not arena["scheduler"].restore_state(snapshot, bindings) and _state_text(arena) == before, description)


func _until(scheduler: CinderThreatScheduler, deadline: float) -> void:
	while scheduler.get_clock() < deadline:
		await physics_frame


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
	await process_frame


func _dispose(arena: Dictionary) -> void:
	arena["root"].queue_free()
	await process_frame
	paused = false


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
