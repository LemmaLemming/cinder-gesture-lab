class_name Act1LaunchScenery
extends Node3D
## A1-L1 authored scenic kit. No collision, input, damage or progression lives here.
## G16/G14 and F01-F05 inform shapes; generated boards are never runtime atlases.

const ASSET_ROOT: String = "res://assets/acts/act1/launch/"
const INK: Color = Color("141414")
const COAL: Color = Color("272727")
const SHADE: Color = Color("434343")
const SILVER: Color = Color("939393")
const LIGHT: Color = Color("c1c1c1")
const WHITE: Color = Color("e7e7e7")

var _built: bool = false
var _hatch_open: bool = false
var _exit_door: Node3D
var _materials: Dictionary = {}
var _textures: Dictionary = {}


func build(parent: Node3D) -> void:
	if _built or not is_instance_valid(parent):
		return
	name = "LaunchTheatreScenery"
	if get_parent() == null:
		parent.add_child(self)
	_built = true
	_build_hall()
	_build_workshop()
	_build_roof()
	var exit_capsule := _capsule("ExitCapsule", Vector3(0, 0, -16.1), 1.0)
	_exit_door = exit_capsule.get_node("HatchHinge") as Node3D
	set_hatch_open(_hatch_open)


func set_hatch_open(open: bool) -> void:
	# Immediate presentation follows the level's committed state. There is no
	# decorative timer that could delay a contact exit or replay progress.
	_hatch_open = open
	if is_instance_valid(_exit_door):
		_exit_door.rotation.y = deg_to_rad(-108.0) if open else 0.0


func _build_hall() -> void:
	var hall := _group(self, "CeremonialHall", Vector3.ZERO)
	# Columns frame the close portrait instead of occupying ordinary edge-dash landings.
	for side: float in [-1.0, 1.0]:
		for z: float in [12.0, 7.0, 2.9]:
			_column(hall, Vector3(side * 3.8, 0, z))
		for z: float in [12.7, 5.4]:
			var window := _cutout(hall, "DividedArchedWindow", "arched_window.png", Vector3(side * 3.10, 0.1, z), 0.025)
			window.rotation.y = side * deg_to_rad(-65.0)
			var drape := _cutout(hall, "CelestialFabricPanel", "celestial_drape.png", Vector3(side * 3.16, 0.5, z + 0.8), 0.021)
			drape.rotation.y = window.rotation.y
		_bench(hall, Vector3(side * 2.88, 0, 11.6))
	# Science props remain ahead of the tested z7.8 edge landing, above its body.
	_ringed_instrument(hall, Vector3(2.60, 0, 6.2))
	_journey_board(hall, Vector3(-2.60, 0, 6.4))
	_friendly(hall, "CongressAstronomer", "academic.png", Vector3(-2.78, 0.025, 11.3), false)
	_friendly(hall, "SecondAcademic", "academic.png", Vector3(2.78, 0.025, 11.3), true)


func _build_workshop() -> void:
	var workshop := _group(self, "CapsuleWorkshop", Vector3.ZERO)
	for side: float in [-1.0, 1.0]:
		_truss(workshop, Vector3(side * 3.25, 0, 0.0))
		_bench(workshop, Vector3(side * 2.80, 0, -0.75))
	_anvil(workshop, Vector3(-2.60, 0, -1.6))
	var capsule := _capsule("WorkshopCapsule", Vector3(2.75, 0, -1.1), 0.75)
	capsule.rotation.y = deg_to_rad(-8.0)
	var workshop_door := capsule.get_node("HatchHinge") as Node3D
	workshop_door.rotation.y = deg_to_rad(-108.0)
	_friendly(workshop, "WorkshopMetalworker", "metalworker.png", Vector3(-2.78, 0.025, -2.9), false)
	# This observer stays at the entry; its silhouette sits below the staged
	# z1.25 player instead of sharing the capsule or later right-side target.
	_friendly(workshop, "CapsuleMetalworker", "metalworker.png", Vector3(2.88, 0.025, 3.8), true)
	# Ladder is a background prop, with no traversal trigger or collider.
	var ladder := _group(workshop, "BackgroundLadder", Vector3(3.08, 0, -1.9))
	ladder.rotation.z = deg_to_rad(-9.0)
	for x: float in [-0.22, 0.22]:
		_box(ladder, "LadderRail", Vector3(x, 1.35, 0), Vector3(0.065, 2.7, 0.09), SHADE)
	for step: int in range(8):
		_box(ladder, "LadderRung", Vector3(0, 0.2 + step * 0.31, 0), Vector3(0.48, 0.055, 0.09), SILVER)


func _build_roof() -> void:
	var roof := _group(self, "RooftopLaunch", Vector3.ZERO)
	for side: float in [-1.0, 1.0]:
		_gantry(roof, Vector3(side * 4.30, 0, -7.0))
		var skyline := _cutout(roof, "PaintedChimneySkyline", "rooftop_skyline.png", Vector3(side * 5.1, 0.0, -10.0), 0.04)
		skyline.rotation.y = side * deg_to_rad(-62.0)
	_telescope(roof, Vector3(3.95, 0, -5.1))
	_cannon(roof, Vector3(-4.4, 0, -11.5))
	_friendly(roof, "LaunchAttendantLeft", "launch_attendant.png", Vector3(-3.7, 0.025, -9.2), false)
	_friendly(roof, "LaunchAttendantRight", "launch_attendant.png", Vector3(3.9, 0.025, -12.0), true)
	# Far roof silhouettes frame the exit but remain beyond the continuous floor.
	var far_skyline := _cutout(roof, "DistantRoofBackdrop", "rooftop_skyline.png", Vector3(0, 0, -19.25), 0.055)
	far_skyline.modulate = Color(0.65, 0.65, 0.65)


func _column(parent: Node3D, origin: Vector3) -> void:
	var column := _group(parent, "FlutedColumn", origin)
	_box(column, "SteppedPlinth", Vector3(0, 0.10, 0), Vector3(0.84, 0.2, 0.80), SHADE)
	_box(column, "PlinthUpper", Vector3(0, 0.26, 0), Vector3(0.70, 0.12, 0.66), SILVER)
	_cylinder(column, "ColumnShaft", Vector3(0, 1.74, 0), 0.25, 0.28, 2.84, SILVER)
	for i: int in range(10):
		var angle: float = TAU * i / 10.0
		var flute := _box(column, "PaleFlute", Vector3(cos(angle) * 0.263, 1.76, sin(angle) * 0.263), Vector3(0.055, 2.62, 0.055), LIGHT if i % 2 == 0 else SHADE)
		flute.rotation.y = -angle
	for pair: Vector2 in [Vector2(0.33, 0.12), Vector2(0.40, 0.10), Vector2(0.48, 0.13)]:
		_cylinder(column, "CapitalBand", Vector3(0, 3.18 + pair.x * 0.22, 0), pair.x, pair.x, pair.y, LIGHT)
	_box(column, "CapitalAbacus", Vector3(0, 3.47, 0), Vector3(0.9, 0.16, 0.86), SILVER)
	for side: float in [-1.0, 1.0]:
		_ring(column, "CapitalScroll", Vector3(side * 0.34, 3.21, 0.22), 0.11, 0.035, LIGHT, Vector3(PI * 0.5, 0, 0))


func _ringed_instrument(parent: Node3D, origin: Vector3) -> void:
	var instrument := _group(parent, "RingedAstronomicalInstrument", origin)
	_box(instrument, "InstrumentBase", Vector3(0, 0.11, 0), Vector3(1.0, 0.22, 0.82), SHADE)
	_cylinder(instrument, "InstrumentPedestal", Vector3(0, 0.60, 0), 0.16, 0.24, 0.84, SILVER)
	_cylinder(instrument, "PedestalTop", Vector3(0, 1.02, 0), 0.35, 0.35, 0.10, LIGHT)
	_ring(instrument, "EquatorialRing", Vector3(0, 1.86, 0), 0.69, 0.045, LIGHT, Vector3.ZERO)
	_ring(instrument, "MeridianRing", Vector3(0, 1.86, 0), 0.69, 0.045, SILVER, Vector3(PI * 0.5, 0, 0))
	_ring(instrument, "InclinedRing", Vector3(0, 1.86, 0), 0.66, 0.035, WHITE, Vector3(0, 0, PI * 0.5))
	_cylinder(instrument, "AxisRod", Vector3(0, 1.90, 0), 0.035, 0.035, 1.63, SHADE)
	_sphere(instrument, "SmallGlobe", Vector3(0, 1.86, 0), 0.22, SHADE)
	_sphere(instrument, "AxisFinial", Vector3(0, 2.74, 0), 0.06, LIGHT)


func _journey_board(parent: Node3D, origin: Vector3) -> void:
	var board := _group(parent, "AstronomicalJourneyBoard", origin)
	board.rotation.y = deg_to_rad(23.0)
	_box(board, "BoardBacking", Vector3(0, 1.43, 0), Vector3(1.8, 1.08, 0.13), COAL)
	var illustration := _cutout(board, "ChalkJourneyDiagram", "journey_board.png", Vector3(0, 0.91, 0.078), 0.0184)
	illustration.offset = Vector2(0, 28)
	for side: float in [-1.0, 1.0]:
		_box(board, "BoardLeg", Vector3(side * 0.69, 0.46, 0), Vector3(0.08, 0.92, 0.12), SHADE)
		_box(board, "BoardFoot", Vector3(side * 0.69, 0.05, 0), Vector3(0.25, 0.10, 0.36), SHADE)
	_box(board, "ChalkLedge", Vector3(0, 0.87, 0.1), Vector3(1.94, 0.08, 0.2), SILVER)


func _bench(parent: Node3D, origin: Vector3) -> void:
	var bench := _group(parent, "PlankBench", origin)
	_box(bench, "BenchTop", Vector3(0, 0.75, 0), Vector3(0.9, 0.12, 1.68), SILVER)
	for x: float in [-0.28, 0.28]:
		for z: float in [-0.62, 0.62]:
			_box(bench, "BenchLeg", Vector3(x, 0.36, z), Vector3(0.105, 0.72, 0.105), SHADE)
	_box(bench, "BenchStretcher", Vector3(0, 0.29, 0), Vector3(0.14, 0.09, 1.45), COAL)
	for z: float in [-0.50, 0.0, 0.51]:
		_box(bench, "PlankSeam", Vector3(0, 0.817, z), Vector3(0.9, 0.009, 0.014), SHADE)


func _anvil(parent: Node3D, origin: Vector3) -> void:
	var anvil := _group(parent, "AnvilAndPedestal", origin)
	_cylinder(anvil, "ChunkyStump", Vector3(0, 0.37, 0), 0.29, 0.33, 0.74, SHADE)
	for i: int in range(8):
		var angle: float = TAU * i / 8.0
		_box(anvil, "StumpPaintStreak", Vector3(cos(angle) * 0.297, 0.40, sin(angle) * 0.297), Vector3(0.028, 0.55, 0.028), SILVER)
	_box(anvil, "AnvilFoot", Vector3(0, 0.81, 0), Vector3(0.60, 0.14, 0.36), COAL)
	_box(anvil, "AnvilWaist", Vector3(0, 0.94, 0), Vector3(0.30, 0.18, 0.28), SHADE)
	_box(anvil, "AnvilFace", Vector3(0.02, 1.10, 0), Vector3(0.68, 0.13, 0.33), LIGHT)
	var horn := _cylinder(anvil, "AnvilHorn", Vector3(-0.46, 1.08, 0), 0.0, 0.14, 0.43, SILVER)
	horn.rotation.z = PI * 0.5
	_box(anvil, "HammerHandle", Vector3(0.27, 0.52, 0.28), Vector3(0.04, 0.69, 0.04), SILVER)
	_box(anvil, "HammerHead", Vector3(0.27, 0.19, 0.28), Vector3(0.21, 0.10, 0.10), COAL)


func _truss(parent: Node3D, origin: Vector3) -> void:
	var truss := _group(parent, "PaintedWorkshopTruss", origin)
	for z: float in [-1.95, 1.95]:
		_box(truss, "TrussUpright", Vector3(0, 1.75, z), Vector3(0.13, 3.5, 0.13), SHADE)
	_box(truss, "TrussBeam", Vector3(0, 3.43, 0), Vector3(0.20, 0.18, 4.15), SILVER)
	for z: float in [-1.0, 1.0]:
		_beam_between(truss, "CrossBrace", Vector3(0, 0.3, z - 0.86), Vector3(0, 3.25, z + 0.86), 0.065, SHADE)
		_beam_between(truss, "CrossBrace", Vector3(0, 0.3, z + 0.86), Vector3(0, 3.25, z - 0.86), 0.065, SILVER)


func _capsule(node_name: String, origin: Vector3, scale_factor: float) -> Node3D:
	var capsule := _group(self, node_name, origin)
	capsule.scale = Vector3.ONE * scale_factor
	# Long axis is Z. Rear contact hatch faces +Z, nose faces -Z.
	var body := _cylinder(capsule, "RivetedCylindricalBody", Vector3(0, 1.02, -0.12), 0.84, 0.84, 2.65, SILVER)
	body.rotation.x = PI * 0.5
	(body.mesh as CylinderMesh).cap_top = false
	(body.mesh as CylinderMesh).cap_bottom = false
	body.material_override = _painted_metal()
	# Three tapered sections approximate the source's crafted rounded nose.
	for section: Vector4 in [Vector4(-1.55, 0.84, 0.66, 0.42), Vector4(-1.91, 0.66, 0.34, 0.34), Vector4(-2.16, 0.34, 0.07, 0.18)]:
		var nose := _cylinder(capsule, "RoundedBulletNose", Vector3(0, 1.02, section.x), section.z, section.y, section.w, LIGHT)
		nose.rotation.x = -PI * 0.5
	for z: float in [-1.21, -0.17, 1.19]:
		_ring(capsule, "RivetedBodyBand", Vector3(0, 1.02, z), 0.84, 0.04, SHADE, Vector3(PI * 0.5, 0, 0))
		for i: int in range(12):
			var angle: float = TAU * i / 12.0
			_sphere(capsule, "BodyRivet", Vector3(cos(angle) * 0.86, 1.02 + sin(angle) * 0.86, z), 0.025, LIGHT)
	for z: float in [-0.8, 0.9]:
		_box(capsule, "CapsuleCradle", Vector3(0, 0.14, z), Vector3(1.75, 0.28, 0.44), SHADE)
		_box(capsule, "CradleTop", Vector3(0, 0.30, z), Vector3(1.58, 0.05, 0.40), SILVER)
	# O10 is part of O09: one portal plus a hinge-driven door, never a second prop.
	var dark_entry := _cylinder(capsule, "DarkRearOpening", Vector3(0, 1.02, 1.37), 0.74, 0.74, 0.035, INK)
	dark_entry.rotation.x = PI * 0.5
	_ring(capsule, "CircularHatchRim", Vector3(0, 1.02, 1.4), 0.75, 0.095, LIGHT, Vector3(PI * 0.5, 0, 0))
	# The authored contact plane is local Z=1.8, world Z=-14.3 on ExitCapsule.
	_box(capsule, "BroadHatchSill", Vector3(0, 0.13, 1.58), Vector3(1.65, 0.15, 0.46), SHADE)
	var hinge := _group(capsule, "HatchHinge", Vector3(0.79, 1.02, 1.45))
	var door := _cylinder(hinge, "RoundHatchDoor", Vector3(-0.79, 0, 0.025), 0.72, 0.72, 0.07, SILVER)
	door.rotation.x = PI * 0.5
	_ring(hinge, "DoorInset", Vector3(-0.79, 0, 0.072), 0.35, 0.04, LIGHT, Vector3(PI * 0.5, 0, 0))
	var porthole := _cylinder(hinge, "DoorPorthole", Vector3(-0.79, 0, 0.075), 0.31, 0.31, 0.013, COAL)
	porthole.rotation.x = PI * 0.5
	for i: int in range(10):
		var angle: float = TAU * i / 10.0
		_sphere(hinge, "HatchRivet", Vector3(-0.79 + cos(angle) * 0.61, sin(angle) * 0.61, 0.084), 0.025, LIGHT)
	for y: float in [-0.37, 0.37]:
		_box(capsule, "DoorHingePlate", Vector3(0.79, 1.02 + y, 1.45), Vector3(0.15, 0.14, 0.15), SHADE)
	return capsule


func _gantry(parent: Node3D, origin: Vector3) -> void:
	var gantry := _group(parent, "CrossBracedRailing", origin)
	for z: float in [-1.7, 0.0, 1.7]:
		_box(gantry, "RailPost", Vector3(0, 0.55, z), Vector3(0.13, 1.1, 0.13), SILVER)
		_box(gantry, "PostFoot", Vector3(0, 0.06, z), Vector3(0.25, 0.12, 0.25), SHADE)
	for y: float in [0.20, 1.02]:
		_box(gantry, "HorizontalRail", Vector3(0, y, 0), Vector3(0.095, 0.08, 3.6), LIGHT)
	for z: float in [-0.85, 0.85]:
		_beam_between(gantry, "RailCrossBrace", Vector3(0, 0.24, z - 0.78), Vector3(0, 0.98, z + 0.78), 0.06, SHADE)
		_beam_between(gantry, "RailCrossBrace", Vector3(0, 0.24, z + 0.78), Vector3(0, 0.98, z - 0.78), 0.06, SILVER)


func _telescope(parent: Node3D, origin: Vector3) -> void:
	var telescope := _group(parent, "RooftopTelescope", origin)
	for i: int in range(3):
		var angle: float = TAU * i / 3.0
		_beam_between(telescope, "TripodLeg", Vector3(cos(angle) * 0.46, 0.04, sin(angle) * 0.46), Vector3(0, 1.22, 0), 0.065, SILVER)
	var tube := _cylinder(telescope, "TelescopeTube", Vector3(0, 1.45, 0), 0.10, 0.19, 1.34, LIGHT)
	tube.rotation.x = deg_to_rad(-67.0)
	for z: float in [-0.48, 0.05, 0.49]:
		_ring(telescope, "TubeBand", Vector3(0, 1.45 - z * 0.42, z), 0.155, 0.027, SHADE, Vector3(deg_to_rad(23.0), 0, 0))
	_cylinder(telescope, "TripodHead", Vector3(0, 1.20, 0), 0.16, 0.16, 0.13, SHADE)


func _cannon(parent: Node3D, origin: Vector3) -> void:
	var cannon := _group(parent, "EnormousLaunchCannon", origin)
	cannon.rotation.y = deg_to_rad(-13.0)
	_box(cannon, "CannonPlinth", Vector3(0, 0.13, 0), Vector3(1.8, 0.26, 3.0), SHADE)
	for x: float in [-0.54, 0.54]:
		_box(cannon, "BarrelSupport", Vector3(x, 0.72, 0.20), Vector3(0.22, 1.15, 1.18), SILVER)
	var barrel_root := _group(cannon, "RaisedBarrel", Vector3(0, 1.58, 0))
	barrel_root.rotation.x = deg_to_rad(-11.0)
	var barrel := _cylinder(barrel_root, "WideRingedBarrel", Vector3(0, 0, -0.22), 0.54, 0.74, 3.42, SILVER)
	barrel.rotation.x = -PI * 0.5
	barrel.material_override = _painted_metal()
	for z: float in [-1.76, -0.92, 0.20, 1.18]:
		_ring(barrel_root, "CannonReinforcement", Vector3(0, 0, z), 0.65 if z < 0 else 0.76, 0.08, LIGHT, Vector3(PI * 0.5, 0, 0))
	var bore := _cylinder(barrel_root, "BlackBarrelMouth", Vector3(0, 0, -1.96), 0.49, 0.49, 0.035, INK)
	bore.rotation.x = PI * 0.5
	_ring(barrel_root, "CannonMuzzle", Vector3(0, 0, -1.98), 0.55, 0.09, SILVER, Vector3(PI * 0.5, 0, 0))


func _friendly(parent: Node3D, node_name: String, filename: String, origin: Vector3, flip: bool) -> void:
	var person := _cutout(parent, node_name, filename, origin, 0.023)
	person.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	person.flip_h = flip
	person.set_meta("nonhostile_scenery", true)
	person.set_meta("readiness", "authored_portrait_unverified")


func _group(parent: Node3D, node_name: String, origin: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = node_name
	node.position = origin
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


func _painted_metal() -> StandardMaterial3D:
	if not _materials.has("painted_metal"):
		var material := StandardMaterial3D.new()
		material.albedo_texture = _texture("riveted_plate.png")
		material.roughness = 0.82
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_materials["painted_metal"] = material
	return _materials["painted_metal"] as StandardMaterial3D


func _texture(filename: String) -> Texture2D:
	if not _textures.has(filename):
		_textures[filename] = load(ASSET_ROOT + filename) as Texture2D
	return _textures[filename] as Texture2D


func _mesh(parent: Node3D, node_name: String, origin: Vector3, geometry: Mesh, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = geometry
	node.material_override = _material(color)
	node.position = origin
	# Small scenic parts are depth-tested and never create a gameplay shape.
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node


func _box(parent: Node3D, node_name: String, origin: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(parent, node_name, origin, mesh, color)


func _cylinder(parent: Node3D, node_name: String, origin: Vector3, top: float, bottom: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 1
	return _mesh(parent, node_name, origin, mesh, color)


func _ring(parent: Node3D, node_name: String, origin: Vector3, radius: float, thickness: float, color: Color, orientation: Vector3) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - thickness
	mesh.outer_radius = radius + thickness
	mesh.rings = 16
	mesh.ring_segments = 6
	var node := _mesh(parent, node_name, origin, mesh, color)
	node.rotation = orientation
	return node


func _sphere(parent: Node3D, node_name: String, origin: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	return _mesh(parent, node_name, origin, mesh, color)


func _beam_between(parent: Node3D, node_name: String, from: Vector3, to: Vector3, thickness: float, color: Color) -> void:
	var vector: Vector3 = to - from
	var beam := _box(parent, node_name, (from + to) * 0.5, Vector3(thickness, vector.length(), thickness), color)
	beam.quaternion = Quaternion(Vector3.UP, vector.normalized())


func _cutout(parent: Node3D, node_name: String, filename: String, feet: Vector3, pixel_size: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.name = node_name
	sprite.texture = _texture(filename)
	sprite.pixel_size = pixel_size
	sprite.offset = Vector2(0, sprite.texture.get_height() * 0.5)
	sprite.position = feet
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.no_depth_test = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(sprite)
	return sprite
