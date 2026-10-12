extends "res://tests/act1_l2_registration_smoke.gd"
## Narrow pure-plan/cost diagnostic; Root attributes selection/native results.
## Loads the ORIGINAL genuine CP2 envelope into a NEW isolated PID directory.
## Only TEST registry metadata and ONE Hero placement are supplied. No actor
## injury, progress/phase/camera/clock setter, acceptance or full-route claim.
## At most one physics/process await pair AFTER Resume/placement. Native
## Engine frame indices/clocks expose catch-up physics rather than asserting
## one simulation tick per render frame. A blocked call needs Root's host bound.
## Original Attempt41 packet stays immutable; current Attempts6701 may append
## the thirteen implemented equipment IDs only, never change its saved unit.

const StageEquipment = preload("res://scripts/equipment.gd")
const STAGE_ORIGINAL: String = "res://.cinder/a1-l3-stage-source/campaign.json"
const STAGE_ORIGINAL_SHA: String = "c1f4eb2333f61248998844dd7a13ecdb4cf2505448f7ab787cf984a78083c4ef"
const STAGE_ORIGINAL_BYTES: int = 271077
const STAGE_COMMIT: String = "0129e260a25405dc1e24d1869bbe607884eca430"
const STAGE_SCENE: String = "res://scenes/acts/act1/a1_l3.tscn"
const STAGE_SCRIPT: String = "res://scripts/acts/act1/mushroom_caverns_full.gd"
const STAGE_ACTOR: String = "res://scripts/acts/act1/mushroom_selenite.gd"
const STAGE_MAX_TICKS: int = 1

var _stage_registry: Dictionary = {}
var _stage_payload: Dictionary = {}
var _stage_expected_session: Dictionary = {}
var _stage_started_us: int = 0
var _stage_ticks: int = 0
var _stage_paused_probes: bool = false
var _stage_quiet_events: int = -1
var _stage_room_returned: bool = false
var _stage_view_returned: bool = false
var _stage_outcome: String = "not_started"


func _initialize() -> void:
	_stage_started_us = Time.get_ticks_usec()
	_test_root = "user://test-act1-l3-stage-diagnostic-%d-%d/" % [OS.get_process_id(), _stage_started_us]
	_expected_commit = STAGE_COMMIT
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--paused-probes": _stage_paused_probes = true
		else: _expect(false, "unsupported diagnostic selector: " + argument)
	node_added.connect(_observe_restore_node)
	# This observes only a returning event loop, not a blocked synchronous call.
	create_timer(120.0, true).timeout.connect(func() -> void:
		if not _finished:
			_trace("event_loop_watchdog")
			_stage_outcome = "returning_event_loop_watchdog"
			_expect(false, "stage diagnostic returns within its event-loop watchdog")
			_finish())
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	paused = true
	_trace("setup_before")
	if failures > 0 or not _stage_seed_original(): _finish(); return
	_restore_events.clear()
	_watching_restore = true
	_trace("new_shell_before")
	game = _new_shell()
	_trace("new_shell_after")
	await _settle()
	if not _title_valid("genuine preserved CP2 in isolated diagnostic") or not _expect(game.player == null, "fresh actual Title has NULL Player before GUI Continue"):
		_finish(); return
	var actual_session: String = Exact.stringify(game.attempts.state())
	var expected_session: String = Exact.stringify(_stage_expected_session)
	var disk := Store.new(_test_root + "campaign.json")
	var actual_disk: Dictionary = disk.read_payload()
	if not _expect(not actual_session.is_empty() and actual_session == expected_session and disk.last_error.is_empty() and Exact.stringify(actual_disk) == expected_session, "actual load preserves original entire CP2 payload except supported four-to-thirteen availability migration"):
		_finish(); return
	_trace("gui_continue_before")
	await _click(_find("ContinueStoryButton") as Control)
	_trace("gui_continue_after")
	_watching_restore = false
	_stage_quiet_events = _restore_events.size()
	if not _actual_entry(): _finish(); return
	_trace("exact_recapture_before")
	var restored: Dictionary = game.capture_campaign_snapshot()
	_trace("exact_recapture_after")
	var actual_wire: String = Exact.stringify(restored)
	var original_wire: String = Exact.stringify(_stage_payload.story.snapshot)
	if not _expect(not actual_wire.is_empty() and actual_wire == original_wire and _restore_events.is_empty(), "fresh GUI Continue quietly reconstructs the EXACT genuine nineteen-source CP2 Player/level/shell unit"):
		_finish(); return
	_trace("exact_recapture_match", {"unit_bytes": actual_wire.to_utf8_buffer().size(), "unit_sha256": actual_wire.sha256_text(), "quiet_events": _stage_quiet_events, "available_before": _stage_payload.unlocked_equipment.size(), "available_after": game.attempts.state().unlocked_equipment.size()})
	if _stage_paused_probes:
		_run_paused_probes()
		if not _expect(Exact.stringify(game.capture_campaign_snapshot()) == original_wire, "pure paused probes leave the exact original entire native unit unchanged"): _finish(); return
	_trace("gui_resume_before")
	if not _resume_consumed("preserved genuine CP2"):
		_finish(); return
	_trace("gui_resume_after")
	if not _place_hero_once(): _finish(); return
	# Same original predicates, explicitly instrumented and sharing ONE tick.
	_stage_outcome = "bounded_room_wait"
	_trace("wait_room_before")
	_stage_room_returned = await _wait_stage_room()
	_trace("wait_room_after", {"predicate": _stage_room_returned})
	if _stage_room_returned:
		_stage_outcome = "bounded_view_wait"
		_trace("wait_current_view_before")
		_stage_view_returned = await _wait_stage_view()
		_trace("wait_current_view_after", {"predicate": _stage_view_returned})
	_stage_outcome = "room_and_view_returned" if _stage_view_returned else ("room_returned_view_not_ready_in_budget" if _stage_room_returned else "room_not_active_in_budget")
	_trace("bounded_outcome", {"room_predicate": _stage_room_returned, "view_predicate": _stage_view_returned, "tick_budget": STAGE_MAX_TICKS})
	_finish()


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
	if not _expect(test_registry.last_error.is_empty() and test_registry.scene_error("A1-L3").is_empty() and test_registry.entry("A1-L3").accepted_commit == STAGE_COMMIT and not test_registry.is_playable("A1-L4"), "TEST ONLY in-memory exact L3 metadata leaves canonical registry and unavailable L4 unchanged: " + test_registry.last_error): return false
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


func _wait_stage_room() -> bool:
	while true:
		if not _can_tick(): return false
		_trace("room_predicate_before")
		var accepted: bool = game.active_level.get("beat_index") == 2 and game.active_level.get("room_stage") == "active"
		_trace("room_predicate_after", {"predicate": accepted})
		if accepted: return true
		if _stage_ticks >= STAGE_MAX_TICKS or not _can_tick(): return false
		await _one_stage_tick("wait_room")
	return false


func _wait_stage_view() -> bool:
	while true:
		if not _can_tick(): return false
		_trace("framing_provider_before")
		var started: int = Time.get_ticks_usec()
		var points: Array = game.active_level.camera_framing_points()
		_trace("framing_provider_after", {"call_us": Time.get_ticks_usec() - started, "point_count": points.size(), "point_error": _short(game.active_level.last_camera_framing_error), "camera_framing_state": game.get_camera_framing_state()})
		_trace("hero_response_before")
		started = Time.get_ticks_usec()
		var response: Dictionary = game.player.get_threat_response_state()
		_trace("hero_response_after", {"call_us": Time.get_ticks_usec() - started, "stable": response.get("stable", false), "grounded": response.get("motion", {}).get("grounded", false)})
		_trace("containment_before")
		started = Time.get_ticks_usec()
		var containment: String = game.camera_framing_error(points)
		_trace("containment_after", {"call_us": Time.get_ticks_usec() - started, "error": _short(containment)})
		if not points.is_empty() and response.get("stable") == true and response.get("motion", {}).get("grounded") == true and containment.is_empty(): return true
		if _stage_ticks >= STAGE_MAX_TICKS: return false
		await _one_stage_tick("wait_current_view")
	return false


func _one_stage_tick(label: String) -> void:
	_stage_ticks += 1
	_trace(label + ".physics_await_before")
	await physics_frame
	_trace(label + ".physics_await_after")
	_trace(label + ".process_await_before")
	await process_frame
	_trace(label + ".process_await_after")


func _can_tick() -> bool:
	return not _finished and is_instance_valid(game) and is_instance_valid(game.active_level) and is_instance_valid(game.player) and not paused and not game.player.dead and game.campaign_error.is_empty()


func _run_paused_probes() -> void:
	_trace("paused_scenery_before")
	var started: int = Time.get_ticks_usec()
	var error: String = game.active_level.call("_scenery_error")
	_trace("paused_scenery_after", {"call_us": Time.get_ticks_usec() - started, "error": _short(error)})
	var protocols: Dictionary = game.active_level.get("_protocols")
	var breathing: Dictionary = protocols.get("crossed", {})
	if not breathing.is_empty():
		var protocol: RefCounted = breathing.values()[0]
		_trace("paused_native_protocol_before")
		started = Time.get_ticks_usec()
		error = protocol.call("binding_error")
		_trace("paused_native_protocol_after", {"call_us": Time.get_ticks_usec() - started, "error": _short(error)})
	var crossed: Dictionary = protocols.get("crossed", {})
	var total_started: int = Time.get_ticks_usec()
	var probe_errors: Dictionary = {}
	for id: String in crossed:
		started = Time.get_ticks_usec()
		error = crossed[id].call("binding_error")
		probe_errors[id] = error
		_trace("paused_crossed_protocol", {"source_id": id, "call_us": Time.get_ticks_usec() - started, "error": _short(error)})
	_trace("paused_crossed_protocol_total", {"source_count": crossed.size(), "call_us": Time.get_ticks_usec() - total_started, "errors": probe_errors})
	var consumers: Dictionary = game.active_level.get("_consumers")
	var consumer: Node = consumers.get("crossed") as Node
	if is_instance_valid(consumer):
		started = Time.get_ticks_usec()
		error = consumer.call("_binding_error")
		_trace("paused_crossed_consumer_binding", {"call_us": Time.get_ticks_usec() - started, "error": _short(error)})
	_trace("paused_response_context_before")
	started = Time.get_ticks_usec()
	var context: Dictionary = game.active_level.call("response_context")
	_trace("paused_response_context_after", {"call_us": Time.get_ticks_usec() - started, "field_count": context.size(), "floor_count": context.get("floor_regions", []).size()})
	_trace("paused_framing_provider_before")
	started = Time.get_ticks_usec()
	var points: Array = game.active_level.camera_framing_points()
	_trace("paused_framing_provider_after", {"call_us": Time.get_ticks_usec() - started, "point_count": points.size(), "error": _short(game.active_level.last_camera_framing_error)})
	_trace("paused_containment_before")
	started = Time.get_ticks_usec()
	error = game.camera_framing_error(points)
	_trace("paused_containment_after", {"call_us": Time.get_ticks_usec() - started, "error": _short(error)})
	# These are observations, not permissions or substitutes for normal guards.


func _trace(stage: String, details: Dictionary = {}) -> void:
	var row: Dictionary = {"engine_pid": OS.get_process_id(), "stage": stage, "wall_us": Time.get_ticks_usec() - _stage_started_us, "ticks_started": _stage_ticks, "physics_frame_index": Engine.get_physics_frames(), "process_frame_index": Engine.get_process_frames(), "paused": paused}
	if is_instance_valid(game):
		row.campaign_error = _short(game.campaign_error)
		if is_instance_valid(game.active_level):
			row.beat_index = game.active_level.get("beat_index")
			row.room_stage = game.active_level.get("room_stage")
			row.encounter_error = _short(String(game.active_level.get("last_encounter_error")))
			var scheduler: CinderThreatScheduler = game.active_level.get("scheduler")
			if is_instance_valid(scheduler):
				row.scheduler_clock_s = scheduler.get_clock()
				row.scheduler_clock_bits = _clock_bits(scheduler.get_clock())
		if is_instance_valid(game.player):
			row.player_clock_s = game.player.get_world_action_clock()
			row.player_clock_bits = _clock_bits(game.player.get_world_action_clock())
			row.hero_position = Codec.vector3(game.player.global_position)
			row.hp = game.player.hp
			row.shells = game.player.shells
			row.dead = game.player.dead
	row.merge(details, true)
	print("A1_L3_STAGE ", JSON.stringify(row))


func _clock_bits(value: float) -> String:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	return bytes.hex_encode()


func _short(value: String) -> String:
	return value.substr(0, 256)


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


func _close_shell() -> void:
	if is_instance_valid(game):
		if is_instance_valid(game.active_level): game.active_level.exit_level()
		_stop_stage_audio(game)
		game.free()
	game = null
	paused = true


func _stop_stage_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer3D: node.call("stop")
	for child: Node in node.get_children(): _stop_stage_audio(child)


func _expect(condition: bool, message: String) -> bool:
	checks += 1
	if condition: print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
		_trace("assertion_failure", {"message": _short(message)})
	return condition


func _finish() -> void:
	if _finished: return
	_finished = true
	_trace("cleanup_before", {"outcome": _stage_outcome})
	_close_shell()
	paused = false
	await create_timer(0.2, true).timeout
	_cleanup_saves() # ONLY the unique diagnostic PID directory.
	_expect(FileAccess.get_sha256(STAGE_ORIGINAL) == STAGE_ORIGINAL_SHA and FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_text, "diagnostic preserves original Root envelope and canonical registry bytes")
	_trace("cleanup_after", {"outcome": _stage_outcome})
	print("A1-L3 stage diagnostic: %d checks, %d failures; outcome=%s; physics_process_await_pairs=%d/1; TEST registry clone +ONE Hero placement; no activation/full-route/acceptance/performance claim." % [checks, failures, _stage_outcome, _stage_ticks])
	quit(0 if failures == 0 else 1)
