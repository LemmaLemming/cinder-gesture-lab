extends SceneTree
## TEST ONLY Act1 prefix and transport-checkpoint seed. Actual Horsell arrival,
## shared dash, pause and retry are exercised; no authored clear/exit is claimed.
## Saved components prove the same player's actual feet position without moving
## the live or fresh receiver during prevalidation.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const Shell: Script = preload("res://scripts/campaign/shell.gd")
const Registry: Script = preload("res://scripts/campaign/registry.gd")
const Attempts: Script = preload("res://scripts/campaign/attempts.gd")
const Store: Script = preload("res://scripts/campaign/save_store.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const LevelPath: String = "res://scenes/acts/act2/a2_l1.tscn"
const TEST_ROOT: String = "user://test-a2-l1-aggregate-context/"
const PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3", "A1-L4", "A1-L5"]
var _checks: int = 0
var _failures: int = 0
var _game: CinderCampaignShell
var _fresh: Node
var _canonical: String = ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_cleanup()
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var raw: Dictionary = JSON.parse_string(_canonical)
	for info: Dictionary in raw["levels"]:
		if info["id"] == "A2-L1":
			info["scene_path"] = LevelPath
			info["readiness"] = "accepted"
			info["accepted_commit"] = "b".repeat(40)
			info["api_revision"] = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty(), "TEST ONLY registry retains canonical campaign links") or not await _seed(registry):
		_finish()
		return
	_game = Shell.new() as CinderCampaignShell
	_expect(_game.configure_runtime(raw, TEST_ROOT + "campaign.json", TEST_ROOT + "settings.json", TEST_ROOT + "preferences.json"), "actual shell uses isolated injected registry/save paths")
	root.add_child(_game)
	await _settle()
	_game.resume_campaign()
	await _settle()
	if not _expect(_game.campaign_error.is_empty() and _game.active_level != null and paused, "actual Horsell saved arrival installs paused: " + _game.campaign_error):
		_finish()
		return
	_game.resume_campaign()
	if not _expect(_game.player.request_dash(Vector3.RIGHT), "actual shared player starts a dash during the admitted arrival warning"):
		_finish()
		return
	await _ticks(2)
	_game.request_pause()
	await _settle()
	var saved: Dictionary = _json(_game.capture_campaign_snapshot())
	if not _expect(not saved.is_empty(), "paused mid-dash aggregate captures through actual shell: " + _game.campaign_error):
		_finish()
		return
	var running: Dictionary = saved["level"]["local"]["exchange"]["records"]["arrival"]
	_expect(float(saved["player"]["clocks"]["dash_left_s"]) > 0.0 and running["status"] == "running" and Codec.same_values(saved["player"]["motion"]["position"], running["sample"]["position"]), "actual moving player and running arrival retain the same damage sample")
	_expect(_game.player.snapshot_error(saved["player"]).is_empty() and _game.active_level.snapshot_error(saved["level"]).is_empty(), "actual current player/local components individually validate")
	# This is an explicit transport-test checkpoint, not an authored encounter
	# boundary or evidence that the player defeated the arrival Scout.
	if not _expect(_game.attempts.record_snapshot(saved, true), "TEST ONLY moving aggregate becomes retry checkpoint: " + _game.attempts.last_error):
		_finish()
		return
	_game.resume_campaign()
	await _ticks(3)
	_game.request_pause()
	await _settle()
	var later: Dictionary = _json(_game.capture_campaign_snapshot())
	if not _expect(not later.is_empty() and not Codec.same_values(later["player"]["motion"]["position"], saved["player"]["motion"]["position"]), "shared player actually travels past the saved moving position"):
		_finish()
		return
	_expect(_game.active_level.snapshot_error(saved["level"]).is_empty(), "pure local preflight accepts internally coherent saved state independently of receiver position")
	var events: Array[String] = []
	_observe(_game.active_level, _game.player, events)
	_expect(not _game.active_level.restore_state(saved["level"]) and Codec.same_values(_game.capture_campaign_snapshot(), later) and events.is_empty(), "actual level commit rejects an unrestored shared player before any owned mutation")
	var caller_before: Dictionary = saved.duplicate(true)
	_expect(_game.active_level.snapshot_error_with_player(saved["level"], saved["player"]).is_empty(), "saved-player hook validates moving arrival independently of later live position")
	_expect(Codec.same_values(saved, caller_before) and Codec.same_values(_game.capture_campaign_snapshot(), later) and events.is_empty(), "accepted pure preflight changes no caller/live component or callback")
	var before_model: Dictionary = _game.attempts.state()
	for direction: int in range(2):
		var forged: Dictionary = saved.duplicate(true) if direction == 0 else later.duplicate(true)
		forged["player"] = (later["player"] if direction == 0 else saved["player"]).duplicate(true)
		forged["shell"] = (later["shell"] if direction == 0 else saved["shell"]).duplicate(true)
		_expect(_game.player.snapshot_error(forged["player"]).is_empty(), "cross-forged player is an individually valid actual capture")
		_expect(not _game.active_level.snapshot_error_with_player(forged["level"], forged["player"]).is_empty(), "saved player rejects the independently valid opposite local sample")
		_expect(not _game.attempts.record_snapshot(forged) and Codec.same_values(_game.attempts.state(), before_model) and Codec.same_values(_game.capture_campaign_snapshot(), later) and events.is_empty(), "whole shell/model cross-pair refusal is atomic")
	var forged_progress: Dictionary = saved["level"].duplicate(true)
	forged_progress["progress"]["checkpoint_ids"] = {"unearned": "encounter"}
	forged_progress["progress"]["checkpoint_id"] = "unearned"
	forged_progress["progress"]["checkpoint_kind"] = "encounter"
	_expect(not _game.active_level.snapshot_error_with_player(forged_progress, saved["player"]).is_empty(), "aggregate override retains exact authored checkpoint history validation")
	_fresh = MainScene.instantiate()
	_fresh.set("level_scene_path", LevelPath)
	root.add_child(_fresh)
	paused = true
	var fresh_hero: CinderPlayer = _fresh.get("player") as CinderPlayer
	var fresh_level: CinderLevel = _fresh.get("active_level") as CinderLevel
	var fresh_before: Dictionary = {"player": fresh_hero.snapshot_state(), "level": fresh_level.snapshot_state()}
	var fresh_events: Array[String] = []
	_observe(fresh_level, fresh_hero, fresh_events)
	_expect(not fresh_hero.global_position.is_equal_approx(Codec.read_vector3(saved["player"]["motion"]["position"])) and not fresh_before["player"].is_empty() and not fresh_before["level"].is_empty(), "fresh actual scene remains at a different idle spawn pose")
	_expect(fresh_hero.snapshot_error(saved["player"]).is_empty() and fresh_level.snapshot_error_with_player(saved["level"], saved["player"]).is_empty(), "fresh pure prevalidation accepts the saved moving actor/arrival pair")
	_expect(Codec.same_values(fresh_hero.snapshot_state(), fresh_before["player"]) and Codec.same_values(fresh_level.snapshot_state(), fresh_before["level"]) and fresh_events.is_empty(), "fresh pure proof preserves spawn, idle sources, clocks and resources")
	_expect(fresh_hero.restore_state(saved["player"]) and fresh_level.restore_state(saved["level"]) and String(fresh_level.get("runtime_error")).is_empty(), "ordered actual player then authored level commit succeeds after complete preflight")
	_expect(Codec.same_values(fresh_hero.snapshot_state(), saved["player"]) and Codec.same_values(fresh_level.snapshot_state(), saved["level"]) and fresh_events.is_empty(), "ordered restore is silent and retains exact moving path/clock/deadlines")
	_fresh.free()
	_fresh = null
	_game.menu.difficulty_preference_requested.emit("challenge")
	_expect(_game.get_difficulty_preference() == "challenge" and _game.attempts.state()["story"]["checkpoint"]["level"]["local"]["profile_id"] == "standard", "new preference does not retune the saved fixed encounter")
	var old_level: CinderLevel = _game.active_level
	var old_hero: CinderPlayer = _game.player
	var old_scenery: Node = old_level.get_node("HorsellHeathKit")
	_game.request_retry()
	await _settle()
	_expect(_game.campaign_error.is_empty() and paused and _game.menu.page_name() == "resume", "public retry reconstructs moving checkpoint under a different current preference: " + _game.campaign_error)
	var retried: Dictionary = _json(_game.capture_campaign_snapshot())
	_expect(not retried.is_empty() and Codec.same_values(retried, saved) and _game.get_difficulty_preference() == "challenge", "retry preserves exact saved standard encounter/player/input resources while keeping the new preference")
	_expect(not is_instance_valid(old_level) and not is_instance_valid(old_hero) and not is_instance_valid(old_scenery), "actual retry frees external references to old level/hero/scenery")
	_expect(not _game.active_level.is_completed() and _game.attempts.state()["completed_main"] == PREFIX and _game.attempts.state()["reward_ids"].is_empty(), "context checks fabricate no Horsell clear, exit, reward or later-level progress")
	_finish()


func _seed(registry: CinderCampaignRegistry) -> bool:
	var preview: Node = MainScene.instantiate()
	preview.set("level_scene_path", LevelPath)
	root.add_child(preview)
	paused = true
	var hero: CinderPlayer = preview.get("player") as CinderPlayer
	_expect(hero.equip_item("WEAPON-03"), "seed selects existing shared Heavy Edge before combat")
	hero.hp = 37.0
	hero.shells = 0
	preview.call("resume_lab")
	await _ticks(8)
	paused = true
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var camera: Camera3D = preview.get("camera") as Camera3D
	var anchor: Vector2 = preview.call("get_aim_anchor_normalized")
	var shell_state: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Vector3(0, 18, 13)), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}
	var aggregate: Dictionary = _json({"schema_version": 1, "level_id": "A2-L1", "scene_path": LevelPath, "paused": true, "equipment_ids": hero.equipment.snapshot(), "player": hero.snapshot_state(), "level": level.snapshot_state(), "shell": shell_state})
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var state: Dictionary = model.state()
	state["completed_main"] = PREFIX.duplicate()
	# Synthetic prior catalogue unlocks for the TEST ONLY Heavy seed, not actual
	# Act1 completion or newly granted Horsell equipment/reward/progression.
	var selected_ids: Array = hero.equipment.snapshot().values()
	for id: String in selected_ids:
		if not state["unlocked_equipment"].has(id):
			state["unlocked_equipment"].append(id)
	print("TEST ONLY synthetic prior catalogue unlocks for aggregate seed gear: ", selected_ids)
	state["story"] = {"kind": "story", "level_id": "A2-L1", "snapshot": aggregate.duplicate(true), "checkpoint": aggregate.duplicate(true)}
	var store: CinderSaveStore = Store.new(TEST_ROOT + "campaign.json")
	store.payload_validator = model.saved_payload_error
	var seed_error: String = model.state_error(state)
	var valid: bool = not aggregate["player"].is_empty() and not aggregate["level"].is_empty() and seed_error.is_empty()
	var saved: bool = valid and store.write_payload(state)
	if not saved:
		print("Horsell aggregate seed rejection: actor_error=%s level_error=%s runtime_error=%s model_error=%s store_error=%s actor_keys=%s level_keys=%s" % [hero.last_snapshot_error, level.last_snapshot_error, level.get("runtime_error"), seed_error, store.last_error, aggregate["player"].keys(), aggregate["level"].keys()])
	_expect(saved, "isolated TEST ONLY Act1 prefix stores actual shared Horsell state: " + store.last_error)
	preview.free()
	_expect(not is_instance_valid(hero) and not is_instance_valid(level), "seed standalone scene is freed before actual shell installation")
	return saved


func _observe(level: CinderLevel, hero: CinderPlayer, events: Array[String]) -> void:
	hero.world_action_executed.connect(func(_record: Dictionary) -> void: events.append("action"))
	hero.died.connect(func() -> void: events.append("death"))
	hero.equipment_changed.connect(func(_id: String) -> void: events.append("gear"))
	level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: events.append("checkpoint"))
	level.completion_requested.connect(func(_id: String, _completion: String) -> void: events.append("completion"))
	level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: events.append("exit"))
	level.get_node("HorsellThreatScheduler").connect("reservation_invalidated", func(_id: String, _reason: String) -> void: events.append("cancel"))
	level.get_node("HorsellRayExchanges").connect("state_changed", func(_id: String, _state: Dictionary) -> void: events.append("phase"))
	level.get_node("HorsellRayExchanges").connect("hit_resolved", func(_id: String, _hit: Dictionary) -> void: events.append("hit"))


func _json(value: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(value, "", true, true))


func _ticks(count: int) -> void:
	for index: int in range(count):
		await physics_frame
	await process_frame


func _settle() -> void:
	for index: int in range(4):
		await process_frame


func _finish() -> void:
	if is_instance_valid(_fresh):
		_fresh.free()
	if is_instance_valid(_game):
		_game.free()
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical, "canonical registry bytes remain unchanged")
	paused = false
	_cleanup()
	print("Horsell aggregate context smoke: %d checks, %d failures; TEST ONLY prefix/checkpoint, actual arrival/moving save/retry" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _cleanup() -> void:
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT))


func _expect(condition: bool, message: String) -> bool:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
	return condition
