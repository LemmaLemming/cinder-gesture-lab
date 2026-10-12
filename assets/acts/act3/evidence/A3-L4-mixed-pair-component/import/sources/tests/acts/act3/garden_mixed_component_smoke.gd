extends "res://tests/acts/act3/garden_network_pair_smoke.gd"
## IGNORED TEST driver; publish only with its two declared component fixtures.
## Reuses engine-routed gestures/full dashes, not native OS input or a route clear.
## TEST registry/predecessor metadata surround actual native snapshots.
## No private HP/pose/clock/camera writes, weakened proof, disk/GUI campaign claim.

const ProductionShell = preload("res://scripts/campaign/shell.gd")
const CampaignRegistry = preload("res://scripts/campaign/registry.gd")
const ComponentModel = preload("res://scripts/acts/act3/false_paradise_codec.gd")
const MIXED_RUNTIME: String = "res://tests/acts/act3/fixtures/garden_mixed_component.gd"
const ROOT_CELL: String = "res://tests/acts/act3/fixtures/garden_mixed_component.tscn"
const ECHO_CELL: String = "res://tests/acts/act3/fixtures/garden_mixed_echo_component.tscn"
const MIXED_LIMIT_S: float = 55.0

class MixedBarrier extends Node:
	signal observed
	var waiting: bool = false
	var expired: bool = false
	var frames: int = 0
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 1000
	func _physics_process(_delta: float) -> void:
		if waiting and not get_tree().paused: _wake()
	func _process(_delta: float) -> void:
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

var _production: CinderCampaignShell
var _mixed_barrier: MixedBarrier
var _echo: Node3D
var _helper_dead_branch: bool = false
var _pair_only: bool = false
var _cell_path: String = ""
var _canonical_registry: String = ""
var _isolated_root: String = ""
var _test_registry: Dictionary = {}
var _initial_checkpoint: Dictionary = {}
var _quiet_watch: bool = false
var _quiet_events: Array[String] = []
var _seen_nodes: Dictionary = {}
var _arm_abort: bool = false
var _abort_armed: int = 0
var _abort_candidates: Dictionary = {}
var _abort_refs: Array[WeakRef] = []
var _abort_cancellations: Array[Dictionary] = []
var _abort_exits: Array[Dictionary] = []
var _abort_expected: Dictionary = {}
var _abort_expected_ids: Array[String] = []
var _watch_enclose: bool = false
var _enclose_geometry: Dictionary = {}
var _enclose_id: String = ""
var _enclose_sun: int = 0
var _flip_seen: bool = false
var _native_ticks: int = 0
var _negative_native_events: Array[String] = []


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_helper_dead_branch = args.size() == 1 and args[0] == "--helper-dead"
	_pair_only = args.size() == 1 and args[0] == "--pair-only"
	if not _expect(args.is_empty() or _helper_dead_branch or _pair_only, "only default living retirement, --helper-dead or --pair-only is declared", str(args)):
		await _finish()
		return
	_canonical_registry = FileAccess.get_file_as_string(CampaignRegistry.DATA_PATH)
	if not node_added.is_connected(_watch_mixed_node): node_added.connect(_watch_mixed_node)
	if await _open_cell(ROOT_CELL):
		if _pair_only:
			var held: Dictionary = await _admit("draw", Vector3.LEFT)
			if not held.is_empty(): await _roundtrip_and_abort("held-Draw-Scheduler3", true)
		else:
			await _root_component()
	await _close()
	if not _pair_only and _failures == 0 and await _open_cell(ECHO_CELL):
		await _echo_component()
	await _finish()


func _open_cell(path: String) -> bool:
	_cell_path = path
	_events.clear()
	_game = MainScene.instantiate()
	root.add_child(_game)
	_game.call("open_bench")
	if not _expect(paused and _game.call("load_level_scene", path), "public Main loads the declared native TEST cell", path): return false
	_game.call("open_bench")
	if not _bind_mixed(): return false
	for _i: int in range(4): await process_frame
	var camera: Camera3D = _game.get("camera") as Camera3D
	var hud: GameHUD = _game.get("hud") as GameHUD
	var input: Dictionary = _game.call("get_input_observation_state")
	if not _expect(_hero.get_world_action_clock() == 0.0 and _scheduler.get_clock() == 0.0 and _hero.get_world_action_records().is_empty() and input.sequence == 0 and input.last_observation.is_empty() and _game.call("get_aim_anchor_normalized") == Vector2(0.5, 0.5), "declared initial seed observes real clock0/no input or action history"): return false
	hud.update_status(_hero.hp, _hero.max_hp, _hero.shells, _hero.max_shells, 0, _level.objective_text)
	var actor: Dictionary = _hero.snapshot_state()
	var level: Dictionary = _level.snapshot_state_for_presentation(camera, hud)
	if not _expect(not actor.is_empty() and not level.is_empty() and _level.snapshot_error_with_player(level, actor).is_empty(), "clock0 native component pair includes its actual Camera/HUD", _level.last_snapshot_error): return false
	var seed: Dictionary = {"schema_version": 1, "level_id": "A3-L4", "scene_path": path, "paused": true, "equipment_ids": _kit.duplicate(true), "player": actor, "level": level, "shell": {"api_revision": ProductionShell.SHELL_API, "anchor_normalized": [0.5, 0.5], "input_sequence": 0, "last_input_observation": {}, "camera_focus": PairCodec.vector3(camera.global_position - Vector3(0, 18, 13)), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}}
	var raw: Variant = JSON.parse_string(_canonical_registry)
	if not _expect(raw is Dictionary, "canonical registry is readable without writes"): return false
	var replaced: bool = false
	for row: Dictionary in raw.levels:
		if row.id == "A3-L4":
			row.scene_path = path
			row.readiness = "accepted" # TEST ONLY metadata, never canonical evidence.
			row.accepted_commit = "a".repeat(40)
			row.api_revision = CampaignRegistry.API_REVISION
			replaced = true
	if not _expect(replaced, "one in-memory TEST registry row declares only this component cell"): return false
	_test_registry = raw.duplicate(true)
	_initial_checkpoint = seed.duplicate(true)
	await _close()
	_isolated_root = "user://test-garden-mixed-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	_production = ProductionShell.new()
	_game = _production
	if not _expect(_production.configure_runtime(raw, _isolated_root + "campaign.json", _isolated_root + "settings.json", _isolated_root + "preferences.json"), "actual ProductionShell uses its public registry and isolated SaveStore", _production.campaign_error): return false
	root.add_child(_production)
	for _i: int in range(4): await process_frame
	var prefix: Array[String] = []
	prefix.assign(_production.registry.main_route().slice(0, 13))
	if not _expect(paused and prefix.size() == 13 and prefix.back() == "A3-L3" and _production.registry.scene_error("A3-L4").is_empty(), "TEST predecessor metadata enables the declared component identity"): return false
	var session: Dictionary = _production.attempts.state()
	session.completed_main = prefix
	session.story = {"kind": "story", "level_id": "A3-L4", "snapshot": seed.duplicate(true), "checkpoint": seed.duplicate(true)}
	_quiet_events.clear()
	_quiet_watch = true
	var error: String = _production.attempts.state_error(session)
	if not _expect(error.is_empty() and _production.attempts.restore_session(session), "public TEST session seed preserves the actual clock0 pair", error): return false
	_production.menu.continue_story_requested.emit()
	if not await _settle_success("resume"): return false
	_quiet_watch = false
	if not _bind_mixed(): return false
	return _expect(_quiet_events.is_empty() and _wire_exact(_production.capture_campaign_snapshot(), seed), "fresh quiet Shell receiver retains exact clock0 mechanics and native optics", str(_quiet_events))


func _bind_mixed() -> bool:
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _expect(is_instance_valid(_level) and is_instance_valid(_hero) and _level.scene_file_path == _cell_path and _level.get_script().resource_path == MIXED_RUNTIME and _level.level_id == "A3-L4" and _level.local_snapshot_version == 1, "actual declared component/shared Player identity"): return false
	_core = _level.get("root_network") as Node3D
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	_echo = _level.get("echo") as Node3D
	if not _expect(is_instance_valid(_core) and is_instance_valid(_scheduler) and is_instance_valid(_echo) and String(_level.call("runtime_error")).is_empty(), "actual native Core/Scheduler/managed Echo configure", String(_level.call("runtime_error"))): return false
	_tether = _core.call("get_tether") as StaticBody3D
	_mechanisms = _core.call("get_mechanisms")
	_kit = _hero.equipment.snapshot()
	_hero_hp = _hero.hp
	_fixed_target = _tether.global_transform
	_fixed_sources.clear()
	for kind: String in ["draw", "enclose"]: _fixed_sources[kind] = _source(kind).global_transform
	if is_instance_valid(_mixed_barrier): _mixed_barrier.queue_free()
	_mixed_barrier = MixedBarrier.new()
	_game.add_child(_mixed_barrier)
	_hero.fired.connect(func(kind: String) -> void: _events.append("fired_" + kind))
	_hero.died.connect(func() -> void: _events.append("hero_death"))
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _events.append("completion"))
	_level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: _events.append("checkpoint"))
	_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _events.append("exit"))
	return _expect(_hero.stats.primary_damage == 20.0 and _hero.presentation_id == "act3_traveller" and _scheduler.encounter_profile().get("id") == "standard", "unchanged starter primary and Standard traveller; no fixture resource writes")


func _root_component() -> void:
	var first: Dictionary = await _admit("draw", Vector3.LEFT)
	if first.is_empty() or not await _roundtrip_and_abort("held-Draw", true): return
	_game.call("resume_lab")
	if not await _earned_return(first, "draw") or not _ordinary_hit(60.0, 40.0, 1): return
	var first_ms: int = Time.get_ticks_msec()
	var exchange: Dictionary = _retained_exchange("draw")
	if not await _second_primary_ready(first_ms, float(exchange.recovery_until_s)) or not _ordinary_hit(40.0, 30.0, 2): return
	var helper: Node3D = _level.get("helper") as Node3D
	var state: Dictionary = _level.call("component_state")
	if not _expect(is_instance_valid(helper) and helper.get("hp") == helper.get("max_hp") and not helper.get("dead") and state.sun.started and state.sun.anchor_s == _scheduler.get_clock(), "real60→40→30 crossing alone creates one original living helper and sun anchor"): return
	if _helper_dead_branch:
		if not await _slay_helper() or not await _approach_core_with_dash(): return
	var anchor: float = float((_level.call("component_state") as Dictionary).sun.anchor_s)
	var now: float = _scheduler.get_clock()
	var flip: float = anchor + 4.0
	while flip - 3.65 <= now: flip += 14.0
	if not await _until(flip - 3.65): return
	var second: Dictionary = await _admit("enclose", Vector3.BACK)
	if second.is_empty(): return
	var held: Dictionary = _source("enclose").state()
	_enclose_geometry = held.geometry.duplicate(true)
	_enclose_id = String(held.reservation_id)
	_enclose_sun = int((_level.call("component_state") as Dictionary).sun.effective_index)
	_flip_seen = false
	_watch_enclose = true
	if not await _roundtrip_and_abort("held-phase2-Enclose", true): return
	_game.call("resume_lab")
	if not await _earned_return(second, "enclose"): return
	if _scheduler.get_clock() < flip and not await _until(flip): return
	if not _expect(_flip_seen and _source("enclose").state().geometry == _enclose_geometry and _source("enclose").state().reservation_id == _enclose_id and _source("enclose").state().phase == "recovery", "real familiar sun flip cannot retarget the held Enclose lease/geometry"): return
	if not _ordinary_hit(30.0, 10.0, 2): return
	first_ms = Time.get_ticks_msec()
	exchange = _retained_exchange("enclose")
	if not await _second_primary_ready(first_ms, float(exchange.recovery_until_s)): return
	_watch_enclose = false
	if not _ordinary_hit(10.0, 0.0, 3): return
	# The actual primary runs after the driver's post-actor barrier. Pause at
	# this real deferred boundary BEFORE another component tick settles release.
	if not await _completed_pause(): return
	state = _level.call("component_state")
	if not _expect(state.pending_release and not state.released and _tether.get("hp") == 0.0 and _tether.get("phase") == 3, "actual final primary retains genuine pending helper release at the completed pause", str(state)): return
	if not await _roundtrip_and_abort("genuine-pending-release", false): return
	_game.call("resume_lab")
	for _i: int in range(3):
		if not await _tick(): return
	state = _level.call("component_state")
	helper = _level.get("helper") as Node3D
	var mechanism: CinderLaneMechanism = helper.call("get_mechanism")
	var body: CollisionShape3D = helper.get_node("BodyCollision") as CollisionShape3D
	var outcome: bool = helper.get("dead") and helper.get("hp") == 0.0 and not state.helper_death.is_empty() and state.helper_retired.is_empty() and mechanism.state().last_cancel_reason == "source_defeated" if _helper_dead_branch else not helper.get("dead") and helper.get("hp") > 0.0 and not state.helper_retired.is_empty() and state.helper_death.is_empty() and not body.disabled and helper.is_in_group("enemies") and mechanism.state().last_cancel_reason == "test_garden_released"
	if not _expect(state.released and not state.pending_release and outcome and _scheduler.reservations().is_empty() and _tether.get("hp") == 0.0 and _tether.get("phase") == 3, "actual final0 releases the component with its genuine " + ("helper death" if _helper_dead_branch else "living helper retirement"), str(state)): return
	await _roundtrip_and_abort("settled-native-release", false)


func _slay_helper() -> bool:
	var helper: Node3D = _level.get("helper") as Node3D
	for _i: int in range(300):
		var mechanism: CinderLaneMechanism = helper.call("get_mechanism")
		var current: Dictionary = mechanism.state()
		if current.status == "running" and current.phase == "warning":
			var proof: Dictionary = helper.call("state").get("proof", {})
			if not await _follow_native_proof(proof): return false
			return _primary_at(helper, 20.0, 0.0, "actual helper recovery primary earns original20→0") and _expect(_tether.get("hp") == 30.0 and helper.get("dead"), "helper removal cannot reset or replace the real30HP core")
		if not await _tick(): return false
	return _expect(false, "finite real helper admission is available", str(helper.call("state")))


func _approach_core_with_dash() -> bool:
	var toward: Vector3 = _tether.global_position - _hero.global_position
	toward.y = 0.0
	if toward.length() <= float(_hero.stats.primary_range) - 0.3: return true
	for _i: int in range(90):
		if _hero.get_threat_response_state().stable: break
		if not await _tick(): return false
	var error: String = _swipe(toward.normalized())
	if not _expect(error.is_empty(), "real full swipe approaches the fixed core after helper defeat", error): return false
	for _i: int in range(60):
		if _hero.get_threat_response_state().motion.dash_left_s == 0.0:
			var action: Dictionary = _hero.get_world_action_records().back()
			var offset: Vector3 = _tether.global_position - _hero.global_position
			offset.y = 0.0
			return _expect(action.kind == "dash" and not action.collision_shortened and not action.movement_damage and absf(float(action.distance) - float(_hero.stats.dash_distance)) < 0.005 and offset.length() <= float(_hero.stats.primary_range) - 0.3, "actual canonical approach dash ends within ordinary reach; no pose write or fabricated combat proof", str(action))
		if not await _tick(): return false
	return _expect(false, "finite complete ordinary approach is supported")


func _echo_component() -> void:
	_game.call("resume_lab")
	var answer: Dictionary = await _admit_echo()
	if answer.is_empty() or not await _roundtrip_and_abort("held-own-Echo", true): return
	_game.call("resume_lab")
	var committed: Dictionary = await _locked_echo_proof(String(answer.reservation_id))
	if committed.is_empty() or not await _follow_native_proof(committed) or not _primary_at(_echo, 36.0, 16.0, "ordinary real TEST own-Echo primary earns36→16"): return
	for _i: int in range(600):
		if not (_echo.call("get_authored_cycle_terminal_receipt") as Dictionary).is_empty() and _level.call("prepare_next_echo_cycle"): break
		if not await _tick(): return
	if not _expect(_echo.call("get_authored_cycle_generation") == 2 and _echo.get("hp") == 16.0 and _echo.call("source_phase") == "cycle_ready", "genuine terminal/cooldown prepares generation2 with the same16HP owner"): return
	if not await _roundtrip_and_abort("managed-ready-generation2", false): return
	_game.call("resume_lab")
	answer = await _admit_echo()
	if answer.is_empty(): return
	committed = await _locked_echo_proof(String(answer.reservation_id))
	if committed.is_empty() or not await _follow_native_proof(committed) or not _primary_at(_echo, 16.0, 0.0, "genuine next-cycle primary defeats the remaining16HP Echo"): return
	for _i: int in range(3):
		if not await _tick(): return
	var state: Dictionary = _level.call("component_state")
	if not _expect(_echo.get("dead") and not (_echo.call("get_authored_cycle_terminal_receipt") as Dictionary).is_empty() and _tether.get("hp") == 60.0 and _tether.get("phase") == 1 and not is_instance_valid(_level.get("helper")) and not state.sun.started and not state.released, "separate Echo cell retains original idle core/no helper/no invented garden boundary"): return
	await _roundtrip_and_abort("native-Echo-terminal", false)


func _admit(kind: String, direction: Vector3) -> Dictionary:
	_active_kind = kind
	if paused: _game.call("resume_lab")
	var last: Dictionary = {}
	for _i: int in range(180):
		if _hero.get_threat_response_state().stable:
			last = _level.call("try_core", kind, direction)
			if last.get("accepted", false): return last
		if not await _tick(): return {}
	_expect(false, "finite authored native " + kind + " proof/admission; no fallback or timing relaxation", str(last))
	return {}


func _admit_echo() -> Dictionary:
	var last: Dictionary = {}
	for _i: int in range(180):
		if _hero.get_threat_response_state().stable:
			last = _level.call("admit_echo")
			if last.get("accepted", false): return last
		if not await _tick(): return {}
	_expect(false, "finite declared TEST own-Echo native witness/admission", str(last))
	return {}


func _locked_echo_proof(reservation_id: String) -> Dictionary:
	var initial: Dictionary = _level.call("component_state")
	var original: Dictionary = initial.echo_lease
	if not _expect(original.get("id") == reservation_id and original.get("lock_from_s") is float, "real initial Echo lease supplies its unchanged native lock deadline"): return {}
	var due: float = float(original.lock_from_s)
	for _i: int in range(240):
		var state: Dictionary = _level.call("component_state")
		var lease: Dictionary = state.echo_lease
		if lease.get("id") != reservation_id:
			_expect(false, "same actual Echo reservation survives until observer85 commitment", str(state))
			return {}
		if lease.get("adapter", {}).get("locked", false):
			var proof: Dictionary = state.echo_proof
			if not _expect(_scheduler.get_clock() >= due and _scheduler.get_clock() <= due + 1.0 / float(Engine.physics_ticks_per_second) + 0.000000001 and proof.get("accepted", false), "first actual due post-actor tick retains observer85's committed Echo proof/deadlines", str(state)): return {}
			return proof.duplicate(true)
		if not await _tick(): return {}
	_expect(false, "finite native Echo lock commitment supplies the actual usable proof")
	return {}


func _follow_native_proof(proof: Dictionary) -> bool:
	if not _expect(proof.get("accepted", false) and proof.get("path") is Array and not proof.get("uses_blast", true) and not proof.get("uses_invulnerability", true), "actual native ordinary proof supplies the route", str(proof)): return false
	var dashes: int = 0
	for segment: Dictionary in proof.path:
		if segment.kind not in ["escape_dash", "positioning_dash"]: continue
		if not await _until(float(segment.start_s)): return false
		var error: String = _swipe((segment.to - segment.from).normalized())
		if not _expect(error.is_empty(), "engine-routed actual proved dash", error) or not await _complete_dash(segment): return false
		dashes += 1
	if not await _until(float(proof.primary_time_s)): return false
	return _expect(dashes > 0 and _hero.global_position.distance_to(proof.attack_position) < 0.02 and _hero.hp == _hero_hp and _hero.get_threat_response_state().primary_cooldown_left_s == 0.0, "actual full ordinary route reaches its native attack opportunity")


func _primary_at(owner: Node3D, before_hp: float, after_hp: float, label: String) -> bool:
	var direction: Vector3 = owner.global_position - _hero.global_position
	direction.y = 0.0
	var count: int = _hero.get_world_action_records().size()
	var actual_before: float = float(owner.get("hp"))
	var error: String = _tap(direction.normalized())
	var actions: Array[Dictionary] = _hero.get_world_action_records()
	return _expect(error.is_empty() and actual_before == before_hp and owner.get("hp") == after_hp and actions.size() == count + 1 and actions.back().kind == "primary" and actions.back().hits == 1 and _hero.hp == _hero_hp and not _events.has("fired_blast"), label, error + "; " + str(owner.call("state")))


func _roundtrip_and_abort(label: String, abort: bool) -> bool:
	# Public Pause performs the native Save operation and retains the original
	# protected clock0 checkpoint; no synthetic late checkpoint is introduced.
	_production.request_pause()
	if not await _settle_success("pause"): return false
	var saved: Dictionary = _production.capture_campaign_snapshot()
	if not _expect(not saved.is_empty() and _level.snapshot_error_with_player(saved.level, saved.player).is_empty(), "actual paused whole component capture: " + label, _production.campaign_error + "; " + _level.last_snapshot_error): return false
	var decoded: Dictionary = PairExact.parse(PairExact.stringify(saved))
	if not _expect(decoded.get("accepted", false) and _wire_exact(decoded.value, saved), "exact JSON preserves the complete native component wire: " + label): return false
	if not _atomic_copy_negatives(saved): return false
	var session: Dictionary = _production.attempts.state()
	if not _expect(_wire_exact(session.story.snapshot, saved) and _wire_exact(session.story.checkpoint, _initial_checkpoint), "public Pause saves the real held pair while preserving its original clock0 checkpoint"): return false
	var donor_shell: CinderCampaignShell = _production
	var donor_host: Node = _game
	var donor_level: CinderLevel = _level
	var old_ids: Dictionary = _native_ids_mixed()
	var donor: Dictionary = _donor_observation()
	var refs: Array[WeakRef] = []
	_weakrefs(donor_host, refs)
	_quiet_events.clear()
	_quiet_watch = true
	_production = ProductionShell.new()
	if not _expect(_production.configure_runtime(_test_registry, _isolated_root + "campaign.json", _isolated_root + "settings.json", _isolated_root + "preferences.json"), "fresh Shell reads the same isolated actual SaveStore"): return false
	root.add_child(_production)
	for _i: int in range(4): await process_frame
	if not _expect(paused and _production.campaign_error.is_empty() and _production.menu.page_name() == "title" and _wire_exact(_production.attempts.state(), session), "fresh native title loads the exact saved component attempt", _production.campaign_error): return false
	if abort:
		_abort_expected = saved.duplicate(true)
		_abort_expected_ids.clear()
		for reservation: Dictionary in saved.level.local.scheduler.reservations: _abort_expected_ids.append(String(reservation.id))
		if not _expect(not _abort_expected_ids.is_empty(), "staged abort has genuine held Scheduler leases: " + label): return false
		_abort_refs.clear()
		_abort_candidates.clear()
		_abort_cancellations.clear()
		_abort_exits.clear()
		_abort_armed = 0
		_arm_abort = true
		_production.menu.continue_story_requested.emit()
		for _i: int in range(60):
			await process_frame
			if not _production.campaign_error.is_empty(): break
		_arm_abort = false
		if not _expect(_abort_armed == 1 and _production.campaign_error.contains("commit hook failed") and not is_instance_valid(_production.active_level) and _wire_exact(donor_shell.capture_campaign_snapshot(), saved) and donor == _donor_observation() and _native_ids_mixed() == old_ids, "real fresh Continue abort after Scheduler preserves the paused donor mechanics/input/camera: " + label, _production.campaign_error): return false
		for _i: int in range(8): await process_frame
		var freed: bool = true
		for ref: WeakRef in _abort_refs: freed = freed and ref.get_ref() == null
		var cancelled: Array[String] = []
		for event: Dictionary in _abort_cancellations:
			if event.clock_s == saved.level.local.scheduler.clock_s and event.reason == "test_mixed_unfinished_exit": cancelled.append(event.id)
		var all_cancelled: bool = true
		for id: String in _abort_expected_ids: all_cancelled = all_cancelled and cancelled.has(id)
		var exited: bool = false
		for event: Dictionary in _abort_exits: exited = exited or event.empty
		if not _expect(freed and all_cancelled and exited, "actual committed Scheduler leases cancel without clock advance and discarded native recipients release: " + label, str(_abort_cancellations) + "; " + str(_abort_exits)): return false
		_quiet_events.clear() # Disclosed expected abort cleanup; success is checked separately.
		_production.retry_pending_operations()
	else:
		_production.menu.continue_story_requested.emit()
	if not await _settle_success("resume"): return false
	if not _expect(donor == _donor_observation() and _wire_exact(donor_shell.capture_campaign_snapshot(), saved), "successful independent fresh construction also leaves the paused donor unchanged"): return false
	_quiet_watch = false
	_game = _production
	if not _bind_mixed(): return false
	var fresh: bool = _native_ids_mixed().hero != old_ids.hero and _native_ids_mixed().level != old_ids.level and _native_ids_mixed().scheduler != old_ids.scheduler and _native_ids_mixed().core != old_ids.core and _native_ids_mixed().echo != old_ids.echo
	var native: Dictionary = _production.capture_campaign_snapshot()
	donor_level.exit_level()
	if donor_host.get_parent() == root: root.remove_child(donor_host)
	donor_host.queue_free()
	for _i: int in range(6): await process_frame
	var released: bool = true
	for ref: WeakRef in refs: released = released and ref.get_ref() == null
	return _expect(fresh and released and _quiet_events.is_empty() and _wire_exact(native, saved) and _wire_exact(_production.capture_campaign_snapshot(), saved) and not _level.is_restore_candidate(), "public fresh Continue passes actual native Camera/HUD, exact recapture and donor cleanup: " + label, str(_quiet_events) + "; " + _production.campaign_error)


func _atomic_copy_negatives(saved: Dictionary) -> bool:
	if not _expect(paused, "three copy-only component negatives use the completed paused barrier"): return false
	var signals: Array[Dictionary] = []
	for node: Node in [_hero, _scheduler, _core, _tether, _echo, _source("draw"), _source("enclose"), _source("draw").get_cue(), _source("enclose").get_cue(), _level.get("helper")]:
		if not is_instance_valid(node): continue
		for label: String in ["world_action_executed", "fired", "died", "reservation_invalidated", "phase_boundary", "state_changed", "source_hit_resolved", "source_defeated", "event_dispatched", "hit_resolved"]:
			if not node.has_signal(label): continue
			var observer: Callable = _note_negative_native_event
			if not node.is_connected(label, observer):
				node.connect(label, observer)
				signals.append({"node": node, "signal": label, "observer": observer})
	_negative_native_events.clear()
	var bad: Dictionary = saved.duplicate(true)
	bad.level.local.scheduler.clock_s = float(bad.level.local.scheduler.clock_s) + 0.00000001
	var ok: bool = _atomic_copy_rejection(saved, bad, "outer Scheduler clock drift with unchanged Hero")
	if ok:
		bad = saved.duplicate(true)
		var anchor: Variant = bad.level.local.sun.anchor_s
		bad.level.local.sun.anchor_s = 0.0 if anchor == null else float(anchor) + 0.00000001
		ok = _atomic_copy_rejection(saved, bad, "forged sun anchor with unchanged genuine Core boundary")
	if ok:
		bad = saved.duplicate(true)
		if not _expect(bad.level.local.scheduler.authored_source_cycles.sources.size() > 0, "actual managed component journal supplies a first source entry"):
			ok = false
		else:
			bad.level.local.scheduler.authored_source_cycles.sources[0] = 42
			ok = _atomic_copy_rejection(saved, bad, "scalar first authored-source journal entry")
	for receipt: Dictionary in signals:
		if is_instance_valid(receipt.node) and receipt.node.is_connected(receipt.signal, receipt.observer): receipt.node.disconnect(receipt.signal, receipt.observer)
	return ok


func _note_negative_native_event(_a: Variant = null, _b: Variant = null, _c: Variant = null) -> void:
	_negative_native_events.append("native_signal")


func _atomic_copy_rejection(saved: Dictionary, bad: Dictionary, label: String) -> bool:
	var input_wire: String = PairExact.stringify(bad)
	var events: Array[String] = _events.duplicate()
	var native_events: Array[String] = _negative_native_events.duplicate()
	var error: Variant = _level.snapshot_error_with_player(bad.level, bad.player)
	return _expect(error is String and not error.is_empty() and not input_wire.is_empty() and PairExact.stringify(bad) == input_wire and _wire_exact(_production.capture_campaign_snapshot(), saved) and _events == events and _negative_native_events == native_events, "paused pure validation rejects atomically: " + label, str(error))


func _completed_pause() -> bool:
	if not paused and not _production.request_pause_deferred(): return _expect(false, "public Shell completed pause request")
	for _i: int in range(6): await process_frame
	return _expect(paused and not _production.is_pause_requested(), "actual completed paused post-consumer boundary")


func _settle_success(page: String) -> bool:
	for _i: int in range(60):
		await process_frame
		if not _production.campaign_error.is_empty(): return _expect(false, "actual Shell fresh component operation", _production.campaign_error)
		if paused and not _production.is_pause_requested() and _production.menu.page_name() == page and is_instance_valid(_production.active_level): return true
	return _expect(false, "finite actual Shell settles to " + page)


func _tick() -> bool:
	if paused or not is_instance_valid(_mixed_barrier): return _expect(false, "actual unpaused component tick requires its native barrier")
	_mixed_barrier.expired = false
	_mixed_barrier.frames = 0
	_mixed_barrier.waiting = true
	await _mixed_barrier.observed
	var error: String = String(_level.call("runtime_error"))
	var fixed: bool = _tether.global_transform == _fixed_target
	for kind: String in ["draw", "enclose"]: fixed = fixed and _source(kind).global_transform == _fixed_sources[kind]
	if _watch_enclose:
		var current: Dictionary = _source("enclose").state()
		fixed = fixed and current.status == "running" and current.reservation_id == _enclose_id and current.geometry == _enclose_geometry
		if int((_level.call("component_state") as Dictionary).sun.effective_index) != _enclose_sun: _flip_seen = true
	_native_ticks += 1
	var ok: bool = not _mixed_barrier.expired and not paused and error.is_empty() and fixed and not _hero.dead and _hero.hp == _hero_hp and _hero.equipment.snapshot() == _kit and not _events.has("fired_blast") and not _events.has("completion") and not _events.has("checkpoint") and not _events.has("exit") and _scheduler.get_clock() <= MIXED_LIMIT_S
	return true if ok else _expect(false, "bounded post-actor tick preserves actual ordinary controls/fixed sources/HP and TEST scope", error)


func _until(target: float) -> bool:
	if target > MIXED_LIMIT_S: return _expect(false, "declared native deadline fits the component clock bound", str(target))
	for _i: int in range(3600):
		if _scheduler.get_clock() >= target:
			return _expect(_scheduler.get_clock() <= target + 1.0 / float(Engine.physics_ticks_per_second) + 0.000000001, "first actual post-actor tick reaches the unchanged native deadline", str(target))
		if not await _tick(): return false
	return _expect(false, "finite native component deadline is reachable", str(target))


func _native_ids_mixed() -> Dictionary:
	return {"hero": _hero.get_instance_id(), "level": _level.get_instance_id(), "scheduler": _scheduler.get_instance_id(), "core": _core.get_instance_id(), "echo": _echo.get_instance_id(), "camera": (_game.get("camera") as Camera3D).get_instance_id()}


func _donor_observation() -> Dictionary:
	return {"actor": _hero.snapshot_state(), "component": _level.call("component_state"), "scheduler": _scheduler.snapshot_state(_level.call("scheduler_bindings")), "core": _core.call("capture", _level.call("scheduler_bindings"), _scheduler.snapshot_state(_level.call("scheduler_bindings"))), "camera": (_game.get("camera") as Camera3D).global_transform, "input": _game.call("get_input_observation_state"), "events": _events.duplicate()}


func _watch_mixed_node(node: Node) -> void:
	if not _quiet_watch or not is_instance_valid(_production) or not _production.is_ancestor_of(node) or _seen_nodes.has(node.get_instance_id()): return
	_seen_nodes[node.get_instance_id()] = true
	# Level.ready can precede Shell's actual Hero/FX additions. Retain each
	# later native candidate descendant as well, without changing its binding.
	if _arm_abort:
		_abort_refs.append(weakref(node))
		if node.is_node_ready(): _weakrefs(node, _abort_refs)
		else: node.ready.connect(func() -> void: _weakrefs(node, _abort_refs), CONNECT_ONE_SHOT)
	if node is CinderLevel and node.get_script() != null and node.get_script().resource_path == MIXED_RUNTIME:
		if node.is_node_ready(): _on_mixed_ready(node)
		else: node.ready.connect(_on_mixed_ready.bind(node), CONNECT_ONE_SHOT)
	if node is CinderPlayer:
		node.fired.connect(func(_kind: String) -> void: _quiet_note(node, "receiver_fire"))
		node.world_action_executed.connect(func(_action: Dictionary) -> void: _quiet_note(node, "receiver_action"))
		node.died.connect(func() -> void: _quiet_note(node, "receiver_hero_death"))
	if node is CinderThreatCue: node.state_changed.connect(func(_state: Dictionary) -> void: _quiet_note(node, "receiver_cue"))
	if node is CinderLaneMechanism:
		node.hit_resolved.connect(func(_id: String, _cycle: int, _result: Dictionary) -> void: _quiet_note(node, "receiver_hit"))
	if node is CinderAct3RootLatcher: node.state_changed.connect(func(_state: Dictionary) -> void: _quiet_note(node, "receiver_root_state"))
	if node is CinderAct3MirrorEcho:
		node.source_hit_resolved.connect(func(_result: Dictionary) -> void: _quiet_note(node, "receiver_echo_hit"))
		node.source_defeated.connect(func(_result: Dictionary) -> void: _quiet_note(node, "receiver_echo_death"))
		node.event_dispatched.connect(func(_event: Dictionary, _opportunity: Dictionary) -> void: _quiet_note(node, "receiver_echo_event"))
	if node is CinderLevel:
		node.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: _quiet_note(node, "receiver_checkpoint"))
		node.completion_requested.connect(func(_id: String, _completion: String) -> void: _quiet_note(node, "receiver_completion"))
		node.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _quiet_note(node, "receiver_exit"))


func _quiet_note(node: Node, label: String) -> void:
	if _quiet_watch and is_instance_valid(_production) and _production.is_ancestor_of(node): _quiet_events.append(label)


func _on_mixed_ready(recipient: CinderLevel) -> void:
	if not _arm_abort: return
	if not _expect(recipient.hero == null and paused and recipient.call("arm_test_abort_after_scheduler"), "public abort selector arms only an actual ready unconfigured fresh recipient"): return
	_abort_armed += 1
	_abort_candidates[recipient.get_instance_id()] = true
	_weakrefs(recipient.get_parent().get_parent().get_parent(), _abort_refs)
	var scheduler: CinderThreatScheduler = recipient.get("threat_scheduler") as CinderThreatScheduler
	scheduler.reservation_invalidated.connect(func(id: String, reason: String) -> void:
		_abort_cancellations.append({"id": id, "reason": reason, "clock_s": scheduler.get_clock()})
		# Public non-pruning custody is read while every candidate owner is still
		# in its native tree; never depend on sibling destruction order.
		var empty: bool = true
		for owner: Node3D in (recipient.call("scheduler_bindings") as Dictionary).owners.values():
			var control: Dictionary = scheduler.source_control_state(owner)
			empty = empty and not control.is_empty() and control.reservations.is_empty()
		_abort_exits.append({"empty": empty, "clock_s": scheduler.get_clock()})
	)
	recipient.child_entered_tree.connect(func(child: Node) -> void:
		if child is CinderAct3RootLatcher:
			if child.is_node_ready(): _weakrefs(child, _abort_refs)
			else: child.ready.connect(func() -> void: _weakrefs(child, _abort_refs), CONNECT_ONE_SHOT)
	)


func _close(_held: bool = false) -> void:
	_quiet_watch = false
	_arm_abort = false
	_watch_enclose = false
	if not is_instance_valid(_game): return
	var refs: Array[WeakRef] = []
	_weakrefs(_game, refs)
	if is_instance_valid(_production) and _production != _game:
		_weakrefs(_production, refs)
		if is_instance_valid(_production.active_level): _production.active_level.exit_level()
		if _production.get_parent() == root: root.remove_child(_production)
		_production.queue_free()
	if is_instance_valid(_level): _level.exit_level()
	if _game.get_parent() == root: root.remove_child(_game)
	_game.queue_free()
	paused = false
	for _i: int in range(6): await process_frame
	var released: bool = true
	for ref: WeakRef in refs: released = released and ref.get_ref() == null
	_expect(released and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "actual TEST host/Hero/Core/Echo/helper/cues release without group residue")
	_game = null
	_production = null
	_level = null
	_hero = null
	_scheduler = null
	_core = null
	_echo = null
	_tether = null
	_mixed_barrier = null
	_mechanisms.clear()
	if not _isolated_root.is_empty():
		_cleanup_isolated(_isolated_root)
		_isolated_root = ""


func _cleanup_isolated(path: String) -> void:
	if _isolated_root.is_empty() or not path.begins_with(_isolated_root) or not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)): return
	for directory: String in DirAccess.get_directories_at(path): _cleanup_isolated(path.path_join(directory))
	for filename: String in DirAccess.get_files_at(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path.path_join(filename)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _finish() -> void:
	await _close()
	if node_added.is_connected(_watch_mixed_node): node_added.disconnect(_watch_mixed_node)
	_expect(_canonical_registry.is_empty() or FileAccess.get_file_as_string(CampaignRegistry.DATA_PATH) == _canonical_registry, "canonical registry remains byte-identical")
	print("TEST ONLY garden mixed component: %d checks; %d post-actor ticks; failures: %d. Selector: %s. --pair-only covers one held Draw/Scheduler3 pair, ready Echo, fresh Continue and actual staged discard without combat; default living helper or --helper-dead covers the separate fixed-core and nearby own-Echo cells. Native gestures, public Pause/Save and independent fresh Continue retain the original clock0 checkpoint; no canonical earlier court/full route/production campaign/GUI/mobile acceptance. Unsupported native proof/input/timing remains a finite failure." % [_checks, _native_ticks, _failures, "--pair-only" if _pair_only else "--helper-dead" if _helper_dead_branch else "default"])
	quit(0 if _failures == 0 else 1)
