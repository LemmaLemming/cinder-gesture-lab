extends SceneTree
## Actual L2 through the production CampaignShell/menu/save seams. Accepted
## metadata is test-only; the existing generic L1 fixture supplies its public
## completion/contact handoff. Injured resources are explicitly staged on that
## fixture, never claimed as a no-teleport campaign route or L2 completion.
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const LEVEL_PATH: String = "res://scenes/acts/act1/a1_l2.tscn"
const HANDOFF_PATH: String = "res://tests/fixtures/campaign/live_a1_l1.tscn"
var game: CinderCampaignShell
var raw: Dictionary
var test_root: String
var registry_text: String
var checks: int = 0
var failures: int = 0
var events: int = 0
var finishing: bool = false
var candidates: Array[Dictionary] = []
var old_fps: int
var old_audio: AudioBusLayout


func _initialize() -> void:
	test_root = "user://test-act1-crater-campaign-%d/" % OS.get_process_id()
	old_fps = Engine.max_fps
	old_audio = AudioServer.generate_bus_layout()
	_run.call_deferred()


func _run() -> void:
	create_timer(45.0, true).timeout.connect(func() -> void:
		if not finishing:
			_expect(false, "bounded actual L2 campaign fixture completes within45 seconds")
			_finish())
	root.size = Vector2i(540, 1170)
	_cleanup_files()
	registry_text = FileAccess.get_file_as_string(Registry.DATA_PATH)
	raw = JSON.parse_string(registry_text)
	for info: Dictionary in raw.levels:
		if info.id in ["A1-L1", "A1-L2"]:
			info.scene_path = HANDOFF_PATH if info.id == "A1-L1" else LEVEL_PATH
			info.readiness = "accepted"
			info.accepted_commit = "f".repeat(40)
			info.api_revision = Registry.API_REVISION
	node_added.connect(_observe_candidate)
	if not _new_shell():
		_finish(); return
	await _settle()
	_expect(paused and game.active_level == null and game.menu.page_name() == "title", "isolated production shell begins at the paused actual Title")
	if not _select_profile("assisted"):
		_finish(); return
	_expect(game.settings.storage_path() == test_root + "settings.json", "actual settings use only this process-specific user path")
	if not _press("JourneyButton"):
		_finish(); return
	await _settle()
	_expect(game.menu.page_name() == "journey" and paused, "actual Journey menu remains paused before Begin")
	game.menu.select_level("A1-L1")
	if not _press("LevelCardAction"):
		_finish(); return
	await _settle()
	if not _expect(game.campaign_error.is_empty() and is_instance_valid(game.active_level) and game.active_level.scene_file_path == HANDOFF_PATH, "Journey Begin prepares only the existing test-only L1 handoff: " + game.campaign_error):
		_finish(); return
	# Explicit fixture resource staging before the real shell transition. Shared
	# passive reload stays enabled; the entire handoff is a paused barrier.
	game.player.hp = 22.0
	game.player.shells = 0
	if not _expect(game.active_level.request_completion("test-crater-handoff"), "generic test L1 publishes its real public completion request"):
		_finish(); return
	await _settle()
	if not _expect(game.active_level.request_contact_exit("test-crater-contact", game.player), "generic test L1 publishes its public same-Hero contact request"):
		_finish(); return
	await _settle()
	if not _expect(_actual_l2_ready(), "uninstalled actual L2 candidate captures and installs through the production next-level flow: " + game.campaign_error):
		_finish(); return
	_expect(_saw_candidate("A1-L1"), "incoming actual L2 has a distinct native World3D while L1 is still installed")
	_expect(_bindings_live(), "actual L2 retains one Hero and all four actors/five impacts in its installed native world")
	var entry: Dictionary = game.attempts.state().story.checkpoint.duplicate(true)
	if not _expect(not entry.is_empty() and Exact.stringify(game.capture_campaign_snapshot()) == Exact.stringify(entry), "actual L2 initial retry checkpoint is a complete exact paused aggregate"):
		_finish(); return
	_expect(entry.player.resources.hp == 22.0 and entry.player.resources.shells == 0 and entry.level.local.beat_index == 0 and entry.level.local.scheduler.profile.id == "assisted", "fresh L2 carries injured HP/zero ammo and resolves the public Assisted preference")
	_expect(game.attempts.state().completed_main == ["A1-L1"] and not game.active_level.is_completed() and game.player.presentation_id == "act1_expedition", "test handoff alone is completed; actual L2 keeps the shared G07 Hero and unfinished progression")
	if not _press("ResumeButton"):
		_finish(); return
	var landing: CinderLaneMechanism = (game.active_level.get("circles") as Dictionary)["landing-impact"]
	if not _expect(await _wait_for(func() -> bool: return not paused and landing.state().status == "running" and landing.state().phase == "warning", 300), "actual Resume naturally admits the native landing warning without staging a phase or scheduler clock"):
		_finish(); return
	# Capture this particular ammo-empty state immediately before requesting the
	# normal deferred pause; never disable or patch the shared reload clock.
	game.player.shells = 0
	game.request_pause()
	await _settle()
	var warning: Dictionary = game.capture_campaign_snapshot()
	if not _expect(not warning.is_empty() and game.campaign_error.is_empty(), "public Pause reaches a coherent deferred actor/level/scheduler save barrier: " + game.campaign_error):
		_finish(); return
	_expect(warning.player.resources.hp == 22.0 and warning.player.resources.shells == 0 and warning.level.local.circles["landing-impact"].status == "running" and warning.level.local.circles["landing-impact"].phase == "warning" and warning.level.local.scheduler.clock_s > 0.0, "saved real warning retains injured resources and its actual finite native clock")
	var wire: String = Exact.stringify(warning)
	var decoded: Dictionary = Exact.parse(wire)
	_expect(not wire.is_empty() and decoded.get("accepted", false) and decoded.get("value") is Dictionary and Exact.stringify(decoded.value) == wire, "whole paired warning transports exact scalar bits/types through published ExactJson")
	_expect(_durable_matches(), "actual paused attempt generation stores the complete exact payload in format2")
	await create_timer(0.08, true).timeout
	_expect(Exact.stringify(game.capture_campaign_snapshot()) == wire, "ordinary pause freezes actor, scheduler, retained sources, circles, camera and release anchor exactly")
	var identities: Dictionary = _identities()
	_watch_events()
	if not _select_profile("challenge"):
		_finish(); return
	_expect(game.get_difficulty_preference() == "challenge" and warning.level.local.scheduler.profile.id == "assisted" and Exact.stringify(game.capture_campaign_snapshot()) == wire, "public Challenge preference does not retune the already admitted Assisted warning")
	var preferences: Dictionary = Store.new(test_root + "preferences.json").read_payload()
	_expect(preferences.get("profile_id") == "challenge", "actual menu preference persists only in this process-specific user path")
	var malformed: Dictionary = warning.duplicate(true)
	malformed.level.local.circles["landing-impact"].exchange.source_position[0] += 0.25
	_reject_unchanged(malformed, "forged paired source position", true)
	malformed = warning.duplicate(true)
	malformed.level.local.circles["landing-impact"].clock_s += 1.0
	_reject_unchanged(malformed, "forged circle/scheduler clock", true)
	malformed = warning.duplicate(true)
	malformed.player.motion.position[0] += 0.25
	_reject_unchanged(malformed, "cross-forged saved Hero/sample", false)
	_expect(_identities() == identities and Exact.stringify(game.capture_campaign_snapshot()) == wire, "all malformed public attempts preserve retained live identity and complete warning state")
	# Close/reopen uses the exact production disk loader. Its validation candidate
	# is at spawn before saved Hero context validates the running source samples.
	game.free()
	await process_frame
	if not _new_shell():
		_finish(); return
	await _settle()
	if not _expect(paused and game.active_level == null and game.menu.page_name() == "title" and game.campaign_error.is_empty(), "fresh production shell validates the saved actual warning before displaying Title: " + game.campaign_error):
		_finish(); return
	_expect(_saw_candidate("") and game.get_difficulty_preference() == "challenge" and Exact.stringify(game.attempts.active_snapshot()) == wire, "fresh hidden native candidate accepts staged saved-Hero context and separately loads the new preference")
	if not _press("ContinueStoryButton"):
		_finish(); return
	await _settle()
	if not _expect(_actual_l2_ready() and Exact.stringify(game.capture_campaign_snapshot()) == wire, "fresh actual Continue restores the complete original warning without heal, refill or clock drift: " + game.campaign_error):
		_finish(); return
	_expect(_all_new(identities, _identities()) and _bindings_live(), "Continue creates new world/Hero/level/scheduler/source/cue identities with truthful current-world bindings")
	landing = (game.active_level.get("circles") as Dictionary)["landing-impact"]
	_expect(landing.get_cue().state().phase == "warning" and (game.active_level.get("scheduler") as CinderThreatScheduler).get_clock() == warning.level.local.scheduler.clock_s and game.capture_campaign_snapshot().level.local.scheduler.profile.id == "assisted", "restored native footprint keeps its warning, exact clock and original Assisted epoch despite Challenge preference")
	var continued: Dictionary = _identities()
	game.request_pause()
	await _settle()
	if not _press("RetryButton"):
		_finish(); return
	await _settle()
	if not _expect(_actual_l2_ready() and Exact.stringify(game.capture_campaign_snapshot()) == Exact.stringify(entry), "actual Retry restores the exact initial L2 checkpoint without healing or refilling: " + game.campaign_error):
		_finish(); return
	_expect(_all_new(continued, _identities()) and _bindings_live() and paused and game.menu.page_name() == "resume", "Retry installs another real candidate and waits for public Resume")
	landing = (game.active_level.get("circles") as Dictionary)["landing-impact"]
	_expect(landing.state().status == "idle" and landing.get_cue().state().phase == "clear" and game.player.hp == 22.0 and game.player.shells == 0 and game.get_difficulty_preference() == "challenge", "retry clears the retired warning while retaining injured resources and independent next-encounter preference")
	_expect(game.attempts.state().completed_main == ["A1-L1"] and not game.active_level.is_completed() and _durable_matches(), "save/Continue/Retry do not fabricate L2 progression or completion")
	_finish()


func _new_shell() -> bool:
	game = Shell.new()
	if not _expect(game.configure_runtime(raw, test_root + "campaign.json", test_root + "settings.json", test_root + "preferences.json"), "test-only metadata and isolated paths configure the actual production shell"):
		game.free(); return false
	root.add_child(game)
	return true


func _observe_candidate(node: Node) -> void:
	if not node is CinderLevel or node.scene_file_path != LEVEL_PATH or not is_instance_valid(game) or not is_instance_valid(game.world): return
	var incoming := node as CinderLevel
	candidates.append({"old_level": game.active_level.level_id if is_instance_valid(game.active_level) else "", "separate": incoming.get_world_3d() != game.world.get_world_3d() and incoming != game.active_level})


func _saw_candidate(old_level: String) -> bool:
	for observation: Dictionary in candidates:
		if observation.old_level == old_level and observation.separate: return true
	return false


func _actual_l2_ready() -> bool:
	return game.campaign_error.is_empty() and is_instance_valid(game.active_level) and game.active_level.level_id == "A1-L2" and game.active_level.scene_file_path == LEVEL_PATH and game.active_level.contract_error().is_empty()


func _bindings_live() -> bool:
	if not _actual_l2_ready() or game.active_level.hero != game.player or game.active_level.shared_shell != game: return false
	var bindings: Dictionary = game.active_level.call("scheduler_bindings")
	if bindings.world_root != game.world or game.active_level.get_world_3d() != game.player.get_world_3d(): return false
	for collection: String in ["sources", "circles"]:
		for actor: Node3D in (game.active_level.get(collection) as Dictionary).values():
			if actor.get_parent() != game.active_level or actor.get_world_3d() != game.player.get_world_3d(): return false
	return (game.active_level.get("sources") as Dictionary).size() == 4 and (game.active_level.get("circles") as Dictionary).size() == 5


func _identities() -> Dictionary:
	var result: Dictionary = {"world": game.world.get_instance_id(), "native_world": game.world.get_world_3d().get_instance_id(), "hero": game.player.get_instance_id(), "level": game.active_level.get_instance_id(), "scheduler": (game.active_level.get("scheduler") as Node).get_instance_id()}
	for collection: String in ["sources", "circles"]:
		var actors: Dictionary = game.active_level.get(collection)
		for id: String in actors:
			result[collection + "/" + id] = actors[id].get_instance_id()
			result[collection + "/" + id + "/cue"] = actors[id].get_cue().get_instance_id()
	return result


func _all_new(before: Dictionary, after: Dictionary) -> bool:
	if before.size() != after.size(): return false
	for id: String in before:
		if not after.has(id) or before[id] == after[id]: return false
	return true


func _watch_events() -> void:
	game.active_level.checkpoint_requested.connect(func(_level: String, _checkpoint: String, _kind: String) -> void: events += 1)
	game.active_level.completion_requested.connect(func(_level: String, _completion: String) -> void: events += 1)
	for collection: String in ["sources", "circles"]:
		for actor: Node in (game.active_level.get(collection) as Dictionary).values():
			actor.connect("state_changed", func(_state: Dictionary) -> void: events += 1)


func _reject_unchanged(malformed: Dictionary, description: String, reject_local_restore: bool) -> void:
	var before: String = Exact.stringify(game.capture_campaign_snapshot())
	var memory: String = Exact.stringify(game.attempts.state())
	var disk: String = FileAccess.get_file_as_string(test_root + "campaign.json")
	var backup: String = FileAccess.get_file_as_string(test_root + "campaign.json.bak")
	var identities: Dictionary = _identities()
	var prior_events: int = events
	_expect(not game.active_level.snapshot_error_with_player(malformed.level, malformed.player).is_empty(), description + " rejects through public saved-player context")
	if reject_local_restore:
		_expect(not game.active_level.restore_state(malformed.level), description + " rejects direct local restore before any commit")
	_expect(not game.attempts.record_snapshot(malformed), description + " rejects through the actual campaign save validator")
	_expect(Exact.stringify(game.capture_campaign_snapshot()) == before and Exact.stringify(game.attempts.state()) == memory and FileAccess.get_file_as_string(test_root + "campaign.json") == disk and FileAccess.get_file_as_string(test_root + "campaign.json.bak") == backup and _identities() == identities and events == prior_events, description + " changes no actor, progress, cue, scheduler, live identity or durable generation")


func _durable_matches() -> bool:
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(test_root + "campaign.json"))
	if not envelope is Dictionary or envelope.get("format_version") != 2: return false
	var decoded: Dictionary = Exact.parse(String(envelope.get("payload_json", "")))
	return decoded.get("accepted", false) and decoded.get("value") is Dictionary and Exact.stringify(decoded.value) == Exact.stringify(game.attempts.state())


func _press(name: String) -> bool:
	var button := game.menu.find_child(name, true, false) as Button
	if not _expect(is_instance_valid(button) and not button.disabled and button.is_visible_in_tree(), "actual menu exposes enabled " + name): return false
	button.pressed.emit()
	return true


func _select_profile(id: String) -> bool:
	if not _press("SettingsButton"): return false
	var selector := game.menu.find_child("DifficultySelector", true, false) as OptionButton
	if not _expect(is_instance_valid(selector) and game.menu.page_name() == "settings", "actual Settings exposes the public difficulty selector"): return false
	var selected: bool = false
	for index: int in range(selector.item_count):
		if selector.get_item_metadata(index) == id:
			selector.select(index)
			selector.item_selected.emit(index)
			selected = true
			break
	if not _expect(selected and game.get_difficulty_preference() == id, "actual menu persists public " + id + " preference"): return false
	return _press("BackButton")


func _settle() -> void:
	for index: int in range(6):
		if finishing: return
		await process_frame


func _wait_for(predicate: Callable, attempts: int) -> bool:
	for index: int in range(attempts):
		if finishing: return false
		if predicate.call() == true: return true
		await create_timer(0.01, true).timeout
	return false


func _finish() -> void:
	if finishing: return
	finishing = true
	if node_added.is_connected(_observe_candidate): node_added.disconnect(_observe_candidate)
	if is_instance_valid(game): game.free()
	paused = false
	# Shared effects may own short native audio tails. Retire them before quit.
	await create_timer(0.5, true).timeout
	await process_frame
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == registry_text, "test metadata never mutates the canonical production registry")
	_cleanup_files()
	Engine.max_fps = old_fps
	AudioServer.set_bus_layout(old_audio)
	print("A1-L2 actual campaign landing lifecycle: %d checks, %d failures (TEST L1 handoff/metadata; no route or completion acceptance)" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _cleanup_files() -> void:
	# The stores use unique temporary suffixes. This directory belongs only to
	# this fixture's OS process; remove its files rather than shared user saves.
	var directory := DirAccess.open(test_root)
	if directory != null:
		for filename: String in directory.get_files():
			DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root + filename))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))


func _expect(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + message)
	return ok
