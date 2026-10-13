extends RefCounted
## TMP original G09/G20 London/coda composition using existing Act 2 families.
## Static opaque scenery and stage-derived tableaux; no colliders, targets,
## pickups, clocks, cue imitation or ecology damage. Host owns dry floor.
const London: Script = preload("res://scripts/acts/act2/london_approaches_kit.gd")
const Heath: Script = preload("res://scripts/acts/act2/heath_kit.gd")
const Weybridge: Script = preload("res://scripts/acts/act2/weybridge_kit.gd")
const House: Script = preload("res://scripts/acts/act2/ruined_house_kit.gd")
const Weed: Script = preload("res://scripts/acts/act2/red_weed_visual.gd")
const Handler: Script = preload("res://scripts/acts/act2/salvage_handler_visual.gd")
const Tripod: Script = preload("res://scripts/acts/act2/dead_london_sentry_visual.gd")
const ART_REVISION: String = "a2-dead-london-tmp-production-1"
const QUIET_SURFACES: Array[Dictionary] = [
	{"id": "FirstEmptySquare", "at": Vector3(0, 0.008, -2.1), "size": Vector2(6.8, 11.4), "kind": "paving"},
	{"id": "SecondEmptySquare", "at": Vector3(0, 0.009, -11.45), "size": Vector2(6.8, 7.3), "kind": "paving"},
	{"id": "ParkApproach", "at": Vector3(0, 0.008, -19.65), "size": Vector2(6.8, 9.1), "kind": "earth"},
	{"id": "LocalSentryCourt", "at": Vector3(0, 0.009, -29.1), "size": Vector2(6.8, 9.8), "kind": "paving"},
	{"id": "QuietRedoubt", "at": Vector3(0, 0.008, -38.7), "size": Vector2(6.8, 9.4), "kind": "earth"},
	{"id": "DawnDeparture", "at": Vector3(0, 0.009, -45.2), "size": Vector2(6.8, 3.8), "kind": "road"},
]

static func build(parent: Node3D) -> Dictionary:
	var root := Node3D.new()
	root.name = "DeadLondonScenery"
	root.set_meta("art_revision", ART_REVISION)
	root.set_meta("source_ids", ["G09", "G11", "G20", "S03", "G04"])
	root.set_meta("readiness", "original TMP authored geometry, unrendered")
	root.set_meta("scenery_only", true)
	root.set_meta("optional_cutaway_paths", [])
	parent.add_child(root)
	London._surface(root, "ContinuousDryAshRoad", Vector3(0, 0.005, -21.7), Vector2(6.8, 50.2), "road")
	for spec: Dictionary in QUIET_SURFACES:
		London._surface(root, String(spec.id), spec.at, spec.size, String(spec.kind))
	for side: int in [-1, 1]:
		London._surface(root, "OutboardAsh_%s" % side, Vector3(float(side) * 5.25, -0.01, -21.7), Vector2(3.2, 50.2), "earth")
		_box(root, "ContinuousLowCurb_%s" % side, Vector3(float(side) * 3.55, 0.055, -21.7), Vector3(0.22, 0.11, 50.2), "stone")
	_empty_squares(root)
	_park_edge(root)
	_sentry_court(root)
	var redoubt: Dictionary = _redoubt(root)
	_collect_optional(root, root)
	var result: Dictionary = {"root": root, "survivor": redoubt.survivor, "inert_machines": redoubt.inert_machines, "wreck": redoubt.wreck, "corpse_piles": redoubt.corpse_piles}
	project_stage(result, 0)
	return result

static func project_stage(kit: Dictionary, stage: int) -> void:
	## Derived only from host's actual saved progression. No hidden clock, wait,
	## movement/timer, pickup or new enemy; dead machinery already remains inert.
	var root: Variant = kit.get("root")
	if is_instance_valid(root): root.set_meta("derived_stage", stage)
	var survivor: Variant = kit.get("survivor")
	if not is_instance_valid(survivor): return
	survivor.visible = stage >= 9
	var sprite: Sprite3D = survivor.get_node_or_null("FeetAnchoredCostume") as Sprite3D
	if is_instance_valid(sprite): sprite.texture = Heath._witness_texture(2, "turn" if stage >= 10 else "watch")
	survivor.set_meta("witness_pose", "turn" if stage >= 10 else "watch")

static func _empty_squares(root: Node3D) -> void:
	for side: int in [-1, 1]:
		for row: int in range(3):
			var at: Vector3 = Vector3(float(side) * 4.55, 0, -0.5 - float(row) * 4.75)
			London._villa(root, at, side, row == 2 and side < 0, "DesertedLondonFacade_%s_%s" % [side, row])
			var shop := _node(root, "ClosedShop_%s_%s" % [side, row], at)
			shop.rotation.y = -float(side) * PI / 6.0
			shop.scale = Vector3(0.65, 1, 0.65)
			_box(shop, "DarkDisplay", Vector3(0, 0.62, 0.385), Vector3(0.48, 0.75, 0.045), "window")
			for plank: int in range(3):
				_box(shop, "ShutterBoard", Vector3(0, 0.39 + float(plank) * 0.23, 0.425), Vector3(0.50, 0.07, 0.035), "wood")
			_box(shop, "UnlitShopSign", Vector3(0, 1.54, 0.44), Vector3(1.10, 0.24, 0.09), "ash_wood")
		London._lamp(root, Vector3(float(side) * 3.95, 0, -4.2), "UnlitSquareLamp_%s" % side)
		London._iron_fence(root, root, Vector3(float(side) * 3.98, 0, -9.2), 2.8, "DesertedSquareRail_%s" % side)
		for index: int in range(3):
			var weed: Node3D = London._weed(root, root, "PaleFacadeVerge_%s_%s" % [side, index], Vector3(float(side) * 4.15, 0, -2.3 - float(index) * 4.5), "bleached", index + 3)
			London._portrait_weed_transform(weed, side, Vector3(0.65, 0.72, 0.65))
	# Paper is a flat low-value cluster, not a collectible or floor warning.
	var paper: StandardMaterial3D = _plain(Color("a69f8c"))
	for index: int in range(12):
		var x: float = -2.3 + float((index * 7) % 11) * 0.42
		var page: MeshInstance3D = Heath._plane(root, "StillNewspaper_%s" % index, Vector3(x, 0.012, -1.7 - float(index) * 0.98), Vector2(0.20, 0.27), "ash_wood")
		page.material_override = paper
		page.rotation.y = float(index % 5 - 2) * 0.28
		_box(root, "BlackDustCluster_%s" % index, Vector3(float(index % 2 * 2 - 1) * 2.68, 0.013, -0.7 - float(index) * 1.15), Vector3(0.42, 0.006, 0.25), "char")
	Weybridge._cart(root, Vector3(4.75, 0, -6.5))
	var omnibus := _node(root, "OverturnedOmnibusScenery", Vector3(-4.8, 0.40, -12.8))
	omnibus.rotation.z = -0.24
	_box(omnibus, "AbandonedCarriageBody", Vector3.ZERO, Vector3(1.0, 0.74, 2.15), "wood")
	_box(omnibus, "SplitCarriageRoof", Vector3(0, 0.42, 0), Vector3(1.12, 0.10, 2.26), "slate")
	for side: float in [-1.0, 1.0]:
		for z: float in [-0.72, 0.72]: Weybridge._spoked_wheel(omnibus, Vector3(side * 0.57, -0.30, z), 0.30, "StillOmnibusWheel")
		for z: float in [-0.66, 0, 0.66]: _box(omnibus, "DarkCarriageWindow", Vector3(side * 0.505, 0.15, z), Vector3(0.025, 0.25, 0.36), "window")

static func _park_edge(root: Node3D) -> void:
	for side: int in [-1, 1]:
		var x: float = float(side) * 3.93
		_box(root, "ParkGatePier_%s" % side, Vector3(x, 0.85, -15.6), Vector3(0.45, 1.7, 0.50), "stone")
		_box(root, "ParkPierCap_%s" % side, Vector3(x, 1.77, -15.6), Vector3(0.58, 0.12, 0.62), "stone")
		London._iron_fence(root, root, Vector3(x, 0, -18.5), 4.8, "DryParkBoundary_%s" % side)
		London._lamp(root, Vector3(x, 0, -23.8), "SilentParkLamp_%s" % side)
		for row: int in range(2):
			var tree := _node(root, "BareParkTree_%s_%s" % [side, row], Vector3(float(side) * 4.8, 0, -18.0 - float(row) * 5.7))
			_rod(tree, "BareTrunk", Vector3.ZERO, Vector3(0.08, 2.4, 0), 0.13, "bark")
			for branch: int in range(3):
				var hand: float = float(branch % 2 * 2 - 1)
				_rod(tree, "StillBough", Vector3(0.04, 1.2 + float(branch) * 0.32, 0), Vector3(hand * 0.72, 2.3 + float(branch) * 0.19, float(branch - 1) * 0.28), 0.045, "char")
			London._weed(root, root, "BleachedParkFronds_%s_%s" % [side, row], Vector3(float(side) * 4.15, 0, -17.3 - float(row) * 5.8), "bleached", row + 1)
	# Ordinary canisters are inert dressing; no Tender actor or shell pickup.
	for index: int in range(3):
		var at: Vector3 = Vector3(4.08 + float(index % 2) * 0.25, 0.20, -20.5 - float(index) * 0.34)
		Heath._cylinder(root, "AbandonedCanister_%s" % index, at, 0.115, 0.115, 0.38, Heath._material("metal"), 10)
		Heath._cylinder(root, "InertCanisterCap_%s" % index, at + Vector3.UP * 0.21, 0.125, 0.125, 0.04, Heath._material("rim"), 10)

static func _sentry_court(root: Node3D) -> void:
	for side: int in [-1, 1]:
		var x: float = float(side) * 4.13
		for row: int in range(3):
			_box(root, "OutboardRubbleWall_%s_%s" % [side, row], Vector3(x, 0.27 + float(row % 2) * 0.08, -26.4 - float(row) * 2.3), Vector3(0.70, 0.54 + float(row % 2) * 0.16, 1.65), "brick")
			_box(root, "BrokenCoping_%s_%s" % [side, row], Vector3(x, 0.57 + float(row % 2) * 0.16, -26.4 - float(row) * 2.3), Vector3(0.76, 0.07, 1.4), "stone")
			London._weed(root, root, "CourtPaleWeed_%s_%s" % [side, row], Vector3(float(side) * 4.20, 0, -27.1 - float(row) * 2.2), "bleached", row + 4)
	# Source low joint and native gate props belong to host, not this scenery.

static func _redoubt(root: Node3D) -> Dictionary:
	var wreck: Node3D = Handler.new() as Node3D
	wreck.name = "FiveLeggedWreckScenery"
	wreck.position = Vector3(4.65, 0, -21.1)
	root.add_child(wreck)
	wreck.call("pose", "defeated", 1.0, Vector3.BACK, false)
	wreck.set_meta("scenery_only", true)
	var corpses: Array[Node3D] = []
	for index: int in range(2): corpses.append(_dead_martian(root, Vector3(float(index % 2 * 2 - 1) * 4.22, 0, -35.4 - float(index) * 1.4), index))
	var machines: Array[Node3D] = []
	for index: int in range(2):
		var inert: Node3D = Tripod.new() as Node3D
		inert.name = "InertThreeLegMachine_%s" % index
		inert.position = Vector3(float(index % 2 * 2 - 1) * 5.42, 0, -38.7 - float(index) * 1.8)
		inert.scale = Vector3.ONE * 0.65
		root.add_child(inert)
		inert.call("set_brace_pose", 2, "spent")
		inert.call("pose", "defeated", 1.0, Vector3.BACK, false)
		inert.set_meta("scenery_only", true)
		machines.append(inert)
		for bird: int in range(2): _bird(inert, Vector3(-0.4 + float(bird) * 0.75, 2.10, -1.12), "PerchedBird_%s" % bird)
	for side: int in [-1, 1]:
		London._villa(root, Vector3(float(side) * 4.6, 0, -43.0), side, true, "DawnRuinFacade_%s" % side)
		for index: int in range(3):
			var tuft := _node(root, "SmallReturningShoot_%s_%s" % [side, index], Vector3(float(side) * 3.98, 0, -42.2 - float(index) * 0.45))
			var plant: StandardMaterial3D = _plain(Color("65705a"))
			var stalk: MeshInstance3D = Heath._box(tuft, "QuietNewStem", Vector3(0, 0.12, 0), Vector3(0.025, 0.24, 0.025), plant)
			stalk.rotation.z = float(side) * 0.12
			var leaf: MeshInstance3D = Heath._box(tuft, "QuietLeaf", Vector3(0.07, 0.16, 0), Vector3(0.13, 0.045, 0.07), plant)
			leaf.rotation.z = 0.25
	var survivor: Node3D = Heath._witness(root, Vector3(3.93, 0.025, -43.15), 2, 1)
	survivor.name = "QuietSurvivor"
	return {"wreck": wreck, "inert_machines": machines, "corpse_piles": corpses, "survivor": survivor}

static func _dead_martian(root: Node3D, at: Vector3, variant: int) -> Node3D:
	## G04 round/tentacled anatomy. No humanoid torso/legs, enemy faction, blood
	## effect or pickup. Sixteen still tentacles in two bunches of eight.
	var corpse := _node(root, "DeadRoundMartian_%s" % variant, at)
	corpse.rotation.y = 0.4 if variant == 0 else -0.4
	var skin: StandardMaterial3D = _plain(Color("6a6256"))
	var body: MeshInstance3D = Heath._sphere(corpse, "SaggingRoundBody", Vector3(0, 0.27, 0), skin)
	body.scale = Vector3(1.16, 0.64, 1.0)
	for side: float in [-1.0, 1.0]:
		var eye: MeshInstance3D = Heath._sphere(corpse, "DarkStillEye", Vector3(side * 0.22, 0.33, 0.39), Heath._material("cavity"))
		eye.scale = Vector3(0.18, 0.12, 0.10)
		for finger: int in range(8):
			var z: float = 0.50 + float(finger % 4) * 0.14
			var x: float = side * (0.19 + float(finger) * 0.065)
			var joint: Vector3 = Vector3(x, 0.09, z)
			_rod(corpse, "StillTentacleRoot", Vector3(side * 0.12, 0.24, 0.37), joint, 0.022, "ash_wood")
			_rod(corpse, "StillTentacleTip", joint, Vector3(side * (0.32 + float(finger) * 0.09), 0.025, z + 0.25), 0.017, "ash_wood")
	corpse.set_meta("scenery_only", true)
	corpse.set_meta("source_ids", ["G04", "G09", "T21"])
	corpse.set_meta("microbial_coda", true)
	return corpse

static func _bird(parent: Node3D, at: Vector3, label: String) -> Node3D:
	var bird := _node(parent, label, at)
	_box(bird, "StillBlackBody", Vector3(0, 0.07, 0), Vector3(0.16, 0.13, 0.10), "char")
	_box(bird, "SmallHead", Vector3(0, 0.17, 0.055), Vector3(0.09, 0.09, 0.08), "char")
	_box(bird, "FoldedWing", Vector3(0.035, 0.055, -0.035), Vector3(0.055, 0.12, 0.15), "cavity")
	_box(bird, "RestrainedBeak", Vector3(0, 0.16, 0.108), Vector3(0.027, 0.025, 0.05), "ash_wood")
	return bird

static func _node(parent: Node3D, label: String, at: Vector3) -> Node3D:
	return London._node(parent, label, at)

static func _box(parent: Node3D, label: String, at: Vector3, size: Vector3, kind: String) -> MeshInstance3D:
	return Heath._box(parent, label, at, size, House._material(kind))

static func _rod(parent: Node3D, label: String, start: Vector3, finish: Vector3, radius: float, kind: String) -> void:
	var delta: Vector3 = finish - start
	var segment: MeshInstance3D = Heath._cylinder(parent, label, (start + finish) * 0.5, radius, radius * 0.70, delta.length(), House._material(kind), 6)
	segment.quaternion = Quaternion(Vector3.UP, delta.normalized())

static func _plain(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.96
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return material

static func _collect_optional(root: Node3D, node: Node) -> void:
	# Native rigs own their material/cutaway machinery, including palette surfaces.
	# Do not route a null multi-surface mirror override through the prop helper.
	if node is MeshInstance3D and not node.mesh is PlaneMesh and node.material_override is StandardMaterial3D:
		London._mark_cutaway(root, node)
	for child: Node in node.get_children():
		if child is Node3D and child.get_script() in [Handler, Tripod]: continue
		_collect_optional(root, child)
