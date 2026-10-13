extends CinderLevel
## Independent L3 shore production fixture, covering the familiar first beat.
## No Echo placeholder, player capture, campaign completion or resource grant.

const SceneryScript = preload("res://scripts/acts/act3/mirror_sea_scenery.gd")
const StalkerScript = preload("res://scripts/acts/act3/sunbound_stalker.gd")
const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ParentData: String = "res://data/campaign/act3/a3_l1_encounters.json"
const SOURCE_ID: String = "shore-stalker"
const ENCOUNTER_ID: String = "A3-L3/shore-preview"
const OWNED_API: String = "act3-mirror-shore-preview-1"
const FloorRect: Rect2 = Rect2(-7.0, -11.0, 14.0, 22.0)

var scenery: Node3D
var stalker: CharacterBody3D
var threat_scheduler: CinderThreatScheduler
var last_configuration_error: String = ""
var _floor_region: Dictionary = {}
var _active: bool = false


func _ready() -> void:
	process_physics_priority = 30
	scenery = SceneryScript.new()
	scenery.name = "MirrorShoreScenery"
	add_child(scenery)
	scenery.call("build", true)
	var floor_body: StaticBody3D = scenery.get("floor_body") as StaticBody3D
	var solid: CollisionShape3D = floor_body.get_node_or_null("Solid") as CollisionShape3D if is_instance_valid(floor_body) else null
	if solid == null:
		last_configuration_error = "Shore preview requires its actual firm floor collider"
	else:
		_floor_region = {"collision": solid, "safe_rect": FloorRect}
	threat_scheduler = SchedulerScript.new()
	threat_scheduler.name = "ShorePreviewScheduler"
	add_child(threat_scheduler)
	stalker = StalkerScript.new()
	stalker.name = "ShoreStalker"
	add_child(stalker)
	stalker.global_position = (get_node("StalkerSource") as Marker3D).global_position


func _on_enter_level() -> void:
	if not last_configuration_error.is_empty():
		_update_guidance()
		return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ParentData))
	if not raw is Dictionary or not raw.get("stalker_raw_role") is Dictionary or not raw.get("minimum_timing_floors") is Dictionary:
		last_configuration_error = "Shore preview requires the unchanged accepted parent Stalker role"
		_update_guidance()
		return
	var profile: String = "standard"
	if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference"):
		profile = shared_shell.call("get_difficulty_preference")
	if not threat_scheduler.begin_encounter(profile, ENCOUNTER_ID, 1):
		last_configuration_error = threat_scheduler.last_error
	elif not stalker.call("configure", SOURCE_ID, hero, effects, threat_scheduler, combat_response, raw.stalker_raw_role, raw.minimum_timing_floors):
		last_configuration_error = "Shore Stalker rejected its actual shared Hero/Scheduler/floor bindings"
	else:
		_active = true
		stalker.call("set_sun_visual", 0)
		scenery.call("follow_landmarks", hero.global_position)
	_update_guidance()


func _on_exit_level() -> void:
	_active = false
	if is_instance_valid(threat_scheduler):
		threat_scheduler.end_encounter("mirror_shore_preview_exit")


func _physics_process(_delta: float) -> void:
	if not _active or not is_instance_valid(hero):
		return
	scenery.call("follow_landmarks", hero.global_position)
	_update_guidance()


func combat_response() -> Dictionary:
	if not is_instance_valid(hero) or _floor_region.is_empty():
		return {}
	var response: Dictionary = hero.get_threat_response_state()
	var directions: Array[Vector3] = []
	if is_instance_valid(stalker):
		var toward: Vector3 = hero.global_position - stalker.global_position
		toward.y = 0.0
		if toward.length_squared() > 0.0001:
			var right: Vector3 = Vector3.UP.cross(toward.normalized())
			directions.append_array([right, -right])
	directions.append_array([Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK])
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			directions.append(Vector3(x, 0.0, z).normalized())
	response["world_root"] = get_parent() as Node3D
	response["world_revision"] = 1
	response["recognition_s"] = 0.25
	response["attack_input_margin_s"] = 0.06
	response["escape_directions"] = directions
	response["return_directions"] = directions.duplicate()
	response["floor_regions"] = [_floor_region]
	return response


func _camera_framing_points() -> Array:
	if not _active:
		return []
	var result: Dictionary = camera_framing_union()
	if not String(result.get("error", "")).is_empty():
		last_camera_framing_error = String(result.error)
		return []
	return (result.points as Array).duplicate()


func camera_framing_union(candidate_id: String = "", candidate_points: Array = [], current_view: bool = false) -> Dictionary:
	if not is_instance_valid(shared_shell) or not is_instance_valid(stalker):
		return {"error": "Shore preview requires its actual shared shell and retained source", "points": []}
	if not candidate_id.is_empty():
		if candidate_id != SOURCE_ID or candidate_points.is_empty() or not String(stalker.call("state").get("reservation_id", "")).is_empty():
			return {"error": "Shore forecast must replace only its actual unleased source", "points": []}
	elif not candidate_points.is_empty():
		return {"error": "Shore prospective corners require the actual source identity", "points": []}
	var points: Array = candidate_points.duplicate()
	if candidate_id.is_empty():
		var source_bounds: Dictionary = stalker.call("camera_framing_points", shared_shell, {}, {}, current_view)
		if not String(source_bounds.get("error", "")).is_empty():
			return source_bounds
		points.append_array(source_bounds.points)
	if points.size() > 224:
		return {"error": "Shore source union exceeds the common corner bound", "points": []}
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite() or maxf(absf(point.x), maxf(absf(point.y), absf(point.z))) > 1024.0:
			return {"error": "Shore source union requires bounded finite actual corners", "points": []}
	return {"error": "", "points": points.duplicate()}


func scheduler_bindings() -> Dictionary:
	return {"world_root": self, "owners": {SOURCE_ID: stalker}, "floors": {"shore-floor": _floor_region}}


func state() -> Dictionary:
	return {"api_revision": OWNED_API, "configuration_error": last_configuration_error, "source": stalker.call("state") if is_instance_valid(stalker) else {}, "scheduler_clock_s": threat_scheduler.get_clock() if is_instance_valid(threat_scheduler) else -1.0}


func _update_guidance() -> void:
	if not last_configuration_error.is_empty():
		objective_text = "SHORE PREVIEW UNAVAILABLE\n" + last_configuration_error
		return
	if not is_instance_valid(stalker):
		return
	var actual: Dictionary = stalker.call("state")
	if actual.dead:
		objective_text = "THE DRY SHORE IS QUIET\nSHORE PREVIEW CLEAR"
	elif not String(actual.get("framing_error", "")).is_empty():
		objective_text = "THREAT REARMS\nKEEP THE BODY AND LANE IN VIEW"
	elif actual.phase == "recovery":
		objective_text = "LOW BODY OPEN\nRETURN TO THE USEFUL FLANK"
	else:
		objective_text = "FIRM SHORE; STILL WATER\nDASH CLEAR OF THE LOCKED LANE"


func _capture_local_state() -> Dictionary:
	if not last_configuration_error.is_empty():
		return {}
	return {"scheduler": threat_scheduler.snapshot_state(scheduler_bindings()), "stalker": stalker.call("snapshot_state")}


func _local_snapshot_error(state_data: Dictionary) -> String:
	return _paired_local_snapshot_error(state_data, hero.global_position)


func _local_snapshot_error_with_player(state_data: Dictionary, saved_player: Dictionary) -> String:
	var motion: Variant = saved_player.get("motion")
	if not motion is Dictionary or not Codec.is_vector3(motion.get("position")):
		return "Shore pairing requires the validated saved Hero feet position"
	return _paired_local_snapshot_error(state_data, Codec.read_vector3(motion.position))


func _paired_local_snapshot_error(state_data: Dictionary, expected_hero_position: Vector3) -> String:
	if not last_configuration_error.is_empty():
		return last_configuration_error
	if not is_instance_valid(scenery) or scenery.is_queued_for_deletion() or not is_instance_valid(stalker) or stalker.is_queued_for_deletion() or not is_instance_valid(threat_scheduler) or threat_scheduler.is_queued_for_deletion():
		return "Shore requires its retained native scenery/source/Scheduler"
	var scenery_error: String = scenery.call("runtime_error")
	if not scenery_error.is_empty():
		return scenery_error
	if not Codec.keys_error(state_data, ["scheduler", "stalker"]).is_empty() or not state_data.get("scheduler") is Dictionary or not state_data.get("stalker") is Dictionary:
		return "Shore snapshot requires exactly its complete source/Scheduler unit"
	var source: Dictionary = state_data.stalker
	var error: String = stalker.call("snapshot_error", source, state_data.scheduler)
	if not error.is_empty():
		return error
	var bindings: Dictionary = scheduler_bindings()
	bindings["owner_positions"] = {SOURCE_ID: Codec.read_vector3(source.position)}
	bindings["owner_velocities"] = {SOURCE_ID: Codec.read_vector3(source.velocity)}
	if not source.dead and not String(source.reservation_id).is_empty():
		bindings["owner_collision_states"] = {SOURCE_ID: {"collision_path": "BodyCollision", "enabled": true, "layer": 2, "mask": 1}}
	error = threat_scheduler.snapshot_error(state_data.scheduler, bindings)
	if not error.is_empty():
		return error
	if state_data.scheduler.get("encounter_id") != ENCOUNTER_ID:
		return "Shore source belongs to this authored preview encounter"
	var previous: Variant = source.get("previous")
	if previous is Dictionary and Codec.is_number(previous.get("clock_s")) and float(previous.clock_s) == float(state_data.scheduler.get("clock_s", -1.0)):
		if not Codec.is_vector3(previous.get("hero_position")) or Codec.read_vector3(previous.hero_position) != expected_hero_position:
			return "Shore source sample must match the paired Hero at the same clock"
	return ""


func _restore_local_state(state_data: Dictionary) -> void:
	var actor_applied: bool = stalker.call("apply_validated_state", state_data.stalker)
	assert(actor_applied, "Prevalidated shore native actor commit failed")
	var scheduler_applied: bool = threat_scheduler.restore_state(state_data.scheduler, scheduler_bindings())
	assert(scheduler_applied, "Prevalidated shore native Scheduler commit failed")
	var presentation_applied: bool = stalker.call("refresh_presentation")
	assert(presentation_applied, "Prevalidated shore quiet presentation failed")
	scenery.call("follow_landmarks", hero.global_position)
	_update_guidance()
