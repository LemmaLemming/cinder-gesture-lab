extends "res://tests/acts/act3/mirror_sea_route_smoke.gd"
## TEST ONLY single-host native arrival draw sampler; focused visual evidence.
## Actual route setup, current Main/World/Camera/HUD and untouched source-free
## arrival. No entries, combat, second Main, restore, policy override or fake draw.

const ArrivalRouteSha: String = "1a8ab67e7fd6185ad5069aa8476bb20fa0900bef3a85968c7fb014588ac316f1"
const ArrivalPhysicalSize: Vector2i = Vector2i(340, 736)
const ArrivalLogicalSize: Vector2i = Vector2i(540, 1170)
const ArrivalRasterSize: Vector2i = Vector2i(339, 736)
const ArrivalWaitSeconds: float = 8.0
const ArrivalOutput: String = "res://.cinder/mirror-sea-arrival-draw-gate-candidate"


class ArrivalBoundaryWait extends Node:
	signal settled(result: Dictionary)
	var _boundary: Signal
	var _timer: SceneTreeTimer
	var _finished: bool = false
	var _started_ms: int = 0
	var _process_start: int = 0
	var _physics_start: int = 0
	var _kind: String = ""

	func begin(kind: String, seconds: float) -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		_kind = kind
		_started_ms = Time.get_ticks_msec()
		_process_start = Engine.get_process_frames()
		_physics_start = Engine.get_physics_frames()
		_boundary = RenderingServer.frame_post_draw if kind == "draw" else get_tree().process_frame
		_boundary.connect(_on_boundary, CONNECT_ONE_SHOT)
		_timer = get_tree().create_timer(seconds, true, false, true)
		_timer.timeout.connect(_on_timeout, CONNECT_ONE_SHOT)

	func _on_boundary() -> void:
		_finish(true)

	func _on_timeout() -> void:
		_finish(false)

	func _finish(observed: bool) -> void:
		if _finished: return
		_finished = true
		_disconnect()
		settled.emit({"observed": observed, "kind": _kind, "elapsed_monotonic_wall_ms": Time.get_ticks_msec() - _started_ms, "process_start": _process_start, "process_end": Engine.get_process_frames(), "physics_start": _physics_start, "physics_end": Engine.get_physics_frames()})

	func _disconnect() -> void:
		if not _boundary.is_null() and _boundary.is_connected(_on_boundary): _boundary.disconnect(_on_boundary)
		if is_instance_valid(_timer) and _timer.timeout.is_connected(_on_timeout): _timer.timeout.disconnect(_on_timeout)
		_timer = null

	func _exit_tree() -> void:
		_disconnect()


class ArrivalPauseObserver extends Node:
	var observe: Callable

	func _notification(what: int) -> void:
		if observe.is_valid() and what in [NOTIFICATION_PAUSED, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_IN]:
			observe.call(what, get_stack().slice(0, 12))


var _arrival_observer: ArrivalPauseObserver
var _arrival_refs: Array[WeakRef] = []
var _arrival_wait_result: Dictionary = {}
var _arrival_wait_receipts: Array[Dictionary] = []
var _arrival_pause_receipts: Array[Dictionary] = []
var _arrival_focus_receipts: Array[Dictionary] = []
var _arrival_ordinary_started: bool = false
var _arrival_test_pause: bool = false
var _arrival_unexpected_pause: bool = false
var _arrival_png_written: bool = false
var _arrival_draw_observations: int = 0


func _run() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var reason: String = "" if arguments.is_empty() or (arguments.size() == 1 and arguments[0] == "--arrival-only") else "unsupported selector; capture autorun flags are not permitted: " + str(arguments)
	if reason.is_empty() and DisplayServer.get_name() == "headless": reason = "actual native arrival sampler requires Root's queued graphical renderer"
	if reason.is_empty() and FileAccess.get_sha256("res://tests/acts/act3/mirror_sea_route_smoke.gd") != ArrivalRouteSha: reason = "actual route1a8 changed; review this ignored extension before publication"
	if reason.is_empty(): reason = await _open()
	if _expect(reason.is_empty(), "one actual paused Main retains original source-free Mirror Sea arrival", reason):
		reason = await _arrival_focus()
		if _expect(reason.is_empty(), "one native focus request earns two actual focus frames without changing the paused native unit", reason):
			reason = await _arrival_draw()
			_expect(reason.is_empty(), "one original native arrival PNG follows actual draw and exact paused unit/current Camera/HUD", reason)
	if not reason.is_empty(): print("FIRST MEANINGFUL ARRIVAL DRAW FAILURE; no later route/second Main attempted: ", reason, "; ", _arrival_diagnostics("failure"))
	await _close_route()
	var freed: bool = true
	for ref: WeakRef in _arrival_refs: freed = freed and ref.get_ref() == null
	_expect(freed, "arrival observational nodes free with the actual parent world")
	print("Mirror Sea arrival draw sampler: %d checks; failures: %d; png_written=%s. Single actual Main/source-free arrival only; no combat/restore/disk/full portrait or human acceptance." % [_checks, _failures, str(_arrival_png_written)])
	quit(0 if _failures == 0 else 1)


func _arrival_focus() -> String:
	print("ARRIVAL PRE-FOCUS: ", _arrival_diagnostics("preFocus"))
	var error: String = _arrival_window_error()
	if error.is_empty(): error = _arrival_state_error()
	if not error.is_empty() or not paused: return "paused native focus precondition refused: " + error
	_arrival_observer = ArrivalPauseObserver.new()
	_arrival_observer.name = "TestOnlyArrivalNativePauseObserver"
	_arrival_observer.process_mode = Node.PROCESS_MODE_PAUSABLE
	_arrival_observer.observe = _arrival_notification
	_game.add_child(_arrival_observer)
	_arrival_refs.append(weakref(_arrival_observer))
	root.focus_entered.connect(_arrival_focus_signal.bind("entered"))
	root.focus_exited.connect(_arrival_focus_signal.bind("exited"))
	var before: Dictionary = _arrival_observation(false)
	if before.hero.is_empty() or before.scheduler.is_empty(): return "paused native Hero/Scheduler capture refused before focus request"
	root.grab_focus() # One genuine setup request; no later focus keeper.
	var stable: int = 0
	for index: int in range(60):
		if not await _arrival_wait("process", "focus-frame-%d" % (index + 1)): return "native focus process boundary was not observed"
		if not paused or not _exact(before, _arrival_observation(false)):
			return "actual focus settlement changed paused native arrival/clocks/resources/current Camera/HUD"
		stable = stable + 1 if root.has_focus() and DisplayServer.window_is_focused(root.get_window_id()) else 0
		if stable >= 2:
			print("ARRIVAL FOCUS EARNED: ", _arrival_diagnostics("two-real-focus-frames"))
			return ""
	print("ARRIVAL FOCUS REFUSAL: ", _arrival_diagnostics("focus-refusal"))
	return "one native foreground request did not earn actual Window/DisplayServer focus on two process frames"


func _arrival_draw() -> String:
	var before: Dictionary = _arrival_history()
	_arrival_ordinary_started = true
	_game.call("resume_lab")
	if paused: return "actual public resume refused; preserve native pause"
	if not await _arrival_wait("draw", "ordinary-before-TEST-pause"):
		return "ordinary native frame_post_draw was not observed; main-loop-alive timeout is not an art pass"
	if paused or _arrival_unexpected_pause:
		return "real focus/application pause occurred before TEST capture; preserve pause and write no PNG"
	var error: String = _arrival_window_error()
	if error.is_empty(): error = _arrival_state_error()
	if error.is_empty() and not _exact(before, _arrival_history()): error = "ordinary draw changed genuine arrival resources/actions/events/kit or aim anchor"
	if not error.is_empty(): return error
	_arrival_test_pause = true
	paused = true # TEST ONLY after the first real ordinary draw.
	var frozen: Dictionary = _arrival_observation(true)
	error = _arrival_pair_error(frozen)
	if error.is_empty(): error = _arrival_hud_error()
	var union: Dictionary = _level.call("mirror_sea_codec_framing_union") if error.is_empty() else {}
	if error.is_empty(): error = String(union.get("error", "complete actual arrival bounds required"))
	if error.is_empty(): error = String(_game.call("camera_framing_error", union.points))
	if not error.is_empty(): return error
	if not await _arrival_wait("process", "TEST-paused-process"): return "paused process boundary unobserved; no PNG"
	if not await _arrival_wait("draw", "TEST-paused-draw"): return "paused native draw boundary unobserved; no PNG"
	var later: Dictionary = _arrival_observation(true)
	var later_union: Dictionary = _level.call("mirror_sea_codec_framing_union")
	error = _arrival_pair_error(later)
	if error.is_empty() and (not _exact(frozen, later) or not _exact(union, later_union)): error = "native pair/resources/actions/events/poses/current Camera/HUD changed across actual paused draw"
	if error.is_empty(): error = _arrival_state_error()
	if error.is_empty(): error = _arrival_window_error()
	if error.is_empty(): error = _arrival_hud_error()
	if error.is_empty() and (not paused or not root.has_focus() or not DisplayServer.window_is_focused(root.get_window_id()) or not DisplayServer.window_can_draw(root.get_window_id()) or not RenderingServer.is_render_loop_enabled()): error = "actual paused focused visible native draw policy no longer holds; no PNG"
	var image: Image = root.get_texture().get_image() if error.is_empty() else null
	if error.is_empty() and (image == null or image.is_empty() or image.get_size() != ArrivalRasterSize): error = "actual original root raster must be339x736; observed " + str(image.get_size() if image != null else Vector2i.ZERO)
	if not error.is_empty(): return error
	var directory: String = ProjectSettings.globalize_path(ArrivalOutput)
	var path: String = directory.path_join("arrival.png")
	var native_path: String = directory.path_join("arrival.native")
	if FileAccess.file_exists(path) or FileAccess.file_exists(native_path): return "preserve original evidence; output already exists: " + path
	if DirAccess.make_dir_recursive_absolute(directory) != OK: return "cannot create owned original arrival evidence directory"
	var receipt: FileAccess = FileAccess.open(native_path, FileAccess.WRITE)
	if receipt == null: return "cannot write exact native arrival receipt"
	receipt.store_buffer(var_to_bytes({"route_sha256": ArrivalRouteSha, "native_observation": frozen, "required_union": union, "waits": _arrival_wait_receipts, "native_pauses": _arrival_pause_receipts, "native_focus_signals": _arrival_focus_receipts, "actual_policy": _arrival_diagnostics("PNG-boundary"), "scope": "single-host source-free actual arrival; no full-parent art acceptance"}))
	receipt.close()
	if image.save_png(path) != OK: return "cannot save original native arrival PNG"
	_arrival_png_written = true
	print("ACTUAL ARRIVAL PNG: ", path, " native_size=", image.get_size(), " clock_s=", _scheduler.get_clock(), " ordinary_draw_then_TEST_pause=true; native pair/current Camera/HUD exact across paused draw; no full route/art acceptance")
	return ""


func _arrival_wait(kind: String, site: String) -> bool:
	var waiter := ArrivalBoundaryWait.new()
	waiter.name = "TestOnlyArrivalDrawBoundary"
	root.add_child(waiter)
	_arrival_refs.append(weakref(waiter))
	var before: Dictionary = _arrival_diagnostics(site + ":START")
	print("ARRIVAL ACTUAL WAIT START: ", {"kind": kind, "native_process_seconds": ArrivalWaitSeconds, "actual": before})
	waiter.begin(kind, ArrivalWaitSeconds)
	var result: Dictionary = await waiter.settled
	if kind == "draw" and result.observed: _arrival_draw_observations += 1
	_arrival_wait_result = {"site": site, "result": result, "before": before, "after": _arrival_diagnostics(site + (":OBSERVED" if result.observed else ":TIMEOUT")), "png_written": _arrival_png_written}
	_arrival_wait_receipts.append(_arrival_wait_result.duplicate(true))
	print("ARRIVAL ACTUAL WAIT OBSERVED: " if result.observed else "ARRIVAL ACTUAL WAIT TIMEOUT: ", _arrival_wait_result)
	if waiter.get_parent() == root: root.remove_child(waiter)
	waiter.queue_free()
	return result.observed


func _arrival_window_error() -> String:
	var window_id: int = root.get_window_id()
	if window_id != DisplayServer.MAIN_WINDOW_ID or DisplayServer.window_get_attached_instance_id(window_id) != root.get_instance_id() or root.size != ArrivalPhysicalSize or DisplayServer.window_get_size(window_id) != ArrivalPhysicalSize or root.get_visible_rect() != Rect2(Vector2.ZERO, Vector2(ArrivalLogicalSize)) or root.content_scale_size != ArrivalLogicalSize or root.content_scale_mode != Window.CONTENT_SCALE_MODE_CANVAS_ITEMS or root.content_scale_aspect != Window.CONTENT_SCALE_ASPECT_KEEP or root.content_scale_factor != 1.0 or not root.visible:
		return "unchanged physical340x736/logical540x1170 KEEP canvas_items/native Window policy required"
	return ""


func _arrival_state_error() -> String:
	var world: Node3D = _game.get("world") as Node3D
	var camera: Camera3D = _game.get("camera") as Camera3D
	var hud: GameHUD = _game.get("hud") as GameHUD
	if world == null or camera == null or hud == null or _game.get("active_level") != _level or _game.get("player") != _hero or _level.hero != _hero or _level.shared_shell != _game or _level.get_parent() != world or _hero.get_parent() != world or camera.get_parent() != world or camera.get_viewport().get_camera_3d() != camera or camera.get_world_3d() != _hero.get_world_3d(): return "actual original Main/World/Hero/current Camera/HUD bindings required"
	var error: String = String(_level.call("runtime_error"))
	if not error.is_empty(): return error
	var state: Dictionary = _level.call("state")
	if not state.route.entries.is_empty() or not state.route.deaths.is_empty() or not state.route.pending_checkpoint_boundaries.is_empty() or state.ring.installed or state.completed or state.exit_state != "clear" or not state.contact.is_empty() or not (_level.get("sources") as Dictionary).is_empty() or is_instance_valid(_level.get("mechanism")) or not _scheduler.reservations().is_empty() or not get_nodes_in_group("enemies").is_empty() or not get_nodes_in_group("required_cues").is_empty(): return "single-host arrival earned future entries/sources/pulses/leases/contact"
	if _hero.dead or _hero.hp != _hero_hp or _hero.shells != _shells or not _exact(_hero.equipment.snapshot(), _kit) or not _exact(_hero.equipment.resolved_stats(), _stats) or not _hero.get_world_action_records().is_empty() or not _actions.is_empty() or not _events.is_empty() or _hero.get_world_action_clock() != _scheduler.get_clock(): return "actual arrival actions/resources/events/kit or paired native clocks differ"
	for id: String in state.sources:
		if state.sources[id].installed: return "future native source installed before actual entry: " + id
	return ""


func _arrival_history() -> Dictionary:
	return {"resources": [_hero.hp, _hero.max_hp, _hero.shells, _hero.max_shells], "kit": _hero.equipment.snapshot(), "stats": _hero.equipment.resolved_stats(), "actions": _hero.get_world_action_records(), "observed_actions": _actions.duplicate(true), "events": _events.duplicate(true), "anchor": _game.call("get_aim_anchor_normalized")}


func _arrival_observation(whole: bool) -> Dictionary:
	var camera: Camera3D = _game.get("camera") as Camera3D
	var player: Dictionary = _hero.snapshot_state()
	var scheduler: Dictionary = _scheduler.snapshot_state(_level.call("scheduler_bindings"))
	var local: Dictionary = _level.snapshot_state() if whole else {}
	return {"hero": player, "scheduler": scheduler, "level": local, "level_state": _level.call("state"), "history": _arrival_history(), "hero_pose": [_hero.global_transform, _hero.velocity], "camera": [camera.get_instance_id(), camera.global_transform, camera.projection, camera.size, camera.keep_aspect, camera.h_offset, camera.v_offset, camera.near, camera.far, camera.cull_mask, camera.get_viewport().get_camera_3d() == camera], "input": _game.call("get_input_observation_state"), "level_render": _arrival_node_state(_level), "hero_render": _arrival_node_state(_hero), "hud": _arrival_node_state(_game.get("hud") as Node), "bench": _arrival_node_state(_game.get("bench") as Node), "window_policy": [root.size, root.get_visible_rect(), root.content_scale_size, root.content_scale_mode, root.content_scale_aspect, root.content_scale_factor]}


func _arrival_pair_error(value: Dictionary) -> String:
	if not paused or value.hero.is_empty() or value.scheduler.is_empty() or value.level.is_empty(): return "complete actual paused native Hero/Scheduler/level pair refused: " + _hero.last_snapshot_error + "; " + _scheduler.last_snapshot_error + "; " + _level.last_snapshot_error
	var error: String = _hero.snapshot_error(value.hero)
	if error.is_empty(): error = _level.snapshot_error_with_player(value.level, value.hero)
	if error.is_empty() and not _exact(value.scheduler, value.level.local.scheduler): error = "independent public Scheduler packet differs from complete local pair"
	return error


func _arrival_hud_error() -> String:
	var hud: GameHUD = _game.get("hud") as GameHUD
	var bench: CanvasLayer = _game.get("bench") as CanvasLayer
	var labels: Array[String] = _arrival_labels(hud)
	if hud == null or not hud.visible or bench == null or bench.visible or not labels.has("HP  %d / %d" % [int(ceil(_hero.hp)), int(ceil(_hero.max_hp))]) or not labels.has("SHELLS  %d / %d" % [_hero.shells, _hero.max_shells]) or not labels.has(_level.objective_text.to_upper()) or labels.has("PAUSED") or labels.has("LEVEL PREVIEW"): return "normal actual HUD must show current full HP/ammo/level objective with no pause overlay: " + str(labels)
	return ""


func _arrival_labels(node: Node) -> Array[String]:
	var labels: Array[String] = []
	if not is_instance_valid(node): return labels
	if node is Label and (node as Label).is_visible_in_tree(): labels.append((node as Label).text)
	for child: Node in node.get_children(): labels.append_array(_arrival_labels(child))
	return labels


func _arrival_notification(what: int, stack: Array) -> void:
	if _arrival_ordinary_started and not _arrival_test_pause and paused: _arrival_unexpected_pause = true
	var value: Dictionary = {"notification": what, "test_pause_requested": _arrival_test_pause, "ordinary_started": _arrival_ordinary_started, "actual": _arrival_diagnostics("native-notification"), "stack_first12": stack}
	_arrival_pause_receipts.append(value)
	print("ARRIVAL NATIVE PAUSE/FOCUS NOTIFICATION: ", value)


func _arrival_focus_signal(kind: String) -> void:
	var value: Dictionary = _arrival_diagnostics("native-focus-" + kind)
	_arrival_focus_receipts.append(value)
	print("ARRIVAL NATIVE FOCUS SIGNAL: ", value)


func _arrival_diagnostics(site: String) -> Dictionary:
	var game_valid: bool = is_instance_valid(_game) and _game.is_inside_tree()
	var texture: Texture2D = root.get_texture()
	var hud: Node = _game.get("hud") as Node if game_valid else null
	return {"site": site, "wall_ticks_ms": Time.get_ticks_msec(), "wait_limit": ArrivalWaitSeconds, "wait_limit_unit": "unscaled_native_process_seconds", "physics_frames": Engine.get_physics_frames(), "process_frames": Engine.get_process_frames(), "frames_drawn": Engine.get_frames_drawn(), "frame_post_draw_observations": _arrival_draw_observations, "render_loop_enabled": RenderingServer.is_render_loop_enabled(), "render_server_has_changed": RenderingServer.has_changed(), "rendering_driver": RenderingServer.get_current_rendering_driver_name(), "rendering_method": RenderingServer.get_current_rendering_method(), "low_processor_usage_mode": OS.is_in_low_processor_usage_mode(), "has_additional_outputs": DisplayServer.has_additional_outputs(), "window_can_draw": DisplayServer.window_can_draw(root.get_window_id()), "window_id": root.get_window_id(), "window_mode": root.mode, "window_visible": root.visible, "window_has_focus": root.has_focus(), "display_window_focused": DisplayServer.window_is_focused(root.get_window_id()), "window_size": root.size, "display_window_size": DisplayServer.window_get_size(root.get_window_id()), "display_attached_instance_id": DisplayServer.window_get_attached_instance_id(root.get_window_id()), "logical_visible_rect": root.get_visible_rect(), "texture_size": texture.get_size() if is_instance_valid(texture) else null, "content_scale_size": root.content_scale_size, "content_scale_mode": root.content_scale_mode, "content_scale_aspect": root.content_scale_aspect, "content_scale_factor": root.content_scale_factor, "window_flags": {"unresizable": root.unresizable, "borderless": root.borderless, "always_on_top": root.always_on_top, "transparent": root.transparent, "unfocusable": root.unfocusable, "popup_window": root.popup_window, "exclude_from_capture": root.exclude_from_capture}, "tree_paused": paused, "public_pause_pending": _game.call("is_pause_requested") if game_valid else null, "game_can_process": _game.can_process() if game_valid else null, "hud_can_process": hud.can_process() if is_instance_valid(hud) else null, "hero_hp": _hero.hp if is_instance_valid(_hero) else null, "hero_clock_s": _hero.get_world_action_clock() if is_instance_valid(_hero) else null, "scheduler_clock_s": _scheduler.get_clock() if is_instance_valid(_scheduler) else null, "parent_state": _level.call("state") if is_instance_valid(_level) and _level.is_inside_tree() else {}, "input": _game.call("get_input_observation_state") if game_valid else {}}


func _arrival_node_state(node: Node) -> Dictionary:
	if not is_instance_valid(node): return {"missing": true}
	var value: Dictionary = {"id": node.get_instance_id(), "name": String(node.name), "children": []}
	if node is Node3D: value.pose = [(node as Node3D).transform, (node as Node3D).global_transform, (node as Node3D).visible]
	if node is CanvasLayer: value.visible = (node as CanvasLayer).visible
	elif node is CanvasItem: value.visible = (node as CanvasItem).visible
	if node is Control: value.rect = (node as Control).get_global_rect()
	if node is Label: value.text = (node as Label).text
	if node is Button: value.text = (node as Button).text
	if node is MeshInstance3D:
		var mesh: MeshInstance3D = node as MeshInstance3D
		var surfaces: Array = []
		if mesh.mesh != null:
			for index: int in range(mesh.mesh.get_surface_count()): surfaces.append([mesh.mesh.surface_get_arrays(index), _arrival_resource_stamp(mesh.mesh.surface_get_material(index)), _arrival_resource_stamp(mesh.get_surface_override_material(index))])
		value.mesh = [mesh.mesh.get_instance_id() if mesh.mesh != null else 0, mesh.mesh.get_aabb() if mesh.mesh != null else AABB(), var_to_bytes(surfaces), _arrival_resource_stamp(mesh.material_override), _arrival_resource_stamp(mesh.material_overlay), mesh.cast_shadow]
	if node is Sprite3D:
		var sprite: Sprite3D = node as Sprite3D
		value.sprite = [sprite.get_item_rect(), sprite.offset, sprite.pixel_size, sprite.axis, sprite.billboard, sprite.alpha_cut, sprite.alpha_scissor_threshold, sprite.no_depth_test, sprite.texture_filter, sprite.modulate, sprite.centered, sprite.flip_h, sprite.flip_v, sprite.fixed_size, sprite.region_enabled, sprite.region_rect, sprite.hframes, sprite.vframes, sprite.frame, sprite.cast_shadow, _arrival_resource_stamp(sprite.texture)]
	for child: Node in node.get_children(): value.children.append(_arrival_node_state(child))
	return value


func _arrival_resource_stamp(resource: Resource) -> PackedByteArray:
	if resource == null: return PackedByteArray()
	var values: Array = [resource.get_instance_id(), resource.get_class(), resource.resource_path]
	for info: Dictionary in resource.get_property_list():
		if (int(info.usage) & PROPERTY_USAGE_STORAGE) == 0: continue
		var value: Variant = resource.get(String(info.name))
		if value is Image:
			var image: Image = value as Image
			value = [image.get_size(), image.get_format(), image.has_mipmaps(), image.get_data()]
		elif value is Object: value = [value.get_instance_id(), value.get_class()] if is_instance_valid(value) else null
		values.append([String(info.name), value])
	return var_to_bytes(values)


func _close_route() -> void:
	if root.focus_entered.is_connected(_arrival_focus_signal.bind("entered")): root.focus_entered.disconnect(_arrival_focus_signal.bind("entered"))
	if root.focus_exited.is_connected(_arrival_focus_signal.bind("exited")): root.focus_exited.disconnect(_arrival_focus_signal.bind("exited"))
	if is_instance_valid(_arrival_observer): _arrival_observer.observe = Callable()
	await super._close_route() # Root4af public exit retires any genuine owner insideTree.
	_arrival_observer = null
