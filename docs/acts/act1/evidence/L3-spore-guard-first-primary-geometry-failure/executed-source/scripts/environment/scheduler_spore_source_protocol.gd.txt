class_name CinderSchedulerSporeSourceProtocol
extends RefCounted
## Proposed native composition seam; no controller, timers, HP or motion here.
## Source-owned codecs validate genuine actor/controller/player units. The
## trusted parent still validates and commits the complete paused aggregate.

const Exact = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Route = preload("res://scripts/combat/repulsion_route.gd")
const Sweep = preload("res://scripts/combat/body_sweep.gd")
const API_REVISION: String = "scheduler-spore-source-1"
const ACTOR_REVISION: String = "scheduler-spore-actor-1"
const CONTROL_REVISION: String = "scheduler-source-control-1"
const MAX_CONFIGURATION_BYTES: int = 65536
const MAX_CLOCK: float = 1000000000.0
const RESPONSE_KEYS: Array[String] = ["api_revision", "source_id", "consumer_id", "alive", "grounded", "position", "velocity", "facing", "hurt_remaining_s", "body_collision_path", "support_radius", "height", "episode_id", "phase", "direction", "progress", "outside_transaction"]
const VIEW_KEYS: Array[String] = ["source_id", "consumer_id", "alive", "grounded", "motion", "repulsion", "reservation_id"]
const STAMP_KEYS: Array[String] = ["api_revision", "consumer_id", "source_id", "episode_id", "phase", "direction", "progress"]
const PHASES: Array[String] = ["none", "recoil", "turn", "retreat", "hold", "regroup", "interrupted", "failed"]
const HOOKS: Array[String] = ["get_spore_native_bindings", "spore_bind_error", "bind_spore_repulsion", "get_spore_response_state", "cancel_attack_for_spores", "present_spore_phase", "resume_spore_retreat", "finish_spore_episode", "spore_snapshot_state"]

var last_error: String = ""
var _source: WeakRef
var _scheduler: WeakRef
var _player: WeakRef
var _world: WeakRef
var _consumer: WeakRef
var _source_script: Script
var _codec_script: Script
var _codec: RefCounted
var _collision: WeakRef
var _shape: Shape3D
var _shape_owner: int = -1
var _native_body: Dictionary = {}
var _configuration: Dictionary = {}
var _configuration_json: String = ""
var _descriptor: Dictionary = {}
var _environment: Dictionary = {}
var _floor_shapes: Dictionary = {}
var _ground_y: float = 0.0
var _consumer_id: String = ""


func configure(source: CharacterBody3D, scheduler: CinderThreatScheduler, player: CinderPlayer, source_id: String, controller_id: String, player_id: String, environment: Dictionary) -> bool:
	if not _descriptor.is_empty():
		return _reject("Configure an unbound protocol exactly once")
	if not _id(source_id) or not _id(controller_id) or not _id(player_id) or not _live(source) or not _live(scheduler) or not _live(player) or not _keys(environment, ["world_root", "floors"]) or not environment.floors is Dictionary:
		return _reject("Distinct stable IDs and actual ready source/controller/player/environment required")
	if not _valid_object(environment.world_root) or not environment.world_root is Node3D:
		return _reject("Actual live world handle required before native casting")
	var floor_error: String = _floor_handles_error(environment.floors)
	if not floor_error.is_empty():
		return _reject(floor_error)
	var world: Node3D = environment.world_root as Node3D
	if not _live(world) or source.get_world_3d() != world.get_world_3d() or scheduler.get_world_3d() != world.get_world_3d() or player.get_world_3d() != world.get_world_3d() or not _under(source, world) or not _under(scheduler, world) or not _under(player, world) or source == player:
		return _reject("Actual source, Scheduler and Player must share the complete collision world root")
	if source.process_physics_priority <= scheduler.process_physics_priority or source.process_physics_priority <= player.process_physics_priority:
		return _reject("Actor sampling must follow actual Scheduler and Player physics")
	for hook: String in HOOKS:
		if not source.has_method(hook):
			return _reject("Actual source is missing owned hook: " + hook)
	var native: Variant = source.call("get_spore_native_bindings")
	if not _live(source) or not _live(scheduler) or not _live(player) or not _live(world):
		return _reject("Actual source callback released a retained native handle")
	if not native is Dictionary or not _keys(native, ["api_revision", "actor_revision", "source_id", "scheduler", "player", "codec", "configuration"]) or native.api_revision != ACTOR_REVISION or not _id(native.actor_revision) or native.source_id != source_id or not _valid_object(native.scheduler) or not _valid_object(native.player) or native.scheduler != scheduler or native.player != player or not _valid_object(native.codec) or not native.codec is RefCounted or not native.configuration is Dictionary:
		return _reject("Owned native bindings must identify the exact actor/controller/player")
	var owned_codec: RefCounted = native.codec
	if not owned_codec.has_method("record_error") or not owned_codec.has_method("record_view") or source.get_script() == null or owned_codec.get_script() == null:
		return _reject("Retained source script and owned native record decoder required")
	var configuration_json: String = Exact.stringify(native.configuration)
	if configuration_json.is_empty() or configuration_json.to_utf8_buffer().size() > MAX_CONFIGURATION_BYTES:
		return _reject("Bounded closed immutable native configuration required before copying")
	if not scheduler.has_method("source_control_state"):
		return _reject("Actual Scheduler pure source_control_state accessor has not been adopted")
	floor_error = _floor_handles_error(environment.floors)
	if not floor_error.is_empty():
		return _reject(floor_error)
	var measured: Dictionary = Route.binding_state(source, environment)
	var body: Dictionary = Sweep.source_description(source)
	if measured.has("error") or body.has("error"):
		return _reject(String(measured.get("error", body.get("error", "Unsupported actual source body"))))
	var collision: CollisionShape3D = source.get_node_or_null("BodyCollision") as CollisionShape3D
	if not _live(collision) or body.collision != collision:
		return _reject("One retained actual BodyCollision is required")
	var owners: PackedInt32Array = source.get_shape_owners()
	if owners.size() != 1 or source.shape_owner_get_owner(owners[0]) != collision:
		return _reject("Retained actual single shape registration required")
	var response: Variant = source.call("get_spore_response_state")
	if not _live(source) or not _live(scheduler) or not _live(player) or not _live(world) or not _live(collision) or not _valid_object(owned_codec):
		return _reject("Owned response callback released a retained native handle")
	floor_error = _floor_handles_error(environment.floors)
	if not floor_error.is_empty():
		return _reject(floor_error)
	var response_error: String = _response_error(response, source_id, "", float(measured.support_radius), float(body.height))
	if not response_error.is_empty() or not response.alive or not response.outside_transaction or response.phase != "none":
		return _reject(response_error if not response_error.is_empty() else "Bind an actual living idle environmental source outside transactions")
	if not _same(_vector(response.position), _vector(source.global_position)) or not _same(_vector(response.velocity), _vector(source.velocity)):
		return _reject("Owned response differs from actual native source motion")
	var control: Variant = scheduler.call("source_control_state", source)
	var control_error: String = _control_error(control, source.get_instance_id())
	if not control_error.is_empty() or not control.outside_transaction:
		return _reject(control_error if not control_error.is_empty() else "Bind outside Scheduler transactions")
	_source = weakref(source)
	_scheduler = weakref(scheduler)
	_player = weakref(player)
	_world = weakref(world)
	_source_script = source.get_script() as Script
	_codec = owned_codec
	_codec_script = owned_codec.get_script() as Script
	_collision = weakref(collision)
	_shape = collision.shape
	_shape_owner = owners[0]
	_native_body = _body_properties(source, collision)
	_configuration_json = configuration_json
	_configuration = native.configuration.duplicate(true)
	_environment = environment.duplicate(true)
	for id: String in environment.floors:
		_floor_shapes[id] = (environment.floors[id].collision as CollisionShape3D).shape
	_ground_y = source.global_position.y + float(measured.foot_offset)
	_descriptor = {"api_revision": API_REVISION, "actor_revision": native.actor_revision, "source_id": source_id, "controller_id": controller_id, "player_id": player_id, "configuration_sha256": configuration_json.sha256_text(), "source_environment": measured.duplicate(true), "height": float(body.height)}
	last_error = ""
	return true


func binding_state() -> Dictionary:
	return _descriptor.duplicate(true)


func matches_source(source: CharacterBody3D, source_id: String) -> bool:
	return _live(source) and _source_node() == source and _descriptor.get("source_id") == source_id and binding_error().is_empty()


func binding_compatibility_error(other: CinderSchedulerSporeSourceProtocol) -> String:
	if not is_instance_valid(other) or not binding_error().is_empty() or not other.binding_error().is_empty(): return "Actual live native bindings required for compatibility"
	if (_descriptor.controller_id == other._descriptor.controller_id) != (_scheduler_node() == other._scheduler_node()): return "Native controller ID/object aliases conflict"
	if (_descriptor.player_id == other._descriptor.player_id) != (_player_node() == other._player_node()): return "Native Player ID/object aliases conflict"
	if (_descriptor.source_id == other._descriptor.source_id) != (_source_node() == other._source_node()): return "Native source ID/object aliases conflict"
	return ""


func binding_error() -> String:
	return _binding_error(false)


func bind_error(consumer: Node) -> String:
	var error: String = binding_error()
	if not error.is_empty():
		return error
	if not _live(consumer) or not consumer.has_method("consumer_id") or not consumer.has_method("source_binding_matches"):
		return "Actual environmental consumer binding required"
	var id: Variant = consumer.call("consumer_id")
	var source: CharacterBody3D = _source_node()
	if not _live(consumer) or not _live(source) or not _id(id) or not bool(consumer.call("source_binding_matches", source, _descriptor.source_id)):
		return "Consumer must already stage this exact source and stable ID"
	if not _live(consumer) or not _live(source):
		return "Pure consumer query released a retained handle"
	if not _consumer_id.is_empty():
		return "" if _consumer_node() == consumer and _consumer_id == id else "Environmental binding is immutable"
	var result: Variant = source.call("spore_bind_error", consumer, _descriptor.source_id)
	if not _live(consumer) or not _live(source):
		return "Pure owned bind guard released a retained handle"
	if not result is String:
		return "Owned pure bind guard must return a String"
	return binding_error() if result.is_empty() else result


func bind(consumer: Node) -> bool:
	last_error = bind_error(consumer)
	if not last_error.is_empty():
		return false
	if not _consumer_id.is_empty():
		return true
	var source: CharacterBody3D = _source_node()
	var id: String = consumer.call("consumer_id")
	if not _live(consumer) or not _live(source):
		return _reject("Prevalidated native binding handle disappeared")
	if not bool(source.call("bind_spore_repulsion", consumer, _descriptor.source_id)):
		return _reject("Prevalidated owned native binding rejected its silent commit")
	if not _live(consumer) or not _live(source):
		return _reject("Owned binding callback released a retained handle")
	_consumer = weakref(consumer)
	_consumer_id = id
	var error: String = binding_error()
	if not error.is_empty():
		return _reject("Committed source binding changed: " + error)
	last_error = ""
	return true


func response_state() -> Dictionary:
	if not binding_error().is_empty():
		return {}
	var source: CharacterBody3D = _source_node()
	var result: Variant = source.call("get_spore_response_state")
	if not _live(source) or not _response_error(result, _descriptor.source_id, _consumer_id, float(_descriptor.source_environment.support_radius), float(_descriptor.height)).is_empty():
		return {}
	if not _same(_vector(result.position), _vector(source.global_position)) or not _same(_vector(result.velocity), _vector(source.velocity)):
		return {}
	if not binding_error().is_empty():
		return {}
	return (result as Dictionary).duplicate(true)


func control_state() -> Dictionary:
	if not binding_error().is_empty(): return {}
	var source: CharacterBody3D = _source_node()
	var control: Variant = _scheduler_node().call("source_control_state", source)
	if not _control_error(control, source.get_instance_id()).is_empty() or not binding_error().is_empty(): return {}
	return (control as Dictionary).duplicate(true)


func profile_state() -> Dictionary:
	if not binding_error().is_empty(): return {}
	var profile: Dictionary = _scheduler_node().encounter_profile()
	return profile.duplicate(true) if not Exact.stringify(profile).is_empty() and binding_error().is_empty() else {}


func unit_error(actor: Dictionary, context: Dictionary) -> String:
	var error: String = _context_error(context)
	if not error.is_empty():
		return error
	if Exact.stringify(actor).is_empty():
		return "Bounded closed native actor envelope required before copying"
	error = _binding_error(true)
	if not error.is_empty():
		return error
	if not _scheduler_node().get_tree().paused:
		return "Native units require the complete paused deferred barrier"
	var source: CharacterBody3D = _source_node()
	var query_owner: Node3D = source if source != null else _player_node()
	var control: Variant = _scheduler_node().call("source_control_state", query_owner)
	error = _control_error(control, query_owner.get_instance_id())
	if not error.is_empty() or not control.outside_transaction:
		return error if not error.is_empty() else "Native validation cannot run inside Scheduler callbacks"
	if source != null:
		var response: Dictionary = response_state()
		if response.is_empty() or not response.outside_transaction:
			return "Native validation requires a retained actual response outside actor callbacks"
	var scheduler: Dictionary = context.controllers[_descriptor.controller_id]
	var player: Dictionary = context.players[_descriptor.player_id]
	error = _player_node().snapshot_error(player)
	if not error.is_empty():
		return "Complete native Player envelope rejected: " + error
	var decoded: Variant = _codec.call("record_error", actor.duplicate(true), scheduler.duplicate(true), player.duplicate(true), _codec_binding())
	if not decoded is String:
		return "Owned native decoder must return a String"
	if not decoded.is_empty():
		return "Owned native envelope rejected: " + decoded
	error = _binding_error(true)
	if not error.is_empty():
		return error
	var view: Variant = _codec.call("record_view", actor.duplicate(true), _codec_binding())
	error = _view_error(view)
	if not error.is_empty():
		return error
	error = _binding_error(true)
	if not error.is_empty():
		return error
	var owned: Array = _owned_records(scheduler.reservations)
	var cooldowns: Array = _owned_records(scheduler.cooldowns)
	if owned.size() > 1 or cooldowns.size() > 1:
		return "Source cannot own duplicated Scheduler reservations or cooldowns"
	if view.reservation_id.is_empty():
		if not owned.is_empty():
			return "Native actor cannot discard its paired Scheduler lease"
	elif owned.size() != 1 or owned[0].get("id") != view.reservation_id:
		return "Native actor requires its exact paired Scheduler reservation"
	if not view.alive and (not owned.is_empty() or not cooldowns.is_empty()):
		return "Actual defeated source cannot retain a lease or cooldown"
	if view.repulsion.phase != "none" and (not view.alive or not view.reservation_id.is_empty() or not owned.is_empty()):
		return "Spore episode must suppress the genuine native Scheduler attack"
	if _source_node() == null and (view.alive or view.repulsion.phase != "none"):
		return "Missing live source requires a ready external replacement"
	var saved_position: Vector3 = Codec.read_vector3(view.motion.position)
	var environment: Dictionary = Route.static_environment_state(_world_node(), _environment.floors, _descriptor.source_environment, Vector3(saved_position.x, _ground_y - float(_descriptor.source_environment.foot_offset), saved_position.z))
	if environment.has("error") or not _same(environment.get("world_signature"), _descriptor.source_environment.world_signature) or not _same(environment.get("floor_signature"), _descriptor.source_environment.floor_signature):
		return "Actual registered static world/floor assumptions changed"
	return ""


func unit_view(actor: Dictionary, context: Dictionary) -> Dictionary:
	if not unit_error(actor, context).is_empty():
		return {}
	var view: Variant = _codec.call("record_view", actor.duplicate(true), _codec_binding())
	if not _view_error(view).is_empty() or not _binding_error(true).is_empty():
		return {}
	return (view as Dictionary).duplicate(true)


func current_unit(context: Dictionary) -> Dictionary:
	last_error = _context_error(context)
	if last_error.is_empty():
		last_error = binding_error()
	var source: CharacterBody3D = _source_node()
	if not last_error.is_empty() or source == null:
		return {}
	if not source.get_tree().paused:
		return _capture_rejected("Native captures require the complete paused deferred barrier")
	var control: Variant = _scheduler_node().call("source_control_state", source)
	var control_error: String = _control_error(control, source.get_instance_id())
	var response: Dictionary = response_state()
	if not control_error.is_empty() or response.is_empty() or not control.outside_transaction or not response.outside_transaction:
		return _capture_rejected("Native captures cannot run inside source or Scheduler callbacks")
	var saved_scheduler: Dictionary = context.controllers[_descriptor.controller_id]
	if not _same(control.clock_s, saved_scheduler.clock_s) or control.encounter_id != saved_scheduler.get("encounter_id") or control.world_revision != saved_scheduler.get("world_revision") or not _same(_scheduler_node().encounter_profile(), saved_scheduler.get("profile")):
		return _capture_rejected("Actual Scheduler clock/encounter/profile differs from paired capture")
	var own: Array = _owned_records(saved_scheduler.reservations)
	if own.size() != control.reservations.size():
		return _capture_rejected("Actual Scheduler source lease count differs from paired capture")
	for record: Dictionary in control.reservations:
		if own.is_empty() or own[0].get("id") != record.get("id"):
			return _capture_rejected("Actual Scheduler source lease identity differs from paired capture")
		for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision"]:
			if not _same(record.get(key), own[0].get(key)):
				return _capture_rejected("Actual Scheduler source deadline/profile differs from paired capture")
		for key: String in ["source_position", "opening_position", "geometry"]:
			if not _same(_encode_native(record.get(key)), own[0].get(key)):
				return _capture_rejected("Actual Scheduler source pose/geometry differs from paired capture")
		if record.has("adapter") != own[0].has("adapter") or (record.has("adapter") and not _same(_encode_native(record.adapter), own[0].adapter)):
			return _capture_rejected("Actual native Scheduler adapter differs from paired capture")
	var saved_cooldowns: Array = _owned_records(saved_scheduler.cooldowns)
	var retained: bool = control.cooldown != null and float(control.cooldown.ready_s) > float(control.clock_s)
	if saved_cooldowns.size() != (1 if retained else 0) or (retained and not _same(saved_cooldowns[0].get("ready_s"), control.cooldown.ready_s)):
		return _capture_rejected("Actual retained Scheduler cooldown differs from paired capture")
	var current_player: Dictionary = _player_node().snapshot_state()
	if current_player.is_empty() or not _same(current_player, context.players[_descriptor.player_id]):
		return _capture_rejected("Actual complete Player differs from paired capture")
	var value: Variant = source.call("spore_snapshot_state", saved_scheduler.duplicate(true), current_player.duplicate(true))
	if not _live(source):
		return _capture_rejected("Owned paused writer released the actual source handle")
	if not value is Dictionary or value.is_empty():
		return _capture_rejected("Owned native paused writer rejected the capture")
	last_error = unit_error(value, context)
	if not last_error.is_empty():
		return {}
	var view: Variant = _codec.call("record_view", value.duplicate(true), _codec_binding())
	if not _view_error(view).is_empty() or not binding_error().is_empty():
		return _capture_rejected("Owned final capture view or retained native binding changed")
	if not _same(view.motion.position, _vector(source.global_position)) or not _same(view.motion.velocity, _vector(source.velocity)):
		return _capture_rejected("Native capture differs from the actual physical source")
	return value.duplicate(true)


func _binding_error(allow_missing_defeat: bool) -> String:
	if _descriptor.is_empty():
		return "Protocol has not been configured"
	var world: Node3D = _world_node()
	var scheduler: CinderThreatScheduler = _scheduler_node()
	var player: CinderPlayer = _player_node()
	if not _live(world) or not _live(scheduler) or not _live(player) or scheduler.get_world_3d() != world.get_world_3d() or player.get_world_3d() != world.get_world_3d() or not _under(scheduler, world) or not _under(player, world) or not is_instance_valid(_codec) or _codec.get_script() != _codec_script:
		return "Retained actual world/controller/player/codec binding changed"
	var floor_error: String = _floor_handles_error(_environment.floors)
	if not floor_error.is_empty():
		return floor_error
	for id: String in _environment.floors:
		if (_environment.floors[id].collision as CollisionShape3D).shape != _floor_shapes[id]:
			return "Retained actual floor shape resource changed"
	var static_environment: Dictionary = Route.static_environment_state(world, _environment.floors, _descriptor.source_environment, Vector3(0.0, _ground_y - float(_descriptor.source_environment.foot_offset), 0.0))
	if static_environment.has("error") or not _same(static_environment.get("world_signature"), _descriptor.source_environment.world_signature) or not _same(static_environment.get("floor_signature"), _descriptor.source_environment.floor_signature):
		return "Retained actual static world/floor binding changed"
	if not _consumer_id.is_empty() and not _live(_consumer_node()):
		return "Retained environmental consumer disappeared"
	var source: CharacterBody3D = _source_node()
	if source == null:
		return "" if allow_missing_defeat else "Retained actual source disappeared"
	if not _live(source) or source.get_world_3d() != world.get_world_3d() or not _under(source, world) or source.get_script() != _source_script:
		return "Retained actual source/script/world binding changed"
	if source.process_physics_priority <= scheduler.process_physics_priority or source.process_physics_priority <= player.process_physics_priority:
		return "Actual source sampling must remain after retained Scheduler and Player physics"
	var native: Variant = source.call("get_spore_native_bindings")
	if not _live(source) or not _live(scheduler) or not _live(player) or not _live(world) or not _valid_object(_codec):
		return "Owned binding query released a retained native handle"
	if not native is Dictionary or not _keys(native, ["api_revision", "actor_revision", "source_id", "scheduler", "player", "codec", "configuration"]) or native.api_revision != ACTOR_REVISION or native.actor_revision != _descriptor.actor_revision or native.source_id != _descriptor.source_id or not _valid_object(native.scheduler) or not _valid_object(native.player) or not _valid_object(native.codec) or native.scheduler != scheduler or native.player != player or native.codec != _codec or not native.configuration is Dictionary or Exact.stringify(native.configuration) != _configuration_json:
		return "Owned immutable source/controller/codec/configuration binding changed"
	var collision: CollisionShape3D = _collision.get_ref() as CollisionShape3D
	if not _live(collision) or collision.get_parent() != source or source.get_node_or_null("BodyCollision") != collision or collision.shape != _shape or not is_instance_valid(_shape) or not _same(_body_properties(source, collision), _native_body):
		return "Retained native body/collider/resource/properties changed"
	var owners: PackedInt32Array = source.get_shape_owners()
	if owners.size() != 1 or owners[0] != _shape_owner or source.shape_owner_get_owner(_shape_owner) != collision or source.shape_owner_get_shape_count(_shape_owner) != 1 or source.shape_owner_get_shape(_shape_owner, 0) != _shape or source.shape_owner_get_transform(_shape_owner) != collision.transform or source.is_shape_owner_disabled(_shape_owner) != collision.disabled:
		return "Retained actual native shape registration changed"
	if not _same(_basis(source.global_basis), _basis(Basis.IDENTITY)) or not source.global_position.is_finite() or not source.velocity.is_finite() or not source.get_collision_exceptions().is_empty() or source.get_platform_velocity() != Vector3.ZERO or source.get_platform_angular_velocity() != Vector3.ZERO:
		return "Source must retain upright finite fixed-world native motion"
	var response: Variant = source.call("get_spore_response_state")
	if not _live(source) or not _live(scheduler) or not _live(player) or not _live(world) or not _live(collision):
		return "Owned response query released a retained native handle"
	var error: String = _response_error(response, _descriptor.source_id, _consumer_id, float(_descriptor.source_environment.support_radius), float(_descriptor.height))
	if not error.is_empty():
		return error
	if not _same(_vector(response.position), _vector(source.global_position)) or not _same(_vector(response.velocity), _vector(source.velocity)):
		return "Owned response changed actual source pose/velocity"
	if source.collision_layer != (2 if response.alive else 0) or source.collision_mask != (1 if response.alive else 0) or collision.disabled == response.alive:
		return "Actual source collision lifecycle differs from its owned alive state"
	if not scheduler.has_method("source_control_state"):
		return "Actual Scheduler pure source accessor disappeared"
	var control: Variant = scheduler.call("source_control_state", source)
	return _control_error(control, source.get_instance_id())


func _context_error(context: Dictionary) -> String:
	if _descriptor.is_empty() or not _keys(context, ["controllers", "players"]) or not context.controllers is Dictionary or not context.players is Dictionary or not context.controllers.has(_descriptor.controller_id) or not context.players.has(_descriptor.player_id):
		return "Complete native controller/player context by stable binding required"
	if Exact.stringify(context).is_empty() or not context.controllers[_descriptor.controller_id] is Dictionary or not context.players[_descriptor.player_id] is Dictionary:
		return "Bounded closed complete native context required before copying"
	var scheduler: Dictionary = context.controllers[_descriptor.controller_id]
	if not scheduler.get("reservations") is Array or not scheduler.get("cooldowns") is Array or not scheduler.get("clock_s") is float or not Codec.in_range(scheduler.clock_s, 0.0, MAX_CLOCK):
		return "Validated native Scheduler envelope with exact clock and source tables required"
	for records: Array in [scheduler.reservations, scheduler.cooldowns]:
		for record: Variant in records:
			if not record is Dictionary or not _id(record.get("source_id")):
				return "Native controller records require stable authored source IDs"
	return ""


func _view_error(view: Variant) -> String:
	if not view is Dictionary or not _keys(view, VIEW_KEYS) or Exact.stringify(view).is_empty() or view.source_id != _descriptor.source_id or view.consumer_id != _consumer_id or not view.alive is bool or not view.grounded is bool or not view.motion is Dictionary or not _keys(view.motion, ["position", "basis", "velocity", "facing"]) or not view.repulsion is Dictionary or not view.reservation_id is String:
		return "Owned native decoder returned an invalid common view"
	for key: String in ["position", "velocity", "facing"]:
		if not _encoded_vector(view.motion[key]):
			return "Common view requires exact encoded native vectors"
	if not _bounded_position(Codec.read_vector3(view.motion.position)):
		return "Saved native source position exceeds measured-world bounds"
	if not _same(view.motion.basis, _basis(Basis.IDENTITY)) or not _direction(Codec.read_vector3(view.motion.facing)):
		return "Common source view requires upright native basis and planar facing"
	var error: String = _stamp_error(view.repulsion, _descriptor.source_id, _consumer_id)
	if not error.is_empty():
		return error
	if not view.alive and (view.repulsion.phase != "none" or not view.reservation_id.is_empty()):
		return "Defeated native view cannot retain an episode or attack"
	return ""


static func _response_error(response: Variant, source_id: String, consumer_id: String, radius: float, height: float) -> String:
	if not response is Dictionary or not _keys(response, RESPONSE_KEYS) or response.api_revision != ACTOR_REVISION or response.source_id != source_id or response.consumer_id != consumer_id or not response.alive is bool or not response.grounded is bool or not response.outside_transaction is bool:
		return "Owned actual native response keys/identity/lifecycle invalid"
	for key: String in ["position", "velocity", "facing", "direction"]:
		if not response[key] is Vector3 or not response[key].is_finite():
			return "Owned response requires finite native vectors"
	if not _bounded_position(response.position):
		return "Actual native source position exceeds measured-world bounds"
	if not _direction(response.facing) or not _direction(response.direction) or response.body_collision_path != "BodyCollision" or not _same(response.support_radius, radius) or not _same(response.height, height) or not Codec.in_range(response.hurt_remaining_s, 0.0, MAX_CLOCK):
		return "Owned response body/facing/hurt differs from actual immutable support"
	return _stamp_error({"api_revision": response.api_revision, "source_id": response.source_id, "consumer_id": response.consumer_id, "episode_id": response.episode_id, "phase": response.phase, "direction": _vector(response.direction), "progress": response.progress}, source_id, consumer_id)


static func _stamp_error(stamp: Dictionary, source_id: String, consumer_id: String) -> String:
	if not _keys(stamp, STAMP_KEYS) or stamp.api_revision != ACTOR_REVISION or stamp.source_id != source_id or stamp.consumer_id != consumer_id or not stamp.episode_id is String or not stamp.phase is String or not PHASES.has(stamp.phase) or not _encoded_vector(stamp.direction) or not _direction(Codec.read_vector3(stamp.direction)) or not stamp.progress is float or not Codec.in_range(stamp.progress, 0.0, 1.0):
		return "Native repulsion identity/phase/direction/progress invalid"
	if stamp.phase == "none":
		return "" if stamp.episode_id.is_empty() and stamp.progress == 0.0 else "Inactive native source cannot retain an episode"
	return "" if _id(stamp.episode_id) and not consumer_id.is_empty() and stamp.episode_id.begins_with(consumer_id + "/episode-") else "Active native source requires its bound episode identity"


static func _control_error(control: Variant, owner_id: int) -> String:
	if not control is Dictionary or not _keys(control, ["api_revision", "source_instance_id", "encounter_id", "world_revision", "clock_s", "outside_transaction", "reservations", "cooldown"]) or control.api_revision != CONTROL_REVISION or control.source_instance_id != owner_id or not control.source_instance_id is int or not control.encounter_id is String or not control.world_revision is int or not control.clock_s is float or not Codec.in_range(control.clock_s, 0.0, MAX_CLOCK) or not control.outside_transaction is bool or not control.reservations is Array or control.reservations.size() > 1:
		return "Actual pure Scheduler source control state invalid"
	for record: Variant in control.reservations:
		if not record is Dictionary or record.get("source_instance_id") != owner_id or not record.get("id") is String:
			return "Actual pure Scheduler lease owner differs"
	if control.cooldown != null and (not control.cooldown is Dictionary or not _keys(control.cooldown, ["ready_s"]) or not control.cooldown.ready_s is float or not Codec.in_range(control.cooldown.ready_s, 0.0, MAX_CLOCK)):
		return "Actual retained Scheduler cooldown invalid"
	return ""


func _codec_binding() -> Dictionary:
	return {"api_revision": API_REVISION, "actor_revision": _descriptor.actor_revision, "source_id": _descriptor.source_id, "controller_id": _descriptor.controller_id, "player_id": _descriptor.player_id, "consumer_id": _consumer_id, "configuration": _configuration.duplicate(true), "body_signature": _descriptor.source_environment.body_signature.duplicate(true)}


func _owned_records(records: Array) -> Array:
	var result: Array = []
	for record: Dictionary in records:
		if record.source_id == _descriptor.source_id:
			result.append(record)
	return result


static func _body_properties(source: CharacterBody3D, collision: CollisionShape3D) -> Dictionary:
	var shape: Shape3D = collision.shape
	var dimensions: Dictionary = {"kind": shape.get_class(), "margin": shape.margin, "custom_solver_bias": shape.custom_solver_bias}
	if shape is CapsuleShape3D:
		dimensions["radius"] = shape.radius
		dimensions["height"] = shape.height
	elif shape is BoxShape3D:
		dimensions["size"] = _vector(shape.size)
	return {"collision_basis": _basis(collision.basis), "collision_position": _vector(collision.position), "shape": dimensions, "safe_margin": source.safe_margin, "priority": source.collision_priority, "up_direction": _vector(source.up_direction), "floor_snap_length": source.floor_snap_length, "motion_mode": source.motion_mode, "axis_locks": [source.axis_lock_linear_x, source.axis_lock_linear_y, source.axis_lock_linear_z, source.axis_lock_angular_x, source.axis_lock_angular_y, source.axis_lock_angular_z], "process_mode": source.process_mode, "physics_priority": source.process_physics_priority}


func _source_node() -> CharacterBody3D:
	return _source.get_ref() as CharacterBody3D if _source != null else null


func _scheduler_node() -> CinderThreatScheduler:
	return _scheduler.get_ref() as CinderThreatScheduler if _scheduler != null else null


func _player_node() -> CinderPlayer:
	return _player.get_ref() as CinderPlayer if _player != null else null


func _world_node() -> Node3D:
	return _world.get_ref() as Node3D if _world != null else null


func _consumer_node() -> Node:
	return _consumer.get_ref() as Node if _consumer != null else null


static func _live(node: Node) -> bool:
	return is_instance_valid(node) and node.is_inside_tree() and node.is_node_ready() and not node.is_queued_for_deletion()


static func _valid_object(value: Variant) -> bool:
	return typeof(value) == TYPE_OBJECT and is_instance_valid(value)


static func _floor_handles_error(floors: Dictionary) -> String:
	if floors.is_empty() or floors.size() > 32:
		return "One to 32 actual authored floor bindings required"
	for id: Variant in floors:
		var value: Variant = floors[id]
		if not _id(id) or not value is Dictionary or not _keys(value, ["collision", "safe_rect"]) or not _valid_object(value.collision) or not value.collision is CollisionShape3D or not value.safe_rect is Rect2:
			return "Live native floor handles required before collision casting"
		var collision: CollisionShape3D = value.collision as CollisionShape3D
		if not _live(collision) or not _valid_object(collision.shape) or not collision.shape is BoxShape3D:
			return "Actual retained static BOX floor collider required"
	return ""


static func _under(node: Node, world: Node) -> bool:
	return node == world or world.is_ancestor_of(node)


static func _keys(value: Dictionary, names: Array) -> bool:
	if value.size() != names.size():
		return false
	for name: Variant in names:
		if not value.has(name):
			return false
	return true


static func _id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 128:
		return false
	for character: String in value:
		if not "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_./:-".contains(character):
			return false
	return true


static func _encoded_vector(value: Variant) -> bool:
	return value is Array and value.size() == 3 and value[0] is float and value[1] is float and value[2] is float and is_finite(value[0]) and is_finite(value[1]) and is_finite(value[2])


static func _direction(value: Vector3) -> bool:
	return value.is_finite() and absf(value.y) <= Sweep.EPSILON and absf(value.length() - 1.0) <= Sweep.EPSILON


static func _bounded_position(value: Vector3) -> bool:
	return value.is_finite() and absf(value.x) <= Sweep.MAX_COORDINATE and absf(value.y) <= Sweep.MAX_COORDINATE and absf(value.z) <= Sweep.MAX_COORDINATE


static func _vector(value: Vector3) -> Array:
	return [float(value.x), float(value.y), float(value.z)]


static func _basis(value: Basis) -> Array:
	return [_vector(value.x), _vector(value.y), _vector(value.z)]


static func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = Exact.stringify(left)
	return not encoded.is_empty() and encoded == Exact.stringify(right)


static func _encode_native(value: Variant) -> Variant:
	if value is Vector3:
		return _vector(value)
	if value is Dictionary:
		var encoded: Dictionary = {}
		for key: Variant in value:
			encoded[key] = _encode_native(value[key])
		return encoded
	if value is Array:
		var encoded: Array = []
		for item: Variant in value:
			encoded.append(_encode_native(item))
		return encoded
	return value


func _reject(reason: String) -> bool:
	last_error = reason
	return false


func _capture_rejected(reason: String) -> Dictionary:
	last_error = reason
	return {}
