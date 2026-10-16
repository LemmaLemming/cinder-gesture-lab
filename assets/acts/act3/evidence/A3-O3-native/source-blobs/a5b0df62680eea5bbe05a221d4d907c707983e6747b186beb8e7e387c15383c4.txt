extends "res://tests/acts/act3/pillars_before_time_focused.gd"
## One finite managed Echo + independently due native pulse. Reuses only O1's
## post-actor observer, exact comparisons, public cleanup and watchdog helpers.
## Actual controller dash/slash only: no HP/ammo/clock/pose/history writes.
## No Optional transport, fresh candidate, route, defeat-all or art claim.

const O3_ROOM: String = "res://scenes/acts/act3/a3_o3_irontick_reflection.tscn"
const ECHO_ID: String = "o3-first-echo"
const PULSE_ID: String = "o3-first-pulse"
const FLOOR: Rect2 = Rect2(-7, -11, 14, 22)
const POINT_EPS: float = 0.005
const TIME_EPS: float = 0.000001
const DEADLINES: Array[String] = ["start_s","lock_from_s","active_from_s","active_until_s","recovery_until_s","cooldown_until_s"]
const DASHES: Array[String] = ["escape_dash","first_escape_dash","second_escape_dash","positioning_dash","tether_positioning_dash"]

var _echo: Node3D
var _pulse: CinderLaneMechanism
var _reflection: Node3D
var _starting_hp: float
var _starting_shells: int
var _stats: Dictionary = {}
var _fired: Array[String] = []
var _events: Dictionary = {}
var _phases: Dictionary = {}
var _pulse_phases: Dictionary = {}
var _echo_lease: Dictionary = {}
var _pulse_lease: Dictionary = {}
var _holding_echo: bool = false
var _real_transform: Transform3D
var _render_origin: Vector3
var _render_travel: float = 0.0


func _run() -> void:
	create_timer(90.0, true, false, true).timeout.connect(_watchdog)
	if not _expect(OS.get_cmdline_user_args().is_empty(), "bounded prototype accepts no selectors"):
		await _finish()
		return
	if await _open_o3():
		if await _warning():
			if await _paused_pair("unarmed warning", true):
				if await _lock():
					if await _follow_armed():
						if await _terminal():
							await _paused_pair("surviving terminal", false)
	await _finish()


func _open_o3() -> bool:
	_game = MainScene.instantiate()
	root.add_child(_game)
	_game.call("open_bench")
	if not _expect(paused and _game.call("is_lab_level") and get_nodes_in_group("enemies").is_empty(), "actual Main starts at its enemy-free paused lab"): return false
	if not _expect(_game.call("load_level_scene", O3_ROOM), "public Main loads owned O3 prototype", String(_game.get("level_load_error"))): return false
	_game.call("open_bench")
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _expect(_level != null and _hero != null and _level.level_id == "A3-O3" and _level.scene_file_path == O3_ROOM and _level.contract_error().is_empty(), "native O3 identity and one actual shared Hero bind"): return false
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	_echo = _level.get("echo") as Node3D
	_pulse = _level.get("mechanism") as CinderLaneMechanism
	_reflection = _level.get_node_or_null("HarmlessOutlinedReflection") as Node3D
	if not _expect(_scheduler != null and _echo != null and _pulse != null and _reflection != null and String(_level.call("runtime_error")).is_empty(), "actual managed Echo/pulse/reflection/Scheduler configure", String(_level.call("runtime_error"))): return false
	_starting_hp = _hero.hp
	_starting_shells = _hero.shells
	_kit = _hero.equipment.snapshot()
	_stats = _hero.equipment.resolved_stats()
	_real_transform = _echo.global_transform
	var playback: Dictionary = _echo.call("state")
	var bindings: Dictionary = _level.call("scheduler_bindings")
	if not _expect(_hero.global_position == Vector3(0,0.1,8) and _hero.presentation_id == "act3_traveller" and _hero.hp == _hero.max_hp and not _hero.dead and _scheduler.get_clock() == 0.0 and _scheduler.encounter_profile().get("id") == "standard" and _scheduler.reservations().is_empty() and _hero.get_world_action_records().is_empty() and _echo.global_position == Vector3(0,0,6) and _echo.get("hp") == 36.0 and _echo.get("max_hp") == 36.0 and not _echo.get("dead") and _echo.call("source_cycles_managed") and playback.status == "cycle_ready" and _echo.call("get_authored_cycle_generation") == 1 and _pulse.state().cycle == 0 and Codec.keys_error(bindings.owners,[ECHO_ID,PULSE_ID]).is_empty() and bindings.owners[ECHO_ID] == _echo and bindings.owners[PULSE_ID] == _pulse and bindings.actors == {"hero":_hero} and bindings.floors.size() == 1 and bindings.floors["firm-shore"].safe_rect == FLOOR, "fresh native ready journal/36HP knot/idle pulse share exact Hero and14x22 floor"): return false
	var collision: CollisionShape3D = bindings.floors["firm-shore"].collision
	var body: StaticBody3D = collision.get_parent() as StaticBody3D
	var signature: Dictionary = _scheduler.authored_floor_signature(bindings.world_root,bindings.floors.values())
	if not _expect(body != null and body.collision_layer == 1 and body.collision_mask == 0 and collision.shape is BoxShape3D and not collision.disabled and (collision.shape as BoxShape3D).size == Vector3(14,1,22) and body.global_position == Vector3(0,-0.5,0) and signature.get("accepted",false) and signature.signature.size() == 1 and _harmless(_reflection) and _echo.is_in_group("enemies") and _echo.has_method("take_damage") and get_nodes_in_group("enemies").size() == 1, "actual stable shore and real HP endpoint remain distinct from the harmless non-target image",str(signature)): return false
	var definition: Dictionary = _level.call("native_definition")
	if not _expect(_exact(definition,_echo.call("source_definition")) and definition.route.size() == 2 and definition.route[0].position == Vector3(0,0,4) and definition.route[0].at_s == 0.0 and definition.route[1].position == Vector3(0,0,6) and definition.route[1].at_s == 0.30 and definition.slash.world_origin == Vector3(0,0,6) and definition.slash.commitment_duration_s == 0.18 and definition.raw_role.max_hp == 36.0 and definition.raw_role.raw_damage == 18.0, "actual Echo uses its unchanged finite own route/slash/role rather than any Player recording"): return false
	_level.checkpoint_requested.connect(func(_id: String, value: String, _kind: String) -> void: _checkpoints.append(value))
	_level.completion_requested.connect(func(_id: String, value: String) -> void: _completions.append(value))
	_level.contact_exit_requested.connect(func(_id: String, value: String) -> void: _exits.append(value))
	_hero.world_action_executed.connect(_on_action)
	_hero.fired.connect(func(kind: String) -> void: _fired.append(kind))
	_echo.connect("event_dispatched",func(_native_event: Dictionary,_receipt: Dictionary) -> void: _event("dispatch"))
	_echo.connect("source_hit_resolved",func(_result: Dictionary) -> void: _event("ordinary_hit"))
	_echo.connect("source_defeated",func(_result: Dictionary) -> void: _event("defeat"))
	_echo.connect("state_changed",func(_state: Dictionary) -> void: _event("echo_state"))
	_pulse.state_changed.connect(func(_state: Dictionary) -> void: _event("pulse_state"))
	_pulse.hit_resolved.connect(func(_id: String,_cycle: int,_result: Dictionary) -> void: _event("pulse_contact"))
	_barrier = PostActorBarrier.new()
	_barrier.name = "O3FocusedPostActorBarrier"
	root.add_child(_barrier)
	for _frame: int in range(4): await process_frame
	_game.call("resume_lab")
	for _index: int in range(12):
		if _hero.is_on_floor(): break
		if not await _tick(): return false
	return _expect(_hero.is_on_floor() and _hero.get_threat_response_state().stable, "actual floor registration settles before any native body sweep/action")


func _harmless(node: Node) -> bool:
	if node is CollisionObject3D or node is CollisionShape3D or not node.get_groups().is_empty() or node.has_method("take_damage"): return false
	for property: Dictionary in node.get_property_list():
		if property.name in ["hp","max_hp","dead"]: return false
	for child: Node in node.get_children():
		if not _harmless(child): return false
	return true


func _warning() -> bool:
	for _index: int in range(180):
		var playback: Dictionary = _echo.call("state")
		if playback.status == "running":
			var lease: Dictionary = _scheduler.replay_reservation_state(String(playback.reservation_id))
			return _expect(not lease.is_empty() and lease.adapter.kind == "authored_replay" and not lease.adapter.locked and not playback.cursor.armed and _echo.call("source_phase") == "warning" and _scheduler.get_clock() < float(lease.lock_from_s) and playback.lifecycle.terminal_receipts.is_empty() and _actions.is_empty(), "first genuine managed warning retains its own native program/unarmed lease without Player recordings")
		if not _expect(playback.status == "cycle_ready", "first source remains ready until real admission",str(playback)): return false
		if not await _tick(): return false
	return _expect(false,"bounded genuine unarmed warning admission",str(_level.call("state")))


func _lock() -> bool:
	for _index: int in range(240):
		var state: Dictionary = _level.call("state")
		if state.echo_record.locked:
			var playback: Dictionary = _echo.call("state")
			_echo_lease = _scheduler.replay_reservation_state(String(playback.reservation_id))
			_holding_echo = true
			var proof: Dictionary = state.echo_record.proof
			return _expect(not _echo_lease.is_empty() and _echo_lease.adapter.locked and playback.cursor.armed and proof.get("accepted",false) and proof.get("uses_blast") == false and proof.get("uses_invulnerability") == false and _echo.call("get_authored_cycle_generation") == 1, "actual due lock reproves the native own route and ordinary escape-return against the independent danger union",str(state))
		if not _expect((_echo.call("state") as Dictionary).status == "running", "held warning survives until its actual due commit"): return false
		if not await _tick(): return false
	return _expect(false,"bounded genuine due lock",str(_level.call("state")))


func _follow_armed() -> bool:
	var proof: Dictionary = (_level.call("state") as Dictionary).echo_record.proof
	if not _expect(proof.get("path") is Array and not proof.path.is_empty() and proof.path.size() <= 10 and proof.get("attack_position") is Vector3 and is_finite(float(proof.get("primary_time_s",INF))), "real armed witness exposes finite public positions/deadlines"): return false
	var first: bool = true
	var escaped: bool = false
	var last_end_s: float = -1.0
	var previous: Dictionary = {}
	for segment: Dictionary in proof.path:
		if not _expect(segment.get("from") is Vector3 and segment.get("to") is Vector3 and segment.from.is_finite() and segment.to.is_finite() and is_finite(float(segment.start_s)) and is_finite(float(segment.end_s)) and float(segment.end_s) >= float(segment.start_s), "native path segment retains finite positions/times"): return false
		if not previous.is_empty() and not _expect(absf(float(previous.end_s)-float(segment.start_s)) <= TIME_EPS and previous.to.distance_to(segment.from) <= POINT_EPS, "actual accepted own path remains continuous"): return false
		previous = segment
		var scheduled_s: float = maxf(float(segment.start_s),last_end_s)
		if first and segment.kind == "recognition_and_ready":
			if not _expect(segment.from == segment.to and _hero.global_position.distance_to(segment.from) <= POINT_EPS and _scheduler.get_clock() < float(segment.end_s), "held pair joins only unchanged first recognition before its original end"): return false
			scheduled_s = maxf(scheduled_s,_scheduler.get_clock())
		first = false
		if segment.kind in ["ordinary_primary","ordinary_primary_full_recovery"]: break
		if DASHES.has(String(segment.kind)):
			if not await _until_o3(scheduled_s): return false
			if not await _dash_o3(segment,scheduled_s): return false
			last_end_s = float(_actions.back().completed_at_s)
			escaped = escaped or segment.kind in ["escape_dash","first_escape_dash"]
		else:
			if not _expect(segment.from == segment.to and _hero.global_position.distance_to(segment.from) <= POINT_EPS, "passive witness waits at its actual unchanged world point"): return false
			if not await _until_o3(float(segment.end_s),segment.from): return false
	if not await _until_o3(float(proof.primary_time_s)): return false
	var hp_before: float = float(_echo.get("hp"))
	var damage: float = float(_stats.primary_damage)
	if not _expect(escaped and _echo.call("source_phase") == "recovery" and _hero.is_on_floor() and _hero.global_position.distance_to(proof.attack_position) <= POINT_EPS and float(proof.response_complete_s) < float(_echo_lease.recovery_until_s) and float(_hero.get_threat_response_state().primary_cooldown_left_s) == 0.0 and hp_before == 36.0 and damage > 0.0 and damage < hp_before, "real selected response reaches the same ordinary 36HP native recovery opening without blast"): return false
	var count: int = _actions.size()
	var direction: Vector3 = _echo.global_position-_hero.global_position
	direction.y = 0.0
	var hits: int = _hero.slash(direction.normalized())
	_holding_echo = false
	return _expect(hits == 1 and _actions.size() == count+1 and _actions.back().kind == "primary" and _actions.back().hits == 1 and _actions.back().damage == damage and _echo.get("hp") == hp_before-damage and not _echo.get("dead") and _echo.get("source_hits") == 1 and _events.get("ordinary_hit",0) == 1 and not _fired.has("blast") and _render_travel > 0.1 and _phases.has("warning") and _phases.has("lock") and _phases.has("active") and _phases.has("recovery"), "one actual public ordinary primary damages only the real surviving endpoint after native own-route travel")


func _dash_o3(segment: Dictionary, scheduled_s: float) -> bool:
	var response: Dictionary = _hero.get_threat_response_state()
	var from: Vector3 = _hero.global_position
	var direction: Vector3 = segment.to-segment.from
	direction.y = 0.0
	direction = direction.normalized()
	var distance: float = float(_stats.dash_distance)
	var bindings: Dictionary = _level.call("scheduler_bindings")
	var sweep: Dictionary = BodySweep.sweep(_hero,_hero.global_transform,direction*distance,bindings.floors.values())
	if not _expect(response.stable and float(response.dash_cooldown_left_s) == 0.0 and response.motion.queued_dash == Vector3.ZERO and from.distance_to(segment.from) <= POINT_EPS and not sweep.has("error") and not sweep.get("collided",true) and sweep.get("end") is Vector3 and sweep.end.distance_to(from+direction*distance) <= POINT_EPS, "actual grounded body/floor sweep admits the full unbuffered native response dash",str(sweep)): return false
	var count: int = _actions.size()
	var requested_s: float = _hero.get_world_action_clock()
	if not _expect(_hero.request_dash(direction), "public controller accepts the actual witness dash"): return false
	for _index: int in range(60):
		if not await _tick(): return false
		if _actions.size() <= count: continue
		var action: Dictionary = _actions.back()
		var start_s: float = float(action.started_at_s)
		var end_s: float = float(action.completed_at_s)
		var native_duration_s: float = float(ceili(float(_stats.dash_duration)/_tick_seconds()))*_tick_seconds()
		var safe: bool = end_s < float(_echo_lease.active_from_s) if segment.kind in ["escape_dash","first_escape_dash"] else start_s >= float(_echo_lease.active_until_s) and end_s < float(_echo_lease.recovery_until_s)
		return _expect(_actions.size() == count+1 and action.kind == "dash" and not action.blocked and not action.collision_shortened and not action.movement_damage and action.world_origin == from and action.landing == _hero.global_position and action.landing.distance_to(segment.to) <= POINT_EPS and absf(float(action.distance)-distance) <= POINT_EPS and _hero.is_on_floor() and _exact(action.equipment_ids,_kit) and _exact(action.resolved_stats,_stats) and not CinderPlayer.encode_world_action_record(action,_hero.get_world_action_clock()).is_empty() and _exact(start_s,requested_s) and start_s >= scheduled_s-TIME_EPS and start_s <= scheduled_s+_tick_seconds()+TIME_EPS and absf(end_s-start_s-native_duration_s) <= TIME_EPS and absf(_scheduler.get_clock()-end_s) <= TIME_EPS and safe, "actual dash independently preserves request tick, native duration, full landing and unchanged safe window",str({"kind":segment.kind,"planned_start":segment.start_s,"planned_end":segment.end_s,"scheduled":scheduled_s,"requested":requested_s,"actual_start":start_s,"actual_end":end_s,"native_duration":native_duration_s,"safe":safe}))
	return _expect(false,"bounded actual dash completion")


func _until_o3(target_s: float, point: Variant = null) -> bool:
	if not _expect(is_finite(target_s), "finite authoritative witness deadline"): return false
	for _index: int in range(600):
		if point is Vector3 and not _expect(_hero.global_position.distance_to(point) <= POINT_EPS, "native passive path retains its original position"): return false
		if _scheduler.get_clock() >= target_s:
			return _expect(_scheduler.get_clock() <= target_s+_tick_seconds()+TIME_EPS,"action follows its first available native proof tick",str({"target":target_s,"actual":_scheduler.get_clock()}))
		if not await _tick(): return false
	return _expect(false,"bounded native witness deadline")


func _terminal() -> bool:
	for _index: int in range(900):
		if _echo.call("source_phase") == "complete" and _pulse.state().status == "complete":
			var receipt: Dictionary = _echo.call("get_authored_cycle_terminal_receipt")
			var clean: bool = not receipt.is_empty() and receipt.generation == 1 and receipt.exchange.id == _echo_lease.id and receipt.opportunities.size() == 1
			for opportunity: Dictionary in receipt.get("opportunities",[]): clean = clean and not opportunity.contact and not opportunity.damage_attempted
			return _expect(clean and (_echo.call("state") as Dictionary).lifecycle.terminal_receipts.size() == 1 and _events.get("dispatch",0) == 1 and _events.get("defeat",0) == 0 and _events.get("pulse_contact",0) == 0 and not _pulse_lease.is_empty() and float(_pulse_lease.start_s) >= 0.65 and _pulse.state().cycle == 1 and _pulse.get_cue().state().phase == "clear" and _scheduler.reservations().is_empty() and _pulse_phases.has("warning") and _pulse_phases.has("lock") and _pulse_phases.has("active") and _pulse_phases.has("recovery") and _hero.hp == _starting_hp and not _echo.get("dead"), "one finite managed terminal and independent due pulse retain actual contact-free history, surviving HP and clear leases/cues")
		if not await _tick(): return false
	return _expect(false,"bounded own Echo and independent pulse reach genuine terminals",str(_level.call("state")))


func _paused_pair(label: String, restore_identical: bool) -> bool:
	if not await _presentation_o3(): return false
	if not _expect(_game.call("request_pause_deferred"), "public complete-tick pause at "+label): return false
	for _frame: int in range(4): await process_frame
	if not _expect(paused and not _game.call("is_pause_requested"), "native pause request completes before aggregate access"): return false
	var before: Dictionary = _observation_o3()
	for _frame: int in range(5): await process_frame
	if not _expect(_exact(before,_observation_o3()), "paused Hero/Source/Playback/pulse/Scheduler/current view clocks and custody freeze exactly"): return false
	var camera: Camera3D = _game.get("camera") as Camera3D
	var hud: GameHUD = _game.get("hud") as GameHUD
	var pair: Dictionary = {"player":_hero.snapshot_state(),"level":_level.snapshot_state_for_presentation(camera,hud)}
	if not _expect(not pair.player.is_empty() and not pair.level.is_empty() and _hero.snapshot_error(pair.player).is_empty() and _level.snapshot_error_with_player(pair.level,pair.player).is_empty() and _exact(pair.level,_level.snapshot_state()), "whole actual typed managed source/playback/pulse/Scheduler/Hero pair captures and validates at "+label,_hero.last_snapshot_error+"; "+_level.last_snapshot_error): return false
	var local: Dictionary = pair.level.local
	if not _expect(local.scheduler.schema_version == 3 and local.echo.actor.schema_version == 2 and local.echo.playback.api_revision == "authored-echo-playback-2" and local.echo.actor.clock_s == local.scheduler.clock_s and local.echo.playback.clock_s == local.scheduler.clock_s and local.pulse.mechanism.clock_s == local.scheduler.clock_s and pair.player.world_actions.clock_s == local.scheduler.clock_s and local.pulse.eligible_at_s == 0.65 and not pair.level.progress.completed and pair.level.progress.checkpoint_ids.is_empty(), "native typed aggregate retains independent due rule and exact shared clocks without checkpoint/progress fabrication"): return false
	var wire: String = ExactJson.stringify(pair)
	var read: Dictionary = ExactJson.parse(wire)
	if not _expect(not wire.is_empty() and read.get("accepted",false) and read.get("value") is Dictionary and _exact(pair,read.value) and _level.snapshot_error_with_player(read.value.level,read.value.player).is_empty(), "ExactJson preserves every native whole-pair type/float/history at "+label): return false
	for kind: String in ["source-clock","pulse-due","scheduler-clock","source-hp","generation-type","missing-pulse","floor","unknown","progress"]:
		var bad: Dictionary = pair.level.duplicate(true)
		match kind:
			"source-clock": bad.local.echo.actor.clock_s += 0.00000001
			"pulse-due": bad.local.pulse.eligible_at_s += 0.01
			"scheduler-clock": bad.local.scheduler.clock_s += 0.00000001
			"source-hp": bad.local.echo.actor.hp = -0.1
			"generation-type": bad.local.echo.actor.generation = float(bad.local.echo.actor.generation)
			"missing-pulse": bad.local.erase("pulse")
			"floor": bad.local.world.floor_signature[0].safe_rect[2] = 13.5
			"unknown": bad.local["foreign"] = true
			"progress": bad.progress.completed = true
		var observation: Dictionary = _observation_o3()
		var error: String = _level.snapshot_error_with_player(bad,pair.player)
		if not _expect(not error.is_empty() and not _level.restore_state(bad) and _exact(observation,_observation_o3()) and _exact(pair.player,_hero.snapshot_state()) and _exact(pair.level,_level.snapshot_state()), "malformed "+kind+" rejects through pure/restore paths atomically",error): return false
	var foreign := Camera3D.new()
	foreign.name = "O3ForeignUnselectedCamera"
	(_level.get_parent() as Node3D).add_child(foreign)
	var rejected: Dictionary = _level.snapshot_state_for_presentation(foreign,hud)
	var optical_error: String = _level.last_snapshot_error
	foreign.free()
	if not _expect(rejected.is_empty() and not optical_error.is_empty() and _exact(before,_observation_o3()) and camera.get_viewport().get_camera_3d() == camera and _exact(pair.level,_level.snapshot_state_for_presentation(camera,hud)), "actual foreign noncurrent native camera rejects without a donor alias or state mutation",optical_error): return false
	if restore_identical:
		# Diagnostic proof/projection/lease caches are rebuilt from native wire;
		# they cannot authenticate a response after restore. Exact authoritative
		# pair/native state, positions, lock and every observed event remain fixed.
		var observation: Dictionary = _observation_o3(true)
		if not _expect(_hero.restore_state(read.value.player) and _level.restore_state(read.value.level) and _exact(observation,_observation_o3(true)) and _exact(pair.player,_hero.snapshot_state()) and _exact(pair.level,_level.snapshot_state()), "same actual pair restores quietly Hero→source physical→Scheduler→Playback→pulse without new earning",_level.last_snapshot_error): return false
	_game.call("resume_lab")
	return _expect(not paused,"public resume retains the same actual "+label+" unit")


func _presentation_o3() -> bool:
	_barrier.presentation_waiting = true
	_barrier.presentation_expiration = Engine.get_process_frames()+120
	var boundary: String = await _barrier.presentation_observed
	if _finishing: return false
	return _expect(boundary == "post_presentation_process" and not paused and _hero.hp == _starting_hp and not _hero.dead, "actual post-Main Camera/HUD process precedes native capture pause",boundary)


func _tick() -> bool:
	if _finishing: return false
	if not is_instance_valid(_barrier) or paused: return _expect(false,"live unpaused actual post-actor observer required")
	_barrier.waiting = true
	_barrier.expiration = Engine.get_process_frames()+120
	var boundary: String = await _barrier.observed
	_ticks += 1
	if _finishing: return false
	var state: Dictionary = _level.call("state")
	var error: String = String(_level.call("runtime_error"))
	if not _expect(boundary == "post_actor_physics" and not paused and _ticks <= 1800 and _scheduler.get_clock() <= 30.0 and error.is_empty() and not _hero.dead and _hero.hp == _starting_hp and _hero.shells == _starting_shells and _exact(_hero.equipment.snapshot(),_kit) and _exact(_hero.equipment.resolved_stats(),_stats) and _echo.global_transform == _real_transform and String(_echo.call("source_native_error")).is_empty() and not _fired.has("blast") and _events.get("pulse_contact",0) == 0 and _checkpoints.is_empty() and _completions.is_empty() and _exits.is_empty(), "bounded native tick retains actual fixed endpoint/HP/kit/ammo and ordinary-only no-contact/no-progress scope",str({"boundary":boundary,"clock":_scheduler.get_clock(),"error":error,"state":state})): return false
	var phase: String = String(_echo.call("source_phase"))
	_phases[phase] = true
	if phase == "cancelled": return _expect(false,"genuine managed Echo must not cancel during its accepted response",str(state))
	var renderer: Node3D = _echo.call("get_enemy_apparition") as Node3D
	if phase == "active" and renderer != null:
		if _render_travel == 0.0 and not _phases.has("active-origin"):
			_render_origin = renderer.global_position
			_phases["active-origin"] = true
		_render_travel = maxf(_render_travel,renderer.global_position.distance_to(_render_origin))
	var pulse: Dictionary = _pulse.state()
	_pulse_phases[String(pulse.phase)] = true
	if pulse.status == "cancelled": return _expect(false,"independent native pulse must not cancel during the actual accepted exchange",str(pulse))
	if pulse.status == "running":
		var lease: Dictionary = _scheduler.reservation_state(String(pulse.reservation_id))
		if _pulse_lease.is_empty():
			_pulse_lease = lease.duplicate(true)
			if not _expect(not lease.is_empty() and pulse.cycle == 1 and float(lease.start_s) >= 0.65 and lease.source_instance_id == _pulse.get_instance_id() and lease.source_position == Vector3(0.7,0,6.65) and lease.opening_position == _echo.global_position and lease.geometry.kind == "circle" and lease.geometry.origin == Vector3(0.7,0,6.65) and lease.geometry.radius == 1.15 and state.pulse_record.proof.get("accepted",false) and state.pulse_record.proof.get("uses_blast") == false and state.pulse_record.proof.get("uses_invulnerability") == false, "independently due native pulse admits through its actual preview/proof and immutable rule",str(state)): return false
		for key: String in DEADLINES:
			if not _expect(not lease.is_empty() and _exact(lease[key],_pulse_lease[key]),"held pulse keeps original native "+key): return false
	if _holding_echo:
		var lease: Dictionary = _scheduler.replay_reservation_state(String(_echo_lease.id))
		for key: String in DEADLINES:
			if not _expect(not lease.is_empty() and _exact(lease[key],_echo_lease[key]),"armed own replay keeps original native "+key): return false
	return true


func _observation_o3(quiet_derived: bool = false) -> Dictionary:
	var camera: Camera3D = _game.get("camera") as Camera3D
	var body: CollisionShape3D = _hero.get_node("BodyCollision") as CollisionShape3D
	var renderer: Node3D = _echo.call("get_enemy_apparition") as Node3D
	var state: Dictionary = _level.call("state")
	if quiet_derived:
		for key: String in ["proof","projection","lease"]: state.echo_record.erase(key)
		state.pulse_record.erase("proof")
	return {"level":state,"hero_transform":_hero.global_transform,"hero_velocity":_hero.velocity,"hero_clock":_hero.get_world_action_clock(),"hero_body":body.disabled,"hp":_hero.hp,"ammo":_hero.shells,"kit":_hero.equipment.snapshot(),"actions":_hero.get_world_action_records(),"source":_echo.call("get_source_state"),"playback":_echo.call("state"),"source_transform":_echo.global_transform,"renderer_transform":renderer.global_transform if renderer != null else Transform3D.IDENTITY,"pulse":_pulse.state(),"cue":_pulse.get_cue().state(),"clock":_scheduler.get_clock(),"leases":_scheduler.reservations(),"camera_id":camera.get_instance_id(),"camera_transform":camera.global_transform,"camera_size":camera.size,"input":_game.call("get_input_observation_state"),"events":_events.duplicate(),"fired":_fired.duplicate(),"progress":[_checkpoints.duplicate(),_completions.duplicate(),_exits.duplicate()]}


func _event(kind: String) -> void:
	_events[kind] = int(_events.get(kind,0))+1


func _tick_seconds() -> float:
	return 1.0/float(Engine.physics_ticks_per_second)


func _finish() -> void:
	if _finishing: return
	_finishing = true
	_holding_echo = false
	await _dispose()
	_done = true
	print("Irontick reflection focused: ",_checks," checks; failures: ",_failures,"; native post-actor ticks: ",_ticks,". One managed prototype cycle/independent pulse/ordinary recovery/same-pair exact pause transport only; no fresh Optional transport, route, defeat-all, gear matrix or portrait acceptance.")
	quit(0 if _failures == 0 else 1)
