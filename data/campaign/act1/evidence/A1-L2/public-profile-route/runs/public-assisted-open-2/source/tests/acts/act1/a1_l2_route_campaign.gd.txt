extends "res://tests/acts/act1/a1_l2_route.gd"
## Real CampaignShell adapter over the unchanged actual-touch Main route.
## TEST accepted metadata and the existing generic L1 handoff are setup only.
## Actual L2 starts at spawn; no player/source motion, HP, phase, progression,
## scheduler clock, difficulty getter or controller is substituted. The route
## stops at genuine L2 completion, without contacting an unaccepted next level.
const CampaignShellScript = preload("res://scripts/campaign/shell.gd")
const CampaignRegistryScript = preload("res://scripts/campaign/registry.gd")
const SaveStoreScript = preload("res://scripts/campaign/save_store.gd")
const TestHandoffPath: String = "res://tests/fixtures/campaign/live_a1_l1.tscn"
const CampaignScope: String = "actual authored L2 touch route through production CampaignShell; TEST L1 metadata/public handoff only; real Settings profile, checkpoint saves and completion format2; no L1 route, next-level contact, teleports, phase forcing, human or native-focus override"
var test_root: String = ""
var registry_text: String = ""
var old_fps: int = 0
var old_audio: AudioBusLayout
var boundary_ids: Array[String] = []
var pending_boundaries: Array[Dictionary] = []
var boundary_evidence: Array[Dictionary] = []
var boundary_busy: bool = false
var campaign_evidence: Dictionary = {}


func _initialize() -> void:
	test_root = "user://test-act1-crater-route-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	old_fps = Engine.max_fps
	old_audio = AudioServer.generate_bus_layout()
	process_frame.connect(_poll_campaign_boundaries)
	super._initialize()


func _profile_supported() -> bool:
	# Fresh production ownership contains starter gear only. Other existing kits
	# remain the preview fixture's scope; no fixture invents a reward/unlock here.
	return _require(profile in ["standard", "assisted", "challenge"] and kit == "neutral", "campaign route supports public Standard/Assisted/Challenge with owned neutral starter gear; other kits belong to the preview route")


func _start_game() -> bool:
	registry_text = FileAccess.get_file_as_string(CampaignRegistryScript.DATA_PATH)
	var parsed: Variant = JSON.parse_string(registry_text)
	if not _require(parsed is Dictionary and parsed.get("levels") is Array, "canonical registry supplies the isolated in-memory TEST metadata"): return false
	var raw: Dictionary = parsed.duplicate(true)
	for info: Dictionary in raw.levels:
		if info.id in ["A1-L1", "A1-L2"]:
			info.scene_path = TestHandoffPath if info.id == "A1-L1" else LevelPath
			info.readiness = "accepted"
			info.accepted_commit = "f".repeat(40)
			info.api_revision = CampaignRegistryScript.API_REVISION
	_cleanup_files()
	game = CampaignShellScript.new()
	if not _require(_shell().configure_runtime(raw, test_root + "campaign.json", test_root + "settings.json", test_root + "preferences.json"), "actual shell configures only unique fixture save/settings/preference paths"): return false
	root.add_child(game)
	if not await _settle_shell(): return false
	if not _require(paused and _shell().active_level == null and _shell().menu.page_name() == "title", "actual isolated shell begins at Title with no playable actor"): return false
	if not _select_profile(profile): return false
	if not _require(_shell().settings.storage_path() == test_root + "settings.json" and SaveStoreScript.new(test_root + "preferences.json").read_payload().get("profile_id") == profile, "actual Settings selector persists the chosen profile in isolated public storage"): return false
	if not _press_setup_button("JourneyButton"): return false
	if not await _settle_shell(): return false
	if not _require(paused and _shell().menu.page_name() == "journey", "actual Journey waits for public Begin"): return false
	_shell().menu.select_level("A1-L1")
	if not _press_setup_button("LevelCardAction"): return false
	if not await _settle_shell(): return false
	if not _require(is_instance_valid(_shell().active_level) and _shell().active_level.scene_file_path == TestHandoffPath and _shell().campaign_error.is_empty(), "Journey starts only the existing TEST L1 handoff fixture: " + _shell().campaign_error): return false
	# These are the generic fixture's public authored events. Its paused Hero is
	# neither moved nor injured. This is not evidence of playing through L1.
	if not _require(_shell().active_level.request_completion("test-crater-handoff"), "TEST predecessor publishes its existing public completion handoff"): return false
	if not await _settle_shell(): return false
	if not _require(_shell().active_level.request_contact_exit("test-crater-contact", _shell().player), "TEST predecessor publishes its public same-Hero contact handoff"): return false
	if not await _settle_shell(): return false
	if not _require(paused and _shell().campaign_error.is_empty() and is_instance_valid(_shell().active_level) and _shell().active_level.scene_file_path == LevelPath and _shell().active_level.level_id == "A1-L2", "actual shell installs the authored L2 candidate at its genuine paused entry: " + _shell().campaign_error): return false
	var entry: Dictionary = _shell().capture_campaign_snapshot()
	var state: Dictionary = _shell().attempts.state()
	if not _require(not entry.is_empty() and Exact.stringify(entry) == Exact.stringify(state.story.checkpoint) and entry.level.local.beat_index == 0 and entry.player.resources.hp == _shell().player.max_hp and entry.level.local.scheduler.profile.id == profile and state.completed_main == ["A1-L1"], "fresh authored L2 entry has a whole native checkpoint, full carried HP and selected actual profile; only TEST L1 is complete"): return false
	if not _require(_durable_matches(), "actual initial L2 attempt persists exact format2 at its own fixture path"): return false
	_shell().active_level.checkpoint_requested.connect(_checkpoint_boundary)
	_shell().active_level.completion_requested.connect(_completion_boundary)
	campaign_evidence = {"scope": CampaignScope, "test_handoff_scene": TestHandoffPath, "actual_level_scene": LevelPath, "profile": profile, "kit": kit, "initial_checkpoint_exact_json": Exact.stringify(entry), "settings_path": _shell().settings.storage_path(), "isolated_save_path": test_root + "campaign.json"}
	return true


func _shell() -> CinderCampaignShell:
	return game as CinderCampaignShell


func _route_has_contact() -> bool:
	return false


func _resume_surface() -> Node:
	return _shell().menu


func _resume_button(node: Node) -> Button:
	# CampaignMenu's actual text is title-case "Resume", whereas preview HUD
	# uses uppercase. Select the existing named public control, without mutation.
	if node == null: return null
	var button := node.find_child("ResumeButton", true, false) as Button
	return button if is_instance_valid(button) and not button.disabled and button.is_visible_in_tree() else null


func _pause_game() -> void:
	_shell().request_pause()


func _checkpoint_boundary(_level_id: String, id: String, kind: String) -> void:
	if not _require(boundary_ids.size() < 4 and id == Progress[boundary_ids.size()] and kind == "encounter", "real checkpoint signal retains the exact four authored boundary IDs/order"): return
	_boundary_requested("checkpoint", id)


func _completion_boundary(_level_id: String, id: String) -> void:
	if not _require(boundary_ids == Progress.slice(0, 4) and id == Progress[4], "real completion follows exactly the four authored checkpoints"): return
	_boundary_requested("completion", id)


func _boundary_requested(kind: String, id: String) -> void:
	# Shell already subscribed to these actual signals before the fixture did.
	# Entitlement lasts only for this observed operation and never a focus pause.
	boundary_ids.append(id)
	pending_boundaries.append({"kind": kind, "id": id, "hp": _shell().player.hp, "deadline_ms": Time.get_ticks_msec() + 2500})


func _poll_campaign_boundaries() -> void:
	if finished or aborted or pending_boundaries.is_empty() or boundary_busy: return
	boundary_busy = true
	_service_campaign_boundary.call_deferred()


func _service_campaign_boundary() -> void:
	var operation: Dictionary = pending_boundaries[0]
	# Public automatic checkpoint/complete resume is respected. Only a Resume
	# menu that remains after the actual save gets a real consumed GUI click.
	for frame: int in range(3):
		await process_frame
		if finished or aborted: boundary_busy = false; return
		if not _transition_allowed(): boundary_busy = false; return
	var state: Dictionary = _shell().attempts.state()
	var saved: Dictionary = state.story.snapshot
	var progress: Dictionary = saved.level.progress
	var boundary_ok: bool = progress.checkpoint_id == operation.id if operation.kind == "checkpoint" else progress.completed and progress.completion_id == operation.id and state.completed_main == ["A1-L1", "A1-L2"]
	if not _require(_shell().campaign_error.is_empty() and boundary_ok and saved.level_id == "A1-L2" and saved.scene_path == LevelPath and saved.level.scene_path == LevelPath and saved.player.resources.hp == operation.hp and saved.level.local.scheduler.profile.id == profile and not Exact.stringify(saved).is_empty() and _durable_matches(), "actual " + operation.id + " saves the complete same-resource/profile authored unit in format2: " + _shell().campaign_error): boundary_busy = false; return
	var gui_resumed: bool = false
	if paused:
		if not _require(_shell().menu.is_open() and _shell().menu.page_name() == "resume", "only this saved authored boundary's Resume menu may receive automatic fixture GUI input"): boundary_busy = false; return
		if not await _click_boundary_resume(): boundary_busy = false; return
		gui_resumed = true
	if not _require(not paused and not _shell().menu.is_open(), "actual saved boundary returns to gameplay through public auto-resume or real GUI Resume"): boundary_busy = false; return
	boundary_evidence.append({"kind": operation.kind, "id": operation.id, "snapshot_exact_json": Exact.stringify(saved), "hp_at_request": operation.hp, "format_version": 2, "gui_resume_consumed": gui_resumed, "public_auto_resume": not gui_resumed})
	pending_boundaries.pop_front()
	boundary_busy = false


func _click_boundary_resume() -> bool:
	var button: Button = _resume_button(_resume_surface())
	if not _require(button != null, "expected campaign boundary exposes its actual visible Resume control"): return false
	var before: Dictionary = _shell().get_input_observation_state()
	var actions: Array[Dictionary] = hero.get_world_action_records()
	var point: Vector2 = button.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = point; press.global_position = point
	Input.parse_input_event(press)
	await process_frame
	if finished or aborted: return false
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT; release.position = point; release.global_position = point
	Input.parse_input_event(release)
	await process_frame
	if finished or aborted: return false
	return _require(not paused and _shell().get_input_observation_state() == before and Codec.same_values(hero.get_world_action_records(), actions), "actual boundary GUI Resume is consumed without combat, movement or release-anchor changes")


func _transition_allowed() -> bool:
	if finished or aborted or not is_instance_valid(game): return false
	if not _require(not pending_boundaries.is_empty() and Time.get_ticks_msec() <= int(pending_boundaries[0].deadline_ms) and _shell().campaign_error.is_empty(), "observed authored save transition finishes within its bounded public window: " + _shell().campaign_error): return false
	# A normal focus-out/user Pause produces the pause page, not an entitled
	# checkpoint Resume. Reject it; never repeatedly resume or change focus.
	return _require(not paused or not _shell().menu.is_open() or _shell().menu.page_name() == "resume", "authored transition cannot authorize a normal focus-out or user Pause menu")


func _guard_input() -> bool:
	if finished or aborted: return false
	if not _require(is_instance_valid(hero) and not hero.dead and (not graphical or scripted_portrait or _native_focus()), "campaign route requires its actual live Hero and unchanged observed focus policy"): return false
	if not pending_boundaries.is_empty(): return _transition_allowed()
	return _require(not paused and _shell().campaign_error.is_empty(), "campaign gesture requires normal unpaused gameplay outside public authored save transitions: " + _shell().campaign_error)


func _ready_for_input(label: String) -> bool:
	return await _wait(func() -> bool:
		if paused or boundary_busy or not pending_boundaries.is_empty(): return false
		var response: Dictionary = hero.get_threat_response_state()
		return response.stable and float(response.dash_cooldown_left_s) == 0.0 and float(response.primary_cooldown_left_s) == 0.0 and float(response.commitment_remaining_s) == 0.0, label + " real campaign unpaused input readiness", 250)


func _capture(stage: String) -> bool:
	if not await _settle_boundaries(): return false
	return await super._capture(stage)


func _settle_boundaries() -> bool:
	while boundary_busy or not pending_boundaries.is_empty():
		if finished or aborted or not _transition_allowed(): return false
		await process_frame
	return not aborted and not finished


func _extra_completion_checks() -> bool:
	if not await _settle_boundaries(): return false
	if not _require(boundary_ids == Progress.slice(0, 5) and boundary_evidence.size() == 5, "real shell has saved each of four native checkpoints and the final completion exactly once"): return false
	_shell().request_pause()
	if not await _settle_shell(): return false
	if not _require(paused and _shell().menu.page_name() == "pause" and _shell().campaign_error.is_empty(), "public final Pause reaches the completed production save barrier: " + _shell().campaign_error): return false
	var final: Dictionary = _shell().capture_campaign_snapshot()
	var state: Dictionary = _shell().attempts.state()
	if not _require(not final.is_empty() and Exact.stringify(final) == Exact.stringify(state.story.snapshot) and state.completed_main == ["A1-L1", "A1-L2"] and state.completed_optional.is_empty() and state.reward_ids.is_empty() and state.side_attempt == null and _shell().attempts.active_kind() == "story" and _durable_matches(), "genuine L2 completion persists exact format2 story state without optional rewards, replay or a fabricated next-level transition"): return false
	if not _require(final.level.progress.completed and final.level.progress.completion_id == Progress[4] and final.level.progress.contact_exit_id.is_empty() and final.level.progress.checkpoint_ids.size() == 4 and state.story.checkpoint.level.progress.checkpoint_id == Progress[3] and state.story.checkpoint.level.local.beat_index == 4 and final.level.local.beat_index == 5 and final.player.resources.hp == initial_hp and final.level.local.scheduler.profile.id == profile, "completed native unit retains four checkpoints, the genuine quiet-camp retry unit, selected profile and unchanged HP; contact remains unclaimed"): return false
	for record: Dictionary in boundary_evidence:
		var decoded: Dictionary = Exact.parse(record.snapshot_exact_json)
		if not _require(decoded.get("accepted", false) and decoded.get("value") is Dictionary, record.id + " saved exact native boundary decodes without scalar/type drift"): return false
		var saved: Dictionary = decoded.value
		if not _require(level.snapshot_error_with_player(saved.level, saved.player).is_empty() and saved.player.resources.hp == initial_hp, record.id + " complete saved unit purely prevalidates against staged saved-Player context without healing"): return false
	campaign_evidence["boundaries"] = boundary_evidence.duplicate(true)
	campaign_evidence["completed_main"] = state.completed_main.duplicate()
	campaign_evidence["final_snapshot_exact_json"] = Exact.stringify(final)
	campaign_evidence["quiet_camp_retry_exact_json"] = Exact.stringify(state.story.checkpoint)
	campaign_evidence["format_version"] = 2
	campaign_evidence["physical_next_level_contact_claimed"] = false
	return true


func _durable_matches() -> bool:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(test_root + "campaign.json"))
	if not raw is Dictionary or raw.get("format_version") != 2: return false
	var decoded: Dictionary = Exact.parse(String(raw.get("payload_json", "")))
	return decoded.get("accepted", false) and decoded.get("value") is Dictionary and Exact.stringify(decoded.value) == Exact.stringify(_shell().attempts.state())


func _press_setup_button(name: String) -> bool:
	var button := _shell().menu.find_child(name, true, false) as Button
	if not _require(is_instance_valid(button) and not button.disabled and button.is_visible_in_tree(), "actual setup menu exposes enabled " + name): return false
	button.pressed.emit()
	return true


func _select_profile(id: String) -> bool:
	if not _press_setup_button("SettingsButton"): return false
	var selector := _shell().menu.find_child("DifficultySelector", true, false) as OptionButton
	if not _require(is_instance_valid(selector) and _shell().menu.page_name() == "settings", "actual Settings exposes its real profile selector"): return false
	var selected: bool = false
	for index: int in range(selector.item_count):
		if selector.get_item_metadata(index) == id:
			selector.select(index)
			selector.item_selected.emit(index)
			selected = true
			break
	if not _require(selected and _shell().get_difficulty_preference() == id, "actual public Settings persists " + id + " without a fixture getter or scheduler retune"): return false
	return _press_setup_button("BackButton")


func _settle_shell() -> bool:
	for frame: int in range(6):
		if finished or aborted: return false
		await process_frame
	return not finished and not aborted


func _cleanup_fixture() -> void:
	if process_frame.is_connected(_poll_campaign_boundaries): process_frame.disconnect(_poll_campaign_boundaries)
	if not registry_text.is_empty(): _require(FileAccess.get_file_as_string(CampaignRegistryScript.DATA_PATH) == registry_text, "TEST metadata leaves the canonical production registry byte-identical")
	# Base writes the real input/art record before freeing Game. Mark this
	# adapter's broader tested scope and attach its actual public save evidence.
	if graphical and not capture_dir.is_empty():
		var path: String = capture_dir.path_join("evidence.json")
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if _require(parsed is Dictionary, "campaign adapter retains the inherited native route evidence"):
			parsed["scope"] = CampaignScope
			parsed["campaign"] = campaign_evidence.duplicate(true)
			var file := FileAccess.open(path, FileAccess.WRITE)
			if _require(file != null, "campaign adapter annotates actual route/save evidence after native cleanup"):
				parsed["checks"] = checks
				parsed["failures"] = failures
				file.store_string(JSON.stringify(parsed, "\t"))
				file.close()
	_cleanup_files()
	Engine.max_fps = old_fps
	if old_audio != null: AudioServer.set_bus_layout(old_audio)


func _cleanup_files() -> void:
	if test_root.is_empty(): return
	var directory := DirAccess.open(test_root)
	if directory != null:
		for filename: String in directory.get_files():
			DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root + filename))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))
