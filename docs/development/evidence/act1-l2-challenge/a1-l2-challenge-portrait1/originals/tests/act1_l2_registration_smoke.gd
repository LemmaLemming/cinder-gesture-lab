extends SceneTree
## Production Registry/Title/Journey/format2 lifecycle for exact accepted A1-L2.
## Requires the exact installed HANDOFF; --expected-commit may assert it. No metadata is
## injected. The single-predecessor prefix and fresh low HP/empty ammo are TEST ONLY
## isolated public seed data, not evidence of predecessor gameplay or a clear.
## Later dash/primary and landing-circle contact/death are actual native input/physics.
## This is an entry/save/Retry registration leaf, not another authored full route.
## Installation and execution provenance are recorded by integration.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const Game = preload("res://scripts/game.gd")
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Attempts = preload("res://scripts/campaign/attempts.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const ACCEPTED_COMMIT: String = "dcd109857b966ea77b231944d0e41e3d88cc27bc"
const LEVEL_PATH: String = "res://scenes/acts/act1/a1_l2.tscn"
const RUNTIME_PATH: String = "res://scripts/acts/act1/crater_gardens.gd"
const SOURCE_IDS: Array[String] = ["solo", "rock", "open", "finale"]
const CIRCLE_IDS: Array[String] = ["landing-impact", "rock-impact", "open-impact", "finale-impact-a", "finale-impact-b"]
const BEAT_IDS: Array[String] = ["landing-clearing", "first-selenite", "approaches-rejoined", "celestial-camp", "grotto-opening"]
const CHECKPOINT_IDS: Array[String] = ["landing-clearing", "first-selenite", "approaches-rejoined", "celestial-camp"]
const FIXTURE_PREFIX: Array[String] = ["A1-L1"]
const FATAL_WAIT_S: float = 9.0

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
var _restore_events: Array[String] = []
var _contacts: Array[Dictionary] = []
var _armed_active_seen: bool = false
var _deaths: int = 0
var _death_clock_s: float = 0.0
var _death_player_clock_s: float = 0.0
var _death_shells: int = 0


func _initialize() -> void:
	var identity: String = "%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_test_root = "user://test-act1-l2-registration-%s/" % identity
	_capture_root = "user://test-act1-l2-registration-captures-%s/" % identity
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--portrait":
			graphical = true
		elif argument.begins_with("--expected-commit="):
			_expected_commit = argument.trim_prefix("--expected-commit=")
	node_added.connect(_observe_restore_node)
	create_timer(90.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "production A1-L2 registration completes within its watchdog")
			_finish())
	_run.call_deferred()


func _run() -> void:
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
	var accepted: Dictionary = registry.entry("A1-L2")
	if not _expect(registry.last_error.is_empty() and registry.ids().size() == 24 and accepted.get("readiness") == "accepted" and accepted.get("accepted_commit") == _expected_commit and accepted.get("scene_path") == LEVEL_PATH and accepted.get("api_revision") == "campaign-level-1" and registry.scene_error("A1-L2").is_empty(), "actual production registry validates the exact accepted authored A1-L2 scene: " + registry.last_error):
		_finish()
		return
	if "--fatal-only" in OS.get_cmdline_user_args():
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
	await _click(_find("Act1Shortcut") as Control)
	await _click(_find("Node_A1_L2") as Control)
	var action: Button = _find("LevelCardAction") as Button
	var node: Button = _find("Node_A1_L2") as Button
	if not _expect(game.menu.page_name() == "journey" and node != null and node.get_meta("campaign_state") == "locked" and action != null and action.disabled and (_find("LevelCardBody") as Label).text.contains("A1-L1"), "real Journey keeps accepted A1-L2 locked behind its actual A1-L1 prerequisite"):
		_finish()
		return
	await _capture("journey-locked")
	var empty_model: String = Exact.stringify(game.attempts.state())
	await _click(action)
	_expect(game.active_level == null and Exact.stringify(game.attempts.state()) == empty_model, "disabled locked card neither loads A1-L2 nor fabricates progression")
	_close_shell()
	if not await _seed_actual_story(registry, 37.0):
		_finish()
		return
	game = _new_shell()
	await _settle()
	if not _title_valid("TEST ONLY single-predecessor story seed"):
		_finish()
		return
	_expect(_no_progress() and not (_find("ContinueStoryButton") as Button).disabled, "TEST ONLY single-predecessor prefix offers protected uncompleted A1-L2 story Continue")
	await _click(_find("JourneyButton") as Control)
	await _click(_find("Act1Shortcut") as Control)
	await _click(_find("Node_A1_L2") as Control)
	action = _find("LevelCardAction") as Button
	node = _find("Node_A1_L2") as Button
	if not _expect(node != null and node.get_meta("campaign_state") == "current" and action != null and not action.disabled and action.text == "Continue Story" and (_find("Node_A1_L3") as Button).get_meta("campaign_state") == "locked", "real seeded Journey offers current A1-L2 Continue while A1-L3 stays locked"):
		_finish()
		return
	await _capture("journey-seeded")
	await _click(action)
	if not _actual_entry():
		_finish()
		return
	var entry: Dictionary = game.capture_campaign_snapshot()
	if not _expect(not entry.is_empty() and entry.level.local_snapshot_version == 1 and _initial_local(entry.level) and _valid_pair(entry), "actual accepted localversion1 Crater Gardens entry is a coherent Player/four-C30/five-circle/scheduler/shell unit"):
		_finish()
		return
	_expect(game.player.hp == 37.0 and game.player.shells == 0 and entry.player.world_actions.clock_s == 0.0 and entry.player.world_actions.sequence == 0 and entry.shell.input_sequence == 0, "fresh TEST ONLY initial resources retain no executed action/input/tick")
	_expect(_disk_state_matches(), "entry reopens actual checked format2 SaveStore data")
	var entry_encoded: String = Exact.stringify(entry)
	if not _resume_consumed("initial living entry"):
		_finish()
		return
	await _capture("arrival")
	if not await _ready_dash() or not await _swipe(Vector2(0.36, 0.72), Vector2(0.55, 0.72)) or not await _wait_finished_dash(1) or not _primary_tap(Vector2(0.70, 0.72)):
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
	var actual_release_anchor: Vector2 = (Vector2(0.55, 0.72) * size) / size
	_expect(dash.kind == "dash" and dash.path.size() >= 2 and dash.completed_at_s > dash.started_at_s and saved.player.world_actions.sequence == 2 and game.get_aim_anchor_normalized() == actual_release_anchor, "real routed release retains its completed physical path and separate exact screen anchor after the primary tap")
	_expect(saved_encoded != entry_encoded and saved.player.world_actions.clock_s > 0.0 and saved.level.local.scheduler.clock_s > 0.0 and saved.shell.camera_focus != entry.shell.camera_focus, "live dash changes actual path/clocks/camera before the save")
	_expect(saved.player.resources.hp == 37.0 and saved.player.resources.shells == game.player.shells and saved.equipment_ids == entry.equipment_ids and saved.shell.input_sequence == 2, "short native movement/primary preserves initial low HP and gear with two real inputs; ammo follows its actual passive reload")
	_expect(Exact.stringify(game.attempts.active_snapshot()) == saved_encoded and Exact.stringify(game.attempts.state().story.checkpoint) == entry_encoded and _no_progress(), "coherent movement save protects its initial checkpoint and awards no A1-L2 completion/reward")
	_expect(_disk_state_matches(), "actual pause publishes an exact checked format2 generation")
	await _settle()
	_expect(Exact.stringify(game.capture_campaign_snapshot()) == saved_encoded, "paused frames freeze complete actor/local/input/camera state exactly")
	var retired: Array[Dictionary] = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "first shell closure")
	if not await _fresh_continue(saved_encoded, "living saved movement/aimed primary"):
		_finish()
		return
	_expect(game.player.hp == saved.player.resources.hp and game.player.shells == saved.player.resources.shells and game.player.get_world_action_records().size() == 2, "fresh Continue preserves actual resources and does not republish the past dash or primary")
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
	# Separate TEST ONLY quiet initial HP0.1/shell0. The authored spawn is within
	# the padded landing-circle contact, so a native admitted hit causes death.
	# No live pose, phase, clock, HP, damage or checkpoint is assigned.
	if not await _seed_actual_story(registry, 0.1):
		return false
	game = _new_shell()
	await _settle()
	if not _title_valid("fatal TEST ONLY initial HP0.1/zeroammo"):
		return false
	await _click(_find("ContinueStoryButton") as Control)
	if not _actual_entry():
		return false
	var checkpoint: Dictionary = game.capture_campaign_snapshot()
	if not _expect(not checkpoint.is_empty() and _valid_pair(checkpoint) and _initial_local(checkpoint.level) and checkpoint.player.resources.hp == 0.1 and checkpoint.player.resources.shells == 0 and not checkpoint.player.resources.dead and checkpoint.player.world_actions.clock_s == 0.0 and checkpoint.player.world_actions.sequence == 0 and Exact.stringify(game.attempts.state().story.checkpoint) == Exact.stringify(checkpoint), "fatal branch protects the exact actual living entry through TEST ONLY public seed/Continue"):
		return false
	_contacts.clear()
	_deaths = 0
	_armed_active_seen = false
	var scheduler: CinderThreatScheduler = game.active_level.get_node("CraterThreatScheduler") as CinderThreatScheduler
	var landing: CinderLaneMechanism = (game.active_level.get("circles") as Dictionary)["landing-impact"]
	game.player.died.connect(func() -> void:
		_deaths += 1
		_death_clock_s = scheduler.get_clock()
		_death_player_clock_s = game.player.get_world_action_clock()
		_death_shells = game.player.shells)
	landing.hit_resolved.connect(_on_contact)
	landing.state_changed.connect(func(state: Dictionary) -> void:
		if state.get("status") == "running" and state.get("phase") == "active" and not String(state.get("reservation_id", "")).is_empty():
			_armed_active_seen = true)
	if not _resume_consumed("fatal initial living entry"):
		return false
	var deadline: float = scheduler.get_clock() + FATAL_WAIT_S
	for tick: int in range(int(ceilf(FATAL_WAIT_S * Engine.physics_ticks_per_second)) + 120):
		if game.player.dead:
			break
		if paused or not game.campaign_error.is_empty() or scheduler.get_clock() >= deadline:
			break
		await physics_frame
		await process_frame
	var accepted_contacts: Array[Dictionary] = []
	for contact: Dictionary in _contacts:
		if contact.result.get("accepted") == true and float(contact.result.get("hp_damage", 0.0)) > 0.0:
			accepted_contacts.append(contact)
	if not _expect(game.player.dead and _deaths == 1 and _armed_active_seen and accepted_contacts.size() == 1 and accepted_contacts[0].hero_id == "hero" and accepted_contacts[0].cycle == 1 and accepted_contacts[0].result.get("opportunity_consumed") == true and accepted_contacts[0].result.get("impulse") == Vector3.ZERO, "bounded stationary spawn wait receives one real landing active contact/death without forced live state: " + str(_contacts)):
		return false
	await _settle()
	var fatal: Dictionary = game.capture_campaign_snapshot()
	if not _expect(paused and game.menu.page_name() == "pause" and game.campaign_error.is_empty() and not fatal.is_empty() and fatal.player.resources.dead and fatal.player.resources.hp == 0.0 and _valid_pair(fatal), "native fatal callback settles the complete paused Player/C30/circle/scheduler unit: " + game.campaign_error):
		return false
	_expect(fatal.player.resources.shells == _death_shells and fatal.player.world_actions.clock_s == _death_player_clock_s and fatal.level.local.scheduler.clock_s == _death_clock_s, "fatal save retains actual passive-reload ammo and the exact accepted lethal Player/Scheduler tick")
	var fatal_encoded: String = Exact.stringify(fatal)
	var impact: Dictionary = fatal.level.local.circles["landing-impact"]
	_expect(game.player.get_world_action_records().is_empty() and fatal.player.world_actions.sequence == 0 and fatal.shell.input_sequence == 0 and impact.status == "cancelled" and impact.phase == "clear" and impact.cycle == 1 and impact.hit_ids == ["hero"] and impact.last_cancel_reason == "actual_player_death", "death consumes the real landing opportunity and retains clear cancellation with no Player action/input")
	_expect(fatal.level.local.scheduler.reservations.is_empty() and fatal.level.local.beat_index == 0 and fatal.level.local.completed_beats.is_empty() and fatal.level.local.chosen_route.is_empty() and fatal.level.local.framing.is_empty() and fatal.level.local.custody.is_empty() and fatal.level.local.sequence.is_empty() and fatal.level.progress.checkpoint_ids.is_empty() and not fatal.level.progress.completed and fatal.level.progress.contact_exit_id.is_empty(), "death creates no beat/checkpoint/rusher defeat/choice/completion/contact or live damage lease")
	_expect(Exact.stringify(fatal.level.local.sources) == Exact.stringify(checkpoint.level.local.sources), "fatal retirement preserves all four untouched dormant future C30 actors")
	_expect(Exact.stringify(game.attempts.active_snapshot()) == fatal_encoded and Exact.stringify(game.attempts.state().story.checkpoint) == Exact.stringify(checkpoint) and _disk_state_matches() and _no_progress(), "fatal format2 save preserves the exact earlier living entry checkpoint and no unearned progress")
	print("ACTUAL FATAL RECEIPT: ", {"clock_s": _death_clock_s, "player_clock_s": _death_player_clock_s, "shells": _death_shells, "contacts": _contacts, "level_error": game.active_level.last_snapshot_error})
	var retired: Array[Dictionary] = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "fatal shell closure")
	if not await _fresh_continue(fatal_encoded, "actual fatal unit"):
		return false
	var dead_before: String = Exact.stringify(game.capture_campaign_snapshot())
	var disk_before: String = FileAccess.get_file_as_string(_test_root + "campaign.json")
	_restore_events.clear()
	_watching_restore = true
	_click_immediate(_find("ResumeButton") as Control)
	await _settle()
	_watching_restore = false
	var notice: Label = _find("MenuStatus") as Label
	_expect(paused and game.player.dead and game.menu.page_name() == "pause" and notice != null and notice.text == "Retry your saved checkpoint." and Exact.stringify(game.capture_campaign_snapshot()) == dead_before and FileAccess.get_file_as_string(_test_root + "campaign.json") == disk_before and _restore_events.is_empty(), "dead GUI Resume preserves the exact fatal actor/local/input/camera/disk and offers Retry without gameplay callbacks")
	retired = _old_refs()
	if not await _quiet_retry(Exact.stringify(checkpoint), "fatal world's living entry checkpoint"):
		return false
	_expect_refs_freed(retired, "fatal GUI Retry")
	_expect(not game.player.dead and game.player.hp == 0.1 and game.player.shells == 0 and game.player.get_world_action_records().is_empty() and _no_progress() and _disk_state_matches(), "fatal GUI Retry restores living lowHP/zeroammo entry without healing or redelivering the circle hit")
	await _settle()
	_expect(Exact.stringify(game.capture_campaign_snapshot()) == Exact.stringify(checkpoint), "retried Player/C30/circle/input/camera clocks stay exactly paused")
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
	if not _expect(is_instance_valid(actor) and is_instance_valid(level) and level.get_script().resource_path == RUNTIME_PATH, "TEST ONLY seed uses the actual reviewed Crater Gardens runtime, not a greybox or predecessor"):
		preview.free()
		return false
	var initial: Dictionary = actor.snapshot_state()
	if initial.is_empty():
		_expect(false, "quiet initial actual Player snapshot exists: " + actor.last_snapshot_error)
		level.exit_level()
		preview.free()
		return false
	initial.resources.hp = initial_hp
	initial.resources.shells = 0
	var accepted: bool = actor.restore_state(initial)
	_expect(accepted, "TEST ONLY initial HP/zeroammo seed uses validated quiet public Player restore")
	var player_state: Dictionary = actor.snapshot_state()
	var local: Dictionary = level.snapshot_state()
	var anchor: Vector2 = preview.call("get_aim_anchor_normalized")
	var shell_state: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Game.CAMERA_OFFSET), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}
	var aggregate: Dictionary = {"schema_version": 1, "level_id": "A1-L2", "scene_path": LEVEL_PATH, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": player_state, "level": local, "shell": shell_state}
	var store: CinderSaveStore = Store.new(_test_root + "campaign.json")
	var model: CinderCampaignAttempts = Attempts.new(registry, store)
	var seed: Dictionary = model.state()
	seed["completed_main"] = FIXTURE_PREFIX.duplicate()
	seed["story"] = {"kind": "story", "level_id": "A1-L2", "snapshot": aggregate.duplicate(true), "checkpoint": aggregate.duplicate(true)}
	var error: String = level.snapshot_error_with_player(local, player_state) if not local.is_empty() and not player_state.is_empty() else "Actual paused scene capture failed"
	accepted = accepted and error.is_empty() and model.state_error(seed).is_empty() and model.restore_session(seed) and store.write_payload(model.state())
	_expect(accepted, "TEST ONLY A1-L1 prefix/actual initial A1-L2 unit writes through public Attempts/SaveStore: " + error + " " + model.last_error + " " + store.last_error)
	_expect(actor.presentation_id == "act1_expedition" and actor.get_world_action_records().is_empty() and _initial_local(local), "seed retains initial five-beat/four-checkpoint Main, four dormant C30/five idle circles and no Player action")
	var actor_ref: WeakRef = weakref(actor)
	var level_ref: WeakRef = weakref(level)
	level.exit_level()
	preview.free()
	_expect(actor_ref.get_ref() == null and level_ref.get_ref() == null, "seed preview retires before production installation")
	print("TEST ONLY predecessor/resource seed: ", FIXTURE_PREFIX, "; HP=", initial_hp, "; initial shells=0; not A1-L1 gameplay or A1-L2 clear evidence")
	return accepted


func _initial_local(snapshot: Dictionary) -> bool:
	if snapshot.is_empty() or snapshot.get("local_snapshot_version") != 1:
		return false
	var local: Dictionary = snapshot.get("local", {})
	var progress: Dictionary = snapshot.get("progress", {})
	if local.get("beat_index") != 0 or local.get("completed_beats") != [] or local.get("chosen_route") != "" or local.get("encounter_started") != true or local.get("scheduler", {}).get("clock_s") != 0.0 or not local.get("scheduler", {}).get("reservations", [1]).is_empty() or local.get("framing") != {} or local.get("custody") != {} or local.get("sequence") != {} or progress.get("completed") != false or progress.get("checkpoint_ids") != {} or progress.get("checkpoint_id") != "" or progress.get("contact_exit_id") != "":
		return false
	var sources: Dictionary = local.get("sources", {})
	var circles: Dictionary = local.get("circles", {})
	if not Codec.keys_error(sources, SOURCE_IDS).is_empty() or not Codec.keys_error(circles, CIRCLE_IDS).is_empty():
		return false
	for id: String in SOURCE_IDS:
		var value: Dictionary = sources[id]
		if value.get("dormant") != true or value.get("dead") != false or value.get("hp") != 20.0 or value.get("cycle") != 0 or value.get("reservation_id") != "":
			return false
	for id: String in CIRCLE_IDS:
		var value: Dictionary = circles[id]
		if value.get("status") != "idle" or value.get("phase") != "clear" or value.get("cycle") != 0 or value.get("hit_ids") != []:
			return false
	return true


func _fresh_continue(expected: String, label: String) -> bool:
	_restore_events.clear()
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
	if not _expect(game.campaign_error.is_empty() and is_instance_valid(game.active_level) and paused and game.menu.page_name() == "resume", "production A1-L2 installation waits at its real paused Resume: " + game.campaign_error):
		return false
	var level: CinderLevel = game.active_level
	var state: Dictionary = level.call("encounter_state")
	if not _expect(level.level_id == "A1-L2" and level.scene_file_path == LEVEL_PATH and level.get_script().resource_path == RUNTIME_PATH and level.hero == game.player and level.effects == game.fx and game.player.presentation_id == "act1_expedition" and level.contract_error().is_empty() and state.get("sources", {}).size() == 4 and state.get("circles", {}).size() == 5, "reviewed Main owns one shared expedition Player/effects, four retained C30 and five HP-free stationary circles"):
		return false
	var sources: Dictionary = level.get("sources")
	var circles: Dictionary = level.get("circles")
	for id: String in SOURCE_IDS:
		var actor: Node3D = sources[id] as Node3D
		if not _expect(is_instance_valid(actor) and level.is_ancestor_of(actor) and actor.get_script().resource_path == "res://scripts/acts/act1/rush_selenite.gd" and actor.call("state").get("source_id") == id and String(actor.call("art_binding_error")).is_empty(), "retained actual C30 source/art binding: " + id):
			return false
	for id: String in CIRCLE_IDS:
		var impact: CinderLaneMechanism = circles[id] as CinderLaneMechanism
		if not _expect(is_instance_valid(impact) and level.is_ancestor_of(impact) and impact.state().mechanism_id == id and impact.get_cue().is_inside_tree() and not impact.is_in_group("enemies"), "actual HP-free native circle/source/cue binding: " + id):
			return false
	var scheduler: Node = level.get_node_or_null("CraterThreatScheduler")
	var spawn: Marker3D = level.get_node("PlayerSpawn") as Marker3D
	var authored: Dictionary = (level.get_script() as Script).get_script_constant_map()
	return _expect(scheduler is CinderThreatScheduler and level.is_ancestor_of(scheduler) and spawn.position == Vector3(0, 0.1, 16) and authored.get("BEATS") == BEAT_IDS and authored.get("CHECKPOINTS") == CHECKPOINT_IDS, "reviewed spawn, shared Scheduler and exact five-beat/four-checkpoint authored prefix remain intact")


func _valid_pair(unit: Dictionary) -> bool:
	return game.player.snapshot_error(unit.player).is_empty() and game.active_level.snapshot_error_with_player(unit.level, unit.player).is_empty()


func _no_progress() -> bool:
	var state: Dictionary = game.attempts.state()
	return state.completed_main == FIXTURE_PREFIX and state.completed_optional.is_empty() and state.reward_ids.is_empty() and state.side_attempt == null and (not is_instance_valid(game.active_level) or not game.active_level.is_completed())


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
			return _expect(false, "ready routed dash requires live focused unpaused actor: " + game.campaign_error)
		var response: Dictionary = game.player.get_threat_response_state()
		if response.get("stable") == true and response.get("motion", {}).get("grounded") == true and float(response.get("dash_cooldown_left_s", 1.0)) == 0.0:
			return true
		await physics_frame
		await process_frame
	return _expect(false, "actual grounded dash becomes ready within bounded physics wait")


func _wait_finished_dash(expected_sequence: int) -> bool:
	for tick: int in range(90):
		if _finished or not is_instance_valid(game) or paused or game.player.dead or not game.campaign_error.is_empty():
			return _expect(false, "short routed dash remains a live focused encounter")
		var records: Array[Dictionary] = game.player.get_world_action_records()
		if not records.is_empty() and int(records.back().sequence) == expected_sequence and game.player.get_committed_dash_state().get("active") == false:
			return true
		await physics_frame
		await process_frame
	return _expect(false, "actual routed dash completes within its finite bound")


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


func _primary_tap(normalized: Vector2) -> bool:
	var size: Vector2 = root.get_visible_rect().size
	var tap: Vector2 = normalized * size
	var anchor: Vector2 = game.get_aim_anchor_normalized()
	var expected_direction: Vector3 = game.aim_direction(tap)
	var origin: Vector3 = game.player.global_position
	var input_sequence: int = int(game.get_input_observation_state().sequence)
	var action_sequence: int = int(game.player.get_world_action_records().back().sequence)
	var shells: int = game.player.shells
	var press := InputEventScreenTouch.new()
	press.index = 3
	press.position = tap
	press.pressed = true
	root.push_input(press, true)
	var release := press.duplicate() as InputEventScreenTouch
	release.pressed = false
	root.push_input(release, true)
	var records: Array[Dictionary] = game.player.get_world_action_records()
	var observation: Dictionary = game.get_input_observation_state().last_observation
	if not _expect(records.size() == 2 and int(records.back().sequence) == action_sequence + 1 and int(game.get_input_observation_state().sequence) == input_sequence + 1 and observation.get("kind") == "primary_tap" and observation.get("accepted") == true, "one real viewport first tap executes an immediate primary after the completed native dash"):
		return false
	var record: Dictionary = records.back()
	return _expect(record.kind == "primary" and record.origin == "player_direct" and record.hits == 0 and record.world_origin == origin and record.direction == expected_direction and record.completed_at_s == game.player.get_world_action_clock() and game.get_aim_anchor_normalized() == anchor and game.player.shells == shells, "actual primary aims from the stored swipe-release anchor, has native geometry/clock and consumes no ammo or target HP")


func _on_contact(hero_id: String, cycle: int, result: Dictionary) -> void:
	_contacts.append({"hero_id": hero_id, "cycle": cycle, "result": result.duplicate(true), "paused": paused})


func _observe_restore_node(node: Node) -> void:
	if not _watching_restore:
		return
	if node is CinderPlayer:
		var actor: CinderPlayer = node as CinderPlayer
		actor.fired.connect(func(_kind: String) -> void: _restore_events.append("player.fired"))
		actor.died.connect(func() -> void: _restore_events.append("player.died"))
		actor.equipment_changed.connect(func(_id: String) -> void: _restore_events.append("player.equipment_changed"))
		actor.world_action_executed.connect(func(_record: Dictionary) -> void: _restore_events.append("player.world_action_executed"))
	elif node is CinderLevel:
		var level: CinderLevel = node as CinderLevel
		level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _boundary: String) -> void: _restore_events.append("level.checkpoint"))
		level.completion_requested.connect(func(_id: String, _completion: String) -> void: _restore_events.append("level.completion"))
		level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _restore_events.append("level.contact_exit"))
	elif node is CinderLaneMechanism:
		node.connect("hit_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: _restore_events.append("circle.hit_resolved"))
	elif node.get_script() != null and node.get_script().resource_path == "res://scripts/acts/act1/rush_selenite.gd":
		node.connect("hit_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: _restore_events.append("C30.hit_resolved"))
		node.connect("defeated", func(_id: String) -> void: _restore_events.append("C30.defeated"))


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
		if child is CharacterBody3D or child is StaticBody3D or child is CinderThreatScheduler or child.is_in_group("required_cues") or child.is_in_group("enemies"):
			result.append({"label": String(child.name), "ref": weakref(child)})
		_collect_refs(child, result)


func _expect_refs_freed(refs: Array[Dictionary], label: String) -> void:
	for entry: Dictionary in refs:
		_expect((entry.ref as WeakRef).get_ref() == null, label + " frees actual " + String(entry.label))


func _close_shell() -> void:
	if is_instance_valid(game):
		game.free()
	game = null
	paused = true


func _capture(label: String) -> void:
	if not graphical:
		return
	if not _expect(DisplayServer.get_name() != "headless", "optional portrait capture uses actual graphical renderer"):
		return
	await RenderingServer.frame_post_draw

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_root))
	var picture: Image = root.get_texture().get_image()
	_expect(picture.get_size() == Vector2i(540, 1170) and picture.save_png(_capture_root + label + ".png") == OK, "actual540x1170 production portrait captured: " + ProjectSettings.globalize_path(_capture_root + label + ".png"))


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
	var scope: String = "fatal lifecycle only" if "--fatal-only" in OS.get_cmdline_user_args() else "Title/Journey/entry/dash+aim/save/Continue/Retry/fatal lifecycle"
	print("Production Act1 L2 registration: %d checks, %d failures; expected_commit=%s; scope=%s; TEST ONLY A1-L1/initial-resource seeds; no predecessor gameplay, full-route or native-human claim" % [checks, failures, _expected_commit, scope])
	quit(0 if failures == 0 else 1)


func _expect(condition: bool, message: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
		if failures == 1 and is_instance_valid(game):
			print("FIRST FAILURE PUBLIC CONTEXT: ", {"paused": paused, "campaign_error": game.campaign_error, "level": game.active_level.call("encounter_state") if is_instance_valid(game.active_level) and game.active_level.has_method("encounter_state") else {}, "contacts": _contacts, "armed_active_seen": _armed_active_seen})
	else:
		print("PASS: " + message)
	return condition
