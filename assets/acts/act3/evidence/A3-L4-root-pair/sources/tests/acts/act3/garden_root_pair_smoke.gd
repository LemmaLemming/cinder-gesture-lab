extends "res://tests/acts/act3/garden_root_rule_room_smoke.gd"
## Focused local paired unit. Inherits the actual Main/gesture/barrier
## fixture helpers, but replaces its run with one genuine paired-state battle.
## No campaign, disk, Shell input/focus or whole-level acceptance claim.

const PairExact = preload("res://scripts/campaign/exact_json.gd")
var _native_deadlines: Dictionary = {}
var _first_recovery: Dictionary = {}


func _run() -> void:
	if not _expect(OS.get_cmdline_user_args().is_empty(), "paired prototype draft has no fabricated profile/loadout selector"):
		await _finish()
		return
	if not await _open():
		await _finish()
		return
	if not await _paired_stage("initial idle", 60.0, 1):
		await _finish()
		return
	var draw: Dictionary = await _admit("draw", Vector3.LEFT)
	if draw.is_empty() or not await _earned_return(draw, "draw"):
		await _finish()
		return
	if not await _paired_stage("earned Draw ordinary-return60", 60.0, 1):
		await _finish()
		return
	_game.call("resume_lab")
	var first_wall_ms: int = Time.get_ticks_msec()
	if not _ordinary_hit(60.0, 40.0, 1):
		await _finish()
		return
	first_wall_ms = Time.get_ticks_msec() # Conservatively after actual input.
	if not await _paired_stage("earned Draw partial40", 40.0, 1):
		await _finish()
		return
	_game.call("resume_lab")
	if not await _second_primary_ready(first_wall_ms, float(_native_deadlines.draw)):
		await _finish()
		return
	_allow_cancelled = true
	if not _ordinary_hit(40.0, 30.0, 2) or not _expect(_all_sources_clear(), "real Draw phase boundary closes every actual lease/cue before capture"):
		await _finish()
		return
	if not await _paired_stage("earned phase boundary30", 30.0, 2):
		await _finish()
		return
	_retired_sources.clear()
	for kind: String in ["draw", "enclose"]:
		_retired_sources[kind] = _source(kind).state()
	_allow_cancelled = false
	var enclose: Dictionary = await _admit("enclose", Vector3.RIGHT)
	if enclose.is_empty() or not await _earned_return(enclose, "enclose"):
		await _finish()
		return
	if not await _paired_stage("earned Enclose recovery30", 30.0, 2):
		await _finish()
		return
	_game.call("resume_lab")
	if not _ordinary_hit(30.0, 10.0, 2):
		await _finish()
		return
	first_wall_ms = Time.get_ticks_msec()
	if not await _paired_stage("earned Enclose partial10", 10.0, 2):
		await _finish()
		return
	_game.call("resume_lab")
	if not await _second_primary_ready(first_wall_ms, float(_native_deadlines.enclose)):
		await _finish()
		return
	_allow_cancelled = true
	if not _ordinary_hit(10.0, 0.0, 3) or not _expect(_all_sources_clear(), "real final ordinary primary closes actual native leases/cues"):
		await _finish()
		return
	if not await _paired_stage("earned settled dead0", 0.0, 3):
		await _finish()
		return
	var body: CollisionShape3D = _tether.get_node_or_null("RootCollision") as CollisionShape3D
	_expect(body != null and body.disabled and not _tether.is_in_group("enemies") and _tether.collision_layer == 0 and _tether.collision_mask == 0 and _hero.hp == _hero_hp and _hero.hp == _hero.max_hp and _all_sources_clear(), "fresh final pair keeps genuine settled spent body, full Hero HP and cleared authority")
	if _failures == 0:
		await _close()
		await _warning_cancel_reentry()
	await _finish()


func _earned_return(answer: Dictionary, kind: String) -> bool:
	var source: CinderLaneMechanism = _source(kind)
	var reservation_id: String = String(answer.get("reservation_id", ""))
	var record: Dictionary = _scheduler.reservation_state(reservation_id)
	var proof: Dictionary = answer.get("proof", {})
	if not _expect(answer.get("accepted", false) and not record.is_empty() and record.get("source_instance_id") == source.get_instance_id() and proof.get("accepted", false) and not proof.get("uses_blast", true) and not proof.get("uses_invulnerability", true), "actual " + kind + " admission supplies the native ordinary proof before any paired capture", str(answer)):
		return false
	# Keep the actual native deadline in the caller's transient test observation;
	# this is never a serialized proof/authority field of the level packet.
	_native_deadlines[kind] = float(record.recovery_until_s)
	var escaped: bool = false
	var returned: bool = false
	for segment: Dictionary in proof.path:
		if segment.kind not in ["escape_dash", "positioning_dash"]:
			continue
		if kind == "draw" and segment.kind == "positioning_dash":
			# Sample the first actual native Recovery transition, rather than
			# assuming a rounded active deadline equals its first physics tick.
			for _i: int in range(360):
				if _source(kind).state().phase == "recovery":
					break
				if not await _tick():
					return false
			var band: MeshInstance3D = _tether.get_node("TetherBand") as MeshInstance3D
			if not _expect(_source(kind).state().phase == "recovery" and _scheduler.get_clock() <= float(record.active_until_s) + 1.0 / float(Engine.physics_ticks_per_second) + 0.000000001 and (band.material_override as StandardMaterial3D).albedo_color == Color("e5dece"), "first actual completed recovery tick publishes the derived white low-tether band after native mechanism physics"):
				return false
			_first_recovery = {"clock_s": _scheduler.get_clock(), "active_until_s": float(record.active_until_s)}
			if not await _paired_stage("first actual Draw recovery tick60", 60.0, 1):
				return false
			_first_recovery.clear()
			_game.call("resume_lab")
			source = _source(kind) # The genuine paired stage replaced the donor.
		if not await _until(float(segment.start_s)):
			return false
		var intended: Vector3 = (segment.to - segment.from).normalized()
		var error: String = _swipe(intended)
		var dash: Dictionary = _hero.get_committed_dash_state()
		if not _expect(error.is_empty() and dash.get("active", false) and dash.distance == _hero.stats.dash_distance and dash.duration_s == _hero.stats.dash_duration and (dash.direction as Vector3).distance_to(intended) < 0.000001, "actual paired fixture " + String(segment.kind) + " starts a full canonical routed dash", error):
			return false
		if not await _complete_dash(segment):
			return false
		if segment.kind == "escape_dash":
			escaped = true
		else:
			returned = true
	if not await _until(float(proof.primary_time_s)):
		return false
	var held: Dictionary = source.state()
	var live: Dictionary = _scheduler.reservation_state(reservation_id)
	return _expect(escaped and returned and held.status == "running" and held.phase == "recovery" and live.get("state") == "recovery" and _hero.global_position.distance_to(proof.attack_position) < 0.02 and _hero.hp == _hero_hp and float(proof.response_complete_s) < float(record.recovery_until_s), "genuine " + kind + " escape/return earns ordinary recovery on firm floor without direct actor/source changes")


func _ordinary_hit(before_hp: float, after_hp: float, after_phase: int) -> bool:
	var actions: Array[Dictionary] = _hero.get_world_action_records()
	var count: int = actions.size()
	var actual_before_hp: float = float(_tether.get("hp"))
	var error: String = _tap(_target_direction())
	actions = _hero.get_world_action_records()
	var actual: Dictionary = _game.call("get_input_observation_state")
	return _expect(error.is_empty() and actual_before_hp == before_hp and _hero.stats.primary_damage == 20.0 and actions.size() == count + 1 and actions.back().kind == "primary" and actions.back().hits == 1 and actions.back().damage == 20.0 and actual.last_observation.kind == "primary_tap" and actual.last_observation.accepted and before_hp - minf(20.0, before_hp - (30.0 if after_phase == 2 and before_hp > 30.0 else 0.0)) == after_hp and float(_tether.get("hp")) == after_hp and int(_tether.get("phase")) == after_phase and _hero.hp == _hero_hp and not _events.has("fired_blast"), "genuine ordinary primary earns exact %.0f→%.0f HP before paired transport" % [before_hp, after_hp], error)


func _pair() -> Dictionary:
	return {"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}


func _pair_error(pair: Dictionary) -> String:
	var error: String = _hero.snapshot_error(pair.hero)
	return _level.snapshot_error_with_player(pair.level, pair.hero) if error.is_empty() else error


func _wire_exact(left: Variant, right: Variant) -> bool:
	var lhs: String = PairExact.stringify(left)
	var rhs: String = PairExact.stringify(right)
	return not lhs.is_empty() and not rhs.is_empty() and lhs == rhs


func _completed_pause() -> bool:
	if not paused and not _expect(_game.call("request_pause_deferred"), "public Game requests the actual completed paired pause"):
		return false
	for _i: int in range(4):
		await process_frame
	return _expect(paused and not _game.call("is_pause_requested"), "actual completed paused barrier settles outside Hero/source/contact callbacks")


func _paired_stage(label: String, hp: float, phase: int) -> bool:
	if not await _completed_pause():
		return false
	if not _first_recovery.is_empty():
		if not _expect(_scheduler.get_clock() == _first_recovery.clock_s and _source("draw").state().phase == "recovery" and _scheduler.get_clock() <= float(_first_recovery.active_until_s) + 1.0 / float(Engine.physics_ticks_per_second) + 0.000000001, "public deferred pause captures that exact first completed recovery tick without an extra simulation step"):
			return false
	var pair: Dictionary = _pair()
	var before: Dictionary = _observation()
	var text: String = PairExact.stringify(pair)
	var decoded: Dictionary = PairExact.parse(text)
	if not _expect(not pair.hero.is_empty() and not pair.level.is_empty() and pair.level.local_snapshot_version == 2 and pair.level.local.tether.hp == hp and int(pair.level.local.tether.phase) == phase and pair.level.local.control.boundaries.size() == phase - 1 and decoded.get("accepted", false) and decoded.get("value") is Dictionary and _wire_exact(pair, decoded.value) and _pair_error(decoded.value).is_empty() and before == _observation(), "actual " + label + " captures and ExactJson-roundtrips the complete earned Hero/local unit without side effects", _hero.last_snapshot_error + "; " + _level.last_snapshot_error):
		return false
	var saved: Dictionary = decoded.value
	if not _negative_pairs(saved, label):
		return false
	for _i: int in range(2):
		await process_frame
	if not _expect(before == _observation() and _wire_exact(_pair(), saved), "native paused " + label + " remains frozen after rejected controls and real render frames"):
		return false
	return await _fresh_replace(saved, label)


func _negative_pairs(pair: Dictionary, label: String) -> bool:
	var before: Dictionary = _observation()
	var bads: Array[Dictionary] = []
	var labels: Array[String] = []
	var bad: Dictionary = pair.duplicate(true)
	bad.level.local.scheduler.clock_s = INF
	bads.append(bad)
	labels.append("nonfinite native clock")
	bad = pair.duplicate(true)
	bad.level.local.tether.clock_s = float(bad.level.local.tether.clock_s) + 0.00000001
	bads.append(bad)
	labels.append("exact target/Scheduler clock join")
	bad = pair.duplicate(true)
	bad.level.local.mechanisms.draw.clock_s = float(bad.level.local.mechanisms.draw.clock_s) + 0.00000001
	bads.append(bad)
	labels.append("exact native mechanism clock join")
	bad = pair.duplicate(true)
	bad.level.local.mechanisms.draw.cycle = int(bad.level.local.mechanisms.draw.cycle) + 1
	bads.append(bad)
	labels.append("current accepted source cycle join")
	bad = pair.duplicate(true)
	bad.level.local.tether.phase = 2 if int(bad.level.local.tether.phase) == 1 else 1
	bads.append(bad)
	labels.append("HP-derived exact phase")
	bad = pair.duplicate(true)
	bad.level.local.tether.collision.enabled = not bad.level.local.tether.collision.enabled
	bads.append(bad)
	labels.append("actual living/dead collision flags")
	bad = pair.duplicate(true)
	bad.level.local.mechanisms.erase("enclose")
	bads.append(bad)
	labels.append("missing native sibling source")
	bad = pair.duplicate(true)
	if bad.level.local.control.boundaries.is_empty():
		bad.level.local.control.boundaries.append({"from_phase": 1, "to_phase": 2, "clock_s": bad.level.local.scheduler.clock_s, "kind": "draw", "cycle": 1, "exchange_id": "threat-1"})
	else:
		bad.level.local.control.boundaries[0].exchange_id = "threat-999999999"
	bads.append(bad)
	labels.append("fabricated earned boundary receipt")
	if not pair.level.local.control.boundaries.is_empty():
		bad = pair.duplicate(true)
		bad.level.local.control.boundaries.pop_back()
		bads.append(bad)
		labels.append("missing genuine phase prefix")
	bad = pair.duplicate(true)
	bad.level.local.control.retry_at_s = float(bad.level.local.control.retry_at_s) + 0.00000001
	bads.append(bad)
	labels.append("exact retry/last-crossing join")
	bad = pair.duplicate(true)
	bad.level.progress.completed = true
	bad.level.progress.completion_id = "forged-garden-clear"
	bads.append(bad)
	labels.append("invented campaign completion")
	bad = pair.duplicate(true)
	bad.level.local.control["held"] = true
	bads.append(bad)
	labels.append("undeclared local control")
	bad = pair.duplicate(true)
	if int(bad.level.local.mechanisms.draw.cycle) > 0:
		bad.level.local.control.cycle_records.erase("draw")
	else:
		bad.level.local.control.cycle_records.draw = {"cycle": 1, "exchange_id": "threat-1", "tether_phase": 1}
	bads.append(bad)
	labels.append("missing/invented current-cycle association")
	for kind: String in ["draw", "enclose"]:
		var packet: Dictionary = pair.level.local.mechanisms[kind]
		if int(packet.cycle) == 0 or packet.status == "running":
			continue
		bad = pair.duplicate(true)
		var over_serial: String = "threat-%d" % (int(pair.level.local.scheduler.serial) + 1)
		bad.level.local.mechanisms[kind].exchange.id = over_serial
		bad.level.local.control.cycle_records[kind].exchange_id = over_serial
		bads.append(bad)
		labels.append("inactive " + kind + " two-field exchange exceeds actual native serial")
		if int(pair.level.local.control.cycle_records[kind].tether_phase) == 1:
			bad = pair.duplicate(true)
			bad.level.local.control.cycle_records[kind].tether_phase = 2
			bads.append(bad)
			labels.append("closed " + kind + " forged phase1→2 cycle/boundary association")
	for index: int in range(bads.size()):
		var input: Dictionary = bads[index].duplicate(true)
		if not _expect(not _pair_error(bads[index]).is_empty() and not _level.restore_state(bads[index].level) and input == bads[index] and before == _observation() and _pair_error(pair).is_empty() and _wire_exact(_pair(), pair), "pure/live " + label + " rejection is atomic and genuine unit stays accepted: " + labels[index]):
			return false
	return true


func _target_presentation() -> Dictionary:
	var body: CollisionShape3D = _tether.get_node("RootCollision") as CollisionShape3D
	var root_view: MeshInstance3D = _tether.get_node("RootBody") as MeshInstance3D
	var band: MeshInstance3D = _tether.get_node("TetherBand") as MeshInstance3D
	return {"body_disabled": body.disabled, "layer": _tether.collision_layer, "mask": _tether.collision_mask, "enemy": _tether.is_in_group("enemies"), "pose": _tether.global_transform, "root_color": (root_view.material_override as StandardMaterial3D).albedo_color, "band_color": (band.material_override as StandardMaterial3D).albedo_color}


func _fresh_replace(saved: Dictionary, label: String) -> bool:
	var donor_refs: Array[WeakRef] = []
	_weakrefs(_hero, donor_refs)
	_weakrefs(_level, donor_refs)
	var cues: Dictionary = {}
	for kind: String in ["draw", "enclose"]:
		cues[kind] = _source(kind).get_cue().state()
	var target_presentation: Dictionary = _target_presentation()
	var input: Dictionary = saved.duplicate(true)
	var original_event_count: int = _events.size()
	if not _expect(_game.call("load_level_scene", ROOM), "public Main fresh scene replacement constructs actual recipient for " + label):
		return false
	_game.call("open_bench") # Pause the construction stack before native ticks.
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	_level.set("auto_attack", false)
	_tether = _level.get("tether") as StaticBody3D
	_mechanisms = _level.get("mechanisms") as Dictionary
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	for _i: int in range(5):
		await process_frame # Actual donor queue disposal; paused recipient clock0.
	var released: bool = true
	for retained: WeakRef in donor_refs:
		released = released and retained.get_ref() == null
	if not _expect(released and paused and _scheduler.get_clock() == 0.0 and _source("draw").state().cycle == 0 and _source("enclose").state().cycle == 0 and float(_tether.get("hp")) == 60.0 and not bool(_level.get("auto_attack")), "real donor Hero/level/target/source descendants release before zero-tick fresh " + label + " prevalidation"):
		return false
	print("PAIR DONOR TEARDOWN: ", label, " events_before=", original_event_count, " events_after=", _events.size())
	# Teardown events are disclosed above; only the following fresh live signals
	# count against quiet reconstruction. Executed Hero history stays in saved.
	_events.clear()
	for kind: String in ["draw", "enclose"]:
		var mechanism: CinderLaneMechanism = _source(kind)
		mechanism.hit_resolved.connect(func(_id: String, _cycle: int, _result: Dictionary) -> void: _events.append("hit"))
		mechanism.state_changed.connect(func(current: Dictionary) -> void:
			_phases[kind + ":" + String(current.phase)] = true
			_events.append("phase_" + kind + "_" + String(current.phase)))
		mechanism.get_cue().state_changed.connect(func(_current: Dictionary) -> void: _events.append("cue_" + kind))
	_scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _events.append("cancel"))
	_hero.world_action_executed.connect(func(_record: Dictionary) -> void: _events.append("world_action"))
	_hero.fired.connect(func(kind: String) -> void: _events.append("fired_" + kind))
	_tether.connect("state_changed", func(_current: Dictionary) -> void: _events.append("target_state"))
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _events.append("completion"))
	_level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _boundary: String) -> void: _events.append("checkpoint"))
	_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _events.append("exit"))
	var fresh_before: Dictionary = _observation()
	var fresh_input: Dictionary = _game.call("get_input_observation_state")
	var fresh_events: Array[String] = _events.duplicate()
	if not _expect(_pair_error(saved).is_empty() and _wire_exact(input, saved) and fresh_before == _observation(), "whole staged saved Hero/local validation is pure on actual fresh " + label + " bindings", _level.last_snapshot_error):
		return false
	# No await, action, lease request, callback or cancellation between commits.
	if not _expect(_hero.restore_state(saved.hero) and _level.restore_state(saved.level), "public ordered Hero→level quietly commits complete " + label, _hero.last_snapshot_error + "; " + _level.last_snapshot_error):
		return false
	var cues_match: bool = true
	for kind: String in ["draw", "enclose"]:
		cues_match = cues_match and cues[kind] == _source(kind).get_cue().state()
	if not _expect(_wire_exact(_pair(), saved) and _target_presentation() == target_presentation and cues_match and _events == fresh_events and _game.call("get_input_observation_state") == fresh_input and _hero.hp == _hero_hp and _hero.equipment.snapshot() == _kit and _level.call("runtime_error") == "", "fresh exact " + label + " recapture retains clocks/resources/HP/phase/control/native cues/palette and emits no quiet gameplay/input events"):
		return false
	var stable: Dictionary = _observation()
	for _i: int in range(2):
		await process_frame
	return _expect(stable == _observation() and _wire_exact(_pair(), saved), "fresh reconstructed " + label + " stays frozen without donor deferred work or retiming")


func _warning_cancel_reentry() -> void:
	if not await _open():
		return
	var observed: Dictionary = {}
	var draw: CinderLaneMechanism = _source("draw")
	draw.state_changed.connect(func(current: Dictionary) -> void:
		if current.phase == "warning" and observed.is_empty():
			observed["entered"] = true
			# Disclosed TEST ONLY real public cancellation from the actual warning
			# observer, followed synchronously by a sibling admission attempt.
			observed["cancelled"] = draw.cancel("test_warning_observer_cancel")
			observed["nested"] = _level.call("start_attack", "enclose", Vector3.RIGHT))
	_game.call("resume_lab")
	var outer: Dictionary = {}
	for _i: int in range(180):
		if bool(_hero.get_threat_response_state().stable):
			outer = _level.call("start_attack", "draw", Vector3.LEFT)
			if not observed.is_empty():
				break
		if not await _tick():
			return
	_allow_cancelled = true
	var nested: Dictionary = observed.get("nested", {})
	_expect(observed.get("entered", false) and observed.get("cancelled", false) and not nested.get("accepted", true) and String(nested.get("reason", "")).contains("cannot reenter") and draw.state().status == "cancelled" and draw.state().cycle == 1 and _source("enclose").state().cycle == 0 and _source("enclose").state().status == "idle" and _all_sources_clear() and float(_tether.get("hp")) == 60.0 and int(_tether.get("phase")) == 1 and _hero.get_world_action_records().is_empty() and _hero.hp == _hero_hp and _level.call("runtime_error") == "", "actual warning cancellation cannot reenter parent control to allocate a sibling native cycle", "outer=" + str(outer) + "; nested=" + str(nested))


func _finish() -> void:
	await _close()
	await create_timer(0.15, true, false, true).timeout
	print("Garden paired rule: %d checks; failures: %d. Actual Hero/local version2 only; no campaign/disk/Shell input or full-level/playthrough credit." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
