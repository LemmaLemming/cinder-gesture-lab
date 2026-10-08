class_name CinderCampaignMenu
extends CanvasLayer
## Presentation only. The shell owns paused barriers, gesture clearing, saves,
## scene transitions and runtime settings. No control calls combat or unpauses.

signal begin_story_requested
signal continue_story_requested
signal optional_requested(level_id: String)
signal replay_requested(level_id: String, loadout: Dictionary)
signal restart_replay_requested(level_id: String, loadout: Dictionary)
signal resume_requested
signal retry_requested
signal leave_side_requested
signal journey_requested
signal settings_changed_request(changes: Dictionary)
signal difficulty_preference_requested(profile_id: String)
signal retry_failed_operation_requested

const Equipment = preload("res://scripts/equipment.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const PlayerArt = preload("res://scripts/pixel_sprite.gd")
const REPLAY_SLOTS: Array[String] = ["weapon", "jacket", "pants", "shoes"]
const DIFFICULTY_IDS: Array[String] = ["assisted", "standard", "challenge"]
const ACT_NAMES: Array[String] = ["The Moon", "The Invasion", "Tormance"]
const ACT_COLOURS: Array[Color] = [Color("b9c8d4"), Color("dba08c"), Color("cbc194")]
const ACT_BACKGROUNDS: Array[Color] = [Color("1d2631"), Color("311e25"), Color("262138")]
const INK: Color = Color("edf0e7")
const MUTED: Color = Color("adb4bd")
const ACT_HEIGHT: float = 1080.0
const ROW_HEIGHT: float = 192.0
const NODE_SIZE: Vector2 = Vector2(132, 76)

class RouteCanvas extends Control:
	var segments: Array[PackedVector2Array] = []
	var region_colours: Array[Color] = []
	func _draw() -> void:
		for act: int in range(region_colours.size()):
			draw_rect(Rect2(0, act * ACT_HEIGHT, size.x, ACT_HEIGHT - 8.0), region_colours[act])
		for segment: PackedVector2Array in segments:
			draw_line(segment[0], segment[1], Color("77818b"), 3.0, false)

var _registry: CinderCampaignRegistry
var _attempts: CinderCampaignAttempts
var _settings: CinderGameSettings
var _equipment := Equipment.new()
var _overlay: ColorRect
var _heading: Label
var _back: Button
var _status: Label
var _host: VBoxContainer
var _page: String = ""
var _return_page: String = "title"
var _selected_id: String = ""
var _journey_scroll: ScrollContainer
var _route_canvas: RouteCanvas
var _node_buttons: Dictionary = {}
var _story_marker: Label
var _card_title: Label
var _card_body: Label
var _card_action: Button
var _journey_offset: int = 0
var _replay_id: String = ""
var _replay_gear: Dictionary = {}
var _restarting_replay: bool = false
var _selectors: Dictionary = {}
var _comparison: Label
var _item_description: Label
var _replay_action: Button
var _quality: OptionButton
var _fps: OptionButton
var _motion: CheckBox
var _audio_sliders: Dictionary = {}
var _audio_labels: Dictionary = {}
var _audio_dragging: Dictionary = {}
var _syncing_settings: bool = false
var _difficulty_id: String = "standard"
var _difficulty_select: OptionButton
var _portrait: TextureRect

func _ready() -> void:
	_ensure_ui()
	if _page.is_empty():
		show_title()

func configure(registry: CinderCampaignRegistry, attempts: CinderCampaignAttempts, settings: CinderGameSettings) -> void:
	_registry = registry
	_attempts = attempts
	_settings = settings
	if not _page.is_empty():
		refresh()

func is_open() -> bool:
	return visible

func page_name() -> String:
	return _page

func hide_menu() -> void:
	visible = false

func show_error(message: String) -> void:
	_ensure_ui()
	_status.text = message
	_status.modulate = Color("ffc09a")

func show_commit_error(message: String) -> void:
	show_error(message)
	_button(_host, "Retry Pending Save / Transition", "RetryPendingOperationButton").pressed.connect(func() -> void: retry_failed_operation_requested.emit())

func show_notice(message: String) -> void:
	_ensure_ui()
	_status.text = message
	_status.modulate = Color.WHITE

func show_title() -> void:
	_open_page("title", "CINDER", false)
	var box: VBoxContainer = _scroll_box()
	_label(box, "CINDER", 56).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(box, "A journey across three strange worlds", 23).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_presentation_note(box, _story_id() if not _story_id().is_empty() else "A1-L1")
	var state: Dictionary = _state()
	var story: String = _story_id()
	if story.is_empty():
		var begin: Button = _button(box, "Begin Story", "BeginStoryButton")
		begin.disabled = not _playable("A1-L1")
		begin.pressed.connect(func() -> void: begin_story_requested.emit())
		if begin.disabled:
			_label(box, "The opening level is awaiting integration.", 19, MUTED)
	elif state.get("completed_main", []).size() < 15 or String(state.get("story", {}).get("snapshot", {}).get("level", {}).get("progress", {}).get("contact_exit_id", "")).is_empty():
		var continue_button: Button = _button(box, "Continue Story · " + story, "ContinueStoryButton")
		continue_button.disabled = not _playable(story)
		continue_button.pressed.connect(func() -> void: continue_story_requested.emit())
		_label(box, "Resume your preserved story equipment and checkpoint.", 19, MUTED)
	else:
		_label(box, "The main journey is complete. Visit cleared levels or optional paths.", 21)
	if state.get("side_attempt") != null:
		var side: Dictionary = state["side_attempt"]
		_button(box, "Resume %s · %s" % [String(side["kind"]).capitalize(), side["level_id"]], "ResumeSideButton").pressed.connect(func() -> void: resume_requested.emit())
	_button(box, "Journey", "JourneyButton").pressed.connect(_open_journey)
	_button(box, "Settings & Credits", "SettingsButton").pressed.connect(show_settings)

func show_journey() -> void:
	_open_page("journey", "Journey", true)
	var state: Dictionary = _state()
	_label(_host, "%d / 15 main  ·  %d / 9 optional" % [state.get("completed_main", []).size(), state.get("completed_optional", []).size()], 20)
	var shortcuts := HBoxContainer.new()
	_host.add_child(shortcuts)
	for act: int in range(3):
		var shortcut: Button = _button(shortcuts, "Act %d" % (act + 1), "Act%dShortcut" % (act + 1))
		shortcut.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shortcut.pressed.connect(func() -> void: _journey_scroll.scroll_vertical = int(act * ACT_HEIGHT))
	var current: Button = _button(shortcuts, "Story", "CurrentStoryShortcut")
	current.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current.disabled = _story_id().is_empty()
	current.pressed.connect(func() -> void:
		if _node_buttons.has(_story_id()):
			_journey_scroll.ensure_control_visible(_node_buttons[_story_id()]))
	_journey_scroll = _scroll(_host, "JourneyScroll")
	_route_canvas = RouteCanvas.new()
	_route_canvas.name = "JourneyPath"
	_route_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_route_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_route_canvas.custom_minimum_size = Vector2(0, ACT_HEIGHT * 3.0)
	_route_canvas.region_colours = ACT_BACKGROUNDS.duplicate()
	_journey_scroll.add_child(_route_canvas)
	_node_buttons.clear()
	for act: int in range(3):
		var title: Label = _label(_route_canvas, "ACT %d · %s" % [act + 1, ACT_NAMES[act]], 24, ACT_COLOURS[act])
		title.position = Vector2(16, act * ACT_HEIGHT + 20)
		title.size = Vector2(264, 64)
		title.name = "Act%dTitle" % (act + 1)
	if _registry != null:
		for id: String in _registry.ids():
			var node: Button = _button(_route_canvas, "", "Node_" + id.replace("-", "_"))
			node.add_theme_font_size_override("font_size", 16)
			node.custom_minimum_size = NODE_SIZE
			node.size = NODE_SIZE
			node.set_meta("level_id", id)
			node.set_meta("parent_level_id", _registry.entry(id).get("parent_level_id"))
			node.pressed.connect(func() -> void: select_level(id))
			_node_buttons[id] = node
	# Configure the one-line marker before entering the tree; a wrapped label at
	# zero width can retain a tall shaped paragraph through the first portrait.
	_story_marker = Label.new()
	_story_marker.name = "StoryMarker"
	_story_marker.text = "STORY HERE"
	_story_marker.add_theme_font_size_override("font_size", 15)
	_story_marker.add_theme_color_override("font_color", Color("f8d788"))
	_story_marker.autowrap_mode = TextServer.AUTOWRAP_OFF
	_story_marker.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_story_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_marker.size = Vector2(NODE_SIZE.x, 22)
	_route_canvas.add_child(_story_marker)
	_route_canvas.resized.connect(_layout_journey)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("151b25"), Color("738390")))
	_host.add_child(panel)
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 8)
	panel.add_child(card)
	_card_title = _label(card, "", 23)
	_card_title.name = "LevelCardTitle"
	_card_body = _label(card, "", 18, MUTED)
	_card_body.name = "LevelCardBody"
	_card_action = _button(card, "", "LevelCardAction")
	_card_action.pressed.connect(_activate_selected)
	if _selected_id.is_empty() or not _node_buttons.has(_selected_id):
		_selected_id = _story_id() if not _story_id().is_empty() else "A1-L1"
	_layout_journey.call_deferred()
	select_level(_selected_id)
	_restore_journey_scroll.call_deferred()

func select_level(id: String) -> void:
	if _page != "journey" or not _node_buttons.has(id):
		return
	_selected_id = id
	var state: Dictionary = _state()
	for node_id: String in _node_buttons:
		var node: Button = _node_buttons[node_id]
		var status: String = _node_state(node_id)
		var kind: String = "Optional" if _registry.entry(node_id)["kind"] == "optional" else "Main"
		node.text = "%s\n%s\n%s" % [node_id, kind, _state_label(status)]
		node.tooltip_text = "Awaiting integration" if status == "unimplemented" else _state_label(status)
		node.set_meta("campaign_state", status)
		node.add_theme_stylebox_override("normal", _style(ACT_BACKGROUNDS[int(node_id.substr(1, 1)) - 1], Color("f8d788") if node_id == id else Color("738390"), 3 if node_id == id else 2))
	var entry: Dictionary = _registry.entry(id)
	var status: String = _node_state(id)
	_card_action.disabled = true
	if status == "locked":
		var prerequisite: Variant = entry.get("parent_level_id") if entry["kind"] == "optional" else entry.get("previous_main_id")
		_card_title.text = id + " · Locked " + String(entry["kind"]) + " level"
		_card_body.text = "Clear %s to unlock this path." % prerequisite
		_card_action.text = "Locked"
		return
	_card_title.text = id + " · " + String(entry["name"])
	if status == "unimplemented":
		_card_body.text = "Awaiting integration. This scene is not available to play."
		_card_action.text = "Awaiting integration"
	elif id == _story_id() and not state.get("completed_main", []).has(id):
		_card_body.text = "Current story checkpoint. Your story equipment and resources are preserved."
		_card_action.text = "Continue Story"
		_card_action.disabled = false
	elif state.get("completed_main", []).has(id) or state.get("completed_optional", []).has(id):
		_card_body.text = "Completed. Choose equipment for an isolated replay."
		_card_action.text = "Replay · Choose Equipment"
		_card_action.disabled = state.get("side_attempt") != null
	elif entry["kind"] == "optional":
		_card_body.text = "Optional path from %s. It never blocks the main journey." % entry["parent_level_id"]
		_card_action.text = "Play Optional"
		_card_action.disabled = state.get("story") == null or state.get("side_attempt") != null
	elif id == "A1-L1" and state.get("story") == null:
		_card_body.text = "Begin the main journey with starter equipment."
		_card_action.text = "Begin Story"
		_card_action.disabled = false
	else:
		_card_body.text = "Continue the current story and use its exit to reach this level."
		_card_action.text = "Continue Story"
		_card_action.disabled = _story_id().is_empty() or not _playable(_story_id())
	if state.get("side_attempt") != null and id != _story_id():
		_card_body.text += " Finish or leave your active side attempt first."

func show_pause() -> void:
	_open_page("pause", "Paused", true)
	var box: VBoxContainer = _scroll_box()
	_label(box, "All simulation clocks are paused.", 23)
	_button(box, "Resume", "ResumeButton").pressed.connect(func() -> void: resume_requested.emit())
	_button(box, "Retry Checkpoint", "RetryButton").pressed.connect(func() -> void: retry_requested.emit())
	if _state().get("side_attempt") != null:
		_button(box, "Leave Side Attempt · Continue Story", "LeaveSideButton").pressed.connect(func() -> void: leave_side_requested.emit())
		if _state()["side_attempt"]["kind"] == "replay":
			_button(box, "Restart Replay with New Equipment", "RestartReplayButton").pressed.connect(func() -> void: show_replay_setup(_state()["side_attempt"]["level_id"], true))
	_button(box, "Journey", "JourneyButton").pressed.connect(_open_journey)
	_button(box, "Settings & Credits", "SettingsButton").pressed.connect(show_settings)

func show_resume(kind: String = "story") -> void:
	_open_page("resume", "Resume " + kind.capitalize(), false)
	var box: VBoxContainer = _scroll_box()
	_label(box, "Your coherent saved attempt is restored and paused.", 24)
	_label(box, "Press Resume when ready. The menu gesture is consumed before combat.", 20, MUTED)
	_button(box, "Resume", "ResumeButton").pressed.connect(func() -> void: resume_requested.emit())
	_button(box, "Journey", "JourneyButton").pressed.connect(_open_journey)

func show_replay_setup(id: String, restart: bool = false) -> void:
	_replay_id = id
	var state: Dictionary = _state()
	_restarting_replay = restart and state.get("side_attempt") != null and state["side_attempt"]["kind"] == "replay" and state["side_attempt"]["level_id"] == id
	if _registry == null or not _playable(id) or not (state.get("completed_main", []).has(id) or state.get("completed_optional", []).has(id)):
		show_journey()
		show_error("Replay requires a completed, integrated level.")
		return
	_open_page("replay", "Replay · " + id, true)
	_replay_gear = _valid_loadout(state.get("last_replay_equipment", {}))
	if _restarting_replay:
		_replay_gear = _valid_loadout(state["side_attempt"]["snapshot"]["equipment_ids"])
	if _replay_gear.is_empty():
		_replay_gear = _story_gear()
	var box: VBoxContainer = _scroll_box()
	_label(box, "For this replay only. Your story equipment and checkpoint are preserved.", 21)
	_presentation_note(box, id)
	_selectors.clear()
	for slot: String in REPLAY_SLOTS:
		_label(box, slot.capitalize(), 20, MUTED)
		var select: OptionButton = _option(box, slot.capitalize() + "Selector")
		for item: Dictionary in _equipment.available_items(slot):
			if state.get("unlocked_equipment", []).has(item["id"]):
				select.add_item(String(item["name"]))
				var index: int = select.item_count - 1
				select.set_item_metadata(index, item["id"])
				if item["id"] == _replay_gear.get(slot):
					select.select(index)
		select.item_selected.connect(func(index: int) -> void: _choose_item(slot, String(select.get_item_metadata(index))))
		_selectors[slot] = select
	var presets := VBoxContainer.new()
	box.add_child(presets)
	_button(presets, "Use Story Equipment", "UseStoryButton").pressed.connect(func() -> void: _set_replay_gear(_story_gear()))
	_button(presets, "Starter", "StarterButton").pressed.connect(func() -> void: _set_replay_gear(Equipment.STARTER))
	_item_description = _label(box, "", 19, MUTED)
	_item_description.name = "ItemDescription"
	var expand: Button = _button(box, "Show Equipment Comparison", "ComparisonToggle")
	expand.toggle_mode = true
	_comparison = _label(box, "", 18)
	_comparison.name = "EquipmentComparison"
	_comparison.visible = false
	expand.toggled.connect(func(value: bool) -> void:
		_comparison.visible = value
		expand.text = "Hide Equipment Comparison" if value else "Show Equipment Comparison")
	_replay_action = _button(box, "Restart Replay" if _restarting_replay else "Start Replay", "StartReplayButton")
	_replay_action.pressed.connect(func() -> void:
		if not _valid_loadout(_replay_gear).is_empty() and _playable(_replay_id):
			if _restarting_replay and _can_restart_replay():
				restart_replay_requested.emit(_replay_id, _replay_gear.duplicate(true))
			elif _state().get("side_attempt") == null:
				replay_requested.emit(_replay_id, _replay_gear.duplicate(true)))
	_refresh_comparison("weapon")

func replay_loadout() -> Dictionary:
	return _replay_gear.duplicate(true)

func _can_restart_replay() -> bool:
	var side: Variant = _state().get("side_attempt")
	return side is Dictionary and side["kind"] == "replay" and side["level_id"] == _replay_id

func show_settings() -> void:
	if _page != "settings":
		_return_page = _page if not _page.is_empty() else "title"
	_open_page("settings", "Settings & Credits", true)
	var box: VBoxContainer = _scroll_box()
	_label(box, "Quality changes optional decoration. Warnings, safe landings and action feedback remain visible.", 21)
	_label(box, "Cosmetic Quality", 20, MUTED)
	_quality = _option(box, "QualitySelector")
	for id: String in CinderGameSettings.QUALITY_IDS:
		_quality.add_item(id)
		_quality.set_item_metadata(_quality.item_count - 1, id)
	_label(box, "Frame Rate", 20, MUTED)
	_fps = _option(box, "FPSSelector")
	for fps: int in [30, 60]:
		_fps.add_item("%d FPS" % fps)
		_fps.set_item_metadata(_fps.item_count - 1, fps)
	_audio_sliders.clear()
	_audio_labels.clear()
	_audio_dragging.clear()
	for channel: String in CinderGameSettings.AUDIO_CHANNELS:
		var caption: Label = _label(box, channel.capitalize(), 20, MUTED)
		var slider := HSlider.new()
		slider.name = channel.capitalize() + "Volume"
		slider.custom_minimum_size = Vector2(44, 48)
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.mouse_filter = Control.MOUSE_FILTER_STOP
		box.add_child(slider)
		_audio_sliders[channel] = slider
		_audio_labels[channel] = caption
		_audio_dragging[channel] = false
		slider.drag_started.connect(func() -> void: _audio_dragging[channel] = true)
		slider.drag_ended.connect(func(changed: bool) -> void:
			_audio_dragging[channel] = false
			if changed and not _syncing_settings:
				settings_changed_request.emit({"audio": {channel: slider.value}}))
		slider.value_changed.connect(func(value: float) -> void:
			caption.text = "%s · %d%%" % [channel.capitalize(), roundi(value * 100.0)]
			if not _syncing_settings and not _audio_dragging[channel]:
				settings_changed_request.emit({"audio": {channel: value}}))
	_motion = CheckBox.new()
	_motion.name = "ReducedMotionToggle"
	_motion.text = "Reduced Motion"
	_motion.custom_minimum_size = Vector2(44, 52)
	_motion.add_theme_font_size_override("font_size", 22)
	_motion.mouse_filter = Control.MOUSE_FILTER_STOP
	box.add_child(_motion)
	_label(box, "Reduces camera shake and decorative motion. Input and encounter timings stay the same.", 18, MUTED)
	_label(box, "Difficulty Preference", 20, MUTED)
	_difficulty_select = _option(box, "DifficultySelector")
	var difficulty := Difficulty.new()
	for id: String in DIFFICULTY_IDS:
		_difficulty_select.add_item(String(difficulty.profile(id).get("name", id.capitalize())))
		_difficulty_select.set_item_metadata(_difficulty_select.item_count - 1, id)
	_label(box, "Provisional tuning. The shell applies this preference at the next fresh encounter boundary.", 18, MUTED)
	_sync_settings_controls()
	_quality.item_selected.connect(func(index: int) -> void: settings_changed_request.emit({"quality": _quality.get_item_metadata(index)}))
	_fps.item_selected.connect(func(index: int) -> void: settings_changed_request.emit({"target_fps": _fps.get_item_metadata(index)}))
	_motion.toggled.connect(func(value: bool) -> void: settings_changed_request.emit({"reduced_motion": value}))
	_difficulty_select.item_selected.connect(func(index: int) -> void: difficulty_preference_requested.emit(String(_difficulty_select.get_item_metadata(index))))
	var credits_toggle: Button = _button(box, "Show Credits & Sources", "CreditsToggle")
	credits_toggle.toggle_mode = true
	var credits := VBoxContainer.new()
	credits.name = "CreditsContent"
	credits.visible = false
	credits.add_theme_constant_override("separation", 18)
	box.add_child(credits)
	for credit: Dictionary in CinderGameSettings.credits():
		_label(credits, String(credit["title"]), 22)
		_label(credits, String(credit["credit"]) + "\n" + String(credit["role"]), 18, MUTED)
		if credit.has("source"):
			_label(credits, String(credit["source"]), 16, MUTED)
		for source: String in credit.get("sources", []):
			if source != String(credit.get("source", "")):
				_label(credits, source, 16, MUTED)
	credits_toggle.toggled.connect(func(value: bool) -> void: credits.visible = value)

func acknowledge_settings(success: bool, message: String = "") -> void:
	if _page == "settings":
		_sync_settings_controls()
	if success:
		_status.text = "Settings saved." if message.is_empty() else message
		_status.modulate = INK
	else:
		show_error("Settings were not saved. " + message)

func set_difficulty_preference(profile_id: String) -> void:
	if not DIFFICULTY_IDS.has(profile_id):
		return
	_difficulty_id = profile_id
	if _page == "settings" and is_instance_valid(_difficulty_select):
		_difficulty_select.select(DIFFICULTY_IDS.find(profile_id))

func refresh() -> void:
	match _page:
		"title": show_title()
		"journey": show_journey()
		"replay": show_replay_setup(_replay_id)
		"settings": _sync_settings_controls()
		"pause": show_pause()

func _ensure_ui() -> void:
	if _overlay != null:
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	_overlay = ColorRect.new()
	_overlay.name = "CampaignOverlay"
	_overlay.color = Color("0c1019")
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.mouse_force_pass_scroll_events = false
	_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.gui_input.connect(func(_event: InputEvent) -> void: _overlay.accept_event())
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.mouse_force_pass_scroll_events = false
	_overlay.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	_back = _button(header, "‹", "BackButton")
	_back.custom_minimum_size.x = 52
	_back.pressed.connect(_go_back)
	_heading = _label(header, "", 28)
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status = _label(layout, "", 18)
	_status.name = "MenuStatus"
	_host = VBoxContainer.new()
	_host.add_theme_constant_override("separation", 12)
	_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_host)

func _open_page(page: String, title: String, back: bool) -> void:
	_ensure_ui()
	if _page == "journey" and is_instance_valid(_journey_scroll):
		_journey_offset = _journey_scroll.scroll_vertical
	for child: Node in _host.get_children():
		_host.remove_child(child)
		child.queue_free()
	_page = page
	visible = true
	_heading.text = title
	_back.visible = back
	_status.text = ""
	_status.modulate = INK

func _go_back() -> void:
	match _page:
		"settings":
			if _return_page == "pause": show_pause()
			elif _return_page == "journey": show_journey()
			elif _return_page == "replay": show_replay_setup(_replay_id)
			else: show_title()
		"replay": show_journey()
		"pause": resume_requested.emit()
		_: show_title()

func _open_journey() -> void:
	show_journey()
	journey_requested.emit()

func _activate_selected() -> void:
	if _card_action.disabled or not _playable(_selected_id):
		return
	var state: Dictionary = _state()
	if state.get("completed_main", []).has(_selected_id) or state.get("completed_optional", []).has(_selected_id):
		show_replay_setup(_selected_id)
	elif _selected_id == _story_id():
		continue_story_requested.emit()
	elif _registry.entry(_selected_id)["kind"] == "optional":
		optional_requested.emit(_selected_id)
	elif state.get("story") == null:
		begin_story_requested.emit()
	else:
		continue_story_requested.emit()

func _layout_journey() -> void:
	if _page != "journey" or not is_instance_valid(_route_canvas) or _registry == null:
		return
	var width: float = maxf(_journey_scroll.size.x - 16.0, 264.0)
	_route_canvas.size.x = width
	for act: int in range(3):
		(_route_canvas.get_node("Act%dTitle" % (act + 1)) as Label).size.x = width - 32.0
	_route_canvas.segments.clear()
	var route_x: Array[float] = [0.5, 0.28, 0.72, 0.28, 0.5]
	for id: String in _registry.main_route():
		var act: int = int(id.substr(1, 1)) - 1
		var row: int = int(id.substr(4, 1)) - 1
		var node: Button = _node_buttons[id]
		node.position = Vector2(roundf(width * route_x[row] - NODE_SIZE.x / 2.0), act * ACT_HEIGHT + 100.0 + row * ROW_HEIGHT)
	var route: Array[String] = _registry.main_route()
	for index: int in range(1, route.size()):
		var previous: Button = _node_buttons[route[index - 1]]
		var next: Button = _node_buttons[route[index]]
		_route_canvas.segments.append(PackedVector2Array([previous.position + NODE_SIZE / 2.0, next.position + NODE_SIZE / 2.0]))
	for id: String in CinderCampaignRegistry.PARENTS:
		var parent: Button = _node_buttons[CinderCampaignRegistry.PARENTS[id]]
		var node: Button = _node_buttons[id]
		var fraction: float = 0.72 if parent.position.x + NODE_SIZE.x / 2.0 < width * 0.5 else 0.18
		node.position = Vector2(clampf(roundf(width * fraction - NODE_SIZE.x / 2.0), 4.0, width - NODE_SIZE.x - 4.0), parent.position.y + ROW_HEIGHT / 2.0)
		_route_canvas.segments.append(PackedVector2Array([parent.position + NODE_SIZE / 2.0, node.position + NODE_SIZE / 2.0]))
	var story: String = _story_id()
	_story_marker.visible = _node_buttons.has(story)
	if _story_marker.visible:
		_story_marker.size = Vector2(NODE_SIZE.x, 22)
		_story_marker.position = (_node_buttons[story] as Button).position + Vector2(0, -24)
	_route_canvas.queue_redraw()

func _restore_journey_scroll() -> void:
	# ScrollContainer cannot ensure a new child's visibility in its adding frame.
	await get_tree().process_frame
	if _page != "journey" or not is_instance_valid(_journey_scroll):
		return
	_journey_scroll.scroll_vertical = _journey_offset
	if _journey_offset == 0 and _node_buttons.has(_story_id()):
		_journey_scroll.ensure_control_visible(_node_buttons[_story_id()])

func _choose_item(slot: String, id: String) -> void:
	var proposed: Dictionary = _replay_gear.duplicate(true)
	proposed[slot] = id
	if _valid_loadout(proposed).is_empty():
		return
	_replay_gear = proposed
	_refresh_comparison(slot)

func _set_replay_gear(loadout: Dictionary) -> void:
	var valid: Dictionary = _valid_loadout(loadout)
	if valid.is_empty():
		show_error("That equipment is not available for this replay.")
		return
	_replay_gear = valid
	for slot: String in REPLAY_SLOTS:
		var select: OptionButton = _selectors[slot]
		for index: int in range(select.item_count):
			if select.get_item_metadata(index) == valid[slot]:
				select.select(index)
	_refresh_comparison("weapon")

func _refresh_comparison(slot: String) -> void:
	if is_instance_valid(_portrait) and _page == "replay":
		_portrait.texture = PlayerArt.preview_texture(PlayerArt.presentation_for_act(int(_replay_id.substr(1, 1))), _replay_gear)
	var story_gear := Equipment.new()
	story_gear.restore(_story_gear())
	var selected_gear := Equipment.new()
	selected_gear.restore(_replay_gear)
	var before: Dictionary = story_gear.resolved_stats()
	var after: Dictionary = selected_gear.resolved_stats()
	var item: Dictionary = selected_gear.item(String(_replay_gear[slot]))
	_item_description.text = "%s\n%s\nTradeoff: %s" % [item["name"], item["role"], item["tradeoff"]]
	var hp: float = float(_attempts.story_snapshot().get("player", {}).get("hp", before["max_health"]))
	var retained_hp: float = Equipment.health_after_swap(hp, float(after["max_health"]))
	_comparison.text = "Story equipment → Selected replay equipment\n" \
		+ "Slash damage: %.1f → %.1f\nBlast damage: %.1f → %.1f\n" % [before["primary_damage"], after["primary_damage"], before["followup_damage"], after["followup_damage"]] \
		+ "Recovery (s), slash / blast: %.3f / %.3f → %.3f / %.3f\n" % [before["primary_cooldown"], before["followup_cooldown"], after["primary_cooldown"], after["followup_cooldown"]] \
		+ "Reach (units), slash / blast: %.2f / %.2f → %.2f / %.2f\n" % [before["primary_range"], before["followup_range"], after["primary_range"], after["followup_range"]] \
		+ "Dash speed (units/s): %.2f → %.2f\nDash distance (units): %.2f → %.2f\nDash duration (s): %.3f → %.3f\n" % [before["dash_speed"], after["dash_speed"], before["dash_distance"], after["dash_distance"], before["dash_duration"], after["dash_duration"]] \
		+ "Max HP: %.0f → %.0f\nArmour divisor: %.2f → %.2f\nDamage reduction: %.1f%% → %.1f%%\n" % [before["max_health"], after["max_health"], before["armour"], after["armour"], before["damage_reduction"] * 100.0, after["damage_reduction"] * 100.0] \
		+ "Shell capacity: %d → %d\nShell reload (s): %.2f → %.2f\n" % [before["shell_capacity"], after["shell_capacity"], before["shell_reload"], after["shell_reload"]] \
		+ "Perk: None (implemented static equipment)\nCapped bonuses: " + (", ".join(after["capped_stats"]) if not after["capped_stats"].is_empty() else "None") \
		+ "\nSwap rule comparison: %.1f HP retained, %.1f discarded; larger max HP does not heal. Replay starting resources follow the level's fresh-start policy." % [retained_hp, maxf(hp - retained_hp, 0.0)]
	_replay_action.disabled = _valid_loadout(_replay_gear).is_empty() or (_state().get("side_attempt") != null and not (_restarting_replay and _can_restart_replay()))

func _sync_settings_controls() -> void:
	if _page != "settings" or _settings == null:
		return
	_syncing_settings = true
	var data: Dictionary = _settings.snapshot()
	_quality.select(CinderGameSettings.QUALITY_IDS.find(data["quality"]))
	_fps.select(0 if data["target_fps"] == 30 else 1)
	_motion.set_pressed_no_signal(data["reduced_motion"])
	for channel: String in CinderGameSettings.AUDIO_CHANNELS:
		(_audio_sliders[channel] as HSlider).value = data["audio"][channel]
		(_audio_labels[channel] as Label).text = "%s · %d%%" % [channel.capitalize(), roundi(float(data["audio"][channel]) * 100.0)]
	_difficulty_select.select(DIFFICULTY_IDS.find(_difficulty_id))
	_syncing_settings = false

func _valid_loadout(candidate: Variant) -> Dictionary:
	if not candidate is Dictionary or candidate.size() != 4:
		return {}
	var unlocked: Array = _state().get("unlocked_equipment", [])
	for slot: String in REPLAY_SLOTS:
		var id: Variant = candidate.get(slot)
		if not id is String or not unlocked.has(id) or not _equipment.is_implemented(id) or _equipment.item(id).get("slot") != slot:
			return {}
	return candidate.duplicate(true)

func _story_gear() -> Dictionary:
	var valid: Dictionary = _valid_loadout(_attempts.story_snapshot().get("equipment_ids", {}) if _attempts != null else {})
	return Equipment.STARTER.duplicate(true) if valid.is_empty() else valid

func _state() -> Dictionary:
	return _attempts.state() if _attempts != null else {}

func _story_id() -> String:
	var story: Variant = _state().get("story")
	return String(story["level_id"]) if story is Dictionary else ""

func _playable(id: String) -> bool:
	return _registry != null and _registry.is_playable(id)

func _node_state(id: String) -> String:
	var state: Dictionary = _state()
	return _registry.node_state(id, state.get("completed_main", []), state.get("completed_optional", []), _story_id())

func _state_label(value: String) -> String:
	return {"locked": "Locked", "unimplemented": "Pending", "completed": "Cleared", "current": "Current", "available": "Available"}.get(value, value)

func _presentation_note(parent: Node, id: String) -> void:
	var act: int = clampi(int(id.substr(1, 1)) - 1, 0, 2)
	_label(parent, "ACT %d · %s" % [act + 1, ACT_NAMES[act]], 24, ACT_COLOURS[act])
	_portrait = TextureRect.new()
	_portrait.name = "EquipmentPreview"
	_portrait.custom_minimum_size = Vector2(144, 192)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.texture = PlayerArt.preview_texture(PlayerArt.presentation_for_act(act + 1), _replay_gear if _page == "replay" else _story_gear())
	parent.add_child(_portrait)

func _scroll_box() -> VBoxContainer:
	var scroll: ScrollContainer = _scroll(_host, "PageScroll")
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 14)
	scroll.add_child(box)
	return box

func _scroll(parent: Node, node_name: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = node_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.mouse_force_pass_scroll_events = false
	parent.add_child(scroll)
	return scroll

func _label(parent: Node, value: String, font_size: int = 22, colour: Color = INK) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, value: String, node_name: String = "") -> Button:
	var button := Button.new()
	if not node_name.is_empty(): button.name = node_name
	button.text = value
	button.custom_minimum_size = Vector2(44, 52)
	button.add_theme_font_size_override("font_size", 22)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_force_pass_scroll_events = false
	button.add_theme_stylebox_override("normal", _style(Color("222d3a"), Color("738390")))
	button.add_theme_stylebox_override("hover", _style(Color("334150"), INK))
	button.add_theme_stylebox_override("pressed", _style(Color("415265"), Color("f8d788")))
	button.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), Color("f8d788"), 3))
	parent.add_child(button)
	return button

func _option(parent: Node, node_name: String) -> OptionButton:
	var option := OptionButton.new()
	option.name = node_name
	option.custom_minimum_size = Vector2(44, 52)
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.add_theme_font_size_override("font_size", 22)
	option.get_popup().add_theme_constant_override("v_separation", 24)
	option.mouse_filter = Control.MOUSE_FILTER_STOP
	option.mouse_force_pass_scroll_events = false
	option.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), Color("f8d788"), 3))
	parent.add_child(option)
	return option

func _style(fill: Color, border: Color, width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _unhandled_input(_event: InputEvent) -> void:
	if visible:
		get_viewport().set_input_as_handled()
