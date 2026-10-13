extends SceneTree
## TEST ONLY one stationary own-enemy cycle. InputHost inherits the real
## recognizer; no campaign placement, captured Player art or native OS claim.
const Actor = preload("res://tests/fixtures/authored_echo_actor.gd")
const Player = preload("res://scripts/player.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const ReplayProjection = preload("res://scripts/combat/replay_footprint.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Cursor = preload("res://scripts/combat/replay_cursor.gd")
const NativeCodec = preload("res://tests/fixtures/authored_echo_native_codec.gd")
const SOURCE_ID: String = "test-only/actual-mirror"
const EPOCH: String = "test-only/own-enemy-attempt"
const GENERATION: int = 1

class InputHost extends "res://scripts/game.gd":
	# Suppress unrelated arena/HUD setup only. All actual input/aim methods,
	# gesture guards and native focus notification behavior are inherited.
	func _ready() -> void:
		pass
	func _process(_delta: float) -> void:
		pass

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	var route_only: bool = "--route-only" in OS.get_cmdline_user_args()
	await _ordinary_cycle(false)
	await _ordinary_cycle(true)
	await _mid_route_restore()
	if not route_only:
		for held: String in ["cue", "event", "state", "cue_death"]:
			await _held_delivery(held)
		await _renderer_faults()
		await _renderer_observer_boundaries()
	print("Authored echo playback smoke: %d checks, %d failures; route_only=%s" % [_checks, _failures, route_only])
	quit(0 if _failures == 0 else 1)


func _ordinary_cycle(extreme: bool) -> void:
	var arena: Dictionary = await _arena(extreme)
	# A distinct pre-admission control proves real primary input works with zero
	# ammo. The later recovery route preserves the Player's normal regeneration.
	paused = false
	_expect(arena.player.shells == 0 and _tap(arena, Vector3.LEFT) and arena.player.shells == 0 and arena.player.get_world_action_records().back().hits == 0 and arena.actor.hp == 12.0, "TEST ONLY pre-admission actual empty-ammo first tap executes a primary miss without spending ammo or changing source HP")
	var installed: Dictionary = _install(arena)
	if installed.is_empty():
		await _dispose(arena)
		return
	var hp: float = arena.player.hp
	var source_pose: Transform3D = arena.actor.global_transform
	_expect(arena.player.shells == 0 and arena.actor.get_enemy_apparition() != null and arena.actor.get_apparition() == null and arena.actor.preview_state().static_loadouts.is_empty(), "actual empty-ammo source-owned native renderer has no Player sprite, gear or capture loadouts")
	var proof: Dictionary = await _lock(arena, installed)
	if proof.is_empty():
		await _dispose(arena)
		return
	var completed: Array[String] = []
	arena.player.world_action_executed.connect(func(record: Dictionary) -> void: completed.append(record.kind))
	for segment: Dictionary in proof.path:
		if segment.kind not in ["first_escape_dash", "tether_positioning_dash"]:
			continue
		await _until(arena, float(segment.start_s))
		_expect(_swipe(arena, (segment.to - segment.from).normalized()), "shared native touch/drag/release starts " + segment.kind + (" with slow long-step gear" if extreme else " with default gear"))
		await _finished_dash(arena)
		_expect(arena.actor.global_transform == source_pose and arena.player.hp == hp, "actual harmless apparition/hero travel changes no source pose or HP")
	await _until(arena, float(proof.primary_time_s))
	_expect(arena.actor.source_phase() == "recovery" and arena.player.global_position.distance_to(arena.actor.global_position) <= float(arena.player.stats.primary_range), "actual return reaches the living recovery knot inside ordinary primary range")
	var shells_before: int = arena.player.shells
	_expect(_tap(arena, (arena.actor.global_position - arena.player.global_position).normalized()), "ordinary shared first tap aims from the final swipe release and hits own source")
	_expect(arena.actor.dead and arena.actor.hp == 0.0 and arena.actor.source_hits == 1 and completed.count("dash") == 2 and completed.count("primary") == 1 and not completed.has("blast") and arena.player.hp == hp, "two real dashes and one primary defeat the actual knot without ammo, movement damage or recursive capture")
	_expect(shells_before > 0 and not completed.has("blast"), "ordinary recovery primary spends no blast ammo; canonical regeneration after the zero-ammo entry remains intact")
	paused = true
	await process_frame
	var bundle: Dictionary = _capture(arena, "ordinary-extreme" if extreme else "ordinary")
	if not bundle.is_empty():
		_expect(bundle.source.phase == "defeated" and bundle.playback.status == "cancelled" and bundle.playback.reason == "authored_source_defeated" and bundle.scheduler.replay_cancellations.size() == 1 and not bundle.scheduler.cooldowns.is_empty(), "actual source defeat retains original terminal tombstone/prefix and conservative cooldown")
		_terminal_negatives(arena, bundle)
		var fresh: Dictionary = await _fresh(arena, bundle)
		if not fresh.is_empty():
			_expect(fresh.actor.dead and fresh.actor.source_hits == 1 and fresh.player.hp == arena.player.hp and fresh.actor.state().opportunities == arena.actor.state().opportunities, "fresh quiet defeated source has original HP/once-hit state and no duplicate events")
			await _retire(arena)
			arena = fresh
			paused = false
			var past_hp: float = arena.player.hp
			await _ticks(2)
			_expect(arena.actor.state().status == "cancelled" and arena.player.hp == past_hp and arena.actor.source_hits == 1, "restored defeated tombstone cannot restart the old own-enemy cycle")
	await _dispose(arena)


func _mid_route_restore() -> void:
	var arena: Dictionary = await _arena()
	var installed: Dictionary = _install(arena)
	if installed.is_empty():
		await _dispose(arena)
		return
	var proof: Dictionary = await _lock(arena, installed)
	if proof.is_empty():
		await _dispose(arena)
		return
	await _until(arena, float(installed.lease.active_from_s) + 0.04)
	paused = true
	await process_frame
	var native: Dictionary = arena.actor.get_enemy_apparition().native_pose()
	_expect(arena.actor.source_phase() == "active" and native.pose.action == "dash" and native.transform.origin != arena.actor.global_position and arena.actor.state().opportunities.is_empty(), "real ticks reach own harmless moving mesh while fixed HP owner and future slash remain separate")
	var bundle: Dictionary = _capture(arena, "mid-route")
	if not bundle.is_empty():
		_atomic_negatives(arena, bundle)
		var fresh: Dictionary = await _fresh(arena, bundle)
		if not fresh.is_empty():
			_expect(fresh.actor.get_enemy_apparition().native_pose() == native and fresh.actor.global_position == arena.actor.global_position, "quiet whole fresh world reconstructs exact native mesh foot pivot/facing/action/progress and fixed source")
			var before: String = Exact.stringify(_capture(fresh, "paused-copy"))
			await create_timer(0.05, true).timeout
			_expect(Exact.stringify(_capture(fresh, "paused-copy-2")) == before, "paused fresh actor/Scheduler/Playback/cue resources remain coherent and clocks do not advance")
			await _retire(arena)
			arena = fresh
			paused = false
			await _until(arena, float(bundle.playback.exchange.adapter.timeline_origin_s) + float(bundle.playback.sequence.timeline.tether_from_s) + 0.02)
			_expect(arena.actor.state().opportunities.size() == 1 and arena.actor.state().opportunities[0].contact and arena.actor.state().opportunities[0].damage_attempted, "fresh mid-route continuation dispatches one real cone contact, not dash damage")
	await _dispose(arena)


func _held_delivery(kind: String) -> void:
	var arena: Dictionary = await _arena()
	var installed: Dictionary = _install(arena)
	if installed.is_empty():
		await _dispose(arena)
		return
	var hp: float = arena.player.hp
	var event_calls: Array[String] = []
	var held: Array[bool] = [false]
	arena.actor.event_dispatched.connect(func(event: Dictionary, _receipt: Dictionary) -> void:
		event_calls.append(event.kind)
		_expect(not arena.actor.advance().get("accepted", false), "nested actual event observer cannot duplicate its once-only prefix")
		if kind == "event" and not held[0]:
			held[0] = true
			paused = true
	)
	if kind == "cue":
		arena.actor.get_cues()[0].state_changed.connect(func(value: Dictionary) -> void:
			if value.phase == "active" and not held[0]:
				held[0] = true
				_expect(_swipe(arena, Vector3.BACK), "held real active cue starts an actual unfinished Player dash")
				paused = true
		)
	elif kind == "state":
		arena.actor.state_changed.connect(func(value: Dictionary) -> void:
			if value.cursor.get("phase") == "active" and not value.opportunities.is_empty() and not held[0]:
				held[0] = true
				paused = true
		)
	elif kind == "cue_death":
		arena.actor.get_cues()[0].state_changed.connect(func(value: Dictionary) -> void:
			if value.phase == "active" and not held[0]:
				held[0] = true
				arena.player.take_damage(100000.0, Vector3.ZERO)
				paused = true
		)
	var proof: Dictionary = await _lock(arena, installed)
	if proof.is_empty():
		await _dispose(arena)
		return
	for _tick: int in range(180):
		if paused:
			break
		await _ticks(1)
	_expect(paused and held[0], kind + " genuine native observer holds the original dispatch boundary")
	await process_frame
	var original_native: Dictionary = arena.actor.get_enemy_apparition().native_pose()
	var bundle: Dictionary = _capture(arena, "held-" + kind)
	if bundle.is_empty():
		await _dispose(arena)
		return
	if kind == "cue":
		_expect(bundle.playback.schema_version == 3 and bundle.playback.pending_delivery.events == [{"event_index": 0, "stage": "damage"}] and bundle.playback.opportunities[0].contact and not bundle.playback.opportunities[0].damage_attempted and arena.player.hp == hp, "projected pending transport retains original accepted contact/time before actual damage, with unfinished dash")
	elif kind in ["event", "state"]:
		_expect(event_calls == ["enemy_slash"] and bundle.playback.get("pending_delivery", {}).get("events", []).is_empty() and bundle.playback.opportunities[0].damage_attempted and arena.player.hp < hp, "held " + kind + " observer has already consumed original damage and notification before its remaining visual/state boundary")
	else:
		_expect(arena.player.dead and bundle.playback.status == "cancelled" and not bundle.playback.opportunities[0].damage_attempted and event_calls.is_empty(), "real active observer death cancels remaining damage without replaying the committed original contact")
	var fresh: Dictionary = await _fresh(arena, bundle)
	if not fresh.is_empty():
		_expect(fresh.actor.get_enemy_apparition().native_pose() == original_native, kind + " fresh native renderer reconstructs actual last presented pose, not an unpresented cursor proxy")
		var new_calls: Array[String] = []
		fresh.actor.event_dispatched.connect(func(event: Dictionary, _receipt: Dictionary) -> void: new_calls.append(event.kind))
		var previous_hp: float = fresh.player.hp
		await _retire(arena)
		arena = fresh
		paused = false
		await _ticks(1)
		arena.actor.advance()
		_expect(new_calls == (["enemy_slash"] if kind == "cue" else []) and arena.player.hp == previous_hp, kind + " actual first resumed physics tick drains only undelivered prefix; invulnerable dash/death/consumed hit cannot duplicate HP")
		if kind == "cue":
			_expect(arena.actor.state().opportunities[0].dispatch_clock_s == bundle.playback.opportunities[0].dispatch_clock_s and arena.actor.state().opportunities[0].scheduled_at_s == bundle.playback.opportunities[0].scheduled_at_s and arena.actor.state().opportunities[0].damage_attempted, "accepted original contact survives resumed actual movement with exact original receipt clocks")
	await _dispose(arena)


func _renderer_faults() -> void:
	for fault: String in ["hidden", "freed", "replaced"]:
		var arena: Dictionary = await _arena()
		var installed: Dictionary = _install(arena)
		if installed.is_empty():
			await _dispose(arena)
			continue
		var held: Array[bool] = [false]
		arena.actor.get_cues()[0].state_changed.connect(func(value: Dictionary) -> void:
			if value.phase == "active" and not held[0]:
				held[0] = true
				paused = true
		)
		await _lock(arena, installed)
		for _tick: int in range(180):
			if paused:
				break
			await _ticks(1)
		var mesh: MeshInstance3D = arena.actor.get_enemy_apparition().visual
		match fault:
			"hidden": mesh.hide()
			"freed": mesh.queue_free()
			"replaced": mesh.mesh = mesh.mesh.duplicate()
		await process_frame # Freed child is genuinely gone, not just queued.
		var hp: float = arena.player.hp
		var bindings: Dictionary = _bindings(arena)
		var schedule: Dictionary = arena.scheduler.snapshot_state(bindings)
		_expect(arena.actor.snapshot_state(schedule, bindings).is_empty(), fault + " live pending writer rejects lost actual renderer authority purely")
		paused = false
		arena.actor.advance()
		paused = true
		await process_frame
		_expect(arena.actor.state().status == "cancelled" and arena.player.hp == hp and not arena.scheduler.replay_cancellation_state(installed.id).is_empty() and arena.scheduler.source_control_state(arena.actor).get("cooldown") is Dictionary, fault + " native renderer loss cancels without historical damage or fresh cooldown grant")
		await _dispose(arena)


func _renderer_observer_boundaries() -> void:
	for mode: String in ["cancel", "pause"]:
		var arena: Dictionary = await _arena()
		var installed: Dictionary = _install(arena)
		if installed.is_empty():
			await _dispose(arena)
			continue
		var calls: Array[String] = []
		arena.actor.get_enemy_apparition().pose_presented.connect(func(value: Dictionary) -> void:
			if value.action == "dash" and calls.is_empty():
				calls.append(mode)
				if mode == "cancel":
					arena.scheduler.cancel_owner(arena.actor, "native_renderer_hook_cancelled")
				else:
					paused = true # Unsupported renderer-hook pause fails closed.
		)
		var hp: float = arena.player.hp
		await _lock(arena, installed)
		for _tick: int in range(180):
			if not calls.is_empty():
				break
			await _ticks(1)
		paused = true
		await process_frame
		var terminal: Dictionary = arena.actor.state()
		var cleared: bool = true
		for cue: Node3D in arena.actor.get_cues():
			cleared = cleared and (cue.state().phase == "clear" or not cue.is_visible_in_tree())
		_expect(calls == [mode] and terminal.status == "cancelled" and terminal.opportunities.is_empty() and arena.player.hp == hp and cleared and not arena.scheduler.replay_cancellation_state(installed.id).is_empty(), "actual renderer-hook " + mode + " cancels once with retained cooldown and cannot reopen a later active cue")
		var native: Dictionary = arena.actor.get_enemy_apparition().native_pose()
		_expect(native.pose == terminal.visual_pose and native.transform.origin == arena.actor.global_position and native.pose.action == "idle", "renderer-hook " + mode + " settles actual native terminal idle after the outer hook unlocks")
		await _dispose(arena)


func _arena(extreme: bool = false, settle: bool = true) -> Dictionary:
	if settle:
		paused = false
	var viewport := SubViewport.new()
	viewport.name = "TestOnlyOwnEnemyWorld"
	viewport.size = Vector2i(270, 585)
	viewport.own_world_3d = true
	viewport.handle_input_locally = false
	root.add_child(viewport)
	var world := Node3D.new()
	world.name = "NativeWorld"
	viewport.add_child(world)
	var body := StaticBody3D.new()
	body.name = "DryFloor"
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var box := BoxShape3D.new()
	box.size = Vector3(16, 1, 16)
	collision.shape = box
	body.position = Vector3(0, -0.5, 0)
	body.add_child(collision)
	world.add_child(body)
	var camera := Camera3D.new()
	camera.name = "NativeCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7.2
	world.add_child(camera)
	camera.position = Vector3(0, 18, 13)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var hero = Player.new()
	hero.name = "ActualSharedPlayer"
	world.add_child(hero)
	hero.position = Vector3(0.6, 0.1, 0)
	var scheduler = Scheduler.new()
	scheduler.name = "ActualScheduler"
	world.add_child(scheduler)
	_expect(scheduler.begin_encounter("standard", "test-only/own-echo", 1), "actual Scheduler selects a fresh raw Standard encounter")
	var host = InputHost.new()
	host.name = "ActualRecognizerHost"
	host.player = hero
	host.world = world
	host.camera = camera
	root.add_child(host)
	if settle:
		await _ticks(8)
		paused = true
		await process_frame
		if extreme:
			for id: String in ["CLOTH-J1", "CLOTH-P2", "CLOTH-S2", "WEAPON-04"]:
				_expect(hero.equip_item(id), "legal paused pre-encounter gear selects " + id)
		var seed: Dictionary = hero.snapshot_state()
		seed.resources.shells = 0
		seed.clocks.reload_s = 0.0
		_expect(hero.restore_state(seed), "TEST ONLY initial paused empty-ammo seed retains coherent actual actor")
	var floors: Array = [{"collision": collision, "safe_rect": Rect2(-8, -8, 16, 16)}]
	var signature: Dictionary = ReplayProjection.floor_signature(world, floors)
	var context: Dictionary = {"world_root": world, "source_id": SOURCE_ID, "source_epoch": EPOCH, "generation": GENERATION, "world_collision_fingerprint": scheduler.pure_collision_fingerprint(world), "world_floor_signature": signature.get("signature", [])}
	var source = Actor.new()
	source.name = "ActualFixedKnotC52"
	world.add_child(source)
	var prepared: Dictionary = {"world_revision": 1, "collision_fingerprint": context.world_collision_fingerprint, "floor_signature": context.world_floor_signature}
	_expect(source.initialize_source(SOURCE_ID, EPOCH, GENERATION, _definition(), "standard", prepared) and source.attach_source_scheduler(scheduler), "genuine shared Playback subclass owns immutable native definition, HP, visible mesh and fixed endpoint")
	_expect(source.configure_authored("test-only/physical-echo", source.source_program(), EPOCH, GENERATION), "own enemy configure_authored uses its actual source hooks: " + source.last_error)
	return {"viewport": viewport, "world": world, "floor": collision, "floors": floors, "camera": camera, "host": host, "player": hero, "scheduler": scheduler, "actor": source, "context": context}


func _definition() -> Dictionary:
	var travel_s: float = 0.18
	var slash_s: float = 0.05
	return {"definition_id": "test-only/own-c52-dash-slash", "definition_revision": 1, "role_id": "C52", "raw_role": {"raw_damage": 4.0, "windup_s": 0.6, "lock_s": 0.4, "active_s": travel_s + slash_s, "recovery_s": 1.1, "attack_interval_s": 2.5, "max_hp": 12.0, "move_speed": 0.0}, "timing_floors": {"windup_s": 0.6, "lock_s": 0.4, "recovery_s": 1.1}, "recognition_s": 0.04, "route": [{"position": Vector3(-2, 0, 0), "at_s": 0.0}, {"position": Vector3.ZERO, "at_s": travel_s}], "travel_clearance": {"radius_m": 0.3, "height_m": 1.2}, "slash": {"world_origin": Vector3.ZERO, "direction": Vector3.RIGHT, "reach": 1.8, "cone_min_dot": 0.2, "origin_disk_radius": 0.1, "max_vertical_distance": 1.0, "los_height": 0.9, "commitment_duration_s": slash_s, "visual_duration_s": 0.2}, "presentation": {"presentation_id": "test-only/own-visible-echo", "presentation_revision": 1}}


func _install(arena: Dictionary) -> Dictionary:
	paused = false
	var answer: Dictionary = arena.scheduler.request_authored_replay(arena.actor, arena.actor.source_program(), _response(arena), arena.context)
	_expect(answer.get("accepted", false), "actual exclusive stationary source receives complete live-body own-enemy witness: " + str(answer.get("reason", "")))
	if not answer.get("accepted", false):
		return {}
	var projection: Dictionary = ReplayProjection.plan_authored(arena.scheduler, arena.actor.source_program(), arena.world, arena.floors, arena.context)
	_expect(projection.get("accepted", false), "native required footprint derives from exact own source/world/floor program")
	if not projection.get("accepted", false):
		return {}
	_expect(arena.actor.bind_projected(arena.scheduler, answer.reservation_id, {"hero": arena.player}, arena.floors, projection, arena.context), "projected owner binds exact actual exclusive Player without a capture gate: " + arena.actor.last_error)
	return {"id": answer.reservation_id, "lease": answer.reservation, "proof": answer.proof}


func _lock(arena: Dictionary, installed: Dictionary) -> Dictionary:
	await _until(arena, float(installed.lease.lock_from_s))
	var answer: Dictionary = arena.scheduler.commit_authored_replay(installed.id, _response(arena))
	_expect(answer.get("accepted", false), "actual due lock revalidates full lead and current actual Player: " + str(answer.get("reason", "")))
	if not answer.get("accepted", false):
		return {}
	installed.lease = answer.reservation
	_expect(arena.actor.advance().get("accepted", false), "own cursor consumes actual canonical lock without retiming or new proof")
	return answer.proof


func _response(arena: Dictionary) -> Dictionary:
	var response: Dictionary = arena.player.get_threat_response_state()
	response.merge({"world_revision": 1, "recognition_s": 0.04, "attack_input_margin_s": 0.02, "escape_directions": [Vector3.BACK], "return_directions": [Vector3.FORWARD], "floor_regions": arena.floors})
	return response


func _bindings(arena: Dictionary, source_snapshot: Dictionary = {}) -> Dictionary:
	var bindings: Dictionary = {"world_root": arena.world, "owners": {SOURCE_ID: arena.actor}, "actors": {"hero": arena.player}, "floors": {"floor": arena.floors[0]}}
	if not source_snapshot.is_empty():
		bindings["authored_owner_bindings"] = {SOURCE_ID: arena.actor.staged_source_binding(source_snapshot)}
	return bindings


func _capture(arena: Dictionary, label: String) -> Dictionary:
	var bindings: Dictionary = _bindings(arena)
	var player: Dictionary = arena.player.snapshot_state()
	var scheduler: Dictionary = arena.scheduler.snapshot_state(bindings)
	var playback: Dictionary = arena.actor.snapshot_state(scheduler, bindings)
	var source: Dictionary = arena.actor.capture_source(player, scheduler, playback)
	_expect(not player.is_empty() and not scheduler.is_empty() and not playback.is_empty() and not source.is_empty(), label + " deferred paused whole native unit captures: " + arena.actor.last_snapshot_error + " / " + arena.actor.source_snapshot_error)
	if source.is_empty() or playback.is_empty() or scheduler.is_empty() or player.is_empty():
		return {}
	var payload: Dictionary = {"player": player, "source": source, "scheduler": scheduler, "playback": playback}
	var path: String = "user://test-authored-echo-%d-%s.json" % [OS.get_process_id(), label]
	var store = Store.new(path)
	_expect(store.write_payload(payload), label + " actual isolated format2 write retains native exact types: " + store.last_error)
	var loaded: Dictionary = store.read_payload()
	_expect(Exact.stringify(loaded) == Exact.stringify(payload), label + " actual disk transport preserves complete paired byte/type identity")
	for suffix: String in ["", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	return loaded if loaded.has("playback") else {}


func _fresh(old: Dictionary, bundle: Dictionary) -> Dictionary:
	var fresh: Dictionary = await _arena(false, false)
	var callbacks: Array[String] = []
	fresh.actor.state_changed.connect(func(_value: Dictionary) -> void: callbacks.append("state"))
	fresh.actor.event_dispatched.connect(func(_event: Dictionary, _receipt: Dictionary) -> void: callbacks.append("event"))
	fresh.actor.source_hit_resolved.connect(func(_value: Dictionary) -> void: callbacks.append("source_hit"))
	fresh.actor.source_defeated.connect(func(_value: Dictionary) -> void: callbacks.append("source_defeated"))
	fresh.player.fired.connect(func(kind: String) -> void: callbacks.append(kind))
	fresh.player.world_action_executed.connect(func(_value: Dictionary) -> void: callbacks.append("player_action"))
	for cue: Node3D in fresh.actor.get_cues():
		cue.state_changed.connect(func(_value: Dictionary) -> void: callbacks.append("cue"))
	var bindings: Dictionary = _bindings(fresh, bundle.source)
	var error: String = _pair_error(fresh, bundle, bindings)
	_expect(error.is_empty(), "fresh actual parent fully prevalidates Player/source/Scheduler/Playback before mutation: " + error)
	if not error.is_empty():
		await _retire(fresh)
		return {}
	_expect(not fresh.actor.restore_state(bundle.playback, fresh.scheduler, bundle.scheduler, bindings, {"hero": fresh.player}, fresh.floors, fresh.context), "fresh Playback refuses commit before actual paired actor/Scheduler resources")
	var accepted: bool = fresh.player.restore_state(bundle.player) and fresh.actor.restore_source_physical(bundle.source, bundle.player, bundle.scheduler, bundle.playback)
	if accepted:
		accepted = fresh.scheduler.restore_state(bundle.scheduler, _bindings(fresh))
	if accepted:
		accepted = fresh.actor.restore_state(bundle.playback, fresh.scheduler, bundle.scheduler, _bindings(fresh), {"hero": fresh.player}, fresh.floors, fresh.context)
	if accepted:
		accepted = fresh.actor.verify_restored_source_phase(bundle.source)
	_expect(accepted and callbacks.is_empty(), "quiet actual physical actor -> Scheduler -> Playback -> source phase commits exact saved unit with no damage/cue/action/death callbacks: " + fresh.actor.last_snapshot_error + "/" + fresh.actor.source_snapshot_error)
	if not accepted:
		await _retire(fresh)
		return {}
	_expect(Exact.stringify(fresh.player.snapshot_state()) == Exact.stringify(bundle.player) and fresh.actor.hp == old.actor.hp and fresh.actor.source_phase() == bundle.source.phase, "fresh native whole restore neither heals resources nor restarts the source phase")
	return fresh


func _pair_error(arena: Dictionary, bundle: Dictionary, bindings: Dictionary) -> String:
	var error: String = arena.player.snapshot_error(bundle.player)
	if error.is_empty():
		error = arena.actor.source_record_error(bundle.source, bundle.player, bundle.scheduler, bundle.playback)
	if error.is_empty():
		error = arena.scheduler.snapshot_error(bundle.scheduler, bindings)
	if error.is_empty():
		error = arena.actor.snapshot_error(bundle.playback, arena.scheduler, bundle.scheduler, bindings, {"hero": arena.player}, arena.floors, arena.context)
	return error


func _atomic_negatives(arena: Dictionary, bundle: Dictionary) -> void:
	var before: String = Exact.stringify(bundle)
	for key: String in ["clock", "cycle", "source", "definition", "hp", "native", "position", "unknown", "pending", "origin"]:
		var bad: Dictionary = bundle.duplicate(true)
		match key:
			"clock": bad.source.clock_s = _one_bit(bad.source.clock_s)
			"cycle": bad.source.generation = float(bad.source.generation)
			"source": bad.source.source_id = "test-only/foreign-owner"
			"definition": bad.source.sequence.definition.raw_role.raw_damage = _one_bit(bad.source.sequence.definition.raw_role.raw_damage)
			"hp": bad.source.hp = -0.1
			"native": bad.source.native.material.depth_disabled = true
			"position": bad.source.physical.position[0] = _one_bit(bad.source.physical.position[0])
			"unknown": bad.source["equipment_ids"] = {}
			"pending": bad.playback["pending_delivery"] = {"events": []}
			"origin": bad.playback.exchange.adapter.timeline_origin_s = _one_bit(bad.playback.exchange.adapter.timeline_origin_s)
		_expect(not _pair_error(arena, bad, _bindings(arena, bad.source)).is_empty() and Exact.stringify(_capture(arena, "negative-" + key)) == before, "malformed exact paired " + key + " rejects before any native resources/clock/cursor mutation")
	var proxy := Node3D.new()
	arena.world.add_child(proxy)
	var codec = NativeCodec.new()
	_expect(not codec.record_error(bundle.source, proxy, bundle.player, bundle.scheduler, bundle.playback).is_empty(), "native source codec rejects a live caller proxy without querying foreign hooks")
	_expect(not codec.restore_physical(bundle.source, proxy, bundle.player, bundle.scheduler, bundle.playback) and not codec.verify_phase(bundle.source, proxy), "native source commit rejects live foreign handles before writing caller properties")
	proxy.free()
	_expect(not codec.record_error(bundle.source, proxy, bundle.player, bundle.scheduler, bundle.playback).is_empty(), "native source codec rejects a genuinely freed source handle before cast/access")
	_expect(not codec.restore_physical(bundle.source, proxy, bundle.player, bundle.scheduler, bundle.playback) and not codec.verify_phase(bundle.source, proxy), "native source commit rejects genuinely freed handles before property mutation")


func _terminal_negatives(arena: Dictionary, bundle: Dictionary) -> void:
	var before: Dictionary = arena.actor.state()
	for key: String in ["deadline", "world", "cooldown", "profile", "source_point", "opening_point", "generation"]:
		var bad: Dictionary = bundle.playback.duplicate(true)
		match key:
			"deadline": bad.exchange.recovery_until_s = _one_bit(bad.exchange.recovery_until_s)
			"world": bad.exchange.world_revision = float(bad.exchange.world_revision)
			"cooldown": bad.exchange.cooldown_until_s = _one_bit(bad.exchange.cooldown_until_s)
			"profile": bad.exchange.profile_id = "assisted"
			"source_point": bad.exchange.source_position[0] = _one_bit(bad.exchange.source_position[0])
			"opening_point": bad.exchange.opening_position[0] = _one_bit(bad.exchange.opening_position[0])
			"generation": bad.exchange.adapter.generation = float(bad.exchange.adapter.generation)
		_expect(not arena.actor.restore_state(bad, arena.scheduler, bundle.scheduler, _bindings(arena), {"hero": arena.player}, arena.floors, arena.context) and arena.actor.state() == before, "terminal own-enemy " + key + " mutation refuses exact original definition/profile/world/cooldown custody")
	# Labelled pure transport edge, not a physical exchange or a forged actor.
	var negative = Cursor.new()
	var positive = Cursor.new()
	var warning_s: float = float(bundle.playback.sequence.authored.warning_s)
	var negative_zero_bytes := PackedByteArray([0, 0, 0, 0, 0, 0, 0, 128])
	var negative_zero: float = negative_zero_bytes.decode_double(0)
	var roundtrip := PackedByteArray()
	roundtrip.resize(8)
	roundtrip.encode_double(0, negative_zero)
	_expect(roundtrip == negative_zero_bytes and negative_zero == 0.0, "TEST ONLY signed-zero control has actual native negative-zero bits despite numeric equality")
	_expect(negative.configure_authored(bundle.playback.sequence, EPOCH, GENERATION, 0.0) and not negative.arm(negative_zero, warning_s), "TEST ONLY authored transport arm rejects genuine negative-zero origin even though numeric equality collapses it")
	_expect(positive.configure_authored(bundle.playback.sequence, EPOCH, GENERATION, 0.0) and positive.arm(0.0, warning_s), "TEST ONLY canonical positive-zero authored transport arm remains supported")


func _screen_delta(arena: Dictionary, direction: Vector3) -> Vector2:
	var right: Vector3 = arena.camera.global_basis.x
	var down: Vector3 = arena.camera.global_basis.z
	right.y = 0.0
	down.y = 0.0
	return Vector2(direction.dot(right.normalized()), direction.dot(down.normalized())).normalized() * 100.0


func _swipe(arena: Dictionary, direction: Vector3) -> bool:
	var before: int = int(arena.host.get_input_observation_state().sequence)
	var start: Vector2 = Vector2(270, 760)
	var finish: Vector2 = start + _screen_delta(arena, direction)
	var press := InputEventScreenTouch.new()
	press.index = 5
	press.pressed = true
	press.position = start
	root.push_input(press, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 5
	drag.position = finish
	drag.relative = finish - start
	root.push_input(drag, true)
	var release := InputEventScreenTouch.new()
	release.index = 5
	release.position = finish
	root.push_input(release, true)
	return arena.host.get_input_observation_state().sequence == before + 1 and arena.host.get_input_observation_state().last_observation.kind == "swipe_release" and arena.player.get_committed_dash_state().active


func _tap(arena: Dictionary, direction: Vector3) -> bool:
	var before: Array = arena.player.get_world_action_records()
	var at: Vector2 = arena.host.get_aim_anchor() + _screen_delta(arena, direction)
	var touch := InputEventScreenTouch.new()
	touch.index = 5
	touch.pressed = true
	touch.position = at
	root.push_input(touch, true)
	touch = touch.duplicate()
	touch.pressed = false
	root.push_input(touch, true)
	var after: Array = arena.player.get_world_action_records()
	return after.size() == before.size() + 1 and after.back().kind == "primary" and arena.host.get_input_observation_state().last_observation.accepted


func _finished_dash(arena: Dictionary) -> void:
	for _tick: int in range(90):
		if not arena.player.get_committed_dash_state().active:
			return
		await _ticks(1)
	_expect(false, "bounded actual native dash completes")


func _until(arena: Dictionary, clock_s: float) -> void:
	for _tick: int in range(600):
		if arena.scheduler.get_clock() >= clock_s or paused:
			return
		await _ticks(1)
	_expect(false, "bounded real native physics reaches requested timeline clock")


func _ticks(count: int) -> void:
	for _tick: int in range(count):
		await physics_frame
		await process_frame


func _retire(arena: Dictionary) -> void:
	arena.host.set_process_unhandled_input(false)
	arena.host.queue_free()
	arena.viewport.queue_free()
	await process_frame


func _dispose(arena: Dictionary) -> void:
	await _retire(arena)
	paused = false
	await process_frame


func _one_bit(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes[0] = bytes[0] ^ 1
	return bytes.decode_double(0)


func _expect(accepted: bool, description: String) -> void:
	_checks += 1
	if accepted:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
