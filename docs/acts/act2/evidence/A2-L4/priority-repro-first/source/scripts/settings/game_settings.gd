class_name CinderGameSettings
extends RefCounted
## Desktop settings data. The shell owns menus, voice routing and cosmetic hooks.
## Construction, loading and updates do not apply runtime changes implicitly.

signal settings_changed(settings: Dictionary)

const SCHEMA_VERSION: int = 1
const DEFAULT_PATH: String = "user://cinder/settings.json"
const QUALITY_IDS: Array[String] = ["Low", "Standard", "High"]
const AUDIO_CHANNELS: Array[String] = ["master", "music", "effects"]
const MUSIC_BUS: String = "Music"
const EFFECTS_BUS: String = "Effects"
const MAX_FILE_BYTES: int = 65536

var last_error: String = ""
var _storage_path: String
var _settings: Dictionary = defaults()


func _init(storage_path: String = DEFAULT_PATH) -> void:
	_storage_path = storage_path


static func defaults() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"quality": "Standard",
		"target_fps": 60,
		"audio": {"master": 1.0, "music": 1.0, "effects": 1.0},
		"reduced_motion": false,
	}


func storage_path() -> String:
	return _storage_path


func snapshot() -> Dictionary:
	return _settings.duplicate(true)


func validation_error(candidate: Variant) -> String:
	if not candidate is Dictionary:
		return "Settings must be a dictionary."
	var data: Dictionary = candidate
	var key_error: String = _keys_error(data, ["schema_version", "quality", "target_fps", "audio", "reduced_motion"])
	if not key_error.is_empty():
		return key_error
	if not _number_in_range(data["schema_version"], SCHEMA_VERSION, SCHEMA_VERSION):
		return "Unsupported settings schema version."
	if not data["quality"] is String or not QUALITY_IDS.has(data["quality"]):
		return "Quality must be Low, Standard or High."
	if not _number_in_range(data["target_fps"], 30.0, 60.0) or not [30.0, 60.0].has(float(data["target_fps"])):
		return "Target FPS must be 30 or 60."
	if not data["reduced_motion"] is bool:
		return "Reduced motion must be a boolean."
	if not data["audio"] is Dictionary:
		return "Audio must contain master, music and effects volumes."
	var audio: Dictionary = data["audio"]
	key_error = _keys_error(audio, AUDIO_CHANNELS)
	if not key_error.is_empty():
		return "Audio: " + key_error
	for channel: String in AUDIO_CHANNELS:
		if not _number_in_range(audio[channel], 0.0, 1.0):
			return "%s volume must be finite and between 0 and 1." % channel
	return ""


## Partial updates merge named audio sliders; unknown keys still reject.
## With persistence enabled, disk replacement succeeds before memory changes.
func update(changes: Dictionary, persist: bool = true) -> bool:
	var candidate: Dictionary = snapshot()
	for key: Variant in changes:
		if key == "audio" and changes[key] is Dictionary:
			candidate["audio"].merge(changes[key], true)
		else:
			candidate[key] = changes[key]
	return replace(candidate, persist)


func replace(candidate: Variant, persist: bool = true) -> bool:
	last_error = validation_error(candidate)
	if not last_error.is_empty():
		return false
	var canonical: Dictionary = _canonical(candidate as Dictionary)
	if persist and not _write_atomic(canonical):
		return false
	var changed: bool = canonical != _settings
	_settings = canonical
	last_error = ""
	if changed:
		settings_changed.emit(snapshot())
	return true


## Missing files keep the current defaults/settings and are not created here.
## Rejected files are retained verbatim; loading never repairs by overwriting.
func load_settings() -> bool:
	last_error = _path_error()
	if not last_error.is_empty():
		return false
	if DirAccess.dir_exists_absolute(_storage_path):
		last_error = "Settings path is a directory."
		return false
	if not FileAccess.file_exists(_storage_path):
		return true
	var candidate: Variant = _read_validated(_storage_path)
	if not last_error.is_empty():
		return false
	return replace(candidate, false)


func save_settings() -> bool:
	last_error = validation_error(_settings)
	return last_error.is_empty() and _write_atomic(_settings)


## FPS caps rendering only. Never change physics rate, time scale, input,
## viewport dimensions/filtering, action clocks, collision or cue timings here.
## Root routes existing combat voices to Effects; no music track exists yet.
func apply_runtime() -> void:
	Engine.max_fps = int(_settings["target_fps"])
	_ensure_audio_bus(MUSIC_BUS)
	_ensure_audio_bus(EFFECTS_BUS)
	for channel: String in AUDIO_CHANNELS:
		var bus_name: String = "Master" if channel == "master" else (MUSIC_BUS if channel == "music" else EFFECTS_BUS)
		var index: int = AudioServer.get_bus_index(bus_name)
		var volume: float = float(_settings["audio"][channel])
		# Explicit mute avoids an infinite decibel value for zero volume.
		AudioServer.set_bus_volume_linear(index, volume if volume > 0.0 else 1.0)
		AudioServer.set_bus_mute(index, volume == 0.0)


## Only optional cosmetics may consume these budgets. Do not scale the global
## transient pool: it also holds essential action/readability feedback.
func cosmetic_policy() -> Dictionary:
	var quality: String = _settings["quality"]
	var reduced: bool = _settings["reduced_motion"]
	var budget: Dictionary = {
		"Low": {"density": 0.35, "debris": 24, "flecks": 8, "decoration": 0.4},
		"Standard": {"density": 0.7, "debris": 64, "flecks": 16, "decoration": 0.75},
		"High": {"density": 1.0, "debris": 96, "flecks": 24, "decoration": 1.0},
	}[quality]
	return {
		"quality": quality,
		"optional_particle_density": budget["density"],
		"optional_debris_limit": budget["debris"],
		"optional_impact_fleck_limit": budget["flecks"],
		"decoration_density": budget["decoration"],
		"camera_shake_scale": 0.0 if reduced else 1.0,
		"decoration_motion_scale": 0.0 if reduced else 1.0,
		"menu_motion_enabled": not reduced,
		"authoritative_feedback_scale": 1.0,
		"action_feedback_scale": 1.0,
		"protected_feedback": ["warning", "lock", "active_footprint", "recovery", "source", "target", "safe_landing", "interaction_state", "hit_confirmation", "dash_path", "slash_arc", "blast_release"],
		"nearest_filtering": true,
		"portrait_camera_unchanged": true,
		"simulation_unchanged": true,
	}


## Credits are data for a future menu, not evidence that a menu or campaign
## art integration exists. Reference material retains its individual records.
static func credits() -> Array[Dictionary]:
	return [
		{"id": "engine", "title": "Godot Engine", "credit": "Godot Engine contributors", "role": "Engine, MIT license", "source": "https://godotengine.org/license/"},
		{"id": "runtime-art", "title": "Cinder runtime artwork", "credit": "Original code-authored Cinder pixel actors, equipment and effects", "role": "Implemented prototype artwork; no stock-image or concept-board pixels imported", "sources": ["res://assets/characters/manifest.json", "res://assets/effects/manifest.json", "res://scripts/pixel_sprite.gd"]},
		{"id": "runtime-audio", "title": "Cinder prototype audio", "credit": "Original synthesized slash, blast and hit sounds", "role": "Procedural audio in scripts/effects.gd; no music track currently bundled", "sources": ["res://scripts/effects.gd"]},
		{"id": "player-reference", "title": "Astronaut turnaround reference", "credit": "Built-in image generation tool; user-supplied astronaut silhouette/detail reference", "role": "Historical reference for the helmeted lab pass, not a runtime sprite sheet; selected act headwear supersedes its campaign rule", "sources": ["res://assets/references/manifest.json"]},
		{"id": "smoke-reference", "title": "Curling smoke reference", "credit": "User-supplied visual reference", "role": "Inspired original procedural smoke; no reference pixels imported", "sources": ["res://assets/effects/manifest.json"]},
		{"id": "concept-art", "title": "Campaign concept studies", "credit": "Built-in image generation tool", "role": "Original generated planning illustrations; not implemented scenes or runtime atlases", "sources": ["res://docs/concept-art/act1/generated-manifest.json", "res://docs/concept-art/act2/generated-manifest.json", "res://docs/concept-art/act3/generated-manifest.json"]},
		{"id": "act1-inspiration", "title": "A Trip to the Moon (1902)", "credit": "Georges Méliès", "role": "Film inspiration; reference reproductions retain individual source/license declarations", "sources": ["res://docs/reference-library/act1/CREDITS.md"]},
		{"id": "act2-inspiration", "title": "The War of the Worlds (1898)", "credit": "H. G. Wells", "role": "Literary inspiration; modern adaptation assets are not runtime sources", "sources": ["res://docs/reference-library/act2/CREDITS.md"]},
		{"id": "act3-inspiration", "title": "A Voyage to Arcturus (1920)", "credit": "David Lindsay", "role": "Literary inspiration; scenery and combat artwork are game adaptations", "sources": ["res://docs/reference-library/act3/research/SOURCES.md"]},
	]


func _write_atomic(candidate: Dictionary) -> bool:
	last_error = _path_error()
	if not last_error.is_empty():
		return false
	if DirAccess.dir_exists_absolute(_storage_path):
		last_error = "Settings path is a directory."
		return false
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(_storage_path.get_base_dir())
	if directory_error != OK:
		last_error = "Cannot create settings directory: %s." % error_string(directory_error)
		return false
	var temporary: String = "%s.tmp-%d-%d" % [_storage_path, get_instance_id(), Time.get_ticks_usec()]
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "Cannot open temporary settings file: %s." % error_string(FileAccess.get_open_error())
		return false
	# Full precision preserves arbitrary valid slider values on readback.
	var stored: bool = file.store_string(JSON.stringify(candidate, "\t", true, true) + "\n")
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if not stored or write_error != OK:
		last_error = "Cannot write settings: %s." % error_string(write_error)
		DirAccess.remove_absolute(temporary)
		return false
	var verified: Variant = _read_validated(temporary)
	if not last_error.is_empty() or _canonical(verified as Dictionary) != candidate:
		if last_error.is_empty():
			last_error = "Temporary settings verification failed."
		DirAccess.remove_absolute(temporary)
		return false
	# A sibling rename replaces the old file without a delete-then-write gap.
	# Never remove the valid target as a fallback for a failed rename.
	var commit_error: Error = _commit_temp_file(temporary, _storage_path)
	if commit_error != OK:
		last_error = "Cannot replace settings: %s." % error_string(commit_error)
		DirAccess.remove_absolute(temporary)
		return false
	last_error = ""
	return true


## Narrow seam lets the smoke test inject a commit failure after a real temp
## write/readback, without modifying permissions or touching a real user file.
func _commit_temp_file(from_path: String, to_path: String) -> Error:
	return DirAccess.rename_absolute(from_path, to_path)


func _read_validated(path: String) -> Variant:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "Cannot read settings: %s." % error_string(FileAccess.get_open_error())
		return null
	if file.get_length() > MAX_FILE_BYTES:
		file.close()
		last_error = "Settings file exceeds the size limit."
		return null
	var text: String = file.get_as_text()
	var read_error: Error = file.get_error()
	file.close()
	if read_error != OK:
		last_error = "Cannot read settings: %s." % error_string(read_error)
		return null
	var parser: JSON = JSON.new()
	if parser.parse(text) != OK:
		last_error = "Malformed settings JSON."
		return null
	last_error = validation_error(parser.data)
	return parser.data if last_error.is_empty() else null


func _path_error() -> String:
	if not _storage_path.begins_with("user://"):
		return "Settings must be stored under user://."
	var relative: String = _storage_path.trim_prefix("user://")
	if relative.is_empty() or relative.ends_with("/") or relative.contains("\\") or relative.contains(":"):
		return "Invalid settings file path."
	for component: String in relative.split("/"):
		if component.is_empty() or component in [".", ".."]:
			return "Invalid settings file path."
	return ""


func _canonical(candidate: Dictionary) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"quality": String(candidate["quality"]),
		"target_fps": int(candidate["target_fps"]),
		"audio": {"master": float(candidate["audio"]["master"]), "music": float(candidate["audio"]["music"]), "effects": float(candidate["audio"]["effects"])},
		"reduced_motion": bool(candidate["reduced_motion"]),
	}


func _keys_error(data: Dictionary, required: Array) -> String:
	for key: Variant in data:
		if not key is String or not required.has(key):
			return "Unknown settings key: %s." % str(key)
	for key: String in required:
		if not data.has(key):
			return "Missing settings key: %s." % key
	return ""


func _number_in_range(value: Variant, minimum: float, maximum: float) -> bool:
	if not (value is int or value is float):
		return false
	var number: float = float(value)
	return is_finite(number) and number >= minimum and number <= maximum


func _ensure_audio_bus(bus_name: String) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")
