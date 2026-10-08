extends SceneTree
## TEST ONLY: live shared-shell consumer evidence over unfinished Twin Suns.
## Registry acceptance and the predecessor prefix exist only in memory. They
## do not accept this level, complete earlier levels, or modify campaign data.
## Routed Godot touch events are automated fixture input, not native OS or
## human play evidence. No enemy, scheduler, lunge or completion is exercised.
## Run through dev.py engine --headless --path . --script this file, with no
## --level-scene/--capture arguments (those select the shell's preview mode).

const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const PreviewScene: PackedScene = preload("res://scenes/main.tscn")
const SunScript: GDScript = preload("res://scripts/acts/act3/twin_suns.gd")
const RoomPath: String = "res://scenes/acts/act3/a3_l1_sun_room.tscn"
const FullPath: String = "res://scenes/acts/act3/a3_l1.tscn"
const CheckpointHP: float = 31.25
const CheckpointID: String = "test-only-shell-noon"

var _checks: int = 0
var _failures: int = 0
var _test_root: String = ""
var _game: CinderCampaignShell


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_root = "user://test-act3-twin-suns-shell-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	var canonical_text: String = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var parsed: Variant = JSON.parse_string(canonical_text)
	if not _expect(parsed is Dictionary, "fixture reads the canonical registry without editing it"):
		_finish()
		return
	for scene_path: String in [RoomPath, FullPath]:
		var label: String = "room" if scene_path == RoomPath else "full"
		await _exercise(scene_path, label, parsed)
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == canonical_text, "canonical registry bytes remain unchanged")
	_finish()


func _exercise(scene_path: String, label: String, canonical: Dictionary) -> void:
	var initial: Dictionary = await _initial_snapshot(scene_path, label)
	if initial.is_empty():
		return
	# The published registry keeps the canonical A1-L1 opening. Seed a marked
	# saved-session fixture through restore_session rather than replacing its
	# route or calling private preparation/install methods.
	var raw: Dictionary = canonical.duplicate(true)
	for info: Dictionary in raw["levels"]:
		if info["id"] == "A3-L1":
			info["scene_path"] = scene_path
			info["readiness"] = "accepted" # TEST ONLY, in-memory fixture metadata.
			info["accepted_commit"] = "a".repeat(40) # TEST ONLY provenance marker.
			info["api_revision"] = Registry.API_REVISION
	var case_root: String = _test_root.path_join(label) + "/"
	_game = Shell.new()
	if not _expect(_game.configure_runtime(raw, case_root + "campaign.json", case_root + "settings.json", case_root + "preferences.json"), label + ": configure the real shell with isolated fixture paths"):
		_game.free()
		_game = null
		return
	root.add_child(_game)
	await _settle()
	var prefix: Array[String] = []
	for id: String in _game.registry.main_route():
		if id == "A3-L1":
			break
		prefix.append(id)
	var session: Dictionary = _game.attempts.state()
	session["completed_main"] = prefix.duplicate() # TEST ONLY prior-route fixture.
	session["story"] = {"kind": "story", "level_id": "A3-L1", "snapshot": initial.duplicate(true), "checkpoint": initial.duplicate(true)}
	if not _expect(prefix.size() == 10 and _game.attempts.restore_session(session), label + ": public session restore accepts the marked canonical-prefix fixture: " + _game.attempts.last_error):
		await _close_case(case_root, label)
		return
	_game.resume_campaign()
	await _settle()
	if not _expect(_game.campaign_error.is_empty() and is_instance_valid(_game.active_level) and is_instance_valid(_game.player), label + ": real shell stages the authored A3-L1 world: " + _game.campaign_error):
		await _close_case(case_root, label)
		return
	_expect(paused and _game.menu.page_name() == "resume" and _game.active_level.scene_file_path == scene_path and _game.active_level.shared_shell == _game, label + ": staged authored level retains its entered lifecycle and waits for resume")
	_expect(_game.player.presentation_id == "act3_traveller", label + ": shared actor selects the published Act 3 presentation")
	_game.resume_campaign()
	if not await _wait_clock(_game.player, 0.2, label):
		await _close_case(case_root, label)
		return
	_expect(_game.player.get_threat_response_state()["motion"]["grounded"], label + ": staged shared actor settles on the actual authored safe floor")
	var checkpoint_anchor := Vector2(0.34, 0.52)
	if not await _swipe(checkpoint_anchor, label):
		await _close_case(case_root, label)
		return
	if not await _wait_sun_preview(label):
		await _close_case(case_root, label)
		return
	# Deliberately depleted fixture resources, just before the real checkpoint.
	# No private reload/cooldown field or synthetic local sun clock is changed.
	_game.player.hp = CheckpointHP
	_game.player.shells = 0
	var checkpoint_clock: float = _game.player.get_world_action_clock()
	var accepted: bool = _game.active_level.request_checkpoint(CheckpointID, "encounter")
	_expect(accepted and paused, label + ": public level checkpoint enters the shell's deferred paused barrier")
	var local_at_barrier: Dictionary = _game.active_level.snapshot_state()
	await _settle()
	var checkpoint: Dictionary = (_game.attempts.state()["story"] as Dictionary)["checkpoint"]
	if not _expect(_game.campaign_error.is_empty() and not checkpoint.is_empty(), label + ": shell commits the actual actor/local/input checkpoint: " + _game.campaign_error):
		await _close_case(case_root, label)
		return
	_expect(checkpoint["player"]["resources"]["hp"] == CheckpointHP and checkpoint["player"]["resources"]["shells"] == 0 and checkpoint["level"]["progress"]["checkpoint_id"] == CheckpointID, label + ": checkpoint retains depleted HP/zero ammo and the authored boundary without healing")
	_expect(Codec.same_values(checkpoint["level"], local_at_barrier) and float(checkpoint["player"]["world_actions"]["clock_s"]) == checkpoint_clock and Codec.same_values(checkpoint["shell"]["anchor_normalized"], [checkpoint_anchor.x, checkpoint_anchor.y]), label + ": one barrier captures the real preview clock, actor clock and exact release anchor together")
	_expect(not paused and not _game.menu.is_open(), label + ": successful checkpoint resumes the previously active scenery simulation")
	var stored: Dictionary = Store.new(case_root + "campaign.json").read_payload()
	if _expect(not stored.is_empty(), label + ": isolated test save contains the shell's checkpoint"):
		var written: Dictionary = (stored["story"] as Dictionary)["checkpoint"]
		_expect(Codec.same_values(written, checkpoint) and float(written["level"]["local"]["sun_elapsed_s"]) == float(checkpoint["level"]["local"]["sun_elapsed_s"]) and float(written["player"]["world_actions"]["clock_s"]) == checkpoint_clock, label + ": published full-precision store preserves the authored fractional clocks")
	if not await _wait_sun_change(int(checkpoint["level"]["local"]["sun_state"]), label):
		await _close_case(case_root, label)
		return
	if not await _swipe(Vector2(0.72, 0.58), label):
		await _close_case(case_root, label)
		return
	_game.player.hp = 7.5
	_game.player.shells = 1
	_game.request_pause()
	await _settle()
	var changed: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(paused and not changed.is_empty() and changed["player"]["resources"]["hp"] == 7.5 and changed["player"]["resources"]["shells"] == 1 and not Codec.same_values(changed["level"]["local"], checkpoint["level"]["local"]), label + ": later live actor/local/input state differs meaningfully from the saved checkpoint"):
		await _close_case(case_root, label)
		return
	await create_timer(0.08, true).timeout
	_expect(Codec.same_values(_game.capture_campaign_snapshot(), changed), label + ": explicit pause freezes the aggregate including sun and actor clocks")
	var old_level: CinderLevel = _game.active_level
	var old_player: CinderPlayer = _game.player
	var old_world: Node3D = _game.world
	_game.request_retry()
	await _settle()
	var retried: Dictionary = _game.capture_campaign_snapshot()
	_expect(_game.campaign_error.is_empty() and paused and Codec.same_values(retried, checkpoint), label + ": public retry restores the exact paused actor/local/screen/camera aggregate: " + _game.campaign_error)
	_expect(_game.player.hp == CheckpointHP and _game.player.hp < _game.player.max_hp and _game.player.shells == 0 and _game.get_aim_anchor_normalized().is_equal_approx(checkpoint_anchor) and String(_game.active_level.get("sun_stage")) == "preview", label + ": retry preserves protected HP/zero ammo and restores the actual earlier sun preview and anchor")
	var sun_motifs: Node3D = _game.active_level.find_child("ScenicSuns", true, false) as Node3D
	_expect(paused and is_instance_valid(sun_motifs) and is_equal_approx(sun_motifs.global_position.x, _game.player.global_position.x) and is_equal_approx(sun_motifs.global_position.z, _game.player.global_position.z), label + ": paused retry aligns distant sun motifs with the restored actor without a physics tick")
	_expect(not is_instance_valid(old_level) and not is_instance_valid(old_player) and not is_instance_valid(old_world) and _count_levels(root) == 1 and _game.active_level.shared_shell == _game, label + ": retry retires the old world and preserves the new level's shared lifecycle")
	await create_timer(0.08, true).timeout
	_expect(Codec.same_values(_game.capture_campaign_snapshot(), checkpoint), label + ": restored sun/resources/input clocks remain frozen until explicit resume")
	var history_before: Array[Dictionary] = _game.player.get_world_action_records()
	_game.resume_campaign()
	_expect(not paused and not _game.menu.is_open() and _game.player.get_world_action_records() == history_before and _game.get_aim_anchor_normalized().is_equal_approx(checkpoint_anchor), label + ": public resume retains the saved release anchor without executing an attack or new dash")
	if await _wait_clock(_game.player, 0.12, label):
		_expect(float(_game.active_level.get("sun_elapsed_s")) > float(checkpoint["level"]["local"]["sun_elapsed_s"]) and _game.player.hp == CheckpointHP and _game.player.shells == 0, label + ": restored live clocks continue without a resource reset")
	_expect(_game.attempts.state()["completed_main"] == prefix and _game.attempts.state()["completed_optional"].is_empty() and _game.attempts.state()["reward_ids"].is_empty() and not _game.active_level.is_completed(), label + ": fixture neither completes A3-L1 nor advances or rewards the campaign")
	await _close_case(case_root, label)


func _initial_snapshot(scene_path: String, label: String) -> Dictionary:
	paused = false
	var preview: Node = PreviewScene.instantiate()
	preview.set("level_scene_path", scene_path)
	root.add_child(preview)
	preview.call("resume_lab")
	await _ticks(12)
	preview.call("open_bench")
	await _settle()
	var actor: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var snapshot: Dictionary = {}
	if _expect(is_instance_valid(actor) and is_instance_valid(level), label + ": seed uses the actual shared preview actor and authored scene"):
		var actor_state: Dictionary = actor.snapshot_state()
		var local_state: Dictionary = level.snapshot_state()
		if _expect(not actor_state.is_empty() and not local_state.is_empty(), label + ": public paused snapshots provide real initial actor/local state"):
			# Only fresh shell initialization is declared by the fixture. Subsequent
			# input/camera snapshots are produced and restored by the live shell.
			var shell_state: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [0.5, 0.5], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(actor.global_position + Vector3.UP * 0.75), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}
			snapshot = {"schema_version": 1, "level_id": "A3-L1", "scene_path": scene_path, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": actor_state, "level": local_state, "shell": shell_state}
	preview.free()
	await _settle()
	return snapshot


func _swipe(release: Vector2, label: String) -> bool:
	var actor: CinderPlayer = _game.player
	var before: Array[Dictionary] = actor.get_world_action_records()
	var sequence: int = int(before.back()["sequence"]) if not before.is_empty() else 0
	var position_before: Vector3 = actor.global_position
	var observation_before: Dictionary = _game.get_input_observation_state()
	var size: Vector2 = root.get_visible_rect().size
	var start: Vector2 = size * Vector2(0.56, 0.65)
	var finish: Vector2 = size * release
	var route_trace: Array[Dictionary] = []
	# These points already use the root viewport's logical coordinates. The
	# public push_input(event, true) preserves that space; its false default
	# would convert them again from the embedder/window's coordinate space.
	# Same route as tests/campaign_menu_smoke.gd; GUI consumption still applies.
	var down := InputEventScreenTouch.new()
	down.index = 7
	down.position = start
	down.pressed = true
	root.push_input(down, true)
	route_trace.append({"event": "down", "handled": root.is_input_handled(), "observation": _game.get_input_observation_state()})
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.index = 7
	drag.position = finish
	drag.relative = finish - start
	root.push_input(drag, true)
	route_trace.append({"event": "drag", "handled": root.is_input_handled(), "observation": _game.get_input_observation_state()})
	await process_frame
	var up := InputEventScreenTouch.new()
	up.index = 7
	up.position = finish
	up.pressed = false
	root.push_input(up, true)
	route_trace.append({"event": "up", "handled": root.is_input_handled(), "observation": _game.get_input_observation_state()})
	await process_frame
	if not await _wait_clock(actor, float(actor.equipment.resolved_stats()["dash_cooldown"]) + 0.04, label):
		return false
	var observed: Dictionary = _game.get_input_observation_state()
	var records: Array[Dictionary] = actor.get_world_action_records(sequence)
	print("SWIPE DIAGNOSTIC TEST ONLY ", label, ": ", {"root_rect": root.get_visible_rect(), "shell_viewport_rect": _game.get_viewport().get_visible_rect(), "screen_transform": root.get_screen_transform(), "stretch_transform": root.get_stretch_transform(), "in_local_coords": true, "start": start, "finish": finish, "expected_anchor": release, "actual_anchor": _game.get_aim_anchor_normalized(), "observation_before": observation_before, "observation_after": observed, "position_before": position_before, "position_after": actor.global_position, "paused": paused, "menu_open": _game.menu.is_open(), "menu_page": _game.menu.page_name(), "route_trace": route_trace})
	print("SWIPE COMPLETED PUBLIC RECORDS TEST ONLY ", label, ": ", records)
	return _expect(_game.get_aim_anchor_normalized().is_equal_approx(release) and observed["last_observation"].get("kind") == "swipe_release" and records.size() == 1 and records[0].get("kind") == "dash" and not bool(records[0].get("blocked", true)) and not bool(records[0].get("collision_shortened", true)), label + ": routed Godot touch swipe supplies a final release anchor and a real completed unobstructed dash")


func _wait_sun_preview(label: String) -> bool:
	for _index: int in range(int(Engine.physics_ticks_per_second * (SunScript.SUN_PERIOD_S + 1.0))):
		if String(_game.active_level.get("sun_stage")) == "preview":
			return true
		if paused:
			return _expect(false, label + ": unexpected pause before the real sun preview")
		await _ticks(1)
	return _expect(false, label + ": actual scenic clock failed to reach its preview")


func _wait_sun_change(previous: int, label: String) -> bool:
	for _index: int in range(int(Engine.physics_ticks_per_second * (SunScript.SUN_PREVIEW_S + SunScript.SUN_LOCK_S + 2.0))):
		if int(_game.active_level.get("sun_state")) != previous:
			return true
		if paused:
			return _expect(false, label + ": checkpoint did not resume the active sun clock")
		await _ticks(1)
	return _expect(false, label + ": actual sun cycle failed to progress after its checkpoint")


func _wait_clock(actor: CinderPlayer, duration: float, label: String) -> bool:
	var deadline: float = actor.get_world_action_clock() + duration
	for _index: int in range(int(ceilf(duration * Engine.physics_ticks_per_second)) + 16):
		if actor.get_world_action_clock() >= deadline:
			return true
		if paused:
			return _expect(false, label + ": active actor clock unexpectedly paused")
		await _ticks(1)
	return _expect(false, label + ": actual actor clock did not advance within the bounded wait")


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame


func _settle() -> void:
	for _index: int in range(6):
		await process_frame


func _close_case(case_root: String, label: String) -> void:
	if is_instance_valid(_game):
		_game.free()
	_game = null
	paused = false
	await _settle()
	_expect(_count_levels(root) == 0, label + ": disposing the shell releases every authored level and prepared world")
	_cleanup_owned_path(case_root)


func _count_levels(node: Node) -> int:
	var count: int = 1 if node is CinderLevel else 0
	for child: Node in node.get_children():
		count += _count_levels(child)
	return count


func _cleanup_owned_path(path: String) -> void:
	if path.is_empty() or not path.begins_with(_test_root):
		return
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
		return
	for directory: String in DirAccess.get_directories_at(path):
		_cleanup_owned_path(path.path_join(directory))
	for filename: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path.path_join(filename)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(ok: bool, note: String) -> bool:
	_checks += 1
	print("PASS: TEST ONLY " + note) if ok else push_error("FAIL: TEST ONLY " + note)
	if not ok:
		_failures += 1
	return ok


func _finish() -> void:
	if is_instance_valid(_game):
		_game.free()
	_game = null
	paused = false
	_cleanup_owned_path(_test_root)
	print("Twin Suns campaign-shell scaffold: %d checks, %d failures (TEST ONLY room/full; no campaign or combat acceptance)" % [_checks, _failures])
	quit(1 if _failures else 0)
