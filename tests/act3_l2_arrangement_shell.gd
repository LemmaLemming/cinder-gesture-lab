extends "res://tests/acts/act3/pillars_before_time_optional_shell.gd"
## Actual canonical Shell consumer of new retained Forest arrangement.
## Disclosed TEST prefix11 and stable representative Hero placement only.
## Full-route/completion/contact/all-kit behavior is outside this check.

class ProfileMain:
	extends "res://scripts/game.gd"
	func get_difficulty_preference() -> String:
		return "challenge"

var rows: Array[Dictionary] = []
var first_failure: Dictionary = {}
var receipts: Array[Dictionary] = []
var report_path: String
var source_before: Dictionary
var named_sources: Array[String] = []

func _initialize() -> void:
	isolated = "user://test-forest-arrangement-shell-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	old_audio = AudioServer.generate_bus_layout(); old_fps = Engine.max_fps
	report_path = OS.get_environment("CINDER_FOREST_SHELL_REPORT")
	var supplied: Variant = JSON.parse_string(OS.get_environment("CINDER_FOREST_ARRANGEMENT_SOURCES"))
	if supplied is Array:
		for name: Variant in supplied:
			if name is String: named_sources.append(name)
	source_before = _source_observation()
	_run.call_deferred()

func _run() -> void:
	create_timer(120.0, true).timeout.connect(func() -> void:
		if not finished: _expect(false, "bounded actual Shell retained-arrangement watchdog"); _finish.call_deferred())
	root.size = Vector2i(540, 1170)
	canonical_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	raw = JSON.parse_string(canonical_bytes)
	node_added.connect(_watch_node)
	var registry = Registry.new()
	if not _expect(OS.get_cmdline_user_args().is_empty() and not report_path.is_empty() and not named_sources.is_empty() and registry.last_error.is_empty(), "actual canonical registry and closed changed-level Shell scope") or not await _seed_story(registry) or not await _new_shell(expected_session):
		await _finish(); return
	production.menu.continue_story_requested.emit()
	if not await _wait_installed(STORY_ID, "resume", protected): await _finish(); return
	var entrance: Dictionary = production.capture_campaign_snapshot()
	if not _expect(entrance.level.local.arrangement.profile == "challenge" and entrance.level.local.scheduler.profile.id == "challenge" and production.get_difficulty_preference() == "standard", "actual independent canonical Continue constructs saved Challenge bindings despite default Standard preference") or not _disk(expected_session):
		await _finish(); return
	production.menu.resume_requested.emit()
	for _frame: int in range(120):
		await process_frame
		if not _valid_shell(): await _finish(); return
		if not paused and production.player.get_threat_response_state().stable: break
	if not _expect(not paused and production.player.get_threat_response_state().stable, "actual public Resume settles the shared Hero on native floor"):
		await _finish(); return
	# TEST ONLY representative location; native ticks create all chronology.
	production.request_pause()
	if not await _wait_pause(): await _finish(); return
	# Each representative TEST relocation crosses exactly one native entry.
	# The real Shell must durably settle that checkpoint before the next one.
	var sites: Array[float] = [37.5, 25.5, 10.5]
	var checkpoints: Array[String] = ["forest-threshold-entry", "root-promise-entry", "trunk-court-entry"]
	for index: int in range(sites.size()):
		production.player.global_position = Vector3(0, production.player.global_position.y, sites[index])
		production.menu.resume_requested.emit()
		var settled: bool = false
		for _frame: int in range(120):
			await process_frame
			if not _valid_shell(): await _finish(); return
			var model: Dictionary = production.attempts.state()
			if production.active_level.call("state").entries.size() == index + 1 and model.story.checkpoint.level.progress.checkpoint_id == checkpoints[index]:
				settled = true; break
		if not _expect(settled, "native ordered checkpoint settles durably before next TEST location: " + checkpoints[index]): await _finish(); return
		production.request_pause()
		if not await _wait_pause(): await _finish(); return
	production.menu.resume_requested.emit()
	var observed: bool = false
	for _frame: int in range(1200):
		await physics_frame
		await process_frame
		if not _valid_shell() or production.player.dead: break
		var state: Dictionary = production.active_level.call("state")
		if state.entries.size() == 3 and state.source_states["l2-priority-stalker"].phase == "warning":
			production.request_pause(); observed = true; break
	if not _expect(observed, "actual new trunk Stalker produces a genuine warning after native sequential entry checkpoints") or not await _wait_pause(): await _finish(); return
	var saved: Dictionary = production.capture_campaign_snapshot()
	var earlier: Dictionary = production.attempts.state().story.checkpoint.duplicate(true)
	if not _expect(not saved.is_empty() and saved.level.local.arrangement == entrance.level.local.arrangement and saved.level.local.route.entries.size() == 3 and saved.level.local.route.deaths.is_empty() and saved.level.local.scheduler.reservations.size() >= 1, "whole current partial native warning Save retains new recipe, live lease and real entry history") or not _disk(production.attempts.state()):
		await _finish(); return
	receipts.append({"stage": "actual public Pause warning Save", "exact_snapshot": Exact.stringify(saved), "exact_session": Exact.stringify(production.attempts.state()), "exact_checkpoint": Exact.stringify(earlier)})
	production.menu.difficulty_preference_requested.emit("assisted")
	if not _expect(production.get_difficulty_preference() == "assisted" and _same(production.capture_campaign_snapshot(), saved), "preference change leaves current native profile/recipe/complete packet unchanged"):
		await _finish(); return
	var session: Dictionary = production.attempts.state()
	var before_ids: Dictionary = _core_ids()
	await _dispose_shell()
	if not await _new_shell(session): await _finish(); return
	production.menu.continue_story_requested.emit()
	if not await _wait_installed(STORY_ID, "resume", saved): await _finish(); return
	if not _expect(_core_ids() != before_ids and production.get_difficulty_preference() == "assisted" and production.active_level.get("threat_scheduler").encounter_profile().id == "challenge" and _same(production.attempts.state().story.checkpoint, earlier), "fresh actual disk Continue restores original Challenge epoch under newer Assisted preference and retains prior checkpoint"):
		await _finish(); return
	var baseline: String = Exact.stringify(production.capture_campaign_snapshot())
	var disk_sha: String = FileAccess.get_sha256(isolated + "campaign.json")
	var malformed: Dictionary = saved.duplicate(true)
	malformed.level.local.arrangement.order.reverse()
	var candidate: Dictionary = production._prepare_snapshot(malformed)
	var rejected: bool = candidate.is_empty()
	if not candidate.is_empty(): production._dispose(candidate)
	if not _expect(rejected and Exact.stringify(production.capture_campaign_snapshot()) == baseline and FileAccess.get_sha256(isolated + "campaign.json") == disk_sha and _same(production.attempts.state(), session), "tampered retained order refuses atomically without donor, complete session or disk mutation"):
		await _finish(); return
	production.campaign_error = "" # Clear expected refusal diagnostic only.
	before_ids = _core_ids()
	production.menu.retry_requested.emit()
	if not await _wait_installed(STORY_ID, "resume", earlier, before_ids): await _finish(); return
	if not _expect(production.capture_campaign_snapshot().level.local.arrangement == saved.level.local.arrangement and production.active_level.get("threat_scheduler").encounter_profile().id == "challenge" and production.attempts.state().completed_main == expected_session.completed_main and production.attempts.state().completed_optional.is_empty(), "public Retry reconstructs the real entry checkpoint's own recipe/profile without inferred completion") or not _disk(production.attempts.state()):
		await _finish(); return
	receipts.append({"stage": "actual public Retry earlier checkpoint", "exact_snapshot": Exact.stringify(production.capture_campaign_snapshot()), "exact_session": Exact.stringify(production.attempts.state())})
	scope_complete = true
	await _finish()

func _new_shell(expected: Dictionary) -> bool:
	receiver_events.clear(); watched.clear()
	production = Shell.new()
	if not _expect(production.configure_runtime({}, isolated + "campaign.json", isolated + "settings.json", isolated + "preferences.json"), "actual canonical Shell receives no substitute registry", production.campaign_error): return false
	root.add_child(production)
	for _frame: int in range(FRAME_LIMIT):
		await process_frame
		if not _valid_shell(): return false
		if paused and not production.is_pause_requested() and production.menu.page_name() == "title" and production.player == null and production.active_level == null and _same(production.attempts.state(), expected): return true
	return _expect(false, "actual canonical Title startup retains whole expected session", production.campaign_error)

func _source_observation() -> Dictionary:
	var result: Dictionary = {}
	for name: String in named_sources: result[name] = FileAccess.get_sha256("res://" + name) if FileAccess.file_exists("res://" + name) else null
	return result

func _expect(ok: bool, label: String, detail: String = "") -> bool:
	checks += 1
	var row: Dictionary = {"n": checks, "ok": ok, "label": label, "detail": detail}
	rows.append(row)
	if not ok:
		failures += 1
		if first_failure.is_empty(): first_failure = row.duplicate(true)
		push_error("FAIL FOREST SHELL: " + label + "; " + detail)
	else: print("PASS: " + label)
	return ok

func _finish() -> void:
	if finished: return
	finished = true
	await _dispose_shell()
	if is_instance_valid(preview): preview.free(); preview = null
	if node_added.is_connected(_watch_node): node_added.disconnect(_watch_node)
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == canonical_bytes, "canonical registry unchanged")
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		var path: String = isolated + name
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(isolated))
	AudioServer.set_bus_layout(old_audio); Engine.max_fps = old_fps; paused = false
	var report: Dictionary = {"checks": checks, "failures": failures, "rows": rows, "first_failure": first_failure, "complete": scope_complete, "success": scope_complete and failures == 0, "receipts": receipts, "source_before": source_before, "source_after": _source_observation(), "scope": "Actual canonical Shell newrecipe Save/diskContinue/oppositepreference/Retry/cleanup;TESTprefix11,preferencecaller,stableHero placement only. No route/clears/completion/contact/balance/allkit/legacy claim."}
	if not report_path.is_empty():
		var f: FileAccess = FileAccess.open(report_path, FileAccess.WRITE)
		if f != null: f.store_string(JSON.stringify(report, "  ") + "\n"); f.close()
	print("FOREST_SHELL ", checks, "/", failures, " complete=", scope_complete, " report=", report_path, " sha256=", FileAccess.get_sha256(report_path))
	quit(0 if scope_complete and failures == 0 else 1)

func _seed_story(registry: CinderCampaignRegistry) -> bool:
	paused = true
	preview = MainScene.instantiate()
	preview.set_script(ProfileMain)
	preview.set("level_scene_path", STORY_PATH)
	root.add_child(preview)
	preview.call("open_bench") # Main construction resumes; restore the actual public paused boundary before any frame.
	var actor: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var camera: Camera3D = preview.get("camera") as Camera3D
	if not _expect(actor != null and level != null and camera != null and level.level_id == STORY_ID and String(preview.get("level_load_error")).is_empty(), "actual accepted Main opening constructs the protected Story donor"):
		return false
	await process_frame # Native ready/layout only; gameplay remains paused.
	var actor_state: Dictionary = actor.snapshot_state()
	var local_state: Dictionary = level.snapshot_state()
	var input: Dictionary = preview.call("get_input_observation_state")
	if not _expect(paused and not actor_state.is_empty() and not local_state.is_empty() and actor.get_world_action_records().is_empty() and input.sequence == 0 and input.last_observation.is_empty(), "actual paused initial actor/local/input writers contain no fabricated gameplay", actor.last_snapshot_error + "; " + level.last_snapshot_error):
		return false
	var anchor: Vector2 = input.anchor_normalized
	var fresh_shell: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": input.sequence, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Game.CAMERA_OFFSET), "shake_left_s": 0.0, "difficulty_at_entry": "challenge"}
	protected = {"schema_version": 1, "level_id": STORY_ID, "scene_path": STORY_PATH, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": actor_state, "level": local_state, "shell": fresh_shell}
	var detached = Attempts.new(registry)
	expected_session = detached.state()
	expected_session.completed_main = registry.main_route().slice(0, 11) # TEST ONLY predecessor completions.
	expected_session.story = {"kind": "story", "level_id": STORY_ID, "snapshot": protected.duplicate(true), "checkpoint": protected.duplicate(true)}
	var problem: String = detached.state_error(expected_session)
	var writer = Store.new(isolated + "campaign.json")
	writer.payload_validator = detached.saved_payload_error # Structural model, never a live Shell validator.
	if not _expect(problem.is_empty() and expected_session.completed_main[-1] == "A3-L1" and writer.write_payload(expected_session), "detached structural Attempts/format2 Store seed TEST predecessor prefix plus real complete native Story packet", problem + "; " + writer.last_error):
		return false
	var refs: Array[WeakRef] = []
	_collect_refs(preview, refs)
	level.exit_level()
	preview.queue_free()
	preview = null
	return await _released(refs, "seed donor normal whole-tree retirement") and _disk(expected_session)

