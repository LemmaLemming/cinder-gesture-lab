class_name Act1RehearsalTargetVisual
extends Node3D
## G14's safe rehearsal cloth/roundel, adapted as original low-segment geometry.
## Visual-only: the published shared parent must supply state and hit fraction.
## No health, hit detection, groups, input, timers, cues or progression live here.

const INK: Color = Color("222222")
const COAL: Color = Color("353535")
const SHADE: Color = Color("606060")
const SILVER: Color = Color("a9a9a9")
const LIGHT: Color = Color("c8c8c8")

var _built: bool = false
var _state: String = "inactive"
var _hit_fraction: float = 0.0
var _standing: Node3D
var _folded: Node3D
var _cloth: Node3D
var _cloth_face: MeshInstance3D
var _materials: Dictionary = {}


func build(parent: Node3D) -> void:
	if _built or not is_instance_valid(parent):
		return
	name = "RehearsalClothVisual"
	if get_parent() == null:
		parent.add_child(self)
	_built = true
	# Level parent owns placement; our bottom-centred ground pivot stays zero.
	# Existing attack cue reaches0.34 atY0.025. Keep the central floor open
	# using side feet/rear tie; the shared cue and hit centre remain untouched.
	for side: float in [-1.0, 1.0]:
		_box(self, "LowPlantedSideFoot", Vector3(side * 0.45, 0.045, 0), Vector3(0.18, 0.09, 0.8), COAL)
	_box(self, "RearPlantedBrace", Vector3(0, 0.045, -0.43), Vector3(1.08, 0.09, 0.12), COAL)
	_standing = _group(self, "StandingClothFrame", Vector3.ZERO)
	for side: float in [-1.0, 1.0]:
		_box(_standing, "SlimFrameUpright", Vector3(side * 0.405, 0.77, 0), Vector3(0.065, 1.40, 0.065), SHADE)
		_cylinder(_standing, "RoundedFrameFinial", Vector3(side * 0.405, 1.50, 0), 0.050, 0.050, 0.06, SILVER)
		_box(_standing, "SplayedFrameFoot", Vector3(side * 0.435, 0.12, 0.14), Vector3(0.075, 0.13, 0.57), SHADE)
	_box(_standing, "ClothHangingBar", Vector3(0, 1.46, 0), Vector3(0.85, 0.055, 0.065), SILVER)
	_cloth = _group(_standing, "ClothFacePivot", Vector3(0, 1.04, 0.04))
	_cloth_face = _box(_cloth, "QuietCanvasCloth", Vector3.ZERO, Vector3(0.70, 0.81, 0.045), SILVER)
	# Intrinsic black/silver roundel is the source prop's painted decoration.
	# It has no phase colour, emissive halo or reserved actionable pulse.
	var outer := _cylinder(_cloth, "PaintedOuterRoundel", Vector3(0, 0, 0.028), 0.245, 0.245, 0.012, COAL)
	outer.rotation.x = PI * 0.5
	var middle := _cylinder(_cloth, "QuietRoundelBand", Vector3(0, 0, 0.037), 0.191, 0.191, 0.011, LIGHT)
	middle.rotation.x = PI * 0.5
	var centre := _cylinder(_cloth, "PaintedRoundelCentre", Vector3(0, 0, 0.045), 0.112, 0.112, 0.010, INK)
	centre.rotation.x = PI * 0.5
	for side: float in [-1.0, 1.0]:
		_box(_cloth, "ClothSideHem", Vector3(side * 0.33, 0, 0.032), Vector3(0.02, 0.78, 0.008), SHADE)
	_box(_cloth, "ClothBottomHem", Vector3(0, -0.39, 0.032), Vector3(0.67, 0.025, 0.008), SHADE)
	# Spent cloth rests behind the original cue; only this mesh group moves.
	_folded = _group(self, "FoldedSpentCloth", Vector3(0, 0, -0.75))
	for side: float in [-1.0, 1.0]:
		var folded_post := _box(_folded, "FoldedFrameRail", Vector3(side * 0.435, 0.19, 0), Vector3(0.065, 0.065, 0.63), SHADE)
		folded_post.rotation.x = side * deg_to_rad(5.0)
	_box(_folded, "LoweredClothBar", Vector3(0, 0.25, -0.20), Vector3(0.84, 0.055, 0.065), COAL)
	# Three broad dark folds replace the standing roundel and lower silhouette.
	for i: int in range(3):
		var fold := _box(_folded, "BroadFoldedCanvas", Vector3(0, 0.28 + i * 0.04, -0.11 + i * 0.13), Vector3(0.70, 0.035, 0.20), COAL if i % 2 == 0 else SHADE)
		fold.rotation.x = deg_to_rad(-13.0 if i % 2 == 0 else 13.0)
	_box(_folded, "FoldedCanvasHem", Vector3(0, 0.39, 0.22), Vector3(0.67, 0.035, 0.055), COAL)
	present_state(_state, _hit_fraction)


func present_state(state: String, hit_fraction: float) -> void:
	var requested: String = state.strip_edges().to_lower()
	_state = requested if requested in ["inactive", "available", "spent", "cleared"] else "inactive"
	_hit_fraction = clampf(hit_fraction, 0.0, 1.0) if is_finite(hit_fraction) else 0.0
	if not _built:
		return
	var spent: bool = _state in ["spent", "cleared"]
	_standing.visible = not spent
	_folded.visible = spent
	_cloth_face.material_override = _material(SILVER if _state == "available" else SHADE)
	# Supplied amount is a squash strength, not an elapsed time or hit event.
	# Frame/base stay planted; only available cloth responds, up to10% in Y.
	var squash: float = _hit_fraction if _state == "available" else 0.0
	_cloth.scale = Vector3(1.0 + 0.05 * squash, 1.0 - 0.10 * squash, 1.0)


func _group(parent: Node3D, node_name: String, origin: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = node_name
	node.position = origin
	parent.add_child(node)
	return node


func _material(color: Color) -> StandardMaterial3D:
	var key: String = color.to_html()
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.9
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_materials[key] = material
	return _materials[key] as StandardMaterial3D


func _mesh(parent: Node3D, node_name: String, origin: Vector3, geometry: Mesh, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	node.position = origin
	node.mesh = geometry
	node.material_override = _material(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node


func _box(parent: Node3D, node_name: String, origin: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var geometry := BoxMesh.new()
	geometry.size = size
	return _mesh(parent, node_name, origin, geometry, color)


func _cylinder(parent: Node3D, node_name: String, origin: Vector3, top: float, bottom: float, height: float, color: Color) -> MeshInstance3D:
	var geometry := CylinderMesh.new()
	geometry.top_radius = top
	geometry.bottom_radius = bottom
	geometry.height = height
	geometry.radial_segments = 16
	geometry.rings = 1
	return _mesh(parent, node_name, origin, geometry, color)
