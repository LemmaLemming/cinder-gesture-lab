extends "res://tests/scheduler_spore_source_smoke.gd"
## Supplemental immutable-reference checks only. Inherits the existing genuine
## native actor/Player/Scheduler/floor fixture, without rerunning its 208 checks.
## TEST ONLY native property mutations are paused, confirmed at their getters,
## and restored; no descriptor cache or controller internals are edited.
const NativeRoute = preload("res://scripts/combat/repulsion_route.gd")


func _run() -> void:
	var w: Dictionary = await _reference_world()
	if not w.ready:
		await _dispose(w)
		_finish()
		return
	paused = true
	var context: Dictionary = _context(w)
	var unit: Dictionary = context.sources["native-source"]
	_expect(not unit.is_empty() and w.protocol.binding_error().is_empty(), "genuine paused native unit starts with valid world/floor/body references")
	if unit.is_empty():
		await _dispose(w)
		_finish()
		return
	var events: Array = []
	w.scheduler.reservation_invalidated.connect(func(id: String, reason: String) -> void: events.append([id, reason]))
	w.source.hit_resolved.connect(func(result: Dictionary) -> void: events.append(result))
	w.scheduler.last_error = "reference-request-diagnostic"
	w.scheduler.last_snapshot_error = "reference-snapshot-diagnostic"
	w.protocol.last_error = "reference-protocol-diagnostic"

	var original_descriptor: Dictionary = w.protocol.binding_state()
	var before: Dictionary = _native_receipt(w, context)
	var alias: Dictionary = w.protocol.binding_state()
	alias.source_environment.world_signature.colliders.clear()
	alias.source_environment.floor_signature[0].shape.size[0] += 1.0
	alias.source_environment.body_signature.shape.radius += 0.1
	alias.source_environment.support_radius += 1.0
	alias.height += 1.0
	_expect(_same(original_descriptor, w.protocol.binding_state()), "public nested world/floor/body descriptor is a defensive copy")
	_expect(w.protocol.binding_error().is_empty() and w.protocol.unit_error(unit, _pair(context)).is_empty(), "mutating the public descriptor cannot alter live admission or saved-unit validation")
	_expect(_native_receipt(w, context) == before and events.is_empty() and w.protocol.last_error == "reference-protocol-diagnostic", "pure descriptor/validator queries change no native state, clocks, diagnostics or callbacks")
	_expect(_same(unit, w.protocol.current_unit(_pair(context))) and w.protocol.last_error.is_empty() and _native_receipt(w, context) == before, "public writer still captures the exact unit and clears only its documented capture diagnostic")

	# One native binary32 ULP, not a binary64 edit rounded away by Vector3.
	var scenery: BoxShape3D = w.scenery_collision.shape
	var old_scenery: Vector3 = scenery.size
	var changed_scenery := Vector3(_next_native_float(old_scenery.x), old_scenery.y, old_scenery.z)
	scenery.size = changed_scenery
	_expect(scenery.size == changed_scenery and scenery.size != old_scenery, "actual nonfloor scenery resource retains the one-bit dimension change")
	var measured: Dictionary = _fresh_environment(w, original_descriptor)
	_expect(not measured.has("error") and not _same(measured.world_signature, original_descriptor.source_environment.world_signature) and _same(measured.floor_signature, original_descriptor.source_environment.floor_signature), "real scenery mutation changes only the actual world fingerprint, leaving registered floor descriptors intact")
	_reject_unchanged(w, context, unit, events, "one-bit actual static world")
	scenery.size = old_scenery
	_expect(w.protocol.binding_error().is_empty() and _same(unit, w.protocol.current_unit(_pair(context))), "restoring only the injected native scenery dimension recovers the original exact unit")

	var floor_shape: BoxShape3D = w.floor.collision.shape
	var old_floor: Vector3 = floor_shape.size
	var changed_floor := Vector3(_next_native_float(old_floor.x), old_floor.y, old_floor.z)
	floor_shape.size = changed_floor
	_expect(floor_shape.size == changed_floor and floor_shape.size != old_floor, "actual retained floor Box resource retains its one-bit size change")
	measured = _fresh_environment(w, original_descriptor)
	_expect(not measured.has("error") and not _same(measured.floor_signature, original_descriptor.source_environment.floor_signature), "enlarged real floor still provides valid support but has a different exact native floor signature")
	_reject_unchanged(w, context, unit, events, "one-bit actual floor")
	floor_shape.size = old_floor
	_expect(w.protocol.binding_error().is_empty() and _same(unit, w.protocol.current_unit(_pair(context))), "restoring only the injected floor size recovers exact supported state")

	var collision: CollisionShape3D = w.source.get_node("BodyCollision")
	var body_shape: CapsuleShape3D = collision.shape
	var old_margin: float = body_shape.margin
	var changed_margin: float = _next_native_float(old_margin)
	body_shape.margin = changed_margin
	_expect(body_shape.margin == changed_margin and body_shape.margin != old_margin, "actual retained Capsule resource retains its one-bit solver margin change")
	measured = _fresh_environment(w, original_descriptor)
	_expect(not measured.has("error") and _same(measured.world_signature, original_descriptor.source_environment.world_signature) and _same(measured.floor_signature, original_descriptor.source_environment.floor_signature), "native body-property mutation leaves actual static world/floor signatures unchanged")
	_reject_unchanged(w, context, unit, events, "one-bit actual body property")
	body_shape.margin = old_margin
	_expect(w.protocol.binding_error().is_empty() and w.protocol.unit_error(unit, _pair(context)).is_empty() and _same(unit, w.protocol.current_unit(_pair(context))), "restoring only the actual body margin recovers original full native unit")
	_expect(_same(original_descriptor, w.protocol.binding_state()) and _native_receipt(w, context) == before and events.is_empty(), "all test controls return the complete original reference/native unit with unchanged clocks/history/diagnostics")
	await _dispose(w)
	_finish()


func _reference_world() -> Dictionary:
	var w: Dictionary = await _world(false)
	if not w.ready: return w
	paused = true
	# Add real scenery before configuring this supplemental protocol. The base
	# unbound protocol is retired; its original scene helpers remain unchanged.
	var wall := StaticBody3D.new()
	wall.name = "ReferenceScenery"
	wall.position = Vector3(8.0, 1.0, 8.0)
	wall.collision_layer = 1
	wall.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "NativeBox"
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 2.0, 0.8)
	collision.shape = box
	wall.add_child(collision)
	w.root.add_child(wall)
	var protocol = Protocol.new()
	w.ready = protocol.configure(w.source, w.scheduler, w.hero, "native-source", "controller", "hero", {"world_root": w.root, "floors": {"ground": w.floor}})
	_expect(w.ready, "fresh actual protocol binds the complete native world including genuine nonfloor scenery: " + protocol.last_error)
	w.protocol = protocol
	w.bindings.source_protocols["native-source"] = protocol
	w["scenery_collision"] = collision
	if w.ready:
		w.ready = w.consumer.bind_environment(w.bindings)
		_expect(w.ready, "actual repulsion consumer admits the genuine source/controller/Player/world unit: " + w.consumer.last_error)
	return w


func _fresh_environment(w: Dictionary, descriptor: Dictionary) -> Dictionary:
	return NativeRoute.static_environment_state(w.root, {"ground": w.floor}, descriptor.source_environment, Vector3(0.0, w.source.global_position.y, 0.0))


func _reject_unchanged(w: Dictionary, context: Dictionary, unit: Dictionary, events: Array, label: String) -> void:
	var before: Dictionary = _native_receipt(w, context)
	var diagnostic: String = w.protocol.last_error
	_expect(not w.protocol.binding_error().is_empty(), label + " fails the live native guard")
	_expect(not w.protocol.unit_error(unit, _pair(context)).is_empty() and w.protocol.last_error == diagnostic, label + " pure paired validation rejects without changing diagnostics")
	_expect(w.protocol.current_unit(_pair(context)).is_empty() and not w.protocol.last_error.is_empty(), label + " public writer rejects with its documented diagnostic instead of a stale-reference capture")
	_expect(_native_receipt(w, context) == before and events.is_empty(), label + " rejection is atomic: no clock, controller, source/Player resources, geometry or Scheduler diagnostics mutation")


func _native_receipt(w: Dictionary, context: Dictionary) -> Dictionary:
	var collision: CollisionShape3D = w.source.get_node("BodyCollision")
	var body: CapsuleShape3D = collision.shape
	return {"paused": paused, "clock": w.scheduler.get_clock(), "control": w.scheduler.source_control_state(w.source), "source": Exact.stringify(w.source.spore_snapshot_state(context.controllers.controller, context.players.hero)), "player": Exact.stringify(w.hero.snapshot_state()), "native": [w.source.global_transform, w.source.velocity, w.hero.global_transform, w.hero.velocity, w.source.hp, w.source.dead, collision.global_transform, body.get_instance_id(), body.radius, body.height, body.margin, w.floor.collision.global_transform, w.floor.collision.shape.get_instance_id(), w.floor.collision.shape.size, w.scenery_collision.global_transform, w.scenery_collision.shape.get_instance_id(), w.scenery_collision.shape.size], "descriptor": Exact.stringify(w.protocol.binding_state()), "diagnostics": [w.scheduler.last_error, w.scheduler.last_snapshot_error]}


func _next_native_float(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(4)
	bytes.encode_float(0, value)
	bytes.encode_u32(0, bytes.decode_u32(0) + 1)
	return bytes.decode_float(0)


func _finish() -> void:
	print("Scheduler spore reference supplement: %d checks, %d failures; real native properties/public descriptor only" % [checks, failures])
	quit(0 if failures == 0 else 1)
