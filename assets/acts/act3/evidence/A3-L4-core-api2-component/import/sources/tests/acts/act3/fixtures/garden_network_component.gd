extends CinderLevel
## TEST ONLY native component recipient: no authored route or whole-level codec.
## One published API2 core, one Scheduler, the actual 14x78 authored floor,
## and Main's one actual Player. Sources admit only through explicit try_start.

const CoreScript = preload("res://scripts/acts/act3/garden_root_network.gd")
const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const SceneryScript = preload("res://scripts/acts/act3/false_paradise_scenery.gd")
const ENCOUNTER_ID: String = "garden-network-component"
const WORLD_REVISION: int = 1
const FLOOR_ID: String = "garden-component-floor"
const FLOOR_RECT := Rect2(-7, -14, 14, 78)
const SAVE_LIMIT: String = "TEST ONLY garden network component has no CinderLevel or campaign save codec"

var root_network: Node3D
var threat_scheduler: CinderThreatScheduler
var scenery: Node3D
var configuration_error: String = ""
var _floor: Dictionary = {}
var _live: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	scenery = SceneryScript.new()
	scenery.name = "ActualFalseParadiseScenery"
	add_child(scenery)
	if not scenery.call("build"):
		configuration_error = "Actual authored scenery/floor build failed"
		return
	# This declared component starts in the root court; no route is earned.
	# The cosmetic anchor is derived from that fixed fixture metadata.
	if not scenery.call("show_progress", true, false):
		configuration_error = "Native root-court scenery presentation failed"
		return
	var body: StaticBody3D = scenery.get("floor_body") as StaticBody3D
	_floor = {"collision": body.get_node("Solid"), "safe_rect": FLOOR_RECT}
	threat_scheduler = SchedulerScript.new()
	threat_scheduler.name = "OneActualScheduler"
	add_child(threat_scheduler)
	root_network = CoreScript.new()
	root_network.name = "ActualRootNetwork"
	add_child(root_network)


func _on_enter_level() -> void:
	if not configuration_error.is_empty() or not is_instance_valid(root_network) or not is_instance_valid(threat_scheduler):
		return
	var profile: String = String(shared_shell.call("get_difficulty_preference")) if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference") else "standard"
	if not threat_scheduler.begin_encounter(profile, ENCOUNTER_ID, WORLD_REVISION):
		configuration_error = "One actual native encounter must begin before binding"
		return
	if not root_network.call("configure", self, hero, effects, shared_shell, threat_scheduler, get_parent() as Node3D, {FLOOR_ID: _floor}, _response, _view_guard, ENCOUNTER_ID, WORLD_REVISION):
		configuration_error = String(root_network.get("last_configuration_error"))
		return
	if not root_network.call("set_active", true):
		configuration_error = "Actual configured core must enable without admission"
		return
	_live = true


func scheduler_bindings() -> Dictionary:
	return {"world_root": get_parent(), "owners": root_network.call("scheduler_owners"), "actors": {"hero": hero}, "floors": {FLOOR_ID: _floor}}


func _response(_kind: String, direction: Vector3) -> Dictionary:
	return {"encounter_id": ENCOUNTER_ID, "world_revision": WORLD_REVISION, "recognition_s": 0.25, "attack_input_margin_s": 0.06, "escape_directions": [direction], "return_directions": [-direction], "floor_regions": [_floor]}


func _view_guard(current_view: bool, prospective: Dictionary) -> String:
	if not _live or not runtime_error().is_empty():
		return "Actual live component custody required for optics"
	var bounds: Dictionary = root_network.call("framing_points_for_context", get_viewport().get_camera_3d(), prospective)
	if not bounds.get("accepted", false):
		return String(bounds.get("reason", "Complete actual native component bounds required"))
	if current_view:
		return String(shared_shell.call("camera_framing_error", bounds.points))
	var plan: Dictionary = shared_shell.call("camera_framing_plan", bounds.points, hero.global_position + Vector3.UP * 0.75)
	return "" if plan.get("accepted", false) else String(plan.get("reason", "Actual camera plan refused"))


func _camera_framing_points() -> Array:
	if not _live:
		return []
	var bounds: Dictionary = root_network.call("framing_points_for_context", get_viewport().get_camera_3d())
	if not bounds.get("accepted", false):
		last_camera_framing_error = String(bounds.get("reason", "Actual native component bounds required"))
		return []
	return bounds.points


func runtime_error() -> String:
	if not configuration_error.is_empty():
		return configuration_error
	if not _live or not is_instance_valid(scenery) or not is_instance_valid(root_network) or not is_instance_valid(threat_scheduler) or not is_instance_valid(hero) or not is_instance_valid(shared_shell):
		return "Actual entered native component bindings required"
	var error: String = String(scenery.call("runtime_error"))
	if error.is_empty():
		error = String(root_network.call("runtime_error"))
	return error


func state() -> Dictionary:
	return {"configuration_error": configuration_error, "core": root_network.call("state") if is_instance_valid(root_network) else {}, "clock_s": threat_scheduler.get_clock() if is_instance_valid(threat_scheduler) else 0.0}


func _capture_local_state() -> Dictionary:
	last_snapshot_error = SAVE_LIMIT
	return {}


func _local_snapshot_error(_local: Dictionary) -> String:
	return SAVE_LIMIT


func _local_snapshot_error_with_player(_local: Dictionary, _saved_player: Dictionary) -> String:
	return SAVE_LIMIT


func _on_enter_restore_candidate(_local: Dictionary, _saved_player: Dictionary) -> String:
	return SAVE_LIMIT


func _restore_local_state(_local: Dictionary) -> void:
	last_snapshot_error = SAVE_LIMIT


func snapshot_state_for_presentation(_camera: Camera3D, _hud: GameHUD) -> Dictionary:
	last_snapshot_error = SAVE_LIMIT
	return {}


func _on_exit_level() -> void:
	_live = false
	if is_instance_valid(root_network) and root_network.is_inside_tree():
		root_network.call("retire", "garden_component_exit")
	if is_instance_valid(threat_scheduler):
		threat_scheduler.end_encounter("garden_component_exit")

