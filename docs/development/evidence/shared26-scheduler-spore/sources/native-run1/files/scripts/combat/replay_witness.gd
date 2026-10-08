class_name CinderReplayWitness
extends RefCounted
## Pure bounded whole-sequence response witness. This does NOT reserve a threat,
## consume capture, execute a ghost or certify portrait visibility. Caller must
## atomically reserve the exclusive exchange and visibly reject/re-arm on failure.
## All recorded attack cones stay dangerous even behind LOS shelter: conservative
## false rejection is preferable to attributing safety to unverified clipping.

const Sequence = preload("res://scripts/combat/replay_sequence.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const API_REVISION: String = "replay-witness-1"
const MAX_COORDINATE: float = 512.0
const MAX_CLOCK_S: float = 1000000.0
const MAX_DISPATCH_DELAY_S: float = 0.05

var last_error: String = ""


func prove(scheduler: Node3D, sequence_snapshot: Dictionary, response: Dictionary, context: Dictionary, at_lock: bool = false, permitted_reservation_id: String = "") -> Dictionary:
	last_error = ""
	if not is_instance_valid(scheduler):
		return _reject("Live shared scheduler required")
	var error: String = scheduler.response_error(response)
	if not error.is_empty():
		return _reject(error)
	if not permitted_reservation_id.is_empty():
		if not at_lock or not scheduler.has_method("replay_exchange_error"):
			return _reject("Only the scheduler's exact own unarmed replay may be excluded at lock")
		error = scheduler.replay_exchange_error(sequence_snapshot, context, permitted_reservation_id)
		if not error.is_empty():
			return _reject(error)
	elif scheduler.has_committed_exchange():
		return _reject("Replay requires an exclusive exchange; other preparing/active/recovery sources must be suppressed")
	var world_root: Node3D = context.get("world_root") as Node3D
	if not is_instance_valid(world_root) or not world_root.is_inside_tree() or world_root.is_queued_for_deletion() or world_root.get_world_3d() != scheduler.get_world_3d() or not (world_root == scheduler or world_root.is_ancestor_of(scheduler)):
		return _reject("Live immutable collision root containing the scheduler required")
	if not context.get("source_epoch") is String or not Codec.is_integer(context.get("generation"), 1):
		return _reject("Explicit capture epoch and generation required")
	var sequence = Sequence.new()
	if not sequence.restore_state(sequence_snapshot, context.source_epoch, int(context.generation)):
		return _reject("Invalid immutable sequence: " + sequence.last_snapshot_error)
	var plan: Dictionary = sequence.state()
	var actor: CharacterBody3D = response.actor
	if not actor.has_method("get_threat_response_state"):
		return _reject("Actual shared-player response publication required")
	var live: Dictionary = actor.get_threat_response_state()
	for key: String in ["stats", "stable", "dash_cooldown_left_s", "primary_cooldown_left_s", "commitment_remaining_s", "primary_commitment_s"]:
		if not live.has(key) or live[key] != response.get(key):
			return _reject("Replay response must match the actual current player: " + key)
	if not live.get("pending_weapon_id") is String or not String(live.pending_weapon_id).is_empty():
		return _reject("Wait for the actual pending weapon change before proving a future loadout")
	if (actor.collision_mask & 1) == 0 or (actor.collision_layer & 1) != 0:
		return _reject("Shared actor must collide with scenery without becoming scenery")
	for axis: int in [PhysicsServer3D.BODY_AXIS_LINEAR_X, PhysicsServer3D.BODY_AXIS_LINEAR_Y, PhysicsServer3D.BODY_AXIS_LINEAR_Z]:
		if actor.get_axis_lock(axis):
			return _reject("Actor axis locks cannot preserve the ordinary dash model")
	var collider_count: int = 0
	for child: Node in actor.get_children():
		if child is CollisionShape3D or child is CollisionPolygon3D:
			collider_count += 1
	if collider_count != 1:
		return _reject("Shared actor must own exactly its fixed capsule")
	if float(response.recognition_s) < float(plan.authored.recognition_s):
		return _reject("Response recognition cannot undercut the authored recognition budget")
	if not _bounded_point(actor.global_position) or not _bounded_point(plan.authored.tether_position) or not _world_bounded(world_root):
		return _reject("Replay world exceeds supported coordinate/shape precision envelope")
	var fingerprint: Dictionary = scheduler.collision_fingerprint(world_root)
	if fingerprint.is_empty():
		return _reject("Supported static collision fingerprint required")
	if not context.get("capture_collision_fingerprint") is Dictionary or not Codec.value_error(context.capture_collision_fingerprint).is_empty() or not _same_guard(context.capture_collision_fingerprint, fingerprint):
		return _reject("Collision world must match its recorded capture fingerprint")
	var clock_s: float = scheduler.get_clock()
	if not is_finite(clock_s) or clock_s < 0.0 or clock_s > MAX_CLOCK_S:
		return _reject("Replay scheduler clock exceeds the supported numerical envelope")
	var timeline_origin_s: float = clock_s - float(plan.authored.warning_s) if at_lock else clock_s
	var attacks: Array[Dictionary] = []
	for slot: Dictionary in plan.timeline.slots:
		# The captured actual route must still be physically valid in this world;
		# a nonblocking visual ghost does not authorize travel through new walls.
		for index: int in range(slot.route.size()):
			var point: Vector3 = slot.route[index].position
			var before: Vector3 = point if index == 0 else slot.route[index - 1].position
			if not _bounded_point(point):
				return _reject("Captured absolute route exceeds supported coordinates")
			var floor_error: String = scheduler._floor_error(response.floor_regions, point)
			if not floor_error.is_empty():
				return _reject("Captured absolute route lost floor at sample %d: %s" % [index, floor_error])
			if not _captured_floor_supported(scheduler, before, point, response.floor_regions):
				return _reject("Captured absolute route lost continuous floor at sample %d" % index)
			if not _captured_path_clear(scheduler, before, point, actor, response.floor_regions):
				return _reject("Captured absolute route intersects current scenery at sample %d" % index)
		for event: Dictionary in slot.events:
			var record: Dictionary = event.record
			var geometry: Dictionary = Geometry.cone(record.world_origin, record.direction, float(record.geometry.reach), float(record.geometry.cone_min_dot), float(record.geometry.origin_disk_radius))
			if not _bounded_point(record.world_origin) or not Geometry.error(geometry).is_empty():
				return _reject("Captured attack requires supported convex authoritative geometry")
			attacks.append({"event_id": event.event_id, "at_s": timeline_origin_s + float(event.at_s), "until_s": timeline_origin_s + float(event.at_s) + MAX_DISPATCH_DELAY_S, "geometry": geometry})
	var stats: Dictionary = response.stats
	var origin: Vector3 = actor.global_position
	var dash_start_s: float = clock_s + float(response.recognition_s) + float(response.commitment_remaining_s) + float(response.dash_cooldown_left_s)
	var dash_end_s: float = dash_start_s + float(stats.dash_duration)
	var slots: Array = plan.timeline.slots
	if dash_end_s > timeline_origin_s + float(slots[0].from_s) - scheduler.TIME_MARGIN:
		return _reject("Full current response and ordinary dash do not fit before first playback")
	var primary_ready_s: float = clock_s + float(response.primary_cooldown_left_s)
	for direction: Vector3 in response.escape_directions:
		var first_landing: Vector3 = origin + direction * float(stats.dash_distance)
		var initial: Array[Dictionary] = [_segment(origin, origin, clock_s, dash_start_s, "recognition_and_ready"), _segment(origin, first_landing, dash_start_s, dash_end_s, "first_escape_dash")]
		var second_choices: Array[Vector3] = []
		if slots.size() == 1:
			second_choices.append(Vector3.ZERO)
		if slots.size() == 2:
			for second_direction: Vector3 in response.escape_directions:
				second_choices.append(second_direction)
		for second_direction: Vector3 in second_choices:
			var path: Array[Dictionary] = initial.duplicate(true)
			var landing: Vector3 = first_landing
			var last_dash_start_s: float = dash_start_s
			var last_dash_end_s: float = dash_end_s
			if slots.size() == 2:
				# Do not start crossing the second echo until the first combination's
				# complete intrinsic end; normal dash cooldown and recognition remain.
				last_dash_start_s = maxf(dash_start_s + float(stats.dash_cooldown), timeline_origin_s + _slot_safe_end(slots[0], scheduler.TIME_MARGIN) + float(response.recognition_s))
				last_dash_end_s = last_dash_start_s + float(stats.dash_duration)
				if last_dash_end_s > timeline_origin_s + float(slots[1].from_s) - scheduler.TIME_MARGIN:
					continue
				landing = first_landing + second_direction * float(stats.dash_distance)
				path.append(_segment(first_landing, first_landing, dash_end_s, last_dash_start_s, "inter_echo_ready"))
				path.append(_segment(first_landing, landing, last_dash_start_s, last_dash_end_s, "second_escape_dash"))
			var safe_tether_s: float = float(plan.timeline.tether_from_s)
			for attack: Dictionary in attacks:
				safe_tether_s = maxf(safe_tether_s, float(attack.until_s) - timeline_origin_s)
			var opening_s: float = maxf(last_dash_end_s, timeline_origin_s + safe_tether_s + scheduler.TIME_MARGIN)
			var return_choices: Array[Vector3] = [Vector3.ZERO]
			for returning: Vector3 in response.return_directions:
				return_choices.append(returning)
			for returning: Vector3 in return_choices:
				var complete_path: Array[Dictionary] = path.duplicate(true)
				var attack_position: Vector3 = landing
				var attack_s: float = maxf(opening_s, primary_ready_s) + float(response.attack_input_margin_s)
				if returning != Vector3.ZERO:
					var return_s: float = maxf(opening_s, last_dash_start_s + float(stats.dash_cooldown))
					var return_end_s: float = return_s + float(stats.dash_duration)
					attack_position = landing + returning * float(stats.dash_distance)
					complete_path.append(_segment(landing, landing, last_dash_end_s, return_s, "tether_return_ready"))
					complete_path.append(_segment(landing, attack_position, return_s, return_end_s, "tether_positioning_dash"))
					attack_s = maxf(return_end_s, primary_ready_s) + float(response.attack_input_margin_s)
					complete_path.append(_segment(attack_position, attack_position, return_end_s, attack_s, "ordinary_primary_ready"))
				else:
					complete_path.append(_segment(landing, landing, last_dash_end_s, attack_s, "tether_ready"))
				var finish_s: float = attack_s + maxf(float(stats.primary_cooldown), float(response.primary_commitment_s))
				if not is_finite(finish_s) or finish_s > timeline_origin_s + float(plan.timeline.tether_until_s) - scheduler.TIME_MARGIN or not scheduler._opening_reachable(attack_position, plan.authored.tether_position, float(stats.primary_range)):
					continue
				complete_path.append(_segment(attack_position, attack_position, attack_s, finish_s, "ordinary_primary_full_recovery"))
				if not _safe_path(scheduler, complete_path, actor, response.floor_regions, attacks):
					continue
				# Physics queries cannot yield; a changed scene fingerprint would
				# invalidate the same call, never be accepted as a partial proof.
				if scheduler.collision_fingerprint(world_root) != fingerprint:
					return _reject("Collision world changed during whole-sequence validation")
				return {"accepted": true, "api_revision": API_REVISION, "proof_scope": "static_box_floor_bounded_dispatch_replay_union_and_stationary_tether", "dispatch_delay_bound_s": MAX_DISPATCH_DELAY_S, "path": complete_path, "attack_position": attack_position, "primary_time_s": attack_s, "response_complete_s": finish_s, "timeline_origin_s": timeline_origin_s, "evaluated_at_s": clock_s, "at_lock": at_lock, "event_count": attacks.size(), "slot_count": slots.size(), "source_epoch": plan.source_epoch, "generation": plan.generation, "sequence_id": plan.sequence_id, "world_revision": response.world_revision, "profile_id": scheduler.encounter_profile().id, "collision_fingerprint": fingerprint.duplicate(true), "uses_blast": false, "uses_invulnerability": false, "reserves_threat": false}
	return _reject("No supported timed route clears every replay dispatch window and reaches the tether with ordinary-primary recovery")


func _slot_safe_end(slot: Dictionary, margin_s: float) -> float:
	var end_s: float = float(slot.end_s)
	for event: Dictionary in slot.events:
		end_s = maxf(end_s, float(event.at_s) + MAX_DISPATCH_DELAY_S + margin_s)
	return end_s


func _captured_floor_supported(scheduler: Node3D, start: Vector3, finish: Vector3, floors: Array) -> bool:
	# Recorded move_and_slide can include tiny real vertical floor settling.
	# Preserve all original samples; only analytic X/Z support uses a plane.
	# Both actual endpoints remain inside the same standing-height envelope.
	if not scheduler._floor_error(floors, start).is_empty() or not scheduler._floor_error(floors, finish).is_empty():
		return false
	var planar_finish: Vector3 = finish
	planar_finish.y = start.y
	if not scheduler._floor_path_supported(start, planar_finish, floors):
		return false
	for point: Vector3 in [start, finish]:
		var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.2, point - Vector3.UP * 0.2, 1)
		var hit: Dictionary = scheduler.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			return false
		var matched: bool = false
		for region: Dictionary in floors:
			if hit.rid == (region.collision.get_parent() as StaticBody3D).get_rid():
				matched = true
		if not matched:
			return false
	return true


func _captured_path_clear(scheduler: Node3D, start: Vector3, finish: Vector3, actor: CharacterBody3D, floors: Array) -> bool:
	# Replay travel is nonblocking and harmless. Recorded actual contacts can
	# differ from shape-query boundaries within the measured .005m physical
	# contact tolerance. This query applies that tolerance only to recorded
	# travel, with a matching capture-world guard; live escape still uses full
	# padded capsule proof. No path, origin or damage geometry is changed.
	var shape := CapsuleShape3D.new()
	shape.radius = scheduler.CAPSULE_RADIUS - 0.005
	shape.height = scheduler.CAPSULE_HEIGHT
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	query.collide_with_areas = false
	var excluded: Array[RID] = [actor.get_rid()]
	for floor_region: Dictionary in floors:
		excluded.append((floor_region.collision.get_parent() as StaticBody3D).get_rid())
	query.exclude = excluded
	query.transform = Transform3D(Basis.IDENTITY, start + Vector3.UP * scheduler.CAPSULE_CENTER_Y)
	var space: PhysicsDirectSpaceState3D = scheduler.get_world_3d().direct_space_state
	if not space.intersect_shape(query, 1).is_empty():
		return false
	query.motion = finish - start
	var fractions: PackedFloat32Array = space.cast_motion(query)
	if fractions.size() != 2 or float(fractions[0]) < 1.0 - scheduler.EPSILON:
		return false
	query.transform.origin = finish + Vector3.UP * scheduler.CAPSULE_CENTER_Y
	query.motion = Vector3.ZERO
	return space.intersect_shape(query, 1).is_empty()


func _safe_path(scheduler: Node3D, path: Array[Dictionary], actor: CharacterBody3D, floors: Array, attacks: Array[Dictionary]) -> bool:
	for segment: Dictionary in path:
		if not _bounded_point(segment.from) or not _bounded_point(segment.to) or not scheduler._floor_path_supported(segment.from, segment.to, floors) or not scheduler._capsule_path_clear(segment.from, segment.to, actor, floors):
			return false
	for attack: Dictionary in attacks:
		if Geometry.timed_path_hits(attack.geometry, path, float(attack.at_s), float(attack.until_s), scheduler.CAPSULE_RADIUS + scheduler.SKIN):
			return false
	return true


func _same_guard(left: Variant, right: Variant) -> bool:
	if Codec.is_number(left) and Codec.is_number(right):
		# Immutable collision identity has no physical/contact tolerance. Tagged
		# exact JSON preserves native scalar values across the save boundary.
		return float(left) == float(right)
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size():
			return false
		for key: String in left:
			if not right.has(key) or not _same_guard(left[key], right[key]):
				return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size():
			return false
		for index: int in range(left.size()):
			if not _same_guard(left[index], right[index]):
				return false
		return true
	return typeof(left) == typeof(right) and left == right


func _bounded_point(point: Vector3) -> bool:
	return point.is_finite() and maxf(absf(point.x), maxf(absf(point.y), absf(point.z))) <= MAX_COORDINATE


func _world_bounded(world_root: Node3D) -> bool:
	# Enclosing spheres include full collider extents and world scale. The bound
	# is deliberately conservative; Godot Vector3 precision is finite float32.
	var pending: Array[Node] = [world_root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		pending.append_array(node.get_children())
		if not node is StaticBody3D or ((node as StaticBody3D).collision_layer & 1) == 0:
			continue
		var body: StaticBody3D = node
		for owner_id: int in body.get_shape_owners():
			if body.is_shape_owner_disabled(owner_id):
				continue
			var transform: Transform3D = body.global_transform * body.shape_owner_get_transform(owner_id)
			if not _bounded_point(transform.origin):
				return false
			var basis_norm: float = sqrt(transform.basis.x.length_squared() + transform.basis.y.length_squared() + transform.basis.z.length_squared())
			for index: int in range(body.shape_owner_get_shape_count(owner_id)):
				var shape: Shape3D = body.shape_owner_get_shape(owner_id, index)
				var radius: float = _shape_radius(shape)
				var origin_extent: float = maxf(absf(transform.origin.x), maxf(absf(transform.origin.y), absf(transform.origin.z)))
				if not is_finite(radius) or radius <= 0.0 or not is_finite(basis_norm) or origin_extent + basis_norm * radius > MAX_COORDINATE:
					return false
	return true


func _shape_radius(shape: Shape3D) -> float:
	if shape is BoxShape3D:
		return (shape as BoxShape3D).size.length() * 0.5
	if shape is CapsuleShape3D:
		return (shape as CapsuleShape3D).height * 0.5
	if shape is CylinderShape3D:
		return Vector2((shape as CylinderShape3D).radius, (shape as CylinderShape3D).height * 0.5).length()
	if shape is SphereShape3D:
		return (shape as SphereShape3D).radius
	var points: PackedVector3Array
	if shape is ConvexPolygonShape3D:
		points = (shape as ConvexPolygonShape3D).points
	elif shape is ConcavePolygonShape3D:
		points = (shape as ConcavePolygonShape3D).get_faces()
	else:
		return INF
	var radius: float = 0.0
	for point: Vector3 in points:
		if not point.is_finite():
			return INF
		radius = maxf(radius, point.length())
	return radius


func _segment(start: Vector3, finish: Vector3, begin_s: float, end_s: float, kind: String) -> Dictionary:
	return {"from": start, "to": finish, "start_s": begin_s, "end_s": end_s, "kind": kind}


func _reject(reason: String) -> Dictionary:
	last_error = reason
	return {"accepted": false, "reason": reason}
