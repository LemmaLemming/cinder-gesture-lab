class_name CinderLungeMotion
extends RefCounted
## Real-body straight motion only. The scheduler separately proves floor/escape
## and reserves the full swept damage lane. No sliding, tracking, gravity,
## moving platforms or source collision with actors is supported here.

const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const BodySweep = preload("res://scripts/combat/body_sweep.gd")
const SAFE_MARGIN: float = 0.001
const ENDPOINT_TOLERANCE: float = 0.005
const EPSILON: float = 0.00001
const SWEEP_STEP: float = 0.05
const MAX_DISTANCE: float = 16.0


static func source_description(owner: CharacterBody3D, collision_path: String = "BodyCollision") -> Dictionary:
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion() or owner.collision_mask != 1 or (owner.collision_layer & 1) != 0 or owner.axis_lock_linear_x or owner.axis_lock_linear_y or owner.axis_lock_linear_z or not owner.global_basis.is_equal_approx(Basis.IDENTITY) or not Geometry.finite_vector(owner.global_position):
		return {"error": "Live unrotated source body with scenery-only collision mask required"}
	var collision: CollisionShape3D = owner.get_node_or_null(NodePath(collision_path)) as CollisionShape3D
	if collision == null or collision.get_parent() != owner or collision.disabled or collision.is_queued_for_deletion() or not collision.shape is CapsuleShape3D or not collision.transform.basis.is_equal_approx(Basis.IDENTITY) or absf(collision.position.x) > EPSILON or absf(collision.position.z) > EPSILON:
		return {"error": "Supported source requires one upright centred capsule"}
	var active_shapes: int = 0
	for shape_owner: int in owner.get_shape_owners():
		if not owner.is_shape_owner_disabled(shape_owner):
			active_shapes += owner.shape_owner_get_shape_count(shape_owner)
	if active_shapes != 1:
		return {"error": "Source physical footprint must be its single measured capsule"}
	var shape: CapsuleShape3D = collision.shape as CapsuleShape3D
	var signature := {"collision_path": collision_path, "centre": Codec.vector3(collision.position), "radius": shape.radius, "height": shape.height, "margin": shape.margin, "custom_solver_bias": shape.custom_solver_bias, "layer": owner.collision_layer, "mask": owner.collision_mask, "linear_axis_locks": [owner.axis_lock_linear_x, owner.axis_lock_linear_y, owner.axis_lock_linear_z]}
	if not Codec.value_error(signature).is_empty() or shape.radius <= 0 or shape.height < 2.0 * shape.radius:
		return {"error": "Finite positive source capsule dimensions required"}
	return {"signature": signature, "radius": shape.radius, "height": shape.height, "foot_offset": collision.position.y - shape.height * 0.5, "collision": collision}


static func staged_source_description(owner: CharacterBody3D, state: Dictionary) -> Dictionary:
	## Paused aggregate prevalidation only. Lifecycle flags come from a separately
	## validated actor snapshot; shape/resource/registration/transform come from the
	## retained actual body. This neither enables collision nor licenses movement.
	if not Codec.value_error(state).is_empty() or not Codec.keys_error(state, ["collision_path", "enabled", "layer", "mask"]).is_empty():
		return {"error": "Closed staged source collision state required"}
	if not state["collision_path"] is String or state["collision_path"].is_empty() or state["collision_path"].contains("\n") or state["collision_path"].contains("\r") or not state["enabled"] is bool or not state["enabled"] or not state["layer"] is int or not Codec.is_integer(state["layer"], 0, 4294967295) or (int(state["layer"]) & 1) != 0 or not state["mask"] is int or state["mask"] != 1:
		return {"error": "Staged live capsule requires enabled=true, non-scenery layer and scenery-only mask"}
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion() or not owner.get_tree().paused or owner.axis_lock_linear_x or owner.axis_lock_linear_y or owner.axis_lock_linear_z or owner.global_basis != Basis.IDENTITY or not Geometry.finite_vector(owner.global_position):
		return {"error": "Paused retained unrotated actual source body required"}
	var collision_path: String = state["collision_path"]
	var collision: CollisionShape3D = owner.get_node_or_null(NodePath(collision_path)) as CollisionShape3D
	if collision == null or collision.get_parent() != owner or String(owner.get_path_to(collision)) != collision_path or collision.is_queued_for_deletion() or not collision.shape is CapsuleShape3D or collision.transform.basis != Basis.IDENTITY or absf(collision.position.x) > EPSILON or absf(collision.position.z) > EPSILON:
		return {"error": "Staged source requires its retained upright centred capsule at the exact child path"}
	# Count retained registrations, including disabled owners. Also reject an extra
	# pending collider child which has not acquired a registration yet.
	var collider_children: int = 0
	for child: Node in owner.get_children():
		if child is CollisionShape3D or child is CollisionPolygon3D:
			collider_children += 1
	var shape_owners: PackedInt32Array = owner.get_shape_owners()
	if collider_children != 1 or shape_owners.size() != 1:
		return {"error": "Staged source must retain exactly one registered capsule and no pending colliders"}
	var shape_owner: int = shape_owners[0]
	if owner.shape_owner_get_owner(shape_owner) != collision or owner.shape_owner_get_shape_count(shape_owner) != 1 or owner.shape_owner_get_shape(shape_owner, 0) != collision.shape or owner.shape_owner_get_transform(shape_owner) != collision.transform or owner.is_shape_owner_disabled(shape_owner) != collision.disabled:
		return {"error": "Staged capsule must match its actual registered owner, resource, transform and lifecycle"}
	var shape: CapsuleShape3D = collision.shape as CapsuleShape3D
	var signature := {"collision_path": collision_path, "centre": Codec.vector3(collision.position), "radius": shape.radius, "height": shape.height, "margin": shape.margin, "custom_solver_bias": shape.custom_solver_bias, "layer": state["layer"], "mask": state["mask"], "linear_axis_locks": [owner.axis_lock_linear_x, owner.axis_lock_linear_y, owner.axis_lock_linear_z]}
	if not Codec.value_error(signature).is_empty() or shape.radius <= 0 or shape.height < 2.0 * shape.radius:
		return {"error": "Finite positive retained capsule dimensions required"}
	return {"signature": signature, "radius": shape.radius, "height": shape.height, "foot_offset": collision.position.y - shape.height * 0.5, "collision": collision}


static func plan(owner: CharacterBody3D, motion: Dictionary, floor_regions: Array) -> Dictionary:
	var path: Variant = motion.get("body_collision_path", "BodyCollision")
	if not path is String or path.is_empty() or path.contains("\n") or path.contains("\r"):
		return {"error": "Stable source body_collision_path required"}
	var description: Dictionary = source_description(owner, path)
	if description.has("error"):
		return description
	if not Geometry.finite_vector(owner.velocity) or owner.velocity.length() > EPSILON:
		return {"error": "Source must stop approach/knockback before committing a lunge"}
	var direction: Variant = motion.get("direction")
	if not Geometry.finite_vector(direction) or absf(direction.y) > EPSILON or absf(direction.length() - 1.0) > EPSILON:
		return {"error": "Lunge requires a fixed normalized ground direction"}
	for key: String in ["speed", "distance", "damage_radius"]:
		if not Geometry.finite_number(motion.get(key)) or float(motion[key]) <= 0:
			return {"error": "Finite positive lunge motion required: " + key}
	if float(motion["damage_radius"]) < float(description["radius"]) + ENDPOINT_TOLERANCE:
		return {"error": "Reserved lane must contain actual source footprint plus bounded contact tolerance"}
	if float(motion["distance"]) <= EPSILON or float(motion["distance"]) > MAX_DISTANCE:
		return {"error": "Supported lunge travel must exceed motion epsilon and stay within the bounded 16m sweep"}
	var duration: float = float(motion["distance"]) / float(motion["speed"])
	var intended: Vector3 = direction * float(motion["distance"])
	if not is_finite(duration) or duration <= 0 or not intended.is_finite() or not (direction * float(motion["speed"])).is_finite():
		return {"error": "Lunge motion must remain finite"}
	var collision: CollisionShape3D = description["collision"]
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	query.transform = collision.global_transform
	query.collision_mask = 1
	var excluded: Array[RID] = [owner.get_rid()]
	for floor_region: Variant in floor_regions:
		if not floor_region is Dictionary:
			return {"error": "Actual supported floor bindings required"}
		var floor_collision: CollisionShape3D = floor_region.get("collision") as CollisionShape3D
		if not is_instance_valid(floor_collision) or not floor_collision.is_inside_tree() or floor_collision.is_queued_for_deletion() or not floor_collision.get_parent() is StaticBody3D:
			return {"error": "Actual supported floor bindings required"}
		excluded.append((floor_collision.get_parent() as StaticBody3D).get_rid())
	query.exclude = excluded
	if not owner.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
		return {"error": "Source starts overlapped with scenery"}
	var sweep: Dictionary = _sweep(owner, owner.global_transform, intended, floor_regions)
	if sweep.has("error"):
		return sweep
	var travel: Vector3 = sweep["travel"]
	if not travel.is_finite() or absf(travel.y) > EPSILON or travel.dot(direction) < -EPSILON or travel.dot(direction) > float(motion["distance"]) + EPSILON or (travel - direction * travel.dot(direction)).length() > EPSILON:
		return {"error": "Source collision cannot be represented by a straight shortened route"}
	var start: Vector3 = owner.global_position
	var endpoint: Vector3 = start + travel
	return {"kind": "lunge", "start": start, "planned_endpoint": endpoint, "current_position": start, "current_velocity": Vector3.ZERO, "direction": direction, "speed": float(motion["speed"]), "distance": float(motion["distance"]), "duration_s": duration, "damage_radius": float(motion["damage_radius"]), "body_signature": description["signature"], "body_collision_path": path, "collision_shortened": travel.length() < intended.length() - EPSILON, "actual_collided": false, "finished": false, "geometry": Geometry.lane(start, endpoint, float(motion["damage_radius"])), "source_radius": description["radius"], "foot_offset": description["foot_offset"]}


static func advance(owner: CharacterBody3D, motion: Dictionary, elapsed_s: float, floor_regions: Array = []) -> Dictionary:
	## Mutates only this real source, never a proxy or the player. All geometry,
	## floor and timing acceptance belongs to the scheduler before this call.
	var description: Dictionary = source_description(owner, motion["body_collision_path"])
	if description.has("error") or not Codec.same_values(description.get("signature", {}), motion["body_signature"]) or owner.global_position.distance_to(motion["current_position"]) > EPSILON or owner.velocity.distance_to(motion["current_velocity"]) > EPSILON:
		return {"error": "Committed lunge source pose/capsule changed"}
	var result: Dictionary = motion.duplicate(true)
	if motion["finished"]:
		owner.velocity = Vector3.ZERO
		result["current_velocity"] = Vector3.ZERO
		return result
	if not is_finite(elapsed_s) or elapsed_s < 0:
		return {"error": "Finite elapsed lunge time required"}
	var progressed: float = minf(float(motion["distance"]), float(motion["speed"]) * elapsed_s)
	var desired: Vector3 = motion["start"] + motion["direction"] * progressed
	var step: Vector3 = desired - owner.global_position
	if step.dot(motion["direction"]) < -EPSILON:
		return {"error": "Lunge clock cannot move backward"}
	if step.length() <= EPSILON:
		if progressed >= float(motion["distance"]) - EPSILON:
			result["finished"] = true
			owner.velocity = Vector3.ZERO
			result["current_velocity"] = Vector3.ZERO
		return result
	# Check before real movement so a removed/changed wall cannot let the source
	# escape its committed lane. Per-step and full-sweep contact margins differ
	# numerically; tolerance is smaller than the response proof's 0.01m skin.
	var sweep: Dictionary = _sweep(owner, owner.global_transform, step, floor_regions)
	if sweep.has("error"):
		return sweep
	var will_collide: bool = sweep["collided"]
	var predicted: Vector3 = owner.global_position + sweep["travel"]
	var maximum: float = (motion["planned_endpoint"] as Vector3).distance_to(motion["start"])
	if (predicted - motion["start"]).dot(motion["direction"]) > maximum + ENDPOINT_TOLERANCE or (will_collide and predicted.distance_to(motion["planned_endpoint"]) > ENDPOINT_TOLERANCE):
		owner.velocity = Vector3.ZERO
		return {"error": "Collision-shortened lunge endpoint changed before movement"}
	owner.velocity = motion["direction"] * float(motion["speed"])
	var remaining: Vector3 = step
	var contact: KinematicCollision3D = null
	while remaining.length() > EPSILON:
		var substep: Vector3 = remaining.normalized() * minf(SWEEP_STEP, remaining.length())
		contact = owner.move_and_collide(substep, false, SAFE_MARGIN, false, 1)
		var travelled: Vector3 = owner.global_position - motion["start"]
		var progress: float = travelled.dot(motion["direction"])
		if not travelled.is_finite() or absf(travelled.y) > EPSILON or (travelled - motion["direction"] * progress).length() > EPSILON or progress > maximum + ENDPOINT_TOLERANCE:
			owner.velocity = Vector3.ZERO
			return {"error": "Real source left the supported straight committed lane"}
		if contact != null:
			break
		remaining -= substep
	result["current_position"] = owner.global_position
	result["actual_collided"] = contact != null
	result["finished"] = contact != null or progressed >= float(motion["distance"]) - EPSILON
	if result["finished"]:
		owner.velocity = Vector3.ZERO
		if owner.global_position.distance_to(motion["planned_endpoint"]) > ENDPOINT_TOLERANCE:
			return {"error": "Actual lunge landing differs from its committed opening"}
	result["current_velocity"] = owner.velocity
	return result


static func _sweep(owner: CharacterBody3D, from: Transform3D, motion: Vector3, floor_regions: Array) -> Dictionary:
	# Pure actual-body query matches installed move_and_collide cancel_sliding,
	# including separately classified tiny resting floor recovery. Actual floor
	# collision and source pose remain untouched, and deep/side recovery rejects.
	return BodySweep.sweep(owner, from, motion, floor_regions)
