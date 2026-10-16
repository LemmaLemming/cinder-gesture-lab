extends RefCounted
## Pure A1-L5 metadata envelope, not Save authorization or another save system.
## Keep every native packet, conditional pending suffix and schema-4 adapter intact.
## Parent validates native internals, construction, current-view proof and checkpoint
## history separately, then quietly commits Player -> eye -> Scheduler -> sources.
## Sneeze demonstration is a once-latched parent fact: the first exchange can
## prove its completed active interval; later cycles preserve it through new
## warning/active windows. The latest native packet does not replay old history.

const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Layout = preload("res://scripts/acts/act1/living_moon_layout.gd")
const API_REVISION: String = "act1-living-moon-level-2"
const SCHEMA_VERSION: int = 2
const LEGACY_API_REVISION: String = "act1-living-moon-level-1"
const LEGACY_SCHEMA_VERSION: int = 1
const WORLD_REVISION: int = 1
const LEGACY_LOCAL_KEYS: Array[String] = ["api_revision", "schema_version", "world_revision", "stage", "impact_demonstrated", "sneeze_demonstrated", "next_attack", "pending_phase", "escape", "actors", "eye", "scheduler", "impact", "nose", "blink", "framing"]
const LOCAL_KEYS: Array[String] = ["api_revision", "schema_version", "world_revision", "stage", "impact_demonstrated", "sneeze_demonstrated", "next_attack", "pending_phase", "escape", "actors", "eye", "scheduler", "impact", "nose", "blink", "framing", "final_arrangement"]
const FINAL_ARRANGEMENTS_PATH: String = "res://data/campaign/act1/a1_l5_difficulty_arrangements.json"
const FINAL_PROFILES: Array[String] = ["assisted", "standard", "challenge"]
const FINAL_ARRANGEMENT_KEYS: Array[String] = ["profile_id", "recipe_id", "initial_attack"]
static var _final_definition: Variant = JSON.parse_string(FileAccess.get_file_as_string(FINAL_ARRANGEMENTS_PATH))
const STAGES: Array[String] = ["return", "capsule", "blink", "sneeze", "final", "hatch", "escape", "departed"]
const SOURCE_IDS: Array[String] = ["moon-return-impact", "moon-return-rusher", "moon-eye", "moon-nose"]
const ESCAPE_KEYS: Array[String] = ["started", "from_s", "until_s", "finished", "contact_position"]
const FRAME_KEYS: Array[String] = ["reservation_id", "proof"]
const PROOF_KEYS: Array[String] = ["accepted", "path", "landing", "attack_position", "primary_time_s", "response_complete_s", "uses_blast", "uses_invulnerability", "proof_scope"]
const PATH_KEYS: Array[String] = ["from", "to", "start_s", "end_s", "kind"]


static func envelope_error(value: Variant) -> String:
	if Exact.stringify(value).is_empty(): return "L5 requires complete exact typed closed transport"
	if not value is Dictionary: return "L5 local state must be a closed Dictionary"
	var saved: Dictionary = value
	var legacy: bool = saved.get("api_revision") == LEGACY_API_REVISION and saved.get("schema_version") is int and saved.schema_version == LEGACY_SCHEMA_VERSION
	var current: bool = saved.get("api_revision") == API_REVISION and saved.get("schema_version") is int and saved.schema_version == SCHEMA_VERSION
	if not legacy and not current: return "Unsupported exact L5 metadata revision"
	var error: String = Codec.keys_error(saved, LEGACY_LOCAL_KEYS if legacy else LOCAL_KEYS)
	if not error.is_empty(): return error
	if not saved.world_revision is int or saved.world_revision != WORLD_REVISION:
		return "Unsupported exact L5 metadata revision"
	if not saved.stage is String or saved.stage not in STAGES or not saved.next_attack is String or saved.next_attack not in ["blink", "sneeze"] or not saved.pending_phase is int or saved.pending_phase not in [0, 2, 3]:
		return "Closed L5 stage, next attack and deferred phase required"
	if not saved.impact_demonstrated is bool or not saved.sneeze_demonstrated is bool: return "Actual demonstration flags must remain booleans"
	for key: String in ["escape", "actors", "eye", "scheduler", "impact", "nose", "blink", "framing"]:
		if not saved[key] is Dictionary: return "Complete dictionary required: " + key
	if not Codec.keys_error(saved.actors, [Layout.RUSHER_ID]).is_empty(): return "Exact native return-rusher cast required"
	if not saved.actors[Layout.RUSHER_ID] is Dictionary or saved.actors[Layout.RUSHER_ID].is_empty(): return "Complete native return-rusher packet required"
	for key: String in ["eye", "scheduler", "impact", "nose", "blink"]:
		if saved[key].is_empty(): return "Complete unstripped native packet required: " + key
	if saved.actors[Layout.RUSHER_ID].get("source_id") != Layout.RUSHER_ID or saved.eye.get("source_id") != Layout.EYE_ID or saved.nose.get("source_id") != Layout.NOSE_ID or saved.impact.get("mechanism_id") != Layout.IMPACT_ID:
		return "Packets must retain their actual L5 source identities"
	if not saved.blink.get("source_binding") is Dictionary or saved.blink.source_binding.get("source_id") != Layout.EYE_ID: return "Blink retains the actual eye's complete native source binding"
	if saved.scheduler.get("api_revision") != "scheduler-snapshot-1" or not saved.scheduler.get("schema_version") is int or saved.scheduler.schema_version != 4 or not saved.scheduler.get("world_revision") is int or saved.scheduler.world_revision != WORLD_REVISION or not saved.scheduler.get("clock_s") is float or not Codec.in_range(saved.scheduler.clock_s, 0.0, 1000000000.0) or not saved.scheduler.get("reservations") is Array:
		return "L5 retains complete native schema-4 Scheduler and its original float clock"
	if not saved.scheduler.get("profile") is Dictionary or not saved.scheduler.profile.get("id") is String or saved.scheduler.profile.id not in FINAL_PROFILES:
		return "L5 retains its actual entry-resolved native Scheduler profile"
	if current:
		error = final_arrangement_error(saved.final_arrangement)
		if not error.is_empty(): return error
		if saved.final_arrangement.profile_id != saved.scheduler.profile.id:
			return "Final arrangement differs from the saved native entry profile"
	error = _escape_error(saved)
	return _framing_error(saved) if error.is_empty() else error


## This table selects only the first phase-three attack. It changes no source
## definition, timing, geometry or later accepted-start alternation.
static func arrangement_configuration_error() -> String:
	if not _final_definition is Dictionary or not Codec.keys_error(_final_definition, ["schema_version", "level_id", "arrangements"]).is_empty():
		return "Closed L5 final arrangement definitions required"
	if not Codec.is_integer(_final_definition.schema_version, 1, 1) or _final_definition.level_id != "A1-L5" or not _final_definition.arrangements is Array or _final_definition.arrangements.size() != FINAL_PROFILES.size():
		return "Exact L5 final arrangement table required"
	var seen: Array[String] = []
	for value: Variant in _final_definition.arrangements:
		if not value is Dictionary or not Codec.keys_error(value, FINAL_ARRANGEMENT_KEYS).is_empty(): return "Closed final arrangement row required"
		if not value.profile_id is String or value.profile_id not in FINAL_PROFILES or seen.has(value.profile_id): return "Each native profile requires one final arrangement"
		var attack: String = "sneeze" if value.profile_id == "challenge" else "blink"
		var recipe: String = "A1-L5/final-" + attack + "-leads@v1"
		if not value.recipe_id is String or value.recipe_id != recipe or not value.initial_attack is String or value.initial_attack != attack:
			return "Final arrangement must retain the authorized initial leader"
		seen.append(value.profile_id)
	return ""


static func fresh_final_arrangement(profile_id: String) -> Dictionary:
	if not arrangement_configuration_error().is_empty(): return {}
	for value: Dictionary in _final_definition.arrangements:
		if value.profile_id == profile_id: return value.duplicate(true)
	return {}


static func final_arrangement_error(value: Variant) -> String:
	if not value is Dictionary or not Codec.keys_error(value, FINAL_ARRANGEMENT_KEYS).is_empty(): return "Closed final arrangement descriptor required"
	for key: String in FINAL_ARRANGEMENT_KEYS:
		if not value[key] is String: return "Final arrangement descriptor retains exact strings"
	var error: String = arrangement_configuration_error()
	if not error.is_empty(): return error
	var expected: Dictionary = fresh_final_arrangement(value.profile_id)
	return "" if not expected.is_empty() and _same(value, expected) else "Unknown or inconsistent final arrangement descriptor"


## Metadata coherence only. A copied wire cannot establish native provenance.
static func metadata_error(saved: Dictionary) -> String:
	var error: String = envelope_error(saved)
	if not error.is_empty(): return error
	var eye: Dictionary = saved.eye
	if not eye.get("phase") is int or eye.phase not in [1, 2, 3] or not eye.get("dead") is bool or not eye.get("hp") is float or not Codec.in_range(eye.hp, 0.0, Layout.BOSS_MAX_HP) or eye.dead != (eye.hp == 0.0): return "Native eye HP, phase and death metadata required"
	var expected_phase: int = 1 if eye.hp > Layout.BOSS_PHASE_THRESHOLDS[0] else (2 if eye.hp > Layout.BOSS_PHASE_THRESHOLDS[1] else 3)
	if eye.phase != expected_phase: return "Eye phase must follow the immutable genuine HP thresholds"
	if saved.stage in ["return", "capsule"]:
		if eye.dead or eye.phase != 1 or not _same(eye.hp, Layout.BOSS_MAX_HP) or saved.pending_phase != 0: return "Return and capsule retain the pristine, unexposed living eye"
	elif saved.stage in ["blink", "sneeze", "final"]:
		if eye.dead: return "Committed eye defeat must already be hatch stage after the settled observer"
		var stage_phase: int = {"blink": 1, "sneeze": 2, "final": 3}[saved.stage]
		if saved.pending_phase == 0:
			if eye.phase != stage_phase: return "Stable boss stage must match its actual eye phase"
		elif saved.pending_phase != stage_phase + 1 or saved.pending_phase != eye.phase or saved.stage == "final":
			return "Deferred phase is only the actual committed next HP phase before parent transition"
	else:
		if not eye.dead or eye.phase != 3 or saved.pending_phase != 0: return "Hatch, escape and departure require genuine committed eye defeat"
	if saved.stage != "return":
		if not saved.impact_demonstrated or not saved.actors[Layout.RUSHER_ID].get("dead") is bool or saved.actors[Layout.RUSHER_ID].dead != true: return "Capsule and all later beats retain the completed impact and genuine rusher defeat"
	if saved.impact_demonstrated:
		error = _demonstration_error(saved.impact, saved.scheduler.clock_s, "impact")
		if not error.is_empty(): return error
	if saved.stage in ["return", "capsule", "blink"] and saved.sneeze_demonstrated: return "Sneeze cannot be demonstrated before its authored phase"
	if saved.sneeze_demonstrated:
		error = _demonstration_error(saved.nose, saved.scheduler.clock_s, "Sneeze")
		if not error.is_empty(): return error
	if (saved.pending_phase == 3 or saved.stage in ["final", "hatch", "escape", "departed"]) and not saved.sneeze_demonstrated: return "Later beats require the real Sneeze active interval to have ended"
	if saved.stage in ["return", "capsule"] and (saved.nose.get("cycle") != 0 or saved.blink.get("cycle") != 0): return "Boss sources cannot start before the blocked-capsule preview"
	if saved.stage == "blink" and saved.nose.get("cycle") != 0: return "First Blink phase cannot hide a premature Sneeze cycle"
	return ""


static func _demonstration_error(packet: Dictionary, clock_s: float, label: String) -> String:
	if not packet.get("cycle") is int or packet.cycle < 1 or not packet.get("exchange") is Dictionary or packet.exchange.is_empty(): return label + " demonstration retains its genuine native cycle and exchange"
	if label == "impact" and packet.cycle != 1: return "Return impact is one finite original demonstration"
	if packet.get("status") not in ["running", "complete", "cancelled"]: return label + " demonstration cannot replace native cycle history"
	var exchange: Dictionary = packet.exchange
	if not exchange.get("active_from_s") is float or not exchange.get("active_until_s") is float or not Codec.in_range(exchange.active_from_s, 0.0, 1000000000.0) or not Codec.in_range(exchange.active_until_s, exchange.active_from_s, 1000000000.0) or exchange.active_until_s <= exchange.active_from_s: return label + " retains the original nonempty actual active interval"
	if label == "Sneeze" and packet.cycle > 1:
		# Parent latches only from a genuine recovery observer. A later admitted
		# cycle replaces exchange; keeping the boolean does not reset the source.
		return ""
	if clock_s < exchange.active_until_s: return label + " demonstration cannot precede its actual active end"
	if packet.get("status") == "running" and packet.get("phase") != "recovery": return label + " running demonstration must be in actual recovery"
	return ""


static func _escape_error(saved: Dictionary) -> String:
	var escape: Dictionary = saved.escape
	if not Codec.keys_error(escape, ESCAPE_KEYS).is_empty() or not escape.started is bool or not escape.finished is bool or not escape.from_s is float or not escape.until_s is float or not Codec.in_range(escape.from_s, 0.0, 1000000000.0) or not Codec.in_range(escape.until_s, 0.0, 1000000000.0) or not _native_vector(escape.contact_position): return "Exact finite original escape metadata and native contact position required"
	if not escape.started:
		if not _same(escape.from_s, 0.0) or not _same(escape.until_s, 0.0) or not _same(escape.contact_position, Codec.vector3(Vector3.ZERO)) or escape.finished or saved.stage in ["escape", "departed"]: return "Unstarted escape retains only original zero deadlines/contact position and no completion"
		return ""
	if saved.stage not in ["escape", "departed"] or not _same(escape.until_s, escape.from_s + Layout.ESCAPE_DURATION_S) or saved.scheduler.clock_s < escape.from_s: return "Contact-started escape retains the exact original clock plus finite .75s duration"
	if escape.finished and saved.scheduler.clock_s < escape.until_s: return "Escape cannot finish before its original deadline"
	if saved.stage == "departed" and not escape.finished: return "Departed stage retains completed finite escape; parent proves actual contact"
	# Historical contact_position belongs to the first actual overlap. Parent
	# checks its retained hatch/capsule geometry, not current in-flight Hero pose.
	# A finished escape retains its first native contact; ordinary movement
	# during the finite vignette does not require a second overlap.
	return ""


static func _framing_error(saved: Dictionary) -> String:
	var leases: Dictionary = {}
	for value: Variant in saved.scheduler.reservations:
		if not value is Dictionary or not value.get("source_id") is String or value.source_id not in SOURCE_IDS or leases.has(value.source_id) or not value.get("id") is String or value.id.is_empty(): return "Unique actual L5 native lease owner and ID required"
		leases[value.source_id] = value
	var error: String = Codec.keys_error(saved.framing, leases.keys())
	if not error.is_empty(): return "Complete original framing proofs cover exactly current native leases"
	for id: String in saved.framing:
		var value: Variant = saved.framing[id]
		var record: Dictionary = leases[id]
		if not value is Dictionary or not Codec.keys_error(value, FRAME_KEYS).is_empty() or not value.reservation_id is String or value.reservation_id != record.id or not value.proof is Dictionary: return "Exact reservation ID and full encoded native proof required"
		error = _proof_error(value.proof, record)
		if not error.is_empty(): return id + ": " + error
	return ""


static func _proof_error(proof: Dictionary, record: Dictionary) -> String:
	if not Codec.keys_error(proof, PROOF_KEYS).is_empty() or proof.accepted != true or not proof.accepted is bool or not proof.uses_blast is bool or proof.uses_blast or not proof.uses_invulnerability is bool or proof.uses_invulnerability or proof.proof_scope != "static_box_floor_full_dash_stationary_primary" or not proof.path is Array or proof.path.size() not in [4, 6] or not _native_vector(proof.landing) or not _native_vector(proof.attack_position): return "Full original ordinary-primary response proof required"
	for key: String in ["start_s", "active_until_s", "recovery_until_s"]:
		if not record.get(key) is float or not Codec.in_range(record[key], 0.0, 1000000000.0): return "Original native reservation float deadline required"
	if not proof.primary_time_s is float or not proof.response_complete_s is float or not Codec.in_range(proof.primary_time_s, record.active_until_s, record.recovery_until_s) or not Codec.in_range(proof.response_complete_s, proof.primary_time_s, record.recovery_until_s) or proof.response_complete_s >= record.recovery_until_s: return "Full primary and response must fit the original recovery interval"
	var kinds: Array = ["recognition_and_ready", "escape_dash", "recovery_wait", "ordinary_primary"] if proof.path.size() == 4 else ["recognition_and_ready", "escape_dash", "recovery_wait", "positioning_dash", "primary_ready", "ordinary_primary"]
	var previous: Dictionary = {}
	for index: int in range(proof.path.size()):
		var value: Variant = proof.path[index]
		if not value is Dictionary or not Codec.keys_error(value, PATH_KEYS).is_empty() or not _native_vector(value.from) or not _native_vector(value.to) or not value.start_s is float or not value.end_s is float or not Codec.in_range(value.start_s, 0.0, 1000000000.0) or not Codec.in_range(value.end_s, value.start_s, 1000000000.0) or value.kind != kinds[index]: return "Complete finite native path segments and their original order required"
		if value.start_s == value.end_s and not _same(value.from, value.to): return "Zero-time native path segment cannot contain displacement"
		if index == 0 and not _same(value.start_s, record.start_s): return "Native proof begins at original admission clock"
		if not previous.is_empty() and (not _same(previous.end_s, value.start_s) or not _same(previous.to, value.from)): return "Native proof path must retain exact contiguous times and endpoints"
		if value.kind not in ["escape_dash", "positioning_dash"] and not _same(value.from, value.to): return "Waiting and ordinary primary cannot hide travel"
		previous = value
	if not _same(proof.path[1].to, proof.landing) or not _same(previous.from, proof.attack_position) or not _same(previous.to, proof.attack_position) or not _same(previous.start_s, proof.primary_time_s) or not _same(previous.end_s, proof.response_complete_s): return "Proof retains original full landing, attack position and response timing"
	return ""


static func _native_vector(value: Variant) -> bool:
	return Codec.is_vector3(value) and _same(value, Codec.vector3(Codec.read_vector3(value)))


static func _same(left: Variant, right: Variant) -> bool:
	var text: String = Exact.stringify(left)
	return not text.is_empty() and text == Exact.stringify(right)
