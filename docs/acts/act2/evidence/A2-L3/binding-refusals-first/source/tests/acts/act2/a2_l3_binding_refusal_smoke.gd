extends "res://tests/acts/act2/a2_l3_smoke_custody.gd"
## Focused real paused initial aggregate refusals and queued road-source custody.
## The future cursor and moved idle tool are TEST ONLY rejection inputs. Contact
## uses two actual completed dashes and delivered native smoke damage, then a
## priority98 queue_free intervention before guard99/contact100. No live Hero
## HP, motion, phase, gear, progress or source/Scheduler clock is seeded.

func _run() -> void:
	var only: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--case="): only = argument.trim_prefix("--case=")
	if not _expect(only in ["", "bindings", "queued_tender"], "supported explicit binding-refusal case selector"):
		quit(1); return
	if only.is_empty() or only == "bindings": await _initial_binding_refusals()
	if only.is_empty() or only == "queued_tender": await _queued_tender_before_contact()
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "selected actual binding/custody units release their target and required-cue subtrees")
	print("A2-L3 binding refusals: %d checks, %d failures; initial full19 atomic cursor/tool refusals and real pre100 queued Tender contact only, no full route/fresh retry claim" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _initial_binding_refusals() -> void:
	if not await _boot_custody(): await _release(); return
	if not await _barrier(): await _release(); return
	var whole: Dictionary = _level.snapshot_state()
	var player: Dictionary = _hero.snapshot_state()
	if not _expect(not whole.is_empty() and whole.local.size() == 19 and whole.local.banks.size() == 3 and not player.is_empty() and _level.snapshot_error_with_player(whole, player).is_empty(), "real initial paused Main/Hero provides the complete accepted full19/three-bank pack"):
		await _release(); return
	var whole_encoded: String = Exact.stringify(whole)
	var events: Array[String] = []
	_observe_binding_events(events)
	var before: Dictionary = _independent_binding_state()
	var future: Dictionary = whole.duplicate(true)
	future.local.last_action_sequence = int(player.world_actions.sequence) + 1
	var error: String = _level.snapshot_error_with_player(future, player)
	_expect(not error.is_empty(), "pure whole preflight rejects a local cursor ahead of the complete saved Player sequence")
	_expect_independent_binding_state(before, events, "future cursor preflight")
	_expect(not _level.restore_state(future) and not _level.last_snapshot_error.is_empty(), "public whole restore rejects the future cursor before commit")
	_expect_independent_binding_state(before, events, "future cursor restore")
	_expect(Exact.stringify(_level.snapshot_state()) == whole_encoded, "future cursor rejection leaves the original public whole pack exact")

	var tool: Node3D = _level.get("_mechanisms")["tool_house_handler"] as Node3D
	var state: Dictionary = tool.call("state")
	if not _expect(is_instance_valid(tool) and state.status == "idle" and state.cycle == 0, "actual future house tool remains idle and unstarted before the native binding intervention"):
		await _release(); return
	var original: Transform3D = tool.transform
	tool.position += Vector3(0.25, 0.0, 0.0)
	var altered: Transform3D = tool.transform
	var moved_before: Dictionary = _independent_binding_state()
	_expect(altered != original and tool.call("state").status == "idle", "TEST ONLY native idle-tool transform changes while the entire actual unit is paused")
	error = _level.snapshot_error_with_player(whole, player)
	_expect(not error.is_empty(), "pure whole preflight rejects the displaced actual idle tool even without a danger lease")
	_expect_independent_binding_state(moved_before, events, "moved idle-tool preflight")
	_expect(tool.transform == altered, "preflight neither commits nor heals the deliberately altered native tool transform")
	_expect(not _level.restore_state(whole) and not _level.last_snapshot_error.is_empty(), "public whole restore refuses the moved idle tool before any owned commit")
	_expect_independent_binding_state(moved_before, events, "moved idle-tool restore")
	_expect(tool.transform == altered, "atomic restore refusal retains the deliberately altered native transform")
	# Restore only this explicit TEST ONLY binding intervention; never repair
	# resources, root runtime errors, actors, clocks or gameplay history.
	tool.transform = original
	_expect(tool.transform == original and _level.snapshot_error_with_player(whole, player).is_empty(), "original idle-tool transform restores healthy preflight without changing the saved components")
	_expect(Exact.stringify(_level.snapshot_state()) == whole_encoded and events.is_empty(), "original transform restoration leaves the original complete pack exact and event-free")
	await _release()

func _independent_binding_state() -> Dictionary:
	# Separate native/public component reads remain meaningful even when whole
	# capture correctly refuses a moved tool. Include root fields independently
	# so a late commit failure cannot be hidden by an empty aggregate capture.
	var bindings: Dictionary = _level.call("_scheduler_bindings")
	var actors: Dictionary = {}
	for id: String in _level.get("_actors"):
		actors[id] = _level.get("_actors")[id].call("snapshot_state")
	var tools: Dictionary = {}
	for id: String in _level.get("_mechanisms"):
		tools[id] = _level.get("_mechanisms")[id].call("snapshot_state", bindings)
	var banks: Dictionary = {}
	for id: String in _level.get("_clouds"):
		banks[id] = _level.get("_clouds")[id].call("snapshot_state", bindings)
	var fields: Dictionary = {}
	for key: String in ["_profile_id", "_scenic_clock", "_last_action_sequence", "_contact_seen", "_pending_checkpoints", "_completion_pending", "_exit_requested", "_boss_phase_pending", "_boss_next_action", "_boss_ready_s", "_views", "_bank_views", "_bank_proofs", "_mechanism_proofs", "_forecast_points", "runtime_error"]:
		fields[key] = _level.get(key)
	var result: Dictionary = {"player": _hero.snapshot_state(), "actors": actors, "sequence": _level.get("_crossing").call("snapshot_state"), "scheduler": _scheduler.snapshot_state(bindings), "rays": _level.get("_exchange").call("snapshot_state", bindings), "tools": tools, "banks": banks, "root_fields": fields.duplicate(true), "checkpoint": _level.current_checkpoint(), "completed": _level.is_completed()}
	var complete: bool = not result.player.is_empty() and not result.sequence.is_empty() and not result.scheduler.is_empty() and not result.rays.is_empty() and actors.size() == 7 and tools.size() == 4 and banks.size() == 3
	for components: Dictionary in [actors, tools, banks]:
		for value: Dictionary in components.values(): complete = complete and not value.is_empty()
	_expect(complete and not Exact.stringify(result).is_empty(), "independent real Player/actors/sequence/Scheduler/consumers expose complete paused state")
	return result

func _expect_independent_binding_state(before: Dictionary, events: Array[String], label: String) -> void:
	var after: Dictionary = _independent_binding_state()
	for key: String in ["player", "actors", "sequence", "scheduler", "rays", "tools", "banks", "root_fields", "checkpoint", "completed"]:
		_expect(Exact.stringify(after[key]) == Exact.stringify(before[key]), label + " leaves independent " + key + " exact")
	_expect(events.is_empty(), label + " publishes no input, gameplay, cue, defeat or progress event")

func _observe_binding_events(events: Array[String]) -> void:
	_hero.world_action_executed.connect(func(_record: Dictionary) -> void: events.append("action"))
	_hero.fired.connect(func(_kind: String) -> void: events.append("fired"))
	_hero.action_resolved.connect(func(_kind: String, _hits: int, _damage: float) -> void: events.append("action-result"))
	_hero.died.connect(func() -> void: events.append("death"))
	_hero.equipment_changed.connect(func(_id: String) -> void: events.append("gear"))
	_level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: events.append("checkpoint"))
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: events.append("completion"))
	_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: events.append("exit"))
	_game.connect("input_observed", func(_record: Dictionary) -> void: events.append("input"))
	_scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: events.append("cancel"))
	var ray: Node = _level.get("_exchange")
	ray.connect("state_changed", func(_id: String, _state: Dictionary) -> void: events.append("ray-phase"))
	ray.connect("hit_resolved", func(_id: String, _result: Dictionary) -> void: events.append("ray-hit"))
	ray.connect("scout_defeated", func(_id: String) -> void: events.append("target-defeat"))
	for tool: Node in _level.get("_mechanisms").values():
		tool.connect("state_changed", func(_state: Dictionary) -> void: events.append("tool-phase"))
		tool.connect("hit_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: events.append("tool-hit"))
	for bank: Node in _level.get("_clouds").values():
		bank.connect("state_changed", func(_state: Dictionary) -> void: events.append("bank-phase"))
		bank.connect("tick_resolved", func(_id: String, _cycle: int, _result: Dictionary) -> void: events.append("bank-tick"))
	for actor: Node in _level.get("_actors").values():
		actor.connect("defeated", func(_id: String) -> void: events.append("target-defeat"))
		if actor.has_signal("phase_boundary_reached"):
			actor.connect("phase_boundary_reached", func(_id: String) -> void: events.append("boss-phase-boundary"))
	for cue: Node in get_nodes_in_group("required_cues"):
		if _level.is_ancestor_of(cue) and cue.has_signal("state_changed"):
			cue.connect("state_changed", func(_state: Dictionary) -> void: events.append("required-cue"))
	for cue: Node in _level.get("_opening_cues").values():
		cue.connect("state_changed", func(_state: Dictionary) -> void: events.append("opening"))
	_level.get("_exit_cue").connect("state_changed", func(_state: Dictionary) -> void: events.append("exit-cue"))

func _queued_tender_before_contact() -> void:
	if not await _boot_custody(): await _release(); return
	if not await _drive_to_contact(): await _release(); return
	# No typed actor reference survives deletion. The explicit WeakRef is read
	# and validated only inside the pre100 intervention, then must become null.
	var source: WeakRef = weakref(_level.get("_actors").get(TENDER_ID))
	var events: Array[String] = []
	_observe_binding_events(events)
	var observed: Array[Dictionary] = []
	var probe := BeforeContactProbe.new()
	probe.name = "TESTONLY_QueueRoadTenderBeforeSmokeContact"
	probe.process_physics_priority = 98
	probe.process_mode = Node.PROCESS_MODE_PAUSABLE
	probe.callback = func() -> void:
		if not observed.is_empty(): return
		var value: Dictionary = _bank.call("state")
		if value.status != "running" or value.phase != "active" or value.receipts.is_empty() or value.next_eligible_s == null: return
		var now: float = _scheduler.get_clock()
		if now < float(value.next_eligible_s): return
		var last_damage_s: float = -1.0
		for receipt: Dictionary in value.receipts:
			if receipt.result.get("accepted", false): last_damage_s = float(receipt.consumed_s)
		if last_damage_s < 0.0 or now < last_damage_s + float(_hero.stats.hurt_invulnerability) + 0.05: return
		var offset: Vector3 = _hero.global_position - _bank.global_position
		var inside: bool = _hero.is_on_floor() and Vector2(offset.x, offset.z).length_squared() < pow(1.05 + CinderThreatScheduler.CAPSULE_RADIUS, 2.0)
		var actor: Variant = source.get_ref()
		if not inside or not is_instance_valid(actor) or actor.is_queued_for_deletion(): return
		observed.append({"bank": value.duplicate(true), "hp": _hero.hp, "receipts": value.receipts.size(), "ticks": events.count("bank-tick"), "clock_s": now, "inside": inside, "source_hp": actor.get("hp"), "queued": false, "pause_accepted": false})
		actor.queue_free()
		observed[0].queued = actor.is_queued_for_deletion()
		observed[0].pause_accepted = bool(_game.call("request_pause_deferred"))
	_level.add_child(probe)
	var reached: bool = await _wait_custody(func() -> bool: return not observed.is_empty() and paused)
	if not _expect(reached, "actual road-bank contact delivers HP damage then reaches another eligible pre100 native tick"):
		print("Queued source setup diagnostic: bank=", _bank.call("state"), " Hero=", _hero.global_position, " HP=", _hero.hp, " root_error=", _level.get("runtime_error"))
		await _release(); return
	await _barrier()
	var original: Dictionary = observed[0].bank
	var current: Dictionary = _bank.call("state")
	_expect(observed[0].inside and float(observed[0].hp) < 100.0 and float(observed[0].source_hp) == 30.0 and observed[0].queued and observed[0].pause_accepted and source.get_ref() == null, "real delivered contact precedes source queue/free and the complete native deferred-pause barrier")
	_expect(_hero.hp == float(observed[0].hp) and not _hero.dead and current.receipts.size() == int(observed[0].receipts) and events.count("bank-tick") == int(observed[0].ticks), "queued Tender before guard99/contact100 permits no further actual HP, opportunity or tick notification")
	_expect(current.status == "cancelled" and current.phase == "clear" and current.cycle == original.cycle and current.exchange.id == original.exchange.id, "parent custody cancels only the original admitted road-bank cycle")
	_expect(not _level.get("_bank_views").has(BANK_ID) and _scheduler.reservations().is_empty(), "queued source cancellation retains no replacement bank witness or danger lease")
	_expect(not String(_level.get("runtime_error")).is_empty() and _level.snapshot_state().is_empty(), "lost actual authored actor is an explicit root fault and whole checkpoint refusal")
	_expect(_level.get("_crossing").call("snapshot_state").stage_index == 0 and _level.current_checkpoint().id.is_empty() and not _level.is_completed() and not events.has("target-defeat") and not events.has("checkpoint") and not events.has("completion") and not events.has("exit"), "queue/free is no accepted defeat, earned contact, checkpoint or completion")

	# The native HP-free bank remains independently bound to Hero/Scheduler.
	# Its public component capture is distinct from the rejected whole level;
	# never read/cast the freed Tender or repair the authored actor map here.
	var bindings: Dictionary = _level.call("_scheduler_bindings")
	var player: Dictionary = _hero.snapshot_state()
	var scheduler: Dictionary = _scheduler.snapshot_state(bindings)
	var saved: Dictionary = _bank.call("snapshot_state", bindings)
	if _expect(not player.is_empty() and not scheduler.is_empty() and not saved.is_empty(), "healthy independent native Player/Scheduler/canceled Bank still supply paused component captures"):
		_expect(saved.status == "cancelled" and saved.cycle == original.cycle and saved.exchange.id == original.exchange.id and _bank.call("snapshot_error", saved, bindings, scheduler, player).is_empty(), "published canceled Bank preflights its complete actual saved Player/staged Scheduler despite the lost external Tender")
		for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
			_expect(float(saved.exchange[key]) == float(original.exchange[key]), "queued source cancellation preserves exact original " + key)
		if float(saved.exchange.cooldown_until_s) > float(scheduler.clock_s):
			var retained: bool = false
			for cooldown: Dictionary in scheduler.cooldowns:
				if cooldown.source_id == BANK_ID and float(cooldown.ready_s) == float(saved.exchange.cooldown_until_s): retained = true
			_expect(retained, "queued source cancellation retains its original unexpired admitted cooldown without refresh")
		var encoded: String = Exact.stringify({"player": player, "scheduler": scheduler, "bank": saved})
		var decoded: Dictionary = Exact.parse(encoded)
		_expect(not encoded.is_empty() and decoded.get("accepted", false) and Exact.stringify(decoded.value) == encoded, "independent canceled component transport retains exact scalar values")
	await _release()
