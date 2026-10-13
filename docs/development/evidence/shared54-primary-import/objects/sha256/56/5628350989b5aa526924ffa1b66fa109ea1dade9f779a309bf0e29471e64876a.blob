extends "res://tests/replay_comparison_snapshot_smoke.gd"
## Actual paused Shell and native Title controls. TEST-only existing plain floor.
## Immediate destruction reproduces deferred node-capture lifetime faults.
## Living rebuild/resize must preserve complete real save/model/player/input.

func _run() -> void:
	_isolated_root = "user://test-menu-scenery-lifecycle-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	root.size = Vector2i(540, 1170)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	create_timer(30.0, true).timeout.connect(func() -> void:
		_expect(false, "focused lifecycle watchdog")
		_finish())
	_cleanup()
	raw = JSON.parse_string(FileAccess.get_file_as_string(Registry.DATA_PATH))
	for info: Dictionary in raw.levels:
		if info.id == "A1-L1":
			info.scene_path = "res://tests/fixtures/campaign/live_a1_l1.tscn"
			info.readiness = "accepted"
			info.accepted_commit = "a".repeat(40)
			info.api_revision = Registry.API_REVISION
	game = _new_shell()
	await _settle()
	game.menu.begin_story_requested.emit()
	await _settle()
	if not is_instance_valid(game.player) or not is_instance_valid(game.active_level):
		_expect(false, "actual paused Player/plain floor enters through public Begin")
		_finish(); return
	game.input_observed.connect(_input_seen)
	game.aim_anchor_changed.connect(_anchor_seen)
	game.player.world_action_executed.connect(_world_action_seen)
	var before: Dictionary = _receipt()
	game.menu.show_title()
	var title: Control = game.menu.find_child("TitleScenery", true, false) as Control
	var portrait: TextureRect = game.menu.find_child("EquipmentPreview", true, false) as TextureRect
	var pair_valid: bool = title != null and portrait != null and portrait.get_parent() == title
	_expect(pair_valid, "actual pending Title layout owns scenery and portrait")
	if not pair_valid:
		_finish(); return
	var title_ref: WeakRef = weakref(title)
	var portrait_ref: WeakRef = weakref(portrait)
	# Explicit destructive TEST UI teardown before its deferred first layout.
	title.free()
	await _settle()
	_expect(title_ref.get_ref() == null and portrait_ref.get_ref() == null, "native scenery and preview really retire before deferred callback drain")
	_expect_unchanged(before, "retired Title child deferred drain")
	game.menu.show_title()
	game.menu.show_journey()
	game.menu.show_title()
	await _settle()
	_check_living_layout("rapid native page rebuild")
	_expect_unchanged(before, "rapid native page rebuild")
	root.size = Vector2i(600, 1300)
	await _settle()
	_check_living_layout("normal portrait resize")
	_expect_unchanged(before, "normal portrait resize")
	game.menu.show_title()
	var retiring: WeakRef = weakref(game)
	root.remove_child(game)
	game.free(); game = null
	await _settle()
	_expect(retiring.get_ref() == null, "whole native Shell really retires with a pending Title layout")
	game = _new_shell()
	await _settle()
	_expect(paused and game.player == null and game.menu.page_name() == "title" and game.campaign_error.is_empty(), "actual fresh disk recipient survives retired callback drain")
	game.menu.continue_story_requested.emit()
	await _settle()
	_expect_unchanged_without_native_ids(before, "fresh disk Continue after native menu destruction")
	_finish()

func _check_living_layout(note: String) -> void:
	var title: Control = game.menu.find_child("TitleScenery", true, false) as Control
	var portrait: TextureRect = game.menu.find_child("EquipmentPreview", true, false) as TextureRect
	var pair_valid: bool = title != null and portrait != null and portrait.get_parent() == title
	_expect(pair_valid, note + " retains actual living scenery/preview pair")
	if not pair_valid: return
	var rect: Rect2 = title.call("traveller_rect")
	_expect(portrait.custom_minimum_size == rect.size and portrait.position == rect.position and portrait.size == rect.size, note + " preserves the exact native traveller rectangle")

func _expect_unchanged_without_native_ids(before: Dictionary, note: String) -> void:
	var after: Dictionary = _receipt()
	for key: String in before:
		if key in ["player_id", "level_id"]: continue
		_expect(before[key] == after[key], note + " preserves actual " + key)
	_expect(before.player_id != after.player_id and before.level_id != after.level_id, note + " has independent fresh native Player/level identities")

func _finish() -> void:
	if is_instance_valid(game):
		game.free(); game = null
	paused = false
	_cleanup()
	print("Menu scenery lifecycle: %d checks, %d failures; actual retired-node/deferred callback drain, living layout/resize and whole-save/input/clock/identity custody; TEST plain floor, no campaign playthrough" % [checks, failures])
	quit(1 if failures else 0)
