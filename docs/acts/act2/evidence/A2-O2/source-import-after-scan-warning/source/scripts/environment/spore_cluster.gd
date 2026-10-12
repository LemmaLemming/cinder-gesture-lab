class_name CinderSporeCluster
extends Node3D
## HP-free ordinary-attack anchor. Its mushroom owns supplies and all clocks.

const Cue = preload("res://scripts/cues/interaction_cue.gd")
var _owner: WeakRef
var _cluster_id: String = ""
var _bound: bool = false
var _cue: Node3D
var _full: MeshInstance3D
var _patch: MeshInstance3D
var _visual_state: String = "available"


func configure(owner: Node3D, cluster_id: String) -> bool:
	if is_inside_tree() or _bound or not is_instance_valid(owner) or not owner.has_method("activate_cluster") or cluster_id.is_empty():
		return false
	_owner = weakref(owner)
	_cluster_id = cluster_id
	_bound = true
	return true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if not _bound:
		return
	add_to_group("environment_attack_targets")
	_full = _box("FullCluster", Vector3(0.16, 0.12, 0.16), Color(0.87, 0.87, 0.78), Vector3(0, 0.09, 0))
	_patch = _box("EmptyClusterPatch", Vector3(0.17, 0.025, 0.17), Color(0.34, 0.35, 0.32), Vector3(0, 0.015, 0))
	_cue = Cue.new()
	add_child(_cue)
	present_state("available", false)


func receive_attack(attack: Dictionary) -> Dictionary:
	var result: Dictionary = {"interaction_accepted": false, "interaction_kind": "spore_release", "accepted": false, "hp_damage": 0.0, "target_id": get_instance_id(), "target_alive_before_hit": false}
	if attack.size() != 2 or attack.get("kind") not in ["primary", "blast"] or attack.get("origin") != "player_direct" or not _bound or not is_inside_tree():
		return result
	var owner: Node3D = _owner.get_ref() as Node3D
	if is_instance_valid(owner):
		result.interaction_accepted = owner.call("activate_cluster", _cluster_id)
	return result


func present_state(visual_state: String, notify: bool = true) -> void:
	if visual_state not in ["available", "active", "spent"] or not is_instance_valid(_cue):
		return
	_visual_state = visual_state
	_full.visible = visual_state != "spent"
	_patch.visible = visual_state == "spent"
	var blocked: bool = _cue.is_blocking_signals()
	if not notify:
		_cue.set_block_signals(true)
	_cue.call("present", visual_state, "attack")
	_cue.set_block_signals(blocked)


func get_cue_state() -> Dictionary:
	return {"id": _cluster_id, "state": _visual_state, "full": _visual_state != "spent", "cue": _cue.call("state")} if is_instance_valid(_cue) else {}


func binding_error() -> String:
	if not _bound or not is_inside_tree() or not is_node_ready() or _owner == null or not is_instance_valid(_owner.get_ref()) or not is_instance_valid(_cue) or _cue.is_queued_for_deletion() or not is_instance_valid(_full) or _full.is_queued_for_deletion() or not is_instance_valid(_patch) or _patch.is_queued_for_deletion():
		return "Environmental cluster requires its actual owner and full/spent/cue nodes"
	return ""


func _box(node_name: String, size: Vector3, tint: Color, offset: Vector3) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = offset
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = tint
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)
	return visual
