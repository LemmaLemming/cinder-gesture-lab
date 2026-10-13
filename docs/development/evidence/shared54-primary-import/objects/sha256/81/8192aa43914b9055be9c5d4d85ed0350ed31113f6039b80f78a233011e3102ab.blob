extends "res://tests/act1_l2_registration_smoke.gd"
## UNEXECUTED ROOT DRAFT. Install only in Root's sealed isolated L4 candidate.
## All actual Shells inherit configure_runtime({}) and consume canonical Registry.
## Prefix3 is explicit TEST campaign metadata; local/Player/camera state comes
## unchanged from an actual paused native pristine L4. No resource/pose/clock,
## actor phase/HP, room/progress/contact, camera or registry setter is used.
## Scope: canonical unlock, entry, one native entrance dash/warning,
## format2 Save/fresh Continue/earlier pristine Retry and normal cleanup.
## Owner373 terminal/observer and original mechanic/portrait scopes are reused.

const L4_SUBMITTED_COMMIT: String = "9f1d6fe012e4f2859ea2a482a98260c1a226ba4a"
const L4_SCENE: String = "res://scenes/acts/act1/a1_l4.tscn"
const L4_SCRIPT: String = "res://scripts/acts/act1/selenite_court.gd"
const L4_GUARD: String = "res://scripts/acts/act1/mushroom_selenite.gd"
const L4_KING: String = "res://scripts/acts/act1/selenite_king.gd"
const L4_PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3"]
const L4_SOURCES: Array[String] = ["court-curtain-guard", "court-formation-west", "court-formation-east", "court-approach-west", "court-approach-east", "court-king", "court-helper-west", "court-helper-east"]
const L4_KEYS: Array[String] = ["api_revision", "schema_version", "world_revision", "room", "formation", "awaiting_room", "roundel_demonstrated", "helpers_once", "helper_stage", "king_intro", "entry_records", "entry_outcomes", "actors", "scheduler", "roundel", "framing"]
var _l4_option_error: String = ""
var _l4_restore_epoch: int = 0


func _initialize() -> void:
	var identity: String = "%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_test_root = "user://test-act1-l4-registration-%s/" % identity
	_expected_commit = L4_SUBMITTED_COMMIT
	var seen: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		var key: String = "--expected-commit" if argument.begins_with("--expected-commit=") else argument
		if seen.has(key): _l4_option_error = "Repeated selector: " + key
		seen[key] = true
		if argument.begins_with("--expected-commit="): _expected_commit = argument.trim_prefix("--expected-commit=")
		else: _l4_option_error = "Unsupported selector: " + argument
	node_added.connect(_observe_restore_node)
	create_timer(120.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "bounded production L4 registration finishes within120wall seconds")
			_finish())
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if not _expect(_l4_option_error.is_empty() and _expected_commit.length() == 40 and _expected_commit.is_valid_hex_number(false), "Root's exact accepted commit and bounded selectors: " + _l4_option_error): _finish(); return
	_registry_text = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var registry := Registry.new()
	var accepted: Dictionary = registry.entry("A1-L4")
	var future: Dictionary = registry.entry("A1-L5")
	if not _expect(registry.last_error.is_empty() and registry.ids().size() == 24 and accepted.get("readiness") == "accepted" and accepted.get("accepted_commit") == _expected_commit and accepted.get("scene_path") == L4_SCENE and accepted.get("previous_main_id") == "A1-L3" and accepted.get("next_main_id") == "A1-L5" and accepted.get("api_revision") == Registry.API_REVISION and registry.entry("A1-L3").get("readiness") == "accepted" and future.get("readiness") != "accepted" and future.get("scene_path") == null and registry.scene_error("A1-L4").is_empty(), "canonical registry exposes exact authored L4, accepted L3 prerequisite and unavailable L5: " + registry.last_error): _finish(); return
	game = _new_shell()
	await _settle()
	if not _title_valid("isolated first launch"): _finish(); return
	await _click(_find("JourneyButton") as Control)
	await _click(_find("Act1Shortcut") as Control)
	await _click(_find("Node_A1_L4") as Control)
	var action: Button = _find("LevelCardAction") as Button
	var node: Button = _find("Node_A1_L4") as Button
	var body: Label = _find("LevelCardBody") as Label
	if not _expect(game.menu.page_name() == "journey" and node != null and node.get_meta("campaign_state") == "locked" and action != null and action.disabled and body != null and body.text.contains("A1-L3") and game.active_level == null and game.attempts.state().completed_main.is_empty(), "actual empty Journey keeps accepted L4 locked behind L3 with no world or invented prefix"): _finish(); return
	var empty_wire: String = Exact.stringify(game.attempts.state())
	await _click(action)
	if not _expect(game.active_level == null and Exact.stringify(game.attempts.state()) == empty_wire, "disabled locked card neither installs L4 nor awards progress"): _finish(); return
	_close_shell()
	if not await _seed_l4(registry): _finish(); return
	game = _new_shell()
	await _settle()
	if not _title_valid("declared TEST ONLY prefix3"): _finish(); return
	await _click(_find("JourneyButton") as Control)
	await _click(_find("Act1Shortcut") as Control)
	await _click(_find("Node_A1_L4") as Control)
	action = _find("LevelCardAction") as Button
	node = _find("Node_A1_L4") as Button
	if not _expect(node != null and node.get_meta("campaign_state") == "current" and action != null and not action.disabled and action.text == "Continue Story" and (_find("Node_A1_L5") as Button).get_meta("campaign_state") == "locked", "TEST prefix3 exposes actual L4 Continue and retains unavailable L5 behind L4"): _finish(); return
	_l4_restore_epoch += 1
	_watching_restore = true
	_restore_events.clear()
	await _click(action)
	_watching_restore = false
	if not _actual_entry() or not _expect(_restore_events.is_empty(), "initial production Continue reconstructs quietly without gameplay delivery"): _finish(); return
	var entry: Dictionary = game.capture_campaign_snapshot()
	if not _expect(not entry.is_empty() and _initial_local(entry.level) and _valid_pair(entry) and _no_progress() and _disk_state_matches(), "actual pristine court is one exact protected native Player/world/Shell unit"): _finish(); return
	var entry_wire: String = Exact.stringify(entry)
	if not _expect(Exact.stringify(game.attempts.state().story.checkpoint) == entry_wire, "production Continue protects actual earlier pristine entry"): _finish(); return
	if not _resume_consumed("actual L4 entry") or not await _ready_dash() or not _swipe(Vector2(.5, .76), Vector2(.35, .76)) or not await _wait_finished_dash(1): _finish(); return
	if not await _entrance_warning(): _finish(); return
	game.request_pause()
	await _settle()
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _expect(game.campaign_error.is_empty() and paused and game.menu.page_name() == "pause" and not saved.is_empty() and _valid_pair(saved) and saved.level.local.room == 0 and not saved.level.local.actors["court-curtain-guard"].reservation_id.is_empty() and saved.player.world_actions.sequence == 1 and saved.shell.input_sequence == 1 and saved.player.world_actions.clock_s > entry.player.world_actions.clock_s and saved.level.local.scheduler.clock_s > 0.0 and not saved.level.progress.completed and saved.level.progress.checkpoint_ids.is_empty() and Exact.stringify(game.attempts.state().story.checkpoint) == entry_wire and _no_progress() and _disk_state_matches(), "one genuine entrance dash plus warning Pause publishes exact format2 and protects pristine Retry: " + game.campaign_error): _finish(); return
	var saved_wire: String = Exact.stringify(saved)
	await _settle()
	if not _expect(Exact.stringify(game.capture_campaign_snapshot()) == saved_wire, "paused production warning keeps complete actor/local/input/camera bytes exact"): _finish(); return
	var retired: Array[Dictionary] = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "saved donor cleanup")
	if not await _fresh_continue(saved_wire, "actual L4 entrance warning") or not _expect(_disk_state_matches(), "fresh disk Continue preserves exact warning format2 payload"): _finish(); return
	retired = _old_refs()
	if not await _quiet_retry(entry_wire, "earlier actual pristine court"): _finish(); return
	_expect_refs_freed(retired, "protected earlier Retry")
	if not _expect(_initial_local(game.capture_campaign_snapshot().level) and _no_progress() and _disk_state_matches(), "Retry restores exact earlier resources/actions/clocks/eight native sources without repair"): _finish(); return
	retired = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "final exact Retry recipient cleanup")
	_expect(get_nodes_in_group("required_cues").is_empty() and get_nodes_in_group("enemies").is_empty(), "disposed production worlds release cue/enemy groups")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_text, "fixture leaves production registry bytes unchanged")
	_finish()


func _seed_l4(registry: CinderCampaignRegistry) -> bool:
	paused = true
	var preview: Node = MainScene.instantiate()
	preview.set("level_scene_path", L4_SCENE)
	root.add_child(preview)
	paused = true
	await _settle()
	var actor: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var camera: Camera3D = preview.get("camera") as Camera3D
	if not _expect(is_instance_valid(actor) and is_instance_valid(level) and is_instance_valid(camera) and level.get_script().resource_path == L4_SCRIPT and level.scene_file_path == L4_SCENE, "TEST prefix3 captures unchanged actual native court/Player/camera"):
		preview.free(); return false
	var player_state: Dictionary = actor.snapshot_state()
	var local: Dictionary = level.snapshot_state()
	var anchor: Vector2 = preview.call("get_aim_anchor_normalized")
	var shell_state: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Game.CAMERA_OFFSET), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}
	var unit: Dictionary = {"schema_version": 1, "level_id": "A1-L4", "scene_path": L4_SCENE, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": player_state, "level": local, "shell": shell_state}
	var store: CinderSaveStore = Store.new(_test_root + "campaign.json")
	var model: CinderCampaignAttempts = Attempts.new(registry, store)
	var seed: Dictionary = model.state()
	seed.completed_main = L4_PREFIX.duplicate()
	seed.story = {"kind": "story", "level_id": "A1-L4", "snapshot": unit.duplicate(true), "checkpoint": unit.duplicate(true)}
	var error: String = level.snapshot_error_with_player(local, player_state) if not local.is_empty() and not player_state.is_empty() else "Actual pristine capture unavailable"
	var accepted: bool = _expect(error.is_empty() and _initial_local(local) and player_state.world_actions.sequence == 0 and player_state.world_actions.clock_s == 0.0 and model.state_error(seed).is_empty() and model.restore_session(seed) and store.write_payload(model.state()), "TEST ONLY prefix3 publishes untouched actual local/resources through Attempts/format2: " + error + "; " + model.last_error + "; " + store.last_error)
	# Only campaign predecessor metadata is arranged. No local/Player value is edited.
	var actor_ref: WeakRef = weakref(actor)
	var level_ref: WeakRef = weakref(level)
	level.exit_level()
	_stop_l4_audio(preview)
	preview.free()
	return accepted and _expect(actor_ref.get_ref() == null and level_ref.get_ref() == null, "actual pristine preview retires before production Shell construction")


func _actual_entry() -> bool:
	if not _expect(is_instance_valid(game) and game.campaign_error.is_empty() and paused and game.menu.page_name() == "resume" and is_instance_valid(game.active_level) and is_instance_valid(game.player), "production L4 waits at real paused Resume: " + game.campaign_error): return false
	var level: CinderLevel = game.active_level
	var actors: Dictionary = level.get("sources")
	if not _expect(level.level_id == "A1-L4" and level.scene_file_path == L4_SCENE and level.get_script().resource_path == L4_SCRIPT and level.hero == game.player and level.shared_shell == game and level.effects == game.fx and game.player.presentation_id == "act1_expedition" and level.contract_error().is_empty() and Codec.keys_error(actors, L4_SOURCES).is_empty(), "production court retains exact identity/shared Player/Shell/effects and eight sources"): return false
	for id: String in L4_SOURCES:
		var actor: CharacterBody3D = actors[id]
		var native: Dictionary = actor.call("get_court_native_bindings" if id == "court-king" else "get_spore_native_bindings")
		if not _expect(actor.get_parent() == level and actor.get_script().resource_path == (L4_KING if id == "court-king" else L4_GUARD) and native.get("player") == game.player and native.get("scheduler") == level.get("scheduler") and actor.get_world_3d() == game.player.get_world_3d() and String(actor.call("art_binding_error")).is_empty(), "actual retained actor/body/world/art alias: " + id): return false
	return _expect(String(level.call("_native_runtime_error")).is_empty(), "actual court retains native floor/contact/scenery/configuration custody")


func _initial_local(snapshot: Dictionary) -> bool:
	if snapshot.is_empty() or snapshot.get("local_snapshot_version") != 2: return false
	var local: Dictionary = snapshot.get("local", {})
	var progress: Dictionary = snapshot.get("progress", {})
	if not Codec.keys_error(local, L4_KEYS).is_empty() or local.api_revision != "act1-court-aggregate-2" or local.schema_version != 2 or local.world_revision != 2 or local.room != 0 or local.formation != "parallel" or local.awaiting_room != -1 or local.roundel_demonstrated or local.helpers_once or local.helper_stage != "unborn" or local.king_intro != {"stage": "unborn", "record": {}, "outcome": {}} or not local.entry_records.is_empty() or not local.entry_outcomes.is_empty() or local.scheduler.clock_s != 0.0 or not local.scheduler.reservations.is_empty() or not local.framing.is_empty() or not Codec.keys_error(local.actors, L4_SOURCES).is_empty() or progress.get("completed") != false or not progress.get("checkpoint_ids", {"invalid": true}).is_empty() or progress.get("contact_exit_id") != "": return false
	for id: String in L4_SOURCES:
		var actor: Dictionary = local.actors[id]
		if actor.dead or actor.hp != actor.configuration.raw_role.max_hp or actor.cycle != 0 or actor.reservation_id != "" or actor.dormant != (id != "court-curtain-guard"): return false
	return true


func _entrance_warning() -> bool:
	var deadline: int = Time.get_ticks_msec() + 8000
	while not _finished and Time.get_ticks_msec() <= deadline:
		if not is_instance_valid(game) or not is_instance_valid(game.player) or paused or game.player.dead or not game.campaign_error.is_empty(): return _expect(false, "native entrance warning retains live unpaused original world")
		var actor: CharacterBody3D = game.active_level.get("sources")["court-curtain-guard"]
		var state: Dictionary = actor.call("pure_presentation_state")
		if state.phase == "warning" and not String(state.reservation_id).is_empty(): return true
		await process_frame
	return _expect(false, "actual entrance warning is observed within bounded8wall seconds")


func _no_progress() -> bool:
	var state: Dictionary = game.attempts.state()
	return state.completed_main == L4_PREFIX and state.completed_optional.is_empty() and state.reward_ids.is_empty() and state.side_attempt == null and (not is_instance_valid(game.active_level) or not game.active_level.is_completed())


func _fresh_continue(expected: String, label: String) -> bool:
	_l4_restore_epoch += 1
	return await super._fresh_continue(expected, label)


func _quiet_retry(expected: String, label: String) -> bool:
	_l4_restore_epoch += 1
	return await super._quiet_retry(expected, label)


func _l4_restore_event(event: String, epoch: int) -> void:
	if _watching_restore and epoch == _l4_restore_epoch: _restore_events.append(event)


func _observe_restore_node(node: Node) -> void:
	if not _watching_restore: return
	var epoch: int = _l4_restore_epoch
	if node is CinderPlayer:
		node.fired.connect(func(_kind: String) -> void: _l4_restore_event("player.fired", epoch))
		node.died.connect(func() -> void: _l4_restore_event("player.died", epoch))
		node.equipment_changed.connect(func(_id: String) -> void: _l4_restore_event("player.equipment_changed", epoch))
		node.world_action_executed.connect(func(_record: Dictionary) -> void: _l4_restore_event("player.world_action_executed", epoch))
	elif node is CinderLevel:
		node.checkpoint_requested.connect(func(_id: String, _cp: String, _kind: String) -> void: _l4_restore_event("level.checkpoint", epoch))
		node.completion_requested.connect(func(_id: String, _completion: String) -> void: _l4_restore_event("level.completion", epoch))
		node.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _l4_restore_event("level.contact_exit", epoch))
	elif node.get_script() != null and node.get_script().resource_path in [L4_GUARD, L4_KING]:
		node.connect("hit_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: _l4_restore_event("native.hit_resolved", epoch))
		node.connect("defeated", func(_id: String) -> void: _l4_restore_event("native.defeated", epoch))
	elif node is CinderThreatScheduler:
		node.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _l4_restore_event("scheduler.invalidated", epoch))
	elif node is CinderLaneMechanism:
		node.hit_resolved.connect(func(_id: String, _cycle: int, _result: Dictionary) -> void: _l4_restore_event("lane.hit_resolved", epoch))


func _collect_refs(parent: Node, result: Array[Dictionary]) -> void:
	for child: Node in parent.get_children():
		result.append({"label": String(child.name), "ref": weakref(child)})
		_collect_refs(child, result)


func _close_shell() -> void:
	if is_instance_valid(game):
		if is_instance_valid(game.active_level): game.active_level.exit_level()
		_stop_l4_audio(game)
		game.free()
	game = null
	paused = true


func _stop_l4_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer3D: node.call("stop")
	for child: Node in node.get_children(): _stop_l4_audio(child)


func _finish() -> void:
	if _finished: return
	_finished = true
	_close_shell()
	paused = false
	_cleanup_saves()
	print("Production Act1 L4 registration: %d checks, %d failures; expected_commit=%s; scope=canonical unlock/actual entry/one dash/warning Save/fresh Continue/pristine Retry/cleanup; TEST prefix3 only; no earned route/terminal rerun/new portrait" % [checks, failures, _expected_commit])
	quit(0 if failures == 0 else 1)
