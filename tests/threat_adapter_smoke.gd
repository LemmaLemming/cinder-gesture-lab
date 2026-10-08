extends SceneTree
## Two-stage tracking and real moving-source regression fixtures.

const World = preload("res://tests/fixtures/threat_world.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_tracking_warning_and_lock()
	await _test_tracking_failure_and_union()
	await _test_real_lunge_and_retry()
	await _test_lunge_cleanup_barriers()
	print("Threat adapter smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _ray(profile_id: String = "standard", windup_s: float = 1.55) -> Dictionary:
	var role: Dictionary = Difficulty.new().resolve_role({"raw_damage": 10.0, "windup_s": windup_s, "lock_s": 1.1, "active_s": 0.16, "recovery_s": 1.6, "attack_interval_s": 1.6, "max_hp": 30.0, "move_speed": 0.0}, profile_id, {"windup_s": windup_s, "lock_s": 1.1, "recovery_s": 1.6})
	return {"role": role, "geometry": Geometry.lane(Vector3.ZERO, Vector3(0, 0, 3.8), 0.31), "source_stationary": true, "opening_stationary": true, "opening_position": Vector3.ZERO, "cooldown_remaining_s": 0.0}


func _test_tracking_warning_and_lock() -> void:
	var arena: Dictionary = World.create(self)
	await physics_frame
	var scheduler: Variant = arena["scheduler"]
	scheduler.begin_encounter("standard", "scout-tracking")
	var context: Dictionary = World.response(arena)
	context["stable"] = false
	(arena["actor"] as CharacterBody3D).velocity = Vector3.RIGHT
	var result: Dictionary = scheduler.call("request_tracking", arena["source_a"], _ray(), context)
	_expect(result.get("accepted", false) and not result.get("armed", true), "moving hero can receive a reserved tracking warning without permission to activate damage")
	if not result.get("accepted", false):
		await _dispose(arena)
		return
	var reservation_id: String = result["reservation_id"]
	var updated: Dictionary = scheduler.call("update_tracking", reservation_id, Geometry.lane(Vector3.ZERO, Vector3.LEFT * 3.8, 0.31))
	_expect(updated.get("accepted", false) and scheduler.call("reservation_state", reservation_id)["geometry"]["to"] == Vector3.LEFT * 3.8, "warning preview retargets while its preparing slot remains owned")
	var stretched: Dictionary = scheduler.call("update_tracking", reservation_id, Geometry.lane(Vector3.ZERO, Vector3.LEFT * 4.8, 0.31))
	_expect(not stretched.get("accepted", false) and scheduler.call("reservation_state", reservation_id)["geometry"]["to"] == Vector3.LEFT * 3.8, "tracking preview cannot expand its committed reach while holding an old slot")
	paused = true
	await process_frame
	var bindings: Dictionary = World.bindings(arena)
	var pending: Dictionary = scheduler.snapshot_state(bindings)
	_expect(not pending.is_empty() and not pending["reservations"][0]["adapter"]["locked"], "pending tracking geometry/phase survives paused transport without becoming armed")
	_expect(scheduler.restore_state(JSON.parse_string(JSON.stringify(pending)), bindings), "pending tracking snapshot restores its warning and tentative deadlines exactly")
	var premature: Dictionary = pending.duplicate(true)
	premature["reservations"][0]["adapter"]["locked"] = true
	_expect(not scheduler.restore_state(premature, bindings) and Codec.same_values(pending, scheduler.snapshot_state(bindings)), "transport cannot manufacture an early tracking lock and rejection leaves state unchanged")
	paused = false
	(arena["actor"] as CharacterBody3D).velocity = Vector3.ZERO
	context["stable"] = true
	await _until_clock(scheduler, float(scheduler.call("reservation_state", reservation_id)["lock_from_s"]))
	var before_lock: float = scheduler.get_clock()
	var pending_before_lock: Dictionary = scheduler.call("reservation_state", reservation_id)
	var committed: Dictionary = scheduler.call("commit_tracking", reservation_id, Geometry.lane(Vector3.ZERO, Vector3(0, 0, 3.8), 0.31), context)
	if not committed.get("accepted", false):
		print("Tracking lock diagnostic: result=%s clock=%s previous=%s actor=%s velocity=%s" % [committed, before_lock, pending_before_lock, (arena["actor"] as CharacterBody3D).global_position, (arena["actor"] as CharacterBody3D).velocity])
	_expect(committed.get("accepted", false) and committed.get("armed", false), "immutable lock requires a fresh supported response proof")
	if committed.get("accepted", false):
		var locked: Dictionary = scheduler.call("reservation_state", reservation_id)
		_expect(locked["adapter"]["locked"] and float(locked["active_from_s"]) - before_lock >= 1.1 - 0.00001, "quantized late lock preserves Scout's full 1.10s locked lead instead of shortening recognition")
		_expect(locked["state"] == "lock" and is_equal_approx(float(locked["active_until_s"]) - float(locked["active_from_s"]), 0.16) and is_equal_approx(float(locked["recovery_until_s"]) - float(locked["active_until_s"]), 1.6) and is_equal_approx(float(locked["cooldown_until_s"]) - float(locked["active_from_s"]), 1.6), "successful tracking lock keeps resolved active/recovery/cooldown durations with authoritative lock state")
		var refused: Dictionary = scheduler.call("update_tracking", reservation_id, Geometry.lane(Vector3.ZERO, Vector3.RIGHT * 3.8, 0.31))
		_expect(not refused.get("accepted", false) and scheduler.call("reservation_state", reservation_id)["geometry"] == locked["geometry"], "locked geometry stays immutable through activation and recovery")
		paused = true
		await process_frame
		var snapshot: Dictionary = scheduler.snapshot_state(bindings)
		_expect(not snapshot.is_empty() and scheduler.restore_state(snapshot, bindings) and Codec.same_values(snapshot, scheduler.snapshot_state(bindings)), "locked retimed geometry and cooldown snapshot coherently without rescheduling")
	await _dispose(arena)


func _test_tracking_failure_and_union() -> void:
	var arena: Dictionary = World.create(self)
	await physics_frame
	var scheduler: Variant = arena["scheduler"]
	var context: Dictionary = World.response(arena)
	scheduler.begin_encounter("assisted", "tracking-budget")
	var first: Dictionary = scheduler.call("request_tracking", arena["source_a"], _ray("assisted"), context)
	await _until_clock(scheduler, scheduler.get_clock() + 0.2)
	var second: Dictionary = scheduler.call("request_tracking", arena["source_b"], _ray("assisted"), context)
	_expect(first.get("accepted", false) and not second.get("accepted", false) and String(second["reason"]).contains("budget"), "tracking tells occupy Assisted's preparing budget before any footprint locks")
	scheduler.end_encounter()
	scheduler.begin_encounter("standard", "failed-lock")
	first = scheduler.call("request_tracking", arena["source_a"], _ray(), context)
	await _until_clock(scheduler, float(scheduler.call("reservation_state", first["reservation_id"])["lock_from_s"]))
	var impossible: Dictionary = context.duplicate()
	impossible["escape_directions"] = [Vector3.LEFT]
	var failed: Dictionary = scheduler.call("commit_tracking", first["reservation_id"], Geometry.lane(Vector3.ZERO, Vector3.LEFT * 3.8, 0.31), impossible)
	_expect(not failed.get("accepted", false) and scheduler.reservations().is_empty(), "unproved locked landing visibly cancels the warning and cannot become active")
	scheduler.end_encounter()
	scheduler.begin_encounter("standard", "two-tracking")
	first = scheduler.call("request_tracking", arena["source_a"], _ray(), context)
	await _until_clock(scheduler, scheduler.get_clock() + 0.2)
	second = scheduler.call("request_tracking", arena["source_b"], _ray(), context)
	_expect(first.get("accepted", false) and second.get("accepted", false), "two visibly staggered tracking tells reserve their preparing slots")
	scheduler.end_encounter()
	scheduler.begin_encounter("standard", "tracking-union-reproof")
	first = scheduler.call("request_tracking", arena["source_a"], _ray(), context)
	await _until_clock(scheduler, float(scheduler.call("reservation_state", first["reservation_id"])["lock_from_s"]))
	var a_lock: Dictionary = scheduler.call("commit_tracking", first["reservation_id"], Geometry.lane(Vector3.ZERO, Vector3.LEFT * 3.8, 0.31), context)
	second = scheduler.call("request_tracking", arena["source_b"], _ray(), context)
	await _until_clock(scheduler, float(scheduler.call("reservation_state", second["reservation_id"])["lock_from_s"]))
	var b_lock: Dictionary = scheduler.call("commit_tracking", second["reservation_id"], Geometry.lane(Vector3.ZERO, Vector3.RIGHT * 3.8, 0.31), context)
	_expect(a_lock.get("accepted", false) and not b_lock.get("accepted", false) and scheduler.reservations().size() == 1, "second lock reproof checks the first committed lane and cancels an impossible combined response atomically")
	scheduler.end_encounter()
	scheduler.begin_encounter("standard", "missed-lock")
	var invalidations: Array[String] = []
	scheduler.reservation_invalidated.connect(func(_id: String, reason: String) -> void: invalidations.append(reason))
	first = scheduler.call("request_tracking", arena["source_a"], _ray(), context)
	await _until_clock(scheduler, float(first["reservation"]["active_from_s"]) + 0.02)
	_expect(first.get("accepted", false) and scheduler.reservations().is_empty() and invalidations.has("tracking_lock_missed"), "a tracking warning that never proves lock expires without an unproved active attack")
	await _dispose(arena)


func _test_real_lunge_and_retry() -> void:
	var arena: Dictionary = World.create(self)
	var source := CharacterBody3D.new()
	source.name = "Stalker"
	source.collision_layer = 2
	source.collision_mask = 1
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.27
	capsule.height = 1.1
	collision.shape = capsule
	collision.position.y = 0.555
	source.add_child(collision)
	arena["root"].add_child(source)
	source.position = Vector3(-3, 0, 0)
	arena["wall"].position.x = -0.5
	(arena["actor"] as CharacterBody3D).position = Vector3(-2.5, 0, 0)
	await physics_frame
	var scheduler: Variant = arena["scheduler"]
	scheduler.begin_encounter("standard", "physical-lunge")
	var threat: Dictionary = World.threat(0.6, 0.5)
	threat["source_stationary"] = false
	threat["lunge"] = {"direction": Vector3.RIGHT, "speed": 8.0, "distance": 3.8, "damage_radius": 0.31}
	var context: Dictionary = World.response(arena)
	context["escape_directions"] = [Vector3.FORWARD, Vector3.BACK]
	context["return_directions"] = [Vector3.FORWARD, Vector3.BACK]
	var unsupported: Dictionary = context.duplicate()
	unsupported["floor_regions"] = [{"collision": arena["floor_region"]["collision"], "safe_rect": Rect2(-2.85, -10, 12.85, 20)}]
	var hole: Dictionary = scheduler.call("request_lunge", source, threat, unsupported)
	_expect(not hole.get("accepted", false) and scheduler.reservations().is_empty() and source.global_position == Vector3(-3, 0, 0), "source route outside authored continuous support rejects without moving or allocating a reservation")
	var short_active: Dictionary = threat.duplicate(true)
	short_active["role"]["active_s"] = 0.1
	var clipped: Dictionary = scheduler.call("request_lunge", source, short_active, context)
	_expect(not clipped.get("accepted", false) and scheduler.reservations().is_empty(), "wall shortening cannot hide an active window shorter than full resolved lunge duration")
	var result: Dictionary = scheduler.call("request_lunge", source, threat, context)
	_expect(result.get("accepted", false), "actual moving source receives a committed collision-shortened lane and endpoint primary opening")
	if not result.get("accepted", false):
		await _dispose(arena)
		return
	var reservation_id: String = result["reservation_id"]
	var record: Dictionary = scheduler.call("reservation_state", reservation_id)
	_expect(is_equal_approx(record["adapter"]["body_signature"]["radius"], 0.27) and record["adapter"]["collision_shortened"] and record["opening_position"].x < -0.8, "reservation uses actual source dimensions and shortened physical recovery point")
	await _until_clock(scheduler, float(record["active_from_s"]) + 0.14)
	paused = true
	await process_frame
	var mid_position: Vector3 = source.global_position
	var mid_velocity: Vector3 = source.velocity
	var bindings: Dictionary = World.bindings(arena)
	bindings["owners"]["stalker"] = source
	var saved: Dictionary = scheduler.snapshot_state(bindings)
	_expect(not saved.is_empty() and mid_position.x > -3 and mid_position.x < -1.0 and not saved["reservations"][0]["adapter"]["finished"], "mid-active real lunge captures its source position, velocity and finite remaining motion")
	if saved.is_empty():
		print("Lunge scheduler snapshot diagnostic: ", scheduler.last_snapshot_error)
		await _dispose(arena)
		return
	var invalid: Dictionary = saved.duplicate(true)
	invalid["reservations"][0]["adapter"]["duration_s"] = 0.01
	_expect(not scheduler.restore_state(invalid, bindings) and Codec.same_values(saved, scheduler.snapshot_state(bindings)), "forged source duration cannot restore and failed validation leaves scheduler unchanged")
	var premature_landing: Dictionary = saved.duplicate(true)
	var early_record: Dictionary = premature_landing["reservations"][0]
	early_record["source_position"] = early_record["adapter"]["planned_endpoint"].duplicate()
	early_record["adapter"]["current_position"] = early_record["source_position"].duplicate()
	early_record["adapter"]["current_velocity"] = [0.0, 0.0, 0.0]
	early_record["adapter"]["finished"] = true
	early_record["adapter"]["actual_collided"] = true
	var staged_landing: Dictionary = bindings.duplicate(true)
	staged_landing["owner_positions"] = {"stalker": Codec.read_vector3(early_record["source_position"])}
	staged_landing["owner_velocities"] = {"stalker": Vector3.ZERO}
	_expect(String(scheduler.snapshot_error(premature_landing, staged_landing)).contains("travel time") and Codec.same_values(saved, scheduler.snapshot_state(bindings)), "finished collision flag cannot teleport a staged source to its endpoint before resolved travel time")
	var frozen: float = scheduler.get_clock()
	await create_timer(0.05, true).timeout
	_expect(source.global_position == mid_position and scheduler.get_clock() == frozen, "pause freezes real source movement and scheduler motion deadlines together")
	paused = false
	await _until_clock(scheduler, float(record["active_until_s"]) + 0.1)
	paused = true
	await process_frame
	var endpoint: Vector3 = source.global_position
	var finished: Dictionary = scheduler.call("reservation_state", reservation_id)
	if finished.is_empty():
		print("Lunge scheduler diagnostic: source=%s velocity=%s reservations=%s" % [source.global_position, source.velocity, scheduler.reservations()])
		_expect(false, "real lunge retains a recovery reservation through its proven opening")
		await _dispose(arena)
		return
	_expect(finished["state"] == "recovery" and finished["adapter"]["actual_collided"] and source.velocity == Vector3.ZERO and endpoint.distance_to(finished["opening_position"]) <= 0.005, "source physically collides and exposes recovery at its actual stopped endpoint")
	bindings["owner_positions"] = {"stalker": mid_position}
	bindings["owner_velocities"] = {"stalker": mid_velocity}
	_expect(scheduler.snapshot_error(saved, bindings).is_empty() and not scheduler.restore_state(saved, bindings) and source.global_position == endpoint, "staged source pose/velocity prevalidates, while commit requires the actual paired source restore")
	source.global_position = mid_position
	source.velocity = Vector3.ZERO
	_expect(not scheduler.restore_state(saved, bindings), "mid-active source position alone cannot commit without its saved velocity")
	source.velocity = mid_velocity
	var events: Array[String] = []
	scheduler.reservation_invalidated.connect(func(_id: String, reason: String) -> void: events.append(reason))
	_expect(scheduler.restore_state(JSON.parse_string(JSON.stringify(saved)), bindings) and events.is_empty(), "paired source restore plus scheduler restore resumes mid-lunge without cancellation/attack events")
	paused = false
	await _until_clock(scheduler, float(record["active_until_s"]) + 0.1)
	_expect(source.global_position.distance_to(endpoint) <= 0.005 and events.is_empty(), "restored collision-shortened movement reaches the same physical endpoint as uninterrupted continuation")
	scheduler.cancel(reservation_id, "stagger_before_impulse")
	source.velocity = Vector3.BACK
	_expect(scheduler.reservations().is_empty() and source.velocity == Vector3.BACK and events.has("stagger_before_impulse"), "owner cancellation releases real motion before applying a fresh stagger impulse")
	paused = true
	await process_frame
	var interrupted: Dictionary = scheduler.snapshot_state(bindings)
	_expect(not interrupted.is_empty() and not interrupted["cooldowns"].is_empty(), "ordinary lunge interruption preserves conservative scheduled cooldown after releasing geometry")
	await _dispose(arena)


func _test_lunge_cleanup_barriers() -> void:
	var arena: Dictionary = World.create(self)
	var source := CharacterBody3D.new()
	source.name = "Stalker"
	source.collision_layer = 2
	source.collision_mask = 1
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.27
	capsule.height = 1.1
	collision.shape = capsule
	collision.position.y = 0.555
	source.add_child(collision)
	arena["root"].add_child(source)
	source.position = Vector3(-3, 0, 0)
	arena["wall"].position.x = -0.5
	(arena["actor"] as CharacterBody3D).position = Vector3(-2.5, 0, 0)
	await physics_frame
	var scheduler: Variant = arena["scheduler"]
	scheduler.begin_encounter("standard", "cleanup-boundaries")
	var context: Dictionary = World.response(arena)
	context["escape_directions"] = [Vector3.FORWARD, Vector3.BACK]
	context["return_directions"] = [Vector3.FORWARD, Vector3.BACK]
	var warning: Dictionary = scheduler.call("request_tracking", arena["source_a"], _ray(), context)
	var reentrant: Array[Dictionary] = []
	var mutate_on_cancel: Callable = func(_id: String, _reason: String) -> void:
		source.position.z += 0.1
		reentrant.append(scheduler.call("request_tracking", arena["source_b"], _ray(), context))
	scheduler.reservation_invalidated.connect(mutate_on_cancel)
	(arena["source_a"] as Node3D).position = Vector3.FORWARD
	var threat: Dictionary = World.threat(0.6, 0.5)
	threat["source_stationary"] = false
	threat["lunge"] = {"direction": Vector3.RIGHT, "speed": 8.0, "distance": 3.8, "damage_radius": 0.31}
	var result: Dictionary = scheduler.call("request_lunge", source, threat, context)
	_expect(warning.get("accepted", false) and not result.get("accepted", false) and scheduler.reservations().is_empty(), "cleanup callback source mutation rejects a stale lunge plan before publishing an armed reservation")
	_expect(reentrant.size() == 1 and not reentrant[0].get("accepted", false) and String(reentrant[0]["reason"]).contains("transaction"), "cancellation callback cannot allocate another tracking reservation inside request validation")
	scheduler.reservation_invalidated.disconnect(mutate_on_cancel)
	source.position = Vector3(-3, 0, 0)
	result = scheduler.call("request_lunge", source, threat, context)
	_expect(result.get("accepted", false), "source can commit a fresh coherent plan after the callback barrier completes")
	if result.get("accepted", false):
		await _until_clock(scheduler, float(result["reservation"]["active_from_s"]) + 0.14)
		var before: Vector3 = source.global_position
		var moving: bool = source.velocity.length() > 0.0
		var events: Array[String] = []
		scheduler.reservation_invalidated.connect(func(_id: String, reason: String) -> void: events.append(reason))
		# Deliberately simulate an unusually long physics tick, with the tree
		# unpaused. Normal expiry must stop an outstanding real motion lease.
		scheduler.call("_physics_process", 4.0)
		_expect(moving and scheduler.reservations().is_empty() and source.velocity == Vector3.ZERO and source.global_position == before and events.is_empty(), "normal expiry after a long tick stops leased velocity without emitting cancellation or extra movement")
	await _dispose(arena)


func _until_clock(scheduler: Variant, deadline: float) -> void:
	# SceneTree timers may run ahead of fixed physics after pause/transport work.
	# Every protocol assertion consumes the public simulation deadline instead.
	while scheduler.get_clock() + 0.00001 < deadline:
		await physics_frame


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
