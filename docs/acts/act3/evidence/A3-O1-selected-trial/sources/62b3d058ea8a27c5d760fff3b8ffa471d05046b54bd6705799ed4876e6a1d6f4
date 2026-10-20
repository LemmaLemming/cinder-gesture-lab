extends SceneTree
## DRAFT ONLY. Do not execute before the owning agent freezes source + controls.
## One fixed paired actual Main/Hero/Camera/HUD trial, no whole attempt authority.
## The baseline changes pure fresh selection only, before once-only configure.
const MainScene = preload("res://scenes/main.tscn")
const O1 = preload("res://scripts/acts/act3/pillars_before_time.gd")
const Construction = preload("res://scripts/acts/act3/pillars_construction.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const BodySweep = preload("res://scripts/combat/body_sweep.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const ROOM: String = "res://scenes/acts/act3/a3_o1_pillars_before_time.tscn"
const CENTRAL: String = "o1-central-stalker"
const SW: String = "o1-southwest-marker"
const TOL: float = 0.005
const EPS: float = 0.00001
const CASE_SECONDS: float = 30.0
const CASE_TICKS: int = 1808
const OUTER_B: Vector3 = Vector3(-5.364169897140411, 0.1, 7.561595210825823)
const Q: Vector3 = Vector3(-4.15, 0.1, 5.15)
const T: Vector3 = Vector3(-1.45, 0.1, 5.15)
const NEUTRAL: Dictionary = {"jacket":"CLOTH-J0", "pants":"CLOTH-P0", "shoes":"CLOTH-S0", "weapon":"WEAPON-01"}

class ChallengeMain extends "res://scripts/game.gd":
	func get_difficulty_preference() -> String: return "challenge"

class CanonicalO1 extends "res://scripts/acts/act3/pillars_before_time.gd":
	func _fresh_construction(profile: String) -> Dictionary:
		# Exact closed seven-key constructor header. This is metadata, never a
		# fabricated native source/Scheduler/whole saved packet or restore call.
		var canonical: Dictionary = {
			"api_revision":"act3-pillars-before-time-3", "schema_version":2,
			"construction":{
				"api_revision":"act3-pillars-construction-1", "schema_version":1,
				"profile":Difficulty.new().profile(profile),
				"recipe_id":"A3-O1/canonical-homes@v1"},
			"scenery":{}, "scheduler":{"profile":Difficulty.new().profile(profile)},
			"sources":{}, "route":{}}
		return Construction.saved(canonical)

class AfterActors extends Node:
	signal observed(boundary: String)
	var waiting: bool = false
	var expires_at_process: int = 0
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 1000
		process_priority = 1000
	func _physics_process(_delta: float) -> void:
		if waiting and not get_tree().paused: wake("post_actor_physics")
	func _process(_delta: float) -> void:
		if waiting and Engine.get_process_frames() >= expires_at_process: wake("expired_process_bound")
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PAUSED and waiting: wake.bind("unexpected_pause").call_deferred()
	func wake(boundary: String) -> void:
		if waiting:
			waiting = false
			observed.emit(boundary)

var _main: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _scheduler: CinderThreatScheduler
var _sources: Dictionary = {}
var _homes: Dictionary = {}
var _observer: AfterActors
var _packed: PackedScene
var _packed_path: String = ""
var _kit: Dictionary = {}
var _stats: Dictionary = {}
var _hp: float = 0.0
var _ticks: int = 0
var _checks: int = 0
var _failures: int = 0
var _stop: bool = false
var _finished: bool = false
var _first_error: String = ""
var _label: String = ""
var _actions: Array[Dictionary] = []
var _controls: Array[Dictionary] = []
var _contacts: Array[Dictionary] = []
var _phase_events: Array[Dictionary] = []
var _trace: Array[Dictionary] = []
var _cases: Array[Dictionary] = []
var _connections: Array[Array] = []
var _records: Dictionary = {}
var _phases: Dictionary = {}
var _travel: Dictionary = {}
var _last_clock: float = 0.0
var _last_position: Vector3 = Vector3.ZERO
var _prior_union: Array[Dictionary] = []
var _expected_hp: Dictionary = {}
var _warnings: Dictionary = {}
var _used_warnings: Dictionary = {}
var _hit: Dictionary = {}
var _output_dir: String = ""

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	create_timer(600.0, true, false, true).timeout.connect(_watchdog)
	if not OS.get_cmdline_user_args().is_empty():
		_fail("Fixed paired fixture accepts no selectors")
		await _finish("refused")
		return
	root.size = Vector2i(340, 736)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	for changed: bool in [false, true]:
		var actual: Dictionary = await _case(changed)
		# Every failure/partial action/native tick is sealed BEFORE disposal.
		_cases.append(actual.duplicate(true))
		var archive_error: String = _archive("case-" + _label, actual)
		if not archive_error.is_empty(): _fail(archive_error)
		var cleanup: String = await _dispose()
		_cases[-1]["cleanup_error"] = cleanup
		if not cleanup.is_empty(): _fail(cleanup)
		if _stop or not String(actual.get("error", "Missing actual result")).is_empty():
			await _finish("unsafe_or_inconclusive")
			return
	var comparison: Dictionary = _compare(_cases[0], _cases[1])
	if not String(comparison.error).is_empty(): _fail(comparison.error)
	await _finish(String(comparison.outcome), comparison)

func _case(changed: bool) -> Dictionary:
	_label = "selected-v2-challenge" if changed else "canonical-v1-challenge"
	_ticks = 0
	_actions.clear(); _controls.clear(); _contacts.clear(); _phase_events.clear(); _trace.clear()
	_connections.clear(); _records.clear(); _phases.clear(); _travel.clear()
	_expected_hp.clear(); _warnings.clear(); _used_warnings.clear(); _hit.clear()
	_first_error = ""
	var open_error: String = await _open(changed)
	if not open_error.is_empty(): return _result(open_error)
	var points: Array[Vector3] = [Vector3(-2.7, 0.1, 8), OUTER_B, Q]
	for target: Vector3 in points:
		var error: String = await _ordinary_dash_to(target)
		if not error.is_empty(): return _result(error)
	var q_observation: Dictionary = _observation("fixed-Q-contact-discriminator")
	if _planar(_hero.global_position - Q).length() > TOL or not _level.call("state").collected.has(SW):
		return _result("Fixed native prefix failed to earn actual southwest contact at Q", {"q":q_observation})
	# This shared fourth RIGHT dash is predeclared to offer native SW response
	# in the otherwise quiet canonical arm; no follow-up prefix or search.
	var continuation: String = await _ordinary_dash_to(T)
	if not continuation.is_empty(): return _result(continuation, {"q":q_observation})
	var first: Dictionary = await _wait_native_warning()
	if first.is_empty(): return _result(_first_error if not _first_error.is_empty() else "No actual usable native warning before fixed bound", {"q":q_observation})
	var response: String = await _follow_native_response(first)
	if not response.is_empty(): return _result(response, {"q":q_observation})
	return _result("", {"q":q_observation, "first_response":first, "useful_primary":_hit.duplicate(true)})

func _open(changed: bool) -> String:
	paused = false
	_main = MainScene.instantiate()
	_main.set_script(ChallengeMain)
	root.add_child(_main)
	_main.call("open_bench")
	var lab_hero: CinderPlayer = _main.get("player") as CinderPlayer
	if not paused or lab_hero == null or not get_nodes_in_group("enemies").is_empty(): return "Actual enemy-free paused Main unavailable"
	if lab_hero.equipment.snapshot() != NEUTRAL: return "Actual Main neutral starter equipment differs"
	var path: String = ROOM
	if not changed:
		var packed: Dictionary = _canonical_scene()
		if not String(packed.error).is_empty(): return packed.error
		_packed = packed.scene
		_packed_path = packed.path
		path = _packed_path
	if not _main.call("load_level_scene", path): return "Public Main O1 load declined: " + String(_main.get("level_load_error"))
	_main.call("open_bench")
	_level = _main.get("active_level") as CinderLevel
	_hero = _main.get("player") as CinderPlayer
	if _level == null or _hero == null or _hero == lab_hero: return "Fresh actual O1/Hero unavailable"
	var camera: Camera3D = _main.get("camera") as Camera3D
	var hud: GameHUD = _main.get("hud") as GameHUD
	if camera == null or hud == null or camera != _hero.get_viewport().get_camera_3d() or camera.get_world_3d() != _hero.get_world_3d(): return "Actual native Main Camera/HUD/Hero world unavailable"
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	_sources = (_level.get("sources") as Dictionary).duplicate()
	_homes = _level.call("selected_source_positions")
	_kit = _hero.equipment.snapshot()
	_stats = _hero.equipment.resolved_stats()
	_hp = _hero.hp
	if _scheduler == null or not _level.contract_error().is_empty() or _level.level_id != "A3-O1" or _level.local_snapshot_version != 2: return "Actual O1 outer/native constructor contract differs"
	if _kit != NEUTRAL or _hero.global_position != Vector3(0, 0.1, 8) or _hero.hp != _hero.max_hp or _hero.dead or _scheduler.get_clock() != 0.0 or _hero.get_world_action_clock() != 0.0 or not _hero.get_world_action_records().is_empty(): return "Genuine fresh native spawn/resources/clock differ"
	if _scheduler.encounter_profile() != Difficulty.new().profile("challenge") or not is_equal_approx(float(_stats.dash_distance), 2.7): return "Exact canonical Challenge profile/ordinary neutral dash required"
	var expected: Dictionary = O1.SOURCE_POSITIONS.duplicate()
	if changed: expected[CENTRAL] = Vector3(-3, 0.1, 1)
	if _homes != expected or not Codec.keys_error(_sources, O1.SOURCE_IDS).is_empty(): return "Selected finite home map/source IDs differ"
	var bindings: Dictionary = _level.call("scheduler_bindings")
	if bindings.world_root != _level or bindings.owners != _sources or bindings.floors.size() != 1 or bindings.floors["shelf-floor"].safe_rect != O1.FLOOR_RECT: return "Actual permanent floor/source owner bindings differ"
	for id: String in O1.SOURCE_IDS:
		var source: CinderAct3SunboundStalker = _sources[id]
		if source.global_position != expected[id] or source.hp != 36.0 or source.dead or not source.is_in_group("enemies") or source.is_physics_processing() or source.get_world_3d() != _hero.get_world_3d(): return "Fresh once-configured dormant living source differs: " + id
		_expected_hp[id] = source.hp
		_connect(source, "state_changed", _on_phase.bind(id))
		_connect(source, "hit_resolved", _on_contact.bind(id))
	_connect(_hero, "world_action_executed", _on_action)
	_connect(_hero, "fired", _on_fired)
	_observer = AfterActors.new()
	root.add_child(_observer)
	_last_clock = _scheduler.get_clock()
	_last_position = _hero.global_position
	_prior_union = _scheduler.reservations()
	_trace.append(_observation("paused-genuine-fresh-entry"))
	_main.call("resume_lab")
	for _index: int in range(8):
		if _hero.is_on_floor(): break
		var error: String = await _tick()
		if not error.is_empty(): return error
	return "" if _hero.is_on_floor() else "Genuine Hero did not ground within eight native ticks"

func _canonical_scene() -> Dictionary:
	var template: Node = load(ROOM).instantiate()
	var declared := CanonicalO1.new()
	declared.name = "TEST_A3_O1_CanonicalConstructor"
	# These are the canonical scene's only authored root values. Every actual
	# child, including its unchanged spawn/home Markers, is duplicated below.
	declared.level_id = template.get("level_id")
	declared.objective_text = template.get("objective_text")
	for child: Node in template.get_children():
		var copy: Node = child.duplicate()
		declared.add_child(copy)
		_assign_owner(copy, declared)
	template.free()
	var scene := PackedScene.new()
	var error: Error = scene.pack(declared)
	declared.free()
	if error != OK: return {"error":"TEST canonical constructor scene packing failed"}
	var path: String = "res://tests/acts/act3/__TEST_o1_canonical_%d_%d.tscn" % [OS.get_process_id(), Time.get_ticks_usec()]
	if FileAccess.file_exists(path) or ResourceLoader.has_cached(path): return {"error":"New TEST in-memory scene cache path required"}
	scene.take_over_path(path)
	return {"error":"", "scene":scene, "path":path}

func _assign_owner(node: Node, owner: Node) -> void:
	node.owner = owner
	for child: Node in node.get_children(): _assign_owner(child, owner)

func _ordinary_dash_to(target: Vector3) -> String:
	for _index: int in range(90):
		var ready: Dictionary = _hero.get_threat_response_state()
		if ready.stable and float(ready.dash_cooldown_left_s) == 0.0: break
		var error: String = await _tick()
		if not error.is_empty(): return error
	var motion: Vector3 = target - _hero.global_position
	motion.y = 0.0
	if absf(motion.length() - float(_stats.dash_distance)) > TOL: return "Predeclared prefix no longer matches one full ordinary dash"
	var now: float = _scheduler.get_clock()
	return await _dash({"from":_hero.global_position, "to":_hero.global_position + motion, "start_s":now, "end_s":now + float(_stats.dash_duration), "kind":"fixed_prefix_dash"})

func _dash(segment: Dictionary) -> String:
	var response: Dictionary = _hero.get_threat_response_state()
	if not response.stable or float(response.dash_cooldown_left_s) != 0.0 or _hero.global_position.distance_to(segment.from) > TOL: return "Real public dash is not ready at its declared origin"
	var motion: Vector3 = segment.to - segment.from
	motion.y = 0.0
	if absf(motion.length() - float(_stats.dash_distance)) > TOL: return "Only one full ordinary native dash is supported"
	var floors: Array = (_level.call("scheduler_bindings") as Dictionary).floors.values()
	var sweep: Dictionary = BodySweep.sweep(_hero, _hero.global_transform, motion, floors)
	if sweep.has("error") or sweep.get("collided", true) or (sweep.end as Vector3).distance_to(segment.to) > TOL: return "Actual Hero full dash lacks complete native body/floor clearance: " + str(sweep)
	var path: Array[Dictionary] = [segment]
	var union_error: String = _future_union_error(path)
	if not union_error.is_empty(): return union_error
	var sequence: int = _last_sequence()
	var accepted: bool = _hero.request_dash(motion.normalized())
	_controls.append({"kind":"public_hero_request_dash", "direction":motion.normalized(), "clock_s":_scheduler.get_clock(), "world_origin":segment.from, "expected_landing":segment.to, "accepted":accepted})
	if not accepted: return "Ordinary public controller refused fixed native dash"
	for _index: int in range(40):
		var error: String = await _tick()
		if not error.is_empty(): return error
		var actions: Array[Dictionary] = _hero.get_world_action_records(sequence)
		if actions.is_empty(): continue
		if actions.size() != 1: return "One native dash emitted unexpected world action count"
		var action: Dictionary = actions[0]
		if action.kind != "dash" or action.blocked or action.collision_shortened or action.equipment_ids != _kit or action.resolved_stats != _stats: return "Actual native dash was shortened/blocked or changed kit/stats"
		if (action.world_origin as Vector3).distance_to(segment.from) > TOL or (action.landing as Vector3).distance_to(segment.to) > TOL or _hero.global_position.distance_to(segment.to) > TOL or absf(float(action.distance) - float(_stats.dash_distance)) > TOL: return "Actual ordinary full-dash origin/distance/landing differs"
		return ""
	return "Actual dash completion exceeded forty native ticks"

func _wait_native_warning() -> Dictionary:
	for _index: int in range(CASE_TICKS):
		var pending: Dictionary = _pending()
		if not pending.is_empty():
			var error: String = _proof_error(pending)
			if not error.is_empty():
				_fail(error)
				return {}
			_used_warnings[pending.record.id] = true
			return pending
		var error: String = await _tick()
		if not error.is_empty():
			_fail(error)
			return {}
	_fail("No native warning inside fixed thirty-second case")
	return {}

func _pending() -> Dictionary:
	var chosen: Dictionary = {}
	for reservation_id: String in _warnings:
		if _used_warnings.has(reservation_id): continue
		var row: Dictionary = _warnings[reservation_id]
		var source: CinderAct3SunboundStalker = _sources[row.id]
		var state: Dictionary = source.state()
		var record: Dictionary = _scheduler.reservation_state(reservation_id)
		if state.dead or state.reservation_id != reservation_id or record.is_empty() or record.state != "warning": continue
		if chosen.is_empty() or float(record.start_s) > float(chosen.record.start_s) or (float(record.start_s) == float(chosen.record.start_s) and String(row.id) > String(chosen.id)):
			chosen = {"id":row.id, "record":record, "proof":row.proof.duplicate(true), "state":state}
	return chosen

func _proof_error(warning: Dictionary) -> String:
	var source: CinderAct3SunboundStalker = _sources[warning.id]
	var record: Dictionary = warning.record
	var proof: Dictionary = warning.proof
	if record.get("source_instance_id") != source.get_instance_id() or record.get("armed") != true or record.get("adapter", {}).get("kind") != "lunge": return "Actual ordinary native lease lacks its real owner/lunge binding"
	# Ordinary leases do not universally carry replay-only actor identity keys.
	var response: Dictionary = _level.call("combat_response", warning.id)
	if response.get("actor") != _hero or response.get("equipment_ids") != _kit or response.get("stats") != _stats or proof.get("accepted") != true or proof.get("uses_blast") != false or proof.get("uses_invulnerability") != false or not proof.get("path") is Array or proof.path.is_empty(): return "Actual native witness lacks current Hero/ordinary no-immunity response"
	var path: Array[Dictionary] = []
	var previous: Dictionary = {}
	var escapes: int = 0
	var primaries: int = 0
	for value: Variant in proof.path:
		if not value is Dictionary: return "Actual native path contains non-dictionary segment"
		var segment: Dictionary = value
		if not Geometry.finite_vector(segment.get("from")) or not Geometry.finite_vector(segment.get("to")) or not Geometry.finite_number(segment.get("start_s")) or not Geometry.finite_number(segment.get("end_s")) or float(segment.end_s) < float(segment.start_s): return "Actual native path has malformed finite endpoints/timing"
		if segment.kind not in ["recognition_and_ready", "escape_dash", "recovery_wait", "positioning_dash", "primary_ready", "ordinary_primary"]: return "Native proof advertises unsupported response kind"
		if not previous.is_empty() and (absf(float(previous.end_s) - float(segment.start_s)) > EPS or (previous.to as Vector3).distance_to(segment.from) > TOL): return "Actual native path is discontinuous"
		if not _floor_point(segment.from) or not _floor_point(segment.to): return "Native proof path loses permanent supported floor"
		escapes += 1 if segment.kind == "escape_dash" else 0
		primaries += 1 if segment.kind == "ordinary_primary" else 0
		path.append(segment)
		previous = segment
	if escapes != 1 or primaries != 1 or (path[0].from as Vector3).distance_to(_hero.global_position) > TOL or float(proof.primary_time_s) <= float(record.active_until_s) or float(proof.response_complete_s) > float(record.recovery_until_s): return "Native witness lacks current origin and useful full ordinary recovery opening"
	return _future_union_error(path)

func _follow_native_response(warning: Dictionary) -> String:
	# The policy is finite: use the real newest warning at stopped boundaries;
	# a newly admitted native warning may supersede before commitment, never
	# mutate an old lease/path. A refused/unsafe path ends this declared trial.
	var current: Dictionary = warning
	for _episode: int in range(8):
		var error: String = _proof_error(current)
		if not error.is_empty(): return error
		var superseded: bool = false
		for segment: Dictionary in current.proof.path:
			if segment.kind in ["escape_dash", "positioning_dash"]:
				error = await _wait_until(float(segment.start_s), segment.from)
				if error.is_empty(): error = await _dash(segment)
			elif segment.kind == "ordinary_primary":
				error = await _primary(current, segment)
				if error.is_empty(): return ""
			else:
				error = await _wait_until(float(segment.end_s), segment.from)
			if error == "new_actual_native_warning":
				current = _pending()
				if current.is_empty(): return "New warning disappeared at ordinary response boundary"
				_used_warnings[current.record.id] = true
				superseded = true
				break
			if not error.is_empty(): return error
		if not superseded: return "Native proof completed without its advertised ordinary primary"
	return "Eight actual native warning decisions exhausted; no route search"

func _wait_until(target: float, position: Vector3, allow_new_warning: bool = true) -> String:
	if not is_finite(target) or target > CASE_SECONDS: return "Native response hold target exceeds declared case bound"
	for _index: int in range(CASE_TICKS):
		if _hero.global_position.distance_to(position) > TOL: return "Actual passive native hold drifted from advertised stopped position"
		if allow_new_warning and not _pending().is_empty(): return "new_actual_native_warning"
		if _scheduler.get_clock() >= target:
			return "" if _scheduler.get_clock() - target <= _tick_s() + EPS else "Actual native action missed first fixed-tick deadline"
		var error: String = await _tick()
		if not error.is_empty(): return error
	return "Actual native passive hold exceeds tick bound"

func _primary(warning: Dictionary, segment: Dictionary) -> String:
	var error: String = await _wait_until(float(warning.proof.primary_time_s), segment.from)
	if not error.is_empty(): return error
	var source: CinderAct3SunboundStalker = _sources[warning.id]
	var state: Dictionary = source.state()
	var record: Dictionary = _scheduler.reservation_state(warning.record.id)
	if record.is_empty() or record.state != "recovery" or state.phase != "recovery" or state.dead or not source.velocity.is_zero_approx() or source.global_position.distance_to(warning.record.adapter.planned_endpoint) > TOL or _hero.global_position.distance_to(warning.proof.attack_position) > TOL: return "Primary lacks actual stopped source recovery and advertised ordinary range"
	for phase: String in ["warning", "lock", "active", "recovery"]:
		if not (_phases.get(record.id, {}) as Dictionary).has(phase): return "Native source never presented full actual phase: " + phase
	if float(_travel.get(record.id, 0.0)) <= 0.1: return "Native active source never made genuine lunge travel"
	var response: Dictionary = _hero.get_threat_response_state()
	if not response.stable or float(response.primary_cooldown_left_s) != 0.0: return "Ordinary primary is not currently ready"
	var before: Dictionary = _expected_hp.duplicate(true)
	var sequence: int = _last_sequence()
	var toward: Vector3 = source.global_position - _hero.global_position
	toward.y = 0.0
	if toward.is_zero_approx(): return "Ordinary primary needs nonzero actual target bearing"
	var hits: int = _hero.slash(toward.normalized())
	_controls.append({"kind":"public_hero_slash", "direction":toward.normalized(), "clock_s":_scheduler.get_clock(), "world_origin":_hero.global_position, "actual_target_id":warning.id, "actual_hits_returned":hits})
	var changed: int = 0
	for id: String in O1.SOURCE_IDS:
		var actual: float = float((_sources[id] as CinderAct3SunboundStalker).hp)
		if actual != float(before[id]):
			if actual != maxf(float(before[id]) - float(_stats.primary_damage), 0.0): return "Actual ordinary primary produced unexpected source damage"
			changed += 1
		_expected_hp[id] = actual
	var actions: Array[Dictionary] = _hero.get_world_action_records(sequence)
	if hits < 1 or changed != hits or float(_expected_hp[warning.id]) >= float(before[warning.id]) or actions.size() != 1 or actions[0].kind != "primary" or actions[0].hits != hits or actions[0].equipment_ids != _kit: return "Useful public ordinary primary did not publish matching native source hit(s)"
	_hit = {"source_id":warning.id, "record":warning.record.duplicate(true), "proof":warning.proof.duplicate(true), "action":actions[0].duplicate(true), "hp_before":before, "hp_after":_expected_hp.duplicate(true), "clock_s":_scheduler.get_clock()}
	# Keep full stationary primary cooldown/commitment even though the genuine
	# hit may cancel the target lease with primary_stagger. Other owners remain
	# live and autonomous and every actual passive interval is checked below.
	var hold: float = maxf(float(warning.record.recovery_until_s), maxf(float(segment.end_s), _scheduler.get_clock() + maxf(float(_stats.primary_cooldown), float(response.primary_commitment_s))))
	return await _wait_until(hold, _hero.global_position, false)

func _future_union_error(path: Array[Dictionary]) -> String:
	for held: Dictionary in _scheduler.reservations():
		if not _owner_for_record(held).is_empty() and Geometry.timed_path_hits(held.geometry, path, float(held.active_from_s), float(held.active_until_s), CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN): return "Declared complete response intersects a current/pending native threat union member"
		if _owner_for_record(held).is_empty(): return "Actual ordinary lease lacks one of three genuine source owners"
	return ""

func _tick() -> String:
	if _stop: return _first_error if not _first_error.is_empty() else "Fixture stopped"
	if paused or _observer == null or not is_instance_valid(_hero): return "No live unpaused post-actor observer/actual Hero"
	_observer.waiting = true
	_observer.expires_at_process = Engine.get_process_frames() + 240
	var boundary: String = await _observer.observed
	if _stop: return _first_error
	_ticks += 1
	if boundary != "post_actor_physics" or paused or _ticks > CASE_TICKS: return "Post-actor native tick boundary/bound failed"
	var current: Dictionary = _observation("post-actor-native-tick")
	_trace.append(current)
	var error: String = _live_error(current)
	if not error.is_empty():
		_fail(error)
		return error
	_checks += 1
	_last_clock = _scheduler.get_clock()
	_last_position = _hero.global_position
	_prior_union = _scheduler.reservations()
	return ""

func _live_error(observation: Dictionary) -> String:
	if _hero.dead or _hero.hp != _hp or _hero.equipment.snapshot() != _kit or _scheduler.get_clock() > CASE_SECONDS or absf(_hero.get_world_action_clock() - _scheduler.get_clock()) > EPS: return "Actual native Hero HP/kit/clock/budget changed"
	if not _contacts.is_empty(): return "A native C50 opportunity was consumed/damage attempted even if invulnerability rejected HP"
	if not _level.contract_error().is_empty() or not String(observation.level.configuration_error).is_empty(): return "Actual O1 native constructor/runtime contract failed"
	if not _floor_point(_hero.global_position): return "Actual Hero lost supported permanent floor"
	var actual_segment: Array[Dictionary] = [{"from":_last_position, "to":_hero.global_position, "start_s":_last_clock, "end_s":_scheduler.get_clock(), "kind":"actual_tick_motion_or_passive_hold"}]
	var union: Array[Dictionary] = _prior_union.duplicate(true)
	for record: Dictionary in _scheduler.reservations(): union.append(record)
	for record: Dictionary in union:
		if Geometry.timed_path_hits(record.geometry, actual_segment, float(record.active_from_s), float(record.active_until_s), CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN): return "Actual full movement/passive interval intersects native current/previous active union geometry"
	for id: String in O1.SOURCE_IDS:
		var source: CinderAct3SunboundStalker = _sources[id]
		var state: Dictionary = source.state()
		if source.hp != float(_expected_hp[id]) or source.dead or state.hit_consumed: return "Actual autonomous source resources/lifecycle/contact changed: " + id
		if not String(state.reservation_id).is_empty() and not String(state.framing_error).is_empty(): return "Admitted native source failed current required view: " + id
		if String(state.last_cancel_reason).begins_with("required_view_unsafe") or state.last_cancel_reason == "required_presentation_failed": return "Actual native source canceled for unsafe presentation: " + id
		var awake: bool = (observation.level.awakenings as Dictionary).has(id)
		if source.is_physics_processing() != awake: return "Actual autonomous source awakening eligibility differs: " + id
		if not awake and (source.global_position != _homes[id] or int(state.cycle) != 0 or state.reservation_id != "" or state.phase != "idle"): return "Unawakened native source moved/leased/acted: " + id
	for record: Dictionary in _scheduler.reservations():
		var id: String = _owner_for_record(record)
		if id.is_empty(): return "Actual held native lease has foreign/missing owner"
		if not _records.has(record.id):
			_records[record.id] = record.duplicate(true)
			_phases[record.id] = {}
			_travel[record.id] = 0.0
		if _fixed_record(record) != _fixed_record(_records[record.id]): return "Actual held native lane/deadline/identity changed"
		var source: CinderAct3SunboundStalker = _sources[id]
		var state: Dictionary = source.state()
		var cue: Dictionary = source.get_cue().state()
		if state.reservation_id != record.id or state.phase != record.state or cue.phase != record.state or cue.geometry != record.geometry or cue.source_position != source.global_position or not cue.source_visible: return "Actual source/lease/cue phase binding differs"
		_phases[record.id][record.state] = true
		if record.state == "active": _travel[record.id] = maxf(float(_travel[record.id]), source.global_position.distance_to(record.adapter.start))
		if record.state == "recovery" and (source.global_position.distance_to(record.adapter.planned_endpoint) > TOL or not source.velocity.is_zero_approx()): return "Actual native lunge failed stopped recovery endpoint"
	return ""

func _observation(reason: String) -> Dictionary:
	var actors: Dictionary = {}
	for id: String in _sources:
		var source: CinderAct3SunboundStalker = _sources[id]
		actors[id] = {"instance_id":source.get_instance_id(), "physics":source.is_physics_processing(), "state":source.state(), "control":_scheduler.source_control_state(source)}
	var response: Dictionary = _hero.get_threat_response_state()
	response.erase("actor") # Native object identity is separately captured as int.
	return {"reason":reason, "native_tick":_ticks, "clock_s":_scheduler.get_clock(), "hero_instance_id":_hero.get_instance_id(), "hero_position":_hero.global_position, "hero_hp":_hero.hp, "hero_response":response, "hero_committed_dash":_hero.get_committed_dash_state(), "level":_level.call("state"), "construction":_level.call("selected_construction"), "homes":_homes.duplicate(), "sources":actors, "union":_scheduler.reservations(), "action_sequence":_last_sequence(), "contacts_observed":_contacts.size()}

func _result(error: String, additions: Dictionary = {}) -> Dictionary:
	if not error.is_empty(): _fail(error)
	var result: Dictionary = {"error":error, "label":_label, "native_ticks":_ticks, "kit":_kit.duplicate(true), "stats":_stats.duplicate(true), "initial_hp":_hp, "controls":_controls.duplicate(true), "control_provenance":"Actual public Hero.request_dash and Hero.slash calls; no swipe/tap recognizer or input-observation credit", "actions":_actions.duplicate(true), "contacts":_contacts.duplicate(true), "phase_events":_phase_events.duplicate(true), "trace":_trace.duplicate(true), "actual_useful_primary":_hit.duplicate(true), "whole_attempt_or_route_credit":false}
	if is_instance_valid(_hero) and is_instance_valid(_scheduler) and is_instance_valid(_level): result["actual_terminal_observation"] = _observation("stopped_before_disposal")
	result["c50_damage_attempts"] = _contacts.size()
	result["c50_opportunities_consumed"] = _contacts.size()
	result.merge(additions, false)
	return result

func _compare(original: Dictionary, changed: Dictionary) -> Dictionary:
	if original.kit != changed.kit or original.stats != changed.stats or original.initial_hp != changed.initial_hp: return {"error":"Paired native initial kit/stats/HP differ", "outcome":"inconclusive"}
	if original.trace.is_empty() or changed.trace.is_empty() or original.trace[0].clock_s != 0.0 or changed.trace[0].clock_s != 0.0 or original.trace[0].hero_position != changed.trace[0].hero_position: return {"error":"Paired native actual start clocks/origins do not join", "outcome":"inconclusive"}
	if not original.has("q") or not changed.has("q") or original.q.hero_position.distance_to(changed.q.hero_position) > TOL or absf(float(original.q.clock_s) - float(changed.q.clock_s)) > EPS: return {"error":"Actual fixed Q clocks/origins do not join; no causal cross-case path claim", "outcome":"inconclusive"}
	if original.q.level.collected != changed.q.level.collected or not original.q.level.collected.has(SW): return {"error":"Paired actual Q contacts do not join", "outcome":"inconclusive"}
	var physical: bool = false
	var original_response: Array[Dictionary] = []
	var changed_response: Array[Dictionary] = []
	for action: Dictionary in original.actions:
		if int(action.sequence) > 4: original_response.append(action)
	for action: Dictionary in changed.actions:
		if int(action.sequence) > 4: changed_response.append(action)
	if original_response.size() != changed_response.size(): physical = true
	else:
		for index: int in range(original_response.size()):
			var a: Dictionary = original_response[index]
			var b: Dictionary = changed_response[index]
			if a.kind != b.kind or (a.world_origin as Vector3).distance_to(b.world_origin) > TOL or (a.kind == "dash" and (a.landing as Vector3).distance_to(b.landing) > TOL): physical = true
	# A wake or target label alone is never a successful decision result. Both
	# arms must actually execute useful ordinary primary and complete safe hold.
	if original.actual_useful_primary.is_empty() or changed.actual_useful_primary.is_empty(): return {"error":"Paired case lacks genuine useful ordinary response", "outcome":"inconclusive"}
	if not physical: return {"error":"No observed useful physical escape/return decision difference", "outcome":"equivalent"}
	return {"error":"", "outcome":"safe_native_trace_difference_requires_owner_review", "native_protocol_complete":true, "same_Q_clock_origin":true, "observed_physical_difference":true, "owner_semantic_review_required":true, "difficulty_credit":false, "whole_attempt_or_route_credit":false, "human_balance_credit":false, "scope":"Fixed three-dash southwest prefix and predeclared right continuation; full actual native warning/lock/active/recovery, useful primary and full ordinary/source-recovery hold under both autonomous three-source arrangements. Absolute positions/angles/action count alone do not establish a new player decision. Owner must review full traces for causal and semantic meaning before difficulty qualification or dependent portrait/save work."}

func _fixed_record(record: Dictionary) -> Dictionary:
	var result: Dictionary = {"id":record.id, "source_instance_id":record.source_instance_id, "geometry":record.geometry, "armed":record.armed, "start":record.adapter.start, "direction":record.adapter.direction, "endpoint":record.adapter.planned_endpoint, "body_collision_path":record.adapter.body_collision_path}
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]: result[key] = record[key]
	return result

func _owner_for_record(record: Dictionary) -> String:
	for id: String in _sources:
		if record.get("source_instance_id") == (_sources[id] as Node).get_instance_id(): return id
	return ""

func _floor_point(point: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.25, point - Vector3.UP * 0.25, 1)
	var hit: Dictionary = _hero.get_world_3d().direct_space_state.intersect_ray(query)
	var floor: StaticBody3D = (_level.get("scenery") as Node).get("floor_body") as StaticBody3D
	return not hit.is_empty() and hit.get("collider") == floor

func _last_sequence() -> int:
	var records: Array[Dictionary] = _hero.get_world_action_records()
	return 0 if records.is_empty() else int(records.back().sequence)

func _tick_s() -> float: return 1.0 / float(Engine.physics_ticks_per_second)

func _planar(value: Vector3) -> Vector3: return Vector3(value.x, 0.0, value.z)

func _connect(node: Node, name: String, callback: Callable) -> void:
	node.connect(name, callback)
	_connections.append([node, name, callback])

func _on_phase(state: Dictionary, id: String) -> void:
	_phase_events.append({"source_id":id, "state":state.duplicate(true), "clock_s":_scheduler.get_clock()})
	if state.get("phase") == "warning" and state.get("proof", {}).get("accepted") == true:
		_warnings[String(state.reservation_id)] = {"id":id, "proof":state.proof.duplicate(true)}

func _on_contact(result: Dictionary, id: String) -> void:
	_contacts.append({"source_id":id, "result":result.duplicate(true), "clock_s":_scheduler.get_clock()})
	_fail("Native C50 opportunity consumed/damage attempted: " + id)

func _on_action(record: Dictionary) -> void: _actions.append(record.duplicate(true))

func _on_fired(kind: String) -> void:
	if kind not in ["dash", "slash"]: _fail("Unexpected fired control: " + kind)

func _fail(message: String) -> void:
	if not _first_error.is_empty(): return
	_first_error = message
	_stop = true
	_failures += 1
	push_error("Pillars fixed pair: " + message)

func _archive(label: String, value: Dictionary) -> String:
	if _output_dir.is_empty():
		_output_dir = "res://captures/act3/pillars-arrangement/fixed-pair-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
		if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_output_dir)): return "New actual result folder required"
		if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir)) != OK: return "Actual result folder unavailable"
	var path: String = _output_dir.path_join(label + ".var.bin")
	var bytes: PackedByteArray = var_to_bytes(value)
	if bytes.is_empty() or FileAccess.file_exists(path): return "Actual result must be nonempty/new"
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null: return "Actual native result stream unavailable"
	file.store_buffer(bytes)
	file.flush()
	file.close()
	if FileAccess.get_file_as_bytes(path) != bytes: return "Actual native full trace did not persist exactly"
	var text_file: FileAccess = FileAccess.open(_output_dir.path_join(label + ".var.txt"), FileAccess.WRITE)
	if text_file == null: return "Actual result text stream unavailable"
	text_file.store_string(var_to_str(value) + "\n")
	text_file.flush()
	text_file.close()
	print("Pillars fixed pair actual result: ", ProjectSettings.globalize_path(path), "; sha256=", FileAccess.get_sha256(path), "; error=", value.get("error", ""))
	return ""

func _dispose() -> String:
	if is_instance_valid(_observer): _observer.wake("normal_retirement")
	for connection: Array in _connections:
		var node: Node = connection[0]
		if is_instance_valid(node) and node.is_connected(connection[1], connection[2]): node.disconnect(connection[1], connection[2])
	_connections.clear()
	var leases_clear: bool = true
	if is_instance_valid(_level) and _level.is_inside_tree():
		_level.exit_level()
		for source: Node3D in _sources.values():
			var control: Dictionary = _scheduler.source_control_state(source)
			leases_clear = leases_clear and not control.is_empty() and control.reservations.is_empty()
	var weak_nodes: Array[WeakRef] = []
	if is_instance_valid(_main):
		weak_nodes.append(weakref(_main))
		var effects: PixelEffects = _main.get("fx") as PixelEffects
		if effects != null: effects.clear()
		_main.queue_free()
	if is_instance_valid(_observer):
		weak_nodes.append(weakref(_observer))
		_observer.queue_free()
	var scene_ref: WeakRef = weakref(_packed) if _packed != null else null
	_packed = null
	_main = null; _level = null; _hero = null; _scheduler = null
	_sources.clear(); _observer = null
	var released: bool = false
	for _frame: int in range(120):
		await process_frame
		released = true
		for reference: WeakRef in weak_nodes:
			if reference.get_ref() != null: released = false
		if released: break
	var no_cache: bool = _packed_path.is_empty() or not ResourceLoader.has_cached(_packed_path)
	var scene_gone: bool = scene_ref == null or scene_ref.get_ref() == null
	_packed_path = ""
	return "" if leases_clear and released and no_cache and scene_gone and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty() else "Actual public cleanup retained leases/owners/cues/scene cache"

func _finish(outcome: String, comparison: Dictionary = {}) -> void:
	if _finished: return
	_finished = true
	_stop = true
	var result: Dictionary = {"schema_version":1, "kind":"a3-o1-fixed-native-arrangement-pair-1", "test_only":true, "error":_first_error, "outcome":outcome, "cases":_cases.duplicate(true), "comparison":comparison, "checks":_checks, "failures":_failures, "complete":_failures == 0 and outcome == "safe_native_trace_difference_requires_owner_review", "owner_semantic_review_required":true, "difficulty_credit":false, "whole_attempt_or_route_credit":false, "control_provenance":"Actual public Hero controller requests, no swipe/tap recognizer credit", "fixed_controls":"spawn→A(-2.7,8)→outer-west B(-5.364169897140411,7.561595210825823)→Q(-4.15,5.15)→RIGHT T(-1.45,5.15), then actual native witness response; no alternate prefix or coordinate search", "native_case_seconds_bound":CASE_SECONDS, "wall_seconds_bound":600.0}
	var error: String = _archive("result", result)
	if not error.is_empty(): push_error(error)
	if is_instance_valid(_main): await _dispose()
	print("Pillars fixed pair: outcome=", outcome, "; failures=", _failures, "; complete=", result.complete)
	quit(0 if result.complete and error.is_empty() else 1)

func _watchdog() -> void:
	if _finished: return
	_fail("Six-hundred-second wall watchdog; partial actual trace preserved")
	if is_instance_valid(_hero) and is_instance_valid(_scheduler):
		_cases.append(_result(_first_error, {"watchdog":true}))
	await _finish("inconclusive_wall_bound")
