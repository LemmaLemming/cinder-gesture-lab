extends RefCounted
## Pure A3-O1 format/profile/home selection. No nodes, native state commit,
## saved-history entitlement, source validation, or configuration happens here.
## The host must run its unchanged complete paired/native validators afterward.

const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const LEGACY_API: String = "act3-pillars-before-time-2"
const API_REVISION: String = "act3-pillars-before-time-3"
const CONSTRUCTION_API: String = "act3-pillars-construction-1"
const CANONICAL_RECIPE: String = "A3-O1/canonical-homes@v1"
const CHALLENGE_RECIPE: String = "A3-O1/challenge-central-southwest@v2"
const PROFILE_IDS: Array[String] = ["assisted", "standard", "challenge"]
const SOURCE_IDS: Array[String] = ["o1-southwest-stalker", "o1-central-stalker", "o1-northwest-stalker"]
const CANONICAL_HOMES: Dictionary = {
	"o1-southwest-stalker": Vector3(0, 0.1, 3),
	"o1-central-stalker": Vector3(0, 0.1, -1),
	"o1-northwest-stalker": Vector3(0, 0.1, -5.5),
}
const LEGACY_LOCAL_KEYS: Array[String] = ["api_revision", "schema_version", "scenery", "scheduler", "sources", "route"]
const LOCAL_KEYS: Array[String] = ["api_revision", "schema_version", "scenery", "scheduler", "sources", "route", "construction"]
const CONSTRUCTION_KEYS: Array[String] = ["api_revision", "schema_version", "profile", "recipe_id"]
const PROFILE_KEYS: Array[String] = ["id", "name", "raw_damage_multiplier", "windup_multiplier", "recovery_multiplier", "reserved_threat_budget", "commit_stagger_s", "arrangement"]
const PROFILE_STRINGS: Array[String] = ["id", "name", "arrangement"]
const PROFILE_FLOATS: Array[String] = ["raw_damage_multiplier", "windup_multiplier", "recovery_multiplier", "reserved_threat_budget", "commit_stagger_s"]


static func fresh(profile_id: Variant) -> Dictionary:
	if not profile_id is String or not PROFILE_IDS.has(profile_id):
		return _error("Pillars fresh construction requires a known String profile ID")
	var profile: Dictionary = Difficulty.new().profile(profile_id)
	var problem: String = _strict_profile_shape_error(profile)
	if not problem.is_empty() or profile.get("id") != profile_id:
		return _error("Canonical Pillars fresh profile unavailable or mistyped: " + problem)
	var recipe_id: String = CHALLENGE_RECIPE if profile_id == "challenge" else CANONICAL_RECIPE
	var definition: Dictionary = recipe_homes(profile_id, recipe_id)
	if not String(definition.error).is_empty():
		return definition
	var construction: Dictionary = {"api_revision": CONSTRUCTION_API, "schema_version": 1, "profile": profile.duplicate(true), "recipe_id": recipe_id}
	return _success(false, profile, recipe_id, definition.homes, construction)


static func saved(local: Variant) -> Dictionary:
	var problem: String = Codec.value_error(local)
	if not problem.is_empty():
		return _error(problem)
	if not local is Dictionary:
		return _error("Pillars saved construction requires a local Dictionary")
	var packet: Dictionary = local
	var legacy: bool = packet.get("api_revision") == LEGACY_API and Codec.is_integer(packet.get("schema_version"), 1, 1)
	var current: bool = packet.get("api_revision") == API_REVISION and packet.get("schema_version") is int and packet.schema_version == 2
	if not legacy and not current:
		return _error("Unsupported Pillars inner construction API/schema")
	problem = Codec.keys_error(packet, LEGACY_LOCAL_KEYS if legacy else LOCAL_KEYS)
	if not problem.is_empty():
		return _error("Closed literal-six or construction-seven Pillars local required")
	for key: String in ["scenery", "scheduler", "sources", "route"]:
		if not packet[key] is Dictionary:
			return _error("Pillars construction requires a Dictionary branch: " + key)
	var profile_value: Variant = packet.scheduler.get("profile")
	if not profile_value is Dictionary or not profile_value.get("id") is String or not PROFILE_IDS.has(profile_value.id):
		return _error("Pillars construction requires a complete known saved Scheduler profile")
	var profile: Dictionary = profile_value
	var canonical: Dictionary = Difficulty.new().profile(profile.id)
	if canonical.is_empty():
		return _error("Saved Pillars profile is absent from the canonical catalogue")
	if legacy:
		# Preserve existing full-profile numeric/int-float acceptance AND the
		# original validated saved values. Never normalize an old writer packet.
		if not Codec.same_values(profile, canonical):
			return _error("Legacy Pillars saved profile differs from its canonical profile")
		var old_definition: Dictionary = recipe_homes(profile.id, CANONICAL_RECIPE)
		if not String(old_definition.error).is_empty():
			return old_definition
		return _success(true, profile, CANONICAL_RECIPE, old_definition.homes, {})
	var construction_value: Variant = packet.get("construction")
	if not construction_value is Dictionary:
		return _error("New Pillars construction requires its four-field descriptor")
	var construction: Dictionary = construction_value
	if not Codec.keys_error(construction, CONSTRUCTION_KEYS).is_empty() or not construction.get("api_revision") is String or construction.api_revision != CONSTRUCTION_API or not construction.get("schema_version") is int or construction.schema_version != 1 or not construction.get("profile") is Dictionary or not construction.get("recipe_id") is String:
		return _error("Closed typed Pillars construction descriptor required")
	problem = _strict_profile_shape_error(canonical)
	if problem.is_empty():
		problem = _strict_profile_shape_error(profile)
	if problem.is_empty():
		problem = _strict_profile_shape_error(construction.profile)
	if not problem.is_empty():
		return _error(problem)
	if not exact_equal(profile, canonical) or not exact_equal(construction.profile, canonical) or not exact_equal(construction.profile, profile):
		return _error("New Pillars descriptor/Scheduler/full canonical typed profiles differ")
	var definition: Dictionary = recipe_homes(profile.id, construction.recipe_id)
	if not String(definition.error).is_empty():
		return definition
	return _success(false, profile, construction.recipe_id, definition.homes, construction)


## Finite geometry lookup only. No catalogue read, serialized positions, or
## preference selection. A saved canonical recipe is legal for Challenge too.
static func recipe_homes(profile_id: Variant, recipe_id: Variant) -> Dictionary:
	if not profile_id is String or not PROFILE_IDS.has(profile_id) or not recipe_id is String:
		return _error("Known String Pillars profile and finite String recipe required")
	if recipe_id != CANONICAL_RECIPE and (recipe_id != CHALLENGE_RECIPE or profile_id != "challenge"):
		return _error("Pillars recipe is not entitled to the selected saved profile")
	var homes: Dictionary = CANONICAL_HOMES.duplicate(true)
	if recipe_id == CHALLENGE_RECIPE:
		homes["o1-central-stalker"] = Vector3(-3, 0.1, 1)
	return {"error": "", "homes": homes}


## Exact typed JSON equality for the small retained profile/descriptor values.
## This is deliberately separate from legacy Codec.same_values semantics.
static func exact_equal(left: Variant, right: Variant) -> bool:
	return _exact_json_equal(left, right, 0)


static func _exact_json_equal(left: Variant, right: Variant, depth: int) -> bool:
	if depth > Codec.MAX_DEPTH or typeof(left) != typeof(right):
		return false
	if left is Dictionary:
		if left.size() != right.size() or left.size() > Codec.MAX_CONTAINER_ENTRIES:
			return false
		for key: Variant in left:
			if not key is String or not right.has(key) or not _exact_json_equal(left[key], right[key], depth + 1):
				return false
		for key: Variant in right:
			if not key is String:
				return false
		return true
	if left is Array:
		if left.size() != right.size() or left.size() > Codec.MAX_CONTAINER_ENTRIES:
			return false
		for index: int in range(left.size()):
			if not _exact_json_equal(left[index], right[index], depth + 1):
				return false
		return true
	match typeof(left):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return left == right
		TYPE_FLOAT:
			return is_finite(left) and is_finite(right) and left == right
	return false


static func _strict_profile_shape_error(profile: Dictionary) -> String:
	var problem: String = Codec.value_error(profile)
	if not problem.is_empty():
		return problem
	if not Codec.keys_error(profile, PROFILE_KEYS).is_empty():
		return "Exactly eight canonical Pillars profile fields required"
	for key: String in PROFILE_STRINGS:
		if not profile[key] is String:
			return "Pillars canonical profile String required: " + key
	for key: String in PROFILE_FLOATS:
		if not profile[key] is float or not is_finite(profile[key]):
			return "Pillars canonical profile finite float required: " + key
	return "" if PROFILE_IDS.has(profile.id) else "Unknown Pillars canonical profile identity"


static func _success(legacy: bool, profile: Dictionary, recipe_id: String, homes: Dictionary, construction: Dictionary) -> Dictionary:
	return {"error": "", "legacy": legacy, "profile_id": profile.id, "profile": profile.duplicate(true), "recipe_id": recipe_id, "homes": homes.duplicate(true), "construction": construction.duplicate(true)}


static func _error(message: String) -> Dictionary:
	return {"error": message}
