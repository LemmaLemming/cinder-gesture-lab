extends "res://tests/acts/act1/a1_o1_campaign.gd"
## PRIVATE SOURCE DRAFT. One genuine original-writer custody producer only.
## TEST predecessor prefix / same-floor Hero positions are disclosed by parent.
## No native HP, phase, clock, lease, source position or progress is assigned.

const LegacyCodec = preload("res://scripts/acts/act1/salvage_circuit_codec.gd")
const DIFFICULTY_BRANCHES: Array[String] = ["entrance", "one-part-live", "pre-final-checkpoint", "final-epoch-opposite"]
const ORIGINAL_SOURCE_SHA256: Dictionary = {
	"res://scripts/acts/act1/salvage_circuit.gd": "66f8b88b120cd466c8d6df23911f7c823a90df0594f388eb44cc1c4b4fd36776",
	"res://scripts/acts/act1/salvage_circuit_codec.gd": "0e7e3432388af3a7cae8af6a706f811ff098c6d980f2f3a8a29c486f28d4418f",
	"res://scripts/acts/act1/salvage_circuit_layout.gd": "6a395b291698d7f1218aca81e34b53578dea3c5c772ce8b70d5afd9ccac43aec",
	"res://tests/acts/act1/a1_o1_campaign.gd": "37b7df85460f1d11c8d8da0dfd5fdb1511c8b2307542f6a33ed548ba27fccc50",
	"res://tests/acts/act1/a1_o1_mechanics.gd": "9bbdbeadd8dee96cac2938e53edc2475676a14341f213f156a053ed3f3c516c1",
}
const DIFFICULTY_RECIPE_PATH: String = "res://data/campaign/act1/a1_o1_difficulty_arrangements.json"
const DIFFICULTY_SOURCE_PATHS: Array[String] = [
	"res://scripts/acts/act1/salvage_circuit.gd", "res://scripts/acts/act1/salvage_circuit_layout.gd",
	"res://scripts/acts/act1/salvage_circuit_codec.gd", "res://scripts/acts/act1/salvage_circuit_part.gd",
	"res://scripts/acts/act1/salvage_circuit_scenery.gd", "res://scenes/acts/act1/a1_o1.tscn",
	"res://scripts/acts/act1/rush_selenite.gd", "res://scripts/combat/lane_mechanism.gd",
	"res://scripts/combat/threat_scheduler.gd", "res://scripts/campaign/level.gd",
	"res://scripts/campaign/shell.gd", "res://scripts/campaign/attempts.gd",
	"res://scripts/campaign/save_store.gd", "res://scripts/campaign/exact_json.gd",
	"res://tests/acts/act1/a1_o1_campaign.gd", "res://tests/acts/act1/a1_o1_mechanics.gd",
	DIFFICULTY_RECIPE_PATH,
]

var difficulty_case: String = ""
var branch_root: String = ""
var branches: Dictionary = {}
var branch_order: Array[String] = []
var assertion_rows: Array[Dictionary] = []
var source_pre: Dictionary = {}
var source_post: Dictionary = {}
var producer_scope_complete: bool = false
var cleanup_complete: bool = false
var producer_final_observation: Dictionary = {}


func _initialize() -> void:
	super._initialize() # Original120s watchdog, signal observation and deferred _run.
	test_root = "user://test-act1-o1-difficulty-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	report_path = "res://.cinder/a1-o1-difficulty-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	branch_root = "res://.cinder/a1-o1-difficulty-branches-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]


func _run() -> void:
	root.size = Vector2i(540, 1170)
	registry_bytes = FileAccess.get_file_as_bytes(Registry.DATA_PATH)
	source_pre = _difficulty_source_pins()
	if not _difficulty_parse_arguments() or not _original_writer(): await _finish(); return
	if not _expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(branch_root)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(branch_root)) == OK, "new dedicated branch archive directory cannot overwrite an earlier producer"):
		await _finish(); return
	var parsed: Variant = JSON.parse_string(registry_bytes.get_string_from_utf8())
	if not _expect(parsed is Dictionary and parsed.get("levels") is Array, "canonical Registry supplies isolated TEST metadata"): await _finish(); return
	raw = parsed.duplicate(true)
	var changed: int = 0
	for row: Dictionary in raw.levels:
		if row.id == Layout.LEVEL_ID:
			setups.append({"kind": "TEST in-memory O1 row only", "before": row.duplicate(true), "scene_path": O1_PATH, "accepted_commit": "f".repeat(40)})
			row.scene_path = O1_PATH; row.readiness = "accepted"; row.accepted_commit = "f".repeat(40); row.api_revision = Registry.API_REVISION
			changed += 1
	var registry: CinderCampaignRegistry = Registry.new(raw)
	if not _expect(changed == 1 and registry.last_error.is_empty() and registry.scene_error(Layout.LEVEL_ID).is_empty() and registry.scene_error("A1-L2").is_empty(), "isolated O1 row and unchanged accepted L2 scene are valid"): await _finish(); return
	var entry: Dictionary = registry.entry(Layout.LEVEL_ID)
	if not _expect(entry.parent_level_id == "A1-L2" and registry.is_unlocked(Layout.LEVEL_ID, PREFIX) and not registry.is_unlocked(Layout.LEVEL_ID, ["A1-L1"]) and entry.reward_id == REWARD_ID, "original optional parent unlock and stamp identity are retained"): await _finish(); return
	if not await _seed_story(registry) or not await _new_shell(): await _finish(); return
	game.menu.continue_story_requested.emit()
	if not await _await_operation(func() -> bool: return _live("A1-L2") and paused and game.menu.page_name() == "resume" and _difficulty_idle(), "actual protected Story install is settled", 8.0): await _finish(); return
	protected_story = game.attempts.state().story.duplicate(true)
	unlocked_before = game.attempts.state().unlocked_equipment.duplicate()
	if not _expect(_same(game.capture_campaign_snapshot(), protected_story.snapshot) and game.attempts.state().completed_main == PREFIX and _durable(), "real pristine L2 Story plus disclosed TEST prefix is protected"): await _finish(); return
	if not await _difficulty_preference("challenge"): await _finish(); return
	game.menu.optional_requested.emit(Layout.LEVEL_ID)
	if not await _await_operation(func() -> bool: return _live(Layout.LEVEL_ID) and paused and game.menu.page_name() == "resume" and game.attempts.active_kind() == "optional" and _difficulty_idle(), "fresh actual Challenge Optional entry is settled", 8.0): await _finish(); return
	var entrance: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_legacy_unit(entrance) and entrance.shell.difficulty_at_entry == "challenge" and entrance.level.local.scheduler.profile.id == "challenge" and entrance.level.local.scheduler.clock_s == 0.0 and entrance.level.local.collected_ids.is_empty() and entrance.level.local.sources[Layout.FINAL_SOURCE_ID].dormant and _same(game.attempts.state().side_attempt.checkpoint, entrance) and _bindings(), "genuine original13-key Challenge is born at public Optional entry with pristine own checkpoint"): await _finish(); return
	if not _archive_difficulty_branch("entrance"): await _finish(); return
	if not await _contact_part("nose-cap"): await _finish(); return
	if not await _wait_live(func() -> bool: return _source(Layout.CIRCUIT_SOURCE_ID).state().status == "running" and not _source(Layout.CIRCUIT_SOURCE_ID).state().reservation_id.is_empty() and _impact().state().status == "running" and _impact().state().phase in ["warning", "lock"], "natural original Challenge paired C30/impact admission", 10.0): await _finish(); return
	if not await _pause("original Challenge one-part paired Save") or not await _difficulty_settled("one-part Save"): await _finish(); return
	var partial: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_legacy_unit(partial) and partial.level.local.collected_ids == ["nose-cap"] and partial.level.local.stage == "circuit" and partial.level.local.scheduler.profile.id == "challenge" and partial.level.local.scheduler.reservations.size() == 2 and partial.level.local.impact.status == "running" and not partial.level.local.sources[Layout.CIRCUIT_SOURCE_ID].reservation_id.is_empty() and partial.level.local.sources[Layout.FINAL_SOURCE_ID].dormant and _same(game.attempts.state().side_attempt.checkpoint, entrance), "genuine one-part paired current retains the exact independent entrance checkpoint"): await _finish(); return
	if not _archive_difficulty_branch("one-part-live"): await _finish(); return
	for id: String in ["hatch-disc", "rivet-band"]:
		if not await _contact_part(id): await _finish(); return
	if not await _await_operation(func() -> bool: return _stored_checkpoint_ready() and _difficulty_idle() and _durable(), "actual three-contact checkpoint finishes its queued Store commit", 10.0): await _finish(); return
	var checkpoint: Dictionary = game.attempts.state().side_attempt.checkpoint.duplicate(true)
	if not _expect(_legacy_unit(checkpoint) and checkpoint.level.local.collected_ids == ["nose-cap", "hatch-disc", "rivet-band"] and checkpoint.level.local.stage == "final" and checkpoint.level.local.checkpoint_published and not checkpoint.level.local.final_started and checkpoint.level.local.sources[Layout.FINAL_SOURCE_ID].dormant and checkpoint.level.local.sources[Layout.FINAL_SOURCE_ID].cycle == 0 and checkpoint.level.local.scheduler.profile.id == "challenge" and checkpoint.level.local.scheduler.reservations.is_empty() and checkpoint.level.progress.checkpoint_ids == {Layout.CHECKPOINT_ID: "encounter"}, "genuine earlier pre-final Challenge checkpoint is actual dormant native state"): await _finish(); return
	receipts.append({"label": "original checkpoint publication before independent Retry branch", "exact_checkpoint": Exact.stringify(checkpoint), "native_state_after_drain": _diagnostic()})
	# Checkpoint dispatch may already auto-resume. Never substitute that later
	# current for the earlier checkpoint or edit Attempts to create a branch.
	if not await _pause("settle actual post-checkpoint current") or not await _difficulty_settled("post-checkpoint current"): await _finish(); return
	if not await _retry_checkpoint(checkpoint) or not await _difficulty_settled("independent public Retry branch"): await _finish(); return
	if not _expect(_same(game.capture_campaign_snapshot(), checkpoint) and _same(game.attempts.state().side_attempt.snapshot, checkpoint) and _same(game.attempts.state().side_attempt.checkpoint, checkpoint), "public Retry produces a real whole Store branch with current equal to its original earlier checkpoint"): await _finish(); return
	if not _archive_difficulty_branch("pre-final-checkpoint"): await _finish(); return
	if not await _difficulty_preference("standard"): await _finish(); return
	if not _expect(_same(game.capture_campaign_snapshot(), checkpoint) and _same(game.attempts.state().side_attempt.checkpoint, checkpoint) and _scheduler().encounter_profile().id == "challenge", "opposite future preference leaves the actual earlier Challenge current/checkpoint and native profile exact"): await _finish(); return
	if not await _resume("natural final boundary after opposite future preference"): await _finish(); return
	if not await _wait_live(func() -> bool: return _source(Layout.FINAL_SOURCE_ID).state().status == "running" and _source(Layout.FINAL_SOURCE_ID).state().phase == "warning" and _final_admission().get("accepted", false), "actual final C30 warning under its new Standard epoch", 10.0): await _finish(); return
	if not await _pause("later opposite-profile final epoch Save") or not await _difficulty_settled("final epoch Save"): await _finish(); return
	var final_unit: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_legacy_unit(final_unit) and final_unit.shell.difficulty_at_entry == "challenge" and final_unit.level.local.stage == "final" and final_unit.level.local.final_started and not final_unit.level.local.final_defeated and final_unit.level.local.scheduler.encounter_id == "salvage-final-encounter" and final_unit.level.local.scheduler.profile.id == "standard" and final_unit.level.local.sources[Layout.FINAL_SOURCE_ID].profile_id == "standard" and final_unit.level.local.sources[Layout.FINAL_SOURCE_ID].hp == 20.0 and not final_unit.level.local.sources[Layout.FINAL_SOURCE_ID].reservation_id.is_empty() and _same(game.attempts.state().side_attempt.checkpoint, checkpoint), "later genuine Standard final epoch keeps Challenge birth and the same earlier Challenge checkpoint without transplant"): await _finish(); return
	if not _archive_difficulty_branch("final-epoch-opposite"): await _finish(); return
	producer_final_observation = _diagnostic()
	producer_scope_complete = branch_order == DIFFICULTY_BRANCHES
	await _finish()


func _difficulty_parse_arguments() -> bool:
	var seen: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		var key: String = "case" if argument.begins_with("--case=") else ("branch-root" if argument.begins_with("--branch-root=") else "")
		if not _expect(not key.is_empty() and not seen.has(key), "only unique exact case/branch-root producer arguments are accepted: " + argument): return false
		seen[key] = true
		if key == "case": difficulty_case = argument.trim_prefix("--case=")
		else: branch_root = argument.trim_prefix("--branch-root=").trim_suffix("/")
	return _expect(difficulty_case == "legacy-producer" and branch_root.begins_with("res://.cinder/") and not ".." in branch_root and not "\\" in branch_root and branch_root != "res://.cinder", "one original-writer case and a dedicated local .cinder branch root are required")


func _difficulty_source_pins() -> Dictionary:
	var result: Dictionary = {}
	var paths: Array[String] = DIFFICULTY_SOURCE_PATHS.duplicate()
	paths.append(get_script().resource_path)
	for path: String in paths:
		result[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "<absent>"
	return result


func _original_writer() -> bool:
	for path: String in ORIGINAL_SOURCE_SHA256:
		if not _expect(source_pre.get(path) == ORIGINAL_SOURCE_SHA256[path], "literal original writer/helper source remains installed: " + path): return false
	return _expect(source_pre.get(DIFFICULTY_RECIPE_PATH) == "<absent>", "no new O1 difficulty recipe exists before this original-writer seal")


func _difficulty_idle() -> bool:
	return is_instance_valid(game) and not bool(game.get("_draining")) and not bool(game.get("_drain_queued")) and not bool(game.get("_registration_inflight")) and not bool(game.get("_registration_pending")) and not bool(game.get("_pause_request_pending")) and (game.get("_operations") as Array).is_empty() and (game.get("_failed_operations") as Array).is_empty()


func _difficulty_settled(label: String) -> bool:
	return await _await_operation(func() -> bool: return paused and _difficulty_idle() and _durable(), "settled original whole Store barrier: " + label, 8.0)


func _difficulty_preference(profile_id: String) -> bool:
	if not await _difficulty_settled("before future preference " + profile_id): return false
	var before: Dictionary = game.capture_campaign_snapshot()
	var before_attempts: String = Exact.stringify(game.attempts.state())
	game.menu.difficulty_preference_requested.emit(profile_id)
	var preference_envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(test_root + "preferences.json"))
	var preference: Dictionary = Exact.parse(String(preference_envelope.get("payload_json", ""))) if preference_envelope is Dictionary else {}
	return _expect(_closed(before) and game.get_difficulty_preference() == profile_id and preference.get("accepted", false) and preference.value == {"schema_version": 1, "profile_id": profile_id} and _same(game.capture_campaign_snapshot(), before) and Exact.stringify(game.attempts.state()) == before_attempts, "public future preference persists separately without changing current or checkpoint: " + profile_id)


func _legacy_unit(unit: Dictionary) -> bool:
	if not _closed(unit) or not unit.level.get("local") is Dictionary: return false
	var local: Dictionary = unit.level.local
	return local.size() == 13 and local.get("api_revision") == "act1-salvage-circuit-1" and local.get("schema_version") is int and local.schema_version == 1 and local.get("world_revision") is int and local.world_revision == 1 and not local.has("circuit_arrangement") and unit.level.local_snapshot_version == 1 and LegacyCodec.metadata_error(local).is_empty() and _same(local.impact.configuration.geometry, {"kind": "circle", "origin": Codec.vector3(Layout.IMPACT_POSITION), "radius": Layout.IMPACT_RADIUS})


func _archive_difficulty_branch(label: String) -> bool:
	operation = "literal original whole branch archive: " + label
	if not _expect(label in DIFFICULTY_BRANCHES and not branches.has(label) and paused and _difficulty_idle() and _durable(), "branch capture uses one settled original paused Store: " + label): return false
	var current: Dictionary = game.capture_campaign_snapshot()
	var attempts: Dictionary = game.attempts.state()
	var side: Dictionary = attempts.side_attempt
	var checkpoint: Dictionary = side.checkpoint
	if not _expect(_legacy_unit(current) and _legacy_unit(checkpoint) and _same(side.snapshot, current) and _same(attempts.story, protected_story) and not current.level.progress.completed and attempts.completed_optional.is_empty() and attempts.reward_ids.is_empty(), "actual whole optional current/checkpoint/Story joins with no completion or reward: " + label): return false
	var row: Dictionary = {"label": label, "complete": false, "current_exact": Exact.stringify(current), "checkpoint_exact": Exact.stringify(checkpoint), "attempts_exact": Exact.stringify(attempts), "protected_story_exact": Exact.stringify(protected_story), "future_profile": game.get_difficulty_preference(), "all_original_disk_files": {}, "original_disk_presence": {}, "native_identities": _ids(), "body_metadata": {"hero_position": Codec.vector3(game.player.global_position), "circuit_position": Codec.vector3(_source(Layout.CIRCUIT_SOURCE_ID).global_position), "final_position": Codec.vector3(_source(Layout.FINAL_SOURCE_ID).global_position), "impact_position": Codec.vector3(_impact().global_position), "floor_size": Codec.vector3(((game.active_level.get_node("Floor/CollisionShape3D") as CollisionShape3D).shape as BoxShape3D).size)}, "root_size": [root.size.x, root.size.y], "diagnostic": _diagnostic()}
	branches[label] = row # Preserve a partial receipt even if a later archive write fails.
	for prefix: String in ["current", "checkpoint", "attempts", "protected_story"]:
		var wire: String = row[prefix + "_exact"]
		var decoded: Dictionary = Exact.parse(wire)
		if not _expect(not wire.is_empty() and decoded.get("accepted", false) and Exact.stringify(decoded.value) == wire, "complete original typed " + prefix + " wire round trips: " + label): return false
		row[prefix + "_sha256"] = wire.sha256_text()
	var directory: String = branch_root + "/" + label
	if not _expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(directory)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) == OK, "dedicated original branch directory is new and writable: " + label): return false
	var original: DirAccess = DirAccess.open(test_root)
	if not _expect(original != null, "original isolated Store directory exists before cleanup: " + label): return false
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		row.original_disk_presence[name] = FileAccess.file_exists(test_root + name)
	for name: String in original.get_files():
		var source: String = test_root + name
		var destination: String = directory + "/" + name
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(source)
		var copied: Error = DirAccess.copy_absolute(ProjectSettings.globalize_path(source), ProjectSettings.globalize_path(destination))
		var hash: String = _difficulty_bytes_sha256(bytes)
		row.all_original_disk_files[name] = {"path": destination, "original_path": source, "bytes": bytes.size(), "sha256": hash, "hex": bytes.hex_encode()}
		if not _expect(copied == OK and hash.length() == 64 and FileAccess.get_file_as_bytes(destination) == bytes and _difficulty_bytes_sha256(FileAccess.get_file_as_bytes(destination)) == hash, "literal original disk bytes are copied before further writes/cleanup: " + label + "/" + name): return false
	if not _expect(row.all_original_disk_files.has("campaign.json") and row.all_original_disk_files.has("campaign.json.bak") and row.all_original_disk_files.has("preferences.json"), "original campaign, actual backup and preference files are archived: " + label): return false
	row["raw_store"] = row.all_original_disk_files["campaign.json"].duplicate(true)
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(directory + "/campaign.json"))
	if not _expect(envelope is Dictionary and envelope.get("format_version") == 2 and envelope.get("payload_json") == row.attempts_exact and envelope.get("sha256") == row.attempts_sha256, "literal original Store envelope contains exactly the complete captured Attempts wire: " + label): return false
	row["generation"] = int(envelope.generation)
	row["complete"] = true
	var file: FileAccess = FileAccess.open(directory + "/branch.json", FileAccess.WRITE)
	if not _expect(file != null, "original branch manifest is writable: " + label): row.complete = false; return false
	file.store_string(JSON.stringify(row, "\t")); file.flush()
	var write_error: Error = file.get_error(); file.close()
	if not _expect(write_error == OK and JSON.parse_string(FileAccess.get_file_as_string(directory + "/branch.json")) == JSON.parse_string(JSON.stringify(row)), "original complete branch manifest survives literal write/read: " + label): row.complete = false; return false
	branch_order.append(label)
	return true


func _difficulty_bytes_sha256(bytes: PackedByteArray) -> String:
	var hashing := HashingContext.new()
	if hashing.start(HashingContext.HASH_SHA256) != OK or hashing.update(bytes) != OK: return ""
	return hashing.finish().hex_encode()


func _expect(ok: bool, label: String) -> bool:
	assertion_rows.append({"index": checks + 1, "passed": ok, "label": label})
	return super._expect(ok, label)


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true; operation = "normal final producer cleanup"
	var refs: Array[WeakRef] = []
	if is_instance_valid(preview):
		var level: CinderLevel = preview.get("active_level") as CinderLevel
		if level != null: level.exit_level()
		refs.append_array(_refs(preview)); preview.free(); preview = null
	if is_instance_valid(game):
		if is_instance_valid(game.active_level): game.active_level.exit_level()
		refs.append_array(_refs(game)); game.free(); game = null
	paused = false
	await create_timer(0.5, true).timeout
	await process_frame
	cleanup_complete = _expect((refs.is_empty() or _freed(refs)) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal final Shell/Main cleanup frees original native descendants and source/cue groups")
	_expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH) == registry_bytes, "isolated producer leaves every canonical Registry byte unchanged")
	source_post = _difficulty_source_pins()
	_expect(source_post == source_pre, "all named original source inputs and recipe absence remain unchanged throughout this producer")
	# All completed branch files were already durably copied. Keep inherited
	# normal isolated-user cleanup; no later copy can substitute a missing branch.
	var directory := DirAccess.open(test_root)
	if directory != null:
		for name: String in directory.get_files(): DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	var report: FileAccess = FileAccess.open(report_path, FileAccess.WRITE)
	if report == null: _expect(false, "unique native difficulty producer report is writable")
	var complete: bool = producer_scope_complete and cleanup_complete and branch_order == DIFFICULTY_BRANCHES and failures == 0
	if report != null:
		report.store_string(JSON.stringify({"case": difficulty_case, "checks": checks, "failures": failures, "assertions": assertion_rows, "complete": complete, "scope_complete": complete, "success": complete, "first_failure": first_failure, "elapsed_ms": Time.get_ticks_msec() - started_ms, "branch_root": branch_root, "branch_order": branch_order, "branches": branches, "source_pre": source_pre, "source_post": source_post, "setups": setups, "receipts": receipts, "observations": observations, "final_observation": producer_final_observation, "scope": "Genuine original API1/schema1 exact13 old Challenge optional writer; isolated production Shell/Attempts/Store, actual protected pristine L2 Story plus disclosed TEST completed prefix and same-floor Hero contact setup; entrance and one-part native paired current; actual three-contact checkpoint independently materialized by public Retry; later genuine Standard final epoch after public future preference retains exact same Challenge checkpoint. All original Store/backup/settings/preferences bytes preserved before cleanup. No source/phase/HP/clock/lease/progress assignment; no final kill, route comparison, hatch, reward, GUI/recognizer, portrait, all-order, equipment balance or performance claim."}, "\t"))
		report.flush(); report.close()
	print("A1-O1 DIFFICULTY: %d checks, %d failures; complete=%s; report=%s" % [checks, failures, "true" if complete else "false", report_path])
	quit(0 if complete else 1)
