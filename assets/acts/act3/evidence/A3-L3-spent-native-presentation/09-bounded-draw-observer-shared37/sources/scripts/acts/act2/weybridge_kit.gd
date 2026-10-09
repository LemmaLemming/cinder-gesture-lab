extends RefCounted
## Weybridge/Shepperton scenery only. The level owns ground, encounters and clocks.
## Reuses the original Horsell mesh/material/witness family without editing it.

const Heath: Script = preload("res://scripts/acts/act2/heath_kit.gd")
const ART_REVISION := "a2-weybridge-kit-1"
const TILE_WORLD_SIZE := 1.44
const COLLAPSE_ANCHOR := Vector3(0.0, -0.12, -41.6)
static var _surface_cache: Dictionary = {}

static func build(parent: Node3D) -> Dictionary:
	assert(parent != null, "Weybridge scenery requires a level-owned parent.")
	var root := Node3D.new()
	root.name = "WeybridgeSceneryKit"
	root.set_meta("art_revision", ART_REVISION)
	root.set_meta("scenery_only", true)
	root.set_meta("optional_cutaway_paths", [])
	parent.add_child(root)
	_ground(root)
	_quay(root)
	for side: int in [-1, 1]:
		for index: int in range(4):
			var z: float = [-4.5, -7.0, -33.7, -37.0][index]
			Heath._cottage(root, Vector3(float(side) * 4.95, 0.0, z), side, index)
	_cart(root, Vector3(-4.85, 0.0, -5.2))
	var field_gun := _field_gun(root, Vector3(4.95, 0.0, -31.5))
	_ruined_tower(root, Vector3(-5.4, 0.0, -37.8))
	_courtyard_end(root)
	var witnesses: Array[Node3D] = []
	for side: int in [-1, 1]:
		var variants: Array[int] = [0, 2, 3]
		if side > 0:
			variants = [1, 4, 5]
		for index: int in range(3):
			var position := Vector3(float(side) * 4.0, 0.025, 1.0 - float(index) * 1.5)
			var witness: Node3D = Heath._witness(root, position, variants[index], side)
			# Existing costume turn/step poses face this outboard retreat direction.
			witness.set_meta("retreat_direction", Vector3(float(side), 0.0, 0.0))
			witnesses.append(witness)
	var collapse := _collapse(root)
	collapse.set_meta("field_gun", weakref(field_gun))
	var kit: Dictionary = {"root": root, "witnesses": witnesses, "collapse": collapse}
	set_tableau(kit, "arrival", 0.0)
	set_collapse(kit, false, 0.0)
	return kit

static func set_tableau(kit: Dictionary, state: String, progress: float = 0.0) -> void:
	Heath.set_tableau(kit, state, _phase(progress))

static func set_collapse(kit: Dictionary, visible: bool, progress: float = 0.0) -> void:
	## Every pose is reconstructed, including reverse progress and fresh restore.
	var collapse := kit.get("collapse") as Node3D
	if not is_instance_valid(collapse):
		return
	var phase: float = _phase(progress)
	collapse.visible = visible
	collapse.set_meta("collapse_progress", phase)
	var fall: float = smoothstep(0.15, 0.85, phase)
	var machine := collapse.get_node_or_null("TripodFall") as Node3D
	if machine != null:
		machine.position = Vector3(0.28 * fall, -0.10 * fall, 0.0)
		machine.rotation = Vector3(0.0, 0.0, -1.43 * fall)
	for child: Node in collapse.get_children():
		var piece := child as MeshInstance3D
		if piece == null:
			continue
		var index: int = int(piece.get_meta("piece_index", 0))
		var home: Vector3 = piece.get_meta("home_position", Vector3.ZERO)
		if piece.has_meta("debris"):
			var flight: float = clampf((phase - 0.20) / 0.62, 0.0, 1.0)
			piece.visible = phase >= 0.20
			piece.position = home + Vector3(flight * (1.8 + float(index) * 0.28), -home.y * flight + sin(flight * PI) * 0.65 + 0.10 * flight, 0.0)
			piece.rotation = Vector3(flight * 1.7, flight * float(index + 1), flight * 2.3)
		elif piece.has_meta("steam"):
			var steam: float = clampf((phase - 0.40) / 0.60, 0.0, 1.0)
			piece.position = home + Vector3(steam * 0.55, steam * (1.4 + float(index) * 0.12), 0.0)
			piece.scale = Vector3(0.50 + steam * 1.1, 0.45 + steam * 1.45, 0.55 + steam * 0.7)
			_set_alpha(piece, smoothstep(0.0, 0.12, steam) * (1.0 - smoothstep(0.72, 1.0, steam)) * 0.42)
	var reference := collapse.get_meta("field_gun", null) as WeakRef
	var gun: Node3D = reference.get_ref() as Node3D if reference != null else null
	if is_instance_valid(gun):
		var flash := gun.get_node_or_null("ArtilleryMuzzleFlash") as MeshInstance3D
		var recoil: float = sin(clampf((phase - 0.03) / 0.18, 0.0, 1.0) * PI) * 0.10 if visible else 0.0
		if flash != null:
			flash.visible = visible and phase > 0.03 and phase < 0.15
			flash.position = Vector3(0.0, 1.18, -1.12 + recoil)
			var pulse: float = sin(clampf((phase - 0.03) / 0.12, 0.0, 1.0) * PI)
			flash.scale = Vector3(0.18 + pulse * 0.18, 0.18 + pulse * 0.18, 0.35 + pulse * 0.25)
			_set_alpha(flash, pulse * 0.72 if visible else 0.0)
		var barrel := gun.get_node_or_null("FieldGunBarrel") as MeshInstance3D
		if barrel != null:
			barrel.position = Vector3(0.0, 1.18, -0.22 + recoil)
		var bore := gun.get_node_or_null("DarkMuzzleBore") as MeshInstance3D
		if bore != null:
			bore.position = Vector3(0.0, 1.18, -1.002 + recoil)

static func _phase(progress: float) -> float:
	return clampf(progress, 0.0, 1.0) if is_finite(progress) else 0.0

static func _ground(root: Node3D) -> void:
	# One overlay spans the complete dry route; no cosmetic join or collider.
	_surface(root, "ContinuousDryPaving", Vector3(0.0, 0.005, -17.7), Vector2(6.8, 42.6), "paving")
	_surface(root, "ScenicUnderlyingEarth", Vector3(0.0, -0.20, -22.0), Vector2(26.0, 68.0), "earth")
	for side: int in [-1, 1]:
		_surface(root, "VillageOutboardPaving_%s" % side, Vector3(float(side) * 5.1, 0.003, -2.2), Vector2(3.4, 11.6), "paving")
		_surface(root, "QuayOutboardPaving_%s" % side, Vector3(float(side) * 4.1, 0.003, -19.0), Vector2(1.4, 22.0), "paving")
		_surface(root, "CourtyardOutboardPaving_%s" % side, Vector3(float(side) * 5.1, 0.003, -34.5), Vector2(3.4, 9.0), "paving")
		_surface(root, "WeyThamesWater_%s" % side, Vector3(float(side) * 8.9, -0.12, -19.0), Vector2(8.2, 22.0), "water")
	_surface(root, "DistantConfluenceWater", Vector3(0.0, -0.12, -46.0), Vector2(20.0, 12.8), "water")
	for side: int in [-1, 1]:
		for index: int in range(8):
			var curb: MeshInstance3D = Heath._box(root, "LowQuayCurb_%s_%s" % [side, index], Vector3(float(side) * 3.60, 0.06, -9.5 - float(index) * 2.7), Vector3(0.32, 0.12, 2.55), Heath._material("stone"))
			_optional_cutaway(root, curb)

static func _quay(root: Node3D) -> void:
	for side: int in [-1, 1]:
		var x: float = float(side) * 4.1
		for index: int in range(12):
			var z: float = -8.6 - float(index) * 1.8
			Heath._cylinder(root, "IronQuayPost_%s_%s" % [side, index], Vector3(x, 0.43, z), 0.048, 0.041, 0.86, Heath._material("metal"), 6)
			Heath._box(root, "QuayPostCap_%s_%s" % [side, index], Vector3(x, 0.89, z), Vector3(0.13, 0.08, 0.13), Heath._material("rim"))
			if index < 11:
				for height: float in [0.34, 0.68]:
					Heath._branch(root, Vector3(x, height, z), Vector3(x, height, z - 1.8), 0.030, Heath._material("metal"), "IronQuayRail")
		for index: int in range(4):
			var z: float = -19.1 - float(index) * 3.15
			Heath._box(root, "BrickBridgeAbutment_%s_%s" % [side, index], Vector3(float(side) * 4.25, -0.23, z), Vector3(0.60, 0.50, 2.5), Heath._material("brick"))
			Heath._box(root, "AbutmentCoping_%s_%s" % [side, index], Vector3(float(side) * 4.25, 0.05, z), Vector3(0.60, 0.08, 2.65), Heath._material("stone"))
	# Lock furniture is visibly on the far bank, not an actionable control.
	for side: int in [-1, 1]:
		var furniture := Node3D.new()
		furniture.name = "FarBankLockFurniture_%s" % side
		furniture.position = Vector3(float(side) * 5.35, 0.0, -14.0)
		root.add_child(furniture)
		Heath._box(furniture, "FarBankStoneLockBase", Vector3(0.0, -0.08, 0.0), Vector3(1.4, 0.16, 3.9), Heath._material("stone"))
		Heath._box(furniture, "WornTimberLockBeam", Vector3(0.0, 0.52, 0.0), Vector3(0.28, 0.30, 3.2), Heath._material("wood"))
		for z: float in [-1.25, 1.25]:
			Heath._cylinder(furniture, "LockIronPin", Vector3(0.0, 0.42, z), 0.09, 0.09, 0.84, Heath._material("metal"), 8)
		Heath._box(furniture, "RatchetHousing", Vector3(0.0, 0.94, -0.55), Vector3(0.40, 0.28, 0.45), Heath._material("metal"))

static func _cart(root: Node3D, position: Vector3) -> void:
	var cart := Node3D.new()
	cart.name = "AbandonedWoodenDogCart"
	cart.position = position
	root.add_child(cart)
	Heath._box(cart, "CartBed", Vector3(0.0, 0.73, 0.0), Vector3(1.08, 0.20, 1.18), Heath._material("wood"))
	for side: int in [-1, 1]:
		Heath._box(cart, "CartSideboard", Vector3(float(side) * 0.50, 0.97, 0.0), Vector3(0.09, 0.40, 1.18), Heath._material("wood"))
		Heath._branch(cart, Vector3(float(side) * 0.38, 0.63, 0.40), Vector3(float(side) * 0.38, 0.35, 2.30), 0.044, Heath._material("wood"), "EmptyHarnessShaft")
		_spoked_wheel(cart, Vector3(float(side) * 0.68, 0.475, 0.0), 0.46, "CartWheel_%s" % side)
	Heath._branch(cart, Vector3(-0.76, 0.475, 0.0), Vector3(0.76, 0.475, 0.0), 0.065, Heath._material("metal"), "CartAxle")
	Heath._box(cart, "LuggageChest", Vector3(0.10, 1.01, -0.14), Vector3(0.64, 0.40, 0.66), Heath._material("wood"))
	for x: float in [-0.10, 0.30]:
		Heath._box(cart, "LuggageStrap", Vector3(x, 1.22, -0.14), Vector3(0.045, 0.025, 0.69), Heath._material("metal"))
	Heath._box(cart, "FoldedPaleBundle", Vector3(-0.28, 0.95, 0.25), Vector3(0.34, 0.29, 0.47), Heath._material("ash_wood"))

static func _spoked_wheel(parent: Node3D, position: Vector3, radius: float, label: String) -> void:
	var wheel := Node3D.new()
	wheel.name = label
	wheel.position = position
	wheel.rotation.z = PI * 0.5
	parent.add_child(wheel)
	Heath._torus(wheel, "IronTyre", Vector3.ZERO, radius - 0.055, radius, Heath._material("rim"))
	Heath._cylinder(wheel, "AxleHub", Vector3.ZERO, 0.095, 0.095, 0.18, Heath._material("metal"), 8)
	for index: int in range(10):
		var angle: float = float(index) * TAU / 10.0
		Heath._branch(wheel, Vector3.ZERO, Vector3(cos(angle) * (radius - 0.05), 0.0, sin(angle) * (radius - 0.05)), 0.021, Heath._material("wood"), "WoodenSpoke")

static func _field_gun(root: Node3D, position: Vector3) -> Node3D:
	var gun := Node3D.new()
	gun.name = "RiversideFieldGun"
	gun.position = position
	root.add_child(gun)
	for side: int in [-1, 1]:
		_spoked_wheel(gun, Vector3(float(side) * 0.60, 0.555, 0.0), 0.54, "GunWheel_%s" % side)
		Heath._branch(gun, Vector3(float(side) * 0.35, 0.67, 0.0), Vector3(float(side) * 0.16, 0.13, 1.65), 0.07, Heath._material("wood"), "GunCarriageTrail")
	Heath._branch(gun, Vector3(-0.78, 0.555, 0.0), Vector3(0.78, 0.555, 0.0), 0.09, Heath._material("metal"), "GunAxle")
	Heath._box(gun, "BarrelCradle", Vector3(0.0, 0.89, 0.03), Vector3(0.70, 0.30, 0.55), Heath._material("metal"))
	var barrel: MeshInstance3D = Heath._cylinder(gun, "FieldGunBarrel", Vector3(0.0, 1.18, -0.22), 0.18, 0.14, 1.55, Heath._material("rim"), 12)
	barrel.rotation.x = PI * 0.5
	var bore: MeshInstance3D = Heath._cylinder(gun, "DarkMuzzleBore", Vector3(0.0, 1.18, -1.002), 0.11, 0.11, 0.018, Heath._material("cavity"), 12)
	bore.rotation.x = PI * 0.5
	var flash: MeshInstance3D = Heath._sphere(gun, "ArtilleryMuzzleFlash", Vector3(0.0, 1.18, -1.12), _alpha_material("fastener"))
	flash.visible = false
	return gun

static func _ruined_tower(root: Node3D, position: Vector3) -> void:
	var tower := Node3D.new()
	tower.name = "RuinedChurchTowerRemnant"
	tower.position = position
	root.add_child(tower)
	Heath._box(tower, "BrokenBrickTowerBase", Vector3(0.0, 1.05, 0.0), Vector3(1.40, 2.1, 1.4), Heath._material("brick"))
	Heath._box(tower, "DarkTowerArchRecess", Vector3(0.0, 0.82, 0.708), Vector3(0.46, 1.30, 0.02), Heath._material("cavity"))
	for side: int in [-1, 1]:
		Heath._box(tower, "BrokenUpperMasonry", Vector3(float(side) * 0.52, 2.26 + float(side) * 0.10, -0.24), Vector3(0.35, 0.60 + float(side) * 0.20, 0.88), Heath._material("brick"))
		Heath._box(tower, "TowerCopingFragment", Vector3(float(side) * 0.50, 2.64 + float(side) * 0.20, -0.24), Vector3(0.43, 0.15, 0.89), Heath._material("stone"))

static func _courtyard_end(root: Node3D) -> void:
	for side: int in [-1, 1]:
		var pier: MeshInstance3D = Heath._box(root, "FarCourtyardPier_%s" % side, Vector3(float(side) * 3.95, 1.12, -39.8), Vector3(0.55, 2.24, 0.55), Heath._material("brick"))
		_optional_cutaway(root, pier)
		var coping: MeshInstance3D = Heath._box(root, "CourtyardPierCoping_%s" % side, Vector3(float(side) * 3.95, 2.31, -39.8), Vector3(0.66, 0.14, 0.66), Heath._material("stone"))
		_optional_cutaway(root, coping)

static func _collapse(root: Node3D) -> Node3D:
	var collapse := Node3D.new()
	collapse.name = "DistantArtilleryTripodCollapse"
	collapse.position = COLLAPSE_ANCHOR
	root.add_child(collapse)
	var machine := Node3D.new()
	machine.name = "TripodFall"
	collapse.add_child(machine)
	# The complete standing/falling silhouette stays behind the route's Z-39 edge.
	Heath._cylinder(machine, "BrazenMovingHood", Vector3(0.0, 4.02, 0.0), 1.10, 0.68, 0.70, Heath._material("rim"), 12)
	Heath._torus(machine, "DarkHoodRim", Vector3(0.0, 3.70, 0.0), 1.025, 1.10, Heath._material("cavity"))
	Heath._cylinder(machine, "HoodCrown", Vector3(0.0, 4.44, -0.10), 0.17, 0.06, 0.22, Heath._material("fastener"), 8)
	for index: int in range(12):
		var angle: float = float(index) * TAU / 12.0
		Heath._cylinder(machine, "HoodRaisedRivet", Vector3(cos(angle) * 1.04, 3.76, sin(angle) * 1.04), 0.040, 0.040, 0.065, Heath._material("fastener"), 6)
	var hips: Array[Vector3] = [Vector3(-0.53, 3.62, 0.20), Vector3(0.53, 3.62, 0.20), Vector3(0.0, 3.62, -0.40)]
	var knees: Array[Vector3] = [Vector3(-0.74, 2.02, 0.34), Vector3(0.74, 2.02, 0.34), Vector3(0.0, 1.92, -0.62)]
	var feet: Array[Vector3] = [Vector3(-1.03, 0.065, 0.56), Vector3(1.03, 0.065, 0.56), Vector3(0.0, 0.065, -0.85)]
	for index: int in range(3):
		Heath._branch(machine, hips[index], knees[index], 0.10, Heath._material("metal"), "TripodUpperSupport_%s" % index)
		Heath._branch(machine, knees[index], feet[index], 0.080, Heath._material("rim"), "TripodLowerSupport_%s" % index)
		Heath._branch(machine, hips[index] + Vector3(0.08, -0.20, 0.0), knees[index] + Vector3(0.08, 0.12, 0.0), 0.030, Heath._material("cavity"), "ElasticJointSheath_%s" % index)
		var knee: MeshInstance3D = Heath._sphere(machine, "ArticulatedKnee_%s" % index, knees[index], Heath._material("fastener"))
		knee.scale = Vector3(0.24, 0.24, 0.24)
		Heath._box(machine, "TripodFoot_%s" % index, feet[index], Vector3(0.64, 0.13, 0.52), Heath._material("metal"))
	Heath._box(machine, "CameraLikeRayCase", Vector3(0.66, 3.85, 0.12), Vector3(0.52, 0.35, 0.55), Heath._material("metal"))
	var mirror: MeshInstance3D = Heath._cylinder(machine, "DistantRayMirror", Vector3(0.66, 3.85, 0.415), 0.20, 0.20, 0.035, Heath._material("fastener"), 8)
	mirror.rotation.x = PI * 0.5
	# Debris and steam are art, never falling bodies or surprise damage footprints.
	for index: int in range(4):
		var home := Vector3(-0.55 + float(index) * 0.32, 3.48 + float(index % 2) * 0.24, -0.40 + float(index) * 0.23)
		var debris: MeshInstance3D = Heath._box(collapse, "HarmlessHoodFragment_%s" % index, home, Vector3(0.24, 0.13, 0.31), Heath._material("metal"))
		debris.set_meta("debris", true)
		debris.set_meta("piece_index", index)
		debris.set_meta("home_position", home)
	for index: int in range(6):
		var home := Vector3(-0.45 + float(index) * 0.31, 0.14 + float(index % 2) * 0.12, -0.55 + float(index % 3) * 0.30)
		var steam: MeshInstance3D = Heath._sphere(collapse, "HarmlessRiverSteam_%s" % index, home, _alpha_material("vapour"))
		steam.set_meta("steam", true)
		steam.set_meta("piece_index", index)
		steam.set_meta("home_position", home)
	return collapse

static func _optional_cutaway(root: Node3D, mesh: MeshInstance3D) -> void:
	mesh.set_meta("weybridge_cutaway_candidate", true)
	var paths: Array = root.get_meta("optional_cutaway_paths", [])
	paths.append(str(root.get_path_to(mesh)))
	root.set_meta("optional_cutaway_paths", paths)

static func _alpha_material(kind: String) -> StandardMaterial3D:
	# Effects own their copies; never animate the reused Heath material cache.
	var material: StandardMaterial3D = Heath._material(kind).duplicate() as StandardMaterial3D
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
	return material

static func _set_alpha(mesh: MeshInstance3D, alpha: float) -> void:
	var material := mesh.material_override as StandardMaterial3D
	if material != null:
		var tint: Color = material.albedo_color
		tint.a = alpha
		material.albedo_color = tint

static func _surface(parent: Node3D, label: String, position: Vector3, size: Vector2, kind: String) -> void:
	var mesh: MeshInstance3D = Heath._plane(parent, label, position, size, "road")
	var material: StandardMaterial3D = _surface_material(kind).duplicate() as StandardMaterial3D
	material.uv1_scale = Vector3(size.x / TILE_WORLD_SIZE, size.y / TILE_WORLD_SIZE, 1.0)
	mesh.material_override = material

static func _surface_material(kind: String) -> StandardMaterial3D:
	var cached := _surface_cache.get(kind) as StandardMaterial3D
	if cached != null:
		return cached
	var palette: Array[Color] = [Color("817a6b"), Color("777466"), Color("918673"), Color("6c6a60")]
	if kind == "water":
		palette = [Color("3d4740"), Color("414a43"), Color("4b534a"), Color("343e38")]
	elif kind == "earth":
		palette = [Color("665d4d"), Color("60594c"), Color("706351"), Color("575347")]
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y: int in range(64):
		for x: int in range(64):
			var cluster: int = posmod((x >> 2) * 17 + (y >> 2) * 31, 29)
			var shade: int = 1 if cluster < 4 else (2 if cluster == 8 else 0)
			if kind == "paving" and (y % 8 == 0 or posmod(x + (8 if (y >> 3) % 2 == 0 else 0), 16) == 0):
				shade = 3
			elif kind == "water" and y % 16 == 0 and x % 13 < 3:
				shade = 2
			image.set_pixel(x, y, palette[shade])
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 0.92
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_surface_cache[kind] = material
	return material
