extends RefCounted
## Original static Act 2 ecology, not an enemy or an attack footprint.
## The parent owns placement, support/collision and any derived cutaway.
## Native feet pivot is local (0, 0, 0); every authored vertex is at Y >= 0.

const ART_REVISION := "a2-red-weed-1"
const VARIANTS: Array[String] = ["sparse", "dense", "bleached", "creeper"]
const SEED_FORMS: int = 8
const SIDES: int = 6
const TEXTURE_SIZE: int = 32

static var _geometry_cache: Dictionary = {}
static var _material_cache: Dictionary = {}


static func build(parent: Node3D, variant: String, seed: int = 0) -> Node3D:
	if not is_instance_valid(parent) or parent.is_queued_for_deletion():
		push_error("Red weed requires a valid parent that is not retiring.")
		return null
	if variant not in VARIANTS:
		push_error("Unsupported static red-weed variant: %s" % variant)
		return null
	var form: int = posmod(seed, SEED_FORMS)
	var key: String = "%s:%s" % [variant, form]
	if not _geometry_cache.has(key):
		_geometry_cache[key] = _geometry(variant, form)
	var pack: Dictionary = _geometry_cache[key]
	var root := Node3D.new()
	root.name = "RedWeed_%s" % variant
	root.set_meta("asset_id", "a2-red-%s" % ("creeper" if variant == "creeper" else "weed-" + variant))
	root.set_meta("art_revision", ART_REVISION)
	root.set_meta("source_ids", ["G08", "G16", "T20" if variant == "creeper" else "T19"])
	root.set_meta("variant", variant)
	root.set_meta("seed_form", form)
	root.set_meta("scenery_only", true)
	root.set_meta("grounded_feet_pivot", Vector3.ZERO)
	root.set_meta("collision_role", "none; parent-authored collision is separate")
	root.set_meta("optional_cutaway_paths", [])
	root.set_meta("native_geometry", pack["stats"].duplicate(true))
	root.set_meta("visual_bounds_local", pack["stats"]["bounds_local"])
	root.set_meta("visual_footprint_xz", pack["stats"]["footprint_xz"])
	root.set_meta("structural_base_bounds_local", pack["base_bounds"])
	root.set_meta("outboard_only", variant in ["dense", "bleached"])
	root.set_meta("geometry_shared_immutable", true)
	parent.add_child(root)
	var material_kind: String = "bleached" if variant == "bleached" else ("creeper" if variant == "creeper" else "living")
	_part(root, "StructuralFronds" if variant != "creeper" else "ClimbingStems", pack["structure"] as ArrayMesh, material_kind)
	_part(root, "BranchTips" if variant != "creeper" else "ClimbingFilaments", pack["tips"] as ArrayMesh, material_kind)
	return root


static func _part(root: Node3D, label: String, mesh: ArrayMesh, material_kind: String) -> void:
	var part := MeshInstance3D.new()
	part.name = label
	part.mesh = mesh
	# Textures and geometry are immutable caches. Each mesh owns its material;
	# a parent cutaway can alter this override without affecting any neighbour.
	part.material_override = _material(material_kind).duplicate() as StandardMaterial3D
	part.set_meta("weybridge_cutaway_candidate", true)
	part.set_meta("static_ecology", true)
	root.add_child(part)
	var paths: Array = root.get_meta("optional_cutaway_paths", [])
	paths.append(str(root.get_path_to(part)))
	root.set_meta("optional_cutaway_paths", paths)


static func _geometry(variant: String, form: int) -> Dictionary:
	var segments: Array[Dictionary] = _creeper_segments(form) if variant == "creeper" else _frond_segments(variant, form)
	var structure := _parcel()
	var tips := _parcel()
	var bases: Array[Vector3] = []
	var phase: float = float(form) * TAU / float(SEED_FORMS)
	# The fine creeper has a wall-facing XY habit, never a bulky water-frond root.
	var yaw: float = 0.0 if variant == "creeper" else phase
	var basis := Basis(Vector3.UP, yaw)
	for segment: Dictionary in segments:
		var a: Vector3 = basis * (segment["a"] as Vector3)
		var b: Vector3 = basis * (segment["b"] as Vector3)
		var target: Dictionary = structure if int(segment["part"]) == 0 else tips
		_segment(target, a, b, float(segment["r0"]), float(segment["r1"]), float(segment["facet_phase"]))
		if bool(segment.get("rooted", false)):
			# Inspectable rooted flare bounds include actual foot-ring vertices.
			for vertex: Vector3 in target["vertices"]:
				if vertex.y <= 0.00001:
					bases.append(vertex)
	var all_vertices: Array[Vector3] = []
	all_vertices.append_array(structure["vertices"])
	all_vertices.append_array(tips["vertices"])
	var bounds: AABB = _bounds(all_vertices)
	var radius: float = 0.0
	for vertex: Vector3 in all_vertices:
		radius = maxf(radius, Vector2(vertex.x, vertex.z).length())
	var stats: Dictionary = {
		"bounds_local": bounds,
		"footprint_xz": Rect2(Vector2(bounds.position.x, bounds.position.z), Vector2(bounds.size.x, bounds.size.z)),
		"top_y": bounds.end.y,
		"minimum_y": bounds.position.y,
		"max_radius_xz": radius,
		"segment_count": segments.size(),
		"vertex_count": all_vertices.size(),
		"triangle_count": int(all_vertices.size() / 3.0),
		"mesh_count": 2,
		"native_scale": Vector3.ONE,
		"clock": "none; static authored variant",
	}
	return {"structure": _mesh(structure), "tips": _mesh(tips), "stats": stats, "base_bounds": _bounds(bases)}


static func _frond_segments(variant: String, form: int) -> Array[Dictionary]:
	# Bulky, crooked, rising water-loving fronds. Asymmetrical lateral forks
	# preserve the cactus-like branching instead of fern leaves or flower balls.
	var stems: Array = [
		[Vector3(-0.16, 0.0, -0.08), Vector3(-0.22, 0.50, -0.06), Vector3(-0.05, 1.02, 0.02), Vector3(0.32, 1.38, 0.16)],
		[Vector3(0.10, 0.0, 0.08), Vector3(0.24, 0.46, 0.12), Vector3(0.52, 0.89, 0.20), Vector3(0.86, 1.02, 0.24)],
		[Vector3(0.08, 0.0, -0.15), Vector3(0.00, 0.40, -0.26), Vector3(-0.30, 0.86, -0.34), Vector3(-0.70, 0.96, -0.30)],
		[Vector3(-0.20, 0.0, 0.18), Vector3(-0.32, 0.55, 0.25), Vector3(-0.60, 1.21, 0.30), Vector3(-0.42, 1.88, 0.34)],
		[Vector3(0.18, 0.0, -0.19), Vector3(0.35, 0.61, -0.28), Vector3(0.22, 1.26, -0.41), Vector3(0.53, 1.66, -0.45)],
	]
	var radii: Array[float] = [0.085, 0.068, 0.075, 0.090, 0.080]
	var count: int = 3 if variant == "sparse" else 5
	var segments: Array[Dictionary] = []
	var bleached: bool = variant == "bleached"
	var bend: float = float(form % 3 - 1) * 0.035
	for index: int in range(count):
		var path: Array[Vector3] = []
		for point: Vector3 in stems[index]:
			var posed: Vector3 = point + Vector3(bend * point.y, 0.0, bend * float(index % 2) * point.y)
			if bleached:
				# Static brittle collapse: shorter stalks, splayed tips and droop.
				posed = Vector3(posed.x * 1.08, posed.y * 0.72, posed.z * 1.10)
			path.append(posed)
		for step: int in range(3):
			var r0: float = radii[index] * (1.0 - float(step) * 0.25)
			var r1: float = radii[index] * (0.75 - float(step) * 0.24)
			_add(segments, path[step], path[step + 1], r0, r1, 0, index, step == 0)
		for step: int in [1, 2]:
			var start: Vector3 = path[step]
			var side: float = -1.0 if (index + step + form) % 2 == 0 else 1.0
			var reach: float = 0.24 + float((index + step) % 3) * 0.075
			var elbow: Vector3 = start + Vector3(side * reach, 0.17 if not bleached else 0.065, 0.10 + float(index % 2) * 0.055)
			var finish: Vector3 = elbow + Vector3(side * 0.17, 0.17 if not bleached else -0.095, -0.045)
			_add(segments, start, elbow, 0.034, 0.023, 1, index + step)
			_add(segments, elbow, finish, 0.023, 0.009, 1, index + step + 1)
			# Short secondary forks have intentionally visible woody width.
			_add(segments, elbow, elbow + Vector3(-side * 0.085, 0.18 if not bleached else -0.12, 0.12), 0.016, 0.006, 1, index + 2)
			_add(segments, start, start + Vector3(-side * 0.18, 0.085 if not bleached else -0.065, -0.13), 0.021, 0.007, 1, index + 3)
		var crown: Vector3 = path[3]
		_add(segments, crown, crown + Vector3(-0.10, 0.14 if not bleached else -0.17, 0.09), 0.014, 0.005, 1, index)
	return segments


static func _creeper_segments(form: int) -> Array[Dictionary]:
	# T20 fine climbing strands remain distinct from the T19 water-loving weed.
	# Local +Z is the display/front of the wall; no wall or collider is created.
	var segments: Array[Dictionary] = []
	var starts: Array[float] = [-0.40, -0.15, 0.18, 0.40]
	for index: int in range(4):
		var path: Array[Vector3] = [Vector3(starts[index], 0.0, 0.035)]
		for step: int in range(1, 5):
			var side: float = -1.0 if (index + step + form) % 2 == 0 else 1.0
			path.append(Vector3(starts[index] + side * (0.07 + float(step % 2) * 0.05), float(step) * 0.405, 0.035 + float((step + index) % 3) * 0.012))
		for step: int in range(4):
			_add(segments, path[step], path[step + 1], 0.018 - float(step) * 0.0025, 0.015 - float(step) * 0.0025, 0, index, step == 0)
		for step: int in [1, 2, 3]:
			var side: float = -1.0 if (index + step + form) % 2 == 0 else 1.0
			var start: Vector3 = path[step]
			var hook: Vector3 = start + Vector3(side * 0.17, 0.09, 0.012)
			_add(segments, start, hook, 0.011, 0.007, 1, step)
			_add(segments, hook, hook + Vector3(side * 0.065, -0.10, 0.008), 0.007, 0.0045, 1, step + 1)
	return segments


static func _add(segments: Array[Dictionary], a: Vector3, b: Vector3, r0: float, r1: float, part: int, form: int, rooted: bool = false) -> void:
	segments.append({"a": a, "b": b, "r0": r0, "r1": r1, "part": part, "facet_phase": float(form % 3) * PI / 9.0, "rooted": rooted})


static func _parcel() -> Dictionary:
	var vertices: Array[Vector3] = []
	var normals: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	return {"vertices": vertices, "normals": normals, "uvs": uvs}


static func _segment(parcel: Dictionary, a: Vector3, b: Vector3, bottom: float, top: float, facet_phase: float) -> void:
	var axis: Vector3 = (b - a).normalized()
	var reference: Vector3 = Vector3.FORWARD if absf(axis.dot(Vector3.UP)) > 0.9 else Vector3.UP
	var u: Vector3 = axis.cross(reference).normalized()
	var v: Vector3 = axis.cross(u).normalized()
	for face: int in range(SIDES):
		var angle0: float = float(face) * TAU / float(SIDES) + facet_phase
		var angle1: float = float(face + 1) * TAU / float(SIDES) + facet_phase
		var ring0: Vector3 = u * cos(angle0) + v * sin(angle0)
		var ring1: Vector3 = u * cos(angle1) + v * sin(angle1)
		var a0: Vector3 = a + ring0 * bottom
		var a1: Vector3 = a + ring1 * bottom
		var b0: Vector3 = b + ring0 * top
		var b1: Vector3 = b + ring1 * top
		# Root rings are flattened against Y0 so tilted bases never float below
		# the support. Normals derive from final triangles after this flattening.
		a0.y = maxf(0.0, a0.y)
		a1.y = maxf(0.0, a1.y)
		b0.y = maxf(0.0, b0.y)
		b1.y = maxf(0.0, b1.y)
		var uv0 := Vector2(float(face) / float(SIDES), a.y * 2.0)
		var uv1 := Vector2(float(face + 1) / float(SIDES), a.y * 2.0)
		var uv2 := Vector2(float(face + 1) / float(SIDES), b.y * 2.0)
		var uv3 := Vector2(float(face) / float(SIDES), b.y * 2.0)
		_triangle(parcel, a0, a1, b1, uv0, uv1, uv2)
		_triangle(parcel, a0, b1, b0, uv0, uv2, uv3)
		_triangle(parcel, a, a1, a0, Vector2(0.5, 0.5), Vector2(1.0, 0.0), Vector2.ZERO)
		_triangle(parcel, b, b0, b1, Vector2(0.5, 0.5), Vector2.ZERO, Vector2(1.0, 0.0))


static func _triangle(parcel: Dictionary, a: Vector3, b: Vector3, c: Vector3, uv_a: Vector2, uv_b: Vector2, uv_c: Vector2) -> void:
	var normal: Vector3 = (b - a).cross(c - a)
	# Flattened ground cap triangles can be degenerate; omit them quietly.
	if normal.length_squared() <= 0.00000000000001:
		return
	normal = normal.normalized()
	parcel["vertices"].append_array([a, b, c])
	parcel["normals"].append_array([normal, normal, normal])
	parcel["uvs"].append_array([uv_a, uv_b, uv_c])


static func _mesh(parcel: Dictionary) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(parcel["vertices"])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(parcel["normals"])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(parcel["uvs"])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _bounds(vertices: Array[Vector3]) -> AABB:
	if vertices.is_empty():
		return AABB()
	var bounds := AABB(vertices[0], Vector3.ZERO)
	for vertex: Vector3 in vertices:
		bounds = bounds.expand(vertex)
	return bounds


static func _material(kind: String) -> StandardMaterial3D:
	if _material_cache.has(kind):
		return _material_cache[kind] as StandardMaterial3D
	var palette: Array[Color] = [Color("633328"), Color("793b30"), Color("99493b"), Color("422c27")]
	if kind == "bleached":
		palette = [Color("a19580"), Color("b8ad96"), Color("8b816e"), Color("736852")]
	elif kind == "creeper":
		palette = [Color("6c382d"), Color("864034"), Color("a64b3a"), Color("452d27")]
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	for y: int in range(TEXTURE_SIZE):
		for x: int in range(TEXTURE_SIZE):
			var cluster: int = posmod((x >> 2) * 17 + (y >> 2) * 29 + x * y, 23)
			var index: int = 0 if cluster < 14 else (1 if cluster < 19 else 2)
			if x % 8 == 0 and y % 5 != 0:
				index = 3
			image.set_pixel(x, y, palette[index])
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 0.94
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	_material_cache[kind] = material
	return material
