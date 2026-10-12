class_name CinderDifficulty
extends RefCounted
## Provisional encounter profiles. Resolve ONLY immutable raw role data once.
## Changing preference must wait for the next begin_encounter; resolved data is
## marked and rejected as input, preventing multiplier compounding.

const DATA_PATH: String = "res://data/design/difficulty_profiles.json"
const SCHEMA_VERSION: int = 1
## Reuse is optional above this bound; catalogue parsing/acceptance is unchanged.
const MAX_VALIDATION_INPUT_BYTES: int = 65536

var last_error: String = ""
var _profiles: Dictionary = {}
var _validation_input := PackedByteArray()


func _init() -> void:
	var file: FileAccess = FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		last_error = "Difficulty catalogue unavailable"
		return
	# Keep the ORIGINAL native text decoder and its UTF8/BOM/error behavior.
	# This receipt describes exactly the String passed to JSON, not its unknown
	# pre-decoding raw encoding. No old cached profile becomes fresh authority.
	var input_text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(input_text)
	if not parsed is Dictionary or parsed.get("schema_version") != SCHEMA_VERSION or not parsed.get("profiles") is Array:
		last_error = "Unsupported difficulty catalogue"
		return
	for profile: Dictionary in parsed["profiles"]:
		_profiles[String(profile["id"])] = profile.duplicate(true)
	# At most 4*limit UTF8 bytes are temporarily encoded; larger catalogues keep
	# the original accepted set but disable this optional validation reuse.
	if not input_text.is_empty() and input_text.length() <= MAX_VALIDATION_INPUT_BYTES:
		var bytes: PackedByteArray = input_text.to_utf8_buffer()
		if bytes.size() <= MAX_VALIDATION_INPUT_BYTES:
			_validation_input = bytes


## Private validation dependency transported only between fresh pure codecs.
## Packed bytes are defensive; this is never an actor/world authorization.
func _catalogue_validation_input() -> PackedByteArray:
	return _validation_input.duplicate()


static func _catalogue_validation_input_matches(expected: PackedByteArray) -> bool:
	# Fresh raw read at the binding boundary; no second decoder/error side effect.
	# BOM/malformed encodings normally differ from the parser's normalized UTF8
	# input and use the old validator. Missing/large/short files also fall back.
	if expected.is_empty() or expected.size() > MAX_VALIDATION_INPUT_BYTES:
		return false
	var file: FileAccess = FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null or file.get_length() != expected.size():
		return false
	var current: PackedByteArray = file.get_buffer(expected.size())
	return current.size() == expected.size() and current == expected


func profile(profile_id: String) -> Dictionary:
	return (_profiles.get(profile_id, {}) as Dictionary).duplicate(true)


func resolve_role(raw_role: Dictionary, profile_id: String, timing_floors: Dictionary) -> Dictionary:
	last_error = ""
	var selected: Dictionary = profile(profile_id)
	if selected.is_empty():
		last_error = "Unknown difficulty profile: " + profile_id
		return {}
	if raw_role.has("difficulty_schema") or raw_role.has("difficulty_profile"):
		last_error = "Resolve from raw role values, not an already resolved profile"
		return {}
	for key: String in ["raw_damage", "windup_s", "lock_s", "active_s", "recovery_s", "attack_interval_s", "max_hp"]:
		if not _number(raw_role.get(key)) or float(raw_role[key]) <= 0.0:
			last_error = "Missing positive raw role value: " + key
			return {}
	if not _number(raw_role.get("move_speed")) or float(raw_role["move_speed"]) < 0.0:
		last_error = "Finite nonnegative raw move_speed required; zero is a stationary role"
		return {}
	for key: String in ["windup_s", "lock_s", "recovery_s"]:
		if not _number(timing_floors.get(key)) or float(timing_floors[key]) <= 0.0:
			last_error = "Explicit positive timing floor required: " + key
			return {}
	var resolved: Dictionary = raw_role.duplicate(true)
	resolved["damage"] = float(raw_role["raw_damage"]) * float(selected["raw_damage_multiplier"])
	resolved["windup_s"] = maxf(float(raw_role["windup_s"]) * float(selected["windup_multiplier"]), float(timing_floors["windup_s"]))
	resolved["lock_s"] = maxf(float(raw_role["lock_s"]), float(timing_floors["lock_s"]))
	resolved["recovery_s"] = maxf(float(raw_role["recovery_s"]) * float(selected["recovery_multiplier"]), float(timing_floors["recovery_s"]))
	if float(resolved["lock_s"]) >= float(resolved["windup_s"]):
		last_error = "Windup must include a nonzero warning before its locked phase"
		return {}
	resolved["difficulty_schema"] = SCHEMA_VERSION
	resolved["difficulty_profile"] = profile_id
	resolved["tuning_status"] = "provisional_unplaytested"
	resolved["raw_role"] = raw_role.duplicate(true)
	return resolved


static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
