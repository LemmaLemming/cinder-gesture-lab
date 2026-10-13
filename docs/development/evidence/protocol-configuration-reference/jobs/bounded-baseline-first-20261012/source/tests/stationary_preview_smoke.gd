extends SceneTree
## Actual shared Hero/native fixed-world proof; no authored level acceptance or
## source HP/damage consumer is implemented by this prospective framing fixture.

const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Player = preload("res://scripts/player.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_geometry_and_correspondence()
	await _test_exact_forgery_and_live_drift()
	await _test_union(false)
	await _test_union(true)
	await _test_stale_cleanup_and_callback()
	await _test_native_source_and_hero()
	await _test_world_and_input_boundaries()
	print("Stationary preview smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_geometry_and_correspondence() -> void:
	for kind: String in ["circle", "cone", "lane", "crescent"]:
		var arena: Dictionary = await _arena()
		var scheduler = arena.scheduler
		var response: Dictionary = _response(arena)
		var threat: Dictionary = _threat(arena.source, kind)
		var before: Dictionary = _unit(arena)
		var events: Array[String] = []
		scheduler.reservation_invalidated.connect(func(_id: String, reason: String) -> void: events.append(reason))
		scheduler.last_error = "prior-request"
		scheduler.last_snapshot_error = "prior-snapshot"
		var preview: Dictionary = scheduler.preview_stationary(arena.source, threat, response)
		_expect(preview.get("accepted", false), kind + " actual stationary-source proof has supported ordinary escape/opening: " + String(preview.get("reason", "")))
		_expect(scheduler.last_error == "prior-request" and scheduler.last_snapshot_error == "prior-snapshot", kind + " pure result preserves both diagnostic fields")
		_expect(events.is_empty() and not scheduler.has_committed_exchange() and _same(before, _unit(arena)), kind + " preview has no allocation, clock, flag, callback or actor/source mutation")
		if not preview.get("accepted", false):
			await _dispose(arena)
			continue
		_expect(preview.api_revision == "stationary-preview-1" and preview.candidate.geometry == threat.geometry and preview.candidate.opening_position == threat.opening_position and preview.proof.uses_blast == false and preview.proof.uses_invulnerability == false, kind + " retains actual geometry/opening and ordinary-primary witness without moving proxy")
		var copied: Dictionary = preview.duplicate(true)
		copied.proof.landing += Vector3.RIGHT
		copied.guard.source.transform.origin += Vector3.UP
		_expect(_native_same(preview, scheduler.preview_stationary(arena.source, threat, response)), kind + " returns defensive data and repeat proof is exact")
		var admitted: Dictionary = scheduler.request_attack(arena.source, threat, response, preview)
		_expect(admitted.get("accepted", false), kind + " unchanged fourth argument is freshly proved and admitted: " + String(admitted.get("reason", "")))
		if admitted.get("accepted", false):
			var record: Dictionary = admitted.reservation.duplicate(true)
			for key: String in ["id", "armed", "state"]: record.erase(key)
			_expect(_native_same(record, preview.candidate) and _native_same(admitted.proof, preview.proof) and admitted.reservation_id == "threat-1", kind + " request commits exact prospective candidate/proof and untouched serial1")
			var committed: Dictionary = _unit(arena)
			_expect(not scheduler.request_attack(arena.source, threat, response, preview).accepted and _same(committed, _unit(arena)), kind + " used preview cannot bypass live source cooldown/union")
		await _dispose(arena)


func _test_exact_forgery_and_live_drift() -> void:
	var arena: Dictionary = await _arena()
	var scheduler = arena.scheduler
	var threat: Dictionary = _threat(arena.source)
	var response: Dictionary = _response(arena)
	var preview: Dictionary = scheduler.preview_stationary(arena.source, threat, response)
	if not _require(preview, "exact stationary correspondence"):
		await _dispose(arena)
		return
	for mutation: String in ["clock-bit", "serial", "source-transform", "world-bit", "candidate-time-bit", "landing", "native-type", "missing", "unknown", "api"]:
		var bad: Dictionary = preview.duplicate(true)
		match mutation:
			"clock-bit": bad.guard.clock_s = _next_float(float(bad.guard.clock_s))
			"serial": bad.guard.serial += 1
			"source-transform": bad.guard.source.transform.origin.x += 0.000001
			"world-bit": bad.guard.collision_fingerprint.colliders[0].priority = _next_float(float(bad.guard.collision_fingerprint.colliders[0].priority))
			"candidate-time-bit": bad.candidate.active_from_s = _next_float(float(bad.candidate.active_from_s))
			"landing": bad.proof.landing += Vector3(0.001, 0, 0)
			"native-type": bad.proof.landing = Codec.vector3(bad.proof.landing)
			"missing": bad.erase("guard")
			"unknown": bad.fake_authority = true
			"api": bad.api_revision = "lunge-preview-1"
		var before: Dictionary = _unit(arena)
		_expect(not scheduler.request_attack(arena.source, threat, response, bad).accepted and _same(before, _unit(arena)), "copied " + mutation + " rejects exactly without any allocation")
	var pose: Vector3 = arena.source.global_position
	arena.source.global_position += Vector3(0, 0, 0.000001)
	_expect(not scheduler.request_attack(arena.source, threat, _response(arena), preview).accepted and not scheduler.has_committed_exchange(), "actual sub-epsilon source move rejects copied guard despite unchanged geometry tolerance")
	arena.source.global_position = pose
	arena.source.rotation.y = 0.000001
	_expect(not scheduler.request_attack(arena.source, threat, _response(arena), preview).accepted, "actual stationary source basis change rejects exact presentation/source custody")
	arena.source.rotation = Vector3.ZERO
	var actor_pose: Vector3 = arena.actor.global_position
	arena.actor.global_position += Vector3(0, 0, 0.01)
	_expect(not scheduler.request_attack(arena.source, threat, _response(arena), preview).accepted, "actual Hero move rejects old landing witness")
	arena.actor.global_position = actor_pose
	var changed: Dictionary = _response(arena)
	changed.primary_cooldown_left_s = _next_float(float(changed.primary_cooldown_left_s))
	scheduler.last_error = "preserved-pure-rejection"
	scheduler.last_snapshot_error = "preserved-snapshot-rejection"
	_expect(not scheduler.preview_stationary(arena.source, threat, changed).accepted and scheduler.last_error == "preserved-pure-rejection" and scheduler.last_snapshot_error == "preserved-snapshot-rejection", "one-bit fabricated actual public response rejects without either diagnostic change")
	changed = _response(arena)
	changed.recognition_s += 0.01
	_expect(not scheduler.request_attack(arena.source, threat, changed, preview).accepted, "changed authored recognition budget cannot reuse prospective proof")
	changed = _response(arena)
	changed.escape_directions.reverse()
	_expect(not scheduler.request_attack(arena.source, threat, changed, preview).accepted, "changed candidate order rejects selected-proof correspondence")
	var changed_threat: Dictionary = threat.duplicate(true)
	changed_threat.role.active_s += 0.01
	_expect(not scheduler.request_attack(arena.source, changed_threat, _response(arena), preview).accepted, "resolved deadline changes reject exact copied candidate")
	var wall_pose: Vector3 = arena.wall.global_position
	arena.wall.global_position.x += 0.01
	_expect(not scheduler.request_attack(arena.source, threat, _response(arena), preview).accepted, "changed actual static world fingerprint rejects even when distant wall leaves route clear")
	arena.wall.global_position = wall_pose
	var floor_shape: Shape3D = arena.floor_region.collision.shape
	var equivalent := BoxShape3D.new()
	equivalent.size = (floor_shape as BoxShape3D).size
	arena.floor_region.collision.shape = equivalent
	_expect(not scheduler.request_attack(arena.source, threat, _response(arena), preview).accepted, "equivalent authored floor resource replacement invalidates exact bound identity")
	arena.floor_region.collision.shape = floor_shape
	changed = _response(arena)
	changed.floor_regions = [{"collision": arena.floor_region.collision, "safe_rect": Rect2(-19.9, -20, 39.9, 40)}]
	_expect(not scheduler.request_attack(arena.source, threat, changed, preview).accepted, "changed safe-floor domain rejects copied correspondence")
	var old_clock: float = scheduler.get_clock()
	await _ticks(1)
	_expect(scheduler.get_clock() > old_clock and not scheduler.request_attack(arena.source, threat, _response(arena), preview).accepted, "actual scheduler/Hero tick advances invalidate old ephemeral clock exactly")
	var fresh: Dictionary = scheduler.preview_stationary(arena.source, threat, _response(arena))
	_expect(fresh.get("accepted", false) and scheduler.request_attack(arena.source, threat, _response(arena), fresh).accepted, "fresh contemporaneous actual proof admits after stale-clock rejection")
	await _dispose(arena)


func _test_union(active: bool) -> void:
	var arena: Dictionary = await _arena()
	var scheduler = arena.scheduler
	var threat: Dictionary = _threat(arena.other, "circle", 0.45 if active else 0.6, 1.0 if active else 0.16)
	var first: Dictionary = scheduler.request_attack(arena.other, threat, _response(arena))
	if not _require(first, "ordinary union prerequisite"):
		await _dispose(arena)
		return
	if active: await _until_clock(scheduler, float(first.reservation.active_from_s) + 0.05)
	var before: Dictionary = _unit(arena)
	var current_threat: Dictionary = _threat(arena.source, "circle", 1.4)
	var response: Dictionary = _response(arena)
	var preview: Dictionary = scheduler.preview_stationary(arena.source, current_threat, response)
	_expect(preview.get("accepted", false) and _same(before, _unit(arena)), "complete %s union obtains pure stationary witness without retiring original" % ("active" if active else "preparing"))
	if preview.get("accepted", false):
		_expect(preview.guard.retained_union.size() == 1 and preview.guard.retained_union[0].record.id == first.reservation_id and preview.guard.cooldowns.size() == 1, "copied stationary guard binds full actual retained union and cooldown")
		if active: _expect(preview.proof.landing.z > arena.actor.global_position.z, "active circle removes forward landing and chooses supported back flank")
		var admitted: Dictionary = scheduler.request_attack(arena.source, current_threat, response, preview)
		_expect(admitted.get("accepted", false) and _native_same(admitted.proof, preview.proof), "paired request uses same preparing/active whole-union witness")
	await _dispose(arena)


func _test_stale_cleanup_and_callback() -> void:
	var arena: Dictionary = await _arena()
	var scheduler = arena.scheduler
	var threat: Dictionary = _threat(arena.source, "circle", 1.4)
	var response: Dictionary = _response(arena)
	var original: Dictionary = scheduler.preview_stationary(arena.source, threat, response)
	var first: Dictionary = scheduler.request_attack(arena.other, _threat(arena.other), response)
	if not _require(original, "pre-union prospective fixture") or not _require(first, "actual retained fixture"):
		await _dispose(arena)
		return
	var before: Dictionary = _unit(arena)
	_expect(not scheduler.request_attack(arena.source, threat, response, original).accepted and _same(before, _unit(arena)), "new same-clock source/serial/cooldown/union invalidates copied stationary preview without cleanup")
	var callbacks: Array[Dictionary] = []
	scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void:
		var diagnostic: String = scheduler.last_error
		var denied: Dictionary = scheduler.preview_stationary(arena.source, threat, _response(arena))
		callbacks.append({"denied": denied, "same_diagnostic": scheduler.last_error == diagnostic})
	)
	arena.other.global_position += Vector3.RIGHT
	scheduler.last_error = "retain-stale-diagnostic"
	var clock: float = scheduler.get_clock()
	var stale: Dictionary = scheduler.preview_stationary(arena.source, threat, _response(arena))
	_expect(not stale.accepted and callbacks.is_empty() and scheduler.has_committed_exchange() and scheduler.get_clock() == clock and scheduler.last_error == "retain-stale-diagnostic", "stale source union rejects pure preview without prune/callback/clock/diagnostic changes")
	_expect(not scheduler.request_attack(arena.source, threat, _response(arena), original).accepted and callbacks.is_empty() and scheduler.has_committed_exchange(), "stale paired request rejects before ordinary cleanup could cancel another source")
	var legacy: Dictionary = scheduler.request_attack(arena.source, threat, _response(arena))
	_expect(legacy.get("accepted", false) and callbacks.size() == 1 and not callbacks[0].denied.accepted and callbacks[0].same_diagnostic, "legacy three-argument request retains ordinary cleanup and callback transaction exclusion")
	if legacy.get("accepted", false):
		scheduler.cancel(legacy.reservation_id, "ordinary_cancel")
		before = _unit(arena)
		_expect(not scheduler.preview_stationary(arena.source, threat, _response(arena)).accepted and _same(before, _unit(arena)), "released stationary geometry retains actual source cooldown; pure preview cannot age it")
	await _dispose(arena)


func _test_native_source_and_hero() -> void:
	var arena: Dictionary = await _arena()
	var scheduler = arena.scheduler
	var source := CharacterBody3D.new()
	source.name = "NativeBoxSource"
	source.collision_layer = 2
	source.collision_mask = 1
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 1.0, 0.5)
	collision.shape = box
	collision.position.y = 0.5
	source.add_child(collision)
	arena.root.add_child(source)
	source.position = Vector3(0.5, 0, 1.0)
	var threat: Dictionary = _threat(source)
	var response: Dictionary = _response(arena)
	var preview: Dictionary = scheduler.preview_stationary(source, threat, response)
	_expect(preview.get("accepted", false) and preview.guard.source.body_signature.shape.type == "BoxShape3D", "genuine stationary native BOX retains measured collision descriptor, no capsule/source proxy")
	source.velocity = Vector3(0.000001, 0, 0)
	_expect(not scheduler.preview_stationary(source, threat, _response(arena)).accepted and source.velocity == Vector3(0.000001, 0, 0), "even sub-epsilon commanded native source velocity rejects stationary claim without zeroing source")
	source.velocity = Vector3.ZERO
	source.axis_lock_linear_x = true
	_expect(not scheduler.preview_stationary(source, threat, _response(arena)).accepted and source.axis_lock_linear_x, "unsupported actual source axis lock fails pure native descriptor without mutation")
	source.axis_lock_linear_x = false
	var equivalent := BoxShape3D.new()
	equivalent.size = box.size
	collision.shape = equivalent
	_expect(preview.get("accepted", false) and not scheduler.request_attack(source, threat, _response(arena), preview).accepted and not scheduler.has_committed_exchange(), "equivalent genuine source BOX resource replacement rejects exact copied identity")
	collision.shape = box
	arena.actor.axis_lock_linear_x = true
	_expect(not scheduler.preview_stationary(arena.source, _threat(arena.source), _response(arena)).accepted and arena.actor.axis_lock_linear_x, "actual Hero unsupported axis lock cannot borrow copied fixed-capsule response")
	arena.actor.axis_lock_linear_x = false
	arena.actor.add_collision_exception_with(arena.wall)
	_expect(not scheduler.preview_stationary(arena.source, _threat(arena.source), _response(arena)).accepted and arena.actor.get_collision_exceptions().size() == 1, "actual Hero scenery exception fails native response proof and remains intact")
	arena.actor.remove_collision_exception_with(arena.wall)
	var fresh: Dictionary = scheduler.preview_stationary(source, threat, _response(arena))
	_expect(fresh.get("accepted", false) and scheduler.request_attack(source, threat, _response(arena), fresh).accepted, "restoring supported real Hero/source permits fresh stationary BOX admission")
	var rigid := RigidBody3D.new()
	rigid.name = "UnsupportedMovingSource"
	arena.root.add_child(rigid)
	rigid.position = Vector3(-0.5, 0, 1.0)
	_expect(not scheduler.preview_stationary(rigid, _threat(rigid, "circle", 1.4), _response(arena)).accepted, "unsupported native rigid source cannot declare stationary framing proof")
	await _dispose(arena)


func _test_world_and_input_boundaries() -> void:
	var arena: Dictionary = await _arena()
	var scheduler = arena.scheduler
	var threat: Dictionary = _threat(arena.source)
	var response: Dictionary = _response(arena)
	scheduler.last_error = "pure-boundaries"
	scheduler.last_snapshot_error = "snapshot-boundaries"
	var changed: Dictionary = threat.duplicate(true)
	changed.source_stationary = false
	_expect(not scheduler.preview_stationary(arena.source, changed, response).accepted, "moving-source authored flag requires a supported moving adapter rather than stationary preview")
	changed = threat.duplicate(true)
	changed.geometry.origin += Vector3.RIGHT
	_expect(not scheduler.preview_stationary(arena.source, changed, response).accepted, "detached geometry origin cannot impersonate actual stationary source")
	changed = _threat(arena.source, "lane")
	changed.geometry.from += Vector3.RIGHT
	_expect(not scheduler.preview_stationary(arena.source, changed, response).accepted, "detached lane from cannot impersonate actual stationary source")
	var missing: Dictionary = response.duplicate()
	missing.erase("world_root")
	_expect(not scheduler.preview_stationary(arena.source, threat, missing).accepted, "explicit common containing world root required")
	missing = response.duplicate()
	missing.world_root = arena.source
	_expect(not scheduler.preview_stationary(arena.source, threat, missing).accepted, "source-only root does not contain actual shared Hero and Scheduler")
	missing = _response(arena)
	missing.stats.primary_range *= 1.01
	_expect(not scheduler.preview_stationary(arena.source, threat, missing).accepted, "fabricated actor equipment/range cannot license stationary witness")
	var cycle: Dictionary = {}
	cycle.again = cycle
	changed = threat.duplicate(true)
	changed.recursive = cycle
	_expect(not scheduler.preview_stationary(arena.source, changed, response).accepted, "cyclic threat rejects bounded preflight before any recursive deep copy")
	cycle.clear()
	changed = threat.duplicate(true)
	changed.resource = RefCounted.new()
	_expect(not scheduler.preview_stationary(arena.source, changed, response).accepted, "arbitrary source object cannot enter exact native preview guard")
	var oversized: Array = []
	oversized.resize(16385)
	changed = threat.duplicate(true)
	changed.extra = oversized
	_expect(not scheduler.preview_stationary(arena.source, changed, response).accepted, "oversized caller container rejects without allocation")
	var floor: StaticBody3D = arena.floor_region.collision.get_parent()
	floor.constant_linear_velocity = Vector3(0.1, 0, 0)
	_expect(not scheduler.preview_stationary(arena.source, threat, response).accepted and floor.constant_linear_velocity == Vector3(0.1, 0, 0), "native moving static-floor world rejected without editing velocities")
	floor.constant_linear_velocity = Vector3.ZERO
	paused = true
	_expect(not scheduler.preview_stationary(arena.source, threat, response).accepted, "paused live world cannot obtain prospective active admission")
	paused = false
	_expect(scheduler.last_error == "pure-boundaries" and scheduler.last_snapshot_error == "snapshot-boundaries" and not scheduler.has_committed_exchange(), "all pure rejection branches preserve request/snapshot diagnostics and allocation state")
	var preview: Dictionary = scheduler.preview_stationary(arena.source, threat, _response(arena))
	_expect(preview.get("accepted", false) and scheduler.request_attack(arena.source, threat, _response(arena), preview).accepted, "repaired exact native world admits fresh stationary proof")
	await _dispose(arena)


func _arena() -> Dictionary:
	paused = false
	var world := Node3D.new()
	world.name = "StationaryPreviewWorld"
	root.add_child(world)
	var floor: Dictionary = _box(world, "Floor", Vector3(0, -0.5, 0), Vector3(40, 1, 40))
	var wall: Dictionary = _box(world, "DistantWall", Vector3(8, 1, 0), Vector3(0.2, 2, 8))
	var actor: CinderPlayer = Player.new()
	actor.name = "Hero"
	world.add_child(actor)
	actor.position = Vector3.ZERO
	var source := Node3D.new()
	source.name = "FixedSource"
	world.add_child(source)
	source.position = Vector3(0.5, 0, 0)
	var other := Node3D.new()
	other.name = "OtherFixedSource"
	world.add_child(other)
	other.position = Vector3(0, 0, -1.5)
	var scheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	world.add_child(scheduler)
	await _ticks(5)
	_expect(scheduler.begin_encounter("standard", "stationary-preview", 1), "fresh isolated native fixture starts fixed encounter")
	return {"root": world, "source": source, "other": other, "actor": actor, "scheduler": scheduler, "wall": wall.body, "floor_region": {"collision": floor.collision, "safe_rect": Rect2(-20, -20, 40, 40)}}


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


func _role(windup: float = 0.7, active: float = 0.16) -> Dictionary:
	return Difficulty.new().resolve_role({"raw_damage": 10.0, "windup_s": windup, "lock_s": 0.2, "active_s": active, "recovery_s": 2.0, "attack_interval_s": 2.0, "max_hp": 30.0, "move_speed": 0.0}, "standard", {"windup_s": windup, "lock_s": 0.2, "recovery_s": 2.0})


func _threat(source: Node3D, kind: String = "circle", windup: float = 0.7, active: float = 0.16) -> Dictionary:
	var origin: Vector3 = source.global_position
	var geometry: Dictionary
	match kind:
		"cone": geometry = Geometry.cone(origin, Vector3.FORWARD, 1.5, 0.55, 0.1)
		"crescent": geometry = Geometry.crescent(origin, Vector3.FORWARD, 0.4, 1.5, 0.55)
		"lane": geometry = Geometry.lane(origin, origin + Vector3.FORWARD * 1.5, 0.2)
		_: geometry = Geometry.circle(origin, 0.3)
	return {"role": _role(windup, active), "geometry": geometry, "source_stationary": true, "opening_stationary": true, "opening_position": origin, "cooldown_remaining_s": 0.0}


func _unit(arena: Dictionary) -> Dictionary:
	var prior: bool = paused
	paused = true
	var saved: Dictionary = arena.scheduler.snapshot_state({"world_root": arena.root, "owners": {"source": arena.source, "other": arena.other}, "floors": {"floor": arena.floor_region}})
	var actor_saved: Dictionary = arena.actor.snapshot_state()
	_expect(not saved.is_empty() and not actor_saved.is_empty(), "purity comparison uses nonempty exact actual Scheduler/Player snapshots")
	var result := {"scheduler": saved, "player": actor_saved, "source_position": Codec.vector3(arena.source.global_position), "source_basis": [Codec.vector3(arena.source.global_basis.x), Codec.vector3(arena.source.global_basis.y), Codec.vector3(arena.source.global_basis.z)], "transaction_depth": arena.scheduler.get("_transaction_depth"), "request_busy": arena.scheduler.get("_request_busy"), "snapshot_busy": arena.scheduler.get("_snapshot_busy"), "boundary_busy": arena.scheduler.get("_boundary_busy")}
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


func _require(answer: Dictionary, label: String) -> bool:
	var accepted: bool = answer.get("accepted", false)
	_expect(accepted, label + ": " + String(answer.get("reason", "")))
	return accepted


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
