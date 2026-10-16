extends "res://tests/acts/act3/crystalman_rule_room_smoke.gd"
## INERT until Root promotes this exact .txt to producer.gd and seals it.
## NEW execution of untouched original captured API2, not historical reuse.
## Declared stage2 prior regular deaths are TEST history. Current native phase,
## floor, Player, Gate, Scheduler and captured Playback are genuine.
## No route/tether defeat, packet edits, private pose/resources/clock/phase writes.
const ProducerMain = preload("res://.cinder/captured-assisted-policy-audit-20261015/producer-prepare/profile_main.gd")
const ProducerStore = preload("res://scripts/campaign/save_store.gd")
const ProducerPhase = preload("res://scripts/acts/act3/crystalman_capture_phase.gd")
const ProducerCodec = preload("res://scripts/acts/act3/crystalman_capture_codec.gd")
const PARENT_ROOM: String = "res://tests/acts/act3/fixtures/crystalman_declared_2.tscn"
var _outer: CinderLevel
var _producer_profile: String = ""
var _producer_out: String = ""
var _producer_store_root: String = ""
var _producer_sources: Array[String] = []
var _producer_before: Dictionary = {}
var _producer_rows: Array[Dictionary] = []
var _producer_packets: Array[Dictionary] = []
var _producer_unsupported: Array[Dictionary] = []
var _producer_first_failure: Dictionary = {}
var _producer_complete: bool = false
var _producer_finishing: bool = false

func _run() -> void:
	_producer_out = OS.get_environment("CINDER_CAPTURED_ORIGINAL_OUTPUT")
	_producer_store_root = "user://test-captured-original-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	var supplied: Variant = JSON.parse_string(OS.get_environment("CINDER_CAPTURED_ORIGINAL_SOURCES"))
	if supplied is Array:
		for item: Variant in supplied:
			if item is String: _producer_sources.append(item)
	_producer_before = _producer_source_state()
	create_timer(150.0, true).timeout.connect(func() -> void:
		if not _producer_finishing:
			_expect(false, "150-second native producer watchdog")
			_producer_finish.call_deferred())
	root.size = Vector2i(340, 736)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if not _expect(not _producer_out.is_empty() and not _producer_sources.is_empty() and OS.get_cmdline_user_args().is_empty(), "Explicit unique output and named pins; no scenario mutation"):
		await _producer_finish(); return
	for profile: String in ["assisted", "standard"]:
		_producer_profile = profile
		if not await _open(): await _producer_finish(); return
		# No native tick has run. This actual configured gen0 may be written only
		# if the original native codec accepts it. Never manufacture a fallback.
		if not await _producer_capture("gen0", false): await _producer_finish(); return
		_game.call("resume_lab")
		if not await _wait_phase("recording", 180): await _producer_finish(); return
		_game.call("open_bench")
		if not await _producer_capture("recording", true): await _producer_finish(); return
		_game.call("resume_lab")
		# Existing focused route helper sends one actual swipe then primary tap.
		# It does not release a tether or defeat any source.
		if not await _record_valid(Vector3.BACK): await _producer_finish(); return
		if not await _wait_phase("warning", 240): await _producer_finish(); return
		_game.call("open_bench")
		if not await _producer_capture("warning", true): await _producer_finish(); return
		await _close_parent()
		if _failures > 0: await _producer_finish(); return
	_producer_complete = true
	await _producer_finish()

func _open() -> bool:
	paused = false
	_game = MainScene.instantiate()
	_game.set_script(ProducerMain)
	_game.set("producer_test_profile", _producer_profile)
	_game.set("level_scene_path", PARENT_ROOM)
	if not _expect(not _game.is_inside_tree() and _game.scene_file_path == "res://scenes/main.tscn", "Actual Main PackedScene identity retained before explicit TEST profile wrapper"):
		return false
	root.add_child(_game)
	_game.call("open_bench")
	_hero = _game.get("player") as CinderPlayer
	_outer = _game.get("active_level") as CinderLevel
	_room = _outer.get("current_unit") as CinderLevel if _outer != null else null
	_scheduler = _room.get("threat_scheduler") as CinderThreatScheduler if _room != null else null
	_gate = _room.get("capture_gate") as CinderReplayCaptureGate if _room != null else null
	if not _expect(paused and _hero != null and _outer != null and _room != null and _room.get_script() == ProducerPhase and _outer.scene_file_path == PARENT_ROOM and _outer.call("parent_owned_state").stage == 2 and _scheduler.encounter_profile().id == _producer_profile and String(_outer.get("last_configuration_error")).is_empty(), "Declared TEST stage2 starts genuine original captured phase/Scheduler with explicit " + _producer_profile):
		return false
	_hp = _hero.hp
	_kit = _hero.equipment.snapshot()
	_hero.fired.connect(_on_fired)
	_barrier = Barrier.new()
	root.add_child(_barrier)
	var region: Dictionary = _room.call("floor_regions")[0]
	_floor_collision = region.collision
	_floor_transform = _floor_collision.global_transform
	_floor_size = (_floor_collision.shape as BoxShape3D).size
	_events.clear(); _retirements.clear()
	_reentrant_rejected = false; _blast_seen = false
	_gate.sequence_retired.connect(_on_retired)
	return true

func _close_parent() -> void:
	var native_refs: Array[WeakRef] = []
	for node: Node in [_room, _scheduler, _gate]:
		if is_instance_valid(node): native_refs.append(weakref(node))
	if is_instance_valid(_outer): _outer.exit_level()
	_room = null; _scheduler = null; _gate = null
	await super._close()
	_outer = null
	_expect(native_refs.all(func(ref: WeakRef) -> bool: return ref.get_ref() == null), "Normal owned parent disposal frees actual captured native descendants")

func _wait_phase(wanted: String, limit: int) -> bool:
	for _i: int in range(limit):
		if _producer_finishing: return false
		if String(_room.call("state").phase) == wanted: return true
		if not await _tick(): return false
	return _expect(false, "Bounded genuine native phase reaches " + wanted, str(_room.call("state")))

func _tick() -> bool:
	if _producer_finishing: return false
	if paused or not is_instance_valid(_barrier): return _expect(false, "Actual unpaused post-consumer barrier required")
	_barrier.waiting = true; _barrier.expired = false; _barrier.frames = 0
	await _barrier.observed
	if _producer_finishing: return false
	_ticks += 1
	var fixed: bool = _floor_collision.global_transform == _floor_transform and (_floor_collision.shape as BoxShape3D).size == _floor_size
	return _expect(not _barrier.expired and not paused and is_instance_valid(_room) and _outer.get("current_unit") == _room and not _hero.dead and _hero.hp == _hp and _hero.equipment.snapshot() == _kit and fixed and not _blast_seen and String(_outer.get("last_configuration_error")).is_empty(), "Actual original phase tick preserves Hero/resources/floor without private state writes")

func _on_retired(_sequence: Dictionary, retirement: Dictionary) -> void:
	# Observation only. No duplicate consume/prepare transaction is attempted.
	_retirements.append(retirement.duplicate(true))

func _producer_capture(stage: String, required: bool) -> bool:
	await process_frame
	if _producer_finishing: return false
	var actor: Dictionary = _hero.snapshot_state()
	var unit: Dictionary = _room.call("capture_native_state", actor, false)
	if unit.is_empty():
		var reason: String = String(_room.call("native_capture_error"))
		if not required:
			_producer_unsupported.append({"profile": _producer_profile, "stage": stage, "reason": reason, "payload_exported": false})
			return _expect(true, "Optional gen0 refused by original writer; omission and original reason recorded", reason)
		return _expect(false, "Required original whole phase writer: " + stage, reason)
	if not _expect(paused and not actor.is_empty() and unit.get("api_revision") == "act3-crystalman-captured-phase-2" and unit.get("schema_version") is int and unit.schema_version == 2 and unit.configuration.capacity == 1 and unit.world.profile_id == _producer_profile and unit.scheduler.profile.id == _producer_profile and unit.configuration.base_runtime_sha256 == ProducerCodec.BASE_SHA, "Actual old API2/schema2 complete phase and actual profile: " + stage): return false
	var expected: String = "settling" if stage == "gen0" else stage
	if not _expect(unit.owned.phase == expected and (stage != "gen0" or (unit.owned.generation == 0 and unit.playback.is_empty())) and (stage != "recording" or (unit.gate.capture.armed and unit.gate.capture.allocated == 0 and unit.playback.is_empty())), "Original unjoined phase/gen0 entitlement retained: " + stage): return false
	if stage == "warning":
		var source: CinderReplayPlayback = _room.get("playback") as CinderReplayPlayback
		var records: Array = unit.scheduler.reservations
		if not _expect(is_instance_valid(source) and records.size() == 1 and _scheduler.replay_reservation_state(records[0].id).source_instance_id == source.get_instance_id() and records[0].adapter.kind == "replay" and not records[0].adapter.locked and unit.playback.api_revision == "replay-playback-1" and unit.playback.schema_version == 3 and unit.playback.status == "running" and unit.playback.opportunities.is_empty() and unit.owned.joins == 1 and unit.gate.retirement.slot_ids == [1] and _retirements.size() == 1 and unit.owned.sequence.capture_snapshot.slots[0].blast.is_empty() and _wire_exact(unit.owned.sequence.capture_snapshot.slots[0].dash, _first_dash) and _wire_exact(unit.owned.sequence.capture_snapshot.slots[0].primary, _first_primary), "One actual held captured lease retains original public records/FIFO/no delivered damage; not authored-source managed cycles"):
			return false
	var packet: Dictionary = {"player": actor, "phase": unit}
	var wire: String = Exact.stringify(packet)
	var parsed: Dictionary = Exact.parse(wire)
	if not _expect(not wire.is_empty() and parsed.get("accepted", false) and Exact.stringify(parsed.value) == wire and _hero.snapshot_error(actor).is_empty() and String(_room.call("native_state_error", unit, actor)).is_empty(), "Original native whole phase+Player validators and Exact scalar bits: " + stage): return false
	var name: String = _producer_profile + "-" + stage
	var exact_path: String = _producer_out.path_join(name + ".exact.json")
	var file := FileAccess.open(exact_path, FileAccess.WRITE)
	if not _expect(file != null, "Opaque exact original packet output opens"): return false
	file.store_string(wire); file.close()
	var store_uri: String = _producer_store_root + name + ".json"
	var store: CinderSaveStore = ProducerStore.new(store_uri)
	if not _expect(store.write_payload(packet), "Actual format2 Store writes complete original native pair", store.last_error): return false
	var raw: PackedByteArray = FileAccess.get_file_as_bytes(store_uri)
	var envelope: Variant = JSON.parse_string(raw.get_string_from_utf8())
	var reread: Dictionary = ProducerStore.new(store_uri).read_payload()
	var frozen: Dictionary = {"player": _hero.snapshot_state(), "phase": _room.call("capture_native_state", _hero.snapshot_state(), false)}
	if not _expect(envelope is Dictionary and envelope.get("format_version") == 2 and envelope.get("payload_json") == wire and Exact.stringify(reread) == wire and Exact.stringify(frozen) == wire, "Independent Store reread and unchanged actual paused whole native pair preserve original wire"): return false
	var store_path: String = _producer_out.path_join(name + ".store.json")
	file = FileAccess.open(store_path, FileAccess.WRITE)
	if not _expect(file != null, "Raw actual Store bytes output opens"): return false
	file.store_buffer(raw); file.close()
	_producer_packets.append({"profile": _producer_profile, "stage": stage, "exact_file": name + ".exact.json", "exact_sha256": wire.sha256_text(), "exact_bytes": wire.to_utf8_buffer().size(), "store_file": name + ".store.json", "store_sha256": FileAccess.get_sha256(store_path), "store_bytes": raw.size(), "original_store_uri": store_uri, "api_revision": unit.api_revision, "schema_version": unit.schema_version, "phase": unit.owned.phase, "native_ids": {"hero": _hero.get_instance_id(), "phase": _room.get_instance_id(), "gate": _gate.get_instance_id(), "scheduler": _scheduler.get_instance_id(), "floor": _floor_collision.get_instance_id(), "playback": (_room.get("playback") as Node).get_instance_id() if is_instance_valid(_room.get("playback")) else 0}, "scope": "New execution of original API2 complete native phase+Player; actual production parent floor under declared TEST stage2. Not historical recovery, CampaignAttempts/Shell session, whole-parent optical save, route clear or executed damage."})
	return true

func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	var row: Dictionary = {"check": _checks, "ok": ok, "label": label, "detail": detail}
	_producer_rows.append(row)
	if ok: print("PASS: " + label)
	else:
		_failures += 1
		if _producer_first_failure.is_empty(): _producer_first_failure = row.duplicate(true)
		print("FAIL original captured producer: " + label + "; " + detail)
	return ok

func _producer_source_state() -> Dictionary:
	var answer: Dictionary = {}
	for path: String in _producer_sources:
		answer[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else null
	return answer

func _producer_finish() -> void:
	if _producer_finishing: return
	_producer_finishing = true
	if is_instance_valid(_game): await _close_parent()
	paused = true
	var dir := DirAccess.open(_producer_store_root)
	if dir != null:
		for name: String in dir.get_files(): DirAccess.remove_absolute(ProjectSettings.globalize_path(_producer_store_root + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_producer_store_root))
	var source_after: Dictionary = _producer_source_state()
	_expect(source_after == _producer_before, "Fixed named source/UID observations stay unchanged")
	var report: Dictionary = {"schema_version": 1, "kind": "new-executed-original-captured-api2-producer", "checks": _checks, "failures": _failures, "rows": _producer_rows, "first_failure": _producer_first_failure, "complete": _producer_complete, "success": _producer_complete and _failures == 0, "source_before": _producer_before, "source_after": source_after, "packets": _producer_packets, "unsupported": _producer_unsupported, "scope": "Original full native captured phase+Player and actual raw Store only. Explicit TEST Main Assisted/Standard and declared prior regular history. One-slot actual warning lease, original public swipe/tap records; no later lock/damage/tether/boss/full route, optical/CampaignAttempts or performance credit."}
	var path: String = _producer_out.path_join("native-report.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: print("Original captured producer report write failed"); quit(2); return
	file.store_string(JSON.stringify(report, "\t") + "\n"); file.close()
	print("CINDER_CAPTURED_ORIGINAL_REPORT path=" + path + " sha256=" + FileAccess.get_sha256(path))
	print("Captured original API2 producer: %d checks/%d failures; complete=%s; packets=%d" % [_checks, _failures, str(_producer_complete), _producer_packets.size()])
	quit(0 if _producer_complete and _failures == 0 else 1)
