extends "res://tests/acts/act2/a2_l4_courtyard_closure_smoke.gd"
## TEST ONLY late gun view: untouched earned stage 6/seven-defeat artifact,
## exact public fresh GUI Continue, two real Putney defeats and one gun photo.
## Original 1261/1 remains failed; prior tails/combat and 2271/0 stay archived at Shared 32.
## No full-route/matrix credit, private tail flags or live state/camera writes.
## Required root-authored compatibility manifest and CLI SHA fail closed.

const GUN_TEST_ROOT: String = "user://test-a2-l4-gun-view/"
const GUN_CAPTURE_ROOT: String = "res://captures/act2/a2-l4-gun-view/"
const GUN_COMPATIBILITY_PATH: String = "res://docs/acts/act2/evidence/A2-L4/gun-view-source-compatibility.json"
const GUN_PUBLICATION: String = "a445cda7556dcbb03a9af04ad9b9098486bd2163"
const GUN_SCHEDULER_SHA: String = "c824097911e6ea6dfabaee83a75d45da56a36027423b0428123260550867cdae"
const GUN_CLOSURE_ROOT: String = "res://docs/acts/act2/evidence/A2-L4/courtyard-closure-corrected/"
const GUN_CLOSURE_HASHES: Dictionary = {
	"source.json": "b91fb5e7645328092e5e6c08e8b9c9f9191314b3dffda470ef6132639fca9c25",
	"result.json": "e145b58706526d3ef2cb5286c07da8efb1b4dc73ce8a8f2fc330bbe59c375b09",
	"raw.log": "600dd0526cb09c7371d61bb1ba296161c6bf074136a3d215bc3f0139ffbc98f3",
	"wrapper.log": "600dd0526cb09c7371d61bb1ba296161c6bf074136a3d215bc3f0139ffbc98f3",
}
const GUN_RECEIPTS: Array[String] = [
	"docs/acts/act2/evidence/shared32-adoption/adoption.json",
	"docs/acts/act2/evidence/shared34-adoption/adoption.json",
	"docs/acts/act2/evidence/shared35-adoption/adoption.json",
]
const GUN_NEW_DEPENDENCIES: Array[String] = [
	"tests/acts/act2/a2_l4_courtyard_closure_smoke.gd",
	"tests/acts/act2/a2_l4_gun_view_smoke.gd",
]
const GUN_SUBJECT_PATH: NodePath = ^"BroadPutneyApproach/QuietAbandonedFieldGun"
const GUN_GOAL: Vector3 = Vector3(-3.0, 0.0, -44.0)
const GUN_GOAL_RADIUS: float = 0.20
const GUN_EXIT_FRONT_Z: float = -47.9

var _gun_compatibility_sha: String = ""
var _gun_compatibility: Dictionary = {}
var _gun_inventory: Dictionary = {}
var _gun_navigation: bool = false
var _gun_navigation_start: int = 0
var _gun_png_sha: String = ""
var _gun_metadata: Dictionary = {}
var _gun_earned_files: Dictionary = {}

func _read_options() -> bool:
	if not super._read_options(): return false
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--compatibility-sha256="): _gun_compatibility_sha = argument.trim_prefix("--compatibility-sha256=")
	_capture_live = false # This child owns one manual post-draw view, no parent capture loop.
	return _expect(_profile_id == "standard" and _loadout_name == "heavy" and DisplayServer.get_name() != "headless" and _gun_sha_valid(_gun_compatibility_sha), "gun view requires archived Heavy/Standard, graphics and an explicit compatibility manifest SHA")

func _run() -> void:
	if not _read_options(): quit(1); return
	root.size = Vector2i(540, 1170)
	_native_probe = NativeTickProbe.new()
	root.add_child(_native_probe)
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	print("L4 gun view scope: exact archived stage 6/seven defeats under Shared 35, two new real Putney defeats/quiet completion, one ordinary-follow gun view and actual road exit. Original 1261/1 remains failed; prior tails and 2271/0 are archived at Shared 32, no full-route/matrix credit.")
	var good: bool = _gun_read_original()
	if good: good = _cl_check_historical_closure()
	if good:
		node_added.connect(_cl_observe_added)
		_cl_cleanup_paths()
		good = await _gun_install_original()
		if good:
			for frame: int in range(8): await process_frame
			good = _expect(paused and _cl_events.is_empty() and _cl_retirements_exact() and PriorityJson.stringify(_game.capture_campaign_snapshot()) == PriorityJson.stringify(_cl_unit) and PriorityJson.stringify(_game.attempts.state()) == PriorityJson.stringify(_cl_model), "fresh paused original complete unit/model holds silently before any new action")
		if good:
			_cl_watch = false
			_pr_bind_live()
			good = await _gun_run_late_scope()
	_cl_watch = false
	if is_instance_valid(_game): await _cl_close_whole_shell()
	if is_instance_valid(_native_probe): _native_probe.free()
	_native_probe = null
	paused = false
	_cl_cleanup_paths()
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical, "gun TEST registry injection preserves canonical registry bytes")
	_cl_verify_artifact_hashes()
	_gun_guard_sources()
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "gun fixture retires whole native units and leaves no enemy/cue identities")
	print("L4 gun view smoke: %d checks, %d failures; late_scope_complete=%s; HP_progress_timeout=%s; one actual gun view only, no full-route/matrix or prior-tail replay credit" % [_checks, _failures, good, _hp_watch_timeout])
	quit(2 if _hp_watch_timeout else (0 if good and _failures == 0 else 1))

func _gun_sha_valid(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for index: int in range(value.length()):
		if not "0123456789abcdef".contains(value.substr(index, 1)): return false
	return true

func _gun_relative_path(value: Variant) -> bool:
	return value is String and not value.is_empty() and not value.begins_with("/") and not value.contains(":") and not value.contains("\\") and not value.split("/").has("..") and not value.split("/").has(".") and not value.split("/").has("")

func _gun_guard_sources() -> bool:
	if not _expect(FileAccess.get_sha256(GUN_COMPATIBILITY_PATH) == _gun_compatibility_sha, "required root-authored compatibility manifest remains exact"): return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GUN_COMPATIBILITY_PATH))
	var keys: Array[String] = ["schema_version", "level_id", "shared_publication", "producer_source_sha256", "producer_provenance_sha256", "quiet_restore_result_sha256", "changes", "current_dependencies", "shared_receipts", "gun_view_goal_xz"]
	if not _expect(parsed is Dictionary and Codec.keys_error(parsed, keys).is_empty(), "gun compatibility has an exact closed field envelope"): return false
	var manifest: Dictionary = parsed
	if not _expect(manifest.schema_version == 1 and manifest.level_id == "A2-L4" and manifest.shared_publication == GUN_PUBLICATION and manifest.producer_source_sha256 == CLEARED_SOURCE_SHA and manifest.producer_provenance_sha256 == CLEARED_PROVENANCE_SHA and manifest.quiet_restore_result_sha256 == GUN_CLOSURE_HASHES["result.json"] and manifest.gun_view_goal_xz == [-3.0, -44.0], "compatibility pins original producer/provenance, corrected quiet Shared 32 result and exact35 gun goal"): return false
	if not _expect(manifest.changes is Dictionary and manifest.current_dependencies is Dictionary and manifest.shared_receipts is Array and FileAccess.get_sha256("res://scripts/combat/threat_scheduler.gd") == GUN_SCHEDULER_SHA, "current ordinary Scheduler is exact published35; explicit source/receipt maps required"): return false
	if not _cl_verify_artifact_hashes(): return false
	var inventory: Variant = JSON.parse_string(FileAccess.get_file_as_string(CLEARED_ROOT + "source.json"))
	if not _expect(inventory is Dictionary and inventory.get("files") is Dictionary and inventory.files.size() == 281, "original producer inventory remains complete 281"): return false
	var mismatches: Array[String] = []
	for path: String in inventory.files:
		var recorded: Variant = inventory.files[path]
		if not _expect(_gun_relative_path(path) and _gun_sha_valid(recorded) and FileAccess.get_sha256(CLEARED_ROOT + "source/" + path) == recorded, "every original literal source copy remains pinned: " + path): return false
		var current: String = FileAccess.get_sha256("res://" + path)
		if current == recorded:
			if not _expect(not manifest.changes.has(path), "unchanged source cannot receive an exception: " + path): return false
			continue
		mismatches.append(path)
		var entry: Variant = manifest.changes.get(path)
		if not _expect(entry is Dictionary and Codec.keys_error(entry, ["original_sha256", "current_sha256", "reason"]).is_empty() and entry.original_sha256 == recorded and _gun_sha_valid(entry.current_sha256) and entry.current_sha256 == current and entry.reason is String and not entry.reason.strip_edges().is_empty(), "each exact source difference has pinned old/current hashes and specific root rationale: " + path): return false
	if not _expect(not mismatches.is_empty() and manifest.changes.size() == mismatches.size(), "compatibility differences equal the whole original 281 current mismatch set, with no unused exception"): return false
	for path: Variant in manifest.current_dependencies:
		var entry: Variant = manifest.current_dependencies[path]
		if not _expect(_gun_relative_path(path) and not inventory.files.has(path) and entry is Dictionary and Codec.keys_error(entry, ["sha256", "reason"]).is_empty() and _gun_sha_valid(entry.sha256) and FileAccess.get_sha256("res://" + path) == entry.sha256 and entry.reason is String and not entry.reason.strip_edges().is_empty(), "new current dependency is explicit and hash-pinned: " + str(path)): return false
	for path: String in GUN_NEW_DEPENDENCIES:
		if not _expect(manifest.current_dependencies.has(path), "current closure/gun helper is explicitly pinned: " + path): return false
	var receipt_paths: Array[String] = []
	for entry: Variant in manifest.shared_receipts:
		if not _expect(entry is Dictionary and Codec.keys_error(entry, ["path", "sha256"]).is_empty() and _gun_relative_path(entry.path) and _gun_sha_valid(entry.sha256) and not receipt_paths.has(entry.path) and FileAccess.get_sha256("res://" + entry.path) == entry.sha256, "each shared compatibility receipt is unique and exact"): return false
		receipt_paths.append(entry.path)
	for path: String in GUN_RECEIPTS:
		if not _expect(receipt_paths.has(path), "original32 through current34/35 adoption provenance is retained: " + path): return false
	_gun_compatibility = manifest.duplicate(true)
	_gun_inventory = inventory
	return true

func _gun_read_original() -> bool:
	if not _gun_guard_sources(): return false
	for name: String in GUN_CLOSURE_HASHES:
		if not _expect(FileAccess.get_sha256(GUN_CLOSURE_ROOT + name) == GUN_CLOSURE_HASHES[name], "original corrected 2271 quiet Shared 32 evidence remains pinned: " + name): return false
	var result: Variant = JSON.parse_string(FileAccess.get_file_as_string(GUN_CLOSURE_ROOT + "result.json"))
	if not _expect(result is Dictionary and result.exit_code == 0 and result.script_errors == 0 and result.native_errors == 0, "corrected archival quiet scope remains its original clean32 result"): return false
	var packets: Dictionary = {}
	for name: String in ["aggregate", "attempts", "diagnostic"]:
		var original: String = FileAccess.get_file_as_string(CLEARED_ROOT + "earned-cleared/incomplete-actual." + name + ".exact.json")
		var decoded: Dictionary = PriorityJson.parse(original)
		if not _expect(decoded.get("accepted", false) and decoded.get("value") is Dictionary and PriorityJson.stringify(decoded.value) == original, "exact public decoder preserves complete original scalar bits/types: " + name): return false
		packets[name] = decoded.value
	_cl_unit = packets.aggregate
	_cl_model = packets.attempts
	_cl_history = packets.diagnostic
	return true

func _gun_install_original() -> bool:
	var raw: Dictionary = JSON.parse_string(_canonical)
	for info: Dictionary in raw.levels:
		if info.id in ["A2-L4", "A2-L5"]:
			info.scene_path = LONDON_SCENE if info.id == "A2-L4" else LONDON_DESTINATION
			info.readiness = "accepted"; info.accepted_commit = "b".repeat(40); info.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(raw)
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var store: CinderSaveStore = Store.new(GUN_TEST_ROOT + "campaign.json")
	store.payload_validator = model.saved_payload_error
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A2-L5").is_empty() and model.state_error(_cl_model).is_empty() and store.write_payload(_cl_model), "public isolated Store writes unchanged complete original model: " + store.last_error): return false
	if not _expect(PriorityJson.stringify(store.read_payload()) == PriorityJson.stringify(_cl_model) and store.last_error.is_empty() and not store.loaded_backup, "public Store reads exact original whole model without backup"): return false
	_game = Shell.new() as CinderCampaignShell
	if not _expect(_game.configure_runtime(raw, GUN_TEST_ROOT + "campaign.json", GUN_TEST_ROOT + "settings.json", GUN_TEST_ROOT + "preferences.json"), "fresh Shell owns isolated gun-view save paths"): return false
	_cl_events.clear(); _cl_watch = true
	root.add_child(_game)
	await _pr_settle()
	if not _expect(paused and _game.menu.page_name() == "title" and _game.campaign_error.is_empty() and _cl_events.is_empty() and _cl_retirements_exact(), "real Title validates original snapshot/checkpoint with exact pristine retirements only"): return false
	if not await _pr_click("ContinueStoryButton"): return false
	var actual: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(paused and _game.menu.page_name() == "resume" and _game.campaign_error.is_empty() and _cl_events.is_empty() and _cl_retirements_exact() and PriorityJson.stringify(actual) == PriorityJson.stringify(_cl_unit) and PriorityJson.stringify(_game.attempts.state()) == PriorityJson.stringify(_cl_model), "real GUI Continue silently installs exact original whole unit/model/history"): return false
	return _expect(_game.player.snapshot_error(actual.player).is_empty() and _game.active_level.snapshot_error_with_player(actual.level, actual.player).is_empty() and _state().beat == "putney_entry", "actual receiver passes saved-player/native preflight at genuine stage 6")

func _gun_run_late_scope() -> bool:
	if not await _pr_click("ResumeButton"): return false
	if not _expect(_live() and not paused and PriorityJson.stringify(_game.attempts.state().story.checkpoint) == PriorityJson.stringify(_cl_model.story.checkpoint), "actual Resume preserves original protected stage4 checkpoint until genuine Putney contact"): return false
	if not await _contact("putney_entry", _pr_checkpoints): return false
	# The level signal is synchronous; the public Shell transaction commits
	# after this native tick. Observe Attempts only after normal GUI settlement.
	print("L4 gun checkpoint before public settlement: ", _game.attempts.state().story.checkpoint.level.local.sequence.stage_index)
	await _pr_settle()
	var checkpoint: Dictionary = _game.attempts.state().story.checkpoint
	print("L4 gun checkpoint after public settlement: ", checkpoint.level.local.sequence.stage_index, " id=", checkpoint.level.progress.checkpoint_id)
	if not _expect(_pr_checkpoints == ["villa-courtyards-clear"] and checkpoint.level.local.sequence.stage_index == 7 and checkpoint.level.progress.checkpoint_id == "villa-courtyards-clear" and checkpoint.level.local.sequence.defeated_ids == _cl_unit.level.local.sequence.defeated_ids, "one real Putney contact legitimately earns the next living checkpoint after public commit"): return false
	var targets: Array[String] = ["putney_scout", "putney_handler"]
	if not await _clear(targets): return false
	for frame: int in range(600):
		if not _live(): return false
		if _game.active_level.is_completed(): break
		await _step()
	if not _expect(_gun_quiet() and _pr_defeats.size() == 2 and _pr_defeats.count("putney_scout") == 1 and _pr_defeats.count("putney_handler") == 1 and _pr_completions == ["london-road-open"] and _pr_exits.is_empty(), "two actual new HP 30 defeats and quiet original banks earn one completion without replaying prior seven"): return false
	if not _expect(_tail_pending.is_empty() and _tail_completed.is_empty(), "restored complete bank tails remain archival, never fabricated as live observer completions"): return false
	if not _gun_original_banks_unchanged() or not await _gun_preserve_earned_late(): return false
	_gun_navigation = true
	_gun_navigation_start = _actions.size()
	var reached: bool = false
	for attempt: int in range(24):
		if not await _gun_ready(): return false
		if _gun_at_goal(): reached = true; break
		var goal: Vector3 = GUN_GOAL
		goal.y = _game.player.global_position.y
		if not await _navigate_dash(goal): return false
	if not reached and await _gun_ready(): reached = _gun_at_goal()
	if not _expect(reached, "at most 24 real supported swipes reach the strict gun viewpoint"): return false
	if not await _gun_settle_camera() or not await _gun_capture(): return false
	_gun_navigation = false
	if not _expect(_gun_original_banks_unchanged() and _pr_exits.is_empty(), "gun view keeps completed banks and unopened real road exit"): return false
	_game.request_pause()
	await _pr_settle()
	var aggregate: Dictionary = _game.capture_campaign_snapshot()
	var model: Dictionary = _game.attempts.state()
	if not _expect(paused and not aggregate.is_empty() and _game.campaign_error.is_empty() and _game.player.snapshot_error(aggregate.player).is_empty() and _game.active_level.snapshot_error_with_player(aggregate.level, aggregate.player).is_empty(), "public pause captures complete valid actual late unit"): return false
	if not _expect(aggregate.level.progress.completed and aggregate.level.progress.checkpoint_id == "villa-courtyards-clear" and aggregate.level.progress.contact_exit_id.is_empty() and model.completed_main == LONDON_PREFIX + ["A2-L4"] and aggregate.level.local.sequence.defeated_ids.slice(0, 7) == _cl_unit.level.local.sequence.defeated_ids, "original defeat prefix persists, with only actual new contact/defeats/completion"): return false
	var file_hashes: Dictionary = {"gun-view.png": _gun_png_sha}
	for pair: Array in [["gun-view.aggregate.exact.json", aggregate], ["gun-view.attempts.exact.json", model], ["gun-view.metadata.exact.json", _gun_metadata]]:
		if not _gun_write_exact(String(pair[0]), pair[1], file_hashes): return false
	var receipt: Dictionary = {"scope": "Actual two late defeats and one gun view only; prior seven/tails archived at Shared 32, original 1261/1 failed, no full-route/matrix/art acceptance", "shared_publication": GUN_PUBLICATION, "compatibility_sha256": _gun_compatibility_sha, "original_files": CLEARED_HASHES.duplicate(), "corrected_quiet32_files": GUN_CLOSURE_HASHES.duplicate(), "captured_files": file_hashes, "new_earned_files": _gun_earned_files.duplicate(), "new_defeats": _pr_defeats.duplicate(), "new_checkpoints": _pr_checkpoints.duplicate(), "new_completions": _pr_completions.duplicate(), "prior_tails_replayed": false}
	if not _gun_write_exact("receipt.exact.json", receipt, {}): return false
	var old_refs: Array[Dictionary] = _gun_tree_refs(_game.world)
	var resources: Dictionary = {"hp": _game.player.hp, "shells": _game.player.shells, "equipment": _game.player.equipment.snapshot()}
	if not await _pr_click("ResumeButton") or not await _dash_to_exit(): return false
	await _pr_settle()
	if not _expect(_game.campaign_error.is_empty() and _game.active_level.level_id == "A2-L5" and _game.active_level.scene_file_path == LONDON_DESTINATION and _pr_exits == ["putney-road"] and _pr_completions == ["london-road-open"], "only actual road navigation requests one TEST L5 transition without repeating completion"): return false
	_expect(_game.player.hp == resources.hp and _game.player.shells == resources.shells and _game.player.equipment.snapshot() == resources.equipment, "real transition retains actual HP/ammo/canonical gear without grant")
	for entry: Dictionary in old_refs: _expect((entry.ref as WeakRef).get_ref() == null, "real exit retires every old L4 world native identity: " + entry.label)
	return _failures == 0

func _gun_preserve_earned_late() -> bool:
	# Preserve only a genuinely earned quiet native barrier, before the photo.
	_game.request_pause()
	await _pr_settle()
	var unit: Dictionary = _game.capture_campaign_snapshot()
	var model: Dictionary = _game.attempts.state()
	if not _expect(paused and not unit.is_empty() and _game.campaign_error.is_empty() and _game.player.snapshot_error(unit.player).is_empty() and _game.active_level.snapshot_error_with_player(unit.level, unit.player).is_empty(), "public native pause captures a valid newly earned completed late unit before gun navigation"): return false
	if not _expect(unit.level.local.sequence.stage_index == 8 and unit.level.progress.completed and unit.level.progress.checkpoint_id == "villa-courtyards-clear" and unit.level.progress.contact_exit_id.is_empty() and unit.level.local.sequence.defeated_ids.slice(0, 7) == _cl_unit.level.local.sequence.defeated_ids and model.completed_main == LONDON_PREFIX + ["A2-L4"] and PriorityJson.stringify(model.story.snapshot) == PriorityJson.stringify(unit), "newly preserved whole model contains only actual late contact/defeats/completion and its untouched prior prefix"): return false
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GUN_CAPTURE_ROOT)) == OK, "new earned-late native artifacts own separate ignored output"): return false
	for pair: Array in [["earned-late.aggregate.exact.json", unit], ["earned-late.attempts.exact.json", model]]:
		if not _gun_write_exact(String(pair[0]), pair[1], _gun_earned_files): return false
	var receipt: Dictionary = {"scope": "Actual newly earned two Putney defeats and completed quiet native unit before gun navigation; prior seven/tails archived at Shared 32, original 1261/1 failed", "shared_publication": GUN_PUBLICATION, "compatibility_sha256": _gun_compatibility_sha, "original_files": CLEARED_HASHES.duplicate(), "captured_files": _gun_earned_files.duplicate(), "new_defeats": _pr_defeats.duplicate(), "new_checkpoints": _pr_checkpoints.duplicate(), "new_completions": _pr_completions.duplicate(), "new_exits": _pr_exits.duplicate(), "prior_tails_replayed": false}
	if not _gun_write_exact("earned-late.receipt.exact.json", receipt, _gun_earned_files): return false
	print("Preserved actual L4 earned-late unit/model: ", GUN_CAPTURE_ROOT, " checksums=", _gun_earned_files)
	if not await _pr_click("ResumeButton"): return false
	return _expect(_gun_quiet() and _game.player.equipment.snapshot() == _cl_unit.equipment_ids, "actual GUI Resume continues the new quiet late unit without gear or authority refresh")

func _gun_quiet() -> bool:
	if not _live() or paused or _state().beat != "clear" or not _state().exit_open or not _game.active_level.is_completed() or _actors.size() != 9 or _banks.size() != 2: return false
	for actor: Node in _actors.values():
		if not is_instance_valid(actor) or actor.get("hp") != 0.0: return false
	for bank: Node in _banks.values():
		if not is_instance_valid(bank) or bank.call("state").get("status") != "complete": return false
	return true

func _gun_original_banks_unchanged() -> bool:
	for id: String in _banks:
		var native: Dictionary = _banks[id].call("state")
		var saved: Dictionary = _cl_unit.level.local.banks[id]
		if not _expect(native.status == "complete" and native.phase == "clear" and native.reservation_id.is_empty() and native.cycle == saved.cycle and _exact_public_equal(native.exchange, saved.exchange) and _exact_public_equal(native.receipts, saved.receipts), "original bank remains actually complete with exact archived lease/deadlines/receipts: " + id): return false
	return true

func _gun_ready() -> bool:
	for frame: int in range(180):
		if not _gun_quiet(): return false
		var response: Dictionary = _game.player.get_threat_response_state()
		if _stable() and float(response.dash_cooldown_left_s) <= 0.00001: return true
		await _step()
	return _expect(false, "gun navigation waits native stable grounded Hero and actual dash cooldown")

func _gun_at_goal() -> bool:
	var at: Vector3 = _game.player.global_position
	return at.x <= -2.8 and Vector2(at.x - GUN_GOAL.x, at.z - GUN_GOAL.z).length() <= GUN_GOAL_RADIUS

func _gun_settle_camera() -> bool:
	if not await _gun_ready(): return false
	for frame: int in range(120):
		if not _gun_quiet() or not _stable() or not _gun_at_goal(): return false
		if _game.camera.global_position.distance_to(_game.player.global_position + Vector3(0, 18.75, 13)) <= 0.03: return true
		await _step()
		await process_frame
	return _expect(false, "normal following camera settles without focus/camera writes")

func _dash(direction: Vector3, allow_exit_transition: bool = false, proof_plan: Dictionary = {}, proof_segment: Dictionary = {}) -> bool:
	if not _gun_navigation: return await super._dash(direction, allow_exit_transition, proof_plan, proof_segment)
	if not await _gun_ready(): return false
	var at: Vector3 = _game.player.global_position
	var endpoint: Vector3 = at + direction.normalized() * float(_game.player.stats.dash_distance)
	if not _expect(direction.is_finite() and direction.length_squared() > 0.0 and minf(at.z, endpoint.z) > GUN_EXIT_FRONT_Z, "unshortened actual quiet swipe stays strictly before breakout contact"): return false
	var before: int = _actions.size()
	if not await super._dash(direction, false, proof_plan, proof_segment): return false
	var found: bool = false
	for record: Dictionary in _actions.slice(before):
		if record.kind != "dash": continue
		found = true
		for sample: Dictionary in record.path:
			var point: Vector3 = sample.position
			if not _expect(point.is_finite() and point.z > GUN_EXIT_FRONT_Z and point.y > -0.05 and point.y < 0.2 and _gun_floor_contains(point), "every real gun navigation sample stays on dry ground before exit"): return false
	return _expect(found, "real gun navigation publishes its genuine completed dash")

func _gun_floor_contains(point: Vector3) -> bool:
	for specification: Dictionary in LondonFloor.SPECS:
		var rect: Rect2 = specification.rect
		if rect.has_point(Vector2(point.x, point.z)): return true
	return false

func _gun_capture() -> bool:
	if not _expect(_gun_quiet() and _stable() and _gun_at_goal() and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GUN_CAPTURE_ROOT)) == OK, "actual quiet strict gun viewpoint owns separate capture directory"): return false
	await RenderingServer.frame_post_draw
	if not _expect(_gun_quiet() and _stable() and _gun_at_goal(), "native post-draw pixels retain the actual quiet landing"): return false
	var kit: Node3D = _game.active_level.get_node_or_null("LondonApproachesKit") as Node3D
	var gun: Node3D = kit.get_node_or_null(GUN_SUBJECT_PATH) as Node3D if is_instance_valid(kit) else null
	if not _expect(is_instance_valid(gun) and gun.is_inside_tree() and gun.is_visible_in_tree() and gun.global_transform.is_finite() and gun.global_position == Vector3(-5.0, 0.0, -43.8) and gun.global_basis.is_equal_approx(Basis(Vector3.UP, PI / 3.0)), "actual Kit5 existing gun has its authored fixed yaw/position, no pose staging"): return false
	var points: Array[Vector3] = []
	points.assign(_game.active_level.call("_required_source_points", gun))
	var required: Array[Vector3] = []
	required.assign(_game.call("player_camera_framing_points"))
	required.append_array(points)
	if not _expect(not points.is_empty() and _raw_camera_error(points).is_empty() and _raw_camera_error(required).is_empty(), "actual full gun bounds and full Hero fit the native HUD-safe view after normal follow"): return false
	var image: Image = root.get_texture().get_image()
	if not _expect(image != null and image.get_size() == Vector2i(540, 1170) and image.save_png(GUN_CAPTURE_ROOT + "gun-view.png") == OK, "save one actual native 540x1170 gun view"): return false
	_gun_png_sha = FileAccess.get_sha256(GUN_CAPTURE_ROOT + "gun-view.png")
	var native_points: Array = []
	for point: Vector3 in points: native_points.append(Codec.vector3(point))
	var hero_points: Array = []
	for point: Vector3 in required: hero_points.append(Codec.vector3(point))
	var actions: Array[Dictionary] = []
	var clock: float = float(_game.player.get_threat_response_state().action_clock_s)
	for record: Dictionary in _actions.slice(_gun_navigation_start):
		var encoded: Dictionary = CinderPlayer.encode_world_action_record(record, clock)
		if not _expect(record.kind == "dash" and not encoded.is_empty(), "quiet gun route retains exact public completed dash records"): return false
		actions.append(encoded)
	if not _expect(not actions.is_empty(), "gun viewpoint has genuinely completed ordinary swipe navigation"): return false
	var safe: Rect2 = _game.hud.call("combat_safe_rect")
	_gun_metadata = {"scope": "One actual Kit5 gun photo after archived7 and two real Putney defeats; pixel recognizability needs separate review", "shared_publication": GUN_PUBLICATION, "compatibility_sha256": _gun_compatibility_sha, "producer_source_sha256": CLEARED_SOURCE_SHA, "original_files": CLEARED_HASHES.duplicate(), "new_earned_files": _gun_earned_files.duplicate(), "original_protected_checkpoint_exact_sha256": PriorityJson.stringify(_cl_model.story.checkpoint).sha256_text(), "prior_tails_replayed": false, "label": "gun-view", "image": GUN_CAPTURE_ROOT + "gun-view.png", "image_sha256": _gun_png_sha, "beat": _state().beat, "clock_s": _state().clock_s, "hero_position": Codec.vector3(_game.player.global_position), "hero_hp": _game.player.hp, "shells": _game.player.shells, "equipment_ids": _game.player.equipment.snapshot(), "input": _input_json(), "actual_gun_navigation": actions, "navigation_goal_xz": [-3.0, -44.0], "navigation_radius_m": GUN_GOAL_RADIUS, "gun_path": String(gun.get_path()), "gun_native_id_decimal": str(gun.get_instance_id()), "gun_global_position": Codec.vector3(gun.global_position), "gun_global_basis": {"x": Codec.vector3(gun.global_basis.x), "y": Codec.vector3(gun.global_basis.y), "z": Codec.vector3(gun.global_basis.z)}, "gun_visible": gun.is_visible_in_tree(), "gun_bounds_points": native_points, "hero_and_gun_required_points": hero_points, "gun_camera_error": _raw_camera_error(points), "combined_camera_error": _raw_camera_error(required), "kit_art_revision": kit.get_meta("art_revision", ""), "camera_position": Codec.vector3(_game.camera.global_position), "camera_size": _game.camera.size, "camera_basis": {"x": Codec.vector3(_game.camera.global_basis.x), "y": Codec.vector3(_game.camera.global_basis.y), "z": Codec.vector3(_game.camera.global_basis.z)}, "hud_safe_rect": {"position": [safe.position.x, safe.position.y], "size": [safe.size.x, safe.size.y]}, "new_defeats": _pr_defeats.duplicate(), "new_checkpoints": _pr_checkpoints.duplicate(), "new_completions": _pr_completions.duplicate(), "exit_requested": not _pr_exits.is_empty()}
	print("Actual L4 late gun view: ", GUN_CAPTURE_ROOT + "gun-view.png", " SHA256=", _gun_png_sha)
	return _gun_sha_valid(_gun_png_sha)

func _gun_write_exact(name: String, value: Variant, hashes: Dictionary) -> bool:
	var text: String = PriorityJson.stringify(value)
	if not _expect(not text.is_empty(), "exact closed gun evidence is serializable: " + name): return false
	var file: FileAccess = FileAccess.open(GUN_CAPTURE_ROOT + name, FileAccess.WRITE)
	if not _expect(file != null, "open separate gun evidence: " + name): return false
	file.store_string(text)
	file.close()
	hashes[name] = FileAccess.get_sha256(GUN_CAPTURE_ROOT + name)
	return _expect(hashes[name] == text.sha256_text(), "actual gun evidence checksum matches exact written bytes: " + name)

func _gun_tree_refs(node: Node) -> Array[Dictionary]:
	var refs: Array[Dictionary] = []
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		refs.append({"label": String(current.get_path()), "ref": weakref(current)})
		pending.append_array(current.get_children())
	return refs

func _step() -> void:
	if _hp_watch_timeout: return
	await _native_probe.tick_finished
	_observe_runtime()
	await _observe_hp_watchdog()

func _progress_diagnostic_root() -> String:
	return GUN_TEST_ROOT

func _cl_cleanup_paths() -> void:
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GUN_TEST_ROOT + name))
