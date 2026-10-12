extends SceneTree
## TMP ONLY. Root owns reviewed promotion and the canonical dev.py engine job.
## Frozen codec V2 c1d1050c + Published41 guard; original552/d899 stays separate.
## Actual Standard pristine + first armed Ray, full three-owner/two-floor scope.
## Fresh paused recipient preflights synchronously before its first physics tick.
## Public native transport only; no live HP/phase/clock/receipt/transform seeding.
## No Shell checkpoint/Continue/Retry, whole level, camera/art or balance credit.
const ParentScript: Script = preload("res://scripts/acts/act2/dead_london_sentry_encounter.gd")
const PlayerScript: Script = preload("res://scripts/player.gd")
const EffectsScript: Script = preload("res://scripts/effects.gd")
const SchedulerScript: Script = preload("res://scripts/combat/threat_scheduler.gd")
const BaitScript: Script = preload("res://scripts/acts/act2/dead_london_bait.gd")
const ForeignActorScript: Script = preload("res://scripts/acts/act2/weybridge_scout_actor.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson: Script = preload("res://scripts/campaign/exact_json.gd")
const ENCOUNTER_ID: String = "TEST:A2-L5:parent-transport"
const FOREIGN_ID: String = "TEST:A2-L5:inactive-scout"
const HERO_AT: Vector3 = Vector3(0, 0.02, 1.5)
const FOREIGN_AT: Vector3 = Vector3(14, 0, 0)
const MAX_TICKS: int = 180

class NativeTickProbe:
	extends Node
	signal tick_finished
	var ticks: int = 0
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 120
	func _physics_process(_delta: float) -> void:
		ticks += 1
		tick_finished.emit()

var _checks: int = 0
var _failures: int = 0
var _worlds: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await _native_transport()
	paused = true
	for fixture: Dictionary in _worlds:
		if not fixture.disposed: await _dispose(fixture)
	_worlds.clear()
	paused = false
	print("A2-L5 native Sentry parent transport smoke: %d checks, %d failures; Standard pristine/first armed Ray, actual fresh quiet three-owner/two-floor transport and malformed atomic refusal only; no Shell checkpoint, whole level, camera/art or balance credit" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _create(profile: String) -> Dictionary:
	# All placement, names, geometry and loadout are authored before tree entry.
	var viewport := SubViewport.new()
	viewport.name = "TEST_OnlyParentTransport_%d" % (_worlds.size() + 1)
	viewport.size = Vector2i(540, 1170)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	var world := Node3D.new()
	world.name = "NativeTransportWorld"
	viewport.add_child(world)
	var first: Dictionary = _floor(world, "AuthoredMainFloor", Vector3(0, -0.5, 0), Vector3(20, 1, 20), Rect2(-9.998, -9.998, 19.996, 19.996))
	var second: Dictionary = _floor(world, "AuthoredForeignFloor", Vector3(14, -0.5, 0), Vector3(4, 1, 4), Rect2(12.002, -1.998, 3.996, 3.996))
	var floors: Dictionary = {"dry-floor": first, "foreign-floor": second}
	var effects: PixelEffects = EffectsScript.new()
	effects.name = "SharedEffects"
	world.add_child(effects)
	var hero: CinderPlayer = PlayerScript.new()
	hero.name = "SharedHero"
	hero.position = HERO_AT
	var heavy: bool = hero.equipment.equip("WEAPON-03")
	hero.fx = effects
	world.add_child(hero)
	var scheduler: CinderThreatScheduler = SchedulerScript.new()
	scheduler.name = "OneSharedScheduler"
	world.add_child(scheduler)
	var epoch: bool = scheduler.begin_encounter(profile, ENCOUNTER_ID, 1)
	var bait: RefCounted = BaitScript.new()
	var bait_bound: bool = bool(bait.call("bind", hero))
	var consumed: Array[bool] = []
	var action_callback: Callable = func(record: Dictionary) -> void: consumed.append(bool(bait.call("observe_record", record)))
	hero.world_action_executed.connect(action_callback)
	var foreign: Node3D = ForeignActorScript.new() as Node3D
	foreign.name = "InactiveForeignScout"
	foreign.position = FOREIGN_AT
	world.add_child(foreign)
	var foreign_bound: bool = bool(foreign.call("configure", hero, effects, FOREIGN_ID))
	var directions: Array[Vector3] = []
	for index: int in range(16): directions.append(Vector3(sin(float(index) * TAU / 16.0), 0, cos(float(index) * TAU / 16.0)).normalized())
	var context: Dictionary = {"encounter_id": ENCOUNTER_ID, "world_revision": 1, "recognition_s": 0.30, "attack_input_margin_s": 0.03, "escape_directions": directions.duplicate(), "return_directions": directions.duplicate(), "floor_regions": [first]}
	var parent: Node3D = ParentScript.new() as Node3D
	parent.name = "ActualB05TransportParent"
	world.add_child(parent)
	var guard: Callable = func(proposed: Dictionary) -> bool:
		for key: String in ["actor", "ray_cue", "foot_cue", "foot_visual", "joint", "hero"]:
			var node: Variant = proposed.get(key)
			if not is_instance_valid(node) or not node.is_inside_tree() or not node.is_node_ready() or node.is_queued_for_deletion() or not node.visible or node.get_world_3d() != world.get_world_3d(): return false
		return true # TEST_ONLY physical custody; no portrait framing acceptance.
	var configured: bool = bool(parent.call("configure", hero, effects, scheduler, bait, world, floors, context, Vector3.ZERO, Vector3.ZERO, guard))
	var owners: Dictionary = parent.call("owners")
	owners[FOREIGN_ID] = foreign
	var bindings: Dictionary = {"world_root": world, "owners": owners, "floors": floors}
	var scope: bool = configured and bool(parent.call("bind_transport_scope", bindings))
	var events: Array[String] = []
	var runtime_failures: Array[String] = []
	parent.connect("runtime_failed", func(reason: String) -> void: runtime_failures.append(reason))
	_watch(hero, "world_action_executed", events, "hero.world_action")
	_watch(hero, "action_resolved", events, "hero.action")
	_watch(hero, "fired", events, "hero.fired")
	_watch(hero, "died", events, "hero.died")
	_watch(hero, "equipment_changed", events, "hero.equipment")
	_watch(scheduler, "reservation_invalidated", events, "scheduler.invalidated")
	_watch(foreign, "defeated", events, "foreign.defeated")
	for signal_name: String in ["phase_checkpoint_eligible", "sentry_cleared", "hit_resolved", "runtime_failed"]: _watch(parent, signal_name, events, "parent." + signal_name)
	if configured:
		var ray: Node3D = parent.call("get_ray")
		var foot: CinderLaneMechanism = parent.call("get_foot")
		var actor: Node3D = parent.call("get_actor")
		for signal_name: String in ["state_changed", "hit_resolved"]:
			_watch(ray, signal_name, events, "ray." + signal_name)
			_watch(foot, signal_name, events, "foot." + signal_name)
		_watch(ray.call("get_cue"), "state_changed", events, "ray.cue")
		_watch(foot.get_cue(), "state_changed", events, "foot.cue")
		_watch(parent.call("get_joint_cue"), "state_changed", events, "joint.cue")
		_watch(actor, "phase_boundary_reached", events, "actor.threshold")
		_watch(actor, "defeated", events, "actor.defeated")
	var probe := NativeTickProbe.new()
	probe.name = "TEST_OnlyNativeTickBarrier"
	world.add_child(probe)
	var fixture: Dictionary = {"viewport": viewport, "world": world, "hero": hero, "effects": effects, "scheduler": scheduler, "bait": bait, "foreign": foreign, "parent": parent, "probe": probe, "bindings": bindings, "events": events, "runtime_failures": runtime_failures, "consumed": consumed, "action_callback": action_callback, "configured": heavy and epoch and bait_bound and foreign_bound and scope, "disposed": false}
	_worlds.append(fixture)
	return fixture

func _floor(world: Node3D, name_value: String, at: Vector3, size: Vector3, safe: Rect2) -> Dictionary:
	var body := StaticBody3D.new()
	body.name = name_value
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	shape.name = "AuthoredDryFloorShape"
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	world.add_child(body)
	return {"collision": shape, "safe_rect": safe}

func _watch(node: Object, signal_name: String, events: Array[String], label: String) -> void:
	# Explicit arity preserves real signal APIs; callbacks retain only strings.
	var count: int = 0
	for definition: Dictionary in node.get_signal_list():
		if definition.name == signal_name: count = definition.args.size()
	var callback: Callable
	match count:
		0: callback = func() -> void: events.append(label)
		1: callback = func(_a: Variant) -> void: events.append(label)
		2: callback = func(_a: Variant, _b: Variant) -> void: events.append(label)
		3: callback = func(_a: Variant, _b: Variant, _c: Variant) -> void: events.append(label)
		_: push_error("Unsupported fixture signal arity: " + label); return
	node.connect(signal_name, callback)

func _native_transport() -> void:
	var source: Dictionary = _create("standard")
	if not _expect(source.configured, "source constructs actual Heavy/Player/Bait/B05/foreign Scout and one Standard epoch"): return
	if not _expect(source.bindings.owners.size() == 3 and source.bindings.floors.size() == 2 and source.bindings.floors["dry-floor"].collision != source.bindings.floors["foreign-floor"].collision, "whole scope includes distinct actual third owner and second authored static floor"): return
	if not _expect(await _until(source, func() -> bool: return _stable(source.hero)), "source earns real native dry-floor contact before pristine capture"): return
	paused = true
	await process_frame # Retire ordinary callbacks; this does not advance physics.
	var pristine: Dictionary = _capture(source)
	if not _expect(_complete(pristine) and pristine.parent.parent.stage == "dormant" and pristine.parent.ray.record.cycle == 0 and pristine.parent.foot.cycle == 0 and pristine.parent.bait.boundary.is_empty(), "pristine full actual tuple has no invented bait/cycle/history"): _diagnose(source, "pristine capture"); return
	if not await _fresh_round_trip(pristine, "pristine", false): return
	paused = false
	if not _expect(bool(source.parent.call("start")), "public parent.start seeds real entry bait and begins one Ray introduction"): return
	if not _expect(await _until(source, func() -> bool: return source.parent.call("get_ray").call("state").get("armed", false)), "first actual Ray reaches genuine armed native lock"): _diagnose(source, "armed Ray"); return
	paused = true
	await process_frame # Required cue transport retirement, with no physics tick.
	var armed: Dictionary = _capture(source)
	if not _expect(_complete(armed), "actual paused armed Ray captures full Player/foreign Actor/B05/whole Scheduler tuple"): _diagnose(source, "armed capture"); return
	var native: Dictionary = source.parent.call("get_ray").call("state")
	if not _expect(armed.parent.ray.record.status == "running" and armed.parent.ray.record.phase == "lock" and armed.parent.parent.ray_admission.proof.accepted == true and native.proof_available and armed.parent.ray.record.cycle == 1 and armed.parent.foot.cycle == 0 and armed.player.resources.hp == 100.0 and source.hero.get_world_action_records().is_empty(), "armed sample is genuine first accepted full proof with unchanged health and no manufactured actions/Foot/threshold"): return
	if not await _fresh_round_trip(armed, "armed Ray", true): return
	_expect(source.runtime_failures.is_empty() and source.consumed.is_empty(), "small native source has no runtime failure or fabricated Player publication")

func _capture(fixture: Dictionary) -> Dictionary:
	return {"player": fixture.hero.snapshot_state(), "foreign_actor": fixture.foreign.call("snapshot_state"), "scheduler": fixture.scheduler.snapshot_state(fixture.bindings), "parent": fixture.parent.call("snapshot_state", fixture.bindings)}

func _complete(value: Dictionary) -> bool:
	for key: String in ["player", "foreign_actor", "scheduler", "parent"]:
		if not value.get(key) is Dictionary or value[key].is_empty(): return false
	return true

func _preflight(fixture: Dictionary, value: Dictionary, bindings: Dictionary) -> String:
	var error: String = fixture.hero.snapshot_error(value.player)
	if error.is_empty(): error = String(fixture.foreign.call("snapshot_error", value.foreign_actor))
	if error.is_empty(): error = fixture.scheduler.snapshot_error(value.scheduler, bindings)
	if error.is_empty(): error = String(fixture.parent.call("snapshot_error", value.parent, bindings, value.player, value.scheduler))
	return error

func _fresh_round_trip(original: Dictionary, label: String, malformed: bool) -> bool:
	var wire: String = ExactJson.stringify(original)
	var decoded: Dictionary = ExactJson.parse(wire)
	if not _expect(not wire.is_empty() and decoded.get("accepted", false) and ExactJson.stringify(decoded.get("value")) == wire, label + " full real tuple round-trips ExactJson scalar/vector bits and types"): return false
	var saved: Dictionary = decoded.value
	# No await/native tick is allowed between creation and first pure preflight.
	var fresh: Dictionary = _create("assisted")
	if not _expect(fresh.configured and paused and fresh.probe.ticks == 0 and fresh.scheduler.get_clock() == 0.0 and fresh.scheduler.encounter_profile().id == "assisted", label + " fresh actual paused recipient is constructed before its first physics tick with different preference"): return false
	var before: Dictionary = _capture(fresh)
	var signals_before: int = fresh.events.size()
	var error: String = _preflight(fresh, saved, fresh.bindings)
	if not _expect(error.is_empty() and fresh.probe.ticks == 0 and fresh.scheduler.get_clock() == 0.0, label + " same-call fresh prospective native floor/capsule/proof preflight accepts before any physics tick: " + error): _diagnose(fresh, label + " immediate fresh preflight"); return false
	if not _expect(_complete(before) and _same(before, _capture(fresh)) and fresh.events.size() == signals_before, label + " pure fresh preflight preserves exact tuple and emits zero callbacks"): return false
	if not _expect(not bool(fresh.parent.call("restore_consumers_state", saved.parent, fresh.bindings, saved.player, saved.scheduler)) and _same(before, _capture(fresh)) and fresh.events.size() == signals_before, label + " consumer-before-source order refuses atomically"): return false
	if malformed and not _malformed_refusals(fresh, saved): return false
	for repetition: int in range(2):
		if not _expect(_preflight(fresh, saved, fresh.bindings).is_empty(), label + " entire real tuple preflights before quiet commit %d" % repetition): return false
		var callback_count: int = fresh.events.size()
		# WHOLE quiet barrier: full Player, actual foreign source, B05 source,
		# exactly ONE Scheduler, then actual native B05 consumers. No yield.
		if not _expect(fresh.hero.restore_state(saved.player), label + " quietly restores actual full native Player"): return false
		if not _expect(bool(fresh.foreign.call("restore_state", saved.foreign_actor)), label + " quietly restores actual inactive foreign Scout before shared Scheduler"): return false
		if not _expect(bool(fresh.parent.call("restore_source_state", saved.parent, fresh.bindings, saved.player, saved.scheduler)), label + " commits exact Bait/Actor/Joint after actual Player"): _diagnose(fresh, "source commit"); return false
		if not _expect(fresh.scheduler.restore_state(saved.scheduler, fresh.bindings), label + " restores ONE full shared Scheduler for all three owners/two floors"): _diagnose(fresh, "Scheduler commit"); return false
		if not _expect(bool(fresh.parent.call("restore_consumers_state", saved.parent, fresh.bindings, saved.player, saved.scheduler)), label + " quietly commits actual Ray/Foot and bounded parent facts"): _diagnose(fresh, "consumer commit"); return false
		var after: Dictionary = _capture(fresh)
		if not _expect(_complete(after) and _same(saved, after), label + " repeated full actual recapture is exact without proof/clock/health/profile/deadline drift"): _diagnose(fresh, "exact recapture"); return false
		if not _expect(fresh.events.size() == callback_count and fresh.runtime_failures.is_empty(), label + " quiet restoration and capture emit zero action/damage/cue/progression/Scheduler callbacks"): return false
		if not _expect(fresh.parent.call("get_actor").call("snapshot_state").actor.body_yaw == saved.parent.actor.actor.body_yaw and fresh.scheduler.encounter_profile().id == "standard", label + " preserves exact actual Actor body yaw and saved canonical Standard profile"): return false
	var quiet_callbacks: int = fresh.events.size()
	await process_frame # Still paused: retire deferred work without advancing owners.
	if not _expect(fresh.events.size() == quiet_callbacks and _same(saved, _capture(fresh)), label + " paused deferred barrier preserves exact tuple with no late restoration callbacks"): return false
	_expect(not bool(fresh.parent.call("restore_state", saved.parent, fresh.bindings, saved.player, saved.scheduler)) and _same(saved, _capture(fresh)), label + " three-owner whole host rejects standalone two-owner convenience atomically")
	await _dispose(fresh)
	return _failures == 0

func _malformed_refusals(fixture: Dictionary, saved: Dictionary) -> bool:
	for kind: String in ["copied clock", "missing foreign owner", "original proof scalar", "wrong nested receipt type"]:
		var candidate: Dictionary = saved.duplicate(true)
		var bindings: Dictionary = fixture.bindings.duplicate()
		match kind:
			"copied clock": candidate.parent.clock_s = float(candidate.parent.clock_s) + 0.125
			"missing foreign owner":
				bindings.owners = fixture.bindings.owners.duplicate()
				bindings.owners.erase(FOREIGN_ID)
			"original proof scalar": candidate.parent.parent.ray_admission.proof.primary_time_s = float(candidate.parent.parent.ray_admission.proof.primary_time_s) + 0.125
			"wrong nested receipt type": candidate.parent.parent.ray_admission.bait_sample = false
		var before: Dictionary = _capture(fixture)
		var callbacks: int = fixture.events.size()
		var error: String = _preflight(fixture, candidate, bindings)
		if not _expect(not error.is_empty() and _complete(before) and _same(before, _capture(fixture)) and fixture.events.size() == callbacks, "malformed " + kind + " pure whole-tuple preflight refuses atomically: " + error): return false
	return true

func _same(left: Variant, right: Variant) -> bool:
	var wire: String = ExactJson.stringify(left)
	return not wire.is_empty() and wire == ExactJson.stringify(right)

func _stable(hero: CinderPlayer) -> bool:
	var response: Dictionary = hero.get_threat_response_state()
	return response.stable and response.motion.grounded and not hero.action_in_progress()

func _until(fixture: Dictionary, predicate: Callable) -> bool:
	for _index: int in range(MAX_TICKS):
		if bool(predicate.call()): return true
		if not fixture.runtime_failures.is_empty() or not String(fixture.parent.call("state").runtime_error).is_empty() or fixture.hero.dead: return false
		await (fixture.probe as NativeTickProbe).tick_finished
	return false

func _diagnose(fixture: Dictionary, point: String) -> void:
	var native: Dictionary = fixture.parent.call("state")
	push_error("Transport stopped at %s: parent_error=%s ray_error=%s foot_error=%s scheduler_error=%s stage=%s clock=%s ray=%s/%s" % [point, fixture.parent.get("last_snapshot_error"), fixture.parent.call("get_ray").get("last_snapshot_error"), fixture.parent.call("get_foot").last_snapshot_error, fixture.scheduler.last_snapshot_error, native.stage, native.clock_s, native.ray.status, native.ray.phase])

func _dispose(fixture: Dictionary) -> void:
	if fixture.disposed: return
	fixture.disposed = true
	var refs: Array[WeakRef] = []
	for node: Variant in [fixture.world, fixture.hero, fixture.parent, fixture.foreign, fixture.scheduler]: refs.append(weakref(node))
	if is_instance_valid(fixture.parent):
		if not fixture.parent.call("owners").is_empty():
			for node: Variant in [fixture.parent.call("get_actor"), fixture.parent.call("get_ray"), fixture.parent.call("get_foot"), fixture.parent.call("get_joint_cue"), fixture.parent.call("get_ray").call("get_cue"), fixture.parent.call("get_foot").get_cue()]: refs.append(weakref(node))
		fixture.parent.call("cleanup")
		_expect(not bool(fixture.parent.call("start")) and fixture.parent.call("owners").is_empty() and fixture.parent.call("snapshot_state", fixture.bindings).is_empty(), "permanent cleanup closes actual parent admission/owner/transport authority")
	if fixture.hero.world_action_executed.is_connected(fixture.action_callback): fixture.hero.world_action_executed.disconnect(fixture.action_callback)
	fixture.bait.call("release")
	fixture.foreign.call("cleanup")
	fixture.scheduler.end_encounter("test_whole_transport_disposal")
	fixture.viewport.queue_free()
	await process_frame
	await process_frame
	for reference: WeakRef in refs: _expect(reference.get_ref() == null, "whole actual transport world/controller/source/cue disposes")

func _expect(condition: bool, description: String) -> bool:
	_checks += 1
	if condition: print("PASS: " + description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
	return condition
