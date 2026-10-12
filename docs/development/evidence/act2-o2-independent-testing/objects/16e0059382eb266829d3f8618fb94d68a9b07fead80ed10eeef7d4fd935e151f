extends SceneTree
## Actual shared Player/capsule/physics proofs. Preview is framing data, not an
## admission lease, camera controller, authored source or fairness certificate.

const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Player = preload("res://scripts/player.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Framing = preload("res://scripts/presentation/camera_framing.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_ensure_uid()
	await _test_pure_native_plan_and_camera()
	await _test_exact_stale_correspondence()
	await _test_preparing_and_active_union(false)
	await _test_preparing_and_active_union(true)
	await _test_stale_retention_and_callbacks()
	await _test_custom_collision_identity()
	await _test_actual_hero_physics_guards()
	print("Lunge preview smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_pure_native_plan_and_camera() -> void:
	var arena: Dictionary = await _arena()
	var scheduler = arena.scheduler
	var response: Dictionary = _response(arena)
	var threat: Dictionary = _threat()
	var before: Dictionary = _unit(arena)
	scheduler.last_error = "prior-request-diagnostic"
	scheduler.last_snapshot_error = "prior-snapshot-diagnostic"
	var events: Array[String] = []
	scheduler.reservation_invalidated.connect(func(_id: String, reason: String) -> void: events.append(reason))
	var preview: Dictionary = scheduler.preview_lunge(arena.source, threat, response)
	_expect(preview.get("accepted", false), "real shared Player/capsule obtains prospective supported endpoint and witness: " + String(preview.get("reason", "")))
	_expect(scheduler.last_error == "prior-request-diagnostic" and scheduler.last_snapshot_error == "prior-snapshot-diagnostic", "accepted pure preview preserves both diagnostics")
	_expect(events.is_empty() and not scheduler.has_committed_exchange() and _same(before, _unit(arena)), "pure preview allocates no serial/reservation/cooldown, changes no clock/actor/source and emits nothing")
	if not preview.get("accepted", false):
		await _dispose(arena)
		return
	var physical: Dictionary = Motion.plan(arena.source, threat.lunge, response.floor_regions)
	var measured_radius: float = (arena.source.get_node("BodyCollision").shape as CapsuleShape3D).radius
	_expect(_native_same(preview.plan, physical) and preview.plan.collision_shortened and preview.plan.planned_endpoint.x < -0.8 and preview.plan.body_signature.radius == measured_radius and is_equal_approx(measured_radius, 0.27), "preview uses actual full measured wall-shortened source plan, not a stationary proxy")
	_expect(preview.candidate.geometry == physical.geometry and preview.candidate.opening_position == physical.planned_endpoint and preview.proof.accepted and preview.proof.uses_blast == false, "prospective candidate exposes full corridor/end-point plus ordinary-primary selected witness")
	var anchors: Array = [physical.start, physical.start + Vector3.UP * 1.1, physical.planned_endpoint, physical.planned_endpoint + Vector3.UP * 1.1, preview.proof.landing, preview.proof.landing + Vector3.UP * 1.45, preview.proof.attack_position, arena.actor.global_position]
	for point: Vector3 in [physical.start, physical.planned_endpoint]:
		for x: float in [-0.31, 0.31]:
			for z: float in [-0.31, 0.31]: anchors.append(point + Vector3(x, 0.0, z))
	var spec := {"basis": Basis.looking_at(Vector3(0, -8, -7.5), Vector3.UP), "offset": Vector3(0, 8, 7.5), "width": 7.2, "viewport_size": Vector2(360, 640), "safe_rect": Rect2(0.08, 0.15, 0.84, 0.75), "max_shift": 4.0, "safety_margin": 0.055, "near": 0.05, "far": 100.0}
	var framed: Dictionary = Framing.plan(anchors, arena.actor.global_position, spec)
	_expect(framed.accepted and Framing.containment(anchors, framed.focus, spec).is_empty() and not scheduler.has_committed_exchange(), "actual supported landing/opening/full corridor fit camera prospectively without request/cancel")
	var changed_copy: Dictionary = preview.duplicate(true)
	changed_copy.proof.landing += Vector3.RIGHT
	changed_copy.plan.body_signature.radius = 99.0
	var fresh: Dictionary = scheduler.preview_lunge(arena.source, threat, response)
	_expect(_native_same(preview, fresh), "returned plan/proof/guard are defensive data and repeated pure preview is exact")
	var request: Dictionary = scheduler.request_lunge(arena.source, threat, response, preview)
	_expect(request.get("accepted", false), "paired request freshly reproofs and admits contemporaneous pure preview: " + String(request.get("reason", "")))
	if request.get("accepted", false):
		var admitted: Dictionary = request.reservation.duplicate(true)
		for key: String in ["id", "armed", "state"]: admitted.erase(key)
		_expect(_native_same(admitted, preview.candidate) and _native_same(request.proof, preview.proof), "accepted paired request commits same prospective candidate/selected proof")
		_expect(request.reservation_id == "threat-1" and request.reservation.adapter.start == preview.plan.start and arena.source.velocity == Vector3.ZERO, "preview did not spend serial1, reserve cooldown or move source before real admission")
		var current_unit: Dictionary = _unit(arena)
		_expect(not scheduler.request_lunge(arena.source, threat, response, preview).accepted and _same(current_unit, _unit(arena)), "reusing preview after source admission cannot bypass cooldown or union")
	await _dispose(arena)


func _test_exact_stale_correspondence() -> void:
	var arena: Dictionary = await _arena()
	var scheduler = arena.scheduler
	var response: Dictionary = _response(arena)
	var threat: Dictionary = _threat()
	var preview: Dictionary = scheduler.preview_lunge(arena.source, threat, response)
	if not preview.get("accepted", false):
		_expect(false, "stale correspondence requires accepted native fixture: " + String(preview.get("reason", "")))
		await _dispose(arena)
		return
	for mutation: String in ["clock-bit", "serial", "source-signature-bit", "world-bit", "candidate-time-bit", "landing", "native-type", "missing", "unknown"]:
		var bad: Dictionary = preview.duplicate(true)
		match mutation:
			"clock-bit": bad.guard.clock_s = _next_float(float(bad.guard.clock_s))
			"serial": bad.guard.serial += 1
			"source-signature-bit": bad.guard.source.body_signature.radius = _next_float(float(bad.guard.source.body_signature.radius))
			"world-bit": bad.guard.collision_fingerprint.colliders[0].priority = _next_float(float(bad.guard.collision_fingerprint.colliders[0].priority))
			"candidate-time-bit": bad.candidate.active_from_s = _next_float(float(bad.candidate.active_from_s))
			"landing": bad.proof.landing += Vector3(0.001, 0, 0)
			"native-type": bad.proof.landing = Codec.vector3(bad.proof.landing)
			"missing": bad.erase("guard")
			"unknown": bad.admission_authority = true
		var before: Dictionary = _unit(arena)
		_expect(not scheduler.request_lunge(arena.source, threat, response, bad).accepted and _same(before, _unit(arena)), "copied " + mutation + " forgery rejects exactly without admission/cooldown/serial effects")
	var pose: Vector3 = arena.source.global_position
	arena.source.global_position += Vector3(0, 0, 0.000001)
	_expect(not scheduler.request_lunge(arena.source, threat, _response(arena), preview).accepted and not scheduler.has_committed_exchange(), "actual sub-epsilon source pose change invalidates copied preview without loosening geometry14")
	arena.source.global_position = pose
	arena.source.velocity = Vector3(0.001, 0, 0)
	_expect(not scheduler.preview_lunge(arena.source, threat, _response(arena)).accepted, "actual moving source cannot obtain stopped lunge preview")
	arena.source.velocity = Vector3.ZERO
	var actor_pose: Vector3 = arena.actor.global_position
	arena.actor.global_position += Vector3(0, 0, 0.01)
	_expect(not scheduler.request_lunge(arena.source, threat, _response(arena), preview).accepted, "actual hero pose change rejects old selected landing witness")
	arena.actor.global_position = actor_pose
	var stale_response: Dictionary = _response(arena)
	stale_response.dash_cooldown_left_s = _next_float(float(stale_response.dash_cooldown_left_s))
	var diagnostic: String = scheduler.last_error
	_expect(not scheduler.preview_lunge(arena.source, threat, stale_response).accepted and scheduler.last_error == diagnostic, "one-bit copied live cooldown differs from public actual Player and pure rejection retains diagnostic")
	stale_response = _response(arena)
	stale_response.recognition_s += 0.01
	_expect(not scheduler.request_lunge(arena.source, threat, stale_response, preview).accepted, "changed authored recognition budget rejects correspondence")
	stale_response = _response(arena)
	stale_response.escape_directions.reverse()
	_expect(not scheduler.request_lunge(arena.source, threat, stale_response, preview).accepted, "candidate direction enumeration change cannot reuse preferred selected witness")
	var changed_threat: Dictionary = threat.duplicate(true)
	changed_threat.role.active_s += 0.01
	_expect(not scheduler.request_lunge(arena.source, changed_threat, _response(arena), preview).accepted, "changed resolved role timing rejects old candidate/plan guard")
	var wall_pose: Vector3 = arena.wall.global_position
	arena.wall.global_position.x -= 0.01
	_expect(not scheduler.request_lunge(arena.source, threat, _response(arena), preview).accepted, "current actual static world is freshly queried and changed wall rejects old shortened endpoint")
	arena.wall.global_position = wall_pose
	stale_response = _response(arena)
	stale_response.floor_regions = [{"collision": arena.floor_region.collision, "safe_rect": Rect2(-19.9, -20, 39.9, 40)}]
	_expect(not scheduler.request_lunge(arena.source, threat, stale_response, preview).accepted, "authored safe-floor domain changes invalidate copied preview even when route still fits")
	var old_shape: Shape3D = arena.floor_region.collision.shape
	var replacement := BoxShape3D.new()
	replacement.size = (old_shape as BoxShape3D).size
	arena.floor_region.collision.shape = replacement
	_expect(not scheduler.request_lunge(arena.source, threat, _response(arena), preview).accepted, "equivalent floor dimensions cannot substitute another bound actual shape resource identity")
	arena.floor_region.collision.shape = old_shape
	var unsupported: Dictionary = _response(arena)
	unsupported.erase("world_root")
	diagnostic = scheduler.last_error
	_expect(not scheduler.preview_lunge(arena.source, threat, unsupported).accepted and scheduler.last_error == diagnostic, "missing explicit world root fails closed without diagnostics mutation")
	unsupported = _response(arena)
	unsupported.stats.primary_range *= 1.01
	_expect(not scheduler.preview_lunge(arena.source, threat, unsupported).accepted, "caller stats cannot replace actual Player resolved equipment response")
	var recursive: Dictionary = {}
	recursive["again"] = recursive
	changed_threat = threat.duplicate(true)
	changed_threat["recursive"] = recursive
	diagnostic = scheduler.last_error
	_expect(not scheduler.preview_lunge(arena.source, changed_threat, _response(arena)).accepted and scheduler.last_error == diagnostic, "cyclic native caller data rejects before any deep-copy recursion or diagnostic mutation")
	recursive.clear()
	changed_threat = threat.duplicate(true)
	changed_threat["resource"] = RefCounted.new()
	_expect(not scheduler.preview_lunge(arena.source, changed_threat, _response(arena)).accepted, "unsupported arbitrary caller object cannot enter exact preview identity")
	arena.source.axis_lock_linear_x = true
	_expect(not scheduler.preview_lunge(arena.source, threat, _response(arena)).accepted and arena.source.axis_lock_linear_x, "actual unsupported axis-locked source fails closed without changing its body")
	arena.source.axis_lock_linear_x = false
	unsupported = _response(arena)
	unsupported.floor_regions = [{"collision": arena.floor_region.collision, "safe_rect": Rect2(-2.85, -20, 22.85, 40)}]
	_expect(not scheduler.preview_lunge(arena.source, threat, unsupported).accepted and not scheduler.has_committed_exchange(), "unsupported source floor route/hole-domain never manufactures camera landing")
	var old_clock: float = scheduler.get_clock()
	await _ticks(1)
	_expect(scheduler.get_clock() > old_clock and not scheduler.request_lunge(arena.source, threat, _response(arena), preview).accepted, "real scheduler/player clock advance rejects old preview exactly")
	var fresh: Dictionary = scheduler.preview_lunge(arena.source, threat, _response(arena))
	_expect(fresh.get("accepted", false) and scheduler.request_lunge(arena.source, threat, _response(arena), fresh).accepted, "new contemporaneous real proof admits after stale-clock rejection")
	await _dispose(arena)


func _test_preparing_and_active_union(active: bool) -> void:
	var arena: Dictionary = await _arena()
	var scheduler = arena.scheduler
	var circle: Dictionary = _circle(arena, 0.45 if active else 0.6, 1.0 if active else 0.16)
	var first: Dictionary = scheduler.request_attack(arena.other, circle, _response(arena))
	_expect(first.get("accepted", false), "real ordinary circle receives initial supported preparation: " + String(first.get("reason", "")))
	if not first.get("accepted", false):
		await _dispose(arena)
		return
	if active: await _until_clock(scheduler, float(first.reservation.active_from_s) + 0.05)
	var before: Dictionary = _unit(arena)
	var response: Dictionary = _response(arena)
	var threat: Dictionary = _threat()
	var preview: Dictionary = scheduler.preview_lunge(arena.source, threat, response)
	_expect(preview.get("accepted", false) and _same(before, _unit(arena)), "pure preview evaluates valid %s union without retiring existing threat" % ("active" if active else "preparing"))
	if preview.get("accepted", false):
		_expect(preview.guard.retained_union.size() == 1 and preview.guard.retained_union[0].record.id == first.reservation_id, "complete retained union is bound into copied guard")
		if active: _expect(preview.proof.landing.z > arena.actor.global_position.z, "active circle crossing eliminates forward landing and selects actual supported back flank")
		var admitted: Dictionary = scheduler.request_lunge(arena.source, threat, response, preview)
		_expect(admitted.get("accepted", false) and _native_same(admitted.proof, preview.proof), "real request shares same complete preparing/active proof path")
		var cooldown_unit: Dictionary = _unit(arena)
		scheduler.last_error = "retain-cooldown-rejection"
		_expect(not scheduler.preview_lunge(arena.source, threat, response).accepted and scheduler.last_error == "retain-cooldown-rejection" and _same(cooldown_unit, _unit(arena)), "occupied actual scheduler source cooldown rejects pure preview without cleanup/mutation")
	await _dispose(arena)


func _test_stale_retention_and_callbacks() -> void:
	var arena: Dictionary = await _arena()
	var scheduler = arena.scheduler
	var threat: Dictionary = _threat()
	var response: Dictionary = _response(arena)
	var original: Dictionary = scheduler.preview_lunge(arena.source, threat, response)
	var first: Dictionary = scheduler.request_attack(arena.other, _circle(arena), response)
	_expect(first.get("accepted", false), "union drift fixture admits real ordinary threat after pure lunge preview")
	var before: Dictionary = _unit(arena)
	_expect(not scheduler.request_lunge(arena.source, threat, response, original).accepted and _same(before, _unit(arena)), "new contemporaneous union/serial/cooldown invalidates old preview without consuming another source")
	var callbacks: Array[Dictionary] = []
	scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void:
		var diagnostic: String = scheduler.last_error
		var denied: Dictionary = scheduler.preview_lunge(arena.source, threat, _response(arena))
		callbacks.append({"denied": denied, "same_diagnostic": scheduler.last_error == diagnostic})
	)
	var moved: Vector3 = arena.other.global_position
	arena.other.global_position += Vector3.RIGHT
	var current_clock: float = scheduler.get_clock()
	scheduler.last_error = "retain-stale-union"
	var stale: Dictionary = scheduler.preview_lunge(arena.source, threat, _response(arena))
	_expect(not stale.accepted and callbacks.is_empty() and scheduler.has_committed_exchange() and scheduler.get_clock() == current_clock and scheduler.last_error == "retain-stale-union", "stale retained source rejects conservatively without prune/callback/clock/diagnostic mutation")
	_expect(not scheduler.request_lunge(arena.source, threat, _response(arena), original).accepted and callbacks.is_empty() and scheduler.has_committed_exchange(), "paired stale preview rejects before ordinary cleanup can emit cancellation")
	# Legacy request retains its cleanup policy and transaction guard. Callback
	# attempts at the pure seam fail without altering request diagnostics.
	var legacy: Dictionary = scheduler.request_lunge(arena.source, threat, _response(arena))
	_expect(legacy.get("accepted", false) and callbacks.size() == 1 and not callbacks[0].denied.accepted and callbacks[0].same_diagnostic, "legacy cleanup remains compatible and reentrant preview rejects during actual transaction")
	if legacy.get("accepted", false):
		scheduler.cancel(legacy.reservation_id)
		var after_cancel: Dictionary = _unit(arena)
		_expect(not scheduler.preview_lunge(arena.source, threat, _response(arena)).accepted and _same(after_cancel, _unit(arena)), "normal cancellation retains real source cooldown despite released geometry")
	arena.other.global_position = moved
	await _dispose(arena)


func _arena() -> Dictionary:
	paused = false
	var world := Node3D.new()
	world.name = "LungePreviewWorld"
	root.add_child(world)
	var floor: Dictionary = _box(world, "Floor", Vector3(0, -0.5, 0), Vector3(40, 1, 40))
	var wall: Dictionary = _box(world, "Wall", Vector3(-0.5, 1, 0), Vector3(0.2, 2, 10))
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
	world.add_child(source)
	source.position = Vector3(-3, 0, 0)
	var actor: CinderPlayer = Player.new()
	actor.name = "Hero"
	world.add_child(actor)
	actor.position = Vector3(-2.5, 0, 0)
	var other := Node3D.new()
	other.name = "CircleSource"
	world.add_child(other)
	other.position = Vector3(-2.5, 0, -1.5)
	var scheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	world.add_child(scheduler)
	await _ticks(5)
	scheduler.begin_encounter("standard", "lunge-preview", 1)
	return {"root": world, "source": source, "actor": actor, "other": other, "scheduler": scheduler, "wall": wall.body, "floor_region": {"collision": floor.collision, "safe_rect": Rect2(-20, -20, 40, 40)}}


func _test_custom_collision_identity() -> void:
	var arena: Dictionary = await _arena()
	var scheduler = arena.scheduler
	var collision: CollisionShape3D = arena.source.get_node("BodyCollision")
	collision.name = "CustomCapsule"
	var threat: Dictionary = _threat()
	threat.lunge.body_collision_path = "CustomCapsule"
	var preview: Dictionary = scheduler.preview_lunge(arena.source, threat, _response(arena))
	_expect(preview.get("accepted", false) and preview.guard.source.has("shape_instance_id") and preview.plan.body_collision_path == "CustomCapsule", "explicit custom collision path retains actual source node/resource identity: " + String(preview.get("reason", "")))
	if not preview.get("accepted", false):
		await _dispose(arena)
		return
	var old_shape: CapsuleShape3D = collision.shape
	var replacement := CapsuleShape3D.new()
	replacement.radius = old_shape.radius
	replacement.height = old_shape.height
	replacement.margin = old_shape.margin
	replacement.custom_solver_bias = old_shape.custom_solver_bias
	collision.shape = replacement
	var fresh: Dictionary = scheduler.preview_lunge(arena.source, threat, _response(arena))
	_expect(fresh.get("accepted", false) and _native_same(preview.plan, fresh.plan) and preview.guard.source.shape_instance_id != fresh.guard.source.shape_instance_id, "equivalent actual custom capsule remains physically legal but has different immutable resource binding")
	_expect(not scheduler.request_lunge(arena.source, threat, _response(arena), preview).accepted and not scheduler.has_committed_exchange(), "equivalent custom-path resource replacement rejects historical preview before admission")
	var admitted: Dictionary = scheduler.request_lunge(arena.source, threat, _response(arena))
	_expect(admitted.get("accepted", false) and admitted.reservation.adapter.body_collision_path == "CustomCapsule", "legacy three-argument custom-path request still admits freshly measured actual body")
	if not admitted.get("accepted", false):
		await _dispose(arena)
		return
	var second := CharacterBody3D.new()
	second.name = "SecondStalker"
	second.collision_layer = 2
	second.collision_mask = 1
	var second_collision := CollisionShape3D.new()
	second_collision.name = "SecondCapsule"
	var second_shape := CapsuleShape3D.new()
	second_shape.radius = 0.27
	second_shape.height = 1.1
	second_collision.shape = second_shape
	second_collision.position.y = 0.555
	second.add_child(second_collision)
	arena.root.add_child(second)
	second.position = Vector3(-3, 0, 0.1)
	await _ticks(1)
	var second_threat: Dictionary = _threat()
	second_threat.role = _role(1.2, 0.5)
	second_threat.lunge.body_collision_path = "SecondCapsule"
	var second_preview: Dictionary = scheduler.preview_lunge(second, second_threat, _response(arena))
	_expect(second_preview.get("accepted", false) and second_preview.guard.retained_union[0].actual_source.has("shape_instance_id"), "retained custom-path lunge exposes its actual source resource identity in another source preview: " + String(second_preview.get("reason", "")))
	if second_preview.get("accepted", false):
		var equivalent := CapsuleShape3D.new()
		equivalent.radius = replacement.radius
		equivalent.height = replacement.height
		equivalent.margin = replacement.margin
		equivalent.custom_solver_bias = replacement.custom_solver_bias
		collision.shape = equivalent
		var current: Dictionary = scheduler.preview_lunge(second, second_threat, _response(arena))
		_expect(current.get("accepted", false) and second_preview.guard.retained_union[0].actual_source.shape_instance_id != current.guard.retained_union[0].actual_source.shape_instance_id, "retained equivalent capsule replacement keeps physical proof legal but changes exact union resource identity")
		_expect(not scheduler.request_lunge(second, second_threat, _response(arena), second_preview).accepted, "copied preview cannot overlook another retained lunge's custom resource replacement")
		arena.source.add_collision_exception_with(arena.wall)
		var rejected: Dictionary = scheduler.preview_lunge(second, second_threat, _response(arena))
		_expect(not rejected.accepted and arena.source.get_collision_exceptions().size() == 1 and scheduler.has_committed_exchange(), "retained actual source descriptor error fails closed without dropping shape signature or pruning lease")
		arena.source.remove_collision_exception_with(arena.wall)
	await _dispose(arena)


func _test_actual_hero_physics_guards() -> void:
	var arena: Dictionary = await _arena()
	var scheduler = arena.scheduler
	var actor: CinderPlayer = arena.actor
	var threat: Dictionary = _threat()
	var response: Dictionary = _response(arena)
	_expect(response.stable and scheduler.preview_lunge(arena.source, threat, response).accepted, "actual settled shared Hero starts with supported live escape physics")
	scheduler.last_error = "retain-hero-guard-diagnostic"
	actor.axis_lock_linear_x = true
	response = _response(arena)
	var rejected: Dictionary = scheduler.preview_lunge(arena.source, threat, response)
	_expect(scheduler.response_error(response).is_empty() and not rejected.accepted and actor.axis_lock_linear_x and scheduler.last_error == "retain-hero-guard-diagnostic", "real stopped Hero axis lock passes legacy fixed-capsule preflight but fails new pure supported-body guard")
	actor.axis_lock_linear_x = false
	actor.collision_mask = 0
	rejected = scheduler.preview_lunge(arena.source, threat, _response(arena))
	_expect(not rejected.accepted and actor.collision_mask == 0 and scheduler.last_error == "retain-hero-guard-diagnostic", "actual ghost scenery mask cannot obtain fresh escape preview and remains untouched")
	actor.collision_mask = 1
	actor.add_collision_exception_with(arena.wall)
	rejected = scheduler.preview_lunge(arena.source, threat, _response(arena))
	_expect(not rejected.accepted and actor.get_collision_exceptions().size() == 1 and scheduler.last_error == "retain-hero-guard-diagnostic", "actual Hero collision exception fails closed without altering exception or diagnostic")
	actor.remove_collision_exception_with(arena.wall)
	_expect(scheduler.preview_lunge(arena.source, threat, _response(arena)).accepted and not scheduler.has_committed_exchange(), "restoring original actual Hero bindings permits a fresh pure preview without rearm")
	# Native conveyor floor establishes cached platform carry through actual
	# shared Player move_and_slide. No private timer/velocity metadata is forged.
	var floor: StaticBody3D = arena.floor_region.collision.get_parent()
	floor.constant_linear_velocity = Vector3(0.4, 0, 0)
	await _ticks(6)
	var carry: Vector3 = actor.get_platform_velocity()
	rejected = scheduler.preview_lunge(arena.source, threat, _response(arena))
	_expect(carry.length() > 0.1 and not rejected.accepted and String(rejected.reason).contains("Hero body") and actor.get_platform_velocity() == carry, "real floor-derived Hero platform carry rejects through supported-body guard without modifying actual carry")
	floor.constant_linear_velocity = Vector3.ZERO
	await _ticks(3)
	_expect(actor.get_platform_velocity().length() < 0.00001 and scheduler.preview_lunge(arena.source, threat, _response(arena)).accepted, "actual physics clears platform carry after original static floor restoration and fresh preview resumes")
	await _dispose(arena)


func _box(parent: Node3D, title: String, point: Vector3, size: Vector3) -> Dictionary:
	var body := StaticBody3D.new()
	body.name = title
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "Support"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.position = point
	return {"body": body, "collision": collision}


func _response(arena: Dictionary) -> Dictionary:
	var response: Dictionary = arena.actor.get_threat_response_state()
	response.merge({"world_root": arena.root, "world_revision": 1, "recognition_s": 0.1, "attack_input_margin_s": 0.02, "escape_directions": [Vector3.FORWARD, Vector3.BACK], "return_directions": [Vector3.FORWARD, Vector3.BACK], "floor_regions": [arena.floor_region]})
	return response


func _role(windup: float = 0.9, active: float = 0.5) -> Dictionary:
	return Difficulty.new().resolve_role({"raw_damage": 10.0, "windup_s": windup, "lock_s": 0.2, "active_s": active, "recovery_s": 1.6, "attack_interval_s": 1.6, "max_hp": 30.0, "move_speed": 2.6}, "standard", {"windup_s": windup, "lock_s": 0.2, "recovery_s": 1.6})


func _threat() -> Dictionary:
	return {"role": _role(), "source_stationary": false, "opening_stationary": true, "cooldown_remaining_s": 0.0, "lunge": {"direction": Vector3.RIGHT, "speed": 8.0, "distance": 3.8, "damage_radius": 0.31, "body_collision_path": "BodyCollision"}}


func _circle(arena: Dictionary, windup: float = 0.6, active: float = 0.16) -> Dictionary:
	return {"role": _role(windup, active), "geometry": Geometry.circle(arena.other.global_position, 0.31), "source_stationary": true, "opening_stationary": true, "opening_position": arena.other.global_position, "cooldown_remaining_s": 0.0}


func _unit(arena: Dictionary) -> Dictionary:
	var prior: bool = paused
	paused = true
	var saved: Dictionary = arena.scheduler.snapshot_state({"world_root": arena.root, "owners": {"stalker": arena.source, "circle": arena.other}, "floors": {"floor": arena.floor_region}})
	var result := {"scheduler": saved, "player": arena.actor.snapshot_state(), "source_position": Codec.vector3(arena.source.global_position), "source_velocity": Codec.vector3(arena.source.velocity)}
	paused = prior
	return result


func _same(left: Dictionary, right: Dictionary) -> bool:
	var encoded: String = Exact.stringify(left)
	return not encoded.is_empty() and encoded == Exact.stringify(right)


func _native_same(left: Variant, right: Variant) -> bool:
	if typeof(left) != typeof(right): return false
	if left is Dictionary:
		if left.size() != right.size(): return false
		for key: String in left:
			if not right.has(key) or not _native_same(left[key], right[key]): return false
		return true
	if left is Array:
		if left.size() != right.size(): return false
		for index: int in range(left.size()):
			if not _native_same(left[index], right[index]): return false
		return true
	return left == right


func _next_float(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes.encode_u64(0, bytes.decode_u64(0) + 1)
	return bytes.decode_double(0)


func _until_clock(scheduler: CinderThreatScheduler, target: float) -> void:
	while scheduler.get_clock() < target: await _ticks(1)


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame


func _dispose(arena: Dictionary) -> void:
	arena.root.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)


func _ensure_uid() -> void:
	var path: String = "res://tests/lunge_preview_smoke.gd.uid"
	if not FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_line(ResourceUID.id_to_text(ResourceUID.create_id()))
