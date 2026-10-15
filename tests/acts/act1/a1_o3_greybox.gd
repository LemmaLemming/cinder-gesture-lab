extends SceneTree
## SOURCE ONLY until Root imports/runs through the shared dev.py queue.
## Production Main and native C32/Scheduler. TEST Hero same-floor bell placement;
## two disclosed negative body_entered deliveries. Public request_dash/slash only.
## No actor HP/phase/clock/proof/custody writes, private simulation or GUI claim.

const MainScene = preload("res://scenes/main.tscn")
const Layout = preload("res://scripts/acts/act1/royal_rehearsal_layout.gd")
const Equipment = preload("res://scripts/equipment.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const LEVEL_PATH: String = "res://scenes/acts/act1/a1_o3.tscn"
const WATCHDOG_MS: int = 60000
const POSITION_TOLERANCE: float = 0.035

var game: Node
var level: CinderLevel
var hero: CinderPlayer
var scheduler: CinderThreatScheduler
var sources: Dictionary = {}
var bell: Area3D
var floor_collision: CollisionShape3D
var floor_shape: BoxShape3D
var floor_frame: Transform3D
var source_birth: Dictionary = {}
var source_hp: Dictionary = {}
var checks: int = 0
var failures: int = 0
var check_rows: Array[Dictionary] = []
var first_failure: Dictionary = {}
var started_ms: int
var report_path: String
var finishing: bool = false
var scope_complete: bool = false
var negative_contact_delivery: bool = false
var old_fps: int
var old_audio: AudioBusLayout
var initial_hp: float
var setups: Array[Dictionary] = []
var receipts: Array[Dictionary] = []
var actions: Array[Dictionary] = []
var admissions: Dictionary = {}
var admission_rows: Array[Dictionary] = []
var phases: Dictionary = {}
var hit_events: Array[Dictionary] = []
var bell_contacts: Array[Dictionary] = []
var progress_events: Array[Dictionary] = []
var cancellations: Array[Dictionary] = []
var attack_id: String = ""
var attack_lease: String = ""
var attack_cycle: int = 0


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	old_fps = Engine.max_fps; old_audio = AudioServer.generate_bus_layout()
	report_path = "res://.cinder/a1-o3-greybox-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	process_frame.connect(_watchdog)
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	paused = true
	game = MainScene.instantiate(); game.set("level_scene_path", LEVEL_PATH)
	root.add_child(game)
	paused = true # Main.reset_lab unpauses synchronously; latch before yielding.
	await process_frame; await process_frame
	level = game.get("active_level") as CinderLevel; hero = game.get("player") as CinderPlayer
	if not _expect(level != null and hero != null and level.scene_file_path == LEVEL_PATH and level.level_id == Layout.LEVEL_ID and level.hero == hero and level.shared_shell == game and level.contract_error().is_empty(), "production Main loads the actual O3/shared Player contract"): await _finish(); return
	if not _expect(_count_players(game) == 1 and hero.global_position == Layout.SPAWN and hero.global_position == level.spawn_position() and hero.equipment.snapshot() == Equipment.STARTER, "one canonical starter Player begins at the exact authored O3 spawn"): await _finish(); return
	sources = (level.get("sources") as Dictionary).duplicate(); scheduler = level.get("scheduler") as CinderThreatScheduler
	bell = level.get_node_or_null("BellArea") as Area3D
	floor_collision = level.get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
	if not _expect(scheduler != null and bell != null and floor_collision != null and floor_collision.shape is BoxShape3D and Codec.keys_error(sources, Layout.SOURCE_IDS).is_empty() and sources.size() == 6 and _count_native_sources(game) == 6, "all six finite native C32 sources, real bell Area, floor and Scheduler exist"): await _finish(); return
	floor_shape = floor_collision.shape as BoxShape3D; floor_frame = floor_collision.global_transform
	if not _expect(_floor_unchanged() and floor_collision.global_position == Vector3(0, -0.5, 0) and floor_collision.global_basis == Basis.IDENTITY and scheduler.get_clock() == 0.0 and scheduler.encounter_profile().is_empty() and scheduler.reservations().is_empty(), "pristine entrance retains the 14x16 supported floor and genuinely unbegun Scheduler"): await _finish(); return
	for id: String in Layout.SOURCE_IDS:
		var actor := sources[id] as Act1MushroomSelenite
		var state: Dictionary = actor.pure_presentation_state() if actor != null else {}
		if not _expect(not state.is_empty() and state.source_id == id and state.entity_id == "C32" and state.role_id == "A1-E3" and state.dormant and not state.dead and state.hp == 24.0 and not state.approach_enabled and not actor.visible and not actor.is_in_group("enemies") and actor.body_binding_error().is_empty() and actor.art_binding_error().is_empty(), "pristine finite C32 identity, HP, body/art and dormant custody: " + id): await _finish(); return
		source_hp[id] = actor.hp; source_birth[id] = actor.global_position
		actor.state_changed.connect(_notice_phase.bind(id))
		actor.hit_resolved.connect(_notice_hit.bind(id))
	var initial: Dictionary = level.call("rehearsal_state")
	if not _expect(initial.exercise_index == 0 and initial.stage == "awaiting_bell" and initial.completed_exercises.is_empty() and not initial.checkpoint_published and initial.bell_armed and not level.is_completed(), "initial bell awaits exercise one without earned checkpoint or completion"): await _finish(); return
	initial_hp = hero.hp
	hero.world_action_executed.connect(func(record: Dictionary) -> void: actions.append(record.duplicate(true)))
	level.connect("native_admission_published", _notice_admission)
	bell.body_entered.connect(_notice_bell)
	scheduler.reservation_invalidated.connect(func(id: String, reason: String) -> void: cancellations.append({"reservation_id": id, "reason": reason, "clock_s": scheduler.get_clock()}))
	level.checkpoint_requested.connect(func(id: String, checkpoint: String, kind: String) -> void: progress_events.append({"kind": "checkpoint", "level_id": id, "id": checkpoint, "boundary": kind}))
	level.completion_requested.connect(func(id: String, completion: String) -> void: progress_events.append({"kind": "completion", "level_id": id, "id": completion}))
	level.contact_exit_requested.connect(func(id: String, exit_id: String) -> void: progress_events.append({"kind": "exit", "level_id": id, "id": exit_id}))
	receipts.append({"label": "actual pristine paused entrance", "host": _portable(initial), "player": hero.snapshot_state(), "floor_frame": _portable(floor_frame), "source_birth": _portable(source_birth)})
	game.call("resume_lab")
	if not await _wait(func() -> bool: return hero.get_threat_response_state().stable and not bell.overlaps_body(hero), "actual Hero settles on the floor outside the bell", 4.0): await _finish(); return
	if not _expect(level.call("rehearsal_state").stage == "awaiting_bell" and scheduler.encounter_profile().is_empty() and admissions.is_empty(), "normal outside-bell settling cannot start an exercise"): await _finish(); return
	if not _negative_contact(level.get_node("Floor"), "foreign Floor body while awaiting first contact"): await _finish(); return
	# TEST placement only. Native floor registration, Area overlap, signal delivery,
	# deferred guarded activation, camera and all native actor state remain real.
	var contact_position: Vector3 = Layout.BELL_POSITION + Vector3(0, 0.005, 0)
	hero.global_position = contact_position; hero.velocity = Vector3.ZERO
	setups.append({"kind": "TEST same-floor Hero position and zero velocity only", "position": _portable(contact_position), "scope": "No earned movement, recognizer or gesture credit"})
	if not await _wait(func() -> bool: return level.call("rehearsal_state").stage == "active", "genuine Area contact and deferred host guard activate the first pair", 8.0): await _finish(); return
	var active: Dictionary = level.call("rehearsal_state")
	if not _expect(bell.overlaps_body(hero) and bell_contacts.any(func(row: Dictionary) -> bool: return not row.injected_negative and row.body_instance_id == hero.get_instance_id() and row.actual_overlap) and active.exercise_index == 0 and not active.bell_armed and active.completed_exercises.is_empty() and not scheduler.encounter_profile().is_empty(), "one real Hero overlap starts only the first exercise and consumes bell readiness"): await _finish(); return
	if not _negative_contact(hero, "duplicate Hero contact while the first pair is active"): await _finish(); return
	for id: String in Layout.SOURCE_IDS:
		var actor := sources[id] as Act1MushroomSelenite
		if not _expect(actor.dormant == (id not in Layout.group_ids(0)) and actor.hp == source_hp[id] and _distance(actor.global_position, source_birth[id]) == 0.0 and absf(actor.global_position.y - (source_birth[id] as Vector3).y) <= POSITION_TOLERANCE, "first contact activates only the two original parallel sources at their authored planar positions: " + id): await _finish(); return
	if not await _wait(_first_warning, "first native C32 warning has a published current admission", 12.0): await _finish(); return
	var actor: Act1MushroomSelenite = sources[attack_id]
	var first: Dictionary = actor.pure_presentation_state()
	attack_lease = String(first.reservation_id); attack_cycle = int(first.cycle)
	var answer: Dictionary = admissions[attack_lease]
	var proof: Dictionary = answer.proof.duplicate(true)
	var reservation: Dictionary = answer.reservation.duplicate(true)
	if not _expect(answer.accepted == true and answer.armed == true and answer.reservation_id == attack_lease and reservation.source_instance_id == actor.get_instance_id() and proof.accepted == true and proof.uses_blast == false and proof.uses_invulnerability == false and proof.proof_scope == "static_box_floor_full_dash_stationary_primary", "first warning retains actual C32 identity, armed lease and ordinary-only native proof"): await _finish(); return
	if not _expect(reservation.geometry.kind == "lane" and absf((reservation.geometry["to"] as Vector3).distance_to(reservation.geometry["from"]) - 2.0) <= POSITION_TOLERANCE and float(reservation.geometry.radius) == 0.38 and float(proof.primary_time_s) >= float(reservation.active_until_s) and float(proof.response_complete_s) < float(reservation.recovery_until_s), "unchanged C32 lane admits an ordinary primary inside its original recovery"): await _finish(); return
	if not _framing("actual first warning"): await _finish(); return
	var escape: Dictionary = {}
	var returning: Dictionary = {}
	for segment: Dictionary in proof.path:
		if segment.kind == "escape_dash": escape = segment
		elif segment.kind == "positioning_dash": returning = segment
	if not _expect(not escape.is_empty() and _distance(hero.global_position, escape["from"]) <= POSITION_TOLERANCE, "native proof starts at the actual current supported Hero position"): await _finish(); return
	if not await _wait(func() -> bool: return scheduler.get_clock() >= float(escape.start_s), "native recognition and readiness boundary", 4.0): await _finish(); return
	if not await _dash_to(escape["to"], "native proof escape"): await _finish(); return
	if not _framing("actual stopped escape landing"): await _finish(); return
	for phase: String in ["warning", "lock", "active", "recovery"]:
		var key: String = _phase_key(attack_id, attack_cycle, attack_lease, phase)
		if not await _wait(func() -> bool: return phases.has(key), "same actual C32 cycle reaches " + phase, 7.0): await _finish(); return
		var row: Dictionary = phases[key]
		if not _expect(row.state.status == "running" and row.state.cycle == attack_cycle and row.state.reservation_id == attack_lease and row.state.source_position == first.source_position and row.state.velocity == Vector3.ZERO, "native " + phase + " observation retains the original stationary source, cycle and lease"): await _finish(); return
	if not returning.is_empty():
		if not await _wait(func() -> bool: return scheduler.get_clock() >= float(returning.start_s), "native recovery return boundary", 4.0): await _finish(); return
		if not await _dash_to(returning["to"], "native proof return"): await _finish(); return
	if not await _wait(func() -> bool: return scheduler.get_clock() >= float(proof.primary_time_s) and _primary_ready(), "actual ordinary-primary opening and readiness", 4.0): await _finish(); return
	if not _framing("actual primary opening"): await _finish(); return
	if not _primary(actor, proof, reservation): await _finish(); return
	if not _expect(_future_pristine() and progress_events.is_empty() and level.call("rehearsal_state").exercise_index == 0 and level.call("rehearsal_state").completed_exercises.is_empty() and not level.is_completed() and _floor_unchanged() and hero.hp == initial_hp and hit_events.is_empty(), "focused surviving-guard cycle leaves four later sources pristine, all progress unearned, floor and Hero HP intact"): await _finish(); return
	receipts.append({"label": "final focused parallel state", "diagnostic": _diagnostic()})
	scope_complete = true
	await _finish()


func _negative_contact(body: Node3D, label: String) -> bool:
	var before: Dictionary = _contact_boundary()
	negative_contact_delivery = true
	bell.body_entered.emit(body)
	negative_contact_delivery = false
	var after: Dictionary = _contact_boundary()
	setups.append({"kind": "TEST negative body_entered signal delivery only", "label": label, "body_instance_id": body.get_instance_id(), "actual_overlap": bell.overlaps_body(body)})
	receipts.append({"label": label, "before": _portable(before), "after": _portable(after)})
	return _expect(_same(_portable(before), _portable(after)), label + " preserves complete host metadata and native source controls synchronously")


func _contact_boundary() -> Dictionary:
	var controls: Dictionary = {}
	for id: String in sources: controls[id] = scheduler.source_control_state(sources[id])
	return {"host": level.call("rehearsal_state"), "clock_s": scheduler.get_clock(), "profile": scheduler.encounter_profile(), "sources": _source_states(), "controls": controls, "progress": progress_events.duplicate(true), "admissions": admission_rows.duplicate(true)}


func _first_warning() -> bool:
	for id: String in Layout.group_ids(0):
		var state: Dictionary = sources[id].call("pure_presentation_state")
		if state.status == "running" and state.phase == "warning" and admissions.has(String(state.reservation_id)):
			attack_id = id
			return true
	return false


func _dash_to(destination: Vector3, label: String) -> bool:
	var state: Dictionary = hero.get_threat_response_state()
	var direction: Vector3 = destination - hero.global_position
	direction.y = 0.0
	var distance: float = float(hero.equipment.resolved_stats().dash_distance)
	if not _expect(state.stable and float(state.dash_cooldown_left_s) == 0.0 and float(state.commitment_remaining_s) == 0.0 and absf(direction.length() - distance) <= POSITION_TOLERANCE, label + " uses a full ordinary dash from actual stable input readiness"): return false
	var sequence: int = _sequence()
	var start: Vector3 = hero.global_position
	var clock_s: float = scheduler.get_clock()
	if not _expect(hero.request_dash(direction), label + " is accepted by public Player.request_dash"): return false
	if not await _wait(func() -> bool: return hero.get_threat_response_state().stable and not hero.get_committed_dash_state().active, label + " reaches a deliberate native stopped landing", 4.0): return false
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	receipts.append({"label": label, "requested_at_scheduler_s": clock_s, "from": _portable(start), "native_proof_destination": _portable(destination), "actual_landing": _portable(hero.global_position), "actions": _portable(records)})
	return _expect(records.size() == 1 and records[0].kind == "dash" and records[0].origin == "player_direct" and not records[0].collision_shortened and absf(float(records[0].distance) - distance) <= POSITION_TOLERANCE and records[0].path.size() >= 2 and _distance(hero.global_position, destination) <= POSITION_TOLERANCE and hero.hp == initial_hp, label + " executes one real full-distance dash and preserves Hero HP; no gesture claim")


func _primary(actor: Act1MushroomSelenite, proof: Dictionary, reservation: Dictionary) -> bool:
	var before: Dictionary = actor.pure_presentation_state()
	var direction: Vector3 = actor.global_position - hero.global_position
	direction.y = 0.0
	if not _expect(_primary_ready() and before.phase == "recovery" and before.reservation_id == attack_lease and before.cycle == attack_cycle and scheduler.get_clock() >= float(proof.primary_time_s) and scheduler.get_clock() < float(reservation.recovery_until_s) and _distance(hero.global_position, proof.attack_position) <= POSITION_TOLERANCE and direction.length() <= float(hero.equipment.resolved_stats().primary_range), "real primary begins in the same proved native recovery from ordinary close range"): return false
	var sequence: int = _sequence()
	var shells: int = hero.shells
	var hp: float = actor.hp
	var native_clock: float = scheduler.get_clock()
	var result: int = hero.slash(direction)
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	var after: Dictionary = actor.pure_presentation_state()
	var control: Dictionary = scheduler.source_control_state(actor)
	receipts.append({"label": "actual ordinary primary in native recovery", "scheduler_s": native_clock, "source_id": attack_id, "before": _portable(before), "after": _portable(after), "controller": _portable(control), "returned_enemy_hits": result, "actions": _portable(records), "shells_before": shells, "shells_after": hero.shells})
	if not _expect(result == 1 and records.size() == 1 and records[0].kind == "primary" and records[0].origin == "player_direct" and records[0].hits == 1 and records[0].direction == hero.facing and actor.hp == hp - float(hero.equipment.resolved_stats().primary_damage) and actor.hp > 0.0 and not actor.dead and hero.shells >= shells, "one genuine public ordinary primary damages exactly one surviving guard without spending blast ammo"): return false
	if not _expect(after.last_cancel_reason == "actual_player_damage" and after.reservation_id.is_empty() and control.reservations.is_empty() and control.cooldown != null and float(control.cooldown.ready_s) == float(reservation.cooldown_until_s) and cancellations.any(func(row: Dictionary) -> bool: return row.reservation_id == attack_lease and row.reason == "actual_player_damage" and row.clock_s == native_clock), "real damage cancels its lease while retaining the original native cooldown deadline"): return false
	var cooldown_before: Dictionary = hero.get_threat_response_state()
	var actor_before: Dictionary = actor.pure_presentation_state()
	var refused: int = hero.slash(direction)
	var cooldown_after: Dictionary = hero.get_threat_response_state()
	return _expect(refused == 0 and hero.get_world_action_records(sequence).size() == 1 and _same(_portable(actor_before), _portable(actor.pure_presentation_state())) and float(cooldown_after.primary_cooldown_left_s) == float(cooldown_before.primary_cooldown_left_s) and float(cooldown_after.primary_cooldown_left_s) > 0.0, "immediate second primary is refused by unchanged real Player cooldown without another action or actor mutation")


func _primary_ready() -> bool:
	if paused or not is_instance_valid(hero) or hero.dead: return false
	var state: Dictionary = hero.get_threat_response_state()
	return state.stable and float(state.commitment_remaining_s) == 0.0 and float(state.primary_cooldown_left_s) == 0.0


func _future_pristine() -> bool:
	for id: String in Layout.SOURCE_IDS:
		if id in Layout.group_ids(0): continue
		var actor := sources[id] as Act1MushroomSelenite
		var state: Dictionary = actor.pure_presentation_state()
		if not state.dormant or state.dead or state.hp != source_hp[id] or actor.global_position != source_birth[id] or not state.reservation_id.is_empty() or state.cycle != 0 or actor.visible or actor.is_in_group("enemies") or not actor.body_binding_error().is_empty() or not actor.art_binding_error().is_empty(): return false
	return true


func _notice_admission(id: String, answer: Dictionary) -> void:
	admission_rows.append({"source_id": id, "answer": _portable(answer)})
	if answer.get("accepted") == true and answer.get("armed") == true:
		admissions[String(answer.get("reservation_id", ""))] = answer.duplicate(true)


func _notice_phase(state: Dictionary, id: String) -> void:
	var lease: String = String(state.get("reservation_id", ""))
	if state.get("status") != "running" or lease.is_empty(): return
	var key: String = _phase_key(id, int(state.cycle), lease, String(state.phase))
	if not phases.has(key): phases[key] = {"source_id": id, "clock_s": scheduler.get_clock(), "state": state.duplicate(true)}


func _notice_hit(hero_id: String, cycle: int, result: Dictionary, source_id: String) -> void:
	if result.get("accepted", false): hit_events.append({"source_id": source_id, "hero_id": hero_id, "cycle": cycle, "result": result.duplicate(true)})


func _notice_bell(body: Node3D) -> void:
	bell_contacts.append({"injected_negative": negative_contact_delivery, "body_instance_id": body.get_instance_id(), "actual_overlap": bell.overlaps_body(body), "hero_instance_id": hero.get_instance_id(), "clock_s": hero.get_world_action_clock()})


func _phase_key(id: String, cycle: int, lease: String, phase: String) -> String:
	return "%s/%d/%s/%s" % [id, cycle, lease, phase]


func _framing(label: String) -> bool:
	var points: Array = level.camera_framing_points()
	return _expect(not points.is_empty() and level.last_camera_framing_error.is_empty() and String(game.call("camera_framing_error", points)).is_empty(), label + " has actual current source/footprint/response containment; no pixel-review claim")


func _wait(predicate: Callable, label: String, native_seconds: float) -> bool:
	var deadline: float = hero.get_world_action_clock() + native_seconds
	while not finishing:
		if paused or not is_instance_valid(game) or not is_instance_valid(hero) or hero.dead or not level.contract_error().is_empty(): return _expect(false, "native observation lost living unpaused Main contract: " + label)
		if hero.get_world_action_clock() > deadline: return _expect(false, "bounded native observation failed: " + label)
		if predicate.call() == true: return true
		await process_frame
	return false


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > WATCHDOG_MS:
		_expect(false, "O3 greybox watchdog reached 60 wall seconds")
		_finish.call_deferred()


func _floor_unchanged() -> bool:
	return level.get_node_or_null("Floor/CollisionShape3D") == floor_collision and floor_collision.shape == floor_shape and floor_shape.size == Vector3(14, 1, 16) and floor_collision.global_transform == floor_frame and not floor_collision.disabled


func _source_states() -> Dictionary:
	var result: Dictionary = {}
	for id: String in sources:
		if is_instance_valid(sources[id]): result[id] = sources[id].call("pure_presentation_state")
	return result


func _diagnostic() -> Dictionary:
	var result: Dictionary = {"paused": paused, "elapsed_ms": Time.get_ticks_msec() - started_ms}
	if is_instance_valid(level): result["host"] = _portable(level.call("rehearsal_state")); result["contract_error"] = level.contract_error()
	if is_instance_valid(game): result["camera"] = _portable(game.call("get_camera_framing_state"))
	if is_instance_valid(hero): result["hero"] = _portable(hero.get_threat_response_state()); result["hero_hp"] = hero.hp
	if is_instance_valid(scheduler): result["scheduler_s"] = scheduler.get_clock(); result["profile"] = scheduler.encounter_profile()
	result["sources"] = _portable(_source_states())
	return result


func _expect(ok: bool, label: String) -> bool:
	checks += 1
	check_rows.append({"number": checks, "passed": ok, "label": label, "elapsed_ms": Time.get_ticks_msec() - started_ms})
	if not ok:
		failures += 1
		if first_failure.is_empty(): first_failure = {"label": label, "diagnostic": _diagnostic()}
		push_error(label)
	else: print("PASS ", checks, ": ", label)
	return ok


func _sequence() -> int:
	var history: Array[Dictionary] = hero.get_world_action_records()
	return 0 if history.is_empty() else int(history.back().sequence)


func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = Exact.stringify(left)
	return not encoded.is_empty() and encoded == Exact.stringify(right)


func _distance(left: Vector3, right: Vector3) -> float:
	return Vector2(left.x - right.x, left.z - right.z).length()


func _count_players(node: Node) -> int:
	var count: int = 1 if node is CinderPlayer else 0
	for child: Node in node.get_children(): count += _count_players(child)
	return count


func _count_native_sources(node: Node) -> int:
	var count: int = 1 if node is Act1MushroomSelenite else 0
	for child: Node in node.get_children(): count += _count_native_sources(child)
	return count


func _portable(value: Variant) -> Variant:
	if value is Vector3: return Codec.vector3(value)
	if value is Vector2: return [value.x, value.y]
	if value is Basis: return {"x": _portable(value.x), "y": _portable(value.y), "z": _portable(value.z)}
	if value is Transform3D: return {"basis": _portable(value.basis), "origin": _portable(value.origin)}
	if value is StringName: return String(value)
	if value is Object: return {"native_class": value.get_class(), "instance_id": value.get_instance_id()} if is_instance_valid(value) else null
	if value is Dictionary:
		var converted: Dictionary = {}
		for key: Variant in value: converted[String(key)] = _portable(value[key])
		return converted
	if value is Array:
		var converted: Array = []
		for child: Variant in value: converted.append(_portable(child))
		return converted
	return value


func _refs(node: Node) -> Array[WeakRef]:
	var result: Array[WeakRef] = [weakref(node)]
	for child: Node in node.get_children(): result.append_array(_refs(child))
	return result


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(scheduler):
		var retired: bool = not scheduler.is_physics_processing() and scheduler.reservations().is_empty()
		for actor: Act1MushroomSelenite in sources.values(): retired = retired and not actor.is_physics_processing() and not actor.is_in_group("enemies")
		_expect(retired and level.hero == null and level.shared_shell == null, "public level exit retires the actual native sources, leases and shared aliases")
	var refs: Array[WeakRef] = []
	if is_instance_valid(game):
		var fx := game.get("fx") as PixelEffects
		if is_instance_valid(fx): fx.clear()
		refs = _refs(game)
		game.free()
	game = null; level = null; hero = null; scheduler = null; bell = null
	sources.clear(); admissions.clear(); floor_collision = null; floor_shape = null
	paused = false
	await create_timer(0.5, true).timeout; await process_frame
	var freed: bool = true
	for ref: WeakRef in refs:
		if ref.get_ref() != null: freed = false
	_expect(freed and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("environment_attack_targets").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal Main teardown releases descendants and native enemy/contact/cue groups")
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	var exact_observations: String = Exact.stringify(_portable({"receipts": receipts, "actions": actions, "admissions": admission_rows, "phases": phases, "cancellations": cancellations}))
	_expect(not exact_observations.is_empty(), "native observations retain exact scalar types and bits in the report")
	var output := FileAccess.open(report_path, FileAccess.WRITE)
	if output == null: _expect(false, "unique O3 greybox JSON report is writable")
	else:
		output.store_string(JSON.stringify({"complete": scope_complete and failures == 0, "checks": checks, "passes": checks - failures, "failures": failures, "check_rows": check_rows, "first_failure": first_failure, "elapsed_ms": Time.get_ticks_msec() - started_ms, "report_path": report_path, "execution": {"script": get_script().resource_path, "native_args": Array(OS.get_cmdline_args()), "user_args": Array(OS.get_cmdline_user_args()), "pid": OS.get_process_id()}, "required_runner_command": "python3 scripts/dev/dev.py engine --headless --path . --script tests/acts/act1/a1_o3_greybox.gd", "setups": setups, "receipts": receipts, "world_actions": _portable(actions), "admissions": admission_rows, "phase_observations": _portable(phases), "bell_contacts": bell_contacts, "hit_events": hit_events, "cancellations": cancellations, "progress_events": progress_events, "exact_observations": exact_observations, "scope": "Production Main at540x1170; one starter Hero/six finite native C32 sources, original14x16 floor; disclosed TEST Hero same-floor bell placement; actual Area contact/deferred first-pair activation; separate injected foreign/duplicate negative signals; native current lease/proof/warning-lock-active-recovery; public real dash/primary and intact original source/Player cooldowns; later four pristine; normal cleanup. No GUI/recognizer/earned traversal, pixel inspection, full route, later exercise, whole Save/Continue/Retry, completion/stamp, all-kit, all-preset, latency or FPS credit."}, "\t"))
		output.close()
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-O3 GREYBOX: complete=%s, %d checks, %d passes, %d failures; report=%s" % [scope_complete and failures == 0, checks, checks - failures, failures, report_path])
	quit(1 if failures > 0 else 0)
