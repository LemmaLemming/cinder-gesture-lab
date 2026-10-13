extends "res://tests/authored_echo_playback_smoke.gd"
## TEST ONLY genuine two-cycle stationary C52 lifecycle. The immutable source
## has HP32 before any admission; real default primary20 is nonlethal first,
## lethal second. Never assign HP/ammo/position/phase/clock after admission.
## InputHost and native tick/input helpers are inherited unchanged. Independent
## callback cases below are labelled controls, not the ordinary two-cycle route.
## Fresh quiet probe worlds never execute while the retained donor is alive.
const LifecycleActor = preload("res://tests/fixtures/authored_echo_lifecycle_actor.gd")
const EnemySequence = preload("res://scripts/combat/authored_enemy_sequence.gd")
const CycleReceipt = preload("res://scripts/combat/authored_echo_terminal_receipt.gd")
const FIRST_PLAYBACK: String = "test-only/lifecycle-playback-1"
const SECOND_PLAYBACK: String = "test-only/lifecycle-playback-2"


func _run() -> void:
	root.size = Vector2i(540, 1170)
	print("TEST ONLY native lifecycle: same retained HP32 owner, real first/second primaries, actual cooldown/tombstone expiry; paused initial zero ammo may naturally regenerate; no campaign/portrait/OS/human claim")
	await _two_cycles()
	await _binding_compatibility()
	await _nested_cue_cancel()
	# These unchanged genuine observer drivers now exercise managed API2. The
	# death case is an explicit direct-damage callback control, not route proof.
	for held: String in ["cue", "event", "state", "cue_death"]:
		await _held_delivery(held)
	print("Authored echo lifecycle smoke: %d checks, %d failures; same-owner two-cycle route plus isolated native callback/transport controls" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _definition() -> Dictionary:
	var result: Dictionary = super._definition()
	result["definition_id"] = "test-only/retained-c52-lifecycle"
	result.raw_role["max_hp"] = 32.0
	return result


func _arena(extreme: bool = false, settle: bool = true) -> Dictionary:
	# Same actual native construction as the released first-cycle fixture, with
	# the new exact source Script and managed lifecycle opt-in only. Fresh
	# recipients stay untracked/idle until public saved-recipe preparation.
	if settle: paused = false
	var viewport := SubViewport.new()
	viewport.name = "TestOnlyLifecycleWorld"
	viewport.size = Vector2i(270, 585)
	viewport.own_world_3d = true
	viewport.handle_input_locally = false
	root.add_child(viewport)
	var world := Node3D.new()
	world.name = "NativeWorld"
	viewport.add_child(world)
	var body := StaticBody3D.new()
	body.name = "DryFloor"
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector3(0, -0.5, 0)
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var box := BoxShape3D.new()
	box.size = Vector3(16, 1, 16)
	collision.shape = box
	body.add_child(collision)
	world.add_child(body)
	var camera := Camera3D.new()
	camera.name = "NativeCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7.2
	world.add_child(camera)
	camera.position = Vector3(0, 18, 13)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var hero = Player.new()
	hero.name = "ActualSharedPlayer"
	world.add_child(hero)
	hero.position = Vector3(0.6, 0.1, 0)
	var scheduler = Scheduler.new()
	scheduler.name = "ActualScheduler"
	world.add_child(scheduler)
	_expect(scheduler.begin_encounter("standard", "test-only/own-echo", 1), "actual lifecycle Scheduler begins one retained native encounter")
	var host = InputHost.new()
	host.name = "ActualRecognizerHost"
	host.player = hero
	host.world = world
	host.camera = camera
	root.add_child(host)
	if settle:
		await _ticks(8)
		paused = true
		await process_frame
		if extreme:
			for id: String in ["CLOTH-J1", "CLOTH-P2", "CLOTH-S2", "WEAPON-04"]: _expect(hero.equip_item(id), "legal initial extreme gear: " + id)
		var seed: Dictionary = hero.snapshot_state()
		seed.resources["shells"] = 0
		seed.clocks["reload_s"] = 0.0
		_expect(hero.restore_state(seed), "TEST ONLY paused initial zero-ammo seed, no post-admission resources assignment")
	var floors: Array = [{"collision": collision, "safe_rect": Rect2(-8, -8, 16, 16)}]
	var signature: Dictionary = ReplayProjection.floor_signature(world, floors)
	var context: Dictionary = {"world_root": world, "source_id": SOURCE_ID, "source_epoch": EPOCH, "generation": 1, "world_collision_fingerprint": scheduler.pure_collision_fingerprint(world), "world_floor_signature": signature.get("signature", [])}
	var source = LifecycleActor.new()
	source.name = "ActualFixedKnotC52"
	world.add_child(source)
	var prepared: Dictionary = {"world_revision": 1, "collision_fingerprint": context.world_collision_fingerprint, "floor_signature": context.world_floor_signature}
	_expect(source.initialize_source(SOURCE_ID, EPOCH, 1, _definition(), "standard", prepared) and source.attach_source_scheduler(scheduler) and source.retain_fixture_environment(world, floors), "actual immutable HP32 source retains own native renderer, recipe and actual floor environment")
	_expect(source.configure_authored(FIRST_PLAYBACK, source.source_program(), EPOCH, 1), "actual lifecycle source configures its genuine first authored program: " + source.last_error)
	var arena: Dictionary = {"viewport": viewport, "world": world, "floor": collision, "floors": floors, "camera": camera, "host": host, "player": hero, "scheduler": scheduler, "actor": source, "context": context}
	if settle:
		_expect(source.enable_authored_cycle_tracking(scheduler, {"hero": hero}, floors, context), "public first opt-in retains actual owner/Hero/controller with no previous lease/history: " + source.last_error)
		_expect(source.get_authored_cycle_generation() == 1 and source.state().status == "cycle_ready" and scheduler.authored_cycle_state(source).terminal_receipts.is_empty(), "first ready generation is exactly one with no invented terminal receipt")
	return arena


func _staged_bindings(arena: Dictionary, bundle: Dictionary) -> Dictionary:
	var result: Dictionary = super._bindings(arena, bundle.source)
	result["authored_cycle_playback_ids"] = {SOURCE_ID: bundle.playback.playback_id}
	return result


func _context_for(arena: Dictionary, generation: int) -> Dictionary:
	var result: Dictionary = arena.context.duplicate(true)
	result["generation"] = generation
	return result


func _next_program(arena: Dictionary, generation: int, definition: Dictionary = {}, world: Dictionary = {}) -> Dictionary:
	var reader = EnemySequence.new()
	var actual_definition: Dictionary = arena.actor.source_definition() if definition.is_empty() else definition
	var actual_world: Dictionary = arena.actor.prepared_world() if world.is_empty() else world
	var accepted: bool = reader.configure("test-only/lifecycle-cycle-%d" % generation, actual_definition, SOURCE_ID, EPOCH, generation, arena.actor.source_profile(), actual_world)
	_expect(accepted, "pure next-generation constructor uses the same native immutable recipe/world: " + reader.last_error)
	return reader.snapshot_state() if accepted else {}


func _resources(arena: Dictionary) -> Dictionary:
	var renderer: Node3D = arena.actor.get_enemy_apparition()
	var visual: MeshInstance3D = renderer.get("visual")
	return {"owner": arena.actor.get_instance_id(), "hero": arena.player.get_instance_id(), "scheduler": arena.scheduler.get_instance_id(), "script": arena.actor.get_script().get_instance_id(), "renderer": renderer.get_instance_id(), "mesh": visual.mesh.get_instance_id(), "material": visual.material_override.get_instance_id(), "source_transform": arena.actor.global_transform, "descriptor": arena.actor.native_descriptor()}


func _two_cycles() -> void:
	var arena: Dictionary = await _arena()
	var retained: Dictionary = _resources(arena)
	var source_hp: float = arena.actor.hp
	var hero_hp: float = arena.player.hp
	var actions: Array[String] = []
	var dispatched: Array[String] = []
	arena.player.world_action_executed.connect(func(record: Dictionary) -> void: actions.append(record.kind))
	arena.actor.event_dispatched.connect(func(event: Dictionary, _receipt: Dictionary) -> void:
		dispatched.append(event.event_id)
		_expect(not arena.actor.advance().get("accepted", false), "nested actual dispatch cannot redeliver current cycle prefix")
	)
	_expect(source_hp == 32.0 and arena.actor.max_hp == 32.0 and arena.player.stats.primary_damage == 20.0 and arena.player.shells == 0, "immutable initial HP32 and genuine ordinary primary20 make the first hit nonlethal; entry ammo is zero")
	var first: Dictionary = _install(arena)
	if first.is_empty(): await _dispose(arena); return
	var proof: Dictionary = await _lock(arena, first)
	if proof.is_empty() or not await _return_and_primary(arena, proof, retained, hero_hp): await _dispose(arena); return
	_expect(arena.actor.hp == 12.0 and not arena.actor.dead and arena.actor.source_hits == 1 and arena.actor.get_authored_cycle_generation() == 1 and actions == ["dash", "dash", "primary"], "first real shared return/primary leaves the same owner alive HP12 with no blast or private reset")
	await _until(arena, float(first.lease.recovery_until_s) + 0.02)
	paused = true
	await process_frame
	var complete: Dictionary = _capture(arena, "lifecycle-complete-before-expiry")
	if complete.is_empty(): await _dispose(arena); return
	var receipt_one: Dictionary = complete.playback.lifecycle.terminal_receipts[0].duplicate(true)
	_expect(complete.playback.status == "complete" and complete.playback.lifecycle.stage == "terminal" and complete.playback.lifecycle.terminal_receipts.size() == 1 and receipt_one.outcome == "complete" and receipt_one.generation == 1 and receipt_one.opportunities.size() == 1 and not receipt_one.opportunities[0].contact and float(complete.scheduler.clock_s) < float(receipt_one.exchange.cooldown_until_s), "real completed first exchange seals its consumed miss and original cooldown before expiry")
	var calls_before: int = arena.actor.test_native_advance_calls
	var cursor_before: Dictionary = arena.actor.get("_cursor").snapshot_state()
	var pose_before: Dictionary = arena.actor.get_enemy_apparition().native_pose()
	var dispatched_before: Array = dispatched.duplicate()
	var clock_before: float = arena.scheduler.get_clock()
	paused = false
	await _ticks(12)
	paused = true
	await process_frame
	_expect(arena.scheduler.get_clock() > clock_before and arena.actor.test_native_advance_calls == calls_before, "actual completed managed native ticks advance Scheduler independently without repeated inert actor advance scans")
	_expect(EnemySequence.exact_equal(arena.actor.get("_cursor").snapshot_state(), cursor_before) and EnemySequence.exact_equal(arena.actor.get_authored_cycle_terminal_receipt(), receipt_one) and arena.actor.get_enemy_apparition().native_pose() == pose_before and dispatched == dispatched_before and arena.actor.hp == 12.0 and arena.player.hp == hero_hp, "inert completed native frames retain exact original cursor/receipt, native pose, HP and once-only delivery")
	complete = _capture(arena, "lifecycle-complete-after-inert-ticks")
	if complete.is_empty(): await _dispose(arena); return
	await _quiet_same(arena, complete, "complete-before-expiry")
	await _quiet_fresh_probe(arena, complete, "complete-before-expiry")
	var next: Dictionary = _next_program(arena, 2)
	var before: String = Exact.stringify(_capture(arena, "lifecycle-before-early-refusal"))
	_expect(not arena.actor.prepare_next_authored_cycle(SECOND_PLAYBACK, next), "same actual owner cannot prepare next generation before original native cooldown")
	_expect(not arena.actor.configure_authored(SECOND_PLAYBACK, next, EPOCH, 2) and not arena.actor.enable_authored_cycle_tracking(arena.scheduler, {"hero": arena.player}, arena.floors, arena.context), "legacy reconfigure/initial opt-in cannot clear earned managed history")
	var early: Dictionary = arena.scheduler.request_authored_replay(arena.actor, next, _response(arena), _context_for(arena, 2))
	_expect(not early.get("accepted", false) and Exact.stringify(_capture(arena, "lifecycle-after-early-refusal")) == before and _resources(arena) == retained, "early rearm refusals leave HP/resources/prefix/history/original cooldown unchanged")
	await _same_id_owner_refusal(arena)
	paused = false
	await _until(arena, float(receipt_one.exchange.cooldown_until_s) + 0.02)
	paused = true
	await process_frame
	var later_complete: Dictionary = _capture(arena, "lifecycle-complete-after-expiry")
	if later_complete.is_empty(): await _dispose(arena); return
	_expect(EnemySequence.exact_equal(arena.actor.get_authored_cycle_terminal_receipt(), receipt_one) and later_complete.scheduler.cooldowns.is_empty(), "real clock expiry leaves the original completed receipt frozen, no regenerated native cooldown")
	_next_refusals(arena, next)
	_expect(arena.actor.prepare_next_authored_cycle(SECOND_PLAYBACK, next), "same actual surviving owner prepares exactly generation2 after original cooldown: " + arena.actor.last_error)
	arena.context["generation"] = 2
	_expect(_resources(arena) == retained and arena.actor.hp == 12.0 and arena.actor.source_hits == 1 and not arena.actor.dead and arena.actor.get_authored_cycle_generation() == 2 and arena.actor.get_authored_cycle_terminal_receipt().is_empty(), "successful preparation preserves original HP/native objects and retires only the current exchange, not earlier history")
	var ready: Dictionary = _capture(arena, "lifecycle-ready-two")
	if ready.is_empty(): await _dispose(arena); return
	_expect(ready.playback.size() == 12 and ready.playback.status == "cycle_ready" and ready.playback.generation == 2 and ready.playback.lifecycle.terminal_receipts == [receipt_one] and not ready.playback.has("exchange") and not ready.playback.has("cursor") and not ready.playback.has("opportunities"), "ready2 has its closed12-key prospective program and exact predecessor, no fabricated current admission/events")
	await _quiet_same(arena, ready, "ready-two")
	await _quiet_fresh_probe(arena, ready, "ready-two")
	var second: Dictionary = _install(arena)
	if second.is_empty(): await _dispose(arena); return
	paused = true
	await process_frame
	var running: Dictionary = _capture(arena, "lifecycle-running-two")
	if running.is_empty(): await _dispose(arena); return
	_expect(running.playback.status == "running" and running.playback.generation == 2 and running.playback.lifecycle.stage == "running" and running.playback.lifecycle.terminal_receipts == [receipt_one] and running.scheduler.reservations.size() == 1 and not running.playback.cursor.armed and running.playback.opportunities.is_empty() and running.playback.reservation_id != receipt_one.exchange.id, "second actual preview has one new lease and unchanged predecessor; no past event or third admission")
	await _quiet_same(arena, running, "running-two")
	await _quiet_fresh_probe(arena, running, "running-two")
	_history_negatives(arena, running, complete)
	paused = false
	proof = await _lock(arena, second)
	if proof.is_empty(): await _dispose(arena); return
	var defeated_calls: Array[int] = [0]
	arena.actor.source_defeated.connect(func(_hit: Dictionary) -> void:
		defeated_calls[0] += 1
		var receipt: Dictionary = arena.actor.get_authored_cycle_terminal_receipt()
		_expect(not receipt.is_empty() and receipt.reason == "authored_source_defeated" and receipt.generation == 2 and arena.scheduler.authored_cycle_state(arena.actor).stage == "terminal", "actual source death seals its original cancellation/history before death observers")
		_expect(not arena.actor.prepare_next_authored_cycle("test-only/lifecycle-playback-3", _next_program(arena, 3)), "actual death observer cannot recursively rearm or revive the source")
		paused = true
	)
	if not await _return_and_primary(arena, proof, retained, hero_hp): await _dispose(arena); return
	await process_frame
	_expect(paused and defeated_calls[0] == 1 and arena.actor.dead and arena.actor.hp == 0.0 and arena.actor.max_hp == 32.0 and arena.actor.source_hits == 2 and actions == ["dash", "dash", "primary", "dash", "dash", "primary"] and dispatched.size() == 2 and dispatched[0] != dispatched[1] and _resources(arena) == retained, "same native owner completes both ordinary routes and dies only to its second real primary, with distinct once-only slash events and no HP/resource reset")
	var cancelled: Dictionary = _capture(arena, "lifecycle-cancel-before-expiry")
	if cancelled.is_empty(): await _dispose(arena); return
	var receipt_two: Dictionary = cancelled.playback.lifecycle.terminal_receipts[1].duplicate(true)
	_expect(cancelled.playback.status == "cancelled" and cancelled.playback.lifecycle.terminal_receipts == [receipt_one, receipt_two] and cancelled.source.defeated_at_s == receipt_two.terminal_at_s and cancelled.playback.cancelled_at_s == receipt_two.terminal_at_s and cancelled.scheduler.replay_cancellations.size() == 1, "original actual gen2 defeat carries exact cancelled prefix/deadline and retained cancellation tombstone")
	await _quiet_same(arena, cancelled, "cancel-before-expiry")
	await _quiet_fresh_probe(arena, cancelled, "cancel-before-expiry")
	paused = false
	await _until(arena, float(receipt_two.exchange.cooldown_until_s) + 0.10)
	paused = true
	await process_frame
	var late: Dictionary = _capture(arena, "lifecycle-late-dead")
	if late.is_empty(): await _dispose(arena); return
	_expect(late.scheduler.get("replay_cancellations", []).is_empty() and late.scheduler.cooldowns.is_empty() and float(late.scheduler.clock_s) > float(receipt_two.exchange.cooldown_until_s) and late.source.hp == 0.0 and late.source.defeated_at_s == receipt_two.terminal_at_s and late.playback.cancelled_at_s == receipt_two.terminal_at_s and late.playback.clock_s > late.playback.cancelled_at_s and EnemySequence.exact_equal(late.playback.lifecycle.terminal_receipts, [receipt_one, receipt_two]) and EnemySequence.exact_equal(late.playback.cursor, receipt_two.cursor) and EnemySequence.exact_equal(late.playback.opportunities, receipt_two.opportunities), "later real aggregate ticks prune live tombstone/cooldown but preserve trueHP0/original defeat time and both immutable original receipts/prefixes")
	_history_negatives(arena, late, complete)
	await _quiet_same(arena, late, "late-dead")
	var fresh: Dictionary = await _fresh(arena, late)
	if not fresh.is_empty():
		var quiet_events: Array[String] = []
		fresh.actor.event_dispatched.connect(func(_event: Dictionary, _receipt: Dictionary) -> void: quiet_events.append("event"))
		fresh.actor.source_defeated.connect(func(_hit: Dictionary) -> void: quiet_events.append("source-death"))
		_expect(fresh.actor.dead and fresh.actor.hp == 0.0 and fresh.actor.source_hits == 2 and fresh.actor.get_authored_cycle_generation() == 2 and fresh.actor.verify_restored_source_phase(late.source), "fresh paused late-dead world restores actual source HP/lifecycle/gen2 without revive or reexecution")
		await _retire(arena)
		arena = fresh
		var before_receipts: String = Exact.stringify(arena.actor.get_authored_cycle_terminal_receipt())
		var resource_ids: Dictionary = _resources(arena)
		paused = false
		await _ticks(12)
		_expect(arena.actor.advance().get("accepted", false) and arena.actor.state().status == "cancelled" and quiet_events.is_empty() and arena.actor.dead and arena.actor.hp == 0.0 and arena.player.hp == hero_hp and Exact.stringify(arena.actor.get_authored_cycle_terminal_receipt()) == before_receipts and _resources(arena) == resource_ids, "actual restored late-dead continuation stays inert with unchanged native resources/HP and zero past event/death callbacks")
		paused = true
		await process_frame
		var inert: String = Exact.stringify(_capture(arena, "lifecycle-dead-before-refusal"))
		_expect(not arena.actor.prepare_next_authored_cycle("test-only/lifecycle-playback-3", _next_program(arena, 3)) and not arena.scheduler.request_authored_replay(arena.actor, arena.actor.source_program(), _response(arena), arena.context).get("accepted", false) and Exact.stringify(_capture(arena, "lifecycle-dead-after-refusal")) == inert, "dead actual owner cannot regrant a lease, clear history or regenerate HP after original expiry")
	await _native_substitution_controls(arena, late)
	await _dispose(arena)


func _return_and_primary(arena: Dictionary, proof: Dictionary, retained: Dictionary, hero_hp: float) -> bool:
	for segment: Dictionary in proof.path:
		if segment.kind not in ["first_escape_dash", "tether_positioning_dash"]: continue
		await _until(arena, float(segment.start_s))
		if not _swipe(arena, (segment.to - segment.from).normalized()): _expect(false, "real inherited touch/drag/release accepted proof dash"); return false
		await _finished_dash(arena)
		_expect(_resources(arena) == retained and arena.player.hp == hero_hp, "actual world dash moves Hero only; source body/renderer resources and HP stay fixed")
	await _until(arena, float(proof.primary_time_s))
	_expect(arena.actor.source_phase() == "recovery" and arena.player.global_position.distance_to(arena.actor.global_position) <= float(arena.player.stats.primary_range), "real native return reaches the original fixed recovery knot in ordinary primary range")
	var ammo: int = arena.player.shells
	var primary_ok: bool = _tap(arena, (arena.actor.global_position - arena.player.global_position).normalized())
	_expect(primary_ok and arena.player.shells >= ammo and arena.player.hp == hero_hp, "actual first tap aims from last screen release and uses ordinary primary, without blast ammo spending or movement damage")
	return primary_ok


func _capture(arena: Dictionary, label: String) -> Dictionary:
	var bundle: Dictionary = super._capture(arena, "lifecycle-" + label)
	if bundle.is_empty(): return {}
	_expect(bundle.playback.api_revision == "authored-echo-playback-2" and bundle.scheduler.schema_version is int and bundle.scheduler.schema_version == 3 and bundle.scheduler.authored_source_cycles.sources.size() == 1 and EnemySequence.exact_equal(bundle.source.lifecycle, bundle.playback.lifecycle) and EnemySequence.exact_equal(bundle.playback.lifecycle, bundle.scheduler.authored_source_cycles.sources[0]), label + " format2 disk retains actual Player/native source/API2 and conditional Scheduler3 one whole journal")
	return bundle


func _preflight_native(arena: Dictionary, bundle: Dictionary, bindings: Dictionary) -> String:
	var error: String = CycleReceipt.transport_error(bundle)
	if error.is_empty() and not Value.keys_error(bundle, ["player", "source", "scheduler", "playback"]).is_empty(): error = "Closed whole fixture unit required"
	if error.is_empty(): error = arena.player.snapshot_error(bundle.player)
	if error.is_empty(): error = arena.actor.source_record_error(bundle.source, bundle.player, bundle.scheduler, bundle.playback)
	if error.is_empty(): error = arena.scheduler.snapshot_error(bundle.scheduler, bindings)
	return error


func _pair_error(arena: Dictionary, bundle: Dictionary, bindings: Dictionary) -> String:
	var error: String = _preflight_native(arena, bundle, bindings)
	if error.is_empty(): error = arena.actor.snapshot_error(bundle.playback, arena.scheduler, bundle.scheduler, bindings, {"hero": arena.player}, arena.floors, _context_for(arena, int(bundle.playback.generation)))
	return error


func _fresh(_old: Dictionary, bundle: Dictionary) -> Dictionary:
	var fresh: Dictionary = await _arena(false, false)
	var callbacks: Array[String] = []
	fresh.actor.state_changed.connect(func(_state: Dictionary) -> void: callbacks.append("state"))
	fresh.actor.event_dispatched.connect(func(_event: Dictionary, _receipt: Dictionary) -> void: callbacks.append("event"))
	fresh.actor.source_hit_resolved.connect(func(_hit: Dictionary) -> void: callbacks.append("hit"))
	fresh.actor.source_defeated.connect(func(_hit: Dictionary) -> void: callbacks.append("defeat"))
	fresh.actor.get_enemy_apparition().pose_presented.connect(func(_pose: Dictionary) -> void: callbacks.append("renderer"))
	fresh.scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: callbacks.append("invalidation"))
	fresh.player.fired.connect(func(_kind: String) -> void: callbacks.append("player-fired"))
	fresh.player.died.connect(func() -> void: callbacks.append("player-death"))
	fresh.player.equipment_changed.connect(func(_id: String) -> void: callbacks.append("equipment"))
	fresh.player.world_action_executed.connect(func(_record: Dictionary) -> void: callbacks.append("player-action"))
	var context: Dictionary = _context_for(fresh, int(bundle.playback.generation))
	var bindings: Dictionary = _staged_bindings(fresh, bundle)
	var error: String = _preflight_native(fresh, bundle, bindings)
	_expect(error.is_empty(), "fresh native Player/source/Scheduler staged preflight precedes recipe preparation: " + error)
	if not error.is_empty(): await _retire(fresh); return {}
	var prepared: bool = fresh.actor.prepare_authored_restore(bundle.playback, fresh.scheduler, {"hero": fresh.player}, fresh.floors, context)
	_expect(prepared, "public fresh immutable saved-generation recipe preparation changes no actual HP/clock/history: " + fresh.actor.last_error)
	if not prepared: await _retire(fresh); return {}
	var recipe: Dictionary = fresh.actor.get_authored_cycle_restore_recipe()
	_expect(recipe.get("playback_id", "") == bundle.playback.playback_id and EnemySequence.exact_equal(recipe.get("lifecycle", {}), bundle.playback.lifecycle) and fresh.actor.get_authored_cycle_terminal_receipt().is_empty() and fresh.actor.hp == 32.0 and fresh.actor.source_hits == 0 and fresh.scheduler.get_clock() == 0.0, "prepared recipe is distinct from an earned terminal receipt; true physical and Scheduler state are still pristine")
	fresh.context = context
	for cue: Node3D in fresh.actor.get_cues(): cue.state_changed.connect(func(_state: Dictionary) -> void: callbacks.append("cue"))
	error = _pair_error(fresh, bundle, bindings)
	_expect(error.is_empty(), "prepared current program fully prevalidates whole paired unit before authoritative physical/history commit: " + error)
	if not error.is_empty(): await _retire(fresh); return {}
	_expect(not fresh.actor.restore_state(bundle.playback, fresh.scheduler, bundle.scheduler, bindings, {"hero": fresh.player}, fresh.floors, context), "actual Playback cannot restore before the paired actor/Scheduler commit")
	var accepted: bool = fresh.player.restore_state(bundle.player) and fresh.actor.restore_source_physical(bundle.source, bundle.player, bundle.scheduler, bundle.playback)
	if accepted: accepted = fresh.scheduler.restore_state(bundle.scheduler, super._bindings(fresh))
	if accepted:
		var actual_packet: Dictionary = fresh.scheduler.snapshot_state_for_authored_restore(fresh.actor, super._bindings(fresh))
		accepted = EnemySequence.exact_equal(actual_packet, bundle.scheduler)
		_expect(accepted and fresh.actor.get_authored_cycle_terminal_receipt().is_empty(), "distinct paused restore-only actual packet joins true source HP/gen and real Scheduler, without fabricating an earned terminal getter")
	if accepted: accepted = fresh.actor.restore_state(bundle.playback, fresh.scheduler, bundle.scheduler, super._bindings(fresh), {"hero": fresh.player}, fresh.floors, context)
	if accepted: accepted = fresh.actor.verify_restored_source_phase(bundle.source)
	_expect(accepted and callbacks.is_empty(), "quiet actual Player -> source physical -> Scheduler3 -> Playback2 restores current phase/history/native renderer without callbacks: " + fresh.actor.last_snapshot_error + "/" + fresh.actor.source_snapshot_error)
	if not accepted: await _retire(fresh); return {}
	_expect(fresh.actor.get_authored_cycle_restore_recipe().is_empty() and Exact.stringify(fresh.player.snapshot_state()) == Exact.stringify(bundle.player) and EnemySequence.exact_equal(fresh.actor.capture_source(bundle.player, bundle.scheduler, bundle.playback), bundle.source) and EnemySequence.exact_equal(fresh.actor.get_authored_cycle_program(), bundle.source.sequence), "finished fresh pair removes construction-only recipe and preserves exact saved resources/gen/program/physical state")
	return fresh


func _quiet_fresh_probe(arena: Dictionary, bundle: Dictionary, label: String) -> void:
	var fresh: Dictionary = await _fresh(arena, bundle)
	if fresh.is_empty(): return
	var before: String = Exact.stringify(_capture(fresh, "fresh-quiet-" + label))
	await create_timer(0.04, true).timeout
	_expect(paused and Exact.stringify(_capture(fresh, "fresh-quiet-repeat-" + label)) == before, label + " fresh recipient remains paused with original clocks/resources and zero redelivery")
	# A probe never executes while donor remains. Only the final late-dead
	# reconstruction retires the donor and continues the fresh recipient.
	await _retire(fresh)


func _quiet_same(arena: Dictionary, bundle: Dictionary, label: String) -> void:
	var callbacks: Array[String] = []
	var observer: Callable = func(_state: Dictionary) -> void: callbacks.append("state")
	arena.actor.state_changed.connect(observer)
	var bindings: Dictionary = super._bindings(arena)
	var error: String = _pair_error(arena, bundle, bindings)
	var accepted: bool = error.is_empty() and arena.player.restore_state(bundle.player) and arena.actor.restore_source_physical(bundle.source, bundle.player, bundle.scheduler, bundle.playback) and arena.scheduler.restore_state(bundle.scheduler, bindings) and arena.actor.restore_state(bundle.playback, arena.scheduler, bundle.scheduler, bindings, {"hero": arena.player}, arena.floors, arena.context)
	_expect(accepted and callbacks.is_empty() and EnemySequence.exact_equal(arena.actor.capture_source(bundle.player, bundle.scheduler, bundle.playback), bundle.source), label + " same actual current pair restores quietly without HP/history rollback: " + error)
	arena.actor.state_changed.disconnect(observer)


func _next_refusals(arena: Dictionary, next: Dictionary) -> void:
	var before: String = Exact.stringify(_capture(arena, "next-refusal-before"))
	var reused: Dictionary = next.duplicate(true)
	var numeric: Dictionary = next.duplicate(true)
	numeric["generation"] = 2.0
	var raw: Dictionary = arena.actor.source_definition()
	raw.slash["reach"] = _one_bit(float(raw.slash.reach))
	var changed_definition: Dictionary = _next_program(arena, 2, raw)
	var world: Dictionary = arena.actor.prepared_world()
	world["world_revision"] = 2
	var changed_world: Dictionary = _next_program(arena, 2, {}, world)
	_expect(not arena.actor.prepare_next_authored_cycle(FIRST_PLAYBACK, reused), "retired Playback identity cannot be reused at actual cooldown expiry")
	_expect(not arena.actor.prepare_next_authored_cycle(SECOND_PLAYBACK, numeric), "equal float generation cannot replace canonical integer generation")
	_expect(not arena.actor.prepare_next_authored_cycle(SECOND_PLAYBACK, _next_program(arena, 3)), "same actual owner cannot skip the contiguous next generation")
	_expect(not arena.actor.prepare_next_authored_cycle(SECOND_PLAYBACK, changed_definition) and not arena.actor.prepare_next_authored_cycle(SECOND_PLAYBACK, changed_world), "next cycle cannot substitute one-bit raw definition or actual world revision")
	_expect(Exact.stringify(_capture(arena, "next-refusal-after")) == before, "all malformed next preparations are atomic for actual HP/cooldown/native resources/history")


func _history_negatives(arena: Dictionary, bundle: Dictionary, previous: Dictionary) -> void:
	var before: String = Exact.stringify(_capture(arena, "history-negative-before"))
	var bads: Dictionary = {}
	var changed: Dictionary = bundle.duplicate(true)
	changed.source["generation"] = float(changed.source.generation)
	bads["float native generation"] = changed
	changed = bundle.duplicate(true)
	changed.source["clock_s"] = _one_bit(float(changed.source.clock_s))
	bads["one-bit copied aggregate clock"] = changed
	changed = bundle.duplicate(true)
	changed.playback["clock_s"] = int(changed.playback.clock_s)
	bads["integer copied clock"] = changed
	changed = bundle.duplicate(true)
	changed.source.sequence.definition.slash["reach"] = _one_bit(float(changed.source.sequence.definition.slash.reach))
	bads["one-bit native definition"] = changed
	changed = bundle.duplicate(true)
	changed.source.native.size[0] = _one_bit(float(changed.source.native.size[0]))
	bads["one-bit native resource descriptor"] = changed
	changed = bundle.duplicate(true)
	changed.source["source_epoch"] = "test-only/foreign-epoch"
	bads["foreign actor epoch"] = changed
	changed = bundle.duplicate(true)
	for entry: Dictionary in [changed.source.lifecycle, changed.playback.lifecycle, changed.scheduler.authored_source_cycles.sources[0]]: entry.terminal_receipts.remove_at(0)
	bads["omitted predecessor receipt"] = changed
	changed = bundle.duplicate(true)
	for entry: Dictionary in [changed.source.lifecycle, changed.playback.lifecycle, changed.scheduler.authored_source_cycles.sources[0]]: entry.terminal_receipts[0].exchange["cooldown_until_s"] = _one_bit(float(entry.terminal_receipts[0].exchange.cooldown_until_s))
	bads["rewritten original cooldown"] = changed
	changed = bundle.duplicate(true)
	for entry: Dictionary in [changed.source.lifecycle, changed.playback.lifecycle, changed.scheduler.authored_source_cycles.sources[0]]: entry.terminal_receipts.append(entry.terminal_receipts[0].duplicate(true))
	bads["duplicate retired identity/history"] = changed
	if bundle.source.hp == 0.0:
		changed = bundle.duplicate(true)
		changed.source["hp"] = 32.0
		changed.source["alive"] = true
		changed.source["phase"] = "cancelled"
		changed.source["defeated_at_s"] = null
		bads["revived physical source"] = changed
		changed = bundle.duplicate(true)
		changed.playback.opportunities[0]["damage_attempted"] = not changed.playback.opportunities[0].damage_attempted
		bads["rewritten consumed opportunity"] = changed
	for name: String in bads:
		var bad: Dictionary = bads[name]
		_expect(not _pair_error(arena, bad, _staged_bindings(arena, bad)).is_empty() and Exact.stringify(_capture(arena, "history-negative-after-" + str(_checks))) == before, "closed actual paired " + name + " rejects without HP/prefix/history/resources mutation")
	_expect(not arena.scheduler.snapshot_error(previous.scheduler, _staged_bindings(arena, previous)).is_empty(), "same retained native owner rejects a structurally valid earlier generation/history packet, no rewind")
	_expect(not arena.actor.prepare_authored_restore(previous.playback, arena.scheduler, {"hero": arena.player}, arena.floors, _context_for(arena, 1)), "fresh preparation API cannot reset a previously admitted actual owner")
	_expect(Exact.stringify(_capture(arena, "history-negative-final")) == before, "failed downgrade/fresh-preparation leave exact current whole native unit unchanged")


func _same_id_owner_refusal(arena: Dictionary) -> void:
	var before: String = Exact.stringify(_capture(arena, "same-id-before"))
	var other = LifecycleActor.new()
	other.name = "TestOnlyRejectedSameIdSource"
	arena.world.add_child(other)
	_expect(other.initialize_source(SOURCE_ID, EPOCH, 1, arena.actor.source_definition(), "standard", arena.actor.prepared_world()) and other.attach_source_scheduler(arena.scheduler) and other.retain_fixture_environment(arena.world, arena.floors) and other.configure_authored("test-only/forbidden-cloned-owner", other.source_program(), EPOCH, 1), "labelled negative builds a same-ID fresh physical source without executing or copying earned HP/history")
	_expect(not other.enable_authored_cycle_tracking(arena.scheduler, {"hero": arena.player}, arena.floors, _context_for(arena, 1)), "same stable ID cannot rebind retained Scheduler history to a different actual owner")
	other.free()
	_expect(Exact.stringify(_capture(arena, "same-id-after")) == before, "same-ID refusal preserves original native HP/cooldown/receipt and frees the unused negative source")


func _registration_candidate(arena: Dictionary, world: Node3D, source_id: String) -> Dictionary:
	# Each candidate has a genuine individually valid native source/program.
	# Only registration negatives, never a replacement for an earned owner.
	var signature: Dictionary = ReplayProjection.floor_signature(world, arena.floors)
	var context: Dictionary = {"world_root": world, "source_id": source_id, "source_epoch": EPOCH, "generation": 1, "world_collision_fingerprint": arena.scheduler.pure_collision_fingerprint(world), "world_floor_signature": signature.get("signature", [])}
	var prepared: Dictionary = {"world_revision": 1, "collision_fingerprint": context.world_collision_fingerprint, "floor_signature": context.world_floor_signature}
	var source = LifecycleActor.new()
	source.name = "TestOnlyRegistrationCandidate"
	world.add_child(source)
	var initialized: bool = source.initialize_source(source_id, EPOCH, 1, arena.actor.source_definition(), "standard", prepared, source_id + "/sequence-1") and source.attach_source_scheduler(arena.scheduler) and source.retain_fixture_environment(world, arena.floors) and source.configure_authored(source_id + "/playback-1", source.source_program(), EPOCH, 1)
	var error: String = arena.scheduler.authored_replay_source_error(source, source.source_program(), context, arena.floors) if initialized else source.source_snapshot_error
	_expect(initialized and error.is_empty(), "registration control's own actual source/recipe/world/floor preflight passes independently: " + error)
	if not initialized or not error.is_empty(): source.free(); return {}
	return {"actor": source, "context": context}


func _binding_compatibility() -> void:
	var arena: Dictionary = await _arena()
	# Both possible root selections are genuine native ancestors. Reparenting
	# takes place while the first source is merely ready, before any admission;
	# the donor's inner-root collision/floor descriptors remain exactly unchanged.
	var outer := Node3D.new()
	outer.name = "ActualOuterRoot"
	arena.viewport.add_child(outer)
	arena.world.reparent(outer, true)
	var other_hero = Player.new()
	other_hero.name = "TestOnlyOtherActualHero"
	arena.world.add_child(other_hero)
	other_hero.position = Vector3(-4, 0.1, 3)
	paused = false
	await _ticks(8)
	paused = true
	await process_frame
	_expect(other_hero.is_node_ready() and other_hero.is_on_floor() and other_hero.get_threat_response_state().actor == other_hero and EnemySequence.exact_equal(arena.scheduler.pure_collision_fingerprint(arena.world), arena.context.world_collision_fingerprint), "genuine second settled Hero is excluded from the unchanged donor static collision fingerprint")
	var installed: Dictionary = _install(arena)
	if installed.is_empty(): await _dispose(arena); return
	paused = true
	await process_frame
	var original: Dictionary = _capture(arena, "binding-domain-before")
	if original.is_empty(): await _dispose(arena); return
	var native_cues: Array = []
	for cue: Node3D in arena.actor.get_cues(): native_cues.append(cue.state())
	_expect(arena.scheduler.replay_reservation_error(installed.id).is_empty() and native_cues[0].phase == "warning", "first actual preview/required warning and journal are valid before registration controls")
	var original_resources: Dictionary = _resources(arena)
	var original_pose: Dictionary = arena.actor.get_enemy_apparition().native_pose()
	var original_fingerprint: Dictionary = arena.scheduler.pure_collision_fingerprint(arena.world)
	for kind: String in ["different-hero", "different-hero-id", "nested-root"]:
		var domain: Node3D = outer if kind == "nested-root" else arena.world
		var peer: Dictionary = _registration_candidate(arena, domain, "test-only/" + kind)
		if peer.is_empty(): continue
		var hero: CinderPlayer = other_hero if kind == "different-hero" else arena.player
		# The alias control retains the exact same actual settled Hero and full
		# native domain; only its prospective stable saved identity differs.
		var heroes: Dictionary = {"alias-hero": hero} if kind == "different-hero-id" else {"hero": hero}
		_expect(not peer.actor.enable_authored_cycle_tracking(arena.scheduler, heroes, arena.floors, peer.context) and peer.actor.get_authored_cycle_terminal_receipt().is_empty() and arena.scheduler.authored_cycle_state(peer.actor).is_empty(), "individually valid " + kind + " cannot enter an existing actual Hero/root/floor aggregate or acquire journal authority")
		var current_cues: Array = []
		for cue: Node3D in arena.actor.get_cues(): current_cues.append(cue.state())
		_expect(Exact.stringify(_capture(arena, "binding-domain-after-" + kind)) == Exact.stringify(original) and current_cues == native_cues and arena.scheduler.replay_reservation_error(installed.id).is_empty() and _resources(arena) == original_resources and arena.actor.get_enemy_apparition().native_pose() == original_pose and EnemySequence.exact_equal(arena.scheduler.pure_collision_fingerprint(arena.world), original_fingerprint), kind + " refusal preserves exact original Player/source/history/current native warning/lease, local native resources/pose and pure world fingerprint")
		peer.actor.free()
	var compatible: Dictionary = _registration_candidate(arena, arena.world, "test-only/same-native-domain")
	if not compatible.is_empty():
		_expect(compatible.actor.enable_authored_cycle_tracking(arena.scheduler, {"hero": arena.player}, arena.floors, compatible.context), "positive second actual source with the same actual Hero/exact root/full native floor domain can register")
		var bindings: Dictionary = super._bindings(arena)
		bindings.owners[compatible.context.source_id] = compatible.actor
		var packet: Dictionary = arena.scheduler.snapshot_state(bindings)
		var current: Dictionary = arena.actor.snapshot_state(packet, bindings)
		var prospective: Dictionary = compatible.actor.snapshot_state(packet, bindings)
		_expect(not packet.is_empty() and packet.authored_source_cycles.sources.size() == 2 and not current.is_empty() and not prospective.is_empty() and prospective.status == "cycle_ready" and prospective.lifecycle.terminal_receipts.is_empty() and EnemySequence.exact_equal(current.lifecycle, original.playback.lifecycle) and EnemySequence.exact_equal(current.opportunities, original.playback.opportunities), "same-domain positive capture contains two distinct truthful sources without changing the first preview/event prefix or inventing second history")
	# Positive owner remains retained until the whole native parent retires.
	await _dispose(arena)


func _cue_descendants_hidden(cue: Node3D) -> bool:
	for node_name: String in ["RequiredSourceMarker", "RequiredFootprintOutline", "RequiredFootprintFill"]:
		var child: MeshInstance3D = cue.get_node_or_null(node_name)
		if child == null or child.is_visible_in_tree(): return false
	return true


func _nested_cue_cancel() -> void:
	var arena: Dictionary = await _arena()
	var retained: Dictionary = _resources(arena)
	var installed: Dictionary = _install(arena)
	if installed.is_empty(): await _dispose(arena); return
	var cue: Node3D = arena.actor.get_cues()[0]
	var hit_events: Array[String] = []
	var terminal_calls: Array[String] = []
	var cue_phases: Array[String] = []
	var cancelled: Array[bool] = [false]
	var following_observer: Array[bool] = [false]
	var hp: float = arena.player.hp
	arena.actor.event_dispatched.connect(func(_event: Dictionary, _receipt: Dictionary) -> void: hit_events.append("event"))
	arena.actor.playback_failed.connect(func(_reason: String) -> void: terminal_calls.append("failed"))
	arena.actor.state_changed.connect(func(value: Dictionary) -> void:
		if value.status == "cancelled": terminal_calls.append("cancelled-state")
	)
	cue.state_changed.connect(func(value: Dictionary) -> void:
		cue_phases.append(value.phase)
		if value.phase != "active" or cancelled[0]: return
		cancelled[0] = true
		_expect(arena.scheduler.cancel(installed.id, "test-only/nested-native-cue-cancel"), "genuine active Cue observer cancels the actual native lease synchronously")
		paused = true
		var receipt: Dictionary = arena.actor.get_authored_cycle_terminal_receipt()
		_expect(not receipt.is_empty() and receipt.outcome == "cancelled" and receipt.reason == "test-only/nested-native-cue-cancel" and arena.scheduler.authored_cycle_state(arena.actor).stage == "terminal" and receipt.opportunities[0].contact and not receipt.opportunities[0].damage_attempted, "nested cancellation seals exact original undelivered contact/history before remaining Cue observers, with no damage")
		_expect(_cue_descendants_hidden(cue) and arena.player.hp == hp and hit_events.is_empty() and not arena.actor.prepare_next_authored_cycle(SECOND_PLAYBACK, _next_program(arena, 2)), "notifying active Cue is immediately concealed; recursive next preparation cannot restore damage authority")
		var packet: Dictionary = arena.scheduler.snapshot_state(_bindings(arena))
		_expect(arena.actor.snapshot_state(packet, _bindings(arena)).is_empty(), "held notifying Cue cannot publish a falsely clear save before genuine deferred native clear")
	)
	cue.state_changed.connect(func(value: Dictionary) -> void:
		if value.phase == "active" and cancelled[0]:
			following_observer[0] = true
			_expect(_cue_descendants_hidden(cue) and not arena.actor.get_authored_cycle_terminal_receipt().is_empty() and hit_events.is_empty() and arena.player.hp == hp, "later real Cue observer sees sealed cancellation and concealed native meshes, never an active hazard")
	)
	var proof: Dictionary = await _lock(arena, installed)
	if proof.is_empty(): await _dispose(arena); return
	for _tick: int in range(180):
		if paused: break
		await _ticks(1)
	_expect(paused and cancelled[0] and following_observer[0], "bounded actual native event reaches both nested cancellation observers")
	await process_frame
	await process_frame
	_expect(cue.state().phase == "clear" and _cue_descendants_hidden(cue) and cue_phases.count("active") == 1 and not cue_phases.has("clear") and terminal_calls == ["failed", "cancelled-state"] and hit_events.is_empty() and arena.player.hp == hp and arena.actor.hp == 32.0 and _resources(arena) == retained, "post-notification deferred native clear is quiet, preserves original receipt/resources and cannot replay Cue/state/hit observers")
	var bundle: Dictionary = _capture(arena, "nested-native-cue-cancel")
	if bundle.is_empty(): await _dispose(arena); return
	var receipt: Dictionary = arena.actor.get_authored_cycle_terminal_receipt()
	var native: Dictionary = arena.actor.get_enemy_apparition().native_pose()
	var fresh: Dictionary = await _fresh(arena, bundle)
	if not fresh.is_empty():
		_expect(fresh.actor.get_enemy_apparition().native_pose() == native and fresh.actor.get_cues()[0].state().phase == "clear" and _cue_descendants_hidden(fresh.actor.get_cues()[0]) and EnemySequence.exact_equal(fresh.actor.get_authored_cycle_terminal_receipt(), receipt), "fresh paused nested-cancel restore retains actual harmless native presentation and original inert receipt without observers")
		await _retire(fresh)
	paused = false
	await _until(arena, float(receipt.exchange.cooldown_until_s) + 0.02)
	paused = true
	await process_frame
	var next: Dictionary = _next_program(arena, 2)
	_expect(arena.actor.prepare_next_authored_cycle(SECOND_PLAYBACK, next), "surviving same actual owner may prepare its next genuine generation after original nested-cancel cooldown")
	arena.context["generation"] = 2
	var ready: Dictionary = _capture(arena, "nested-cancel-next-ready")
	_expect(not ready.is_empty() and ready.playback.status == "cycle_ready" and ready.playback.lifecycle.terminal_receipts == [receipt] and terminal_calls == ["failed", "cancelled-state"] and hit_events.is_empty() and arena.player.hp == hp and arena.actor.hp == 32.0 and _resources(arena) == retained, "next readiness retains original cancelled history/HP/native objects and emits no replayed cancellation/event or damage")
	await _dispose(arena)


func _native_substitution_controls(arena: Dictionary, bundle: Dictionary) -> void:
	# Disposable paused fresh recipients provide real object/resource negatives;
	# these do not move or repair the admitted donor or fabricate earned history.
	for kind: String in ["mesh", "material", "floor"]:
		var fresh: Dictionary = await _arena(false, false)
		var before: String = Exact.stringify(fresh.player.snapshot_state())
		var mesh: MeshInstance3D = fresh.actor.get_authored_echo_renderer().get("visual")
		if kind == "mesh": mesh.mesh = mesh.mesh.duplicate()
		elif kind == "material": mesh.material_override = mesh.material_override.duplicate()
		else:
			var shape: BoxShape3D = fresh.floor.shape
			shape.size += Vector3(0.125, 0.0, 0.0)
		_expect(not _preflight_native(fresh, bundle, _staged_bindings(fresh, bundle)).is_empty() and Exact.stringify(fresh.player.snapshot_state()) == before and fresh.actor.hp == 32.0 and fresh.actor.source_hits == 0 and fresh.scheduler.get_clock() == 0.0, "actual fresh native " + kind + " substitution rejects before any physical/history restore")
		await _retire(fresh)
	_expect(is_instance_valid(arena.actor), "negative fresh recipients never replace or mutate the retained donor")
