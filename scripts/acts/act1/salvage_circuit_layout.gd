class_name Act1SalvageCircuitLayout
extends RefCounted
## SOURCE ONLY: compact parent-L2 optional clearing. Positions are hypotheses.
## No collection, attack, clock, camera, equipment or progression authority.

const LEVEL_ID: String = "A1-O1"
const FLOOR_RECT: Rect2 = Rect2(-7, -8, 14, 16)
const SAFE_RECT: Rect2 = Rect2(-6.5, -7.5, 13, 15)
const FLOOR_SIZE: Vector3 = Vector3(14, 1, 16)
const FLOOR_CENTRE: Vector3 = Vector3(0, -0.5, 0)
const SPAWN_POSITION: Vector3 = Vector3(0, 0.1, 5)
const PART_IDS: Array[String] = ["nose-cap", "rivet-band", "hatch-disc"]
const PART_POSITIONS: Dictionary = {
	"nose-cap": Vector3(-2, 0, 0),
	"rivet-band": Vector3(2, 0, 0),
	"hatch-disc": Vector3(0, 0, -2.7),
}
const HATCH_POSITION: Vector3 = Vector3(0, 0.65, 3.8)
const HATCH_CONTACT_SIZE: Vector3 = Vector3(1.6, 1.3, 0.9)
const CAPSULE_POSITION: Vector3 = Vector3(0, 0, 2)
const CIRCUIT_SOURCE_ID: String = "salvage-circuit-rusher"
const CIRCUIT_SOURCE_POSITION: Vector3 = Vector3(-1.8, 0.005, -1.5)
const FINAL_SOURCE_ID: String = "salvage-final-rusher"
const FINAL_SOURCE_POSITION: Vector3 = Vector3(1.2, 0.005, 0)
const IMPACT_ID: String = "salvage-circuit-impact"
const IMPACT_POSITION: Vector3 = Vector3(0, 0, -2.4)
const IMPACT_RADIUS: float = 0.85
const CHECKPOINT_ID: String = "salvage-parts-ready"
const COMPLETION_ID: String = "salvage-circuit-clear"
const HATCH_EXIT_ID: String = "repaired-hatch"
const PartScript = preload("res://scripts/acts/act1/salvage_circuit_part.gd")
const SceneryScript = preload("res://scripts/acts/act1/salvage_circuit_scenery.gd")


static func build_geometry(level: Node3D) -> Dictionary:
	if not is_instance_valid(level) or level.is_queued_for_deletion(): return {}
	# The scene retains its authoritative support body/shape; never replace it.
	var floor_body: StaticBody3D = level.get_node_or_null("Floor") as StaticBody3D
	var floor_collision: CollisionShape3D = level.get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
	if floor_body == null or floor_collision == null or not floor_collision.shape is BoxShape3D: return {}
	if level.get_node_or_null("Parts") != null or level.get_node_or_null("HatchContact") != null or level.get_node_or_null("Scenery") != null: return {}
	for spec: Array in [
		["WestEdge", Vector3(-7, 0.2, 0), Vector3(0.2, 0.4, 16)],
		["EastEdge", Vector3(7, 0.2, 0), Vector3(0.2, 0.4, 16)],
		["NorthEdge", Vector3(0, 0.2, -8), Vector3(14, 0.4, 0.2)],
		["SouthEdge", Vector3(0, 0.2, 8), Vector3(14, 0.4, 0.2)],
	]:
		_low_edge(level, String(spec[0]), spec[1], spec[2])
	var parts_root := Node3D.new()
	parts_root.name = "Parts"
	level.add_child(parts_root)
	var parts: Dictionary = {}
	for id: String in PART_IDS:
		var part: Node3D = PartScript.new()
		if not part.call("configure", id): return {}
		part.position = PART_POSITIONS[id]
		parts_root.add_child(part)
		parts[id] = part
	var hatch := Area3D.new()
	hatch.name = "HatchContact"
	hatch.position = HATCH_POSITION
	hatch.collision_layer = 0
	hatch.collision_mask = 4 # Actual shared Player body layer; no scenery blocker.
	hatch.monitorable = false
	var hatch_collision := CollisionShape3D.new()
	hatch_collision.name = "CollisionShape3D"
	var hatch_shape := BoxShape3D.new()
	hatch_shape.size = HATCH_CONTACT_SIZE
	hatch_collision.shape = hatch_shape
	hatch.add_child(hatch_collision)
	var hatch_cue := CinderInteractionCue.new()
	hatch_cue.name = "HatchInteractionCue"
	hatch_cue.position = Vector3(0, -0.65, 0)
	hatch.add_child(hatch_cue)
	level.add_child(hatch)
	var scenery: Node3D = SceneryScript.new()
	scenery.call("build", level)
	return {"floor_collision": floor_collision, "parts": parts, "hatch": hatch,
		"hatch_collision": hatch_collision, "hatch_cue": hatch_cue, "scenery": scenery}


static func _low_edge(level: Node3D, label: String, origin: Vector3, size: Vector3) -> void:
	# Same L2 low visible Box/physical Box convention, with O1 perimeter lengths.
	var body := StaticBody3D.new()
	body.name = label
	body.position = origin
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var visual := MeshInstance3D.new()
	visual.name = "VisibleLowScenery"
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.18, 0.18, 0.18)
	visual.material_override = material
	body.add_child(visual)
	level.add_child(body)
