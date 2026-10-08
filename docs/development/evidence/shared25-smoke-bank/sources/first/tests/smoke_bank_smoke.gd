extends SceneTree
## NEW leaf: actual native Player/Scheduler/source and TEST ONLY public Shell.
const Bank = preload("res://scripts/combat/smoke_bank.gd")
const Player = preload("res://scripts/player.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Enemy = preload("res://scripts/enemy.gd")
var checks: int = 0
var failures: int = 0
var paths: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await _stationary_preview_and_cycle()
	await _crossing_and_reentry()
	await _invulnerability()
	await _paused_grace_restore()
	await _receipt_history()
	await _held_phase_suffix()
	await _held_expiry_suffix()
	await _held_notification()
	await _cancel_and_native_guards()
	await _unsupported_domain()
	await _emitter_independence_and_dead_hero()
	await _shell_barrier("deferred")
	await _shell_barrier("checkpoint")
	await _shell_barrier("fatal")
	for path: String in paths:
		for suffix: String in ["", ".bak"]:
			if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	print("Smoke bank smoke: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _world(profile: String = "standard", position: Vector3 = Vector3.ZERO) -> Dictionary:
	var world := Node3D.new()
	world.name = "SmokeWorld"
	root.add_child(world)
	var floor := StaticBody3D.new()
	floor.name = "Floor"
	floor.collision_layer = 1
	floor.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = Vector3(20, 1, 20)
	collision.shape = shape
	floor.add_child(collision)
	world.add_child(floor)
	floor.position.y = -0.5
	var hero: CinderPlayer = Player.new()
	hero.name = "Hero"
	hero.position = position + Vector3.UP * 0.1
	world.add_child(hero)
	hero.shells = 0
	var scheduler: CinderThreatScheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	world.add_child(scheduler)
	scheduler.begin_encounter(profile, "smoke-test", 1)
	var bank: Bank = Bank.new()
	bank.name = "Bank"
	_expect(bank.configure("smoke-test/bank", Geometry.circle(Vector3.ZERO, 1.05), Vector3.ZERO), "immutable real stationary circle configuration")
	world.add_child(bank)
	_expect(bank.bind(scheduler, {"hero": hero}), "actual earlier-physics shared Player/Scheduler binding")
	var region := {"collision": collision, "safe_rect": Rect2(-10, -10, 20, 20)}
	return {"world": world, "hero": hero, "scheduler": scheduler, "bank": bank, "region": region}

func _context(arena: Dictionary) -> Dictionary:
	return {"encounter_id": "smoke-test", "world_revision": 1, "recognition_s": 0.12, "attack_input_margin_s": 0.02, "escape_directions": [Vector3.RIGHT, Vector3.LEFT], "return_directions": [Vector3.RIGHT, Vector3.LEFT], "floor_regions": [arena.region]}

func _bindings(arena: Dictionary) -> Dictionary:
	return {"world_root": arena.world, "owners": {"smoke-test/bank": arena.bank}, "floors": {"floor": arena.region}}

func _start(arena: Dictionary) -> Dictionary:
	await _ticks(6)
	var answer: Dictionary = arena.bank.start("hero", _context(arena))
	_expect(answer.get("accepted", false), "actual empty-ammo stationary admission: " + String(answer.get("reason", "")))
	return answer

func _stationary_preview_and_cycle() -> void:
	for profile: String in ["standard", "assisted", "challenge"]:
		var arena: Dictionary = _world(profile)
		await _ticks(6)
		var bank: Bank = arena.bank
		var hero: CinderPlayer = arena.hero
		var scheduler: CinderThreatScheduler = arena.scheduler
		bank.last_error = "unchanged"
		scheduler.last_error = "scheduler unchanged"
		scheduler.last_snapshot_error = "snapshot unchanged"
		var before: Dictionary = {"state": bank.state(), "clock": scheduler.get_clock(), "hero_position": hero.global_position, "hero_velocity": hero.velocity, "history": hero.get_world_action_records(), "cue": bank.get_cue().state()}
		var preview: Dictionary = bank.preview_start("hero", _context(arena))
		_expect(preview.get("accepted", false), profile + " actual pure stationary prospective proof: " + String(preview.get("reason", "")))
		_expect(before == {"state": bank.state(), "clock": scheduler.get_clock(), "hero_position": hero.global_position, "hero_velocity": hero.velocity, "history": hero.get_world_action_records(), "cue": bank.get_cue().state()} and bank.last_error == "unchanged" and scheduler.last_error == "scheduler unchanged" and scheduler.last_snapshot_error == "snapshot unchanged", "pure preview preserves live clocks, flags, diagnostics, actor resources/actions/cue")
		if preview.get("accepted", false) and profile == "standard":
			var forged: Dictionary = preview.duplicate(true)
			forged.candidate.geometry.radius = 1.06
			_expect(not bank.start("hero", _context(arena), null, forged).get("accepted", false) and bank.state().cycle == 0 and scheduler.reservations().is_empty(), "modified prospective footprint cannot authorize admission or allocate a bank cycle")
			await _ticks(1)
			_expect(not bank.start("hero", _context(arena), null, preview).get("accepted", false) and bank.state().cycle == 0 and scheduler.reservations().is_empty(), "one actual native clock tick invalidates old preview correspondence without reserving")
			preview = bank.preview_start("hero", _context(arena))
		var phase_events: Array[String] = []
		var hits: Array[Dictionary] = []
		bank.state_changed.connect(func(value: Dictionary) -> void: phase_events.append(value.phase))
		bank.tick_resolved.connect(func(_id: String, _cycle: int, value: Dictionary) -> void: hits.append(value))
		var answer: Dictionary = bank.start("hero", _context(arena), null, preview)
		_expect(answer.get("accepted", false), profile + " exact contemporaneous native preview correspondence admits")
		if not answer.get("accepted", false):
			await _dispose(arena)
			continue
		var exchange: Dictionary = bank.state().exchange
		_expect(exchange.geometry == Geometry.circle(Vector3.ZERO, 1.05) and exchange.active_from_s == preview.candidate.active_from_s and exchange.active_until_s == preview.candidate.active_until_s and exchange.cooldown_until_s == preview.candidate.cooldown_until_s, "fresh admission retains preview geometry and original absolute phase/cooldown deadlines")
		_expect(not bank.is_in_group("enemies") and not bank.has_method("take_damage") and bank.get_cue().state().phase == "warning", "bank remains HP-free environmental source with real required warning")
		await _until_clock(scheduler, float(exchange.active_from_s) + 0.20)
		_expect(hero.hp == hero.max_hp and hits.is_empty() and bank.state().grace_progress > 0.0 and bank.state().grace_progress < 1.0, "real edge exposure shows native grace progress before any damage")
		var indicator: Node3D = bank.get_grace_indicator()
		_expect(indicator.get_node("GraceBackground").is_visible_in_tree() and indicator.get_node("GraceProgress").is_visible_in_tree() and bank.get_required_camera_points().size() >= 9, "bank-owned required progress and current actual corners are available to portrait owner")
		await _until_clock(scheduler, float(exchange.active_until_s) + 0.10)
		_expect(hits.size() == 5 and bank.state().opportunities_consumed == 5, "original active cycle consumes at most five real opportunities without catchup")
		for index: int in range(hits.size()):
			_expect(hits[index].index == index + 1 and hits[index].consumed_s >= hits[index].eligible_s and hits[index].consumed_s <= exchange.active_until_s and (index == 0 or hits[index].consumed_s >= float(hits[index - 1].consumed_s) + 0.5), "bounded original opportunity order and actual consumed-clock spacing " + str(index))
		var hp: float = hero.hp
		_expect(bank.state().exchange == exchange and bank.state().phase == "recovery" and hero.shells >= 0 and not indicator.get_node("GraceBackground").visible, "original recovery thins required cue and closes contact without resetting deadlines/resources")
		await _until_clock(scheduler, float(exchange.recovery_until_s) + 0.10)
		_expect(bank.state().status == "complete" and bank.state().phase == "clear" and hero.hp == hp and hits.size() == 5, "natural expiry completes independently without further damage or repeat opportunity")
		_expect(phase_events == ["warning", "lock", "active", "recovery", "clear"], "one coherent shared warning/lock/active/recovery/clear publication")
		await _dispose(arena)

func _crossing_and_reentry() -> void:
	var arena: Dictionary = _world()
	var answer: Dictionary = await _start(arena)
	if not answer.get("accepted", false):
		await _dispose(arena)
		return
	var hero: CinderPlayer = arena.hero
	var bank: Bank = arena.bank
	var exchange: Dictionary = bank.state().exchange
	await _until_clock(arena.scheduler, float(exchange.active_from_s) + 0.12)
	_expect(hero.request_dash(Vector3.RIGHT), "actual accepted native dash leaves an exposed smoke bank")
	await _ticks(15)
	_expect(hero.global_position.x > 2.6 and hero.hp == hero.max_hp and bank.state().opportunities_consumed == 0 and bank.state().contact_since_s == null, "exit/crossing earns no full grace; actual collision body leaves and resets unearned contact")
	var records: Array = hero.get_world_action_records()
	_expect(records.size() == 1 and records[0].kind == "dash" and records[0].path.size() > 1 and records[0].landing == hero.global_position, "crossing evidence is actual native completed dash, not reconstructed samples")
	for count: int in range(100):
		if hero.get_threat_response_state().stable and hero.get_threat_response_state().dash_cooldown_left_s <= 0.0: break
		await _ticks(1)
	_expect(hero.request_dash(Vector3.LEFT), "real cooldown-aware input returns to the bank")
	await _ticks(14)
	_expect(absf(hero.global_position.x) < 0.02 and hero.hp == hero.max_hp and bank.state().opportunities_consumed == 0, "reentry does not immediately reuse the old grace or swept crossing")
	var since: Variant = bank.state().contact_since_s
	_expect(since != null, "supported full stationary reentry starts a new visible grace interval")
	if since != null:
		await _until_clock(arena.scheduler, float(since) + 0.35)
		_expect(hero.hp == hero.max_hp and bank.state().opportunities_consumed == 0, "new grace remains unearned before its original 0.4 seconds")
		await _until_clock(arena.scheduler, float(since) + 0.44)
		_expect(bank.state().opportunities_consumed == 1, "new continuous full ticks earn precisely one first opportunity")
	await _dispose(arena)

func _invulnerability() -> void:
	var arena: Dictionary = _world()
	var answer: Dictionary = await _start(arena)
	if not answer.get("accepted", false):
		await _dispose(arena)
		return
	var bank: Bank = arena.bank
	var hero: CinderPlayer = arena.hero
	await _until_clock(arena.scheduler, float(bank.state().exchange.active_from_s) + 0.30)
	hero.take_damage(1.0, Vector3.ZERO)
	var actual_hurt_hp: float = hero.hp
	var results: Array[Dictionary] = []
	bank.tick_resolved.connect(func(_id: String, _cycle: int, value: Dictionary) -> void: results.append(value))
	await _until_clock(arena.scheduler, float(bank.state().exchange.active_from_s) + 0.48)
	_expect(results.size() == 1 and not results[0].accepted and results[0].opportunity_consumed and hero.hp == actual_hurt_hp and bank.state().opportunities_consumed == 1, "actual hurt invulnerability consumes the earned opportunity once without HP damage")
	await _ticks(5)
	_expect(results.size() == 1 and hero.hp == actual_hurt_hp, "invulnerability ending cannot regrant the consumed opportunity or create a burst")
	await _dispose(arena)

func _paused_grace_restore() -> void:
	var arena: Dictionary = _world()
	var answer: Dictionary = await _start(arena)
	if not answer.get("accepted", false):
		await _dispose(arena)
		return
	var bank: Bank = arena.bank
	await _until_clock(arena.scheduler, float(bank.state().exchange.active_from_s) + 0.24)
	paused = true
	await process_frame
	var pair: Dictionary = _pair(arena)
	_expect(not pair.bank.is_empty() and pair.bank.contact_since_s >= pair.bank.exchange.active_from_s and pair.bank.receipts.is_empty() and pair.bank.processed_count == pair.bank.trace.size(), "paused native grace transport contains original full-tick trace, no premature opportunity")
	if pair.bank.is_empty():
		push_error(bank.last_snapshot_error)
		await _dispose(arena)
		return
	var held: String = ExactJson.stringify(pair)
	var native: Dictionary = _native(arena)
	await create_timer(0.05, true).timeout
	_expect(held == ExactJson.stringify(_pair(arena)) and _native(arena) == native, "genuine pause freezes every exact actor/Scheduler/contact/required native pose bit")
	for mutation: String in ["grace", "processed_clock", "sample_clock", "actor_clock", "sample_position", "trace_endpoint", "trace_clock", "omit_tick", "reorder", "grounded", "collision", "dead", "domain", "deadline", "profile", "unknown", "schema"]:
		var bad: Dictionary = pair.bank.duplicate(true)
		match mutation:
			"grace": bad.contact_since_s = _adjacent(float(bad.contact_since_s))
			"processed_clock": bad.processed_clock_s = _adjacent(float(bad.processed_clock_s))
			"sample_clock": bad.sample.clock_s = _adjacent(float(bad.sample.clock_s))
			"actor_clock": bad.sample.actor_clock_s = _adjacent(float(bad.sample.actor_clock_s))
			"sample_position": bad.sample.position[0] = _adjacent(float(bad.sample.position[0]))
			"trace_endpoint": bad.trace[-1].to[0] = _adjacent(float(bad.trace[-1].to[0]))
			"trace_clock": bad.trace[-1].end_s = _adjacent(float(bad.trace[-1].end_s))
			"omit_tick": bad.trace.remove_at(1); bad.processed_count -= 1
			"reorder": bad.trace.reverse()
			"grounded": bad.trace[-1].to_grounded = false
			"collision": bad.trace[-1].horizontal_collision = true
			"dead": bad.sample.alive = false
			"domain": bad.domain.floors[0].safe_rect[0] = _adjacent(float(bad.domain.floors[0].safe_rect[0]))
			"deadline": bad.exchange.active_until_s = _adjacent(float(bad.exchange.active_until_s))
			"profile": bad.resolved_role.damage = 200.0
			"unknown": bad["private_hp"] = 1.0
			"schema": bad.schema_version = 2
		_expect(_reject_unchanged(arena, bad), "atomic exact transport rejection for " + mutation)
	var fresh: Dictionary = await _fresh(arena, pair)
	if not fresh.is_empty():
		_expect(_native(fresh) == native and ExactJson.stringify(_pair(fresh)) == held, "fresh actual Player/Scheduler/bank quietly reconstruct exact grace and native indicator without healing")
		var hp: float = fresh.hero.hp
		paused = false
		await _until_clock(fresh.scheduler, float(pair.bank.contact_since_s) + 0.44)
		_expect(fresh.bank.state().opportunities_consumed == 1 and fresh.hero.hp < hp, "restored remaining grace reaches original first opportunity without restarted timing")
		await _dispose(fresh)
	else: await _dispose(arena)

func _receipt_history() -> void:
	var arena: Dictionary = _world()
	var answer: Dictionary = await _start(arena)
	if not answer.get("accepted", false):
		await _dispose(arena)
		return
	await _until_clock(arena.scheduler, float(arena.bank.state().exchange.active_from_s) + 1.52)
	paused = true
	await process_frame
	var pair: Dictionary = _pair(arena)
	_expect(not pair.bank.is_empty() and pair.bank.receipts.size() == 3 and pair.bank.pending_stage == "", "actual three-opportunity history retains every processed native tick and consumed receipt")
	if pair.bank.is_empty() or pair.bank.receipts.size() != 3:
		push_error(arena.bank.last_snapshot_error)
		await _dispose(arena)
		return
	for mutation: String in ["all", "first", "last", "eligibility", "consumed_clock", "processing_clock", "result_type", "rewind_all", "rewind_phase", "rewind_notify", "rewind_notification"]:
		var bad: Dictionary = pair.bank.duplicate(true)
		match mutation:
			"all": bad.receipts.clear()
			"first": bad.receipts.remove_at(0)
			"last": bad.receipts.pop_back()
			"eligibility": bad.receipts[-1].eligible_s = _adjacent(float(bad.receipts[-1].eligible_s))
			"consumed_clock": bad.receipts[-1].consumed_s = _adjacent(float(bad.receipts[-1].consumed_s))
			"processing_clock": bad.trace[-1].processed_at_s = _adjacent(float(bad.trace[-1].processed_at_s))
			"result_type": bad.receipts[-1].result.damage_attempted = 1
			"rewind_all":
				bad.receipts.clear()
				bad.processed_count = 0
				bad.processed_clock_s = -1.0
				bad.contact_since_s = -1.0
				bad.pending_stage = "phase"
				for segment: Dictionary in bad.trace: segment.processed_at_s = null
			_:
				bad.processed_count -= 1
				bad.trace[-1].processed_at_s = null
				bad.processed_clock_s = bad.trace[-2].end_s
				bad.pending_stage = mutation.trim_prefix("rewind_")
		_expect(_reject_unchanged(arena, bad), "omitted/reclassified consumed history rejects atomically: " + mutation)
	var fresh: Dictionary = await _fresh(arena, pair)
	if not fresh.is_empty():
		var hp: float = fresh.hero.hp
		paused = false
		await _ticks(2)
		_expect(fresh.bank.state().opportunities_consumed == 3 and fresh.hero.hp == hp, "exact fresh consumed history cannot replay an old due tick or reset the five-opportunity budget")
		await _dispose(fresh)
	else: await _dispose(arena)

func _held_phase_suffix() -> void:
	var arena: Dictionary = _world()
	var answer: Dictionary = await _start(arena)
	if not answer.get("accepted", false):
		await _dispose(arena)
		return
	var denied: Array[bool] = []
	arena.bank.get_cue().state_changed.connect(func(value: Dictionary) -> void:
		if value.phase == "active":
			paused = true
			denied.append(arena.bank.snapshot_state(_bindings(arena)).is_empty())
	)
	for count: int in range(230):
		if paused: break
		await _ticks(1)
	await process_frame
	var pair: Dictionary = _pair(arena)
	_expect(paused and denied == [true] and not pair.bank.is_empty() and pair.bank.pending_stage == "phase" and pair.bank.trace.size() - pair.bank.processed_count == 1 and pair.bank.receipts.is_empty(), "actual activation Cue observer holds exactly one unprocessed native sample, with no prematurely earned grace")
	if pair.bank.is_empty():
		push_error(arena.bank.last_snapshot_error)
		await _dispose(arena)
		return
	var held: String = ExactJson.stringify(pair)
	var native: Dictionary = _native(arena)
	var fresh: Dictionary = await _fresh(arena, pair)
	if not fresh.is_empty():
		_expect(ExactJson.stringify(_pair(fresh)) == held and _native(fresh) == native, "quiet fresh phase-held restore retains the exact original native required cue and pending sample")
		paused = false
		_expect(fresh.hero.request_dash(Vector3.RIGHT), "ordinary real input leaves the restored original field")
		await _ticks(15)
		_expect(fresh.hero.hp == fresh.hero.max_hp and fresh.bank.state().opportunities_consumed == 0 and fresh.bank.state().contact_since_s == null and fresh.bank.state().pending_samples == 0, "processing the held activation plus real exit never grants grace from a swept crossing or duplicates the original tick")
		_expect(fresh.hero.get_world_action_records().size() == 1 and fresh.hero.get_world_action_records()[0].kind == "dash", "held-boundary exit uses the actual completed shared Player dash record")
		await _dispose(fresh)
	else: await _dispose(arena)

func _held_expiry_suffix() -> void:
	var arena: Dictionary = _world()
	var answer: Dictionary = await _start(arena)
	if not answer.get("accepted", false):
		await _dispose(arena)
		return
	arena.bank.get_cue().state_changed.connect(func(value: Dictionary) -> void:
		if value.phase == "recovery": paused = true
	)
	for count: int in range(380):
		if paused: break
		await _ticks(1)
	await process_frame
	var pair: Dictionary = _pair(arena)
	_expect(paused and not pair.bank.is_empty() and pair.bank.pending_stage == "phase" and pair.bank.phase == "recovery" and pair.bank.contact_since_s == -1.0 and pair.bank.receipts.size() == 5, "actual recovery Cue pause preserves original consumed cycle and one expired boundary sample with closed grace")
	if pair.bank.is_empty():
		push_error(arena.bank.last_snapshot_error)
		await _dispose(arena)
		return
	var fresh: Dictionary = await _fresh(arena, pair)
	if not fresh.is_empty():
		var hp: float = fresh.hero.hp
		paused = false
		await _ticks(2)
		_expect(fresh.hero.hp == hp and fresh.bank.state().opportunities_consumed == 5 and fresh.bank.state().pending_samples == 0 and fresh.bank.state().contact_since_s == null and fresh.bank.state().exchange.active_until_s == pair.bank.exchange.active_until_s and fresh.bank.state().exchange.recovery_until_s == pair.bank.exchange.recovery_until_s, "quiet recovery-boundary restore expires the held tick without stale damage, catchup or original deadline reset")
		await _dispose(fresh)
	else: await _dispose(arena)

func _held_notification() -> void:
	var arena: Dictionary = _world()
	var answer: Dictionary = await _start(arena)
	if not answer.get("accepted", false):
		await _dispose(arena)
		return
	var hero: CinderPlayer = arena.hero
	var bank: Bank = arena.bank
	var results: Array = []
	var denied: Array[bool] = []
	hero.fired.connect(func(action: String) -> void:
		if action == "hurt":
			paused = true
			denied.append(bank.snapshot_state(_bindings(arena)).is_empty())
	)
	bank.tick_resolved.connect(func(_id: String, _cycle: int, result: Dictionary) -> void: results.append(result))
	for count: int in range(230):
		if paused: break
		await _ticks(1)
	await process_frame
	var pair: Dictionary = _pair(arena)
	_expect(paused and denied == [true] and not pair.bank.is_empty() and pair.bank.receipts.size() == 1 and pair.bank.receipts[0].stage == "notify" and results.is_empty() and pair.hero.resources.hp < pair.hero.resources.max_hp, "actual Player hurt observer pauses after one committed damage and retains unfinished notification")
	if pair.bank.is_empty():
		push_error(bank.last_snapshot_error)
		await _dispose(arena)
		return
	var fresh: Dictionary = await _fresh(arena, pair)
	if not fresh.is_empty():
		var hp: float = fresh.hero.hp
		var notifications: Array = []
		fresh.bank.tick_resolved.connect(func(_id: String, _cycle: int, result: Dictionary) -> void:
			notifications.append(result)
			paused = true
		)
		paused = false
		await _ticks(1)
		var delivered: Dictionary = _pair(fresh)
		_expect(paused and notifications.size() == 1 and notifications[0].index == 1 and notifications[0].consumed_s == pair.bank.receipts[0].consumed_s and fresh.hero.hp == hp and not delivered.bank.is_empty() and delivered.bank.pending_stage == "notification" and delivered.bank.trace.size() - delivered.bank.processed_count == 1 and delivered.bank.receipts[0].stage == "done", "fresh resume delivers original held receipt once and direct notification pause retains its actual new pending native tick")
		if not delivered.bank.is_empty():
			var again: Dictionary = await _fresh(fresh, delivered)
			if not again.is_empty():
				var repeats: Array = []
				again.bank.tick_resolved.connect(func(_id: String, _cycle: int, result: Dictionary) -> void: repeats.append(result))
				paused = false
				await _ticks(2)
				_expect(repeats.is_empty() and again.hero.hp == hp and again.bank.state().opportunities_consumed == 1 and again.bank.state().pending_samples == 0, "second quiet fresh restore processes held notification sample without redelivery, damage or deadline reset")
				await _dispose(again)
		else: await _dispose(fresh)
	else: await _dispose(arena)

func _cancel_and_native_guards() -> void:
	for mutation: String in ["hidden_bar", "missing_bar", "replace_bar", "change_bar", "bar_layers", "bar_texture", "hidden_outline", "missing_cue", "replace_fill", "edit_fill", "source", "floor", "world"]:
		var arena: Dictionary = _world()
		var answer: Dictionary = await _start(arena)
		if not answer.get("accepted", false):
			await _dispose(arena)
			continue
		var bank: Bank = arena.bank
		await _until_clock(arena.scheduler, float(bank.state().exchange.active_from_s) + 0.20)
		paused = true
		await process_frame
		var original: Dictionary = _pair(arena)
		var grace: Node3D = bank.get_grace_indicator()
		var cue: CinderThreatCue = bank.get_cue()
		match mutation:
			"hidden_bar": grace.get_node("GraceBackground").visible = false
			"missing_bar": grace.get_node("GraceProgress").free()
			"replace_bar": grace.get_node("GraceProgress").mesh = grace.get_node("GraceProgress").mesh.duplicate()
			"change_bar": grace.get_node("GraceProgress").mesh.size.x += 0.01
			"bar_layers": grace.get_node("GraceProgress").layers = 0
			"bar_texture": grace.get_node("GraceProgress").material_override.albedo_texture = GradientTexture2D.new()
			"hidden_outline": cue.get_node("RequiredFootprintOutline").visible = false
			"missing_cue": cue.get_node("RequiredFootprintFill").free()
			"replace_fill": cue.get_node("RequiredFootprintFill").mesh = cue.get_node("RequiredFootprintFill").mesh.duplicate()
			"edit_fill": cue.get_node("RequiredFootprintFill").mesh.clear_surfaces()
			"source": bank.position.x += 0.01
			"floor": arena.region.collision.position.y += 0.01
			"world": _wall(arena.world, Vector3(5, 1, 5))
		var hp: float = arena.hero.hp
		_expect(bank.snapshot_state(_bindings(arena)).is_empty() and not bank.restore_state(original.bank, _bindings(arena)), "live required " + mutation + " rejects capture/restore without healing native binding")
		paused = false
		await _ticks(3)
		_expect(bank.state().status == "cancelled" and bank.state().opportunities_consumed == 0 and arena.hero.hp == hp, "unavailable required " + mutation + " cancels original lease before grace can license damage")
		await _dispose(arena)
	var arena: Dictionary = _world()
	var answer: Dictionary = await _start(arena)
	if answer.get("accepted", false):
		var bank: Bank = arena.bank
		var reentry: Array = []
		bank.tick_resolved.connect(func(_id: String, _cycle: int, _result: Dictionary) -> void:
			reentry.append(bank.start("hero", _context(arena)).get("accepted", false))
			reentry.append(bank.cancel("actual_tick_observer"))
		)
		await _until_clock(arena.scheduler, float(bank.state().exchange.active_from_s) + 0.60)
		_expect(reentry == [false, true] and bank.state().status == "cancelled" and bank.state().opportunities_consumed == 1, "synchronous observer cannot start or duplicate; actual cancellation stops current lease after one consumed opportunity")
		_expect(not bank.start("hero", _context(arena)).get("accepted", false) and bank.state().cycle == 1, "cancellation cannot refresh the original source cooldown")
		var hp: float = arena.hero.hp
		await _ticks(45)
		_expect(arena.hero.hp == hp and bank.state().opportunities_consumed == 1, "canceled receipt cannot later deliver or refresh damage")
	await _dispose(arena)

func _unsupported_domain() -> void:
	for mutation: String in ["gap", "wall", "rotated", "moving", "unsupported", "axis", "mask", "epoch"]:
		var arena: Dictionary = _world()
		await _ticks(6)
		var context: Dictionary = _context(arena)
		match mutation:
			"gap": context.floor_regions[0].safe_rect = Rect2(-1, -1, 2, 2)
			"wall": _wall(arena.world, Vector3(0.8, 1, 0))
			"rotated": arena.region.collision.rotation.y = 0.01
			"moving": arena.region.collision.get_parent().constant_linear_velocity = Vector3.RIGHT
			"unsupported": arena.region.collision.shape = SphereShape3D.new()
			"axis": arena.hero.axis_lock_linear_x = true
			"mask": arena.hero.collision_mask = 0
			"epoch": context.encounter_id = "other"
		var original: Dictionary = arena.bank.state()
		var clock: float = arena.scheduler.get_clock()
		arena.bank.last_error = "preserve"
		_expect(not arena.bank.preview_start("hero", context).get("accepted", false) and arena.bank.state() == original and arena.bank.last_error == "preserve" and arena.scheduler.get_clock() == clock, "pure fail-closed rejection of unsupported actual " + mutation)
		_expect(not arena.bank.start("hero", context).get("accepted", false) and arena.bank.state().cycle == 0 and arena.scheduler.reservations().is_empty(), "unsupported " + mutation + " cannot allocate or mutate a cycle")
		await _dispose(arena)

func _emitter_independence_and_dead_hero() -> void:
	var arena: Dictionary = _world()
	var answer: Dictionary = await _start(arena)
	if answer.get("accepted", false):
		var enemy: AshEnemy = Enemy.new()
		enemy.name = "ActualSeparateEmitter"
		enemy.position = Vector3(-4, 0.1, 0)
		arena.world.add_child(enemy)
		enemy.set_physics_process(false)
		var exchange: Dictionary = arena.bank.state().exchange
		var death: Array = []
		enemy.died.connect(func(where: Vector3) -> void: death.append(where))
		enemy.take_damage(100000.0, Vector3.ZERO)
		await _ticks(2)
		_expect(death.size() == 1 and not is_instance_valid(enemy) and arena.bank.state().status == "running" and arena.bank.state().exchange == exchange, "actual independent living enemy death/free does not clear active bank or rewrite original deadlines")
		await _until_clock(arena.scheduler, float(exchange.active_from_s) + 0.48)
		_expect(arena.bank.state().opportunities_consumed == 1, "existing bank still follows its own admitted contact cycle after emitter defeat")
	await _dispose(arena)
	arena = _world()
	answer = await _start(arena)
	if answer.get("accepted", false):
		arena.hero.hp = 0.1
		await _until_clock(arena.scheduler, float(arena.bank.state().exchange.active_from_s) + 0.50)
		_expect(arena.hero.dead and arena.hero.hp == 0.0 and arena.bank.state().opportunities_consumed == 1, "actual original smoke tick kills injured real Hero once")
		paused = true
		await process_frame
		var pair: Dictionary = _pair(arena)
		_expect(not pair.bank.is_empty() and pair.hero.resources.dead and pair.bank.contact_since_s == -1.0, "fatal exact aggregate retains dead Hero and no live grace")
		if not pair.bank.is_empty():
			var fresh: Dictionary = await _fresh(arena, pair)
			if not fresh.is_empty():
				paused = false
				await _ticks(35)
				_expect(fresh.hero.dead and fresh.hero.hp == 0.0 and fresh.bank.state().opportunities_consumed == 1, "dead fresh resume neither resurrects Hero nor regrants a smoke opportunity")
				await _dispose(fresh)
				return
	await _dispose(arena)

func _shell_barrier(selector: String) -> void:
	paused = true
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Registry.DATA_PATH))
	for info: Dictionary in raw.levels:
		if info.id == "A1-L1":
			info.scene_path = "res://tests/fixtures/smoke_bank_level.tscn"
			info.readiness = "accepted"
			info.accepted_commit = "b".repeat(40)
			info.api_revision = Registry.API_REVISION
	var prefix: String = "user://test-smoke-bank-%d-%s-" % [OS.get_process_id(), selector]
	paths.append_array([prefix + "campaign.json", prefix + "settings.json", prefix + "preferences.json"])
	var game: CinderCampaignShell = Shell.new()
	_expect(game.configure_runtime(raw, prefix + "campaign.json", prefix + "settings.json", prefix + "preferences.json"), selector + " configures isolated public production Shell with TEST ONLY registry fixture")
	root.add_child(game)
	await _settle()
	game.menu.begin_story_requested.emit()
	await _settle()
	_expect(is_instance_valid(game.active_level) and game.campaign_error.is_empty(), selector + " public Begin Story enters paused native fixture: " + game.campaign_error)
	if not is_instance_valid(game.active_level):
		game.free()
		await _settle()
		return
	game.player.hp = 0.1 if selector == "fatal" else 37.0
	game.player.shells = 0
	game.resume_campaign()
	await _ticks(6)
	var level: CinderLevel = game.active_level
	var bank: Bank = level.bank
	var seen: Array = []
	bank.tick_resolved.connect(func(_id: String, _cycle: int, _result: Dictionary) -> void:
		if not seen.is_empty(): return
		seen.append({"in_physics": Engine.is_in_physics_frame(), "paused_inside": paused, "first": game.request_pause_deferred(), "second": game.request_pause_deferred()})
		if selector == "checkpoint": level.request_checkpoint("smoke-native-tick", "encounter")
	)
	_expect(level.start_bank().get("accepted", false), selector + " actual public-Shell bank admission")
	for count: int in range(230):
		if not seen.is_empty(): break
		await _ticks(1)
	await _settle()
	_expect(seen.size() == 1 and seen[0].in_physics and not seen[0].paused_inside and seen[0].first and not seen[0].second, selector + " real source callback uses coalesced public deferred barrier without early tree freeze")
	var saved: Dictionary = game.capture_campaign_snapshot()
	_expect(paused and not saved.is_empty() and game.campaign_error.is_empty(), selector + " public whole campaign capture/save is coherent after the completed native tick: " + game.campaign_error)
	if not saved.is_empty():
		var local: Dictionary = saved.level.local
		_expect(local.bank.clock_s == local.scheduler.clock_s and local.late_clock == local.scheduler.clock_s and local.late_phase == local.bank.phase and local.bank.sample.position == saved.player.motion.position and local.bank.sample.actor_clock_s == saved.player.world_actions.clock_s, selector + " later real presentation and actual saved Hero join the same native Scheduler tick")
		_expect(local.bank.receipts.size() == 1 and local.bank.receipts[0].stage == "done", selector + " original tick notification settles once before whole-unit capture")
		if selector == "fatal":
			_expect(saved.player.resources.dead and saved.player.resources.hp == 0.0, "public fatal aggregate contains actual smoke-hit death, not forged dead metadata")
			game.resume_campaign()
			_expect(paused and game.player.dead and ExactJson.stringify(game.capture_campaign_snapshot()) == ExactJson.stringify(saved), "public dead Resume remains frozen with original fatal resources/contact history")
		else:
			var disk: Dictionary = preload("res://scripts/campaign/save_store.gd").new(prefix + "campaign.json").read_payload()
			_expect(not disk.is_empty() and disk.story.snapshot.level.local.bank.receipts.size() == 1, "actual isolated format2 durable save retains completed smoke opportunity")
			var frozen: String = ExactJson.stringify(saved)
			await create_timer(0.04, true).timeout
			_expect(ExactJson.stringify(game.capture_campaign_snapshot()) == frozen, "held public Shell pause freezes exact bank/actor/Scheduler/late presentation")
			game.free()
			await _settle()
			game = Shell.new()
			_expect(game.configure_runtime(raw, prefix + "campaign.json", prefix + "settings.json", prefix + "preferences.json"), "fresh actual public Shell uses same isolated exact saved unit")
			root.add_child(game)
			await _settle()
			game.menu.continue_story_requested.emit()
			await _settle()
			_expect(is_instance_valid(game.active_level) and game.campaign_error.is_empty() and paused, "fresh public Continue Story quietly restores real bank/Scheduler/Player unit: " + game.campaign_error)
			if is_instance_valid(game.active_level):
				_expect(ExactJson.stringify(game.capture_campaign_snapshot()) == frozen and game.player.hp == saved.player.resources.hp, "fresh public campaign retry/continue preserves original grace/receipts/resources and full native tick")
	game.free()
	await _settle()
	paused = false

func _pair(arena: Dictionary) -> Dictionary:
	var value := {"hero": arena.hero.snapshot_state(), "scheduler": arena.scheduler.snapshot_state(_bindings(arena)), "bank": arena.bank.snapshot_state(_bindings(arena))}
	var parsed: Dictionary = ExactJson.parse(ExactJson.stringify(value))
	return parsed.get("value", {})

func _fresh(old: Dictionary, pair: Dictionary) -> Dictionary:
	# Actual native fresh recipients must have the same named world paths and
	# immutable resources. Free the prior world only after retaining exact bytes.
	old.world.free()
	paused = false
	var arena: Dictionary = _world()
	await _ticks(6)
	paused = true
	await process_frame
	var phases: Array = []
	var results: Array = []
	arena.bank.state_changed.connect(func(value: Dictionary) -> void: phases.append(value.phase))
	arena.bank.get_cue().state_changed.connect(func(value: Dictionary) -> void: phases.append(value.phase))
	arena.bank.tick_resolved.connect(func(_id: String, _cycle: int, result: Dictionary) -> void: results.append(result))
	var actor_error: String = arena.hero.snapshot_error(pair.hero)
	var scheduler_error: String = arena.scheduler.snapshot_error(pair.scheduler, _bindings(arena))
	var bank_error: String = arena.bank.snapshot_error(pair.bank, _bindings(arena), pair.scheduler, pair.hero)
	_expect(actor_error.is_empty() and scheduler_error.is_empty() and bank_error.is_empty(), "pure fresh aggregate prevalidation: " + actor_error + " / " + scheduler_error + " / " + bank_error)
	var okay: bool = actor_error.is_empty() and scheduler_error.is_empty() and bank_error.is_empty() and arena.hero.restore_state(pair.hero) and arena.scheduler.restore_state(pair.scheduler, _bindings(arena)) and arena.bank.restore_state(pair.bank, _bindings(arena))
	_expect(okay and phases.is_empty() and results.is_empty(), "actual Player→Scheduler→bank atomic quiet commit emits no attacks, phases, damage or resource grants")
	if not okay:
		push_error(arena.bank.last_snapshot_error)
		await _dispose(arena)
		return {}
	return arena

func _reject_unchanged(arena: Dictionary, bad: Dictionary) -> bool:
	var before: String = ExactJson.stringify(_pair(arena))
	var native: Dictionary = _native(arena)
	return not arena.bank.snapshot_error(bad, _bindings(arena)).is_empty() and not arena.bank.restore_state(bad, _bindings(arena)) and before == ExactJson.stringify(_pair(arena)) and native == _native(arena)

func _native(arena: Dictionary) -> Dictionary:
	var indicator: Node3D = arena.bank.get_grace_indicator()
	var value: Dictionary = {"indicator_transform": indicator.global_transform}
	for name: String in ["GraceBackground", "GraceProgress"]:
		var part: MeshInstance3D = indicator.get_node(name) as MeshInstance3D
		value[name] = {"visible": part.visible, "transform": part.transform, "size": (part.mesh as BoxMesh).size, "color": (part.material_override as StandardMaterial3D).albedo_color}
	for name: String in ["RequiredFootprintOutline", "RequiredFootprintFill", "RequiredSourceMarker"]:
		var part: MeshInstance3D = arena.bank.get_cue().get_node(name) as MeshInstance3D
		value[name] = {"visible": part.visible, "transform": part.transform, "global": part.global_transform, "arrays": part.mesh.surface_get_arrays(0) if part.mesh != null else [], "color": (part.material_override as StandardMaterial3D).albedo_color}
	return value

func _wall(world: Node3D, position: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "Wall"
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.3, 2, 0.3)
	collision.shape = shape
	body.add_child(collision)
	world.add_child(body)
	body.position = position

func _adjacent(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes.encode_u64(0, bytes.decode_u64(0) + 1)
	return bytes.decode_double(0)

func _until_clock(scheduler: CinderThreatScheduler, deadline: float) -> void:
	for count: int in range(1000):
		if scheduler.get_clock() >= deadline: return
		await _ticks(1)
	_expect(false, "bounded native deadline wait did not reach " + str(deadline))

func _ticks(count: int) -> void:
	for index: int in range(count):
		await physics_frame
		await process_frame

func _settle() -> void:
	for count: int in range(4): await process_frame

func _dispose(arena: Dictionary) -> void:
	if is_instance_valid(arena.get("world")): arena.world.free()
	paused = false
	await process_frame

func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
