extends "res://tests/act1_l2_registration_smoke.gd"
## INERT TEST draft: original persisted CP2, actual GUI Continue/Resume and one
## same-Hero placement. Dynamic resources use the SAME cached Script identity;
## only passive prepare observers and the pinned original Route are substituted
## in this isolated child. No disk production edit or weakened guard/return.
## Ordinary native frames alone drive the room/actors. The passive window ends
## at its first observed admission or at <=1 simulation second /60 frame delta.
## Catch-up after that boundary is separately labelled, never inside the window.
## Bounded non-observation exits2 with zero assertion failures; it is incomplete,
## not proof of permanent refusal. Native/parser credit requires actual execution.

const StageEquipment = preload("res://scripts/equipment.gd")
const STAGE_ORIGINAL: String = "res://tests/acts/act2/shared_support/admission_diagnostic_inputs/cp2-original-format2.json"
const STAGE_ORIGINAL_SHA: String = "c1f4eb2333f61248998844dd7a13ecdb4cf2505448f7ab787cf984a78083c4ef"
const STAGE_ORIGINAL_BYTES: int = 271077
const STAGE_COMMIT: String = "0129e260a25405dc1e24d1869bbe607884eca430"
const STAGE_SCENE: String = "res://scenes/acts/act1/a1_l3.tscn"
const STAGE_SCRIPT: String = "res://scripts/acts/act1/mushroom_caverns_full.gd"
const STAGE_ACTOR: String = "res://scripts/acts/act1/mushroom_selenite.gd"
const ROUTE_PATH: String = "res://scripts/combat/repulsion_route.gd"
const BASELINE_ROUTE_PATH: String = "res://tests/acts/act2/shared_support/admission_diagnostic_inputs/repulsion_route.original.gd.txt"
const ACTOR_SHA: String = "a351ad0d46441887043ac24e31ec2e69a8279092b4bf3d8b839c7a99fb158932"
const CURRENT_ROUTE_SHA: String = "985a474fa65670dfac21e1dc3869d40d448119d896ca5a4a92c0a36ad2a51dad"
const BASELINE_ROUTE_SHA: String = "2bdfd3ea6997beceb0d5d26eb27e8520214872b0e81e1d7f8039afbf6d53b30a"
const PROTOCOL_PATH: String = "res://scripts/environment/scheduler_spore_source_protocol.gd"
const PROTOCOL_SHA: String = "a01b5481e3d06f64f65973fff075c4cbe622e4a1129c1646ee228c103b8523b5"
const OBSERVER_META: String = "act2_cp2_native_prepare_observer_20261014"
const PREPARE_LINE: String = "\tvar prepared: Dictionary = _prepare_start(context, direction, context.get(\"world_root\") as Node3D)\n"
const WINDOW_S: float = 1.0
const WINDOW_FRAMES: int = 60
const MAX_AWAIT_PAIRS: int = 16
const STACK_LIMIT: int = 12

var _diag_actor: Script
var _diag_route: Script
var _diag_protocol: Script
var _stage_registry: Dictionary = {}
var _stage_payload: Dictionary = {}
var _stage_expected_session: Dictionary = {}
var _started_us: int = 0
var _parse_only: bool = false
var _seeded: bool = false
var _actor_original: String = ""
var _route_original: String = ""
var _actor_resource_id: int = 0
var _route_resource_id: int = 0
var _actor_changed: bool = false
var _route_changed: bool = false
var _observer_installed: bool = false
var _patched_actor_sha: String = ""
var _live: bool = false
var _window_started: bool = false
var _window_closed: bool = false
var _window_start: Dictionary = {}
var _window_end: Dictionary = {}
var _end_reason: String = "not_started"
var _await_pairs: int = 0
var _call_counts: Dictionary = {}
var _first_refusals: Dictionary = {}
var _source_pins: Dictionary = {}
var _admission: Dictionary = {}
var _tail_publications: Array[Dictionary] = []
var _observer_error: String = ""
var _quiet_events: int = -1
var _outcome: String = "not_started"


func _initialize() -> void:
	_started_us = Time.get_ticks_usec()
	_test_root = "user://test-act2-cp2-admission-%d-%d/" % [OS.get_process_id(), _started_us]
	_expected_commit = STAGE_COMMIT
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--parse-observers-only": _parse_only = true
		else: _expect(false, "unsupported bounded diagnostic selector: " + argument)
	node_added.connect(_observe_restore_node)
	physics_frame.connect(_observe_physics_boundary)
	# This watches a returning event loop. Root separately bounds a blocked
	# synchronous call with its canonical 90-second post-spawn native deadline.
	create_timer(85.0, true).timeout.connect(func() -> void:
		if not _finished:
			_outcome = "returning_loop_watchdog"
			_expect(false, "diagnostic returns before its85-second event-loop watchdog")
			_finish())
	_run.call_deferred()


func _run() -> void:
	paused = true
	if failures > 0 or not _install_observers(): _finish(); return
	if _parse_only:
		_outcome = "dynamic_observers_compiled_without_instances_or_save_seed"
		_finish(); return
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if not _stage_seed_original(): _finish(); return
	_seeded = true
	_restore_events.clear()
	_watching_restore = true
	game = _new_shell()
	await _settle()
	if _finished: return
	if not _title_valid("original CP2 admission diagnostic") or not _expect(game.player == null, "fresh actual Title has no Player before real GUI Continue"):
		_finish(); return
	var disk := Store.new(_test_root + "campaign.json")
	var actual_disk: Dictionary = disk.read_payload()
	var expected: String = Exact.stringify(_stage_expected_session)
	if not _expect(not expected.is_empty() and Exact.stringify(game.attempts.state()) == expected and disk.last_error.is_empty() and Exact.stringify(actual_disk) == expected, "entire original CP2 session changes only by supported equipment availability migration"):
		_finish(); return
	await _click(_find("ContinueStoryButton") as Control)
	if _finished: return
	_watching_restore = false
	_quiet_events = _restore_events.size()
	if not _actual_entry(): _finish(); return
	var actual_wire: String = Exact.stringify(game.capture_campaign_snapshot())
	var original_wire: String = Exact.stringify(_stage_payload.story.snapshot)
	if not _expect(not actual_wire.is_empty() and actual_wire == original_wire and _restore_events.is_empty(), "fresh GUI Continue quietly recaptures the EXACT original nineteen-source Player/level/Shell unit"):
		_finish(); return
	_trace("quiet_original_cp2", {"unit_sha256": actual_wire.sha256_text(), "unit_bytes": actual_wire.to_utf8_buffer().size(), "quiet_events": _quiet_events})
	if not _pin_actual_sources(): _finish(); return
	game.active_level.connect("native_admission_published", _observe_publication)
	_live = true
	if not _resume_consumed("original CP2 admission diagnostic") or not _place_hero_once(): _finish(); return
	# No manual Actor ticks, attacks, previews, native response queries, or live
	# snapshots. Both observations execute inside ordinary native scheduling.
	while not _finished and not _window_closed and _await_pairs < MAX_AWAIT_PAIRS and _can_tick():
		_await_pairs += 1
		await physics_frame
		await process_frame
	if _finished: return
	if not _window_closed:
		_close_window("await_pair_safety_limit" if _await_pairs >= MAX_AWAIT_PAIRS else "live_room_stopped")
	var returned: Dictionary = _direct_time()
	# Real public pause occurs only after this ordinary await pair returns.
	game.request_pause()
	await _settle()
	if _finished: return
	_live = false
	_expect(paused, "public Shell pause closes the returning native observation")
	_expect(_observer_error.is_empty(), "passive prepare/publication observations preserve actual correspondence: " + _observer_error)
	_outcome = "native_admission_observed" if not _admission.is_empty() else "bounded_not_observed"
	_trace("bounded_native_outcome", {"outcome": _outcome, "scope_complete": not _admission.is_empty(), "end_reason": _end_reason, "window_start": _window_start, "window_end": _window_end, "return_after_boundary": returned, "catchup_tail": _time_delta(_window_end, returned), "await_pairs": _await_pairs, "await_pair_limit": MAX_AWAIT_PAIRS, "maximum_window_s": WINDOW_S, "maximum_window_frame_delta": WINDOW_FRAMES, "prepare_counts": _call_counts, "first_refusals": _first_refusals, "admission": _admission, "tail_publications_outside_window": _tail_publications})
	_finish()


func _install_observers() -> bool:
	_diag_actor = load(STAGE_ACTOR) as Script
	_diag_route = load(ROUTE_PATH) as Script
	_diag_protocol = load(PROTOCOL_PATH) as Script
	if not _expect(_diag_actor != null and _diag_route != null and _diag_protocol != null, "exact existing paths resolve to actual cached Script resources before construction"): return false
	_actor_original = _diag_actor.source_code
	_route_original = _diag_route.source_code
	_actor_resource_id = _diag_actor.get_instance_id()
	_route_resource_id = _diag_route.get_instance_id()
	if not _expect(_disk_pins_match() and _actor_original.sha256_text() == ACTOR_SHA and _route_original.sha256_text() == CURRENT_ROUTE_SHA and load(STAGE_ACTOR) == _diag_actor and load(ROUTE_PATH) == _diag_route, "before instances, SAME cached production Actor/Route and unchanged Protocol have exact current pins"):
		return false
	if not _expect(FileAccess.file_exists(BASELINE_ROUTE_PATH) and FileAccess.get_sha256(BASELINE_ROUTE_PATH) == BASELINE_ROUTE_SHA, "Root supplies the exact pinned original Route text, without reconstructed bytes"):
		return false
	if not _expect(not has_meta(OBSERVER_META), "isolated child starts without another observer metadata owner"): return false
	var patched: String = _actor_original
	var preview_prefix: String = "func preview_start(target: Vector3, context: Dictionary) -> Dictionary:\n\tvar direction: Vector3 = _target_direction(target)\n" + PREPARE_LINE
	var start_prefix: String = "func start(target: Vector3, context: Dictionary, preview: Dictionary = {}) -> Dictionary:\n\tvar direction: Vector3 = _target_direction(target)\n" + PREPARE_LINE
	var preview_hook: String = _observer_hook("preview_start")
	var start_hook: String = _observer_hook("start")
	if not _expect(patched.count(PREPARE_LINE) == 2 and patched.count(preview_prefix) == 1 and patched.count(start_prefix) == 1, "exact two original prepare call sites each occur once in their production method"):
		return false
	patched = patched.replace(preview_prefix, preview_prefix + preview_hook).replace(start_prefix, start_prefix + start_hook)
	if not _expect(patched.count(PREPARE_LINE) == 2 and patched.count("get_stack())") == _actor_original.count("get_stack())") + 2 and patched.replace(preview_hook, "").replace(start_hook, "") == _actor_original, "only passive hooks are inserted AFTER original calls; every guard, return and prepare call remains byte exact"):
		return false
	set_meta(OBSERVER_META, Callable(self, "_observe_prepare"))
	_observer_installed = true
	_route_changed = true
	_diag_route.source_code = FileAccess.get_file_as_string(BASELINE_ROUTE_PATH)
	var route_error: Error = _diag_route.reload()
	if not _expect(route_error == OK and _diag_route.get_instance_id() == _route_resource_id and load(ROUTE_PATH) == _diag_route and _diag_route.source_code.sha256_text() == BASELINE_ROUTE_SHA and _disk_pins_match(), "same cached Route compiles original pinned baseline in memory, with unchanged disk and resource identity"):
		return false
	_actor_changed = true
	_diag_actor.source_code = patched
	_patched_actor_sha = patched.sha256_text()
	var actor_error: Error = _diag_actor.reload()
	if not _expect(actor_error == OK and _diag_actor.get_instance_id() == _actor_resource_id and load(STAGE_ACTOR) == _diag_actor and _diag_actor.source_code.sha256_text() == _patched_actor_sha and _disk_pins_match(), "same cached Actor compiles both exact passive observer insertions before any game instance"):
		return false
	_trace("dynamic_resource_pins", {"actor_disk": ACTOR_SHA, "actor_memory_original": _actor_original.sha256_text(), "actor_memory_observed": _patched_actor_sha, "actor_resource_id": str(_actor_resource_id), "route_disk": CURRENT_ROUTE_SHA, "route_memory_baseline": BASELINE_ROUTE_SHA, "route_resource_id": str(_route_resource_id), "protocol": PROTOCOL_SHA, "parse_only": _parse_only})
	return true


func _observer_hook(caller: String) -> String:
	return "\t# Isolated TEST passive observer, immediately AFTER the existing call.\n\tvar cp2_observer: Callable = get_tree().get_meta(\"" + OBSERVER_META + "\", Callable())\n\tif cp2_observer.is_valid(): cp2_observer.call(\"" + caller + "\", self, prepared, context, target, direction, get_stack())\n"


func _disk_pins_match() -> bool:
	return FileAccess.get_sha256(STAGE_ACTOR) == ACTOR_SHA and FileAccess.get_sha256(ROUTE_PATH) == CURRENT_ROUTE_SHA and FileAccess.get_sha256(PROTOCOL_PATH) == PROTOCOL_SHA and _diag_protocol.source_code.sha256_text() == PROTOCOL_SHA


func _pin_actual_sources() -> bool:
	var sources: Dictionary = game.active_level.get("sources")
	var retained: Dictionary = game.active_level.get("_retained_sources")
	var all_match: bool = sources.size() == 19
	for id: String in sources:
		var actor: Node3D = sources[id] as Node3D
		all_match = all_match and is_instance_valid(actor) and actor == retained.get(id) and actor.get_script() == _diag_actor and actor.get("_hero") == game.player and actor.get("_scheduler") == game.active_level.get("scheduler")
		if is_instance_valid(actor): _source_pins[id] = {"ref": weakref(actor), "instance_id": actor.get_instance_id(), "cycle": int(actor.get("_cycle"))}
	return _expect(all_match and _diag_actor.source_code.sha256_text() == _patched_actor_sha and _diag_route.source_code.sha256_text() == BASELINE_ROUTE_SHA, "quiet committed recipient retains all nineteen genuine actors with SAME cached observed Script and actual Hero/Scheduler")


func _observe_physics_boundary() -> void:
	if not _live or _finished or _window_closed or not _can_tick(): return
	if game.active_level.get("beat_index") != 2 or game.active_level.get("room_stage") != "active": return
	if not _window_started:
		_window_started = true
		_window_start = _direct_time()
		_trace("active_window_start", _window_start)
	var now: Dictionary = _direct_time()
	var delta: Dictionary = _time_delta(_window_start, now)
	if int(delta.physics_frames) >= WINDOW_FRAMES or float(delta.hero_clock_s) >= WINDOW_S or float(delta.scheduler_clock_s) >= WINDOW_S:
		_close_window("passive_simulation_or_frame_boundary")


func _close_window(reason: String) -> void:
	if _window_closed: return
	_window_closed = true
	_window_end = _direct_time()
	_end_reason = reason
	_trace("passive_window_closed", {"reason": reason, "window_started": _window_started, "window_start": _window_start, "window_end": _window_end, "observed_delta": _time_delta(_window_start, _window_end), "boundary_before_actor_callbacks": reason == "passive_simulation_or_frame_boundary"})


func _observe_prepare(caller: String, actor: Node3D, prepared: Dictionary, context: Dictionary, target: Vector3, direction: Vector3, stack: Array) -> void:
	if not _live or _finished or _window_closed: return
	if not _window_started: _observe_physics_boundary()
	if not _window_started or _window_closed: return
	var configuration: Dictionary = actor.get("_configuration")
	var id: String = String(configuration.get("source_id", ""))
	var pin: Dictionary = _source_pins.get(id, {})
	if caller not in ["preview_start", "start"] or pin.is_empty() or (pin.ref as WeakRef).get_ref() != actor or actor.get_script() != _diag_actor:
		_observer_error = "prepare callback does not name the exact retained Actor/caller"
		return
	var counts: Dictionary = _call_counts.get(id, {"preview_start": 0, "start": 0, "accepted_prepare": 0, "rejected_prepare": 0})
	counts[caller] += 1
	counts["accepted_prepare" if prepared.get("accepted") == true else "rejected_prepare"] += 1
	_call_counts[id] = counts
	if prepared.get("accepted") == true or _first_refusals.has(id): return
	if String(prepared.get("reason", "")) != "Authored encounter context and fixed normalized world direction required": return
	var before: PackedByteArray = var_to_bytes([prepared, context, target, direction])
	var heading: Vector3 = actor.get("_facing")
	var kept_stack: Array[Dictionary] = []
	for index: int in range(mini(stack.size(), STACK_LIMIT)):
		var row: Variant = stack[index]
		kept_stack.append(_close_value(row) if row is Dictionary else {"unexpected_frame": _close_value(row)})
	var receipt: Dictionary = {"caller": caller, "source_id": id, "source_instance_id": actor.get_instance_id(), "actor_script_resource_id": str(_actor_resource_id), "prepared_rejection": _close_value(prepared), "context": _context_receipt(context), "actual_public_target": _vector_receipt(target), "direction": _vector_receipt(direction), "heading": _vector_receipt(heading), "source_position": _vector_receipt(actor.global_position), "source_velocity": _vector_receipt((actor as CharacterBody3D).velocity), "hero_position": _vector_receipt(game.player.global_position), "approach_enabled": configuration.get("approach", {}).get("enabled", false), "source_cycle": int(actor.get("_cycle")), "source_reservation_id": String(actor.get("_reservation_id")), "source_last_error_before_original_return": String(actor.get("last_error")), "native_time": _direct_time(), "stack": kept_stack, "stack_total": stack.size(), "stack_kept": kept_stack.size(), "stack_truncated": stack.size() > STACK_LIMIT}
	receipt["passed_context_and_result_unchanged"] = before == var_to_bytes([prepared, context, target, direction])
	if not receipt.passed_context_and_result_unchanged: _observer_error = "passive observer changed supplied context/result/direction"
	_first_refusals[id] = receipt
	_trace("first_actual_prepare_refusal", receipt)


func _observe_publication(id: String, answer: Dictionary) -> void:
	if not _live or _finished or not is_instance_valid(game.active_level): return
	# This signal originates AFTER the base parent's final custody guard.
	# Full's own recorder was connected in _ready before this external listener.
	# Inspect direct retained fields only, never query/prune native reservations.
	var level: CinderLevel = game.active_level
	var sources: Dictionary = level.get("sources")
	var actor: Node3D = sources.get(id) as Node3D
	var pin: Dictionary = _source_pins.get(id, {})
	var scheduler: CinderThreatScheduler = level.get("scheduler") as CinderThreatScheduler
	var rid: String = String(answer.get("reservation_id", ""))
	var framing: Dictionary = (level.get("_framing") as Dictionary).get(id, {})
	var accepted_frame: Dictionary = (level.get("_accepted_frames") as Dictionary).get(id, {})
	var protocols: Dictionary = (level.get("_protocols") as Dictionary).get("crossed", {})
	var protocol: RefCounted = protocols.get(id) as RefCounted
	var records: Dictionary = scheduler.get("_reservations")
	var record: Dictionary = records.get(rid, {})
	var matches: bool = answer.get("accepted") == true and not rid.is_empty() and not pin.is_empty() and is_instance_valid(actor) and (pin.ref as WeakRef).get_ref() == actor and actor.get_instance_id() == pin.instance_id and actor.get_script() == _diag_actor and actor == (level.get("_retained_sources") as Dictionary).get(id) and actor.get("_hero") == game.player and actor.get("_scheduler") == scheduler and actor.get("_reservation_id") == rid and int(actor.get("_cycle")) > int(pin.cycle) and level.get("beat_index") == 2 and level.get("room_stage") == "active" and not paused and is_instance_valid(protocol) and protocol.get_script() == _diag_protocol and framing.get("reservation_id") == rid and accepted_frame.get("reservation_id") == rid and record.get("source_instance_id") == actor.get_instance_id() and record.get("_owner") is WeakRef and (record._owner as WeakRef).get_ref() == actor
	var receipt: Dictionary = {"scope": "outside_window_tail" if _window_closed else "inside_window", "source_id": id, "source_instance_id": actor.get_instance_id() if is_instance_valid(actor) else 0, "cycle_before_resume": pin.get("cycle", -1), "actual_cycle": int(actor.get("_cycle")) if is_instance_valid(actor) else -1, "actual_reservation_id": String(actor.get("_reservation_id")) if is_instance_valid(actor) else "", "published_reservation_id": rid, "actual_scheduler_id": scheduler.get_instance_id(), "actual_hero_id": game.player.get_instance_id(), "actual_protocol_id": str(protocol.get_instance_id()) if is_instance_valid(protocol) else "", "post_final_custody_direct_correspondence": matches, "native_time": _direct_time(), "published_answer": _close_value(answer)}
	if _window_closed:
		_tail_publications.append(receipt)
		return
	if not matches:
		_observer_error = "actual parent publication did not match retained cycle/lease/identity/recorded framing"
		return
	if not _window_started: _observe_physics_boundary()
	if _window_closed:
		receipt.scope = "outside_window_tail"
		_tail_publications.append(receipt)
		return
	_admission = receipt
	_trace("actual_final_native_admission", receipt)
	_close_window("actual_final_native_admission")


func _context_receipt(context: Dictionary) -> Dictionary:
	var keys: Array = context.keys()
	keys.sort()
	var rows: Array[Dictionary] = []
	for key: Variant in keys:
		rows.append({"key": _close_value(key), "key_type": type_string(typeof(key)), "value_type": type_string(typeof(context[key])), "value": _close_value(context[key])})
	return {"actual_key_count": context.size(), "actual_keys_and_types": rows}


func _close_value(value: Variant) -> Variant:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_STRING: return value
		TYPE_INT: return {"native_type": "int64", "decimal": str(value)} if absf(float(value)) > 9007199254740991.0 else value
		TYPE_FLOAT: return _float_receipt(value)
		TYPE_VECTOR2: return {"type": "Vector2", "x": _float_receipt(value.x), "y": _float_receipt(value.y)}
		TYPE_VECTOR3: return _vector_receipt(value)
		TYPE_RECT2: return {"type": "Rect2", "position": _close_value(value.position), "size": _close_value(value.size)}
		TYPE_OBJECT:
			return {"type": "Object", "native_class": value.get_class() if is_instance_valid(value) else "freed", "instance_id": str(value.get_instance_id()) if is_instance_valid(value) else ""}
		TYPE_ARRAY:
			var items: Array = []
			for item: Variant in value: items.append(_close_value(item))
			return {"type": "Array", "size": value.size(), "items": items}
		TYPE_DICTIONARY:
			var closed: Dictionary = {}
			for key: Variant in value: closed[String(key)] = _close_value(value[key])
			return closed
	return {"type": type_string(typeof(value)), "text": str(value)}


func _float_receipt(value: float) -> Dictionary:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	return {"finite": is_finite(value), "value": value if is_finite(value) else null, "text": str(value), "raw_ieee754_f64_le": bytes.hex_encode()}


func _vector_receipt(value: Vector3) -> Dictionary:
	return {"type": "Vector3", "finite": value.is_finite(), "x": _float_receipt(value.x), "y": _float_receipt(value.y), "z": _float_receipt(value.z), "length": _float_receipt(value.length())}


func _direct_time() -> Dictionary:
	var result: Dictionary = {"physics_frame": Engine.get_physics_frames(), "process_frame": Engine.get_process_frames(), "elapsed_wall_us": Time.get_ticks_usec() - _started_us, "hero_clock_s": 0.0, "scheduler_clock_s": 0.0}
	if is_instance_valid(game) and is_instance_valid(game.player): result.hero_clock_s = float(game.player.get("_world_action_clock"))
	if is_instance_valid(game) and is_instance_valid(game.active_level):
		var scheduler: Node = game.active_level.get("scheduler") as Node
		if is_instance_valid(scheduler): result.scheduler_clock_s = float(scheduler.get("_clock"))
	result.hero_clock_bits = _float_receipt(float(result.hero_clock_s))
	result.scheduler_clock_bits = _float_receipt(float(result.scheduler_clock_s))
	return result


func _time_delta(before: Dictionary, after: Dictionary) -> Dictionary:
	if before.is_empty() or after.is_empty(): return {"not_observed": true}
	return {"physics_frames": int(after.physics_frame) - int(before.physics_frame), "process_frames": int(after.process_frame) - int(before.process_frame), "hero_clock_s": float(after.hero_clock_s) - float(before.hero_clock_s), "scheduler_clock_s": float(after.scheduler_clock_s) - float(before.scheduler_clock_s), "wall_us": int(after.elapsed_wall_us) - int(before.elapsed_wall_us)}


func _can_tick() -> bool:
	return not _finished and is_instance_valid(game) and is_instance_valid(game.active_level) and is_instance_valid(game.player) and not paused and not game.player.dead and game.campaign_error.is_empty()


func _trace(label: String, fields: Dictionary = {}) -> void:
	var row: Dictionary = {"event": label, "elapsed_wall_us": Time.get_ticks_usec() - _started_us}
	for key: String in fields: row[key] = fields[key]
	var wire: String = Exact.stringify(_diagnostic_json_keys(row))
	if wire.is_empty():
		_observer_error = "diagnostic row was not representable without losing native details: " + label
		print("CP2_ADMISSION_DIAGNOSTIC_UNENCODABLE: ", label)
	else: print("CP2_ADMISSION_DIAGNOSTIC: ", wire)


func _diagnostic_json_keys(value: Variant) -> Variant:
	# Diagnostic field maps may contain native StringName keys introduced by
	# dictionary dot assignment. Preserve values/bits and normalize ONLY map
	# keys; the recorded context rows still retain each actual key/type.
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value:
			result[String(key)] = _diagnostic_json_keys(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_diagnostic_json_keys(item))
		return result
	return value


func _expect(condition: bool, message: String) -> bool:
	checks += 1
	if condition: print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
	return condition


func _close_shell() -> void:
	if is_instance_valid(game):
		if is_instance_valid(game.active_level):
			if game.active_level.is_connected("native_admission_published", _observe_publication): game.active_level.disconnect("native_admission_published", _observe_publication)
			game.active_level.exit_level()
		_stop_stage_audio(game)
		game.free() # Synchronous disposal BEFORE either cached Script restoration.
	game = null
	paused = true


func _restore_memory_sources() -> void:
	if _actor_changed:
		_diag_actor.source_code = _actor_original
		var error: Error = _diag_actor.reload()
		_expect(error == OK and _diag_actor.get_instance_id() == _actor_resource_id and load(STAGE_ACTOR) == _diag_actor and _diag_actor.source_code.sha256_text() == ACTOR_SHA, "after synchronous Shell free, original cached Actor source reloads with exact identity/hash")
	if _route_changed:
		_diag_route.source_code = _route_original
		var error: Error = _diag_route.reload()
		_expect(error == OK and _diag_route.get_instance_id() == _route_resource_id and load(ROUTE_PATH) == _diag_route and _diag_route.source_code.sha256_text() == CURRENT_ROUTE_SHA, "after synchronous Shell free, original cached current Route source reloads with exact identity/hash")
	if _observer_installed: remove_meta(OBSERVER_META)
	_expect(not has_meta(OBSERVER_META) and _disk_pins_match(), "observer metadata is removed and original production Actor/Route/Protocol disk bytes remain exact")


func _finish() -> void:
	if _finished: return
	_finished = true
	_live = false
	if physics_frame.is_connected(_observe_physics_boundary): physics_frame.disconnect(_observe_physics_boundary)
	var refs: Array[Dictionary] = []
	if is_instance_valid(game) and is_instance_valid(game.active_level): refs = _old_refs()
	_close_shell()
	_expect_refs_freed(refs, "ordinary diagnostic disposal")
	_restore_memory_sources()
	paused = false
	await create_timer(0.2, true).timeout
	if _seeded or not _registry_text.is_empty():
		_cleanup_saves()
		_expect(FileAccess.get_sha256(STAGE_ORIGINAL) == STAGE_ORIGINAL_SHA and FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_text, "only unique user save directory is removed; supplied original CP2 and canonical registry bytes stay exact")
	_expect(_observer_error.is_empty(), "all actual diagnostic rows are losslessly representable: " + _observer_error)
	var complete: bool = failures == 0 and (_parse_only or not _admission.is_empty())
	print("CP2 native admission diagnostic: %d checks, %d failures; scope_complete=%s; outcome=%s; parse_observers_only=%s; native_physics_process_await_pairs=%d/%d; finite passive window only, catch-up tail separately recorded; no full-route/performance/campaign acceptance claim." % [checks, failures, str(complete), _outcome, str(_parse_only), _await_pairs, MAX_AWAIT_PAIRS])
	quit(1 if failures > 0 else (0 if complete else 2))


func _stage_seed_original() -> bool:
	if not _expect(FileAccess.file_exists(STAGE_ORIGINAL) and FileAccess.get_sha256(STAGE_ORIGINAL) == STAGE_ORIGINAL_SHA and FileAccess.get_file_as_bytes(STAGE_ORIGINAL).size() == STAGE_ORIGINAL_BYTES, "Root's preserved original format2 envelope matches its immutable byte receipt"):
		return false
	_registry_text = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var raw: Variant = JSON.parse_string(_registry_text)
	if not _expect(raw is Dictionary, "actual canonical registry is readable before TEST metadata clone"): return false
	_stage_registry = (raw as Dictionary).duplicate(true)
	for row: Dictionary in _stage_registry.levels:
		if row.id == "A1-L3":
			row.readiness = "accepted"
			row.accepted_commit = STAGE_COMMIT
			row.scene_path = STAGE_SCENE
			row.api_revision = "campaign-level-1"
	var test_registry := Registry.new(_stage_registry)
	var current_registry := Registry.new(raw)
	var other_metadata_unchanged: bool = current_registry.last_error.is_empty()
	for row: Dictionary in _stage_registry.levels:
		if row.id != "A1-L3":
			other_metadata_unchanged = other_metadata_unchanged and Exact.stringify(test_registry.entry(row.id)) == Exact.stringify(current_registry.entry(row.id))
	if not _expect(test_registry.last_error.is_empty() and test_registry.scene_error("A1-L3").is_empty() and test_registry.entry("A1-L3").accepted_commit == STAGE_COMMIT and other_metadata_unchanged, "TEST ONLY in-memory exact L3 metadata preserves all other current registry entries: " + test_registry.last_error): return false
	# SaveStore deliberately accepts user:// only. Copy original envelope bytes
	# ONCE to the new PID path, then use its real checked exact-format2 reader.
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_test_root)) == OK and DirAccess.copy_absolute(ProjectSettings.globalize_path(STAGE_ORIGINAL), ProjectSettings.globalize_path(_test_root + "campaign.json")) == OK and FileAccess.get_sha256(_test_root + "campaign.json") == STAGE_ORIGINAL_SHA, "only new isolated user path receives an exact original envelope copy"): return false
	var store := Store.new(_test_root + "campaign.json")
	_stage_payload = store.read_payload()
	if not _expect(store.last_error.is_empty() and not store.loaded_backup and store.generation == 8 and not _stage_payload.is_empty(), "actual checked SaveStore reads original generation8 without a synthetic reconstructed seed: " + store.last_error): return false
	var story: Dictionary = _stage_payload.get("story", {})
	var unit: Dictionary = story.get("snapshot", {})
	var local: Dictionary = unit.get("level", {}).get("local", {})
	if not _expect(_stage_payload.completed_main == ["A1-L1", "A1-L2"] and story.get("kind") == "story" and story.get("level_id") == "A1-L3" and unit.get("level_id") == "A1-L3" and local.get("beat_index") == 2 and local.get("room_stage") == "approach" and local.get("completed_beats") == ["umbrella-grove", "breathing-chamber"] and local.get("actors", {}).size() == 19 and not Exact.stringify(unit).is_empty() and Exact.stringify(unit) == Exact.stringify(story.get("checkpoint", {})), "original genuinely persisted CP2 has its actual completed rooms and nineteen-source checkpoint, without inventing progression"): return false
	_stage_expected_session = _stage_payload.duplicate(true)
	for id: String in StageEquipment.IMPLEMENTED_IDS:
		if not _stage_expected_session.unlocked_equipment.has(id): _stage_expected_session.unlocked_equipment.append(id)
	return true


func _new_shell() -> CinderCampaignShell:
	var result: CinderCampaignShell = Shell.new()
	_expect(result.configure_runtime(_stage_registry, _test_root + "campaign.json", _test_root + "settings.json", _test_root + "preferences.json"), "actual Shell uses TEST registry clone and only fresh PID save/settings paths")
	root.add_child(result)
	return result


func _actual_entry() -> bool:
	return _expect(game.campaign_error.is_empty() and paused and game.menu.page_name() == "resume" and is_instance_valid(game.active_level) and is_instance_valid(game.player) and game.active_level.level_id == "A1-L3" and game.active_level.get_script().resource_path == STAGE_SCRIPT and game.active_level.scene_file_path == STAGE_SCENE and game.active_level.hero == game.player and game.active_level.effects == game.fx and (game.active_level.get("sources") as Dictionary).size() == 19 and int(game.active_level.get("beat_index")) == 2 and game.active_level.get("room_stage") == "approach", "actual Full CP2 owns one shared Hero/effects and nineteen original native actors at real paused Resume: " + game.campaign_error)


func _place_hero_once() -> bool:
	var actor: CinderPlayer = game.player
	var before_clock: float = actor.get_world_action_clock()
	var before_hp: float = actor.hp
	var before_shells: int = actor.shells
	var before_input: String = Exact.stringify(game.get_input_observation_state())
	var before_anchor: Vector2 = game.get_aim_anchor_normalized()
	var before_basis: Basis = actor.global_basis
	var before_camera: Transform3D = game.camera.global_transform
	_trace("test_hero_placement_before")
	actor.global_position = Vector3(0.0, actor.global_position.y, -10.4)
	_trace("test_hero_placement_after", {"test_only": true, "placement_count": 1})
	return _expect(not paused and not actor.dead and actor.get_world_action_clock() == before_clock and actor.hp == before_hp and actor.shells == before_shells and Exact.stringify(game.get_input_observation_state()) == before_input and game.get_aim_anchor_normalized() == before_anchor and actor.global_basis == before_basis and game.camera.global_transform == before_camera and game.active_level.get("beat_index") == 2 and game.active_level.get("room_stage") == "approach", "ONE explicitly supported TEST Hero placement retains actual Y/basis/resources/input/clocks/camera/CP2 before any native tick")


func _observe_restore_node(node: Node) -> void:
	super._observe_restore_node(node)
	if not _watching_restore: return
	if node.get_script() != null and node.get_script().resource_path == STAGE_ACTOR:
		node.connect("hit_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: _restore_events.append("C31/C32.hit_resolved"))
		node.connect("defeated", func(_id: String) -> void: _restore_events.append("C31/C32.defeated"))
	elif node is CinderThreatScheduler:
		node.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _restore_events.append("scheduler.invalidated"))
	elif node is CinderSporeField:
		node.activated.connect(func(_domain: Dictionary) -> void: _restore_events.append("field.activated"))
	elif node is CinderSporeRepulsion:
		node.reaction_started.connect(func(_id: String, _episode: String) -> void: _restore_events.append("consumer.reaction_started"))
		node.placement_rejected.connect(func(_id: String, _reason: String) -> void: _restore_events.append("consumer.placement_rejected"))


func _stop_stage_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer3D: node.call("stop")
	for child: Node in node.get_children(): _stop_stage_audio(child)
