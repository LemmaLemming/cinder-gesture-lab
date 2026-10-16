class_name Act1LivingMoonScenery
extends Node3D
## Static wrinkled-return/lower-cheek theatre, sharing the existing lunar kit.
## No collision, source, actor, camera, clock, cue, contact or progress authority.

const Layout = preload("res://scripts/acts/act1/living_moon_layout.gd")
const SILVER_TILE = preload("res://assets/acts/act1/lunar/environment/floor_silver_tile.png")
const ROCK_A = preload("res://assets/acts/act1/lunar/environment/rock_flat_low_a.png")
const ROCK_B = preload("res://assets/acts/act1/lunar/environment/rock_flat_low_b.png")
const CRESCENT = preload("res://assets/acts/act1/lunar/environment/crescent_performer.png")
const HUMAN_STAR = preload("res://assets/acts/act1/lunar/accents/human_star_performer.png")
const FLOOR_TILE_WORLD_SIZE: float = 64.0 * 0.024
const LANDMARKS: Array[String] = ["floor", "return-creases", "cheek-creases", "side-flats", "distant-cast"]

var _meshes: Array[MeshInstance3D] = []
var _sprites: Array[Sprite3D] = []
var _landmarks: Dictionary = {}
var _floor_overlay: MeshInstance3D


func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	set_meta("readiness", "authored_source_unparsed_unexecuted_portrait_unverified")
	_build_floor()
	_build_wrinkles()
	_build_flats()
	_build_distant_cast()


func sprites() -> Array[Sprite3D]:
	return _sprites.duplicate()


func floor_overlay() -> MeshInstance3D:
	return _floor_overlay


func presentation_state() -> Dictionary:
	return {"family":"act1_lunar_theatre", "state":"quiet-static", "meshes":_meshes.size(), "sprites":_sprites.size(), "landmarks":LANDMARKS.duplicate()}


func landmark_world_corners(id: String, camera: Camera3D) -> Array[Vector3]:
	if id not in LANDMARKS or not _actual_camera(camera): return [Vector3.INF]
	var points: Array[Vector3] = []
	for node: Node3D in _landmarks.get(id, []):
		if node is MeshInstance3D:
			points.append_array(_box_points((node as MeshInstance3D).get_aabb(), node.global_transform))
		elif node is Sprite3D:
			points.append_array(_sprite_points(node as Sprite3D, camera))
	return points


func world_corners(camera: Camera3D) -> Array[Vector3]:
	if not _actual_camera(camera): return [Vector3.INF]
	var points: Array[Vector3] = []
	for id: String in LANDMARKS: points.append_array(landmark_world_corners(id, camera))
	# Whole-level scenery may crop. This catalogue of actual complete art bounds
	# is not a required local source/footprint/safe-landing framing certificate.
	return points


func _actual_camera(camera: Camera3D) -> bool:
	return is_instance_valid(camera) and is_inside_tree() and camera.is_inside_tree() and not camera.is_queued_for_deletion() and camera.get_world_3d() == get_world_3d() and camera.get_viewport() == get_viewport() and get_viewport().get_camera_3d() == camera and camera.global_basis.is_finite()


func _build_floor() -> void:
	_floor_overlay = MeshInstance3D.new()
	_floor_overlay.name = "QuietSilverFloorOverlay"
	_floor_overlay.position = Vector3(Layout.FLOOR_CENTRE.x, 0.002, Layout.FLOOR_CENTRE.z)
	var plane := PlaneMesh.new()
	plane.size = Vector2(Layout.FLOOR_SIZE.x, Layout.FLOOR_SIZE.z)
	_floor_overlay.mesh = plane
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.WHITE
	material.albedo_texture = SILVER_TILE
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.texture_repeat = true
	material.uv1_scale = Vector3(plane.size.x / FLOOR_TILE_WORLD_SIZE, plane.size.y / FLOOR_TILE_WORLD_SIZE, 1)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.5
	material.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_OFF
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = false
	material.render_priority = 0
	_floor_overlay.material_override = material
	_floor_overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_floor_overlay.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(_floor_overlay)
	_meshes.append(_floor_overlay)
	_landmarks["floor"] = [_floor_overlay]


func _build_wrinkles() -> void:
	_landmarks["return-creases"] = []
	_landmarks["cheek-creases"] = []
	# Open painted folds, not circular impact warnings or an interaction border.
	# Uneven outer curves suggest facial wrinkles as the familiar floor returns.
	_crease("WestReturnFold", "return-creases", [Vector2(-4.9,7.0),Vector2(-4.4,5.1),Vector2(-3.5,4.2),Vector2(-3.4,2.8),Vector2(-4.0,1.5),Vector2(-4.6,-0.1)], 0.22)
	_crease("EastReturnFold", "return-creases", [Vector2(4.8,5.5),Vector2(4.2,3.6),Vector2(3.9,2.2),Vector2(4.4,0.4),Vector2(4.6,-1.1)], 0.18)
	_crease("FarReturnFold", "return-creases", [Vector2(-2.2,8.4),Vector2(-0.8,8.7),Vector2(1.4,8.5),Vector2(2.7,7.8)], 0.13)
	_crease("WestCheekFold", "cheek-creases", [Vector2(-5.6,-3.1),Vector2(-5.1,-4.6),Vector2(-4.8,-5.6),Vector2(-5.4,-6.8),Vector2(-5.9,-8.4)], 0.27)
	_crease("EastCheekFold", "cheek-creases", [Vector2(5.5,-7.2),Vector2(5.9,-9.2),Vector2(5.1,-11.6),Vector2(5.6,-13.5)], 0.22)
	_crease("OuterHatchFold", "cheek-creases", [Vector2(-5.9,-9.4),Vector2(-6.3,-11.6),Vector2(-6.2,-13.4)], 0.17)


func _crease(label: String, family: String, points: Array, width: float) -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	for index: int in range(points.size()-1):
		var a: Vector2 = points[index]
		var b: Vector2 = points[index+1]
		var side: Vector2 = Vector2(-(b-a).y,(b-a).x).normalized()
		var broad: float = width * (1.0 if index % 2 == 0 else 0.7)
		_ground_poly(vertices,colors,[a-side*broad,b-side*broad*0.65,b+side*broad*0.65,a+side*broad],0.35,0.004)
		_ground_poly(vertices,colors,[a+side*broad*0.5,b+side*broad*0.35,b+side*broad*0.60,a+side*broad*0.8],0.52,0.006)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var geometry := ArrayMesh.new()
	geometry.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color.WHITE
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = false
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = geometry
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(mesh)
	_meshes.append(mesh)
	(_landmarks[family] as Array).append(mesh)


func _build_flats() -> void:
	_landmarks["side-flats"] = []
	# Existing low flats keep their 0.024 step; clear continuous floor stays real.
	# All flats are passable painted scenery, never a hidden physical wall.
	for side: float in [-1.0,1.0]:
		for index: int in range(4):
			var positions: Array[Vector3] = [Vector3(7.0,0.005,7.1),Vector3(6.95,0.005,0.4),Vector3(7.05,0.005,-6.4),Vector3(7.10,0.005,-12.2)]
			var origin: Vector3 = positions[index]
			origin.x *= side
			var texture: Texture2D = ROCK_A if index % 2 == 0 else ROCK_B
			var flat := _sprite("%sPaintedEdge%d" % ["West" if side < 0 else "East",index],texture,origin,0.024,"side-flats")
			flat.flip_h = side > 0
	# Distant taller-looking flats behind the face are the same native kit,
	# arranged on the far stage edge. They do not add a second walkable platform.
	_sprite("FarWestRockFlat",ROCK_B,Vector3(-5.2,0.005,-16.4),0.029,"side-flats")
	var far_east := _sprite("FarEastRockFlat",ROCK_A,Vector3(5.8,0.005,-16.9),0.028,"side-flats")
	far_east.flip_h = true


func _build_distant_cast() -> void:
	_landmarks["distant-cast"] = []
	# Quiet human celestial performers remain background costume/prop scenery.
	var crescent := _sprite("DistantCrescentPerformer",CRESCENT,Vector3(-7.4,2.5,-15.6),0.024,"distant-cast")
	crescent.set_meta("nonhostile_scenery",true)
	var star := _sprite("DistantHumanStarPerformer",HUMAN_STAR,Vector3(7.2,3.0,-16.1),0.020,"distant-cast")
	star.offset = Vector2.ZERO
	star.set_meta("nonhostile_scenery",true)


func _sprite(label: String, texture: Texture2D, origin: Vector3, pixel_size: float, family: String) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.name = label
	sprite.texture = texture
	sprite.position = origin
	sprite.pixel_size = pixel_size
	sprite.centered = true
	sprite.offset = Vector2(0,texture.get_height()*0.5)
	sprite.axis = Vector3.AXIS_Z
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = false
	sprite.double_sided = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.5
	sprite.no_depth_test = false
	sprite.fixed_size = false
	sprite.render_priority = 0
	sprite.sorting_offset = 0.0
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.modulate = Color.WHITE
	sprite.transparency = 0.0
	sprite.layers = 1
	sprite.region_enabled = false
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	sprite.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(sprite)
	_sprites.append(sprite)
	(_landmarks[family] as Array).append(sprite)
	return sprite


static func _ground_poly(vertices: PackedVector3Array, colors: PackedColorArray, points: Array, value: float, height: float) -> void:
	var polygon := PackedVector2Array()
	for point: Vector2 in points:
		# Discrete material edges are authored; physics and inputs remain continuous.
		polygon.append(Vector2(snappedf(point.x,0.024),snappedf(point.y,0.024)))
	for index: int in Geometry2D.triangulate_polygon(polygon):
		vertices.append(Vector3(polygon[index].x,height,polygon[index].y))
		colors.append(Color(value,value,value,1.0))


static func _sprite_points(sprite: Sprite3D, camera: Camera3D) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var size: Vector2 = Vector2(sprite.texture.get_size()) * sprite.pixel_size
	var native_scale: Vector3 = sprite.global_basis.get_scale()
	var centre: Vector3 = sprite.global_position + camera.global_basis.x * sprite.offset.x * sprite.pixel_size * native_scale.x + camera.global_basis.y * sprite.offset.y * sprite.pixel_size * native_scale.y
	for x: float in [-0.5,0.5]:
		for y: float in [-0.5,0.5]:
			for depth: float in [-0.001,0.001]:
				points.append(centre + camera.global_basis.x * size.x * native_scale.x * x + camera.global_basis.y * size.y * native_scale.y * y + camera.global_basis.z * depth)
	return points


static func _box_points(bounds: AABB, frame: Transform3D) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for x: float in [bounds.position.x,bounds.end.x]:
		for y: float in [bounds.position.y,bounds.end.y]:
			for z: float in [bounds.position.z,bounds.end.z]:
				points.append(frame * Vector3(x,y,z))
	return points
