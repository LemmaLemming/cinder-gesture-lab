class_name Act2RayScoutVisual
extends Node3D
## Original Act 2 cosmetic rig. The parent actor supplies every phase clock.
## +Z is the mirror's local forward; the root is the low housing attack point.
## No collision, target groups, warning geometry, damage, timers or processing.

const BODY_CENTER: Vector3 = Vector3(0.0, 0.79, -0.20)
const HIP_HEIGHT: float = 0.74
const MIRROR_RADIUS: float = 0.285
const MIRROR_SECTORS: int = 16
const MIRROR_HINGE_HALF_SPAN: float = 0.31

var _built: bool = false
var _last_phase: String = ""
var _body_yaw: float = 0.0
var _direction: Vector3 = Vector3.BACK
var _requested_phase: String = "idle"
var _requested_progress: float = 0.0
var _requested_flash: bool = false
var _chassis: Node3D
var _case: Node3D
var _mirror_swivel: Node3D
var _mirror_hinge: Node3D
var _left_door: Node3D
var _right_door: Node3D
var _release_shutter: MeshInstance3D
var _aperture_cover: MeshInstance3D
var _mirror_links: Array[MeshInstance3D] = []
var _legs: Array[Dictionary] = []
var _materials: Array[StandardMaterial3D] = []
var _plate: StandardMaterial3D
var _black: StandardMaterial3D
var _rust: StandardMaterial3D
var _brass: StandardMaterial3D
var _rubber: StandardMaterial3D
var _pale: StandardMaterial3D
var _actuator: MeshInstance3D
var _actuator_ribs: Array[MeshInstance3D] = []


func _ready() -> void:
	if not _built:
		_build()
	pose(_requested_phase, _requested_progress, _direction, _requested_flash)


func pose(phase: String, progress: float, direction: Vector3, hit_flash: bool = false) -> void:
	_requested_phase = phase
	_requested_progress = clampf(progress, 0.0, 1.0) if is_finite(progress) else 0.0
	_requested_flash = hit_flash
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if flat.is_finite() and flat.length_squared() > 0.000001:
		_direction = flat.normalized()
	if not _built:
		return
	var local_direction: Vector3 = _direction
	local_direction = global_basis.inverse() * _direction
	local_direction.y = 0.0
	var target_yaw: float = atan2(local_direction.x, local_direction.z)
	# Plant the support orientation at warning entry. The mirror alone follows
	# subsequent warning calls; the parent's locked direction holds it still.
	if phase != _last_phase and (phase == "warning" or _last_phase.is_empty()):
		_body_yaw = target_yaw
	if phase == "idle" or phase == "approach":
		_body_yaw = target_yaw
	_last_phase = phase
	_chassis.rotation.y = _body_yaw
	_mirror_swivel.rotation.y = wrapf(target_yaw - _body_yaw, -PI, PI)
	var p: float = _requested_progress
	var fold: float = 0.0
	var collapse: float = 0.0
	var plant: float = 0.0
	var case_tilt: float = 0.0
	var mirror_tilt: float = -0.62
	match phase:
		"warning":
			plant = 0.45 + p * 0.45
			mirror_tilt = lerpf(-0.40, -0.24, p)
		"lock":
			plant = 1.0
			mirror_tilt = 0.0
		"active":
			plant = 1.0
			mirror_tilt = -0.045
			case_tilt = 0.025
		"recovery":
			plant = 1.0
			fold = 1.0
			mirror_tilt = -1.27
			case_tilt = -0.025 * (1.0 - p)
		"defeated":
			collapse = 0.85 + 0.15 * p
			fold = 0.70
			mirror_tilt = -1.08
			case_tilt = 0.20
	_case.position = BODY_CENTER - Vector3.UP * 0.31 * collapse
	_case.rotation = Vector3(case_tilt, 0.0, 0.12 * collapse)
	var mirror_forward: float = 0.30 if fold > 0.0 else 0.54
	_mirror_swivel.position = Vector3(0.0, 0.65 - 0.10 * collapse, mirror_forward)
	_mirror_hinge.rotation.x = mirror_tilt
	_left_door.rotation.y = -1.18 * fold
	_right_door.rotation.y = 1.18 * fold
	_release_shutter.visible = phase == "active"
	# A physical camera shutter covers the idle aperture; warning exposes the
	# pale mirror immediately. This is body articulation, not a shared cue.
	_aperture_cover.visible = phase == "idle" or phase == "approach"
	for index: int in range(_mirror_links.size()):
		var side: float = -1.0 if index == 0 else 1.0
		var link_start: Vector3 = Vector3(side * 0.37, 0.59 - collapse * 0.31, 0.13)
		var link_end: Vector3 = _mirror_swivel.position + _mirror_swivel.basis * Vector3(side * MIRROR_HINGE_HALF_SPAN, 0.0, -0.015)
		_fit_segment(_mirror_links[index], link_start, link_end)
	for leg: Dictionary in _legs:
		_pose_leg(leg, plant, collapse)
	var actuator_start: Vector3 = Vector3(0.0, 0.32, -0.16)
	var actuator_end: Vector3 = Vector3(0.12, 0.67 - collapse * 0.26, -0.30)
	_fit_segment(_actuator, actuator_start, actuator_end)
	for index: int in range(_actuator_ribs.size()):
		var rib: MeshInstance3D = _actuator_ribs[index]
		rib.position = actuator_start.lerp(actuator_end, (float(index) + 0.5) / _actuator_ribs.size())
		rib.basis = _actuator.basis
	for material: StandardMaterial3D in _materials:
		material.emission_enabled = hit_flash
		material.emission = Color(0.62, 0.52, 0.39) if hit_flash else Color.BLACK


func _build() -> void:
	_plate = _textured_material(Color(0.25, 0.23, 0.20), Color(0.38, 0.20, 0.12), 32, false)
	_rust = _textured_material(Color(0.28, 0.14, 0.09), Color(0.42, 0.23, 0.13), 32, false)
	_black = _material(Color(0.075, 0.071, 0.067))
	_brass = _material(Color(0.48, 0.38, 0.23))
	_rubber = _textured_material(Color(0.10, 0.10, 0.092), Color(0.17, 0.16, 0.14), 16, true)
	_pale = _material(Color(0.66, 0.63, 0.53))
	_chassis = _pivot(self, "ThreeLegChassis", Vector3.ZERO)
	_case = _pivot(_chassis, "RivetedCameraCase", BODY_CENTER)
	_box(_case, "CameraCase", Vector3(1.01, 0.45, 0.59), Vector3.ZERO, _plate)
	_box(_case, "Undercase", Vector3(0.77, 0.13, 0.48), Vector3(0.0, -0.26, -0.015), _black)
	_box(_case, "FrontBracket", Vector3(0.82, 0.035, 0.06), Vector3(0.0, -0.20, 0.33), _brass)
	for sign_value: float in [-1.0, 1.0]:
		_box(_case, "SideArmour", Vector3(0.04, 0.32, 0.42), Vector3(sign_value * 0.525, 0.0, -0.025), _rust)
		_box(_case, "CornerBracket", Vector3(0.055, 0.44, 0.065), Vector3(sign_value * 0.455, 0.0, 0.31), _black)
		for row: int in range(3):
			_box(_case, "CornerRivet", Vector3(0.043, 0.043, 0.030), Vector3(sign_value * 0.455, -0.145 + row * 0.145, 0.348), _brass)
		var cap: MeshInstance3D = _cylinder(_case, "SidePivotCap", 0.10, 0.045, _black)
		cap.position = Vector3(sign_value * 0.57, -0.035, -0.005)
		cap.rotation.z = PI * 0.5
	var roof: MeshInstance3D = _cylinder(_case, "FacetedSurveyHood", 0.39, 0.12, _plate, 0.205, 12)
	roof.position.y = 0.275
	var roof_cap: MeshInstance3D = _cylinder(_case, "HoodRim", 0.22, 0.035, _black, 0.22, 12)
	roof_cap.position.y = 0.352
	var mast: MeshInstance3D = _cylinder(_case, "ShortSurveyMast", 0.026, 0.18, _black, 0.020, 6)
	mast.position.y = 0.47
	_box(_case, "MastCap", Vector3(0.05, 0.035, 0.05), Vector3(0.0, 0.575, 0.0), _brass)
	for index: int in range(5):
		_box(_case, "RearCoolingRib", Vector3(0.045, 0.26, 0.08), Vector3(-0.24 + index * 0.12, -0.015, -0.33), _black)
	_build_housing()
	_build_mirror()
	_legs.append(_build_leg("LeftSupport", -1.0, false))
	_legs.append(_build_leg("RightSupport", 1.0, false))
	_legs.append(_build_leg("RearSupport", 0.0, true))
	_actuator = _cylinder(_chassis, "FlexibleHousingActuator", 0.067, 0.30, _rubber, 0.067, 8)
	for index: int in range(6):
		var rib: MeshInstance3D = _cylinder(_chassis, "ActuatorRib", 0.086, 0.025, _black, 0.086, 8)
		_actuator_ribs.append(rib)
	_built = true


func _build_housing() -> void:
	var housing: Node3D = _pivot(_chassis, "FixedLowMirrorHousing", Vector3(0.0, 0.30, 0.0))
	_box(housing, "HousingBlock", Vector3(0.66, 0.32, 0.42), Vector3.ZERO, _black)
	_box(housing, "HousingTopPlate", Vector3(0.70, 0.045, 0.43), Vector3(0.0, 0.18, 0.0), _rust)
	_box(housing, "LowCouplerInterior", Vector3(0.42, 0.18, 0.035), Vector3(0.0, 0.0, 0.226), _pale)
	for index: int in range(4):
		_box(housing, "CouplerInteriorRib", Vector3(0.037, 0.15, 0.055), Vector3(-0.135 + index * 0.09, 0.0, 0.255), _black)
	_left_door = _pivot(housing, "LeftHousingDoor", Vector3(-0.30, 0.0, 0.21))
	_right_door = _pivot(housing, "RightHousingDoor", Vector3(0.30, 0.0, 0.21))
	_box(_left_door, "LeftDoorPlate", Vector3(0.30, 0.25, 0.040), Vector3(0.15, 0.0, 0.015), _rust)
	_box(_right_door, "RightDoorPlate", Vector3(0.30, 0.25, 0.040), Vector3(-0.15, 0.0, 0.015), _rust)
	_box(_left_door, "LeftDoorRivet", Vector3(0.045, 0.045, 0.035), Vector3(0.06, 0.075, 0.045), _brass)
	_box(_right_door, "RightDoorRivet", Vector3(0.045, 0.045, 0.035), Vector3(-0.06, 0.075, 0.045), _brass)


func _build_mirror() -> void:
	_mirror_swivel = _pivot(_chassis, "TrackingMirrorSwivel", Vector3(0.0, 0.65, 0.54))
	_mirror_hinge = _pivot(_mirror_swivel, "FoldingMirrorHinge", Vector3.ZERO)
	var dish: Node3D = _pivot(_mirror_hinge, "SegmentedParabolicMirror", Vector3(0.0, 0.285, 0.0))
	var palette: Array[StandardMaterial3D] = [
		_material(Color(0.56, 0.55, 0.49)), _material(Color(0.73, 0.71, 0.61)),
		_material(Color(0.85, 0.83, 0.72)), _material(Color(0.64, 0.66, 0.62))
	]
	for material: StandardMaterial3D in palette:
		material.roughness = 0.28
		material.metallic = 0.35
	var batches: Array = [[], [], [], []]
	for sector: int in range(MIRROR_SECTORS):
		var a: float = TAU * float(sector) / MIRROR_SECTORS
		var b: float = TAU * float(sector + 1) / MIRROR_SECTORS
		var shade: int = 2 if sector >= 2 and sector <= 6 else (sector % 4)
		for ring_index: int in range(3):
			var inner: float = MIRROR_RADIUS * float(ring_index) / 3.0
			var outer: float = MIRROR_RADIUS * float(ring_index + 1) / 3.0
			var v0: Vector3 = _dish_point(a, inner)
			var v1: Vector3 = _dish_point(a, outer)
			var v2: Vector3 = _dish_point(b, outer)
			var v3: Vector3 = _dish_point(b, inner)
			(batches[shade] as Array).append_array([v0, v1, v2])
			if ring_index > 0:
				(batches[shade] as Array).append_array([v0, v2, v3])
	var mesh: ArrayMesh = ArrayMesh.new()
	for shade: int in range(batches.size()):
		var vertices: Array = batches[shade]
		if vertices.is_empty():
			continue
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
		var normals: PackedVector3Array = PackedVector3Array()
		for _vertex: Variant in vertices:
			normals.append(Vector3.BACK)
		arrays[Mesh.ARRAY_NORMAL] = normals
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, palette[shade])
	_part(dish, "PolishedMirrorFacets", mesh, null, Vector3.ZERO)
	for sector: int in range(MIRROR_SECTORS):
		var a: float = TAU * float(sector) / MIRROR_SECTORS
		var b: float = TAU * float(sector + 1) / MIRROR_SECTORS
		var rim: MeshInstance3D = _cylinder(dish, "MirrorRetainingRim", 0.014, 0.10, _black, 0.014, 6)
		_fit_segment(rim, _dish_point(a, MIRROR_RADIUS), _dish_point(b, MIRROR_RADIUS))
	for index: int in range(4):
		var angle: float = TAU * float(index) / 4.0
		_box(dish, "MirrorRetainingClip", Vector3(0.064, 0.055, 0.055), _dish_point(angle, MIRROR_RADIUS), _brass)
	_box(dish, "MirrorHub", Vector3(0.060, 0.060, 0.060), Vector3(0.0, 0.0, -0.014), _black)
	_release_shutter = _box(dish, "PhysicalReleaseShutter", Vector3(0.041, 0.041, 0.025), Vector3(0.0, 0.0, 0.023), _pale)
	_release_shutter.visible = false
	_aperture_cover = _cylinder(dish, "PhysicalIdleApertureCover", 0.235, 0.025, _black, 0.235, 12)
	_aperture_cover.position.z = 0.035
	_aperture_cover.rotation.x = PI * 0.5
	for x_sign: float in [-1.0, 1.0]:
		for z_sign: float in [-1.0, 1.0]:
			_box(_aperture_cover, "ApertureCoverRivet", Vector3(0.028, 0.012, 0.028), Vector3(x_sign * 0.105, 0.021, z_sign * 0.105), _brass)
	for sign_value: float in [-1.0, 1.0]:
		_box(_mirror_hinge, "MirrorFork", Vector3(0.040, 0.32, 0.075), Vector3(sign_value * MIRROR_HINGE_HALF_SPAN, 0.12, -0.015), _plate)
		var hinge_pin: MeshInstance3D = _cylinder(_mirror_hinge, "MirrorHingePin", 0.075, 0.085, _brass)
		hinge_pin.position = Vector3(sign_value * MIRROR_HINGE_HALF_SPAN, 0.0, -0.015)
		hinge_pin.rotation.z = PI * 0.5
		_mirror_links.append(_cylinder(_chassis, "MirrorSaddleLink", 0.030, 0.4, _plate, 0.030, 8))


func _build_leg(node_name: String, side: float, rear: bool) -> Dictionary:
	var rig: Node3D = _pivot(_chassis, node_name, Vector3.ZERO)
	var upper: MeshInstance3D = _cylinder(rig, "UpperSupport", 0.065, 0.40, _plate, 0.065, 8)
	var lower: MeshInstance3D = _cylinder(rig, "LowerSupport", 0.047, 0.43, _black, 0.047, 8)
	var piston: MeshInstance3D = _cylinder(rig, "PistonSleeve", 0.028, 0.28, _rust, 0.028, 6)
	var rod: MeshInstance3D = _cylinder(rig, "PistonRod", 0.016, 0.28, _pale, 0.016, 6)
	var knee: MeshInstance3D = _box(rig, "KneeHinge", Vector3(0.15, 0.13, 0.16), Vector3.ZERO, _rust)
	var knee_pin: MeshInstance3D = _cylinder(rig, "KneePin", 0.045, 0.19, _brass, 0.045, 6)
	knee_pin.rotation.z = PI * 0.5
	var foot: Vector3 = Vector3(0.0, 0.045, -0.85) if rear else Vector3(side * 0.82, 0.045, 0.42)
	_box(rig, "GroundedFoot", Vector3(0.16, 0.09, 0.27), foot, _black)
	_box(rig, "FootToePlate", Vector3(0.14, 0.025, 0.13), foot + Vector3(0.0, 0.055, 0.06), _rust)
	var result: Dictionary = {"side": side, "rear": rear, "foot": foot, "upper": upper, "lower": lower, "piston": piston, "rod": rod, "knee": knee, "pin": knee_pin}
	return result


func _pose_leg(leg: Dictionary, plant: float, collapse: float) -> void:
	var side: float = float(leg["side"])
	var rear: bool = bool(leg["rear"])
	var hip: Vector3 = Vector3(0.0, HIP_HEIGHT, -0.40) if rear else Vector3(side * 0.44, HIP_HEIGHT, -0.16)
	hip.y -= collapse * 0.29
	var knee: Vector3 = Vector3(0.0, 0.38, -0.65) if rear else Vector3(side * (0.67 + collapse * 0.045), 0.40, 0.17)
	knee.y -= plant * 0.025 + collapse * 0.19
	var foot: Vector3 = leg["foot"]
	_fit_segment(leg["upper"] as MeshInstance3D, hip, knee)
	_fit_segment(leg["lower"] as MeshInstance3D, knee, foot)
	(leg["knee"] as Node3D).position = knee
	(leg["pin"] as Node3D).position = knee + Vector3(0.0, 0.0, 0.005)
	var piston_start: Vector3 = hip + Vector3(side * 0.045, -0.05, 0.065)
	var piston_end: Vector3 = knee.lerp(foot, 0.45) + Vector3(side * 0.045, 0.0, 0.065)
	_fit_segment(leg["piston"] as MeshInstance3D, piston_start, piston_start.lerp(piston_end, 0.56))
	_fit_segment(leg["rod"] as MeshInstance3D, piston_start.lerp(piston_end, 0.40), piston_end)


func _dish_point(angle: float, radius: float) -> Vector3:
	var depth: float = -0.050 * (1.0 - pow(radius / MIRROR_RADIUS, 2.0))
	return Vector3(cos(angle) * radius, sin(angle) * radius, depth)


func _fit_segment(node: MeshInstance3D, start: Vector3, finish: Vector3) -> void:
	var along: Vector3 = finish - start
	var length: float = maxf(along.length(), 0.0001)
	var axis: Vector3 = along / length
	var reference: Vector3 = Vector3.RIGHT if absf(axis.x) < 0.90 else Vector3.FORWARD
	var side: Vector3 = axis.cross(reference).normalized()
	var forward: Vector3 = side.cross(axis).normalized()
	node.position = (start + finish) * 0.5
	node.basis = Basis(side, axis, forward)
	(node.mesh as CylinderMesh).height = length


func _pivot(parent: Node3D, node_name: String, at: Vector3) -> Node3D:
	var node: Node3D = Node3D.new()
	node.name = node_name
	node.position = at
	parent.add_child(node)
	return node


func _part(parent: Node3D, node_name: String, mesh: Mesh, material: StandardMaterial3D, at: Vector3) -> MeshInstance3D:
	var part: MeshInstance3D = MeshInstance3D.new()
	part.name = node_name
	part.mesh = mesh
	part.material_override = material
	part.position = at
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)
	return part


func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	return _part(parent, node_name, mesh, material, at)


func _cylinder(parent: Node3D, node_name: String, radius: float, height: float, material: StandardMaterial3D, top_radius: float = -1.0, segments: int = 8) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return _part(parent, node_name, mesh, material, Vector3.ZERO)


func _material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	material.metallic = 0.12
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials.append(material)
	return material


func _textured_material(base: Color, oxidation: Color, pixels: int, rubber: bool) -> StandardMaterial3D:
	var image: Image = Image.create(pixels, pixels, false, Image.FORMAT_RGBA8)
	for y: int in range(pixels):
		for x: int in range(pixels):
			var cluster_x: int = x >> 2
			var cluster_y: int = y >> 2
			var cluster: int = (cluster_x * 11 + cluster_y * 7 + cluster_x * cluster_y * 3) % 17
			var color: Color = base
			if cluster == 2 or cluster == 5:
				color = oxidation
			elif cluster == 9:
				color = base.lightened(0.09)
			if rubber and y % 4 == 0:
				color = base.darkened(0.28)
			elif not rubber and y % 12 == 0 and x > 3 and x < pixels - 4:
				color = base.darkened(0.18)
			image.set_pixel(x, y, color)
	var material: StandardMaterial3D = _material(Color.WHITE)
	material.albedo_texture = ImageTexture.create_from_image(image)
	return material
