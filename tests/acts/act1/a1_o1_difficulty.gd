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
	if "--case=old-east-second" in OS.get_cmdline_user_args():
		difficulty_case = "old-east-second"
		if _route_parse_arguments() and _original_writer(): await _run_old_east_second()
		await _finish(); return
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
	if not paused and not await _pause("settle actual post-checkpoint current"): await _finish(); return
	if not await _difficulty_settled("post-checkpoint current"): await _finish(); return
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
	_route_stop_observers()
	if difficulty_case == "old-east-second" and bool(route_result.complete) and not route_fault.is_empty():
		route_result["complete"] = false
		if failures == 0: _expect(false, "late final native observation refused completed old route: " + route_fault)
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
	var case_done: bool = (bool(route_result.complete) and route_fault.is_empty()) if difficulty_case == "old-east-second" else producer_scope_complete and branch_order == DIFFICULTY_BRANCHES
	var complete: bool = case_done and cleanup_complete and failures == 0
	if report != null:
		report.store_string(JSON.stringify({"case": difficulty_case, "checks": checks, "failures": failures, "assertions": assertion_rows, "complete": complete, "scope_complete": complete, "success": complete, "first_failure": first_failure, "elapsed_ms": Time.get_ticks_msec() - started_ms, "branch_root": branch_root, "branch_order": branch_order, "branches": branches, "source_pre": source_pre, "source_post": source_post, "setups": setups, "receipts": receipts, "observations": observations, "final_observation": producer_final_observation, "route_result": route_result if difficulty_case == "old-east-second" else {}, "scope": ROUTE_SCOPE if difficulty_case == "old-east-second" else "Genuine original API1/schema1 exact13 old Challenge optional writer; isolated production Shell/Attempts/Store, actual protected pristine L2 Story plus disclosed TEST completed prefix and same-floor Hero contact setup; entrance and one-part native paired current; actual three-contact checkpoint independently materialized by public Retry; later genuine Standard final epoch after public future preference retains exact same Challenge checkpoint. All original Store/backup/settings/preferences bytes preserved before cleanup. No source/phase/HP/clock/lease/progress assignment; no final kill, route comparison, hatch, reward, GUI/recognizer, portrait, all-order, equipment balance or performance claim."}, "\t"))
		report.flush(); report.close()
	print("A1-O1 DIFFICULTY: %d checks, %d failures; complete=%s; report=%s" % [checks, failures, "true" if complete else "false", report_path])
	quit(0 if complete else 1)


# Additive original-route consumer. No source/actor/clock/progress assignments.
const RouteGeometry = preload("res://scripts/combat/threat_geometry.gd")
const ROUTE_PRODUCER_SHA: String = "2a410fe2ca7265c6cc372f15296bd807f3021c77b8fda6665e195c764d2f1146"
const ROUTE_PRODUCER_FIXTURE_SHA: String = "d03a9262c28a1eaa5e8a4f0092d7017b4de750bd62998d781f83ccadb9c7f729"
const ROUTE_SCOPE: String = "One original Challenge one-part whole Store consumer; public fresh Title Resume Side, exact quiet installation, fixed full RIGHT/RIGHT/LEFT/LEFT, real east-second contact, actual stopped-C30 ordinary primary and full commitment inside its ORIGINAL recovery. Literal original disk/Attempts/Story custody retained. No consumer placement, new source/clock/phase/lease/HP, shortened dash, different side search, new arrangement, GUI gesture, portrait or novelty claim. Passive199/3000 observations occur after native100, not at an exact rejected guard callback."

class RouteObserver extends Node:
	var observe: Callable
	func _physics_process(_delta: float) -> void:
		if observe.is_valid(): observe.call()

var route_options: Dictionary = {}
var route_result: Dictionary = {"complete": false, "scope": ROUTE_SCOPE, "actions": [], "holds": [], "trace": [], "boundaries": [], "boundary_omitted": 0, "trace_omitted": 0, "contacts": [], "hits": [], "cancellations": []}
var route_row: Dictionary = {}
var route_original: Dictionary = {}
var route_leases: Dictionary = {}
var route_step: String = "input"
var route_observers: Array[Node] = []
var route_observing: bool = false
var route_observation_cursor: int = 0
var route_hit_rows: Array[Dictionary] = []
var route_fault: String = ""
var route_primary_started: bool = false
var route_clock_offset: float = 0.0
var route_last_boundary: Dictionary = {}
var route_input_hashes: Dictionary = {}


func _route_parse_arguments() -> bool:
	for argument: String in OS.get_cmdline_user_args():
		var split: int = argument.find("=")
		var key: String = argument.substr(2, split - 2) if argument.begins_with("--") and split > 2 else ""
		if not _expect(key in ["case", "source-producer-report", "source-branch-store", "source-backup-store", "source-preferences-store"] and not route_options.has(key), "unique closed old-route input selector: " + argument): return false
		route_options[key] = argument.substr(split + 1)
	if not _expect(route_options.size() == 5 and route_options.get("case") == "old-east-second", "exact old-east-second case and all four original input paths required"): return false
	difficulty_case = "old-east-second"
	for key: String in route_options:
		if key == "case": continue
		var path: String = route_options[key]
		if not _expect(path.begins_with("res://") and not ".." in path and FileAccess.file_exists(path), "existing explicit original input: " + key): return false
		route_input_hashes[path] = FileAccess.get_sha256(path)
	return true


func _run_old_east_second() -> void:
	if not _route_load_inputs(): return
	if not await _new_shell(): return
	if not _expect(Exact.stringify(game.attempts.state()) == route_row.attempts_exact and game.get_difficulty_preference() == "challenge", "fresh Title loads the exact original whole optional Attempts and persisted Challenge preference"): return
	operation = "public Title Resume Side from sealed one-part original Store"
	game.menu.resume_requested.emit()
	if not await _await_operation(func() -> bool: return _live(Layout.LEVEL_ID) and paused and game.menu.page_name() == "resume" and _difficulty_idle(), "fresh quiet installed original optional recipient", 8.0): return
	var callbacks: Array[Dictionary] = _recipient_callbacks()
	var installed: Dictionary = game.capture_campaign_snapshot()
	if not _expect(Exact.stringify(installed) == route_row.current_exact and Exact.stringify(game.attempts.state()) == route_row.attempts_exact and Exact.stringify(game.attempts.state().story) == route_row.protected_story_exact and callbacks.is_empty() and _bindings() and _durable(), "fresh actual installed recipient equals all original typed bytes with zero installed callbacks and intact native bindings"): return
	for name: String in route_row.all_original_disk_files:
		if not _expect(FileAccess.get_file_as_bytes(test_root + name).hex_encode() == route_row.all_original_disk_files[name].hex, "quiet Continue leaves original disk bytes untouched: " + name): return
	route_result["installed"] = {"exact_snapshot": Exact.stringify(installed), "exact_attempts": Exact.stringify(game.attempts.state()), "identities": _ids(), "installed_callbacks": callbacks, "consumer_pid": OS.get_process_id(), "cross_process_numeric_ids_are_not_global_identity": true}
	var response: Dictionary = game.player.get_threat_response_state()
	if not _expect(response.stable and float(response.commitment_remaining_s) == 0.0 and float(response.dash_cooldown_left_s) == 0.0 and float(response.primary_cooldown_left_s) == 0.0 and game.player.hp == 100.0 and game.player.shells == 2 and _same(Codec.vector3(game.player.global_position), route_original.player.motion.position) and absf(game.player.global_position.x + 2.0) <= LANDING_PHYSICAL_BOUND and absf(game.player.global_position.z) <= LANDING_PHYSICAL_BOUND, "actual restored west Hero is supported ready neutral and unchanged; no consumer placement"): return
	for id: String in [Layout.CIRCUIT_SOURCE_ID, Layout.IMPACT_ID]:
		var records: Array = _route_control(id).get("reservations", [])
		if not _expect(records.size() == 1, "one original live lease retained at Continue: " + id): return
		route_leases[id] = records[0].duplicate(true)
		var original: Dictionary = {}
		for saved: Dictionary in route_original.level.local.scheduler.reservations:
			if saved.source_id == id: original = saved
		if not _expect(not original.is_empty() and records[0].id == original.id and records[0].start_s == original.start_s and records[0].active_from_s == original.active_from_s and records[0].active_until_s == original.active_until_s and records[0].recovery_until_s == original.recovery_until_s, "original source lease/deadlines restored without replacement: " + id): return
	route_clock_offset = _scheduler().get_clock() - game.player.get_world_action_clock()
	route_result["original_leases_exact"] = _route_exact(route_leases)
	route_result["original_frames_exact"] = _route_exact(game.active_level.get("_frames"))
	route_result["clock_offset_s"] = route_clock_offset
	route_result["initial_native"] = _route_native()
	route_observation_cursor = observations.size()
	route_observing = true
	for priority: int in [199, 3000]:
		var observer := RouteObserver.new(); observer.name = "OldRoutePassive%d" % priority; observer.process_mode = Node.PROCESS_MODE_PAUSABLE; observer.process_physics_priority = priority
		observer.observe = Callable(self, "_route_observe").bind(priority); root.add_child(observer); route_observers.append(observer)
	_route_boundary(199, true); _route_boundary(3000, true)
	if not await _resume("fixed old east-second ordinary route"): return
	if not await _route_dash(Vector3.RIGHT, Vector3(0.7, game.player.global_position.y, 0), "first-right"): return
	route_step = "original-circle-active-hold"
	var circle: Dictionary = route_leases[Layout.IMPACT_ID]
	var hold_start: float = _scheduler().get_clock()
	var hold_position: Vector3 = game.player.global_position
	var ready_at: float = hold_start + float(game.player.get_threat_response_state().dash_cooldown_left_s)
	var hold_until: float = maxf(ready_at, float(circle.active_from_s))
	var intended: Dictionary = {"from": hold_position, "to": hold_position, "start_s": hold_start, "end_s": hold_until}
	route_result.holds.append({"intended_exact": _route_exact(intended), "complete": false})
	if not _expect(hold_until <= float(circle.active_until_s) and _route_timed_safe(intended), "known original union permits exactly the required stationary wait before original impact active/readiness"): return
	if not await _route_wait(func() -> bool: return _dash_ready() and _scheduler().get_clock() >= float(circle.active_from_s), "actual original impact active plus native dash readiness", float(circle.active_until_s), 8.0): return
	var active: Dictionary = _route_current_lease(Layout.IMPACT_ID)
	var observed_hold: Dictionary = {"from": hold_position, "to": game.player.global_position, "start_s": hold_start, "end_s": _scheduler().get_clock()}
	route_result.holds[-1]["actual_exact"] = _route_exact(observed_hold); route_result.holds[-1]["complete"] = true
	if not _expect(active.get("state") == "active" and game.player.global_position.is_equal_approx(hold_position) and _route_timed_safe(observed_hold), "actual unchanged held landing ends within this original circle active window"): return
	if not await _route_dash(Vector3.RIGHT, Vector3(3.4, game.player.global_position.y, 0), "second-right-east-contact"): return
	if not _expect(game.active_level.get("collected_ids") == ["nose-cap", "rivet-band"] and route_result.contacts.size() == 1 and route_result.contacts[0].value.id == "rivet-band" and route_result.contacts[0].value.order == ["nose-cap", "rivet-band"] and route_result.contacts[0].get("route_stamp", {}).get("step") == "second-right-east-contact" and route_result.contacts[0].get("route_stamp", {}).get("committed_dash", {}).get("active", false), "actual east Area contact was exactly second during the full second-right path"): return
	if not await _route_dash(Vector3.LEFT, Vector3(0.7, game.player.global_position.y, 0), "first-left-return"): return
	if not await _route_dash(Vector3.LEFT, Vector3(-2.0, game.player.global_position.y, 0), "second-left-return"): return
	route_step = "ordinary-opening"
	var host: Dictionary = route_leases[Layout.CIRCUIT_SOURCE_ID]
	if not await _route_wait(func() -> bool: return _primary_ready() and _scheduler().get_clock() >= float(host.active_until_s), "ordinary readiness at original stopped-C30 opening", float(host.recovery_until_s), 8.0): return
	var lease: Dictionary = _route_current_lease(Layout.CIRCUIT_SOURCE_ID)
	var actor: Act1RushSelenite = _source(Layout.CIRCUIT_SOURCE_ID)
	var primary_time: float = _scheduler().get_clock()
	var commitment: float = float(game.player.get_threat_response_state().primary_commitment_s)
	if not _expect(lease.get("state") == "recovery" and lease.get("adapter", {}).get("finished", false) and actor.velocity == Vector3.ZERO and actor.hp == 20.0 and not actor.dead and primary_time + commitment < float(host.recovery_until_s) and actor.global_position.is_equal_approx(host.opening_position), "actual original C30 finished and stopped at native opening with full ordinary commitment before original recovery end"): return
	var sequence: int = _last_sequence(); var hp: float = actor.hp; var shells: int = game.player.shells
	var aim: Vector3 = (actor.global_position - game.player.global_position).normalized()
	# Mutation authority is the ordinary public primary only. Death/cancel after this is expected.
	route_primary_started = true
	var hits: int = game.player.slash(aim)
	var actions: Array[Dictionary] = game.player.get_world_action_records(sequence)
	route_result["primary"] = {"started_s": primary_time, "aim": _route_encode(aim), "host_before_exact": _route_exact(lease), "actor_hp_before": hp, "actor_hp_after": actor.hp, "actions_exact": _route_exact(actions), "complete": false}
	if not _expect(hits == 1 and actions.size() == 1 and actions[0].kind == "primary" and actions[0].origin == "player_direct" and actions[0].hits == 1 and actor.hp == 0.0 and actor.dead and game.player.shells >= shells, "one actual ordinary primary hits the stopped C30 without blast or ammo expenditure"): return
	if not await _route_wait(func() -> bool: return game.player.get_threat_response_state().stable and float(game.player.get_threat_response_state().commitment_remaining_s) == 0.0, "actual ordinary commitment finishes inside original host recovery", float(host.recovery_until_s), 4.0): return
	route_result.primary["completed_s"] = _scheduler().get_clock(); route_result.primary["complete"] = true
	if not _expect(_scheduler().get_clock() < float(host.recovery_until_s) and route_result.actions.size() == 4 and game.active_level.get("collected_ids") == ["nose-cap", "rivet-band"] and game.active_level.get("stage") == "circuit" and not game.active_level.get("checkpoint_published") and game.player.hp == 100.0 and route_result.hits.is_empty(), "complete useful four-full-dash east-second route finishes original ordinary recovery before third contact and without any native source-hit opportunity"): return
	route_step = "final-save"
	_route_boundary(199, true); _route_boundary(3000, true)
	if not await _pause("complete old east-second ordinary response") or not await _difficulty_settled("old route final Save"): return
	var final_unit: Dictionary = game.capture_campaign_snapshot()
	route_result["final_saved_unit_exact"] = Exact.stringify(final_unit); route_result["final_attempts_exact"] = Exact.stringify(game.attempts.state())
	if not _expect(_legacy_unit(final_unit) and not route_result.final_saved_unit_exact.is_empty() and _same(game.attempts.state().side_attempt.checkpoint, Exact.parse(route_row.checkpoint_exact).value) and _same(game.attempts.state().story, protected_story) and _durable(), "normal final route Save retains original earlier checkpoint and protected Story"): return
	route_result["complete"] = true


func _route_load_inputs() -> bool:
	var path: String = route_options["source-producer-report"]
	if not _expect(FileAccess.get_sha256(path) == ROUTE_PRODUCER_SHA, "actual complete102 original producer report is byte pinned"): return false
	var producer: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not _expect(producer is Dictionary and producer.get("case") == "legacy-producer" and producer.get("checks") == 102 and producer.get("failures") == 0 and producer.get("complete") == true and producer.get("success") == true and producer.get("branch_order") == DIFFICULTY_BRANCHES and producer.get("source_pre") == producer.get("source_post") and producer.source_pre.get("res://tests/acts/act1/a1_o1_difficulty.gd") == ROUTE_PRODUCER_FIXTURE_SHA, "closed genuine original writer and branch source attribution retained"): return false
	route_row = producer.branches["one-part-live"].duplicate(true)
	branches["one-part-live"] = route_row.duplicate(true)
	route_result["input_producer"] = {"path": path, "sha256": ROUTE_PRODUCER_SHA, "scope": producer.scope, "branch": "one-part-live", "original_fixture_sha256": ROUTE_PRODUCER_FIXTURE_SHA}
	for key: String in ["current", "checkpoint", "attempts", "protected_story"]:
		var wire: String = route_row[key + "_exact"]; var answer: Dictionary = Exact.parse(wire)
		if not _expect(not wire.is_empty() and wire.sha256_text() == route_row[key + "_sha256"] and answer.get("accepted", false) and Exact.stringify(answer.value) == wire, "original complete input wire: " + key): return false
	route_original = Exact.parse(route_row.current_exact).value
	var attempts: Dictionary = Exact.parse(route_row.attempts_exact).value
	var checkpoint: Dictionary = Exact.parse(route_row.checkpoint_exact).value
	protected_story = Exact.parse(route_row.protected_story_exact).value
	if not _expect(_legacy_unit(route_original) and _legacy_unit(checkpoint) and route_row.complete and route_row.generation == 4 and route_original.level.local.stage == "circuit" and route_original.level.local.collected_ids == ["nose-cap"] and route_original.level.local.scheduler.profile.id == "challenge" and route_original.shell.difficulty_at_entry == "challenge" and _same(attempts.side_attempt.snapshot, route_original) and _same(attempts.side_attempt.checkpoint, checkpoint) and _same(attempts.story, protected_story) and attempts.completed_optional.is_empty() and attempts.reward_ids.is_empty(), "literal original one-part Challenge current, independent entrance and whole protected Story/Attempts join"): return false
	if not _expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(test_root)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_root)) == OK, "new isolated consumer store directory"): return false
	var inputs: Dictionary = {"campaign.json": "source-branch-store", "campaign.json.bak": "source-backup-store", "preferences.json": "source-preferences-store"}
	if not _expect(route_row.all_original_disk_files.size() == 3 and not route_row.original_disk_presence["settings.json"] and not route_row.original_disk_presence["settings.json.bak"] and not route_row.original_disk_presence["preferences.json.bak"], "all actual original companion presence/absence is retained"): return false
	for name: String in inputs:
		var source: String = route_options[inputs[name]]; var item: Dictionary = route_row.all_original_disk_files[name]
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(source)
		if not _expect(bytes.size() == int(item.bytes) and bytes.hex_encode() == item.hex and _difficulty_bytes_sha256(bytes) == item.sha256, "explicit original raw bytes join sealed report: " + name): return false
		if not _expect(DirAccess.copy_absolute(ProjectSettings.globalize_path(source), ProjectSettings.globalize_path(test_root + name)) == OK and FileAccess.get_file_as_bytes(test_root + name) == bytes, "literal whole file copied to fresh consumer: " + name): return false
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(test_root + "campaign.json"))
	if not _expect(envelope is Dictionary and envelope.get("format_version") == 2 and envelope.get("payload_json") == route_row.attempts_exact and envelope.get("sha256") == route_row.attempts_sha256, "copied actual Store envelope retains complete original payload"): return false
	raw = {} # Actual accepted canonical Registry; no synthetic saved attempt or row override.
	return true


func _route_control(id: String) -> Dictionary:
	var actor: Node3D = _impact() if id == Layout.IMPACT_ID else _source(id)
	return _scheduler().source_control_state(actor)


func _route_current_lease(id: String) -> Dictionary:
	var rows: Array = _route_control(id).get("reservations", [])
	return rows[0] if rows.size() == 1 else {}


func _route_native() -> Dictionary:
	return {"clock_s": _scheduler().get_clock(), "action_clock_s": game.player.get_world_action_clock(), "hero_position": _route_encode(game.player.global_position), "hero_velocity": _route_encode(game.player.velocity), "response": _route_encode(game.player.get_threat_response_state()), "hp": game.player.hp, "shells": game.player.shells, "circuit_control": _route_encode(_route_control(Layout.CIRCUIT_SOURCE_ID)), "impact_control": _route_encode(_route_control(Layout.IMPACT_ID)), "circuit_position": _route_encode(_source(Layout.CIRCUIT_SOURCE_ID).global_position), "circuit_velocity": _route_encode(_source(Layout.CIRCUIT_SOURCE_ID).velocity), "circuit_hp": _source(Layout.CIRCUIT_SOURCE_ID).hp, "collected": (game.active_level.get("collected_ids") as Array).duplicate(), "stage": game.active_level.get("stage"), "encounter_error": game.active_level.get("last_encounter_error")}


func _route_integrity() -> bool:
	if not _live(Layout.LEVEL_ID) or paused or finishing:
		if route_fault.is_empty(): route_fault = "live optional simulation lost or paused"
		return false
	if not route_fault.is_empty(): return false
	if game.player.hp != 100.0 or game.player.dead or not route_result.hits.is_empty(): route_fault = "native source hit/opportunity or Hero resource loss"; return false
	if game.active_level.get("stage") != "circuit" or game.active_level.get("checkpoint_published") or game.active_level.get("final_started"): route_fault = "third contact or final boundary occurred"; return false
	var parts_now: Array = game.active_level.get("collected_ids")
	if parts_now != ["nose-cap"] and parts_now != ["nose-cap", "rivet-band"]: route_fault = "unexpected actual contact order"; return false
	if absf((_scheduler().get_clock() - game.player.get_world_action_clock()) - route_clock_offset) > 0.000001: route_fault = "actual Player/Scheduler clock offset changed"; return false
	if _scheduler().get_clock() >= float(route_leases[Layout.CIRCUIT_SOURCE_ID].recovery_until_s): route_fault = "original host recovery deadline missed"; return false
	if route_primary_started: return true
	for id: String in [Layout.CIRCUIT_SOURCE_ID, Layout.IMPACT_ID]:
		var current: Dictionary = _route_current_lease(id); var original: Dictionary = route_leases[id]
		if current.is_empty() or current.id != original.id or current.start_s != original.start_s or current.active_from_s != original.active_from_s or current.active_until_s != original.active_until_s or current.recovery_until_s != original.recovery_until_s: route_fault = "original lease cancelled, expired or replaced: " + id; return false
	return true


func _route_wait(predicate: Callable, label: String, native_deadline: float, wall_seconds: float) -> bool:
	var until: int = Time.get_ticks_msec() + int(wall_seconds * 1000.0)
	while not finishing and Time.get_ticks_msec() <= until:
		if not _route_integrity(): return _expect(false, "old route stopped: " + label + "; " + route_fault)
		if _scheduler().get_clock() > native_deadline: return _expect(false, "original native deadline exceeded: " + label)
		if predicate.call() == true: return true
		await process_frame
	return _expect(false, "bounded wall observation ended: " + label)


func _route_dash(direction: Vector3, landing: Vector3, label: String) -> bool:
	route_step = label
	if not await _route_wait(_dash_ready, label + " native readiness", float(route_leases[Layout.CIRCUIT_SOURCE_ID].recovery_until_s), 8.0): return false
	var response: Dictionary = game.player.get_threat_response_state()
	if not _expect(float(response.stats.dash_distance) == 2.7 and is_equal_approx(float(response.stats.dash_speed) * float(response.stats.dash_duration), 2.7), "unchanged original full2.7 dash kit: " + label): return false
	var sequence: int = _last_sequence(); var origin: Vector3 = game.player.global_position; var began: float = _scheduler().get_clock()
	if not _expect(game.player.request_dash(direction), "actual ready public full dash accepted: " + label): return false
	if not await _route_wait(func() -> bool: return not game.player.get_committed_dash_state().get("active", false) and game.player.get_threat_response_state().stable, label + " native deliberate stop", float(route_leases[Layout.CIRCUIT_SOURCE_ID].recovery_until_s), 8.0): return false
	var actions: Array[Dictionary] = game.player.get_world_action_records(sequence)
	var row: Dictionary = {"label": label, "started_s": began, "stopped_s": _scheduler().get_clock(), "origin": _route_encode(origin), "expected_landing": _route_encode(landing), "actual_landing": _route_encode(game.player.global_position), "actions_exact": _route_exact(actions)}
	route_result.actions.append(row)
	var distance: float = Vector2(game.player.global_position.x - landing.x, game.player.global_position.z - landing.z).length()
	return _expect(actions.size() == 1 and actions[0].kind == "dash" and actions[0].origin == "player_direct" and actions[0].direction == direction and not actions[0].collision_shortened and not actions[0].blocked and distance <= LANDING_PHYSICAL_BOUND, "actual unshortened complete2.7 dash and supported measured endpoint: " + label)


func _route_timed_safe(segment: Dictionary) -> bool:
	var path: Array[Dictionary] = [segment]
	for record: Dictionary in route_leases.values():
		if maxf(float(segment.start_s), float(record.active_from_s)) > minf(float(segment.end_s), float(record.active_until_s)): continue
		# Conservative native leased lane for C30; real source-hit events remain authoritative.
		if RouteGeometry.timed_path_hits(record.geometry, path, float(record.active_from_s), float(record.active_until_s), Scheduler.CAPSULE_RADIUS): return false
	return true


func _route_observe(priority: int) -> void:
	if not route_observing or finishing or not _live(Layout.LEVEL_ID): return
	if priority == 3000:
		var sample: Dictionary = {"step": route_step, "clock_s": _scheduler().get_clock(), "action_clock_s": game.player.get_world_action_clock(), "hero": _route_encode(game.player.global_position), "source": _route_encode(_source(Layout.CIRCUIT_SOURCE_ID).global_position), "hp": game.player.hp, "supported": game.player.get_threat_response_state().motion.grounded}
		if route_result.trace.size() < 2400: route_result.trace.append(sample)
		else:
			route_result.trace_omitted += 1
			if route_fault.is_empty(): route_fault = "bounded complete route trace exhausted"
		_route_consume_events()
	_route_boundary(priority, false)


func _route_consume_events() -> void:
	while route_observation_cursor < observations.size():
		var event: Dictionary = observations[route_observation_cursor]; route_observation_cursor += 1
		if event.level_instance_id != str(game.active_level.get_instance_id()): continue
		if event.kind == "part": route_result.contacts.append(event.duplicate(true))
		if event.kind == "source-hit": route_result.hits.append(event.duplicate(true)); route_fault = "native source-hit opportunity consumed even if HP damage is zero"
		if event.kind == "reservation-invalidated":
			route_result.cancellations.append(event.duplicate(true))
			var expected: bool = route_primary_started and ((event.value.id == route_leases[Layout.CIRCUIT_SOURCE_ID].id and event.value.reason == "actual_player_damage") or (event.value.id == route_leases[Layout.IMPACT_ID].id and event.value.reason == "circuit_source_defeated"))
			if not expected and route_fault.is_empty(): route_fault = "native reservation cancellation: " + str(event.value)


func _route_boundary(priority: int, force: bool) -> void:
	var now: float = _scheduler().get_clock(); var key: String = str(priority)
	var prior: Dictionary = route_last_boundary.get(key, {})
	var marker: String = route_step + "/" + route_fault
	if not force and prior.get("marker") == marker and now - float(prior.get("clock_s", -1.0)) < 0.1: return
	route_last_boundary[key] = {"marker": marker, "clock_s": now}
	var current: Array = game.active_level.call("_camera_framing_points", false)
	var forecast: Array = game.active_level.call("_camera_framing_points", true)
	var desired: Vector3 = game.player.global_position + Vector3.UP * 0.65
	var camera: Camera3D = game.camera
	var row: Dictionary = {"priority": priority, "ordering": "after native100; before parent200" if priority == 199 else "after native100 and parent200", "exact_rejected_callback_claim": false, "camera_render_update_order": "physics observers do not imply the next _process camera/HUD update has run", "step": route_step, "fault": route_fault, "clock_s": now, "current_points": current, "forecast_inclusive_points": forecast, "current_plan": game.camera_framing_plan(current, desired), "current_containment": game.camera_framing_error(current), "forecast_plan": game.camera_framing_plan(forecast, desired), "forecast_containment": game.camera_framing_error(forecast), "plan_spec": game.call("_camera_framing_spec", 0.055), "containment_spec": game.call("_camera_framing_spec", 0.02), "camera_transform": camera.global_transform, "camera_size": camera.size, "camera_projection": camera.projection, "camera_keep_aspect": camera.keep_aspect, "camera_offsets": [camera.h_offset, camera.v_offset], "camera_cull_mask": camera.cull_mask, "mandatory_player_points": game.player_camera_framing_points(), "retained_forecast": (game.active_level.get("_forecast") as Array).duplicate(), "forecast_hero": game.active_level.get("_forecast_hero"), "impact_host": (game.active_level.get("_impact_host") as Dictionary).duplicate(true), "frames": (game.active_level.get("_frames") as Dictionary).duplicate(true), "pending": (game.active_level.get("_pending_start") as Dictionary).duplicate(true), "native": _route_native()}
	var wire: String = _route_exact(row)
	if wire.is_empty() and route_fault.is_empty(): route_fault = "complete passive exact witness serialization refused"
	route_result.boundaries.append({"priority": priority, "step": route_step, "clock_s": now, "exact": wire, "sha256": wire.sha256_text()})
	if route_result.boundaries.size() > 24: route_result.boundaries.pop_front(); route_result.boundary_omitted += 1


func _route_encode(value: Variant) -> Variant:
	if value is float and not is_finite(value): return {"native_type": "nonfinite_float", "value": "nan" if is_nan(value) else ("+inf" if value > 0.0 else "-inf")}
	if value is Vector2: return [_route_encode(value.x), _route_encode(value.y)]
	if value is Vector3: return [_route_encode(value.x), _route_encode(value.y), _route_encode(value.z)]
	if value is Color: return [_route_encode(value.r), _route_encode(value.g), _route_encode(value.b), _route_encode(value.a)]
	if value is Basis: return {"x": _route_encode(value.x), "y": _route_encode(value.y), "z": _route_encode(value.z)}
	if value is Transform3D: return {"basis": _route_encode(value.basis), "origin": _route_encode(value.origin)}
	if value is Rect2: return {"native_type": "Rect2", "position": _route_encode(value.position), "size": _route_encode(value.size)}
	if value is Object: return {"native_type": value.get_class(), "instance_id": str(value.get_instance_id())} if is_instance_valid(value) else null
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _route_encode(value[key])
		return result
	if value is Array:
		var result: Array = []
		for child: Variant in value: result.append(_route_encode(child))
		return result
	return _encode(value)


func _route_exact(value: Variant) -> String:
	var wire: String = Exact.stringify(_route_encode(value))
	var parsed: Dictionary = Exact.parse(wire)
	return wire if not wire.is_empty() and parsed.get("accepted", false) and Exact.stringify(parsed.value) == wire else ""


func _route_stop_observers() -> void:
	if difficulty_case != "old-east-second": return
	if route_observing and _live(Layout.LEVEL_ID):
		_route_consume_events(); _route_boundary(199, true); _route_boundary(3000, true)
		route_result["last_native"] = _route_native()
		route_result["pending_dash_exact"] = _route_exact(game.player.get_committed_dash_state())
		route_result["pending_world_action_exact"] = _route_exact(game.player.get("_world_dash_record"))
		route_result["fault"] = route_fault
	route_observing = false
	for observer: Node in route_observers:
		if is_instance_valid(observer): observer.free()
	route_observers.clear()
	for path: String in route_input_hashes:
		_expect(FileAccess.get_sha256(path) == route_input_hashes[path], "original source input bytes remain unchanged: " + path)


func _observe_added(node: Node) -> void:
	super._observe_added(node)
	if difficulty_case == "old-east-second" and node.get_script() in [Rush, Lane]:
		var ref: WeakRef = weakref(node)
		node.connect("hit_resolved", func(id: String, cycle: int, value: Dictionary) -> void: _record("source-hit", ref, {"hero_id": id, "cycle": cycle, "result": value}))


func _diagnostic() -> Dictionary:
	if difficulty_case != "old-east-second": return super._diagnostic()
	var result: Dictionary = {"operation": operation, "step": route_step, "fault": route_fault, "paused": paused, "elapsed_ms": Time.get_ticks_msec() - started_ms, "last_boundaries": route_result.boundaries.duplicate(true)}
	if _live(Layout.LEVEL_ID): result["native"] = _route_native()
	return result


func _record(kind: String, ref: WeakRef, value: Dictionary) -> void:
	super._record(kind, ref, value)
	if difficulty_case != "old-east-second" or not _live(Layout.LEVEL_ID) or observations.is_empty(): return
	var event: Dictionary = observations[-1]
	if event.level_instance_id != str(game.active_level.get_instance_id()): return
	event["route_stamp"] = {"step": route_step, "clock_s": _scheduler().get_clock(), "action_clock_s": game.player.get_world_action_clock(), "hero_position": _route_encode(game.player.global_position), "committed_dash": _route_encode(game.player.get_committed_dash_state())}
