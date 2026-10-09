extends SceneTree
## TEST ONLY B05 actor API fixture: actual shared Player, Effects, native floor,
## InteractionCue and ordinary primaries. Opening poses/phase commit are public
## isolated fixture calls, not earned ray/foot receipts or whole-level authority.
## Authored placement/equipment precede tree entry; no live HP/motion/clock seed.
## The idle-yaw case changes only a prospective saved cosmetic heading.

const PlayerScript: Script = preload("res://scripts/player.gd")
const EffectsScript: Script = preload("res://scripts/effects.gd")
const ActorScript: Script = preload("res://scripts/acts/act2/dead_london_sentry_actor.gd")
const CueScript: Script = preload("res://scripts/cues/interaction_cue.gd")
const ExactJson: Script = preload("res://scripts/campaign/exact_json.gd")
const MAX_TICKS: int = 180
const ACTOR_ID: String = "A2-L5:actor-api-sentry"
var _checks: int = 0
var _failures: int = 0
var _fixtures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await _damage_and_observer_checks()
	await _exact_idle_restore_checks()
	await _cue_loss_checks()
	paused = false
	print("A2-L5 isolated Sentry actor smoke: %d checks, %d failures; actor API/prospective pose only, no native Scheduler/ray/foot, recognizer, whole-parent, checkpoint, balance or art credit" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _create() -> Dictionary:
	_fixtures += 1
	var viewport := SubViewport.new()
	viewport.name = "TEST_ONLY_SentryActor%d" % _fixtures
	viewport.size = Vector2i(540, 1170)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	var world := Node3D.new()
	world.name = "NativeActorWorld"
	viewport.add_child(world)
	var floor := StaticBody3D.new()
	floor.name = "AuthoredDryFloor"
	floor.collision_layer = 1
	floor.collision_mask = 0
	floor.position = Vector3(0, -0.5, 0)
	var collision := CollisionShape3D.new()
	collision.name = "DrySupport"
	var box := BoxShape3D.new()
	box.size = Vector3(12, 1, 12)
	collision.shape = box
	floor.add_child(collision)
	world.add_child(floor)
	var effects: PixelEffects = EffectsScript.new()
	effects.name = "SharedEffects"
	world.add_child(effects)
	var hero: CinderPlayer = PlayerScript.new()
	hero.name = "SharedPlayer"
	hero.position = Vector3(0, 0.02, 0)
	_expect(hero.equipment.equip("WEAPON-03"), "authored equipment uses canonical shortest-reach Heavy primary")
	hero.fx = effects
	world.add_child(hero)
	var actor: Node3D = ActorScript.new() as Node3D
	actor.name = "SentryLowJoint"
	actor.position = Vector3(0, 0, -1.1)
	world.add_child(actor)
	var cue: CinderInteractionCue = CueScript.new()
	cue.name = "ParentOwnedJointCue"
	cue.position = actor.position
	world.add_child(cue)
	_expect(bool(actor.call("configure", hero, effects, ACTOR_ID)) and bool(actor.call("bind_joint_cue", cue)), "actor binds actual ready shared context and same-world parent cue")
	var gate_views: Array[Dictionary] = []
	var gate: Callable = func() -> bool:
		var projection: Dictionary = actor.call("source_snapshot_state")
		gate_views.append(projection.duplicate(true))
		return not paused and not projection.is_empty() and projection.opening_state == "available" and not projection.phase_pending and not projection.defeated
	_expect(bool(actor.call("bind_damage_window", gate)), "isolated incoming gate reads the actual pure source projection")
	return {"viewport": viewport, "world": world, "hero": hero, "effects": effects, "actor": actor, "cue": cue, "gate": gate, "gate_views": gate_views}

func _damage_and_observer_checks() -> void:
	var fixture: Dictionary = _create()
	var hero: CinderPlayer = fixture.hero
	var actor: Node3D = fixture.actor
	var cue: CinderInteractionCue = fixture.cue
	if not _expect(await _wait_ready(hero), "actual Player settles on supported native floor"):
		await _dispose(fixture)
		return
	_expect(hero.stats.primary_damage == 24.0 and hero.stats.primary_range == 1.8 and actor.global_position.distance_to(hero.global_position) < 1.8, "ordinary Heavy profile reaches authored low joint without dash or blast")
	_expect(not actor.is_processing() and not actor.is_physics_processing() and not _contains_collision(actor), "actor has no independent clock or body collider")
	paused = true
	await process_frame
	var initial: Dictionary = actor.call("snapshot_state")
	_expect(not initial.is_empty() and initial.actor.hp == 30.0 and initial.boss_phase == 1 and not initial.transition_pending, "initial native snapshot has one finite total 30 first pool")
	paused = false
	var order: Array[String] = []
	var rejections: Array[bool] = []
	var owner_spent: Array[bool] = []
	var after_owner: Array[Dictionary] = []
	var thresholds: Array[String] = []
	actor.connect("phase_boundary_reached", func(id: String) -> void:
		order.append("before-owner")
		thresholds.append(id)
		rejections.append(actor.call("source_snapshot_state").is_empty())
		rejections.append(not bool(actor.call("take_damage", 24.0, Vector3.ZERO).accepted))
		rejections.append(not bool(actor.call("present_phase", "idle", 0.0, Vector3.BACK)))
		rejections.append(not bool(actor.call("commit_phase_two")))
		var previous_pause: bool = paused
		paused = true
		rejections.append(actor.call("snapshot_state").is_empty() and String(actor.get("last_snapshot_error")).contains("phase-damage"))
		rejections.append(not String(actor.call("snapshot_error", initial)).is_empty() and not bool(actor.call("restore_state", initial)))
		paused = previous_pause
	)
	actor.connect("phase_boundary_reached", func(_id: String) -> void:
		order.append("owner")
		owner_spent.append(cue.present("spent", "attack"))
	)
	actor.connect("phase_boundary_reached", func(_id: String) -> void:
		order.append("after-owner")
		after_owner.append(actor.call("source_snapshot_state"))
	)
	_expect(bool(actor.call("present_phase", "recovery", 0.25, Vector3.BACK)) and cue.present("available", "attack"), "public manual recovery and actual joint cue expose isolated actor opening")
	var anchor: Vector3 = actor.global_position
	var hp_before: float = float(actor.get("hp"))
	_expect(hero.slash(Vector3.FORWARD) == 1 and hp_before - float(actor.get("hp")) == 15.0 and actor.get("hp") == 15.0, "actual 24 primary accepts exactly first 15 with no refill or movement")
	_expect(actor.global_position == anchor and actor.get("boss_phase") == 1 and actor.get("transition_pending") and thresholds == [ACTOR_ID], "one threshold commits pending 15 and preserves immutable anchor")
	_expect(fixture.gate_views.size() == 1 and not fixture.gate_views[0].is_empty() and fixture.gate_views[0].opening_state == "available" and not fixture.gate_views[0].phase_pending, "gate reads nonempty native source projection inside both damage transactions")
	_expect(order == ["before-owner", "owner", "after-owner"] and rejections == [true, true, true, true, true, true] and owner_spent == [true], "threshold observers reject reentry and parent spends cue before later observers")
	_expect(after_owner.size() == 1 and not after_owner[0].is_empty() and after_owner[0].phase_pending and not after_owner[0].defeated and after_owner[0].opening_state == "spent", "later observer reads coherent pending source with real spent cue")
	var records: Array[Dictionary] = hero.get_world_action_records()
	_expect(records.size() == 1 and records[0].kind == "primary" and records[0].damage == 24.0 and records[0].hits == 1, "actual Player publishes one raw 24 accepted ordinary action, without blast")
	_expect(not bool(actor.call("commit_phase_two")), "phase commit rejects the actual unfinished primary commitment")
	if not _expect(await _wait_ready(hero), "actual primary commitment and cooldown settle before component pause"):
		await _dispose(fixture)
		return
	paused = true
	await process_frame
	var pending: Dictionary = actor.call("snapshot_state")
	var pending_player: Dictionary = hero.snapshot_state()
	_expect(not pending.is_empty() and pending.actor.hp == 15.0 and pending.transition_pending and bool(actor.call("restore_state", pending)) and _same(actor.call("snapshot_state"), pending) and _same(hero.snapshot_state(), pending_player) and thresholds == [ACTOR_ID], "actual pending actor quietly round-trips without player changes or a new threshold")
	paused = false
	_expect(hero.slash(Vector3.FORWARD) == 0 and actor.get("hp") == 15.0 and thresholds == [ACTOR_ID], "spent first brace cannot consume a second actual ordinary action")
	if not _expect(await _wait_ready(hero) and bool(actor.call("commit_phase_two")), "stable actual Player permits public actor phase commit without claiming parent foot receipts"):
		await _dispose(fixture)
		return
	_expect(actor.get("boss_phase") == 2 and not actor.get("transition_pending") and actor.get("hp") == 15.0 and actor.get("phase") == "idle", "actor phase commit retains remaining 15 and does not silently expose a new opening")
	var defeats: Array[String] = []
	var defeat_checks: Array[bool] = []
	actor.connect("defeated", func(id: String) -> void:
		defeats.append(id)
		defeat_checks.append(cue.present("spent", "attack"))
		var projection: Dictionary = actor.call("source_snapshot_state")
		defeat_checks.append(not projection.is_empty() and projection.defeated and not projection.phase_pending and projection.opening_state == "spent")
		defeat_checks.append(not bool(actor.call("take_damage", 24.0, Vector3.ZERO).accepted) and not bool(actor.call("commit_phase_two")))
		var previous_pause: bool = paused
		paused = true
		defeat_checks.append(actor.call("snapshot_state").is_empty() and not bool(actor.call("restore_state", pending)))
		paused = previous_pause
	)
	_expect(bool(actor.call("present_phase", "recovery", 0.25, Vector3.BACK)) and cue.present("available", "attack"), "isolated second pool opens only through explicit public recovery presentation")
	_expect(hero.slash(Vector3.FORWARD) == 1 and actor.get("hp") == 0.0 and actor.get("phase") == "defeated" and defeats == [ACTOR_ID], "second actual 24 primary consumes remaining 15 and emits one defeat")
	_expect(defeat_checks == [true, true, true, true] and fixture.gate_views.size() == 2 and not fixture.gate_views[1].is_empty(), "lethal callback retains guarded source metadata and refuses transactional restore")
	if not _expect(await _wait_ready(hero), "actual lethal primary finishes before spent capture"):
		await _dispose(fixture)
		return
	paused = true
	await process_frame
	var spent: Dictionary = actor.call("snapshot_state")
	_expect(not spent.is_empty() and spent.actor.hp == 0.0 and spent.boss_phase == 2 and not spent.transition_pending and bool(actor.call("restore_state", spent)) and bool(actor.call("restore_state", spent)) and _same(actor.call("snapshot_state"), spent) and defeats == [ACTOR_ID], "real spent tombstone restores repeatedly without duplicate defeat")
	await _dispose(fixture)

func _exact_idle_restore_checks() -> void:
	var donor: Dictionary = _create()
	var donor_hero: CinderPlayer = donor.hero
	if not _expect(await _wait_ready(donor_hero), "prospective pose donor first earns actual supported native floor contact"):
		await _dispose(donor)
		return
	paused = true
	await process_frame
	var pack: Dictionary = {"player": donor_hero.snapshot_state(), "actor": donor.actor.call("snapshot_state")}
	if not _expect(not pack.player.is_empty() and not pack.actor.is_empty(), "prospective idle test begins with genuine native component captures"):
		await _dispose(donor)
		return
	pack.actor.actor.body_yaw = 0.5 # Cosmetic prospective field only; HP/phase unchanged.
	var wire: String = ExactJson.stringify(pack)
	var decoded: Dictionary = ExactJson.parse(wire)
	if not _expect(not wire.is_empty() and decoded.get("accepted", false) and ExactJson.stringify(decoded.value) == wire, "prospective idle heading preserves exact component transport"):
		await _dispose(donor)
		return
	var saved: Dictionary = decoded.value
	await _dispose(donor)
	paused = true
	var receiver: Dictionary = _create()
	var hero: CinderPlayer = receiver.hero
	var actor: Node3D = receiver.actor
	var cue: CinderInteractionCue = receiver.cue
	var quiet: Array[String] = _watch(receiver)
	_expect(hero.snapshot_error(saved.player).is_empty() and String(actor.call("snapshot_error", saved.actor)).is_empty(), "fresh actual recipient purely preflights prospective idle tuple")
	_expect(hero.restore_state(saved.player) and bool(actor.call("restore_state", saved.actor)), "fresh quiet commit restores actual Player before actor")
	_expect(_same(hero.snapshot_state(), saved.player) and _same(actor.call("snapshot_state"), saved.actor) and actor.get_node("ScoutRig").call("get_body_yaw") == 0.5 and quiet.is_empty(), "accepted idle heading remains exactly 0.5 rather than directional redraw, with no events")
	_expect(bool(actor.call("restore_state", saved.actor)) and bool(actor.call("restore_state", saved.actor)) and _same(actor.call("snapshot_state"), saved.actor) and quiet.is_empty(), "repeated prospective quiet actor restore remains exact and silent")
	var source: Dictionary = actor.call("source_snapshot_state")
	var prospective: Dictionary = source.duplicate(true)
	prospective.phase_pending = true
	prospective.opening_state = "spent"
	_expect(not source.is_empty() and String(actor.call("source_snapshot_error", prospective)).is_empty() and _same(actor.call("source_snapshot_state"), source), "prospective source shape is pure and does not replace aggregate HP/cue correspondence")
	var malformed: Dictionary = saved.actor.duplicate(true)
	malformed["extra"] = true
	_atomic_refusal(receiver, malformed, quiet, "extra wrapper key")
	malformed = saved.actor.duplicate(true)
	malformed.erase("actor")
	_atomic_refusal(receiver, malformed, quiet, "missing actor")
	malformed = saved.actor.duplicate(true)
	malformed.boss_phase = 3
	_atomic_refusal(receiver, malformed, quiet, "unknown boss phase")
	malformed = saved.actor.duplicate(true)
	malformed.transition_pending = true
	_atomic_refusal(receiver, malformed, quiet, "pending first pool above threshold")
	malformed = saved.actor.duplicate(true)
	malformed.actor.hp = 15.0
	_atomic_refusal(receiver, malformed, quiet, "threshold without pending flag")
	malformed = saved.actor.duplicate(true)
	malformed.actor.hp = 14.0
	_atomic_refusal(receiver, malformed, quiet, "first pool below boundary")
	malformed = saved.actor.duplicate(true)
	malformed.boss_phase = 2
	_atomic_refusal(receiver, malformed, quiet, "second pool refilling above 15")
	malformed = saved.actor.duplicate(true)
	malformed.actor.max_hp = 31.0
	_atomic_refusal(receiver, malformed, quiet, "changed finite total")
	malformed = saved.actor.duplicate(true)
	malformed.actor.hp = NAN
	_atomic_refusal(receiver, malformed, quiet, "nonfinite health")
	malformed = saved.actor.duplicate(true)
	malformed.actor.body_yaw = INF
	_atomic_refusal(receiver, malformed, quiet, "nonfinite heading")
	malformed = saved.actor.duplicate(true)
	malformed.actor.root_position[0] = float(malformed.actor.root_position[0]) + 0.125
	_atomic_refusal(receiver, malformed, quiet, "changed immutable anchor")
	prospective = source.duplicate(true)
	prospective.defeated = true
	prospective.phase_pending = true
	prospective.opening_state = "spent"
	_expect(not String(actor.call("source_snapshot_error", prospective)).is_empty() and _same(actor.call("source_snapshot_state"), source) and _same(cue.state(), {"api_revision": "interaction-cue-1", "state": "clear", "trigger": "attack", "required": true, "visible": false}), "contradictory source flags refuse without native projection/cue mutation")
	await _dispose(receiver)

func _cue_loss_checks() -> void:
	var fixture: Dictionary = _create()
	var hero: CinderPlayer = fixture.hero
	var actor: Node3D = fixture.actor
	var cue: CinderInteractionCue = fixture.cue
	if not _expect(await _wait_ready(hero) and bool(actor.call("present_phase", "recovery", 0.25, Vector3.BACK)) and cue.present("available", "attack"), "cue-loss fixture exposes actual isolated recovery"):
		await _dispose(fixture)
		return
	var projection: Dictionary = actor.call("source_snapshot_state")
	var retired_cue: WeakRef = weakref(cue)
	cue.queue_free()
	_expect(actor.call("source_snapshot_state").is_empty() and not String(actor.call("source_snapshot_error", projection)).is_empty(), "queued actual parent cue immediately closes source projection")
	_expect(hero.slash(Vector3.FORWARD) == 0 and actor.get("hp") == 30.0 and fixture.gate_views.size() == 1 and fixture.gate_views[0].is_empty(), "real primary cannot damage recovery through lost required cue")
	await process_frame
	await process_frame
	_expect(retired_cue.get_ref() == null and actor.call("source_snapshot_state").is_empty(), "freed parent cue cannot be retained or regenerated by actor")
	actor.call("cleanup")
	_expect(not bool(actor.call("is_armed")) and actor.call("source_snapshot_state").is_empty() and not bool(actor.call("configure", hero, fixture.effects, ACTOR_ID)), "disarm permanently retires actor context without a refill or source resurrection")
	paused = true
	await process_frame
	_expect(actor.call("snapshot_state").is_empty() and not String(actor.call("snapshot_error", {})).is_empty() and not bool(actor.call("restore_state", {})), "retired actor refuses capture/preflight/restore at a paused boundary")
	await _dispose(fixture)

func _atomic_refusal(fixture: Dictionary, rejected: Dictionary, quiet: Array[String], label: String) -> void:
	var actor: Node3D = fixture.actor
	var hero: CinderPlayer = fixture.hero
	var cue: CinderInteractionCue = fixture.cue
	var before: Dictionary = {"actor": actor.call("snapshot_state"), "player": hero.snapshot_state(), "cue": cue.state()}
	var event_count: int = quiet.size()
	_expect(not String(actor.call("snapshot_error", rejected)).is_empty(), label + " preflight refuses")
	_expect(not bool(actor.call("restore_state", rejected)) and _same(actor.call("snapshot_state"), before.actor) and _same(hero.snapshot_state(), before.player) and _same(cue.state(), before.cue) and quiet.size() == event_count, label + " restore refuses atomically")

func _watch(fixture: Dictionary) -> Array[String]:
	var events: Array[String] = []
	var hero: CinderPlayer = fixture.hero
	var actor: Node3D = fixture.actor
	var cue: CinderInteractionCue = fixture.cue
	hero.world_action_executed.connect(func(_record: Dictionary) -> void: events.append("world-action"))
	hero.fired.connect(func(_kind: String) -> void: events.append("fired"))
	hero.action_resolved.connect(func(_kind: String, _hits: int, _damage: float) -> void: events.append("action"))
	hero.equipment_changed.connect(func(_id: String) -> void: events.append("equipment"))
	hero.died.connect(func() -> void: events.append("hero-death"))
	actor.connect("phase_boundary_reached", func(_id: String) -> void: events.append("threshold"))
	actor.connect("defeated", func(_id: String) -> void: events.append("defeat"))
	cue.state_changed.connect(func(_state: Dictionary) -> void: events.append("cue"))
	return events

func _wait_ready(hero: CinderPlayer) -> bool:
	for _index: int in range(MAX_TICKS):
		var response: Dictionary = hero.get_threat_response_state()
		if response.get("stable", false) and response.motion.get("grounded", false) and not hero.action_in_progress() and float(response.primary_cooldown_left_s) == 0.0:
			return true
		await physics_frame
		await process_frame
	return false

func _contains_collision(node: Node) -> bool:
	if node is CollisionObject3D or node is CollisionShape3D: return true
	for child: Node in node.get_children():
		if _contains_collision(child): return true
	return false

func _dispose(fixture: Dictionary) -> void:
	paused = false
	var actor: Node3D = fixture.actor
	actor.call("cleanup")
	var effects: PixelEffects = fixture.effects
	effects.clear()
	var retired_viewport: WeakRef = weakref(fixture.viewport)
	var retired_world: WeakRef = weakref(fixture.world)
	var retired_hero: WeakRef = weakref(fixture.hero)
	var retired_actor: WeakRef = weakref(actor)
	fixture.viewport.queue_free()
	await process_frame
	await process_frame
	_expect(retired_viewport.get_ref() == null and retired_world.get_ref() == null and retired_hero.get_ref() == null and retired_actor.get_ref() == null and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "whole fixture releases bound Player/actor/cue/effects and leaves no stale target groups")

func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = ExactJson.stringify(left)
	return not encoded.is_empty() and encoded == ExactJson.stringify(right)

func _expect(condition: bool, description: String) -> bool:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
	return condition
