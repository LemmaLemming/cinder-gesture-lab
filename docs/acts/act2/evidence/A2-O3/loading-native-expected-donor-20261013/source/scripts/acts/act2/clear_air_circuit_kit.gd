extends RefCounted
## Compact A2-O2 arrangement of unchanged accepted House/Heath/Weybridge leaves.
## Decorative enemy stores only: no collider, cue, pickup, clock or gameplay state.

const House: Script = preload("res://scripts/acts/act2/ruined_house_kit.gd")
const ART_REVISION := "a2-clear-air-circuit-kit-1"
const FLOOR := Rect2(-3.4, -14.8, 6.8, 18.4)
const CRATE_IDS: Array[String] = ["west_tender", "east_tender"]
const CRATE_POSITIONS := {
	"west_tender": Vector3(-3.85, 0.0, -2.7),
	"east_tender": Vector3(3.85, 0.0, -2.7),
}
const MARKER_POSITION := Vector3(0.9, 0.0, -13.9)


static func build(parent: Node3D) -> Dictionary:
	assert(is_instance_valid(parent), "Clear Air scenery requires a level-owned parent.")
	var root := Node3D.new()
	root.name = "ClearAirCircuitSceneryKit"
	root.set_meta("art_revision", ART_REVISION)
	root.set_meta("source_ids", ["G07", "G16", "G19", "sample-S02"])
	root.set_meta("scenery_only", true)
	root.set_meta("collision_role", "none; host supplies the sole upright Box dry floor")
	root.set_meta("optional_cutaway_paths", [])
	root.set_meta("dry_floor_rect", FLOOR)
	root.set_meta("native_scale", 1.0)
	parent.add_child(root)
	_ground(root)
	_rooms(root)
	_industrial_edges(root)
	var crates: Dictionary = {}
	for id: String in CRATE_IDS:
		crates[id] = _store_crate(root, id, CRATE_POSITIONS[id])
	var marker: Node3D = _circuit_marker(root)
	var kit: Dictionary = {"root": root, "crates": crates, "marker": marker}
	var cleared: Array[String] = []
	set_progress(kit, cleared, false)
	return kit


static func set_progress(kit: Dictionary, cleared_ids: Array[String], completed: bool) -> void:
	# Pure absolute presentation. The host owns accepted defeats and completion.
	var crates: Dictionary = kit.get("crates", {})
	for id: String in CRATE_IDS:
		var raw: Variant = crates.get(id)
		if not is_instance_valid(raw) or not raw is Node3D:
			continue
		var crate: Node3D = raw
		var empty: bool = cleared_ids.has(id)
		var contents := crate.get_node_or_null("FullCanisters") as Node3D
		if is_instance_valid(contents):
			contents.visible = not empty
		crate.set_meta("store_state", "empty" if empty else "full")
	var raw_marker: Variant = kit.get("marker")
	if is_instance_valid(raw_marker) and raw_marker is Node3D:
		var marker: Node3D = raw_marker
		marker.visible = completed
		marker.set_meta("marker_state", "completed" if completed else "hidden")


static func _ground(root: Node3D) -> void:
	# Joined material bands cover exactly the one dry support, without cutaway.
	House._surface(root, "ContinuousPaleAshFoundation", Vector3(0.0, 0.004, -5.6), Vector2(6.8, 18.4), "ash_floor")
	House._surface(root, "ArrivalWornHouseFloor", Vector3(0.0, 0.006, 0.1), Vector2(6.8, 7.0), "floor_timber")
	House._surface(root, "ClearAirWorkApron", Vector3(0.0, 0.006, -7.4), Vector2(6.8, 8.0), "paving")
	House._surface(root, "QuietExitAshFloor", Vector3(0.0, 0.006, -13.1), Vector2(6.8, 3.4), "ash_floor")
	# Lower scenic earth prevents a portrait void; it is not playable support.
	House._surface(root, "ScenicUnderlyingEarth", Vector3(0.0, -0.16, -5.6), Vector2(20.0, 36.0), "earth")
	for side: int in [-1, 1]:
		House._surface(root, "OutboardHouseFoundation_%s" % side, Vector3(float(side) * 4.4, 0.001, -5.6), Vector2(2.0, 18.4), "ash_floor")
		for index: int in range(7):
			# Low persistent floor-edge masonry: not a wall or required blocker.
			var edge: MeshInstance3D = House._box(root, root, "OutboardEdgeStone_%s_%s" % [side, index], Vector3(float(side) * 3.52, 0.035, 2.6 - float(index) * 2.5), Vector3(0.20, 0.07, 0.48), "stone")
			edge.set_meta("weybridge_cutaway_candidate", false)
	# Remove the helper-added edge paths; ground/base marks stay opaque.
	_rebuild_cutaway_paths(root)


static func _rooms(root: Node3D) -> void:
	var rooms: Node3D = House._node(root, "CompactExposedDomesticRooms", Vector3.ZERO, "a2-o2-reused-domestic-rooms")
	rooms.set_meta("front_wall_removed", true)
	for side: int in [-1, 1]:
		for index: int in range(3):
			var z: float = 0.8 - float(index) * 5.5
			House._box(root, rooms, "LowBrickSidePier_%s_%s" % [side, index], Vector3(float(side) * 3.86, 0.40, z), Vector3(0.34, 0.80, 0.42), "brick")
			House._box(root, rooms, "BrokenFlushCoping_%s_%s" % [side, index], Vector3(float(side) * 3.86, 0.83, z), Vector3(0.36, 0.06, 0.44), "ash_wood")
			House._box(root, rooms, "ChippedPlasterSide_%s_%s" % [side, index], Vector3(float(side) * 4.03, 0.40, z - 1.8), Vector3(0.14, 0.80, 2.8), "plaster")
			House._rod(root, rooms, "ShortSplitSideTimber_%s_%s" % [side, index], Vector3(float(side) * 3.87, 0.88, z - 0.2), Vector3(float(side) * 3.72, 0.66, z - 1.45), 0.035, "char")
	# Whole original modules retain native scale and materials; only roots move.
	House._pantry(root, rooms, Vector3(-3.65, 0.0, 0.0))
	House._sink(root, rooms, Vector3(3.72, 0.0, -6.0))
	House._hearth(root, rooms, Vector3(-3.75, 0.0, -10.7))
	var arch: Node3D = House._brick_arch(root, rooms, Vector3(3.70, 0.0, -12.2))
	arch.rotation.y = PI * 0.5


static func _industrial_edges(root: Node3D) -> void:
	# Retain the accepted harmless stand's shape, fixed at its quiet first pose.
	var work: Node3D = House._work_tableau(root)
	work.position = Vector3(4.55, 0.0, -9.2)
	work.set_meta("clock_owner", "none; fixed quiet reused tableau")
	House.set_work_tableau({"work_tableau": work}, false, 0.0)
	var plates: Node3D = House._node(root, "OutboardRivetedPlateStore", Vector3(-4.05, 0.0, -6.1), "a2-o2-reused-industrial-plates")
	for index: int in range(3):
		House._box(root, plates, "StackedOxidisedPlate_%s" % index, Vector3(0.0, 0.055 + float(index) * 0.065, 0.0), Vector3(0.78, 0.045, 0.82), "metal")
		for rivet: int in range(3):
			House._box(root, plates, "PlateFastener_%s_%s" % [index, rivet], Vector3(-0.30 + float(rivet) * 0.30, 0.086 + float(index) * 0.065, -0.30), Vector3(0.028, 0.017, 0.028), "fastener")
	for index: int in range(3):
		House._rod(root, plates, "QuietLooseRod_%s" % index, Vector3(-0.28, 0.075, 0.61 + float(index) * 0.12), Vector3(0.32, 0.075, 0.82 + float(index) * 0.12), 0.025, "rim")


static func _store_crate(root: Node3D, id: String, at: Vector3) -> Node3D:
	var crate: Node3D = House._node(root, "CanisterStore_%s" % id, at, "a2-o2-canister-store-%s" % id)
	crate.set_meta("enemy_store_id", id)
	crate.set_meta("nonactionable", true)
	crate.set_meta("native_scale", 1.0)
	crate.set_meta("feet_pivot", Vector3.ZERO)
	crate.set_meta("visual_bounds_local", AABB(Vector3(-0.36, 0.0, -0.44), Vector3(0.72, 0.67, 0.88)))
	House._box(root, crate, "GroundedTimberCrateBase", Vector3(0.0, 0.045, 0.0), Vector3(0.72, 0.09, 0.88), "wood")
	House._box(root, crate, "EmptyDarkCrateInterior", Vector3(0.0, 0.100, 0.0), Vector3(0.60, 0.012, 0.76), "cavity")
	for side: int in [-1, 1]:
		for slat: int in range(3):
			House._box(root, crate, "SideSlat_%s_%s" % [side, slat], Vector3(float(side) * 0.335, 0.15 + float(slat) * 0.115, 0.0), Vector3(0.05, 0.075, 0.84), "wood")
			House._box(root, crate, "EndSlat_%s_%s" % [side, slat], Vector3(0.0, 0.15 + float(slat) * 0.115, float(side) * 0.415), Vector3(0.62, 0.075, 0.05), "wood")
		for z: float in [-0.395, 0.395]:
			House._box(root, crate, "CrateCornerStrap_%s_%s" % [side, z], Vector3(float(side) * 0.30, 0.26, z), Vector3(0.035, 0.33, 0.025), "rim")
	var contents: Node3D = House._node(crate, "FullCanisters", Vector3.ZERO, "a2-o2-reused-canister-contents")
	for index: int in range(6):
		var x: float = -0.16 + float(index % 2) * 0.32
		var z: float = -0.26 + float(index >> 1) * 0.26
		House._cylinder(root, contents, "OxidisedStoreTube_%s" % index, Vector3(x, 0.365, z), 0.090, 0.085, 0.43, "metal", 10)
		House._ring(root, contents, "TubeRaisedRim_%s" % index, Vector3(x, 0.585, z), 0.074, 0.096, "rim")
		House._cylinder(root, contents, "QuietClosedTubeCap_%s" % index, Vector3(x, 0.601, z), 0.073, 0.073, 0.028, "cavity", 10)
		House._box(root, contents, "ShortTubeValve_%s" % index, Vector3(x, 0.637, z), Vector3(0.047, 0.044, 0.032), "rim")
	return crate


static func _circuit_marker(root: Node3D) -> Node3D:
	var marker: Node3D = House._node(root, "CompletedCircuitMarker", MARKER_POSITION, "a2-o2-completed-circuit-marker")
	marker.set_meta("native_scale", 1.0)
	marker.set_meta("feet_pivot", Vector3.ZERO)
	marker.set_meta("nonactionable", true)
	marker.set_meta("visual_bounds_local", AABB(Vector3(-0.36, 0.0, -0.12), Vector3(0.72, 0.73, 0.24)))
	House._box(root, marker, "QuietStoneMarkerFoot", Vector3(0.0, 0.045, 0.0), Vector3(0.32, 0.09, 0.24), "stone")
	House._box(root, marker, "WeatheredMarkerPost", Vector3(0.0, 0.34, 0.0), Vector3(0.065, 0.59, 0.07), "wood")
	House._box(root, marker, "PlainWornCircuitBoard", Vector3(0.0, 0.59, 0.0), Vector3(0.72, 0.26, 0.075), "ash_wood")
	# Three dull metal heads echo a completed circuit without an arrow/glow cue.
	for index: int in range(3):
		var fastener: MeshInstance3D = House._cylinder(root, marker, "DullCircuitFastener_%s" % index, Vector3(-0.22 + float(index) * 0.22, 0.59, 0.055), 0.033, 0.033, 0.027, "rim", 8)
		fastener.rotation.x = PI * 0.5
	return marker


static func _rebuild_cutaway_paths(root: Node3D) -> void:
	var paths: Array[String] = []
	_collect_cutaway_paths(root, root, paths)
	root.set_meta("optional_cutaway_paths", paths)


static func _collect_cutaway_paths(root: Node3D, parent: Node, paths: Array[String]) -> void:
	for child: Node in parent.get_children():
		if child is MeshInstance3D and bool(child.get_meta("weybridge_cutaway_candidate", false)):
			paths.append(str(root.get_path_to(child)))
		_collect_cutaway_paths(root, child, paths)
