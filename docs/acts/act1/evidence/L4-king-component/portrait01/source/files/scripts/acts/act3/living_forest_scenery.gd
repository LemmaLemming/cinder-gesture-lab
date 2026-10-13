class_name CinderAct3LivingForestScenery
extends Node3D
## Original scene-native Wombflash kit. Tall trunks/canopy/mist are scenery.
## Only floor, boundaries and two full-route visible bases receive collision.
## No terrain animation, damage, clock, target group or interaction authority.
## Native authored geometry is an untested candidate until actual portraits.

const FLOOR_SHADER: Shader = preload("res://assets/acts/act3/forest-leaf-floor.gdshader")
const NEAR_BARK: Texture2D = preload("res://assets/acts/act3/forest-bark-albedo-v1.png")
const NEAR_BARK_TILE_HEIGHT: float = 5.6
const BASE_SIZE := Vector3(1.0, 1.4, 1.0)

var floor_body: StaticBody3D
var _built: bool = false
var _room: bool = false
var _build_error: String = ""
var _solids: Dictionary = {}
var _solid_specs: Dictionary = {}
var _required: Array[Node] = []
var _landmarks: Node3D
var _near_west: Node3D
var _near_east: Node3D
var _white_sun: MeshInstance3D
var _blue_sun: MeshInstance3D
var _floor_material: ShaderMaterial
var _bark_material: StandardMaterial3D
var _distant_near_material: StandardMaterial3D
var _distant_far_material: StandardMaterial3D
var _white_material: StandardMaterial3D
var _blue_material: StandardMaterial3D


func build(room: bool = false) -> void:
	if _built:
		if room != _room:
			_build_error = "Living Forest cannot change a built floor layout"
		return
	_room = room
	var depth: float = 22.0 if room else 108.0
	floor_body = _solid("floor", "ForestFloor", Vector3(14, 1, depth), Vector3(0, -0.5, 0))
	_floor_material = ShaderMaterial.new()
	_floor_material.shader = FLOOR_SHADER
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(14, 1, depth)
	_view(floor_body, "WetLeafSurface", floor_mesh, Vector3.ZERO, _floor_material)
	_solid("west_boundary", "WestBoundary", Vector3(0.5, 2, depth), Vector3(-7.25, 0.8, 0))
	_solid("east_boundary", "EastBoundary", Vector3(0.5, 2, depth), Vector3(7.25, 0.8, 0))
	_solid("north_boundary", "NorthBoundary", Vector3(14.5, 2, 0.5), Vector3(0, 0.8, -depth * 0.5 - 0.25))
	_solid("south_boundary", "SouthBoundary", Vector3(14.5, 2, 0.5), Vector3(0, 0.8, depth * 0.5 + 0.25))
	var edge_material: StandardMaterial3D = _material(Color("29222f"))
	_box(self, "WestRootLip", Vector3(0.2, 0.12, depth), Vector3(-7.1, 0.06, 0), edge_material)
	_box(self, "EastRootLip", Vector3(0.2, 0.12, depth), Vector3(7.1, 0.06, 0), edge_material)
	_box(self, "NorthRootLip", Vector3(14.4, 0.12, 0.2), Vector3(0, 0.06, -depth * 0.5 - 0.1), edge_material)
	_box(self, "SouthRootLip", Vector3(14.4, 0.12, 0.2), Vector3(0, 0.06, depth * 0.5 + 0.1), edge_material)
	_bark_material = _material(Color("6e354b"))
	_bark_material.vertex_color_use_as_albedo = true
	# Giant whole trunks live outside the continuous floor. Their planted fused
	# skirts also stay outside; relevant courts retain clear low sightlines.
	var courses: Array[float] = []
	courses.assign([-8.0, 7.0] if room else [-45.0, -28.0, -11.0, 6.0, 23.0, 40.0])
	for i: int in range(courses.size()):
		var z: float = courses[i]
		_giant_trunk(Vector3(-10.2, 0, z), 8.0 + float(i % 3) * 1.2, 1.15, "WestTrunk" + str(i))
		_giant_trunk(Vector3(10.2, 0, z - 5.0), 9.2 + float(i % 2), 1.25, "EastTrunk" + str(i))
	if not room:
		# Only low sections are central. A towering central billboard/column
		# would hide the approach and opening behind an otherwise legal base.
		_fixed_base("two_approaches", "TwoApproachesBase", Vector3(0, 0, 8))
		_fixed_base("crossing", "CrossingBase", Vector3(0, 0, -13))
	_build_landmarks()
	_built = true
	show_sun(0, "hold")
	follow_landmarks(Vector3.ZERO)


## Defensive stable IDs -> actual StaticBody3D, excluding the public floor.
## Callers read each body's named Solid CollisionShape3D for shared bindings.
func blockers() -> Dictionary:
	var result: Dictionary = _solids.duplicate()
	result.erase("floor")
	return result


func show_sun(state: int, stage: String) -> void:
	if not _built or state not in [0, 1] or not is_instance_valid(_white_sun) or not is_instance_valid(_blue_sun):
		return
	_floor_material.set_shader_parameter("blue_sun", float(state))
	_bark_material.albedo_color = Color("6e354b") if state == 0 else Color("59405b")
	_distant_near_material.albedo_color = Color("984654") if state == 0 else Color("774864")
	_distant_far_material.albedo_color = Color("613c54") if state == 0 else Color("534461")
	_white_material.albedo_color = Color("d4cebd") if state == 0 else Color("aaa7b8")
	_blue_material.albedo_color = Color("506799") if state == 0 else Color("8295bd")
	if stage == "preview" or stage == "lock":
		if state == 0:
			_blue_material.albedo_color = Color("a0aecf")
		else:
			_white_material.albedo_color = Color("e1dbc9")


## Far scenery follows X/Z. Near trunks follow Z and only outward X, keeping
## fixed court sources clear as the Hero crosses the centre. No phase/clock cue.
func follow_landmarks(hero_position: Vector3) -> void:
	if not _built or not hero_position.is_finite():
		return
	if is_instance_valid(_landmarks):
		_landmarks.position = Vector3(hero_position.x, 0, hero_position.z)
	if is_instance_valid(_near_west):
		_near_west.position = Vector3(minf(hero_position.x, 0.0), 0, hero_position.z)
	if is_instance_valid(_near_east):
		_near_east.position = Vector3(maxf(hero_position.x, 0.0), 0, hero_position.z)


func runtime_error() -> String:
	if not _built or not _build_error.is_empty():
		return _build_error if not _build_error.is_empty() else "Living Forest is not built"
	if not is_instance_valid(floor_body) or floor_body != _solids.get("floor"):
		return "Living Forest requires its actual floor body"
	# Test validity before typed node conversion: freed-node references must
	# reject normally rather than throwing while constructing a typed list.
	for value: Variant in _required:
		if not is_instance_valid(value):
			return "Living Forest scenery dependency was removed"
		var node: Node = value as Node
		if node.is_queued_for_deletion() or not node.is_inside_tree() or not is_ancestor_of(node):
			return "Living Forest requires its live owned scenery"
	for id: String in _solids:
		var body: StaticBody3D = _solids[id] as StaticBody3D
		var spec: Dictionary = _solid_specs[id]
		if not is_instance_valid(body) or body.transform != Transform3D(Basis.IDENTITY, spec.at) or body.collision_layer != 1 or body.collision_mask != 0:
			return "Living Forest fixed body changed: " + id
		var collider: CollisionShape3D = body.get_node_or_null("Solid") as CollisionShape3D
		if not is_instance_valid(collider) or collider.disabled or collider.transform != Transform3D.IDENTITY or collider.shape != spec.shape:
			return "Living Forest fixed collision changed: " + id
		var shape: BoxShape3D = collider.shape as BoxShape3D
		if shape == null or shape.size != spec.size:
			return "Living Forest box dimensions changed: " + id
	if not is_instance_valid(_landmarks) or not is_instance_valid(_white_sun) or not is_instance_valid(_blue_sun) or _white_sun.get_parent() != _landmarks or _blue_sun.get_parent() != _landmarks:
		return "Living Forest requires its live scenic suns"
	if not is_instance_valid(_near_west) or not is_instance_valid(_near_east) or _near_west.get_parent() != self or _near_east.get_parent() != self:
		return "Living Forest requires its independent near scenic bands"
	return ""


func _solid(id: String, label: String, size: Vector3, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	var collider := CollisionShape3D.new()
	collider.name = "Solid"
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	add_child(body)
	_solids[id] = body
	_solid_specs[id] = {"at": at, "size": size, "shape": shape}
	_required.append(body)
	_required.append(collider)
	return body


func _fixed_base(id: String, label: String, at: Vector3) -> void:
	var body: StaticBody3D = _solid(id, label, BASE_SIZE, at + Vector3(0, 0.7, 0))
	# The square fused footing fills the actual1x1 collider footprint; upper
	# flutes/buttresses stay inside that visible footprint, not invisible roots.
	_box(body, "FusedFooting", Vector3(1, 0.28, 1), Vector3(0, -0.56, 0), _bark_material)
	_view(body, "RibbedLowSection", _fluted_mesh(1.4, 0.46), Vector3(0, -0.7, 0), _bark_material)
	_view(body, "Buttresses", _root_mesh(0.49, 0.8), Vector3(0, -0.7, 0), _bark_material)


func _giant_trunk(at: Vector3, height: float, radius: float, label: String) -> void:
	var tree := Node3D.new()
	tree.name = label
	tree.position = at
	add_child(tree)
	_required.append(tree)
	_view(tree, "ImmenseFlutedTrunk", _fluted_mesh(height, radius), Vector3.ZERO, _bark_material)
	_view(tree, "VisibleFusedRoots", _root_mesh(radius * 1.6, 1.35), Vector3.ZERO, _bark_material)
	# Sparse canopy rises with the edge tree, never bridges its court to the
	# opposite trunk. All these upper forms are noncolliding scenic meshes.
	for i: int in range(3):
		var canopy := SphereMesh.new()
		canopy.radius = radius * (1.35 + float(i) * 0.18)
		canopy.height = radius * 0.60
		canopy.radial_segments = 8
		canopy.rings = 3
		_view(tree, "HighCanopy" + str(i), canopy, Vector3(0.3 * float(i - 1), height - 0.8 + float(i) * 0.5, 0.2 * float(i)), _material(Color("30283e")))


func _build_landmarks() -> void:
	_landmarks = Node3D.new()
	_landmarks.name = "ForestDistantBand"
	add_child(_landmarks)
	_required.append(_landmarks)
	var backdrop := QuadMesh.new()
	backdrop.size = Vector2(40, 10)
	var sky_material: StandardMaterial3D = _material(Color("37313f"))
	sky_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	# Actual first portraits lost lower columns behind the nearer billboard
	# plane. Move only this backdrop behind the complete scenic tree roots.
	# Shift along the fixed camera's away axis (18Y:13Z), preserving the
	# backdrop's projected placement while correcting its actual depth.
	_view(_landmarks, "DistantMistySky", backdrop, Vector3(0, -8.8, -16.0), sky_material)
	_distant_near_material = _material(Color("984654"))
	_distant_near_material.albedo_texture = NEAR_BARK
	_distant_near_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_distant_near_material.texture_repeat = true
	_distant_far_material = _material(Color("613c54"))
	_distant_near_material.vertex_color_use_as_albedo = true
	_distant_far_material.vertex_color_use_as_albedo = true
	# Broad cropped red folds and fused roots make scale visible in the actual
	# close portrait. This scenic translation is not a physical court boundary.
	# Forward/lateral source and landing occlusion still needs actual portraits.
	for side: float in [-1.0, 1.0]:
		var near_band := Node3D.new()
		near_band.name = "WestNearForestBand" if side < 0.0 else "EastNearForestBand"
		add_child(near_band)
		_required.append(near_band)
		if side < 0.0:
			_near_west = near_band
		else:
			_near_east = near_band
		for i: int in range(2):
			# Planted near folds use phase-independent outward-only bands.
			# The extra west .25 keeps the sampled watched crescent edge open;
			# native source/landing/outline views must still confirm opacity.
			# The far pair keeps its previous native placement and mesh shape.
			var near_x: float = 4.25 if side > 0.0 else -4.50
			var at := Vector3(near_x, 0, -1.2) if i == 0 else Vector3(side * 5.1, -0.65, -7.8)
			var parent: Node3D = near_band if i == 0 else _landmarks
			var scenic_side: float = side if i == 0 else 0.0
			var radius: float = 1.45 + float(i) * 0.30
			var height: float = 11.2 + float(i) * 1.8
			var material: StandardMaterial3D = _distant_near_material if i == 0 else _distant_far_material
			var label: String = ("West" if side < 0 else "East") + "DistantTrunk" + str(i)
			_view(parent, label, _folded_trunk_mesh(height, radius, scenic_side), at, material)
			_view(parent, label + "FusedRoots", _root_mesh(1.8 + float(i) * 0.25, 1.15 + float(i) * 0.30, scenic_side), at, material)
			var shelf := SphereMesh.new()
			shelf.radius = 1.65 + float(i) * 0.15
			shelf.height = 0.42
			shelf.radial_segments = 8
			shelf.rings = 3
			_view(parent, label + "CanopyShelf", shelf, at + Vector3(side * 0.65, 3.0 + float(i), -0.1), _material(Color("342b40")))
		# Faceted quiet mist tones are background layers, never alpha overlays
		# over playable ground or hazard fills. No transparency sorting trick.
		var mist := QuadMesh.new()
		mist.size = Vector2(2.4, 0.65)
		var mist_material: StandardMaterial3D = _material(Color("514655"))
		mist_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_view(_landmarks, "MistEdge" + str(int(side)), mist, Vector3(side * 4.2, -0.55, -7.0), mist_material)
	_white_material = _material(Color("d4cebd"))
	_blue_material = _material(Color("506799"))
	# Separate the opaque white disc from the completed dry contact marker.
	_white_sun = _orb("Branchspell", Vector3(-2.25, 0.95, -5.2), 0.55, _white_material)
	_blue_sun = _orb("Alppain", Vector3(1.1, 1.12, -4.9), 0.38, _blue_material)


func _folded_trunk_mesh(height: float, radius: float, scenic_side: float = 0.0) -> ArrayMesh:
	var vertices: Array[Vector3] = []
	var colors: Array[Color] = []
	var levels: Array[float] = [0.0, 0.10, 0.30, 0.60, 1.0]
	var widths: Array[float] = [1.10, 1.0, 0.93, 0.87, 0.80]
	# Optional near-pair variation stays within the original 1.10R envelope.
	# The outward bend reaches 0.25R at the top; defaults retain the old mesh.
	var furrows: Array[float] = [1.0, 0.61, 0.96, 0.55, 0.99, 0.64, 0.93, 0.57, 1.0, 0.60, 0.97, 0.54, 0.94, 0.63, 0.98, 0.58]
	for ring: int in range(levels.size() - 1):
		for i: int in range(16):
			var angle0: float = TAU * float(i) / 16.0
			var angle1: float = TAU * float(i + 1) / 16.0
			var fold0: float = 1.0 if i % 2 == 0 else 0.58
			var fold1: float = 1.0 if (i + 1) % 2 == 0 else 0.58
			if scenic_side != 0.0:
				fold0 = furrows[i]
				fold1 = furrows[(i + 1) % 16]
			var bottom: float = levels[ring]
			var top: float = levels[ring + 1]
			var a := Vector3(cos(angle0) * radius * fold0 * widths[ring], bottom * height, sin(angle0) * radius * fold0 * widths[ring])
			var b := Vector3(cos(angle1) * radius * fold1 * widths[ring], bottom * height, sin(angle1) * radius * fold1 * widths[ring])
			var c := Vector3(cos(angle1) * radius * fold1 * widths[ring + 1], top * height, sin(angle1) * radius * fold1 * widths[ring + 1])
			var d := Vector3(cos(angle0) * radius * fold0 * widths[ring + 1], top * height, sin(angle0) * radius * fold0 * widths[ring + 1])
			if scenic_side != 0.0:
				var lower_bend := Vector3(scenic_side * radius * 0.25 * bottom * bottom, 0, 0)
				var upper_bend := Vector3(scenic_side * radius * 0.25 * top * top, 0, 0)
				a += lower_bend
				b += lower_bend
				c += upper_bend
				d += upper_bend
			var tint := Color(1.04, 0.93, 0.91) if i % 2 == 0 else Color(0.52, 0.57, 0.70)
			_triangle(vertices, colors, a, b, c, tint)
			_triangle(vertices, colors, a, c, d, tint)
			if ring == levels.size() - 2:
				var crown := Vector3(0, height, 0)
				if scenic_side != 0.0:
					crown.x = scenic_side * radius * 0.25
				_triangle(vertices, colors, crown, d, c, Color(0.40, 0.38, 0.51))
	if scenic_side != 0.0:
		return _mesh(vertices, colors, _near_fold_uvs(vertices, height, radius, scenic_side))
	return _mesh(vertices, colors)


## UV-only angular mapping. Undo the known scenic bend for the native x/z
## angle; never change the supplied vertices, colours or triangle order.
func _near_fold_uvs(vertices: Array[Vector3], height: float, radius: float, scenic_side: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for start: int in range(0, vertices.size(), 3):
		var triangle_uvs: Array[Vector2] = []
		for i: int in range(3):
			var point: Vector3 = vertices[start + i]
			var level: float = point.y / height
			var unbent_x: float = point.x - scenic_side * radius * 0.25 * level * level
			var u: float = fposmod(atan2(point.z, unbent_x) / TAU, 1.0)
			triangle_uvs.append(Vector2(u, point.y / NEAR_BARK_TILE_HEIGHT))
		var minimum_u: float = minf(triangle_uvs[0].x, minf(triangle_uvs[1].x, triangle_uvs[2].x))
		var maximum_u: float = maxf(triangle_uvs[0].x, maxf(triangle_uvs[1].x, triangle_uvs[2].x))
		for uv: Vector2 in triangle_uvs:
			if maximum_u - minimum_u > 0.5 and uv.x < 0.5:
				uv.x += 1.0
			result.append(uv)
	return result


func _fluted_mesh(height: float, radius: float) -> ArrayMesh:
	var vertices: Array[Vector3] = []
	var colors: Array[Color] = []
	var levels: Array[float] = [0.0, 0.32, 0.68, 1.0]
	for ring: int in range(levels.size() - 1):
		for i: int in range(16):
			var angle0: float = TAU * float(i) / 16.0
			var angle1: float = TAU * float(i + 1) / 16.0
			var flute0: float = 1.0 if i % 2 == 0 else 0.78
			var flute1: float = 1.0 if (i + 1) % 2 == 0 else 0.78
			var bottom: float = levels[ring]
			var top: float = levels[ring + 1]
			var a := Vector3(cos(angle0) * radius * flute0 * (1.0 - bottom * 0.20), bottom * height, sin(angle0) * radius * flute0 * (1.0 - bottom * 0.20))
			var b := Vector3(cos(angle1) * radius * flute1 * (1.0 - bottom * 0.20), bottom * height, sin(angle1) * radius * flute1 * (1.0 - bottom * 0.20))
			var c := Vector3(cos(angle1) * radius * flute1 * (1.0 - top * 0.20), top * height, sin(angle1) * radius * flute1 * (1.0 - top * 0.20))
			var d := Vector3(cos(angle0) * radius * flute0 * (1.0 - top * 0.20), top * height, sin(angle0) * radius * flute0 * (1.0 - top * 0.20))
			var tint := Color(0.72 + float(i % 3) * 0.10, 0.76 + float(i % 2) * 0.08, 0.84, 1)
			_triangle(vertices, colors, a, b, c, tint)
			_triangle(vertices, colors, a, c, d, tint)
			if ring == levels.size() - 2:
				_triangle(vertices, colors, Vector3(0, height, 0), d, c, Color(0.48, 0.46, 0.58))
	return _mesh(vertices, colors)


func _root_mesh(radius: float, height: float, scenic_side: float = 0.0) -> ArrayMesh:
	var vertices: Array[Vector3] = []
	var colors: Array[Color] = []
	for i: int in range(4):
		var angle: float = TAU * float(i) / 4.0
		var along := Vector3(cos(angle), 0, sin(angle))
		# Only the grounded near following pair omits its inward scenic arm.
		# Physical, edge and far roots retain all four default buttresses.
		if scenic_side != 0.0 and along.x * scenic_side < -0.5:
			continue
		var across := Vector3(-sin(angle), 0, cos(angle))
		var tip: Vector3 = along * radius + Vector3(0, 0.025, 0)
		var left: Vector3 = along * radius * 0.20 - across * radius * 0.27 + Vector3(0, 0.025, 0)
		var right: Vector3 = along * radius * 0.20 + across * radius * 0.27 + Vector3(0, 0.025, 0)
		var top: Vector3 = along * radius * 0.26 + Vector3(0, height, 0)
		_triangle(vertices, colors, left, tip, top, Color(0.70, 0.73, 0.82))
		_triangle(vertices, colors, tip, right, top, Color(0.92, 0.83, 0.88))
		_triangle(vertices, colors, right, left, top, Color(0.54, 0.61, 0.71))
	if scenic_side != 0.0:
		var uvs := PackedVector2Array()
		for point: Vector3 in vertices:
			uvs.append(Vector2(point.x, point.z) / NEAR_BARK_TILE_HEIGHT + Vector2(0.5, 0.5))
		return _mesh(vertices, colors, uvs)
	return _mesh(vertices, colors)


func _triangle(vertices: Array[Vector3], colors: Array[Color], a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	vertices.append_array([a, b, c])
	colors.append_array([color, color, color])


func _mesh(vertices: Array[Vector3], colors: Array[Color], uvs: PackedVector2Array = PackedVector2Array()) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray(colors)
	if not uvs.is_empty():
		arrays[Mesh.ARRAY_TEX_UV] = uvs
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result


func _orb(label: String, at: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	return _view(_landmarks, label, sphere, at, material)


func _box(parent: Node3D, label: String, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _view(parent, label, mesh, at, material)


func _view(parent: Node3D, label: String, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.name = label
	view.mesh = mesh
	view.position = at
	view.material_override = material
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(view)
	_required.append(view)
	return view


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	return material
