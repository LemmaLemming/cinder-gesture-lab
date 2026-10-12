extends RefCounted
## Stateless owned court transport, authored composition and constructor plan.
## Native actor, Scheduler, Lane, physical-world, progress and optical validation
## remain parent responsibilities; this helper alone never authorizes a Save.
## No mutable fields, aliases, construction flags, Player wire or second clock.

const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Layout = preload("res://scripts/acts/act1/selenite_court_layout.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const BodySweep = preload("res://scripts/combat/body_sweep.gd")
const API_REVISION: String = "act1-court-aggregate-1"
const SCHEMA_VERSION: int = 1
const WORLD_REVISION: int = 1
const SOURCE_IDS: Array[String] = ["court-curtain-guard", "court-formation-west", "court-formation-east", "court-approach-west", "court-approach-east", "court-king", "court-helper-west", "court-helper-east"]
const HELPER_IDS: Array[String] = ["court-helper-west", "court-helper-east"]
const LOCAL_KEYS: Array[String] = ["api_revision", "schema_version", "world_revision", "room", "formation", "awaiting_room", "roundel_demonstrated", "helpers_once", "helper_stage", "entry_records", "entry_outcomes", "actors", "scheduler", "roundel", "framing"]
const ACTOR_KEYS: Array[String] = ["api_revision", "schema_version", "source_id", "configuration", "hp", "dead", "dormant", "motion", "hurt_left_s", "role_encounter_id", "profile_id", "resolved_role", "reservation_id", "cycle", "sample", "hit_ids", "last_cancel_reason"]
const SCHEDULER_KEYS: Array[String] = ["api_revision", "schema_version", "encounter_id", "profile", "world_revision", "clock_s", "serial", "collision", "reservations", "cooldowns"]
const RESERVATION_KEYS: Array[String] = ["id", "source_id", "source_position", "opening_position", "floors", "geometry", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision"]
const LANE_KEYS: Array[String] = ["api_revision", "schema_version", "mechanism_id", "configuration", "status", "phase", "cycle", "clock_s", "resolved_role", "exchange_encounter_id", "exchange", "hero_samples", "hit_ids", "last_cancel_reason"]
const FRAME_KEYS: Array[String] = ["reservation_id", "landing", "attack_position", "proof"]
const PROOF_KEYS: Array[String] = ["accepted", "path", "landing", "attack_position", "primary_time_s", "response_complete_s", "uses_blast", "uses_invulnerability", "proof_scope"]
const SEGMENT_KEYS: Array[String] = ["from", "to", "start_s", "end_s"]
const ENTRY_KEYS: Array[String] = ["active", "from", "to", "start_s", "end_s", "speed"]


## Shape only. Complete native copied payloads remain in the wire unchanged.
static func envelope_error(value: Variant) -> String:
	var error: String = Codec.value_error(value)
	if not error.is_empty(): return error
	if not value is Dictionary: return "Court aggregate must be a closed Dictionary"
	var saved: Dictionary = value
	error = Codec.keys_error(saved, LOCAL_KEYS)
	if not error.is_empty(): return error
	if saved.api_revision != API_REVISION or not saved.schema_version is int or saved.schema_version != SCHEMA_VERSION or not saved.world_revision is int or saved.world_revision != WORLD_REVISION:
		return "Unsupported exact court aggregate revision"
	if not saved.room is int or saved.room < 0 or saved.room > 4 or not saved.awaiting_room is int or saved.awaiting_room not in [-1, 1, 2, 3]:
		return "Bounded current room and awaiting boundary required"
	if not saved.formation is String or saved.formation not in ["parallel", "inward"] or not saved.helper_stage is String or saved.helper_stage not in ["unborn", "settling", "entering", "done"] or not saved.roundel_demonstrated is bool or not saved.helpers_once is bool:
		return "Closed court arrangement / roundel / helper metadata required"
	for key: String in ["entry_records", "entry_outcomes", "actors", "scheduler", "roundel", "framing"]:
		if not saved[key] is Dictionary: return "Dictionary required: " + key
	error = Codec.keys_error(saved.actors, SOURCE_IDS)
	if not error.is_empty(): return "Exact original eight-identity cast required: " + error
	for id: String in SOURCE_IDS:
		error = _actor_shape_error(saved.actors[id], id)
		if not error.is_empty(): return id + ": " + error
	error = _scheduler_shape_error(saved.scheduler)
	if not error.is_empty(): return error
	error = _lane_shape_error(saved.roundel)
	if not error.is_empty(): return error
	return _framing_error(saved)


## Authored logical stage checks, not proof of actual native playback or Save.
static func metadata_error(saved: Dictionary) -> String:
	var error: String = envelope_error(saved)
	if not error.is_empty(): return error
	if saved.room == 0 and saved.formation != "parallel": return "Formation cannot change before its own room"
	if saved.formation == "inward" and saved.actors["court-formation-west"].cycle == 0 and saved.actors["court-formation-east"].cycle == 0: return "Inward arrangement cannot skip every actual parallel cycle"
	if saved.room < 2 and saved.roundel_demonstrated: return "Roundel demonstration cannot precede approach"
	if saved.room > 2 and not saved.roundel_demonstrated: return "Later rooms require the completed roundel demonstration"
	if saved.awaiting_room >= 0 and (saved.room > 2 or saved.awaiting_room != saved.room + 1): return "Awaiting room must be the next actual cleared court boundary"
	var exposed: Array[String] = _exposed_ids(saved)
	for id: String in SOURCE_IDS:
		var actor: Dictionary = saved.actors[id]
		if actor.dormant == exposed.has(id): return "Exposure differs from the exact saved stage: " + id
		if int(Layout.SOURCES[id].room) < saved.room and id != "court-king" and not actor.dead:
			return "Earlier court source must retain genuine defeat: " + id
		if actor.dormant:
			error = _pristine_future_error(actor, id)
			if not error.is_empty(): return error
	if saved.awaiting_room >= 0 and not _current_room_dead(saved): return "Awaiting boundary requires all actual current guards defeated"
	if saved.room < 4:
		if saved.helpers_once or saved.helper_stage != "unborn" or not saved.entry_records.is_empty() or not saved.entry_outcomes.is_empty(): return "Helpers and finite entry cannot precede King phase two"
	else:
		if not saved.helpers_once or saved.helper_stage == "unborn": return "Phase two retains the once-only exposed pair"
		if float(saved.actors["court-king"].hp) > 40.0: return "Once-only helpers cannot precede the actual King half-HP boundary"
		error = _entry_error(saved)
		if not error.is_empty(): return error
	return _epoch_error(saved, exposed)


## Inputs are detached JSON-only READY-TIME fingerprints and encoded positions,
## not current moving positions and not values learned from the submitted wire.
## Parent must retain their actual native provenance before opening entitlements.
## Accepted here means construction-shape accepted ONLY. Parent still performs
## native validation, actual construction custody and complete quiet-unit proof.
static func construction_plan(saved: Dictionary, configuration_sha256: Dictionary, source_positions: Dictionary) -> Dictionary:
	var error: String = metadata_error(saved)
	if not error.is_empty(): return _rejected(error)
	error = Codec.value_error(configuration_sha256)
	if error.is_empty(): error = Codec.value_error(source_positions)
	if error.is_empty(): error = Codec.keys_error(configuration_sha256, SOURCE_IDS)
	if error.is_empty(): error = Codec.keys_error(source_positions, SOURCE_IDS)
	if not error.is_empty(): return _rejected("Closed trusted actual ready-time input maps required: " + error)
	for id: String in SOURCE_IDS:
		if not _sha256(configuration_sha256[id]) or not _native_vector(source_positions[id]) or not _same(source_positions[id], Codec.vector3(Layout.SOURCES[id].position)):
			return _rejected("Immutable actual configuration fingerprint / authored position required: " + id)
		var text: String = Exact.stringify(saved.actors[id].configuration)
		if text.is_empty() or text.sha256_text() != configuration_sha256[id]: return _rejected("Submitted configuration differs from trusted actual ready-time native bytes: " + id)
	var rooms: Array[String] = []
	for index: int in range(saved.room + 1): rooms.append(Layout.ROOM_IDS[index])
	var exposed: Array[String] = _exposed_ids(saved)
	var descriptors: Dictionary = {}
	for id: String in exposed:
		var born_room: int = int(Layout.SOURCES[id].room)
		descriptors[id] = {"api_revision": "act1-king-restore-recipient-construction-1" if id == "court-king" else "act1-restore-recipient-construction-1", "source_id": id, "room_id": Layout.ROOM_IDS[born_room], "installed_rooms": rooms.duplicate(), "installed_fields": [], "configuration_sha256": configuration_sha256[id], "authored_position": source_positions[id].duplicate()}
	return {"accepted": true, "error": "", "scope": "authored_transport_and_construction_plan_only", "installed_rooms": rooms, "installed_fields": [], "activated_source_ids": exposed, "descriptors": descriptors}


static func _actor_shape_error(value: Variant, id: String) -> String:
	if not value is Dictionary: return "Complete literal native actor envelope required"
	var actor: Dictionary = value
	var king: bool = id == "court-king"
	var keys: Array = ACTOR_KEYS.duplicate()
	if not king: keys.append_array(["role_id", "approach_driving"])
	var ordinary_schema: int = 2 if king else 1
	var pending_schema: int = 3 if king else 2
	if not actor.get("schema_version") is int or actor.schema_version not in [ordinary_schema, pending_schema]: return "Court accepts ordinary / conditional pending native schemas only"
	if actor.schema_version == pending_schema: keys.append("pending_segments")
	var error: String = Codec.keys_error(actor, keys)
	if not error.is_empty(): return error
	if actor.api_revision != ("act1-selenite-king-native-1" if king else "act1-mushroom-selenite-3") or actor.source_id != id or not actor.configuration is Dictionary:
		return "Actual source-specific native API / identity / configuration required"
	var config: Dictionary = actor.configuration
	if config.get("source_id") != id or config.get("role_id") != ("B01" if king else "A1-E3") or config.get("initially_dormant") != true or not config.get("raw_role") is Dictionary or not Codec.is_number(config.raw_role.get("max_hp")) or float(config.raw_role.max_hp) <= 0.0:
		return "Native court identity and initially-dormant immutable configuration required"
	if not king and (actor.role_id != "A1-E3" or config.get("entity_id") != "C32" or not actor.approach_driving is bool or actor.approach_driving): return "Court guard is a stationary C32 without C31 approach ownership"
	if not Codec.in_range(actor.hp, 0.0, float(config.raw_role.max_hp)) or not actor.dead is bool or actor.dead != (float(actor.hp) == 0.0) or not actor.dormant is bool or not actor.motion is Dictionary or not Codec.keys_error(actor.motion, ["position", "velocity", "facing", "grounded"]).is_empty() or not actor.motion.grounded is bool:
		return "Copied actor lifecycle / native motion envelope malformed"
	for key: String in ["position", "velocity", "facing"]:
		if not _native_vector(actor.motion[key]): return "Native vector round-trip required: " + key
	for key: String in ["role_encounter_id", "profile_id", "reservation_id", "last_cancel_reason"]:
		if not actor[key] is String: return "Native String required: " + key
	if not actor.cycle is int or not Codec.is_integer(actor.cycle) or not actor.hurt_left_s is float or not Codec.in_range(actor.hurt_left_s, 0.0, 1000000000.0) or not actor.resolved_role is Dictionary or not actor.sample is Dictionary or not actor.hit_ids is Array:
		return "Native copied exchange payload types required"
	if actor.schema_version == pending_schema:
		if not actor.pending_segments is Array or actor.pending_segments.is_empty() or actor.pending_segments.size() > 256: return "Conditional schema must retain nonempty original pending segments"
		for segment: Variant in actor.pending_segments:
			error = _segment_shape_error(segment, false)
			if not error.is_empty(): return error
	# Complete native schema/context checks deliberately remain parent-called.
	return ""


static func _scheduler_shape_error(saved: Dictionary) -> String:
	var error: String = Codec.keys_error(saved, SCHEDULER_KEYS)
	if not error.is_empty(): return "Court has no authored replay / cycle history authority: " + error
	if saved.api_revision != "scheduler-snapshot-1" or not saved.schema_version is int or saved.schema_version != 1 or not saved.encounter_id is String or not saved.profile is Dictionary or saved.world_revision != WORLD_REVISION or not saved.world_revision is int or not saved.clock_s is float or not Codec.in_range(saved.clock_s, 0.0, 1000000000.0) or not saved.serial is int or not Codec.is_integer(saved.serial) or not saved.collision is Dictionary or not saved.reservations is Array or not saved.cooldowns is Array:
		return "Exact complete ordinary native Scheduler envelope required"
	var seen: Dictionary = {}
	for value: Variant in saved.reservations:
		if not value is Dictionary or not value.get("source_id") is String or not _owner_id(value.source_id) or seen.has(value.source_id): return "Unique actual court / roundel reservation owner required"
		seen[value.source_id] = true
		var keys: Array = RESERVATION_KEYS.duplicate()
		if value.source_id == "court-king": keys.append("adapter")
		error = Codec.keys_error(value, keys)
		if not error.is_empty(): return error
		if not value.id is String or value.id.is_empty() or not _native_vector(value.source_position) or not _native_vector(value.opening_position) or not value.floors is Array or value.floors.is_empty() or not value.geometry is Dictionary or not value.profile_id is String or value.world_revision != WORLD_REVISION: return "Complete copied native reservation transport required"
		if value.source_id == "court-king" and not value.adapter is Dictionary: return "King retains its actual native lunge adapter"
		for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
			if not value[key] is float or not Codec.in_range(value[key], 0.0, 1000000000.0): return "Original native deadline must remain a finite float"
	seen.clear()
	for value: Variant in saved.cooldowns:
		if not value is Dictionary or not Codec.keys_error(value, ["source_id", "ready_s"]).is_empty() or not value.source_id is String or not _owner_id(value.source_id) or seen.has(value.source_id) or not value.ready_s is float or not Codec.in_range(value.ready_s, 0.0, 1000000000.0): return "Unique complete copied native cooldown required"
		seen[value.source_id] = true
	return ""


static func _lane_shape_error(saved: Dictionary) -> String:
	var keys: Array = LANE_KEYS.duplicate()
	if saved.get("schema_version") == 2: keys.append("pending_segments")
	var error: String = Codec.keys_error(saved, keys)
	if not error.is_empty(): return error
	if saved.api_revision != "lane-mechanism-1" or not saved.schema_version is int or saved.schema_version not in [1, 2] or saved.mechanism_id != Layout.ROUND_EL_ID or not saved.configuration is Dictionary or not saved.status is String or saved.status not in ["idle", "running", "cancelled", "complete"] or not saved.phase is String or not saved.cycle is int or not Codec.is_integer(saved.cycle) or not saved.clock_s is float or not Codec.in_range(saved.clock_s, 0.0, 1000000000.0) or not saved.resolved_role is Dictionary or not saved.exchange_encounter_id is String or not saved.exchange is Dictionary or not saved.hero_samples is Dictionary or not saved.hit_ids is Array or not saved.last_cancel_reason is String:
		return "Complete copied native roundel envelope required"
	if saved.schema_version == 2:
		if not saved.pending_segments is Dictionary or saved.pending_segments.is_empty(): return "Conditional Lane schema retains actual nonempty pending groups"
		for id: String in saved.pending_segments:
			var segments: Variant = saved.pending_segments[id]
			if id != "hero" or not segments is Array or segments.is_empty() or segments.size() > 256: return "Original bound Hero pending paths required"
			for segment: Variant in segments:
				error = _segment_shape_error(segment, false)
				if not error.is_empty(): return error
	return ""


static func _epoch_error(saved: Dictionary, exposed: Array[String]) -> String:
	var control: Dictionary = saved.scheduler
	if not _same(saved.roundel.clock_s, control.clock_s): return "Lane and Scheduler share the same exact captured clock"
	var expected: String = "court-king" if saved.room >= 3 else ("court-roundel-demonstration" if saved.room == 2 and not saved.roundel_demonstrated else "court-" + Layout.ROOM_IDS[saved.room])
	if control.encounter_id.is_empty():
		var terminal_king: bool = saved.room >= 3 and saved.actors["court-king"].dead
		if not terminal_king and not (saved.room <= 2 and _current_room_dead(saved)): return "Empty epoch requires actual cleared-room / King-death boundary"
		if saved.room == 2 and not saved.roundel_demonstrated: return "Unfinished quiet demonstration cannot become a cleared boundary"
		if not control.profile.is_empty() or not control.reservations.is_empty() or not control.cooldowns.is_empty(): return "Ended native epoch cannot retain live profile / leases / cooldowns"
	else:
		if control.encounter_id != expected or saved.awaiting_room >= 0 or control.profile.get("id") not in ["assisted", "standard", "challenge"]: return "Current authored stage must retain its exact native epoch / profile"
	if saved.room < 2 and (saved.roundel.status != "idle" or saved.roundel.cycle != 0): return "Future roundel must remain genuinely unused"
	if saved.room == 2 and not saved.roundel_demonstrated:
		if saved.roundel.status != "idle" and saved.roundel.exchange_encounter_id != "court-roundel-demonstration": return "Quiet demonstration cannot hide a combination epoch"
	elif saved.room >= 2:
		if saved.roundel.status == "idle" or saved.roundel.cycle < 1 or saved.roundel.exchange_encounter_id not in ["court-roundel-demonstration", "court-approach"]: return "Completed demonstration retains native historical exchange rather than resetting Lane"
		if saved.roundel.exchange_encounter_id == "court-approach" and saved.roundel.cycle < 2: return "Combination retains an earlier demonstration cycle without rebirth"
		if saved.roundel.exchange_encounter_id == "court-roundel-demonstration" and saved.roundel.status != "complete":
			# Native cancel also marks an already-complete historical Lane cancelled.
			# Parent legitimately retires it when guards die before any combo cycle.
			if saved.roundel.status != "cancelled" or saved.roundel.last_cancel_reason != "approach_complete" or not _approach_guards_dead(saved): return "Retain completed demo or its actual final approach retirement"
	if saved.room != 2 and saved.roundel.status == "running": return "Roundel danger cannot escape its actual approach room"
	var leases: Dictionary = {}
	for record: Dictionary in control.reservations:
		var id: String = record.source_id
		if id != Layout.ROUND_EL_ID and (not exposed.has(id) or int(Layout.SOURCES[id].room) < saved.room and id != "court-king"): return "Only current exposed actors may retain a lease"
		if id == Layout.ROUND_EL_ID and saved.room != 2: return "Roundel lease outside approach"
		leases[id] = record.id
	for id: String in SOURCE_IDS:
		var actor: Dictionary = saved.actors[id]
		if actor.reservation_id != leases.get(id, ""): return "Native actor / Scheduler lease membership differs: " + id
		if (actor.dead or actor.dormant) and leases.has(id): return "Inactive source cannot retain danger"
	if (saved.roundel.status == "running") != leases.has(Layout.ROUND_EL_ID): return "Native roundel / Scheduler live membership differs"
	for value: Dictionary in control.cooldowns:
		if value.source_id == Layout.ROUND_EL_ID:
			if saved.room != 2: return "Roundel readiness cannot escape its approach epoch"
		else:
			var actor: Dictionary = saved.actors[value.source_id]
			if actor.dead or actor.dormant or not exposed.has(value.source_id) or int(Layout.SOURCES[value.source_id].room) < saved.room and value.source_id != "court-king": return "Cooldown belongs to a retained living current source"
	return ""


static func _exposed_ids(saved: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for id: String in SOURCE_IDS:
		var born_room: int = int(Layout.SOURCES[id].room)
		if born_room > saved.room: continue
		if born_room == 2 and saved.room == 2 and not saved.roundel_demonstrated: continue
		result.append(id)
	return result


static func _pristine_future_error(actor: Dictionary, id: String) -> String:
	if actor.dead or actor.has("pending_segments") or actor.motion.grounded or actor.hp != actor.configuration.raw_role.max_hp or not _same(actor.motion.position, Codec.vector3(Layout.SOURCES[id].position)) or not _same(actor.motion.velocity, Codec.vector3(Vector3.ZERO)) or not _same(actor.motion.facing, Codec.vector3(Vector3.FORWARD)) or actor.hurt_left_s != 0.0 or actor.cycle != 0 or not actor.role_encounter_id.is_empty() or not actor.profile_id.is_empty() or not actor.resolved_role.is_empty() or not actor.reservation_id.is_empty() or not actor.sample.is_empty() or not actor.hit_ids.is_empty() or not actor.last_cancel_reason.is_empty(): return "Future source must retain exact pristine dormant authored native state: " + id
	return ""


static func _current_room_dead(saved: Dictionary) -> bool:
	for id: String in Layout.ROOM_SOURCE_IDS[saved.room]:
		if not saved.actors[id].dead: return false
	return true


static func _approach_guards_dead(saved: Dictionary) -> bool:
	for id: String in Layout.ROOM_SOURCE_IDS[2]:
		if not saved.actors[id].dead: return false
	return true


static func _entry_error(saved: Dictionary) -> String:
	for id: String in saved.entry_records:
		if id not in HELPER_IDS: return "Entry belongs only to the original finite helper pair"
	for id: String in saved.entry_outcomes:
		if id not in HELPER_IDS: return "Entry outcomes belong only to the original finite helper pair"
	if saved.helper_stage == "settling" and not saved.entry_records.is_empty(): return "Original entry plans are authored only after actual settling"
	var shared_start: Variant = null
	for id: String in saved.entry_records:
		var value: Variant = saved.entry_records[id]
		if not value is Dictionary or not Codec.keys_error(value, ENTRY_KEYS).is_empty() or not value.active is bool or value.active != true or not _native_vector(value.from) or not _native_vector(value.to) or not value.start_s is float or not value.end_s is float or not value.speed is float or not Codec.in_range(value.start_s, 0.0, 1000000000.0) or not Codec.in_range(value.end_s, value.start_s, 1000000000.0): return "Exact encoded six-key original finite entry record required"
		var origin: Vector3 = Codec.read_vector3(value.from)
		var goal: Vector3 = Codec.read_vector3(value.to)
		var authored: Vector3 = Layout.SOURCES[id].position
		if origin.x != authored.x or origin.z != authored.z or absf(origin.y - authored.y) > 0.02 or not _same(value.to, Codec.vector3(origin + Vector3.BACK * Layout.HELPER_ENTRY_DISTANCE)) or value.speed != Layout.HELPER_ENTRY_SPEED or value.end_s != value.start_s + Layout.HELPER_ENTRY_DURATION or saved.scheduler.clock_s < value.start_s: return "Retain authored settled origin, original .7-unit path, 1.4 speed and .5 deadline"
		if shared_start == null: shared_start = value.start_s
		elif not _same(shared_start, value.start_s): return "The same once-only pair retains its one original entry start"
		if not saved.entry_outcomes.has(id):
			if saved.helper_stage != "entering": return "Unretired entry exists only during actual entering stage"
			var actor: Dictionary = saved.actors[id]
			# A real injury/death can precede the parent's next outcome callback.
			if not actor.dead and actor.hp == actor.configuration.raw_role.max_hp:
				var position: Vector3 = Codec.read_vector3(actor.motion.position)
				var velocity: Vector3 = Codec.read_vector3(actor.motion.velocity)
				if actor.dormant or actor.hurt_left_s != 0.0 or not actor.reservation_id.is_empty() or actor.cycle != 0 or not actor.role_encounter_id.is_empty() or not actor.profile_id.is_empty() or not actor.resolved_role.is_empty() or not actor.last_cancel_reason.is_empty() or not actor.motion.grounded or absf(position.x - origin.x) > Motion.EPSILON or absf(position.y - origin.y) > Motion.EPSILON or position.z < origin.z - Motion.EPSILON or position.z > goal.z + Motion.EPSILON or velocity.x != 0.0 or velocity.y != 0.0 or velocity.z < 0.0 or velocity.z > Layout.HELPER_ENTRY_SPEED + Motion.EPSILON: return "Unretired pristine helper retains genuine bounded grounded unleased entry motion"
				var elapsed: float = clampf(saved.scheduler.clock_s - value.start_s, 0.0, Layout.HELPER_ENTRY_DURATION)
				var expected: Vector3 = BodySweep.anchored_position(origin, Vector3.BACK, Layout.HELPER_ENTRY_SPEED * elapsed)
				# Match the actual native clock-anchored primitive's represented
				# coordinate arithmetic. This bound never authorizes retiming or a
				# missing physics step. Parent must certify capture after the owned
				# movement callback has settled, or reject that pending boundary.
				if position.distance_to(expected) > BodySweep.position_rounding_bound(position, expected): return "Entry preserves its original-clock native anchor without catch-up"
	for id: String in saved.entry_outcomes:
		var value: Variant = saved.entry_outcomes[id]
		if not value is Dictionary or not Codec.keys_error(value, ["outcome", "endpoint"]).is_empty() or not value.outcome is String or value.outcome not in ["injured", "defeated", "blocked", "complete", "king_defeated"] or not _native_vector(value.endpoint): return "Closed literal original entry outcome and actual retirement endpoint required"
		var actor: Dictionary = saved.actors[id]
		if value.outcome == "injured" and actor.hp >= actor.configuration.raw_role.max_hp: return "Injured retirement cannot invent full-HP injury history"
		if value.outcome == "defeated" and not actor.dead: return "Defeated retirement requires actual retained death"
		if value.outcome == "king_defeated" and not saved.actors["court-king"].dead: return "Terminal entry stop requires actual King defeat"
		if value.outcome in ["complete", "blocked", "king_defeated"]:
			if not saved.entry_records.has(id): return "This outcome retains the original finite entry record"
			var record: Dictionary = saved.entry_records[id]
			var origin: Vector3 = Codec.read_vector3(record.from)
			var goal: Vector3 = Codec.read_vector3(record.to)
			var endpoint: Vector3 = Codec.read_vector3(value.endpoint)
			# Retirement endpoint is history, not a substitute for later hurt motion.
			if value.outcome == "complete":
				if saved.scheduler.clock_s < record.end_s or absf(endpoint.y - origin.y) > BodySweep.position_rounding_bound(endpoint, origin) or Vector2(endpoint.x - goal.x, endpoint.z - goal.z).length() > Motion.ENDPOINT_TOLERANCE: return "Completed entry preserves its genuine reached endpoint and original deadline"
			elif value.outcome == "blocked" and (absf(endpoint.x - origin.x) > Motion.EPSILON or absf(endpoint.y - origin.y) > Motion.EPSILON or endpoint.z < origin.z - Motion.EPSILON or endpoint.z > goal.z + Motion.EPSILON): return "Blocked entry preserves the actual shortened grounded corridor endpoint"
		elif not saved.entry_records.has(id) and saved.helper_stage != "settling" and value.outcome not in ["injured", "defeated"]: return "Outcome without a plan must precede finite motion"
	if saved.helper_stage in ["entering", "done"]:
		for id: String in HELPER_IDS:
			if not saved.entry_records.has(id) and not saved.entry_outcomes.has(id): return "Each once-born helper retains its plan or actual early retirement"
	if saved.helper_stage == "done":
		for id: String in HELPER_IDS:
			if not saved.entry_outcomes.has(id): return "Done entry retains both genuine retirement outcomes"
	# Native active-step cadence / BodySweep / whole optical and scene custody
	# remain parent obligations, including fresh replay of unfinished entry.
	return ""


static func _framing_error(saved: Dictionary) -> String:
	var leases: Dictionary = {}
	for record: Dictionary in saved.scheduler.reservations: leases[record.source_id] = record
	var error: String = Codec.keys_error(saved.framing, leases.keys())
	if not error.is_empty(): return "Original witnesses cover exactly all captured live native leases"
	for id: String in saved.framing:
		var value: Variant = saved.framing[id]
		var record: Dictionary = leases[id]
		if not value is Dictionary or not Codec.keys_error(value, FRAME_KEYS).is_empty() or value.reservation_id != record.id or not _native_vector(value.landing) or not _native_vector(value.attack_position) or not value.proof is Dictionary: return "Original four-key response witness and complete proof required"
		var proof: Dictionary = value.proof
		if not Codec.keys_error(proof, PROOF_KEYS).is_empty() or not proof.accepted is bool or proof.accepted != true or not proof.uses_blast is bool or proof.uses_blast != false or not proof.uses_invulnerability is bool or proof.uses_invulnerability != false or proof.proof_scope != "static_box_floor_full_dash_stationary_primary" or not proof.path is Array or proof.path.size() not in [4, 6] or not _same(proof.landing, value.landing) or not _same(proof.attack_position, value.attack_position) or not proof.primary_time_s is float or not proof.response_complete_s is float: return "Full original ordinary-only native proof transport required"
		if not Codec.in_range(proof.primary_time_s, record.active_until_s, record.recovery_until_s) or proof.response_complete_s < proof.primary_time_s or proof.response_complete_s >= record.recovery_until_s: return "Original primary and complete response fit the committed recovery interval"
		var kinds: Array = ["recognition_and_ready", "escape_dash", "recovery_wait", "ordinary_primary"] if proof.path.size() == 4 else ["recognition_and_ready", "escape_dash", "recovery_wait", "positioning_dash", "primary_ready", "ordinary_primary"]
		var previous: Dictionary = {}
		for index: int in range(proof.path.size()):
			var segment: Variant = proof.path[index]
			error = _segment_shape_error(segment, true)
			if not error.is_empty(): return error
			if segment.kind != kinds[index]: return "Original native ordinary path segment order required"
			if index == 0 and not _same(segment.start_s, record.start_s): return "Original accepted response begins at its actual reservation start"
			if not previous.is_empty() and (not _same(previous.end_s, segment.start_s) or not _same(previous.to, segment.from)): return "Original path retains literal contiguous endpoints / times"
			if segment.kind not in ["escape_dash", "positioning_dash"] and not _same(segment.from, segment.to): return "Native wait / ordinary primary cannot hide travel"
			previous = segment
		if not _same(proof.path[1].to, value.landing) or not _same(previous.from, value.attack_position) or not _same(previous.to, value.attack_position) or not _same(previous.start_s, proof.primary_time_s) or not _same(previous.end_s, proof.response_complete_s): return "Full path preserves original landing / primary endpoint and timing"
	# Native proof provenance, physical support/escape, source opening and camera
	# fit are NOT inferred from these copied values; actual parent must prove them.
	return ""


static func _segment_shape_error(value: Variant, has_kind: bool) -> String:
	var keys: Array = SEGMENT_KEYS.duplicate()
	if has_kind: keys.append("kind")
	if not value is Dictionary or not Codec.keys_error(value, keys).is_empty() or not _native_vector(value.from) or not _native_vector(value.to) or not value.start_s is float or not value.end_s is float or not Codec.in_range(value.start_s, 0.0, 1000000000.0) or not Codec.in_range(value.end_s, value.start_s, 1000000000.0): return "Complete literal native finite path segment required"
	if has_kind and not value.kind is String: return "Native path kind must remain a String"
	if value.start_s == value.end_s and not _same(value.from, value.to): return "Zero-time segment cannot contain displacement"
	return ""


static func _native_vector(value: Variant) -> bool:
	return Codec.is_vector3(value) and _same(value, Codec.vector3(Codec.read_vector3(value)))


static func _same(left: Variant, right: Variant) -> bool:
	var text: String = Exact.stringify(left)
	return not text.is_empty() and text == Exact.stringify(right)


static func _sha256(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for index: int in range(64):
		if "0123456789abcdef".find(value.substr(index, 1)) < 0: return false
	return true


static func _owner_id(id: String) -> bool:
	return id in SOURCE_IDS or id == Layout.ROUND_EL_ID


static func _rejected(error: String) -> Dictionary:
	return {"accepted": false, "error": error}
