class_name PracticeTarget
extends Node3D
## Safe equipment-test prop. It is never an enemy, a reload reward or a core.

var hp: float = 100.0
var max_hp: float = 100.0
var _face: MeshInstance3D
var _label: Label3D
var _hit_left: float = 0.0

func _ready() -> void:
	add_to_group("practice_targets")
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
	_update_label()

func take_damage(amount: float, _impulse: Vector3) -> Dictionary:
	var alive := hp > 0.0
	var loss: float = minf(hp, maxf(amount, 0.0)) if alive else 0.0
	hp -= loss
	if loss > 0.0:
		_hit_left = 0.15
		_update_label()
	return {"accepted": loss > 0.0, "hp_damage": loss, "target_id": get_instance_id(), "target_alive_before_hit": alive}

func _process(delta: float) -> void:
	_hit_left = maxf(0.0, _hit_left - delta)
	_face.scale = Vector3(1.0, 1.0, 1.0) if _hit_left <= 0.0 else Vector3(0.9, 0.9, 1.0)
	_face.visible = hp > 0.0

func _update_label() -> void:
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
