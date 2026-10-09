extends RefCounted
## Original exposed-house/work-apron scenery for A2-L3. No gameplay authority.
## The level owns floors, the matching central blocker, clocks and smoke.

const Heath: Script = preload("res://scripts/acts/act2/heath_kit.gd")
const Weybridge: Script = preload("res://scripts/acts/act2/weybridge_kit.gd")
const ART_REVISION := "a2-ruined-house-kit-1"
const TILE_WORLD_SIZE := 1.44
const LOW_WALL_CENTER := Vector3(0.0, 0.225, -13.4)
const LOW_WALL_SIZE := Vector3(2.5, 0.45, 0.45)
const WORK_ANCHOR := Vector3(4.8, 0.0, -23.0)
static var _material_cache: Dictionary = {}


static func build(parent: Node3D) -> Dictionary:
	assert(parent != null, "Ruined-house scenery requires a level-owned parent.")
	var root := Node3D.new()
	root.name = "RuinedHouseSceneryKit"
	root.set_meta("art_revision", ART_REVISION)
	root.set_meta("source_ids", ["G07", "G19", "sample-S02"])
	root.set_meta("scenery_only", true)
	root.set_meta("optional_cutaway_paths", [])
	root.set_meta("collision_role", "none; level-owned dry floors and central low wall")
	parent.add_child(root)
	_ground(root)
	_central_wall(root)
	_exposed_house(root)
	_work_apron(root)
	_excavation(root)
	var work: Node3D = _work_tableau(root)
	var witnesses: Array[Node3D] = []
	var kit: Dictionary = {"root": root, "witnesses": witnesses, "work_tableau": work}
	set_work_tableau(kit, false, 0.0)
	return kit


static func set_work_tableau(kit: Dictionary, active: bool, progress: float = 0.0) -> void:
	# Supplied progress reconstructs every transform; inactive retains a quiet
	# supplied arrangement. No timer, signal, combat phase or completion event.
	var work := kit.get("work_tableau") as Node3D
	if not is_instance_valid(work):
		return
	var p: float = clampf(progress, 0.0, 1.0) if is_finite(progress) else 0.0
	work.set_meta("work_active", active)
	work.set_meta("work_progress", p)
	var transfer: float = smoothstep(0.12, 0.88, p)
	var lift: float = sin(p * PI) * 0.34
	var plate_at := Vector3(lerpf(-0.65, 0.28, transfer), 0.15 + lift, 0.36)
	var grip_at: Vector3 = plate_at + Vector3(0.0, 0.16, 0.0)
	var elbow := Vector3(-0.16 + transfer * 0.15, 0.83 + lift * 0.35, 0.12)
	var shoulder := Vector3(-0.24, 0.65, -0.16)
	var plate := work.get_node_or_null("TransferredPlate") as MeshInstance3D
	var grip := work.get_node_or_null("PlateClamp") as Node3D
	var upper := work.get_node_or_null("UpperWorkRod") as MeshInstance3D
	var lower := work.get_node_or_null("LowerWorkRod") as MeshInstance3D
	var joint := work.get_node_or_null("MovingRoundJournal") as MeshInstance3D
	if plate != null:
		plate.position = plate_at
		plate.rotation = Vector3(0.0, 0.06 * sin(p * PI), -0.06 * sin(p * PI))
	if grip != null:
		grip.position = grip_at
		grip.rotation = Vector3(0.0, 0.0, -0.06 * sin(p * PI))
		for side: int in [-1, 1]:
			var finger := grip.get_node_or_null("ClampFinger_%s" % side) as MeshInstance3D
			if finger != null:
				finger.position = Vector3(float(side) * (0.125 if active else 0.155), -0.07, 0.0)
	if upper != null:
		_fit_segment(upper, shoulder, elbow)
	if lower != null:
		_fit_segment(lower, elbow, grip_at)
	if joint != null:
		joint.position = elbow


static func _ground(root: Node3D) -> void:
	# Complete continuous dry visual support: no holes and no cutaway floor.
	_surface(root, "ContinuousPaleAshFoundation", Vector3(0.0, 0.004, -18.7), Vector2(6.8, 44.6), "ash_floor")
	_surface(root, "ArrivalDrySandRoad", Vector3(0.0, 0.006, -2.6), Vector2(6.8, 12.4), "road")
	_surface(root, "ExposedHouseWornFloor", Vector3(0.0, 0.006, -13.9), Vector2(6.8, 10.2), "floor_timber")
	_surface(root, "WorkApronDryPaving", Vector3(0.0, 0.006, -24.25), Vector2(6.8, 10.5), "paving")
	_surface(root, "BossOpeningAshPaving", Vector3(0.0, 0.006, -35.25), Vector2(6.8, 11.5), "ash_floor")
	_surface(root, "ScenicUnderlyingDryEarth", Vector3(0.0, -0.16, -19.0), Vector2(26.0, 72.0), "earth")
	for side: int in [-1, 1]:
		_surface(root, "OutboardHouseFoundation_%s" % side, Vector3(float(side) * 4.65, 0.001, -13.6), Vector2(2.5, 12.6), "ash_floor")
		_surface(root, "OutboardWorkFoundation_%s" % side, Vector3(float(side) * 5.0, 0.001, -29.4), Vector2(3.2, 21.2), "paving")
		for index: int in range(5):
			var mark := _box(root, root, "RoadEdgeWornStone_%s_%s" % [side, index], Vector3(float(side) * 3.51, 0.045, 1.2 - float(index) * 2.0), Vector3(0.20, 0.09, 0.62), "stone")
			mark.rotation.y = float(side) * 0.025 * float(index % 3)


static func _central_wall(root: Node3D) -> void:
	var wall := _node(root, "CentralLowWall", Vector3(0.0, 0.0, LOW_WALL_CENTER.z), "a2-l3-central-low-wall")
	wall.set_meta("expected_level_collider_center", LOW_WALL_CENTER)
	wall.set_meta("expected_level_collider_size", LOW_WALL_SIZE)
	wall.set_meta("side_approach_width_m", 2.15)
	# Both mesh bounds stay within the one exact future root blocker.
	_box(root, wall, "WeatheredBrickWallBody", Vector3(0.0, 0.195, 0.0), Vector3(2.5, 0.39, 0.45), "brick")
	_box(root, wall, "WornFlushCoping", Vector3(0.0, 0.42, 0.0), Vector3(2.5, 0.06, 0.45), "stone")


static func _exposed_house(root: Node3D) -> void:
	var house := _node(root, "ExposedKitchenSculleryPantry", Vector3.ZERO, "a2-l3-exposed-house")
	house.set_meta("front_wall_removed", true)
	# Rooms sit at the route margins. There is no facade across either approach.
	for side: int in [-1, 1]:
		var x: float = float(side) * 4.10
		for index: int in range(3):
			var z: float = -9.9 - float(index) * 3.55
			_box(root, house, "BrickSidePier_%s_%s" % [side, index], Vector3(x, 0.67, z), Vector3(0.38, 1.34, 0.42), "brick")
			_box(root, house, "ChippedPierCoping_%s_%s" % [side, index], Vector3(x, 1.365, z), Vector3(0.40, 0.05, 0.44), "ash_wood")
			_box(root, house, "ExposedPlasterPanel_%s_%s" % [side, index], Vector3(float(side) * 4.28, 0.72, z - 1.35), Vector3(0.16, 1.40, 2.25), "plaster")
		var beam := _box(root, house, "BrokenLongitudinalTimber_%s" % side, Vector3(float(side) * 3.94, 1.49, -13.7), Vector3(0.16, 0.17, 8.25), "char")
		beam.rotation.z = float(side) * 0.045
		for index: int in range(3):
			_rod(root, house, "SplitRoofRafter_%s_%s" % [side, index], Vector3(float(side) * 4.15, 1.40, -10.6 - float(index) * 2.7), Vector3(float(side) * 3.51, 1.14, -11.0 - float(index) * 2.7), 0.043, "char")
	_pantry(root, house, Vector3(-3.50, 0.0, -10.95))
	_sink(root, house, Vector3(3.63, 0.0, -11.55))
	_hearth(root, house, Vector3(-3.64, 0.0, -16.7))
	var arch: Node3D = _brick_arch(root, house, Vector3(3.90, 0.0, -16.35))
	arch.rotation.y = PI * 0.25
	var window := _node(house, "BrokenScullerySash", Vector3(3.58, 0.0, -13.45), "a2-l3-broken-window")
	for z: float in [-0.47, 0.47]:
		_box(root, window, "SashUpright_%s" % z, Vector3(0.0, 0.83, z), Vector3(0.09, 1.36, 0.09), "ash_wood")
	for y: float in [0.16, 0.84, 1.49]:
		_box(root, window, "SashCrosspiece_%s" % y, Vector3(0.0, y, 0.0), Vector3(0.09, 0.06, 1.0), "ash_wood")
	_rod(root, window, "BrokenSashSplinter", Vector3(-0.08, 0.57, -0.08), Vector3(-0.18, 0.93, 0.18), 0.022, "wood")
	for side: int in [-1, 1]:
		for index: int in range(5):
			var fragment := _box(root, house, "PeripheralBrickFragment_%s_%s" % [side, index], Vector3(float(side) * (3.42 + float(index % 2) * 0.14), 0.050, -9.5 - float(index) * 1.9), Vector3(0.19, 0.10, 0.29), "brick")
			fragment.rotation.y = 0.27 * float(index + side)


static func _pantry(root: Node3D, parent: Node3D, at: Vector3) -> void:
	var pantry := _node(parent, "ExposedPantryShelves", at, "a2-l3-pantry")
	_box(root, pantry, "PantryBackTimber", Vector3(-0.39, 0.72, 0.0), Vector3(0.10, 1.38, 1.58), "wood")
	for z: float in [-0.74, 0.74]:
		_box(root, pantry, "PantryUpright_%s" % z, Vector3(-0.17, 0.66, z), Vector3(0.075, 1.32, 0.08), "wood")
	for index: int in range(3):
		var y: float = 0.30 + float(index) * 0.39
		_box(root, pantry, "WornShelf_%s" % index, Vector3(-0.13, y, 0.0), Vector3(0.66, 0.06, 1.59), "wood")
		_pot(root, pantry, "PotteryJar_%s" % index, Vector3(-0.05, y + 0.16, -0.43 + float(index % 2) * 0.08), 0.115, 0.25, "pottery")
		for plate_index: int in range(2):
			_plate(root, pantry, "ShelfPlate_%s_%s" % [index, plate_index], Vector3(0.05, y + 0.045 + float(plate_index) * 0.028, 0.42), 0.17)
	_box(root, pantry, "LowFlourTin", Vector3(-0.12, 0.16, 0.13), Vector3(0.29, 0.26, 0.27), "rim")


static func _sink(root: Node3D, parent: Node3D, at: Vector3) -> void:
	var sink := _node(parent, "SculleryDrySink", at, "a2-l3-scullery-sink")
	_box(root, sink, "WornSinkCabinet", Vector3(0.12, 0.34, 0.0), Vector3(0.71, 0.68, 1.28), "wood")
	_box(root, sink, "DryBasinFloor", Vector3(0.07, 0.688, 0.0), Vector3(0.58, 0.014, 1.11), "cavity")
	for side: int in [-1, 1]:
		_box(root, sink, "PaleBasinLongRim_%s" % side, Vector3(0.07 + float(side) * 0.31, 0.747, 0.0), Vector3(0.08, 0.13, 1.26), "ceramic")
		_box(root, sink, "PaleBasinEndRim_%s" % side, Vector3(0.07, 0.747, float(side) * 0.60), Vector3(0.54, 0.13, 0.08), "ceramic")
	_rod(root, sink, "DryTapStem", Vector3(0.29, 0.80, -0.39), Vector3(0.29, 1.01, -0.39), 0.025, "rim")
	_rod(root, sink, "TapBentSpout", Vector3(0.29, 1.01, -0.39), Vector3(0.09, 1.01, -0.39), 0.025, "rim")
	_box(root, sink, "TapQuietCrossbar", Vector3(0.29, 0.95, -0.39), Vector3(0.08, 0.023, 0.06), "metal")
	_pot(root, sink, "EmptySculleryPot", Vector3(0.01, 0.14, 0.91), 0.17, 0.26, "char")


static func _hearth(root: Node3D, parent: Node3D, at: Vector3) -> void:
	var hearth := _node(parent, "BrokenKitchenHearth", at, "a2-l3-kitchen-hearth")
	_box(root, hearth, "ColdHearthStone", Vector3(-0.12, 0.065, 0.0), Vector3(0.85, 0.13, 1.55), "stone")
	_box(root, hearth, "ColdFireboxBack", Vector3(-0.38, 0.39, 0.0), Vector3(0.10, 0.66, 0.89), "cavity")
	for z: float in [-0.56, 0.56]:
		_box(root, hearth, "HearthBrickCheek_%s" % z, Vector3(-0.11, 0.40, z), Vector3(0.61, 0.67, 0.20), "brick")
	_box(root, hearth, "CrackedHearthLintel", Vector3(-0.11, 0.77, 0.0), Vector3(0.65, 0.14, 1.28), "brick")
	_pot(root, hearth, "BlackKitchenStewPot", Vector3(0.03, 0.28, 0.0), 0.19, 0.28, "char")
	for index: int in range(2):
		_rod(root, hearth, "ColdCharredFirewood_%s" % index, Vector3(0.03, 0.145, -0.30 + float(index) * 0.40), Vector3(0.17, 0.145, -0.07 + float(index) * 0.40), 0.036, "char")
	_box(root, hearth, "BrokenMantelTimber", Vector3(-0.17, 0.87, 0.05), Vector3(0.66, 0.085, 1.47), "wood")


static func _brick_arch(root: Node3D, parent: Node3D, at: Vector3) -> Node3D:
	var arch := _node(parent, "OpenSculleryBrickArch", at, "a2-l3-open-brick-arch")
	# Separate voussoirs leave a real empty opening, not a painted black slab.
	for side: int in [-1, 1]:
		_box(root, arch, "ArchPillar_%s" % side, Vector3(float(side) * 0.65, 0.44, 0.0), Vector3(0.28, 0.88, 0.30), "brick")
	for index: int in range(9):
		var angle: float = PI * (float(index) + 0.5) / 9.0
		var stone := _box(root, arch, "ArchVoussoir_%02d" % index, Vector3(cos(angle) * 0.66, 0.88 + sin(angle) * 0.66, 0.0), Vector3(0.218, 0.27, 0.30), "brick")
		stone.rotation.z = angle - PI * 0.5
	return arch


static func _pot(root: Node3D, parent: Node3D, label: String, at: Vector3, radius: float, height: float, kind: String) -> void:
	var pot := _node(parent, label, at, "a2-l3-house-pottery")
	_cylinder(root, pot, "OpenPotBody", Vector3.ZERO, radius * 0.76, radius, height, kind, 10, false)
	_ring(root, pot, "WornPotLip", Vector3(0.0, height * 0.49, 0.0), radius * 0.83, radius * 1.03, kind)
	_cylinder(root, pot, "EmptyPotDarkInside", Vector3(0.0, height * 0.26, 0.0), radius * 0.80, radius * 0.80, 0.015, "cavity", 10)
	if kind == "char":
		for side: int in [-1, 1]:
			var handle: MeshInstance3D = _ring(root, pot, "StewPotHandle_%s" % side, Vector3(float(side) * radius, 0.02, 0.0), radius * 0.22, radius * 0.40, "metal")
			handle.rotation.z = PI * 0.5


static func _plate(root: Node3D, parent: Node3D, label: String, at: Vector3, radius: float) -> void:
	var plate := _node(parent, label, at, "a2-l3-house-plate")
	_cylinder(root, plate, "PlateShallowDish", Vector3.ZERO, radius * 0.76, radius * 0.88, 0.025, "ceramic", 12)
	_ring(root, plate, "DishRim", Vector3(0.0, 0.015, 0.0), radius * 0.79, radius, "ceramic")


static func _work_apron(root: Node3D) -> void:
	for side: int in [-1, 1]:
		var store := _node(root, "OutboardIndustrialStore_%s" % side, Vector3(float(side) * 4.58, 0.0, -27.2), "a2-l3-industrial-rods-plates")
		for index: int in range(4):
			var plate := _box(root, store, "StackedOxidisedPlate_%s" % index, Vector3(0.0, 0.055 + float(index) * 0.065, float(index % 2) * 0.08), Vector3(1.18, 0.045, 1.06), "metal")
			plate.rotation.y = float(side) * 0.055 * float(index)
			for rivet: int in range(3):
				_box(root, store, "PlateFastener_%s_%s" % [index, rivet], Vector3(-0.43 + float(rivet) * 0.42, 0.090 + float(index) * 0.065, -0.34 + float(index % 2) * 0.08), Vector3(0.028, 0.017, 0.028), "fastener")
		for index: int in range(5):
			_rod(root, store, "LooseIndustrialRod_%s" % index, Vector3(-0.53, 0.075 + float(index % 2) * 0.065, 1.13 + float(index) * 0.10), Vector3(0.55, 0.075 + float(index % 2) * 0.065, 1.31 + float(index) * 0.10), 0.034, "rim")
		var panel := _node(root, "RivetedCylinderPanel_%s" % side, Vector3(float(side) * 4.43, 0.0, -20.9), "a2-l3-detached-cylinder-panel")
		var shell := _box(root, panel, "OxidisedPanelFace", Vector3(0.0, 0.36, 0.0), Vector3(0.83, 0.66, 0.075), "metal")
		shell.rotation.x = -0.22
		for edge: int in [-1, 1]:
			_box(root, panel, "PanelRaisedSeam_%s" % edge, Vector3(float(edge) * 0.36, 0.36, 0.03), Vector3(0.05, 0.68, 0.04), "rim")
			for index: int in range(4):
				_box(root, panel, "PanelRivet_%s_%s" % [edge, index], Vector3(float(edge) * 0.36, 0.095 + float(index) * 0.18, 0.058), Vector3(0.033, 0.033, 0.018), "fastener")
		var timber := _node(root, "BrokenApronTimber_%s" % side, Vector3(float(side) * 4.05, 0.0, -34.2), "a2-l3-charred-timber")
		_rod(root, timber, "FallenCharredBeam", Vector3(-0.14, 0.10, -0.85), Vector3(0.15, 0.10, 0.85), 0.080, "char")
		_rod(root, timber, "JaggedTimberBranch", Vector3(0.03, 0.15, -0.08), Vector3(0.27, 0.30, 0.29), 0.034, "char")


static func _excavation(root: Node3D) -> void:
	# Cosmetic earthwork only: every rim/bed is outside X3.65 or behind Z-42.
	for side: int in [-1, 1]:
		var x: float = float(side) * 5.95
		_surface(root, "OutboardExcavationAsh_%s" % side, Vector3(x, -0.015, -31.0), Vector2(3.8, 6.8), "excavation")
		_surface(root, "OutboardDarkWorkBed_%s" % side, Vector3(x, -0.011, -31.0), Vector2(2.8, 4.8), "scorch")
		for index: int in range(5):
			var clod := _box(root, root, "OutboardAshBerm_%s_%s" % [side, index], Vector3(float(side) * 4.04, 0.09, -28.7 - float(index) * 1.05), Vector3(0.43, 0.18, 0.84), "excavation")
			clod.rotation.y = float(side) * 0.055 * float(index % 3)
	var rear := _node(root, "DistantIndustrialExcavation", Vector3(-4.9, 0.0, -44.3), "a2-l3-distant-excavation")
	var shell: MeshInstance3D = _cylinder(root, rear, "DistantRivetedCylinderShell", Vector3(0.0, 0.40, 0.0), 0.65, 0.65, 2.9, "metal", 14, false)
	shell.rotation.z = PI * 0.5
	for index: int in range(4):
		var ring: MeshInstance3D = _ring(root, rear, "DistantCylinderRing_%s" % index, Vector3(-1.23 + float(index) * 0.82, 0.40, 0.0), 0.62, 0.69, "rim")
		ring.rotation.z = PI * 0.5
		for rivet: int in range(8):
			var angle: float = TAU * float(rivet) / 8.0
			_box(root, rear, "DistantCylinderRivet_%s_%s" % [index, rivet], Vector3(-1.23 + float(index) * 0.82, 0.40 + cos(angle) * 0.66, sin(angle) * 0.66), Vector3(0.034, 0.034, 0.034), "fastener")
	_surface(root, "RearScenicAshFoundation", Vector3(0.0, -0.005, -45.7), Vector2(13.0, 5.8), "excavation")


static func _work_tableau(root: Node3D) -> Node3D:
	var work := _node(root, "HarmlessWorkTableau", WORK_ANCHOR, "a2-l3-rods-plates-tableau")
	work.set_meta("collision_role", "none; harmless outboard manipulation")
	work.set_meta("clock_owner", "level supplies normalized progress; no local clock")
	_box(root, work, "LowWorkStand", Vector3(-0.19, 0.13, -0.20), Vector3(0.77, 0.26, 0.67), "metal")
	for side: int in [-1, 1]:
		_box(root, work, "WorkStandFoot_%s" % side, Vector3(float(side) * 0.34 - 0.19, 0.035, -0.20), Vector3(0.12, 0.07, 0.89), "char")
		_box(root, work, "WorkStandUpright_%s" % side, Vector3(-0.24, 0.44, -0.16 + float(side) * 0.11), Vector3(0.085, 0.52, 0.07), "rim")
	var journal: MeshInstance3D = _cylinder(root, work, "FixedRoundJournal", Vector3(-0.24, 0.65, -0.16), 0.14, 0.14, 0.27, "rim", 10)
	journal.rotation.x = PI * 0.5
	_cylinder(root, work, "MovingRoundJournal", Vector3.ZERO, 0.085, 0.085, 0.17, "rim", 10)
	_cylinder(root, work, "UpperWorkRod", Vector3.ZERO, 0.051, 0.042, 1.0, "metal", 8)
	_cylinder(root, work, "LowerWorkRod", Vector3.ZERO, 0.042, 0.035, 1.0, "rim", 8)
	var clamp := _node(work, "PlateClamp", Vector3.ZERO, "a2-l3-harmless-plate-clamp")
	_box(root, clamp, "ClampCrosspiece", Vector3.ZERO, Vector3(0.33, 0.045, 0.13), "metal")
	for side: int in [-1, 1]:
		_box(root, clamp, "ClampFinger_%s" % side, Vector3.ZERO, Vector3(0.045, 0.19, 0.13), "rim")
	_box(root, work, "TransferredPlate", Vector3.ZERO, Vector3(0.62, 0.045, 0.57), "metal")
	for index: int in range(3):
		_rod(root, work, "StationarySupplyRod_%s" % index, Vector3(0.39, 0.065, -0.52 + float(index) * 0.10), Vector3(0.64, 0.065, 0.55 + float(index) * 0.10), 0.025, "rim")
	return work


static func _node(parent: Node3D, label: String, at: Vector3, asset_id: String) -> Node3D:
	var node := Node3D.new()
	node.name = label
	node.position = at
	node.set_meta("asset_id", asset_id)
	node.set_meta("scenery_only", true)
	parent.add_child(node)
	return node


static func _box(root: Node3D, parent: Node3D, label: String, at: Vector3, size: Vector3, kind: String) -> MeshInstance3D:
	var mesh: MeshInstance3D = Heath._box(parent, label, at, size, _material(kind).duplicate() as StandardMaterial3D)
	_optional_cutaway(root, mesh)
	return mesh


static func _cylinder(root: Node3D, parent: Node3D, label: String, at: Vector3, bottom: float, top: float, height: float, kind: String, segments: int = 12, cap_top: bool = true) -> MeshInstance3D:
	var mesh: MeshInstance3D = Heath._cylinder(parent, label, at, bottom, top, height, _material(kind).duplicate() as StandardMaterial3D, segments, cap_top)
	_optional_cutaway(root, mesh)
	return mesh


static func _ring(root: Node3D, parent: Node3D, label: String, at: Vector3, inner: float, outer: float, kind: String) -> MeshInstance3D:
	var mesh: MeshInstance3D = Heath._torus(parent, label, at, inner, outer, _material(kind).duplicate() as StandardMaterial3D)
	_optional_cutaway(root, mesh)
	return mesh


static func _rod(root: Node3D, parent: Node3D, label: String, start: Vector3, finish: Vector3, radius: float, kind: String) -> MeshInstance3D:
	var mesh: MeshInstance3D = _cylinder(root, parent, label, Vector3.ZERO, radius, radius * 0.76, 1.0, kind, 8)
	_fit_segment(mesh, start, finish)
	return mesh


static func _fit_segment(mesh: MeshInstance3D, start: Vector3, finish: Vector3) -> void:
	var delta: Vector3 = finish - start
	mesh.position = (start + finish) * 0.5
	mesh.scale = Vector3(1.0, maxf(delta.length(), 0.0001), 1.0)
	mesh.quaternion = Quaternion(Vector3.UP, delta.normalized()) if delta.length_squared() > 0.00000001 else Quaternion.IDENTITY


static func _optional_cutaway(root: Node3D, mesh: MeshInstance3D) -> void:
	# Material overrides above are unique for each instance; the root derives
	# temporary alpha from actual camera/protected points, never a saved bit.
	mesh.set_meta("weybridge_cutaway_candidate", true)
	var paths: Array = root.get_meta("optional_cutaway_paths", [])
	paths.append(str(root.get_path_to(mesh)))
	root.set_meta("optional_cutaway_paths", paths)


static func _surface(parent: Node3D, label: String, at: Vector3, size: Vector2, kind: String) -> void:
	var mesh: MeshInstance3D = Heath._plane(parent, label, at, size, "sand_clear")
	var material: StandardMaterial3D = _material(kind).duplicate() as StandardMaterial3D
	material.uv1_scale = Vector3(size.x / TILE_WORLD_SIZE, size.y / TILE_WORLD_SIZE, 1.0)
	mesh.material_override = material


static func _material(kind: String) -> StandardMaterial3D:
	if kind in ["paving", "earth"]:
		return Weybridge._surface_material(kind)
	if kind not in ["ash_floor", "floor_timber", "plaster", "ceramic", "pottery"]:
		return Heath._material(kind)
	var cached := _material_cache.get(kind) as StandardMaterial3D
	if cached != null:
		return cached
	var palette: Array[Color] = []
	match kind:
		"ash_floor": palette = [Color("a89b85"), Color("9d9381"), Color("b5a993"), Color("897f70")]
		"floor_timber": palette = [Color("82715a"), Color("74644f"), Color("94816a"), Color("605646")]
		"plaster": palette = [Color("b4a58c"), Color("a09580"), Color("c1b29a"), Color("785440")]
		"ceramic": palette = [Color("bdb49d"), Color("a49f8c"), Color("ccc2aa"), Color("777768")]
		"pottery": palette = [Color("8f6850"), Color("765743"), Color("a27a5b"), Color("5e4b3d")]
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y: int in range(64):
		for x: int in range(64):
			var cluster: int = posmod((x >> 2) * 17 + (y >> 2) * 31 + kind.length() * 7, 29)
			var detail: int = posmod(x * 37 + y * 73 + x * y * 13, 997)
			var index: int = 1 if cluster < 3 else (2 if cluster == 8 else 0)
			match kind:
				"floor_timber":
					if x % 16 == 0 or (y % 32 == 0 and (x >> 4) % 2 == 0):
						index = 3
					elif x % 7 == 0 and detail < 340:
						index = 1
				"plaster":
					if cluster > 25 or (x % 16 == 0 and detail < 70):
						index = 3
				"ceramic":
					index = 1 if cluster > 25 else (2 if cluster < 2 else 0)
					if detail < 10:
						index = 3
				"pottery":
					if y % 24 == 0 and detail < 250:
						index = 3
				_:
					if detail < 7:
						index = 3
			image.set_pixel(x, y, palette[index])
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 0.94
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material_cache[kind] = material
	return material
