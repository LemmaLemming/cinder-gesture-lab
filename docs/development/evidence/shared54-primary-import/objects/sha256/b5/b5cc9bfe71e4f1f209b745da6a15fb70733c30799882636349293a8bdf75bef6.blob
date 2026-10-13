extends CinderLevel
## Quiet original lake-instrument art fixture using the real shared traveller/camera/controls.
## No enemy, hazard, interaction, progress, checkpoint, save or resource grant.
## Sun selection is explicit still presentation, never a transition clock.

const SceneryScript: GDScript = preload("res://scripts/acts/act3/mirror_sea_scenery.gd")
const WitnessScript: GDScript = preload("res://scripts/acts/act3/mirror_irontick_scenery.gd")
const OWNED_API: String = "act3-mirror-irontick-art-preview-1"
const WITNESS_POSITION: Vector3 = Vector3.ZERO

var scenery: Node3D
var witnesses: Node3D
var last_configuration_error: String = ""
var _sun_state: int = 0


func _ready() -> void:
	process_physics_priority = 130
	scenery = SceneryScript.new() as Node3D
	scenery.name = "QuietMirrorShore"
	add_child(scenery)
	scenery.call("build", true)
	witnesses = WitnessScript.new() as Node3D
	witnesses.name = "IrontickAndKneelingEarthridScenery"
	witnesses.position = WITNESS_POSITION
	add_child(witnesses)
	witnesses.call("build", true)
	last_configuration_error = _dependency_error()


func _on_enter_level() -> void:
	set_sun_presentation(0)


func _physics_process(_delta: float) -> void:
	# This tail only follows the actual traveller. It has no local clock.
	if is_instance_valid(hero) and is_instance_valid(scenery):
		scenery.call("follow_landmarks", hero.global_position)
	var error: String = _dependency_error()
	if not error.is_empty():
		last_configuration_error = error


func set_sun_presentation(value: int) -> bool:
	if value not in [0, 1] or not is_instance_valid(hero):
		return false
	var error: String = _dependency_error()
	if not error.is_empty():
		last_configuration_error = error
		return false
	_sun_state = value
	# These are the actual scenery's public sun meshes and stable pose API.
	scenery.call("show_sun", value, "stable")
	scenery.call("follow_landmarks", hero.global_position)
	return true


func state() -> Dictionary:
	return {"api_revision": OWNED_API, "sun_state": _sun_state, "sun_stage": "stable", "configuration_error": runtime_error()}


func runtime_error() -> String:
	return last_configuration_error if not last_configuration_error.is_empty() else _dependency_error()


func _dependency_error() -> String:
	if not is_instance_valid(scenery) or scenery.get_parent() != self or not is_instance_valid(witnesses) or witnesses.get_parent() != self:
		return "Quiet shore requires its actual scenery and static lake/figure builder"
	if witnesses.transform != Transform3D(Basis.IDENTITY, WITNESS_POSITION) or global_transform != Transform3D.IDENTITY:
		return "Quiet shore requires its fixed untransformed authored floor and cast"
	if witnesses.get_child_count() != 31:
		return "Quiet shore requires exactly its31 authored native meshes"
	var error: String = String(scenery.call("runtime_error"))
	if not error.is_empty():
		return error
	return String(witnesses.call("runtime_error"))


## All248 actual native mesh corners are conservatively enclosed by eight
## world-AABB corners. This preserves the complete pool, rim and kneeling
## figure while respecting the shared level's224-point limit.
func art_framing_points() -> Dictionary:
	var error: String = runtime_error()
	if not error.is_empty():
		return {"error": error, "points": []}
	var native: Dictionary = witnesses.call("framing_points")
	if not String(native.error).is_empty() or native.points.size() != 248:
		return {"error": "Irontick requires all248 actual original mesh corners", "points": []}
	var low: Vector3 = native.points[0]
	var high: Vector3 = low
	for point: Vector3 in native.points:
		if not point.is_finite():
			return {"error": "Native lake/figure bounds require finite world corners", "points": []}
		low = low.min(point)
		high = high.max(point)
	var points: Array = []
	for x: float in [low.x, high.x]:
		for y: float in [low.y, high.y]:
			for z: float in [low.z, high.z]:
				points.append(Vector3(x, y, z))
	return {"error": "", "points": points}


func _camera_framing_points() -> Array:
	# The shell asks once during initial construction before enter_level.
	if not is_instance_valid(shared_shell):
		return []
	var result: Dictionary = art_framing_points()
	last_camera_framing_error = String(result.error)
	return result.points


func _capture_local_state() -> Dictionary:
	return {"api_revision": OWNED_API, "sun_state": _sun_state, "sun_stage": "stable"}


func _local_snapshot_error(data: Dictionary) -> String:
	var error: String = runtime_error()
	if not error.is_empty():
		return error
	if data.size() != 3 or data.get("api_revision") != OWNED_API or data.get("sun_stage") != "stable":
		return "Quiet shore snapshot requires its declared static presentation schema"
	var value: Variant = data.get("sun_state")
	if not (value is int or value is float) or value not in [0, 1]:
		return "Quiet shore snapshot requires actual sun presentation0 or1"
	return ""


func _restore_local_state(data: Dictionary) -> void:
	# Only an already validated scenery still is restored; no events/resources.
	_sun_state = int(data.sun_state)
	scenery.call("show_sun", _sun_state, "stable")
	scenery.call("follow_landmarks", hero.global_position)
