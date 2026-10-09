class_name CinderAct3MirrorShoreModules
extends Node3D
## Original render-only G07/G17/G19 shore modules, not gameplay geometry.
## Instance once per court. No collision, groups, cues, clocks or follow motion.

const API: String = "act3-mirror-shore-modules-1"
const SAFE_HALF_WIDTH: float = 7.0
const FLAT_TOP: float = 0.014
const BASALT: Color = Color("28232f")
const SLATE: Color = Color("3d3548")
const PALE: Color = Color("746d7e")
const CRYSTAL: Color = Color("8a8194")

var last_error: String = ""
var _built: bool = false
var _court_id: String = ""
var _court_z: float = 0.0
var _material: StandardMaterial3D
var _pieces: Array[Dictionary] = []


## Fixed X/Y and court-relative Z; the consumer retains its actual broad floor.
## A repeated identical build is harmless; changing an existing court is refused.
func build(court_id: String, court_z: float = 0.0) -> bool:
	if court_id.is_empty() or court_id.length() > 96 or not is_finite(court_z) or absf(court_z) > 256.0:
		last_error = "A stable court ID and finite bounded court Z are required"
		return false
	if _built:
		if court_id != _court_id or court_z != _court_z:
			last_error = "Built shore modules keep their original court placement"
			return false
		return true
	if not is_inside_tree() or global_transform != Transform3D.IDENTITY or get_child_count() != 0:
		last_error = "Build one empty live module root under the untransformed shore World"
		return false
	_court_id = court_id
	_court_z = court_z
	position.z = court_z
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.albedo_color = Color.WHITE
	# Default opaque material depth test/write remain enabled. No emission,
	# alpha fade, render-priority override, warning border or pulsing shader.
	_flat_course("WestNearSlate", Vector3(-2.45, 0.006, 1.7), false)
	_flat_course("WestFarSlate", Vector3(-5.0, 0.006, -4.9), true)
	_flat_course("EastNearSlate", Vector3(2.5, 0.006, 2.0), true)
	_flat_course("EastFarSlate", Vector3(5.05, 0.006, -3.9), false)
	for side: float in [-1.0, 1.0]:
		var label: String = "West" if side < 0.0 else "East"
		_shelf(label + "NearShelf", Vector3(side * 8.05, 0, 5.25), side, 0.32)
		_shelf(label + "FarShelf", Vector3(side * 8.1, 0, -5.7), side, 0.44)
		_spine(label + "ShortSpine", Vector3(side * 8.44, 0, 2.0), side, 0.73)
		_spine(label + "TallSpine", Vector3(side * 8.53, 0, -7.6), side, 1.05)
		_crystal_shrub(label + "NearMineral", Vector3(side * 7.92, 0, 6.7), side)
		_crystal_shrub(label + "FarMineral", Vector3(side * 7.97, 0, -2.3), side)
	_built = true
	last_error = ""
	return true


## Diagnostic native mesh extents only. They authorize no floor or camera fit.
func state() -> Dictionary:
	return {"api_revision": API, "built": _built, "court_id": _court_id, "court_z": _court_z, "error": last_error, "pieces": _pieces.duplicate(true)}


func _flat_course(label: String, at: Vector3, reverse: bool) -> void:
	# Broad irregular filled plates, without a closed bright edge. Interior
	# dressing is only 6..14mm above the existing floor; no raised obstacle.
	var contour := PackedVector2Array([
		Vector2(-1.28, -1.76), Vector2(-0.32, -2.08),
		Vector2(0.92, -1.73), Vector2(1.25, -0.59),
		Vector2(0.96, 0.74), Vector2(0.42, 1.81),
		Vector2(-0.81, 1.54), Vector2(-1.31, 0.35),
	])
	if reverse:
		for i: int in range(contour.size()):
			contour[i] = -contour[i]
	var vertices: Array[Vector3] = []
	var colors: Array[Color] = []
	var center := Vector3(0.03, 0, -0.10)
	for i: int in range(contour.size()):
		_triangle(vertices, colors, center, _ground(contour[i]), _ground(contour[(i + 1) % contour.size()]), SLATE.darkened(0.07 * float(i % 3)))
	_piece(label + "Plate", at, vertices, colors, false)
	# Two quiet filled stepped slivers suggest eroded slab laminations.
	# They remain separated, not a ring, route, chevron or interaction edge.
	var sign: float = -1.0 if reverse else 1.0
	_polygon(label + "LowPaleSlab", at + Vector3(0, 0.007, 0), PackedVector2Array([
		Vector2(-1.10, -1.39) * sign, Vector2(-0.35, -1.59) * sign,
		Vector2(0.52, -1.34) * sign, Vector2(0.47, -1.25) * sign,
		Vector2(-0.34, -1.48) * sign, Vector2(-1.02, -1.29) * sign,
	]), PALE.darkened(0.18))
	_polygon(label + "VioletBedding", at + Vector3(0, 0.008, 0), PackedVector2Array([
		Vector2(0.53, 0.83) * sign, Vector2(0.83, 0.23) * sign,
		Vector2(0.94, -0.48) * sign, Vector2(0.83, -0.39) * sign,
		Vector2(0.71, 0.21) * sign, Vector2(0.43, 0.76) * sign,
	]), Color("514458"))


func _shelf(label: String, at: Vector3, side: float, height: float) -> void:
	# The complete raised shelf, including all projecting ledge vertices,
	# is beyond ±7.3. Ordinary depth can still occlude a near-edge actor.
	var contour := PackedVector2Array([
		Vector2(-0.68, -1.74), Vector2(0.34, -1.93),
		Vector2(0.73, -1.02), Vector2(0.69, 0.42),
		Vector2(0.30, 1.83), Vector2(-0.56, 1.49),
		Vector2(-0.74, 0.14),
	])
	var vertices: Array[Vector3] = []
	var colors: Array[Color] = []
	var center := Vector3(side * 0.08, height, -0.12)
	for i: int in range(contour.size()):
		var next: int = (i + 1) % contour.size()
		var rim: Vector3 = _ground(contour[i]) + Vector3.UP * (height * (0.77 + 0.035 * float(i % 3)))
		var end: Vector3 = _ground(contour[next]) + Vector3.UP * (height * (0.77 + 0.035 * float(next % 3)))
		_triangle(vertices, colors, center, rim, end, SLATE.darkened(0.09 * float(i % 3)))
		var low: Vector3 = _ground(contour[i])
		var low_end: Vector3 = _ground(contour[next])
		# Broad dark sides with one low pale bedding facet, not a bright rim.
		if i in [0, 4]:
			var band_a: Vector3 = low.lerp(rim, 0.40)
			var band_b: Vector3 = low_end.lerp(end, 0.40)
			var upper_a: Vector3 = low.lerp(rim, 0.49)
			var upper_b: Vector3 = low_end.lerp(end, 0.49)
			# Subdivide the actual side face; no coplanar overlay/z fighting.
			_triangle(vertices, colors, low, band_a, low_end, BASALT)
			_triangle(vertices, colors, low_end, band_a, band_b, BASALT)
			_triangle(vertices, colors, band_a, upper_a, band_b, PALE.darkened(0.30))
			_triangle(vertices, colors, band_b, upper_a, upper_b, PALE.darkened(0.30))
			_triangle(vertices, colors, upper_a, rim, upper_b, BASALT)
			_triangle(vertices, colors, upper_b, rim, end, BASALT)
		else:
			_triangle(vertices, colors, low, rim, low_end, BASALT)
			_triangle(vertices, colors, low_end, rim, end, BASALT.lightened(0.025 * float(i % 3)))
	_piece(label, at, vertices, colors, true)


func _spine(label: String, at: Vector3, side: float, height: float) -> void:
	var ring: Array[Vector3] = [Vector3(-0.26, 0, -0.24), Vector3(0.22, 0, -0.29), Vector3(0.29, 0, 0.18), Vector3(-0.19, 0, 0.31)]
	var crown := Vector3(side * 0.07, height, -0.06)
	var vertices: Array[Vector3] = []
	var colors: Array[Color] = []
	for i: int in range(4):
		var next: int = (i + 1) % 4
		var shoulder: Vector3 = ring[i] * 0.68 + Vector3(side * 0.02, height * 0.72, 0)
		var shoulder_end: Vector3 = ring[next] * 0.68 + Vector3(side * 0.02, height * 0.72, 0)
		var shade: Color = BASALT.lightened(float(i % 3) * 0.035)
		_triangle(vertices, colors, ring[i], ring[next], shoulder, shade)
		_triangle(vertices, colors, ring[next], shoulder_end, shoulder, shade)
		_triangle(vertices, colors, shoulder, shoulder_end, crown, shade.lightened(0.035))
	_piece(label, at, vertices, colors, true)


func _crystal_shrub(label: String, at: Vector3, side: float) -> void:
	# One low main stem and two attached mineral arms. Inward arm extents
	# are still beyond the floor; neither facets nor tips emit/glint.
	_crystal_segment(label + "Stem", at, Vector3.ZERO, Vector3(side * 0.035, 0.57, -0.025), 0.075)
	_crystal_segment(label + "InwardArm", at, Vector3(side * 0.025, 0.25, 0), Vector3(-side * 0.28, 0.49, -0.12), 0.045)
	_crystal_segment(label + "OutwardArm", at, Vector3(side * 0.03, 0.33, -0.015), Vector3(side * 0.27, 0.67, 0.09), 0.052)


func _crystal_segment(label: String, at: Vector3, start: Vector3, tip: Vector3, radius: float) -> void:
	var axis: Vector3 = (tip - start).normalized()
	var across: Vector3 = Vector3.FORWARD.cross(axis).normalized()
	var back: Vector3 = axis.cross(across).normalized()
	var shoulder: Vector3 = start.lerp(tip, 0.74)
	var ring: Array[Vector3] = [across * radius, back * radius, -across * radius, -back * radius]
	var vertices: Array[Vector3] = []
	var colors: Array[Color] = []
	for i: int in range(4):
		var next: int = (i + 1) % 4
		var a: Vector3 = start + ring[i]
		var b: Vector3 = start + ring[next]
		# The slightly leaning first stem has a horizontal floor-cut base.
		# This is authored mesh geometry, not a collider or ground snap.
		a.y = maxf(0.0, a.y)
		b.y = maxf(0.0, b.y)
		var c: Vector3 = shoulder + ring[i] * 0.62
		var d: Vector3 = shoulder + ring[next] * 0.62
		var shade: Color = CRYSTAL.darkened(0.10 * float(i % 3))
		_triangle(vertices, colors, a, b, c, shade)
		_triangle(vertices, colors, b, d, c, shade)
		_triangle(vertices, colors, c, d, tip, shade)
	_piece(label, at, vertices, colors, true)


func _polygon(label: String, at: Vector3, contour: PackedVector2Array, color: Color) -> void:
	var vertices: Array[Vector3] = []
	var colors: Array[Color] = []
	var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(contour)
	for i: int in range(0, triangles.size(), 3):
		_triangle(vertices, colors, _ground(contour[triangles[i]]), _ground(contour[triangles[i + 1]]), _ground(contour[triangles[i + 2]]), color)
	_piece(label, at, vertices, colors, false)


func _ground(point: Vector2) -> Vector3:
	return Vector3(point.x, 0, point.y)


func _triangle(vertices: Array[Vector3], colors: Array[Color], a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	vertices.append_array([a, b, c])
	colors.append_array([color, color, color])


func _piece(label: String, at: Vector3, vertices: Array[Vector3], colors: Array[Color], raised: bool) -> void:
	var low: Vector3 = at + vertices[0]
	var high: Vector3 = low
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(vertices.size()):
		low = low.min(at + vertices[i])
		high = high.max(at + vertices[i])
		surface.set_color(colors[i])
		surface.add_vertex(vertices[i])
	var visual := MeshInstance3D.new()
	visual.name = label
	visual.mesh = surface.commit()
	visual.material_override = _material
	visual.position = at
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)
	_pieces.append({"id": label, "raised": raised, "court_bounds": AABB(low, high - low), "vertex_count": vertices.size(), "readiness": "unexecuted_native_scenery_candidate"})
