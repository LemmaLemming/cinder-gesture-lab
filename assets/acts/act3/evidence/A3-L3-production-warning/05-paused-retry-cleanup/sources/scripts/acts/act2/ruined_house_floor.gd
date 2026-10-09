extends RefCounted
## Root-owned measured static floor/blocker assembly for A2-L3.
## Visual dressing is a separate collisionless kit. No moving surfaces.
const SPECS: Array[Dictionary] = [
	{"id": "smoke_edge_road", "rect": Rect2(-3.4, -8.8, 6.8, 12.4)},
	{"id": "exposed_house", "rect": Rect2(-3.4, -19.0, 6.8, 11.2)},
	{"id": "work_apron", "rect": Rect2(-3.4, -29.5, 6.8, 11.5)},
	{"id": "boss_opening", "rect": Rect2(-3.4, -41.0, 6.8, 12.5)},
]
const WALL_AT: Vector3 = Vector3(0.0, 0.225, -13.4)
const WALL_SIZE: Vector3 = Vector3(2.5, 0.45, 0.45)
const FLOOR_INSET: float = 0.002

static func build(parent: Node3D) -> Array[Dictionary]:
	assert(is_instance_valid(parent), "L3 floor needs an actual owned parent")
	var root := Node3D.new()
	root.name = "RuinedHouseDryGround"
	parent.add_child(root)
	var floors: Array[Dictionary] = []
	for specification: Dictionary in SPECS:
		var rect: Rect2 = specification.rect
		var body: StaticBody3D = _box_body(root, specification.id, Vector3(rect.get_center().x, -0.25, rect.get_center().y), Vector3(rect.size.x, 0.5, rect.size.y), "DrySupport")
		var shape: CollisionShape3D = body.get_node("DrySupport") as CollisionShape3D
		floors.append({"id": specification.id, "rect": rect, "body": body, "collision": shape, "safe_rect": rect.grow(-FLOOR_INSET)})
	_box_body(root, "RuinedHouseLowWall", WALL_AT, WALL_SIZE, "GroundedWall")
	_box_body(root, "RoadArrivalEnd", Vector3(0.0, 0.45, 3.9), Vector3(7.8, 1.0, 0.6), "BankSolid")
	_box_body(root, "ExcavationEscapeEnd", Vector3(0.0, 0.45, -41.3), Vector3(7.8, 1.0, 0.6), "BankSolid")
	for side: int in [-1, 1]:
		_box_body(root, "WestDryBoundary" if side < 0 else "EastDryBoundary", Vector3(float(side) * 3.65, 0.45, -18.7), Vector3(0.5, 1.0, 44.6), "BankSolid")
	return floors

static func _box_body(parent: Node3D, stable_id: String, at: Vector3, dimensions: Vector3, shape_name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = stable_id
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var box := BoxShape3D.new()
	box.size = dimensions
	var collision := CollisionShape3D.new()
	collision.name = shape_name
	collision.shape = box
	body.add_child(collision)
	return body
