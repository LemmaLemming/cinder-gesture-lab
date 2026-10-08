extends CinderLevel
## Owned scene production foundation. Combat awaits the published tracking
## adapter and shared cues; visual scouts are not damageable gameplay targets.

const HeathKit: Script = preload("res://scripts/acts/act2/heath_kit.gd")
const ScoutVisual: Script = preload("res://scripts/acts/act2/ray_scout_visual.gd")
const FLOOR_SPECS: Array[Dictionary] = [
	{"id": "arrival", "rect": Rect2(-3.4, -3.6, 6.8, 7.2)},
	{"id": "scorched_road", "rect": Rect2(-3.4, -10.0, 6.8, 7.0)},
	{"id": "common", "rect": Rect2(-3.4, -17.6, 6.8, 8.8)},
	{"id": "reunion_road", "rect": Rect2(-2.9, -20.0, 5.8, 2.8)},
	{"id": "departure", "rect": Rect2(-3.4, -27.6, 6.8, 8.4)},
	{"id": "woking_road", "rect": Rect2(-2.9, -30.2, 5.8, 3.0)},
]
## Two millimetres conservatively guard float32 collision transform roundoff.
## This changes proof rectangles only, never playable floor or dash collision.
const FLOOR_PROOF_INSET: float = 0.002
const SCOUT_POSITIONS: Dictionary = {
	"arrival": Vector3(0, 0, -0.4),
	"road_east": Vector3(1, 0, -5.4),
	"road_west": Vector3(-1, 0, -9.0),
	"common_left": Vector3(-0.9, 0, -14.5),
	"departure_a": Vector3(-0.65, 0, -23.1),
	"departure_b": Vector3(0.65, 0, -25.5),
}

var _floors: Array[Dictionary] = []
var _kit: Dictionary = {}
var _scouts: Dictionary = {}
var _scenic_clock: float = 0.0
var _witness_state: String = "arrival"
var _eruption_visible: bool = false


func _ready() -> void:
	_build_ground()
	_kit = HeathKit.build(self)
	for actor_id: String in SCOUT_POSITIONS:
		var visual: Node3D = ScoutVisual.new() as Node3D
		visual.name = "ScoutVisual_" + actor_id
		visual.position = SCOUT_POSITIONS[actor_id]
		add_child(visual)
		visual.call("pose", "idle", 0.0, Vector3.BACK)
		visual.visible = actor_id == "arrival"
		_scouts[actor_id] = visual
	_apply_tableau()


func _physics_process(delta: float) -> void:
	if not _entered or get_tree().paused or not is_instance_valid(hero) or hero.dead:
		return
	_scenic_clock += delta
	_apply_tableau()
	# Scenic time is simulation-owned. No timed wait, new attack, or completion
	# is inferred from the source tableau. Encounter transitions will own it.


func floor_regions() -> Array[Dictionary]:
	# Public authored geometry for the shared scheduler's real-floor witness.
	var result: Array[Dictionary] = []
	for floor: Dictionary in _floors:
		result.append({"id": floor["id"], "body": floor["body"], "rect": floor["rect"], "collision": floor["collision"], "safe_rect": floor["safe_rect"]})
	return result


func floor_bindings() -> Dictionary:
	# Stable authored save bindings; objects are live guards, never JSON payload.
	var result: Dictionary = {}
	for floor: Dictionary in _floors:
		result[floor["id"]] = {"collision": floor["collision"], "safe_rect": floor["safe_rect"]}
	return result


func _build_ground() -> void:
	var floor_root := Node3D.new()
	floor_root.name = "DryGround"
	add_child(floor_root)
	for specification: Dictionary in FLOOR_SPECS:
		var rect: Rect2 = specification["rect"]
		var body := StaticBody3D.new()
		body.name = specification["id"]
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = Vector3(rect.get_center().x, -0.25, rect.get_center().y)
		floor_root.add_child(body)
		var shape := BoxShape3D.new()
		shape.size = Vector3(rect.size.x, 0.5, rect.size.y)
		var collision := CollisionShape3D.new()
		collision.name = "DrySupport"
		collision.shape = shape
		body.add_child(collision)
		_floors.append({"id": specification["id"], "rect": rect, "body": body, "collision": collision, "safe_rect": rect.grow(-FLOOR_PROOF_INSET)})
		# Kit supplies the authored ground texture above this hidden collision.
	_build_bank("ArrivalEndBank", Vector3(0, 0.45, 3.9), Vector3(7.8, 1.0, 0.6), floor_root)
	_build_bank("WokingEndBank", Vector3(0, 0.45, -30.5), Vector3(6.8, 1.0, 0.6), floor_root)
	for edge: Dictionary in [
		{"id": "Heath", "half_width": 3.4, "near": 3.6, "far": -17.6},
		{"id": "Reunion", "half_width": 2.9, "near": -17.6, "far": -19.2},
		{"id": "Departure", "half_width": 3.4, "near": -19.2, "far": -27.6},
		{"id": "Woking", "half_width": 2.9, "near": -27.6, "far": -30.2},
	]:
		for side: float in [-1.0, 1.0]:
			_build_bank(edge["id"] + ("WestBank" if side < 0.0 else "EastBank"), Vector3(side * (edge["half_width"] + 0.25), 0.45, (edge["near"] + edge["far"]) * 0.5), Vector3(0.5, 1.0, edge["near"] - edge["far"]), floor_root)
	# One grounded trunk creates the short inside flank on the common. It is
	# stationary layer-1 scenery, and does not impersonate an interaction cue.
	var trunk := StaticBody3D.new()
	trunk.name = "CommonGroundedTrunk"
	trunk.position = Vector3(-1.2, 0.6, -10.8)
	trunk.collision_layer = 1
	trunk.collision_mask = 0
	floor_root.add_child(trunk)
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = 0.35
	trunk_shape.height = 1.2
	var trunk_collision := CollisionShape3D.new()
	trunk_collision.name = "GroundedSolid"
	trunk_collision.shape = trunk_shape
	trunk.add_child(trunk_collision)
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.21
	trunk_mesh.bottom_radius = 0.35
	trunk_mesh.height = 1.2
	trunk_mesh.radial_segments = 7
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color("322924")
	bark.roughness = 1.0
	var trunk_visual := MeshInstance3D.new()
	trunk_visual.mesh = trunk_mesh
	trunk_visual.material_override = bark
	trunk.add_child(trunk_visual)


func _build_bank(stable_name: String, position_value: Vector3, dimensions: Vector3, parent: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = stable_name
	body.position = position_value
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var shape := BoxShape3D.new()
	shape.size = dimensions
	var collision := CollisionShape3D.new()
	collision.name = "BankSolid"
	collision.shape = shape
	body.add_child(collision)
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var soil := StandardMaterial3D.new()
	soil.albedo_color = Color("69523b")
	soil.roughness = 1.0
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = soil
	body.add_child(visual)


func _apply_tableau() -> void:
	var witness_progress: float = clampf(_scenic_clock / 1.6, 0.0, 1.0) if _witness_state == "retreat" else 0.0
	HeathKit.set_tableau(_kit, _witness_state, witness_progress)
	HeathKit.set_eruption(_kit, _eruption_visible, clampf(_scenic_clock / 1.6, 0.0, 1.0))


func _capture_local_state() -> Dictionary:
	return {"scenic_clock": _scenic_clock, "witness_state": _witness_state, "eruption_visible": _eruption_visible}


func _local_snapshot_error(state: Dictionary) -> String:
	if state.size() != 3 or not state.has_all(["scenic_clock", "witness_state", "eruption_visible"]):
		return "Horsell scenery snapshot fields do not match version 1"
	if not (state["scenic_clock"] is float or state["scenic_clock"] is int) or not is_finite(float(state["scenic_clock"])) or float(state["scenic_clock"]) < 0.0:
		return "Invalid Horsell simulation clock"
	if not state["witness_state"] is String or state["witness_state"] not in ["arrival", "retreat", "absent"] or not state["eruption_visible"] is bool:
		return "Invalid Horsell tableau state"
	if _floors.size() != FLOOR_SPECS.size() or _scouts.size() != SCOUT_POSITIONS.size() or not _kit.has("root") or not is_instance_valid(_kit["root"]):
		return "Missing Horsell runtime content"
	for floor: Dictionary in _floors:
		var body: Variant = floor["body"]
		if not is_instance_valid(body) or body.is_queued_for_deletion() or not is_ancestor_of(body):
			return "Missing owned Horsell floor"
		var support: Variant = floor.get("collision")
		if not is_instance_valid(support) or support.is_queued_for_deletion() or support.get_parent() != body or not support is CollisionShape3D or support.disabled or not support.shape is BoxShape3D:
			return "Missing owned Horsell support collision"
	for visual: Variant in _scouts.values():
		if not is_instance_valid(visual) or visual.is_queued_for_deletion() or not is_ancestor_of(visual):
			return "Missing owned Horsell Scout visual"
	for key: String in ["root", "eruption"]:
		var required: Variant = _kit.get(key)
		if not is_instance_valid(required) or required.is_queued_for_deletion() or not is_ancestor_of(required):
			return "Missing owned Horsell kit node"
	if not _kit.get("witnesses") is Array:
		return "Missing Horsell witness collection"
	for witness: Variant in _kit["witnesses"]:
		if not is_instance_valid(witness) or witness.is_queued_for_deletion() or not is_ancestor_of(witness):
			return "Missing owned Horsell witness"
	return ""


func _restore_local_state(state: Dictionary) -> void:
	_scenic_clock = float(state["scenic_clock"])
	_witness_state = state["witness_state"]
	_eruption_visible = state["eruption_visible"]
	_apply_tableau()


func _on_enter_level() -> void:
	set_physics_process(true)


func _on_exit_level() -> void:
	# All local scenery/visuals are children. No external signal/timer exists in
	# this art-preview revision. Disable its clock before shared refs release.
	set_physics_process(false)
