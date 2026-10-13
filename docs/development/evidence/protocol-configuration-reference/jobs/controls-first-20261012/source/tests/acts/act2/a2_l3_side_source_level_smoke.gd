extends "res://tests/acts/act2/a2_l3_live_level_smoke.gd"
## Actual full L3 fixture; only the optional phase2 side source uses this bot.
## Choose a dry right pocket outside Boss admission, counter the real bank's
## recovery with ordinary primary, and retreat before a new Boss activation.
## All other encounters retain inherited proof preemption unchanged.
## No live state assignment, damage injection, source/cue hiding or clock step.

const SidePlanner: Script = preload("res://tests/acts/act2/a2_l3_route_planner.gd")
const SideGeometry: Script = preload("res://scripts/combat/threat_geometry.gd")
const SideExact: Script = preload("res://scripts/campaign/exact_json.gd")
const SIDE_POCKET := Vector3(2.75, 0.0, -38.25)
const SIDE_BOSS_TOOLS: Array[String] = ["boss_reach", "boss_place"]
const SIDE_PRIMARY_INPUT_MARGIN: float = 0.10
var _side_export_path: String = ""
var _side_active: bool = false
var _side_broken: bool = false
var _side_hero_hp: float = 0.0
var _side_leases: Dictionary = {}
var _side_running_boss: Dictionary = {}
var _side_completed_boss: Dictionary = {}
var _side_first_diagnosis: bool = false

func _read_options() -> bool:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--export-boss-checkpoint="): _side_export_path = argument.trim_prefix("--export-boss-checkpoint=")
	return super._read_options() and _expect(_side_export_path.is_empty() or _side_export_path.begins_with("res://.cinder/"), "optional earned-checkpoint export stays in ignored local evidence")

func _advance_boss_phase(checkpoints: Array[String]) -> bool:
	if not await super._advance_boss_phase(checkpoints): return false
	if _side_export_path.is_empty(): return true
	# Capture after the complete supported Shell boundary, never inside its
	# checkpoint callback. No checkpoint fields or live resources are rebuilt.
	_game.request_pause()
	await _settle()
	if not _expect(paused and _game.campaign_error.is_empty() and _game.menu.page_name() == "pause" and not _game.player.dead, "real earned B02 checkpoint reaches a complete living pause barrier"): return false
	var payload: Dictionary = _game.attempts.state()
	var checkpoint: Dictionary = payload.story.checkpoint
	var current: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(not current.is_empty() and _game.attempts.state_error(payload).is_empty() and SideExact.stringify(current) == SideExact.stringify(payload.story.snapshot), "actual paused current unit and stored complete Attempts payload remain exact"): return false
	var boss: Dictionary = checkpoint.level.local.targets.handling_machine
	var sequence: Dictionary = checkpoint.level.local.sequence
	if not _expect(boss.actor.hp == 15.0 and boss.actor.max_hp == 30.0 and boss.boss_phase == 2 and not boss.transition_pending and not checkpoint.level.local.boss_phase_pending and sequence.stage_index == 7 and sequence.boss_phase == 2 and sequence.crossed_contacts == HOUSE_CONTACT_ORDER and sequence.defeated_ids.size() == 5 and checkpoint.level.progress.checkpoint_id == "handling-machine-phase-two" and checkpoint.level.progress.checkpoint_kind == "boss_phase" and not checkpoint.level.progress.completed and String(checkpoint.level.progress.contact_exit_id).is_empty() and not checkpoint.player.resources.dead, "export is the actual earned living15HP checkpoint with three contacts/five defeats and no completion/exit"): return false
	var hashes: Dictionary = {}
	for path: String in ["scripts/acts/act2/ruined_house.gd", "scripts/acts/act2/ruined_house_smoke_rules.gd", "scripts/acts/act2/ruined_house_bank_guard.gd", "scripts/acts/act2/handling_machine_boss_actor.gd", "scripts/combat/smoke_bank.gd", "scripts/combat/threat_scheduler.gd", "scripts/player.gd", "scripts/campaign/shell.gd", "tests/acts/act2/a2_l3_live_level_smoke.gd", "tests/acts/act2/a2_l3_side_source_level_smoke.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var exported: Dictionary = {"api_revision": "act2-earned-boss-checkpoint-1", "scope": "untouched complete payload and checkpoint earned through actual L3 contacts/ordinary phase1 primary; prior campaign prefix/unlocks only are TEST ONLY", "level_id": "A2-L3", "loadout": _loadout_name, "profile": _profile_id, "source_sha256": hashes, "boundary_records": _boundary_records.duplicate(true), "boss_hits": _boss_hits.duplicate(true), "checkpoint": checkpoint.duplicate(true), "attempts_payload": payload.duplicate(true)}
	var encoded: String = SideExact.stringify(exported)
	var file: FileAccess = FileAccess.open(_side_export_path, FileAccess.WRITE)
	if not _expect(not encoded.is_empty() and file != null, "save untouched original earned checkpoint/payload/provenance for focused fresh Retry"): return false
	file.store_string(encoded)
	file.close()
	if not _expect(FileAccess.get_file_as_string(_side_export_path) == encoded, "earned checkpoint export retains exact original bytes"): return false
	print("Actual earned B02 checkpoint export: ", _side_export_path, " SHA256=", FileAccess.get_sha256(_side_export_path))
	_game.resume_campaign()
	return _expect(not paused and _game.campaign_error.is_empty(), "same actual route resumes after the original checkpoint export")

func _clear(ids: Array[String]) -> bool:
	if ids != ["side_tender"]: return await super._clear(ids)
	_side_active = true
	_side_broken = false
	_side_first_diagnosis = false
	_side_leases.clear()
	_side_running_boss.clear()
	_side_completed_boss.clear()
	_side_hero_hp = _game.player.hp
	var result: bool = await _side_clear()
	_side_active = false
	return result

func _side_clear() -> bool:
	if not _expect(_state().beat == "boss_phase_two" and _actors.handling_machine.get("hp") == 15.0 and _actors.handling_machine.get("max_hp") == 30.0, "side-source strategy starts only after the real 15HP phase checkpoint"): return false
	_side_read_leases()
	if not await _side_move_to_pocket(): return false
	for attempt: int in range(8):
		if not _live() or _side_broken: return false
		if float(_actors.side_tender.get("hp")) <= 0.0: break
		var bank: Dictionary = await _side_recovery()
		if bank.is_empty(): return false
		var hero: CinderPlayer = _game.player
		var offset: Vector3 = _actors.side_tender.global_position - hero.global_position
		offset.y = 0.0
		var direction: Vector3 = offset.normalized()
		var attack: Vector3 = hero.global_position + direction * float(hero.stats.dash_distance)
		var plan: Array[Vector3] = SidePlanner.path(hero, _game.active_level, attack)
		if plan.size() != 1 or not _side_predicted_safe(hero.global_position, attack, float(hero.stats.dash_duration)):
			return _side_fail("inward full dash has no supported dry one-leg path")
		var now: float = float(_state().clock_s)
		var tick_margin: float = 2.0 / float(Engine.physics_ticks_per_second)
		var primary_ready: float = maxf(float(hero.get_threat_response_state().primary_cooldown_left_s), float(hero.stats.dash_duration) + SIDE_PRIMARY_INPUT_MARGIN + tick_margin)
		var primary_end: float = now + primary_ready + float(hero.stats.primary_cooldown) + tick_margin
		if primary_end > float(bank.exchange.recovery_until_s):
			return _side_fail("selected real recovery cannot fit the original full primary deadline")
		var original: Vector3 = hero.global_position
		if not await _side_dash(direction): return false
		var ready_after: float = float(_state().clock_s) + SIDE_PRIMARY_INPUT_MARGIN
		var ready: bool = false
		for frame: int in range(180):
			if not _live() or _side_broken: return false
			var response: Dictionary = hero.get_threat_response_state()
			if _stable() and float(response.primary_cooldown_left_s) <= 0.00001 and float(_state().clock_s) >= ready_after:
				ready = true
				break
			await _step()
		if not ready or not _side_same_recovery(bank): return _side_fail("native inward dash/primary readiness lost the original bank recovery")
		var current: Dictionary = _state().exchanges.side_tender
		var cue: Node3D = (_game.active_level.get("_opening_cues") as Dictionary).side_tender as Node3D
		var lease: Dictionary = _reservation(String(current.reservation_id))
		if lease.is_empty() or lease.state != "recovery" or lease.source_instance_id != _banks.boss_bank.get_instance_id() or lease.opening_position != _actors.side_tender.global_position or float(_state().clock_s) <= float(lease.active_until_s) or float(_state().clock_s) + float(hero.stats.primary_cooldown) > float(lease.recovery_until_s) or _actors.side_tender.get("phase") != "recovery" or not is_instance_valid(cue) or not cue.is_visible_in_tree() or cue.call("state").state != "available" or not level_actor_framed("side_tender"):
			return _side_fail("ordinary side damage window/cue/current native framing is unavailable")
		if _actors.handling_machine.get("phase") == "recovery": return _side_fail("Boss ordinary damage window remains open during side counter")
		var retreat_span: float = maxf(float(hero.get_threat_response_state().dash_cooldown_left_s), float(hero.get_threat_response_state().primary_commitment_s)) + float(hero.stats.dash_duration) + tick_margin
		if not _side_retreat_deadline(float(_state().clock_s) + maxf(retreat_span, float(hero.stats.primary_cooldown))): return false
		var hp_before: float = float(_actors.side_tender.get("hp"))
		var primary_direction: Vector3 = _actors.side_tender.global_position - hero.global_position
		primary_direction.y = 0.0
		if primary_direction.length() > float(hero.stats.primary_range): return _side_fail("real landing misses canonical ordinary-primary reach")
		var hits: int = hero.slash(primary_direction.normalized())
		if not _expect(hits > 0 and float(_actors.side_tender.get("hp")) < hp_before and _actors.handling_machine.get("hp") == 15.0 and hero.hp == _side_hero_hp, "actual side primary damages only its recovering source and preserves Boss 15/actual HeroHP"): return _side_fail("ordinary side primary was rejected or caused collateral")
		for frame: int in range(180):
			if not _live() or _side_broken: return false
			var response: Dictionary = hero.get_threat_response_state()
			if _stable() and float(response.dash_cooldown_left_s) <= 0.00001: break
			if not _side_retreat_deadline(float(_state().clock_s) + maxf(float(response.dash_cooldown_left_s), float(response.commitment_remaining_s)) + float(hero.stats.dash_duration) + tick_margin): return false
			await _step()
		if not _stable() or float(hero.get_threat_response_state().dash_cooldown_left_s) > 0.00001: return _side_fail("ordinary primary did not settle before the full retreat")
		if not _side_retreat_deadline(float(_state().clock_s) + float(hero.stats.dash_duration) + tick_margin): return false
		var return_direction: Vector3 = original - hero.global_position
		return_direction.y = 0.0
		if not await _side_dash(return_direction.normalized()) or not await _side_move_to_pocket(): return false
		print("Actual side counter: attempt=", attempt + 1, " bank_cycle=", bank.cycle, " TenderHP=", _actors.side_tender.get("hp"), " BossHP=", _actors.handling_machine.get("hp"), " real_pocket=", hero.global_position)
	if not _expect(float(_actors.side_tender.get("hp")) == 0.0 and _actors.handling_machine.get("hp") == 15.0 and _game.player.hp == _side_hero_hp and _source_seen("side_tender"), "bounded actual side counters finish its HP/native phases while retaining Boss 15 and untouched HeroHP"): return _side_fail("bounded dry-pocket counters did not clear the optional source")
	for frame: int in range(4): await _step()
	return not _side_broken

func _side_move_to_pocket() -> bool:
	for attempt: int in range(12):
		if not _live() or _side_broken: return false
		if not await _side_move_ready(): return false
		var hero: CinderPlayer = _game.player
		var target := Vector3(SIDE_POCKET.x, hero.global_position.y, SIDE_POCKET.z)
		if Vector2(hero.global_position.x - target.x, hero.global_position.z - target.z).length() <= 0.10:
			return _expect(hero.global_position.distance_to(_actors.handling_machine.global_position) > 3.8 and hero.global_position.distance_to(_actors.side_tender.global_position) <= 3.8 and SidePlanner.leg_clear(hero, _game.active_level, hero.global_position, hero.global_position), "actual supported right pocket excludes Boss admission while retaining Tender range")
		var offset: Vector3 = target - hero.global_position
		var goal: Vector3 = target
		if offset.length() > 2.0 * float(hero.stats.dash_distance): goal = hero.global_position + offset.normalized() * float(hero.stats.dash_distance)
		var waypoints: Array[Vector3] = SidePlanner.path(hero, _game.active_level, goal)
		if waypoints.is_empty(): return _side_fail("pure full-distance planner cannot reach the right pocket")
		var direction: Vector3 = waypoints[0] - hero.global_position
		direction.y = 0.0
		if direction.length() < 0.00001: return _side_fail("pocket planner returned a zero movement outside pocket")
		if not await _side_dash(direction.normalized()): return false
	return _side_fail("bounded real equal-length dashes did not settle in the right pocket")

func _side_recovery() -> Dictionary:
	for frame: int in range(1200):
		if not _live() or _side_broken: return {}
		var outside: bool = _game.player.global_position.distance_to(_actors.handling_machine.global_position) > 3.8
		if not outside or not SidePlanner.leg_clear(_game.player, _game.active_level, _game.player.global_position, _game.player.global_position):
			_side_fail("actual waiting pocket no longer supports the Hero outside Boss admission"); return {}
		_side_read_leases()
		if _side_broken: return {}
		var finished: bool = true
		for id: String in SIDE_BOSS_TOOLS:
			if (_game.active_level.get("_mechanisms")[id] as Node).call("state").status == "running": finished = false
		var bank: Dictionary = _state().exchanges.side_tender
		if finished and bank.status == "running" and bank.phase == "recovery" and _stable() and float(_game.player.get_threat_response_state().dash_cooldown_left_s) <= 0.00001:
			var lease: Dictionary = _reservation(String(bank.reservation_id))
			var hero: CinderPlayer = _game.player
			var tick_margin: float = 2.0 / float(Engine.physics_ticks_per_second)
			var ready: float = maxf(float(hero.get_threat_response_state().primary_cooldown_left_s), float(hero.stats.dash_duration) + SIDE_PRIMARY_INPUT_MARGIN + tick_margin)
			var primary_end: float = float(_state().clock_s) + ready + float(hero.stats.primary_cooldown) + tick_margin
			if not lease.is_empty() and lease.armed and lease.state == "recovery" and primary_end <= float(lease.recovery_until_s):
				if not _expect(Codec.same_values(bank.resolved_role, _expected_roles.bank) and is_equal_approx(float(lease.active_from_s) - float(lease.lock_from_s), float(_expected_roles.bank.lock_s)), "real side bank retains published role/full resolved lock before dry counter"): return {}
				if not _expect(_side_running_boss.is_empty(), "every observed Boss mechanism finished its original lease at the outside pocket"): return {}
				return bank.duplicate(true)
		await _step()
	_side_fail("real bank recovery/native Boss lease completion was unavailable at the pocket")
	return {}

func _side_move_ready() -> bool:
	for frame: int in range(180):
		if not _live() or _side_broken: return false
		if _stable() and float(_game.player.get_threat_response_state().dash_cooldown_left_s) <= 0.00001: return true
		await _step()
	return _side_fail("native stable dash/cooldown readiness did not arrive")

func _side_same_recovery(original: Dictionary) -> bool:
	var current: Dictionary = _state().exchanges.side_tender
	return current.status == "running" and current.phase == "recovery" and current.cycle == original.cycle and current.reservation_id == original.reservation_id and Codec.same_values(current.exchange, original.exchange)

func _side_retreat_deadline(response_until: float) -> bool:
	for id: String in SIDE_BOSS_TOOLS:
		var current: Dictionary = (_game.active_level.get("_mechanisms")[id] as Node).call("state")
		if current.status != "running": continue
		var lease: Dictionary = _reservation(String(current.reservation_id))
		if lease.is_empty() or not lease.armed or float(lease.active_from_s) <= response_until:
			return _side_fail("actual incoming Boss activation does not cover full ordinary-primary/retreat response")
	return true

func _side_dash(direction: Vector3) -> bool:
	if not await _side_move_ready(): return false
	var hero: CinderPlayer = _game.player
	var finish: Vector3 = hero.global_position + direction * float(hero.stats.dash_distance)
	if not SidePlanner.leg_clear(hero, _game.active_level, hero.global_position, finish) or not _side_predicted_safe(hero.global_position, finish, float(hero.stats.dash_duration)): return _side_fail("next real full dash intersects scenery or an admitted active footprint")
	var clock_offset: float = float(_state().clock_s) - hero.get_world_action_clock()
	if not await _dash(direction): return false
	var action: Dictionary = _last_dash()
	var samples: Array = action.path
	var segments: Array[Dictionary] = []
	for index: int in range(1, samples.size()):
		segments.append({"from": samples[index - 1].position, "to": samples[index].position, "start_s": float(samples[index - 1].time_s) + clock_offset, "end_s": float(samples[index].time_s) + clock_offset})
	if not _side_safe(segments) or not SidePlanner.leg_clear(hero, _game.active_level, action.landing, action.landing) or not action.landing.is_equal_approx(hero.global_position) or not is_equal_approx(float(_state().clock_s) - hero.get_world_action_clock(), clock_offset): return _side_fail("actual completed native dash samples/landing fail supported timed-geometry check")
	return _expect(not _side_broken and hero.hp == _side_hero_hp, "every actual completed dry dash retains native samples/supported landing and unchanged HeroHP")

func _side_predicted_safe(start: Vector3, finish: Vector3, duration: float) -> bool:
	_side_read_leases()
	var now: float = float(_state().clock_s)
	var segments: Array[Dictionary] = [{"from": start, "to": finish, "start_s": now, "end_s": now + duration}]
	return not _side_broken and _side_safe(segments)

func _side_safe(segments: Array[Dictionary]) -> bool:
	for lease: Dictionary in _side_leases.values():
		# These are actual admitted immutable geometry/windows, not decorative
		# art meshes or an invented proof. Every native sampled segment is tested.
		if SideGeometry.timed_path_hits(lease.geometry, segments, float(lease.active_from_s), float(lease.active_until_s), CinderThreatScheduler.CAPSULE_RADIUS): return false
	return true

func _side_read_leases() -> void:
	if not _side_active or not _live(): return
	var consumers: Array[Node] = [_banks.boss_bank]
	var now: float = float(_state().clock_s)
	for id: String in SIDE_BOSS_TOOLS:
		var tool: Node = _game.active_level.get("_mechanisms")[id] as Node
		var current: Dictionary = tool.call("state")
		if _side_running_boss.has(id):
			var original: Dictionary = _side_running_boss[id]
			if current.status != "running":
				if current.status != "complete" or current.cycle != original.cycle or now <= float(original.recovery_until_s):
					_side_fail("observed Boss mechanism cancelled or discarded its original recovery"); return
				_side_completed_boss[id] = int(current.cycle)
				_side_running_boss.erase(id)
			elif current.cycle != original.cycle or current.reservation_id != original.reservation_id:
				_side_fail("Boss mechanism replaced an unfinished original lease"); return
		if current.status == "running" and not _side_running_boss.has(id):
			var admitted: Dictionary = _reservation(String(current.reservation_id))
			if admitted.is_empty():
				_side_fail("actual running Boss mechanism omitted its native lease"); return
			_side_running_boss[id] = {"cycle": current.cycle, "reservation_id": current.reservation_id, "recovery_until_s": admitted.recovery_until_s}
		consumers.append(tool)
	for consumer: Node in consumers:
		var current: Dictionary = consumer.call("state")
		if current.status != "running": continue
		var lease: Dictionary = _reservation(String(current.reservation_id))
		if lease.is_empty() or not lease.armed or not SideGeometry.error(lease.geometry).is_empty():
			_side_fail("running side consumer has no actual supported armed lease"); return
		if _side_leases.has(lease.id):
			var original: Dictionary = _side_leases[lease.id]
			if not Codec.same_values(original.geometry, lease.geometry) or original.active_from_s != lease.active_from_s or original.active_until_s != lease.active_until_s:
				_side_fail("same native lease changed its original timed geometry"); return
		else: _side_leases[lease.id] = lease.duplicate(true)

func _step() -> void:
	var start: Vector3 = _game.player.global_position if _side_active and _live() else Vector3.ZERO
	var clock: float = float(_state().clock_s) if _side_active and _live() else 0.0
	await super._step()
	if not _side_active or not _live() or _side_broken: return
	_side_read_leases()
	var until: float = float(_state().clock_s)
	if until > clock:
		var segments: Array[Dictionary] = [{"from": start, "to": _game.player.global_position, "start_s": clock, "end_s": until}]
		if not _side_safe(segments): _side_fail("actual native wait/dash segment intersects an admitted active footprint")
	if _game.player.hp != _side_hero_hp: _side_fail("actual HeroHP changed along the chosen dry side path")

func _side_fail(reason: String) -> bool:
	_side_broken = true
	if not _side_first_diagnosis:
		_side_first_diagnosis = true
		var state: Dictionary = _state()
		var boss_states: Dictionary = {}
		for id: String in SIDE_BOSS_TOOLS:
			var current: Dictionary = (_game.active_level.get("_mechanisms")[id] as Node).call("state")
			var lease: Dictionary = _reservation(String(current.reservation_id))
			boss_states[id] = {"status": current.status, "phase": current.phase, "cycle": current.cycle, "reservation_id": current.reservation_id, "cancel": current.last_cancel_reason, "active_from_s": lease.get("active_from_s"), "recovery_until_s": lease.get("recovery_until_s")}
		var bank: Dictionary = state.get("exchanges", {}).get("side_tender", {})
		var response: Dictionary = _game.player.get_threat_response_state()
		var errors: Dictionary = {}
		for id: String in state.get("admission_errors", {}).keys().slice(-3): errors[id] = state.admission_errors[id]
		print("First actual side-source diagnosis: ", {"reason": reason, "clock_s": state.get("clock_s"), "Hero": _game.player.global_position, "HeroHP": _game.player.hp, "stable": response.get("stable"), "commitment_s": response.get("commitment_remaining_s"), "dash_cd_s": response.get("dash_cooldown_left_s"), "primary_cd_s": response.get("primary_cooldown_left_s"), "TenderHP": _actors.side_tender.get("hp"), "bank": {"status": bank.get("status"), "phase": bank.get("phase"), "cycle": bank.get("cycle"), "reservation_id": bank.get("reservation_id"), "cancel": bank.get("last_cancel_reason"), "recovery_until_s": bank.get("exchange", {}).get("recovery_until_s")}, "BossHP": _actors.handling_machine.get("hp"), "Boss": boss_states, "naturally_complete_boss_cycles": _side_completed_boss, "admission_errors": errors})
	return _expect(false, reason)
