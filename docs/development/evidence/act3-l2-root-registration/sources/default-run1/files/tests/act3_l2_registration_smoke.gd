extends SceneTree
## Production Registry/Title/Journey/format2 lifecycle for the installed A3-L2 HANDOFF.
## Defaults to the exact accepted HANDOFF; --expected-commit may assert it. No metadata is
## injected. The eleven-predecessor prefix and fresh low HP/empty ammo are TEST ONLY
## isolated public seed data, not evidence of predecessor gameplay or a clear.
## All later movement/contact/death/checkpoints are actual routed input/physics.
## Installation and execution provenance are recorded by integration.
## Default --portrait captures four native menu/arrival frames; --fatal-only
## --portrait captures four actual checkpoint/warning/deadContinue/Retry frames.
## --journey-only stops before production entry and captures three menu frames.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const Game = preload("res://scripts/game.gd")
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Attempts = preload("res://scripts/campaign/attempts.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const ACCEPTED_COMMIT: String = "bd6b3cde9321213a2717e998c5ce2dff58ca2dd3"
const LEVEL_PATH: String = "res://scenes/acts/act3/a3_l2_living_forest.tscn"
const RUNTIME_PATH: String = "res://scripts/acts/act3/living_forest_level.gd"
const FIRST_CHECKPOINT: String = "forest-threshold-entry"
const SOURCE_IDS: Array[String] = ["l2-threshold-stalker", "l2-promise-root", "l2-trunk-root", "l2-priority-root", "l2-priority-stalker", "l2-watched-root", "l2-watched-stalker", "l2-slit-root", "l2-slit-stalker"]
const SOURCE_KINDS: Dictionary = {"l2-threshold-stalker": "stalker", "l2-promise-root": "root", "l2-trunk-root": "root", "l2-priority-root": "root", "l2-priority-stalker": "stalker", "l2-watched-root": "root", "l2-watched-stalker": "stalker", "l2-slit-root": "root", "l2-slit-stalker": "stalker"}
const FIXTURE_PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3", "A1-L4", "A1-L5", "A2-L1", "A2-L2", "A2-L3", "A2-L4", "A2-L5", "A3-L1"]
const ROUTE_DASH_BOUND: int = 10
const FATAL_WAIT_S: float = 18.0

var checks: int = 0
var failures: int = 0
var game: CinderCampaignShell
var graphical: bool = false
var _finished: bool = false
var _expected_commit: String = ACCEPTED_COMMIT
var _test_root: String = ""
var _capture_root: String = ""
var _registry_text: String = ""
var _watching_restore: bool = false
var _restore_watch_epoch: int = 0
var _restore_events: Array[String] = []
var _contacts: Array[Dictionary] = []
var _checkpoint_events: Array[Dictionary] = []
var _deaths: int = 0
var _fatal_only: bool = false
var _journey_only: bool = false
var _option_error: String = ""
var _captures: Array[String] = []


func _initialize() -> void:
	var identity: String = "%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_test_root = "user://test-act3-l2-registration-%s/" % identity
	_capture_root = "user://test-act3-l2-registration-captures-%s/" % identity
	var seen: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		var key: String = "--expected-commit" if argument.begins_with("--expected-commit=") else argument
		if seen.has(key):
			_option_error = "Repeated registration selector: " + key
		seen[key] = true
		if argument == "--portrait":
			graphical = true
		elif argument == "--fatal-only":
			_fatal_only = true
		elif argument == "--journey-only":
			_journey_only = true
		elif argument.begins_with("--expected-commit="):
			_expected_commit = argument.trim_prefix("--expected-commit=")
		else:
			_option_error = "Unsupported registration selector: " + argument
	if _fatal_only and _journey_only:
		_option_error = "Select one bounded registration scope"
	node_added.connect(_observe_restore_node)
	create_timer(180.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "production A3-L2 registration completes within its watchdog")
			_finish())
	_run.call_deferred()


func _run() -> void:
	if not _expect(_option_error.is_empty(), "registration selectors are explicit and bounded: " + _option_error):
		_finish()
		return
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if not _expect(_expected_commit.length() == 40 and _expected_commit.is_valid_hex_number(false), "fixture asserts exact accepted HANDOFF provenance (optional --expected-commit=<40hex>)"):
		_finish()
		return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--level-scene") or argument in ["--capture", "--capture-polish"]:
			_expect(false, "registration fixture does not select the historical preview shell")
			_finish()
			return
	_registry_text = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var registry := Registry.new()
	var accepted: Dictionary = registry.entry("A3-L2")
	var prerequisite: Dictionary = registry.entry("A3-L1")
	var future: Dictionary = registry.entry("A3-L3")
	if not _expect(registry.last_error.is_empty() and registry.ids().size() == 24 and accepted.get("readiness") == "accepted" and accepted.get("accepted_commit") == _expected_commit and accepted.get("scene_path") == LEVEL_PATH and accepted.get("api_revision") == "campaign-level-1" and accepted.get("previous_main_id") == "A3-L1" and prerequisite.get("readiness") == "accepted" and future.get("readiness") != "accepted" and future.get("scene_path") == null and registry.scene_error("A3-L2").is_empty(), "actual production registry validates exact Living Forest provenance, accepted L1 prerequisite and unexposed L3: " + registry.last_error):
		_finish()
		return
	if _fatal_only:
		await _fatal_case(registry)
		_finish()
		return
	game = _new_shell()
	await _settle()
	if not _title_valid("isolated first launch"):
		_finish()
		return
	_expect(game.attempts.state().completed_main.is_empty(), "first launch invents no prior story progress")
	await _capture("title-locked")
	await _click(_find("JourneyButton") as Control)
	await _click(_find("Act3Shortcut") as Control)
	await _click(_find("Node_A3_L2") as Control)
	var action: Button = _find("LevelCardAction") as Button
	var node: Button = _find("Node_A3_L2") as Button
	if not _expect(game.menu.page_name() == "journey" and node != null and node.get_meta("campaign_state") == "locked" and action != null and action.disabled and (_find("LevelCardBody") as Label).text.contains("A3-L1"), "real Journey keeps accepted A3-L2 locked behind its actual A3-L1 prerequisite"):
		_finish()
		return
	await _capture("journey-locked")
	var empty_model: String = Exact.stringify(game.attempts.state())
	await _click(action)
	_expect(game.active_level == null and Exact.stringify(game.attempts.state()) == empty_model, "disabled locked card neither loads A3 nor fabricates progression")
	_close_shell()
	if not await _seed_actual_story(registry, 37.0):
		_finish()
		return
	game = _new_shell()
	await _settle()
	if not _title_valid("TEST ONLY eleven-predecessor story seed"):
		_finish()
		return
	_expect(_no_progress() and not (_find("ContinueStoryButton") as Button).disabled, "TEST ONLY eleven-predecessor prefix offers protected uncompleted A3 story Continue")
	await _click(_find("JourneyButton") as Control)
	await _click(_find("Act3Shortcut") as Control)
	await _click(_find("Node_A3_L2") as Control)
	action = _find("LevelCardAction") as Button
	node = _find("Node_A3_L2") as Button
	if not _expect(node != null and node.get_meta("campaign_state") == "current" and action != null and not action.disabled and action.text == "Continue Story" and (_find("Node_A3_L3") as Button).get_meta("campaign_state") == "locked", "real seeded Journey offers current A3-L2 Continue while A3-L3 stays locked"):
		_finish()
		return
	await _capture("journey-seeded")
	if _journey_only:
		_close_shell()
		_finish()
		return
	await _click(action)
	if not _actual_entry():
		_finish()
		return
	var entry: Dictionary = game.capture_campaign_snapshot()
	if not _expect(not entry.is_empty() and entry.level.local_snapshot_version == 1 and _valid_pair(entry), "actual accepted full localversion1 entry is a coherent actor/nine-typed-source/scheduler/shell unit"):
		_finish()
		return
	_expect(game.player.hp == 37.0 and game.player.shells == 0 and entry.player.world_actions.clock_s == 0.0 and entry.player.world_actions.sequence == 0 and entry.shell.input_sequence == 0, "fresh TEST ONLY initial resources retain no executed action/input/tick")
	_expect(_disk_state_matches(), "entry reopens actual checked format2 SaveStore data")
	var entry_encoded: String = Exact.stringify(entry)
	if not _resume_consumed("initial living entry"):
		_finish()
		return
	await _capture("arrival")
	if not await _ready_dash() or not await _swipe(Vector2(0.55, 0.72), Vector2(0.36, 0.72)) or not await _wait_finished_dash(1):
		_finish()
		return
	game.request_pause()
	await _settle()
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _expect(game.campaign_error.is_empty() and paused and game.menu.page_name() == "pause" and not saved.is_empty() and _valid_pair(saved), "public deferred pause captures the actual routed movement and complete authored world: " + game.campaign_error):
		_finish()
		return
	var saved_encoded: String = Exact.stringify(saved)
	var dash: Dictionary = game.player.get_world_action_records()[0]
	var size: Vector2 = root.get_visible_rect().size
	var actual_release_anchor: Vector2 = (Vector2(0.36, 0.72) * size) / size
	_expect(dash.kind == "dash" and dash.path.size() >= 2 and dash.completed_at_s > dash.started_at_s and saved.player.world_actions.sequence == 1 and game.get_aim_anchor_normalized() == actual_release_anchor, "real routed release retains physical dash path and separate exact screen release anchor")
	_expect(saved_encoded != entry_encoded and saved.player.world_actions.clock_s > 0.0 and saved.level.local.scheduler.clock_s > 0.0 and saved.shell.camera_focus != entry.shell.camera_focus, "live dash changes actual path/clocks/camera before the save")
	_expect(saved.player.resources.hp == 37.0 and saved.player.resources.shells == 0 and saved.equipment_ids == entry.equipment_ids and saved.shell.input_sequence == 1, "short actual movement preserves low HP/empty ammo/gear and one routed input")
	_expect(Exact.stringify(game.attempts.active_snapshot()) == saved_encoded and Exact.stringify(game.attempts.state().story.checkpoint) == entry_encoded and _no_progress(), "coherent movement save protects its initial checkpoint and awards no A3 completion/reward")
	_expect(_disk_state_matches(), "actual pause publishes an exact checked format2 generation")
	await _settle()
	_expect(Exact.stringify(game.capture_campaign_snapshot()) == saved_encoded, "paused frames freeze complete actor/local/input/camera state exactly")
	var retired: Array[Dictionary] = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "first shell closure")
	if not await _fresh_continue(saved_encoded, "living saved movement"):
		_finish()
		return
	_expect(game.player.hp == saved.player.resources.hp and game.player.shells == saved.player.resources.shells and game.player.get_world_action_records().size() == 1, "fresh Continue preserves actual resources and does not republish the past dash")
	retired = _old_refs()
	if not await _quiet_retry(entry_encoded, "initial living checkpoint"):
		_finish()
		return
	_expect_refs_freed(retired, "living GUI Retry")
	_expect(game.player.hp == 37.0 and game.player.shells == 0 and game.player.get_world_action_records().is_empty() and _no_progress() and _disk_state_matches(), "Retry uses exact checkpoint resources/history without healing or invented progress")
	retired = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "living retry closure")
	_cleanup_saves()
	if not await _fatal_case(registry):
		_finish()
		return
	_expect(get_nodes_in_group("required_cues").is_empty() and get_nodes_in_group("enemies").is_empty(), "disposed production worlds retain no required cue or actor group member")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_text, "registration fixture leaves production registry bytes unchanged")
	_finish()


func _fatal_case(registry: CinderCampaignRegistry) -> bool:
	# Only the fresh paused initial actor is seeded. Natural reload during the
	# subsequent route is legitimate and is retained in checkpoint/fatal units.
	if not await _seed_actual_story(registry, 0.1):
		return false
	game = _new_shell()
	await _settle()
	if not _title_valid("fatal branch initial TEST ONLY HP0.1/zeroammo"):
		return false
	await _click(_find("ContinueStoryButton") as Control)
	if not _actual_entry():
		return false
	_expect(game.player.hp == 0.1 and game.player.shells == 0, "fatal branch starts from quiet public initial lowHP/zeroammo seed")
	_contacts.clear()
	_checkpoint_events.clear()
	_deaths = 0
	game.player.died.connect(func() -> void: _deaths += 1)
	game.active_level.checkpoint_requested.connect(func(id: String, checkpoint: String, boundary: String) -> void:
		_checkpoint_events.append({"level_id": id, "checkpoint_id": checkpoint, "boundary": boundary, "paused": paused, "physics_frame": Engine.is_in_physics_frame()}))
	var sources: Dictionary = game.active_level.get("sources")
	for id: String in SOURCE_IDS:
		if SOURCE_KINDS[id] == "stalker":
			sources[id].connect("hit_resolved", _on_contact.bind(id))
	if not _resume_consumed("fatal branch living entry"):
		return false
	var routed: int = 0
	# Bounded source-dependent seam: current authored spawn z43, first entry z38.
	# The first root run after exact HANDOFF must confirm these frozen bytes; a
	# changed route/contact fails visibly rather than injecting a phase or pose.
	for step: int in range(ROUTE_DASH_BOUND):
		if _first_checkpoint_exists():
			break
		if not await _ready_dash() or not await _swipe(Vector2(0.56, 0.68), Vector2(0.56, 0.38)):
			return false
		routed += 1
		if not await _wait_route_step(routed):
			return false
	if not _expect(_first_checkpoint_exists() and _checkpoint_events.size() == 1 and _checkpoint_events[0].level_id == "A3-L2" and _checkpoint_events[0].checkpoint_id == FIRST_CHECKPOINT and _checkpoint_events[0].boundary == "encounter" and not _checkpoint_events[0].paused and _checkpoint_events[0].physics_frame, "real forward entry requests its checkpoint inside the still-unpaused full native tick"):
		return false
	game.request_pause()
	await _settle()
	var checkpoint: Dictionary = game.attempts.state().story.checkpoint.duplicate(true)
	if not _expect(checkpoint.player.resources.hp == 0.1 and not checkpoint.player.resources.dead and not checkpoint.player.world_actions.pending_dash.is_empty() and checkpoint.level.local.route.entries.size() == 1 and checkpoint.level.local.route.deaths.is_empty() and _valid_pair(checkpoint), "protected first entry retains its true unfinished dash, living lowHP and exact paired source state"):
		return false
	if _fatal_only:
		await _capture("fatal-living-checkpoint")
	if paused:
		await _settle()
		if paused and not _resume_consumed("actual first-entry checkpoint"):
			return false
	var scheduler: Node = game.active_level.get("threat_scheduler") as Node
	var deadline: float = float(scheduler.call("get_clock")) + FATAL_WAIT_S
	var warning_captured: bool = false
	var real_armed_seen: bool = false
	for tick: int in range(int(ceilf(FATAL_WAIT_S * Engine.physics_ticks_per_second)) + 120):
		if game.player.dead:
			break
		if paused or not game.campaign_error.is_empty() or float(scheduler.call("get_clock")) >= deadline:
			break
		var first: Dictionary = sources[SOURCE_IDS[0]].call("state")
		if first.get("phase") in ["warning", "lock", "active"] and not String(first.get("reservation_id", "")).is_empty():
			var lease: Dictionary = scheduler.call("reservation_state", first.reservation_id)
			real_armed_seen = real_armed_seen or (lease.get("armed") == true and lease.get("adapter", {}).get("kind") == "lunge")
			if graphical and _fatal_only and not warning_captured and first.phase in ["warning", "lock"]:
				warning_captured = true
				await _capture("fatal-first-warning")
		await physics_frame
		await process_frame
	var accepted_contacts: Array[Dictionary] = []
	for contact: Dictionary in _contacts:
		if contact.result.get("accepted") == true and float(contact.result.get("hp_damage", 0.0)) > 0.0:
			accepted_contacts.append(contact)
	if not _expect(game.player.dead and _deaths == 1 and real_armed_seen and accepted_contacts.size() == 1 and accepted_contacts[0].source_id == SOURCE_IDS[0] and accepted_contacts[0].result.get("opportunity_consumed") == true and accepted_contacts[0].result.get("impulse") == Vector3.ZERO, "bounded stationary wait receives actual admitted first Stalker contact/death, without forced HP/phase/damage: " + str(_contacts)):
		return false
	await _settle()
	var fatal: Dictionary = game.capture_campaign_snapshot()
	if not _expect(paused and game.menu.page_name() == "pause" and game.campaign_error.is_empty() and not fatal.is_empty() and fatal.player.resources.dead and fatal.player.resources.hp == 0.0 and _valid_pair(fatal), "real fatal callback settles and saves a coherent paused dead actor/source/local unit: " + game.campaign_error):
		return false
	var fatal_encoded: String = Exact.stringify(fatal)
	var only_dashes: bool = true
	for record: Dictionary in game.player.get_world_action_records():
		only_dashes = only_dashes and record.kind == "dash"
	_expect(only_dashes and fatal.level.local.sources[SOURCE_IDS[0]].actor.hit_consumed and fatal.level.local.route.deaths.is_empty(), "fatal branch consumes real enemy contact without a player attack, source death or replayed hit")
	_expect(Exact.stringify(game.attempts.active_snapshot()) == fatal_encoded and Exact.stringify(game.attempts.state().story.checkpoint) == Exact.stringify(checkpoint) and _disk_state_matches() and _no_progress(), "fatal format2 save retains its real earlier living checkpoint and no manufactured completion")
	var retired: Array[Dictionary] = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "fatal shell closure")
	if not await _fresh_continue(fatal_encoded, "actual fatal saved unit"):
		return false
	if _fatal_only:
		await _capture("fatal-continued-dead")
	var dead_before: String = Exact.stringify(game.capture_campaign_snapshot())
	var disk_before: String = FileAccess.get_file_as_string(_test_root + "campaign.json")
	_restore_events.clear()
	_watching_restore = true
	_click_immediate(_find("ResumeButton") as Control)
	await _settle()
	_watching_restore = false
	var dead_notice: Label = _find("MenuStatus") as Label
	_expect(paused and game.player.dead and game.menu.page_name() == "pause" and dead_notice != null and dead_notice.text == "Retry your saved checkpoint." and Exact.stringify(game.capture_campaign_snapshot()) == dead_before and FileAccess.get_file_as_string(_test_root + "campaign.json") == disk_before and _restore_events.is_empty(), "actual dead GUI Resume offers checkpoint Retry while preserving exact paused fatal resources/clocks/history/input/camera/disk without gameplay callbacks")
	retired = _old_refs()
	if not await _quiet_retry(Exact.stringify(checkpoint), "fatal world's actual unfinished-dash checkpoint"):
		return false
	_expect_refs_freed(retired, "fatal GUI Retry")
	_expect(not game.player.dead and game.player.hp == checkpoint.player.resources.hp and game.player.shells == checkpoint.player.resources.shells and not game.player.snapshot_state().world_actions.pending_dash.is_empty() and _no_progress() and _disk_state_matches(), "fatal Retry restores exact living checkpoint HP/ammo and pending dash without healing or past delivery")
	await _settle()
	_expect(Exact.stringify(game.capture_campaign_snapshot()) == Exact.stringify(checkpoint), "retried unfinished dash/source clocks remain exactly paused before any continuation tick")
	if _fatal_only:
		await _capture("fatal-living-retry")
	var resumed_records: Array[Dictionary] = []
	game.player.world_action_executed.connect(func(record: Dictionary) -> void: resumed_records.append(record.duplicate(true)))
	var history_size: int = checkpoint.player.world_actions.history.size()
	var expected_sequence: int = int(checkpoint.player.world_actions.sequence) + 1
	if not _resume_consumed("retried original unfinished dash") or not await _wait_finished_dash(expected_sequence):
		return false
	game.request_pause()
	await _settle()
	var resumed: Dictionary = game.capture_campaign_snapshot()
	if not _expect(not resumed.is_empty() and _valid_pair(resumed) and resumed_records.size() == 1 and resumed_records[0].kind == "dash" and int(resumed_records[0].sequence) == expected_sequence and resumed.player.world_actions.history.size() == history_size + 1 and resumed.player.world_actions.pending_dash.is_empty() and resumed.player.resources.hp == checkpoint.player.resources.hp and Exact.stringify(game.attempts.state().story.checkpoint) == Exact.stringify(checkpoint) and _disk_state_matches() and _no_progress(), "real Resume finishes the original saved dash once, preserving living HP and the earlier checkpoint without regrant or delivery"):
		return false
	retired = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "fatal retry closure")
	return true


func _seed_actual_story(registry: CinderCampaignRegistry, initial_hp: float) -> bool:
	paused = true
	var preview: Node = MainScene.instantiate()
	preview.set("level_scene_path", LEVEL_PATH)
	root.add_child(preview)
	paused = true
	await _settle()
	var actor: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var camera: Camera3D = preview.get("camera") as Camera3D
	if not _expect(is_instance_valid(actor) and is_instance_valid(level) and level.get_script().resource_path == RUNTIME_PATH, "TEST ONLY seed captures actual authored full runtime, not historical Living Forest preview"):
		preview.free()
		return false
	var initial: Dictionary = actor.snapshot_state()
	if initial.is_empty():
		_expect(false, "actual quiet initial actor snapshot is available: " + actor.last_snapshot_error)
		level.exit_level()
		preview.free()
		return false
	initial.resources.hp = initial_hp
	initial.resources.shells = 0
	var accepted: bool = actor.restore_state(initial)
	_expect(accepted, "TEST ONLY initial HP/zeroammo seed uses validated quiet public actor restore")
	var player_state: Dictionary = actor.snapshot_state()
	var local: Dictionary = level.snapshot_state()
	var anchor: Vector2 = preview.call("get_aim_anchor_normalized")
	var shell_state: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Game.CAMERA_OFFSET), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}
	var aggregate: Dictionary = {"schema_version": 1, "level_id": "A3-L2", "scene_path": LEVEL_PATH, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": player_state, "level": local, "shell": shell_state}
	var store: CinderSaveStore = Store.new(_test_root + "campaign.json")
	var model: CinderCampaignAttempts = Attempts.new(registry, store)
	var seed: Dictionary = model.state()
	seed["completed_main"] = FIXTURE_PREFIX.duplicate()
	seed["story"] = {"kind": "story", "level_id": "A3-L2", "snapshot": aggregate.duplicate(true), "checkpoint": aggregate.duplicate(true)}
	var error: String = level.snapshot_error_with_player(local, player_state) if not local.is_empty() and not player_state.is_empty() else "Actual paused scene capture failed"
	accepted = accepted and error.is_empty() and model.state_error(seed).is_empty() and model.restore_session(seed) and store.write_payload(model.state())
	_expect(accepted, "TEST ONLY eleven-predecessor prefix/actual initial A3 unit writes through public attempts/store: " + error + " " + model.last_error + " " + store.last_error)
	_expect(actor.presentation_id == "act3_traveller" and actor.get_world_action_records().is_empty() and not local.is_empty() and local.local_snapshot_version == 1 and local.local.scheduler.clock_s == 0.0 and local.local.route.entries.is_empty(), "seed retains unchanged initial full A3 world/presentation with no entered source or executed action")
	var actor_ref: WeakRef = weakref(actor)
	var level_ref: WeakRef = weakref(level)
	level.exit_level()
	preview.free()
	_expect(actor_ref.get_ref() == null and level_ref.get_ref() == null, "seed preview actor/level retire before production installation")
	print("TEST ONLY prefix/resource seed: ", FIXTURE_PREFIX, "; HP=", initial_hp, "; initial shells=0; not predecessor gameplay or A3 clear evidence")
	return accepted


func _fresh_continue(expected: String, label: String) -> bool:
	_restore_events.clear()
	_restore_watch_epoch += 1
	_watching_restore = true
	game = _new_shell()
	await _settle()
	if not _title_valid(label):
		_watching_restore = false
		return false
	await _click(_find("ContinueStoryButton") as Control)
	_watching_restore = false
	return _actual_entry() and _expect(Exact.stringify(game.capture_campaign_snapshot()) == expected and _restore_events.is_empty(), "fresh actual GUI Continue restores exact " + label + " without gameplay callbacks: " + str(_restore_events))


func _quiet_retry(expected: String, label: String) -> bool:
	if game.menu.page_name() == "resume":
		game.request_pause()
		await _settle()
	_restore_events.clear()
	_restore_watch_epoch += 1
	_watching_restore = true
	await _click(_find("RetryButton") as Control)
	_watching_restore = false
	return _actual_entry() and _expect(Exact.stringify(game.capture_campaign_snapshot()) == expected and _restore_events.is_empty(), "actual GUI Retry restores exact " + label + " without gameplay callbacks: " + str(_restore_events))


func _new_shell() -> CinderCampaignShell:
	var result: CinderCampaignShell = Shell.new()
	_expect(result.configure_runtime({}, _test_root + "campaign.json", _test_root + "settings.json", _test_root + "preferences.json"), "production registry configures only isolated PID user paths")
	root.add_child(result)
	return result


func _title_valid(label: String) -> bool:
	return _expect(game.campaign_error.is_empty() and paused and game.active_level == null and game.menu.page_name() == "title", "real production Title has no duplicate live world for " + label + ": " + game.campaign_error)


func _actual_entry() -> bool:
	if not _expect(game.campaign_error.is_empty() and is_instance_valid(game.active_level) and paused and game.menu.page_name() == "resume", "actual production A3 installation waits paused at Resume: " + game.campaign_error):
		return false
	var level: CinderLevel = game.active_level
	var sources: Variant = level.get("sources")
	if not _expect(level.level_id == "A3-L2" and level.scene_file_path == LEVEL_PATH and level.get_script().resource_path == RUNTIME_PATH and level.hero == game.player and level.effects == game.fx and game.player.presentation_id == "act3_traveller" and sources is Dictionary and Codec.keys_error(sources, SOURCE_IDS).is_empty() and level.call("state").get("configuration_error", "missing") == "", "exact production Forest owns the shared actor/effects and all nine typed authored sources"):
		return false
	for id: String in SOURCE_IDS:
		var actual_kind: bool = sources[id] is CharacterBody3D if SOURCE_KINDS[id] == "stalker" else sources[id] is StaticBody3D
		var path: String = "res://scripts/acts/act3/sunbound_stalker.gd" if SOURCE_KINDS[id] == "stalker" else "res://scripts/acts/act3/root_latcher.gd"
		if not _expect(actual_kind and sources[id].get_script().resource_path == path and level.is_ancestor_of(sources[id]) and sources[id].call("state").get("stable_id") == id, "actual retained typed source has canonical binding: " + id):
			return false
	var scheduler: Node = level.get("threat_scheduler") as Node
	var bindings: Dictionary = level.call("scheduler_bindings")
	var owners: Dictionary = bindings.get("owners", {})
	var same_owners: bool = owners.size() == SOURCE_IDS.size()
	for id: String in SOURCE_IDS:
		var actual: Node3D = sources[id]
		if SOURCE_KINDS[id] == "stalker":
			same_owners = same_owners and owners.get(id) == actual
		else:
			var mechanism: Node3D = actual.call("get_mechanism")
			same_owners = same_owners and is_instance_valid(mechanism) and actual.is_ancestor_of(mechanism) and owners.get(id + "/attack") == mechanism
	return _expect(is_instance_valid(scheduler) and level.is_ancestor_of(scheduler) and bindings.get("world_root") == game.world and same_owners and bindings.get("actors", {}).get("hero") == game.player and game.camera.get_viewport() is SubViewport and (game.camera.get_viewport() as SubViewport).size == Vector2i(270, 585), "Forest binds four actual bodies/five actual mechanism children and native270x585 world to one shared scheduler")


func _valid_pair(unit: Dictionary) -> bool:
	if not unit.get("player") is Dictionary or not unit.get("level") is Dictionary or not unit.level.get("local") is Dictionary or not unit.level.local.get("sources") is Dictionary or not unit.level.local.get("scheduler") is Dictionary or not Codec.keys_error(unit.level.local.sources, SOURCE_IDS).is_empty(): return false
	for id: String in SOURCE_IDS:
		var typed: Variant = unit.level.local.sources[id]
		if not typed is Dictionary or not Codec.keys_error(typed, ["kind", "actor"]).is_empty() or typed.get("kind") != SOURCE_KINDS[id] or not typed.get("actor") is Dictionary: return false
		var actor: Dictionary = typed.actor
		if actor.get("stable_id") != id or actor.get("api_revision") != ("act3-stalker-snapshot-3" if SOURCE_KINDS[id] == "stalker" else "act3-root-latcher-2") or actor.get("schema_version") != (3 if SOURCE_KINDS[id] == "stalker" else 2) or actor.get("clock_s") != unit.level.local.scheduler.get("clock_s"): return false
	return game.player.snapshot_error(unit.player).is_empty() and game.active_level.snapshot_error_with_player(unit.level, unit.player).is_empty()


func _no_progress() -> bool:
	var state: Dictionary = game.attempts.state()
	return state.completed_main == FIXTURE_PREFIX and state.completed_optional.is_empty() and state.reward_ids.is_empty() and state.side_attempt == null and (not is_instance_valid(game.active_level) or not game.active_level.is_completed())


func _first_checkpoint_exists() -> bool:
	return game.attempts.state().story.checkpoint.level.progress.checkpoint_id == FIRST_CHECKPOINT


func _disk_state_matches() -> bool:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(_test_root + "campaign.json"))
	if not raw is Dictionary or raw.get("format_version") != 2 or not raw.get("payload_json") is String or not (raw.get("generation") is float or raw.get("generation") is int) or float(raw.generation) < 1.0:
		return false
	var disk: CinderSaveStore = Store.new(_test_root + "campaign.json")
	disk.payload_validator = game.attempts.saved_payload_error
	var payload: Dictionary = disk.read_payload()
	return disk.last_error.is_empty() and not disk.loaded_backup and Exact.stringify(payload) == Exact.stringify(game.attempts.state()) and raw.payload_json == Exact.stringify(payload) and raw.get("sha256") == String(raw.payload_json).sha256_text()


func _resume_consumed(label: String) -> bool:
	if not _expect(paused and game.menu.page_name() in ["resume", "pause"] and is_instance_valid(_find("ResumeButton")), label + " exposes actual paused GUI Resume"):
		return false
	var clock_before: float = game.player.get_world_action_clock()
	var hp_before: float = game.player.hp
	var shells_before: int = game.player.shells
	var pose_before: Vector3 = game.player.global_position
	var anchor_before: Vector2 = game.get_aim_anchor_normalized()
	var input_before: Dictionary = game.get_input_observation_state()
	var history_before: Array[Dictionary] = game.player.get_world_action_records()
	_click_immediate(_find("ResumeButton") as Control)
	# No await: a legitimate pending dash may complete on the next physics tick.
	return _expect(not paused and not game.menu.is_open() and root.is_input_handled() and game.get_input_observation_state() == input_before and game.player.get_world_action_records() == history_before and game.player.get_world_action_clock() == clock_before and game.player.hp == hp_before and game.player.shells == shells_before and game.player.global_position == pose_before and game.get_aim_anchor_normalized() == anchor_before, label + " GUI press/release is consumed before input/action/resource/pose/clock/anchor changes")


func _ready_dash() -> bool:
	for tick: int in range(120):
		if _finished or not is_instance_valid(game) or game.player.dead or paused or not game.campaign_error.is_empty():
			return _expect(false, "ready routed dash requires live unpaused actor: " + game.campaign_error)
		var response: Dictionary = game.player.get_threat_response_state()
		if response.get("stable") == true and response.get("motion", {}).get("grounded") == true and float(response.get("dash_cooldown_left_s", 1.0)) == 0.0:
			return true
		await physics_frame
		await process_frame
	return _expect(false, "actual grounded dash becomes ready within bounded physics wait")


func _wait_finished_dash(expected_sequence: int) -> bool:
	for tick: int in range(90):
		if _finished or not is_instance_valid(game) or paused or game.player.dead or not game.campaign_error.is_empty():
			return _expect(false, "short routed dash remains a live unpaused encounter")
		var records: Array[Dictionary] = game.player.get_world_action_records()
		if not records.is_empty() and int(records.back().sequence) == expected_sequence and game.player.get_committed_dash_state().get("active") == false:
			return true
		await physics_frame
		await process_frame
	return _expect(false, "actual routed dash completes within its finite bound")


func _wait_route_step(expected_sequence: int) -> bool:
	for tick: int in range(120):
		if _finished or not is_instance_valid(game) or game.player.dead or not game.campaign_error.is_empty():
			return _expect(false, "fatal route fails visibly before genuine contact/checkpoint: " + game.campaign_error)
		if _first_checkpoint_exists():
			return true
		if paused:
			return _expect(false, "unexpected focus/pause before first real spatial checkpoint")
		var records: Array[Dictionary] = game.player.get_world_action_records()
		if not records.is_empty() and int(records.back().sequence) == expected_sequence and game.player.get_committed_dash_state().get("active") == false:
			return true
		await physics_frame
		await process_frame
	return _expect(false, "forward routed dash/checkpoint settles within bounded physics wait")


func _swipe(start: Vector2, release: Vector2) -> bool:
	var sequence: int = int(game.get_input_observation_state().sequence)
	var size: Vector2 = root.get_visible_rect().size
	var finish: Vector2 = release * size
	var expected_anchor: Vector2 = finish / size
	var press := InputEventScreenTouch.new()
	press.index = 3
	press.position = start * size
	press.pressed = true
	root.push_input(press, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = finish
	drag.relative = (release - start) * size
	root.push_input(drag, true)
	var end := InputEventScreenTouch.new()
	end.index = 3
	end.position = finish
	root.push_input(end, true)
	# Real recognizer runs synchronously; release precedes the physics checkpoint.
	return _expect(int(game.get_input_observation_state().sequence) == sequence + 1 and game.get_input_observation_state().last_observation.get("kind") == "swipe_release" and game.get_aim_anchor_normalized() == expected_anchor and game.player.get_committed_dash_state().get("active") == true, "actual viewport touch/drag/release starts one public physical dash and records exact release anchor")


func _on_contact(result: Dictionary, source_id: String) -> void:
	_contacts.append({"source_id": source_id, "result": result.duplicate(true), "paused": paused})


func _observe_restore_node(node: Node) -> void:
	if not _watching_restore:
		return
	var watch_epoch: int = _restore_watch_epoch
	var observed: WeakRef = weakref(node)
	if node is CinderPlayer:
		var actor: CinderPlayer = node as CinderPlayer
		actor.fired.connect(func(_kind: String) -> void: _record_restore_event("player.fired", watch_epoch, observed))
		actor.died.connect(func() -> void: _record_restore_event("player.died", watch_epoch, observed))
		actor.equipment_changed.connect(func(_id: String) -> void: _record_restore_event("player.equipment_changed", watch_epoch, observed))
		actor.world_action_executed.connect(func(_record: Dictionary) -> void: _record_restore_event("player.world_action_executed", watch_epoch, observed))
	elif node is CinderLevel:
		var level: CinderLevel = node as CinderLevel
		level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _boundary: String) -> void: _record_restore_event("level.checkpoint", watch_epoch, observed))
		level.completion_requested.connect(func(_id: String, _completion: String) -> void: _record_restore_event("level.completion", watch_epoch, observed))
		level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _record_restore_event("level.contact_exit", watch_epoch, observed))
	elif node is CinderThreatScheduler:
		var scheduler: CinderThreatScheduler = node as CinderThreatScheduler
		scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _record_restore_event("scheduler.cancel", watch_epoch, observed))
	elif node is CinderLaneMechanism:
		var mechanism: CinderLaneMechanism = node as CinderLaneMechanism
		mechanism.state_changed.connect(func(_state: Dictionary) -> void: _record_restore_event("root-mechanism.state_changed", watch_epoch, observed))
		mechanism.hit_resolved.connect(func(_hero: String, _cycle: int, _result: Dictionary) -> void: _record_restore_event("root-mechanism.hit_resolved", watch_epoch, observed))
	elif node is CinderThreatCue:
		var cue: CinderThreatCue = node as CinderThreatCue
		cue.state_changed.connect(func(_state: Dictionary) -> void: _record_restore_event("cue.state_changed", watch_epoch, observed))
	elif node.get_script() != null and (node.get_script() as Script).resource_path in ["res://scripts/acts/act3/sunbound_stalker.gd", "res://scripts/acts/act3/root_latcher.gd"]:
		node.connect("state_changed", func(_state: Dictionary) -> void: _record_restore_event("source.state_changed", watch_epoch, observed))
		node.connect("died", func(_where: Vector3) -> void: _record_restore_event("source.died", watch_epoch, observed))
		if node.has_signal("hit_resolved"):
			node.connect("hit_resolved", func(_result: Dictionary) -> void: _record_restore_event("source.hit_resolved", watch_epoch, observed))


func _record_restore_event(event: String, watch_epoch: int, observed: WeakRef) -> void:
	# Prior-world teardown remains real and is checked by retirement assertions.
	# A new restore watches only its newly constructed candidates. Dead Resume
	# retains the current epoch so callbacks from its existing world still count.
	if _watching_restore and watch_epoch == _restore_watch_epoch and is_instance_valid(observed.get_ref()):
		_restore_events.append(event)


func _find(node_name: String) -> Node:
	return game.menu.find_child(node_name, true, false)


func _click(control: Control) -> void:
	await _settle()
	_click_immediate(control)
	await _settle()


func _click_immediate(control: Control) -> void:
	if not is_instance_valid(control) or not control.is_visible_in_tree():
		_expect(false, "required actual GUI control exists and is visible")
		return
	var at: Vector2 = control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	root.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = at
	press.global_position = at
	press.pressed = true
	root.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release, true)


func _old_refs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node: Node in [game.world, game.active_level, game.player, game.fx]:
		result.append({"label": String(node.name), "ref": weakref(node)})
	_collect_refs(game.active_level, result)
	return result


func _collect_refs(parent: Node, result: Array[Dictionary]) -> void:
	for child: Node in parent.get_children():
		if child is CharacterBody3D or child is StaticBody3D or child is CinderThreatScheduler or child is CinderLaneMechanism or child.is_in_group("required_cues"):
			result.append({"label": String(child.name), "ref": weakref(child)})
		_collect_refs(child, result)


func _expect_refs_freed(refs: Array[Dictionary], label: String) -> void:
	for entry: Dictionary in refs:
		_expect((entry.ref as WeakRef).get_ref() == null, label + " frees actual " + String(entry.label))


func _close_shell() -> void:
	if is_instance_valid(game):
		_stop_audio(game)
		game.free()
	game = null
	paused = true


func _stop_audio(parent: Node) -> void:
	for child: Node in parent.get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()
			(child as AudioStreamPlayer).stream = null
		elif child is AudioStreamPlayer3D:
			(child as AudioStreamPlayer3D).stop()
			(child as AudioStreamPlayer3D).stream = null
		_stop_audio(child)


func _capture(label: String) -> void:
	if not graphical:
		return
	if not _expect(DisplayServer.get_name() != "headless", "optional portrait capture uses actual graphical renderer"):
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_root))
	var picture: Image = root.get_texture().get_image()
	if _expect(picture.get_size() == Vector2i(540, 1170) and picture.save_png(_capture_root + label + ".png") == OK, "actual540x1170 production portrait captured: " + ProjectSettings.globalize_path(_capture_root + label + ".png")):
		_captures.append(label)
	print("NATIVE PORTRAIT CONTEXT: ", {"label": label, "paused": paused, "native_focus": root.has_focus(), "menu": game.menu.page_name(), "level_id": game.active_level.level_id if is_instance_valid(game.active_level) else "", "player_clock_s": game.player.get_world_action_clock() if is_instance_valid(game.player) else -1.0})


func _settle() -> void:
	for frame: int in range(8):
		await process_frame


func _cleanup_saves() -> void:
	for filename: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_test_root + filename))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_test_root))


func _finish() -> void:
	if _finished:
		return
	_finished = true
	_close_shell()
	paused = false
	_cleanup_saves()
	if not _registry_text.is_empty():
		_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_text, "every selected scope leaves canonical registry bytes unchanged")
	_expect(get_nodes_in_group("required_cues").is_empty() and get_nodes_in_group("enemies").is_empty(), "selected scope retires all actual source/cue group members")
	if graphical and failures == 0:
		_expect(_captures.size() == (3 if _journey_only else 4), "selected portrait scope produces its exact bounded original frame count")
	# Native mixer retirement after the last real hit; gameplay assertions and
	# every original actor/world cleanup check precede this test-only drain.
	await create_timer(0.35, true).timeout
	for frame: int in range(4):
		await process_frame
	print("Production Act3 L2 registration: %d checks, %d failures; expected_commit=%s; TEST ONLY eleven-predecessor/initial-resource seeds; actual production GUI/format2/routed dash/fatal Continue/Retry; no route-clear or native-human claim" % [checks, failures, _expected_commit])
	quit(0 if failures == 0 else 1)


func _expect(condition: bool, message: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
		if failures == 1 and is_instance_valid(game):
			print("FIRST FAILURE PUBLIC CONTEXT: ", {"paused": paused, "campaign_error": game.campaign_error, "level": game.active_level.call("state") if is_instance_valid(game.active_level) and game.active_level.has_method("state") else {}, "contacts": _contacts, "checkpoint_events": _checkpoint_events})
	else:
		print("PASS: " + message)
	return condition
