extends "res://tests/acts/act3/pillars_before_time_focused.gd"
## TEMP ONLY final O3 derivative; unparsed/unexecuted. Registered prototype
## stays frozen. Reuses only accepted observer/exact/disposal helpers.
## First court proves actual generation1→2/ordinary death/CP1. Optional jobs
## reuse EchoDriver with genuine CP archives for later changed courts/exit.

const O3_ROOM: String = "res://scenes/acts/act3/a3_o3_irontick_reflection.tscn"
const ECHO_IDS: Array[String] = ["o3-first-echo","o3-rearranged-echo","o3-final-echo"]
const STALKER_ID: String = "o3-final-stalker"
const STAGE_IDS: Array[String] = ["first-reflection","rearranged-endpoint","final-resonant-apron"]
const CHECKPOINT_IDS: Array[String] = ["first-reflection-cleared","rearranged-endpoint-cleared"]

class EchoDriver extends RefCounted:
	## No Shell model, pause, archive, source preparation or runtime state edits.
	## tick/presentation callbacks await actual native completed boundaries;
	## Optional's tick callback also drains its real CP/complete pause operations.
	const BodySweep = preload("res://scripts/combat/body_sweep.gd")
	const EchoIds: Array[String] = ["o3-first-echo","o3-rearranged-echo","o3-final-echo"]
	const StageIds: Array[String] = ["first-reflection","rearranged-endpoint","final-resonant-apron"]
	const CheckpointIds: Array[String] = ["first-reflection-cleared","rearranged-endpoint-cleared"]
	const PointEps: float = 0.005
	const TimeEps: float = 0.000001
	const Deadlines: Array[String] = ["start_s","lock_from_s","active_from_s","active_until_s","recovery_until_s","cooldown_until_s"]
	const DashKinds: Array[String] = ["escape_dash","first_escape_dash","positioning_dash","tether_positioning_dash"]
	var _hero: CinderPlayer
	var _level: CinderLevel
	var _scheduler: CinderThreatScheduler
	var _source: Node3D
	var _source_id: String
	var _stage_index: int = -1
	var _kit: Dictionary
	var _stats: Dictionary
	var _starting_hp: float
	var _starting_ammo: int
	var _starting_clock: float
	var _starting_blasts: int
	var _fixed: Transform3D
	var _source_instance: int
	var _ticks: int = 0
	var _actions: Callable
	var _fired: Callable
	var _native_tick: Callable
	var _presentation: Callable
	var _assert: Callable
	var _boundary: Dictionary = {}
	var _held_lease: Dictionary = {}

	func configure(actual_hero: CinderPlayer, actual_level: CinderLevel, actual_scheduler: CinderThreatScheduler, source_id: String, held_kit: Dictionary, action_records: Callable, fired_kinds: Callable, tick_callback: Callable, presentation_callback: Callable, assertion_callback: Callable) -> void:
		_hero = actual_hero
		_level = actual_level
		_scheduler = actual_scheduler
		_source_id = source_id
		_stage_index = EchoIds.find(source_id)
		_source = (actual_level.get("sources") as Dictionary).get(source_id) as Node3D
		_kit = held_kit.duplicate(true)
		_stats = actual_hero.equipment.resolved_stats().duplicate(true)
		_starting_hp = actual_hero.hp
		_starting_ammo = actual_hero.shells
		_starting_clock = actual_scheduler.get_clock()
		_actions = action_records
		_fired = fired_kinds
		_native_tick = tick_callback
		_presentation = presentation_callback
		_assert = assertion_callback
		_starting_blasts = (fired_kinds.call() as Array).count("blast")
		_fixed = _source.global_transform if is_instance_valid(_source) else Transform3D.IDENTITY
		_source_instance = _source.get_instance_id() if is_instance_valid(_source) else 0

	func _expect(ok: bool, label: String, detail: String = "") -> bool:
		return bool(_assert.call(ok,label,detail))

	func _tick() -> bool:
		if not bool(await _native_tick.call()): return false
		_ticks += 1
		if not _held_lease.is_empty():
			var held: Dictionary = _scheduler.replay_reservation_state(String(_held_lease.id))
			for key: String in Deadlines:
				if not _expect(not held.is_empty() and _same(held[key],_held_lease[key]),"actual held own replay retains original native "+key): return false
			for opportunity: Dictionary in (_source.call("state") as Dictionary).get("opportunities",[]):
				if not _expect(not opportunity.contact and not opportunity.damage_attempted,"actual selected response consumes no contact hidden by dash immunity"): return false
		return _expect(_ticks <= 1800 and _scheduler.get_clock()-_starting_clock <= 30.0 and _level.hero == _hero and _hero.hp == _starting_hp and not _hero.dead and _hero.shells == _starting_ammo and _same(_hero.equipment.snapshot(),_kit) and _same(_hero.equipment.resolved_stats(),_stats) and is_instance_valid(_source) and _source.get_instance_id() == _source_instance and _source.global_transform == _fixed and String(_source.call("source_native_error")).is_empty() and (_fired.call() as Array).count("blast") == _starting_blasts, "bounded native Echo driver preserves actual recipient/fixed knot/HP/ammo/kit and ordinary-only controls",str(describe()))

	func describe() -> Dictionary:
		return {"source_id":_source_id,"stage_index":_stage_index,"clock_s":_scheduler.get_clock() if is_instance_valid(_scheduler) else -1.0,"driver_ticks":_ticks,"phase":_source.call("source_phase") if is_instance_valid(_source) else "<missing>","generation":_source.call("get_authored_cycle_generation") if is_instance_valid(_source) else -1,"hp":_source.get("hp") if is_instance_valid(_source) else -1.0,"actions":(_actions.call() as Array).size()}

	func last_boundary() -> Dictionary:
		return _boundary.duplicate(true)

	func clear_current_stage(require_generation_two: bool = false) -> bool:
		var state: Dictionary = _level.call("state")
		if not _expect(_stage_index >= 0 and state.route.active_stage == _stage_index and is_instance_valid(_source) and _source.call("source_cycles_managed") and not _source.get("dead") and _source.get("hp") == 36.0 and _source.call("get_authored_cycle_generation") == 1, "driver observes the genuinely current living native36HP stage source before any approach",str(state)): return false
		print("O3 DRIVER: current ",_source_id,"; ",describe())
		if (await _warning()).is_empty(): return false
		if not await _follow_warning_to_primary(): return false
		var first_hits: Array = _source.call("source_hit_receipts")
		if not _expect(_source.get("hp") == maxf(0.0,36.0-float(_stats.primary_damage)) and _source.get("source_hits") == 1 and first_hits.size() == 1 and first_hits[0].generation == 1 and not _source.get("dead"), "first ordinary recovery hit preserves actual generation1 partial HP/history"): return false
		if require_generation_two:
			if not await _generation_two(first_hits): return false
			if (await _warning()).is_empty(): return false
			if not await _follow_warning_to_primary(): return false
		else:
			# Native recovery/complete is a legitimate ordinary window. Respect
			# real cooldown; if the parent already rearmed, follow its new proof.
			var hit: bool = false
			for _index: int in range(600):
				var phase: String = String(_source.call("source_phase"))
				if phase in ["recovery","complete"] and float(_hero.get_threat_response_state().primary_cooldown_left_s) == 0.0:
					hit = _primary()
					break
				if (_source.call("state") as Dictionary).status == "running" and phase == "warning":
					hit = await _follow_warning_to_primary()
					break
				if not await _tick(): return false
			if not _expect(hit,"bounded later-stage ordinary follow-up executes through an actual native opening"): return false
		var hits: Array = _source.call("source_hit_receipts")
		if not _expect(_source.get("dead") and _source.get("hp") == 0.0 and _source.get("source_hits") == 2 and hits.size() == 2 and _same(hits[0],first_hits[0]) and hits[1].generation == (2 if require_generation_two else int(_source.call("get_authored_cycle_generation"))) and not _source.is_in_group("enemies"), "two genuine ordinary transactions retire the same real endpoint without HP/history reset",str(describe())): return false
		return await await_boundary(_stage_index+1)

	func _generation_two(first_hits: Array) -> bool:
		var first_terminal: Dictionary = {}
		for _index: int in range(900):
			var playback: Dictionary = _source.call("state")
			var receipts: Array = playback.lifecycle.terminal_receipts
			if first_terminal.is_empty() and not receipts.is_empty():
				first_terminal = receipts[0].duplicate(true)
				if not _expect(first_terminal.generation == 1 and first_terminal.outcome == "complete", "native first generation seals its true complete terminal before rearm",str(first_terminal)): return false
			if int(_source.call("get_authored_cycle_generation")) == 2:
				return _expect(not first_terminal.is_empty() and receipts.size() == 1 and _same(receipts[0],first_terminal) and _same(_source.call("source_hit_receipts"),first_hits) and _source.get("hp") == maxf(0.0,36.0-float(_stats.primary_damage)) and not _source.get("dead") and _source.get_instance_id() == _source_instance and playback.status in ["cycle_ready","running"], "actual parent prepares generation2 only after native terminal/cooldown, retaining source/HP/hit/terminal history",str(describe()))
			if not _expect(not _source.get("dead") and int(_source.call("get_authored_cycle_generation")) == 1 and _same(_source.call("source_hit_receipts"),first_hits), "waiting for real rearm fabricates no source generation/death/hit"): return false
			if not await _tick(): return false
		return _expect(false,"bounded actual parent generation1→2 rearm",str(describe()))

	func _warning() -> Dictionary:
		var approaches: int = 0
		for index: int in range(600):
			# Observe newly current and newly admitted sources before approaching.
			var playback: Dictionary = _source.call("state")
			if playback.status == "running":
				var lease: Dictionary = _scheduler.replay_reservation_state(String(playback.reservation_id))
				if _expect(not lease.is_empty() and not lease.adapter.locked and not playback.cursor.armed and _source.call("source_phase") == "warning" and _scheduler.get_clock() < float(lease.lock_from_s), "new real source admission is observed during its own unarmed warning",str(describe())): return lease
				return {}
			if not _expect(playback.status == "cycle_ready", "actual selected source remains ready until native admission",str(describe())): return {}
			if not _hero.is_on_floor() or not _hero.get_threat_response_state().get("stable",false):
				if not await _tick(): return {}
				continue
			if index > 0 and index%16 == 0 and float(_hero.get_threat_response_state().dash_cooldown_left_s) == 0.0 and _hero.global_position.distance_to(_source.global_position) > float(_stats.primary_range):
				if not _expect(approaches < 4,"bounded fixed-stone approach uses at most four actual dashes",str(describe())): return {}
				if not await approach(): return {}
				approaches += 1
			else:
				if not await _tick(): return {}
		return {}

	func approach() -> bool:
		if not _expect(_hero.is_on_floor() and _hero.get_threat_response_state().get("stable",false) and (_source.call("state") as Dictionary).status == "cycle_ready", "actual floor/current-source observation precedes approach preflight"): return false
		var from: Transform3D = _hero.global_transform
		var toward: Vector3 = _source.global_position-from.origin
		toward.y = 0.0
		if not _expect(not toward.is_zero_approx(),"actual fixed endpoint provides a nonzero approach bearing"): return false
		var distance: float = float(_stats.dash_distance)
		var floors: Array = (_level.call("scheduler_bindings") as Dictionary).floors.values()
		var direct: Dictionary = BodySweep.sweep(_hero,from,toward.normalized()*distance,floors)
		if _full_sweep(direct,from.origin+toward.normalized()*distance): return await _dash(toward.normalized())
		for side: Vector3 in [Vector3.RIGHT,Vector3.LEFT]:
			var lateral: Dictionary = BodySweep.sweep(_hero,from,side*distance,floors)
			if not _full_sweep(lateral,from.origin+side*distance): continue
			var next_from: Transform3D = from
			next_from.origin = lateral.end # Pure virtual sweep input, never Hero pose.
			var next_toward: Vector3 = _source.global_position-next_from.origin
			next_toward.y = 0.0
			if next_toward.is_zero_approx(): continue
			var next: Dictionary = BodySweep.sweep(_hero,next_from,next_toward.normalized()*distance,floors)
			if not _full_sweep(next,next_from.origin+next_toward.normalized()*distance): continue
			print("O3 DRIVER: fixed stone blocks direct full dash; actual lateral ",side,"; source=",_source_id)
			return await _dash(side)
		return _expect(false,"actual body/floor supports a full direct or fixed-stone lateral approach",str(direct))

	func _follow_warning_to_primary() -> bool:
		var lease: Dictionary = {}
		var proof: Dictionary = {}
		for _index: int in range(240):
			var state: Dictionary = _level.call("state")
			var data: Dictionary = state.echo_records[_source_id]
			if data.locked:
				lease = _scheduler.replay_reservation_state(String((_source.call("state") as Dictionary).reservation_id))
				proof = data.proof
				break
			if not _expect((_source.call("state") as Dictionary).status == "running", "actual admitted warning retains its original native lease until due lock"): return false
			if not await _tick(): return false
		if not _expect(not lease.is_empty() and lease.adapter.locked and proof.get("accepted",false) and proof.get("uses_blast") == false and proof.get("uses_invulnerability") == false and proof.get("path") is Array and not proof.path.is_empty() and proof.path.size() <= 10, "actual due lock supplies a finite ordinary-only current stage/stone/danger-union proof",str(describe())): return false
		_held_lease = lease.duplicate(true)
		var first: bool = true
		var escaped: bool = false
		var last_end: float = -1.0
		var previous: Dictionary = {}
		for segment: Dictionary in proof.path:
			if not _expect(segment.get("from") is Vector3 and segment.get("to") is Vector3 and segment.from.is_finite() and segment.to.is_finite() and is_finite(float(segment.start_s)) and is_finite(float(segment.end_s)) and float(segment.end_s) >= float(segment.start_s), "actual own-route witness retains finite physical positions/deadlines"): return false
			if not previous.is_empty() and not _expect(absf(float(previous.end_s)-float(segment.start_s)) <= TimeEps and previous.to.distance_to(segment.from) <= PointEps,"actual selected own-route path remains continuous"): return false
			previous = segment
			var scheduled: float = maxf(float(segment.start_s),last_end)
			if first and segment.kind == "recognition_and_ready":
				if not _expect(segment.from == segment.to and _hero.global_position.distance_to(segment.from) <= PointEps and _scheduler.get_clock() < float(segment.end_s), "only unchanged first passive recognition may be joined before its original end"): return false
				scheduled = maxf(scheduled,_scheduler.get_clock())
			first = false
			if segment.kind in ["ordinary_primary","ordinary_primary_full_recovery"]: break
			if DashKinds.has(String(segment.kind)):
				if not await _until(scheduled): return false
				if not await _dash((segment.to-segment.from).normalized(),segment,scheduled,lease): return false
				last_end = float((_actions.call() as Array).back().completed_at_s)
				escaped = escaped or segment.kind in ["escape_dash","first_escape_dash"]
			else:
				if not _expect(segment.from == segment.to and _hero.global_position.distance_to(segment.from) <= PointEps, "actual passive segment preserves its native stationary point"): return false
				if not await _until(float(segment.end_s),segment.from): return false
		if not await _until(float(proof.primary_time_s)): return false
		if not _expect(escaped and _source.call("source_phase") == "recovery" and _hero.global_position.distance_to(proof.attack_position) <= PointEps and _hero.is_on_floor() and float(proof.response_complete_s) < float(lease.recovery_until_s), "full actual selected response reaches its ordinary native recovery opening"): return false
		var hit: bool = _primary()
		_held_lease.clear()
		return hit

	func _primary() -> bool:
		var before: float = float(_source.get("hp"))
		var count: int = (_actions.call() as Array).size()
		var hits_before: int = int(_source.get("source_hits"))
		var generation: int = int(_source.call("get_authored_cycle_generation"))
		var phase: String = String(_source.call("source_phase"))
		if not _expect(phase in ["recovery","complete"] and float(_hero.get_threat_response_state().primary_cooldown_left_s) == 0.0 and _hero.is_on_floor(), "actual ordinary primary respects native phase/cooldown/floor"): return false
		var toward: Vector3 = _source.global_position-_hero.global_position
		toward.y = 0.0
		var hits: int = _hero.slash(toward.normalized())
		var actions: Array = _actions.call()
		var receipts: Array = _source.call("source_hit_receipts")
		var damage: float = float(_stats.primary_damage)
		return _expect(hits >= 1 and actions.size() == count+1 and actions.back().kind == "primary" and actions.back().hits == hits and actions.back().damage == damage and _source.get("hp") == maxf(0.0,before-damage) and int(_source.get("source_hits")) == hits_before+1 and receipts.size() == hits_before+1 and receipts.back().generation == generation and receipts.back().phase == phase and receipts.back().hp_before == before and receipts.back().hp_after == maxf(0.0,before-damage) and receipts.back().hp_damage == minf(before,damage), "one actual controller primary reaches the real target through a genuine native hit receipt",str(describe()))

	func _dash(direction: Vector3, segment: Dictionary = {}, scheduled: float = -1.0, lease: Dictionary = {}) -> bool:
		direction.y = 0.0
		direction = direction.normalized()
		var response: Dictionary = _hero.get_threat_response_state()
		var from: Vector3 = _hero.global_position
		var distance: float = float(_stats.dash_distance)
		var sweep: Dictionary = BodySweep.sweep(_hero,_hero.global_transform,direction*distance,(_level.call("scheduler_bindings") as Dictionary).floors.values())
		if not _expect(_hero.is_on_floor() and response.stable and float(response.dash_cooldown_left_s) == 0.0 and response.motion.queued_dash == Vector3.ZERO and not direction.is_zero_approx() and _full_sweep(sweep,from+direction*distance) and (segment.is_empty() or from.distance_to(segment.from) <= PointEps), "actual grounded capsule/full-floor sweep supports the whole unbuffered ordinary dash",str(sweep)): return false
		var count: int = (_actions.call() as Array).size()
		var requested: float = _hero.get_world_action_clock()
		if not _expect(_hero.request_dash(direction), "public controller accepts full actual stage response/approach dash"): return false
		for _index: int in range(60):
			if not await _tick(): return false
			var actions: Array = _actions.call()
			if actions.size() <= count: continue
			var action: Dictionary = actions.back()
			var start: float = float(action.started_at_s)
			var finish: float = float(action.completed_at_s)
			var duration: float = float(ceili(float(_stats.dash_duration)/_tick_s()))*_tick_s()
			var safe: bool = true
			if not segment.is_empty(): safe = finish < float(lease.active_from_s) if segment.kind in ["escape_dash","first_escape_dash"] else start >= float(lease.active_until_s) and finish < float(lease.recovery_until_s)
			return _expect(actions.size() == count+1 and action.kind == "dash" and not action.blocked and not action.collision_shortened and not action.movement_damage and action.world_origin == from and action.landing == _hero.global_position and action.landing.distance_to(from+direction*distance) <= PointEps and absf(float(action.distance)-distance) <= PointEps and _hero.is_on_floor() and _same(action.equipment_ids,_kit) and _same(action.resolved_stats,_stats) and not CinderPlayer.encode_world_action_record(action,_hero.get_world_action_clock()).is_empty() and _same(start,requested) and absf(finish-start-duration) <= TimeEps and absf(_scheduler.get_clock()-finish) <= TimeEps and (segment.is_empty() or (action.landing.distance_to(segment.to) <= PointEps and start >= scheduled-TimeEps and start <= scheduled+_tick_s()+TimeEps and safe)), "actual dash separately bounds request tick/native duration and preserves full fixed-stone landing/safe deadline",str({"source":_source_id,"scheduled":scheduled,"request":requested,"start":start,"finish":finish,"native_duration":duration,"safe":safe}))
		return _expect(false,"bounded actual native dash completion")

	func _until(target: float, held: Variant = null) -> bool:
		if not _expect(is_finite(target),"finite actual witness deadline"): return false
		for _index: int in range(600):
			if held is Vector3 and not _expect(_hero.global_position.distance_to(held) <= PointEps,"actual passive proof position stays unchanged"): return false
			if _scheduler.get_clock() >= target: return _expect(_scheduler.get_clock() <= target+_tick_s()+TimeEps,"actual action follows its first available native proof tick")
			if not await _tick(): return false
		return _expect(false,"bounded native proof deadline")

	func await_boundary(expected_stage: int) -> bool:
		for _index: int in range(120):
			var state: Dictionary = _level.call("state")
			if int(state.route.active_stage) == expected_stage:
				var checkpoint: Dictionary = _level.current_checkpoint()
				var coherent: bool = state.route.deaths.has(_source_id) and _source.get("dead") and _source.get("hp") == 0.0 and not _source.is_in_group("enemies") and state.route.clears.size() == expected_stage
				if expected_stage < StageIds.size():
					var next: Node3D = (_level.get("sources") as Dictionary)[EchoIds[expected_stage]]
					coherent = coherent and checkpoint.id == CheckpointIds[expected_stage-1] and checkpoint.kind == "encounter" and not _level.is_completed() and not next.get("dead") and next.get("hp") == 36.0 and next.call("get_authored_cycle_generation") == 1 and (next.call("state") as Dictionary).status in ["cycle_ready","running"]
				else:
					var stalker: Node3D = (_level.get("sources") as Dictionary)["o3-final-stalker"]
					coherent = coherent and checkpoint.id == CheckpointIds[1] and _level.is_completed() and not stalker.get("dead") and float(stalker.get("hp")) > 0.0 and stalker.is_in_group("enemies")
				_boundary = {"clock_s":_scheduler.get_clock(),"state":state.duplicate(true),"checkpoint":checkpoint.duplicate(true)}
				if not _expect(coherent,"genuine source retirement produces coherent next-stage CP1/CP2 or third completion without a kill-all gate",str(_boundary)): return false
				return bool(await _presentation.call())
			if not await _tick(): return false
		return _expect(false,"bounded actual authored stage boundary",str(describe()))

	func _full_sweep(sweep: Dictionary, endpoint: Vector3) -> bool:
		return not sweep.has("error") and not sweep.get("collided",true) and sweep.get("end") is Vector3 and sweep.end.distance_to(endpoint) <= PointEps

	func _tick_s() -> float:
		return 1.0/float(Engine.physics_ticks_per_second)

	func _same(a: Variant, b: Variant) -> bool:
		if typeof(a) != typeof(b): return false
		if a is float: return var_to_bytes(a) == var_to_bytes(b)
		if a is Dictionary:
			if a.size() != b.size(): return false
			for key: Variant in a:
				if not b.has(key) or not _same(a[key],b[key]): return false
			return true
		if a is Array:
			if a.size() != b.size(): return false
			for index: int in range(a.size()):
				if not _same(a[index],b[index]): return false
			return true
		return a == b


var _driver: EchoDriver
var _hp: float
var _ammo: int
var _fired: Array[String] = []
var _stage: String = "initializing final first-court fixture"

func _run() -> void:
	create_timer(600.0,true,false,true).timeout.connect(_watchdog)
	if _expect(OS.get_cmdline_user_args().is_empty(),"final focused first-court case accepts no selectors"):
		if await _open_final():
			_stage = "actual first generation1→2 clear"
			_driver = EchoDriver.new()
			_driver.configure(_hero,_level,_scheduler,ECHO_IDS[0],_kit,_action_records,_fired_kinds,_tick,_presentation_boundary,_expect)
			if await _driver.clear_current_stage(true):
				await _cp1_pair()
	await _finish()

func _open_final() -> bool:
	_game = MainScene.instantiate()
	root.add_child(_game)
	_game.call("open_bench")
	if not _expect(paused and _game.call("is_lab_level"),"actual paused Main lab precedes final O3 fresh load"): return false
	if not _expect(_game.call("load_level_scene",O3_ROOM),"public Main loads final authored O3",String(_game.get("level_load_error"))): return false
	_game.call("open_bench")
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler if _level != null else null
	if not _expect(_level != null and _hero != null and _scheduler != null and _level.level_id == "A3-O3" and _level.local_snapshot_version == 2 and _level.scene_file_path == O3_ROOM and _level.contract_error().is_empty(),"actual final local2 O3/Hero/Scheduler bind"): return false
	var state: Dictionary = _level.call("state")
	var sources: Dictionary = _level.get("sources")
	var ids: Array = ECHO_IDS.duplicate()
	ids.append(STALKER_ID)
	if not _expect(state.api_revision == "act3-irontick-reflection-2" and state.route.active_stage == 0 and state.route.clears.is_empty() and state.route.deaths.is_empty() and Codec.keys_error(sources,ids).is_empty() and _hero.global_position == Vector3(0,0.1,8) and _hero.hp == _hero.max_hp and _scheduler.get_clock() == 0.0 and _scheduler.reservations().is_empty(),"final fresh topology retains three actual managed recipients plus familiar living Stalker without earned stage history",str(state)): return false
	for id: String in ECHO_IDS:
		var source: Node3D = sources[id]
		if not _expect(source.call("source_cycles_managed") and (source.call("state") as Dictionary).status == "cycle_ready" and source.call("get_authored_cycle_generation") == 1 and source.get("hp") == 36.0 and not source.get("dead"),"actual final managed ready recipient: "+id): return false
	_hp = _hero.hp
	_ammo = _hero.shells
	_kit = _hero.equipment.snapshot()
	_hero.world_action_executed.connect(_on_action)
	_hero.fired.connect(func(kind: String) -> void: _fired.append(kind))
	_level.checkpoint_requested.connect(func(_id: String,value: String,_kind: String) -> void: _checkpoints.append(value))
	_level.completion_requested.connect(func(_id: String,value: String) -> void: _completions.append(value))
	_level.contact_exit_requested.connect(func(_id: String,value: String) -> void: _exits.append(value))
	_barrier = PostActorBarrier.new()
	_barrier.name = "O3FinalFocusedObserver"
	root.add_child(_barrier)
	for _frame: int in range(4): await process_frame
	_game.call("resume_lab")
	for _index: int in range(12):
		if _hero.is_on_floor(): break
		if not await _tick(): return false
	return _expect(_hero.is_on_floor() and _hero.get_threat_response_state().stable,"actual floor registration precedes final driver approach/sweeps")

func _tick() -> bool:
	if _finishing: return false
	if not is_instance_valid(_barrier) or paused: return _expect(false,"actual final focused tick requires live unpaused observer")
	_barrier.waiting = true
	_barrier.expiration = Engine.get_process_frames()+120
	var boundary: String = await _barrier.observed
	_ticks += 1
	if _finishing: return false
	return _expect(boundary == "post_actor_physics" and not paused and _ticks <= 1800 and _scheduler.get_clock() <= 30.0 and _hero.hp == _hp and not _hero.dead and _hero.shells == _ammo and _exact(_hero.equipment.snapshot(),_kit) and String(_level.call("runtime_error")).is_empty() and not _fired.has("blast") and _completions.is_empty() and _exits.is_empty(),"bounded actual final first-court ticks preserve Hero/kit/ammo/clock and no later route completion",str(_level.call("state")))

func _presentation_boundary() -> bool:
	_barrier.presentation_waiting = true
	_barrier.presentation_expiration = Engine.get_process_frames()+120
	var boundary: String = await _barrier.presentation_observed
	if _finishing: return false
	return _expect(boundary == "post_presentation_process" and not paused,"actual Main Camera/HUD process precedes final CP capture",boundary)

func _action_records() -> Array:
	return _hero.get_world_action_records()

func _fired_kinds() -> Array:
	return _fired

func _cp1_pair() -> bool:
	_stage = "coherent actual final CP1 pair"
	if not await _presentation_boundary(): return false
	if not _expect(_game.call("request_pause_deferred"),"public completed-tick CP1 pause requested"): return false
	for _frame: int in range(4): await process_frame
	var pair: Dictionary = {"player":_hero.snapshot_state(),"level":_level.snapshot_state_for_presentation(_game.get("camera") as Camera3D,_game.get("hud") as GameHUD)}
	if not _expect(paused and not _game.call("is_pause_requested") and not pair.player.is_empty() and not pair.level.is_empty() and _hero.snapshot_error(pair.player).is_empty() and _level.snapshot_error_with_player(pair.level,pair.player).is_empty(),"complete final3journal CP1 pair captures/prevalidates through actual public Camera/HUD",_level.last_snapshot_error): return false
	var local: Dictionary = pair.level.local
	var first: Dictionary = local.sources[ECHO_IDS[0]]
	if not _expect(local.route.active_stage == 1 and local.route.clears.size() == 1 and local.route.deaths.has(ECHO_IDS[0]) and local.scheduler.schema_version == 3 and local.scheduler.authored_source_cycles.sources.size() == 3 and first.actor.hp == 0.0 and not first.actor.alive and first.actor.source_hits == 2 and first.actor.generation == 2 and _checkpoints == [CHECKPOINT_IDS[0]] and pair.level.progress.checkpoint_id == CHECKPOINT_IDS[0] and pair.level.progress.checkpoint_ids == {CHECKPOINT_IDS[0]:"encounter"} and not pair.level.progress.completed,"actual CP1 retains generation2 death and all three managed journals while activating the next native stage"): return false
	for id: String in ECHO_IDS:
		var source: Dictionary = local.sources[id]
		if not _expect(source.actor.schema_version == 2 and source.playback.api_revision == "authored-echo-playback-2" and source.actor.clock_s == local.scheduler.clock_s and source.playback.clock_s == local.scheduler.clock_s and pair.player.world_actions.clock_s == local.scheduler.clock_s,"complete actual source/playback/Scheduler/Hero native clock join: "+id): return false
	var wire: String = ExactJson.stringify(pair)
	var parsed: Dictionary = ExactJson.parse(wire)
	if not _expect(not wire.is_empty() and parsed.get("accepted",false) and _exact(pair,parsed.get("value")) and _level.snapshot_error_with_player(parsed.value.level,parsed.value.player).is_empty(),"actual final CP1 ExactJson retains complete native types/float bits/history"): return false
	# Only new final-route/journal joins. The prototype's nine generic negative
	# cases and pulse/own-route rule evidence remain preserved, not rerun here.
	for label: String in ["future-stage","missing-source","missing-journal","future-checkpoint"]:
		var bad: Dictionary = pair.level.duplicate(true)
		match label:
			"future-stage": bad.local.route.active_stage = 2
			"missing-source": bad.local.sources.erase(ECHO_IDS[2])
			"missing-journal": bad.local.scheduler.authored_source_cycles.sources.pop_back()
			"future-checkpoint": bad.progress.checkpoint_ids[CHECKPOINT_IDS[1]] = "encounter"
		var before: Dictionary = {"player":_hero.snapshot_state(),"level":_level.snapshot_state()}
		var events: Array = [_checkpoints.duplicate(),_completions.duplicate(),_exits.duplicate(),_actions.size()]
		var error: String = _level.snapshot_error_with_player(bad,pair.player)
		if not _expect(not error.is_empty() and not _level.restore_state(bad) and _exact(before,{"player":_hero.snapshot_state(),"level":_level.snapshot_state()}) and _exact(events,[_checkpoints,_completions,_exits,_actions.size()]),"new final "+label+" rejects atomically without earning history",error): return false
	return true

func _watchdog() -> void:
	if not _done and not _finishing:
		print("O3 FINAL WATCHDOG: ",_stage,"; ",_driver.describe() if _driver != null else {})
		_expect(false,"finite600s native final first-court watchdog expired")
		_finish.call_deferred()

func _finish() -> void:
	if _finishing: return
	_finishing = true
	await _dispose()
	_done = true
	print("Irontick final focused: ",_checks," checks; failures: ",_failures,"; native ticks: ",_ticks,". Actual first generation1→2/ordinary death/CP1/all3journals only; later stone/stage/CP2/completion/contact via separate Optional jobs. No route/all-kit/portrait acceptance.")
	quit(0 if _failures == 0 else 1)
