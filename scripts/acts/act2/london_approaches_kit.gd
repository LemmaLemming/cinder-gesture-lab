extends RefCounted
## Original A2-L4 arrangement of reused Act 2 module families and static weed.
## Collision, attack cues, clocks, contacts and all progression belong to the level.
const Heath = preload("res://scripts/acts/act2/heath_kit.gd")
const Weybridge = preload("res://scripts/acts/act2/weybridge_kit.gd")
const House = preload("res://scripts/acts/act2/ruined_house_kit.gd")
const Weed = preload("res://scripts/acts/act2/red_weed_visual.gd")
const Floor = preload("res://scripts/acts/act2/london_approaches_floor.gd")
const ART_REVISION := "a2-london-approaches-4"
const TILE_WORLD_SIZE := 1.44
const ACTOR_PIXEL_SIZE := 0.0225
const ARTILLERYMAN_HOME := Vector3(4.00, 0.025, -43.8)
## Cosmetic room cuts meet exactly; native support rectangles overlap separately.
const VISUAL_ROOM_RECTS: Array[Rect2] = [
	Rect2(-3.4, -8.3, 6.8, 11.9), Rect2(-3.4, -18.5, 6.8, 10.2),
	Rect2(-3.4, -27.5, 6.8, 9.0), Rect2(-3.4, -38.0, 6.8, 10.5),
	Rect2(-3.4, -50.0, 6.8, 12.0),
]
const ROOM_SURFACE_KINDS: Array[String] = ["earth", "road", "paving", "earth", "paving"]
static var _artilleryman_textures: Dictionary = {}

static func build(parent: Node3D) -> Dictionary:
	assert(is_instance_valid(parent), "London approaches scenery needs a level-owned parent")
	var root := Node3D.new()
	root.name = "LondonApproachesKit"
	root.set_meta("art_revision", ART_REVISION)
	root.set_meta("source_ids", ["G08", "G16", "G17", "G01", "G03"])
	root.set_meta("scenery_only", true)
	root.set_meta("optional_cutaway_paths", [])
	parent.add_child(root)
	_ground(root)
	_garden(root)
	_flood_margin(root)
	_villas(root)
	_putney(root)
	var witnesses: Array[Node3D] = []
	for index: int in range(4):
		var side: int = -1 if index % 2 == 0 else 1
		var witness: Node3D = Heath._witness(root, Vector3(float(side) * 4.05, 0.025, -0.3 - floorf(float(index) * 0.5) * 1.9), index, side)
		witness.name = "GardenWitness_%s" % index
		witness.set_meta("retreat_direction", Vector3(float(side), 0.0, 0.0))
		witnesses.append(witness)
	var artilleryman: Node3D = _artilleryman(root)
	var kit: Dictionary = {"root": root, "witnesses": witnesses, "artilleryman": artilleryman}
	set_departure_tableau(kit, false)
	return kit

static func set_departure_tableau(kit: Dictionary, active: bool, progress: float = 0.0) -> void:
	# Reconstruct directly from caller-owned progress, including after restore.
	var phase: float = clampf(progress, 0.0, 1.0) if is_finite(progress) else 0.0
	var root := kit.get("root") as Node3D
	if is_instance_valid(root):
		root.set_meta("departure_tableau_active", active)
		root.set_meta("departure_tableau_progress", phase)
	var witnesses: Array = kit.get("witnesses", [])
	for candidate: Variant in witnesses:
		var witness := candidate as Node3D
		if not is_instance_valid(witness):
			continue
		var home: Vector3 = witness.get_meta("home_position", Vector3.ZERO)
		var retreat: Vector3 = witness.get_meta("retreat_direction", Vector3.ZERO)
		witness.position = home + retreat * (phase * 0.7 if active else 0.0)
		witness.visible = not active or phase < 1.0
		var pose: String = "watch" if not active else ("turn" if phase < 0.2 else ("retreat_a" if int(floor(phase * 8.0)) % 2 == 0 else "retreat_b"))
		var sprite := witness.get_node_or_null("FeetAnchoredCostume") as Sprite3D
		if sprite != null:
			sprite.texture = Heath._witness_texture(int(witness.get_meta("costume_variant", 0)), pose)
		witness.set_meta("witness_pose", pose)
	var soldier := kit.get("artilleryman") as Node3D
	if not is_instance_valid(soldier):
		return
	soldier.position = ARTILLERYMAN_HOME
	soldier.visible = active
	var soldier_pose: String = "rest" if phase < 0.5 else "satchel"
	var soldier_sprite := soldier.get_node_or_null("FeetAnchoredCostume") as Sprite3D
	if soldier_sprite != null:
		soldier_sprite.texture = _artilleryman_texture(soldier_pose)
	soldier.set_meta("tableau_pose", soldier_pose)

static func _ground(root: Node3D) -> void:
	# One continuous low-contrast top surface hides no support joins. Room
	# overlays vary material without making apparent holes or raised platforms.
	_surface(root, "ContinuousDryRoad", Vector3(0.0, 0.005, -23.2), Vector2(6.8, 53.6), "road")
	for index: int in range(VISUAL_ROOM_RECTS.size()):
		var rect: Rect2 = VISUAL_ROOM_RECTS[index]
		var kind: String = ROOM_SURFACE_KINDS[index]
		_surface(root, "%sQuietFloor" % Floor.SPECS[index].id, Vector3(rect.get_center().x, 0.008, rect.get_center().y), rect.size, kind)
	for side: int in [-1, 1]:
		var x: float = float(side) * 3.60
		_box(root, root, "DryRoadCurb_%s" % side, Vector3(x, 0.065, -23.2), Vector3(0.36, 0.13, 53.6), "stone")
		_surface(root, "OutboardEarth_%s" % side, Vector3(float(side) * 5.2, -0.015, -23.2), Vector2(3.2, 53.6), "earth")

static func _garden(root: Node3D) -> void:
	var garden := _node(root, "ChangedGarden", Vector3.ZERO)
	# Exact opaque base communicates the independent native collision extent.
	var specification: Dictionary = Floor.BLOCKERS[0]
	_box(root, garden, String(specification.id) + "VisibleBase", specification.at, specification.size, "bark")
	for side: int in [-1, 1]:
		var sign_side: float = float(side)
		_box(root, garden, "GardenBrickBoundary_%s" % side, Vector3(sign_side * 4.1, 0.30, -3.8), Vector3(0.55, 0.60, 5.0), "brick")
		_villa(root, Vector3(sign_side * 4.50, 0.0, 0.0), side, false, "GardenHouse_%s" % side)
		for index: int in range(3):
			if index == 0:
				var frond: Node3D = _weed(root, garden, "GardenFronds_%s_%s" % [side, index], Vector3(sign_side * 4.10, 0.0, -2.1), "dense", 6)
				_portrait_weed_transform(frond, side)
			else:
				_weed(root, garden, "GardenFronds_%s_%s" % [side, index], Vector3(sign_side * 4.70, 0.0, -2.1 - float(index) * 2.5), "dense", index + (4 if side < 0 else 0))
	# Sparse, native-size branching on the fixed stem base is visual only;
	# the base above remains the complete collision shape, never moving weed.
	_weed(root, garden, "FixedGardenStemCrown", Vector3(0.0, 0.80, -4.6), "sparse", 2)
	Weybridge._cart(garden, Vector3(5.10, 0.0, -6.5))
	_collect_cutaway(root, garden)

static func _flood_margin(root: Node3D) -> void:
	var flood := _node(root, "FloodDryMargin", Vector3.ZERO)
	for side: int in [-1, 1]:
		var sign_side: float = float(side)
		_surface(flood, "FloodWater_%s" % side, Vector3(sign_side * 5.15, -0.12, -13.8), Vector2(3.4, 10.0), "water")
		_box(root, flood, "BrickCulvertAbutment_%s" % side, Vector3(sign_side * 4.30, 0.43, -16.8), Vector3(1.0, 0.86, 2.2), "brick")
		_box(root, flood, "CulvertStoneCap_%s" % side, Vector3(sign_side * 4.30, 0.91, -16.8), Vector3(1.14, 0.10, 2.3), "stone")
		for index: int in range(3):
			if index == 1:
				var frond: Node3D = _weed(root, flood, "WaterFronds_%s_%s" % [side, index], Vector3(sign_side * 4.10, 0.0, -13.15), "dense", 6)
				_portrait_weed_transform(frond, side)
			else:
				_weed(root, flood, "WaterFronds_%s_%s" % [side, index], Vector3(sign_side * 4.85, 0.0, -10.4 - float(index) * 2.75), "dense", index + 1)
		_lamp(root, Vector3(sign_side * 3.95, 0.0, -18.1), "FloodLamp_%s" % side)
		_iron_fence(root, flood, Vector3(sign_side * 3.95, 0.0, -13.4), 3.0, "FloodRail_%s" % side)

static func _villas(root: Node3D) -> void:
	var villas := _node(root, "TwoVillaArrangements", Vector3.ZERO)
	var specification: Dictionary = Floor.BLOCKERS[1]
	_box(root, villas, String(specification.id) + "VisibleBase", specification.at, specification.size, "brick")
	# Mortar/coping stays within the same measured fixed wall envelope.
	_box(root, villas, "VillaLowWallCoping", Vector3(0.0, 0.415, -22.6), Vector3(1.5, 0.07, 0.45), "stone")
	# The low body may fade to reveal feet/cues, but its solid footprint must
	# remain legible. Reuse opaque brick on one exact ground-level plane.
	# It is ordinary scenery, never a threat outline or interaction cue.
	_surface(villas, "VillaLowWallPersistentBrickBase", Vector3(0.0, 0.013, -22.6), Vector2(1.5, 0.45), "brick")
	for side: int in [-1, 1]:
		var sign_side: float = float(side)
		_villa(root, Vector3(sign_side * 4.50, 0.0, -22.0), side, false, "ShutteredVilla_%s" % side)
		_villa(root, Vector3(sign_side * 4.50, 0.0, -31.5), side, side > 0, "RuinVilla_%s" % side)
		for index: int in range(2):
			var at := Vector3(sign_side * (4.05 if index == 0 else 4.25), 0.0, -27.3 - float(index) * 1.0)
			var pale: Node3D = _weed(root, villas, "BleachedQuietView_%s_%s" % [side, index], at, "bleached", index + 3)
			_portrait_weed_transform(pale, side, Vector3(0.8, 1.0, 0.8))
		_lamp(root, Vector3(sign_side * 3.98, 0.0, -35.5), "VillaLamp_%s" % side)
		var frond: Node3D = _weed(root, villas, "SecondVillaFronds_%s" % side, Vector3(sign_side * 4.10, 0.0, -34.8), "dense", 6)
		_portrait_weed_transform(frond, side)
	var debris := _node(villas, "OutboardRuinFurniture", Vector3(4.72, 0.0, -34.6))
	_box(root, debris, "BrokenTableTop", Vector3(0.0, 0.32, 0.0), Vector3(0.95, 0.11, 0.62), "wood")
	for x: float in [-0.33, 0.33]:
		_box(root, debris, "BrokenTableLeg", Vector3(x, 0.14, 0.17), Vector3(0.07, 0.28, 0.07), "wood")
	for index: int in range(3):
		var tin: MeshInstance3D = Heath._cylinder(debris, "EmptyTin_%s" % index, Vector3(-0.22 + float(index) * 0.22, 0.43, 0.0), 0.055, 0.055, 0.12, Heath._material("rim"), 8)
		_mark_cutaway(root, tin)

static func _putney(root: Node3D) -> void:
	var putney := _node(root, "BroadPutneyApproach", Vector3.ZERO)
	for side: int in [-1, 1]:
		var sign_side: float = float(side)
		_villa(root, Vector3(sign_side * 4.50, 0.0, -41.5), side, true, "PutneyTerrace_%s" % side)
		_box(root, putney, "BridgeOutboardPier_%s" % side, Vector3(sign_side * 4.4, 0.65, -46.0), Vector3(1.0, 1.30, 1.8), "brick")
		_box(root, putney, "BridgePierCap_%s" % side, Vector3(sign_side * 4.4, 1.34, -46.0), Vector3(1.12, 0.08, 1.9), "stone")
		_iron_fence(root, putney, Vector3(sign_side * 4.0, 0.0, -46.0), 3.0, "PutneyBridgeRail_%s" % side)
		var weed: Node3D = _weed(root, putney, "SparsePutneyWeed_%s" % side, Vector3(sign_side * 4.10, 0.0, -37.6), "sparse", 1)
		_portrait_weed_transform(weed, side, Vector3(0.9, 1.0, 0.9))
		_lamp(root, Vector3(sign_side * 4.0, 0.0, -48.0), "PutneyLamp_%s" % side)
	var gun: Node3D = Weybridge._field_gun(putney, Vector3(-4.30, 0.0, -43.8))
	gun.name = "QuietAbandonedFieldGun"
	gun.set_meta("scenery_only", true)
	_collect_cutaway(root, gun)

static func _villa(root: Node3D, at: Vector3, side: int, ruined: bool, label: String) -> void:
	var villa := _node(root, label, at)
	# Present the existing sash/door face to both the road and fixed camera.
	# Compact X/Z only; door and wall height remain native. At |X|4.50 the
	# widest intact eave stays beyond |X|3.45, outside the dry-floor edge.
	villa.rotation.y = -float(side) * PI / 6.0
	villa.scale = Vector3(0.65, 1.0, 0.65)
	villa.set_meta("kit_placement_revision", ART_REVISION)
	villa.set_meta("kit_placement_scale", villa.scale)
	var height: float = 1.55 if ruined else 2.15
	_box(root, villa, "BrickFacade", Vector3(0.0, height * 0.5, 0.0), Vector3(2.65, height, 0.65), "brick")
	_box(root, villa, "Foundation", Vector3(0.0, 0.14, 0.0), Vector3(2.85, 0.28, 1.10), "stone")
	_box(root, villa, "Lintel", Vector3(0.0, 1.47, 0.39), Vector3(0.63, 0.09, 0.14), "stone")
	_box(root, villa, "RecessedDoor", Vector3(0.0, 0.69, 0.341), Vector3(0.55, 1.25, 0.04), "wood")
	_box(root, villa, "DoorHandle", Vector3(0.17, 0.70, 0.375), Vector3(0.035, 0.035, 0.02), "rim")
	for x: float in [-0.91, 0.91]:
		_box(root, villa, "DarkSashWindow", Vector3(x, 0.98, 0.341), Vector3(0.62, 0.75, 0.035), "window")
		_box(root, villa, "SashVertical", Vector3(x, 0.98, 0.37), Vector3(0.035, 0.75, 0.045), "ash_wood")
		_box(root, villa, "SashHorizontal", Vector3(x, 0.98, 0.38), Vector3(0.62, 0.035, 0.05), "ash_wood")
		_box(root, villa, "WindowSill", Vector3(x, 0.58, 0.39), Vector3(0.78, 0.07, 0.19), "stone")
		var shutter_x: float = x + (-0.36 if x < 0.0 else 0.36)
		_box(root, villa, "ClosedSideShutter", Vector3(shutter_x, 0.98, 0.34), Vector3(0.15, 0.78, 0.07), "wood")
		for y: float in [0.71, 1.04, 1.30]:
			_box(root, villa, "ShutterSlat", Vector3(shutter_x, y, 0.39), Vector3(0.15, 0.02, 0.03), "ash_wood")
	if not ruined:
		_box(root, villa, "SlateEave", Vector3(0.0, 2.20, 0.0), Vector3(2.95, 0.18, 1.35), "slate")
		_box(root, villa, "BrickChimney", Vector3(-0.75, 2.37, -0.15), Vector3(0.30, 0.34, 0.32), "brick")
	else:
		for index: int in range(4):
			_box(root, villa, "BrokenWallCrown", Vector3(-1.10 + float(index) * 0.53, 1.60 + float(index % 2) * 0.12, 0.0), Vector3(0.36, 0.12 + float(index % 2) * 0.24, 0.64), "brick")
		var plank: MeshInstance3D = _box(root, villa, "LeaningBrokenTimber", Vector3(0.35, 0.75, 0.62), Vector3(0.09, 1.48, 0.10), "wood")
		plank.rotation.z = -0.35
	var creeper: Node3D = _weed(root, villa, "FacadeCreeper", Vector3(-0.43, 0.0, 0.43), "creeper", 4 if ruined else 0)
	creeper.set_meta("wall_attached_scenery", true)

static func _iron_fence(root: Node3D, parent: Node3D, at: Vector3, length: float, label: String) -> void:
	var fence := _node(parent, label, at)
	for index: int in range(5):
		var z: float = -length * 0.5 + float(index) * length * 0.25
		_box(root, fence, "IronUpright_%s" % index, Vector3(0.0, 0.40, z), Vector3(0.055, 0.80, 0.055), "metal")
	for y: float in [0.31, 0.64]:
		_box(root, fence, "IronCrossRail", Vector3(0.0, y, 0.0), Vector3(0.045, 0.045, length), "metal")

static func _lamp(root: Node3D, at: Vector3, label: String) -> void:
	var lamp := _node(root, label, at)
	_box(root, lamp, "GroundedLampBase", Vector3(0.0, 0.10, 0.0), Vector3(0.24, 0.20, 0.24), "stone")
	_box(root, lamp, "UnlitIronPost", Vector3(0.0, 0.85, 0.0), Vector3(0.07, 1.50, 0.07), "metal")
	_box(root, lamp, "DarkLantern", Vector3(0.0, 1.72, 0.0), Vector3(0.23, 0.32, 0.23), "window")
	_box(root, lamp, "LanternCap", Vector3(0.0, 1.92, 0.0), Vector3(0.31, 0.09, 0.31), "metal")

static func _weed(root: Node3D, parent: Node3D, label: String, at: Vector3, variant: String, seed: int) -> Node3D:
	var weed: Node3D = Weed.build(parent, variant, seed)
	assert(is_instance_valid(weed), "Static weed helper must support the authored variant")
	weed.name = label
	weed.position = at
	for path: String in weed.get_meta("optional_cutaway_paths", []):
		var mesh := weed.get_node_or_null(NodePath(path)) as MeshInstance3D
		if is_instance_valid(mesh):
			_mark_cutaway(root, mesh, false)
	return weed

static func _portrait_weed_transform(weed: Node3D, side: int, native_scale: Vector3 = Vector3.ONE) -> void:
	# Curated existing seed forms expose an inward crown without moving roots
	# into the route. Parent transform is separate from immutable native stats.
	weed.rotation.y = PI if side < 0 else 0.0
	weed.scale = native_scale
	weed.set_meta("kit_placement_revision", ART_REVISION)
	weed.set_meta("kit_placement_scale", native_scale)

static func _node(parent: Node3D, label: String, at: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = label
	node.position = at
	parent.add_child(node)
	return node

static func _box(root: Node3D, parent: Node3D, label: String, at: Vector3, size: Vector3, kind: String) -> MeshInstance3D:
	var mesh: MeshInstance3D = Heath._box(parent, label, at, size, House._material(kind))
	_mark_cutaway(root, mesh)
	return mesh

static func _surface(parent: Node3D, label: String, at: Vector3, size: Vector2, kind: String) -> void:
	var mesh: MeshInstance3D = Heath._plane(parent, label, at, size, "sand_clear")
	var material: StandardMaterial3D = (Weybridge._surface_material(kind) if kind in ["paving", "earth", "water"] else Heath._material(kind)).duplicate() as StandardMaterial3D
	material.uv1_scale = Vector3(size.x / TILE_WORLD_SIZE, size.y / TILE_WORLD_SIZE, 1.0)
	mesh.material_override = material

static func _collect_cutaway(root: Node3D, node: Node) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		# Ground planes remain opaque; architecture and furniture are eligible.
		if not mesh.mesh is PlaneMesh and not mesh.has_meta("london_cutaway_registered"):
			_mark_cutaway(root, mesh)
	for child: Node in node.get_children():
		_collect_cutaway(root, child)

static func _mark_cutaway(root: Node3D, mesh: MeshInstance3D, duplicate_material: bool = true) -> void:
	if mesh.has_meta("london_cutaway_registered"):
		return
	var material := mesh.material_override as StandardMaterial3D
	assert(material != null, "Every optional cutaway must have an instance StandardMaterial3D")
	if duplicate_material:
		mesh.material_override = material.duplicate() as StandardMaterial3D
	mesh.set_meta("london_cutaway_registered", true)
	mesh.set_meta("weybridge_cutaway_candidate", true)
	var paths: Array = root.get_meta("optional_cutaway_paths", [])
	paths.append(str(root.get_path_to(mesh)))
	root.set_meta("optional_cutaway_paths", paths)

static func _artilleryman(root: Node3D) -> Node3D:
	var soldier: Node3D = Heath._witness(root, ARTILLERYMAN_HOME, 2, 1)
	soldier.name = "NonhostileArtilleryman"
	soldier.set_meta("source_ids", ["G01", "C04"])
	soldier.set_meta("art_revision", ART_REVISION)
	soldier.set_meta("costume_family", "late-Victorian artilleryman; muted olive with red collar, cross strap and satchel")
	var sprite: Sprite3D = soldier.get_node("FeetAnchoredCostume") as Sprite3D
	sprite.texture = _artilleryman_texture("rest")
	return soldier

static func _artilleryman_texture(pose: String) -> Texture2D:
	var cached := _artilleryman_textures.get(pose) as Texture2D
	if cached != null:
		return cached
	# Reuse the 48x64 feet-anchored human grid, replacing civilian workman's
	# clothing with the selected G01 soldier vocabulary. No cue-like glow.
	var image: Image = Heath._witness_texture(2).get_image()
	var olive := Color("626348")
	var dark_olive := Color("414835")
	var red := Color("7d423a")
	var skin := Color("bfa283")
	Heath._rect(image, 18, 6, 13, 3, dark_olive)
	Heath._rect(image, 16, 23, 16, 25, olive)
	Heath._rect(image, 18, 20, 12, 3, red)
	Heath._rect(image, 13, 24, 5, 8, olive)
	Heath._rect(image, 30, 24, 5, 8, olive)
	Heath._rect(image, 13, 32, 5, 7, skin)
	Heath._rect(image, 30, 32, 5, 7, skin)
	Heath._rect(image, 18, 48, 6, 11, dark_olive)
	Heath._rect(image, 26, 48, 6, 11, dark_olive)
	Heath._line(image, Vector2i(18, 23), Vector2i(30, 43), Color("ac9675"))
	Heath._line(image, Vector2i(19, 23), Vector2i(31, 43), Color("ac9675"))
	Heath._rect(image, 28, 40, 8, 10, Color("66543b"))
	Heath._rect(image, 29, 40, 6, 2, Color("9c8867"))
	Heath._rect(image, 17, 43, 16, 3, Color("554733"))
	if pose == "satchel":
		Heath._rect(image, 29, 34, 6, 7, dark_olive)
		Heath._rect(image, 28, 40, 5, 3, skin)
	var texture: Texture2D = ImageTexture.create_from_image(image)
	_artilleryman_textures[pose] = texture
	return texture
