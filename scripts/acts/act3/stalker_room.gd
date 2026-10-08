extends "res://scripts/acts/act3/twin_suns.gd"
## A3-L1's isolated physical-lunge consumer. Full-route encounters stay separate
## until this rule is accepted. This room grants no campaign clear or pickups.

const StalkerScript = preload("res://scripts/acts/act3/sunbound_stalker.gd")
const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ENCOUNTER_DATA: String = "res://data/campaign/act3/a3_l1_encounters.json"
const SOURCE_ID: String = "rule-stalker"
const ENCOUNTER_ID: String = "A3-L1/stalker-rule"

var stalker: CharacterBody3D
var threat_scheduler: CinderThreatScheduler
var _floor_region: Dictionary = {}
var _guidance: String = ""
var _configuration_error: String = ""


func _ready() -> void:
	local_snapshot_version = 4
	prototype_room = true
	clear_rule_pockets = true
	super._ready()
	process_physics_priority = 30
	threat_scheduler = SchedulerScript.new()
	threat_scheduler.name = "StalkerRuleScheduler"
	add_child(threat_scheduler)
	var floor_body: StaticBody3D = scenery.get("floor_body") as StaticBody3D
	if is_instance_valid(floor_body) and floor_body.get_child_count() > 0 and floor_body.get_child(0) is CollisionShape3D:
		_floor_region = {"collision": floor_body.get_child(0), "safe_rect": Rect2(-7.0, -11.0, 14.0, 22.0)}
	else:
		_configuration_error = "Stalker rule requires the actual continuous shelf collider"
	stalker = StalkerScript.new()
	stalker.name = "RuleStalker"
	add_child(stalker)
	stalker.global_position = (get_node("StalkerRuleSource") as Marker3D).global_position


func _on_enter_level() -> void:
	super._on_enter_level()
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENCOUNTER_DATA))
	if not raw is Dictionary or not raw.get("stalker_raw_role") is Dictionary or not raw.get("minimum_timing_floors") is Dictionary:
		_configuration_error = "Stalker rule requires its authored raw role and timing floors"
		return
	var numeric_keys: Dictionary = {"max_distance_world": "lunge_distance", "lunge_speed_world_per_s": "lunge_speed", "lane_radius_world": "damage_radius", "source_capsule_radius_world": "capsule_radius", "approach_acceleration_world_per_s2": "approach_acceleration", "approach_turn_radians_per_s": "approach_turn_radians_s", "brace_min_distance_world": "brace_min_distance", "brace_max_distance_world": "brace_max_distance", "brace_facing_min_dot": "brace_facing_min_dot", "sun_bias_degrees": "sun_bias_degrees"}
	if not raw.get("stalker_lunge") is Dictionary:
		_configuration_error = "Stalker authoring data requires its immutable motion record"
		return
	for key: String in numeric_keys:
		if not Codec.is_number(raw["stalker_lunge"].get(key)) or float(raw["stalker_lunge"][key]) != float(StalkerScript.TUNING[numeric_keys[key]]):
			_configuration_error = "Stalker authoring/runtime motion differs: " + key
			return
	var profile: String = "standard"
	if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference"):
		profile = shared_shell.call("get_difficulty_preference")
	if not threat_scheduler.begin_encounter(profile, ENCOUNTER_ID, 1):
		_configuration_error = threat_scheduler.last_error
		return
	if not stalker.call("configure", SOURCE_ID, hero, effects, threat_scheduler, combat_response, raw["stalker_raw_role"], raw["minimum_timing_floors"]):
		_configuration_error = "Stalker consumer rejected its authored live bindings"
		return
	_update_guidance()


func _on_exit_level() -> void:
	if is_instance_valid(threat_scheduler):
		threat_scheduler.end_encounter("stalker_room_exit")
	super._on_exit_level()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _active:
		_update_guidance()


## The witness receives the actual actor's defensive live state. The source's
## near/far flanks and eight compass swipes are finite proof candidates.
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
			var choice: int = int(stalker.call("state").get("sun_visual", sun_state))
			var near_side: Vector3 = right if choice == 0 else -right
			directions.append(near_side)
			directions.append(-near_side)
	directions.append_array([Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK])
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			directions.append(Vector3(x, 0.0, z).normalized())
	# The real shared player is a sibling of this level under the common World.
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


## Pure union preparation. The candidate replaces only its unleased source;
## ordinary scheduler proof still owns every mechanical response/lease.
## This geometry helper never admits attacks or replaces mechanical proof.
func camera_framing_union(candidate_id: String = "", candidate_points: Array = [], current_view: bool = false) -> Dictionary:
	if not is_instance_valid(shared_shell) or not is_instance_valid(stalker):
		return {"error": "Actual shared shell and retained rule source required", "points": []}
	if not candidate_id.is_empty():
		if candidate_id != SOURCE_ID or candidate_points.is_empty() or not String(stalker.call("state").get("reservation_id", "")).is_empty():
			return {"error": "A prospective rule forecast must replace its unleased actual source", "points": []}
	elif not candidate_points.is_empty():
		return {"error": "Prospective camera corners require their actual source identity", "points": []}
	var points: Array = candidate_points.duplicate()
	if candidate_id.is_empty():
		var source_bounds: Dictionary = stalker.call("camera_framing_points", shared_shell, {}, {}, current_view)
		if not String(source_bounds.get("error", "")).is_empty():
			return source_bounds
		points.append_array(source_bounds.points)
	return _camera_union_result(points)


func _camera_union_result(points: Array) -> Dictionary:
	if points.size() > 224:
		return {"error": "Actual source camera union exceeds the shared corner bound", "points": []}
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite() or maxf(absf(point.x), maxf(absf(point.y), absf(point.z))) > 1024.0:
			return {"error": "Actual source camera union requires bounded finite native corners", "points": []}
	return {"error": "", "points": points.duplicate()}


func scheduler_bindings() -> Dictionary:
	return {"world_root": self, "owners": {SOURCE_ID: stalker}, "floors": {"shelf-floor": _floor_region}}


func _update_guidance() -> void:
	if not _configuration_error.is_empty():
		objective_text = "RULE ROOM UNAVAILABLE\n" + _configuration_error
		return
	if not is_instance_valid(stalker):
		return
	stalker.call("set_sun_visual", sun_state)
	var state: Dictionary = stalker.call("state")
	var phase: String = state.get("phase", "approach")
	var text: String = "SINGLE CREST: ITS RIGHT FLANK\nDASH CLEAR OF THE LOCKED LANE" if int(state.get("effective_sun", sun_state)) == 0 else "FORKED CREST: ITS LEFT FLANK\nDASH CLEAR OF THE LOCKED LANE"
	if not String(state.get("framing_error", "")).is_empty() and not state.get("dead", false):
		text = "THREAT REARMS\nKEEP THE BODY AND LANE IN VIEW"
	elif phase == "recovery":
		text = "LOW BODY OPEN\nTAP FROM NEAR SIDE OR RETURN"
	elif state.get("dead", false):
		text = "RULE ROOM CLEAR\nBOTH SUNS KEEP THE SAME SAFE FLOOR"
	if text != _guidance:
		_guidance = text
		objective_text = text


func _capture_local_state() -> Dictionary:
	if not _configuration_error.is_empty():
		return {}
	return {"scenery": super._capture_local_state(), "scheduler": threat_scheduler.snapshot_state(scheduler_bindings()), "stalker": stalker.call("snapshot_state")}


func _local_snapshot_error(state: Dictionary) -> String:
	if not is_instance_valid(hero):
		return "Stalker rule requires its paired actual hero"
	return _paired_local_snapshot_error(state, hero.global_position)


func _local_snapshot_error_with_player(state: Dictionary, saved_player: Dictionary) -> String:
	# The shell already validated this complete saved actor. Consume only its
	# canonical feet position; never move the fresh/live hero during proof.
	var motion: Variant = saved_player.get("motion")
	if not motion is Dictionary or not Codec.is_vector3(motion.get("position")):
		return "Stalker aggregate requires the validated saved hero position"
	return _paired_local_snapshot_error(state, Codec.read_vector3(motion["position"]))


func _paired_local_snapshot_error(state: Dictionary, expected_hero_position: Vector3) -> String:
	if not _configuration_error.is_empty():
		return _configuration_error
	if not is_instance_valid(threat_scheduler) or not is_instance_valid(stalker) or threat_scheduler.is_queued_for_deletion() or stalker.is_queued_for_deletion():
		return "Stalker rule requires its live source and scheduler"
	if not Codec.keys_error(state, ["scenery", "scheduler", "stalker"]).is_empty() or not state.get("scenery") is Dictionary or not state.get("scheduler") is Dictionary or not state.get("stalker") is Dictionary:
		return "Stalker rule snapshot requires the complete scenery/source/scheduler unit"
	var error: String = super._local_snapshot_error(state["scenery"])
	if not error.is_empty():
		return error
	var source: Dictionary = state["stalker"]
	if not Codec.is_vector3(source.get("position")) or not Codec.is_vector3(source.get("velocity")):
		return "Stalker source requires finite staged position and velocity"
	# Independently validate the saved actor before deriving native collision
	# custody; scheduler staging is never an actor-lifecycle substitute.
	error = stalker.call("snapshot_error", source, state["scheduler"])
	if not error.is_empty():
		return error
	var bindings: Dictionary = scheduler_bindings()
	bindings["owner_positions"] = {SOURCE_ID: Codec.read_vector3(source["position"])}
	bindings["owner_velocities"] = {SOURCE_ID: Codec.read_vector3(source["velocity"])}
	if not source.dead and not String(source.reservation_id).is_empty():
		bindings["owner_collision_states"] = {SOURCE_ID: {"collision_path": "BodyCollision", "enabled": true, "layer": 2, "mask": 1}}
	error = threat_scheduler.snapshot_error(state["scheduler"], bindings)
	if not error.is_empty():
		return error
	if state["scheduler"].get("encounter_id") != ENCOUNTER_ID:
		return "Stalker source belongs to this authored rule encounter"
	var previous: Variant = source.get("previous")
	if previous is Dictionary and Codec.is_number(previous.get("clock_s")) and float(previous["clock_s"]) == float(state["scheduler"].get("clock_s", -1.0)):
		if not Codec.is_vector3(previous.get("hero_position")) or Codec.read_vector3(previous["hero_position"]) != expected_hero_position:
			return "Stalker contact sample must match the paired hero position"
	return ""


func _restore_local_state(state: Dictionary) -> void:
	# Every component has prevalidated. Source pose/velocity precedes the actual
	# scheduler commit; rebuilding cues afterwards emits no attack or phase event.
	var applied: bool = stalker.call("apply_validated_state", state["stalker"])
	assert(applied, "Prevalidated Stalker source including real collision flags failed")
	var scheduler_applied: bool = threat_scheduler.restore_state(state["scheduler"], scheduler_bindings())
	assert(scheduler_applied, "Prevalidated Stalker scheduler commit failed")
	super._restore_local_state(state["scenery"])
	stalker.call("refresh_presentation")
	_guidance = ""
	_update_guidance()
