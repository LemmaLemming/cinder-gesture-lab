extends CinderLevel
## Quiet art-only consumer. Actual shared Hero/floor/camera, no combat or clock.

const Shore: GDScript = preload("res://scripts/acts/act3/mirror_sea_scenery.gd")
const Modules: GDScript = preload("res://scripts/acts/act3/mirror_shore_modules.gd")
const API: String = "act3-mirror-shore-modules-preview-1"
const COURT_ID: String = "quiet-central-shore"

var scenery: Node3D
var modules: Node3D
var last_configuration_error: String = ""


func _ready() -> void:
	process_physics_priority = 130
	scenery = Shore.new()
	scenery.name = "UnchangedMirrorSeaScenery"
	add_child(scenery)
	scenery.call("build", true)
	modules = Modules.new()
	modules.name = "QuietCourtShoreModules"
	add_child(modules)
	if not modules.call("build", COURT_ID, 0.0):
		last_configuration_error = String(modules.get("last_error"))
	else:
		last_configuration_error = runtime_error()


func _on_enter_level() -> void:
	scenery.call("show_sun", 0, "stable")
	_follow_distant_scenery()


func _physics_process(_delta: float) -> void:
	_follow_distant_scenery() # No local counter/timer or moving court modules.


func _follow_distant_scenery() -> void:
	if is_instance_valid(hero) and is_instance_valid(scenery):
		scenery.call("follow_landmarks", Vector3(hero.global_position.x, 0, 0.4))


func runtime_error() -> String:
	if not last_configuration_error.is_empty():
		return last_configuration_error
	if global_transform != Transform3D.IDENTITY or not is_instance_valid(scenery) or not is_instance_valid(modules) or scenery.get_parent() != self or modules.get_parent() != self or scenery.get_script() != Shore or modules.get_script() != Modules:
		return "Quiet module preview requires its retained untransformed native builders"
	var error: String = scenery.call("runtime_error")
	if not error.is_empty():
		return error
	var native: Dictionary = modules.call("state")
	if not native.built or native.court_id != COURT_ID or native.court_z != 0.0 or not String(native.error).is_empty() or modules.global_transform != Transform3D.IDENTITY or modules.get_child_count() != 32:
		return "Quiet preview requires its32 fixed court-relative module pieces"
	return ""


func state() -> Dictionary:
	return {"api_revision": API, "configuration_error": runtime_error(), "modules": modules.call("state") if is_instance_valid(modules) else {}}


func _camera_framing_points() -> Array:
	# Decorative edges need not fit. The real shared Hero remains mandatory;
	# the shell owns normal following and adds these same native bounds.
	if not is_instance_valid(shared_shell) or not is_instance_valid(hero):
		return []
	return shared_shell.call("player_camera_framing_points")


func _capture_local_state() -> Dictionary:
	return {"api_revision": API, "court_id": COURT_ID, "court_z": 0.0, "sun_presentation": 0}


func _local_snapshot_error(data: Dictionary) -> String:
	var error: String = runtime_error()
	if not error.is_empty():
		return error
	if data.size() != 4 or data.get("api_revision") != API or data.get("court_id") != COURT_ID or data.get("court_z") != 0.0 or data.get("sun_presentation") != 0:
		return "Quiet preview keeps exactly its immutable court/sun presentation"
	return ""


func _restore_local_state(_data: Dictionary) -> void:
	scenery.call("show_sun", 0, "stable")
	_follow_distant_scenery() # Quiet still rebuilding; no Hero resources/events/progress.
