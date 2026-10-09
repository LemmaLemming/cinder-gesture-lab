class_name Act1MushroomGrottoArt
extends Node3D
## Static authored lunar theatre scenery; not wired or portrait accepted yet.
## G18/G25/G15/G12 and F09/F10 supply shapes, not extracted runtime pixels.
## Gameplay owns the actual floor, BOX stalks, fields, supplies and exit contact.

const Layout = preload("res://scripts/acts/act1/mushroom_caverns_layout.gd")
const RockPaint = preload("res://assets/acts/act1/lunar/accents/painted_rock_surface.png")
const CAP_SEGMENTS: int = 24
const COURT_ORIGIN: Vector3 = Vector3(0, 0, -52)

var court_open: bool = false
var _blocked_curtain: Node3D
var _open_curtain: Node3D
var _flat_materials: Dictionary = {}
var _paint_materials: Dictionary = {}
var _vertex_materials: Dictionary = {}
var _bound_level: Node3D
var _bound_script: Script
var _bound_level_transform: Transform3D
var _retained_stalks: Array[Dictionary] = []
var _retained_nodes: Array[Dictionary] = []
var _retained_meshes: Array[Dictionary] = []
var _retained_materials: Array[Dictionary] = []
var _expected_court_open: bool = false
var _custody_ready: bool = false


static func build_geometry_art(level: Node3D) -> Node3D:
	# Validate every replacement before hiding anything. Physical nodes, their
	# resources, GroundedBase, Floor/Visual and all perimeter visuals stay intact.
	if not is_instance_valid(level) or level.get_node_or_null("FungalArt") != null: return null
	var replaced: Array[MeshInstance3D] = []
	for spec: Dictionary in Layout.STALK_SPECS:
		var stalk := level.get_node_or_null(String(spec.id)) as StaticBody3D
		var visual := level.get_node_or_null(String(spec.id) + "/Visual") as MeshInstance3D
		var base := level.get_node_or_null(String(spec.id) + "/GroundedBase") as MeshInstance3D
		var cap := level.get_node_or_null(String(spec.id) + "GreyboxCap") as MeshInstance3D
		if not is_instance_valid(stalk) or not is_instance_valid(visual) or not is_instance_valid(base) or not is_instance_valid(cap): return null
		var collision := stalk.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if not is_instance_valid(collision): return null
		var shape := collision.shape as BoxShape3D
		if not is_instance_valid(shape) or shape.size != Layout.STALK_SIZE or collision.disabled: return null
		if visual.mesh == null or base.mesh == null or cap.mesh == null or not visual.material_override is StandardMaterial3D or not base.material_override is StandardMaterial3D or not cap.material_override is StandardMaterial3D: return null
		replaced.append(visual)
		replaced.append(cap)
	for spec: Array in Layout.SCENIC_SPECS:
		var visual := level.get_node_or_null(String(spec[0])) as MeshInstance3D
		if not is_instance_valid(visual): return null
		if visual.mesh == null or not visual.material_override is StandardMaterial3D: return null
		replaced.append(visual)
	var art := Act1MushroomGrottoArt.new()
	art.name = "FungalArt"
	art.process_mode = Node.PROCESS_MODE_DISABLED
	level.add_child(art)
	art._build()
	for visual: MeshInstance3D in replaced: visual.visible = false
	art._retain_bindings(level, replaced)
	return art


func _build() -> void:
	for spec: Dictionary in Layout.STALK_SPECS: _mushroom(spec)
	for spec: Array in Layout.SCENIC_SPECS:
		if spec[0] == "FallenTrunk": _trunk(spec[1], spec[2])
		else: _shelf(String(spec[0]), spec[1], spec[2])
	# Side flats stay beyond the physical perimeter. Their real porous gaps
	# reveal background; they are neither holes in floor nor collision proxies.
	for side: float in [-1.0, 1.0]:
		for index: int in 5:
			var z: float = [10.0, -3.0, -16.0, -30.0, -43.0][index]
			_wing(side, z, index)
	_court_threshold()
	set_court_open(false)


func _mushroom(spec: Dictionary) -> void:
	var root := _group(self, String(spec.id) + "PaintedSurface", spec.origin)
	# A full visible core matches the actual BOX collider, including corners.
	# Striations give the long stalk a hand-painted surface without hiding an
	# invisible square collision shoulder behind a narrower cylinder.
	# The original 0..0.16 grounded base stays exposed, with no coplanar overlap.
	var core_size := Vector3(Layout.STALK_SIZE.x, Layout.STALK_SIZE.y - 0.16, Layout.STALK_SIZE.z)
	var core := _box(root, "FullPhysicalStalkSurface", Vector3.UP * (0.16 + core_size.y * 0.5), core_size, _paint(0.78))
	(core.material_override as StandardMaterial3D).uv1_scale = Vector3(0.65, 2.3, 1)
	for index: int in 7:
		var x: float = -0.44 + index * 0.145
		var low: float = 0.18 + (index % 3) * 0.05
		var high: float = 2.12 - (index % 2) * 0.12
		_box(root, "FrontGrain%d" % index, Vector3(x, (low + high) * 0.5, 0.552), Vector3(0.043 if index % 2 else 0.065, high - low, 0.006), _material(0.74 if index % 3 else 0.35))
		_box(root, "SideGrain%d" % index, Vector3(0.552, (low + high) * 0.5, x), Vector3(0.006, high - low, 0.045), _material(0.60 if index % 2 else 0.32))
	var cap := _group(root, "ShallowUmbrellaCap", spec.cap_offset)
	_cap(cap, spec.cap_size, Vector3(-spec.cap_offset.x, 0, -spec.cap_offset.z))


func _cap(parent: Node3D, size: Vector3, stalk_projection: Vector3) -> void:
	var vertices := PackedVector3Array()
	var colours := PackedColorArray()
	var uvs := PackedVector2Array()
	var outer: Array[Vector3] = []
	var inner: Array[Vector3] = []
	for index: int in CAP_SEGMENTS:
		var angle: float = TAU * float(index) / CAP_SEGMENTS
		var irregular: float = 0.97 + 0.03 * float((index * 7) % 5) / 4.0
		outer.append(Vector3(cos(angle) * size.x * 0.5 * irregular, -size.y * 0.12, sin(angle) * size.z * 0.5 * irregular))
		inner.append(Vector3(cos(angle) * size.x * 0.27, size.y * 0.34, sin(angle) * size.z * 0.27))
	for index: int in CAP_SEGMENTS:
		var next: int = (index + 1) % CAP_SEGMENTS
		var silver: float = [0.75, 0.84, 0.79, 0.70][index % 4]
		_triangle(vertices, colours, uvs, Vector3(0, size.y * 0.5, 0), inner[index], inner[next], silver)
		_triangle(vertices, colours, uvs, inner[index], outer[index], outer[next], silver - 0.04)
		_triangle(vertices, colours, uvs, inner[index], outer[next], inner[next], silver - 0.04)
		var bottom_a := Vector3(outer[index].x, -size.y * 0.5, outer[index].z)
		var bottom_b := Vector3(outer[next].x, -size.y * 0.5, outer[next].z)
		_triangle(vertices, colours, uvs, outer[index], bottom_a, bottom_b, 0.28)
		_triangle(vertices, colours, uvs, outer[index], bottom_b, outer[next], 0.28)
		_triangle(vertices, colours, uvs, Vector3(stalk_projection.x, -size.y * 0.49, stalk_projection.z), bottom_b, bottom_a, 0.22)
	_mesh(parent, "FacetedPaintedCap", _array_mesh(vertices, colours, uvs), _vertex_material(true))
	# Fine underside gills converge at the real stalk. All vertices stay within
	# the original cap envelope; they have normal depth and no cue semantics.
	for index: int in CAP_SEGMENTS:
		var start := Vector3(stalk_projection.x, -size.y * 0.497, stalk_projection.z)
		var finish := Vector3(outer[index].x * 0.97, start.y, outer[index].z * 0.97)
		_ribbon_xz(parent, "RadialGill%d" % index, start, finish, 0.035, 0.47 if index % 2 else 0.58)


func _wing(side: float, z: float, index: int) -> void:
	var wing := _group(self, "RockWing%s%d" % ["West" if side < 0 else "East", index], Vector3(side * 7.65, 0, z))
	var outline := PackedVector2Array([
		Vector2(-0.43, 0), Vector2(0.43, 0), Vector2(0.40, 1.15),
		Vector2(0.23, 1.03), Vector2(0.30, 2.0), Vector2(0.09, 1.78),
		Vector2(0.04, 3.05), Vector2(-0.12, 2.55), Vector2(-0.20, 2.72),
		Vector2(-0.28, 1.55), Vector2(-0.42, 1.83),
	])
	_polygon_xy(wing, "JaggedPaintedFlat", outline, 0, _paint(0.67))
	# Annular geometry has actual open centres, not a painted black disc.
	for hole: int in 4:
		_ring_xy(wing, "PorousOpening%d" % hole, Vector3(0.02 if hole % 2 else -0.06, 0.48 + hole * 0.5, 0.12), 0.26, 0.16, 0.53)
	# A separate adjacent porous piece lets its openings reveal the dark outside
	# background rather than placing opaque rock directly behind every gap.
	var porous := _group(self, "PorousFungus%s%d" % ["West" if side < 0 else "East", index], Vector3(side * 8.45, 0, z + 0.65))
	for hole: int in 5:
		_ring_xy(porous, "OpenPore%d" % hole, Vector3(0.18 if hole % 2 else -0.12, 0.33 + hole * 0.43, 0), 0.31, 0.20, 0.61)


func _shelf(node_name: String, origin: Vector3, size: Vector3) -> void:
	var shelf := _group(self, node_name + "PaintedShelf", origin)
	_box(shelf, "QuietRockVolume", Vector3.ZERO, size, _paint(0.52))
	for index: int in 5:
		var z: float = -size.z * 0.42 + index * size.z * 0.21
		_box(shelf, "IrregularSilverLip%d" % index, Vector3(0, size.y * 0.45, z), Vector3(size.x * (0.86 if index % 2 else 1.0), size.y * 0.10, size.z * 0.19), _material(0.63 if index % 2 else 0.73))


func _trunk(origin: Vector3, size: Vector3) -> void:
	var trunk := _group(self, "FallenTrunkPaintedWood", origin)
	var timber := CylinderMesh.new()
	timber.top_radius = size.x * 0.42
	timber.bottom_radius = size.x * 0.5
	timber.height = size.z
	timber.radial_segments = 8
	timber.rings = 1
	var body := _mesh(trunk, "EightSidedTimber", timber, _paint(0.45))
	body.rotation.x = PI * 0.5
	for index: int in 4:
		_box(trunk, "LongWoodGrain%d" % index, Vector3(-0.23 + index * 0.15, 0.28, 0), Vector3(0.04, 0.025, size.z * (0.90 if index % 2 else 0.97)), _material(0.71 if index % 2 else 0.58))


func _court_threshold() -> void:
	var court := _group(self, "CourtCurtainO56", COURT_ORIGIN)
	for side: float in [-1.0, 1.0]:
		var side_name: String = "West" if side < 0 else "East"
		_box(court, "Column" + side_name, Vector3(side * 2.9, 1.8, 0), Vector3(0.30, 3.6, 0.24), _material(0.65))
		_box(court, "ColumnBase" + side_name, Vector3(side * 2.9, 0.15, 0), Vector3(0.64, 0.30, 0.40), _paint(0.74))
		_box(court, "ColumnCapital" + side_name, Vector3(side * 2.9, 3.56, 0), Vector3(0.60, 0.25, 0.34), _material(0.81))
		_crescent(court, "CrescentCrown" + side_name, Vector3(side * 2.9, 4.05, 0), side)
		_box(court, "CurlingPanel" + side_name, Vector3(side * 3.65, 1.56, 0.01), Vector3(1.04, 2.8, 0.12), _material(0.19))
		_spiral(court, "PaintedCurl" + side_name, Vector3(side * 3.65, 1.72, 0.09), side)
	_box(court, "TopDraperyRail", Vector3(0, 3.72, 0), Vector3(6.15, 0.16, 0.20), _material(0.75))
	_blocked_curtain = _group(court, "BlockedDrapery", Vector3.ZERO)
	_open_curtain = _group(court, "OpenGatheredDrapery", Vector3.ZERO)
	for side: float in [-1.0, 1.0]:
		_curtain_half(_blocked_curtain, side, false)
		_curtain_half(_open_curtain, side, true)


func set_court_open(opened: bool) -> void:
	# Gameplay owns the condition/contact gate. This synchronous, clockless leaf
	# only selects an authored scenic drapery pose; it emits no gameplay event.
	court_open = opened
	_expected_court_open = opened
	if is_instance_valid(_blocked_curtain): _blocked_curtain.visible = not opened
	if is_instance_valid(_open_curtain): _open_curtain.visible = opened


## Pure availability/readback guard for scenery that replaces visible physics
## surfaces or can occlude an actor. It grants no geometry, motion or clock.
func binding_error() -> String:
	if not _custody_ready or not is_instance_valid(_bound_level) or not _bound_level.is_inside_tree() or _bound_level.is_queued_for_deletion():
		return "Retained actual grotto level is unavailable"
	if not is_inside_tree() or is_queued_for_deletion() or get_parent() != _bound_level or _bound_level.get_node_or_null("FungalArt") != self or get_world_3d() != _bound_level.get_world_3d():
		return "Grotto art must retain its direct actual level/world binding"
	if _bound_level.global_transform != _bound_level_transform or _bound_level_transform != Transform3D.IDENTITY or transform != Transform3D.IDENTITY or is_set_as_top_level():
		return "Grotto layout and art must retain their authored identity world frames"
	if not visible or not is_visible_in_tree() or process_mode != Node.PROCESS_MODE_DISABLED or is_processing() or is_physics_processing() or get_script() != _bound_script:
		return "Grotto art requires its visible clockless authored leaf"
	if court_open != _expected_court_open or not is_instance_valid(_blocked_curtain) or not is_instance_valid(_open_curtain) or _blocked_curtain.visible != (not _expected_court_open) or _open_curtain.visible != _expected_court_open:
		return "Grotto curtain pose must follow its supported open/blocked setter"
	for record: Dictionary in _retained_stalks:
		if not is_instance_valid(record.body) or not is_instance_valid(record.collision):
			return "Retained physical mushroom stalk/collision is unavailable"
		var body := record.body as StaticBody3D
		var collision := record.collision as CollisionShape3D
		if not is_instance_valid(body) or not body.is_inside_tree() or body.is_queued_for_deletion() or body.get_parent() != _bound_level or _bound_level.get_node_or_null(record.path) != body:
			return "Retained physical mushroom stalk is unavailable"
		if not is_instance_valid(collision) or not collision.is_inside_tree() or collision.is_queued_for_deletion() or collision.get_parent() != body or body.get_node_or_null("CollisionShape3D") != collision:
			return "Retained actual stalk collision binding is unavailable"
		if body.transform != record.transform or body.global_transform != record.global_transform or body.is_set_as_top_level() or not body.is_visible_in_tree() or body.collision_layer != record.layer or body.collision_mask != record.mask or body.constant_linear_velocity != Vector3.ZERO or body.constant_angular_velocity != Vector3.ZERO:
			return "Physical mushroom stalk frame or collision authority changed"
		if not is_instance_valid(record.shape) or collision.shape != record.shape or not collision.shape is BoxShape3D:
			return "Physical mushroom stalk must retain its actual unchanged BOX resource"
		var shape := collision.shape as BoxShape3D
		if collision.transform != record.collision_transform or collision.global_transform != record.collision_global_transform or collision.disabled or collision.is_set_as_top_level() or shape.size != record.size or shape.margin != record.margin or shape.custom_solver_bias != record.solver_bias:
			return "Physical mushroom stalk must retain its actual unchanged BOX resource"
		var owners: PackedInt32Array = body.get_shape_owners()
		if owners != record.shape_owners or owners.size() != 1 or body.shape_owner_get_owner(owners[0]) != collision or body.shape_owner_get_shape_count(owners[0]) != 1 or body.shape_owner_get_shape(owners[0], 0) != record.shape or body.shape_owner_get_transform(owners[0]) != collision.transform or body.is_shape_owner_disabled(owners[0]):
			return "Physical stalk native shape registration changed"
	for record: Dictionary in _retained_nodes:
		if not is_instance_valid(record.node):
			return "Required grotto surface/cap/scenic node is unavailable"
		var node := record.node as Node3D
		if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion() or node.get_parent() != record.parent or _bound_level.get_node_or_null(record.path) != node:
			return "Required grotto surface/cap/scenic node is unavailable"
		if node.transform != record.transform or node.global_transform != record.global_transform or node.is_set_as_top_level() or node.process_mode != record.process_mode:
			return "Required grotto surface/cap/scenic frame changed"
		var expected_visible: bool = record.visible
		if node == _blocked_curtain: expected_visible = not _expected_court_open
		elif node == _open_curtain: expected_visible = _expected_court_open
		if node.visible != expected_visible:
			return "Required grotto surface/cap/scenic visibility changed"
		var expected_in_tree: bool = expected_visible
		if _blocked_curtain.is_ancestor_of(node): expected_in_tree = not _expected_court_open
		elif _open_curtain.is_ancestor_of(node): expected_in_tree = _expected_court_open
		if node.is_visible_in_tree() != expected_in_tree:
			return "Required grotto surface/cap/scenic ancestor visibility changed"
		if node.get_children() != record.children:
			return "Required grotto surface/cap/scenic composition changed"
	for record: Dictionary in _retained_meshes:
		if not is_instance_valid(record.node):
			return "Required grotto surface/cap/scenic mesh is unavailable"
		var node := record.node as MeshInstance3D
		if not is_instance_valid(node) or not is_instance_valid(record.mesh) or node.mesh != record.mesh or node.material_override != record.material or node.material_overlay != null or node.get_script() != null:
			return "Required grotto surface/cap/scenic mesh/material identity changed"
		if _mesh_bytes(node.mesh) != record.geometry or _renderer_bytes(node) != record.renderer:
			return "Required grotto surface/cap/scenic native geometry or renderer changed"
		if node.get_surface_override_material_count() != record.surface_materials.size():
			return "Required grotto surface material slots changed"
		for index: int in record.surface_materials.size():
			if node.get_surface_override_material(index) != record.surface_materials[index]:
				return "Required grotto surface material override changed"
	for record: Dictionary in _retained_materials:
		if not is_instance_valid(record.material):
			return "Required grotto painted material is unavailable"
		var material := record.material as StandardMaterial3D
		if not is_instance_valid(material) or material.get_script() != null or material.albedo_texture != record.texture or _material_bytes(material) != record.settings:
			return "Required grotto painted material/resource settings changed"
		if record.texture != null and (not is_instance_valid(record.texture) or material.albedo_texture.resource_path != record.texture_path or material.albedo_texture.get_size() != record.texture_size):
			return "Required grotto painted texture readback changed"
	return ""


func _retain_bindings(level: Node3D, replaced: Array[MeshInstance3D]) -> void:
	# Retain actual native resources/registrations after construction. Strong
	# references are intentional; missing/replaced nodes still fail identity.
	_bound_level = level
	_bound_script = get_script()
	_bound_level_transform = level.global_transform
	for spec: Dictionary in Layout.STALK_SPECS:
		var body := level.get_node_or_null(String(spec.id)) as StaticBody3D
		var collision := body.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var shape := collision.shape as BoxShape3D
		_retained_stalks.append({"body": body, "path": level.get_path_to(body), "collision": collision, "shape": shape, "transform": body.transform, "global_transform": body.global_transform, "layer": body.collision_layer, "mask": body.collision_mask, "collision_transform": collision.transform, "collision_global_transform": collision.global_transform, "size": shape.size, "margin": shape.margin, "solver_bias": shape.custom_solver_bias, "shape_owners": body.get_shape_owners()})
	var nodes: Array[Node3D] = [self]
	for node: Node in find_children("*", "Node3D", true, false): nodes.append(node as Node3D)
	for node: MeshInstance3D in replaced: nodes.append(node)
	for spec: Dictionary in Layout.STALK_SPECS: nodes.append(level.get_node(String(spec.id) + "/GroundedBase") as MeshInstance3D)
	for node: Node3D in nodes:
		_retained_nodes.append({"node": node, "parent": node.get_parent(), "path": level.get_path_to(node), "transform": node.transform, "global_transform": node.global_transform, "visible": node.visible, "process_mode": node.process_mode, "children": node.get_children()})
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			var surfaces: Array = []
			for index: int in mesh_node.get_surface_override_material_count(): surfaces.append(mesh_node.get_surface_override_material(index))
			_retained_meshes.append({"node": mesh_node, "mesh": mesh_node.mesh, "material": mesh_node.material_override, "geometry": _mesh_bytes(mesh_node.mesh), "renderer": _renderer_bytes(mesh_node), "surface_materials": surfaces})
			var material := mesh_node.material_override as StandardMaterial3D
			var present: bool = false
			for existing: Dictionary in _retained_materials:
				if existing.material == material: present = true
			if not present:
				var texture: Texture2D = material.albedo_texture
				_retained_materials.append({"material": material, "texture": texture, "texture_path": texture.resource_path if texture != null else "", "texture_size": texture.get_size() if texture != null else Vector2.ZERO, "settings": _material_bytes(material)})
	_custody_ready = true


func _mesh_bytes(mesh: Mesh) -> PackedByteArray:
	var surfaces: Array = []
	for index: int in mesh.get_surface_count():
		surfaces.append(mesh.surface_get_arrays(index))
		# The builder uses a node override; an added mesh-surface material is not
		# supported presentation and cannot become a second unguarded authority.
		if mesh.surface_get_material(index) != null: return PackedByteArray()
	return var_to_bytes([mesh.get_aabb(), surfaces])


func _renderer_bytes(node: MeshInstance3D) -> PackedByteArray:
	return var_to_bytes([node.cast_shadow, node.layers, node.transparency, node.visibility_range_begin, node.visibility_range_end, node.visibility_range_begin_margin, node.visibility_range_end_margin, node.visibility_range_fade_mode, node.ignore_occlusion_culling])


func _material_bytes(material: StandardMaterial3D) -> PackedByteArray:
	return var_to_bytes([material.shading_mode, material.albedo_color, material.cull_mode, material.texture_filter, material.texture_repeat, material.vertex_color_use_as_albedo, material.uv1_scale, material.uv1_offset, material.transparency, material.no_depth_test, material.render_priority, material.billboard_mode, material.grow, material.grow_amount, material.proximity_fade_enabled, material.distance_fade_mode, material.next_pass == null])


func _curtain_half(parent: Node3D, side: float, opened: bool) -> void:
	var side_name: String = "West" if side < 0 else "East"
	for index: int in 10:
		var width: float = 0.072 if opened else 0.255
		var x: float = side * (2.11 + index * width if opened else 0.13 + index * width)
		var bottom: float = 0.08 + 0.06 * float(index % 3)
		if opened: bottom += 0.45 * (1.0 - float(index) / 10.0)
		var top: float = 3.54 - 0.12 * sin(float(index) * PI / 9.0)
		_box(parent, "Fold%s_%d" % [side_name, index], Vector3(x, (top + bottom) * 0.5, 0.05 + (index % 2) * 0.03), Vector3(width * 1.06, top - bottom, 0.06), _material(0.30 if index % 2 else 0.45))
		_box(parent, "SilverHem%s_%d" % [side_name, index], Vector3(x, bottom + 0.04, 0.098), Vector3(width * 1.06, 0.06, 0.015), _material(0.70))


func _crescent(parent: Node3D, node_name: String, centre: Vector3, side: float) -> void:
	var polygon := PackedVector2Array()
	for index: int in 17:
		var angle: float = -PI * 0.5 + float(index) * PI / 16.0
		polygon.append(Vector2(side * cos(angle) * 0.45, sin(angle) * 0.45))
	# A shared pair of tips and a narrower inner arc form a simple polygon;
	# omitting duplicate tips avoids degenerate or self-crossing triangles.
	for index: int in range(15, 0, -1):
		var angle: float = -PI * 0.5 + float(index) * PI / 16.0
		polygon.append(Vector2(side * cos(angle) * 0.12, sin(angle) * 0.45))
	var root := _group(parent, node_name, centre)
	_polygon_xy(root, "MoonWhiteCrescent", polygon, 0, _material(0.85))


func _spiral(parent: Node3D, node_name: String, centre: Vector3, side: float) -> void:
	var root := _group(parent, node_name, centre)
	for index: int in 18:
		var a: float = float(index) * TAU * 1.1 / 18.0
		var b: float = float(index + 1) * TAU * 1.1 / 18.0
		var p := Vector2(side * cos(a) * (0.08 + index * 0.022), sin(a) * (0.08 + index * 0.022))
		var q := Vector2(side * cos(b) * (0.08 + (index + 1) * 0.022), sin(b) * (0.08 + (index + 1) * 0.022))
		var delta: Vector2 = q - p
		var stroke := _box(root, "CurlStroke%d" % index, Vector3((p.x + q.x) * 0.5, (p.y + q.y) * 0.5, 0), Vector3(delta.length() + 0.025, 0.045, 0.012), _material(0.70))
		stroke.rotation.z = delta.angle()


func _ring_xy(parent: Node3D, node_name: String, centre: Vector3, radius: float, hole: float, silver: float) -> void:
	var vertices := PackedVector3Array()
	var colours := PackedColorArray()
	var uvs := PackedVector2Array()
	for index: int in 10:
		var a: float = TAU * index / 10.0
		var b: float = TAU * (index + 1) / 10.0
		var p := centre + Vector3(cos(a) * radius, sin(a) * radius, 0)
		var q := centre + Vector3(cos(b) * radius, sin(b) * radius, 0)
		var r := centre + Vector3(cos(a) * hole, sin(a) * hole, 0)
		var s := centre + Vector3(cos(b) * hole, sin(b) * hole, 0)
		_triangle(vertices, colours, uvs, p, q, s, silver if index % 2 else silver - 0.10)
		_triangle(vertices, colours, uvs, p, s, r, silver if index % 2 else silver - 0.10)
	_mesh(parent, node_name, _array_mesh(vertices, colours, uvs), _vertex_material(false))


func _ribbon_xz(parent: Node3D, node_name: String, start: Vector3, finish: Vector3, width: float, silver: float) -> void:
	var direction: Vector3 = finish - start
	if direction.length_squared() < 0.0001: return
	var side: Vector3 = Vector3(-direction.z, 0, direction.x).normalized() * width * 0.5
	var vertices := PackedVector3Array()
	var colours := PackedColorArray()
	var uvs := PackedVector2Array()
	_triangle(vertices, colours, uvs, start - side, finish - side, finish + side, silver)
	_triangle(vertices, colours, uvs, start - side, finish + side, start + side, silver)
	_mesh(parent, node_name, _array_mesh(vertices, colours, uvs), _vertex_material(false))


func _polygon_xy(parent: Node3D, node_name: String, polygon: PackedVector2Array, z: float, material: StandardMaterial3D) -> void:
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(polygon)
	var vertices := PackedVector3Array()
	var colours := PackedColorArray()
	var uvs := PackedVector2Array()
	for index: int in indices:
		var point: Vector2 = polygon[index]
		vertices.append(Vector3(point.x, point.y, z))
		colours.append(Color.WHITE)
		uvs.append(point * 0.6)
	_mesh(parent, node_name, _array_mesh(vertices, colours, uvs), material)


func _triangle(vertices: PackedVector3Array, colours: PackedColorArray, uvs: PackedVector2Array, a: Vector3, b: Vector3, c: Vector3, silver: float) -> void:
	for vertex: Vector3 in [a, b, c]:
		vertices.append(vertex)
		colours.append(Color(silver, silver, silver))
		uvs.append(Vector2(vertex.x, vertex.z) * 0.5)


func _array_mesh(vertices: PackedVector3Array, colours: PackedColorArray, uvs: PackedVector2Array) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colours
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _group(parent: Node3D, node_name: String, origin: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = node_name
	node.position = origin
	parent.add_child(node)
	return node


func _box(parent: Node3D, node_name: String, origin: Vector3, size: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := _mesh(parent, node_name, mesh, material)
	node.position = origin
	return node


func _mesh(parent: Node3D, node_name: String, mesh: Mesh, material: StandardMaterial3D) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node


func _material(silver: float) -> StandardMaterial3D:
	if _flat_materials.has(silver): return _flat_materials[silver]
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(silver, silver, silver)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_flat_materials[silver] = material
	return material


func _paint(silver: float) -> StandardMaterial3D:
	if _paint_materials.has(silver): return _paint_materials[silver]
	var material := _material(silver).duplicate() as StandardMaterial3D
	material.albedo_texture = RockPaint
	material.texture_repeat = true
	_paint_materials[silver] = material
	return material


func _vertex_material(painted: bool) -> StandardMaterial3D:
	if _vertex_materials.has(painted): return _vertex_materials[painted]
	var material := _material(1.0).duplicate() as StandardMaterial3D
	material.vertex_color_use_as_albedo = true
	if painted:
		material.albedo_texture = RockPaint
		material.texture_repeat = true
	_vertex_materials[painted] = material
	return material
