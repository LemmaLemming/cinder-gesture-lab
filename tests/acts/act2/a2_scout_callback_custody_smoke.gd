extends "res://tests/acts/act2/a2_l1_ray_exchange_smoke.gd"
## Isolated TEST ONLY callback-custody regression from integration RESPONSE
## ad2a03eb-0652-4a72-9f00-92bccc21a622. No authored route/native-art claim.
## Before-fix owned source witnesses:
## Ray actor SHA256 1ffb51c7197f33d483538997543cee3fd629965f0f9625f38b762f8408be4e30
## Ray driver SHA256 5a9abf5ae3b1875ba9eacbce9036c5eb82de67d058be1d208b24e222c7a70642
## Inherited suite SHA256 e9426bd1f0eb6325ed1ddcd1b9f6b3004e461e6a55e86db1eb29ea57e0f3b405
## Raw clocks remain actual 0.45 tracking/FULL1.10 lock/0.16 active/1.60
## recovery, interval1.60, rawdamage10, HP30, anchored move_speed0.
## SceneTree pause and initial manual target identity/root/recovery below are
## explicit TEST ONLY fixture controls, not a CampaignShell/level proof.
## No private scheduler, source clocks, hit latches, hero HP or dead assignment.

const MANUAL_ID: String = "TEST-ONLY:callback-custody-manual"

func _run() -> void:
	print("Scout callback custody: isolated TEST ONLY source/cue-plus-pause, actual recovery/query cleanup callbacks, manual true-gate defensive context; prior actor1ffb51c/driver5a9abf5 source witness; no full route/native claim")
	for intervention: String in ["hide_source", "clear_cue", "pure_pause"]:
		await _custody_outgoing_pause(intervention)
	for intervention: String in ["hide_source", "clear_cue", "kill_hero"]:
		await _custody_recovery_query(intervention)
	for intervention: String in ["pure_true", "pause", "disarm", "kill_hero"]:
		await _custody_manual_gate(intervention)
	print("A2 isolated Scout callback custody smoke: %d checks, %d failures; actual public tracking/recovery/callbacks and quiet exact canceled transport; no level/native acceptance" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _custody_outgoing_pause(intervention: String) -> void:
	var arena: Dictionary = _create()
	await _ticks(6)
	var driver: Node3D = arena.driver
	var scheduler: CinderThreatScheduler = arena.scheduler
	var hero: CinderPlayer = arena.hero
	var actor: Node3D = arena.actor
	var observed: Array[Dictionary] = []
	var hits: Array[Dictionary] = []
	var once: Array[bool] = [false]
	driver.connect("hit_resolved", func(_id: String, value: Dictionary) -> void: hits.append(value.duplicate(true)))
	driver.connect("state_changed", func(id: String, value: Dictionary) -> void:
		if id != SCOUT_ID or value.phase != "active" or once[0]: return
		once[0] = true
		observed.append(value.duplicate(true))
		if intervention == "hide_source": actor.hide()
		elif intervention == "clear_cue": driver.call("get_cue", SCOUT_ID).clear()
		paused = true
	)
	var hp_before: float = hero.hp
	var admitted: Dictionary = driver.call("activate", SCOUT_ID)
	_expect(admitted.get("accepted", false), intervention + " starts real unarmed tracking through the actual shared scheduler")
	if not admitted.get("accepted", false):
		await _dispose(arena)
		return
	_expect(await _until_phase(arena, "lock"), intervention + " reaches the actual proved full lock before its active callback")
	for frame: int in range(180):
		if once[0]: break
		await _ticks(1)
	_expect(once[0] and paused and observed.size() == 1 and observed[0].armed and observed[0].phase == "active", intervention + " actual driver active-state observer holds a synchronous tree pause")
	if not once[0]:
		await _dispose(arena)
		return
	await process_frame
	var current: Dictionary = driver.call("state", SCOUT_ID)
	var expected_cancel: bool = intervention != "pure_pause"
	if expected_cancel:
		_expect(current.status == "cancelled" and current.phase == "clear" and not current.last_cancel_reason.is_empty() and not current.armed and not current.hit_consumed and current.presentation_witness.is_empty(), intervention + " rejects lost source/cue BEFORE pause retention can preserve damage authority")
		_expect(scheduler.reservations().is_empty() and driver.call("get_cue", SCOUT_ID).state().phase == "clear" and driver.call("get_opening_cue", SCOUT_ID).state().state == "clear", intervention + " visibly clears danger, opening and actual reservation while pause remains held")
	else:
		_expect(current.status == "running" and current.phase == "active" and current.armed and scheduler.reservations().size() == 1, "pure pause preserves valid source/cue and the existing committed lease")
	_expect(hero.hp == hp_before and hits.is_empty() and not current.hit_consumed, intervention + " callback tick produces no HP loss or consumed outgoing opportunity")
	var saved: Dictionary = _custody_capture(arena)
	if not saved.is_empty():
		var record: Dictionary = saved.driver.records[SCOUT_ID]
		_expect(record.deferred_paths.is_empty() if expected_cancel else not record.deferred_paths.is_empty(), intervention + " transport retains no path for canceled danger and preserves a measured path only for valid pure pause")
		_expect(record.cycle == observed[0].cycle and record.exchange.id == observed[0].exchange.id and saved.scheduler.clock_s == scheduler.get_clock(), intervention + " capture retains exact original source cycle/reservation and current shared clock")
		var cooldown: Dictionary = _custody_cooldown(saved.scheduler, SCOUT_ID)
		_expect(not cooldown.is_empty() and cooldown.ready_s == record.exchange.cooldown_until_s, intervention + " preserves the exact consumed source cooldown without refresh")
		await _custody_fresh_transport(arena, saved, expected_cancel, intervention)
	await _dispose(arena)

func _custody_capture(arena: Dictionary) -> Dictionary:
	var unit: Dictionary = {"player": (arena.hero as CinderPlayer).snapshot_state(), "scheduler": (arena.scheduler as CinderThreatScheduler).snapshot_state(arena.bindings), "driver": (arena.driver as Node3D).call("snapshot_state", arena.bindings)}
	_expect(not unit.player.is_empty() and not unit.scheduler.is_empty() and not unit.driver.is_empty(), "strict paused player/actors/scheduler/driver aggregate capture succeeds outside callbacks")
	if unit.player.is_empty() or unit.scheduler.is_empty() or unit.driver.is_empty():
		print("Custody capture refusal: player=", (arena.hero as CinderPlayer).last_snapshot_error, " scheduler=", (arena.scheduler as CinderThreatScheduler).last_snapshot_error, " driver=", arena.driver.get("last_snapshot_error"))
		return {}
	var encoded: String = ExactJson.stringify(unit)
	var decoded: Dictionary = ExactJson.parse(encoded)
	_expect(not encoded.is_empty() and decoded.get("accepted", false) and decoded.get("value") is Dictionary and ExactJson.stringify(decoded.value) == encoded, "ExactJson preserves the entire closed paused unit, including original copied clocks/deadlines/latches")
	return decoded.value if decoded.get("accepted", false) and decoded.get("value") is Dictionary else {}

func _custody_fresh_transport(arena: Dictionary, saved: Dictionary, expected_cancel: bool, label: String) -> void:
	var fresh: Dictionary = _create()
	await process_frame
	var driver: Node3D = fresh.driver
	var scheduler: CinderThreatScheduler = fresh.scheduler
	var hero: CinderPlayer = fresh.hero
	var staged: Dictionary = fresh.bindings.duplicate(true)
	staged.hero_positions = {"hero": Codec.read_vector3(saved.player.motion.position)}
	var quiet: Array[String] = []
	driver.connect("state_changed", func(_id: String, _value: Dictionary) -> void: quiet.append("state"))
	driver.connect("hit_resolved", func(_id: String, _value: Dictionary) -> void: quiet.append("hit"))
	driver.connect("scout_defeated", func(_id: String) -> void: quiet.append("defeat"))
	driver.call("get_cue", SCOUT_ID).state_changed.connect(func(_value: Dictionary) -> void: quiet.append("cue"))
	driver.call("get_opening_cue", SCOUT_ID).state_changed.connect(func(_value: Dictionary) -> void: quiet.append("opening"))
	hero.equipment_changed.connect(func(_id: String) -> void: quiet.append("equipment"))
	hero.died.connect(func() -> void: quiet.append("death"))
	scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: quiet.append("cancel"))
	var before: String = ExactJson.stringify({"player": hero.snapshot_state(), "scheduler": scheduler.snapshot_state(fresh.bindings), "driver": driver.call("snapshot_state", fresh.bindings)})
	var preflight: bool = hero.snapshot_error(saved.player).is_empty() and scheduler.snapshot_error(saved.scheduler, staged).is_empty() and String(driver.call("snapshot_error", saved.driver, staged, saved.scheduler)).is_empty()
	_expect(preflight and before == ExactJson.stringify({"player": hero.snapshot_state(), "scheduler": scheduler.snapshot_state(fresh.bindings), "driver": driver.call("snapshot_state", fresh.bindings)}) and quiet.is_empty(), label + " fresh staged-player complete preflight changes no actual source/hero/clock/event")
	var restored: bool = preflight and hero.restore_state(saved.player)
	for id: String in saved.driver.actors:
		if restored: restored = bool((fresh.actors[id] as Node3D).call("restore_state", saved.driver.actors[id]))
	if restored: restored = scheduler.restore_state(saved.scheduler, fresh.bindings)
	if restored: restored = bool(driver.call("restore_state", saved.driver, fresh.bindings))
	_expect(restored and quiet.is_empty(), label + " fresh player then actors then scheduler then driver commit is quiet and creates no request/damage")
	if restored:
		var rebuilt: Dictionary = _custody_capture(fresh)
		_expect(not rebuilt.is_empty() and ExactJson.stringify(rebuilt) == ExactJson.stringify(saved), label + " fresh snapshot preserves every canceled/running state, copied deadline/cooldown and sample bit")
		var state: Dictionary = driver.call("state", SCOUT_ID)
		if expected_cancel:
			_expect((fresh.actor as Node3D).is_visible_in_tree() and state.status == "cancelled" and state.phase == "clear" and not state.armed and not state.hit_consumed and saved.driver.records[SCOUT_ID].deferred_paths.is_empty() and scheduler.reservations().is_empty() and driver.call("get_cue", SCOUT_ID).state().phase == "clear", label + " a fresh visible actor cannot resurrect the canceled source's hidden/cleared authority")
		else:
			_expect(state.status == "running" and state.armed and not state.hit_consumed and not saved.driver.records[SCOUT_ID].deferred_paths.is_empty(), "fresh valid pure pause keeps the measured original unconsumed opportunity")
		# Retire the old driver while paused. Keep its subtree until the caller
		# disposes it; the independent fresh world alone continues saved danger.
		arena.driver.call("cleanup")
		quiet.clear()
		var hp: float = hero.hp
		paused = false
		await _ticks(16)
		paused = true
		await process_frame
		var continued: Dictionary = _custody_capture(fresh)
		if not continued.is_empty():
			var continuation: Dictionary = continued.driver.records[SCOUT_ID]
			if expected_cancel:
				_expect(hero.hp == hp and continuation.status == "cancelled" and continuation.phase == "clear" and not continuation.hit_consumed and continuation.deferred_paths.is_empty() and scheduler.reservations().is_empty() and quiet.is_empty(), label + " resumed fresh canceled unit has no path, hit, lease or authority resurrection")
			else:
				_expect(quiet.count("hit") == 1 and hero.hp == hp - hero.equipment.damage_received(10.0) and continuation.hit_consumed and continuation.deferred_paths.is_empty() and continuation.phase == "recovery", "pure pause control resumes exactly one original active opportunity without blanket cancellation")
			_expect(ExactJson.stringify(continuation.exchange) == ExactJson.stringify(saved.driver.records[SCOUT_ID].exchange) and _custody_cooldown(continued.scheduler, SCOUT_ID) == _custody_cooldown(saved.scheduler, SCOUT_ID), label + " continuation never requests a replacement or refreshes original deadlines/cooldown")
	await _dispose(fresh)

func _custody_recovery_query(intervention: String) -> void:
	var arena: Dictionary = _create()
	await _ticks(6)
	var driver: Node3D = arena.driver
	var scheduler: CinderThreatScheduler = arena.scheduler
	var hero: CinderPlayer = arena.hero
	var actor: Node3D = arena.actor
	var admitted: Dictionary = driver.call("activate", SCOUT_ID)
	_expect(admitted.get("accepted", false), intervention + " incoming fixture admits real tracking")
	if not admitted.get("accepted", false):
		await _dispose(arena)
		return
	_expect(await _until_phase(arena, "recovery"), intervention + " incoming fixture reaches actual full-lock/active/recovery deadlines")
	var original: Dictionary = driver.call("state", SCOUT_ID)
	# Let actual prior hurt invulnerability expire while retaining the real1.60
	# recovery window; lethal mutation must be a genuine accepted Player hit.
	await _until_clock(scheduler, float(original.exchange.active_until_s) + float(hero.stats.hurt_invulnerability) + 0.05)
	_expect(bool(driver.call("damage_window_open", SCOUT_ID)), intervention + " first actual source has a valid live recovery gate before cleanup")
	var secondary := Node3D.new()
	secondary.name = "IndependentCleanupSource"
	secondary.position = Vector3(1.0, 0.0, 0.0)
	(arena.root as Node3D).add_child(secondary)
	var shape: Dictionary = Geometry.lane(secondary.global_position, secondary.global_position + Vector3.BACK * 3.8, 0.31)
	var threat: Dictionary = {"role": original.resolved_role.duplicate(true), "geometry": shape, "source_stationary": true, "opening_stationary": true, "opening_position": secondary.global_position, "cooldown_remaining_s": 0.0}
	var response: Dictionary = hero.get_threat_response_state()
	for key: String in arena.context:
		if key != "encounter_id": response[key] = arena.context[key]
	var other: Dictionary = scheduler.request_tracking(secondary, threat, response)
	_expect(other.get("accepted", false) and not other.get("armed", true) and scheduler.reservations().size() == 2, intervention + " independent actual Node3D owner holds a second public tracking lease")
	if not other.get("accepted", false):
		await _dispose(arena)
		return
	var own_id: String = String(original.reservation_id)
	var own_before: Dictionary = scheduler.reservation_state(own_id)
	var callbacks: Array[Dictionary] = []
	scheduler.reservation_invalidated.connect(func(id: String, reason: String) -> void:
		if id != String(other.reservation_id): return
		callbacks.append({"id": id, "reason": reason, "clock_s": scheduler.get_clock()})
		if intervention == "hide_source": actor.hide()
		elif intervention == "clear_cue": driver.call("get_cue", SCOUT_ID).clear()
		else: hero.take_damage(hero.hp * float(hero.stats.armour) + 1.0, Vector3.ZERO)
	)
	var hp: float = float(actor.get("hp"))
	# This owner is outside the driver's bound actor map. Queuing it leaves
	# the driver binding check valid until its gate's reservation_state prunes
	# that real second lease and synchronously invokes the observer above.
	secondary.queue_free()
	var damage: Dictionary = actor.call("take_damage", 2.0, Vector3.ZERO)
	_expect(callbacks.size() == 1 and callbacks[0].id == other.reservation_id and callbacks[0].reason == "source_removed" and callbacks[0].clock_s == scheduler.get_clock(), intervention + " actual gate query triggers exactly one real cleanup invalidation observer")
	_expect(not damage.accepted and damage.hp_damage == 0.0 and float(actor.get("hp")) == hp, intervention + " incoming target damage rechecks required source/cue/live Hero AFTER callback-producing reservation query")
	var own_after: Dictionary = scheduler.reservation_state(own_id)
	_expect(not own_before.is_empty() and not own_after.is_empty() and own_before == own_after and driver.call("state", SCOUT_ID).cycle == original.cycle, intervention + " query regression changes no first-source lease/deadlines/cycle to manufacture rejection")
	if intervention == "kill_hero": _expect(hero.dead and hero.hp == 0.0, "query observer uses actual public Player damage/death, not an assigned dead flag")
	await _dispose(arena)

func _custody_manual_gate(intervention: String) -> void:
	var arena: Dictionary = _create()
	await _ticks(6)
	var hero: CinderPlayer = arena.hero
	var target: Node3D = ActorScript.new() as Node3D
	target.name = "ManualGateScout"
	target.position = Vector3(-3.0, 0.0, 0.0)
	(arena.root as Node3D).add_child(target)
	_expect(bool(target.call("configure", hero, arena.effects, MANUAL_ID)) and bool(target.call("present_phase", "recovery", 0.5, Vector3.BACK)), intervention + " TEST ONLY manual target uses public configuration and explicit isolated recovery pose")
	var gate_calls: Array[String] = []
	var gate: Callable = func() -> bool:
		gate_calls.append(intervention)
		if intervention == "pause": paused = true
		elif intervention == "disarm": target.call("disarm")
		elif intervention == "kill_hero": hero.take_damage(hero.hp * float(hero.stats.armour) + 1.0, Vector3.ZERO)
		return true
	_expect(bool(target.call("bind_damage_window", gate)), intervention + " manual target installs one actual public configured gate")
	var defeats: Array[String] = []
	target.connect("defeated", func(id: String) -> void: defeats.append(id))
	var damage: Dictionary = target.call("take_damage", 2.0, Vector3.ZERO)
	_expect(gate_calls == [intervention] and defeats.is_empty(), intervention + " configured true gate runs exactly once and causes no target defeat event")
	if intervention == "pure_true":
		_expect(damage.accepted and damage.hp_damage == 2.0 and float(target.get("hp")) == 28.0, "valid true-gate control retains ordinary accepted-result damage")
	else:
		_expect(not damage.accepted and damage.hp_damage == 0.0 and float(target.get("hp")) == 30.0, intervention + " actor rechecks current pause/live binding/Hero after an otherwise true gate before HP mutation")
	if intervention == "pause": _expect(paused, "manual true gate genuinely pauses the actual tree")
	elif intervention == "disarm": _expect(not bool(target.call("is_armed")), "manual true gate genuinely retires its actual public binding")
	elif intervention == "kill_hero": _expect(hero.dead and hero.hp == 0.0, "manual true gate genuinely defeats the bound shared Hero through accepted damage")
	await _dispose(arena)

func _custody_cooldown(shared: Dictionary, source_id: String) -> Dictionary:
	for entry: Dictionary in shared.cooldowns:
		if entry.source_id == source_id: return entry.duplicate(true)
	return {}
