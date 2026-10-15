class_name Act1RoyalRehearsalArt
extends Node3D
## O3-only clockless bell/quiet station ornament, authored from G19/G15.
## No collision, signals, cue, attack, admission, progress or timing authority.
## Source authored; parser/native/portrait validation is owned by the level owner.

const Layout = preload("res://scripts/acts/act1/royal_rehearsal_layout.gd")
const BELL_STATES: Array[String] = ["available", "active", "spent"]
const API_REVISION: String = "act1-rehearsal-art-1"
# Keep the opaque stand beside the contact approach and player billboard.
const BELL_ART_OFFSET: Vector3 = Vector3(-1.0, 0, 0)

var _level: Node3D
var _script: Script
var _nodes: Array[Dictionary] = []
var _meshes: Array[Dictionary] = []
var _landmarks: Dictionary = {}
var _poses: Dictionary = {}
var _markers: Dictionary = {}
var _bell_state: String = "available"
var _exercise_index: int = 0
var _markers_visible: bool = true
var _custody_ready: bool = false


static func build_geometry_art(level: Node3D) -> Node3D:
	if not is_instance_valid(level) or not level.is_inside_tree() or level.is_queued_for_deletion() or level.get_node_or_null("RehearsalArt") != null: return null
	if level.transform != Transform3D.IDENTITY or level.global_transform != Transform3D.IDENTITY or level.is_set_as_top_level(): return null
	var art := Act1RoyalRehearsalArt.new()
	art.name = "RehearsalArt"
	art._level = level
	art._script = art.get_script()
	art._build()
	# Preserve the off-tree authored composition before child-enter callbacks.
	art._retain_tree()
	art._custody_ready = true
	level.add_child(art)
	if not is_instance_valid(art): return null
	if not art.binding_error().is_empty():
		art.free()
		return null
	return art


func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED


func _build() -> void:
	var bell := _group(self, "PracticeBell", Layout.BELL_POSITION + BELL_ART_OFFSET)
	_landmarks["bell"] = bell
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	for side: float in [-1.0, 1.0]:
		_box(vertices, colors, Vector3(side * 0.43, 0.055, 0), Vector3(0.14, 0.11, 0.4), 0.22)
		_box(vertices, colors, Vector3(side * 0.43, 0.73, 0), Vector3(0.11, 1.36, 0.12), 0.25)
		_box(vertices, colors, Vector3(side * 0.414, 0.73, 0.065), Vector3(0.028, 1.29, 0.014), 0.43)
		_box(vertices, colors, Vector3(side * 0.43, 1.40, 0.077), Vector3(0.047, 0.06, 0.018), 0.55)
	_box(vertices, colors, Vector3(0, 1.43, 0), Vector3(1.0, 0.14, 0.16), 0.27)
	_box(vertices, colors, Vector3(0, 1.485, 0.086), Vector3(0.94, 0.026, 0.018), 0.46)
	_box(vertices, colors, Vector3(0, 1.29, 0), Vector3(0.055, 0.16, 0.065), 0.19)
	_mesh(bell, "JoinedWoodenStand", vertices, colors)
	for state: String in BELL_STATES:
		var pose := _group(bell, state.capitalize(), Vector3.ZERO)
		_poses[state] = pose
		_build_bell_pose(pose, state)
		pose.visible = state == _bell_state
	for id: String in Layout.SOURCE_IDS:
		var marker := _group(self, id, Layout.SOURCES[id].position + Vector3(0, 0.012, 0))
		_markers[id] = marker
		_landmarks["marker:" + id] = marker
		_build_marker(marker)
		marker.visible = int(Layout.SOURCES[id].exercise) == _exercise_index


func _build_bell_pose(parent: Node3D, state: String) -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	# Abrupt tier changes make a stepped flared lip; the underside stays dark.
	var profile: Array[Vector2] = [Vector2(1.24, 0.065), Vector2(1.17, 0.065), Vector2(1.17, 0.13), Vector2(1.09, 0.16), Vector2(0.85, 0.20), Vector2(0.78, 0.24), Vector2(0.75, 0.29), Vector2(0.69, 0.29)]
	for tier: int in range(profile.size() - 1):
		for facet: int in 12:
			var a: float = TAU * float(facet) / 12.0
			var b: float = TAU * float(facet + 1) / 12.0
			var upper: Vector2 = profile[tier]
			var lower: Vector2 = profile[tier + 1]
			var p := Vector3(cos(a) * upper.y, upper.x, sin(a) * upper.y * 0.55)
			var q := Vector3(cos(b) * upper.y, upper.x, sin(b) * upper.y * 0.55)
			var r := Vector3(cos(b) * lower.y, lower.x, sin(b) * lower.y * 0.55)
			var s := Vector3(cos(a) * lower.y, lower.x, sin(a) * lower.y * 0.55)
			var silver: float = (0.66 if facet % 3 else 0.78) if state != "spent" else (0.43 if facet % 3 else 0.51)
			if tier == 6: silver = 0.79 if state != "spent" else 0.54
			_triangle(vertices, colors, p, q, r, silver)
			_triangle(vertices, colors, p, r, s, silver)
	_disc(vertices, colors, Vector3(0, 0.688, 0), 0.264, 0.55, 0.17)
	var clapper_x: float = 0.11 if state == "active" else 0.0
	_box(vertices, colors, Vector3(clapper_x, 0.665, 0), Vector3(0.045, 0.15, 0.045), 0.22)
	_box(vertices, colors, Vector3(clapper_x, 0.60, 0), Vector3(0.09, 0.07, 0.07), 0.49)
	if state == "spent":
		# A coarse dark felt mute is a state pose, never a new hit target/cue.
		_box(vertices, colors, Vector3(0, 0.875, 0.124), Vector3(0.40, 0.13, 0.026), 0.25)
	if state == "active":
		var pivot := Vector3(0, 1.25, 0)
		var lean := Basis(Vector3.FORWARD, deg_to_rad(10.0))
		for index: int in vertices.size(): vertices[index] = pivot + lean * (vertices[index] - pivot)
	_mesh(parent, "SteppedBellAndClapper", vertices, colors)


func _build_marker(parent: Node3D) -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	# Closed subdued discs: no segmented warning rim, countdown or active fill.
	_disc(vertices, colors, Vector3.ZERO, 0.40, 1.0, 0.37)
	_disc(vertices, colors, Vector3(0, 0.001, 0), 0.34, 1.0, 0.40)
	for index: int in 10:
		var a: float = -PI * 0.5 + float(index) * PI / 5.0
		var b: float = -PI * 0.5 + float(index + 1) * PI / 5.0
		var p := Vector3(cos(a) * (0.22 if index % 2 == 0 else 0.095), 0.002, sin(a) * (0.22 if index % 2 == 0 else 0.095))
		var q := Vector3(cos(b) * (0.095 if index % 2 == 0 else 0.22), 0.002, sin(b) * (0.095 if index % 2 == 0 else 0.22))
		_triangle(vertices, colors, Vector3(0, 0.002, 0), p, q, 0.31)
	_mesh(parent, "QuietStarDisc", vertices, colors)


func apply_state(bell_state: String, exercise_index: int, markers_visible: bool) -> void:
	# Quiet and idempotent, including restoration: no emitted signal or clock.
	if bell_state not in BELL_STATES or exercise_index < 0 or exercise_index >= Layout.EXERCISE_IDS.size() or not binding_error().is_empty(): return
	_bell_state = bell_state
	_exercise_index = exercise_index
	_markers_visible = markers_visible
	for state: String in BELL_STATES: (_poses[state] as Node3D).visible = state == _bell_state
	for id: String in Layout.SOURCE_IDS: (_markers[id] as Node3D).visible = _markers_visible and int(Layout.SOURCES[id].exercise) == _exercise_index


func presentation_state() -> Dictionary:
	return {"api_revision": API_REVISION, "bell_state": _bell_state, "exercise_index": _exercise_index, "markers_visible": _markers_visible}


func binding_error() -> String:
	if not _custody_ready or not is_instance_valid(_level) or not _level.is_inside_tree() or _level.is_queued_for_deletion(): return "Rehearsal art requires its retained live level"
	if get_parent() != _level or _level.get_node_or_null("RehearsalArt") != self or get_world_3d() != _level.get_world_3d() or get_script() != _script: return "Rehearsal art level/world/script binding changed"
	if _level.transform != Transform3D.IDENTITY or _level.global_transform != Transform3D.IDENTITY or _level.is_set_as_top_level(): return "Rehearsal art requires the authored level frame"
	if _bell_state not in BELL_STATES or _exercise_index < 0 or _exercise_index >= Layout.EXERCISE_IDS.size(): return "Rehearsal art pose is invalid"
	if _poses.size() != BELL_STATES.size() or _markers.size() != Layout.SOURCE_IDS.size() or _landmarks.size() != Layout.SOURCE_IDS.size() + 1 or _landmarks.get("bell") != _level.get_node_or_null("RehearsalArt/PracticeBell"): return "Retain the authored rehearsal landmark set"
	for state: String in BELL_STATES:
		if not is_instance_valid(_poses.get(state)) or _poses[state] != _level.get_node_or_null("RehearsalArt/PracticeBell/" + state.capitalize()): return "Retained bell pose is unavailable or substituted"
	for id: String in Layout.SOURCE_IDS:
		if not is_instance_valid(_markers.get(id)) or _markers[id] != _level.get_node_or_null("RehearsalArt/" + id) or _landmarks.get("marker:" + id) != _markers[id]: return "Retained formation marker is unavailable or substituted"
	for record: Dictionary in _nodes:
		if not is_instance_valid(record.node): return "Required rehearsal art node is unavailable"
		var node: Node3D = record.node
		var visible_expected: bool = true
		var tree_visible_expected: bool = true
		for state: String in BELL_STATES:
			if node == _poses[state]: visible_expected = state == _bell_state
			if node == _poses[state] or (_poses[state] as Node3D).is_ancestor_of(node): tree_visible_expected = state == _bell_state
		for id: String in Layout.SOURCE_IDS:
			var showing: bool = _markers_visible and int(Layout.SOURCES[id].exercise) == _exercise_index
			if node == _markers[id]: visible_expected = showing
			if node == _markers[id] or (_markers[id] as Node3D).is_ancestor_of(node): tree_visible_expected = showing
		if not node.is_inside_tree() or node.is_queued_for_deletion() or node.get_parent() != record.parent or _level.get_node_or_null(record.path) != node or node.get_children() != record.children or node.get_script() != record.script: return "Rehearsal art tree composition changed"
		if node.transform != record.transform or node.global_transform != record.global_transform or node.is_set_as_top_level() or node.process_mode != Node.PROCESS_MODE_DISABLED or node.is_processing() or node.is_physics_processing() or node.visible != visible_expected or node.is_visible_in_tree() != tree_visible_expected: return "Rehearsal art frame, clockless mode or pose changed"
	for record: Dictionary in _meshes:
		var node: MeshInstance3D = record.node
		if not is_instance_valid(record.mesh) or not is_instance_valid(record.material) or node.mesh != record.mesh or node.material_override != record.material or node.material_overlay != null or _properties(node, ["visible"]) != record.properties: return "Rehearsal mesh renderer binding changed"
		if record.mesh.get_script() != null or record.material.get_script() != null or _properties(record.material) != record.material_properties or _mesh_bytes(record.mesh) != record.geometry: return "Rehearsal authored geometry/material changed"
		for index: int in node.get_surface_override_material_count():
			if node.get_surface_override_material(index) != null: return "Rehearsal surface material override is unsupported"
	return ""


func landmark_world_corners(id: String) -> Array:
	if not _landmarks.has(id) or not binding_error().is_empty(): return [Vector3.INF]
	var root: Node3D = _landmarks[id]
	if not root.is_visible_in_tree(): return []
	var points: Array[Vector3] = []
	for record: Dictionary in _meshes:
		var node: MeshInstance3D = record.node
		if root.is_ancestor_of(node) and node.is_visible_in_tree(): points.append_array(_box_points(node.get_aabb(), node.global_transform))
	if points.is_empty(): return [Vector3.INF]
	var bounds := AABB(points[0], Vector3.ZERO)
	for point: Vector3 in points: bounds = bounds.expand(point)
	return _box_points(bounds, Transform3D.IDENTITY)


func _retain_tree() -> void:
	var nodes: Array[Node3D] = [self]
	for raw: Node in find_children("*", "Node3D", true, false): nodes.append(raw as Node3D)
	for node: Node3D in nodes:
		var frame := Transform3D.IDENTITY
		var chain: Array[Transform3D] = []
		var cursor: Node3D = node
		while cursor != self:
			chain.push_front(cursor.transform)
			cursor = cursor.get_parent() as Node3D
		for local_frame: Transform3D in chain: frame = frame * local_frame
		_nodes.append({"node": node, "parent": _level if node == self else node.get_parent(), "path": NodePath("RehearsalArt" if node == self else "RehearsalArt/" + String(get_path_to(node))), "script": node.get_script(), "children": node.get_children(), "transform": node.transform, "global_transform": frame})
		if node is MeshInstance3D:
			var mesh := node as MeshInstance3D
			_meshes.append({"node": mesh, "mesh": mesh.mesh, "material": mesh.material_override, "properties": _properties(mesh, ["visible"]), "material_properties": _properties(mesh.material_override), "geometry": _mesh_bytes(mesh.mesh)})


static func _properties(object: Object, excluded: Array[String] = []) -> PackedByteArray:
	var values: Array = []
	for info: Dictionary in object.get_property_list():
		var key: String = String(info.name)
		if (int(info.usage) & PROPERTY_USAGE_STORAGE) == 0 or (int(info.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 or key in excluded: continue
		var value: Variant = object.get(key)
		values.append([key, ["object", value.get_instance_id()] if value is Object and is_instance_valid(value) else value])
	return var_to_bytes(values)


static func _mesh_bytes(mesh: Mesh) -> PackedByteArray:
	var surfaces: Array = []
	for index: int in mesh.get_surface_count():
		if mesh.surface_get_material(index) != null: return PackedByteArray()
		surfaces.append(mesh.surface_get_arrays(index))
	return var_to_bytes([_properties(mesh), mesh.get_aabb(), surfaces])


static func _box_points(bounds: AABB, frame: Transform3D) -> Array:
	var points: Array[Vector3] = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]: points.append(frame * Vector3(x, y, z))
	return points


func _group(parent: Node3D, node_name: String, origin: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = node_name
	node.position = origin
	node.process_mode = Node.PROCESS_MODE_DISABLED
	parent.add_child(node)
	return node


func _mesh(parent: Node3D, node_name: String, vertices: PackedVector3Array, colors: PackedColorArray) -> void:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.no_depth_test = false
	material.roughness = 1.0
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.process_mode = Node.PROCESS_MODE_DISABLED
	parent.add_child(node)


static func _triangle(vertices: PackedVector3Array, colors: PackedColorArray, a: Vector3, b: Vector3, c: Vector3, silver: float) -> void:
	for point: Vector3 in [a, b, c]:
		vertices.append(point)
		colors.append(Color(silver, silver, silver))


static func _box(vertices: PackedVector3Array, colors: PackedColorArray, origin: Vector3, size: Vector3, silver: float) -> void:
	var points: Array[Vector3] = []
	for x: float in [-0.5, 0.5]:
		for y: float in [-0.5, 0.5]:
			for z: float in [-0.5, 0.5]: points.append(origin + size * Vector3(x, y, z))
	for face: Array in [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]]:
		_triangle(vertices, colors, points[face[0]], points[face[1]], points[face[2]], silver)
		_triangle(vertices, colors, points[face[0]], points[face[2]], points[face[3]], silver)


static func _disc(vertices: PackedVector3Array, colors: PackedColorArray, origin: Vector3, radius: float, depth_ratio: float, silver: float) -> void:
	for index: int in 24:
		var a: float = TAU * float(index) / 24.0
		var b: float = TAU * float(index + 1) / 24.0
		_triangle(vertices, colors, origin, origin + Vector3(cos(a) * radius, 0, sin(a) * radius * depth_ratio), origin + Vector3(cos(b) * radius, 0, sin(b) * radius * depth_ratio), silver)
