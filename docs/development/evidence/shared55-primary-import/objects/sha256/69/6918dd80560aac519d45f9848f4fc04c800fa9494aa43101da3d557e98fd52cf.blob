extends SceneTree
## TEST ONLY actual shared Player/ordinary-primary and stationary Reach/Place.
## Isolated native actors/phase transport; not authored L3/smoke/portrait proof.
const PlayerScript: Script = preload("res://scripts/player.gd")
const EffectsScript: Script = preload("res://scripts/effects.gd")
const BossScript: Script = preload("res://scripts/acts/act2/handling_machine_boss_actor.gd")
const TenderScript: Script = preload("res://scripts/acts/act2/canister_tender_actor.gd")
const SchedulerScript: Script = preload("res://scripts/combat/threat_scheduler.gd")
const MechanismScript: Script = preload("res://scripts/combat/lane_mechanism.gd")
const Geometry: Script = preload("res://scripts/combat/threat_geometry.gd")
const ExactJson: Script = preload("res://scripts/campaign/exact_json.gd")
const EPOCH: String = "A2-L3:actor-fixture"
const ROLE: Dictionary = {"raw_damage": 10.0, "windup_s": 2.2, "lock_s": 1.1, "active_s": 0.2, "recovery_s": 1.9, "attack_interval_s": 1.9, "max_hp": 30.0, "move_speed": 0.0}
const FLOORS: Dictionary = {"windup_s": 2.2, "lock_s": 1.1, "recovery_s": 1.9}
var _checks: int = 0
var _failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var a: Dictionary = _create()
	await _ticks(6)
	var boss: Node3D = a.boss
	var hero: CinderPlayer = a.hero
	var boundary: Array[String] = []
	var boundary_reentry: Array[bool] = []
	boss.connect("phase_boundary_reached", func(id: String) -> void:
		boundary.append(id)
		boundary_reentry.append(not boss.call("commit_phase_two") and not boss.call("set_tool_action", "place") and not boss.call("take_damage", 100.0, Vector3.ZERO).accepted and boss.get("hp") == 15.0 and boss.get("boss_phase") == 1)
	)
	_expect(get_nodes_in_group("enemies") == [boss], "one actual boss target, no duplicate cosmetic HP group")
	var before_direction: String = str([boss.get("phase"), boss.get("phase_progress"), boss.get("direction"), boss.get_node("BossRig").call("get_body_yaw")])
	_expect(not boss.call("present_phase", "lock", 0.5, Vector3.LEFT) and str([boss.get("phase"), boss.get("phase_progress"), boss.get("direction"), boss.get_node("BossRig").call("get_body_yaw")]) == before_direction, "unsupported B02 heading rejects atomically without actor/art divergence")
	_expect(not boss.is_physics_processing() and not _contains_collision(boss), "anchored B02 adapter has no autonomous clock/body cage")
	_expect(boss.call("present_phase", "recovery", 0.3, Vector3.BACK), "actual actor can present a parent-owned opening pose")
	_expect(hero.slash(Vector3.BACK) == 0 and boss.get("hp") == 30.0, "fake recovery pose cannot bypass actual retained Reach")
	await _primary_ready(hero)
	var reach: CinderLaneMechanism = a.mechanisms.reach
	var preview: Dictionary = reach.preview_start("hero", a.context)
	_expect(preview.get("accepted", false), "actual shared23 Reach supplies pure prospective primary proof")
	var started: Dictionary = reach.start("hero", a.context, null, null, preview)
	_expect(started.get("accepted", false) and not started.get("proof", {}).get("uses_blast", true), "exact preview commits actual Reach without ammo")
	if not started.get("accepted", false):
		push_error(str(started))
		await _dispose(a)
		_done()
		return
	_expect(hero.slash(Vector3.BACK) == 0 and boss.get("hp") == 30.0, "real warning does not open incoming boss damage")
	_expect(await _until_phase(reach, "recovery"), "actual Reach warning/lock/active deadlines naturally reach recovery")
	await _primary_ready(hero)
	hero.shells = 0
	_expect(hero.slash(Vector3.BACK) == 1 and boss.get("hp") == 15.0 and boss.get("transition_pending") and boss.get("boss_phase") == 1, "actual Heavy24 primary consumes first15HP phase at low joint without healing or skipping phase2")
	_expect(boundary_reentry == [true], "boundary observer cannot commit phase/action or consume phase2 inside original incoming hit")
	_expect(boundary == ["fixture-boss"], "one actual accepted threshold emits one phase boundary")
	var blocked: Dictionary = boss.call("take_damage", 100.0, Vector3.ZERO)
	_expect(not blocked.accepted and blocked.hp_damage == 0.0 and boss.get("hp") == 15.0, "closed phase transaction rejects surplus/duplicate damage")
	paused = true
	var saved: Dictionary = boss.call("snapshot_state")
	var encoded: String = ExactJson.stringify(saved)
	var transported: Dictionary = ExactJson.parse(encoded)
	_expect(not saved.is_empty() and transported.get("accepted", false) and transported.value == saved, "actual paused threshold actor preserves exact native portable phase tuple")
	var forged: Dictionary = saved.duplicate(true)
	forged.actor.hp = 14.0
	_expect(not boss.call("snapshot_error", forged).is_empty() and not boss.call("restore_state", forged) and boss.call("snapshot_state") == saved, "first-phase underflow rejects atomically without HP/pose mutation")
	var fresh: Node3D = BossScript.new() as Node3D
	fresh.name = "FreshExactBoss"
	a.world.add_child(fresh)
	fresh.remove_from_group("enemies") # TEST ONLY staged actor, no duplicate hit.
	_expect(fresh.call("configure", hero, a.effects, "fixture-boss") and fresh.call("restore_state", transported.value) and fresh.call("snapshot_state") == saved, "fresh native B02 actor restores pending phase and actual pose exactly/quietly")
	fresh.call("cleanup")
	fresh.queue_free()
	paused = false
	await _ticks(2)
	_expect(boss.call("commit_phase_two") and boss.get("hp") == 15.0 and boss.get("boss_phase") == 2 and not boss.get("transition_pending"), "earned phase commit changes no remaining HP")
	_expect(not boss.call("commit_phase_two"), "duplicate phase commit refuses")
	reach.cancel("fixture_phase_boundary")
	a.action = "place"
	_expect(boss.call("set_tool_action", "place"), "second known action selects parent-owned Place art")
	var place: CinderLaneMechanism = a.mechanisms.place
	var circle_preview: Dictionary = place.preview_start("hero", a.context)
	_expect(circle_preview.get("accepted", false), "actual default Circle supplies prospective response proof")
	var placed: Dictionary = place.start("hero", a.context, null, null, circle_preview)
	_expect(placed.get("accepted", false), "exact Circle preview commits original immutable plate footprint")
	if not placed.get("accepted", false): push_error(str(placed))
	_expect(await _until_phase(place, "recovery"), "actual Place patch reaches recovery under original clocks")
	paused = true
	var phase2: Dictionary = boss.call("snapshot_state")
	_expect(phase2.boss_phase == 2 and phase2.tool_action == "place" and phase2.actor.hp == 15.0, "saved second-phase tuple retains exact selected plate action/remaining pool")
	var second_fresh: Node3D = BossScript.new() as Node3D
	second_fresh.name = "FreshPhaseTwoPlace"
	a.world.add_child(second_fresh)
	second_fresh.remove_from_group("enemies") # TEST ONLY staged actor.
	var place_transport: Dictionary = ExactJson.parse(ExactJson.stringify(phase2))
	_expect(second_fresh.call("configure", hero, a.effects, "fixture-boss") and place_transport.get("accepted", false) and second_fresh.call("restore_state", place_transport.value) and second_fresh.call("snapshot_state") == phase2 and second_fresh.get_node("BossRig").call("get_action") == "place", "fresh native phase2 restores exact Place action and low grounded pose")
	var malformed_action: Dictionary = phase2.duplicate(true)
	malformed_action.tool_action = "sweep"
	_expect(not second_fresh.call("restore_state", malformed_action) and second_fresh.call("snapshot_state") == phase2 and second_fresh.get_node("BossRig").call("get_action") == "place", "malformed boss action rejects without actor/art mutation")
	second_fresh.call("cleanup")
	second_fresh.queue_free()
	var wrong: Dictionary = phase2.duplicate(true)
	wrong.actor.hp = 30.0
	_expect(not boss.call("restore_state", wrong) and boss.call("snapshot_state") == phase2, "second phase rejects HP refill atomically")
	paused = false
	await _primary_ready(hero)
	hero.shells = 0
	var defeats: Array[String] = []
	boss.connect("defeated", func(id: String) -> void:
		defeats.append(id)
		place.cancel("actual_local_arm_disengaged")
	)
	_expect(hero.slash(Vector3.BACK) == 1 and boss.get("hp") == 0.0 and boss.get("phase") == "defeated", "actual second zero-ammo Heavy primary disables remaining15HP local arm")
	_expect(defeats == ["fixture-boss"] and boundary.size() == 1 and a.scheduler.reservations().is_empty(), "one local disable retires actual danger without extra phase/kill")
	var spent: Dictionary = boss.call("take_damage", 100.0, Vector3.ZERO)
	_expect(not spent.accepted and not spent.target_alive_before_hit, "spent boss grants no repeat accepted hit/reload credit")
	var tender: Node3D = TenderScript.new() as Node3D
	tender.name = "ActualTender"
	tender.position = Vector3(4, 0, 0)
	a.world.add_child(tender)
	_expect(tender.call("configure", hero, a.effects, "fixture-tender") and tender.get_node_or_null("TenderRig/TwoSkidCradle") != null and tender.get_node_or_null("ScoutRig") == null, "genuine Tender target builds its distinct tube/skid rig only")
	_expect(not _contains_collision(tender) and not tender.is_physics_processing(), "Tender visual introduces no private body cage/damage clock")
	tender.call("present_phase", "recovery", 0.5, Vector3.BACK)
	paused = true
	var tender_saved: Dictionary = tender.call("snapshot_state")
	var tender_exact: Dictionary = ExactJson.parse(ExactJson.stringify(tender_saved))
	_expect(not tender_saved.is_empty() and tender_exact.get("accepted", false) and tender.call("restore_state", tender_exact.value) and tender.call("snapshot_state") == tender_saved, "Tender reuses exact ordinary-target quiet pose transport")
	paused = false
	tender.call("cleanup")
	tender.queue_free()
	await _dispose(a)
	_done()

func _create() -> Dictionary:
	var viewport := SubViewport.new()
	viewport.name = "L3ActorFixture"
	viewport.size = Vector2i(540, 1170)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	var world := Node3D.new()
	world.name = "NativeFixtureWorld"
	viewport.add_child(world)
	var floor := StaticBody3D.new()
	floor.name = "DryFixtureFloor"
	floor.collision_layer = 1
	floor.collision_mask = 0
	floor.position.y = -0.5
	var support := CollisionShape3D.new()
	support.name = "DrySupport"
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	support.shape = box
	floor.add_child(support)
	world.add_child(floor)
	var hero: CinderPlayer = PlayerScript.new()
	hero.name = "SharedHero"
	hero.position = Vector3(0, 0, -1)
	world.add_child(hero)
	_expect(hero.equip_item("WEAPON-03"), "fixture uses canonical shortest Heavy primary")
	hero.shells = 0
	var effects: PixelEffects = EffectsScript.new()
	world.add_child(effects)
	hero.fx = effects
	var scheduler: CinderThreatScheduler = SchedulerScript.new()
	world.add_child(scheduler)
	_expect(scheduler.begin_encounter("standard", EPOCH), "fixture begins actual standard shared encounter")
	var boss: Node3D = BossScript.new() as Node3D
	boss.name = "ActualBoss"
	world.add_child(boss)
	_expect(boss.call("configure", hero, effects, "fixture-boss"), "B02 binds actual shared Hero/effects and immutable native root")
	var region: Dictionary = {"collision": support, "safe_rect": Rect2(-9.998, -9.998, 19.996, 19.996)}
	var context: Dictionary = {"encounter_id": EPOCH, "world_revision": 1, "recognition_s": 0.12, "attack_input_margin_s": 0.02, "escape_directions": [Vector3.LEFT, Vector3.RIGHT], "return_directions": [Vector3.LEFT, Vector3.RIGHT], "floor_regions": [region]}
	var a: Dictionary = {"viewport": viewport, "world": world, "hero": hero, "effects": effects, "boss": boss, "scheduler": scheduler, "mechanisms": {}, "context": context, "action": "reach"}
	for action: String in ["reach", "place"]:
		var node: CinderLaneMechanism = MechanismScript.new()
		node.name = action
		var shape: Dictionary = Geometry.lane(Vector3.ZERO, Vector3.BACK * 3.8, 0.31) if action == "reach" else Geometry.circle(Vector3.ZERO, 1.1)
		_expect(node.configure("boss-" + action, shape, Vector3.ZERO, ROLE, FLOORS), "known action configures actual immutable geometry " + action)
		world.add_child(node)
		_expect(node.bind(scheduler, {"hero": hero}), "known action binds exact native consumers " + action)
		a.mechanisms[action] = node
		node.state_changed.connect(func(state: Dictionary) -> void:
			if a.action == action and float(boss.get("hp")) > 0.0:
				boss.call("present_phase", "idle" if state.phase == "clear" else state.phase, 0.0, Vector3.BACK)
		)
	var gate: Callable = func() -> bool:
		var node: CinderLaneMechanism = a.mechanisms[a.action]
		if paused or not is_instance_valid(node) or not node.is_visible_in_tree() or not node.get_cue().is_visible_in_tree(): return false
		var state: Dictionary = node.state()
		var retained: Dictionary = scheduler.reservation_state(state.reservation_id)
		return not paused and state.status == "running" and state.phase == "recovery" and not retained.is_empty() and retained.state == "recovery" and node.get_cue().state().phase == "recovery" and node.get_cue().state().geometry == state.geometry and scheduler.get_clock() > float(retained.active_until_s) and scheduler.get_clock() <= float(retained.recovery_until_s)
	_expect(boss.call("bind_damage_window", gate), "B02 binds real retained shared recovery, not cosmetic phase")
	return a

func _until_phase(node: CinderLaneMechanism, phase: String) -> bool:
	for ignored: int in range(420):
		if node.state().phase == phase and node.state().status == "running": return true
		await physics_frame
	return false

func _primary_ready(hero: CinderPlayer) -> void:
	await create_timer(float(hero.stats.primary_cooldown) + 0.03).timeout

func _ticks(count: int) -> void:
	for ignored: int in range(count): await physics_frame

func _contains_collision(node: Node) -> bool:
	if node is CollisionObject3D or node is CollisionShape3D: return true
	for child: Node in node.get_children():
		if _contains_collision(child): return true
	return false

func _dispose(a: Dictionary) -> void:
	paused = false
	for node: CinderLaneMechanism in a.mechanisms.values(): node.clear("fixture_cleanup")
	a.scheduler.end_encounter("fixture_cleanup")
	a.boss.call("cleanup")
	a.effects.clear()
	await create_timer(0.15).timeout
	a.viewport.queue_free()
	await _ticks(3)
	await process_frame
	_expect(get_nodes_in_group("enemies").is_empty(), "isolated actors/effects/consumers retire cleanly")

func _expect(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("FAIL: " + label)

func _done() -> void:
	print("A2-L3 isolated actual actor/phase smoke: %d checks, %d failures; no authored L3/smoke/portrait/full aggregate claim" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
