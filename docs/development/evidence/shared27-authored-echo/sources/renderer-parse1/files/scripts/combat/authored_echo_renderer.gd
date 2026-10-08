class_name CinderAuthoredEchoRenderer
extends RefCounted
## Native visual custody only. The parent authenticates actual enemy/source,
## definition, cycle, world, lease and physical contact. No Player art or gear.
## First support is a fixed primitive silhouette; only its root travels/yaws.

const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const API_REVISION: String = "authored-echo-renderer-1"
const MAX_NODES: int = 32
const MAX_VISUALS: int = 16
const MAX_VERTICES: int = 16384
const MAX_COORDINATE: float = 512.0
# Derived native float32 silhouette/facing measurements only. Copied resource,
# tree, transforms and accepted world-position identity always remain exact.
const NATIVE_MEASUREMENT_EPS: float = 0.000001
const BINDING_KEYS: Array[String] = ["api_revision", "presentation", "required_visuals"]
const POSE_KEYS: Array[String] = ["position", "direction", "action", "progress"]

var last_error: String = ""
var _bound: Dictionary = {}
var _busy: bool = false
var _fault: String = ""


func bind(owner: Node3D, renderer: Node3D, definition: Dictionary) -> bool:
	if _busy or not _bound.is_empty():
		return _reject("Bind one fresh authored renderer guard only")
	_busy = true
	var accepted: bool = _bind_candidate(owner, renderer, definition)
	_busy = false
	return accepted


func _bind_candidate(owner: Node3D, renderer: Node3D, definition: Dictionary) -> bool:
	var error: String = _definition_error(definition)
	if not error.is_empty():
		return _reject(error)
	if not _live(owner) or not _live(renderer) or owner == renderer or not owner.is_ancestor_of(renderer) or owner.get_world_3d() != renderer.get_world_3d() or not owner.has_method("get_authored_echo_renderer") or not renderer.has_method("get_authored_echo_render_bindings") or not renderer.has_method("present_authored_echo_pose"):
		return _reject("Actual live source-owned renderer and native hooks required")
	# Getter hooks are trusted pure source APIs; recheck handles after each call.
	var actual: Variant = owner.call("get_authored_echo_renderer")
	if not _live(owner) or not _live(renderer) or not _live(actual) or actual != renderer:
		return _reject("Actual source renderer binding differs or was freed")
	var bindings: Variant = renderer.call("get_authored_echo_render_bindings")
	if not _live(owner) or not _live(renderer):
		return _reject("Renderer binding hook invalidated a native owner")
	error = _bindings_error(bindings, definition.presentation)
	if not error.is_empty():
		return _reject(error)
	if not owner.is_visible_in_tree() or not renderer.is_visible_in_tree() or renderer.global_position != owner.global_position or not _yaw_basis(renderer.global_basis):
		return _reject("Fresh renderer must be visible at the actual fixed-knot foot pivot with unit yaw basis")
	var tree: Dictionary = _collect_tree(renderer, bindings.required_visuals, float(definition.travel_clearance.radius_m), float(definition.travel_clearance.height_m))
	if not tree.get("accepted", false):
		return _reject(tree.reason)
	# Revalidate native identities after every getter/mesh inspection before
	# committing; no caller callback, signal or yield is introduced here.
	if not _live(owner) or not _live(renderer) or renderer.get_world_3d() != owner.get_world_3d() or renderer.global_position != owner.global_position:
		return _reject("Source/root custody changed during renderer preflight")
	_bound = {"owner": weakref(owner), "renderer": weakref(renderer), "owner_parent": weakref(owner.get_parent()), "renderer_parent": weakref(renderer.get_parent()), "world": weakref(renderer.get_world_3d()), "owner_script": owner.get_script(), "renderer_script": renderer.get_script(), "presentation": definition.presentation.duplicate(true), "definition_wire": _definition_wire(definition), "root_transform": renderer.global_transform, "tree": tree.nodes, "visuals": tree.visuals, "radius_m": float(definition.travel_clearance.radius_m), "height_m": float(definition.travel_clearance.height_m)}
	_fault = ""
	error = _current_error(false)
	if not error.is_empty():
		_bound = {}
		return _reject(error)
	last_error = ""
	return true


func current_error() -> String:
	if _busy:
		return "Authored renderer presentation is in progress"
	return _current_error(false)


func present(pose: Dictionary, quiet: bool) -> bool:
	if _busy:
		return _reject("Authored renderer cannot present recursively")
	var error: String = _current_error(false)
	if not error.is_empty():
		_fault = error
		return _reject(error)
	# Empty terminal/idle view retains the actual visible fixed-knot/root.
	# It neither hides nor heals required presentation, and invokes no hook.
	if pose.is_empty():
		last_error = ""
		return true
	error = _pose_error(pose)
	if not error.is_empty():
		return _reject(error)
	var renderer: Node3D = _bound.renderer.get_ref()
	var owner: Node3D = _bound.owner.get_ref()
	var blocked: Array = []
	_busy = true
	if quiet:
		var nodes: Array = [owner]
		for receipt: Dictionary in _bound.tree:
			nodes.append(receipt.node.get_ref())
		for raw: Variant in nodes:
			if is_instance_valid(raw):
				blocked.append({"node": weakref(raw), "was_blocked": raw.is_blocking_signals()})
				raw.set_block_signals(true)
	var accepted: Variant = renderer.call("present_authored_echo_pose", pose.duplicate(true), quiet)
	for receipt: Dictionary in blocked:
		var raw: Variant = receipt.node.get_ref()
		if is_instance_valid(raw):
			raw.set_block_signals(receipt.was_blocked)
	# Only this authorized root movement may differ from the prior receipt.
	# All children/resources/tree/materials must survive the hook unchanged.
	error = _current_error(true)
	if error.is_empty() and (not accepted is bool or not accepted):
		error = "Actual renderer declined authored pose"
	if error.is_empty():
		var actual_renderer: Node3D = _bound.renderer.get_ref()
		var expected_basis := Basis(Vector3.UP, atan2(float(pose.direction.x), float(pose.direction.z)))
		if var_to_bytes(actual_renderer.global_position) != var_to_bytes(pose.position) or not _basis_close(actual_renderer.global_basis, expected_basis):
			error = "Actual renderer did not retain the requested native foot pivot/yaw"
	if error.is_empty():
		_bound.root_transform = (_bound.renderer.get_ref() as Node3D).global_transform
	else:
		_fault = error
	_busy = false
	if not error.is_empty():
		return _reject(error)
	last_error = ""
	return true


func _current_error(allow_root_motion: bool) -> String:
	if _bound.is_empty():
		return "Authored renderer guard is unbound"
	if not _fault.is_empty():
		return _fault
	var owner: Variant = _bound.owner.get_ref()
	var renderer: Variant = _bound.renderer.get_ref()
	if not _live(owner) or not _live(renderer):
		return "Actual authored renderer/source is unavailable"
	if owner.get_parent() != _bound.owner_parent.get_ref() or renderer.get_parent() != _bound.renderer_parent.get_ref() or not owner.is_ancestor_of(renderer) or owner.get_world_3d() != _bound.world.get_ref() or renderer.get_world_3d() != _bound.world.get_ref() or owner.get_script() != _bound.owner_script or renderer.get_script() != _bound.renderer_script or not owner.is_visible_in_tree() or not renderer.is_visible_in_tree():
		return "Actual renderer parent/world/script/visibility custody changed"
	if not _bounded(renderer.global_position) or not _yaw_basis(renderer.global_basis) or (not allow_root_motion and var_to_bytes(renderer.global_transform) != var_to_bytes(_bound.root_transform)):
		return "Actual authored renderer root transform changed outside presentation"
	if not owner.has_method("get_authored_echo_renderer") or not renderer.has_method("get_authored_echo_render_bindings") or not renderer.has_method("present_authored_echo_pose"):
		return "Actual renderer hooks disappeared"
	var actual: Variant = owner.call("get_authored_echo_renderer")
	if not _live(owner) or not _live(renderer) or not _live(actual) or actual != renderer:
		return "Actual source changed its retained renderer"
	var bindings: Variant = renderer.call("get_authored_echo_render_bindings")
	if not _live(owner) or not _live(renderer):
		return "Renderer binding hook invalidated native custody"
	var error: String = _bindings_error(bindings, _bound.presentation)
	if not error.is_empty():
		return error
	if bindings.required_visuals.size() != _bound.visuals.size():
		return "Required renderer visual set changed"
	for index: int in range(_bound.visuals.size()):
		var receipt: Dictionary = _bound.visuals[index]
		var visual: Variant = receipt.node.get_ref()
		if not _live(visual) or bindings.required_visuals[index] != visual:
			return "Required renderer visual was lost/reordered/replaced"
	var tree: Dictionary = _collect_tree(renderer, bindings.required_visuals, _bound.radius_m, _bound.height_m)
	if not tree.get("accepted", false):
		return tree.reason
	if tree.nodes.size() != _bound.tree.size():
		return "Complete native renderer child tree changed"
	for index: int in range(tree.nodes.size()):
		var fresh: Dictionary = tree.nodes[index]
		var receipt: Dictionary = _bound.tree[index]
		if fresh.node.get_ref() != receipt.node.get_ref() or fresh.parent.get_ref() != receipt.parent.get_ref() or fresh.script != receipt.script or fresh.top_level != receipt.top_level or fresh.renderer_bytes != receipt.renderer_bytes or (index > 0 and fresh.transform_bytes != receipt.transform_bytes):
			return "Native renderer tree/script/local transform/renderer properties changed"
	for index: int in range(tree.visuals.size()):
		var fresh: Dictionary = tree.visuals[index]
		var receipt: Dictionary = _bound.visuals[index]
		if fresh.node.get_ref() != receipt.node.get_ref() or fresh.mesh != receipt.mesh or fresh.material != receipt.material or fresh.mesh_bytes != receipt.mesh_bytes or fresh.material_bytes != receipt.material_bytes:
			return "Required native renderer mesh/material identity or geometry changed"
	# Getter inspection is allowed no independent transform/visibility mutation.
	if not _live(owner) or not _live(renderer) or owner.get_parent() != _bound.owner_parent.get_ref() or renderer.get_parent() != _bound.renderer_parent.get_ref() or renderer.get_world_3d() != _bound.world.get_ref() or not renderer.is_visible_in_tree() or (not allow_root_motion and var_to_bytes(renderer.global_transform) != var_to_bytes(_bound.root_transform)):
		return "Renderer custody changed during its pure getter inspection"
	return ""


static func _collect_tree(renderer: Node3D, required: Array, radius_m: float, height_m: float) -> Dictionary:
	var pending: Array = [renderer]
	var nodes: Array = []
	var visuals: Array = []
	var mesh_nodes: Array = []
	var vertex_count: int = 0
	while not pending.is_empty():
		var raw: Variant = pending.pop_front()
		if not _live(raw) or not raw is Node3D or raw is CollisionObject3D or raw is CollisionShape3D or raw is CollisionPolygon3D or (raw != renderer and not raw is MeshInstance3D and raw.get_class() != "Node3D"):
			return _invalid("Only live primitive meshes/plain Node3D children are supported; no collision or additional draw actors")
		var node: Node3D = raw
		if nodes.size() >= MAX_NODES or not node.is_visible_in_tree() or node.get_world_3d() != renderer.get_world_3d() or (node != renderer and node.top_level):
			return _invalid("Required renderer tree exceeds bounds or lost visibility/world/inherited transform")
		nodes.append({"node": weakref(node), "parent": weakref(node.get_parent()), "script": node.get_script(), "top_level": node.top_level, "transform_bytes": var_to_bytes(node.transform), "renderer_bytes": _properties(node, ["transform", "position", "rotation", "rotation_degrees", "quaternion", "basis", "scale", "visible", "mesh", "material_override", "name", "owner", "unique_name_in_owner", "process_mode", "process_priority", "process_physics_priority"])})
		if node is MeshInstance3D:
			var visual: MeshInstance3D = node
			if not required.has(visual) or visual.mesh == null or not (visual.mesh is BoxMesh or visual.mesh is QuadMesh or visual.mesh is CapsuleMesh) or visual.mesh.get_script() != null or not visual.material_override is StandardMaterial3D or visual.material_overlay != null or visual.transparency != 0.0 or visual.visibility_range_begin != 0.0 or visual.visibility_range_end != 0.0:
				return _invalid("Every actual draw child must be an opted visible Box/Quad/Capsule with StandardMaterial3D")
			for surface: int in range(visual.get_surface_override_material_count()):
				if visual.get_surface_override_material(surface) != null:
					return _invalid("Renderer surface override material is unsupported")
			var material: StandardMaterial3D = visual.material_override
			if material.get_script() != null or material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.albedo_color.a <= 0.0 or not _finite_color(material.albedo_color) or material.no_depth_test or material.next_pass != null or material.is_grow_enabled() or material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED or material.fixed_size or material.use_fov_override or material.use_z_clip_scale or material.proximity_fade_enabled or material.distance_fade_mode != BaseMaterial3D.DISTANCE_FADE_DISABLED or material.blend_mode != BaseMaterial3D.BLEND_MODE_MIX or material.depth_test != 0 or material.stencil_mode != 0 or material.shadow_to_opacity or material.use_particle_trails or material.use_point_size or material.albedo_texture != null:
				return _invalid("Required renderer material must retain opaque depth-tested unshaded nearest policy without geometry deformation")
			var mesh_data: Array = []
			var relative: Transform3D = _relative_transform(visual, renderer)
			for surface: int in range(visual.mesh.get_surface_count()):
				if visual.mesh.surface_get_material(surface) != null:
					return _invalid("Native primitive surface material must use the retained sole override")
				var arrays: Array = visual.mesh.surface_get_arrays(surface)
				if arrays.size() != Mesh.ARRAY_MAX or not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array:
					return _invalid("Actual native primitive vertex arrays required")
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				vertex_count += vertices.size()
				if vertices.is_empty() or vertex_count > MAX_VERTICES:
					return _invalid("Native required silhouette exceeds finite vertex bounds")
				for point: Vector3 in vertices:
					var actual: Vector3 = relative * point
					if not actual.is_finite() or actual.y < -NATIVE_MEASUREMENT_EPS or actual.y > height_m + NATIVE_MEASUREMENT_EPS or sqrt(float(actual.x) * float(actual.x) + float(actual.z) * float(actual.z)) > radius_m + NATIVE_MEASUREMENT_EPS:
					return _invalid("Actual native silhouette exceeds source-owned upright travel clearance at the foot pivot")
				# Installed ed1daf0bf PrimitiveMesh uses triangles for these
				# three native classes; its primitive-type getter is not
				# script-bound on Mesh/PrimitiveMesh (only ArrayMesh).
				mesh_data.append([Mesh.PRIMITIVE_TRIANGLES, arrays, visual.mesh.surface_get_blend_shape_arrays(surface)])
			if mesh_data.is_empty():
				return _invalid("Required native primitive silhouette is empty")
			mesh_nodes.append(visual)
			visuals.append({"node": weakref(visual), "mesh": visual.mesh, "material": material, "mesh_bytes": var_to_bytes([_properties(visual.mesh, []), visual.mesh.get_aabb(), mesh_data]), "material_bytes": _properties(material, [])})
		for child: Node in node.get_children():
			pending.append(child)
		if pending.size() + nodes.size() > MAX_NODES:
			return _invalid("Complete native renderer child tree exceeds finite bounds")
	if mesh_nodes.size() != required.size():
		return _invalid("Required native visual set does not cover the exact renderer child tree")
	# Preserve caller descriptor order while the full tree retains native order.
	var ordered: Array = []
	for node: MeshInstance3D in required:
		for receipt: Dictionary in visuals:
			if receipt.node.get_ref() == node:
				ordered.append(receipt)
	return {"accepted": true, "nodes": nodes, "visuals": ordered}


static func _bindings_error(value: Variant, presentation: Dictionary) -> String:
	if not value is Dictionary or not Codec.keys_error(value, BINDING_KEYS).is_empty() or value.api_revision != API_REVISION or not value.presentation is Dictionary or not Exact.stringify(value.presentation) == Exact.stringify(presentation) or not value.required_visuals is Array or value.required_visuals.is_empty() or value.required_visuals.size() > MAX_VISUALS:
		return "Exact typed renderer presentation and bounded required native visual bindings required"
	var ids: Dictionary = {}
	for raw: Variant in value.required_visuals:
		if not _live(raw) or not raw is MeshInstance3D or ids.has(raw.get_instance_id()):
			return "Required native renderer visuals must be live unique MeshInstance3D objects"
		ids[raw.get_instance_id()] = true
	return ""


static func _definition_error(definition: Dictionary) -> String:
	if _definition_wire(definition).is_empty() or not definition.get("presentation") is Dictionary or not Codec.keys_error(definition.presentation, ["presentation_id", "presentation_revision"]).is_empty() or not definition.presentation.presentation_id is String or definition.presentation.presentation_id.is_empty() or definition.presentation.presentation_id.length() > 192 or typeof(definition.presentation.presentation_revision) != TYPE_INT or not Codec.is_integer(definition.presentation.presentation_revision, 1) or not definition.get("travel_clearance") is Dictionary or not Codec.keys_error(definition.travel_clearance, ["radius_m", "height_m"]).is_empty() or not Codec.in_range(definition.travel_clearance.get("radius_m"), 0.001, 4.0) or not Codec.in_range(definition.travel_clearance.get("height_m"), 0.001, 8.0) or float(definition.travel_clearance.height_m) < 2.0 * float(definition.travel_clearance.radius_m):
		return "Bounded closed source definition/presentation/upright travel clearance required"
	return ""


static func _definition_wire(value: Dictionary) -> String:
	# The authenticated source definition contains native vectors. This
	# bounded finite Vector3/closed-JSON view never serializes Objects.
	var budget: Array[int] = [65536]
	var encoded: Dictionary = _encode_native(value, 0, budget)
	return Exact.stringify(encoded.value) if encoded.accepted else ""


static func _encode_native(value: Variant, depth: int, budget: Array[int]) -> Dictionary:
	budget[0] -= 1
	if budget[0] < 0 or depth > 32:
		return {"accepted": false}
	if value is Vector3:
		return {"accepted": true, "value": Codec.vector3(value)} if _bounded(value) else {"accepted": false}
	if value is Array or value is Dictionary:
		if value.size() > 16384:
			return {"accepted": false}
		var result: Variant = [] if value is Array else {}
		for key: Variant in (range(value.size()) if value is Array else value.keys()):
			if value is Dictionary and not key is String:
				return {"accepted": false}
			var child: Dictionary = _encode_native(value[key], depth + 1, budget)
			if not child.accepted:
				return child
			if value is Array:
				result.append(child.value)
			else:
				result[key] = child.value
		return {"accepted": true, "value": result}
	return {"accepted": true, "value": value} if typeof(value) in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING] else {"accepted": false}


static func _pose_error(pose: Dictionary) -> String:
	if not Codec.keys_error(pose, POSE_KEYS).is_empty() or not pose.position is Vector3 or not _bounded(pose.position) or not pose.direction is Vector3 or not pose.direction.is_finite() or pose.direction.y != 0.0 or absf(float(pose.direction.length_squared()) - 1.0) > NATIVE_MEASUREMENT_EPS or pose.action not in ["idle", "dash", "enemy_slash"] or typeof(pose.progress) != TYPE_FLOAT or not Codec.in_range(pose.progress, 0.0, 1.0):
		return "Exact native authored position/direction/action/progress pose required"
	return ""


static func _relative_transform(node: Node3D, renderer: Node3D) -> Transform3D:
	var chain: Array[Transform3D] = []
	var cursor: Node3D = node
	while cursor != renderer:
		chain.push_front(cursor.transform)
		cursor = cursor.get_parent() as Node3D
	var result := Transform3D.IDENTITY
	for transform: Transform3D in chain:
		result = result * transform
	return result


static func _properties(object: Object, excluded: Array[String]) -> PackedByteArray:
	var values: Array = []
	for info: Dictionary in object.get_property_list():
		var key: String = String(info.name)
		if (int(info.usage) & PROPERTY_USAGE_STORAGE) == 0 or (int(info.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 or key.begins_with("metadata/") or key in excluded or key in ["resource_name", "resource_path", "resource_local_to_scene"]:
			continue
		var value: Variant = object.get(key)
		values.append([key, ["object", value.get_instance_id()] if value is Object and is_instance_valid(value) else value])
	return var_to_bytes(values)


static func _finite_color(value: Color) -> bool:
	return is_finite(value.r) and is_finite(value.g) and is_finite(value.b) and is_finite(value.a)


static func _yaw_basis(basis: Basis) -> bool:
	return basis.is_finite() and _basis_close(basis, Basis(Vector3.UP, atan2(float(basis.z.x), float(basis.z.z))))


static func _basis_close(left: Basis, right: Basis) -> bool:
	return left.x.distance_to(right.x) <= NATIVE_MEASUREMENT_EPS and left.y.distance_to(right.y) <= NATIVE_MEASUREMENT_EPS and left.z.distance_to(right.z) <= NATIVE_MEASUREMENT_EPS


static func _bounded(point: Vector3) -> bool:
	return point.is_finite() and absf(point.x) <= MAX_COORDINATE and absf(point.y) <= MAX_COORDINATE and absf(point.z) <= MAX_COORDINATE


static func _live(value: Variant) -> bool:
	return is_instance_valid(value) and value is Node3D and value.is_inside_tree() and value.is_node_ready() and not value.is_queued_for_deletion()


static func _invalid(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}


func _reject(reason: String) -> bool:
	last_error = reason
	return false
