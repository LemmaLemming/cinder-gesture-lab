class_name CinderSaveStore
extends RefCounted
## Desktop JSON persistence. A sibling rename publishes a complete generation;
## a verified prior generation remains available after an interrupted/corrupt write.
## Flush/rename is tested at process level, not a proof of power-loss durability.

const FORMAT_VERSION: int = 1
const MAX_BYTES: int = 8 * 1024 * 1024
const MAX_GENERATION: int = 9007199254740991
var path: String
var last_error: String = ""
var loaded_backup: bool = false
var generation: int = 0
var payload_validator: Callable

func _init(save_path: String = "user://campaign.json") -> void:
	path = save_path

static func json_error(value: Variant, depth: int = 0) -> String:
	if depth > 64:
		return "Save nesting exceeds 64 levels"
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_STRING:
			return ""
		TYPE_INT:
			return "" if value >= -MAX_GENERATION and value <= MAX_GENERATION else "Save integers outside exact JSON range must be encoded as strings"
		TYPE_FLOAT:
			return "" if is_finite(value) else "Save numbers must be finite"
		TYPE_ARRAY:
			for child: Variant in value:
				var error: String = json_error(child, depth + 1)
				if not error.is_empty():
					return error
		TYPE_DICTIONARY:
			for key: Variant in value:
				if not key is String:
					return "Save keys must be strings"
				var error: String = json_error(value[key], depth + 1)
				if not error.is_empty():
					return error
		_:
			return "Save contains a non-JSON value"
	return ""

func write_payload(payload: Dictionary) -> bool:
	last_error = json_error(payload)
	if last_error.is_empty() and payload_validator.is_valid():
		last_error = payload_validator.call(payload.duplicate(true))
	if not last_error.is_empty():
		return false
	if not path.begins_with("user://"):
		last_error = "Desktop saves require a user:// path"
		return false
	var encoded: String = JSON.stringify(payload, "", true, true)
	if encoded.to_utf8_buffer().size() > MAX_BYTES:
		last_error = "Save exceeds size limit"
		return false
	var previous: Dictionary = _read_file(path)
	var next_generation: int = maxi(generation, int(previous.get("generation", 0))) + 1
	if next_generation > MAX_GENERATION:
		last_error = "Save generation exceeds exact JSON integer range"
		return false
	var envelope: Dictionary = {
		"format_version": FORMAT_VERSION, "generation": next_generation,
		"payload_json": encoded, "sha256": encoded.sha256_text(),
	}
	var absolute: String = ProjectSettings.globalize_path(path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir()) != OK:
		last_error = "Cannot create save directory"
		return false
	var suffix: String = ".tmp-%d-%s" % [Time.get_ticks_usec(), Crypto.new().generate_random_bytes(8).hex_encode()]
	var temporary: String = path + suffix
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "Cannot open temporary save"
		return false
	file.store_string(JSON.stringify(envelope))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	var verified: Dictionary = _read_file(temporary)
	if write_error != OK or verified.is_empty() or verified["payload_json"] != encoded or verified["generation"] != next_generation:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		last_error = "Temporary save verification failed"
		return false
	# Preserve only a valid previous generation; a corrupt primary must not
	# replace a known-good backup during recovery.
	if not previous.is_empty():
		var backup_temp: String = path + ".bak" + suffix
		var copied: Error = DirAccess.copy_absolute(absolute, ProjectSettings.globalize_path(backup_temp))
		var backed_up: Error = copied
		if copied == OK:
			backed_up = DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_temp), absolute + ".bak")
		if backed_up != OK:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_temp))
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
			last_error = "Cannot preserve prior save generation"
			return false
	var published: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), absolute)
	if published != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		last_error = "Cannot publish complete save generation"
		return false
	generation = next_generation
	last_error = ""
	return true

func read_payload() -> Dictionary:
	loaded_backup = false
	last_error = ""
	if not path.begins_with("user://"):
		last_error = "Desktop saves require a user:// path"
		return {}
	var envelope: Dictionary = _read_file(path)
	if envelope.is_empty():
		envelope = _read_file(path + ".bak")
		loaded_backup = not envelope.is_empty()
	if envelope.is_empty():
		last_error = "No valid campaign save generation"
		return {}
	generation = int(envelope["generation"])
	return (envelope["payload"] as Dictionary).duplicate(true)

func _read_file(candidate_path: String) -> Dictionary:
	if not FileAccess.file_exists(candidate_path):
		return {}
	var file: FileAccess = FileAccess.open(candidate_path, FileAccess.READ)
	if file == null:
		return {}
	if file.get_length() > MAX_BYTES * 2:
		file.close()
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary or parsed.get("format_version") != FORMAT_VERSION:
		return {}
	var serial: Variant = parsed.get("generation")
	if not (serial is int or serial is float) or not is_finite(float(serial)) or serial < 1 or serial > MAX_GENERATION or serial != floor(serial):
		return {}
	if not parsed.get("payload_json") is String or not parsed.get("sha256") is String:
		return {}
	var encoded: String = parsed["payload_json"]
	if encoded.to_utf8_buffer().size() > MAX_BYTES or encoded.sha256_text() != parsed["sha256"]:
		return {}
	if parser.parse(encoded) != OK:
		return {}
	var payload: Variant = parser.data
	if not payload is Dictionary or not json_error(payload).is_empty():
		return {}
	if payload_validator.is_valid() and not String(payload_validator.call(payload.duplicate(true))).is_empty():
		return {}
	return {"generation": int(serial), "payload": payload, "payload_json": encoded}
