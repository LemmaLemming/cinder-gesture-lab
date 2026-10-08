extends SceneTree
## Actual A1-L1 preview progression and shared finite-lane transport. Explicit
## staging skips travel only; campaign aggregate retry/portrait proof are separate.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const LevelPath: String = "res://scenes/acts/act1/a1_l1.tscn"
const Geometry: GDScript = preload("res://scripts/combat/threat_geometry.gd")
const ExactJson: GDScript = preload("res://scripts/campaign/exact_json.gd")
const ARM_IDS: Array[String] = ["a1_l1_roof_arm", "a1_l1_boarding_arm"]
const EXERCISES: Array[String] = ["first-dash", "release-point", "workshop-approach", "loading-arm", "boarding-rehearsal"]
const PROOF_KITS: Array[Dictionary] = [
	{"label": "neutral", "ids": ["CLOTH-J0", "CLOTH-P0", "CLOTH-S0", "WEAPON-01"], "speed": 15.0, "distance": 2.7, "reach": 2.0, "primary": 0.3},
	{"label": "slowest-longest-shortest", "ids": ["CLOTH-J1", "CLOTH-P2", "CLOTH-S2", "WEAPON-03"], "speed": 13.5, "distance": 2.97, "reach": 1.8, "primary": 0.4},
	{"label": "slowest-primary", "ids": ["CLOTH-J1", "CLOTH-P1", "CLOTH-S2", "WEAPON-03"], "speed": 14.25, "distance": 2.97, "reach": 1.9, "primary": 0.3 / 0.7},
	{"label": "fastest-short-dash", "ids": ["CLOTH-J0", "CLOTH-P0", "CLOTH-S1", "WEAPON-02"], "speed": 16.5, "distance": 2.7, "reach": 1.9, "primary": 0.3 / 1.15},
]

var _checks: int = 0
var _failures: int = 0
var _finished: bool = false
var _phases: Array[String] = []
var _hits: Array[Dictionary] = []
var _progress: Array[String] = []
var _cue_events: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(60.0, true).timeout.connect(_watchdog)
	await _test_progression()
	await _test_extreme_witnesses()
	_finished = true
	print("A1-L1 arm preview: %d checks, %d failures" % [_checks, _failures])
	print("STAGED: labelled floor positions skip traversal. NOT TESTED: campaign aggregate retry/transition, all-loadout fairness or portrait arm composition.")
	quit(0 if _failures == 0 else 1)


func _test_progression() -> void:
	var fixture: Dictionary = _fixture()
	if fixture.is_empty():
		return
	var level: CinderLevel = fixture.level
	var hero: CinderPlayer = fixture.hero
	var scheduler: CinderThreatScheduler = level.get("scheduler") as CinderThreatScheduler
	var arms: Dictionary = level.get("arms")
	var roof: CinderLaneMechanism = arms[ARM_IDS[0]] as CinderLaneMechanism
	var boarding: CinderLaneMechanism = arms[ARM_IDS[1]] as CinderLaneMechanism
	for id: String in ARM_IDS:
		var observed_id: String = id
		var arm: CinderLaneMechanism = arms[id] as CinderLaneMechanism
		arm.state_changed.connect(func(state: Dictionary) -> void: _phases.append(observed_id + ":" + state.phase))
		arm.hit_resolved.connect(func(actor_id: String, cycle: int, result: Dictionary) -> void: _hits.append({"arm": observed_id, "hero": actor_id, "cycle": cycle, "result": result.duplicate(true)}))
		arm.get_cue().state_changed.connect(func(state: Dictionary) -> void: _cue_events.append(observed_id + ":" + state.phase))
	level.checkpoint_requested.connect(func(_id: String, checkpoint: String, _kind: String) -> void: _progress.append(checkpoint))
	level.completion_requested.connect(func(_id: String, completion: String) -> void: _progress.append(completion))
	level.contact_exit_requested.connect(func(_id: String, exit_id: String) -> void: _progress.append(exit_id))
	if not await _opening(fixture):
		await _dispose(fixture)
		return
	_expect(roof.state().cycle == 0 and boarding.state().cycle == 0 and scheduler.reservations().is_empty(), "genuine opening reaches roof with no fabricated arm cycle")
	_stage(hero, Vector3(1.4, 0.1, -6.0), "first roof demonstration outside the full padded lane")
	if not await _require_phase(roof, "warning", "broad side approach starts the real first roof warning"):
		await _dispose(fixture)
		return
	_expect(not Geometry.segment_hits(roof.state().geometry, hero.global_position, hero.global_position, CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN) and roof.state().cycle == 1, "first warning is an empty-space preview beyond the actual source footprint")
	_expect(roof.get_cue().state().geometry == roof.state().geometry and roof.get_cue().state().phase == "warning" and not roof.is_in_group("enemies"), "shared cue retains the committed finite source lane without enemy classification")
	await _test_warning_transport(level, hero, roof)
	var hp_before: float = hero.hp
	if not await _require_phase(roof, "lock", "empty preview reaches real lock"):
		await _dispose(fixture)
		return
	_expect(hero.hp == hp_before and _hits.is_empty(), "warning and lock never deal early damage")
	if not await _require_phase(roof, "active", "empty preview reaches real active"):
		await _dispose(fixture)
		return
	_expect(hero.hp == hp_before and _hits.is_empty(), "empty first active swing causes no invented injury")
	if not await _require_phase(roof, "recovery", "empty preview exposes the real recovery opening"):
		await _dispose(fixture)
		return
	_stage(hero, Vector3(3.1, 0.1, -6.0), "outside the authored approach to observe finite cycle completion")
	if not await _require_phase(roof, "clear", "empty preview finishes its full recovery"):
		await _dispose(fixture)
		return
	_expect(roof.state().status == "complete" and roof.state().cycle == 1 and scheduler.reservations().is_empty() and _beat(level) == 3 and _hits.is_empty(), "time and empty swings cannot clear the roof target or advance an exercise")
	_expect(_phases.slice(0, 5) == [ARM_IDS[0] + ":warning", ARM_IDS[0] + ":lock", ARM_IDS[0] + ":active", ARM_IDS[0] + ":recovery", ARM_IDS[0] + ":clear"], "actual first swing follows warning-lock-active-recovery-clear exactly")

	_stage(hero, Vector3(0.0, 0.1, -6.0), "second roof swing deliberately exposes the hero to the real lane")
	if not await _require_phase(roof, "warning", "a later stable approach permits a new real roof cycle"):
		await _dispose(fixture)
		return
	hp_before = hero.hp
	var expected_loss: float = hero.equipment.damage_received(4.0)
	if not await _require_phase(roof, "active", "second roof cycle enters active"):
		await _dispose(fixture)
		return
	_expect(_hits.size() == 1 and _near(hero.hp, hp_before - expected_loss) and _hits[0].cycle == 2 and _hits[0].hero == "hero" and _hits[0].result.opportunity_consumed and _near(_hits[0].result.hp_damage, expected_loss), "real padded-lane exposure consumes one shared environmental hit through armor")
	if _hits.size() != 1:
		await _dispose(fixture)
		return
	_expect(_hits[0].result.impulse == Vector3.ZERO and roof.state().hit_ids == ["hero"], "loading arm applies zero impulse and retains stable per-cycle hit dedupe")
	if not await _require_phase(roof, "recovery", "injured roof cycle reaches ordinary attack recovery"):
		await _dispose(fixture)
		return
	_expect(_hits.size() == 1, "standing through the full active interval cannot duplicate the consumed hit")
	# The authored cloth is farther to the side for player visibility. This
	# actual ordinary diagonal keeps a useful primary margin from lane centre.
	_expect(hero.request_dash(Vector3(0.8, 0.0, 0.6)), "real diagonal dash leaves the roof lane for a useful primary landing")
	await _ticks(2)
	await _test_mid_dash_capture(level, hero, roof)
	await create_timer(0.4).timeout
	var roof_target: PracticeTarget = (level.get("targets") as Dictionary)["roof"] as PracticeTarget
	var records: Array[Dictionary] = hero.get_world_action_records()
	_expect(not records.is_empty() and records[-1].kind == "dash" and hero.global_position.distance_to(roof_target.global_position) < hero.equipment.resolved_stats().primary_range and _beat(level) == 3, "real completed diagonal landing remains in ordinary reach without granting progress")
	hero.shells = 0
	_expect(hero.slash(roof_target.global_position - hero.global_position) == 1 and hero.shells == 0 and roof_target.hp == 0.0 and _beat(level) == 4, "zero-ammo ordinary primary clears roof and advances immediately")
	_expect(roof.state().status == "cancelled" and roof.state().last_cancel_reason == "target_cleared" and roof.get_cue().state().phase == "clear" and scheduler.reservations().is_empty(), "target clear cancels its real danger before the next checkpoint boundary")

	_stage(hero, Vector3(1.4, 0.1, -12.0), "broad boarding side approach after real roof clear")
	if not await _require_phase(boarding, "warning", "boarding lesson starts its own empty first warning"):
		await _dispose(fixture)
		return
	_expect(boarding.state().cycle == 1 and _beat(level) == 4 and not level.is_completed(), "boarding target cannot be skipped merely by waiting or entering its preview")
	var hatch_cue: CinderInteractionCue = level.get("hatch_cue") as CinderInteractionCue
	_expect(hatch_cue.state().state == "clear" and not level.request_contact_exit("capsule-hatch", hero), "actual hatch remains unavailable before final target clear")
	_expect(hero.request_dash(Vector3(0.6, 0.0, 0.8)), "real boarding diagonal reaches its ordinary attack pocket")
	await create_timer(0.4).timeout
	var finale: PracticeTarget = (level.get("targets") as Dictionary)["finale"] as PracticeTarget
	hero.shells = 0
	_expect(hero.slash(finale.global_position - hero.global_position) == 1 and hero.shells == 0 and _beat(level) == 5 and level.is_completed(), "final zero-ammo genuine primary completes all five authored exercises synchronously")
	_expect(boarding.state().status == "cancelled" and scheduler.reservations().is_empty() and _progress == EXERCISES.slice(0, 4) + ["launch-rehearsal-clear"], "final clear cancels danger and emits four checkpoints plus one completion without a premature final checkpoint")
	paused = true
	await process_frame
	var completed: Dictionary = level.snapshot_state()
	_expect(not completed.is_empty() and completed.progress.completed and completed.progress.checkpoint_id == "loading-arm" and completed.progress.checkpoint_ids.size() == 4 and completed.local.completed_exercises == EXERCISES, "completed local v3 capture preserves all exercises and the valid pre-completion checkpoint prefix")
	_expect(hatch_cue.state().state == "available" and hatch_cue.state().trigger == "contact", "completed hatch uses the distinct available contact cue")
	var foreign := Node3D.new()
	root.add_child(foreign)
	_expect(not level.request_contact_exit("capsule-hatch", foreign) and not level.request_contact_exit("wrong-hatch", hero) and not level.request_contact_exit("capsule-hatch", hero), "completed hatch still rejects a foreign actor, wrong ID and remote hero")
	foreign.queue_free()
	paused = false
	await create_timer(0.5).timeout
	_stage(hero, Vector3(0.0, 0.1, -10.8), "physical approach before a real swipe into the hatch contact")
	await _ticks(3)
	_expect(hero.request_dash(Vector3.FORWARD), "shared swipe dash genuinely travels into the capsule contact")
	await create_timer(0.4).timeout
	_expect((level.get("hatch") as Area3D).overlaps_body(hero) and _progress.count("capsule-hatch") == 1, "actual hero overlap triggers exactly one completed contact exit")
	_expect(not level.request_contact_exit("capsule-hatch", hero) and _progress.count("capsule-hatch") == 1, "repeated contact cannot duplicate the exit")
	await _dispose(fixture)


func _test_warning_transport(level: CinderLevel, hero: CinderPlayer, arm: CinderLaneMechanism) -> void:
	paused = true
	await process_frame
	var saved: Dictionary = level.snapshot_state()
	var actor: Dictionary = hero.snapshot_state()
	_expect(not saved.is_empty() and not actor.is_empty() and saved.local_snapshot_version == 3 and saved.local.size() == 5 and saved.local.arms[ARM_IDS[0]].hero_samples.hero.position == actor.motion.position, "paused v3 capture pairs actual actor position with scheduler and both arms")
	if saved.is_empty() or actor.is_empty():
		paused = false
		return
	# Transport the complete actual pair together; exact reservation/sample
	# clocks are not allowed to pass through a decimal float reconstruction.
	var pair_text: String = ExactJson.stringify({"player": actor, "level": saved})
	var decoded_pair: Dictionary = ExactJson.parse(pair_text)
	var pair_accepted: bool = not pair_text.is_empty() and decoded_pair.get("accepted", false) and decoded_pair.get("value") is Dictionary and ExactJson.stringify(decoded_pair.value) == pair_text
	_expect(pair_accepted, "paused real warning pair round-trips exact scalar bits and native types through the published transport")
	if not pair_accepted:
		paused = false
		return
	var transported: Dictionary = decoded_pair.value
	var clock: float = (level.get("scheduler") as CinderThreatScheduler).get_clock()
	var action_clock: float = hero.get_world_action_clock()
	var counts: Array[int] = [_phases.size(), _hits.size(), _cue_events.size(), _progress.size()]
	_expect(hero.snapshot_error(transported.player).is_empty() and level.snapshot_error_with_player(transported.level, transported.player).is_empty() and hero.restore_state(transported.player) and level.restore_state(transported.level) and level.snapshot_state() == saved and hero.snapshot_state() == actor and counts == [_phases.size(), _hits.size(), _cue_events.size(), _progress.size()], "same-actor coherent warning restore is exact and silent with no resource or clock refresh")
	await create_timer(0.08, true).timeout
	_expect(level.snapshot_state() == saved and hero.snapshot_state() == actor and arm.get_cue().state().phase == "warning" and (level.get("scheduler") as CinderThreatScheduler).get_clock() == clock and hero.get_world_action_clock() == action_clock, "pause freezes action clock, shared warning clocks, samples and resources together")
	_expect(not arm.start("hero", level.call("arm_response_context")).get("accepted", false), "paused calls cannot allocate another arm cycle")
	for kind: String in ["clock", "phase", "sample", "dedupe", "reservation", "geometry", "future", "missing"]:
		var bad: Dictionary = saved.duplicate(true)
		match kind:
			"clock": bad.local.scheduler.clock_s += 0.1
			"phase": bad.local.arms[ARM_IDS[0]].phase = "active"
			"sample": bad.local.arms[ARM_IDS[0]].hero_samples.hero.position[0] += 0.5
			"dedupe": bad.local.arms[ARM_IDS[0]].hit_ids = ["hero", "hero"]
			"reservation": bad.local.scheduler.reservations = []
			"geometry": bad.local.arms[ARM_IDS[0]].exchange.geometry.radius += 0.1
			"future": bad.local.arms[ARM_IDS[1]].status = "running"
			"missing": bad.local.arms.erase(ARM_IDS[1])
		_expect(not level.restore_state(bad) and not level.last_snapshot_error.is_empty() and level.snapshot_state() == saved and hero.snapshot_state() == actor and counts == [_phases.size(), _hits.size(), _cue_events.size(), _progress.size()], "invalid paired " + kind + " rejects before actor/local/cue/progression commit")
	_expect(hero.snapshot_error(actor).is_empty() and level.snapshot_error_with_player(saved, actor).is_empty() and level.snapshot_state() == saved and hero.snapshot_state() == actor and counts == [_phases.size(), _hits.size(), _cue_events.size(), _progress.size()], "public validated-player context accepts the coherent pair without actor/local/event mutation")
	for kind: String in ["completion", "unknown-boundary", "older-boundary", "local-v2"]:
		var bad: Dictionary = saved.duplicate(true)
		match kind:
			"completion":
				bad.progress.completed = true
				bad.progress.completion_id = "launch-rehearsal-clear"
			"unknown-boundary":
				bad.progress.checkpoint_ids["unknown-boundary"] = "encounter"
				bad.progress.checkpoint_id = "unknown-boundary"
				bad.progress.checkpoint_kind = "encounter"
			"older-boundary":
				bad.progress.checkpoint_id = "first-dash"
				bad.progress.checkpoint_kind = "encounter"
			"local-v2": bad.local_snapshot_version = 2
		var input_before: Dictionary = bad.duplicate(true)
		_expect(not level.snapshot_error(bad).is_empty() and not level.snapshot_error_with_player(bad, actor).is_empty() and bad == input_before and level.snapshot_state() == saved and hero.snapshot_state() == actor and counts == [_phases.size(), _hits.size(), _cue_events.size(), _progress.size()], "public live/player-context validation both reject " + kind + " without input, actor, local or event mutation")

	# Break one actual binding at a time. Observe public simulation/cue state
	# without querying/pruning scheduler reservations while its floor is absent.
	var scheduler: CinderThreatScheduler = level.get("scheduler") as CinderThreatScheduler
	var hatch: Area3D = level.get("hatch") as Area3D
	var hatch_shape: CollisionShape3D = hatch.get_node("BroadBoardingContact") as CollisionShape3D
	var hatch_box: BoxShape3D = hatch_shape.shape as BoxShape3D
	var hatch_cue: CinderInteractionCue = level.get("hatch_cue") as CinderInteractionCue
	var source_art: Node3D = (level.get("arm_visuals") as Dictionary)[ARM_IDS[0]] as Node3D
	var floor: StaticBody3D = level.get_node("Floor") as StaticBody3D
	var observe: Callable = func() -> Dictionary:
		var arm_states: Dictionary = {}
		var target_states: Dictionary = {}
		var arms: Dictionary = level.get("arms")
		var targets: Dictionary = level.get("targets")
		for id: String in ARM_IDS:
			var observed_arm: CinderLaneMechanism = arms[id] as CinderLaneMechanism
			arm_states[id] = {"state": observed_arm.state(), "cue": observed_arm.get_cue().state()}
		for id: String in ["hall", "workshop", "roof", "finale"]:
			var target: PracticeTarget = targets[id] as PracticeTarget
			target_states[id] = {"hp": target.hp, "active": target.is_in_group("practice_targets"), "feedback": target.hit_feedback_left()}
		return {"actor": hero.snapshot_state(), "beat": _beat(level), "completed": (level.get("completed_exercises") as Array).duplicate(), "clock": scheduler.get_clock(), "profile": scheduler.encounter_profile(), "arms": arm_states, "targets": target_states, "hatch_cue": hatch_cue.state()}
	for kind: String in ["disabled-hatch", "moved-hatch", "resized-hatch", "missing-hatch-cue", "missing-source-art", "missing-floor"]:
		var before: Dictionary = observe.call()
		var hatch_transform: Transform3D = hatch.transform
		var hatch_size: Vector3 = hatch_box.size
		var was_disabled: bool = hatch_shape.disabled
		var detached: Node
		var original_parent: Node
		var original_index: int = -1
		match kind:
			"disabled-hatch": hatch_shape.disabled = true
			"moved-hatch": hatch.position += Vector3.RIGHT
			"resized-hatch": hatch_box.size.x += 0.2
			"missing-hatch-cue": detached = hatch_cue
			"missing-source-art": detached = source_art
			"missing-floor": detached = floor
		if detached != null:
			original_parent = detached.get_parent()
			original_index = detached.get_index()
			original_parent.remove_child(detached)
		var live_error: String = level.snapshot_error(saved)
		var staged_error: String = level.snapshot_error_with_player(saved, actor)
		var rejected: bool = not level.restore_state(saved)
		_expect(not live_error.is_empty() and not staged_error.is_empty() and rejected and not level.last_snapshot_error.is_empty() and observe.call() == before and counts == [_phases.size(), _hits.size(), _cue_events.size(), _progress.size()], "invalid runtime " + kind + " rejects live/context/restore before actor, simulation, cue or progress mutation")
		# Restore the same actual nodes/resource/transform synchronously while
		# paused; never recreate bodies, advance a tick or restore the actor.
		hatch_shape.disabled = was_disabled
		hatch.transform = hatch_transform
		hatch_box.size = hatch_size
		if detached != null:
			original_parent.add_child(detached)
			original_parent.move_child(detached, original_index)
		_expect(level.snapshot_state() == saved and hero.snapshot_state() == actor and counts == [_phases.size(), _hits.size(), _cue_events.size(), _progress.size()], "restoring original " + kind + " bindings recovers the exact saved pair without a new cycle/event")
	paused = false


func _test_mid_dash_capture(level: CinderLevel, hero: CinderPlayer, arm: CinderLaneMechanism) -> void:
	paused = true
	await process_frame
	var actor: Dictionary = hero.snapshot_state()
	var saved: Dictionary = level.snapshot_state()
	_expect(not actor.is_empty() and not saved.is_empty() and actor.clocks.dash_left_s > 0.0 and saved.local.arms[ARM_IDS[0]].hero_samples.hero.position == actor.motion.position and saved.local.arms[ARM_IDS[0]].clock_s == saved.local.scheduler.clock_s, "manual paused barrier retains an actual unfinished dash and the matching completed arm/scheduler tick")
	if not saved.is_empty() and not actor.is_empty():
		var pair_text: String = ExactJson.stringify({"player": actor, "level": saved})
		var decoded_pair: Dictionary = ExactJson.parse(pair_text)
		var pair_accepted: bool = not pair_text.is_empty() and decoded_pair.get("accepted", false) and decoded_pair.get("value") is Dictionary and ExactJson.stringify(decoded_pair.value) == pair_text
		_expect(pair_accepted, "paused actual unfinished dash and arm/scheduler pair round-trip exact scalar bits and native types")
		if not pair_accepted:
			paused = false
			return
		var transported: Dictionary = decoded_pair.value
		var counts: Array[int] = [_phases.size(), _hits.size(), _cue_events.size(), _progress.size()]
		_expect(hero.snapshot_error(transported.player).is_empty() and level.snapshot_error_with_player(transported.level, transported.player).is_empty() and hero.restore_state(transported.player) and level.restore_state(transported.level) and hero.snapshot_state() == actor and level.snapshot_state() == saved and counts == [_phases.size(), _hits.size(), _cue_events.size(), _progress.size()], "prevalidated exact mid-dash pair restores actor then scheduler/mechanisms without yield, clock refresh or events")
		var remaining: float = arm.state().remaining_s
		await create_timer(0.05, true).timeout
		_expect(hero.snapshot_state() == actor and level.snapshot_state() == saved and arm.state().remaining_s == remaining, "mid-dash pause preserves exact actor path, arm sample and remaining recovery")
	paused = false


func _test_extreme_witnesses() -> void:
	var fixture: Dictionary = _fixture()
	if fixture.is_empty():
		return
	if not await _opening(fixture):
		await _dispose(fixture)
		return
	var level: CinderLevel = fixture.level
	var hero: CinderPlayer = fixture.hero
	var scheduler: CinderThreatScheduler = level.get("scheduler") as CinderThreatScheduler
	var arms: Dictionary = level.get("arms")
	# Public explicit cycles below are scheduler witnesses in the actual owned
	# floor, not authored progression. Stay outside its automatic approach.
	for kit: Dictionary in PROOF_KITS:
		paused = true
		await process_frame
		var equipped: bool = true
		for id: String in kit.ids:
			equipped = hero.equip_item(id) and equipped
		var stats: Dictionary = hero.equipment.resolved_stats()
		_expect(equipped and hero.equipment.acceptance_errors().is_empty() and _near(stats.dash_speed, kit.speed) and _near(stats.dash_distance, kit.distance) and _near(stats.primary_range, kit.reach) and _near(stats.primary_cooldown, kit.primary), "canonical legal static extreme resolves without fabricated stats: " + kit.label)
		paused = false
		for profile: String in ["assisted", "standard", "challenge"]:
			for index: int in ARM_IDS.size():
				var arm: CinderLaneMechanism = arms[ARM_IDS[index]] as CinderLaneMechanism
				_stage(hero, Vector3(3.1, 0.1, -6.0 - index * 6.0), "proof witness outside automatic approach: " + kit.label + "/" + profile + "/" + ARM_IDS[index])
				await _ticks(3)
				scheduler.end_encounter("proof_fixture")
				var context: Dictionary = level.call("arm_response_context")
				context.encounter_id = "a1-l1-proof-" + profile
				_expect(scheduler.begin_encounter(profile, context.encounter_id, 1), "explicit proof boundary selects " + profile + " for " + ARM_IDS[index])
				hero.shells = 0
				var answer: Dictionary = arm.start("hero", context)
				_expect(answer.get("accepted", false), "actual source/floor/hero supports finite escape and ordinary-primary witness: " + kit.label + "/" + profile + "/" + ARM_IDS[index])
				if answer.get("accepted", false):
					var proof: Dictionary = answer.proof
					var escape: Dictionary = proof.path[1]
					var delta: Vector3 = proof.attack_position - arm.state().opening_position
					delta.y = 0.0
					_expect(not proof.uses_blast and not proof.uses_invulnerability and _near((escape.to as Vector3).distance_to(escape.from), stats.dash_distance) and _near(float(escape.end_s) - float(escape.start_s), stats.dash_duration) and delta.length() <= float(stats.primary_range) - CinderThreatScheduler.SKIN + 0.0001 and proof.response_complete_s < scheduler.reservations()[0].recovery_until_s, "witness uses actual full dash distance/duration and selected ordinary reach/recovery with zero shells")
				else:
					print("PROOF DIAGNOSTIC: ", answer)
				arm.cancel("proof_fixture")
				scheduler.end_encounter("proof_fixture")
	_expect(_beat(level) == 3 and not level.is_completed() and hero.get_world_action_records().size() == 3, "public proof fixtures never fabricate player actions or claim authored arm completion")
	await _dispose(fixture)


func _fixture() -> Dictionary:
	var game: Node = MainScene.instantiate()
	game.set("level_scene_path", LevelPath)
	root.add_child(game)
	var level: CinderLevel = game.get("active_level") as CinderLevel
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	if level == null or hero == null or not level.has_method("scheduler_bindings") or not (level.get("arms") as Dictionary).has_all(ARM_IDS):
		_expect(false, "arm fixture starts through the real shared MainScene")
		game.queue_free()
		return {}
	return {"game": game, "level": level, "hero": hero}


func _opening(fixture: Dictionary) -> bool:
	var hero: CinderPlayer = fixture.hero
	var level: CinderLevel = fixture.level
	_expect(hero.request_dash(level.call("dash_marker_position") - hero.global_position), "fixture begins with the real authored opening dash")
	await create_timer(0.4).timeout
	if _beat(level) != 1:
		_expect(false, "opening dash really completes its authored boundary")
		return false
	var targets: Dictionary = level.get("targets")
	for id: String in ["hall", "workshop"]:
		var target: PracticeTarget = targets[id] as PracticeTarget
		_stage(hero, target.global_position + Vector3(0.0, 0.1, 1.0), "ordinary " + id + " primary approach after genuine previous exercise")
		hero.shells = 0
		_expect(hero.slash(Vector3.FORWARD) == 1 and hero.shells == 0 and target.hp == 0.0, "genuine zero-ammo " + id + " primary clears its real target")
		await create_timer(0.5).timeout
	_expect(_beat(level) == 3 and (level.get("completed_exercises") as Array) == EXERCISES.slice(0, 3), "real opening actions reach the exact first three exercise prefix")
	return _beat(level) == 3


func _stage(hero: CinderPlayer, position: Vector3, note: String) -> void:
	print("STAGED FLOOR POSITION ", position, ": ", note)
	hero.global_position = position


func _require_phase(arm: CinderLaneMechanism, phase: String, description: String) -> bool:
	var reached: bool = await _until_phase(arm, phase)
	_expect(reached, description)
	if not reached:
		print("PHASE DIAGNOSTIC: ", arm.state(), " ", arm.last_error)
	return reached


func _until_phase(arm: CinderLaneMechanism, phase: String) -> bool:
	for _index: int in 340:
		if arm.state().phase == phase:
			return true
		await _ticks(1)
	return false


func _ticks(count: int) -> void:
	for _index: int in count:
		await physics_frame
		await process_frame


func _dispose(fixture: Dictionary) -> void:
	paused = false
	var level: CinderLevel = fixture.level
	level.exit_level()
	# Let accepted audio feedback finish before destroying its shared voices.
	await create_timer(0.5).timeout
	(fixture.game as Node).queue_free()
	await process_frame


func _beat(level: CinderLevel) -> int:
	return int(level.get("beat_index"))


func _near(actual: Variant, expected: Variant) -> bool:
	return absf(float(actual) - float(expected)) < 0.0001


func _watchdog() -> void:
	if not _finished:
		_expect(false, "bounded arm harness completes without a hung phase or fixture")
		quit(1)


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	print("PASS: " if condition else "FAIL: ", description)
	if not condition:
		_failures += 1
