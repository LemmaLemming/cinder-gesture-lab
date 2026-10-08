extends RefCounted
## Owned codec for the real native test actor. Not an Ash translation, authored
## Selenite codec, replay consumer or stand-in for parent world validation.

const Exact = preload("res://scripts/campaign/exact_json.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const API: String = "scheduler-spore-fixture-actor-1"
const KEYS: Array[String] = ["api_revision", "schema_version", "source_id", "configuration", "hp", "dead", "motion", "hurt_left_s", "resolved_role", "profile_id", "reservation_id", "sample", "hit_ids", "cue", "repulsion"]


func record_error(actor: Dictionary, scheduler: Dictionary, player: Dictionary, binding: Dictionary) -> String:
	var pending: bool = actor.get("schema_version") == 2
	var keys: Array = KEYS.duplicate()
	if pending: keys.append("pending_segments")
	if Exact.stringify(actor).is_empty() or not _keys(actor, keys) or actor.api_revision != API or actor.schema_version not in [1, 2] or not actor.schema_version is int or actor.source_id != binding.source_id or binding.actor_revision != API or not _same(actor.configuration, binding.configuration):
		return "Complete genuine native fixture actor identity/configuration required"
	if not actor.hp is float or not Value.in_range(actor.hp, 0.0, float(binding.configuration.max_hp)) or not actor.dead is bool or actor.dead != (actor.hp == 0.0) or not actor.hurt_left_s is float or not Value.in_range(actor.hurt_left_s, 0.0, 0.22) or (actor.dead and actor.hurt_left_s != 0.0):
		return "Native fixture HP/death/hurt authority invalid"
	if not actor.motion is Dictionary or not _keys(actor.motion, ["position", "basis", "velocity", "facing", "grounded"]) or not actor.motion.grounded is bool or not _same(actor.motion.basis, _basis(Basis.IDENTITY)):
		return "Native fixture upright motion required"
	for key: String in ["position", "velocity", "facing"]:
		if not _vector_error(actor.motion[key]).is_empty():
			return "Native fixture exact vectors required"
	if not actor.reservation_id is String or not actor.profile_id is String or not actor.resolved_role is Dictionary or not actor.sample is Dictionary or not actor.hit_ids is Array or actor.hit_ids.size() > 1 or (not actor.hit_ids.is_empty() and actor.hit_ids[0] != "hero"):
		return "Native fixture combat custody invalid"
	if scheduler.get("api_revision") != "scheduler-snapshot-1" or scheduler.get("schema_version") != 1 or not scheduler.get("clock_s") is float or not scheduler.get("reservations") is Array or not scheduler.get("cooldowns") is Array or not scheduler.get("profile") is Dictionary or not scheduler.get("serial") is int:
		return "Complete genuine native Scheduler unit required"
	if player.get("actor_type") != "CinderPlayer" or not player.get("motion") is Dictionary:
		return "Genuine shared Player unit required"
	var own: Array = []
	for record: Variant in scheduler.reservations:
		if not record is Dictionary:
			return "Malformed native Scheduler source table"
		if record.get("source_id") == actor.source_id:
			own.append(record)
	if own.size() > 1:
		return "Duplicate native fixture lease"
	if actor.profile_id.is_empty():
		if not actor.resolved_role.is_empty():
			return "Unstarted native fixture cannot manufacture a resolved role"
	else:
		var expected: Dictionary = Difficulty.new().resolve_role(binding.configuration.raw_role, actor.profile_id, binding.configuration.timing_floors)
		if expected.is_empty() or not _same(expected, actor.resolved_role):
			return "Native role must resolve the immutable raw configuration once"
	if actor.reservation_id.is_empty():
		if not own.is_empty() or not actor.sample.is_empty() or pending:
			return "Cancelled fixture cannot hide a lease or retain attack opportunity"
	else:
		if actor.dead or actor.hurt_left_s > 0.0 or own.size() != 1 or own[0].get("id") != actor.reservation_id or actor.profile_id != scheduler.profile.get("id") or not _keys(actor.sample, ["clock_s", "source_position", "hero_position"]) or not _same(actor.sample.clock_s, scheduler.clock_s) or not _same(actor.sample.source_position, actor.motion.position) or not _same(actor.sample.hero_position, player.motion.get("position")):
			return "Native attack/sample requires its exact paired source/hero clock"
		var record: Dictionary = own[0]
		if pending:
			if not actor.pending_segments is Array or actor.pending_segments.is_empty() or actor.pending_segments.size() > 32 or not actor.hit_ids.is_empty():
				return "Native pending opportunity must be bounded and unconsumed"
			var previous: Dictionary = {}
			var tick_s: float = 1.0 / float(Engine.physics_ticks_per_second)
			for segment: Variant in actor.pending_segments:
				if not segment is Dictionary or not _keys(segment, ["from", "to", "source_from", "source_to", "start_s", "end_s"]) or not _vector_error(segment.from).is_empty() or not _vector_error(segment.to).is_empty() or not _vector_error(segment.source_from).is_empty() or not _vector_error(segment.source_to).is_empty() or not segment.start_s is float or not segment.end_s is float or not Value.in_range(segment.start_s, float(record.start_s), float(scheduler.clock_s)) or not Value.in_range(segment.end_s, float(segment.start_s), float(scheduler.clock_s)) or float(segment.end_s) - float(segment.start_s) > tick_s + 1e-9:
					return "Native pending segment must retain a genuine bounded physical interval"
				if segment.start_s == segment.end_s and (not _same(segment.from, segment.to) or not _same(segment.source_from, segment.source_to)):
					return "Zero-time native contact cannot manufacture Hero/source travel"
				if not previous.is_empty() and (not _same(previous.to, segment.from) or not _same(previous.end_s, segment.start_s) or not _same(previous.source_to, segment.source_from)):
					return "Native pending opportunity path is discontinuous"
				previous = segment
			if not _same(previous.to, actor.sample.hero_position) or not _same(previous.end_s, actor.sample.clock_s) or not _same(previous.source_to, actor.sample.source_position):
				return "Native pending opportunity must end at the actual paired Player sample"
		if not _same(record.get("source_position"), actor.motion.position) or record.get("profile_id") != actor.profile_id:
			return "Native lease pose/profile differs from real actor"
		if record.has("adapter"):
			if record.adapter.get("kind") != "lunge" or not _same(record.adapter.get("current_position"), actor.motion.position) or not _same(record.adapter.get("current_velocity"), actor.motion.velocity) or not _same(record.adapter.get("body_signature", {}).get("radius"), binding.configuration.body.radius):
				return "Native moving fixture must retain its real lunge capsule"
		elif record.get("geometry", {}).get("kind") != "lane" or not _same(record.geometry.get("from"), actor.motion.position):
			return "Native stationary fixture must retain its actual lane source"
		var start_s: float = float(record.get("start_s", -1.0))
		var active_s: float = start_s + float(actor.resolved_role.windup_s)
		var deadlines: Dictionary = {"lock_from_s": active_s - float(actor.resolved_role.lock_s), "active_from_s": active_s, "active_until_s": active_s + float(actor.resolved_role.active_s), "recovery_until_s": active_s + float(actor.resolved_role.active_s) + float(actor.resolved_role.recovery_s), "cooldown_until_s": active_s + float(actor.resolved_role.attack_interval_s)}
		for key: String in deadlines:
			if not _same(record.get(key), deadlines[key]):
				return "Native deadlines must match exact Scheduler arithmetic"
	if not actor.repulsion is Dictionary or not _keys(actor.repulsion, ["api_revision", "consumer_id", "source_id", "episode_id", "phase", "direction", "progress"]) or actor.repulsion.api_revision != "scheduler-spore-actor-1" or actor.repulsion.source_id != actor.source_id or actor.repulsion.consumer_id != binding.consumer_id:
		return "Native environmental stamp binding invalid"
	if actor.repulsion.phase != "none" and (not actor.reservation_id.is_empty() or not actor.sample.is_empty() or actor.dead):
		return "Actual spore episode suppresses the native controller exchange"
	if not actor.cue is Dictionary or not _keys(actor.cue, ["phase", "geometry", "source_position"]) or not actor.cue.phase is String or not actor.cue.geometry is Dictionary or (actor.cue.source_position != null and not _vector_error(actor.cue.source_position).is_empty()):
		return "Native cue receipt required"
	if own.is_empty():
		if actor.cue.phase != "clear" or not actor.cue.geometry.is_empty() or actor.cue.source_position != null:
			return "Cancelled native actor cannot retain a required warning"
	else:
		var record: Dictionary = own[0]
		var clock: float = float(scheduler.clock_s)
		var phase: String = "warning" if clock < float(record.lock_from_s) else ("lock" if clock < float(record.active_from_s) else ("active" if clock <= float(record.active_until_s) else "recovery"))
		if actor.cue.phase != phase or not _same(actor.cue.geometry, record.geometry) or not _same(actor.cue.source_position, actor.motion.position):
			return "Native source cue must match its exact paired geometry/phase"
	return ""


func record_view(actor: Dictionary, _binding: Dictionary) -> Dictionary:
	return {"source_id": actor.source_id, "consumer_id": actor.repulsion.consumer_id, "alive": not actor.dead, "grounded": actor.motion.grounded, "motion": {"position": actor.motion.position.duplicate(), "basis": actor.motion.basis.duplicate(true), "velocity": actor.motion.velocity.duplicate(), "facing": actor.motion.facing.duplicate()}, "repulsion": actor.repulsion.duplicate(true), "reservation_id": actor.reservation_id}


static func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = Exact.stringify(left)
	return not encoded.is_empty() and encoded == Exact.stringify(right)


static func _keys(value: Dictionary, names: Array) -> bool:
	if value.size() != names.size():
		return false
	for name: Variant in names:
		if not value.has(name):
			return false
	return true


static func _vector_error(value: Variant) -> String:
	if not value is Array or value.size() != 3:
		return "Vector must contain three native coordinates"
	for item: Variant in value:
		if not item is float or not is_finite(item):
			return "Vector must preserve finite native float components"
	return ""


static func _basis(value: Basis) -> Array:
	return [[float(value.x.x), float(value.x.y), float(value.x.z)], [float(value.y.x), float(value.y.y), float(value.y.z)], [float(value.z.x), float(value.z.y), float(value.z.z)]]
