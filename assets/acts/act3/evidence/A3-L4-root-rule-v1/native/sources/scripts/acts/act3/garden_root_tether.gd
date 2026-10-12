class_name CinderAct3GardenRootTether
extends StaticBody3D
## B05 physical root network only. The distant likeness is separate scenery.
## The caller supplies actual native recovery custody; this target has no timer.

signal state_changed(current: Dictionary)

const MAX_HP: float = 60.0
const PHASE_BOUNDARY: float = 30.0
const BODY_SIZE: Vector3 = Vector3(0.34, 0.36, 0.34)
const FIXED_POSITION: Vector3 = Vector3(1, 0, 0)
var hp: float = MAX_HP
var max_hp: float = MAX_HP
var phase: int = 1
var dead: bool = false
var _open_provider: Callable
var _boundary_provider: Callable
var _configured: bool = false
var _mutating: bool = false
var _body: CollisionShape3D
var _views: Array[MeshInstance3D] = []
var _materials: Array[StandardMaterial3D] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 2
	collision_mask = 1
	_body = CollisionShape3D.new()
	_body.name = "RootCollision"
	var shape := BoxShape3D.new()
	shape.size = BODY_SIZE
	_body.shape = shape
	_body.position.y = BODY_SIZE.y * 0.5
	add_child(_body)
	_make_box("RootBody", BODY_SIZE, Vector3(0, 0.18, 0), Color("46334e"))
	_make_box("TetherBand", Vector3(0.42, 0.08, 0.42), Vector3(0, 0.08, 0), Color("74616f"))


func configure(open_provider: Callable, boundary_provider: Callable) -> bool:
	if _configured or not is_inside_tree() or not is_node_ready() or global_position != FIXED_POSITION or not open_provider.is_valid() or open_provider.get_argument_count() != 0 or not boundary_provider.is_valid() or boundary_provider.get_argument_count() != 0:
		return false
	_open_provider = open_provider
	_boundary_provider = boundary_provider
	_configured = true
	add_to_group("enemies")
	return true


func take_damage(amount: float, impulse: Vector3) -> Dictionary:
	var alive_before: bool = _configured and not dead and hp > 0.0
	var result: Dictionary = {"accepted": false, "hp_damage": 0.0, "target_id": get_instance_id(), "target_alive_before_hit": alive_before}
	if not alive_before or _mutating or get_tree().paused or not is_finite(amount) or amount <= 0.0 or not impulse.is_finite() or not runtime_error().is_empty() or not _open_provider.is_valid() or not _open_provider.call():
		return result
	_mutating = true
	var old_hp: float = hp
	var lower: float = PHASE_BOUNDARY if phase == 1 else 0.0
	hp = maxf(lower, hp - amount)
	result.accepted = hp < old_hp
	result.hp_damage = old_hp - hp
	if hp == lower:
		# Commit closed phase/lifecycle before parent cancellation and observers.
		phase = 2 if lower > 0.0 else 3
		dead = hp == 0.0
		if dead:
			collision_layer = 0
			collision_mask = 0
			_body.set_deferred("disabled", true)
			remove_from_group("enemies")
		_boundary_provider.call()
	present()
	state_changed.emit(state())
	_mutating = false
	return result


func state() -> Dictionary:
	return {"hp": hp, "max_hp": max_hp, "phase": phase, "dead": dead, "position": global_position, "open": _configured and not dead and _open_provider.is_valid() and bool(_open_provider.call())}


func present() -> void:
	var open: bool = _configured and not dead and _open_provider.is_valid() and bool(_open_provider.call())
	_materials[0].albedo_color = Color("201d29") if dead else Color("46334e")
	_materials[1].albedo_color = Color("514650") if dead else (Color("e5dece") if open else Color("74616f"))


func framing_points() -> Array:
	var points: Array = []
	for view: MeshInstance3D in _views:
		if is_instance_valid(view) and view.mesh != null:
			var box: AABB = view.mesh.get_aabb()
			for index: int in range(8):
				points.append(view.global_transform * box.get_endpoint(index))
	return points


func runtime_error() -> String:
	if not _configured or not is_inside_tree() or is_queued_for_deletion() or not is_visible_in_tree() or global_transform != Transform3D(Basis.IDENTITY, FIXED_POSITION) or not is_instance_valid(_body) or _body.get_parent() != self or not _body.shape is BoxShape3D or (_body.shape as BoxShape3D).size != BODY_SIZE or _body.transform != Transform3D(Basis.IDENTITY, Vector3(0, 0.18, 0)):
		return "Actual fixed low tether body required"
	if not is_finite(hp) or dead != (hp == 0.0) or phase != (3 if dead else (1 if hp > PHASE_BOUNDARY else 2)) or hp < 0.0 or hp > MAX_HP or max_hp != MAX_HP:
		return "Monotonic tether HP and phase must agree"
	if not dead and (collision_layer != 2 or collision_mask != 1 or _body.disabled or not is_in_group("enemies")):
		return "Living tether must retain its physical ordinary target"
	for index: int in range(_views.size()):
		var view: MeshInstance3D = _views[index]
		var size: Vector3 = BODY_SIZE if index == 0 else Vector3(0.42, 0.08, 0.42)
		var at: Vector3 = Vector3(0, 0.18, 0) if index == 0 else Vector3(0, 0.08, 0)
		if not is_instance_valid(view) or view.get_parent() != self or not view.is_visible_in_tree() or not view.mesh is BoxMesh or (view.mesh as BoxMesh).size != size or view.transform != Transform3D(Basis.IDENTITY, at) or view.material_override != _materials[index]:
			return "Complete closed/exposed/spent low tether rendering required"
		var material: StandardMaterial3D = _materials[index]
		if material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.no_depth_test:
			return "Opaque nearest depth-tested low tether required"
	return ""


func _make_box(label: String, size: Vector3, at: Vector3, color: Color) -> void:
	var view := MeshInstance3D.new()
	view.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	view.mesh = mesh
	view.position = at
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.albedo_color = color
	view.material_override = material
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(view)
	_views.append(view)
	_materials.append(material)


func _exit_tree() -> void:
	_open_provider = Callable()
	_boundary_provider = Callable()
