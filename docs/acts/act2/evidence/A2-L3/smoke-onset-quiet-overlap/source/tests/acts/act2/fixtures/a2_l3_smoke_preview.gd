extends "res://scripts/campaign/level.gd"
## TEST ONLY native smoke/cue/skin assembly. No Scheduler, targets or damage.
const Floor: Script = preload("res://scripts/acts/act2/ruined_house_floor.gd")
const Kit: Script = preload("res://scripts/acts/act2/ruined_house_kit.gd")
const Sequence: Script = preload("res://scripts/acts/act2/ruined_house_sequence.gd")
const TenderVisual: Script = preload("res://scripts/acts/act2/canister_tender_visual.gd")
const SmokeVisual: Script = preload("res://scripts/acts/act2/smoke_bank_visual.gd")
const ThreatCue: Script = preload("res://scripts/cues/threat_cue.gd")
const CueMesh: Script = preload("res://scripts/cues/cue_mesh.gd")
const Geometry: Script = preload("res://scripts/combat/threat_geometry.gd")
const BANK_RADIUS: float = 1.05
var floors: Array[Dictionary] = []
var kit: Dictionary = {}
var bank_source: Node3D
var smoke: Node3D
var tender: Node3D
var cue: Node3D
var assembly_error: String = ""


func _ready() -> void:
	floors = Floor.build(self)
	kit = Kit.build(self)
	bank_source = Node3D.new()
	bank_source.name = "TESTONLY_RoadBankSource"
	bank_source.position = Sequence.CLOUDS["road_bank"]
	add_child(bank_source)
	smoke = SmokeVisual.new() as Node3D
	smoke.name = "QuietLowBlackVapour"
	if not smoke.call("configure_radius", BANK_RADIUS):
		assembly_error = "Cannot match the authored cosmetic bank radius"
	bank_source.add_child(smoke)
	tender = TenderVisual.new() as Node3D
	tender.name = "TESTONLY_RoadTenderVisual"
	tender.position = Sequence.ACTORS["road_tender"]
	add_child(tender)
	tender.call("pose", "idle", 0.0, Vector3.BACK)
	cue = ThreatCue.new() as Node3D
	cue.name = "TESTONLY_ActualSharedCircleCue"
	add_child(cue)
	set_process(false)
	set_physics_process(false)


func select_view(phase: String, progress: float) -> bool:
	if not assembly_error.is_empty() or phase not in ["warning", "lock", "active", "recovery"] or not is_finite(progress) or progress < 0.0 or progress > 1.0:
		return false
	if not cue.call("present", bank_geometry(), phase):
		return false
	if not smoke.call("pose", phase, progress):
		return false
	tender.call("pose", phase, progress, Vector3.BACK)
	return true


func bank_geometry() -> Dictionary:
	# Actual authored HP-free bank origin, distinct from the Tender target.
	var shape: Dictionary = Geometry.circle(bank_source.global_position, BANK_RADIUS)
	shape["source_position"] = bank_source.global_position
	return shape


func _camera_framing_points() -> Array:
	var points: Array = []
	if not is_instance_valid(bank_source):
		return points
	# Full unchanged circle is included even while the cosmetic bank is small.
	for point: Vector3 in CueMesh.boundary(bank_geometry()):
		points.append(bank_source.global_position + point + Vector3.UP * 0.025)
	for node: Node3D in [tender, smoke, cue]:
		if not is_instance_valid(node):
			continue
		var bounds: Dictionary = _native_bound(node)
		if bounds["found"]:
			for index: int in range(8):
				points.append((bounds["box"] as AABB).get_endpoint(index))
	return points


func _native_bound(node: Node) -> Dictionary:
	var found: bool = false
	var box: AABB
	if node is MeshInstance3D and is_instance_valid(node.mesh) and node.is_visible_in_tree():
		var local: AABB = node.mesh.get_aabb()
		for index: int in range(8):
			var point: Vector3 = node.global_transform * local.get_endpoint(index)
			if not found:
				box = AABB(point, Vector3.ZERO)
				found = true
			else:
				box = box.expand(point)
	for child: Node in node.get_children():
		var item: Dictionary = _native_bound(child)
		if item["found"]:
			box = box.merge(item["box"]) if found else item["box"]
			found = true
	return {"found": found, "box": box}


func _on_exit_level() -> void:
	if is_instance_valid(cue):
		cue.call("clear")
	if is_instance_valid(smoke):
		smoke.call("pose", "clear", 0.0)
	if is_instance_valid(tender):
		tender.call("clear_readability")
	kit.clear()
	floors.clear()
