extends "res://tests/authored_echo_lifecycle_smoke.gd"
## Corrected scope: genuine native lifecycle registration, no fabricated
## journal/HP/clock/body after admission. Terminal is an explicitly cancelled
## actual authored preview; cooldown expiry uses real native physics ticks.
## This does not repeat or claim the ordinary two-cycle combat route.
const GuardActor = preload("res://tests/fixtures/managed_ordinary_actor.gd")
const OrdinaryGeometry = preload("res://scripts/combat/threat_geometry.gd")
const OrdinaryDifficulty = preload("res://scripts/combat/difficulty.gd")
const GuardMotion = preload("res://scripts/combat/lunge_motion.gd")

func _run() -> void:
	root.size = Vector2i(540, 1170)
	print("Managed ordinary guard CORRECTED draft: real first-ready/running/cancelled/next-ready, retained pre-registration previews, actual CharacterBody with genuine Playback Script, native getter reentry. Unexecuted until queued by root; no campaign claim.")
	await _ordinary_control(false)
	await _ordinary_control(true)
	await _ordinary_tracking_control()
	await _state_matrix(false)
	await _state_matrix(true)
	await _handshake_reentry(false)
	await _handshake_reentry(true)
	print("Managed ordinary corrected guard: %d checks, %d failures; isolated actual native admission/custody controls" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _native_guard_arena(body_source: bool) -> Dictionary:
	# Released helper constructs actual native floor/Scheduler/Player/world and
	# an untracked initial source when settle=false. Replace ONLY that fresh,
	# unadmitted fixture source, before any history/authority exists. Never clone
	# a managed owner, mutate a native earned journal or change its Script later.
	var arena: Dictionary = await _arena(false, false)
	var old: Node3D = arena.actor
	arena.world.remove_child(old)
	old.free()
	var source: Node3D
	if body_source:
		var body := CharacterBody3D.new()
		body.collision_layer = 2
		body.collision_mask = 1
		body.set_script(GuardActor)
		var collision := CollisionShape3D.new()
		collision.name = "BodyCollision"
		collision.position = Vector3(0, 0.73, 0)
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.25
		capsule.height = 1.45
		collision.shape = capsule
		body.add_child(collision)
		source = body
	else:
		source = GuardActor.new()
	source.name = "ActualGuardC52Body" if body_source else "ActualGuardC52Node"
	arena.world.add_child(source)
	arena.actor = source
	# CharacterBody dynamic layer2 does not modify the static floor fingerprint.
	arena.context["world_collision_fingerprint"] = arena.scheduler.pure_collision_fingerprint(arena.world)
	var prepared: Dictionary = {"world_revision": 1, "collision_fingerprint": arena.context.world_collision_fingerprint, "floor_signature": arena.context.world_floor_signature}
	_expect(source.call("initialize_source", SOURCE_ID, EPOCH, 1, _definition(), "standard", prepared) and source.call("attach_source_scheduler", arena.scheduler) and source.call("retain_fixture_environment", arena.world, arena.floors) and source.call("configure_authored", FIRST_PLAYBACK, source.call("source_program"), EPOCH, 1), "fresh actual %s source retains own Script/native renderer/raw recipe before any registration" % ("CharacterBody3D" if body_source else "Node3D"))
	paused = false
	await _ticks(8)
	paused = true
	await process_frame
	_expect(arena.player.get_threat_response_state().stable and arena.player.is_on_floor() and String(source.call("source_native_error")).is_empty() and arena.scheduler.authored_cycle_state(source).is_empty(), "actual Hero settles on real floor while source is still fresh untracked with genuine native renderer")
	if body_source:
		var description: Dictionary = GuardMotion.source_description(source as CharacterBody3D)
		_expect(not description.has("error") and (source as CharacterBody3D).velocity == Vector3.ZERO and description.radius == ((source.get_node("BodyCollision") as CollisionShape3D).shape as CapsuleShape3D).radius, "real Script-attached CharacterBody has one actual registered scenery-only capsule and zero native velocity")
	return arena

func _ordinary_response(arena: Dictionary) -> Dictionary:
	var result: Dictionary = _response(arena)
	result["world_root"] = arena.world
	return result

func _ordinary_role(active_s: float = 0.16) -> Dictionary:
	return OrdinaryDifficulty.new().resolve_role({"raw_damage": 4.0, "windup_s": 0.7, "lock_s": 0.2, "active_s": active_s, "recovery_s": 2.0, "attack_interval_s": 2.0, "max_hp": 32.0, "move_speed": 0.0}, "standard", {"windup_s": 0.7, "lock_s": 0.2, "recovery_s": 2.0})

func _ordinary_threat(arena: Dictionary) -> Dictionary:
	return {"role": _ordinary_role(), "geometry": OrdinaryGeometry.circle(arena.actor.global_position, 0.3), "source_stationary": true, "opening_stationary": true, "opening_position": arena.actor.global_position, "cooldown_remaining_s": 0.0}

func _tracking_threat(arena: Dictionary) -> Dictionary:
	var result: Dictionary = _ordinary_threat(arena)
	result["geometry"] = OrdinaryGeometry.lane(arena.actor.global_position, arena.actor.global_position + Vector3.FORWARD * 1.5, 0.2)
	return result

func _lunge_threat() -> Dictionary:
	return {"role": _ordinary_role(0.5), "source_stationary": false, "opening_stationary": true, "cooldown_remaining_s": 0.0, "lunge": {"body_collision_path": "BodyCollision", "direction": Vector3.LEFT, "speed": 8.0, "distance": 1.0, "damage_radius": 0.31}}

func _ordinary_control(body_source: bool) -> void:
	var arena: Dictionary = await _native_guard_arena(body_source)
	paused = false
	var response: Dictionary = _ordinary_response(arena)
	var preview: Dictionary
	var admitted: Dictionary
	if body_source:
		preview = arena.scheduler.preview_lunge(arena.actor as CharacterBody3D, _lunge_threat(), response)
		_expect(preview.get("accepted", false), "untracked actual CharacterBody ordinary lunge proof remains available: " + str(preview.get("reason", "")))
		admitted = arena.scheduler.request_lunge(arena.actor as CharacterBody3D, _lunge_threat(), response, preview)
	else:
		preview = arena.scheduler.preview_stationary(arena.actor, _ordinary_threat(arena), response)
		_expect(preview.get("accepted", false), "untracked ordinary stationary proof remains available: " + str(preview.get("reason", "")))
		admitted = arena.scheduler.request_attack(arena.actor, _ordinary_threat(arena), response, preview)
	_expect(admitted.get("accepted", false) and admitted.get("reservation_id", "") == "threat-1" and arena.scheduler.authored_cycle_state(arena.actor).is_empty(), "unmanaged ordinary control admits exactly its real first lease without an authored journal: " + str(admitted.get("reason", "")))
	_expect(not arena.actor.enable_authored_cycle_tracking(arena.scheduler, {"hero": arena.player}, arena.floors, arena.context) and arena.scheduler.authored_cycle_state(arena.actor).is_empty(), "existing ordinary lease/cooldown cannot be adopted into a managed journal")
	await _dispose(arena)

func _ordinary_tracking_control() -> void:
	var arena: Dictionary = await _native_guard_arena(false)
	paused = false
	var threat: Dictionary = _tracking_threat(arena)
	var admitted: Dictionary = arena.scheduler.request_tracking(arena.actor, threat, _ordinary_response(arena))
	_expect(admitted.get("accepted", false) and not admitted.get("armed", true), "unmanaged ordinary tracking control keeps a genuine unarmed lease")
	if admitted.get("accepted", false):
		var before: Dictionary = arena.scheduler.source_control_state(arena.actor)
		_expect(not arena.actor.enable_authored_cycle_tracking(arena.scheduler, {"hero": arena.player}, arena.floors, arena.context) and arena.scheduler.authored_cycle_state(arena.actor).is_empty() and arena.scheduler.source_control_state(arena.actor) == before, "actual tracking lease refuses managed registration without altering its original ordinary commitment")
		var updated: Dictionary = arena.scheduler.update_tracking(admitted.reservation_id, threat.geometry)
		_expect(updated.get("accepted", false), "ordinary public tracking update remains available after rejected managed opt-in")
		await _until(arena, float(admitted.reservation.lock_from_s))
		var committed: Dictionary = arena.scheduler.commit_tracking(admitted.reservation_id, threat.geometry, _ordinary_response(arena))
		_expect(committed.get("accepted", false) and committed.get("armed", false), "ordinary due tracking commit remains supported; no forged managed tracking lease")
	await _dispose(arena)

func _state_matrix(body_source: bool) -> void:
	var arena: Dictionary = await _native_guard_arena(body_source)
	paused = false
	var response: Dictionary = _ordinary_response(arena)
	var retained: Dictionary = arena.scheduler.preview_stationary(arena.actor, _ordinary_threat(arena), response)
	var retained_lunge: Dictionary = arena.scheduler.preview_lunge(arena.actor as CharacterBody3D, _lunge_threat(), response) if body_source else {}
	_expect(retained.get("accepted", false) and (not body_source or retained_lunge.get("accepted", false)), "actual valid preview is retained before registration, without obtaining an ordinary lease")
	_expect(arena.actor.enable_authored_cycle_tracking(arena.scheduler, {"hero": arena.player}, arena.floors, arena.context), "same real owner registers its first managed ready cycle: " + arena.actor.last_error)
	var events: Array[String] = []
	arena.scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: events.append("invalidation"))
	arena.actor.state_changed.connect(func(_state: Dictionary) -> void: events.append("state"))
	arena.actor.event_dispatched.connect(func(_event: Dictionary, _receipt: Dictionary) -> void: events.append("event"))
	arena.actor.source_hit_resolved.connect(func(_hit: Dictionary) -> void: events.append("hit"))
	arena.actor.source_defeated.connect(func(_hit: Dictionary) -> void: events.append("death"))
	arena.player.world_action_executed.connect(func(_record: Dictionary) -> void: events.append("player-action"))
	await _guard_stage(arena, "first-ready", retained, retained_lunge, events)
	var installed: Dictionary = _install(arena)
	if installed.is_empty(): await _dispose(arena); return
	await _guard_stage(arena, "genuinely admitted running", retained, retained_lunge, events)
	paused = false
	arena.scheduler.cancel(installed.id, "test-only/managed-ordinary-terminal")
	paused = true
	await process_frame
	_expect(arena.actor.state().status == "cancelled" and arena.scheduler.authored_cycle_state(arena.actor).stage == "terminal" and arena.actor.hp == 32.0 and not arena.actor.get_authored_cycle_terminal_receipt().is_empty(), "real public cancellation seals the original unarmed lease without HP/damage or invented history")
	await _guard_stage(arena, "earned-terminal-before-expiry", retained, retained_lunge, events)
	var receipt: Dictionary = arena.actor.get_authored_cycle_terminal_receipt()
	paused = false
	await _until(arena, maxf(float(receipt.exchange.recovery_until_s), float(receipt.exchange.cooldown_until_s)) + 0.02)
	paused = true
	await process_frame
	_expect(arena.scheduler.source_control_state(arena.actor).cooldown == null, "real native physics earns original cooldown/tombstone expiry before preparing next generation")
	await _guard_stage(arena, "earned-terminal-after-expiry", retained, retained_lunge, events)
	var next: Dictionary = _next_program(arena, 2)
	_expect(arena.actor.prepare_next_authored_cycle(SECOND_PLAYBACK, next), "same surviving actual owner prepares genuine generation2 after original cooldown: " + arena.actor.last_error)
	arena.context["generation"] = 2
	_expect(arena.actor.state().status == "cycle_ready" and arena.actor.get_authored_cycle_generation() == 2 and arena.scheduler.authored_cycle_state(arena.actor).terminal_receipts == [receipt], "next ready retains the actual immutable cancelled predecessor and the same native HP32 owner")
	await _guard_stage(arena, "next-ready", retained, retained_lunge, events)
	await _dispose(arena)

func _guard_stage(arena: Dictionary, label: String, retained: Dictionary, retained_lunge: Dictionary, events: Array[String]) -> void:
	paused = false
	var before: Dictionary = _guard_unit(arena)
	var emitted: Array[String] = events.duplicate()
	_expect(not before.scheduler.is_empty() and not before.playback.is_empty(), label + " begins with a genuine valid paired managed snapshot")
	var response: Dictionary = _ordinary_response(arena)
	var threat: Dictionary = _ordinary_threat(arena)
	_assert_refusal(arena, label + "/preview_stationary", func() -> Dictionary: return arena.scheduler.preview_stationary(arena.actor, threat, response), before, events, emitted, true)
	_assert_refusal(arena, label + "/request_attack", func() -> Dictionary: return arena.scheduler.request_attack(arena.actor, threat, response), before, events, emitted)
	_assert_refusal(arena, label + "/request_attack-retained-preview", func() -> Dictionary: return arena.scheduler.request_attack(arena.actor, threat, response, retained), before, events, emitted)
	_assert_refusal(arena, label + "/request_tracking", func() -> Dictionary: return arena.scheduler.request_tracking(arena.actor, _tracking_threat(arena), response), before, events, emitted)
	if arena.actor is CharacterBody3D:
		var body: CharacterBody3D = arena.actor as CharacterBody3D
		_assert_refusal(arena, label + "/preview_lunge", func() -> Dictionary: return arena.scheduler.preview_lunge(body, _lunge_threat(), response), before, events, emitted, true)
		_assert_refusal(arena, label + "/request_lunge", func() -> Dictionary: return arena.scheduler.request_lunge(body, _lunge_threat(), response), before, events, emitted)
		_assert_refusal(arena, label + "/request_lunge-retained-preview", func() -> Dictionary: return arena.scheduler.request_lunge(body, _lunge_threat(), response, retained_lunge), before, events, emitted)
	var encoded: String = Exact.stringify({"label": label, "body": arena.actor is CharacterBody3D, "before": before, "after": _guard_unit(arena), "callbacks": events.duplicate()})
	_expect(not encoded.is_empty(), label + " exact complete stage diagnostic is nonempty")
	print("CORRECTED_MANAGED_STAGE " + encoded)

func _assert_refusal(arena: Dictionary, label: String, operation: Callable, before: Dictionary, events: Array[String], emitted: Array[String], pure: bool = false) -> void:
	var diagnostic: String = arena.scheduler.last_error
	var snapshot_diagnostic: String = arena.scheduler.last_snapshot_error
	var answer: Dictionary = operation.call()
	_expect(not answer.get("accepted", false) and String(answer.get("reason", "")).contains("Managed authored"), label + " rejects by managed ownership before native proof/prune/preview correspondence: " + str(answer.get("reason", "")))
	if pure: _expect(arena.scheduler.last_error == diagnostic and arena.scheduler.last_snapshot_error == snapshot_diagnostic, label + " is diagnostic-pure")
	var after: Dictionary = _guard_unit(arena)
	_expect(EnemySequence.exact_equal(before, after) and events == emitted, label + " retains exact clock/serial/tables/history/HP/native objects/renderer/prefix and emits no callbacks")

func _handshake_reentry(body_source: bool) -> void:
	var arena: Dictionary = await _native_guard_arena(body_source)
	paused = false
	var response: Dictionary = _ordinary_response(arena)
	var preview: Dictionary = arena.scheduler.preview_stationary(arena.actor, _ordinary_threat(arena), response)
	_expect(preview.get("accepted", false), "reentry control starts with a genuine pre-registration preview")
	arena.actor.test_probe_response = response
	arena.actor.test_probe_threat = _ordinary_threat(arena)
	arena.actor.test_probe_preview = preview
	arena.actor.test_probe_lunge = _lunge_threat()
	arena.actor.test_probe_lunge_preview = arena.scheduler.preview_lunge(arena.actor as CharacterBody3D, _lunge_threat(), response) if body_source else {}
	if body_source: _expect(arena.actor.test_probe_lunge_preview.get("accepted", false), "reentry control retains a genuine native lunge preview before registration")
	arena.actor.test_probe_once = true
	var clock: float = arena.scheduler.get_clock()
	var resources: Dictionary = _native_diagnostic(_resources(arena))
	var hp: float = arena.player.hp
	_expect(arena.actor.enable_authored_cycle_tracking(arena.scheduler, {"hero": arena.player}, arena.floors, arena.context), "genuine native begin-tracking getter handshake completes after refusing nested ordinary calls: " + arena.actor.last_error)
	var trace: Array = arena.actor.test_probe_trace
	_expect(trace.size() == (9 if body_source else 6), "actual native getter invokes every applicable public ordinary entry during real Scheduler transaction")
	for entry: Dictionary in trace:
		_expect(not entry.accepted and (String(entry.reason).contains("transaction") or String(entry.reason).contains("barrier")) and entry.clock_unchanged, "actual handshake reentry " + entry.method + " rejects at transaction gate without clock/allocation")
		if entry.pure: _expect(entry.diagnostic_unchanged, "actual nested pure " + entry.method + " preserves current diagnostics")
	var unit: Dictionary = _guard_unit(arena)
	_expect(not unit.scheduler.is_empty() and not unit.playback.is_empty() and unit.scheduler.serial == 0 and unit.scheduler.reservations.is_empty() and unit.scheduler.cooldowns.is_empty() and unit.journal.stage == "cycle_ready" and unit.journal.terminal_receipts.is_empty() and arena.scheduler.get_clock() == clock and arena.player.hp == hp and EnemySequence.exact_equal(_native_diagnostic(_resources(arena)), resources), "only the genuine successful ready registration commits; nested ordinary calls create no lease/cooldown/history/resource/HP change")
	print("NATIVE_MANAGED_GETTER_REENTRY " + Exact.stringify(trace))
	await _dispose(arena)

func _native_diagnostic(value: Variant) -> Variant:
	# DIAGNOSTIC ONLY, from bounded genuine native fixture readers. Native
	# Resource instance IDs are signed int64 and may exceed closed wire's safe
	# integer budget. Preserve their exact type/value with a decimal string tag;
	# never alter production snapshots, budgets or native resource identities.
	if value is int and (value < -9007199254740991 or value > 9007199254740991): return {"native_int64_decimal": str(value)}
	if value is Vector3: return [value.x, value.y, value.z]
	if value is Vector2: return [value.x, value.y]
	if value is Rect2: return {"native_rect2": {"position": _native_diagnostic(value.position), "size": _native_diagnostic(value.size)}}
	if value is Rect2i: return {"native_rect2i": {"position": [value.position.x, value.position.y], "size": [value.size.x, value.size.y]}}
	if value is Transform3D: return {"native_transform3d": {"origin": _native_diagnostic(value.origin), "x": _native_diagnostic(value.basis.x), "y": _native_diagnostic(value.basis.y), "z": _native_diagnostic(value.basis.z)}}
	if value is Basis: return {"native_basis": {"x": _native_diagnostic(value.x), "y": _native_diagnostic(value.y), "z": _native_diagnostic(value.z)}}
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _native_diagnostic(value[key])
		return result
	if value is Array:
		var result: Array = []
		for entry: Variant in value: result.append(_native_diagnostic(entry))
		return result
	return value

func _guard_unit(arena: Dictionary) -> Dictionary:
	var prior: bool = paused
	paused = true
	var bindings: Dictionary = _bindings(arena)
	var scheduler: Dictionary = arena.scheduler.snapshot_state(bindings)
	var scheduler_error: String = arena.scheduler.last_snapshot_error
	var playback: Dictionary = arena.actor.snapshot_state(scheduler, bindings) if not scheduler.is_empty() else {}
	var unit: Dictionary = _native_diagnostic({"clock_s": arena.scheduler.get_clock(), "player": arena.player.snapshot_state(), "scheduler": scheduler, "scheduler_snapshot_error": scheduler_error, "playback": playback, "journal": arena.scheduler.authored_cycle_state(arena.actor), "control": arena.scheduler.source_control_state(arena.actor), "resources": _resources(arena), "renderer": arena.actor.get_enemy_apparition().native_pose(), "hp": arena.actor.hp, "dead": arena.actor.dead})
	if arena.actor is CharacterBody3D:
		var body: CharacterBody3D = arena.actor as CharacterBody3D
		var collision: CollisionShape3D = body.get_node("BodyCollision") as CollisionShape3D
		var shape: CapsuleShape3D = collision.shape as CapsuleShape3D
		unit["actual_body"] = _native_diagnostic({"body_id": body.get_instance_id(), "collision_id": collision.get_instance_id(), "shape_id": shape.get_instance_id(), "position": body.global_position, "basis": body.global_basis, "velocity": body.velocity, "layer": body.collision_layer, "mask": body.collision_mask, "disabled": collision.disabled, "radius": shape.radius, "height": shape.height, "margin": shape.margin, "solver_bias": shape.custom_solver_bias, "collision_transform": collision.transform, "shape_owners": body.get_shape_owners().size()})
	paused = prior
	var error: String = Value.value_error(unit)
	_expect(error.is_empty() and not Exact.stringify(unit).is_empty(), "complete observation encodes canonical snapshots plus lossless typed native resource/body diagnostics: " + error)
	return unit
