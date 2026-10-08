extends SceneTree

const World = preload("res://tests/fixtures/lane_mechanism_world.gd")
const Mechanism = preload("res://scripts/combat/lane_mechanism.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")

class OpeningRusher:
	extends CharacterBody3D
	var hp: float = 12.0
	var hits: int = 0
	var scheduler: CinderThreatScheduler
	func take_damage(amount: float, _impulse: Vector3) -> Dictionary:
		if hp <= 0.0:
			return {"accepted": false, "hp_damage": 0.0}
		var before: float = hp
		hp = maxf(0.0, hp - amount)
		hits += 1
		scheduler.cancel_owner(self, "source_defeated")
		remove_from_group("enemies")
		return {"accepted": true, "hp_damage": before - hp, "target_alive_before_hit": true}

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
	await _test_circle_crossing_and_exact_restore()
	await _test_circle_combined_actual_opening()
	await _test_circle_union_budget()
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


func _test_circle_crossing_and_exact_restore() -> void:
	var raw: Dictionary = Mechanism.DEFAULT_RAW_ROLE.duplicate(true)
	raw.active_s = 1.05
	raw.attack_interval_s = raw.active_s + raw.recovery_s
	var arena: Dictionary = _circle_arena(raw)
	var hero: CinderPlayer = arena.hero
	var mechanism: CinderLaneMechanism = arena.mechanism
	var scheduler: CinderThreatScheduler = arena.scheduler
	hero.position.z = -1.6
	await _ticks(5)
	var hp_fields: Array = mechanism.get_property_list().filter(func(value: Dictionary) -> bool: return value.name == "hp")
	_expect(hp_fields.is_empty() and not mechanism.has_method("take_damage") and not mechanism.is_in_group("enemies") and not mechanism.is_in_group("practice_targets") and mechanism.get_class() == "Node3D", "circle impact remains an HP-free nonattackable nonblocking environmental source")
	_expect(scheduler.begin_encounter("standard", "circle-crossing"), "circle uses the same fixed shared encounter")
	mechanism.position.x = 0.5
	_expect(not mechanism.start("hero", World.context(arena, "circle-crossing")).get("accepted", false) and mechanism.state().cycle == 0 and scheduler.reservations().is_empty(), "circle source must actually occupy its canonical origin before any warning or lease begins")
	mechanism.position.x = 0.0
	var answer: Dictionary = mechanism.start("hero", World.context(arena, "circle-crossing"))
	_expect(answer.get("accepted", false) and not answer.proof.uses_blast and not answer.proof.uses_invulnerability and hero.shells == 0, "canonical circle receives actual empty-ammo ordinary-primary response without a lane proxy")
	if not answer.get("accepted", false):
		print("Circle crossing diagnostic: ", answer)
		await _dispose(arena)
		return
	_expect(answer.reservation.geometry.kind == "circle" and not answer.reservation.geometry.has("from") and mechanism.get_cue().state().geometry == Geometry.circle(Vector3.ZERO, 0.3), "scheduler/cue retain the exact circle origin/radius rather than a zero-length capsule lane")
	var events: Array[Dictionary] = []
	mechanism.hit_resolved.connect(func(_id: String, _cycle: int, result: Dictionary) -> void: events.append(result.duplicate(true)))
	_expect(await _until_phase(mechanism, "lock") and events.is_empty(), "circle warning and immutable lock never deliver early damage")
	_expect(await _until_phase(mechanism, "active") and events.is_empty(), "circle activation uses existing scheduler deadline while outside hero remains unconsumed")
	_expect(hero.request_dash(Vector3.BACK), "actual shared physics dash crosses the circular footprint")
	await _ticks(2)
	paused = true
	await process_frame
	var bindings: Dictionary = World.bindings(arena)
	var pair: Dictionary = _exact_json({"hero": hero.snapshot_state(), "scheduler": scheduler.snapshot_state(bindings), "mechanism": mechanism.snapshot_state(bindings)})
	_expect(not pair.mechanism.is_empty() and pair.hero.clocks.dash_left_s > 0.0 and pair.mechanism.exchange.geometry.kind == "circle" and pair.mechanism.hero_samples.hero.position == pair.hero.motion.position, "exact JSON mid-dash circle pair retains actual path sample and pending motion")
	if pair.mechanism.is_empty():
		print("Circle snapshot diagnostic: ", mechanism.last_snapshot_error)
		await _dispose(arena)
		return
	paused = false
	await _ticks(13)
	_expect(events.size() == 1 and events[0].opportunity_consumed and not events[0].accepted and hero.hp == hero.max_hp and mechanism.state().hit_ids == ["hero"], "actual dash-circle segment consumes one opportunity even when live dash invulnerability rejects HP damage")
	var uninterrupted: Dictionary = hero.get_world_action_records()[0]
	paused = true
	await process_frame
	bindings.hero_positions = {"hero": Codec.read_vector3(pair.hero.motion.position)}
	var count: int = events.size()
	_expect(mechanism.snapshot_error(pair.mechanism, bindings, pair.scheduler).is_empty() and hero.restore_state(pair.hero) and scheduler.restore_state(pair.scheduler, bindings) and mechanism.restore_state(pair.mechanism, bindings) and events.size() == count, "staged exact circle pair validates and commits actor→scheduler→consumer quietly")
	paused = false
	await _ticks(13)
	var resumed: Dictionary = hero.get_world_action_records()[0]
	_expect(resumed.path == uninterrupted.path and resumed.landing == uninterrupted.landing and resumed.completed_at_s == uninterrupted.completed_at_s and events.size() == 2 and mechanism.state().hit_ids == ["hero"], "restored actual crossing reproduces complete dash path/time and exactly one branch-local opportunity")
	paused = true
	await process_frame
	var active: Dictionary = mechanism.snapshot_state(bindings)
	var paired: Dictionary = scheduler.snapshot_state(bindings)
	for changed: String in ["clock", "sample", "deadline", "opening"]:
		var bad: Dictionary = active.duplicate(true)
		match changed:
			"clock": bad.clock_s = _adjacent_float(float(bad.clock_s))
			"sample": bad.hero_samples.hero.clock_s = _adjacent_float(float(bad.hero_samples.hero.clock_s))
			"deadline": bad.exchange.start_s = _adjacent_float(float(bad.exchange.start_s))
			"opening": bad.exchange.opening_position[0] = _adjacent_float(0.0)
		_expect(_exact_reject_unchanged(mechanism, scheduler, _exact_json(bad), bindings), "one-bit copied circle " + changed + " drift rejects before cue/clock/HP/table mutation")
	var bad: Dictionary = active.duplicate(true)
	bad.exchange.geometry = {"kind": "lane", "from": [0.0, 0.0, 0.0], "to": [0.0, 0.0, 0.0], "radius": 0.3}
	_expect(_exact_reject_unchanged(mechanism, scheduler, bad, bindings), "circle transport cannot substitute a zero-length lane geometry")
	bad = active.duplicate(true)
	bad.hit_ids.append("hero")
	_expect(_exact_reject_unchanged(mechanism, scheduler, bad, bindings), "circle duplicate opportunity records reject atomically")
	var returned: Dictionary = mechanism.snapshot_state(bindings)
	returned.exchange.geometry.radius = 9.0
	returned.hit_ids.clear()
	_expect(ExactJson.stringify(active) == ExactJson.stringify(mechanism.snapshot_state(bindings)), "circle state/transport geometry and opportunity copies are defensive")
	var frozen: String = ExactJson.stringify({"mechanism": active, "scheduler": paired, "hero": hero.snapshot_state()})
	await create_timer(0.04, true).timeout
	_expect(frozen == ExactJson.stringify({"mechanism": mechanism.snapshot_state(bindings), "scheduler": scheduler.snapshot_state(bindings), "hero": hero.snapshot_state()}), "pause freezes exact circle deadline, samples and actual hero resources")
	bindings.erase("hero_positions")
	paused = false
	hero.position.z = 0.0
	await _ticks(55)
	_expect(events.size() == 2 and hero.hp == hero.max_hp and mechanism.state().phase == "recovery", "return after hurt/dash invulnerability expires cannot spend a second circle opportunity")
	mechanism.cancel("circle_exit")
	paused = true
	await process_frame
	var cancelled: Dictionary = _exact_json(mechanism.snapshot_state(bindings))
	var cancelled_scheduler: Dictionary = _exact_json(scheduler.snapshot_state(bindings))
	_expect(cancelled.status == "cancelled" and cancelled.phase == "clear" and not cancelled_scheduler.cooldowns.is_empty(), "circle cancellation clears required cue and retains scheduled source cooldown")
	bad = cancelled_scheduler.duplicate(true)
	bad.cooldowns.clear()
	_expect(not mechanism.snapshot_error(cancelled, bindings, bad).is_empty(), "cancelled circle pair cannot discard retained cooldown to grant a fresh impact")
	count = events.size()
	_expect(scheduler.restore_state(cancelled_scheduler, bindings) and mechanism.restore_state(cancelled, bindings) and events.size() == count and hero.hp == hero.max_hp, "cancelled exact circle restores silently without a fresh opportunity or HP change")
	paused = false
	_expect(not mechanism.start("hero", World.context(arena, "circle-crossing")).get("accepted", false), "cancelled circle keeps its original cooldown on a fresh start request")
	await _until_clock(scheduler, float(cancelled.exchange.cooldown_until_s) + 0.02)
	paused = true
	_expect(hero.equip_item("CLOTH-J1"), "circle exposure fixture uses legal shared armor at a paused boundary")
	hero.hp = 7.5
	hero.shells = 0
	var loss: float = hero.equipment.damage_received(4.0)
	paused = false
	_expect(mechanism.start("hero", World.context(arena, "circle-crossing")).get("accepted", false) and mechanism.state().cycle == 2, "only a new explicit accepted circle cycle resets the consumed opportunity")
	_expect(await _until_phase(mechanism, "active") and events.size() == 3 and events[-1].accepted and events[-1].impulse == Vector3.ZERO and _near(hero.hp, 7.5 - loss), "actual non-invulnerable circle exposure deals armor-respecting low damage once with zero impulse")
	mechanism.clear("circle_target_cleared")
	_expect(scheduler.reservations().is_empty() and mechanism.get_cue().state().phase == "clear", "circle target clear releases danger immediately without waiting through recovery")
	await _dispose(arena)


func _test_circle_combined_actual_opening() -> void:
	var arena: Dictionary = _circle_arena()
	var hero: CinderPlayer = arena.hero
	var mechanism: CinderLaneMechanism = arena.mechanism
	var scheduler: CinderThreatScheduler = arena.scheduler
	hero.position.x = -2.5
	var rusher := OpeningRusher.new()
	rusher.name = "OpeningRusher"
	rusher.scheduler = scheduler
	rusher.collision_layer = 2
	rusher.collision_mask = 1
	rusher.position = Vector3(-3, 0, 0)
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.27
	capsule.height = 1.1
	collision.shape = capsule
	collision.position.y = 0.555
	rusher.add_child(collision)
	arena.root.add_child(rusher)
	rusher.add_to_group("enemies")
	var wall := StaticBody3D.new()
	wall.name = "OpeningWall"
	wall.collision_layer = 1
	wall.collision_mask = 0
	var solid := CollisionShape3D.new()
	solid.name = "Solid"
	var box := BoxShape3D.new()
	box.size = Vector3(0.2, 2, 5)
	solid.shape = box
	wall.add_child(solid)
	arena.root.add_child(wall)
	wall.position = Vector3(-0.5, 1, 0)
	await _ticks(5)
	scheduler.begin_encounter("standard", "circle-rusher")
	var response: Dictionary = hero.get_threat_response_state()
	var context: Dictionary = World.context(arena, "circle-rusher")
	for key: String in context:
		if key != "encounter_id":
			response[key] = context[key]
	var role: Dictionary = Difficulty.new().resolve_role({"raw_damage": 4.0, "windup_s": 2.2, "lock_s": 1.1, "active_s": 0.5, "recovery_s": 1.6, "attack_interval_s": 2.1, "max_hp": 12.0, "move_speed": 8.0}, "standard", {"windup_s": 2.2, "lock_s": 1.1, "recovery_s": 1.6})
	var lunge: Dictionary = scheduler.request_lunge(rusher, {"role": role, "source_stationary": false, "opening_stationary": true, "cooldown_remaining_s": 0.0, "lunge": {"direction": Vector3.RIGHT, "speed": 8.0, "distance": 3.8, "damage_radius": 0.31}}, response)
	_expect(lunge.get("accepted", false) and lunge.reservation.adapter.collision_shortened, "combined fixture commits an actual wall-shortened rusher rather than a stationary opening proxy")
	if not lunge.get("accepted", false):
		print("Combined actual lunge diagnostic: ", lunge)
		await _dispose(arena)
		return
	await _until_clock(scheduler, scheduler.get_clock() + 0.2)
	var cycle_before: int = mechanism.state().cycle
	_expect(not mechanism.start("hero", context).get("accepted", false) and mechanism.state().cycle == cycle_before and scheduler.reservations().size() == 1, "arbitrary circle-source default cannot stand in for the actual rusher primary opening")
	for invalid: Variant in [Vector3(INF, 0, 0), "opening-proxy", {"opening_position": Vector3.ZERO}, Vector3(100, 0, 0)]:
		_expect(not mechanism.start("hero", context, invalid).get("accepted", false) and mechanism.state().cycle == cycle_before and scheduler.reservations().size() == 1, "malformed/unreachable per-cycle opening rejects before a second lease or cycle")
	var actual_opening: Vector3 = lunge.reservation.opening_position
	var answer: Dictionary = mechanism.start("hero", context, actual_opening)
	_expect(answer.get("accepted", false), "circle reserves a combined union with the real rusher's committed stopped endpoint as its opening")
	if not answer.get("accepted", false):
		print("Combined circle diagnostic: ", answer)
		await _dispose(arena)
		return
	_expect(mechanism.state().opening_position == actual_opening and answer.reservation.opening_position == actual_opening and actual_opening != mechanism.state().source_position and answer.proof.primary_time_s >= lunge.reservation.active_until_s and answer.proof.response_complete_s < lunge.reservation.recovery_until_s, "accepted cycle exposes actual distinct target endpoint with primary and full cooldown inside that rusher's recovery")
	var bindings: Dictionary = World.bindings(arena)
	bindings.owners["rusher"] = rusher
	await _ticks(4)
	paused = true
	await process_frame
	var pair: Dictionary = _exact_json({"hero": hero.snapshot_state(), "scheduler": scheduler.snapshot_state(bindings), "mechanism": mechanism.snapshot_state(bindings)})
	_expect(not pair.mechanism.is_empty() and pair.mechanism.configuration.opening_position == [0.0, 0.0, 0.0] and pair.mechanism.exchange.opening_position == Codec.vector3(actual_opening), "exact combined transport preserves configured legacy default and distinct accepted cycle opening without a new schema field")
	var cue_events: Array[String] = []
	mechanism.get_cue().state_changed.connect(func(value: Dictionary) -> void: cue_events.append(value.phase))
	var bad: Dictionary = pair.mechanism.duplicate(true)
	bad.exchange.opening_position = bad.configuration.opening_position.duplicate()
	_expect(_exact_reject_unchanged(mechanism, scheduler, bad, bindings), "paired combined snapshot rejects substitution of circle default for the actual accepted rusher opening")
	_expect(hero.restore_state(pair.hero) and scheduler.restore_state(pair.scheduler, bindings) and mechanism.restore_state(pair.mechanism, bindings) and cue_events.is_empty() and mechanism.state().opening_position == actual_opening, "same exact combined actor/scheduler/consumer pair restores quietly without rewriting its saved opening")
	paused = false
	for segment: Dictionary in answer.proof.path:
		if segment.kind in ["escape_dash", "positioning_dash"]:
			await _until_clock(scheduler, float(segment.start_s))
			_expect(hero.request_dash((segment["to"] - segment["from"]).normalized()), "actual actor performs the proved combined " + segment.kind)
	await _until_clock(scheduler, float(answer.proof.primary_time_s))
	var current: Dictionary = scheduler.reservation_state(String(lunge.reservation_id))
	_expect(not current.is_empty() and current.state == "recovery" and rusher.velocity == Vector3.ZERO and rusher.global_position.distance_to(actual_opening) <= 0.005 and current.adapter.actual_collided, "real source physically lands at the original shortened endpoint and is currently stopped in recovery")
	# Passive reload remains active; pin this test's public resource fixture to
	# zero immediately before the required ordinary-primary opening.
	hero.shells = 0
	_expect(hero.shells == 0 and hero.slash(rusher.global_position - hero.global_position) == 1 and rusher.hp == 0.0 and rusher.hits == 1, "zero-ammo ordinary primary hits that actual rusher during recovery without attacking the HP-free circle")
	mechanism.clear("actual_target_cleared")
	_expect(mechanism.get_cue().state().phase == "clear" and scheduler.reservations().is_empty(), "target-clear pair cleanup releases actual rusher and circle danger immediately")
	await _dispose(arena)


func _test_circle_union_budget() -> void:
	for profile: String in ["standard", "challenge", "assisted"]:
		var arena: Dictionary = _circle_arena()
		var first: CinderLaneMechanism = arena.mechanism
		var second: CinderLaneMechanism = _circle(arena, "impact-b", Vector3(1, 0, 0))
		var third: CinderLaneMechanism = _circle(arena, "impact-c", Vector3(-1, 0, 0))
		await _ticks(5)
		var scheduler: CinderThreatScheduler = arena.scheduler
		scheduler.begin_encounter(profile, "circle-budget-" + profile)
		var context: Dictionary = World.context(arena, "circle-budget-" + profile)
		var a: Dictionary = first.start("hero", context)
		_expect(a.get("accepted", false), profile + " first canonical circle obtains preparing budget")
		var simultaneous: Dictionary = second.start("hero", context)
		_expect(not simultaneous.get("accepted", false) and second.state().cycle == 0, profile + " simultaneous circle activation rejects without an invisible stagger bypass")
		await _until_clock(scheduler, scheduler.get_clock() + 0.2)
		var b: Dictionary = second.start("hero", context)
		_expect(bool(b.get("accepted", false)) == (profile != "assisted"), profile + " staggered circles obey the actual one/two shared preparing budget")
		if b.get("accepted", false):
			_expect(float(b.reservation.active_from_s) - float(a.reservation.active_from_s) >= 0.12, profile + " second circle retains a visible actual activation stagger")
			await _until_clock(scheduler, scheduler.get_clock() + 0.2)
			var c: Dictionary = third.start("hero", context)
			_expect(not c.get("accepted", false) and third.state().cycle == 0 and scheduler.reservations().size() == 2, profile + " third source cannot bypass the union budget")
			paused = true
			await process_frame
			var bindings: Dictionary = World.bindings(arena)
			bindings.owners["impact-b"] = second
			bindings.owners["impact-c"] = third
			var pair: Dictionary = _exact_json({"hero": arena.hero.snapshot_state(), "scheduler": scheduler.snapshot_state(bindings), "first": first.snapshot_state(bindings), "second": second.snapshot_state(bindings)})
			_expect(not pair.first.is_empty() and not pair.second.is_empty() and first.snapshot_error(pair.first, bindings, pair.scheduler).is_empty() and second.snapshot_error(pair.second, bindings, pair.scheduler).is_empty() and arena.hero.restore_state(pair.hero) and scheduler.restore_state(pair.scheduler, bindings) and first.restore_state(pair.first, bindings) and second.restore_state(pair.second, bindings), profile + " exact two-circle pair restores the original separate reservations and stagger")
			paused = false
		first.clear("union_exit")
		second.clear("union_exit")
		third.clear("union_exit")
		_expect(scheduler.reservations().is_empty() and first.get_cue().state().phase == "clear" and second.get_cue().state().phase == "clear", profile + " explicit union cleanup clears all required circle cues")
		await _dispose(arena)


func _circle_arena(raw: Dictionary = Mechanism.DEFAULT_RAW_ROLE) -> Dictionary:
	var arena: Dictionary = World.create(self, raw)
	arena.mechanism.free()
	arena["mechanism"] = _circle(arena, "loading-arm", Vector3.ZERO, raw)
	return arena


func _circle(arena: Dictionary, id: String, origin: Vector3, raw: Dictionary = Mechanism.DEFAULT_RAW_ROLE) -> CinderLaneMechanism:
	var result: CinderLaneMechanism = Mechanism.new()
	result.name = id.replace("-", "_")
	result.position = origin
	result.configure(id, Geometry.circle(origin, 0.3), Vector3.ZERO, raw)
	arena.root.add_child(result)
	result.bind(arena.scheduler, {"hero": arena.hero})
	return result


func _exact_json(value: Dictionary) -> Dictionary:
	var parsed: Dictionary = ExactJson.parse(ExactJson.stringify(value))
	_expect(parsed.get("accepted", false) and ExactJson.stringify(parsed.get("value", {})) == ExactJson.stringify(value), "pair survives exact tagged JSON including binary64 clock identity")
	return parsed.get("value", {})


func _exact_reject_unchanged(mechanism: CinderLaneMechanism, scheduler: CinderThreatScheduler, bad: Dictionary, bindings: Dictionary) -> bool:
	var before: String = ExactJson.stringify({"mechanism": mechanism.snapshot_state(bindings), "scheduler": scheduler.snapshot_state(bindings)})
	var phase: Dictionary = mechanism.get_cue().state()
	return not mechanism.restore_state(bad, bindings) and before == ExactJson.stringify({"mechanism": mechanism.snapshot_state(bindings), "scheduler": scheduler.snapshot_state(bindings)}) and mechanism.get_cue().state() == phase


func _adjacent_float(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes.encode_u64(0, bytes.decode_u64(0) + 1)
	return bytes.decode_double(0)


func _until_clock(scheduler: CinderThreatScheduler, deadline: float) -> void:
	while scheduler.get_clock() < deadline:
		await _ticks(1)


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
