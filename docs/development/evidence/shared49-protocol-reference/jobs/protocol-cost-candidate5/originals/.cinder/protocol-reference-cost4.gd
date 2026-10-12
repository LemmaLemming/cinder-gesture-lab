extends "res://.cinder/a1-l3-stage-diagnostic4.gd"
## Private bounded direct-query measurement, not a playthrough or level gate.
## Real original CP2 -> GUI Continue/Resume -> ONE TEST Hero placement -> real
## Crossed activation -> public Pause. No actor/progress/camera/clock setters.
## Only installed8 native Protocols are timed; all receipts are outside timing.

const NativeProtocol = preload("res://scripts/environment/scheduler_spore_source_protocol.gd")
const CostRoute = preload("res://scripts/combat/repulsion_route.gd")
var _cost_label: String = "unset"
var _cost_events: Array = []
var _cost_sources: Array[String] = []
var _cost_rows: Array[Dictionary] = []
var _cost_packet_error: String = ""
var _cost_native_error: String = ""


func _initialize() -> void:
	_stage_started_us = Time.get_ticks_usec()
	_test_root = "user://test-protocol-reference-cost-%d-%d/" % [OS.get_process_id(), _stage_started_us]
	_expected_commit = STAGE_COMMIT
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--measurement-label="): _cost_label = argument.trim_prefix("--measurement-label=")
		else: _expect(false, "unsupported direct-query measurement selector")
	node_added.connect(_observe_restore_node)
	create_timer(85.0, true).timeout.connect(func() -> void:
		if not _finished:
			_stage_outcome = "returning_event_loop_watchdog"
			_expect(false, "direct-query measurement returns within its event-loop bound")
			_finish())
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	paused = true
	_trace("cost_setup", {"measurement_label": _cost_label})
	if failures > 0 or not _stage_seed_original(): _finish(); return
	_restore_events.clear()
	_watching_restore = true
	game = _new_shell()
	await _settle()
	if not _title_valid("original CP2 direct-query measurement") or not _expect(game.player == null, "actual Title retains NULL Player before Continue"): _finish(); return
	await _click(_find("ContinueStoryButton") as Control)
	_watching_restore = false
	if not _actual_entry(): _finish(); return
	var original: String = Exact.stringify(_stage_payload.story.snapshot)
	var actual: String = Exact.stringify(game.capture_campaign_snapshot())
	if not _expect(not actual.is_empty() and actual == original and _restore_events.is_empty(), "actual fresh native Continue exactly recaptures the original complete19-source CP2 without gameplay signals"): _finish(); return
	if not _resume_consumed("original CP2 cost probe") or not _place_hero_once(): _finish(); return
	_trace("cost_activation_before")
	_stage_room_returned = await _wait_stage_room()
	_trace("cost_activation_after", {"room_active": _stage_room_returned})
	if not _expect(_stage_room_returned, "real Crossed room activates within the one physics/process await-pair bound"): _finish(); return
	game.request_pause()
	await _settle()
	if not _expect(paused and is_instance_valid(game.active_level) and game.active_level.get("beat_index") == 2 and game.active_level.get("room_stage") == "active", "public Pause settles the actual active Crossed native barrier"): _finish(); return
	var groups: Dictionary = game.active_level.get("_protocols")
	var protocols: Dictionary = groups.get("crossed", {})
	for id: Variant in protocols:
		if typeof(id) == TYPE_STRING: _cost_sources.append(id)
	_cost_sources.sort()
	if not _expect(protocols.size() == 8 and _cost_sources.size() == 8, "measurement contains all8 actual installed Crossed Protocols rather than absent approach resources"): _finish(); return
	for id: String in _cost_sources:
		var protocol: NativeProtocol = protocols[id]
		if not _expect(protocol.get_script() == NativeProtocol and protocol.binding_state().source_id == id and protocol.binding_error().is_empty(), "actual retained exact native Protocol and valid binding: " + id): _finish(); return
	var scheduler: CinderThreatScheduler = game.active_level.get("scheduler")
	var sources: Dictionary = game.active_level.get("sources")
	scheduler.reservation_invalidated.connect(func(id: String, reason: String) -> void: _cost_events.append(["scheduler", id, reason]))
	for id: String in sources:
		var source: Node = sources[id]
		source.connect("hit_resolved", func(source_id: String, cycle: int, result: Dictionary) -> void: _cost_events.append(["hit", source_id, cycle, result]))
		source.connect("defeated", func(source_id: String) -> void: _cost_events.append(["defeat", source_id]))
		source.connect("state_changed", func(state: Dictionary) -> void: _cost_events.append(["source_state", state]))
		var cue: Node = source.call("get_cue")
		cue.connect("state_changed", func(state: Dictionary) -> void: _cost_events.append(["cue_state", state]))
	for retained: Variant in (game.active_level.get("_fields") as Dictionary).values():
		var field: Node = retained
		field.connect("activated", func(state: Dictionary) -> void: _cost_events.append(["field_activated", state]))
		field.connect("state_changed", func(state: Dictionary) -> void: _cost_events.append(["field_state", state]))
	for retained: Variant in (game.active_level.get("_consumers") as Dictionary).values():
		var consumer: Node = retained
		consumer.connect("reaction_started", func(source_id: String, episode_id: String) -> void: _cost_events.append(["reaction", source_id, episode_id]))
		consumer.connect("placement_rejected", func(source_id: String, reason: String) -> void: _cost_events.append(["rejected", source_id, reason]))
	_trace("cost_full_capture_before")
	var optical_unit: Dictionary = game.capture_campaign_snapshot()
	_trace("cost_full_capture_after", {"nonempty": not optical_unit.is_empty(), "snapshot_error": game.campaign_error, "scope": "Optical whole-parent availability is reported separately; no fitting or camera mutation."})
	var before_packets: String = _cost_packets()
	var before_native: String = _cost_native(protocols)
	_trace("cost_receipts", {"packet_nonempty": not before_packets.is_empty(), "native_nonempty": not before_native.is_empty(), "packet_error": _cost_packet_error, "native_error": _cost_native_error})
	if not _expect(not before_packets.is_empty() and not before_native.is_empty(), "before measurement has complete actual19actor/Player/Scheduler packets and fresh immutable native resource receipts"): _finish(); return
	for sample: int in range(3):
		var sample_rows: Array[Dictionary] = []
		for id: String in _cost_sources:
			var started: int = Time.get_ticks_usec()
			var error: String = protocols[id].binding_error()
			var elapsed: int = Time.get_ticks_usec() - started
			var row: Dictionary = {"sample": sample, "source_id": id, "query_us": elapsed, "error": error}
			sample_rows.append(row)
			_cost_rows.append(row)
		# Observe diagnostics BEFORE public snapshot writers can reset them.
		var after_native: String = _cost_native(protocols)
		var after_packets: String = _cost_packets()
		var errors: int = 0
		for row: Dictionary in sample_rows:
			if not row.error.is_empty(): errors += 1
		if not _expect(errors == 0 and before_packets == after_packets and before_native == after_native and _cost_events.is_empty(), "same-clock sample%d retains every complete packet/native receipt/diagnostic and emits no monitored source/cue/field/consumer/Scheduler callback" % sample): _finish(); return
		_trace("cost_sample", {"measurement_label": _cost_label, "sample": sample, "source_count": _cost_sources.size(), "rows": sample_rows, "packet_bytes": before_packets.to_utf8_buffer().size(), "packet_sha256": before_packets.sha256_text(), "native_bytes": before_native.to_utf8_buffer().size(), "native_sha256": before_native.sha256_text(), "queries_are_direct_paused_only": true})
	_stage_outcome = "three_actual_same_clock_samples"
	_finish()


func _cost_packets() -> String:
	_cost_packet_error = ""
	var level: Node = game.active_level
	var controller: CinderThreatScheduler = level.get("scheduler")
	var scheduler: Dictionary = controller.snapshot_state(level.call("scheduler_bindings"))
	var player: Dictionary = game.player.snapshot_state()
	if scheduler.is_empty() or player.is_empty():
		_cost_packet_error = "Scheduler=" + controller.last_snapshot_error + "; Player=" + game.player.last_snapshot_error
		return ""
	var actors: Dictionary = {}
	var sources: Dictionary = level.get("sources")
	for id: String in sources:
		var unit: Dictionary = sources[id].spore_snapshot_state(scheduler, player)
		if unit.is_empty():
			_cost_packet_error = id + ": " + String(sources[id].get("last_snapshot_error"))
			return ""
		actors[id] = unit
	if actors.size() != 19: return ""
	return Exact.stringify({"scheduler": scheduler, "player": player, "actors": actors})


func _cost_native(protocols: Dictionary) -> String:
	_cost_native_error = ""
	var references: Dictionary = {}
	var controller: CinderThreatScheduler = game.active_level.get("scheduler")
	var sources: Dictionary = game.active_level.get("sources")
	var diagnostics: Dictionary = {"campaign": game.campaign_error, "scheduler": [controller.last_error, controller.last_snapshot_error], "sources": {}, "protocols": {}}
	for id: String in sources:
		var source: Node = sources[id]
		diagnostics.sources[id] = [source.get("last_error"), source.get("last_snapshot_error")]
	for id: String in _cost_sources:
		var descriptor: Dictionary = protocols[id].binding_state()
		var environment: Dictionary = CostRoute.static_environment_state(game.active_level.call("_world_root"), game.active_level.call("scheduler_bindings").floors, descriptor.source_environment, Vector3(0.0, float(protocols[id].get("_ground_y")) - float(descriptor.source_environment.foot_offset), 0.0))
		if environment.has("error"):
			_cost_native_error = id + ": " + String(environment.error)
			return ""
		references[id] = {"descriptor": descriptor, "fresh_environment": environment, "fresh_body": NativeProtocol._body_properties(sources[id], sources[id].get_node("BodyCollision"))}
		diagnostics.protocols[id] = protocols[id].last_error
	# The original all-node Script-field diagnostic exceeded its65536-node
	# observation budget. This explicitly scoped direct-query witness includes
	# actual native handles/properties and shared input/optics/session state;
	# complete19actor/Player/Scheduler packets are independently required.
	# It is neither a whole-parent save nor arbitrary Script-internals capture.
	var native_sources: Dictionary = {}
	for id: String in sources:
		var source: CharacterBody3D = sources[id]
		var collision: CollisionShape3D = source.get_node("BodyCollision")
		native_sources[id] = {"node_id": str(source.get_instance_id()), "script_id": str(source.get_script().get_instance_id()), "pose": source.global_transform, "velocity": source.velocity, "grounded": source.is_on_floor(), "collision_id": str(collision.get_instance_id()), "shape_id": str(collision.shape.get_instance_id()), "collision_pose": collision.global_transform, "disabled": collision.disabled}
	var focused: Dictionary = {"paused": paused, "shell_id": str(game.get_instance_id()), "shell_script": str(game.get_script().get_instance_id()), "level_id": str(game.active_level.get_instance_id()), "level_script": str(game.active_level.get_script().get_instance_id()), "hero_id": str(game.player.get_instance_id()), "hero_script": str(game.player.get_script().get_instance_id()), "controller_id": str(controller.get_instance_id()), "controller_script": str(controller.get_script().get_instance_id()), "controller_clock_bits": _clock_bits(controller.get_clock()), "player_clock_bits": _clock_bits(game.player.get_world_action_clock()), "input": game.get_input_observation_state(), "aim": game.get_aim_anchor_normalized(), "camera_pose": game.camera.global_transform, "camera_size": game.camera.size, "camera_projection": game.camera.projection, "camera_focus": game.get("_camera_focus"), "hud_safe": game.hud.combat_safe_rect(), "attempts": game.attempts.state(), "menu": game.menu.page_name(), "beat_index": game.active_level.get("beat_index"), "room_stage": game.active_level.get("room_stage"), "completed_beats": game.active_level.get("completed_beats"), "sources": native_sources}
	_stage_observation_error = ""
	var budget: Array[int] = [0]
	var observed: Variant = _stage_observation_value(focused, budget)
	if not _stage_observation_error.is_empty():
		_cost_native_error = "Focused native witness: " + _stage_observation_error
		return ""
	var wire: String = Exact.stringify({"references": references, "diagnostics": diagnostics, "focused_native": observed, "scope": "Fresh native references and explicit session/input/optics/identity properties plus separately required complete19actor/Player/Scheduler packets; not arbitrary Script internals or optical parent save."})
	if wire.is_empty(): _cost_native_error = "Focused native witness exceeds original Exact admission"
	return wire


func _finish() -> void:
	if _finished: return
	_finished = true
	_trace("cost_cleanup_before", {"measurement_label": _cost_label, "outcome": _stage_outcome, "query_count": _cost_rows.size()})
	_close_shell()
	paused = false
	await create_timer(0.2, true).timeout
	_cleanup_saves()
	_expect(FileAccess.get_sha256(STAGE_ORIGINAL) == STAGE_ORIGINAL_SHA and FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_text, "cost probe preserves original CP2 and canonical registry bytes")
	_trace("cost_cleanup_after", {"measurement_label": _cost_label, "outcome": _stage_outcome})
	print("Protocol reference cost: %d checks, %d failures; queries=%d; label=%s; outcome=%s; direct paused queries only; no FPS/whole-route/acceptance/cause claim." % [checks, failures, _cost_rows.size(), _cost_label, _stage_outcome])
	quit(0 if failures == 0 else 1)
