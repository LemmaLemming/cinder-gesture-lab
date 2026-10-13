extends "res://scripts/campaign/level.gd"
## TEST ONLY native shared-Game art preview. No enemy target/hazard/progress.
## Actual production floor/kit/visual resources are reused without simulation.
const Floor: Script = preload("res://scripts/acts/act2/ruined_house_floor.gd")
const Kit: Script = preload("res://scripts/acts/act2/ruined_house_kit.gd")
const Boss: Script = preload("res://scripts/acts/act2/handling_machine_boss_visual.gd")
const Tender: Script = preload("res://scripts/acts/act2/canister_tender_visual.gd")
const Handler: Script = preload("res://scripts/acts/act2/salvage_handler_visual.gd")
var floors: Array[Dictionary] = []
var kit: Dictionary = {}
var rigs: Dictionary = {}
var selected_id: String = "boss"

func _ready() -> void:
	floors = Floor.build(self)
	kit = Kit.build(self)
	for id: String in ["road_tender", "house_tender", "house_handler", "boss"]:
		var rig: Node3D = (Boss.new() if id == "boss" else (Handler.new() if id == "house_handler" else Tender.new())) as Node3D
		rig.name = id
		rig.position = {"road_tender": Vector3(0.4, 0.0, -2.5), "house_tender": Vector3(0.85, 0.0, -12.2), "house_handler": Vector3(-0.80, 0.0, -15.5), "boss": Vector3(0.0, 0.0, -35.0)}[id]
		add_child(rig)
		rig.call("pose", "idle", 0.0, Vector3.BACK)
		rigs[id] = rig
	set_process(false)
	set_physics_process(false)

func select_view(id: String, phase: String, progress: float, action: String = "reach") -> bool:
	if not rigs.has(id) or phase not in ["idle", "warning", "lock", "active", "recovery", "defeated"] or not is_finite(progress) or progress < 0.0 or progress > 1.0: return false
	if id == "boss" and not rigs[id].call("set_action", action): return false
	selected_id = id
	rigs[id].call("pose", phase, progress, Vector3.BACK)
	return true

func _camera_framing_points() -> Array:
	var points: Array = []
	if not rigs.has(selected_id): return points
	var bound: Dictionary = _native_bound(rigs[selected_id])
	if bound.get("found", false):
		for index: int in range(8): points.append(bound.box.get_endpoint(index))
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
			else: box = box.expand(point)
	for child: Node in node.get_children():
		var item: Dictionary = _native_bound(child)
		if item.found:
			box = box.merge(item.box) if found else item.box
			found = true
	return {"found": found, "box": box}

func _on_exit_level() -> void:
	for rig: Node3D in rigs.values(): rig.call("clear_readability")
	rigs.clear()
	kit.clear()
	floors.clear()
