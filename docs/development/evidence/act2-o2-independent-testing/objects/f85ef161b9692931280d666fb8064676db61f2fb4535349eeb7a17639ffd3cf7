extends Node3D
## Produced reusable garden dressing. Native readiness is in the asset record.
## G08/G10/B05 adaptation: pale blossoms over quiet fibrous external roots.
## Reuse only owned parent helpers; NEVER call the parent complete build().
## No floor, boundary, collider, target, enemy, cue, HP, pulse or damage.
## Parent owns actual disengagement and the unchanged permanent safe floor.
## Static world layout is an authored trial, not proof of portrait visibility.

const KIT = preload("res://scripts/acts/act3/twin_suns_scenery.gd")
const COURT_RECT := Rect2(-7, -6, 14, 12) # Record only: no floor is created.
const RESERVED_RECT := Rect2(-4.2, -0.6, 8.4, 4.35)
const ROOT_Y: float = 0.008
const VEIN_Y: float = 0.010
const ROOT_COLOR := Color("63525e")
const VEIN_COLOR := Color("70695b")
const BED_COLOR := Color("767260")
const PETAL_COLOR := Color("bab6a7")
const STEM_COLOR := Color("5a5d49")
const ARCH_COLOR := Color("68634f")
const SOURCE_ENDS: Array[Vector2] = [Vector2(-1, 1.25), Vector2(1, 1.25), Vector2.ZERO]
const TETHER_END := Vector2(1, 0)
const ROOT_PATHS: Array = [
	[Vector2(-1, 1.25), Vector2(-0.82, 0.77), Vector2(-0.55, 0.44), Vector2(-0.06, 0.30), Vector2(0.49, 0.16), Vector2(1, 0)],
	[Vector2(1, 1.25), Vector2(0.91, 0.95), Vector2(1.08, 0.66), Vector2(1.11, 0.33), Vector2(1, 0)],
	[Vector2.ZERO, Vector2(0.27, -0.12), Vector2(0.63, -0.10), Vector2(1, 0)],
]
const BED_CENTRES: Array[Vector2] = [Vector2(-2.25, -1.75), Vector2(2.25, -1.75), Vector2(-5.60, 1.30), Vector2(5.60, 1.30)]
const BED_CONTOUR := [Vector2(-0.95, -0.33), Vector2(-0.51, -0.54), Vector2(0.37, -0.47), Vector2(1.02, -0.13), Vector2(0.72, 0.39), Vector2(0.02, 0.49), Vector2(-0.81, 0.28)]
const BLOOM_OFFSETS: Array[Vector2] = [Vector2(-0.49, -0.08), Vector2(0.08, 0.14), Vector2(0.53, -0.12)]
const ARCH_PIVOTS: Array[Vector3] = [Vector3(-7.70, 0, -3.75), Vector3(7.70, 0, -3.75)]

var _kit: Node3D
var _beauty: Node3D
var _built: bool = false
var _disengaged: bool = false
var _reserved: Rect2 = RESERVED_RECT
var _parts: Array[Dictionary] = []
var _last_error: String = ""


## Idempotent, parent-local world units. Supply the actual projected-response
## floor union as a conservative X/Z rectangle before publication. This plane
## separation is NOT a substitute for actual portrait/ordinary-depth review.
func build(reserved_rect: Rect2 = RESERVED_RECT) -> bool:
	if _built:
		_last_error = runtime_error()
		return _last_error.is_empty()
	if not is_inside_tree() or not is_node_ready() or get_child_count() != 0 or basis != Basis.IDENTITY or global_basis != Basis.IDENTITY or not global_position.is_finite() or not _rect_valid(reserved_rect) or not COURT_RECT.encloses(reserved_rect):
		_last_error = "Ready translated-only empty scenic root and bounded court reservation required"
		return false
	_reserved = reserved_rect
	# Check every removable footprint before adding any instance.
	for centre: Vector2 in BED_CENTRES:
		if _bed_rect(centre).intersects(_reserved, true):
			_last_error = "Pale flower bed intersects actual protected floor union"
			return false
	for at: Vector3 in ARCH_PIVOTS:
		if Rect2(at.x - 0.32, at.z - 0.50, 0.64, 1.00).intersects(_reserved, true):
			_last_error = "Side arch intersects actual protected floor union"
			return false
	_kit = KIT.new()
	_kit.name = "ReusedDecorativeHelpersOnly"
	add_child(_kit)
	_beauty = Node3D.new()
	_beauty.name = "RemovableBlossomsAndArches"
	add_child(_beauty)
	for index: int in range(ROOT_PATHS.size()):
		var path: Array = ROOT_PATHS[index]
		_add_ribbon("FixedExternalRoot%d" % index, path, 0.14, ROOT_Y, ROOT_COLOR)
		_add_ribbon("QuietFibrousVein%d" % index, path, 0.034, VEIN_Y, VEIN_COLOR)
	for index: int in range(BED_CENTRES.size()):
		var centre: Vector2 = BED_CENTRES[index]
		var contour := PackedVector2Array(BED_CONTOUR)
		var bed: MeshInstance3D = _kit.call("_floor_polygon", contour, Vector3(centre.x, 0.003, centre.y), BED_COLOR)
		bed.name = "PaleFilledGardenBed%d" % index
		_register(bed, "beauty", _beauty)
		for bloom: int in range(BLOOM_OFFSETS.size()):
			var point: Vector2 = centre + BLOOM_OFFSETS[bloom]
			_blossom(Vector3(point.x, 0, point.y), index * 3 + bloom)
	for index: int in range(ARCH_PIVOTS.size()):
		_side_arch(ARCH_PIVOTS[index], index)
	_built = true
	_last_error = runtime_error()
	return _last_error.is_empty()


## A parent-owned scenic state change only: no inference from a target HP,
## source phase, sun, lease or clock. Restore may quietly re-present intact.
## Fixed root ribbons remain unchanged when the decorative beauty withdraws.
func present_parent_disengagement(disengaged: bool) -> bool:
	if not runtime_error().is_empty():
		return false
	_disengaged = disengaged
	_beauty.visible = not disengaged
	return true


func state() -> Dictionary:
	return {"family": "act3-garden-external-roots-and-removable-beauty", "built": _built, "disengaged": _disengaged, "court_record_only": COURT_RECT, "protected_rect": _reserved, "mesh_count": _parts.size(), "readiness": "produced_geometry_consumer_see_asset_record", "fixed_root_endpoints": SOURCE_ENDS.duplicate(), "low_tether_endpoint": TETHER_END, "last_error": _last_error}


## Pure conservative enclosing world AABB corners for the selected family.
## These are actual mesh-AABB bounds after build, not predicted visibility or
## permission to change the shared camera. Beauty is optional scenery and must
## not force all peripheral arches into a combat camera admission union.
func native_bounds(family: String = "roots") -> Dictionary:
	var error: String = runtime_error()
	if not error.is_empty() or family not in ["roots", "beauty", "all"]:
		return {"error": error if not error.is_empty() else "Unknown scenic bound family", "points": []}
	var points: Array[Vector3] = []
	for spec: Dictionary in _parts:
		if family != "all" and spec.family != family:
			continue
		var mesh: MeshInstance3D = spec.node
		for corner: int in range(8):
			points.append(mesh.global_transform * mesh.mesh.get_aabb().get_endpoint(corner))
	if points.is_empty():
		return {"error": "Actual scenic mesh bounds unavailable", "points": []}
	var box := AABB(points[0], Vector3.ZERO)
	for point: Vector3 in points:
		box = box.expand(point)
	var corners: Array = []
	for corner: int in range(8):
		corners.append(box.get_endpoint(corner))
	return {"error": "", "points": corners, "world_aabb": box, "actual_corner_samples": points.size(), "optional_scenery": family != "roots"}


func runtime_error() -> String:
	if not _built or not is_inside_tree() or not is_node_ready() or is_queued_for_deletion() or basis != Basis.IDENTITY or global_basis != Basis.IDENTITY or not global_position.is_finite() or not get_groups().is_empty() or get_child_count() != 2 or not is_instance_valid(_kit) or not is_instance_valid(_beauty) or _kit.get_parent() != self or _beauty.get_parent() != self or _kit.transform != Transform3D.IDENTITY or _beauty.transform != Transform3D.IDENTITY or not _kit.visible or _beauty.visible != (not _disengaged):
		return "Original nonphysical garden dressing hierarchy required"
	if _kit.get_child_count() != 6 or _beauty.get_child_count() != 124 or _parts.size() != 130:
		return "Six fixed ribbons and original124 removable meshes required"
	for spec: Dictionary in _parts:
		var node: MeshInstance3D = spec.node
		if not is_instance_valid(node) or node.is_queued_for_deletion() or not node.is_inside_tree() or node.get_parent() != spec.parent or node.transform != spec.transform or node.mesh != spec.mesh or node.mesh.get_aabb() != spec.aabb or node.material_override != spec.material or not node.visible or not node.get_groups().is_empty() or node.get_child_count() != 0 or node.material_overlay != null or node.layers != 1 or node.transparency != 0.0 or node.top_level or node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			return "Authored noncolliding garden part transform/mesh/state changed"
		var material: StandardMaterial3D = spec.material
		if material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.no_depth_test or material.albedo_color != spec.color or material.albedo_texture != null or material.next_pass != null or material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
			return "Restrained opaque nearest ordinary-depth garden material required"
		if node.mesh is ArrayMesh:
			if node.mesh.get_surface_count() != 1 or node.mesh.surface_get_arrays(0) != spec.arrays:
				return "Original filled root/bed triangles changed"
		elif not node.mesh is BoxMesh or (node.mesh as BoxMesh).size != spec.size:
			return "Original low blossom/arch box dimensions changed"
	return ""


func _add_ribbon(label: String, path: Array, width: float, y: float, color: Color) -> void:
	var left: Array[Vector2] = []
	var right: Array[Vector2] = []
	for index: int in range(path.size()):
		var before: Vector2 = path[maxi(0, index - 1)]
		var after: Vector2 = path[mini(path.size() - 1, index + 1)]
		var tangent: Vector2 = (after - before).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		var half: float = width * 0.5 * (1.0 - 0.25 * float(index) / float(path.size() - 1))
		left.append((path[index] as Vector2) + normal * half)
		right.append((path[index] as Vector2) - normal * half)
	var outline := PackedVector2Array(left)
	right.reverse()
	outline.append_array(PackedVector2Array(right))
	var ribbon: MeshInstance3D = _kit.call("_floor_polygon", outline, Vector3(0, y, 0), color)
	ribbon.name = label
	_register(ribbon, "roots", _kit)


func _blossom(at: Vector3, index: int) -> void:
	_box_part("Stem%d" % index, Vector3(0.028, 0.13, 0.028), at + Vector3(0, 0.065, 0), STEM_COLOR)
	_box_part("LeafA%d" % index, Vector3(0.14, 0.012, 0.045), at + Vector3(-0.05, 0.065, 0), STEM_COLOR, -28.0)
	_box_part("LeafB%d" % index, Vector3(0.13, 0.012, 0.045), at + Vector3(0.045, 0.075, 0), STEM_COLOR, 34.0)
	for petal: int in range(5):
		var angle: float = TAU * float(petal) / 5.0 + float(index % 2) * 0.24
		var center: Vector3 = at + Vector3(sin(angle) * 0.063, 0.145 + float(petal % 2) * 0.005, cos(angle) * 0.063)
		_box_part("Petal%d_%d" % [index, petal], Vector3(0.10, 0.020, 0.13), center, PETAL_COLOR, rad_to_deg(angle))
	_box_part("QuietCentre%d" % index, Vector3(0.055, 0.025, 0.055), at + Vector3(0, 0.155, 0), Color("96917b"))


func _side_arch(at: Vector3, index: int) -> void:
	# Off-floor segmented fork, no lintel across the centre court or full ring.
	_box_part("ArchStem%d" % index, Vector3(0.19, 1.42, 0.22), at + Vector3(0, 0.71, 0), ARCH_COLOR)
	_box_part("ArchUpper%d" % index, Vector3(0.16, 0.60, 0.20), at + Vector3(0, 1.63, -0.12), ARCH_COLOR)
	_box_part("ArchForkA%d" % index, Vector3(0.14, 0.18, 0.69), at + Vector3(-0.14, 1.85, -0.12), ARCH_COLOR, -18.0)
	_box_part("ArchForkB%d" % index, Vector3(0.13, 0.15, 0.54), at + Vector3(0.13, 1.73, -0.05), Color("79725d"), 24.0)
	_box_part("ArchRootFoot%d" % index, Vector3(0.45, 0.055, 0.42), at + Vector3(0, 0.0275, 0), ROOT_COLOR)
	_box_part("ArchIvoryTip%d" % index, Vector3(0.10, 0.08, 0.12), at + Vector3(-0.14, 1.97, -0.38), PETAL_COLOR)


func _box_part(label: String, size: Vector3, at: Vector3, color: Color, yaw_degrees: float = 0.0) -> void:
	var part: MeshInstance3D = _kit.call("_box", size, at, color)
	part.name = label
	part.rotation_degrees.y = yaw_degrees
	_register(part, "beauty", _beauty)


func _register(part: MeshInstance3D, family: String, parent: Node3D) -> void:
	if part.get_parent() != parent:
		part.reparent(parent, false)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material: StandardMaterial3D = part.material_override
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	var spec: Dictionary = {"node": part, "family": family, "parent": parent, "transform": part.transform, "mesh": part.mesh, "aabb": part.mesh.get_aabb(), "material": material, "color": material.albedo_color}
	if part.mesh is ArrayMesh:
		spec.arrays = part.mesh.surface_get_arrays(0).duplicate(true)
	else:
		spec.size = (part.mesh as BoxMesh).size
	_parts.append(spec)


func _bed_rect(centre: Vector2) -> Rect2:
	# Includes every blossom as well as the complete irregular filled patch.
	return Rect2(centre + Vector2(-0.95, -0.54), Vector2(1.97, 1.03))


func _rect_valid(rect: Rect2) -> bool:
	return rect.position.is_finite() and rect.size.is_finite() and rect.size.x > 0.0 and rect.size.y > 0.0
