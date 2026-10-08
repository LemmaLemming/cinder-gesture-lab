class_name CinderThreatScheduler
extends Node3D
## Conservative supported-response witness, not a campaign fairness certificate.
## Root supplies exact live commitment/cooldown data and authored candidate swipes.
## We prove unobstructed full-distance dashes on immutable, unrotated box floors,
## then a stationary ordinary-primary opening. No blast, invulnerability tanking,
## collision-shortened prediction, dynamic floor, tracking or moving recovery is
## assumed. Unsupported inputs reject. Candidate enumeration can false-reject.
## Logical threat intersection is continuous in space/time; floor continuity is
## established analytically against actual solid floor boxes, not ray samples.
## Capsule casts still use the engine's numerical physics tolerances. Owners MUST
## cancel their attack on reservation_invalidated; world changes MUST invalidate
## the encounter before altering collision. Future navigation/replay adapters must
## supply their own proof rather than opt out of these checks.

signal reservation_invalidated(reservation_id: String, reason: String)

const DifficultyScript = preload("res://scripts/combat/difficulty.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const API_REVISION: String = "threat-scheduler-1"
const CAPSULE_RADIUS: float = 0.32
const CAPSULE_HEIGHT: float = 1.45
const CAPSULE_CENTER_Y: float = 0.73
const SKIN: float = 0.01
const FEET_TOLERANCE: float = 0.015
const EPSILON: float = 0.00001
const TIME_MARGIN: float = 0.001

var last_error: String = ""
var _difficulty = DifficultyScript.new()
var _profile: Dictionary = {}
var _encounter_id: String = ""
var _world_revision: int = 0
var _clock: float = 0.0
var _serial: int = 0
var _reservations: Dictionary = {}
var _cooldowns: Dictionary = {}
var _boundary_busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func begin_encounter(profile_id: String, encounter_id: String = "encounter", world_revision: int = 1) -> bool:
	last_error = ""
	if _boundary_busy or not _encounter_id.is_empty():
		last_error = "End the current encounter before applying another profile"
		return false
	var selected: Dictionary = _difficulty.profile(profile_id)
	if selected.is_empty() or encounter_id.is_empty() or world_revision < 1:
		last_error = "Known profile, stable encounter ID and positive world revision required"
		return false
	_profile = selected
	_encounter_id = encounter_id
	_world_revision = world_revision
	_clock = 0.0
	_reservations.clear()
	_cooldowns.clear()
	return true


func end_encounter(reason: String = "encounter_end") -> void:
	if _boundary_busy:
		return
	_boundary_busy = true
	for reservation_id: String in _reservations.keys():
		cancel(reservation_id, reason)
	_cooldowns.clear()
	_profile.clear()
	_encounter_id = ""
	_boundary_busy = false


func encounter_profile() -> Dictionary:
	return _profile.duplicate(true)


func get_clock() -> float:
	return _clock


func request_attack(owner: Node3D, threat: Dictionary, response: Dictionary) -> Dictionary:
	_prune()
	last_error = _request_error(owner, threat, response)
	if not last_error.is_empty():
		return {"accepted": false, "reason": last_error}
	var role: Dictionary = threat["role"]
	var active_from: float = _clock + float(role["windup_s"])
	var active_until: float = active_from + float(role["active_s"])
	var recovery_until: float = active_until + float(role["recovery_s"])
	if not is_finite(recovery_until) or not is_finite(active_from + float(role["attack_interval_s"])):
		last_error = "Committed deadlines must remain finite"
		return {"accepted": false, "reason": last_error}
	var budget: int = 0
	for existing: Dictionary in _reservations.values():
		if float(existing["active_until_s"]) >= _clock:
			budget += 1
			if absf(float(existing["active_from_s"]) - active_from) < float(_profile["commit_stagger_s"]) - EPSILON:
				last_error = "Committed activations require a visible stagger"
				return {"accepted": false, "reason": last_error}
	if budget >= int(_profile["reserved_threat_budget"]):
		last_error = "Preparing and active threat budget occupied"
		return {"accepted": false, "reason": last_error}
	var candidate: Dictionary = {
		"geometry": (threat["geometry"] as Dictionary).duplicate(true),
		"active_from_s": active_from, "active_until_s": active_until,
		"recovery_until_s": recovery_until,
		"opening_position": threat["opening_position"],
	}
	var proof: Dictionary = _prove(candidate, response)
	if not proof.get("accepted", false):
		last_error = proof["reason"]
		return proof
	_serial += 1
	var reservation_id: String = "threat-%d" % _serial
	candidate["id"] = reservation_id
	candidate["source_instance_id"] = owner.get_instance_id()
	candidate["source_position"] = owner.global_position
	candidate["start_s"] = _clock
	candidate["lock_from_s"] = active_from - float(role["lock_s"])
	candidate["cooldown_until_s"] = active_from + float(role["attack_interval_s"])
	candidate["profile_id"] = _profile["id"]
	candidate["world_revision"] = _world_revision
	candidate["_owner"] = weakref(owner)
	candidate["_floor_guards"] = _floor_guards(response["floor_regions"])
	_reservations[reservation_id] = candidate
	_cooldowns[owner.get_instance_id()] = {"owner": weakref(owner), "ready_s": candidate["cooldown_until_s"]}
	return {"accepted": true, "reservation_id": reservation_id, "proof": proof, "profile_id": _profile["id"]}


func cancel(reservation_id: String, reason: String = "cancelled") -> bool:
	if not _reservations.has(reservation_id):
		return false
	_reservations.erase(reservation_id)
	# Cancellation releases geometry/budget; cooldown remains conservative until
	# the scheduled role interval expires. Death/removal cancels owner cooldown too.
	reservation_invalidated.emit(reservation_id, reason)
	return true


func cancel_owner(owner: Node3D, reason: String = "source_defeated") -> void:
	if _boundary_busy or not is_instance_valid(owner):
		return
	_boundary_busy = true
	var instance_id: int = owner.get_instance_id()
	for reservation_id: String in _reservations.keys():
		if not _reservations.has(reservation_id):
			continue
		if int(_reservations[reservation_id]["source_instance_id"]) == instance_id:
			cancel(reservation_id, reason)
	_cooldowns.erase(instance_id)
	_boundary_busy = false


func invalidate_world(new_revision: int) -> void:
	if _boundary_busy:
		return
	if new_revision <= _world_revision:
		last_error = "Collision world revision must increase"
		return
	_boundary_busy = true
	for reservation_id: String in _reservations.keys():
		cancel(reservation_id, "collision_world_changed")
	_world_revision = new_revision
	_boundary_busy = false


func reservations() -> Array[Dictionary]:
	_prune()
	var result: Array[Dictionary] = []
	for record: Dictionary in _reservations.values():
		var copy: Dictionary = record.duplicate(true)
		copy.erase("_owner")
		copy.erase("_floor_guards")
		copy["state"] = "warning" if _clock < float(record["lock_from_s"]) else ("lock" if _clock < float(record["active_from_s"]) else ("active" if _clock <= float(record["active_until_s"]) else "recovery"))
		result.append(copy)
	return result


func _physics_process(delta: float) -> void:
	if _encounter_id.is_empty():
		return
	_clock += delta
	_prune()


func _prune() -> void:
	for reservation_id: String in _reservations.keys():
		if not _reservations.has(reservation_id):
			continue
		var record: Dictionary = _reservations[reservation_id]
		var owner: Node3D = (record["_owner"] as WeakRef).get_ref() as Node3D
		if not is_instance_valid(owner) or owner.is_queued_for_deletion() or not owner.is_inside_tree():
			cancel(reservation_id, "source_removed")
		elif not owner.global_position.is_equal_approx(record["source_position"]):
			cancel(reservation_id, "stationary_source_moved")
		elif not _guards_valid(record["_floor_guards"]):
			cancel(reservation_id, "floor_contract_changed")
		elif _clock > float(record["recovery_until_s"]):
			# Normal expiry is release, not a cancellation notification.
			_reservations.erase(reservation_id)
	for instance_id: int in _cooldowns.keys():
		var entry: Dictionary = _cooldowns[instance_id]
		var owner: Node3D = (entry["owner"] as WeakRef).get_ref() as Node3D
		if not is_instance_valid(owner) or owner.is_queued_for_deletion() or not owner.is_inside_tree() or _clock >= float(entry["ready_s"]):
			_cooldowns.erase(instance_id)


func _request_error(owner: Node3D, threat: Dictionary, response: Dictionary) -> String:
	if _boundary_busy or _encounter_id.is_empty() or not is_inside_tree() or get_tree().paused:
		return "An active, unpaused encounter is required"
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion() or owner.get_world_3d() != get_world_3d() or not Geometry.finite_vector(owner.global_position):
		return "Live source in the scheduler's world required"
	if _cooldowns.has(owner.get_instance_id()):
		return "Source attack cooldown is still occupied"
	for existing: Dictionary in _reservations.values():
		if int(existing["source_instance_id"]) == owner.get_instance_id():
			return "Source already owns a committed exchange"
	if response.get("world_revision") != _world_revision or not threat.get("role") is Dictionary:
		return "World revision and a resolved role are required"
	var role: Dictionary = threat["role"]
	if role.get("difficulty_schema") != 1 or role.get("difficulty_profile") != _profile["id"]:
		return "Role must be resolved for this fixed encounter profile"
	for key: String in ["windup_s", "lock_s", "active_s", "recovery_s", "attack_interval_s"]:
		if not Geometry.finite_number(role.get(key)) or float(role[key]) <= 0.0:
			return "Finite role timing required: " + key
	if float(role["lock_s"]) >= float(role["windup_s"]):
		return "Locked phase must follow a readable warning"
	if not threat.get("geometry") is Dictionary or not Geometry.error(threat["geometry"]).is_empty():
		return "Authoritative supported threat geometry required"
	if threat.get("source_stationary") != true or threat.get("opening_stationary") != true or not Geometry.finite_vector(threat.get("opening_position")):
		return "Stationary committed source and reachable recovery target required"
	if not Geometry.finite_number(threat.get("cooldown_remaining_s")) or float(threat["cooldown_remaining_s"]) > EPSILON or float(threat["cooldown_remaining_s"]) < 0.0:
		return "Source must be ready according to its live cooldown"
	var actor: CharacterBody3D = response.get("actor") as CharacterBody3D
	if not is_instance_valid(actor) or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.get_world_3d() != get_world_3d() or response.get("stable") != true or not Geometry.finite_vector(actor.global_position) or not Geometry.finite_vector(actor.velocity) or Vector2(actor.velocity.x, actor.velocity.z).length() > EPSILON or absf(actor.velocity.y) > EPSILON:
		return "Stable live shared actor required; reject current dash/knockback/fall"
	var collision: CollisionShape3D = actor.get_node_or_null("BodyCollision") as CollisionShape3D
	if collision == null or collision.disabled or not collision.shape is CapsuleShape3D or not actor.global_basis.is_equal_approx(Basis.IDENTITY) or not collision.transform.basis.is_equal_approx(Basis.IDENTITY) or not collision.position.is_equal_approx(Vector3(0, CAPSULE_CENTER_Y, 0)):
		return "Shared fixed capsule/feet convention required"
	var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D
	if not is_equal_approx(capsule.radius, CAPSULE_RADIUS) or not is_equal_approx(capsule.height, CAPSULE_HEIGHT):
		return "Capsule dimensions differ from the shared actor"
	if not response.get("stats") is Dictionary:
		return "Resolved ordinary equipment stats required"
	var stats: Dictionary = response["stats"]
	for key: String in ["dash_speed", "dash_distance", "dash_duration", "dash_cooldown", "primary_range", "primary_cooldown"]:
		if not Geometry.finite_number(stats.get(key)) or float(stats[key]) <= 0.0:
			return "Missing resolved response stat: " + key
	if not is_equal_approx(float(stats["dash_duration"]), float(stats["dash_distance"]) / float(stats["dash_speed"])):
		return "Dash travel and duration must use the same action snapshot"
	for key: String in ["dash_cooldown_left_s", "primary_cooldown_left_s", "commitment_remaining_s", "recognition_s", "primary_commitment_s", "attack_input_margin_s"]:
		if not Geometry.finite_number(response.get(key)) or float(response[key]) < 0.0:
			return "Explicit live response timing required: " + key
	if float(response["recognition_s"]) <= 0.0 or float(response["primary_commitment_s"]) <= 0.0 or float(response["primary_commitment_s"]) > float(stats["primary_cooldown"]) or float(response["dash_cooldown_left_s"]) > float(stats["dash_cooldown"]) + EPSILON:
		return "Response recognition, commitment and remaining cooldown are inconsistent"
	for key: String in ["escape_directions", "return_directions"]:
		if not response.get(key) is Array or (response[key] as Array).size() > 16:
			return "Finite authored response candidates required: " + key
		for direction: Variant in response[key]:
			if not Geometry.finite_vector(direction) or absf(direction.y) > EPSILON or absf(direction.length() - 1.0) > EPSILON:
				return "Response candidates must be normalized ground swipes"
	if (response["escape_directions"] as Array).is_empty():
		return "At least one authored escape candidate is required"
	return _floor_error(response["floor_regions"] if response.has("floor_regions") else null, actor.global_position)


func _prove(candidate: Dictionary, response: Dictionary) -> Dictionary:
	var actor: CharacterBody3D = response["actor"]
	var stats: Dictionary = response["stats"]
	var origin: Vector3 = actor.global_position
	# Conservatively sum recognition, current stationary commitment and remaining
	# dash cooldown; no instantaneous ideal dash or immunity is credited.
	var dash_start: float = _clock + float(response["recognition_s"]) + float(response["commitment_remaining_s"]) + float(response["dash_cooldown_left_s"])
	var dash_end: float = dash_start + float(stats["dash_duration"])
	var primary_ready: float = _clock + float(response["primary_cooldown_left_s"])
	var all_threats: Array[Dictionary] = [candidate]
	for reservation: Dictionary in _reservations.values():
		all_threats.append(reservation)
	for direction: Vector3 in response["escape_directions"]:
		var landing: Vector3 = origin + direction * float(stats["dash_distance"])
		if not Geometry.finite_vector(landing):
			continue
		var initial: Array[Dictionary] = [_segment(origin, origin, _clock, dash_start, "recognition_and_ready"), _segment(origin, landing, dash_start, dash_end, "escape_dash")]
		var opening_start: float = maxf(dash_end, float(candidate["active_until_s"]) + TIME_MARGIN)
		var return_choices: Array[Vector3] = [Vector3.ZERO]
		for returning: Vector3 in response["return_directions"]:
			return_choices.append(returning)
		for returning: Vector3 in return_choices:
			var path: Array[Dictionary] = initial.duplicate(true)
			var attack_position: Vector3 = landing
			var attack_start: float = maxf(opening_start, primary_ready) + float(response["attack_input_margin_s"])
			if returning != Vector3.ZERO:
				var return_start: float = maxf(opening_start, dash_start + float(stats["dash_cooldown"]))
				attack_position = landing + returning * float(stats["dash_distance"])
				if not Geometry.finite_vector(attack_position):
					continue
				path.append(_segment(landing, landing, dash_end, return_start, "recovery_wait"))
				var return_end: float = return_start + float(stats["dash_duration"])
				path.append(_segment(landing, attack_position, return_start, return_end, "positioning_dash"))
				attack_start = maxf(return_end, primary_ready) + float(response["attack_input_margin_s"])
				path.append(_segment(attack_position, attack_position, return_end, attack_start, "primary_ready"))
			else:
				path.append(_segment(landing, landing, dash_end, attack_start, "recovery_wait"))
			# Holding through full ordinary recovery is stricter than the immediate
			# hit/short logical phase; it covers the slowest selected weapon cadence.
			var finish: float = attack_start + maxf(float(stats["primary_cooldown"]), float(response["primary_commitment_s"]))
			if not is_finite(finish) or finish > float(candidate["recovery_until_s"]) - TIME_MARGIN:
				continue
			path.append(_segment(attack_position, attack_position, attack_start, finish, "ordinary_primary"))
			if not _opening_reachable(attack_position, candidate["opening_position"], float(stats["primary_range"])):
				continue
			var safe: bool = true
			for segment: Dictionary in path:
				if not _floor_path_supported(segment["from"], segment["to"], response["floor_regions"]) or not _capsule_path_clear(segment["from"], segment["to"], actor, response["floor_regions"]):
					safe = false
					break
			if not safe:
				continue
			for existing: Dictionary in all_threats:
				if Geometry.timed_path_hits(existing["geometry"], path, float(existing["active_from_s"]), float(existing["active_until_s"]), CAPSULE_RADIUS + SKIN):
					safe = false
					break
			if safe:
				return {"accepted": true, "path": path, "landing": landing, "attack_position": attack_position, "primary_time_s": attack_start, "response_complete_s": finish, "uses_blast": false, "uses_invulnerability": false, "proof_scope": "static_box_floor_full_dash_stationary_primary"}
	return {"accepted": false, "reason": "No supported collision/floor-safe timed escape and ordinary-primary opening through the committed threat union"}


func _segment(start: Vector3, finish: Vector3, begin: float, end: float, kind: String) -> Dictionary:
	return {"from": start, "to": finish, "start_s": begin, "end_s": end, "kind": kind}


func _opening_reachable(position: Vector3, target: Vector3, reach: float) -> bool:
	if Geometry.planar(position).distance_to(Geometry.planar(target)) > reach - SKIN or absf(position.y - target.y) > 1.4:
		return false
	var query := PhysicsRayQueryParameters3D.create(position + Vector3.UP * 0.7, target + Vector3.UP * 0.7, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _floor_error(regions: Variant, position: Vector3) -> String:
	if not regions is Array or regions.is_empty() or regions.size() > 32:
		return "Authored supported floor regions are required"
	var floor_height: float = INF
	for region: Variant in regions:
		if not region is Dictionary or not region.get("safe_rect") is Rect2:
			return "Floor region needs a world X/Z safe_rect"
		var collision: CollisionShape3D = region.get("collision") as CollisionShape3D
		if not is_instance_valid(collision) or not collision.is_inside_tree() or collision.disabled or not collision.shape is BoxShape3D or not collision.get_parent() is StaticBody3D or not collision.global_basis.is_equal_approx(Basis.IDENTITY):
			return "Floor proof requires a live unrotated solid static box collider"
		var body: StaticBody3D = collision.get_parent() as StaticBody3D
		if body.get_world_3d() != get_world_3d() or (body.collision_layer & 1) == 0:
			return "Floor collider must participate in the shared scenery mask"
		var collision_count: int = 0
		for child: Node in body.get_children():
			if child is CollisionShape3D or child is CollisionPolygon3D:
				collision_count += 1
		if collision_count != 1:
			return "Supported floor body must own exactly one box shape"
		var box: BoxShape3D = collision.shape as BoxShape3D
		var rect: Rect2 = region["safe_rect"]
		var floor_rect := Rect2(Geometry.planar(collision.global_position) - Vector2(box.size.x, box.size.z) * 0.5, Vector2(box.size.x, box.size.z))
		var top: float = collision.global_position.y + box.size.y * 0.5
		if not Geometry.finite_vector(box.size) or not Geometry.finite_vector(collision.global_position) or not is_finite(top):
			return "Floor proof needs finite box dimensions and transform"
		if is_finite(floor_height) and absf(top - floor_height) > EPSILON:
			return "Supported floor boxes must share one ground height"
		floor_height = top
		var feet_y: float = position.y + CAPSULE_CENTER_Y - CAPSULE_HEIGHT * 0.5
		if not rect.position.is_finite() or not rect.size.is_finite() or rect.size.x <= 2.0 * (CAPSULE_RADIUS + SKIN) or rect.size.y <= 2.0 * (CAPSULE_RADIUS + SKIN) or not floor_rect.encloses(rect) or absf(feet_y - top) > FEET_TOLERANCE:
			return "Authored safe rectangle must fit a continuous box floor at actor feet height"
	return ""


func _floor_path_supported(start: Vector3, finish: Vector3, regions: Array) -> bool:
	if absf(start.y - finish.y) > EPSILON:
		return false
	var intervals: Array[Vector2] = []
	var a: Vector2 = Geometry.planar(start)
	var b: Vector2 = Geometry.planar(finish)
	for region: Dictionary in regions:
		var rect: Rect2 = (region["safe_rect"] as Rect2).grow(-(CAPSULE_RADIUS + SKIN))
		var interval := Vector2(0, 1)
		for axis: int in range(2):
			var movement: float = b[axis] - a[axis]
			if absf(movement) <= EPSILON:
				if a[axis] < rect.position[axis] - EPSILON or a[axis] > rect.end[axis] + EPSILON:
					interval = Vector2(1, 0)
					break
			else:
				var first: float = (rect.position[axis] - a[axis]) / movement
				var last: float = (rect.end[axis] - a[axis]) / movement
				interval.x = maxf(interval.x, minf(first, last))
				interval.y = minf(interval.y, maxf(first, last))
		if interval.x <= interval.y:
			intervals.append(interval)
	intervals.sort_custom(func(left: Vector2, right: Vector2) -> bool: return left.x < right.x)
	var covered: float = 0.0
	for interval: Vector2 in intervals:
		if interval.x > covered + EPSILON:
			return false
		covered = maxf(covered, interval.y)
	if covered < 1.0 - EPSILON:
		return false
	# Rays confirm current physics registration; analytic box coverage above is
	# the continuous support proof. Sparse probes alone never establish no holes.
	for point: Vector3 in [start, finish]:
		var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.2, point - Vector3.UP * 0.2, 1)
		var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			return false
		var matched: bool = false
		for region: Dictionary in regions:
			if hit["rid"] == ((region["collision"] as CollisionShape3D).get_parent() as StaticBody3D).get_rid():
				matched = true
		if not matched:
			return false
	return true


func _capsule_path_clear(start: Vector3, finish: Vector3, actor: CharacterBody3D, regions: Array) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = CAPSULE_RADIUS + SKIN
	# Cover the small allowed standing/settling tolerance too. Distinct floor
	# heights are rejected, so excluded floor bodies cannot hide a step collision.
	capsule.height = CAPSULE_HEIGHT + 2.0 * (SKIN + FEET_TOLERANCE)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.collide_with_areas = false
	var excluded: Array[RID] = [actor.get_rid()]
	for region: Dictionary in regions:
		excluded.append(((region["collision"] as CollisionShape3D).get_parent() as StaticBody3D).get_rid())
	query.exclude = excluded
	query.transform = Transform3D(Basis.IDENTITY, start + Vector3.UP * CAPSULE_CENTER_Y)
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if not space.intersect_shape(query, 1).is_empty():
		return false
	query.motion = finish - start
	var fractions: PackedFloat32Array = space.cast_motion(query)
	if fractions.size() != 2 or float(fractions[0]) < 1.0 - EPSILON:
		return false
	query.transform.origin = finish + Vector3.UP * CAPSULE_CENTER_Y
	query.motion = Vector3.ZERO
	return space.intersect_shape(query, 1).is_empty()


func _floor_guards(regions: Array) -> Array[Dictionary]:
	var guards: Array[Dictionary] = []
	for region: Dictionary in regions:
		var collision: CollisionShape3D = region["collision"]
		guards.append({"node": weakref(collision), "transform": collision.global_transform, "size": (collision.shape as BoxShape3D).size})
	return guards


func _guards_valid(guards: Array) -> bool:
	for guard: Dictionary in guards:
		var collision: CollisionShape3D = (guard["node"] as WeakRef).get_ref() as CollisionShape3D
		if not is_instance_valid(collision) or not collision.is_inside_tree() or collision.disabled or not collision.shape is BoxShape3D or not collision.global_transform.is_equal_approx(guard["transform"]) or not (collision.shape as BoxShape3D).size.is_equal_approx(guard["size"]):
			return false
	return true
