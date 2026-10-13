extends "res://tests/authored_echo_playback_smoke.gd"
## TEST ONLY bounded native first-cycle cost, never an FPS/balance benchmark.
## The original fixture's actual arena/definition/input/proof paths are retained.
## Only the actual source subclass wraps super.advance(). Scheduler retains its
## EXACT original Script. No proof cache, skipped guard, retiming or save claim.
## Three direct probes per pure API run separately at one fixed real clock; they
## are NOT nested production timings or a cache. Microsecond advance samples
## include timer overhead; sample bookkeeping occurs after the end timestamp.
## Cue, renderer guard and Cursor are the actual already-bound instances. No
## second guard/resource is created, and these probes never run inside advance.
## One real required Box visual is measured; production 16-visual art is absent.
const MAX_ADVANCES: int = 240

class TimedActor extends "res://tests/fixtures/authored_echo_actor.gd":
	var profiling: bool = false
	var profile_scheduler: Node3D
	var measurements: Array[Dictionary] = []
	var overflow: int = 0
	var automatic_tick: bool = false

	func _physics_process(delta: float) -> void:
		automatic_tick = true
		super._physics_process(delta)
		automatic_tick = false

	func advance() -> Dictionary:
		var clock_before: float = profile_scheduler.get_clock() if profiling and is_instance_valid(profile_scheduler) else -1.0
		var began: int = Time.get_ticks_usec()
		var answer: Dictionary = super.advance()
		var ended: int = Time.get_ticks_usec()
		if profiling:
			if measurements.size() < 240:
				measurements.append({"start_us": began, "finish_us": ended, "inclusive_us": ended - began, "clock_s": clock_before, "physics_frame": Engine.get_physics_frames(), "process_frame": Engine.get_process_frames(), "automatic_native_tick": automatic_tick, "phase": answer.get("phase", "rejected"), "accepted": answer.get("accepted", false), "event_count": answer.get("events", []).size()})
			else:
				overflow += 1
		return answer

var _profile_arena: Dictionary = {}
var _direct_guard_probes: Array[Dictionary] = []
var _probe_elapsed_us: int = 0
var _admission_bind_us: int = 0


func _run() -> void:
	root.size = Vector2i(540, 1170)
	var arena: Dictionary = await _arena()
	_profile_arena = arena
	var actor: TimedActor = arena.actor
	var scheduler = arena.scheduler
	var native_visuals: int = actor.get_enemy_apparition().get_authored_echo_render_bindings().required_visuals.size()
	var source_position: Vector3 = actor.global_position
	var source_basis: Basis = actor.global_basis
	var hp_before: float = arena.player.hp
	var actions: Array[Dictionary] = []
	var phases: Array[String] = []
	arena.player.world_action_executed.connect(func(record: Dictionary) -> void: actions.append(record.duplicate(true)))
	actor.state_changed.connect(func(value: Dictionary) -> void:
		var phase: String = String(value.cursor.get("phase", value.status))
		if not phases.has(phase): phases.append(phase))
	_expect(scheduler.get_script() == Scheduler, "profile retains EXACT real shared Scheduler Script required by ReplayWitness")
	actor.profile_scheduler = scheduler
	actor.profiling = true
	var wall_start: int = Time.get_ticks_usec()
	var clock_start: float = scheduler.get_clock()
	var admission_start: int = Time.get_ticks_usec()
	var installed: Dictionary = _install(arena)
	_admission_bind_us = Time.get_ticks_usec() - admission_start
	if installed.is_empty():
		await _finish_profile(arena, wall_start, clock_start, native_visuals, actions, phases)
		return
	_direct_guard_probes = _probe_guards(arena, installed.id)
	var proof: Dictionary = await _lock(arena, installed)
	if proof.is_empty():
		await _finish_profile(arena, wall_start, clock_start, native_visuals, actions, phases)
		return
	for segment: Dictionary in proof.path:
		if segment.kind not in ["first_escape_dash", "tether_positioning_dash"]: continue
		await _until(arena, float(segment.start_s))
		if _profile_budget_exhausted(): break
		_expect(_swipe(arena, (segment.to - segment.from).normalized()), "profile executes actual routed " + segment.kind)
		await _finished_dash(arena)
		_expect(arena.player.hp == hp_before and actor.global_position == source_position and actor.global_basis == source_basis, "profile harmless route retains real Hero HP and fixed native source")
	if not _profile_budget_exhausted():
		await _until(arena, float(proof.primary_time_s))
		_expect(actor.source_phase() == "recovery" and arena.player.global_position.distance_to(actor.global_position) <= float(arena.player.stats.primary_range), "real profile witness returns to ordinary hittable recovery knot")
		_expect(_tap(arena, (actor.global_position - arena.player.global_position).normalized()), "real profile first tap executes ordinary primary")
		_expect(actor.dead and actor.hp == 0.0 and actor.source_hits == 1 and arena.player.hp == hp_before, "real profile route defeats own HP source once without Hero damage")
	var kinds: Array[String] = []
	for action: Dictionary in actions: kinds.append(action.kind)
	_expect(kinds.count("dash") == 2 and kinds.count("primary") == 1 and not kinds.has("blast"), "measurement workload contains two native dashes and one ordinary primary; natural ammo regeneration preserved")
	await _finish_profile(arena, wall_start, clock_start, native_visuals, actions, phases)


func _probe_guards(arena: Dictionary, reservation_id: String) -> Array[Dictionary]:
	# Immediately after genuine admission/bind. No await, input, callback emission,
	# advance or authority mutation; these are SEPARATE current pure read probes.
	var program: Dictionary = arena.actor.source_program()
	var clock_s: float = arena.scheduler.get_clock()
	var cues: Array[Node3D] = arena.actor.get_cues()
	var projection: Dictionary = arena.actor.get_footprint_projection()
	var renderer_guard: Variant = arena.actor.get("_enemy_renderer_guard")
	var cursor: Variant = arena.actor.get("_cursor")
	var actual_refs_ready: bool = cues.size() == 1 and projection.get("events", []).size() == 1 and is_instance_valid(renderer_guard) and renderer_guard.has_method("current_error") and is_instance_valid(cursor) and cursor.has_method("snapshot_error")
	_expect(actual_refs_ready, "pure probes use the genuine one-event Cue and actual retained native renderer guard/Cursor")
	if not actual_refs_ready:
		return []
	var cue: Node3D = cues[0]
	var event: Dictionary = projection.events[0]
	var cursor_snapshot: Dictionary = cursor.snapshot_state()
	_expect(Exact.stringify(cursor_snapshot.last_advanced_clock_s) == Exact.stringify(clock_s) and cursor_snapshot.source_epoch == program.source_epoch and cursor_snapshot.generation == program.generation, "separate probes start at the actual same prelock native clock/epoch/generation")
	var last_error: String = arena.scheduler.last_error
	var snapshot_error: String = arena.scheduler.last_snapshot_error
	var own_diagnostics: Array = [arena.actor.last_error, cue.last_error, renderer_guard.last_error, cursor.last_error, cursor.last_snapshot_error]
	var cue_state: PackedByteArray = var_to_bytes(cue.state())
	var physics_frame: int = Engine.get_physics_frames()
	var process_frame_number: int = Engine.get_process_frames()
	var advance_count: int = arena.actor.measurements.size()
	var pose: Transform3D = arena.actor.global_transform
	var source_hp: float = arena.actor.hp
	var hero_hp: float = arena.player.hp
	var history_size: int = arena.player.get_world_action_records().size()
	var results: Array[Dictionary] = []
	var all_started: int = Time.get_ticks_usec()
	for repetition: int in range(3):
		for api: String in ["replay_reservation_error", "authored_replay_source_error", "cue.projection_error", "renderer_guard.current_error", "cursor.snapshot_error"]:
			var began: int = Time.get_ticks_usec()
			var error: String = ""
			match api:
				"replay_reservation_error":
					error = arena.scheduler.replay_reservation_error(reservation_id)
				"authored_replay_source_error":
					error = arena.scheduler.authored_replay_source_error(arena.actor, program, arena.context, arena.floors)
				"cue.projection_error":
					error = cue.projection_error(event)
				"renderer_guard.current_error":
					error = renderer_guard.current_error()
				"cursor.snapshot_error":
					error = cursor.snapshot_error(cursor_snapshot, program, program.source_epoch, int(program.generation), clock_s)
			var ended: int = Time.get_ticks_usec()
			results.append({"call": api, "repetition": repetition, "start_us": began, "finish_us": ended, "inclusive_us": ended - began, "fixed_clock_s": clock_s, "clock_after_s": arena.scheduler.get_clock(), "accepted": error.is_empty(), "error": error, "scope": "separate_pure_probe_not_nested_native_advance"})
			_expect(error.is_empty(), "separate actual pure " + api + " probe authenticates genuine admitted source")
	_probe_elapsed_us = Time.get_ticks_usec() - all_started
	_expect(Exact.stringify(arena.scheduler.get_clock()) == Exact.stringify(clock_s) and arena.scheduler.last_error == last_error and arena.scheduler.last_snapshot_error == snapshot_error and arena.actor.global_transform == pose and arena.actor.hp == source_hp and arena.player.hp == hero_hp and arena.player.get_world_action_records().size() == history_size, "separate same-clock pure probes retain real clocks/diagnostics/source/Hero/history")
	_expect(arena.actor.get("_enemy_renderer_guard") == renderer_guard and arena.actor.get("_cursor") == cursor and arena.actor.get_cues()[0] == cue and [arena.actor.last_error, cue.last_error, renderer_guard.last_error, cursor.last_error, cursor.last_snapshot_error] == own_diagnostics and var_to_bytes(cue.state()) == cue_state and Exact.stringify(cursor.snapshot_state()) == Exact.stringify(cursor_snapshot) and Exact.stringify(arena.actor.get_footprint_projection()) == Exact.stringify(projection), "separate native probes retain actual guard/Cursor/Cue identities, diagnostics, projection and delivery prefix")
	_expect(Engine.get_physics_frames() == physics_frame and Engine.get_process_frames() == process_frame_number and arena.actor.measurements.size() == advance_count, "fixed-clock probes neither yield a native frame nor add a production advance sample")
	return results


func _profile_budget_exhausted() -> bool:
	return not _profile_arena.is_empty() and (_profile_arena.actor.measurements.size() >= MAX_ADVANCES or _profile_arena.actor.overflow > 0)


func _until(arena: Dictionary, clock_s: float) -> void:
	for _tick: int in range(MAX_ADVANCES):
		if arena.scheduler.get_clock() >= clock_s or paused: return
		if _profile_budget_exhausted():
			_expect(false, "bounded profile native advance budget reached before required route deadline")
			return
		await _ticks(1)
	_expect(false, "bounded native profile clock reaches required route deadline")


func _finished_dash(arena: Dictionary) -> void:
	for _tick: int in range(90):
		if not arena.player.get_committed_dash_state().active: return
		if _profile_budget_exhausted():
			_expect(false, "bounded profile native advance budget reached before genuine dash ended")
			return
		await _ticks(1)
	_expect(false, "actual profile dash ends within its ordinary bounded fixture window")


func _finish_profile(arena: Dictionary, wall_start: int, clock_start: float, visuals: int, actions: Array, phases: Array) -> void:
	var wall_finish: int = Time.get_ticks_usec()
	var clock_finish: float = arena.scheduler.get_clock()
	var actor: TimedActor = arena.actor
	actor.profiling = false
	var advances: Array = actor.measurements.duplicate(true)
	_expect(not advances.is_empty() and actor.overflow == 0 and advances.size() <= MAX_ADVANCES, "bounded raw native measurements remain complete")
	var actual_ticks: int = 0
	var last_clock: float = -1.0
	var native_costs: Array[int] = []
	var costs_by_phase: Dictionary = {}
	for sample: Dictionary in advances:
		_expect(sample.accepted and sample.inclusive_us >= 0 and sample.clock_s >= last_clock, "profile native advance accepts original authority and monotonic real clock")
		last_clock = sample.clock_s
		if not sample.automatic_native_tick: continue
		actual_ticks += 1
		native_costs.append(sample.inclusive_us)
		if not costs_by_phase.has(sample.phase): costs_by_phase[sample.phase] = []
		costs_by_phase[sample.phase].append(sample.inclusive_us)
	var phase_summary: Dictionary = {}
	for phase: String in costs_by_phase: phase_summary[phase] = _cost_summary(costs_by_phase[phase])
	_expect(actual_ticks > 0 and phases.has("warning") and phases.has("active") and phases.has("recovery"), "profile actually observes finite native warning/active/recovery execution")
	var action_summary: Array = []
	for action: Dictionary in actions: action_summary.append({"kind": action.kind, "started_at_s": action.started_at_s, "completed_at_s": action.completed_at_s, "hits": action.get("hits", 0), "damage": action.get("damage", 0.0)})
	var probe_costs: Dictionary = {}
	for probe: Dictionary in _direct_guard_probes:
		if not probe_costs.has(probe.call): probe_costs[probe.call] = []
		probe_costs[probe.call].append(probe.inclusive_us)
	var probe_summary: Dictionary = {}
	for api: String in probe_costs: probe_summary[api] = _cost_summary(probe_costs[api])
	var report: Dictionary = {"api_revision": "test-only-authored-echo-performance-2", "schema_version": 2, "engine": Engine.get_version_info(), "display_driver": DisplayServer.get_name(), "physics_ticks_per_second": Engine.physics_ticks_per_second, "viewport_size": [270, 585], "native_output": [540, 1170], "required_native_visuals": visuals, "wall_start_us": wall_start, "wall_finish_us": wall_finish, "wall_elapsed_us": wall_finish - wall_start, "simulation_start_s": clock_start, "simulation_finish_s": clock_finish, "simulation_elapsed_s": clock_finish - clock_start, "automatic_native_advances": actual_ticks, "advance_cost_summary_us": _cost_summary(native_costs), "advance_phase_summary_us": phase_summary, "admission_projection_bind_inclusive_us": _admission_bind_us, "separate_fixed_clock_probe_elapsed_us": _probe_elapsed_us, "separate_fixed_clock_probe_summary_us": probe_summary, "native_phases_observed": phases, "actual_world_actions": action_summary, "advance_samples": advances, "separate_fixed_clock_guard_probes": _direct_guard_probes, "limitations": "Instrumented one-Box native source first cycle with EXACT real Scheduler; advance end timestamps exclude appended sample bookkeeping. Cycle wall elapsed includes separately reported direct fixed-clock probes, admission/projection/bind, native loop waits and other observer overhead; probe costs are not nested production call counts. Three samples per API inspect only the genuine admitted prelock clock; Cue, renderer guard and Cursor probes use the actual retained instances, not new guards or cached authority. Not actual authored A3-L3, production 16-visual art, portrait review, FPS, CPU monitor percentiles, sustained performance or a latency acceptance threshold. No guards or contact/proof authority bypassed."}
	print("AUTHORED_ECHO_PROFILE_JSON ", JSON.stringify(report))
	await _dispose(arena)
	print("Authored echo performance smoke: %d checks, %d failures; native-only first-cycle measurement" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _cost_summary(values: Array) -> Dictionary:
	if values.is_empty(): return {"count": 0}
	var ordered: Array = values.duplicate()
	ordered.sort()
	var total: int = 0
	for value: int in ordered: total += value
	return {"count": ordered.size(), "inclusive_total_us": total, "mean_us": float(total) / ordered.size(), "p50_us": ordered[int(ceil(ordered.size() * 0.50)) - 1], "p95_us": ordered[int(ceil(ordered.size() * 0.95)) - 1], "max_us": ordered[-1]}


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
	var source = TimedActor.new()
	source.name = "ActualFixedKnotC52"
	world.add_child(source)
	var prepared: Dictionary = {"world_revision": 1, "collision_fingerprint": context.world_collision_fingerprint, "floor_signature": context.world_floor_signature}
	_expect(source.initialize_source(SOURCE_ID, EPOCH, GENERATION, _definition(), "standard", prepared) and source.attach_source_scheduler(scheduler), "genuine shared Playback subclass owns immutable native definition, HP, visible mesh and fixed endpoint")
	_expect(source.configure_authored("test-only/physical-echo", source.source_program(), EPOCH, GENERATION), "own enemy configure_authored uses its actual source hooks: " + source.last_error)
	return {"viewport": viewport, "world": world, "floor": collision, "floors": floors, "camera": camera, "host": host, "player": hero, "scheduler": scheduler, "actor": source, "context": context}
