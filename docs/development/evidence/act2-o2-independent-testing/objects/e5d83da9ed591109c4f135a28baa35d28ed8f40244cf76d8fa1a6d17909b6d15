extends "res://tests/acts/act2/a2_l3_entry_smoke.gd"
## Actual authored Main/L3 bank custody at real road-bank contact. No Hero HP,
## motion, phase, source clock, defeat/progression or equipment seed. Uses real
## public dashes/primary and deferred native pause. Native camera projection narrowing and
## source/cue hiding are explicit TEST ONLY presentation-loss interventions.
## Recovery cue.clear is before a real primary/query, not an injected Scheduler
## pruning observer; this fixture does not claim that separate reentrancy case.
const Exact: Script = preload("res://scripts/campaign/exact_json.gd")
const BANK_ID: String = "road_bank"
const TENDER_ID: String = "road_tender"
var _level: CinderLevel
var _bank: Node3D
var _scheduler: CinderThreatScheduler

class BeforeContactProbe:
	extends Node
	var callback: Callable
	func _physics_process(_delta: float) -> void:
		if callback.is_valid(): callback.call()

func _run() -> void:
	var only: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--case="): only = argument.trim_prefix("--case=")
	if not _expect(only in ["", "warning_hide", "pure_pause", "contact_hide", "hide_bank_cue", "frame_loss", "recovery_clear"], "supported explicit custody case selector"):
		quit(1); return
	for intervention: String in ["hide_tender", "pure_pause"]:
		if only.is_empty() or only == ("warning_hide" if intervention == "hide_tender" else intervention): await _warning_pause(intervention)
	for intervention: String in ["hide_tender", "hide_bank_cue", "frame_loss"]:
		if only.is_empty() or only == ("contact_hide" if intervention == "hide_tender" else intervention): await _eligible_contact_loss(intervention)
	if only.is_empty() or only == "recovery_clear": await _recovery_primary_cue_loss()
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "all selected actual L3 custody units release their target/cue subtrees")
	print("A2-L3 actual smoke custody: %d checks, %d failures; real road-bank contact, poststart held pause, pre100 exposure loss and real recovery primary; no full route/pruning-callback claim" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _boot_custody() -> bool:
	root.size = Vector2i(540, 1170)
	_actions.clear()
	_game = Main.instantiate()
	_game.set("level_scene_path", "res://scenes/acts/act2/a2_l3.tscn")
	root.add_child(_game)
	_game.call("resume_lab")
	await _settle(12)
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _expect(is_instance_valid(_level) and is_instance_valid(_hero) and _level.level_id == "A2-L3" and String(_level.get("runtime_error")).is_empty(), "actual authored L3/shared Hero enters healthy for custody"):
		return false
	var banks: Dictionary = _level.get("_clouds")
	_bank = banks.get(BANK_ID) as Node3D
	_scheduler = _level.get("_scheduler") as CinderThreatScheduler
	var guard: Node = _level.get("_bank_guard") as Node
	if not _expect(banks.size() == 3 and is_instance_valid(_bank) and is_instance_valid(_scheduler) and is_instance_valid(guard) and guard.call("binding_matches", Callable(_level, "_guard_banks_before_contact")), "actual three published banks retain the native priority99 parent guard"):
		return false
	_expect(_hero.hp == 100.0 and _hero.is_on_floor() and _bank.call("state").status == "idle", "real initial native Hero settles on the dry floor before any bank emission")
	_hero.world_action_executed.connect(func(record: Dictionary) -> void: _actions.append(record))
	return true

func _step_custody() -> void:
	if not paused and not _game.call("is_pause_requested"): await physics_frame
	await process_frame

func _wait_custody(predicate: Callable, frames: int = 600) -> bool:
	for ignored: int in range(frames):
		if bool(predicate.call()): return true
		await _step_custody()
	return bool(predicate.call())

func _barrier() -> bool:
	if not paused and not _game.call("is_pause_requested"):
		if not _expect(_game.call("request_pause_deferred"), "supported deferred native custody barrier requested"): return false
	for ignored: int in range(3): await process_frame
	return _expect(paused and not _game.call("is_pause_requested"), "complete current native tick/deferred pause barrier settles")

func _warning_pause(intervention: String) -> void:
	if not await _boot_custody(): await _release(); return
	var actor: Node3D = _level.get("_actors")[TENDER_ID]
	var observed: Array[Dictionary] = []
	var pause_result: Array[bool] = []
	# Root listener was installed during real entry; this later observer runs
	# after its warning presentation and before start returns to the parent.
	_bank.connect("state_changed", func(value: Dictionary) -> void:
		if value.status != "running" or value.phase != "warning" or not observed.is_empty(): return
		observed.append(value.duplicate(true))
		if intervention == "hide_tender": actor.hide()
		pause_result.append(bool(_game.call("request_pause_deferred")))
	)
	var hp: float = _hero.hp
	_expect(_hero.request_dash(Vector3.FORWARD), intervention + " public ground dash genuinely enters road Tender admission range")
	var reached: bool = await _wait_custody(func() -> bool: return not observed.is_empty() and paused, 240)
	if not _expect(reached and pause_result == [true], intervention + " actual late warning observer requests and reaches the full native pause"):
		await _release(); return
	await _barrier()
	var current: Dictionary = _bank.call("state")
	if intervention == "hide_tender":
		_expect(current.status == "cancelled" and current.phase == "clear" and not current.last_cancel_reason.is_empty(), "late hidden Tender cancels its accepted independent bank before pause retention")
		_expect(not _level.get("_bank_views").has(BANK_ID) and _scheduler.reservations().is_empty(), "poststart custody failure retains no replacement bank view or danger lease")
		_capture_cancelled(observed[0], true, "late Tender hide")
	else:
		_expect(current.status == "running" and current.phase == "warning" and current.cycle == observed[0].cycle and current.reservation_id == observed[0].reservation_id, "pure deferred pause retains its actual original admitted warning/cycle/lease")
		var pack: Dictionary = _level.snapshot_state()
		_expect(not pack.is_empty() and pack.local.bank_views.has(BANK_ID) and pack.local.banks[BANK_ID].status == "running", "pure held pause retains a complete actual running-bank checkpoint/view")
	_expect(_hero.hp == hp and float(actor.get("hp")) == 30.0 and not _hero.dead, intervention + " warning pause causes no Hero/Tender damage")
	_expect(_level.call("encounter_state").beat == "smoke_edge" and _level.current_checkpoint().id.is_empty() and not _level.is_completed(), "warning pause earns no fictional contact/defeat/progression")
	await _release()

func _drive_to_contact() -> bool:
	if not await _dash(Vector3.FORWARD): return false
	var toward: Vector3 = _bank.global_position - _hero.global_position
	toward.y = 0.0
	if not await _dash(toward): return false
	await _settle(2)
	var offset: Vector3 = _hero.global_position - _bank.global_position
	var inside: bool = Vector2(offset.x, offset.z).length_squared() < pow(1.05 + CinderThreatScheduler.CAPSULE_RADIUS, 2.0)
	return _expect(_actions.size() >= 2 and _actions[-1].kind == "dash" and _actions[-1].landing == _hero.global_position and _hero.is_on_floor() and inside and _bank.call("state").status == "running", "two real completed supported dashes reach the actual admitted road-bank contact disc")

func _eligible_contact_loss(intervention: String) -> void:
	if not await _boot_custody(): await _release(); return
	if not await _drive_to_contact(): await _release(); return
	var actor: Node3D = _level.get("_actors")[TENDER_ID]
	var camera: Camera3D = _game.get("camera") as Camera3D
	var original_width: float = camera.size
	var observed: Array[Dictionary] = []
	var probe := BeforeContactProbe.new()
	probe.name = "TESTONLY_BeforeBankGuardExposureLoss"
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
		if not inside: return
		observed.append({"bank": value.duplicate(true), "hp": _hero.hp, "receipt_count": value.receipts.size(), "clock_s": now, "inside": inside, "frame_failed": false})
		if intervention == "hide_tender": actor.hide()
		elif intervention == "hide_bank_cue": _bank.call("get_cue").hide()
		else:
			# TEST ONLY actual native orthographic projection setter. Window.size
			# does not guarantee headless Viewport changes. Keep Hero/camera
			# transforms and the genuine framing query unchanged.
			camera.size = 1.0
			observed[0].frame_failed = not bool(_level.call("_bank_framed", BANK_ID))
		_game.call("request_pause_deferred")
	_level.add_child(probe)
	var reached: bool = await _wait_custody(func() -> bool: return not observed.is_empty() and paused)
	if not _expect(reached, intervention + " actual stationary contact earns damage then reaches its next real eligible native tick"):
		print("Custody contact setup diagnostic: bank=", _bank.call("state"), " Hero=", _hero.global_position, " HP=", _hero.hp, " root=", _level.call("encounter_state"))
		await _release(); return
	await _barrier()
	var original: Dictionary = observed[0].bank
	var current: Dictionary = _bank.call("state")
	_expect(observed[0].inside and float(observed[0].hp) < 100.0 and original.receipts[0].result.contact and original.receipts[0].result.damage_attempted, intervention + " setup includes a genuine accepted shared smoke contact receipt")
	_expect(_hero.hp == float(observed[0].hp) and not _hero.dead and current.receipts.size() == int(observed[0].receipt_count), intervention + " pre100 presentation loss prevents the next real eligible contact HP/opportunity")
	_expect(current.status == "cancelled" and current.phase == "clear" and current.cycle == original.cycle and current.exchange.id == original.exchange.id, intervention + " priority99 guard cancels the original cycle without replacement")
	_expect(not _level.get("_bank_views").has(BANK_ID) and _scheduler.reservations().is_empty(), intervention + " cancellation leaves no regranted witness or danger lease")
	if intervention == "frame_loss":
		_expect(observed[0].frame_failed, "actual narrowed native projection really fails the parent source/footprint/landing projection")
		camera.size = original_width
	_capture_cancelled(original, intervention != "hide_bank_cue", intervention)
	_expect(float(actor.get("hp")) == 30.0 and _level.call("encounter_state").beat == "smoke_edge" and _level.current_checkpoint().id.is_empty() and not _level.is_completed(), intervention + " contact fixture changes no authored target/progression")
	await _release()

func _recovery_primary_cue_loss() -> void:
	if not await _boot_custody(): await _release(); return
	if not await _drive_to_contact(): await _release(); return
	var actor: Node3D = _level.get("_actors")[TENDER_ID]
	var observed: Array[Dictionary] = []
	_bank.connect("state_changed", func(value: Dictionary) -> void:
		if value.status != "running" or value.phase != "recovery" or not observed.is_empty(): return
		var distance: float = _hero.global_position.distance_to(actor.global_position)
		var before_hp: float = float(actor.get("hp"))
		var hp: float = _hero.hp
		var before_actions: int = _actions.size()
		_bank.call("get_cue").clear()
		var hits: int = _hero.slash(actor.global_position - _hero.global_position)
		observed.append({"bank": value.duplicate(true), "actor_hp": before_hp, "after_actor_hp": actor.get("hp"), "hero_hp": hp, "hits": hits, "distance": distance, "before_actions": before_actions, "cue_cleared": _bank.call("get_cue").state().phase == "clear"})
		_game.call("request_pause_deferred")
	)
	var reached: bool = await _wait_custody(func() -> bool: return not observed.is_empty() and paused)
	if not _expect(reached, "actual admitted road bank reaches recovery before cue-loss primary"):
		await _release(); return
	await _barrier()
	var view: Dictionary = observed[0]
	_expect(view.bank.phase == "recovery" and view.cue_cleared and float(view.distance) <= float(_hero.stats.primary_range), "actual recovering Tender is ordinarily reachable when its shared bank cue is publicly cleared")
	_expect(view.hits == 0 and float(view.after_actor_hp) == float(view.actor_hp) and float(actor.get("hp")) == 30.0, "real ordinary primary/query rejects lost bank native cue before Tender HP commitment")
	_expect(_actions.size() == int(view.before_actions) + 1 and _actions[-1].kind == "primary" and _actions[-1].hits == 0, "rejection is an actual public primary record, not synthetic take_damage or HP assignment")
	_expect(_hero.hp == float(view.hero_hp) and not _hero.dead, "recovery cue-loss primary causes no further Hero exposure damage")
	var current: Dictionary = _bank.call("state")
	_expect(current.status == "cancelled" and current.cycle == view.bank.cycle and current.exchange.id == view.bank.exchange.id and not _level.get("_bank_views").has(BANK_ID), "same-tick cue-loss cancellation retains the original cycle without a replacement bank witness")
	# Public clear may be followed by legitimate owner cancellation. Never
	# repair mutated shared native children or force a valid transport verdict.
	var bindings: Dictionary = _level.call("_scheduler_bindings")
	var saved: Dictionary = _bank.call("snapshot_state", bindings)
	_expect(saved.is_empty() or saved.status == "cancelled", "shared native capture either refuses the lost cue or preserves only its original canceled state")
	_expect(_level.current_checkpoint().id.is_empty() and not _level.is_completed() and _level.call("encounter_state").beat == "smoke_edge", "cue-loss primary earns no target defeat/contact/exit")
	await _release()

func _capture_cancelled(original: Dictionary, healthy: bool, label: String) -> void:
	var bindings: Dictionary = _level.call("_scheduler_bindings")
	var player: Dictionary = _hero.snapshot_state()
	var scheduler: Dictionary = _scheduler.snapshot_state(bindings)
	var saved: Dictionary = _bank.call("snapshot_state", bindings)
	_expect(not player.is_empty() and not scheduler.is_empty(), label + " full native paused Player/Scheduler snapshots remain available")
	if not healthy:
		_expect(saved.is_empty() and not String(_bank.get("last_snapshot_error")).is_empty(), "hidden actual shared cue remains invalid; no private redraw/restore repairs the corrupt native unit")
		_expect(_level.snapshot_state().is_empty(), "whole checkpoint refuses the still-corrupt shared native cue")
		return
	_expect(not saved.is_empty() and saved.status == "cancelled" and saved.cycle == original.cycle and saved.exchange.id == original.exchange.id, label + " original canceled bank is a valid pure paused capture")
	if saved.is_empty(): return
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		_expect(float(saved.exchange[key]) == float(original.exchange[key]), label + " retains exact original " + key)
	var error: String = _bank.call("snapshot_error", saved, bindings, scheduler, player)
	_expect(error.is_empty(), label + " published complete saved-Player/staged-Scheduler bank preflight: " + error)
	if float(saved.exchange.cooldown_until_s) > float(scheduler.clock_s):
		var retained: bool = false
		for cooldown: Dictionary in scheduler.cooldowns:
			if cooldown.source_id == BANK_ID and float(cooldown.ready_s) == float(saved.exchange.cooldown_until_s): retained = true
		_expect(retained, label + " preserves the original unexpired admitted cooldown without refresh")
	var encoded: String = Exact.stringify({"player": player, "scheduler": scheduler, "bank": saved})
	var decoded: Dictionary = Exact.parse(encoded)
	_expect(not encoded.is_empty() and decoded.get("accepted", false) and Exact.stringify(decoded.value) == encoded, label + " canceled complete component transport preserves exact scalar bits")
	var pack: Dictionary = _level.snapshot_state()
	_expect(not pack.is_empty() and pack.local.banks[BANK_ID].status == "cancelled" and not pack.local.bank_views.has(BANK_ID) and _level.snapshot_error_with_player(pack, player).is_empty(), label + " whole actual canceled checkpoint is coherent and grants no replacement view")
