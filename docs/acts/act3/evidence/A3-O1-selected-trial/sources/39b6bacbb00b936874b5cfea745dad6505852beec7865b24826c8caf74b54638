extends Node3D
## New O1 scene-native prop adapted from G05 stone rings/G18 pale pillars.
## Visual only: the level owns grounded contact, receipts and InteractionCue.
## World-unit scale; origin is the floor/feet pivot. No collision or process.

const STONE := Color("34293f")
const EDGE := Color("7c668d")
const INLAY := Color("b9b4c9")
const SPENT := Color("626076")
const LOW_BOUND := Vector3(-0.72, 0.0, -0.72)
const HIGH_BOUND := Vector3(0.72, 0.64, 0.72)

var _built: bool = false
var _collected: bool = false
var _exit_seal: bool = false
var _cap: MeshInstance3D
var _inlay: MeshInstance3D
var _pieces: Array[MeshInstance3D] = []
var _teeth: Array[MeshInstance3D] = []
var _standing_teeth: Dictionary = {}
var _authored: Dictionary = {}


func build(index: int, exit_seal: bool = false) -> bool:
	if _built or index < 0 or index > 3:
		return false
	_exit_seal = exit_seal
	var base := CylinderMesh.new()
	base.top_radius = 0.56 if not exit_seal else 0.67
	base.bottom_radius = 0.64 if not exit_seal else 0.72
	base.height = 0.07
	base.radial_segments = 6
	_piece("GroundedStoneFoot", base, Vector3(0, 0.035, 0), STONE)
	# Two low broken uprights echo the tall reference pillars without hiding
	# the traveller's torso or impersonating an attack footprint.
	_teeth.append(_box("WestTooth", Vector3(0.16, 0.39, 0.18), Vector3(-0.27, 0.245, -0.12), EDGE))
	_teeth.append(_box("EastTooth", Vector3(0.16, 0.31, 0.18), Vector3(0.27, 0.205, -0.12), EDGE))
	for tooth: MeshInstance3D in _teeth:
		_standing_teeth[tooth.get_instance_id()] = tooth.transform
	_cap = _box("UnsettledCap", Vector3(0.67, 0.09, 0.20), Vector3(0, 0.57, -0.12), INLAY)
	_inlay = _box("SettledInlay", Vector3(0.39, 0.025, 0.30), Vector3(0, 0.087, 0.13), SPENT)
	# Quiet engraved notches identify the three props without a second HUD.
	for notch: int in range(3 if exit_seal else index + 1):
		var x: float = float(notch) * 0.14 - (float((3 if exit_seal else index + 1) - 1) * 0.07)
		_box("Notch%d" % notch, Vector3(0.06, 0.012, 0.10), Vector3(x, 0.078, 0.40), INLAY)
	_built = true
	return set_collected(false)


func set_collected(value: bool) -> bool:
	if not runtime_error().is_empty():
		return false
	if _collected == value:
		return true
	_collected = value
	_cap.position.y = 0.095 if value else 0.57
	# The authentic contact portrait showed raised spent teeth hiding boots.
	# Settled mirages become a low engraving; available silhouette is retained.
	for tooth: MeshInstance3D in _teeth:
		tooth.transform = _standing_teeth[tooth.get_instance_id()]
		if value:
			tooth.scale.y = 0.15
			tooth.position.y = 0.07 + tooth.mesh.get_aabb().size.y * 0.15 * 0.5
		_remember_piece(tooth)
	_cap.material_override = _material(SPENT if value else INLAY)
	_inlay.material_override = _material(INLAY if value else SPENT)
	_remember_piece(_cap)
	_remember_piece(_inlay)
	return true


func state() -> Dictionary:
	return {"built": _built, "collected": _collected, "exit_seal": _exit_seal}


func framing_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	if not runtime_error().is_empty():
		return points
	for x: float in [LOW_BOUND.x, HIGH_BOUND.x]:
		for y: float in [LOW_BOUND.y, HIGH_BOUND.y]:
			for z: float in [LOW_BOUND.z, HIGH_BOUND.z]:
				points.append(global_transform * Vector3(x, y, z))
	return points


func runtime_error() -> String:
	if not _built or not is_instance_valid(_cap) or not is_instance_valid(_inlay):
		return "Temporal marker requires its authored cap and inlay"
	for piece: MeshInstance3D in _pieces:
		if not is_instance_valid(piece) or piece.is_queued_for_deletion() or piece.get_parent() != self or piece.mesh == null or piece.material_override == null:
			return "Temporal marker requires its live noncolliding geometry"
		var material: StandardMaterial3D = piece.material_override as StandardMaterial3D
		var expected: Dictionary = _authored.get(piece.get_instance_id(), {})
		if material == null or expected.is_empty() or piece.mesh != expected.mesh or piece.mesh.get_aabb() != expected.bounds or piece.transform != expected.transform or piece.material_override != expected.material or material.albedo_color != expected.colour:
			return "Temporal marker authored geometry or presentation drifted"
	return ""


func _box(label: String, size: Vector3, at: Vector3, colour: Color) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	return _piece(label, box, at, colour)


func _piece(label: String, mesh: Mesh, at: Vector3, colour: Color) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.name = label
	piece.mesh = mesh
	piece.position = at
	piece.material_override = _material(colour)
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(piece)
	_pieces.append(piece)
	_remember_piece(piece)
	return piece


func _remember_piece(piece: MeshInstance3D) -> void:
	var material: StandardMaterial3D = piece.material_override as StandardMaterial3D
	_authored[piece.get_instance_id()] = {"mesh": piece.mesh, "bounds": piece.mesh.get_aabb(), "transform": piece.transform, "material": piece.material_override, "colour": material.albedo_color}


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = colour
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return material
