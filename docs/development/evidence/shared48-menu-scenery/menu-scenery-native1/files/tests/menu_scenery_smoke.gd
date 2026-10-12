extends "res://tests/replay_comparison_snapshot_smoke.gd"
## Focused shared static Title/Journey scenery regression.
## Queued native/interface checks and optional actual portrait captures.
## One actual paused A1 Shell supplies all nonempty live/save/input receipts.
## Other act Title themes below are explicitly TEST standalone 2D art previews,
## not current A2/A3 gameplay, earned progression or an accepted scene substitute.

const Scenery = preload("res://scripts/ui/campaign_scenery.gd")
var _scenery_capture: bool = false
var _gallery: CanvasLayer
var _scenic_capture_count: int = 0

func _run() -> void:
	_scenery_capture = "--capture-portraits" in OS.get_cmdline_user_args()
	if _scenery_capture and DisplayServer.get_name() == "headless":
		_expect(false, "scenic captures require a real graphical renderer")
		_finish(); return
	_isolated_root = "user://test-menu-scenery-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	_capture_root = "res://.cinder/captures/menu-scenery-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_watchdog = Timer.new()
	_watchdog.process_mode = Node.PROCESS_MODE_ALWAYS
	_watchdog.one_shot = true
	_watchdog.wait_time = 60.0
	_watchdog.timeout.connect(_watchdog_expired)
	root.add_child(_watchdog)
	_watchdog.start()
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
	_expect(paused and game.player == null and game.menu.page_name() == "title", "fresh actual Shell begins paused with NULL Player")
	game.menu.begin_story_requested.emit()
	await _settle()
	if not is_instance_valid(game.player) or not is_instance_valid(game.active_level):
		_expect(false, "public Begin installs actual shared Player/plain existing test floor: " + game.campaign_error)
		await _dispose_shell(); _finish(); return
	game.input_observed.connect(_input_seen)
	game.aim_anchor_changed.connect(_anchor_seen)
	game.player.world_action_executed.connect(_world_action_seen)
	_expect(paused and game.player.get_world_action_clock() == 0.0 and game.player.get_world_action_records().is_empty(), "scenic tests never Resume or execute gameplay")
	var before: Dictionary = _receipt()
	game.menu.show_title()
	await _settle()
	var title: Control = game.menu.find_child("TitleScenery", true, false) as Control
	_check_scenic(title, 1, "title", true, true, "actual protected A1-L1 Title")
	_expect_unchanged(before, "actual Title construction/native layout")
	if _scenery_capture:
		if not await _capture_view("01-actual-a1-title", "title", ["TitleScenery", "EquipmentPreview", "SavedCheckpointLabel"]):
			await _dispose_shell(); _finish(); return
		_scenic_capture_count += 1
	before = _receipt()
	game.menu.show_journey()
	await _settle()
	var authored: Dictionary = _node_layout()
	var locks: Dictionary = _node_states()
	_expect(authored.size() == raw.levels.size() and locks.size() == raw.levels.size(), "scenery creates no extra level buttons or metadata")
	_check_story_traveller()
	_check_route_draw_order()
	for act: int in range(1, 4):
		var scenic: Control = game.menu.find_child("Act%dRouteScenery" % act, true, false) as Control
		_check_scenic(scenic, act, "route", act == 1, act == 1, "actual route region%d" % act)
		# Native shortcut scrolling changes no world pose or story selection.
		var button: Button = game.menu.find_child("Act%dShortcut" % act, true, false) as Button
		_expect(is_instance_valid(button), "real native act shortcut exists for region%d" % act)
		if is_instance_valid(button): button.pressed.emit()
		await _settle()
		_expect(_node_layout() == authored and _node_states() == locks, "native region%d scroll retains all authored local node positions/locks" % act)
		if _scenery_capture:
			if not await _capture_view("0%d-actual-route-region%d" % [act + 1, act], "journey", ["Act%dRouteScenery" % act, "Act%dTitle" % act]):
				await _dispose_shell(); _finish(); return
			_scenic_capture_count += 1
	game.menu.select_level("A3-L5")
	var card: Label = game.menu.find_child("LevelCardTitle", true, false) as Label
	var action: Button = game.menu.find_child("LevelCardAction", true, false) as Button
	_expect(is_instance_valid(card) and not card.text.contains("Crystalman") and is_instance_valid(action) and action.disabled, "scenery never reveals or launches an unreached boss/unfinished level")
	_expect_unchanged(before, "all native route region/layout/selection waits")
	before = _receipt()
	game.menu.show_journey()
	await _settle()
	_expect(_node_layout() == authored and _node_states() == locks, "same-size repeated Journey rebuild retains exact node geometry/locks")
	await _resize_check(authored, locks)
	_expect_unchanged(before, "rebuild and native portrait resize")
	# Standalone art controls use the SAME actual protected story equipment.
	# No menu/model/controller is reconfigured to pretend another current act.
	for act: int in range(1, 4):
		if not await _standalone_theme(act, act == 1):
			await _dispose_shell(); _finish(); return
	# The later Moon landmark is a static art-only supported branch, not a fake
	# A1-L2 progress stamp. No extra production-world or encounter is loaded.
	if not await _standalone_theme(1, false):
		await _dispose_shell(); _finish(); return
	_expect(_events.is_empty() and game.player.get_world_action_clock() == 0.0, "every menu and TEST theme wait publishes no input/aim/world action or clock advance")
	await _dispose_shell()
	_finish()

func _check_scenic(control: Control, act: int, mode: String, revealed: bool, earth: bool, note: String) -> void:
	_expect(is_instance_valid(control) and control.get_script() == Scenery and control.is_visible_in_tree(), note + " retains exact actual scenic Control")
	if not is_instance_valid(control) or control.get_script() != Scenery: return
	_expect(control.mouse_filter == Control.MOUSE_FILTER_IGNORE and control.focus_mode == Control.FOCUS_NONE and not control.is_processing() and not control.is_physics_processing(), note + " decoration has no interaction, focus, animation or physics tick")
	var descriptor: Dictionary = control.call("presentation_state")
	_expect(not FocusExact.stringify(descriptor).is_empty() and descriptor.get("act") == act and descriptor.get("mode") == mode and descriptor.get("revealed") == revealed and descriptor.get("earth_launch") == earth, note + " bounded descriptor matches only actual revealed/scenic context")
	var encoded: String = FocusExact.stringify(descriptor)
	_expect(not bool(control.call("configure", 0, mode, revealed, earth)) and FocusExact.stringify(control.call("presentation_state")) == encoded, note + " refused configuration preserves existing finite presentation")
	var static_children: bool = true
	for child: Node in control.get_children():
		# Root retains the SAME existing shared preview as a native TextureRect
		# child of TitleScenery; it has no controller or animation Script.
		static_children = static_children and child is TextureRect and child.name == "EquipmentPreview" and child.get_script() == null and (child as TextureRect).mouse_filter == Control.MOUSE_FILTER_IGNORE and (child as TextureRect).focus_mode == Control.FOCUS_NONE and not child.is_processing() and not child.is_physics_processing()
	_expect(static_children, note + " contains only a possible existing static shared preview, no actors/buttons/timers")

func _check_route_draw_order() -> void:
	var path: Control = game.menu.find_child("JourneyPath", true, false) as Control
	var links: Control = game.menu.find_child("JourneyConnections", true, false) as Control
	var valid: bool = is_instance_valid(path) and is_instance_valid(links)
	if not valid:
		_expect(false, "actual route has separate native scenery/links/node families"); return
	valid = links.get_parent() == path and links.z_index == 0
	for act: int in range(1, 4):
		var scenic: Control = game.menu.find_child("Act%dRouteScenery" % act, true, false) as Control
		valid = valid and is_instance_valid(scenic) and scenic.get_parent() == path and scenic.z_index == 0 and scenic.get_index() < links.get_index()
	for info: Dictionary in raw.levels:
		var button: Button = game.menu.find_child("Node_" + String(info.id).replace("-", "_"), true, false) as Button
		valid = valid and is_instance_valid(button) and button.get_parent() == path and button.z_index == 0 and button.get_index() > links.get_index()
	_expect(valid, "native sibling draw order retains connections above all static scenery and below every level button")
	_expect(path.get("segments") == links.get("segments"), "native connection drawing uses the exact existing authored route segments")

func _node_layout() -> Dictionary:
	var result: Dictionary = {}
	for info: Dictionary in raw.levels:
		var button: Button = game.menu.find_child("Node_" + String(info.id).replace("-", "_"), true, false) as Button
		if is_instance_valid(button): result[String(info.id)] = [button.position, button.size]
	return result

func _node_states() -> Dictionary:
	var result: Dictionary = {}
	for info: Dictionary in raw.levels:
		var button: Button = game.menu.find_child("Node_" + String(info.id).replace("-", "_"), true, false) as Button
		if is_instance_valid(button): result[String(info.id)] = [button.get_meta("campaign_state", ""), button.get_meta("parent_level_id", null), button.text, button.disabled]
	return result

func _resize_check(original: Dictionary, locks: Dictionary) -> void:
	root.size = Vector2i(432, 936)
	root.content_scale_size = Vector2i(432, 936)
	await _settle()
	var narrow: Dictionary = _node_layout()
	_expect(narrow.size() == raw.levels.size() and _node_states() == locks, "actual narrower portrait retains canonical node/state identities")
	var path: Control = game.menu.find_child("JourneyPath", true, false) as Control
	var safe: bool = is_instance_valid(path)
	if not safe:
		_expect(false, "native narrowed Journey path exists"); return
	for id: String in narrow:
		var pair: Array = narrow[id]
		var position: Vector2 = pair[0]
		var size: Vector2 = pair[1]
		safe = safe and size.x >= 44.0 and size.y >= 44.0 and position.x >= 0.0 and position.x + size.x <= path.size.x + 1.0
	_expect(safe, "native narrowed layout preserves accessible node widths inside route bounds")
	game.menu.show_journey()
	await _settle()
	_expect(_node_layout() == narrow and _node_states() == locks, "narrow native rebuild is stable rather than random scenery-driven scattering")
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	await _settle()
	_expect(_node_layout() == original and _node_states() == locks, "return to original portrait restores exact authored node positions")

func _standalone_theme(act: int, earth: bool) -> bool:
	var before: Dictionary = _receipt()
	_gallery = CanvasLayer.new()
	_gallery.layer = 60
	root.add_child(_gallery)
	var background := ColorRect.new()
	background.color = Color("0c1019")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.size = Vector2(540, 1170)
	_gallery.add_child(background)
	var heading := Label.new()
	heading.text = "TEST SCENIC PREVIEW · ACT%d" % act
	heading.position = Vector2(20, 32)
	heading.add_theme_font_size_override("font_size", 22)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(heading)
	var scenic: Control = Scenery.new() as Control
	scenic.name = "TESTStandaloneTheme"
	scenic.position = Vector2(20, 110)
	scenic.size = Vector2(500, 360)
	background.add_child(scenic)
	if not bool(scenic.call("configure", act, "title", true, earth)):
		_expect(false, "standalone scenic art accepts its supported finite configuration")
		_gallery.free(); _gallery = null; return false
	var preview := TextureRect.new()
	preview.name = "TESTSharedTraveller"
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture = ReplayArt.preview_texture(ReplayArt.presentation_for_act(act), game.attempts.story_snapshot().equipment_ids)
	scenic.add_sibling(preview)
	var where: Rect2 = scenic.call("traveller_rect")
	preview.position = scenic.position + where.position
	preview.size = where.size
	var state: String = FocusExact.stringify(scenic.call("presentation_state"))
	await _settle()
	_check_scenic(scenic, act, "title", true, earth, "explicit TEST standalone theme%d" % act)
	_expect(not state.is_empty() and FocusExact.stringify(scenic.call("presentation_state")) == state, "native process waits do not advance static scenic state")
	var expected: Texture2D = ReplayArt.preview_texture(ReplayArt.presentation_for_act(act), game.attempts.story_snapshot().equipment_ids)
	_expect(preview.texture != null and expected != null and preview.texture.get_image().get_data() == expected.get_image().get_data(), "TEST theme%d retains native shared act headwear and actual protected gear pixels" % act)
	_expect(where.has_area() and Rect2(Vector2.ZERO, scenic.size).encloses(where), "actual scenic feet-anchor rectangle contains the whole shared traveller")
	if _scenery_capture:
		if not await _capture_standalone(act, earth, scenic, preview):
			_gallery.free(); _gallery = null; return false
	_gallery.free()
	_gallery = null
	_expect_unchanged(before, "TEST standalone theme%d creation/layout/free" % act)
	return true

func _capture_standalone(act: int, earth: bool, scenic: Control, preview: TextureRect) -> bool:
	if DisplayServer.get_name() == "headless":
		_expect(false, "scenic capture requires actual graphical renderer"); return false
	var before: Dictionary = _receipt()
	_capture_wait_id += 1
	var token: int = _capture_wait_id
	_capture_waiting = true
	create_timer(8.0, true).timeout.connect(func() -> void:
		if _capture_waiting and _capture_wait_id == token:
			push_error("Static scenery frame_post_draw timeout; no draw/focus override or cleanup claim")
			quit(1))
	await RenderingServer.frame_post_draw
	_capture_waiting = false
	var label: String = "test-title-act%d-%s" % [act, "earth" if earth else "later"]
	var path: String = ProjectSettings.globalize_path(_capture_root + label + ".png")
	var image: Image = root.get_texture().get_image()
	var ok: bool = image != null and image.get_size() == Vector2i(540, 1170) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_root)) == OK and image.save_png(path) == OK
	_expect(ok, "actual native TEST-only theme portrait stored: " + path)
	_expect(_capture_clip_rect(preview).encloses(preview.get_global_rect()) and scenic.is_visible_in_tree(), "actual native whole standalone preview fits its viewport")
	_expect_unchanged(before, "static theme frame_post_draw")
	if ok:
		_scenic_capture_count += 1
		print("MENU_SCENERY_TEST_PORTRAIT ", FocusExact.stringify({"path": path, "sha256": FileAccess.get_sha256(path), "act": act, "earth_launch": earth, "paused": paused, "focus_observed": root.has_focus(), "scope": "standalone TEST 2D scenic control/shared preview; actual protected A1 Player/model unchanged; no current A2/A3 gameplay or GUI hit-test claim"}))
	return ok

func _finish() -> void:
	_capture_waiting = false
	if is_instance_valid(_gallery): _gallery.free()
	if _scenery_capture:
		_expect(_scenic_capture_count == 8, "graphical scope supplies actual Title/three route regions and four explicitly TEST standalone Title themes")
	if is_instance_valid(_watchdog):
		_watchdog.stop(); _watchdog.free()
	paused = false
	_cleanup()
	print("Shared menu scenery: %d checks, %d failures; native captures=%d; actual paused A1 interface + TEST standalone theme art, no gameplay/GUI hit-test claim" % [checks, failures, _scenic_capture_count])
	quit(1 if failures else 0)
