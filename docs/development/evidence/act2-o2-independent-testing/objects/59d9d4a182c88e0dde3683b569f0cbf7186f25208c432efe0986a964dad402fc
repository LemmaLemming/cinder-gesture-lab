extends SceneTree
## Supported-proof regression fixtures, not human timing/campaign balance tests.

const DifficultyScript = preload("res://scripts/combat/difficulty.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const EquipmentScript = preload("res://scripts/equipment.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_profiles()
	_test_geometry()
	await _test_basic_and_pause()
	await _test_union_and_active()
	await _test_walls_and_holes()
	await _test_legal_slow_kit()
	await _test_cleanup_and_missing_proof()
	print("Threat scheduler smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_profiles() -> void:
	var difficulty = DifficultyScript.new()
	var raw: Dictionary = _raw_role()
	var preserved: Dictionary = raw.duplicate(true)
	var floors := {"windup_s": 0.6, "lock_s": 0.2, "recovery_s": 1.2}
	var assisted: Dictionary = difficulty.resolve_role(raw, "assisted", floors)
	var standard: Dictionary = difficulty.resolve_role(raw, "standard", floors)
	var challenge: Dictionary = difficulty.resolve_role(raw, "challenge", floors)
	_expect(_near(assisted["damage"], 7.0) and _near(assisted["windup_s"], 0.81) and _near(assisted["recovery_s"], 1.62), "Assisted applies documented damage/windup direction and a longer provisional recovery")
	_expect(standard["damage"] == challenge["damage"] and standard["windup_s"] == challenge["windup_s"] and standard["recovery_s"] == challenge["recovery_s"], "Challenge retains Standard damage and readable timing reference")
	_expect(raw == preserved and assisted["max_hp"] == raw["max_hp"] and assisted["move_speed"] == raw["move_speed"], "resolution preserves raw role data, health and approach speed")
	_expect(difficulty.resolve_role(assisted, "assisted", floors).is_empty() and not difficulty.last_error.is_empty(), "already-resolved role data is rejected instead of compounding multipliers")
	_expect(difficulty.resolve_role(raw, "assisted", floors) == assisted, "repeated raw resolution is deterministic and noncompounding")
	var raised: Dictionary = difficulty.resolve_role(raw, "standard", {"windup_s": 0.9, "lock_s": 0.25, "recovery_s": 1.4})
	_expect(_near(raised["windup_s"], 0.9) and _near(raised["lock_s"], 0.25) and _near(raised["recovery_s"], 1.4), "explicit role timing floors retain warning, lock and primary opening")
	_expect(difficulty.resolve_role(raw, "unknown", floors).is_empty() and difficulty.resolve_role(raw, "standard", {}).is_empty(), "unknown profiles and absent timing floors fail closed")
	var copied: Dictionary = difficulty.profile("assisted")
	copied["raw_damage_multiplier"] = 99
	_expect(_near(difficulty.profile("assisted")["raw_damage_multiplier"], 0.7), "returned profile cannot mutate canonical resolver state")
	var stationary: Dictionary = raw.duplicate(true)
	stationary["move_speed"] = 0.0
	for profile_id: String in ["assisted", "standard", "challenge"]:
		var resolved: Dictionary = difficulty.resolve_role(stationary, profile_id, floors)
		_expect(not resolved.is_empty() and resolved["move_speed"] == 0.0 and resolved["raw_role"]["move_speed"] == 0.0, "stationary source retains genuine zero speed across " + profile_id)
	stationary["move_speed"] = -0.1
	_expect(difficulty.resolve_role(stationary, "standard", floors).is_empty(), "negative approach speed cannot masquerade as a stationary role")


func _test_geometry() -> void:
	var origin := Vector3.ZERO
	var shape: Dictionary = Geometry.cone(origin, Vector3.RIGHT, 2.0, 0.55)
	_expect(Geometry.segment_hits(shape, Vector3(1, 0, 0), Vector3(1.5, 0, 0), 0.0), "logical committed cone catches an active forward path")
	_expect(not Geometry.segment_hits(shape, Vector3(-1, 0, 0), Vector3(-2, 0, 0), 0.0), "logical cone does not turn its rear into a decorative full circle")
	_expect(Geometry.segment_hits(Geometry.circle(origin, 0.5), Vector3(-3, 0, 0), Vector3(3, 0, 0), 0.0), "continuous geometry catches a narrow circle between distant endpoints")
	_expect(Geometry.segment_hits(Geometry.lane(Vector3(-2, 0, 0), Vector3(2, 0, 0), 0.2), Vector3(0, 0, -2), Vector3(0, 0, 2), 0.1), "committed lane reserves its swept capsule and catches crossing travel")
	var path: Array[Dictionary] = [{"from": Vector3(-3, 0, 0), "to": Vector3(3, 0, 0), "start_s": 0.0, "end_s": 1.0}]
	_expect(not Geometry.timed_path_hits(Geometry.circle(origin, 0.5), path, 0.9, 1.0, 0.0) and Geometry.timed_path_hits(Geometry.circle(origin, 0.5), path, 0.4, 0.6, 0.0), "continuous timed union checks only the actual active overlap, including travel interior")
	_expect(not Geometry.error({"kind": "decorative_mesh"}).is_empty(), "unsupported visual shapes cannot act as authoritative geometry")
	_expect(Geometry.segment_hits(Geometry.circle(origin, 0.5), origin, origin, NAN), "nonfinite response padding fails closed instead of proving a safe route")


func _test_basic_and_pause() -> void:
	var arena: Dictionary = _arena()
	await physics_frame
	var scheduler = arena["scheduler"]
	_expect(scheduler.begin_encounter("standard", "basic"), "fresh encounter selects a known fixed profile")
	var result: Dictionary = scheduler.request_attack(arena["source_a"], _threat(), _response(arena))
	_expect(result.get("accepted", false), "ordinary neutral kit receives a collision/floor-safe escape and primary opening")
	if result.get("accepted", false):
		_expect(not result["proof"]["uses_blast"] and not result["proof"]["uses_invulnerability"] and result["proof"]["path"].size() >= 4, "accepted proof includes waiting, actual dash travel and recovery without ammo/immunity")
	_expect(not scheduler.begin_encounter("assisted", "mid-encounter") and scheduler.encounter_profile()["id"] == "standard", "difficulty changes cannot retune a live encounter")
	var copied: Dictionary = scheduler.encounter_profile()
	copied["reserved_threat_budget"] = 99
	_expect(scheduler.encounter_profile()["reserved_threat_budget"] == 2, "encounter profile view is defensive")
	var before: float = scheduler.get_clock()
	paused = true
	await create_timer(0.08, true).timeout
	_expect(_near(scheduler.get_clock(), before) and scheduler.reservations().size() == 1, "pause freezes scheduler deadlines and reservation lifetime")
	_expect(not scheduler.request_attack(arena["source_b"], _threat(), _response(arena)).get("accepted", false), "paused UI calls cannot allocate new gameplay threats")
	paused = false
	await physics_frame
	await physics_frame
	_expect(scheduler.get_clock() > before, "scheduler clock resumes through physics after unpause")
	var boundary_allocations: Array[bool] = []
	scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void:
		boundary_allocations.append(scheduler.request_attack(arena["source_b"], _threat(), _response(arena)).get("accepted", false))
		boundary_allocations.append(scheduler.begin_encounter("assisted", "reentrant")))
	scheduler.end_encounter()
	_expect(boundary_allocations == [false, false] and scheduler.reservations().is_empty(), "cleanup callbacks cannot allocate a reservation or replace the encounter mid-boundary")
	_expect(scheduler.reservations().is_empty() and scheduler.begin_encounter("assisted", "next"), "fresh encounter boundary releases old exchanges and accepts the selected next profile")
	arena["root"].queue_free()
	await process_frame


func _test_union_and_active() -> void:
	var arena: Dictionary = _arena()
	await physics_frame
	var scheduler = arena["scheduler"]
	scheduler.begin_encounter("standard", "combined")
	var a: Dictionary = _threat()
	a["geometry"] = Geometry.circle(Vector3(-2.7, 0.1, 0), 1.4)
	var b: Dictionary = _threat(0.85)
	b["geometry"] = Geometry.circle(Vector3(2.7, 0.1, 0), 1.4)
	_expect(scheduler.request_attack(arena["source_a"], a, _response(arena)).get("accepted", false), "first side threat leaves the opposite escape and return opening")
	_expect(not scheduler.request_attack(arena["source_b"], b, _response(arena)).get("accepted", false), "two individually escapable footprints with impossible combined landing pressure are rejected")
	scheduler.end_encounter()
	scheduler.begin_encounter("standard", "second-alone")
	_expect(scheduler.request_attack(arena["source_b"], b, _response(arena)).get("accepted", false), "rejected combined threat has a valid solo witness, establishing a union-specific failure")
	scheduler.end_encounter()
	scheduler.begin_encounter("standard", "stagger")
	_expect(scheduler.request_attack(arena["source_a"], _threat(), _response(arena)).get("accepted", false), "stagger fixture reserves its first committed exchange")
	var unstaggered: Dictionary = scheduler.request_attack(arena["source_b"], _threat(), _response(arena))
	_expect(not unstaggered.get("accepted", false) and String(unstaggered["reason"]).contains("stagger"), "geometry cannot bypass the visible activation stagger")
	scheduler.end_encounter()
	scheduler.begin_encounter("assisted", "active-budget")
	var far: Dictionary = _threat(0.6, "assisted", 0.4)
	far["geometry"] = Geometry.circle(Vector3(8, 0.1, 0), 0.5)
	_expect(scheduler.request_attack(arena["source_a"], far, _response(arena)).get("accepted", false), "Assisted fixture reserves one finite far committed threat")
	# Assisted windup is 0.81 seconds; hold inside its 0.4-second active window.
	await create_timer(0.9).timeout
	_expect(scheduler.reservations().size() == 1 and scheduler.reservations()[0]["state"] == "active", "reservation persists after preparation becomes active")
	var active_budget: Dictionary = scheduler.request_attack(arena["source_b"], _threat(0.6, "assisted"), _response(arena))
	_expect(not active_budget.get("accepted", false) and String(active_budget["reason"]).contains("budget"), "an active threat continues to occupy Assisted's budget")
	scheduler.end_encounter()
	scheduler.begin_encounter("standard", "active-union")
	var active_near: Dictionary = _threat(0.6, "standard", 0.4)
	_expect(scheduler.request_attack(arena["source_a"], active_near, _response(arena)).get("accepted", false), "active union fixture reserves its first threat")
	await create_timer(0.7).timeout
	var during_active: Dictionary = scheduler.request_attack(arena["source_b"], _threat(0.8), _response(arena))
	_expect(not during_active.get("accepted", false) and String(during_active["reason"]).contains("union"), "existing active damage during recognition/wait is included even below the two-threat budget")
	scheduler.end_encounter()
	scheduler.begin_encounter("standard", "finite-release")
	var invalidations: Array[String] = []
	scheduler.reservation_invalidated.connect(func(_id: String, reason: String) -> void: invalidations.append(reason))
	_expect(scheduler.request_attack(arena["source_a"], _threat(), _response(arena)).get("accepted", false), "finite release fixture reserves a complete warning, active and recovery exchange")
	await create_timer(2.0).timeout
	_expect(scheduler.reservations().is_empty() and invalidations.is_empty(), "normal finite recovery expiry releases geometry without a false cancellation event")
	var still_cooling: Dictionary = scheduler.request_attack(arena["source_a"], _threat(), _response(arena))
	_expect(not still_cooling.get("accepted", false) and String(still_cooling["reason"]).contains("cooldown"), "released recovery geometry does not erase the later scheduled source cooldown")
	await create_timer(0.3).timeout
	_expect(scheduler.request_attack(arena["source_a"], _threat(), _response(arena)).get("accepted", false), "normal expiry also permits the same source after its scheduled cooldown")
	arena["root"].queue_free()
	await process_frame


func _test_walls_and_holes() -> void:
	var arena: Dictionary = _arena()
	_wall(arena["root"], Vector3(1.1, 0.8, 0), Vector3(0.15, 1.6, 8))
	await physics_frame
	var scheduler = arena["scheduler"]
	scheduler.begin_encounter("standard", "wall")
	var response: Dictionary = _response(arena)
	response["escape_directions"] = [Vector3.RIGHT]
	response["return_directions"] = [Vector3.LEFT]
	_expect(not scheduler.request_attack(arena["source_a"], _threat(), response).get("accepted", false), "actual capsule sweep rejects an escape crossing a thin wall")
	arena["root"].queue_free()
	await process_frame
	arena = _arena(false)
	var floors: Array = [_floor(arena["root"], Rect2(-5, -5, 4.7, 10)), _floor(arena["root"], Rect2(0.3, -5, 4.7, 10))]
	arena["floors"] = floors
	(arena["actor"] as CharacterBody3D).position.x = -2.0
	await physics_frame
	scheduler = arena["scheduler"]
	scheduler.begin_encounter("standard", "gap")
	response = _response(arena)
	response["escape_directions"] = [Vector3.RIGHT]
	response["return_directions"] = [Vector3.LEFT]
	var threat: Dictionary = _threat()
	threat["geometry"] = Geometry.circle(Vector3(-2, 0.1, 0), 0.8)
	threat["opening_position"] = Vector3(-2, 0.1, 0)
	_expect(not scheduler.request_attack(arena["source_a"], threat, response).get("accepted", false), "continuous floor proof rejects a hole between supported endpoints")
	response["floor_regions"] = [{"collision": floors[0]["collision"], "safe_rect": Rect2(-5, -5, 10, 10)}]
	var dishonest_floor: Dictionary = scheduler.request_attack(arena["source_a"], threat, response)
	_expect(not dishonest_floor.get("accepted", false) and String(dishonest_floor["reason"]).contains("rectangle"), "an authored rectangle cannot claim support beyond its real solid floor collider")
	response["floor_regions"] = floors
	((floors[1]["collision"] as CollisionShape3D).get_parent() as StaticBody3D).position.y += 0.05
	var stepped: Dictionary = scheduler.request_attack(arena["source_a"], threat, response)
	_expect(not stepped.get("accepted", false) and String(stepped["reason"]).contains("height"), "excluded support boxes cannot conceal a step that changes the constant-height dash model")
	arena["root"].queue_free()
	await process_frame


func _test_legal_slow_kit() -> void:
	var arena: Dictionary = _arena()
	await physics_frame
	var scheduler = arena["scheduler"]
	var gear = EquipmentScript.new()
	gear.equip("CLOTH-J1")
	gear.equip("CLOTH-P2")
	gear.equip("CLOTH-S2")
	gear.equip("WEAPON-03")
	_expect(gear.acceptance_errors().is_empty(), "slow-kit fixture uses permitted canonical equipment rather than invented stat extremes")
	var slow: Dictionary = gear.resolved_stats()
	var fast_response: Dictionary = _response(arena)
	fast_response["dash_cooldown_left_s"] = 0.34
	var slow_response: Dictionary = _response(arena, slow)
	slow_response["dash_cooldown_left_s"] = 0.34
	var tight: Dictionary = _threat(0.54)
	tight["geometry"] = Geometry.circle(Vector3(0, 0.1, 0), 1.1)
	scheduler.begin_encounter("standard", "neutral-tight")
	_expect(scheduler.request_attack(arena["source_a"], tight, fast_response).get("accepted", false), "neutral kit clears the bounded timed footprint after remaining cooldown")
	scheduler.end_encounter()
	scheduler.begin_encounter("standard", "slow-tight")
	_expect(not scheduler.request_attack(arena["source_a"], tight, slow_response).get("accepted", false), "same short windup rejects slower legal travel that remains in danger at activation")
	scheduler.end_encounter()
	scheduler.begin_encounter("standard", "slow-readable")
	var readable: Dictionary = _threat(0.9)
	readable["geometry"] = tight["geometry"]
	var accepted: Dictionary = scheduler.request_attack(arena["source_a"], readable, slow_response)
	_expect(accepted.get("accepted", false), "readable windup and recovery support slow legal dash, shortest selected reach and primary cadence without blast")
	if accepted.get("accepted", false):
		var escape: Dictionary = accepted["proof"]["path"][1]
		_expect(_near(float(escape["end_s"]) - float(escape["start_s"]), slow["dash_duration"]) and _near((escape["to"] as Vector3).distance_to(escape["from"]), slow["dash_distance"]), "proof uses resolved full travel/duration instead of an ideal instant response")
	scheduler.end_encounter()
	scheduler.begin_encounter("standard", "recovery-too-short")
	var short_opening: Dictionary = _threat(0.9, "standard", 0.1, 0.1)
	_expect(not scheduler.request_attack(arena["source_a"], short_opening, slow_response).get("accepted", false), "escape alone cannot accept a recovery with no ordinary-primary opening")
	scheduler.end_encounter()
	scheduler.begin_encounter("standard", "opening-out-of-reach")
	var unreachable: Dictionary = _threat(0.9)
	unreachable["opening_position"] = Vector3(0, 0.1, 6)
	_expect(not scheduler.request_attack(arena["source_a"], unreachable, slow_response).get("accepted", false), "safe landing without a reachable shortest-range primary target is rejected")
	arena["root"].queue_free()
	await process_frame


func _test_cleanup_and_missing_proof() -> void:
	var arena: Dictionary = _arena()
	await physics_frame
	var scheduler = arena["scheduler"]
	scheduler.begin_encounter("standard", "cleanup")
	var context: Dictionary = _response(arena)
	var missing: Dictionary = context.duplicate()
	missing.erase("commitment_remaining_s")
	_expect(not scheduler.request_attack(arena["source_a"], _threat(), missing).get("accepted", false), "missing current commitment cannot fall back to an ideal actor")
	missing = context.duplicate()
	missing.erase("floor_regions")
	_expect(not scheduler.request_attack(arena["source_a"], _threat(), missing).get("accepted", false), "missing authored floor proof fails closed")
	(arena["actor"] as CharacterBody3D).velocity = Vector3.RIGHT
	_expect(not scheduler.request_attack(arena["source_a"], _threat(), context).get("accepted", false), "current forced or voluntary travel cannot be treated as a stationary response origin")
	(arena["actor"] as CharacterBody3D).velocity = Vector3.ZERO
	var overflow: Dictionary = _threat()
	overflow["role"]["windup_s"] = 1.0e308
	overflow["role"]["active_s"] = 1.0e308
	var overflow_result: Dictionary = scheduler.request_attack(arena["source_a"], overflow, context)
	_expect(not overflow_result.get("accepted", false) and String(overflow_result["reason"]).contains("finite"), "finite individual timing values cannot overflow into an unbounded committed reservation")
	var moving: Dictionary = _threat()
	moving["opening_stationary"] = false
	_expect(not scheduler.request_attack(arena["source_a"], moving, context).get("accepted", false), "moving recovery target requires another supported adapter rather than an invented opening")
	var accepted: Dictionary = scheduler.request_attack(arena["source_a"], _threat(), context)
	_expect(accepted.get("accepted", false), "cleanup fixture begins with a valid committed exchange")
	if accepted.get("accepted", false):
		var copied: Array[Dictionary] = scheduler.reservations()
		copied[0]["geometry"]["radius"] = 999
		_expect(_near(scheduler.reservations()[0]["geometry"]["radius"], 0.8), "public reservation geometry cannot mutate the committed union")
		_expect(scheduler.cancel(accepted["reservation_id"], "stagger") and scheduler.reservations().is_empty() and not scheduler.cancel(accepted["reservation_id"]), "cancellation releases geometry once and leaves no stale budget")
	_expect(scheduler.request_attack(arena["source_b"], _threat(), context).get("accepted", false), "another source can use the released threat slot")
	arena["source_b"].queue_free()
	await process_frame
	_expect(scheduler.reservations().is_empty(), "queued/deleted source clears its reservation and cooldown ownership")
	scheduler.cancel_owner(arena["source_a"])
	var accepted_again: Dictionary = scheduler.request_attack(arena["source_a"], _threat(), context)
	_expect(accepted_again.get("accepted", false), "explicit death/cancel-owner cleanup removes owner cooldown as well as reservations")
	var invalidations: Array[String] = []
	scheduler.reservation_invalidated.connect(func(_id: String, reason: String) -> void: invalidations.append(reason))
	(arena["source_a"] as Node3D).position.x += 0.1
	_expect(scheduler.reservations().is_empty() and invalidations.has("stationary_source_moved"), "unplanned source motion invalidates the stationary exchange for owner cancellation")
	scheduler.cancel_owner(arena["source_a"])
	(arena["source_a"] as Node3D).position.x -= 0.1
	_expect(scheduler.request_attack(arena["source_a"], _threat(), context).get("accepted", false), "floor-change fixture reserves a valid exchange")
	var collision: CollisionShape3D = arena["floors"][0]["collision"]
	(collision.shape as BoxShape3D).size.x -= 1.0
	_expect(scheduler.reservations().is_empty() and invalidations.has("floor_contract_changed"), "a changed support collider invalidates the proof and signals cancellation")
	scheduler.cancel_owner(arena["source_a"])
	scheduler.invalidate_world(2)
	var stale: Dictionary = scheduler.request_attack(arena["source_a"], _threat(), context)
	_expect(not stale.get("accepted", false) and String(stale["reason"]).contains("revision"), "stale collision revision itself prevents allocation after a world change")
	arena["root"].queue_free()
	await process_frame


func _raw_role(windup: float = 0.6, active: float = 0.1, recovery: float = 1.2) -> Dictionary:
	return {"raw_damage": 10.0, "windup_s": windup, "lock_s": 0.2, "active_s": active, "recovery_s": recovery, "attack_interval_s": 1.6, "max_hp": 32.0, "move_speed": 2.6}


func _threat(windup: float = 0.6, profile_id: String = "standard", active: float = 0.1, recovery: float = 1.2) -> Dictionary:
	var difficulty = DifficultyScript.new()
	var role: Dictionary = difficulty.resolve_role(_raw_role(windup, active, recovery), profile_id, {"windup_s": windup, "lock_s": 0.2, "recovery_s": recovery})
	return {"role": role, "geometry": Geometry.circle(Vector3(0, 0.1, 0), 0.8), "source_stationary": true, "opening_stationary": true, "opening_position": Vector3(0, 0.1, 0), "cooldown_remaining_s": 0.0}


func _response(arena: Dictionary, supplied_stats: Dictionary = {}) -> Dictionary:
	var stats: Dictionary = supplied_stats if not supplied_stats.is_empty() else EquipmentScript.new().resolved_stats()
	return {"actor": arena["actor"], "stats": stats, "stable": true, "world_revision": 1, "commitment_remaining_s": 0.0, "dash_cooldown_left_s": 0.0, "primary_cooldown_left_s": 0.0, "recognition_s": 0.1, "primary_commitment_s": float(stats["primary_cooldown"]) * (0.13 / 0.3), "attack_input_margin_s": 0.02, "escape_directions": [Vector3.LEFT, Vector3.RIGHT], "return_directions": [Vector3.LEFT, Vector3.RIGHT], "floor_regions": arena["floors"]}


func _arena(with_floor: bool = true) -> Dictionary:
	var world := Node3D.new()
	root.add_child(world)
	var actor := CharacterBody3D.new()
	actor.collision_layer = 4
	actor.collision_mask = 1
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.45
	collision.shape = capsule
	collision.position.y = 0.73
	actor.add_child(collision)
	world.add_child(actor)
	actor.position.y = 0.0
	var scheduler = SchedulerScript.new()
	world.add_child(scheduler)
	var source_a := Node3D.new()
	var source_b := Node3D.new()
	world.add_child(source_a)
	world.add_child(source_b)
	source_a.position.y = 0.1
	source_b.position.y = 0.1
	var floors: Array = [_floor(world, Rect2(-10, -10, 20, 20))] if with_floor else []
	return {"root": world, "actor": actor, "scheduler": scheduler, "source_a": source_a, "source_b": source_b, "floors": floors}


func _floor(parent: Node3D, rect: Rect2) -> Dictionary:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(rect.size.x, 1, rect.size.y)
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.position = Vector3(rect.get_center().x, -0.5, rect.get_center().y)
	return {"collision": collision, "safe_rect": rect}


func _wall(parent: Node3D, position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.position = position


func _near(actual: Variant, expected: Variant) -> bool:
	return absf(float(actual) - float(expected)) < 0.0001


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
