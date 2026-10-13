extends SceneTree
## TEST ONLY native eye component through the actual shared Main custom-level
## entry. Executes public ordinary Player.slash, not synthetic body damage for
## positive hits. Eligibility comes only from real supported nose recovery,
## its live Scheduler lease/cue, actual floor and current shared camera.
## Same-unit quiet paired restoration, not fresh campaign Save/Continue/Retry.
## No Blink, full route, touch gesture, runtime art, balance or mobile claim.

const MainScene = preload("res://scenes/main.tscn")
const Fixture = preload("res://tests/acts/act1/fixtures/a1_l5_body_owner.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const FixturePath: String = "res://tests/acts/act1/fixtures/a1_l5_body_owner.tscn"
const WatchdogMs: int = 75000
var game: Node
var owner: CinderLevel
var hero: CinderPlayer
var body: StaticBody3D
var nose: Node3D
var scheduler: CinderThreatScheduler
var checks: int = 0
var failures: int = 0
var body_events: int = 0
var phase_events: Array[int] = []
var defeat_events: int = 0
var nested_rejected: bool = false
var started_ms: int = 0
var finishing: bool = false


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	process_frame.connect(_watchdog)
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	game = MainScene.instantiate()
	game.set("level_scene_path", FixturePath)
	root.add_child(game)
	owner = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	if not _expect(owner != null and owner.get_script() == Fixture and hero != null and owner.hero == hero and game.get("world") is Node3D and game.get("camera") is Camera3D and game.get("hud") is GameHUD, "actual shared Main enters disclosed TEST CinderLevel with one native Hero/camera/HUD"):
		await _finish(); return
	body = owner.get("body") as StaticBody3D
	nose = owner.get("nose") as Node3D
	scheduler = owner.get("scheduler") as CinderThreatScheduler
	if not _expect(owner.get("setup_error") == "" and body != null and nose != null and scheduler != null, "actual owning-level eye/nose/Scheduler native bindings succeed: " + String(owner.get("setup_error"))):
		await _finish(); return
	game.call("resume_lab")
	if not await _wait(func() -> bool: return hero.get_threat_response_state().stable, "shared Hero settles on actual authored component floor", 4.0):
		await _finish(); return
	# TEST initial ammo seed only. Later natural reload/accepted-primary credit is
	# retained; the fixture never invokes blast or collects equipment/pickups.
	hero.shells = 0
	body.connect("state_changed", func(_state: Dictionary) -> void: body_events += 1)
	body.connect("phase_changed", _on_phase)
	body.connect("defeated", func(_id: String) -> void: defeat_events += 1)
	var collision: CollisionShape3D = body.call("get_collision") as CollisionShape3D
	if not _expect(body.global_position == Vector3(0.0, 0.0, -9.0) and collision != null and collision.get_parent() == body and collision.shape is BoxShape3D and body.collision_layer == 2 and body.collision_mask == 1 and body.is_in_group("enemies") and not nose.is_in_group("enemies"), "one actual low eye receiver and HP target; separate nose has no enemy health target"):
		await _finish(); return
	if not await _native_registration_negatives(): await _finish(); return
	if not _expect(scheduler.begin_encounter("standard", Fixture.ENCOUNTER_ID, 1), "shared Scheduler begins the actual native component epoch"):
		await _finish(); return
	var initial_hp: float = float(body.get("hp"))
	var closed_hits: int = hero.slash(Vector3.BACK)
	if not _expect(closed_hits == 0 and body.get("hp") == initial_hp and body_events == 0 and phase_events.is_empty() and defeat_events == 0, "real ordinary primary reaches the eye but idle recovery denies HP/hit credit"):
		await _finish(); return
	if not await _wait(func() -> bool: return hero.get_threat_response_state().stable and hero.get_threat_response_state().commitment_remaining_s == 0.0 and hero.get_threat_response_state().primary_cooldown_left_s == 0.0, "closed primary pays its normal action/cooldown", 3.0):
		await _finish(); return
	var hero_initial_hp: float = hero.hp
	for cycle: int in range(1, 4):
		if not await _start_recovery(cycle): await _finish(); return
		if cycle == 1:
			owner.set("provider_fault", "integer_eligibility")
			var hp_before_fault: float = float(body.get("hp"))
			var fault_hits: int = hero.slash(Vector3.BACK)
			owner.set("provider_fault", "")
			if not _expect(fault_hits == 0 and body.get("hp") == hp_before_fault and body_events == 0, "literal integer eligibility rejects during genuine recovery without HP or enemy credit"):
				await _finish(); return
		for index: int in range(4):
			if not await _wait(func() -> bool: return hero.get_threat_response_state().primary_cooldown_left_s == 0.0, "normal primary readiness in actual recovery", 2.0):
				await _finish(); return
			var before: float = float(body.get("hp"))
			var shells_before: int = hero.shells
			var record_count: int = hero.get_world_action_records().size()
			var hit_count: int = hero.slash(Vector3.BACK)
			var history: Array[Dictionary] = hero.get_world_action_records()
			var last: Dictionary = history.back() if not history.is_empty() else {}
			if not _expect(hit_count == 1 and float(body.get("hp")) == maxf(0.0, before - float(hero.equipment.resolved_stats().primary_damage)) and history.size() == record_count + 1 and last.kind == "primary" and last.origin == "player_direct" and last.hits == 1 and hero.shells >= shells_before, "actual shared ordinary primary damages the genuine recovery target once with truthful native action record and no ammo expenditure"):
				await _finish(); return
			if not _expect(body.global_position == Vector3(0.0, 0.0, -9.0) and body.call("get_collision") == collision and collision.shape is BoxShape3D and not collision.disabled and body.collision_layer == 2 and body.collision_mask == 1, "native eye impulse does not move/replace/disable its fixed low collider"):
				await _finish(); return
		if not _expect(int(body.get("phase")) == mini(3, cycle + 1) and float(body.get("hp")) == 240.0 - float(cycle) * 80.0, "ordinary primary crosses the provisional HP phase boundary without skipping") or not await _quiet_pair("phase" + str(cycle)):
			await _finish(); return
		if cycle < 3:
			if not await _wait(func() -> bool: return nose.call("state").status == "complete" and scheduler.source_control_state(nose).cooldown == null and hero.get_threat_response_state().primary_cooldown_left_s == 0.0, "original nose recovery/cooldown expires without retiming", 5.0):
				await _finish(); return
	if not _expect(phase_events == [2, 3] and nested_rejected and defeat_events == 1 and body_events == 12 and body.get("dead") == true and not body.is_in_group("enemies") and body.visible and body.is_visible_in_tree() and hero.hp == hero_initial_hp, "phase/defeat observers see committed HP, reject reentrant damage, retain spent body and avoid nose damage from the actual outside-cone starting position"):
		await _finish(); return
	var repeated: Dictionary = body.call("take_damage", 1.0, Vector3.ZERO)
	_expect(not repeated.accepted and repeated.hp_damage == 0.0 and defeat_events == 1 and body.get("hp") == 0.0, "dead native receiver denies repeated HP/death credit")
	await _finish()


func _on_phase(id: String, next_phase: int) -> void:
	phase_events.append(next_phase)
	var before: float = float(body.get("hp"))
	var result: Dictionary = body.call("take_damage", 1.0, Vector3.ZERO)
	nested_rejected = not result.accepted and result.hp_damage == 0.0 and body.get("hp") == before and id == Fixture.BODY_ID and int(body.get("phase")) == next_phase


func _start_recovery(cycle: int) -> bool:
	var preview: Dictionary = nose.call("preview_start", owner.call("context"))
	if not _expect(preview.get("accepted", false), "actual nose preview proves supported ordinary escape/eye opening: " + String(preview.get("reason", ""))): return false
	owner.call("frame_preview", preview)
	if not await _wait(func() -> bool: return game.call("camera_framing_error", owner.get("required_points")) == "", "current shared camera contains actual source/footprint/proved landing/eye", 4.0): return false
	# Camera settling advances the real clock: acquire a fresh exact preview.
	preview = nose.call("preview_start", owner.call("context"))
	var answer: Dictionary = nose.call("start", owner.call("context"), null, null, preview)
	if not _expect(answer.get("accepted", false) and nose.call("state").cycle == cycle and answer.reservation.opening_position == body.global_position and answer.reservation.source_instance_id == nose.get_instance_id(), "actual nose owns a new native fixed-cone exchange, opening at the actual eye: " + String(answer.get("reason", ""))): return false
	var hp_before: float = float(body.get("hp"))
	if not _expect(hero.slash(Vector3.BACK) == 0 and body.get("hp") == hp_before, "actual warning holds the eye closed to ordinary primary"):
		return false
	return await _wait(func() -> bool: return nose.call("state").phase == "recovery", "real shared-clock nose warning/lock/active reaches recovery", 5.0)


func _unit() -> Dictionary:
	var player: Dictionary = hero.snapshot_state()
	var control: Dictionary = scheduler.snapshot_state(owner.call("bindings"))
	return {"player": player, "scheduler": control, "body": body.call("snapshot_state", control, player), "nose": nose.call("snapshot_state", owner.call("bindings"))}


func _quiet_pair(label: String) -> bool:
	paused = true
	await process_frame
	var unit: Dictionary = _unit()
	if not _expect(not unit.player.is_empty() and not unit.scheduler.is_empty() and not unit.body.is_empty() and not unit.nose.is_empty(), label + " captures complete actual paused Player/Scheduler/body/nose unit: " + String(body.get("last_snapshot_error"))): return false
	var wire: String = Exact.stringify(unit)
	var count: int = body_events + phase_events.size() + defeat_events
	await create_timer(0.04, true).timeout
	if not _expect(wire == Exact.stringify(_unit()), label + " paused resources/clocks/phase/native unit freezes exactly"): return false
	var denied: Dictionary = body.call("take_damage", 1.0, Vector3.ZERO)
	if not _expect(not denied.accepted and wire == Exact.stringify(_unit()), label + " paused receiver denies damage without mutating paired state"): return false
	var parsed: Dictionary = Exact.parse(wire)
	if not _expect(parsed.get("accepted", false), label + " exact transport preserves native numeric identities"): return false
	var saved: Dictionary = parsed.value
	var malformed: Dictionary = saved.body.duplicate(true)
	malformed["phase"] = 1 if saved.body.phase != 1 else 2
	if not _expect(body.call("snapshot_error", malformed, saved.scheduler, saved.player) != "" and wire == Exact.stringify(_unit()), label + " incoherent HP/phase rejects purely"): return false
	malformed = saved.body.duplicate(true)
	malformed["clock_s"] = float(saved.body.clock_s) + 0.001
	if not _expect(body.call("snapshot_error", malformed, saved.scheduler, saved.player) != "" and wire == Exact.stringify(_unit()), label + " changed paired eye clock rejects purely"): return false
	var bindings: Dictionary = owner.call("bindings")
	if not _expect(hero.snapshot_error(saved.player) == "" and scheduler.snapshot_error(saved.scheduler, bindings) == "" and body.call("snapshot_error", saved.body, saved.scheduler, saved.player) == "" and nose.call("snapshot_error", saved.nose, bindings, saved.scheduler) == "", label + " complete original component aggregate prevalidates independently"): return false
	if not _expect(hero.restore_state(saved.player) and scheduler.restore_state(saved.scheduler, bindings) and body.call("restore_state", saved.body, saved.scheduler, saved.player) and nose.call("restore_state", saved.nose, bindings), label + " quiet actual Player → Scheduler → body/nose restoration succeeds"): return false
	if not _expect(wire == Exact.stringify(_unit()) and body_events + phase_events.size() + defeat_events == count, label + " same-unit restoration preserves exact clock/HP/dedupes and emits no observer signals"): return false
	game.call("resume_lab")
	return _expect(not paused, label + " resumes through public shared Main")


func _native_registration_negatives() -> bool:
	paused = true
	await process_frame
	var unit: Dictionary = _unit()
	if not _expect(not unit.body.is_empty(), "native idle eye supports actual paired paused transport before fault injection"): return false
	var collision: CollisionShape3D = body.call("get_collision") as CollisionShape3D
	var box: Shape3D = collision.shape
	var owner_id: int = body.shape_find_owner(0)
	var transform: Transform3D = body.shape_owner_get_transform(owner_id)
	body.shape_owner_set_transform(owner_id, Transform3D(transform.basis, transform.origin + Vector3.RIGHT))
	if not _expect(collision.transform == transform and body.call("get_native_bindings").is_empty() and body.call("snapshot_error", unit.body, unit.scheduler, unit.player) != "", "actual registered eye transform mutation rejects despite unchanged CollisionShape node pose"): return false
	body.shape_owner_set_transform(owner_id, transform)
	body.shape_owner_clear_shapes(owner_id)
	body.shape_owner_add_shape(owner_id, box.duplicate() as Shape3D)
	if not _expect(collision.shape == box and body.call("get_native_bindings").is_empty() and body.call("snapshot_error", unit.body, unit.scheduler, unit.player) != "", "equivalent registered eye shape replacement rejects despite unchanged node resource"): return false
	body.shape_owner_clear_shapes(owner_id)
	body.shape_owner_add_shape(owner_id, box)
	var floor_collision: CollisionShape3D = owner.get_node("Floor/Collision") as CollisionShape3D
	var floor: StaticBody3D = floor_collision.get_parent() as StaticBody3D
	var floor_owner: int = floor.shape_find_owner(0)
	var floor_transform: Transform3D = floor.shape_owner_get_transform(floor_owner)
	var floor_shape: Shape3D = floor_collision.shape
	floor.shape_owner_set_transform(floor_owner, Transform3D(floor_transform.basis, floor_transform.origin + Vector3.DOWN))
	if not _expect(floor_collision.transform == floor_transform and body.call("get_native_bindings").is_empty() and body.call("snapshot_error", unit.body, unit.scheduler, unit.player) != "", "actual support registration mutation rejects without trusting cached/node-only floor support"): return false
	floor.shape_owner_set_transform(floor_owner, floor_transform)
	floor.shape_owner_clear_shapes(floor_owner)
	floor.shape_owner_add_shape(floor_owner, floor_shape.duplicate() as Shape3D)
	if not _expect(floor_collision.shape == floor_shape and body.call("get_native_bindings").is_empty(), "equivalent registered floor resource replacement rejects"): return false
	floor.shape_owner_clear_shapes(floor_owner)
	floor.shape_owner_add_shape(floor_owner, floor_shape)
	if not _expect(body.call("get_collision") == collision and Exact.stringify(_unit()) == Exact.stringify(unit), "restoring the original actual native registrations recovers the unchanged paired unit"): return false
	game.call("resume_lab")
	return true


func _wait(condition: Callable, message: String, seconds: float) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline and not finishing:
		if condition.call(): return _expect(true, message)
		await process_frame
	return _expect(false, message)


func _expect(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("L5 eye component: " + message)
	return ok


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > WatchdogMs:
		_expect(false, "bounded native component watchdog expired")
		_finish.call_deferred()


func _finish() -> void:
	if finishing: return
	finishing = true
	paused = true
	var refs: Array[WeakRef] = []
	for node: Node in [owner, body, nose, scheduler, hero, game]:
		if is_instance_valid(node): refs.append(weakref(node))
	if is_instance_valid(owner): owner.exit_level()
	if is_instance_valid(game): game.queue_free()
	paused = false
	await process_frame
	await process_frame
	_expect(refs.all(func(ref: WeakRef) -> bool: return ref.get_ref() == null), "normal Main/level/Hero/eye/nose/Scheduler disposal releases all native nodes")
	print("L5 eye native component: %d checks, %d failures; no full-level/gesture/campaign-save/art claim" % [checks, failures])
	quit(0 if failures == 0 else 1)
