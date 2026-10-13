extends "res://tests/act1_l2_challenge_admission_smoke.gd"
## One actual Challenge starter component, with a brief native
## paused B-first portrait. Same native setup/transport helpers as admission.
## TEST ONLY Pause-menu concealment for image, immediately restored. No focus,
## draw policy, simulation, renderer, camera, actor or required-cue override.
## Requires the separate test-only _inspect_first_prefix(saved)->bool hook.

var _portrait_events: Array[String] = []
var _portrait_connections: Array[Dictionary] = []
var _portrait_receipts: Array[Dictionary] = []
var _portrait_waiting: bool = false


func _initialize() -> void:
	var identity: String = "%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_test_root = "user://test-act1-l2-challenge-portrait-%s/" % identity
	_capture_root = "res://.cinder/captures/act1-l2-challenge-%s/" % identity
	for argument: String in OS.get_cmdline_user_args(): _option_error = "Unsupported selector: " + argument
	node_added.connect(_observe_restore_node)
	create_timer(100.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "one native portrait component finishes within100wall seconds; no timeout cleanup credit")
			quit(1))
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if not _expect(_option_error.is_empty() and DisplayServer.get_name() != "headless", "brief portrait requires actual graphical renderer and no policy selectors"): _finish(); return
	_registry_text = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var registry := Registry.new()
	if not _expect(registry.last_error.is_empty() and registry.is_playable("A1-L2") and registry.entry("A1-L2").scene_path == LEVEL_PATH, "native portrait uses actual canonical A1-L2"): _finish(); return
	_cleanup_saves()
	if not await _component_case(registry, INITIAL_CASES[1]): _finish(); return
	_expect(_portrait_receipts.size() == 1 and FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_text, "one real B-first image and unchanged registry, no full-route or native-focus claim")
	print("ACTUAL CHALLENGE PORTRAIT RECEIPTS ", Exact.stringify(_portrait_receipts))
	_finish()


func _inspect_first_prefix(saved: Dictionary) -> bool:
	if not _expect(paused and game.menu.page_name() == "pause" and game.menu.visible and saved.level.local.scheduler.profile.id == "challenge" and _first_finale_id == "finale-impact-b" and saved.level.local.sequence.next_index == 1 and saved.level.local.circles["finale-impact-b"].status == "running", "portrait source is the actual paused B-first native prefix"): return false
	var wire: String = Exact.stringify(saved)
	var before: String = Exact.stringify(game.capture_campaign_snapshot())
	var native_before: String = _capture_native_wire()
	var model_before: String = Exact.stringify(game.attempts.state())
	var disk_before: String = FileAccess.get_file_as_string(_test_root + "campaign.json")
	print("PORTRAIT CAPTURE OPERANDS ", {"wire_nonempty": not wire.is_empty(), "snapshot_equal": before == wire, "native_nonempty": not native_before.is_empty(), "framing_error": game.camera_framing_error(game.active_level.camera_framing_points()), "root_size": root.size, "root_visible_size": root.get_visible_rect().size, "content_scale_size": root.content_scale_size, "world_size": game.camera.get_viewport().size})
	if not _expect(not wire.is_empty() and before == wire and not native_before.is_empty() and game.camera_framing_error(game.active_level.camera_framing_points()).is_empty() and root.size == Vector2i(540,1170) and game.camera.get_viewport().size == Vector2i(270,585), "exact current full union/HUD/native camera uses540x1170 over270x585 raster"): return false
	_portrait_events.clear(); _connect_portrait_events()
	var page_before: String = game.menu.page_name()
	var visible_before: bool = game.menu.visible
	# Sole TEST presentation write. The actual world, HUD and required cues keep
	# their native policy/transforms/resources; physics remains genuinely paused.
	game.menu.visible = false
	_portrait_waiting = true
	create_timer(8.0, true).timeout.connect(func() -> void:
		if _portrait_waiting and not _finished:
			print("PORTRAIT DRAW WAIT TIMEOUT: paused=", paused, " native_focus=", root.has_focus(), " renderer=", DisplayServer.get_name())
			_expect(false, "native frame_post_draw absent within8wall seconds; no forced draw/focus/resume or image credit")
			quit(1))
	await RenderingServer.frame_post_draw
	_portrait_waiting = false
	var image: Image = root.get_texture().get_image()
	var absolute: String = ProjectSettings.globalize_path(_capture_root + "01-challenge-finale-b-first-native-paused.png")
	var directory_ok: bool = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_root)) == OK
	var image_ok: bool = image != null and image.get_size() == Vector2i(540,1170) and directory_ok and image.save_png(absolute) == OK
	# Restore exactly the same overlay visibility; no page reconstruction or
	# new gameplay observer/Resume/refresh is invoked for this visual step.
	game.menu.visible = visible_before
	var after: String = Exact.stringify(game.capture_campaign_snapshot())
	var native_after: String = _capture_native_wire()
	_disconnect_portrait_events()
	if not _expect(image_ok and FileAccess.get_sha256(absolute).length() == 64, "actual rendered540x1170 viewport saved at absolute path: " + absolute): return false
	if not _expect(paused and game.menu.visible == visible_before and game.menu.page_name() == page_before and not after.is_empty() and after == before and not native_after.is_empty() and native_after == native_before and Exact.stringify(game.attempts.state()) == model_before and FileAccess.get_file_as_string(_test_root + "campaign.json") == disk_before and _portrait_events.is_empty(), "temporary Pause concealment restores overlay and preserves exact complete native unit/resources/world/HUD/camera/model/disk with zero observed gameplay/phase callbacks"): return false
	var receipt: Dictionary = {"path": absolute, "sha256": FileAccess.get_sha256(absolute), "bytes": FileAccess.get_file_as_bytes(absolute).size(), "size": [540,1170], "world_raster": [270,585], "profile": "challenge", "first_native_companion": "finale-impact-b", "phase": saved.level.local.circles["finale-impact-b"].phase, "clock_s": saved.level.local.scheduler.clock_s, "snapshot_sha256": wire.sha256_text(), "native_signature_sha256": native_before.sha256_text(), "test_pause_overlay_hidden_then_restored": true, "observed_gameplay_phase_callbacks": _portrait_events.size(), "native_window_focus_observed": root.has_focus(), "scope": "actual rendered view after frame_post_draw; TEST approach+zeroammo; no full route/finale defeat/balance/native-human claim"}
	_portrait_receipts.append(receipt)
	var report: FileAccess = FileAccess.open(_capture_root + "portrait-receipt.exact.json", FileAccess.WRITE)
	if not _expect(report != null, "native portrait evidence receipt is writable"): return false
	report.store_string(Exact.stringify(receipt)); report.close()
	return true


func _connect_portrait_events() -> void:
	for source: Act1RushSelenite in (game.active_level.get("sources") as Dictionary).values():
		_portrait_connect(source, "state_changed", func(_state: Dictionary) -> void: _portrait_events.append("C30.state"))
		_portrait_connect(source.get_cue(), "state_changed", func(_state: Dictionary) -> void: _portrait_events.append("C30.cue"))
	for circle: CinderLaneMechanism in (game.active_level.get("circles") as Dictionary).values():
		_portrait_connect(circle, "state_changed", func(_state: Dictionary) -> void: _portrait_events.append("circle.state"))
		_portrait_connect(circle.get_cue(), "state_changed", func(_state: Dictionary) -> void: _portrait_events.append("circle.cue"))
		_portrait_connect(circle, "hit_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: _portrait_events.append("circle.hit"))
	_portrait_connect(game.player, "world_action_executed", func(_record: Dictionary) -> void: _portrait_events.append("Player.action"))
	_portrait_connect(game.player, "fired", func(_kind: String) -> void: _portrait_events.append("Player.fired"))
	_portrait_connect(game.player, "died", func() -> void: _portrait_events.append("Player.died"))
	_portrait_connect(game.player, "equipment_changed", func(_id: String) -> void: _portrait_events.append("Player.equipment"))
	_portrait_connect(game.active_level, "checkpoint_requested", func(_id: String, _checkpoint: String, _kind: String) -> void: _portrait_events.append("Level.checkpoint"))
	_portrait_connect(game.active_level, "completion_requested", func(_id: String, _completion: String) -> void: _portrait_events.append("Level.complete"))
	_portrait_connect(game.active_level, "contact_exit_requested", func(_id: String, _exit: String) -> void: _portrait_events.append("Level.exit"))
	_portrait_connect(game.active_level.get("scheduler"), "reservation_invalidated", func(_id: String, _reason: String) -> void: _portrait_events.append("Scheduler.cancel"))


func _portrait_connect(node: Node, signal_name: String, callback: Callable) -> void:
	node.connect(signal_name, callback)
	_portrait_connections.append({"node": node, "signal": signal_name, "callback": callback})


func _disconnect_portrait_events() -> void:
	for connection: Dictionary in _portrait_connections:
		if is_instance_valid(connection.node) and connection.node.is_connected(connection.signal, connection.callback): connection.node.disconnect(connection.signal, connection.callback)
	_portrait_connections.clear()


func _capture_native_wire() -> String:
	var native: Array[Dictionary] = []
	_collect_native_nodes(game.world, native)
	var safe: Rect2 = game.hud.combat_safe_rect()
	# The public observation intentionally contains native vectors. Encode every
	# component without rounding before using the closed JSON-only comparer.
	var input: Dictionary = game.get_input_observation_state()
	var anchor: Vector2 = input.anchor_normalized
	input["anchor_normalized"] = [anchor.x, anchor.y]
	var last: Dictionary = input.last_observation
	if not last.is_empty():
		var screen: Vector2 = last.screen_position_normalized
		var last_anchor: Vector2 = last.anchor_normalized
		var direction: Vector3 = last.direction
		last["screen_position_normalized"] = [screen.x, screen.y]
		last["anchor_normalized"] = [last_anchor.x, last_anchor.y]
		last["direction"] = Codec.vector3(direction)
	return Exact.stringify({"nodes": native, "hud_visible": game.hud.visible, "hud_safe": [safe.position.x,safe.position.y,safe.size.x,safe.size.y], "input": input})


func _collect_native_nodes(parent: Node, output: Array[Dictionary]) -> void:
	if parent is Node3D:
		var node: Node3D = parent as Node3D
		var row: Dictionary = {"path": String(game.world.get_path_to(node)), "native_id": str(node.get_instance_id()), "script_id": str(node.get_script().get_instance_id()) if node.get_script() != null else "", "visible": node.visible, "origin": Codec.vector3(node.global_position), "basis": [Codec.vector3(node.global_basis.x),Codec.vector3(node.global_basis.y),Codec.vector3(node.global_basis.z)]}
		if node is MeshInstance3D:
			var mesh: MeshInstance3D = node as MeshInstance3D
			row["mesh_id"] = str(mesh.mesh.get_instance_id()) if mesh.mesh != null else ""
			row["override_id"] = str(mesh.material_override.get_instance_id()) if mesh.material_override != null else ""
			row["overlay_id"] = str(mesh.material_overlay.get_instance_id()) if mesh.material_overlay != null else ""
			var bounds: AABB = mesh.get_aabb()
			row["bounds"] = {"origin": Codec.vector3(bounds.position), "size": Codec.vector3(bounds.size)}
		elif node is Sprite3D:
			var sprite: Sprite3D = node as Sprite3D
			row["texture_id"] = str(sprite.texture.get_instance_id()) if sprite.texture != null else ""
			row["frame"] = sprite.frame
			row["pixel_size"] = sprite.pixel_size
		elif node is CollisionShape3D:
			var collision: CollisionShape3D = node as CollisionShape3D
			row["shape_id"] = str(collision.shape.get_instance_id()) if collision.shape != null else ""
			row["disabled"] = collision.disabled
		output.append(row)
	for child: Node in parent.get_children(): _collect_native_nodes(child, output)


func _finish() -> void:
	if _finished: return
	_finished = true; _portrait_waiting = false
	_disconnect_portrait_events()
	_close_shell(); paused = false; _cleanup_saves()
	print("Act1 L2 Challenge brief portrait: %d checks, %d failures; ONE actual starter B-first component; TEST Pause overlay hidden/restored for native PNG; no full-route/finale-defeat/balance/native-focus claim" % [checks, failures])
	quit(0 if failures == 0 else 1)
