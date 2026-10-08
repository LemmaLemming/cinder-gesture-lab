extends CinderLevel
## Isolated A3-L2 role-permitted STRIP scaffold. This is not the canonical
## crescent teaching beat or the completed Living Forest level.
## Shared shell/Player/Scheduler/LaneMechanism own controls and attack proof.

const RootScript = preload("res://scripts/acts/act3/root_latcher.gd")
const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const ENCOUNTER_ID: String = "A3-L2/root-strip-scaffold"
const SOURCE_ID: String = "root-strip-source"
const FLOOR_RECT: Rect2 = Rect2(-4.8, -5.8, 9.6, 11.6)

var root_latcher: StaticBody3D
var threat_scheduler: CinderThreatScheduler
var floor_body: StaticBody3D
var last_configuration_error: String = ""
var _floor_region: Dictionary = {}
var _active: bool = false
var _forecast_points: Array = []


func _ready() -> void:
	process_physics_priority = 130
	_build_floor()
	threat_scheduler = SchedulerScript.new()
	threat_scheduler.name = "RootRuleScheduler"
	add_child(threat_scheduler)
	root_latcher = RootScript.new()
	root_latcher.name = "FixedRootLatcher"
	add_child(root_latcher)
	root_latcher.global_position = Vector3(0, 0, -0.4)


func _build_floor() -> void:
	floor_body = StaticBody3D.new()
	floor_body.name = "ContinuousDryCourt"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	floor_body.position.y = -0.5
	add_child(floor_body)
	var collision := CollisionShape3D.new()
	collision.name = "FloorCollision"
	var box := BoxShape3D.new()
	box.size = Vector3(10, 1, 12)
	collision.shape = box
	floor_body.add_child(collision)
	var mesh := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = box.size
	mesh.mesh = slab
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("454252")
	material.roughness = 0.85
	mesh.material_override = material
	floor_body.add_child(mesh)
	_floor_region = {"collision": collision, "safe_rect": FLOOR_RECT}


func _on_enter_level() -> void:
	_active = true
	var profile: String = "standard"
	if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference"):
		profile = String(shared_shell.call("get_difficulty_preference"))
	if not threat_scheduler.begin_encounter(profile, ENCOUNTER_ID, 1):
		last_configuration_error = threat_scheduler.last_error
		return
	if not root_latcher.call("configure", SOURCE_ID, hero, effects, threat_scheduler, combat_response, framing_guard):
		last_configuration_error = String(root_latcher.get("last_error"))
		return
	_update_guidance()


func _on_exit_level() -> void:
	_active = false
	if is_instance_valid(threat_scheduler):
		threat_scheduler.end_encounter("root_rule_exit")


func _physics_process(_delta: float) -> void:
	if _active:
		_update_guidance()


func combat_response() -> Dictionary:
	if not is_instance_valid(hero) or not is_instance_valid(root_latcher):
		return {}
	var response: Dictionary = hero.get_threat_response_state()
	var distance: float = float(response.stats.dash_distance)
	var landing: Vector3 = hero.global_position + Vector3.RIGHT * distance
	var toward_source: Vector3 = root_latcher.global_position - landing
	toward_source.y = 0
	var return_direction: Vector3 = toward_source.normalized()
	response["world_root"] = get_parent() as Node3D
	response["world_revision"] = 1
	response["recognition_s"] = 0.25
	response["attack_input_margin_s"] = 0.06
	response["escape_directions"] = [Vector3.RIGHT]
	response["return_directions"] = [return_direction]
	response["floor_regions"] = [_floor_region]
	response["encounter_id"] = ENCOUNTER_ID
	return response


func _camera_framing_points() -> Array:
	if not _active or not is_instance_valid(hero) or not is_instance_valid(shared_shell):
		return []
	var source: Dictionary = root_latcher.call("state")
	if source.get("dead", false):
		return []
	if source.get("phase", "idle") in ["idle", "clear"]:
		_refresh_forecast()
	if not last_camera_framing_error.is_empty():
		return []
	return _forecast_points.duplicate()


func _refresh_forecast() -> void:
	_forecast_points.clear()
	var origin: Vector3 = root_latcher.global_position
	# The fixed strip's entire radius/endcaps and actual low bulb bounds.
	for x: float in [-0.35, 0.35]:
		for z: float in [-0.35, 2.65]:
			_forecast_points.append(origin + Vector3(x, 0.03, z))
	for x: float in [-0.32, 0.32]:
		for y: float in [0.0, 0.64]:
			for z: float in [-0.32, 0.32]:
				_forecast_points.append(origin + Vector3(x, y, z))
	if root_latcher.has_method("framing_points"):
		var art_bounds: Dictionary = root_latcher.call("framing_points", shared_shell)
		if not String(art_bounds.get("error", "")).is_empty():
			last_camera_framing_error = String(art_bounds.error)
			return
		_forecast_points.append_array(art_bounds.get("points", []))
	var native_player: Array = shared_shell.call("player_camera_framing_points")
	var response: Dictionary = combat_response()
	var distance: float = float(response.stats.dash_distance)
	var escape_shift: Vector3 = Vector3.RIGHT * distance
	var return_shift: Vector3 = escape_shift + response.return_directions[0] * distance
	for shift: Vector3 in [Vector3.ZERO, escape_shift, return_shift]:
		for point: Vector3 in native_player:
			_forecast_points.append(point + shift)


func framing_guard(current_view: bool) -> String:
	if not is_instance_valid(shared_shell) or not shared_shell.has_method("camera_framing_plan"):
		return "Ready shared portrait camera required"
	if _forecast_points.is_empty():
		_refresh_forecast()
	if not last_camera_framing_error.is_empty():
		return last_camera_framing_error
	if current_view:
		return String(shared_shell.call("camera_framing_error", _forecast_points))
	var plan: Dictionary = shared_shell.call("camera_framing_plan", _forecast_points, hero.global_position)
	return "" if plan.get("accepted", false) else String(plan.get("reason", "Root strip forecast cannot fit"))


func scheduler_bindings() -> Dictionary:
	return {"world_root": get_parent(), "owners": root_latcher.call("scheduler_owners"), "floors": {"root-court": _floor_region}, "actors": {"hero": hero}}


func _update_guidance() -> void:
	if not last_configuration_error.is_empty():
		objective_text = "ROOT RULE: " + last_configuration_error
		return
	if not is_instance_valid(root_latcher):
		return
	var source: Dictionary = root_latcher.call("state")
	if source.get("dead", false):
		objective_text = "Strip scaffold cleared — crescent teaching beat remains pending"
	elif source.get("phase", "idle") == "recovery":
		objective_text = "Return to the low exposed knot; ordinary primary"
	else:
		objective_text = "Strip scaffold: bait the fixed root; land on its flank"
