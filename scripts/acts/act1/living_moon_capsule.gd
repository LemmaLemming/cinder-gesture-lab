class_name Act1LivingMoonCapsule
extends Node3D
## L1 shell presentation extracted for L5; no workshop or gameplay actor.
## Parent owns real contact, cues, shared-clock time and the final transition.

const METAL_TEXTURE = preload("res://assets/acts/act1/launch/riveted_plate.png")
const SELENITE_TEXTURE = preload("res://assets/acts/act1/lunar/rusher_front_standing.png")
const HATCH_CONTACT_ANCHOR := Vector3(0.0, 0.0, 1.8)
const PIXEL_STEP: float = 0.022
const CLINGER_RESERVE := AABB(Vector3(-0.528, 0.0, -0.022), Vector3(1.056, 1.760, 0.044))
const INK: Color = Color("141414")
const COAL: Color = Color("272727")
const SHADE: Color = Color("434343")
const SILVER: Color = Color("939393")
const LIGHT: Color = Color("c1c1c1")
const WHITE: Color = Color("e7e7e7")

var _flight: Node3D
var _hinge: Node3D
var _clinger: Node3D
var _cord: MeshInstance3D
var _camera: Camera3D
var _hatch_open: bool = false
var _escape_progress: float = 0.0
var _materials: Dictionary = {}
var _meshes: Array[MeshInstance3D] = []


func _init() -> void:
	name = "LivingMoonCapsuleScenery"
	process_mode = Node.PROCESS_MODE_DISABLED
	set_meta("nonhostile_scenery", true)
	_flight = _group(self, "CosmeticShellCarrier", Vector3.ZERO)
	_build_shell()
	# Ground cradles stay on the floor when the cosmetic shell leaves them.
	for z: float in [-0.8, 0.9]:
		_box(self, "CapsuleCradle", Vector3(0, 0.14, z), Vector3(1.75, 0.28, 0.44), SHADE)
		_box(self, "CradleTop", Vector3(0, 0.30, z), Vector3(1.58, 0.05, 0.40), SILVER)
	_clinger = _group(_flight, "NonhostileClingingSelenite", Vector3(-0.90, -0.12, 1.0))
	_clinger.set_meta("nonhostile_scenery", true)
	_clinger.set_meta("reuse_family", "act1_selenite_C30_rusher_cosmetic_pose")
	_build_clinger()
	_clinger.visible = false
	_cord = _box(self, "ScenicEscapeCord", Vector3.ZERO, Vector3(0.04, 1.0, 0.04), LIGHT)
	_cord.visible = false
	set_hatch_open(false)


func set_hatch_open(open: bool) -> void:
	_hatch_open = open
	_hinge.rotation.y = deg_to_rad(-108.0) if open else 0.0


func set_presentation_camera(camera: Camera3D) -> bool:
	if not _actual_camera(camera): return false
	_camera = camera
	_align_clinger()
	return true


func set_escape_progress(alpha: float) -> bool:
	# Alpha comes from the parent's existing shared-clock vignette. There is
	# no processing loop, duration, contact latch or private animation clock.
	if not is_finite(alpha) or alpha < 0.0 or alpha > 1.0: return false
	if alpha > 0.0 and not _actual_camera(_camera): return false
	if _camera != null and not _actual_camera(_camera): return false
	_escape_progress = alpha
	_flight.position = Vector3(-0.32, 0.85, -0.65) * alpha
	_flight.rotation = Vector3(-0.22, 0.0, 0.04) * alpha
	_clinger.visible = alpha > 0.0
	_cord.visible = alpha > 0.0
	var from: Vector3 = _flight.transform * Vector3(0.15, 0.50, 1.08)
	var to := Vector3(0.15, 0.04, 2.30)
	var delta: Vector3 = to - from
	_cord.position = (from + to) * 0.5
	_cord.scale = Vector3(1.0, delta.length(), 1.0)
	_cord.quaternion = Quaternion(Vector3.UP, delta.normalized())
	if _camera != null: _align_clinger()
	return true


func presentation_state() -> Dictionary:
	return {"hatch_open":_hatch_open, "escape_progress":_escape_progress, "clinger_visible":_clinger.visible, "cord_visible":_cord.visible}


func world_corners() -> Array[Vector3]:
	if not is_inside_tree(): return [Vector3.INF]
	var points: Array[Vector3] = []
	for mesh: MeshInstance3D in _meshes:
		if mesh.is_visible_in_tree(): points.append_array(_box_points(mesh.get_aabb(), mesh.global_transform))
	if _clinger.is_visible_in_tree(): points.append_array(_box_points(CLINGER_RESERVE, _clinger.global_transform))
	return points


func _actual_camera(camera: Camera3D) -> bool:
	return is_instance_valid(camera) and is_inside_tree() and camera.is_inside_tree() and not camera.is_queued_for_deletion() and camera.get_world_3d() == get_world_3d() and camera.get_viewport() == get_viewport() and get_viewport().get_camera_3d() == camera and camera.global_basis.is_finite()


func _align_clinger() -> void:
	# Only its renderer carrier faces the camera, never a source/body/camera.
	_clinger.basis = _flight.global_basis.inverse() * _camera.global_basis


func _build_shell() -> void:
	# Exact existing L1 shell at native scale1: long axis Z, rear hatch +Z.
	var body := _cylinder(_flight, "RivetedCylindricalBody", Vector3(0, 1.02, -0.12), 0.84, 0.84, 2.65, SILVER)
	body.rotation.x = PI * 0.5
	(body.mesh as CylinderMesh).cap_top = false
	(body.mesh as CylinderMesh).cap_bottom = false
	var painted := StandardMaterial3D.new()
	painted.albedo_texture = METAL_TEXTURE
	painted.roughness = 0.82
	painted.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	body.material_override = painted
	for section: Vector4 in [Vector4(-1.55, 0.84, 0.66, 0.42), Vector4(-1.91, 0.66, 0.34, 0.34), Vector4(-2.16, 0.34, 0.07, 0.18)]:
		var nose := _cylinder(_flight, "RoundedBulletNose", Vector3(0, 1.02, section.x), section.z, section.y, section.w, LIGHT)
		nose.rotation.x = -PI * 0.5
	for z: float in [-1.21, -0.17, 1.19]:
		_ring(_flight, "RivetedBodyBand", Vector3(0, 1.02, z), 0.84, 0.04, SHADE, Vector3(PI * 0.5, 0, 0))
		for i: int in range(12):
			var angle: float = TAU * i / 12.0
			_sphere(_flight, "BodyRivet", Vector3(cos(angle) * 0.86, 1.02 + sin(angle) * 0.86, z), 0.025, LIGHT)
	var dark_entry := _cylinder(_flight, "DarkRearOpening", Vector3(0, 1.02, 1.37), 0.74, 0.74, 0.035, INK)
	dark_entry.rotation.x = PI * 0.5
	_ring(_flight, "CircularHatchRim", Vector3(0, 1.02, 1.4), 0.75, 0.095, LIGHT, Vector3(PI * 0.5, 0, 0))
	_box(_flight, "BroadHatchSill", Vector3(0, 0.13, 1.58), Vector3(1.65, 0.15, 0.46), SHADE)
	_hinge = _group(_flight, "HatchHinge", Vector3(0.79, 1.02, 1.45))
	var door := _cylinder(_hinge, "RoundHatchDoor", Vector3(-0.79, 0, 0.025), 0.72, 0.72, 0.07, SILVER)
	door.rotation.x = PI * 0.5
	_ring(_hinge, "DoorInset", Vector3(-0.79, 0, 0.072), 0.35, 0.04, LIGHT, Vector3(PI * 0.5, 0, 0))
	var porthole := _cylinder(_hinge, "DoorPorthole", Vector3(-0.79, 0, 0.075), 0.31, 0.31, 0.013, COAL)
	porthole.rotation.x = PI * 0.5
	for i: int in range(10):
		var angle: float = TAU * i / 10.0
		_sphere(_hinge, "HatchRivet", Vector3(-0.79 + cos(angle) * 0.61, sin(angle) * 0.61, 0.084), 0.025, LIGHT)
	for y: float in [-0.37, 0.37]:
		_box(_flight, "DoorHingePlate", Vector3(0.79, 1.02 + y, 1.45), Vector3(0.15, 0.14, 0.15), SHADE)


func _build_clinger() -> void:
	# Existing masked headpiece/rib torso/boots, kept as unchanged texture regions.
	# Fresh raised arms adapt the old costume, not its gameplay attack or actor.
	_sprite_region("ExistingMaskedHead", Rect2(0, 0, 48, 35), Vector2(0, 62.5))
	_sprite_region("ExistingRibTorso", Rect2(15, 35, 19, 29), Vector2(0.5, 30.5))
	_sprite_region("ExistingBootedLegs", Rect2(0, 64, 48, 16), Vector2(0, 8))
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	_arm(vertices, colors, Vector2(-8,39), Vector2(-10,53), Vector2(5,65))
	_arm(vertices, colors, Vector2(9,39), Vector2(20,50), Vector2(20,65))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var arms := ArrayMesh.new()
	arms.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var node := _mesh(_clinger, "CosmeticRaisedGripArms", Vector3.ZERO, arms, WHITE)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	node.material_override = material


func _sprite_region(label: String, region: Rect2, offset: Vector2) -> void:
	var sprite := Sprite3D.new()
	sprite.name = label
	sprite.texture = SELENITE_TEXTURE
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = true
	sprite.offset = offset
	sprite.pixel_size = PIXEL_STEP
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = false
	sprite.double_sided = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.5
	sprite.no_depth_test = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.process_mode = Node.PROCESS_MODE_DISABLED
	_clinger.add_child(sprite)


static func _arm(v: PackedVector3Array, c: PackedColorArray, shoulder: Vector2, elbow: Vector2, hand: Vector2) -> void:
	for pair: Array in [[shoulder,elbow],[elbow,hand]]:
		var a: Vector2 = pair[0]
		var b: Vector2 = pair[1]
		var side: Vector2 = Vector2(-(b-a).y, (b-a).x).normalized()
		_polygon(v,c,[a-side*3,b-side*3,b+side*3,a+side*3],INK,0.004)
		_polygon(v,c,[a-side,b-side,b+side,a+side],SHADE,0.008)
		var middle: Vector2 = a.lerp(b,0.72)
		_polygon(v,c,[middle-side*3,middle-side*3+Vector2(0,2),middle+side*3+Vector2(0,2),middle+side*3],LIGHT,0.012)
	_polygon(v,c,[hand+Vector2(-2,-2),hand+Vector2(2,-2),hand+Vector2(2,3),hand+Vector2(-2,3)],WHITE,0.014)


static func _polygon(v: PackedVector3Array, c: PackedColorArray, points: Array, color: Color, depth: float) -> void:
	var polygon := PackedVector2Array()
	for raw: Vector2 in points: polygon.append(Vector2(roundf(raw.x),roundf(raw.y)))
	for index: int in Geometry2D.triangulate_polygon(polygon):
		v.append(Vector3(polygon[index].x*PIXEL_STEP,polygon[index].y*PIXEL_STEP,depth))
		c.append(color)


func _group(parent: Node3D, label: String, origin: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = label
	node.position = origin
	node.process_mode = Node.PROCESS_MODE_DISABLED
	parent.add_child(node)
	return node


func _material(color: Color) -> StandardMaterial3D:
	var key: String = color.to_html()
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.9
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_materials[key] = material
	return _materials[key] as StandardMaterial3D


func _mesh(parent: Node3D, label: String, origin: Vector3, geometry: Mesh, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = geometry
	node.material_override = _material(color)
	node.position = origin
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.process_mode = Node.PROCESS_MODE_DISABLED
	parent.add_child(node)
	_meshes.append(node)
	return node


func _box(parent: Node3D, label: String, origin: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(parent,label,origin,mesh,color)


func _cylinder(parent: Node3D, label: String, origin: Vector3, top: float, bottom: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 1
	return _mesh(parent,label,origin,mesh,color)


func _ring(parent: Node3D, label: String, origin: Vector3, radius: float, thickness: float, color: Color, orientation: Vector3) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - thickness
	mesh.outer_radius = radius + thickness
	mesh.rings = 16
	mesh.ring_segments = 6
	var node := _mesh(parent,label,origin,mesh,color)
	node.rotation = orientation
	return node


func _sphere(parent: Node3D, label: String, origin: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	return _mesh(parent,label,origin,mesh,color)


static func _box_points(bounds: AABB, frame: Transform3D) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]:
				points.append(frame * Vector3(x,y,z))
	return points
