extends "res://tests/acts/act1/a1_l3_spore_component.gd"
## Actual isolated C31 leased cancellation in two fresh
## Games. ONLY test-only injury injection is public take_damage called from a
## genuine Scheduler spore_repulsion invalidation observer. No HP/pose/clock/
## lease/phase seed, controller command, field activation bypass or full-L3 claim.
## Shared passive reload stays live; inherited primary stages shells0 at release.

const CallbackSource: String = "umbrella-1"
const CallbackController: String = "mushroom-scheduler"
const CallbackField: String = "component-mushroom"
const CallbackImpulse := Vector3(0.5, 2.0, 0.0)
var callback_cases: Array[Dictionary] = []
var callback_case: Dictionary = {}
var callback_actor: Act1MushroomSelenite
var callback_consumer: CinderSporeRepulsion
var callback_lease: String = ""
var callback_mode: String = ""
var inside_cancel_observer: bool = false
var state_attempted: bool = false
var previous_world_ids: Dictionary = {}


func _run() -> void:
	root.size = PortraitSize
	# This first bounded callback draft is headless-capable. No authored portrait
	# readability claim; the separate component retains actual renderer evidence.
	portrait = false
	for mode: String in ["survivor", "fatal"]:
		if not await _callback_world(mode):
			await _finish(); return
		if not await _dispose_callback_world():
			await _finish(); return
	await _finish()


func _callback_world(mode: String) -> bool:
	if not await _open_spore_world(SporeGrovePath, "grove", Vector3(0.0, 0.1, 15.0)):
		return false
	_watch_pair_events()
	callback_mode = mode
	callback_case = {"mode": mode, "calls": 0, "results": [], "state_result": {}, "defeats": 0, "defeat_view": {}, "capture_before_rejected": false, "capture_after_rejected": false, "pause_requested": false}
	state_attempted = false
	inside_cancel_observer = false
	callback_actor = sources[CallbackSource] as Act1MushroomSelenite
	if not await _wait(func() -> bool: return bool(level.get("spores_ready")), mode + " actual C31 binds native environment after real physics grounding"):
		return false
	callback_consumer = level.get("spore_consumer") as CinderSporeRepulsion
	var ids: Dictionary = {"game": game.get_instance_id(), "hero": hero.get_instance_id(), "actor": callback_actor.get_instance_id(), "scheduler": scheduler.get_instance_id(), "consumer": callback_consumer.get_instance_id()}
	for key: String in previous_world_ids:
		if not _require(ids[key] != previous_world_ids[key], mode + " fresh actual " + key + " identity is independent of the previous callback world"):
			return false
	previous_world_ids = ids.duplicate()
	callback_case["actual_ids"] = ids
	if not await _swipe(Vector3.FORWARD, mode + " genuine C31 warning approach"):
		return false
	if not await _wait(func() -> bool: return _running_warning(CallbackSource), mode + " genuine opt-in C31 stops/aligns and receives one native warning lease"):
		return false
	var actual: Dictionary = callback_actor.state()
	callback_lease = String(actual.reservation_id)
	var admitted: Dictionary = admissions.get(callback_lease, {})
	var native: Dictionary = scheduler.source_control_state(callback_actor)
	if not _require(admitted.get("accepted", false) and admitted.reservation.source_instance_id == callback_actor.get_instance_id() and admitted.reservation.adapter.kind == "lunge" and callback_actor.velocity == Vector3.ZERO and not actual.approach_driving and native.outside_transaction and native.reservations.size() == 1 and native.reservations[0].id == callback_lease and native.cooldown != null and callback_actor.hp == 16.0 and not callback_actor.dead and callback_actor.get_spore_response_state().phase == "none", mode + " original actual stopped C31 lease/cooldown/config/HP are genuine before the harmless field"):
		return false
	callback_case["admission"] = admitted.duplicate(true)
	callback_case["original_cooldown"] = native.cooldown.duplicate(true)
	callback_case["actor_hp_before"] = callback_actor.hp
	callback_case["hero_hp_before"] = hero.hp
	scheduler.reservation_invalidated.connect(_on_native_spore_invalidated)
	callback_actor.state_changed.connect(_on_callback_damage_state)
	callback_actor.defeated.connect(_on_callback_defeat)
	var field: CinderSporeField = level.get("spore_field") as CinderSporeField
	# Inherited helper also requires exactly one primary record with hits0, exact
	# last-release aim and no blast. The source remains beyond direct primary
	# range; actual injected injury is confined to the Scheduler callback below.
	if not _require(_planar_distance(hero.global_position, callback_actor.global_position) > float(hero.equipment.resolved_stats().primary_range) + float(callback_actor.get_spore_response_state().support_radius), mode + " living source is outside direct primary reach so callback injury cannot be confused with the mushroom hit"):
		return false
	if not await _cluster_primary(field.get_node("cluster-right") as Node3D, mode + " real ordinary-primary field release", true):
		return false
	if not _require(paused and callback_case.calls == 1 and callback_case.pause_requested and callback_case.capture_before_rejected and callback_case.capture_after_rejected and callback_case.results.size() == 2 and callback_case.results[0].accepted and not callback_case.results[1].accepted and state_attempted and not callback_case.state_result.accepted, mode + " genuine invalidation admits exactly one public injury, rejects repeated/depth2 injury and callback capture, then reaches public deferred pause"):
		return false
	var before_response: Dictionary = callback_case.response_before
	if not _require(before_response.alive and before_response.phase == "recoil" and not before_response.episode_id.is_empty() and before_response.progress == 0.0 and not before_response.outside_transaction and callback_case.hp_at_callback == callback_case.actor_hp_before, mode + " genuine recoil stamp is already published before native cancellation injury observers"):
		return false
	var pre: Dictionary = callback_case.control_before
	var post: Dictionary = callback_case.control_after
	if not _require(pre.clock_s == post.clock_s and pre.encounter_id == post.encounter_id and pre.world_revision == post.world_revision and not pre.outside_transaction and not post.outside_transaction and pre.reservations.is_empty() and post.reservations.is_empty() and Exact.stringify(pre.cooldown) == Exact.stringify(callback_case.original_cooldown), mode + " literal cancellation callback keeps the same native tick/encounter/world and already-cleared lease"):
		return false
	if not _require(hero.hp == callback_case.hero_hp_before and hero.hp == initial_hp and hit_events.is_empty() and field.state().generation == 1 and field.state().spent_ids == ["cluster-right"] and callback_consumer.placement_accepted(), mode + " field/explicit callback injury never damages Hero, refreshes supply or creates enemy hit/kill credit"):
		return false
	if mode == "survivor":
		var immediate: Dictionary = callback_case.response_after
		if not _require(callback_actor.hp == 14.0 and not callback_actor.dead and callback_case.results[0].hp_damage == 2.0 and immediate.alive and immediate.velocity == CallbackImpulse and immediate.hurt_remaining_s == 0.22 and immediate.phase == "interrupted" and immediate.progress == 0.0 and not immediate.outside_transaction and callback_case.defeats == 0 and Exact.stringify(pre.cooldown) == Exact.stringify(post.cooldown), "survivor genuine nested injury preserves exact HP/full impulse/hurt and original native cooldown before observers"):
			return false
		var reaction: Dictionary = callback_consumer.source_state(CallbackSource)
		if not _require(reaction.phase == "interrupted" and reaction.route.is_empty() and scheduler.source_control_state(callback_actor).reservations.is_empty(), "survivor real interruption rejects Route acquisition and hidden native lease"):
			return false
	else:
		var death: Dictionary = callback_case.defeat_view
		var shape: CollisionShape3D = callback_actor.get_node("BodyCollision") as CollisionShape3D
		if not _require(callback_actor.hp == 0.0 and callback_actor.dead and callback_case.results[0].hp_damage == 16.0 and callback_case.defeats == 1 and not death.response.alive and death.response.phase == "none" and death.response.episode_id.is_empty() and death.response.progress == 0.0 and death.disabled and death.layer == 0 and death.mask == 0 and not death.visible and not death.enemies and death.consumer_empty and death.control.reservations.is_empty() and death.control.cooldown == null and shape.disabled and post.cooldown == null and callback_consumer.source_state(CallbackSource).is_empty(), "fatal actual HP0/collider/group/bound-none/coordinator/native cooldown are committed before one defeat observer"):
			return false
	# Deferred pause may include a legitimate final physical tick of real hurt.
	# Exact callback impulse was checked above; later complete unit must preserve
	# the actual settled slice, not pretend no native time/motion occurred.
	var unit: Dictionary = level.call("component_unit_state")
	if not _require(not unit.is_empty() and String(level.call("component_unit_error", unit)).is_empty() and unit.player.resources.hp == initial_hp and unit.player.resources.shells == 0 and unit.actors[CallbackSource].hp == (14.0 if mode == "survivor" else 0.0) and unit.actors[CallbackSource].reservation_id.is_empty() and unit.scheduler.clock_s >= post.clock_s, mode + " deferred barrier captures genuine complete Player/all actors/Scheduler/field/consumer without HP/ammo/motion seeds"):
		return false
	if not _quiet_component(mode + " cancellation whole native unit"):
		return false
	callback_case["paused_unit"] = unit.duplicate(true)
	if mode == "fatal" and not _removed_defeat(unit):
		return false
	callback_case["world_actions"] = _portable(world_records)
	callback_case["input_observations"] = _portable(input_observations)
	callback_cases.append(callback_case.duplicate(true))
	return true


func _on_native_spore_invalidated(id: String, reason: String) -> void:
	if id != callback_lease or reason != "spore_repulsion" or callback_case.calls != 0:
		return
	callback_case.calls += 1
	inside_cancel_observer = true
	callback_case["control_before"] = scheduler.source_control_state(callback_actor).duplicate(true)
	callback_case["response_before"] = callback_actor.get_spore_response_state().duplicate(true)
	callback_case["hp_at_callback"] = callback_actor.hp
	callback_case.capture_before_rejected = (level.call("component_unit_state") as Dictionary).is_empty()
	var amount: float = callback_actor.hp if callback_mode == "fatal" else 2.0
	# Explicit test-only public injury, triggered ONLY by this real native signal.
	# It is not an environmental damage mechanic or ordinary-primary route proof.
	callback_case.results.append(callback_actor.take_damage(amount, CallbackImpulse))
	callback_case.results.append(callback_actor.take_damage(1.0, Vector3.ZERO))
	callback_case["response_after"] = callback_actor.get_spore_response_state().duplicate(true)
	callback_case["control_after"] = scheduler.source_control_state(callback_actor).duplicate(true)
	callback_case.capture_after_rejected = (level.call("component_unit_state") as Dictionary).is_empty()
	callback_case.pause_requested = game.call("request_pause_deferred")
	inside_cancel_observer = false


func _on_callback_damage_state(_state: Dictionary) -> void:
	if not inside_cancel_observer or state_attempted:
		return
	state_attempted = true
	callback_case.state_result = callback_actor.take_damage(1.0, Vector3.ZERO)


func _on_callback_defeat(id: String) -> void:
	if id != CallbackSource: return
	callback_case.defeats += 1
	var shape: CollisionShape3D = callback_actor.get_node("BodyCollision") as CollisionShape3D
	callback_case["defeat_view"] = {"response": callback_actor.get_spore_response_state().duplicate(true), "control": scheduler.source_control_state(callback_actor).duplicate(true), "disabled": shape.disabled, "layer": callback_actor.collision_layer, "mask": callback_actor.collision_mask, "visible": callback_actor.visible, "enemies": callback_actor.is_in_group("enemies"), "consumer_empty": callback_consumer.source_state(CallbackSource).is_empty()}
	# Retain the genuine node through protocol's immediate post-callback proof.


func _removed_defeat(unit: Dictionary) -> bool:
	# Only AFTER complete real death capture/quiet validation. This is not a Main
	# missing-actor save test: parent aggregate requires its retained four actors.
	var protocol: RefCounted = (level.get("source_protocols") as Dictionary)[CallbackSource]
	var pair: Dictionary = {"controllers": {CallbackController: unit.scheduler}, "players": {"hero": unit.player}}
	var context: Dictionary = {"fields": unit.fields, "sources": {CallbackSource: unit.actors[CallbackSource]}, "controllers": pair.controllers, "players": pair.players}
	var genuine: Dictionary = unit.actors[CallbackSource].duplicate(true)
	var consumer_wire: String = Exact.stringify(unit.coordinator)
	var player_wire: String = Exact.stringify(hero.snapshot_state())
	var clock: float = scheduler.get_clock()
	_disconnect_callback_observers()
	callback_actor.free() # Actual retained defeated node, not synthetic envelope.
	callback_actor = null
	if not _require(String(protocol.call("unit_error", genuine, pair)).is_empty() and String(callback_consumer.snapshot_error(unit.coordinator, context)).is_empty() and Exact.stringify(unit.coordinator) == consumer_wire and Exact.stringify(hero.snapshot_state()) == player_wire and scheduler.get_clock() == clock, "removed actual defeated source validates its captured whole native tombstone through retained decoder without body/HP/clock fabrication"):
		return false
	var forged: Dictionary = genuine.duplicate(true)
	forged["dead"] = false
	forged["hp"] = 1.0
	return _require(not String(protocol.call("unit_error", forged, pair)).is_empty(), "missing living source cannot pass as a captured defeat tombstone")


func _disconnect_callback_observers() -> void:
	if is_instance_valid(scheduler) and scheduler.reservation_invalidated.is_connected(_on_native_spore_invalidated):
		scheduler.reservation_invalidated.disconnect(_on_native_spore_invalidated)
	if is_instance_valid(callback_actor):
		if callback_actor.state_changed.is_connected(_on_callback_damage_state): callback_actor.state_changed.disconnect(_on_callback_damage_state)
		if callback_actor.defeated.is_connected(_on_callback_defeat): callback_actor.defeated.disconnect(_on_callback_defeat)


func _dispose_callback_world() -> bool:
	paused = true
	_disconnect_callback_observers()
	var old_game: Node = game
	var old_hero: Node = hero
	var old_scheduler: Node = scheduler
	var old_consumer: Node = callback_consumer
	var retained: Array = sources.values().duplicate()
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(game):
		var effects: PixelEffects = game.get("fx") as PixelEffects
		if is_instance_valid(effects): effects.clear()
	await create_timer(0.5, true).timeout
	if is_instance_valid(game): game.free()
	sources.clear(); game = null; level = null; hero = null; scheduler = null
	callback_actor = null; callback_consumer = null
	paused = false
	await process_frame
	var freed: bool = not is_instance_valid(old_game) and not is_instance_valid(old_hero) and not is_instance_valid(old_scheduler) and not is_instance_valid(old_consumer)
	for actor: Variant in retained: freed = freed and not is_instance_valid(actor)
	return _require(freed and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("environment_attack_targets").is_empty(), "independent actual callback world teardown frees native/source/environment nodes and groups")


func _finish() -> void:
	if finishing: return
	finishing = true
	_disconnect_callback_observers()
	paused = true
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(game):
		var effects: PixelEffects = game.get("fx") as PixelEffects
		if is_instance_valid(effects): effects.clear()
	await create_timer(0.5, true).timeout
	if is_instance_valid(game): game.free()
	paused = false
	await process_frame
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	var path: String = "res://.cinder/l3-spore-callback-state-%d.json" % Time.get_ticks_usec()
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"scope": "two fresh actual C31 leased spore-cancel survivor/fatal components; explicit test-only public nested injury; no Main campaign/fresh recipient/whole route/portrait claim", "checks": checks, "failures": failures, "actual_swipes": swipes, "actual_primaries": primaries, "cases": _portable(callback_cases)}, "\t"))
		file.close()
		print("L3 NATIVE SPORE CALLBACK EVIDENCE ", ProjectSettings.globalize_path(path))
	else:
		checks += 1; failures += 1
		push_error("Callback evidence file is not writable")
	print("A1-L3 NATIVE SPORE CALLBACKS: %d checks, %d failures; %d real swipes/%d ordinary primaries; explicit isolated public injury only" % [checks, failures, swipes, primaries])
	quit(1 if failures else 0)
