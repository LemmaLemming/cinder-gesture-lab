extends "res://tests/acts/act3/quiet_root_circuit_optional_shell.gd"
## Producer-only amendment fixture. Run BEFORE promoting the O2 reader.
## Canonical Registry is unmodified. Only TEST completed-main prefix12 is seeded,
## around an actual accepted L2 opening captured from native public writers.
## Public Challenge selection precedes fresh Optional entry; no profile/pose/HP/
## clock/history/death/checkpoint/lease is patched. No court is cleared.

const PRODUCER_PATH: String = "res://tests/acts/act3/quiet_root_circuit_arrangement_smoke.gd"
const FIXTURE_ROOT: String = "res://tests/acts/act3/fixtures/a3_o2_arrangement_legacy"
const AUTHORIZATION_HEAD: String = "18b07006ea514ad9db20fd6a48a4baccfdd30970"
const LEGACY_API: String = "act3-quiet-root-circuit-2"
const LEGACY_KEYS: Array[String] = ["api_revision", "schema_version", "scenery", "scheduler", "sources", "route"]
const FIRST_OWNER: String = "o2-first-root/attack"
const DEADLINES: Array[String] = ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]
const LEGACY_ORIGINS: Dictionary = {
	"o2-first-root": Vector3(0, 0, 4),
	"o2-second-root": Vector3(1.4, 0, -1),
	"o2-final-west-root": Vector3(-1.2, 0, -6),
	"o2-final-east-root": Vector3(1.2, 0, -6),
	"o2-final-stalker": Vector3(0, 0.1, -4.5),
}

var _legacy_entrance: Dictionary = {}
var _original_pins: Dictionary = {}
var _original_uids: Dictionary = {}
var _fixture_files: Dictionary = {}
var _samples: Dictionary = {}
var _started_usec: int = 0

func _initialize() -> void:
	isolated = "user://test-a3-o2-arrangement-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	old_audio = AudioServer.generate_bus_layout()
	old_fps = Engine.max_fps
	_started_usec = Time.get_ticks_usec()
	_run.call_deferred()

func _run() -> void:
	create_timer(1800.0, true, false, true).timeout.connect(func() -> void:
		if not finished:
			_expect(false, "bounded original legacy producer host watchdog")
			_finish())
	root.size = Vector2i(340, 736)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	canonical_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	if not _expect(OS.get_cmdline_user_args() == PackedStringArray(["--produce-legacy"]) and DisplayServer.get_name() == "headless", "only explicit headless --produce-legacy is implemented"):
		await _finish(); return
	if not _expect(QRC.LOCAL_VERSION == 2 and QRC.ROUTE_API == LEGACY_API and QRC.WORLD_REVISION == 1, "producer runs only the original unpromoted outer2/API2/world1 runtime"):
		await _finish(); return
	if not _expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(FIXTURE_ROOT)), "never overwrite a prior original or partial legacy fixture"):
		await _finish(); return
	var parsed: Variant = JSON.parse_string(canonical_bytes)
	if not _expect(parsed is Dictionary, "canonical Registry parses without metadata amendment"):
		await _finish(); return
	raw = parsed
	var registry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A3-O2").is_empty() and registry.entry("A3-O2").parent_level_id == STORY_ID and registry.entry("A3-O2").scene_path == O2_PATH and registry.entry("A3-O2").readiness == "accepted", "actual accepted O2 Registry row/scene/parent are used unchanged", registry.last_error):
		await _finish(); return
	if not _capture_source_pins(): await _finish(); return
	node_added.connect(_watch_node)
	if not await _seed_story(registry) or not await _new_shell(expected_session): await _finish(); return
	# This is the public preference request, not Menu's presentation-only setter.
	var before_preference: String = Exact.stringify(production.attempts.state())
	production.menu.difficulty_preference_requested.emit("challenge")
	var preference_reader = Store.new(isolated + "preferences.json")
	var preference: Dictionary = preference_reader.read_payload()
	if not _expect(production.get_difficulty_preference() == "challenge" and preference_reader.last_error.is_empty() and not preference_reader.loaded_backup and preference == {"schema_version": 1, "profile_id": "challenge"} and before_preference == Exact.stringify(production.attempts.state()), "public Challenge selection persists before fresh Optional without modifying Story/session"):
		await _finish(); return
	production.menu.continue_story_requested.emit()
	if not await _wait_installed(STORY_ID, "resume", protected) or not _installed(protected) or not _quiet_selected(): await _finish(); return
	var old_story_refs: Array[WeakRef] = []
	_collect_refs(_world_container(), old_story_refs)
	var old_story_ids: Dictionary = _core_ids()
	production.menu.optional_requested.emit("A3-O2")
	if not await _wait_installed("A3-O2", "resume", {}, old_story_ids): await _finish(); return
	_legacy_entrance = production.capture_campaign_snapshot()
	checkpoint = production.attempts.state().side_attempt.checkpoint.duplicate(true)
	if not _installed(_legacy_entrance) or not await _released(old_story_refs, "fresh Challenge Optional retires the actual protected Story World"): await _finish(); return
	if not _expect(_same(_legacy_entrance, checkpoint) and _same(production.attempts.state().story, expected_session.story) and production.player.get_world_action_records().is_empty(), "genuine Challenge entry retains protected Story and pristine entrance checkpoint"):
		await _finish(); return
	if not _prepare_fixture() or not _archive_sample("entrance", _legacy_entrance, {}): await _finish(); return
	_phase("actual old Challenge entrance archived")
	if not _o2_bind_live() or not await _resume_after_layout(): await _finish(); return
	if (await _o2_warning(O2_ROOT)).is_empty() or not await _o2_presentation(): await _finish(); return
	production.request_pause()
	if not await _wait_pause(): await _finish(); return
	held = production.capture_campaign_snapshot()
	var receipt: Dictionary = _held_receipt()
	var only_dash_events: bool = true
	for kind: String in _o2_fired:
		if kind != "dash": only_dash_events = false
	var operands: Dictionary = {"receipt_present":not receipt.is_empty(), "only_dash_events":only_dash_events, "checkpoint_exact":_same(production.attempts.state().side_attempt.checkpoint,_legacy_entrance), "current_differs_from_entrance":not _same(held,_legacy_entrance)}
	print("O2 ARRANGEMENT HELD OPERANDS: ", operands, "; actual fired kinds=", _o2_fired)
	if not _expect(not receipt.is_empty() and only_dash_events and _same(production.attempts.state().side_attempt.checkpoint, _legacy_entrance) and not _same(held, _legacy_entrance), "actual first Root warning is separate from entrance with only genuine approach dashes, no attack or court checkpoint", str({"operands":operands,"fired":_o2_fired,"receipt":receipt,"campaign_error":production.campaign_error,"level_error":production.active_level.last_snapshot_error})):
		await _finish(); return
	if not _installed(held) or not _archive_sample("first-root-held", held, receipt): await _finish(); return
	if not _pins_unchanged(): await _finish(); return
	var manifest: Dictionary = {
		"schema_version": 1, "kind": "a3-o2-original-challenge-arrangement-legacy-1",
		"test_only": true, "selector": "produce-legacy",
		"authorization_source_head": AUTHORIZATION_HEAD,
		"execution_provenance": "Original canonical runner command/sources/result/native.log govern actual HEAD, immutable inputs and closure; this manifest alone grants no pass.",
		"canonical_registry_sha256": FileAccess.get_sha256(Registry.DATA_PATH),
		"source_pins": _original_pins, "resource_uid_text": _original_uids,
		"files": _fixture_files.duplicate(true), "samples": _samples.duplicate(true),
		"native_driver_ticks": _o2_ticks,
		"scope": "Actual old Challenge entrance and first Root held warning; all five original native origins, whole units/sessions and byte-copied raw format2 Stores. TEST prefix12 only. No court clear, new reader, restore, ordinary-hit, final arrangement, portrait or full-route result.",
	}
	if not _write_exact("manifest.json", manifest): await _finish(); return
	scope_complete = true
	_phase("both original legacy samples and manifest written")
	await _finish()

func _seed_story(registry: CinderCampaignRegistry) -> bool:
	# Same accepted native L2 donor lifecycle; seed prefix12 directly, never a
	# transient prefix11/relabeled packet or made-up accepted Registry row.
	paused = true
	preview = MainScene.instantiate()
	preview.set("level_scene_path", STORY_PATH)
	root.add_child(preview)
	preview.call("open_bench")
	var actor: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var camera: Camera3D = preview.get("camera") as Camera3D
	if not _expect(actor != null and level != null and camera != null and level.level_id == STORY_ID and String(preview.get("level_load_error")).is_empty(), "actual accepted L2 Main constructs the Story donor"):
		return false
	await process_frame
	var actor_state: Dictionary = actor.snapshot_state()
	var level_state: Dictionary = level.snapshot_state()
	var input: Dictionary = preview.call("get_input_observation_state")
	if not _expect(paused and not actor_state.is_empty() and not level_state.is_empty() and actor.get_world_action_records().is_empty() and input.sequence == 0 and input.last_observation.is_empty(), "actual paused L2 actor/local/input writers contain no fabricated gameplay", actor.last_snapshot_error + "; " + level.last_snapshot_error):
		return false
	var anchor: Vector2 = input.anchor_normalized
	var shell_state: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": input.sequence, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Game.CAMERA_OFFSET), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}
	protected = {"schema_version": 1, "level_id": STORY_ID, "scene_path": STORY_PATH, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": actor_state, "level": level_state, "shell": shell_state}
	var model = Attempts.new(registry)
	expected_session = model.state()
	expected_session.completed_main = registry.main_route().slice(0, 12) # TEST ONLY allowed predecessor prefix.
	expected_session.story = {"kind": "story", "level_id": STORY_ID, "snapshot": protected.duplicate(true), "checkpoint": protected.duplicate(true)}
	var error: String = model.state_error(expected_session)
	var writer = Store.new(isolated + "campaign.json")
	writer.payload_validator = model.saved_payload_error
	if not _expect(error.is_empty() and expected_session.completed_main[-1] == STORY_ID and writer.write_payload(expected_session), "detached prefix12 wraps the complete actual L2 opening unchanged", error + "; " + writer.last_error): return false
	var refs: Array[WeakRef] = []
	_collect_refs(preview, refs)
	level.exit_level()
	preview.queue_free()
	preview = null
	return await _released(refs, "original L2 donor retires through public level exit") and _disk(expected_session)

func _capture_source_pins() -> bool:
	var paths: Array[String] = []
	paths.assign(O2_PINS)
	paths.append_array([PRODUCER_PATH, "res://scripts/acts/act3/garden_root_latcher_art.gd", "res://scenes/acts/act3/a3_l2_living_forest.tscn", "res://scripts/combat/difficulty.gd", "res://scripts/combat/encounter_arrangement.gd", "res://data/design/difficulty_profiles.json", "res://scripts/campaign/attempts.gd", Registry.DATA_PATH])
	if not _expect(FileAccess.file_exists(PRODUCER_PATH + ".uid"), "new producer UID must come from legitimate import before execution"): return false
	for path: String in paths:
		var digest: String = FileAccess.get_sha256(path)
		if not _expect(digest.length() == 64, "original source bytes exist: " + path): return false
		_original_pins[path] = digest
		if FileAccess.file_exists(path + ".uid"):
			_original_pins[path + ".uid"] = FileAccess.get_sha256(path + ".uid")
			_original_uids[path] = FileAccess.get_file_as_string(path + ".uid").strip_edges()
		elif path.ends_with(".tscn"):
			var uid: int = ResourceLoader.get_resource_uid(path)
			if uid != ResourceUID.INVALID_ID: _original_uids[path] = ResourceUID.id_to_text(uid)
	return true

func _pins_unchanged() -> bool:
	for path: String in _original_pins:
		if not _expect(FileAccess.get_sha256(path) == _original_pins[path], "producer retains actual original source/UID bytes: " + path): return false
	return true

func _observed_origins() -> Dictionary:
	var origins: Dictionary = {}
	var sources: Dictionary = production.active_level.get("sources")
	for id: String in QRC.SOURCE_IDS: origins[id] = Codec.vector3((sources[id] as Node3D).global_position)
	return origins

func _o2_tick() -> bool:
	if not await super._o2_tick(): return false
	return _expect(_o2_ticks <= 1800 and _o2_scheduler.get_clock() <= 30.0, "first-warning producer retains bounded1800 native ticks/30seconds independently of host budget")

func _native_ids() -> Dictionary:
	var ids: Dictionary = super._native_ids()
	ids.source = ((production.active_level.get("sources") as Dictionary)[O2_ROOT] as Node).get_instance_id()
	return ids

func _legacy_unit(unit: Dictionary, origins: Dictionary, warning: bool) -> bool:
	if not _expect(not unit.is_empty() and unit.level_id == "A3-O2" and unit.scene_path == O2_PATH and unit.paused and unit.shell.difficulty_at_entry == "challenge" and unit.level.local_snapshot_version == 2, "actual paused old Challenge whole unit retains outer local version2"): return false
	var local: Dictionary = unit.level.local
	if not _expect(Codec.keys_error(local, LEGACY_KEYS).is_empty() and local.api_revision == LEGACY_API and local.schema_version == 1 and local.scheduler.profile.id == "challenge" and local.scheduler.world_revision == 1 and local.scheduler.encounter_id == QRC.ENCOUNTER_ID and local.scheduler.clock_s <= 30.0 and Codec.keys_error(local.sources, QRC.SOURCE_IDS).is_empty() and local.route.active_court == 0 and local.route.clears.is_empty() and local.route.deaths.is_empty() and local.route.exit_state == "clear" and local.route.contact.is_empty() and not unit.level.progress.completed and unit.level.progress.checkpoint_ids.is_empty(), "literal old inner API2/schema1 six-key unit/world1 has no arrangement descriptor or earned court"): return false
	for id: String in QRC.SOURCE_IDS:
		var actor: Dictionary = local.sources[id].actor
		if not _expect(local.sources[id].kind == QRC.SOURCE_KINDS[id] and actor.stable_id == id and actor.resolved_role.difficulty_profile == "challenge" and not actor.dead and actor.hp == actor.max_hp and Codec.read_vector3(actor.position) == LEGACY_ORIGINS[id] and _same(actor.position, origins[id]), "all five genuine old native origins/Challenge roles retained: " + id): return false
		if QRC.SOURCE_KINDS[id] == "root":
			var mechanism: Dictionary = actor.mechanism
			var expected_cycle: bool = (mechanism.cycle >= 1 and mechanism.status == "running" and mechanism.phase == "warning") if warning and id == O2_ROOT else (mechanism.cycle == 0 and mechanism.exchange.is_empty())
			if not _expect(expected_cycle, "only the actual selected first Root may have an original warning cycle: " + id): return false
		elif not _expect(actor.cycle == 0 and actor.reservation_id.is_empty(), "future Stalker remains dormant at original home"): return false
	return true

func _held_receipt() -> Dictionary:
	var level: CinderLevel = production.active_level
	var source: CinderAct3RootLatcher = (level.get("sources") as Dictionary)[O2_ROOT] as CinderAct3RootLatcher
	var mechanism: CinderLaneMechanism = source.get_mechanism()
	var scheduler: CinderThreatScheduler = level.get("threat_scheduler") as CinderThreatScheduler
	var state: Dictionary = source.state()
	var control: Dictionary = scheduler.source_control_state(mechanism) # Pure; do not prune at this paused archive boundary.
	var bindings: Dictionary = level.call("scheduler_bindings")
	var native: Dictionary = state.mechanism
	if state.phase != "warning" or native.status != "running" or native.phase != "warning" or String(native.reservation_id).is_empty() or control.get("reservations", []).size() != 1: return {}
	var lease: Dictionary = control.reservations[0]
	if state.source_id != FIRST_OWNER or bindings.owners.get(FIRST_OWNER) != mechanism or control.source_instance_id != mechanism.get_instance_id() or lease.id != native.reservation_id or lease.state != "warning" or not lease.armed or lease.profile_id != "challenge" or control.clock_s != scheduler.get_clock() or state.clock_s != scheduler.get_clock() or scheduler.get_clock() >= float(lease.lock_from_s): return {}
	var deadlines: Dictionary = {}
	for key: String in DEADLINES: deadlines[key] = lease[key]
	return {"source_id": O2_ROOT, "mechanism_id": FIRST_OWNER, "phase": "warning", "reservation_id": lease.id, "cycle": native.cycle, "clock_s": scheduler.get_clock(), "deadlines": deadlines, "mechanism_instance_id_decimal_text": str(mechanism.get_instance_id())}

func _prepare_fixture() -> bool:
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FIXTURE_ROOT)) == OK, "new immutable original fixture directory opens"): return false
	return _write_exact("registry.native.json", raw) and _write_exact("story.native.json", protected) and _write_exact("start-session.native.json", expected_session) and _write_exact("source-pins.json", {"source_pins": _original_pins, "resource_uid_text": _original_uids})

func _archive_sample(label: String, unit: Dictionary, receipt: Dictionary) -> bool:
	var warning: bool = label == "first-root-held"
	var origins: Dictionary = _observed_origins()
	if not _legacy_unit(unit, origins, warning): return false
	var session: Dictionary = production.attempts.state()
	if not _expect(paused and _same(production.capture_campaign_snapshot(), unit) and _same(session.side_attempt.snapshot, unit) and _same(session.side_attempt.checkpoint, _legacy_entrance) and _same(session.story, expected_session.story), "actual complete native session/checkpoint/Story joins at " + label): return false
	if not _disk(session): return false
	if warning:
		var exchange: Dictionary = unit.level.local.sources[O2_ROOT].actor.mechanism.exchange
		for key: String in DEADLINES:
			if not _expect(_same(exchange[key], receipt.deadlines[key]), "actual held deadline joins native mechanism/Scheduler: " + key): return false
	var folder: String = FIXTURE_ROOT.path_join(label)
	if not _expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK, "sample path is new and never overwrites original bytes"): return false
	if not _write_exact(label + "/unit.native.json", unit) or not _write_exact(label + "/session.native.json", session) or not _write_exact(label + "/checkpoint.native.json", session.side_attempt.checkpoint): return false
	if not _copy_raw(label + "/campaign.store.json", isolated + "campaign.json") or not _copy_raw(label + "/preferences.store.json", isolated + "preferences.json"): return false
	if FileAccess.file_exists(isolated + "campaign.json.bak"):
		if not _copy_raw(label + "/campaign.store.json.bak", isolated + "campaign.json.bak"): return false
	var native: Dictionary = _native_ids()
	var native_text: Dictionary = {}
	for key: String in native: native_text[key] = str(native[key])
	var observation: Dictionary = {"schema_version": 1, "test_only": true, "sample": label, "actual_origins": origins, "held_warning": receipt, "actual_native_ids_decimal_text": native_text, "whole_unit_exact_wire_sha256": Exact.stringify(unit).sha256_text(), "session_exact_wire_sha256": Exact.stringify(session).sha256_text(), "raw_store_sha256": FileAccess.get_sha256(isolated + "campaign.json"), "raw_preferences_sha256": FileAccess.get_sha256(isolated + "preferences.json"), "raw_copy_policy": "Original native format2 Store bytes copied directly; not JSON parsed/reencoded or synthesized."}
	if not _write_exact(label + "/receipt.json", observation): return false
	_samples[label] = {"unit": label + "/unit.native.json", "session": label + "/session.native.json", "checkpoint": label + "/checkpoint.native.json", "raw_store": label + "/campaign.store.json", "receipt": label + "/receipt.json"}
	return _expect(_same(production.capture_campaign_snapshot(), unit) and _same(production.attempts.state(), session), "archive writes preserve the actual full native unit/session: " + label)

func _write_exact(relative: String, value: Dictionary) -> bool:
	var path: String = FIXTURE_ROOT.path_join(relative)
	var wire: String = Exact.stringify(value)
	if not _expect(not wire.is_empty() and not FileAccess.file_exists(path), "new finite exact archive writer: " + relative): return false
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not _expect(file != null, "original exact archive file opens: " + relative): return false
	file.store_string(wire + "\n")
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if not _expect(error == OK and FileAccess.get_file_as_string(path) == wire + "\n", "original exact archive wire persists without transformation: " + relative): return false
	_fixture_files[relative] = {"sha256": FileAccess.get_sha256(path), "exact_wire_sha256": wire.sha256_text(), "bytes": FileAccess.get_file_as_bytes(path).size()}
	return true

func _copy_raw(relative: String, source: String) -> bool:
	var target: String = FIXTURE_ROOT.path_join(relative)
	var before: String = FileAccess.get_sha256(source)
	if not _expect(before.length() == 64 and not FileAccess.file_exists(target) and DirAccess.copy_absolute(ProjectSettings.globalize_path(source), ProjectSettings.globalize_path(target)) == OK and FileAccess.get_sha256(source) == before and FileAccess.get_sha256(target) == before, "byte-for-byte actual native format2 Store copy: " + relative): return false
	_fixture_files[relative] = {"sha256": before, "bytes": FileAccess.get_file_as_bytes(target).size(), "original_user_path": source, "raw_store_copy": true}
	return true

func _dispose_shell() -> bool:
	var retired: bool = true
	if is_instance_valid(production) and is_instance_valid(production.active_level) and production.active_level.is_inside_tree():
		var scheduler: CinderThreatScheduler = production.active_level.get("threat_scheduler") as CinderThreatScheduler
		production.active_level.exit_level()
		if scheduler != null: retired = _expect(scheduler.reservations().is_empty(), "public level exit retires the held owner before Shell children leave tree")
	var disposed: bool = await super._dispose_shell()
	return retired and disposed

func _phase(label: String) -> void:
	print("O2 ARRANGEMENT PHASE: ", label, "; host_wall_s=", float(Time.get_ticks_usec() - _started_usec) / 1000000.0, "; native_ticks=", _o2_ticks)

func _expect(ok: bool, label: String, detail: String = "") -> bool:
	checks += 1
	print("O2 ARRANGEMENT ROW ", checks, ": ", "PASS " if ok else "FAIL ", label)
	if not ok:
		failures += 1
		push_error("FAIL O2 arrangement producer: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok

func _finish() -> void:
	if finished: return
	finished = true
	if is_instance_valid(_o2_barrier):
		var observer_ref: WeakRef = weakref(_o2_barrier)
		if _o2_barrier.get("waiting"): _o2_barrier.call("_wake", "normal_finish")
		if _o2_barrier.get("presentation_waiting"): _o2_barrier.call("_wake_presentation", "normal_finish")
		_o2_barrier.queue_free()
		_o2_barrier = null
		await _released([observer_ref], "normal native observer cleanup")
	await _dispose_shell()
	if is_instance_valid(preview):
		var refs: Array[WeakRef] = []
		_collect_refs(preview, refs)
		var level: CinderLevel = preview.get("active_level") as CinderLevel
		if is_instance_valid(level) and level.is_inside_tree(): level.exit_level()
		preview.queue_free()
		preview = null
		await _released(refs, "remaining native Story donor cleanup")
	if node_added.is_connected(_watch_node): node_added.disconnect(_watch_node)
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal producer cleanup leaves no native enemy/cue groups")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == canonical_bytes, "canonical Registry bytes unchanged")
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		if FileAccess.file_exists(isolated + name): DirAccess.remove_absolute(ProjectSettings.globalize_path(isolated + name))
	AudioServer.set_bus_layout(old_audio)
	Engine.max_fps = old_fps
	paused = false
	print("O2 arrangement producer: %d checks/%d failures; scope_complete=%s; selector=produce-legacy; native ticks=%d; actual oldChallenge entrance/firstRootheld/all5origins/raw format2/whole cleanup only; no reader promotion, court clear, portrait or full-route credit." % [checks, failures, str(scope_complete), _o2_ticks])
	quit(0 if failures == 0 and scope_complete else 1)
