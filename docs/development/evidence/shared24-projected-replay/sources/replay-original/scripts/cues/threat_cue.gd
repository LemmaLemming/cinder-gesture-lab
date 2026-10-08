class_name CinderThreatCue
extends Node3D
## Required, externally clocked presentation of committed threat geometry.
## Owners advance phases and cancel attacks; this node has no damage/timers.
## Act art may subscribe to state_changed, leaving the required meshes intact.

signal state_changed(cue_state: Dictionary)

const Geometry: GDScript = preload("res://scripts/combat/threat_geometry.gd")
const CueMesh: GDScript = preload("res://scripts/cues/cue_mesh.gd")
const API_REVISION: String = "threat-cue-1"
const PHASES: Array[String] = ["warning", "lock", "active", "recovery"]
const FLOOR_OFFSET: float = 0.025

var last_error: String = ""
var _cue_state: Dictionary = {"api_revision": API_REVISION, "phase": "clear", "geometry": {}, "source_position": null, "required": true, "source_visible": false, "footprint_visible": false, "active_fill_visible": false}
var _outline: MeshInstance3D
var _fill: MeshInstance3D
var _source: MeshInstance3D
var _notifying: bool = false


func _ready() -> void:
	# The footprint is world geometry even under transformed act scenery.
	top_level = true
	add_to_group("required_cues")
	_outline = _mesh_node("RequiredFootprintOutline", FLOOR_OFFSET)
	_fill = _mesh_node("RequiredFootprintFill", FLOOR_OFFSET - 0.004)
	_source = _mesh_node("RequiredSourceMarker", FLOOR_OFFSET + 0.004)
	_outline.visible = false
	_fill.visible = false
	_source.visible = false


func present(geometry: Dictionary, phase: String) -> bool:
	if not is_inside_tree() or not is_node_ready():
		return _reject("Threat cue must be ready before presentation")
	if _notifying:
		return _reject("Threat cue cannot change inside its state callback")
	if phase not in PHASES:
		return _reject("Unsupported threat cue phase")
	var geometry_error: String = Geometry.error(geometry)
	if not geometry_error.is_empty():
		return _reject(geometry_error)
	var source: Variant = geometry.get("source_position", CueMesh.anchor(geometry))
	if not Geometry.finite_vector(source):
		return _reject("Threat source marker requires a finite world position")
	var shape: Dictionary = CueMesh.canonical_geometry(geometry)
	if _cue_state["phase"] in ["lock", "active"] and phase in ["lock", "active", "recovery"] and shape != _cue_state["geometry"]:
		return _reject("Locked danger geometry must remain committed; cancel before replacing it")
	var next: Dictionary = {"api_revision": API_REVISION, "phase": phase, "geometry": shape, "source_position": source, "required": true, "source_visible": true, "footprint_visible": phase != "recovery", "active_fill_visible": phase == "active"}
	last_error = ""
	if next == _cue_state:
		return true
	_cue_state = next
	global_transform = Transform3D(Basis.IDENTITY, CueMesh.anchor(shape))
	_outline.mesh = CueMesh.geometry_mesh(shape, false)
	_fill.mesh = CueMesh.geometry_mesh(shape, true)
	_source.mesh = CueMesh.source_mesh(phase)
	_source.position = (source as Vector3) - global_position + Vector3.UP * (FLOOR_OFFSET + 0.004)
	_outline.visible = next["footprint_visible"]
	_fill.visible = next["active_fill_visible"]
	_source.visible = true
	var color: Color = _phase_color(phase)
	(_outline.material_override as StandardMaterial3D).albedo_color = color
	(_fill.material_override as StandardMaterial3D).albedo_color = Color(color.r, color.g, color.b, 0.22)
	(_source.material_override as StandardMaterial3D).albedo_color = color
	_notify()
	return true


func clear() -> bool:
	if _notifying:
		return _reject("Threat cue cannot clear inside its state callback")
	last_error = ""
	if _cue_state["phase"] == "clear":
		return true
	_cue_state = {"api_revision": API_REVISION, "phase": "clear", "geometry": {}, "source_position": null, "required": true, "source_visible": false, "footprint_visible": false, "active_fill_visible": false}
	_outline.visible = false
	_fill.visible = false
	_source.visible = false
	_outline.mesh = null
	_fill.mesh = null
	_source.mesh = null
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


func _mesh_node(node_name: String, height: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	node.position.y = height
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	# Depth testing stays enabled: required logical geometry is not a
	# permission to make hidden scenery transparent or draw through walls.
	node.material_override = material
	add_child(node)
	return node


func _phase_color(phase: String) -> Color:
	match phase:
		"warning": return Color(1.0, 0.90, 0.63, 0.95)
		"lock": return Color(1.0, 0.76, 0.35, 1.0)
		"active": return Color(1.0, 0.43, 0.26, 1.0)
		"recovery": return Color(0.77, 0.88, 0.90, 0.70)
	return Color.WHITE
