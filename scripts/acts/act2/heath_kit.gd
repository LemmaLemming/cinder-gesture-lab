extends RefCounted
## Original Horsell Common scenery. No actor, collider, hazard, or autonomous clock.
## The caller supplies tableau state/progress from its paused simulation clock.

const ART_REVISION := "a2-horsell-heath-2"
const ACTOR_PIXEL_SIZE := 0.0225
const TILE_WORLD_SIZE := 1.44
const CYLINDER_ANCHOR := Vector3(-4.8, 0.0, -1.0)
const CYLINDER_YAW := -0.55
const WITNESS_POSITIONS: Array[Vector3] = [
	Vector3(-3.45, 0.975, 0.8), Vector3(3.45, 0.975, 0.8),
	Vector3(-2.5, 0.975, 3.85), Vector3(-1.8, 0.975, 3.85),
	Vector3(1.8, 0.975, 3.85), Vector3(2.5, 0.975, 3.85),
]
static var _material_cache: Dictionary = {}
static var _texture_cache: Dictionary = {}
static var _mesh_cache: Dictionary = {}

static func build(parent: Node3D) -> Dictionary:
	assert(parent != null, "Horsell scenery requires a level-owned parent.")
	var root := Node3D.new()
	root.name = "HorsellHeathKit"
	root.set_meta("art_revision", ART_REVISION)
	parent.add_child(root)
	_ground(root)
	_road_edges(root)
	for side: int in [-1, 1]:
		for index: int in range(5):
			var z: float = -2.8 - float(index) * 5.4
			_pine(root, Vector3(float(side) * 4.8, 0.0, z), side, index)
			_log(root, Vector3(float(side) * 4.65, 0.0, z + 1.4), side, index)
		for index: int in range(14):
			var z: float = 2.4 - float(index) * 2.2
			var x: float = float(side) * (4.3 + float(index % 3) * 0.24)
			_heather(root, Vector3(x, 0.025, z), index % 3)
		for index: int in range(3):
			_cottage(root, Vector3(float(side) * (6.3 + float(index % 2) * 0.7), 0.0, -6.5 - float(index) * 10.2), side, index)
	# Cropped bank-top heather is visible without occupying landing floor.
	for side: int in [-1, 1]:
		for z: float in [-1.5, -5.6, -11.0, -15.7, -22.0, -26.0]:
			_heather(root, Vector3(float(side) * 3.75, 0.975, z), 1)
		for z: float in [-18.4, -29.0]:
			_heather(root, Vector3(float(side) * 3.25, 0.975, z), 2)
		for z: float in [7.0, 10.0]:
			_heather(root, Vector3(float(side) * 2.8, 0.025, z), 0)
	_cylinder_landmark(root)
	var witnesses: Array[Node3D] = []
	for index: int in range(WITNESS_POSITIONS.size()):
		var position: Vector3 = WITNESS_POSITIONS[index]
		var side: int = -1 if position.x < 0.0 else 1
		var witness := _witness(root, position, index, side)
		if index < 2:
			# These two retreat along the side-bank top instead of floating off it.
			witness.set_meta("retreat_direction", Vector3.BACK)
		witnesses.append(witness)
	var eruption := _eruption(root)
	var kit: Dictionary = {"root": root, "witnesses": witnesses, "eruption": eruption}
	set_tableau(kit, "arrival", 0.0)
	set_eruption(kit, false, 0.0)
	return kit

static func set_tableau(kit: Dictionary, state: String, progress: float = 0.0) -> void:
	## No elapsed-time sampling here: the level supplies normalized simulation progress.
	var phase: float = clampf(progress, 0.0, 1.0)
	var witnesses: Array = kit.get("witnesses", [])
	for candidate: Variant in witnesses:
		var witness := candidate as Node3D
		if not is_instance_valid(witness):
			continue
		var home: Vector3 = witness.get_meta("home_position", Vector3.ZERO)
		var direction: Vector3 = witness.get_meta("retreat_direction", Vector3.ZERO)
		witness.position = home + direction * (phase * 1.2 if state == "retreat" else 0.0)
		witness.visible = state == "arrival" or (state == "retreat" and phase < 1.0)
	var root := kit.get("root") as Node3D
	if is_instance_valid(root):
		root.set_meta("tableau_state", state)
		root.set_meta("tableau_progress", phase)

static func set_eruption(kit: Dictionary, visible: bool, normalized_progress: float = 0.0) -> void:
	## Independent from witnesses so level snapshots can restore both visual states.
	var phase: float = clampf(normalized_progress, 0.0, 1.0)
	var eruption := kit.get("eruption") as Node3D
	if not is_instance_valid(eruption):
		return
	eruption.visible = visible and phase > 0.0 and phase < 1.0
	eruption.set_meta("eruption_progress", phase)
	for child: Node in eruption.get_children():
		var puff := child as Node3D
		if puff == null:
			continue
		var index: int = int(puff.get_meta("puff_index", 0))
		var home: Vector3 = puff.get_meta("home_position", Vector3.ZERO)
		puff.position = home + Vector3(0.0, phase * (1.0 + float(index) * 0.15), 0.0)
		var breadth: float = 0.45 + sin(phase * PI) * (0.5 + float(index % 3) * 0.12)
		puff.scale = Vector3(breadth, 0.6 + phase * 0.9, breadth)
		var mesh_puff := puff as MeshInstance3D
		if mesh_puff != null:
			var material := mesh_puff.material_override as StandardMaterial3D
			if material != null:
				var tint: Color = material.albedo_color
				tint.a = smoothstep(0.0, 0.08, phase) * (1.0 - smoothstep(0.65, 1.0, phase)) * 0.58
				material.albedo_color = tint

static func _ground(root: Node3D) -> void:
	# Far-side terrain is scenery behind the caller's visible end banks, not route.
	_plane(root, "ForegroundHeathBeyondEndBank", Vector3(0.0, 0.002, 8.8), Vector2(16.0, 10.4), "heath")
	_plane(root, "FarHeathBeyondWokingBank", Vector3(0.0, 0.002, -36.1), Vector2(16.0, 11.8), "heath")
	_plane(root, "ForegroundQuietSand", Vector3(0.0, 0.006, 6.7), Vector2(7.0, 5.6), "sand")
	_plane(root, "WokingQuietSand", Vector3(0.0, 0.006, -33.5), Vector2(7.0, 5.6), "sand")
	# Route overlays exactly match the union of the caller's continuous dry floor.
	_plane(root, "PaleSandFloor", Vector3(0.0, 0.004, -7.0), Vector2(6.8, 21.2), "sand")
	_plane(root, "ReunionRoadFloor", Vector3(0.0, 0.004, -18.4), Vector2(5.8, 1.6), "sand")
	_plane(root, "DepartureFloor", Vector3(0.0, 0.004, -23.4), Vector2(6.8, 8.4), "sand")
	_plane(root, "WokingRoadFloor", Vector3(0.0, 0.004, -28.9), Vector2(5.8, 2.6), "road")
	for z: float in [0.0, -13.2, -23.4]:
		_plane(root, "ClearingSand", Vector3(0.0, 0.008, z), Vector2(6.4, 5.8), "sand_clear")
	_plane(root, "WornRoad", Vector3(0.0, 0.010, -6.5), Vector2(2.6, 6.0), "road")
	for side: int in [-1, 1]:
		_plane(root, "HeathMargin", Vector3(float(side) * 5.3, 0.006, -13.3), Vector2(2.9, 33.8), "heath")
		for index: int in range(5):
			var z: float = -1.0 - float(index) * 6.0
			_plane(root, "StaticScorch", Vector3(float(side) * 4.45, 0.011, z), Vector2(0.9, 1.4), "scorch")

static func _road_edges(root: Node3D) -> void:
	for side: int in [-1, 1]:
		for index: int in range(12):
			var position := Vector3(float(side) * 4.0, 0.05, 2.6 - float(index) * 2.7)
			var stone := _box(root, "QuietRoadStone", position, Vector3(0.22, 0.10, 0.28 + float(index % 3) * 0.08), _material("stone"))
			stone.rotation.y = float(side) * (0.12 + float(index % 3) * 0.10)
		for z: float in [-5.0, -17.0, -28.0]:
			var post := _cylinder(root, "WeatheredRoadPost", Vector3(float(side) * 4.2, 0.35, z), 0.075, 0.055, 0.7, _material("wood"), 6)
			post.rotation.z = float(side) * 0.06

static func _pine(root: Node3D, position: Vector3, side: int, variant: int) -> void:
	var pine := Node3D.new()
	pine.name = "Pine_%s_%s" % [side, variant]
	pine.position = position
	root.add_child(pine)
	var height: float = 3.4 + float(variant % 3) * 0.25
	var trunk := _cylinder(pine, "TaperedBarkTrunk", Vector3(0.0, height * 0.5, 0.0), 0.17, 0.055, height, _material("bark"), 7)
	trunk.rotation.z = float(side) * 0.035
	# Outboard crowns leave the floor edge and landing pockets unobstructed.
	for index: int in range(3):
		var radius: float = 0.86 - float(index) * 0.18
		var crown := _cylinder(pine, "OutboardCrown", Vector3(float(side) * 0.58, 2.0 + float(index) * 0.65, 0.0), radius, 0.0, 1.55, _material("pine"), 7)
		crown.rotation.y = float(variant + index) * 0.31
	_branch(pine, Vector3(0.0, 1.7, 0.0), Vector3(float(side) * 0.62, 2.1, -0.35), 0.065, _material("bark"), "OutboardBranch")

static func _log(root: Node3D, position: Vector3, side: int, variant: int) -> void:
	var log_root := Node3D.new()
	log_root.name = "CharredLog_%s_%s" % [side, variant]
	log_root.position = position
	log_root.rotation.y = float(side) * (0.12 + float(variant % 2) * 0.09)
	root.add_child(log_root)
	_branch(log_root, Vector3(0.0, 0.13, -0.75), Vector3(0.0, 0.13, 0.75), 0.13, _material("char"), "BurnedTrunk")
	_branch(log_root, Vector3(0.0, 0.16, -0.25), Vector3(float(side) * 0.26, 0.29, -0.55), 0.045, _material("char"), "BrokenLimb")
	_branch(log_root, Vector3(0.0, 0.14, 0.4), Vector3(float(side) * 0.24, 0.24, 0.65), 0.035, _material("char"), "BurnedTwig")

static func _heather(root: Node3D, position: Vector3, variant: int) -> void:
	var sprite := Sprite3D.new()
	sprite.name = "SparseRustHeather"
	sprite.position = position
	sprite.pixel_size = ACTOR_PIXEL_SIZE
	sprite.offset = Vector2(0.0, 12.0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.5
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.texture = _heather_texture(variant)
	root.add_child(sprite)

static func _cylinder_landmark(root: Node3D) -> void:
	var landmark := Node3D.new()
	landmark.name = "OxidisedCylinderLandmark"
	landmark.position = CYLINDER_ANCHOR
	landmark.rotation.y = CYLINDER_YAW
	root.add_child(landmark)
	# Ground anchor is near the mouth; the six-unit barrel extends away from play.
	var mouth_x: float = 1.15
	var axis_height: float = 0.55
	var shell := _cylinder(landmark, "OpenSixUnitShell", Vector3(mouth_x - 3.0, axis_height, 0.0), 1.35, 1.35, 6.0, _material("metal"), 24, false)
	shell.rotation.z = -PI * 0.5
	var cavity := _cylinder(landmark, "RecessedDarkMouth", Vector3(mouth_x - 0.12, axis_height, 0.0), 1.235, 1.235, 0.035, _material("cavity"), 24)
	cavity.rotation.z = -PI * 0.5
	for index: int in range(5):
		var collar := _torus(landmark, "ThreadedMouthCollar", Vector3(mouth_x - float(index) * 0.09, axis_height, 0.0), 1.24, 1.35, _material("rim"))
		collar.rotation.z = -PI * 0.5
	for offset: float in [0.9, 2.8, 5.45]:
		var band := _torus(landmark, "ShellRivetBand", Vector3(mouth_x - offset, axis_height, 0.0), 1.315, 1.395, _material("rim"))
		band.rotation.z = -PI * 0.5
	for ring_x: float in [mouth_x + 0.045, mouth_x - 0.84]:
		for index: int in range(24):
			var angle: float = float(index) * TAU / 24.0
			var position := Vector3(ring_x, axis_height + cos(angle) * 1.29, sin(angle) * 1.29)
			if position.y < 0.12:
				continue
			var rivet := _cylinder(landmark, "RaisedRivet", position, 0.057, 0.057, 0.075, _material("fastener"), 6)
			rivet.rotation.z = -PI * 0.5
	for index: int in range(4):
		var mound := _sphere(landmark, "ExcavatedSandHeap", Vector3(mouth_x - 0.25 - float(index) * 1.6, 0.08, 1.05 if index % 2 == 0 else -1.05), _material("sand"))
		mound.scale = Vector3(0.65, 0.28, 0.65)
	var lid_root := Node3D.new()
	lid_root.name = "DetachedThreadedLid"
	lid_root.position = Vector3(-0.1, 0.16, 3.0)
	lid_root.rotation.z = -0.10
	landmark.add_child(lid_root)
	_cylinder(lid_root, "LidPlate", Vector3.ZERO, 1.35, 1.35, 0.18, _material("metal"), 24)
	_torus(lid_root, "LidRaisedRim", Vector3(0.0, 0.13, 0.0), 1.21, 1.35, _material("rim"))
	_torus(lid_root, "LidInnerThread", Vector3(0.0, 0.15, 0.0), 1.02, 1.09, _material("fastener"))
	for index: int in range(16):
		var angle: float = float(index) * TAU / 16.0
		_cylinder(lid_root, "LidRivet", Vector3(cos(angle) * 1.25, 0.17, sin(angle) * 1.25), 0.053, 0.053, 0.07, _material("fastener"), 6)

static func _cottage(root: Node3D, position: Vector3, side: int, variant: int) -> void:
	var cottage := Node3D.new()
	cottage.name = "VictorianCottage_%s_%s" % [side, variant]
	cottage.position = position
	cottage.rotation.y = float(side) * 0.12
	root.add_child(cottage)
	_box(cottage, "MasonryFacade", Vector3(0.0, 0.75, 0.0), Vector3(1.6, 1.5, 1.25), _material("brick"))
	var roof := _mesh(cottage, "PitchedSlateRoof", Vector3(0.0, 1.5, 0.0), _roof_mesh(), _material("slate"))
	roof.scale = Vector3(1.85, 0.6, 1.50)
	_box(cottage, "ChimneyStack", Vector3(0.46, 2.0, -0.18), Vector3(0.23, 0.58, 0.24), _material("brick"))
	_box(cottage, "ChimneyLip", Vector3(0.46, 2.3, -0.18), Vector3(0.29, 0.10, 0.30), _material("stone"))
	_box(cottage, "DarkTimberDoor", Vector3(0.0, 0.38, 0.635), Vector3(0.29, 0.76, 0.045), _material("wood"))
	for x: float in [-0.5, 0.5]:
		_box(cottage, "SashRecess", Vector3(x, 0.85, 0.648), Vector3(0.31, 0.43, 0.03), _material("window"))
		_box(cottage, "SashVertical", Vector3(x, 0.85, 0.671), Vector3(0.025, 0.43, 0.028), _material("ash_wood"))
		_box(cottage, "SashHorizontal", Vector3(x, 0.85, 0.675), Vector3(0.31, 0.025, 0.028), _material("ash_wood"))
		_box(cottage, "WindowSill", Vector3(x, 0.61, 0.67), Vector3(0.37, 0.055, 0.08), _material("stone"))

static func _witness(root: Node3D, position: Vector3, variant: int, side: int) -> Node3D:
	var witness := Node3D.new()
	witness.name = "NonhostileWitness_%s" % variant
	witness.position = position
	witness.set_meta("home_position", position)
	witness.set_meta("retreat_direction", Vector3(float(side), 0.0, 0.0))
	root.add_child(witness)
	var sprite := Sprite3D.new()
	sprite.name = "FeetAnchoredCostume"
	sprite.pixel_size = ACTOR_PIXEL_SIZE
	sprite.offset = Vector2(0.0, 32.0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.5
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.texture = _witness_texture(variant)
	witness.add_child(sprite)
	_cylinder(witness, "ContactShadow", Vector3(0.0, -0.009, 0.0), 0.22, 0.22, 0.009, _material("shadow"), 8)
	return witness

static func _eruption(root: Node3D) -> Node3D:
	var eruption := Node3D.new()
	eruption.name = "HarmlessDistantEruption"
	eruption.position = CYLINDER_ANCHOR + Vector3(cos(CYLINDER_YAW) * 1.15, 0.6, -sin(CYLINDER_YAW) * 1.15)
	root.add_child(eruption)
	for index: int in range(6):
		var position := Vector3(-0.15 - float(index % 2) * 0.18, float(index) * 0.23, float(index % 3 - 1) * 0.18)
		# Only these per-instance materials change opacity; cached materials stay immutable.
		var material := _material("vapour").duplicate() as StandardMaterial3D
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var puff := _sphere(eruption, "AshVapourPuff", position, material)
		puff.set_meta("home_position", position)
		puff.set_meta("puff_index", index)
	return eruption

static func _plane(parent: Node3D, label: String, position: Vector3, size: Vector2, kind: String) -> MeshInstance3D:
	var key: String = "plane:%s" % size
	var plane: PlaneMesh = _mesh_cache.get(key) as PlaneMesh
	if plane == null:
		plane = PlaneMesh.new()
		plane.size = size
		_mesh_cache[key] = plane
	var material_key: String = "surface:%s:%s" % [kind, size]
	var material := _material_cache.get(material_key) as StandardMaterial3D
	if material == null:
		material = _material(kind).duplicate() as StandardMaterial3D
		material.uv1_scale = Vector3(size.x / TILE_WORLD_SIZE, size.y / TILE_WORLD_SIZE, 1.0)
		_material_cache[material_key] = material
	return _mesh(parent, label, position, plane, material)

static func _box(parent: Node3D, label: String, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var key: String = "box:%s" % size
	var box := _mesh_cache.get(key) as BoxMesh
	if box == null:
		box = BoxMesh.new()
		box.size = size
		_mesh_cache[key] = box
	return _mesh(parent, label, position, box, material)

static func _cylinder(parent: Node3D, label: String, position: Vector3, bottom: float, top: float, height: float, material: Material, segments: int = 12, cap_top: bool = true) -> MeshInstance3D:
	var key: String = "cylinder:%s:%s:%s:%s:%s" % [bottom, top, height, segments, cap_top]
	var cylinder := _mesh_cache.get(key) as CylinderMesh
	if cylinder == null:
		cylinder = CylinderMesh.new()
		cylinder.bottom_radius = bottom
		cylinder.top_radius = top
		cylinder.height = height
		cylinder.radial_segments = segments
		cylinder.rings = 1
		cylinder.cap_top = cap_top
		_mesh_cache[key] = cylinder
	return _mesh(parent, label, position, cylinder, material)

static func _torus(parent: Node3D, label: String, position: Vector3, inner: float, outer: float, material: Material) -> MeshInstance3D:
	var key: String = "torus:%s:%s" % [inner, outer]
	var torus := _mesh_cache.get(key) as TorusMesh
	if torus == null:
		torus = TorusMesh.new()
		torus.inner_radius = inner
		torus.outer_radius = outer
		torus.rings = 24
		torus.ring_segments = 5
		_mesh_cache[key] = torus
	return _mesh(parent, label, position, torus, material)

static func _sphere(parent: Node3D, label: String, position: Vector3, material: Material) -> MeshInstance3D:
	var sphere := _mesh_cache.get("sphere") as SphereMesh
	if sphere == null:
		sphere = SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		sphere.radial_segments = 8
		sphere.rings = 4
		_mesh_cache["sphere"] = sphere
	return _mesh(parent, label, position, sphere, material)

static func _branch(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material, label: String) -> void:
	var delta: Vector3 = end - start
	var branch := _cylinder(parent, label, (start + end) * 0.5, radius, radius * 0.62, delta.length(), material, 6)
	branch.quaternion = Quaternion(Vector3.UP, delta.normalized())

static func _mesh(parent: Node3D, label: String, position: Vector3, mesh: Mesh, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.position = position
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance

static func _roof_mesh() -> ArrayMesh:
	var cached := _mesh_cache.get("gable_roof") as ArrayMesh
	if cached != null:
		return cached
	var points: Array[Vector3] = [Vector3(-0.5, 0.0, -0.5), Vector3(-0.5, 0.0, 0.5), Vector3(0.0, 1.0, -0.5), Vector3(0.0, 1.0, 0.5), Vector3(0.5, 0.0, -0.5), Vector3(0.5, 0.0, 0.5)]
	var faces: Array[Vector3i] = [Vector3i(0, 1, 2), Vector3i(2, 1, 3), Vector3i(2, 3, 4), Vector3i(4, 3, 5), Vector3i(0, 2, 4), Vector3i(1, 5, 3)]
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	for face: Vector3i in faces:
		var a: Vector3 = points[face.x]
		var b: Vector3 = points[face.y]
		var c: Vector3 = points[face.z]
		var normal: Vector3 = (c - a).cross(b - a).normalized()
		for point: Vector3 in [a, b, c]:
			vertices.append(point)
			normals.append(normal)
			uv.append(Vector2(point.x + 0.5, point.z + 0.5 + point.y * 0.5))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var roof := ArrayMesh.new()
	roof.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_mesh_cache["gable_roof"] = roof
	return roof

static func _material(kind: String) -> StandardMaterial3D:
	var cached := _material_cache.get(kind) as StandardMaterial3D
	if cached != null:
		return cached
	var palette: Array[Color] = []
	match kind:
		"sand": palette = [Color("b5a58c"), Color("b0a087"), Color("bcad94"), Color("978b79")]
		"sand_clear": palette = [Color("bdaf97"), Color("b9ab94"), Color("c0b29d"), Color("a49884")]
		"road": palette = [Color("a89881"), Color("a29179"), Color("b09f88"), Color("928674")]
		"heath": palette = [Color("706354"), Color("635c50"), Color("7c6853"), Color("675448")]
		"scorch": palette = [Color("554a40"), Color("50483f"), Color("645346"), Color("49433c")]
		"metal": palette = [Color("4c514f"), Color("353b3b"), Color("75523d"), Color("918878")]
		"rim": palette = [Color("5f625a"), Color("404741"), Color("815d44"), Color("a79b81")]
		"fastener": palette = [Color("837e6a"), Color("555e55"), Color("9c9177"), Color("695845")]
		"cavity": palette = [Color("181d1b"), Color("151a18"), Color("222722"), Color("1a211d")]
		"bark": palette = [Color("433c30"), Color("2f3029"), Color("645440"), Color("4b4535")]
		"pine": palette = [Color("333b30"), Color("293329"), Color("444c36"), Color("303629")]
		"char": palette = [Color("302d28"), Color("272824"), Color("494137"), Color("36332d")]
		"wood": palette = [Color("5a4938"), Color("413b30"), Color("786046"), Color("564934")]
		"ash_wood": palette = [Color("b1a48c"), Color("928b79"), Color("bcb19b"), Color("a29681")]
		"stone": palette = [Color("817a6b"), Color("6f6c61"), Color("968a76"), Color("747166")]
		"brick": palette = [Color("765442"), Color("674f41"), Color("85634d"), Color("645345")]
		"slate": palette = [Color("41494a"), Color("353e40"), Color("55605d"), Color("444e4d")]
		"window": palette = [Color("333c38"), Color("2d3532"), Color("596257"), Color("434c44")]
		"vapour": palette = [Color("72796b"), Color("636b5e"), Color("8a8f7b"), Color("6e7666")]
		"shadow": palette = [Color("524e43"), Color("524e43"), Color("524e43"), Color("524e43")]
		_: palette = [Color("8e8170"), Color("7f7568"), Color("9a8d78"), Color("867b6d")]
	var width: int = 64
	var height: int = 64
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y: int in range(height):
		for x: int in range(width):
			var cluster: int = posmod((x >> 2) * 17 + (y >> 2) * 31 + kind.length() * 7, 29)
			var detail: int = posmod(x * 37 + y * 73 + x * y * 13, 997)
			var index: int = 0
			if kind in ["metal", "rim", "fastener"]:
				index = 2 if cluster < 6 else (1 if cluster > 24 else 0)
				if y % 24 == 0 and detail < 350:
					index = 3
			elif kind in ["wood", "bark", "char"]:
				index = 1 if x % 9 < 2 else (2 if cluster == 7 else 0)
			elif kind == "brick":
				index = 3 if y % 8 == 0 or posmod(x + (8 if (y >> 3) % 2 == 0 else 0), 16) == 0 else (2 if cluster < 4 else 0)
			elif kind == "slate":
				index = 1 if y % 8 < 2 else (2 if cluster == 9 else 0)
			else:
				# Sparse, low-contrast clustered marks preserve a quiet combat floor.
				index = 1 if cluster < 3 else (2 if cluster == 8 else 0)
				if detail < 9:
					index = 3
			image.set_pixel(x, y, palette[index])
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 0.92
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material_cache[kind] = material
	return material

static func _heather_texture(variant: int) -> Texture2D:
	var key: String = "heather:%s" % variant
	var cached := _texture_cache.get(key) as Texture2D
	if cached != null:
		return cached
	var image := Image.create(32, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var stem := Color("514237")
	var leaf := Color("704438")
	var bloom := Color("8d5143")
	for index: int in range(7):
		var tip := Vector2i(3 + index * 4, 3 + posmod(index * 7 + variant * 3, 9))
		_line(image, Vector2i(16, 23), tip, stem)
		_rect(image, tip.x - 1, tip.y, 3, 4, leaf)
		_rect(image, tip.x, tip.y - 1, 2, 2, bloom)
		_rect(image, tip.x - 2, tip.y + 5, 3, 2, leaf)
	var texture := ImageTexture.create_from_image(image)
	_texture_cache[key] = texture
	return texture

static func _witness_texture(variant: int) -> Texture2D:
	var key: String = "witness:%s" % variant
	var cached := _texture_cache.get(key) as Texture2D
	if cached != null:
		return cached
	var image := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var cloths: Array[Color] = [Color("69513c"), Color("444a47"), Color("82705a"), Color("825343"), Color("3e4340"), Color("928571")]
	var cloth: Color = cloths[variant % cloths.size()]
	var shadow: Color = cloth.darkened(0.22)
	var skin := Color("bba186")
	var hair := Color("40382d")
	var light := Color("c0b299")
	var boots := Color("393831")
	# Distinct coats, work shirt, cloak/dress, cap and hat; original pixel cutouts.
	var dress: bool = variant == 3 or variant == 5
	_rect(image, 20, 8, 9, 11, skin)
	_rect(image, 19, 7, 10, 4, hair)
	_rect(image, 19, 10, 3, 7, hair)
	_rect(image, 23, 18, 4, 4, skin)
	for y: int in range(21, 55 if dress else 50):
		var flare: int = int(float(y - 21) * (0.17 if dress else 0.07))
		_rect(image, 17 - flare, y, 14 + flare * 2, 1, cloth)
		_rect(image, 17 - flare, y, 3, 1, shadow)
	_rect(image, 13, 23, 5, 20, cloth)
	_rect(image, 31, 23, 5, 20, shadow)
	_rect(image, 13, 43, 4, 4, skin)
	_rect(image, 32, 42, 4, 4, skin)
	if not dress:
		_rect(image, 19, 48, 6, 12, shadow)
		_rect(image, 26, 48, 5, 12, shadow)
	else:
		_rect(image, 19, 53, 5, 7, shadow)
		_rect(image, 26, 53, 5, 7, shadow)
	_rect(image, 17, 60, 8, 4, boots)
	_rect(image, 26, 60, 8, 4, boots)
	_line(image, Vector2i(20, 21), Vector2i(24, 31), light)
	_line(image, Vector2i(29, 21), Vector2i(25, 31), shadow)
	_line(image, Vector2i(24, 32), Vector2i(24, 47), shadow)
	if variant in [1, 4]:
		_rect(image, 17, 7, 16, 3, hair)
		_rect(image, 20, 1 if variant == 4 else 3, 10, 6 if variant == 4 else 4, shadow)
	elif variant == 2:
		_rect(image, 18, 6, 13, 3, shadow)
		_rect(image, 13, 24, 5, 8, light)
		_rect(image, 31, 24, 5, 8, light)
	elif dress:
		_line(image, Vector2i(18, 21), Vector2i(30, 34), light if variant == 5 else shadow)
		_rect(image, 31, 38, 6, 10, Color("705d45"))
	else:
		_rect(image, 14, 38, 9, 7, Color("a59a80"))
		_rect(image, 15, 39, 7, 1, Color("665e50"))
	_rect(image, 26, 12, 2, 1, shadow)
	var texture := ImageTexture.create_from_image(image)
	_texture_cache[key] = texture
	return texture

static func _rect(image: Image, x: int, y: int, width: int, height: int, colour: Color) -> void:
	for py: int in range(maxi(y, 0), mini(y + height, image.get_height())):
		for px: int in range(maxi(x, 0), mini(x + width, image.get_width())):
			image.set_pixel(px, py, colour)

static func _line(image: Image, start: Vector2i, end: Vector2i, colour: Color) -> void:
	var steps: int = maxi(absi(end.x - start.x), absi(end.y - start.y))
	for index: int in range(steps + 1):
		var fraction: float = float(index) / float(maxi(steps, 1))
		var point := Vector2i(Vector2(start).lerp(Vector2(end), fraction).round())
		_rect(image, point.x, point.y, 1, 1, colour)
