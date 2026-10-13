extends RefCounted
## Original compact A2-O3 composition of accepted L4 scenery leaves.
## Quiet signs and the mooring prop are decorative; the host owns all authority.
## Collision, contacts, cues, progression, actor state and clocks are not in this kit.

const London = preload("res://scripts/acts/act2/london_approaches_kit.gd")
const Heath = preload("res://scripts/acts/act2/heath_kit.gd")
const House = preload("res://scripts/acts/act2/ruined_house_kit.gd")
const ART_REVISION := "a2-bleached-canal-1"
const FLOOR_RECT := Rect2(-3.4, -27.0, 6.8, 30.6)
const SPAWN := Vector3(0.0, 0.1, 2.6)
const EXIT_POSITION := Vector3(0.0, 0.0, -26.0)
const WALL_POSITION := Vector3(-1.1, 0.225, -10.0)
const WALL_SIZE := Vector3(1.5, 0.45, 0.45)
const CANAL_PROP_POSITION := Vector3(4.18, 0.0, -15.8)
const SIGN_IDS: Array[String] = ["first", "second", "third"]
const SIGN_POSITIONS: Array[Vector3] = [
	Vector3(-3.88, 0.0, 0.6), Vector3(3.88, 0.0, -7.0),
	Vector3(-3.88, 0.0, -18.1),
]
const COURT_RECTS: Array[Rect2] = [
	Rect2(-3.4, -5.8, 6.8, 9.4), Rect2(-3.4, -15.2, 6.8, 7.2),
	Rect2(-3.4, -25.1, 6.8, 5.9),
]
const COURT_KINDS: Array[String] = ["earth", "paving", "earth"]

static func build(parent: Node3D) -> Dictionary:
	assert(is_instance_valid(parent) and not parent.is_queued_for_deletion(), "Bleached Canal scenery needs an intact host")
	var root := Node3D.new()
	root.name = "BleachedCanalKit"
	root.set_meta("art_revision", ART_REVISION)
	root.set_meta("source_ids", ["G08", "G16", "G17", "T19", "T20", "E22", "E23", "E25"])
	root.set_meta("scenery_only", true)
	root.set_meta("grounded_feet_pivot", Vector3.ZERO)
	root.set_meta("native_scale", Vector3.ONE)
	root.set_meta("collision_role", "none; host-authored dry floor, boundaries and one wall")
	root.set_meta("optional_cutaway_paths", [])
	root.set_meta("provisional_floor_rect", FLOOR_RECT)
	root.set_meta("provisional_wall_position", WALL_POSITION)
	root.set_meta("provisional_wall_size", WALL_SIZE)
	parent.add_child(root)
	_ground(root)
	_low_wall(root)
	_margins(root)
	var signs: Dictionary = {}
	for index: int in range(SIGN_IDS.size()):
		signs[SIGN_IDS[index]] = _route_sign(root, SIGN_IDS[index], SIGN_POSITIONS[index], index + 1)
	var canal_prop: Node3D = _mooring(root)
	return {"root": root, "signs": signs, "canal_prop": canal_prop}

static func _ground(root: Node3D) -> void:
	London._surface(root, "ContinuousDryRoad", Vector3(0.0, 0.005, -11.7), FLOOR_RECT.size, "road")
	for index: int in range(COURT_RECTS.size()):
		var rect: Rect2 = COURT_RECTS[index]
		London._surface(root, "Court_%s_QuietFloor" % SIGN_IDS[index], Vector3(rect.get_center().x, 0.008, rect.get_center().y), rect.size, COURT_KINDS[index])
	# Low margins and quiet backdrops are visual only, never support bindings.
	for side: int in [-1, 1]:
		London._surface(root, "OutboardEarthBank_%s" % side, Vector3(float(side) * 3.86, -0.015, -11.7), Vector2(0.92, 30.6), "earth")
		London._surface(root, "QuietCanalWater_%s" % side, Vector3(float(side) * 5.62, -0.12, -13.9), Vector2(2.6, 22.8), "water")
		London._surface(root, "DryEdgeStone_%s" % side, Vector3(float(side) * 3.48, 0.012, -11.7), Vector2(0.16, 30.6), "stone")
	London._surface(root, "ArrivalQuietBackdrop", Vector3(0.0, -0.03, 7.8), Vector2(13.84, 8.4), "earth")
	London._surface(root, "DepartureQuietBackdrop", Vector3(0.0, -0.03, -31.2), Vector2(13.84, 8.4), "earth")

static func _low_wall(root: Node3D) -> void:
	var wall: Node3D = London._node(root, "ReusedLowVillaWall", Vector3.ZERO)
	wall.set_meta("collision_role", "visual match only; host owns the fixed BoxShape3D")
	London._box(root, wall, "LowWallBody", WALL_POSITION, WALL_SIZE, "brick")
	London._box(root, wall, "LowWallCoping", Vector3(-1.1, 0.415, -10.0), Vector3(1.5, 0.07, 0.45), "stone")
	# This exact opaque footprint survives the host's derived body cutaway.
	# It is brick floor scenery, with no threat outline or interaction grammar.
	London._surface(wall, "PersistentBrickFootprint", Vector3(-1.1, 0.013, -10.0), Vector2(1.5, 0.45), "brick")
	wall.set_meta("persistent_footprint_rect", Rect2(-1.85, -10.225, 1.5, 0.45))

static func _margins(root: Node3D) -> void:
	var margins: Node3D = London._node(root, "CanalMargins", Vector3.ZERO)
	for side: int in [-1, 1]:
		var sign_side: float = float(side)
		London._villa(root, Vector3(sign_side * 4.50, 0.0, -2.0), side, side > 0, "ArrivalVilla_%s" % side)
		London._villa(root, Vector3(sign_side * 4.50, 0.0, -11.2), side, false, "MiddleVilla_%s" % side)
		London._villa(root, Vector3(sign_side * 4.50, 0.0, -22.1), side, true, "QuietRuinVilla_%s" % side)
		for index: int in range(3):
			var z: float = -3.6 - float(index) * 8.4
			var pale: Node3D = London._weed(root, margins, "BleachedBank_%s_%s" % [side, index], Vector3(sign_side * 4.10, 0.0, z), "bleached", index + 3)
			London._portrait_weed_transform(pale, side, Vector3(0.8, 1.0, 0.8))
		var sparse: Node3D = London._weed(root, margins, "SparseLivingBank_%s" % side, Vector3(sign_side * 4.25, 0.0, -6.1), "sparse", 1)
		London._portrait_weed_transform(sparse, side)
		var dense: Node3D = London._weed(root, margins, "WaterFrond_%s" % side, Vector3(sign_side * 4.25, 0.0, -16.0), "dense", 6)
		London._portrait_weed_transform(dense, side, Vector3(0.8, 1.0, 0.8))
		London._iron_fence(root, margins, Vector3(sign_side * 4.0, 0.0, -14.0), 2.7, "QuietIronRail_%s" % side)
		London._lamp(root, Vector3(sign_side * 3.98, 0.0, -8.2), "UnlitCanalLamp_%s" % side)
		London._lamp(root, Vector3(sign_side * 3.98, 0.0, -24.1), "UnlitExitVergeLamp_%s" % side)

static func _route_sign(root: Node3D, sign_id: String, at: Vector3, number: int) -> Node3D:
	var sign: Node3D = London._node(root, "QuietRouteSign_%s" % sign_id, at)
	sign.set_meta("asset_id", "a2-o3-route-sign-" + sign_id)
	sign.set_meta("source_ids", ["G17"])
	sign.set_meta("requirement_level_id", "A2-O3")
	sign.set_meta("scenery_only", true)
	sign.set_meta("grounded_feet_pivot", Vector3.ZERO)
	sign.set_meta("display_state", "static_quiet_route_marker")
	sign.set_meta("collision_role", "none")
	London._box(root, sign, "GroundedTimberPost", Vector3(0.0, 0.53, 0.0), Vector3(0.085, 1.06, 0.085), "wood")
	London._box(root, sign, "WeatheredRouteBoard", Vector3(0.0, 0.91, 0.025), Vector3(0.76, 0.28, 0.07), "ash_wood")
	London._box(root, sign, "DarkBoardBacking", Vector3(0.0, 0.91, 0.064), Vector3(0.57, 0.17, 0.012), "wood")
	# Quiet I/II/III marks distinguish the three route signs. They are not
	# an exit chevron, an available/active/spent cue or a contact objective.
	for index: int in range(number):
		var x: float = (float(index) - float(number - 1) * 0.5) * 0.105
		London._box(root, sign, "PaleRouteNumeral_%s" % index, Vector3(x, 0.91, 0.073), Vector3(0.028, 0.12, 0.014), "ash_wood")
	for x: float in [-0.28, 0.28]:
		London._box(root, sign, "DarkIronFastener_%s" % ("left" if x < 0.0 else "right"), Vector3(x, 0.91, 0.079), Vector3(0.032, 0.032, 0.015), "metal")
	return sign

static func _mooring(root: Node3D) -> Node3D:
	var prop: Node3D = London._node(root, "QuietCanalMooring", CANAL_PROP_POSITION)
	prop.set_meta("asset_id", "a2-o3-canal-mooring")
	prop.set_meta("source_ids", ["G17", "E22"])
	prop.set_meta("requirement_level_id", "A2-O3")
	prop.set_meta("scenery_only", true)
	prop.set_meta("grounded_feet_pivot", Vector3.ZERO)
	prop.set_meta("display_state", "static_quiet_mooring")
	prop.set_meta("collision_role", "none")
	London._box(root, prop, "QuietStoneFooting", Vector3(0.0, 0.055, 0.0), Vector3(0.34, 0.11, 0.34), "stone")
	London._box(root, prop, "ShortWeatheredTimber", Vector3(0.0, 0.30, 0.0), Vector3(0.18, 0.60, 0.18), "wood")
	London._box(root, prop, "DarkIronPostStrap", Vector3(0.0, 0.36, 0.0), Vector3(0.195, 0.045, 0.195), "metal")
	var ring: MeshInstance3D = Heath._torus(prop, "QuietIronMooringRing", Vector3(0.0, 0.36, 0.15), 0.075, 0.12, House._material("metal"))
	ring.rotation.x = PI * 0.5
	London._mark_cutaway(root, ring)
	return prop
