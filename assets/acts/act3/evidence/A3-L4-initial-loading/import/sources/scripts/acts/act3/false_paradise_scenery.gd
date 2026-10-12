extends Node3D
## A3-L4 authored scenery consumer; initial source-only, unparsed/unrendered.
## G08/G10: permanent dark mineral ground, pale removable garden beauty,
## external low roots and ONE harmless maroon-haired clothed projection.
## Reuses TwinSuns helpers independently, published GardenArt130 and the
## original1254 likeness f45558d7... at its retained native feet/alpha scale.
## Never calls the complete TwinSuns build or adds its walls/controllers.
## Only this floor collides. No HP, target/group, cue, reward, sun or Scheduler.
## Approach court bands are static placement bookkeeping, NOT proof that
## moving sources, forecast Player shadows or opaque projection remain clear.
## Parent owns actual entry/disengagement and the full paused aggregate.

const KIT = preload("res://scripts/acts/act3/twin_suns_scenery.gd")
const GardenArt = preload("res://scripts/acts/act3/garden_scenery.gd")
const LikenessArt = preload("res://scripts/acts/act3/garden_likeness_art.gd")
const LikenessTexture = preload("res://assets/acts/act3/garden/sullenbode-likeness-v1.png")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const FLOOR_SIZE := Vector3(14, 1, 78)
const FLOOR_CENTER := Vector3(0, -0.5, 25)
const SAFE_RECT := Rect2(-7, -14, 14, 78)
const APPROACH_COURTS: Array[float] = [54.0, 36.0, 18.0]
const APPROACH_ANCHOR := Vector3(-0.85, 0, 51.5)
const BOSS_ANCHOR := Vector3(-0.85, 0, -1.5)
const PRESENTATION_SCHEMA: int = 1
const BED_CONTOUR := [Vector2(-0.95, -0.33), Vector2(-0.51, -0.54), Vector2(0.37, -0.47), Vector2(1.02, -0.13), Vector2(0.72, 0.39), Vector2(0.02, 0.49), Vector2(-0.81, 0.28)]
const BLOOM_OFFSETS: Array[Vector2] = [Vector2(-0.49, -0.08), Vector2(0.08, 0.14), Vector2(0.53, -0.12)]
const FLOOR_COLOR := Color("302438")
const BED_COLOR := Color("767260")
const PETAL_COLOR := Color("bab6a7")
const STEM_COLOR := Color("5a5d49")
const ARCH_COLOR := Color("68634f")
const NEW_MESH_COUNT: int = 205 # Floor1, permanent12, approach beauty192.

var floor_body: StaticBody3D
var garden: Node3D
var likeness: Node3D
var _kit: Node3D
var _approach_beauty: Node3D
var _floor_shape: BoxShape3D
var _floor_margin: float = 0.0
var _floor_disable_mode: int = 0
var _parts: Array[Dictionary] = []
var _built: bool = false
var _boss_entered: bool = false
var _disengaged: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_process(false)
	set_physics_process(false)


func build() -> bool:
	if _built:
		return runtime_error().is_empty()
	if not is_inside_tree() or not is_node_ready() or is_queued_for_deletion() or get_child_count() != 0 or transform != Transform3D.IDENTITY or global_transform != Transform3D.IDENTITY or not get_groups().is_empty():
		return false
	_kit = KIT.new()
	_kit.name = "ReusedGeometryHelpersOnly"
	add_child(_kit)
	_approach_beauty = Node3D.new()
	_approach_beauty.name = "RemovableApproachGarden"
	add_child(_approach_beauty)
	floor_body = _kit.call("_solid_box", "PermanentFalseParadiseFloor", FLOOR_SIZE, FLOOR_CENTER)
	floor_body.reparent(self, false)
	_floor_shape = (floor_body.get_child(0) as CollisionShape3D).shape as BoxShape3D
	_floor_margin = _floor_shape.margin # Retain the actual native scalar.
	_floor_disable_mode = floor_body.disable_mode
	var floor_view: MeshInstance3D = _kit.call("_box", FLOOR_SIZE, Vector3.ZERO, FLOOR_COLOR)
	floor_view.name = "PermanentMineralSurface"
	floor_view.reparent(floor_body, false)
	_register(floor_view, "floor")
	for index: int in range(APPROACH_COURTS.size()):
		_approach_court(APPROACH_COURTS[index], index)
	garden = GardenArt.new()
	garden.name = "ReusedBossGarden"
	add_child(garden) # Exact tested boss-local130mesh layout remains atZ0.
	if not garden.call("build"):
		return false
	likeness = LikenessArt.new()
	likeness.name = "OneHarmlessGardenLikeness"
	likeness.position = APPROACH_ANCHOR
	add_child(likeness)
	if not likeness.call("configure", LikenessTexture):
		return false
	_built = true
	return runtime_error().is_empty()


## This specific cosmetic relocation is derived ONLY from actual boss entry.
## The parent changes the anchor offscreen; no arbitrary saved translation,
## duplicated figure, injury/death/interaction or new gameplay event exists.
## Live progress is monotonic. Earlier Retry uses paused restore below, never
## present_parent_disengagement(false) to rearm a latched likeness fade.
func show_progress(boss_entered: bool, disengaged: bool) -> bool:
	if not runtime_error().is_empty() or (disengaged and not boss_entered) or (_boss_entered and not boss_entered) or (_disengaged and not disengaged):
		return false
	if not likeness.call("present_parent_disengagement", disengaged) or not garden.call("present_parent_disengagement", disengaged):
		return false
	_boss_entered = boss_entered
	_disengaged = disengaged
	likeness.position = _anchor(boss_entered)
	_approach_beauty.visible = not disengaged
	return runtime_error().is_empty()


## Closed derived cosmetic wire; floor/geometry/translations are never saved.
## The existing likeness owns its remaining cosmetic time, paused by the tree.
func presentation_state() -> Dictionary:
	return {"schema_version": PRESENTATION_SCHEMA, "boss_entered": _boss_entered, "disengaged": _disengaged, "likeness": likeness.call("presentation_state") if is_instance_valid(likeness) else {}}


func presentation_error(data: Dictionary, parent_boss_entered: bool, parent_disengaged: bool) -> String:
	var keys: Array = ["schema_version", "boss_entered", "disengaged", "likeness"]
	if data.size() != keys.size():
		return "Exact derived garden presentation fields required"
	for key: String in keys:
		if not data.has(key):
			return "Missing derived garden presentation field"
	if not Codec.is_integer(data.schema_version, PRESENTATION_SCHEMA, PRESENTATION_SCHEMA) or not data.boss_entered is bool or not data.disengaged is bool or data.boss_entered != parent_boss_entered or data.disengaged != parent_disengaged or (parent_disengaged and not parent_boss_entered) or not data.likeness is Dictionary:
		return "Garden presentation must match independently validated parent progress"
	if not is_instance_valid(likeness):
		return "Produced likeness consumer required for pure presentation validation"
	return String(likeness.call("presentation_error", data.likeness, parent_disengaged))


## Quiet no-yield commit, after parent whole-unit validation. A native paused
## transaction restores earlier beauty/fade and derives the one correct anchor.
## This restores no Hero/source/Scheduler/progress/camera/HUD or gameplay clock.
func restore_presentation(data: Dictionary, parent_boss_entered: bool, parent_disengaged: bool) -> bool:
	if not is_inside_tree() or not get_tree().paused or not runtime_error().is_empty() or not presentation_error(data, parent_boss_entered, parent_disengaged).is_empty():
		return false
	if not likeness.call("restore_presentation", data.likeness, parent_disengaged):
		return false
	if not garden.call("present_parent_disengagement", parent_disengaged):
		return false
	_boss_entered = parent_boss_entered
	_disengaged = parent_disengaged
	likeness.position = _anchor(parent_boss_entered)
	_approach_beauty.visible = not parent_disengaged
	return runtime_error().is_empty()


## The fixed approach observer is optional scenery when the Hero has passed.
## It must not force camera focus/zoom from51.5 while combat travels to36/18.
## Complete native quad remains explicit for representative portrait checking.
func likeness_framing_points(camera: Camera3D) -> Dictionary:
	var error: String = runtime_error()
	if not error.is_empty():
		return {"error": error, "points": []}
	var result: Dictionary = likeness.call("framing_points", camera)
	result.optional_scenery = true
	return result


## Required boss root bounds plus an OPTIONAL requested full likeness quad.
## No floor78/full peripheral-decoration AABB enters combat admission.
func framing_points(camera: Camera3D, include_likeness: bool = false) -> Dictionary:
	var optional: Dictionary = likeness_framing_points(camera)
	if not String(optional.get("error", "")).is_empty():
		return optional
	var points: Array = []
	if _boss_entered:
		var roots: Dictionary = garden.call("native_bounds", "roots")
		if not String(roots.get("error", "")).is_empty():
			return roots
		points.append_array(roots.points)
	if include_likeness and bool(optional.get("displayed_stage", false)):
		points.append_array(optional.points)
	return {"error": "", "points": points, "optional_likeness_points": optional.points, "likeness_displayed": optional.displayed_stage, "full_likeness_quad": true}


## Inspection-only actual native AABB8; optional beauty never forces admission.
func native_bounds(family: String = "approach_beauty") -> Dictionary:
	var error: String = runtime_error()
	if not error.is_empty() or family not in ["approach_beauty", "permanent", "floor"]:
		return {"error": error if not error.is_empty() else "Unknown scenic bound family", "points": []}
	var points: Array[Vector3] = []
	for spec: Dictionary in _parts:
		if spec.family != family:
			continue
		var part: MeshInstance3D = spec.node
		for corner: int in range(8):
			points.append(part.global_transform * part.mesh.get_aabb().get_endpoint(corner))
	if points.is_empty():
		return {"error": "Actual scenic bounds unavailable", "points": []}
	var bounds := AABB(points[0], Vector3.ZERO)
	for point: Vector3 in points:
		bounds = bounds.expand(point)
	var corners: Array[Vector3] = []
	for corner: int in range(8):
		corners.append(bounds.get_endpoint(corner))
	return {"error": "", "points": corners, "world_aabb": bounds, "actual_corner_samples": points.size(), "optional_scenery": true}


func runtime_error() -> String:
	if not _built or not is_inside_tree() or not is_node_ready() or is_queued_for_deletion() or not is_visible_in_tree() or transform != Transform3D.IDENTITY or global_transform != Transform3D.IDENTITY or process_mode != Node.PROCESS_MODE_PAUSABLE or not get_groups().is_empty() or get_child_count() != 5:
		return "Original ready identity False Paradise scenery root required"
	# Native typed-list construction rejects freed references before iteration.
	if not is_instance_valid(_kit) or not is_instance_valid(_approach_beauty) or not is_instance_valid(garden) or not is_instance_valid(likeness):
		return "Live harmless scenic consumers and helper hierarchy required"
	for node: Node3D in [_kit, _approach_beauty, garden, likeness]:
		if not is_instance_valid(node) or node.is_queued_for_deletion() or node.get_parent() != self or not node.get_groups().is_empty():
			return "Original harmless scenic consumers and helper hierarchy required"
	if _kit.transform != Transform3D.IDENTITY or _approach_beauty.transform != Transform3D.IDENTITY or garden.transform != Transform3D.IDENTITY or likeness.transform != Transform3D(Basis.IDENTITY, _anchor(_boss_entered)) or not _kit.visible or not garden.visible or not likeness.visible or _approach_beauty.visible != (not _disengaged) or _kit.get_child_count() != 12 or _approach_beauty.get_child_count() != 192 or _parts.size() != NEW_MESH_COUNT:
		return "Fixed scenic transforms/counts and derived single likeness anchor required"
	if not is_instance_valid(floor_body) or floor_body.is_queued_for_deletion() or not floor_body.is_inside_tree() or floor_body.get_parent() != self or not floor_body.visible or floor_body.top_level or floor_body.transform != Transform3D(Basis.IDENTITY, FLOOR_CENTER) or floor_body.global_transform != floor_body.transform or floor_body.collision_layer != 1 or floor_body.collision_mask != 0 or floor_body.constant_linear_velocity != Vector3.ZERO or floor_body.constant_angular_velocity != Vector3.ZERO or floor_body.disable_mode != _floor_disable_mode or floor_body.physics_material_override != null or not floor_body.get_groups().is_empty() or floor_body.get_child_count() != 2:
		return "Exact permanent14x1x78 floor at(0,-.5,25), layer1/mask0 required"
	var collider: CollisionShape3D = floor_body.get_child(0) as CollisionShape3D
	if not is_instance_valid(collider) or collider.is_queued_for_deletion() or not collider.is_inside_tree() or collider.name != "Solid" or collider.disabled or collider.transform != Transform3D.IDENTITY or collider.shape != _floor_shape or not is_instance_valid(_floor_shape) or _floor_shape.size != FLOOR_SIZE or _floor_shape.margin != _floor_margin or not collider.get_groups().is_empty() or collider.get_child_count() != 0:
		return "Original enabled first Solid and retained native floor shape required"
	for spec: Dictionary in _parts:
		if not is_instance_valid(spec.node) or not is_instance_valid(spec.mesh) or not is_instance_valid(spec.material):
			return "Live original scenic mesh and material resources required"
		var part: MeshInstance3D = spec.node
		if not is_instance_valid(part) or part.is_queued_for_deletion() or part.get_parent() != spec.parent or part.transform != spec.transform or part.global_transform != spec.global_transform or part.mesh != spec.mesh or part.mesh.get_aabb() != spec.aabb or part.material_override != spec.material or not part.visible or not part.get_groups().is_empty() or part.get_child_count() != 0 or part.layers != 1 or part.transparency != 0.0 or part.material_overlay != null or part.top_level or part.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			return "Original static noncolliding scenic mesh custody changed"
		var material: StandardMaterial3D = spec.material
		if material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.no_depth_test or material.albedo_color != spec.color or material.albedo_texture != null or material.next_pass != null or material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED or material.vertex_color_use_as_albedo != spec.vertex_color or material.cull_mode != spec.cull_mode or material.emission_enabled:
			return "Quiet opaque nearest ordinary-depth scenic material required"
		if part.mesh is ArrayMesh:
			if part.mesh.get_surface_count() != 1 or part.mesh.surface_get_arrays(0) != spec.arrays:
				return "Original filled mineral/bed/spine triangles changed"
		elif not part.mesh is BoxMesh or (part.mesh as BoxMesh).size != spec.size:
			return "Original low flower/arch/floor dimensions changed"
	var error: String = String(garden.call("runtime_error"))
	if not error.is_empty():
		return error
	error = String(likeness.call("runtime_error"))
	if not error.is_empty():
		return error
	if garden.call("state").disengaged != _disengaged:
		return "Boss garden stripping must match derived parent disengagement"
	return presentation_error(presentation_state(), _boss_entered, _disengaged)


func _anchor(boss_entered: bool) -> Vector3:
	return BOSS_ANCHOR if boss_entered else APPROACH_ANCHOR


func _approach_court(z: float, index: int) -> void:
	for side: float in [-1.0, 1.0]:
		# Back band is proposed static dressing, not dynamic escape-proof authority.
		var centre := Vector2(side * 2.25, z + 5.5)
		var bed: MeshInstance3D = _kit.call("_floor_polygon", PackedVector2Array(BED_CONTOUR), Vector3(centre.x, 0.003, centre.y), BED_COLOR)
		bed.name = "LowApproachBed%d_%s" % [index, str(side)]
		bed.reparent(_approach_beauty, false)
		_register(bed, "approach_beauty")
		for bloom: int in range(BLOOM_OFFSETS.size()):
			var at: Vector2 = centre + BLOOM_OFFSETS[bloom]
			_blossom(Vector3(at.x, 0, at.y), index * 6 + bloom + (3 if side > 0 else 0))
		var patch: MeshInstance3D = _kit.call("_floor_polygon", PackedVector2Array([Vector2(-0.65, -1.6), Vector2(0.45, -1.35), Vector2(0.78, 0.6), Vector2(-0.3, 1.5), Vector2(-0.8, 0.5)]), Vector3(side * 5.2, 0.002, z), Color("3d3442"))
		patch.name = "PermanentQuietMineral%d_%s" % [index, str(side)]
		_register(patch, "permanent")
		# Complete raised extents stay outside the full±7 floor, not just a lane.
		var old_count: int = _kit.get_child_count()
		_kit.call("_rock_spine", Vector3(side * 8.5, 0, z - 2.6), 1.1 + float(index % 2) * 0.2, side, _kit)
		var spine: MeshInstance3D = _kit.get_child(old_count) as MeshInstance3D
		spine.name = "PermanentOffFloorSpine%d_%s" % [index, str(side)]
		_register(spine, "permanent")
		_arch(Vector3(side * 8.5, 0, z + 1.5), index, side)


## Same nine-box pale blossom vocabulary as the published boss dressing.
## SoleY0, maximumY.1675, no outlines/emission/physical interaction.
func _blossom(at: Vector3, index: int) -> void:
	_beauty_box("Stem%d" % index, Vector3(0.028, 0.13, 0.028), at + Vector3(0, 0.065, 0), STEM_COLOR)
	_beauty_box("LeafA%d" % index, Vector3(0.14, 0.012, 0.045), at + Vector3(-0.05, 0.065, 0), STEM_COLOR, -28.0)
	_beauty_box("LeafB%d" % index, Vector3(0.13, 0.012, 0.045), at + Vector3(0.045, 0.075, 0), STEM_COLOR, 34.0)
	for petal: int in range(5):
		var angle: float = TAU * float(petal) / 5.0 + float(index % 2) * 0.24
		_beauty_box("Petal%d_%d" % [index, petal], Vector3(0.10, 0.020, 0.13), at + Vector3(sin(angle) * 0.063, 0.145 + float(petal % 2) * 0.005, cos(angle) * 0.063), PETAL_COLOR, rad_to_deg(angle))
	_beauty_box("QuietCentre%d" % index, Vector3(0.055, 0.025, 0.055), at + Vector3(0, 0.155, 0), Color("96917b"))


func _arch(at: Vector3, index: int, side: float) -> void:
	# Open side forks, no centre lintel/halo/full ring; ordinary depth only.
	var label: String = "%d_%s" % [index, str(side)]
	_beauty_box("SideStem" + label, Vector3(0.19, 1.42, 0.22), at + Vector3(0, 0.71, 0), ARCH_COLOR)
	_beauty_box("SideUpper" + label, Vector3(0.16, 0.60, 0.20), at + Vector3(0, 1.63, -0.12), ARCH_COLOR)
	_beauty_box("SideFork" + label, Vector3(0.14, 0.18, 0.69), at + Vector3(side * 0.14, 1.85, -0.12), ARCH_COLOR, side * 18.0)
	_beauty_box("SideRootFoot" + label, Vector3(0.45, 0.055, 0.42), at + Vector3(0, 0.0275, 0), Color("63525e"))


func _beauty_box(label: String, size: Vector3, at: Vector3, color: Color, yaw: float = 0.0) -> void:
	var part: MeshInstance3D = _kit.call("_box", size, at, color)
	part.name = label
	part.rotation_degrees.y = yaw
	part.reparent(_approach_beauty, false)
	_register(part, "approach_beauty")


func _register(part: MeshInstance3D, family: String) -> void:
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material: StandardMaterial3D = part.material_override
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	var spec: Dictionary = {"node": part, "family": family, "parent": part.get_parent(), "transform": part.transform, "global_transform": part.global_transform, "mesh": part.mesh, "aabb": part.mesh.get_aabb(), "material": material, "color": material.albedo_color, "vertex_color": material.vertex_color_use_as_albedo, "cull_mode": material.cull_mode}
	if part.mesh is ArrayMesh:
		spec.arrays = part.mesh.surface_get_arrays(0).duplicate(true)
	else:
		spec.size = (part.mesh as BoxMesh).size
	_parts.append(spec)
