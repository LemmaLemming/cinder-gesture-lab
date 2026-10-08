extends SceneTree
## NEW native-composition target. Requires reviewed Scheduler/coordinator adoption;
## no mocked source_control_state, authored Selenite or campaign acceptance.
const NativeActor = preload("res://tests/fixtures/environment/scheduler_spore_native_actor.gd")
const Protocol = preload("res://scripts/environment/scheduler_spore_source_protocol.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Player = preload("res://scripts/player.gd")
const Consumer = preload("res://scripts/environment/spore_repulsion.gd")
const Field = preload("res://scripts/environment/spore_field.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")

var checks: int = 0
var failures: int = 0


class FreedCodecSource:
	extends NativeActor
	var supplied_codec: Variant
	func get_spore_native_bindings() -> Dictionary:
		var native: Dictionary = super.get_spore_native_bindings()
		native.codec = supplied_codec
		return native


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var probe = Scheduler.new()
	var adopted: bool = probe.has_method("source_control_state")
	probe.free()
	_expect(adopted, "actual Scheduler pure accessor adopted; no fixture fallback authority")
	if not adopted:
		_finish()
		return
	await _identity_and_purity()
	await _actual_attack_and_cancel("lane", false)
	await _actual_attack_and_cancel("lunge", false)
	await _actual_attack_and_cancel("lane", true)
	await _actual_attack_and_cancel("lunge", true)
	await _lunge_contact_tracks_actual_body()
	await _cancel_callback_boundaries()
	await _stale_accessor()
	await _binding_aliases()
	await _direct_player_activation()
	await _pending_contact_restore()
	await _episode_restore(false)
	await _episode_restore(true)
	await _removed_defeat()
	await _freed_handles()
	_finish()


func _identity_and_purity() -> void:
	var w: Dictionary = await _world(false)
	if not w.ready:
		await _dispose(w)
		return
	paused = true
	var context: Dictionary = _context(w)
	var unit: Dictionary = w.protocol.current_unit(_pair(context))
	_expect(not unit.is_empty(), "actual paused native HP/controller/Player unit captures: " + w.protocol.last_error)
	var source_pose: Vector3 = w.source.global_position
	var velocity: Vector3 = w.source.velocity
	var clock: float = w.scheduler.get_clock()
	w.scheduler.last_error = "retained-request"
	w.scheduler.last_snapshot_error = "retained-snapshot"
	w.protocol.last_error = "retained-helper"
	var events: Array = []
	w.scheduler.reservation_invalidated.connect(func(id: String, why: String) -> void: events.append([id, why]))
	for _iteration: int in range(3):
		_expect(w.protocol.binding_error().is_empty() and w.protocol.unit_error(unit, _pair(context)).is_empty(), "pure complete native decoder accepts actual paused unit")
		var view: Dictionary = w.protocol.unit_view(unit, _pair(context))
		view.motion.position[0] += 1.0
		var response: Dictionary = w.protocol.response_state()
		response.position += Vector3.RIGHT
	_expect(w.source.global_position == source_pose and w.source.velocity == velocity and w.scheduler.get_clock() == clock and events.is_empty(), "pure views neither move/stop source nor advance/prune controller or emit callbacks")
	_expect(w.scheduler.last_error == "retained-request" and w.scheduler.last_snapshot_error == "retained-snapshot" and w.protocol.last_error == "retained-helper", "pure queries preserve all diagnostics")
	_expect(_same(unit, w.protocol.current_unit(_pair(context))), "defensive view mutations cannot change full actual native capture")
	var collision: CollisionShape3D = w.source.get_node("BodyCollision")
	var original: CapsuleShape3D = collision.shape as CapsuleShape3D
	var equivalent: Shape3D = original.duplicate()
	collision.shape = equivalent
	_expect(not w.protocol.binding_error().is_empty() and w.source.global_position == source_pose and w.source.velocity == velocity, "equivalent replacement native resource rejected without source mutation")
	collision.shape = original
	var radius: float = original.radius
	original.radius = radius + 0.001
	_expect(not w.protocol.binding_error().is_empty(), "actual retained capsule dimensions cannot drift")
	original.radius = radius
	var floor_shape: Shape3D = w.floor.collision.shape
	w.floor.collision.shape = floor_shape.duplicate()
	_expect(not w.protocol.binding_error().is_empty(), "equivalent actual floor resource replacement fails retained identity")
	w.floor.collision.shape = floor_shape
	var own: Dictionary = w.source.get("_configuration").duplicate(true)
	w.source.get("_configuration")["max_hp"] = _next_float(float(own.max_hp))
	_expect(not w.protocol.binding_error().is_empty(), "one-bit native immutable configuration change fails exact identity")
	w.source.set("_configuration", own)
	_expect(w.protocol.binding_error().is_empty(), "fixture repairs only its injected resource/config mutations")
	var scheduler_priority: int = w.scheduler.process_physics_priority
	w.scheduler.process_physics_priority = 11
	_expect(not w.protocol.binding_error().is_empty(), "changed actual Scheduler priority cannot follow native sampling")
	w.scheduler.process_physics_priority = scheduler_priority
	var player_priority: int = w.hero.process_physics_priority
	w.hero.process_physics_priority = 11
	_expect(not w.protocol.binding_error().is_empty(), "changed actual Player priority cannot follow native sampling")
	w.hero.process_physics_priority = player_priority
	for malformed: Variant in [[], null]:
		var bad_cue: Dictionary = unit.duplicate(true)
		bad_cue.cue.geometry = malformed
		_expect(not w.protocol.unit_error(bad_cue, _pair(context)).is_empty(), "malformed owned cue geometry rejects atomically before dereference")
	var bad_context: Dictionary = context.duplicate(true)
	bad_context.players.hero.resources.hp = _next_float(float(bad_context.players.hero.resources.hp))
	_expect(w.protocol.current_unit(_pair(bad_context)).is_empty(), "one-bit full actual Player mismatch rejects current-unit pairing")
	await _dispose(w)


func _actual_attack_and_cancel(kind: String, after_hit: bool) -> void:
	var w: Dictionary = await _world(true)
	if not w.ready:
		await _dispose(w)
		return
	var hits: Array = []
	w.source.hit_resolved.connect(func(result: Dictionary) -> void: hits.append(result))
	var accepted: Dictionary = w.source.start(kind, _response(w))
	_expect(accepted.get("accepted", false), "real native " + kind + " Scheduler admission: " + String(accepted.get("reason", "")))
	if not accepted.get("accepted", false):
		await _dispose(w)
		return
	var controller: Dictionary = w.scheduler.call("source_control_state", w.source)
	var cooldown: float = controller.cooldown.ready_s
	var body: Shape3D = w.source.get_node("BodyCollision").shape
	var hp: float = w.source.hp
	var hero_hp: float = w.hero.hp
	var origin: Vector3 = w.source.global_position
	if after_hit:
		await _until_clock(w.scheduler, float(accepted.reservation.active_from_s) + 0.05)
		_expect(hits.size() == 1 and w.hero.hp < hero_hp and w.source.get("_hit_ids") == ["hero"], "genuine actual native active contact consumes one shared Player hit")
	else:
		await _until_clock(w.scheduler, float(accepted.reservation.lock_from_s))
		_expect(hits.is_empty() and w.hero.hp == hero_hp, "unresolved native warning/lock carries no fabricated damage")
	paused = true
	var paired: Dictionary = _context(w)
	var genuine: Dictionary = w.protocol.current_unit(_pair(paired))
	_expect(not genuine.is_empty(), "actual admitted native source captures full paired lease/sample/cue")
	var table: Dictionary = w.scheduler.get("_reservations")
	var old_geometry: Dictionary = table[accepted.reservation_id].geometry.duplicate(true)
	table[accepted.reservation_id].geometry.radius = _next_float(float(old_geometry.radius))
	_expect(w.protocol.current_unit(_pair(paired)).is_empty(), "one-bit actual retained controller geometry mutation rejects unchanged-clock native capture")
	table[accepted.reservation_id].geometry = old_geometry
	_expect(_same(genuine, w.protocol.current_unit(_pair(paired))), "fixture restores only its injected retained-controller mutation")
	paused = false
	if kind == "lunge" and after_hit:
		_expect(w.source.global_position != origin and w.source.velocity != Vector3.ZERO, "actual active-lunge capsule moved before legitimate zero-velocity cancellation")
	_expect(w.first.activate_cluster("left"), "actual mushroom activation delegates to the real coordinator")
	var response: Dictionary = w.protocol.response_state()
	var canceled: Dictionary = w.scheduler.call("source_control_state", w.source)
	_expect(response.phase == "recoil" and canceled.reservations.is_empty() and canceled.cooldown.ready_s == cooldown, "environment removes actual lane/lunge lease, retains exact cooled-down deadline and stages one episode")
	_expect(w.source.hp == hp and w.source.get_node("BodyCollision").shape == body and w.source.global_basis == Basis.IDENTITY, "spores preserve native HP/body/resource and basis")
	var paid: float = w.hero.hp
	await _ticks(10)
	_expect(w.hero.hp == paid and hits.size() == (1 if after_hit else 0), "canceled real attack cannot deliver a delayed or second Player hit")
	_expect(w.source.global_position != origin or response.phase == "recoil", "native source uses actual motion rather than controller flag alone")
	await _wait_phase(w, "retreat")
	var route: Dictionary = w.consumer.source_state("native-source")
	_expect(route.get("route", {}).get("leased", false) and w.scheduler.call("source_control_state", w.source).reservations.is_empty(), "real capsule retreat acquires only after genuine Scheduler cancellation")
	var old_episode: String = route.episode_id
	_expect(w.second.activate_cluster("right"), "independent actual mushroom joins current connected component")
	await _ticks(2)
	_expect(w.consumer.source_state("native-source").episode_id == old_episode and w.consumer.source_state("native-source").members.size() == 2, "overlap does not rearm attack or refresh recoil/episode")
	await _dispose(w)


func _lunge_contact_tracks_actual_body() -> void:
	var w: Dictionary = await _world(true)
	if not w.ready:
		await _dispose(w)
		return
	# Fixture setup only: real Hero starts farther ahead before actual admission.
	w.hero.global_position = w.source.global_position + Vector3.RIGHT * 1.1
	await _ticks(1)
	var hits: Array = []
	w.source.hit_resolved.connect(func(result: Dictionary) -> void: hits.append(result))
	var hp: float = w.hero.hp
	var source_start: Vector3 = w.source.global_position
	var admitted: Dictionary = w.source.start("lunge", _response(w))
	_expect(admitted.get("accepted", false), "separated real Hero admits genuine native lunge: " + String(admitted.get("reason", "")))
	if not admitted.get("accepted", false):
		await _dispose(w)
		return
	var hero_radius: float = (w.hero.get_node("BodyCollision").shape as CapsuleShape3D).radius
	var damage_radius: float = float(admitted.reservation.adapter.damage_radius)
	_expect(Geometry.segment_hits(admitted.reservation.geometry, w.hero.global_position, w.hero.global_position, hero_radius), "real separated Hero lies in admitted conservative warning corridor")
	await _until_clock(w.scheduler, float(admitted.reservation.active_from_s))
	var first_distance: float = w.hero.global_position.distance_to(w.source.global_position)
	_expect(first_distance > damage_radius + hero_radius and w.hero.hp == hp and hits.is_empty(), "first real active tick outside moving damage body causes no corridor-only hit")
	for _tick: int in range(40):
		if not hits.is_empty(): break
		await _ticks(1)
	var contact_distance: float = w.hero.global_position.distance_to(w.source.global_position)
	_expect(w.source.global_position != source_start and contact_distance <= damage_radius + hero_radius and hits.size() == 1 and w.hero.hp < hp, "only actual approaching capsule produces one genuine shared Player hit")
	await _ticks(8)
	_expect(hits.size() == 1, "continuing actual body overlap cannot duplicate consumed lunge hit")
	await _dispose(w)


func _cancel_callback_boundaries() -> void:
	for kind: String in ["pause", "hurt", "hurt-cooldown", "epoch", "cooldown", "horizontal"]:
		var w: Dictionary = await _world(true)
		if not w.ready:
			await _dispose(w)
			continue
		var attack: Dictionary = w.source.start("lane", _response(w))
		_expect(attack.get("accepted", false), "callback fixture owns actual native lease")
		if not attack.get("accepted", false):
			await _dispose(w)
			continue
		var origin: Vector3 = w.source.global_position
		var hp: float = w.source.hp
		var control: Dictionary = w.protocol.control_state()
		var damage: Array = []
		var cancellation_observer: Callable = func(id: String, reason: String) -> void:
			if id != attack.reservation_id or reason != "spore_repulsion":
				return
			match kind:
				"pause":
					paused = true
				"hurt":
					damage.append(w.source.take_damage(2.0, Vector3(0.5, 2.0, 0.0)))
				"hurt-cooldown":
					damage.append(w.source.take_damage(2.0, Vector3(0.5, 2.0, 0.0)))
					w.scheduler.cancel_owner(w.source, "observer_drop_after_hurt")
				"epoch":
					w.scheduler.end_encounter("observer_end")
				"cooldown":
					w.scheduler.cancel_owner(w.source, "observer_drop_cooldown")
				"horizontal":
					w.source.velocity += Vector3(0.25, 0.0, 0.0)
		w.scheduler.reservation_invalidated.connect(cancellation_observer)

		_expect(w.first.activate_cluster("left"), "field invokes synchronous real " + kind + " cancellation observer")
		if kind == "pause":
			_expect(paused and w.source.global_position == origin and w.protocol.control_state().clock_s == control.clock_s and _same(w.protocol.control_state().cooldown, control.cooldown), "invalidation pause freezes pose/clock and retains exact real cooldown")
			await process_frame
			var context: Dictionary = _context(w)
			var saved: Dictionary = w.consumer.snapshot_state(context)
			_expect(not saved.is_empty() and saved.records["native-source"].age_s == 0.0 and saved.records["native-source"].route.route.elapsed_s == 0.0, "later complete paused native recoil unit has no retreat clock advance")
		elif kind == "hurt":
			_expect(damage.size() == 1 and damage[0].accepted and w.source.hp == hp - 2.0 and w.source.velocity == Vector3(0.5, 2.0, 0.0), "one genuine nested public damage transaction preserves HP and full impulse")
			var saved: Dictionary = w.consumer.source_state("native-source")
			_expect(saved.phase == "interrupted" and saved.route.is_empty() and _same(w.protocol.control_state().cooldown, control.cooldown), "hurt interrupts before acquire without erased impulse/refreshed cooldown")
		elif kind == "epoch":
			var after: Dictionary = w.protocol.control_state()
			_expect(w.consumer.placement_accepted() and not w.consumer.source_state("native-source").route.is_empty() and after.encounter_id == control.encounter_id and after.world_revision == control.world_revision and after.clock_s == control.clock_s and _same(after.cooldown, control.cooldown), "end_encounter request is ignored inside real cancellation transaction; coherent route/cooldown remain")
		else:
			_expect(not w.consumer.placement_accepted() and w.consumer.source_state("native-source").route.is_empty() and w.source.global_position == origin, "changed " + kind + " custody refuses native acquire")
			if kind == "horizontal": _expect(w.source.velocity == Vector3(0.25, 0.0, 0.0), "unexplained horizontal velocity is preserved")
			if kind == "hurt-cooldown":
				_expect(damage.size() == 1 and damage[0].accepted and w.source.hp == hp - 2.0 and w.source.velocity == Vector3(0.5, 2.0, 0.0), "combined custody failure preserves genuine callback damage and impulse")
				for _tick: int in range(80):
					var response: Dictionary = w.protocol.response_state()
					if response.hurt_remaining_s == 0.0 and response.grounded and response.velocity == Vector3.ZERO: break
					await _ticks(1)
				var settled: Dictionary = w.protocol.response_state()
				_expect(settled.hurt_remaining_s == 0.0 and settled.grounded and settled.velocity == Vector3.ZERO and w.source.hp == hp - 2.0, "actual failed-episode source settles real hurt and impulse through native physics")
				var id: String = w.consumer.source_state("native-source").episode_id
				await _ticks(12)
				_expect(w.consumer.source_state("native-source").episode_id == id and w.consumer.source_state("native-source").route.is_empty() and not w.consumer.placement_accepted() and w.protocol.control_state().reservations.is_empty(), "settled native custody fault remains latched without route acquisition or attack rearm")
		await _dispose(w)


func _stale_accessor() -> void:
	var w: Dictionary = await _world(false)
	if w.ready:
		var attack: Dictionary = w.source.start("lane", _response(w))
		_expect(attack.get("accepted", false), "stale accessor uses genuine admitted lease")
		if attack.get("accepted", false):
			paused = true
			var before: Dictionary = w.protocol.control_state()
			var table: Dictionary = w.scheduler.get("_reservations").duplicate(true)
			var cooldowns: Dictionary = w.scheduler.get("_cooldowns").duplicate(true)
			var events: Array = []
			w.scheduler.reservation_invalidated.connect(func(id: String, reason: String) -> void: events.append([id, reason]))
			w.scheduler.last_error = "retain-stale"
			w.scheduler.last_snapshot_error = "retain-snapshot"
			# Test-only clock injection; real retained tables remain untouched.
			w.scheduler.set("_clock", float(before.reservations[0].recovery_until_s) + 1.0)
			var overdue: Dictionary = w.scheduler.call("source_control_state", w.source)
			_expect(overdue.reservations.size() == 1 and overdue.cooldown.ready_s == before.cooldown.ready_s and overdue.cooldown.ready_s < overdue.clock_s, "pure accessor retains real overdue lease/cooldown")
			_expect(table == w.scheduler.get("_reservations") and cooldowns == w.scheduler.get("_cooldowns") and events.is_empty() and w.scheduler.last_error == "retain-stale" and w.scheduler.last_snapshot_error == "retain-snapshot", "pure overdue query does not prune/mutate/emit/change diagnostics")
			w.scheduler.set("_clock", before.clock_s)
	await _dispose(w)


func _binding_aliases() -> void:
	for kind: String in ["controller-node", "controller-id", "player-node", "player-id"]:
		var w: Dictionary = await _world(false)
		if not w.ready:
			await _dispose(w)
			continue
		paused = true
		var scheduler: CinderThreatScheduler = w.scheduler
		var hero: CinderPlayer = w.hero
		var controller_id: String = "controller"
		var player_id: String = "hero"
		if kind == "controller-node":
			scheduler = Scheduler.new()
			scheduler.process_physics_priority = -20
			w.root.add_child(scheduler)
			scheduler.begin_encounter("standard", "native-spore-fixture", 1)
		elif kind == "controller-id": controller_id = "second-controller"
		elif kind == "player-node":
			hero = Player.new()
			hero.process_physics_priority = -10
			hero.position = Vector3(8.0, 0.0, 0.0)
			w.root.add_child(hero)
		else: player_id = "second-hero"
		var source = NativeActor.new()
		source.configure_source_id("second-source")
		source.position = Vector3(-8.0, 0.0, 0.0)
		w.root.add_child(source)
		source.bind_native(scheduler, hero)
		var other = Protocol.new()
		var configured: bool = other.configure(source, scheduler, hero, "second-source", controller_id, player_id, {"world_root": w.root, "floors": {"ground": w.floor}})
		_expect(configured, "alias fixture has a genuine second native binding: " + other.last_error)
		if configured:
			var bindings: Dictionary = w.bindings.duplicate(true)
			bindings.sources["second-source"] = source
			bindings.source_protocols["second-source"] = other
			_expect(not w.protocol.binding_compatibility_error(other).is_empty() and not other.binding_compatibility_error(w.protocol).is_empty(), "pure " + kind + " identity compatibility refuses both directions")
			_expect(not w.consumer.bind_environment(bindings) and w.source.get_spore_response_state().consumer_id.is_empty() and source.get_spore_response_state().consumer_id.is_empty() and w.protocol.control_state().reservations.is_empty(), "precommit " + kind + " refusal binds neither real actor or lease")
		await _dispose(w)


func _direct_player_activation() -> void:
	var w: Dictionary = await _world(true)
	if w.ready:
		var hp: float = w.source.hp
		var hero_hp: float = w.hero.hp
		var shells: int = w.hero.shells
		var reload: float = w.hero.get("_reload")
		_expect(w.hero.slash(Vector3.FORWARD) == 0 and w.first.state().generation == 1 and w.source.hp == hp and w.hero.get("_accepted_enemy_hits") == 0 and w.hero.get("_reload") == reload, "actual shared primary origin-disk cluster dispatch repels native actor without enemy HP/reload credit")
		var episode: String = w.consumer.source_state("native-source").episode_id
		var deadline: float = w.first.state().deadline_s
		_expect(shells > 0 and w.hero.blast(Vector3.FORWARD) == 0 and w.hero.shells == shells - 1 and w.hero.hp == hero_hp and w.source.hp == hp, "actual blast spends ordinary ammo with zero environmental damage/hit")
		_expect(w.first.state().generation == 1 and w.first.state().deadline_s == deadline and w.consumer.source_state("native-source").episode_id == episode, "primary then blast spends one supply without native episode/deadline refresh")
	await _dispose(w)


func _pending_contact_restore() -> void:
	var w: Dictionary = await _world(true)
	if not w.ready:
		await _dispose(w)
		return
	var entered: Array = []
	var cue: CinderThreatCue = w.source.get_node("NativeCue")
	var pause_on_active: Callable = func(phase: String) -> void:
		if phase == "active":
			entered.append(true)
			paused = true
	cue.phase_changed.connect(pause_on_active)
	var start: Dictionary = w.source.start("lane", _response(w))
	_expect(start.get("accepted", false), "pending native contact requires actual admitted lane")
	if not start.get("accepted", false):
		await _dispose(w)
		return
	for _frame: int in range(160):
		if paused: break
		await _ticks(1)
	_expect(paused and entered == [true], "synchronous actual cue active callback genuinely pauses before damage")
	var context: Dictionary = _context(w)
	var saved: Dictionary = w.protocol.current_unit(_pair(context))
	_expect(saved.get("schema_version") == 2 and not saved.get("pending_segments", []).is_empty() and saved.hit_ids.is_empty(), "owned native codec captures the exact unconsumed actual sampled opportunity")
	if not saved.is_empty():
		var forged: Dictionary = saved.duplicate(true)
		forged.pending_segments[0].start_s = forged.pending_segments[0].end_s
		forged.pending_segments[0].from[0] += 0.1
		_expect(not w.protocol.unit_error(forged, _pair(context)).is_empty(), "zero-time forged Hero/source travel rejects without opportunity mutation")
	var health: float = w.hero.hp
	await process_frame
	await process_frame
	_expect(w.hero.hp == health and _same(saved, w.protocol.current_unit(_pair(context))), "genuine pause freezes pending native opportunity and whole actor/context")
	var copy: Dictionary = await _world(true, false)
	if copy.ready and not saved.is_empty():
		var callbacks: Array = []
		copy.source.hit_resolved.connect(func(result: Dictionary) -> void: callbacks.append(result))
		_expect(copy.protocol.unit_error(saved, _pair(context)).is_empty(), "fresh source validates complete saved native exchange without current-clock/pose guessing")
		_expect(_restore_external(copy, context), "real whole Player/Scheduler/actor paused pair restores quietly")
		_expect(_same(saved, copy.protocol.current_unit(_pair(context))) and callbacks.is_empty(), "conditional native pending transport is exact and quiet")
		paused = false
		await _ticks(2)
		_expect(callbacks.size() == 1 and copy.hero.hp < health and copy.source.get("_hit_ids") == ["hero"], "saved actual opportunity resumes once through the shared Player")
		await _ticks(4)
		_expect(callbacks.size() == 1, "consumed native pending delivery never duplicates")
	await _dispose(copy)
	await _dispose(w)


func _episode_restore(interrupt: bool) -> void:
	var original: Dictionary = await _world(true)
	if not original.ready:
		await _dispose(original)
		return
	var start: Dictionary = original.source.start("lunge", _response(original))
	_expect(start.get("accepted", false) and original.first.activate_cluster("left"), "native paired episode cancels actual lunge before route motion")
	await _wait_phase(original, "retreat")
	await _ticks(3)
	if interrupt:
		var before: Vector3 = original.source.velocity
		var hp: float = original.source.hp
		var result: Dictionary = original.source.take_damage(2.0, Vector3(0.5, 2.0, 0.0))
		_expect(result.accepted and original.source.hp == hp - 2.0 and original.source.velocity == before + Vector3(0.5, 2.0, 0.0), "genuine actual damage retains source HP loss and external impulse")
		_expect(original.consumer.source_state("native-source").phase == "interrupted" and original.consumer.source_state("native-source").route.is_empty(), "source calls actual coordinator interruption before observers; route releases without overwriting impulse")
	paused = true
	var context: Dictionary = _context(original)
	var saved: Dictionary = original.consumer.snapshot_state(context)
	_expect(saved.get("schema_version") == 2 and saved.get("source_protocols", {}).has("native-source"), "opted native coordinator uses conditional schema2 with exact full actor reference")
	var parsed: Dictionary = Exact.parse(Exact.stringify({"context": context, "consumer": saved}))
	_expect(parsed.get("accepted", false) and _same(parsed.value, {"context": context, "consumer": saved}), "actual whole paused pair preserves scalar bits/types through ExactJson")
	var fresh: Dictionary = await _world(true, false)
	if fresh.ready and not saved.is_empty():
		var pose: Vector3 = fresh.source.global_position
		var events: Array = []
		fresh.consumer.reaction_started.connect(func(id: String, episode: String) -> void: events.append([id, episode]))
		_expect(fresh.consumer.snapshot_error(saved, context).is_empty() and fresh.source.global_position == pose, "fresh schema2 staging proves saved native pose/route without mutation")
		_expect(not fresh.consumer.restore_state(saved, context) and fresh.source.global_position == pose, "actual commit rejects before external native units are restored")
		_expect(_restore_external(fresh, context) and fresh.consumer.restore_state(saved, context), "validated physical→Scheduler→native exchange→route restore commits coherently")
		_expect(events.is_empty() and _same(saved, fresh.consumer.snapshot_state(_context(fresh))), "whole native episode restore emits no activation/reaction and preserves exact copied pair")
		for mutation: String in ["field-clock", "actor-progress", "actor-hash", "configuration"]:
			var bad: Dictionary = saved.duplicate(true)
			var bad_context: Dictionary = context.duplicate(true)
			match mutation:
				"field-clock": bad.field_references["mushroom-a"].clock_s = _next_float(float(bad.field_references["mushroom-a"].clock_s))
				"actor-progress": bad_context.sources["native-source"].repulsion.progress = _next_float(float(bad_context.sources["native-source"].repulsion.progress))
				"actor-hash": bad.source_protocols["native-source"].actor_sha256 = "0".repeat(64)
				"configuration": bad.source_protocols["native-source"].configuration_sha256 = "0".repeat(64)
			_expect(not fresh.consumer.snapshot_error(bad, bad_context).is_empty() and _same(saved, fresh.consumer.snapshot_state(_context(fresh))), "one-bit/exact schema2 " + mutation + " mismatch rejects without route/actor mutation")

	await _dispose(fresh)
	await _dispose(original)


func _removed_defeat() -> void:
	var w: Dictionary = await _world(true)
	if not w.ready:
		await _dispose(w)
		return
	var attack: Dictionary = w.source.start("lane", _response(w))
	_expect(attack.get("accepted", false), "defeat fixture owns a genuine prepared Scheduler lease")
	w.source.take_damage(100.0, Vector3.ZERO)
	paused = true
	var context: Dictionary = _context(w)
	var saved: Dictionary = w.consumer.snapshot_state(context)
	_expect(context.sources["native-source"].dead and w.scheduler.call("source_control_state", w.source).reservations.is_empty() and w.scheduler.call("source_control_state", w.source).cooldown == null, "actual source death clears genuine lease/cooldown before tombstone capture")
	w.source.free()
	_expect(w.protocol.unit_error(context.sources["native-source"], _pair(context)).is_empty() and w.consumer.snapshot_error(saved, context).is_empty(), "retained genuine owned codec validates full removed-source defeat without cloning actor")
	var forged: Dictionary = context.sources["native-source"].duplicate(true)
	forged.dead = false
	forged.hp = 1.0
	_expect(not w.protocol.unit_error(forged, _pair(context)).is_empty(), "missing living native source cannot become a defeat tombstone")
	await _dispose(w)


func _freed_handles() -> void:
	var w: Dictionary = await _world(false)
	if not w.ready:
		await _dispose(w)
		return
	paused = true
	var clock: float = w.scheduler.get_clock()
	w.scheduler.last_error = "handle-guard-retained"
	var collision: CollisionShape3D = w.source.get_node("BodyCollision")
	collision.free()
	_expect(not w.protocol.binding_error().is_empty() and w.scheduler.get_clock() == clock and w.scheduler.last_error == "handle-guard-retained", "freed cached BodyCollision rejects before owned response casts, without diagnostics or clock mutation")
	await _dispose(w)
	w = await _world(false)
	if w.ready:
		var floor_collision: CollisionShape3D = w.floor.collision
		floor_collision.free()
		_expect(not w.protocol.binding_error().is_empty(), "freed retained floor rejects before existing Route's native casts")
	await _dispose(w)
	w = await _world(false)
	if w.ready:
		var bad_source = FreedCodecSource.new()
		bad_source.name = "FreedCodecSource"
		bad_source.position = Vector3(-8.0, 0.0, 0.0)
		w.root.add_child(bad_source)
		bad_source.bind_native(w.scheduler, w.hero)
		var codec_handle := Node.new()
		bad_source.supplied_codec = codec_handle
		codec_handle.free()
		var codec_rejected = Protocol.new()
		var current_clock: float = w.scheduler.get_clock()
		_expect(not codec_rejected.configure(bad_source, w.scheduler, w.hero, "native-source", "controller", "hero", {"world_root": w.root, "floors": {"ground": w.floor}}) and w.scheduler.get_clock() == current_clock, "owned binding callback returning a freed codec handle rejects before RefCounted assignment without advancing real controller")
		var removed := Node3D.new()
		root.add_child(removed)
		var supplied: Dictionary = {"world_root": removed, "floors": {"ground": w.floor}}
		removed.free()
		var rejected = Protocol.new()
		_expect(not rejected.configure(w.source, w.scheduler, w.hero, "native-source", "controller", "hero", supplied), "externally supplied freed world Variant rejects before typed casting")
		var detached = NativeActor.new()
		_expect(w.scheduler.call("source_control_state", detached).is_empty(), "pure accessor rejects detached owner without retained-table cleanup")
		detached.free()
	await _dispose(w)


func _world(bind_consumer: bool, simulate: bool = true) -> Dictionary:
	var was_paused: bool = paused
	if simulate: paused = false
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = Vector2i(64, 64)
	root.add_child(viewport)
	var arena := Node3D.new()
	arena.name = "World"
	viewport.add_child(arena)
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.position.y = -0.5
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 1.0, 40.0)
	collision.shape = box
	floor_body.add_child(collision)
	arena.add_child(floor_body)
	var floor := {"collision": collision, "safe_rect": Rect2(-20.0, -20.0, 40.0, 40.0)}
	var hero: CinderPlayer = Player.new()
	hero.name = "Hero"
	hero.process_physics_priority = -10
	hero.position = Vector3(-2.5, 0.0, 0.0)
	arena.add_child(hero)
	var scheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	scheduler.process_physics_priority = -20
	arena.add_child(scheduler)
	var source = NativeActor.new()
	source.name = "Source"
	source.position = Vector3(-3.0, 0.0, 0.0)
	arena.add_child(source)
	source.bind_native(scheduler, hero)
	var first = _field(arena, "mushroom-a", Vector3(-3.0, 0.0, 0.0))
	var second = _field(arena, "mushroom-b", Vector3(-4.0, 0.0, 0.0))
	var consumer = Consumer.new()
	consumer.name = "Repulsion"
	consumer.configure("native-spores", [Vector3.LEFT])
	arena.add_child(consumer)
	if simulate: await _ticks(5)
	scheduler.begin_encounter("standard", "native-spore-fixture", 1)
	var protocol = Protocol.new()
	var ready: bool = protocol.configure(source, scheduler, hero, "native-source", "controller", "hero", {"world_root": arena, "floors": {"ground": floor}})
	_expect(ready, "actual supported native capsule/Scheduler/Player composition configures: " + protocol.last_error)
	var bindings := {"world_root": arena, "floors": {"ground": floor}, "fields": {"mushroom-a": first, "mushroom-b": second}, "sources": {"native-source": source}, "source_protocols": {"native-source": protocol}}
	if ready and bind_consumer:
		ready = consumer.bind_environment(bindings)
		_expect(ready, "actual coordinator opts into complete native composition: " + consumer.last_error)
	if not simulate: paused = was_paused
	return {"viewport": viewport, "root": arena, "floor": floor, "hero": hero, "scheduler": scheduler, "source": source, "first": first, "second": second, "consumer": consumer, "protocol": protocol, "bindings": bindings, "ready": ready}


func _field(parent: Node3D, id: String, at: Vector3) -> Node3D:
	var field = Field.new()
	field.name = id
	field.configure(id, [{"id": "left", "offset": Vector3(-0.5, 0.7, 0.0)}, {"id": "right", "offset": Vector3(0.5, 0.7, 0.0)}])
	field.position = at
	parent.add_child(field)
	return field


func _response(w: Dictionary) -> Dictionary:
	var response: Dictionary = w.hero.get_threat_response_state()
	response.merge({"world_root": w.root, "world_revision": 1, "recognition_s": 0.1, "attack_input_margin_s": 0.02, "escape_directions": [Vector3.FORWARD, Vector3.BACK], "return_directions": [Vector3.FORWARD, Vector3.BACK], "floor_regions": [w.floor]})
	return response


func _context(w: Dictionary) -> Dictionary:
	var bindings: Dictionary = _scheduler_bindings(w)
	var saved_scheduler: Dictionary = w.scheduler.snapshot_state(bindings)
	var saved_player: Dictionary = w.hero.snapshot_state()
	var saved_actor: Dictionary = w.protocol.current_unit({"controllers": {"controller": saved_scheduler}, "players": {"hero": saved_player}})
	return {"fields": {"mushroom-a": w.first.snapshot_state(), "mushroom-b": w.second.snapshot_state()}, "sources": {"native-source": saved_actor}, "controllers": {"controller": saved_scheduler}, "players": {"hero": saved_player}}


func _scheduler_bindings(w: Dictionary, context: Dictionary = {}) -> Dictionary:
	var binding: Dictionary = {"world_root": w.root, "owners": {"native-source": w.source}, "floors": {"ground": w.floor}}
	if not context.is_empty():
		binding["owner_positions"] = {"native-source": Value.read_vector3(context.sources["native-source"].motion.position)}
		binding["owner_velocities"] = {"native-source": Value.read_vector3(context.sources["native-source"].motion.velocity)}
		if not context.sources["native-source"].dead:
			binding["owner_collision_states"] = {"native-source": {"collision_path": "BodyCollision", "enabled": true, "layer": 2, "mask": 1}}
	return binding


func _restore_external(w: Dictionary, context: Dictionary) -> bool:
	var scheduler_bindings: Dictionary = _scheduler_bindings(w, context)
	if not w.hero.snapshot_error(context.players.hero).is_empty() or not w.scheduler.snapshot_error(context.controllers.controller, scheduler_bindings).is_empty() or not w.protocol.unit_error(context.sources["native-source"], _pair(context)).is_empty(): return false
	for id: String in context.fields:
		if not w.bindings.fields[id].snapshot_error(context.fields[id]).is_empty(): return false
	for id: String in context.fields:
		if not w.bindings.fields[id].restore_state(context.fields[id]): return false
	if not w.hero.restore_state(context.players.hero): return false
	w.source.restore_physical(context.sources["native-source"])
	if not w.scheduler.restore_state(context.controllers.controller, scheduler_bindings): return false
	w.source.restore_exchange(context.sources["native-source"])
	return true


func _pair(context: Dictionary) -> Dictionary:
	return {"controllers": context.controllers, "players": context.players}


func _until_clock(scheduler: CinderThreatScheduler, deadline: float) -> void:
	for _tick: int in range(180):
		if scheduler.get_clock() >= deadline: return
		await _ticks(1)
	_expect(false, "actual Scheduler deadline timed out")


func _wait_phase(w: Dictionary, phase: String) -> void:
	for _tick: int in range(180):
		if w.protocol.response_state().get("phase") == phase: return
		await _ticks(1)
	_expect(false, "actual native episode did not reach " + phase)


func _ticks(count: int) -> void:
	for _tick: int in range(count):
		await physics_frame
		await process_frame


func _dispose(w: Dictionary) -> void:
	paused = false
	if w.has("viewport") and is_instance_valid(w.viewport): w.viewport.free()
	await process_frame


func _same(left: Variant, right: Variant) -> bool:
	var bytes: String = Exact.stringify(left)
	return not bytes.is_empty() and bytes == Exact.stringify(right)


func _next_float(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes.encode_u64(0, bytes.decode_u64(0) + 1)
	return bytes.decode_double(0)


func _expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)


func _finish() -> void:
	print("Scheduler spore source smoke: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
