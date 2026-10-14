class_name Act1SalvageCircuitPart
extends Node3D
## SOURCE ONLY GREYBOX: one stationary contact collectible; neutral low Box.
## Parent owns real eligibility, collected IDs, cue notifications and cleanup.
## No body-entered callback, attack receiver, inventory, reward or private timer.

const IDS: Array[String] = ["nose-cap", "rivet-band", "hatch-disc"]
const STATES: Array[String] = ["available", "active", "spent"]
const CONTACT_SIZE: Vector3 = Vector3(0.9, 1.2, 0.9)
const CONTACT_OFFSET: Vector3 = Vector3(0, 0.6, 0)

var _part_id: String = ""
var _state: String = "available"
var _art: Node3D
var _area: Area3D
var _collision: CollisionShape3D
var _cue: CinderInteractionCue
var _meshes: Array[MeshInstance3D] = []


func configure(id: String) -> bool:
	if is_inside_tree() or not _part_id.is_empty() or id not in IDS: return false
	_part_id = id
	name = id
	set_meta("reuse_family", "act1_finless_capsule_recoverable_fragment")
	set_meta("readiness", "source_only_unparsed_unexecuted_portrait_unverified")
	_art = Node3D.new()
	_art.name = "FragmentPresentation"
	_art.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(_art)
	_build_fragment()
	_area = Area3D.new()
	_area.name = "ContactArea"
	_area.position = CONTACT_OFFSET
	_area.collision_layer = 0
	_area.collision_mask = 4
	_area.monitorable = false
	_collision = CollisionShape3D.new()
	_collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = CONTACT_SIZE
	_collision.shape = shape
	_area.add_child(_collision)
	add_child(_area)
	_cue = CinderInteractionCue.new()
	_cue.name = "ContactInteractionCue"
	add_child(_cue)
	return true


func set_state(state: String) -> bool:
	# Renderer only. The parent separately uses the existing shared cue API.
	if _part_id.is_empty() or state not in STATES: return false
	_state = state
	_art.visible = state != "spent"
	return true


func presentation_state() -> Dictionary:
	return {"part_id": _part_id, "state": _state, "fragment_visible": is_instance_valid(_art) and _art.visible}


func get_cue() -> CinderInteractionCue:
	return _cue


func contact_area() -> Area3D:
	return _area


func contact_collision() -> CollisionShape3D:
	return _collision


func contact_corners() -> Array[Vector3]:
	if not is_inside_tree() or not is_instance_valid(_collision) or not _collision.shape is BoxShape3D: return [Vector3.INF]
	var size: Vector3 = (_collision.shape as BoxShape3D).size
	return _box_points(AABB(-size * 0.5, size), _collision.global_transform)


func cue_corners() -> Array[Vector3]:
	if not is_inside_tree() or not is_instance_valid(_cue): return [Vector3.INF]
	var marker: MeshInstance3D = _cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
	if marker == null or marker.mesh == null or not marker.is_visible_in_tree(): return []
	return _box_points(marker.get_aabb(), marker.global_transform)


func world_corners() -> Array[Vector3]:
	if not is_inside_tree(): return [Vector3.INF]
	var points: Array[Vector3] = contact_corners()
	for mesh: MeshInstance3D in _meshes:
		if mesh.is_visible_in_tree(): points.append_array(_box_points(mesh.get_aabb(), mesh.global_transform))
	points.append_array(cue_corners())
	# Full current extent, not per-rivet allocation. Every visible mesh and
	# retained contact/cue remains inside this conservative complete world AABB.
	return _complete_world_aabb(points)


func _build_fragment() -> void:
	# Neutral contact placeholder; authored three-fragment meshes remain staged.
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.5, 0.25, 0.5)
	_mesh("GreyboxContactPart", mesh, Vector3(0, 0.125, 0), Color("939393"))


func _mesh(label: String, geometry: Mesh, origin: Vector3, color: Color) -> void:
	var visual := MeshInstance3D.new()
	visual.name = label
	visual.mesh = geometry
	visual.position = origin
	visual.process_mode = Node.PROCESS_MODE_DISABLED
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	visual.material_override = material
	_art.add_child(visual)
	_meshes.append(visual)


static func _box_points(bounds: AABB, frame: Transform3D) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]: points.append(frame * Vector3(x, y, z))
	return points


static func _complete_world_aabb(points: Array[Vector3]) -> Array[Vector3]:
	if points.is_empty(): return []
	var minimum: Vector3 = points[0]
	var maximum: Vector3 = points[0]
	for point: Vector3 in points:
		if not point.is_finite(): return [Vector3.INF]
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return _box_points(AABB(minimum, maximum - minimum), Transform3D.IDENTITY)
