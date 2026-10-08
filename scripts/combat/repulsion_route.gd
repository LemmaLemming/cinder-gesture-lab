class_name CinderRepulsionRoute
extends RefCounted
## Measured-body straight retreat only. This neither applies damage nor owns an
## enemy controller/attack. The owner MUST cancel its attack and suspend other
## movement before acquire, then release the lease on interruption/cleanup.
## Preflight is pure with respect to the actor/world, including its velocity.
## Only fixed static scenery and supported box floors are accepted. A box's
## floor footprint uses its enclosing disc: safe but conservative near corners
## and adjacent floor seams. No field avoidance, no-repeat or fairness proof.

const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const API_REVISION: String = "repulsion-route-1"
const EPSILON: float = 0.00001
const SAFE_MARGIN: float = 0.001
const ENDPOINT_TOLERANCE: float = 0.005
const FLOOR_SKIN: float = 0.01
const FEET_TOLERANCE: float = 0.015
const SWEEP_STEP: float = 0.05
const MAX_DISTANCE: float = 16.0
const MAX_SPEED: float = 32.0
const MAX_DURATION_S: float = 16.0

var last_error: String = ""
var _route: Dictionary = {}
var _owner: WeakRef
var _world_root: WeakRef
var _floors: Dictionary = {}
var _world_signature: Dictionary = {}
var _floor_signature: Array = []
var _leased: bool = false
var _busy: bool = false


## motion={direction:normalized planar Vector3,speed:positive,distance:positive,
## body_collision_path?:String}. bindings={world_root:Node3D,
## floors:{stable_id:{collision:CollisionShape3D,safe_rect:world X/Z Rect2}}}.
## A supported moving source is allowed; grounding is measured from its actual
## lower face, continuous authored support and registered floor rays, rather
## than inferred from a private controller flag or a stale is_on_floor value.
func plan(owner: CharacterBody3D, motion: Dictionary, bindings: Dictionary) -> Dictionary:
	last_error = ""
	if _busy or _leased:
		return _error("Release the existing motion lease before planning another route")
	_route.clear()
	var path: Variant = motion.get("body_collision_path", "BodyCollision")
	if not path is String or not _stable_path(path):
		return _error("Stable body collision path required")
	var description: Dictionary = _body_description(owner, path)
	if description.has("error"):
		return _error(description.error)
	var direction: Variant = motion.get("direction")
	if not Geometry.finite_vector(direction) or absf(direction.y) > EPSILON or absf(direction.length() - 1.0) > EPSILON:
		return _error("Retreat requires a normalized planar direction")
	if not Geometry.finite_number(motion.get("speed")) or not Geometry.finite_number(motion.get("distance")):
		return _error("Finite positive retreat speed and distance required")
	var speed: float = float(motion.speed)
	var distance: float = float(motion.distance)
	if speed <= 0.0 or speed > MAX_SPEED or distance <= EPSILON or distance > MAX_DISTANCE or distance / speed > MAX_DURATION_S:
		return _error("Retreat exceeds supported speed/distance/duration bounds")
	var root: Node3D = bindings.get("world_root") as Node3D
	var world: Dictionary = _collision_signature(owner, root)
	if world.has("error"):
		return _error(world.error)
	var floor_plan: Dictionary = _floor_plan(owner, bindings.get("floors"), root, description)
	if floor_plan.has("error"):
		return _error(floor_plan.error)
	var regions: Array = floor_plan.regions
	if not _supported(owner, owner.global_position, owner.global_position, regions, float(description.support_radius), float(description.foot_offset)):
		return _error("Actual measured source footprint lacks registered safe floor support")
	if _overlapped(owner, description.collision, regions):
		return _error("Source starts overlapped with scenery")
	var sweep: Dictionary = _sweep(owner, owner.global_transform, direction * distance)
	if sweep.has("error"):
		return _error(sweep.error)
	var endpoint: Vector3 = owner.global_position + sweep.travel
	if not _supported(owner, owner.global_position, endpoint, regions, float(description.support_radius) + ENDPOINT_TOLERANCE, float(description.foot_offset)):
		return _error("Collision-shortened route crosses unsupported floor or a hole")
	_owner = weakref(owner)
	_world_root = weakref(root)
	_floors.clear()
	for id: String in bindings.floors:
		_floors[id] = {"collision": weakref(bindings.floors[id].collision), "safe_rect": bindings.floors[id].safe_rect}
	_world_signature = world.signature.duplicate(true)
	_floor_signature = floor_plan.signature.duplicate(true)
	_route = {"api_revision": API_REVISION, "start": owner.global_position, "planned_endpoint": endpoint, "current_position": owner.global_position, "current_velocity": owner.velocity, "approach_velocity": owner.velocity, "body_collision_path": path, "body_signature": description.signature.duplicate(true), "support_radius": description.support_radius, "foot_offset": description.foot_offset, "direction": direction, "speed": speed, "distance": distance, "duration_s": distance / speed, "elapsed_s": 0.0, "collision_shortened": sweep.collided, "actual_collided": false, "finished": false}
	return state()


## External successful attack-cancellation/controller lease barrier precedes
## this call. Revalidation completes before velocity is stopped. No HP, attack
## cooldown, cue, controller flag or event is inspected/emitted/mutated here.
func acquire(owner: CharacterBody3D) -> bool:
	last_error = ""
	if _busy or _leased or _route.is_empty():
		last_error = "Acquire one prepared route outside an existing lease"
		return false
	var error: String = _guard_error(owner, false)
	if not error.is_empty():
		last_error = error
		return false
	var sweep: Dictionary = _sweep(owner, owner.global_transform, _route.direction * float(_route.distance))
	if sweep.has("error") or (owner.global_position + sweep.get("travel", Vector3.ZERO)).distance_to(_route.planned_endpoint) > ENDPOINT_TOLERANCE:
		last_error = String(sweep.get("error", "Prepared shortening endpoint changed before lease acquisition"))
		return false
	owner.velocity = Vector3.ZERO
	_route.current_velocity = Vector3.ZERO
	_leased = true
	return true


## elapsed_s is absolute simulation time since acquire, monotonically advanced
## by the owning controller. Paused trees reject advance: no wall-clock travel.
## On rejection the actor is unchanged; the owner must release/cancel this
## route rather than allow another controller to continue its leased velocity.
func advance(owner: CharacterBody3D, elapsed_s: float) -> Dictionary:
	last_error = ""
	if _busy or not _leased or _route.is_empty():
		return _error("Advance requires the acquired actual-body lease")
	if not is_finite(elapsed_s) or elapsed_s < float(_route.elapsed_s) or elapsed_s > MAX_DURATION_S:
		return _error("Retreat simulation time must be finite, monotonic and bounded")
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.get_tree().paused:
		return _error("Advance requires the live unpaused simulation boundary")
	var error: String = _guard_error(owner, true)
	if not error.is_empty():
		return _error(error)
	if _route.finished:
		_route.elapsed_s = elapsed_s
		return state()
	var progressed: float = minf(float(_route.distance), float(_route.speed) * elapsed_s)
	var step: Vector3 = _route.start + _route.direction * progressed - owner.global_position
	if step.dot(_route.direction) < -EPSILON:
		return _error("Retreat cannot move backward from its actual leased pose")
	if step.length() <= EPSILON:
		_route.elapsed_s = elapsed_s
		return state()
	var sweep: Dictionary = _sweep(owner, owner.global_transform, step)
	if sweep.has("error"):
		return _error(sweep.error)
	var predicted: Vector3 = owner.global_position + sweep.travel
	var maximum: float = (_route.planned_endpoint as Vector3).distance_to(_route.start)
	if (predicted - _route.start).dot(_route.direction) > maximum + ENDPOINT_TOLERANCE or (sweep.collided and predicted.distance_to(_route.planned_endpoint) > ENDPOINT_TOLERANCE):
		return _error("Committed wall contact endpoint changed before actual movement")
	_busy = true
	owner.velocity = _route.direction * float(_route.speed)
	var remaining: Vector3 = step
	var contact: KinematicCollision3D = null
	while remaining.length() > EPSILON:
		var substep: Vector3 = remaining.normalized() * minf(SWEEP_STEP, remaining.length())
		contact = owner.move_and_collide(substep, false, SAFE_MARGIN, true, 1)
		var travelled: Vector3 = owner.global_position - _route.start
		var along: float = travelled.dot(_route.direction)
		if not travelled.is_finite() or absf(travelled.y) > EPSILON or (travelled - _route.direction * along).length() > EPSILON or along > maximum + ENDPOINT_TOLERANCE:
			owner.velocity = Vector3.ZERO
			_busy = false
			# A synchronous world mutation during engine movement cannot be
			# rolled back. This branch disarms the lease; it never teleports back.
			_leased = false
			return _error("Actual retreat left the supported straight route; lease disarmed")
		if contact != null:
			break
		remaining -= substep
	_route.current_position = owner.global_position
	_route.actual_collided = contact != null
	_route.finished = contact != null or progressed >= float(_route.distance) - EPSILON
	_route.elapsed_s = elapsed_s
	if _route.finished:
		owner.velocity = Vector3.ZERO
	_route.current_velocity = owner.velocity
	_busy = false
	if _route.finished and owner.global_position.distance_to(_route.planned_endpoint) > ENDPOINT_TOLERANCE:
		_leased = false
		return _error("Actual retreat endpoint differs from committed supported landing")
	return state()


## Stop only the velocity still owned by this route. An external impulse/pose
## change belongs to its caller and is never overwritten by cleanup.
func release(owner: CharacterBody3D) -> bool:
	last_error = ""
	if _busy or not _leased or not is_instance_valid(owner) or _owner == null or _owner.get_ref() != owner:
		last_error = "Release requires this actual source lease"
		return false
	_leased = false
	var description: Dictionary = _body_description(owner, _route.body_collision_path)
	if description.has("error") or not Codec.same_values(description.get("signature", {}), _route.body_signature) or owner.global_position.distance_to(_route.current_position) > EPSILON or owner.velocity.distance_to(_route.current_velocity) > EPSILON:
		last_error = "External pose/velocity owns this source now; cleanup did not overwrite it"
		return false
	owner.velocity = Vector3.ZERO
	_route.current_velocity = Vector3.ZERO
	return true


func state() -> Dictionary:
	var result: Dictionary = _route.duplicate(true)
	if not result.is_empty():
		result.leased = _leased
	return result


func _guard_error(owner: CharacterBody3D, check_velocity: bool) -> String:
	if _owner == null or _owner.get_ref() != owner:
		return "Prepared/leased source identity changed"
	var description: Dictionary = _body_description(owner, _route.body_collision_path)
	if description.has("error") or not Codec.same_values(description.get("signature", {}), _route.body_signature):
		return "Prepared/leased actual collision body changed"
	if owner.global_position.distance_to(_route.current_position) > EPSILON or (check_velocity and owner.velocity.distance_to(_route.current_velocity) > EPSILON):
		return "Prepared/leased source pose or velocity changed"
	var root: Node3D = _world_root.get_ref() as Node3D if _world_root != null else null
	var world: Dictionary = _collision_signature(owner, root)
	if world.has("error") or not Codec.same_values(world.get("signature", {}), _world_signature):
		return "Prepared static collision world changed"
	var floors: Dictionary = {}
	for id: String in _floors:
		floors[id] = {"collision": (_floors[id].collision as WeakRef).get_ref(), "safe_rect": _floors[id].safe_rect}
	var floor_plan: Dictionary = _floor_plan(owner, floors, root, description)
	if floor_plan.has("error") or not Codec.same_values(floor_plan.get("signature", []), _floor_signature):
		return "Prepared supported floor bindings changed"
	if not _supported(owner, owner.global_position, _route.planned_endpoint, floor_plan.regions, float(_route.support_radius) + ENDPOINT_TOLERANCE, float(_route.foot_offset)):
		return "Remaining measured-body route lost continuous registered support"
	return ""


static func _body_description(owner: CharacterBody3D, path: String) -> Dictionary:
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion() or owner.collision_mask != 1 or (owner.collision_layer & 1) != 0 or not owner.global_basis.is_equal_approx(Basis.IDENTITY) or not Geometry.finite_vector(owner.global_position) or not Geometry.finite_vector(owner.velocity) or absf(owner.velocity.y) > EPSILON:
		return {"error": "Live unscaled upright source with scenery-only mask and grounded planar velocity required"}
	if owner.axis_lock_linear_x or owner.axis_lock_linear_y or owner.axis_lock_linear_z or owner.axis_lock_angular_x or owner.axis_lock_angular_y or owner.axis_lock_angular_z or not owner.get_collision_exceptions().is_empty() or owner.get_platform_velocity().length() > EPSILON or owner.get_platform_angular_velocity().length() > EPSILON:
		return {"error": "Axis locks, collision exceptions and moving platforms are unsupported"}
	var collision: CollisionShape3D = owner.get_node_or_null(NodePath(path)) as CollisionShape3D
	if not is_instance_valid(collision) or collision.get_parent() != owner or collision.disabled or collision.is_queued_for_deletion() or not collision.transform.basis.is_equal_approx(Basis.IDENTITY) or absf(collision.position.x) > EPSILON or absf(collision.position.z) > EPSILON or (not collision.shape is BoxShape3D and not collision.shape is CapsuleShape3D):
		return {"error": "One actual centred upright BOX or CAPSULE collision required"}
	var count: int = 0
	for shape_owner: int in owner.get_shape_owners():
		if not owner.is_shape_owner_disabled(shape_owner):
			count += owner.shape_owner_get_shape_count(shape_owner)
	if count != 1:
		return {"error": "Source must retain exactly one measured collision shape"}
	var data: Dictionary = _shape_data(collision.shape)
	var radius: float
	var height: float
	if collision.shape is BoxShape3D:
		var size: Vector3 = (collision.shape as BoxShape3D).size
		if not size.is_finite() or minf(size.x, minf(size.y, size.z)) <= EPSILON:
			return {"error": "Finite positive source box dimensions required"}
		radius = Vector2(size.x, size.z).length() * 0.5
		height = size.y
	else:
		var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D
		if not is_finite(capsule.radius) or not is_finite(capsule.height) or capsule.radius <= EPSILON or capsule.height < 2.0 * capsule.radius:
			return {"error": "Finite positive source capsule dimensions required"}
		radius = capsule.radius
		height = capsule.height
	var signature: Dictionary = {"path": path, "centre": Codec.vector3(collision.position), "shape": data, "layer": owner.collision_layer, "mask": owner.collision_mask, "priority": owner.collision_priority}
	var error: String = Codec.value_error(signature)
	if not error.is_empty():
		return {"error": "Source collision description must remain finite: " + error}
	return {"signature": signature, "collision": collision, "support_radius": radius + FLOOR_SKIN, "foot_offset": collision.position.y - height * 0.5}


static func _floor_plan(owner: CharacterBody3D, floors: Variant, root: Node3D, description: Dictionary) -> Dictionary:
	if not floors is Dictionary or floors.is_empty() or floors.size() > 32:
		return {"error": "One to 32 stable authored floor bindings required"}
	var regions: Array = []
	var signatures: Array = []
	var ids: Array = floors.keys()
	for id: Variant in ids:
		if not id is String:
			return {"error": "Floor IDs must be stable authored strings"}
	ids.sort()
	var used: Dictionary = {}
	var height: float = INF
	for id: Variant in ids:
		if not id is String or not _stable_path(id) or not floors[id] is Dictionary or not floors[id].get("safe_rect") is Rect2:
			return {"error": "Stable floor IDs and finite world X/Z safe rectangles required"}
		var collision: CollisionShape3D = floors[id].get("collision") as CollisionShape3D
		if not is_instance_valid(collision) or not collision.is_inside_tree() or collision.is_queued_for_deletion() or collision.disabled or not collision.shape is BoxShape3D or not collision.global_basis.is_equal_approx(Basis.IDENTITY) or not collision.get_parent() is StaticBody3D or not _under(collision, root) or used.has(collision.get_instance_id()):
			return {"error": "Distinct live unscaled upright static floor box bindings required"}
		var body: StaticBody3D = collision.get_parent() as StaticBody3D
		if body is AnimatableBody3D or body.get_world_3d() != owner.get_world_3d() or (body.collision_layer & 1) == 0 or body.constant_linear_velocity != Vector3.ZERO or body.constant_angular_velocity != Vector3.ZERO:
			return {"error": "Supported floors cannot move or omit scenery collision"}
		var count: int = 0
		for shape_owner: int in body.get_shape_owners():
			if not body.is_shape_owner_disabled(shape_owner):
				count += body.shape_owner_get_shape_count(shape_owner)
		if count != 1:
			return {"error": "Supported floor must own exactly one enabled box"}
		var size: Vector3 = (collision.shape as BoxShape3D).size
		var rect: Rect2 = floors[id].safe_rect
		var physical := Rect2(Geometry.planar(collision.global_position) - Vector2(size.x, size.z) * 0.5, Vector2(size.x, size.z))
		var top: float = collision.global_position.y + size.y * 0.5
		if not size.is_finite() or minf(size.x, minf(size.y, size.z)) <= EPSILON or not collision.global_position.is_finite() or not rect.position.is_finite() or not rect.size.is_finite() or rect.size.x <= 2.0 * float(description.support_radius) or rect.size.y <= 2.0 * float(description.support_radius) or not physical.encloses(rect) or absf(owner.global_position.y + float(description.foot_offset) - top) > FEET_TOLERANCE or (is_finite(height) and absf(top - height) > EPSILON):
			return {"error": "Authored floor rectangles must fit solid boxes at the measured source feet height"}
		height = top
		used[collision.get_instance_id()] = true
		regions.append({"collision": collision, "safe_rect": rect, "top": top})
		signatures.append({"floor_id": id, "path": String(root.get_path_to(collision)), "transform": _transform(collision.global_transform), "shape": _shape_data(collision.shape), "layer": body.collision_layer, "mask": body.collision_mask, "safe_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]})
	return {"regions": regions, "signature": signatures}


static func _supported(owner: CharacterBody3D, start: Vector3, finish: Vector3, regions: Array, radius: float, foot_offset: float) -> bool:
	if absf(start.y - finish.y) > EPSILON:
		return false
	var a: Vector2 = Geometry.planar(start)
	var b: Vector2 = Geometry.planar(finish)
	var intervals: Array[Vector2] = []
	for region: Dictionary in regions:
		var rect: Rect2 = (region.safe_rect as Rect2).grow(-radius)
		if rect.size.x <= 0 or rect.size.y <= 0:
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
	# Actual physics registration checks supplement analytic full-route coverage;
	# rays alone cannot prove that the region between the endpoints has no hole.
	for point: Vector3 in [start, finish]:
		var foot: Vector3 = point + Vector3.UP * foot_offset
		var query := PhysicsRayQueryParameters3D.create(foot + Vector3.UP * 0.1, foot - Vector3.UP * 0.1, 1)
		query.exclude = [owner.get_rid()]
		var hit: Dictionary = owner.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			return false
		var matched: bool = false
		for region: Dictionary in regions:
			if hit.rid == (region.collision.get_parent() as StaticBody3D).get_rid() and absf(float(hit.position.y) - float(region.top)) <= EPSILON:
				matched = true
		if not matched:
			return false
	return true


static func _overlapped(owner: CharacterBody3D, collision: CollisionShape3D, regions: Array) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	query.transform = collision.global_transform
	query.collision_mask = 1
	query.collide_with_areas = false
	var excluded: Array[RID] = [owner.get_rid()]
	for region: Dictionary in regions:
		excluded.append(region.collision.get_parent().get_rid())
	query.exclude = excluded
	return not owner.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


static func _sweep(owner: CharacterBody3D, from: Transform3D, motion: Vector3) -> Dictionary:
	if not motion.is_finite() or motion.length() > MAX_DISTANCE + EPSILON:
		return {"error": "Retreat sweep exceeds bounded finite travel"}
	var direction: Vector3 = motion.normalized()
	var remaining: float = motion.length()
	var travel := Vector3.ZERO
	while remaining > EPSILON:
		var length: float = minf(SWEEP_STEP, remaining)
		var step: Vector3 = direction * length
		var check := KinematicCollision3D.new()
		var blocked: bool = owner.test_move(from, step, check, SAFE_MARGIN, true, 1)
		var moved: Vector3 = check.get_travel() if blocked else step
		if not moved.is_finite() or absf(moved.y) > EPSILON or moved.dot(direction) < -EPSILON or moved.dot(direction) > length + EPSILON or (moved - direction * moved.dot(direction)).length() > EPSILON:
			return {"error": "Depenetration/nonplanar physics recovery cannot form a straight retreat"}
		travel += moved
		if blocked:
			return {"travel": travel, "collided": true}
		from.origin += moved
		remaining -= length
	return {"travel": travel, "collided": false}


static func _collision_signature(owner: CharacterBody3D, root: Node3D) -> Dictionary:
	if not is_instance_valid(root) or not root.is_inside_tree() or root.is_queued_for_deletion() or root.get_world_3d() != owner.get_world_3d() or not _under(owner, root):
		return {"error": "Actual same-world root containing source and all scenery required"}
	var pending: Array[Node] = [owner.get_tree().root]
	var colliders: Array = []
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		pending.append_array(node.get_children())
		if not node is Node3D or (node as Node3D).get_world_3d() != owner.get_world_3d():
			continue
		if node is GridMap or (node is CSGShape3D and (node as CSGShape3D).use_collision):
			return {"error": "Generated scenery collision has no supported stable signature"}
		if not node is PhysicsBody3D or ((node as PhysicsBody3D).collision_layer & 1) == 0:
			continue
		if not node is StaticBody3D or node is AnimatableBody3D or not _under(node, root):
			return {"error": "Every scenery blocker must be a fixed static body under world_root"}
		var body: StaticBody3D = node as StaticBody3D
		if body.is_queued_for_deletion() or body.constant_linear_velocity != Vector3.ZERO or body.constant_angular_velocity != Vector3.ZERO:
			return {"error": "Moving/removed static scenery is unsupported"}
		var path: String = String(root.get_path_to(body))
		if not _stable_path(path):
			return {"error": "Scenery requires stable authored collider paths"}
		var shapes: Array = []
		for id: int in body.get_shape_owners():
			if body.is_shape_owner_disabled(id):
				continue
			var shape_owner: Object = body.shape_owner_get_owner(id)
			if not shape_owner is Node or not body.is_ancestor_of(shape_owner as Node):
				return {"error": "Scenery shape needs a stable authored node owner"}
			var shape_path: String = String(body.get_path_to(shape_owner as Node))
			if not _stable_path(shape_path):
				return {"error": "Scenery shape requires stable authored path"}
			for index: int in range(body.shape_owner_get_shape_count(id)):
				var data: Dictionary = _shape_data(body.shape_owner_get_shape(id, index))
				if data.is_empty():
					return {"error": "Unsupported immutable scenery shape"}
				shapes.append({"path": shape_path, "index": index, "transform": _transform(body.shape_owner_get_transform(id)), "data": data})
		shapes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.path < b.path or (a.path == b.path and a.index < b.index))
		colliders.append({"path": path, "transform": _transform(body.global_transform), "layer": body.collision_layer, "mask": body.collision_mask, "priority": body.collision_priority, "shapes": shapes})
		if colliders.size() > 256:
			return {"error": "Supported world exceeds 256 scenery colliders"}
	colliders.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.path < b.path)
	var signature: Dictionary = {"engine": ProjectSettings.get_setting("physics/3d/physics_engine", "DEFAULT"), "tick_rate": Engine.physics_ticks_per_second, "colliders": colliders}
	var error: String = Codec.value_error(signature)
	return {"signature": signature} if error.is_empty() else {"error": error}


static func _shape_data(shape: Shape3D) -> Dictionary:
	var data: Dictionary = {"type": shape.get_class(), "margin": shape.margin, "custom_solver_bias": shape.custom_solver_bias}
	if shape is BoxShape3D:
		data["size"] = Codec.vector3((shape as BoxShape3D).size)
	elif shape is CapsuleShape3D or shape is CylinderShape3D:
		data["radius"] = (shape as CapsuleShape3D).radius if shape is CapsuleShape3D else (shape as CylinderShape3D).radius
		data["height"] = (shape as CapsuleShape3D).height if shape is CapsuleShape3D else (shape as CylinderShape3D).height
	elif shape is SphereShape3D:
		data["radius"] = (shape as SphereShape3D).radius
	elif shape is ConvexPolygonShape3D or shape is ConcavePolygonShape3D:
		var points: PackedVector3Array = (shape as ConvexPolygonShape3D).points if shape is ConvexPolygonShape3D else (shape as ConcavePolygonShape3D).get_faces()
		var encoded: Array = []
		for point: Vector3 in points:
			encoded.append(Codec.vector3(point))
		data["points"] = encoded
		if shape is ConcavePolygonShape3D:
			data["backface_collision"] = (shape as ConcavePolygonShape3D).backface_collision
	else:
		return {}
	return data


static func _transform(value: Transform3D) -> Array:
	return [Codec.vector3(value.basis.x), Codec.vector3(value.basis.y), Codec.vector3(value.basis.z), Codec.vector3(value.origin)]


static func _under(node: Node, root: Node) -> bool:
	return is_instance_valid(root) and (node == root or root.is_ancestor_of(node))


static func _stable_path(value: String) -> bool:
	return not value.is_empty() and not value.contains("@") and not value.contains("\n") and not value.contains("\r")


func _error(message: String) -> Dictionary:
	last_error = message
	return {"error": message}
