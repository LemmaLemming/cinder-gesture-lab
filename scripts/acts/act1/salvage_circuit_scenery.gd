class_name Act1SalvageCircuitScenery
extends Node3D
## SOURCE ONLY GREYBOX: unchanged L5 finless capsule; no new authored kit.
## Closed/open hatch placeholder, clockless; parent owns real contact/repair.

const CapsuleScript = preload("res://scripts/acts/act1/living_moon_capsule.gd")
const CAPSULE_POSITION: Vector3 = Vector3(0, 0, 2)
var _built: bool = false
var _capsule: Act1LivingMoonCapsule
var _repaired: bool = false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED


func build(level: Node3D) -> void:
	if _built or not is_instance_valid(level) or level.is_queued_for_deletion() or (get_parent() != null and get_parent() != level): return
	name = "Scenery"
	if get_parent() == null: level.add_child(self)
	_built = true
	set_meta("readiness", "greybox_source_only_unparsed_unexecuted")
	_capsule = CapsuleScript.new()
	_capsule.name = "ExistingFinlessCapsule"
	_capsule.position = CAPSULE_POSITION
	add_child(_capsule)
	set_repaired(false)


func set_repaired(repaired: bool) -> bool:
	if not is_instance_valid(_capsule): return false
	_repaired = repaired
	_capsule.set_hatch_open(repaired)
	return true


func set_presentation_camera(camera: Camera3D) -> bool:
	return is_instance_valid(_capsule) and _capsule.set_presentation_camera(camera)


func presentation_state() -> Dictionary:
	return {"family": "act1_lunar_theatre_salvage", "repaired": _repaired,
		"damage_seams_visible": false, # No authored seam art in mechanics greybox.
		"capsule": _capsule.presentation_state() if is_instance_valid(_capsule) else {}}


func capsule_world_corners() -> Array[Vector3]:
	if not is_inside_tree() or not is_instance_valid(_capsule): return [Vector3.INF]
	return _complete_world_aabb(_capsule.world_corners())


func world_corners() -> Array[Vector3]:
	return capsule_world_corners()


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
