extends "res://tests/lane_mechanism_smoke.gd"
## Focused optional parent-guard checks; run through the canonical dev queue.
## Reuses genuine native shared World/Player/Scheduler and old fixture helpers;
## no act parent, whole level, save provenance, portrait or timing claim.

class ParentGuard:
	extends Node3D
	var mechanism: CinderLaneMechanism
	var required: MeshInstance3D
	var mode: String = "normal"
	var acted: bool = false
	var calls: int = 0
	var active_calls: int = 0
	var recursive_refusals: Array[bool] = []
	var context: Dictionary = {}
	var bindings: Dictionary = {}
	var foreign: Node3D
	var foreign_id: String = ""
	var scheduler: CinderThreatScheduler
	func _ready() -> void:
		required = MeshInstance3D.new()
		required.name = "ActualRequiredSiblingArt"
		var shape := BoxMesh.new()
		shape.size = Vector3(0.10, 0.10, 0.10)
		required.mesh = shape
		add_child(required)
	func ready_now() -> bool:
		return is_inside_tree() and not is_queued_for_deletion() and is_instance_valid(required) and required.is_inside_tree() and not required.is_queued_for_deletion() and required.is_visible_in_tree() and required.mesh != null and is_instance_valid(mechanism) and required.get_world_3d() == mechanism.get_world_3d()
	func guard(id: String, proposed: Dictionary) -> Variant:
		calls += 1
		var before: bool = id == "loading-arm" and ready_now()
		# State is defensive native data, never a caller accepted proof token.
		proposed.geometry.radius = 999.0
		proposed.resolved_role.damage = 999.0
		if proposed.phase == "active":
			active_calls += 1
			if not acted:
				acted = true
				match mode:
					"wrong-type": return 1
					"hide-cue": mechanism.get_cue().hide()
					"pause": get_tree().paused = true
					"cancel": mechanism.cancel("parent_precise_cancel")
					"recursive":
						recursive_refusals.append(not mechanism.start("hero", context).get("accepted", false))
						recursive_refusals.append(not mechanism.preview_start("hero", context).get("accepted", false))
						recursive_refusals.append(not mechanism.set_presentation_guard(guard))
						recursive_refusals.append(mechanism.snapshot_state(bindings).is_empty())
					"foreign-move": foreign.position.x += 0.25
					"foreign-cancel": scheduler.cancel(foreign_id, "parent_guard_foreign_cancel")
		return before # Foreign listeners can revoke this earlier result.
	func wrong_arity(_id: String) -> bool:
		return true


func _run() -> void:
	create_timer(240.0, true).timeout.connect(func() -> void:
		push_error("Lane parent guard watchdog expired")
		quit(1)
	)
	await _guard_binding_and_normal()
	for mutation: String in ["late-hide", "freed-provider", "wrong-type", "hide-cue", "cancel", "recursive"]:
		await _guard_active_boundary(mutation)
	for mutation: String in ["foreign-move", "foreign-cancel"]:
		await _guard_foreign_observer(mutation)
	await _guard_paused_fresh_restore()
	print("Lane parent presentation guard smoke: %d checks, %d failures; focused native sibling/callback/pending/quiet recipient scope only" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _parent(arena: Dictionary, mode: String = "normal") -> ParentGuard:
	var parent := ParentGuard.new()
	parent.name = "ActualAuthoredSiblingParent"
	parent.mechanism = arena.mechanism
	parent.context = World.context(arena, "parent-guard")
	parent.bindings = World.bindings(arena)
	parent.scheduler = arena.scheduler
	parent.mode = mode
	arena.root.add_child(parent)
	return parent


func _guard_binding_and_normal() -> void:
	var arena: Dictionary = World.create(self)
	await _ticks(5)
	var mechanism: CinderLaneMechanism = arena.mechanism
	var parent: ParentGuard = _parent(arena)
	_expect(not mechanism.set_presentation_guard(Callable()) and not mechanism.set_presentation_guard(parent.wrong_arity) and parent.calls == 0, "invalid/wrong-arity guard refuses before any callback or binding")
	_expect(mechanism.set_presentation_guard(parent.guard) and not mechanism.set_presentation_guard(parent.guard), "fresh actual parent guard binds once and cannot be replaced")
	arena.scheduler.begin_encounter("standard", "parent-guard")
	var hits: Array[String] = []
	mechanism.hit_resolved.connect(func(id: String, _cycle: int, _result: Dictionary) -> void: hits.append(id))
	var answer: Dictionary = mechanism.start("hero", parent.context)
	_expect(answer.get("accepted", false), "guarded native source receives an actual ordinary empty-ammo proof")
	if answer.get("accepted", false):
		_expect(await _until_phase(mechanism, "active") and hits == ["hero"] and arena.hero.hp == arena.hero.max_hp - arena.hero.equipment.damage_received(4.0), "valid parent guard permits one real armor-respecting opportunity")
		_expect(mechanism.state().geometry.radius == 0.30 and mechanism.state().resolved_role.damage == 4.0 and parent.active_calls > 0, "provider state mutation cannot change committed geometry/raw damage")
	await _dispose(arena)


func _guard_active_boundary(mutation: String) -> void:
	var arena: Dictionary = World.create(self)
	await _ticks(5)
	var mechanism: CinderLaneMechanism = arena.mechanism
	var parent: ParentGuard = _parent(arena, mutation)
	var initial_checks: Array[bool] = []
	if mutation == "late-hide":
		mechanism.state_changed.connect(func(value: Dictionary) -> void:
			if value.phase == "active": initial_checks.append(parent.ready_now())
		)
		mechanism.state_changed.connect(func(value: Dictionary) -> void:
			if value.phase == "active": parent.required.hide()
		)
	elif mutation == "freed-provider":
		mechanism.state_changed.connect(func(value: Dictionary) -> void:
			if value.phase == "active": parent.free()
		)
	_expect(mechanism.set_presentation_guard(parent.guard), mutation + " binds the genuine required sibling guard before first cycle")
	arena.scheduler.begin_encounter("standard", "parent-guard")
	var hits: Array[String] = []
	mechanism.hit_resolved.connect(func(id: String, _cycle: int, _result: Dictionary) -> void: hits.append(id))
	var answer: Dictionary = mechanism.start("hero", World.context(arena, "parent-guard"))
	_expect(answer.get("accepted", false), mutation + " admits native unchanged warning/lock deadlines")
	if answer.get("accepted", false):
		await _until_clock(arena.scheduler, float(answer.reservation.active_from_s) + 0.04)
		if mutation == "recursive":
			_expect(parent.recursive_refusals == [true, true, true, true] and hits == ["hero"] and mechanism.state().hit_ids == ["hero"], "guard recursion refuses admissions/rebinding/capture but original opportunity occurs once")
		else:
			_expect(hits.is_empty() and arena.hero.hp == arena.hero.max_hp and mechanism.state().hit_ids.is_empty() and mechanism.state().status == "cancelled" and mechanism.get_cue().state().phase == "clear", mutation + " closes after actual synchronous publication before opportunity or HP damage")
			if mutation == "late-hide": _expect(initial_checks == [true], "later live sibling hide occurs after the earlier same-publication parent visibility check")
			if mutation == "cancel": _expect(mechanism.state().last_cancel_reason == "parent_precise_cancel", "synchronous owner cancellation keeps its precise reason")
			if mutation in ["late-hide", "freed-provider", "wrong-type"]: _expect(mechanism.state().last_cancel_reason == "required_parent_presentation_unavailable", mutation + " invalid/false/wrong-type guard fails closed")
			paused = true
			await process_frame
			var saved: Dictionary = arena.scheduler.snapshot_state(World.bindings(arena))
			_expect(not saved.is_empty() and saved.cooldowns.size() == 1 and saved.cooldowns[0].ready_s == answer.reservation.cooldown_until_s and saved.reservations.is_empty(), mutation + " cancellation retains original source cooldown")
	await _dispose(arena)


func _guard_foreign_observer(mutation: String) -> void:
	var arena: Dictionary = World.create(self)
	await _ticks(5)
	var mechanism: CinderLaneMechanism = arena.mechanism
	var scheduler: CinderThreatScheduler = arena.scheduler
	var parent: ParentGuard = _parent(arena, mutation)
	_expect(mechanism.set_presentation_guard(parent.guard), mutation + " binds actual parent before native union admission")
	scheduler.begin_encounter("standard", "parent-guard")
	var main: Dictionary = mechanism.start("hero", parent.context)
	_expect(main.get("accepted", false), mutation + " main cycle receives genuine Scheduler admission")
	if not main.get("accepted", false):
		await _dispose(arena)
		return
	var foreign := Node3D.new()
	foreign.name = "ActualForeignStationarySource"
	foreign.position = Vector3(-4, 0, 0)
	arena.root.add_child(foreign)
	parent.foreign = foreign
	var raw: Dictionary = Mechanism.DEFAULT_RAW_ROLE.duplicate(true)
	raw.windup_s = 2.7
	var role: Dictionary = Difficulty.new().resolve_role(raw, "standard", Mechanism.DEFAULT_TIMING_FLOORS)
	var response: Dictionary = arena.hero.get_threat_response_state()
	for key: String in parent.context:
		if key != "encounter_id": response[key] = parent.context[key]
	var threat: Dictionary = {"role": role, "geometry": Geometry.lane(foreign.position, foreign.position + Vector3.RIGHT * 0.5, 0.3), "source_stationary": true, "opening_stationary": true, "opening_position": Vector3.ZERO, "cooldown_remaining_s": 0.0}
	var other: Dictionary = scheduler.request_attack(foreign, threat, response)
	_expect(other.get("accepted", false), mutation + " foreign source receives real staggered combined-union proof: " + String(other.get("reason", "")))
	if not other.get("accepted", false):
		await _dispose(arena)
		return
	parent.foreign_id = other.reservation_id
	var notifications: Array[String] = []
	scheduler.reservation_invalidated.connect(func(id: String, reason: String) -> void:
		if id == parent.foreign_id:
			notifications.append(reason)
			parent.required.hide()
	)
	var hits: Array[String] = []
	mechanism.hit_resolved.connect(func(id: String, _cycle: int, _result: Dictionary) -> void: hits.append(id))
	await _until_clock(scheduler, float(main.reservation.active_from_s) + 0.04)
	_expect(notifications == ["stationary_source_moved" if mutation == "foreign-move" else "parent_guard_foreign_cancel"] and parent.active_calls >= 2 and hits.is_empty() and arena.hero.hp == arena.hero.max_hp and mechanism.state().status == "cancelled" and mechanism.state().hit_ids.is_empty(), mutation + " later foreign invalidation revokes earlier parent answer and is rechecked before consumption")
	await _dispose(arena)


func _guard_paused_fresh_restore() -> void:
	var raw: Dictionary = Mechanism.DEFAULT_RAW_ROLE.duplicate(true)
	raw.active_s = 0.02
	var arena: Dictionary = World.create(self, raw)
	await _ticks(5)
	var mechanism: CinderLaneMechanism = arena.mechanism
	var parent: ParentGuard = _parent(arena, "pause")
	_expect(mechanism.set_presentation_guard(parent.guard), "pause fixture binds actual ephemeral parent guard")
	arena.scheduler.begin_encounter("standard", "parent-guard")
	var hits: Array[String] = []
	mechanism.hit_resolved.connect(func(id: String, _cycle: int, _result: Dictionary) -> void: hits.append(id))
	var answer: Dictionary = mechanism.start("hero", parent.context)
	var reached_pause: bool = answer.get("accepted", false) and await _until_phase(mechanism, "active") and paused
	_expect(reached_pause, "actual guard pauses after native active publication before hurt")
	if not reached_pause:
		await _dispose(arena)
		return
	await process_frame
	var calls: int = parent.calls
	var pair: Dictionary = _exact_json({"hero": arena.hero.snapshot_state(), "scheduler": arena.scheduler.snapshot_state(World.bindings(arena)), "mechanism": mechanism.snapshot_state(World.bindings(arena))})
	_expect(parent.calls == calls and not pair.mechanism.is_empty() and pair.mechanism.schema_version == 2 and hits.is_empty() and pair.mechanism.hit_ids.is_empty() and arena.hero.hp == arena.hero.max_hp, "quiet paused capture invokes no guard and preserves exact pending original opportunity")
	if pair.mechanism.is_empty():
		await _dispose(arena)
		return
	await _dispose(arena)
	arena = World.create(self, raw)
	await _ticks(5)
	mechanism = arena.mechanism
	parent = _parent(arena)
	_expect(mechanism.set_presentation_guard(parent.guard), "fresh actual recipient explicitly binds new parent guard before restoring old wire")
	arena.scheduler.begin_encounter("standard", "parent-guard")
	paused = true
	await process_frame
	var bindings: Dictionary = World.bindings(arena)
	bindings.hero_positions = {"hero": Codec.read_vector3(pair.hero.motion.position)}
	calls = parent.calls
	var restored: bool = arena.hero.snapshot_error(pair.hero).is_empty() and arena.scheduler.snapshot_error(pair.scheduler, bindings).is_empty() and mechanism.snapshot_error(pair.mechanism, bindings, pair.scheduler).is_empty() and arena.hero.restore_state(pair.hero) and arena.scheduler.restore_state(pair.scheduler, bindings) and mechanism.restore_state(pair.mechanism, bindings)
	_expect(restored and parent.calls == calls and arena.hero.hp == arena.hero.max_hp and ExactJson.stringify(mechanism.snapshot_state(bindings)) == ExactJson.stringify(pair.mechanism), "fresh quiet Player-Scheduler-mechanism aggregate restoration never invokes provider or changes envelope")
	if restored:
		hits.clear()
		mechanism.hit_resolved.connect(func(id: String, _cycle: int, _result: Dictionary) -> void: hits.append(id))
		paused = false
		await _ticks(3)
		_expect(parent.calls > calls and hits == ["hero"] and arena.hero.hp == arena.hero.max_hp - arena.hero.equipment.damage_received(4.0) and mechanism.state().hit_ids == ["hero"], "fresh restored provider rechecks on real resumed tick and consumes the original pending hit once")
	await _dispose(arena)
