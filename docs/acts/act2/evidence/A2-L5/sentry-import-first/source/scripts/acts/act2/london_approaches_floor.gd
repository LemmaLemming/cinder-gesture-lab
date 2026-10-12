extends RefCounted
## A2-L4's fixed, continuous dry supports and two visible grounded blockers.
## All geometry is axis-aligned in the level's identity coordinate space.
const SPECS: Array[Dictionary] = [
	{"id": "garden", "rect": Rect2(-3.4, -8.8, 6.8, 12.4)},
	{"id": "flood", "rect": Rect2(-3.4, -19.0, 6.8, 11.2)},
	{"id": "villa1", "rect": Rect2(-3.4, -28.0, 6.8, 10.0)},
	{"id": "villa2", "rect": Rect2(-3.4, -38.5, 6.8, 11.5)},
	{"id": "putney", "rect": Rect2(-3.4, -50.0, 6.8, 12.5)},
]
const BLOCKERS: Array[Dictionary] = [
	{"id": "GardenStemBlocker", "at": Vector3(0.0, 0.4, -4.6), "size": Vector3(1.4, 0.8, 0.65)},
	{"id": "VillaLowWall", "at": Vector3(0.0, 0.225, -22.6), "size": Vector3(1.5, 0.45, 0.45)},
]
const FLOOR_INSET: float = 0.002

static func build(parent: Node3D) -> Array[Dictionary]:
	assert(is_instance_valid(parent), "London approaches floor needs a level-owned parent")
	var root := Node3D.new()
	root.name = "LondonApproachesDryGround"
	parent.add_child(root)
	var floors: Array[Dictionary] = []
	for specification: Dictionary in SPECS:
		var rect: Rect2 = specification.rect
		var body: StaticBody3D = _box_body(root, specification.id, Vector3(rect.get_center().x, -0.25, rect.get_center().y), Vector3(rect.size.x, 0.5, rect.size.y), "DrySupport")
		var shape: CollisionShape3D = body.get_node("DrySupport") as CollisionShape3D
		floors.append({"id": specification.id, "rect": rect, "body": body, "collision": shape, "safe_rect": rect.grow(-FLOOR_INSET)})
	for specification: Dictionary in BLOCKERS:
		_box_body(root, specification.id, specification.at, specification.size, "GroundedBlocker")
	_box_body(root, "GardenArrivalEnd", Vector3(0.0, 0.45, 3.9), Vector3(7.8, 1.0, 0.6), "BankSolid")
	_box_body(root, "PutneyDepartureEnd", Vector3(0.0, 0.45, -50.3), Vector3(7.8, 1.0, 0.6), "BankSolid")
	for side: int in [-1, 1]:
		_box_body(root, "WestDryBoundary" if side < 0 else "EastDryBoundary", Vector3(float(side) * 3.65, 0.45, -23.2), Vector3(0.5, 1.0, 54.2), "BankSolid")
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
