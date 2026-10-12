extends "res://tests/act2_l4_registration_smoke.gd"
## Focused production A2-L5 Registry/GUI/save/Retry registration.
## Requires Root's exact accepted production Registry and imported HANDOFF; it
## never injects readiness, scene paths, accepted pins or next-act exposure.
## TEST ONLY nine-predecessor prefix and validated HP37/zero-ammo entrance seed
## are not predecessor gameplay, an earned checkpoint, B05/coda or route credit.
## Actual GUI and routed touch helpers are inherited from accepted L4 coverage.
## Existing owned154/107 mechanics/common-transition evidence stays separate.

const L5_ACCEPTED_COMMIT: String = "5703fd42cd5350f4c261b3c044456fbea9f9f3b7"
const L5_SCENE: String = "res://scenes/acts/act2/dead_london.tscn"
const L5_RUNTIME: String = "res://scripts/acts/act2/dead_london.gd"
const L5_PARENT: String = "res://scripts/acts/act2/dead_london_sentry_presented_encounter.gd"
const L5_PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3", "A1-L4", "A1-L5", "A2-L1", "A2-L2", "A2-L3", "A2-L4"]
const L5_SCOUTS: Array[String] = ["A2-L5:square-scout", "A2-L5:park-scout"]

func _initialize() -> void:
	var identity: String = "%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_test_root = "user://test-act2-l5-registration-%s/" % identity
	_capture_root = "user://test-act2-l5-registration-captures-%s/" % identity
	_expected_commit = L5_ACCEPTED_COMMIT
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--portrait": graphical = true
		elif argument.begins_with("--expected-commit="): _expected_commit = argument.trim_prefix("--expected-commit=")
	node_added.connect(_observe_restore_node)
	create_timer(90.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "production A2-L5 registration finishes within its bounded watchdog")
			# A hung coroutine is not freed beneath its native callback. Root also
			# bounds only this owned process after canonical lock acquisition.
			quit(1))
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if not _expect(_expected_commit == L5_ACCEPTED_COMMIT, "registration requires the exact submitted HANDOFF; --expected-commit may assert but not replace it"):
		_finish(); return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--level-scene") or argument in ["--capture", "--capture-polish"]:
			_expect(false, "registration cannot select a private preview or substitute scene")
			_finish(); return
	_registry_text = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var registry := Registry.new()
	var accepted: Dictionary = registry.entry("A2-L5")
	if not _expect(registry.last_error.is_empty() and registry.ids().size() == 24 and accepted.get("readiness") == "accepted" and accepted.get("accepted_commit") == L5_ACCEPTED_COMMIT and accepted.get("scene_path") == L5_SCENE and accepted.get("api_revision") == Registry.API_REVISION and registry.scene_error("A2-L5").is_empty(), "untouched production Registry contains exact accepted A2-L5: " + registry.last_error):
		_finish(); return
	_expect(accepted.get("previous_main_id") == "A2-L4" and registry.next_main("A2-L5") == "A3-L1" and registry.is_playable("A3-L1"), "canonical A2-L4 prerequisite and already accepted A3-L1 recipient are preserved")
	game = _new_shell()
	await _settle()
	if not _title_valid("isolated first launch"):
		_finish(); return
	_expect(game.player == null and game.attempts.state().completed_main.is_empty(), "fresh Title has NULL Player and invents no prefix")
	await _capture("title-locked")
	await _click(_find("JourneyButton") as Control)
	await _click(_find("Act2Shortcut") as Control)
	await _click(_find("Node_A2_L5") as Control)
	var action: Button = _find("LevelCardAction") as Button
	var node: Button = _find("Node_A2_L5") as Button
	if not _expect(game.menu.page_name() == "journey" and is_instance_valid(node) and node.get_meta("campaign_state") == "locked" and is_instance_valid(action) and action.disabled and (_find("LevelCardBody") as Label).text.contains("A2-L4"), "actual Journey locks A2-L5 behind its actual A2-L4 prerequisite"):
		_finish(); return
	await _capture("journey-locked")
	var empty_model: String = Exact.stringify(game.attempts.state())
	await _click(action)
	_expect(game.player == null and game.active_level == null and not empty_model.is_empty() and Exact.stringify(game.attempts.state()) == empty_model, "disabled production card loads no world and fabricates no progress")
	_close_shell()
	if not await _seed_actual_story(registry, 37.0):
		_finish(); return
	game = _new_shell()
	await _settle()
	if not _title_valid("TEST ONLY nine-predecessor initial unit"):
		_finish(); return
	_expect(game.player == null and _no_progress() and not (_find("ContinueStoryButton") as Button).disabled, "fresh NULL-Player Title offers the genuine saved uncompleted production L5")
	await _click(_find("JourneyButton") as Control)
	await _click(_find("Act2Shortcut") as Control)
	await _click(_find("Node_A2_L5") as Control)
	action = _find("LevelCardAction") as Button
	node = _find("Node_A2_L5") as Button
	if not _expect(is_instance_valid(node) and node.get_meta("campaign_state") == "current" and is_instance_valid(action) and not action.disabled and action.text == "Continue Story" and (_find("Node_A3_L1") as Button).get_meta("campaign_state") == "locked", "seeded actual Journey offers L5 Continue while A3-L1 remains completion-locked"):
		_finish(); return
	await _capture("journey-seeded")
	_restore_events.clear()
	_watching_restore = true
	await _click(action)
	_watching_restore = false
	if not _actual_entry():
		_finish(); return
	var entry: Dictionary = game.capture_campaign_snapshot()
	if not _expect(not entry.is_empty() and _valid_pair(entry) and _restore_events.is_empty(), "actual initial GUI Continue quietly restores a complete production Player/local26/Scheduler/Shell unit: " + str(_restore_events)):
		_finish(); return
	var entry_encoded: String = Exact.stringify(entry)
	if not _expect(not entry_encoded.is_empty() and entry_encoded == Exact.stringify(game.attempts.active_snapshot()) and entry_encoded == Exact.stringify(game.attempts.state().story.checkpoint) and entry.player.resources.hp == 37.0 and entry.player.resources.shells == 0 and entry.player.world_actions.clock_s == 0.0 and entry.player.world_actions.sequence == 0 and entry.shell.input_sequence == 0 and _disk_state_matches(), "genuine protected entrance exactly matches its seeded current/checkpoint units, HP37/zeroammo, no native tick/input and checked format2 data"):
		_finish(); return
	if not _resume_consumed("initial living production L5 entry"):
		_finish(); return
	await _capture("arrival")
	# One ordinary RIGHT dash remains in the actual first square, well before
	# its first contact at Z=-6.2. No actor/source/phase/pose/focus write is used.
	if not await _ready_dash() or not await _swipe(Vector2(0.36, 0.72), Vector2(0.55, 0.72)) or not await _wait_finished_dash(1):
		_finish(); return
	game.request_pause()
	await _settle()
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _expect(game.campaign_error.is_empty() and paused and game.menu.page_name() == "pause" and not saved.is_empty() and _valid_pair(saved), "public deferred Pause captures actual routed dash plus complete production world: " + game.campaign_error):
		_finish(); return
	var saved_encoded: String = Exact.stringify(saved)
	var records: Array[Dictionary] = game.player.get_world_action_records()
	if not _expect(not saved_encoded.is_empty() and records.size() == 1, "exact current production snapshot retains one genuine completed world action"):
		_finish(); return
	var dash: Dictionary = records[0]
	var size: Vector2 = root.get_visible_rect().size
	var release_anchor: Vector2 = (Vector2(0.55, 0.72) * size) / size
	_expect(dash.kind == "dash" and dash.path.size() >= 2 and dash.completed_at_s > dash.started_at_s and saved.player.world_actions.sequence == 1 and game.get_aim_anchor_normalized() == release_anchor, "native completed dash has measured path and exact final-screen release aim")
	_expect(saved_encoded != entry_encoded and saved.player.world_actions.clock_s > 0.0 and saved.level.local.scheduler.clock_s > 0.0 and saved.shell.camera_focus != entry.shell.camera_focus, "normal physics changes native Player/Scheduler clocks, movement and following camera")
	_expect(saved.player.resources.hp == 37.0 and saved.player.resources.shells == 0 and saved.equipment_ids == entry.equipment_ids and saved.shell.input_sequence == 1, "short native entrance dash preserves actual HP/emptyammo/gear with one routed input")
	_expect(Exact.stringify(game.attempts.active_snapshot()) == saved_encoded and Exact.stringify(game.attempts.state().story.checkpoint) == entry_encoded and _no_progress(), "real Pause records current whole unit and protects its exact earlier entrance without completion/rewards")
	_expect(_disk_state_matches(), "actual moved L5 unit reopens exact checked format2 generation")
	await _settle()
	_expect(Exact.stringify(game.capture_campaign_snapshot()) == saved_encoded, "paused process frames freeze complete actual current unit")
	var retired: Array[Dictionary] = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "saved L5 shell retirement")
	if not await _fresh_continue(saved_encoded, "living production L5 movement"):
		_finish(); return
	_expect(game.player.hp == 37.0 and game.player.shells == 0 and game.player.get_world_action_records().size() == 1 and _disk_state_matches(), "fresh actual GUI Continue preserves resources/history and publishes no past dash")
	retired = _old_refs()
	if not await _quiet_retry(entry_encoded, "protected production L5 entrance"):
		_finish(); return
	_expect_refs_freed(retired, "actual GUI L5 Retry")
	_expect(game.player.hp == 37.0 and game.player.shells == 0 and game.player.get_world_action_records().is_empty() and _no_progress() and _disk_state_matches(), "exact earlier Retry restores genuine HP/emptyammo/history without healing or invented progress")
	retired = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "final L5 recipient retirement")
	_expect(get_nodes_in_group("required_cues").is_empty() and get_nodes_in_group("enemies").is_empty(), "all actual L5 worlds leave no required cue or enemy group member")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_text, "production Registry bytes remain untouched throughout")
	_finish()

func _seed_actual_story(registry: CinderCampaignRegistry, initial_hp: float) -> bool:
	paused = true
	var preview: Node = MainScene.instantiate()
	preview.set("level_scene_path", L5_SCENE)
	root.add_child(preview)
	paused = true # Public ordinary constructor resumes; close before any tick.
	await _settle()
	var actor: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var camera: Camera3D = preview.get("camera") as Camera3D
	if not _expect(is_instance_valid(actor) and is_instance_valid(level) and is_instance_valid(camera) and level.scene_file_path == L5_SCENE and level.get_script().resource_path == L5_RUNTIME and String(preview.get("level_load_error")).is_empty(), "TEST seed constructs exact full actual DeadLondon scene/controller, not a plain contact source or proxy"):
		preview.free(); return false
	var initial: Dictionary = actor.snapshot_state()
	if not _expect(not initial.is_empty(), "actual paused pristine Player seed is available: " + actor.last_snapshot_error):
		level.exit_level(); preview.free(); return false
	initial.resources.hp = initial_hp
	initial.resources.shells = 0
	var accepted: bool = actor.restore_state(initial)
	var player_state: Dictionary = actor.snapshot_state()
	var local: Dictionary = level.snapshot_state()
	var anchor: Vector2 = preview.call("get_aim_anchor_normalized")
	var observation: Dictionary = preview.call("get_input_observation_state")
	var shell_state: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": observation.sequence, "last_input_observation": observation.last_observation.duplicate(true), "camera_focus": Codec.vector3(camera.global_position - Game.CAMERA_OFFSET), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}
	var aggregate: Dictionary = {"schema_version": 1, "level_id": "A2-L5", "scene_path": L5_SCENE, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": player_state, "level": local, "shell": shell_state}
	var store: CinderSaveStore = Store.new(_test_root + "campaign.json")
	var model: CinderCampaignAttempts = Attempts.new(registry, store)
	var seed: Dictionary = model.state()
	seed["completed_main"] = L5_PREFIX.duplicate()
	seed["story"] = {"kind": "story", "level_id": "A2-L5", "snapshot": aggregate.duplicate(true), "checkpoint": aggregate.duplicate(true)}
	var error: String = level.snapshot_error_with_player(local, player_state) if not local.is_empty() and not player_state.is_empty() else "Actual paused production capture failed"
	accepted = accepted and error.is_empty() and model.state_error(seed).is_empty() and model.restore_session(seed) and store.write_payload(model.state())
	if not _expect(accepted, "public actor restore/Attempts/Store write disclosed nine-predecessor and HP37/zeroammo seed with genuine production unit: " + error + " / " + model.last_error + " / " + store.last_error):
		level.exit_level(); preview.free(); return false
	_expect(not local.is_empty() and local.local.size() == 26 and local.local_snapshot_version == 1 and local.local.stage == 0 and local.local.contacts.is_empty() and local.local.defeated_scouts.is_empty() and local.local.scheduler.clock_s == 0.0 and local.local.sentry.parent.stage == "dormant" and player_state.world_actions.clock_s == 0.0 and player_state.world_actions.sequence == 0 and observation.sequence == 0 and observation.last_observation.is_empty(), "seed retains pristine local26/actual dormant Sentry and normal counters, without native progress/phase forcing")
	var refs: Array[Dictionary] = [{"label": "initial actual Main", "ref": weakref(preview)}, {"label": "initial actual Player", "ref": weakref(actor)}, {"label": "initial actual L5", "ref": weakref(level)}]
	_collect_refs(level, refs)
	level.exit_level()
	preview.free()
	_expect_refs_freed(refs, "seed constructor retirement before production Continue")
	print("TEST ONLY prefix/resource seed: ", L5_PREFIX, "; HP=", initial_hp, "; initial shells=0; no predecessor gameplay, B05/coda or full-route claim")
	return accepted

func _actual_entry() -> bool:
	if not _expect(game.campaign_error.is_empty() and is_instance_valid(game.active_level) and is_instance_valid(game.player) and paused and game.menu.page_name() == "resume", "actual production L5 installation waits paused at Resume: " + game.campaign_error): return false
	var level: CinderLevel = game.active_level
	var state: Dictionary = level.call("encounter_state")
	if not _expect(level.level_id == "A2-L5" and level.scene_file_path == L5_SCENE and level.get_script().resource_path == L5_RUNTIME and level.hero == game.player and level.effects == game.fx and game.player.presentation_id == "act2_survivor" and state.get("runtime_error", "missing") == "" and state.get("stage_index") == 0 and state.get("sources", {}).size() == 2 and state.get("sentry", {}).get("stage") == "dormant" and not level.is_completed(), "real full L5 owns the shared Hero/effects, two familiar sources, rehearsal and dormant native B05 without completion"): return false
	for id: String in L5_SCOUTS:
		var actor: Node3D = level.get_node_or_null("Familiar_" + id.replace(":", "_")) as Node3D
		if not _expect(is_instance_valid(actor) and actor.get("actor_id") == id and level.is_ancestor_of(actor), "actual retained familiar source has canonical identity: " + id): return false
	var scheduler: Node = level.get_node_or_null("OneDeadLondonScheduler")
	var familiar: Node = level.get_node_or_null("TwoKnownScouts")
	var rehearsal: Node = level.get_node_or_null("OneApproachFootConsumer")
	var sentry: Node = level.get_node_or_null("OnePersistentB05Parent")
	if not _expect(scheduler is CinderThreatScheduler and is_instance_valid(familiar) and familiar.has_signal("hit_resolved") and rehearsal is CinderLaneMechanism and is_instance_valid(sentry) and sentry.get_script().resource_path == L5_PARENT and is_instance_valid(sentry.call("get_actor")) and is_instance_valid(sentry.call("get_ray")) and is_instance_valid(sentry.call("get_foot")) and is_instance_valid(sentry.call("get_joint_cue")), "exact full L5 retains one real Scheduler/familiar consumer/rehearsal/native presented Sentry and sources"): return false
	var points: Array = level.camera_framing_points()
	var hero_points: Array = game.player_camera_framing_points()
	points.append_array(hero_points)
	var optics: String = game.camera_framing_error(points)
	return _expect(not hero_points.is_empty() and level.last_camera_framing_error.is_empty() and optics.is_empty() and (level.get_node("PlayerSpawn") as Marker3D).position == Vector3(0, 0.1, 2.2), "actual full Hero/source bounds fit fixed camera/HUD and original authored spawn is intact: " + optics)

func _no_progress() -> bool:
	var state: Dictionary = game.attempts.state()
	return state.completed_main == L5_PREFIX and state.completed_optional.is_empty() and state.reward_ids.is_empty() and state.side_attempt == null and (not is_instance_valid(game.active_level) or not game.active_level.is_completed())

func _observe_restore_node(node: Node) -> void:
	# Retain all actual Player/level/familiar/Lane/actor gameplay observations.
	super._observe_restore_node(node)
	if not _watching_restore or node.get_script() == null: return
	var path: String = node.get_script().resource_path
	if path == "res://scripts/acts/act2/dead_london_ray_exchange.gd":
		node.connect("hit_resolved", func(_id: String, _result: Dictionary) -> void: _restore_events.append("sentry_ray.hit_resolved"))
	elif path == L5_PARENT:
		node.connect("phase_checkpoint_eligible", func(_value: Dictionary) -> void: _restore_events.append("sentry.phase_checkpoint"))
		node.connect("sentry_cleared", func(_value: Dictionary) -> void: _restore_events.append("sentry.cleared"))
		node.connect("hit_resolved", func(_id: String, _result: Dictionary) -> void: _restore_events.append("sentry.hit_resolved"))
		node.connect("runtime_failed", func(_reason: String) -> void: _restore_events.append("sentry.runtime_failed"))
	elif path == "res://scripts/acts/act2/dead_london_sentry_presented_actor.gd":
		node.connect("phase_boundary_reached", func(_id: String) -> void: _restore_events.append("sentry_actor.phase_boundary"))

func _capture(label: String) -> void:
	if not graphical: return
	if not _expect(DisplayServer.get_name() != "headless", "optional L5 portrait requires the actual graphical renderer"): return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_root))
	var picture: Image = root.get_texture().get_image()
	_expect(picture != null and picture.get_size() == Vector2i(540, 1170) and picture.save_png(_capture_root + label + ".png") == OK, "actual L5 registration portrait stored: " + ProjectSettings.globalize_path(_capture_root + label + ".png"))

func _finish() -> void:
	if _finished: return
	_finished = true
	_close_shell()
	paused = false
	_cleanup_saves()
	print("Production Act2 L5 registration: %d checks, %d failures; expected_commit=%s; TEST ONLY nine-predecessor/HP37/zeroammo seed; actual full production GUI/format2/routed dash/quiet Continue/Retry/cleanup; no strict coda/B05 clear/full-route/all-kit claim" % [checks, failures, _expected_commit])
	quit(0 if failures == 0 else 1)
