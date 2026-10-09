class_name Act1SeleniteCourtArt
extends Node3D
## Original clockless court theatre. No floor/support, actor, cue or progress
## authority. G19/G15/G21/F10 inform shapes; no reference pixels are extracted.
## This first entrance composition is authored, unimported and unviewed.

const SilverFloor = preload("res://assets/acts/act1/lunar/environment/floor_silver_tile.png")
const FLOOR_SIZE: Vector3 = Vector3(14, 1, 16)
const FLOOR_TRANSFORM: Transform3D = Transform3D(Basis.IDENTITY, Vector3(0, -0.5, 0))
const FLOOR_TILE_WORLD_SIZE: float = 1.536
const LANDMARK_IDS: Array[String] = ["entrance-curtain", "curling-panels", "crescents", "floor", "radial-ornament"]
const LANDMARK_PATHS: Dictionary = {"entrance-curtain": "CourtArt/EntranceCurtain", "curling-panels": "CourtArt/CurlingPanels", "crescents": "CourtArt/Crescents", "floor": "CourtArt/QuietSilverFloorSkin", "radial-ornament": "CourtArt/QuietRadialOrnament"}

var exit_open: bool = false
var _expected_exit_open: bool = false
var _level: Node3D
var _script: Script
var _specs: Dictionary = {}
var _specs_bytes: PackedByteArray
var _floor_records: Array[Dictionary] = []
var _floor_shape_owner: int = -1
var _nodes: Array[Dictionary] = []
var _meshes: Array[Dictionary] = []
var _materials: Array[Dictionary] = []
var _landmarks: Dictionary = {}
var _blocked: Node3D
var _open: Node3D
var _custody_ready: bool = false


static func entrance_specs() -> Dictionary:
	# Each call creates a detached exact authored table, containing no nodes.
	return {"revision": 1, "id": "curtain-entrance", "floor_size": Vector2(14, 16), "floor_origin": Vector3(0, 0.002, 0), "curtain_origin": Vector3(0, 0, -5.3), "panel_origins": [Vector3(-2.85, 0, -4.9), Vector3(2.85, 0, -4.9)], "radial_origin": Vector3(-1.55, 0.008, -4.6)}


static func build_geometry_art(level: Node3D, immutable_court_specs: Dictionary = {}) -> Node3D:
	var selected: Dictionary = entrance_specs() if immutable_court_specs.is_empty() else immutable_court_specs.duplicate(true)
	if var_to_bytes(selected) != var_to_bytes(entrance_specs()) or not _entrance_error(level).is_empty(): return null
	var art := Act1SeleniteCourtArt.new()
	art.name = "CourtArt"
	art._level = level
	art._script = art.get_script()
	art._specs = selected.duplicate(true)
	art._specs_bytes = var_to_bytes(selected)
	art._retain_floor()
	art._build()
	# Retain the authored off-tree composition BEFORE native child-enter events.
	# Expected global frames are the exact local chain under an identity level.
	art._retain_tree()
	art._custody_ready = true
	level.add_child(art)
	if not is_instance_valid(art): return null
	if not art.binding_error().is_empty():
		art.free()
		return null
	return art


static func _entrance_error(level: Node3D) -> String:
	if not is_instance_valid(level) or not level.is_inside_tree() or level.is_queued_for_deletion() or level.get_node_or_null("CourtArt") != null:
		return "A fresh actual court level without CourtArt is required"
	if level.transform != Transform3D.IDENTITY or level.global_transform != Transform3D.IDENTITY or level.is_set_as_top_level():
		return "The entrance layout must retain its authored identity frame"
	var spawn := level.get_node_or_null("PlayerSpawn") as Marker3D
	var floor := level.get_node_or_null("Floor") as StaticBody3D
	var collision := level.get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
	var visual := level.get_node_or_null("Floor/QuietFloor") as MeshInstance3D
	if not is_instance_valid(spawn) or not is_instance_valid(floor) or not is_instance_valid(collision) or not is_instance_valid(visual):
		return "Actual spawn, native floor and unchanged quiet floor mesh are required"
	if spawn.get_parent() != level or spawn.transform != Transform3D(Basis.IDENTITY, Vector3(0, 0.1, 0)) or spawn.is_set_as_top_level() or spawn.get_script() != null:
		return "Entrance spawn feet must remain at (0,.1,0)"
	if floor.get_parent() != level or floor.transform != FLOOR_TRANSFORM or floor.global_transform != FLOOR_TRANSFORM or floor.is_set_as_top_level() or floor.get_script() != null or floor.collision_layer != 1 or floor.collision_mask != 0 or floor.constant_linear_velocity != Vector3.ZERO or floor.constant_angular_velocity != Vector3.ZERO or floor.physics_material_override != null:
		return "The native 14x1x16 support floor must remain static at top zero"
	if collision.get_parent() != floor or collision.get_script() != null or collision.transform != Transform3D.IDENTITY or collision.is_set_as_top_level() or collision.disabled or not collision.shape is BoxShape3D or (collision.shape as BoxShape3D).size != FLOOR_SIZE:
		return "The original solid floor BOX and local collision frame are required"
	if collision.shape.get_script() != null:
		return "The entrance support BOX must be an actual native resource"
	var owners: PackedInt32Array = floor.get_shape_owners()
	if owners.size() != 1 or floor.shape_owner_get_owner(owners[0]) != collision or floor.shape_owner_get_shape_count(owners[0]) != 1 or floor.shape_owner_get_shape(owners[0], 0) != collision.shape or floor.shape_owner_get_transform(owners[0]) != Transform3D.IDENTITY or floor.is_shape_owner_disabled(owners[0]):
		return "The actual unchanged floor shape registration is required"
	if visual.get_parent() != floor or visual.transform != Transform3D.IDENTITY or visual.is_set_as_top_level() or not visual.is_visible_in_tree() or visual.get_script() != null or not visual.mesh is BoxMesh or (visual.mesh as BoxMesh).size != FLOOR_SIZE or not visual.material_override is StandardMaterial3D or visual.material_overlay != null:
		return "The original visible quiet floor BOX must remain intact"
	var material := visual.material_override as StandardMaterial3D
	if visual.mesh.get_script() != null or visual.transparency != 0.0 or visual.layers != 1 or material.get_script() != null or material.albedo_color != Color(0.28, 0.28, 0.28, 1.0) or material.albedo_texture != null or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.no_depth_test or material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED or material.shading_mode != BaseMaterial3D.SHADING_MODE_PER_PIXEL or material.next_pass != null or material.roughness != 1.0:
		return "The original native opaque gray floor material and depth rendering are required"
	return ""


func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED


func _build() -> void:
	var plane := PlaneMesh.new()
	plane.size = _specs.floor_size
	var floor_material := _material(1.0)
	floor_material.albedo_texture = SilverFloor
	floor_material.texture_repeat = true
	floor_material.uv1_scale = Vector3(14.0 / FLOOR_TILE_WORLD_SIZE, 16.0 / FLOOR_TILE_WORLD_SIZE, 1)
	floor_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	floor_material.alpha_scissor_threshold = 0.5
	floor_material.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_OFF
	floor_material.alpha_antialiasing_edge = 0.3
	var skin := _mesh(self, "QuietSilverFloorSkin", plane, floor_material)
	skin.position = _specs.floor_origin
	_landmarks["floor"] = skin
	var panels := _group(self, "CurlingPanels", Vector3.ZERO)
	for index: int in 2:
		var panel := _group(panels, "West" if index == 0 else "East", _specs.panel_origins[index])
		_build_panel(panel, -1.0 if index == 0 else 1.0)
	_landmarks["curling-panels"] = panels
	var curtain := _group(self, "EntranceCurtain", _specs.curtain_origin)
	_build_curtain(curtain)
	_landmarks["entrance-curtain"] = curtain
	var crescents := _group(self, "Crescents", _specs.curtain_origin)
	for side: float in [-1.0, 1.0]:
		var crescent := _group(crescents, "West" if side < 0 else "East", Vector3(side * 2.24, 2.75, 0.05))
		_build_crescent(crescent, side)
	_landmarks["crescents"] = crescents
	var radial := _group(self, "QuietRadialOrnament", _specs.radial_origin)
	_build_radial(radial)
	_landmarks["radial-ornament"] = radial


func _build_panel(parent: Node3D, side: float) -> void:
	_box(parent, "PaintedFlat", Vector3(0, 1.21, 0), Vector3(0.78, 2.30, 0.10), 0.24)
	_box(parent, "PaleSideRib", Vector3(side * 0.34, 1.21, 0.062), Vector3(0.07, 2.30, 0.025), 0.66)
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	for index: int in 18:
		var a: float = float(index) * TAU * 1.15 / 18.0
		var b: float = float(index + 1) * TAU * 1.15 / 18.0
		var p := Vector2(side * cos(a) * (0.04 + index * 0.013), 0.81 + sin(a) * (0.04 + index * 0.013))
		var q := Vector2(side * cos(b) * (0.04 + (index + 1) * 0.013), 0.81 + sin(b) * (0.04 + (index + 1) * 0.013))
		_ribbon_xy(vertices, colors, uvs, p, q, 0.055, 0.067, 0.65)
	var star := PackedVector2Array()
	for index: int in 10:
		var angle: float = -PI * 0.5 + float(index) * PI / 5.0
		var radius: float = 0.29 if index % 2 == 0 else 0.125
		star.append(Vector2(cos(angle) * radius, 1.79 + sin(angle) * radius))
	_polygon_xy(vertices, colors, uvs, star, 0.068, 0.63)
	_mesh(parent, "BroadPaintedCurlAndStar", _array_mesh(vertices, colors, uvs), _vertex_material())


func _build_curtain(parent: Node3D) -> void:
	for side: float in [-1.0, 1.0]:
		var suffix: String = "West" if side < 0 else "East"
		_box(parent, "Column" + suffix, Vector3(side * 2.24, 1.22, 0), Vector3(0.24, 2.44, 0.18), 0.61)
		_box(parent, "VisibleBase" + suffix, Vector3(side * 2.24, 0.12, 0.01), Vector3(0.42, 0.24, 0.28), 0.49)
		_box(parent, "Capital" + suffix, Vector3(side * 2.24, 2.43, 0.01), Vector3(0.43, 0.16, 0.24), 0.75)
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	for index: int in 16:
		var a: float = float(index) * PI / 16.0
		var b: float = float(index + 1) * PI / 16.0
		var p := Vector3(cos(a) * 2.35, 2.35 + sin(a) * 0.79, 0.015)
		var q := Vector3(cos(b) * 2.35, 2.35 + sin(b) * 0.79, 0.015)
		var r := Vector3(cos(a) * 2.10, 2.35 + sin(a) * 0.57, 0.015)
		var s := Vector3(cos(b) * 2.10, 2.35 + sin(b) * 0.57, 0.015)
		_triangle(vertices, colors, uvs, p, q, s, 0.66 if index % 2 else 0.74)
		_triangle(vertices, colors, uvs, p, s, r, 0.66 if index % 2 else 0.74)
	_mesh(parent, "RoundedDraperyRail", _array_mesh(vertices, colors, uvs), _vertex_material())
	_blocked = _group(parent, "BlockedDrapery", Vector3.ZERO)
	_open = _group(parent, "OpenGatheredDrapery", Vector3.ZERO)
	_build_folds(_blocked, false)
	_build_folds(_open, true)
	_open.visible = false


func _build_folds(parent: Node3D, opened: bool) -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	for side: float in [-1.0, 1.0]:
		for index: int in 6:
			var width: float = 0.15 if opened else 0.32
			var x: float = side * (1.48 + index * width if opened else 0.16 + index * width)
			var bottom: float = 0.13 + 0.06 * float(index % 3)
			if opened: bottom += 0.48 * float(5 - index) / 5.0
			var top: float = 2.41 - 0.055 * float(index % 3)
			_cuboid(vertices, colors, uvs, Vector3(x, (top + bottom) * 0.5, 0.05 + float(index % 2) * 0.018), Vector3(width * 1.06, top - bottom, 0.075), 0.31 if index % 2 else 0.40)
			_cuboid(vertices, colors, uvs, Vector3(x, bottom + 0.03, 0.102), Vector3(width * 1.06, 0.055, 0.018), 0.61)
	_mesh(parent, "PaintedFolds", _array_mesh(vertices, colors, uvs), _vertex_material())


func _build_crescent(parent: Node3D, side: float) -> void:
	var polygon := PackedVector2Array()
	for index: int in 17:
		var angle: float = -PI * 0.5 + float(index) * PI / 16.0
		polygon.append(Vector2(side * cos(angle) * 0.34, sin(angle) * 0.34))
	for index: int in range(15, 0, -1):
		var angle: float = -PI * 0.5 + float(index) * PI / 16.0
		polygon.append(Vector2(side * cos(angle) * 0.10, sin(angle) * 0.34))
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	_polygon_xy(vertices, colors, uvs, polygon, 0, 0.79)
	_mesh(parent, "MoonWhiteCrescent", _array_mesh(vertices, colors, uvs), _vertex_material())


func _build_radial(parent: Node3D) -> void:
	# Flat muted ornament: no outline/countdown/fill/pulse or hit/cue authority.
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	for index: int in 20:
		var a: float = TAU * float(index) / 20.0
		var b: float = TAU * float(index + 1) / 20.0
		var radius: float = 0.54 if index % 2 == 0 else 0.39
		var p := Vector3(cos(a) * radius, 0, sin(a) * radius)
		var q := Vector3(cos(b) * (0.39 if index % 2 == 0 else 0.54), 0, sin(b) * (0.39 if index % 2 == 0 else 0.54))
		_triangle(vertices, colors, uvs, Vector3.ZERO, p, q, 0.43 if index % 2 else 0.46)
	for index: int in 10:
		var a: float = -PI * 0.5 + float(index) * PI / 5.0
		var b: float = -PI * 0.5 + float(index + 1) * PI / 5.0
		var p := Vector3(cos(a) * (0.30 if index % 2 == 0 else 0.13), 0.002, sin(a) * (0.30 if index % 2 == 0 else 0.13))
		var q := Vector3(cos(b) * (0.13 if index % 2 == 0 else 0.30), 0.002, sin(b) * (0.13 if index % 2 == 0 else 0.30))
		_triangle(vertices, colors, uvs, Vector3(0, 0.002, 0), p, q, 0.31)
	_mesh(parent, "MutedStarAndRays", _array_mesh(vertices, colors, uvs), _vertex_material())


func set_exit_open(opened: bool) -> void:
	# A supported scenic pose only. No native lease/contact/progress is touched.
	if not binding_error().is_empty(): return
	exit_open = opened
	_expected_exit_open = opened
	if is_instance_valid(_blocked): _blocked.visible = not opened
	if is_instance_valid(_open): _open.visible = opened


func binding_error() -> String:
	if not _custody_ready or not is_instance_valid(_level) or not _level.is_inside_tree() or _level.is_queued_for_deletion(): return "Retained actual court level is unavailable"
	if get_parent() != _level or _level.get_node_or_null("CourtArt") != self or not is_inside_tree() or is_queued_for_deletion() or get_world_3d() != _level.get_world_3d() or get_script() != _script:
		return "CourtArt must retain its actual level/world/script binding"
	if _level.transform != Transform3D.IDENTITY or _level.global_transform != Transform3D.IDENTITY or _level.is_set_as_top_level() or transform != Transform3D.IDENTITY or is_set_as_top_level(): return "CourtArt requires the authored identity world frames"
	if var_to_bytes(_specs) != _specs_bytes or _specs_bytes != var_to_bytes(entrance_specs()): return "Retain the exact authored entrance table"
	if exit_open != _expected_exit_open or not is_instance_valid(_blocked) or not is_instance_valid(_open): return "Retained blocked/open drapery state is unavailable"
	if _level.get_node_or_null("CourtArt/EntranceCurtain/BlockedDrapery") != _blocked or _level.get_node_or_null("CourtArt/EntranceCurtain/OpenGatheredDrapery") != _open: return "Retained actual drapery state nodes changed"
	for record: Dictionary in _floor_records:
		if not is_instance_valid(record.node): return "Retained original court support/presentation is unavailable"
		var node: Node = record.node
		if not node.is_inside_tree() or node.is_queued_for_deletion() or node.get_parent() != record.parent or _level.get_node_or_null(record.path) != node or node.get_children() != record.children or node.get_script() != record.script or _properties(node) != record.properties:
			return "Original court support/spawn/presentation binding changed"
		if node is Node3D and ((node as Node3D).global_transform != record.global_transform or (node as Node3D).is_set_as_top_level()): return "Original court support/spawn/presentation frame changed"
		if record.has("shape"):
			var collision := node as CollisionShape3D
			if not is_instance_valid(record.shape) or collision.shape != record.shape or _properties(record.shape) != record.shape_properties: return "Original court BOX resource changed"
		if record.has("mesh"):
			var visual := node as MeshInstance3D
			if not is_instance_valid(record.mesh) or not is_instance_valid(record.material) or record.material.get_script() != null or visual.mesh != record.mesh or visual.material_override != record.material or _mesh_bytes(record.mesh) != record.geometry or _properties(record.material) != record.material_properties: return "Original quiet floor mesh/material changed"
	var floor := _floor_records[0].node as StaticBody3D
	var collision := _floor_records[1].node as CollisionShape3D
	if floor.get_shape_owners() != PackedInt32Array([_floor_shape_owner]) or floor.shape_owner_get_owner(_floor_shape_owner) != collision or floor.shape_owner_get_shape_count(_floor_shape_owner) != 1 or floor.shape_owner_get_shape(_floor_shape_owner, 0) != collision.shape or floor.shape_owner_get_transform(_floor_shape_owner) != Transform3D.IDENTITY or floor.is_shape_owner_disabled(_floor_shape_owner): return "Original floor native shape registration changed"
	for record: Dictionary in _nodes:
		if not is_instance_valid(record.node): return "Required authored court node is unavailable"
		var node: Node3D = record.node
		var expected_visible: bool = record.visible
		if node == _blocked: expected_visible = not _expected_exit_open
		elif node == _open: expected_visible = _expected_exit_open
		var expected_in_tree: bool = expected_visible
		if _blocked.is_ancestor_of(node): expected_in_tree = not _expected_exit_open
		elif _open.is_ancestor_of(node): expected_in_tree = _expected_exit_open
		if not node.is_inside_tree() or node.is_queued_for_deletion() or node.get_parent() != record.parent or _level.get_node_or_null(record.path) != node or node.get_script() != record.script or node.get_children() != record.children: return "Required court tree/script composition changed"
		if node.transform != record.transform or node.global_transform != record.global_transform or node.is_set_as_top_level() or node.process_mode != Node.PROCESS_MODE_DISABLED or node.is_processing() or node.is_physics_processing() or node.visible != expected_visible or node.is_visible_in_tree() != expected_in_tree: return "Required clockless court frame/visibility changed"
	for record: Dictionary in _meshes:
		if not is_instance_valid(record.mesh): return "Retained authored court mesh is unavailable"
		var node: MeshInstance3D = record.node
		if node.mesh != record.mesh or node.material_override != record.material or node.material_overlay != null or _properties(node, ["visible"]) != record.properties or _mesh_bytes(record.mesh) != record.geometry: return "Authored court mesh/renderer identity or geometry changed"
		for index: int in node.get_surface_override_material_count():
			if node.get_surface_override_material(index) != null: return "Court mesh surface overrides are unsupported"
	for record: Dictionary in _materials:
		if not is_instance_valid(record.material) or record.material.get_script() != null or _properties(record.material) != record.properties: return "Retained court material/settings changed"
		var material: StandardMaterial3D = record.material
		if material.albedo_texture != record.texture: return "Retained court texture identity changed"
		if record.texture != null and (not is_instance_valid(record.texture) or record.texture.get_script() != null or record.texture.resource_path != record.texture_path or record.texture.get_size() != record.texture_size): return "Retained court texture readback changed"
	if _landmarks.size() != LANDMARK_IDS.size(): return "Retain the exact authored landmark set"
	for id: String in LANDMARK_IDS:
		if not is_instance_valid(_landmarks.get(id)) or _level.get_node_or_null(LANDMARK_PATHS[id]) != _landmarks[id]: return "Required actual authored court landmark is unavailable or substituted"
	return ""


func landmark_world_corners(id: String) -> Array:
	if not LANDMARK_IDS.has(id) or not binding_error().is_empty(): return [Vector3.INF]
	var root: Node3D = _landmarks[id]
	var points: Array[Vector3] = []
	for record: Dictionary in _meshes:
		var mesh: MeshInstance3D = record.node
		if (mesh == root or root.is_ancestor_of(mesh)) and mesh.is_visible_in_tree():
			points.append_array(_box_points(mesh.get_aabb(), mesh.global_transform))
	if points.is_empty(): return [Vector3.INF]
	# A conservative world enclosure of EVERY current visible native mesh;
	# this is actual geometry readback, never a silhouette/distance proxy.
	var bounds := AABB(points[0], Vector3.ZERO)
	for point: Vector3 in points: bounds = bounds.expand(point)
	return _box_points(bounds, Transform3D.IDENTITY)


func _retain_floor() -> void:
	for path: String in ["Floor", "Floor/CollisionShape3D", "Floor/QuietFloor", "PlayerSpawn"]:
		var node: Node3D = _level.get_node(path)
		var record: Dictionary = {"node": node, "parent": node.get_parent(), "path": NodePath(path), "script": node.get_script(), "children": node.get_children(), "global_transform": node.global_transform, "properties": _properties(node)}
		if node is CollisionShape3D:
			record["shape"] = (node as CollisionShape3D).shape
			record["shape_properties"] = _properties(record.shape)
		if node is MeshInstance3D:
			record["mesh"] = (node as MeshInstance3D).mesh
			record["material"] = (node as MeshInstance3D).material_override
			record["geometry"] = _mesh_bytes(record.mesh)
			record["material_properties"] = _properties(record.material)
		_floor_records.append(record)
	_floor_shape_owner = int((_floor_records[0].node as StaticBody3D).get_shape_owners()[0])


func _retain_tree() -> void:
	var nodes: Array[Node3D] = [self]
	for raw: Node in find_children("*", "Node3D", true, false): nodes.append(raw as Node3D)
	for node: Node3D in nodes:
		var path := NodePath("CourtArt" if node == self else "CourtArt/" + String(get_path_to(node)))
		_nodes.append({"node": node, "parent": _level if node == self else node.get_parent(), "path": path, "script": node.get_script(), "children": node.get_children(), "transform": node.transform, "global_transform": _authored_transform(node), "visible": node.visible})
		if node is MeshInstance3D:
			var mesh := node as MeshInstance3D
			_meshes.append({"node": mesh, "mesh": mesh.mesh, "material": mesh.material_override, "geometry": _mesh_bytes(mesh.mesh), "properties": _properties(mesh, ["visible"])})
			var material := mesh.material_override as StandardMaterial3D
			_materials.append({"material": material, "properties": _properties(material), "texture": material.albedo_texture, "texture_path": material.albedo_texture.resource_path if material.albedo_texture != null else "", "texture_size": material.albedo_texture.get_size() if material.albedo_texture != null else Vector2.ZERO})


func _authored_transform(node: Node3D) -> Transform3D:
	var chain: Array[Transform3D] = []
	var cursor: Node3D = node
	while cursor != self:
		chain.push_front(cursor.transform)
		cursor = cursor.get_parent() as Node3D
	var result := Transform3D.IDENTITY
	for frame: Transform3D in chain: result = result * frame
	return result


static func _properties(object: Object, excluded: Array[String] = []) -> PackedByteArray:
	var values: Array = []
	for info: Dictionary in object.get_property_list():
		var key: String = String(info.name)
		if (int(info.usage) & PROPERTY_USAGE_STORAGE) == 0 or (int(info.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 or key in excluded: continue
		var value: Variant = object.get(key)
		values.append([key, ["object", value.get_instance_id()] if value is Object and is_instance_valid(value) else value])
	return var_to_bytes(values)


static func _mesh_bytes(mesh: Mesh) -> PackedByteArray:
	if not is_instance_valid(mesh) or mesh.get_script() != null: return PackedByteArray()
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


func _mesh(parent: Node3D, node_name: String, mesh: Mesh, material: StandardMaterial3D) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.process_mode = Node.PROCESS_MODE_DISABLED
	parent.add_child(node)
	return node


func _box(parent: Node3D, node_name: String, origin: Vector3, size: Vector3, silver: float) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := _mesh(parent, node_name, mesh, _material(silver))
	node.position = origin


static func _material(silver: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(silver, silver, silver)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.no_depth_test = false
	material.render_priority = 0
	return material


static func _vertex_material() -> StandardMaterial3D:
	var material := _material(1.0)
	material.vertex_color_use_as_albedo = true
	return material


static func _array_mesh(vertices: PackedVector3Array, colors: PackedColorArray, uvs: PackedVector2Array) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _triangle(vertices: PackedVector3Array, colors: PackedColorArray, uvs: PackedVector2Array, a: Vector3, b: Vector3, c: Vector3, silver: float) -> void:
	for point: Vector3 in [a, b, c]:
		vertices.append(point)
		colors.append(Color(silver, silver, silver))
		uvs.append(Vector2(point.x, point.y))


static func _polygon_xy(vertices: PackedVector3Array, colors: PackedColorArray, uvs: PackedVector2Array, polygon: PackedVector2Array, z: float, silver: float) -> void:
	for index: int in Geometry2D.triangulate_polygon(polygon):
		var point: Vector2 = polygon[index]
		vertices.append(Vector3(point.x, point.y, z))
		colors.append(Color(silver, silver, silver))
		uvs.append(point)


static func _ribbon_xy(vertices: PackedVector3Array, colors: PackedColorArray, uvs: PackedVector2Array, p: Vector2, q: Vector2, width: float, z: float, silver: float) -> void:
	var delta: Vector2 = q - p
	var side := Vector2(-delta.y, delta.x).normalized() * width * 0.5
	_triangle(vertices, colors, uvs, Vector3(p.x - side.x, p.y - side.y, z), Vector3(q.x - side.x, q.y - side.y, z), Vector3(q.x + side.x, q.y + side.y, z), silver)
	_triangle(vertices, colors, uvs, Vector3(p.x - side.x, p.y - side.y, z), Vector3(q.x + side.x, q.y + side.y, z), Vector3(p.x + side.x, p.y + side.y, z), silver)


static func _cuboid(vertices: PackedVector3Array, colors: PackedColorArray, uvs: PackedVector2Array, origin: Vector3, size: Vector3, silver: float) -> void:
	var points: Array[Vector3] = []
	for x: float in [-0.5, 0.5]:
		for y: float in [-0.5, 0.5]:
			for z: float in [-0.5, 0.5]: points.append(origin + size * Vector3(x, y, z))
	for face: Array in [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]]:
		_triangle(vertices, colors, uvs, points[face[0]], points[face[1]], points[face[2]], silver)
		_triangle(vertices, colors, uvs, points[face[0]], points[face[2]], points[face[3]], silver)
