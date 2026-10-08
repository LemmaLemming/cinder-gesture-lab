extends SceneTree
## Actual shared shell/Horsell portrait input routing. TEST ONLY preceding Act1
## completion/unlock metadata seeds the story; it certifies no Act1 gameplay.
## No live pose, phase, HP or ammo assignment, recognizer bypass, defeat or exit.
## Optional --capture-routed saves actual 540x1170 view and public evidence.
## Optional --swipe-side=left/right (default right) selects a real routed swipe.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const Shell: Script = preload("res://scripts/campaign/shell.gd")
const Registry: Script = preload("res://scripts/campaign/registry.gd")
const Attempts: Script = preload("res://scripts/campaign/attempts.gd")
const Store: Script = preload("res://scripts/campaign/save_store.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const LevelPath: String = "res://scenes/acts/act2/a2_l1.tscn"
const TEST_ROOT: String = "user://test-a2-l1-routed-input/"
const CAPTURE_ROOT: String = "res://captures/act2/routed/"
const PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3", "A1-L4", "A1-L5"]
var _checks: int = 0
var _failures: int = 0
var _game: CinderCampaignShell
var _canonical: String = ""
var _capture_routed: bool = false
var _swipe_side: String = "right"
var _observations: Array[Dictionary] = []
var _actions: Array[Dictionary] = []
var _captures: Dictionary = {}
var _timing: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_cleanup()
	root.size = Vector2i(540, 1170)
	_capture_routed = OS.get_cmdline_user_args().has("--capture-routed")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--swipe-side="):
			_swipe_side = argument.trim_prefix("--swipe-side=")
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	if not _expect(_swipe_side in ["left", "right"], "routed swipe side is left or right"):
		_finish()
		return
	if not _expect(not _capture_routed or DisplayServer.get_name() != "headless", "native routed capture requires graphical rendering"):
		_finish()
		return
	if _capture_routed and not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_ROOT)) == OK, "create ignored routed portrait capture directory"):
		_finish()
		return
	var raw: Dictionary = JSON.parse_string(_canonical)
	for info: Dictionary in raw["levels"]:
		if info["id"] == "A2-L1":
			info["scene_path"] = LevelPath
			info["readiness"] = "accepted"
			info["accepted_commit"] = "b".repeat(40)
			info["api_revision"] = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty(), "TEST ONLY injected Horsell acceptance preserves canonical route identity") or not await _seed(registry):
		_finish()
		return
	_game = Shell.new() as CinderCampaignShell
	_expect(_game.configure_runtime(raw, TEST_ROOT + "campaign.json", TEST_ROOT + "settings.json", TEST_ROOT + "preferences.json"), "actual shell uses isolated fixture paths")
	root.add_child(_game)
	await _settle()
	_game.resume_campaign()
	await _settle()
	if not _expect(_game.campaign_error.is_empty() and _game.active_level != null and paused and _game.menu.page_name() == "resume", "real seeded Horsell installs at a paused resume boundary: " + _game.campaign_error):
		_finish()
		return
	_expect(_game.player.presentation_id == "act2_survivor" and _game.player.shells == 0 and _game.player.equipment.snapshot()["weapon"] == "WEAPON-03", "actual shared actor begins with Act2 identity, existing Heavy and initial zero ammo")
	_game.input_observed.connect(func(record: Dictionary) -> void: _observations.append(record.duplicate(true)))
	_game.player.world_action_executed.connect(func(record: Dictionary) -> void: _actions.append(record.duplicate(true)))
	var initial_clock: float = _game.player.get_world_action_clock()
	_game.resume_campaign()
	var swipe_start := Vector2(0.55, 0.72) if _swipe_side == "left" else Vector2(0.45, 0.72)
	var swipe_crossing := Vector2(0.45, 0.72) if _swipe_side == "left" else Vector2(0.55, 0.72)
	var expected_anchor := Vector2(0.36, 0.72) if _swipe_side == "left" else Vector2(0.64, 0.72)
	await _swipe(swipe_start, swipe_crossing, expected_anchor)
	if not await _wait_stable():
		_finish()
		return
	_expect(_observations.size() == 1 and _observations[0]["kind"] == "swipe_release" and _game.get_aim_anchor_normalized().is_equal_approx(expected_anchor) and _observations[0]["anchor_normalized"].is_equal_approx(expected_anchor), "actual pointer release records its final anchor, distinct from threshold crossing")
	_expect(_actions.size() == 1 and _actions[0]["kind"] == "dash" and _actions[0]["path"].size() >= 2 and _actions[0]["landing"].is_finite(), "routed swipe publishes exactly one real completed sampled dash")
	await _capture("after-swipe")
	if not _expect(_game.player.shells == 0, "early routed taps begin before natural reload; no live ammo reset"):
		_finish()
		return
	var size: Vector2 = root.get_visible_rect().size
	var first_tap: Vector2 = size * Vector2(0.76, 0.76)
	var second_tap: Vector2 = size * Vector2(0.765, 0.765)
	var expected_direction: Vector3 = _game.aim_direction(first_tap)
	var first_release_ms: int = Time.get_ticks_msec()
	_touch_tap(first_tap)
	# Viewport dispatch is synchronous: first primary must exist immediately
	# after routed release, before a second tap, timer or frame can arbitrate it.
	_expect(_observations.size() == 2 and _observations[1]["kind"] == "primary_tap" and _observations[1]["accepted"] and _actions.size() == 2 and _actions[1]["kind"] == "primary", "first routed tap immediately executes an ordinary primary")
	if _actions.size() < 2 or _observations.size() < 2:
		_finish()
		return
	var primary: Dictionary = _actions[1]
	_expect(primary["direction"].is_equal_approx(expected_direction) and _observations[1]["direction"].is_equal_approx(expected_direction) and _observations[1]["world_action_sequence"] == primary["sequence"] and primary["started_at_s"] == primary["completed_at_s"] and primary["damage_timing"] == "instant_at_execution", "actual immediate primary uses exact aim from the last final screen release and links its publication")
	var second_release_ms: int = Time.get_ticks_msec()
	_touch_tap(second_tap)
	_timing = {"tap_interval_ms": second_release_ms - first_release_ms, "tap_distance_px": first_tap.distance_to(second_tap), "simulation_elapsed_to_taps_s": _game.player.get_world_action_clock() - initial_clock}
	_expect(second_release_ms - first_release_ms <= 280 and first_tap.distance_to(second_tap) < 90.0, "actual routed second tap is nearby and within the shared timing window")
	_expect(_observations.size() == 3 and _observations[2]["kind"] == "blast_tap" and not _observations[2]["accepted"] and _actions.size() == 2 and _game.player.shells == 0, "empty nearby second tap is observed as rejected and publishes no blast or ammo spend")
	print("Actual Horsell routed input timing: ", _timing)
	_game.request_pause()
	await _settle()
	if not _expect(paused and _game.campaign_error.is_empty() and _game.menu.page_name() == "pause", "public shell pause reaches a coherent actual saved boundary: " + _game.campaign_error):
		_finish()
		return
	var observation_before: Dictionary = _game.get_input_observation_state()
	var actions_before: Array[Dictionary] = _game.player.get_world_action_records()
	var published_before: int = _actions.size()
	await _capture("paused-overlay")
	await _swipe(Vector2(0.02, 0.90), Vector2(0.09, 0.90), Vector2(0.14, 0.90))
	_touch_tap(size * Vector2(0.02, 0.96))
	await process_frame
	_expect(paused and _game.get_input_observation_state() == observation_before and _game.player.get_world_action_records() == actions_before and _actions.size() == published_before, "real pause overlay consumes routed swipe/tap without aim, input or action leakage")
	var resume_button: Button = _game.menu.find_child("ResumeButton", true, false) as Button
	if not _expect(resume_button != null, "actual pause menu exposes its Resume button"):
		_finish()
		return
	await _click(resume_button.get_global_rect().get_center())
	_expect(not paused and not _game.menu.is_open() and _game.get_input_observation_state() == observation_before and _game.player.get_world_action_records() == actions_before and _actions.size() == published_before, "real routed Resume button click unpauses and is consumed before combat")
	await _capture("resumed")
	_expect(not _game.active_level.is_completed() and _game.attempts.state()["completed_main"] == PREFIX and _game.attempts.state()["reward_ids"].is_empty(), "input checks fabricate no authored defeat, clear, exit, reward or progression")
	_finish()


func _seed(registry: CinderCampaignRegistry) -> bool:
	var preview: Node = MainScene.instantiate()
	preview.set("level_scene_path", LevelPath)
	root.add_child(preview)
	paused = true
	var hero: CinderPlayer = preview.get("player") as CinderPlayer
	_expect(hero.equip_item("WEAPON-03"), "TEST ONLY seed selects existing shared Heavy before combat")
	hero.hp = 37.0
	hero.shells = 0
	preview.call("resume_lab")
	for frame: int in range(8):
		await physics_frame
	await process_frame
	paused = true
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var camera: Camera3D = preview.get("camera") as Camera3D
	var anchor: Vector2 = preview.call("get_aim_anchor_normalized")
	var aggregate: Dictionary = {
		"schema_version": 1, "level_id": "A2-L1", "scene_path": LevelPath, "paused": true,
		"equipment_ids": hero.equipment.snapshot(), "player": hero.snapshot_state(), "level": level.snapshot_state(),
		"shell": {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Vector3(0, 18, 13)), "shake_left_s": 0.0, "difficulty_at_entry": "standard"},
	}
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var seed: Dictionary = model.state()
	seed["completed_main"] = PREFIX.duplicate()
	# Synthetic prior catalogue unlocks only, not new L1 rewards or Act1 proof.
	for id: String in hero.equipment.snapshot().values():
		if not seed["unlocked_equipment"].has(id):
			seed["unlocked_equipment"].append(id)
	print("TEST ONLY routed seed prerequisite prefix/prior catalogue unlocks: ", PREFIX, " / ", hero.equipment.snapshot().values())
	seed["story"] = {"kind": "story", "level_id": "A2-L1", "snapshot": aggregate.duplicate(true), "checkpoint": aggregate.duplicate(true)}
	var store: CinderSaveStore = Store.new(TEST_ROOT + "campaign.json")
	store.payload_validator = model.saved_payload_error
	var seed_error: String = model.state_error(seed)
	var valid: bool = not aggregate["player"].is_empty() and not aggregate["level"].is_empty() and seed_error.is_empty()
	var saved: bool = valid and store.write_payload(seed)
	if not saved:
		print("Horsell routed seed rejection: actor=%s level=%s runtime=%s model=%s store=%s" % [hero.last_snapshot_error, level.last_snapshot_error, level.get("runtime_error"), seed_error, store.last_error])
	_expect(saved, "actual captured shared actor/Horsell state stores in isolated validated seed")
	preview.free()
	_expect(not is_instance_valid(hero) and not is_instance_valid(level), "seed standalone hero/level are freed before shell installation")
	return saved


func _wait_stable() -> bool:
	for frame: int in range(90):
		if paused or not _game.campaign_error.is_empty() or _game.player.dead:
			return _expect(false, "routed swipe stops before a stable live landing: " + _game.campaign_error)
		var response: Dictionary = _game.player.get_threat_response_state()
		if response["stable"] and float(response["commitment_remaining_s"]) <= 0.00001 and float(response["primary_cooldown_left_s"]) <= 0.00001 and _actions.size() == 1:
			return true
		await physics_frame
		await process_frame
	return _expect(false, "actual routed swipe did not finish its bounded stable landing")


func _swipe(start: Vector2, crossing: Vector2, release: Vector2) -> void:
	var size: Vector2 = root.get_visible_rect().size
	var press := InputEventScreenTouch.new()
	press.index = 5
	press.pressed = true
	press.position = start * size
	root.push_input(press, true)
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.index = 5
	drag.position = crossing * size
	drag.relative = (crossing - start) * size
	root.push_input(drag, true)
	await process_frame
	var end := InputEventScreenTouch.new()
	end.index = 5
	end.position = release * size
	root.push_input(end, true)
	await process_frame


func _touch_tap(position_value: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.index = 6
	press.pressed = true
	press.position = position_value
	root.push_input(press, true)
	var release := InputEventScreenTouch.new()
	release.index = 6
	release.position = position_value
	root.push_input(release, true)


func _click(position_value: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position_value
	motion.global_position = position_value
	root.push_input(motion, true)
	await process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = position_value
	press.global_position = position_value
	root.push_input(press, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = position_value
	release.global_position = position_value
	root.push_input(release, true)
	await process_frame


func _capture(label: String) -> void:
	if not _capture_routed:
		return
	await RenderingServer.frame_post_draw
	if not _expect((label == "paused-overlay" and paused and _game.menu.is_open()) or (label != "paused-overlay" and not paused and not _game.menu.is_open()), "actual rendered routed frame matches its pause/menu label"):
		return
	var image: Image = root.get_texture().get_image()
	if not _expect(image.get_size() == Vector2i(540, 1170), "routed actual portrait texture is native 540x1170"):
		return
	var path: String = CAPTURE_ROOT + "a2-l1-routed-" + _swipe_side + "-" + label + ".png"
	if not _expect(image.save_png(path) == OK, "save actual routed portrait " + label):
		return
	var observation: Dictionary = _game.get_input_observation_state()
	var last: Dictionary = observation["last_observation"]
	var last_metadata: Dictionary = {}
	if not last.is_empty():
		var screen: Vector2 = last["screen_position_normalized"]
		last_metadata = {"kind": last["kind"], "accepted": last["accepted"], "direction": Codec.vector3(last["direction"]), "screen_position_normalized": [screen.x, screen.y], "world_action_sequence": last["world_action_sequence"], "action_clock_s": last["action_clock_s"]}
	var anchor: Vector2 = _game.get_aim_anchor_normalized()
	var action_metadata: Array[Dictionary] = []
	for action: Dictionary in _actions:
		action_metadata.append({"kind": action["kind"], "sequence": action["sequence"], "started_at_s": action["started_at_s"], "completed_at_s": action["completed_at_s"], "direction": Codec.vector3(action["direction"]), "sampled_path_points": action.get("path", []).size()})
	_captures[label] = {"image": path, "paused": paused, "menu": _game.menu.page_name() if _game.menu.is_open() else "closed", "anchor_normalized": [anchor.x, anchor.y], "input_sequence": observation["sequence"], "last_observation": last_metadata, "actions": action_metadata, "hero_position": Codec.vector3(_game.player.global_position), "hp": _game.player.hp, "shells": _game.player.shells, "presentation_id": _game.player.presentation_id, "equipment": _game.player.equipment.snapshot()}
	var file: FileAccess = FileAccess.open(CAPTURE_ROOT + "a2-l1-routed-" + _swipe_side + "-evidence.json", FileAccess.WRITE)
	if _expect(file != null, "open ignored routed input public evidence sidecar"):
		file.store_string(JSON.stringify({"scope": "actual shared-shell portrait input routing; TEST ONLY prerequisite prefix/unlocks; no fullfight/human balance acceptance", "swipe_side": _swipe_side, "timing": _timing, "captures": _captures}, "\t", true, true))
	print("Actual routed portrait: ", path)


func _settle() -> void:
	for frame: int in range(4):
		await process_frame


func _finish() -> void:
	if is_instance_valid(_game):
		var old_nodes: Array[Node] = [_game, _game.player, _game.active_level, _game.fx]
		if is_instance_valid(_game.active_level):
			old_nodes.append(_game.active_level.get_node("HorsellHeathKit"))
			old_nodes.append(_game.active_level.get_node("DryGround"))
		_game.free()
		for node: Node in old_nodes:
			_expect(not is_instance_valid(node), "routed fixture cleanup frees actual old actor/level/effects/scenery refs")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical, "canonical campaign registry bytes remain unchanged")
	paused = false
	_cleanup()
	print("Horsell routed input smoke: %d checks, %d failures; TEST ONLY prefix/unlocks, actual portrait swipe/tap/menu routing" % [_checks, _failures])
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
