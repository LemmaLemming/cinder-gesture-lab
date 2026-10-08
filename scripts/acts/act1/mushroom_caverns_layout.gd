extends Node3D
## A1-L3 prospective greybox layout, composed by the level owner.
## Source: canonical A1-L3 five beats/O43-O48 in the Act 1 level research and
## ACT1_CONCEPT; shallow caps/grounded stalks follow the source style guide.
## Reuses L2's quiet silver material and existing painted-rock texture.
## New fungal geometry is a static greybox, not production art or a spore proof.
## No Player, camera, HUD, actor, field, Scheduler or progression is created.

const FLOOR_RECT: Rect2 = Rect2(-7, -54, 14, 72)
# Inner faces of the visible perimeter bodies. Both rectangles are world X/Z;
# callers must retain an unscaled/unrotated level at the authored world origin.
const SAFE_RECT: Rect2 = Rect2(-6.9, -53.9, 13.8, 71.8)
const FLOOR_SIZE: Vector3 = Vector3(14, 0.4, 72)
const FLOOR_CENTRE: Vector3 = Vector3(0, -0.2, -18)
const SPAWN: Vector3 = Vector3(0, 0.1, 15)
const EXIT: Vector3 = Vector3(0, 0.8, -51)

const ROOM_IDS: Array[String] = ["umbrella", "breathing", "crossed", "lone-guard", "court"]
const ROOM_CENTRES: Array[Vector3] = [
	Vector3(0, 0, 10), Vector3(0, 0, -2), Vector3(0, 0, -16),
	Vector3(0, 0, -30), Vector3(0, 0, -43),
]
const BEAT_THRESHOLDS: Array[float] = [13.0, 2.0, -10.0, -25.0, -38.0]
# Prospective actual-body starts only. These do not create actors or decide
# admission, attack concurrency, population, difficulty or completed beats.
const SOURCE_POINTS: Dictionary = {
	"umbrella": [
		Vector3(-2.4, 0.005, 10), Vector3(2.4, 0.005, 10),
		Vector3(-2.4, 0.005, 7.2), Vector3(2.4, 0.005, 7.2),
	],
	"breathing": [
		Vector3(-2.4, 0.005, -1.5), Vector3(2.4, 0.005, -1.5),
		Vector3(0, 0.005, -5.2),
	],
	"crossed": [
		Vector3(-3.6, 0.005, -12.8), Vector3(3.6, 0.005, -12.8),
		Vector3(-1.2, 0.005, -13.6), Vector3(1.2, 0.005, -13.6),
		Vector3(-3.6, 0.005, -19.2), Vector3(3.6, 0.005, -19.2),
		Vector3(-1.2, 0.005, -18.4), Vector3(1.2, 0.005, -18.4),
	],
	"lone-guard": [Vector3(0, 0.005, -30)],
	"court": [
		Vector3(-2.8, 0.005, -40.5), Vector3(2.8, 0.005, -40.5),
		Vector3(0, 0.005, -41.5), Vector3(0, 0.005, -45),
	],
}

# Four independent future mushrooms: one breathing, two crossed, one court.
# Full circular fields are centred beneath an offset cap edge, not around a
# blocking stalk. Radius remains a proposal until the native consumer accepts.
const FIELD_RADIUS: float = 1.5
const FIELD_ORIGINS: Dictionary = {
	"breathing": Vector3(-1.6, 0, -2),
	"crossed-left": Vector3(-2.6, 0, -15.2),
	"crossed-right": Vector3(2.6, 0, -18),
	"court": Vector3(1.5, 0, -43),
}
# World-axis offsets, two separate low ordinary-primary anchors per instance.
# No cluster mesh, attack target or supply is instantiated by this helper.
const CLUSTER_OFFSETS: Array[Vector3] = [Vector3(-0.35, 0.8, -0.25), Vector3(0.35, 0.8, 0.25)]
const FIELD_SPECS: Array = [
	{"id": "breathing", "stalk": "BreathingStalk", "radius": FIELD_RADIUS},
	{"id": "crossed-left", "stalk": "CrossedLeftStalk", "radius": FIELD_RADIUS},
	{"id": "crossed-right", "stalk": "CrossedRightStalk", "radius": FIELD_RADIUS},
	{"id": "court", "stalk": "CourtStalk", "radius": FIELD_RADIUS},
]
# A bookkeeping reserve only: current shared capsule0.32 + clearance0.08 gives
# expanded radius1.90. Native measured support, floor/cylinder/route queries
# remain authoritative; neither this number nor algebra accepts placement.
const PROPOSED_CAPSULE_SUPPORT: float = 0.32
const PROPOSED_EXIT_CLEARANCE: float = 0.08
const PROPOSED_EXPANDED_RADIUS: float = FIELD_RADIUS + PROPOSED_CAPSULE_SUPPORT + PROPOSED_EXIT_CLEARANCE

# Five tall, visible BOX stalks. Their exact1.1x1.1 footprint is physical from
# floor0 to2.2. The contrasting grounded base has that same footprint.
# Caps are offset shallow scenic boxes and have NO collision or attack role.
const STALK_SIZE: Vector3 = Vector3(1.1, 2.2, 1.1)
const STALK_SPECS: Array = [
	{"id": "UmbrellaStalk", "origin": Vector3(-5.1, 0, 8.4), "cap_offset": Vector3(0.4, 2.4, 0), "cap_size": Vector3(3.2, 0.16, 1.6)},
	{"id": "BreathingStalk", "origin": Vector3(-4.6, 0, -2), "cap_offset": Vector3(1.2, 2.4, 0), "cap_size": Vector3(4.8, 0.16, 1.6)},
	{"id": "CrossedLeftStalk", "origin": Vector3(-5.6, 0, -15.2), "cap_offset": Vector3(1.2, 2.4, 0), "cap_size": Vector3(4.8, 0.16, 1.6)},
	{"id": "CrossedRightStalk", "origin": Vector3(5.6, 0, -18), "cap_offset": Vector3(-1.2, 2.4, 0), "cap_size": Vector3(4.8, 0.16, 1.6)},
	{"id": "CourtStalk", "origin": Vector3(4.5, 0, -43), "cap_offset": Vector3(-1.2, 2.4, 0), "cap_size": Vector3(4.8, 0.16, 1.6)},
]
const EDGE_SPECS: Array = [
	["WestEdge", Vector3(-7, 0.35, -18), Vector3(0.2, 0.7, 72)],
	["EastEdge", Vector3(7, 0.35, -18), Vector3(0.2, 0.7, 72)],
	["NorthEdge", Vector3(0, 0.35, -54), Vector3(14, 0.7, 0.2)],
	["SouthEdge", Vector3(0, 0.35, 18), Vector3(14, 0.7, 0.2)],
]
# Outer painted scenic shelves/trunk are not floors or hidden obstacles.
# Their nearest X extent stays outside the perimeter's outer face at+-7.1.
const SCENIC_SPECS: Array = [
	["WestShelf", Vector3(-7.6, 1.0, -8), Vector3(0.8, 0.5, 4)],
	["EastShelf", Vector3(7.6, 1.2, -35), Vector3(0.8, 0.5, 4)],
	["FallenTrunk", Vector3(7.6, 0.4, -25), Vector3(0.7, 0.8, 5)],
]
const PaintedRock = preload("res://assets/acts/act1/lunar/accents/painted_rock_surface.png")


static func stalk_specs_error(specifications: Array) -> String:
	# A whole authored table can relocate an origin, never silently change a
	# stalk's identity/order, physical size or cap vocabulary. This structural
	# guard is not a source/body/field/visibility clearance certificate.
	if specifications.size() != STALK_SPECS.size(): return "Every original mushroom stalk required exactly once"
	for index: int in range(STALK_SPECS.size()):
		var supplied: Variant = specifications[index]
		var original: Dictionary = STALK_SPECS[index]
		if not supplied is Dictionary or supplied.size() != 4: return "Closed mushroom stalk specification required"
		for key: Variant in supplied:
			if not key is String or key not in ["id", "origin", "cap_offset", "cap_size"]: return "Closed String mushroom stalk keys required"
		if not supplied.get("id") is String or supplied.id != original.id or not supplied.get("origin") is Vector3 or not supplied.get("cap_offset") is Vector3 or not supplied.get("cap_size") is Vector3: return "Original stalk identity/order and native vectors required"
		var origin: Vector3 = supplied.origin
		if not origin.is_finite() or origin.y != 0.0 or supplied.cap_offset != original.cap_offset or supplied.cap_size != original.cap_size: return "Retain grounded stalk origin and original cap offset/size"
		var half: Vector3 = STALK_SIZE * .5
		if origin.x - half.x < FLOOR_RECT.position.x or origin.x + half.x > FLOOR_RECT.end.x or origin.z - half.z < FLOOR_RECT.position.y or origin.z + half.z > FLOOR_RECT.end.y: return "Whole physical stalk must remain on the authored floor"
	return ""


static func build_geometry(level: Node3D, stalk_specifications: Array = []) -> bool:
	var specifications: Array = STALK_SPECS.duplicate(true) if stalk_specifications.is_empty() else stalk_specifications.duplicate(true)
	if not stalk_specs_error(specifications).is_empty(): return false
	# Call once on the actual level. One supported coplanar Box floor spans all
	# five connected chambers. Stable names expose real collider bindings.
	var floor_material := _material(Color(115.0 / 255.0, 115.0 / 255.0, 115.0 / 255.0))
	_box_body(level, "Floor", FLOOR_CENTRE, FLOOR_SIZE, floor_material)
	var rock_material := _material(Color.WHITE)
	rock_material.albedo_texture = PaintedRock
	rock_material.texture_repeat = true
	for spec: Array in EDGE_SPECS:
		_box_body(level, spec[0], spec[1], spec[2], rock_material)
	var stalk_material := _material(Color(0.48, 0.48, 0.48))
	var base_material := _material(Color(0.20, 0.20, 0.20))
	var cap_material := _material(Color(0.67, 0.67, 0.67))
	for spec: Dictionary in specifications:
		var origin: Vector3 = spec.origin
		var stalk: StaticBody3D = _box_body(level, spec.id, origin + Vector3.UP * STALK_SIZE.y * 0.5, STALK_SIZE, stalk_material)
		_box_visual(stalk, "GroundedBase", Vector3(0, 0.08 - STALK_SIZE.y * 0.5, 0), Vector3(STALK_SIZE.x, 0.16, STALK_SIZE.z), base_material)
		_box_visual(level, String(spec.id) + "GreyboxCap", origin + spec.cap_offset, spec.cap_size, cap_material)
	for spec: Array in SCENIC_SPECS:
		_box_visual(level, spec[0], spec[1], spec[2], rock_material)
	return true


static func _box_body(parent: Node3D, node_name: String, origin: Vector3, size: Vector3, material: StandardMaterial3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = origin
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	_box_visual(body, "Visual", Vector3.ZERO, size, material)
	parent.add_child(body)
	return body


static func _box_visual(parent: Node3D, node_name: String, origin: Vector3, size: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.position = origin
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(visual)
	return visual


static func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = colour
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return material
