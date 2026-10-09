class_name Act1MushroomSeleniteCodec
extends RefCounted
## Pure owned C31/C32 envelope codec; no nodes, clocks, motion or controller authority.
## API3 keeps ordinary schema1/native-pending2 and adds bound schema3/bound-pending4.
## The conditional repulsion stamp contains only genuine consumer-owned state.
##
## schema_error/context_error remain the native core. Complete Player/Scheduler
## units MUST also pass their existing shared validators. A structurally valid
## stamp does not prove environmental ownership: the parent/coordinator MUST
## prevalidate the exact paired episode, Route, fields and whole native unit.
## Never call this core a complete environmental or physical-world validator.
## record_error/record_view dispatch only closed owned binding3 or the exact
## reviewed scheduler-spore-source-1 binding. Native view3 and common view are
## distinct projections; Route's measured descriptor is explicitly mapped to
## Motion's capsule signature instead of substituting one schema for the other.

const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const Approach = preload("res://scripts/acts/act1/mushroom_selenite_approach.gd")
const API_REVISION: String = "act1-mushroom-selenite-3"
const SNAPSHOT_SCHEMA_VERSION: int = 1
const PENDING_SNAPSHOT_SCHEMA_VERSION: int = 2
const BOUND_SNAPSHOT_SCHEMA_VERSION: int = 3
const BOUND_PENDING_SNAPSHOT_SCHEMA_VERSION: int = 4
const SPORE_PROTOCOL_REVISION: String = "scheduler-spore-source-1"
const SPORE_ACTOR_REVISION: String = "scheduler-spore-actor-1"
const REPULSION_KEYS: Array[String] = ["api_revision", "consumer_id", "source_id", "episode_id", "phase", "direction", "progress"]
const REPULSION_PHASES: Array[String] = ["none", "recoil", "turn", "retreat", "hold", "regroup", "interrupted", "failed"]
const MAX_PENDING_SEGMENTS: int = 256
const HURT_S: float = 0.22
const HERO_ID: String = "hero"
const ROLE_SWARM: String = "A1-E2"
const ROLE_GUARD: String = "A1-E3"
const BINDING_REVISION: String = "act1-mushroom-selenite-codec-binding-3"
const VIEW_REVISION: String = "act1-mushroom-selenite-native-view-3"
const SNAPSHOT_KEYS: Array[String] = ["api_revision", "schema_version", "role_id", "source_id", "configuration", "hp", "dead", "dormant", "motion", "hurt_left_s", "approach_driving", "role_encounter_id", "profile_id", "resolved_role", "reservation_id", "cycle", "sample", "hit_ids", "last_cancel_reason"]


func record_error(actor: Dictionary, scheduler: Dictionary, player: Dictionary, binding: Dictionary) -> String:
	# Literal revision selects a separately closed adapter, never loose duck typing.
	if binding.get("api_revision") == SPORE_PROTOCOL_REVISION:
		return spore_record_error(actor, scheduler, player, binding)
	var error: String = _native_binding_error(binding)
	if not error.is_empty(): return error
	# Stable controller/player IDs resolve separately validated complete units.
	return context_error(actor, scheduler, player, binding.configuration, binding.body_signature)


func record_view(actor: Dictionary, binding: Dictionary) -> Dictionary:
	if binding.get("api_revision") == SPORE_PROTOCOL_REVISION:
		return spore_record_view(actor, binding)
	# Caller first runs record_error against complete paired context. A two-argument
	# view cannot validate that context or a consumer's saved Route/episode.
	if not _native_binding_error(binding).is_empty() or not schema_error(actor, binding.configuration).is_empty():
		return {}
	var result: Dictionary = {"api_revision": VIEW_REVISION, "actor_revision": API_REVISION,
		"source_id": actor.source_id, "controller_id": binding.controller_id,
		"player_id": binding.player_id, "role_id": actor.role_id,
		"entity_id": binding.configuration.entity_id, "hp": actor.hp,
		"max_hp": binding.configuration.raw_role.max_hp,
		"alive": not actor.dead and not actor.dormant, "dead": actor.dead,
		"dormant": actor.dormant, "grounded": actor.motion.grounded,
		"motion": actor.motion.duplicate(true), "hurt_left_s": actor.hurt_left_s,
		"approach_driving": actor.approach_driving,
		"reservation_id": actor.reservation_id, "cycle": actor.cycle}
	if _bound_schema(actor): result["repulsion"] = actor.repulsion.duplicate(true)
	return result


func binding_error(binding: Dictionary) -> String:
	return spore_binding_error(binding) if binding.get("api_revision") == SPORE_PROTOCOL_REVISION else _native_binding_error(binding)


func _native_binding_error(binding: Dictionary) -> String:
	var error: String = Codec.value_error(binding)
	if not error.is_empty(): return error
	if not Codec.keys_error(binding, ["api_revision", "actor_revision", "source_id", "controller_id", "player_id", "configuration", "body_signature"]).is_empty():
		return "Closed owned native codec binding3 required"
	if binding.api_revision != BINDING_REVISION or binding.actor_revision != API_REVISION or not _stable_id(binding.source_id) or not _stable_id(binding.controller_id) or not _stable_id(binding.player_id) or not binding.configuration is Dictionary or not binding.body_signature is Dictionary:
		return "Invalid stable native codec binding identity/configuration/signature"
	error = configuration_error(binding.configuration)
	if not error.is_empty(): return error
	if binding.source_id != binding.configuration.source_id:
		return "Native codec binding source must match the actual immutable configured source"
	# Retained Motion signature; actual native source validation owns measurement.
	if not Codec.keys_error(binding.body_signature, ["collision_path", "centre", "radius", "height", "margin", "custom_solver_bias", "layer", "mask", "linear_axis_locks"]).is_empty():
		return "Retained exact native capsule signature required"
	var body: Dictionary = binding.body_signature
	if body.collision_path != "BodyCollision" or not Codec.is_vector3(body.centre) or not _same(Codec.vector3(Codec.read_vector3(body.centre)), body.centre) or not Codec.is_number(body.radius) or float(body.radius) <= 0.0 or not Codec.is_number(body.height) or float(body.height) < 2.0 * float(body.radius) or not Codec.is_number(body.margin) or float(body.margin) < 0.0 or not Codec.is_number(body.custom_solver_bias) or not body.layer is int or body.layer != 2 or not body.mask is int or body.mask != 1 or not body.linear_axis_locks is Array or body.linear_axis_locks.size() != 3:
		return "Invalid measured native capsule signature values"
	for flag: Variant in body.linear_axis_locks:
		if not flag is bool: return "Native capsule axis lock signature requires actual booleans"
	return ""


## Reviewed helper supplies this exact eight-key binding from actual retained
## native objects. It remains distinct from the seven-key owned Motion binding.
func spore_binding_error(binding: Dictionary) -> String:
	var error: String = Codec.value_error(binding)
	if not error.is_empty(): return error
	if not Codec.keys_error(binding, ["api_revision", "actor_revision", "source_id", "controller_id", "player_id", "consumer_id", "configuration", "body_signature"]).is_empty():
		return "Closed reviewed scheduler-spore-source-1 codec binding required"
	if binding.api_revision != SPORE_PROTOCOL_REVISION or binding.actor_revision != API_REVISION or not _stable_id(binding.source_id) or not _stable_id(binding.controller_id) or not _stable_id(binding.player_id) or not binding.consumer_id is String or (not binding.consumer_id.is_empty() and not _stable_id(binding.consumer_id)) or not binding.configuration is Dictionary or not binding.body_signature is Dictionary:
		return "Invalid reviewed native spore codec binding identity/configuration"
	error = configuration_error(binding.configuration)
	if not error.is_empty(): return error
	if binding.source_id != binding.configuration.source_id:
		return "Spore codec binding source differs from immutable configured source"
	var body: Dictionary = binding.body_signature
	if not Codec.keys_error(body, ["path", "centre", "shape", "layer", "mask", "priority"]).is_empty() or body.path != "BodyCollision" or not Codec.is_vector3(body.centre) or not _same(Codec.vector3(Codec.read_vector3(body.centre)), body.centre) or not body.shape is Dictionary or not body.layer is int or body.layer != 2 or not body.mask is int or body.mask != 1 or not body.priority is float or not Codec.in_range(body.priority, 0.0, 1000000000.0):
		return "Exact measured upright native Route capsule descriptor required"
	var shape: Dictionary = body.shape
	if not Codec.keys_error(shape, ["type", "margin", "custom_solver_bias", "radius", "height"]).is_empty() or shape.type != "CapsuleShape3D" or not shape.margin is float or not Codec.in_range(shape.margin, 0.0, 1000000000.0) or not shape.custom_solver_bias is float or not is_finite(shape.custom_solver_bias) or not shape.radius is float or not Codec.in_range(shape.radius, 0.000001, 10000.0) or not shape.height is float or not Codec.in_range(shape.height, 2.0 * float(shape.radius), 10000.0):
		return "Measured Route signature must retain its actual finite capsule shape data"
	return ""


func spore_record_error(actor: Dictionary, scheduler: Dictionary, player: Dictionary, binding: Dictionary) -> String:
	var error: String = spore_binding_error(binding)
	if not error.is_empty(): return error
	error = schema_error(actor, binding.configuration)
	if error.is_empty(): error = _spore_binding_correspondence_error(actor, binding)
	if not error.is_empty(): return error
	# Route requires all linear/angular axis locks false in its actual measurement.
	# Explicitly map only equivalent copied fields into Motion's exact signature;
	# retained live helper/native Scheduler guards still prove actual registration.
	return context_error(actor, scheduler, player, binding.configuration, _motion_signature_from_route(binding.body_signature))


func spore_record_view(actor: Dictionary, binding: Dictionary) -> Dictionary:
	if not spore_binding_error(binding).is_empty() or not schema_error(actor, binding.configuration).is_empty() or not _spore_binding_correspondence_error(actor, binding).is_empty():
		return {}
	var stamp: Dictionary = actor.repulsion.duplicate(true) if _bound_schema(actor) else {
		"api_revision": SPORE_ACTOR_REVISION, "consumer_id": "", "source_id": actor.source_id,
		"episode_id": "", "phase": "none", "direction": actor.motion.facing.duplicate(), "progress": 0.0}
	# Unbound projection is visibly inactive and derives direction from actual
	# saved facing. A bound source MUST carry its genuine stamp in schema3/4.
	return {"source_id": actor.source_id, "consumer_id": binding.consumer_id,
		"alive": not actor.dead and not actor.dormant, "grounded": actor.motion.grounded,
		"motion": {"position": actor.motion.position.duplicate(), "basis": _identity_basis(),
			"velocity": actor.motion.velocity.duplicate(), "facing": actor.motion.facing.duplicate()},
		"repulsion": stamp, "reservation_id": actor.reservation_id}


func _spore_binding_correspondence_error(actor: Dictionary, binding: Dictionary) -> String:
	if binding.consumer_id.is_empty():
		return "Unbound native protocol cannot accept a bound saved actor" if _bound_schema(actor) else ""
	if not _bound_schema(actor): return "Bound actual native protocol requires conditional schema3/4 stamp"
	return "Saved actor stamp differs from actual configured consumer" if actor.repulsion.consumer_id != binding.consumer_id else ""


func _motion_signature_from_route(body: Dictionary) -> Dictionary:
	return {"collision_path": body.path, "centre": body.centre.duplicate(),
		"radius": body.shape.radius, "height": body.shape.height,
		"margin": body.shape.margin, "custom_solver_bias": body.shape.custom_solver_bias,
		"layer": body.layer, "mask": body.mask, "linear_axis_locks": [false, false, false]}


func _identity_basis() -> Array:
	return [Codec.vector3(Basis.IDENTITY.x), Codec.vector3(Basis.IDENTITY.y), Codec.vector3(Basis.IDENTITY.z)]


func configuration_error(configuration: Dictionary) -> String:
	var error: String = Codec.value_error(configuration)
	if not error.is_empty(): return error
	if not Codec.keys_error(configuration, ["role_id", "entity_id", "source_id", "raw_role", "timing_floors", "lunge", "lane", "initially_dormant", "approach"]).is_empty():
		return "Complete immutable native C31/C32 configuration required"
	if configuration.role_id not in [ROLE_SWARM, ROLE_GUARD] or configuration.entity_id != ("C31" if configuration.role_id == ROLE_SWARM else "C32") or not _stable_id(configuration.source_id) or not configuration.raw_role is Dictionary or not configuration.timing_floors is Dictionary or not configuration.lunge is Dictionary or not configuration.lane is Dictionary or not configuration.initially_dormant is bool:
		return "Invalid canonical native role/entity/source/configuration types"
	if not configuration.approach is Dictionary:
		return "Complete immutable approach configuration required"
	var approach_error: String = Approach.new().configuration_error(configuration.approach)
	if not approach_error.is_empty(): return approach_error
	if configuration.role_id != ROLE_SWARM and configuration.approach.enabled:
		return "C32 cannot opt in to approach motion"
	if not Codec.keys_error(configuration.raw_role, ["raw_damage", "windup_s", "lock_s", "active_s", "recovery_s", "attack_interval_s", "max_hp", "move_speed"]).is_empty() or not Codec.keys_error(configuration.timing_floors, ["windup_s", "lock_s", "recovery_s"]).is_empty():
		return "Closed immutable raw role and timing floors required"
	var difficulty = Difficulty.new()
	for profile_id: String in ["assisted", "standard", "challenge"]:
		var resolved: Dictionary = difficulty.resolve_role(configuration.raw_role, profile_id, configuration.timing_floors)
		if resolved.is_empty(): return "Immutable native role/floors cannot resolve: " + difficulty.last_error
	if configuration.role_id == ROLE_SWARM:
		if not configuration.lane.is_empty() or not Codec.keys_error(configuration.lunge, ["speed", "distance", "damage_radius", "body_collision_path"]).is_empty():
			return "C31 requires its own native lunge and no stationary lane"
		for key: String in ["speed", "distance", "damage_radius"]:
			if not Codec.is_number(configuration.lunge[key]) or float(configuration.lunge[key]) <= 0.0: return "Positive immutable native lunge values required"
		if configuration.lunge.body_collision_path != "BodyCollision" or float(configuration.lunge.distance) / float(configuration.lunge.speed) > float(configuration.raw_role.active_s):
			return "Complete native lunge must fit its actual immutable active window"
	else:
		if not configuration.lunge.is_empty() or not Codec.keys_error(configuration.lane, ["length", "radius"]).is_empty() or not Codec.is_number(configuration.lane.length) or float(configuration.lane.length) <= 0.0 or not Codec.is_number(configuration.lane.radius) or float(configuration.lane.radius) <= 0.0:
			return "C32 requires its own positive stationary lane and no lunge"
	return ""


func schema_error(saved: Dictionary, configuration: Dictionary) -> String:
	var configuration_problem: String = configuration_error(configuration)
	if not configuration_problem.is_empty(): return configuration_problem
	var error: String = Codec.value_error(saved)
	if error.is_empty():
		var keys: Array[String] = SNAPSHOT_KEYS.duplicate()
		if _pending_schema(saved): keys.append("pending_segments")
		if _bound_schema(saved): keys.append("repulsion")
		error = Codec.keys_error(saved, keys)
	if not error.is_empty():
		return error
	if saved.api_revision != API_REVISION or not saved.schema_version is int or saved.schema_version not in [SNAPSHOT_SCHEMA_VERSION, PENDING_SNAPSHOT_SCHEMA_VERSION, BOUND_SNAPSHOT_SCHEMA_VERSION, BOUND_PENDING_SNAPSHOT_SCHEMA_VERSION] or saved.role_id != configuration.role_id or saved.source_id != configuration.source_id or not saved.configuration is Dictionary or not _same(saved.configuration, configuration) or not Codec.in_range(saved.hp, 0.0, float(configuration.raw_role.max_hp)) or not saved.dead is bool or saved.dead != (saved.hp == 0.0) or not saved.dormant is bool or not saved.motion is Dictionary or not Codec.keys_error(saved.motion, ["position", "velocity", "facing", "grounded"]).is_empty() or not saved.motion.grounded is bool:
		return "Invalid immutable C31/C32 identity/configuration/HP/motion envelope"
	for key: String in ["position", "velocity", "facing"]:
		if not Codec.is_vector3(saved.motion[key]) or not _same(Codec.vector3(Codec.read_vector3(saved.motion[key])), saved.motion[key]):
			return "C31/C32 motion requires finite serialized vectors"
	var facing: Vector3 = Codec.read_vector3(saved.motion.facing)
	if absf(facing.y) > Motion.EPSILON or absf(facing.length() - 1.0) > Motion.EPSILON or not saved.hurt_left_s is float or not Codec.in_range(saved.hurt_left_s, 0.0, HURT_S) or not saved.cycle is int or not Codec.is_integer(saved.cycle) or not saved.reservation_id is String or not saved.role_encounter_id is String or not saved.profile_id is String or not saved.resolved_role is Dictionary or not saved.sample is Dictionary or not saved.hit_ids is Array or not saved.last_cancel_reason is String:
		return "Invalid C31/C32 facing, hurt clock or exchange field types"
	if not saved.approach_driving is bool:
		return "Approach ownership requires an exact boolean"
	if _bound_schema(saved):
		if not saved.repulsion is Dictionary: return "Bound actor requires its exact genuine repulsion stamp"
		error = repulsion_error(saved.repulsion, saved.source_id)
		if not error.is_empty(): return error
		error = _spore_ownership_error(saved)
		if not error.is_empty(): return error
	if saved.approach_driving:
		var horizontal := Codec.read_vector3(saved.motion.velocity)
		horizontal.y = 0.0
		# Motion.EPSILON applies only to derived native float32 velocity magnitude,
		# never immutable tuning/copied clocks/identity/sample correspondence.
		if configuration.role_id != ROLE_SWARM or not configuration.approach.enabled or saved.dead or saved.dormant or not saved.reservation_id.is_empty() or saved.hurt_left_s != 0.0 or not saved.motion.grounded or Codec.read_vector3(saved.motion.velocity).y != 0.0 or horizontal == Vector3.ZERO or horizontal.length() > float(configuration.approach.speed) + Motion.EPSILON:
			return "Approach driving requires live grounded opt-in idle C31 owned finite motion"
	if _unowned_approach_residual(saved, configuration) and not _hurt_residual(saved) and not _external_residual(saved) and saved.last_cancel_reason != "actual_player_death":
		return "Unowned grounded C31 residual requires actual hurt, paired fatal cancellation or conditional external custody"
	if _pending_schema(saved) and (not saved.pending_segments is Array or saved.pending_segments.is_empty() or saved.pending_segments.size() > MAX_PENDING_SEGMENTS or saved.dead or saved.dormant or saved.reservation_id.is_empty() or saved.hurt_left_s != 0.0 or not saved.hit_ids.is_empty()):
		return "Pending Mushroom Selenite schema2/4 requires a bounded unconsumed path in its live unharmed exchange"
	if saved.dead and (not saved.reservation_id.is_empty() or saved.hurt_left_s != 0.0 or Codec.read_vector3(saved.motion.velocity) != Vector3.ZERO):
		return "Defeated C31/C32 cannot retain motion, hurt or a live lease"
	if saved.dormant and (not configuration.initially_dormant or saved.dead or saved.hp != float(configuration.raw_role.max_hp) or Codec.read_vector3(saved.motion.velocity) != Vector3.ZERO or saved.hurt_left_s != 0.0 or saved.cycle != 0 or not saved.role_encounter_id.is_empty() or not saved.profile_id.is_empty() or not saved.resolved_role.is_empty() or not saved.reservation_id.is_empty() or not saved.sample.is_empty() or not saved.hit_ids.is_empty() or not saved.last_cancel_reason.is_empty()):
		return "Dormant snapshot cannot invent injury, activation or combat history"
	if saved.cycle == 0:
		if not saved.role_encounter_id.is_empty() or not saved.profile_id.is_empty() or not saved.resolved_role.is_empty() or not saved.reservation_id.is_empty():
			return "Fresh C31/C32 cannot invent prior exchanges"
	else:
		if not _stable_id(saved.role_encounter_id):
			return "Executed C31/C32 requires its stable encounter epoch"
		var difficulty = Difficulty.new()
		var role: Dictionary = difficulty.resolve_role(configuration.raw_role, saved.profile_id, configuration.timing_floors)
		if role.is_empty() or not _same(role, saved.resolved_role):
			return "Saved C31/C32 role must resolve exactly from immutable raw data"
	if saved.reservation_id.is_empty():
		return "Inactive C31/C32 cannot retain sampled damage state" if not saved.sample.is_empty() or not saved.hit_ids.is_empty() else ""
	if saved.dead or saved.hurt_left_s != 0.0 or saved.cycle < 1 or not saved.reservation_id.begins_with("threat-") or not Codec.keys_error(saved.sample, ["clock_s", "source_position", "hero_position"]).is_empty() or not saved.sample.clock_s is float or not Codec.in_range(saved.sample.clock_s, 0.0, 1000000000.0) or not Codec.is_vector3(saved.sample.source_position) or not Codec.is_vector3(saved.sample.hero_position) or not _same(saved.sample.source_position, saved.motion.position):
		return "Live C31/C32 requires a coherent finite source/hero sample and unharmed lease"
	if saved.hit_ids.size() > 1 or (saved.hit_ids.size() == 1 and saved.hit_ids[0] != HERO_ID):
		return "C31/C32 hit dedupe must contain the unique actual bound hero ID"
	return ""


func context_error(saved: Dictionary, paired: Dictionary, saved_player: Dictionary, configuration: Dictionary, body_signature: Dictionary = {}) -> String:
	var error: String = schema_error(saved, configuration)
	if not error.is_empty():
		return error
	error = Codec.value_error(paired)
	if error.is_empty(): error = Codec.value_error(saved_player)
	if not error.is_empty(): return error
	if not paired.get("reservations") is Array or not paired.get("cooldowns") is Array or not paired.get("clock_s") is float or not paired.get("encounter_id") is String or not paired.get("profile") is Dictionary:
		return "Validated paired scheduler transport required"
	if _unowned_approach_residual(saved, configuration) and not _hurt_residual(saved) and not _external_residual(saved):
		if not saved_player.get("resources") is Dictionary or saved_player.resources.get("dead") != true:
			return "Unowned unharmed C31 residual requires the paired actual dead Player"
	if saved.approach_driving and (not saved_player.get("resources") is Dictionary or saved_player.resources.get("dead") != false):
		return "Driving C31 requires the separately validated living saved Player"
	var owned: Dictionary = {}
	for value: Variant in paired.reservations:
		if not value is Dictionary:
			return "Malformed paired scheduler reservation"
		if value.get("source_id") == saved.source_id:
			if not owned.is_empty():
				return "C31/C32 cannot own duplicate scheduler exchanges"
			owned = value
	if saved.dead or saved.dormant:
		for value: Variant in paired.cooldowns:
			if not value is Dictionary or value.get("source_id") == saved.source_id:
				return "Defeated/dormant C31/C32 cannot retain its owner cooldown"
	if saved.reservation_id.is_empty():
		return "Inactive C31/C32 cannot discard a scheduler lease" if not owned.is_empty() else ""
	if owned.is_empty() or owned.get("id") != saved.reservation_id or paired.encounter_id != saved.role_encounter_id or paired.profile.get("id") != saved.profile_id:
		return "Actor requires the same paired encounter/profile/reservation"
	if not _same(owned.get("source_position"), saved.motion.position) or not _same(saved.sample.clock_s, paired.clock_s):
		return "Actor motion/sample must match the exact paired source tick"
	if not saved_player.get("motion") is Dictionary or not Codec.is_vector3(saved_player.motion.get("position")) or not _same(saved.sample.hero_position, saved_player.motion.position):
		return "Hero sample must match the separately validated saved Player"
	if configuration.role_id == ROLE_SWARM:
		if not owned.get("adapter") is Dictionary or owned.adapter.get("kind") != "lunge":
			return "C31 requires its actual native ground-lunge adapter"
		var adapter: Dictionary = owned.adapter
		for key: String in ["current_position", "current_velocity", "direction"]:
			if not Codec.is_vector3(adapter.get(key)): return "Paired lunge requires finite physical motion vectors"
		if not _same(adapter.current_position, saved.motion.position) or not _same(adapter.current_velocity, saved.motion.velocity) or not _same(adapter.direction, saved.motion.facing):
			return "C31 motion must match its exact native lunge"
		for key: String in ["speed", "distance", "damage_radius", "body_collision_path"]:
			if not _same(adapter.get(key), configuration.lunge[key]): return "Paired lunge differs from canonical provisional C31 tuning"
		# Actual measurement/resource/world validity remains with the actor and
		# native Scheduler. A retained trusted native signature can also compare
		# copied envelope identity, including after genuine source removal.
		if not body_signature.is_empty() and not _same(adapter.get("body_signature"), body_signature):
			return "Native lunge must retain the actual unchanged capsule"
	else:
		if owned.has("adapter") or Codec.read_vector3(saved.motion.velocity) != Vector3.ZERO:
			return "C32 retains a stationary native lane with no motion adapter"
		var origin: Vector3 = Codec.read_vector3(saved.motion.position)
		var facing: Vector3 = Codec.read_vector3(saved.motion.facing)
		var expected_lane: Dictionary = Geometry.lane(origin, origin + facing * float(configuration.lane.length), float(configuration.lane.radius))
		if not _same(owned.get("geometry"), _encode_geometry(expected_lane)) or not _same(owned.get("opening_position"), saved.motion.position):
			return "C32 original lane and stationary opening must match its exact actual body/facing"
	var role: Dictionary = saved.resolved_role
	if not Codec.is_number(owned.get("start_s")):
		return "Paired C31/C32 start time required"
	var start_s: float = float(owned.start_s)
	var active_s: float = start_s + float(role.windup_s)
	var expected: Dictionary = {"lock_from_s": active_s - float(role.lock_s), "active_from_s": active_s, "active_until_s": active_s + float(role.active_s), "recovery_until_s": active_s + float(role.active_s) + float(role.recovery_s), "cooldown_until_s": active_s + float(role.attack_interval_s)}
	for key: String in expected:
		if not _same(owned.get(key), expected[key]):
			return "Paired C31/C32 deadlines must retain the exact resolved role arithmetic"
	if paired.clock_s < start_s or paired.clock_s > expected.recovery_until_s or (not saved.hit_ids.is_empty() and paired.clock_s < active_s):
		return "C31/C32 damage sample/dedupe cannot precede admission/activation or outlive recovery"
	var previous: Dictionary = {}
	for segment: Variant in saved.get("pending_segments", []):
		if not segment is Dictionary or not Codec.keys_error(segment, ["from", "to", "start_s", "end_s"]).is_empty() or not Codec.is_vector3(segment.from) or not Codec.is_vector3(segment.to) or not segment.start_s is float or not segment.end_s is float or not Codec.in_range(segment.start_s, start_s, float(paired.clock_s)) or not Codec.in_range(segment.end_s, float(segment.start_s), float(paired.clock_s)) or float(segment.end_s) - float(segment.start_s) > 1.0 / float(Engine.physics_ticks_per_second) + Geometry.EPSILON:
			return "Pending C31/C32 path requires finite actual single-physics-tick relative samples"
		for key: String in ["from", "to"]:
			if not _same(Codec.vector3(Codec.read_vector3(segment[key])), segment[key]):
				return "Pending C31/C32 path must retain exact native relative vectors without restore rounding"
		if segment.start_s == segment.end_s and not _same(segment.from, segment.to):
			return "A zero-time native sample cannot contain a swept relative jump"
		if not previous.is_empty() and (not _same(segment.start_s, previous.end_s) or not _same(segment.from, previous.to)):
			return "Pending C31/C32 path must preserve exact contiguous relative samples"
		previous = segment
	if not previous.is_empty():
		var relative: Vector3 = Codec.read_vector3(saved.sample.hero_position) - Codec.read_vector3(saved.sample.source_position)
		if not _same(previous.end_s, paired.clock_s) or not _same(previous.to, Codec.vector3(relative)):
			return "Pending C31/C32 path must end at the exact paired current relative position and clock"
	return ""


## Stamp validation is structural only. The parent/coordinator additionally
## proves its exact paired episode/Route and original native control custody.
func repulsion_error(stamp: Dictionary, source_id: String, consumer_id: String = "") -> String:
	var error: String = Codec.value_error(stamp)
	if not error.is_empty(): return error
	if not Codec.keys_error(stamp, REPULSION_KEYS).is_empty() or stamp.api_revision != SPORE_ACTOR_REVISION or stamp.source_id != source_id or not _stable_id(stamp.consumer_id) or (not consumer_id.is_empty() and stamp.consumer_id != consumer_id) or not stamp.episode_id is String or not stamp.phase is String or stamp.phase not in REPULSION_PHASES or not Codec.is_vector3(stamp.direction) or not _same(Codec.vector3(Codec.read_vector3(stamp.direction)), stamp.direction) or not stamp.progress is float or not Codec.in_range(stamp.progress, 0.0, 1.0):
		return "Invalid exact conditional native repulsion identity/phase/direction/progress"
	var direction: Vector3 = Codec.read_vector3(stamp.direction)
	if absf(direction.y) > Motion.EPSILON or absf(direction.length() - 1.0) > Motion.EPSILON:
		return "Repulsion stamp retains a unit native planar direction, including phase none"
	if stamp.phase == "none":
		return "" if stamp.episode_id.is_empty() and stamp.progress == 0.0 else "Inactive bound stamp cannot retain an episode/progress"
	if stamp.phase in ["hold", "regroup", "interrupted", "failed"] and stamp.progress != 0.0:
		return "Stopped/interrupted stamp cannot invent movement or recoil progress"
	if stamp.phase in ["recoil", "turn"] and stamp.progress >= 1.0:
		return "Finished recoil/turn must already publish its next native consumer phase"
	if not _stable_id(stamp.episode_id) or not stamp.episode_id.begins_with(stamp.consumer_id + "/episode-"):
		return "Active bound stamp requires the same stable consumer episode identity"
	return ""


func _spore_ownership_error(saved: Dictionary) -> String:
	if saved.dormant: return "Dormant future source cannot carry an actual environmental binding"
	var phase: String = saved.repulsion.phase
	if phase == "none": return ""
	if saved.dead or saved.approach_driving or not saved.reservation_id.is_empty() or not saved.sample.is_empty() or not saved.hit_ids.is_empty() or _pending_schema(saved):
		return "Active external episode cannot retain approach/native lease or damage opportunity"
	var motion: Vector3 = Codec.read_vector3(saved.motion.velocity)
	if phase not in ["interrupted", "failed"]:
		if saved.hurt_left_s != 0.0 or not saved.motion.grounded or motion.y != 0.0:
			return "Ordinary external episode requires unharmed actual grounded planar motion"
		# Recoil can retain the real cancellation-boundary velocity before acquire;
		# retreat may own actual Route velocity. Complete paired custody proves both.
		if phase in ["turn", "hold", "regroup"] and motion != Vector3.ZERO:
			return "Stopped external phase cannot invent retained physical velocity"
	return ""


func _pending_schema(saved: Dictionary) -> bool:
	return saved.get("schema_version") in [PENDING_SNAPSHOT_SCHEMA_VERSION, BOUND_PENDING_SNAPSHOT_SCHEMA_VERSION]


func _bound_schema(saved: Dictionary) -> bool:
	return saved.get("schema_version") in [BOUND_SNAPSHOT_SCHEMA_VERSION, BOUND_PENDING_SNAPSHOT_SCHEMA_VERSION]


func _external_residual(saved: Dictionary) -> bool:
	# This is NOT a standalone route certificate. Whole environmental prevalidation
	# is required; a reason string or unbound none stamp grants no external owner.
	return _bound_schema(saved) and saved.repulsion.phase != "none"


func _unowned_approach_residual(saved: Dictionary, configuration: Dictionary) -> bool:
	# schema_error already established every field/type before this exact check.
	var actual_velocity: Vector3 = Codec.read_vector3(saved.motion.velocity)
	return configuration.role_id == ROLE_SWARM and configuration.approach.enabled and not saved.approach_driving and saved.reservation_id.is_empty() and saved.motion.grounded and Vector3(actual_velocity.x, 0.0, actual_velocity.z) != Vector3.ZERO


func _hurt_residual(saved: Dictionary) -> bool:
	return saved.hurt_left_s > 0.0 or (saved.hp < saved.configuration.raw_role.max_hp and saved.last_cancel_reason == "actual_player_damage")


func _encode_geometry(shape: Dictionary) -> Dictionary:
	var encoded: Dictionary = shape.duplicate(true)
	for key: String in encoded:
		if encoded[key] is Vector3: encoded[key] = Codec.vector3(encoded[key])
	return encoded


func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = ExactJson.stringify(left)
	return not encoded.is_empty() and encoded == ExactJson.stringify(right)


func _stable_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 128:
		return false
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9_./:-]+$")
	var found: RegExMatch = pattern.search(value)
	return found != null and found.get_string() == value
