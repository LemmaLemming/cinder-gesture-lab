extends SceneTree
## Model/storage tests use marked fixtures only; they do not accept real levels.
const Registry = preload("res://scripts/campaign/registry.gd")
const Attempts = preload("res://scripts/campaign/attempts.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Equipment = preload("res://scripts/equipment.gd")
const ROOT: String = "user://test-campaign-persistence/"
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_cleanup()
	var registry := Registry.new()
	_expect(registry.last_error.is_empty() and registry.ids().size() == 24 and registry.main_route().size() == 15, "authored registry has 15 main and nine optional canonical levels")
	_expect(not registry.is_playable("A1-L1") and registry.node_state("A1-L1", [], [], "") == "unimplemented", "authored route does not expose unfinished scenes as playable")
	_expect(registry.is_unlocked("A1-L1", []) and not registry.is_unlocked("A1-L2", []) and not registry.is_unlocked("A1-O1", ["A1-L1"]), "main sequence and optional parent clear are independent gates")
	_expect(registry.is_unlocked("A1-O1", ["A1-L1", "A1-L2"]) and registry.next_main("A1-L5") == "A2-L1", "optional unlock and inter-act link use canonical IDs")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Registry.DATA_PATH))
	var invalid: Dictionary = raw.duplicate(true)
	invalid["levels"][0]["id"] = "A1-L1\n"
	_expect(not registry.configure(invalid) and registry.ids().size() == 24, "invalid registry rejects atomically without discarding the prior route")
	invalid = raw.duplicate(true)
	for info: Dictionary in invalid["levels"]:
		if info["id"] == "A1-O1":
			info["reward_id"] = "renamed-stamp"
	_expect(not registry.configure(invalid), "stable optional reward identity cannot silently change and invalidate save stamps")
	for info: Dictionary in raw["levels"]:
		var id: String = info["id"]
		if ["A1-L1", "A1-L2", "A1-O1"].has(id):
			info["scene_path"] = "res://tests/fixtures/campaign/" + id.to_lower().replace("-", "_") + ".tscn"
			info["readiness"] = "accepted"
			info["accepted_commit"] = "a".repeat(40)
			info["api_revision"] = "campaign-level-1"
	_expect(registry.configure(raw) and registry.is_playable("A1-L1") and registry.is_playable("A1-O1"), "test-only accepted fixtures validate root, spawn and matching scene identity")
	invalid = raw.duplicate(true)
	invalid["levels"][0]["scene_path"] = "res://tests/fixtures/campaign/a1_l2.tscn"
	var wrong := Registry.new(invalid)
	_expect(not wrong.is_playable("A1-L1"), "existing accepted path with another level identity is not playable")
	var store := Store.new(ROOT + "campaign.json")
	var attempts := Attempts.new(registry, store)
	var story: Dictionary = _snapshot(registry, "A1-L1", 23.0, 0)
	story["player"]["reload_s"] = 0.12345678901234568
	var begun: bool = attempts.begin_story(story)
	_expect(begun, "first story starts at accepted A1-L1 with an explicit coherent snapshot: " + attempts.last_error)
	if not begun:
		_cleanup()
		quit(1)
		return
	story["player"]["hp"] = 99.0
	_expect(attempts.story_snapshot()["player"]["hp"] == 23.0, "caller cannot mutate protected story resources")
	_expect(store.read_payload()["story"]["snapshot"]["player"]["reload_s"] == 0.12345678901234568, "full-precision fractional actor clocks survive atomic disk verification")
	var after_damage: Dictionary = attempts.active_snapshot()
	after_damage["player"]["hp"] = 9.0
	after_damage["player"]["reload_s"] = 1.7
	after_damage["level"]["local"]["enemy_hp"] = 4.0
	_expect(attempts.record_snapshot(after_damage), "active state records resources and encounter state together")
	var retry: Dictionary = attempts.retry_snapshot()
	_expect(retry["player"]["hp"] == 23.0 and retry["player"]["shells"] == 0 and retry["level"]["local"]["enemy_hp"] == 7.0 and retry["level"]["local"]["charges"] == 0, "checkpoint retry restores its original resources/enemies/spent supply without healing or refreshing")
	var checkpoint: Dictionary = attempts.active_snapshot()
	checkpoint["player"]["hp"] = 14.0
	checkpoint["level"]["local"]["enemy_hp"] = 2.0
	_expect(attempts.record_snapshot(checkpoint, true) and attempts.retry_snapshot() == checkpoint, "authored checkpoint becomes one coherent retry unit")
	_expect(not attempts.begin_side("replay", "A1-L1", _snapshot(registry, "A1-L1", 100, 2)), "uncompleted main levels cannot start replay")
	_expect(attempts.complete_active() and attempts.state()["completed_main"] == ["A1-L1"], "story completion advances the record once")
	_expect(attempts.complete_active() and attempts.state()["completed_main"].size() == 1, "repeated completion does not duplicate main progress")
	var second: Dictionary = _snapshot(registry, "A1-L2", 14.0, 0)
	_expect(attempts.advance_story(second), "main transition follows canonical sequence without requiring optional clears")
	_expect(attempts.grant_equipment(["WEAPON-02"]), "explicit implemented equipment grant adds catalogue access separately from resources")
	var protected: Dictionary = attempts.story_snapshot()
	var replay: Dictionary = _snapshot(registry, "A1-L1", 100.0, 2)
	replay["equipment_ids"]["weapon"] = "WEAPON-02"
	_expect(attempts.begin_side("replay", "A1-L1", replay), "completed-level replay starts with its separate chosen unlocked equipment")
	var replay_damage: Dictionary = attempts.active_snapshot()
	replay_damage["player"]["hp"] = 2.0
	replay_damage["player"]["shells"] = 0
	replay_damage["level"]["local"]["charges"] = 2
	_expect(attempts.record_snapshot(replay_damage) and attempts.story_snapshot() == protected, "replay damage/ammo/pickups never overwrite the coherent story")
	_expect(attempts.retry_snapshot() == replay and attempts.story_snapshot() == protected, "replay retry uses its own initial checkpoint and preserves story")
	var interrupted: Dictionary = attempts.state()
	var reopened := Attempts.new(registry)
	_expect(reopened.restore_session(JSON.parse_string(JSON.stringify(interrupted))) and reopened.active_kind() == "replay" and reopened.active_snapshot()["paused"], "interrupted replay resumes as an independent paused snapshot")
	_expect(reopened.complete_active() and _same(reopened.leave_side(), protected) and _same(reopened.story_snapshot(), protected) and reopened.active_kind() == "story", "finishing replay automatically yields the entire original story and equipment")
	_expect(attempts.leave_side() == protected and attempts.state()["last_replay_equipment"]["weapon"] == "WEAPON-02", "abandoning replay restores story while remembering separate replay choices")
	_expect(attempts.complete_active() and attempts.state()["completed_main"] == ["A1-L1", "A1-L2"], "second main clear unlocks its optional parent branch")
	protected = attempts.story_snapshot()
	var optional: Dictionary = _snapshot(registry, "A1-O1", 100.0, 2)
	_expect(attempts.begin_side("optional", "A1-O1", optional) and attempts.active_kind() == "optional", "first optional play is an isolated optional attempt rather than replay")
	_expect(attempts.complete_active() and attempts.complete_active() and attempts.state()["reward_ids"] == ["A1-O1-completion-stamp"], "optional completion grants its stamp exactly once")
	_expect(attempts.leave_side() == protected and attempts.story_snapshot() == protected, "optional return restores story equipment/resources/local state automatically")
	_expect(attempts.begin_side("replay", "A1-O1", optional) and attempts.complete_active() and attempts.leave_side() == protected and attempts.state()["reward_ids"].size() == 1, "optional replay never repeats reward or advances the main route")
	var before: Dictionary = attempts.state()
	_expect(not attempts.advance_story(_snapshot(registry, "A1-L3", 100, 2)) and attempts.state() == before, "unfinished next level preserves the cleared story rather than substituting lab or fake scene")
	var corrupt_side: Dictionary = interrupted.duplicate(true)
	corrupt_side["side_attempt"]["snapshot"]["equipment_ids"]["weapon"] = "WEAPON-99"
	_expect(reopened.restore_session(corrupt_side) and reopened.active_kind() == "story" and reopened.story_snapshot() == interrupted["story"]["snapshot"] and not reopened.last_warning.is_empty(), "corrupt replay is discarded after protected story independently validates")
	corrupt_side = interrupted.duplicate(true)
	corrupt_side["last_replay_equipment"] = {"weapon": "BROKEN"}
	_expect(reopened.restore_session(corrupt_side) and reopened.story_snapshot() == interrupted["story"]["snapshot"] and reopened.state()["last_replay_equipment"].is_empty() and not reopened.last_warning.is_empty(), "corrupt remembered replay preferences cannot invalidate the protected story")
	var corrupt_story: Dictionary = before.duplicate(true)
	corrupt_story["story"]["snapshot"]["equipment_ids"]["weapon"] = "WEAPON-99"
	var coherent: Dictionary = reopened.state()
	_expect(not reopened.restore_session(corrupt_story) and reopened.state() == coherent, "invalid protected story rejects atomically without overwriting valid live state")
	corrupt_story = before.duplicate(true)
	corrupt_story["completed_main"] = ["A1-L2"]
	_expect(not reopened.restore_session(corrupt_story) and reopened.state() == coherent, "nonsequential progress cannot unlock later campaign content")
	var invalid_snapshot: Dictionary = attempts.active_snapshot()
	invalid_snapshot["equipment_ids"]["helmet"] = "BONUS"
	_expect(not attempts.record_snapshot(invalid_snapshot) and attempts.state() == before, "snapshot cannot add a fifth equipment slot")
	invalid_snapshot = attempts.active_snapshot()
	invalid_snapshot["paused"] = false
	_expect(not attempts.record_snapshot(invalid_snapshot) and attempts.state() == before, "simulation-running snapshots cannot become coherent saves")
	var loaded := Attempts.new(registry, store)
	_expect(loaded.load_saved() and _same(loaded.state(), before) and loaded.active_snapshot()["paused"], "desktop save/load round-trip retains progression, reward, gear, resources and checkpoint paused")
	var atomic: Dictionary = store.read_payload()
	var nonfinite: Dictionary = atomic.duplicate(true)
	nonfinite["story"]["snapshot"]["player"]["hp"] = INF
	_expect(not store.write_payload(nonfinite) and store.read_payload() == atomic, "nonfinite candidate cannot clobber the previous complete disk generation")
	var oversized_integer: Dictionary = atomic.duplicate(true)
	oversized_integer["story"]["snapshot"]["shell"]["unsafe_rng"] = 9223372036854775807
	_expect(not store.write_payload(oversized_integer) and store.read_payload() == atomic, "int64 RNG must be encoded as string rather than silently rounded through JSON")
	_expect(FileAccess.file_exists(ROOT + "campaign.json.bak"), "verified prior generation remains as backup")
	var semantic_bad: Dictionary = atomic.duplicate(true)
	semantic_bad["story"]["snapshot"]["equipment_ids"]["weapon"] = "CORRUPT"
	var encoded: String = JSON.stringify(semantic_bad, "", true, true)
	var primary := FileAccess.open(ROOT + "campaign.json", FileAccess.WRITE)
	primary.store_string(JSON.stringify({"format_version": 1, "generation": 100, "payload_json": encoded, "sha256": encoded.sha256_text()}))
	primary.close()
	_expect(not store.read_payload().is_empty() and store.loaded_backup and loaded.load_saved(), "checksum-valid but semantically corrupt story falls back to a protected valid backup")
	var protected_backup: String = FileAccess.get_file_as_string(ROOT + "campaign.json.bak")
	_expect(store.write_payload(atomic) and FileAccess.get_file_as_string(ROOT + "campaign.json.bak") == protected_backup, "semantically corrupt primary never replaces the valid backup during recovery")
	primary = FileAccess.open(ROOT + "campaign.json", FileAccess.WRITE)
	primary.store_string("{interrupted")
	primary.close()
	_expect(not store.read_payload().is_empty() and store.loaded_backup, "interrupted primary falls back to the verified prior generation")
	var blocked := Store.new(ROOT + "blocked.json")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(blocked.path))
	var failed := Attempts.new(registry, blocked)
	var untouched: Dictionary = failed.state()
	_expect(not failed.begin_story(_snapshot(registry, "A1-L1", 100, 2)) and failed.state() == untouched and not failed.last_error.is_empty(), "failed atomic publication retains the prior model state")
	_cleanup()
	print("Campaign persistence smoke: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _snapshot(registry: CinderCampaignRegistry, id: String, hp: float, shells: int) -> Dictionary:
	var scene: Variant = registry.entry(id).get("scene_path")
	return {
		"schema_version": 1, "level_id": id, "scene_path": scene, "paused": true,
		"equipment_ids": Equipment.STARTER.duplicate(true),
		"player": {"hp": hp, "shells": shells, "reload_s": 0.7, "dash_cooldown_s": 0.2},
		"level": {"level_id": id, "scene_path": scene, "local": {"enemy_hp": 7.0, "charges": 0, "collected_ids": ["spent"], "rng_state": "1234567890123456789"}},
		"shell": {"aim_anchor_fraction": [0.3, 0.6], "difficulty": "standard", "simulation_clock_s": 12.3},
	}

func _cleanup() -> void:
	var absolute: String = ProjectSettings.globalize_path(ROOT)
	var directory: DirAccess = DirAccess.open(absolute)
	if directory == null:
		return
	for file: String in directory.get_files():
		DirAccess.remove_absolute(absolute.path_join(file))
	for folder: String in directory.get_directories():
		DirAccess.remove_absolute(absolute.path_join(folder))
	DirAccess.remove_absolute(absolute)

func _same(a: Dictionary, b: Dictionary) -> bool:
	# Godot JSON decodes integral numbers as floats. Compare the normalized
	# transport form; actor/local schemas validate and normalize integer fields.
	return JSON.parse_string(JSON.stringify(a, "", true, true)) == JSON.parse_string(JSON.stringify(b, "", true, true))

func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
	print(("PASS: " if condition else "FAIL: ") + message)
