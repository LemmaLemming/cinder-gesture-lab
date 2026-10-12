class_name PracticeTarget
extends Node3D
## Safe equipment-test prop. It is never an enemy, a reload reward or a core.

signal visual_state_changed(visual_state: String)

const PRESENTATION_API_REVISION: String = "practice-target-1"
const HIT_FEEDBACK_S: float = 0.15

var hp: float = 100.0
var max_hp: float = 100.0
var _face: MeshInstance3D
var _label: Label3D
var _hit_left: float = 0.0
var _visual_state: String = ""
var _presenting: bool = false
var _resolving_damage: bool = false

func _ready() -> void:
	add_to_group("practice_targets")
	build_presentation()
	_refresh_presentation(true)


## Override to build act-owned artwork beneath this prop. Group membership,
## health, accepted hits and feedback clocks remain in the shared parent.
## The matching present_state hook must use the artwork's own public nodes.
func build_presentation() -> void:
	_box(Vector3(0, 0.06, 0), Vector3(0.9, 0.12, 0.8), Color(0.19, 0.20, 0.22))
	_box(Vector3(0, 0.54, 0), Vector3(0.16, 0.96, 0.16), Color(0.38, 0.39, 0.42))
	_face = _box(Vector3(0, 1.04, 0), Vector3(0.72, 0.7, 0.15), Color(0.80, 0.81, 0.78))
	var centre := _box(Vector3.ZERO, Vector3(0.32, 0.32, 0.025), Color(0.17, 0.18, 0.20))
	remove_child(centre)
	_face.add_child(centre)
	centre.position = Vector3(0, 0, 0.09)
	_label = Label3D.new()
	_label.position = Vector3(0, 1.72, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.pixel_size = 0.022
	_label.font_size = 20
	_label.outline_size = 6
	add_child(_label)


## Explicit setup/local restoration. Omitted current_hp initializes full HP.
## notify=false refreshes presentation without hit/progression notifications.
## Validation precedes all mutation; restoring a feedback clock never hits.
func configure(maximum_hp: float = 100.0, current_hp: float = -1.0, hit_feedback_left_s: float = 0.0, notify: bool = true) -> bool:
	if _presenting or _resolving_damage or not is_finite(maximum_hp) or maximum_hp <= 0.0 or not is_finite(current_hp) or not is_finite(hit_feedback_left_s):
		return false
	var configured_hp: float = maximum_hp if current_hp == -1.0 else current_hp
	if configured_hp < 0.0 or configured_hp > maximum_hp or hit_feedback_left_s < 0.0 or hit_feedback_left_s > HIT_FEEDBACK_S:
		return false
	max_hp = maximum_hp
	hp = configured_hp
	_hit_left = hit_feedback_left_s
	if is_node_ready():
		_refresh_presentation(notify)
	return true


func state() -> String:
	if hp <= 0.0:
		return "cleared"
	return "hit" if _hit_left > 0.0 else "available"


func hit_feedback_left() -> float:
	return _hit_left

func take_damage(amount: float, _impulse: Vector3) -> Dictionary:
	var alive := hp > 0.0
	var loss: float = minf(hp, maxf(amount, 0.0)) if alive and is_finite(amount) else 0.0
	hp -= loss
	if loss > 0.0:
		_resolving_damage = true
		_hit_left = HIT_FEEDBACK_S
		_refresh_presentation(true)
		_resolving_damage = false
	return {"accepted": loss > 0.0, "hp_damage": loss, "target_id": get_instance_id(), "target_alive_before_hit": alive}

func _process(delta: float) -> void:
	_hit_left = maxf(0.0, _hit_left - delta)
	_refresh_presentation(true)


## Override for available/hit/cleared act artwork. The fraction counts down
## from 1 to 0 on the same pause-safe clock; it never controls accepted hits.
func present_state(visual_state: String, hit_feedback_fraction: float) -> void:
	if is_instance_valid(_face):
		_face.scale = Vector3(0.9, 0.9, 1.0) if visual_state == "hit" and hit_feedback_fraction > 0.0 else Vector3.ONE
		_face.visible = visual_state != "cleared"
	_update_label()


func _refresh_presentation(notify: bool) -> void:
	if _presenting:
		return
	var visual_state: String = state()
	var changed: bool = visual_state != _visual_state
	_visual_state = visual_state
	_presenting = true
	present_state(visual_state, clampf(_hit_left / HIT_FEEDBACK_S, 0.0, 1.0))
	if changed and notify:
		visual_state_changed.emit(visual_state)
	_presenting = false

func _update_label() -> void:
	if not is_instance_valid(_label):
		return
	_label.text = "%d" % int(ceil(hp)) if hp > 0.0 else "DONE"

func _box(pos: Vector3, dimensions: Vector3, tint: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	visual.material_override = material
	visual.position = pos
	add_child(visual)
	return visual
