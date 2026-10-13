extends "res://tests/act1_l2_registration_smoke.gd"
## Focused production-registration fixture for exact submitted A1-L3.
## Installation, native execution and original evidence are recorded by Root.
## Reuses only production Shell/Registry/format2/input/GUI helpers from L2.
## Prefix2 is TEST ONLY campaign metadata. Local packets are actual Full
## captures. This focused leaf covers loading, one native entrance dash,
## exact Save/Continue/earlier Retry and cleanup. Later rooms/contact/route
## and all-room optics remain separate recorded untested behavior.
## No beat/progress/entitlement/phase/clock/checkpoint/camera setter is used.

const L3_COMMIT: String = "0129e260a25405dc1e24d1869bbe607884eca430"
const L3_SCENE: String = "res://scenes/acts/act1/a1_l3.tscn"
const L3_SCRIPT: String = "res://scripts/acts/act1/mushroom_caverns_full.gd"
const L3_ACTOR: String = "res://scripts/acts/act1/mushroom_selenite.gd"
const L3_PREFIX: Array[String] = ["A1-L1", "A1-L2"]
const L3_ROOMS: Array = [
	["umbrella-1", "umbrella-2", "umbrella-3"],
	["breathing-1", "breathing-2", "breathing-3"],
	["crossed-1", "crossed-2", "crossed-3", "crossed-4", "crossed-5", "crossed-6", "crossed-7", "crossed-8"],
	["lone-guard"], ["court-1", "court-2", "court-3", "court-guard"]]
const L3_BEATS: Array[String] = ["umbrella-grove", "breathing-chamber", "crossed-grotto", "spear-pocket", "court-approach"]
const L3_THRESHOLDS: Array[float] = [13.0, 2.0, -10.0, -25.0, -38.0]
const L3_LOCAL_KEYS: Array[String] = ["authored_snapshot_version", "beat_index", "completed_beats", "room_stage", "actors", "scheduler", "fields", "consumers", "framing"]

var _restore_watch_epoch: int = 0
var _l3_option_error: String = ""
var _l3_checkpoints: Array[Dictionary] = []
var _l3_completions: Array[Dictionary] = []
var _l3_contacts: Array[Dictionary] = []
var _l3_placements: Array[Dictionary] = []
var _l3_injuries: Array[Dictionary] = []
var _l3_progress_bound: Dictionary = {}


func _initialize() -> void:
	var identity: String = "%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_test_root = "user://test-act1-l3-registration-%s/" % identity
	_capture_root = "user://test-act1-l3-registration-captures-%s/" % identity
	_expected_commit = L3_COMMIT
	var seen: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		var key: String = "--expected-commit" if argument.begins_with("--expected-commit=") else argument
		if seen.has(key): _l3_option_error = "Repeated selector: " + key
		seen[key] = true
		if argument == "--portrait": graphical = true
		elif argument.begins_with("--expected-commit="): _expected_commit = argument.trim_prefix("--expected-commit=")
		else: _l3_option_error = "Unsupported selector: " + argument
	node_added.connect(_observe_restore_node)
	create_timer(600.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "bounded L3 registration finishes within600wall seconds")
			_finish())
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if not _expect(_l3_option_error.is_empty() and _expected_commit == L3_COMMIT, "exact submitted L3 commit and bounded selectors: " + _l3_option_error): _finish(); return
	_registry_text = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var registry := Registry.new()
	var accepted: Dictionary = registry.entry("A1-L3")
	var future: Dictionary = registry.entry("A1-L4")
	if not _expect(registry.last_error.is_empty() and registry.ids().size() == 24 and accepted.get("readiness") == "accepted" and accepted.get("accepted_commit") == _expected_commit and accepted.get("scene_path") == L3_SCENE and accepted.get("previous_main_id") == "A1-L2" and accepted.get("api_revision") == "campaign-level-1" and registry.entry("A1-L2").get("readiness") == "accepted" and future.get("readiness") != "accepted" and future.get("scene_path") == null and registry.scene_error("A1-L3").is_empty(), "canonical registry exposes exact Full L3, accepted L2 prerequisite and unavailable L4: " + registry.last_error): _finish(); return
	game = _new_shell()
	await _settle()
	if not _title_valid("isolated first launch"): _finish(); return
	await _capture("title")
	await _click(_find("JourneyButton") as Control)
	await _click(_find("Act1Shortcut") as Control)
	await _click(_find("Node_A1_L3") as Control)
	var action: Button = _find("LevelCardAction") as Button
	var card: Label = _find("LevelCardBody") as Label
	if not _expect(game.menu.page_name() == "journey" and (_find("Node_A1_L3") as Button).get_meta("campaign_state") == "locked" and action != null and action.disabled and card != null and card.text.contains("A1-L2") and game.active_level == null and game.attempts.state().completed_main.is_empty(), "actual Journey locks L3 behind L2 without a live world or invented prefix"): _finish(); return
	_close_shell()
	if not await _seed_l3(registry): _finish(); return
	game = _new_shell()
	await _settle()
	if not _title_valid("declared TEST ONLY prefix2"): _finish(); return
	_watching_restore = true
	_restore_events.clear()
	await _click(_find("ContinueStoryButton") as Control)
	_watching_restore = false
	if not _actual_entry() or not _expect(_restore_events.is_empty(), "initial actual Full Continue has no gameplay delivery"): _finish(); return
	var entry: Dictionary = game.capture_campaign_snapshot()
	if not _expect(not entry.is_empty() and _initial_local(entry.level) and _valid_pair(entry) and _no_progress() and _disk_state_matches(), "source-pristine actual Full entry is one exact protected native unit"): _finish(); return
	var entry_wire: String = Exact.stringify(entry)
	if not _resume_consumed("actual L3 entry"): _finish(); return
	if not await _ready_dash() or not _swipe(Vector2(.5, .76), Vector2(.5, .48)) or not await _wait_finished_dash(1): _finish(); return
	game.request_pause()
	await _settle()
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _expect(game.campaign_error.is_empty() and paused and game.menu.page_name() == "pause" and not saved.is_empty() and _valid_pair(saved) and saved.level.local.beat_index == 0 and saved.level.local.room_stage == "active" and saved.level.local.completed_beats.is_empty() and saved.player.world_actions.sequence == 1 and saved.shell.input_sequence == 1 and not saved.level.progress.completed and saved.level.progress.checkpoint_ids.is_empty() and Exact.stringify(game.attempts.state().story.checkpoint) == entry_wire and _disk_state_matches(), "one real entrance dash saves current three-source room and protects original earlier entry: " + game.campaign_error): _finish(); return
	var saved_wire: String = Exact.stringify(saved)
	await _settle()
	if not _expect(Exact.stringify(game.capture_campaign_snapshot()) == saved_wire, "paused complete nineteen-source packet remains exact"): _finish(); return
	var retired: Array[Dictionary] = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "saved donor cleanup")
	if not await _fresh_continue(saved_wire, "actual L3 entrance save") or not _expect(_disk_state_matches(), "fresh NULL-Player Title Continue retains exact format2 payload"): _finish(); return
	retired = _old_refs()
	if not await _quiet_retry(entry_wire, "earlier source-pristine checkpoint"): _finish(); return
	_expect_refs_freed(retired, "protected earlier Retry")
	if not _expect(_initial_local(game.capture_campaign_snapshot().level) and _no_progress() and _disk_state_matches(), "Retry restores original resources/actions/clocks and dormant19 without repair"): _finish(); return
	retired = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "final exact Retry recipient cleanup")
	_expect(get_nodes_in_group("required_cues").is_empty() and get_nodes_in_group("enemies").is_empty(), "all disposed native worlds release cue/enemy groups")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_text, "canonical registry bytes unchanged by fixture")
	_finish()


func _seed_l3(registry: CinderCampaignRegistry) -> bool:
	paused = true
	var preview: Node = MainScene.instantiate()
	preview.set("level_scene_path", L3_SCENE)
	root.add_child(preview)
	paused = true
	await _settle()
	var actor: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var camera: Camera3D = preview.get("camera") as Camera3D
	if not _expect(is_instance_valid(actor) and is_instance_valid(level) and is_instance_valid(camera) and level.get_script().resource_path == L3_SCRIPT and level.scene_file_path == L3_SCENE, "TEST prefix uses actual unchanged Full alias, shared Player and native camera"):
		preview.free(); return false
	var player_state: Dictionary = actor.snapshot_state()
	var local: Dictionary = level.snapshot_state()
	var anchor: Vector2 = preview.call("get_aim_anchor_normalized")
	var shell_state: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Game.CAMERA_OFFSET), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}
	var unit: Dictionary = {"schema_version": 1, "level_id": "A1-L3", "scene_path": L3_SCENE, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": player_state, "level": local, "shell": shell_state}
	var store: CinderSaveStore = Store.new(_test_root + "campaign.json")
	var model: CinderCampaignAttempts = Attempts.new(registry, store)
	var seed: Dictionary = model.state()
	seed.completed_main = L3_PREFIX.duplicate()
	seed.story = {"kind": "story", "level_id": "A1-L3", "snapshot": unit.duplicate(true), "checkpoint": unit.duplicate(true)}
	var error: String = level.snapshot_error_with_player(local, player_state) if not local.is_empty() and not player_state.is_empty() else "Actual pristine capture unavailable"
	var accepted: bool = _expect(error.is_empty() and _initial_local(local) and model.state_error(seed).is_empty() and model.restore_session(seed) and store.write_payload(model.state()), "TEST ONLY prefix2 publishes untouched actual local/resources through Attempts/format2: " + error + "; " + model.last_error + "; " + store.last_error)
	# No test HP/ammo/loadout/pose/history writes occur in this initial unit.
	level.exit_level()
	preview.free()
	return accepted


func _actual_entry() -> bool:
	if not _expect(is_instance_valid(game) and game.campaign_error.is_empty() and paused and game.menu.page_name() == "resume" and is_instance_valid(game.active_level) and is_instance_valid(game.player), "actual L3 installation waits at paused Resume: " + game.campaign_error): return false
	var level: CinderLevel = game.active_level
	var actors: Dictionary = level.get("sources")
	var spec: Dictionary = level.call("normal_route_spec")
	if not _expect(level.level_id == "A1-L3" and level.scene_file_path == L3_SCENE and level.get_script().resource_path == L3_SCRIPT and level.hero == game.player and level.effects == game.fx and game.player.presentation_id == "act1_expedition" and level.contract_error().is_empty() and actors.size() == 19 and spec.room_sources == L3_ROOMS and spec.thresholds == L3_THRESHOLDS and spec.checkpoint_ids == L3_BEATS.slice(0,4) and spec.completion_id == "mushroom-caverns-clear" and spec.exit_id == "open-court", "actual Full owns shared expedition Player/effects, nineteen retained actors and authored five-beat contract"): return false
	for room: Array in L3_ROOMS:
		for id: String in room:
			var actor: CharacterBody3D = actors.get(id) as CharacterBody3D
			if not _expect(is_instance_valid(actor) and actor.get_parent() == level and actor.get_script().resource_path == L3_ACTOR and actor.call("get_spore_native_bindings").get("player") == game.player and actor.call("get_spore_native_bindings").get("scheduler") == level.get("scheduler") and String(actor.call("body_binding_error")).is_empty() and String(actor.call("art_binding_error")).is_empty(), "retained actual native C31/C32 aliases/body/art: " + id): return false
	return _expect(String(level.call("route_snapshot_runtime_error")).is_empty(), "Full native snapshot resources and field/protocol/controller custody remain valid")


func _initial_local(snapshot: Dictionary) -> bool:
	if snapshot.is_empty() or snapshot.get("local_snapshot_version") != 1: return false
	var local: Dictionary = snapshot.get("local", {})
	var progress: Dictionary = snapshot.get("progress", {})
	if not Codec.keys_error(local, L3_LOCAL_KEYS).is_empty() or local.get("authored_snapshot_version") != 1 or local.get("beat_index") != 0 or local.get("completed_beats") != [] or local.get("room_stage") != "approach" or not local.get("actors") is Dictionary or local.actors.size() != 19 or not local.get("scheduler") is Dictionary or local.scheduler.get("clock_s") != 0.0 or not local.scheduler.get("profile", {"invalid": true}).is_empty() or not local.scheduler.get("reservations", [1]).is_empty() or not local.get("framing", {"invalid": true}).is_empty() or progress.get("completed") != false or not progress.get("checkpoint_ids", {"invalid": true}).is_empty() or progress.get("contact_exit_id") != "": return false
	for room: Array in L3_ROOMS:
		for id: String in room:
			var actor: Dictionary = local.actors.get(id, {})
			if actor.get("dormant") != true or actor.get("dead") != false or actor.get("hp") != (24.0 if id in ["lone-guard", "court-guard"] else 16.0) or actor.get("cycle") != 0 or actor.get("reservation_id") != "": return false
	for field: Variant in local.get("fields", {}).values():
		if field != null: return false
	for consumer: Variant in local.get("consumers", {}).values():
		if consumer != null: return false
	return true


func _no_progress() -> bool:
	var state: Dictionary = game.attempts.state()
	return state.completed_main == L3_PREFIX and state.completed_optional.is_empty() and state.reward_ids.is_empty() and state.side_attempt == null and not game.active_level.is_completed()


func _fresh_continue(expected: String, label: String) -> bool:
	_restore_watch_epoch += 1
	return await super._fresh_continue(expected, label)


func _quiet_retry(expected: String, label: String) -> bool:
	_restore_watch_epoch += 1
	return await super._quiet_retry(expected, label)


func _restore_event(event: String, epoch: int) -> void:
	# A retired donor may legitimately cancel a lease during Retry. Its old
	# observer epoch is distinct from newly constructed recipient callbacks.
	if _watching_restore and epoch == _restore_watch_epoch:
		_restore_events.append(event)


func _observe_restore_node(node: Node) -> void:
	if not _watching_restore: return
	var epoch: int = _restore_watch_epoch
	if node is CinderPlayer:
		node.fired.connect(func(_kind: String) -> void: _restore_event("player.fired", epoch))
		node.died.connect(func() -> void: _restore_event("player.died", epoch))
		node.equipment_changed.connect(func(_id: String) -> void: _restore_event("player.equipment_changed", epoch))
		node.world_action_executed.connect(func(_record: Dictionary) -> void: _restore_event("player.world_action_executed", epoch))
	elif node is CinderLevel:
		node.checkpoint_requested.connect(func(_id: String, _cp: String, _kind: String) -> void: _restore_event("level.checkpoint", epoch))
		node.completion_requested.connect(func(_id: String, _completion: String) -> void: _restore_event("level.completion", epoch))
		node.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _restore_event("level.contact_exit", epoch))
	elif node.get_script() != null and node.get_script().resource_path == L3_ACTOR:
		node.connect("hit_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: _restore_event("C31/C32.hit_resolved", epoch))
		node.connect("defeated", func(_id: String) -> void: _restore_event("C31/C32.defeated", epoch))
	elif node is CinderThreatScheduler:
		node.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _restore_event("scheduler.invalidated", epoch))
	elif node is CinderSporeField:
		node.activated.connect(func(_domain: Dictionary) -> void: _restore_event("field.activated", epoch))
	elif node is CinderSporeRepulsion:
		node.reaction_started.connect(func(_id: String, _episode: String) -> void: _restore_event("consumer.reaction_started", epoch))
		node.placement_rejected.connect(func(_id: String, _reason: String) -> void: _restore_event("consumer.placement_rejected", epoch))


func _collect_refs(parent: Node, result: Array[Dictionary]) -> void:
	for child: Node in parent.get_children():
		result.append({"label": String(child.name), "ref": weakref(child)})
		_collect_refs(child,result)


func _close_shell() -> void:
	if is_instance_valid(game):
		if is_instance_valid(game.active_level): game.active_level.exit_level()
		_stop_audio(game)
		game.free()
	game = null
	paused = true


func _stop_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer3D: node.call("stop")
	for child: Node in node.get_children(): _stop_audio(child)


func _expect(condition: bool, message: String) -> bool:
	checks += 1
	if condition: print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
		if failures == 1 and is_instance_valid(game):
			print("FIRST A1-L3 REGISTRATION CONTEXT: ", {"paused": paused, "campaign_error": game.campaign_error, "menu": game.menu.page_name(), "route": game.active_level.call("route_state") if is_instance_valid(game.active_level) else {}, "player_response": game.player.get_threat_response_state() if is_instance_valid(game.player) else {}, "checkpoints": _l3_checkpoints, "completions": _l3_completions, "contacts": _l3_contacts, "test_placements": _l3_placements, "test_injuries": _l3_injuries})
	return condition


func _finish() -> void:
	if _finished: return
	_finished = true
	_close_shell()
	paused = false
	await create_timer(.2,true).timeout # Actual native audio/render disposal flush.
	_cleanup_saves()
	print("Production A1-L3 focused transport registration: %d checks, %d failures; expected_commit=%s. Actual Full Title/Journey loading/one entrance dash/Save/NULL-Player Continue/earlier Retry/cleanup. TEST prefix2; zero Hero placements or public HP injuries. Later room optics/checkpoints/completion/contact/full route/human/mobile/performance remain separate untested behavior." % [checks,failures,_expected_commit])
	quit(0 if failures == 0 else 1)
