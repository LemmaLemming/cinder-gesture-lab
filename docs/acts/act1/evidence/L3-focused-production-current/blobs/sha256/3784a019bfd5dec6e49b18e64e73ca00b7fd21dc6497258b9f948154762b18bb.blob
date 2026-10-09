extends "res://scripts/acts/act1/mushroom_caverns.gd"
## Owned normal-route prototype; full native gameplay and aggregate still untested.
## One real retained19 cast and one shared Player/Scheduler; no auto waves,
## private attack clock, synthetic kill, teleport or campaign save support.
## Source/field tables below are provisional full-main choices, separate from
## Layout's frozen component starts. Camera/body admission may still reject.

const NativeProtocol = preload("res://scripts/environment/scheduler_spore_source_protocol.gd")
const SporeField = preload("res://scripts/environment/spore_field.gd")
const Repulsion = preload("res://scripts/environment/spore_repulsion.gd")
const SporeRoute = preload("res://scripts/combat/repulsion_route.gd")
const LowClusterArt = preload("res://scripts/acts/act1/mushroom_cluster_art.gd")
const InteractionCue = preload("res://scripts/cues/interaction_cue.gd")
const NORMAL_SOURCE_IDS: Array[String] = ["umbrella-1", "umbrella-2", "umbrella-3", "breathing-1", "breathing-2", "breathing-3", "crossed-1", "crossed-2", "crossed-3", "crossed-4", "crossed-5", "crossed-6", "crossed-7", "crossed-8", "lone-guard", "court-1", "court-2", "court-3", "court-guard"]
const ROOM_SOURCES: Array = [
	["umbrella-1", "umbrella-2", "umbrella-3"],
	["breathing-1", "breathing-2", "breathing-3"],
	["crossed-1", "crossed-2", "crossed-3", "crossed-4", "crossed-5", "crossed-6", "crossed-7", "crossed-8"],
	["lone-guard"], ["court-1", "court-2", "court-3", "court-guard"],
]
const ROOM_FIELDS: Array = [[], ["breathing"], ["crossed-left", "crossed-right"], [], ["court"]]
const ROOM_BEATS: Array[String] = ["umbrella-grove", "breathing-chamber", "crossed-grotto", "spear-pocket", "court-approach"]
const CHECKPOINTS: Array[String] = ["umbrella-grove", "breathing-chamber", "crossed-grotto", "spear-pocket"]
const COMPLETION_ID: String = "mushroom-caverns-clear"
const EXIT_ID: String = "open-court"
const CONTROLLER_ID: String = "mushroom-scheduler"
const CLUSTER_IDS: Array[String] = ["cluster-left", "cluster-right"]
const SPORE_CAMERA_PAD: float = 0.05 # Presentation reserve, not motion permission.
const SAVE_REFUSAL: String = "Normal L3 route has no implemented whole native aggregate/candidate consumer"
# Explicit candidate starts: Root must choose/freeze these before native tests.
# Narrowed eight-body columns preserve all actual actors and ordinary capsules.
const NORMAL_SOURCE_POINTS: Dictionary = {
	"umbrella": [Vector3(-2.4, .005, 10), Vector3(2.4, .005, 10), Vector3(-2.4, .005, 7.2)],
	"breathing": [Vector3(-2.4, .005, -1.5), Vector3(2.4, .005, -1.5), Vector3(0, .005, -5.2)],
	"crossed": [Vector3(-2.4, .005, -12.8), Vector3(2.4, .005, -12.8), Vector3(-.8, .005, -13.6), Vector3(.8, .005, -13.6), Vector3(-2.4, .005, -19.2), Vector3(2.4, .005, -19.2), Vector3(-.8, .005, -18.4), Vector3(.8, .005, -18.4)],
	"lone-guard": [Vector3(0, .005, -30)],
	"court": [Vector3(-2.4, .005, -40.5), Vector3(2.4, .005, -40.5), Vector3(0, .005, -41.5), Vector3(0, .005, -45)],
}
# The old crossed X+-2.6 circles span8.2m and cannot fit a7.2m view.
# This owned longitudinal alternative is a proposal, not a native union proof.
const NORMAL_FIELD_POINTS: Dictionary = {"breathing": Vector3(-.4, 0, -2), "crossed-left": Vector3(-.4, 0, -15.2), "crossed-right": Vector3(.4, 0, -18), "court": Vector3(.4, 0, -43)}
# Source movement extents preserve broad chamber space. They do not restrict Hero
# gestures, grant a landing, add walls or replace actual native support queries.
const ROOM_RECTS: Array[Rect2] = [Rect2(-6.35, 4, 12.7, 13), Rect2(-6.35, -9.9, 12.7, 13.8), Rect2(-6.35, -24.9, 12.7, 14.9), Rect2(-6.35, -37.9, 12.7, 12.9), Rect2(-6.35, -53.2, 12.7, 15.2)]
const OBJECTIVES: Array[String] = ["UMBRELLA GROVE\nCLEAR THE THREE SWARMERS", "BREATHING CHAMBER\nLOW CLUSTERS REPEL LIVING ENEMIES", "CROSSED GROTTO\nKEEP AN ORDINARY ESCAPE AND OPENING", "THE SPEAR BRACES\nREAD THE LANE · FLANK THE GUARD", "COURT APPROACH\nCLEAR THE SWARM AND SPEAR GUARD", "MUSHROOM CAVERNS CLEAR\nCROSS THE OPEN COURT"]

var beat_index: int = 0
var completed_beats: Array[String] = []
var room_stage: String = "approach"
var encounter_started: bool = false
var _publishing_progress: bool = false
var _fields: Dictionary = {}
var _consumers: Dictionary = {}
var _protocols: Dictionary = {}
var _cluster_art: Dictionary = {}
var _field_callbacks: Dictionary = {}
var _route_callbacks: Dictionary = {}
var _player_body: Dictionary = {}
var _exit_area: Area3D
var _exit_shape: CollisionShape3D
var _exit_resource: BoxShape3D
var _exit_cue: CinderInteractionCue


func _ready() -> void:
	enable_swarm_approach = true # Immutable opt-in for this normal prototype.
	super._ready()
	if not _construction_error.is_empty(): return
	_build_contact()


func _all_source_ids() -> Array[String]:
	return NORMAL_SOURCE_IDS.duplicate()


func _authored_stalk_specs() -> Array:
	var specifications: Array = super._authored_stalk_specs()
	# Normal route only: move the whole real stalk and all its painted/cap
	# children together. Optical clearance is pending actual portrait review.
	for spec: Dictionary in specifications:
		if spec.id == "BreathingStalk": spec["origin"] = Vector3(-5.1, 0, -3.2)
		if spec.id == "CrossedRightStalk": spec["origin"] = Vector3(5.6, 0, -16.0)
	return specifications


func _source_spec(id: String) -> Dictionary:
	for room: int in ROOM_SOURCES.size():
		var index: int = ROOM_SOURCES[room].find(id)
		if index >= 0:
			return {"role_id": "C32" if id in ["lone-guard", "court-guard"] else "C31", "position": NORMAL_SOURCE_POINTS[Layout.ROOM_IDS[room]][index], "approach": id not in ["lone-guard", "court-guard"]}
	return {} # Constructor's actual configure rejects an unsupported definition.


func _component_configuration_error() -> String:
	return "Normal Caverns starts at its actual first entrance" if initial_greybox_room != 0 else ""


func _initial_objective_text() -> String:
	return OBJECTIVES[0]


func normal_route_spec() -> Dictionary:
	# Native read-only authored definitions; not a save or world certificate.
	return {"sources": NORMAL_SOURCE_IDS.duplicate(), "room_sources": ROOM_SOURCES.duplicate(true), "room_fields": ROOM_FIELDS.duplicate(true), "source_points": NORMAL_SOURCE_POINTS.duplicate(true), "field_points": NORMAL_FIELD_POINTS.duplicate(true), "room_rects": ROOM_RECTS.duplicate(), "thresholds": Layout.BEAT_THRESHOLDS.duplicate(), "checkpoint_ids": CHECKPOINTS.duplicate(), "completion_id": COMPLETION_ID, "exit_id": EXIT_ID}


func current_source_ids() -> Array[String]:
	var result: Array[String] = []
	if beat_index < 5:
		for id: String in ROOM_SOURCES[beat_index]: result.append(id)
	return result


func _encounter_id() -> String:
	return "a1_l3_" + Layout.ROOM_IDS[beat_index] if beat_index < 5 else "a1_l3_complete"


func _start_initial_encounter() -> void:
	# Inherited entry bound ALL19 to the single actual Scheduler/Player first.
	# No future enemy/field is made live in an entered normal world.
	_player_body = BodySweep.source_description(hero)
	if _player_body.has("error") or not _player_body.get("collision") is CollisionShape3D or not _player_body.collision.shape is CapsuleShape3D:
		_entry_failed("Normal Caverns requires the actual shared Player capsule")
		return
	_player_body["parent"] = hero.get_parent()
	_player_body["shape"] = _player_body.collision.shape
	_player_body["transform"] = _player_body.collision.transform
	_player_body["radius"] = _player_body.collision.shape.radius
	_player_body["height"] = _player_body.collision.shape.height
	_apply_route_presentation()


func _refresh_render_state() -> void:
	# Read raw actual control without state() pruning or observer delivery.
	for id: String in _all_source_ids():
		var retained: Variant = sources.get(id)
		if not is_instance_valid(retained) or not retained is Act1MushroomSelenite:
			_render_sources[id] = {}
			last_encounter_error = "Retained normal-route source is unavailable: " + id
			_running = false
			continue
		var actor: Act1MushroomSelenite = retained
		if actor != _retained_sources.get(id) or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.get_parent() != self:
			_render_sources[id] = {}
			last_encounter_error = "Retained normal-route source is unavailable: " + id
			_running = false
			continue
		_render_sources[id] = actor.pure_presentation_state()


func _physics_process(delta: float) -> void:
	if not _running or _changing or not is_instance_valid(hero): return
	_refresh_render_state() # Settle final actual presentation after all native ticks.
	if not _running: return
	var art_error: String = _sync_clusters()
	if not art_error.is_empty():
		last_encounter_error = art_error
		return
	if hero.dead: return
	if beat_index == 5:
		if _exit_area.overlaps_body(hero): request_contact_exit(EXIT_ID, hero)
		return
	if room_stage == "approach":
		if hero.global_position.z <= Layout.BEAT_THRESHOLDS[beat_index]: _begin_room()
		return
	if room_stage != "active": return
	if _room_genuinely_clear():
		_advance_room()
		return
	super._physics_process(delta) # Same native pursuit/preview/proof/admission loop.


func _quiet_lifecycle_error() -> String:
	var binding_error: String = _spore_bindings_error()
	if not binding_error.is_empty(): return binding_error
	if _callback_depth > 0 or get_tree().paused or not _floor_error().is_empty() or not _scenery_error().is_empty(): return "Room boundary requires actual unpaused supported world outside callbacks"
	for id: String in _all_source_ids():
		var retained: Variant = sources.get(id)
		if not is_instance_valid(retained) or not retained is Act1MushroomSelenite: return "Retain every actual source at the quiet room boundary"
		var actor: Act1MushroomSelenite = retained
		if actor != _retained_sources.get(id) or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.get_parent() != self: return "Retain every actual source at the quiet room boundary"
		var response: Dictionary = actor.get_spore_response_state()
		var control: Dictionary = scheduler.source_control_state(actor)
		if response.is_empty() or not response.outside_transaction or control.is_empty() or not control.outside_transaction or not control.reservations.is_empty(): return "Every retained source must release its actual native callback/lease before a new room"
	for consumer: CinderSporeRepulsion in _consumers.values():
		if not consumer.snapshot_boundary_available(): return "Environmental callback must finish before a room boundary"
	return ""


func _begin_room() -> void:
	last_encounter_error = _quiet_lifecycle_error()
	if not last_encounter_error.is_empty(): return
	_changing = true
	var profile: String = String(shared_shell.call("get_difficulty_preference")) if shared_shell.has_method("get_difficulty_preference") else "standard"
	scheduler.end_encounter("normal_authored_room_boundary")
	if not scheduler.begin_encounter(profile, _encounter_id(), WORLD_REVISION):
		_changing = false
		_entry_failed(scheduler.last_error)
		return
	encounter_started = true
	room_stage = "preparing_environment"
	for id: String in current_source_ids():
		_activation_entitlement = id
		var accepted: bool = (sources[id] as Act1MushroomSelenite).activate()
		_activation_entitlement = ""
		if not accepted:
			_changing = false
			_entry_failed((sources[id] as Act1MushroomSelenite).last_error)
			return
	# Published binding measures actual support, including fresh floor history;
	# no staged grounded flag or prescribed settling clock is introduced.
	var environment_error: String = _install_room_environment()
	_changing = false
	if not environment_error.is_empty():
		_entry_failed(environment_error)
		return
	room_stage = "active"
	_refresh_render_state()
	_apply_route_presentation()
	_framing_ready(_camera_framing_points()) # Truthful diagnostic; admission remains guarded.


func _install_room_environment() -> String:
	return _install_authored_room_environment(beat_index)


func _install_authored_room_environment(room: int) -> String:
	if room < 0 or room >= 5: return "Known authored room required"
	var field_ids: Array = ROOM_FIELDS[room]
	if field_ids.is_empty(): return ""
	var room_id: String = Layout.ROOM_IDS[room]
	if _consumers.has(room_id): return "A room's permanent spore consumer cannot be rebound"
	var native: Dictionary = scheduler_bindings()
	var environment: Dictionary = {"world_root": native.world_root, "floors": native.floors}
	var recipients: Dictionary = {}
	var protocols: Dictionary = {}
	for id: String in ROOM_SOURCES[room]:
		var actor: Act1MushroomSelenite = sources[id]
		var callback: Callable = Callable(self, "_normal_spore_route_error").bind(id, room_id)
		_route_callbacks[id] = callback
		actor.spore_route_guard = callback
		actor.spore_route_guard_required = true
		var protocol := NativeProtocol.new()
		if not protocol.configure(actor, scheduler, hero, id, CONTROLLER_ID, "hero", environment): return id + ": " + protocol.last_error
		protocols[id] = protocol
		recipients[id] = actor
	var room_fields: Dictionary = {}
	for field_id: String in field_ids:
		if _fields.has(field_id): return "Actual field is installed once and retained"
		var field := SporeField.new()
		field.name = field_id.replace("-", "_") + "_mushroom"
		field.position = NORMAL_FIELD_POINTS[field_id]
		if not field.configure(field_id, [{"id": "cluster-left", "offset": Layout.CLUSTER_OFFSETS[0]}, {"id": "cluster-right", "offset": Layout.CLUSTER_OFFSETS[1]}], {"radius": Layout.FIELD_RADIUS, "duration_s": 3.0, "thinning_s": .5}):
			var diagnostic: String = field.last_error
			field.free()
			return diagnostic
		add_child(field)
		_fields[field_id] = field
		room_fields[field_id] = field
		var leaves: Dictionary = {}
		_cluster_art[field_id] = leaves
		for cluster_id: String in CLUSTER_IDS:
			var leaf = LowClusterArt.new()
			var cluster := field.get_node_or_null(cluster_id) as Node3D
			leaf.name = "AuthoredLowCluster"
			if not leaf.configure(cluster, field):
				var diagnostic: String = leaf.last_error
				leaf.free()
				return diagnostic
			cluster.add_child(leaf)
			leaves[cluster_id] = leaf
		var callback: Callable = Callable(self, "_on_room_field_state").bind(field_id)
		_field_callbacks[field_id] = callback
		field.state_changed.connect(callback)
	var consumer := Repulsion.new()
	consumer.name = room_id.replace("-", "_") + "_native_spores"
	var directions: Array[Vector3] = [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]: directions.append(Vector3(x, 0, z).normalized())
	if not consumer.configure("a1_l3_" + room_id + "_spores", directions):
		var diagnostic: String = consumer.last_error
		consumer.free()
		return diagnostic
	add_child(consumer)
	if not consumer.bind_environment({"world_root": native.world_root, "floors": native.floors, "fields": room_fields, "sources": recipients, "source_protocols": protocols}):
		var diagnostic: String = consumer.last_error
		consumer.queue_free()
		return diagnostic
	_protocols[room_id] = protocols
	_consumers[room_id] = consumer
	var error: String = _sync_clusters()
	return error if not error.is_empty() else _spore_bindings_error()


func _cluster_handles_error() -> String:
	# Native availability/active/spent may already have changed in its callback.
	# Validate actual handles before syncing, without comparing old pixels to it.
	for field_id: String in _fields:
		var field := _fields[field_id] as CinderSporeField
		if not is_instance_valid(field) or not field.is_inside_tree() or field.is_queued_for_deletion() or field.get_parent() != self or field.global_position != NORMAL_FIELD_POINTS[field_id]: return "Retain installed actual mushroom and fixed origin"
		var error: String = field.binding_error()
		if not error.is_empty(): return error
		var leaves: Dictionary = _cluster_art.get(field_id, {})
		if not Codec.keys_error(leaves, CLUSTER_IDS).is_empty(): return "Both true low-cluster presentation leaves required"
		for cluster_id: String in CLUSTER_IDS:
			var leaf := leaves[cluster_id] as Node3D
			if not is_instance_valid(leaf) or not leaf.is_inside_tree() or leaf.is_queued_for_deletion() or leaf.get_script() != LowClusterArt or leaf.get_parent() != field.get_node_or_null(cluster_id): return "Retain actual low cluster art/resources"
	return ""


func _cluster_bindings_error() -> String:
	# Pure consumers never redraw or repair state; after synchronization the leaf
	# itself checks every retained resource and exact native presentation meaning.
	var error: String = _cluster_handles_error()
	if not error.is_empty(): return error
	for leaves: Dictionary in _cluster_art.values():
		for leaf: Node3D in leaves.values():
			error = String(leaf.call("binding_error"))
			if not error.is_empty(): return error
	return ""


func _sync_clusters() -> String:
	var error: String = _cluster_handles_error()
	if not error.is_empty(): return error
	for leaves: Dictionary in _cluster_art.values():
		for leaf: Node3D in leaves.values():
			error = String(leaf.call("sync_from_native"))
			if not error.is_empty(): return error
	return _cluster_bindings_error()


func _spore_bindings_error() -> String:
	# Permanent room bindings include the exact owned pre-cancel/continuation
	# guard. A different valid Callable is not authority for the actual Route.
	for room_id: String in _consumers:
		var room: int = Layout.ROOM_IDS.find(room_id)
		if room < 0 or ROOM_FIELDS[room].is_empty(): return "Only the actual spore room has a permanent consumer"
		var consumer := _consumers[room_id] as CinderSporeRepulsion
		if not is_instance_valid(consumer) or not consumer.is_inside_tree() or consumer.is_queued_for_deletion() or consumer.get_parent() != self or consumer.consumer_id() != "a1_l3_" + room_id + "_spores": return "Retain the actual native room consumer and identity"
		var protocols: Dictionary = _protocols.get(room_id, {})
		if not Codec.keys_error(protocols, ROOM_SOURCES[room]).is_empty(): return "Retain every actual room source protocol"
		for id: String in ROOM_SOURCES[room]:
			var retained: Variant = sources.get(id)
			if not is_instance_valid(retained) or not retained is Act1MushroomSelenite: return "Retain the actual bound source and world"
			var actor: Act1MushroomSelenite = retained
			if actor != _retained_sources.get(id) or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.get_parent() != self or actor.get_world_3d() != get_world_3d(): return "Retain the actual bound source and world"
			var protocol: Variant = protocols.get(id)
			if not protocol is RefCounted or not is_instance_valid(protocol) or protocol.get_script() != NativeProtocol: return "Retain the published native source protocol"
			var callback: Callable = _route_callbacks.get(id, Callable())
			if not callback.is_valid() or not actor.spore_route_guard_required or actor.spore_route_guard != callback: return "Retain the exact required owned spore Route guard"
			if not consumer.source_binding_matches(actor, id): return "Retain the exact actual source/consumer binding"
	return ""


func _on_room_field_state(_state: Dictionary, _field_id: String) -> void:
	if not _running or _changing: return
	var error: String = _sync_clusters()
	if error.is_empty(): error = _spore_bindings_error()
	if not error.is_empty(): last_encounter_error = error


func _source_approach_error(plan: Dictionary, id: String) -> String:
	var binding_error: String = _spore_bindings_error()
	if not binding_error.is_empty(): return binding_error
	if room_stage != "active" or id not in current_source_ids(): return "Approach belongs only to the actual entitled room"
	var radius: float = (_retained_capsules[id] as CapsuleShape3D).radius
	for key: String in ["next_position", "braking_position"]:
		if not plan.get(key) is Vector3 or not _inside_source_room(plan[key], radius): return "Complete source approach/braking body must stay in its broad authored chamber"
	return super._source_approach_error(plan, id)


func _inside_source_room(position: Vector3, radius: float) -> bool:
	return beat_index < 5 and position.is_finite() and ROOM_RECTS[beat_index].grow(-radius).has_point(Vector2(position.x, position.z))


func _admit(id: String, delta: float) -> void:
	if room_stage != "active": return
	var binding_error: String = _spore_bindings_error()
	if binding_error.is_empty(): binding_error = _cluster_bindings_error()
	if not binding_error.is_empty():
		last_encounter_error = binding_error
		return
	var actor: Act1MushroomSelenite = sources[id]
	var preview: Dictionary = actor.preview_start(hero.global_position, response_context(String(_render_sources[id].role_id)))
	if not preview.get("accepted", false):
		last_encounter_error = String(preview.get("reason", "Native room preview rejected"))
		return
	if not _inside_source_room(preview.candidate.opening_position, (_retained_capsules[id] as CapsuleShape3D).radius):
		last_encounter_error = "Actual source/opening must remain in its broad room"
		return
	# Parent's second native preview remains fresh; this preliminary query grants
	# no admission and mutates no source/role/cooldown. No private solver is used.
	super._admit(id, delta)


func _source_presentation_error(id: String) -> String:
	var error: String = _spore_bindings_error()
	if error.is_empty(): error = _cluster_bindings_error()
	return error if not error.is_empty() else super._source_presentation_error(id)


func _neighbor_paths(id: String, delta: float) -> Dictionary:
	var result: Dictionary = super._neighbor_paths(id, delta)
	if not result.get("accepted", false) or beat_index >= 5: return result
	var consumer := _consumers.get(Layout.ROOM_IDS[beat_index]) as CinderSporeRepulsion
	if not is_instance_valid(consumer): return result
	for other_id: String in current_source_ids():
		if other_id == id: continue
		var other := sources.get(other_id) as Act1MushroomSelenite
		if not is_instance_valid(other) or other.dead or other.dormant: continue
		var record: Dictionary = consumer.source_state(other_id)
		if not record.get("original_endpoint") is Vector3: continue
		var endpoint: Vector3 = record.original_endpoint
		if not endpoint.is_finite(): return {"accepted": false, "reason": "Actual neighboring environmental endpoint must remain finite"}
		var radius: float = (_retained_capsules[other_id] as CapsuleShape3D).radius
		# Include the real prepared/continuing Route endpoint in addition to the
		# inherited native-lunge or hurt/braking corridor. No scalar brake estimate
		# substitutes for an actual retained environmental travel plan.
		result.paths.append({"from": other.global_position, "to": endpoint, "radius": radius})
	return result


func _normal_spore_route_error(proposal: Dictionary, id: String, room_id: String) -> String:
	var error: String = _spore_bindings_error()
	if error.is_empty(): error = _cluster_bindings_error()
	if not error.is_empty(): return error
	var actor := sources.get(id) as Act1MushroomSelenite
	var consumer := _consumers.get(room_id) as CinderSporeRepulsion
	if not _running or _changing or get_tree().paused or hero.dead or room_stage != "active" or id not in current_source_ids() or not is_instance_valid(actor) or actor != _retained_sources.get(id) or not is_instance_valid(consumer) or not consumer.source_binding_matches(actor, id): return "Retain actual entitled native source/room/consumer before environmental movement"
	if not Codec.keys_error(proposal, ["source_id", "consumer", "episode_id", "boundary", "direction"]).is_empty() or proposal.source_id != id or proposal.consumer != consumer or not proposal.episode_id is String or proposal.boundary not in ["cancel", "continue"] or not proposal.direction is Vector3 or not proposal.direction.is_finite(): return "Closed same-source environmental boundary required"
	error = actor.body_binding_error()
	if error.is_empty(): error = actor.art_binding_error()
	if error.is_empty(): error = _floor_error()
	if error.is_empty(): error = _scenery_error()
	if not error.is_empty(): return error
	var body: Dictionary = BodySweep.source_description(hero)
	if body.has("error") or hero.get_parent() != _player_body.parent or body.get("collision") != _player_body.collision or _player_body.collision.shape != _player_body.shape or _player_body.collision.transform != _player_body.transform or _player_body.shape.radius != _player_body.radius or _player_body.shape.height != _player_body.height: return "Retain actual complete Player capsule and world"
	var response: Dictionary = actor.get_spore_response_state()
	var record: Dictionary = consumer.source_state(id)
	var required_phase: String = "recoil" if proposal.boundary == "cancel" else "interrupted"
	if response.is_empty() or not response.alive or not response.grounded or not response.outside_transaction or record.get("episode_id") != proposal.episode_id or record.get("phase") != required_phase or not record.get("original_endpoint") is Vector3: return "Actual same-episode prepared endpoint required"
	var start: Vector3 = actor.global_position
	var original: Vector3 = record.original_endpoint
	if not original.is_finite() or absf(original.y - start.y) > SporeRoute.ENDPOINT_TOLERANCE: return "Retain supported original environmental feet plane"
	var finish := Vector3(original.x, start.y, original.z)
	var motion: Vector3 = finish - start
	if motion.length() <= Repulsion.EPSILON or motion.length() > BodySweep.MAX_DISTANCE or not _inside_source_room(finish, (_retained_capsules[id] as CapsuleShape3D).radius): return "Bounded whole environmental body endpoint must remain in the actual room"
	if proposal.boundary == "continue" and proposal.direction != motion.normalized(): return "Native continuation retains its original endpoint bearing"
	var sweep: Dictionary = BodySweep.sweep(actor, Transform3D(Basis.IDENTITY, start), motion, scheduler_bindings().floors.values())
	if sweep.has("error") or sweep.get("collided", true) or not sweep.get("end") is Vector3 or sweep.end.distance_to(finish) > BodySweep.position_rounding_bound(start, finish): return "Actual full retreat body path must retain clear native floor/scenery support"
	# Conservative current neighbor paths do not predict an uncommitted future
	# player swipe or prove simultaneous eight-body Route ordering. Tests required.
	error = _source_path_gap_error(id, start, finish, 0.0)
	if not error.is_empty(): return error
	var player_response: Dictionary = hero.get_threat_response_state()
	var dash: Dictionary = hero.get_committed_dash_state()
	if not player_response.get("motion", {}).get("grounded", false) or dash.is_empty(): return "Actual grounded Player commitment required for body spacing"
	var endpoint: Vector3 = hero.global_position
	if dash.get("active", false): endpoint = dash.origin + dash.direction * float(dash.distance)
	elif player_response.motion.velocity != Vector3.ZERO or player_response.motion.queued_dash != Vector3.ZERO: return "This owned guard does not certify uncommitted Player hurt/queued motion"
	var capsule := _retained_capsules[id] as CapsuleShape3D
	if _planar_segment_distance(start, finish, hero.global_position, endpoint) < capsule.radius + float(_player_body.radius) + .12: return "Native retreat requires a complete actual Player/dash capsule gap"
	var points: Array = _camera_framing_points() + _actor_points(id, finish)
	var hero_points: Array = shared_shell.call("player_camera_framing_points")
	if hero_points.is_empty(): return "Complete actual Player presentation required"
	points.append_array(hero_points)
	for point: Vector3 in hero_points: points.append(point + endpoint - hero.global_position)
	return _containment_error(_bounded_union(points))


func _camera_framing_points() -> Array:
	var points: Array = super._camera_framing_points()
	if not _running: return points
	if not _spore_bindings_error().is_empty() or not _cluster_bindings_error().is_empty(): return [Vector3.INF]
	if beat_index < 5:
		for field_id: String in ROOM_FIELDS[beat_index]:
			if not _fields.has(field_id): continue # Genuinely absent approach-stage field.
			var origin: Vector3 = _fields[field_id].global_position
			for x: float in [-Layout.FIELD_RADIUS, Layout.FIELD_RADIUS]:
				for z: float in [-Layout.FIELD_RADIUS, Layout.FIELD_RADIUS]: points.append(origin + Vector3(x, .03, z))
			for leaf: Node3D in _cluster_art[field_id].values():
				var actual: Array = leaf.call("framing_points", shared_shell)
				if actual.is_empty(): return [Vector3.INF]
				points.append_array(actual)
			for id: String in current_source_ids():
				var actor: Act1MushroomSelenite = sources[id]
				if actor.dead or actor.dormant: continue
				var response: Dictionary = actor.get_spore_response_state()
				if response.is_empty(): return [Vector3.INF]
				var radius: float = Layout.FIELD_RADIUS + float(response.support_radius) + float(Repulsion.DEFAULTS.exit_clearance) + SPORE_CAMERA_PAD
				var actual: Array = _actor_points(id, actor.global_position)
				for x: float in [-radius, radius]:
					for z: float in [-radius, radius]:
						var endpoint := Vector3(origin.x + x, actor.global_position.y, origin.z + z)
						for point: Vector3 in actual: points.append(point + endpoint - actor.global_position)
		var consumer := _consumers.get(Layout.ROOM_IDS[beat_index]) as CinderSporeRepulsion
		if is_instance_valid(consumer):
			for id: String in current_source_ids():
				var record: Dictionary = consumer.source_state(id)
				if record.get("route", {}).get("planned_endpoint") is Vector3: points.append_array(_actor_points(id, record.route.planned_endpoint))
	elif not _contact_error().is_empty():
		return [Vector3.INF]
	else:
		points.append_array(_box_points(AABB(-_exit_resource.size * .5, _exit_resource.size), _exit_shape.global_transform))
		var marker := _exit_cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
		if not is_instance_valid(marker) or marker.mesh == null or not marker.is_visible_in_tree(): return [Vector3.INF]
		points.append_array(_box_points(marker.get_aabb(), marker.global_transform))
	# Convex containment compression encloses EVERY actual point, not a source
	# distance filter. It never validates body paths or makes an oversized union fit.
	return _bounded_union(points)


func _bounded_union(points: Array) -> Array:
	if points.is_empty(): return []
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite(): return [Vector3.INF]
	# A world-axis box mixes unrelated maximum height/depth corners and can
	# inflate the fixed camera's projected bounds. Enclose every original corner
	# in the ACTUAL camera basis instead; the camera and world remain untouched.
	var raw: Variant = shared_shell.get("camera") if is_instance_valid(shared_shell) else null
	if not is_instance_valid(raw) or not raw is Camera3D: return [Vector3.INF]
	var actual_camera: Camera3D = raw
	var basis: Basis = actual_camera.global_basis
	if not basis.is_finite() or absf(basis.determinant() - 1.0) > 0.00001: return [Vector3.INF]
	var inverse: Basis = basis.inverse()
	var bounds := AABB(inverse * points[0], Vector3.ZERO)
	for point: Vector3 in points: bounds = bounds.expand(inverse * point)
	# Outward presentation reserve covers float32 roundtrip; it never relaxes
	# protected containment or supplies a body/landing/Route permission.
	bounds = bounds.grow(0.0001)
	return _box_points(bounds, Transform3D(basis, Vector3.ZERO))


func _room_genuinely_clear() -> bool:
	if not _spore_bindings_error().is_empty(): return false
	if not encounter_started or room_stage != "active" or hero.dead: return false
	for id: String in current_source_ids():
		if not (sources[id] as Act1MushroomSelenite).dead: return false
	var consumer := _consumers.get(Layout.ROOM_IDS[beat_index]) as CinderSporeRepulsion
	if is_instance_valid(consumer):
		if not consumer.snapshot_boundary_available(): return false
		for id: String in current_source_ids():
			if not consumer.source_state(id).is_empty(): return false
	return not scheduler.has_committed_exchange()


func _advance_room() -> void:
	if not _room_genuinely_clear() or not _quiet_lifecycle_error().is_empty(): return
	_changing = true
	# Genuine all-dead encounter boundary retires old readiness; no live actor's
	# original cooldown is shortened to obtain another attack.
	scheduler.end_encounter("actual_room_required_cast_defeated")
	for id: String in current_source_ids():
		var control: Dictionary = scheduler.source_control_state(sources[id])
		if not control.outside_transaction or not control.reservations.is_empty() or control.cooldown != null:
			_changing = false
			_entry_failed("Actual defeated room retained native lease/readiness after its boundary")
			return
	completed_beats.append(ROOM_BEATS[beat_index])
	beat_index += 1
	encounter_started = false
	room_stage = "complete" if beat_index == 5 else "approach"
	_framing.clear()
	_forecast_points.clear()
	_approach_forecasts.clear()
	_approach_camera_requests.clear()
	_publishing_progress = true
	var accepted: bool = request_completion(COMPLETION_ID) if beat_index == 5 else request_checkpoint(CHECKPOINTS[beat_index - 1], "encounter")
	_publishing_progress = false
	_changing = false
	if not accepted:
		_entry_failed("Actual authored progress publication rejected")
		return
	_apply_route_presentation()


func request_checkpoint(checkpoint_id: String, boundary_kind: String = "encounter") -> bool:
	if not _publishing_progress or beat_index not in [1, 2, 3, 4] or checkpoint_id != CHECKPOINTS[beat_index - 1] or boundary_kind != "encounter": return false
	_publishing_progress = false # Consume before inherited synchronous observers.
	return super.request_checkpoint(checkpoint_id, boundary_kind)


func request_completion(completion_id: String = "complete") -> bool:
	if not _publishing_progress or beat_index != 5 or completed_beats != ROOM_BEATS or completion_id != COMPLETION_ID: return false
	for id: String in _all_source_ids():
		if not (sources[id] as Act1MushroomSelenite).dead: return false
	_publishing_progress = false # Nested public completion cannot reuse entitlement.
	return super.request_completion(completion_id)


func _build_contact() -> void:
	_exit_area = Area3D.new()
	_exit_area.name = "ActualOpenCourtContact"
	_exit_area.position = Layout.EXIT
	_exit_area.collision_layer = 0
	_exit_area.collision_mask = 4
	_exit_shape = CollisionShape3D.new()
	_exit_shape.name = "BroadCourtContact"
	_exit_resource = BoxShape3D.new()
	_exit_resource.size = Vector3(2.8, 1.6, 1.6)
	_exit_shape.shape = _exit_resource
	_exit_area.add_child(_exit_shape)
	add_child(_exit_area)
	_exit_area.body_entered.connect(_on_court_contact)
	_exit_cue = InteractionCue.new()
	_exit_cue.name = "ActualCourtContactCue"
	_exit_cue.position = Vector3(Layout.EXIT.x, 0, Layout.EXIT.z + .8)
	add_child(_exit_cue)
	_exit_cue.clear()


func _contact_error() -> String:
	if not is_instance_valid(_exit_area) or not _exit_area.is_inside_tree() or _exit_area.is_queued_for_deletion() or _exit_area.get_parent() != self or _exit_area.position != Layout.EXIT or _exit_area.basis != Basis.IDENTITY or _exit_area.collision_layer != 0 or _exit_area.collision_mask != 4 or not _exit_area.monitoring: return "Retain the actual broad court Area"
	if not is_instance_valid(_exit_shape) or _exit_shape.get_parent() != _exit_area or not _exit_shape.is_inside_tree() or _exit_shape.is_queued_for_deletion() or _exit_shape.shape != _exit_resource or _exit_shape.disabled or _exit_shape.transform != Transform3D.IDENTITY or _exit_resource.size != Vector3(2.8, 1.6, 1.6): return "Retain the actual court contact box/resource"
	if not is_instance_valid(_exit_cue) or _exit_cue.get_parent() != self or not _exit_cue.is_inside_tree() or _exit_cue.is_queued_for_deletion() or _exit_cue.position != Vector3(Layout.EXIT.x, 0, Layout.EXIT.z + .8) or _exit_cue.basis != Basis.IDENTITY or not _exit_cue.is_visible_in_tree(): return "Retain the actual contact cue"
	if beat_index == 5:
		var cue_state: Dictionary = _exit_cue.state()
		var marker := _exit_cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
		if cue_state.get("state") != "available" or cue_state.get("trigger") != "contact" or not cue_state.get("required", false) or not is_instance_valid(marker) or not marker.is_inside_tree() or marker.is_queued_for_deletion() or marker.get_parent() != _exit_cue or marker.mesh == null or marker.material_override == null or not marker.is_visible_in_tree(): return "Completed native contact needs its actual visible available contact glyph"
	return ""


func request_contact_exit(exit_id: String, body: Node3D) -> bool:
	if not _running or _changing or beat_index != 5 or hero.dead or body != hero or exit_id != EXIT_ID or not _contact_error().is_empty() or not _exit_area.overlaps_body(body): return false
	return super.request_contact_exit(exit_id, body)


func _on_court_contact(body: Node3D) -> void:
	request_contact_exit(EXIT_ID, body)


func _apply_route_presentation() -> void:
	if not _running: return
	objective_text = OBJECTIVES[beat_index]
	greybox_clear = beat_index == 5
	if is_instance_valid(_exit_cue):
		if beat_index == 5: _exit_cue.present("available", "contact")
		else: _exit_cue.clear()
	if is_instance_valid(_scenery_art): _scenery_art.call("set_court_open", beat_index == 5)


func route_state() -> Dictionary:
	return {"beat_index": beat_index, "completed_beats": completed_beats.duplicate(), "room_stage": room_stage, "encounter_started": encounter_started, "sources": _render_sources.duplicate(true), "installed_fields": _fields.keys(), "installed_consumers": _consumers.keys(), "last_error": last_encounter_error, "save_supported": false}


func snapshot_state() -> Dictionary:
	if _native_route_snapshot_enabled(): return super.snapshot_state()
	last_snapshot_error = SAVE_REFUSAL
	return {}


func _local_snapshot_error(_state: Dictionary) -> String:
	return SAVE_REFUSAL


func _on_hero_died() -> void:
	super._on_hero_died()
	# Normal prototype exposes no fatal restore. Stop owned actor processing;
	# preserve genuine native motion/Route bytes until ordinary teardown releases.
	for id: String in _all_source_ids():
		if is_instance_valid(sources.get(id)): sources[id].set_physics_process(false)


func _on_exit_level() -> void:
	_running = false # Close owned admission before genuine release callbacks.
	_changing = true
	_activation_entitlement = ""
	for room_id: String in _consumers:
		var consumer := _consumers[room_id] as CinderSporeRepulsion
		if not is_instance_valid(consumer) or not consumer.is_inside_tree(): continue
		for id: String in ROOM_SOURCES[Layout.ROOM_IDS.find(room_id)]:
			if is_instance_valid(sources.get(id)): consumer.source_interrupted(sources[id], "actual_death" if sources[id].dead else "normal_route_exit")
	for field_id: String in _fields:
		var field := _fields[field_id] as CinderSporeField
		if not is_instance_valid(field): continue
		if field.state_changed.is_connected(_field_callbacks.get(field_id, Callable())): field.state_changed.disconnect(_field_callbacks[field_id])
		field.set_physics_process(false)
	super._on_exit_level()
