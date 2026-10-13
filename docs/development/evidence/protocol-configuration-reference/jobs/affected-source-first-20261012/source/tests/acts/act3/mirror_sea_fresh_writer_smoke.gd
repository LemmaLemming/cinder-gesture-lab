extends "res://tests/acts/act3/mirror_sea_frontier_smoke.gd"
## TEST ONLY source-free arrival leaf for the complete Mirror Sea codec.
## Actual Main installs its actual parent/Hero/World/Camera; no host rebinding.
## A separate canonical native HUD mirrors Shared36's supplied receiver setup.
## No camera, actor, input, HP/ammo, clock, loadout or progression is written.
## Default and --arrival-only are identical: no combat, earned route, disk,
## ProductionShell flow, portrait pixels or campaign acceptance is claimed.

const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const HUDScript = preload("res://scripts/hud.gd")

var _receiver_viewport: SubViewport
var _receiver_hud: GameHUD
var _wrong_viewport: SubViewport
var _wrong_hud: GameHUD
var _receiver_refs: Array[WeakRef] = []
var _writer_pair: Dictionary = {}


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var reason: String = "" if args.is_empty() or (args.size() == 1 and args[0] == "--arrival-only") else "unsupported selector: " + str(args)
	if reason.is_empty(): reason = await _open()
	if _expect(reason.is_empty(), "actual paused Main installs empty clock0 Mirror Sea and original native bindings", reason):
		reason = _host_error()
		if reason.is_empty(): reason = _build_receiver_huds()
		if _expect(reason.is_empty(), "separate canonical native receiver HUDs retain actual integral outer pixels", reason):
			reason = _capture_actual_arrival()
			if _expect(reason.is_empty(), "supplied actual Camera/HUD writer captures a complete pure exact native arrival pair", reason):
				reason = _reject_optical_contexts()
				if _expect(reason.is_empty(), "missing Camera/HUD and wrong native HUD pixels reject without world/receiver mutation", reason):
					reason = _reject_bad_units()
					_expect(reason.is_empty(), "malformed whole arrival units reject through pure and restore paths atomically", reason)
	if not reason.is_empty():
		print("FIRST MEANINGFUL FRESH-WRITER FAILURE; later checks unattempted: ", reason, "; ", _diagnostic())
	_dispose_receiver_huds()
	await _close()
	var freed: bool = true
	for ref: WeakRef in _receiver_refs: freed = freed and ref.get_ref() == null
	_expect(freed, "temporary actual canonical receiver HUDs/viewports free without retained aliases")
	print("Ignored Mirror Sea fresh-writer arrival: %d checks; failures: %d. TEST ONLY actual Main leaf, no Shell/disk/combat/route/art acceptance." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _host_error() -> String:
	var world: Node3D = _game.get("world") as Node3D
	var camera: Camera3D = _game.get("camera") as Camera3D
	var hud: GameHUD = _game.get("hud") as GameHUD
	if world == null or camera == null or hud == null or _game.get("active_level") != _level or _game.get("player") != _hero or _level.hero != _hero or _level.shared_shell != _game or _level.effects != _game.get("fx") or _level.get_parent() != world or _hero.get_parent() != world or camera.get_parent() != world or _scheduler.get_parent() != _level:
		return "actual Main must retain its original installed level/Hero/effects/Scheduler/current Camera"
	if not paused or _level.is_restore_candidate() or _level.get_viewport() != camera.get_viewport() or _level.get_world_3d() != camera.get_world_3d() or camera.get_viewport().get_camera_3d() != camera or camera.get_script() != null or hud.get_script() != HUDScript:
		return "paused ordinary fresh entry must use the actual canonical current native camera/HUD"
	return ""


func _build_receiver_huds() -> String:
	var outer: GameHUD = _game.get("hud") as GameHUD
	var size: Vector2 = outer.get_viewport().get_visible_rect().size
	if not size.is_finite() or size.x < 1.0 or size.y < 1.0 or size.x > 16383.0 or size.y > 16384.0 or Vector2(Vector2i(size)) != size:
		return "actual outer HUD requires bounded integral pixels"
	_receiver_viewport = _hud_viewport(Vector2i(size), "TestOnlyFreshReceiverHUDViewport")
	_receiver_hud = _hud(_receiver_viewport, "TestOnlyFreshReceiverHUD")
	_wrong_viewport = _hud_viewport(Vector2i(size) + Vector2i(1, 0), "TestOnlyWrongPixelHUDViewport")
	_wrong_hud = _hud(_wrong_viewport, "TestOnlyWrongPixelHUD")
	for node: Node in [_receiver_viewport, _receiver_hud, _wrong_viewport, _wrong_hud]: _receiver_refs.append(weakref(node))
	if _receiver_hud == outer or _wrong_hud == outer or _game.get("hud") != outer or _receiver_hud.get_script() != HUDScript or _wrong_hud.get_script() != HUDScript or not _receiver_hud.is_node_ready() or not _wrong_hud.is_node_ready() or _receiver_hud.get_viewport().get_visible_rect().size != size or _wrong_hud.get_viewport().get_visible_rect().size == size:
		return "receiver construction replaced a Main alias or lacks distinct actual native pixel contexts"
	return ""


func _hud_viewport(size: Vector2i, label: String) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.name = label
	viewport.size = size
	viewport.disable_3d = true
	viewport.handle_input_locally = false
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	return viewport


func _hud(viewport: SubViewport, label: String) -> GameHUD:
	var hud: GameHUD = HUDScript.new()
	hud.name = label
	hud.visible = false
	viewport.add_child(hud)
	hud.set_campaign_mode()
	hud.hide_overlay()
	hud.update_status(_hero.hp, _hero.max_hp, _hero.shells, _hero.max_shells, 0, _level.objective_text)
	return hud


func _capture_actual_arrival() -> String:
	var camera: Camera3D = _game.get("camera") as Camera3D
	var union: Dictionary = _level.call("mirror_sea_codec_framing_union", camera)
	if not String(union.get("error", "Complete owned native union unavailable")).is_empty() or union.get("points", []).is_empty():
		return "actual arrival native union unavailable: " + String(union.get("error", ""))
	var error: String = String(_game.call("camera_framing_error_for_context", union.points, _hero, camera, _receiver_hud))
	if not error.is_empty(): return "actual current view must fit BEFORE explicit capture: " + error
	var before: Dictionary = _capture_observation()
	var player: Dictionary = _hero.snapshot_state()
	var local: Dictionary = _level.snapshot_state_for_presentation(camera, _receiver_hud)
	if player.is_empty() or local.is_empty(): return "explicit actual receiver writer refused: " + _hero.last_snapshot_error + "; " + _level.last_snapshot_error
	_writer_pair = {"hero": player, "level": local}
	error = _unit_error(_writer_pair)
	if error.is_empty(): error = _level.snapshot_error(local) # Independent base/whole check OUTSIDE writer.
	if not error.is_empty() or not _exact(before, _capture_observation()): return "complete actual supplied-context capture/validation mutated native custody: " + error
	if not _exact(_level.snapshot_state(), local): return "ordinary checked writer does not preserve the same complete arrival envelope"
	if not _exact(before, _capture_observation()): return "ordinary capture changed native resources/presentation/events"
	var wire: String = ExactJson.stringify(_writer_pair)
	var parsed: Dictionary = ExactJson.parse(wire)
	if wire.is_empty() or not parsed.get("accepted", false) or not String(parsed.get("error", "")).is_empty() or not parsed.get("value") is Dictionary or not _exact(_writer_pair, parsed.value):
		return "published exact transport changed whole native types/float bits: " + String(parsed.get("error", ""))
	error = _unit_error(parsed.value)
	if error.is_empty(): error = _level.snapshot_error_with_player(parsed.value.level, parsed.value.hero)
	if not error.is_empty() or not _exact(before, _capture_observation()): return "decoded native whole arrival pair validation failed or mutated: " + error
	return ""


func _unit_error(pair: Dictionary) -> String:
	if not paused or pair.hero.is_empty() or pair.level.is_empty(): return "complete paused Hero/level unit required"
	var error: String = _hero.snapshot_error(pair.hero)
	if error.is_empty(): error = _level.snapshot_error_with_player(pair.level, pair.hero)
	if not error.is_empty(): return error
	var local: Dictionary = pair.level.local
	if pair.level.local_snapshot_version != 1 or local.get("api_revision") != "act3-mirror-sea-snapshot-1" or local.get("schema_version") != 1 or local.scheduler.clock_s != 0.0 or pair.hero.world_actions.clock_s != 0.0 or not local.sources.is_empty() or not local.scheduler.reservations.is_empty() or not local.route.entries.is_empty() or not local.route.deaths.is_empty() or not local.route.pending_checkpoint_boundaries.is_empty() or local.ring.stage != "uninstalled" or not local.ring.mechanism.is_empty() or not local.ring.history.is_empty() or not local.ring.between_receipt.is_empty() or local.route.exit_state != "clear" or not local.route.contact.is_empty() or pair.level.progress.completed or not pair.level.progress.checkpoint_ids.is_empty() or not String(pair.level.progress.contact_exit_id).is_empty():
		return "arrival packet omits a closed component or contains future earned state"
	return ""


func _reject_optical_contexts() -> String:
	var camera: Camera3D = _game.get("camera") as Camera3D
	for label: String in ["missing-camera", "missing-hud", "wrong-native-pixels"]:
		var before: Dictionary = _capture_observation()
		var value: Dictionary
		match label:
			"missing-camera": value = _level.snapshot_state_for_presentation(null, _receiver_hud)
			"missing-hud": value = _level.snapshot_state_for_presentation(camera, null)
			"wrong-native-pixels": value = _level.snapshot_state_for_presentation(camera, _wrong_hud)
		var error: String = _level.last_snapshot_error
		if not value.is_empty() or error.is_empty() or not _exact(before, _capture_observation()):
			return "rejected actual optical context was accepted, repainted or altered world/receivers: " + label + "; " + error
		if label == "wrong-native-pixels" and not error.contains("native pixel dimensions"):
			return "wrong actual native pixels did not reach canonical context rejection: " + error
		var again: Dictionary = _level.snapshot_state_for_presentation(camera, _receiver_hud)
		if not _exact(again, _writer_pair.level) or not _exact(before, _capture_observation()):
			return "rejected receiver context leaked into subsequent valid actual capture: " + label
		print("OPTICAL REJECT: ", label, "; ", error)
	return ""


func _reject_bad_units() -> String:
	for label: String in ["schema", "encounter", "clock", "future-source", "progress"]:
		var bad: Dictionary = _writer_pair.duplicate(true)
		match label:
			"schema": bad.level.local.schema_version = 0
			"encounter": bad.level.local.scheduler.encounter_id = ""
			"clock": bad.level.local.scheduler.clock_s = 0.00000001
			"future-source": bad.level.local.sources[ECHO_ID] = {"kind": "echo", "actor": {}, "playback": {}}
			"progress": bad.level.progress.checkpoint_id = "mirror-sea-real-body-entry"
		var before: Dictionary = _capture_observation()
		var error: String = _level.snapshot_error_with_player(bad.level, bad.hero)
		if error.is_empty() or _level.restore_state(bad.level) or not _exact(before, _capture_observation()):
			return "malformed whole arrival unit was accepted or mutated actual native state: " + label + "; " + error
		var actual: Dictionary = {"hero": _hero.snapshot_state(), "level": _level.snapshot_state_for_presentation(_game.get("camera") as Camera3D, _receiver_hud)}
		if not _exact(actual, _writer_pair) or not _exact(before, _capture_observation()): return "bad unit changed the original whole pair: " + label
		print("ATOMIC UNIT REJECT: ", label, "; ", error)
	return ""


func _capture_observation() -> Dictionary:
	return {"mechanics": _observation(), "aliases": {"game": _game.get_instance_id(), "level": (_game.get("active_level") as Node).get_instance_id(), "hero": (_game.get("player") as Node).get_instance_id(), "camera": (_game.get("camera") as Node).get_instance_id(), "hud": (_game.get("hud") as Node).get_instance_id()}, "parent": _native_tree(_level), "hero": _native_tree(_hero), "camera": _camera_observation(), "outer_hud": _native_tree(_game.get("hud") as Node), "receiver": _native_tree(_receiver_viewport), "wrong_receiver": _native_tree(_wrong_viewport)}


func _camera_observation() -> Dictionary:
	var camera: Camera3D = _game.get("camera") as Camera3D
	return {"id": camera.get_instance_id(), "parent": camera.get_parent().get_instance_id(), "transform": camera.global_transform, "projection": camera.projection, "keep_aspect": camera.keep_aspect, "size": camera.size, "near": camera.near, "far": camera.far, "h_offset": camera.h_offset, "v_offset": camera.v_offset, "frustum_offset": camera.frustum_offset, "cull_mask": camera.cull_mask, "current": camera.get_viewport().get_camera_3d() == camera}


func _native_tree(node: Node) -> Dictionary:
	if not is_instance_valid(node): return {"missing": true}
	var result: Dictionary = {"id": node.get_instance_id(), "parent": node.get_parent().get_instance_id() if node.get_parent() != null else 0, "name": String(node.name), "script_id": node.get_script().get_instance_id() if node.get_script() != null else 0, "blocked": node.is_blocking_signals(), "process": node.is_processing(), "physics": node.is_physics_processing(), "children": []}
	if node is Node3D:
		result["transform"] = node.transform
		result["visible"] = node.visible
	if node is CollisionObject3D:
		result["layer"] = node.collision_layer
		result["mask"] = node.collision_mask
	if node is CollisionShape3D:
		result["disabled"] = node.disabled
		result["shape_id"] = node.shape.get_instance_id() if node.shape != null else 0
		if node.shape is BoxShape3D: result["shape_size"] = (node.shape as BoxShape3D).size
		elif node.shape is CapsuleShape3D: result["shape_size"] = Vector2((node.shape as CapsuleShape3D).radius, (node.shape as CapsuleShape3D).height)
	if node is MeshInstance3D:
		result["mesh_id"] = node.mesh.get_instance_id() if node.mesh != null else 0
		result["bounds"] = node.get_aabb() if node.mesh != null else AABB()
		result["material_id"] = node.material_override.get_instance_id() if node.material_override != null else 0
		if node.material_override is StandardMaterial3D:
			var material: StandardMaterial3D = node.material_override as StandardMaterial3D
			result["material"] = {"color": material.albedo_color, "transparency": material.transparency, "depth": material.depth_draw_mode, "shading": material.shading_mode, "cull": material.cull_mode, "filter": material.texture_filter, "blocked": material.is_blocking_signals()}
	if node is Sprite3D:
		result["sprite"] = {"texture": node.texture.get_instance_id() if node.texture != null else 0, "pixel_size": node.pixel_size, "offset": node.offset, "billboard": node.billboard, "modulate": node.modulate, "alpha_cut": node.alpha_cut, "filter": node.texture_filter}
	if node is CanvasLayer:
		result["visible"] = node.visible
		result["layer"] = node.layer
	if node is Control:
		result["ui"] = {"position": node.position, "size": node.size, "scale": node.scale, "rotation": node.rotation, "visible": node.visible, "modulate": node.modulate, "mouse_filter": node.mouse_filter}
	if node is Label: result["text"] = node.text
	if node is BaseButton: result["text"] = node.text if node is Button else ""
	if node is SubViewport: result["viewport_size"] = node.get_visible_rect().size
	for child: Node in node.get_children(): result.children.append(_native_tree(child))
	return result


func _dispose_receiver_huds() -> void:
	for viewport: SubViewport in [_receiver_viewport, _wrong_viewport]:
		if is_instance_valid(viewport):
			if viewport.get_parent() == root: root.remove_child(viewport)
			viewport.queue_free()
	_receiver_viewport = null
	_receiver_hud = null
	_wrong_viewport = null
	_wrong_hud = null
