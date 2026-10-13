extends SceneTree

const SettingsScript: GDScript = preload("res://scripts/settings/game_settings.gd")

class FailedCommitSettings:
	extends "res://scripts/settings/game_settings.gd"
	var fail_commit: bool = false

	func _commit_temp_file(from_path: String, to_path: String) -> Error:
		if fail_commit:
			return ERR_CANT_CREATE
		return super._commit_temp_file(from_path, to_path)

var _failures: int = 0
var _checks: int = 0
var _directory: String


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_directory = "user://settings-smoke-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var path: String = _directory + "/settings.json"
	var initial_fps: int = Engine.max_fps
	var settings = SettingsScript.new(path)
	_expect(settings.snapshot() == SettingsScript.defaults() and settings.snapshot()["target_fps"] == 60, "initial settings select Standard quality and 60 FPS")
	_expect(Engine.max_fps == initial_fps and not FileAccess.file_exists(path), "construction neither applies runtime settings nor creates a file")
	_expect(settings.load_settings() and not FileAccess.file_exists(path), "missing settings load defaults without writing a replacement")
	var copy: Dictionary = settings.snapshot()
	copy["audio"]["master"] = 0.2
	_expect(settings.snapshot()["audio"]["master"] == 1.0, "snapshots have no mutable links to retained settings")
	_expect(settings.save_settings() and FileAccess.file_exists(path), "defaults persist in the isolated user directory")
	var events: Array[Dictionary] = []
	settings.settings_changed.connect(func(record: Dictionary) -> void: events.append(record))
	_expect(settings.update({"quality": "Low", "target_fps": 30, "audio": {"master": 0.6, "music": 0.0, "effects": 0.4}, "reduced_motion": true}), "all desktop preferences persist as one validated update")
	var accepted: Dictionary = settings.snapshot()
	var disk: String = FileAccess.get_file_as_string(path)
	_expect(events.size() == 1 and events[0] == accepted, "one committed change publishes its complete settings record")
	events[0]["audio"]["master"] = 0.01
	_expect(settings.snapshot() == accepted, "signal records cannot mutate retained audio settings")
	var reopened = SettingsScript.new(path)
	_expect(reopened.load_settings() and reopened.snapshot() == accepted, "reopening restores quality, FPS, volumes and reduced motion together")
	_expect(reopened.snapshot()["schema_version"] is int and reopened.snapshot()["target_fps"] is int, "integral JSON version/FPS values normalize to canonical integers")
	_expect(settings.update({"audio": {"effects": 0.123456789012345}}) and reopened.load_settings() and reopened.snapshot() == settings.snapshot(), "full-precision persistence preserves arbitrary valid slider values")
	_expect(settings.replace(accepted) and FileAccess.get_file_as_string(path) == disk, "precision round-trip restores the original accepted file")
	_expect(settings.update({"audio": {"effects": 0.75}}, false) and settings.snapshot()["audio"]["master"] == 0.6 and settings.snapshot()["audio"]["music"] == 0.0, "one audio slider preserves the other channels")
	_expect(FileAccess.get_file_as_string(path) == disk and settings.replace(accepted, false), "explicit preview updates preserve the disk record and can restore the accepted preferences")
	_validation_checks(settings, path, accepted)
	_atomic_failure_checks(path, accepted, disk)
	_policy_checks(settings)
	_runtime_checks(settings)
	_credits_checks()
	_corrupt_load_checks(settings, path, accepted)
	_storage_failure_checks()
	_cleanup()
	print("Settings smoke: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _validation_checks(settings, path: String, accepted: Dictionary) -> void:
	var malformed: Array = [null, [], "settings"]
	for field: String in ["schema_version", "quality", "target_fps", "audio", "reduced_motion"]:
		var missing: Dictionary = accepted.duplicate(true)
		missing.erase(field)
		malformed.append(missing)
	for change: Dictionary in [{"schema_version": 2}, {"schema_version": 1.5}, {"schema_version": true}, {"quality": "Ultra"}, {"quality": "low"}, {"target_fps": 45}, {"target_fps": 30.5}, {"target_fps": "60"}, {"target_fps": INF}, {"reduced_motion": 1}, {"unknown": true}, {3: "bad-key"}]:
		var invalid: Dictionary = accepted.duplicate(true)
		invalid.merge(change, true)
		malformed.append(invalid)
	for volume: Variant in [-0.01, 1.01, INF, -INF, NAN, "0.5", true, null]:
		var invalid: Dictionary = accepted.duplicate(true)
		invalid["audio"]["effects"] = volume
		malformed.append(invalid)
	for audio: Variant in [{"master": 0.5}, {"master": 0.5, "music": 0.5, "effects": 0.5, "dialogue": 0.5}, []]:
		var invalid: Dictionary = accepted.duplicate(true)
		invalid["audio"] = audio
		malformed.append(invalid)
	var disk: String = FileAccess.get_file_as_string(path)
	for candidate: Variant in malformed:
		_expect(not settings.validation_error(candidate).is_empty() and not settings.replace(candidate) and settings.snapshot() == accepted and FileAccess.get_file_as_string(path) == disk, "malformed settings reject before changing memory or valid disk data")
	_expect(not settings.update({"audio": {"effects": NAN}}) and settings.snapshot() == accepted and FileAccess.get_file_as_string(path) == disk, "invalid partial audio changes also preserve memory and disk")


func _atomic_failure_checks(path: String, accepted: Dictionary, disk: String) -> void:
	var failing = FailedCommitSettings.new(path)
	_expect(failing.load_settings() and failing.snapshot() == accepted, "failure fixture starts from the real valid temporary-directory record")
	failing.fail_commit = true
	var events: Array[Dictionary] = []
	failing.settings_changed.connect(func(record: Dictionary) -> void: events.append(record))
	_expect(not failing.update({"quality": "High"}) and failing.last_error.contains("replace"), "injected sibling-rename failure reports its failed commit")
	_expect(failing.snapshot() == accepted and FileAccess.get_file_as_string(path) == disk and events.is_empty(), "failed atomic replacement retains old memory/disk and emits no change")
	_expect(DirAccess.get_files_at(_directory).size() == 1, "failed commit removes its own uncommitted temporary file")
	failing.fail_commit = false
	_expect(failing.update({"quality": "High"}) and FileAccess.get_file_as_string(path) != disk, "a later successful rename replaces the old file without deleting it first")
	_expect(failing.replace(accepted), "atomic failure test restores the original valid preferences")


func _policy_checks(settings) -> void:
	var prior: Dictionary = settings.snapshot()
	for quality: String in SettingsScript.QUALITY_IDS:
		for reduced: bool in [false, true]:
			settings.update({"quality": quality, "reduced_motion": reduced}, false)
			var policy: Dictionary = settings.cosmetic_policy()
			_expect(policy["authoritative_feedback_scale"] == 1.0 and policy["action_feedback_scale"] == 1.0 and policy["nearest_filtering"] and policy["portrait_camera_unchanged"] and policy["simulation_unchanged"], "%s keeps essential feedback, pixels, portrait camera and simulation unchanged" % quality)
			_expect(policy["optional_debris_limit"] <= 96 and policy["optional_impact_fleck_limit"] <= 24 and policy["optional_particle_density"] > 0.0 and policy["optional_particle_density"] <= 1.0, "%s optional budgets stay within existing effect ceilings" % quality)
			_expect(policy["camera_shake_scale"] == (0.0 if reduced else 1.0) and policy["decoration_motion_scale"] == (0.0 if reduced else 1.0) and policy["menu_motion_enabled"] == (not reduced), "reduced motion controls optional shake/decoration/menu movement only")
			for cue: String in ["warning", "lock", "active_footprint", "recovery", "source", "target", "safe_landing", "interaction_state", "hit_confirmation", "dash_path", "slash_arc", "blast_release"]:
				_expect(policy["protected_feedback"].has(cue), "%s retains %s at both motion settings" % [quality, cue])
	settings.replace(prior, false)
	var policy_copy: Dictionary = settings.cosmetic_policy()
	policy_copy["protected_feedback"].clear()
	_expect(not settings.cosmetic_policy()["protected_feedback"].is_empty(), "policy callers cannot modify subsequent protected-feedback lists")


func _runtime_checks(settings) -> void:
	var prior: Dictionary = settings.snapshot()
	var old_fps: int = Engine.max_fps
	var old_layout: AudioBusLayout = AudioServer.generate_bus_layout()
	var ticks: int = Engine.physics_ticks_per_second
	var steps: int = Engine.max_physics_steps_per_frame
	var scale: float = Engine.time_scale
	var width: Variant = ProjectSettings.get_setting("display/window/size/viewport_width")
	var height: Variant = ProjectSettings.get_setting("display/window/size/viewport_height")
	var orientation: Variant = ProjectSettings.get_setting("display/window/handheld/orientation")
	settings.update({"target_fps": 30, "audio": {"master": 0.6, "music": 0.0, "effects": 0.4}}, false)
	settings.apply_runtime()
	_expect(Engine.max_fps == 30 and Engine.physics_ticks_per_second == ticks and Engine.max_physics_steps_per_frame == steps and Engine.time_scale == scale, "30 FPS changes only the render cap and preserves simulation clocks/rate")
	_expect(ProjectSettings.get_setting("display/window/size/viewport_width") == width and ProjectSettings.get_setting("display/window/size/viewport_height") == height and ProjectSettings.get_setting("display/window/handheld/orientation") == orientation, "applying settings preserves portrait dimensions/orientation")
	var master: int = AudioServer.get_bus_index("Master")
	var music: int = AudioServer.get_bus_index(SettingsScript.MUSIC_BUS)
	var effects: int = AudioServer.get_bus_index(SettingsScript.EFFECTS_BUS)
	_expect(music >= 0 and effects >= 0 and AudioServer.get_bus_send(music) == "Master" and AudioServer.get_bus_send(effects) == "Master", "independent Music and Effects buses send to Master")
	_expect(is_equal_approx(AudioServer.get_bus_volume_linear(master), 0.6) and is_equal_approx(AudioServer.get_bus_volume_linear(effects), 0.4) and AudioServer.is_bus_mute(music), "master/effects gains apply independently and zero music volume mutes its bus")
	var count: int = AudioServer.bus_count
	settings.update({"target_fps": 60, "audio": {"music": 0.8}}, false)
	settings.apply_runtime()
	_expect(Engine.max_fps == 60 and AudioServer.bus_count == count and not AudioServer.is_bus_mute(music) and is_equal_approx(AudioServer.get_bus_volume_linear(music), 0.8), "60 FPS and nonzero audio restore without duplicate buses")
	AudioServer.set_bus_layout(old_layout)
	Engine.max_fps = old_fps
	settings.replace(prior, false)


func _credits_checks() -> void:
	var records: Array[Dictionary] = SettingsScript.credits()
	var ids: Dictionary = {}
	for record: Dictionary in records:
		_expect(not ids.has(record["id"]) and not String(record["title"]).is_empty() and not String(record["credit"]).is_empty() and not String(record["role"]).is_empty(), "credit entries have unique stable IDs and truthful display fields")
		ids[record["id"]] = true
		for path: String in record.get("sources", []):
			_expect(FileAccess.file_exists(path), "credit source record exists: " + path)
	_expect(ids.has("runtime-art") and ids.has("runtime-audio") and ids.has("player-reference") and ids.has("smoke-reference") and ids.has("concept-art"), "credits distinguish current originals from supplied/generated references")
	records[0]["title"] = "Changed by caller"
	_expect(SettingsScript.credits()[0]["title"] == "Godot Engine", "credits return independent records")


func _corrupt_load_checks(settings, path: String, accepted: Dictionary) -> void:
	for text: String in ["{truncated", "[]", '{"schema_version": 999}', '{"schema_version": 1, "quality": "Ultra", "target_fps": 60, "audio": {"master": 1, "music": 1, "effects": 1}, "reduced_motion": false}']:
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(text)
		file.close()
		_expect(not settings.load_settings() and not settings.last_error.is_empty() and settings.snapshot() == accepted and FileAccess.get_file_as_string(path) == text, "malformed disk record rejects without overwriting it or current preferences")
	_expect(settings.save_settings(), "explicit save can replace a rejected file with the retained valid settings")


func _storage_failure_checks() -> void:
	var blocked_path: String = _directory + "/blocked"
	var blocker: FileAccess = FileAccess.open(blocked_path, FileAccess.WRITE)
	blocker.store_string("not a directory")
	blocker.close()
	var blocked = SettingsScript.new(blocked_path + "/settings.json")
	var before: Dictionary = blocked.snapshot()
	_expect(not blocked.update({"quality": "Low"}) and blocked.snapshot() == before and FileAccess.get_file_as_string(blocked_path) == "not a directory", "directory-creation failure preserves settings and the blocking file")
	for path: String in ["res://settings.json", "user://../settings.json", "user://", "user://settings/", "user://settings//settings.json"]:
		var invalid_path = SettingsScript.new(path)
		_expect(not invalid_path.save_settings() and not invalid_path.load_settings(), "invalid/out-of-scope storage paths reject before filesystem mutation")


func _cleanup() -> void:
	for file: String in DirAccess.get_files_at(_directory):
		DirAccess.remove_absolute(_directory + "/" + file)
	DirAccess.remove_absolute(_directory)


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
