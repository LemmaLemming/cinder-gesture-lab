extends Node3D
## Original scene-native shelf/scenery kit, adapted from G05/G17/G18.
## Every scenic mesh is non-colliding. Only authored floor/walls/low trunks
## receive separate, stationary collision. White shadows never authorize hits.

const SAND_SHADER: Shader = preload("res://assets/acts/act3/scarlet_sand.gdshader")
const TREE_PATH: String = "res://assets/acts/act3/twin-suns-violet-tree.png"
const COMPANIONS_PATH: String = "res://assets/acts/act3/compassion-companions.png"
const SCARLET: Color = Color("8b243d")
const VIOLET: Color = Color("382043")
const ROCK: Color = Color("151320")
const SHADOW: Color = Color("a08c9f")

var floor_body: StaticBody3D
var _sun_motifs: Node3D
var _white_sun: MeshInstance3D
var _blue_sun: MeshInstance3D
var _scenic_shadows: Array[MeshInstance3D] = []


func build(room: bool) -> void:
	var depth: float = 22.0 if room else 108.0
	floor_body = _solid_box("SafeShelfFloor", Vector3(14, 1, depth), Vector3(0, -0.5, 0))
	var sand := ShaderMaterial.new()
	sand.shader = SAND_SHADER
	var surface := BoxMesh.new()
	surface.size = Vector3(14, 1, depth)
	var floor_view := MeshInstance3D.new()
	floor_view.mesh = surface
	floor_view.material_override = sand
	floor_body.add_child(floor_view)
	# Continuous safe floor extends to solid boundaries; no lethal scenic edge.
	_solid_box("WestBoundary", Vector3(0.5, 2, depth), Vector3(-7.25, 0.8, 0))
	_solid_box("EastBoundary", Vector3(0.5, 2, depth), Vector3(7.25, 0.8, 0))
	_solid_box("NorthBoundary", Vector3(14.5, 2, 0.5), Vector3(0, 0.8, -depth * 0.5 - 0.25))
	_solid_box("SouthBoundary", Vector3(14.5, 2, 0.5), Vector3(0, 0.8, depth * 0.5 + 0.25))
	var courses: Array[float] = []
	courses.assign([-7.0, 0.0, 7.0] if room else [-46.0, -37.0, -28.0, -19.0, -10.0, -1.0, 8.0, 17.0, 26.0, 35.0, 44.0])
	for i: int in range(courses.size()):
		var z: float = courses[i]
		# Raised noncolliding dressing stays beyond the solid playable boundary,
		# where it cannot cover a legal actor position or safe landing.
		_shelf_dressing(Vector3(-8.9, 0, z), i, -1.0)
		_shelf_dressing(Vector3(9.1, 0, z - 2.5), i + 3, 1.0)
	if room:
		_low_tree(Vector3(-2.8, 0, 1.0), "WestLowTree", false)
		_low_tree(Vector3(2.8, 0, 2.6), "EastLowTree", false)
		_pillars(Vector3(-8.5, 0, -8.0), 3)
	else:
		# Foreign noon / useful flank / two approaches / crossing / departure.
		_low_tree(Vector3(-3.0, 0, 41.5), "ArrivalTree", false)
		_low_tree(Vector3(3.0, 0, 26.0), "FlankTree", false)
		_low_tree(Vector3(0, 0, 8.0), "TwoApproachesTree", true)
		_low_tree(Vector3(0, 0, -13.0), "CrossingTree", true)
		_low_tree(Vector3(-3.1, 0, -30.0), "DepartureTree", false)
		_pillars(Vector3(-9.8, 0, 40.0), 4)
		_pillars(Vector3(8.0, 0, -39.0), 5)
		_clear_water_alcove(Vector3(-4.7, 0, 32.0))
		_companion_vignette(Vector3(-4.7, 0, 29.7))
	_sun_motifs = Node3D.new()
	_sun_motifs.name = "ScenicSuns"
	add_child(_sun_motifs)
	var sky := MeshInstance3D.new()
	sky.name = "DistantSkyBand"
	var quad := QuadMesh.new()
	quad.size = Vector2(40, 6)
	sky.mesh = quad
	sky.position = Vector3(0, 2, -8.2)
	var sky_material := _material(Color("30263d"))
	sky_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	sky.material_override = sky_material
	_sun_motifs.add_child(sky)
	_white_sun = _orb(_sun_motifs, "Branchspell", Vector3(-3.5, 3.1, -5.8), 1.45, Color("e5dece"))
	_blue_sun = _orb(_sun_motifs, "Alppain", Vector3(2.9, 3.6, -6.7), 0.82, Color("5171b7"))


func follow_landmarks(hero_position: Vector3) -> void:
	# A scenery-only sky motif stays in the distant upper framing band. It has
	# no physics, aiming transform, warning footprint or gameplay authority.
	_sun_motifs.position = Vector3(hero_position.x, 0, hero_position.z)


func show_sun(state: int, stage: String) -> void:
	_white_sun.material_override = _material(Color("e5dece") if state == 0 else Color("bbb6c6"))
	_blue_sun.material_override = _material(Color("5171b7") if state == 0 else Color("829dd7"))
	for shadow: MeshInstance3D in _scenic_shadows:
		shadow.material_override = _material(SHADOW if state == 0 else Color("827b98"))
	# Preview brightens the coming sun, then holds. It changes scenery only.
	if stage == "preview" or stage == "lock":
		var incoming: MeshInstance3D = _blue_sun if state == 0 else _white_sun
		incoming.material_override = _material(Color("a5b6df") if state == 0 else Color("f0e9db"))


func runtime_error() -> String:
	# Snapshot validation must cover every node that its commit dereferences.
	# Retired scenery rejects before any local sun/clock fields can change.
	# Check validity before constructing a typed node list: Godot rejects a
	# previously freed reference during that construction, before iteration.
	if not is_instance_valid(floor_body) or not is_instance_valid(_sun_motifs) or not is_instance_valid(_white_sun) or not is_instance_valid(_blue_sun):
		return "Twin Suns requires its live authored floor and sun scenery"
	for node: Node in [floor_body, _sun_motifs, _white_sun, _blue_sun]:
		if not is_instance_valid(node) or node.is_queued_for_deletion() or not node.is_inside_tree() or not is_ancestor_of(node):
			return "Twin Suns requires its live authored floor and sun scenery"
	if _scenic_shadows.is_empty():
		return "Twin Suns requires its authored scenic casts"
	for shadow: MeshInstance3D in _scenic_shadows:
		if not is_instance_valid(shadow) or shadow.is_queued_for_deletion() or not shadow.is_inside_tree() or not is_ancestor_of(shadow):
			return "Twin Suns requires its live authored scenic casts"
	return ""


func _solid_box(label: String, size: Vector3, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	add_child(body)
	return body


func _shelf_dressing(at: Vector3, index: int, side: float) -> void:
	_faceted_ledge(at, side, index)
	for j: int in range(3):
		var height: float = 1.2 + float((index + j) % 4) * 0.48
		_rock_spine(at + Vector3(side * float(j) * 0.35, 0.2, float(j) * 1.05 - 1.0), height, side)
	for j: int in range(4):
		var pebble := _box(Vector3(0.34, 0.16, 0.45), at + Vector3(-side * 1.4, 0.07, float(j) * 0.7 - 1.0), Color("5b2b55"))
		pebble.rotation_degrees.y = float(j * 27 + index * 15)


func _low_tree(at: Vector3, label: String, colliding: bool) -> void:
	var tree := Node3D.new()
	tree.name = label
	tree.position = at
	add_child(tree)
	if ResourceLoader.exists(TREE_PATH):
		var texture := load(TREE_PATH) as Texture2D
		var sprite := Sprite3D.new()
		sprite.texture = texture
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		# Native alpha>=0.5 crown-to-root bounds are y314..1137. Root tips
		# share the ground pivot; no transparent padding changes world scale.
		sprite.pixel_size = 1.6 / 823.0
		sprite.offset = Vector2(-6, 510)
		sprite.position.y = 0.025
		tree.add_child(sprite)
	else:
		# Scene-native initial silhouette; replaced by the produced cutout after
		# alpha, native-scale and actual portrait review. No board used as sheet.
		_box(Vector3(0.35, 0.9, 0.4), at + Vector3(0, 0.45, 0), ROCK)
		_box(Vector3(1.75, 0.7, 1.0), at + Vector3(0, 1.1, 0), Color("512a6b"))
		_box(Vector3(1.1, 0.55, 0.7), at + Vector3(0.3, 1.65, 0), Color("70396c"))
	if colliding:
		_solid_box(label + "LowTrunk", Vector3(1.0, 0.75, 1.0), at + Vector3(0, 0.375, 0))
	# A branching cast silhouette has no straight lane edge or arrow-like cap.
	var outline := PackedVector2Array([Vector2(0.32, -0.05), Vector2(0.54, 0.7), Vector2(0.14, 1.1), Vector2(-0.15, 2.4), Vector2(-0.45, 2.9), Vector2(-0.93, 2.55), Vector2(-1.05, 3.1), Vector2(-1.51, 3.35), Vector2(-1.68, 3.1), Vector2(-1.05, 1.6), Vector2(-0.6, 0.5), Vector2(-0.4, 0.2)])
	var shadow := _floor_polygon(outline, at + Vector3(0, 0.011, 0), SHADOW)
	shadow.name = label + "ScenicCast"
	_scenic_shadows.append(shadow)


func _floor_polygon(outline: PackedVector2Array, at: Vector3, color: Color) -> MeshInstance3D:
	var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(outline)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in triangles:
		var point: Vector2 = outline[index]
		surface.add_vertex(Vector3(point.x, 0, point.y))
	var node := MeshInstance3D.new()
	node.mesh = surface.commit()
	node.position = at
	var material := _material(color)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = material
	add_child(node)
	return node


func _faceted_ledge(at: Vector3, side: float, index: int) -> void:
	var points: Array[Vector3] = [Vector3(-1.35, 0.05, -2.4), Vector3(0.6, 0.34, -2.0), Vector3(1.6, 0.12, -0.7), Vector3(1.3, 0.26, 1.8), Vector3(-0.35, 0.38, 2.5), Vector3(-1.55, 0.08, 1.0)]
	var center := Vector3(side * 0.2, 0.45, 0)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(points.size()):
		var shade: Color = VIOLET.lightened(float((i + index) % 3) * 0.035)
		_triangle(surface, center, points[i], points[(i + 1) % points.size()], shade)
	var node := MeshInstance3D.new()
	node.mesh = surface.commit()
	node.position = at
	node.rotation_degrees.y = side * (8.0 + float(index % 3) * 3.0)
	node.material_override = _vertex_material()
	add_child(node)


func _rock_spine(at: Vector3, height: float, side: float) -> void:
	var base: Array[Vector3] = [Vector3(-0.28, 0, -0.38), Vector3(0.32, 0, -0.23), Vector3(0.22, 0, 0.37), Vector3(-0.3, 0, 0.25)]
	var tip := Vector3(side * 0.3, height, -0.2)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(base.size()):
		_triangle(surface, base[i], tip, base[(i + 1) % base.size()], ROCK.lightened(float(i % 3) * 0.025))
	var node := MeshInstance3D.new()
	node.mesh = surface.commit()
	node.position = at
	node.material_override = _vertex_material()
	add_child(node)


func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	for vertex: Vector3 in [a, b, c]:
		surface.set_color(color)
		surface.add_vertex(vertex)


func _vertex_material() -> StandardMaterial3D:
	var material := _material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _pillars(at: Vector3, count: int) -> void:
	for i: int in range(count):
		var height: float = 1.3 + float(i % 3) * 0.8
		_box(Vector3(0.24, height, 0.3), at + Vector3(float(i) * 0.5, height * 0.5, -float(i) * 0.6), Color("918aa3"))
		_box(Vector3(0.46, 0.12, 0.5), at + Vector3(float(i) * 0.5, height, -float(i) * 0.6), Color("b5a7b7"))


func _clear_water_alcove(at: Vector3) -> void:
	# Clear, firm decorative inset: no healing, depth trap or interaction cue.
	var shore := PackedVector2Array([Vector2(-0.9, -1.45), Vector2(0.25, -1.6), Vector2(0.85, -1.1), Vector2(1.1, -0.2), Vector2(0.8, 1.05), Vector2(0.05, 1.6), Vector2(-0.8, 1.15), Vector2(-1.1, 0.2)])
	_floor_polygon(shore, at + Vector3(0, 0.021, 0), Color("496078"))
	for i: int in range(4):
		_box(Vector3(0.35 + float(i % 2) * 0.2, 0.012, 0.035), at + Vector3(float(i % 2) * 0.4 - 0.2, 0.026, float(i) * 0.5 - 0.8), Color("728693"))


func _companion_vignette(at: Vector3) -> void:
	if not ResourceLoader.exists(COMPANIONS_PATH):
		return
	var pair := Node3D.new()
	pair.name = "JoiwindAndPanaweScenery"
	pair.position = at
	add_child(pair)
	var sprite := Sprite3D.new()
	sprite.texture = load(COMPANIONS_PATH) as Texture2D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.5
	sprite.pixel_size = 1.65 / 1130.0
	sprite.offset = Vector2(-8, 547)
	sprite.position.y = 0.025
	pair.add_child(sprite)
	# Named source people are a quiet nonhostile vignette, not combat targets,
	# another player/controller, available pickup, heal or required conversation.


func _box(size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	node.material_override = _material(color)
	add_child(node)
	return node


func _orb(parent: Node3D, label: String, at: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 20
	sphere.rings = 8
	node.mesh = sphere
	node.position = at
	node.material_override = _material(color)
	parent.add_child(node)
	return node


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material
