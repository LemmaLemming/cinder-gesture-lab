extends "res://scripts/acts/act1/mushroom_caverns.gd"
## SOURCE-ONLY functional O2 draft; no parser/engine/gameplay acceptance.
## Reuses Base's native actors/admission/approach and exact 14x72 world.
## Whole aggregate/candidate transport deliberately refuses until Root adds it.

const Bloom = preload("res://scripts/acts/act1/spore_bloom_layout.gd")
const NativeProtocol = preload("res://scripts/environment/scheduler_spore_source_protocol.gd")
const NativeField = preload("res://scripts/environment/spore_field.gd")
const Repulsion = preload("res://scripts/environment/spore_repulsion.gd")
const SporeRoute = preload("res://scripts/combat/repulsion_route.gd")
const LowClusterArt = preload("res://scripts/acts/act1/mushroom_cluster_art.gd")
const InteractionCue = preload("res://scripts/cues/interaction_cue.gd")
const SAVE_PENDING: String = "O2 whole native aggregate/candidate transport pending Root integration"
const OBJECTIVES: Array[String] = [
	"FIRST BREATHING ROOM\nHIT A LOW CLUSTER OR KEEP ITS SUPPLY",
	"PAIRED MUSHROOMS\nFINITE SUPPLIES · KEEP AN ORDINARY OPENING",
	"FINAL MIXED CROWD\nCLEAR THE SWARM AND ONE SPEAR GUARD",
	"SPORE BLOOM CLEAR\nCROSS THE CONTACT EXIT",
]

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
	if _construction_error.is_empty(): _build_contact()


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
	var actual: Array = shared_shell.call("player_camera_framing_points")
	if actual.is_empty(): return "Complete actual Player presentation required"
	for point: Vector3 in actual: points.append(point + endpoint - hero.global_position)
	return _containment_error(_bounded_union(points))


func _actor_points(id: String, endpoint: Vector3) -> Array:
	# Base omits inherited-hidden dormant sprites. Prospective disclosure needs
	# their COMPLETE real existing quads before changing any lifecycle property.
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
	var points: Array = super._camera_framing_points()
	if not _spore_bindings_error().is_empty() or not _cluster_bindings_error().is_empty(): return [Vector3.INF]
	var actual: Array = shared_shell.call("player_camera_framing_points")
	if actual.is_empty(): return [Vector3.INF]
	points.append_array(actual)
	if room_stage == "approach":
		for id: String in current_source_ids(): points.append_array(_actor_points(id, sources[id].global_position))
	# Keep every retained visible finite assembly, including spent carryover.
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
	var raw: Variant = shared_shell.get("camera") if is_instance_valid(shared_shell) else null
	if not is_instance_valid(raw) or not raw is Camera3D: return [Vector3.INF]
	var basis: Basis = (raw as Camera3D).global_basis
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
			_entry_failed("Genuinely defeated group retained actual Scheduler readiness")
			return
	completed_beats.append(Bloom.BEAT_IDS[beat_index])
	beat_index += 1
	room_stage = "hatch" if beat_index == 3 else "approach"
	_framing.clear()
	_clear_forecast_hint()
	_approach_forecasts.clear()
	_approach_camera_requests.clear()
	_changing = false
	_apply_bloom_presentation()
	if beat_index != 2: return
	_publishing_progress = true
	var accepted: bool = request_checkpoint(Bloom.CHECKPOINT_ID, "encounter")
	_publishing_progress = false
	if not accepted: _entry_failed("Genuine O2 pre-final checkpoint publication refused")


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
	objective_text = OBJECTIVES[beat_index]
	greybox_clear = room_stage in ["hatch", "departed"]
	if room_stage in ["hatch", "departed"]: _exit_cue.present("available", "contact")
	else: _exit_cue.clear()


func bloom_state() -> Dictionary:
	return {"beat_index": beat_index, "completed_beats": completed_beats.duplicate(), "room_stage": room_stage, "checkpoint_published": checkpoint_published, "sources": _render_sources.duplicate(true), "installed_fields": _fields.keys(), "installed_consumers": _consumers.keys(), "last_error": last_encounter_error, "save_supported": false}


func snapshot_state() -> Dictionary:
	last_snapshot_error = SAVE_PENDING
	return {}


func snapshot_state_for_presentation(_camera: Camera3D, _hud: GameHUD) -> Dictionary:
	last_snapshot_error = SAVE_PENDING
	return {}


func _local_snapshot_error(_state: Dictionary) -> String:
	return SAVE_PENDING


func _local_snapshot_error_with_player(_state: Dictionary, _player: Dictionary) -> String:
	return SAVE_PENDING


func _on_enter_restore_candidate(_local: Dictionary, _player: Dictionary) -> String:
	return SAVE_PENDING # Root must integrate the actual native constructor plan.


func _on_exit_level() -> void:
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
