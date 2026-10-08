extends "res://tests/acts/act1/a1_l3_actor_pair.gd"
## PRIVATE DRAFT: API2/opt-in scene exist; parent movement/framing guards are
## being revised. This fixture has not been parsed or run.
## Actual neutral/Standard spawn -> three genuine ordinary-primary defeats.
## No teleport, source motion/phase/HP writes, fabricated lease, spore aggregate,
## whole-level completion/save, eight-body crowd or legal-profile/kit claim.
## Inherits real touch/drag/release, camera, native pair and cleanup helpers.
## Unlike the isolated role proof, a genuine ordinary swing may hit several
## living sources; every credited hit must match actual source HP loss.
##
## Scene: a1_l3_crowd_greybox.tscn, same four retained sources,
## room0/spawn(0,.1,15), parent enable_swarm_approach=true.
## Required actor state(): approach_enabled/approach_driving literal booleans,
## velocity/facing native Vector3; native capture has root approach_driving.
## Capture remains actor-only, with parent campaign aggregate explicitly denied.

const CrowdPath: String = "res://scenes/acts/act1/a1_l3_crowd_greybox.tscn"
const CrowdIds: Array[String] = ["umbrella-1", "umbrella-2", "umbrella-3"]
const CrowdEpsilon: float = 0.00001
const MotionTolerance: float = 0.001
var crowd_previous: Dictionary = {}
var crowd_motion_samples: Array[Dictionary] = []
var crowd_admissions: Array[Dictionary] = []
var crowd_primary_receipts: Array[Dictionary] = []
var approach_displacement: Dictionary = {}
var maximum_speed: float = 0.0
var maximum_turn_rate: float = 0.0
var approach_frames: int = 0
var full_cycle_followed: bool = false


func _run() -> void:
	portrait = "--portrait" in OS.get_cmdline_user_args()
	root.size = PortraitSize
	if portrait:
		if not _require(DisplayServer.get_name() != "headless", "crowd portrait requires the actual graphical renderer"):
			await _finish(); return
		capture_dir = "res://.cinder/captures/l3-crowd-%d" % Time.get_ticks_usec()
		if not _require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir)) == OK, "crowd portrait directory is writable"):
			await _finish(); return
		print("SCRIPTED L3 CROWD PORTRAIT native_focus_observed=", DisplayServer.window_is_focused(), "; one initial public resume; normal FOCUS_OUT unchanged")
	if not await _open_world(CrowdPath, "three-real-crowd", Vector3(0, 0.1, 15)):
		await _finish(); return
	if not _require(scheduler.encounter_profile().get("id") == "standard" and hero.equipment.snapshot() == {"jacket": "CLOTH-J0", "pants": "CLOTH-P0", "shoes": "CLOTH-S0", "weapon": "WEAPON-01"}, "crowd proof uses the actual Standard profile and existing neutral starter types"):
		await _finish(); return
	_watch_pair_events()
	for id: String in ActorIds:
		var state: Dictionary = sources[id].call("state")
		if not _require(state.get("approach_enabled") == (id in CrowdIds) and typeof(state.get("approach_driving")) == TYPE_BOOL and state.get("velocity") is Vector3 and state.get("facing") is Vector3, id + " exposes the confirmed opt-in public approach view"):
			await _finish(); return
		approach_displacement[id] = 0.0
	process_frame.connect(_sample_crowd)
	if not await _wait(func() -> bool: return _all_three_approached() and _driven_source() != "", "all three C31s genuinely approach while Hero stays at authored spawn", 12.0):
		_crowd_diagnostic("all-three initial approach timed out"); await _finish(); return
	if not _framing("actual slow approach") or not await _capture("driven-approach") or not await _pause_driven_pair():
		await _finish(); return
	if not _require(hero.global_position.x == 0.0 and hero.global_position.z == 15.0 and hero.get_world_action_records().is_empty(), "all-three motion observation and real paired GUI pause leave Hero at authored spawn before any gameplay action"):
		await _finish(); return
	if not await _swipe(Vector3.FORWARD, "genuine full grove approach after all-three driven observation"):
		await _finish(); return
	var rounds: int = 0
	while not _all_three_defeated() and rounds < 6 and not aborted:
		if not await _wait(func() -> bool: return _fresh_warning() != "" or (full_cycle_followed and _reachable_source() != ""), "next genuine reachable or fresh native crowd opportunity", 12.0):
			_crowd_diagnostic("crowd opportunity timed out"); await _finish(); return
		var id: String = _fresh_warning()
		if not id.is_empty():
			if not await _fight_cycle(id, not full_cycle_followed):
				_crowd_diagnostic("native crowd response failed"); await _finish(); return
			full_cycle_followed = true
		else:
			id = _reachable_source()
			if id.is_empty() or not await _primary(sources[id], id + " genuine nearby crowd opening"):
				await _finish(); return
		rounds += 1
	if not await _wait(func() -> bool: return _all_three_defeated() and bool(level.get("greybox_clear")), "parent observes all three actual ordinary-primary defeats", 2.0):
		_crowd_diagnostic("crowd clear did not settle"); await _finish(); return
	if not _require(full_cycle_followed and approach_frames > 1 and not crowd_admissions.is_empty() and not crowd_primary_receipts.is_empty(), "crowd clear includes actual approach, accepted native full cycle and recorded ordinary primaries"):
		await _finish(); return
	for id: String in CrowdIds:
		var actor: CharacterBody3D = sources[id]
		if not _require(float(approach_displacement[id]) > CrowdEpsilon and actor.get("dead") and actor.get("hp") == 0.0 and not actor.is_in_group("enemies") and not actor.call("state").approach_driving, id + " physically approached and then genuinely defeated without lingering drive/target membership"):
			await _finish(); return
	if not _require(not level.is_completed() and bool(sources["lone-guard"].call("state").dormant), "three-source component clear neither completes L3 nor activates the isolated future guard"):
		await _finish(); return
	if not await _capture("three-real-defeats") or not await _close_world(false):
		await _finish(); return
	await _finish()


func _sample_crowd() -> void:
	if finishing or aborted or paused or not is_instance_valid(scheduler): return
	var now: float = scheduler.get_clock()
	for id: String in CrowdIds:
		var actor := sources.get(id) as CharacterBody3D
		if not is_instance_valid(actor): continue
		var state: Dictionary = actor.call("state")
		if not _require_unexpected(state.get("velocity") is Vector3 and state.get("facing") is Vector3 and typeof(state.get("approach_driving")) == TYPE_BOOL, "crowd observer requires the actual public native approach view"):
			return
		var previous: Dictionary = crowd_previous.get(id, {})
		var current: Dictionary = {"clock_s": now, "position": actor.global_position, "velocity": actor.velocity, "facing": state.facing, "phase": state.phase, "lease": state.reservation_id, "cycle": state.cycle, "hurt_left_s": state.hurt_left_s, "dead": state.dead, "driving": state.approach_driving}
		if not previous.is_empty() and now > float(previous.clock_s) and not state.dead and not previous.dead:
			var elapsed: float = now - float(previous.clock_s)
			var step: float = _planar_distance(actor.global_position, previous.position)
			if state.reservation_id.is_empty() and previous.lease.is_empty() and int(state.cycle) == int(previous.cycle) and float(state.hurt_left_s) == 0.0 and float(previous.hurt_left_s) == 0.0:
				var facing: Vector3 = state.facing
				var old_facing: Vector3 = previous.facing
				var angle: float = acos(clampf(facing.normalized().dot(old_facing.normalized()), -1.0, 1.0))
				if not _require_unexpected(angle <= 3.0 * elapsed + MotionTolerance, id + " idle facing turns gradually within the authored rate"):
					return
				maximum_turn_rate = maxf(maximum_turn_rate, angle / elapsed)
				if state.approach_driving or previous.driving:
					var speed: float = Vector2(actor.velocity.x, actor.velocity.z).length()
					if not _require_unexpected(speed <= 1.2 + MotionTolerance and step <= 1.2 * elapsed + MotionTolerance, id + " approach uses actual slow native motion without a position jump"):
						return
					maximum_speed = maxf(maximum_speed, speed)
					approach_frames += 1
					approach_displacement[id] = float(approach_displacement[id]) + step
			if not state.reservation_id.is_empty() and state.reservation_id == previous.lease:
				if not _require_unexpected(not state.approach_driving, id + " native lease suspends approach-driving ownership"):
					return
				if state.phase == previous.phase and state.phase in ["warning", "lock", "recovery"]:
					if not _require_unexpected(step <= CrowdEpsilon and actor.velocity == Vector3.ZERO, id + " native " + state.phase + " retains its planted source without approach movement"):
						return
		crowd_previous[id] = current
		if crowd_motion_samples.size() < 512: crowd_motion_samples.append(_portable({"source_id": id, "sample": current}))
	# Actual retained capsule footprints, not decorative sprite extents. Attack
	# motion is included: a genuine crossing would be a concrete crowd defect.
	for a: int in range(CrowdIds.size()):
		for b: int in range(a + 1, CrowdIds.size()):
			var first: CharacterBody3D = sources[CrowdIds[a]]
			var second: CharacterBody3D = sources[CrowdIds[b]]
			if first.get("dead") or second.get("dead"): continue
			var first_shape := first.get_node("BodyCollision") as CollisionShape3D
			var second_shape := second.get_node("BodyCollision") as CollisionShape3D
			var first_capsule := first_shape.shape as CapsuleShape3D
			var second_capsule := second_shape.shape as CapsuleShape3D
			if not _require_unexpected(first_capsule != null and second_capsule != null and _planar_distance(first_shape.global_position, second_shape.global_position) + CrowdEpsilon >= first_capsule.radius + second_capsule.radius, "living crowd retains nonoverlapping actual capsule footprints"):
				return


func _notice_admission(id: String, answer: Dictionary) -> void:
	super._notice_admission(id, answer)
	if aborted or not admissions.has(String(answer.get("reservation_id", ""))): return
	var actor: CharacterBody3D = sources[id]
	var state: Dictionary = actor.call("state")
	var direction: Vector3 = (answer.reservation.geometry["to"] as Vector3) - (answer.reservation.geometry["from"] as Vector3)
	direction.y = 0.0
	var facing: Vector3 = state.get("facing", Vector3.ZERO)
	if not _require_unexpected(actor.velocity == Vector3.ZERO and state.get("velocity") == Vector3.ZERO and state.get("approach_driving") == false and facing.is_finite() and facing.dot(direction.normalized()) > 0.9999, id + " actual native admission starts stopped/aligned with no approach-driving velocity"):
		return
	crowd_admissions.append(_portable({"source_id": id, "clock_s": scheduler.get_clock(), "state": state, "answer": answer}))


func _driven_source() -> String:
	for id: String in CrowdIds:
		var state: Dictionary = sources[id].call("state")
		var velocity: Vector3 = state.get("velocity", Vector3.ZERO)
		if state.get("approach_driving") == true and state.reservation_id.is_empty() and Vector2(velocity.x, velocity.z).length() > 0.0: return id
	return ""


func _all_three_approached() -> bool:
	for id: String in CrowdIds:
		if float(approach_displacement.get(id, 0.0)) <= CrowdEpsilon: return false
	return true


func _fresh_warning() -> String:
	var selected: String = ""
	var nearest: float = INF
	for id: String in CrowdIds:
		if not _running_warning(id): continue
		var state: Dictionary = sources[id].call("state")
		var answer: Dictionary = admissions.get(String(state.reservation_id), {})
		var path: Array = answer.get("proof", {}).get("path", [])
		if path.is_empty() or not path[0].get("from") is Vector3 or _planar_distance(path[0]["from"], hero.global_position) > PositionTolerance: continue
		var escape_start: float = -1.0
		for segment: Dictionary in path:
			if segment.get("kind") == "escape_dash": escape_start = float(segment.start_s)
		if escape_start < scheduler.get_clock(): continue
		var distance: float = _planar_distance(sources[id].global_position, hero.global_position)
		if distance < nearest: nearest = distance; selected = id
	return selected


func _reachable_source() -> String:
	var selected: String = ""
	var nearest: float = float(hero.equipment.resolved_stats().primary_range) - 0.08
	for id: String in CrowdIds:
		var state: Dictionary = sources[id].call("state")
		var distance: float = _planar_distance(sources[id].global_position, hero.global_position)
		if not state.dead and not state.dormant and state.phase != "active" and distance <= nearest:
			nearest = distance; selected = id
	return selected


func _all_three_defeated() -> bool:
	for id: String in CrowdIds:
		if not sources[id].get("dead") or sources[id].get("hp") != 0.0: return false
	return true


func _pause_driven_pair() -> bool:
	if not await _pause_pair("actual driven crowd"): return false
	var pair: Dictionary = _pair_capture()
	if not _require(not pair.is_empty() and _pair_error(pair).is_empty(), "actual driven pause captures the complete Player/four-actor/native Scheduler unit"):
		return false
	var id: String = _driven_source()
	if not _require(not id.is_empty() and pair.actors[id].approach_driving and _planar_distance(Codec.read_vector3(pair.actors[id].motion.velocity), Vector3.ZERO) > 0.0, "paused driven envelope records genuine nonzero approach motion"):
		return false
	var wire: String = Exact.stringify(pair)
	var count: int = pair_events
	var bad: Dictionary = pair.duplicate(true)
	bad.actors[id]["approach_driving"] = 1
	if not _reject_crowd_pair(bad, wire, count, "wrong-type approach-driving transport"): return false
	bad = pair.duplicate(true)
	bad.actors[id]["approach_driving"] = false
	if not _reject_crowd_pair(bad, wire, count, "actual driven ownership cannot be silently removed by a false boolean"): return false
	bad = pair.duplicate(true)
	bad.actors[id]["motion"]["velocity"][1] = 0.125
	if not _reject_crowd_pair(bad, wire, count, "driven C31 cannot forge nonzero vertical motion"): return false
	bad = pair.duplicate(true)
	bad.actors[id]["motion"]["grounded"] = false
	if not _reject_crowd_pair(bad, wire, count, "driven C31 cannot forge an ungrounded state"): return false
	bad = pair.duplicate(true)
	# An intentionally invalid copied identity; no reservation is acquired or
	# synthesized in the actual Scheduler or in its unchanged saved envelope.
	bad.actors[id]["reservation_id"] = "forged-owned-lease"
	if not _reject_crowd_pair(bad, wire, count, "driven C31 cannot claim ordinary native lease ownership"): return false
	bad = pair.duplicate(true)
	bad.actors["lone-guard"]["approach_driving"] = true
	if not _reject_crowd_pair(bad, wire, count, "dormant stationary guard cannot forge approach-driving ownership"): return false
	var decoded: Dictionary = Exact.parse(wire)
	if not _require(not wire.is_empty() and decoded.get("accepted", false) and _pair_restore(decoded.value) and Exact.stringify(_pair_capture()) == wire and pair_events == count, "genuine driven motion quietly reconstructs in prevalidated Player/physical actors/Scheduler/exchange order"):
		return false
	if not _require(hero.hp == float(pair.player.resources.hp) and hero.shells == int(pair.player.resources.shells) and level.snapshot_state().is_empty(), "driven component restore neither heals/refills nor grants unsupported full L3 save"):
		return false
	var deadline: int = Time.get_ticks_msec() + 120
	while Time.get_ticks_msec() < deadline and not finishing: await process_frame
	if not _require(Exact.stringify(_pair_capture()) == wire and pair_events == count, "real pause freezes driven motion, native time, resources and signals"):
		return false
	if not _framing("paused driven bodies") or not await _capture("driven-paired-pause"): return false
	return await _gui_resume_pair()


func _reject_crowd_pair(bad: Dictionary, wire: String, count: int, label: String) -> bool:
	return _require(not _pair_error(bad).is_empty() and not _pair_restore(bad) and Exact.stringify(_pair_capture()) == wire and pair_events == count, label + " rejects through pure whole-unit prevalidation before mutation")


func _pause_component(id: String, lease: String) -> bool:
	# The first accepted response also tests the converse using a real retained
	# lease. No lease, clock, motion or phase is fabricated to make a valid case.
	if not await _pause_pair(id + " actual native lease"): return false
	var pair: Dictionary = _pair_capture()
	if not _require(not pair.is_empty() and _pair_error(pair).is_empty() and pair.actors[id].reservation_id == lease and not pair.actors[id].approach_driving, id + " paused admission owns its actual native lease without pursuit drive"):
		return false
	var bad: Dictionary = pair.duplicate(true)
	bad.actors[id]["approach_driving"] = true
	if not _reject_crowd_pair(bad, Exact.stringify(pair), pair_events, id + " genuinely leased source cannot forge pursuit ownership"): return false
	if not _framing(id + " leased pause") or not await _capture(id + "-leased-paired-pause"): return false
	return await _gui_resume_pair()


func _primary(actor: CharacterBody3D, label: String) -> bool:
	if not await _ready_input(label + " primary readiness"): return false
	while Time.get_ticks_msec() - last_primary_ms <= 300:
		if not _guard_input(): return false
		await process_frame
	var offset: Vector3 = actor.global_position - hero.global_position
	offset.y = 0.0
	var direction: Vector3 = offset.normalized()
	var anchor: Vector2 = game.call("get_aim_anchor")
	var tap: Vector2 = anchor + _screen_delta(direction) * 160.0
	if not _require(actor.is_in_group("enemies") and offset.length() <= float(hero.equipment.resolved_stats().primary_range) and _input_safe(tap) and (game.call("aim_direction", tap) as Vector3).dot(direction) > 0.9999, label + " has actual ordinary reach and literal-release aiming"):
		return false
	var before_hp: Dictionary = {}
	for id: String in CrowdIds: before_hp[id] = float(sources[id].get("hp"))
	var sequence: int = _last_sequence()
	var press := InputEventScreenTouch.new()
	press.index = 7; press.pressed = true; press.position = tap
	Input.parse_input_event(press)
	await process_frame
	if not _guard_input(): return false
	var release := InputEventScreenTouch.new()
	release.index = 7; release.position = tap
	hero.shells = 0 # Release-only test ammo setup; passive reload remains enabled.
	Input.parse_input_event(release)
	await process_frame
	if not _guard_input(): return false
	last_primary_ms = Time.get_ticks_msec()
	primaries += 1
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	var observed: Dictionary = game.call("get_input_observation_state")
	if not _require(records.size() == 1 and records[0].kind == "primary" and records[0].direction.dot(direction) > 0.9999 and observed.last_observation.kind == "primary_tap" and observed.last_observation.accepted and observed.last_observation.world_action_sequence == records[0].sequence and (game.call("get_aim_anchor") as Vector2).is_equal_approx(anchor), label + " executes one immediate actual primary with zero shells at release and unchanged aim"):
		return false
	var hit_count: int = 0
	var losses: Dictionary = {}
	for id: String in CrowdIds:
		var loss: float = float(before_hp[id]) - float(sources[id].get("hp"))
		if loss > 0.0:
			hit_count += 1
			losses[id] = loss
			if not _require(absf(loss - minf(float(before_hp[id]), float(records[0].damage))) <= CrowdEpsilon, id + " actual HP loss matches the genuine ordinary-primary damage receipt"):
				return false
	if not _require(hit_count > 0 and hit_count == int(records[0].hits) and float(actor.get("hp")) < float(before_hp[String(actor.call("state").source_id)]), label + " credits exactly the genuinely hit living sources, allowing real crowd multi-hits"):
		return false
	crowd_primary_receipts.append({"sequence": records[0].sequence, "shells_at_release": 0, "actual_hp_losses": losses, "record": _portable(records[0])})
	return true


func _crowd_diagnostic(label: String) -> void:
	var actor_errors: Dictionary = {}
	for id: String in sources:
		if is_instance_valid(sources[id]): actor_errors[id] = sources[id].get("last_error")
	print("L3 CROWD DIAGNOSTIC ", label, " clock=", scheduler.get_clock() if is_instance_valid(scheduler) else -1, " hero=", hero.global_position if is_instance_valid(hero) else Vector3.ZERO, " sources=", _source_states(), " actor_last_errors=", actor_errors, " admissions=", _portable(admissions), " encounter_error=", level.get("last_encounter_error") if is_instance_valid(level) else "", " approach_error=", level.get("last_approach_error") if is_instance_valid(level) else "", " camera=", game.call("get_camera_framing_state") if is_instance_valid(game) else {})


func _finish() -> void:
	if finishing: return
	if process_frame.is_connected(_sample_crowd): process_frame.disconnect(_sample_crowd)
	finishing = true
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(game):
		var effects: PixelEffects = game.get("fx") as PixelEffects
		if is_instance_valid(effects): effects.clear()
		game.queue_free()
	paused = false
	await process_frame
	if portrait and not capture_dir.is_empty():
		var file := FileAccess.open(capture_dir.path_join("evidence.json"), FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify({"scope": "actual-input neutral/Standard opt-in three-C31 crowd component; genuine production spawn/ordinary primaries and actor-only driven pair; no spores/fulllevel/campaign save/eight-body/kit-profile/human/performance claim", "checks": checks, "failures": failures, "actual_swipes": swipes, "actual_primaries": primaries, "normal_focus_out_preserved": true, "approach_frames": approach_frames, "approach_displacement": approach_displacement, "maximum_speed": maximum_speed, "maximum_turn_rate": maximum_turn_rate, "motion_samples": crowd_motion_samples, "admission_receipts": crowd_admissions, "primary_receipts": crowd_primary_receipts, "worlds": worlds, "captures": shots}, "\t"))
			file.close()
		else:
			checks += 1; failures += 1
			push_error("crowd portrait evidence file failed to open")
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L3 ACTUAL CROWD COMPONENT: %d checks, %d failures; %d swipes, %d primaries; NO TELEPORTS / NO SPORES / NO FULL-LEVEL CLAIM" % [checks, failures, swipes, primaries])
	quit(1 if failures else 0)
