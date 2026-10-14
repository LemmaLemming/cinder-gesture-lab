extends "res://tests/acts/act3/pillars_before_time_optional_shell.gd"
## Paused-only native graphical reader of the original held-warning archive.
## Public Shell startup/Side Resume, exact archived packets and actual optics.
## TEST-only Menu CanvasLayer exclusion; no simulation/input/actor writes.
## One representative frame; no active/lateral/full-route or pacing claim.

var draw_seen: bool = false
var portrait_path: String = ""
var provenance: Dictionary = {}

func _run() -> void:
	create_timer(90.0, true).timeout.connect(func() -> void:
		if not finished:
			_expect(false, "bounded paused O1 portrait watchdog")
			_finish())
	root.size = Vector2i(340, 736)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	canonical_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	if not _expect(DisplayServer.get_name() != "headless", "portrait requires actual native graphical renderer"):
		await _finish(); return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not _expect(args.size() == 1 and args[0].begins_with("--archive=res://captures/act3/pillars-before-time/"), "one explicit owned genuine warning archive is required"):
		await _finish(); return
	archive_path = args[0].trim_prefix("--archive=")
	var decoded: Dictionary = Exact.parse(FileAccess.get_file_as_string(archive_path.path_join("manifest.json")))
	if not _expect(decoded.get("accepted", false) and decoded.get("value") is Dictionary, "original warning manifest parses with native exact transport"):
		await _finish(); return
	provenance = decoded.value
	if not _expect(provenance.get("kind") == "a3-o1-genuine-warning-session-1" and provenance.get("test_only") == true and provenance.get("source_pins") is Dictionary and provenance.get("files") is Dictionary, "original TEST native warning provenance identifies its source/file scope"):
		await _finish(); return
	for path: String in provenance.source_pins:
		if not _expect(FileAccess.get_sha256(path) == provenance.source_pins[path], "current scoped source retains original warning authority: " + path):
			await _finish(); return
	raw = _original_packet("registry.native.json")
	expected_session = _original_packet("session.native.json")
	held = _original_packet("held.native.json")
	checkpoint = _original_packet("checkpoint.native.json")
	protected = _original_packet("story.native.json")
	if failures > 0 or not _expect(not raw.is_empty() and not expected_session.is_empty() and not held.is_empty() and _same(expected_session.side_attempt.snapshot, held) and _same(expected_session.side_attempt.checkpoint, checkpoint) and _same(expected_session.story.snapshot, protected), "complete original warning session matches independently archived native packets"):
		await _finish(); return
	var registry = Registry.new(raw)
	var detached = Attempts.new(registry)
	var writer = Store.new(isolated + "campaign.json")
	writer.payload_validator = detached.saved_payload_error
	paused = true
	if not _expect(registry.last_error.is_empty() and detached.state_error(expected_session).is_empty() and writer.write_payload(expected_session), "isolated detached format2 Store retains the original complete native session", registry.last_error + "; " + writer.last_error):
		await _finish(); return
	node_added.connect(_watch_node)
	if not await _new_shell(expected_session): await _finish(); return
	production.menu.resume_requested.emit() # Public Title Side Resume; stays paused.
	if not await _wait_installed("A3-O1", "resume", held): await _finish(); return
	if not _installed(held) or not _quiet_selected() or not _disk(expected_session): await _finish(); return
	if not _expect(_same(_held_receipt(), provenance.held_receipt), "fresh native recipient carries the original genuine warning lease/phase/cycle/clock"):
		await _finish(); return
	if not await _portrait(): await _finish(); return
	scope_complete = true
	await _finish()

func _original_packet(filename: String) -> Dictionary:
	var path: String = archive_path.path_join(filename)
	if not _expect(provenance.files.has(filename) and FileAccess.get_sha256(path) == provenance.files[filename].sha256, "original native file checksum: " + filename): return {}
	var decoded: Dictionary = Exact.parse(FileAccess.get_file_as_string(path))
	if not _expect(decoded.get("accepted", false) and decoded.get("value") is Dictionary, "original finite exact native packet: " + filename): return {}
	var packet: Dictionary = decoded.value
	if not _expect(Exact.stringify(packet).sha256_text() == provenance.files[filename].exact_wire_sha256, "original exact native wire checksum: " + filename): return {}
	return packet

func _portrait() -> bool:
	await process_frame # Native UI layout only; gameplay remains paused.
	var view: SubViewport = production.world.get_parent() as SubViewport
	var container: SubViewportContainer = view.get_parent() as SubViewportContainer
	if not _expect(paused and not production.is_pause_requested() and container.is_visible_in_tree() and view.own_world_3d and view.get_camera_3d() == production.camera and production.hud.visible and production.menu.visible, "actual installed native World/Camera/Hero/HUD and paused Menu are visible"):
		return false
	var wire: String = Exact.stringify(production.capture_campaign_snapshot())
	var input: PackedByteArray = var_to_bytes(production.get_input_observation_state())
	var optics: PackedByteArray = var_to_bytes(_optics_record())
	var events: PackedByteArray = var_to_bytes(receiver_events)
	var menu_visibility: bool = production.menu.visible
	production.menu.visible = false # TEST ONLY independent overlay exclusion.
	draw_seen = false
	RenderingServer.frame_post_draw.connect(_on_draw)
	for _frame: int in range(32):
		await process_frame
		if finished or not is_instance_valid(production): return false
		if draw_seen: break
	if RenderingServer.frame_post_draw.is_connected(_on_draw): RenderingServer.frame_post_draw.disconnect(_on_draw)
	var pixels: Image = root.get_texture().get_image() if draw_seen else null
	var problem: String = String(production.active_level.call("candidate_presentation_error", production.camera, production.hud))
	var unchanged: bool = paused and not production.is_pause_requested() and not wire.is_empty() and wire == Exact.stringify(production.capture_campaign_snapshot()) and input == var_to_bytes(production.get_input_observation_state()) and optics == var_to_bytes(_optics_record()) and events == var_to_bytes(receiver_events)
	production.menu.visible = menu_visibility # Restore before every failure return.
	if not _expect(draw_seen and pixels != null and pixels.get_size().x in [339, 340] and pixels.get_size().y == 736 and unchanged and production.menu.visible == menu_visibility and problem.is_empty(), "native paused portrait preserves full packet/input/current Camera/HUD/events and restores Menu", problem):
		return false
	var folder: String = "res://captures/act3/pillars-before-time/portrait-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	portrait_path = folder.path_join("01-authentic-held-warning.png")
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK and pixels.save_png(portrait_path) == OK, "original native portrait pixels saved unchanged"):
		return false
	var receipt: Dictionary = {"schema_version": 1, "test_only": true, "archive": archive_path, "archive_manifest_sha256": FileAccess.get_sha256(archive_path.path_join("manifest.json")), "reader_sha256": FileAccess.get_sha256("res://tests/acts/act3/pillars_before_time_portrait.gd"), "png_sha256": FileAccess.get_sha256(portrait_path), "actual_size": [pixels.get_size().x, pixels.get_size().y], "actual_native_ids": _native_ids(), "held_receipt": _held_receipt(), "whole_pair_exact_wire_sha256": wire.sha256_text(), "paused_without_tick": true, "whole_pair_input_camera_hud_events_unchanged": unchanged, "native_optical_error": problem, "menu_test_only_exclusion": {"visible_before": menu_visibility, "visible_during": false, "visible_restored": production.menu.visible}, "scope": "one authentic saved warning; no active/lateral/full-route/pacing/human balance claim"}
	var file: FileAccess = FileAccess.open(portrait_path + ".json", FileAccess.WRITE)
	if not _expect(file != null, "native portrait receipt opens"): return false
	file.store_string(Exact.stringify(receipt) + "\n")
	file.close()
	print("O1 PORTRAIT: ", ProjectSettings.globalize_path(portrait_path))
	return true

func _optics_record() -> Dictionary:
	var camera: Camera3D = production.camera
	var labels: Array = []
	_label_record(production.hud, labels)
	return {"camera": [camera.global_transform, camera.projection, camera.keep_aspect, camera.size, camera.near, camera.far, camera.h_offset, camera.v_offset], "hud": [production.hud.visible, production.hud.combat_safe_rect(), labels]}

func _label_record(node: Node, labels: Array) -> void:
	if node is Label:
		var label: Label = node as Label
		labels.append([str(production.hud.get_path_to(label)), label.text, label.is_visible_in_tree(), label.global_position, label.size, label.get_theme_font_size("font_size")])
	for child: Node in node.get_children(): _label_record(child, labels)

func _on_draw() -> void:
	draw_seen = true

func _finish() -> void:
	if finished: return
	finished = true
	await _dispose_shell()
	if node_added.is_connected(_watch_node): node_added.disconnect(_watch_node)
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal native portrait cleanup releases all source/cue groups")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == canonical_bytes, "canonical registry bytes remain unchanged")
	for filename: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		var path: String = isolated + filename
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	AudioServer.set_bus_layout(old_audio)
	Engine.max_fps = old_fps
	paused = false
	print("O1 paused portrait: %d checks/%d failures; scope_complete=%s; actual original-warning Side Resume/optics/pixels/whole cleanup only." % [checks, failures, str(scope_complete)])
	quit(0 if failures == 0 and scope_complete else 1)
