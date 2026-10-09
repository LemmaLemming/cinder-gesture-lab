extends "res://tests/acts/act2/a2_l4_live_level_smoke.gd"
## Scoped actual courtyard continuation from the immutable first-run format2.
## No _seed, player/gear/progress/clock rewrite, private native clock step,
## manufactured proof, primary-gate exception or original artifact mutation.
## Saved preceding TEST ONLY registry/prefix metadata remains fixture metadata.
## Records stage5 as a real current unit; its earlier checkpoint stays stage4.
## --resume-stage5 resumes the pinned genuinely earned unit via public Store
## and GUI Continue, skipping only its already defeated first courtyard.
## --resume-stalled resumes the later pinned genuine6HP Tender boundary.
## No final mix/contact, completion, exit, Boss, full route or matrix claim.

const PriorityJson: Script = preload("res://scripts/campaign/exact_json.gd")
const PRIORITY_TEST_ROOT: String = "user://test-a2-l4-priority-repro/"
const ORIGINAL_ROOT: String = "res://docs/acts/act2/evidence/A2-L4/live-heavy-first/"
const ORIGINAL_CAMPAIGN_SHA: String = "e3a33fa9415acec8d67965bfa1604ef22851b73754cde1bdc25c2bf8a3867611"
const ORIGINAL_SOURCE_SHA: String = "df99b684fd2aa85f790b8f4675cfb9f47ccaa1238010f06b99932af3854dd321"
const STAGE5_ROOT: String = "res://docs/acts/act2/evidence/A2-L4/priority-repro-first/"
const STAGE5_SOURCE_SHA: String = "a76927a963d537f3cd36b017bf40a63b4dfbe294ff3c48495c3b4875210ca4c1"
const STALLED_ROOT: String = "res://docs/acts/act2/evidence/A2-L4/priority-stage5-first/"
const STALLED_SOURCE_SHA: String = "d118ad080a4dd66c707a24abeeb327a64739a9d83586caa47752c68fe5e194bf"
const STALLED_FILE_HASHES: Dictionary = {
	"incomplete-actual.aggregate.exact.json": "16932fc65b1d847e6f6a7ac3edcc26985590d3abcc82b09c68067943e8e60b54",
	"incomplete-actual.attempts.exact.json": "2d488e7499a4ce4ad6862a57adf4ccd9012a59b0626186e72e1500d38c677342",
	"incomplete-actual.diagnostic.exact.json": "9b950f4357a4e10ad60183e4d09cc2a57f8f1218e8f5d68e02a09bebe87de5f5",
}
const STAGE5_FILE_HASHES: Dictionary = {
	"actual-stage5.aggregate.exact.json": "efb6bdfeaf1063c6440a6c91663806fb917d978f1feeaa0fe391884a88092561",
	"actual-stage5.attempts.exact.json": "3cd126f7e4564299206ad26f12c7c1b2115c6a20b2bd47222edb203103c6bf6a",
}
const ORIGINAL_STORAGE_HASHES: Dictionary = {
	"campaign.json": ORIGINAL_CAMPAIGN_SHA,
	"campaign.json.bak": "f01dbbe42839dde5ded7a7c9801b2ef08db3cb4419fa8a6293264c661612819b",
	"preferences.json": "f26399c5e3edfba4b7c320c8c276017630698a1c8e1b58ba319db2e6f1a4b305",
}
const TEST_SOURCE_EXCLUSIONS: Dictionary = {
	"tests/acts/act2/a2_l4_live_level_smoke.gd": "Current TEST ONLY helper adds strict equality, full native blocker witnesses, bounded HP-progress diagnostics and quiet native-source inward positioning and capsule-padded complete-path spatial qualification of later temporal candidates. Original hash remains provenance; production/resources/other sources must match exactly.",
}
const SHARED32_COMPATIBILITY_PATH: String = "res://docs/acts/act2/evidence/shared32-adoption/source-compatibility.json"
const SHARED32_COMPATIBILITY_SHA: String = "201841ec607782f7dbcb35382895c5de31ca864734c1cc8a48f5f4430bd16066"
var _pr_shared_compatibility: Dictionary = {}
var _pr_payload: Dictionary = {}
var _pr_original: Dictionary = {}
var _pr_checkpoint: Dictionary = {}
var _pr_resume_stage5: bool = false
var _pr_resume_stalled: bool = false
var _pr_stage5_checked_sources: int = 0
var _pr_source: Dictionary = {}
var _pr_exclusions: Dictionary = {}
var _pr_checked_sources: int = 0
var _pr_defeats: Array[String] = []
var _pr_checkpoints: Array[String] = []
var _pr_completions: Array[String] = []
var _pr_exits: Array[String] = []
var _pr_restore_events: Array[String] = []
var _pr_watch_restore: bool = false
var _pr_auto_resume: bool = false
var _pr_capture_root: String = ""

func _diagnostic_public_value(value: Variant) -> Dictionary:
	# Diagnostic classification only; original aggregate/model and strict
	# native equality retain their canonical codecs and exact rejection rules.
	var issues: Array[Dictionary] = []
	_pr_diagnostic_anomalies(value, "diagnostic", issues)
	if not issues.is_empty(): print("L4 TEST diagnostic preflight native value classifications: ", JSON.stringify(issues, "", true, true))
	var converted: Variant = _pr_json_value(value)
	var problem: String = _pr_closed_problem(converted, "diagnostic")
	if not problem.is_empty(): print("L4 TEST diagnostic preflight rejected path/reason: ", problem)
	return {"accepted": problem.is_empty(), "value": converted, "error": problem}

func _progress_diagnostic_root() -> String:
	return PRIORITY_TEST_ROOT

func _pr_saved_courtyard_selected() -> bool:
	return _pr_resume_stage5 or _pr_resume_stalled

func _pr_selected_source_root() -> String:
	return STALLED_ROOT if _pr_resume_stalled else (STAGE5_ROOT if _pr_resume_stage5 else ORIGINAL_ROOT)

func _run() -> void:
	_pr_resume_stage5 = OS.get_cmdline_user_args().has("--resume-stage5")
	_pr_resume_stalled = OS.get_cmdline_user_args().has("--resume-stalled")
	if not _expect(not (_pr_resume_stage5 and _pr_resume_stalled), "select one genuine saved courtyard boundary"): quit(1); return
	if not _read_options() or not _expect(_loadout_name == "heavy" and _profile_id == "standard" and not _capture_live, "reproduction selects the genuine original Heavy/Standard unit without art/full-route selectors"):
		quit(1); return
	root.size = Vector2i(540, 1170)
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	if not _pr_read_source(): quit(1); return
	_pr_cleanup_save_paths()
	_pr_capture_root = PRIORITY_TEST_ROOT + "captures/%s/" % Time.get_ticks_usec()
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_pr_capture_root)) == OK, "create isolated scoped diagnostic directory"):
		quit(1); return
	_native_probe = NativeTickProbe.new()
	root.add_child(_native_probe)
	node_added.connect(_pr_observe_added)
	print("L4 courtyard reproduction: genuine pinned %s unit, original resources including naturally earned ammo; Heavy/Standard, actual %s inputs, protected stage4 checkpoint; original source=%s isolated output=%s" % ["earned stalled6HP Tender stage5" if _pr_resume_stalled else ("earned stage5" if _pr_resume_stage5 else "generation3 flood-margin-clear/stage4"), "Tender-first second courtyard" if _pr_saved_courtyard_selected() else "Scout-first then Tender-first courtyards", _pr_selected_source_root(), ProjectSettings.globalize_path(_pr_capture_root)])
	var failures_before: int = _failures
	var complete: bool = await _run_route()
	if _pr_resume_stalled: _expect(_replacement_spatially_clear_checks > 0 and not _replacement_witnesses.is_empty(), "genuine stalled-boundary native run observed a later temporal candidate spatially clear of the complete original capsule-padded response path")
	if not complete and not _hp_watch_timeout:
		if _failures == failures_before: _expect(false, "scoped actual courtyard reproduction stopped: " + _diagnostic())
		if is_instance_valid(_game) and is_instance_valid(_game.active_level): await _pr_capture("incomplete-actual", false)
	await process_frame
	_pr_watch_restore = false
	if is_instance_valid(_game): _release_fixture_shell(_game)
	_game = null
	if is_instance_valid(_native_probe): _native_probe.free()
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical, "isolated registry injection preserves canonical bytes")
	_pr_verify_original_storage()
	_expect(FileAccess.get_sha256(ORIGINAL_ROOT + "source.json") == ORIGINAL_SOURCE_SHA, "original source inventory bytes remain immutable")
	if _pr_saved_courtyard_selected(): _pr_verify_saved_artifacts()
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "actual scoped Shell closure releases all owned targets/cues/grace indicators")
	print("L4 courtyard reproduction: %d checks, %d failures; capture_root=%s; completed_scoped_courtyards=%s; HP_progress_timeout=%s; no full-level/transition acceptance" % [_checks, _failures, ProjectSettings.globalize_path(_pr_capture_root), complete, _hp_watch_timeout])
	quit(2 if _hp_watch_timeout else (0 if _failures == 0 and complete else 1))

func _pr_read_shared_compatibility() -> bool:
	if not _expect(FileAccess.get_sha256(SHARED32_COMPATIBILITY_PATH) == SHARED32_COMPATIBILITY_SHA, "exact independently reviewed Shared32 compatibility receipt is pinned"): return false
	var receipt: Variant = JSON.parse_string(FileAccess.get_file_as_string(SHARED32_COMPATIBILITY_PATH))
	if not _expect(receipt is Dictionary and receipt.get("publication") == "9caeddf0540cb9c37479a470ad0fdf86425594cc" and receipt.get("original_publication") == "64f34c8776aa81d7eb8f88b71b8b8d64192f35f0" and receipt.get("merge_commit") == "645c360eaa0933621aed18f384cea5b9aa8a32d5" and receipt.get("sources") is Dictionary and receipt.sources.size() == 6, "only exact published Shared32 preservation and six reviewed shared paths authorize compatibility"): return false
	for path: String in receipt.sources:
		var entry: Dictionary = receipt.sources[path]
		if not _expect(entry.get("original_sha256") is String and entry.original_sha256.length() == 64 and entry.get("current_sha256") is String and entry.current_sha256.length() == 64 and entry.get("reason") is String and not entry.reason.is_empty() and FileAccess.get_sha256("res://" + path) == entry.current_sha256, "every reviewed shared dependency matches exact published bytes: " + path): return false
	_pr_shared_compatibility = receipt.sources.duplicate(true)
	return true

func _pr_shared_source_allows(path: String, recorded: String, current: String) -> bool:
	var entry: Dictionary = _pr_shared_compatibility[path]
	if not _expect(recorded == entry.original_sha256 and current == entry.current_sha256, "original earned-source and actual published Shared32 bytes both match reviewed compatibility: " + path): return false
	_pr_exclusions["published-shared32:" + path] = {"original_sha256": recorded, "current_sha256": current, "publication": "9caeddf0540cb9c37479a470ad0fdf86425594cc", "receipt_sha256": SHARED32_COMPATIBILITY_SHA, "reason": entry.reason}
	return true

func _pr_read_source() -> bool:
	if not _pr_read_shared_compatibility(): return false
	if not _pr_verify_original_storage() or not _expect(FileAccess.get_sha256(ORIGINAL_ROOT + "source.json") == ORIGINAL_SOURCE_SHA, "exact original source inventory is preserved"): return false
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ORIGINAL_ROOT + "source.json"))
	if not _expect(raw is Dictionary and raw.get("files") is Dictionary and raw.files.size() == 279, "original source inventory contains its complete recorded279-source set"): return false
	_pr_source = raw
	for path: String in _pr_source.files:
		var recorded: Variant = _pr_source.files[path]
		if not _expect(not path.begins_with("/") and not path.split("/").has("..") and recorded is String and recorded.length() == 64, "original source entry is a bounded relative hash: " + path): return false
		var current: String = FileAccess.get_sha256("res://" + path)
		if TEST_SOURCE_EXCLUSIONS.has(path):
			_pr_exclusions[path] = {"original_sha256": recorded, "current_sha256": current, "reason": TEST_SOURCE_EXCLUSIONS[path]}
			continue
		if _pr_shared_compatibility.has(path):
			if not _pr_shared_source_allows(path, recorded, current): return false
			continue
		if not _expect(current == recorded, "actual production/resource/source bytes match the genuine first run: " + path): return false
		_pr_checked_sources += 1
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(ORIGINAL_ROOT + "earned-storage/campaign.json"))
	if not _expect(envelope is Dictionary and envelope.get("format_version") == 2 and envelope.get("generation") == 3 and envelope.get("payload_json") is String and envelope.get("sha256") == envelope.payload_json.sha256_text(), "original primary is genuine valid format2 generation3"): return false
	var decoded: Dictionary = PriorityJson.parse(envelope.payload_json)
	if not _expect(decoded.get("accepted", false) and decoded.get("value") is Dictionary, "published ExactJson decodes original complete Attempts payload"): return false
	_pr_payload = decoded.value
	if not _expect(_pr_payload.get("story") is Dictionary and _pr_payload.story.get("snapshot") is Dictionary and _pr_payload.story.get("checkpoint") is Dictionary, "original contains both current story and protected checkpoint"): return false
	_pr_original = _pr_payload.story.snapshot
	if not _expect(_pr_original.level_id == "A2-L4" and _pr_original.scene_path == LONDON_SCENE and _pr_original.paused and not _pr_original.player.resources.dead and _pr_original.equipment_ids == _loadout and _pr_original.level.local.profile_id == "standard" and _pr_original.level.local.sequence.stage_index == 4 and _pr_original.level.local.sequence.defeated_ids == ["garden_handler", "flood_scout", "flood_tender"] and _pr_original.level.local.sequence.crossed_contacts == ["road_entry", "villa_entry"] and _pr_original.level.progress.checkpoint_id == "flood-margin-clear" and not _pr_original.level.progress.completed and _pr_payload.completed_main == LONDON_PREFIX and PriorityJson.stringify(_pr_payload.story.checkpoint) == PriorityJson.stringify(_pr_original), "actual saved3-kill/two-contact living stage4 unit and earlier TEST prefix remain untouched"): return false
	_pr_checkpoint = _pr_payload.story.checkpoint.duplicate(true)
	return _pr_read_saved_courtyard() if _pr_saved_courtyard_selected() else true

func _pr_verify_original_storage() -> bool:
	for name: String in ORIGINAL_STORAGE_HASHES:
		if not _expect(FileAccess.get_sha256(ORIGINAL_ROOT + "earned-storage/" + name) == ORIGINAL_STORAGE_HASHES[name], "original earned storage remains byte-identical: " + name): return false
	return true

func _pr_verify_saved_artifacts() -> bool:
	var source: String = _pr_selected_source_root()
	var source_sha: String = STALLED_SOURCE_SHA if _pr_resume_stalled else STAGE5_SOURCE_SHA
	var directory: String = "earned-stalled/" if _pr_resume_stalled else "earned-stage5/"
	var hashes: Dictionary = STALLED_FILE_HASHES if _pr_resume_stalled else STAGE5_FILE_HASHES
	if not _expect(FileAccess.get_sha256(source + "source.json") == source_sha, "genuine saved-courtyard source inventory stays byte-identical"): return false
	for name: String in hashes:
		if not _expect(FileAccess.get_sha256(source + directory + name) == hashes[name], "original actual earned-courtyard exact bytes remain pinned: " + name): return false
	return true

func _pr_read_saved_courtyard() -> bool:
	if not _pr_verify_saved_artifacts(): return false
	var source: String = _pr_selected_source_root()
	var directory: String = "earned-stalled/" if _pr_resume_stalled else "earned-stage5/"
	var stem: String = "incomplete-actual" if _pr_resume_stalled else "actual-stage5"
	var inventory: Variant = JSON.parse_string(FileAccess.get_file_as_string(source + "source.json"))
	if not _expect(inventory is Dictionary and inventory.get("files") is Dictionary and inventory.files.size() == 280, "earned-courtyard unit has its complete frozen280-source inventory"): return false
	for path: String in inventory.files:
		var recorded: Variant = inventory.files[path]
		if not _expect(not path.begins_with("/") and not path.split("/").has("..") and recorded is String and recorded.length() == 64 and FileAccess.get_sha256(source + "source/" + path) == recorded, "earned-courtyard literal source copy matches its pinned original: " + path): return false
		var current: String = FileAccess.get_sha256("res://" + path)
		if path in ["tests/acts/act2/a2_l4_priority_repro.gd", "tests/acts/act2/a2_l4_live_level_smoke.gd"]:
			_pr_exclusions["saved-courtyard:" + path] = {"original_sha256": recorded, "current_sha256": current, "reason": "Only these two TEST files add finite diagnostic transport, genuine saved-courtyard options, quiet native-source inward positioning and TEST selector spatial qualification using original native paths. Original frozen source remains preserved. No production/input timing/Scheduler proof change."}
			continue
		if _pr_shared_compatibility.has(path):
			if not _pr_shared_source_allows(path, recorded, current): return false
			continue
		if not _expect(current == recorded, "all non-TEST runtime/resources/frozen helper bytes match actual earned-courtyard source: " + path): return false
		_pr_stage5_checked_sources += 1
	var unit: Dictionary = PriorityJson.parse(FileAccess.get_file_as_string(source + directory + stem + ".aggregate.exact.json"))
	var model: Dictionary = PriorityJson.parse(FileAccess.get_file_as_string(source + directory + stem + ".attempts.exact.json"))
	if not _expect(unit.get("accepted", false) and unit.get("value") is Dictionary and model.get("accepted", false) and model.get("value") is Dictionary, "public ExactJson decodes genuine full earned-courtyard aggregate and Attempts"): return false
	var saved: Dictionary = unit.value
	var payload: Dictionary = model.value
	var prefix: Array[String] = ["garden_handler", "flood_scout", "flood_tender", "villa_scout", "villa_ray_handler"]
	if not _expect(saved.level_id == "A2-L4" and saved.scene_path == LONDON_SCENE and saved.paused and not saved.player.resources.dead and saved.equipment_ids == _loadout and saved.level.local.profile_id == "standard" and saved.level.local.sequence.stage_index == 5 and saved.level.local.sequence.defeated_ids == prefix and saved.level.local.sequence.active_ids == ["villa_tender", "villa_smoke_handler"] and saved.level.local.sequence.crossed_contacts == ["road_entry", "villa_entry"] and saved.level.progress.checkpoint_id == "flood-margin-clear" and not saved.level.progress.completed and saved.level.progress.contact_exit_id.is_empty() and payload.completed_main == LONDON_PREFIX and PriorityJson.stringify(payload.story.snapshot) == PriorityJson.stringify(saved) and PriorityJson.stringify(payload.story.checkpoint) == PriorityJson.stringify(_pr_checkpoint), "genuinely earned five-kill courtyard current unit retains exact prior stage4 checkpoint, resources and prefix"): return false
	if _pr_resume_stalled:
		if not _expect(float(saved.level.local.targets.villa_tender.hp) == 6.0 and float(saved.level.local.targets.villa_smoke_handler.hp) == 30.0 and saved.level.local.scheduler.reservations.is_empty(), "genuine stalled boundary retains its earned6HP Tender,30HP Handler and no running reservation"): return false
	_pr_payload = payload
	_pr_original = saved
	return true

func _run_route() -> bool:
	var raw: Dictionary = JSON.parse_string(_canonical)
	for info: Dictionary in raw.levels:
		if info.id in ["A2-L4", "A2-L5"]:
			info.scene_path = LONDON_SCENE if info.id == "A2-L4" else LONDON_DESTINATION
			info.readiness = "accepted"; info.accepted_commit = "b".repeat(40); info.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A2-L5").is_empty(), "only TEST registry/destination metadata is injected"): return false
	for name: String in ORIGINAL_STORAGE_HASHES:
		if _pr_saved_courtyard_selected() and name != "preferences.json": continue
		var copied: Error = DirAccess.copy_absolute(ProjectSettings.globalize_path(ORIGINAL_ROOT + "earned-storage/" + name), ProjectSettings.globalize_path(PRIORITY_TEST_ROOT + name))
		if not _expect(copied == OK and FileAccess.get_sha256(PRIORITY_TEST_ROOT + name) == ORIGINAL_STORAGE_HASHES[name], "copy untouched real original storage into isolated prefix: " + name): return false
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var store: CinderSaveStore = Store.new(PRIORITY_TEST_ROOT + "campaign.json")
	store.payload_validator = model.saved_payload_error
	if _pr_saved_courtyard_selected():
		if not _expect(model.state_error(_pr_payload).is_empty() and store.write_payload(_pr_payload), "public SaveStore writes complete genuine earned-courtyard model without editing fields: " + store.last_error): return false
	var loaded: Dictionary = store.read_payload()
	if not _expect(store.last_error.is_empty() and not store.loaded_backup and store.generation == (1 if _pr_saved_courtyard_selected() else 3) and model.state_error(loaded).is_empty() and PriorityJson.stringify(loaded) == PriorityJson.stringify(_pr_payload), "public SaveStore loads exact selected original full model with no live seed or field rewrite: " + store.last_error): return false
	_game = Shell.new() as CinderCampaignShell
	if not _expect(_game.configure_runtime(raw, PRIORITY_TEST_ROOT + "campaign.json", PRIORITY_TEST_ROOT + "settings.json", PRIORITY_TEST_ROOT + "preferences.json"), "actual Shell uses new isolated real-storage prefix"): return false
	_pr_watch_restore = true
	root.add_child(_game)
	await _pr_settle()
	if not _expect(paused and _game.campaign_error.is_empty() and _game.menu.page_name() == "title", "real saved story loads at GUI Title"): return false
	if not await _pr_click("ContinueStoryButton"): return false
	_pr_watch_restore = false
	var installed: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(_live() and paused and _game.menu.page_name() == "resume" and PriorityJson.stringify(installed) == PriorityJson.stringify(_pr_original) and PriorityJson.stringify(_game.attempts.state()) == PriorityJson.stringify(_pr_payload) and _pr_restore_events.is_empty(), "fresh GUI Continue quietly restores exact original Player/level/shell and original full model; menu consumes no world action: " + str(_pr_restore_events)): return false
	if not _expect(_game.player.snapshot_error(installed.player).is_empty() and _game.active_level.snapshot_error_with_player(installed.level, installed.player).is_empty() and Codec.same_values(_game.player.stats, _expected_stats), "fresh actual aggregate passes public saved-player preflight with original canonical gear/stats"): return false
	_pr_bind_live()
	if not await _pr_click("ResumeButton"): return false
	_pr_auto_resume = true
	if not _pr_saved_courtyard_selected():
		if not await _clear(["villa_scout"]) or not await _broadside_blocker("VillaLowWall") or not await _clear(["villa_ray_handler"]): return false
		if not _expect(_pr_defeats == ["villa_scout", "villa_ray_handler"] and _pr_checkpoints.is_empty() and _pr_completions.is_empty() and _pr_exits.is_empty() and _state().beat == "villa_tender_priority", "real Scout-first courtyard/broad full-strip side bypass earns stage5 without another checkpoint/wave"): return false
		if not await _pr_capture("actual-stage5", true): return false
		if not await _pr_click("ResumeButton"): return false
		_pr_auto_resume = true
	else:
		if not _expect(_state().beat == "villa_tender_priority" and _pr_defeats.is_empty(), "genuine stage5 GUI continuation skips only its already earned Scout/Handler defeats"): return false
	if not await _clear(["villa_tender"]) or not await _finish_bank_tail("villa_bank") or not await _clear(["villa_smoke_handler"]): return false
	var expected: Array[String] = _pr_expected_defeats()
	if not _expect(_pr_defeats == expected and _state().beat == "putney_entry" and _pr_checkpoints.is_empty() and _pr_completions.is_empty() and _pr_exits.is_empty() and _tail_pending.is_empty() and _tail_completed.has("villa_bank"), "actual Tender-first/native finite tail/remaining Handler earn only the remaining courtyard arrangement"): return false
	if not await _pr_capture("actual-courtyards-finished", true): return false
	return _failures == 0

func _pr_expected_defeats() -> Array[String]:
	var expected: Array[String] = ["villa_scout", "villa_ray_handler", "villa_tender", "villa_smoke_handler"]
	if _pr_saved_courtyard_selected():
		expected.assign(["villa_tender", "villa_smoke_handler"])
	return expected

func _pr_bind_live() -> void:
	_actors = _game.active_level.get("_actors").duplicate()
	_banks = _game.active_level.get("_clouds").duplicate()
	for actor: Node in _actors.values():
		actor.connect("defeated", func(id: String) -> void: _pr_defeats.append(id); _observe_defeat(id))
	_game.player.world_action_executed.connect(func(record: Dictionary) -> void: _actions.append(record.duplicate(true)); _observe_blocker_path(record))
	_game.active_level.checkpoint_requested.connect(func(_id: String, checkpoint: String, _kind: String) -> void: _pr_checkpoints.append(checkpoint))
	_game.active_level.completion_requested.connect(func(_id: String, id: String) -> void: _pr_completions.append(id))
	_game.active_level.contact_exit_requested.connect(func(_id: String, id: String) -> void: _pr_exits.append(id))

func _pr_capture(label: String, require_valid: bool) -> bool:
	_pr_auto_resume = false
	_game.request_pause()
	await _pr_settle()
	var saved: Dictionary = _game.capture_campaign_snapshot()
	var problem: String = "Empty full aggregate" if saved.is_empty() else _game.active_level.snapshot_error_with_player(saved.level, saved.player)
	if require_valid and not _expect(paused and _game.campaign_error.is_empty() and not saved.is_empty() and problem.is_empty() and _game.player.snapshot_error(saved.player).is_empty(), "public full-tick pause captures genuine complete " + label + ": " + problem): return false
	if require_valid:
		_expect(not saved.level.progress.completed and saved.level.progress.contact_exit_id.is_empty() and saved.level.progress.checkpoint_id == "flood-margin-clear" and PriorityJson.stringify(_game.attempts.state().story.checkpoint) == PriorityJson.stringify(_pr_checkpoint), "current earned courtyard unit preserves its genuine earlier protected checkpoint and no full-clear/exit")
		if label == "actual-stage5": _expect(saved.level.local.sequence.stage_index == 5 and saved.level.local.sequence.defeated_ids.size() == 5, "actual five defeats produce stage5 current unit; checkpoint remains original stage4")
	var actors: Dictionary = {}
	for id: String in _actors:
		var actor: Node3D = _actors[id]
		var current: Dictionary = _state().exchanges.get(id, {})
		var proof: Dictionary = current.get("proof", {})
		if current.has("mechanism_id"): proof = _game.active_level.call("mechanism_proof", current.mechanism_id)
		actors[id] = {"hp": actor.get("hp"), "max_hp": actor.get("max_hp"), "position": actor.global_position, "actor_phase": actor.get("phase"), "current": current, "lease": _reservation(String(current.get("reservation_id", ""))), "accepted_proof": proof}
	var diagnostic: Dictionary = {"scope": "actual courtyard reproduction current state; no full-level acceptance", "label": label, "original_campaign_sha256": ORIGINAL_CAMPAIGN_SHA, "original_source_sha256": ORIGINAL_SOURCE_SHA, "source_checked_count": _pr_checked_sources, "resume_original_stage5": _pr_resume_stage5, "resume_original_stalled": _pr_resume_stalled, "saved_courtyard_source_sha256": STALLED_SOURCE_SHA if _pr_resume_stalled else (STAGE5_SOURCE_SHA if _pr_resume_stage5 else ""), "stage5_source_checked_count": _pr_stage5_checked_sources, "test_only_exclusions": _pr_exclusions, "new_fixture": {"path": "tests/acts/act2/a2_l4_priority_repro.gd", "sha256": FileAccess.get_sha256("res://tests/acts/act2/a2_l4_priority_repro.gd"), "reason": "New test-only orchestration absent from original source inventory; no gameplay authority"}, "aggregate_validation_error": problem, "campaign_error": _game.campaign_error, "paused": paused, "actors": actors, "encounter_state": _state(), "actual_player_response": _game.player.get_threat_response_state(), "actual_completed_actions": _actions, "blocker_witnesses": _blocker_bypass_seen, "new_defeats": _pr_defeats, "new_checkpoints": _pr_checkpoints, "new_completions": _pr_completions, "new_exits": _pr_exits, "actual_camera_framing": _game.get_camera_framing_state(), "replacement_spatially_clear_checks": _replacement_spatially_clear_checks, "replacement_witnesses": _replacement_witnesses}
	var exact: String = PriorityJson.stringify(saved)
	var payload: String = PriorityJson.stringify(_game.attempts.state())
	var anomalies: Array[Dictionary] = []
	_pr_diagnostic_anomalies(diagnostic, "diagnostic", anomalies)
	if not anomalies.is_empty(): print("L4 TEST diagnostic preflight native value classifications: ", JSON.stringify(anomalies, "", true, true))
	var converted: Variant = _pr_json_value(diagnostic)
	var diagnostic_problem: String = _pr_closed_problem(converted, "diagnostic")
	if not diagnostic_problem.is_empty(): print("L4 TEST diagnostic preflight rejected path/reason: ", diagnostic_problem)
	var diagnostic_exact: String = PriorityJson.stringify(converted) if diagnostic_problem.is_empty() else ""
	if diagnostic_exact.is_empty() and diagnostic_problem.is_empty(): print("L4 TEST diagnostic preflight rejected ExactJson structural/byte budget at diagnostic; converted ordinary JSON bytes=", JSON.stringify(converted).to_utf8_buffer().size())
	if not _pr_write(label + ".aggregate.exact.json", exact) or not _pr_write(label + ".attempts.exact.json", payload) or not _pr_write(label + ".diagnostic.exact.json", diagnostic_exact): return false
	print("L4 actual scoped capture ", label, ": ", ProjectSettings.globalize_path(_pr_capture_root), " aggregateSHA=", exact.sha256_text(), " state=", JSON.stringify(_pr_json_value({"beat": _state().beat, "clock_s": _state().clock_s, "actors": actors, "admission_errors": _state().admission_errors})))
	return true

func _pr_json_value(value: Variant) -> Variant:
	if value is Vector3: return _pr_json_value([value.x, value.y, value.z])
	if value is Vector2: return _pr_json_value([value.x, value.y])
	if value is Rect2: return {"position": _pr_json_value(value.position), "size": _pr_json_value(value.size)}
	if value is Basis: return {"x": _pr_json_value(value.x), "y": _pr_json_value(value.y), "z": _pr_json_value(value.z)}
	if value is Transform3D: return {"origin": _pr_json_value(value.origin), "basis": _pr_json_value(value.basis)}
	if value is AABB: return {"position": _pr_json_value(value.position), "size": _pr_json_value(value.size)}
	if value is Array:
		var result: Array = []
		for child: Variant in value: result.append(_pr_json_value(child))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[str(key)] = _pr_json_value(value[key])
		return result
	if value is Object: return {"diagnostic_native_object": value.get_class() if is_instance_valid(value) else "retired"}
	if value is int and (value < -PriorityJson.MAX_INTEGER or value > PriorityJson.MAX_INTEGER): return {"diagnostic_native_integer_decimal": str(value)}
	if value is float and not is_finite(value): return {"diagnostic_nonfinite_float": "NAN" if is_nan(value) else ("+INF" if value > 0.0 else "-INF")}
	if typeof(value) in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING]: return value
	return {"diagnostic_native_type": type_string(typeof(value)), "text": str(value)}

func _pr_diagnostic_anomalies(value: Variant, path: String, issues: Array[Dictionary]) -> void:
	if value is int and (value < -PriorityJson.MAX_INTEGER or value > PriorityJson.MAX_INTEGER):
		issues.append({"path": path, "reason": "native integer exceeds exact JSON range", "decimal": str(value)})
	elif value is float and not is_finite(value):
		issues.append({"path": path, "reason": "nonfinite native diagnostic float", "classification": "NAN" if is_nan(value) else ("+INF" if value > 0.0 else "-INF")})
	elif value is Vector3:
		_pr_diagnostic_anomalies(value.x, path + ".x", issues)
		_pr_diagnostic_anomalies(value.y, path + ".y", issues)
		_pr_diagnostic_anomalies(value.z, path + ".z", issues)
	elif value is Vector2:
		_pr_diagnostic_anomalies(value.x, path + ".x", issues)
		_pr_diagnostic_anomalies(value.y, path + ".y", issues)
	elif value is Array:
		for index: int in range(value.size()): _pr_diagnostic_anomalies(value[index], path + "[%d]" % index, issues)
	elif value is Dictionary:
		for key: Variant in value: _pr_diagnostic_anomalies(value[key], path + "." + str(key), issues)

func _pr_closed_problem(value: Variant, path: String, depth: int = 0) -> String:
	if depth > PriorityJson.MAX_DEPTH: return path + ": exceeds exact JSON depth64"
	if value is int: return path + ": integer outside exact JSON range" if value < -PriorityJson.MAX_INTEGER or value > PriorityJson.MAX_INTEGER else ""
	if value is float: return path + ": nonfinite float" if not is_finite(value) else ""
	if value is Array:
		if value.size() > PriorityJson.MAX_ENTRIES: return path + ": exceeds exact JSON array entry bound"
		for index: int in range(value.size()):
			var problem: String = _pr_closed_problem(value[index], path + "[%d]" % index, depth + 1)
			if not problem.is_empty(): return problem
		return ""
	if value is Dictionary:
		if value.size() > PriorityJson.MAX_ENTRIES: return path + ": exceeds exact JSON dictionary entry bound"
		for key: Variant in value:
			if not key is String: return path + ": nonstring dictionary key"
			var problem: String = _pr_closed_problem(value[key], path + "." + key, depth + 1)
			if not problem.is_empty(): return problem
		return ""
	return "" if typeof(value) in [TYPE_NIL, TYPE_BOOL, TYPE_STRING] else path + ": unsupported closed type " + type_string(typeof(value))

func _pr_write(name: String, text: String) -> bool:
	if not _expect(not text.is_empty(), "scoped exact transport is serializable: " + name): return false
	var file: FileAccess = FileAccess.open(_pr_capture_root + name, FileAccess.WRITE)
	if not _expect(file != null, "open isolated scoped output: " + name): return false
	file.store_string(text); file.flush()
	var good: bool = file.get_error() == OK
	file.close()
	return _expect(good and FileAccess.get_file_as_string(_pr_capture_root + name) == text, "preserve actual exact snapshot/diagnostic bytes: " + name)

func _pr_observe_added(node: Node) -> void:
	if not _pr_watch_restore: return
	if node is CinderPlayer:
		node.connect("world_action_executed", func(_record: Dictionary) -> void: _pr_restore_events.append("player-action"))
		node.connect("died", func() -> void: _pr_restore_events.append("player-death"))
	elif node is CinderLevel:
		node.connect("checkpoint_requested", func(_id: String, _checkpoint: String, _kind: String) -> void: _pr_restore_events.append("checkpoint"))
		node.connect("completion_requested", func(_id: String, _completion: String) -> void: _pr_restore_events.append("completion"))
		node.connect("contact_exit_requested", func(_id: String, _exit: String) -> void: _pr_restore_events.append("exit"))
	elif node.has_signal("defeated"):
		node.connect("defeated", func(_id: String) -> void: _pr_restore_events.append("target-defeat"))

func _pr_click(name: String) -> bool:
	await _pr_settle()
	var button: Button = _game.menu.find_child(name, true, false) as Button
	if not _expect(is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled, "actual enabled GUI button exists: " + name): return false
	var pressed: Array[String] = []
	button.pressed.connect(func() -> void: pressed.append(name), CONNECT_ONE_SHOT)
	var at: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = at; motion.global_position = at
	root.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.position = at; press.global_position = at; press.pressed = true
	root.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false; root.push_input(release, true)
	await _pr_settle()
	return _expect(pressed == [name] and _game.campaign_error.is_empty(), "real GUI click emits once and settles without campaign error: " + name + " " + _game.campaign_error)

func _pr_settle() -> void:
	for frame: int in range(8): await process_frame

func _pr_cleanup_save_paths() -> void:
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PRIORITY_TEST_ROOT + name))

func _step() -> void:
	if _hp_watch_timeout: return
	await _native_probe.tick_finished
	if _pr_auto_resume and is_instance_valid(_game) and paused and _game.campaign_error.is_empty() and _game.menu.page_name() == "resume" and not _game.player.dead: _game.resume_campaign()
	_observe_runtime()
	await _observe_hp_watchdog()
	if _hp_watch_timeout: return
