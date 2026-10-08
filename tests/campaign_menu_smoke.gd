extends SceneTree
## Live portrait GUI over isolated models. Accepted fixtures below are TEST ONLY;
## they prove menu gates, not campaign acceptance or live actor restoration.
const Menu = preload("res://scripts/ui/campaign_menu.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Attempts = preload("res://scripts/campaign/attempts.gd")
const Settings = preload("res://scripts/settings/game_settings.gd")
const Equipment = preload("res://scripts/equipment.gd")
var checks: int = 0
var failures: int = 0
var _menu: CinderCampaignMenu
var _probe: InputProbe
var _continue_count: int = 0
var _optional_ids: Array[String] = []
var _replay_requests: Array[Dictionary] = []
var _settings_requests: Array[Dictionary] = []
var _difficulty_requests: Array[String] = []
var _begin_count: int = 0
var _resume_count: int = 0
var _retry_count: int = 0
var _leave_count: int = 0

class InputProbe extends Node:
	var events: int = 0
	func _unhandled_input(_event: InputEvent) -> void:
		events += 1

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_probe = InputProbe.new()
	_probe.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(_probe)
	var real_registry := Registry.new()
	var real_attempts := Attempts.new(real_registry)
	var settings := Settings.new("user://test-campaign-menu-unused/settings.json")
	_menu = Menu.new()
	_menu.configure(real_registry, real_attempts, settings)
	_menu.continue_story_requested.connect(func() -> void: _continue_count += 1)
	_menu.begin_story_requested.connect(func() -> void: _begin_count += 1)
	_menu.resume_requested.connect(func() -> void: _resume_count += 1)
	_menu.retry_requested.connect(func() -> void: _retry_count += 1)
	_menu.leave_side_requested.connect(func() -> void: _leave_count += 1)
	_menu.optional_requested.connect(func(id: String) -> void: _optional_ids.append(id))
	_menu.replay_requested.connect(func(id: String, gear: Dictionary) -> void: _replay_requests.append({"id": id, "gear": gear}))
	_menu.settings_changed_request.connect(func(changes: Dictionary) -> void: _settings_requests.append(changes.duplicate(true)))
	_menu.difficulty_preference_requested.connect(func(id: String) -> void: _difficulty_requests.append(id))
	root.add_child(_menu)
	paused = true
	await _settle()
	_expect(_menu.is_open() and _menu.page_name() == "title" and _menu.process_mode == Node.PROCESS_MODE_ALWAYS, "title controls remain live while the scene tree is paused")
	var overlay: Control = _find("CampaignOverlay") as Control
	_expect(overlay.size.is_equal_approx(Vector2(540, 1170)) and overlay.mouse_filter == Control.MOUSE_FILTER_STOP and not overlay.mouse_force_pass_scroll_events, "portrait overlay fills the logical viewport and stops GUI scroll propagation")
	_expect(overlay.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "all menu pixels inherit nearest filtering")
	_expect((_find("BeginStoryButton") as Button).disabled and not real_registry.is_playable("A1-L1"), "real unimplemented opening cannot be launched from Title")
	_menu.show_journey()
	await _settle()
	var positions: Dictionary = _node_positions()
	_expect(positions.size() == 24, "Journey shows exactly 15 main and nine optional stable nodes")
	var node_checks: bool = true
	var parents_correct: bool = true
	for id: String in real_registry.ids():
		var node: Button = _node(id)
		node_checks = node_checks and node.size.x >= 44 and node.size.y >= 44 and node.position.x >= 0 and node.position.x + node.size.x <= (_find("JourneyPath") as Control).size.x + 1
		if Registry.PARENTS.has(id):
			parents_correct = parents_correct and node.get_meta("parent_level_id") == Registry.PARENTS[id]
	_expect(node_checks and parents_correct, "node touch targets fit portrait width and optional branches retain canonical parents")
	var nonoverlapping: bool = true
	for id: String in real_registry.ids():
		for other: String in real_registry.ids():
			if id < other:
				nonoverlapping = nonoverlapping and not _node(id).get_rect().grow(4.0).intersects(_node(other).get_rect().grow(4.0))
	_expect(nonoverlapping, "all main and optional touch targets retain at least eight pixels of separation at portrait width")
	_menu.select_level("A3-L5")
	_expect((_find("LevelCardTitle") as Label).text.find("Crystalman") == -1 and (_find("LevelCardBody") as Label).text.contains("A3-L4") and (_find("LevelCardAction") as Button).disabled, "locked inspector reveals its prerequisite without spoiling the unreached level name")
	_menu.select_level("A1-L1")
	_expect((_find("LevelCardAction") as Button).disabled and (_find("LevelCardBody") as Label).text.contains("Awaiting integration"), "Journey cannot launch a pending scene")
	_menu.show_journey()
	await _settle()
	_expect(_node_positions() == positions, "selection and page rebuilding never move authored path coordinates")
	_expect((_find("Act1Title") as Label).text.contains("The Moon") and (_find("Act2Title") as Label).text.contains("The Invasion") and (_find("Act3Title") as Label).text.contains("Tormance"), "three act regions have distinct readable headings")

	# Clone authored metadata into explicit model/GUI fixtures; never mutate the
	# real registry or accept these rooms as playable campaign content.
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Registry.DATA_PATH))
	for entry: Dictionary in raw["levels"]:
		var id: String = entry["id"]
		if ["A1-L1", "A1-L2", "A1-O1"].has(id):
			entry["scene_path"] = "res://tests/fixtures/campaign/" + id.to_lower().replace("-", "_") + ".tscn"
			entry["readiness"] = "accepted"
			entry["accepted_commit"] = "a".repeat(40)
			entry["api_revision"] = Registry.API_REVISION
	var fixture_registry := Registry.new(raw)
	var attempts := Attempts.new(fixture_registry)
	_expect(fixture_registry.last_error.is_empty() and attempts.begin_story(_snapshot(fixture_registry, "A1-L1")) and attempts.complete_active() and attempts.advance_story(_snapshot(fixture_registry, "A1-L2")), "test-only accepted models establish a cleared level and a different current story level")
	_expect(attempts.grant_equipment(["WEAPON-02", "CLOTH-J1"]), "test unlocks a weapon and jacket through the model API")
	var protected: Dictionary = attempts.state()
	_menu.configure(fixture_registry, attempts, settings)
	_menu.show_title()
	await _settle()
	_expect(not (_find("ContinueStoryButton") as Button).disabled, "accepted current story exposes Continue Story")
	await _click(_find("ContinueStoryButton") as Control)
	_expect(_continue_count == 1 and attempts.state() == protected and paused, "actual paused GUI click requests Continue without mutating story or unpausing")
	_menu.show_journey()
	await _settle()
	_menu.select_level("A1-L2")
	_expect((_find("LevelCardAction") as Button).text == "Continue Story" and (_find("StoryMarker") as Label).visible, "current story marker remains separate from node selection")
	_menu.select_level("A1-L1")
	_expect((_find("LevelCardAction") as Button).text == "Replay · Choose Equipment", "completed noncurrent main level offers replay equipment setup")
	await _click(_find("LevelCardAction") as Control)
	_expect(_menu.page_name() == "replay", "completed node opens the real replay chooser")
	var count: int = 0
	var filtered: bool = true
	for slot: String in Menu.REPLAY_SLOTS:
		var selector: OptionButton = _find(slot.capitalize() + "Selector") as OptionButton
		if selector != null:
			count += 1
			for index: int in range(selector.item_count):
				var id: String = String(selector.get_item_metadata(index))
				filtered = filtered and protected["unlocked_equipment"].has(id) and Equipment.new().item(id)["slot"] == slot
	_expect(count == 4 and filtered and _find("HelmetSelector") == null, "chooser has exactly four canonical slots filtered by campaign unlocks")
	_expect(_menu.replay_loadout() == Equipment.STARTER and attempts.state() == protected, "first replay starts from story equipment without editing the protected model")
	var preview: TextureRect = _find("EquipmentPreview") as TextureRect
	_expect(preview != null and preview.texture != null and preview.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and preview.texture.get_image().get_data() == LabSprite.preview_texture("act1_expedition", Equipment.STARTER).get_image().get_data(), "replay preview shows the native selected act and actual four-slot equipment")
	_choose("WeaponSelector", "WEAPON-02")
	_choose("JacketSelector", "CLOTH-J1")
	_expect(preview.texture.get_image().get_data() == LabSprite.preview_texture("act1_expedition", _menu.replay_loadout()).get_image().get_data(), "actual selector changes redraw carried gear through the shared art path")
	await _click(_find("ComparisonToggle") as Control)
	var gear := Equipment.new()
	gear.restore(_menu.replay_loadout())
	var expected: Dictionary = gear.resolved_stats()
	var comparison: Label = _find("EquipmentComparison") as Label
	_expect(comparison.visible and comparison.text.contains("→ %.1f" % expected["primary_damage"]) and comparison.text.contains("Armour divisor") and comparison.text.contains("does not heal") and not comparison.text.contains("DPS"), "expanded comparison comes from the resolver with armour, caps and honest HP rules")
	await _click(_find("UseStoryButton") as Control)
	_expect(_menu.replay_loadout() == Equipment.STARTER, "Use Story Equipment restores all four selectors")
	_choose("WeaponSelector", "WEAPON-02")
	await _click(_find("StarterButton") as Control)
	_expect(_menu.replay_loadout() == Equipment.STARTER, "Starter restores the legal canonical loadout")
	_choose("WeaponSelector", "WEAPON-02")
	await _click(_find("StartReplayButton") as Control)
	_expect(_replay_requests.size() == 1 and _replay_requests[0]["id"] == "A1-L1" and _replay_requests[0]["gear"].size() == 4 and _replay_requests[0]["gear"]["weapon"] == "WEAPON-02" and attempts.state() == protected, "Start Replay emits a legal isolated selection without changing any attempt state")
	_replay_requests[0]["gear"]["weapon"] = "WEAPON-99"
	_expect(_menu.replay_loadout()["weapon"] == "WEAPON-02", "signal recipients cannot mutate the menu's selected equipment")
	_expect(attempts.complete_active(), "test model clears the optional branch parent")
	protected = attempts.state()
	_menu.show_journey()
	await _settle()
	_menu.select_level("A1-L2")
	_expect((_find("LevelCardAction") as Button).text == "Replay · Choose Equipment", "completed current story remains replayable, including the final campaign level")
	await _click(_find("LevelCardAction") as Control)
	_expect(_menu.page_name() == "replay" and _continue_count == 1, "completed current node opens replay while Title retains the saved Continue Story flow")
	_menu.show_journey()
	await _settle()
	_menu.select_level("A1-O1")
	_expect((_find("LevelCardAction") as Button).text == "Play Optional" and not (_find("LevelCardAction") as Button).disabled, "uncompleted optional path uses first-play semantics after its parent clears")
	await _click(_find("LevelCardAction") as Control)
	_expect(_optional_ids == ["A1-O1"] and attempts.state() == protected, "actual optional GUI action signals the shell and preserves the story model")
	var remembered_replay: Dictionary = _snapshot(fixture_registry, "A1-L1")
	remembered_replay["equipment_ids"]["weapon"] = "WEAPON-02"
	_expect(attempts.begin_side("replay", "A1-L1", remembered_replay), "test-only active replay is established")
	var active_before: Dictionary = attempts.state()
	_menu.show_pause()
	await _settle()
	await _click(_find("ResumeButton") as Control)
	await _click(_find("RetryButton") as Control)
	await _click(_find("LeaveSideButton") as Control)
	_expect(_resume_count == 1 and _retry_count == 1 and _leave_count == 1 and attempts.state() == active_before and paused, "pause actions only signal the shell; retry and leaving cannot refresh resources inside the menu")
	_menu.show_journey()
	await _settle()
	_menu.select_level("A1-O1")
	_expect((_find("LevelCardAction") as Button).disabled, "another side level cannot start while a side attempt is active")
	attempts.leave_side()
	_menu.show_replay_setup("A1-L1")
	await _settle()
	_expect(_menu.replay_loadout()["weapon"] == "WEAPON-02" and attempts.story_snapshot()["equipment_ids"]["weapon"] == "WEAPON-01", "later replay defaults to its last separate equipment choice rather than altering story equipment")

	_menu.show_settings()
	await _settle()
	_expect((_find("QualitySelector") as OptionButton).get_item_text(1) == "Standard" and (_find("FPSSelector") as OptionButton).selected == 1, "settings displays stable quality names and initial 60 FPS")
	var quality: OptionButton = _find("QualitySelector") as OptionButton
	quality.select(0)
	quality.item_selected.emit(0)
	_expect(_settings_requests.back() == {"quality": "Low"} and settings.snapshot()["quality"] == "Standard", "UI requests a quality patch without applying or persisting it")
	_menu.acknowledge_settings(false, "Disk unavailable.")
	_expect(quality.selected == 1 and (_find("MenuStatus") as Label).text.contains("not saved") and (_find("MenuStatus") as Label).text.contains("Disk unavailable"), "failed settings acknowledgement is visible and restores the saved selection")
	_expect(settings.update({"quality": "Low", "reduced_motion": true}, false), "test model accepts a validated settings update without disk writes")
	_menu.acknowledge_settings(true)
	_expect(quality.selected == 0 and (_find("ReducedMotionToggle") as CheckBox).button_pressed and (_find("MenuStatus") as Label).text == "Settings saved.", "successful acknowledgement synchronizes controls to committed settings")
	var fps: OptionButton = _find("FPSSelector") as OptionButton
	fps.select(0)
	fps.item_selected.emit(0)
	_expect(_settings_requests.back() == {"target_fps": 30} and settings.snapshot()["target_fps"] == 60, "30 FPS remains a shell persistence request until acknowledged")
	var effects: HSlider = _find("EffectsVolume") as HSlider
	effects.value = 0.42
	var audio_request: Dictionary = _settings_requests.back()
	_expect(audio_request.keys() == ["audio"] and audio_request["audio"].keys() == ["effects"] and is_equal_approx(float(audio_request["audio"]["effects"]), 0.42) and settings.snapshot()["audio"]["effects"] == 1.0, "audio controls emit only their named validated channel for shell persistence")
	var difficulty: OptionButton = _find("DifficultySelector") as OptionButton
	difficulty.select(2)
	difficulty.item_selected.emit(2)
	_expect(_difficulty_requests == ["challenge"] and not settings.snapshot().has("difficulty"), "difficulty is a separate fresh-encounter preference rather than an unsupported settings key")
	_menu.set_difficulty_preference("standard")
	_expect(difficulty.selected == 1, "shell can acknowledge the actual stored difficulty preference")
	await _click(_find("CreditsToggle") as Control)
	var credit_text: String = _labels_text(_find("CreditsContent"))
	_expect((_find("CreditsContent") as Control).visible and credit_text.contains("Godot Engine contributors") and credit_text.contains("no music track currently bundled") and credit_text.contains("not a runtime sprite sheet"), "expanded credits disclose actual runtime sources and historical reference limits")
	var small_targets: Array[String] = []
	_collect_small_targets(_menu, small_targets)
	_expect(small_targets.is_empty(), "interactive settings controls meet the 44 logical pixel minimum: " + ", ".join(small_targets))

	# This proves the GUI/unhandled boundary, not the shell's earlier _input
	# combat guard. The shell must clear gestures at its paused transition barrier.
	_probe.events = 0
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	wheel.position = Vector2(300, 500)
	root.push_input(wheel, true)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = Vector2(16, 500)
	root.push_input(touch, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(16, 540)
	drag.relative = Vector2(0, 40)
	root.push_input(drag, true)
	touch.pressed = false
	touch.position = drag.position
	root.push_input(touch, true)
	await _settle()
	_expect(_probe.events == 0, "visible overlay consumes wheel, touch and drag before another node's unhandled input")
	_menu.hide_menu()
	root.push_input(drag, true)
	await _settle()
	_expect(_probe.events > 0, "input probe is live and receives events after the menu hides")
	var fresh_attempts := Attempts.new(fixture_registry)
	_menu.configure(fixture_registry, fresh_attempts, settings)
	_menu.show_title()
	await _settle()
	await _click(_find("BeginStoryButton") as Control)
	_expect(_begin_count == 1 and fresh_attempts.state()["story"] == null and paused, "accepted opening requests Begin Story without inventing a fresh actor snapshot")
	_menu.show_resume("replay")
	await _settle()
	await _click(_find("ResumeButton") as Control)
	_expect(_resume_count == 2 and _menu.page_name() == "resume" and paused, "interrupted resume waits paused for the shell to consume the menu gesture")
	_expect(not real_registry.is_playable("A1-L1") and real_attempts.state()["story"] == null, "isolated GUI fixtures never alter authored scene acceptance or real campaign state")
	_menu.queue_free()
	_probe.queue_free()
	await process_frame
	paused = false
	print("Campaign menu smoke: %d checks, %d failures (portrait GUI/model fixtures only)" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _snapshot(registry: CinderCampaignRegistry, id: String) -> Dictionary:
	var scene: Variant = registry.entry(id)["scene_path"]
	return {"schema_version": 1, "level_id": id, "scene_path": scene, "paused": true,
		"equipment_ids": Equipment.STARTER.duplicate(true), "player": {"hp": 37.0, "shells": 0},
		"level": {"level_id": id, "scene_path": scene, "local": {}}, "shell": {}}

func _find(node_name: String) -> Node:
	return _menu.find_child(node_name, true, false)

func _node(id: String) -> Button:
	return _find("Node_" + id.replace("-", "_")) as Button

func _node_positions() -> Dictionary:
	var positions: Dictionary = {}
	for act: int in range(1, 4):
		for number: int in range(1, 6):
			var id: String = "A%d-L%d" % [act, number]
			positions[id] = _node(id).position
		for number: int in range(1, 4):
			var id: String = "A%d-O%d" % [act, number]
			positions[id] = _node(id).position
	return positions

func _choose(selector_name: String, id: String) -> void:
	var selector: OptionButton = _find(selector_name) as OptionButton
	for index: int in range(selector.item_count):
		if selector.get_item_metadata(index) == id:
			selector.select(index)
			selector.item_selected.emit(index)
			return
	_expect(false, "requested test equipment must exist in the filtered selector: " + id)

func _click(control: Control) -> void:
	if control == null:
		_expect(false, "GUI click target must exist")
		return
	var ancestor: Node = control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			(ancestor as ScrollContainer).ensure_control_visible(control)
			break
		ancestor = ancestor.get_parent()
	await _settle()
	var position: Vector2 = control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	root.push_input(motion, true)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = position
	click.global_position = position
	click.pressed = true
	root.push_input(click, true)
	click = click.duplicate() as InputEventMouseButton
	click.pressed = false
	root.push_input(click, true)
	await _settle()

func _settle() -> void:
	await process_frame
	await process_frame

func _labels_text(node: Node) -> String:
	var result: String = node.text + "\n" if node is Label else ""
	for child: Node in node.get_children():
		result += _labels_text(child)
	return result

func _collect_small_targets(node: Node, names: Array[String]) -> void:
	if node is BaseButton or node is Slider:
		var control: Control = node as Control
		if control.is_visible_in_tree() and (control.size.x < 44 or control.size.y < 44):
			names.append(String(node.name))
	for child: Node in node.get_children():
		_collect_small_targets(child, names)

func _expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)
