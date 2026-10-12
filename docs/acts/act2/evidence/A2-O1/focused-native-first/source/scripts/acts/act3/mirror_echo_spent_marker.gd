class_name CinderAct3MirrorEchoSpentMarker
extends Node3D
## Original static spent annotation beside the retained ordinary knot.
## Preconstruct outside PorcelainOwnSequence; visibility derives only from the
## actual HP/dead transaction. No attack, interaction, collision or clock.

const MarkerValue = preload("res://scripts/campaign/snapshot_codec.gd")
const MarkerExact = preload("res://scripts/combat/authored_enemy_sequence.gd")
const API: String = "act3-mirror-echo-spent-marker-1"
const ROOT_NAME: String = "SpentEchoMarker"
const OWNER_PATH: String = "res://scripts/acts/act3/mirror_echo.gd"
const SCRIPT_PATH: String = "res://scripts/acts/act3/mirror_echo_spent_marker.gd"
const PART_NAMES: Array[String] = ["SeveredBase", "DetachedChip", "LooseFragment"]

var last_error: String = ""
var _construction_error: String = ""
var _native_parent: Node3D
var _native_world: World3D
var _native_script: Script
var _native_owner_script: Script
var _parts: Array[Dictionary] = []
var _descriptor: Dictionary = {}
var _applied_dead: bool = false


func _init() -> void:
	name = ROOT_NAME
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func _ready() -> void:
	if transform != Transform3D.IDENTITY or get_child_count() != 0 or not get_parent() is Node3D:
		_construction_error = "Preconstruct one empty fixed marker directly under the actual source"
		return
	_native_parent = get_parent() as Node3D
	_native_owner_script = _native_parent.get_script() as Script
	_native_script = get_script() as Script
	_native_world = get_world_3d()
	if _native_owner_script == null or _native_owner_script.resource_path != OWNER_PATH or _native_script == null or _native_script.resource_path != SCRIPT_PATH:
		_construction_error = "Actual owned source and spent-marker scripts required"
		return
	# Unequal, separated chips: neither a closed bracket/ring nor an opening cue.
	# Source, filled porcelain body and the original fixed knot remain untouched.
	_box("SeveredBase", Vector3(0.20, 0.07, 0.17), Vector3(0.55, 0.035, 0.07), 0.0, Color(0.24, 0.18, 0.30, 1.0))
	_box("DetachedChip", Vector3(0.08, 0.19, 0.10), Vector3(0.54, 0.245, 0.06), -18.0, Color(0.50, 0.47, 0.58, 1.0))
	_box("LooseFragment", Vector3(0.12, 0.08, 0.13), Vector3(0.735, 0.045, 0.10), 0.0, Color(0.37, 0.31, 0.44, 1.0))
	_descriptor = _current_descriptor()
	if _descriptor.is_empty():
		_construction_error = "Complete immutable marker tree/resources could not be captured"


func _box(label: String, size: Vector3, offset: Vector3, roll_degrees: float, color: Color) -> void:
	var visual := MeshInstance3D.new()
	visual.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	material.no_depth_test = false
	material.albedo_color = color
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.position = offset
	visual.rotation.z = deg_to_rad(roll_degrees)
	visual.layers = 1
	add_child(visual)
	_parts.append({"node": visual, "mesh": mesh, "material": material, "transform": visual.transform})


## Pure fixed-resource custody. Root visibility is deliberately absent from
## the descriptor; fresh alive/dead recipients share the same native recipe.
func immutable_descriptor() -> Dictionary:
	return _descriptor.duplicate(true) if _immutable_error().is_empty() else {}


func descriptor_error(saved: Dictionary) -> String:
	var error: String = _immutable_error()
	if not error.is_empty():
		return error
	if not MarkerValue.value_error(saved).is_empty() or not MarkerExact.exact_equal(saved, _descriptor):
		return "Saved spent-marker descriptor differs from the complete fixed native recipe"
	return ""


## Invoke after actual accepted HP/dead/group assignment, before source
## observers or final quiet restore checks. This never repairs an old mismatch.
func apply_actual_dead(actual_dead: bool) -> bool:
	var error: String = _immutable_error()
	if error.is_empty():
		error = _physical_error(actual_dead)
	if error.is_empty() and visible != _applied_dead:
		error = "Existing spent-marker visibility was tampered; repaint is refused"
	if not error.is_empty():
		last_error = error
		return false
	# Ancestor visibility may notify children. Block every retained marker signal
	# and preserve the original flags; no source/action/cue callback is emitted.
	var nodes: Array[Node] = [self]
	var flags: Array[bool] = []
	for spec: Dictionary in _parts:
		nodes.append(spec.node)
	for node: Node in nodes:
		flags.append(node.is_blocking_signals())
		node.set_block_signals(true)
	visible = actual_dead
	_applied_dead = actual_dead
	for index: int in range(nodes.size()):
		nodes[index].set_block_signals(flags[index])
	last_error = native_error(actual_dead)
	return last_error.is_empty()


## Pure actual-state inspection. Playback complete/cancelled is never death.
func native_error(actual_dead: bool) -> String:
	var error: String = _immutable_error()
	if error.is_empty():
		error = _physical_error(actual_dead)
	if not error.is_empty():
		return error
	if _applied_dead != actual_dead or visible != actual_dead or is_visible_in_tree() != actual_dead:
		return "Spent marker must be hidden alive and visible only for actual HP0/dead"
	return ""


## Actual complete native render AABB only, not collision or hit authority.
## The hidden living marker contributes no required current-view corners.
func framing_points(actual_dead: bool) -> Dictionary:
	var error: String = native_error(actual_dead)
	if not error.is_empty():
		return {"error": error, "points": [], "bounds": AABB()}
	if not actual_dead:
		return {"error": "", "points": [], "bounds": AABB()}
	var corners: Array[Vector3] = []
	for spec: Dictionary in _parts:
		var visual: MeshInstance3D = spec.node
		_append_box(corners, visual.mesh.get_aabb(), visual.global_transform)
	var low: Vector3 = corners[0]
	var high: Vector3 = corners[0]
	for point: Vector3 in corners:
		if not point.is_finite():
			return {"error": "Finite complete spent-marker native corners required", "points": [], "bounds": AABB()}
		low = low.min(point)
		high = high.max(point)
	var bounds := AABB(low, high - low)
	var points: Array[Vector3] = []
	_append_box(points, bounds, Transform3D.IDENTITY)
	return {"error": "", "points": points, "bounds": bounds}


func _physical_error(actual_dead: bool) -> String:
	var current_hp: Variant = _native_parent.get("hp")
	var maximum_hp: Variant = _native_parent.get("max_hp")
	var current_dead: Variant = _native_parent.get("dead")
	if not current_hp is float or not maximum_hp is float or not current_dead is bool or not is_finite(current_hp) or not is_finite(maximum_hp) or maximum_hp <= 0.0 or current_hp < 0.0 or current_hp > maximum_hp or current_dead != actual_dead or actual_dead != (current_hp == 0.0) or _native_parent.is_in_group("enemies") == actual_dead:
		return "Derive spent presentation only from actual validated HP/dead/target retirement"
	return ""


func _immutable_error() -> String:
	if not _construction_error.is_empty():
		return _construction_error
	if not is_inside_tree() or not is_node_ready() or is_queued_for_deletion() or _descriptor.is_empty() or not is_instance_valid(_native_parent) or _native_parent.is_queued_for_deletion() or not _native_parent.is_inside_tree() or get_parent() != _native_parent or get_world_3d() != _native_world or _native_parent.get_world_3d() != _native_world:
		return "Retained live source/marker parent and native world required"
	if get_script() != _native_script or _native_parent.get_script() != _native_owner_script or name != ROOT_NAME or transform != Transform3D.IDENTITY or global_basis != Basis.IDENTITY or not _native_parent.is_visible_in_tree() or process_mode != Node.PROCESS_MODE_DISABLED or is_processing() or is_physics_processing() or not get_groups().is_empty() or get_child_count() != PART_NAMES.size() or _parts.size() != PART_NAMES.size():
		return "Fixed nonprocessing marker root/tree/pose/script policy changed"
	for index: int in range(_parts.size()):
		var spec: Dictionary = _parts[index]
		var visual: MeshInstance3D = spec.node
		if not is_instance_valid(visual) or visual.is_queued_for_deletion() or get_child(index) != visual or visual.get_parent() != self or String(visual.name) != PART_NAMES[index] or visual.transform != spec.transform or visual.mesh != spec.mesh or visual.material_override != spec.material or visual.material_overlay != null or not visual.visible or visual.get_script() != null or not is_instance_valid(spec.mesh) or spec.mesh.get_script() != null or not is_instance_valid(spec.material) or spec.material.get_script() != null or visual.get_child_count() != 0 or not visual.get_groups().is_empty() or visual.layers != 1:
			return "Fixed native spent-marker part/resource identity changed"
	var current: Dictionary = _current_descriptor()
	return "" if not current.is_empty() and MarkerExact.exact_equal(current, _descriptor) else "Spent-marker native geometry, material or draw policy changed"


func _current_descriptor() -> Dictionary:
	if not is_instance_valid(_native_parent) or _parts.size() != PART_NAMES.size():
		return {}
	var root_hash: String = _storage_hash(self, ["visible", "transform", "position", "rotation", "rotation_degrees", "quaternion", "basis", "scale", "owner", "name", "unique_name_in_owner"])
	if root_hash.is_empty():
		return {}
	var parts: Array[Dictionary] = []
	for spec: Dictionary in _parts:
		var visual: MeshInstance3D = spec.node
		if not is_instance_valid(visual) or not visual.mesh is BoxMesh or not visual.material_override is StandardMaterial3D:
			return {}
		var mesh: BoxMesh = visual.mesh
		var material: StandardMaterial3D = visual.material_override
		var arrays: Array = []
		for surface: int in range(mesh.get_surface_count()):
			if mesh.surface_get_material(surface) != null:
				return {}
			arrays.append(mesh.surface_get_arrays(surface))
		var node_hash: String = _storage_hash(visual, ["transform", "position", "rotation", "rotation_degrees", "quaternion", "basis", "scale", "mesh", "material_override", "owner", "name", "unique_name_in_owner"])
		var mesh_hash: String = _storage_hash(mesh, [])
		var material_hash: String = _storage_hash(material, [])
		var array_hash: String = _hash_bytes(var_to_bytes(arrays))
		if node_hash.is_empty() or mesh_hash.is_empty() or material_hash.is_empty() or array_hash.is_empty():
			return {}
		parts.append({"path": String(get_path_to(visual)), "kind": "BoxMesh", "size": MarkerValue.vector3(mesh.size), "position": MarkerValue.vector3(visual.position), "basis": _basis(visual.basis), "color": [material.albedo_color.r, material.albedo_color.g, material.albedo_color.b, material.albedo_color.a], "node": node_hash, "mesh": mesh_hash, "arrays": array_hash, "material": material_hash})
	return {"api_revision": API, "marker_script": SCRIPT_PATH, "owner_script": OWNER_PATH, "root_path": String(_native_parent.get_path_to(self)), "position": MarkerValue.vector3(position), "basis": _basis(basis), "node": root_hash, "parts": parts}


static func _storage_hash(object: Object, excluded: Array[String]) -> String:
	var values: Array = []
	for info: Dictionary in object.get_property_list():
		var key: String = String(info.name)
		if (int(info.usage) & PROPERTY_USAGE_STORAGE) == 0 or (int(info.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 or key.begins_with("metadata/") or key in excluded or key in ["resource_name", "resource_path", "resource_local_to_scene", "script"]:
			continue
		var value: Variant = object.get(key)
		if value is Object and is_instance_valid(value):
			return "" # No handle/fresh instance identity enters transport.
		values.append([key, value])
	return _hash_bytes(var_to_bytes(values))


static func _hash_bytes(bytes: PackedByteArray) -> String:
	var digest := HashingContext.new()
	if digest.start(HashingContext.HASH_SHA256) != OK or digest.update(bytes) != OK:
		return ""
	return digest.finish().hex_encode()


static func _basis(value: Basis) -> Array:
	return [MarkerValue.vector3(value.x), MarkerValue.vector3(value.y), MarkerValue.vector3(value.z)]


static func _append_box(points: Array[Vector3], bounds: AABB, at: Transform3D) -> void:
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]:
				points.append(at * Vector3(x, y, z))
