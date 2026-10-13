extends SceneTree
## TEST ONLY native persistent B05 ray component. No recognizer, camera, Foot,
## whole B05/level/checkpoint/sequence, balance or production-art credit.
## Actual Player/controller, Sentry greybox, bait, Scheduler and parent joint
## cue; authored transforms/equipment precede entry. No live HP/phase/clock/
## motion/receipt seed. Fixture parent poses source and owns ONE ray-only gate
## and cue policy; production parent must combine Ray AND Foot instead.
## Authoring baseline: ray d6bbcc1f35f45b4ac32226f898d924350e3b01543f28f44cf15cade7b75a3ff1,
## actor ffaf6c671894715995f03fa5d2c1f54ea6b2bf720a118fb0a8b97a2269b67b5d,
## bait 9ae1b065521e1d521025d0f90fc941aa0f19867851ddc3eaa632432147d94808.
## Complete component packet includes Player/bait/actor/joint cue/Scheduler/ray;
## Effects is a fresh actual context, with no prior active effects in the saved
## pending-ray case. This is not whole Game/effects-policy transport evidence.
const PlayerScript: Script = preload("res://scripts/player.gd")
const EffectsScript: Script = preload("res://scripts/effects.gd")
const ActorScript: Script = preload("res://scripts/acts/act2/dead_london_sentry_actor.gd")
const BaitScript: Script = preload("res://scripts/acts/act2/dead_london_bait.gd")
const RayScript: Script = preload("res://scripts/acts/act2/dead_london_ray_exchange.gd")
const SchedulerScript: Script = preload("res://scripts/combat/threat_scheduler.gd")
const JointCueScript: Script = preload("res://scripts/cues/interaction_cue.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson: Script = preload("res://scripts/campaign/exact_json.gd")
const Geometry: Script = preload("res://scripts/combat/threat_geometry.gd")
const SOURCE_ID: String = "TEST:A2-L5:sentry-ray-joint"
const ENCOUNTER_ID: String = "TEST:A2-L5:persistent-ray"
const PACK_KEYS: Array[String] = ["player", "bait", "actor", "joint_cue", "scheduler", "ray"]
const MAX_TICKS: int = 480
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
	await _immutable_bait_cycles()
	await _pending_path_fresh_transport()
	paused = false
	print("A2-L5 isolated persistent Sentry ray smoke: %d checks, %d failures; actual admission/full lock/immutable bait/pending component transport only; no Foot, recognizer, camera, full B05/level/checkpoint, balance or art credit" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _create() -> Dictionary:
	_fixtures += 1
	var viewport := SubViewport.new()
	viewport.name = "TEST_ONLY_SentryRay%d" % _fixtures
	viewport.size = Vector2i(540, 1170)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	var world := Node3D.new()
	world.name = "NativeRayWorld"
	viewport.add_child(world)
	var floor := StaticBody3D.new()
	floor.name = "AuthoredDryFloor"
	floor.collision_layer = 1
	floor.collision_mask = 0
	floor.position = Vector3(0, -0.5, 0)
	var support := CollisionShape3D.new()
	support.name = "DrySupport"
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	support.shape = box
	floor.add_child(support)
	world.add_child(floor)
	var effects: PixelEffects = EffectsScript.new()
	effects.name = "SharedEffects"
	world.add_child(effects)
	var hero: CinderPlayer = PlayerScript.new()
	hero.name = "SharedPlayer"
	hero.position = Vector3(0, 0.02, 3)
	_expect(hero.equipment.equip("WEAPON-03"), "pre-entry canonical Heavy ordinary-primary fixture equipment")
	hero.fx = effects
	world.add_child(hero)
	var actor: Node3D = ActorScript.new() as Node3D
	actor.name = "PersistentSentryLowJoint"
	actor.position = Vector3.ZERO
	world.add_child(actor)
	var joint: CinderInteractionCue = JointCueScript.new()
	joint.name = "ActualParentJointCue"
	joint.position = Vector3.ZERO
	world.add_child(joint)
	var scheduler: CinderThreatScheduler = SchedulerScript.new()
	scheduler.name = "SharedScheduler"
	world.add_child(scheduler)
	_expect(scheduler.begin_encounter("standard", ENCOUNTER_ID, 1), "parent begins one real Standard encounter held across both test cycles")
	var bait: RefCounted = BaitScript.new()
	_expect(bool(bait.call("bind", hero)), "bait binds the actual ready native Player without seeding an unfinished landing")
	var consumed: Array[bool] = []
	var action_callback: Callable = func(record: Dictionary) -> void: consumed.append(bool(bait.call("observe_record", record)))
	hero.world_action_executed.connect(action_callback)
	_expect(bool(actor.call("configure", hero, effects, SOURCE_ID)) and bool(actor.call("bind_joint_cue", joint)), "one persistent actual Sentry binds shared context and actual parent-owned cue")
	var region: Dictionary = {"collision": support, "safe_rect": Rect2(-9.998, -9.998, 19.996, 19.996)}
	var directions: Array[Vector3] = []
	for index: int in range(16): directions.append(Vector3(sin(float(index) * TAU / 16.0), 0, cos(float(index) * TAU / 16.0)).normalized())
	var context: Dictionary = {"encounter_id": ENCOUNTER_ID, "world_revision": 1, "recognition_s": 0.30, "attack_input_margin_s": 0.03, "escape_directions": directions.duplicate(), "return_directions": directions.duplicate(), "floor_regions": [region]}
	var ray: Node3D = RayScript.new() as Node3D
	ray.name = "PersistentRayDriver"
	world.add_child(ray)
	var configured: bool = bool(ray.call("configure", hero, scheduler, actor, bait, joint, "standard", context))
	_expect(configured, "ray configures once with persistent source/cue and actual floor bindings")
	var probe := NativeTickProbe.new()
	probe.name = "TEST_OnlyNativeTickBarrier"
	world.add_child(probe)
	var hits: Array[Dictionary] = []
	var fixture: Dictionary = {"viewport": viewport, "world": world, "hero": hero, "actor": actor, "joint": joint, "scheduler": scheduler, "bait": bait, "ray": ray, "effects": effects, "probe": probe, "context": context, "configured": configured, "consumed": consumed, "action_callback": action_callback, "hits": hits, "bindings": {"world_root": world, "owners": {SOURCE_ID: actor}, "floors": {"dry-floor": region}}}
	if configured:
		# Parent first: external pause observers see the actual source pose and
		# composite cue policy synchronized to this publication, not next tick.
		ray.connect("state_changed", func(_id: String, state: Dictionary) -> void: _sync_parent(fixture, state))
		ray.connect("hit_resolved", func(_id: String, result: Dictionary) -> void: hits.append(result.duplicate(true)))
		var gate: Callable = func() -> bool:
			var source: Dictionary = actor.call("source_snapshot_state")
			return not paused and not source.is_empty() and source.armed and not source.phase_pending and not source.defeated and source.opening_state in ["available", "active"] and bool(ray.call("recovery_window_open"))
		fixture.gate = gate
		_expect(bool(actor.call("bind_damage_window", gate)), "fixture parent alone binds its explicit isolated ray-recovery gate")
		actor.connect("phase_boundary_reached", func(_id: String) -> void:
			joint.present("spent", "attack")
			ray.call("cancel", "test_parent_brace_spent")
		)
		actor.connect("defeated", func(_id: String) -> void:
			joint.present("spent", "attack")
			ray.call("source_defeated")
		)
	return fixture

func _sync_parent(fixture: Dictionary, state: Dictionary) -> void:
	if state.is_empty(): return
	var actor: Node3D = fixture.actor
	var joint: CinderInteractionCue = fixture.joint
	if bool(actor.get("transition_pending")) or float(actor.get("hp")) <= 0.0:
		joint.present("spent", "attack")
		return
	var phase: String = "idle" if state.phase == "clear" else String(state.phase)
	_expect(bool(actor.call("present_phase", phase, float(state.phase_progress), state.direction, false)), "parent source pose follows actual ray phase and returned normalized clock")
	if bool(fixture.ray.call("recovery_window_open")):
		_expect(joint.present("available", "attack"), "parent exposes its isolated actual ray recovery")
	else:
		_expect(joint.clear(), "parent keeps joint unavailable outside actual recovery")

func _begin(fixture: Dictionary) -> bool:
	if not fixture.configured: return false
	for _index: int in range(MAX_TICKS):
		var response: Dictionary = fixture.hero.get_threat_response_state()
		if response.stable and response.motion.grounded and not fixture.hero.action_in_progress():
			return bool(fixture.bait.call("begin_boundary", "sentry-entry"))
		await _step(fixture)
	return false

func _immutable_bait_cycles() -> void:
	var fixture: Dictionary = _create()
	if not _expect(await _begin(fixture), "initial bait seeds only actual stable supported native floor"):
		await _dispose(fixture)
		return
	var hero: CinderPlayer = fixture.hero
	var ray: Node3D = fixture.ray
	var actor: Node3D = fixture.actor
	var scheduler: CinderThreatScheduler = fixture.scheduler
	var source_native: int = actor.get_instance_id()
	var cue_native: int = ray.call("get_cue").get_instance_id()
	var hp: float = hero.hp
	var answer: Dictionary = ray.call("activate")
	if not _expect(answer.get("accepted", false) and not answer.get("armed", true), "real request_tracking admits unarmed warning"):
		push_error(str(answer))
		await _dispose(fixture)
		return
	var admitted: Dictionary = ray.call("state")
	var shape: Dictionary = admitted.geometry.duplicate(true)
	var sample: Dictionary = admitted.bait_sample.duplicate(true)
	_expect(sample.dash_sequence == 0 and sample.receipt == null and shape == Geometry.lane(actor.global_position, actor.global_position + Vector3.BACK * 3.8, 0.31) and ray.call("get_cue").state().geometry == shape, "initial physical-floor sample defines the actual source/capsule/endcaps and required cue")
	_expect(not bool(ray.call("recovery_window_open")) and fixture.joint.state().state == "clear" and actor.get("phase") == "warning", "parent does not expose a warning opening")
	_expect(hero.request_dash(Vector3(0.4, 0, -sqrt(0.84))), "actual public diagonal dash is accepted during unarmed warning")
	if not _expect(await _until(fixture, func() -> bool: return hero.get_world_action_records().size() == 1), "later native dash completes and publishes an actual receipt"):
		await _dispose(fixture)
		return
	var dash: Dictionary = hero.get_world_action_records()[0]
	var current_bait: Dictionary = fixture.bait.call("sample_for_ray")
	_expect(dash.kind == "dash" and fixture.consumed == [true] and current_bait.dash_sequence == dash.sequence and current_bait.point == Vector3(dash.landing.x, 0, dash.landing.z), "bound observer consumes exact completed world-space landing")
	_expect(current_bait.point != sample.point and ray.call("state").bait_sample == sample and ray.call("state").geometry == shape, "later completed dash changes cache but cannot resample the admitted ray")
	if not _expect(await _until(fixture, func() -> bool: return String(ray.call("state").phase) == "lock"), "fresh actual response commits a proved lock after movement settles"):
		push_error(str(ray.call("state")))
		await _dispose(fixture)
		return
	var locked: Dictionary = ray.call("state")
	_expect(locked.armed and locked.geometry == shape and locked.bait_sample == sample and float(RayScript.RAW_ROLE.lock_s) == 1.10 and locked.exchange.active_from_s == locked.exchange.lock_from_s + float(RayScript.RAW_ROLE.lock_s) and locked.proof_available and locked.proof.accepted, "actual commit preserves immutable bait and FULL returned 1.10 lock")
	_expect(hero.hp == hp and float(actor.get("hp")) == 30.0 and not bool(ray.call("recovery_window_open")), "neither early ray damage nor HP/resource/brace progression is fabricated")
	if not _expect(await _until(fixture, func() -> bool: return String(ray.call("state").status) == "complete"), "original active/recovery self-completes through native ticks"):
		await _dispose(fixture)
		return
	_expect(hero.hp == hp and fixture.hits.is_empty() and scheduler.reservations().is_empty(), "actual completed diagonal landing stays outside first immutable ray")
	answer = ray.call("activate")
	if not _expect(answer.get("accepted", false) and not answer.get("armed", true), "same persistent owner admits next cycle only after original lease/cooldown release"):
		push_error(str(answer))
		await _dispose(fixture)
		return
	var next: Dictionary = ray.call("state")
	_expect(next.cycle == 2 and next.bait_sample.dash_sequence == dash.sequence and next.bait_sample.point == current_bait.point and next.bait_sample.receipt == PlayerScript.encode_world_action_record(dash, hero.get_world_action_clock()) and next.geometry != shape and sample.receipt == null, "next real cycle samples latest completed receipt while earlier sampled copy stays immutable")
	_expect(actor.get_instance_id() == source_native and ray.call("get_cue").get_instance_id() == cue_native, "both cycles retain exact persistent native source and single threat cue")
	_expect(bool(ray.call("cancel", "test_second_sample_complete")), "public cancellation releases second unarmed danger with original cooldown")
	_expect(hero.slash(actor.global_position - hero.global_position) == 0, "real primary while parent opening is closed publishes no accepted joint damage")
	paused = true
	await process_frame
	var pack: Dictionary = _capture(fixture)
	_expect(_packet_error(fixture, pack).is_empty() and _round_trip(pack) == pack and pack.ray.record.status == "cancelled" and pack.ray.record.bait_sample.last_sequence < pack.bait.last_sequence and float(pack.actor.actor.hp) == 30.0, "cancelled second cycle preserves sampled dash beside later primary cursor in exact component transport")
	await _dispose(fixture)

func _pending_path_fresh_transport() -> void:
	var donor: Dictionary = _create()
	if not _expect(await _begin(donor), "pending donor first earns supported native floor seed"):
		await _dispose(donor)
		return
	var observed: Array[bool] = [false]
	var callback_refusal: Array[bool] = []
	donor.ray.connect("state_changed", func(_id: String, state: Dictionary) -> void:
		if state.phase == "active" and not observed[0]:
			observed[0] = true
			paused = true
			callback_refusal.append(donor.ray.call("snapshot_state", donor.bindings).is_empty())
	)
	var answer: Dictionary = donor.ray.call("activate")
	if not _expect(answer.get("accepted", false) and await _until(donor, func() -> bool: return observed[0]), "actual first-active publication synchronously pauses after parent pose/cue synchronization"):
		push_error(str(donor.ray.call("state")))
		await _dispose(donor)
		return
	await process_frame # Original ray/Scheduler/Player/cue callbacks have returned.
	var original: Dictionary = _capture(donor)
	if not _expect(callback_refusal == [true] and _packet_error(donor, original).is_empty() and not original.ray.record.deferred_paths.is_empty() and not original.ray.record.hit_consumed and original.ray.record.phase == "active", "genuine paused ray retains exact measured active path outside callback capture"):
		push_error(str(donor.ray.get("last_snapshot_error")))
		await _dispose(donor)
		return
	var measured: Array[Dictionary] = []
	for item: Dictionary in original.ray.record.deferred_paths:
		measured.append({"from": Codec.read_vector3(item["from"]), "to": Codec.read_vector3(item["to"]), "start_s": item.start_s, "end_s": item.end_s})
	var shape: Dictionary = Geometry.lane(Codec.read_vector3(original.ray.record.exchange.geometry["from"]), Codec.read_vector3(original.ray.record.exchange.geometry["to"]), float(original.ray.record.exchange.geometry.radius))
	_expect(Geometry.timed_path_hits(shape, measured, float(original.ray.record.exchange.active_from_s), float(original.ray.record.exchange.active_until_s), SchedulerScript.CAPSULE_RADIUS) and donor.hero.hp == 100.0 and donor.hits.is_empty(), "retained actual stationary capsule path intersects ray but no opportunity resolves while paused")
	var frozen_clock: float = donor.scheduler.get_clock()
	await process_frame
	await process_frame
	_expect(donor.scheduler.get_clock() == frozen_clock and _same(_capture(donor), original), "pause freezes complete native clock/sample/receipt/pose tuple")
	var saved: Dictionary = _round_trip(original)
	if not _expect(not saved.is_empty() and _same(saved, original), "complete pending component packet round-trips full-precision ExactJson"):
		await _dispose(donor)
		return
	await _dispose(donor)
	paused = true
	var receiver: Dictionary = _create()
	await process_frame
	var quiet: Array[String] = _watch(receiver)
	_expect(_packet_error(receiver, saved).is_empty(), "fresh recipient purely validates whole staged Player/bait/actor/cue/Scheduler/ray without comparing fresh phase")
	if not _expect(receiver.scheduler.restore_state(saved.scheduler, receiver.bindings), "isolated wrong-order probe stages actual saved Scheduler before ray commit"):
		await _dispose(receiver)
		return
	var before: Dictionary = _native_view(receiver)
	_expect(not bool(receiver.ray.call("restore_state", saved.ray, receiver.bindings, saved.player, saved.bait)) and _same(_native_view(receiver), before) and quiet.is_empty(), "actual ray commit refuses fresh-before-Player atomically with same paired native Scheduler")
	_expect(receiver.hero.restore_state(saved.player), "public Player restores exact native pending barrier first")
	before = _native_view(receiver)
	_expect(not bool(receiver.ray.call("restore_state", saved.ray, receiver.bindings, saved.player, saved.bait)) and _same(_native_view(receiver), before) and quiet.is_empty(), "actual ray commit refuses before bound bait restoration without mutation")
	_expect(bool(receiver.bait.call("restore_state", saved.bait, saved.player)), "public bait restore checks actual restored full native Player")
	before = _native_view(receiver)
	_expect(not _commit_driver_after_parent(receiver, saved) and _same(_native_view(receiver), before) and quiet.is_empty(), "fixture whole-parent actor check refuses before actual full pose/cue restore; flat source alone is insufficient")
	if not _expect(_restore_packet(receiver, saved), "quiet complete commit follows actual Player/bait/whole actor+cue -> Scheduler -> persistent ray order"):
		push_error(str(receiver.ray.get("last_snapshot_error")))
		await _dispose(receiver)
		return
	_expect(_same(_capture(receiver), saved) and quiet.is_empty() and receiver.hits.is_empty(), "fresh quiet receiver retains every complete nested field, measured path and copied cooldown without events")
	var malformed: Dictionary = saved.duplicate(true)
	malformed.ray.clock_s += 0.001
	_atomic_refusal(receiver, malformed, quiet, "mismatched copied ray/Scheduler clock")
	malformed = saved.duplicate(true)
	malformed.ray.record.bait_sample.dash_sequence = 1
	_atomic_refusal(receiver, malformed, quiet, "invented future completed bait")
	malformed = saved.duplicate(true)
	malformed.ray.record.deferred_paths[0].end_s += 0.1
	_atomic_refusal(receiver, malformed, quiet, "deferred path later than actual paused sample")
	malformed = saved.duplicate(true)
	malformed.actor.actor.phase = "warning"
	_atomic_refusal(receiver, malformed, quiet, "staged complete actor pose disagrees with ray")
	var hp_before: float = receiver.hero.hp
	var damage: float = float(saved.ray.configuration.resolved_role.damage)
	var expected_loss: float = receiver.hero.equipment.damage_received(damage)
	var cooldown: float = float(saved.ray.record.exchange.cooldown_until_s)
	paused = false
	await _step(receiver)
	_expect(receiver.hits.size() == 1 and receiver.hits[0].opportunity_consumed and receiver.hits[0].accepted and receiver.hits[0].raw_damage == damage and receiver.hits[0].hp_damage == expected_loss and receiver.hero.hp == hp_before - expected_loss and receiver.ray.call("state").hit_consumed, "resume resolves real retained active path exactly once through actual shared hurt")
	for _index: int in range(16): await _step(receiver)
	_expect(receiver.hits.size() == 1 and receiver.hero.hp == hp_before - expected_loss and receiver.ray.call("state").exchange.cooldown_until_s == cooldown and receiver.ray.call("state").phase == "recovery" and bool(receiver.ray.call("recovery_window_open")) and receiver.joint.state().state == "available", "continued real ticks cannot repeat hit/refresh cooldown and expose actual parent recovery")
	paused = true
	await process_frame
	var resumed: Dictionary = _capture(receiver)
	_expect(_packet_error(receiver, resumed).is_empty() and resumed.ray.record.deferred_paths.is_empty() and resumed.ray.record.hit_consumed and resumed.actor.actor.hp == 30.0, "post-resume component capture consumes pending path without fabricated brace damage")
	await _dispose(receiver)

func _capture(fixture: Dictionary) -> Dictionary:
	return {"player": fixture.hero.snapshot_state(), "bait": fixture.bait.call("state"), "actor": fixture.actor.call("snapshot_state"), "joint_cue": fixture.joint.state(), "scheduler": fixture.scheduler.snapshot_state(fixture.bindings), "ray": fixture.ray.call("snapshot_state", fixture.bindings)}

func _packet_error(fixture: Dictionary, pack: Dictionary) -> String:
	var error: String = Codec.value_error(pack)
	if error.is_empty(): error = Codec.keys_error(pack, PACK_KEYS)
	if not error.is_empty(): return error
	for key: String in PACK_KEYS:
		if not pack[key] is Dictionary or pack[key].is_empty(): return "Missing actual complete component: " + key
	error = fixture.hero.snapshot_error(pack.player)
	if error.is_empty(): error = String(fixture.bait.call("snapshot_error", pack.bait, pack.player))
	if error.is_empty(): error = String(fixture.actor.call("snapshot_error", pack.actor))
	if error.is_empty(): error = fixture.scheduler.snapshot_error(pack.scheduler, fixture.bindings)
	if error.is_empty(): error = String(fixture.ray.call("snapshot_error", pack.ray, fixture.bindings, pack.scheduler, pack.player, pack.bait))
	if not error.is_empty(): return error
	var cue: Dictionary = pack.joint_cue
	if not Codec.keys_error(cue, ["api_revision", "state", "trigger", "required", "visible"]).is_empty() or cue.api_revision != "interaction-cue-1" or cue.trigger != "attack" or cue.required != true or not cue.visible is bool or cue.state not in ["clear", "available", "active", "spent"] or cue.visible != (cue.state != "clear"): return "Invalid complete parent joint cue"
	var record: Dictionary = pack.ray.record
	var actor: Dictionary = pack.actor.actor
	var phase: String = "idle" if record.phase == "clear" else String(record.phase)
	if pack.actor.boss_phase != 1 or pack.actor.transition_pending or actor.hp != 30.0 or pack.bait.boundary != "sentry-entry" or actor.phase != phase or not _same(actor.direction, Codec.vector3(Codec.read_vector3(record.direction).normalized())) or actor.phase_progress != _saved_progress(pack.ray): return "This isolated ray packet requires its full unchanged first-pool source/pose/bait tuple"
	var expected_opening: String = "available" if record.status == "running" and record.phase == "recovery" else "clear"
	if cue.state != expected_opening: return "Actual isolated parent cue policy differs from native ray recovery"
	var flat: Dictionary = {"api_revision": ActorScript.SOURCE_API, "source_id": actor.actor_id, "root_position": actor.root_position, "armed": true, "phase_pending": pack.actor.transition_pending, "defeated": actor.hp <= 0.0, "opening_state": cue.state}
	return "" if _same(pack.ray.source, flat) and fixture.joint.global_position == fixture.actor.global_position else "Flat view is not the complete staged actor and actual authored parent cue"

func _saved_progress(ray: Dictionary) -> float:
	var record: Dictionary = ray.record
	var keys: Array = {"warning": ["start_s", "lock_from_s"], "lock": ["lock_from_s", "active_from_s"], "active": ["active_from_s", "active_until_s"], "recovery": ["active_until_s", "recovery_until_s"]}.get(record.phase, [])
	return 0.0 if record.status != "running" or keys.is_empty() else clampf((float(ray.clock_s) - float(record.exchange[keys[0]])) / (float(record.exchange[keys[1]]) - float(record.exchange[keys[0]])), 0.0, 1.0)

func _restore_packet(fixture: Dictionary, pack: Dictionary) -> bool:
	if not _packet_error(fixture, pack).is_empty(): return false
	if not fixture.hero.restore_state(pack.player) or not bool(fixture.bait.call("restore_state", pack.bait, pack.player)) or not bool(fixture.actor.call("restore_state", pack.actor)): return false
	var joint: CinderInteractionCue = fixture.joint
	var blocked: bool = joint.is_blocking_signals()
	joint.set_block_signals(true)
	var presented: bool = joint.clear() if pack.joint_cue.state == "clear" else joint.present(pack.joint_cue.state, "attack")
	joint.set_block_signals(blocked)
	return presented and fixture.scheduler.restore_state(pack.scheduler, fixture.bindings) and _commit_driver_after_parent(fixture, pack)

func _commit_driver_after_parent(fixture: Dictionary, pack: Dictionary) -> bool:
	# Test parent, not a new shared controller: flat source doesn't encode the
	# complete pose. Actual full native actor/cue must precede driver authority.
	return _same(fixture.actor.call("snapshot_state"), pack.actor) and _same(fixture.joint.state(), pack.joint_cue) and bool(fixture.ray.call("restore_state", pack.ray, fixture.bindings, pack.player, pack.bait))

func _native_view(fixture: Dictionary) -> Dictionary:
	# Ray.state has native vectors and no pending-path copy: use it only as a
	# defensive before/after view here. Exact component capture needs real lease.
	return {"player": fixture.hero.snapshot_state(), "bait": fixture.bait.call("state"), "actor": fixture.actor.call("snapshot_state"), "joint_cue": fixture.joint.state(), "scheduler": fixture.scheduler.snapshot_state(fixture.bindings), "ray": fixture.ray.call("state")}

func _atomic_refusal(fixture: Dictionary, rejected: Dictionary, quiet: Array[String], label: String) -> void:
	var before: Dictionary = _capture(fixture)
	var count: int = quiet.size()
	_expect(not _packet_error(fixture, rejected).is_empty(), label + " complete pure preflight refuses")
	_expect(not _restore_packet(fixture, rejected) and _same(_capture(fixture), before) and quiet.size() == count, label + " rejects before any native mutation or publication")

func _watch(fixture: Dictionary) -> Array[String]:
	var events: Array[String] = []
	fixture.hero.world_action_executed.connect(func(_record: Dictionary) -> void: events.append("world-action"))
	fixture.hero.fired.connect(func(_kind: String) -> void: events.append("fired"))
	fixture.hero.action_resolved.connect(func(_kind: String, _hits: int, _damage: float) -> void: events.append("action"))
	fixture.hero.equipment_changed.connect(func(_id: String) -> void: events.append("equipment"))
	fixture.hero.died.connect(func() -> void: events.append("hero-death"))
	fixture.actor.connect("phase_boundary_reached", func(_id: String) -> void: events.append("brace"))
	fixture.actor.connect("defeated", func(_id: String) -> void: events.append("defeat"))
	fixture.joint.state_changed.connect(func(_state: Dictionary) -> void: events.append("joint-cue"))
	fixture.ray.call("get_cue").state_changed.connect(func(_state: Dictionary) -> void: events.append("threat-cue"))
	fixture.ray.connect("state_changed", func(_id: String, _state: Dictionary) -> void: events.append("ray-state"))
	fixture.ray.connect("hit_resolved", func(_id: String, _result: Dictionary) -> void: events.append("ray-hit"))
	fixture.scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: events.append("invalidated"))
	return events

func _round_trip(value: Dictionary) -> Dictionary:
	var wire: String = ExactJson.stringify(value)
	var decoded: Dictionary = ExactJson.parse(wire)
	return decoded.value if not wire.is_empty() and decoded.get("accepted", false) and ExactJson.stringify(decoded.value) == wire else {}

func _same(left: Variant, right: Variant) -> bool:
	# ExactJson deliberately excludes native Vector3. Actual native diagnostic
	# state below uses strict recursive native equality, never empty==empty.
	var encoded: String = ExactJson.stringify(left)
	if not encoded.is_empty(): return encoded == ExactJson.stringify(right)
	return _native_equal(left, right)

func _native_equal(left: Variant, right: Variant) -> bool:
	if typeof(left) != typeof(right): return false
	if left is Dictionary:
		if left.size() != right.size(): return false
		for key: Variant in left:
			if not right.has(key) or not _native_equal(left[key], right[key]): return false
		return true
	if left is Array:
		if left.size() != right.size(): return false
		for index: int in range(left.size()):
			if not _native_equal(left[index], right[index]): return false
		return true
	return left == right

func _until(fixture: Dictionary, predicate: Callable) -> bool:
	for _index: int in range(MAX_TICKS):
		if bool(predicate.call()): return true
		await _step(fixture)
	return false

func _step(fixture: Dictionary) -> void:
	await (fixture.probe as NativeTickProbe).tick_finished
	await process_frame

func _dispose(fixture: Dictionary) -> void:
	var hero: Variant = fixture.hero
	var nodes: Array[WeakRef] = [weakref(fixture.world), weakref(fixture.hero), weakref(fixture.actor), weakref(fixture.scheduler), weakref(fixture.ray), weakref(fixture.joint)]
	if fixture.configured:
		var cue: Variant = fixture.ray.call("get_cue")
		if is_instance_valid(cue): nodes.append(weakref(cue))
		fixture.ray.call("cleanup")
		_expect(fixture.ray.call("state").is_empty() and fixture.ray.call("snapshot_state", fixture.bindings).is_empty() and not bool(fixture.ray.call("activate").get("accepted", false)), "driver cleanup permanently disarms and refuses new snapshot/admission")
	fixture.bait.call("release")
	if is_instance_valid(hero) and hero.world_action_executed.is_connected(fixture.action_callback): hero.world_action_executed.disconnect(fixture.action_callback)
	fixture.actor.call("cleanup")
	fixture.scheduler.end_encounter("test_component_disposal")
	fixture.viewport.queue_free()
	await process_frame
	await process_frame
	for ref: WeakRef in nodes: _expect(ref.get_ref() == null, "whole isolated native world/source/cues/driver bodies are freed")
	paused = false

func _expect(condition: bool, description: String) -> bool:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)
	return condition
