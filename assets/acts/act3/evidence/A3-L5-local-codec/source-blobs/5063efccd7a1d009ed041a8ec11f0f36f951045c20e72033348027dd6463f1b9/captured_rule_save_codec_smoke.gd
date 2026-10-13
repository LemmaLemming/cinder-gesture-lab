extends "res://tests/acts/act3/crystalman_two_slot_rule_room_smoke.gd"
## TEST ONLY draft: public real routes + exact whole Player/local transport.
## No campaign Store/Attempts Continue/Retry, full parent, art or acceptance claim.
const LocalCodec = preload("res://tests/acts/act3/fixtures/captured_rule_room_codec.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const ONE_ROOM: String = "res://tests/acts/act3/fixtures/captured_rule_codec_one.tscn"
const TWO_ROOM: String = "res://tests/acts/act3/fixtures/captured_rule_codec_two.tscn"
const HELPER_SHA: String = "6c3cfc228985e64f5b34f9c25b2b744b92ad6f8f031b68c3a428450a7b9c3bbc"
const MAX2_HELPER_SHA: String = "35c35fa0a6f60f45eb890c6f044917cd981efea7c64683d74f95db802f792675"
const BASE_SHA: String = "915252a26089e7b4ecec92a8046d42555a702af7c1566551b80e67ce39e87a6b"
var _capacity: int = 1
var _samples: Array[String] = []
var _quiet_events: int = 0
var _candidate_game: Node
var _candidate_viewport: SubViewport
var _focus_resumes: int = 0
var _pending_capture_due: bool = false
var _pending_capture_seen: bool = false
var _recording_pending_sampled: bool = false
const FOCUS_RESUME_LIMIT: int = 4

func _room_path() -> String:
	return ONE_ROOM if _capacity == 1 else TWO_ROOM

func _expected_capture_slots() -> int:
	return _capacity

func _run() -> void:
	_clock_join_only = true
	_capacity = 2 if "--captured-codec-two-slot" in OS.get_cmdline_user_args() else 1
	if not _expect(OS.get_cmdline_user_args().is_empty() or OS.get_cmdline_user_args() == PackedStringArray(["--captured-codec-two-slot"]), "only one exact capacity selector is supported"):
		quit(1); return
	if not _expect(FileAccess.get_sha256("res://tests/acts/act3/crystalman_rule_room_smoke.gd") == HELPER_SHA and FileAccess.get_sha256("res://tests/acts/act3/crystalman_two_slot_rule_room_smoke.gd") == MAX2_HELPER_SHA and FileAccess.get_sha256("res://scripts/acts/act3/crystalman_rule_room.gd") == BASE_SHA, "reviewed helper/current V2 remain frozen"):
		quit(1); return
	root.size = Vector2i(340, 736)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if await _open(): await _codec_real_route()
	await _close_candidate()
	await _close()
	# Rejected has no admitted owner/history: construct it through actual bad input.
	if _failures == 0 and await _open(): await _codec_real_rejection()
	await _close_candidate()
	await _close()
	print("Captured rule local codec draft: capacity%d, %d checks; failures%d; post-actor ticks%d; native samples%s. No whole-parent campaign transport/Retry/art/phase acceptance." % [_capacity, _checks, _failures, _ticks, str(_samples)])
	quit(0 if _failures == 0 else 1)

func _open() -> bool:
	paused = false
	_game = MainScene.instantiate()
	_game.set("level_scene_path", _room_path())
	root.add_child(_game)
	_hero = _game.get("player") as CinderPlayer
	_room = _game.get("active_level") as CinderLevel
	_scheduler = _room.get("threat_scheduler") as CinderThreatScheduler if _room != null else null
	_gate = _room.get("capture_gate") as CinderReplayCaptureGate if _room != null else null
	if not _expect(_hero != null and _room != null and _scheduler != null and _gate != null and _room.scene_file_path == _room_path() and _room.level_id == "A3-L5" and String(_room.get("last_configuration_error")).is_empty(), "actual MainScene enters test-only CinderLevel recipient with shared Player/camera/HUD"): return false
	_hero.shells = 0 # Explicit initial TEST supply, identical to inherited mechanics.
	_hp = _hero.hp
	_kit = _hero.equipment.snapshot()
	_events.clear(); _retirements.clear()
	_pending_capture_due = false; _pending_capture_seen = false; _recording_pending_sampled = false
	_expected_slots.clear(); _opportunities.clear(); _completed_prefix.clear()
	_reentrant_rejected = false; _blast_seen = false
	_hero.fired.connect(_on_fired)
	_gate.sequence_retired.connect(_on_retired)
	_barrier = Barrier.new(); root.add_child(_barrier)
	var region: Dictionary = _room.call("floor_regions")[0]
	_floor_collision = region.collision
	_floor_transform = _floor_collision.global_transform
	_floor_size = (_floor_collision.shape as BoxShape3D).size
	if not await _wait_phase("recording", 180): return false
	return _expect(_gate.state().capture.armed and _gate.state().capture.max_slots == _capacity and _gate.state().capture.allocated == 0, "one fresh sole Gate legitimately arms exact chosen capacity")

func _codec_real_route() -> bool:
	if not await _sample("recording-empty"): return false
	if _capacity == 2:
		# Exact current max2 helper owns the real records, ordered expected slots,
		# completion observer and trace. Only snapshot hooks are added here.
		if not await _record_combo(Vector3.BACK, 1): return false
		if not await _sample("recording-one-of-two-sealed"): return false
		if not await _record_combo(Vector3.FORWARD, 2): return false
	else:
		if not await _record_valid(Vector3.BACK): return false
		if not await _tick(): return false
		if not _expect(_room.call("state").phase == "recording" and _gate.state().capture.pending > 0, "actual first primary retains live pending combo before natural sealing"): return false
		if not await _sample("recording-pending"): return false
	if not await _wait_phase("warning", 240): return false
	if _capacity == 2 and not _check_two_join(1): return false
	if not await _sample("warning"): return false
	var playback: CinderReplayPlayback = _room.get("playback") as CinderReplayPlayback
	playback.event_dispatched.connect(_on_replay_event)
	if not await _pause_resume("warning"): return false
	if not await _wait_locked(): return false
	if not await _sample("lock"): return false
	var proof: Dictionary = _room.call("state").proof
	if not _expect(proof.accepted and proof.at_lock and proof.slot_count == _capacity and not proof.uses_blast and not proof.uses_invulnerability, "actual fresh public lock proves whole ordinary response for selected capacity"): return false
	if not await _follow_proof(proof, true): return false
	if not await _sample("exposed"): return false
	if not await _sever_with_real_primary(): return false
	if not await _sample("spent-complete"): return false
	return _expect(_events.size() == _capacity and _retirements.size() == 1 and _room.call("state").joins == 1 and _room.call("state").tether_hits == 1, "actual finite suffix and one original FIFO retirement/tether remain once-only")

func _wait_one_sealed() -> bool:
	for _i: int in range(180):
		var capture: Dictionary = _gate.state().capture
		if capture.sealed == 1 and capture.pending == 0: return true
		if not await _tick(): return false
	return _expect(false, "real first two-slot combo naturally seals")

func _pause_resume(label: String) -> bool:
	if not await super._pause_resume(label): return false
	if label == "active": return await _sample("active")
	return true

func _drain_original_replay_recovery(until_s: float, history: int, count: int) -> bool:
	# Release was immediate. This paused sample is the genuine remaining original
	# recovery, with no synthetic complete status, deadline or empty lease.
	if not await _sample("spent-recovery"): return false
	return await super._drain_original_replay_recovery(until_s, history, count)

func _sever_with_real_primary() -> bool:
	if _capacity == 2: return await _sever_two_with_actual_recovery()
	return await super._sever_with_real_primary()

func _wait_sealed_one() -> bool:
	if not _recording_pending_sampled:
		if not await _tick(): return false
		if not _expect(_room.call("state").phase == "recording" and _gate.state().capture.pending > 0, "actual max2 first primary retains original pending combo"): return false
		if not await _sample("recording-pending"): return false
		_recording_pending_sampled = true
	return await super._wait_sealed_one()


func _codec_real_rejection() -> bool:
	# Capacity2 leaves its first complete combo intact until a bad second input;
	# neither case fabricates an origin, history, consumed sequence or source.
	if _capacity == 2:
		if not await _record_valid(Vector3.BACK) or not await _wait_one_sealed(): return false
	if not _expect(_swipe(Vector3.FORWARD).is_empty(), "bad recording still begins with actual completed dash"): return false
	if not await _wait_stable(): return false
	if not _expect(_swipe(Vector3.RIGHT).is_empty(), "bad recording begins actual second in-flight dash"): return false
	if not await _tick(): return false
	if not _expect(_tap(Vector3.RIGHT).is_empty(), "bad recording publishes real mismatched mid-dash primary"): return false
	if not await _wait_phase("rejected", 180): return false
	if not _expect(_room.call("state").joins == 0 and _gate.retirement_state().is_empty() and _scheduler.reservations().is_empty(), "visible rejected recording has no admitted replay/retirement/history repair"): return false
	if not await _sample("rejected-before-admission"): return false
	if not await _wait_phase("recording", 180): return false
	return _expect(_room.call("state").generation == 2 and _room.call("state").rejections == 1 and _gate.state().capture.allocated == 0 and _gate.retirement_state().is_empty(), "real original rejection deadline rearms a new empty generation without replaying saved input")

func _sample(label: String) -> bool:
	_game.call("open_bench") # Actual public paused UI, after post-actor deferred barrier.
	await process_frame
	var player: Dictionary = _hero.snapshot_state()
	var level: Dictionary = _room.snapshot_state()
	if not _expect(paused and not player.is_empty() and not level.is_empty(), label + ": actual complete Player + CinderLevel writer succeeds", _room.last_snapshot_error): return false
	var aggregate: Dictionary = {"player": player, "level": level}
	var wire: String = Exact.stringify(aggregate)
	var path: String = "user://test-captured-rule-%d-%d-%s.exact.json" % [OS.get_process_id(), _capacity, label]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not _expect(file != null and not wire.is_empty(), label + ": bounded whole exact-json disk transport opens"): return false
	file.store_string(wire); file.close()
	var parsed: Dictionary = Exact.parse(FileAccess.get_file_as_string(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if not _expect(parsed.get("accepted", false) and _wire_exact(parsed.get("value"), aggregate), label + ": exact integer/scalar/vector/history bits survive actual disk transport"): return false
	var before: Dictionary = _donor_receipt()
	for _i: int in range(3): await process_frame
	if not _expect(_wire_exact(before, _donor_receipt()), label + ": public Pause preserves whole clocks/floor/history/native view/input"): return false
	if not await _fresh_candidate(parsed.value, label): return false
	if not _negative_packets(aggregate, before, label): return false
	if not _negative_actual_marker(before, label): return false
	if not _expect(_wire_exact(before, _donor_receipt()), label + ": candidate and negative controls leave installed donor exact"): return false
	_samples.append(label)
	var input_before: PackedByteArray = var_to_bytes(_game.call("get_input_observation_state"))
	var sequence: int = _latest_sequence(); var clock: float = _hero.get_world_action_clock()
	var resume: Button = _find_resume(_game.get("hud") as Node)
	if not _expect(resume != null and resume.is_visible_in_tree(), label + ": real Resume is visible"): return false
	_touch(resume.get_global_rect().get_center(), 93)
	return _expect(not paused and _latest_sequence() == sequence and _hero.get_world_action_clock() == clock and input_before == var_to_bytes(_game.call("get_input_observation_state")), label + ": Resume is consumed with no gameplay gesture/tick")

func _fresh_candidate(saved: Dictionary, label: String) -> bool:
	# Native test construction only: independent MainScene supplies the existing
	# World3D, shared Player/fx/camera/HUD. Its ordinary gen0 entry is immediately
	# exited while paused before fresh CinderLevel restore construction.
	_candidate_viewport = SubViewport.new()
	_candidate_viewport.size = Vector2i(root.get_visible_rect().size)
	_candidate_viewport.own_world_3d = true
	_candidate_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(_candidate_viewport)
	_candidate_game = MainScene.instantiate(); _candidate_game.set("level_scene_path", _room_path())
	_candidate_viewport.add_child(_candidate_game)
	# MainScene reset_lab synchronously resumes its fresh preview. Restore the
	# TEST freeze before yielding; no donor/native physics tick has occurred.
	paused = true
	var room: CinderLevel = _candidate_game.get("active_level") as CinderLevel
	var hero: CinderPlayer = _candidate_game.get("player") as CinderPlayer
	var camera: Camera3D = _candidate_game.get("camera") as Camera3D
	var hud: GameHUD = _candidate_game.get("hud") as GameHUD
	room.exit_level()
	var prepared: bool = room.enter_restore_candidate(hero, _candidate_game.get("fx") as PixelEffects, _candidate_game, saved.level, saved.player)
	if not _expect(prepared and room.is_restore_candidate() and hero.get_world_3d() != _hero.get_world_3d() and hero.get_instance_id() != _hero.get_instance_id(), label + ": genuine fresh paused recipient has independent native bindings", room.last_snapshot_error): return false
	_watch_quiet(room, hero)
	var quiet: int = _quiet_events
	if not _expect(room.snapshot_error_with_player(saved.level, saved.player).is_empty(), label + ": full saved-player/mechanical native candidate prevalidation is pure", room.last_snapshot_error): return false
	if not _expect(hero.restore_state(saved.player) and room.restore_state(saved.level), label + ": actual Player→Gate→whole Scheduler→projected Playback quiet commit succeeds", room.last_snapshot_error): return false
	# Explicit saved native view context, as the outer Shell does; no fit plan or
	# actor/source pose edit. Input anchor belongs to Shell, not this local codec.
	camera.global_transform = (_game.get("camera") as Camera3D).global_transform
	hud.update_status(hero.hp, hero.max_hp, hero.shells, hero.max_shells, 0, room.objective_text)
	await process_frame
	var optical: String = room.restore_candidate_presentation_error(camera, hud)
	var recaptured: Dictionary = LocalCodec.new().capture(room, hero.snapshot_state(), false)
	if not _expect(optical.is_empty() and _wire_exact(hero.snapshot_state(), saved.player) and _wire_exact(recaptured, saved.level.local) and _quiet_events == quiet and room.snapshot_state().is_empty(), label + ": exact native unit/current camera/HUD gate is quiet and candidate remains nonplayable", optical): return false
	var floor: CollisionShape3D = room.call("floor_regions")[0].collision
	if not _expect(floor != _floor_collision and floor.get_instance_id() != _floor_collision.get_instance_id() and floor.global_transform == _floor_transform and (floor.shape as BoxShape3D).size == _floor_size, label + ": fresh original floor resources retain geometry without aliasing donor"): return false
	if String(saved.level.local.owned.phase) in ["exposed", "spent"]:
		var current_marker: MeshInstance3D = room.get_node("LowFixedExternalTether/SharedOrdinaryAttackCue/RequiredInteractionMarker") as MeshInstance3D
		var material: StandardMaterial3D = current_marker.material_override as StandardMaterial3D
		var original_color: Color = material.albedo_color
		material.albedo_color = Color(original_color.r, original_color.g, original_color.b, 0.0) # TEST ONLY actual native cue fault.
		var alpha_error: String = room.restore_candidate_presentation_error(camera, hud)
		material.albedo_color = original_color
		if not _expect(not alpha_error.is_empty() and material.albedo_color == original_color and _wire_exact(hero.snapshot_state(), saved.player) and _quiet_events == quiet, label + ": actual transparent required candidate marker refuses quietly; exact original material restored", alpha_error): return false
		var original_mask: int = camera.cull_mask
		camera.cull_mask = original_mask & ~current_marker.layers
		var mask_error: String = room.restore_candidate_presentation_error(camera, hud)
		camera.cull_mask = original_mask
		if not _expect(not mask_error.is_empty() and camera.cull_mask == original_mask and _quiet_events == quiet, label + ": actual candidate mask excludes required visible marker and refuses", mask_error): return false
	var original: Transform3D = camera.global_transform
	camera.global_position += Vector3(100, 0, 0) # TEST ONLY actual optical rejection.
	var bad_view: String = room.restore_candidate_presentation_error(camera, hud)
	camera.global_transform = original
	if not _expect(not bad_view.is_empty() and _wire_exact(hero.snapshot_state(), saved.player) and _quiet_events == quiet, label + ": clipped actual candidate rejects without retiming/admission/damage/presentation callbacks"): return false
	await _close_candidate()
	return true

func _negative_actual_marker(before: Dictionary, label: String) -> bool:
	if String(_room.call("state").phase) not in ["exposed", "spent"]: return true
	var marker: MeshInstance3D = _room.get_node("LowFixedExternalTether/SharedOrdinaryAttackCue/RequiredInteractionMarker") as MeshInstance3D
	var material: StandardMaterial3D = marker.material_override as StandardMaterial3D
	var original_color: Color = material.albedo_color
	var native_before: PackedByteArray = _native_marker_receipt(marker)
	material.albedo_color = Color(original_color.r, original_color.g, original_color.b, 0.0) # TEST ONLY real native fault.
	var refused: Dictionary = _room.snapshot_state()
	var reason: String = _room.last_snapshot_error
	material.albedo_color = original_color # Exact donor restoration before any GUI Resume/tick.
	var restored: Dictionary = _room.snapshot_state()
	return _expect(refused.is_empty() and not reason.is_empty() and not restored.is_empty() and _native_marker_receipt(marker) == native_before and _wire_exact(before, _donor_receipt()), label + ": alpha0 actual required marker capture refuses and exact donor/material is restored", reason)

func _native_marker_receipt(marker: MeshInstance3D) -> PackedByteArray:
	var material: StandardMaterial3D = marker.material_override as StandardMaterial3D
	return var_to_bytes([marker.global_transform, marker.visible, marker.layers, marker.cast_shadow, marker.transparency, marker.visibility_range_begin, marker.visibility_range_end, material.albedo_color, material.shading_mode, material.transparency, material.cull_mode, material.texture_filter, material.no_depth_test, material.grow_enabled, material.distance_fade_mode])

func _negative_packets(saved: Dictionary, before: Dictionary, label: String) -> bool:
	var bad: Dictionary = saved.duplicate(true)
	bad.level.local.owned.phase = "severed"
	if not _reject_packet(bad, before, label + ": transient phase"): return false
	bad = saved.duplicate(true); bad.level.local.gate.prepared_sequence = {"untrusted": true}
	if not _reject_packet(bad, before, label + ": preparing Gate"): return false
	bad = saved.duplicate(true); bad.level.local.gate.actor_sha256 = "0".repeat(64)
	if not _reject_packet(bad, before, label + ": foreign actor hash"): return false
	bad = saved.duplicate(true); bad.level.local.configuration.capacity = 3
	if not _reject_packet(bad, before, label + ": extra capacity"): return false
	bad = saved.duplicate(true); bad.level.local.world.collision_fingerprint = {}
	if not _reject_packet(bad, before, label + ": foreign floor/collision"): return false
	if _capacity == 2:
		bad = saved.duplicate(true); bad.level.local.owned.presentation.marker_mode = "sequence" if saved.level.local.owned.presentation.marker_mode == "capture" else "capture"
		if not _reject_packet(bad, before, label + ": forged passive-marker mode"): return false
	if not saved.level.local.playback.is_empty():
		bad = saved.duplicate(true); bad.level.local.playback.status = "cancelled"
		if not _reject_packet(bad, before, label + ": canceled retained owner"): return false
		bad = saved.duplicate(true); bad.level.local.playback.exchange.adapter = 1; bad.level.local.owned.held_exchange.adapter = 1
		if not _reject_packet(bad, before, label + ": malformed nested adapter"): return false
		bad = saved.duplicate(true); bad.level.local.owned.projection.events = 1
		if not _reject_packet(bad, before, label + ": malformed projection events"): return false
		bad = saved.duplicate(true); bad.level.local.owned.projection.floor_signature = [1]
		if not _reject_packet(bad, before, label + ": malformed projection floor membership"): return false
		bad = saved.duplicate(true); bad.level.local.playback.exchange.source_position[0] += 1.0; bad.level.local.owned.held_exchange.source_position[0] += 1.0
		if not _reject_packet(bad, before, label + ": moved source pose"): return false
		bad = saved.duplicate(true); bad.level.local.owned.join_receipt.prepared_actor_sha256 = "wrong"
		if not _reject_packet(bad, before, label + ": false retirement hash"): return false
		bad = saved.duplicate(true); bad.level.local.owned.exposure_until_s += 1.0
		if not _reject_packet(bad, before, label + ": extended original opening"): return false
		bad = saved.duplicate(true); bad.level.local.playback.clock_s += 0.01
		if not _reject_packet(bad, before, label + ": divergent native replay clock"): return false
	return true

func _reject_packet(bad: Dictionary, before: Dictionary, label: String) -> bool:
	var error: String = _room.snapshot_error_with_player(bad.level, bad.player)
	return _expect(not error.is_empty() and _wire_exact(before, _donor_receipt()), label + " rejects atomically with a reason", error)

func _donor_receipt() -> Dictionary:
	var bindings: Dictionary = _room.call("scheduler_bindings")
	var schedule: Dictionary = _scheduler.snapshot_state(bindings)
	var owner: CinderReplayPlayback = _room.get("playback") as CinderReplayPlayback
	return {"player": _hero.snapshot_state(), "gate": _gate.snapshot_state(), "scheduler": schedule, "playback": owner.snapshot_state(schedule, bindings) if is_instance_valid(owner) else {}, "owned": _room.call("captured_codec_owned_state"), "input": var_to_bytes(_game.call("get_input_observation_state")).hex_encode(), "anchor": [float((_game.call("get_aim_anchor_normalized") as Vector2).x), float((_game.call("get_aim_anchor_normalized") as Vector2).y)], "camera": var_to_bytes((_game.get("camera") as Camera3D).global_transform).hex_encode(), "floor": var_to_bytes([_floor_collision.global_transform, _floor_size]).hex_encode(), "events": _events.size(), "retirements": _retirements.size()}

func _watch_quiet(room: CinderLevel, hero: CinderPlayer) -> void:
	var nodes: Array = [hero, room, room.get("capture_gate"), room.get("threat_scheduler"), room.get("playback"), room.get_node("LowFixedExternalTether/SharedOrdinaryAttackCue")]
	var owner: CinderReplayPlayback = room.get("playback") as CinderReplayPlayback
	if is_instance_valid(owner): nodes.append_array(owner.get_cues())
	for node: Node in nodes:
		if not is_instance_valid(node): continue
		for signal_info: Dictionary in node.get_signal_list():
			if signal_info.name not in ["fired", "died", "action_resolved", "equipment_changed", "world_action_executed", "sequence_retired", "gate_failed", "reservation_invalidated", "state_changed", "event_dispatched", "playback_failed", "recording_rejected", "recording_joined", "tether_severed", "completion_requested", "contact_exit_requested", "checkpoint_requested"]: continue
			var callback: Callable = Callable(self, "_quiet" + str(signal_info.args.size()))
			if callback.is_valid(): node.connect(signal_info.name, callback)

func _quiet0() -> void: _quiet_events += 1
func _quiet1(_a: Variant) -> void: _quiet_events += 1
func _quiet2(_a: Variant, _b: Variant) -> void: _quiet_events += 1
func _quiet3(_a: Variant, _b: Variant, _c: Variant) -> void: _quiet_events += 1

func _close_candidate() -> void:
	var refs: Array[WeakRef] = []
	if is_instance_valid(_candidate_game):
		var room: CinderLevel = _candidate_game.get("active_level") as CinderLevel
		for node: Node in [_candidate_game, room, _candidate_game.get("player"), room.get("capture_gate"), room.get("threat_scheduler"), room.get("playback")]:
			if is_instance_valid(node): refs.append(weakref(node))
		room.exit_level()
	if is_instance_valid(_candidate_viewport):
		refs.append(weakref(_candidate_viewport)); _candidate_viewport.queue_free()
	_candidate_game = null; _candidate_viewport = null
	for _i: int in range(3): await process_frame
	if not refs.is_empty(): _expect(refs.all(func(ref: WeakRef) -> bool: return ref.get_ref() == null), "normal paused candidate disposal frees actual Hero, Gate listener, owner and Scheduler")

func _on_replay_event(event: Dictionary, receipt: Dictionary) -> void:
	super._on_replay_event(event, receipt)
	if not _pending_capture_seen:
		_pending_capture_seen = true
		_pending_capture_due = true
		# Genuine interruption at a public once-only event observer. Do not take
		# a snapshot recursively: native delivery unwinds with its real suffix.
		_game.call("open_bench")

func _recover_paused_native_barrier() -> bool:
	if paused and _pending_capture_due:
		_pending_capture_due = false
		var owner: CinderReplayPlayback = _room.get("playback") as CinderReplayPlayback
		var bindings: Dictionary = _room.call("scheduler_bindings")
		var scheduler: Dictionary = _scheduler.snapshot_state(bindings)
		# The public observer paused at Playback110 before Gate2000. After native
		# unwind synchronize through the sole Gate's normal public capture path.
		# This changes only Gate's observation of the real actor clock/history;
		# it never rebases a packet or advances Player/Scheduler/input/geometry.
		var actor_before: Dictionary = _hero.snapshot_state()
		var actor_history: PackedByteArray = var_to_bytes(_hero.get_world_action_records())
		var events_before: PackedByteArray = var_to_bytes([_events, _opportunities])
		var input_before: PackedByteArray = var_to_bytes(_game.call("get_input_observation_state"))
		var retirement_before: Dictionary = _gate.retirement_state()
		var camera_before: Transform3D = (_game.get("camera") as Camera3D).global_transform
		if not _expect(_gate.synchronize(), "deferred sole Gate synchronizes its real actor observation after callback unwind", _gate.last_error): return false
		var gate_now: Dictionary = _gate.snapshot_state()
		if not _expect(not gate_now.is_empty() and gate_now.clock_s == actor_before.world_actions.clock_s and _wire_exact(actor_before, _hero.snapshot_state()) and _wire_exact(scheduler, _scheduler.snapshot_state(bindings)) and actor_history == var_to_bytes(_hero.get_world_action_records()) and events_before == var_to_bytes([_events, _opportunities]) and input_before == var_to_bytes(_game.call("get_input_observation_state")) and _wire_exact(retirement_before, _gate.retirement_state()) and camera_before == (_game.get("camera") as Camera3D).global_transform and _floor_collision.global_transform == _floor_transform and (_floor_collision.shape as BoxShape3D).size == _floor_size, "sole Gate clock joins actual Player without actor/Scheduler/history/events/input/retirement/view/floor repair", _gate.last_snapshot_error): return false
		var packet: Dictionary = owner.snapshot_state(scheduler, bindings)
		if not _expect(not packet.is_empty() and packet.has("pending_delivery") and not packet.pending_delivery.is_empty(), "genuine public event interruption retains native pending suffix after callback unwind", owner.last_snapshot_error): return false
		return await _sample("active-pending-native-suffix")
	var resume: Button = _find_resume(_game.get("hud") as Node) if is_instance_valid(_game) else null
	if not paused or root.has_focus() or not is_instance_valid(resume) or not resume.is_visible_in_tree() or _focus_resumes >= FOCUS_RESUME_LIMIT: return false
	var before: Dictionary = _donor_receipt()
	_focus_resumes += 1
	print("ACTUAL_FOCUS_PAUSE_RESUME codec " + str(_focus_resumes))
	# Public GUI path; bounded recovery never forces a physics tick or focus flag.
	if is_instance_valid(_room.get("playback")):
		if not await super._pause_resume("application focus pause"): return false
	else:
		var clock: float = _hero.get_world_action_clock(); var sequence: int = _latest_sequence()
		_touch(resume.get_global_rect().get_center(), 94)
		if not _expect(not paused and _hero.get_world_action_clock() == clock and _latest_sequence() == sequence, "actual early-recording GUI focus Resume adds no input/tick"): return false
	paused = true # TEST read-only freeze for receipt comparison, no simulation.
	var after: Dictionary = _donor_receipt()
	paused = false
	return _expect(_wire_exact(before, after), "focus Resume preserves exact original whole unit/resources/floor/view")

# Original current35c35 strict terminal/cursor/prefix/negative/GUI checks,
# changing only the intentionally implemented local-writer predicate.
func _check_completed_two_slot_leaves(original: Dictionary) -> bool:
	# Real public Pause after original native recovery has already completed.
	# No whole-level codec or fake overlay is used to obtain these leaf states.
	_game.call("open_bench")
	await process_frame
	var playback: CinderReplayPlayback = _room.get("playback") as CinderReplayPlayback
	var bindings: Dictionary = _room.call("scheduler_bindings")
	var schedule: Dictionary = _scheduler.snapshot_state(bindings)
	var terminal: Dictionary = playback.snapshot_state(schedule, bindings)
	var aggregate: Dictionary = {"player": _hero.snapshot_state(), "gate": _gate.snapshot_state(), "scheduler": schedule, "playback": terminal}
	var cues: Array[Node3D] = playback.get_cues()
	var quiet_cues: bool = cues.size() == 2
	if quiet_cues:
		for index: int in range(2):
			var observed: Dictionary = cues[index].call("state")
			quiet_cues = quiet_cues and observed.phase == "clear" and not observed.source_visible and not observed.footprint_visible and not observed.active_fill_visible and String(cues[index].call("projection_error", original.projection.events[index])).is_empty()
	var camera_error: String = _game.call("camera_framing_error", _room.call("camera_framing_points"))
	print("READONLY TWO-SLOT STRICT COMPLETED LEAF JOIN " + var_to_str({"aggregate": aggregate, "original_proof": original.proof, "original_lease": original.lease, "original_timeline": original.sequence.timeline, "quiet_cues": quiet_cues, "camera_error": camera_error}))
	if not _expect(paused and not aggregate.player.is_empty() and not aggregate.gate.is_empty() and not schedule.is_empty() and not terminal.is_empty() and terminal.status == "complete" and terminal.schema_version == 3 and terminal.cursor.armed and terminal.cursor.phase == "complete" and terminal.cursor.next_event_index == 2 and terminal.cursor.executed_events.size() == 2 and terminal.cursor.last_advanced_clock_s == schedule.clock_s and terminal.clock_s == schedule.clock_s and float(schedule.clock_s) > float(original.lease.recovery_until_s) and schedule.reservations.is_empty() and not schedule.has("replay_cancellations") and schedule.profile.id == original.lease.profile_id and terminal.reason.is_empty() and terminal.cancelled_at_s == null and terminal.cancellation.is_empty() and _wire_exact(terminal.sequence, original.sequence) and _wire_exact(terminal.projection, original.projection) and _wire_exact(terminal.opportunities, _opportunities) and _gate.retirement_state().slot_ids == [1, 2] and quiet_cues and not playback.get_apparition().visible and not playback.get_apparition_root().visible and playback.global_position == original.lease.source_position and not _hero.dead and _hero.hp == _hp and _hero.equipment.snapshot() == _kit and camera_error.is_empty() and not _room.call("snapshot_state").is_empty() and _room.last_snapshot_error.is_empty(), "actual completed schema3 leaves retain original profile/full prefix/current native quiet cues with the changed whole local codec writer", playback.last_snapshot_error): return false
	# Correct the observed expectation with the PUBLIC original cursor codec,
	# whose strict prefix validation uses the same declared deadline precision
	# as actual advance. Immutable schedule/clock/type/identity stay exact.
	var cursor_reader := CinderReplayCursor.new()
	var prefix_error: String = cursor_reader.snapshot_error(terminal.cursor, original.sequence, String(original.sequence.source_epoch), int(original.generation), float(schedule.clock_s))
	var too_early: Dictionary = terminal.cursor.duplicate(true)
	too_early.executed_events[0].dispatch_clock_s = float(too_early.executed_events[0].scheduled_at_s) - 2.0 * CinderReplayCursor.TIME_EPSILON_S
	var altered_schedule: Dictionary = terminal.cursor.duplicate(true)
	altered_schedule.executed_events[0].scheduled_at_s = float(altered_schedule.executed_events[0].scheduled_at_s) + 0.0001
	if not _expect(prefix_error.is_empty() and not cursor_reader.snapshot_error(too_early, original.sequence, String(original.sequence.source_epoch), int(original.generation), float(schedule.clock_s)).is_empty() and not cursor_reader.snapshot_error(altered_schedule, original.sequence, String(original.sequence.source_epoch), int(original.generation), float(schedule.clock_s)).is_empty(), "original public cursor accepts native exact prefix and rejects dispatch before declared precision or altered scheduled bits", prefix_error): return false
	_completed_prefix = terminal.cursor.executed_events.duplicate(true)
	var input_before: PackedByteArray = var_to_bytes(_game.call("get_input_observation_state"))
	var camera: Camera3D = _game.get("camera") as Camera3D
	var camera_before: PackedByteArray = var_to_bytes(camera.global_transform)
	var history: int = _latest_sequence()
	var actor_clock: float = _hero.get_world_action_clock()
	for _i: int in range(4): await process_frame
	schedule = _scheduler.snapshot_state(bindings)
	var after: Dictionary = {"player": _hero.snapshot_state(), "gate": _gate.snapshot_state(), "scheduler": schedule, "playback": playback.snapshot_state(schedule, bindings)}
	if not _expect(_wire_exact(aggregate, after) and _events.size() == 2 and _latest_sequence() == history and input_before == var_to_bytes(_game.call("get_input_observation_state")) and camera_before == var_to_bytes(camera.global_transform), "actual public paused completed aggregate remains exact without redelivery, input or clock advance"): return false
	var button: Button = _find_resume(_game.get("hud") as Node)
	if not _expect(button != null and button.is_visible_in_tree(), "actual completed Resume GUI control is visible"): return false
	_touch(button.get_global_rect().get_center(), 91)
	return _expect(not paused and _latest_sequence() == history and _hero.get_world_action_clock() == actor_clock and _events.size() == 2 and input_before == var_to_bytes(_game.call("get_input_observation_state")), "actual completed GUI Resume is consumed without action, recapture or tick")
