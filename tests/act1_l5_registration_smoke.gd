extends "res://tests/act1_l2_registration_smoke.gd"
## UNEXECUTED ROOT DRAFT: sealed to owner HANDOFF 7cddb385 content below.
## Root installs and runs this leaf only after canonical content registration.
## Every Shell uses configure_runtime({}) and the real canonical Registry.
## Only the four-predecessor campaign prefix is TEST data. The pristine unit is
## captured from a real fresh Shell candidate, with no local/Player/camera edits.
## One short natural entry tick distinguishes the Save from its earlier Retry.
## Reuse owner119/80 for boss phases, hatch, successor transport and later CP2.

const MoonLayout = preload("res://scripts/acts/act1/living_moon_layout.gd")
const MoonCodec = preload("res://scripts/acts/act1/living_moon_codec.gd")
const Equipment = preload("res://scripts/equipment.gd")
const L5_SUBMITTED_COMMIT: String = "8f81768a221644264d8fa76c3710d9b7e4dcb79e"
const L5_SCENE: String = "res://scenes/acts/act1/a1_l5.tscn"
const L5_SCRIPT: String = "res://scripts/acts/act1/living_moon.gd"
const L5_BODY: String = "res://scripts/acts/act1/living_moon_body.gd"
const L5_NOSE: String = "res://scripts/acts/act1/living_moon_nose.gd"
const L5_BLINK: String = "res://scripts/combat/native_sampled_circle.gd"
const L5_PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3", "A1-L4"]
var _l5_option_error: String = ""
var _l5_restore_epoch: int = 0
var _l5_candidate: Dictionary = {}


func _initialize() -> void:
	_test_root = "user://test-act1-l5-registration-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	_expected_commit = L5_SUBMITTED_COMMIT
	var seen: bool = false
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--expected-commit=") and not seen:
			_expected_commit = argument.trim_prefix("--expected-commit="); seen = true
		else: _l5_option_error = "Unsupported/repeated selector: " + argument
	node_added.connect(_observe_restore_node)
	create_timer(150.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "bounded canonical L5 registration completes within150wall seconds")
			_finish())
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if not _expect(_l5_option_error.is_empty() and _expected_commit == L5_SUBMITTED_COMMIT, "sealed content commit (optional matching --expected-commit): " + _l5_option_error): _finish(); return
	_registry_text = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var registry := Registry.new()
	var accepted: Dictionary = registry.entry("A1-L5")
	var previous: Dictionary = registry.entry("A1-L4")
	var successor: Dictionary = registry.entry("A2-L1")
	if not _expect(registry.last_error.is_empty() and registry.ids().size() == 24 and accepted.get("readiness") == "accepted" and accepted.get("accepted_commit") == _expected_commit and accepted.get("scene_path") == L5_SCENE and accepted.get("api_revision") == Registry.API_REVISION and accepted.get("previous_main_id") == "A1-L4" and accepted.get("next_main_id") == "A2-L1" and previous.get("readiness") == "accepted" and previous.get("next_main_id") == "A1-L5" and successor.get("readiness") == "accepted" and successor.get("previous_main_id") == "A1-L5" and registry.scene_error("A1-L4").is_empty() and registry.scene_error("A1-L5").is_empty() and registry.scene_error("A2-L1").is_empty(), "canonical exact L4-to-Moon-to-accepted-A2-L1 links and scene readiness: " + registry.last_error): _finish(); return
	game = _new_shell()
	await _settle()
	if not _title_valid("empty production launch") or not await _l5_click("JourneyButton") or not await _l5_click("Act1Shortcut") or not await _l5_click("Node_A1_L5"): _finish(); return
	var action: Button = _find("LevelCardAction") as Button
	var node: Button = _find("Node_A1_L5") as Button
	var body: Label = _find("LevelCardBody") as Label
	if not _expect(game.menu.page_name() == "journey" and node != null and node.get_meta("campaign_state") == "locked" and action != null and action.disabled and body != null and body.text.contains("A1-L4") and game.active_level == null and game.attempts.state().completed_main.is_empty(), "actual empty Journey locks accepted Moon behind L4 without invented progress"): _finish(); return
	var empty_wire: String = Exact.stringify(game.attempts.state())
	if not await _l5_control_visible(action): _finish(); return
	_click_immediate(action)
	await _settle()
	if not _expect(_settled_ok() and game.active_level == null and Exact.stringify(game.attempts.state()) == empty_wire, "disabled card neither installs Moon nor awards progress"): _finish(); return
	_close_shell()
	if not await _seed_l5(registry): _finish(); return
	game = _new_shell()
	await _settle()
	if not _title_valid("explicit TEST prefix4 and genuine pristine unit") or not await _l5_click("JourneyButton") or not await _l5_click("Act1Shortcut") or not await _l5_click("Node_A1_L5"): _finish(); return
	action = _find("LevelCardAction") as Button
	node = _find("Node_A1_L5") as Button
	if not _expect(node != null and node.get_meta("campaign_state") == "current" and action != null and not action.disabled and action.text == "Continue Story" and _no_progress(), "TEST prefix4 exposes canonical Moon Continue without completion or reward"): _finish(); return
	_begin_l5_watch()
	if not await _l5_click("LevelCardAction"): _finish(); return
	_watching_restore = false
	if not _actual_entry() or not _expect(_restore_events.is_empty(), "canonical Continue installs quiet actual Moon recipients"): _finish(); return
	var entry: Dictionary = game.capture_campaign_snapshot()
	if not _expect(not entry.is_empty() and _initial_local(entry.level) and _valid_pair(entry) and _disk_state_matches(), "pristine production entry has exact local1/eye2/Scheduler4/native Player/Shell state"): _finish(); return
	var entry_wire: String = Exact.stringify(entry)
	if not _expect(Exact.stringify(game.attempts.state().story.checkpoint) == entry_wire and entry.player.world_actions.sequence == 0 and entry.player.world_actions.clock_s == 0.0, "actual pristine entry remains the earlier protected checkpoint"): _finish(); return
	if not _resume_consumed("canonical Moon entry") or not await _one_native_entry_tick(): _finish(); return
	game.request_pause()
	await _settle()
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_settled_ok() and paused and game.menu.page_name() == "pause" and not saved.is_empty() and _valid_pair(saved) and saved.level.local.stage == "return" and saved.level.local.eye.hp == MoonLayout.BOSS_MAX_HP and saved.player.world_actions.clock_s > entry.player.world_actions.clock_s and saved.level.local.scheduler.clock_s > 0.0 and saved.player.world_actions.sequence == 0 and saved.shell.input_sequence == 0 and Exact.stringify(game.attempts.state().story.checkpoint) == entry_wire and _no_progress() and _disk_state_matches(), "public Pause saves one genuine short entry interval with exact earlier pristine checkpoint: " + game.campaign_error): _finish(); return
	var saved_wire: String = Exact.stringify(saved)
	if not _expect(saved_wire != entry_wire and Exact.stringify(game.attempts.active_snapshot()) == saved_wire, "actual native time creates a distinct durable saved unit without fabricated phase or action"): _finish(); return
	await _settle()
	if not _expect(_settled_ok() and Exact.stringify(game.capture_campaign_snapshot()) == saved_wire, "complete paused native/input/camera unit remains exact"): _finish(); return
	var retired: Array[Dictionary] = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "saved canonical donor closure")
	if not await _fresh_continue(saved_wire, "short native Moon entry") or not _expect(_disk_state_matches(), "fresh disk Continue retains exact format2 generation"): _finish(); return
	retired = _old_refs()
	if not await _quiet_retry(entry_wire, "earlier pristine Moon entry"): _finish(); return
	_expect_refs_freed(retired, "actual earlier GUI Retry")
	if not _expect(_initial_local(game.capture_campaign_snapshot().level) and _no_progress() and _disk_state_matches(), "Retry preserves initial resources/history and awards no Moon or successor progress"): _finish(); return
	retired = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "final canonical recipient closure")
	_expect(get_nodes_in_group("required_cues").is_empty() and get_nodes_in_group("enemies").is_empty(), "normal disposal clears every Moon cue/enemy group")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_text, "fixture never rewrites canonical registry data")
	_finish()


func _seed_l5(registry: CinderCampaignRegistry) -> bool:
	game = _new_shell()
	await _settle()
	if not _title_valid("pristine canonical capture host"): return false
	_l5_candidate = game._prepare("A1-L5", Equipment.STARTER)
	if not _expect(not _l5_candidate.is_empty(), "canonical Shell prepares the real registered Moon scene"): return false
	var pristine: Dictionary = game._capture_fresh_candidate(_l5_candidate, game._fresh_shell_state())
	if not _expect(not pristine.is_empty() and _initial_local(pristine.level) and pristine.player.world_actions.sequence == 0 and pristine.player.world_actions.clock_s == 0.0, "fresh candidate supplies untouched Player/local/native camera state"): return false
	var model := Attempts.new(registry)
	var payload: Dictionary = model.state()
	payload.completed_main = L5_PREFIX.duplicate()
	payload.story = {"kind": "story", "level_id": "A1-L5", "snapshot": pristine.duplicate(true), "checkpoint": pristine.duplicate(true)}
	var store := Store.new(_test_root + "campaign.json")
	store.payload_validator = model.saved_payload_error
	if not _expect(model.state_error(payload).is_empty() and store.write_payload(payload), "TEST ONLY prefix4 plus unchanged captured unit writes through actual validated Store: " + model.last_error + "; " + store.last_error): return false
	var refs: Array[Dictionary] = []
	refs.append({"label": "seed container", "ref": weakref(_l5_candidate.container)})
	_collect_refs(_l5_candidate.container, refs)
	game._dispose(_l5_candidate); _l5_candidate = {}
	_close_shell()
	_expect_refs_freed(refs, "pristine seed candidate disposal")
	print("TEST ONLY prefix4: ", L5_PREFIX, "; all Player/local/camera values captured unchanged; no predecessor gameplay")
	return failures == 0


func _actual_entry() -> bool:
	if not _expect(_settled_ok() and paused and game.menu.page_name() == "resume" and is_instance_valid(game.active_level) and is_instance_valid(game.player), "canonical Moon operation has fully settled at paused Resume"): return false
	var level: CinderLevel = game.active_level
	if not _expect(level.level_id == "A1-L5" and level.scene_file_path == L5_SCENE and level.get_script().resource_path == L5_SCRIPT and level.hero == game.player and level.shared_shell == game and level.effects == game.fx and game.player.presentation_id == "act1_expedition" and level.contract_error().is_empty() and is_instance_valid(game.camera) and is_instance_valid(game.hud), "canonical Moon owns the shared expedition Hero, Shell, camera and HUD"): return false
	var eye: CharacterBody3D = level.get("eye") as CharacterBody3D
	var blink: CinderNativeSampledCircle = level.get("blink") as CinderNativeSampledCircle
	var nose: Node = level.get("nose")
	var scheduler: CinderThreatScheduler = level.get("scheduler") as CinderThreatScheduler
	if not _expect(is_instance_valid(eye) and is_instance_valid(blink) and is_instance_valid(nose) and is_instance_valid(scheduler), "Moon native eye/consumer/Nose/Scheduler exist"): return false
	var binding: Dictionary = eye.call("get_sampled_circle_binding")
	var owners: Dictionary = level.call("scheduler_bindings").owners
	var points: Array = level.camera_framing_points()
	return _expect(eye.get_script().resource_path == L5_BODY and blink.get_script().resource_path == L5_BLINK and nose.get_script().resource_path == L5_NOSE and blink.get_parent() == eye and binding.get("hero") == game.player and owners.get(MoonLayout.EYE_ID) == eye and owners.get(MoonLayout.NOSE_ID) == nose and owners.get(MoonLayout.RUSHER_ID) == level.get("rusher") and owners.get(MoonLayout.IMPACT_ID) == level.get("impact") and eye.get_world_3d() == game.player.get_world_3d() and _count_l5_players(game.world) == 1 and game.player.get_viewport().get_camera_3d() == game.camera and not points.is_empty() and level.last_camera_framing_error.is_empty() and game.camera_framing_error(points).is_empty() and String(level.call("_runtime_error")).is_empty(), "actual Moon source identities/native owner aliases/one Hero/current camera containment survive canonical installation")


func _initial_local(snapshot: Dictionary) -> bool:
	if snapshot.is_empty() or snapshot.get("local_snapshot_version") != 1: return false
	var local: Dictionary = snapshot.get("local", {})
	var progress: Dictionary = snapshot.get("progress", {})
	if not MoonCodec.metadata_error(local).is_empty(): return false
	return local.stage == "return" and not local.impact_demonstrated and not local.sneeze_demonstrated and local.pending_phase == 0 and local.eye.schema_version == 2 and local.eye.hp == MoonLayout.BOSS_MAX_HP and not local.eye.dead and local.eye.phase == 1 and local.blink.status == "idle" and local.blink.cycle == 0 and local.nose.cycle == 0 and local.impact.cycle == 0 and local.scheduler.schema_version == 4 and local.scheduler.clock_s == 0.0 and local.scheduler.reservations.is_empty() and not local.actors[MoonLayout.RUSHER_ID].dead and not local.escape.started and progress.get("completed") == false and progress.get("checkpoint_id") == "" and progress.get("checkpoint_ids") == {} and progress.get("contact_exit_id") == ""


func _no_progress() -> bool:
	var state: Dictionary = game.attempts.state()
	return state.completed_main == L5_PREFIX and state.completed_optional.is_empty() and state.reward_ids.is_empty() and state.side_attempt == null and (not is_instance_valid(game.active_level) or (not game.active_level.is_completed() and game.active_level.current_checkpoint().id == ""))


func _one_native_entry_tick() -> bool:
	for _frame: int in range(30):
		await physics_frame
		await process_frame
		if _finished: return false
		if not _expect(not paused and is_instance_valid(game.player) and not game.player.dead and game.campaign_error.is_empty(), "short natural entry interval stays live without forced Resume"): return false
		if game.player.get_world_action_clock() > 0.0 and (game.active_level.get("scheduler") as CinderThreatScheduler).get_clock() > 0.0: return true
	return _expect(false, "bounded short entry interval observes actual native clocks")


func _fresh_continue(expected: String, label: String) -> bool:
	_begin_l5_watch()
	game = _new_shell()
	await _settle()
	if not _title_valid(label) or not await _l5_click("ContinueStoryButton"): return false
	_watching_restore = false
	return _actual_entry() and _expect(Exact.stringify(game.capture_campaign_snapshot()) == expected and _restore_events.is_empty(), "fresh canonical GUI Continue restores exact packet with no recipient gameplay callbacks")


func _quiet_retry(expected: String, label: String) -> bool:
	game.request_pause()
	await _settle()
	if not _expect(_settled_ok() and paused and game.menu.page_name() == "pause", "public Pause exposes supported actual GUI Retry"): return false
	var previous: Dictionary = _l5_ids()
	_begin_l5_watch()
	if not await _l5_click("RetryButton"): return false
	_watching_restore = false
	if not _actual_entry(): return false
	var current: Dictionary = _l5_ids()
	for key: String in previous:
		if not _expect(current[key] != previous[key], "actual Retry installs distinct " + key): return false
	return _expect(Exact.stringify(game.capture_campaign_snapshot()) == expected and _restore_events.is_empty(), "actual earlier GUI Retry restores exact " + label + " without new-recipient gameplay callbacks")


func _title_valid(label: String) -> bool:
	return _expect(_settled_ok() and paused and game.active_level == null and game.player == null and game.menu.page_name() == "title", "fresh canonical Title has no installed level/Player: " + label)


func _l5_click(name: String) -> bool:
	await _settle()
	if not _expect(_settled_ok(), "GUI operation begins only after prior completion: " + name): return false
	var button: Button = _find(name) as Button
	if not _expect(button != null and button.is_visible_in_tree() and not button.disabled, "actual enabled GUI " + name): return false
	if not await _l5_control_visible(button): return false
	var pressed: Array[String] = []
	button.pressed.connect(func() -> void: pressed.append(name), CONNECT_ONE_SHOT)
	_click_immediate(button)
	await _settle()
	return _expect(_settled_ok() and pressed == [name], "one actual GUI click and complete operation: " + name)


func _l5_control_visible(control: Control) -> bool:
	if not _expect(_settled_ok() and is_instance_valid(control) and control.is_visible_in_tree(), "actual GUI control remains present before scrolling"): return false
	# Act1Shortcut returns to the top; L5's fifth row may be clipped there.
	# Use the same public scroll operation as Story, then route real input.
	var ancestor: Node = control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer: (ancestor as ScrollContainer).ensure_control_visible(control)
		ancestor = ancestor.get_parent()
	await _settle()
	if not _expect(_settled_ok() and is_instance_valid(control) and control.is_visible_in_tree(), "GUI scroll settles without replacing its control"): return false
	var at: Vector2 = control.get_global_rect().get_center()
	if not _expect(root.get_visible_rect().has_point(at), "actual GUI click point is inside the portrait viewport"): return false
	ancestor = control.get_parent()
	while ancestor != null:
		if ancestor is Control and (ancestor as Control).clip_contents:
			if not _expect((ancestor as Control).get_global_rect().has_point(at), "actual GUI click point survives ancestor clipping: " + String(ancestor.name)): return false
		ancestor = ancestor.get_parent()
	return true


func _settled_ok() -> bool:
	return not _finished and is_instance_valid(game) and game.campaign_error.is_empty() and (game.get("_failed_operations") as Array).is_empty() and not game.is_pause_requested() and not game.get("_draining") and not game.get("_drain_queued") and not game.get("_registration_inflight") and not game.get("_registration_pending") and (game.get("_operations") as Array).is_empty()


func _settle() -> void:
	var deadline: int = Time.get_ticks_msec() + 20000
	var stable_frames: int = 0
	# Headless process frames may outrun the native registration physics waits.
	# Bound by wall time, while still requiring two completely settled frames.
	while Time.get_ticks_msec() <= deadline:
		await process_frame
		if _finished: return
		if not is_instance_valid(game) or not game.campaign_error.is_empty() or not (game.get("_failed_operations") as Array).is_empty():
			_expect(false, "canonical operation refuses explicitly rather than passing an old menu/page"); return
		stable_frames = stable_frames + 1 if _settled_ok() else 0
		if stable_frames >= 2: return
	_expect(false, "bounded canonical queue/registration/pause completion")


func _l5_ids() -> Dictionary:
	return {"world": game.world.get_instance_id(), "level": game.active_level.get_instance_id(), "hero": game.player.get_instance_id(), "camera": game.camera.get_instance_id(), "eye": game.active_level.get("eye").get_instance_id(), "blink": game.active_level.get("blink").get_instance_id(), "nose": game.active_level.get("nose").get_instance_id(), "scheduler": game.active_level.get("scheduler").get_instance_id()}


func _count_l5_players(node: Node) -> int:
	var count: int = 1 if node is CinderPlayer else 0
	for child: Node in node.get_children(): count += _count_l5_players(child)
	return count


func _begin_l5_watch() -> void:
	_l5_restore_epoch += 1; _watching_restore = true; _restore_events.clear()


func _l5_event(label: String, epoch: int) -> void:
	if _watching_restore and epoch == _l5_restore_epoch: _restore_events.append(label)


func _observe_restore_node(node: Node) -> void:
	if not _watching_restore: return
	var epoch: int = _l5_restore_epoch
	if node is CinderPlayer:
		node.fired.connect(func(_kind: String) -> void: _l5_event("player.fired", epoch))
		node.died.connect(func() -> void: _l5_event("player.died", epoch))
		node.equipment_changed.connect(func(_id: String) -> void: _l5_event("player.equipment_changed", epoch))
		node.world_action_executed.connect(func(_record: Dictionary) -> void: _l5_event("player.world_action", epoch))
	elif node is CinderLevel:
		node.checkpoint_requested.connect(func(_id: String, _cp: String, _kind: String) -> void: _l5_event("level.checkpoint", epoch))
		node.completion_requested.connect(func(_id: String, _completion: String) -> void: _l5_event("level.completion", epoch))
		node.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _l5_event("level.contact", epoch))
	elif node is CinderThreatScheduler:
		node.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _l5_event("scheduler.invalidated", epoch))
	elif node.get_script() != null and node.get_script().resource_path == L5_BODY:
		node.connect("phase_changed", func(_id: String, _phase: int) -> void: _l5_event("eye.phase", epoch))
		node.connect("defeated", func(_id: String) -> void: _l5_event("eye.defeated", epoch))
		node.connect("state_changed", func(_state: Dictionary) -> void: _l5_event("eye.state", epoch))
	elif node is CinderLaneMechanism or node is CinderNativeSampledCircle or (node.get_script() != null and node.get_script().resource_path == L5_NOSE):
		node.connect("hit_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: _l5_event("source.hit", epoch))
		node.connect("state_changed", func(_state: Dictionary) -> void: _l5_event("source.state", epoch))
	elif node.get_script() != null and node.get_script().resource_path == "res://scripts/acts/act1/rush_selenite.gd":
		node.connect("hit_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: _l5_event("rusher.hit", epoch))
		node.connect("defeated", func(_id: String) -> void: _l5_event("rusher.defeated", epoch))


func _collect_refs(parent: Node, result: Array[Dictionary]) -> void:
	for child: Node in parent.get_children():
		result.append({"label": String(child.name), "ref": weakref(child)})
		_collect_refs(child, result)


func _old_refs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	# Shell._install frees this exact original container, including its viewport,
	# camera, world, Hero, effects and all level descendants.
	var container: Node = game.world.get_parent().get_parent()
	result.append({"label": String(container.name), "ref": weakref(container)})
	_collect_refs(container, result)
	return result


func _close_shell() -> void:
	_watching_restore = false
	if is_instance_valid(game) and not _l5_candidate.is_empty(): game._dispose(_l5_candidate)
	_l5_candidate = {}
	super._close_shell()


func _finish() -> void:
	if _finished: return
	_finished = true
	_close_shell()
	paused = false
	_cleanup_saves()
	_expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_test_root)), "isolated registration save/settings/backup directory retires normally")
	print("Production Act1 L5 registration: %d checks, %d failures; expected_commit=%s; scope=canonical links/unlock/entry/short native Save/fresh GUI Continue/earlier GUI Retry/cleanup; TEST prefix4; no boss defeat/full route/new portrait" % [checks, failures, _expected_commit])
	quit(0 if failures == 0 else 1)
