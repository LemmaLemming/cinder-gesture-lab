extends Node3D
## SOURCE-ONLY DRAFT. No native import, portrait or production acceptance.
## G09/G11/G15/G20: the calm face belongs to the landscape, not an NPC.
## Parent owns permanent floor, capture, tethers, cues, progress and clocks.
## Helpers are instanced without build(): no Twin Suns floor/walls/controllers.

const KIT = preload("res://scripts/acts/act3/twin_suns_scenery.gd")
const BLACK := Color("1a1823")
const VIOLET := Color("61516f")
const SULPHUR := Color("92966e")
const IVORY := Color("b3b09a")
const FACE_ORIGIN := Vector3(0, 0.25, -6.8)
const CODA_ORIGIN := Vector3(0, 0, -16.0) # Provisional layout, never a spawn.
const FAMILIES: Array[String] = ["presence", "flora", "roots", "spines", "coda"]

var _kit: Node3D
var _parts: Array[Dictionary] = []
var _built: bool = false
var _strip_stage: int = 0
var _coda_displayed: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)


func build() -> bool:
	if _built:
		return runtime_error().is_empty()
	if not is_inside_tree() or not is_node_ready() or get_child_count() != 0 or basis != Basis.IDENTITY or global_basis != Basis.IDENTITY or not global_position.is_finite() or not get_groups().is_empty():
		return false
	_kit = KIT.new()
	_kit.name = "DecorativeGeometryHelpersOnly"
	add_child(_kit)
	_build_presence()
	for side: float in [-1.0, 1.0]:
		for index: int in range(3):
			var at := Vector3(side * 8.4, 0, -4.8 + float(index) * 2.4)
			var before: int = _kit.get_child_count()
			_kit.call("_rock_spine", at, 0.75 + float(index % 2) * 0.25, side, _kit)
			_retain(_kit.get_child(before) as MeshInstance3D, "spines", -1)
			_crystal(at + Vector3(-side * 0.16, 0, 0.55), side, index)
			# Filled quiet fibrous fragments end at the perimeter. They do not
			# connect to or compete with the actual mechanic's low tether.
			var ribbon := PackedVector2Array([Vector2(-0.65, -0.12), Vector2(-0.20, -0.05), Vector2(0.40, 0.10), Vector2(0.64, 0.32), Vector2(0.31, 0.22), Vector2(-0.23, 0.03)])
			var root: MeshInstance3D = _kit.call("_floor_polygon", ribbon, at + Vector3(0, 0.006, 0), Color("4d4654"))
			root.name = "QuietPeripheralRoot%d_%s" % [index, str(side)]
			_retain(root, "roots", 2)
	_build_coda()
	_built = true
	_apply(0, false)
	return runtime_error().is_empty()


## Derived display only. State 0: all beauty; 1: sparse flora; 2: bare spines.
## Changes are discrete and static. No falling bodies, damage or timers.
func present_parent_state(strip_stage: int, coda_displayed: bool = false) -> bool:
	if not runtime_error().is_empty() or not _state_valid(strip_stage, coda_displayed) or strip_stage < _strip_stage or (_coda_displayed and not coda_displayed):
		return false
	_apply(strip_stage, coda_displayed)
	return runtime_error().is_empty()


## For the later parent's already-validated paused aggregate transaction.
## This owns no save wire and cannot restore Player/capture/scene progress.
func restore_parent_state(strip_stage: int, coda_displayed: bool) -> bool:
	if not is_inside_tree() or not get_tree().paused or not runtime_error().is_empty() or not _state_valid(strip_stage, coda_displayed):
		return false
	_apply(strip_stage, coda_displayed)
	return runtime_error().is_empty()


func state() -> Dictionary:
	return {"strip_stage": _strip_stage, "coda_displayed": _coda_displayed, "optional_scenery": true}


## Inspection only: exact actual native mesh AABB corners after instantiation.
## Optional art bounds are never fed into capture/escape admission.
func framing_points(family: String = "presence") -> Dictionary:
	var error: String = runtime_error()
	if not error.is_empty() or family not in FAMILIES:
		return {"error": error if not error.is_empty() else "Unknown optional scenic family", "points": []}
	var points: Array[Vector3] = []
	for spec: Dictionary in _parts:
		var part: MeshInstance3D = spec.node
		if spec.family != family or not part.is_visible_in_tree():
			continue
		for corner: int in range(8):
			points.append(part.global_transform * part.mesh.get_aabb().get_endpoint(corner))
	if points.is_empty():
		return {"error": "", "points": [], "displayed": false, "optional_scenery": true}
	var bounds := AABB(points[0], Vector3.ZERO)
	for point: Vector3 in points:
		bounds = bounds.expand(point)
	return {"error": "", "points": points, "world_aabb": bounds, "displayed": true, "optional_scenery": true, "actual_corner_samples": points.size()}


## Deliberately modest draft custody; production must add immutable surface
## arrays/material-property stamps and its actual parent contract if needed.
func runtime_error() -> String:
	if not _built or not is_inside_tree() or not is_node_ready() or is_queued_for_deletion() or not is_instance_valid(_kit) or _kit.get_parent() != self or get_child_count() != 1 or basis != Basis.IDENTITY or global_basis != Basis.IDENTITY or not global_position.is_finite() or not get_groups().is_empty() or is_processing() or is_physics_processing():
		return "Live translated-only static decorative root required"
	if not _state_valid(_strip_stage, _coda_displayed) or _kit.get_child_count() != _parts.size():
		return "Original finite scenic children and derived state required"
	for spec: Dictionary in _parts:
		if not is_instance_valid(spec.node) or not is_instance_valid(spec.mesh) or not is_instance_valid(spec.material):
			return "Live decorative mesh and material required"
		var part: MeshInstance3D = spec.node
		var material: StandardMaterial3D = spec.material
		if part.is_queued_for_deletion() or part.get_parent() != _kit or part.get_child_count() != 0 or not part.get_groups().is_empty() or part.transform != spec.transform or part.mesh != spec.mesh or part.mesh.get_aabb() != spec.aabb or part.material_override != material or part.visible != _visible(spec, _strip_stage, _coda_displayed) or part.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			return "Original static noncolliding scenic geometry required"
		if material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.no_depth_test or material.emission_enabled or material.albedo_color != spec.color or material.albedo_texture != null or material.next_pass != null or material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
			return "Quiet opaque ordinary-depth material required"
	return ""


func _build_presence() -> void:
	# Broad filled planes suggest a closed-eye, almost-human calm. There are
	# no eyeballs, pupils, hit targets, body collider or threat-facing gesture.
	_panel("LeftCheek", [Vector2(-3.3, 0.9), Vector2(-2.9, 2.8), Vector2(-1.2, 3.6), Vector2(-0.35, 2.7), Vector2(-0.52, 1.1), Vector2(-1.6, 0.2)], SULPHUR)
	_panel("RightCheek", [Vector2(0.52, 1.1), Vector2(0.35, 2.7), Vector2(1.4, 3.5), Vector2(3.1, 2.8), Vector2(3.4, 0.8), Vector2(1.55, 0.2)], Color("85896a"))
	_panel("ForeheadRidge", [Vector2(-2.5, 2.75), Vector2(-1.3, 3.75), Vector2(1.4, 3.65), Vector2(2.75, 2.75), Vector2(0.1, 3.0)], IVORY, 0.01)
	_panel("LeftClosedLid", [Vector2(-2.6, 2.23), Vector2(-1.75, 2.12), Vector2(-0.83, 2.31), Vector2(-1.70, 2.27)], BLACK, 0.018)
	_panel("RightClosedLid", [Vector2(0.83, 2.31), Vector2(1.70, 2.12), Vector2(2.6, 2.23), Vector2(1.76, 2.28)], BLACK, 0.018)
	_panel("NoseMineralLight", [Vector2(-0.2, 2.8), Vector2(0.14, 2.62), Vector2(0.36, 1.35), Vector2(-0.23, 1.12), Vector2(-0.42, 1.39)], IVORY, 0.025)
	_panel("QuietSmileCrease", [Vector2(-1.12, 0.77), Vector2(-0.4, 0.51), Vector2(0.43, 0.53), Vector2(1.2, 0.83), Vector2(0.5, 0.62), Vector2(-0.35, 0.60)], BLACK, 0.02)
	# Four separated filled mineral fragments: partial architectural veil,
	# not a decorative outline/halo around a usable part or capture pocket.
	for side: float in [-1.0, 1.0]:
		_box("PeripheralVeil", Vector3(0.32, 1.1, 0.22), Vector3(side * 3.65, 0.8, -6.75), VIOLET, "presence", 2)
		_box("PeripheralVeilTip", Vector3(0.25, 0.32, 0.20), Vector3(side * 3.5, 2.2, -6.75), Color("827989"), "presence", 2)


func _panel(label: String, contour: Array, color: Color, z_bias: float = 0.0) -> void:
	var part: MeshInstance3D = _kit.call("_floor_polygon", PackedVector2Array(contour), FACE_ORIGIN + Vector3(0, 0, z_bias), color)
	part.name = label
	part.rotation_degrees.x = -90.0 # Same filled mesh helper, vertical plane.
	_retain(part, "presence", 2)


func _crystal(at: Vector3, side: float, index: int) -> void:
	# Mirror Sea branch topology: base -> faceted shoulder -> pointed tip.
	# Lower value than the real tether, with no glint, outline or emission.
	for branch: int in range(3):
		var radius: float = 0.10 + float(branch % 2) * 0.025
		var height: float = 0.36 + float((branch + index) % 3) * 0.13
		var base: Array[Vector3] = [Vector3(-radius, 0, -radius), Vector3(radius, 0, -radius), Vector3(radius, 0, radius), Vector3(-radius, 0, radius)]
		var shoulder := Vector3(side * 0.06, height * 0.72, 0)
		var tip := Vector3(side * 0.1, height, -0.03)
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for face: int in range(4):
			var next: int = (face + 1) % 4
			var shade: Color = VIOLET.darkened(float(face % 3) * 0.1)
			_kit.call("_triangle", surface, base[face], shoulder + base[face] * 0.65, base[next], shade)
			_kit.call("_triangle", surface, base[next], shoulder + base[face] * 0.65, shoulder + base[next] * 0.65, shade)
			_kit.call("_triangle", surface, shoulder + base[face] * 0.65, tip, shoulder + base[next] * 0.65, shade.lightened(0.035))
		var part := MeshInstance3D.new()
		part.name = "VioletScenicBranch%d_%d" % [index, branch]
		part.mesh = surface.commit()
		part.material_override = _kit.call("_vertex_material")
		part.position = at + Vector3(side * float(branch) * 0.19, 0, float(branch - 1) * 0.16)
		_kit.add_child(part)
		_retain(part, "flora", 2 if branch == 0 else 1)


func _build_coda() -> void:
	# Distant sea framing, not the playable surface. Root must place this
	# behind/outside its actual plain firm-floor exit in the authored layout.
	_box("DistantStillSea", Vector3(24, 0.018, 4), CODA_ORIGIN + Vector3(0, -0.06, -7.0), Color("28303a"), "coda", -1)
	_box("PlainTower", Vector3(0.84, 2.65, 0.58), CODA_ORIGIN + Vector3(2.15, 1.325, -5.6), BLACK, "coda", -1)
	_box("TowerQuietFoot", Vector3(1.2, 0.12, 0.9), CODA_ORIGIN + Vector3(2.15, 0.06, -5.6), Color("302936"), "coda", -1)
	for row: int in range(3):
		_box("DistantIvoryWindow%d" % row, Vector3(0.19, 0.34, 0.014), CODA_ORIGIN + Vector3(2.15, 0.50 + float(row) * 0.75, -5.3), Color("9d9d85"), "coda", -1)
	# A few broad broken sea reflections use filled rectangles, no shimmer,
	# target silhouette, route chevrons, action marker or contact response.
	for index: int in range(3):
		_box("DistantBrokenReflection%d" % index, Vector3(0.15 + float(index % 2) * 0.06, 0.003, 0.28), CODA_ORIGIN + Vector3(2.15, -0.049, -6.1 - float(index) * 0.52), Color("363743"), "coda", -1)


func _box(label: String, size: Vector3, at: Vector3, color: Color, family: String, strip_after: int) -> void:
	var part: MeshInstance3D = _kit.call("_box", size, at, color)
	part.name = label
	_retain(part, family, strip_after)


func _retain(part: MeshInstance3D, family: String, strip_after: int) -> void:
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material: StandardMaterial3D = part.material_override
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	_parts.append({"node": part, "family": family, "strip_after": strip_after, "transform": part.transform, "mesh": part.mesh, "aabb": part.mesh.get_aabb(), "material": material, "color": material.albedo_color})


func _state_valid(strip_stage: int, coda_displayed: bool) -> bool:
	return strip_stage >= 0 and strip_stage <= 2 and (not coda_displayed or strip_stage == 2)


func _visible(spec: Dictionary, strip_stage: int, coda_displayed: bool) -> bool:
	if spec.family == "coda":
		return coda_displayed
	return spec.strip_after < 0 or strip_stage < spec.strip_after


func _apply(strip_stage: int, coda_displayed: bool) -> void:
	for spec: Dictionary in _parts:
		var part: MeshInstance3D = spec.node
		var blocked: bool = part.is_blocking_signals()
		part.set_block_signals(true)
		part.visible = _visible(spec, strip_stage, coda_displayed)
		part.set_block_signals(blocked)
	_strip_stage = strip_stage
	_coda_displayed = coda_displayed
