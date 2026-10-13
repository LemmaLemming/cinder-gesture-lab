extends SceneTree
## Isolated real-player Scout exchange fixture. No forced recovery, blast,
## private scheduler/controller or claim of the complete Horsell route/portrait.

const PlayerScript = preload("res://scripts/player.gd")
const EffectsScript = preload("res://scripts/effects.gd")
const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const ActorScript = preload("res://scripts/acts/act2/ray_scout_actor.gd")
const ExchangeScript = preload("res://scripts/acts/act2/ray_scout_exchange.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const SCOUT_ID: String = "A2-L1:fixture-ray"
const SECOND_ID: String = "A2-L1:second-ray"
const ENCOUNTER_ID: String = "A2-L1:ray-fixture"
var _checks: int = 0
var _failures: int = 0
var _fixtures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_tracking_proof_primary_and_cleanup()
	await _test_failed_and_missed_lock()
	await _test_active_hit_and_sweep()
	await _test_presentation_callbacks_and_guard()
	await _test_callback_pause_transport()
	await _test_pending_weapon_lock()
	await _test_copied_clock_identity()
	for phase: String in ["warning", "lock", "active", "recovery"]:
		await _test_json_transport(phase)
	print("A2-L1 isolated Ray exchange smoke: %d checks, %d failures; no full-level/portrait claim" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _create(profile: String = "standard", second: bool = false) -> Dictionary:
	_fixtures += 1
	var viewport := SubViewport.new()
	viewport.name = "RayFixture%d" % _fixtures
	viewport.size = Vector2i(540, 1170)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	var world := Node3D.new()
	world.name = "RayExchangeWorld"
	viewport.add_child(world)
	var floor := StaticBody3D.new()
	floor.name = "DryFloor"
	floor.collision_layer = 1
	floor.collision_mask = 0
	floor.position.y = -0.5
	var support := CollisionShape3D.new()
	support.name = "DrySupport"
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	support.shape = box
	floor.add_child(support)
	world.add_child(floor)
	var hero: CinderPlayer = PlayerScript.new()
	hero.name = "SharedHero"
	hero.position = Vector3(0, 0, 3)
	world.add_child(hero)
	_expect(hero.equip_item("WEAPON-03"), "fixture uses canonical Heavy ordinary primary")
	hero.shells = 0
	var effects: PixelEffects = EffectsScript.new()
	effects.name = "SharedEffects"
	world.add_child(effects)
	var scheduler: CinderThreatScheduler = SchedulerScript.new()
	scheduler.name = "SharedScheduler"
	world.add_child(scheduler)
	_expect(scheduler.begin_encounter(profile, ENCOUNTER_ID), "parent fixture begins one fixed-profile encounter")
	var actors: Dictionary = {}
	for id: String in ([SCOUT_ID, SECOND_ID] if second else [SCOUT_ID]):
		var actor: Node3D = ActorScript.new() as Node3D
		actor.name = "ScoutRoot" if id == SCOUT_ID else "SecondScoutRoot"
		actor.position = Vector3.ZERO if id == SCOUT_ID else Vector3(1, 0, 0)
		world.add_child(actor)
		_expect(bool(actor.call("configure", hero, effects, id)), "parent fixture configures the one logical low housing root")
		actors[id] = actor
	var region: Dictionary = {"collision": support, "safe_rect": Rect2(-9.998, -9.998, 19.996, 19.996)}
	var context: Dictionary = {"encounter_id": ENCOUNTER_ID, "world_revision": 1, "recognition_s": 0.30, "attack_input_margin_s": 0.03, "escape_directions": [Vector3(0.4, 0, -sqrt(0.84)), Vector3(-0.4, 0, -sqrt(0.84))], "return_directions": [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK], "floor_regions": [region]}
	var driver: Node3D = ExchangeScript.new() as Node3D
	driver.name = "ScoutExchanges"
	world.add_child(driver)
	_expect(bool(driver.call("configure", hero, effects, scheduler, actors, profile, context)), "fresh driver binds actual roots/floor and resolves raw stationary data once")
	return {"viewport": viewport, "root": world, "hero": hero, "effects": effects, "scheduler": scheduler, "actors": actors, "actor": actors[SCOUT_ID], "driver": driver, "context": context, "bindings": {"world_root": world, "owners": actors.duplicate(), "floors": {"dry-floor": region}}}


func _test_tracking_proof_primary_and_cleanup() -> void:
	var arena: Dictionary = _create()
	await _ticks(6)
	var hero: CinderPlayer = arena.hero
	var scheduler: CinderThreatScheduler = arena.scheduler
	var driver: Node3D = arena.driver
	var actor: Node3D = arena.actor
	var defeated: Array[String] = []
	var cancel_before_progress: Array[bool] = []
	var provided_geometry: Array[Dictionary] = []
	var provider: Callable = func(id: String, geometry: Dictionary) -> Dictionary:
		provided_geometry.append(geometry.duplicate(true))
		geometry.radius = 999.0 # Defensive query copy cannot alter the lane.
		var context: Dictionary = arena.context.duplicate(true)
		context.escape_directions.reverse()
		return context if id == SCOUT_ID else {}
	_expect(bool(driver.call("set_response_context_provider", provider)), "parent installs an ephemeral current-camera/authored candidate provider")
	driver.connect("scout_defeated", func(id: String) -> void:
		defeated.append(id)
		cancel_before_progress.append(scheduler.reservations().is_empty() and not bool(driver.call("damage_window_open", id)) and driver.call("get_cue", id).state().phase == "clear")
	)
	_expect(driver.process_physics_priority > hero.process_physics_priority and driver.process_physics_priority > scheduler.process_physics_priority, "driver samples completed shared hero/scheduler physics ticks")
	var hp_before: float = hero.hp
	var started: Dictionary = driver.call("activate", SCOUT_ID)
	_expect(started.get("accepted", false) and not started.get("armed", true) and not bool(driver.call("damage_window_open", SCOUT_ID)), "actual tracking admission reserves a visible unarmed warning")
	if not started.get("accepted", false):
		push_error(str(started))
		await _dispose(arena)
		return
	var initial: Dictionary = driver.call("state", SCOUT_ID)
	_expect(_near(initial.resolved_role.windup_s - initial.resolved_role.lock_s, 0.45) and _near(initial.resolved_role.move_speed, 0.0) and _near(initial.resolved_role.max_hp, 30.0), "raw Scout uses 0.45 tracking and a genuinely stationary 30HP housing")
	_expect(driver.call("get_cue", SCOUT_ID).state().geometry == initial.geometry and _near(initial.geometry.radius, 0.31), "required cue uses the same source-anchored capsule geometry including endcaps")
	_expect(hero.request_dash(Vector3.RIGHT), "warning allows a real shared moving dash")
	_expect(await _until_phase(arena, "lock"), "moving warning updates then locks only after the actual player settles")
	var locked: Dictionary = driver.call("state", SCOUT_ID)
	_expect(locked.armed and locked.direction.distance_to(initial.direction) > 0.1 and _near(float(locked.exchange.active_from_s) - float(locked.exchange.lock_from_s), 1.10), "actual tracked direction commits with the FULL returned1.10 lock lead")
	_expect(hero.hp == hp_before and locked.proof_available and locked.proof.accepted and not locked.proof.uses_blast and not locked.proof.uses_invulnerability, "fresh live response yields an ordinary escape/counter proof without early damage")
	_expect(provided_geometry.size() == 2 and provided_geometry[0] == initial.geometry and provided_geometry[1] == locked.geometry and _near(locked.geometry.radius, 0.31), "provider sees current geometry at admission and fresh lock without replacing live hero response or immutable lane")
	var committed_geometry: Dictionary = locked.geometry.duplicate(true)
	locked.geometry.radius = 999.0
	locked.proof.path.clear()
	locked.presentation_witness.landing = Vector3(99, 0, 99)
	_expect(_near(driver.call("state", SCOUT_ID).geometry.radius, 0.31) and not driver.call("state", SCOUT_ID).proof.path.is_empty() and driver.call("state", SCOUT_ID).presentation_witness.landing == driver.call("state", SCOUT_ID).proof.landing, "public geometry, committed proof and framing witness are defensive native copies")
	var proof: Dictionary = driver.call("state", SCOUT_ID).proof
	await _execute_proof_dashes(arena, proof)
	await _until_clock(scheduler, float(proof.primary_time_s) + 0.02)
	_expect(driver.call("state", SCOUT_ID).phase == "recovery" and bool(driver.call("damage_window_open", SCOUT_ID)) and driver.call("get_opening_cue", SCOUT_ID).state().state == "available", "actual recovery deadline exposes the shared attack opening")
	_expect(driver.call("state", SCOUT_ID).geometry == committed_geometry and hero.hp == hp_before, "actual proved dashes preserve immutable lane and avoid the ray")
	hero.shells = 0
	_expect(hero.slash(actor.global_position - hero.global_position) == 1 and _near(actor.get("hp"), 6.0), "real no-ammo Heavy primary reaches the proved low housing and deals24")
	await _until_clock(scheduler, scheduler.get_clock() + float(hero.stats.primary_cooldown) + 0.04)
	hero.shells = 0
	paused = true
	var before_kill: Dictionary = hero.snapshot_state()
	paused = false
	_expect(hero.slash(actor.global_position - hero.global_position) == 1 and _near(actor.get("hp"), 0.0), "second ordinary no-ammo primary accepts only the remaining6HP")
	paused = true
	var after_kill: Dictionary = hero.snapshot_state()
	paused = false
	var credited_reload: float = float(before_kill.clocks.reload_s) + float(hero.stats.primary_hit_reload_credit)
	var earns_shell: bool = credited_reload >= float(hero.stats.shell_reload)
	_expect(defeated == [SCOUT_ID] and cancel_before_progress == [true] and actor.is_in_group("enemies") and after_kill.resources.shells == (1 if earns_shell else 0) and _near(after_kill.clocks.reload_s, 0.0 if earns_shell else credited_reload), "defeat cancels before progression and retained tombstone earns exact shared killing-action reload credit")
	scheduler.end_encounter("fixture_complete")
	paused = true
	await process_frame
	var ended: Dictionary = driver.call("snapshot_state", arena.bindings)
	_expect(not ended.is_empty() and ended.records[SCOUT_ID].status == "defeated" and scheduler.snapshot_state(arena.bindings).profile.is_empty(), "all-defeated local history remains capturable after parent ends scheduler encounter")
	driver.call("cleanup")
	driver.call("disarm")
	_expect(driver.call("snapshot_state", arena.bindings).is_empty() and driver.call("state").is_empty() and not bool(actor.call("take_damage", 1.0, Vector3.ZERO)["accepted"]), "idempotent cleanup releases refs/callbacks and permanently closes the bound gate")
	await _dispose(arena)


func _test_failed_and_missed_lock() -> void:
	var arena: Dictionary = _create("assisted", true)
	await _ticks(6)
	var scheduler: CinderThreatScheduler = arena.scheduler
	var driver: Node3D = arena.driver
	var hero: CinderPlayer = arena.hero
	var first: Dictionary = driver.call("activate", SCOUT_ID)
	await _until_clock(scheduler, scheduler.get_clock() + 0.16)
	var second: Dictionary = driver.call("activate", SECOND_ID)
	_expect(first.get("accepted", false) and not second.get("accepted", false) and String(second.get("reason", "")).contains("budget"), "actual Assisted preparing budget admits one visible warning only")
	await _until_clock(scheduler, float(first.reservation.lock_from_s) - 0.06)
	_expect(hero.request_dash(Vector3.RIGHT), "real motion begins just before the fresh lock proof")
	await _ticks(8)
	var failed: Dictionary = driver.call("state", SCOUT_ID)
	_expect(failed.status == "cancelled" and not failed.armed and failed.last_cancel_reason == "tracking_lock_unproved" and driver.call("get_cue", SCOUT_ID).state().phase == "clear" and driver.call("get_opening_cue", SCOUT_ID).state().state == "clear", "unstable actual lock visibly cancels without arming or leaving an opening cue")
	_expect(not driver.call("activate", SCOUT_ID).get("accepted", false) and scheduler.reservations().is_empty(), "failed lock preserves the original consumed source cooldown")
	await _dispose(arena)
	arena = _create()
	await _ticks(6)
	driver = arena.driver
	scheduler = arena.scheduler
	var hp: float = (arena.hero as CinderPlayer).hp
	first = driver.call("activate", SCOUT_ID)
	driver.set_physics_process(false)
	await _until_clock(scheduler, float(first.reservation.active_from_s) + 0.04)
	failed = driver.call("state", SCOUT_ID)
	_expect(failed.status == "cancelled" and failed.last_cancel_reason == "tracking_lock_missed" and driver.call("get_cue", SCOUT_ID).state().phase == "clear" and (arena.hero as CinderPlayer).hp == hp, "scheduler missed-lock invalidation cancels the disabled consumer and never damages unarmed")
	await _dispose(arena)


func _test_active_hit_and_sweep() -> void:
	var arena: Dictionary = _create()
	await _ticks(6)
	var hero: CinderPlayer = arena.hero
	var driver: Node3D = arena.driver
	var scheduler: CinderThreatScheduler = arena.scheduler
	var hits: Array[Dictionary] = []
	var reentrant: Array[bool] = []
	driver.connect("hit_resolved", func(_id: String, result: Dictionary) -> void: hits.append(result.duplicate(true)))
	hero.fired.connect(func(kind: String) -> void:
		if kind == "hurt":
			reentrant.append(bool(driver.call("state", SCOUT_ID).hit_consumed))
			driver.call("tick")
			var before_pause: bool = paused
			paused = true
			reentrant.append(driver.call("snapshot_state", arena.bindings).is_empty())
			paused = before_pause
	)
	var hp: float = hero.hp
	_expect(driver.call("activate", SCOUT_ID).get("accepted", false) and await _until_phase(arena, "active"), "actual shared clock reaches one armed ray release")
	_expect(hits.size() == 1 and hits[0].opportunity_consumed and hits[0].accepted and _near(hp - hero.hp, hero.equipment.damage_received(10.0)) and reentrant == [true, true], "real ray applies shared armor damage once and consumes its opportunity before synchronous hurt callbacks")
	_expect(await _until_phase(arena, "recovery") and hits.size() == 1, "continued lane exposure and first recovery sample cannot duplicate that hit")
	var shape: Dictionary = driver.call("state", SCOUT_ID).geometry
	_expect(Geometry.segment_hits(shape, Vector3(0, 0, 4.429), Vector3(0, 0, 4.429), 0.32) and not Geometry.segment_hits(shape, Vector3(0, 0, 4.45), Vector3(0, 0, 4.45), 0.32), "same immutable capsule damage includes its padded far endcap")
	# Freeze only the presentation consumer across normal recovery expiry. The
	# actor gate must use the actual scheduler deadline despite stale recovery art.
	driver.set_physics_process(false)
	await _until_clock(scheduler, float(driver.call("state", SCOUT_ID).exchange.recovery_until_s) + 0.03)
	_expect((arena.actor as Node3D).get("phase") == "recovery" and not bool((arena.actor as Node3D).call("take_damage", 2.0, Vector3.ZERO)["accepted"]) and _near((arena.actor as Node3D).get("hp"), 30.0), "actual recovery gate rejects expired damage even while cosmetic phase is stale")
	await _dispose(arena)
	arena = _create()
	await _ticks(6)
	hero = arena.hero
	driver = arena.driver
	scheduler = arena.scheduler
	hits.clear()
	driver.connect("hit_resolved", func(_id: String, result: Dictionary) -> void: hits.append(result.duplicate(true)))
	_expect(driver.call("activate", SCOUT_ID).get("accepted", false) and await _until_phase(arena, "lock"), "actual sweep fixture locks a proved source")
	var proof: Dictionary = driver.call("state", SCOUT_ID).proof
	await _execute_proof_dashes(arena, proof)
	_expect(await _until_phase(arena, "active"), "actual sweep starts from the safe proved landing")
	var before: Vector3 = hero.global_position
	shape = driver.call("state", SCOUT_ID).geometry
	driver.set_physics_process(false)
	_expect(hero.request_dash(Vector3.LEFT), "actual shared dash crosses the lane between consumer samples")
	await _until_clock(scheduler, scheduler.get_clock() + 0.15)
	var after: Vector3 = hero.global_position
	_expect(not Geometry.segment_hits(shape, before, before, 0.32) and not Geometry.segment_hits(shape, after, after, 0.32) and Geometry.segment_hits(shape, before, after, 0.32), "real dash endpoints are both outside while its measured segment crosses the capsule")
	driver.call("tick")
	_expect(hits.size() == 1 and driver.call("state", SCOUT_ID).hit_consumed, "timed actual sweep consumes one opportunity even if the sample arrives in first recovery")
	driver.call("tick")
	_expect(hits.size() == 1, "repeated same-tick actual sweep cannot duplicate damage")
	await _dispose(arena)


func _test_copied_clock_identity() -> void:
	var arena: Dictionary = _create()
	await _ticks(6)
	var driver: Node3D = arena.driver
	var scheduler: CinderThreatScheduler = arena.scheduler
	_expect(driver.call("activate", SCOUT_ID).get("accepted", false), "copied-clock fixture admits a real unarmed warning")
	# Advance real warning samples beyond start_s so one-bit down is still in
	# the valid history range and exercises equality rather than range rejection.
	await _ticks(2)
	paused = true
	await process_frame
	var local: Dictionary = driver.call("snapshot_state", arena.bindings)
	var paired: Dictionary = scheduler.snapshot_state(arena.bindings)
	_expect(not local.is_empty() and not paired.is_empty() and String(driver.call("snapshot_error", local, arena.bindings, paired)).is_empty(), "native copied-clock unit validates before any mutation")
	if local.is_empty() or paired.is_empty():
		await _dispose(arena)
		return
	var invalid: Dictionary = local.duplicate(true)
	invalid.clock_s = _one_bit_down(float(local.clock_s))
	_expect(invalid.clock_s < local.clock_s, "fixture creates the immediately preceding finite binary64 clock")
	_expect_identity_rejected(arena, invalid, paired, "one-bit down copied driver clock rejects atomically")
	invalid = local.duplicate(true)
	invalid.records[SCOUT_ID].sample.clock_s = _one_bit_down(float(local.records[SCOUT_ID].sample.clock_s))
	_expect(invalid.records[SCOUT_ID].sample.clock_s > local.records[SCOUT_ID].exchange.start_s, "one-bit prior sample remains inside the valid running history range")
	_expect_identity_rejected(arena, invalid, paired, "one-bit down prior sample rejects before changing resumed hit denominator")
	invalid = local.duplicate(true)
	invalid.records[SCOUT_ID].exchange.active_from_s = _one_bit_down(float(local.records[SCOUT_ID].exchange.active_from_s))
	_expect_identity_rejected(arena, invalid, paired, "one-bit down copied active deadline rejects atomically")
	invalid = local.duplicate(true)
	invalid.records[SCOUT_ID].exchange.adapter.lock_s = _one_bit_down(float(local.records[SCOUT_ID].exchange.adapter.lock_s))
	_expect_identity_rejected(arena, invalid, paired, "one-bit down copied adapter lock scalar rejects atomically")
	# A real public cancellation releases the reservation while preserving its
	# consumed cooldown. This reaches the retained-cooldown identity guard itself.
	_expect(bool(driver.call("cancel", SCOUT_ID, "fixture_copied_cooldown")), "public cancellation retains the actual original source cooldown")
	local = driver.call("snapshot_state", arena.bindings)
	paired = scheduler.snapshot_state(arena.bindings)
	_expect(not local.is_empty() and not paired.cooldowns.is_empty() and paired.reservations.is_empty() and String(driver.call("snapshot_error", local, arena.bindings, paired)).is_empty(), "cancelled native history validates with its retained cooldown and no reservation")
	if not local.is_empty() and not paired.cooldowns.is_empty():
		invalid = local.duplicate(true)
		invalid.records[SCOUT_ID].exchange.cooldown_until_s = _one_bit_down(float(local.records[SCOUT_ID].exchange.cooldown_until_s))
		_expect_identity_rejected(arena, invalid, paired, "one-bit down copied cancelled cooldown rejects atomically")
	await _dispose(arena)


func _expect_identity_rejected(arena: Dictionary, invalid: Dictionary, paired: Dictionary, description: String) -> void:
	var before: String = _identity_unit(arena)
	var error: String = String(arena.driver.call("snapshot_error", invalid, arena.bindings, paired))
	var restored: bool = bool(arena.driver.call("restore_state", invalid, arena.bindings))
	var after: String = _identity_unit(arena)
	_expect(not before.is_empty() and not error.is_empty() and not restored and after == before, description)


func _identity_unit(arena: Dictionary) -> String:
	return ExactJson.stringify({"player": (arena.hero as CinderPlayer).snapshot_state(), "scheduler": (arena.scheduler as CinderThreatScheduler).snapshot_state(arena.bindings), "exchange": arena.driver.call("snapshot_state", arena.bindings)})


func _one_bit_down(value: float) -> float:
	# Positive finite fixture clocks use the adjacent lower IEEE754 bit pattern.
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes.encode_s64(0, bytes.decode_s64(0) - 1)
	return bytes.decode_double(0)


func _test_json_transport(saved_phase: String) -> void:
	var saved_profile: String = "assisted" if saved_phase == "lock" else "standard"
	var arena: Dictionary = _create(saved_profile)
	await _ticks(6)
	var driver: Node3D = arena.driver
	var scheduler: CinderThreatScheduler = arena.scheduler
	_expect(driver.call("activate", SCOUT_ID).get("accepted", false), "JSON " + saved_phase + " fixture admits actual tracking")
	if saved_phase != "warning":
		_expect(await _until_phase(arena, saved_phase), "JSON fixture reaches actual " + saved_phase)
	paused = true
	await process_frame
	var local: Dictionary = _json(driver.call("snapshot_state", arena.bindings))
	var shared: Dictionary = _json(scheduler.snapshot_state(arena.bindings))
	var player: Dictionary = _json((arena.hero as CinderPlayer).snapshot_state())
	_expect(not local.is_empty() and not shared.is_empty() and not player.is_empty(), "paused " + saved_phase + " unit captures finite full-precision JSON")
	var clock: float = scheduler.get_clock()
	await create_timer(0.03, true).timeout
	_expect(_near(scheduler.get_clock(), clock) and Codec.same_values(local, driver.call("snapshot_state", arena.bindings)), "pause freezes phase, samples, local hit/flash latches and shared deadlines")
	var invalid: Dictionary = local.duplicate(true)
	invalid.records[SCOUT_ID].exchange.active_from_s += 0.01
	_expect(not String(driver.call("snapshot_error", invalid, arena.bindings, shared)).is_empty() and not bool(driver.call("restore_state", invalid, arena.bindings)) and Codec.same_values(local, driver.call("snapshot_state", arena.bindings)), "deadline mismatch rejects the entire driver without mutation")
	invalid = local.duplicate(true)
	invalid.actors[SCOUT_ID].body_yaw = NAN
	_expect(not String(driver.call("snapshot_error", invalid, arena.bindings, shared)).is_empty() and Codec.same_values(local, driver.call("snapshot_state", arena.bindings)), "malformed saved cosmetic yaw rejects before any actor or driver mutation")
	if saved_phase != "warning":
		invalid = local.duplicate(true)
		invalid.records[SCOUT_ID].presentation_witness.landing = [99.0, 0.0, 99.0]
		_expect(not String(driver.call("snapshot_error", invalid, arena.bindings, shared)).is_empty(), "unsupported view witness rejects without introducing a replacement combat proof")
	if saved_phase == "warning":
		invalid = local.duplicate(true)
		invalid.records[SCOUT_ID].hit_consumed = true
		_expect(not String(driver.call("snapshot_error", invalid, arena.bindings, shared)).is_empty(), "unarmed warning cannot manufacture a consumed active hit")
	var fresh: Dictionary = _create("standard")
	(fresh.root as Node3D).visible = false
	(fresh.hero as CinderPlayer).global_position = Vector3(4, 0, 4)
	await process_frame
	var fresh_driver: Node3D = fresh.driver
	var fresh_scheduler: CinderThreatScheduler = fresh.scheduler
	var events: Array[String] = []
	fresh_driver.connect("state_changed", func(_id: String, _state: Dictionary) -> void: events.append("state"))
	fresh_driver.connect("hit_resolved", func(_id: String, _result: Dictionary) -> void: events.append("hit"))
	fresh_driver.connect("scout_defeated", func(_id: String) -> void: events.append("defeat"))
	fresh_driver.call("get_cue", SCOUT_ID).state_changed.connect(func(_state: Dictionary) -> void: events.append("cue"))
	fresh_driver.call("get_opening_cue", SCOUT_ID).state_changed.connect(func(_state: Dictionary) -> void: events.append("opening"))
	_expect(String(fresh_driver.call("snapshot_error", local, fresh.bindings, shared)).is_empty(), "pure preflight accepts saved " + saved_phase + " profile/samples independently of fresh hero position and current preference")
	var staged_bindings: Dictionary = fresh.bindings.duplicate(true)
	staged_bindings.hero_positions = {"hero": Codec.read_vector3(player.motion.position)}
	_expect(String(fresh_driver.call("snapshot_error", local, staged_bindings, shared)).is_empty(), "saved-player context independently proves the running " + saved_phase + " sample without moving the fresh hero")
	invalid = local.duplicate(true)
	invalid.records[SCOUT_ID].sample.position = [99.0, 0.0, 99.0]
	_expect(not String(fresh_driver.call("snapshot_error", invalid, staged_bindings, shared)).is_empty() and (fresh.hero as CinderPlayer).global_position == Vector3(4, 0, 4), "staged preflight rejects an incoherent saved sample atomically before shared player mutation")
	_expect((fresh.hero as CinderPlayer).restore_state(player), "parent restores the validated saved shared player first")
	for id: String in local.actors:
		_expect(bool((fresh.actors[id] as Node3D).call("restore_state", local.actors[id])), "parent restores saved stationary actor tuple before scheduler")
	_expect(fresh_scheduler.restore_state(shared, fresh.bindings), "parent restores authoritative original scheduler deadlines/cooldowns without requesting")
	invalid = local.duplicate(true)
	invalid.records[SCOUT_ID].sample.position = [99.0, 0.0, 99.0]
	var before_restore: Dictionary = fresh_driver.call("state")
	_expect(String(fresh_driver.call("snapshot_error", invalid, fresh.bindings, shared)).is_empty() and not bool(fresh_driver.call("restore_state", invalid, fresh.bindings)) and fresh_driver.call("state") == before_restore, "sample preflight stays pure while actual commit rejects mismatch with restored player atomically")
	_expect(bool(fresh_driver.call("restore_state", local, fresh.bindings)) and Codec.same_values(local, fresh_driver.call("snapshot_state", fresh.bindings)) and events.is_empty(), "fresh " + saved_phase + " driver restores exact actors/hit/sample/flash/phase silently")
	staged_bindings.hero_positions.hero = Vector3(99, 0, 99)
	_expect(bool(fresh_driver.call("restore_state", local, staged_bindings)), "actual restored-player commit ignores staged position overrides")
	_expect(fresh_driver.call("state", SCOUT_ID).resolved_role.difficulty_profile == saved_profile and not fresh_driver.call("state", SCOUT_ID).proof_available, "saved fixed profile survives preference changes; unsaved diagnostic proof stays explicitly unavailable")
	_expect(Codec.same_values(local.records[SCOUT_ID].presentation_witness, fresh_driver.call("snapshot_state", fresh.bindings).records[SCOUT_ID].presentation_witness), "accepted two-position framing witness survives JSON restore independently of unsaved diagnostic paths")
	var hp: float = (fresh.hero as CinderPlayer).hp
	var consumed: bool = bool(local.records[SCOUT_ID].hit_consumed)
	arena.viewport.queue_free()
	await process_frame
	(fresh.root as Node3D).visible = true
	paused = false
	if saved_phase != "recovery":
		_expect(await _until_phase(fresh, "recovery"), "restored " + saved_phase + " continues the SAME existing reservation through recovery")
	else:
		await _ticks(3)
	var expected_loss: float = 0.0 if consumed else (fresh.hero as CinderPlayer).equipment.damage_received(float(fresh_driver.call("state", SCOUT_ID).resolved_role.damage))
	_expect(_near(hp - (fresh.hero as CinderPlayer).hp, expected_loss) and bool(fresh_driver.call("state", SCOUT_ID).hit_consumed), "restored active opportunity continues exactly once and never refreshes prior hit history")
	await _dispose(fresh)


func _test_presentation_callbacks_and_guard() -> void:
	for intervention: String in ["hide_source", "clear_cue", "queue_source", "portrait_guard"]:
		var arena: Dictionary = _create()
		await _ticks(6)
		var driver: Node3D = arena.driver
		var scheduler: CinderThreatScheduler = arena.scheduler
		var hero: CinderPlayer = arena.hero
		var actor: Node3D = arena.actor
		var hits: Array[Dictionary] = []
		var guarded: Array[Dictionary] = []
		driver.connect("hit_resolved", func(_id: String, result: Dictionary) -> void: hits.append(result))
		if intervention == "hide_source":
			driver.call("get_cue", SCOUT_ID).state_changed.connect(func(cue_state: Dictionary) -> void:
				if cue_state.phase == "active":
					actor.visible = false
			)
		elif intervention == "queue_source":
			driver.call("get_cue", SCOUT_ID).state_changed.connect(func(cue_state: Dictionary) -> void:
				if cue_state.phase == "active":
					actor.queue_free()
			)
		elif intervention == "clear_cue":
			driver.connect("state_changed", func(_id: String, exchange_state: Dictionary) -> void:
				if exchange_state.phase == "active":
					driver.call("get_cue", SCOUT_ID).clear()
			)
		else:
			var guard: Callable = func(id: String, exchange_state: Dictionary) -> bool:
				guarded.append(exchange_state.duplicate(true))
				exchange_state.geometry.radius = 999.0
				return id == SCOUT_ID and exchange_state.phase != "active"
			_expect(bool(driver.call("set_presentation_guard", guard)), "parent installs a fail-closed ephemeral pre-damage portrait guard")
		var hp: float = hero.hp
		_expect(driver.call("activate", SCOUT_ID).get("accepted", false), intervention + " fixture starts one actual unarmed tracking warning")
		_expect(await _until_phase(arena, "lock"), intervention + " fixture commits a full proved lock")
		var active_from: float = float(driver.call("state", SCOUT_ID).exchange.active_from_s)
		await _until_clock(scheduler, active_from + 0.035)
		var stopped: Dictionary = driver.call("state", SCOUT_ID)
		_expect(stopped.status == "cancelled" and stopped.last_cancel_reason == "required_scout_presentation_unavailable" and not stopped.hit_consumed and stopped.presentation_witness.is_empty() and _near(hero.hp, hp) and hits.is_empty(), intervention + " callback/guard visibly cancels before any outgoing ray opportunity or damage")
		_expect(scheduler.reservations().is_empty() and driver.call("get_cue", SCOUT_ID).state().phase == "clear" and driver.call("get_opening_cue", SCOUT_ID).state().state == "clear", intervention + " releases danger and closes both required cues synchronously")
		if intervention == "portrait_guard":
			_expect(not guarded.is_empty() and guarded[0].geometry.kind == "lane" and _near(guarded[0].geometry.radius, 0.31) and _near(stopped.geometry.radius, 0.31), "guard receives defensive complete proposed geometry before admission and cannot alter authoritative capsule")
		await _dispose(arena)
	# A cleared recovery opening must close ordinary incoming primary damage
	# even if no consumer tick has yet redrawn that available interaction cue.
	var arena: Dictionary = _create()
	await _ticks(6)
	_expect(arena.driver.call("activate", SCOUT_ID).get("accepted", false), "recovery opening fixture admits tracking")
	_expect(await _until_phase(arena, "recovery"), "recovery opening fixture reaches a real deadline window")
	arena.driver.call("get_opening_cue", SCOUT_ID).clear()
	_expect(not bool(arena.actor.call("take_damage", 2.0, Vector3.ZERO).accepted) and _near(arena.actor.get("hp"), 30.0), "cleared required opening cue rejects primary damage inside otherwise live recovery")
	await _dispose(arena)


func _test_callback_pause_transport() -> void:
	for origin: String in ["active_cue", "presentation_guard"]:
		var arena: Dictionary = _create()
		await _ticks(6)
		var driver: Node3D = arena.driver
		var scheduler: CinderThreatScheduler = arena.scheduler
		var hero: CinderPlayer = arena.hero
		var paused_once: Array[bool] = [false]
		var hits: Array[Dictionary] = []
		driver.connect("hit_resolved", func(_id: String, result: Dictionary) -> void: hits.append(result))
		if origin == "active_cue":
			driver.call("get_cue", SCOUT_ID).state_changed.connect(func(cue_state: Dictionary) -> void:
				if cue_state.phase == "active" and not paused_once[0]:
					paused_once[0] = true
					paused = true
			)
		else:
			var guard: Callable = func(_id: String, exchange_state: Dictionary) -> bool:
				if exchange_state.phase == "active" and not paused_once[0]:
					paused_once[0] = true
					paused = true
				return true
			_expect(bool(driver.call("set_presentation_guard", guard)), "pause fixture installs actual ephemeral presentation guard")
		var hp: float = hero.hp
		_expect(driver.call("activate", SCOUT_ID).get("accepted", false), origin + " pause fixture starts actual tracking")
		_expect(await _until_phase(arena, "active"), origin + " reaches a synchronous paused active cue")
		_expect(paused and paused_once[0] and _near(hero.hp, hp) and hits.is_empty() and not driver.call("state", SCOUT_ID).hit_consumed and driver.call("state", SCOUT_ID).status == "running", origin + " pause preserves reservation and never consumes or damages within the callback tick")
		var local: Dictionary = _json(driver.call("snapshot_state", arena.bindings))
		var paired: Dictionary = _json(scheduler.snapshot_state(arena.bindings))
		var player: Dictionary = _json(hero.snapshot_state())
		_expect(not local.is_empty() and not local.records[SCOUT_ID].deferred_paths.is_empty() and _near(local.records[SCOUT_ID].sample.clock_s, scheduler.get_clock()) and Codec.read_vector3(local.records[SCOUT_ID].sample.position).is_equal_approx(hero.global_position), origin + " deferred measured sweep retains coherent current-frame saved-player samples")
		var bindings: Dictionary = arena.bindings.duplicate(true)
		bindings.hero_positions = {"hero": Codec.read_vector3(player.motion.position)}
		_expect(String(driver.call("snapshot_error", local, bindings, paired)).is_empty(), origin + " pause unit validates against the separately saved shared player")
		var invalid: Dictionary = local.duplicate(true)
		invalid.records[SCOUT_ID].deferred_paths[-1]["to"] = [99.0, 0.0, 99.0]
		_expect(not String(driver.call("snapshot_error", invalid, bindings, paired)).is_empty() and Codec.same_values(local, driver.call("snapshot_state", arena.bindings)), origin + " malformed deferred endpoint rejects atomically")
		_expect(bool(arena.actor.call("restore_state", local.actors[SCOUT_ID])) and scheduler.restore_state(paired, arena.bindings) and bool(driver.call("restore_state", local, arena.bindings)), origin + " exact deferred opportunity survives silent actor/scheduler/driver JSON restore")
		paused = false
		_expect(await _until_phase(arena, "recovery"), origin + " resumes original active/recovery deadlines")
		_expect(hits.size() == 1 and driver.call("state", SCOUT_ID).hit_consumed and _near(hp - hero.hp, hero.equipment.damage_received(10.0)), origin + " retained active overlap resolves once only after resume")
		await _dispose(arena)
	var arena: Dictionary = _create()
	await _ticks(6)
	_expect(arena.driver.call("activate", SCOUT_ID).get("accepted", false), "incoming pause gate fixture starts tracking")
	_expect(await _until_phase(arena, "recovery"), "incoming pause gate fixture reaches actual recovery")
	var guard: Callable = func(_id: String, _state: Dictionary) -> bool:
		paused = true
		return true
	_expect(bool(arena.driver.call("set_presentation_guard", guard)), "incoming pause fixture installs a synchronous guard")
	_expect(not bool(arena.actor.call("take_damage", 2.0, Vector3.ZERO).accepted) and paused and _near(arena.actor.get("hp"), 30.0) and arena.driver.call("state", SCOUT_ID).status == "running", "incoming primary gate rechecks pause after its callback without cancelling or accepting damage")
	await _dispose(arena)


func _test_pending_weapon_lock() -> void:
	var arena: Dictionary = _create()
	await _ticks(6)
	var hero: CinderPlayer = arena.hero
	var scheduler: CinderThreatScheduler = arena.scheduler
	var driver: Node3D = arena.driver
	var started: Dictionary = driver.call("activate", SCOUT_ID)
	_expect(started.get("accepted", false), "pending-weapon fixture starts a real unarmed warning")
	await _until_clock(scheduler, float(started.reservation.lock_from_s) - 0.06)
	var heavy_response: Dictionary = hero.get_threat_response_state()
	_expect(hero.slash(Vector3.RIGHT) == 0 and hero.action_in_progress(), "real stationary Heavy primary starts an unfinished action without hitting the housing")
	_expect(hero.equip_item("WEAPON-02"), "Quick weapon queues through the ordinary shared action rule")
	var pending: Dictionary = hero.get_threat_response_state()
	_expect(pending.stable and pending.pending_weapon_id == "WEAPON-02" and pending.equipment_ids.weapon == "WEAPON-03" and pending.commitment_remaining_s > 0.0 and Codec.same_values(pending.stats, heavy_response.stats), "physically stable unfinished primary exposes pending Quick while current response still uses Heavy stats")
	# Restore the real queued action before its exact due lock. Gear remains
	# player-owned; no driver cache, private assignment or forced completion.
	paused = true
	var player: Dictionary = _json(hero.snapshot_state())
	var paired: Dictionary = _json(scheduler.snapshot_state(arena.bindings))
	var local: Dictionary = _json(driver.call("snapshot_state", arena.bindings))
	var staged: Dictionary = arena.bindings.duplicate(true)
	staged.hero_positions = {"hero": Codec.read_vector3(player.motion.position)}
	_expect(player.pending_weapon == "WEAPON-02" and not local.is_empty() and String(driver.call("snapshot_error", local, staged, paired)).is_empty(), "paused queued-equipment warning captures a coherent saved-player/actor/scheduler unit before due lock")
	var restore_events: Array[String] = []
	driver.connect("state_changed", func(_id: String, _state: Dictionary) -> void: restore_events.append("state"))
	driver.call("get_cue", SCOUT_ID).state_changed.connect(func(_state: Dictionary) -> void: restore_events.append("cue"))
	driver.call("get_opening_cue", SCOUT_ID).state_changed.connect(func(_state: Dictionary) -> void: restore_events.append("opening"))
	hero.equipment_changed.connect(func(_id: String) -> void: restore_events.append("equipment"))
	_expect(hero.restore_state(player) and bool(arena.actor.call("restore_state", local.actors[SCOUT_ID])) and scheduler.restore_state(paired, arena.bindings) and bool(driver.call("restore_state", local, arena.bindings)) and restore_events.is_empty(), "queued-equipment player/actors/scheduler/driver restore silently without applying or refreshing the weapon action")
	_expect(hero.get_threat_response_state().pending_weapon_id == "WEAPON-02" and hero.get_threat_response_state().equipment_ids.weapon == "WEAPON-03" and _near(scheduler.get_clock(), float(local.clock_s)), "restored queued weapon preserves its original current gear and authoritative clock")
	var hp: float = hero.hp
	paused = false
	await _until_clock(scheduler, float(started.reservation.lock_from_s) + 0.025)
	var cancelled: Dictionary = driver.call("state", SCOUT_ID)
	_expect(cancelled.status == "cancelled" and cancelled.last_cancel_reason == "tracking_pending_weapon_change" and not cancelled.armed and not cancelled.proof_available and cancelled.presentation_witness.is_empty() and not cancelled.hit_consumed and _near(hero.hp, hp), "due lock visibly cancels instead of arming a future counter witness with old pending-weapon stats")
	_expect(scheduler.reservations().is_empty() and driver.call("get_cue", SCOUT_ID).state().phase == "clear" and driver.call("get_opening_cue", SCOUT_ID).state().state == "clear" and not driver.call("activate", SCOUT_ID).get("accepted", false), "pending-weapon cancellation clears both cues while retaining the original consumed source cooldown")
	for count: int in range(120):
		if hero.get_threat_response_state().pending_weapon_id.is_empty():
			break
		await _ticks(1)
	var quick_response: Dictionary = hero.get_threat_response_state()
	_expect(quick_response.pending_weapon_id.is_empty() and quick_response.equipment_ids.weapon == "WEAPON-02" and Codec.same_values(quick_response.stats, hero.equipment.resolved_stats()) and not _near(quick_response.stats.primary_cooldown, float(heavy_response.stats.primary_cooldown)), "ordinary shared physics finishes the primary and applies fresh canonical Quick stats")
	await _until_clock(scheduler, float(cancelled.exchange.cooldown_until_s) + 0.03)
	_expect(driver.call("activate", SCOUT_ID).get("accepted", false), "new warning becomes available only after the original cancellation cooldown")
	_expect(await _until_phase(arena, "lock"), "fresh cleared-equipment response commits a new actual lock")
	var locked: Dictionary = driver.call("state", SCOUT_ID)
	_expect(locked.armed and locked.proof_available and _near(float(locked.exchange.active_from_s) - float(locked.exchange.lock_from_s), 1.10) and _near(float(locked.proof.response_complete_s) - float(locked.proof.primary_time_s), float(quick_response.stats.primary_cooldown)), "new accepted ordinary counter witness uses the freshly equipped Quick timing and full returned lock lead")
	await _dispose(arena)
	# A queued change that finishes during the tracking warning may legitimately
	# lock afterward; warning never becomes damage authority while gear is pending.
	arena = _create()
	await _ticks(6)
	hero = arena.hero
	driver = arena.driver
	_expect(hero.slash(Vector3.RIGHT) == 0 and hero.equip_item("WEAPON-02"), "early queued change uses real slash and equipment input")
	_expect(driver.call("activate", SCOUT_ID).get("accepted", false) and not driver.call("state", SCOUT_ID).armed and hero.get_threat_response_state().pending_weapon_id == "WEAPON-02", "unarmed tracking admission remains available during an unfinished queued-gear action")
	_expect(await _until_phase(arena, "lock"), "early queued gear clears naturally before due lock")
	quick_response = hero.get_threat_response_state()
	locked = driver.call("state", SCOUT_ID)
	_expect(quick_response.pending_weapon_id.is_empty() and quick_response.equipment_ids.weapon == "WEAPON-02" and locked.armed and _near(float(locked.proof.response_complete_s) - float(locked.proof.primary_time_s), float(quick_response.stats.primary_cooldown)), "warning that outlasts the action locks only the actual newly applied canonical gear")
	await _dispose(arena)


func _execute_proof_dashes(arena: Dictionary, proof: Dictionary) -> void:
	for segment: Dictionary in proof.path:
		if segment.kind not in ["escape_dash", "positioning_dash"]:
			continue
		await _until_clock(arena.scheduler, float(segment.start_s))
		var hero: CinderPlayer = arena.hero
		_expect(hero.request_dash((segment["to"] - segment["from"]).normalized()), "actual shared dash executes accepted proof's " + segment.kind)
		await _until_clock(arena.scheduler, float(segment.end_s) + 0.025)
		_expect(hero.global_position.distance_to(segment["to"]) < 0.10, "actual measured full dash reaches its proved " + segment.kind + " landing")


func _until_phase(arena: Dictionary, phase: String) -> bool:
	for count: int in range(900):
		if arena.driver.call("state", SCOUT_ID).phase == phase:
			return true
		if arena.driver.call("state", SCOUT_ID).status in ["cancelled", "defeated", "complete"]:
			return false
		await _ticks(1)
	return false


func _until_clock(scheduler: CinderThreatScheduler, target: float) -> void:
	for count: int in range(900):
		if scheduler.get_clock() >= target - 0.000001:
			return
		await _ticks(1)
	_expect(false, "actual scheduler clock reached bounded fixture target")


func _ticks(count: int) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame


func _dispose(arena: Dictionary) -> void:
	paused = false
	if is_instance_valid(arena.driver):
		arena.driver.call("cleanup")
	if is_instance_valid(arena.scheduler):
		arena.scheduler.end_encounter("fixture_exit")
	arena.viewport.queue_free()
	await process_frame


func _json(value: Dictionary) -> Dictionary:
	var decoded: Variant = JSON.parse_string(JSON.stringify(value, "", true, true))
	return decoded if decoded is Dictionary else {}


func _near(value: Variant, expected: float) -> bool:
	return Codec.is_number(value) and absf(float(value) - expected) < 0.00001


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(description)
