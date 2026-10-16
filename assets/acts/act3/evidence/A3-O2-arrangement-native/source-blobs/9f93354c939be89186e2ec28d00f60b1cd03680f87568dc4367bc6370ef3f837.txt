extends "res://tests/acts/act3/quiet_root_circuit_optional_shell.gd"
## Focused O2 arrangement producer, compatibility, transport and component checks.
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
var _arrangement_selector: String = ""

func _initialize() -> void:
	isolated = "user://test-a3-o2-arrangement-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	old_audio = AudioServer.generate_bus_layout()
	old_fps = Engine.max_fps
	_started_usec = Time.get_ticks_usec()
	_run.call_deferred()

func _run() -> void:
	create_timer(1800.0,true,false,true).timeout.connect(func() -> void:
		if not finished:
			_expect(false,"bounded arrangement host watchdog")
			_finish())
	root.size = Vector2i(340,736)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	canonical_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not _expect(args.size() == 1,"one explicit arrangement scope selector"):
		await _finish(); return
	_arrangement_selector = args[0]
	if _arrangement_selector == "--produce-legacy":
		await _run_original_producer(); return
	if _arrangement_selector == "--pure":
		scope_complete = _run_arrangement_pure()
	elif _arrangement_selector == "--legacy":
		scope_complete = await _ot_run_legacy(ORIGINAL_CHALLENGE_MANIFEST_SHA256)
	elif _arrangement_selector == "--current-persistence":
		scope_complete = await _ot_run_current_persistence()
	elif _arrangement_selector in COMPONENT_SELECTORS:
		scope_complete = await _run_component(_arrangement_selector)
	else:
		_expect(false,"recognized focused arrangement selector",_arrangement_selector)
	await _finish()

func _run_original_producer() -> void:
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
		push_error("FAIL O2 arrangement: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok

func _finish() -> void:
	if finished: return
	finished = true
	if is_instance_valid(_component_main) or is_instance_valid(_component_barrier) or _component_scene != null:
		await _component_dispose()
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
	print("O2 arrangement: %d checks/%d failures; scope_complete=%s; selector=%s; native_ticks=%d; component_ticks=%d; scopes: genuine originals or explicit pure/transport/declared component only; no full-route or human-balance credit." % [checks,failures,str(scope_complete),_arrangement_selector,_o2_ticks,_component_ticks])
	quit(0 if failures == 0 and scope_complete else 1)

## SOURCE-ONLY fragment for the single future O2 arrangement test.
## All mutated packets below are explicitly pure rejection/representation data,
## never native fixture provenance or accepted gameplay/session history.
const ArrangementMetadata = preload("res://scripts/combat/encounter_arrangement.gd")
const ORIGINAL_CHALLENGE_MANIFEST_SHA256: String = "a4dd684ee42fed0a9566d1fd3a8df2f1eacf31c31a727b290f5a26ecb49f97db"

func _run_arrangement_pure() -> bool:
	if not _expect(QRC.ROUTE_API == "act3-quiet-root-circuit-3" and QRC.LEGACY_ROUTE_API == LEGACY_API and QRC.LOCAL_VERSION == 2 and QRC.WORLD_REVISION == 1, "new inner API3 retains literal API2/outer2/world1 seam"): return false
	var definition: Dictionary = QRC.arrangement_definition()
	var selector := ArrangementMetadata.new(definition)
	if not _expect(selector.last_error.is_empty() and definition.unit_ids == QRC.SOURCE_IDS and definition.recipes.size() == 4, "closed metadata retains complete five-source inventory/four immutable recipes"): return false
	var current_challenge: Dictionary = {}
	for profile: String in ["assisted","standard","challenge"]:
		var descriptor: Dictionary = selector.select_fresh(profile)
		var layout: Dictionary = QRC.arrangement_layout(descriptor)
		if not _expect(not descriptor.is_empty() and String(layout.error).is_empty() and descriptor.profile == profile and layout.starts.size() == 5, "fresh profile selects one complete five-source arrangement: "+profile): return false
		for id: String in QRC.SOURCE_IDS:
			var expected: Vector3 = QRC.SOURCE_POSITIONS[id]
			if profile == "challenge" and id == "o2-final-east-root": expected = Vector3(0,0,-4.5)
			if profile == "challenge" and id == "o2-final-stalker": expected = Vector3(1.2,0.1,-6)
			if not _expect(layout.starts[id] == expected and (layout.starts[id] as Vector3).y == (QRC.SOURCE_POSITIONS[id] as Vector3).y, "exact source ground slot/native height: "+profile+"/"+id): return false
		if profile == "challenge": current_challenge = descriptor.duplicate(true)
	var changed_current: Dictionary = definition.duplicate(true)
	changed_current.current.challenge = QRC.LEGACY_RECIPE_IDS.challenge
	var future := ArrangementMetadata.new(changed_current)
	if not _expect(future.last_error.is_empty() and future.select_fresh("challenge").recipe_id == QRC.LEGACY_RECIPE_IDS.challenge and future.restore(current_challenge) == current_challenge, "later fresh mapping cannot reinterpret an already retained current Challenge descriptor"): return false
	var removed: Dictionary = changed_current.duplicate(true)
	removed.recipes.pop_back()
	var missing_recipe := ArrangementMetadata.new(removed)
	if not _expect(missing_recipe.last_error.is_empty() and not missing_recipe.saved_error(current_challenge).is_empty(), "removing retained recipe refuses its old descriptor without migration"): return false
	for key: String in ["profile","recipe_id","order","extra"]:
		var bad: Dictionary = current_challenge.duplicate(true)
		if key == "profile": bad.profile = "standard"
		elif key == "recipe_id": bad.recipe_id = "A3-O2/challenge-forward-knot@v99"
		elif key == "order": bad.order[0] = bad.order[1]
		else: bad.extra = true
		var wire: String = Exact.stringify(bad)
		if not _expect(not String(QRC.arrangement_layout(bad).error).is_empty() and wire == Exact.stringify(bad), "malformed pure descriptor refuses without caller mutation: "+key): return false
	var detached: Dictionary = QRC.arrangement_layout(current_challenge)
	detached.starts["o2-final-east-root"] = Vector3(99,0,99)
	if not _expect(QRC.arrangement_layout(current_challenge).starts["o2-final-east-root"] == Vector3(0,0,-4.5) and QRC.SOURCE_POSITIONS["o2-final-east-root"] == Vector3(1.2,0,-6), "detached layout mutations cannot change retained canonical/new positions"): return false
	if not _expect(FileAccess.get_sha256(FIXTURE_ROOT.path_join("manifest.json")) == ORIGINAL_CHALLENGE_MANIFEST_SHA256, "exact externally verified successful old producer manifest is retained"): return false
	var manifest_result: Dictionary = Exact.parse(FileAccess.get_file_as_string(FIXTURE_ROOT.path_join("manifest.json")))
	if not _expect(manifest_result.get("accepted",false) and manifest_result.get("value") is Dictionary, "actual successful old producer manifest decodes exactly"): return false
	var manifest: Dictionary = manifest_result.value
	if not _expect(manifest.kind == "a3-o2-original-challenge-arrangement-legacy-1" and manifest.files is Dictionary and manifest.samples.has("entrance") and manifest.samples.has("first-root-held"), "literal original fixtures have both genuine samples; failed partials cannot qualify"): return false
	for relative: String in manifest.files:
		if not _expect(FileAccess.get_sha256(FIXTURE_ROOT.path_join(relative)) == manifest.files[relative].sha256 and FileAccess.get_file_as_bytes(FIXTURE_ROOT.path_join(relative)).size() == manifest.files[relative].bytes, "literal old producer artifact bytes unchanged: "+relative): return false
	for label: String in ["entrance","first-root-held"]:
		var parsed: Dictionary = Exact.parse(FileAccess.get_file_as_string(FIXTURE_ROOT.path_join(label+"/unit.native.json")))
		if not _expect(parsed.get("accepted",false) and parsed.get("value") is Dictionary, "actual original whole unit decodes: "+label): return false
		var local: Dictionary = parsed.value.level.local
		var original: String = Exact.stringify(local)
		var valid: Dictionary = QRC.arrangement_constructor(local)
		if not _expect(String(valid.error).is_empty() and valid.legacy and valid.descriptor.recipe_id == QRC.LEGACY_RECIPE_IDS.challenge and valid.starts == QRC.SOURCE_POSITIONS and original == Exact.stringify(local), "original old Challenge constructor retains canonical slots without inserting descriptor: "+label): return false
		for key: String in ["api","schema","extra","unknown_profile","wrong_profile_value","foreign_source","wrong_kind","wrong_origin","future_court","nonfinite"]:
			var bad: Dictionary = local.duplicate(true)
			if key == "api": bad.api_revision = "act3-quiet-root-circuit-99"
			elif key == "schema": bad.schema_version = 1.5
			elif key == "extra": bad.arrangement = current_challenge.duplicate(true)
			elif key == "unknown_profile": bad.scheduler.profile.id = "unknown"
			elif key == "wrong_profile_value": bad.scheduler.profile["raw_damage_multiplier"] = 123.0
			elif key == "foreign_source": bad.sources.erase("o2-first-root")
			elif key == "wrong_kind": bad.sources["o2-first-root"].kind = "stalker"
			elif key == "wrong_origin": bad.sources["o2-final-east-root"].actor.position = [0.0,0.0,-4.5]
			elif key == "future_court": bad.route.active_court = 4
			else: bad.scenery.sun_elapsed_s = INF
			var before: String = Exact.stringify(bad)
			var before_values: Dictionary = bad.duplicate(true)
			var refused: Dictionary = QRC.arrangement_constructor(bad)
			if not _expect(not String(refused.error).is_empty() and before == Exact.stringify(bad) and bad == before_values, "pure malformed old constructor refuses without caller mutation: "+label+"/"+key): return false
		# Supplemental numeric representation control; not authentic new history.
		# Match the original native schema1 Scheduler's Codec.same_values semantics.
		var represented: Dictionary = local.duplicate(true)
		var numeric_key: String = ""
		for key: String in represented.scheduler.profile:
			var value: Variant = represented.scheduler.profile[key]
			if (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)):
				numeric_key = key
				represented.scheduler.profile[key] = float(value) if value is int else int(value)
				break
		if not _expect(not numeric_key.is_empty(), "original profile supplies an integral numeric representation control"): return false
		var represented_wire: String = Exact.stringify(represented)
		var representation: Dictionary = QRC.arrangement_constructor(represented)
		if not _expect(Codec.same_values(local.scheduler.profile,represented.scheduler.profile) and String(representation.error).is_empty() and representation.legacy and representation.starts == QRC.SOURCE_POSITIONS and represented_wire == Exact.stringify(represented), "pure legacy numeric int/float representation retains original native matcher/no rewrite: "+label): return false
	return true

## METHODS FRAGMENT ONLY: merge into the ONE arrangement smoke test only after
## the successful original producer closes and the reviewed reader is promoted.
## No _run/_initialize/_finish override. Root owns dispatcher/watchdog/closure.
## Uses inherited accepted Shell helpers plus the producer's safe disposal,
## first-warning receipt, literal _legacy_unit and actual prefix12 L2 seed.

const OT_CURRENT_API: String = "act3-quiet-root-circuit-3"
const OT_CURRENT_KEYS: Array[String] = ["api_revision", "schema_version", "scenery", "scheduler", "sources", "route", "arrangement"]
const OT_CHALLENGE_RECIPE: String = "A3-O2/challenge-forward-knot@v2"
const OT_CHALLENGE_ORDER: Array[String] = ["o2-first-root", "o2-second-root", "o2-final-west-root", "o2-final-stalker", "o2-final-east-root"]
const OT_CURRENT_ROOT: String = "res://captures/act3/quiet-root-circuit"
const OT_CHALLENGE_STARTS: Dictionary = {
	"o2-first-root": Vector3(0, 0, 4),
	"o2-second-root": Vector3(1.4, 0, -1),
	"o2-final-west-root": Vector3(-1.2, 0, -6),
	"o2-final-east-root": Vector3(0, 0, -4.5),
	"o2-final-stalker": Vector3(1.2, 0.1, -6),
}

var _ot_manifest: Dictionary = {}
var _ot_current_archive: String = ""
var _ot_current_files: Dictionary = {}
var _ot_last_scope: Dictionary = {}

func _ot_run_legacy(successful_producer_manifest_sha256: String) -> bool:
	if not _ot_setup("--legacy"): return false
	if not _ot_verify_legacy_fixture(successful_producer_manifest_sha256): return false
	var original_entrance: Dictionary = _ot_original("entrance/unit.native.json")
	var original_story: Dictionary = _ot_original("story.native.json")
	var original_start: Dictionary = _ot_original("start-session.native.json")
	if failures > 0: return false
	protected = original_story
	for sample: String in ["entrance", "first-root-held"]:
		var unit: Dictionary = _ot_original(sample + "/unit.native.json")
		var session: Dictionary = _ot_original(sample + "/session.native.json")
		var saved_checkpoint: Dictionary = _ot_original(sample + "/checkpoint.native.json")
		var receipt: Dictionary = _ot_original(sample + "/receipt.json")
		if failures > 0: return false
		if not _expect(session.side_attempt != null and session.side_attempt.kind == "optional" and session.side_attempt.level_id == "A3-O2" and _same(session.side_attempt.snapshot, unit) and _same(session.side_attempt.checkpoint, saved_checkpoint) and _same(saved_checkpoint, original_entrance) and _same(session.story.snapshot, protected) and _same(session.story, original_start.story) and session.completed_main == (Registry.new(raw)).main_route().slice(0, 12), "original complete legacy session/entrance checkpoint/protected L2/prefix12 joins: " + sample): return false
		if not _legacy_unit(unit, receipt.actual_origins, sample == "first-root-held"): return false
		if not _ot_stage_original_store(sample, session): return false
		expected_session = session
		checkpoint = saved_checkpoint
		if not await _new_shell(session): return false
		# A fresh isolated test defaults publicly to Standard; after the first
		# sample that same public selection is persisted for the next startup.
		if not _expect(production.get_difficulty_preference() == "standard", "fresh legacy startup already has the opposite future preference"): return false
		if not _ot_set_preference("standard", session): return false
		if not _ot_title_resume_side(): return false
		if not await _wait_installed("A3-O2", "resume", unit) or not _installed(unit) or not _quiet_selected() or not _disk(session): return false
		if not _ot_actual_recipe(unit, true, LEGACY_ORIGINS): return false
		if not _legacy_unit(production.capture_campaign_snapshot(), _observed_origins(), sample == "first-root-held"): return false
		if sample == "first-root-held":
			if not _expect(_same(_ot_warning_core(_held_receipt()), _ot_warning_core(receipt.held_warning)), "fresh legacy first-Root warning retains original cycle/clock/all six deadlines with its own native recipient"): return false
		if not _expect(_same(production.attempts.state(), session) and _same(production.attempts.state().side_attempt.checkpoint, original_entrance), "fresh literal legacy whole model/checkpoint is unchanged"): return false
		if not await _ot_retry_exact(original_entrance, true, LEGACY_ORIGINS): return false
		if not await _ot_cleanup("legacy " + sample): return false
	if not _ot_verify_legacy_fixture(successful_producer_manifest_sha256): return false
	_ot_report("legacy", true, "Both original raw Stores: fresh public Title Resume Side under Standard, literal old API2 six-key exact recapture, saved Challenge/canonical origins and entrance Retry; no court clear or new pixels.")
	return true

func _ot_run_current_persistence() -> bool:
	if not _ot_setup("--current-persistence"): return false
	var registry = Registry.new(raw)
	if not await _seed_story(registry) or not await _new_shell(expected_session): return false
	if not _ot_set_preference("challenge", expected_session): return false
	production.menu.continue_story_requested.emit()
	if not await _wait_installed(STORY_ID, "resume", protected) or not _installed(protected) or not _quiet_selected(): return false
	var story_refs: Array[WeakRef] = []
	_collect_refs(_world_container(), story_refs)
	var story_ids: Dictionary = _core_ids()
	production.menu.optional_requested.emit("A3-O2")
	if not await _wait_installed("A3-O2", "resume", {}, story_ids): return false
	var entrance: Dictionary = production.capture_campaign_snapshot()
	checkpoint = production.attempts.state().side_attempt.checkpoint.duplicate(true)
	if not _installed(entrance) or not await _released(story_refs, "new Challenge Optional retires actual protected Story recipient"): return false
	if not _expect(_same(entrance, checkpoint) and _same(production.attempts.state().story, expected_session.story) and production.player.get_world_action_records().is_empty(), "new Challenge entry is genuine/pristine and protects older L2 Story"): return false
	if not _ot_actual_recipe(entrance, false, OT_CHALLENGE_STARTS): return false
	var entrance_origins: Dictionary = _observed_origins()
	if not _ot_bind_first(): return false
	if not await _resume_after_layout(): return false
	if (await _o2_warning(O2_ROOT)).is_empty() or not await _o2_presentation(): return false
	production.request_pause()
	if not await _wait_pause(): return false
	held = production.capture_campaign_snapshot()
	var warning: Dictionary = _held_receipt()
	if not _expect(not warning.is_empty() and _ot_only_dash_fired() and _same(production.attempts.state().side_attempt.checkpoint, entrance) and not _same(held, entrance), "genuine new first warning permits native approach dashes but no attack/clear/checkpoint fabrication"): return false
	if not _installed(held) or not _ot_actual_recipe(held, false, OT_CHALLENGE_STARTS): return false
	var saved: Dictionary = production.attempts.state()
	if not _disk(saved) or not _ot_archive_current(entrance, entrance_origins, held, saved, warning): return false
	var donor_ids: Dictionary = _native_ids()
	# Public future preference changes while paused; it must not rewrite or
	# retune the current saved Challenge recipe. Persist it BEFORE new startup.
	if not _ot_set_preference("standard", saved): return false
	if not _expect(_same(production.capture_campaign_snapshot(), held) and _same(_held_receipt(), warning), "opposite future preference preserves live saved whole packet/deadlines"): return false
	if not await _ot_cleanup("new Challenge donor"): return false
	if not await _new_shell(saved): return false
	if not _expect(production.get_difficulty_preference() == "standard", "independent fresh Shell loads the persisted opposite future preference"): return false
	if not _ot_title_resume_side(): return false
	if not await _wait_installed("A3-O2", "resume", held) or not _installed(held) or not _distinct(donor_ids) or not _quiet_selected(): return false
	if not _expect(_same(_ot_warning_core(_held_receipt()), _ot_warning_core(warning)) and _same(production.attempts.state(), saved), "fresh disk Continue/Resume Side preserves complete new Challenge unit/lease/deadlines with new native identities"): return false
	if not _disk(saved) or not _ot_actual_recipe(held, false, OT_CHALLENGE_STARTS): return false
	if not await _ot_retry_exact(entrance, false, OT_CHALLENGE_STARTS): return false
	if not await _ot_cleanup("new Challenge Retry recipient"): return false
	_ot_report("current-persistence", true, "Actual new Challenge entrance/first warning/format2 Save, persisted opposite preference before fresh Title Resume Side, independent exact recipient, retained Challenge recipe/origins and entrance Retry; no court clear/contact/portrait.")
	return true

func _ot_setup(selector: String) -> bool:
	if not _expect(OS.get_cmdline_user_args() == PackedStringArray([selector]) and DisplayServer.get_name() == "headless", "one explicit bounded headless arrangement transport selector"): return false
	root.size = Vector2i(340, 736)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	canonical_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var decoded: Variant = JSON.parse_string(canonical_bytes)
	if not _expect(decoded is Dictionary, "canonical Registry parses without mutation"): return false
	raw = decoded
	var registry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.entry("A3-O2").readiness == "accepted" and registry.entry("A3-O2").scene_path == O2_PATH and registry.entry("A3-O2").parent_level_id == STORY_ID, "transport uses the unmodified canonical O2 row/parent/scene", registry.last_error): return false
	if not node_added.is_connected(_watch_node): node_added.connect(_watch_node)
	return true

func _ot_set_preference(profile: String, expected: Dictionary) -> bool:
	if not _expect(paused and not production.is_pause_requested(), "public future preference is selected only at an idle paused boundary"): return false
	var raw_before: String = FileAccess.get_sha256(isolated + "campaign.json")
	production.menu.difficulty_preference_requested.emit(profile)
	var reader = Store.new(isolated + "preferences.json")
	var actual: Dictionary = reader.read_payload()
	return _expect(production.get_difficulty_preference() == profile and reader.last_error.is_empty() and not reader.loaded_backup and actual == {"schema_version": 1, "profile_id": profile} and _same(production.attempts.state(), expected) and FileAccess.get_sha256(isolated + "campaign.json") == raw_before, "actual public preference Store changes only the future preference: " + profile)

func _ot_title_resume_side() -> bool:
	if not _expect(paused and production.menu.page_name() == "title" and production.attempts.state().side_attempt != null, "actual Title has a saved Optional to continue"): return false
	var button: Button = production.menu.find_child("ResumeSideButton", true, false) as Button
	if not _expect(button != null and not button.disabled and button.is_visible_in_tree(), "actual public Title Resume Side button is available"): return false
	button.pressed.emit() # Native UI connection -> resume_requested -> load_active.
	return true

func _ot_retry_exact(expected: Dictionary, legacy: bool, starts: Dictionary) -> bool:
	var refs: Array[WeakRef] = []
	_collect_refs(_world_container(), refs)
	var previous: Dictionary = _native_ids()
	receiver_events.clear()
	production.menu.retry_requested.emit() # Public request_retry queues native retry.
	if not await _wait_installed("A3-O2", "resume", expected, previous): return false
	if not _installed(expected) or not _distinct(previous) or not _quiet_selected() or not await _released(refs, "actual Retry retires whole prior five-source native World"): return false
	if not _expect(_same(production.attempts.active_snapshot(), expected) and _same(production.attempts.state().side_attempt.checkpoint, expected) and _same(production.attempts.state().story.snapshot, protected) and production.get_difficulty_preference() == "standard", "Retry restores exact original entrance while keeping future preference/Story separate"): return false
	return _ot_actual_recipe(expected, legacy, starts) and _disk(production.attempts.state())

func _ot_actual_recipe(unit: Dictionary, legacy: bool, starts: Dictionary) -> bool:
	var local: Dictionary = unit.level.local
	if not _expect(unit.paused and unit.level.local_snapshot_version == 2 and unit.shell.difficulty_at_entry == "challenge" and local.scheduler.profile.id == "challenge" and local.scheduler.world_revision == 1 and local.route.active_court == 0 and local.route.clears.is_empty() and local.route.deaths.is_empty() and not unit.level.progress.completed and unit.level.progress.checkpoint_ids.is_empty(), "saved native Challenge/profile/world/uncleared court is preserved"): return false
	if legacy:
		if not _expect(local.api_revision == LEGACY_API and local.schema_version == 1 and Codec.keys_error(local, LEGACY_KEYS).is_empty() and not local.has("arrangement"), "new reader recaptures literal old six-key API2 without inserting a descriptor"): return false
	else:
		if not _expect(local.api_revision == OT_CURRENT_API and local.schema_version == 2 and Codec.keys_error(local, OT_CURRENT_KEYS).is_empty() and Codec.keys_error(local.arrangement, ["schema_version", "profile", "recipe_id", "order"]).is_empty() and local.arrangement.schema_version == 1 and local.arrangement.profile == "challenge" and local.arrangement.recipe_id == OT_CHALLENGE_RECIPE and local.arrangement.order == OT_CHALLENGE_ORDER, "new actual writer captures only the closed API3/schema2 Challenge descriptor"): return false
	var selected: Dictionary = QRC.arrangement_constructor(local)
	if not _expect(String(selected.get("error", "")).is_empty() and selected.get("legacy") == legacy, "public pure construction receipt agrees with the native retained format"): return false
	var level: CinderLevel = production.active_level
	var actual_starts: Dictionary = level.call("selected_source_positions")
	var sources: Dictionary = level.get("sources")
	var bindings: Dictionary = level.call("scheduler_bindings")
	if not _expect(Codec.keys_error(actual_starts, QRC.SOURCE_IDS).is_empty() and Codec.keys_error(sources, QRC.SOURCE_IDS).is_empty() and bindings.owners.size() == 5 and bindings.actors.hero == production.player, "actual five retained sources and selected immutable map are bound"): return false
	for id: String in QRC.SOURCE_IDS:
		var source: Node3D = sources[id]
		var actor: Dictionary = local.sources[id].actor
		var owner: Node = source.call("get_mechanism") if QRC.SOURCE_KINDS[id] == "root" else source
		var owner_id: String = id + "/attack" if QRC.SOURCE_KINDS[id] == "root" else id
		if not _expect(source.is_inside_tree() and source.get_world_3d() == production.player.get_world_3d() and source.global_position == starts[id] and actual_starts[id] == starts[id] and selected.starts[id] == starts[id] and Codec.read_vector3(actor.position) == starts[id] and actor.resolved_role.difficulty_profile == "challenge" and not actor.dead and actor.hp == actor.max_hp and bindings.owners.get(owner_id) == owner, "real native source/profile/origin/owner retains saved recipe: " + id): return false
	return _expect(String((level.call("state") as Dictionary).api_revision) == (LEGACY_API if legacy else OT_CURRENT_API) and _same(production.capture_campaign_snapshot(), unit), "actual current complete writer retains the saved format exactly")

func _ot_bind_first() -> bool:
	_o2_hero = production.player
	_o2_level = production.active_level
	_o2_scheduler = _o2_level.get("threat_scheduler") as CinderThreatScheduler
	_o2_kit = _o2_hero.equipment.snapshot()
	_o2_hp = _o2_hero.hp
	_o2_deaths = 0
	_o2_selected = O2_ROOT
	_o2_fired.clear()
	_o2_ticks = 0
	if not _expect(paused and _o2_hp == _o2_hero.max_hp and not _o2_hero.dead, "new first-warning driver observes actual untouched Hero/kit"): return false
	_o2_hero.fired.connect(_o2_record_fired)
	if not is_instance_valid(_o2_barrier):
		_o2_barrier = NativeObservers.PostActorBarrier.new()
		_o2_barrier.name = "ArrangementCurrentNativeObserver"
		root.add_child(_o2_barrier)
	return true

func _ot_only_dash_fired() -> bool:
	for kind: String in _o2_fired:
		if kind != "dash": return false
	return true

func _ot_warning_core(receipt: Dictionary) -> Dictionary:
	# This diagnostic native ID is provenance, not portable saved authority.
	# Current binding validity is separately proven by _held_receipt itself,
	# _ot_actual_recipe and same-process _distinct. Every stable lease/deadline
	# field and the entire saved native unit remain exact, without rewriting it.
	var portable: Dictionary = receipt.duplicate(true)
	portable.erase("mechanism_instance_id_decimal_text")
	return portable

func _ot_verify_legacy_fixture(expected_sha256: String) -> bool:
	var path: String = FIXTURE_ROOT.path_join("manifest.json")
	if not _expect(expected_sha256.length() == 64 and expected_sha256.is_valid_hex_number(false) and FileAccess.get_sha256(path) == expected_sha256, "legacy fixture uses the externally pinned successful original producer manifest"): return false
	var decoded: Dictionary = Exact.parse(FileAccess.get_file_as_string(path))
	if not _expect(decoded.get("accepted", false) and decoded.get("value") is Dictionary, "original producer manifest retains exact typed transport"): return false
	_ot_manifest = decoded.value
	if not _expect(_ot_manifest.kind == "a3-o2-original-challenge-arrangement-legacy-1" and _ot_manifest.schema_version == 1 and _ot_manifest.test_only == true and _ot_manifest.selector == "produce-legacy" and _ot_manifest.source_pins is Dictionary and _ot_manifest.resource_uid_text is Dictionary and _ot_manifest.files is Dictionary and _ot_manifest.samples.has("entrance") and _ot_manifest.samples.has("first-root-held"), "original producer identity/sample/source/UID scope is complete"): return false
	for original_path: String in _ot_manifest.source_pins:
		var digest: Variant = _ot_manifest.source_pins[original_path]
		if not _expect(original_path.begins_with("res://") and digest is String and digest.length() == 64 and digest.is_valid_hex_number(false), "retained OLD source pin is a recorded witness, not compared with promoted runtime: " + original_path): return false
	for relative: String in _ot_manifest.files:
		if not _expect(not relative.begins_with("/") and not relative.contains("..") and relative == relative.simplify_path(), "original fixture path stays within the immutable fixture directory"): return false
		var original: String = FIXTURE_ROOT.path_join(relative)
		var info: Dictionary = _ot_manifest.files[relative]
		if not _expect(FileAccess.file_exists(original) and FileAccess.get_sha256(original) == info.sha256 and FileAccess.get_file_as_bytes(original).size() == info.bytes, "original physical fixture bytes/size: " + relative): return false
	var pins: Dictionary = _ot_original("source-pins.json")
	if failures > 0 or pins.is_empty(): return false
	if not _expect(_same(pins.source_pins, _ot_manifest.source_pins) and _same(pins.resource_uid_text, _ot_manifest.resource_uid_text), "original source/UID witnesses agree within pinned provenance"): return false
	for sample: String in ["entrance", "first-root-held"]:
		for file: String in ["unit.native.json", "session.native.json", "checkpoint.native.json", "receipt.json", "campaign.store.json", "preferences.store.json"]:
			if not _expect(_ot_manifest.files.has(sample + "/" + file), "complete original legacy sample file is indexed: " + sample + "/" + file): return false
	return true

func _ot_original(relative: String) -> Dictionary:
	if not _expect(_ot_manifest.files.has(relative), "original typed fixture file is indexed: " + relative): return {}
	var path: String = FIXTURE_ROOT.path_join(relative)
	var info: Dictionary = _ot_manifest.files[relative]
	if not _expect(FileAccess.get_sha256(path) == info.sha256, "original typed file checksum: " + relative): return {}
	var decoded: Dictionary = Exact.parse(FileAccess.get_file_as_string(path))
	if not _expect(decoded.get("accepted", false) and decoded.get("value") is Dictionary, "original typed file parses: " + relative): return {}
	var value: Dictionary = decoded.value
	return value if _expect(Exact.stringify(value).sha256_text() == info.exact_wire_sha256, "original complete exact wire checksum: " + relative) else {}

func _ot_stage_original_store(sample: String, expected: Dictionary) -> bool:
	if not _expect(not is_instance_valid(production), "old raw Store is staged only after normal recipient disposal"): return false
	for file: String in ["campaign.json", "campaign.json.bak"]:
		if FileAccess.file_exists(isolated + file):
			if not _expect(DirAccess.remove_absolute(ProjectSettings.globalize_path(isolated + file)) == OK, "only isolated prior campaign generation is removed"): return false
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(isolated)) == OK, "isolated Store directory exists"): return false
	if not _ot_copy_verified(FIXTURE_ROOT.path_join(sample + "/campaign.store.json"), isolated + "campaign.json"): return false
	if _ot_manifest.files.has(sample + "/campaign.store.json.bak"):
		if not _ot_copy_verified(FIXTURE_ROOT.path_join(sample + "/campaign.store.json.bak"), isolated + "campaign.json.bak"): return false
	var reader = Store.new(isolated + "campaign.json")
	var model = Attempts.new(Registry.new(raw))
	reader.payload_validator = model.saved_payload_error
	var payload: Dictionary = reader.read_payload()
	return _expect(reader.last_error.is_empty() and not reader.loaded_backup and _same(payload, expected), "independent Store reads the original raw generation exactly; no JSON reencoding/write_payload", reader.last_error)

func _ot_copy_verified(source: String, target: String) -> bool:
	var before: String = FileAccess.get_sha256(source)
	return _expect(before.length() == 64 and not FileAccess.file_exists(target) and DirAccess.copy_absolute(ProjectSettings.globalize_path(source), ProjectSettings.globalize_path(target)) == OK and FileAccess.get_sha256(source) == before and FileAccess.get_sha256(target) == before, "verified raw bytes copied without parsing/reencoding: " + target)

func _ot_archive_current(entrance: Dictionary, entrance_origins: Dictionary, unit: Dictionary, session: Dictionary, warning: Dictionary) -> bool:
	_ot_current_archive = OT_CURRENT_ROOT.path_join("arrangement-current-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	_ot_current_files.clear()
	if not _expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_ot_current_archive)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_ot_current_archive)) == OK, "new CURRENT capture directory preserves every legacy original"): return false
	var packets: Dictionary = {"entrance.native.json": entrance, "held.native.json": unit, "session.native.json": session, "checkpoint.native.json": session.side_attempt.checkpoint, "story.native.json": protected, "registry.native.json": raw}
	for name: String in packets:
		if not _ot_write_current(name, packets[name]): return false
	if not _ot_raw_current("campaign.store.json", isolated + "campaign.json") or not _ot_raw_current("preferences.store.json", isolated + "preferences.json"): return false
	if FileAccess.file_exists(isolated + "campaign.json.bak"):
		if not _ot_raw_current("campaign.store.json.bak", isolated + "campaign.json.bak"): return false
	var sources: Dictionary = _ot_current_source_pins()
	if sources.is_empty(): return false
	var native: Dictionary = _native_ids()
	var text_ids: Dictionary = {}
	for key: String in native: text_ids[key] = str(native[key])
	var receipt: Dictionary = {"schema_version": 1, "test_only": true, "api_revision": unit.level.local.api_revision, "arrangement": unit.level.local.arrangement.duplicate(true), "actual_entrance_origins": entrance_origins, "actual_held_origins": _observed_origins(), "held_warning": warning, "actual_native_ids_decimal_text": text_ids, "whole_unit_exact_wire_sha256": Exact.stringify(unit).sha256_text(), "session_exact_wire_sha256": Exact.stringify(session).sha256_text(), "raw_store_sha256": FileAccess.get_sha256(isolated + "campaign.json")}
	if not _ot_write_current("receipt.json", receipt): return false
	var manifest: Dictionary = {"schema_version": 1, "kind": "a3-o2-current-challenge-arrangement-1", "test_only": true, "source_pins": sources, "files": _ot_current_files.duplicate(true), "scope": "Actual new Challenge entrance/first warning/current raw Store. Source packet for later closed pure negatives; archive creation itself is not a persistence, mechanics or portrait pass. Actual runner closure remains authoritative."}
	if not _ot_write_current("manifest.json", manifest): return false
	print("O2 CURRENT ARRANGEMENT ARCHIVE: ", _ot_current_archive, "; manifest_sha256=", FileAccess.get_sha256(_ot_current_archive.path_join("manifest.json")))
	return _expect(_same(production.capture_campaign_snapshot(), unit) and _same(production.attempts.state(), session), "CURRENT evidence writes leave the actual native pair/model unchanged")

func _ot_current_source_pins() -> Dictionary:
	var paths: Array[String] = []
	paths.assign(O2_PINS)
	paths.append_array([PRODUCER_PATH, "res://scripts/combat/encounter_arrangement.gd", "res://scripts/combat/difficulty.gd", "res://data/design/difficulty_profiles.json", "res://scripts/campaign/attempts.gd"])
	var pins: Dictionary = {}
	for path: String in paths:
		var digest: String = FileAccess.get_sha256(path)
		if not _expect(digest.length() == 64, "actual CURRENT source exists: " + path): return {}
		pins[path] = digest
		if FileAccess.file_exists(path + ".uid"): pins[path + ".uid"] = FileAccess.get_sha256(path + ".uid")
	return pins

func _ot_write_current(relative: String, actual: Dictionary) -> bool:
	if not _expect(_ot_current_archive.begins_with(OT_CURRENT_ROOT + "/arrangement-current-") and not relative.contains("/") and not relative.contains(".."), "CURRENT writer is separate from immutable legacy FIXTURE_ROOT"): return false
	var path: String = _ot_current_archive.path_join(relative)
	var wire: String = Exact.stringify(actual)
	if not _expect(not wire.is_empty() and not FileAccess.file_exists(path), "new finite CURRENT native wire: " + relative): return false
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not _expect(file != null, "CURRENT archive file opens: " + relative): return false
	file.store_string(wire + "\n")
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if not _expect(error == OK and FileAccess.get_file_as_string(path) == wire + "\n", "CURRENT native wire persists without transformation"): return false
	_ot_current_files[relative] = {"sha256": FileAccess.get_sha256(path), "exact_wire_sha256": wire.sha256_text(), "bytes": FileAccess.get_file_as_bytes(path).size()}
	return true

func _ot_raw_current(relative: String, actual_source: String) -> bool:
	if not _expect(_ot_current_archive.begins_with(OT_CURRENT_ROOT + "/arrangement-current-") and not relative.contains("/") and not relative.contains(".."), "CURRENT raw writer never targets legacy fixtures"): return false
	var target: String = _ot_current_archive.path_join(relative)
	if not _ot_copy_verified(actual_source, target): return false
	_ot_current_files[relative] = {"sha256": FileAccess.get_sha256(target), "bytes": FileAccess.get_file_as_bytes(target).size(), "raw_store_copy": true, "original_user_path": actual_source}
	return true

func _ot_cleanup(label: String) -> bool:
	if not await _dispose_shell(): return false # Producer override exits level in-tree, then Shell.
	return _expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal native five-source cleanup: " + label)

func _ot_report(selector: String, complete: bool, scope: String) -> void:
	_ot_last_scope = {"selector": selector, "scope_complete": complete, "checks": checks, "failures": failures, "native_ticks": _o2_ticks, "fixture_sha256": FileAccess.get_sha256(PRODUCER_PATH), "runtime_sha256": FileAccess.get_sha256("res://scripts/acts/act3/quiet_root_circuit.gd"), "current_archive": _ot_current_archive}
	print("O2 ARRANGEMENT TRANSPORT: ", _ot_last_scope, "; ", scope)

## APPEND-ONLY SOURCE FRAGMENT for the future ONE O2 arrangement test.
## No extends/_initialize/_run/_finish replacement. Unparsed/unexecuted.
## Inherited aliases: QRC, Focused, NativeObservers, O2Geometry, MainScene,
## Codec, Exact, Registry, checks/failures/finished, _expect, _collect_refs,
## _released. Root's dispatcher calls await _run_component(selector), then
## _finish; every _finish/watchdog path must await _component_dispose first.

class FinalCourtLab extends QRC:
	## TEST initial eligibility, not earned canonical court progress.
	const TEST_SPAWN: Vector3 = Vector3(1.2,0.1,-3.0)
	const SAVE_LIMIT: String = "TEST final-court component has no canonical route/save authority"
	@export_enum("standard", "challenge") var component_profile: String = "challenge"

	func contract_error() -> String:
		var spawn: Marker3D = get_node_or_null(spawn_path) as Marker3D
		if level_id != "A3-O2" or position != Vector3.ZERO or basis != Basis.IDENTITY or spawn == null or spawn.position != TEST_SPAWN:
			return "Exact declared TEST final-court root transform/spawn required"
		return _configuration_error

	func _source_entered(id: String) -> bool:
		return SOURCE_COURTS.has(id) and int(SOURCE_COURTS[id]) == 2

	func _on_enter_level() -> void:
		_active = true
		var selector := Arrangement.new(arrangement_definition())
		var descriptor: Dictionary = selector.select_fresh(component_profile)
		_configuration_error = selector.last_error if descriptor.is_empty() else _configure_sources(descriptor,false)
		scenery.call("follow_landmarks",hero.global_position)
		_update_presentation()

	func _advance_clear() -> bool:
		return false # No court clear, checkpoint, completion or fabricated prefix.

	func _update_presentation(quiet: bool = false) -> void:
		super._update_presentation(quiet)
		objective_text = "TEST O2 FINAL GROUND-SLOT EXCHANGE\nREAL ROOT RETURN; LIVE STALKER PRESSURE"

	func snapshot_state() -> Dictionary:
		last_snapshot_error = SAVE_LIMIT
		return {}

	func snapshot_state_for_presentation(_camera: Camera3D,_hud: GameHUD) -> Dictionary:
		last_snapshot_error = SAVE_LIMIT
		return {}

	func snapshot_error(_packet: Dictionary) -> String:
		return SAVE_LIMIT

	func snapshot_error_with_player(_packet: Dictionary,_player: Dictionary) -> String:
		return SAVE_LIMIT

	func restore_state(_packet: Dictionary) -> bool:
		last_snapshot_error = SAVE_LIMIT
		return false

	func _local_snapshot_error(_local: Dictionary) -> String:
		return SAVE_LIMIT

	func _local_snapshot_error_with_player(_local: Dictionary,_player: Dictionary) -> String:
		return SAVE_LIMIT

	func _on_enter_restore_candidate(_local: Dictionary,_player: Dictionary) -> String:
		return SAVE_LIMIT


class ComponentRootResponse extends Focused.NativeRootResponse:
	func follow(proof: Dictionary, record: Dictionary) -> bool:
		var escaped: bool = false
		var returned: bool = false
		var last_dash_end_s: float = -1.0
		var first_segment: bool = true
		for segment: Dictionary in proof.path:
			# The native controller finishes a dash on a real physics boundary.
			# Later actions cannot start before that measured completion.
			var scheduled_start_s: float = maxf(float(segment.start_s), last_dash_end_s)
			if first_segment and segment.kind == "recognition_and_ready":
				# Capturing/restoring the genuine held pair can consume part of
				# this stationary interval. Join it only at the unchanged origin,
				# before its original end; all action deadlines remain unchanged.
				var now_s: float = _scheduler.get_clock()
				if not _expect(segment.from == segment.to and _hero.global_position.distance_to(segment.from) <= 0.02 and now_s < float(segment.end_s), "held observation joins only the first unchanged passive recognition interval", str({"now_s":now_s,"start_s":segment.start_s,"end_s":segment.end_s,"hero_position":_hero.global_position,"origin":segment.from})): return false
				scheduled_start_s = maxf(scheduled_start_s,now_s)
			first_segment = false
			if not await _until(scheduled_start_s, String(segment.kind)+":start"): return false
			if segment.kind in ["escape_dash","positioning_dash"]:
				if not _expect(_hero.global_position.distance_to(segment.from) <= 0.02, "native witness dash begins at its actual recorded world point"): return false
				var direction: Vector3 = segment.to-segment.from
				direction.y = 0
				if not await dash(direction.normalized()): return false
				var actions: Array = _action_records.call()
				var actual: Dictionary = actions.back() if not actions.is_empty() else {}
				var actual_start_s: float = float(actual.started_at_s)
				var actual_end_s: float = float(actual.completed_at_s)
				var resolved_duration_s: float = float(actual.resolved_stats.dash_duration)
				var native_duration_s: float = float(ceili(resolved_duration_s / _tick_s())) * _tick_s()
				var window_safe: bool = actual_end_s < float(record.active_from_s) if segment.kind == "escape_dash" else (actual_start_s >= float(record.active_until_s) and actual_end_s < float(record.recovery_until_s))
				if not _expect(_hero.global_position.distance_to(segment.to) <= 0.02 and actual_start_s >= scheduled_start_s-EPS and actual_start_s <= scheduled_start_s+_tick_s()+EPS and resolved_duration_s > 0.0 and absf((actual_end_s-actual_start_s)-native_duration_s) <= EPS and absf(_scheduler.get_clock()-actual_end_s) <= EPS and absf(_hero.get_world_action_clock()-actual_end_s) <= EPS and window_safe, "actual dash preserves endpoint, separately bounded request tick/native duration and genuine safe window", str({"kind":segment.kind,"planned_start_s":segment.start_s,"planned_end_s":segment.end_s,"scheduled_start_s":scheduled_start_s,"actual_start_s":actual_start_s,"actual_end_s":actual_end_s,"resolved_duration_s":resolved_duration_s,"native_duration_s":native_duration_s,"hero_position":_hero.global_position,"planned_landing":segment.to,"active_from_s":record.active_from_s,"active_until_s":record.active_until_s,"recovery_until_s":record.recovery_until_s})): return false
				last_dash_end_s = actual_end_s
				escaped = escaped or segment.kind == "escape_dash"
				returned = returned or segment.kind == "positioning_dash"
			elif segment.kind == "ordinary_primary":
				var current: Dictionary = _root_source.state()
				var held: Dictionary = _scheduler.reservation_state(String(record.id))
				if not _expect(escaped and returned and current.phase == "recovery" and current.knot_open and held.get("state") == "recovery" and held.geometry == record.geometry and _hero.global_position.distance_to(proof.attack_position) <= 0.02 and float(proof.response_complete_s) < float(record.recovery_until_s) and float(_hero.get_threat_response_state().primary_cooldown_left_s) == 0.0, "real selected return exposes an ordinary-primary recovery opening"): return false
				var direction: Vector3 = _root_source.global_position-_hero.global_position
				direction.y = 0
				var hp_before: float = _root_source.hp
				var damage: float = float(_hero.equipment.resolved_stats().primary_damage)
				var deaths_before: int = int(_death_count.call())
				var actions_before: int = (_action_records.call() as Array).size()
				if not _expect(hp_before > 0.0 and not _root_source.dead and direction.length_squared() > 0.0,"living actual selected Root and primary bearing required"): return false
				var hits: int = _hero.slash(direction.normalized())
				var hp_after: float = maxf(0.0,hp_before-damage)
				var expected_dead: bool = hp_after == 0.0
				var records: Array = _action_records.call()
				var action: Dictionary = records.back() if not records.is_empty() else {}
				if not _expect(hits >= 1 and damage > 0.0 and _root_source.hp == hp_after and _root_source.dead == expected_dead and int(_death_count.call()) == deaths_before+(1 if expected_dead else 0) and records.size() == actions_before+1 and action.get("kind") == "primary" and action.get("hits") == hits and action.get("equipment_ids") == _kit and not CinderPlayer.encode_world_action_record(action,_hero.get_world_action_clock()).is_empty() and not (_fired_kinds.call() as Array).has("blast"), "one genuine ordinary primary records actual kit damage; weak Root may survive",str({"source":_selected_root_id,"hp_before":hp_before,"actual_primary_damage":damage,"hp_after":_root_source.hp,"dead":_root_source.dead,"hits":hits,"clock_s":_scheduler.get_clock()})): return false
				if not await _tick() or not await _presentation(): return false
				var body: CollisionShape3D = _root_source.get_node("BodyCollision") as CollisionShape3D
				var state: Dictionary = _level.call("state")
				var native: Dictionary = _mechanism.state()
				var lifecycle: bool
				if expected_dead:
					lifecycle = state.deaths.has(_selected_root_id) and Codec.read_vector3(state.deaths[_selected_root_id].source_position) == _root_source.global_position and body.disabled and _root_source.collision_layer == 0 and _root_source.collision_mask == 0 and not _root_source.is_in_group("enemies") and native.status == "cancelled" and native.phase == "clear" and native.last_cancel_reason == "source_defeated"
				else:
					lifecycle = not state.deaths.has(_selected_root_id) and not body.disabled and _root_source.collision_layer == 2 and _root_source.collision_mask == 1 and _root_source.is_in_group("enemies") and _root_source.hp == hp_after and native.status == "running" and native.phase == "recovery"
				return _expect(lifecycle and _hero.hp == _starting_hp and _hero.equipment.snapshot() == _kit,"actual hit/death-or-survival settles without synthetic court progress",str({"expected_dead":expected_dead,"root":_root_source.state(),"component":state}))
			elif not await _until(float(segment.end_s), String(segment.kind)+":end"): return false
		return _expect(false, "actual native witness includes one ordinary primary")

const COMPONENT_SELECTED_ROOT: String = "o2-final-east-root"
const COMPONENT_STALKER: String = "o2-final-stalker"
const COMPONENT_SELECTORS: Array[String] = ["--component-neutral","--component-short","--component-slow","--component-weak","--component-portrait"]
const COMPONENT_NATIVE_LIMIT: int = 1200
var _component_main: Node
var _component_level: FinalCourtLab
var _component_hero: CinderPlayer
var _component_scheduler: CinderThreatScheduler
var _component_root: CinderAct3RootLatcher
var _component_stalker: CinderAct3SunboundStalker
var _component_barrier: NativeObservers.PostActorBarrier
var _component_scene: PackedScene
var _component_scene_path: String = ""
var _component_kit: Dictionary = {}
var _component_start_hp: float = 0.0
var _component_origins: Dictionary = {}
var _component_actions: Array[Dictionary] = []
var _component_fired: Array[String] = []
var _component_death_ids: Array[String] = []
var _component_events: int = 0
var _component_progress: Array[String] = []
var _component_ticks: int = 0
var _component_phases: Dictionary = {}
var _component_pressure: Dictionary = {}
var _component_held_samples: Array[Dictionary] = []
var _component_refs: Array[WeakRef] = []
var _component_seen_nodes: Dictionary = {}
var _component_callbacks: Array[Array] = []
var _component_running: bool = false
var _component_disposing: bool = false
var _component_draw_seen: bool = false
var _component_portrait_path: String = ""
var _component_host_expired: bool = false
var _component_probe_done: bool = false

func _run_component(selector: String) -> bool:
	if not _expect(selector in COMPONENT_SELECTORS,"one explicit focused TEST component selector",selector): return false
	if not _expect(QRC.ROUTE_API == "act3-quiet-root-circuit-3","component requires the promoted reviewed current arrangement reader"): return false
	if not _expect(not is_instance_valid(_component_main) and not is_instance_valid(production),"component begins without a production or prior component host"): return false
	root.size = Vector2i(340,736)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if selector == "--component-portrait" and not _expect(DisplayServer.get_name() != "headless","component portrait requires actual graphical rendering"): return false
	_component_running = true
	_component_host_expired = false
	create_timer(600.0,true,false,true).timeout.connect(_component_host_timeout,CONNECT_ONE_SHOT)
	var passed: bool = await _component_case(selector)
	var retired: bool = await _component_dispose()
	_component_running = false
	print("O2 COMPONENT: selector=",selector,"; returned=",passed and retired,"; native_ticks=",_component_ticks,"; phases=",_component_phases.keys(),"; actual_stalker_pressure=",not _component_pressure.is_empty(),"; portrait=",_component_portrait_path,"; declared final-only component, no parent earned history/save/transport credit")
	return passed and retired

func _component_case(selector: String) -> bool:
	_component_ticks = 0
	_component_events = 0
	_component_actions.clear(); _component_fired.clear(); _component_death_ids.clear()
	_component_progress.clear(); _component_phases.clear(); _component_pressure.clear(); _component_held_samples.clear()
	_component_refs.clear(); _component_seen_nodes.clear(); _component_callbacks.clear()
	_component_main = MainScene.instantiate()
	if not node_added.is_connected(_component_watch_node): node_added.connect(_component_watch_node)
	root.add_child(_component_main)
	_component_main.call("open_bench")
	for _frame: int in range(120):
		if paused: break
		await process_frame
	if not _expect(paused and _component_main.call("is_lab_level") and get_nodes_in_group("enemies").is_empty(),"actual enemy-free paused Main allows legal initial kit selection"): return false
	var lab_hero: CinderPlayer = _component_main.get("player") as CinderPlayer
	var kit: Dictionary = {"jacket":"CLOTH-J0","pants":"CLOTH-P0","shoes":"CLOTH-S0","weapon":"WEAPON-01"}
	if selector == "--component-short": kit.weapon = "WEAPON-03"
	if selector == "--component-weak": kit.weapon = "WEAPON-02"
	if selector == "--component-slow": kit.pants = "CLOTH-P2"; kit.shoes = "CLOTH-S2"
	for slot: String in ["jacket","pants","shoes","weapon"]:
		if not _expect(lab_hero.equip_item(kit[slot]),"public initial enemy-free equip: "+kit[slot]): return false
	if not _expect(lab_hero.equipment.snapshot() == kit,"actual native lab holds the declared static kit"): return false
	var packed: Dictionary = _component_make_scene()
	if not _expect(String(packed.error).is_empty(),"unique in-memory TEST component packs without a scene file",String(packed.error)): return false
	_component_scene = packed.scene
	_component_scene_path = packed.path
	if not _expect(_component_main.call("load_level_scene",_component_scene_path),"actual public Main constructs declared component",String(_component_main.get("level_load_error"))): return false
	_component_main.call("open_bench") # No physics yield after public fresh load.
	_component_level = _component_main.get("active_level") as FinalCourtLab
	_component_hero = _component_main.get("player") as CinderPlayer
	_component_scheduler = _component_level.threat_scheduler if _component_level != null else null
	if not _expect(_component_level != null and _component_scheduler != null and paused and _component_level.contract_error().is_empty() and _component_level.hero == _component_hero and _component_level.shared_shell == _component_main and _component_scheduler.get_clock() == 0.0 and _component_hero.get_world_action_clock() == 0.0 and _component_hero.global_position == FinalCourtLab.TEST_SPAWN and _component_hero.get_world_action_records().is_empty() and _component_hero.equipment.snapshot() == kit and _component_hero.hp == _component_hero.max_hp and not _component_hero.dead,"TEST construction uses one genuine native Hero/world/zero-clock spawn; no post-entry state seed"): return false
	_component_kit = _component_hero.equipment.snapshot()
	_component_start_hp = _component_hero.hp
	_component_origins = _component_level.selected_source_positions()
	_component_root = _component_level.sources[COMPONENT_SELECTED_ROOT] as CinderAct3RootLatcher
	_component_stalker = _component_level.sources[COMPONENT_STALKER] as CinderAct3SunboundStalker
	var bindings: Dictionary = _component_level.scheduler_bindings()
	if not _expect(_component_level.sources.size() == 5 and bindings.owners.size() == 5 and bindings.actors.get("hero") == _component_hero and bindings.floors["forest-floor"].safe_rect == QRC.FLOOR_RECT and _component_origins[COMPONENT_SELECTED_ROOT] == Vector3(0,0,-4.5) and _component_origins[COMPONENT_STALKER] == Vector3(1.2,0.1,-6) and _component_scheduler.encounter_profile().id == "challenge","fresh Challenge complete native maps exchange only final ground slots"): return false
	for id: String in QRC.SOURCE_IDS:
		var source: Node3D = _component_level.sources[id]
		var root_kind: bool = QRC.SOURCE_KINDS[id] == "root"
		var owner: Node3D = source.call("get_mechanism") as Node3D if root_kind else source
		var owner_id: String = id+"/attack" if root_kind else id
		if not _expect(source.global_position == _component_origins[id] and source.get_world_3d() == _component_hero.get_world_3d() and source.get("hp") == (20.0 if root_kind else 36.0) and not source.get("dead") and source.is_in_group("enemies") and bindings.owners.get(owner_id) == owner and source.is_physics_processing() == (int(QRC.SOURCE_COURTS[id]) == 2),"actual final eligibility/immutable native owner/home: "+id): return false
		_component_connect(source,"state_changed",_component_event1)
		if root_kind:
			_component_connect(source,"died",_component_on_death.bind(id))
			_component_connect(owner,"state_changed",_component_event1)
	_component_connect(_component_hero,"world_action_executed",_component_on_action)
	_component_connect(_component_hero,"fired",_component_on_fired)
	_component_connect(_component_level,"checkpoint_requested",_component_on_checkpoint)
	_component_connect(_component_level,"completion_requested",_component_on_completion)
	_component_connect(_component_level,"contact_exit_requested",_component_on_contact)
	if not _expect(_component_level.snapshot_state().is_empty() and _component_level.last_snapshot_error == FinalCourtLab.SAVE_LIMIT and _component_level.current_checkpoint() == {"id":"","kind":""} and not _component_level.is_completed(),"component explicitly refuses parent packets and contains no earned checkpoint/completion"): return false
	_component_barrier = NativeObservers.PostActorBarrier.new()
	_component_barrier.name = "TEST_O2_ArrangementPostActorAndPresentation"
	root.add_child(_component_barrier)
	for _frame: int in range(4): await process_frame
	_component_main.call("resume_lab")
	for _tick_index: int in range(8):
		if _component_hero.is_on_floor(): break
		if not await _component_tick(): return false
	if not _expect(not paused and _component_hero.is_on_floor(),"actual native Hero grounds at declared component spawn"): return false
	var warning: Dictionary = await _component_warning()
	if warning.is_empty(): return false
	if selector == "--component-portrait":
		if not await _component_presentation(): return false
		_component_main.call("open_bench")
		for _frame: int in range(120):
			if paused: break
			await process_frame
		return await _component_portrait()
	var driver := ComponentRootResponse.new()
	driver.configure(_component_hero,_component_level,_component_scheduler,_component_root,COMPONENT_SELECTED_ROOT,_component_kit,_component_action_records,_component_fired_kinds,_component_selected_deaths,_component_tick,_component_presentation,_expect)
	if not await driver.follow(warning.proof,warning.record): return false
	for phase: String in ["warning","lock","active","recovery"]:
		if not _expect(_component_phases.has(phase),"actual selected Root phase observed: "+phase,str(_component_phases)): return false
	if not _expect(not _component_pressure.is_empty() and _component_pressure.get("mixed_held",false) and _component_stalker.is_physics_processing() and not _component_stalker.dead and _component_stalker.hp > 0.0 and _component_stalker.is_in_group("enemies") and not String(_component_stalker.state().last_cancel_reason).begins_with("required_view_unsafe"),"living eligible optional Stalker produced a real native cycle/lease pressure observation without render-guard cancellation",str({"actual_pressure":_component_pressure,"current":_component_stalker.state(),"held_samples":_component_held_samples})): return false
	return _component_integrity("completed ordinary component opportunity")

func _component_make_scene() -> Dictionary:
	var declared := FinalCourtLab.new()
	declared.name = "TEST_O2_FinalCourtArrangement"
	declared.level_id = "A3-O2" # Act3 presentation only, no campaign registry row.
	declared.component_profile = "challenge"
	var spawn := Marker3D.new()
	spawn.name = "PlayerSpawn"
	spawn.position = FinalCourtLab.TEST_SPAWN
	declared.add_child(spawn)
	spawn.owner = declared
	var scene := PackedScene.new()
	var error: Error = scene.pack(declared)
	declared.free()
	if error != OK: return {"error":"Native component pack declined"}
	var path: String = "res://tests/acts/act3/__TEST_o2_final_arrangement_%d_%d.tscn" % [OS.get_process_id(),Time.get_ticks_usec()]
	if FileAccess.file_exists(path) or ResourceLoader.has_cached(path): return {"error":"TEST cache path already occupied"}
	scene.take_over_path(path)
	if not ResourceLoader.exists(path,"PackedScene") or ResourceLoader.get_cached_ref(path) != scene: return {"error":"Actual cached PackedScene identity unavailable"}
	return {"error":"", "scene":scene, "path":path}

func _component_warning() -> Dictionary:
	# First native source tick has precedence over any decision. This component
	# starts near the changed court and supplies no approach/pose repair.
	if not await _component_tick(): return {}
	for _index: int in range(480):
		var state: Dictionary = _component_root.state()
		var proof: Dictionary = state.proof
		var usable: bool = state.phase == "warning" and proof.get("path") is Array and not proof.path.is_empty() and proof.path[0].from.distance_to(_component_hero.global_position) <= 0.02
		if usable:
			for segment: Dictionary in proof.path:
				if segment.kind == "escape_dash":
					usable = _component_scheduler.get_clock() <= float(segment.start_s)+0.00001
					break
		if usable:
			var native: Dictionary = state.mechanism
			var record: Dictionary = _component_scheduler.reservation_state(String(native.reservation_id))
			if not _expect(not record.is_empty() and record.armed and state.source_id == COMPONENT_SELECTED_ROOT+"/attack" and record.source_instance_id == _component_root.get_mechanism().get_instance_id() and record.state == "warning" and record.geometry.kind == "crescent" and record.geometry.origin == _component_origins[COMPONENT_SELECTED_ROOT] and record.geometry == state.geometry and proof.get("accepted",false) and not proof.get("uses_blast",true) and not proof.get("uses_invulnerability",true) and _component_root.get_selected_response().landing == proof.landing and _component_root.get_selected_response().attack_position == proof.attack_position,"native forward Root warning holds genuine current-point crescent/union witness",str(state)): return {}
			var path: Array[Dictionary] = []
			for segment: Dictionary in proof.path: path.append(segment)
			if not _expect(not O2Geometry.timed_path_hits(record.geometry,path,float(record.active_from_s),float(record.active_until_s),CinderThreatScheduler.CAPSULE_RADIUS+CinderThreatScheduler.SKIN),"selected unchanged path avoids the actual active crescent without immunity"): return {}
			print("O2 COMPONENT WARNING: actual forward Root at ",_component_scheduler.get_clock(),"; held native sources=",_component_held_samples)
			return {"proof":proof.duplicate(true),"record":record.duplicate(true)}
		if not await _component_tick(): return {}
	_expect(false,"bounded actual forward-Root warning from the declared current Hero point",str({"hero":_component_hero.global_position,"root":_component_root.state(),"stalker":_component_stalker.state(),"camera_error":_component_level.last_camera_framing_error,"held":_component_held_samples}))
	return {}

func _component_tick() -> bool:
	if finished or _component_host_expired or not is_instance_valid(_component_barrier): return false
	if not _expect(not paused,"component action needs actual live native observer/world"): return false
	_component_barrier.waiting = true
	_component_barrier.expiration = Engine.get_process_frames()+120
	var boundary: String = await _component_barrier.observed
	if finished or _component_host_expired: return false
	_component_ticks += 1
	if not _expect(boundary == "post_actor_physics" and not paused and _component_ticks <= COMPONENT_NATIVE_LIMIT,"bounded actual post-actor component physics boundary",str({"boundary":boundary,"paused":paused,"ticks":_component_ticks,"clock_s":_component_scheduler.get_clock(),"window_focused":root.has_focus()})): return false
	_component_observe_pressure()
	return _component_integrity("post-actor tick")

func _component_presentation() -> bool:
	if finished or _component_host_expired or not is_instance_valid(_component_barrier): return false
	_component_barrier.presentation_waiting = true
	_component_barrier.presentation_expiration = Engine.get_process_frames()+120
	var boundary: String = await _component_barrier.presentation_observed
	if finished or _component_host_expired: return false
	return _expect(boundary == "post_presentation_process" and not paused,"actual post-Main Camera/HUD process precedes component view sample",str({"boundary":boundary,"paused":paused})) and _component_integrity("post-presentation process")

func _component_integrity(label: String) -> bool:
	if not is_instance_valid(_component_level) or not is_instance_valid(_component_hero) or not is_instance_valid(_component_scheduler): return _expect(false,"actual component nodes remain valid: "+label)
	var state: Dictionary = _component_level.state()
	var fixed: bool = true
	for id: String in QRC.ROOT_IDS:
		fixed = fixed and (_component_level.sources[id] as Node3D).global_position == _component_origins[id]
	var clocks: bool = absf(_component_hero.get_world_action_clock()-_component_scheduler.get_clock()) <= 0.00001
	var no_progress: bool = state.active_court == 0 and state.clears.is_empty() and _component_progress.is_empty() and _component_level.current_checkpoint() == {"id":"","kind":""} and not _component_level.is_completed() and state.exit_state == "clear" and state.contact.is_empty()
	return _expect(not _component_hero.dead and _component_hero.hp == _component_start_hp and _component_hero.equipment.snapshot() == _component_kit and not _component_fired.has("blast") and not _component_fired.has("hurt") and state.configuration_error.is_empty() and fixed and clocks and no_progress and _component_stalker.is_physics_processing() and not _component_stalker.dead and _component_stalker.hp > 0.0 and _component_stalker.is_in_group("enemies"),"real component preserves full HP/kit/native clocks/fixed roots/living pressure/no earned progress: "+label,str({"hero_hp":_component_hero.hp,"starting_hp":_component_start_hp,"dead":_component_hero.dead,"kit":_component_hero.equipment.snapshot(),"expected_kit":_component_kit,"hero_clock_s":_component_hero.get_world_action_clock(),"scheduler_clock_s":_component_scheduler.get_clock(),"fixed":fixed,"configuration_error":state.configuration_error,"stalker":_component_stalker.state(),"component_progress":_component_progress}))

func _component_observe_pressure() -> void:
	var root_state: Dictionary = _component_root.state()
	if root_state.phase in ["warning","lock","active","recovery"]:
		_component_phases[root_state.phase] = {"clock_s":_component_scheduler.get_clock(),"cycle":root_state.mechanism.cycle,"reservation_id":root_state.mechanism.reservation_id}
	var all_held: Array = []
	for id: String in QRC.SOURCE_IDS:
		var source: Node3D = _component_level.sources[id]
		var owner: Node3D = source.call("get_mechanism") as Node3D if QRC.SOURCE_KINDS[id] == "root" else source
		var control: Dictionary = _component_scheduler.source_control_state(owner)
		for lease: Dictionary in control.get("reservations",[]):
			all_held.append({"owner_id":id+"/attack" if QRC.SOURCE_KINDS[id] == "root" else id,"owner_instance_id_text":str(owner.get_instance_id()),"id":lease.id,"state":lease.state})
	if _component_held_samples.size() < 24 and (_component_held_samples.is_empty() or _component_held_samples.back().sources != all_held):
		_component_held_samples.append({"clock_s":_component_scheduler.get_clock(),"sources":all_held})
	var actual: Dictionary = _component_stalker.state()
	if not _component_probe_done and actual.last_rejection == "Finite bounded native threat/response values required":
		_component_probe_done = true
		_component_probe_bound_inputs(actual)
	var control: Dictionary = _component_scheduler.source_control_state(_component_stalker)
	for lease: Dictionary in control.get("reservations",[]):
		if actual.cycle >= 1 and actual.phase in ["warning","lock","active","recovery"] and actual.stable_id == COMPONENT_STALKER and control.source_instance_id == _component_stalker.get_instance_id() and lease.source_instance_id == _component_stalker.get_instance_id() and lease.id == actual.reservation_id and lease.armed and lease.profile_id == "challenge" and actual.clock_s == _component_scheduler.get_clock() and control.clock_s == _component_scheduler.get_clock():
			var mixed_held: bool = false
			for participant: Dictionary in all_held:
				if participant.owner_id != COMPONENT_STALKER and String(participant.owner_id).ends_with("/attack"): mixed_held = true
			if _component_pressure.is_empty() or mixed_held:
				_component_pressure = {"clock_s":_component_scheduler.get_clock(),"phase":actual.phase,"cycle":actual.cycle,"reservation_id":lease.id,"geometry":lease.geometry.duplicate(true),"commit":actual.commit.duplicate(true),"cooldown_until_s":actual.cooldown_until_s,"position":actual.position,"mixed_held":mixed_held,"sources":all_held.duplicate(true)}

func _component_action_records() -> Array[Dictionary]: return _component_actions
func _component_fired_kinds() -> Array[String]: return _component_fired
func _component_selected_deaths() -> int: return _component_death_ids.count(COMPONENT_SELECTED_ROOT)
func _component_on_action(record: Dictionary) -> void: _component_actions.append(record.duplicate(true))
func _component_on_fired(kind: String) -> void: _component_fired.append(kind)
func _component_on_death(_where: Vector3,id: String) -> void: _component_death_ids.append(id)
func _component_event1(_value: Variant) -> void: _component_events += 1
func _component_on_checkpoint(_id: String,key: String,_kind: String) -> void: _component_progress.append("checkpoint:"+key)
func _component_on_completion(_id: String,key: String) -> void: _component_progress.append("completion:"+key)
func _component_on_contact(_id: String,key: String) -> void: _component_progress.append("contact:"+key)

func _component_connect(node: Node,signal_name: String,callback: Callable) -> void:
	node.connect(signal_name,callback)
	_component_callbacks.append([node,signal_name,callback])

func _component_watch_node(node: Node) -> void:
	if not is_instance_valid(_component_main) or (node != _component_main and not _component_main.is_ancestor_of(node)): return
	var id: String = str(node.get_instance_id())
	if not _component_seen_nodes.has(id):
		_component_seen_nodes[id] = true
		_component_refs.append(weakref(node))

func _component_host_timeout() -> void:
	if not _component_running or finished: return
	_component_host_expired = true
	_expect(false,"bounded component host watchdog; no physics/render/focus bypass")
	if is_instance_valid(_component_barrier):
		_component_barrier.call("_wake","component_host_timeout")
		_component_barrier.call("_wake_presentation","component_host_timeout")

func _component_dispose() -> bool:
	if _component_disposing: return false
	_component_disposing = true
	if RenderingServer.frame_post_draw.is_connected(_component_on_draw): RenderingServer.frame_post_draw.disconnect(_component_on_draw)
	if node_added.is_connected(_component_watch_node): node_added.disconnect(_component_watch_node)
	for connection: Array in _component_callbacks:
		var node: Node = connection[0] as Node
		if is_instance_valid(node) and node.is_connected(connection[1],connection[2]): node.disconnect(connection[1],connection[2])
	_component_callbacks.clear()
	var released_control: bool = true
	if is_instance_valid(_component_level) and _component_level.is_inside_tree():
		_component_level.exit_level() # Public real cancellation while sources live.
		if is_instance_valid(_component_scheduler):
			var bindings: Dictionary = _component_level.scheduler_bindings()
			for owner: Node3D in bindings.owners.values():
				var raw_control: Dictionary = _component_scheduler.source_control_state(owner)
				released_control = released_control and not raw_control.is_empty() and raw_control.reservations.is_empty()
	if is_instance_valid(_component_main): _component_main.queue_free()
	_component_main = null
	if is_instance_valid(_component_barrier):
		_component_barrier.call("_wake","component_dispose")
		_component_barrier.call("_wake_presentation","component_dispose")
		_component_refs.append(weakref(_component_barrier))
		_component_barrier.queue_free() # Safe if the caller resumed inside emit.
	_component_barrier = null
	var scene_ref: WeakRef = weakref(_component_scene) if _component_scene != null else null
	_component_scene = null
	var released: bool = false
	for _frame: int in range(120):
		await process_frame
		released = true
		for reference: WeakRef in _component_refs:
			if reference.get_ref() != null: released = false; break
		if released: break
	var no_cache: bool = _component_scene_path.is_empty() or not ResourceLoader.has_cached(_component_scene_path)
	var scene_gone: bool = scene_ref == null or scene_ref.get_ref() == null
	_component_level = null; _component_hero = null; _component_scheduler = null
	_component_root = null; _component_stalker = null
	_component_disposing = false
	return _expect(released_control and released and scene_gone and no_cache and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(),"public component exit cancels real owners; all Main/world/actors/cues/observer/cache retire",str({"owner_leases_empty":released_control,"nodes_freed":released,"scene_freed":scene_gone,"test_cache_absent":no_cache}))

func _component_native_observation() -> Dictionary:
	var bindings: Dictionary = _component_level.scheduler_bindings()
	var actors: Dictionary = {}
	for id: String in QRC.SOURCE_IDS:
		var source: Node3D = _component_level.sources[id]
		var saved: Dictionary = source.call("snapshot_state",bindings) if QRC.SOURCE_KINDS[id] == "root" else source.call("snapshot_state")
		if saved.is_empty(): return {}
		actors[id] = saved
	var player: Dictionary = _component_hero.snapshot_state()
	var scheduler: Dictionary = _component_scheduler.snapshot_state(bindings)
	if player.is_empty() or scheduler.is_empty(): return {}
	return {"player":player,"scheduler":scheduler,"native_sources":actors,"declared_component":_component_level.state(),"actions":_component_actions.duplicate(true),"fired":_component_fired.duplicate(),"deaths":_component_death_ids.duplicate(),"events":_component_events,"progress":_component_progress.duplicate(),"input":_component_main.call("get_input_observation_state")}

func _component_optics_stamp() -> Dictionary:
	var camera: Camera3D = _component_main.get("camera") as Camera3D
	var hud: GameHUD = _component_main.get("hud") as GameHUD
	var labels: Array = []
	_component_labels(hud,labels)
	return {"camera":[camera.global_transform,camera.projection,camera.keep_aspect,camera.size,camera.near,camera.far,camera.h_offset,camera.v_offset,camera.frustum_offset,camera.cull_mask],"hud":[hud.visible,hud.combat_safe_rect(),labels]}

func _component_labels(node: Node,records: Array) -> void:
	if node is Label:
		var label: Label = node as Label
		records.append([String(_component_main.get_path_to(label)),label.text,label.is_visible_in_tree(),label.global_position,label.size,label.get_theme_font_size("font_size")])
	for child: Node in node.get_children(): _component_labels(child,records)

func _component_render_stamp(node: Node,records: Array) -> void:
	if node is Node3D:
		var physical: Node3D = node as Node3D
		var record: Array = [String(_component_level.get_path_to(node)),str(node.get_instance_id()),physical.transform,physical.global_transform,physical.visible,physical.is_visible_in_tree()]
		if node is CollisionObject3D:
			var body: CollisionObject3D = node as CollisionObject3D
			record.append_array([body.collision_layer,body.collision_mask,node.is_in_group("enemies")])
		if node is CollisionShape3D:
			var collision: CollisionShape3D = node as CollisionShape3D
			record.append_array([collision.disabled,str(collision.shape.get_instance_id()) if collision.shape != null else ""])
		if node is MeshInstance3D:
			var mesh: MeshInstance3D = node as MeshInstance3D
			record.append_array([str(mesh.mesh.get_instance_id()) if mesh.mesh != null else "",str(mesh.material_override.get_instance_id()) if mesh.material_override != null else "",mesh.layers])
		if node is Sprite3D:
			var sprite: Sprite3D = node as Sprite3D
			record.append_array([str(sprite.texture.get_instance_id()) if sprite.texture != null else "",sprite.pixel_size,sprite.offset,sprite.modulate,sprite.layers])
		records.append(record)
	for child: Node in node.get_children(): _component_render_stamp(child,records)

func _component_portrait() -> bool:
	var hud: GameHUD = _component_main.get("hud") as GameHUD
	var bench: CanvasLayer = _component_main.get("bench") as CanvasLayer
	var camera: Camera3D = _component_main.get("camera") as Camera3D
	if not _expect(paused and not _component_main.call("is_pause_requested") and hud != null and hud.visible and bench != null and camera == _component_hero.get_viewport().get_camera_3d(),"actual paused Main/native Camera/HUD is the component's displayed context"): return false
	for _frame: int in range(2): await process_frame
	var problem: String = _component_level.candidate_presentation_error(camera,hud)
	var before: Dictionary = _component_native_observation()
	if not _expect(problem.is_empty() and not before.is_empty(),"real complete current component/actual Hero view validates before native portrait",problem): return false
	var physical: PackedByteArray = var_to_bytes(before)
	var input: PackedByteArray = var_to_bytes(_component_main.call("get_input_observation_state"))
	var optics: PackedByteArray = var_to_bytes(_component_optics_stamp())
	var render_before: Array = []
	_component_render_stamp(_component_level,render_before)
	var render_bytes: PackedByteArray = var_to_bytes(render_before)
	var bench_visible: bool = bench.visible
	hud.hide_overlay() # Public TEST presentation exclusion; simulation stays paused.
	bench.visible = false
	_component_draw_seen = false
	RenderingServer.frame_post_draw.connect(_component_on_draw)
	for _frame: int in range(120):
		await process_frame
		if finished or _component_host_expired or not is_instance_valid(_component_main): break
		if _component_draw_seen: break
	if RenderingServer.frame_post_draw.is_connected(_component_on_draw): RenderingServer.frame_post_draw.disconnect(_component_on_draw)
	var image: Image = root.get_texture().get_image() if _component_draw_seen else null
	# Restore presentation through the public HUD method BEFORE any return.
	if is_instance_valid(hud): hud.show_pause()
	if is_instance_valid(bench): bench.visible = bench_visible
	if finished or _component_host_expired or not is_instance_valid(_component_main): return false
	var after: Dictionary = _component_native_observation()
	var render_after: Array = []
	_component_render_stamp(_component_level,render_after)
	problem = _component_level.candidate_presentation_error(camera,hud)
	var unchanged: bool = not after.is_empty() and physical == var_to_bytes(after) and input == var_to_bytes(_component_main.call("get_input_observation_state")) and optics == var_to_bytes(_component_optics_stamp()) and render_bytes == var_to_bytes(render_after)
	if not _expect(_component_draw_seen and image != null and image.get_size().x in [339,340] and image.get_size().y == 736 and paused and not _component_main.call("is_pause_requested") and bench.visible == bench_visible and hud.visible and unchanged and problem.is_empty(),"actual native paused component portrait preserves full leaf states/input/Camera/HUD/render identities/events and restores overlay",str({"draw_observed":_component_draw_seen,"image_size":image.get_size() if image != null else Vector2i.ZERO,"unchanged":unchanged,"optical_error":problem})): return false
	var folder: String = "res://captures/act3/quiet-root-circuit/arrangement-component-%d-%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	_component_portrait_path = folder.path_join("01-declared-challenge-held-forward-root.png")
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK and image.save_png(_component_portrait_path) == OK,"original component PNG is written only after a real draw"): return false
	var receipt: Dictionary = {"schema_version":1,"test_only":true,"kind":"a3-o2-declared-final-court-component-portrait-1","source_candidate_sha256":"c56829b59d5f2185110a166993fcb14c53be050ad6fac72ec5dd207be5fc424c","runtime_sha256":FileAccess.get_sha256("res://scripts/acts/act3/quiet_root_circuit.gd"),"fixture_sha256":FileAccess.get_sha256(PRODUCER_PATH),"png_sha256":FileAccess.get_sha256(_component_portrait_path),"actual_dimensions":[image.get_size().x,image.get_size().y],"clock_s":_component_scheduler.get_clock(),"selected_root":COMPONENT_SELECTED_ROOT,"actual_selected_phase":_component_root.state().phase,"actual_stalker_phase":_component_stalker.state().phase,"actual_stalker_cycle":_component_stalker.state().cycle,"native_pressure_observed":not _component_pressure.is_empty(),"parent_route_or_save_credit":false,"paused_without_tick":true,"native_leaf_input_camera_hud_events_unchanged":unchanged,"test_presentation_exclusion":"public HUD.hide_overlay plus bench visible=false; HUD.show_pause and bench restored before comparison; no native source hidden","scope":"one current declared mixed-court warning frame; no parent earned arrival/checkpoint/legacy/Save/Continue/Retry/route/pacing claim"}
	var wire: String = Exact.stringify(receipt)
	if not _expect(not wire.is_empty(),"finite exact component portrait receipt"): return false
	var output: FileAccess = FileAccess.open(_component_portrait_path+".json",FileAccess.WRITE)
	if not _expect(output != null,"new component portrait receipt opens"): return false
	output.store_string(wire+"\n"); output.close()
	print("O2 COMPONENT PORTRAIT: ",ProjectSettings.globalize_path(_component_portrait_path))
	return true

func _component_on_draw() -> void:
	_component_draw_seen = true

## Diagnostic only: reconstruct the unchanged caller threat from public native
## state/constants and inspect the public response. This local encoder grants no
## admission, preview, clock, snapshot or safety authority and changes no input.
func _component_probe_bound_inputs(actual: Dictionary) -> void:
	var threat: Dictionary = {"role":actual.resolved_role,"source_stationary":false,"opening_stationary":true,"cooldown_remaining_s":0.0,"lunge":{"direction":actual.facing,"speed":CinderAct3SunboundStalker.TUNING.lunge_speed,"distance":CinderAct3SunboundStalker.TUNING.lunge_distance,"damage_radius":CinderAct3SunboundStalker.TUNING.damage_radius,"body_collision_path":"BodyCollision"}}
	var response: Dictionary = _component_level.combat_response(COMPONENT_STALKER).duplicate()
	for key: String in ["actor","world_root","floor_regions"]: response.erase(key)
	for label: String in ["threat","response"]:
		var value: Dictionary = threat if label == "threat" else response
		var encoded: Dictionary = _component_probe_encode(value,label,0,[262144])
		var wire: String = Exact.stringify(encoded.value) if encoded.get("accepted",false) else ""
		print("O2 COMPONENT BOUND PROBE: public ",label,"; local_native_encoding=",encoded.get("accepted",false),"; first_error=",encoded.get("error",""),"; exact_wire_bytes=",wire.to_utf8_buffer().size(),"; encoded_codec_error=",Codec.value_error(encoded.get("value")),"; public_values=",value)

func _component_probe_encode(value: Variant,path: String,depth: int,budget: Array[int]) -> Dictionary:
	budget[0] -= 1
	if depth > 32 or budget[0] < 0: return {"accepted":false,"error":path+": native depth/node budget"}
	var encoded: Variant = value
	match typeof(value):
		TYPE_ARRAY,TYPE_DICTIONARY:
			if value.size() > 16384: return {"accepted":false,"error":path+": native container limit"}
			var children: Variant = [] if value is Array else {}
			for key: Variant in (range(value.size()) if value is Array else value.keys()):
				if value is Dictionary and not key is String: return {"accepted":false,"error":path+": nonstring key "+type_string(typeof(key))}
				var child: Dictionary = _component_probe_encode(value[key],path+"/"+str(key),depth+1,budget)
				if not child.get("accepted",false): return child
				if value is Array: children.append(child.value)
				else: children[key] = child.value
			encoded = ["Array" if value is Array else "Dictionary",children]
		TYPE_VECTOR3: encoded = ["Vector3",value.x,value.y,value.z]
		TYPE_VECTOR2: encoded = ["Vector2",value.x,value.y]
		TYPE_RECT2: encoded = ["Rect2",value.position.x,value.position.y,value.size.x,value.size.y]
		TYPE_BASIS: encoded = ["Basis",Codec.vector3(value.x),Codec.vector3(value.y),Codec.vector3(value.z)]
		TYPE_TRANSFORM3D: encoded = ["Transform3D",{"basis":[Codec.vector3(value.basis.x),Codec.vector3(value.basis.y),Codec.vector3(value.basis.z)],"origin":Codec.vector3(value.origin)}]
		TYPE_NIL,TYPE_BOOL,TYPE_STRING,TYPE_INT,TYPE_FLOAT:
			var error: String = Codec.value_error(value)
			if not error.is_empty(): return {"accepted":false,"error":path+": "+error}
		_: return {"accepted":false,"error":path+": unsupported native type "+type_string(typeof(value))}
	return {"accepted":true,"value":encoded}
