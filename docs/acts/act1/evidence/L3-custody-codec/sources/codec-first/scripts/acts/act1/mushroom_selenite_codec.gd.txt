class_name Act1MushroomSeleniteCodec
extends RefCounted
## Pure native-envelope extraction used by the owned actor. No nodes, clocks, repulsion stamp,
## environmental hooks or controller authority. Current actor API/schema are
## unchanged; prospective environmental binding/publication remains separate.
##
## schema_error/context_error form the stable core. Complete Player/Scheduler
## units must ALSO pass their existing shared validators before this logical
## correspondence check; it never replaces physical/native world validation.
## record_error/record_view use an OWNED draft binding, deliberately distinct
## from the unpublished scheduler-spore protocol. Its wrapper may change later.
## record_view is a native logical view, NOT a coordinator repulsion view.

const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const API_REVISION: String = "act1-mushroom-selenite-1"
const SNAPSHOT_SCHEMA_VERSION: int = 1
const PENDING_SNAPSHOT_SCHEMA_VERSION: int = 2
const MAX_PENDING_SEGMENTS: int = 256
const HURT_S: float = 0.22
const HERO_ID: String = "hero"
const ROLE_SWARM: String = "A1-E2"
const ROLE_GUARD: String = "A1-E3"
const BINDING_REVISION: String = "act1-mushroom-selenite-codec-binding-1"
const VIEW_REVISION: String = "act1-mushroom-selenite-native-view-1"
const SNAPSHOT_KEYS: Array[String] = ["api_revision", "schema_version", "role_id", "source_id", "configuration", "hp", "dead", "dormant", "motion", "hurt_left_s", "role_encounter_id", "profile_id", "resolved_role", "reservation_id", "cycle", "sample", "hit_ids", "last_cancel_reason"]


func record_error(actor: Dictionary, scheduler: Dictionary, player: Dictionary, binding: Dictionary) -> String:
	var error: String = binding_error(binding)
	if not error.is_empty(): return error
	# The caller resolved stable controller/player map IDs to these complete
	# separately validated units. Ordinary actor envelopes do not store those IDs.
	return context_error(actor, scheduler, player, binding.configuration, binding.body_signature)


func record_view(actor: Dictionary, binding: Dictionary) -> Dictionary:
	# Caller first runs record_error against complete paired context. This pure
	# query repeats the complete native schema/config check, then only copies
	# genuine resources/motion. It cannot prove context using its two arguments.
	if not binding_error(binding).is_empty() or not schema_error(actor, binding.configuration).is_empty():
		return {}
	return {"api_revision": VIEW_REVISION, "actor_revision": API_REVISION,
		"source_id": actor.source_id, "controller_id": binding.controller_id,
		"player_id": binding.player_id, "role_id": actor.role_id,
		"entity_id": binding.configuration.entity_id, "hp": actor.hp,
		"max_hp": binding.configuration.raw_role.max_hp,
		"alive": not actor.dead and not actor.dormant, "dead": actor.dead,
		"dormant": actor.dormant, "grounded": actor.motion.grounded,
		"motion": actor.motion.duplicate(true), "hurt_left_s": actor.hurt_left_s,
		"reservation_id": actor.reservation_id, "cycle": actor.cycle}


func binding_error(binding: Dictionary) -> String:
	var error: String = Codec.value_error(binding)
	if not error.is_empty(): return error
	if not Codec.keys_error(binding, ["api_revision", "actor_revision", "source_id", "controller_id", "player_id", "configuration", "body_signature"]).is_empty():
		return "Closed owned native codec binding required; proposed environmental bindings are not adopted"
	if binding.api_revision != BINDING_REVISION or binding.actor_revision != API_REVISION or not _stable_id(binding.source_id) or not _stable_id(binding.controller_id) or not _stable_id(binding.player_id) or not binding.configuration is Dictionary or not binding.body_signature is Dictionary:
		return "Invalid stable native codec binding identity/configuration/signature"
	error = configuration_error(binding.configuration)
	if not error.is_empty(): return error
	if binding.source_id != binding.configuration.source_id:
		return "Native codec binding source must match the actual immutable configured source"
	# This is the retained Motion native signature, not Route's distinct measured
	# environment/body descriptor. Native source validation owns the measurement.
	if not Codec.keys_error(binding.body_signature, ["collision_path", "centre", "radius", "height", "margin", "custom_solver_bias", "layer", "mask", "linear_axis_locks"]).is_empty():
		return "Retained exact native capsule signature required"
	var body: Dictionary = binding.body_signature
	if body.collision_path != "BodyCollision" or not Codec.is_vector3(body.centre) or not _same(Codec.vector3(Codec.read_vector3(body.centre)), body.centre) or not Codec.is_number(body.radius) or float(body.radius) <= 0.0 or not Codec.is_number(body.height) or float(body.height) < 2.0 * float(body.radius) or not Codec.is_number(body.margin) or float(body.margin) < 0.0 or not Codec.is_number(body.custom_solver_bias) or not body.layer is int or body.layer != 2 or not body.mask is int or body.mask != 1 or not body.linear_axis_locks is Array or body.linear_axis_locks.size() != 3:
		return "Invalid measured native capsule signature values"
	for flag: Variant in body.linear_axis_locks:
		if not flag is bool: return "Native capsule axis lock signature requires actual booleans"
	return ""


func configuration_error(configuration: Dictionary) -> String:
	var error: String = Codec.value_error(configuration)
	if not error.is_empty(): return error
	if not Codec.keys_error(configuration, ["role_id", "entity_id", "source_id", "raw_role", "timing_floors", "lunge", "lane", "initially_dormant"]).is_empty():
		return "Complete immutable native C31/C32 configuration required"
	if configuration.role_id not in [ROLE_SWARM, ROLE_GUARD] or configuration.entity_id != ("C31" if configuration.role_id == ROLE_SWARM else "C32") or not _stable_id(configuration.source_id) or not configuration.raw_role is Dictionary or not configuration.timing_floors is Dictionary or not configuration.lunge is Dictionary or not configuration.lane is Dictionary or not configuration.initially_dormant is bool:
		return "Invalid canonical native role/entity/source/configuration types"
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
		if saved.get("schema_version") == PENDING_SNAPSHOT_SCHEMA_VERSION: keys.append("pending_segments")
		error = Codec.keys_error(saved, keys)
	if not error.is_empty():
		return error
	if saved.api_revision != API_REVISION or not saved.schema_version is int or saved.schema_version not in [SNAPSHOT_SCHEMA_VERSION, PENDING_SNAPSHOT_SCHEMA_VERSION] or saved.role_id != configuration.role_id or saved.source_id != configuration.source_id or not saved.configuration is Dictionary or not _same(saved.configuration, configuration) or not Codec.in_range(saved.hp, 0.0, float(configuration.raw_role.max_hp)) or not saved.dead is bool or saved.dead != (saved.hp == 0.0) or not saved.dormant is bool or not saved.motion is Dictionary or not Codec.keys_error(saved.motion, ["position", "velocity", "facing", "grounded"]).is_empty() or not saved.motion.grounded is bool:
		return "Invalid immutable C31/C32 identity/configuration/HP/motion envelope"
	for key: String in ["position", "velocity", "facing"]:
		if not Codec.is_vector3(saved.motion[key]) or not _same(Codec.vector3(Codec.read_vector3(saved.motion[key])), saved.motion[key]):
			return "C31/C32 motion requires finite serialized vectors"
	var facing: Vector3 = Codec.read_vector3(saved.motion.facing)
	if absf(facing.y) > Motion.EPSILON or absf(facing.length() - 1.0) > Motion.EPSILON or not saved.hurt_left_s is float or not Codec.in_range(saved.hurt_left_s, 0.0, HURT_S) or not saved.cycle is int or not Codec.is_integer(saved.cycle) or not saved.reservation_id is String or not saved.role_encounter_id is String or not saved.profile_id is String or not saved.resolved_role is Dictionary or not saved.sample is Dictionary or not saved.hit_ids is Array or not saved.last_cancel_reason is String:
		return "Invalid C31/C32 facing, hurt clock or exchange field types"
	if saved.schema_version == PENDING_SNAPSHOT_SCHEMA_VERSION and (not saved.pending_segments is Array or saved.pending_segments.is_empty() or saved.pending_segments.size() > MAX_PENDING_SEGMENTS or saved.dead or saved.dormant or saved.reservation_id.is_empty() or saved.hurt_left_s != 0.0 or not saved.hit_ids.is_empty()):
		return "Pending Mushroom Selenite schema2 requires a bounded unconsumed path in its live unharmed exchange"
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
