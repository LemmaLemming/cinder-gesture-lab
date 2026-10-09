class_name CinderBodySweep
extends RefCounted
## Pure, measured scenery motion for one upright capsule/box on static box floors.
## Matches Godot 4.7.2 ed1daf0bf PhysicsBody3D's default cancel_sliding wrapper.
## This is a collision/support query, not a timed escape or threat fairness proof.

const API_REVISION: String = "body-sweep-1"
const ENGINE_BUILD: String = "4.7.2.stable.official.ed1daf0bf"
const SAFE_MARGIN: float = 0.001
const ENGINE_PRECISION: float = 0.001
const EPSILON: float = 0.00001
const SWEEP_STEP: float = 0.05
const MAX_DISTANCE: float = 16.0
const MAX_COORDINATE: float = 512.0
const STANDING_HEIGHT: float = 0.015
const MAX_FLOOR_RECOVERY: float = SAFE_MARGIN + ENGINE_PRECISION


static func source_description(body: CharacterBody3D) -> Dictionary:
	if not is_instance_valid(body) or not body.is_inside_tree() or body.is_queued_for_deletion() or body.collision_mask != 1 or (body.collision_layer & 1) != 0 or body.axis_lock_linear_x or body.axis_lock_linear_y or body.axis_lock_linear_z or not body.global_basis.is_equal_approx(Basis.IDENTITY) or not body.global_position.is_finite() or not body.velocity.is_finite():
		return _error("Live upright scenery-only body with unlocked finite motion required")
	if not body.get_collision_exceptions().is_empty() or not body.get_platform_velocity().is_finite() or not body.get_platform_angular_velocity().is_finite() or body.get_platform_velocity().length() > EPSILON or body.get_platform_angular_velocity().length() > EPSILON:
		return _error("Collision exceptions and moving-platform carry are unsupported")
	var count: int = 0
	var collision: CollisionShape3D = null
	for shape_owner: int in body.get_shape_owners():
		if not body.is_shape_owner_disabled(shape_owner):
			count += body.shape_owner_get_shape_count(shape_owner)
			collision = body.shape_owner_get_owner(shape_owner) as CollisionShape3D
	if count != 1 or not is_instance_valid(collision) or collision.get_parent() != body or collision.disabled or not collision.transform.basis.is_equal_approx(Basis.IDENTITY) or not collision.position.is_finite() or absf(collision.position.x) > EPSILON or absf(collision.position.z) > EPSILON:
		return _error("One centred upright capsule or box collision shape required")
	var half: Vector2
	var height: float
	if collision.shape is CapsuleShape3D:
		var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D
		if not is_finite(capsule.radius) or not is_finite(capsule.height) or capsule.radius <= 0.0 or capsule.height < 2.0 * capsule.radius:
			return _error("Finite positive measured capsule required")
		half = Vector2.ONE * capsule.radius
		height = capsule.height
	elif collision.shape is BoxShape3D:
		var box: BoxShape3D = collision.shape as BoxShape3D
		if not box.size.is_finite() or box.size.x <= 0.0 or box.size.y <= 0.0 or box.size.z <= 0.0:
			return _error("Finite positive measured box required")
		half = Vector2(box.size.x, box.size.z) * 0.5
		height = box.size.y
	else:
		return _error("Only actual capsule and box bodies are supported")
	return {"collision": collision, "foot_offset": collision.position.y - height * 0.5, "footprint_half": half, "height": height, "api_revision": API_REVISION}


static func step(body: CharacterBody3D, from: Transform3D, motion: Vector3, floor_regions: Array) -> Dictionary:
	if not motion.is_finite() or motion.length() > SWEEP_STEP + EPSILON or absf(motion.y) > EPSILON:
		return _error("A finite planar virtual step of at most 0.05m is required")
	var context: Dictionary = _context(body, from, floor_regions)
	if context.has("error"):
		return context
	return _step(body, from, motion, context)


static func sweep(body: CharacterBody3D, from: Transform3D, motion: Vector3, floor_regions: Array) -> Dictionary:
	if not motion.is_finite() or motion.length() > MAX_DISTANCE or absf(motion.y) > EPSILON:
		return _error("A finite planar sweep of at most 16m is required")
	var context: Dictionary = _context(body, from, floor_regions)
	if context.has("error"):
		return context
	var start: Vector3 = from.origin
	var distance: float = motion.length()
	var records: Array[Dictionary] = []
	if distance <= EPSILON:
		return _step(body, from, motion, context)
	# Anchor every requested point to the original line. Repeatedly adding a
	# .05m Vector3 at z31 accumulates native float32 origin rounding into a
	# fictitious bend/shortening even when every real body query is clear.
	var count: int = maxi(1, ceili((distance - EPSILON) / SWEEP_STEP))
	for index: int in range(count):
		var target: Vector3 = anchored_position(start, motion, float(index + 1) / float(count))
		var result: Dictionary = _step(body, from, target - from.origin, context)
		if result.has("error"):
			result["step_index"] = records.size()
			return result
		records.append(result)
		from.origin = result.end
		if result.collided:
			return {"travel": from.origin - start, "end": from.origin, "collided": true, "collider_rid": result.collider_rid, "normal": result.normal, "steps": records, "api_revision": API_REVISION}
	return {"travel": from.origin - start, "end": from.origin, "collided": false, "collider_rid": RID(), "normal": Vector3.ZERO, "steps": records, "api_revision": API_REVISION}


static func anchored_position(origin: Vector3, displacement: Vector3, scale: float) -> Vector3:
	## GDScript scalars are binary64; construct the native Vector3 only once.
	## Callers still validate finite/bounded inputs and query the actual collider.
	return Vector3(float(origin.x) + float(displacement.x) * scale, float(origin.y) + float(displacement.y) * scale, float(origin.z) + float(displacement.z) * scale)


static func position_rounding_bound(start: Vector3, finish: Vector3) -> float:
	## Only represented world-position/route arithmetic, never copied identities,
	## clocks, body dimensions, floor penetration or physical contact allowance.
	## Two endpoints plus local vector arithmetic: <2sqrt(3) world float32 ULPs
	## and the existing local epsilon. At the supported512m limit this is <.000222m,
	## smaller than the actual .001m query margin and .005m endpoint guard.
	if not _bounded(start) or not _bounded(finish):
		return EPSILON # Invalid coordinates must never grant an infinite margin.
	var magnitude: float = maxf(absf(start.x), maxf(absf(start.y), absf(start.z)))
	magnitude = maxf(magnitude, maxf(absf(finish.x), maxf(absf(finish.y), absf(finish.z))))
	if magnitude == 0.0:
		return EPSILON
	var exponent: float = floor(log(magnitude) / log(2.0))
	return EPSILON + 2.0 * sqrt(3.0) * pow(2.0, exponent - 23.0)


static func _context(body: CharacterBody3D, from: Transform3D, floor_regions: Array) -> Dictionary:
	var description: Dictionary = source_description(body)
	if description.has("error"):
		return description
	if not from.basis.is_equal_approx(Basis.IDENTITY) or not _bounded(from.origin) or floor_regions.is_empty() or floor_regions.size() > 32:
		return _error("Bounded upright virtual transform and actual floor bindings required")
	var top: float = INF
	var floors: Array[Dictionary] = []
	var floor_rids: Array[RID] = []
	for value: Variant in floor_regions:
		if not value is Dictionary or not value.get("safe_rect") is Rect2:
			return _error("Actual floor collision and X/Z safe rectangle required")
		var collision: CollisionShape3D = value.get("collision") as CollisionShape3D
		if not is_instance_valid(collision) or not collision.is_inside_tree() or collision.is_queued_for_deletion() or collision.disabled or not collision.shape is BoxShape3D or not collision.get_parent() is StaticBody3D or not collision.global_basis.is_equal_approx(Basis.IDENTITY):
			return _error("Floor must be a live solid upright static box")
		var floor_body: StaticBody3D = collision.get_parent() as StaticBody3D
		if floor_body.is_queued_for_deletion() or floor_body.get_world_3d() != body.get_world_3d() or (floor_body.collision_layer & 1) == 0:
			return _error("Floor must belong to the actual body's scenery world")
		if floor_body is AnimatableBody3D or not floor_body.constant_linear_velocity.is_finite() or not floor_body.constant_angular_velocity.is_finite() or floor_body.constant_linear_velocity.length() > EPSILON or floor_body.constant_angular_velocity.length() > EPSILON:
			return _error("Animatable or moving support floors are unsupported")
		var count: int = 0
		for shape_owner: int in floor_body.get_shape_owners():
			if not floor_body.is_shape_owner_disabled(shape_owner):
				count += floor_body.shape_owner_get_shape_count(shape_owner)
		if count != 1:
			return _error("Each support floor body must have exactly one box")
		var box: BoxShape3D = collision.shape as BoxShape3D
		var rect: Rect2 = value.safe_rect
		if not box.size.is_finite() or box.size.x <= 0.0 or box.size.y <= 0.0 or box.size.z <= 0.0 or not collision.global_position.is_finite() or not rect.position.is_finite() or not rect.size.is_finite() or rect.size.x <= 0.0 or rect.size.y <= 0.0:
			return _error("Finite positive support geometry required")
		var actual := Rect2(_planar(collision.global_position) - Vector2(box.size.x, box.size.z) * 0.5, Vector2(box.size.x, box.size.z))
		var floor_top: float = collision.global_position.y + box.size.y * 0.5
		if not actual.encloses(rect) or (is_finite(top) and absf(top - floor_top) > EPSILON):
			return _error("Supported rectangles must fit coplanar actual floor boxes")
		top = floor_top
		floors.append({"rect": rect, "rid": floor_body.get_rid()})
		if not floor_rids.has(floor_body.get_rid()):
			floor_rids.append(floor_body.get_rid())
	# A3 measured -0.000078142m resting clearance on this build. The numeric
	# allowance is bounded by execution margin, and _step requires an actual
	# floor-only UP contact at this exact virtual pose. Cached current-body
	# is_on_floor history cannot validate a staged saved pose.
	var context := {"foot_offset": description.foot_offset, "half": description.footprint_half + Vector2.ONE * SAFE_MARGIN, "top": top, "floors": floors, "floor_rids": floor_rids}
	var support: String = _support_error(body, from.origin, from.origin, context)
	return context if support.is_empty() else _error(support)


static func _step(body: CharacterBody3D, from: Transform3D, motion: Vector3, context: Dictionary) -> Dictionary:
	var support: String = _support_error(body, from.origin, from.origin, context)
	if not support.is_empty():
		return _error(support)
	# Reporting recovery remains enabled in both diagnostic probes. No body
	# exceptions, transform, velocity or physics-server state are changed.
	var scenery: Dictionary = _query(body, from, Vector3.ZERO, true, context.floor_rids, 32)
	if not scenery.result.get_travel().is_finite() or scenery.result.get_travel().length() > EPSILON:
		return _error("Non-floor scenery requires depenetration before motion")
	var recovery: Dictionary = _query(body, from, Vector3.ZERO, true, [], 32)
	var floor_recovery: Vector3 = recovery.result.get_travel()
	if not floor_recovery.is_finite() or absf(floor_recovery.x) > EPSILON or absf(floor_recovery.z) > EPSILON or floor_recovery.y < -EPSILON or floor_recovery.y > MAX_FLOOR_RECOVERY + EPSILON:
		return _error("Recovery exceeds tiny upward floor settling")
	var requires_contact: bool = from.origin.y + float(context.foot_offset) < float(context.top) - EPSILON
	if floor_recovery.length() > EPSILON or requires_contact:
		for index: int in range(recovery.result.get_collision_count()):
			if not context.floor_rids.has(recovery.result.get_collider_rid(index)) or recovery.result.get_collision_normal(index).dot(Vector3.UP) < 0.999:
				return _error("Only validated floor normals may explain recovery")
		if recovery.result.get_collision_count() == 0:
			return _error("Floor recovery needs an actual reported support contact")
	# Execution's recovery_as_collision=false controls its returned collision,
	# while the probes above prevent unreported recovery from being accepted.
	var measured: Dictionary = _query(body, from, motion, false, [], 1)
	var result: PhysicsTestMotionResult3D = measured.result
	var raw: Vector3 = result.get_travel()
	if not raw.is_finite():
		return _error("Actual body query returned nonfinite travel")
	# Installed wrapper leaves its motion normal zero at CMP_EPSILON or below.
	var normal: Vector3 = motion.normalized() if motion.length() > EPSILON else Vector3.ZERO
	var longitudinal: float = raw.dot(normal)
	var orthogonal: Vector3 = raw - normal * longitudinal
	if orthogonal.length() > EPSILON and (floor_recovery.length() <= EPSILON or (orthogonal - floor_recovery).length() > 2.0 * EPSILON):
		return _error("Off-axis recovery is not explained by validated floor contact")
	# Exact installed PhysicsBody3D.cpp98-131 cancellation thresholds.
	var precision: float = ENGINE_PRECISION
	var cancel: bool = true
	if measured.collided:
		if result.get_collision_count() == 0:
			return _error("Collision query did not report a measured contact")
		precision += motion.length() * (result.get_collision_unsafe_fraction() - result.get_collision_safe_fraction())
		if result.get_collision_depth(0) > SAFE_MARGIN + precision:
			cancel = false
	var travel: Vector3 = raw
	if cancel and orthogonal.length() < SAFE_MARGIN + precision:
		travel = normal * longitudinal
	if not travel.is_finite() or absf(travel.y) > EPSILON or (travel - normal * travel.dot(normal)).length() > EPSILON or travel.dot(normal) < -EPSILON or travel.dot(normal) > motion.length() + EPSILON:
		return _error("Actual wrapper cannot preserve the supported straight lane")
	var finish: Vector3 = from.origin + travel
	support = _support_error(body, from.origin, finish, context)
	if not support.is_empty():
		return _error(support)
	var collider := RID()
	var contact_normal := Vector3.ZERO
	if measured.collided and result.get_collision_count() > 0:
		collider = result.get_collider_rid(0)
		contact_normal = result.get_collision_normal(0)
	return {"motion": motion, "travel": travel, "end": finish, "collided": measured.collided, "collider_rid": collider, "normal": contact_normal, "raw_travel": raw, "floor_recovery": floor_recovery, "cancelled_recovery": raw - travel, "safe_fraction": result.get_collision_safe_fraction(), "unsafe_fraction": result.get_collision_unsafe_fraction(), "api_revision": API_REVISION}


static func _query(body: CharacterBody3D, from: Transform3D, motion: Vector3, report_recovery: bool, exclude: Array, max_collisions: int) -> Dictionary:
	var parameters := PhysicsTestMotionParameters3D.new()
	parameters.from = from
	parameters.motion = motion
	parameters.margin = SAFE_MARGIN
	parameters.recovery_as_collision = report_recovery
	parameters.max_collisions = max_collisions
	var excluded: Array[RID] = []
	for rid: RID in exclude:
		excluded.append(rid)
	parameters.exclude_bodies = excluded
	var result := PhysicsTestMotionResult3D.new()
	var collided: bool = PhysicsServer3D.body_test_motion(body.get_rid(), parameters, result)
	return {"collided": collided, "result": result}


static func _support_error(body: CharacterBody3D, start: Vector3, finish: Vector3, context: Dictionary) -> String:
	if not _bounded(start) or not _bounded(finish):
		return "Virtual path exceeds finite 512m coordinate bounds"
	for point: Vector3 in [start, finish]:
		var feet: float = point.y + float(context.foot_offset)
		if feet < float(context.top) - SAFE_MARGIN or feet > float(context.top) + STANDING_HEIGHT:
			return "Measured feet are embedded or outside the standing-height envelope"
	var intervals: Array[Vector2] = []
	var a: Vector2 = _planar(start)
	var b: Vector2 = _planar(finish)
	for floor: Dictionary in context.floors:
		var rect: Rect2 = floor.rect
		rect.position += context.half
		rect.size -= 2.0 * context.half
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		var interval := Vector2(0, 1)
		for axis: int in range(2):
			var delta: float = b[axis] - a[axis]
			if absf(delta) <= EPSILON:
				if a[axis] < rect.position[axis] - EPSILON or a[axis] > rect.end[axis] + EPSILON:
					interval = Vector2(1, 0)
					break
			else:
				var first: float = (rect.position[axis] - a[axis]) / delta
				var last: float = (rect.end[axis] - a[axis]) / delta
				interval.x = maxf(interval.x, minf(first, last))
				interval.y = minf(interval.y, maxf(first, last))
		if interval.x <= interval.y:
			intervals.append(interval)
	intervals.sort_custom(func(left: Vector2, right: Vector2) -> bool: return left.x < right.x)
	var covered: float = 0.0
	for interval: Vector2 in intervals:
		if interval.x > covered + EPSILON:
			return "Measured footprint loses continuous floor coverage"
		covered = maxf(covered, interval.y)
	if covered < 1.0 - EPSILON:
		return "Measured footprint loses continuous floor coverage"
	for point: Vector3 in [start, finish]:
		var feet := Vector3(point.x, point.y + float(context.foot_offset), point.z)
		var query := PhysicsRayQueryParameters3D.create(feet + Vector3.UP * 0.1, feet - Vector3.UP * 0.1, 1)
		var hit: Dictionary = body.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or not context.floor_rids.has(hit.rid):
			return "Actual support floor is missing from the physics world"
	return ""


static func _planar(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)


static func _bounded(point: Vector3) -> bool:
	return point.is_finite() and absf(point.x) <= MAX_COORDINATE and absf(point.y) <= MAX_COORDINATE and absf(point.z) <= MAX_COORDINATE


static func _error(reason: String) -> Dictionary:
	return {"error": reason, "api_revision": API_REVISION}
