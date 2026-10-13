extends CinderLevel
## Isolated A3-L2 native crescent rule room; full Living Forest is separate.
## Shared shell/Player/Scheduler/LaneMechanism own controls and attack proof.

const RootScript = preload("res://scripts/acts/act3/root_latcher.gd")
const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const MechanismScript = preload("res://scripts/combat/lane_mechanism.gd")
const ENCOUNTER_ID: String = "A3-L2/root-crescent-rule"
const SOURCE_ID: String = "root-crescent-source"
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
	_refresh_forecast()
	if not last_camera_framing_error.is_empty():
		return []
	return _forecast_points.duplicate()


func _prospective_exchange() -> Dictionary:
	var supplied: Dictionary = combat_response()
	var context: Dictionary = {}
	for key: String in MechanismScript.RESPONSE_KEYS:
		if not supplied.has(key):
			return {}
		context[key] = supplied[key]
	var bearing: Vector3 = hero.global_position - root_latcher.global_position
	bearing.y = 0.0
	if bearing.length_squared() == 0.0:
		return {}
	return root_latcher.call("get_mechanism").preview_start("hero", context, null, bearing.normalized())


func _refresh_forecast(prospective: Dictionary = {}) -> void:
	_forecast_points.clear()
	last_camera_framing_error = ""
	var source: Dictionary = root_latcher.call("state")
	var selected: Dictionary = root_latcher.call("get_selected_response")
	var geometry: Dictionary = root_latcher.call("get_selected_geometry")
	if prospective.is_empty() and source.get("phase", "idle") in ["idle", "clear"]:
		prospective = _prospective_exchange()
	if prospective.get("accepted", false):
		geometry = prospective.candidate.geometry
		selected = {"landing": prospective.proof.landing, "attack_position": prospective.proof.attack_position}
	var art_bounds: Dictionary = root_latcher.call("framing_points", shared_shell, geometry)
	if not String(art_bounds.get("error", "")).is_empty() or art_bounds.get("points", []).is_empty():
		last_camera_framing_error = String(art_bounds.get("error", "Native source bounds are empty"))
		return
	# A conservative box contains every actual body/art/arc corner. Compression
	# preserves all complete native bounds under the shared224-corner budget.
	_forecast_points.append_array(_enclosing_corners(art_bounds.points))
	var native_player: Array = shared_shell.call("player_camera_framing_points")
	if native_player.is_empty():
		last_camera_framing_error = "Actual shared player bounds required"
		return
	var shifts: Array[Vector3] = [Vector3.ZERO]
	for key: String in ["landing", "attack_position"]:
		if selected.has(key) and selected[key] is Vector3 and selected[key].is_finite():
			shifts.append(selected[key] - hero.global_position)
	for shift: Vector3 in shifts:
		for point: Vector3 in native_player:
			_forecast_points.append(point + shift)


func _enclosing_corners(points: Array) -> Array:
	var low: Vector3 = points[0]
	var high: Vector3 = low
	for point: Vector3 in points:
		low = low.min(point)
		high = high.max(point)
	var corners: Array = []
	for x: float in [low.x, high.x]:
		for y: float in [low.y, high.y]:
			for z: float in [low.z, high.z]:
				corners.append(Vector3(x, y, z))
	return corners


func framing_guard(current_view: bool, prospective: Dictionary = {}) -> String:
	if not is_instance_valid(shared_shell) or not shared_shell.has_method("camera_framing_plan"):
		return "Ready shared portrait camera required"
	_refresh_forecast(prospective)
	if not last_camera_framing_error.is_empty():
		return last_camera_framing_error
	if current_view:
		return String(shared_shell.call("camera_framing_error", _forecast_points))
	var plan: Dictionary = shared_shell.call("camera_framing_plan", _forecast_points, hero.global_position)
	return "" if plan.get("accepted", false) else String(plan.get("reason", "Root crescent exchange cannot fit"))


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
		objective_text = "Root rule cleared — Living Forest route continues separately"
	elif source.get("phase", "idle") == "recovery":
		objective_text = "Return to the low exposed knot; ordinary primary"
	else:
		objective_text = "Bait the fixed root; circle its committed crescent"
