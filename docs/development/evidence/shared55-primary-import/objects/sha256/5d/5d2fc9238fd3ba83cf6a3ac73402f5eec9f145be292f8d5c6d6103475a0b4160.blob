extends "res://scripts/combat/threat_scheduler.gd"
## TEST ONLY passive wrapper of one public native commit call. No authority.
## Received arguments are converted immediately, before native cancellation
## callbacks can change their referenced nodes. Return the actual answer.
const MAX_OBSERVATIONS: int = 4
const NODE_BUDGET: int = 16384
const MAX_DEPTH: int = 16
const MAX_OVERLAP_HITS: int = 8
const GENERIC_PROOF_EXHAUSTION: String = "No supported collision/floor-safe timed escape and ordinary-primary opening through the committed threat union"
var observations: Array[Dictionary] = []
var diagnostic_nodes: Array[Node] = []
var _remaining_nodes: int = 0

func commit_tracking(reservation_id: String, geometry: Dictionary, response: Dictionary) -> Dictionary:
	var sample: Dictionary = {}
	if observations.size() < MAX_OBSERVATIONS:
		_remaining_nodes = NODE_BUDGET
		sample = {"call": observations.size() + 1, "reservation_id": reservation_id, "clock_before_s": get_clock(), "geometry_argument": _native_value(geometry), "response_argument": _native_value(response)}
		var context: Array = []
		for node: Node in diagnostic_nodes: context.append(_native_value(node))
		sample["named_native_context_before"] = context
	# Exactly one native public call. Never preview, query a reservation, prune,
	# validate another response, retry admission or modify the returned answer.
	var answer: Dictionary = super.commit_tracking(reservation_id, geometry, response)
	var last_error_after_super: String = last_error # First native fact after super, before conversion/query.
	if not sample.is_empty():
		sample["scheduler_last_error_after_super"] = last_error_after_super
		sample["clock_after_s"] = get_clock()
		sample["answer_accepted"] = answer.get("accepted")
		sample["answer_reason"] = answer.get("reason")
		sample["answer"] = _native_value(answer)
		# Native refusal remains primary. Only this exact generic branch gets two
		# callback-free zero-motion observations, never a cast or substitute proof.
		if answer.get("accepted") == false and answer.get("reason") == GENERIC_PROOF_EXHAUSTION:
			sample["starting_overlap_after_native_refusal"] = _starting_overlap(response)
		observations.append(sample)
	return answer

func _native_value(value: Variant, depth: int = 0) -> Variant:
	_remaining_nodes -= 1
	if _remaining_nodes < 0 or depth > MAX_DEPTH: return {"diagnostic_limit": "native conversion bound reached"}
	if value == null: return null
	if value is bool or value is String: return value
	if value is StringName: return {"native_type": "StringName", "value": str(value)}
	if value is int:
		return value if value >= -9007199254740991 and value <= 9007199254740991 else {"native_type": "int", "decimal": str(value)}
	if value is float:
		return value if is_finite(value) else {"native_type": "nonfinite_float", "diagnostic": str(value)}
	if value is Vector2: return {"native_type": "Vector2", "value": [_native_value(value.x, depth + 1), _native_value(value.y, depth + 1)]}
	if value is Vector3: return {"native_type": "Vector3", "value": [_native_value(value.x, depth + 1), _native_value(value.y, depth + 1), _native_value(value.z, depth + 1)]}
	if value is RID: return {"native_type": "RID", "id_decimal": str(value.get_id())}
	if value is Rect2: return {"native_type": "Rect2", "position": _native_value(value.position, depth + 1), "size": _native_value(value.size, depth + 1)}
	if value is Basis: return {"native_type": "Basis", "x": _native_value(value.x, depth + 1), "y": _native_value(value.y, depth + 1), "z": _native_value(value.z, depth + 1)}
	if value is Transform3D: return {"native_type": "Transform3D", "origin": _native_value(value.origin, depth + 1), "basis": _native_value(value.basis, depth + 1)}
	if value is Dictionary:
		var entries: Array = []
		if value.size() > 256: return {"diagnostic_limit": "native dictionary too large"}
		for key: Variant in value:
			entries.append({"key_type": typeof(key), "key": _native_value(key, depth + 1), "value": _native_value(value[key], depth + 1)})
		return {"native_type": "Dictionary", "entries": entries}
	if value is Array:
		var items: Array = []
		if value.size() > 256: return {"diagnostic_limit": "native array too large"}
		for item: Variant in value: items.append(_native_value(item, depth + 1))
		return {"native_type": "Array", "items": items}
	if typeof(value) == TYPE_OBJECT:
		if not is_instance_valid(value): return {"native_type": "retired_object"}
		var native: Dictionary = {"native_type": value.get_class(), "instance_id_decimal": str(value.get_instance_id())}
		if value is Node:
			native["inside_tree"] = value.is_inside_tree()
			native["queued_for_deletion"] = value.is_queued_for_deletion()
			native["name"] = str(value.name)
			native["path"] = str(value.get_path()) if value.is_inside_tree() else ""
			var script: Variant = value.get_script()
			native["script_path"] = script.resource_path if is_instance_valid(script) else ""
		if value is Node3D:
			native["global_transform"] = _native_value(value.global_transform, depth + 1)
		if value is CollisionObject3D:
			native["collision_layer"] = value.collision_layer
			native["collision_mask"] = value.collision_mask
		if value is CharacterBody3D:
			native["velocity"] = _native_value(value.velocity, depth + 1)
			native["body_collision"] = _native_value(value.get_node_or_null("BodyCollision"), depth + 1)
		if value is CollisionShape3D:
			native["disabled"] = value.disabled
			native["shape"] = _native_value(value.shape, depth + 1)
			var parent: Node = value.get_parent()
			if parent is CollisionObject3D:
				native["parent_layer"] = parent.collision_layer
				native["parent_mask"] = parent.collision_mask
		if value is BoxShape3D: native["size"] = _native_value(value.size, depth + 1)
		if value is CapsuleShape3D or value is CylinderShape3D:
			native["radius"] = _native_value(value.radius, depth + 1)
			native["height"] = _native_value(value.height, depth + 1)
		return native
	return {"native_type_id": typeof(value), "diagnostic": "unsupported native type retained as a diagnostic tag"}


func _starting_overlap(response: Dictionary) -> Dictionary:
	var report: Dictionary = {"scope": "Two passive starting-overlap queries only; no sweep, path proof, admission or state change", "clock_s": get_clock(), "queried": false, "error": ""}
	var actor_value: Variant = response.get("actor")
	var regions_value: Variant = response.get("floor_regions")
	if not is_instance_valid(actor_value) or not actor_value is CharacterBody3D or not actor_value.is_inside_tree() or actor_value.is_queued_for_deletion() or not regions_value is Array or regions_value.is_empty() or regions_value.size() > 64:
		report["error"] = "Actual received actor/floors no longer provide bounded native query bindings"
		return report
	var actor: CharacterBody3D = actor_value
	var body_value: Variant = actor.get_node_or_null("BodyCollision")
	if not is_instance_valid(body_value) or not body_value is CollisionShape3D or body_value.disabled or not body_value.shape is CapsuleShape3D or body_value.get_parent() != actor or not body_value.is_inside_tree() or body_value.is_queued_for_deletion() or actor.get_world_3d() != get_world_3d():
		report["error"] = "Actual Player capsule/world binding unavailable after native refusal"
		return report
	var body: CollisionShape3D = body_value
	var excluded: Array[RID] = [actor.get_rid()]
	var excluded_nodes: Array = [_native_value(actor)]
	for region_value: Variant in regions_value:
		if not region_value is Dictionary:
			report["error"] = "Actual received floor entry is not a Dictionary"
			return report
		var floor_value: Variant = region_value.get("collision")
		if not is_instance_valid(floor_value) or not floor_value is CollisionShape3D or not floor_value.is_inside_tree() or floor_value.is_queued_for_deletion() or not floor_value.get_parent() is StaticBody3D:
			report["error"] = "Actual received floor collision/body cannot provide original exclusions"
			return report
		var floor_body: StaticBody3D = floor_value.get_parent()
		if not floor_body.is_inside_tree() or floor_body.is_queued_for_deletion() or floor_body.get_world_3d() != get_world_3d():
			report["error"] = "Actual received floor body world/lifecycle changed"
			return report
		excluded.append(floor_body.get_rid())
		excluded_nodes.append(_native_value(floor_body))
	var padded: CapsuleShape3D = CapsuleShape3D.new()
	padded.radius = CAPSULE_RADIUS + SKIN
	padded.height = CAPSULE_HEIGHT + 2.0 * (SKIN + FEET_TOLERANCE)
	var padded_transform: Transform3D = Transform3D(Basis.IDENTITY, actor.global_position + Vector3.UP * CAPSULE_CENTER_Y)
	var world: World3D = get_world_3d()
	var space: PhysicsDirectSpaceState3D = world.direct_space_state
	report["actual_actor_at_query"] = _native_value(actor)
	report["actual_body_at_query"] = _native_value(body)
	report["excluded_native_bodies"] = excluded_nodes
	report["collision_mask"] = 1
	report["collide_with_areas"] = false
	report["maximum_hits_per_query"] = MAX_OVERLAP_HITS
	report["actual_player_capsule"] = _zero_motion_overlap(space, body.shape, body.global_transform, excluded)
	report["scheduler_expanded_capsule"] = _zero_motion_overlap(space, padded, padded_transform, excluded)
	report["queried"] = true
	return report


func _zero_motion_overlap(space: PhysicsDirectSpaceState3D, shape: Shape3D, at: Transform3D, excluded: Array[RID]) -> Dictionary:
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	query.collide_with_areas = false
	query.exclude = excluded
	query.transform = at
	query.motion = Vector3.ZERO
	var hits: Array[Dictionary] = space.intersect_shape(query, MAX_OVERLAP_HITS)
	var rows: Array = []
	for hit: Dictionary in hits:
		var row: Dictionary = {"native_result": _native_value(hit)}
		var collider_value: Variant = hit.get("collider")
		var index_value: Variant = hit.get("shape")
		if is_instance_valid(collider_value) and collider_value is CollisionObject3D and index_value is int and index_value >= 0:
			var owner_id: int = collider_value.shape_find_owner(index_value)
			row["shape_index"] = index_value
			row["shape_owner_id"] = owner_id
			row["actual_shape_owner"] = _native_value(collider_value.shape_owner_get_owner(owner_id))
			row["actual_shape_owner_transform"] = _native_value(collider_value.shape_owner_get_transform(owner_id))
		rows.append(row)
	return {"shape": _native_value(shape), "transform": _native_value(at), "zero_motion": _native_value(query.motion), "hits": rows, "overlap": not hits.is_empty(), "result_bound_reached": hits.size() == MAX_OVERLAP_HITS}
