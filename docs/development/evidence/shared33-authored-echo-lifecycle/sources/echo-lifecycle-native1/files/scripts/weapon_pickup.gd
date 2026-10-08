class_name LabWeaponPickup
extends Node3D
## Finite contact candidate. No tap-to-equip and no extra carried slot.

var item_id: String = "WEAPON-02"
var title: String = "Quick Edge"
var available: bool = true
var hero: CinderPlayer
var _label: Label3D
var _blade: MeshInstance3D
var _clock: float = 0.0

func _ready() -> void:
	_box(Vector3(0, 0.025, 0), Vector3(0.74, 0.05, 0.74), Color(0.22, 0.23, 0.26))
	_box(Vector3(0, 0.07, 0), Vector3(0.46, 0.08, 0.46), Color(0.42, 0.43, 0.46))
	_blade = _box(Vector3(0, 0.55, 0), Vector3(0.10, 0.66, 0.06), Color(0.88, 0.89, 0.85))
	_box(Vector3(0, 0.26, 0), Vector3(0.3, 0.06, 0.09), Color(0.63, 0.64, 0.64))
	_label = Label3D.new()
	_label.text = title.trim_suffix(" Edge").to_upper()
	_label.position.y = 1.22
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.pixel_size = 0.022
	_label.font_size = 20
	_label.outline_size = 6
	add_child(_label)

func _process(delta: float) -> void:
	_clock += delta
	if not available or not is_instance_valid(hero) or hero.dead:
		return
	_blade.scale.x = 1.0 if int(_clock / 0.8) % 2 == 0 else 1.2
	var distance: float = Vector2(hero.global_position.x - global_position.x, hero.global_position.z - global_position.z).length()
	if distance < 0.70 and hero.equip_item(item_id):
		available = false
		_blade.visible = false
		_label.text = "TAKEN"

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
