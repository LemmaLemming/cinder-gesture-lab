extends SceneTree
## Real physics body measurements/execution, not a standalone fairness proof.

const World = preload("res://tests/fixtures/threat_world.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var arena: Dictionary = World.create(self)
	var source := CharacterBody3D.new()
	source.name = "Stalker"
	source.collision_layer = 2
	source.collision_mask = 1
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.27
	capsule.height = 1.10
	collision.shape = capsule
	collision.position.y = 0.555
	source.add_child(collision)
	arena["root"].add_child(source)
	source.position = Vector3(-3, 0, 0)
	arena["wall"].position.x = -0.5
	await physics_frame
	var spec := {"direction": Vector3.RIGHT, "speed": 8.0, "distance": 3.8, "damage_radius": 0.31}
	var plan: Dictionary = Motion.plan(source, spec, [arena["floor_region"]])
	_expect(not plan.has("error"), "actual source capsule/body collision produces a supported straight lunge plan")
	if not plan.has("error"):
		_expect(is_equal_approx(plan["source_radius"], 0.27) and is_equal_approx(plan["body_signature"]["height"], 1.1), "source dimensions are measured independently from the fixed shared hero capsule")
		_expect(source.position.is_equal_approx(Vector3(-3, 0, 0)), "test_move prediction leaves the real source unchanged")
		_expect(plan["collision_shortened"] and plan["planned_endpoint"].x < -0.8 and plan["planned_endpoint"].x > -1.0, "thin real wall shortens the committed endpoint by the actual source radius")
		var state: Dictionary = plan
		for step: int in range(1, 40):
			await physics_frame
			state = Motion.advance(source, state, float(step) / 60.0)
			if state.has("error") or state["finished"]:
				break
		if state.has("error"):
			print("Lunge diagnostic: error=%s actual=%s planned=%s velocity=%s" % [state["error"], source.global_position, plan["planned_endpoint"], source.velocity])
		_expect(not state.has("error") and state["finished"] and state["actual_collided"], "real move_and_collide executes the lunge and reports the shortening contact")
		_expect(source.global_position.distance_to(plan["planned_endpoint"]) <= Motion.ENDPOINT_TOLERANCE and source.velocity == Vector3.ZERO, "physical shortened landing agrees with committed recovery opening and stops deliberately")
		if not state.has("error"):
			var stopped: Vector3 = source.global_position
			state = Motion.advance(source, state, 2.0)
			_expect(not state.has("error") and source.global_position == stopped, "finished lunge cannot continue drifting through later active/recovery ticks")
	var too_thin: Dictionary = spec.duplicate()
	too_thin["damage_radius"] = 0.1
	source.position = Vector3(-3, 0, 0)
	_expect(Motion.plan(source, too_thin, [arena["floor_region"]]).has("error"), "reserved footprint cannot be narrower than the real physical source")
	source.velocity = Vector3.RIGHT
	_expect(Motion.plan(source, spec, [arena["floor_region"]]).has("error"), "live source approach momentum cannot masquerade as a stationary committed start")
	source.velocity = Vector3.ZERO
	source.axis_lock_linear_x = true
	_expect(Motion.plan(source, spec, [arena["floor_region"]]).has("error"), "source axis locks cannot make predicted motion differ from real execution")
	source.axis_lock_linear_x = false
	var tiny: Dictionary = spec.duplicate()
	tiny["distance"] = 0.000001
	_expect(Motion.plan(source, tiny, [arena["floor_region"]]).has("error"), "sub-epsilon lunge cannot reserve a motion that never completes")
	plan = Motion.plan(source, spec, [arena["floor_region"]])
	if not plan.has("error"):
		source.velocity = Vector3.BACK
		_expect(Motion.advance(source, plan, 0.1).has("error") and source.position == Vector3(-3, 0, 0), "external knockback velocity rejects before owned motion overwrites it")
		source.velocity = Vector3.ZERO
	source.position = Vector3(-3, -0.01, 0)
	_expect(Motion.plan(source, spec, [arena["floor_region"]]).has("error") and source.position == Vector3(-3, -0.01, 0), "floor depenetration rejects during non-mutating preflight before lifting the real source")
	source.position = Vector3(-3, 0, 0)
	plan = Motion.plan(source, spec, [arena["floor_region"]])
	if not plan.has("error"):
		arena["wall"].position.x = 7.0
		await physics_frame
		var escaped: Dictionary = Motion.advance(source, plan, 0.5)
		_expect(escaped.has("error") and source.position == Vector3(-3, 0, 0), "removed shortening wall rejects before the source can escape its previewed lane")
	arena["root"].queue_free()
	await process_frame
	print("Lunge motion smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
