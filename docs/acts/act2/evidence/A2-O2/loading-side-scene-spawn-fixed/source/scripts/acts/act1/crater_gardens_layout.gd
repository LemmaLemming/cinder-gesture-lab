extends CinderLevel
## Main-level floor/layout hypothesis only. No progression or combat acceptance.
## The single shared Player/camera/input remain the preview shell's authority.

const FLOOR_RECT: Rect2 = Rect2(-7, -24, 14, 44)
const LANDING_CENTRE: Vector3 = Vector3(0, 0, 14.5)
const SOLO_SOURCE: Vector3 = Vector3(0, 0.005, 8)
const ROCK_SOURCE: Vector3 = Vector3(-2.8, 0.005, -1.8)
const OPEN_SOURCE: Vector3 = Vector3(2.8, 0.005, -1.8)
const CAMP_CENTRE: Vector3 = Vector3(0, 0, -9.5)
const FINAL_SOURCE: Vector3 = Vector3(0, 0.005, -16.5)
const GROTTO_CONTACT: Vector3 = Vector3(0, 0.8, -21.8)
const SceneryScript = preload("res://scripts/acts/act1/lunar_scenery.gd")
const PaintedRock = preload("res://assets/acts/act1/lunar/accents/painted_rock_surface.png")


func _ready() -> void:
	build_geometry(self)
	build_scenery(self)


static func build_scenery(level: Node3D) -> Node3D:
	# Match the quiet tile's transparent seams; this changes only floor paint.
	var floor_mesh: MeshInstance3D = level.get_node("Floor/Visual")
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(115.0 / 255.0, 115.0 / 255.0, 115.0 / 255.0)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_mesh.material_override = material
	var scenery: Node3D = SceneryScript.new()
	scenery.call("build", level)
	return scenery


static func build_geometry(level: Node3D) -> void:
	# Every scenery collider has a stable path and matching low visible body.
	# The branch divider is physical scenery, never a hidden progression gate.
	for spec: Array in [
		["WestEdge", Vector3(-7, 0.2, -2), Vector3(0.2, 0.4, 44)],
		["EastEdge", Vector3(7, 0.2, -2), Vector3(0.2, 0.4, 44)],
		["NorthEdge", Vector3(0, 0.2, -24), Vector3(14, 0.4, 0.2)],
		["SouthEdge", Vector3(0, 0.2, 20), Vector3(14, 0.4, 0.2)],
		["ApproachRock", Vector3(0, 0.2, -1.5), Vector3(1.6, 0.4, 7.0)],
		["RockRouteOuterFlat", Vector3(-5.4, 0.2, -1.5), Vector3(0.8, 0.4, 5.0)],
	]:
		var body := StaticBody3D.new()
		body.name = spec[0]
		body.position = spec[1]
		body.collision_layer = 1
		body.collision_mask = 0
		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		var shape := BoxShape3D.new()
		shape.size = spec[2]
		collision.shape = shape
		body.add_child(collision)
		var mesh := MeshInstance3D.new()
		mesh.name = "VisibleLowScenery"
		var box := BoxMesh.new()
		box.size = spec[2]
		mesh.mesh = box
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(0.18, 0.18, 0.18)
		if spec[0] in ["ApproachRock", "RockRouteOuterFlat"]:
			# The full existing low body remains visible and exactly physical.
			# This opaque paint has no cutout holes or separate gameplay surface.
			material.albedo_color = Color.WHITE
			material.albedo_texture = PaintedRock
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			material.texture_repeat = true
			material.uv1_scale = Vector3(1.0, 3.0, 1.0)
		mesh.material_override = material
		body.add_child(mesh)
		level.add_child(body)


func request_completion(_completion_id: String = "complete") -> bool:
	return false


func request_checkpoint(_checkpoint_id: String, _boundary_kind: String = "encounter") -> bool:
	return false


func request_contact_exit(_exit_id: String, _body: Node3D) -> bool:
	return false
