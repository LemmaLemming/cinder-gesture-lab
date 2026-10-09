extends SceneTree
## TMP FOCUSED NATIVE REPRODUCTION, unimported/unexecuted.
## focused-desktop-level-1 representative public Lane cycle under actual B05
## parent guards; not an earned intro/phase2 route or parent save claim.
## Actual parent configure/start, actual bound Foot preview/start, one public
## native dash to actual coincident bait, one late active observer actor.hide().
## No private/live Hero transform, HP, phase, clock, receipt or immunity writes.
## Parent/shared sources remain exact; root owns promotion and queued run.
## Expected parent552 d89967446d5786189cae1371a06934256fa901d6c2042bbc9dff6d10195ce26d.

const ParentScript: Script = preload("res://scripts/acts/act2/dead_london_sentry_encounter.gd")
const PlayerScript: Script = preload("res://scripts/player.gd")
const EffectsScript: Script = preload("res://scripts/effects.gd")
const SchedulerScript: Script = preload("res://scripts/combat/threat_scheduler.gd")
const BaitScript: Script = preload("res://scripts/acts/act2/dead_london_bait.gd")
const Geometry: Script = preload("res://scripts/combat/threat_geometry.gd")
const MAX_TICKS: int = 240

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

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await _late_actor_hide()
	paused = false
	print("A2-L5 late Foot publication smoke: %d checks, %d failures; one Standard public representative Foot cycle/actual dash exposure/late live Actor hide/cancel/cleanup only; no earned boss phase, portable checkpoint, whole level, camera or art credit" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _create() -> Dictionary:
	var viewport := SubViewport.new()
	viewport.name = "TEST_ONLY_B05_LateFootPublication"
	viewport.size = Vector2i(540, 1170)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	var world := Node3D.new()
	world.name = "NativeLateFootWorld"
	viewport.add_child(world)
	var floor := StaticBody3D.new()
	floor.name = "AuthoredDryFloor"
	floor.collision_layer = 1
	floor.collision_mask = 0
	floor.position = Vector3(0, -0.5, 0)
	var support := CollisionShape3D.new()
	support.name = "AuthoredDryFloorShape"
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
	_expect(hero.equipment.equip("WEAPON-03"), "representative fixture authors canonical Heavy before Hero entry")
	# Authored once before entry. A real full native dash, not a live transform
	# write, will place Hero at the circle/joint and publish actual bait there.
	hero.position = Vector3(0, 0.02, -float(hero.equipment.resolved_stats().dash_distance))
	hero.fx = effects
	world.add_child(hero)
	var scheduler: CinderThreatScheduler = SchedulerScript.new()
	scheduler.name = "OneSharedScheduler"
	world.add_child(scheduler)
	var encounter_id: String = "TEST:A2-L5:late-foot-publication:standard"
	_expect(scheduler.begin_encounter("standard", encounter_id, 1), "representative fixture begins one genuine Standard epoch")
	var bait: RefCounted = BaitScript.new()
	_expect(bool(bait.call("bind", hero)), "actual bait binds ready Hero without synthetic receipt")
	var consumed: Array[bool] = []
	var action_callback: Callable = func(record: Dictionary) -> void: consumed.append(bool(bait.call("observe_record", record)))
	hero.world_action_executed.connect(action_callback)
	var region: Dictionary = {"collision": support, "safe_rect": Rect2(-9.998, -9.998, 19.996, 19.996)}
	var directions: Array[Vector3] = []
	for index: int in range(16): directions.append(Vector3(sin(float(index) * TAU / 16.0), 0, cos(float(index) * TAU / 16.0)).normalized())
	var context: Dictionary = {"encounter_id": encounter_id, "world_revision": 1, "recognition_s": 0.30, "attack_input_margin_s": 0.03, "escape_directions": directions.duplicate(), "return_directions": directions.duplicate(), "floor_regions": [region]}
	var guard_calls: Array[Dictionary] = []
	var presentation_guard: Callable = func(proposed: Dictionary) -> bool:
		var ready: bool = true
		for key: String in ["actor", "ray_cue", "foot_cue", "foot_visual", "joint", "hero"]:
			var node: Variant = proposed.get(key)
			if not is_instance_valid(node) or not node.is_inside_tree() or not node.is_node_ready() or node.is_queued_for_deletion() or node.get_world_3d() != world.get_world_3d(): ready = false
		# Live Actor/Foot visual are required presentation. Inactive cue children
		# may be hidden legitimately; Lane checks its actual active cue separately.
		if ready and (not proposed.actor.is_visible_in_tree() or not proposed.foot_visual.is_visible_in_tree()): ready = false
		guard_calls.append({"clock_s": scheduler.get_clock(), "accepted": ready, "actor_visible": proposed.actor.is_visible_in_tree() if is_instance_valid(proposed.get("actor")) else false})
		return ready
	var parent: Node3D = ParentScript.new() as Node3D
	parent.name = "ActualB05MechanicsParent"
	world.add_child(parent)
	var configured: bool = bool(parent.call("configure", hero, effects, scheduler, bait, world, {"dry-floor": region}, context, Vector3.ZERO, Vector3.ZERO, presentation_guard))
	_expect(configured, "actual unmodified B05 parent binds native Foot and visibility-sensitive host guard")
	var hits: Array[Dictionary] = []
	var failures: Array[String] = []
	var hurts: Array[Dictionary] = []
	parent.connect("hit_resolved", func(source_id: String, result: Dictionary) -> void: hits.append({"source_id": source_id, "result": result.duplicate(true), "clock_s": scheduler.get_clock()}))
	parent.connect("runtime_failed", func(reason: String) -> void: failures.append(reason))
	hero.fired.connect(func(kind: String) -> void:
		if kind == "hurt": hurts.append({"hp": hero.hp, "clock_s": scheduler.get_clock()})
	)
	var probe := NativeTickProbe.new()
	probe.name = "TEST_OnlyNativeTickBarrier"
	world.add_child(probe)
	return {"viewport": viewport, "world": world, "hero": hero, "scheduler": scheduler, "bait": bait, "parent": parent, "context": context, "configured": configured, "probe": probe, "guard_calls": guard_calls, "hits": hits, "failures": failures, "hurts": hurts, "consumed": consumed, "action_callback": action_callback}

func _late_actor_hide() -> void:
	var fixture: Dictionary = _create()
	if not fixture.configured:
		await _dispose(fixture)
		return
	var parent: Node3D = fixture.parent
	var hero: CinderPlayer = fixture.hero
	var scheduler: CinderThreatScheduler = fixture.scheduler
	var actor: Node3D = parent.call("get_actor")
	var ray: Node3D = parent.call("get_ray")
	var foot: CinderLaneMechanism = parent.call("get_foot")
	if not _expect(await _until(fixture, func() -> bool: return _stable(hero)), "actual Hero earns stationary native floor before representative setup"):
		await _dispose(fixture)
		return
	_expect(bool(parent.call("start")), "public parent start activates its existing priority99 presentation guard")
	var observations: Array[Dictionary] = []
	var late_observer: Callable = func(state: Dictionary) -> void:
		if state.status != "running" or state.phase != "active" or not observations.is_empty(): return
		var guard: Dictionary = fixture.guard_calls[-1] if not fixture.guard_calls.is_empty() else {}
		observations.append({"clock_s": scheduler.get_clock(), "prior_guard": guard.duplicate(true), "actor_alive": is_instance_valid(actor) and actor.is_inside_tree() and not actor.is_queued_for_deletion(), "actor_visible_before": actor.is_visible_in_tree(), "actor_hp": actor.get("hp"), "parent_before": parent.call("state"), "foot_before": foot.state(), "cue_before": foot.get_cue().state(), "native_cue_before": _active_cue_live(foot), "hero_position": hero.global_position, "hero_response": hero.get_threat_response_state(), "hero_hp_before": hero.hp, "physical_exposure": Geometry.segment_hits(state.geometry, hero.global_position, hero.global_position, SchedulerScript.CAPSULE_RADIUS)})
		actor.hide() # Actual late authored presentation mutation, no source cleanup.
		observations[-1]["actor_visible_after"] = actor.is_visible_in_tree()
		observations[-1]["actor_still_live_after"] = actor.is_inside_tree() and not actor.is_queued_for_deletion()
		observations[-1]["foot_still_live_visible_after"] = foot.is_inside_tree() and not foot.is_queued_for_deletion() and foot.is_visible_in_tree()
		observations[-1]["native_cue_after"] = _active_cue_live(foot)
		observations[-1]["native_foot_control_after"] = scheduler.source_control_state(foot)
	# configure connected the production parent observer first. This observer
	# is deliberately later on the same public native publication.
	foot.state_changed.connect(late_observer)
	var preview: Dictionary = foot.preview_start("hero", fixture.context, actor.global_position)
	if not _expect(preview.get("accepted", false), "pure actual Foot preview admits representative public cycle: " + String(preview.get("reason", ""))):
		await _dispose(fixture)
		return
	var admitted: Dictionary = foot.start("hero", fixture.context, actor.global_position, null, preview)
	if not _expect(admitted.get("accepted", false) and admitted.proof.accepted and not admitted.proof.uses_blast and not admitted.proof.uses_invulnerability, "actual bound Foot commits one genuine native lease/proof through supported public start"):
		await _dispose(fixture)
		return
	if not _expect(hero.request_dash(Vector3.BACK), "public native dash begins actual route-free exposure setup before parent physics"):
		await _dispose(fixture)
		return
	if not _expect(await _until(fixture, func() -> bool: return hero.get_world_action_records().size() == 1 and _stable(hero)), "actual physical dash completes and stable Hero reaches joint/Foot"):
		await _dispose(fixture)
		return
	var receipt: Dictionary = hero.get_world_action_records()[0]
	var sample: Dictionary = fixture.bait.call("sample_for_ray")
	if not _expect(receipt.kind == "dash" and not receipt.blocked and not receipt.collision_shortened and receipt.distance > 0.0 and sample.dash_sequence == receipt.sequence and Geometry.planar(sample.point).distance_to(Geometry.planar(actor.global_position)) <= 0.00001 and ray.call("state").cycle == 0 and hero.hp == 100.0 and fixture.hits.is_empty() and fixture.hurts.is_empty(), "real completed coincident bait prevents Ray admission without private state or immunity seeding"):
		print("DIAG: representative setup ", parent.call("state"), " Hero=", hero.get_threat_response_state(), " receipt=", receipt, " bait=", sample)
		await _dispose(fixture)
		return
	if not _expect(await _until(fixture, func() -> bool: return not observations.is_empty()), "actual late observer executes on native Foot active publication"):
		await _dispose(fixture)
		return
	for _index: int in range(3): await _step(fixture)
	var observation: Dictionary = observations[0]
	var final_state: Dictionary = parent.call("state")
	print("DIAG: late Foot publication observation=", observation, " resulting_parent=", final_state, " actual_hits=", fixture.hits, " actual_hurts=", fixture.hurts, " final_hp=", hero.hp, " failures=", fixture.failures)
	_expect(observations.size() == 1 and observation.prior_guard.get("accepted", false) and observation.prior_guard.clock_s == observation.clock_s and observation.actor_visible_before and observation.actor_alive and observation.actor_hp == 30.0 and observation.parent_before.runtime_error.is_empty() and observation.parent_before.stage == "ray-introduction" and observation.foot_before.status == "running" and observation.foot_before.phase == "active" and observation.cue_before.phase == "active" and observation.native_cue_before and observation.physical_exposure and observation.hero_response.stable and observation.hero_response.motion.grounded and observation.hero_hp_before == 100.0, "late mutation follows successful same-clock parent guard with genuine active Foot and physical unhurt Hero exposure")
	_expect(not observation.actor_visible_after and observation.actor_still_live_after and observation.foot_still_live_visible_after and observation.native_cue_after and observation.native_foot_control_after.reservations.size() == 1, "late actor.hide loses required live presentation while native Foot/required cue/lease remain valid")
	# The required behavior. Preserve a genuine failure/harm result if the old
	# parent-first guard is insufficient; do not call cleanup before observing.
	_expect(hero.hp == 100.0 and fixture.hits.is_empty() and fixture.hurts.is_empty() and foot.state().hit_ids.is_empty(), "late live Sentry presentation loss closes Foot before any actual hurt opportunity")
	_expect(final_state.stage == "cancelled" and final_state.runtime_error == "B05 required native bindings/presentation lost" and foot.state().status == "cancelled" and foot.state().last_cancel_reason == "b05_actual_source_cue_or_frame_lost" and foot.get_cue().state().phase == "clear" and fixture.failures == ["B05 required native bindings/presentation lost"], "parent independently detects live presentation guard failure and cancels actual Foot with its precise reason")
	_expect(ray.call("state").cycle == 0 and actor.get("hp") == 30.0 and actor.get("boss_phase") == 1 and not actor.get("transition_pending") and fixture.consumed == [true], "focused case remains one real Foot/public dash with untouched boss pools and no earned phase claim")
	if foot.state_changed.is_connected(late_observer): foot.state_changed.disconnect(late_observer)
	await _dispose(fixture)

func _active_cue_live(foot: CinderLaneMechanism) -> bool:
	var cue: CinderThreatCue = foot.get_cue()
	if not is_instance_valid(cue) or not cue.is_visible_in_tree() or cue.state().phase != "active": return false
	for part_name: String in ["RequiredSourceMarker", "RequiredFootprintOutline", "RequiredFootprintFill"]:
		var part: MeshInstance3D = cue.get_node_or_null(part_name) as MeshInstance3D
		if not is_instance_valid(part) or part.is_queued_for_deletion() or not part.is_visible_in_tree() or part.mesh == null: return false
	return true

func _stable(hero: CinderPlayer) -> bool:
	var response: Dictionary = hero.get_threat_response_state()
	return response.stable and response.motion.grounded and not hero.action_in_progress()

func _until(fixture: Dictionary, predicate: Callable) -> bool:
	for _index: int in range(MAX_TICKS):
		if bool(predicate.call()): return true
		if fixture.hero.dead: return false
		await _step(fixture)
	return false

func _step(fixture: Dictionary) -> void:
	await (fixture.probe as NativeTickProbe).tick_finished

func _dispose(fixture: Dictionary) -> void:
	var parent: Node3D = fixture.parent
	var hero: CinderPlayer = fixture.hero
	var refs: Array[WeakRef] = [weakref(fixture.world), weakref(hero), weakref(parent), weakref(fixture.scheduler)]
	if fixture.configured:
		for node: Variant in [parent.call("get_actor"), parent.call("get_ray"), parent.call("get_foot"), parent.call("get_joint_cue"), parent.call("get_foot").get_cue()]: refs.append(weakref(node))
		parent.call("cleanup")
		_expect(not bool(parent.call("start")) and not bool(parent.call("resume_after_phase_checkpoint")) and parent.call("owners").is_empty(), "normal public cleanup permanently closes remaining parent admissions")
	fixture.bait.call("release")
	if hero.world_action_executed.is_connected(fixture.action_callback): hero.world_action_executed.disconnect(fixture.action_callback)
	fixture.scheduler.end_encounter("test_late_foot_whole_parent_disposal")
	fixture.viewport.queue_free()
	await process_frame
	await process_frame
	var all_gone: bool = true
	for ref: WeakRef in refs:
		if ref.get_ref() != null: all_gone = false
	_expect(all_gone, "whole native world/parent/source/cue/Hero disposal releases all observed objects")
	paused = false

func _expect(condition: bool, description: String) -> bool:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)
	return condition
