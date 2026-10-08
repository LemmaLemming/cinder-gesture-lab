class_name GameHUD
extends CanvasLayer

signal start_requested
signal restart_requested
signal bench_requested

const MODE_PLAY: int = 0
const MODE_TITLE: int = 1
const MODE_END: int = 2
const INK: Color = Color(0.035, 0.035, 0.045, 0.95)
const RED: Color = Color(0.70, 0.75, 0.77)
const RED_DARK: Color = Color(0.32, 0.36, 0.39)
const PALE: Color = Color(0.92, 0.90, 0.85)
const MUTED: Color = Color(0.61, 0.59, 0.59)
const GESTURE_HINT: String = "SWIPE  ·  DASH     TAP  ·  SLASH\nDOUBLE TAP  ·  BLAST"

var _built: bool = false
var _mode: int = MODE_PLAY
var _hp_fraction: float = 1.0
var _objective_text: String = "TRY MOVEMENT AND COMBAT"
var _flash_token: int = 0
var _level_preview: bool = false

var _root: Control
var _status_panel: Panel
var _name_label: Label
var _hp_label: Label
var _shell_label: Label
var _hp_track: ColorRect
var _hp_fill: ColorRect
var _objective_label: Label
var _reset_button: Button
var _bench_button: Button
var _telemetry_label: Label
var _anchor_label: Label
var _anchor_caption: Label
var _hint_panel: Panel
var _hint_label: Label
var _mouse_hint_label: Label

var _shade: ColorRect
var _card: Panel
var _card_rail: ColorRect
var _card_kicker: Label
var _card_title: Label
var _card_body: Label
var _card_button: Button


func _ready() -> void:
	setup()


func setup() -> void:
	if _built:
		return
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.name = "HUDRoot"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_status()
	_build_overlay()
	_root.resized.connect(_layout)
	_built = true
	_layout()
	show_title()


func update_status(hp: float, max_hp: float, shells: int, max_shells: int, cores: int, objective: String) -> void:
	setup()
	var safe_max: float = maxf(max_hp, 1.0)
	_hp_fraction = clampf(hp / safe_max, 0.0, 1.0)
	_hp_label.text = "HP  %d / %d" % [int(ceil(maxf(hp, 0.0))), int(ceil(maxf(max_hp, 0.0)))]
	_shell_label.text = "SHELLS  %d / %d" % [maxi(shells, 0), maxi(max_shells, 0)]
	_objective_text = objective.to_upper()
	if cores > 0:
		_objective_text += "   //   CORES %d" % cores
	var objective_changed: bool = _objective_label.text != _objective_text
	_objective_label.text = _objective_text
	_hp_fill.size.x = _hp_track.size.x * _hp_fraction
	if objective_changed:
		_layout()

## Required combat framing excludes the actual fitted status/objective region
## and controls. Normalized coordinates also apply to the pixel SubViewport.
## This pure view does not relayout UI or authorize attacks through overlays.
func combat_safe_rect() -> Rect2:
	if not _built or not is_instance_valid(_root) or not is_instance_valid(_objective_label) or not is_instance_valid(_hint_panel):
		return Rect2()
	var screen: Vector2 = get_viewport().get_visible_rect().size
	if screen.x <= 0.0 or screen.y <= 0.0:
		return Rect2()
	var factor: float = clampf(screen.x / 540.0, 0.6, 2.0)
	var edge: float = 22.0 * factor
	var top: float = _objective_label.position.y + _objective_label.size.y
	if is_instance_valid(_telemetry_label) and _telemetry_label.visible:
		top = maxf(top, _telemetry_label.position.y + _telemetry_label.size.y)
	top += 12.0 * factor
	var bottom: float = _hint_panel.position.y - 12.0 * factor
	if bottom <= top or screen.x <= 2.0 * edge:
		return Rect2()
	return Rect2(Vector2(edge / screen.x, top / screen.y), Vector2((screen.x - 2.0 * edge) / screen.x, (bottom - top) / screen.y))


func show_title() -> void:
	setup()
	_mode = MODE_TITLE
	_shade.visible = true
	_reset_button.visible = false
	_card_kicker.text = "GESTURE COMBAT TEST"
	_card_title.text = "CINDER //\nGESTURE LAB"
	_card_body.text = "Swipe to move in any direction. Tap to slash; double tap to follow the slash with a point-blank blast."
	_card_button.text = "TAP TO START  >"
	_layout()


func hide_overlay() -> void:
	setup()
	_mode = MODE_PLAY
	_shade.visible = false
	_reset_button.visible = true


func set_level_preview(enabled: bool) -> void:
	_level_preview = enabled
	_bench_button.text = "PAUSE" if enabled else "LOADOUT"
	_telemetry_label.visible = not enabled


func set_campaign_mode() -> void:
	setup()
	set_level_preview(true)
	_reset_button.text = "RETRY"
	_reset_button.tooltip_text = "Restore the saved checkpoint, including health, ammo and encounter state."


func show_pause() -> void:
	setup()
	_mode = MODE_TITLE
	_shade.visible = true
	_reset_button.visible = false
	_card_kicker.text = "LEVEL PREVIEW"
	_card_title.text = "PAUSED"
	_card_body.text = "Simulation paused. Tap below to continue."
	_card_button.text = "RESUME  >"
	_layout()


func show_end(won: bool, cores: int) -> void:
	setup()
	_mode = MODE_END
	_shade.visible = true
	_reset_button.visible = false
	_card_kicker.text = "TEST SESSION // %d CORES" % maxi(cores, 0)
	_card_title.text = "TEST COMPLETE" if won else "TEST OVER"
	_card_body.text = "The mechanics test is complete. Tap below to reset." if won else "You went down. Tap below to try again."
	_card_button.text = "TAP TO RESET  >"
	if _level_preview:
		_card_kicker.text = "LEVEL PREVIEW"
		_card_title.text = "PREVIEW COMPLETE" if won else "PREVIEW OVER"
		_card_body.text = "Tap below to restart this level preview."
	_layout()


func flash_message(message: String) -> void:
	setup()
	_flash_token += 1
	_objective_label.text = message.to_upper()
	_layout()
	if is_inside_tree():
		get_tree().create_timer(1.8, false).timeout.connect(_restore_objective.bind(_flash_token))

func update_lab(player: CinderPlayer, anchor: Vector2, teaching: bool) -> void:
	_name_label.text = "CINDER / " + player.stats.weapon_name.to_upper()
	_telemetry_label.text = "DASH %.2f UNITS  /  %.2f UNITS/S" % [player.stats.dash_distance, player.stats.dash_speed]
	if not player.last_action.is_empty():
		_telemetry_label.text += "\n%s  %.1f DAMAGE  /  %d HITS" % [player.last_action.kind.to_upper(), player.last_action.damage, player.last_action.hits]
	if player.last_dash_distance > 0.0:
		_telemetry_label.text += "\nLAST LANDING  %.2f UNITS" % player.last_dash_distance
	_anchor_label.visible = teaching
	_anchor_label.position = anchor - Vector2(10, 10)
	_anchor_caption.visible = teaching
	_anchor_caption.position = anchor + Vector2(24, 16)


func _build_status() -> void:
	_status_panel = _panel(_root)
	_name_label = _label(_status_panel, "CINDER // GESTURE LAB", RED, 14)
	_hp_label = _label(_status_panel, "HP  100 / 100", PALE, 19)
	_shell_label = _label(_status_panel, "SHELLS  6 / 6", PALE, 19)

	_hp_track = ColorRect.new()
	_hp_track.color = Color(0.21, 0.11, 0.13)
	_hp_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_panel.add_child(_hp_track)
	_hp_fill = ColorRect.new()
	_hp_fill.color = RED
	_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_panel.add_child(_hp_fill)

	_objective_label = _label(_root, _objective_text, MUTED, 14)
	_objective_label.name = "ObjectiveLabel"
	var objective_backplate := StyleBoxFlat.new()
	objective_backplate.bg_color = INK
	objective_backplate.content_margin_left = 8
	objective_backplate.content_margin_right = 8
	objective_backplate.content_margin_top = 4
	objective_backplate.content_margin_bottom = 4
	_objective_label.add_theme_stylebox_override("normal", objective_backplate)
	_objective_label.add_theme_color_override("font_color", PALE)
	# Keep the shaped text's full minimum height, including paragraph spacing
	# and the protected backplate margins, rather than a clipped one-line min.
	_objective_label.clip_text = false
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reset_button = Button.new()
	_reset_button.name = "ResetButton"
	_reset_button.text = "RESET"
	_reset_button.focus_mode = Control.FOCUS_NONE
	_reset_button.pressed.connect(func() -> void: restart_requested.emit())
	_root.add_child(_reset_button)
	_style_button(_reset_button, false)
	_bench_button = Button.new()
	_bench_button.text = "LOADOUT"
	_bench_button.focus_mode = Control.FOCUS_NONE
	_bench_button.pressed.connect(func() -> void: bench_requested.emit())
	_root.add_child(_bench_button)
	_style_button(_bench_button, false)
	_telemetry_label = _label(_root, "", MUTED, 13)
	_telemetry_label.name = "TelemetryLabel"
	_anchor_label = _label(_root, "+", MUTED, 18)
	_anchor_label.size = Vector2(20, 20)
	_anchor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_anchor_caption = _label(_root, "RELEASE POINT", MUTED, 12)

	_hint_panel = _panel(_root)
	_hint_label = _label(_hint_panel, GESTURE_HINT, PALE, 16)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mouse_hint_label = _label(_hint_panel, "AIM FROM RELEASE POINT TO TAP", MUTED, 12)
	_mouse_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mouse_hint_label.visible = true


func _build_overlay() -> void:
	_shade = ColorRect.new()
	_shade.color = Color(0.01, 0.008, 0.012, 0.91)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_card = _panel(_shade)
	_card.mouse_filter = Control.MOUSE_FILTER_PASS
	_card_rail = ColorRect.new()
	_card_rail.color = RED
	_card_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_card_rail)
	_card_kicker = _label(_card, "", RED, 14)
	_card_title = _label(_card, "", PALE, 42)
	_card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_body = _label(_card, "", MUTED, 19)
	_card_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_button = Button.new()
	_card_button.focus_mode = Control.FOCUS_NONE
	_card_button.pressed.connect(_on_card_pressed)
	_card.add_child(_card_button)
	_style_button(_card_button, true)


func _panel(parent: Node) -> Panel:
	var panel: Panel = Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = INK
	style.border_color = RED_DARK
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func _label(parent: Node, copy: String, color: Color, font_size: int) -> Label:
	var result: Label = Label.new()
	result.text = copy
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_color_override("font_color", color)
	result.add_theme_font_size_override("font_size", font_size)
	parent.add_child(result)
	return result


func _style_button(button: Button, primary: bool) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = RED if primary else INK
	normal.border_color = RED if primary else RED_DARK
	normal.set_border_width_all(2)
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.58, 0.10, 0.14) if primary else Color(0.18, 0.06, 0.08)
	var down: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	down.bg_color = Color(0.35, 0.07, 0.10)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", down)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", INK if primary else PALE)
	button.add_theme_color_override("font_hover_color", PALE)
	button.add_theme_color_override("font_pressed_color", PALE)


func _layout() -> void:
	if not _built or not is_inside_tree():
		return
	var screen: Vector2 = get_viewport().get_visible_rect().size
	if screen.x <= 0.0 or screen.y <= 0.0:
		return
	var factor: float = clampf(screen.x / 540.0, 0.6, 2.0)
	var edge: float = 22.0 * factor
	var top: float = (86.0 if OS.has_feature("mobile") else 18.0) * factor
	var status_width: float = minf(300.0 * factor, screen.x - 2.0 * edge - 100.0 * factor)
	_status_panel.position = Vector2(edge, top)
	_status_panel.size = Vector2(status_width, 116.0 * factor)
	_name_label.position = Vector2(13.0, 9.0) * factor
	_name_label.size = Vector2(status_width - 26.0 * factor, 22.0 * factor)
	_hp_label.position = Vector2(13.0, 39.0) * factor
	_hp_label.size = Vector2(125.0, 28.0) * factor
	_shell_label.position = Vector2(144.0, 39.0) * factor
	_shell_label.size = Vector2(status_width - 157.0 * factor, 28.0 * factor)
	_hp_track.position = Vector2(13.0, 89.0) * factor
	_hp_track.size = Vector2(status_width - 26.0 * factor, 9.0 * factor)
	_hp_fill.position = _hp_track.position
	_hp_fill.size = Vector2(_hp_track.size.x * _hp_fraction, _hp_track.size.y)
	_objective_label.position = Vector2(edge, top + 125.0 * factor)
	_objective_label.add_theme_font_size_override("font_size", _font(13, factor))
	_objective_label.size = Vector2(screen.x - 2.0 * edge, 45.0 * factor)
	# Shape against the final font/width before fitting height. The stylebox
	# belongs to the Label, so its backplate expands with these same bounds.
	_objective_label.size.y = maxf(45.0 * factor, ceilf(_objective_label.get_minimum_size().y))
	_reset_button.position = Vector2(screen.x - edge - 88.0 * factor, top)
	_reset_button.size = Vector2(88.0, 42.0) * factor
	_bench_button.position = Vector2(_reset_button.position.x, top + 54.0 * factor)
	_bench_button.size = Vector2(88.0, 42.0) * factor
	_bench_button.add_theme_font_size_override("font_size", _font(13, factor))
	_telemetry_label.position = Vector2(edge, _objective_label.position.y + _objective_label.size.y)
	_telemetry_label.size = Vector2(screen.x - edge * 2.0, 76.0 * factor)
	_telemetry_label.add_theme_font_size_override("font_size", _font(12, factor))

	var hint_width: float = minf(screen.x - 2.0 * edge, 496.0 * factor)
	var bottom: float = (70.0 if OS.has_feature("mobile") else 20.0) * factor
	_hint_panel.position = Vector2((screen.x - hint_width) * 0.5, screen.y - bottom - 94.0 * factor)
	_hint_panel.size = Vector2(hint_width, 94.0 * factor)
	_hint_label.position = Vector2(10.0, 10.0) * factor
	_hint_label.size = Vector2(hint_width - 20.0 * factor, 57.0 * factor)
	_mouse_hint_label.position = Vector2(10.0, 70.0) * factor
	_mouse_hint_label.size = Vector2(hint_width - 20.0 * factor, 18.0 * factor)
	if OS.has_feature("mobile"):
		_hint_label.position.y = 18.0 * factor

	var card_width: float = minf(screen.x - 32.0 * factor, 466.0 * factor)
	var card_height: float = minf(screen.y - 32.0 * factor, 430.0 * factor)
	_card.position = (screen - Vector2(card_width, card_height)) * 0.5
	_card.size = Vector2(card_width, card_height)
	_card_rail.position = Vector2.ZERO
	_card_rail.size = Vector2(6.0 * factor, card_height)
	var inset: float = 27.0 * factor
	var content_width: float = card_width - 2.0 * inset
	_card_kicker.position = Vector2(inset, 29.0 * factor)
	_card_kicker.size = Vector2(content_width, 25.0 * factor)
	_card_title.position = Vector2(inset, 68.0 * factor)
	_card_title.size = Vector2(content_width, 116.0 * factor)
	_card_body.position = Vector2(inset, 208.0 * factor)
	_card_body.size = Vector2(content_width, 105.0 * factor)
	_card_button.position = Vector2(inset, card_height - 92.0 * factor)
	_card_button.size = Vector2(content_width, 58.0 * factor)

	_name_label.add_theme_font_size_override("font_size", _font(13, factor))
	_hp_label.add_theme_font_size_override("font_size", _font(17, factor))
	_shell_label.add_theme_font_size_override("font_size", _font(17, factor))
	_reset_button.add_theme_font_size_override("font_size", _font(14, factor))
	_hint_label.add_theme_font_size_override("font_size", _font(17, factor))
	_mouse_hint_label.add_theme_font_size_override("font_size", _font(12, factor))
	_card_kicker.add_theme_font_size_override("font_size", _font(14, factor))
	_card_title.add_theme_font_size_override("font_size", _font(40, factor))
	_card_body.add_theme_font_size_override("font_size", _font(18, factor))
	_card_button.add_theme_font_size_override("font_size", _font(20, factor))


func _font(base: int, factor: float) -> int:
	return maxi(11, int(round(float(base) * factor)))


func _on_card_pressed() -> void:
	if _mode == MODE_TITLE:
		start_requested.emit()
	elif _mode == MODE_END:
		restart_requested.emit()


func _restore_objective(token: int) -> void:
	if token == _flash_token and is_instance_valid(_objective_label):
		_objective_label.text = _objective_text
		_layout()
