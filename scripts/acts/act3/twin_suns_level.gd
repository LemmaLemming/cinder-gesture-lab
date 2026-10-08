extends "res://scripts/acts/act3/twin_suns.gd"
## Authored A3-L1 runtime candidate. One scheduler owns all five real Stalkers.
## Spatial entries activate pockets without doors or previous-clear gating.
## Only real source deaths clear pockets. No supplies, healing or gear grants.
## Current stills/tuning and the complete route require queued runtime review.

const StalkerScript = preload("res://scripts/acts/act3/sunbound_stalker.gd")
const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const InteractionCue = preload("res://scripts/cues/interaction_cue.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ENCOUNTER_DATA: String = "res://data/campaign/act3/a3_l1_encounters.json"
const ENCOUNTER_ID: String = "A3-L1/full-route"
const WORLD_REVISION: int = 1
const LOCAL_VERSION: int = 5
const ROUTE_API: String = "act3-twin-suns-level-1"
const COMPLETION_ID: String = "twin-suns-clear"
const EXIT_ID: String = "poolingdred-threshold"
const SOURCE_IDS: Array[String] = ["l1-flank-stalker", "l1-approach-stalker", "l1-crossing-west", "l1-crossing-east", "l1-departure-stalker"]
const POCKET_IDS: Array[String] = ["useful-flank", "two-approaches", "crossing-shadow", "pillars-recede"]
const CHECKPOINT_IDS: Array[String] = ["useful-flank-entry", "two-approaches-entry", "crossing-shadow-entry", "departure-entry"]
const ENTRY_Z: Array[float] = [30.0, 15.0, -6.0, -29.0]
const SOURCE_MARKERS: Dictionary = {
	"l1-flank-stalker": "EncounterSources/UsefulFlank",
	"l1-approach-stalker": "EncounterSources/TwoApproaches",
	"l1-crossing-west": "EncounterSources/CrossingWest",
	"l1-crossing-east": "EncounterSources/CrossingEast",
	"l1-departure-stalker": "EncounterSources/Departure",
}
const SOURCE_POCKETS: Dictionary = {
	"l1-flank-stalker": 0, "l1-approach-stalker": 1,
	"l1-crossing-west": 2, "l1-crossing-east": 2, "l1-departure-stalker": 3,
}

## Public live nodes are stable for the entire level, including after death.
var sources: Dictionary = {}
var threat_scheduler: CinderThreatScheduler
var exit_cue: CinderInteractionCue
var _floor_region: Dictionary = {}
var _exit_rect: Rect2
var _authoring: Dictionary = {}
var _entries: Array[Dictionary] = []
var _deaths: Dictionary = {}
var _exit_state: String = "clear"
var _contact: Dictionary = {}
var _exit_dispatch_queued: bool = false
var _exit_dispatch_generation: int = 0
var _configuration_error: String = ""
var _death_callbacks: Dictionary = {}


func _ready() -> void:
	prototype_room = false
	local_snapshot_version = LOCAL_VERSION
	super._ready()
	# Hero and scheduler sample before source20; entry/checkpoint runs afterwards.
	process_physics_priority = 30
	threat_scheduler = SchedulerScript.new()
	threat_scheduler.name = "TwinSunsThreatScheduler"
	add_child(threat_scheduler)
	var floor_body: StaticBody3D = scenery.get("floor_body") as StaticBody3D
	var collision: CollisionShape3D = floor_body.get_node_or_null("Solid") as CollisionShape3D if is_instance_valid(floor_body) else null
	if not is_instance_valid(collision) or not collision.shape is BoxShape3D:
		_configuration_error = "Twin Suns requires its actual continuous box floor"
		return
	var floor_size: Vector3 = (collision.shape as BoxShape3D).size
	_floor_region = {"collision": collision, "safe_rect": Rect2(collision.global_position.x - floor_size.x * 0.5, collision.global_position.z - floor_size.z * 0.5, floor_size.x, floor_size.z)}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENCOUNTER_DATA))
	if not data is Dictionary:
		_configuration_error = "Twin Suns requires its authored encounter data"
		return
	_authoring = data.duplicate(true)
	_configuration_error = _authoring_error(floor_size)
	if not _configuration_error.is_empty():
		return
	for source_id: String in SOURCE_IDS:
		var marker: Marker3D = get_node_or_null(SOURCE_MARKERS[source_id]) as Marker3D
		if not is_instance_valid(marker):
			_configuration_error = "Twin Suns source marker unavailable: " + source_id
			return
		var source: CinderAct3SunboundStalker = StalkerScript.new()
		source.name = source_id.replace("-", "_")
		add_child(source)
		source.global_position = marker.global_position
		source.set_physics_process(false)
		sources[source_id] = source
	var threshold: Marker3D = get_node_or_null("PoolingdredThreshold") as Marker3D
	if not is_instance_valid(threshold):
		_configuration_error = "Twin Suns requires its actual contact threshold"
		return
	# Broad local contact approach, wholly on permanent floor; no solid gate.
	_exit_rect = Rect2(threshold.global_position.x - 1.2, threshold.global_position.z - 0.65, 2.4, 1.3)
	exit_cue = InteractionCue.new()
	exit_cue.name = "PoolingdredContactCue"
	add_child(exit_cue)
	exit_cue.global_position = Vector3(threshold.global_position.x, 0.0, threshold.global_position.z)


func _authoring_error(floor_size: Vector3) -> String:
	if _authoring.get("level_id") != "A3-L1" or not _authoring.get("stalker_raw_role") is Dictionary or not _authoring.get("minimum_timing_floors") is Dictionary or not _authoring.get("floor") is Dictionary or not _authoring.get("stalker_lunge") is Dictionary or not _authoring.get("encounters") is Array:
		return "Twin Suns authoring data has unsupported fields"
	if not Codec.is_vector3(_authoring.floor.get("continuous_box_size")) or Codec.read_vector3(_authoring.floor.continuous_box_size) != floor_size or _authoring.floor.get("sun_changes_collision") != false or not Codec.is_vector3(_authoring.floor.get("low_trunk_size")) or _authoring.floor.get("low_trunk_centers") != [[0.0, 8.0], [0.0, -13.0]]:
		return "Twin Suns authored continuous floor/trunks differ from actual scenery"
	var numeric_keys: Dictionary = {"max_distance_world": "lunge_distance", "lunge_speed_world_per_s": "lunge_speed", "lane_radius_world": "damage_radius", "source_capsule_radius_world": "capsule_radius", "approach_acceleration_world_per_s2": "approach_acceleration", "approach_turn_radians_per_s": "approach_turn_radians_s", "brace_min_distance_world": "brace_min_distance", "brace_max_distance_world": "brace_max_distance", "brace_facing_min_dot": "brace_facing_min_dot", "sun_bias_degrees": "sun_bias_degrees"}
	for key: String in numeric_keys:
		if not Codec.is_number(_authoring.stalker_lunge.get(key)) or float(_authoring.stalker_lunge[key]) != float(StalkerScript.TUNING[numeric_keys[key]]):
			return "Twin Suns authoring/runtime motion differs: " + key
	var beats: Array = _authoring.encounters
	if beats.size() != 5 or not beats[0] is Dictionary or beats[0].get("id") != "foreign-noon" or beats[0].get("sources") != [] or beats[0].get("mandatory_timer_wait") != false:
		return "Twin Suns requires its five canonical encounter beats"
	var seen: Array[String] = []
	for index: int in range(4):
		var pocket: Variant = beats[index + 1]
		if not pocket is Dictionary or pocket.get("id") != POCKET_IDS[index] or pocket.get("beat") != index + 1 or pocket.get("entry_z") != ENTRY_Z[index] or pocket.get("checkpoint") != CHECKPOINT_IDS[index] or not pocket.get("sources") is Array:
			return "Twin Suns authored entry/checkpoint differs from its canonical beat"
		for definition: Variant in pocket.sources:
			if not definition is Dictionary or not SOURCE_IDS.has(definition.get("id")) or seen.has(definition.id) or definition.get("marker") != SOURCE_MARKERS[definition.id] or int(SOURCE_POCKETS[definition.id]) != index:
				return "Twin Suns requires unique canonical source/marker bindings"
			seen.append(definition.id)
	if seen != SOURCE_IDS or beats[4].get("contact_exit_marker") != "PoolingdredThreshold":
		return "Twin Suns requires all five sources and the authored contact exit"
	return ""


func contract_error() -> String:
	var error: String = super.contract_error()
	return _configuration_error if error.is_empty() else error


func _on_enter_level() -> void:
	super._on_enter_level()
	if not _configuration_error.is_empty():
		_update_guidance()
		return
	var profile: String = "standard"
	if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference"):
		profile = shared_shell.call("get_difficulty_preference")
	if not threat_scheduler.begin_encounter(profile, ENCOUNTER_ID, WORLD_REVISION):
		_configuration_error = threat_scheduler.last_error
		_update_guidance()
		return
	for source_id: String in SOURCE_IDS:
		var source: CinderAct3SunboundStalker = sources[source_id]
		if not source.configure(source_id, hero, effects, threat_scheduler, combat_response.bind(source_id), _authoring.stalker_raw_role, _authoring.minimum_timing_floors):
			_configuration_error = "Twin Suns source configuration failed: " + source_id + ": " + source.last_error
			_update_guidance()
			return
		var callback: Callable = _on_source_died.bind(source_id)
		_death_callbacks[source_id] = callback
		source.died.connect(callback)
	_update_presentation()


func _on_exit_level() -> void:
	# Base disarms progression first. Retire callbacks before scheduler cancels.
	for source_id: String in _death_callbacks:
		if not is_instance_valid(sources.get(source_id)):
			continue
		var source: CinderAct3SunboundStalker = sources[source_id]
		if source.died.is_connected(_death_callbacks[source_id]):
			source.died.disconnect(_death_callbacks[source_id])
		if is_instance_valid(source):
			source.set_physics_process(false)
	_death_callbacks.clear()
	_exit_dispatch_generation += 1
	_exit_dispatch_queued = false
	if is_instance_valid(exit_cue):
		exit_cue.clear()
	if is_instance_valid(threat_scheduler):
		threat_scheduler.end_encounter("twin_suns_level_exit")
	super._on_exit_level()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not _active or not _configuration_error.is_empty() or not is_instance_valid(hero) or hero.dead:
		return
	# Full-route labels follow authored entries, not the scenery-only marker loop.
	beat_index = _entries.size()
	_update_presentation()
	if _advance_entry():
		return # One coherent checkpoint boundary, before a newly enabled tick.
	if _all_cleared() and not is_completed():
		_exit_state = "available"
		request_completion(COMPLETION_ID)
		_update_presentation()
		return
	if not is_completed() or _exit_state == "spent":
		return
	if _exit_state == "available" and _at_exit(hero.global_position):
		_contact = {"clock_s": threat_scheduler.get_clock(), "hero_position": Codec.vector3(hero.global_position)}
		_exit_state = "active"
		_update_presentation()
	if _exit_state == "active" and not _exit_dispatch_queued:
		_exit_dispatch_queued = true
		_dispatch_contact_exit.bind(_exit_dispatch_generation).call_deferred()


func _advance_entry() -> bool:
	if _entries.size() >= POCKET_IDS.size() or hero.global_position.z > ENTRY_Z[_entries.size()]:
		return false
	var index: int = _entries.size()
	_entries.append({"id": POCKET_IDS[index], "clock_s": threat_scheduler.get_clock(), "hero_position": Codec.vector3(hero.global_position)})
	beat_index = index + 1
	for source_id: String in SOURCE_IDS:
		if int(SOURCE_POCKETS[source_id]) == index:
			var source: CinderAct3SunboundStalker = sources[source_id]
			source.set_physics_process(not source.dead)
	# Every actor has already sampled (or remained dormant) this physics tick.
	# The shell freezes now and captures later, before the new source can warn.
	if not request_checkpoint(CHECKPOINT_IDS[index], "encounter"):
		_configuration_error = "Twin Suns entry checkpoint request rejected"
	_update_presentation()
	return true


func _on_source_died(_where: Vector3, source_id: String) -> void:
	if not _active or not _configuration_error.is_empty() or _deaths.has(source_id):
		return
	if not is_instance_valid(sources.get(source_id)):
		return
	var source: CinderAct3SunboundStalker = sources[source_id]
	if not source.dead or source.hp > 0.0 or source.state().get("stable_id") != source_id:
		return
	_deaths[source_id] = {"clock_s": threat_scheduler.get_clock(), "source_position": Codec.vector3(source.global_position)}
	source.set_physics_process(false)
	if _all_cleared() and not is_completed():
		_exit_state = "available"
		request_completion(COMPLETION_ID)
	_update_presentation()


func _all_cleared() -> bool:
	return _deaths.size() == SOURCE_IDS.size() and _entries.size() == POCKET_IDS.size()


func _at_exit(position: Vector3) -> bool:
	return position.is_finite() and absf(position.y) <= 0.2 and _exit_rect.has_point(Vector2(position.x, position.z))


func _dispatch_contact_exit(generation: int) -> void:
	# A restored/retired world invalidates callbacks from the replaced timeline.
	if generation != _exit_dispatch_generation:
		return
	_exit_dispatch_queued = false
	if not _active or not is_instance_valid(hero) or hero.dead or not is_completed() or _exit_state != "active":
		return
	# Contact was sampled by the real actor. Request is separate from attacks.
	_exit_state = "spent"
	if not request_contact_exit(EXIT_ID, hero):
		_exit_state = "available"
		_contact.clear()
	_update_presentation()


## Every configured source receives its own actual source-local candidates.
## Shared admission reproves each new lease against the current complete union.
func combat_response(source_id: String) -> Dictionary:
	if not is_instance_valid(hero) or not sources.has(source_id) or _floor_region.is_empty():
		return {}
	var source: CinderAct3SunboundStalker = sources[source_id]
	var response: Dictionary = hero.get_threat_response_state()
	var directions: Array[Vector3] = []
	var toward: Vector3 = hero.global_position - source.global_position
	toward.y = 0.0
	if toward.length_squared() > 0.0001:
		var right: Vector3 = Vector3.UP.cross(toward.normalized())
		var near_side: Vector3 = right if int(source.state().get("sun_visual", sun_state)) == 0 else -right
		directions.append(near_side)
		directions.append(-near_side)
	directions.append_array([Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK])
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			directions.append(Vector3(x, 0.0, z).normalized())
	response["world_revision"] = WORLD_REVISION
	response["recognition_s"] = 0.25
	response["attack_input_margin_s"] = 0.06
	response["escape_directions"] = directions
	response["return_directions"] = directions.duplicate()
	response["floor_regions"] = [_floor_region]
	return response


## Pure union preparation. Replace only one unleased prospective source while
## retaining every other held source's actual/committed render bounds.
## This helper alone neither enables the shared camera hook nor admits attacks.
func camera_framing_union(candidate_id: String = "", candidate_points: Array = []) -> Dictionary:
	if not is_instance_valid(shared_shell) or not _configuration_error.is_empty():
		return {"error": "Configured authored level and actual shared shell required", "points": []}
	if not candidate_id.is_empty():
		if not sources.has(candidate_id) or candidate_points.is_empty():
			return {"error": "Prospective camera corners require their owned source identity", "points": []}
		var candidate: CinderAct3SunboundStalker = sources[candidate_id]
		if not is_instance_valid(candidate) or not String(candidate.state().get("reservation_id", "")).is_empty():
			return {"error": "Prospective framing must replace only an unleased actual source", "points": []}
	elif not candidate_points.is_empty():
		return {"error": "Prospective camera corners require their actual source identity", "points": []}
	var points: Array = candidate_points.duplicate()
	for source_id: String in SOURCE_IDS:
		if source_id == candidate_id:
			continue
		var source: CinderAct3SunboundStalker = sources.get(source_id) as CinderAct3SunboundStalker
		if not is_instance_valid(source):
			return {"error": "Retained authored source unavailable for camera union: " + source_id, "points": []}
		var source_bounds: Dictionary = source.camera_framing_points(shared_shell)
		if not String(source_bounds.get("error", "")).is_empty():
			return {"error": source_id + ": " + String(source_bounds.error), "points": []}
		points.append_array(source_bounds.points)
	if points.size() > 224:
		return {"error": "Actual source camera union exceeds the shared corner bound", "points": []}
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite() or maxf(absf(point.x), maxf(absf(point.y), absf(point.z))) > 1024.0:
			return {"error": "Actual source camera union requires bounded finite native corners", "points": []}
	return {"error": "", "points": points.duplicate()}


func scheduler_bindings() -> Dictionary:
	return {"world_root": self, "owners": sources.duplicate(), "floors": {"shelf-floor": _floor_region}}


func state() -> Dictionary:
	var entered: Array[String] = []
	for entry: Dictionary in _entries:
		entered.append(entry.id)
	var cleared: Array[String] = []
	var source_states: Dictionary = {}
	for source_id: String in SOURCE_IDS:
		if _deaths.has(source_id):
			cleared.append(source_id)
		if is_instance_valid(sources.get(source_id)):
			source_states[source_id] = sources[source_id].state()
	var cleared_prefix: int = 0
	for index: int in range(_entries.size()):
		var complete: bool = true
		for source_id: String in SOURCE_IDS:
			if int(SOURCE_POCKETS[source_id]) == index and not _deaths.has(source_id):
				complete = false
		if not complete:
			break
		cleared_prefix += 1
	return {"api_revision": ROUTE_API, "configuration_error": _configuration_error, "entered": entered, "cleared": cleared, "cleared_prefix": cleared_prefix, "entries": _entries.duplicate(true), "deaths": _deaths.duplicate(true), "exit_state": _exit_state, "contact": _contact.duplicate(true), "completed": is_completed(), "checkpoint": current_checkpoint(), "clock_s": threat_scheduler.get_clock() if is_instance_valid(threat_scheduler) else 0.0, "source_states": source_states}


func _update_presentation(silent: bool = false) -> void:
	for source_id: String in sources:
		if is_instance_valid(sources[source_id]):
			var source: CinderAct3SunboundStalker = sources[source_id]
			source.set_sun_visual(sun_state)
	if is_instance_valid(exit_cue):
		var blocked: bool = exit_cue.is_blocking_signals()
		if silent:
			exit_cue.set_block_signals(true)
		if _exit_state == "clear":
			exit_cue.clear()
		else:
			exit_cue.present(_exit_state, "contact")
		if silent:
			exit_cue.set_block_signals(blocked)
	_update_guidance()


func _update_guidance() -> void:
	if not _configuration_error.is_empty():
		objective_text = "TWIN SUNS UNAVAILABLE\n" + _configuration_error
	elif _exit_state != "clear":
		objective_text = "THE PILLARS RECEDE\nCONTACT THE FAR THRESHOLD"
	elif _entries.is_empty():
		objective_text = "A FOREIGN NOON\nFOLLOW THE SCARLET SHELF"
	elif _entries.size() == 1 and is_instance_valid(sources.get("l1-flank-stalker")):
		var first: Dictionary = sources["l1-flank-stalker"].state()
		if first.dead:
			objective_text = "THE USEFUL FLANK\nFOLLOW THE NEXT SCARLET SHELF"
		elif first.phase == "recovery":
			objective_text = "LOW BODY OPEN\nTAP FROM NEAR SIDE OR RETURN"
		else:
			objective_text = "SINGLE CREST: ITS RIGHT FLANK\nDASH CLEAR; TAP THE LOW RECOVERY" if int(first.effective_sun) == 0 else "FORKED CREST: ITS LEFT FLANK\nDASH CLEAR; TAP THE LOW RECOVERY"
	else:
		objective_text = BEAT_LABELS[_entries.size()].to_upper() + "\nREAD THE CREST; DASH CLEAR, TAP LOW"


func _capture_local_state() -> Dictionary:
	var error: String = _runtime_error()
	if not error.is_empty():
		return {}
	var source_states: Dictionary = {}
	for source_id: String in SOURCE_IDS:
		source_states[source_id] = sources[source_id].snapshot_state()
	return {"api_revision": ROUTE_API, "schema_version": 1, "scenery": super._capture_local_state(), "scheduler": threat_scheduler.snapshot_state(scheduler_bindings()), "sources": source_states, "route": {"entries": _entries.duplicate(true), "deaths": _deaths.duplicate(true), "exit_state": _exit_state, "contact": _contact.duplicate(true)}}


func _runtime_error() -> String:
	if not _configuration_error.is_empty():
		return _configuration_error
	if not is_instance_valid(scenery) or scenery.is_queued_for_deletion():
		return "Twin Suns requires its live authored scenery"
	if not is_instance_valid(threat_scheduler) or threat_scheduler.is_queued_for_deletion() or not is_instance_valid(exit_cue) or exit_cue.is_queued_for_deletion() or not is_ancestor_of(threat_scheduler) or not is_ancestor_of(exit_cue):
		return "Twin Suns requires its live scheduler and contact cue"
	if not Codec.keys_error(sources, SOURCE_IDS).is_empty():
		return "Twin Suns requires exactly five stable source bindings"
	for source_id: String in SOURCE_IDS:
		var source_marker: Marker3D = get_node_or_null(SOURCE_MARKERS[source_id]) as Marker3D
		if not is_instance_valid(source_marker) or source_marker.is_queued_for_deletion():
			return "Twin Suns requires all five authored source markers"
		if not is_instance_valid(sources[source_id]):
			return "Twin Suns requires all five retained source nodes"
		var source: CinderAct3SunboundStalker = sources[source_id]
		if source.is_queued_for_deletion() or not source.is_inside_tree() or not is_ancestor_of(source):
			return "Twin Suns requires all five retained source nodes"
	var marker: MeshInstance3D = exit_cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
	if not is_instance_valid(marker) or marker.is_queued_for_deletion() or not marker.is_inside_tree() or not marker.material_override is StandardMaterial3D:
		return "Twin Suns requires its live contact marker and material"
	for label: String in ["TwoApproachesTreeLowTrunk", "CrossingTreeLowTrunk"]:
		var body: StaticBody3D = scenery.get_node_or_null(label) as StaticBody3D
		var solid: CollisionShape3D = body.get_node_or_null("Solid") as CollisionShape3D if is_instance_valid(body) else null
		var expected_z: float = 8.0 if label == "TwoApproachesTreeLowTrunk" else -13.0
		if not is_instance_valid(solid) or solid.is_queued_for_deletion() or not solid.is_inside_tree() or solid.disabled or not solid.shape is BoxShape3D or (solid.shape as BoxShape3D).size != Codec.read_vector3(_authoring.floor.low_trunk_size):
			return "Twin Suns requires both actual immutable low trunks"
		if body.position != Vector3(0.0, 0.375, expected_z) or body.basis != Basis.IDENTITY or solid.position != Vector3.ZERO or solid.basis != Basis.IDENTITY or body.collision_layer != 1:
			return "Twin Suns authored low-trunk collision cannot move or change"
	return ""


func _local_snapshot_error(local: Dictionary) -> String:
	if not is_instance_valid(hero):
		return "Twin Suns requires its paired live hero"
	return _paired_local_error(local, hero.global_position, hero.dead)


func _local_snapshot_error_with_player(local: Dictionary, saved_player: Dictionary) -> String:
	var motion: Variant = saved_player.get("motion")
	var resources: Variant = saved_player.get("resources")
	if not motion is Dictionary or not Codec.is_vector3(motion.get("position")) or not resources is Dictionary or not resources.get("dead") is bool:
		return "Twin Suns requires the validated saved hero position/death state"
	return _paired_local_error(local, Codec.read_vector3(motion.position), resources.dead)


func _paired_local_error(local: Dictionary, expected_hero: Vector3, expected_hero_dead: bool) -> String:
	var error: String = _runtime_error()
	if not error.is_empty():
		return error
	if not Codec.keys_error(local, ["api_revision", "schema_version", "scenery", "scheduler", "sources", "route"]).is_empty() or local.get("api_revision") != ROUTE_API or not Codec.is_integer(local.get("schema_version"), 1, 1) or not local.get("scenery") is Dictionary or not local.get("scheduler") is Dictionary or not local.get("sources") is Dictionary or not local.get("route") is Dictionary:
		return "Twin Suns requires its complete versioned route/source/scheduler/scenery unit"
	error = super._local_snapshot_error(local.scenery)
	if not error.is_empty():
		return error
	if not Codec.keys_error(local.sources, SOURCE_IDS).is_empty():
		return "Twin Suns snapshot requires exactly five stable sources"
	var bindings: Dictionary = scheduler_bindings()
	bindings["owner_positions"] = {}
	bindings["owner_velocities"] = {}
	bindings["owner_collision_states"] = {}
	for source_id: String in SOURCE_IDS:
		var saved: Variant = local.sources[source_id]
		if not saved is Dictionary or not Codec.is_vector3(saved.get("position")) or not Codec.is_vector3(saved.get("velocity")):
			return "Twin Suns requires finite staged source positions/velocities"
		# Validate the complete saved actor independently before deriving the
		# native paused collider view from its actual alive/leased lifecycle.
		error = sources[source_id].snapshot_error(saved, local.scheduler)
		if not error.is_empty():
			return source_id + ": " + error
		bindings.owner_positions[source_id] = Codec.read_vector3(saved.position)
		bindings.owner_velocities[source_id] = Codec.read_vector3(saved.velocity)
		if not saved.dead and not String(saved.reservation_id).is_empty():
			bindings.owner_collision_states[source_id] = {"collision_path": "BodyCollision", "enabled": true, "layer": 2, "mask": 1}
	error = threat_scheduler.snapshot_error(local.scheduler, bindings)
	if not error.is_empty():
		return error
	if local.scheduler.get("encounter_id") != ENCOUNTER_ID or local.scheduler.get("world_revision") != WORLD_REVISION:
		return "Twin Suns snapshot must retain its continuous authored encounter"
	for source_id: String in SOURCE_IDS:
		var saved: Dictionary = local.sources[source_id]
		if float(saved.clock_s) != float(local.scheduler.clock_s):
			return "Twin Suns source clocks must exactly match the shared scheduler"
		if float(saved.previous.clock_s) == float(local.scheduler.clock_s) and Codec.read_vector3(saved.previous.hero_position) != expected_hero:
			return "Twin Suns current contact sample differs from the paired hero"
	return _route_local_error(local, expected_hero, expected_hero_dead)


func _route_local_error(local: Dictionary, expected_hero: Vector3, expected_hero_dead: bool) -> String:
	var route: Dictionary = local.route
	if not Codec.keys_error(route, ["entries", "deaths", "exit_state", "contact"]).is_empty() or not route.get("entries") is Array or route.entries.size() > 4 or not route.get("deaths") is Dictionary or not route.get("exit_state") is String or not route.get("contact") is Dictionary:
		return "Twin Suns route requires finite entry/death/contact history"
	# A death callback can pause after actor20 but before entry30. Preserve that
	# legitimate dead boundary; a live paired hero cannot skip a spatial entry.
	if not expected_hero_dead and route.entries.size() < 4 and expected_hero.z <= ENTRY_Z[route.entries.size()]:
		return "Twin Suns live paired hero has passed an unentered spatial boundary"
	var previous_clock: float = -1.0
	for index: int in range(route.entries.size()):
		var entry: Variant = route.entries[index]
		if not entry is Dictionary or not Codec.keys_error(entry, ["id", "clock_s", "hero_position"]).is_empty() or entry.get("id") != POCKET_IDS[index] or not Codec.in_range(entry.get("clock_s"), maxf(previous_clock, 0.0), float(local.scheduler.clock_s)) or not Codec.is_vector3(entry.get("hero_position")):
			return "Twin Suns entry history must be an ordered canonical prefix"
		var position: Vector3 = Codec.read_vector3(entry.hero_position)
		if position.z > ENTRY_Z[index] or not (_floor_region.safe_rect as Rect2).has_point(Vector2(position.x, position.z)):
			return "Twin Suns entry sample must lie past its actual spatial boundary on floor"
		if float(entry.clock_s) == float(local.scheduler.clock_s) and position != expected_hero:
			return "Twin Suns current entry sample differs from the paired hero"
		previous_clock = float(entry.clock_s)
	if int(local.scenery.beat_index) != route.entries.size():
		return "Twin Suns beat presentation must match spatial entry history"
	for source_id: Variant in route.deaths:
		if not SOURCE_IDS.has(source_id):
			return "Twin Suns death history contains an unknown source"
	for source_id: String in SOURCE_IDS:
		var saved: Dictionary = local.sources[source_id]
		if bool(saved.dead) != route.deaths.has(source_id):
			return "Twin Suns clear history must exactly match actual saved deaths"
		if route.deaths.has(source_id):
			var death: Variant = route.deaths[source_id]
			if not death is Dictionary or not Codec.keys_error(death, ["clock_s", "source_position"]).is_empty() or not Codec.in_range(death.get("clock_s"), 0.0, float(local.scheduler.clock_s)) or not Codec.is_vector3(death.get("source_position")) or Codec.read_vector3(death.source_position) != Codec.read_vector3(saved.position):
				return "Twin Suns death record must retain the actual dead source pose"
		if int(SOURCE_POCKETS[source_id]) >= route.entries.size():
			var marker: Marker3D = get_node(SOURCE_MARKERS[source_id]) as Marker3D
			if not String(saved.reservation_id).is_empty() or int(saved.cycle) != 0 or Codec.read_vector3(saved.position) != marker.global_position:
				return "Twin Suns unentered source cannot move or retain an attack lease"
	var all_clear: bool = route.deaths.size() == 5 and route.entries.size() == 4
	if not all_clear:
		if route.exit_state != "clear" or not route.contact.is_empty():
			return "Twin Suns exit remains clear until every actual source is defeated"
	elif route.exit_state not in ["available", "active", "spent"]:
		return "Twin Suns clear route requires its distinct contact exit state"
	if route.exit_state in ["active", "spent"]:
		if not Codec.keys_error(route.contact, ["clock_s", "hero_position"]).is_empty() or not Codec.in_range(route.contact.get("clock_s"), 0.0, float(local.scheduler.clock_s)) or not Codec.is_vector3(route.contact.get("hero_position")) or not _at_exit(Codec.read_vector3(route.contact.hero_position)):
			return "Twin Suns active/spent exit requires a real contact-position sample"
		if float(route.contact.clock_s) == float(local.scheduler.clock_s) and Codec.read_vector3(route.contact.hero_position) != expected_hero:
			return "Twin Suns current contact sample differs from the paired hero"
	elif not route.contact.is_empty():
		return "Twin Suns unused exit cannot contain a contact sample"
	return ""


## Public envelope wrappers add owned progress-to-local relations. Base local
## hooks do not receive progression, so restore must prevalidate this wrapper too.
func snapshot_state() -> Dictionary:
	var snapshot: Dictionary = super.snapshot_state()
	if snapshot.is_empty():
		return snapshot
	last_snapshot_error = _route_progress_error(snapshot)
	return snapshot if last_snapshot_error.is_empty() else {}


func snapshot_error(snapshot: Dictionary) -> String:
	var error: String = super.snapshot_error(snapshot)
	return _route_progress_error(snapshot) if error.is_empty() else error


func snapshot_error_with_player(snapshot: Dictionary, saved_player: Dictionary) -> String:
	var error: String = super.snapshot_error_with_player(snapshot, saved_player)
	return _route_progress_error(snapshot) if error.is_empty() else error


func restore_state(snapshot: Dictionary) -> bool:
	last_snapshot_error = snapshot_error(snapshot)
	if not last_snapshot_error.is_empty():
		return false
	return super.restore_state(snapshot)


func _route_progress_error(snapshot: Dictionary) -> String:
	var route: Dictionary = snapshot.local.route
	var progress: Dictionary = snapshot.progress
	var all_clear: bool = route.deaths.size() == 5 and route.entries.size() == 4
	if progress.completed != all_clear or progress.completion_id != (COMPLETION_ID if all_clear else ""):
		return "Twin Suns completion must match all five actual deaths and spatial entries"
	var expected_checkpoints: Array[String] = []
	for index: int in range(route.entries.size()):
		expected_checkpoints.append(CHECKPOINT_IDS[index])
	if not Codec.keys_error(progress.checkpoint_ids, expected_checkpoints).is_empty():
		return "Twin Suns checkpoint history must exactly match entered pockets"
	for checkpoint: String in expected_checkpoints:
		if progress.checkpoint_ids[checkpoint] != "encounter":
			return "Twin Suns entry checkpoints require encounter boundaries"
	var latest: String = expected_checkpoints[-1] if not expected_checkpoints.is_empty() else ""
	if progress.checkpoint_id != latest or progress.checkpoint_kind != ("encounter" if not latest.is_empty() else ""):
		return "Twin Suns current checkpoint must match its latest spatial entry"
	if progress.contact_exit_id != (EXIT_ID if route.exit_state == "spent" else ""):
		return "Twin Suns contact-exit progress must match its actual spent threshold"
	return ""


func _restore_local_state(local: Dictionary) -> void:
	# All runtime nodes, staged vectors, actors, scheduler and progression have
	# prevalidated before any mutation. Apply without yields or progression events.
	for source_id: String in SOURCE_IDS:
		var applied: bool = sources[source_id].apply_validated_state(local.sources[source_id])
		assert(applied, "Prevalidated Twin Suns source commit failed: " + source_id)
	var scheduler_applied: bool = threat_scheduler.restore_state(local.scheduler, scheduler_bindings())
	assert(scheduler_applied, "Prevalidated Twin Suns scheduler commit failed")
	super._restore_local_state(local.scenery)
	_entries.clear()
	for entry: Dictionary in local.route.entries:
		_entries.append(entry.duplicate(true))
	_deaths = local.route.deaths.duplicate(true)
	_exit_state = local.route.exit_state
	_contact = local.route.contact.duplicate(true)
	_exit_dispatch_generation += 1
	_exit_dispatch_queued = false
	for source_id: String in SOURCE_IDS:
		var source: CinderAct3SunboundStalker = sources[source_id]
		source.set_sun_visual(sun_state)
		var refreshed: bool = source.refresh_presentation()
		assert(refreshed, "Prevalidated Twin Suns source presentation failed: " + source_id)
		source.set_physics_process(int(SOURCE_POCKETS[source_id]) < _entries.size() and not source.dead)
	# Do not inspect base progress during its local hook: base commits it next.
	_update_presentation(true)
