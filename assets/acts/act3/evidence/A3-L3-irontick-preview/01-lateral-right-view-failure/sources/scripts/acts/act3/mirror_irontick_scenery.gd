extends "res://scripts/acts/act3/twin_suns_scenery.gd"
## Original static north-bank Irontick/Earthrid vignette for a 14x22 room.
## Only parent geometry/material helpers are used. This adds no floor, actor,
## collider, group, interaction, warning, pulse clock or damage authority.
## Native geometry is an unrendered proposal until actual quiet portraits.

const LAKE_CENTER: Vector3 = Vector3(-1.55, -0.035, -12.75)
const LAKE_RADIUS: float = 1.6
const EARTHRID_SOLE: Vector3 = Vector3(-1.55, 0.02, -10.55)
const LAKE_COLOR: Color = Color("28323e")
const RIPPLE_COLOR: Color = Color("35404b")
const CLOTH_COLOR: Color = Color("594955")
const PALE_COLOR: Color = Color("a49ca0")
const HAIR_COLOR: Color = Color("211b26")
const EXPECTED_MESH_COUNT: int = 31

var _built: bool = false
var _build_error: String = ""
var _views: Array[MeshInstance3D] = []
var _roles: Array[String] = []
var _native: Array[Dictionary] = []
var _original_parent: Node
var _original_world: World3D
var _original_script: Script


func build(room: bool = true, _clear_pockets: bool = false) -> void:
	if not room:
		_build_error = "Irontick v1 supports only its authored 14x22 north-bank room"
		return
	if _built or not _build_error.is_empty():
		return
	if not is_inside_tree() or is_queued_for_deletion() or global_transform != Transform3D.IDENTITY:
		_build_error = "Add the untransformed Irontick root to its live native world before build"
		return
	_original_parent = get_parent()
	_original_world = get_world_3d()
	_original_script = get_script()
	var disc := PackedVector2Array()
	for i: int in range(24):
		var angle: float = TAU * float(i) / 24.0
		disc.append(Vector2(cos(angle), sin(angle)) * LAKE_RADIUS)
	_retain("IrontickWater", _floor_polygon(disc, LAKE_CENTER, LAKE_COLOR), "water")
	_quiet_water_strip("BrokenWaterStripNear", 0.62, 0.05, -2.65, -0.55)
	_quiet_water_strip("BrokenWaterStripFar", 1.10, 0.05, 0.30, 2.50)
	_rim_wedge("WestLakeRim", Vector3(-3.08, 0, -12.75), Vector2(0.42, 0.78), 0.12)
	_rim_wedge("FarLakeRim", Vector3(-1.45, 0, -14.26), Vector2(0.76, 0.38), 0.17)
	_rim_wedge("EastLakeRim", Vector3(-0.04, 0, -12.90), Vector2(0.46, 0.62), 0.16)
	_build_earthrid()
	for i: int in range(_views.size()):
		var view: MeshInstance3D = _views[i]
		_native.append({"view": view, "mesh": view.mesh, "material": view.material_override,
			"transform": view.transform, "name": view.name, "role": _roles[i],
			"node_stamp": _property_stamp(view, ["mesh", "material_override", "owner"]),
			"mesh_stamp": _mesh_stamp(view.mesh), "material_stamp": _property_stamp(view.material_override)})
	_built = true
	var error: String = runtime_error()
	if not error.is_empty():
		_build_error = error


## Static vignette: it has no sun-state or following-landmark authority.
func show_sun(_state: int, _stage: String) -> void:
	pass


func follow_landmarks(_hero_position: Vector3) -> void:
	pass


func runtime_error() -> String:
	if not _build_error.is_empty():
		return _build_error
	if not _built or not is_inside_tree() or is_queued_for_deletion() or not is_visible_in_tree():
		return "Irontick requires its built visible native root"
	if global_transform != Transform3D.IDENTITY or get_parent() != _original_parent or get_world_3d() != _original_world or get_script() != _original_script:
		return "Irontick requires its original untransformed parent/world/script"
	if not get_groups().is_empty() or is_instance_valid(floor_body) or get_child_count() != EXPECTED_MESH_COUNT or _native.size() != EXPECTED_MESH_COUNT or _views.size() != EXPECTED_MESH_COUNT:
		return "Irontick requires exactly its static meshes, without a floor or groups"
	for retained: Dictionary in _native:
		if not is_instance_valid(retained.view):
			return "Irontick native mesh was removed"
		var view: MeshInstance3D = retained.view as MeshInstance3D
		if view.is_queued_for_deletion() or view.get_parent() != self or not view.is_visible_in_tree() or view.get_child_count() != 0 or not view.get_groups().is_empty() or view.get_script() != null:
			return "Irontick requires its original static mesh ancestry and role"
		if view.name != retained.name or view.transform != retained.transform or view.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			return "Irontick native mesh placement or shadow policy changed"
		if not is_instance_valid(view.mesh) or not is_instance_valid(view.material_override) or view.mesh != retained.mesh or view.material_override != retained.material:
			return "Irontick native mesh/material identity changed"
		if view.mesh.get_script() != null or view.material_override.get_script() != null:
			return "Irontick requires script-free native geometry and material resources"
		if retained.node_stamp.is_empty() or retained.mesh_stamp.is_empty() or retained.material_stamp.is_empty() or _property_stamp(view, ["mesh", "material_override", "owner"]) != retained.node_stamp or _mesh_stamp(view.mesh) != retained.mesh_stamp or _property_stamp(view.material_override) != retained.material_stamp:
			return "Irontick native geometry or opaque ordinary-depth material changed"
		for surface: int in range(view.mesh.get_surface_count()):
			if view.get_surface_override_material(surface) != null:
				return "Irontick requires its original single opaque material per mesh"
	var lake: AABB = _bounds_for_role("water")
	var rim: AABB = _bounds_for_role("rim")
	if lake.position.z + lake.size.z >= -11.0 or rim.position.z + rim.size.z >= -11.0 or rim.position.y + rim.size.y > 0.18:
		return "Irontick water/rim must stay beyond the permanent north floor edge"
	var body: AABB = _bounds_for_role("earthrid")
	if body.size.x > 0.55 or body.size.z > 0.65 or body.size.y < 1.10 or body.size.y > 1.15:
		return "Earthrid must retain his bounded low kneeling native silhouette"
	return ""


## Conservative corners of every actual native mesh, including the whole lake.
func framing_points() -> Dictionary:
	var error: String = runtime_error()
	if not error.is_empty():
		return {"error": error, "points": []}
	var points: Array = []
	for view: MeshInstance3D in _views:
		points.append_array(_native_corners(view))
	return {"error": "", "points": points}


func camera_framing_points() -> Array:
	return framing_points().points


## Pure diagnostic; handles and mutable receipts remain private.
func native_geometry_state() -> Dictionary:
	var error: String = runtime_error()
	if not error.is_empty():
		return {"error": error}
	var meshes: Array = []
	for retained: Dictionary in _native:
		var view: MeshInstance3D = retained.view as MeshInstance3D
		meshes.append({"name": String(view.name), "role": retained.role, "transform": view.global_transform,
			"bounds": view.mesh.get_aabb(), "node_stamp": retained.node_stamp,
			"mesh_stamp": retained.mesh_stamp, "material_stamp": retained.material_stamp})
	return {"error": "", "mesh_count": _views.size(), "lake_center": LAKE_CENTER,
		"lake_radius": LAKE_RADIUS, "earthrid_sole": EARTHRID_SOLE,
		"earthrid_bounds": _bounds_for_role("earthrid"), "water_bounds": _bounds_for_role("water"),
		"rim_bounds": _bounds_for_role("rim"), "meshes": meshes}


func _retain(label: String, view: MeshInstance3D, role: String) -> void:
	view.name = label
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material: StandardMaterial3D = view.material_override as StandardMaterial3D
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	_views.append(view)
	_roles.append(role)


func _quiet_water_strip(label: String, radius: float, width: float, start: float, finish: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(10):
		if i in [3, 7]:
			continue
		var a: float = lerpf(start, finish, float(i) / 10.0)
		var b: float = lerpf(start, finish, float(i + 1) / 10.0)
		var near_a := Vector3(cos(a), 0, sin(a)) * (radius - width * 0.5)
		var far_a := Vector3(cos(a), 0, sin(a)) * (radius + width * 0.5)
		var near_b := Vector3(cos(b), 0, sin(b)) * (radius - width * 0.5)
		var far_b := Vector3(cos(b), 0, sin(b)) * (radius + width * 0.5)
		_triangle(surface, near_a, far_a, near_b, RIPPLE_COLOR)
		_triangle(surface, far_a, far_b, near_b, RIPPLE_COLOR)
	_surface_view(label, surface, LAKE_CENTER + Vector3(0, 0.004, 0), "water")


func _rim_wedge(label: String, at: Vector3, size: Vector2, height: float) -> void:
	var rim: Array[Vector3] = [Vector3(-size.x * 0.5, 0, -size.y * 0.5), Vector3(size.x * 0.5, 0, -size.y * 0.5), Vector3(size.x * 0.5, 0, size.y * 0.5), Vector3(-size.x * 0.5, 0, size.y * 0.5)]
	var crest := Vector3(-size.x * 0.12, height, size.y * 0.06)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(4):
		_triangle(surface, rim[i], crest, rim[(i + 1) % 4], Color("211e2b").lightened(float(i % 2) * 0.025))
	_triangle(surface, rim[0], rim[2], rim[1], Color("211e2b"))
	_triangle(surface, rim[0], rim[3], rim[2], Color("211e2b"))
	_surface_view(label, surface, at, "rim")


func _build_earthrid() -> void:
	for side: float in [-1.0, 1.0]:
		_person_box("Sole" + str(side), Vector3(0.18, 0.08, 0.18), Vector3(side * 0.13, 0.04, 0.09), Color("403440"))
		_person_box("Knee" + str(side), Vector3(0.19, 0.23, 0.22), Vector3(side * 0.16, 0.115, -0.03), CLOTH_COLOR)
	_tapered_person("KneelingHips", Vector3(0, 0.16, 0.10), Vector2(0.36, 0.24), Vector2(0.30, 0.24), 0.23, 0.0)
	_tapered_person("LeaningTorso", Vector3(0, 0.36, 0.04), Vector2(0.36, 0.22), Vector2(0.31, 0.20), 0.38, -0.15)
	_person_box("PaleNeck", Vector3(0.12, 0.13, 0.12), Vector3(0, 0.805, -0.065), PALE_COLOR.darkened(0.08))
	for side: float in [-1.0, 1.0]:
		_person_box("UpperArm" + str(side), Vector3(0.095, 0.31, 0.105), Vector3(side * 0.195, 0.655, -0.11), CLOTH_COLOR, Basis(Vector3.RIGHT, 0.55))
		_person_box("Forearm" + str(side), Vector3(0.085, 0.25, 0.08), Vector3(side * 0.195, 0.45, -0.26), PALE_COLOR.darkened(0.12), Basis(Vector3.RIGHT, 0.62))
		_person_box("HandTowardWater" + str(side), Vector3(0.095, 0.09, 0.11), Vector3(side * 0.195, 0.327, -0.36), PALE_COLOR)
	# Body/hands face the lake. The head turns back three-quarter toward the
	# traveller so the weak face and ear-like forehead fold can be inspected.
	var head := EARTHRID_SOLE + Vector3(0, 0.97, -0.10)
	var facing := Basis(Vector3.UP, 2.50)
	_head_box("PaleWeakHead", Vector3(0.22, 0.26, 0.20), head, facing, Vector3.ZERO, PALE_COLOR)
	_head_box("QuietFacePlane", Vector3(0.18, 0.19, 0.008), head, facing, Vector3(0, -0.015, -0.104), PALE_COLOR.lightened(0.035))
	for side: float in [-1.0, 1.0]:
		_head_box("VacantEye" + str(side), Vector3(0.025, 0.012, 0.009), head, facing, Vector3(side * 0.048, 0.015, -0.111), Color("5d5360"))
		_head_box("SparseChin" + str(side), Vector3(0.016, 0.022, 0.009), head, facing, Vector3(side * 0.036, -0.095, -0.111), HAIR_COLOR)
	_head_box("QuietMouth", Vector3(0.042, 0.01, 0.009), head, facing, Vector3(0, -0.055, -0.111), Color("796a73"))
	for i: int in range(3):
		_head_box("SparseHair" + str(i), Vector3(0.045, 0.016, 0.055), head, facing, Vector3(float(i - 1) * 0.055, 0.142, 0.015 + float(i % 2) * 0.025), HAIR_COLOR)
	_forehead_fold(head, facing)
	var shadow := PackedVector2Array([Vector2(-0.26, -0.13), Vector2(0.16, -0.14), Vector2(0.27, 0.06), Vector2(0.16, 0.18), Vector2(-0.24, 0.15)])
	_retain("EarthridDryContact", _floor_polygon(shadow, Vector3(EARTHRID_SOLE.x, 0.006, EARTHRID_SOLE.z), Color("25202e")), "contact")


func _person_box(label: String, size: Vector3, local_at: Vector3, color: Color, basis: Basis = Basis.IDENTITY) -> void:
	var view: MeshInstance3D = _box(size, EARTHRID_SOLE + local_at, color)
	view.basis = basis
	_retain(label, view, "earthrid")


func _head_box(label: String, size: Vector3, pivot: Vector3, facing: Basis, local_at: Vector3, color: Color) -> void:
	var view: MeshInstance3D = _box(size, pivot + facing * local_at, color)
	view.basis = facing
	_retain(label, view, "earthrid")


func _tapered_person(label: String, at: Vector3, bottom: Vector2, top: Vector2, height: float, lean: float) -> void:
	var low: Array[Vector3] = [Vector3(-bottom.x * 0.5, 0, -bottom.y * 0.5), Vector3(bottom.x * 0.5, 0, -bottom.y * 0.5), Vector3(bottom.x * 0.5, 0, bottom.y * 0.5), Vector3(-bottom.x * 0.5, 0, bottom.y * 0.5)]
	var high: Array[Vector3] = [Vector3(-top.x * 0.5, height, -top.y * 0.5), Vector3(top.x * 0.5, height, -top.y * 0.5), Vector3(top.x * 0.5, height, top.y * 0.5), Vector3(-top.x * 0.5, height, top.y * 0.5)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(4):
		var next: int = (i + 1) % 4
		var shade: Color = CLOTH_COLOR.lightened(float(i % 3) * 0.035)
		_triangle(surface, low[i], high[i], low[next], shade)
		_triangle(surface, low[next], high[i], high[next], shade)
	_triangle(surface, high[0], high[1], high[2], CLOTH_COLOR)
	_triangle(surface, high[0], high[2], high[3], CLOTH_COLOR)
	_triangle(surface, low[0], low[2], low[1], CLOTH_COLOR)
	_triangle(surface, low[0], low[3], low[2], CLOTH_COLOR)
	var view: MeshInstance3D = _surface_view(label, surface, EARTHRID_SOLE + at, "earthrid")
	view.basis = Basis(Vector3.RIGHT, lean)


func _forehead_fold(pivot: Vector3, facing: Basis) -> void:
	# Filled asymmetric ear-like folds, not a hollow target gem or glowing eye.
	var rim: Array[Vector3] = []
	for i: int in range(8):
		var angle: float = TAU * float(i) / 8.0
		rim.append(Vector3(cos(angle) * 0.045, 0.071 + sin(angle) * 0.052, -0.113))
	var crease := Vector3(0.011, 0.072, -0.131)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(8):
		_triangle(surface, rim[i], crease, rim[(i + 1) % 8], PALE_COLOR.darkened(0.035 + float(i % 3) * 0.045))
	_triangle(surface, Vector3(-0.021, 0.085, -0.133), Vector3(0.009, 0.042, -0.135), Vector3(0.016, 0.087, -0.136), PALE_COLOR.lightened(0.05))
	var view: MeshInstance3D = _surface_view("FoldedForeheadEar", surface, pivot, "earthrid")
	view.basis = facing


func _surface_view(label: String, surface: SurfaceTool, at: Vector3, role: String) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.mesh = surface.commit()
	view.material_override = _vertex_material()
	view.position = at
	add_child(view)
	_retain(label, view, role)
	return view


func _native_corners(view: MeshInstance3D) -> Array:
	var result: Array = []
	var bounds: AABB = view.mesh.get_aabb()
	var far: Vector3 = bounds.position + bounds.size
	for x: float in [bounds.position.x, far.x]:
		for y: float in [bounds.position.y, far.y]:
			for z: float in [bounds.position.z, far.z]:
				result.append(view.global_transform * Vector3(x, y, z))
	return result


func _bounds_for_role(role: String) -> AABB:
	var found: bool = false
	var low := Vector3.ZERO
	var high := Vector3.ZERO
	for retained: Dictionary in _native:
		if retained.role != role:
			continue
		for point: Vector3 in _native_corners(retained.view as MeshInstance3D):
			if not found:
				low = point
				high = point
				found = true
			else:
				low = low.min(point)
				high = high.max(point)
	return AABB(low, high - low)


func _mesh_stamp(mesh: Mesh) -> String:
	var properties: String = _property_stamp(mesh)
	if properties.is_empty():
		return ""
	var values: Array = [properties, mesh.get_aabb(), mesh.get_surface_count()]
	for surface: int in range(mesh.get_surface_count()):
		if mesh.surface_get_material(surface) != null:
			return ""
		values.append(mesh.surface_get_arrays(surface))
	return _bytes_stamp(var_to_bytes(values))


func _property_stamp(object: Object, excluded: Array = []) -> String:
	var values: Array = []
	for info: Dictionary in object.get_property_list():
		var key: String = String(info.name)
		if (int(info.usage) & PROPERTY_USAGE_STORAGE) == 0 or key in excluded or key in ["resource_name", "resource_path", "resource_local_to_scene", "script"]:
			continue
		var value: Variant = object.get(key)
		if value is Object and is_instance_valid(value):
			return ""
		values.append([key, value])
	return _bytes_stamp(var_to_bytes(values))


func _bytes_stamp(bytes: PackedByteArray) -> String:
	var digest := HashingContext.new()
	if digest.start(HashingContext.HASH_SHA256) != OK or digest.update(bytes) != OK:
		return ""
	return digest.finish().hex_encode()
