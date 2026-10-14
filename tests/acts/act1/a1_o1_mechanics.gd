extends SceneTree
## SOURCE ONLY until imported and executed by the Act 1 owner.
## Actual production Main and shared Player. One contact and one native exchange;
## explicit TEST same-floor contact placement does not claim an earned route.
## No actor HP/phase, Scheduler clock, checkpoint or source sample is seeded.
## Campaign optional-entry, disk Continue/Retry, full route and art are separate.

const MainScene = preload("res://scenes/main.tscn")
const Layout = preload("res://scripts/acts/act1/salvage_circuit_layout.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Equipment = preload("res://scripts/equipment.gd")
const LEVEL_PATH: String = "res://scenes/acts/act1/a1_o1.tscn"
const WATCHDOG_MS: int = 60000
const PART_ID: String = "nose-cap"
const LANDING_PHYSICAL_BOUND: float = 0.035 # Existing L2 native-dash observation.

var game: Node
var level: CinderLevel
var hero: CinderPlayer
var circuit: Act1RushSelenite
var final_rusher: Act1RushSelenite
var impact: CinderLaneMechanism
var scheduler: CinderThreatScheduler
var floor_collision: CollisionShape3D
var floor_shape: BoxShape3D
var floor_frame: Transform3D
var checks: int = 0
var failures: int = 0
var first_failure: Dictionary = {}
var events: int = 0
var part_events: Array[Dictionary] = []
var progress_events: Array[Dictionary] = []
var admissions: Dictionary = {}
var receipts: Array[Dictionary] = []
var setups: Array[Dictionary] = []
var finishing: bool = false
var started_ms: int = 0
var report_path: String = ""


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	report_path = "res://.cinder/a1-o1-mechanics-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	process_frame.connect(_watchdog)
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	# Pause before construction/first physics; native immutable floor registration
	# still occurs in actual process frames. No private registration substitute.
	paused = true
	game = MainScene.instantiate()
	game.set("level_scene_path", LEVEL_PATH)
	root.add_child(game)
	await process_frame
	await process_frame
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	if not _expect(level != null and hero != null and level.scene_file_path == LEVEL_PATH and level.hero == hero and level.contract_error().is_empty(), "actual Main constructs the O1 scene and its shared level/Player contract"):
		await _finish(); return
	if not _expect(_count_players(game) == 1 and level.level_id == Layout.LEVEL_ID and hero.global_position == level.spawn_position(), "O1 has one actual shared Player at its authored reachable spawn"):
		await _finish(); return
	circuit = level.get("circuit") as Act1RushSelenite
	final_rusher = level.get("final_rusher") as Act1RushSelenite
	impact = level.get("impact") as CinderLaneMechanism
	scheduler = level.get("scheduler") as CinderThreatScheduler
	floor_collision = level.get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
	if not _expect(circuit != null and final_rusher != null and impact != null and scheduler != null and floor_collision != null and floor_collision.shape is BoxShape3D, "retained native C30/Lane/Scheduler and Box query floor exist"):
		await _finish(); return
	floor_shape = floor_collision.shape as BoxShape3D
	floor_frame = floor_collision.global_transform
	_expect(floor_shape.size == Layout.FLOOR_SIZE and floor_collision.get_parent() is StaticBody3D and level.restore_candidate_physics_registration_required(), "fresh restore declares the actual immutable native floor registration need")
	_expect(scheduler.get_clock() == 0.0 and circuit.hp == 20.0 and not circuit.dormant and final_rusher.hp == 20.0 and final_rusher.dormant and not final_rusher.visible and not final_rusher.is_in_group("enemies") and impact.state().cycle == 0, "paused pristine construction advances no native clock or attack and keeps final source dormant")
	_expect(hero.equipment.snapshot() == Equipment.STARTER and float(hero.equipment.resolved_stats().primary_damage) == 20.0, "unchanged canonical starter equipment supplies ordinary20HP primary")
	_watch_events()
	var initial: Dictionary = _pair()
	if not _expect(not initial.player.is_empty() and not initial.level.is_empty(), "paused pristine whole Player/O1 unit captures after native registration"):
		await _finish(); return
	_expect(initial.level.local.api_revision == "act1-salvage-circuit-1" and initial.level.local.schema_version is int and initial.level.local.schema_version == 1 and initial.level.local.stage == "circuit" and initial.level.local.collected_ids.is_empty() and initial.level.progress.checkpoint_ids.is_empty() and not initial.level.progress.completed, "pristine exact O1 metadata retains unearned contacts and progression")
	var wire: String = Exact.stringify(initial)
	var decoded: Dictionary = Exact.parse(wire)
	if not _expect(not wire.is_empty() and decoded.get("accepted", false) and Exact.stringify(decoded.value) == wire and level.snapshot_error_with_player(decoded.value.level, decoded.value.player).is_empty(), "initial complete unit prevalidates and preserves exact typed transport"):
		await _finish(); return
	var prior_events: int = events
	if not _expect(_restore_pair(decoded.value) and Exact.stringify(_pair()) == wire and events == prior_events, "same-world quiet whole Player/local restore preserves all bits without callbacks"):
		await _finish(); return
	var malformed: Dictionary = initial.duplicate(true)
	malformed.level.local.collected_ids = [PART_ID, PART_ID]
	if not _reject(malformed, "duplicate collected-part identity"):
		await _finish(); return
	malformed = initial.duplicate(true)
	malformed.level.local.final_started = true
	if not _reject(malformed, "unearned final activation"):
		await _finish(); return
	malformed = initial.duplicate(true)
	malformed.level.progress.completed = true
	malformed.level.progress.completion_id = Layout.COMPLETION_ID
	if not _reject(malformed, "unearned repaired-hatch completion"):
		await _finish(); return
	receipts.append({"label": "actual initial paused unit", "exact_pair": wire})
	# Focused TEST placement changes only actual Hero position/velocity at a paused
	# barrier. The production Area overlap and late parent tick earn this one part.
	var position: Vector3 = Layout.PART_POSITIONS[PART_ID] + Vector3(0, 0.005, 0)
	hero.global_position = position
	hero.velocity = Vector3.ZERO
	setups.append({"kind": "TEST same-floor one-part contact placement; no earned traversal", "part_id": PART_ID, "hero_position": _encode(position)})
	game.call("resume_lab")
	if not await _wait(func() -> bool: return (level.get("collected_ids") as Array).has(PART_ID), "actual one-part Area contact", 8.0):
		await _finish(); return
	var parts: Dictionary = level.get("parts")
	var part: Node3D = parts[PART_ID]
	var area: Area3D = part.call("contact_area")
	var cue: CinderInteractionCue = part.call("get_cue")
	if not _expect(area.overlaps_body(hero) and (level.get("collected_ids") as Array) == [PART_ID] and part_events.size() == 1 and part_events[0].order == [PART_ID] and part.call("presentation_state").state == "spent" and cue.state().state == "spent" and cue.state().trigger == "contact", "actual contact consumes one unique part, publishes original order and leaves a spent contact cue"):
		await _finish(); return
	for observation: int in range(5):
		if not await _wait_one_frame(): await _finish(); return
	_expect(area.overlaps_body(hero) and (level.get("collected_ids") as Array) == [PART_ID] and part_events.size() == 1 and level.get("stage") == "circuit" and not level.get("checkpoint_published") and not level.get("final_started") and final_rusher.dormant and progress_events.is_empty(), "continued actual overlap is idempotent and cannot activate final/checkpoint/completion after one part")
	if not await _wait(func() -> bool: return admissions.has(Layout.CIRCUIT_SOURCE_ID) and circuit.state().status == "running" and circuit.state().phase == "warning", "natural circuit C30 warning admission", 8.0):
		await _finish(); return
	var host: Dictionary = admissions[Layout.CIRCUIT_SOURCE_ID].duplicate(true)
	if not _expect(host.get("accepted", false) and host.reservation_id == circuit.state().reservation_id and not host.proof.uses_blast and not host.proof.uses_invulnerability and not host.proof.path.is_empty(), "real circuit reservation publishes its complete ordinary response proof"):
		await _finish(); return
	if not await _wait(func() -> bool: return admissions.has(Layout.IMPACT_ID) and impact.state().status == "running" and impact.state().phase == "warning", "natural circuit companion impact warning", 8.0):
		await _finish(); return
	var companion: Dictionary = admissions[Layout.IMPACT_ID].duplicate(true)
	if not _expect(companion.get("accepted", false) and companion.reservation_id == impact.state().reservation_id and not companion.proof.uses_blast and not companion.proof.uses_invulnerability and companion.proof.primary_time_s >= host.reservation.active_until_s and companion.proof.response_complete_s < host.reservation.recovery_until_s and companion.reservation.opening_position == host.reservation.opening_position, "native companion keeps the original full ordinary-primary response within living host recovery"):
		await _finish(); return
	receipts.append({"label": "actual paired warning admissions", "host": _encode(host), "companion": _encode(companion), "clock_s": scheduler.get_clock()})
	if not await _ordinary_response(companion.proof):
		await _finish(); return
	_expect(_floor_unchanged(), "one actual exchange retains the same native floor, shape, dimensions and transform")
	await _finish()


func _ordinary_response(proof: Dictionary) -> bool:
	var paths: Array = proof.path
	if not _expect(paths.size() in [4, 6] and paths[1].kind == "escape_dash" and paths.back().kind == "ordinary_primary", "native proof supplies a complete original escape-to-primary path"): return false
	var hp_before: float = hero.hp
	if not await _wait(func() -> bool: return scheduler.get_clock() >= float(paths[0].end_s), "native recognition/readiness interval", 4.0): return false
	if not await _dash_to(proof.landing, "actual native proof escape"): return false
	if paths.size() == 6:
		if not await _wait(func() -> bool: return scheduler.get_clock() >= float(paths[3].start_s), "native positioning-dash readiness", 8.0): return false
		if not await _dash_to(proof.attack_position, "actual native proof positioning dash"): return false
	if not await _wait(func() -> bool: return scheduler.get_clock() >= float(proof.primary_time_s) and _primary_ready(), "native full ordinary-primary opportunity", 8.0): return false
	var state: Dictionary = circuit.state()
	if not _expect(state.phase == "recovery" and not circuit.dead and state.get("adapter", {}).get("finished", false) and circuit.velocity == Vector3.ZERO and hero.hp == hp_before and impact.state().hit_ids.is_empty(), "actual living C30 has physically stopped and retains a safe undamaged ordinary recovery opening"): return false
	var sequence: int = _last_sequence()
	var shells_before: int = hero.shells
	var hits: int = hero.slash((circuit.global_position - hero.global_position).normalized())
	var history: Array[Dictionary] = hero.get_world_action_records(sequence)
	if not _expect(hits == 1 and circuit.hp == 0.0 and circuit.dead and history.size() == 1 and history[0].kind == "primary" and history[0].origin == "player_direct" and history[0].hits == 1 and hero.shells >= shells_before, "actual public ordinary20HP primary defeats real C30 once during recovery without spending blast ammo"): return false
	receipts.append({"label": "actual public primary during original host recovery", "clock_s": scheduler.get_clock(), "action": _encode(history[0]), "source_before": _encode(state), "hp_after": circuit.hp})
	await process_frame # Unwind native Player/source signal transaction before exit.
	return _expect(not level.get("final_started") and final_rusher.dormant and progress_events.is_empty() and (level.get("collected_ids") as Array).size() < 3, "focused one-part native exchange leaves final/checkpoint/completion unearned")


func _dash_to(landing: Vector3, label: String) -> bool:
	if not await _wait(_dash_ready, label + " readiness", 4.0): return false
	var origin: Vector3 = hero.global_position
	var direction := Vector3(landing.x - origin.x, 0, landing.z - origin.z).normalized()
	var sequence: int = _last_sequence()
	if not _expect(direction.is_finite() and direction.length_squared() > 0.99 and hero.request_dash(direction), label + " uses the ordinary public shared dash"): return false
	if not await _wait(_dash_ready, label + " deliberate stop", 4.0): return false
	var history: Array[Dictionary] = hero.get_world_action_records(sequence)
	var error: float = Vector2(hero.global_position.x - landing.x, hero.global_position.z - landing.z).length()
	receipts.append({"label": label, "native_landing": _encode(landing), "actual_endpoint": _encode(hero.global_position), "physical_observation_error": error, "actions": _encode(history)})
	return _expect(history.size() == 1 and history[0].kind == "dash" and history[0].origin == "player_direct" and not history[0].collision_shortened and error <= LANDING_PHYSICAL_BOUND, label + " finishes its real unshortened dash at the proved landing")


func _dash_ready() -> bool:
	var state: Dictionary = hero.get_threat_response_state()
	return not paused and not hero.dead and state.stable and float(state.commitment_remaining_s) == 0.0 and float(state.dash_cooldown_left_s) == 0.0


func _primary_ready() -> bool:
	return _dash_ready() and float(hero.get_threat_response_state().primary_cooldown_left_s) == 0.0


func _watch_events() -> void:
	level.connect("part_collected", func(id: String, order: Array[String]) -> void:
		events += 1; part_events.append({"id": id, "order": order.duplicate()}))
	level.connect("native_admission_published", func(id: String, answer: Dictionary) -> void:
		events += 1
		if answer.get("accepted", false) and not admissions.has(id): admissions[id] = answer.duplicate(true))
	level.checkpoint_requested.connect(func(id: String, checkpoint: String, kind: String) -> void:
		events += 1; progress_events.append({"kind": "checkpoint", "level_id": id, "id": checkpoint, "boundary": kind}))
	level.completion_requested.connect(func(id: String, completion: String) -> void:
		events += 1; progress_events.append({"kind": "completion", "level_id": id, "id": completion}))
	level.contact_exit_requested.connect(func(id: String, exit_id: String) -> void:
		events += 1; progress_events.append({"kind": "exit", "level_id": id, "id": exit_id}))
	for actor: Act1RushSelenite in [circuit, final_rusher]:
		actor.state_changed.connect(func(_value: Dictionary) -> void: events += 1)
		actor.get_cue().state_changed.connect(func(_value: Dictionary) -> void: events += 1)
	impact.state_changed.connect(func(_value: Dictionary) -> void: events += 1)
	impact.get_cue().state_changed.connect(func(_value: Dictionary) -> void: events += 1)
	for part: Node3D in (level.get("parts") as Dictionary).values():
		var cue: CinderInteractionCue = part.call("get_cue")
		cue.state_changed.connect(func(_value: Dictionary) -> void: events += 1)
	(level.get("hatch_cue") as CinderInteractionCue).state_changed.connect(func(_value: Dictionary) -> void: events += 1)


func _pair() -> Dictionary:
	return {"player": hero.snapshot_state(), "level": level.snapshot_state()}


func _restore_pair(saved: Dictionary) -> bool:
	if not hero.snapshot_error(saved.player).is_empty() or not level.snapshot_error_with_player(saved.level, saved.player).is_empty(): return false
	return hero.restore_state(saved.player) and level.restore_state(saved.level)


func _reject(malformed: Dictionary, label: String) -> bool:
	var wire: String = Exact.stringify(_pair())
	var before: int = events
	var refused: bool = not level.snapshot_error_with_player(malformed.level, malformed.player).is_empty()
	var restore_refused: bool = not _restore_pair(malformed)
	return _expect(refused and restore_refused and Exact.stringify(_pair()) == wire and events == before, label + " is rejected atomically before whole Player/local/cue/progress mutation")


func _floor_unchanged() -> bool:
	return level.get_node_or_null("Floor/CollisionShape3D") == floor_collision and floor_collision.shape == floor_shape and floor_shape.size == Layout.FLOOR_SIZE and floor_collision.global_transform == floor_frame


func _wait(predicate: Callable, label: String, seconds: float) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while not finishing and Time.get_ticks_msec() <= deadline:
		if predicate.call() == true: return true
		if not await _wait_one_frame(): return false
	return _expect(false, "bounded native observation failed: " + label)


func _wait_one_frame() -> bool:
	if finishing: return false
	if not is_instance_valid(game) or not is_instance_valid(hero) or hero.dead: return _expect(false, "actual living Main/Player lost during native observation")
	if is_instance_valid(level) and not level.contract_error().is_empty(): return _expect(false, "actual O1 contract refused during native observation: " + level.contract_error())
	if paused: return _expect(false, "actual native pause interrupted mechanics observation; no forced focus or Resume")
	await process_frame
	return not finishing


func _last_sequence() -> int:
	var history: Array[Dictionary] = hero.get_world_action_records()
	return 0 if history.is_empty() else int(history.back().sequence)


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > WATCHDOG_MS:
		_expect(false, "native mechanics watchdog reached60 seconds")
		_finish.call_deferred()


func _diagnostic() -> Dictionary:
	var value: Dictionary = {"paused": paused, "elapsed_ms": Time.get_ticks_msec() - started_ms}
	if is_instance_valid(level):
		value["stage"] = level.get("stage"); value["collected_ids"] = level.get("collected_ids")
		value["contract_error"] = level.contract_error(); value["snapshot_error"] = level.last_snapshot_error
		value["capture_error"] = level.get("last_capture_error"); value["encounter_error"] = level.get("last_encounter_error")
	if is_instance_valid(game): value["camera_error"] = game.get("last_camera_framing_error")
	if is_instance_valid(hero): value["hero_position"] = _encode(hero.global_position); value["hero_hp"] = hero.hp
	if is_instance_valid(circuit): value["circuit"] = _encode(circuit.state()); value["circuit_error"] = circuit.last_error; value["circuit_snapshot_error"] = circuit.last_snapshot_error
	if is_instance_valid(impact): value["impact"] = _encode(impact.state()); value["impact_error"] = impact.last_error
	if is_instance_valid(scheduler): value["clock_s"] = scheduler.get_clock(); value["reservations"] = _encode(scheduler.reservations())
	return value


func _expect(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		if first_failure.is_empty(): first_failure = {"label": label, "diagnostic": _diagnostic()}
		push_error(label)
	return ok


func _count_players(node: Node) -> int:
	var count: int = 1 if node is CinderPlayer else 0
	for child: Node in node.get_children(): count += _count_players(child)
	return count


func _encode(value: Variant) -> Variant:
	if value is Vector3: return Codec.vector3(value)
	if value is Vector2: return [value.x, value.y]
	if value is Color: return [value.r, value.g, value.b, value.a]
	if value is Basis: return {"x": _encode(value.x), "y": _encode(value.y), "z": _encode(value.z)}
	if value is Transform3D: return {"basis": _encode(value.basis), "origin": _encode(value.origin)}
	if value is StringName: return String(value)
	if value is Dictionary:
		var converted: Dictionary = {}
		for key: Variant in value: converted[String(key)] = _encode(value[key])
		return converted
	if value is Array:
		var converted: Array = []
		for child: Variant in value: converted.append(_encode(child))
		return converted
	return value


func _refs(node: Node) -> Array[WeakRef]:
	var result: Array[WeakRef] = [weakref(node)]
	for child: Node in node.get_children(): result.append_array(_refs(child))
	return result


func _finish() -> void:
	if finishing: return
	finishing = true
	paused = true
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(scheduler):
		var retired: bool = not scheduler.is_physics_processing() and scheduler.reservations().is_empty()
		for source: Node in [circuit, final_rusher, impact]:
			if is_instance_valid(source): retired = retired and not source.is_physics_processing()
		_expect(retired, "normal level exit retires native sources, impact and Scheduler leases/processing")
	var refs: Array[WeakRef] = []
	if is_instance_valid(game):
		var effects: PixelEffects = game.get("fx") as PixelEffects
		if effects != null: effects.clear()
		refs = _refs(game)
		game.free()
	game = null; level = null; hero = null; circuit = null; final_rusher = null; impact = null; scheduler = null
	paused = false
	await create_timer(0.5, true).timeout
	await process_frame
	var freed: bool = true
	for ref: WeakRef in refs:
		if ref.get_ref() != null: freed = false
	_expect(freed and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal Main cleanup frees all descendants and source/cue groups")
	var report := FileAccess.open(report_path, FileAccess.WRITE)
	if report == null: _expect(false, "unique native mechanics report is writable")
	else:
		report.store_string(JSON.stringify({"checks": checks, "failures": failures, "first_failure": first_failure, "elapsed_ms": Time.get_ticks_msec() - started_ms, "setups": setups, "receipts": receipts, "part_events": part_events, "progress_events": progress_events, "scope": "Actual production Main/O1 override; one canonical starter Player; immutable query floor; paused exact initial Player/local transport and quiet same-world restore; atomic malformed refusals; labeled TEST same-floor one-part placement followed by genuine Area collection/idempotence; natural C30/impact warnings and full native ordinary-response proof; actual public dash/20HP primary during physical C30 recovery; no blast/perk; no early final activation; normal native cleanup. Full route, all permutations/loadouts, fresh disk Continue/Retry, optional campaign story/replay/reward flow and portrait art remain untested."}, "\t"))
		report.close()
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-O1 MECHANICS: %d checks, %d failures; report=%s" % [checks, failures, report_path])
	quit(1 if failures > 0 else 0)
