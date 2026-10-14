extends "res://scripts/acts/act1/mushroom_caverns.gd"
## SOURCE-ONLY COMPLETE O2 transport variant; unparsed/unexecuted.
## The original sealed functional260bd87b is unchanged. Actual Root review and
## directly affected native/campaign/portrait execution remain required.
## Reuses Base native actors/admission/approach and exact 14x72 static world.
## Whole native packets/validators/clocks/resources remain authoritative.

const Bloom = preload("res://scripts/acts/act1/spore_bloom_layout.gd")
const NativeProtocol = preload("res://scripts/environment/scheduler_spore_source_protocol.gd")
const NativeField = preload("res://scripts/environment/spore_field.gd")
const Repulsion = preload("res://scripts/environment/spore_repulsion.gd")
const SporeRoute = preload("res://scripts/combat/repulsion_route.gd")
const LowClusterArt = preload("res://scripts/acts/act1/mushroom_cluster_art.gd")
const InteractionCue = preload("res://scripts/cues/interaction_cue.gd")
const OBJECTIVES: Array[String] = [
	"FIRST BREATHING ROOM\nHIT A LOW CLUSTER OR KEEP ITS SUPPLY",
	"PAIRED MUSHROOMS\nFINITE SUPPLIES · KEEP AN ORDINARY OPENING",
	"FINAL MIXED CROWD\nCLEAR THE SWARM AND ONE SPEAR GUARD",
	"SPORE BLOOM CLEAR\nCROSS THE CONTACT EXIT",
]

const BloomCodec = preload("res://scripts/acts/act1/spore_bloom_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const ActorNativeCodec = preload("res://scripts/acts/act1/mushroom_selenite_codec.gd")
const NativeScheduler = preload("res://scripts/combat/threat_scheduler.gd")
const DifficultyData = preload("res://scripts/combat/difficulty.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const NativeMotion = preload("res://scripts/combat/lunge_motion.gd")
const NativeCueMesh = preload("res://scripts/cues/cue_mesh.gd")
const PROOF_KEYS: Array[String] = ["accepted", "path", "landing", "attack_position", "primary_time_s", "response_complete_s", "uses_blast", "uses_invulnerability", "proof_scope"]
const SEGMENT_KEYS: Array[String] = ["from", "to", "start_s", "end_s", "kind"]
const FRAME_KEYS: Array[String] = ["reservation_id", "landing", "attack_position", "primary_time_s", "response_complete_s", "action_escape"]
const ACCEPTED_FRAME_KEYS: Array[String] = ["reservation_id", "landing", "attack_position", "primary_time_s", "response_complete_s", "action_escape"]

var _constructor_open: bool = false
var _constructor_entitlements: Dictionary = {}
var _publication_open: bool = false
var _quiet_commit: bool = false
var _quiet_commit_error: String = ""
var _capture_error: String = ""
var _accepted_frames: Dictionary = {}
var _trusted_configurations: Dictionary = {}
var _retained_scheduler: CinderThreatScheduler
var _scheduler_script: Script
var _hero_script: Script
var _hero_sprite: Sprite3D
var _hero_shadow: MeshInstance3D
var _hero_shadow_mesh: Mesh
var _hero_shadow_material: Material
var _hero_sprite_transform: Transform3D
var _hero_shadow_transform: Transform3D
var _contact_cue: CinderInteractionCue
var _contact_marker: MeshInstance3D
var _contact_material: Material
var _contact_mesh: Mesh
var _cue_parts: Dictionary = {}

var beat_index: int = 0
var completed_beats: Array[String] = []
var room_stage: String = "approach"
var checkpoint_published: bool = false
var _publishing_progress: bool = false
var _contact_pending: bool = false
var _contact_transaction: bool = false
var _contact_phase: String = ""
var _fields: Dictionary = {}
var _consumers: Dictionary = {} # Actual consumer IDs, not group IDs.
var _protocols: Dictionary = {} # Actual consumer ID -> exact source protocol map.
var _cluster_art: Dictionary = {}
var _field_callbacks: Dictionary = {}
var _route_callbacks: Dictionary = {}
var _player_body: Dictionary = {}
var _exit_area: Area3D
var _exit_shape: CollisionShape3D
var _exit_resource: BoxShape3D
var _exit_cue: CinderInteractionCue


func _ready() -> void:
	enable_swarm_approach = true
	super._ready()
	if not _construction_error.is_empty(): return
	_build_contact()
	_retained_scheduler = scheduler
	_scheduler_script = scheduler.get_script() as Script
	_contact_cue = _exit_cue
	_contact_marker = _exit_cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
	if not is_instance_valid(_contact_marker):
		_construction_error = "Retain actual native contact marker"
		return
	_contact_material = _contact_marker.material_override
	_contact_mesh = _contact_marker.mesh
	for id: String in Bloom.SOURCE_IDS:
		var cue: CinderThreatCue = _retained_cues[id]
		var pins: Dictionary = {}
		for part_name: String in ["RequiredFootprintOutline", "RequiredFootprintFill", "RequiredSourceMarker"]:
			var part := cue.get_node_or_null(part_name) as MeshInstance3D
			if not is_instance_valid(part):
				_construction_error = "Retain every actual native threat-cue part"
				return
			var settings: Array = _cue_part_settings(part)
			if settings.is_empty():
				_construction_error = "Native cue material cannot carry script/next pass"
				return
			pins[part_name] = {"node": part, "material": part.material_override, "settings": settings, "transform": part.transform}
		_cue_parts[id] = pins
	native_admission_published.connect(_record_native_admission) # Before outside subscriptions.


func _component_configuration_error() -> String:
	return Bloom.definition_error() if initial_greybox_room == 0 else "O2 begins at its actual first entrance"


func _all_source_ids() -> Array[String]:
	return Bloom.all_source_ids()


func _source_spec(id: String) -> Dictionary:
	return Bloom.source_spec(id, true) # Familiar C31 approach; C32 stays stationary.


func current_source_ids() -> Array[String]:
	return Bloom.group_ids(beat_index)


func _encounter_id() -> String:
	return Bloom.epoch_id(beat_index)


func _initial_objective_text() -> String:
	return OBJECTIVES[0]


func _start_initial_encounter() -> void:
	# Base already bound all nine to one real Hero/Scheduler. Leave all dormant;
	# initial entry is an actual approach, not a fabricated gameplay epoch.
	_player_body = BodySweep.source_description(hero)
	if _player_body.has("error") or not _player_body.get("collision") is CollisionShape3D or not _player_body.collision.shape is CapsuleShape3D:
		_entry_failed("O2 requires actual shared Player capsule")
		return
	_player_body["parent"] = hero.get_parent()
	_player_body["shape"] = _player_body.collision.shape
	_player_body["transform"] = _player_body.collision.transform
	_player_body["radius"] = _player_body.collision.shape.radius
	_player_body["height"] = _player_body.collision.shape.height
	_apply_bloom_presentation()


func _refresh_render_state() -> void:
	for id: String in _all_source_ids():
		var actor := sources.get(id) as Act1MushroomSelenite
		if not is_instance_valid(actor) or actor != _retained_sources.get(id) or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.get_parent() != self:
			_render_sources[id] = {}
			_entry_failed("Retain actual O2 source: " + id)
			continue
		_render_sources[id] = actor.pure_presentation_state() # No legacy state() pruning.


func _physics_process(delta: float) -> void:
	if not _running or _changing or not is_instance_valid(hero): return
	_refresh_render_state()
	if not _running: return
	var error: String = _sync_clusters()
	if not error.is_empty():
		last_encounter_error = error
		return
	if hero.dead: return
	if room_stage == "hatch":
		if not _contact_transaction and (_contact_pending or _exit_area.overlaps_body(hero)):
			_contact_pending = false
			_settle_contact.call_deferred()
		return
	if room_stage == "approach":
		if beat_index > 0 or hero.global_position.z <= Bloom.FIRST_APPROACH_Z: _begin_group()
		return
	if room_stage != "active": return
	if _group_genuinely_clear():
		_advance_group()
		return
	super._physics_process(delta) # Unchanged native preview/proof/admission/approach.
	if _running: objective_text = OBJECTIVES[beat_index]


func _quiet_lifecycle_error() -> String:
	if not _running or _changing or get_tree().paused or _callback_depth != 0: return "Actual unpaused O2 boundary outside callbacks required"
	var error: String = _floor_error()
	if error.is_empty(): error = _scenery_error()
	if error.is_empty(): error = _spore_bindings_error()
	if not error.is_empty(): return error
	for id: String in _all_source_ids():
		var actor := sources.get(id) as Act1MushroomSelenite
		if not is_instance_valid(actor) or actor != _retained_sources.get(id): return "Retain every actual O2 recipient"
		var response: Dictionary = actor.get_spore_response_state()
		var control: Dictionary = scheduler.source_control_state(actor)
		if response.is_empty() or not response.outside_transaction or control.is_empty() or not control.outside_transaction or not control.reservations.is_empty(): return "All native source/Scheduler callbacks and leases must finish before a group boundary"
	for consumer: CinderSporeRepulsion in _consumers.values():
		if not consumer.snapshot_boundary_available(): return "Finish actual environmental callbacks before a group boundary"
	return ""


func _prospective_group_error() -> String:
	# Disabled dormant bodies cannot use BodySweep or Route.binding_state. Read
	# actual retained capsules without enabling them; this is overlap/spacing and
	# floor preflight, never a private motion/attack/retreat solver.
	var error: String = _quiet_lifecycle_error()
	if not error.is_empty(): return error
	var player: Dictionary = hero.get_threat_response_state()
	var dash: Dictionary = hero.get_committed_dash_state()
	if player.get("actor") != hero or not player.get("stable", false) or dash.get("active") != false or player.get("motion", {}).get("velocity") != Vector3.ZERO or player.motion.get("queued_dash") != Vector3.ZERO: return "A settled actual Hero is required before revealing the next group"
	var native: Dictionary = scheduler_bindings()
	for id: String in current_source_ids():
		var actor: Act1MushroomSelenite = sources[id]
		var state: Dictionary = actor.pure_presentation_state()
		if state.is_empty() or not state.dormant or state.dead or state.velocity != Vector3.ZERO or actor.global_position != Bloom.SOURCE_POINTS[id]: return "Next group must retain every genuine pristine dormant authored recipient"
		error = actor.body_binding_error()
		if error.is_empty(): error = actor.art_binding_error()
		if not error.is_empty(): return error
		var collision: CollisionShape3D = _retained_collisions[id]
		var capsule: CapsuleShape3D = _retained_capsules[id]
		var supported: bool = false
		var excluded: Array[RID] = []
		for floor_spec: Dictionary in native.floors.values():
			var floor_collision: CollisionShape3D = floor_spec.collision
			var top: float = floor_collision.global_position.y + (floor_collision.shape as BoxShape3D).size.y * .5
			var feet: float = collision.global_position.y - capsule.height * .5
			var safe: Rect2 = (floor_spec.safe_rect as Rect2).grow(-capsule.radius - SporeRoute.FLOOR_SKIN)
			if safe.has_point(Vector2(actor.global_position.x, actor.global_position.z)) and absf(feet - top) <= SporeRoute.FEET_TOLERANCE: supported = true
			excluded.append(floor_collision.get_parent().get_rid())
		if not supported: return "Prospective complete actual capsule lacks authored floor support"
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = collision.global_transform
		query.collision_mask = 1
		query.exclude = excluded
		query.collide_with_areas = false
		if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty(): return "Prospective actual dormant capsule overlaps native scenery"
		if _planar_segment_distance(actor.global_position, actor.global_position, hero.global_position, hero.global_position) < capsule.radius + float(_player_body.radius) + .12: return "Next group needs its actual Player capsule gap"
		for other_id: String in current_source_ids():
			if other_id == id: continue
			var other: Act1MushroomSelenite = sources[other_id]
			if _planar_segment_distance(actor.global_position, actor.global_position, other.global_position, other.global_position) < capsule.radius + (_retained_capsules[other_id] as CapsuleShape3D).radius + .12: return "Next group's full native capsules need distinct clear starting gaps"
	return _containment_error(_camera_framing_points())


func _begin_group() -> void:
	last_encounter_error = _prospective_group_error()
	if not last_encounter_error.is_empty(): return
	_changing = true
	scheduler.end_encounter("actual_spore_bloom_group_boundary")
	var profile: String = String(shared_shell.call("get_difficulty_preference")) if shared_shell.has_method("get_difficulty_preference") else "standard"
	if not scheduler.begin_encounter(profile, _encounter_id(), WORLD_REVISION):
		_changing = false
		_entry_failed(scheduler.last_error)
		return
	room_stage = "preparing_environment" # Never a serializable boundary.
	for id: String in current_source_ids():
		_activation_entitlement = id
		var accepted: bool = (sources[id] as Act1MushroomSelenite).activate()
		_activation_entitlement = ""
		if not accepted:
			_changing = false
			_entry_failed((sources[id] as Act1MushroomSelenite).last_error)
			return
	var error: String = _install_group_environment(beat_index)
	_changing = false
	if not error.is_empty():
		_entry_failed(error)
		return
	room_stage = "active"
	_refresh_render_state()
	_apply_bloom_presentation()
	last_encounter_error = _containment_error(_camera_framing_points())


func _activation_permitted(id: String) -> bool:
	return _running and _changing and room_stage == "preparing_environment" and _activation_entitlement == id and id in current_source_ids()


func _install_group_environment(index: int) -> String:
	# Native configuration supports only living enabled recipients; actual
	# activation or the supported fresh-candidate constructor precedes this call.
	var consumer_id: String = Bloom.consumer_id(index)
	if consumer_id.is_empty() or _consumers.has(consumer_id): return "Install each group's actual permanent consumer once"
	var native: Dictionary = scheduler_bindings()
	var environment: Dictionary = {"world_root": native.world_root, "floors": native.floors}
	var recipients: Dictionary = {}
	var protocols: Dictionary = {}
	for id: String in Bloom.group_ids(index):
		var actor: Act1MushroomSelenite = sources[id]
		var callback: Callable = Callable(self, "_native_spore_route_error").bind(id, consumer_id)
		_route_callbacks[id] = callback
		actor.spore_route_guard = callback
		actor.spore_route_guard_required = true
		var protocol := NativeProtocol.new()
		if not protocol.configure(actor, scheduler, hero, id, Bloom.CONTROLLER_ID, Bloom.PLAYER_ID, environment): return id + ": " + protocol.last_error
		protocols[id] = protocol
		recipients[id] = actor
	var fields: Dictionary = {}
	for id: String in Bloom.group_field_ids(index):
		if not _fields.has(id):
			var error: String = _install_field(id)
			if not error.is_empty(): return error
		fields[id] = _fields[id] # Same original supply/clock; no reconfigure/reset.
	var consumer := Repulsion.new()
	consumer.name = consumer_id.replace("-", "_")
	if not consumer.configure(consumer_id, Bloom.repulsion_directions()):
		var error: String = consumer.last_error
		consumer.free()
		return error
	add_child(consumer)
	# Retain before possible partial native commit so ordinary cleanup can release
	# its own exact subscriptions/routes even if bind_environment rejects.
	_consumers[consumer_id] = consumer
	_protocols[consumer_id] = protocols
	if not consumer.bind_environment({"world_root": native.world_root, "floors": native.floors, "fields": fields, "sources": recipients, "source_protocols": protocols}): return consumer.last_error
	var error: String = _sync_clusters()
	return error if not error.is_empty() else _spore_bindings_error()


func _install_field(id: String) -> String:
	if _fields.has(id): return "A persistent actual field can be constructed only once"
	var spec: Dictionary = Bloom.field_spec(id)
	if spec.is_empty(): return "Known frozen O2 field specification required"
	var field := NativeField.new()
	field.name = id.replace("-", "_")
	field.position = spec.position
	if not field.configure(id, spec.clusters, spec.parameters):
		var error: String = field.last_error
		field.free()
		return error
	add_child(field)
	_fields[id] = field
	var leaves: Dictionary = {}
	_cluster_art[id] = leaves
	for cluster_id: String in Bloom.CLUSTER_IDS:
		var cluster := field.get_node_or_null(cluster_id) as Node3D
		var leaf = LowClusterArt.new()
		leaf.name = "AuthoredLowCluster"
		if not leaf.configure(cluster, field):
			var error: String = leaf.last_error
			leaf.free()
			return error
		cluster.add_child(leaf)
		leaves[cluster_id] = leaf
	var callback: Callable = Callable(self, "_on_field_state").bind(id)
	_field_callbacks[id] = callback
	field.state_changed.connect(callback)
	return ""


func _cluster_handles_error() -> String:
	for id: String in _fields:
		var field := _fields[id] as CinderSporeField
		if id not in Bloom.FIELD_IDS or not is_instance_valid(field) or not field.is_inside_tree() or field.is_queued_for_deletion() or field.get_parent() != self or field.get_script() != NativeField or field.global_position != Bloom.FIELD_POINTS[id] or field.global_basis != Basis.IDENTITY: return "Retain installed native Field/script/origin"
		var error: String = field.binding_error()
		if not error.is_empty(): return error
		var leaves: Dictionary = _cluster_art.get(id, {})
		if not Codec.keys_error(leaves, Bloom.CLUSTER_IDS).is_empty(): return "Retain both true native cluster art leaves"
		for cluster_id: String in Bloom.CLUSTER_IDS:
			var leaf := leaves.get(cluster_id) as Node3D
			if not is_instance_valid(leaf) or not leaf.is_inside_tree() or leaf.is_queued_for_deletion() or leaf.get_script() != LowClusterArt or leaf.get_parent() != field.get_node_or_null(cluster_id): return "Retain exact native anchor/art handles"
	return ""


func _cluster_bindings_error() -> String:
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


func _on_field_state(_state: Dictionary, _field_id: String) -> void:
	if not _running or _changing: return
	var error: String = _sync_clusters()
	if error.is_empty(): error = _spore_bindings_error()
	if not error.is_empty(): last_encounter_error = error


func _spore_bindings_error() -> String:
	for consumer_id: String in _consumers:
		var index: int = Bloom.CONSUMER_IDS.find(consumer_id)
		if index < 0: return "Only frozen O2 consumers are permitted"
		var consumer := _consumers[consumer_id] as CinderSporeRepulsion
		if not is_instance_valid(consumer) or not consumer.is_inside_tree() or consumer.is_queued_for_deletion() or consumer.get_parent() != self or consumer.get_script() != Repulsion or consumer.consumer_id() != consumer_id: return "Retain actual permanent O2 coordinator"
		var protocols: Dictionary = _protocols.get(consumer_id, {})
		if not Codec.keys_error(protocols, Bloom.group_ids(index)).is_empty(): return "Retain every original group's native protocol"
		for id: String in Bloom.group_ids(index):
			var actor := sources.get(id) as Act1MushroomSelenite
			var protocol: Variant = protocols.get(id)
			if not is_instance_valid(actor) or actor != _retained_sources.get(id) or actor.get_parent() != self or actor.get_world_3d() != get_world_3d() or not is_instance_valid(protocol) or protocol.get_script() != NativeProtocol or not protocol.matches_source(actor, id) or not consumer.source_binding_matches(actor, id): return "Retain exact source/protocol/consumer aliases"
			if not actor.spore_route_guard_required or actor.spore_route_guard != _route_callbacks.get(id, Callable()): return "Retain exact original owned native Route guard"
			var descriptor: Dictionary = protocol.binding_state()
			if descriptor.get("controller_id") != Bloom.CONTROLLER_ID or descriptor.get("player_id") != Bloom.PLAYER_ID: return "Retain exact actual Scheduler/Player protocol IDs"
	return ""


func _admit(id: String, delta: float) -> void:
	if room_stage != "active": return
	var error: String = _spore_bindings_error()
	if error.is_empty(): error = _cluster_bindings_error()
	if not error.is_empty():
		last_encounter_error = error
		return
	super._admit(id, delta)


func _source_approach_error(plan: Dictionary, id: String) -> String:
	if room_stage != "active" or id not in current_source_ids(): return "Approach belongs only to actual current O2 group"
	var error: String = _spore_bindings_error()
	if error.is_empty(): error = _cluster_bindings_error()
	return error if not error.is_empty() else super._source_approach_error(plan, id)


func _source_presentation_error(id: String) -> String:
	var error: String = _spore_bindings_error()
	if error.is_empty(): error = _cluster_bindings_error()
	return error if not error.is_empty() else super._source_presentation_error(id)


func _neighbor_paths(id: String, delta: float) -> Dictionary:
	var result: Dictionary = super._neighbor_paths(id, delta)
	if not result.get("accepted", false): return result
	# Retain actual environmental endpoints, beyond Base lunge/hurt corridors.
	for consumer: CinderSporeRepulsion in _consumers.values():
		for other_id: String in _all_source_ids():
			if other_id == id: continue
			var other := sources.get(other_id) as Act1MushroomSelenite
			if not is_instance_valid(other) or other.dead or other.dormant or not consumer.source_binding_matches(other, other_id): continue
			var record: Dictionary = consumer.source_state(other_id)
			if not record.get("original_endpoint") is Vector3: continue
			if not record.original_endpoint.is_finite(): return {"accepted": false, "reason": "Retain finite actual neighboring retreat endpoint"}
			result.paths.append({"from": other.global_position, "to": record.original_endpoint, "radius": (_retained_capsules[other_id] as CapsuleShape3D).radius})
	return result


func _native_spore_route_error(proposal: Dictionary, id: String, consumer_id: String) -> String:
	# Scoped accepted Route guard pattern, parameterized by O2 identities. Native
	# coordinator prepared the actual endpoint before this pre-cancel/continue call.
	var error: String = _spore_bindings_error()
	if error.is_empty(): error = _cluster_bindings_error()
	if not error.is_empty(): return error
	var actor := sources.get(id) as Act1MushroomSelenite
	var consumer := _consumers.get(consumer_id) as CinderSporeRepulsion
	if not _running or _changing or get_tree().paused or hero.dead or room_stage != "active" or id not in current_source_ids() or not is_instance_valid(actor) or actor != _retained_sources.get(id) or not is_instance_valid(consumer) or not consumer.source_binding_matches(actor, id): return "Retain actual current source/group/consumer before environmental movement"
	if not Codec.keys_error(proposal, ["source_id", "consumer", "episode_id", "boundary", "direction"]).is_empty() or proposal.source_id != id or proposal.consumer != consumer or not proposal.episode_id is String or proposal.boundary not in ["cancel", "continue"] or not proposal.direction is Vector3 or not proposal.direction.is_finite(): return "Closed same-source environmental boundary required"
	error = actor.body_binding_error()
	if error.is_empty(): error = actor.art_binding_error()
	if error.is_empty(): error = _floor_error()
	if error.is_empty(): error = _scenery_error()
	if not error.is_empty(): return error
	var body: Dictionary = BodySweep.source_description(hero)
	if body.has("error") or hero.get_parent() != _player_body.parent or body.get("collision") != _player_body.collision or _player_body.collision.shape != _player_body.shape or _player_body.collision.transform != _player_body.transform or _player_body.shape.radius != _player_body.radius or _player_body.shape.height != _player_body.height: return "Retain exact actual Player body/capsule/world"
	var response: Dictionary = actor.get_spore_response_state()
	var record: Dictionary = consumer.source_state(id)
	var phase: String = "recoil" if proposal.boundary == "cancel" else "interrupted"
	if response.is_empty() or not response.alive or not response.grounded or not response.outside_transaction or record.get("episode_id") != proposal.episode_id or record.get("phase") != phase or not record.get("original_endpoint") is Vector3: return "Actual grounded same-episode prepared endpoint required"
	var start: Vector3 = actor.global_position
	var original: Vector3 = record.original_endpoint
	if not original.is_finite() or absf(original.y - start.y) > SporeRoute.ENDPOINT_TOLERANCE: return "Retain original supported native feet plane"
	var finish := Vector3(original.x, start.y, original.z)
	var motion: Vector3 = finish - start
	if motion.length() <= Repulsion.EPSILON or motion.length() > BodySweep.MAX_DISTANCE: return "Finite bounded whole environmental endpoint required"
	if proposal.boundary == "continue" and proposal.direction != motion.normalized(): return "Native continuation keeps the original endpoint bearing"
	var sweep: Dictionary = BodySweep.sweep(actor, Transform3D(Basis.IDENTITY, start), motion, scheduler_bindings().floors.values())
	if sweep.has("error") or sweep.get("collided", true) or not sweep.get("end") is Vector3 or sweep.end.distance_to(finish) > BodySweep.position_rounding_bound(start, finish): return "Native whole retreat capsule needs clear floor/scenery support"
	error = _source_path_gap_error(id, start, finish, 0.0)
	if not error.is_empty(): return error
	var player: Dictionary = hero.get_threat_response_state()
	var dash: Dictionary = hero.get_committed_dash_state()
	if not player.get("motion", {}).get("grounded", false) or dash.is_empty(): return "Actual grounded Player commitment required"
	var endpoint: Vector3 = hero.global_position
	if dash.get("active", false): endpoint = dash.origin + dash.direction * float(dash.distance)
	elif player.motion.velocity != Vector3.ZERO or player.motion.queued_dash != Vector3.ZERO: return "This guard cannot certify uncommitted Player hurt/queued motion"
	if _planar_segment_distance(start, finish, hero.global_position, endpoint) < (_retained_capsules[id] as CapsuleShape3D).radius + float(_player_body.radius) + .12: return "Whole native retreat needs complete Player/dash capsule gap"
	var points: Array = _camera_framing_points() + _actor_points(id, finish)
	var actual: Array = _actual_hero_points(hero.global_position)
	if actual.is_empty(): return "Complete actual Player presentation required"
	for point: Vector3 in actual: points.append(point + endpoint - hero.global_position)
	return _containment_error(_bounded_union(points))


func _actor_points(id: String, endpoint: Vector3) -> Array:
	# Base omits inherited-hidden dormant sprites. Prospective disclosure needs
	# their COMPLETE real existing quads before changing any lifecycle property.
	if not _billboard_camera_error(_actual_presentation_camera()).is_empty(): return [Vector3.INF]
	var points: Array = super._actor_points(id, endpoint)
	var actor := sources.get(id) as Act1MushroomSelenite
	if points.has(Vector3.INF) or not is_instance_valid(actor): return [Vector3.INF]
	if actor.dormant:
		var art: Node3D = actor.get_art()
		var found: bool = false
		for node: Node in art.find_children("*", "Sprite3D", true, false):
			var sprite := node as Sprite3D
			var quad: Array = shared_shell.call("camera_billboard_points", sprite)
			if quad.is_empty(): return [Vector3.INF]
			found = true
			points.append_array(quad)
			for point: Vector3 in quad: points.append(point + endpoint - actor.global_position)
		if not found: return [Vector3.INF]
	return points


func _camera_framing_points() -> Array:
	if not _running: return []
	if not _floor_error().is_empty() or not _scenery_error().is_empty() or not _spore_bindings_error().is_empty() or not _cluster_bindings_error().is_empty() or not _billboard_camera_error(_actual_presentation_camera()).is_empty(): return [Vector3.INF]
	var points: Array = _actual_hero_points(hero.global_position)
	if points.size() != 22: return [Vector3.INF]
	if _forecast_hint_current(): points.append_array(_forecast_points)
	for forecast: Array in _approach_forecasts.values(): points.append_array(forecast)
	for request: Array in _approach_camera_requests.values(): points.append_array(request)
	for id: String in current_source_ids():
		var actor := sources.get(id) as Act1MushroomSelenite
		if not is_instance_valid(actor) or actor != _retained_sources.get(id): return [Vector3.INF]
		var state: Dictionary = _render_sources.get(id, {})
		if state.is_empty(): return [Vector3.INF]
		if state.dead: continue
		if state.dormant:
			if room_stage == "approach": points.append_array(_actor_points(id, actor.global_position))
			continue
		if not actor.is_visible_in_tree(): return [Vector3.INF]
		points.append_array(_actor_points(id, state.opening_position))
		if state.geometry.get("kind") == "lane": points.append_array(_lane_points(state.geometry))
		points.append_array(_cue_points(id, state))
	for frame: Dictionary in _framing.values(): points.append_array(_response_points(frame.landing, frame.attack_position))
	var dash: Dictionary = hero.get_committed_dash_state()
	if dash.get("active", false): points.append_array(_actual_hero_points(dash.origin + dash.direction * float(dash.distance)))
	for field_id: String in _fields:
		var field: CinderSporeField = _fields[field_id]
		var origin: Vector3 = field.global_position
		for x: float in [-Bloom.FIELD_RADIUS, Bloom.FIELD_RADIUS]:
			for z: float in [-Bloom.FIELD_RADIUS, Bloom.FIELD_RADIUS]: points.append(origin + Vector3(x, .03, z))
		for leaf: Node3D in _cluster_art[field_id].values():
			var corners: Array = leaf.call("framing_points", shared_shell)
			if corners.is_empty(): return [Vector3.INF]
			points.append_array(corners)
		for id: String in current_source_ids():
			var actor: Act1MushroomSelenite = sources[id]
			if actor.dead or actor.dormant: continue
			var response: Dictionary = actor.get_spore_response_state()
			if response.is_empty(): return [Vector3.INF]
			var radius: float = Bloom.FIELD_RADIUS + float(response.support_radius) + float(Repulsion.DEFAULTS.exit_clearance) + .05
			for x: float in [-radius, radius]:
				for z: float in [-radius, radius]: points.append_array(_actor_points(id, Vector3(origin.x + x, actor.global_position.y, origin.z + z)))
	for consumer: CinderSporeRepulsion in _consumers.values():
		for id: String in current_source_ids():
			var record: Dictionary = consumer.source_state(id)
			if record.get("route", {}).get("planned_endpoint") is Vector3: points.append_array(_actor_points(id, record.route.planned_endpoint))
	if room_stage in ["hatch", "departed"]:
		if not _contact_error().is_empty(): return [Vector3.INF]
		points.append_array(_box_points(AABB(-_exit_resource.size * .5, _exit_resource.size), _exit_shape.global_transform))
		var marker := _exit_cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
		if not is_instance_valid(marker) or marker.mesh == null: return [Vector3.INF]
		points.append_array(_box_points(marker.get_aabb(), marker.global_transform))
	return _bounded_union(points)


func _bounded_union(points: Array) -> Array:
	# Accepted Route camera-basis enclosing convex box; all corners are retained.
	# No world AABB inflation, truncation, camera move or motion permission.
	if points.is_empty(): return []
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite(): return [Vector3.INF]
	var actual_camera: Camera3D = _actual_presentation_camera()
	if actual_camera == null: return [Vector3.INF]
	var basis: Basis = actual_camera.global_basis
	if not basis.is_finite() or absf(basis.determinant() - 1.0) > .00001: return [Vector3.INF]
	var inverse: Basis = basis.inverse()
	var bounds := AABB(inverse * points[0], Vector3.ZERO)
	for point: Vector3 in points: bounds = bounds.expand(inverse * point)
	return _box_points(bounds.grow(.0001), Transform3D(basis, Vector3.ZERO))


func _group_genuinely_clear() -> bool:
	if room_stage != "active" or hero.dead or not _spore_bindings_error().is_empty(): return false
	var consumer := _consumers.get(Bloom.consumer_id(beat_index)) as CinderSporeRepulsion
	if not is_instance_valid(consumer) or not consumer.snapshot_boundary_available(): return false
	for id: String in current_source_ids():
		if not (sources[id] as Act1MushroomSelenite).dead or not consumer.source_state(id).is_empty(): return false
	return not scheduler.has_committed_exchange()


func _advance_group() -> void:
	if not _group_genuinely_clear() or not _quiet_lifecycle_error().is_empty(): return
	_changing = true
	scheduler.end_encounter("actual_spore_bloom_required_cast_defeated")
	for id: String in current_source_ids():
		var control: Dictionary = scheduler.source_control_state(sources[id])
		if not control.get("outside_transaction", false) or not control.reservations.is_empty() or control.cooldown != null:
			_changing = false
			_entry_failed("Genuinely defeated group retained native readiness")
			return
	completed_beats.append(Bloom.BEAT_IDS[beat_index])
	beat_index += 1
	room_stage = "hatch" if beat_index == 3 else "approach"
	_framing.clear()
	_accepted_frames.clear()
	_clear_forecast_hint()
	_approach_forecasts.clear()
	_approach_camera_requests.clear()
	_changing = false
	_apply_bloom_presentation()
	if not _running or beat_index != 2: return
	_publication_open = true
	_publishing_progress = true
	var accepted: bool = request_checkpoint(Bloom.CHECKPOINT_ID, "encounter")
	_publishing_progress = false
	_publication_open = false
	if not accepted: _entry_failed("Actual sole pre-final checkpoint refused")


func request_checkpoint(checkpoint_id: String, boundary_kind: String = "encounter") -> bool:
	if not _publishing_progress or checkpoint_published or beat_index != 2 or room_stage != "approach" or completed_beats != Bloom.BEAT_IDS.slice(0, 2) or checkpoint_id != Bloom.CHECKPOINT_ID or boundary_kind != "encounter": return false
	_publishing_progress = false
	checkpoint_published = true # Before synchronous checkpoint observers capture.
	return super.request_checkpoint(checkpoint_id, boundary_kind)


func request_completion(completion_id: String = "complete") -> bool:
	if not _contact_transaction or _contact_phase != "completion" or beat_index != 3 or room_stage != "departed" or completed_beats != Bloom.BEAT_IDS or not checkpoint_published or completion_id != Bloom.COMPLETION_ID: return false
	_contact_phase = ""
	return super.request_completion(completion_id)


func _build_contact() -> void:
	_exit_area = Area3D.new()
	_exit_area.name = "ActualBloomExit"
	_exit_area.position = Bloom.EXIT
	_exit_area.collision_layer = 0
	_exit_area.collision_mask = 4
	_exit_shape = CollisionShape3D.new()
	_exit_shape.name = "ActualBloomExitShape"
	_exit_resource = BoxShape3D.new()
	_exit_resource.size = Vector3(1.6, 1.3, .9)
	_exit_shape.shape = _exit_resource
	_exit_area.add_child(_exit_shape)
	add_child(_exit_area)
	_exit_area.body_entered.connect(_on_exit_contact)
	_exit_cue = InteractionCue.new()
	_exit_cue.name = "ActualBloomContactCue"
	_exit_cue.position = Vector3(Bloom.EXIT.x, 0, Bloom.EXIT.z)
	add_child(_exit_cue)
	_exit_cue.clear()


func _contact_error() -> String:
	if not is_instance_valid(_exit_area) or not _exit_area.is_inside_tree() or _exit_area.is_queued_for_deletion() or _exit_area.get_parent() != self or _exit_area.position != Bloom.EXIT or _exit_area.basis != Basis.IDENTITY or _exit_area.collision_layer != 0 or _exit_area.collision_mask != 4 or not _exit_area.monitoring: return "Retain exact actual O2 contact Area"
	if not is_instance_valid(_exit_shape) or not _exit_shape.is_inside_tree() or _exit_shape.get_parent() != _exit_area or _exit_shape.shape != _exit_resource or _exit_shape.disabled or _exit_shape.transform != Transform3D.IDENTITY or _exit_resource.size != Vector3(1.6, 1.3, .9): return "Retain exact O2 contact box/resource"
	if not is_instance_valid(_exit_cue) or not _exit_cue.is_inside_tree() or _exit_cue.get_parent() != self or _exit_cue.position != Vector3(Bloom.EXIT.x, 0, Bloom.EXIT.z) or _exit_cue.basis != Basis.IDENTITY: return "Retain actual O2 contact cue"
	if room_stage in ["hatch", "departed"]:
		var state: Dictionary = _exit_cue.state()
		var marker := _exit_cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
		if state.get("state") != "available" or state.get("trigger") != "contact" or not is_instance_valid(marker) or marker.mesh == null or not marker.is_visible_in_tree(): return "Completed exit needs actual available contact glyph"
	return ""


func request_contact_exit(exit_id: String, body: Node3D) -> bool:
	if not _contact_transaction or _contact_phase != "exit" or not _running or _changing or room_stage != "departed" or beat_index != 3 or hero.dead or body != hero or exit_id != Bloom.EXIT_ID or not _contact_error().is_empty() or not _exit_area.overlaps_body(body): return false
	_contact_phase = "" # Consume before synchronous inherited observers.
	return super.request_contact_exit(exit_id, body)


func _on_exit_contact(body: Node3D) -> void:
	if _running and room_stage == "hatch" and body == hero: _contact_pending = true


func _settle_contact() -> void:
	if not _running or _changing or _contact_transaction or get_tree().paused or room_stage != "hatch" or hero.dead or not _exit_area.overlaps_body(hero): return
	if not _quiet_lifecycle_error().is_empty() or not _contact_error().is_empty() or not _containment_error(_camera_framing_points()).is_empty(): return
	# Both events come from the real settled contact, outside Area callbacks.
	# Refuse captures during this transaction until the sealed departure exists.
	_contact_transaction = true
	room_stage = "departed"
	_contact_phase = "completion"
	var accepted: bool = request_completion(Bloom.COMPLETION_ID)
	if accepted:
		_contact_phase = "exit"
		accepted = request_contact_exit(Bloom.EXIT_ID, hero)
	_contact_phase = ""
	if not accepted:
		_entry_failed("Genuine O2 settled contact completion/exit refused")
		return # Failed partial world remains refused, never silently rolled back.
	_contact_transaction = false
	_apply_bloom_presentation()


func _apply_bloom_presentation() -> void:
	if not _running: return
	var error: String = _contact_mesh_factory_error()
	if error.is_empty() and _contact_marker.mesh != _contact_mesh: error = "Retain prior exact native contact mesh"
	if not error.is_empty():
		_commit_failed("contact presentation", error)
		return
	var before: Dictionary = _exit_cue.state()
	var blocked: bool = _exit_cue.is_blocking_signals()
	if _quiet_commit: _exit_cue.set_block_signals(true)
	objective_text = OBJECTIVES[beat_index]
	greybox_clear = room_stage in ["hatch", "departed"]
	if greybox_clear: _exit_cue.present("available", "contact")
	else: _exit_cue.clear()
	if _quiet_commit: _exit_cue.set_block_signals(blocked)
	error = _contact_mesh_factory_error()
	if error.is_empty(): error = _contact_error()
	if not error.is_empty():
		_commit_failed("contact presentation", error)
		return
	if before.state != _exit_cue.state().state: _contact_mesh = _contact_marker.mesh
	elif _contact_marker.mesh != _contact_mesh: _commit_failed("contact presentation", "Idempotent native draw cannot legitimize replaced mesh")


func bloom_state() -> Dictionary:
	return {"beat_index": beat_index, "completed_beats": completed_beats.duplicate(), "room_stage": room_stage, "checkpoint_published": checkpoint_published, "sources": _render_sources.duplicate(true), "installed_fields": _fields.keys(), "installed_consumers": _consumers.keys(), "last_error": last_encounter_error, "save_supported": true}


func snapshot_state() -> Dictionary:
	var hud: GameHUD = null
	if is_instance_valid(shared_shell): hud = shared_shell.get("hud") as GameHUD
	return _snapshot_in_presentation(_actual_presentation_camera(), hud)


func snapshot_state_for_presentation(camera: Camera3D, hud: GameHUD) -> Dictionary:
	return _snapshot_in_presentation(camera, hud)


func _local_snapshot_error(local: Dictionary) -> String:
	return _native_state_error(local, hero.snapshot_state())


func _local_snapshot_error_with_player(local: Dictionary, saved_player: Dictionary) -> String:
	return _native_state_error(local, saved_player)


func _on_enter_restore_candidate(local: Dictionary, saved_player: Dictionary) -> String:
	if not is_restore_candidate() or not _fields.is_empty() or not _consumers.is_empty() or not _protocols.is_empty(): return "Fresh paused candidate without earlier installed topology required"
	_running = true
	for id: String in Bloom.SOURCE_IDS:
		var actor := sources.get(id) as Act1MushroomSelenite
		if not is_instance_valid(actor) or not actor.bind(scheduler, hero): return "Fresh recipient bind rejected: " + id
		var callback: Callable = Callable(self, "_on_source_state").bind(id)
		_source_callbacks[id] = callback
		actor.state_changed.connect(callback)
	if not hero.died.is_connected(_on_hero_died): hero.died.connect(_on_hero_died)
	if not hero.fired.is_connected(_on_hero_fired): hero.fired.connect(_on_hero_fired)
	_start_initial_encounter() # Only pins actual Player; no epoch/activation.
	if not _running: return _construction_error
	var error: String = _pin_transport_entry()
	if error.is_empty(): error = _pure_saved_preflight(local, saved_player)
	if not error.is_empty(): return error
	var plan: Dictionary = BloomCodec.construction_plan(local)
	if plan.get("accepted") != true: return String(plan.get("error", "O2 closed topology rejected"))
	_constructor_entitlements.clear()
	for id: String in plan.activated_source_ids:
		var index: int = Bloom.source_group(id)
		_constructor_entitlements[id] = {"api_revision": "act1-restore-recipient-construction-1", "source_id": id, "room_id": Bloom.group_id(index), "installed_rooms": plan.installed_groups.duplicate(), "installed_fields": plan.installed_fields.duplicate(), "configuration_sha256": Exact.stringify(_trusted_configurations[id]).sha256_text(), "authored_position": Codec.vector3(Bloom.SOURCE_POINTS[id])}
	_constructor_open = true
	for id: String in plan.activated_source_ids:
		var actor := sources.get(id) as Act1MushroomSelenite
		var descriptor: Dictionary = _constructor_entitlements[id].duplicate(true)
		var accepted: bool = actor.construct_restore_recipient(self, descriptor)
		_constructor_entitlements.erase(id) # Every attempt consumes, including failure.
		if not accepted:
			_constructor_open = false
			_constructor_entitlements.clear()
			return actor.last_error if is_instance_valid(actor) else "Dispose detached partial native candidate"
	_constructor_open = false
	_constructor_entitlements.clear()
	# Scheduler still pristine/unbegun. All installed recipients are genuinely
	# exposed by the native one-shot factory before any saved HP/death/stamp write.
	for group_id: String in plan.installed_groups:
		var index: int = Bloom.GROUP_IDS.find(group_id)
		error = _install_group_environment(index)
		if not error.is_empty(): return error
	_refresh_render_state()
	return _snapshot_runtime_error()


func _on_exit_level() -> void:
	_constructor_open = false
	_constructor_entitlements.clear()
	_publication_open = false
	_accepted_frames.clear()
	if native_admission_published.is_connected(_record_native_admission): native_admission_published.disconnect(_record_native_admission)
	_running = false
	_changing = true
	_activation_entitlement = ""
	_publishing_progress = false
	_contact_pending = false
	_contact_phase = ""
	for consumer_id: String in _consumers:
		var consumer := _consumers[consumer_id] as CinderSporeRepulsion
		var index: int = Bloom.CONSUMER_IDS.find(consumer_id)
		if not is_instance_valid(consumer) or not consumer.is_inside_tree() or index < 0: continue
		for id: String in Bloom.group_ids(index):
			var actor := sources.get(id) as Act1MushroomSelenite
			if is_instance_valid(actor): consumer.source_interrupted(actor, "actual_death" if actor.dead else "normal_spore_bloom_exit")
		var callback: Callable = Callable(consumer, "_on_activated")
		for field_id: String in Bloom.group_field_ids(index):
			var field := _fields.get(field_id) as CinderSporeField
			if is_instance_valid(field) and field.activated.is_connected(callback): field.activated.disconnect(callback)
	for field_id: String in _fields:
		var field := _fields[field_id] as CinderSporeField
		if not is_instance_valid(field): continue
		var callback: Callable = _field_callbacks.get(field_id, Callable())
		if field.state_changed.is_connected(callback): field.state_changed.disconnect(callback)
		field.set_physics_process(false)
	if is_instance_valid(_exit_area) and _exit_area.body_entered.is_connected(_on_exit_contact): _exit_area.body_entered.disconnect(_on_exit_contact)
	if is_instance_valid(_exit_cue) and _exit_cue.is_inside_tree(): _exit_cue.clear()
	super._on_exit_level()


func _native_route_snapshot_enabled() -> bool:
	return true



func restore_candidate_construction_required() -> bool:
	return true



func restore_candidate_physics_registration_required() -> bool:
	return true # Pure before tree entry; Base builds actual immutable floors in ready.



func _pin_transport_entry() -> String:
	if not is_instance_valid(hero) or hero.get_world_3d() != get_world_3d(): return "Retain actual same-world Hero"
	_hero_script = hero.get_script() as Script
	_hero_sprite = hero.get_node_or_null("ActorSprite") as Sprite3D
	_hero_shadow = hero.get_node_or_null("ContactShadow") as MeshInstance3D
	if not is_instance_valid(_hero_sprite) or not is_instance_valid(_hero_shadow) or _hero_shadow.mesh == null: return "Actual whole Hero billboard/shadow required"
	_hero_sprite_transform = _hero_sprite.transform
	_hero_shadow_transform = _hero_shadow.transform
	_hero_shadow_mesh = _hero_shadow.mesh
	_hero_shadow_material = _hero_shadow.material_override
	_trusted_configurations.clear()
	for id: String in Bloom.SOURCE_IDS:
		var actor := sources.get(id) as Act1MushroomSelenite
		if not is_instance_valid(actor) or actor != _retained_sources.get(id): return "Retain every native recipient before entry pins"
		var native: Dictionary = actor.get_spore_native_bindings()
		if native.is_empty() or native.source_id != id or native.scheduler != scheduler or native.player != hero: return "Retain actual immutable source/Player/Scheduler aliases"
		_trusted_configurations[id] = native.configuration.duplicate(true)
	return ""



func _on_enter_level() -> void:
	super._on_enter_level()
	if not _running: return
	var error: String = _pin_transport_entry()
	if not error.is_empty(): _entry_failed(error)



func restore_recipient_construction_error(source: Act1MushroomSelenite, descriptor: Dictionary) -> String:
	if not _constructor_open or not is_restore_candidate() or _callback_depth != 0 or _publication_open or _contact_transaction or not _quiet_commit_error.is_empty(): return "Owned exact constructor entitlement is closed"
	if not descriptor.get("source_id") is String: return "Stable entitled source required"
	var id: String = descriptor.source_id
	if not _constructor_entitlements.has(id) or sources.get(id) != source or _retained_sources.get(id) != source or not is_instance_valid(source) or source.get_script() != ActorScript or source.get_parent() != self or source.get_world_3d() != get_world_3d(): return "Same actual retained native recipient required"
	return "" if _same(descriptor, _constructor_entitlements[id]) else "Descriptor differs from exact unused copied entitlement"



func _pure_saved_preflight(local: Dictionary, saved_player: Dictionary) -> String:
	var error: String = BloomCodec.metadata_error(local)
	if not error.is_empty(): return error
	if Exact.stringify(saved_player).is_empty(): return "Whole exact saved Player transport required"
	error = hero.snapshot_error(saved_player)
	if error.is_empty(): error = _scheduler_structure_error(local.scheduler)
	if not error.is_empty(): return error
	var plan: Dictionary = BloomCodec.construction_plan(local)
	var current: Array[String] = []
	if local.room_stage == "active": current = Bloom.group_ids(local.beat_index)
	if local.room_stage == "active":
		if local.scheduler.encounter_id != Bloom.epoch_id(local.beat_index) or local.scheduler.world_revision != WORLD_REVISION or not local.scheduler.profile.get("id") is String: return "Current active O2 native epoch/world/profile required"
		var profile: Dictionary = DifficultyData.new().profile(local.scheduler.profile.id)
		if profile.is_empty() or not _same(profile, local.scheduler.profile): return "Retain exact canonical resolved native difficulty profile"
	else:
		if not local.scheduler.encounter_id.is_empty() or not local.scheduler.profile.is_empty() or not local.scheduler.reservations.is_empty() or not local.scheduler.cooldowns.is_empty(): return "Approach/hatch/departed retain actual idle native Scheduler"
		if local.scheduler.world_revision != (0 if local.beat_index == 0 else WORLD_REVISION): return "Retain untouched entrance or genuine completed epoch world revision"
		if local.beat_index == 0 and (local.scheduler.clock_s != 0.0 or local.scheduler.serial != 0): return "Unopened entrance cannot invent earlier native clock/serial"
	var decoder := ActorNativeCodec.new()
	for id: String in Bloom.SOURCE_IDS:
		if not _trusted_configurations.get(id) is Dictionary: return "Actual trusted native configuration required: " + id
		var configuration: Dictionary = _trusted_configurations[id]
		error = decoder.configuration_error(configuration)
		if not error.is_empty(): return id + ": " + error
		if configuration.source_id != id or configuration.entity_id != ("C32" if id == "bloom-final-guard" else "C31") or configuration.initially_dormant != true or configuration.approach.enabled != (id != "bloom-final-guard"): return "Retain frozen native O2 role/dormancy/approach identity"
		var actor: Dictionary = local.sources[id]
		error = decoder.context_error(actor, local.scheduler, saved_player, configuration)
		if not error.is_empty(): return id + ": " + error
		if not actor.hp is float or not is_finite(actor.hp): return "Native HP remains a literal finite float"
		var activated: bool = id in plan.activated_source_ids
		var index: int = Bloom.source_group(id)
		if actor.dormant == activated: return "Saved activation must match exactly the genuine installed prefix"
		if index < local.beat_index and not actor.dead: return "All preceding required sources must be genuinely defeated"
		if not activated and not _same(actor.motion.position, Codec.vector3(Bloom.SOURCE_POINTS[id])): return "Future pristine recipient moved from authored origin"
		if actor.cycle > 0 and actor.role_encounter_id != Bloom.epoch_id(index): return "Source historical epoch belongs to its original exercise"
		if actor.has("repulsion") != activated: return "Only genuinely installed sources carry permanent environmental stamps"
		if activated:
			error = decoder.repulsion_error(actor.repulsion, id, Bloom.consumer_id(index))
			if not error.is_empty(): return id + ": " + error
		if not actor.reservation_id.is_empty() and id not in current: return "Only current actual exercise can retain a native lease"
	for cooldown: Dictionary in local.scheduler.cooldowns:
		if cooldown.source_id not in current: return "Only current living native source can retain readiness"
		for lease: Dictionary in local.scheduler.reservations:
			if cooldown.source_id == lease.source_id and not _same(cooldown.ready_s, lease.cooldown_until_s): return "Retain exact copied owner readiness deadline"
	error = _exact_environment_transport_error(local)
	if error.is_empty(): error = _saved_environment_definition_error(local)
	if error.is_empty(): error = _framing_structure_error(local)
	return error



func _scheduler_structure_error(control: Dictionary) -> String:
	var keys: Array[String] = ["api_revision", "schema_version", "encounter_id", "profile", "world_revision", "clock_s", "serial", "collision", "reservations", "cooldowns"]
	if Exact.stringify(control).is_empty() or not Codec.keys_error(control, keys).is_empty() or control.api_revision != NativeScheduler.SNAPSHOT_API_REVISION or not control.schema_version is int or control.schema_version != 1 or not control.encounter_id is String or not control.profile is Dictionary or not control.world_revision is int or not Codec.is_integer(control.world_revision) or not control.clock_s is float or not Codec.in_range(control.clock_s, 0.0, 1000000000.0) or not control.serial is int or not Codec.is_integer(control.serial) or not control.collision is Dictionary or not control.reservations is Array or not control.cooldowns is Array: return "Whole ordinary native Scheduler schema1 required"
	var seen: Dictionary = {}
	for value: Variant in control.reservations:
		if not value is Dictionary or not value.get("source_id") is String or value.source_id not in Bloom.SOURCE_IDS or seen.has(value.source_id): return "Unique whole native source lease required"
		seen[value.source_id] = true
		for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
			if not value.get(key) is float or not is_finite(value[key]): return "Original native lease deadline remains a finite literal float"
	seen.clear()
	for value: Variant in control.cooldowns:
		if not value is Dictionary or not value.get("source_id") is String or value.source_id not in Bloom.SOURCE_IDS or seen.has(value.source_id) or not value.get("ready_s") is float or not is_finite(value.ready_s): return "Unique complete native owner readiness required"
		seen[value.source_id] = true
	return ""



func _exact_environment_transport_error(local: Dictionary) -> String:
	for id: String in Bloom.FIELD_IDS:
		var field: Variant = local.fields[id]
		if field == null: continue
		if not field.get("schema_version") is int or field.schema_version != 1 or not field.get("generation") is int or not field.get("clock_s") is float or not is_finite(field.clock_s): return "Whole exact native Field1 counters/clock required"
		for key: String in ["activation_s", "deadline_s"]:
			if field.get(key) != null and (not field[key] is float or not is_finite(field[key])): return "Native Field copied optional deadline type differs"
	for consumer_id: String in Bloom.CONSUMER_IDS:
		var consumer: Variant = local.consumers[consumer_id]
		if consumer == null: continue
		if not consumer.get("schema_version") is int or consumer.schema_version != 2 or not consumer.get("serial") is int or not consumer.get("records") is Dictionary or not consumer.get("source_environments") is Dictionary: return "Whole exact native Coordinator2 required"
		for id: String in consumer.records:
			var record: Variant = consumer.records[id]
			if not record is Dictionary or not record.get("route_revision") is int or not record.get("members") is Array or not _encoded_vector(record.get("direction")) or not _encoded_vector(record.get("original_endpoint")): return "Original native episode counter/vector/membership required"
			for key: String in ["age_s", "phase_age_s", "route_started_age_s", "progress"]:
				if not record.get(key) is float or not is_finite(record[key]): return "Original native episode clock/progress float required"
			for member: Variant in record.members:
				if not member is String: return "Original native field generation member ID required"
			if record.get("route") == null: continue
			var route: Variant = record.route
			if not route is Dictionary or not route.get("schema_version") is int or route.schema_version != 1 or not route.get("route") is Dictionary or not consumer.source_environments.get(id) is Dictionary: return "Whole original native Route1 envelope required"
			var motion: Dictionary = route.route
			for key: String in ["start", "planned_endpoint", "current_position", "current_velocity", "approach_velocity", "direction"]:
				if not _encoded_vector(motion.get(key)): return "Original exact native route vector required"
			for key: String in ["support_radius", "foot_offset", "speed", "distance", "duration_s", "elapsed_s"]:
				if not motion.get(key) is float or not is_finite(motion[key]): return "Original exact native route scalar/clock required"
			var environment: Dictionary = consumer.source_environments[id]
			for key: String in ["body_signature", "support_radius", "foot_offset"]:
				if not environment.has(key) or not _same(motion.get(key), environment[key]): return "Route retains immutable measured body bytes"
			for key: String in ["world_signature", "floor_signature"]:
				if not environment.has(key) or not _same(route.get(key), environment[key]): return "Route retains immutable world/floor bytes"
	return ""



func _saved_environment_definition_error(local: Dictionary) -> String:
	for id: String in Bloom.FIELD_IDS:
		if local.fields[id] == null: continue
		var spec: Dictionary = Bloom.field_spec(id)
		var anchors: Array = []
		for cluster: Dictionary in spec.clusters: anchors.append({"id": cluster.id, "offset": Codec.vector3(cluster.offset)})
		if not _same(local.fields[id].get("definition"), {"id": id, "parameters": spec.parameters, "clusters": anchors}) or not _same(local.fields[id].get("geometry"), {"origin": Codec.vector3(spec.position), "radius": spec.parameters.radius}): return "Native Field retains original authored definition/geometry"
	var directions: Array = []
	for direction: Vector3 in Bloom.repulsion_directions(): directions.append(Codec.vector3(direction))
	for id: String in Bloom.CONSUMER_IDS:
		if local.consumers[id] == null: continue
		if not _same(local.consumers[id].get("definition"), {"id": id, "directions": directions, "parameters": Repulsion.DEFAULTS.duplicate(true)}): return "Native Consumer retains original authored native definition"
	return ""



func _consumer_context(local: Dictionary, saved_player: Dictionary, consumer_id: String) -> Dictionary:
	var index: int = Bloom.CONSUMER_IDS.find(consumer_id)
	if index < 0: return {}
	var fields: Dictionary = {}
	var actors: Dictionary = {}
	for id: String in Bloom.group_field_ids(index): fields[id] = local.fields[id]
	for id: String in Bloom.group_ids(index): actors[id] = local.sources[id]
	return {"fields": fields, "sources": actors, "controllers": {Bloom.CONTROLLER_ID: local.scheduler}, "players": {Bloom.PLAYER_ID: saved_player}}



func _staged_scheduler_bindings(local: Dictionary, saved_player: Dictionary) -> Dictionary:
	var result: Dictionary = scheduler_bindings().duplicate(true)
	for key: String in ["owner_positions", "owner_velocities", "owner_collision_states"]: result[key] = {}
	for id: String in Bloom.SOURCE_IDS:
		var actor := sources.get(id) as Act1MushroomSelenite
		var staged: Dictionary = actor.staged_actor_bindings(local.sources[id])
		if staged.is_empty() or not Codec.keys_error(staged, ["owner_positions", "owner_velocities", "owner_collision_states"]).is_empty(): return {}
		for key: String in ["owner_positions", "owner_velocities", "owner_collision_states"]:
			if not staged[key] is Dictionary: return {}
			for owner_id: String in staged[key]:
				if owner_id != id or result[key].has(owner_id): return {}
				result[key][owner_id] = staged[key][owner_id]
		if not result.owner_positions.has(id) or not result.owner_velocities.has(id): return {}
	result["hero_positions"] = {Bloom.PLAYER_ID: Codec.read_vector3(saved_player.motion.position)}
	return result



func _native_state_error(local: Dictionary, saved_player: Dictionary) -> String:
	var error: String = _snapshot_runtime_error()
	if error.is_empty(): error = _pure_saved_preflight(local, saved_player)
	if not error.is_empty(): return error
	var plan: Dictionary = BloomCodec.construction_plan(local)
	if not Codec.keys_error(_fields, plan.installed_fields).is_empty() or not Codec.keys_error(_consumers, plan.installed_consumers).is_empty() or not Codec.keys_error(_protocols, plan.installed_consumers).is_empty(): return "Actual native installation must equal exact saved prefix"
	for id: String in Bloom.SOURCE_IDS:
		var actor: Act1MushroomSelenite = sources[id]
		error = actor.snapshot_error(local.sources[id], local.scheduler, saved_player)
		if not error.is_empty(): return id + ": " + error
	var current_control: Dictionary = scheduler.snapshot_state(scheduler_bindings())
	if current_control.is_empty() or not _same(current_control.collision, local.scheduler.collision): return "Saved static collision bytes differ from actual candidate world"
	for id: String in Bloom.SOURCE_IDS:
		if id in plan.activated_source_ids: continue
		var pristine: Dictionary = (sources[id] as Act1MushroomSelenite).capture_state(current_control)
		if pristine.is_empty() or not _same(pristine, local.sources[id]): return "Future source must retain actual whole pristine dormant packet: " + id
	var staged: Dictionary = _staged_scheduler_bindings(local, saved_player)
	if staged.is_empty(): return "All actual native owner and saved Hero staging maps required"
	error = scheduler.snapshot_error(local.scheduler, staged)
	if not error.is_empty(): return "Scheduler: " + error
	for id: String in plan.installed_fields:
		var field: CinderSporeField = _fields[id]
		var actual: Dictionary = field.snapshot_state()
		if actual.is_empty() or not _same(actual.definition, local.fields[id].get("definition")) or not _same(actual.geometry, local.fields[id].get("geometry")): return "Field's immutable actual native definition/geometry changed"
		error = field.snapshot_error(local.fields[id])
		if not error.is_empty(): return id + ": " + error
	for consumer_id: String in plan.installed_consumers:
		error = (_consumers[consumer_id] as CinderSporeRepulsion).snapshot_error(local.consumers[consumer_id], _consumer_context(local, saved_player, consumer_id))
		if not error.is_empty(): return consumer_id + ": " + error
	error = _saved_response_mechanical_error(local, saved_player)
	return error if not error.is_empty() else _snapshot_runtime_error()



func _capture_local_state() -> Dictionary:
	_capture_error = _snapshot_runtime_error()
	if not _capture_error.is_empty(): return {}
	var player: Dictionary = hero.snapshot_state()
	var control: Dictionary = scheduler.snapshot_state(scheduler_bindings())
	if player.is_empty() or control.is_empty():
		_capture_error = "Actual whole paused Player/Scheduler capture rejected"
		return {}
	var count: int = 3 if beat_index == 3 else beat_index + (1 if room_stage == "active" else 0)
	var activated: Array[String] = []
	var installed: Array[String] = []
	for index: int in range(count):
		activated.append_array(Bloom.group_ids(index))
		installed.append(Bloom.consumer_id(index))
	var local: Dictionary = {"api_revision": BloomCodec.API_REVISION, "schema_version": BloomCodec.SCHEMA_VERSION, "world_revision": WORLD_REVISION, "beat_index": beat_index, "room_stage": room_stage, "completed_beats": completed_beats.duplicate(), "activated_source_ids": activated, "installed_consumers": installed, "checkpoint_published": checkpoint_published, "sources": {}, "fields": {}, "consumers": {}, "scheduler": control, "framing": _accepted_frames.duplicate(true)}
	var pair: Dictionary = {"controllers": {Bloom.CONTROLLER_ID: control}, "players": {Bloom.PLAYER_ID: player}}
	for id: String in Bloom.SOURCE_IDS:
		var consumer_id: String = Bloom.consumer_id(Bloom.source_group(id))
		var protocols: Dictionary = _protocols.get(consumer_id, {})
		var protocol: Variant = protocols.get(id)
		local.sources[id] = protocol.current_unit(pair) if is_instance_valid(protocol) else (sources[id] as Act1MushroomSelenite).capture_state(control)
		if local.sources[id].is_empty():
			_capture_error = "Whole actual native source capture rejected: " + id
			return {}
	for id: String in Bloom.FIELD_IDS:
		local.fields[id] = (_fields[id] as CinderSporeField).snapshot_state() if _fields.has(id) else null
		if _fields.has(id) and local.fields[id].is_empty():
			_capture_error = "Whole actual native Field capture rejected: " + id
			return {}
	for id: String in Bloom.CONSUMER_IDS:
		local.consumers[id] = (_consumers[id] as CinderSporeRepulsion).snapshot_state(_consumer_context(local, player, id)) if _consumers.has(id) else null
		if _consumers.has(id) and local.consumers[id].is_empty():
			_capture_error = "Whole actual native Consumer capture rejected: " + id
			return {}
	_capture_error = _native_state_error(local, player)
	return local if _capture_error.is_empty() else {}



func _snapshot_in_presentation(camera: Camera3D, hud: GameHUD) -> Dictionary:
	if is_restore_candidate():
		last_snapshot_error = "Nonplayable candidate cannot supply live optical capture"
		return {}
	last_snapshot_error = _current_presentation_error(camera, hud)
	if not last_snapshot_error.is_empty(): return {}
	var snapshot: Dictionary = super.snapshot_state() # Base opt-in -> CinderLevel.
	if snapshot.is_empty():
		if not _capture_error.is_empty(): last_snapshot_error = _capture_error
		return {}
	last_snapshot_error = _whole_progress_error(snapshot, hero.snapshot_state())
	return snapshot if last_snapshot_error.is_empty() else {}



func snapshot_error(snapshot: Dictionary) -> String:
	var error: String = super.snapshot_error(snapshot)
	return error if not error.is_empty() else _whole_progress_error(snapshot, hero.snapshot_state())



func snapshot_error_with_player(snapshot: Dictionary, saved_player: Dictionary) -> String:
	var error: String = super.snapshot_error_with_player(snapshot, saved_player)
	return error if not error.is_empty() else _whole_progress_error(snapshot, saved_player)



func _whole_progress_error(snapshot: Dictionary, saved_player: Dictionary) -> String:
	if Exact.stringify(snapshot).is_empty() or not Codec.keys_error(snapshot, ["api_revision", "schema_version", "level_id", "scene_path", "local_snapshot_version", "progress", "local"]).is_empty() or not snapshot.get("schema_version") is int or not snapshot.get("local_snapshot_version") is int: return "Exact closed original CinderLevel envelope required"
	var error: String = BloomCodec.progress_error(snapshot)
	if not error.is_empty() or snapshot.local.room_stage != "departed": return error
	# Exact saved contact tests actual retained capsule/box geometry, not the
	# fresh candidate's pre-quiet overlap cache or a copied contact flag alone.
	var centre: Vector3 = Codec.read_vector3(saved_player.motion.position) + _player_body.collision.position
	var capsule: CapsuleShape3D = _player_body.shape
	var box := AABB(_exit_shape.global_position - _exit_resource.size * .5, _exit_resource.size)
	var half_line: float = capsule.height * .5 - capsule.radius
	var nearest := Vector3(clampf(centre.x, box.position.x, box.end.x), clampf(centre.y, box.position.y - half_line, box.end.y + half_line), clampf(centre.z, box.position.z, box.end.z))
	return "" if centre.distance_squared_to(nearest) <= capsule.radius * capsule.radius else "Saved departed contact lies outside actual capsule/box domain"



func restore_state(snapshot: Dictionary) -> bool:
	if not _quiet_commit_error.is_empty():
		last_snapshot_error = "Dispose failed native candidate: " + _quiet_commit_error
		return false
	last_snapshot_error = snapshot_error(snapshot)
	if not last_snapshot_error.is_empty(): return false
	var accepted: bool = super.restore_state(snapshot)
	if not _quiet_commit_error.is_empty():
		last_snapshot_error = _quiet_commit_error
		return false
	return accepted



func finish_restore_candidate() -> bool:
	return false if not _quiet_commit_error.is_empty() or _quiet_commit or _constructor_open or _publication_open or _contact_transaction else super.finish_restore_candidate()



func _restore_local_state(local: Dictionary) -> void:
	_quiet_commit = true
	var player: Dictionary = hero.snapshot_state() # Shell committed original Player first.
	_quiet_commit_error = _native_state_error(local, player)
	if not _quiet_commit_error.is_empty():
		_quiet_commit = false
		_freeze_failed_candidate()
		return
	var staged: Dictionary = _staged_scheduler_bindings(local, player)
	var plan: Dictionary = BloomCodec.construction_plan(local)
	for id: String in plan.installed_fields:
		if not (_fields[id] as CinderSporeField).restore_state(local.fields[id]):
			_commit_failed("Field " + id, _fields[id].last_snapshot_error)
			return
	for id: String in Bloom.SOURCE_IDS:
		if not (sources[id] as Act1MushroomSelenite).restore_actor_state(local.sources[id]):
			_commit_failed("Actor physical " + id, sources[id].last_snapshot_error)
			return
	if not scheduler.restore_state(local.scheduler, staged):
		_commit_failed("Scheduler", scheduler.last_snapshot_error)
		return
	for id: String in Bloom.SOURCE_IDS:
		if not (sources[id] as Act1MushroomSelenite).restore_exchange_state(local.sources[id]):
			_commit_failed("Actor exchange " + id, sources[id].last_snapshot_error)
			return
	for id: String in plan.installed_consumers:
		if not (_consumers[id] as CinderSporeRepulsion).restore_state(local.consumers[id], _consumer_context(local, player, id)):
			_commit_failed("Consumer " + id, _consumers[id].last_error)
			return
	beat_index = local.beat_index
	room_stage = local.room_stage
	completed_beats.assign(local.completed_beats)
	checkpoint_published = local.checkpoint_published
	_contact_pending = false
	_contact_phase = ""
	_accepted_frames = local.framing.duplicate(true)
	_framing.clear()
	for id: String in local.framing:
		var frame: Dictionary = local.framing[id].duplicate(true)
		frame.landing = Codec.read_vector3(frame.landing)
		frame.attack_position = Codec.read_vector3(frame.attack_position)
		_framing[id] = frame
	_clear_forecast_hint()
	_approach_forecasts.clear()
	_approach_camera_requests.clear()
	last_admission.clear()
	_refresh_render_state()
	_quiet_commit_error = _sync_clusters()
	if _quiet_commit_error.is_empty(): _apply_bloom_presentation()
	if _quiet_commit_error.is_empty(): _quiet_commit_error = _snapshot_runtime_error()
	_quiet_commit = false
	if not _quiet_commit_error.is_empty(): _freeze_failed_candidate()



func _commit_failed(unit: String, error: String) -> void:
	_quiet_commit_error = "Dispose unexpected partial native commit: " + unit + ": " + error
	_quiet_commit = false
	_freeze_failed_candidate()



func _freeze_failed_candidate() -> void:
	_running = false
	_clear_forecast_hint()
	for actor: Act1MushroomSelenite in sources.values():
		if is_instance_valid(actor): actor.set_physics_process(false)
	for field: CinderSporeField in _fields.values():
		if is_instance_valid(field): field.set_physics_process(false)
	if is_instance_valid(scheduler): scheduler.set_physics_process(false)
	set_physics_process(false)



func _snapshot_runtime_error() -> String:
	if not _running or _changing or _callback_depth != 0 or _constructor_open or not _constructor_entitlements.is_empty() or not _activation_entitlement.is_empty() or _publication_open or _contact_transaction or not _contact_phase.is_empty() or _publishing_progress or not get_tree().paused or not _quiet_commit_error.is_empty() or room_stage == "preparing_environment": return "Actual paused native boundary outside construction/publication/callbacks required"
	if global_basis != Basis.IDENTITY or global_position != Vector3.ZERO or not _floor_error().is_empty() or not _scenery_error().is_empty(): return "Retain original actual floor/scenery/world frame"
	if not is_instance_valid(scheduler) or scheduler != _retained_scheduler or scheduler.get_script() != _scheduler_script or scheduler.get_parent() != self or get_node_or_null("MushroomThreatScheduler") != scheduler or not scheduler.is_inside_tree() or scheduler.is_queued_for_deletion(): return "Retain single actual native Scheduler"
	if not is_instance_valid(hero) or hero.get_script() != _hero_script or not hero.is_inside_tree() or hero.is_queued_for_deletion() or hero.get_world_3d() != get_world_3d() or _world_root() == null: return "Retain actual same-world Hero"
	var body: Dictionary = BodySweep.source_description(hero)
	if body.has("error") or _player_body.is_empty() or body.get("collision") != _player_body.collision or hero.get_parent() != _player_body.parent or _player_body.collision.shape != _player_body.shape or _player_body.collision.transform != _player_body.transform or _player_body.shape.radius != _player_body.radius or _player_body.shape.height != _player_body.height: return "Retain actual whole Player capsule/settings"
	if hero.get_node_or_null("ActorSprite") != _hero_sprite or hero.get_node_or_null("ContactShadow") != _hero_shadow or not is_instance_valid(_hero_sprite) or not _hero_sprite.is_visible_in_tree() or _hero_sprite.transform != _hero_sprite_transform or not is_instance_valid(_hero_shadow) or not _hero_shadow.is_visible_in_tree() or _hero_shadow.mesh != _hero_shadow_mesh or _hero_shadow.material_override != _hero_shadow_material or _hero_shadow.transform != _hero_shadow_transform: return "Retain actual Hero billboard/contact-shadow resources"
	if not Codec.keys_error(sources, Bloom.SOURCE_IDS).is_empty() or not Codec.keys_error(_retained_sources, Bloom.SOURCE_IDS).is_empty() or not Codec.keys_error(_trusted_configurations, Bloom.SOURCE_IDS).is_empty(): return "Retain exact nine-source native configuration map"
	for id: String in Bloom.SOURCE_IDS:
		var actor := sources.get(id) as Act1MushroomSelenite
		if not is_instance_valid(actor) or actor != _retained_sources.get(id) or actor.get_script() != ActorScript or actor.get_parent() != self or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.get_world_3d() != get_world_3d(): return "Retain exact actual native source: " + id
		var native: Dictionary = actor.get_spore_native_bindings()
		if native.is_empty() or native.scheduler != scheduler or native.player != hero or not _same(native.configuration, _trusted_configurations[id]): return "Retain immutable actual native source aliases/configuration"
		var error: String = actor.body_binding_error()
		if error.is_empty(): error = actor.art_binding_error()
		if error.is_empty(): error = _native_cue_resources_error(id)
		if not error.is_empty(): return id + ": " + error
		if actor.get_node_or_null("BodyCollision") != _retained_collisions[id] or _retained_collisions[id].shape != _retained_capsules[id] or actor.get_cue() != _retained_cues[id]: return "Retain exact actual source body/cue resources"
		var callback: Callable = Callable(self, "_on_source_state").bind(id)
		if _source_callbacks.get(id) != callback or not actor.state_changed.is_connected(callback) or actor.activation_guard != Callable(self, "_activation_permitted") or actor.presentation_guard != Callable(self, "_source_presentation_error").bind(id) or actor.approach_guard != Callable(self, "_source_approach_error").bind(id): return "Retain exact owned source observers/guards"
	if not native_admission_published.is_connected(_record_native_admission) or not hero.died.is_connected(_on_hero_died) or not hero.fired.is_connected(_on_hero_fired): return "Retain exact native proof/Hero lifecycle observers"
	if not Codec.keys_error(_field_callbacks, _fields.keys()).is_empty() or not Codec.keys_error(_cluster_art, _fields.keys()).is_empty() or not Codec.keys_error(_protocols, _consumers.keys()).is_empty(): return "Retain exact installed callback/art/protocol maps"
	for id: String in _fields:
		var callback: Callable = Callable(self, "_on_field_state").bind(id)
		if _field_callbacks[id] != callback or not _fields[id].state_changed.is_connected(callback): return "Retain exact original Field state observer"
	var error: String = _spore_bindings_error()
	if error.is_empty(): error = _cluster_bindings_error()
	if error.is_empty(): error = _quiet_contact_resources_error()
	return error



func _actual_presentation_camera() -> Camera3D:
	if not is_inside_tree(): return null
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(camera) or camera.get_script() != null or not camera.is_inside_tree() or not camera.is_node_ready() or camera.is_queued_for_deletion() or camera.get_viewport() != get_viewport() or camera.get_world_3d() != get_world_3d(): return null
	return camera



func _billboard_camera_error(camera: Camera3D) -> String:
	if camera == null or camera != _actual_presentation_camera() or not is_instance_valid(shared_shell): return "Actual current same-world native camera required"
	var reference: Variant = shared_shell.get("camera")
	if not is_instance_valid(reference) or not reference is Camera3D or reference.get_script() != null or not reference.is_inside_tree() or reference.is_queued_for_deletion() or camera.global_basis != reference.global_basis: return "Actual candidate keeps exact shared fixed billboard BASIS only"
	return "" # Position/focus/Player/HUD always come from actual supplied context.



func _current_presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	var error: String = _snapshot_runtime_error()
	if error.is_empty(): error = _billboard_camera_error(camera)
	if error.is_empty(): error = _current_framing_history_error()
	if not error.is_empty(): return error
	if not is_instance_valid(hud): return "Actual canonical laid-out HUD required"
	var points: Array = _camera_framing_points()
	if _actual_hero_points(hero.global_position).size() != 22 or points.is_empty() or points.size() > 224 or points.has(Vector3.INF): return "Actual complete Hero/source/cue/field/response union required"
	return String(shared_shell.call("camera_framing_error_for_context", points, hero, camera, hud))



func _restore_candidate_presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	if _quiet_commit or _constructor_open or _publication_open or not _quiet_commit_error.is_empty(): return "Dispose failed or incomplete quiet candidate"
	return _current_presentation_error(camera, hud)



func _actual_hero_points(endpoint: Vector3) -> Array:
	var camera: Camera3D = _actual_presentation_camera()
	if not endpoint.is_finite() or camera == null or not is_instance_valid(hero) or not is_instance_valid(shared_shell): return []
	var actual: Variant = shared_shell.call("player_camera_framing_points_for", hero, camera)
	if not actual is Array or actual.size() != 22: return []
	var points: Array = []
	for point: Variant in actual:
		if not point is Vector3 or not point.is_finite(): return []
		points.append(point + endpoint - hero.global_position)
	return points



func _response_points(landing: Vector3, attack: Vector3) -> Array:
	var actual: Array = _actual_hero_points(hero.global_position)
	if actual.size() != 22: return [Vector3.INF]
	var points: Array = []
	for point: Vector3 in actual:
		points.append(point + landing - hero.global_position)
		points.append(point + attack - hero.global_position)
	return points



func _containment_error(points: Array) -> String:
	if points.is_empty() or points.size() > 224 or not is_instance_valid(shared_shell): return "Complete bounded actual presentation required"
	return String(shared_shell.call("camera_framing_error_for_player", points, hero, _actual_presentation_camera()))



func _framing_ready(points: Array, optional_owner: String = "") -> bool:
	if points.is_empty() or points.size() > 224 or not is_instance_valid(shared_shell): return false
	var plan: Dictionary = shared_shell.call("camera_framing_plan_for_player", points, hero.global_position + Vector3(0, .65, 0), hero, _actual_presentation_camera())
	if plan.get("accepted") != true and not optional_owner.is_empty(): _clear_forecast_hint(optional_owner)
	last_encounter_error = String(plan.get("reason", "")) if plan.get("accepted") != true else _containment_error(points)
	return plan.get("accepted") == true and last_encounter_error.is_empty()



func _encoded_vector(value: Variant) -> bool:
	return Codec.is_vector3(value) and _same(value, Codec.vector3(Codec.read_vector3(value)))



func _same(left: Variant, right: Variant) -> bool:
	var text: String = Exact.stringify(left)
	return not text.is_empty() and text == Exact.stringify(right)



func _record_native_admission(id: String, answer: Dictionary) -> void:
	if answer.get("accepted") != true: return
	# Earlier publication listeners may synchronously cancel, pause, defeat or
	# detach a source. Validate current native custody before storing its proof.
	var custody_error: String = _admission_custody_error(id, answer)
	if not custody_error.is_empty():
		_reject_corresponding_admission(id, answer, custody_error)
		return
	var current: Variant = _framing.get(id)
	if not current is Dictionary or current.get("reservation_id") != answer.get("reservation_id") or not answer.get("proof") is Dictionary:
		_reject_corresponding_admission(id, answer, "Actual native response must still name its returned lease")
		return
	var proof: Dictionary = _encode_native_proof(answer.proof)
	if proof.is_empty():
		_reject_corresponding_admission(id, answer, "Actual accepted native proof cannot be retained exactly")
		return
	var frame: Dictionary = {"reservation_id": String(answer.reservation_id), "landing": proof.landing.duplicate(), "attack_position": proof.attack_position.duplicate(), "primary_time_s": proof.primary_time_s, "response_complete_s": proof.response_complete_s, "action_escape": proof}
	_accepted_frames[id] = frame
	_framing[id]["primary_time_s"] = frame.primary_time_s
	_framing[id]["response_complete_s"] = frame.response_complete_s
	_framing[id]["action_escape"] = answer.proof.duplicate(true)



func _encode_native_proof(proof: Dictionary) -> Dictionary:
	if not Codec.keys_error(proof, PROOF_KEYS).is_empty() or proof.get("accepted") != true or proof.get("uses_blast") != false or proof.get("uses_invulnerability") != false or proof.get("proof_scope") != "static_box_floor_full_dash_stationary_primary" or not proof.get("path") is Array or not proof.get("landing") is Vector3 or not proof.get("attack_position") is Vector3: return {}
	var encoded: Dictionary = proof.duplicate(true)
	encoded["landing"] = Codec.vector3(proof.landing)
	encoded["attack_position"] = Codec.vector3(proof.attack_position)
	encoded["path"] = []
	for segment: Variant in proof.path:
		if not segment is Dictionary or not Codec.keys_error(segment, SEGMENT_KEYS).is_empty() or not segment.get("from") is Vector3 or not segment.get("to") is Vector3: return {}
		var value: Dictionary = segment.duplicate(true)
		value["from"] = Codec.vector3(segment["from"])
		value["to"] = Codec.vector3(segment["to"])
		encoded.path.append(value)
	return encoded if not Exact.stringify(encoded).is_empty() else {}



func _on_source_state(state: Dictionary, id: String) -> void:
	super._on_source_state(state, id)
	if state.reservation_id.is_empty() or state.dead or (_accepted_frames.has(id) and _accepted_frames[id].reservation_id != state.reservation_id): _accepted_frames.erase(id)



func _current_framing_history_error() -> String:
	# Actual render anchors must agree with the original six-field native receipt.
	# The codec separately checks complete leases, proof paths and exact context.
	if not Codec.keys_error(_framing, _accepted_frames.keys()).is_empty(): return "Current response anchors must retain exact accepted history membership"
	for id: String in _accepted_frames:
		var raw: Variant = _framing[id]
		var original: Variant = _accepted_frames[id]
		if not raw is Dictionary or not original is Dictionary or not Codec.keys_error(raw, ACCEPTED_FRAME_KEYS).is_empty() or not Codec.keys_error(original, ACCEPTED_FRAME_KEYS).is_empty() or not Codec.value_error(original).is_empty(): return "Complete current accepted response anchor required"
		if not raw.landing is Vector3 or not raw.landing.is_finite() or not raw.attack_position is Vector3 or not raw.attack_position.is_finite() or not Codec.is_vector3(original.landing) or not Codec.is_vector3(original.attack_position) or not raw.primary_time_s is float or not raw.response_complete_s is float or not is_finite(raw.primary_time_s) or not is_finite(raw.response_complete_s): return "Exact finite current accepted response types required"
		if not raw.action_escape is Dictionary: return "Complete current native action proof required"
		# Genuine live receipt holds native Vector3; quiet-restored render cache
		# holds exact encoded arrays. Normalize only a detached comparison value.
		var current_proof: Dictionary = _encode_native_proof(raw.action_escape) if raw.action_escape.get("landing") is Vector3 else raw.action_escape.duplicate(true)
		if current_proof.is_empty() or raw.reservation_id != original.reservation_id or raw.landing != Codec.read_vector3(original.landing) or raw.attack_position != Codec.read_vector3(original.attack_position) or raw.primary_time_s != original.primary_time_s or raw.response_complete_s != original.response_complete_s or not _same(current_proof, original.action_escape): return "Current response anchors differ from the genuine accepted native history"
		var shown: Variant = _render_sources.get(id)
		if not shown is Dictionary or shown.get("reservation_id") != original.reservation_id: return "Actual current source must retain the same accepted native lease"
	return ""



func _saved_response_mechanical_error(state: Dictionary, saved_player: Dictionary) -> String:
	var environment_error: String = _saved_environment_definition_error(state)
	if not environment_error.is_empty(): return environment_error
	if not _same(hero.equipment.snapshot(), saved_player.equipment): return "Actual candidate equipment must match the supplied saved Player before mechanical response proof"
	var stats: Dictionary = hero.equipment.resolved_stats() # Actual candidate loadout, separately native-validated.
	var decoded: Array[Dictionary] = []
	for raw: Dictionary in state.scheduler.reservations:
		var shape: Dictionary = _decode_shape(raw.geometry)
		var error: String = Geometry.error(shape)
		if not error.is_empty(): return error
		decoded.append({"record": raw, "shape": shape})
	for item: Dictionary in decoded:
		var record: Dictionary = item.record
		var proof: Dictionary = state.framing[record.source_id].action_escape
		var path: Array[Dictionary] = []
		for segment: Dictionary in proof.path:
			path.append({"from": Codec.read_vector3(segment["from"]), "to": Codec.read_vector3(segment["to"]), "start_s": segment.start_s, "end_s": segment.end_s, "kind": segment.kind})
		for segment: Dictionary in path:
			var motion: Vector3 = segment["to"] - segment["from"]
			if segment.kind in ["escape_dash", "positioning_dash"]:
				var precision: float = BodySweep.position_rounding_bound(segment["from"], segment["to"])
				if absf(motion.y) > BodySweep.EPSILON or absf(motion.length() - float(stats.dash_distance)) > precision or not is_equal_approx(float(segment.end_s) - float(segment.start_s), float(stats.dash_duration)): return "Accepted response retains its actual full native dash distance/duration"
			elif motion != Vector3.ZERO: return "Accepted stationary response segment moved"
			var swept: Dictionary = BodySweep.sweep(hero, Transform3D(Basis.IDENTITY, segment["from"]), motion, scheduler_bindings().floors.values())
			if swept.has("error") or swept.get("collided", true) or not swept.get("end") is Vector3 or swept.end.distance_to(segment["to"]) > BodySweep.position_rounding_bound(segment["from"], segment["to"]): return "Saved ordinary response lacks actual full capsule static-floor/scenery support"
		for threat: Dictionary in decoded:
			if Geometry.timed_path_hits(threat.shape, path, float(threat.record.active_from_s), float(threat.record.active_until_s), float(_player_body.radius) + CinderThreatScheduler.SKIN): return "Saved original ordinary response intersects the committed native threat union"
		var opening: Vector3 = Codec.read_vector3(record.opening_position)
		var attack: Vector3 = Codec.read_vector3(proof.attack_position)
		var adapter: Dictionary = record.get("adapter", {})
		var endpoint_reserve: float = NativeMotion.ENDPOINT_TOLERANCE if adapter.get("kind") == "lunge" and not adapter.get("finished", false) else 0.0
		if Vector2(opening.x - attack.x, opening.z - attack.z).length() > float(stats.primary_range) - endpoint_reserve - CinderThreatScheduler.SKIN or absf(opening.y - attack.y) > 1.4: return "Saved ordinary primary cannot reach actual stopped native source"
		var ray := PhysicsRayQueryParameters3D.create(attack + Vector3.UP * .7, opening + Vector3.UP * .7, 1)
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return "Actual static scenery blocks the saved ordinary-primary opening"
		if float(proof.response_complete_s) < float(proof.primary_time_s) + float(stats.primary_cooldown): return "Saved ordinary response truncates the actual primary recovery"
	return "" # Pure mechanical proof; Shared34 checks actual optics after quiet commit.



func _cue_part_settings(part: MeshInstance3D) -> Array:
	var material := part.material_override as StandardMaterial3D
	if material == null or material.get_script() != null or material.next_pass != null: return []
	# Native phase owns color/visibility/mesh. Fixed required depth and renderer
	# settings remain the actual ready readbacks, never repaired during capture.
	return [part.get_script(), part.layers, part.cast_shadow, part.material_overlay, part.transparency, part.extra_cull_margin, part.visibility_range_begin, part.visibility_range_end, part.visibility_range_fade_mode, part.ignore_occlusion_culling, material.shading_mode, material.transparency, material.cull_mode, material.texture_filter, material.no_depth_test, material.albedo_texture]



func _native_cue_resources_error(id: String) -> String:
	var retained: Variant = _retained_cues.get(id)
	if not is_instance_valid(retained) or not retained is CinderThreatCue: return "Retain actual required native cue before typed validation: " + id
	var cue: CinderThreatCue = retained
	if not cue.is_inside_tree() or cue.is_queued_for_deletion() or cue.get_parent() != sources.get(id) or cue.get_script() != CinderThreatCue or not cue.is_in_group("required_cues") or not cue.is_set_as_top_level() or not cue.visible: return "Retain actual required native threat cue: " + id
	var shown: Dictionary = cue.state() # Pure logical read; no prune/presentation.
	if cue.global_basis != Basis.IDENTITY: return "Retain the native identity threat-cue world basis: " + id
	if shown.phase != "clear":
		if not Geometry.error(shown.geometry).is_empty() or cue.global_position != NativeCueMesh.anchor(shown.geometry): return "Actual threat cue moved from its native logical geometry anchor: " + id
	var pins: Dictionary = _cue_parts.get(id, {})
	for part_name: String in ["RequiredFootprintOutline", "RequiredFootprintFill", "RequiredSourceMarker"]:
		if not pins.has(part_name): return "Actual ready native cue pins absent"
		var pin: Dictionary = pins[part_name]
		var part := cue.get_node_or_null(part_name) as MeshInstance3D
		if not is_instance_valid(part) or part != pin.node or not part.is_inside_tree() or part.is_queued_for_deletion() or part.get_parent() != cue or part.is_set_as_top_level() or part.material_override != pin.material or _cue_part_settings(part) != pin.settings: return "Retain actual native threat-cue node/material/settings: " + id
		if part_name != "RequiredSourceMarker" and part.transform != pin.transform: return "Retain actual native footprint local frame: " + id
		if part_name == "RequiredSourceMarker" and part.basis != pin.transform.basis: return "Retain actual native source glyph basis: " + id
		if shown.phase == "clear":
			if part.mesh != null or part.visible: return "Clear native cue cannot retain visible threat meshes: " + id
			continue
		var expected: ArrayMesh
		var expected_visible: bool
		if part_name == "RequiredSourceMarker":
			expected = NativeCueMesh.source_mesh(shown.phase)
			expected_visible = true
			if part.position != shown.source_position - cue.global_position + Vector3.UP * pin.transform.origin.y: return "Actual source glyph moved from the native cue source"
		else:
			expected = NativeCueMesh.geometry_mesh(shown.geometry, part_name == "RequiredFootprintFill")
			expected_visible = shown.phase == "active" if part_name == "RequiredFootprintFill" else shown.phase != "recovery"
		if part.visible != expected_visible or not _same_native_mesh(part.mesh, expected): return "Required native phase mesh/visibility changed: " + id
	return ""



func _same_native_mesh(actual: Variant, expected: ArrayMesh) -> bool:
	if not is_instance_valid(actual) or not actual is ArrayMesh or not is_instance_valid(expected): return false
	var native: ArrayMesh = actual
	if native.get_aabb() != expected.get_aabb() or native.get_surface_count() != expected.get_surface_count(): return false
	for surface: int in range(expected.get_surface_count()):
		if native.surface_get_primitive_type(surface) != expected.surface_get_primitive_type(surface) or native.surface_get_arrays(surface) != expected.surface_get_arrays(surface): return false
	return true



func _contact_mesh_factory_error() -> String:
	if not is_instance_valid(_exit_cue) or _exit_cue != _contact_cue or not _exit_cue.is_inside_tree() or _exit_cue.is_queued_for_deletion() or _exit_cue.get_parent() != self or _exit_cue.get_script() != InteractionCue: return "Retain actual native contact cue before glyph validation"
	if not is_instance_valid(_contact_marker) or _exit_cue.get_node_or_null("RequiredInteractionMarker") != _contact_marker or not _contact_marker.is_inside_tree() or _contact_marker.is_queued_for_deletion() or _contact_marker.get_parent() != _exit_cue or _contact_marker.material_override != _contact_material or not _contact_material is StandardMaterial3D: return "Retain actual native contact marker/material before glyph validation"
	var material: StandardMaterial3D = _contact_material
	if material.get_script() != null or material.next_pass != null: return "Native contact material cannot carry a script or next pass"
	var shown: Dictionary = _exit_cue.state() # Pure native read; no repair or callback.
	if shown.state == "clear":
		return "" if _contact_marker.mesh == null and not _contact_marker.visible else "Clear native contact must retain its genuine null hidden mesh"
	if shown.state != "available" or shown.trigger != "contact" or shown.required != true or shown.visible != true or not _contact_marker.is_visible_in_tree(): return "Only genuine available/contact presentation is supported by this exit"
	var expected: ArrayMesh = NativeCueMesh.interaction_mesh(shown.state, shown.trigger)
	return "" if _same_native_mesh(_contact_marker.mesh, expected) else "Actual contact glyph differs from the public native mesh factory"



func _decode_shape(encoded: Dictionary) -> Dictionary:
	var shape: Dictionary = encoded.duplicate(true)
	for key: String in ["origin", "direction", "from", "to", "source_position"]:
		if shape.has(key): shape[key] = Codec.read_vector3(shape[key])
	return shape



func _framing_structure_error(saved: Dictionary) -> String:
	var reservations: Dictionary = {}
	for raw: Variant in saved.scheduler.reservations:
		if not raw is Dictionary or not raw.get("source_id") is String or not raw.get("id") is String or reservations.has(raw.source_id): return "Unique complete native lease IDs required for framing"
		reservations[raw.source_id] = raw
	if not Codec.keys_error(saved.framing, reservations.keys()).is_empty(): return "Accepted witnesses must cover exactly every live native reservation"
	for id: String in saved.framing:
		var value: Variant = saved.framing[id]
		var record: Dictionary = reservations[id]
		if not value is Dictionary or not Codec.keys_error(value, FRAME_KEYS).is_empty() or value.reservation_id != record.id or not _encoded_vector(value.landing) or not _encoded_vector(value.attack_position) or not value.primary_time_s is float or not value.response_complete_s is float or not is_finite(value.primary_time_s) or not is_finite(value.response_complete_s):
			return "Exact original six-field accepted native response witness required: " + id
		for key: String in ["active_until_s", "recovery_until_s"]:
			if not record.get(key) is float or not is_finite(record[key]): return "Original native recovery deadlines required for accepted witness"
		if value.primary_time_s < record.active_until_s or value.response_complete_s < value.primary_time_s or value.response_complete_s >= record.recovery_until_s: return "Ordinary-primary accepted witness must fit its exact native recovery window"
		var error: String = _action_escape_error(value, record)
		if not error.is_empty(): return id + ": " + error
	return ""



func _action_escape_error(frame: Dictionary, record: Dictionary) -> String:
	var proof: Variant = frame.action_escape
	if not proof is Dictionary or not Codec.keys_error(proof, ["accepted", "path", "landing", "attack_position", "primary_time_s", "response_complete_s", "uses_blast", "uses_invulnerability", "proof_scope"]).is_empty() or not proof.accepted is bool or proof.accepted != true or not proof.uses_blast is bool or proof.uses_blast != false or not proof.uses_invulnerability is bool or proof.uses_invulnerability != false or proof.proof_scope != "static_box_floor_full_dash_stationary_primary" or not proof.path is Array or proof.path.size() not in [4, 6]: return "Whole original supported native ordinary action-escape proof required"
	for key: String in ["landing", "attack_position", "primary_time_s", "response_complete_s"]:
		if not _same(proof[key], frame[key]): return "Accepted proof and retained witness must preserve the same exact copied endpoint/time"
	var kinds: Array = ["recognition_and_ready", "escape_dash", "recovery_wait", "ordinary_primary"] if proof.path.size() == 4 else ["recognition_and_ready", "escape_dash", "recovery_wait", "positioning_dash", "primary_ready", "ordinary_primary"]
	var previous: Dictionary = {}
	for index: int in proof.path.size():
		var segment: Variant = proof.path[index]
		if not segment is Dictionary or not Codec.keys_error(segment, ["from", "to", "start_s", "end_s", "kind"]).is_empty() or segment.kind != kinds[index] or not _encoded_vector(segment.from) or not _encoded_vector(segment.to) or not segment.start_s is float or not segment.end_s is float or not is_finite(segment.start_s) or not is_finite(segment.end_s) or segment.start_s > segment.end_s: return "Original bounded native timed path segment required"
		if index == 0 and not _same(segment.start_s, record.start_s): return "Original action path must start at its actual native admission clock"
		if not previous.is_empty() and (not _same(previous.end_s, segment.start_s) or not _same(previous.to, segment.from)): return "Original action path must retain exact contiguous endpoints/clocks"
		if segment.kind not in ["escape_dash", "positioning_dash"] and not _same(segment.from, segment.to): return "Original native waiting/ordinary primary segment must remain stationary"
		if segment.start_s == segment.end_s and not _same(segment.from, segment.to): return "Zero-time action path cannot contain displacement"
		previous = segment
	if not _same(proof.path[1].to, frame.landing) or not _same(previous.from, frame.attack_position) or not _same(previous.to, frame.attack_position) or not _same(previous.start_s, frame.primary_time_s) or not _same(previous.end_s, frame.response_complete_s): return "Original escape landing and complete ordinary-primary path must agree exactly"
	return ""



func _quiet_contact_resources_error() -> String:
	var error: String = _contact_mesh_factory_error()
	if error.is_empty(): error = _contact_error()
	if not error.is_empty(): return error
	if _exit_cue != _contact_cue or _exit_cue.get_script() != InteractionCue or not _exit_cue.is_in_group("required_cues") or not is_instance_valid(_contact_marker) or _exit_cue.get_node_or_null("RequiredInteractionMarker") != _contact_marker or not _contact_marker.is_inside_tree() or _contact_marker.is_queued_for_deletion() or _contact_marker.get_parent() != _exit_cue or _contact_marker.material_override != _contact_material or _contact_marker.mesh != _contact_mesh: return "Retain actual native contact cue/marker/material/current-state mesh"
	var state: Dictionary = _exit_cue.state()
	if room_stage in ["hatch", "departed"]:
		if state.state != "available" or state.trigger != "contact" or not _contact_marker.is_visible_in_tree(): return "Completed court has actual native available/contact presentation"
	elif state.state != "clear" or _contact_marker.visible or _contact_marker.mesh != null: return "Incomplete court retains actual native clear contact presentation"
	return ""
