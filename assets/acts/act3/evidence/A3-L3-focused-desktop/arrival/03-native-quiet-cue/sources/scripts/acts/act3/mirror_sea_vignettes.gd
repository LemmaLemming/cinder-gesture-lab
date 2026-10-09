class_name CinderAct3MirrorSeaVignettes
extends Node3D
## Optional quiet art; native construction/custody checked at arrival only.
## All six court groups are preconstructed and static. There is no Hero follow,
## enemy, physics, cue, action, progression, clock, interaction or save authority.
## Existing cast pixels and Earthrid/lake native resources retain unity scale.
## Complete per-group bounds are optional scenery evidence, never attack proof.

const API: String = "act3-mirror-sea-vignettes-1"
const Modules = preload("res://scripts/acts/act3/mirror_shore_modules.gd")
const Witnesses = preload("res://scripts/acts/act3/mirror_shore_witnesses.gd")
const Irontick = preload("res://scripts/acts/act3/mirror_irontick_scenery.gd")
const LAYOUT_PATH: String = "res://data/campaign/act3/mirror_sea_layout_candidate.json"
const COURT_IDS: Array[String] = ["shore-and-doubled-sky", "one-real-body", "useful-ending-west", "useful-ending-east", "resonant-apron", "shore-falls-silent"]
const COURT_Z: Array[float] = [34.0, 21.0, 9.0, -3.0, -21.0, -38.0]
const MODULE_COURTS: Array[int] = [0, 2, 4, 5]
const SHORE_ANCHOR: Vector3 = Vector3(-8.2, 0.0, 43.0)
const LAKE_CENTER: Vector3 = Vector3(9.2, -0.031, -21.0)
const EARTHRID_BANK: Vector3 = Vector3(7.65, 0.0, -19.8)
const BODY_TURN: float = -0.9119902906774204 # -atan2(lake-to-bank X1.55, forward Z1.2).
const BASALT: Color = Color("28232f")
const DARK_FACET: Color = Color("322b3a")
const PALE_SHADOW: Color = Color("524b59")

var last_error: String = ""
var _built: bool = false
var _parent: Node3D
var _world: World3D
var _script: Script
var _layout_digest: String = ""
var _groups: Array[Dictionary] = []
var _nodes: Array[Dictionary] = []
var _meshes: Array[Dictionary] = []
var _sprites: Array[Dictionary] = []
var _textures: Array[Dictionary] = []
var _witnesses: Node3D


## Build under the actual untransformed level, not beneath an actor or camera.
## Repeating the same supported build verifies the original native unit.
func build(parent: Node3D) -> bool:
	if _built:
		return parent == _parent and native_error().is_empty()
	if not last_error.is_empty():
		return false
	if not is_instance_valid(parent) or not parent.is_inside_tree() or parent.is_queued_for_deletion() or not parent is CinderLevel or parent.global_transform != Transform3D.IDENTITY:
		return _fail("Quiet vignettes require the live untransformed actual CinderLevel")
	if get_parent() == null:
		parent.add_child(self)
	if get_parent() != parent or global_transform != Transform3D.IDENTITY or get_child_count() != 0:
		return _fail("Build exactly one empty untransformed quiet root under that level")
	var text: String = FileAccess.get_file_as_string(LAYOUT_PATH)
	var layout: Variant = JSON.parse_string(text)
	var error: String = _layout_error(layout)
	if not error.is_empty():
		return _fail(error)
	_parent = parent
	_world = get_world_3d()
	_script = get_script()
	_layout_digest = _digest(text.to_utf8_buffer())
	for index: int in range(COURT_IDS.size()):
		if MODULE_COURTS.has(index):
			var modules: Node3D = Modules.new()
			modules.name = "QuietMineralCourt" + str(index)
			add_child(modules)
			if not modules.call("build", COURT_IDS[index], COURT_Z[index]):
				return _fail(String(modules.get("last_error")))
			if (modules.call("state") as Dictionary).pieces.size() != 32:
				return _fail("Reuse the original32-piece shore module recipe")
			_group(index, "mineral-court", modules, "edge-and-flat-scenery")
			_build_distant_form(index)
		_build_white_shadows(index)
	_build_shore_people()
	if not last_error.is_empty():
		return false
	if not _build_earthrid_lake():
		return false
	_capture_node(self)
	if _meshes.size() != 193 or _sprites.size() != 2 or _groups.size() != 16:
		return _fail("Quiet unit must retain193 meshes,2 original cast sprites and16 complete groups")
	_built = true
	error = native_error()
	return true if error.is_empty() else _fail(error)


## Pure native custody. A missing or altered part is rejected, never healed.
func native_error() -> String:
	if not last_error.is_empty():
		return last_error
	if not _built or not is_inside_tree() or is_queued_for_deletion() or not is_visible_in_tree() or get_parent() != _parent or get_world_3d() != _world or get_script() != _script or global_transform != Transform3D.IDENTITY:
		return "Quiet vignettes require their original visible static parent/world/script"
	for record: Dictionary in _nodes:
		var node: Node3D = record.node as Node3D
		if not is_instance_valid(node) or node is CollisionObject3D or node.is_queued_for_deletion() or node.get_parent() != record.parent or node.name != record.name or var_to_bytes(node.transform) != var_to_bytes(record.transform) or node.get_script() != record.script or node.get_child_count() != record.children or not node.is_visible_in_tree() or not node.get_groups().is_empty() or node.is_processing() or node.is_physics_processing():
			return "Quiet native ancestry, placement, visibility or noninteractive policy changed"
	for record: Dictionary in _meshes:
		var view: MeshInstance3D = record.view as MeshInstance3D
		if view.mesh != record.mesh or view.material_override != record.material or view.material_overlay != null or view.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			return "Quiet native mesh/material identity or shadow policy changed"
		if view.mesh.get_script() != null or view.material_override.get_script() != null or not view.material_override is StandardMaterial3D:
			return "Quiet parts require script-free native mesh and StandardMaterial3D"
		var material: StandardMaterial3D = view.material_override as StandardMaterial3D
		if material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.no_depth_test or material.depth_draw_mode != BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY or material.render_priority != 0 or material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST:
			return "Quiet materials require opaque nearest ordinary depth, without priority bypass"
		if String(record.node_stamp).is_empty() or String(record.mesh_stamp).is_empty() or String(record.material_stamp).is_empty() or _property_stamp(view, ["mesh", "material_override", "owner"]) != record.node_stamp or _mesh_stamp(view.mesh) != record.mesh_stamp or _property_stamp(material) != record.material_stamp:
			return "Quiet native mesh buffers/material/node properties changed"
		for surface: int in range(view.mesh.get_surface_count()):
			if view.get_surface_override_material(surface) != null:
				return "Quiet part acquired an unsupported surface override"
	for record: Dictionary in _sprites:
		var figure: Sprite3D = record.view as Sprite3D
		if figure.texture != record.texture or not figure.texture is AtlasTexture or figure.material_override != null or figure.material_overlay != null or figure.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			return "Quiet cast original atlas or draw policy changed"
		var atlas: AtlasTexture = figure.texture as AtlasTexture
		var retained_vertices: PackedVector3Array = record.vertices
		if atlas.atlas != record.atlas or atlas.region != record.region or atlas.margin != record.margin or atlas.filter_clip != record.filter_clip or atlas.get_script() != null:
			return "Quiet cast must retain original pixel crops and atlas resource"
		if String(record.node_stamp).is_empty() or retained_vertices.size() != 6 or _property_stamp(figure, ["texture", "owner"]) != record.node_stamp or var_to_bytes(_sprite_vertices(figure)) != var_to_bytes(retained_vertices):
			return "Quiet cast native settings, full quad, scale or sole pivot changed"
		var rendered: Dictionary = _sprite_render_corners(figure)
		if not String(rendered.error).is_empty():
			return String(rendered.error)
		if figure.global_basis != Basis.IDENTITY or figure.axis != Vector3.AXIS_Z or figure.billboard != BaseMaterial3D.BILLBOARD_ENABLED or figure.alpha_cut != SpriteBase3D.ALPHA_CUT_DISCARD or figure.alpha_scissor_threshold != 0.5 or figure.no_depth_test or figure.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST:
			return "Quiet cast supports only unchanged nearest clipped ordinary-depth full billboards"
	for record: Dictionary in _textures:
		var texture: Texture2D = record.texture as Texture2D
		if not is_instance_valid(texture) or String(record.stamp).is_empty() or texture.get_script() != null or texture.get_size() != record.size or _texture_stamp(texture) != record.stamp:
			return "Quiet cast original native texture pixels changed"
	if not is_instance_valid(_witnesses):
		return "Quiet shore people were removed"
	var witness_error: String = String(_witnesses.call("runtime_error"))
	if not witness_error.is_empty():
		return witness_error
	return ""


## Complete finite geometry for each optional group at one authored court.
## All points in a group are enclosed, not opaque-alpha/capsule approximations.
## This does not promise that an entire edge/background group fits the camera.
## A quiet consumer chooses a whole group; combat keeps its existing full gates.
func current_court_bounds(index: int) -> Dictionary:
	var error: String = native_error()
	if not error.is_empty():
		return {"error": error, "points": [], "groups": []}
	if index < 0 or index >= COURT_IDS.size():
		return {"error": "An actual six-court index is required", "points": [], "groups": []}
	var result: Array = []
	var all_points: Array = []
	for record: Dictionary in _groups:
		if record.index != index:
			continue
		var raw: Array = []
		var collection_error: String = _collect_points(record.node as Node3D, raw)
		if not collection_error.is_empty():
			return {"error": collection_error, "points": [], "groups": []}
		var bounds: AABB = _bounds(raw)
		var points: Array = _corners(bounds)
		all_points.append_array(points)
		result.append({"id": record.id, "role": record.role, "framing_optional": true, "bounds": bounds, "points": points, "native_point_count": raw.size()})
	return {"api_revision": API, "error": "", "court_id": COURT_IDS[index], "court_origin": Vector3(0, 0, COURT_Z[index]), "framing_optional": true, "groups": result, "points": all_points, "layout_sha256": _layout_digest, "readiness": "unexecuted_unreviewed_native_composition_candidate"}


func _layout_error(layout: Variant) -> String:
	if not layout is Dictionary or layout.get("level_id") != "A3-L3" or not layout.get("arrangements") is Array or layout.arrangements.size() != 6 or not layout.get("scenery") is Dictionary:
		return "Canonical authored six-court Mirror Sea layout required"
	for index: int in range(6):
		var row: Variant = layout.arrangements[index]
		if not row is Dictionary or row.get("id") != COURT_IDS[index] or row.get("entry_index") != index or not _triple(row.get("court_origin_world"), [0.0, 0.0, COURT_Z[index]]):
			return "Quiet court IDs/origins must match the actual authored parent"
	var scenic: Dictionary = layout.scenery
	if not scenic.get("module_court_centres_z") is Array or scenic.module_court_centres_z.size() != MODULE_COURTS.size():
		return "Canonical sparse shore-module repeat policy required"
	for index: int in range(MODULE_COURTS.size()):
		var value: Variant = scenic.module_court_centres_z[index]
		if not _number(value) or float(value) != COURT_Z[MODULE_COURTS[index]]:
			return "Quiet modules must omit adjacent courts21/-3"
	if not scenic.get("shore_witnesses") is Dictionary or not _triple(scenic.shore_witnesses.get("anchor_world"), [-8.2, 0.0, 43.0]) or not scenic.get("irontick_earthrid") is Dictionary or not _triple(scenic.irontick_earthrid.get("lake_center_world"), [9.2, -0.031, -21.0]) or not _triple(scenic.irontick_earthrid.get("earthrid_sole_world"), [7.65, 0.0, -19.8]) or not _number(scenic.irontick_earthrid.get("lake_radius_world")) or float(scenic.irontick_earthrid.lake_radius_world) != 1.6:
		return "Quiet people/lake must retain the canonical optional bank anchors"
	return ""


func _number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))


func _triple(value: Variant, expected: Array) -> bool:
	# This is authoring JSON binary64 data, not a widened native Vector3.
	# Compare declared numbers exactly; native render transforms are captured
	# separately after assignment. No float tolerance or geometry retune.
	if not value is Array or value.size() != 3:
		return false
	for index: int in range(3):
		if not _number(value[index]) or float(value[index]) != float(expected[index]):
			return false
	return true


func _group(index: int, id: String, node: Node3D, role: String) -> void:
	_groups.append({"index": index, "id": COURT_IDS[index] + "/" + id, "node": node, "role": role})


func _new_group(label: String) -> Node3D:
	var node := Node3D.new()
	node.name = label
	add_child(node)
	return node


func _build_distant_form(index: int) -> void:
	var group: Node3D = _new_group("StaticSplitArch" + str(index))
	var side: float = -1.0 if index in [0, 4] else 1.0
	var origin := Vector3(side * 8.25, 0, COURT_Z[index] - 4.9)
	# All raised mass is outside the actual14WU floor. Offset upper fragments
	# imply an impossible interrupted arch without a required bridge/platform.
	_box(group, "LowBlackPier", Vector3(0.42, 1.25, 0.5), origin + Vector3(-side * 0.45, 0.625, 0), BASALT)
	_box(group, "ForkedHighPier", Vector3(0.39, 2.45, 0.44), origin + Vector3(side * 0.40, 1.225, -0.25), DARK_FACET)
	_box(group, "OffsetUpperSlab", Vector3(1.3, 0.19, 0.51), origin + Vector3(side * 0.15, 1.91, -0.08), DARK_FACET)
	_box(group, "DetachedCrown", Vector3(0.17, 0.67, 0.16), origin + Vector3(side * 0.48, 2.815, -0.27), BASALT)
	_box(group, "QuietInsetFacet", Vector3(0.075, 0.49, 0.20), origin + Vector3(-side * 0.24, 0.65, 0.05), Color("484151"))
	_group(index, "split-arch", group, "distant-static-scenery")


func _build_white_shadows(index: int) -> void:
	var group: Node3D = _new_group("QuietWhiteShadows" + str(index))
	var sign: float = -1.0 if index % 2 == 0 else 1.0
	# Irregular filled pale-grey fragments, not standing decoys, rails, arrows,
	# endpoint circles, bright borders, pulses or hidden collision footprints.
	_polygon(group, "LongIrregularPale", Vector3(sign * 5.2, 0.018, COURT_Z[index] + 1.3),
		PackedVector2Array([Vector2(-0.32, -1.10), Vector2(0.03, -1.31), Vector2(0.20, -0.36), Vector2(0.09, 0.74), Vector2(-0.17, 1.07), Vector2(-0.12, 0.08)]), PALE_SHADOW)
	_polygon(group, "SeparatedLowPale", Vector3(sign * 4.75, 0.019, COURT_Z[index] + 2.55),
		PackedVector2Array([Vector2(-0.21, -0.17), Vector2(0.12, -0.29), Vector2(0.27, 0.07), Vector2(-0.05, 0.24)]), PALE_SHADOW.darkened(0.10))
	_group(index, "white-shadows", group, "quiet-filled-floor-motif")


func _build_shore_people() -> void:
	var group: Node3D = _new_group("PolecrabGleameilDryBank")
	_witnesses = Witnesses.new()
	_witnesses.name = "OriginalShorePeople"
	group.add_child(_witnesses)
	_witnesses.position = SHORE_ANCHOR
	var error: String = String(_witnesses.call("runtime_error"))
	if not error.is_empty():
		_fail(error)
		return
	_polygon(group, "OffFloorDryWitnessBank", Vector3(-8.25, 0, 43),
		PackedVector2Array([Vector2(-1.18, -0.60), Vector2(0.80, -0.70), Vector2(1.18, -0.23), Vector2(1.10, 0.66), Vector2(-0.75, 0.71), Vector2(-1.25, 0.19)]), BASALT)
	_group(0, "shore-people", group, "optional-nonhostile-full-cast-bank")


func _build_earthrid_lake() -> bool:
	# The original room helper is a resource factory at its required identity.
	# Its geometry/material resources are reused unchanged. It is then freed;
	# these31 new render nodes retain the current recipe's exact native buffers.
	var factory: Node3D = Irontick.new()
	factory.name = "TemporaryOriginalIrontickResourceFactory"
	add_child(factory)
	factory.call("build", true)
	var error: String = String(factory.call("runtime_error"))
	if not error.is_empty():
		remove_child(factory)
		factory.free()
		return _fail(error)
	var recipe: Dictionary = factory.call("native_geometry_state")
	if recipe.mesh_count != 31 or recipe.meshes.size() != 31:
		remove_child(factory)
		factory.free()
		return _fail("Reuse the complete current31-mesh Earthrid/lake recipe")
	var group: Node3D = _new_group("EarthridIrontickEastBank")
	var roles: Dictionary = {}
	for row: Dictionary in recipe.meshes:
		roles[row.name] = String(row.role)
	var turn := Basis(Vector3.UP, BODY_TURN)
	var sole := EARTHRID_BANK + Vector3(0, 0.02, 0)
	for child: Node in factory.get_children():
		if not child is MeshInstance3D or not roles.has(String(child.name)):
			remove_child(factory)
			factory.free()
			return _fail("Original Irontick factory exposed a nonstatic or unknown part")
		var original: MeshInstance3D = child as MeshInstance3D
		var clone := MeshInstance3D.new()
		clone.name = original.name
		clone.mesh = original.mesh
		clone.material_override = original.material_override
		clone.cast_shadow = original.cast_shadow
		var role: String = roles[String(original.name)]
		if role in ["water", "rim"]:
			clone.transform = original.transform
			clone.position += LAKE_CENTER - Irontick.LAKE_CENTER
		else:
			clone.transform = Transform3D(turn * original.basis, sole + turn * (original.position - Irontick.EARTHRID_SOLE))
		group.add_child(clone)
	remove_child(factory)
	factory.free()
	_polygon(group, "OffFloorDryEarthridBank", Vector3(7.85, 0, -19.8),
		PackedVector2Array([Vector2(-0.70, -0.65), Vector2(0.62, -0.59), Vector2(0.79, 0.15), Vector2(0.42, 0.65), Vector2(-0.65, 0.50)]), BASALT)
	_group(4, "earthrid-irontick", group, "optional-nonhostile-whole-lake-bank")
	return true


func _box(parent: Node3D, label: String, size: Vector3, at: Vector3, color: Color) -> void:
	var view := MeshInstance3D.new()
	view.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	view.mesh = mesh
	view.material_override = _material(color, false)
	view.position = at
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(view)


func _polygon(parent: Node3D, label: String, at: Vector3, contour: PackedVector2Array, color: Color) -> void:
	var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(contour)
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	for index: int in triangles:
		vertices.append(Vector3(contour[index].x, 0, contour[index].y))
		colors.append(color)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var view := MeshInstance3D.new()
	view.name = label
	view.mesh = mesh
	view.material_override = _material(Color.WHITE, true)
	view.position = at
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(view)


func _material(color: Color, vertex_colors: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = vertex_colors
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _capture_node(node: Node3D) -> void:
	if node is CollisionObject3D:
		_fail("Quiet component cannot acquire a collision body")
		return
	_nodes.append({"node": node, "parent": node.get_parent(), "name": node.name, "transform": node.transform, "script": node.get_script(), "children": node.get_child_count()})
	if node is MeshInstance3D:
		var view: MeshInstance3D = node as MeshInstance3D
		_meshes.append({"view": view, "mesh": view.mesh, "material": view.material_override, "node_stamp": _property_stamp(view, ["mesh", "material_override", "owner"]), "mesh_stamp": _mesh_stamp(view.mesh), "material_stamp": _property_stamp(view.material_override)})
	elif node is Sprite3D:
		var figure: Sprite3D = node as Sprite3D
		var atlas: AtlasTexture = figure.texture as AtlasTexture
		_sprites.append({"view": figure, "texture": atlas, "atlas": atlas.atlas, "region": atlas.region, "margin": atlas.margin, "filter_clip": atlas.filter_clip, "node_stamp": _property_stamp(figure, ["texture", "owner"]), "vertices": _sprite_vertices(figure)})
		if _textures.is_empty():
			_textures.append({"texture": atlas.atlas, "size": atlas.atlas.get_size(), "stamp": _texture_stamp(atlas.atlas)})
	for child: Node in node.get_children():
		if child is Node3D:
			_capture_node(child as Node3D)
		else:
			_fail("Quiet component cannot acquire a nonnative/interactive child")


func _collect_points(node: Node3D, result: Array) -> String:
	if node is MeshInstance3D:
		var view: MeshInstance3D = node as MeshInstance3D
		for point: Vector3 in _corners(view.mesh.get_aabb()):
			result.append(view.global_transform * point)
	elif node is Sprite3D:
		var figure: Sprite3D = node as Sprite3D
		var shell: Node = _parent.get("shared_shell") as Node
		var camera: Camera3D = shell.get("camera") as Camera3D if is_instance_valid(shell) else null
		if camera == null or not camera.is_inside_tree() or camera.get_world_3d() != _world:
			return "Quiet cast bounds require the actual existing public world Camera3D"
		# TriangleMesh faces are snapped shape evidence. Actual rendering uses
		# unsnapped item-rect corners, including raster-Y sign, offset and the
		# assigned native pixel_size. Full billboard uses the actual Camera basis.
		var rendered: Dictionary = _sprite_render_corners(figure)
		if not String(rendered.error).is_empty():
			return String(rendered.error)
		for vertex: Vector3 in rendered.points:
			result.append(figure.global_position + camera.global_basis * vertex)
	for child: Node in node.get_children():
		var error: String = _collect_points(child as Node3D, result)
		if not error.is_empty():
			return error
	return ""


func _sprite_vertices(figure: Sprite3D) -> PackedVector3Array:
	var mesh: TriangleMesh = figure.generate_triangle_mesh()
	return PackedVector3Array() if mesh == null else mesh.get_faces()


func _sprite_render_corners(figure: Sprite3D) -> Dictionary:
	# Godot TriangleMesh::create snaps to0.0001WU. This is an exact native
	# shape consistency check, never an epsilon or cropped rendering bound.
	var faces: PackedVector3Array = _sprite_vertices(figure)
	var snapped: Array[Vector3] = []
	for vertex: Vector3 in faces:
		if not vertex.is_finite() or vertex.z != 0.0:
			return {"error": "Quiet cast native quad is unsupported", "points": []}
		if not snapped.has(vertex):
			snapped.append(vertex)
	if faces.size() != 6 or snapped.size() != 4:
		return {"error": "Quiet cast requires six native faces and four complete corners", "points": []}
	var rect: Rect2 = figure.get_item_rect()
	var points: Array[Vector3] = []
	for x: float in [rect.position.x, rect.end.x]:
		for y: float in [rect.position.y, rect.end.y]:
			var corner := Vector3(x * figure.pixel_size, y * figure.pixel_size, 0)
			if not corner.is_finite() or not snapped.has(corner.snapped(Vector3.ONE * 0.0001)):
				return {"error": "Quiet cast rendered rectangle differs from its native quad", "points": []}
			points.append(corner)
	return {"error": "", "points": points}


func _bounds(points: Array) -> AABB:
	var low: Vector3 = points[0]
	var high: Vector3 = low
	for point: Vector3 in points:
		low = low.min(point)
		high = high.max(point)
	return AABB(low, high - low)


func _corners(bounds: AABB) -> Array:
	var result: Array = []
	var far: Vector3 = bounds.position + bounds.size
	for x: float in [bounds.position.x, far.x]:
		for y: float in [bounds.position.y, far.y]:
			for z: float in [bounds.position.z, far.z]:
				result.append(Vector3(x, y, z))
	return result


func _mesh_stamp(mesh: Mesh) -> String:
	if not mesh is ArrayMesh and not mesh is BoxMesh:
		return ""
	var values: Array = [_property_stamp(mesh), mesh.get_aabb(), mesh.get_surface_count(), mesh.get_faces()]
	if String(values[0]).is_empty():
		return ""
	for surface: int in range(mesh.get_surface_count()):
		if mesh.surface_get_material(surface) != null:
			return ""
		var primitive: int = (mesh as ArrayMesh).surface_get_primitive_type(surface) if mesh is ArrayMesh else Mesh.PRIMITIVE_TRIANGLES
		if primitive != Mesh.PRIMITIVE_TRIANGLES:
			return ""
		values.append([primitive, mesh.surface_get_arrays(surface)])
	return _digest(var_to_bytes(values))


func _property_stamp(object: Object, excluded: Array = []) -> String:
	if not is_instance_valid(object):
		return ""
	var values: Array = []
	for info: Dictionary in object.get_property_list():
		var key: String = String(info.name)
		if (int(info.usage) & PROPERTY_USAGE_STORAGE) == 0 or key in excluded or key in ["resource_name", "resource_path", "resource_local_to_scene", "script"]:
			continue
		var value: Variant = object.get(key)
		if value is Object and is_instance_valid(value):
			return ""
		values.append([key, value])
	return _digest(var_to_bytes(values))


func _texture_stamp(texture: Texture2D) -> String:
	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		return ""
	return _digest(var_to_bytes([image.get_width(), image.get_height(), image.get_format(), image.has_mipmaps(), image.get_data()]))


func _digest(bytes: PackedByteArray) -> String:
	var hash := HashingContext.new()
	if hash.start(HashingContext.HASH_SHA256) != OK or hash.update(bytes) != OK:
		return ""
	return hash.finish().hex_encode()


func _fail(reason: String) -> bool:
	last_error = reason
	return false
