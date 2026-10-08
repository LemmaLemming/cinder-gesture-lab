class_name CinderThreatScheduler
extends Node3D
## Conservative supported-response witness, not a campaign fairness certificate.
## Root supplies exact live commitment/cooldown data and authored candidate swipes.
## We prove unobstructed full-distance dashes on immutable, unrotated box floors,
## then a stationary ordinary-primary opening. No blast, invulnerability tanking,
## dynamic floor or moving recovery target is assumed. Tracking warns unarmed
## until atomic reproof at lock; a straight real-body lunge reserves its entire
## collision-shortened swept lane and stationary endpoint recovery. Unsupported
## inputs reject. Candidate enumeration can false-reject ordinary valid play.
## Logical threat intersection is continuous in space/time; floor continuity is
## established analytically against actual solid floor boxes, not ray samples.
## Capsule casts still use the engine's numerical physics tolerances. Owners MUST
## cancel their attack on reservation_invalidated; world changes MUST invalidate
## the encounter before altering collision. Future navigation/replay adapters must
## supply their own proof rather than opt out of these checks.

signal reservation_invalidated(reservation_id: String, reason: String)

const DifficultyScript = preload("res://scripts/combat/difficulty.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const API_REVISION: String = "threat-scheduler-3"
const SNAPSHOT_API_REVISION: String = "scheduler-snapshot-1"
const SNAPSHOT_SCHEMA_VERSION: int = 1
const CAPSULE_RADIUS: float = 0.32
const CAPSULE_HEIGHT: float = 1.45
const CAPSULE_CENTER_Y: float = 0.73
const SKIN: float = 0.01
const FEET_TOLERANCE: float = 0.015
const EPSILON: float = 0.00001
const TIME_MARGIN: float = 0.001

var last_error: String = ""
var last_snapshot_error: String = ""
var _difficulty = DifficultyScript.new()
var _profile: Dictionary = {}
var _encounter_id: String = ""
var _world_revision: int = 0
var _clock: float = 0.0
var _serial: int = 0
var _reservations: Dictionary = {}
var _cooldowns: Dictionary = {}
var _boundary_busy: bool = false
var _snapshot_busy: bool = false
var _request_busy: bool = false
var _transaction_depth: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func begin_encounter(profile_id: String, encounter_id: String = "encounter", world_revision: int = 1) -> bool:
	last_error = ""
	if _snapshot_busy or _request_busy or _transaction_depth > 0 or _boundary_busy or not _encounter_id.is_empty():
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
	if _snapshot_busy or _request_busy or _transaction_depth > 0 or _boundary_busy:
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
	if _snapshot_busy or _request_busy or _boundary_busy or _transaction_depth > 0:
		last_error = "Scheduler transaction is already in progress"
		return {"accepted": false, "reason": last_error}
	_request_busy = true
	_transaction_depth += 1
	var result: Dictionary = _request_attack(owner, threat, response)
	_transaction_depth -= 1
	_request_busy = false
	return result


func _request_attack(owner: Node3D, threat: Dictionary, response: Dictionary, adapter: Dictionary = {}) -> Dictionary:
	_prune()
	last_error = _request_error(owner, threat, response, "", adapter.get("kind") == "tracking")
	if not last_error.is_empty():
		return {"accepted": false, "reason": last_error}
	if adapter.get("kind") == "lunge" and (owner.global_position.distance_to(adapter["current_position"]) > EPSILON or not _lunge_source_valid(owner, adapter)):
		return _rejected("Lunge source plan changed during reservation cleanup")
	if adapter.get("kind") == "tracking" and (not _tracking_geometry_valid(owner, threat["geometry"], adapter) or (threat["opening_position"] as Vector3).distance_to(owner.global_position) > EPSILON):
		return _rejected("Tracking source lane changed during reservation cleanup")
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
	if not adapter.is_empty():
		candidate["adapter"] = adapter.duplicate(true)
	var proof: Dictionary = {"accepted": true, "proof_scope": "unarmed_tracking_warning"} if adapter.get("kind") == "tracking" else _prove(candidate, response)
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
	return {"accepted": true, "reservation_id": reservation_id, "proof": proof, "profile_id": _profile["id"], "armed": adapter.get("kind") != "tracking", "reservation": _public_record(candidate)}


func request_tracking(owner: Node3D, threat: Dictionary, response: Dictionary) -> Dictionary:
	## source-anchored capsule lane rotates during warning, never activates itself.
	## Caller consumes returned scheduler deadlines, then supplies fresh live
	## player response at commit_tracking. A failed proof cancels the tell.
	if _snapshot_busy or _request_busy or _boundary_busy or _transaction_depth > 0:
		return _rejected("Scheduler transaction is already in progress")
	if not threat.get("geometry") is Dictionary or not _tracking_geometry_valid(owner, threat["geometry"]) or not Geometry.finite_vector(threat.get("opening_position")) or (threat["opening_position"] as Vector3).distance_to(owner.global_position) > EPSILON:
		return _rejected("Tracking requires a finite source-anchored capsule lane")
	var role: Variant = threat.get("role")
	if not role is Dictionary:
		return _rejected("Resolved tracking role required")
	var geometry: Dictionary = threat["geometry"]
	var adapter := {"kind": "tracking", "locked": false, "reach": (geometry["to"] as Vector3).distance_to(geometry["from"]), "radius": geometry["radius"], "lock_s": role.get("lock_s"), "active_s": role.get("active_s"), "recovery_s": role.get("recovery_s"), "attack_interval_s": role.get("attack_interval_s")}
	_request_busy = true
	_transaction_depth += 1
	var result: Dictionary = _request_attack(owner, threat, response, adapter)
	_transaction_depth -= 1
	_request_busy = false
	return result


func update_tracking(reservation_id: String, geometry: Dictionary) -> Dictionary:
	if _snapshot_busy or _request_busy or _boundary_busy or _transaction_depth > 0 or not is_inside_tree() or get_tree().paused:
		return _rejected("Unpaused scheduler callback barrier required")
	_prune()
	var record: Dictionary = _reservations.get(reservation_id, {})
	if record.is_empty() or record.get("adapter", {}).get("kind") != "tracking" or record["adapter"]["locked"] or _clock >= float(record["lock_from_s"]):
		return _rejected("Tracking preview may change only before lock is due")
	var owner: Node3D = (record["_owner"] as WeakRef).get_ref() as Node3D
	if not _tracking_geometry_valid(owner, geometry, record["adapter"]):
		return _rejected("Tracking retarget may rotate its fixed source lane only")
	record["geometry"] = geometry.duplicate(true)
	return {"accepted": true, "armed": false, "reservation_id": reservation_id, "reservation": _public_record(record)}


func commit_tracking(reservation_id: String, geometry: Dictionary, response: Dictionary) -> Dictionary:
	if _snapshot_busy or _request_busy or _boundary_busy or _transaction_depth > 0:
		return _rejected("Scheduler transaction is already in progress")
	_request_busy = true
	_transaction_depth += 1
	var result: Dictionary = _commit_tracking(reservation_id, geometry, response)
	_transaction_depth -= 1
	_request_busy = false
	return result


func _commit_tracking(reservation_id: String, geometry: Dictionary, response: Dictionary) -> Dictionary:
	_prune()
	var record: Dictionary = _reservations.get(reservation_id, {})
	if record.is_empty() or record.get("adapter", {}).get("kind") != "tracking" or record["adapter"]["locked"]:
		return _rejected("Live unarmed tracking reservation required")
	if not is_inside_tree() or get_tree().paused or _clock < float(record["lock_from_s"]) - EPSILON:
		return _rejected("Tracking lock is not due in an unpaused encounter")
	var owner: Node3D = (record["_owner"] as WeakRef).get_ref() as Node3D
	var adapter: Dictionary = record["adapter"]
	if not _tracking_geometry_valid(owner, geometry, adapter):
		cancel(reservation_id, "tracking_lock_unproved")
		return _rejected("Tracking lock cannot change source, lane reach or radius")
	var role := {"difficulty_schema": 1, "difficulty_profile": _profile["id"], "windup_s": float(adapter["lock_s"]) + 1.0, "lock_s": adapter["lock_s"], "active_s": adapter["active_s"], "recovery_s": adapter["recovery_s"], "attack_interval_s": adapter["attack_interval_s"]}
	var threat := {"role": role, "geometry": geometry, "source_stationary": true, "opening_stationary": true, "opening_position": record["opening_position"], "cooldown_remaining_s": 0.0}
	last_error = _request_error(owner, threat, response, reservation_id)
	if not last_error.is_empty():
		cancel(reservation_id, "tracking_lock_unproved")
		return {"accepted": false, "reason": last_error}
	var candidate: Dictionary = record.duplicate(true)
	candidate["geometry"] = geometry.duplicate(true)
	candidate["lock_from_s"] = _clock
	candidate["active_from_s"] = _clock + float(adapter["lock_s"])
	candidate["active_until_s"] = float(candidate["active_from_s"]) + float(adapter["active_s"])
	candidate["recovery_until_s"] = float(candidate["active_until_s"]) + float(adapter["recovery_s"])
	candidate["cooldown_until_s"] = float(candidate["active_from_s"]) + float(adapter["attack_interval_s"])
	if not is_finite(candidate["recovery_until_s"]) or not is_finite(candidate["cooldown_until_s"]):
		cancel(reservation_id, "tracking_lock_unproved")
		return _rejected("Locked deadlines must remain finite")
	for other: Dictionary in _reservations.values():
		if other["id"] != reservation_id and float(other["active_until_s"]) >= _clock and absf(float(other["active_from_s"]) - float(candidate["active_from_s"])) < float(_profile["commit_stagger_s"]) - EPSILON:
			cancel(reservation_id, "tracking_lock_unproved")
			return _rejected("Retimed tracking lock lost its visible stagger")
	var proof: Dictionary = _prove(candidate, response, reservation_id)
	if not proof.get("accepted", false):
		cancel(reservation_id, "tracking_lock_unproved")
		last_error = proof["reason"]
		return proof
	candidate["adapter"]["locked"] = true
	candidate["_floor_guards"] = _floor_guards(response["floor_regions"])
	_reservations[reservation_id] = candidate
	_cooldowns[owner.get_instance_id()] = {"owner": weakref(owner), "ready_s": candidate["cooldown_until_s"]}
	return {"accepted": true, "armed": true, "reservation_id": reservation_id, "reservation": _public_record(candidate), "proof": proof, "profile_id": _profile["id"]}


func request_lunge(owner: CharacterBody3D, threat: Dictionary, response: Dictionary) -> Dictionary:
	## Scheduler leases real source motion until release/cancel. Its level script
	## must suspend approach/gravity/knockback and cancel(id) BEFORE any impulse.
	## Normal interruptions retain cooldown; cancel_owner is for death/removal.
	## Active damage is still level-owned and must consume reservation_state.
	if _snapshot_busy or _request_busy or _boundary_busy or _transaction_depth > 0:
		return _rejected("Scheduler transaction is already in progress")
	if threat.get("source_stationary") != false or threat.get("opening_stationary") != true or not threat.get("lunge") is Dictionary or not response.get("floor_regions") is Array:
		return _rejected("Explicit real-body lunge and authored floor proof required")
	var plan: Dictionary = Motion.plan(owner, threat["lunge"], response["floor_regions"])
	if plan.has("error"):
		return _rejected(plan["error"])
	if not threat.get("role") is Dictionary or not Geometry.finite_number(threat["role"].get("active_s")) or float(threat["role"]["active_s"]) < float(plan["duration_s"]) - EPSILON:
		return _rejected("Active window must cover full resolved distance/speed even when collision shortens travel")
	var adjusted_position: Vector3 = owner.global_position + Vector3.UP * (float(plan["foot_offset"]) - CAPSULE_CENTER_Y + CAPSULE_HEIGHT * 0.5)
	var floor_error: String = _floor_error(response["floor_regions"], adjusted_position)
	if not floor_error.is_empty() or not _floor_path_supported(plan["start"], plan["planned_endpoint"], response["floor_regions"], float(plan["source_radius"]) + SKIN):
		return _rejected("Actual lunge source lacks continuous supported floor: " + floor_error)
	var adapted: Dictionary = threat.duplicate(true)
	adapted["source_stationary"] = true # proof only: start fixed until active, recovery fixed at endpoint
	adapted["geometry"] = plan["geometry"]
	adapted["opening_position"] = plan["planned_endpoint"]
	plan.erase("geometry")
	plan.erase("source_radius")
	plan.erase("foot_offset")
	plan["current_velocity"] = Vector3.ZERO
	_request_busy = true
	_transaction_depth += 1
	var result: Dictionary = _request_attack(owner, adapted, response, plan)
	_transaction_depth -= 1
	_request_busy = false
	return result


func _rejected(reason: String) -> Dictionary:
	last_error = reason
	return {"accepted": false, "reason": reason}


func _tracking_geometry_valid(owner: Node3D, geometry: Dictionary, adapter: Dictionary = {}) -> bool:
	if not is_instance_valid(owner) or geometry.get("kind") != "lane" or not Geometry.error(geometry).is_empty() or (geometry["from"] as Vector3).distance_to(owner.global_position) > EPSILON or absf((geometry["to"] as Vector3).y - owner.global_position.y) > EPSILON:
		return false
	var reach: float = (geometry["to"] as Vector3).distance_to(geometry["from"])
	return reach > EPSILON and (adapter.is_empty() or (is_equal_approx(reach, adapter["reach"]) and is_equal_approx(geometry["radius"], adapter["radius"])))


func cancel(reservation_id: String, reason: String = "cancelled") -> bool:
	if _snapshot_busy or not _reservations.has(reservation_id):
		return false
	var record: Dictionary = _reservations[reservation_id]
	# Stop only owned motion. A caller must cancel BEFORE applying knockback.
	if record.get("adapter", {}).get("kind") == "lunge":
		var source: CharacterBody3D = (record["_owner"] as WeakRef).get_ref() as CharacterBody3D
		if is_instance_valid(source):
			source.velocity = Vector3.ZERO
	_reservations.erase(reservation_id)
	# Cancellation releases geometry/budget; cooldown remains conservative until
	# the scheduled role interval expires. Death/removal cancels owner cooldown too.
	_transaction_depth += 1
	reservation_invalidated.emit(reservation_id, reason)
	_transaction_depth -= 1
	return true


func cancel_owner(owner: Node3D, reason: String = "source_defeated") -> void:
	if _snapshot_busy or _boundary_busy or not is_instance_valid(owner):
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
	if _snapshot_busy or _boundary_busy:
		return
	if new_revision <= _world_revision:
		last_error = "Collision world revision must increase"
		return
	_boundary_busy = true
	for reservation_id: String in _reservations.keys():
		cancel(reservation_id, "collision_world_changed")
	_world_revision = new_revision
	_boundary_busy = false


func has_committed_exchange() -> bool:
	## Pure diagnostic: stale entries still occupy a compound-proof barrier.
	## Cleanup and cancellation callbacks remain in ordinary scheduler updates.
	return not _reservations.is_empty()


func reservations() -> Array[Dictionary]:
	if not _snapshot_busy:
		_prune()
	var result: Array[Dictionary] = []
	for record: Dictionary in _reservations.values():
		result.append(_public_record(record))
	return result


func reservation_state(reservation_id: String) -> Dictionary:
	if not _snapshot_busy:
		_prune()
	return _public_record(_reservations[reservation_id]) if _reservations.has(reservation_id) else {}


func _public_record(record: Dictionary) -> Dictionary:
	var copy: Dictionary = record.duplicate(true)
	copy.erase("_owner")
	copy.erase("_floor_guards")
	var pending: bool = record.get("adapter", {}).get("kind") == "tracking" and not record["adapter"]["locked"]
	copy["armed"] = not pending
	copy["state"] = "warning" if pending or _clock < float(record["lock_from_s"]) else ("lock" if _clock < float(record["active_from_s"]) else ("active" if _clock <= float(record["active_until_s"]) else "recovery"))
	return copy


func _physics_process(delta: float) -> void:
	if _encounter_id.is_empty():
		return
	_transaction_depth += 1
	_clock += delta
	_prune()
	_advance_lunges()
	_transaction_depth -= 1


func _prune() -> void:
	for reservation_id: String in _reservations.keys():
		if not _reservations.has(reservation_id):
			continue
		var record: Dictionary = _reservations[reservation_id]
		var owner: Node3D = (record["_owner"] as WeakRef).get_ref() as Node3D
		if not is_instance_valid(owner) or owner.is_queued_for_deletion() or not owner.is_inside_tree():
			cancel(reservation_id, "source_removed")
		elif owner.global_position.distance_to(record["source_position"]) > EPSILON:
			cancel(reservation_id, "stationary_source_moved")
		elif record.get("adapter", {}).get("kind") == "lunge" and not _lunge_source_valid(owner, record["adapter"]):
			cancel(reservation_id, "lunge_source_changed")
		elif not _guards_valid(record["_floor_guards"]):
			cancel(reservation_id, "floor_contract_changed")
		elif record.get("adapter", {}).get("kind") == "tracking" and not record["adapter"]["locked"] and _clock >= float(record["active_from_s"]) - EPSILON:
			cancel(reservation_id, "tracking_lock_missed")
		elif _clock > float(record["recovery_until_s"]):
			# Normal expiry is release, not a cancellation notification.
			if record.get("adapter", {}).get("kind") == "lunge":
				(owner as CharacterBody3D).velocity = Vector3.ZERO
			_reservations.erase(reservation_id)
	for instance_id: int in _cooldowns.keys():
		var entry: Dictionary = _cooldowns[instance_id]
		var owner: Node3D = (entry["owner"] as WeakRef).get_ref() as Node3D
		if not is_instance_valid(owner) or owner.is_queued_for_deletion() or not owner.is_inside_tree() or _clock >= float(entry["ready_s"]):
			_cooldowns.erase(instance_id)


func _lunge_source_valid(owner: Node3D, adapter: Dictionary) -> bool:
	if not owner is CharacterBody3D:
		return false
	var body: CharacterBody3D = owner as CharacterBody3D
	var description: Dictionary = Motion.source_description(body, adapter["body_collision_path"])
	return not description.has("error") and Codec.same_values(description["signature"], adapter["body_signature"]) and body.velocity.distance_to(adapter["current_velocity"]) <= EPSILON


func _advance_lunges() -> void:
	for reservation_id: String in _reservations.keys():
		if not _reservations.has(reservation_id):
			continue
		var record: Dictionary = _reservations[reservation_id]
		if record.get("adapter", {}).get("kind") != "lunge" or _clock < float(record["active_from_s"]):
			continue
		var owner: CharacterBody3D = (record["_owner"] as WeakRef).get_ref() as CharacterBody3D
		var advanced: Dictionary = Motion.advance(owner, record["adapter"], minf(_clock - float(record["active_from_s"]), float(record["adapter"]["duration_s"])))
		if advanced.has("error"):
			cancel(reservation_id, "lunge_motion_unproved")
			continue
		advanced["current_velocity"] = owner.velocity
		record["adapter"] = advanced
		record["source_position"] = owner.global_position
		if advanced["finished"]:
			# Physics endpoint variation is bounded below proof skin. Expose exact
			# actual landing once stopped; never manufacture a stationary proxy.
			record["opening_position"] = owner.global_position


func _request_error(owner: Node3D, threat: Dictionary, response: Dictionary, ignored_id: String = "", allow_unstable_warning: bool = false) -> String:
	if _boundary_busy or _encounter_id.is_empty() or not is_inside_tree() or get_tree().paused:
		return "An active, unpaused encounter is required"
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion() or owner.get_world_3d() != get_world_3d() or not Geometry.finite_vector(owner.global_position):
		return "Live source in the scheduler's world required"
	if ignored_id.is_empty() and _cooldowns.has(owner.get_instance_id()):
		return "Source attack cooldown is still occupied"
	for existing: Dictionary in _reservations.values():
		if existing["id"] != ignored_id and int(existing["source_instance_id"]) == owner.get_instance_id():
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
	return response_error(response, allow_unstable_warning)


func response_error(response: Dictionary, allow_unstable_warning: bool = false) -> String:
	## Shared live-response/floor preflight for conservative compound witnesses.
	## Pure: does not prune, allocate, move a body or reserve any timing.
	if _boundary_busy or _encounter_id.is_empty() or not is_inside_tree() or get_tree().paused:
		return "An active, unpaused encounter is required"
	if response.get("world_revision") != _world_revision:
		return "Current collision world revision required"
	var actor: CharacterBody3D = response.get("actor") as CharacterBody3D
	if not is_instance_valid(actor) or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.get_world_3d() != get_world_3d() or not Geometry.finite_vector(actor.global_position) or not Geometry.finite_vector(actor.velocity):
		return "Live finite shared actor required"
	if not allow_unstable_warning and (response.get("stable") != true or actor.velocity.length() > EPSILON):
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


func _prove(candidate: Dictionary, response: Dictionary, ignored_id: String = "") -> Dictionary:
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
		if reservation["id"] != ignored_id:
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
			var opening_tolerance: float = Motion.ENDPOINT_TOLERANCE if candidate.get("adapter", {}).get("kind") == "lunge" else 0.0
			if not _opening_reachable(attack_position, candidate["opening_position"], float(stats["primary_range"]) - opening_tolerance):
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
		if body.is_queued_for_deletion() or body.get_world_3d() != get_world_3d() or (body.collision_layer & 1) == 0:
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


func _floor_path_supported(start: Vector3, finish: Vector3, regions: Array, radius: float = CAPSULE_RADIUS + SKIN) -> bool:
	if absf(start.y - finish.y) > EPSILON:
		return false
	var intervals: Array[Vector2] = []
	var a: Vector2 = Geometry.planar(start)
	var b: Vector2 = Geometry.planar(finish)
	for region: Dictionary in regions:
		var rect: Rect2 = (region["safe_rect"] as Rect2).grow(-radius)
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
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
		guards.append({"node": weakref(collision), "transform": collision.global_transform, "size": (collision.shape as BoxShape3D).size, "safe_rect": region["safe_rect"]})
	return guards


func _guards_valid(guards: Array) -> bool:
	for guard: Dictionary in guards:
		var collision: CollisionShape3D = (guard["node"] as WeakRef).get_ref() as CollisionShape3D
		if not is_instance_valid(collision) or not collision.is_inside_tree() or collision.disabled or not collision.shape is BoxShape3D or not collision.global_transform.is_equal_approx(guard["transform"]) or not (collision.shape as BoxShape3D).size.is_equal_approx(guard["size"]):
			return false
	return true


## Paused aggregate transport. bindings names stable authored owners/floors and
## supplies a world_root containing EVERY layer-1 blocker in this World3D.
## owner_positions/owner_velocities may prevalidate staged enemy motion; restore
## additionally checks actual positions/velocities at commit. Apply enemies first
## without yielding. Old stationary records retain scheduler-snapshot-1 schema;
## new records carry an optional, strictly validated adapter object.
## Capture never prunes/emits; stale bindings reject. Collision signatures derive
## from actual shape-owner data, not caller-supplied hashes or visual meshes.
func snapshot_state(bindings: Dictionary) -> Dictionary:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty():
		return {}
	_snapshot_busy = true
	last_snapshot_error = _bindings_error(bindings)
	var result: Dictionary = {}
	if last_snapshot_error.is_empty():
		result = _capture_snapshot(bindings)
		if not result.is_empty():
			last_snapshot_error = _snapshot_plan(result, bindings).get("error", "")
	_snapshot_busy = false
	return result.duplicate(true) if last_snapshot_error.is_empty() else {}


func snapshot_error(snapshot: Dictionary, bindings: Dictionary) -> String:
	var error: String = _snapshot_access_error()
	if not error.is_empty():
		return error
	_snapshot_busy = true
	var plan: Dictionary = _snapshot_plan(snapshot, bindings)
	_snapshot_busy = false
	return plan.get("error", "")


func restore_state(snapshot: Dictionary, bindings: Dictionary) -> bool:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty():
		return false
	_snapshot_busy = true
	var plan: Dictionary = _snapshot_plan(snapshot, bindings)
	last_snapshot_error = plan.get("error", "")
	if last_snapshot_error.is_empty():
		for record: Dictionary in plan["reservations"].values():
			var owner: Node3D = (record["_owner"] as WeakRef).get_ref() as Node3D
			if not is_instance_valid(owner) or owner.global_position.distance_to(record["source_position"]) > EPSILON:
				last_snapshot_error = "Apply validated enemy positions before scheduler commit"
				break
			if record.get("adapter", {}).get("kind") == "lunge" and not _lunge_source_valid(owner, record["adapter"]):
				last_snapshot_error = "Apply validated real source velocity/capsule before scheduler commit"
				break
	if last_snapshot_error.is_empty():
		# No callbacks, attack requests, damage, cancellation or retiming here.
		_encounter_id = plan["encounter_id"]
		_profile = plan["profile"].duplicate(true)
		_world_revision = plan["world_revision"]
		_clock = plan["clock_s"]
		_serial = plan["serial"]
		_reservations = plan["reservations"]
		_cooldowns = plan["cooldowns"]
	_snapshot_busy = false
	return last_snapshot_error.is_empty()


func collision_fingerprint(world_root: Node3D) -> Dictionary:
	## Public diagnostic only. Empty + last_snapshot_error means unsupported.
	var result: Dictionary = _collision_signature(world_root)
	last_snapshot_error = result.get("error", "")
	return (result.get("signature", {}) as Dictionary).duplicate(true)


func _snapshot_access_error() -> String:
	if not is_inside_tree() or not get_tree().paused:
		return "Scheduler snapshots require a paused live tree"
	if _snapshot_busy or _boundary_busy or _request_busy or _transaction_depth > 0:
		return "Scheduler snapshots require a deferred callback/physics barrier"
	return ""


func _stable_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 128:
		return false
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9_./:-]+$")
	var matched: RegExMatch = pattern.search(value)
	return matched != null and matched.get_string() == value


func _under_root(node: Node, world_root: Node3D) -> bool:
	return node == world_root or world_root.is_ancestor_of(node)


func _bindings_error(bindings: Dictionary) -> String:
	var world_root: Node3D = bindings.get("world_root") as Node3D
	if not is_instance_valid(world_root) or not world_root.is_inside_tree() or world_root.is_queued_for_deletion() or world_root.get_world_3d() != get_world_3d():
		return "Live same-world authored world_root required"
	if not bindings.get("owners") is Dictionary or not bindings.get("floors") is Dictionary:
		return "Stable owner and floor mappings required"
	if bindings.has("owner_positions") and not bindings["owner_positions"] is Dictionary:
		return "Staged owner_positions must be a dictionary"
	if bindings.has("owner_velocities") and not bindings["owner_velocities"] is Dictionary:
		return "Staged owner_velocities must be a dictionary"
	var used: Dictionary = {}
	for owner_id: Variant in bindings["owners"]:
		var owner: Node3D = bindings["owners"][owner_id] as Node3D
		if not _stable_id(owner_id) or not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion() or owner.get_world_3d() != get_world_3d() or not _under_root(owner, world_root) or used.has(owner.get_instance_id()):
			return "Owner IDs must map uniquely to live nodes under world_root"
		used[owner.get_instance_id()] = true
	for owner_id: Variant in bindings.get("owner_positions", {}):
		if not bindings["owners"].has(owner_id) or not Geometry.finite_vector(bindings["owner_positions"][owner_id]):
			return "Staged positions require a mapped stable owner and finite vector"
	for owner_id: Variant in bindings.get("owner_velocities", {}):
		if not bindings["owners"].has(owner_id) or not bindings["owners"][owner_id] is CharacterBody3D or not Geometry.finite_vector(bindings["owner_velocities"][owner_id]):
			return "Staged velocities require a mapped real source body and finite vector"
	used.clear()
	var regions: Array = []
	for floor_id: Variant in bindings["floors"]:
		var region: Variant = bindings["floors"][floor_id]
		if not _stable_id(floor_id) or not region is Dictionary:
			return "Stable authored floor IDs required"
		var collision: CollisionShape3D = region.get("collision") as CollisionShape3D
		if not is_instance_valid(collision) or not collision.is_inside_tree() or collision.is_queued_for_deletion() or not _under_root(collision, world_root) or used.has(collision.get_instance_id()):
			return "Floor IDs must map uniquely to live colliders under world_root"
		used[collision.get_instance_id()] = true
		regions.append(region)
	if not regions.is_empty():
		var first: CollisionShape3D = regions[0].get("collision") as CollisionShape3D
		if not first.shape is BoxShape3D:
			return "Snapshot floor bindings require supported box floors"
		var floor_y: float = first.global_position.y + (first.shape as BoxShape3D).size.y * 0.5
		return _floor_error(regions, Vector3(0, floor_y - CAPSULE_CENTER_Y + CAPSULE_HEIGHT * 0.5, 0))
	return ""


func _capture_snapshot(bindings: Dictionary) -> Dictionary:
	var collision: Dictionary = _collision_signature(bindings["world_root"])
	if collision.has("error"):
		last_snapshot_error = collision["error"]
		return {}
	var records: Array = []
	for reservation: Dictionary in _reservations.values():
		if float(reservation["recovery_until_s"]) < _clock:
			continue # Pure output filtering; no lifecycle signals.
		var owner: Node3D = (reservation["_owner"] as WeakRef).get_ref() as Node3D
		var owner_id: String = _binding_id(bindings["owners"], owner)
		if owner_id.is_empty() or owner.global_position.distance_to(reservation["source_position"]) > EPSILON or not _guards_valid(reservation["_floor_guards"]):
			last_snapshot_error = "Reservation has stale owner/floor bindings"
			return {}
		if reservation.get("adapter", {}).get("kind") == "lunge" and not _lunge_source_valid(owner, reservation["adapter"]):
			last_snapshot_error = "Reservation has changed real source velocity/capsule"
			return {}
		var floors: Array = []
		for guard: Dictionary in reservation["_floor_guards"]:
			var node: CollisionShape3D = (guard["node"] as WeakRef).get_ref() as CollisionShape3D
			var floor_id: String = ""
			for candidate_id: String in bindings["floors"]:
				if bindings["floors"][candidate_id]["collision"] == node:
					floor_id = candidate_id
			if floor_id.is_empty():
				last_snapshot_error = "Reserved floor has no stable binding"
				return {}
			if not (guard["safe_rect"] as Rect2).is_equal_approx(bindings["floors"][floor_id]["safe_rect"]):
				last_snapshot_error = "Reserved authored safe rectangle changed"
				return {}
			floors.append({"floor_id": floor_id, "signature": _floor_signature(bindings["floors"][floor_id], bindings["world_root"])})
		var record: Dictionary = {"id": reservation["id"], "source_id": owner_id, "source_position": Codec.vector3(reservation["source_position"]), "geometry": _encode_geometry(reservation["geometry"]), "opening_position": Codec.vector3(reservation["opening_position"]), "floors": floors}
		for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision"]:
			record[key] = reservation[key]
		if reservation.has("adapter"):
			record["adapter"] = _encode_adapter(reservation["adapter"])
		records.append(record)
	var cooldowns: Array = []
	for cooldown: Dictionary in _cooldowns.values():
		if float(cooldown["ready_s"]) <= _clock:
			continue
		var owner_id: String = _binding_id(bindings["owners"], (cooldown["owner"] as WeakRef).get_ref())
		if owner_id.is_empty():
			last_snapshot_error = "Cooldown has no stable live owner binding"
			return {}
		cooldowns.append({"source_id": owner_id, "ready_s": cooldown["ready_s"]})
	return {"api_revision": SNAPSHOT_API_REVISION, "schema_version": SNAPSHOT_SCHEMA_VERSION, "encounter_id": _encounter_id, "profile": _profile.duplicate(true), "world_revision": _world_revision, "clock_s": _clock, "serial": _serial, "collision": collision["signature"], "reservations": records, "cooldowns": cooldowns}


func _binding_id(mapping: Dictionary, node: Object) -> String:
	if not is_instance_valid(node):
		return ""
	for stable_id: String in mapping:
		if mapping[stable_id] == node:
			return stable_id
	return ""


func _snapshot_plan(snapshot: Dictionary, bindings: Dictionary) -> Dictionary:
	var error: String = Codec.value_error(snapshot)
	if error.is_empty():
		error = Codec.keys_error(snapshot, ["api_revision", "schema_version", "encounter_id", "profile", "world_revision", "clock_s", "serial", "collision", "reservations", "cooldowns"])
	if error.is_empty():
		error = _bindings_error(bindings)
	if not error.is_empty():
		return {"error": error}
	if snapshot["api_revision"] != SNAPSHOT_API_REVISION or not Codec.is_integer(snapshot["schema_version"], SNAPSHOT_SCHEMA_VERSION, SNAPSHOT_SCHEMA_VERSION) or not snapshot["encounter_id"] is String or not snapshot["profile"] is Dictionary or not Codec.is_integer(snapshot["world_revision"]) or not Codec.is_integer(snapshot["serial"]) or not Codec.is_number(snapshot["clock_s"]) or float(snapshot["clock_s"]) < 0.0 or not snapshot["reservations"] is Array or not snapshot["cooldowns"] is Array:
		return {"error": "Invalid scheduler snapshot envelope"}
	var profile: Dictionary = snapshot["profile"]
	if snapshot["encounter_id"].is_empty():
		if not profile.is_empty() or not snapshot["reservations"].is_empty() or not snapshot["cooldowns"].is_empty():
			return {"error": "Idle scheduler cannot retain committed exchanges"}
	elif not _stable_id(snapshot["encounter_id"]) or int(snapshot["world_revision"]) < 1 or not profile.get("id") is String or not Codec.same_values(profile, _difficulty.profile(profile["id"])) or profile.is_empty():
		return {"error": "Encounter profile/revision no longer matches the catalogue"}
	var collision: Dictionary = _collision_signature(bindings["world_root"])
	if collision.has("error"):
		return collision
	if not Codec.same_values(snapshot["collision"], collision["signature"]):
		return {"error": "Actual authored collision fingerprint changed"}
	var records: Dictionary = {}
	var owners: Dictionary = {}
	var cooldowns: Dictionary = {}
	var clock_s: float = snapshot["clock_s"]
	var budget: int = 0
	for value: Variant in snapshot["reservations"]:
		if not value is Dictionary:
			return {"error": "Reservation must be a dictionary"}
		var record: Dictionary = value
		var record_keys: Array = ["id", "source_id", "source_position", "geometry", "opening_position", "floors", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision"]
		if record.has("adapter"):
			record_keys.append("adapter")
		error = Codec.keys_error(record, record_keys)
		if not error.is_empty() or not record["id"] is String or not record["id"].begins_with("threat-") or not record["id"].substr(7).is_valid_int() or not Codec.is_integer(int(record["id"].substr(7)), 1, int(snapshot["serial"])) or record["id"] != "threat-%d" % int(record["id"].substr(7)) or records.has(record["id"]) or not _stable_id(record["source_id"]) or not bindings["owners"].has(record["source_id"]) or owners.has(record["source_id"]) or not Codec.is_vector3(record["source_position"]) or not Codec.is_vector3(record["opening_position"]) or not record["geometry"] is Dictionary or not record["floors"] is Array or record["floors"].is_empty() or record["profile_id"] != profile.get("id") or record["world_revision"] != snapshot["world_revision"]:
			return {"error": "Invalid reservation identity/bindings"}
		for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
			if not Codec.is_number(record[key]) or float(record[key]) < 0.0:
				return {"error": "Reservation deadlines must be finite and nonnegative"}
		if not (record["start_s"] < record["lock_from_s"] and record["lock_from_s"] < record["active_from_s"] and record["active_from_s"] < record["active_until_s"] and record["active_until_s"] < record["recovery_until_s"] and record["active_from_s"] < record["cooldown_until_s"] and record["start_s"] <= clock_s + EPSILON and clock_s <= record["recovery_until_s"] + EPSILON):
			return {"error": "Reservation phase deadline order or clock is incoherent"}
		var geometry: Dictionary = _decode_geometry(record["geometry"])
		if geometry.is_empty():
			return {"error": "Invalid serialized authoritative geometry"}
		var owner: Node3D = bindings["owners"][record["source_id"]]
		var source_position: Vector3 = Codec.read_vector3(record["source_position"])
		var staged: Vector3 = bindings.get("owner_positions", {}).get(record["source_id"], owner.global_position)
		if staged.distance_to(source_position) > EPSILON:
			return {"error": "Bound/staged owner position differs from saved exchange"}
		var regions: Array = []
		var floor_ids: Dictionary = {}
		for floor_value: Variant in record["floors"]:
			if not floor_value is Dictionary or not Codec.keys_error(floor_value, ["floor_id", "signature"]).is_empty() or not _stable_id(floor_value["floor_id"]) or not bindings["floors"].has(floor_value["floor_id"]) or floor_ids.has(floor_value["floor_id"]):
				return {"error": "Reserved floor ID is missing or duplicated"}
			var region: Dictionary = bindings["floors"][floor_value["floor_id"]]
			if not Codec.same_values(floor_value["signature"], _floor_signature(region, bindings["world_root"])):
				return {"error": "Authored floor signature changed"}
			floor_ids[floor_value["floor_id"]] = true
			regions.append(region)
		var committed: Dictionary = record.duplicate(true)
		committed.erase("source_id")
		committed.erase("floors")
		committed["source_position"] = source_position
		committed["opening_position"] = Codec.read_vector3(record["opening_position"])
		committed["geometry"] = geometry
		committed["source_instance_id"] = owner.get_instance_id()
		committed["_owner"] = weakref(owner)
		committed["_floor_guards"] = _floor_guards(regions)
		if record.has("adapter"):
			var adapter: Dictionary = _decode_adapter(record["adapter"] if record["adapter"] is Dictionary else {}, committed, owner, regions, clock_s, bindings.get("owner_velocities", {}).get(record["source_id"], (owner as CharacterBody3D).velocity if owner is CharacterBody3D else Vector3.ZERO))
			if adapter.has("error"):
				return adapter
			committed["adapter"] = adapter
		records[record["id"]] = committed
		owners[record["source_id"]] = record
		if float(record["active_until_s"]) >= clock_s:
			budget += 1
	if not profile.is_empty() and budget > int(profile["reserved_threat_budget"]):
		return {"error": "Snapshot exceeds its preparing/active threat budget"}
	var committed_records: Array = records.values()
	for first_index: int in range(committed_records.size()):
		for second_index: int in range(first_index + 1, committed_records.size()):
			var first: Dictionary = committed_records[first_index]
			var second: Dictionary = committed_records[second_index]
			if float(first["active_until_s"]) >= clock_s and float(second["active_until_s"]) >= clock_s and absf(float(first["active_from_s"]) - float(second["active_from_s"])) < float(profile["commit_stagger_s"]) - EPSILON:
				return {"error": "Snapshot committed activations lost their visible stagger"}
	for value: Variant in snapshot["cooldowns"]:
		if not value is Dictionary or not Codec.keys_error(value, ["source_id", "ready_s"]).is_empty() or not _stable_id(value["source_id"]) or not bindings["owners"].has(value["source_id"]) or not Codec.is_number(value["ready_s"]) or float(value["ready_s"]) <= clock_s:
			return {"error": "Invalid retained source cooldown"}
		var owner: Node3D = bindings["owners"][value["source_id"]]
		if cooldowns.has(owner.get_instance_id()):
			return {"error": "Duplicated source cooldown"}
		cooldowns[owner.get_instance_id()] = {"owner": weakref(owner), "ready_s": float(value["ready_s"])}
	for owner_id: String in owners:
		var record: Dictionary = owners[owner_id]
		var instance_id: int = (bindings["owners"][owner_id] as Node3D).get_instance_id()
		if float(record["cooldown_until_s"]) > clock_s and (not cooldowns.has(instance_id) or not is_equal_approx(float(cooldowns[instance_id]["ready_s"]), float(record["cooldown_until_s"]))):
			return {"error": "Reservation and retained cooldown disagree"}
	return {"encounter_id": snapshot["encounter_id"], "profile": profile.duplicate(true), "world_revision": int(snapshot["world_revision"]), "clock_s": clock_s, "serial": int(snapshot["serial"]), "reservations": records, "cooldowns": cooldowns}


func _encode_adapter(adapter: Dictionary) -> Dictionary:
	var encoded: Dictionary = adapter.duplicate(true)
	if adapter.get("kind") == "lunge":
		for key: String in ["start", "planned_endpoint", "current_position", "current_velocity", "direction"]:
			encoded[key] = Codec.vector3(adapter[key])
	return encoded


func _decode_adapter(value: Dictionary, record: Dictionary, owner: Node3D, regions: Array, clock_s: float, staged_velocity: Vector3) -> Dictionary:
	if value.get("kind") == "tracking":
		if not Codec.keys_error(value, ["kind", "locked", "reach", "radius", "lock_s", "active_s", "recovery_s", "attack_interval_s"]).is_empty() or not value["locked"] is bool:
			return {"error": "Invalid tracking adapter fields"}
		for key: String in ["reach", "radius", "lock_s", "active_s", "recovery_s", "attack_interval_s"]:
			if not Codec.is_number(value[key]) or float(value[key]) <= 0.0:
				return {"error": "Tracking adapter needs finite positive geometry/timing"}
		var geometry: Dictionary = record["geometry"]
		if geometry["kind"] != "lane" or (geometry["from"] as Vector3).distance_to(record["source_position"]) > EPSILON or (record["opening_position"] as Vector3).distance_to(record["source_position"]) > EPSILON or not is_equal_approx((geometry["to"] as Vector3).distance_to(geometry["from"]), value["reach"]) or not is_equal_approx(geometry["radius"], value["radius"]):
			return {"error": "Tracking adapter no longer matches its fixed source lane"}
		if not is_equal_approx(float(record["active_from_s"]) - float(record["lock_from_s"]), value["lock_s"]) or not is_equal_approx(float(record["active_until_s"]) - float(record["active_from_s"]), value["active_s"]) or not is_equal_approx(float(record["recovery_until_s"]) - float(record["active_until_s"]), value["recovery_s"]) or not is_equal_approx(float(record["cooldown_until_s"]) - float(record["active_from_s"]), value["attack_interval_s"]) or (not value["locked"] and clock_s >= float(record["active_from_s"]) - EPSILON) or (value["locked"] and clock_s < float(record["lock_from_s"]) - EPSILON):
			return {"error": "Tracking adapter arming/deadlines are incoherent"}
		return value.duplicate(true)
	if value.get("kind") != "lunge" or not owner is CharacterBody3D:
		return {"error": "Unsupported source adapter"}
	var keys: Array = ["kind", "start", "planned_endpoint", "current_position", "current_velocity", "direction", "speed", "distance", "duration_s", "damage_radius", "body_signature", "body_collision_path", "collision_shortened", "actual_collided", "finished"]
	if not Codec.keys_error(value, keys).is_empty() or not value["body_signature"] is Dictionary or not value["body_collision_path"] is String or value["body_collision_path"].is_empty() or value["body_collision_path"].contains("\n") or value["body_collision_path"].contains("\r"):
		return {"error": "Invalid lunge adapter fields"}
	for key: String in ["collision_shortened", "actual_collided", "finished"]:
		if not value[key] is bool:
			return {"error": "Lunge collision/completion flags must be booleans"}
	var adapter: Dictionary = value.duplicate(true)
	for key: String in ["start", "planned_endpoint", "current_position", "current_velocity", "direction"]:
		if not Codec.is_vector3(value[key]):
			return {"error": "Lunge adapter needs finite serialized motion vectors"}
		adapter[key] = Codec.read_vector3(value[key])
	for key: String in ["speed", "distance", "duration_s", "damage_radius"]:
		if not Codec.is_number(value[key]) or float(value[key]) <= 0.0:
			return {"error": "Lunge adapter needs finite positive motion data"}
	var description: Dictionary = Motion.source_description(owner as CharacterBody3D, value["body_collision_path"])
	if description.has("error") or not Codec.same_values(description.get("signature", {}), value["body_signature"]):
		return {"error": "Saved lunge physical source signature changed"}
	var direction: Vector3 = adapter["direction"]
	var route: Vector3 = adapter["planned_endpoint"] - adapter["start"]
	var travelled: Vector3 = adapter["current_position"] - adapter["start"]
	var length: float = route.dot(direction)
	var progress: float = travelled.dot(direction)
	if absf(direction.y) > EPSILON or absf(direction.length() - 1.0) > EPSILON or absf(route.y) > EPSILON or (route - direction * length).length() > EPSILON or length < -EPSILON or length > float(value["distance"]) + EPSILON or absf(travelled.y) > EPSILON or (travelled - direction * progress).length() > EPSILON or progress < -EPSILON or progress > length + Motion.ENDPOINT_TOLERANCE or float(value["distance"]) <= EPSILON or float(value["distance"]) > Motion.MAX_DISTANCE or not (direction * float(value["speed"])).is_finite():
		return {"error": "Saved lunge must stay on its bounded straight physical route"}
	if not is_equal_approx(float(value["duration_s"]), float(value["distance"]) / float(value["speed"])) or float(record["active_until_s"]) - float(record["active_from_s"]) < float(value["duration_s"]) - EPSILON or float(value["damage_radius"]) < float(description["radius"]) + Motion.ENDPOINT_TOLERANCE or value["collision_shortened"] != (length < float(value["distance"]) - EPSILON):
		return {"error": "Saved lunge timing/footprint/shortening is incoherent"}
	var geometry: Dictionary = record["geometry"]
	if geometry["kind"] != "lane" or (geometry["from"] as Vector3).distance_to(adapter["start"]) > EPSILON or (geometry["to"] as Vector3).distance_to(adapter["planned_endpoint"]) > EPSILON or not is_equal_approx(geometry["radius"], value["damage_radius"]) or (adapter["current_position"] as Vector3).distance_to(record["source_position"]) > EPSILON or (adapter["current_velocity"] as Vector3).distance_to(staged_velocity) > EPSILON:
		return {"error": "Saved lunge geometry or staged real source motion differs"}
	var elapsed: float = maxf(0.0, clock_s - float(record["active_from_s"]))
	var expected: float = minf(float(value["distance"]), float(value["speed"]) * elapsed)
	var velocity: Vector3 = adapter["current_velocity"]
	if progress > expected + Motion.ENDPOINT_TOLERANCE:
		return {"error": "Saved physical source cannot arrive before resolved travel time"}
	if value["finished"]:
		if clock_s < float(record["active_from_s"]) - EPSILON or (adapter["current_position"] as Vector3).distance_to(adapter["planned_endpoint"]) > Motion.ENDPOINT_TOLERANCE or velocity.length() > EPSILON or (value["collision_shortened"] and not value["actual_collided"]) or (not value["actual_collided"] and expected < float(value["distance"]) - EPSILON) or (record["opening_position"] as Vector3).distance_to(adapter["current_position"]) > EPSILON:
			return {"error": "Saved finished lunge has no coherent physical landing"}
	else:
		var expected_velocity: Vector3 = direction * float(value["speed"]) if elapsed > EPSILON else Vector3.ZERO
		if value["actual_collided"] or elapsed >= float(value["duration_s"]) + EPSILON or absf(progress - expected) > Motion.ENDPOINT_TOLERANCE or velocity.distance_to(expected_velocity) > EPSILON or (record["opening_position"] as Vector3).distance_to(adapter["planned_endpoint"]) > EPSILON:
			return {"error": "Saved running lunge clock/velocity is incoherent"}
	var adjusted: Vector3 = adapter["start"] + Vector3.UP * (float(description["foot_offset"]) - CAPSULE_CENTER_Y + CAPSULE_HEIGHT * 0.5)
	if not _floor_error(regions, adjusted).is_empty() or not _floor_path_supported(adapter["start"], adapter["planned_endpoint"], regions, float(description["radius"]) + SKIN):
		return {"error": "Saved lunge source route lacks supported actual floor"}
	return adapter


func _encode_geometry(geometry: Dictionary) -> Dictionary:
	var result: Dictionary = geometry.duplicate(true)
	for key: String in result:
		if result[key] is Vector3:
			result[key] = Codec.vector3(result[key])
	return result


func _decode_geometry(value: Dictionary) -> Dictionary:
	var keys: Array = []
	var points: Array = []
	match value.get("kind"):
		"circle":
			keys = ["kind", "origin", "radius"]
			points = ["origin"]
		"cone":
			keys = ["kind", "origin", "direction", "reach", "min_dot", "origin_radius"]
			points = ["origin", "direction"]
		"lane":
			keys = ["kind", "from", "to", "radius"]
			points = ["from", "to"]
		_:
			return {}
	if not Codec.keys_error(value, keys).is_empty():
		return {}
	var result: Dictionary = value.duplicate(true)
	for key: String in points:
		if not Codec.is_vector3(result[key]):
			return {}
		result[key] = Codec.read_vector3(result[key])
	return result if Geometry.error(result).is_empty() else {}


func _transform_data(value: Transform3D) -> Array:
	return [Codec.vector3(value.basis.x), Codec.vector3(value.basis.y), Codec.vector3(value.basis.z), Codec.vector3(value.origin)]


func _floor_signature(region: Dictionary, world_root: Node3D) -> Dictionary:
	var collision: CollisionShape3D = region["collision"]
	var body: StaticBody3D = collision.get_parent() as StaticBody3D
	var rect: Rect2 = region["safe_rect"]
	return {"path": String(world_root.get_path_to(collision)), "transform": _transform_data(collision.global_transform), "size": Codec.vector3((collision.shape as BoxShape3D).size), "layer": body.collision_layer, "mask": body.collision_mask, "safe_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]}


func _collision_signature(world_root: Node3D) -> Dictionary:
	if not is_instance_valid(world_root) or not world_root.is_inside_tree() or world_root.get_world_3d() != get_world_3d():
		return {"error": "Live same-world collision root required"}
	var colliders: Array = []
	var pending: Array[Node] = [get_tree().root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		pending.append_array(node.get_children())
		if not node is Node3D or (node as Node3D).get_world_3d() != get_world_3d():
			continue
		if node is GridMap or (node is CSGShape3D and (node as CSGShape3D).use_collision):
			return {"error": "Generated GridMap/CSG collision has no supported stable fingerprint"}
		if not node is PhysicsBody3D or ((node as PhysicsBody3D).collision_layer & 1) == 0:
			continue
		if not node is StaticBody3D or node is AnimatableBody3D or not _under_root(node, world_root):
			return {"error": "All scenery blockers must be immutable static bodies under world_root"}
		var body: StaticBody3D = node as StaticBody3D
		if body.is_queued_for_deletion() or body.constant_linear_velocity != Vector3.ZERO or body.constant_angular_velocity != Vector3.ZERO:
			return {"error": "Moving static-body collision is unsupported"}
		var path: String = String(world_root.get_path_to(body))
		if path.contains("@") or path.contains("\n") or path.contains("\r"):
			return {"error": "Scenery collider paths require stable authored node names"}
		var shapes: Array = []
		for owner_id: int in body.get_shape_owners():
			if body.is_shape_owner_disabled(owner_id):
				continue
			var owner: Object = body.shape_owner_get_owner(owner_id)
			if not owner is Node or not body.is_ancestor_of(owner as Node):
				return {"error": "Collision shape owner requires a stable authored child path"}
			var owner_path: String = String(body.get_path_to(owner as Node))
			if owner_path.contains("@") or owner_path.contains("\n") or owner_path.contains("\r"):
				return {"error": "Collision shape paths require stable authored names"}
			for shape_index: int in range(body.shape_owner_get_shape_count(owner_id)):
				var shape: Shape3D = body.shape_owner_get_shape(owner_id, shape_index)
				var data: Dictionary = _shape_data(shape)
				if data.is_empty():
					return {"error": "Unsupported scenery collision shape: " + shape.get_class()}
				shapes.append({"path": owner_path, "index": shape_index, "transform": _transform_data(body.shape_owner_get_transform(owner_id)), "data": data})
		shapes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["path"] < b["path"] or (a["path"] == b["path"] and a["index"] < b["index"]))
		colliders.append({"path": path, "transform": _transform_data(body.global_transform), "layer": body.collision_layer, "mask": body.collision_mask, "priority": body.collision_priority, "shapes": shapes})
		if colliders.size() > 256:
			return {"error": "Supported collision fingerprint exceeds 256 bodies"}
	colliders.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["path"] < b["path"])
	var signature := {"schema_version": 1, "physics_engine": ProjectSettings.get_setting("physics/3d/physics_engine", "DEFAULT"), "physics_ticks_per_second": Engine.physics_ticks_per_second, "colliders": colliders}
	var error: String = Codec.value_error(signature)
	return {"signature": signature} if error.is_empty() else {"error": error}


func _shape_data(shape: Shape3D) -> Dictionary:
	var result := {"type": shape.get_class(), "margin": shape.margin, "custom_solver_bias": shape.custom_solver_bias}
	if shape is BoxShape3D:
		result["size"] = Codec.vector3((shape as BoxShape3D).size)
	elif shape is SphereShape3D:
		result["radius"] = (shape as SphereShape3D).radius
	elif shape is CapsuleShape3D or shape is CylinderShape3D:
		result["radius"] = (shape as CapsuleShape3D).radius if shape is CapsuleShape3D else (shape as CylinderShape3D).radius
		result["height"] = (shape as CapsuleShape3D).height if shape is CapsuleShape3D else (shape as CylinderShape3D).height
	elif shape is ConvexPolygonShape3D or shape is ConcavePolygonShape3D:
		var points: PackedVector3Array = (shape as ConvexPolygonShape3D).points if shape is ConvexPolygonShape3D else (shape as ConcavePolygonShape3D).get_faces()
		var encoded: Array = []
		for point: Vector3 in points:
			encoded.append(Codec.vector3(point))
		result["points"] = encoded
		if shape is ConcavePolygonShape3D:
			result["backface_collision"] = (shape as ConcavePolygonShape3D).backface_collision
	else:
		return {}
	return result
