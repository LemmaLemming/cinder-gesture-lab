extends "res://.cinder/spore-fusion-measure-prep/stage-current-registry.gd"
## PRIVATE uninstrumented paired whole-window measurement over one actual native interval.
## SOURCE ONLY: unparsed/unexecuted until Root explicitly selects copies.
## Real original CP2 -> GUI Continue/Resume -> ONE TEST Hero placement -> real
## Crossed activation -> public Pause. No actor/progress/camera/clock setters.
## All normal actor/Scheduler/Player callbacks run; receipts stay outside timing.

const NativeProtocol = preload("res://scripts/environment/scheduler_spore_source_protocol.gd")
const CostRoute = preload("res://scripts/combat/repulsion_route.gd")
var _cost_label: String = "unset"
var _cost_sources: Array[String] = []
var _cost_packet_error: String = ""
var _cost_native_error: String = ""
var _running_events: Array = []
var _running_watch: bool = false
var _running_overflow: bool = false
var _running_frame: int = 0
var _start_observation: Dictionary = {}


func _initialize() -> void:
	_stage_started_us = Time.get_ticks_usec()
	_test_root = "user://test-protocol-reference-cost-%d-%d/" % [OS.get_process_id(), _stage_started_us]
	_expected_commit = STAGE_COMMIT
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--measurement-label="): _cost_label = argument.trim_prefix("--measurement-label=")
		else: _expect(false, "unsupported direct-query measurement selector")
	var selector := RegEx.new()
	selector.compile("^[a-z0-9-]+$")
	_expect(_cost_label != "unset" and selector.search(_cost_label) != null, "explicit safe private job label is supplied")
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
	var groups: Dictionary = game.active_level.get("_protocols")
	var protocols: Dictionary = groups.get("crossed", {})
	for id: Variant in protocols:
		if typeof(id) == TYPE_STRING: _cost_sources.append(id)
	_cost_sources.sort()
	if not _expect(protocols.size() == 8 and _cost_sources.size() == 8 and not paused, "actual active Crossed owns all8 native Protocols before measured interval"): _finish(); return
	var frame_before: int = Engine.get_physics_frames()
	var process_before: int = Engine.get_process_frames()
	var clock_before: float = game.player.get_world_action_clock()
	var scheduler: CinderThreatScheduler = game.active_level.get("scheduler")
	var scheduler_before: float = scheduler.get_clock()
	var hp_before: float = game.player.hp
	var actor_ids: Dictionary = {}
	for id: String in game.active_level.get("sources"):
		actor_ids[id] = str(game.active_level.get("sources")[id].get_instance_id())
	var exact_protocol_scripts: bool = true
	for id: String in _cost_sources:
		exact_protocol_scripts = exact_protocol_scripts and protocols[id].get_script() == NativeProtocol
	if not _expect(exact_protocol_scripts, "all8 actual bound Protocols retain the exact shared native Script before measurement"): _finish(); return
	_start_observation = _window_start_observation()
	_connect_window_events()
	_running_frame = frame_before
	_running_watch = true
	var started: int = Time.get_ticks_usec()
	# Real scheduled physics/process callbacks; no manual actor/controller tick.
	await physics_frame
	await process_frame
	var wall_us: int = Time.get_ticks_usec() - started
	_running_watch = false
	_expect(not _running_overflow, "passive ordered event witness stays within its original bounded receipt")
	var actual_ids: Dictionary = {}
	for id: String in game.active_level.get("sources"):
		actual_ids[id] = str(game.active_level.get("sources")[id].get_instance_id())
	_trace("spore_fusion_interval", {"wall_us": wall_us, "physics_frames": Engine.get_physics_frames() - frame_before, "process_frames": Engine.get_process_frames() - process_before, "player_elapsed_s": game.player.get_world_action_clock() - clock_before, "scheduler_elapsed_s": scheduler.get_clock() - scheduler_before, "actor_identities_unchanged": actor_ids == actual_ids, "hp_before": hp_before, "scope": "Uninstrumented whole-window elapsed time; activation/setup/paused witnesses excluded; one native await interval, no sustained FPS or causal gain claim."})
	if not _expect(Engine.get_physics_frames() - frame_before == 8 and Engine.get_process_frames() - process_before == 1 and is_equal_approx(game.player.get_world_action_clock() - clock_before, 8.0 / 60.0) and is_equal_approx(scheduler.get_clock() - scheduler_before, 8.0 / 60.0) and actor_ids == actual_ids and game.player.hp == hp_before and not paused, "real uninstrumented interval advances eight native physics frames with exact actor/health custody"): _finish(); return
	game.request_pause()
	await _settle()
	# Preserve actual diagnostic/input/optics observations BEFORE snapshot
	# writers can reset diagnostic fields; all witness work is outside timing.
	var native: String = _cost_native(protocols)
	var packets: String = _cost_packets()
	_expect(paused and not packets.is_empty() and not native.is_empty(), "actual public Pause retains nonempty complete19actor/Player/Scheduler and focused native observation after measurement")
	var native_file: Dictionary = _persist_exact_witness("focused-native.exact.json", native)
	var packet_file: Dictionary = _persist_exact_witness("complete19-packets.exact.json", packets)
	_expect(not native_file.is_empty() and not packet_file.is_empty(), "both actual paused Exact strings are retained as byte-exact files outside the measured interval")
	_trace("spore_fusion_paused_witness", {"packet_bytes": packets.to_utf8_buffer().size(), "packet_sha256": packets.sha256_text(), "native_bytes": native.to_utf8_buffer().size(), "native_sha256": native.sha256_text(), "native_file": native_file, "packet_file": packet_file, "campaign_error": game.campaign_error, "scope": "Actual complete19actor/Player/Scheduler and focused-native Exact bytes retained and decoded outside timing; Optical Pause refusal is reported, no fitting/Save permission/recovery claim."})
	_stage_outcome = "one_uninstrumented_native_boundary_interval"
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
		native_sources[id] = {"node_id": str(source.get_instance_id()), "script_id": str(source.get_script().get_instance_id()), "pose": source.global_transform, "velocity": source.velocity, "grounded": source.is_on_floor(), "collision_id": str(collision.get_instance_id()), "shape_id": str(collision.shape.get_instance_id()), "collision_pose": collision.global_transform, "disabled": collision.disabled, "hp": source.get("hp"), "max_hp": source.get("max_hp"), "dead": source.get("dead"), "dormant": source.get("dormant"), "body": NativeProtocol._body_properties(source, collision)}
	var focused: Dictionary = {"paused": paused, "shell_id": str(game.get_instance_id()), "shell_script": str(game.get_script().get_instance_id()), "level_id": str(game.active_level.get_instance_id()), "level_script": str(game.active_level.get_script().get_instance_id()), "hero_id": str(game.player.get_instance_id()), "hero_script": str(game.player.get_script().get_instance_id()), "controller_id": str(controller.get_instance_id()), "controller_script": str(controller.get_script().get_instance_id()), "controller_clock_bits": _clock_bits(controller.get_clock()), "player_clock_bits": _clock_bits(game.player.get_world_action_clock()), "input": game.get_input_observation_state(), "aim": game.get_aim_anchor_normalized(), "camera_pose": game.camera.global_transform, "camera_size": game.camera.size, "camera_projection": game.camera.projection, "camera_focus": game.get("_camera_focus"), "hud_safe": game.hud.combat_safe_rect(), "attempts": game.attempts.state(), "menu": game.menu.page_name(), "beat_index": game.active_level.get("beat_index"), "room_stage": game.active_level.get("room_stage"), "completed_beats": game.active_level.get("completed_beats"), "sources": native_sources}
	_stage_observation_error = ""
	var budget: Array[int] = [0]
	var observed: Variant = _stage_observation_value(focused, budget)
	if not _stage_observation_error.is_empty():
		_cost_native_error = "Focused native witness: " + _stage_observation_error
		return ""
	var wire: String = Exact.stringify({"references": references, "diagnostics": diagnostics, "focused_native": observed, "start_observation": _stage_observation_value(_start_observation, [0]), "running_events": _stage_observation_value(_running_events, [0]), "scope": "Fresh native references plus exact mechanical packets, passive ordered events, start camera/input/resource observations and retained full focused native data; fresh process identities differ. Not arbitrary Script internals or optical parent save."})
	if wire.is_empty(): _cost_native_error = "Focused native witness exceeds original Exact admission"
	return wire


func _finish() -> void:
	if _finished: return
	_finished = true
	_trace("cost_cleanup_before", {"measurement_label": _cost_label, "outcome": _stage_outcome})
	_close_shell()
	paused = false
	await create_timer(0.2, true).timeout
	_cleanup_saves()
	_expect(FileAccess.get_sha256(STAGE_ORIGINAL) == STAGE_ORIGINAL_SHA and FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_text, "cost probe preserves original CP2 and canonical registry bytes")
	_trace("cost_cleanup_after", {"measurement_label": _cost_label, "outcome": _stage_outcome})
	print("Spore fusion measurement: %d checks, %d failures; label=%s; outcome=%s; uninstrumented native interval only, no productionFPS/gain/full-route claim" % [checks, failures, _cost_label, _stage_outcome])
	quit(0 if failures == 0 else 1)


func _persist_exact_witness(name: String, wire: String) -> Dictionary:
	if wire.is_empty(): return {}
	var decoded: Dictionary = Exact.parse(wire)
	if not decoded.get("accepted", false) or Exact.stringify(decoded.value) != wire:
		_expect(false, "paused Exact witness decodes and re-encodes without type/bit drift: " + name)
		return {}
	var directory: String = "res://.cinder/spore-fusion-measure-prep/jobs/" + _cost_label + "/observed"
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		_expect(false, "private observed directory can be created")
		return {}
	var path: String = directory + "/" + name
	if FileAccess.file_exists(path):
		_expect(false, "actual witness output does not replace existing evidence: " + name)
		return {}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_expect(false, "actual paused witness file opens successfully: " + name)
		return {}
	file.store_string(wire)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if not _expect(write_error == OK and FileAccess.get_file_as_string(path) == wire and FileAccess.get_sha256(path) == wire.sha256_text(), "actual paused witness file retains the literal Exact bytes/hash: " + name):
		return {}
	return {"path": path, "bytes": wire.to_utf8_buffer().size(), "sha256": wire.sha256_text(), "exact_decoded_and_reencoded": true}


func _window_start_observation() -> Dictionary:
	# Direct observations only, outside timing; no provider acquisition/snapshot.
	var actors: Dictionary = {}
	for id: String in game.active_level.get("sources"):
		var actor: CharacterBody3D = game.active_level.get("sources")[id]
		actors[id] = {"pose": actor.global_transform, "velocity": actor.velocity, "hp": actor.get("hp"), "dead": actor.get("dead"), "dormant": actor.get("dormant")}
	return {"input": game.get_input_observation_state(), "aim": game.get_aim_anchor_normalized(), "hp": game.player.hp, "shells": game.player.shells, "player_clock_bits": _clock_bits(game.player.get_world_action_clock()), "scheduler_clock_bits": _clock_bits((game.active_level.get("scheduler") as CinderThreatScheduler).get_clock()), "camera_pose": game.camera.global_transform, "camera_focus": game.get("_camera_focus"), "camera_size": game.camera.size, "camera_projection": game.camera.projection, "actors": actors}

func _event(source_id: String, kind: String, arguments: Array) -> void:
	if not _running_watch: return
	if _running_events.size() >= 256:
		_running_overflow = true
		return
	# Fixed paired observation overhead; no timer, profiler or provider call.
	_running_events.append({"source": source_id, "kind": kind, "physics_offset": Engine.get_physics_frames() - _running_frame, "arguments": arguments.duplicate(true)})

func _connect_window_events() -> void:
	for id: String in game.active_level.get("sources"):
		var source: Node = game.active_level.get("sources")[id]
		source.connect("state_changed", func(value: Dictionary) -> void: _event(id, "state_changed", [value]))
		source.connect("defeated", func(value: String) -> void: _event(id, "defeated", [value]))
		source.connect("hit_resolved", func(hero_id: String, cycle: int, value: Dictionary) -> void: _event(id, "hit_resolved", [hero_id, cycle, value]))
	game.player.fired.connect(func(kind: String) -> void: _event("hero", "fired", [kind]))
	game.player.died.connect(func() -> void: _event("hero", "died", []))
	game.player.action_resolved.connect(func(kind: String, hits: int, damage: float) -> void: _event("hero", "action_resolved", [kind, hits, damage]))
	game.player.equipment_changed.connect(func(id: String) -> void: _event("hero", "equipment_changed", [id]))
	game.player.world_action_executed.connect(func(value: Dictionary) -> void: _event("hero", "world_action_executed", [value]))
	var scheduler: CinderThreatScheduler = game.active_level.get("scheduler")
	scheduler.reservation_invalidated.connect(func(id: String, reason: String) -> void: _event("scheduler", "reservation_invalidated", [id, reason]))
	for id: String in game.active_level.get("_fields"):
		var field: Node = game.active_level.get("_fields")[id]
		field.connect("activated", func(value: Dictionary) -> void: _event(id, "field.activated", [value]))
		field.connect("state_changed", func(value: Dictionary) -> void: _event(id, "field.state_changed", [value]))
	for id: String in game.active_level.get("_consumers"):
		var consumer: Node = game.active_level.get("_consumers")[id]
		consumer.connect("reaction_started", func(source_id: String, episode: String) -> void: _event(id, "reaction_started", [source_id, episode]))
		consumer.connect("placement_rejected", func(source_id: String, reason: String) -> void: _event(id, "placement_rejected", [source_id, reason]))
