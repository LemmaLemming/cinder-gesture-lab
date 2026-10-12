class_name LabBench
extends CanvasLayer
## A paused safe-boundary comparison. All controls consume their own taps.

signal resume_requested
signal item_requested(item_id: String)
signal exercise_requested(mode: String)

var hero: CinderPlayer
var can_equip: bool = true
var candidate: String = ""
var _root: Control
var _stats: Label
var _tradeoff: Label
var _apply: Button
var _selectors: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	_build()
	visible = false

func show_bench(player: CinderPlayer, safe: bool) -> void:
	hero = player
	can_equip = safe
	candidate = hero.equipment.equipped.weapon
	for slot: String in _selectors:
		var select: OptionButton = _selectors[slot]
		select.clear()
		for definition: Dictionary in hero.equipment.available_items(slot):
			select.add_item(definition.name)
			select.set_item_metadata(select.item_count - 1, definition.id)
			if definition.id == hero.equipment.equipped[slot]:
				select.select(select.item_count - 1)
		select.disabled = not safe
	visible = true
	_refresh()

func _build() -> void:
	_root = ColorRect.new()
	_root.color = Color(0.025, 0.027, 0.036, 0.97)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	_root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var heading := _label(header, "CINDER / LOADOUT", 16, Color(0.69, 0.73, 0.75))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var resume := _button(header, "RESUME  >")
	resume.name = "ResumeButton"
	resume.custom_minimum_size.x = 136
	resume.pressed.connect(func() -> void: resume_requested.emit())
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 16)
	scroll.add_child(box)
	_label(box, "Prepare your traveller", 30)
	_label(box, "Simulation paused. Select a piece, compare, then equip.\nOne weapon profile supplies the slash and blast.", 18)
	for slot: String in ["weapon", "jacket", "pants", "shoes"]:
		var row := HBoxContainer.new()
		box.add_child(row)
		var title := _label(row, slot.capitalize(), 20)
		title.custom_minimum_size.x = 90
		var select := OptionButton.new()
		select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select.custom_minimum_size.y = 48
		select.add_theme_font_size_override("font_size", 20)
		select.focus_mode = Control.FOCUS_NONE
		row.add_child(select)
		_selectors[slot] = select
		select.item_selected.connect(func(index: int) -> void:
			candidate = String(select.get_item_metadata(index))
			_refresh())
	_tradeoff = _label(box, "", 18, Color(0.75, 0.78, 0.78))
	_stats = _label(box, "", 19)
	_apply = _button(box, "EQUIP SELECTED PIECE")
	_apply.pressed.connect(func() -> void:
		item_requested.emit(candidate)
		show_bench(hero, can_equip))
	_label(box, "Exercise reset restores full HP and shells, keeps your gear,\nand resets targets and supplies.", 17, Color(0.67, 0.70, 0.71))
	var choices := HBoxContainer.new()
	box.add_child(choices)
	for choice: Array in [["targets", "TARGETS"], ["duel", "ONE ENEMY"], ["arena", "THREE ENEMIES"]]:
		var button := _button(choices, choice[1])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void: exercise_requested.emit(choice[0]))

func _refresh() -> void:
	var comparison: Dictionary = hero.equipment.compare(candidate, hero.hp)
	var before: Dictionary = comparison.before
	var after: Dictionary = comparison.after
	_tradeoff.text = comparison.name + " — " + comparison.role + "\nTradeoff: " + comparison.tradeoff
	if not can_equip:
		_tradeoff.text = "Finish this encounter to change clothing.\nReset to Targets for a safe loadout boundary."
	_stats.text = "                       CURRENT  →  SELECTED\n" \
		+ "Slash damage       %.1f  →  %.1f\n" % [before.primary_damage, after.primary_damage] \
		+ "Blast damage       %.1f  →  %.1f\n" % [before.followup_damage, after.followup_damage] \
		+ "Recovery (s)       %.3f / %.3f  →  %.3f / %.3f\n" % [before.primary_cooldown, before.followup_cooldown, after.primary_cooldown, after.followup_cooldown] \
		+ "Reach (units)      %.2f / %.2f  →  %.2f / %.2f\n" % [before.primary_range, before.followup_range, after.primary_range, after.followup_range] \
		+ "Dash speed         %.2f  →  %.2f units/s\n" % [before.dash_speed, after.dash_speed] \
		+ "Dash distance      %.2f  →  %.2f units\n" % [before.dash_distance, after.dash_distance] \
		+ "Max HP             %.0f  →  %.0f\n" % [before.max_health, after.max_health] \
		+ "Damage reduction   %.1f%%  →  %.1f%%\n" % [before.damage_reduction * 100.0, after.damage_reduction * 100.0] \
		+ "Armour divisor     %.2f  →  %.2f\n" % [before.armour, after.armour] \
		+ "HP after equip     %.1f  (%.1f discarded)\n" % [comparison.new_hp, comparison.hp_discarded] \
		+ "Perk               None\n" \
		+ "Capped bonuses     " + (", ".join(after.capped_stats) if not after.capped_stats.is_empty() else "None")
	_apply.disabled = not can_equip or hero.equipment.equipped[comparison.slot] == candidate

func _label(parent: Node, copy: String, font_size: int, tint: Color = Color(0.91, 0.92, 0.88)) -> Label:
	var label := Label.new()
	label.text = copy
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, copy: String) -> Button:
	var button := Button.new()
	button.text = copy
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 18)
	button.focus_mode = Control.FOCUS_NONE
	parent.add_child(button)
	return button
