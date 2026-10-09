extends SceneTree
## TMP TEST DRAFT ONLY. Root owns review/promotion/native queue execution.
## Actual two-owner B05 mechanics parent, native Hero/Heavy, one dry floor,
## one encounter epoch and one composite cue. No live HP/clock/transform/
## receipt/phase writes; geometry/loadout are authored before tree entry.
## Eligibility is a component signal. TEST_ONLY host acknowledges it directly;
## this does not create/prove a protected Shell checkpoint or Attempts history.
## Parent codec currently rejects. No Save/Continue/Fatal/whole-level/portrait/
## recognizer/aim/art/balance/performance acceptance from this fixture.
## Expected parent draft: d89967446d5786189cae1371a06934256fa901d6c2042bbc9dff6d10195ce26d.
const ParentScript: Script = preload("res://scripts/acts/act2/dead_london_sentry_encounter.gd")
const PlayerScript: Script = preload("res://scripts/player.gd")
const EffectsScript: Script = preload("res://scripts/effects.gd")
const SchedulerScript: Script = preload("res://scripts/combat/threat_scheduler.gd")
const BaitScript: Script = preload("res://scripts/acts/act2/dead_london_bait.gd")
const Geometry: Script = preload("res://scripts/combat/threat_geometry.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const MAX_TICKS: int = 900
const JOINT_AT: Vector3 = Vector3.ZERO
const FOOT_AT: Vector3 = Vector3.ZERO
const HERO_AT: Vector3 = Vector3(0, 0.02, 1.5)

class NativeTickProbe:
	extends Node
	signal tick_finished
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 120
	func _physics_process(_delta: float) -> void:
		tick_finished.emit()

var _checks: int = 0
var _failures: int = 0
var _fixtures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for profile: String in ["standard", "assisted"]:
		await _real_two_owner_route(profile)
	paused = false
	print("A2-L5 native Sentry parent mechanics smoke: %d checks, %d failures; real finite two-pool/one Foot introduction/earned eligibility/paired native recovery only; no portable checkpoint, whole level, recognizer, camera, balance or art credit" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _create(profile: String) -> Dictionary:
	_fixtures += 1
	var viewport := SubViewport.new()
	viewport.name = "TEST_ONLY_B05_%s_%d" % [profile, _fixtures]
	viewport.size = Vector2i(540, 1170)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	var world := Node3D.new()
	world.name = "NativeParentWorld"
	viewport.add_child(world)
	var floor := StaticBody3D.new()
	floor.name = "AuthoredDryFloor"
	floor.collision_layer = 1
	floor.collision_mask = 0
	floor.position = Vector3(0, -0.5, 0)
	var support := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	support.shape = box
	floor.add_child(support)
	world.add_child(floor)
	var effects: PixelEffects = EffectsScript.new()
	effects.name = "SharedEffects"
	world.add_child(effects)
	var hero: CinderPlayer = PlayerScript.new()
	hero.name = "SharedHero"
	hero.position = HERO_AT
	_expect(hero.equipment.equip("WEAPON-03"), profile + " authors canonical Heavy before Hero entry")
	hero.fx = effects
	world.add_child(hero)
	var scheduler: CinderThreatScheduler = SchedulerScript.new()
	scheduler.name = "OneSharedScheduler"
	world.add_child(scheduler)
	var encounter_id: String = "TEST:A2-L5:two-owner:" + profile
	_expect(scheduler.begin_encounter(profile, encounter_id, 1), profile + " begins exactly one native encounter")
	var bait: RefCounted = BaitScript.new()
	_expect(bool(bait.call("bind", hero)), profile + " binds actual ready Hero without a synthetic landing")
	var consumed: Array[bool] = []
	var action_callback: Callable = func(record: Dictionary) -> void: consumed.append(bool(bait.call("observe_record", record)))
	hero.world_action_executed.connect(action_callback)
	var region: Dictionary = {"collision": support, "safe_rect": Rect2(-9.998, -9.998, 19.996, 19.996)}
	var directions: Array[Vector3] = []
	for index: int in range(16): directions.append(Vector3(sin(float(index) * TAU / 16.0), 0, cos(float(index) * TAU / 16.0)).normalized())
	var context: Dictionary = {"encounter_id": encounter_id, "world_revision": 1, "recognition_s": 0.30, "attack_input_margin_s": 0.03, "escape_directions": directions.duplicate(), "return_directions": directions.duplicate(), "floor_regions": [region]}
	var parent: Node3D = ParentScript.new() as Node3D
	parent.name = "ActualB05MechanicsParent"
	world.add_child(parent)
	# TEST_ONLY physical binding guard. There is no camera or pixel proof here.
	var presentation_guard: Callable = func(proposed: Dictionary) -> bool:
		for key: String in ["actor", "ray_cue", "foot_cue", "foot_visual", "joint", "hero"]:
			var node: Variant = proposed.get(key)
			if not is_instance_valid(node) or not node.is_inside_tree() or not node.is_node_ready() or node.is_queued_for_deletion() or node.get_world_3d() != world.get_world_3d(): return false
		return true
	var configured: bool = bool(parent.call("configure", hero, effects, scheduler, bait, world, {"dry-floor": region}, context, JOINT_AT, FOOT_AT, presentation_guard))
	_expect(configured, profile + " configures actual persistent Ray and distinct Foot under one parent")
	var checkpoints: Array[Dictionary] = []
	var checkpoint_observations: Array[Dictionary] = []
	var clears: Array[Dictionary] = []
	var hits: Array[Dictionary] = []
	var failures: Array[String] = []
	var threshold_observations: Array[Dictionary] = []
	parent.connect("phase_checkpoint_eligible", func(receipts: Dictionary) -> void:
		checkpoints.append(receipts.duplicate(true))
		checkpoint_observations.append({"state": parent.call("state"), "response": hero.get_threat_response_state(), "action_in_progress": hero.action_in_progress(), "floor": Codec.vector3(Vector3(hero.global_position.x, 0, hero.global_position.z))})
	)
	parent.connect("sentry_cleared", func(receipts: Dictionary) -> void: clears.append(receipts.duplicate(true)))
	parent.connect("hit_resolved", func(id: String, result: Dictionary) -> void: hits.append({"source_id": id, "result": result.duplicate(true)}))
	parent.connect("runtime_failed", func(reason: String) -> void: failures.append(reason))
	if configured:
		parent.call("get_actor").connect("phase_boundary_reached", func(_id: String) -> void: threshold_observations.append(parent.call("state")))
	var probe := NativeTickProbe.new()
	probe.name = "TEST_OnlyNativeTickBarrier"
	world.add_child(probe)
	return {"profile": profile, "viewport": viewport, "world": world, "hero": hero, "effects": effects, "scheduler": scheduler, "bait": bait, "parent": parent, "probe": probe, "configured": configured, "encounter_id": encounter_id, "consumed": consumed, "action_callback": action_callback, "checkpoints": checkpoints, "checkpoint_observations": checkpoint_observations, "clears": clears, "hits": hits, "failures": failures, "threshold_observations": threshold_observations}

func _real_two_owner_route(profile: String) -> void:
	var fixture: Dictionary = _create(profile)
	if not fixture.configured:
		await _dispose(fixture)
		return
	var parent: Node3D = fixture.parent
	var hero: CinderPlayer = fixture.hero
	var scheduler: CinderThreatScheduler = fixture.scheduler
	var actor: Node3D = parent.call("get_actor")
	var ray: Node3D = parent.call("get_ray")
	var foot: CinderLaneMechanism = parent.call("get_foot")
	var joint: CinderInteractionCue = parent.call("get_joint_cue")
	var identities: Dictionary = {"actor": actor.get_instance_id(), "ray": ray.get_instance_id(), "foot": foot.get_instance_id(), "joint": joint.get_instance_id(), "ray_cue": ray.call("get_cue").get_instance_id(), "foot_cue": foot.get_cue().get_instance_id()}
	var owners: Dictionary = parent.call("owners")
	_expect(owners.size() == 2 and owners.get(ParentScript.SOURCE_ID) == actor and owners.get(ParentScript.FOOT_ID) == foot and actor != foot and ray.call("get_cue") != foot.get_cue(), profile + " retains two distinct actual owners and distinct threat cues with one composite joint cue")
	_expect(ParentScript.FOOT_ROLE.recovery_s == 2.4 and ParentScript.FOOT_FLOORS.recovery_s == 2.4 and ParentScript.FOOT_RADIUS == 1.10, profile + " uses explicit proposed Foot recovery2.4 and unchanged circle identity")
	_expect(scheduler.encounter_profile().reserved_threat_budget == (1 if profile == "assisted" else 2), profile + " uses real profile budget")
	_expect(Geometry.planar(HERO_AT).distance_to(Geometry.planar(JOINT_AT)) < hero.equipment.resolved_stats().primary_range and Geometry.planar(HERO_AT).distance_to(Geometry.planar(FOOT_AT)) > ParentScript.FOOT_RADIUS + SchedulerScript.CAPSULE_RADIUS + SchedulerScript.SKIN, profile + " authored initial point is noncoincident, Heavy-reachable and outside Foot capsule padding")
	if not _expect(await _until(fixture, func() -> bool: return _stable(hero)), profile + " earns supported native floor before start"):
		await _dispose(fixture)
		return
	var before_codec: Dictionary = parent.call("state")
	_expect(parent.call("snapshot_state", parent.call("bindings")).is_empty() and not String(parent.call("snapshot_error", {}, parent.call("bindings"))).is_empty() and not bool(parent.call("restore_state", {}, parent.call("bindings"))) and parent.call("state") == before_codec, profile + " deliberately incomplete whole-parent codec refuses without mutation or save authority")
	_expect(bool(parent.call("start")), profile + " starts only after actual stable floor and seeds real entry bait")
	if not _expect(await _until(fixture, func() -> bool: return ray.call("state").get("armed", false) and ray.call("state").get("proof_available", false)), profile + " first real Ray commits actual native admission/proof"):
		await _diagnose(fixture, "first Ray admission")
		return
	var first: Dictionary = ray.call("state")
	_expect(first.bait_sample.receipt == null and first.bait_sample.dash_sequence == 0 and first.bait_sample.point != JOINT_AT and first.exchange.adapter.lock_s == 1.10 and first.exchange.active_from_s == first.exchange.lock_from_s + first.exchange.adapter.lock_s, profile + " actual first ray samples noncoincident supported floor and original full lock")
	var first_proof: Dictionary = first.proof.duplicate(true)
	if not _expect(await _follow_motion_proof(fixture, first_proof, true, false), profile + " follows real first Ray escape/return and immediate public Heavy primary"):
		await _diagnose(fixture, "first Ray response")
		return
	var spent: Dictionary = parent.call("state")
	_expect(spent.actor_hp == 15.0 and spent.transition_pending and spent.boss_phase == 1 and spent.threshold.actual_hp_loss == 15.0 and spent.threshold.hp_before == 30.0 and spent.threshold.hp_after == 15.0 and spent.threshold.opening_receipt.kind == "isolated-ray", profile + " one real24damage Heavy strike clamps first finite pool to15 without refilling")
	_expect(fixture.threshold_observations.size() == 1 and fixture.threshold_observations[0].joint_cue.state == "spent" and fixture.threshold_observations[0].transition_pending and fixture.threshold_observations[0].ray.status == "cancelled" and fixture.threshold_observations[0].ray.last_cancel_reason == "b05_first_brace_spent", profile + " parent first observer spends cue and closes Ray before later threshold observers")
	_expect(spent.ray_introduction.closing == "cancelled" and spent.ray_introduction.last_cancel_reason == "b05_first_brace_spent" and not fixture.threshold_observations[0].foot_introduction_started and fixture.checkpoints.is_empty(), profile + " real Ray recovery introduction is cancelled at threshold and never relabelled complete")
	if not _expect(await _until(fixture, func() -> bool: return foot.state().status == "running" and _accepted_foot(parent.call("state"), "foot-introduction").size() == 1), profile + " pending brace permits exactly one distinct native Foot introduction"):
		await _diagnose(fixture, "Foot introduction admission")
		return
	var foot_entry: Dictionary = _accepted_foot(parent.call("state"), "foot-introduction")[0]
	_expect(foot_entry.proof.accepted and foot_entry.proof.uses_blast == false and foot_entry.proof.uses_invulnerability == false and joint.state().state == "spent" and actor.get("hp") == 15.0, profile + " Foot admission has real escape/return proof while pending brace stays spent")
	if not _expect(await _follow_motion_proof(fixture, foot_entry.proof, false, false), profile + " executes actual Foot escape/return and waits through its primary-sized hold without striking pending brace"):
		await _diagnose(fixture, "Foot introduction response")
		return
	if not _expect(await _until(fixture, func() -> bool: return fixture.checkpoints.size() == 1), profile + " complete native Foot receipt plus drained original Ray deadlines earns eligibility"):
		await _diagnose(fixture, "earned phase eligibility")
		return
	var checkpoint: Dictionary = fixture.checkpoints[0]
	var observed: Dictionary = fixture.checkpoint_observations[0]
	var current: Dictionary = parent.call("state")
	_expect(checkpoint.foot_introduction.closing == "complete" and checkpoint.foot_introduction.completed_clock_s > checkpoint.foot_introduction.exchange.recovery_until_s and checkpoint.ray_introduction.closing == "cancelled" and checkpoint.clock_s > checkpoint.ray_introduction.exchange.recovery_until_s and checkpoint.clock_s >= checkpoint.ray_introduction.exchange.cooldown_until_s, profile + " eligibility carries actual completed Foot and cancelled Ray original recovery/cooldown receipts")
	_expect(observed.response.stable and observed.response.motion.grounded and not observed.action_in_progress and observed.state.stage == "phase-two-checkpoint" and observed.state.actor_hp == 15.0 and observed.state.boss_phase == 2 and not observed.state.transition_pending and observed.state.checkpoint_notice_sent and observed.state.ray.status != "running" and observed.state.foot.status != "running", profile + " deferred eligibility publishes stable supported earned phase2 with both consumers drained")
	_expect(checkpoint.bait.boundary == "sentry-phase-2" and checkpoint.bait.initial_floor == observed.floor and checkpoint.bait.last_dash == null and fixture.clears.is_empty() and _accepted_foot(current, "foot-introduction").size() == 1, profile + " phase2 reseeds actual stable floor once without duplicated Foot or premature clear")
	var accepted_before: Array = current.accepted_cycles.duplicate(true)
	var clock_before: float = scheduler.get_clock()
	for _index: int in range(3): await _step(fixture)
	_expect(parent.call("state").accepted_cycles == accepted_before and scheduler.get_clock() > clock_before and fixture.checkpoints.size() == 1, profile + " eligibility holds admissions while original encounter clock continues")
	# TEST_ONLY host acknowledgment of component seam. No Shell save is created.
	_expect(bool(parent.call("resume_after_phase_checkpoint")) and not bool(parent.call("resume_after_phase_checkpoint")), profile + " explicit test host acknowledges eligibility once without resetting encounter")
	if not _expect(await _until(fixture, func() -> bool: return parent.call("state").pair.get("validated", false)), profile + " phase2 Foot-first stagger earns actual native joint-return proof"):
		await _diagnose(fixture, "paired admission and full recovery proof")
		return
	var pair: Dictionary = parent.call("state").pair.duplicate(true)
	var lower: float = maxf(pair.ray_exchange.active_until_s, pair.foot_exchange.active_until_s) + SchedulerScript.TIME_MARGIN
	var upper: float = minf(pair.ray_exchange.recovery_until_s, pair.foot_exchange.recovery_until_s) - SchedulerScript.TIME_MARGIN
	_expect(pair.proof.accepted and pair.proof.uses_blast == false and pair.proof.uses_invulnerability == false and pair.proof.primary_time_s >= lower and pair.proof.response_complete_s <= upper and pair.proof.response_complete_s == pair.proof.primary_time_s + hero.equipment.resolved_stats().primary_cooldown, profile + " accepted union proof fits ordinary primary and full cooldown inside BOTH actual recoveries")
	_expect(pair.ray_exchange.profile_id == profile and pair.foot_exchange.profile_id == profile and pair.ray_exchange.world_revision == 1 and pair.foot_exchange.world_revision == 1 and pair.ray_exchange.active_from_s > pair.foot_exchange.active_from_s, profile + " actual returned members preserve one world epoch and staggered activations")
	if profile == "assisted":
		_expect(pair.ray_exchange.start_s > pair.foot_exchange.active_until_s, "Assisted budget1 waits actual Foot active release while retaining Foot recovery")
	else:
		_expect(pair.ray_exchange.start_s >= pair.foot_exchange.lock_from_s, "Standard Ray admission follows actual Foot lock")
	_expect(not Geometry.timed_path_hits(pair.ray_exchange.geometry, pair.proof.path, pair.ray_exchange.active_from_s, pair.ray_exchange.active_until_s, SchedulerScript.CAPSULE_RADIUS + SchedulerScript.SKIN) and not Geometry.timed_path_hits(pair.foot_exchange.geometry, pair.proof.path, pair.foot_exchange.active_from_s, pair.foot_exchange.active_until_s, SchedulerScript.CAPSULE_RADIUS + SchedulerScript.SKIN), profile + " accepted native path clears actual Ray AND Foot footprints without blast or immunity")
	# First real paired cycle probes the live full-cadence cutoff. Let its
	# accepted native response reach the joint, then intentionally decline the
	# early opening; no pool/clock/pose is seeded for this negative gate check.
	if not _expect(await _follow_motion_proof(fixture, pair.proof, false, true), profile + " executes actual first paired escape/return while declining its early primary"):
		await _diagnose(fixture, "paired late-cadence physical setup")
		return
	var late_pair: Dictionary = pair.duplicate(true)
	var late_at: float = upper - float(hero.equipment.resolved_stats().primary_cooldown) + SchedulerScript.TIME_MARGIN
	if not _expect(await _wait_clock(fixture, late_at), profile + " waits actual paired cadence cutoff without changing any clock"):
		await _diagnose(fixture, "late cadence clock")
		return
	var late: Dictionary = parent.call("state")
	var sequence_before_late: int = _last_sequence(hero)
	_expect(late.ray.status == "running" and late.ray.phase == "recovery" and late.foot.status == "running" and late.foot.phase == "recovery" and late.joint_cue.state == "clear" and scheduler.get_clock() + hero.equipment.resolved_stats().primary_cooldown > upper and _stable(hero) and hero.get_threat_response_state().primary_cooldown_left_s == 0.0, profile + " actual late joint closes while BOTH genuine recoveries remain live")
	_expect(hero.slash(actor.global_position - hero.global_position) == 0 and _last_sequence(hero) == sequence_before_late + 1 and hero.get_world_action_records()[-1].kind == "primary" and parent.call("state").actor_hp == 15.0 and fixture.clears.is_empty(), profile + " late public Heavy primary publishes real zero accepted damage and cannot consume remaining pool")
	if not _expect(await _until(fixture, func() -> bool:
		var next: Dictionary = parent.call("state").pair
		return next.get("validated", false) and int(next.foot_cycle) > int(late_pair.foot_cycle) and int(next.ray_cycle) > int(late_pair.ray_cycle)
	), profile + " naturally finished declined pair permits next real persistent Foot/Ray cycle"):
		await _diagnose(fixture, "fresh pair after genuine late refusal")
		return
	pair = parent.call("state").pair.duplicate(true)
	lower = maxf(pair.ray_exchange.active_until_s, pair.foot_exchange.active_until_s) + SchedulerScript.TIME_MARGIN
	upper = minf(pair.ray_exchange.recovery_until_s, pair.foot_exchange.recovery_until_s) - SchedulerScript.TIME_MARGIN
	_expect(pair.ray_exchange.id != late_pair.ray_exchange.id and pair.foot_exchange.id != late_pair.foot_exchange.id and pair.proof.accepted and pair.proof.uses_blast == false and pair.proof.uses_invulnerability == false and pair.proof.primary_time_s >= lower and pair.proof.response_complete_s <= upper and pair.proof.response_complete_s == pair.proof.primary_time_s + hero.equipment.resolved_stats().primary_cooldown, profile + " fresh real pair earns new exact union proof with full ordinary-primary cadence")
	if not _expect(await _follow_motion_proof(fixture, pair.proof, true, true), profile + " actual native paired escape/return reaches BOTH recoveries for public Heavy defeat"):
		await _diagnose(fixture, "paired physical response")
		return
	if not _expect(await _until(fixture, func() -> bool: return fixture.clears.size() == 1), profile + " deferred real finite-pool clear publishes once"):
		await _diagnose(fixture, "earned clear publication")
		return
	var cleared: Dictionary = parent.call("state")
	_expect(cleared.actor_hp == 0.0 and cleared.boss_phase == 2 and not cleared.transition_pending and cleared.stage == "cleared" and cleared.joint_cue.state == "spent" and fixture.clears[0].hp == 0.0 and fixture.clears[0].defeat.hp_before == 15.0 and fixture.clears[0].defeat.hp_after == 0.0 and fixture.clears[0].defeat.opening_receipt.kind == "paired", profile + " second real24damage Heavy primary consumes only remaining15HP and records paired gate")
	_expect(identities == {"actor": actor.get_instance_id(), "ray": ray.get_instance_id(), "foot": foot.get_instance_id(), "joint": joint.get_instance_id(), "ray_cue": ray.call("get_cue").get_instance_id(), "foot_cue": foot.get_cue().get_instance_id()}, profile + " phase boundary and defeat preserve persistent source/cue identities")
	var ray_control: Dictionary = scheduler.source_control_state(actor)
	var foot_control: Dictionary = scheduler.source_control_state(foot)
	_expect(ray_control.encounter_id == fixture.encounter_id and foot_control.encounter_id == fixture.encounter_id and ray_control.world_revision == 1 and foot_control.world_revision == 1 and ray_control.reservations.is_empty() and foot_control.reservations.is_empty() and ray_control.cooldown == null and foot_control.cooldown.ready_s == pair.foot_exchange.cooldown_until_s, profile + " real source defeat retires Ray owner cooldown and ordinary Foot cancellation retains its original cooldown in the same epoch")
	_expect(hero.hp == 100.0 and fixture.hits.is_empty() and fixture.failures.is_empty() and cleared.runtime_error.is_empty() and fixture.consumed.size() == hero.get_world_action_records().size() and not fixture.consumed.has(false), profile + " actual native paths create no exposure opportunity or fabricated hurt and consume only real published actions")
	for _index: int in range(4): await _step(fixture)
	_expect(fixture.checkpoints.size() == 1 and fixture.clears.size() == 1 and parent.call("state").actor_hp == 0.0 and _accepted_foot(parent.call("state"), "foot-introduction").size() == 1, profile + " continued ticks cannot repeat introduction, phase eligibility or clear")
	await _dispose(fixture)

func _follow_motion_proof(fixture: Dictionary, proof: Dictionary, strike: bool, paired: bool) -> bool:
	if not proof.get("accepted", false) or not proof.get("path") is Array: return false
	var hero: CinderPlayer = fixture.hero
	var parent: Node3D = fixture.parent
	var scheduler: CinderThreatScheduler = fixture.scheduler
	var kinds: Array[String] = []
	for segment: Dictionary in proof.path: kinds.append(String(segment.kind))
	if not _expect(kinds.has("escape_dash") and kinds.has("positioning_dash") and kinds.has("ordinary_primary"), fixture.profile + " selected actual proof explicitly contains escape, return and ordinary-primary hold"): return false
	for segment: Dictionary in proof.path:
		if not await _wait_clock(fixture, float(segment.start_s)): return false
		if String(segment.kind) in ["escape_dash", "positioning_dash"]:
			if not _expect(scheduler.get_clock() < float(segment.end_s) and _stable(hero) and hero.get_threat_response_state().dash_cooldown_left_s == 0.0, fixture.profile + " actual proof dash starts during its genuine allotted interval with native readiness"): return false
			var before_sequence: int = _last_sequence(hero)
			var direction: Vector3 = (segment["to"] - segment["from"]).normalized()
			if not _expect(hero.request_dash(direction), fixture.profile + " public native dash accepts actual proof direction"): return false
			if not await _until(fixture, func() -> bool: return _last_sequence(hero) > before_sequence and _stable(hero)): return false
			var actual: Dictionary = hero.get_world_action_records()[-1]
			if not _expect(actual.kind == "dash" and not actual.blocked and not actual.collision_shortened and actual.distance > 0.0 and fixture.bait.call("sample_for_ray").dash_sequence == actual.sequence, fixture.profile + " proof movement finishes as actual completed physical dash receipt in bound bait"): return false
		elif String(segment.kind) == "ordinary_primary":
			if strike:
				var state: Dictionary = parent.call("state")
				var actor: Node3D = parent.call("get_actor")
				var joint: CinderInteractionCue = parent.call("get_joint_cue")
				if not _expect(_stable(hero) and hero.get_threat_response_state().primary_cooldown_left_s == 0.0 and joint.state().state == "available" and state.ray.phase == "recovery" and state.ray.status == "running" and (not paired or state.foot.phase == "recovery" and state.foot.status == "running"), fixture.profile + " real primary occurs only with actual native readiness and required recovery cues"): return false
				var upper: float = float(state.ray.exchange.recovery_until_s) - SchedulerScript.TIME_MARGIN
				if paired: upper = minf(upper, float(state.pair.foot_exchange.recovery_until_s) - SchedulerScript.TIME_MARGIN)
				var actual_finish: float = scheduler.get_clock() + float(hero.equipment.resolved_stats().primary_cooldown)
				if not _expect(actual_finish <= upper and Geometry.planar(hero.global_position).distance_to(Geometry.planar(actor.global_position)) < float(hero.equipment.resolved_stats().primary_range), fixture.profile + " actual strike placement and full actual primary cooldown fit committed recovery deadlines"): return false
				if not _expect(hero.slash(actor.global_position - hero.global_position) == 1, fixture.profile + " immediate public Heavy primary hits exactly the native low joint"): return false
				if not await _wait_clock(fixture, actual_finish): return false
			else:
				var state: Dictionary = parent.call("state")
				if paired:
					if not _expect(not state.transition_pending and state.boss_phase == 2 and state.actor_hp == 15.0 and state.ray.status == "running" and state.ray.phase == "recovery" and state.foot.status == "running" and state.foot.phase == "recovery" and state.joint_cue.state == "available", fixture.profile + " declined paired proof reaches actual early joint return and preserves remaining pool"): return false
				elif not _expect(state.transition_pending and state.actor_hp == 15.0 and state.joint_cue.state == "spent", fixture.profile + " Foot proof hold leaves finite pending brace untouched"): return false
				if not await _wait_clock(fixture, float(segment.end_s)): return false
		else:
			if not await _wait_clock(fixture, float(segment.end_s)): return false
	return fixture.failures.is_empty() and String(parent.call("state").runtime_error).is_empty()

func _accepted_foot(state: Dictionary, stage: String) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for record: Dictionary in state.accepted_cycles:
		if record.kind == "foot" and record.stage == stage: records.append(record.duplicate(true))
	return records

func _last_sequence(hero: CinderPlayer) -> int:
	var records: Array[Dictionary] = hero.get_world_action_records()
	return 0 if records.is_empty() else int(records[-1].sequence)

func _stable(hero: CinderPlayer) -> bool:
	var response: Dictionary = hero.get_threat_response_state()
	return response.stable and response.motion.grounded and not hero.action_in_progress()

func _wait_clock(fixture: Dictionary, target: float) -> bool:
	if not is_finite(target): return false
	return await _until(fixture, func() -> bool: return fixture.scheduler.get_clock() >= target)

func _until(fixture: Dictionary, predicate: Callable) -> bool:
	for _index: int in range(MAX_TICKS):
		if bool(predicate.call()): return true
		if not fixture.failures.is_empty() or not String(fixture.parent.call("state").runtime_error).is_empty() or fixture.hero.dead: return false
		await _step(fixture)
	return false

func _step(fixture: Dictionary) -> void:
	await (fixture.probe as NativeTickProbe).tick_finished
	await process_frame

func _diagnose(fixture: Dictionary, stage: String) -> void:
	push_error("B05 component fixture stopped at %s for %s: %s" % [stage, fixture.profile, str(fixture.parent.call("state"))])
	await _dispose(fixture)

func _dispose(fixture: Dictionary) -> void:
	var parent: Node3D = fixture.parent
	var hero: CinderPlayer = fixture.hero
	var refs: Array[WeakRef] = [weakref(fixture.world), weakref(hero), weakref(parent), weakref(fixture.scheduler)]
	if fixture.configured:
		for node: Variant in [parent.call("get_actor"), parent.call("get_ray"), parent.call("get_foot"), parent.call("get_joint_cue"), parent.call("get_ray").call("get_cue"), parent.call("get_foot").get_cue()]: refs.append(weakref(node))
		parent.call("cleanup")
		_expect(not bool(parent.call("start")) and not bool(parent.call("resume_after_phase_checkpoint")) and parent.call("owners").is_empty() and parent.call("snapshot_state").is_empty(), fixture.profile + " cleanup permanently closes parent admissions and codec authority")
	fixture.bait.call("release")
	if hero.world_action_executed.is_connected(fixture.action_callback): hero.world_action_executed.disconnect(fixture.action_callback)
	fixture.scheduler.end_encounter("test_whole_parent_disposal")
	fixture.viewport.queue_free()
	await process_frame
	await process_frame
	for ref: WeakRef in refs: _expect(ref.get_ref() == null, fixture.profile + " whole native parent/source/cue/controller world disposes")
	paused = false

func _expect(condition: bool, description: String) -> bool:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)
	return condition
