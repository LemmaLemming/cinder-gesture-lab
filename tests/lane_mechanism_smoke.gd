extends SceneTree

const World = preload("res://tests/fixtures/lane_mechanism_world.gd")
const Mechanism = preload("res://scripts/combat/lane_mechanism.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_default_cycle()
	await _test_response_rejection_and_cancellation()
	await _test_dash_crossing_and_live_heroes()
	await _test_snapshot_continuation()
	await _test_cancelled_snapshot_and_callbacks()
	print("Lane mechanism smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_default_cycle() -> void:
	var arena: Dictionary = World.create(self)
	await _ticks(5)
	var hero: CinderPlayer = arena.hero
	var mechanism: CinderLaneMechanism = arena.mechanism
	var scheduler: CinderThreatScheduler = arena.scheduler
	paused = true
	_expect(hero.equip_item("CLOTH-J1"), "armor fixture uses the supported paused safe clothing boundary")
	paused = false
	hero.hp = 12.5
	var expected_loss: float = hero.equipment.damage_received(4.0)
	var phases: Array[String] = []
	var results: Array[Dictionary] = []
	var artwork := Node3D.new()
	artwork.name = "AuthoredLoadingArmArtwork"
	mechanism.add_child(artwork)
	mechanism.state_changed.connect(func(value: Dictionary) -> void:
		phases.append(value.phase)
		artwork.visible = value.status == "running"
		value.resolved_role.damage = 999.0
	)
	mechanism.hit_resolved.connect(func(id: String, cycle: int, result: Dictionary) -> void: results.append({"hero": id, "cycle": cycle, "result": result.duplicate(true)}))
	_expect(scheduler.begin_encounter("standard", "arm-default"), "loading arm uses a fresh fixed shared encounter")
	var answer: Dictionary = mechanism.start("hero", World.context(arena, "arm-default"))
	_expect(answer.get("accepted", false), "real empty-ammo shared hero receives scheduler-proved normal-dash/primary opportunity")
	if not answer.get("accepted", false):
		push_error(mechanism.last_error)
		await _dispose(arena)
		return
	_expect(not answer.proof.uses_blast and not answer.proof.uses_invulnerability and hero.get_world_action_records().is_empty(), "mechanism proof and execution add no blast requirement or fabricated player action")
	_expect(not mechanism.is_in_group("enemies") and not mechanism.is_in_group("practice_targets") and not mechanism.has_method("take_damage"), "friendly arm remains a nonenemy mechanism with no living target/reload classification")
	var state: Dictionary = mechanism.state()
	_expect(_near(state.resolved_role.windup_s - state.resolved_role.lock_s, 1.1) and _near(state.resolved_role.lock_s, 1.1) and _near(state.resolved_role.active_s, 0.2) and _near(state.resolved_role.recovery_s, 1.6) and state.resolved_role.tuning_status == "provisional_unplaytested", "default warning/lock/active/recovery are 1.1/1.1/0.2/1.6 seconds with explicit provisional status")
	_expect(_near(state.resolved_role.damage, 4.0) and mechanism.get_cue().state().geometry == state.geometry and mechanism.get_cue().global_position == mechanism.global_position, "public cue displays the actual stationary mechanism source and full committed lane")
	state.geometry.radius = 999.0
	_expect(_near(mechanism.state().geometry.radius, 0.3) and not mechanism.start("hero", World.context(arena, "arm-default")).get("accepted", false), "defensive state and occupied cycle reject mutation/nested replacement")
	paused = true
	var clock: float = scheduler.get_clock()
	var remaining: float = mechanism.state().remaining_s
	await create_timer(0.05, true).timeout
	_expect(_near(scheduler.get_clock(), clock) and _near(mechanism.state().remaining_s, remaining) and hero.hp == 12.5 and mechanism.get_cue().state().phase == "warning", "pause freezes shared clock, visible warning and low player resources together")
	_expect(not mechanism.start("hero", World.context(arena, "arm-default")).get("accepted", false), "paused UI cannot create a mechanism cycle")
	paused = false
	_expect(await _until_phase(mechanism, "lock"), "actual physics reaches the fixed lock")
	_expect(hero.hp == 12.5 and results.is_empty() and mechanism.get_cue().state().phase == "lock", "warning and lock have no early environmental damage")
	_expect(await _until_phase(mechanism, "active"), "actual physics enters active without an extra success delay")
	_expect(results.size() == 1 and _near(hero.hp, 12.5 - expected_loss) and results[0].hero == "hero" and results[0].cycle == 1 and _near(results[0].result.hp_damage, expected_loss), "first actual exposure applies low environmental damage through shared armor exactly once")
	_expect(results[0].result.impulse == Vector3.ZERO and Vector2(hero.velocity.x, hero.velocity.z).is_zero_approx() and mechanism.state().hit_ids == ["hero"], "arm consumes one hero opportunity before callbacks with zero planar impulse")
	_expect(await _until_phase(mechanism, "recovery"), "actual active interval ends in the shared recovery opening")
	_expect(results.size() == 1 and mechanism.get_cue().state().phase == "recovery", "continued exposure never grants another opportunity in the same swing")
	_expect(await _until_phase(mechanism, "clear"), "full recovery releases reservation and required cue")
	_expect(mechanism.state().status == "complete" and scheduler.reservations().is_empty() and phases == ["warning", "lock", "active", "recovery", "clear"] and not artwork.visible, "public phase hooks drive act artwork through the complete finite grammar")
	hero.shells = 0
	answer = mechanism.start("hero", World.context(arena, "arm-default"))
	_expect(answer.get("accepted", false) and mechanism.state().cycle == 2 and mechanism.state().hit_ids.is_empty(), "only a new accepted explicit cycle resets per-hero opportunity dedupe")
	mechanism.clear("target_cleared")
	_expect(mechanism.state().phase == "clear" and mechanism.get_cue().state().phase == "clear" and scheduler.reservations().is_empty(), "target clear cancels immediately without waiting for active/recovery/success timers")
	await _dispose(arena)


func _test_response_rejection_and_cancellation() -> void:
	var arena: Dictionary = World.create(self)
	await _ticks(5)
	var mechanism: CinderLaneMechanism = arena.mechanism
	var scheduler: CinderThreatScheduler = arena.scheduler
	scheduler.begin_encounter("standard", "arm-denials")
	var context: Dictionary = World.context(arena, "arm-denials")
	var bad: Dictionary = context.duplicate(true)
	bad.recognition_s = 3.0
	_expect(not mechanism.start("hero", bad).get("accepted", false) and mechanism.state().cycle == 0 and scheduler.reservations().is_empty(), "unsafe recognition budget rejects before any arm phase/cycle begins")
	bad = context.duplicate(true)
	bad.floor_regions = []
	_expect(not mechanism.start("hero", bad).get("accepted", false) and mechanism.get_cue().state().phase == "clear", "missing actual floor proof never falls back to a decorative lane")
	bad = context.duplicate(true)
	bad.escape_directions = [Vector3(2, 0, 0)]
	_expect(not mechanism.start("hero", bad).get("accepted", false), "unnormalized escape candidates fail through the shared authoritative validator")
	bad = context.duplicate(true)
	bad.stats = {"dash_speed": 999.0}
	_expect(not mechanism.start("hero", bad).get("accepted", false), "caller cannot override actual public hero stats or spoof a proxy response")
	mechanism.position.x += 0.5
	_expect(not mechanism.start("hero", context).get("accepted", false), "disconnected source placement rejects rather than reserving an invisible source proxy")
	mechanism.position.x -= 0.5
	var wall := StaticBody3D.new()
	wall.name = "EscapeWall"
	var collision := CollisionShape3D.new()
	collision.name = "Solid"
	var box := BoxShape3D.new()
	box.size = Vector3(12, 2, 0.2)
	collision.shape = box
	wall.add_child(collision)
	arena.root.add_child(wall)
	wall.position = Vector3(0, 1, 1)
	await _ticks(2)
	bad = context.duplicate(true)
	bad.escape_directions = [Vector3.BACK]
	_expect(not mechanism.start("hero", bad).get("accepted", false) and mechanism.state().cycle == 0, "actual obstruction rejects collision-shortened escape instead of claiming a safe full dash")
	wall.queue_free()
	await _ticks(2)
	_expect(mechanism.start("hero", context).get("accepted", false), "same actual actor/layout can begin once a supported escape exists")
	scheduler.invalidate_world(2)
	_expect(mechanism.state().phase == "clear" and mechanism.state().last_cancel_reason == "collision_world_changed" and mechanism.get_cue().state().phase == "clear", "reservation invalidation immediately cancels required warning and arm phase")
	context.world_revision = 2
	_expect(not mechanism.start("hero", context).get("accepted", false), "cancellation preserves source cooldown rather than granting a fresh swing")
	scheduler.end_encounter()
	_expect(scheduler.begin_encounter("assisted", "arm-assisted"), "fresh boundary can select Assisted")
	context.encounter_id = "arm-assisted"
	context.world_revision = 1
	_expect(mechanism.start("hero", context).get("accepted", false) and _near(mechanism.state().resolved_role.damage, 2.8) and _near(mechanism.state().resolved_role.windup_s, 2.97) and _near(mechanism.state().resolved_role.recovery_s, 2.16), "fresh profile resolves the unchanged raw role once without compounding old cycle stats")
	mechanism.clear("exit")
	_expect(scheduler.reservations().is_empty() and mechanism.get_cue().state().phase == "clear", "exit cleanup removes all live required hazard parts immediately")
	await _dispose(arena)


func _test_dash_crossing_and_live_heroes() -> void:
	var raw: Dictionary = Mechanism.DEFAULT_RAW_ROLE.duplicate(true)
	raw.active_s = 1.05
	raw.attack_interval_s = raw.active_s + raw.recovery_s
	var arena: Dictionary = World.create(self, raw)
	await _ticks(5)
	var hero: CinderPlayer = arena.hero
	var mechanism: CinderLaneMechanism = arena.mechanism
	var scheduler: CinderThreatScheduler = arena.scheduler
	scheduler.begin_encounter("standard", "arm-crossing")
	var context: Dictionary = World.context(arena, "arm-crossing")
	hero.position.z = -1.2
	await _ticks(2)
	var events: Array[Dictionary] = []
	mechanism.hit_resolved.connect(func(_id: String, _cycle: int, result: Dictionary) -> void: events.append(result.duplicate(true)))
	_expect(mechanism.start("hero", context).get("accepted", false), "authored longer active fixture receives a real supported response")
	_expect(await _until_phase(mechanism, "active"), "dash crossing fixture reaches active while hero stands outside capsule")
	_expect(events.is_empty() and hero.hp == hero.max_hp, "outside hero does not spend its cycle opportunity")
	_expect(hero.request_dash(Vector3.BACK), "actual shared physics dash crosses the finite active lane")
	await _ticks(2)
	paused = true
	await process_frame
	var bindings: Dictionary = World.bindings(arena)
	var actor_saved: Dictionary = _json(hero.snapshot_state())
	var scheduler_saved: Dictionary = _json(scheduler.snapshot_state(bindings))
	var arm_saved: Dictionary = _json(mechanism.snapshot_state(bindings))
	_expect(not arm_saved.is_empty() and actor_saved.clocks.dash_left_s > 0.0 and arm_saved.hero_samples.hero.position == actor_saved.motion.position, "mid-dash paired capture retains the same real physics hero sample and unfinished actor path")
	paused = false
	await _ticks(13)
	_expect(events.size() == 1 and mechanism.state().hit_ids == ["hero"] and events[0].opportunity_consumed and events[0].impulse == Vector3.ZERO, "actual completed physics crossing consumes exactly one padded-capsule opportunity")
	_expect(hero.get_world_action_records().size() == 1 and hero.get_world_action_records()[0].kind == "dash", "mechanism uses real hero motion without fabricating attack or dash records")
	var uninterrupted_dash: Dictionary = hero.get_world_action_records()[0]
	paused = true
	await process_frame
	bindings.hero_positions = {"hero": Codec.read_vector3(actor_saved.motion.position)}
	_expect(mechanism.snapshot_error(arm_saved, bindings, scheduler_saved).is_empty() and hero.restore_state(actor_saved) and scheduler.restore_state(scheduler_saved, bindings) and mechanism.restore_state(arm_saved, bindings), "actual mid-dash actor/scheduler/mechanism pair prevalidates and commits without reexecuting input")
	paused = false
	await _ticks(13)
	var restored_dash: Dictionary = hero.get_world_action_records()[0]
	_expect(restored_dash.path == uninterrupted_dash.path and restored_dash.landing == uninterrupted_dash.landing and _near(restored_dash.completed_at_s, uninterrupted_dash.completed_at_s) and mechanism.state().hit_ids == ["hero"], "restored real dash completes with identical physics path/landing/time and the correct cycle opportunity")
	var resumed_events: int = events.size()
	hero.position.z = 0.0
	await _ticks(55)
	_expect(events.size() == resumed_events, "returning after dash/hurt invulnerability expires cannot spend a second opportunity in the same long active cycle")
	hero.dead = true
	mechanism.clear("hero_dead")
	_expect(not mechanism.start("hero", context).get("accepted", false), "dead shared actor never becomes a fresh proxy response")
	await _dispose(arena)


func _test_snapshot_continuation() -> void:
	var raw: Dictionary = Mechanism.DEFAULT_RAW_ROLE.duplicate(true)
	raw.active_s = 1.05
	raw.attack_interval_s = raw.active_s + raw.recovery_s
	var arena: Dictionary = World.create(self, raw)
	await _ticks(5)
	var hero: CinderPlayer = arena.hero
	var scheduler: CinderThreatScheduler = arena.scheduler
	var mechanism: CinderLaneMechanism = arena.mechanism
	var bindings: Dictionary = World.bindings(arena)
	scheduler.begin_encounter("standard", "arm-restore")
	hero.hp = 12.5
	_expect(mechanism.start("hero", World.context(arena, "arm-restore")).get("accepted", false), "snapshot fixture begins a real reserved cycle")
	await _ticks(8)
	paused = true
	await process_frame
	var warning_actor: Dictionary = _json(hero.snapshot_state())
	var warning_scheduler: Dictionary = _json(scheduler.snapshot_state(bindings))
	var warning: Dictionary = _json(mechanism.snapshot_state(bindings))
	_expect(not warning.is_empty() and warning.phase == "warning" and Codec.value_error(warning).is_empty() and warning.exchange.id == warning_scheduler.reservations[0].id, "finite JSON warning snapshot retains the actual paired reservation/phase/path samples")
	if warning.is_empty():
		push_error(mechanism.last_snapshot_error)
		await _dispose(arena)
		return
	var phase_events: Array[String] = []
	var hits: Array[Dictionary] = []
	var cue_events: Array[String] = []
	mechanism.state_changed.connect(func(value: Dictionary) -> void: phase_events.append(value.phase))
	mechanism.hit_resolved.connect(func(_id: String, _cycle: int, result: Dictionary) -> void: hits.append(result.duplicate(true)))
	mechanism.get_cue().state_changed.connect(func(value: Dictionary) -> void: cue_events.append(value.phase))
	paused = false
	_expect(await _until_phase(mechanism, "active"), "uninterrupted warning first reaches its real active interval")
	var uninterrupted_hp: float = hero.hp
	_expect(hits.size() == 1 and _near(uninterrupted_hp, 8.5), "uninterrupted actual exposure resolves one four-point hit")
	paused = true
	await process_frame
	var unchanged: Dictionary = mechanism.snapshot_state(bindings)
	_expect(not mechanism.restore_state(warning, bindings) and Codec.same_values(unchanged, mechanism.snapshot_state(bindings)), "mechanism-only restore rejects a different live scheduler clock/reservation generation atomically")
	bindings.hero_positions = {"hero": Codec.read_vector3(warning_actor.motion.position)}
	_expect(mechanism.snapshot_error(warning, bindings, warning_scheduler).is_empty(), "paired pure prevalidation accepts the staged scheduler and actor tick before any mutation")
	mechanism.position.x += 0.5
	bindings.owner_positions = {"loading-arm": Vector3(-1, 0, 0)}
	_expect(scheduler.snapshot_error(warning_scheduler, bindings).is_empty() and mechanism.snapshot_error(warning, bindings, warning_scheduler).is_empty(), "staged static source position validates the complete pair before restoring actual placement")
	_expect(not mechanism.restore_state(warning, bindings), "commit refuses a staged-only source without an actual matching restored reservation")
	mechanism.position.x -= 0.5
	var event_counts: Array = [phase_events.size(), hits.size(), cue_events.size()]
	_expect(hero.restore_state(warning_actor) and scheduler.restore_state(warning_scheduler, bindings) and mechanism.restore_state(warning, bindings), "actor then scheduler then mechanism commit restores exact low resources and pending warning")
	_expect(hero.hp == 12.5 and Codec.same_values(warning, mechanism.snapshot_state(bindings)) and event_counts == [phase_events.size(), hits.size(), cue_events.size()], "restore neither heals/reexecutes damage nor emits phase/hit/cue events or refreshes cycle deadlines")
	paused = false
	_expect(await _until_phase(mechanism, "active"), "restored warning continues into the same accepted active interval")
	_expect(_near(hero.hp, uninterrupted_hp) and hits.size() == 2 and mechanism.state().cycle == 1, "restored branch resolves the same final HP once without a new reservation/cycle")
	paused = true
	await process_frame
	var active_actor: Dictionary = _json(hero.snapshot_state())
	var active_scheduler: Dictionary = _json(scheduler.snapshot_state(bindings))
	var active: Dictionary = _json(mechanism.snapshot_state(bindings))
	_expect(active.phase == "active" and active.hit_ids == ["hero"], "active snapshot contains consumed stable hero opportunity, not engine instance IDs")
	bindings.hero_positions = {"hero": Codec.read_vector3(active_actor.motion.position)}
	event_counts = [phase_events.size(), hits.size(), cue_events.size()]
	_expect(hero.restore_state(active_actor) and scheduler.restore_state(active_scheduler, bindings) and mechanism.restore_state(active, bindings), "exact active JSON restore retains path sample, cooldown and consumed opportunity")
	_expect(event_counts == [phase_events.size(), hits.size(), cue_events.size()], "active feedback rebuild is silent and never deals another strike")
	var frozen: Dictionary = mechanism.snapshot_state(bindings)
	await create_timer(0.05, true).timeout
	_expect(Codec.same_values(frozen, mechanism.snapshot_state(bindings)) and hero.hp == uninterrupted_hp, "paused aggregate freezes remaining active timing and exact low HP")
	var bad: Dictionary = active.duplicate(true)
	bad.mechanism_id = "other-arm"
	_expect(_reject_unchanged(mechanism, bad, bindings), "malformed stable identity rejects without local/scheduler mutation")
	bad = active.duplicate(true)
	bad.clock_s = NAN
	_expect(_reject_unchanged(mechanism, bad, bindings), "nonfinite clock rejects before visible or logical commit")
	bad = active.duplicate(true)
	bad.resolved_role.damage = 40.0
	_expect(_reject_unchanged(mechanism, bad, bindings), "resolved damage drift rejects instead of compounding raw role data")
	bad = active.duplicate(true)
	bad.hit_ids.append("hero")
	_expect(_reject_unchanged(mechanism, bad, bindings), "duplicate stable hero opportunity records reject atomically")
	bad = active.duplicate(true)
	bad.hero_samples.hero.clock_s += 1.0
	_expect(_reject_unchanged(mechanism, bad, bindings), "future/noncoherent hero sample rejects rather than inventing a resumed path")
	bad = active.duplicate(true)
	bad.exchange.geometry.radius = 5.0
	_expect(_reject_unchanged(mechanism, bad, bindings), "hazard geometry drift rejects before required cue changes")
	var returned: Dictionary = mechanism.snapshot_state(bindings)
	returned.hit_ids.clear()
	returned.configuration.raw_role.raw_damage = 100.0
	_expect(Codec.same_values(active, mechanism.snapshot_state(bindings)), "transport snapshots are defensive down to role and dedupe containers")
	paused = false
	_expect(await _until_phase(mechanism, "recovery"), "restored long active cycle reaches original recovery without another hit after invulnerability expires")
	_expect(hero.hp == uninterrupted_hp and hits.size() == 2, "active dedupe survives more than the shared hurt invulnerability duration")
	paused = true
	await process_frame
	var recovery_scheduler: Dictionary = _json(scheduler.snapshot_state(bindings))
	var recovery: Dictionary = _json(mechanism.snapshot_state(bindings))
	_expect(scheduler.restore_state(recovery_scheduler, bindings) and mechanism.restore_state(recovery, bindings) and mechanism.get_cue().state().phase == "recovery", "recovery restore reconnects its existing opening without a fresh warning/strike")
	paused = false
	_expect(await _until_phase(mechanism, "clear") and mechanism.state().status == "complete" and hero.hp == uninterrupted_hp, "restored recovery completes naturally with the same resources and no extra damage")
	await _dispose(arena)


func _test_cancelled_snapshot_and_callbacks() -> void:
	var arena: Dictionary = World.create(self)
	await _ticks(5)
	var mechanism: CinderLaneMechanism = arena.mechanism
	var scheduler: CinderThreatScheduler = arena.scheduler
	var bindings: Dictionary = World.bindings(arena)
	scheduler.begin_encounter("standard", "arm-callback")
	var denied: Array[bool] = []
	mechanism.state_changed.connect(func(value: Dictionary) -> void:
		if value.phase == "warning":
			paused = true
			denied.append(mechanism.snapshot_state(bindings).is_empty())
			denied.append(not mechanism.start("hero", World.context(arena, "arm-callback")).get("accepted", false))
			mechanism.clear("target_cleared_inside_callback")
	)
	_expect(mechanism.start("hero", World.context(arena, "arm-callback")).get("accepted", false) and denied == [true, true], "phase callbacks reject mixed-generation capture/new starts while permitting immediate target cancellation")
	await process_frame
	var cancelled_scheduler: Dictionary = _json(scheduler.snapshot_state(bindings))
	var cancelled: Dictionary = _json(mechanism.snapshot_state(bindings))
	_expect(not cancelled.is_empty() and cancelled.status == "cancelled" and cancelled.phase == "clear" and cancelled_scheduler.reservations.is_empty() and cancelled_scheduler.cooldowns.size() == 1, "cancelled snapshot preserves consumed cycle and retained source cooldown without live danger")
	var bad_pair: Dictionary = cancelled_scheduler.duplicate(true)
	bad_pair.cooldowns.clear()
	_expect(not mechanism.snapshot_error(cancelled, bindings, bad_pair).is_empty(), "paired validation rejects an omitted cancellation cooldown that would grant a fresh swing")
	_expect(scheduler.restore_state(cancelled_scheduler, bindings) and mechanism.restore_state(cancelled, bindings) and mechanism.get_cue().state().phase == "clear", "cancelled checkpoint restores quietly without regranting warning/damage or forgetting cooldown")
	paused = false
	_expect(not mechanism.start("hero", World.context(arena, "arm-callback")).get("accepted", false), "restored cancelled source remains on its original cooldown")
	await _dispose(arena)
	# Also guard direct cue art callbacks while their required cue is publishing.
	arena = World.create(self)
	await _ticks(5)
	mechanism = arena.mechanism
	scheduler = arena.scheduler
	scheduler.begin_encounter("standard", "arm-cue-cancel")
	mechanism.get_cue().state_changed.connect(func(value: Dictionary) -> void:
		if value.phase == "warning":
			mechanism.cancel("art_target_cleared")
	)
	_expect(mechanism.start("hero", World.context(arena, "arm-cue-cancel")).get("accepted", false) and mechanism.state().phase == "clear" and mechanism.get_cue().state().phase == "clear" and scheduler.reservations().is_empty(), "source art callback cancellation removes the required footprint immediately after its publication returns")
	await _dispose(arena)
	arena = World.create(self)
	await _ticks(5)
	mechanism = arena.mechanism
	scheduler = arena.scheduler
	scheduler.begin_encounter("standard", "arm-cue-drift")
	_expect(mechanism.start("hero", World.context(arena, "arm-cue-drift")).get("accepted", false), "cue drift fixture starts an actual reserved warning")
	var wrong_geometry: Dictionary = mechanism.state().geometry
	wrong_geometry["to"] += Vector3.RIGHT
	mechanism.get_cue().present(wrong_geometry, "warning")
	await _ticks(2)
	_expect(mechanism.state().phase == "clear" and scheduler.reservations().is_empty() and arena.hero.hp == arena.hero.max_hp, "public cue geometry drift cancels live danger before a false footprint can damage the hero")
	await _dispose(arena)


func _reject_unchanged(mechanism: CinderLaneMechanism, bad: Dictionary, bindings: Dictionary) -> bool:
	var before: Dictionary = mechanism.snapshot_state(bindings)
	var phase: Dictionary = mechanism.get_cue().state()
	return not mechanism.restore_state(bad, bindings) and Codec.same_values(before, mechanism.snapshot_state(bindings)) and mechanism.get_cue().state() == phase


func _until_phase(mechanism: CinderLaneMechanism, phase: String) -> bool:
	for _index: int in range(420):
		if mechanism.state().phase == phase:
			return true
		await _ticks(1)
	return false


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame


func _json(value: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(value, "", true, true))


func _dispose(arena: Dictionary) -> void:
	paused = false
	arena.root.queue_free()
	await process_frame


func _near(left: Variant, right: Variant) -> bool:
	return absf(float(left) - float(right)) < 0.00001


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
