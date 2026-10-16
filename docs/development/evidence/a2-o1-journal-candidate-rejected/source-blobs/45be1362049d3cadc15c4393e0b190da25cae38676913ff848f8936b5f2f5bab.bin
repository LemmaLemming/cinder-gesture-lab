extends SceneTree
## INERT Root-only comparison draft. No engine run is implied.
## Original old12 quiet restoration precedes a NEW declared TEST pose/view.
## No old saved camera is repaired, no historical packet is rewritten, and
## Main preview checkpoint entitlement is not canonical campaign Save authority.
const O1 = preload("res://scripts/acts/act2/cylinder_perimeter.gd")
const Ray = preload("res://scripts/acts/act2/ray_scout_exchange.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const BodySweep = preload("res://scripts/combat/body_sweep.gd")
const RawPath: String = "res://.cinder/a2-o1-genuine-old-checkpoint-custody-20261016/campaign.json"
const RawSha: String = "7837f021913f3741fdd2048054ff628b5b5a5e990eddc29fc6560bcbb50c5238"
const RuntimeSha: String = "fbdafb33b37adf5da1797bcacbc4a236099af18cf6eee0fd50d3cf69e8cd78d0"
const ScenePath: String = "res://scenes/acts/act2/a2_o1.tscn"
const Start: Vector3 = Vector3(-0.1, 0.0, -6.4)
const GoalZ: float = -8.9
const MaxTicks: int = 600
const Neutral: Dictionary = {"jacket":"CLOTH-J0","pants":"CLOTH-P0","shoes":"CLOTH-S0","weapon":"WEAPON-01"}

class TickProbe extends Node:
	signal observed
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 2000
	func _physics_process(_delta: float) -> void: observed.emit()

class ComponentMain extends "res://scripts/game.gd":
	const StateExact = preload("res://scripts/campaign/exact_json.gd")
	var old_packet: Dictionary = {}
	var old_case: bool = false
	var construction_error: String = ""
	var original_quiet_level: String = ""
	var original_quiet_player: String = ""
	func get_difficulty_preference() -> String: return "challenge"
	func reset_lab() -> void:
		# Only TEST initial construction/profile differs from ordinary Main.
		# All live Ray/Player/camera/HUD/collection guards remain production.
		get_tree().paused = true
		if is_instance_valid(active_level): construction_error = "One component world only"; return
		active_level = (load("res://scenes/acts/act2/a2_o1.tscn") as PackedScene).instantiate() as CinderLevel
		world.add_child(active_level)
		player = PlayerScene.instantiate()
		player.set_presentation("act2_survivor")
		player.fx = fx
		world.add_child(player)
		player.fired.connect(_on_fired) # Same production primary camera response.
		player.died.connect(func() -> void: hud.show_end(false,cores))
		player.equipment_changed.connect(func(id: String) -> void: hud.flash_message("Equipped " + player.equipment.item_name(id)))
		player.global_position = active_level.spawn_position()
		if old_case:
			if not active_level.enter_restore_candidate(player,fx,self,old_packet.level,old_packet.player): construction_error = active_level.last_snapshot_error; return
			if not player.restore_state(old_packet.player) or not active_level.restore_state(old_packet.level): construction_error = active_level.last_snapshot_error; return
			original_quiet_player = StateExact.stringify(player.snapshot_state())
			if original_quiet_player.is_empty() or original_quiet_player != StateExact.stringify(old_packet.player): construction_error = "Original Player mechanical quiet recapture differs"; return
			original_quiet_level = StateExact.stringify(active_level.snapshot_state())
			if original_quiet_level.is_empty() or original_quiet_level != StateExact.stringify(old_packet.level): construction_error = "Original old12 mechanical quiet recapture differs"; return
		else:
			active_level.enter_level(player,fx,self)
		if not String(active_level.get("runtime_error")).is_empty(): construction_error = String(active_level.get("runtime_error")); return
		# Separate NEW component initial state, never an old restored-view pass.
		player.global_position = Vector3(-0.1,0,-6.4)
		player.velocity = Vector3.ZERO
		hud.set_level_preview(true)
		hud.hide_overlay()
		hud.update_status(player.hp,player.max_hp,player.shells,player.max_shells,0,active_level.objective_text)
		_update_camera(0.0,true) # Same production initialization in both branches.
		if old_case:
			construction_error = active_level.restore_candidate_presentation_error(camera,hud)
			if not construction_error.is_empty(): return
			if not active_level.finish_restore_candidate(): construction_error = "Quiet old component did not finish"; return
		bench.visible = false

var report_path: String = ""
var rows: Array[Dictionary] = []
var first_failure: Dictionary = {}
var failures: int = 0
var complete: bool = false
var finished: bool = false
var game: ComponentMain
var probe: TickProbe
var driver: Node
var scheduler: Node
var samples: Array[Dictionary] = []
var states: Array[Dictionary] = []
var hits: Array[Dictionary] = []
var actions: Array[Dictionary] = []
var held: Dictionary = {}
var phases: Dictionary = {}
var first_refusal: Dictionary = {}
var cases: Array[Dictionary] = []
var sampling: bool = false
var ticks: int = 0
var old_audio: AudioBusLayout
var old_fps: int = 0
var last_position: Vector3
var last_clock: float = 0.0
var checkpoint_contact: Dictionary = {}
var case_notes: Dictionary = {}
var decision: String = "UNEXECUTED"

func _initialize() -> void:
	old_audio = AudioServer.generate_bus_layout()
	old_fps = Engine.max_fps
	_run.call_deferred()

func _run() -> void:
	create_timer(150.0,true).timeout.connect(func() -> void:
		if not finished: _expect(false,"finite comparison watchdog"); _finish.call_deferred())
	root.size = Vector2i(540,1170)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	report_path = OS.get_environment("CINDER_A2_O1_GOAL_DECISION_REPORT")
	if not _expect(OS.get_cmdline_user_args().is_empty() and report_path.is_absolute_path() and not FileAccess.file_exists(report_path),"one neutral comparison/fresh absolute report"): await _finish(); return
	if not _expect(FileAccess.get_sha256(RawPath) == RawSha and FileAccess.get_sha256("res://scripts/acts/act2/cylinder_perimeter.gd") == RuntimeSha,"exact original input/current selected runtime pins"): await _finish(); return
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RawPath))
	var parsed: Dictionary = Exact.parse(raw.payload_json)
	if not _expect(raw.format_version == 2 and raw.payload_json.sha256_text() == raw.sha256 and parsed.accepted,"actual original format2 Exact whole Attempts input"): await _finish(); return
	var original: Dictionary = parsed.value.side_attempt.snapshot
	var original_wire: String = Exact.stringify(original)
	if not _expect(original.level.local.size() == 12 and not original.level.local.has("journal_arrangement") and original.level.local.profile_id == "challenge" and original.level.progress.checkpoint_id == "cylinder-before-final-exchange" and original.level.local.exchange.records.final.cycle == 0 and original.level.local.collected_ids.is_empty(),"genuine old12 Challenge dormant CP, no synthetic held/history"): await _finish(); return
	probe = TickProbe.new(); root.add_child(probe)
	for legacy: bool in [true,false]:
		var result: Dictionary = await _case(legacy,original)
		if result.is_empty(): await _finish(); return
		cases.append(result)
		if not await _dispose_game(true): await _finish(); return
	if not _expect(Exact.stringify(original) == original_wire and FileAccess.get_sha256(RawPath) == RawSha,"original packet/raw Store immutable throughout component"): await _finish(); return
	# This is the predeclared mechanical hypothesis, not final policy approval.
	if float(cases[0].primary_hp_damage) > 0.0 and float(cases[1].primary_hp_damage) > 0.0:
		decision = "REJECT_EQUIVALENT_ONE_DASH_CONTACT_PRIMARY"
	elif float(cases[0].primary_hp_damage) == 0.0 and float(cases[1].primary_hp_damage) > 0.0:
		decision = "SELECTED_PATH_DIFFERENCE_ONLY_REQUIRES_ROOT_SEMANTIC_REVIEW"
	elif float(cases[0].primary_hp_damage) > 0.0:
		decision = "REJECT_LOST_OLD_USEFUL_OPPORTUNITY"
	else:
		decision = "REJECT_EQUIVALENT_CONTACT_ONLY_NO_USEFUL_PRIMARY"
	_expect(true,"finite hypothesis outcome recorded; no angle/pose refinement or automatic policy acceptance",decision)
	complete = true
	await _finish()

func _case(legacy: bool,original: Dictionary) -> Dictionary:
	paused = true
	samples = []; states = []; hits = []; actions = []; held = {}; phases = {}; first_refusal = {}; checkpoint_contact = {}; ticks = 0
	case_notes = {"branch":"old12" if legacy else "fresh13","declared_TEST_start":Start,"fixed_angle_degrees":18.0 if legacy else 22.5,"limits":"Predeclared before execution, no post-run angle/pose search. Component Main CP entitlement is not durable campaign history."}
	game = ComponentMain.new()
	game.level_scene_path = ScenePath
	game.old_case = legacy
	game.old_packet = original.duplicate(true) if legacy else {}
	root.add_child(game)
	for _i: int in range(2): await process_frame # Native floor registration/layout, paused.
	if not _expect(game.construction_error.is_empty() and game.level_load_error.is_empty() and paused,"actual Main component construction: " + game.construction_error): return {}
	var level: CinderLevel = game.active_level
	driver = level.get("_exchange"); scheduler = level.get("_scheduler")
	var local: Dictionary = level.snapshot_state().get("local",{})
	if not _expect(not local.is_empty() and local.size() == (12 if legacy else 13) and local.profile_id == "challenge" and local.collected_ids.is_empty() and game.player.equipment.snapshot() == Neutral and game.player.hp == 100.0 and game.player.shells == 2,"actual fixed branch shape/profile/neutral resources, first two journals uncollected"): return {}
	if not legacy:
		if not _expect(local.journal_arrangement == {"schema_version":1,"profile_id":"challenge","recipe_id":"A2-O1/challenge-north-east@v1"},"fresh13 literal closed Challenge authority"): return {}
	var expected_goal := Vector3(-1.4 if legacy else 1.4,0,-8.9)
	var kit: Dictionary = level.get("_kit")
	var cues: Dictionary = level.get("_fragment_cues")
	if not _expect(kit.journals.north.global_position == expected_goal and cues.north.global_position == expected_goal and level.get("_journal_positions").north == expected_goal and level.get("_journal_positions").west == Vector3(-2.05,0,-0.6) and level.get("_journal_positions").east == Vector3(2.05,0,-0.6),"independent literal prop/cue/contact binding; only north moves"): return {}
	var actors: Dictionary = level.get("_actors")
	if not _expect(actors.size() == 2 and actors.final.global_position == Vector3(0.65,0,-7.8) and actors.west.global_position == Vector3(-0.65,0,-2) and actors.final.hp == 30.0 and actors.west.hp == 30.0 and game.camera.projection == Camera3D.PROJECTION_ORTHOGONAL and is_equal_approx(game.camera.size,7.2),"unchanged two native Scouts/fixed optics/HP"): return {}
	if not _expect(game.player.global_position == Start and driver.call("state","final").cycle == 0 and driver.call("state","west").cycle == 0,"same declared TEST pose/dormant native sources; no activation forced"): return {}
	driver.connect("state_changed",_on_state)
	driver.connect("hit_resolved",_on_hit)
	game.player.world_action_executed.connect(_on_action)
	sampling = true
	last_position = game.player.global_position; last_clock = _clock()
	game.resume_lab() # Production resume/input-chain clear.
	var locked: Dictionary = {}
	while ticks < MaxTicks:
		if not await _step(): return {}
		var current: Dictionary = driver.call("state","final")
		if current.get("armed",false): locked = current; break
	if not _expect(not locked.is_empty() and locked.proof_available and locked.phase == "lock" and level.call("_checkpoint_is_committed"),"natural Final admission/armed native lock under existing local CP preview rule"): return {}
	case_notes["native_lock"] = locked.duplicate(true)
	var lease: Dictionary = scheduler.call("reservation_state",locked.reservation_id)
	case_notes["lease"] = lease.duplicate(true)
	if not _expect(not lease.is_empty() and lease.armed and lease.source_instance_id == actors.final.get_instance_id() and lease.geometry == locked.geometry and locked.geometry.kind == "lane" and locked.geometry["from"] == actors.final.global_position and float(locked.geometry.radius) == 0.31 and (locked.geometry.to as Vector3).is_equal_approx(actors.final.global_position+(locked.direction as Vector3)*3.8),"actual own lease/complete native lane geometry and proof retained"): return {}
	# Old18deg is a deliberate counterexample to claiming old contact cannot
	# reach housing: inner old contact edge overlaps ordinary2m reach.
	# Both are legal ordinary swipe directions; no native proof is replaced.
	var direction: Vector3 = Vector3(-0.30901699437494745,0,-0.9510565162951535) if legacy else Vector3(0.3826834323650898,0,-0.9238795325112867)
	direction = direction.normalized()
	case_notes["dash_direction"] = direction
	var escape_at: float = _clock()+0.30 # Existing authored recognition, no clock mutation.
	if not await _until(escape_at): return {}
	if not _expect(_clock()+float(game.player.stats.dash_duration) < float(lease.active_from_s) and driver.call("state","final").reservation_id == lease.id,"real complete dash still fits original immutable lock"): return {}
	var sweep: Dictionary = BodySweep.sweep(game.player,game.player.global_transform,direction*float(game.player.stats.dash_distance),level.call("floor_regions"))
	if not _expect(not sweep.has("error") and not sweep.collided,"actual complete capsule/floor sweep for declared goalward dash"): return {}
	case_notes["capsule_sweep"] = sweep.duplicate(true)
	var before_actions: int = actions.size()
	if not _expect(game.player.request_dash(direction),"ordinary public full goalward dash"): return {}
	while ticks < MaxTicks and actions.size() == before_actions:
		if not await _step(): return {}
	if not _expect(actions.size() == before_actions+1 and actions.back().kind == "dash" and not actions.back().collision_shortened and actions.back().distance > 2.69,"actual single completed unshortened neutral dash record"): return {}
	while ticks < MaxTicks and driver.call("state","final").phase != "recovery":
		if not await _step(): return {}
	var recovery: Dictionary = driver.call("state","final")
	if not _expect(recovery.phase == "recovery" and recovery.reservation_id == lease.id and recovery.cycle == locked.cycle and phases.has("warning") and phases.has("lock") and phases.has("active") and phases.has("recovery") and level.get("_collected_ids") == ["north"] and not checkpoint_contact.is_empty(),"actual all phases and useful native north contact, without other journals/kills"): return {}
	if not _expect(_clock()+float(game.player.stats.primary_cooldown) < float(lease.recovery_until_s),"whole ordinary primary cadence fits real recovery"): return {}
	var hp_before: float = actors.final.hp
	var range_before: float = Vector2(game.player.global_position.x-actors.final.global_position.x,game.player.global_position.z-actors.final.global_position.z).length()
	case_notes["primary_range_before"] = range_before
	case_notes["primary_hp_before"] = hp_before
	var primary_at: float = _clock()
	game.player.slash(actors.final.global_position-game.player.global_position)
	if not await _until(primary_at+float(game.player.stats.primary_cooldown)): return {}
	var damage: float = hp_before-float(actors.final.hp)
	case_notes["primary_hp_damage"] = damage
	if not _expect(hits.is_empty() and game.player.hp == 100.0 and actions.size() == 2 and actions.back().kind == "primary" and not actions.any(func(a: Dictionary) -> bool: return a.kind == "blast"),"zero hit_resolved/no Hero damage and exactly real dash+ordinary primary"): return {}
	for id: String in held:
		var threat: Dictionary = held[id]
		if not _expect(not Geometry.timed_path_hits(threat.geometry,samples,float(threat.active_from_s),float(threat.active_until_s),CinderThreatScheduler.CAPSULE_RADIUS),"entire actual dash/hold/cadence path safe against held union member: "+id): return {}
	if not _expect(not held.is_empty() and actors.west.hp == 30.0 and String(level.get("runtime_error")).is_empty(),"whole held union present; original west Scout retained/no forced kill"): return {}
	return {"branch":"old12" if legacy else "fresh13","declared_TEST_start":Start,"original_quiet_player":game.original_quiet_player,"original_quiet_level":game.original_quiet_level,"checkpoint_scope":"old genuine mechanical CP; new real local contact CP in Main preview; neither is canonical component Save authority","dash_direction":direction,"goal":expected_goal,"goal_contact":true,"contact":checkpoint_contact.duplicate(true),"primary_range_before":range_before,"primary_hp_damage":damage,"final_hp":actors.final.hp,"hero_hp":game.player.hp,"lease":lease,"native_lock":locked,"capsule_sweep":sweep,"held_union":held.duplicate(true),"path":samples.duplicate(true),"state_events":states.duplicate(true),"actions":actions.duplicate(true),"hits":hits.duplicate(true),"ticks":ticks,"first_refusal":first_refusal.duplicate(true)}

func _step() -> bool:
	await probe.observed
	if finished: return false
	ticks += 1
	if ticks > MaxTicks or paused or not is_instance_valid(game) or game.player.dead or game.player.hp != 100.0: return _expect(false,"finite native advance/unchanged Hero HP",{"ticks":ticks,"paused":paused})
	var now: float = _clock()
	samples.append({"from":last_position,"to":game.player.global_position,"start_s":last_clock,"end_s":now})
	last_position = game.player.global_position; last_clock = now
	if checkpoint_contact.is_empty() and game.active_level.get("_collected_ids").has("north"):
		checkpoint_contact = {"clock_s":now,"hero_position":game.player.global_position,"collected_at":game.active_level.get("_fragment_collected_at").north}
	if not first_refusal.is_empty(): return _expect(false,"first actual native refusal; no retry/search/guard change",first_refusal)
	var encounter: Dictionary = game.active_level.call("encounter_state")
	if not String(encounter.runtime_error).is_empty() or not encounter.admission_errors.get("final",{}).is_empty() or not encounter.admission_errors.get("west",{}).is_empty(): return _expect(false,"actual source/runtime admission refusal",encounter)
	return true

func _until(target: float) -> bool:
	while _clock()+0.000001 < target and ticks < MaxTicks:
		if not await _step(): return false
	return _expect(ticks < MaxTicks and _clock()+0.000001 >= target,"finite original native time boundary")

func _clock() -> float: return float(scheduler.call("get_clock"))
func _on_state(id: String,state: Dictionary) -> void:
	if not sampling: return
	states.append({"actor_id":id,"clock_s":_clock(),"state":state.duplicate(true),"camera_origin":game.camera.global_position,"camera_basis":{"x":game.camera.global_basis.x,"y":game.camera.global_basis.y,"z":game.camera.global_basis.z},"shared_framing":game.get_camera_framing_state()})
	if id == "final" and state.status == "running": phases[String(state.phase)] = true
	if state.get("armed",false) and not held.has(state.reservation_id): held[state.reservation_id] = state.exchange.duplicate(true)
	if not String(state.get("last_cancel_reason","")).is_empty() and first_refusal.is_empty(): first_refusal = {"actor_id":id,"clock_s":_clock(),"state":state.duplicate(true)}
func _on_hit(id: String,result: Dictionary) -> void:
	if sampling: hits.append({"actor_id":id,"clock_s":_clock(),"result":result.duplicate(true)})
func _on_action(record: Dictionary) -> void:
	if sampling: actions.append(record.duplicate(true))

func _dispose_game(sampling_completed: bool) -> bool:
	paused = true
	# Explicit observer boundary BEFORE ordinary cleanup cancellation.
	if is_instance_valid(driver):
		if driver.is_connected("state_changed",_on_state): driver.disconnect("state_changed",_on_state)
		if driver.is_connected("hit_resolved",_on_hit): driver.disconnect("hit_resolved",_on_hit)
	if is_instance_valid(game) and is_instance_valid(game.player) and game.player.world_action_executed.is_connected(_on_action): game.player.world_action_executed.disconnect(_on_action)
	sampling = false
	var refs: Array = _refs(game) if is_instance_valid(game) else []
	await process_frame # Never free a native callback emitter while it emits.
	if is_instance_valid(game):
		if is_instance_valid(game.active_level): game.active_level.exit_level()
		if is_instance_valid(game.fx): game.fx.clear_lab()
		game.free()
	game = null; driver = null; scheduler = null
	await process_frame
	return _expect(refs.all(func(r: WeakRef) -> bool: return r.get_ref() == null) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(),"ordinary native world/actor/cue cleanup",{"sampling_completed":sampling_completed})
func _refs(node: Node) -> Array:
	var result: Array = [weakref(node)]
	for child: Node in node.get_children(): result.append_array(_refs(child))
	return result
func _expect(ok: bool,label: String,note: Variant = {}) -> bool:
	var row: Dictionary = {"check":rows.size()+1,"ok":ok,"label":label,"note":_json(note)}
	rows.append(row)
	if not ok:
		failures += 1
		if first_failure.is_empty(): first_failure = row.duplicate(true)
	return ok
func _json(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[str(key)] = _json(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_json(item))
		return result
	if value is Vector3: return [value.x,value.y,value.z]
	if value is Vector2: return [value.x,value.y]
	if value is Rect2: return {"position":_json(value.position),"size":_json(value.size)}
	if value == null or value is bool or value is String or value is int or value is float: return value
	return {"passive_native_type":type_string(typeof(value)),"diagnostic":str(value)}
func _finish() -> void:
	if finished: return
	finished = true; complete = complete and failures == 0
	if is_instance_valid(probe): probe.set_physics_process(false)
	if is_instance_valid(game): await _dispose_game(false)
	paused = false
	if is_instance_valid(probe): probe.free()
	AudioServer.set_bus_layout(old_audio); Engine.max_fps = old_fps
	complete = complete and failures == 0
	var file: FileAccess = null
	if report_path.is_absolute_path() and not FileAccess.file_exists(report_path): file = FileAccess.open(report_path,FileAccess.WRITE)
	if not _expect(file != null,"fresh actual component report opens"): complete = false
	if file != null:
		file.store_string(JSON.stringify({"kind":"a2-o1-goal-decision-component-1","checks":rows.size(),"failures":failures,"rows":rows,"first_failure":first_failure,"complete":complete,"success":complete and failures == 0,"candidate_qualified":false,"decision":decision,"cases":_json(cases),"partial":{"case_notes":_json(case_notes),"path":_json(samples),"states":_json(states),"actions":_json(actions),"hits":_json(hits),"first_refusal":_json(first_refusal)},"scope":"One neutral declared current-final component. Old12 exact mechanical restore then NEW TEST pose/camera, fresh13 real local contact CP. Direct controller request_dash/slash component input, no gesture/last-release aim proof. Not old saved-view/wholeStore acceptance, earned route/exit/all-kit/portrait or final semantic novelty credit. Native experiment completion is not candidate acceptance: REJECT_EQUIVALENT means reject north move. Selected-path differences still need Root semantic review; no global novelty inferred."})+"\n"); file.close()
	print("CINDER_A2_O1_GOAL_DECISION_REPORT=",report_path," sha256=",FileAccess.get_sha256(report_path) if FileAccess.file_exists(report_path) else "")
	print("A2-O1 GOAL DECISION: %d checks, %d failures; complete=%s" % [rows.size(),failures,str(complete)])
	quit(0 if complete and failures == 0 else 2)
