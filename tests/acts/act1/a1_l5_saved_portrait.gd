extends "res://tests/acts/act1/a1_l5_shell_transport.gd"
## SOURCE ONLY: four genuine119 paused units; normal fresh Shell GUI Continue.
## No native state/HP/phase/sample/cue/camera/clock write or fight replay.
## Only the menu CanvasLayer is temporarily hidden for paused-world PNGs.

const PacketPath: String = "res://tests/acts/act1/fixtures/a1_l5_saved_portrait_units.json"
const PacketSha: String = "2daa482db269374b4360d1abc4d89ff618f6f08c1bc222bea49e139913a6dd0e"
const SourceReportSha: String = "e28d0032529186ecd317f49120d33317d799ca43a8c137a5149a479542a10321"
const PortraitSize := Vector2i(540, 1170)
const WholeMs: int = 100000
const PerViewMs: int = 20000

class FocusObserver extends Node:
	var receive: Callable
	func _notification(what: int) -> void:
		if not receive.is_valid(): return
		if what == NOTIFICATION_APPLICATION_FOCUS_IN: receive.call("application-focus-in")
		elif what == NOTIFICATION_APPLICATION_FOCUS_OUT: receive.call("application-focus-out")
		elif what == NOTIFICATION_APPLICATION_PAUSED: receive.call("application-paused")
		elif what == NOTIFICATION_APPLICATION_RESUMED: receive.call("application-resumed")

var source_hashes: Dictionary = {}
var focus_observer: Node
var focus_armed: bool = false
var focus_rows: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var capture_dir: String = ""
var view_deadline_ms: int = 0
var hidden_menu: CinderCampaignMenu
var menu_visible_before: bool = false


func _run() -> void:
	root.size = PortraitSize
	test_root = "user://test-act1-moon-saved-portrait-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	registry_bytes = FileAccess.get_file_as_bytes(Registry.DATA_PATH)
	if not _expect(DisplayServer.get_name() != "headless", "actual graphical renderer required"): await _finish(); return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--level-scene") or argument in ["--capture", "--capture-polish"]:
			_expect(false, "ordinary Shell focus/restore path required"); await _finish(); return
	var observer := FocusObserver.new()
	observer.process_mode = Node.PROCESS_MODE_ALWAYS; observer.receive = Callable(self, "_record_focus")
	focus_observer = observer; root.add_child(observer)
	root.focus_entered.connect(_record_focus.bind("window-focus-entered"))
	root.focus_exited.connect(_record_focus.bind("window-focus-exited"))
	if not await _startup_focus(): await _finish(); return
	focus_armed = true
	if not _expect(FileAccess.get_sha256(PacketPath) == PacketSha, "literal selected genuine119 bundle unchanged"): await _finish(); return
	var document: Variant = JSON.parse_string(FileAccess.get_file_as_string(PacketPath))
	if not _expect(document is Dictionary and document.get("api_revision") == "act1-l5-saved-portrait-1" and document.get("source_report_sha256") == SourceReportSha and document.get("source_checks") == 119 and document.get("source_failures") == 0 and document.get("frames") is Array and document.frames.size() == 4 and document.get("source_sha256") is Dictionary, "exact four-view provenance required"): await _finish(); return
	source_hashes = document.source_sha256
	if not _source_guard(): await _finish(); return
	var registry_doc: Variant = JSON.parse_string(registry_bytes.get_string_from_utf8())
	if not _expect(registry_doc is Dictionary and registry_doc.get("levels") is Array, "canonical registry readable"): await _finish(); return
	raw = registry_doc.duplicate(true)
	for entry: Dictionary in raw.levels:
		if entry.id == Layout.LEVEL_ID:
			setups.append({"kind": "TEST in-memory L5 registration", "before": entry.duplicate(true)})
			entry.scene_path = ScenePath; entry.readiness = "accepted"; entry.accepted_commit = "f".repeat(40); entry.api_revision = Registry.API_REVISION
	var registry := Registry.new(raw)
	if not _expect(registry.last_error.is_empty(), "isolated candidate L5 metadata validates"): await _finish(); return
	capture_dir = "res://.cinder/captures/l5-saved-portrait-%d" % Time.get_ticks_usec()
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir)) == OK, "own capture directory writable"): await _finish(); return
	for row: Dictionary in document.frames:
		view_deadline_ms = Time.get_ticks_msec() + PerViewMs
		if not _focused() or not await _restore_view(row, registry) or not await _capture_view(row): await _finish(); return
		var refs: Array[WeakRef] = _refs(game)
		_end_watch("normal saved-view Shell retirement")
		game.free(); game = null
		if not _expect(_freed(refs) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "one restored world retires normally before next packet"): await _finish(); return
		await process_frame
	view_deadline_ms = 0
	await _finish()


func _restore_view(row: Dictionary, registry: CinderCampaignRegistry) -> bool:
	var decoded: Dictionary = Exact.parse(String(row.snapshot_exact))
	var checkpoint: Dictionary = Exact.parse(String(row.checkpoint_exact))
	if not _expect(decoded.get("accepted") == true and checkpoint.get("accepted") == true and decoded.value is Dictionary and checkpoint.value is Dictionary and Exact.stringify(decoded.value) == row.snapshot_exact and Exact.stringify(checkpoint.value) == row.checkpoint_exact, "original typed packets round-trip with no changed field"): return false
	var saved: Dictionary = decoded.value
	if not _closed(saved) or not _expect(saved.paused and not saved.level.progress.completed, "genuine paused uncompleted unit required"): return false
	var model := Attempts.new(registry)
	var payload: Dictionary = model.state()
	payload.completed_main = Prefix.duplicate()
	payload.story = {"kind": "story", "level_id": Layout.LEVEL_ID, "snapshot": saved.duplicate(true), "checkpoint": checkpoint.value.duplicate(true)}
	var store := Store.new(test_root + "campaign.json")
	store.payload_validator = model.saved_payload_error
	if not _expect(model.state_error(payload).is_empty() and store.write_payload(payload), "public isolated Store retains actual snapshot/earlier checkpoint plus four disclosed TEST predecessors"): return false
	_begin_watch("fresh saved-view recipient", null, null, true)
	game = _new_shell()
	if game == null or not await _settle() or not _focused(): return false
	if not _expect(paused and game.active_level == null and game.player == null and game.menu.page_name() == "title", "actual fresh Title validates the lossless Story"): return false
	if not await _continue_gui() or not _bindings(game): return false
	var actual: Dictionary = game.capture_campaign_snapshot()
	return _expect(paused and _same(actual, saved) and _durable(game) and events.is_empty() and game.active_level.snapshot_error_with_player(actual.level, actual.player).is_empty(), "normal fresh Continue quietly installs complete exact native unit/resources/leases/sample/saved camera")


func _continue_gui() -> bool:
	if not _focused(): return false
	var button: Button = game.menu.find_child("ContinueStoryButton", true, false) as Button
	if not _expect(button != null and button.is_visible_in_tree() and not button.disabled, "actual enabled Continue Story button"): return false
	var pressed: Array[String] = []
	button.pressed.connect(func() -> void: pressed.append("ContinueStoryButton"), CONNECT_ONE_SHOT)
	var point: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new(); motion.position = point; motion.global_position = point; root.push_input(motion, true)
	var press := InputEventMouseButton.new(); press.button_index = MOUSE_BUTTON_LEFT; press.position = point; press.global_position = point; press.pressed = true; root.push_input(press, true)
	await process_frame
	if not _focused(): return false
	var release := press.duplicate() as InputEventMouseButton; release.pressed = false; root.push_input(release, true)
	if not await _settle() or not _focused(): return false
	return _expect(pressed == ["ContinueStoryButton"] and game.campaign_error.is_empty(), "focus-qualified press/frame/release/frame Continue settles normally")


func _capture_view(row: Dictionary) -> bool:
	if not _focused() or not _source_guard(): return false
	var level: CinderLevel = game.active_level
	var points: Array = level.camera_framing_points()
	if not _expect(paused and not points.is_empty() and level.last_camera_framing_error.is_empty() and game.camera_framing_error(points).is_empty(), "actual saved camera/HUD contains full native source/footprint/Hero/landing union"): return false
	var before: String = Exact.stringify(game.capture_campaign_snapshot())
	var physical_before: String = _physical(level, game.player)
	var camera_before: String = _camera_wire()
	var input_before: String = Exact.stringify(_portable(game.get_input_observation_state()))
	if not _expect(before == row.snapshot_exact and not physical_before.is_empty() and not camera_before.is_empty() and not input_before.is_empty(), "full native/physical/camera/input signatures captured before menu hiding"): return false
	var ui: Dictionary = {"menu_visible": game.menu.visible, "menu_page": game.menu.page_name(), "hud_visible": game.hud.visible}
	hidden_menu = game.menu; menu_visible_before = hidden_menu.visible
	hidden_menu.visible = false # Disclosed PNG-only paused overlay hiding.
	await RenderingServer.frame_post_draw
	var valid: bool = _focused() and is_instance_valid(game) and paused
	if valid: valid = _expect(Exact.stringify(game.capture_campaign_snapshot()) == before and _physical(level, game.player) == physical_before and _camera_wire() == camera_before and Exact.stringify(_portable(game.get_input_observation_state())) == input_before, "only menu hiding preserves exact native/physical/camera/input unit")
	var picture: Image = root.get_texture().get_image() if valid else null
	var path: String = capture_dir.path_join("%02d-%s.png" % [shots.size() + 1, row.label])
	var saved_png: bool = picture != null and picture.get_size() == PortraitSize and picture.save_png(path) == OK
	_restore_menu()
	if not valid: return false
	if not _expect(saved_png and game.menu.visible == ui.menu_visible and game.menu.page_name() == ui.menu_page and game.hud.visible == ui.hud_visible and Exact.stringify(game.capture_campaign_snapshot()) == before and _physical(level, game.player) == physical_before and _camera_wire() == camera_before and Exact.stringify(_portable(game.get_input_observation_state())) == input_before, "actual540x1170 PNG and exact native/camera/input/UI restored"): return false
	shots.append({"label": row.label, "path": ProjectSettings.globalize_path(path), "source_receipt_index": row.receipt_index, "source_exact_sha256": row.snapshot_sha256, "paused_world": true, "only_menu_temporarily_hidden": true, "full_before_and_after_exact": before, "camera_before_and_after_exact": camera_before, "native_sources": _portable({"Blink": level.get("blink").state(), "Nose": level.get("nose").state()}), "capsule_pose": level.get("_capsule").presentation_state(), "optical_review": "pending personal inspection; native containment is not art acceptance"})
	return true


func _restore_menu() -> void:
	if is_instance_valid(hidden_menu): hidden_menu.visible = menu_visible_before
	hidden_menu = null


func _camera_wire() -> String:
	return Exact.stringify(_portable({"transform": game.camera.global_transform, "framing": game.get_camera_framing_state(), "safe_rect": game.hud.combat_safe_rect()}))


func _portable(value: Variant) -> Variant:
	if value is Vector2: return [value.x, value.y]
	if value is Rect2: return {"position": _portable(value.position), "size": _portable(value.size)}
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _portable(value[key])
		return result
	if value is Array:
		var result: Array = []
		for child: Variant in value: result.append(_portable(child))
		return result
	return super._encode(value)


func _source_guard() -> bool:
	if not _expect(source_hashes.size() == 21, "exact bounded source guard map required"): return false
	for path: String in source_hashes:
		if not _expect(FileAccess.get_sha256(path) == source_hashes[path], "frozen used source bytes: " + path): return false
	return true


func _focused() -> bool:
	if aborted or finishing: return false
	if root.has_focus() and DisplayServer.window_is_focused(root.get_window_id()): return true
	_expect(false, "genuine native focus loss cancels; no foreground request/resume"); aborted = true; _finish.call_deferred(); return false


func _startup_focus() -> bool:
	var deadline: int = Time.get_ticks_msec() + 4000
	var stable_ms: int = -1
	while Time.get_ticks_msec() < deadline and not finishing and not aborted:
		if root.has_focus() and DisplayServer.window_is_focused(root.get_window_id()):
			if stable_ms < 0: stable_ms = Time.get_ticks_msec()
			if Time.get_ticks_msec() - stable_ms >= 200: return true
		else: stable_ms = -1
		await process_frame
	return _expect(false, "genuine startup focus stable200ms required")


func _record_focus(label: String) -> void:
	if focus_rows.size() < 128: focus_rows.append({"label": label, "wall_usec": Time.get_ticks_usec(), "native_focus": DisplayServer.window_is_focused(root.get_window_id()), "paused": paused})
	if focus_armed and not finishing and not aborted and label in ["application-focus-out", "application-paused", "window-focus-exited"]:
		_expect(false, "actual focus notification cancels saved portrait"); aborted = true; _finish.call_deferred()


func _watchdog() -> void:
	if finishing: return
	var now: int = Time.get_ticks_msec()
	if now - started_ms > WholeMs or (view_deadline_ms > 0 and now > view_deadline_ms):
		_expect(false, "bounded paused portrait watchdog"); aborted = true; _finish.call_deferred()


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true; _restore_menu()
	await process_frame # Unwind any emitting observer before normal free.
	_end_watch("normal saved portrait cleanup")
	if is_instance_valid(game) and not candidate.is_empty(): game._dispose(candidate); candidate = {}
	var refs: Array[WeakRef] = []
	for shell: CinderCampaignShell in [fresh, game]:
		if is_instance_valid(shell): refs.append_array(_refs(shell)); shell.free()
	fresh = null; game = null
	if is_instance_valid(probe): refs.append_array(_refs(probe)); probe.free()
	if is_instance_valid(focus_observer): refs.append(weakref(focus_observer)); focus_observer.free()
	paused = false
	await create_timer(0.5, true).timeout; await process_frame
	_expect(_freed(refs) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal Shell/native-source/cue/observer cleanup releases descendants")
	_expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH) == registry_bytes, "canonical registry unchanged")
	if not source_hashes.is_empty(): _source_guard()
	var report: String = "res://.cinder/a1-l5-saved-portrait-%d.json" % Time.get_ticks_usec()
	var file := FileAccess.open(report, FileAccess.WRITE)
	if file == null: _expect(false, "saved portrait report writable")
	else:
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "first_failure": first_failure, "source_report_sha256": SourceReportSha, "packet_bundle_sha256": PacketSha, "captures": shots, "focus_events": focus_rows, "setups": setups, "observations": observations, "wall_ms": Time.get_ticks_msec() - started_ms, "scope": "Four genuine119 units restored through actual fresh Shell GUI Continue and isolated TEST prefix/store. Paused-world portrait inspection; only menu hidden for PNG, full exact native/physical/camera/input/UI preservation. No fight replay, private state/HP/sample/clock/camera write, forced focus/resume/audio masking or new gameplay/gesture/route/balance/acceptance credit. Actual PNG personal optical review remains required."}, "\t")); file.close()
	var directory := DirAccess.open(test_root)
	if directory != null:
		for name: String in directory.get_files(): DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio) # Inherited normal restoration; no mute.
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L5 SAVED PORTRAIT: %d checks/%d failures; %d actual paused views; report=%s" % [checks, failures, shots.size(), report])
	quit(1 if failures > 0 else 0)
