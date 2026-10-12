extends "res://tests/campaign_shell_smoke.gd"
## Focused shared-menu regression. Actual Shell/Player/format-2 SaveStore, with the
## existing TEST ONLY live_a1_l1 scene supplied through in-memory metadata.
## HP/ammo assignments below are disclosed TEST seeds, not earned gameplay.
## Selector and comparison-button signals exercise actual UI callbacks; they
## provide no GUI hit-test, physical input, portrait, replay or full-route claim.

const ReplayEquipment = preload("res://scripts/equipment.gd")
const ReplayArt = preload("res://scripts/pixel_sprite.gd")
const CHECKPOINT_ID: String = "comparison-checkpoint"
const COMPARISON_SUFFIX: String = "; larger max HP does not heal. Replay starting resources follow the level's fresh-start policy."
var _isolated_root: String = "user://test-replay-comparison-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
var _events: Array[String] = []
var _watchdog: Timer

func _run() -> void:
	_watchdog = Timer.new()
	_watchdog.process_mode = Node.PROCESS_MODE_ALWAYS
	_watchdog.one_shot = true
	_watchdog.wait_time = 60.0
	_watchdog.timeout.connect(_watchdog_expired)
	root.add_child(_watchdog)
	_watchdog.start()
	root.size = Vector2i(540, 1170)
	_cleanup()
	raw = JSON.parse_string(FileAccess.get_file_as_string(Registry.DATA_PATH))
	# Only this plain existing fixture is made accepted in this TEST registry.
	for info: Dictionary in raw.levels:
		if info.id == "A1-L1":
			info.scene_path = "res://tests/fixtures/campaign/live_a1_l1.tscn"
			info.readiness = "accepted"
			info.accepted_commit = "a".repeat(40)
			info.api_revision = Registry.API_REVISION
	game = _new_shell()
	await _settle()
	_expect(paused and game.player == null and game.active_level == null and game.menu.page_name() == "title", "actual fresh Title has no Player or active attempt")
	game.menu.begin_story_requested.emit()
	await _settle()
	_expect(game.campaign_error.is_empty() and is_instance_valid(game.player) and is_instance_valid(game.active_level), "public Begin installs the actual shared Player and test floor: " + game.campaign_error)
	if not is_instance_valid(game.player) or not is_instance_valid(game.active_level):
		await _dispose_shell()
		_finish()
		return
	game.input_observed.connect(_input_seen)
	game.aim_anchor_changed.connect(_anchor_seen)
	game.player.world_action_executed.connect(_world_action_seen)
	_expect(game.player.equipment.snapshot() == ReplayEquipment.STARTER, "actual story starts with canonical static starter gear, without grants")
	_expect(game.attempts.state().unlocked_equipment.has("CLOTH-J2") and game.attempts.state().unlocked_equipment.has("CLOTH-P2"), "existing implemented J2 and P2 are already available, without rewards or abilities")
	# Fresh story has the genuine entry checkpoint; no checkpoint ID is injected.
	game.menu.show_title()
	var initial_title: Dictionary = _receipt()
	_expect(_label_contains("SavedCheckpointLabel", "Entrance"), "fresh Story Title names the saved Entrance checkpoint")
	_expect_unchanged(initial_title, "fresh checkpoint display")
	game.resume_campaign()
	for tick: int in range(12):
		await physics_frame
		await process_frame
		if bool(game.player.get_threat_response_state().motion.grounded):
			break
	game.request_pause()
	await _settle()
	_expect(paused and bool(game.player.get_threat_response_state().motion.grounded) and not game.player.dead, "public Resume and Pause settle actual living Hero on the native floor")
	# TEST ONLY injured resource seed, followed by the public checkpoint barrier.
	game.player.hp = 37.0
	game.player.shells = 0
	_expect(game.active_level.request_checkpoint(CHECKPOINT_ID, "encounter"), "actual level requests comparison-checkpoint through the public Shell consumer")
	await _settle()
	var protected_checkpoint: Dictionary = game.attempts.state().story.checkpoint
	_expect(protected_checkpoint.level.progress.checkpoint_id == CHECKPOINT_ID and protected_checkpoint.player.resources.hp == 37.0 and protected_checkpoint.player.resources.shells == 0, "durable whole checkpoint has actual ID, nested HP37 and empty ammo")
	_expect(not protected_checkpoint.player.has("hp"), "actual Player wire uses resources.hp, never an obsolete top-level HP stub")
	game.menu.show_title()
	var title_before: Dictionary = _receipt()
	_expect(_label_contains("SavedCheckpointLabel", CHECKPOINT_ID), "Title SavedCheckpointLabel names the actual saved checkpoint ID")
	_expect_unchanged(title_before, "saved checkpoint Title")
	game.menu.show_journey()
	game.menu.select_level("A1-L1")
	var journey_before: Dictionary = _receipt()
	_expect(_label_contains("LevelCardBody", CHECKPOINT_ID), "Journey current LevelCardBody names the actual saved checkpoint ID")
	_expect(_journey_totals_match_registry(), "Journey totals derive from the actual test registry's main and optional entries")
	_check_story_traveller()
	_expect_unchanged(journey_before, "saved checkpoint Journey")
	_expect(game.active_level.request_completion("comparison-cleared"), "public completion makes the actual current level Replay selector accessible")
	await _settle()
	_expect(game.attempts.state().completed_main == ["A1-L1"] and game.attempts.active_kind() == "story" and game.attempts.state().side_attempt == null, "completion is a story prefix, with no invented replay attempt")
	game.menu.show_replay_setup("A1-L1")
	_expect(game.menu.page_name() == "replay" and paused, "actual Replay chooser opens for the publicly completed fixture and stays paused")
	_compare_selection("JacketSelector", "CLOTH-J2", 90.0, 37.0, 0.0, "HP37 smaller max")
	# Reset only the chooser through its actual public Button callback. The actual
	# Player remains starter throughout; P2 alone then raises prospective maxHP.
	_use_story_preset()
	_compare_selection("PantsSelector", "CLOTH-P2", 110.0, 37.0, 0.0, "HP37 larger max")
	# A completed level cannot request another checkpoint. Record the genuine
	# changed TEST HP through public Pause; the protected earlier Retry stays37.
	game.player.hp = 95.0
	game.player.shells = 0
	game.request_pause()
	await _settle()
	_expect(game.attempts.story_snapshot().player.resources.hp == 95.0 and game.attempts.story_snapshot().player.resources.shells == 0, "public Pause stores the completed actual story's nested HP95 with empty ammo")
	_expect(FocusExact.stringify(game.attempts.state().story.checkpoint) == FocusExact.stringify(protected_checkpoint), "HP95 live save preserves the earlier whole protected HP37 Retry checkpoint")
	game.menu.show_replay_setup("A1-L1")
	_compare_selection("JacketSelector", "CLOTH-J2", 90.0, 90.0, 5.0, "HP95 smaller max")
	_expect(_events.is_empty(), "display/selector callbacks publish no input, aim or executed world actions")
	await _dispose_shell()
	_finish()

func _compare_selection(selector_name: String, id: String, expected_max: float, retained: float, discarded: float, note: String) -> void:
	var before: Dictionary = _receipt()
	var selector: OptionButton = game.menu.find_child(selector_name, true, false) as OptionButton
	_expect(is_instance_valid(selector), note + " uses the actual named OptionButton")
	if not is_instance_valid(selector):
		return
	var selected_index: int = -1
	for index: int in range(selector.item_count):
		if selector.get_item_metadata(index) == id:
			selected_index = index
			break
	_expect(selected_index >= 0, note + " selects existing canonical " + id)
	if selected_index < 0:
		return
	selector.select(selected_index)
	selector.item_selected.emit(selected_index)
	var toggle: Button = game.menu.find_child("ComparisonToggle", true, false) as Button
	_expect(is_instance_valid(toggle) and toggle.toggle_mode, note + " uses the actual comparison toggle")
	if is_instance_valid(toggle):
		toggle.set_pressed_no_signal(true)
		toggle.toggled.emit(true)
	var label: Label = game.menu.find_child("EquipmentComparison", true, false) as Label
	_expect(is_instance_valid(label) and label.visible, note + " exposes actual equipment comparison text")
	var selected := ReplayEquipment.new()
	_expect(selected.restore(game.menu.replay_loadout()) and ("%.0f" % float(selected.resolved_stats().max_health)) == ("%.0f" % expected_max), note + " prospectively resolves canonical displayed max HP (P2's multiplication is a derived float)")
	_expect(is_instance_valid(label) and label.text.contains("Max HP: 100 → %.0f\n" % expected_max), note + " displays the canonical 100-to-selected max HP comparison")
	var expected_line: String = "Swap rule comparison: %.1f HP retained, %.1f discarded" % [retained, discarded] + COMPARISON_SUFFIX
	var actual_line: String = "<missing>" if not is_instance_valid(label) else label.text.get_slice("\n", label.text.get_slice_count("\n") - 1)
	_expect(actual_line == expected_line, note + " exact nested-resource comparison line; actual=" + actual_line)
	_expect_unchanged(before, note)

func _use_story_preset() -> void:
	var before: Dictionary = _receipt()
	var button: Button = game.menu.find_child("UseStoryButton", true, false) as Button
	_expect(is_instance_valid(button), "actual Use Story Equipment Button exists")
	if is_instance_valid(button):
		button.pressed.emit()
	_expect(game.menu.replay_loadout() == ReplayEquipment.STARTER, "actual chooser preset resets prospective J2 before the independent P2 comparison")
	_expect_unchanged(before, "actual Use Story Equipment preset")

func _label_contains(node_name: String, value: String) -> bool:
	var label: Label = game.menu.find_child(node_name, true, false) as Label
	return is_instance_valid(label) and label.text.contains(value)

func _journey_totals_match_registry() -> bool:
	var main_count: int = 0
	var optional_count: int = 0
	for info: Dictionary in raw.levels:
		main_count += 1 if info.kind == "main" else 0
		optional_count += 1 if info.kind == "optional" else 0
	var expected: String = "0 / %d main  ·  0 / %d optional" % [main_count, optional_count]
	for node: Node in game.menu.find_children("*", "Label", true, false):
		if (node as Label).text == expected:
			return true
	return false

func _check_story_traveller() -> void:
	var marker: TextureRect = game.menu.find_child("StoryTraveller", true, false) as TextureRect
	_expect(is_instance_valid(marker) and marker.visible and marker.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and marker.texture != null, "Journey exposes the nearest-filtered nonempty actual StoryTraveller")
	if not is_instance_valid(marker) or marker.texture == null:
		return
	var expected: Texture2D = ReplayArt.preview_texture(ReplayArt.presentation_for_act(1), game.attempts.story_snapshot().equipment_ids)
	_expect(expected != null, "protected story gear produces a genuine shared preview texture")
	if expected == null:
		return
	var actual_image: Image = marker.texture.get_image()
	var expected_image: Image = expected.get_image()
	_expect(actual_image != null and expected_image != null and actual_image.get_size() == Vector2i(48, 64) and actual_image.get_size() == expected_image.get_size() and actual_image.get_format() == expected_image.get_format() and actual_image.get_data() == expected_image.get_data(), "actual Journey marker matches the shared Act1 preview pixels and protected story gear")

func _receipt() -> Dictionary:
	var store := FocusStore.new(_isolated_root + "campaign.json")
	var disk: Dictionary = store.read_payload()
	var receipt: Dictionary = {
		"story": FocusExact.stringify(game.attempts.story_snapshot()),
		"model": FocusExact.stringify(game.attempts.state()),
		"live": FocusExact.stringify(game.capture_campaign_snapshot()),
		"player": FocusExact.stringify(game.player.snapshot_state()),
		"gear": FocusExact.stringify(game.player.equipment.snapshot()),
		"input": FocusExact.stringify(_encode_observation(game.get_input_observation_state())),
		"actions": FocusExact.stringify(_encode_observation(game.player.get_world_action_records())),
		"disk_payload": FocusExact.stringify(disk), "disk_files": _disk_files(),
		"player_id": str(game.player.get_instance_id()), "level_id": str(game.active_level.get_instance_id()),
		"events": _events.duplicate(), "paused": paused,
	}
	for key: String in ["story", "model", "live", "player", "gear", "input", "actions", "disk_payload"]:
		_expect(not String(receipt[key]).is_empty(), "nonempty exact " + key + " receipt prevents vacuous comparison")
	_expect(not disk.is_empty() and store.last_error.is_empty() and not receipt.disk_files.is_empty(), "real format-2 SaveStore and original file-byte receipts are available: " + store.last_error)
	return receipt

func _expect_unchanged(before: Dictionary, note: String) -> void:
	var after: Dictionary = _receipt()
	for key: String in before:
		_expect(before[key] == after[key], note + " preserves actual " + key)
	_expect(paused and game.attempts.active_kind() == "story" and game.attempts.state().side_attempt == null, note + " retains paused story without replay activation")
	_expect(game.player.equipment.snapshot() == ReplayEquipment.STARTER, note + " never equips the real Player or applies swap resources")

func _encode_observation(value: Variant) -> Variant:
	# The actual public observations contain only bounded dictionaries/arrays and
	# native Vec2/Vec3; encode those vectors, without coercing keys or safe integers.
	if value is Vector2:
		return [value.x, value.y]
	if value is Vector3:
		return [value.x, value.y, value.z]
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value:
			_expect(typeof(key) == TYPE_STRING, "actual public observation key is a String")
			result[key] = _encode_observation(value[key])
		return result
	if value is Array:
		var result: Array = []
		for child: Variant in value:
			result.append(_encode_observation(child))
		return result
	return value

func _disk_files() -> Dictionary:
	var result: Dictionary = {}
	var directory := DirAccess.open(_isolated_root)
	if directory == null:
		return result
	for name: String in directory.get_files():
		result[name] = FileAccess.get_file_as_bytes(_isolated_root + name).hex_encode()
	return result

func _input_seen(_record: Dictionary) -> void:
	_events.append("input")
func _anchor_seen(_anchor: Vector2) -> void:
	_events.append("aim")
func _world_action_seen(_record: Dictionary) -> void:
	_events.append("world_action")

func _new_shell() -> CinderCampaignShell:
	var result: CinderCampaignShell = Shell.new()
	result.configure_runtime(raw, _isolated_root + "campaign.json", _isolated_root + "settings.json", _isolated_root + "preferences.json")
	root.add_child(result)
	return result

func _dispose_shell() -> void:
	paused = true
	if is_instance_valid(game):
		if is_instance_valid(game.fx):
			game.fx.clear_lab()
		await create_timer(0.1, true).timeout
		game.free()
		game = null
		await _settle()
	_cleanup()

func _cleanup() -> void:
	var directory := DirAccess.open(_isolated_root)
	if directory != null:
		for name: String in directory.get_files():
			DirAccess.remove_absolute(ProjectSettings.globalize_path(_isolated_root + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_isolated_root))

func _finish() -> void:
	if is_instance_valid(_watchdog):
		_watchdog.stop()
		_watchdog.free()
	paused = false
	_cleanup()
	print("Replay comparison smoke: %d checks, %d failures (TEST ONLY actual Shell callbacks; no GUI hit-test or full route)" % [checks, failures])
	quit(1 if failures else 0)

func _watchdog_expired() -> void:
	push_error("Replay comparison watchdog: 60 wall seconds; suspended scene retained, no completion claim")
	quit(1)
