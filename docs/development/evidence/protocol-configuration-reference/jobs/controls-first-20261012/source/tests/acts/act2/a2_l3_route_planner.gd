extends RefCounted
## TEST ONLY read-only one/two-full-dash waypoint planner. No motion, clock,
## scheduler/proof, hazard, HP, cue, presentation, input or restore authority.
## Caller requests native dashes, verifies real landings and re-plans from them.
## Empty means unsupported; an already reached clear goal returns [current].

const DISTANCE_EPSILON: float = 0.0001
const GROUND_EPSILON: float = 0.02
const SWEEP_MARGIN: float = 0.001
const FLOOR_MARGIN: float = 0.01

static func path(hero: CinderPlayer, level: CinderLevel, goal: Vector3) -> Array[Vector3]:
	var empty: Array[Vector3] = []
	if not _bound(hero, level) or not goal.is_finite(): return empty
	var start: Vector3 = hero.global_position
	if absf(goal.y - start.y) > GROUND_EPSILON or not hero.stats.has("dash_distance"): return empty
	var distance: float = float(hero.stats.dash_distance)
	if not is_finite(distance) or distance <= 0.0: return empty
	# Keep feet on the actual sampled ground plane. This changes a proposed
	# waypoint only, never the supplied goal object or a production transform.
	var finish := Vector3(goal.x, start.y, goal.z)
	var offset: Vector3 = finish - start
	var span: float = offset.length()
	if not is_finite(span) or not leg_clear(hero, level, start, start) or not leg_clear(hero, level, finish, finish): return empty
	if span <= DISTANCE_EPSILON:
		var reached: Array[Vector3] = [start]
		return reached
	if absf(span - distance) <= DISTANCE_EPSILON and leg_clear(hero, level, start, finish):
		var direct: Array[Vector3] = [finish]
		return direct
	if span > 2.0 * distance: return empty
	var midpoint: Vector3 = (start + finish) * 0.5
	var perpendicular := Vector3(-offset.z, 0.0, offset.x) / span
	var height: float = sqrt(maxf(distance * distance - span * span * 0.25, 0.0))
	var selected: Vector3 = Vector3.INF
	for side: float in [-1.0, 1.0]:
		var waypoint: Vector3 = midpoint + perpendicular * height * side
		if not waypoint.is_finite() or not leg_clear(hero, level, start, waypoint) or not leg_clear(hero, level, waypoint, finish): continue
		if not selected.is_finite() or absf(waypoint.x) < absf(selected.x): selected = waypoint
	if not selected.is_finite(): return empty
	var result: Array[Vector3] = [selected, finish]
	return result

static func leg_clear(hero: CinderPlayer, level: CinderLevel, start: Vector3, finish: Vector3) -> bool:
	if not _bound(hero, level) or not start.is_finite() or not finish.is_finite() or absf(start.y - hero.global_position.y) > GROUND_EPSILON or absf(finish.y - start.y) > GROUND_EPSILON: return false
	var collision: CollisionShape3D = hero.get_node_or_null("BodyCollision") as CollisionShape3D
	if not is_instance_valid(collision) or collision.disabled or not collision.shape is CapsuleShape3D or collision.global_basis != Basis.IDENTITY: return false
	var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D
	if not is_equal_approx(capsule.radius, CinderThreatScheduler.CAPSULE_RADIUS) or not is_equal_approx(capsule.height, CinderThreatScheduler.CAPSULE_HEIGHT): return false
	if not (collision.global_position - hero.global_position).is_equal_approx(Vector3.UP * CinderThreatScheduler.CAPSULE_CENTER_Y): return false
	var regions: Variant = level.call("floor_regions")
	if not regions is Array or regions.is_empty(): return false
	var excluded: Array[RID] = [hero.get_rid()]
	var supported: bool = false
	for value: Variant in regions:
		if not value is Dictionary or not value.has_all(["body", "collision", "safe_rect"]) or not value.safe_rect is Rect2: return false
		var floor: Dictionary = value
		var body: StaticBody3D = floor.body as StaticBody3D
		var shape: CollisionShape3D = floor.collision as CollisionShape3D
		if not is_instance_valid(body) or not body.is_inside_tree() or body.is_queued_for_deletion() or body.get_world_3d() != hero.get_world_3d() or not is_instance_valid(shape) or shape.disabled or shape.get_parent() != body or not shape.shape is BoxShape3D or shape.global_basis != Basis.IDENTITY: return false
		var box: BoxShape3D = shape.shape as BoxShape3D
		if not box.size.is_finite() or box.size.x <= 0.0 or box.size.y <= 0.0 or box.size.z <= 0.0: return false
		var center: Vector3 = shape.global_position
		var native_rect := Rect2(Vector2(center.x - box.size.x * 0.5, center.z - box.size.z * 0.5), Vector2(box.size.x, box.size.z))
		var rect: Rect2 = floor.safe_rect
		if not rect.position.is_finite() or not rect.size.is_finite() or rect.size.x <= 0.0 or rect.size.y <= 0.0: return false
		if not native_rect.encloses(rect): return false
		excluded.append(body.get_rid())
		# One convex supplied native floor must support both capsule-inset
		# endpoints; therefore it also supports their entire straight segment.
		var inset: Rect2 = rect.grow(-(capsule.radius + FLOOR_MARGIN))
		if absf(start.y - (center.y + box.size.y * 0.5)) <= GROUND_EPSILON and absf(finish.y - (center.y + box.size.y * 0.5)) <= GROUND_EPSILON and inset.size.x > 0.0 and inset.size.y > 0.0 and inset.has_point(Vector2(start.x, start.z)) and inset.has_point(Vector2(finish.x, finish.z)): supported = true
	if not supported: return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	var virtual_pose: Transform3D = collision.global_transform
	virtual_pose.origin += start - hero.global_position
	query.transform = virtual_pose
	query.motion = finish - start
	query.collision_mask = 1
	query.margin = SWEEP_MARGIN
	query.exclude = excluded
	# Floors are excluded only from this read-only query; all native dashes
	# retain actual colliders. The supported endpoint test covers floor edges.
	var space: PhysicsDirectSpaceState3D = hero.get_world_3d().direct_space_state
	if space.intersect_shape(query, 1).size() != 0: return false
	if query.motion == Vector3.ZERO: return true
	var cast: PackedFloat32Array = space.cast_motion(query)
	return cast.size() == 2 and cast[0] == 1.0

static func _bound(hero: CinderPlayer, level: CinderLevel) -> bool:
	return is_instance_valid(hero) and hero.is_inside_tree() and not hero.is_queued_for_deletion() and not hero.dead and is_instance_valid(level) and level.is_inside_tree() and not level.is_queued_for_deletion() and level.has_method("floor_regions") and hero.get_world_3d() == level.get_world_3d() and hero.global_position.is_finite()
