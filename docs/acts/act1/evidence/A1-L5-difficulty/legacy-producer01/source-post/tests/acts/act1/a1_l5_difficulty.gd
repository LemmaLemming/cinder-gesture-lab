extends "res://tests/acts/act1/a1_l5_encounter_transition.gd"
## Private draft: legacy-producer only; unparsed/unexecuted until owner queues it.
## Same real parent, eight ordinary primaries and native CP2/CP3. TEST prefix,
## public Rusher injury and supported Hero placement are explicitly disclosed.
## No source HP/phase/clock/lease/profile/forecast/history assignment.

const LEGACY_HOST_SHA: String = "9056b2111d3e709fca592a38ac58ad1a181a0b1825128493fde7a180c71b9144"
const LEGACY_CODEC_SHA: String = "2fafe8b39f64f791804b3546898c6d54f7063985dc0a65222c6ab69313fcc1df"
const LEGACY_HOST_PATH: String = "res://scripts/acts/act1/living_moon.gd"
const LEGACY_CODEC_PATH: String = "res://scripts/acts/act1/living_moon_codec.gd"

class BeforeParentProbe extends Node:
	signal before_parent
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 199
	func _physics_process(_delta: float) -> void:
		before_parent.emit()

var difficulty_case: String = ""
var difficulty_complete: bool = false
var assertion_rows: Array[Dictionary] = []
var branches: Dictionary = {}
var branch_order: Array[String] = []
var source_pre: Dictionary = {}
var source_post: Dictionary = {}
var artifact_root: String = ""
var before_parent_probe: BeforeParentProbe
var selection_rows: Array[Dictionary] = []
var selection_observation_count: int = 0
var latest_preselection: Dictionary = {}
var first_final_admission: Dictionary = {}
var checkpoint_pause_requests: Array[Dictionary] = []


func _initialize() -> void:
	super._initialize()
	test_root = "user://test-act1-l5-difficulty-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	artifact_root = "res://.cinder/a1-l5-difficulty-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]


func _run() -> void:
	root.size = Vector2i(540, 1170)
	registry_bytes = FileAccess.get_file_as_bytes(Registry.DATA_PATH)
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--case="): difficulty_case = argument.trim_prefix("--case=")
		elif argument.begins_with("--level-scene") or argument in ["--capture", "--capture-polish", "--first-primary-only", "--later-phase-transport-only"]:
			_expect(false, "difficulty producer cannot combine preview or inherited alternate selectors"); await _finish(); return
	if not _expect(difficulty_case == "legacy-producer", "only explicitly selected legacy-producer is implemented"):
		await _finish(); return
	source_pre = _source_pins()
	if not _expect(source_pre[LEGACY_HOST_PATH] == LEGACY_HOST_SHA and source_pre[LEGACY_CODEC_PATH] == LEGACY_CODEC_SHA, "genuine old host9056/codec2fafe must remain installed before legacy production"):
		await _finish(); return
	var parsed: Variant = JSON.parse_string(registry_bytes.get_string_from_utf8())
	if not _expect(parsed is Dictionary and parsed.get("levels") is Array, "actual registry supplies isolated TEST L5 metadata"):
		await _finish(); return
	raw = parsed.duplicate(true)
	for entry: Dictionary in raw.levels:
		if entry.id == Layout.LEVEL_ID:
			setups.append({"kind": "TEST in-memory L5 override", "canonical_readiness_before": entry.readiness, "canonical_scene_before": entry.scene_path, "canonical_commit_before": entry.accepted_commit})
			entry.scene_path = ScenePath; entry.readiness = "accepted"; entry.accepted_commit = "f".repeat(40); entry.api_revision = Registry.API_REVISION
	var registry := Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error(Layout.LEVEL_ID).is_empty(), "only owned L5 receives isolated TEST registration; no canonical metadata changes"):
		await _finish(); return
	probe = NativeTickProbe.new(); probe.process_physics_priority = 3000; root.add_child(probe)
	before_parent_probe = BeforeParentProbe.new(); root.add_child(before_parent_probe)
	before_parent_probe.before_parent.connect(_observe_before_parent)
	probe.tick_finished.connect(_observe_after_parent)
	if not await _seed_actual_pristine_story(registry): await _finish(); return
	game = _new_shell()
	if game == null or not await _settle() or not await _click(game, "ContinueStoryButton") or not _bindings(game): await _finish(); return
	moon = game.active_level
	var eye: CharacterBody3D = moon.get("eye") as CharacterBody3D
	eye_ref = weakref(eye)
	var collision: CollisionShape3D = eye.call("get_collision")
	eye_collision_ref = weakref(collision); eye_shape_ref = weakref(collision.shape)
	eye.connect("phase_changed", _phase_observer)
	eye.connect("defeated", _defeat_observer)
	moon.checkpoint_requested.connect(_checkpoint_archive_pause)
	var initial: Dictionary = game.capture_campaign_snapshot()
	if not _legacy_unit(initial) or not _expect(initial.level.local.stage == "return" and initial.level.local.eye.hp == 240.0 and initial.level.local.scheduler.clock_s == 0.0 and initial.level.local.blink.cycle == 0 and initial.level.progress.checkpoint_ids.is_empty() and game.attempts.state().completed_main == Prefix, "actual Challenge-born pristine Story contains no fabricated Moon progress"):
		await _finish(); return
	if not _expect(game.player.equipment.snapshot() == Equipment.STARTER and float(game.player.equipment.resolved_stats().primary_damage) == 20.0, "unchanged neutral kit has actual ordinary20 damage") or not _archive_branch("entry", "", 240.0, 0): await _finish(); return
	if not await _enter_actual_boss(): await _finish(); return
	hp_boundaries.append(240.0)
	if not await _drive_to_hp(160.0, "blink") or not await _phase_checkpoint("moon-phase-2", "sneeze", 160.0): await _finish(); return
	if not _expect(branch_order == ["entry", "cp2"] and primary_receipts.size() == 4, "complete CP2 branch is archived after fourth primary before any CP3 work"):
		await _finish(); return
	if not await _click(game, "ResumeButton"): await _finish(); return
	if not await _drive_to_hp(80.0, "sneeze") or not await _phase_checkpoint("moon-phase-3", "final", 80.0): await _finish(); return
	if not _expect(branch_order == ["entry", "cp2", "cp3"] and primary_receipts.size() == 8 and moon.get("sneeze_demonstrated") == true and first_final_admission.is_empty(), "complete CP3 follows eight real hits and genuine Sneeze demonstration before first final admission"):
		await _finish(); return
	if not await _click(game, "ResumeButton"): await _finish(); return
	if not await _wait(func() -> bool: return not first_final_admission.is_empty(), "first actual legacy final admission", 12.0, true) or not await _pause(): await _finish(); return
	var final_unit: Dictionary = game.capture_campaign_snapshot()
	if not _legacy_unit(final_unit): await _finish(); return
	var leases: Array = final_unit.level.local.scheduler.reservations
	if not _expect(first_final_admission.source_ids == [Layout.EYE_ID] and leases.size() == 1 and leases[0].source_id == Layout.EYE_ID and final_unit.level.local.blink.status == "running" and final_unit.level.local.blink.phase in ["warning", "lock"] and final_unit.level.local.nose.status != "running" and final_unit.level.local.next_attack == "sneeze", "real old Challenge first final source is Blink, saved before a Nose follower"):
		await _finish(); return
	if not _expect(not first_final_admission.preselection.is_empty() and first_final_admission.preselection.clock_s == first_final_admission.clock_s and first_final_admission.preselection.pure, "same native tick records pure preselection without fixture forecast injection; existing parent forecast is reported literally"):
		await _finish(); return
	if not _archive_branch("first-final-blink", "moon-phase-3", 80.0, 8): await _finish(); return
	if not _expect(hp_boundaries == [240.0, 160.0, 80.0] and phase_observers.size() == 2 and phase_observers[0].phase == 2 and phase_observers[1].phase == 3 and primary_receipts.size() == 8 and terminal_observers.is_empty(), "producer stops after original eight primaries/two checkpoints/first final Save; no defeat or exit claim"):
		await _finish(); return
	difficulty_complete = true
	await _finish()


func _seed_actual_pristine_story(registry: CinderCampaignRegistry) -> bool:
	# Same inherited genuine fresh-candidate setup; set the PUBLIC preference
	# before the real entry begin_encounter, never relabel a Standard packet.
	game = _new_shell()
	if game == null or not await _settle(): return false
	game.menu.difficulty_preference_requested.emit("challenge")
	if not _expect(game.get_difficulty_preference() == "challenge" and game.active_level == null and game.player == null, "public Title preference selects Challenge before any fresh L5 entry"):
		return false
	setups.append({"kind": "public Title difficulty preference before fresh entry", "profile_id": "challenge", "interactive_gesture_claim": false})
	candidate = game._prepare(Layout.LEVEL_ID, Equipment.STARTER)
	if not _expect(not candidate.is_empty(), "actual shared Shell constructs the fresh Challenge production entrance"): return false
	var pristine: Dictionary = game._capture_fresh_candidate(candidate, game._fresh_shell_state())
	if not _legacy_unit(pristine): return false
	var model := Attempts.new(registry)
	var payload: Dictionary = model.state()
	payload.completed_main = Prefix.duplicate()
	payload.story = {"kind": "story", "level_id": Layout.LEVEL_ID, "snapshot": pristine.duplicate(true), "checkpoint": pristine.duplicate(true)}
	var store := Store.new(test_root + "campaign.json")
	store.payload_validator = model.saved_payload_error
	if not _expect(model.state_error(payload).is_empty() and store.write_payload(payload), "public validated Store preserves genuine Challenge birth plus disclosed TEST predecessor prefix: " + model.last_error + store.last_error): return false
	setups.append({"kind": "TEST sequential predecessor prefix, not earned playthrough", "completed_main": Prefix.duplicate(), "candidate_scene": ScenePath, "canonical_registry_changed": false})
	operation = "explicit Challenge seed candidate disposal"
	game._dispose(candidate); candidate = {}
	var refs: Array[WeakRef] = _refs(game)
	game.free(); game = null
	return _expect(_freed(refs), "fresh Challenge seed candidate and Shell dispose normally before actual Title Continue")


func _checkpoint_archive_pause(id: String, checkpoint: String, kind: String) -> void:
	if id != Layout.LEVEL_ID or checkpoint not in ["moon-phase-2", "moon-phase-3"] or kind != "boss_phase": return
	checkpoint_pause_requests.append({"checkpoint_id": checkpoint, "clock_s": _scheduler().get_clock(), "primary_count": primary_receipts.size(), "method": "public request_pause queued after native checkpoint; no world state write"})
	# The Shell connected its native checkpoint listener before this observer.
	# Public Pause follows its checkpoint operation and prevents auto-resume.
	game.request_pause()


func _phase_checkpoint(id: String, expected_stage: String, hp: float) -> bool:
	if not await _wait(func() -> bool: return moon.current_checkpoint().id == id and moon.get("stage") == expected_stage, "actual deferred native boundary " + id, 8.0, true) or not await _pause(): return false
	var saved: Dictionary = game.attempts.state().story.checkpoint
	if not _legacy_unit(saved) or not _expect(saved.level.local.eye.hp == hp and saved.level.local.stage == expected_stage and saved.level.progress.checkpoint_id == id and saved.level.progress.checkpoint_kind == "boss_phase" and saved.level.local.pending_phase == 0 and saved.level.local.scheduler.reservations.is_empty() and _durable(game), "native settled phase checkpoint remains complete and durable before further gameplay"):
		return false
	hp_boundaries.append(hp)
	receipts.append({"stage": "actual " + id, "exact_snapshot": Exact.stringify(saved)})
	return _archive_branch("cp2" if id == "moon-phase-2" else "cp3", id, hp, 4 if id == "moon-phase-2" else 8)


func _place_at_actual_low_rim() -> bool:
	# Authorized focused setup: use existing eye approach, not a phase/HP seed.
	var goal: Vector3 = Layout.EYE_APPROACH_POSITION
	goal.y = game.player.global_position.y
	if game.player.global_position.distance_to(goal) <= 0.01: return true
	var supported: Dictionary = Sweep.step(game.player, Transform3D(Basis.IDENTITY, goal), Vector3.ZERO, [moon.call("floor_region")])
	if not _expect(not supported.has("error") and not supported.get("collided", true), "authored eye-approach TEST placement has actual floor/full-capsule support"): return false
	var before: Vector3 = game.player.global_position
	game.player.global_position = goal
	setups.append({"kind": "TEST recovery-only Hero placement at existing EYE_APPROACH; not earned return", "from": Codec.vector3(before), "to": Codec.vector3(goal), "clock_s": _scheduler().get_clock()})
	return true


func _pause() -> bool:
	game.request_pause()
	if not await _settle(): return false
	if not await _wait(func() -> bool: return _shell_idle() and paused and game.menu.is_open() and game.menu.page_name() == "pause", "public Pause and actual asynchronous Store registration settle", 16.0, true): return false
	return _expect(game.campaign_error.is_empty() and _durable(game), "public Pause closes its real durable barrier: " + game.campaign_error)


func _shell_idle() -> bool:
	return is_instance_valid(game) and not game.get("_draining") and not game.get("_drain_queued") and not game.get("_registration_inflight") and not game.get("_pause_request_pending") and game.get("_operations").is_empty() and game.get("_failed_operations").is_empty()


func _legacy_unit(saved: Dictionary) -> bool:
	if not _closed(saved): return false
	return _expect(saved.level.local.size() == 16 and saved.level.local.api_revision == "act1-living-moon-level-1" and saved.level.local.schema_version == 1 and not saved.level.local.has("final_arrangement") and saved.level.local.scheduler.profile.id == "challenge" and saved.shell.difficulty_at_entry == "challenge", "literal old16 omission and actual Challenge entry/native profile remain exact")


func _archive_branch(label: String, checkpoint_id: String, hp: float, hit_count: int) -> bool:
	if not _expect(paused and _shell_idle() and not branches.has(label), "archive only one settled paused branch: " + label): return false
	var current: Dictionary = game.capture_campaign_snapshot()
	var attempts: Dictionary = game.attempts.state()
	var checkpoint: Dictionary = attempts.story.checkpoint
	if not _legacy_unit(current) or not _legacy_unit(checkpoint): return false
	if not _expect(current.level.local.eye.hp == hp and checkpoint.level.local.eye.hp == hp and checkpoint.level.progress.checkpoint_id == checkpoint_id and primary_receipts.size() == hit_count and _same(attempts.story.snapshot, current) and _durable(game), "whole live current/checkpoint/Attempts/raw Store agree before branch archive: " + label): return false
	var current_wire: String = Exact.stringify(current)
	var checkpoint_wire: String = Exact.stringify(checkpoint)
	var attempts_wire: String = Exact.stringify(attempts)
	var parsed_attempts: Dictionary = Exact.parse(attempts_wire)
	if not _expect(not current_wire.is_empty() and not checkpoint_wire.is_empty() and parsed_attempts.get("accepted") == true and _same(parsed_attempts.value, attempts), "complete typed whole Attempts/current/checkpoint wires round-trip: " + label): return false
	var raw_store: PackedByteArray = FileAccess.get_file_as_bytes(test_root + "campaign.json")
	var envelope: Variant = JSON.parse_string(raw_store.get_string_from_utf8())
	if not _expect(not raw_store.is_empty() and envelope is Dictionary and envelope.get("format_version") == Store.FORMAT_VERSION and envelope.get("payload_json") == attempts_wire and envelope.get("sha256") == attempts_wire.sha256_text(), "literal original format2 raw Store contains this exact whole Attempts: " + label): return false
	var branch_dir: String = artifact_root.path_join(label)
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(branch_dir)) == OK, "separate immutable evidence destination exists: " + label): return false
	var disk_files: Dictionary = {}
	var directory := DirAccess.open(test_root)
	if not _expect(directory != null, "actual isolated Store directory can be read: " + label): return false
	for name: String in directory.get_files():
		var original_path: String = test_root.path_join(name)
		var original_bytes: PackedByteArray = FileAccess.get_file_as_bytes(original_path)
		var copy_path: String = branch_dir.path_join(name)
		var copy := FileAccess.open(copy_path, FileAccess.WRITE)
		if not _expect(copy != null, "literal branch file can be archived: " + label + "/" + name): return false
		copy.store_buffer(original_bytes); copy.flush()
		var write_error: Error = copy.get_error(); copy.close()
		if not _expect(write_error == OK and FileAccess.get_file_as_bytes(copy_path) == original_bytes and FileAccess.get_sha256(copy_path) == FileAccess.get_sha256(original_path), "archived original bytes/hash remain exact: " + label + "/" + name): return false
		disk_files[name] = {"path": copy_path, "bytes": original_bytes.size(), "sha256": FileAccess.get_sha256(original_path), "hex": original_bytes.hex_encode()}
	var row: Dictionary = {"label": label, "current_exact": current_wire, "current_sha256": current_wire.sha256_text(), "checkpoint_exact": checkpoint_wire, "checkpoint_sha256": checkpoint_wire.sha256_text(), "attempts_exact": attempts_wire, "attempts_sha256": attempts_wire.sha256_text(), "raw_store": disk_files["campaign.json"], "all_original_disk_files": disk_files, "generation": envelope.generation, "primary_count": hit_count, "profile_id": "challenge", "local_schema": 1, "checkpoint_id": checkpoint_id, "clock_s": current.level.local.scheduler.clock_s, "scope": "Complete literal contemporaneous branch. Future CP2 Retry loads this CP2 branch separately; no transplantation into CP3."}
	if not _expect(FileAccess.get_file_as_bytes(test_root + "campaign.json") == raw_store and Exact.stringify(game.capture_campaign_snapshot()) == current_wire and Exact.stringify(game.attempts.state()) == attempts_wire, "read-only archive leaves actual current/Attempts/original disk unchanged: " + label): return false
	row["source_pre"] = source_pre.duplicate(true)
	var branch_json: String = JSON.stringify(row, "\t")
	var branch_path: String = branch_dir.path_join("branch.json")
	var branch_file := FileAccess.open(branch_path, FileAccess.WRITE)
	if not _expect(branch_file != null, "complete branch receipt can be committed before proceeding: " + label): return false
	branch_file.store_string(branch_json); branch_file.flush()
	var branch_error: Error = branch_file.get_error(); branch_file.close()
	if not _expect(branch_error == OK and FileAccess.get_file_as_string(branch_path) == branch_json, "literal full branch receipt is closed on disk before further gameplay: " + label): return false
	branches[label] = row; branch_order.append(label)
	return true


func _selection_boundary() -> Dictionary:
	var response: Dictionary = game.player.get_threat_response_state().duplicate(true)
	response.erase("actor")
	return {"clock_s": _scheduler().get_clock(), "hero_position": game.player.global_position, "hero_response": response, "eye_hp": moon.get("eye").get("hp"), "blink": moon.get("blink").state(), "nose": moon.get("nose").state(), "eye_control": _scheduler().source_control_state(moon.get("eye")), "nose_control": _scheduler().source_control_state(moon.get("nose")), "stage": moon.get("stage"), "next_attack": moon.get("next_attack"), "forecast": moon.get("_forecast"), "pending_start": moon.get("_pending_start"), "frames": moon.get("_frames"), "parent_error": moon.get("last_encounter_error"), "blink_error": moon.get("blink").get("last_error"), "nose_error": moon.get("nose").get("last_error")}


func _preview_record(value: Dictionary) -> Dictionary:
	return {"accepted": value.get("accepted", false), "reason": value.get("reason", ""), "candidate": _encode(value.get("candidate", {})), "proof": _encode(value.get("proof", {}))}


func _observe_before_parent() -> void:
	if finishing or aborted or paused or not _live() or not is_instance_valid(moon) or moon.get("stage") != "final" or not first_final_admission.is_empty() or not _boss_records().is_empty(): return
	var before: String = Exact.stringify(_encode(_selection_boundary()))
	var blink_preview: Dictionary = moon.get("blink").preview_start(moon.call("response_context", true))
	var nose_preview: Dictionary = moon.get("nose").preview_start(moon.call("response_context"))
	var after: String = Exact.stringify(_encode(_selection_boundary()))
	var pure: bool = not before.is_empty() and before == after
	latest_preselection = {"clock_s": _scheduler().get_clock(), "hero_position": Codec.vector3(game.player.global_position), "profile": _scheduler().encounter_profile(), "blink": _preview_record(blink_preview), "nose": _preview_record(nose_preview), "both_eligible": blink_preview.get("accepted", false) and nose_preview.get("accepted", false), "pure": pure, "forecast_empty": moon.get("_forecast").is_empty() and moon.get("_pending_start").is_empty(), "before_exact": before, "after_exact": after}
	selection_observation_count += 1
	selection_rows.append(latest_preselection.duplicate(true))
	if selection_rows.size() > 32: selection_rows.pop_front()
	if not pure:
		_expect(false, "native preview diagnostics must leave complete source/response/parent boundary unchanged")
		aborted = true; _finish.call_deferred()


func _observe_after_parent() -> void:
	if finishing or aborted or paused or not _live() or not is_instance_valid(moon) or moon.get("stage") != "final" or not first_final_admission.is_empty(): return
	var records: Array[Dictionary] = _boss_records()
	if records.is_empty(): return
	var ids: Array[String] = []
	for record: Dictionary in records: ids.append(String(record.source_id))
	first_final_admission = {"clock_s": _scheduler().get_clock(), "source_ids": ids, "records": _encode(records), "preselection": latest_preselection.duplicate(true), "boundary": _encode(_selection_boundary()), "pause_method": "public request_pause after actual parent admission, outside source callbacks"}
	game.request_pause()


func _source_pins() -> Dictionary:
	var result: Dictionary = {}
	for path: String in [LEGACY_HOST_PATH, LEGACY_CODEC_PATH, "res://scripts/acts/act1/living_moon_layout.gd", "res://scripts/acts/act1/living_moon_body.gd", "res://scripts/acts/act1/living_moon_nose.gd", "res://tests/acts/act1/a1_l5_encounter_transition.gd", "res://tests/acts/act1/a1_l5_shell_transport.gd", ScenePath]:
		result[path] = FileAccess.get_sha256(path)
	return result


func _expect(ok: bool, label: String) -> bool:
	assertion_rows.append({"index": checks + 1, "passed": ok, "label": label, "wall_ms": Time.get_ticks_msec() - started_ms})
	return super._expect(ok, label)


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true; _end_watch("normal legacy producer cleanup")
	# Unwind any native probe emitter before normal node disposal.
	await process_frame
	if is_instance_valid(game) and not candidate.is_empty(): game._dispose(candidate); candidate = {}
	var refs: Array[WeakRef] = []
	for shell: CinderCampaignShell in [fresh, game]:
		if is_instance_valid(shell): refs.append_array(_refs(shell)); shell.free()
	fresh = null; game = null
	for node: Node in [before_parent_probe, probe]:
		if is_instance_valid(node): refs.append_array(_refs(node)); node.free()
	paused = false
	await create_timer(0.5, true).timeout; await process_frame
	_expect(_freed(refs) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal producer Shell/native-source/cue/probe cleanup releases every descendant and group")
	_expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH) == registry_bytes, "TEST prefix and registration never modify canonical registry bytes")
	source_post = _source_pins()
	_expect(not source_pre.is_empty() and source_post == source_pre, "old writer and all named inherited inputs remain byte-identical through production")
	var directory := DirAccess.open(test_root)
	var removed: bool = true
	if directory != null:
		for name: String in directory.get_files():
			if DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root.path_join(name))) != OK: removed = false
		if DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root)) != OK: removed = false
	_expect(removed, "disposable live Store retires after literal complete branches are independently archived")
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	var report: String = "res://.cinder/a1-l5-difficulty-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	var file := FileAccess.open(report, FileAccess.WRITE)
	if file == null:
		_expect(false, "difficulty native report is writable")
	else:
		var complete: bool = difficulty_complete and failures == 0 and not aborted
		var body: Dictionary = {"case": difficulty_case, "checks": checks, "failures": failures, "success": complete, "complete": complete, "assertions": assertion_rows, "first_failure": first_failure, "branches": branches, "branch_order": branch_order, "artifact_root": artifact_root, "source_pre": source_pre, "source_post": source_post, "setups": setups, "receipts": receipts, "primary_receipts": primary_receipts, "phase_observers": phase_observers, "hp_boundaries": hp_boundaries, "checkpoint_pause_requests": checkpoint_pause_requests, "first_final_admission": first_final_admission, "selection_observation_count": selection_observation_count, "selection_rows_retained_last32": selection_rows, "circle_cycles": circle_cycles, "dash_requests": dash_requests, "drive_diagnostics": drive_diagnostics, "observations": observations, "wall_ms": Time.get_ticks_msec() - started_ms, "scope": "Actual old16 Challenge born at real entry, disclosed TEST prefix/public Rusher injury/supported Hero approach placements, eight actual ordinary20-damage primaries and native Sneeze demonstration/CP2/CP3. Separate literal whole current/checkpoint/Attempts/raw original Store branches archived at CP2 BEFORE CP3, then first actual final Blink Save. Pure native preselection diagnostics are observations, not both-eligibility or difficulty-novelty claims. No source HP/phase/clock/lease/profile seed, CP2 transplantation, manufactured v2, earned route, final response comparison, boss defeat/hatch/transition, gesture/portrait/all-kit/balance/performance claim. Runtime remains old source pins."}
		file.store_string(JSON.stringify(body, "\t")); file.flush()
		var report_error: Error = file.get_error(); file.close()
		if report_error != OK: _expect(false, "difficulty report write closes successfully")
	var completed: bool = difficulty_complete and failures == 0 and not aborted
	print("A1-L5 DIFFICULTY: %d checks, %d failures; complete=%s; report=%s" % [checks, failures, "true" if completed else "false", report])
	quit(1 if failures > 0 or not completed else 0)
