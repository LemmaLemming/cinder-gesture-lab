extends "res://tests/acts/act3/irontick_reflection_optional_shell.gd"
## Root canonical focused registration; actual execution is recorded separately.
## Exact final owner handoff is reviewed separately from this short native seam.
## Overrides _run: no inherited held/driver/checkpoint/completion/contact/Replay route.
## Canonical default Registry and Shell. Only disclosed TEST predecessor prefix13
## surrounds a real paused accepted A3-L3 Story donor. No native pose/HP/history edits.
## Public menu signals are API wiring evidence, not OS clicks or a playthrough.
## Owner CP1/CP2/completion/Replay/visual evidence must be reused separately.

const ACCEPTED_CONTENT: String = "b92a56556c8fdce4f32be9c2b379aa73c2f8e243"
const SHORT_REWARD_ID: String = "A3-O3-completion-stamp"
# SOURCE-ONLY proposal: 600s finite ceiling, not a promised runtime or native
# deadline change. Existing original initial held transport took 272.991s; CP1
# whole job 511.411s; CP2 public Pause alone 140.319s. Thus 120s is not supported
# by measured O3 costs. This zero-gameplay seam still has uncertain wall cost.
const SHORT_WATCHDOG_S: float = 600.0
const SHORT_PATHS: Array[String] = [
	"res://tests/acts/act3/irontick_reflection_optional_shell.gd",
	"res://tests/acts/act3/pillars_before_time_optional_shell.gd",
	"res://scripts/acts/act3/irontick_reflection.gd",
	"res://scripts/acts/act3/irontick_reflection_codec.gd",
	"res://data/campaign/act3/a3_o3_encounters.json",
	"res://scenes/acts/act3/a3_o3_irontick_reflection.tscn",
	"res://scenes/acts/act3/a3_l3_mirror_sea.tscn",
	"res://scenes/main.tscn", "res://scenes/player.tscn",
	"res://scripts/game.gd", "res://scripts/player.gd", "res://scripts/hud.gd",
	"res://scripts/equipment.gd", "res://scripts/campaign/shell.gd",
	"res://scripts/campaign/level.gd", "res://scripts/campaign/registry.gd",
	"res://scripts/campaign/attempts.gd", "res://scripts/campaign/save_store.gd",
	"res://scripts/campaign/exact_json.gd", "res://scripts/campaign/snapshot_codec.gd",
	"res://scripts/ui/campaign_menu.gd", "res://data/campaign/registry.json"
]
var _short_complete: bool = false
var _short_rows: Array[Dictionary] = []
var _short_first_failure: Dictionary = {}
var _short_initial: Dictionary = {}
var _short_receipts: Array[Dictionary] = []
var _short_sources_before: Dictionary = {}
var _short_report_path: String = ""
var _short_started_us: int = 0
var _short_operation: String = "initialize"
var _short_start_stats: PackedByteArray

func _initialize() -> void:
	_short_started_us = Time.get_ticks_usec()
	isolated = "user://test-a3-o3-canonical-%d-%d/" % [OS.get_process_id(), _short_started_us]
	old_audio = AudioServer.generate_bus_layout()
	old_fps = Engine.max_fps
	_short_report_path = OS.get_environment("CINDER_A3_O3_SHORT_REGISTRATION_REPORT")
	if _short_report_path.is_empty():
		_short_report_path = "user://test-a3-o3-short-registration-reports/%d-%d.json" % [OS.get_process_id(), _short_started_us]
	_run.call_deferred()

func _run() -> void:
	create_timer(SHORT_WATCHDOG_S, true, false, true).timeout.connect(func() -> void:
		if not finished:
			_expect(false, "finite canonical O3 registration host watchdog", _short_operation)
			_finish.call_deferred())
	root.size = Vector2i(340, 736)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	canonical_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	node_added.connect(_watch_node)
	_short_sources_before = _short_sources()
	if not _expect(DisplayServer.get_name() == "headless" and OS.get_cmdline_user_args().is_empty(), "canonical boundary is explicit headless with no route/archive/completion/Replay/skip selector"):
		await _finish(); return
	var canonical: CinderCampaignRegistry = Registry.new()
	var row: Dictionary = canonical.entry("A3-O3")
	if not _expect(ACCEPTED_CONTENT.length() == 40 and not ACCEPTED_CONTENT.contains("PLACEHOLDER") and canonical.last_error.is_empty() and canonical.ids().size() == 24 and row.get("readiness") == "accepted" and row.get("accepted_commit") == ACCEPTED_CONTENT and row.get("scene_path") == O3_PATH and row.get("api_revision") == Registry.API_REVISION and canonical.scene_error("A3-O3").is_empty(), "actual canonical final O3 content/scene/API validates without injected readiness"):
		await _finish(); return
	if not _expect(row.get("parent_level_id") == O3_STORY_ID and canonical.entry(O3_STORY_ID).get("readiness") == "accepted" and not canonical.is_unlocked("A3-O3", []) and not canonical.is_unlocked("A3-O3", ["A3-L2"]) and canonical.is_unlocked("A3-O3", [O3_STORY_ID]), "accepted canonical A3-L3 alone unlocks O3"):
		await _finish(); return
	if not _expect(row.get("reward_id") == SHORT_REWARD_ID and row.get("reward_policy") == "once_only_completion_stamp_no_stat_growth" and canonical.next_main(O3_STORY_ID) == "A3-L4", "O3 once-only optional stamp stays outside unchanged L3-to-L4 main route"):
		await _finish(); return
	_short_operation = "real accepted A3-L3 Story donor and TEST prefix13"
	if not await _seed_story(canonical): await _finish(); return
	var model: CinderCampaignAttempts = Attempts.new(canonical)
	if not _expect(model.state_error(expected_session).is_empty() and expected_session.side_attempt == null and expected_session.story.level_id == O3_STORY_ID and _same(expected_session.story.snapshot, protected) and _same(expected_session.story.checkpoint, protected) and expected_session.completed_main == canonical.main_route().slice(0, 13) and expected_session.completed_optional.is_empty() and expected_session.reward_ids.is_empty(), "whole native protected A3-L3 Story/session closes; only predecessor prefix13 is TEST") or not _disk(expected_session):
		await _finish(); return
	_short_initial = {"exact_whole_story": Exact.stringify(expected_session.story), "exact_session": Exact.stringify(expected_session), "initial_campaign_disk": _short_disk_observation(), "test_context": "actual pristine accepted A3-L3 native donor; TEST completed-main prefix13 only"}
	if not await _new_shell(expected_session): await _finish(); return
	_short_operation = "canonical public protected Story Continue"
	production.menu.continue_story_requested.emit()
	if not await _wait_installed(O3_STORY_ID, "resume", protected) or not _installed(protected) or not _disk(expected_session) or not await _short_quiet("initial protected A3-L3"):
		await _finish(); return
	_short_start_stats = var_to_bytes(production.player.stats)
	var refs: Array[WeakRef] = []
	_collect_refs(_world_container(), refs)
	var before: Dictionary = _core_ids()
	_short_operation = "canonical public O3 Optional entry"
	production.menu.optional_requested.emit("A3-O3")
	if not await _wait_installed("A3-O3", "resume", {}, before): await _finish(); return
	_entrance = production.capture_campaign_snapshot()
	if not _installed(_entrance) or not _distinct(before) or not _expect(_short_pristine(_entrance) and production.attempts.active_kind() == "optional" and _same(production.attempts.state().story, expected_session.story) and _same(production.attempts.state().side_attempt.checkpoint, _entrance), "canonical pristine O3 native entrance protects whole Story and entrance checkpoint") or not await _released(refs, "canonical Optional frees entire native Story world") or not _disk(production.attempts.state()) or not await _short_quiet("pristine canonical O3 entrance"):
		await _finish(); return
	# Only native contact refusal; calling the generic request_completion here
	# would itself manufacture completion, so it is intentionally not invoked.
	var before_refusal: Dictionary = production.attempts.state()
	if not _expect(not production.active_level.request_contact_exit(O3.EXIT_ID, production.player) and _same(production.capture_campaign_snapshot(), _entrance) and _same(production.attempts.state(), before_refusal), "premature contact refuses atomically without earned completion or stamp") or not _disk(before_refusal):
		await _finish(); return
	_short_record("canonical entrance", _entrance)
	# Entrance Retry only. Owner's genuinely earned CP1/CP2 Retry is reused.
	refs.clear(); _collect_refs(_world_container(), refs)
	before = _native_ids()
	var expected_before_retry: Dictionary = production.attempts.state()
	var disk_before_retry: Dictionary = _short_disk_observation()
	receiver_events.clear()
	_short_operation = "canonical public entrance Retry"
	production.menu.retry_requested.emit()
	if not await _wait_installed("A3-O3", "resume", _entrance, before) or not _installed(_entrance) or not _distinct(before) or not await _released(refs, "canonical entrance Retry frees every retired native descendant") or not _expect(_short_pristine(production.capture_campaign_snapshot()) and _same(production.attempts.state(), expected_before_retry) and _same(production.attempts.state().side_attempt.checkpoint, _entrance), "public entrance Retry retains whole session/Story/entrance checkpoint") or not _disk(production.attempts.state()) or not _short_generation_advance(disk_before_retry, "entrance Retry") or not await _short_quiet("canonical entrance Retry recipient"):
		await _finish(); return
	_short_record("canonical entrance Retry", _entrance)
	# Already paused: a public Pause operation records the actual unit without
	# introducing a Resume/gameplay frame or any fabricated action history.
	var before_save: Dictionary = _short_disk_observation()
	_short_operation = "canonical public paused entrance Save"
	production.request_pause()
	if not await _wait_pause() or not _expect(_same(production.capture_campaign_snapshot(), _entrance) and _same(production.attempts.state().story, expected_session.story), "public Pause Save preserves exact pristine unit and whole Story") or not _disk(production.attempts.state()) or not _short_generation_advance(before_save, "public Pause Save"):
		await _finish(); return
	var saved: Dictionary = production.capture_campaign_snapshot()
	var saved_session: Dictionary = production.attempts.state()
	var saved_disk: Dictionary = _short_disk_observation()
	var donor_ids: Dictionary = _native_ids()
	_short_record("public entrance Save", saved)
	_short_operation = "normal donor Shell retirement before fresh disk recipient"
	if not await _dispose_shell() or not await _new_shell(saved_session): await _finish(); return
	if not _expect(_short_disk_observation() == saved_disk, "fresh whole-session Title preserves primary/backup bytes and generation"):
		await _finish(); return
	_short_operation = "fresh Title public active-side disk Continue"
	production.menu.resume_requested.emit()
	if not await _wait_installed("A3-O3", "resume", saved) or not _installed(saved) or not _distinct(donor_ids) or not _expect(_same(production.attempts.state(), saved_session) and _same(production.attempts.state().story, expected_session.story) and _short_disk_observation() == saved_disk, "independent fresh disk Continue restores entire side unit/session/Story with primary+backup/generation exact") or not _disk(saved_session) or not await _short_quiet("fresh canonical disk Continue recipient"):
		await _finish(); return
	_short_record("fresh Title active-side disk Continue", saved)
	refs.clear(); _collect_refs(_world_container(), refs)
	before = _core_ids()
	var before_leave: Dictionary = _short_disk_observation()
	receiver_events.clear()
	_short_operation = "canonical early public Leave Side"
	production.menu.leave_side_requested.emit()
	if not await _wait_installed(O3_STORY_ID, "journey", protected, before) or not _installed(protected) or not _distinct(before) or not await _released(refs, "early Leave frees entire Optional native world"):
		await _finish(); return
	var returned: Dictionary = production.attempts.state()
	if not _expect(returned.side_attempt == null and _same(returned, expected_session) and _same(returned.story, expected_session.story) and returned.completed_optional.is_empty() and returned.reward_ids.is_empty() and returned.unlocked_equipment == expected_session.unlocked_equipment and var_to_bytes(production.player.stats) == _short_start_stats, "early Leave restores complete initial Story/session/main/equipment/stats with no stamp or growth") or not _disk(returned) or not _short_generation_advance(before_leave, "early Leave Side") or not await _short_quiet("returned canonical protected Story"):
		await _finish(); return
	_short_record("early Leave returns protected Story", protected)
	_short_complete = true
	await _finish()

func _seed_story(registry: CinderCampaignRegistry) -> bool:
	# Explicit O3 constants avoid the ancestor's A3-L2/O1 fallback entirely.
	paused = true
	preview = MainScene.instantiate()
	preview.set("level_scene_path", O3_STORY_PATH)
	root.add_child(preview)
	preview.call("open_bench")
	var actor: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var camera: Camera3D = preview.get("camera") as Camera3D
	if not _expect(actor != null and level != null and camera != null and level.level_id == O3_STORY_ID and String(preview.get("level_load_error")).is_empty(), "actual accepted A3-L3 Main constructs real protected donor"):
		return false
	await process_frame
	var actor_state: Dictionary = actor.snapshot_state()
	var local_state: Dictionary = level.snapshot_state()
	var input: Dictionary = preview.call("get_input_observation_state")
	if not _expect(paused and not actor_state.is_empty() and not local_state.is_empty() and actor.get_world_action_records().is_empty() and input.sequence == 0 and input.last_observation.is_empty(), "real paused donor writers contain no fabricated gameplay/action/input", actor.last_snapshot_error + "; " + level.last_snapshot_error):
		return false
	var anchor: Vector2 = input.anchor_normalized
	var fresh_shell: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": input.sequence, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Game.CAMERA_OFFSET), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}
	protected = {"schema_version": 1, "level_id": O3_STORY_ID, "scene_path": O3_STORY_PATH, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": actor_state, "level": local_state, "shell": fresh_shell}
	var detached: CinderCampaignAttempts = Attempts.new(registry)
	expected_session = detached.state()
	expected_session.completed_main = registry.main_route().slice(0, 13)
	expected_session.story = {"kind": "story", "level_id": O3_STORY_ID, "snapshot": protected.duplicate(true), "checkpoint": protected.duplicate(true)}
	var writer: CinderSaveStore = Store.new(isolated + "campaign.json")
	writer.payload_validator = detached.saved_payload_error
	if not _expect(detached.state_error(expected_session).is_empty() and expected_session.completed_main[-1] == O3_STORY_ID and writer.write_payload(expected_session), "native Attempts/format2 Store writes whole actual Story with TEST prefix13 only", detached.last_error + "; " + writer.last_error):
		return false
	var refs: Array[WeakRef] = []
	_collect_refs(preview, refs)
	level.exit_level()
	preview.queue_free(); preview = null
	return await _released(refs, "normal whole native Story donor retirement") and _disk(expected_session)

func _new_shell(expected: Dictionary) -> bool:
	_short_operation = "fresh canonical whole-session disk Title"
	receiver_events.clear(); watched.clear()
	production = Shell.new()
	if not _expect(production.configure_runtime({}, isolated + "campaign.json", isolated + "settings.json", isolated + "preferences.json"), "actual Shell uses canonical default Registry and isolated stores", production.campaign_error): return false
	root.add_child(production)
	for _frame: int in range(FRAME_LIMIT):
		await process_frame
		if not _valid_shell(): return false
		if paused and not production.is_pause_requested() and production.menu.page_name() == "title" and production.player == null and production.active_level == null and _same(production.attempts.state(), expected):
			return _expect(true, "fresh canonical Title settles entire exact disk session before public load") and _disk(expected)
	return _expect(false, "bounded canonical whole-session Title startup", production.campaign_error)

func _native_ids() -> Dictionary:
	if production.active_level.level_id == "A3-O3":
		return super._native_ids()
	# Explicit accepted A3-L3 branch: never call O3's source alias against Story,
	# nor the deeper ancestor's stale O1 SOURCE constant.
	var result: Dictionary = _core_ids()
	var level: CinderLevel = production.active_level
	var sources: Dictionary = level.get("sources")
	for id: String in sources:
		var source: Node = sources[id] as Node
		result["source/" + id] = source.get_instance_id()
		if source.has_method("get_authored_echo_renderer"):
			var renderer: Node = source.call("get_authored_echo_renderer") as Node
			if is_instance_valid(renderer): result["renderer/" + id] = renderer.get_instance_id()
	for property: String in ["threat_scheduler", "mechanism", "scenery", "vignettes", "exit_cue"]:
		var node: Node = level.get(property) as Node
		if is_instance_valid(node): result[property] = node.get_instance_id()
	var bindings: Dictionary = level.call("scheduler_bindings")
	for id: String in bindings.owners:
		result["owner/" + id] = (bindings.owners[id] as Node).get_instance_id()
	for id: String in bindings.floors:
		var collision: CollisionShape3D = bindings.floors[id].collision
		result["collision/" + id] = collision.get_instance_id()
		result["floor/" + id] = collision.get_parent().get_instance_id()
	return result

func _short_pristine(packet: Dictionary) -> bool:
	var state: Dictionary = production.active_level.call("state")
	return production.active_level.get_script() == O3 and packet.level_id == "A3-O3" and packet.level.local_snapshot_version == O3.LOCAL_VERSION and state.api_revision == O3.API and state.prototype == false and state.sources.size() == 4 and state.route.active_stage == 0 and state.route.clears.is_empty() and state.route.deaths.is_empty() and state.route.contact.is_empty() and state.route.exit_state == "clear" and not state.completed and packet.level.progress.checkpoint_ids.is_empty() and packet.level.progress.completion_id.is_empty() and packet.level.progress.contact_exit_id.is_empty() and production.player.get_world_action_records().is_empty()

func _disk(expected: Dictionary) -> bool:
	var reader: CinderSaveStore = Store.new(isolated + "campaign.json")
	var actual: Dictionary = reader.read_payload()
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(isolated + "campaign.json"))
	return _expect(reader.last_error.is_empty() and not reader.loaded_backup and envelope is Dictionary and envelope.get("format_version") == 2 and envelope.get("payload_json") is String and envelope.payload_json == Exact.stringify(expected) and envelope.payload_json.sha256_text() == envelope.get("sha256") and int(envelope.get("generation", 0)) == reader.generation and _same(actual, expected), "native independent format2 Store/checksum/generation joins complete exact session", reader.last_error)

func _short_disk_observation() -> Dictionary:
	var reader: CinderSaveStore = Store.new(isolated + "campaign.json")
	reader.read_payload()
	var result: Dictionary = {"generation": reader.generation, "reader_error": reader.last_error, "loaded_backup": reader.loaded_backup}
	for name: String in ["campaign.json", "campaign.json.bak"]:
		var path: String = isolated + name
		result[name] = {"raw": FileAccess.get_file_as_string(path), "bytes": FileAccess.get_file_as_bytes(path).size(), "sha256": FileAccess.get_sha256(path)} if FileAccess.file_exists(path) else null
	return result

func _short_generation_advance(before: Dictionary, label: String) -> bool:
	var after: Dictionary = _short_disk_observation()
	return _expect(after.reader_error.is_empty() and not after.loaded_backup and int(after.generation) == int(before.generation) + 1 and after["campaign.json.bak"] == before["campaign.json"], "one public Store generation advances with exact prior-primary backup: " + label)

func _short_callbacks() -> Array[Dictionary]:
	var refs: Array[WeakRef] = []
	_collect_refs(production.active_level, refs)
	_collect_refs(production.player, refs)
	var owners: Dictionary = {}
	for ref: WeakRef in refs:
		var node: Node = ref.get_ref() as Node
		if is_instance_valid(node): owners[str(node.get_instance_id())] = true
	var unexpected: Array[Dictionary] = []
	for event: Dictionary in receiver_events:
		if owners.has(event.owner): unexpected.append(event.duplicate(true))
	return unexpected

func _short_quiet(label: String) -> bool:
	var packet: Dictionary = production.capture_campaign_snapshot()
	var session: Dictionary = production.attempts.state()
	var native_ids: Dictionary = _native_ids()
	var disk: Dictionary = _short_disk_observation()
	await process_frame; await process_frame
	if not _valid_shell(): return false
	return _expect(paused and not production.is_pause_requested() and _same(production.capture_campaign_snapshot(), packet) and _same(production.attempts.state(), session) and _same(production.attempts.state().story, expected_session.story) and _native_ids() == native_ids and _short_callbacks().is_empty() and _short_disk_observation() == disk, "two paused frames retain whole unit/session/Story/IDs/raw primary+backup/generation and recipient callback silence: " + label)

func _short_record(label: String, packet: Dictionary) -> void:
	var ids: Dictionary = _native_ids()
	var strings: Dictionary = {}
	var valid: bool = not ids.is_empty()
	for key: String in ids:
		var value: Variant = ids[key]
		valid = valid and value is int and int(value) != 0 and is_instance_id_valid(int(value))
		strings[key] = str(value)
	if not _expect(valid, "all observed native identities are valid nonzero actual ints before decimal-string report: " + label): return
	var session: Dictionary = production.attempts.state()
	var side: Variant = session.side_attempt
	_short_receipts.append({"stage": label, "elapsed_wall_s": float(Time.get_ticks_usec() - _short_started_us) / 1000000.0, "exact_snapshot": Exact.stringify(packet), "exact_session": Exact.stringify(session), "exact_whole_story": Exact.stringify(session.story), "exact_retry_checkpoint": Exact.stringify(side.checkpoint if side is Dictionary else session.story.checkpoint), "campaign_primary_backup_generation": _short_disk_observation(), "actual_native_ids_decimal": strings, "selected_recipient_callbacks": _short_callbacks(), "scope": "canonical public entry/entrance Retry/Save/fresh Title disk Continue/early Leave; TEST predecessor prefix13 only; no route/completion/Replay"})

func _expect(ok: bool, label: String, detail: String = "") -> bool:
	checks += 1
	var row: Dictionary = {"check": checks, "ok": ok, "label": label, "detail": detail, "operation": _short_operation, "elapsed_wall_s": float(Time.get_ticks_usec() - _short_started_us) / 1000000.0}
	_short_rows.append(row)
	if not ok:
		failures += 1
		if _short_first_failure.is_empty(): _short_first_failure = row.duplicate(true)
		push_error("FAIL A3-O3 SHORT canonical registration: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok

func _short_sources() -> Dictionary:
	var result: Dictionary = {}
	for path: String in SHORT_PATHS:
		result[path] = {"present": FileAccess.file_exists(path), "sha256": FileAccess.get_sha256(path)}
	var own: String = String(get_script().resource_path)
	result["executing_fixture"] = {"path": own, "sha256": FileAccess.get_sha256(own), "scope": "actual executing Script; no inferred Git identity"}
	return result

func _finish() -> void:
	if finished: return
	finished = true
	_short_operation = "normal canonical short fixture cleanup"
	await _dispose_shell()
	if is_instance_valid(preview):
		var refs: Array[WeakRef] = []
		_collect_refs(preview, refs)
		var donor: CinderLevel = preview.get("active_level") as CinderLevel
		if donor != null: donor.exit_level()
		preview.queue_free(); preview = null
		await _released(refs, "remaining actual Story donor cleanup")
	if node_added.is_connected(_watch_node): node_added.disconnect(_watch_node)
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty() and get_nodes_in_group("environment_attack_targets").is_empty(), "normal level/Shell disposal frees all enemy/interaction/cue groups")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == canonical_bytes, "canonical Registry remains byte exact")
	_expect(_short_sources() == _short_sources_before, "named source observations stay exact; no full dependency/UID census")
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		var path: String = isolated + name
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(isolated))
	AudioServer.set_bus_layout(old_audio); Engine.max_fps = old_fps
	paused = false
	_write_short_report()
	print("A3-O3 SHORT canonical registration: %d checks/%d failures; complete=%s; actual entry/entrance Retry/Save/fresh Title disk Continue/early Leave/cleanup only. Owner CP1/CP2/completion/Replay and brief visuals are separate reused evidence. No route/earned checkpoint/completion/GUI/portrait/performance credit." % [checks, failures, str(_short_complete)])
	quit(0 if failures == 0 and _short_complete else 1)

func _write_short_report() -> void:
	var directory: String = _short_report_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(directory)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) != OK:
		_expect(false, "short structured row-report directory opens"); return
	var receipts: Array[String] = []
	for receipt: Dictionary in _short_receipts:
		var wire: String = Exact.stringify(receipt)
		if wire.is_empty(): _expect(false, "complete observed receipt remains Exact JSON with IDs as strings"); return
		receipts.append(wire)
	var payload: Dictionary = {"schema_version": 1, "kind": "a3-o3-short-canonical-registration", "accepted_content": ACCEPTED_CONTENT, "checks": checks, "failures": failures, "complete": _short_complete, "success": failures == 0 and _short_complete, "rows": _short_rows, "first_failure": _short_first_failure, "initial_closed_packet_disk": _short_initial, "exact_receipt_strings": receipts, "source_before": _short_sources_before, "source_after": _short_sources(), "watchdog_s": SHORT_WATCHDOG_S, "elapsed_wall_s": float(Time.get_ticks_usec() - _short_started_us) / 1000000.0, "source_scope": "named byte observations only; no complete resource/import/global/UID closure", "executed_scope": "actual canonical Registry metadata/unlock/main-route/stamp policy; real accepted A3-L3 native donor with TEST prefix13 only; public Optional entrance/entrance Retry/Pause Save/fresh whole-session Title/disk active-side Continue/early Leave/no stamp or stat growth; full native Story/session/checkpoint, independent raw primary+backup/generation, actual valid distinct IDs, recipient callback silence and normal cleanup", "owner_evidence_reuse": {"executed_here": false, "required_before_root_selection": "independent exact final owner CP1/CP2/completion/contact/Replay/brief visual evidence reviewed and mapped separately; no completed-session export required"}, "other_credits": "No inherited held/driver/court/route/completion/contact/Replay consumer; no earned checkpoint, human gesture/OS GUI click, visual, all-kit, full-route, campaign-clear, balance/pacing, FPS, mobile or release claim"}
	var file: FileAccess = FileAccess.open(_short_report_path, FileAccess.WRITE)
	if file == null: _expect(false, "short structured row-report file opens", _short_report_path); return
	# Native packets remain opaque Exact strings, not lossy JSON float metadata.
	file.store_string(JSON.stringify(payload, "\t") + "\n"); file.close()
	print("CINDER_A3_O3_SHORT_REGISTRATION_REPORT path=%s sha256=%s" % [_short_report_path, FileAccess.get_sha256(_short_report_path)])
