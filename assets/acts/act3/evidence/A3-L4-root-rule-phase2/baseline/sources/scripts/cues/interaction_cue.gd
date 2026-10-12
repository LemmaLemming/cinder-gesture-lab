class_name CinderInteractionCue
extends Node3D
## Restrained repeated local cue for ordinary attack vs contact interaction.
## No activation, input, reward, hit logic, pulse timer or danger fill is added.

signal state_changed(cue_state: Dictionary)

const CueMesh: GDScript = preload("res://scripts/cues/cue_mesh.gd")
const API_REVISION: String = "interaction-cue-1"
const STATES: Array[String] = ["available", "active", "spent"]
const TRIGGERS: Array[String] = ["attack", "contact"]

var last_error: String = ""
var _cue_state: Dictionary = {"api_revision": API_REVISION, "state": "clear", "trigger": "attack", "required": true, "visible": false}
var _marker: MeshInstance3D
var _notifying: bool = false


func _ready() -> void:
	add_to_group("required_cues")
	_marker = MeshInstance3D.new()
	_marker.name = "RequiredInteractionMarker"
	_marker.position.y = 0.025
	_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_marker.material_override = material
	_marker.visible = false
	add_child(_marker)


func present(visual_state: String, trigger: String = "attack") -> bool:
	if not is_inside_tree() or not is_node_ready():
		return _reject("Interaction cue must be ready before presentation")
	if _notifying:
		return _reject("Interaction cue cannot change inside its state callback")
	if visual_state not in STATES or trigger not in TRIGGERS:
		return _reject("Unsupported interaction state or trigger")
	var next: Dictionary = {"api_revision": API_REVISION, "state": visual_state, "trigger": trigger, "required": true, "visible": true}
	last_error = ""
	if next == _cue_state:
		return true
	_cue_state = next
	_marker.mesh = CueMesh.interaction_mesh(visual_state, trigger)
	_marker.visible = true
	var color := Color(0.88, 0.92, 0.82, 0.85)
	if visual_state == "active":
		color = Color(1.0, 0.98, 0.87, 1.0)
	elif visual_state == "spent":
		color = Color(0.64, 0.68, 0.65, 0.40)
	(_marker.material_override as StandardMaterial3D).albedo_color = color
	_notify()
	return true


func clear() -> bool:
	if _notifying:
		return _reject("Interaction cue cannot clear inside its state callback")
	last_error = ""
	if _cue_state["state"] == "clear":
		return true
	_cue_state = {"api_revision": API_REVISION, "state": "clear", "trigger": _cue_state["trigger"], "required": true, "visible": false}
	_marker.visible = false
	_marker.mesh = null
	_notify()
	return true


func cancel() -> bool:
	return clear()


func state() -> Dictionary:
	return _cue_state.duplicate(true)


func _notify() -> void:
	_notifying = true
	state_changed.emit(state())
	_notifying = false


func _reject(reason: String) -> bool:
	last_error = reason
	return false
