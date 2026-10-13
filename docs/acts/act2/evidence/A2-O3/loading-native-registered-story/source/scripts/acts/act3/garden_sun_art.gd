extends Node3D
## Harmless native white/blue presentation; actual parent owns the sun timeline.
## Same two noncolliding native orbs/palette as Twin Suns. The actual parent
## owns every clock/choice; this consumer only reads its closed public model.

const Kit = preload("res://scripts/acts/act3/twin_suns_scenery.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const KEYS: Array[String] = ["started", "anchor_s", "cycle", "elapsed_s", "stage", "effective_index", "incoming_index"]
const POSITIONS: Array[Vector3] = [Vector3(-1.8, 0.95, -4.2), Vector3(1.6, 1.1, -4.1)]
const RADII: Array[float] = [0.65, 0.42]
var _owner: CinderLevel
var _hero: CinderPlayer
var _kit: Node3D
var _motifs: Node3D
var _orbs: Array[MeshInstance3D] = []
var _materials: Array[StandardMaterial3D] = []
var _native_spheres: Array[Dictionary] = []
var _model: Dictionary = {}
var last_error: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_process(false)
	set_physics_process(false)


func configure(actual_parent: CinderLevel, actual_hero: CinderPlayer) -> bool:
	if _owner != null or not is_inside_tree() or not is_node_ready() or get_child_count() != 0 or global_transform != Transform3D.IDENTITY or not is_instance_valid(actual_parent) or not is_instance_valid(actual_hero) or not actual_parent.is_ancestor_of(self) or actual_parent.hero != actual_hero or not actual_parent.has_method("sun_presentation_state") or actual_parent.get_world_3d() != get_world_3d() or actual_hero.get_world_3d() != get_world_3d():
		last_error = "Actual entered parent/Hero/native world and public sun model required"
		return false
	_owner = actual_parent
	_hero = actual_hero
	_kit = Kit.new()
	_kit.name = "OriginalOrbHelperOnly"
	add_child(_kit) # No full kit build, floor, wall or controller.
	_motifs = Node3D.new()
	_motifs.name = "FamiliarWhiteBlueSuns"
	add_child(_motifs)
	for index: int in range(2):
		var orb: MeshInstance3D = _kit.call("_orb", _motifs, "Branchspell" if index == 0 else "Alppain", POSITIONS[index], RADII[index], Color.WHITE)
		orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material: StandardMaterial3D = orb.material_override
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_orbs.append(orb)
		_materials.append(material)
		var sphere: SphereMesh = orb.mesh
		_native_spheres.append({"mesh": sphere, "radius": sphere.radius, "height": sphere.height})
	return present()


func _read_model() -> Dictionary:
	var value: Variant = _owner.call("sun_presentation_state")
	if not value is Dictionary or not Codec.keys_error(value, KEYS).is_empty() or not value.started is bool or not Codec.is_integer(value.cycle, 0) or not Codec.in_range(value.elapsed_s, 0.0, 14.0) or value.stage not in ["stable", "preview", "lock"] or not Codec.is_integer(value.effective_index, 0, 1) or not Codec.is_integer(value.incoming_index, 0, 1) or int(value.incoming_index) != 1 - int(value.effective_index):
		return {}
	if (not value.started and (value.anchor_s != null or value.cycle != 0 or float(value.elapsed_s) != 0.0 or value.stage != "stable" or value.effective_index != 0)) or (value.started and not Codec.in_range(value.anchor_s, 0.0, 1000000000.0)):
		return {}
	return value.duplicate(true)


func _colors(model: Dictionary) -> Array[Color]:
	var colors: Array[Color] = [Color("e5dece") if model.effective_index == 0 else Color("bbb6c6"), Color("5171b7") if model.effective_index == 0 else Color("829dd7")]
	if model.stage in ["preview", "lock"]:
		colors[int(model.incoming_index)] = Color("a5b6df") if model.incoming_index == 1 else Color("f0e9db")
	return colors


func present(quiet: bool = false) -> bool:
	if not is_instance_valid(_owner) or not is_instance_valid(_hero) or not _owner.is_inside_tree() or not _hero.is_inside_tree() or _owner.is_queued_for_deletion() or _hero.is_queued_for_deletion() or _owner.hero != _hero or not _hero.global_position.is_finite() or not is_instance_valid(_motifs) or _motifs.is_queued_for_deletion() or _orbs.size() != 2 or _materials.size() != 2:
		last_error = "Actual retained parent/Hero and two native orbs required"
		return false
	for index: int in range(2):
		if not is_instance_valid(_orbs[index]) or _orbs[index].is_queued_for_deletion() or not is_instance_valid(_materials[index]):
			last_error = "Retained native sun leaves/materials required before presentation"
			return false
	var model: Dictionary = _read_model()
	if model.is_empty():
		last_error = "Closed actual parent-owned sun state required"
		return false
	var objects: Array[Object] = [_motifs]
	for index: int in range(2):
		objects.append(_orbs[index])
		objects.append(_materials[index])
	var flags: Array[bool] = []
	if quiet:
		for object: Object in objects:
			flags.append(object.is_blocking_signals())
			object.set_block_signals(true)
	_model = model
	_motifs.position = Vector3(_hero.global_position.x, 0, _hero.global_position.z)
	var colors: Array[Color] = _colors(model)
	for index: int in range(2):
		_orbs[index].visible = bool(model.started)
		_materials[index].albedo_color = colors[index]
	if quiet:
		for index: int in range(objects.size()):
			objects[index].set_block_signals(flags[index])
	last_error = runtime_error()
	return last_error.is_empty()


func runtime_error() -> String:
	if not is_inside_tree() or not is_node_ready() or is_queued_for_deletion() or not is_visible_in_tree() or global_transform != Transform3D.IDENTITY or process_mode != Node.PROCESS_MODE_PAUSABLE or is_processing() or is_physics_processing() or not get_groups().is_empty() or get_child_count() != 2 or not is_instance_valid(_owner) or not is_instance_valid(_hero) or _owner.hero != _hero or not _owner.is_ancestor_of(self):
		return "Ready harmless parent-owned native sun consumer required"
	if not is_instance_valid(_kit) or not is_instance_valid(_motifs) or _kit.get_parent() != self or _motifs.get_parent() != self or _kit.get_child_count() != 0 or _motifs.get_child_count() != 2 or _orbs.size() != 2 or _materials.size() != 2 or _native_spheres.size() != 2 or _model != _read_model() or _motifs.transform != Transform3D(Basis.IDENTITY, Vector3(_hero.global_position.x, 0, _hero.global_position.z)):
		return "Actual fixed orbital layout/current parent model and Hero follow required"
	var colors: Array[Color] = _colors(_model)
	for index: int in range(2):
		var orb: MeshInstance3D = _orbs[index]
		if not is_instance_valid(orb) or not orb.is_inside_tree() or orb.is_queued_for_deletion() or orb.get_parent() != _motifs or orb.top_level or orb.transform != Transform3D(Basis.IDENTITY, POSITIONS[index]) or orb.visible != bool(_model.started) or not orb.mesh is SphereMesh or orb.material_override != _materials[index] or not orb.get_groups().is_empty() or orb.get_child_count() != 0 or orb.layers != 1 or orb.transparency != 0.0 or orb.material_overlay != null or orb.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			return "Two complete original noncolliding native orbital leaves required"
		var sphere: SphereMesh = orb.mesh
		var material: StandardMaterial3D = _materials[index]
		if sphere != _native_spheres[index].mesh or sphere.radius != _native_spheres[index].radius or sphere.height != _native_spheres[index].height or Vector2(sphere.radius, sphere.height) != Vector2(RADII[index], RADII[index] * 2.0) or sphere.is_hemisphere or sphere.radial_segments != 20 or sphere.rings != 8 or material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.no_depth_test or material.albedo_color != colors[index] or material.albedo_texture != null or material.next_pass != null:
			return "Retained ordinary-depth white/blue original orb geometry/palette required"
	return ""


func framing_points(camera: Camera3D) -> Dictionary:
	var error: String = runtime_error()
	if not error.is_empty():
		return {"error": error, "points": []}
	if not is_instance_valid(camera) or not camera.is_inside_tree() or camera.is_queued_for_deletion() or camera.get_script() != null or camera.get_viewport() != get_viewport() or camera.get_world_3d() != get_world_3d() or get_viewport().get_camera_3d() != camera:
		return {"error": "Actual native current same-viewport sun Camera required", "points": []}
	var points: Array[Vector3] = []
	if _model.started:
		for orb: MeshInstance3D in _orbs:
			if not orb.is_visible_in_tree() or (camera.cull_mask & orb.layers) == 0:
				return {"error": "Displayed suns require actual included render leaves", "points": []}
			for corner: int in range(8):
				points.append(orb.global_transform * orb.mesh.get_aabb().get_endpoint(corner))
	return {"error": "", "points": points, "clock_authority": false}
