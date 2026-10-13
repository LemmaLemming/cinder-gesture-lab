class_name Act1SeleniteCourtWholeArt
extends Node3D
## Original whole 14x44 lunar theatre, adapted from personally viewed G19,
## G15, G21 and F10. Broad painted streaks/black creases and shallow gathered
## cloth are scenery. No colliders, actors, leases, cues, clocks or input.
## Source-only authoring: native parse/import and actual portraits remain due.

const SilverFloor = preload("res://assets/acts/act1/lunar/environment/floor_silver_tile.png")
const COURT_SCRIPT: String = "res://scripts/acts/act1/selenite_court.gd"
const ART_NAME: String = "WholeCourtArt"
const FLOOR_SIZE: Vector3 = Vector3(14, 1, 44)
const FLOOR_FRAME: Transform3D = Transform3D(Basis.IDENTITY, Vector3(0, -0.5, -17))
const SKIN_FRAME: Transform3D = Transform3D(Basis.IDENTITY, Vector3(0, 0.002, -17))
const PAINT_STEP: float = 0.02
const LANDMARK_IDS: Array[String] = ["entrance", "formation", "approach", "roundel", "throne", "helper-entries", "exterior", "floor"]
const LANDMARK_PATHS: Dictionary = {"entrance": "WholeCourtArt/Entrance", "formation": "WholeCourtArt/Formation", "approach": "WholeCourtArt/Approach", "roundel": "WholeCourtArt/KnownRoundelBacking", "throne": "WholeCourtArt/CompactSideThrone", "helper-entries": "WholeCourtArt/HelperEntries", "exterior": "WholeCourtArt/ExteriorCurtain", "floor": "QuietSilverFloorSkin"}
const POSE_PATHS: Dictionary = {"helper-west-closed": "WholeCourtArt/HelperEntries/West/ClosedCloth", "helper-west-open": "WholeCourtArt/HelperEntries/West/GatheredCloth", "helper-east-closed": "WholeCourtArt/HelperEntries/East/ClosedCloth", "helper-east-open": "WholeCourtArt/HelperEntries/East/GatheredCloth", "exterior-closed": "WholeCourtArt/ExteriorCurtain/ClosedCloth", "exterior-available": "WholeCourtArt/ExteriorCurtain/AvailableCloth", "exterior-open": "WholeCourtArt/ExteriorCurtain/OpenCloth"}
const STAGES: Array[String] = ["curtain", "formation", "approach", "king1", "king2", "exterior"]
const EXTERIOR_STATES: Array[String] = ["closed", "available", "open"]

var _level: CinderLevel
var _script: Script
var _specs: Dictionary = {}
var _specs_bytes: PackedByteArray
var _state: Dictionary = {"stage": "curtain", "helpers_open": false, "exterior_state": "closed"}
var _state_bytes: PackedByteArray
var _support: Array[Dictionary] = []
var _shape_owner: int = -1
var _nodes: Array[Dictionary] = []
var _meshes: Array[Dictionary] = []
var _materials: Array[Dictionary] = []
var _landmarks: Dictionary = {}
var _poses: Dictionary = {}
var _paint: StandardMaterial3D
var _custody_ready: bool = false


static func whole_specs() -> Dictionary:
	# A detached nominal art table; physics positions and camera are never edited.
	return {"revision": 1, "id": "selenite-whole-theatre", "floor_size": Vector2(14, 44), "floor_origin": Vector3(0, 0.002, -17), "entrance_origin": Vector3(0, 0, -5.2), "entrance_panels": [Vector3(-3.05, 0, -4.8), Vector3(3.05, 0, -4.8)], "formation_panels": [Vector3(-3.15, 0, -12.4), Vector3(3.15, 0, -12.4)], "approach_panels": [Vector3(-3.25, 0, -22.2), Vector3(3.25, 0, -22.2)], "roundel_origin": Vector3(0, 0.01, -20), "throne_origin": Vector3(-1.25, 0, -30.2), "helper_origins": [Vector3(-2, 0, -33.2), Vector3(2, 0, -33.2)], "exterior_origin": Vector3(0, 0, -36.75)}


static func build_whole_art(level: CinderLevel, immutable_court_specs: Dictionary = {}) -> Node3D:
	var selected: Dictionary = whole_specs() if immutable_court_specs.is_empty() else immutable_court_specs.duplicate(true)
	if var_to_bytes(selected) != var_to_bytes(whole_specs()) or not _court_error(level).is_empty(): return null
	var art := Act1SeleniteCourtWholeArt.new()
	art.name = ART_NAME
	art._level = level
	art._script = art.get_script()
	art._specs = selected.duplicate(true)
	art._specs_bytes = var_to_bytes(selected)
	art._state_bytes = var_to_bytes(art._state)
	art._retain_support()
	art._build()
	# Native children/resources and exact authored global frames are retained
	# off-tree before child-enter notifications can expose the composition.
	art._retain_tree()
	art._custody_ready = true
	level.add_child(art)
	if not is_instance_valid(art): return null
	if not art.binding_error().is_empty():
		art.free()
		return null
	return art


static func _court_error(level: CinderLevel) -> String:
	if not is_instance_valid(level) or not level.is_inside_tree() or level.is_queued_for_deletion() or level.get_node_or_null(ART_NAME) != null: return "An actual fresh whole court without WholeCourtArt is required"
	var script: Script = level.get_script()
	if script == null or script.resource_path != COURT_SCRIPT or level.level_id != "A1-L4": return "Bind only the actual A1-L4 whole court script"
	if level.transform != Transform3D.IDENTITY or level.global_transform != Transform3D.IDENTITY or level.is_set_as_top_level(): return "The whole court must retain its identity world frame"
	var spawn := level.get_node_or_null("PlayerSpawn") as Marker3D
	var floor := level.get_node_or_null("Floor") as StaticBody3D
	var collision := level.get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
	var visual := level.get_node_or_null("Floor/Visual") as MeshInstance3D
	var skin := level.get_node_or_null("QuietSilverFloorSkin") as MeshInstance3D
	if not is_instance_valid(spawn) or not is_instance_valid(floor) or not is_instance_valid(collision) or not is_instance_valid(visual) or not is_instance_valid(skin): return "Actual unchanged spawn, support and continuous silver skin are required"
	if spawn.get_parent() != level or spawn.transform != Transform3D(Basis.IDENTITY, Vector3(0, 0.1, 0)) or spawn.is_set_as_top_level() or spawn.get_script() != null: return "Retain whole-court spawn feet at (0,.1,0)"
	if floor.get_parent() != level or floor.transform != FLOOR_FRAME or floor.global_transform != FLOOR_FRAME or floor.is_set_as_top_level() or floor.get_script() != null or floor.collision_layer != 1 or floor.collision_mask != 0 or floor.constant_linear_velocity != Vector3.ZERO or floor.constant_angular_velocity != Vector3.ZERO or floor.physics_material_override != null: return "Retain the native static 14x1x44 support floor, top zero"
	if collision.get_parent() != floor or collision.get_script() != null or collision.transform != Transform3D.IDENTITY or collision.is_set_as_top_level() or collision.disabled or not collision.shape is BoxShape3D or (collision.shape as BoxShape3D).size != FLOOR_SIZE or collision.shape.get_script() != null: return "Retain the actual native floor BOX and collision frame"
	var owners: PackedInt32Array = floor.get_shape_owners()
	if owners.size() != 1 or floor.shape_owner_get_owner(owners[0]) != collision or floor.shape_owner_get_shape_count(owners[0]) != 1 or floor.shape_owner_get_shape(owners[0], 0) != collision.shape or floor.shape_owner_get_transform(owners[0]) != Transform3D.IDENTITY or floor.is_shape_owner_disabled(owners[0]): return "Retain the exact original floor shape registration"
	if visual.get_parent() != floor or visual.transform != Transform3D.IDENTITY or visual.is_set_as_top_level() or visual.get_script() != null or not visual.is_visible_in_tree() or not visual.mesh is BoxMesh or (visual.mesh as BoxMesh).size != FLOOR_SIZE or visual.mesh.get_script() != null or not visual.material_override is StandardMaterial3D or visual.material_overlay != null or visual.transparency != 0.0 or visual.layers != 1 or visual.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: return "Retain the actual unchanged visible native floor BOX"
	var material := visual.material_override as StandardMaterial3D
	if material.get_script() != null or material.albedo_color != Color(0.4509804, 0.4509804, 0.4509804, 1) or material.albedo_texture != null or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.no_depth_test or material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED or material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.next_pass != null: return "Retain the original opaque unshaded floor material"
	if skin.get_parent() != level or skin.transform != SKIN_FRAME or skin.global_transform != SKIN_FRAME or skin.is_set_as_top_level() or skin.get_script() != null or not skin.is_visible_in_tree() or not skin.mesh is PlaneMesh or (skin.mesh as PlaneMesh).size != Vector2(14, 44) or skin.mesh.get_script() != null or not skin.material_override is StandardMaterial3D or skin.material_overlay != null or skin.transparency != 0.0 or skin.layers != 1 or skin.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: return "Retain the native full 14x44 silver skin without a duplicate plane"
	var silver := skin.material_override as StandardMaterial3D
	if silver.get_script() != null or silver.albedo_texture != SilverFloor or silver.albedo_color != Color.WHITE or silver.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or silver.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or not silver.texture_repeat or silver.uv1_scale != Vector3(14.0 / 1.536, 44.0 / 1.536, 1) or silver.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR or silver.alpha_scissor_threshold != 0.5 or silver.alpha_antialiasing_mode != BaseMaterial3D.ALPHA_ANTIALIASING_OFF or not is_equal_approx(silver.alpha_antialiasing_edge, 0.3) or silver.cull_mode != BaseMaterial3D.CULL_DISABLED or silver.no_depth_test or silver.next_pass != null or silver.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED: return "Retain the original nearest silver tile material and ordinary depth"
	return ""


func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED


func _build() -> void:
	_paint = _material(1.0)
	_paint.vertex_color_use_as_albedo = true
	_landmarks["floor"] = _level.get_node("QuietSilverFloorSkin")
	var entrance := _group(self, "Entrance", _specs.entrance_origin)
	_build_portal(entrance, 2.08, 2.10, "entrance")
	for index: int in 2:
		var side: float = -1.0 if index == 0 else 1.0
		var panel := _group(entrance, "PaintedWingWest" if index == 0 else "PaintedWingEast", _specs.entrance_panels[index] - _specs.entrance_origin)
		_build_panel(panel, side, 1.0)
	_landmarks["entrance"] = entrance
	var formation := _group(self, "Formation", Vector3.ZERO)
	var approach := _group(self, "Approach", Vector3.ZERO)
	for index: int in 2:
		var side: float = -1.0 if index == 0 else 1.0
		var suffix: String = "West" if index == 0 else "East"
		_build_panel(_group(formation, "PaintedWing" + suffix, _specs.formation_panels[index]), side, 0.92)
		_build_panel(_group(approach, "PaintedWing" + suffix, _specs.approach_panels[index]), side, 1.03)
	_landmarks["formation"] = formation
	_landmarks["approach"] = approach
	var roundel := _group(self, "KnownRoundelBacking", _specs.roundel_origin)
	_build_roundel(roundel)
	_landmarks["roundel"] = roundel
	var throne := _group(self, "CompactSideThrone", _specs.throne_origin)
	_build_throne(throne)
	_landmarks["throne"] = throne
	var helpers := _group(self, "HelperEntries", Vector3.ZERO)
	for index: int in 2:
		var suffix: String = "West" if index == 0 else "East"
		var door := _group(helpers, suffix, _specs.helper_origins[index])
		_build_portal(door, 0.93, 1.92, "helper-" + suffix.to_lower())
	_landmarks["helper-entries"] = helpers
	var exterior := _group(self, "ExteriorCurtain", _specs.exterior_origin)
	_build_portal(exterior, 2.05, 2.08, "exterior")
	_landmarks["exterior"] = exterior
	_apply_pose()


func _build_panel(parent: Node3D, side: float, height: float) -> void:
	var canvas := _canvas()
	# Irregular shallow painted theatrical silhouette, not a masonry wall.
	_poly(canvas, _mirror([Vector2(-0.66, 0.04), Vector2(-0.66, 0.56), Vector2(-0.55, 1.24), Vector2(-0.35, 1.60), Vector2(-0.47, 1.91), Vector2(-0.14, 2.12), Vector2(0.19, 1.97), Vector2(0.53, 1.64), Vector2(0.65, 0.96), Vector2(0.57, 0.04)], side, height), -0.04, 0.13)
	_poly(canvas, _mirror([Vector2(-0.60, 0.08), Vector2(-0.54, 1.20), Vector2(-0.27, 1.53), Vector2(-0.38, 1.88), Vector2(-0.14, 2.02), Vector2(0.15, 1.90), Vector2(0.43, 1.57), Vector2(0.55, 0.08)], side, height), 0.0, 0.31)
	# Broad broken silver ridges and black creases, deliberately sparse.
	_poly(canvas, _mirror([Vector2(-0.59, 0.15), Vector2(-0.46, 0.28), Vector2(-0.38, 0.80), Vector2(-0.12, 1.21), Vector2(-0.27, 1.52), Vector2(-0.13, 1.83), Vector2(-0.28, 1.87), Vector2(-0.42, 1.46), Vector2(-0.38, 1.12), Vector2(-0.52, 0.75)], side, height), 0.012, 0.75)
	_poly(canvas, _mirror([Vector2(0.25, 0.16), Vector2(0.41, 0.22), Vector2(0.42, 0.90), Vector2(0.31, 1.26), Vector2(0.20, 1.31), Vector2(0.28, 0.77)], side, height), 0.016, 0.61)
	_poly(canvas, _mirror([Vector2(-0.29, 0.16), Vector2(-0.15, 0.20), Vector2(-0.18, 0.74), Vector2(0.05, 1.02), Vector2(-0.03, 1.15), Vector2(-0.28, 0.80)], side, height), 0.023, 0.07)
	_poly(canvas, _mirror([Vector2(0.43, 0.88), Vector2(0.55, 1.05), Vector2(0.46, 1.45), Vector2(0.26, 1.69), Vector2(0.21, 1.56), Vector2(0.37, 1.29)], side, height), 0.026, 0.09)
	_curl(canvas, Vector2(side * 0.07, 0.77 * height), side, 0.88, 0.041, 0.70)
	_star(canvas, Vector2(side * 0.05, 1.65 * height), 0.27, 0.043, 0.68)
	_crescent(canvas, Vector2(side * -0.12, 2.02 * height), 0.29, side, 0.042, 0.84)
	_emit(parent, "PaintedCurlingFlat", canvas)


func _build_portal(parent: Node3D, half_width: float, height: float, kind: String) -> void:
	var canvas := _canvas()
	# Dark stepped aperture and bright weathered border remain shallow flats.
	_poly(canvas, [Vector2(-half_width, 0.03), Vector2(-half_width, height * 0.78), Vector2(-half_width * 0.80, height), Vector2(half_width * 0.80, height), Vector2(half_width, height * 0.78), Vector2(half_width, 0.03)], -0.07, 0.085)
	for side: float in [-1.0, 1.0]:
		var x: float = side * (half_width + 0.12)
		_poly(canvas, [Vector2(x - 0.16, 0.04), Vector2(x - 0.13, height - 0.02), Vector2(x + 0.14, height - 0.02), Vector2(x + 0.19, 0.04)], -0.025, 0.48)
		_poly(canvas, [Vector2(x - 0.055, 0.10), Vector2(x - 0.025, height - 0.11), Vector2(x + 0.075, height - 0.13), Vector2(x + 0.11, 0.10)], 0.014, 0.78)
		_poly(canvas, [Vector2(x - 0.25, 0.025), Vector2(x - 0.22, 0.17), Vector2(x + 0.24, 0.17), Vector2(x + 0.27, 0.025)], 0.018, 0.42)
		_curl(canvas, Vector2(x, height * 0.72), side, 0.57, 0.037, 0.72)
		_crescent(canvas, Vector2(x, height + 0.20), 0.24, side, 0.025, 0.83)
	# Three joined swags: deep black hems, broad silver folds and loose fringe.
	for index: int in 3:
		var middle: float = (float(index) - 1.0) * half_width * 0.64
		var width: float = half_width * 0.70
		_swag(canvas, middle, height + 0.07, width, 0.26 if index == 1 else 0.20)
	_emit(parent, "PaintedBorderSwagsAndCrescents", canvas)
	if kind == "entrance":
		_build_cloth(_group(parent, "GatheredCloth", Vector3.ZERO), half_width, height, half_width * 1.35)
		return
	if kind.begins_with("helper-"):
		var closed := _group(parent, "ClosedCloth", Vector3.ZERO)
		var opened := _group(parent, "GatheredCloth", Vector3.ZERO)
		_build_cloth(closed, half_width, height, 0.0)
		_build_cloth(opened, half_width, height, 1.78)
		_poses[kind + "-closed"] = closed
		_poses[kind + "-open"] = opened
		return
	for state: String in EXTERIOR_STATES:
		var cloth := _group(parent, state.capitalize() + "Cloth", Vector3.ZERO)
		var gap: float = 0.0 if state == "closed" else (2.4 if state == "available" else 3.2)
		_build_cloth(cloth, half_width, height, gap)
		_poses["exterior-" + state] = cloth


func _swag(canvas: Dictionary, middle: float, top: float, width: float, sag: float) -> void:
	var lower: Array[Vector2] = []
	var upper: Array[Vector2] = []
	for index: int in 9:
		var u: float = float(index) / 8.0
		var x: float = middle + (u - 0.5) * width
		var y: float = top - sin(u * PI) * sag
		lower.append(Vector2(x, y - 0.12))
		upper.append(Vector2(x, y))
	var silhouette: Array[Vector2] = upper.duplicate()
	for index: int in range(8, -1, -1): silhouette.append(lower[index])
	_poly(canvas, silhouette, 0.043, 0.21)
	for index: int in 8:
		_poly(canvas, [upper[index], upper[index + 1], lower[index + 1] + Vector2(0, 0.045), lower[index] + Vector2(0, 0.045)], 0.051, 0.72 if index % 3 == 0 else 0.51)
	for index: int in 9:
		var point: Vector2 = lower[index]
		_poly(canvas, [point + Vector2(-0.04, 0.025), point + Vector2(0.035, 0.025), point + Vector2(0.02, -0.11), point + Vector2(-0.015, -0.13)], 0.052, 0.60)


func _build_cloth(parent: Node3D, half_width: float, height: float, gap: float) -> void:
	var canvas := _canvas()
	for side: float in [-1.0, 1.0]:
		var inner: float = gap * 0.5
		var outer: float = half_width + (0.16 if gap > 0 else 0.0)
		var span: float = outer - inner
		var fold_count: int = clampi(int(floor(span / 0.18)), 1, 6)
		var fold_width: float = span / float(fold_count)
		for index: int in fold_count:
			var left: float = inner + fold_width * float(index)
			var right: float = inner + fold_width * float(index + 1)
			var lower: float = 0.04 + (0.055 * float(index % 3) if gap == 0 else 0.14 + 0.38 * float(fold_count - index) / float(fold_count))
			# Each sloping gathered fold has an irregular hem, broad paint and a
			# black crease. No extruded rectangular bars or animated noise.
			var edge: float = left + fold_width * 0.18
			var top: float = height - 0.08 - 0.025 * float(index % 2)
			_poly(canvas, _mirror([Vector2(left, lower + 0.045), Vector2(edge, top), Vector2(right, top - 0.035), Vector2(right, lower), Vector2(left + fold_width * 0.5, lower - 0.035)], side), 0.064 + 0.012 * float(index % 2), 0.26 if index % 2 == 0 else 0.36)
			_poly(canvas, _mirror([Vector2(left + fold_width * 0.25, lower + 0.10), Vector2(edge + fold_width * 0.10, top - 0.12), Vector2(left + fold_width * 0.62, top - 0.17), Vector2(left + fold_width * 0.70, lower + 0.08)], side), 0.084, 0.66 if index % 2 == 0 else 0.55)
			_poly(canvas, _mirror([Vector2(right - fold_width * 0.18, lower + 0.04), Vector2(right - fold_width * 0.22, top - 0.08), Vector2(right, top - 0.10), Vector2(right, lower)], side), 0.088, 0.10)
			_poly(canvas, _mirror([Vector2(left, lower + 0.07), Vector2(right, lower + 0.045), Vector2(right, lower - 0.015), Vector2(left, lower + 0.01)], side), 0.092, 0.70)
		if gap > 0:
			# Quiet broad cloth tie; no available/actionable cue styling.
			_poly(canvas, _mirror([Vector2(inner + 0.02, height * 0.47), Vector2(half_width, height * 0.54), Vector2(half_width, height * 0.48), Vector2(inner + 0.035, height * 0.42)], side), 0.101, 0.43)
	_emit(parent, "LayeredPaintedCloth", canvas)


func _build_throne(parent: Node3D) -> void:
	# Ground-base feet pivot, low compact seat and curved back. No high dais.
	_box(parent, "LowSeat", Vector3(0, 0.105, 0), Vector3(0.94, 0.21, 0.62), 0.32)
	_box(parent, "SeatSilverLip", Vector3(0, 0.20, 0.26), Vector3(1.04, 0.07, 0.12), 0.61)
	var canvas := _canvas()
	_poly(canvas, [Vector2(-0.46, 0.16), Vector2(-0.48, 0.61), Vector2(-0.33, 0.83), Vector2(0, 1.02), Vector2(0.33, 0.83), Vector2(0.48, 0.61), Vector2(0.46, 0.16)], -0.25, 0.21)
	for index: int in 9:
		var angle: float = PI * 0.17 + float(index) * PI * 0.66 / 8.0
		var end := Vector2(cos(angle) * 0.51, 0.32 + sin(angle) * 0.64)
		_ribbon(canvas, Vector2(0, 0.24), end, 0.045, -0.224, 0.63 if index % 2 == 0 else 0.42)
	_crescent(canvas, Vector2(0, 0.87), 0.25, -1.0, -0.21, 0.76)
	_star(canvas, Vector2(0, 0.59), 0.14, -0.208, 0.72)
	for side: float in [-1.0, 1.0]:
		_curl(canvas, Vector2(side * 0.48, 0.38), side, 0.48, 0.09, 0.69)
		_poly(canvas, _mirror([Vector2(0.39, 0.04), Vector2(0.42, 0.41), Vector2(0.54, 0.43), Vector2(0.57, 0.04)], side), 0.05, 0.34)
	_emit(parent, "CrescentBackRibsAndCurlArms", canvas)


func _build_roundel(parent: Node3D) -> void:
	# This is the backing of the EXISTING court-roundel mechanism at -20.
	# Its native radius1.2/shared warning cue remains exclusively parent-owned.
	# Muted filled paint, no outline, pulse, segments or alternate hazard.
	var canvas := _canvas()
	for index: int in 24:
		var a: float = TAU * float(index) / 24.0
		var b: float = TAU * float(index + 1) / 24.0
		_tri(canvas, Vector3.ZERO, Vector3(cos(a) * 1.04, 0, sin(a) * 1.04), Vector3(cos(b) * 1.04, 0, sin(b) * 1.04), 0.37 if index % 3 == 0 else 0.40)
	for index: int in 12:
		var a: float = TAU * float(index) / 12.0
		var b: float = TAU * float(index + 1) / 12.0
		var p := Vector3(cos(a) * (0.69 if index % 2 == 0 else 0.28), 0.002, sin(a) * (0.69 if index % 2 == 0 else 0.28))
		var q := Vector3(cos(b) * (0.28 if index % 2 == 0 else 0.69), 0.002, sin(b) * (0.28 if index % 2 == 0 else 0.69))
		_tri(canvas, Vector3(0, 0.002, 0), p, q, 0.29)
	_emit(parent, "QuietFilledRadialPaint", canvas)


func set_presentation(stage: String, helpers_open: bool, exterior_state: String) -> bool:
	# Parent-provided presentation only; never queries or changes progression.
	if stage not in STAGES or exterior_state not in EXTERIOR_STATES or not binding_error().is_empty(): return false
	_state = {"stage": stage, "helpers_open": helpers_open, "exterior_state": exterior_state}
	_state_bytes = var_to_bytes(_state)
	_apply_pose()
	return binding_error().is_empty()


func presentation_state() -> Dictionary:
	return _state.duplicate(true) if binding_error().is_empty() else {}


func landmark_ids() -> Array[String]:
	return LANDMARK_IDS.duplicate()


func _apply_pose() -> void:
	for key: String in _poses:
		(_poses[key] as Node3D).visible = _pose_visible(key)


func _pose_visible(key: String) -> bool:
	if key.begins_with("helper-"): return bool(_state.helpers_open) if key.ends_with("-open") else not bool(_state.helpers_open)
	return key == "exterior-" + String(_state.exterior_state)


func _visible_for(node: Node3D) -> bool:
	for key: String in _poses:
		if _poses[key] == node: return _pose_visible(key)
	return true


func _visible_in_tree_for(node: Node3D) -> bool:
	for key: String in _poses:
		var root: Node3D = _poses[key]
		if root == node or root.is_ancestor_of(node): return _pose_visible(key)
	return true


func binding_error() -> String:
	if not _custody_ready or not is_instance_valid(_level) or not _level.is_inside_tree() or _level.is_queued_for_deletion(): return "Retained actual whole court is unavailable"
	if get_parent() != _level or _level.get_node_or_null(ART_NAME) != self or not is_inside_tree() or is_queued_for_deletion() or get_world_3d() != _level.get_world_3d() or get_script() != _script: return "WholeCourtArt must retain its actual level/world/script binding"
	var script: Script = _level.get_script()
	if script == null or script.resource_path != COURT_SCRIPT or _level.level_id != "A1-L4" or _level.transform != Transform3D.IDENTITY or _level.global_transform != Transform3D.IDENTITY or _level.is_set_as_top_level() or transform != Transform3D.IDENTITY or is_set_as_top_level(): return "Retain the actual whole court and identity world frames"
	if var_to_bytes(_specs) != _specs_bytes or _specs_bytes != var_to_bytes(whole_specs()): return "Retain the exact authored whole-court table"
	if var_to_bytes(_state) != _state_bytes or _state.keys() != ["stage", "helpers_open", "exterior_state"] or typeof(_state.stage) != TYPE_STRING or typeof(_state.helpers_open) != TYPE_BOOL or typeof(_state.exterior_state) != TYPE_STRING or _state.stage not in STAGES or _state.exterior_state not in EXTERIOR_STATES: return "Retain a supported exact scenic presentation state"
	for record: Dictionary in _support:
		if not is_instance_valid(record.node): return "Retained native whole court support/presentation is unavailable"
		var node: Node3D = record.node
		if not node.is_inside_tree() or node.is_queued_for_deletion() or node.get_parent() != record.parent or _level.get_node_or_null(record.path) != node or node.get_children() != record.children or node.get_script() != record.script or _properties(node) != record.properties or node.global_transform != record.global_transform or node.is_set_as_top_level(): return "Original whole court support/spawn/skin binding changed"
		if record.has("shape") and (not is_instance_valid(record.shape) or (node as CollisionShape3D).shape != record.shape or _properties(record.shape) != record.shape_properties): return "Original native whole court floor BOX changed"
		if record.has("mesh") and (not is_instance_valid(record.mesh) or not is_instance_valid(record.material) or (node as MeshInstance3D).mesh != record.mesh or (node as MeshInstance3D).material_override != record.material or _mesh_bytes(record.mesh) != record.geometry or _properties(record.material) != record.material_properties): return "Original quiet floor/skin mesh or material changed"
	var floor := _support[0].node as StaticBody3D
	var collision := _support[1].node as CollisionShape3D
	if floor.get_shape_owners() != PackedInt32Array([_shape_owner]) or floor.shape_owner_get_owner(_shape_owner) != collision or floor.shape_owner_get_shape_count(_shape_owner) != 1 or floor.shape_owner_get_shape(_shape_owner, 0) != collision.shape or floor.shape_owner_get_transform(_shape_owner) != Transform3D.IDENTITY or floor.is_shape_owner_disabled(_shape_owner): return "Original whole court floor shape registration changed"
	if _poses.size() != POSE_PATHS.size(): return "Retain both helper and all three exterior scenic poses"
	for key: String in POSE_PATHS:
		if not is_instance_valid(_poses.get(key)) or _level.get_node_or_null(POSE_PATHS[key]) != _poses[key]: return "Retained actual cloth pose is unavailable or substituted"
	for record: Dictionary in _nodes:
		if not is_instance_valid(record.node): return "Required authored whole court node is unavailable"
		var node: Node3D = record.node
		if not node.is_inside_tree() or node.is_queued_for_deletion() or node.get_parent() != record.parent or _level.get_node_or_null(record.path) != node or node.get_script() != record.script or node.get_children() != record.children: return "Required whole court tree/script composition changed"
		if _properties(node, ["visible"]) != record.properties or node.transform != record.transform or node.global_transform != record.global_transform or node.is_set_as_top_level() or node.process_mode != Node.PROCESS_MODE_DISABLED or node.is_processing() or node.is_physics_processing() or node.visible != _visible_for(node) or node.is_visible_in_tree() != _visible_in_tree_for(node): return "Required clockless whole court frame/visibility changed"
	for record: Dictionary in _meshes:
		if not is_instance_valid(record.mesh) or not is_instance_valid(record.material): return "Retained authored whole court resource is unavailable"
		var node: MeshInstance3D = record.node
		if node.mesh != record.mesh or node.material_override != record.material or node.material_overlay != null or _mesh_bytes(record.mesh) != record.geometry: return "Authored whole court mesh/material identity or geometry changed"
		for index: int in node.get_surface_override_material_count():
			if node.get_surface_override_material(index) != null: return "Whole court surface overrides are unsupported"
	for record: Dictionary in _materials:
		if not is_instance_valid(record.material) or record.material.get_script() != null or _properties(record.material) != record.properties: return "Retained whole court material/settings changed"
		var material: StandardMaterial3D = record.material
		if material.albedo_texture != record.texture: return "Retained whole court texture identity changed"
		if record.texture != null and (not is_instance_valid(record.texture) or record.texture.get_script() != null or record.texture.resource_path != record.texture_path or record.texture.get_size() != record.texture_size): return "Retained whole court texture readback changed"
	if _landmarks.size() != LANDMARK_IDS.size(): return "Retain the exact whole court landmark set"
	for id: String in LANDMARK_IDS:
		if not is_instance_valid(_landmarks.get(id)) or _level.get_node_or_null(LANDMARK_PATHS[id]) != _landmarks[id]: return "Required actual whole court landmark is unavailable or substituted"
	return ""


func landmark_world_corners(id: String) -> Array:
	if id not in LANDMARK_IDS or not binding_error().is_empty(): return [Vector3.INF]
	var root: Node3D = _landmarks[id]
	var points: Array[Vector3] = []
	if id == "floor": points.append_array(_box_points((root as MeshInstance3D).get_aabb(), root.global_transform))
	else:
		for record: Dictionary in _meshes:
			var mesh: MeshInstance3D = record.node
			if (mesh == root or root.is_ancestor_of(mesh)) and mesh.is_visible_in_tree(): points.append_array(_box_points(mesh.get_aabb(), mesh.global_transform))
	if points.is_empty(): return [Vector3.INF]
	# Actual complete visible native geometry, never a silhouette/distance proxy.
	var bounds := AABB(points[0], Vector3.ZERO)
	for point: Vector3 in points: bounds = bounds.expand(point)
	return _box_points(bounds, Transform3D.IDENTITY)


func _retain_support() -> void:
	for path: String in ["Floor", "Floor/CollisionShape3D", "Floor/Visual", "PlayerSpawn", "QuietSilverFloorSkin"]:
		var node: Node3D = _level.get_node(path)
		var record: Dictionary = {"node": node, "parent": node.get_parent(), "path": NodePath(path), "script": node.get_script(), "children": node.get_children(), "global_transform": node.global_transform, "properties": _properties(node)}
		if node is CollisionShape3D:
			record["shape"] = (node as CollisionShape3D).shape
			record["shape_properties"] = _properties(record.shape)
		if node is MeshInstance3D:
			record["mesh"] = (node as MeshInstance3D).mesh
			record["material"] = (node as MeshInstance3D).material_override
			record["geometry"] = _mesh_bytes(record.mesh)
			record["material_properties"] = _properties(record.material)
		_support.append(record)
		if path == "QuietSilverFloorSkin": _retain_material(record.material)
	_shape_owner = int((_support[0].node as StaticBody3D).get_shape_owners()[0])


func _retain_tree() -> void:
	var nodes: Array[Node3D] = [self]
	for raw: Node in find_children("*", "Node3D", true, false): nodes.append(raw as Node3D)
	for node: Node3D in nodes:
		var path := NodePath(ART_NAME if node == self else ART_NAME + "/" + String(get_path_to(node)))
		_nodes.append({"node": node, "parent": _level if node == self else node.get_parent(), "path": path, "script": node.get_script(), "children": node.get_children(), "transform": node.transform, "global_transform": _authored_transform(node), "properties": _properties(node, ["visible"])})
		if node is MeshInstance3D:
			var mesh := node as MeshInstance3D
			_meshes.append({"node": mesh, "mesh": mesh.mesh, "material": mesh.material_override, "geometry": _mesh_bytes(mesh.mesh)})
			_retain_material(mesh.material_override as StandardMaterial3D)


func _retain_material(material: StandardMaterial3D) -> void:
	for record: Dictionary in _materials:
		if record.material == material: return
	_materials.append({"material": material, "properties": _properties(material), "texture": material.albedo_texture, "texture_path": material.albedo_texture.resource_path if material.albedo_texture != null else "", "texture_size": material.albedo_texture.get_size() if material.albedo_texture != null else Vector2.ZERO})


func _authored_transform(node: Node3D) -> Transform3D:
	var chain: Array[Transform3D] = []
	var cursor: Node3D = node
	while cursor != self:
		chain.push_front(cursor.transform)
		cursor = cursor.get_parent() as Node3D
	var result := Transform3D.IDENTITY
	for frame: Transform3D in chain: result = result * frame
	return result


static func _properties(object: Object, excluded: Array[String] = []) -> PackedByteArray:
	var values: Array = []
	for info: Dictionary in object.get_property_list():
		var key: String = String(info.name)
		if (int(info.usage) & PROPERTY_USAGE_STORAGE) == 0 or (int(info.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 or key in excluded: continue
		var value: Variant = object.get(key)
		values.append([key, ["object", value.get_instance_id()] if value is Object and is_instance_valid(value) else value])
	return var_to_bytes(values)


static func _mesh_bytes(mesh: Mesh) -> PackedByteArray:
	if not is_instance_valid(mesh) or mesh.get_script() != null: return PackedByteArray()
	var surfaces: Array = []
	for index: int in mesh.get_surface_count():
		if mesh.surface_get_material(index) != null: return PackedByteArray()
		surfaces.append(mesh.surface_get_arrays(index))
	return var_to_bytes([_properties(mesh), mesh.get_aabb(), surfaces])


static func _box_points(bounds: AABB, frame: Transform3D) -> Array:
	var points: Array[Vector3] = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]: points.append(frame * Vector3(x, y, z))
	return points


func _group(parent: Node3D, node_name: String, origin: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = node_name
	node.position = origin
	node.process_mode = Node.PROCESS_MODE_DISABLED
	parent.add_child(node)
	return node


func _emit(parent: Node3D, node_name: String, canvas: Dictionary) -> MeshInstance3D:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(canvas.vertices)
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray(canvas.colors)
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(canvas.uvs)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return _mesh(parent, node_name, mesh, _paint)


func _mesh(parent: Node3D, node_name: String, mesh: Mesh, material: StandardMaterial3D) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.process_mode = Node.PROCESS_MODE_DISABLED
	parent.add_child(node)
	return node


func _box(parent: Node3D, node_name: String, origin: Vector3, size: Vector3, silver: float) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := _mesh(parent, node_name, mesh, _material(silver))
	node.position = origin


static func _material(silver: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(silver, silver, silver)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.no_depth_test = false
	material.render_priority = 0
	return material


static func _canvas() -> Dictionary:
	var vertices: Array[Vector3] = []
	var colors: Array[Color] = []
	var uvs: Array[Vector2] = []
	return {"vertices": vertices, "colors": colors, "uvs": uvs}


static func _mirror(points: Array[Vector2], side: float, height: float = 1.0) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for point: Vector2 in points: result.append(Vector2(point.x * side, point.y * height))
	return result


static func _poly(canvas: Dictionary, polygon: Array[Vector2], z: float, silver: float) -> void:
	var native := PackedVector2Array()
	for point: Vector2 in polygon:
		var painted := Vector2(snappedf(point.x, PAINT_STEP), snappedf(point.y, PAINT_STEP))
		if native.is_empty() or native[native.size() - 1] != painted: native.append(painted)
	if native.size() > 1 and native[0] == native[native.size() - 1]: native.remove_at(native.size() - 1)
	# Quantization is solely the native painted edge vocabulary. Body/floor
	# frames, motion, cues and the shallow depth separation remain untouched.
	for index: int in Geometry2D.triangulate_polygon(native):
		var point: Vector2 = native[index]
		canvas.vertices.append(Vector3(point.x, point.y, z))
		canvas.colors.append(Color(silver, silver, silver))
		canvas.uvs.append(point)


static func _tri(canvas: Dictionary, a: Vector3, b: Vector3, c: Vector3, silver: float) -> void:
	for point: Vector3 in [a, b, c]:
		canvas.vertices.append(point)
		canvas.colors.append(Color(silver, silver, silver))
		canvas.uvs.append(Vector2(point.x, point.y))


static func _ribbon(canvas: Dictionary, p: Vector2, q: Vector2, width: float, z: float, silver: float) -> void:
	var delta: Vector2 = q - p
	var normal := Vector2(-delta.y, delta.x).normalized() * width * 0.5
	_poly(canvas, [p - normal, q - normal, q + normal, p + normal], z, silver)


static func _curl(canvas: Dictionary, center: Vector2, side: float, scale: float, z: float, silver: float) -> void:
	for index: int in 18:
		var a: float = float(index) * TAU * 1.16 / 18.0
		var b: float = float(index + 1) * TAU * 1.16 / 18.0
		var p := center + Vector2(side * cos(a), sin(a)) * (0.10 + float(index) * 0.017) * scale
		var q := center + Vector2(side * cos(b), sin(b)) * (0.10 + float(index + 1) * 0.017) * scale
		_ribbon(canvas, p, q, 0.085 * scale, z, silver)


static func _star(canvas: Dictionary, center: Vector2, radius: float, z: float, silver: float) -> void:
	var points: Array[Vector2] = []
	for index: int in 10:
		var angle: float = -PI * 0.5 + float(index) * PI / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius * (1.0 if index % 2 == 0 else 0.42))
	_poly(canvas, points, z, silver)


static func _crescent(canvas: Dictionary, center: Vector2, radius: float, side: float, z: float, silver: float) -> void:
	var points: Array[Vector2] = []
	for index: int in 13:
		var angle: float = -PI * 0.5 + float(index) * PI / 12.0
		points.append(center + Vector2(side * cos(angle) * radius, sin(angle) * radius))
	for index: int in range(12, -1, -1):
		var angle: float = -PI * 0.5 + float(index) * PI / 12.0
		points.append(center + Vector2(side * cos(angle) * radius * 0.25, sin(angle) * radius * 0.80))
	_poly(canvas, points, z, silver)
