extends "res://tests/acts/act1/a1_o3_campaign.gd"
## Root canonical focused registration; owner evidence is reused separately.
## Overrides owner _run; no inherited live-exercise/final/terminal/Replay run.
## Owner final mechanics, final-checkpoint Retry, contact/stamp/Replay and
## portrait evidence must be independently reviewed and reused outside it.
## TEST completed-main prefix4 comes only from actual pristine L4 donor.
## All installed O3 packets are native captures; no ID/schema coercion.
## Root-promoted short seam; actual native execution is recorded separately.
## Public menu/Button signals prove API wiring, not OS clicks or earned route.

const ACCEPTED_CONTENT: String = "3569663dd7a57d40f39cabfe92b1cef5c4c84873"
const SHORT_SOURCE_PATHS: Array[String] = [
	"res://tests/acts/act1/a1_o3_campaign.gd",
	"res://scripts/acts/act1/royal_rehearsal.gd",
	"res://scripts/acts/act1/royal_rehearsal_layout.gd",
	"res://scripts/acts/act1/royal_rehearsal_codec.gd",
	"res://scripts/acts/act1/royal_rehearsal_art.gd",
	"res://scripts/acts/act1/selenite_court.gd",
	"res://scripts/acts/act1/selenite_court_layout.gd",
	"res://scripts/acts/act1/selenite_court_codec.gd",
	"res://scripts/acts/act1/selenite_court_art.gd",
	"res://scripts/acts/act1/mushroom_selenite.gd",
	"res://scripts/acts/act1/mushroom_selenite_codec.gd",
	"res://scenes/acts/act1/a1_o3.tscn",
	"res://scenes/acts/act1/a1_l4.tscn",
	"res://scenes/main.tscn",
	"res://scripts/game.gd",
	"res://scripts/player.gd",
	"res://scripts/campaign/shell.gd",
	"res://scripts/campaign/level.gd",
	"res://scripts/campaign/registry.gd",
	"res://scripts/campaign/attempts.gd",
	"res://scripts/campaign/save_store.gd",
	"res://scripts/campaign/exact_json.gd",
	"res://scripts/campaign/snapshot_codec.gd",
	"res://scripts/combat/threat_scheduler.gd",
	"res://scripts/ui/campaign_menu.gd",
	"res://scripts/equipment.gd",
	"res://data/campaign/registry.json"
]

var entrance: Dictionary = {}
var _short_complete: bool = false
var _short_rows: Array[Dictionary] = []
var _short_first_failure: Dictionary = {}
var _short_before: Dictionary = {}
var _short_initial: Dictionary = {}
var _short_receipts: Array[Dictionary] = []
var _expected_disk: Dictionary = {}


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	test_root = "user://test-a1-o3-canonical-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	report_path = OS.get_environment("CINDER_A1_O3_SHORT_REGISTRATION_REPORT")
	if report_path.is_empty(): report_path = "user://test-a1-o3-short-registration-reports/%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	old_fps = Engine.max_fps
	old_audio = AudioServer.generate_bus_layout()
	process_frame.connect(_watchdog)
	node_added.connect(_observe_added)
	_short_before = _short_sources()
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	registry_bytes = FileAccess.get_file_as_bytes(Registry.DATA_PATH)
	if not _expect(OS.get_cmdline_user_args().is_empty(), "short fixture accepts no route/completed-session/Replay/skip selectors"):
		await _finish(); return
	var canonical: CinderCampaignRegistry = Registry.new()
	var row: Dictionary = canonical.entry(Layout.LEVEL_ID)
	if not _expect(canonical.last_error.is_empty() and canonical.ids().size() == 24 and row.get("readiness") == "accepted" and row.get("accepted_commit") == ACCEPTED_CONTENT and row.get("scene_path") == O3_PATH and row.get("api_revision") == Registry.API_REVISION and canonical.scene_error(Layout.LEVEL_ID).is_empty(), "actual canonical submitted O3 content/scene/API validates without registry override"):
		await _finish(); return
	if not _expect(row.get("parent_level_id") == "A1-L4" and canonical.entry("A1-L4").get("readiness") == "accepted" and not canonical.is_unlocked(Layout.LEVEL_ID, []) and not canonical.is_unlocked(Layout.LEVEL_ID, ["A1-L1", "A1-L2", "A1-L3"]) and canonical.is_unlocked(Layout.LEVEL_ID, ["A1-L4"]), "accepted canonical L4 alone unlocks O3"):
		await _finish(); return
	if not _expect(row.get("reward_id") == REWARD_ID and row.get("reward_policy") == "once_only_completion_stamp_no_stat_growth" and canonical.next_main("A1-L4") == "A1-L5", "once-only O3 stamp remains outside unchanged L4 to L5 main route"):
		await _finish(); return
	# Inherited donor constructs real L4 and only arranges disclosed TEST history.
	if not await _seed_story(canonical): await _finish(); return
	var reader: CinderSaveStore = Store.new(test_root + "campaign.json")
	_expected_disk = reader.read_payload()
	var model: CinderCampaignAttempts = Attempts.new(canonical)
	if not _expect(reader.last_error.is_empty() and model.state_error(_expected_disk).is_empty() and _expected_disk.side_attempt == null and _expected_disk.story.level_id == "A1-L4" and _expected_disk.completed_main == PREFIX and _expected_disk.completed_optional.is_empty() and _expected_disk.reward_ids.is_empty() and _closed(_expected_disk.story.snapshot) and _same(_expected_disk.story.snapshot, _expected_disk.story.checkpoint), "complete actual native L4 Story and whole isolated disk session close before optional installation; TEST prefix4 only"):
		await _finish(); return
	protected_story = _expected_disk.story.duplicate(true)
	unlocked_before = _expected_disk.unlocked_equipment.duplicate()
	_short_initial = {"whole_story_sha256": Exact.stringify(protected_story).sha256_text(), "whole_session_sha256": Exact.stringify(_expected_disk).sha256_text(), "whole_story_bytes": Exact.stringify(protected_story).to_utf8_buffer().size(), "whole_session_bytes": Exact.stringify(_expected_disk).to_utf8_buffer().size(), "independent_initial_disk_equal": true, "exact_whole_protected_story": Exact.stringify(protected_story), "exact_session": Exact.stringify(_expected_disk)}
	if not await _new_shell(): await _finish(); return
	operation = "canonical public protected Story Continue"
	game.menu.continue_story_requested.emit()
	if not await _await_operation(func() -> bool: return _live("A1-L4") and paused and game.menu.page_name() == "resume", "actual canonical Continue installs native protected L4", 12.0):
		await _finish(); return
	if not _expect(_same(game.capture_campaign_snapshot(), protected_story.snapshot) and _same(game.attempts.state().story, protected_story) and _same(game.attempts.state(), _expected_disk) and _disk_matches(_expected_disk), "installed L4 and post-disk entire protected Story/session match initial closed packet") or not await _quiet_selected("initial canonical protected L4"):
		await _finish(); return
	var refs: Array[WeakRef] = _refs(_world_container())
	var before: Dictionary = _core_ids()
	operation = "canonical public O3 Optional entry"
	game.menu.optional_requested.emit(Layout.LEVEL_ID)
	if not await _await_operation(func() -> bool: return _live(Layout.LEVEL_ID) and paused and game.menu.page_name() == "resume" and game.attempts.active_kind() == "optional", "canonical Optional installs pristine independent O3", 12.0):
		await _finish(); return
	entrance = game.capture_campaign_snapshot()
	if not _expect(_pristine(entrance) and game.active_level.get_script() == RehearsalScript and _bindings() and _core_new(before) and _freed(refs) and _same(game.attempts.state().story, protected_story) and _same(game.attempts.state().side_attempt.checkpoint, entrance) and _durable(), "canonical native O3 entrance retires entire Story world and protects complete Story/checkpoint/disk boundary"):
		await _finish(); return
	var before_refusal: Dictionary = game.attempts.state().duplicate(true)
	if not _expect(not game.active_level.request_completion(Layout.COMPLETION_ID) and not game.active_level.request_contact_exit(Layout.EXIT_ID, game.player) and _same(game.capture_campaign_snapshot(), entrance) and _same(game.attempts.state(), before_refusal) and _disk_matches(before_refusal), "real O3 completion/contact guards refuse unearned entrance without packet or stamp mutation"):
		await _finish(); return
	if not await _pause("canonical pristine entrance Save"): await _finish(); return
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_same(saved, entrance) and _same(game.attempts.state().story, protected_story), "public Pause Save keeps entire entrance and protected Story exact"):
		await _finish(); return
	if not await _reopen_side(saved, "canonical pristine entrance"): await _finish(); return
	# This only retries entrance; owner's real final checkpoint Retry is reused.
	if not await _pause("canonical entrance Retry page") or not await _retry_entrance(): await _finish(); return
	if not _expect(_same(game.attempts.state().story, protected_story) and _disk_matches(game.attempts.state()), "post-Retry disk retains complete Story metadata plus snapshot and checkpoint") or not await _quiet_selected("canonical entrance Retry recipient"):
		await _finish(); return
	refs = _refs(_world_container()); before = _core_ids()
	operation = "canonical early Leave Side"
	game.menu.leave_side_requested.emit()
	if not await _await_operation(func() -> bool: return _live("A1-L4") and paused and game.menu.page_name() == "journey" and game.attempts.active_kind() == "story", "canonical early Leave returns exact protected L4", 12.0):
		await _finish(); return
	var returned: Dictionary = game.attempts.state()
	if not _expect(_freed(refs) and _core_new(before) and _same(game.capture_campaign_snapshot(), protected_story.snapshot) and _same(returned.story, protected_story) and returned.side_attempt == null and returned.completed_main == PREFIX and returned.completed_optional.is_empty() and returned.reward_ids.is_empty() and returned.unlocked_equipment == unlocked_before and _disk_matches(returned), "uncompleted canonical Leave frees native O3 and preserves whole Story/main/equipment with no stamp or growth") or not await _quiet_selected("canonical returned protected L4"):
		await _finish(); return
	_short_complete = true
	await _finish()


func _new_shell() -> bool:
	operation = "actual canonical fresh whole-session disk Title"
	game = Shell.new() as CinderCampaignShell
	if not _expect(game.configure_runtime({}, test_root + "campaign.json", test_root + "settings.json", test_root + "preferences.json"), "canonical Shell uses default registry and unique isolated stores"): return false
	root.add_child(game)
	if not await _await_operation(func() -> bool: return paused and game.player == null and game.active_level == null and game.menu.page_name() == "title" and _same(game.attempts.state(), _expected_disk), "entire expected canonical startup session settles at actual Title", 12.0): return false
	return _expect(game.campaign_error.is_empty() and game.settings.storage_path() == test_root + "settings.json" and _disk_matches(_expected_disk), "fresh Title retains exact independently read entire disk session")


func _reopen_side(saved: Dictionary, label: String) -> bool:
	var before: Dictionary = _ids()
	var expected: Dictionary = game.attempts.state().duplicate(true)
	var disk: String = FileAccess.get_file_as_string(test_root + "campaign.json")
	var backup: String = FileAccess.get_file_as_string(test_root + "campaign.json.bak")
	if not _expect(_disk_matches(expected) and _same(expected.story, protected_story), "whole pre-Continue disk includes exact complete protected Story"): return false
	var refs: Array[WeakRef] = _refs(game)
	operation = "normal canonical donor Shell disposal: " + label
	game.active_level.exit_level(); game.free(); game = null
	await process_frame
	if not _expect(_freed(refs), "normal prior Shell frees all native descendants before independent disk recipient"): return false
	_expected_disk = expected.duplicate(true)
	if not await _new_shell(): return false
	operation = "canonical Title public active-side Continue: " + label
	game.menu.resume_requested.emit()
	if not await _await_operation(func() -> bool: return _live(Layout.LEVEL_ID) and paused and game.menu.page_name() == "resume" and game.attempts.active_kind() == "optional", "actual fresh canonical active-side Continue installs O3", 12.0): return false
	var captured: Dictionary = game.capture_campaign_snapshot()
	var callbacks: Array[Dictionary] = _recipient_callbacks()
	if not _expect(_same(captured, saved) and _all_new(before, _ids()) and callbacks.is_empty() and _bindings() and _same(game.attempts.state(), expected) and _same(game.attempts.state().story, protected_story) and FileAccess.get_file_as_string(test_root + "campaign.json") == disk and FileAccess.get_file_as_string(test_root + "campaign.json.bak") == backup and _disk_matches(expected), "post-disk fresh distinct native recipient retains exact entire optional session and whole protected Story; zero installed callbacks and unchanged disk/backup"): return false
	_short_receipts.append({"label": "actual canonical fresh active-side disk Continue", "exact_snapshot": Exact.stringify(captured), "exact_attempts": Exact.stringify(game.attempts.state()), "exact_whole_protected_story": Exact.stringify(game.attempts.state().story), "saved_envelope_json": disk, "before_identities": before, "new_identities": _ids(), "installed_recipient_callbacks": callbacks})
	return await _quiet_selected("fresh canonical disk Continue recipient")


func _quiet_selected(label: String) -> bool:
	var unit: Dictionary = game.capture_campaign_snapshot()
	var session: Dictionary = game.attempts.state().duplicate(true)
	var before: Dictionary = _core_ids()
	var disk: String = FileAccess.get_file_as_string(test_root + "campaign.json")
	var backup: String = FileAccess.get_file_as_string(test_root + "campaign.json.bak")
	await process_frame; await process_frame
	if not _operation_healthy(): return false
	var callbacks: Array[Dictionary] = _recipient_callbacks()
	return _expect(paused and _same(game.capture_campaign_snapshot(), unit) and _same(game.attempts.state(), session) and _same(game.attempts.state().story, protected_story) and _core_ids() == before and callbacks.is_empty() and FileAccess.get_file_as_string(test_root + "campaign.json") == disk and FileAccess.get_file_as_string(test_root + "campaign.json.bak") == backup and _disk_matches(session), "two paused frames preserve complete native packet/session/Story/disk and selected-recipient callback silence: " + label)


func _disk_matches(expected: Dictionary) -> bool:
	var store: CinderSaveStore = Store.new(test_root + "campaign.json")
	var actual: Dictionary = store.read_payload()
	return store.last_error.is_empty() and _same(actual, expected)


func _world_container() -> Node:
	return game.world.get_parent().get_parent()


func _core_ids() -> Dictionary:
	return {"world": str(game.world.get_instance_id()), "native_world": str(game.world.get_world_3d().get_instance_id()), "player": str(game.player.get_instance_id()), "level": str(game.active_level.get_instance_id())}


func _core_new(before: Dictionary) -> bool:
	var after: Dictionary = _core_ids()
	for key: String in before:
		if not after.has(key) or before[key] == after[key]: return false
	return not before.is_empty()


func _expect(ok: bool, label: String) -> bool:
	checks += 1
	var row: Dictionary = {"check": checks, "ok": ok, "label": label}
	if not ok:
		failures += 1
		row["diagnostic"] = _diagnostic()
		if _short_first_failure.is_empty(): _short_first_failure = row.duplicate(true)
		if first_failure.is_empty(): first_failure = {"label": label, "diagnostic": row.diagnostic.duplicate(true)}
		push_error(label)
	_short_rows.append(row)
	return ok


func _short_sources() -> Dictionary:
	var result: Dictionary = {}
	for path: String in SHORT_SOURCE_PATHS: result[path] = FileAccess.get_sha256(path)
	result[get_script().resource_path] = FileAccess.get_sha256(get_script().resource_path)
	return result


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true; operation = "normal canonical short registration cleanup"
	var refs: Array[WeakRef] = []
	if is_instance_valid(preview):
		var level: CinderLevel = preview.get("active_level") as CinderLevel
		if level != null: level.exit_level()
		refs.append_array(_refs(preview)); preview.free(); preview = null
	if is_instance_valid(game):
		if is_instance_valid(game.active_level): game.active_level.exit_level()
		refs.append_array(_refs(game)); game.free(); game = null
	await create_timer(0.5, true).timeout
	await process_frame
	_expect((refs.is_empty() or _freed(refs)) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("environment_attack_targets").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal public level exit and Shell cleanup free descendants and all source/cue groups")
	_expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH) == registry_bytes, "canonical registry remains byte exact")
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		var path: String = test_root + name
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	paused = false
	_write_short_report()
	print("A1-O3 SHORT canonical registration: %d checks/%d failures; complete=%s; canonical entry/Save/disk Continue/entrance Retry/Leave only" % [checks, failures, str(_short_complete)])
	quit(0 if failures == 0 and _short_complete else 1)


func _write_short_report() -> void:
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(report_path.get_base_dir())) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(report_path.get_base_dir())) != OK:
		_expect(false, "short registration report directory opens"); return
	var payload: Dictionary = {"schema_version": 1, "kind": "a1-o3-short-canonical-registration", "accepted_content": ACCEPTED_CONTENT, "checks": checks, "failures": failures, "complete": _short_complete, "success": failures == 0 and _short_complete, "first_failure": _short_first_failure, "rows": _short_rows, "initial_closed_packet_disk": _short_initial, "source_observations_before": _short_before, "source_observations_after": _short_sources(), "exact_receipt_strings": [], "operation_wait_overruns": operation_wait_overruns, "scope": "Actual canonical row/parent/unlock/main-route/stamp-policy metadata; real pristine L4 Story donor and disclosed TEST prefix4; whole-session initial disk and post-disk whole Story; public Optional/Pause Save/fresh active-side Continue/RetryButton/early Leave; fresh native IDs, two paused frames, selected-recipient callback silence, unchanged disk/backup and normal cleanup. Standard starter. No live-exercise/final/terminal/completion/stamp/Replay/GUI/portrait/earned-route/performance/mobile credit.", "completion_replay": {"executed_here": false, "owner_evidence_reuse_required": true, "completed_session_export_required": false}}
	for receipt: Dictionary in _short_receipts:
		var wire: String = Exact.stringify(receipt)
		if wire.is_empty(): _expect(false, "complete canonical disk Continue receipt remains exact JSON"); return
		payload.exact_receipt_strings.append(wire)
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null: _expect(false, "short registration report file opens"); return
	# Primitive report metadata + opaque Exact strings, never lossy native state.
	file.store_string(JSON.stringify(payload, "\t") + "\n"); file.close()
	print("CINDER_A1_O3_SHORT_REGISTRATION_REPORT path=%s sha256=%s" % [report_path, FileAccess.get_sha256(report_path)])


func _retry_entrance() -> bool:
	var checkpoint: Dictionary = game.attempts.state().side_attempt.checkpoint.duplicate(true)
	var expected: Dictionary = game.attempts.state().duplicate(true)
	var button := game.menu.find_child("RetryButton", true, false) as Button
	if not _expect(_same(checkpoint, entrance) and _pristine(checkpoint) and button != null and button.is_visible_in_tree() and not button.disabled and game.menu.page_name() == "pause", "actual production pause RetryButton exposes the original entrance checkpoint"): return false
	var before: Dictionary = _ids()
	var refs: Array[WeakRef] = _refs(_world_container())
	operation = "actual canonical entrance RetryButton public pressed signal"
	button.pressed.emit()
	if not await _observe_registration("Retry genuine whole entrance", 1, func() -> bool: return _live(Layout.LEVEL_ID) and paused and game.menu.page_name() == "resume" and _ids() != before): return false
	return _expect(_same(game.capture_campaign_snapshot(), checkpoint) and _pristine(game.capture_campaign_snapshot()) and _all_new(before, _ids()) and _freed(refs) and _recipient_callbacks().is_empty() and _bindings() and _same(game.attempts.state(), expected) and _same(game.attempts.state().story, protected_story) and _disk_matches(expected), "actual canonical entrance Retry quietly restores the exact whole earlier checkpoint/session/Story into a distinct recipient and frees old native world")
