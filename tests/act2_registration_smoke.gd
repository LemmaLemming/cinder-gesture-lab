extends SceneTree
## Actual production registry/Title/Journey and format2 shell lifecycle.
## TEST ONLY prerequisite A1 completion prefix and initial HP/ammo in an isolated
## save. The paused A2 player/local context is captured from its actual scene.
## No registry injection, live defeat/pose manipulation or route-clear claim.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const Game = preload("res://scripts/game.gd")
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Attempts = preload("res://scripts/campaign/attempts.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const TEST_ROOT: String = "user://test-act2-registration/"
const LEVEL_PATH: String = "res://scenes/acts/act2/a2_l1.tscn"
const ACCEPTED_COMMIT: String = "a96edfaddd22e206438e616a8b4080e5c5cdce7a"
const FIXTURE_PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3", "A1-L4", "A1-L5"]
const CAPTURE_ROOT: String = "res://captures/act2-registration/"

var checks: int = 0
var failures: int = 0
var game: CinderCampaignShell
var graphical: bool = false
var _finished: bool = false
var _registry_text: String = ""


func _initialize() -> void:
	graphical = "--portrait" in OS.get_cmdline_user_args()
	create_timer(60.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "production A2 registration completes within its watchdog")
			_finish())
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_cleanup()
	_registry_text = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var registry := Registry.new()
	if not _expect(registry.last_error.is_empty() and registry.ids().size() == 24, "production registry retains all24 canonical identities"):
		_finish()
		return
	var accepted: Dictionary = registry.entry("A2-L1")
	if not _expect(accepted.get("readiness") == "accepted" and accepted.get("accepted_commit") == ACCEPTED_COMMIT and accepted.get("scene_path") == LEVEL_PATH and registry.scene_error("A2-L1").is_empty(), "actual production A2 entry validates its exact authored candidate and scene"):
		_finish()
		return
	var playable: Array[String] = []
	for id: String in registry.ids():
		if registry.is_playable(id):
			playable.append(id)
	_expect(playable == ["A1-L1", "A2-L1", "A2-L2", "A3-L1"], "only independently accepted scenes are playable, including the separately registered A2-L2")
	game = _new_shell()
	await _settle()
	if not _expect(game.campaign_error.is_empty() and paused and game.active_level == null and game.menu.page_name() == "title", "production Title loads without an actor or invented prior progress: " + game.campaign_error):
		_finish()
		return
	_expect(game.attempts.state()["completed_main"].is_empty(), "isolated first launch has no completed prior levels")
	await _capture("title-locked")
	await _click(_find("JourneyButton") as Control)
	await _click(_find("Act2Shortcut") as Control)
	await _click(_find("Node_A2_L1") as Control)
	var node := _find("Node_A2_L1") as Button
	var action := _find("LevelCardAction") as Button
	if not _expect(game.menu.page_name() == "journey" and paused and node != null and node.get_meta("campaign_state") == "locked" and action != null and action.disabled, "real Journey keeps accepted A2-L1 locked until the A1 prefix is completed"):
		_finish()
		return
	_expect(registry.entry("A2-L1").readiness == "accepted" and (_find("LevelCardBody") as Label).text.contains("A1-L5"), "accepted readiness does not bypass the visible actual A1-L5 prerequisite")
	await _capture("journey-locked")
	var empty_model: String = Exact.stringify(game.attempts.state())
	await _click(action)
	_expect(game.active_level == null and Exact.stringify(game.attempts.state()) == empty_model, "clicking the disabled locked card cannot load A2 or fabricate progress")
	game.free()
	game = null
	if not await _seed_actual_story(registry):
		_finish()
		return
	game = _new_shell()
	await _settle()
	if not _expect(game.campaign_error.is_empty() and paused and game.active_level == null and game.menu.page_name() == "title", "fresh real Title accepts the isolated validated A2 story save: " + game.campaign_error):
		_finish()
		return
	_expect(game.attempts.state()["completed_main"] == FIXTURE_PREFIX and game.attempts.state()["side_attempt"] == null and not (_find("ContinueStoryButton") as Button).disabled, "TEST ONLY A1 prefix unlocks an uncompleted protected A2 story, without a side attempt")
	await _capture("title-seeded")
	await _click(_find("JourneyButton") as Control)
	await _click(_find("Act2Shortcut") as Control)
	await _click(_find("Node_A2_L1") as Control)
	node = _find("Node_A2_L1") as Button
	action = _find("LevelCardAction") as Button
	if not _expect(game.menu.page_name() == "journey" and node != null and node.get_meta("campaign_state") == "current" and action != null and not action.disabled and action.text == "Continue Story", "real seeded Journey selects enabled A2 current-story Continue action"):
		_finish()
		return
	_expect((_find("Node_A2_L2") as Button).get_meta("campaign_state") == "locked", "A2-L2 remains progression-locked until this actual A2-L1 story completes")
	await _capture("journey-seeded")
	await _click(action)
	if not _actual_entry():
		_finish()
		return
	var entry: Dictionary = game.capture_campaign_snapshot()
	if not _expect(not entry.is_empty() and entry.level.local_snapshot_version == 2, "actual production entry captures full localversion2 actor/level/shell context"):
		_finish()
		return
	_expect(game.player.hp == 37.0 and game.player.shells == 0 and entry.player.world_actions.clock_s == 0.0 and entry.player.world_actions.sequence == 0 and game.get_input_observation_state()["sequence"] == 0, "initial TEST ONLY lowHP/emptyammo remain exact with no executed action or input")
	_expect(_disk_state_matches(), "production entry retains a real checked format2 save with an exact attempt payload")
	var entry_encoded: String = Exact.stringify(entry)
	var entry_anchor: Vector2 = game.get_aim_anchor_normalized()
	await _click(_find("ResumeButton") as Control)
	_expect(not paused and not game.menu.is_open() and game.get_aim_anchor_normalized() == entry_anchor and game.player.get_world_action_records().is_empty() and game.get_input_observation_state()["sequence"] == 0, "actual GUI Resume is consumed before aim/input/action publication")
	await _capture("arrival")
	await _swipe(Vector2(0.55, 0.72), Vector2(0.45, 0.72), Vector2(0.36, 0.72))
	if not await _wait_finished_dash():
		_finish()
		return
	game.request_pause()
	await _settle()
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _expect(game.campaign_error.is_empty() and paused and not saved.is_empty() and game.menu.page_name() == "pause", "public pause commits the real routed dash and Horsell aggregate at its deferred barrier: " + game.campaign_error):
		_finish()
		return
	var saved_encoded: String = Exact.stringify(saved)
	var dash: Dictionary = game.player.get_world_action_records()[0]
	_expect(dash.kind == "dash" and dash.path.size() >= 2 and dash.completed_at_s > dash.started_at_s and saved.player.world_actions.sequence == 1 and game.get_aim_anchor_normalized().is_equal_approx(Vector2(0.36, 0.72)), "actual routed release retains sampled physical dash and distinct final screen-space anchor")
	_expect(saved_encoded != entry_encoded and saved.player.world_actions.clock_s > entry.player.world_actions.clock_s and saved.level.local.scheduler.clock_s > entry.level.local.scheduler.clock_s and saved.shell.camera_focus != entry.shell.camera_focus, "live movement changes actual clocks/path/camera before coherent save")
	_expect(saved.player.resources.hp == 37.0 and saved.player.resources.shells == 0 and saved.equipment_ids == entry.equipment_ids and saved.shell.input_sequence == 1 and not saved.shell.last_input_observation.is_empty(), "real paused save preserves low resources, gear and routed input without refill")
	_expect(game.player.snapshot_error(saved.player).is_empty() and game.active_level.snapshot_error_with_player(saved.level, saved.player).is_empty() and Exact.stringify(game.attempts.active_snapshot()) == saved_encoded, "actual stored full saved-player/local aggregate prevalidates and matches active attempt")
	_expect(Exact.stringify(game.attempts.state().story.checkpoint) == entry_encoded and game.attempts.state()["completed_main"] == FIXTURE_PREFIX and not game.active_level.is_completed(), "entry checkpoint and TEST ONLY prerequisite prefix are protected; no A2 clear is fabricated")
	_expect(_disk_state_matches(), "actual pause publishes matching exact format2 disk state")
	await _settle()
	_expect(Exact.stringify(game.capture_campaign_snapshot()) == saved_encoded, "paused render frames freeze actor/path, encounter samples, clocks/input/camera exactly")
	var first_refs: Array[Dictionary] = _old_refs()
	game.free()
	game = null
	_expect_refs_freed(first_refs, "closing the first real shell")
	game = _new_shell()
	await _settle()
	if not _expect(game.campaign_error.is_empty() and paused and game.active_level == null and game.menu.page_name() == "title" and not (_find("ContinueStoryButton") as Button).disabled, "fresh production Title offers real durable Continue without a duplicate live world: " + game.campaign_error):
		_finish()
		return
	await _click(_find("ContinueStoryButton") as Control)
	if not _actual_entry():
		_finish()
		return
	_expect(Exact.stringify(game.capture_campaign_snapshot()) == saved_encoded and game.get_aim_anchor_normalized().is_equal_approx(Vector2(0.36, 0.72)), "fresh GUI Continue restores the entire exact format2 aggregate with no clock/path/input/camera retiming")
	_expect(game.player.hp == saved.player.resources.hp and game.player.shells == saved.player.resources.shells and game.player.get_world_action_records().size() == 1, "Continue neither heals nor fills ammo nor republishes the past dash")
	await _click(_find("ResumeButton") as Control)
	game.request_pause()
	await _settle()
	var retry_refs: Array[Dictionary] = _old_refs()
	await _click(_find("RetryButton") as Control)
	if not _actual_entry():
		_finish()
		return
	_expect(Exact.stringify(game.capture_campaign_snapshot()) == entry_encoded and game.player.hp == 37.0 and game.player.shells == 0 and game.player.get_world_action_records().is_empty(), "real GUI Retry restores the exact initial checkpoint/resources/input/camera without a fresh reset or past-action delivery")
	_expect_refs_freed(retry_refs, "actual GUI Retry")
	_expect(game.attempts.state()["completed_main"] == FIXTURE_PREFIX and game.attempts.state()["reward_ids"].is_empty() and game.attempts.state()["side_attempt"] == null and not game.active_level.is_completed(), "Continue/Retry create no A2 completion, reward or isolated replay")
	_expect(_disk_state_matches(), "Retry persists its real exact format2 attempt")
	var last_refs: Array[Dictionary] = _old_refs()
	game.free()
	game = null
	_expect_refs_freed(last_refs, "closing the retried shell")
	_expect(get_nodes_in_group("required_cues").is_empty() and get_nodes_in_group("enemies").is_empty(), "disposed production worlds leave no required cue or actor group member")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_text, "fixture leaves production registry bytes unchanged")
	_finish()


func _seed_actual_story(registry: CinderCampaignRegistry) -> bool:
	# Explicit TEST ONLY initial prerequisite/resource seed. No caller chooses
	# a gameplay phase, moves a live actor, completes A2 or injects registry data.
	var preview: Node = MainScene.instantiate()
	preview.set("level_scene_path", LEVEL_PATH)
	root.add_child(preview)
	paused = true
	await _settle()
	var player: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var camera: Camera3D = preview.get("camera") as Camera3D
	var initial: Dictionary = player.snapshot_state()
	initial.resources.hp = 37.0
	initial.resources.shells = 0
	if not _expect(player.restore_state(initial), "TEST ONLY initial resource seed uses validated quiet public shared actor restore"):
		preview.free()
		return false
	var actor: Dictionary = player.snapshot_state()
	var local: Dictionary = level.snapshot_state()
	var anchor: Vector2 = preview.call("get_aim_anchor_normalized")
	var shell_state: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Game.CAMERA_OFFSET), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}
	var aggregate: Dictionary = {"schema_version": 1, "level_id": "A2-L1", "scene_path": LEVEL_PATH, "paused": true, "equipment_ids": player.equipment.snapshot(), "player": actor, "level": local, "shell": shell_state}
	var store: CinderSaveStore = Store.new(TEST_ROOT + "campaign.json")
	var model: CinderCampaignAttempts = Attempts.new(registry, store)
	var seed: Dictionary = model.state()
	seed["completed_main"] = FIXTURE_PREFIX.duplicate()
	seed["story"] = {"kind": "story", "level_id": "A2-L1", "snapshot": aggregate.duplicate(true), "checkpoint": aggregate.duplicate(true)}
	var actual_error: String = level.snapshot_error_with_player(local, actor) if not local.is_empty() and not actor.is_empty() else "Actual paused scene capture failed"
	var accepted: bool = actual_error.is_empty() and model.state_error(seed).is_empty() and model.restore_session(seed) and store.write_payload(model.state())
	_expect(accepted, "TEST ONLY prerequisite A1 prefix/actual paused A2 context validates and writes through public attempts/store: " + actual_error + " " + model.last_error + " " + store.last_error)
	_expect(player.presentation_id == "act2_survivor" and player.get_world_action_records().is_empty() and local.get("local", {}).get("scheduler", {}).get("clock_s") == 0.0, "seed source is the real unchanged initial Horsell world/shared Act2 actor")
	var actor_ref: WeakRef = weakref(player)
	var level_ref: WeakRef = weakref(level)
	preview.free()
	_expect(actor_ref.get_ref() == null and level_ref.get_ref() == null, "seed preview actor/level are destroyed before actual production Journey installation")
	print("TEST ONLY prerequisite prefix: ", FIXTURE_PREFIX, "; not Act1 gameplay evidence; A2 story remains uncleared")
	return accepted


func _new_shell() -> CinderCampaignShell:
	var result: CinderCampaignShell = Shell.new()
	_expect(result.configure_runtime({}, TEST_ROOT + "campaign.json", TEST_ROOT + "settings.json", TEST_ROOT + "preferences.json"), "production registry configures only isolated test user paths")
	root.add_child(result)
	return result


func _actual_entry() -> bool:
	if not _expect(game.campaign_error.is_empty() and is_instance_valid(game.active_level) and paused and game.menu.page_name() == "resume", "production A2 installation is valid and paused at actual Resume: " + game.campaign_error):
		return false
	return _expect(game.active_level.level_id == "A2-L1" and game.active_level.scene_file_path == LEVEL_PATH and game.active_level.hero == game.player and game.active_level.effects == game.fx and game.player.presentation_id == "act2_survivor", "exact production Horsell scene owns the common actor/effects with selected Act2 presentation")


func _disk_state_matches() -> bool:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEST_ROOT + "campaign.json"))
	if not raw is Dictionary or raw.get("format_version") != 2 or not raw.get("payload_json") is String or not (raw.get("generation") is float or raw.get("generation") is int) or float(raw["generation"]) < 1.0:
		return false
	var disk: CinderSaveStore = Store.new(TEST_ROOT + "campaign.json")
	disk.payload_validator = game.attempts.saved_payload_error
	var payload: Dictionary = disk.read_payload()
	return disk.last_error.is_empty() and Exact.stringify(payload) == Exact.stringify(game.attempts.state()) and raw["payload_json"] == Exact.stringify(payload) and raw.get("sha256") == String(raw["payload_json"]).sha256_text()


func _find(node_name: String) -> Node:
	return game.menu.find_child(node_name, true, false)


func _click(control: Control) -> void:
	if control == null:
		_expect(false, "required actual GUI control exists")
		return
	await _settle()
	var at: Vector2 = control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	root.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = at
	press.global_position = at
	press.pressed = true
	root.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release, true)
	await _settle()


func _swipe(start: Vector2, crossing: Vector2, release: Vector2) -> void:
	var size: Vector2 = root.get_visible_rect().size
	var press := InputEventScreenTouch.new()
	press.index = 3
	press.position = start * size
	press.pressed = true
	root.push_input(press, true)
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = crossing * size
	drag.relative = (crossing - start) * size
	root.push_input(drag, true)
	await process_frame
	var end := InputEventScreenTouch.new()
	end.index = 3
	end.position = release * size
	root.push_input(end, true)
	await process_frame


func _wait_finished_dash() -> bool:
	for frame: int in range(90):
		if paused or game.player.dead or not game.campaign_error.is_empty():
			return _expect(false, "actual short routed dash remains a live encounter: " + game.campaign_error)
		var response: Dictionary = game.player.get_threat_response_state()
		if response.get("stable", false) and float(response.get("commitment_remaining_s", 1.0)) <= 0.0 and game.player.get_world_action_records().size() == 1:
			return true
		await physics_frame
		await process_frame
	return _expect(false, "routed actual dash finishes before the bounded registration pause")


func _old_refs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var nodes: Array[Node] = [game.active_level, game.player, game.fx, game.active_level.get_node("DryGround"), game.active_level.get_node("HorsellHeathKit"), game.active_level.get_node("HorsellThreatScheduler"), game.active_level.get_node("HorsellRayExchanges")]
	for actor: Node in get_nodes_in_group("enemies"):
		if game.active_level.is_ancestor_of(actor):
			nodes.append(actor)
	for cue: Node in get_nodes_in_group("required_cues"):
		if game.active_level.is_ancestor_of(cue):
			nodes.append(cue)
	for node: Node in nodes:
		result.append({"label": String(node.name), "ref": weakref(node)})
	return result


func _expect_refs_freed(refs: Array[Dictionary], reason: String) -> void:
	for entry: Dictionary in refs:
		_expect((entry["ref"] as WeakRef).get_ref() == null, reason + " frees actual " + String(entry["label"]))


func _capture(label: String) -> void:
	if not graphical:
		return
	if not _expect(DisplayServer.get_name() != "headless", "optional portrait evidence uses an actual graphical renderer"):
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_ROOT))
	var picture: Image = root.get_texture().get_image()
	_expect(picture.get_size() == Vector2i(540, 1170) and picture.save_png(CAPTURE_ROOT + label + ".png") == OK, "actual540x1170 production portrait captured: " + label)


func _settle() -> void:
	for frame: int in range(8):
		await process_frame


func _cleanup() -> void:
	for filename: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT + filename))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT))


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if is_instance_valid(game):
		game.free()
	game = null
	paused = false
	_cleanup()
	print("Production Act2 registration: %d checks, %d failures; TEST ONLY prerequisite prefix/resources, actual production registry/GUI/format2 lifecycle; no authored route-clear claim" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _expect(condition: bool, message: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)
	return condition
