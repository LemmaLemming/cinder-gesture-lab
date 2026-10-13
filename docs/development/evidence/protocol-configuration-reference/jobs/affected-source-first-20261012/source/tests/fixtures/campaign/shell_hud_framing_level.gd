extends "res://scripts/campaign/level.gd"
## TEST ONLY native source/cue/landing framing fixture. No attack or act content.

const Sprite = preload("res://scripts/pixel_sprite.gd")
const Cue = preload("res://scripts/cues/threat_cue.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")

var source: LabSprite
var cue: CinderThreatCue
var landing: MeshInstance3D
var crest: MeshInstance3D
var forecast: Dictionary
var framing_enabled: bool = true

func _ready() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "FixtureFloor"
	floor_body.position = Vector3(0, -0.5, 0)
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(24, 1, 24)
	collision.shape = shape
	floor_body.add_child(collision)
	add_child(floor_body)
	_mesh(floor_body, Vector3.ZERO, shape.size, Color("494c52"))
	source = Sprite.new()
	source.name = "NativeSourceArt"
	source.actor_kind = "enemy"
	source.position = Vector3(-1.02606, 0.8, 2.419079)
	add_child(source)
	crest = _mesh(self, Vector3(-1.02606, 1.58, 2.419079), Vector3(0.42, 0.1, 0.15), Color("f5e5ba"))
	landing = _mesh(self, Vector3(2.7, 0.012, 1.6), Vector3(0.9, 0.024, 0.9), Color("8aa39e"))
	cue = Cue.new()
	cue.name = "RequiredFixtureCue"
	add_child(cue)
	forecast = Geometry.lane(Vector3(0, 0, -0.4), Vector3(-1.02606, 0, 2.419079), 0.42)
	forecast["source_position"] = Vector3(-1.02606, 0, 2.419079)

func _on_enter_level() -> void:
	assert(cue.present(forecast, "warning"), "Fixture shared cue must accept native geometry")

func _camera_framing_points() -> Array:
	if not framing_enabled or not is_instance_valid(shared_shell):
		return []
	var points: Array = shared_shell.camera_billboard_points(source)
	for node: MeshInstance3D in [crest, landing, cue.get_node("RequiredFootprintOutline"), cue.get_node("RequiredSourceMarker")]:
		points.append_array(mesh_points(node))
	return points

func mesh_points(node: MeshInstance3D) -> Array:
	var bounds: AABB = node.get_aabb()
	var points: Array = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]:
				points.append(node.global_transform * Vector3(x, y, z))
	return points

func _mesh(parent: Node3D, at: Vector3, dimensions: Vector3, colour: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	node.mesh = mesh
	node.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	node.material_override = material
	parent.add_child(node)
	return node
