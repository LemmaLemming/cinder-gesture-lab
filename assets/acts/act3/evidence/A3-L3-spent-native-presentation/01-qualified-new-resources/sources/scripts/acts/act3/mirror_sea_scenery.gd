extends "res://scripts/acts/act3/twin_suns_scenery.gd"
## Original native Mirror Sea shore, adapted from G07/G14/G17/G19.
## Only the continuous floor and four boundaries collide. All water, island,
## polished patches, crystals and spines are scenery with ordinary depth.
## No Echo, recording, resonance hazard, contact exit or local clock lives here.

const SHORE_SHADER: Shader = preload("res://assets/acts/act3/mirror_shore.gdshader")
const SHORE_COLOR: Color = Color("302738")
const WATER_COLOR: Color = Color("24242f")
const CRYSTAL_COLOR: Color = Color("938ca0")
# A native scenic depth translation along the existing fixed viewing angle.
# It preserves the island/sun screen positions while putting them ahead of
# the upper water backdrop. No camera, floor or collision is moved.
const ISLAND_DEPTH_SHIFT: Vector3 = Vector3(0, 1.418686, 1.024607)

var _built: bool = false
var _room: bool = true
var _build_error: String = ""
var _required: Array = []
var _solids: Dictionary = {}
var _solid_specs: Dictionary = {}


func build(room: bool = true, _clear_pockets: bool = false) -> void:
	if _built:
		if room != _room:
			_build_error = "Mirror Sea cannot change a built floor layout"
		return
	_room = room
	var depth: float = 22.0 if room else 108.0
	floor_body = _shore_solid("floor", "MirrorShoreFloor", Vector3(14, 1, depth), Vector3(0, -0.5, 0))
	_shore_solid("west_boundary", "WestBoundary", Vector3(0.5, 2, depth), Vector3(-7.25, 0.8, 0))
	_shore_solid("east_boundary", "EastBoundary", Vector3(0.5, 2, depth), Vector3(7.25, 0.8, 0))
	_shore_solid("north_boundary", "NorthBoundary", Vector3(14.5, 2, 0.5), Vector3(0, 0.8, -depth * 0.5 - 0.25))
	_shore_solid("south_boundary", "SouthBoundary", Vector3(14.5, 2, 0.5), Vector3(0, 0.8, depth * 0.5 + 0.25))
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(14, 1, depth)
	var floor_view := MeshInstance3D.new()
	floor_view.name = "DryMineralSurface"
	floor_view.mesh = floor_mesh
	var shore_material := ShaderMaterial.new()
	shore_material.shader = SHORE_SHADER
	floor_view.material_override = shore_material
	floor_view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	floor_body.add_child(floor_view)
	_required.append(floor_view)
	for side: float in [-1.0, 1.0]:
		# Water starts beyond the permanent safe shelf. Its top is below Y=0;
		# there is no water physics, swimming, resource effect or hidden gap.
		var water: MeshInstance3D = _box(Vector3(20, 0.03, depth + 24.0), Vector3(side * 17.1, -0.05, 0), WATER_COLOR)
		water.name = "WestScenicWater" if side < 0.0 else "EastScenicWater"
		_keep_mesh(water)
		var lip: MeshInstance3D = _box(Vector3(0.18, 0.035, depth), Vector3(side * 6.91, 0.0175, 0), Color("514554"))
		lip.name = "WestFilledShoreEdge" if side < 0.0 else "EastFilledShoreEdge"
		_keep_mesh(lip)
	var courses: Array[float] = []
	courses.assign([-7.0, 0.0, 7.0] if room else [-46.0, -34.0, -22.0, -10.0, 2.0, 14.0, 26.0, 38.0, 46.0])
	for index: int in range(courses.size()):
		var z: float = courses[index]
		for side: float in [-1.0, 1.0]:
			_coast_facet(Vector3(side * 8.15, -0.035, z), side, index)
			_rock_spine(Vector3(side * 7.95, -0.025, z - 0.7), 0.50 + float(index % 3) * 0.18, side)
			_keep_mesh(get_child(get_child_count() - 1) as MeshInstance3D)
			_crystal_shrub(Vector3(side * 8.0, 0, z + 1.0), side, index)
			_polished_patch(Vector3(side * 4.8, 0.005, z + 0.2), index)
	_close_mineral_accent(Vector3(2.4, 0.007, 1.7))
	_build_shore_band()
	_built = true
	follow_landmarks(Vector3.ZERO)


## Stable body IDs for shared actual-geometry bindings; the floor is separate.
func blockers() -> Dictionary:
	var result: Dictionary = _solids.duplicate()
	result.erase("floor")
	return result


func follow_landmarks(hero_position: Vector3) -> void:
	if not _built or not hero_position.is_finite() or not is_instance_valid(_sun_motifs):
		return
	# Only a distant scenic band follows. Floor, solids, coast and crystals
	# stay fixed; no source phase or input/camera authority is consulted.
	_sun_motifs.position = Vector3(hero_position.x, 0, hero_position.z)


func runtime_error() -> String:
	if not _build_error.is_empty():
		return _build_error
	if not _built or not is_inside_tree() or is_queued_for_deletion():
		return "Mirror Sea requires its built live scenery root"
	if global_transform != Transform3D.IDENTITY:
		return "Mirror Sea requires its authored untransformed world floor"
	for candidate: Variant in _required:
		if not is_instance_valid(candidate):
			return "Mirror Sea requires its live authored scenery dependencies"
		var node: Node = candidate as Node
		if node.is_queued_for_deletion() or not node.is_inside_tree() or not is_ancestor_of(node):
			return "Mirror Sea requires its live authored scenery dependencies"
		if node is MeshInstance3D:
			var view: MeshInstance3D = node as MeshInstance3D
			if not is_instance_valid(view.mesh) or not is_instance_valid(view.material_override):
				return "Mirror Sea requires its authored mesh and material resources"
	if not is_instance_valid(floor_body) or _solids.get("floor") != floor_body or _solids.size() != 5:
		return "Mirror Sea requires its actual floor and four boundaries"
	for id: String in _solid_specs:
		var body: StaticBody3D = _solids.get(id) as StaticBody3D
		if not is_instance_valid(body):
			return "Mirror Sea requires live stationary solid " + id
		var spec: Dictionary = _solid_specs[id]
		if body.get_parent() != self or body.transform != spec["transform"] or body.global_transform != spec["transform"] or body.collision_layer != 1 or body.collision_mask != 0:
			return "Mirror Sea stationary solid differs: " + id
		if body.constant_linear_velocity != Vector3.ZERO or body.constant_angular_velocity != Vector3.ZERO or body.disable_mode != spec["disable_mode"]:
			return "Mirror Sea requires stationary native solid state: " + id
		if body.get_child_count() == 0 or body.get_child(0) != spec["collision"]:
			return "Mirror Sea requires the first named Solid collider: " + id
		var collision: CollisionShape3D = body.get_child(0) as CollisionShape3D
		if not is_instance_valid(collision) or collision.name != "Solid" or collision.disabled or collision.transform != Transform3D.IDENTITY:
			return "Mirror Sea requires the active native Solid collider: " + id
		if not collision.shape is BoxShape3D or collision.shape != spec["shape"]:
			return "Mirror Sea native solid shape differs: " + id
		var shape: BoxShape3D = collision.shape as BoxShape3D
		if shape.size != spec["size"] or shape.margin != spec["margin"]:
			return "Mirror Sea native solid dimensions differ: " + id
	return ""


func _shore_solid(id: String, label: String, size: Vector3, at: Vector3) -> StaticBody3D:
	var body: StaticBody3D = _solid_box(label, size, at)
	var collision: CollisionShape3D = body.get_child(0) as CollisionShape3D
	_solids[id] = body
	_solid_specs[id] = {
		"transform": body.transform, "size": size, "collision": collision,
		"shape": collision.shape, "margin": collision.shape.margin,
		"disable_mode": body.disable_mode,
	}
	_required.append(body)
	return body


func _keep_mesh(view: MeshInstance3D) -> void:
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_required.append(view)


func _polished_patch(at: Vector3, index: int) -> void:
	# Filled broad irregular plates, not routes, rings, arrows or tell edges.
	var contour := PackedVector2Array([
		Vector2(-1.15, -1.8), Vector2(0.25, -2.0), Vector2(1.3, -0.75),
		Vector2(1.1, 0.8), Vector2(0.15, 1.7), Vector2(-1.25, 1.15),
		Vector2(-1.45, -0.15),
	])
	var patch: MeshInstance3D = _floor_polygon(contour, at, SHORE_COLOR.lightened(0.022 + float(index % 2) * 0.01))
	patch.name = "QuietPolishedPlate"
	_keep_mesh(patch)


func _coast_facet(at: Vector3, side: float, index: int) -> void:
	# The complete raised coast sits beyond the ±7 permanent floor edge.
	var rim: Array[Vector3] = [Vector3(-0.8, 0, -1.8), Vector3(0.9, 0, -1.3), Vector3(1.05, 0, 0.7), Vector3(0.1, 0, 1.9), Vector3(-0.9, 0, 0.8)]
	var center := Vector3(side * 0.12, 0.24 + float(index % 2) * 0.06, 0)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(rim.size()):
		_triangle(surface, center, rim[i], rim[(i + 1) % rim.size()], Color("302b39").lightened(float(i % 3) * 0.028))
	var view := MeshInstance3D.new()
	view.name = "FacetedOffFloorCoast"
	view.mesh = surface.commit()
	view.material_override = _vertex_material()
	view.position = at
	add_child(view)
	_keep_mesh(view)


func _close_mineral_accent(at: Vector3) -> void:
	# One low filled mineral inset in the close court, not a raised crystal
	# obstacle or actionable cluster. The broad facets have no tell outline.
	var contour := PackedVector2Array([
		Vector2(-0.45, -0.22), Vector2(-0.06, -0.36),
		Vector2(0.40, -0.17), Vector2(0.53, 0.16),
		Vector2(0.17, 0.35), Vector2(-0.43, 0.16),
	])
	var base: MeshInstance3D = _floor_polygon(contour, at, Color("514754"))
	base.name = "CloseShoreMineral"
	_keep_mesh(base)
	var pale: MeshInstance3D = _floor_polygon(PackedVector2Array([
		Vector2(-0.45, -0.22), Vector2(-0.06, -0.36),
		Vector2(0.40, -0.17), Vector2(0.02, 0.02),
	]), at + Vector3(0, 0.001, 0), Color("5e5164"))
	pale.name = "CloseShoreMineralFacet"
	_keep_mesh(pale)
	var dark: MeshInstance3D = _floor_polygon(PackedVector2Array([
		Vector2(0.02, 0.02), Vector2(0.53, 0.16),
		Vector2(0.17, 0.35), Vector2(-0.43, 0.16),
	]), at + Vector3(0, 0.001, 0), Color("423b4b"))
	dark.name = "CloseShoreMineralFacet"
	_keep_mesh(dark)


func _crystal_shrub(at: Vector3, side: float, index: int) -> void:
	# Sparse grounded mineral branches; no local glint, emission, pickup or
	# enemy-opening cue. All extents remain outside the permanent floor.
	for branch: int in range(3):
		var offset := Vector3(side * float(branch) * 0.19, 0, float(branch - 1) * 0.16)
		var height: float = 0.36 + float((branch + index) % 3) * 0.13
		var radius: float = 0.10 + float(branch % 2) * 0.025
		var base: Array[Vector3] = [Vector3(-radius, 0, -radius), Vector3(radius, 0, -radius), Vector3(radius, 0, radius), Vector3(-radius, 0, radius)]
		var shoulder := Vector3(side * 0.06, height * 0.72, 0)
		var tip := Vector3(side * 0.1, height, -0.03)
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i: int in range(4):
			var next: int = (i + 1) % 4
			var shade: Color = CRYSTAL_COLOR.darkened(float(i % 3) * 0.1)
			_triangle(surface, base[i], shoulder + base[i] * 0.65, base[next], shade)
			_triangle(surface, base[next], shoulder + base[i] * 0.65, shoulder + base[next] * 0.65, shade)
			_triangle(surface, shoulder + base[i] * 0.65, tip, shoulder + base[next] * 0.65, shade.lightened(0.035))
		var view := MeshInstance3D.new()
		view.name = "ScenicCrystalBranch"
		view.mesh = surface.commit()
		view.material_override = _vertex_material()
		view.position = at + offset
		add_child(view)
		_keep_mesh(view)


func _build_shore_band() -> void:
	_sun_motifs = Node3D.new()
	_sun_motifs.name = "MirrorSeaDistantBand"
	add_child(_sun_motifs)
	_required.append(_sun_motifs)
	# Opaque backdrop planes sit well behind the local floor along the fixed
	# camera's away direction. Normal depth remains enabled for every mesh.
	_band_plane("DoubledSky", Vector2(40, 9), Vector3(0, -8.8, -14.6), Color("38373d"))
	# The first portraits put water above the island and buried the shore
	# identity. This upper backdrop now extends below its island waterline.
	# All corners stay above the opaque shelf; ordinary depth remains on.
	_band_plane("StillDistantSea", Vector2(40, 1.55), Vector3(0, 1.0, -4.8), Color("28323e"))
	_white_sun = _orb(_sun_motifs, "Branchspell", Vector3(-1.6, 0.55, -5.3) + ISLAND_DEPTH_SHIFT, 0.48, Color("d5d1be"))
	_blue_sun = _orb(_sun_motifs, "Alppain", Vector3(2.0, 0.65, -5.4) + ISLAND_DEPTH_SHIFT, 0.29, Color("64748e"))
	_keep_mesh(_white_sun)
	_keep_mesh(_blue_sun)
	# A small impossible arch and uneven black peaks rise from a broad island
	# waterline. This is distant scenic architecture, never a crossing route.
	var island_base: MeshInstance3D = _band_box(Vector3(3.5, 0.18, 0.7), Vector3(0.65, 0.09, -5.7) + ISLAND_DEPTH_SHIFT, Color("25232f"))
	island_base.name = "SwayloneWaterline"
	for i: int in range(6):
		_rock_spine(Vector3(-0.85 + float(i) * 0.58, 0.09, -5.8 - float(i % 2) * 0.18) + ISLAND_DEPTH_SHIFT, 0.35 + float((i * 3) % 5) * 0.09, -1.0 if i < 3 else 1.0, _sun_motifs)
		_keep_mesh(_sun_motifs.get_child(_sun_motifs.get_child_count() - 1) as MeshInstance3D)
	for side: float in [-1.0, 1.0]:
		_band_box(Vector3(0.24, 0.65, 0.28), Vector3(0.7 + side * 0.43, 0.415, -5.6) + ISLAND_DEPTH_SHIFT, Color("25222e"))
	_band_box(Vector3(1.10, 0.16, 0.28), Vector3(0.7, 0.78, -5.6) + ISLAND_DEPTH_SHIFT, Color("25222e"))
	# Restrained vertical broken island reflections live only in distant water;
	# they are not the Echo reflection and carry no warning or target marker.
	for i: int in range(5):
		_band_plane("DistantIslandReflection", Vector2(0.14 + float(i % 2) * 0.07, 0.16 + float(i % 3) * 0.04), Vector3(-0.7 + float(i) * 0.6, 0.9, -4.26 - float(i % 2) * 0.04), Color("202733"))


func _band_box(size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var view: MeshInstance3D = _box(size, at, color)
	remove_child(view)
	_sun_motifs.add_child(view)
	_keep_mesh(view)
	return view


func _band_plane(label: String, size: Vector2, at: Vector3, color: Color) -> void:
	var view := MeshInstance3D.new()
	view.name = label
	var quad := QuadMesh.new()
	quad.size = size
	view.mesh = quad
	view.position = at
	var material: StandardMaterial3D = _material(color)
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	view.material_override = material
	_sun_motifs.add_child(view)
	_keep_mesh(view)
