extends "res://tests/acts/act2/a2_l5_sentry_encounter_smoke.gd"
## TEST ONLY strict late B05 component transport over the clean native setup.
## Inherited construction, ordinary controls and Foot proof runner are unchanged.
## Standard/Heavy only: actual first Ray threshold, spent-source death,
## natural Foot completion, real pending/delivered phase notification and first
## genuine phase2 paired admission. No second-pool defeat or whole-level route.
## Public native APIs only. No HP/phase/clock/pose/proof/receipt/history seeds.
## Phase acknowledgement is explicitly TEST ONLY host behavior, not a protected
## Shell/Attempts checkpoint. Root owns promotion/import/dev.py execution.
const PhaseExact: Script = preload("res://scripts/campaign/exact_json.gd")
var _phase_worlds: Array[Dictionary] = []
var _phase_finished: bool = false

func _run() -> void:
	create_timer(70.0, true).timeout.connect(func() -> void:
		if not _phase_finished:
			_expect(false, "bounded focused late-parent transport watchdog")
			_phase_finish())
	print("TEST ONLY B05 late transport: real native Standard/Heavy threshold and isolated Foot; representative component pending/dead/phase2/pair tuples, no earned whole-level checkpoint or playthrough")
	await _phase_transport()
	_phase_finish()

func _phase_create() -> Dictionary:
	var fixture: Dictionary = super._create("standard")
	var bindings: Dictionary = fixture.parent.call("bindings")
	fixture["bindings"] = bindings
	fixture["disposed"] = false
	var events: Array[String] = []
	fixture["events"] = events
	fixture.configured = fixture.configured and bool(fixture.parent.call("bind_transport_scope", bindings))
	_phase_worlds.append(fixture)
	if not fixture.configured: return fixture
	for event: String in ["world_action_executed", "action_resolved", "fired", "died", "equipment_changed"]: _phase_watch(fixture.hero, event, events, "hero." + event)
	_phase_watch(fixture.scheduler, "reservation_invalidated", events, "scheduler.invalidated")
	for event: String in ["phase_checkpoint_eligible", "sentry_cleared", "hit_resolved", "runtime_failed"]: _phase_watch(fixture.parent, event, events, "parent." + event)
	var ray: Node3D = fixture.parent.call("get_ray")
	var foot: CinderLaneMechanism = fixture.parent.call("get_foot")
	for event: String in ["state_changed", "hit_resolved"]:
		_phase_watch(ray, event, events, "ray." + event)
		_phase_watch(foot, event, events, "foot." + event)
	_phase_watch(ray.call("get_cue"), "state_changed", events, "ray.cue")
	_phase_watch(foot.get_cue(), "state_changed", events, "foot.cue")
	_phase_watch(fixture.parent.call("get_joint_cue"), "state_changed", events, "joint.cue")
	var actor: Node3D = fixture.parent.call("get_actor")
	_phase_watch(actor, "phase_boundary_reached", events, "actor.threshold")
	_phase_watch(actor, "defeated", events, "actor.defeated")
	return fixture

func _phase_transport() -> void:
	paused = false
	var source: Dictionary = _phase_create()
	if not _expect(source.configured, "actual Standard parent binds complete two-owner/one-floor transport scope"): return
	var parent: Node3D = source.parent
	var ray: Node3D = parent.call("get_ray")
	if not _expect(await _until(source, func() -> bool: return _stable(source.hero)), "real source earns grounded native support before start"): return
	if not _expect(bool(parent.call("start")), "public start seeds actual first bait boundary"): return
	if not _expect(await _until(source, func() -> bool: return ray.call("state").get("armed", false) and ray.call("state").get("proof_available", false)), "actual Ray native lock supplies original primary-only response proof"): return
	var first: Dictionary = ray.call("state")
	if not await _phase_first_strike(source, first.proof): return
	# Strike returns outside the complete native damage transaction. At priority
	#120 the complete consumer/parent tick has finished; pause before another tick.
	await _phase_barrier()
	var pending: Dictionary = _phase_capture(source)
	if not _expect(_phase_complete(pending) and pending.parent.actor.actor.hp == 15.0 and pending.parent.actor.transition_pending and pending.parent.actor.boss_phase == 1 and pending.parent.joint.state == "spent" and pending.parent.parent.notifications.checkpoint == "none", "real first Heavy hit yields strict pending15HP/spent source packet before phase commit"): return
	_expect(pending.parent.parent.threshold.actual_hp_loss == 15.0 and pending.parent.parent.threshold.hp_before == 30.0 and pending.parent.parent.threshold.hp_after == 15.0 and pending.parent.parent.ray_introduction.closing == "cancelled" and pending.parent.parent.ray_introduction.last_cancel_reason == "b05_first_brace_spent" and pending.parent.foot.cycle == 0 and source.checkpoints.is_empty(), "pending packet retains real capped threshold/cancelled Ray introduction and cannot invent Foot or phase notification")
	if not _phase_refuse(source, pending, "pending flag"): return
	var pending_copy: Dictionary = await _phase_fresh(pending, "actual pending first brace")
	if pending_copy.is_empty(): return
	var before_death: Dictionary = _phase_capture(pending_copy)
	var deaths: Array[bool] = []
	pending_copy.hero.died.connect(func() -> void: deaths.append(true))
	paused = false
	pending_copy.hero.take_damage(pending_copy.hero.max_hp * 4.0, Vector3.ZERO)
	await _phase_barrier()
	var dead: Dictionary = _phase_capture(pending_copy)
	if not _expect(_phase_complete(dead) and deaths.size() == 1 and dead.player.resources.dead and dead.player.resources.hp == 0.0 and dead.parent.parent.stage == "cancelled" and dead.parent.actor.actor.hp == 15.0 and dead.parent.actor.transition_pending and dead.parent.joint.state == "spent", "public shared hurt creates real dead/pending/spent source tuple without repairing it at capture"): return
	_expect(_phase_same(dead.parent.parent.threshold, before_death.parent.parent.threshold) and _phase_same(dead.parent.parent.ray_introduction, before_death.parent.parent.ray_introduction) and dead.parent.ray.record.status != "running" and dead.parent.foot.status != "running" and dead.scheduler.reservations.is_empty() and dead.parent.parent.notifications.checkpoint == "none", "fatal native barrier preserves original threshold/deadlines/history and closes both owners without notification")
	if not _phase_refuse(pending_copy, dead, "dead available cue"): return
	var dead_copy: Dictionary = await _phase_fresh(dead, "actual dead pending brace")
	if dead_copy.is_empty(): return
	_expect(not bool(dead_copy.parent.call("resume_after_phase_checkpoint")) and _phase_same(dead, _phase_capture(dead_copy)), "dead pending recipient cannot acknowledge or advance phase and remains exact")
	_phase_release(dead_copy)
	_phase_release(pending_copy)

	# Continue the unchanged original living native unit. No saved tuple is
	# written back to it and no physical/clock/phase state is staged live.
	paused = false
	var foot: CinderLaneMechanism = parent.call("get_foot")
	if not _expect(await _until(source, func() -> bool: return foot.state().status == "running" and _accepted_foot(parent.call("state"), "foot-introduction").size() == 1), "original pending source admits its exactly-once real isolated Foot introduction"): return
	var intro: Dictionary = _accepted_foot(parent.call("state"), "foot-introduction")[0]
	if not _expect(await _follow_motion_proof(source, intro.proof, false, false), "inherited actual public Foot escape/return completes without striking spent brace"): return
	if not _expect(await _until(source, func() -> bool: return parent.call("state").stage == "phase-two-checkpoint" and not parent.call("state").checkpoint_notice_sent), "priority120 observes actual earned phase commit before deferred eligibility delivery"): return
	await _phase_barrier()
	var phase_pending: Dictionary = _phase_capture(source)
	if not _expect(_phase_complete(phase_pending) and phase_pending.parent.parent.notifications.checkpoint == "pending" and not phase_pending.parent.parent.checkpoint_notice_sent and phase_pending.parent.actor.boss_phase == 2 and not phase_pending.parent.actor.transition_pending and phase_pending.parent.actor.actor.hp == 15.0 and source.checkpoints.is_empty(), "strict phase2 pending-notification packet follows real first pool and natural Foot completion"): return
	_expect(phase_pending.parent.foot.status == "complete" and phase_pending.parent.parent.foot_introduction.closing == "complete" and phase_pending.parent.parent.foot_introduction.completed_clock_s > phase_pending.parent.parent.foot_introduction.exchange.recovery_until_s and phase_pending.scheduler.clock_s > phase_pending.parent.parent.ray_introduction.exchange.recovery_until_s and phase_pending.scheduler.clock_s >= phase_pending.parent.parent.ray_introduction.exchange.cooldown_until_s, "phase commit drains actual cancelled Ray deadlines and naturally completed Foot recovery before notification")
	if not _phase_refuse(source, phase_pending, "erased notification"): return
	_phase_release(source)
	var notified: Dictionary = await _phase_fresh(phase_pending, "actual pending phase2 notification")
	if notified.is_empty(): return
	_expect(not bool(notified.parent.call("resume_after_phase_checkpoint")) and _phase_same(phase_pending, _phase_capture(notified)), "paused pending recipient cannot acknowledge before genuine notification")
	paused = false
	if not _expect(await _until(notified, func() -> bool: return notified.checkpoints.size() == 1), "restored pending transaction publishes exactly one genuine eligibility after public native resume"): return
	await _phase_barrier()
	var delivered: Dictionary = _phase_capture(notified)
	if not _expect(_phase_complete(delivered) and delivered.parent.parent.notifications.checkpoint == "delivered" and delivered.parent.parent.checkpoint_notice_sent and notified.checkpoints.size() == 1 and notified.clears.is_empty(), "delivered packet records one eligibility with no clear/defeat event"): return
	_expect(_phase_same(delivered.parent.parent.phase_commit, phase_pending.parent.parent.phase_commit) and _phase_same(delivered.parent.parent.threshold, phase_pending.parent.parent.threshold) and _phase_same(delivered.parent.parent.foot_introduction, phase_pending.parent.parent.foot_introduction), "notification delivery preserves original earned boundary/threshold/natural Foot receipts exactly")
	_phase_release(notified)
	var phase_two: Dictionary = await _phase_fresh(delivered, "actual delivered phase2 boundary")
	if phase_two.is_empty(): return
	paused = false
	for _index: int in range(8): await _step(phase_two)
	if not _expect(phase_two.checkpoints.is_empty() and phase_two.clears.is_empty() and phase_two.parent.call("state").stage == "phase-two-checkpoint", "restored delivered notification never replays during native resume"): return
	if not _expect(bool(phase_two.parent.call("resume_after_phase_checkpoint")), "TEST ONLY component host acknowledgement resumes actual delivered phase2; no Shell checkpoint credit"): return
	if not _expect(await _until(phase_two, func() -> bool: return phase_two.parent.call("state").pair.get("validated", false)), "actual phase2 Foot-first stagger and armed Ray earn first real combined native proof"): return
	await _phase_barrier()
	var paired: Dictionary = _phase_capture(phase_two)
	if not _expect(_phase_complete(paired) and paired.parent.parent.stage == "phase-two" and paired.parent.parent.pair.validated and paired.parent.foot.status == "running" and paired.parent.ray.record.status == "running" and paired.parent.ray.record.exchange.adapter.locked, "strict late paired tuple contains both actual live cycles and original combined proof"): return
	var pair: Dictionary = paired.parent.parent.pair
	_expect(pair.proof.accepted and not pair.proof.uses_blast and not pair.proof.uses_invulnerability and pair.proof.response_complete_s == pair.proof.primary_time_s + float(phase_two.hero.stats.primary_cooldown) and pair.proof.response_complete_s <= minf(pair.ray_exchange.recovery_until_s, pair.foot_exchange.recovery_until_s) - SchedulerScript.TIME_MARGIN, "portable combined proof preserves original both-window/full-primary-cadence guarantee")
	if not _phase_refuse(phase_two, paired, "copied pair deadline"): return
	_phase_release(phase_two)
	var paired_copy: Dictionary = await _phase_fresh(paired, "actual armed phase2 pair")
	if paired_copy.is_empty(): return
	_expect(paired_copy.parent.call("state").pair.validated and paired_copy.parent.call("state").actor_hp == 15.0 and paired_copy.checkpoints.is_empty() and paired_copy.clears.is_empty(), "quiet armed pair restoration retains earned pool/proof without new delivery or defeat")
	_phase_release(paired_copy)

func _phase_first_strike(fixture: Dictionary, proof: Dictionary) -> bool:
	if not proof.get("accepted", false) or not proof.get("path") is Array: return false
	var hero: CinderPlayer = fixture.hero
	for segment: Dictionary in proof.path:
		if not await _wait_clock(fixture, float(segment.start_s)): return false
		if String(segment.kind) in ["escape_dash", "positioning_dash"]:
			if not _expect(fixture.scheduler.get_clock() < float(segment.end_s) and _stable(hero) and hero.get_threat_response_state().dash_cooldown_left_s == 0.0, "actual first-response dash starts inside allotted native interval with readiness"): return false
			var before: int = _last_sequence(hero)
			if not _expect(hero.request_dash((segment["to"] - segment["from"]).normalized()), "public native first-response dash accepts original proof direction"): return false
			if not await _until(fixture, func() -> bool: return _last_sequence(hero) > before and _stable(hero)): return false
			var actual: Dictionary = hero.get_world_action_records()[-1]
			if not _expect(actual.kind == "dash" and not actual.blocked and not actual.collision_shortened and fixture.bait.call("sample_for_ray").dash_sequence == actual.sequence, "actual completed first-response landing is retained by the canonical bait cache"): return false
		elif String(segment.kind) == "ordinary_primary":
			var state: Dictionary = fixture.parent.call("state")
			var actor: Node3D = fixture.parent.call("get_actor")
			if not _expect(_stable(hero) and hero.get_threat_response_state().primary_cooldown_left_s == 0.0 and state.joint_cue.state == "available" and state.ray.status == "running" and state.ray.phase == "recovery" and fixture.scheduler.get_clock() + float(hero.stats.primary_cooldown) <= state.ray.exchange.recovery_until_s - SchedulerScript.TIME_MARGIN and Geometry.planar(hero.global_position).distance_to(Geometry.planar(actor.global_position)) < float(hero.stats.primary_range), "actual public first primary is reachable and its full cadence fits real recovery"): return false
			# Preserve the genuine post-transaction pending state immediately;
			# inherited normal runner additionally waits through primary cooldown.
			return _expect(hero.slash(actor.global_position - hero.global_position) == 1, "one public Heavy primary exhausts only the actual first finite pool")
		else:
			if not await _wait_clock(fixture, float(segment.end_s)): return false
	return false

func _phase_barrier() -> void:
	paused = true
	for _index: int in range(2): await process_frame

func _phase_capture(fixture: Dictionary) -> Dictionary:
	var player: Dictionary = fixture.hero.snapshot_state()
	var scheduler: Dictionary = fixture.scheduler.snapshot_state(fixture.bindings)
	var parent: Dictionary = fixture.parent.call("snapshot_state", fixture.bindings)
	return {"player": player, "scheduler": scheduler, "parent": parent}

func _phase_complete(packet: Dictionary) -> bool:
	return packet.get("player") is Dictionary and not packet.player.is_empty() and packet.get("scheduler") is Dictionary and not packet.scheduler.is_empty() and packet.get("parent") is Dictionary and not packet.parent.is_empty()

func _phase_preflight(fixture: Dictionary, packet: Dictionary) -> String:
	var error: String = fixture.hero.snapshot_error(packet.player)
	var staged: Dictionary = fixture.bindings.duplicate()
	staged["hero_positions"] = {"hero": Codec.read_vector3(packet.player.motion.position)}
	if error.is_empty(): error = fixture.scheduler.snapshot_error(packet.scheduler, staged)
	if error.is_empty(): error = String(fixture.parent.call("snapshot_error", packet.parent, fixture.bindings, packet.player, packet.scheduler))
	return error

func _phase_fresh(original: Dictionary, label: String) -> Dictionary:
	var wire: String = PhaseExact.stringify(original)
	var parsed: Dictionary = PhaseExact.parse(wire)
	if not _expect(not wire.is_empty() and parsed.get("accepted", false) and PhaseExact.stringify(parsed.value) == wire, label + " full actual tuple exact typed JSON roundtrip"): return {}
	var saved: Dictionary = parsed.value
	var fresh: Dictionary = _phase_create()
	if not _expect(fresh.configured and _phase_preflight(fresh, saved).is_empty(), label + " pure fresh same-call native preflight before first recipient physics"): return {}
	var identity: bool = true
	for old: Dictionary in _phase_worlds:
		if not old.disposed and old.viewport != fresh.viewport and (old.hero == fresh.hero or old.parent == fresh.parent or old.scheduler == fresh.scheduler): identity = false
	var pristine: Dictionary = _phase_capture(fresh)
	if not _expect(identity and _phase_complete(pristine) and pristine.parent.parent.stage == "dormant", label + " actual fresh native identities remain pristine before commit"): return {}
	for repetition: int in range(2):
		var event_count: int = fresh.events.size()
		if not _expect(_phase_preflight(fresh, saved).is_empty(), label + " full pure preflight precedes quiet repeat%d" % repetition): return {}
		if not _expect(fresh.hero.restore_state(saved.player), label + " restores full actual shared Player first"): return {}
		if not _expect(bool(fresh.parent.call("restore_source_state", saved.parent, fresh.bindings, saved.player, saved.scheduler)), label + " commits exact Bait/Actor/spent-or-clear Joint after actual Player"): return {}
		if not _expect(fresh.scheduler.restore_state(saved.scheduler, fresh.bindings), label + " quietly commits the one complete native Scheduler"): return {}
		if not _expect(bool(fresh.parent.call("restore_consumers_state", saved.parent, fresh.bindings, saved.player, saved.scheduler)), label + " commits both actual consumers and original bounded parent receipts"): return {}
		if not _expect(_phase_same(saved, _phase_capture(fresh)) and fresh.events.size() == event_count and fresh.failures.is_empty(), label + " exact repeated recapture emits no cue/action/damage/phase/progression callbacks"): return {}
	for _index: int in range(2): await process_frame
	_expect(_phase_same(saved, _phase_capture(fresh)) and fresh.checkpoints.is_empty() and fresh.clears.is_empty(), label + " held paused restore preserves notifications and native clocks exactly")
	return fresh if _failures == 0 else {}

func _phase_refuse(fixture: Dictionary, saved: Dictionary, kind: String) -> bool:
	var bad: Dictionary = saved.duplicate(true)
	match kind:
		"pending flag": bad.parent.actor.transition_pending = false
		"dead available cue": bad.parent.joint.state = "available"
		"erased notification": bad.parent.parent.notifications.checkpoint = "none"
		"copied pair deadline": bad.parent.parent.pair.foot_exchange.recovery_until_s += 0.125
	var before: Dictionary = _phase_capture(fixture)
	var events: int = fixture.events.size()
	var error: String = _phase_preflight(fixture, bad)
	return _expect(not error.is_empty() and not bool(fixture.parent.call("restore_source_state", bad.parent, fixture.bindings, bad.player, bad.scheduler)) and _phase_same(before, _phase_capture(fixture)) and fixture.events.size() == events, "malformed " + kind + " preflight/source commit refuse atomically: " + error)

func _phase_watch(node: Object, event: String, events: Array[String], label: String) -> void:
	var arity: int = -1
	for definition: Dictionary in node.get_signal_list():
		if String(definition.name) == event: arity = definition.args.size()
	var callback: Callable
	match arity:
		0: callback = func() -> void: events.append(label)
		1: callback = func(_a: Variant) -> void: events.append(label)
		2: callback = func(_a: Variant, _b: Variant) -> void: events.append(label)
		3: callback = func(_a: Variant, _b: Variant, _c: Variant) -> void: events.append(label)
		_: _expect(false, "real signal arity is supported: " + label); return
	node.connect(event, callback)

func _phase_same(left: Variant, right: Variant) -> bool:
	var encoded: String = PhaseExact.stringify(left)
	return not encoded.is_empty() and encoded == PhaseExact.stringify(right)

func _phase_release(fixture: Dictionary) -> void:
	if fixture.disposed: return
	paused = true
	var refs: Array[WeakRef] = [weakref(fixture.viewport), weakref(fixture.world), weakref(fixture.hero), weakref(fixture.parent), weakref(fixture.scheduler)]
	if fixture.configured:
		for method: String in ["get_actor", "get_ray", "get_foot", "get_joint_cue"]:
			var part: Variant = fixture.parent.call(method)
			if is_instance_valid(part): refs.append(weakref(part))
		for method: String in ["get_ray", "get_foot"]:
			var consumer: Variant = fixture.parent.call(method)
			if is_instance_valid(consumer) and consumer.has_method("get_cue"):
				var cue: Variant = consumer.call("get_cue")
				if is_instance_valid(cue): refs.append(weakref(cue))
	fixture.parent.call("cleanup")
	fixture.bait.call("release")
	if fixture.hero.world_action_executed.is_connected(fixture.action_callback): fixture.hero.world_action_executed.disconnect(fixture.action_callback)
	fixture.scheduler.end_encounter("test_whole_late_parent_disposal")
	fixture.viewport.free()
	fixture.disposed = true
	var gone: bool = true
	for ref: WeakRef in refs:
		if ref.get_ref() != null: gone = false
	_expect(gone, "whole actual late-parent/controller/owners/cues/Scheduler world is freed")

func _phase_finish() -> void:
	if _phase_finished: return
	_phase_finished = true
	paused = true
	for fixture: Dictionary in _phase_worlds:
		if not fixture.disposed: _phase_release(fixture)
	_phase_worlds.clear()
	paused = false
	print("A2-L5 Sentry phase transport smoke: %d checks, %d failures; actual Standard first threshold/spent-source fatal/natural Foot/phase2 pending-delivered exactly-once notification/first armed paired native quiet transport only; no protected Shell checkpoint, whole route, second-pool defeat, recognizer, portrait or balance credit" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
