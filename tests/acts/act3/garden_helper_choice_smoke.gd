extends "res://tests/acts/act3/garden_network_pair_smoke.gd"
## TEST ONLY retained B05 helper choice. SOURCE-ONLY until Root qualifies it.
## The declared adapter autonomously pumps canonical next_kind/cardinal policy.
## This driver never invokes try_core, suppresses a Core, or writes live actors.
## Clock0 TEST prefix13 is metadata, not earned MAIN route/checkpoint5 history.

const HC_ROOM: String = "res://tests/acts/act3/fixtures/garden_helper_choice_component.tscn"
const HC_RUNTIME: String = "res://tests/acts/act3/fixtures/garden_helper_choice_component.gd"
const HC_Shell = preload("res://scripts/campaign/shell.gd")
const HC_Registry = preload("res://scripts/campaign/registry.gd")
const HC_Attempts = preload("res://scripts/campaign/attempts.gd")
const HC_Store = preload("res://scripts/campaign/save_store.gd")
const HC_Exact = preload("res://scripts/campaign/exact_json.gd")
const HC_HELPER_ID: String = "test-helper-choice-latcher"
const HC_NEUTRAL: Dictionary = {"jacket":"CLOTH-J0","pants":"CLOTH-P0","shoes":"CLOTH-S0","weapon":"WEAPON-01"}
const HC_COMBINED: Dictionary = {"jacket":"CLOTH-J0","pants":"CLOTH-P2","shoes":"CLOTH-S2","weapon":"WEAPON-03"}
const HC_MAX_CLOCK_S: float = 80.0

class ChoiceBarrier extends Node:
	signal observed
	signal presented
	var waiting: bool = false
	var presentation_waiting: bool = false
	var expired: bool = false
	var native_physics_seen: bool = false
	var frames: int = 0
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 1000
		process_priority = 1000
	func _physics_process(_delta: float) -> void:
		if waiting and not get_tree().paused:
			native_physics_seen = true
			_wake()
	func _process(_delta: float) -> void:
		if presentation_waiting:
			presentation_waiting = false
			presented.emit()
		if waiting:
			frames += 1
			if frames >= 120:
				expired = true
				_wake()
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PAUSED and waiting: _wake.call_deferred()
	func _wake() -> void:
		if waiting:
			waiting = false
			observed.emit()

var _hc_barrier: ChoiceBarrier
var _hc_shell: CinderCampaignShell
var _hc_helper: Node3D
var _hc_done: bool = false
var _hc_finishing: bool = false
var _hc_selector: String = ""
var _hc_case_name: String = ""
var _hc_registry_text: String = ""
var _hc_registry: Dictionary = {}
var _hc_store_root: String = ""
var _hc_initial: Dictionary = {}
var _hc_stats: Dictionary = {}
var _hc_results: Array[Dictionary] = []
var _hc_actions: Array[Dictionary] = []
var _hc_phases: Dictionary = {}
var _hc_used_proofs: Dictionary = {}
var _hc_pressure: Dictionary = {}
var _hc_native_ticks: int = 0
var _hc_last_dash_end: float = -1.0
var _hc_last_tap_wall_ms: int = -10000
var _hc_quiet: bool = false
var _hc_quiet_events: Array[String] = []
var _hc_seen: Dictionary = {}
var _hc_callbacks: Array[Dictionary] = []
var _hc_archives: Array[String] = []
var _hc_hosts: Array[WeakRef] = []

func _initialize() -> void:
	create_timer(600.0, true, false, true).timeout.connect(_hc_timeout, CONNECT_ONE_SHOT)
	_run.call_deferred()

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_hc_selector = args[0] if args.size() == 1 else ""
	if not _expect(args.size() == 1 and _hc_selector in ["--compare", "--transport-held", "--transport-dead"], "one explicit comparison or genuine component transport selector", str(args)):
		await _finish(); return
	_hc_registry_text = FileAccess.get_file_as_string(HC_Registry.DATA_PATH)
	if not node_added.is_connected(_hc_watch_node): node_added.connect(_hc_watch_node)
	if _hc_selector == "--compare":
		for row: Dictionary in [{"name":"neutral-helper-live","kit":HC_NEUTRAL,"remove":false},{"name":"neutral-helper-dead","kit":HC_NEUTRAL,"remove":true},{"name":"closer-slower-helper-dead","kit":HC_COMBINED,"remove":true}]:
			if _hc_done or _failures > 0: break
			await _hc_compare(row.name, row.kit, row.remove)
			await _close()
	else:
		await _hc_transport_case(_hc_selector == "--transport-dead")
	await _finish()

func _hc_timeout() -> void:
	if _hc_done or _hc_finishing: return
	_expect(false, "600 real wall seconds bound only this declared TEST process")
	await _finish()

func _hc_open_main(kit: Dictionary) -> bool:
	if _hc_done or _hc_finishing: return false
	_hc_actions.clear(); _events.clear(); _hc_phases.clear(); _hc_used_proofs.clear(); _hc_pressure.clear()
	_hc_last_dash_end = -1.0; _hc_last_tap_wall_ms = -10000
	_game = MainScene.instantiate()
	root.add_child(_game)
	_hc_hosts.append(weakref(_game))
	_game.call("open_bench")
	var lab: CinderPlayer = _game.get("player") as CinderPlayer
	if not _expect(paused and _game.call("is_lab_level") and is_instance_valid(lab) and get_nodes_in_group("enemies").is_empty(), "actual enemy-free paused Main permits initial canonical equipment selection"): return false
	for slot: String in ["jacket","pants","shoes","weapon"]:
		if lab.equipment.snapshot().get(slot) == kit[slot]: continue
		if not _expect(lab.equip_item(kit[slot]), "public initial equip: " + String(kit[slot])): return false
	if not _expect(lab.equipment.snapshot() == kit and _game.call("load_level_scene", HC_ROOM), "public Main loads one declared helper-choice component with the actual selected kit", String(_game.get("level_load_error"))): return false
	_game.call("open_bench")
	if not _hc_bind(): return false
	for _frame: int in range(4): await process_frame
	return _expect(paused and _scheduler.get_clock() == 0.0 and _hero.get_world_action_clock() == 0.0 and _hero.get_world_action_records().is_empty() and _hero.equipment.snapshot() == kit and _hero.hp == _hero.max_hp and _hero.global_position == Vector3(0,0.1,1.25) and _tether.get("hp") == 60.0 and _tether.get("phase") == 1 and not is_instance_valid(_level.get("helper")) and _scheduler.encounter_profile().get("id") == "challenge", "fresh declared clock0 Challenge has original target60/no helper/history; no actor repair", _hc_detail())

func _hc_bind() -> bool:
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _expect(is_instance_valid(_level) and is_instance_valid(_hero) and _level.get_script().resource_path == HC_RUNTIME and _level.scene_file_path == HC_ROOM and _level.level_id == "A3-L4" and _level.local_snapshot_version == 1, "actual TEST recipient and one shared Hero bind"): return false
	_core = _level.get("root_network") as Node3D
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	if not _expect(is_instance_valid(_core) and is_instance_valid(_scheduler) and String(_level.call("runtime_error")).is_empty(), "actual unchanged Core/Scheduler configure against full retained garden floor", String(_level.call("runtime_error"))): return false
	_tether = _core.call("get_tether") as StaticBody3D
	_mechanisms = _core.call("get_mechanisms")
	_hc_helper = _level.get("helper") as Node3D
	_kit = _hero.equipment.snapshot().duplicate(true); _hc_stats = _hero.equipment.resolved_stats().duplicate(true); _hero_hp = _hero.hp
	_fixed_target = _tether.global_transform; _fixed_sources.clear()
	for kind: String in ["draw","enclose"]: _fixed_sources[kind] = _source(kind).global_transform
	if is_instance_valid(_hc_barrier): _hc_barrier.queue_free()
	_hc_barrier = ChoiceBarrier.new(); _hc_barrier.name = "ActualPostActorAndPresentationObserver"; _game.add_child(_hc_barrier)
	_hc_connect(_hero, "fired", func(kind: String) -> void: _events.append("fired_" + kind))
	_hc_connect(_hero, "world_action_executed", func(action: Dictionary) -> void: _hc_actions.append(action.duplicate(true)))
	_hc_connect(_hero, "died", func() -> void: _events.append("hero_death"))
	_hc_connect(_level, "checkpoint_requested", func(_id: String, _checkpoint: String, _kind: String) -> void: _events.append("checkpoint"))
	_hc_connect(_level, "completion_requested", func(_id: String, _completion: String) -> void: _events.append("completion"))
	_hc_connect(_level, "contact_exit_requested", func(_id: String, _exit: String) -> void: _events.append("exit"))
	var bindings: Dictionary = _level.call("scheduler_bindings")
	var policy: Dictionary = _level.call("choice_state")
	return _expect(policy.get("policy") == "canonical-next-kind-cardinal-scan-1" and _level.is_physics_processing() and _level.process_physics_priority == 130 and bindings.get("actors", {}).get("hero") == _hero and bindings.get("world_root") == _level.get_parent() and bindings.get("floors") is Dictionary and bindings.floors.size() == 1 and _scheduler.get_world_3d() == _hero.get_world_3d() and _core.get_world_3d() == _hero.get_world_3d() and _scheduler.encounter_profile().get("id") == "challenge", "actual common World/floor/Hero/one Scheduler and saved Challenge identity remain native")

func _hc_compare(label: String, kit: Dictionary, remove_helper: bool) -> bool:
	_hc_case_name = label
	if not await _hc_open_main(kit): return false
	_game.call("resume_lab")
	if not _expect(not paused, "public resume starts the declared ordinary comparison"): return false
	if not await _hc_earn_phase2(): return false
	var boundary: Dictionary = _hc_observation()
	if remove_helper and not await _hc_remove_helper(): return false
	var after_choice: Dictionary = _hc_observation()
	if not await _hc_useful_tether_primary(): return false
	_hc_helper = _level.get("helper") as Node3D
	var native: Dictionary = _hc_helper.call("state")
	var expected: float = maxf(0.0, 30.0 - float(_hero.stats.primary_damage))
	var passed: bool = float(_tether.get("hp")) == expected and _tether.get("phase") == 2 and _hero.hp == _hero_hp and (bool(native.dead) if remove_helper else not bool(native.dead)) and not _hc_pressure.is_empty()
	if not _expect(passed, "real target choice earns useful ordinary tether damage with full HP and recorded autonomous helper pressure: " + label, _hc_detail()): return false
	_hc_results.append({"case":label,"kit":kit.duplicate(true),"declared_start":Vector3(0,0.1,1.25),"boundary":boundary,"after_choice":after_choice,"final":_hc_observation(),"native_actions":_hc_actions.duplicate(true),"native_phases":_hc_phases.duplicate(true),"actual_helper_pressure":_hc_pressure.duplicate(true),"admissions":_level.call("choice_admissions"),"attempts":_level.call("choice_attempts"),"refusals":_level.call("choice_refusals"),"canonical_parent_history":false})
	return true

func _hc_earn_phase2() -> bool:
	for _opening: int in range(8):
		if _hc_done: return false
		if int(_tether.get("phase")) == 2: break
		var response: Dictionary = await _hc_response("core")
		if response.is_empty() or not await _hc_follow(response): return false
		if response.target == "core" and _core.call("exposure_open"):
			if not _hc_primary(_tether, true): return false
			if int(_tether.get("phase")) == 1 and await _hc_primary_ready(response):
				if not _hc_primary(_tether, true): return false
		if _failures > 0: return false
	_hc_helper = _level.get("helper") as Node3D
	var state: Dictionary = _level.call("component_state")
	return _expect(_tether.get("hp") == 30.0 and _tether.get("phase") == 2 and is_instance_valid(_hc_helper) and not _hc_helper.get("dead") and _hc_helper.get("hp") == _hc_helper.get("max_hp") and state.sun.started and state.sun.anchor_s != null and state.helper_death.is_empty() and state.helper_retired.is_empty(), "ordinary phase1 recovery strikes alone earn exact30 boundary, original living helper and first-boundary Sun", _hc_detail())

func _hc_remove_helper() -> bool:
	for _opening: int in range(10):
		_hc_helper = _level.get("helper") as Node3D
		if bool(_hc_helper.get("dead")): break
		var response: Dictionary = await _hc_response("helper")
		if response.is_empty() or not await _hc_follow(response): return false
		if response.target == "helper" and (_hc_helper.call("state") as Dictionary).get("knot_open", false):
			if not _hc_primary(_hc_helper, false): return false
	var state: Dictionary = _level.call("component_state")
	var mechanism: CinderLaneMechanism = _hc_helper.call("get_mechanism")
	var controls: Dictionary = _scheduler.source_control_state(mechanism)
	return _expect(_hc_helper.get("dead") and _hc_helper.get("hp") == 0.0 and not _hc_helper.is_in_group("enemies") and not state.helper_death.is_empty() and state.helper_retired.is_empty() and mechanism.state().last_cancel_reason == "source_defeated" and not controls.is_empty() and controls.reservations.is_empty() and _tether.get("hp") == 30.0 and _tether.get("phase") == 2 and not _hc_pressure.is_empty(), "real ordinary helper recovery death removes only optional pressure; target remains30 and Core kept pumping", _hc_detail())

func _hc_useful_tether_primary() -> bool:
	for _opening: int in range(10):
		var response: Dictionary = await _hc_response("core")
		if response.is_empty() or not await _hc_follow(response): return false
		if response.target == "core" and _core.call("exposure_open"):
			return _hc_primary(_tether, true)
	return _expect(false, "bounded actual next useful tether recovery remains available", _hc_detail())

func _hc_response(preferred: String) -> Dictionary:
	for _i: int in range(600):
		if _hc_done: return {}
		var choices: Array[Dictionary] = []
		var core_state: Dictionary = _core.call("state")
		for kind: String in ["draw","enclose"]:
			var source: CinderLaneMechanism = _source(kind)
			var current: Dictionary = source.state()
			var proof: Dictionary = core_state.get("proofs", {}).get(kind, {})
			var response: Dictionary = _hc_fresh_response("core", kind, source, current, proof)
			if not response.is_empty(): choices.append(response)
		_hc_helper = _level.get("helper") as Node3D
		if is_instance_valid(_hc_helper) and not bool(_hc_helper.get("dead")):
			var mechanism: CinderLaneMechanism = _hc_helper.call("get_mechanism")
			var current: Dictionary = mechanism.state()
			var helper_state: Dictionary = _hc_helper.call("state")
			var response: Dictionary = _hc_fresh_response("helper", "helper", mechanism, current, helper_state.get("proof", {}))
			if not response.is_empty(): choices.append(response)
		for response: Dictionary in choices:
			if response.target == preferred:
				_hc_used_proofs[response.id] = true
				return response
		if not choices.is_empty():
			_hc_used_proofs[choices[0].id] = true
			return choices[0] # React to a real other source; do not stand in its attack while waiting.
		if not await _tick(): return {}
	_expect(false, "bounded autonomous native admission supplies a fresh ordinary response for " + preferred, _hc_detail())
	return {}

func _hc_fresh_response(target: String, kind: String, owner: CinderLaneMechanism, current: Dictionary, proof: Dictionary) -> Dictionary:
	if current.get("status") != "running" or current.get("phase") != "warning" or _hc_used_proofs.has(current.get("reservation_id")) or not proof.get("accepted", false) or not proof.get("path") is Array: return {}
	var first: Dictionary = {}
	for segment: Dictionary in proof.path:
		if segment.kind in ["escape_dash", "positioning_dash"]: first = segment; break
	if first.is_empty() or not first.get("from") is Vector3 or not first.get("to") is Vector3: return {}
	if _scheduler.get_clock() > float(first.start_s) + 0.000000001 or Vector2(_hero.global_position.x, _hero.global_position.z).distance_to(Vector2(first.from.x, first.from.z)) > 0.005: return {}
	var controls: Dictionary = _scheduler.source_control_state(owner)
	for lease: Dictionary in controls.get("reservations", []):
		if lease.id == current.reservation_id and lease.source_instance_id == owner.get_instance_id():
			return {"target":target,"kind":kind,"owner":owner,"id":lease.id,"proof":proof.duplicate(true),"lease":lease.duplicate(true)}
	return {}

func _hc_follow(response: Dictionary) -> bool:
	var proof: Dictionary = response.proof
	var lease: Dictionary = response.lease
	if not _expect(proof.get("accepted", false) and proof.path is Array and not proof.get("uses_blast", true) and not proof.get("uses_invulnerability", true), "actual native committed union proves only ordinary movement/primary", str(response)): return false
	var dashes: int = 0
	for segment: Dictionary in proof.path:
		if segment.kind not in ["escape_dash", "positioning_dash"]: continue
		var scheduled: float = maxf(float(segment.start_s), _hc_last_dash_end)
		if not await _until(scheduled): return false
		var origin: Vector3 = _hero.global_position
		var intended: Vector3 = (segment.to - segment.from).normalized()
		var start: float = _scheduler.get_clock()
		var error: String = _swipe(intended)
		var dash: Dictionary = _hero.get_committed_dash_state()
		if not _expect(error.is_empty() and dash.get("active", false) and dash.get("distance") == _hero.stats.dash_distance and dash.get("duration_s") == _hero.stats.dash_duration and (dash.direction as Vector3).distance_to(intended) < 0.000001 and Vector2(origin.x,origin.z).distance_to(Vector2(segment.from.x,segment.from.z)) < 0.005, "actual engine-routed proof dash keeps origin, full immutable travel and direction", error): return false
		if not await _hc_finish_dash(segment, scheduled, start, response): return false
		if segment.kind == "escape_dash" and not _expect(_hc_last_dash_end <= float(lease.active_from_s) + 0.000000001, "actual escape completes before committed active begins", str(_hc_actions.back())): return false
		if segment.kind == "positioning_dash" and not _expect(start >= float(lease.active_until_s) and _hc_last_dash_end < float(lease.recovery_until_s), "real ordinary return starts after active and finishes inside native recovery", str(_hc_actions.back())): return false
		dashes += 1
	if not await _until(maxf(float(proof.primary_time_s), _hc_last_dash_end)): return false
	var owner: CinderLaneMechanism = response.owner
	var current: Dictionary = owner.state()
	return _expect(dashes > 0 and current.status == "running" and current.reservation_id == response.id and current.phase == "recovery" and _scheduler.get_clock() < float(lease.recovery_until_s) and _hero.global_position.distance_to(proof.attack_position) < 0.02 and _hero.hp == _hero_hp and _hero.get_threat_response_state().primary_cooldown_left_s == 0.0, "actual response reaches the native source recovery/ordinary opening without prescribed extra return", _hc_detail())

func _hc_finish_dash(segment: Dictionary, scheduled: float, started: float, response: Dictionary) -> bool:
	for _i: int in range(90):
		if _hero.get_threat_response_state().motion.dash_left_s == 0.0:
			var records: Array[Dictionary] = _hero.get_world_action_records()
			var final: Dictionary = {} if records.is_empty() else records.back()
			var dt: float = 1.0 / float(Engine.physics_ticks_per_second)
			var duration: float = ceil(float(_hero.stats.dash_duration) / dt - 0.000000001) * dt
			var expected_end: float = started + duration
			var endpoint: float = Vector2(_hero.global_position.x,_hero.global_position.z).distance_to(Vector2(segment.to.x,segment.to.z))
			var ok: bool = final.get("kind") == "dash" and final.get("equipment_ids") == _kit and final.get("resolved_stats") == _hc_stats and final.get("started_at_s") == started and started >= scheduled and started <= scheduled + dt + 0.000000001 and absf(float(final.get("completed_at_s", -1.0)) - expected_end) < 0.000000001 and _hero.get_world_action_clock() == _scheduler.get_clock() and endpoint < 0.005 and _hero.is_on_floor() and not final.get("collision_shortened", true) and not final.get("movement_damage", true) and absf(float(final.get("distance",0.0)) - float(_hero.stats.dash_distance)) < 0.005
			if not _expect(ok, "native request-start ceiling and resolved-duration ceiling are independently exact; full proved landing/HP preserved", str({"segment":segment,"scheduled":scheduled,"started":started,"expected_end":expected_end,"actual":final,"lease":response.lease,"hero":_hero.global_position})): return false
			_hc_last_dash_end = float(final.completed_at_s)
			return true
		if not await _tick(): return false
	return _expect(false, "bounded native full dash completes", _hc_detail())

func _hc_primary_ready(response: Dictionary) -> bool:
	for _i: int in range(90):
		var owner: CinderLaneMechanism = response.owner
		if owner.state().phase != "recovery" or _scheduler.get_clock() >= float(response.lease.recovery_until_s): return false
		if Time.get_ticks_msec() - _hc_last_tap_wall_ms > 280 and _hero.get_threat_response_state().primary_cooldown_left_s == 0.0: return true
		if not await _tick(): return false
	return false # A new genuine admission may offer the next ordinary opening.

func _hc_primary(target: Node3D, tether: bool) -> bool:
	var before: float = float(target.get("hp"))
	var lower: float = 30.0 if tether and int(target.get("phase")) == 1 else 0.0
	var expected: float = maxf(lower, before - float(_hero.stats.primary_damage))
	var open: bool = bool(_core.call("exposure_open")) if tether else bool((target.call("state") as Dictionary).get("knot_open", false))
	if not _expect(open and _hero.get_threat_response_state().primary_cooldown_left_s == 0.0 and Time.get_ticks_msec() - _hc_last_tap_wall_ms > 280, "actual ordinary recovery and native cooldown authorize the selected target"): return false
	var count: int = _hero.get_world_action_records().size()
	var direction: Vector3 = target.global_position - _hero.global_position; direction.y = 0.0
	var error: String = _tap(direction.normalized())
	_hc_last_tap_wall_ms = Time.get_ticks_msec()
	var records: Array[Dictionary] = _hero.get_world_action_records()
	var last: Dictionary = {} if records.is_empty() else records.back()
	return _expect(error.is_empty() and records.size() == count + 1 and last.get("kind") == "primary" and last.get("damage") == _hero.stats.primary_damage and int(last.get("hits", 0)) >= 1 and float(target.get("hp")) == expected and expected < before and _hero.hp == _hero_hp and not _events.has("fired_blast"), "actual engine-routed ordinary primary earns %.3f→%.3f on selected %s" % [before,expected,"tether" if tether else "helper"], error + "; " + str(last))

func _tick() -> bool:
	if _hc_done or _hc_finishing: return false
	if not _expect(not paused and is_instance_valid(_hc_barrier), "actual unpaused native postactor observer is available"): return false
	_hc_barrier.frames = 0; _hc_barrier.expired = false; _hc_barrier.native_physics_seen = false; _hc_barrier.waiting = true
	await _hc_barrier.observed
	if _hc_done or _hc_finishing or not is_instance_valid(_level): return false
	if _hc_barrier.native_physics_seen: _hc_native_ticks += 1
	var error: String = String(_level.call("runtime_error"))
	var fixed: bool = _tether.global_transform == _fixed_target
	for kind: String in ["draw","enclose"]:
		var current: Dictionary = _source(kind).state()
		fixed = fixed and _source(kind).global_transform == _fixed_sources[kind]
		_hc_phases[kind + ":" + String(current.phase)] = true
		if current.status == "cancelled" and current.last_cancel_reason != "garden_phase_boundary": error = "Unexpected actual Core cancellation: " + String(current.last_cancel_reason)
	_hc_helper = _level.get("helper") as Node3D
	if is_instance_valid(_hc_helper):
		var helper_state: Dictionary = _hc_helper.call("state")
		var mechanism: CinderLaneMechanism = _hc_helper.call("get_mechanism")
		_hc_phases["helper:" + String(helper_state.phase)] = true
		fixed = fixed and _hc_helper.global_position == Vector3(-1.5,0,2)
		if helper_state.mechanism.status == "running":
			var controls: Dictionary = _scheduler.source_control_state(mechanism)
			for lease: Dictionary in controls.get("reservations", []):
				if lease.id == helper_state.mechanism.reservation_id and lease.source_instance_id == mechanism.get_instance_id(): _hc_pressure[String(lease.id)] = {"clock_s":_scheduler.get_clock(),"phase":helper_state.phase,"lease":lease.duplicate(true)}
		elif helper_state.mechanism.status == "cancelled" and not helper_state.dead: error = "Unexpected living helper cancellation: " + String(helper_state.mechanism.last_cancel_reason)
	var ok: bool = not _hc_barrier.expired and not paused and error.is_empty() and fixed and not _hero.dead and _hero.hp == _hero_hp and _hero.hp == _hero.max_hp and _hero.equipment.snapshot() == _kit and _hero.equipment.resolved_stats() == _hc_stats and _hero.get_world_action_clock() == _scheduler.get_clock() and absf(_hero.global_position.y) <= 0.2 and Rect2(-7,-14,14,78).has_point(Vector2(_hero.global_position.x,_hero.global_position.z)) and not _events.has("fired_blast") and not _events.has("hero_death") and not _events.has("completion") and not _events.has("checkpoint") and not _events.has("exit") and _scheduler.get_clock() <= HC_MAX_CLOCK_S
	return _expect(ok, "bounded native tick retains autonomous Core/helper policy, fixed physical sources, full Hero/kit/floor and ordinary inputs", error + "; " + _hc_detail())

func _until(target: float) -> bool:
	if target > HC_MAX_CLOCK_S: return _expect(false, "native proof deadline remains inside the declared finite case", str(target))
	for _i: int in range(4800):
		if _scheduler.get_clock() >= target: return _expect(_scheduler.get_clock() <= target + 1.0 / float(Engine.physics_ticks_per_second) + 0.000000001, "first actual native postactor sample reaches its unchanged scheduled target", str({"target":target,"clock_s":_scheduler.get_clock()}))
		if not await _tick(): return false
	return _expect(false, "bounded actual native proof deadline is reachable", _hc_detail())

func _hc_transport_case(dead_helper: bool) -> bool:
	_hc_case_name = "transport-dead" if dead_helper else "transport-held"
	if not await _hc_open_main(HC_NEUTRAL): return false
	var seed: Dictionary = _hc_capture_host(_game)
	if not _expect(not seed.is_empty() and seed.player.world_actions.clock_s == 0.0 and seed.level.local.helper.is_empty() and seed.level.local.control.helper_death.is_empty(), "authentic clock0 native TEST seed contains no helper or later earned boundary", _level.last_snapshot_error): return false
	_hc_initial = seed.duplicate(true)
	var raw: Variant = JSON.parse_string(_hc_registry_text)
	if not _expect(raw is Dictionary, "canonical registry read without mutation"): return false
	_hc_registry = raw.duplicate(true)
	for row: Dictionary in _hc_registry.levels:
		if row.id == "A3-L4":
			row.scene_path = HC_ROOM; row.readiness = "accepted"; row.accepted_commit = "a".repeat(40); row.api_revision = HC_Registry.API_REVISION
	var registry: CinderCampaignRegistry = HC_Registry.new(_hc_registry)
	var model: CinderCampaignAttempts = HC_Attempts.new(registry)
	var session: Dictionary = model.state()
	var prefix: Array[String] = []; prefix.assign(registry.main_route().slice(0,13))
	if not _expect(prefix.size() == 13 and prefix[-1] == "A3-L3" and registry.scene_error("A3-L4").is_empty(), "TEST prefix13/scene readiness is metadata only, never fabricated MAIN phase2 history", registry.last_error): return false
	session.completed_main = prefix.duplicate()
	session.story = {"kind":"story","level_id":"A3-L4","snapshot":seed.duplicate(true),"checkpoint":seed.duplicate(true)}
	_hc_store_root = "user://test-garden-helper-choice-%d-%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	var store: CinderSaveStore = HC_Store.new(_hc_store_root + "campaign.json"); store.payload_validator = model.saved_payload_error
	if not _expect(model.state_error(session).is_empty() and store.write_payload(session), "structurally validated TEST metadata wraps the actual clock0 whole unit without actor repair", model.last_error + "; " + store.last_error): return false
	var main_ids: Dictionary = _hc_ids(_game)
	if not await _hc_retire(_game, "clock0 Main seed donor"): return false
	_game = null; _hc_shell = null
	if not await _hc_new_shell(session): return false
	_hc_shell.menu.continue_story_requested.emit()
	if not await _hc_wait_installed(seed, main_ids) or not _hc_bind(): return false
	_hc_quiet = false
	_hc_shell.resume_lab()
	if not _expect(not paused, "public Shell resumes the genuine clock0 component"): return false
	if not await _hc_earn_phase2(): return false
	if dead_helper:
		if not await _hc_remove_helper(): return false
	else:
		for _opening: int in range(10):
			var response: Dictionary = await _hc_response("helper")
			if response.is_empty(): return false
			if response.target == "helper": break
			if not await _hc_follow(response): return false
		_hc_helper = _level.get("helper") as Node3D
		var helper_state: Dictionary = _hc_helper.call("state")
		if not _expect(helper_state.mechanism.status == "running" and helper_state.phase == "warning" and helper_state.proof.get("accepted",false), "genuine postactor helper warning supplies native held state, not early observer proof", str(helper_state)): return false
	# One actual Main/Shell presentation callback follows the postactor sample;
	# then the public deferred Pause owns Save. No fitting/camera writes.
	if not await _hc_presented_pause(): return false
	var saved: Dictionary = _hc_shell.capture_campaign_snapshot()
	if not _expect(not saved.is_empty() and _level.snapshot_error_with_player(saved.level,saved.player).is_empty() and saved.level.local.world.profile_id == "challenge" and saved.level.local.helper.dead == dead_helper and not saved.level.local.helper.is_empty(), "public paused Save captures complete genuine held/dead helper unit with original Challenge", _hc_shell.campaign_error + "; " + _level.last_snapshot_error): return false
	var decoded: Dictionary = HC_Exact.parse(HC_Exact.stringify(saved))
	if not _expect(decoded.get("accepted",false) and _wire_exact(decoded.value,saved), "ExactJSON preserves complete native Player/component/clock/resources/journal/helper state"): return false
	session = _hc_shell.attempts.state()
	if not _expect(_wire_exact(session.story.snapshot,saved) and _wire_exact(session.story.checkpoint,_hc_initial) and _hc_disk(session), "actual Pause/Store retains genuine saved unit plus original clock0 TEST checkpoint"): return false
	if not _hc_atomic_negatives(saved): return false
	if not _hc_archive(saved,session,dead_helper): return false
	if not await _hc_set_preference("assisted",saved): return false
	var donor: CinderCampaignShell = _hc_shell
	var donor_ids: Dictionary = _hc_ids(donor)
	var donor_observation: Dictionary = _hc_host_observation(donor)
	if not _expect(not donor_observation.is_empty(),"donor witness contains actual typed whole/native/input/Camera data before encoding"): return false
	_hc_quiet_events.clear(); _hc_quiet = true
	if not await _hc_new_shell(session): return false
	if not _expect(_hc_shell.get_difficulty_preference() == "assisted", "fresh disk Shell has opposite FUTURE preference before saved Challenge Continue"): return false
	_hc_shell.menu.continue_story_requested.emit()
	if not await _hc_wait_installed(saved,donor_ids) or not _hc_bind(): return false
	if not _expect(_hc_native_equal(_hc_host_observation(donor),donor_observation), "independent fresh Continue leaves the complete real donor unit/input/Camera/session untouched"): return false
	if not await _hc_retire(donor,"held/dead donor Shell"): return false
	if not await _hc_quiet_exact(saved,session): return false
	var restored_helper: Node3D = _level.get("helper") as Node3D
	var restored_state: Dictionary = _level.call("component_state")
	if not _expect(is_instance_valid(restored_helper) and restored_helper.get("dead") == dead_helper and (not restored_state.helper_death.is_empty() if dead_helper else restored_state.helper_death.is_empty()) and _scheduler.encounter_profile().get("id") == "challenge", "fresh quiet recipient keeps real helper death/no-respawn or held state under opposite preference"): return false
	var old_ids: Dictionary = _hc_ids(_hc_shell)
	var old_container: Node = _hc_shell.world.get_parent().get_parent()
	var refs: Array[WeakRef] = []; _weakrefs(old_container,refs)
	if not _expect(old_container is SubViewportContainer and old_container.get_parent() == _hc_shell, "Retry observes the real entire old viewport subtree"): return false
	_hc_detach_callbacks(old_container); _hc_quiet_events.clear(); _hc_quiet = true
	_hc_shell.request_retry()
	if not await _hc_wait_installed(_hc_initial,old_ids) or not _hc_bind() or not await _hc_refs_released(refs,"Retry old world"): return false
	var retried: Dictionary = session.duplicate(true); retried.story.snapshot = _hc_initial.duplicate(true)
	if not _expect(_wire_exact(_hc_shell.attempts.state(),retried) and _wire_exact(_hc_shell.attempts.state().story.checkpoint,_hc_initial) and not is_instance_valid(_level.get("helper")) and _tether.get("hp") == 60.0 and _tether.get("phase") == 1 and _scheduler.get_clock() == 0.0 and _scheduler.encounter_profile().get("id") == "challenge" and _hc_shell.get_difficulty_preference() == "assisted", "public Retry restores original TEST clock0 before helper entitlement, never pretending later death survives an earlier checkpoint"): return false
	return await _hc_quiet_exact(_hc_initial,retried)

func _hc_capture_host(host: Node) -> Dictionary:
	if host is CinderCampaignShell: return (host as CinderCampaignShell).capture_campaign_snapshot()
	var actor: CinderPlayer = host.get("player") as CinderPlayer
	var level: CinderLevel = host.get("active_level") as CinderLevel
	var camera: Camera3D = host.get("camera") as Camera3D
	var hud: GameHUD = host.get("hud") as GameHUD
	if not paused or not is_instance_valid(actor) or not is_instance_valid(level) or not is_instance_valid(camera) or not is_instance_valid(hud): return {}
	var input: Dictionary = host.call("get_input_observation_state")
	if actor.get_world_action_clock() != 0.0 or not actor.get_world_action_records().is_empty() or input.sequence != 0 or not input.last_observation.is_empty() or host.call("get_aim_anchor_normalized") != Vector2(0.5,0.5): return {}
	hud.update_status(actor.hp,actor.max_hp,actor.shells,actor.max_shells,0,level.objective_text)
	var player: Dictionary = actor.snapshot_state()
	var unit: Dictionary = level.snapshot_state_for_presentation(camera,hud)
	if player.is_empty() or unit.is_empty() or not level.snapshot_error_with_player(unit,player).is_empty(): return {}
	return {"schema_version":1,"level_id":"A3-L4","scene_path":HC_ROOM,"paused":true,"equipment_ids":actor.equipment.snapshot(),"player":player,"level":unit,"shell":{"api_revision":HC_Shell.SHELL_API,"anchor_normalized":[0.5,0.5],"input_sequence":0,"last_input_observation":{},"camera_focus":PairCodec.vector3(camera.global_position-Vector3(0,18,13)),"shake_left_s":0.0,"difficulty_at_entry":"challenge"}}

func _hc_new_shell(session: Dictionary) -> bool:
	if _hc_done or _hc_finishing: return false
	_hc_shell = HC_Shell.new(); _game = _hc_shell
	if not _expect(_hc_shell.configure_runtime(_hc_registry,_hc_store_root+"campaign.json",_hc_store_root+"settings.json",_hc_store_root+"preferences.json"), "fresh public Shell binds isolated real Store/TEST registry"): return false
	root.add_child(_hc_shell)
	_hc_hosts.append(weakref(_hc_shell))
	for _frame: int in range(120):
		await process_frame
		if _hc_done: return false
		if not _hc_shell.campaign_error.is_empty(): return _expect(false,"actual paused startup refuses rather than repairs state",_hc_shell.campaign_error)
		if paused and is_instance_valid(_hc_shell.menu) and _hc_shell.menu.page_name() == "title" and _wire_exact(_hc_shell.attempts.state(),session):
			await process_frame
			return _expect(paused and _hc_shell.campaign_error.is_empty() and _wire_exact(_hc_shell.attempts.state(),session) and not is_instance_valid(_hc_shell.active_level), "public async startup loads exact disk session without installing donor aliases")
	return _expect(false,"bounded120 real process observations settle public disk startup")

func _hc_wait_installed(unit: Dictionary, previous: Dictionary) -> bool:
	if not _expect(not previous.is_empty(),"native replacement identity witness is nonempty before construction"): return false
	for _frame: int in range(120):
		await process_frame
		if _hc_done: return false
		if not _hc_shell.campaign_error.is_empty(): return _expect(false,"public Continue/Retry rejects immediately on actual refusal",_hc_shell.campaign_error)
		if not paused or not is_instance_valid(_hc_shell.active_level) or _hc_shell.menu.page_name() != "resume": continue
		var now: Dictionary = _hc_ids(_hc_shell)
		var distinct: bool = not now.is_empty() and PairCodec.keys_error(now,previous.keys()).is_empty()
		for key: String in previous:
			if key in ["host","hud"] and now.get("host") == previous.get("host"):
				distinct = distinct and int(now.get(key,0)) != 0 and now.get(key) == previous[key]
			elif key.begins_with("helper_") and unit.level.local.helper.is_empty():
				distinct = distinct and now.get(key,0) == 0
			else: distinct = distinct and int(previous[key]) != 0 and int(now.get(key,0)) != 0 and now.get(key) != previous[key]
		if not distinct or not _wire_exact(_hc_shell.capture_campaign_snapshot(),unit): continue
		await process_frame
		return _expect(paused and _hc_shell.campaign_error.is_empty() and _wire_exact(_hc_shell.capture_campaign_snapshot(),unit) and not _hc_shell.is_pause_requested() and _hc_shell.active_level.hero == _hc_shell.player and _hc_shell.active_level.shared_shell == _hc_shell and _hc_shell.camera.get_viewport().get_camera_3d() == _hc_shell.camera and _hc_shell.camera.get_world_3d() == _hc_shell.player.get_world_3d(), "genuine fresh world/owners/current Camera-HUD quiet installation equals the exact saved whole unit")
	return _expect(false,"public native replacement finishes within120 process observations with ALL distinct identities and exact unit",_hc_shell.campaign_error + "; " + str(_hc_ids(_hc_shell)))

func _hc_presented_pause() -> bool:
	if paused: return true
	if not is_instance_valid(_hc_barrier): return false
	_hc_barrier.presentation_waiting = true
	await _hc_barrier.presented
	if _hc_done or paused: return _expect(false,"real native presentation finishes before the TEST public pause; no focus-pause bypass")
	if not _expect(_game.call("request_pause_deferred"),"public deferred pause owns genuine helper Save boundary"): return false
	for _frame: int in range(120):
		await process_frame
		if _hc_done: return false
		if paused and not _game.call("is_pause_requested"):
			if is_instance_valid(_hc_shell):
				if not _hc_shell.campaign_error.is_empty(): return _expect(false,"public Save refused",_hc_shell.campaign_error)
				var current: Dictionary = _hc_shell.capture_campaign_snapshot()
				if _hc_shell.menu.page_name() != "pause" or current.is_empty() or not _wire_exact(_hc_shell.attempts.state().story.snapshot,current): continue
			await process_frame
			return _expect(paused and not _game.call("is_pause_requested"),"public pause/Save remains settled after a real UI boundary")
	return _expect(false,"bounded actual completed pause is observed")

func _hc_set_preference(profile: String, expected: Dictionary) -> bool:
	var before: Dictionary = _hc_shell.attempts.state()
	_hc_shell.menu.show_settings()
	var option: OptionButton = _hc_shell.menu.find_child("DifficultySelector",true,false) as OptionButton
	if not _expect(is_instance_valid(option),"actual public future difficulty option exists"): return false
	var found: int = -1
	for i: int in range(option.item_count):
		if option.get_item_metadata(i) == profile: found = i
	if not _expect(found >= 0,"existing canonical opposite future profile exists"): return false
	option.select(found); option.item_selected.emit(found)
	var reader: CinderSaveStore = HC_Store.new(_hc_store_root+"preferences.json")
	return _expect(_hc_shell.get_difficulty_preference() == profile and _wire_exact(reader.read_payload(),{"schema_version":1,"profile_id":profile}) and _wire_exact(_hc_shell.attempts.state(),before) and _wire_exact(_hc_shell.capture_campaign_snapshot(),expected), "public opposite future preference changes neither actual Challenge nor native history/session")

func _hc_disk(session: Dictionary) -> bool:
	var reader: CinderSaveStore = HC_Store.new(_hc_store_root+"campaign.json")
	var payload: Dictionary = reader.read_payload()
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(_hc_store_root+"campaign.json"))
	return _expect(reader.last_error.is_empty() and not reader.loaded_backup and reader.generation > 0 and envelope is Dictionary and envelope.get("format_version") == 2 and envelope.get("payload_json") is String and envelope.payload_json.sha256_text() == envelope.get("sha256") and _wire_exact(payload,session), "independent native ExactJSON Store format2 joins exact complete session",reader.last_error)

func _hc_quiet_exact(unit: Dictionary, session: Dictionary) -> bool:
	var before: Dictionary = {"host":_hc_host_observation(_hc_shell),"events":_events.duplicate(true),"actions":_hc_actions.duplicate(true),"quiet":_hc_quiet_events.duplicate()}
	if not _expect(not before.host.is_empty() and _hc_quiet_events.is_empty() and _wire_exact(_hc_shell.capture_campaign_snapshot(),unit), "quiet witness is nonempty and native committed whole packet is exact",str(_hc_quiet_events)): return false
	for _frame: int in range(3): await process_frame
	return _expect(paused and _hc_shell.campaign_error.is_empty() and _wire_exact(_hc_shell.capture_campaign_snapshot(),unit) and _wire_exact(_hc_shell.attempts.state(),session) and _hc_native_equal(_hc_host_observation(_hc_shell),before.host) and _events == before.events and _hc_native_equal(_hc_actions,before.actions) and _hc_quiet_events == before.quiet and _hc_disk(session), "paused native resources/clocks/leases/death/model/optics/input/IDs/session remain exact with no gameplay emissions")

func _hc_atomic_negatives(saved: Dictionary) -> bool:
	var cases: Array[Dictionary] = []
	var bad: Dictionary = saved.duplicate(true); bad.level.local.helper.hp = 1.0 if bad.level.local.helper.dead else 0.0; cases.append({"name":"helper HP/death","unit":bad})
	bad = saved.duplicate(true); bad.level.local.scheduler.profile.id = "assisted"; cases.append({"name":"canonical saved profile join","unit":bad})
	bad = saved.duplicate(true); bad.level.local.helper.mechanism.exchange.recovery_until_s = float(bad.level.local.helper.mechanism.exchange.recovery_until_s) + 0.00000001; cases.append({"name":"helper recovery deadline join","unit":bad})
	if saved.level.local.helper.dead:
		bad = saved.duplicate(true); bad.level.local.control.helper_death.clock_s = float(bad.level.local.helper.mechanism.exchange.active_until_s); cases.append({"name":"death outside earned recovery","unit":bad})
	for row: Dictionary in cases:
		var before: Dictionary = _hc_host_observation(_hc_shell)
		var events: Array[String] = _events.duplicate(); var actions: Array[Dictionary] = _hc_actions.duplicate(true)
		var error: String = _level.snapshot_error_with_player(row.unit.level,row.unit.player)
		if not _expect(not error.is_empty() and not _level.restore_state(row.unit.level) and _hc_native_equal(_hc_host_observation(_hc_shell),before) and _events == events and _hc_native_equal(_hc_actions,actions), "copy-only malformed " + String(row.name) + " rejects pure/restore atomically",error): return false
	return true

func _hc_archive(unit: Dictionary, session: Dictionary, dead_helper: bool) -> bool:
	var directory: String = "res://captures/act3/garden-helper-choice/%s-%d-%d/" % ["dead" if dead_helper else "held",OS.get_process_id(),Time.get_ticks_usec()]
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) != OK: return _expect(false,"create authentic paused component archive")
	var files: Dictionary = {"unit.native.json":unit,"session.native.json":session,"checkpoint.native.json":_hc_initial,"registry.native.json":_hc_registry}
	var manifest: Dictionary = {"schema_version":1,"scope":"TEST Challenge helper component, genuinely earned boundary/death; no canonical MAIN checkpoint5/route authority","files":{},"source_pins":{},"producer_fixture_hash_is_provenance_only":true}
	for filename: String in files:
		var wire: String = HC_Exact.stringify(files[filename])
		var output: FileAccess = FileAccess.open(directory+filename,FileAccess.WRITE)
		if wire.is_empty() or output == null: return _expect(false,"write exact authentic component wire: "+filename)
		output.store_string(wire); output.close(); manifest.files[filename] = {"bytes":wire.to_utf8_buffer().size(),"sha256":FileAccess.get_sha256(directory+filename)}
	for filename: String in ["campaign.json","campaign.json.bak","preferences.json"]:
		var source: String = _hc_store_root+filename
		if not FileAccess.file_exists(source):
			if filename.ends_with(".bak") or filename == "preferences.json": continue
			return _expect(false,"real primary Store exists before archive")
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(source)
		var output: FileAccess = FileAccess.open(directory+filename,FileAccess.WRITE)
		if output == null: return _expect(false,"write unmodified actual raw Store archive")
		output.store_buffer(bytes); output.close(); manifest.files[filename] = {"bytes":bytes.size(),"sha256":FileAccess.get_sha256(directory+filename)}
	for path: String in ["res://tests/acts/act3/garden_helper_choice_smoke.gd",HC_RUNTIME,"res://tests/acts/act3/fixtures/garden_helper_choice_component_codec.gd",HC_ROOM,"res://scripts/acts/act3/garden_root_network.gd","res://scripts/acts/act3/garden_root_latcher.gd","res://scripts/acts/act3/garden_root_tether.gd","res://scripts/acts/act3/false_paradise_level.gd","res://scripts/acts/act3/false_paradise_codec.gd","res://scripts/combat/threat_scheduler.gd","res://scripts/campaign/shell.gd","res://data/design/difficulty_profiles.json"]: manifest.source_pins[path] = FileAccess.get_sha256(path)
	var receipt: FileAccess = FileAccess.open(directory+"manifest.json",FileAccess.WRITE)
	if receipt == null: return _expect(false,"write original authentic archive receipt")
	receipt.store_string(HC_Exact.stringify(manifest)); receipt.close(); _hc_archives.append(directory)
	return _expect(true,"authentic paused helper archive retained for separately scoped brief visual: "+directory)

func _hc_ids(host: Node) -> Dictionary:
	if not is_instance_valid(host): return {}
	var level: CinderLevel = host.get("active_level") as CinderLevel
	var actor: CinderPlayer = host.get("player") as CinderPlayer
	var camera: Camera3D = host.get("camera") as Camera3D
	var hud: GameHUD = host.get("hud") as GameHUD
	if not is_instance_valid(level) or not is_instance_valid(actor) or not is_instance_valid(camera) or not is_instance_valid(hud): return {}
	var scheduler: CinderThreatScheduler = level.get("threat_scheduler") as CinderThreatScheduler
	var core: Node3D = level.get("root_network") as Node3D
	var echo: Node3D = level.get("echo") as Node3D
	var helper: Node3D = level.get("helper") as Node3D
	if not is_instance_valid(scheduler) or not is_instance_valid(core) or not is_instance_valid(echo): return {}
	var mechanisms: Dictionary = core.call("get_mechanisms")
	var bindings: Dictionary = level.call("scheduler_bindings")
	if bindings.get("floors",{}).size() != 1: return {}
	var region: Dictionary = bindings.floors.values()[0]
	var collision: CollisionShape3D = region.collision as CollisionShape3D
	var helper_mechanism: CinderLaneMechanism = helper.call("get_mechanism") if is_instance_valid(helper) else null
	return {"host":host.get_instance_id(),"world":level.get_parent().get_instance_id(),"world3d":level.get_world_3d().get_instance_id(),"level":level.get_instance_id(),"hero":actor.get_instance_id(),"scheduler":scheduler.get_instance_id(),"core":core.get_instance_id(),"target":(core.call("get_tether") as Node).get_instance_id(),"draw":(mechanisms.draw as Node).get_instance_id(),"enclose":(mechanisms.enclose as Node).get_instance_id(),"floor":collision.get_parent().get_instance_id(),"floor_shape":collision.get_instance_id(),"echo":echo.get_instance_id(),"echo_renderer":(echo.call("get_authored_echo_renderer") as Node).get_instance_id(),"camera":camera.get_instance_id(),"hud":hud.get_instance_id(),"helper_actor":helper.get_instance_id() if is_instance_valid(helper) else 0,"helper_mechanism":helper_mechanism.get_instance_id() if is_instance_valid(helper_mechanism) else 0,"helper_cue":helper_mechanism.get_cue().get_instance_id() if is_instance_valid(helper_mechanism) else 0}

func _hc_host_observation(host: Node) -> Dictionary:
	if not is_instance_valid(host): return {}
	var unit: Dictionary = _hc_capture_host(host)
	var ids: Dictionary = _hc_ids(host)
	var level: CinderLevel = host.get("active_level") as CinderLevel
	var camera: Camera3D = host.get("camera") as Camera3D
	if unit.is_empty() or ids.is_empty() or not unit.get("player") is Dictionary or unit.player.is_empty() or not unit.get("level") is Dictionary or unit.level.is_empty(): return {}
	return {"unit":unit,"ids":ids,"input":host.call("get_input_observation_state"),"camera":{"transform":camera.global_transform,"projection":camera.projection,"size":camera.size,"near":camera.near,"far":camera.far,"keep_aspect":camera.keep_aspect,"h_offset":camera.h_offset,"v_offset":camera.v_offset},"choice_native":level.call("choice_state"),"session":(host as CinderCampaignShell).attempts.state() if host is CinderCampaignShell else {}}

func _hc_native_equal(left: Variant, right: Variant) -> bool:
	return var_to_bytes(left) == var_to_bytes(right)

func _hc_observation() -> Dictionary:
	return {"clock_s":_scheduler.get_clock(),"hero_position":_hero.global_position,"hero_hp":_hero.hp,"hero_max_hp":_hero.max_hp,"kit":_hero.equipment.snapshot(),"stats":_hero.equipment.resolved_stats(),"hero_response":_hero.get_threat_response_state(),"core":_core.call("state"),"helper":_hc_helper.call("state") if is_instance_valid(_hc_helper) else {},"component":_level.call("component_state"),"policy":_level.call("choice_state")}

func _hc_detail() -> String:
	return str(_hc_observation()) if is_instance_valid(_hero) and is_instance_valid(_core) and is_instance_valid(_scheduler) else "native bindings unavailable"

func _hc_connect(node: Node, signal_name: String, callback: Callable) -> void:
	if not is_instance_valid(node) or not node.has_signal(signal_name) or node.is_connected(signal_name,callback): return
	node.connect(signal_name,callback)
	_hc_callbacks.append({"node":weakref(node),"signal":signal_name,"callback":callback})

func _hc_detach_callbacks(ancestor: Node = null) -> void:
	var kept: Array[Dictionary] = []
	for row: Dictionary in _hc_callbacks:
		var node: Node = (row.node as WeakRef).get_ref() as Node
		if not is_instance_valid(node): continue
		if is_instance_valid(ancestor) and node != ancestor and not ancestor.is_ancestor_of(node): kept.append(row); continue
		if node.is_connected(row.signal,row.callback): node.disconnect(row.signal,row.callback)
	_hc_callbacks = kept

func _hc_watch_node(node: Node) -> void:
	if not is_instance_valid(_hc_shell) or not _hc_shell.is_ancestor_of(node) or _hc_seen.has(node.get_instance_id()): return
	var id: int = node.get_instance_id(); _hc_seen[id] = true
	if node is CinderPlayer:
		_hc_connect(node,"fired",_hc_note_string.bind(id,"Hero fire"))
		_hc_connect(node,"world_action_executed",_hc_note_state.bind(id,"Hero action"))
		_hc_connect(node,"died",_hc_note_zero.bind(id,"Hero death"))
	if node is CinderLaneMechanism:
		_hc_connect(node,"hit_resolved",_hc_note_hit.bind(id,"enemy hit"))
		_hc_connect(node,"state_changed",_hc_note_state.bind(id,"mechanism state"))
	if node is CinderThreatCue or node is CinderAct3RootLatcher or node is CinderAct3GardenRootTether:
		_hc_connect(node,"state_changed",_hc_note_state.bind(id,"cue/target/helper state"))
	if node is CinderLevel:
		_hc_connect(node,"checkpoint_requested",_hc_note_checkpoint.bind(id,"checkpoint"))
		_hc_connect(node,"completion_requested",_hc_note_progress.bind(id,"completion"))
		_hc_connect(node,"contact_exit_requested",_hc_note_progress.bind(id,"exit"))

func _hc_note(id: int, label: String) -> void:
	if not _hc_quiet or not is_instance_valid(_hc_shell): return
	var node: Node = instance_from_id(id) as Node
	if is_instance_valid(node) and node.is_node_ready() and _hc_shell.is_ancestor_of(node): _hc_quiet_events.append(label)
func _hc_note_zero(id: int, label: String) -> void: _hc_note(id,label)
func _hc_note_string(_value: String, id: int, label: String) -> void: _hc_note(id,label)
func _hc_note_state(_value: Dictionary, id: int, label: String) -> void: _hc_note(id,label)
func _hc_note_hit(_hero_id: String, _cycle: int, _result: Dictionary, id: int, label: String) -> void: _hc_note(id,label)
func _hc_note_progress(_level_id: String, _progress: String, id: int, label: String) -> void: _hc_note(id,label)
func _hc_note_checkpoint(_level_id: String, _checkpoint: String, _kind: String, id: int, label: String) -> void: _hc_note(id,label)

func _hc_retire(host: Node, label: String) -> bool:
	if not is_instance_valid(host): return true
	_hc_detach_callbacks(host)
	var refs: Array[WeakRef] = []; _weakrefs(host,refs)
	var clean_exit: bool = true
	var level: CinderLevel = host.get("active_level") as CinderLevel
	if is_instance_valid(level) and level.get_script() != null and level.get_script().resource_path == HC_RUNTIME:
		var scheduler: CinderThreatScheduler = level.get("threat_scheduler") as CinderThreatScheduler
		var actor: CinderPlayer = host.get("player") as CinderPlayer
		var bindings: Dictionary = level.call("scheduler_bindings")
		var clock: float = scheduler.get_clock()
		var hp: float = actor.hp
		level.exit_level() # Supported cancellation occurs while every owner remains in its native tree.
		var empty: bool = true
		for owner: Node3D in bindings.owners.values():
			var control: Dictionary = scheduler.source_control_state(owner)
			empty = empty and not control.is_empty() and control.get("reservations",[]).is_empty()
		clean_exit = _expect(empty and scheduler.get_clock() == clock and actor.hp == hp, "public whole-level exit clears actual retained leases without clock/HP writes: " + label)
	elif is_instance_valid(level):
		level.exit_level() # Failed setup may still be an ordinary Character Lab.
	if host.get_parent() == root: root.remove_child(host)
	host.queue_free()
	var freed: bool = await _hc_refs_released(refs,label)
	return clean_exit and freed

func _hc_refs_released(refs: Array[WeakRef], label: String) -> bool:
	for _frame: int in range(120):
		await process_frame
		var freed: bool = true
		for ref: WeakRef in refs: freed = freed and ref.get_ref() == null
		if freed: return _expect(true,"all actual native subtree WeakRefs free: "+label)
	return _expect(false,"bounded120 process observations release every native descendant: "+label)

func _close(_held: bool = false) -> void:
	_hc_quiet = false
	for ref: WeakRef in _hc_hosts:
		var host: Node = ref.get_ref() as Node
		if is_instance_valid(host): await _hc_retire(host,"comparison/transport final cleanup")
	_hc_hosts.clear()
	_hc_detach_callbacks()
	_game = null; _hc_shell = null; _level = null; _hero = null; _scheduler = null; _core = null; _hc_helper = null; _tether = null; _hc_barrier = null; _mechanisms.clear()
	paused = false
	for _frame: int in range(3): await process_frame
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(),"no old actor/required cue group residue after normal whole-unit cleanup")
	if not _hc_store_root.is_empty():
		_hc_cleanup_store(_hc_store_root); _hc_store_root = ""

func _hc_cleanup_store(path: String) -> void:
	if _hc_store_root.is_empty() or not path.begins_with(_hc_store_root) or not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)): return
	for child: String in DirAccess.get_directories_at(path): _hc_cleanup_store(path.path_join(child))
	for filename: String in DirAccess.get_files_at(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path.path_join(filename)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _finish() -> void:
	if _hc_finishing: return
	_hc_finishing = true; _hc_done = true
	if is_instance_valid(_hc_barrier): _hc_barrier._wake()
	await _close()
	if node_added.is_connected(_hc_watch_node): node_added.disconnect(_hc_watch_node)
	_expect(_hc_registry_text.is_empty() or FileAccess.get_file_as_string(HC_Registry.DATA_PATH) == _hc_registry_text,"canonical registry remains byte-identical")
	if not _hc_results.is_empty():
		var directory: String = "res://captures/act3/garden-helper-choice/results-%d-%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
		if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) == OK:
			var output: FileAccess = FileAccess.open(directory+"native-results.var.bin",FileAccess.WRITE)
			if output != null: output.store_buffer(var_to_bytes(_hc_results)); output.close()
			output = FileAccess.open(directory+"native-results.txt",FileAccess.WRITE)
			if output != null: output.store_string(str(_hc_results)); output.close()
			print("Garden helper choice: literal native case result directory=",directory)
	print("Garden helper choice: %d checks; failures: %d; selector=%s; observed native ticks=%d; cases=%d; authentic archives=%s. TEST declared Challenge root/helper choice only; no canonical MAIN checkpoint5, late parent history, fullroute/allkit/portrait/difficulty increase claim." % [_checks,_failures,_hc_selector,_hc_native_ticks,_hc_results.size(),str(_hc_archives)])
	quit(0 if _failures == 0 else 1)
