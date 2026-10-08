extends SceneTree
## Actual translated native scenery/body motion. No authored level, damage,
## focus control or changed collider. BOX uses BodySweep; lunge is CAPSULE only.

const Sweep = preload("res://scripts/combat/body_sweep.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const PlayerScene = preload("res://scenes/player.tscn")
const World = preload("res://tests/fixtures/threat_world.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const WORKER_START: Vector3 = Vector3(-2.663714647293091, -0.00415944354608655, 30.974029541015625)
const WORKER_DIRECTION: Vector3 = Vector3(0.9883923530578613, 0, 0.15192313492298126)
const DISTANCE: float = 3.0
const SPEED: float = 12.0

var _checks: int = 0
var _failures: int = 0
var _finished: bool = false
var _measurements: Array[Dictionary] = []
var _output: String


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_ensure_uid()
	_output = "res://.cinder/translated-lunge-%d.json" % OS.get_process_id()
	create_timer(25.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "bounded 25 second translated fixture watchdog")
			_finish()
	)
	for kind: String in ["capsule", "box"]:
		for z: float in [WORKER_START.z, -12.4]:
			for sign: float in [-1.0, 1.0]:
				var start := Vector3(WORKER_START.x * sign, WORKER_START.y if kind == "capsule" else 0.0002, z)
				for direction: Vector3 in [Vector3.RIGHT * sign, Vector3(WORKER_DIRECTION.x * sign, 0, WORKER_DIRECTION.z * sign), Vector3(sign, 0, sign).normalized()]:
					await _free_case(kind, start, direction, Vector3.ZERO)
		for sign: float in [-1.0, 1.0]:
			var start := Vector3(510.0 * sign, WORKER_START.y if kind == "capsule" else 0.0002, 510.0 * sign)
			await _free_case(kind, start, WORKER_DIRECTION * -sign, Vector3(506.0 * sign, 0, 470.0 * sign))
		await _wall_controls(kind)
	await _scheduler_transport()
	_finish()


func _free_case(kind: String, start: Vector3, direction: Vector3, floor_centre: Vector3) -> void:
	var arena: Dictionary = await _arena(kind, start, floor_centre)
	var body: CharacterBody3D = arena.source
	var original: Transform3D = body.global_transform
	var velocity: Vector3 = body.velocity
	var intended: Vector3 = direction * DISTANCE
	var analytical_endpoint: Vector3 = original.origin + intended
	var tolerance: float = _native_position_bound(original.origin, analytical_endpoint)
	var sweep: Dictionary = Sweep.sweep(body, original, intended, [arena.floor_region])
	var label: String = "%s start=%s dir=%s" % [kind, original.origin, direction]
	_expect(not sweep.has("error") and body.global_transform == original and body.velocity == velocity, label + " actual-body prediction is pure: " + String(sweep.get("error", "")))
	if sweep.has("error"):
		await _dispose(arena)
		return
	var endpoint_error: float = (sweep.end as Vector3).distance_to(analytical_endpoint)
	_expect(not sweep.collided and endpoint_error <= tolerance and sweep.end.y == original.origin.y, label + " clear measured route reaches one native analytical endpoint without cumulative drift")
	var parity: bool = true
	var real_contact: bool = false
	var maximum_step_error: float = 0.0
	for step: Dictionary in sweep.steps:
		var contact: KinematicCollision3D = body.move_and_collide(step.motion, false, Sweep.SAFE_MARGIN, false, 1)
		var delta: float = body.global_position.distance_to(step.end)
		maximum_step_error = maxf(maximum_step_error, delta)
		real_contact = real_contact or contact != null
		parity = parity and delta <= tolerance and (contact != null) == bool(step.collided)
	_expect(parity and not real_contact and body.global_position.y == original.origin.y, label + " pure returned motion matches actual native M&C at every executed pose without floor lifting")
	_expect(body.global_position.distance_to(analytical_endpoint) <= tolerance and body.global_position.distance_to(sweep.end) <= tolerance, label + " actual clear travel preserves the bounded translated endpoint")
	_measurements.append({"kind": kind, "start": Codec.vector3(original.origin), "direction": Codec.vector3(direction), "native_endpoint": Codec.vector3(analytical_endpoint), "prediction": Codec.vector3(sweep.end), "actual": Codec.vector3(body.global_position), "prediction_error_m": endpoint_error, "maximum_step_parity_error_m": maximum_step_error, "native_position_bound_m": tolerance, "actual_contact": real_contact})
	if kind == "capsule":
		for incremental: bool in [false, true]:
			body.global_transform = original
			body.velocity = Vector3.ZERO
			var plan: Dictionary = Motion.plan(body, _motion(direction), [arena.floor_region])
			_expect(not plan.has("error") and body.global_transform == original and body.velocity == Vector3.ZERO, label + " translated native capsule obtains a real pure lunge plan: " + String(plan.get("error", "")))
			if plan.has("error"):
				continue
			_expect(not plan.collision_shortened and plan.planned_endpoint.distance_to(analytical_endpoint) <= tolerance, label + " no-contact preview cannot invent collision shortening from native rounding")
			var state: Dictionary = plan
			if incremental:
				for tick: int in range(1, 16):
					await physics_frame
					state = Motion.advance(body, state, float(tick) / 60.0, [arena.floor_region])
					if state.has("error") or state.get("finished", false):
						break
			else:
				state = Motion.advance(body, state, DISTANCE / SPEED, [arena.floor_region])
			_expect(not state.has("error") and state.get("finished", false) and not state.get("actual_collided", true) and not state.get("collision_shortened", true), label + " actual " + ("incremental" if incremental else "full-duration") + " lunge finishes without a fabricated contact: " + String(state.get("error", "")))
			_expect(body.global_position.y == original.origin.y and body.global_position.distance_to(analytical_endpoint) <= tolerance and body.velocity == Vector3.ZERO, label + " actual lunge deliberately stops at its bounded native endpoint")
			if not state.has("error"):
				var stopped: Transform3D = body.global_transform
				state = Motion.advance(body, state, 1.0, [arena.floor_region])
				_expect(not state.has("error") and body.global_transform == stopped and body.velocity == Vector3.ZERO, label + " finished motion cannot drift on later recovery advances")
	else:
		body.global_transform = original
		body.velocity = Vector3.ZERO
		_expect(Motion.plan(body, _motion(direction), [arena.floor_region]).has("error") and body.global_transform == original, "BOX keeps its actual measured shape and remains outside the capsule-only lunge contract")
	# The common source-coordinate envelope remains a hard limit. No recentering
	# or larger numerical tolerance may turn a path past512 into a supported one.
	if absf(original.origin.z) > 500.0:
		body.global_transform = original
		var outside: Dictionary = Sweep.sweep(body, original, -direction * DISTANCE * 2.0, [arena.floor_region])
		_expect(outside.has("error") and body.global_transform == original and body.velocity == Vector3.ZERO, "translated native coordinate envelope rejects an outward path beyond512 before mutation")
	await _dispose(arena)


func _wall_controls(kind: String) -> void:
	var start := Vector3(-2.663714647293091, WORKER_START.y if kind == "capsule" else 0.0002, -12.4)
	var arena: Dictionary = await _arena(kind, start, Vector3.ZERO)
	var body: CharacterBody3D = arena.source
	var wall: Dictionary = _static_box(arena.root, "Wall", Vector3(-0.8, 1, start.z), Vector3(0.2, 2, 20))
	await physics_frame
	var original: Transform3D = body.global_transform
	var sweep: Dictionary = Sweep.sweep(body, original, Vector3.RIGHT * DISTANCE, [arena.floor_region])
	_expect(not sweep.has("error") and sweep.get("collided", false) and sweep.get("collider_rid", RID()) == wall.body.get_rid() and body.global_transform == original, kind + " translated actual wall genuinely shortens a pure measured route")
	if not sweep.has("error"):
		var collision: KinematicCollision3D = null
		for step: Dictionary in sweep.steps:
			collision = body.move_and_collide(step.motion, false, Sweep.SAFE_MARGIN, false, 1)
			if collision != null:
				break
		_expect(collision != null and collision.get_collider_rid() == wall.body.get_rid() and body.global_position.distance_to(sweep.end) <= _native_position_bound(original.origin, sweep.end), kind + " real translated M&C contact matches its measured shortened opening")
	body.global_transform = original
	body.velocity = Vector3.ZERO
	var plan: Dictionary = Motion.plan(body, _motion(Vector3.RIGHT), [arena.floor_region]) if kind == "capsule" else {}
	var inserted: Dictionary = _static_box(arena.root, "AddedWall", Vector3(-1.8, 1, start.z), Vector3(0.2, 2, 20))
	await physics_frame
	var changed: Dictionary = Sweep.sweep(body, original, Vector3.RIGHT * DISTANCE, [arena.floor_region])
	_expect(not changed.has("error") and changed.get("collided", false) and changed.get("collider_rid", RID()) == inserted.body.get_rid() and changed.end.x < sweep.get("end", start).x - 0.4 and body.global_transform == original, kind + " newly inserted real wall invalidates the former translated endpoint without movement")
	if kind == "capsule" and not plan.has("error"):
		var changed_motion: Dictionary = Motion.advance(body, plan, DISTANCE / SPEED, [arena.floor_region])
		_expect(changed_motion.has("error") and body.global_transform == original and body.velocity == Vector3.ZERO, "changed-wall lunge rejects atomically before real source movement")
	inserted.body.queue_free()
	wall.body.queue_free()
	await physics_frame
	var description: Dictionary = Sweep.source_description(body)
	body.global_position.y = -float(description.foot_offset) - 0.005
	await physics_frame
	var embedded: Transform3D = body.global_transform
	var deep: Dictionary = Sweep.sweep(body, embedded, Vector3.RIGHT * DISTANCE, [arena.floor_region])
	_expect(deep.has("error") and body.global_transform == embedded and body.velocity == Vector3.ZERO, kind + " true translated floor embedding still rejects without raising or depenetrating the source")
	if kind == "capsule":
		_expect(Motion.plan(body, _motion(Vector3.RIGHT), [arena.floor_region]).has("error") and body.global_transform == embedded, "deep capsule embedding remains outside actual lunge planning")
	await _dispose(arena)


func _scheduler_transport() -> void:
	var arena: Dictionary = await _scheduled_arena()
	var scheduler = arena.scheduler
	var response: Dictionary = arena.actor.get_threat_response_state()
	response["world_revision"] = 1
	response["recognition_s"] = 0.1
	response["attack_input_margin_s"] = 0.02
	response["floor_regions"] = [arena.floor_region]
	response["escape_directions"] = [Vector3.FORWARD, Vector3.BACK]
	response["return_directions"] = [Vector3.FORWARD, Vector3.BACK, Vector3.RIGHT, Vector3.LEFT, Vector3(1, 0, 1).normalized(), Vector3(1, 0, -1).normalized(), Vector3(-1, 0, 1).normalized(), Vector3(-1, 0, -1).normalized()]
	var threat: Dictionary = World.threat(0.8, 0.5)
	threat.source_stationary = false
	threat["lunge"] = _motion(WORKER_DIRECTION)
	_expect(scheduler.begin_encounter("standard", "translated-real-lunge"), "actual translated scheduler fixture freezes its encounter profile")
	var requested: Dictionary = scheduler.request_lunge(arena.source, threat, response)
	_expect(requested.get("accepted", false), "real translated source obtains an ordinary moving reservation from actual hero response: " + String(requested.get("reason", "")))
	if not requested.get("accepted", false):
		await _dispose(arena)
		return
	var id: String = requested.reservation_id
	var active: float = requested.reservation.active_from_s
	await _until(scheduler, active + 0.1)
	paused = true
	await process_frame
	var bindings: Dictionary = _bindings(arena)
	var pair: Dictionary = _pair(arena)
	_expect(not pair.scheduler.is_empty() and pair.scheduler.reservations.size() == 1, "actual moving-active translated pair captures after the deferred paused barrier")
	if pair.scheduler.is_empty() or pair.scheduler.reservations.is_empty():
		print("Translated scheduler snapshot error: ", scheduler.last_snapshot_error)
		await _dispose(arena)
		return
	var adapter: Dictionary = pair.scheduler.reservations[0].adapter
	_expect(not adapter.collision_shortened and not adapter.actual_collided and not adapter.finished, "actual clear moving-active snapshot cannot manufacture shortening or early completion")
	var roundtrip: Dictionary = _json(pair)
	_expect(_same(pair, roundtrip) and scheduler.snapshot_error(roundtrip.scheduler, bindings).is_empty(), "real translated paused pair preserves every native scalar bit/type through ExactJson and validates its actual lane")
	var before: Dictionary = _pair(arena)
	await create_timer(0.06, true).timeout
	_expect(_same(before, _pair(arena)), "paused wall time changes no actual source/hero/scheduler clock or translated position")
	var ready_s: float = float(pair.scheduler.reservations[0].active_until_s) + 0.08
	# Remove old physics nodes before creating stable-path fresh recipients; no
	# duplicate live source or world-root instance can authenticate the restore.
	arena.root.free()
	await process_frame
	arena = await _scheduled_arena(false)
	scheduler = arena.scheduler
	bindings = _bindings(arena)
	var staged: Dictionary = bindings.duplicate(true)
	staged["owner_positions"] = {"stalker": Codec.read_vector3(roundtrip.source.position)}
	staged["owner_velocities"] = {"stalker": Codec.read_vector3(roundtrip.source.velocity)}
	var initial_source: Transform3D = arena.source.global_transform
	_expect(scheduler.snapshot_error(roundtrip.scheduler, staged).is_empty() and arena.source.global_transform == initial_source, "fresh staged translated pose prevalidates purely against actual retained capsule/floor registration")
	var callbacks: Array[String] = []
	scheduler.reservation_invalidated.connect(func(_id: String, reason: String) -> void: callbacks.append(reason))
	_expect(arena.actor.restore_state(roundtrip.hero), "fresh actual hero restores its own coherent resources/clocks before paired scheduler commit")
	arena.source.global_position = Codec.read_vector3(roundtrip.source.position)
	arena.source.velocity = Codec.read_vector3(roundtrip.source.velocity)
	_expect(scheduler.restore_state(roundtrip.scheduler, bindings), "fresh real source/scheduler bind the exact translated moving-active continuation: " + scheduler.last_snapshot_error)
	_expect(_same(roundtrip, _pair(arena)) and callbacks.is_empty(), "fresh translated aggregate continuation is bit-identical and silent without replaying motion")
	if not scheduler.last_snapshot_error.is_empty():
		await _dispose(arena)
		return
	paused = false
	await _until(scheduler, ready_s)
	paused = true
	await process_frame
	var final: Dictionary = _pair(arena)
	var live: Dictionary = scheduler.reservation_state(id)
	_expect(not live.is_empty() and live.state == "recovery" and callbacks.is_empty(), "fresh resumed scheduler reaches ordinary recovery without numeric-route invalidation")
	if not live.is_empty():
		_expect(live.adapter.finished and not live.adapter.collision_shortened and not live.adapter.actual_collided and arena.source.velocity == Vector3.ZERO, "real translated leased source finishes and stops without a fabricated contact")
		var endpoint: Vector3 = WORKER_START + WORKER_DIRECTION * DISTANCE
		_expect(arena.source.global_position.distance_to(endpoint) <= _native_position_bound(WORKER_START, endpoint) and live.opening_position == arena.source.global_position, "actual resumed endpoint and scheduler recovery opening agree within bounded native coordinate precision")
	_expect(not final.scheduler.is_empty() and scheduler.snapshot_error(final.scheduler, bindings).is_empty(), "real translated finished recovery snapshot remains coherent with actual stopped source")
	await _dispose(arena)


func _arena(kind: String, position: Vector3, floor_centre: Vector3) -> Dictionary:
	var world := Node3D.new()
	world.name = "TranslatedNativeWorld"
	root.add_child(world)
	var floor: Dictionary = _static_box(world, "Floor", floor_centre + Vector3(0, -0.5, 0), Vector3(14, 1, 108))
	var source := CharacterBody3D.new()
	source.name = "Source"
	source.collision_layer = 2
	source.collision_mask = 1
	source.safe_margin = 0.001
	source.floor_snap_length = 0.18
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	if kind == "capsule":
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.32
		capsule.height = 1.45
		collision.shape = capsule
		collision.position.y = 0.73
	else:
		var box := BoxShape3D.new()
		box.size = Vector3(0.75, 1.45, 0.65) # Actual existing AshEnemy BOX.
		collision.shape = box
		collision.position.y = 0.725
	source.add_child(collision)
	world.add_child(source)
	source.global_position = position
	await physics_frame
	await process_frame
	return {"root": world, "source": source, "floor_region": {"collision": floor.collision, "safe_rect": Rect2(Vector2(floor_centre.x - 7, floor_centre.z - 54), Vector2(14, 108))}}


func _scheduled_arena(settle: bool = true) -> Dictionary:
	var arena: Dictionary = await _arena("capsule", WORKER_START, Vector3.ZERO)
	arena.root.name = "TranslatedSchedulerWorld"
	var actor: CinderPlayer = PlayerScene.instantiate()
	actor.name = "Hero"
	arena.root.add_child(actor)
	actor.global_position = WORKER_START + Vector3(0.5, 0, 0)
	var scheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	arena.root.add_child(scheduler)
	arena["actor"] = actor
	arena["scheduler"] = scheduler
	if settle:
		paused = false
		for _index: int in range(8):
			await physics_frame
			await process_frame
	return arena


func _bindings(arena: Dictionary) -> Dictionary:
	return {"world_root": arena.root, "owners": {"stalker": arena.source}, "floors": {"main-floor": arena.floor_region}}


func _pair(arena: Dictionary) -> Dictionary:
	return {"scheduler": arena.scheduler.snapshot_state(_bindings(arena)), "source": {"position": Codec.vector3(arena.source.global_position), "velocity": Codec.vector3(arena.source.velocity)}, "hero": arena.actor.snapshot_state()}


func _motion(direction: Vector3) -> Dictionary:
	return {"direction": direction, "speed": SPEED, "distance": DISTANCE, "damage_radius": 0.42}


func _static_box(parent: Node3D, name: String, position: Vector3, size: Vector3) -> Dictionary:
	var body := StaticBody3D.new()
	body.name = name
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "Solid"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.global_position = position
	return {"body": body, "collision": collision}


func _native_position_bound(start: Vector3, finish: Vector3) -> float:
	# Independent bounded float32 coordinate resolution, not a clock/floor or
	# cumulative-step tolerance. Four native ULPs cover subtraction/projection.
	var resolution: float = 0.0
	for value: float in [start.x, start.y, start.z, finish.x, finish.y, finish.z]:
		var bytes := PackedByteArray()
		bytes.resize(4)
		bytes.encode_float(0, absf(value))
		var rounded: float = bytes.decode_float(0)
		bytes.encode_u32(0, bytes.decode_u32(0) + 1)
		resolution = maxf(resolution, bytes.decode_float(0) - rounded)
	return maxf(0.000002, resolution * 4.0)


func _until(scheduler, clock_s: float) -> void:
	for _index: int in range(180):
		if scheduler.get_clock() >= clock_s:
			return
		await physics_frame
		await process_frame
	_expect(false, "bounded actual scheduler clock reaches requested translated phase")


func _dispose(arena: Dictionary) -> void:
	paused = false
	if is_instance_valid(arena.get("root")):
		arena.root.queue_free()
	await process_frame


func _json(value: Dictionary) -> Dictionary:
	var result: Dictionary = ExactJson.parse(ExactJson.stringify(value))
	return result.value if result.get("accepted", false) and result.value is Dictionary else {}


func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = ExactJson.stringify(left)
	return not encoded.is_empty() and encoded == ExactJson.stringify(right)


func _ensure_uid() -> void:
	var path: String = "res://tests/translated_lunge_smoke.gd.uid"
	if not FileAccess.file_exists(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_line(ResourceUID.id_to_text(ResourceUID.create_id()))


func _finish() -> void:
	if _finished:
		return
	_finished = true
	var file: FileAccess = FileAccess.open(_output, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"engine": Engine.get_version_info(), "checks": _checks, "failures": _failures, "worker_start": Codec.vector3(WORKER_START), "worker_direction": Codec.vector3(WORKER_DIRECTION), "measurements": _measurements, "limits": "Native float32 translated motion only; no authored level/damage/focus/campaign acceptance"}, "\t", true, true))
	paused = false
	print("Translated lunge smoke: %d checks, %d failures; %s" % [_checks, _failures, _output])
	quit(0 if _failures == 0 else 1)


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
