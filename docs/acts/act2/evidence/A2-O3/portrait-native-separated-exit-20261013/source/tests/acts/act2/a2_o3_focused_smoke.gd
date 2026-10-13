extends SceneTree
## DRAFT ONLY O3 tracked Scout armed-lock and stationary Handler warning proofs.
## Natural claim uses admitted original proofs, public completed ground dashes,
## one real ordinary primary/source and its full cooldown; no blast or pickup.
## TEST_ONLY public shells=0 at each actual opening (reload remains native).
## TEST_ONLY later recovery-gated Actor injuries and actual Hero placements
## arrange the separate CP/final/completion/quiet scenery boundaries. Those are
## labelled setups, never ordinary route/defeat credit. No HP/phase/proof/clock/
## deadline/pending-path/progression writes; no whole-route acceptance gate.
const MainScene: PackedScene = preload("res://scenes/main.tscn")
const O3_PATH: String = "res://scenes/acts/act2/a2_o3.tscn"
const Exact: Script = preload("res://scripts/campaign/exact_json.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const Equipment: Script = preload("res://scripts/equipment.gd")
const ProfileSeedGame: Script = preload("res://tests/acts/act2/fixtures/a2_l1_profile_seed_game.gd")
const EXTREME_LOADOUTS: Array[Dictionary] = [
	{"id":"slow-dash-short-reach","loadout":{"jacket":"CLOTH-J1","pants":"CLOTH-P2","shoes":"CLOTH-S2","weapon":"WEAPON-03"}},
	{"id":"slow-primary-reach","loadout":{"jacket":"CLOTH-J1","pants":"CLOTH-P1","shoes":"CLOTH-S0","weapon":"WEAPON-03"}},
]
const CP_ID: String = "bleached-canal-before-final-pocket"
const COMPLETE_ID: String = "bleached-canal-complete"
const EXIT_ID: String = "bleached-canal-return"
const SCOUTS: Array[String] = ["first_scout","final_scout"]
const CP_AT: Vector3 = Vector3(0,0.1,-18.3)
const EXIT_AT: Vector3 = Vector3(0,0.1,-26)
const MAX_TICKS: int = 900
const TICK_S: float = 1.0/60.0
const DERIVED_EPS: float = 0.00001
const OWNED_CAPTURE_PREFIX: String = "res://docs/acts/act2/evidence/A2-O3/"
const REVIEW_INPUT: String = "res://docs/acts/act2/evidence/A2-O3/completed-review-input-20261013/completed-order-1.exact.json"
const REVIEW_INPUT_SHA: String = "b2e14450660ff557327fd343508156d2fc7d721c1b212453ef12966276daa519"
const REVIEW_SOURCE_METADATA: String = "res://docs/acts/act2/evidence/A2-O3/portrait-native-first/images/metadata.exact.json"
const REVIEW_SOURCE_METADATA_SHA: String = "cc3b1bf3be15cdd4341265f36d1a4d8f7a25355240a423ff03ee3f7f3d9ff708"
const REVIEW_EXIT_REGION: Rect2 = Rect2(-0.65,-26.55,1.3,1.1)
const REVIEW_POSE: Vector3 = Vector3(2.1,0.1,-24.8)
const LABELS: Array[String] = ["entry","scout-lock","quiet-wall","handler-lock","mixed-pair","opened-exit"]
class NativeTickProbe extends Node:
	signal tick_finished
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 120
	func _physics_process(_delta: float) -> void: tick_finished.emit()
var _checks: int = 0
var _failures: int = 0
var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _probe: NativeTickProbe
var _abort: bool = false
var _capture: bool = false
var _review: bool = false
var _review_info: Dictionary = {}
var _review_restore_events: Array[String] = []
var _review_watch: bool = false
var _capture_root: String
var _capture_pending: bool = false
var _capture_resume_events: Array[Dictionary] = []
var _frames: Array[Dictionary] = []
var _scope_complete: bool = false
var _extremes: bool = false
var _loadout: Dictionary = {}
var _stats: Dictionary = {}
var _extreme_results: Array[Dictionary] = []
var _actions: Array[Dictionary] = []
var _phases: Dictionary = {}
var _setup: Array[Dictionary] = []
var _checkpoints: Array[String] = []
var _completions: Array[String] = []
var _exits: Array[String] = []
var _lock_captured: Dictionary = {}
var _invalidations: Array[Dictionary] = []
var _mixed_follow: bool = false
var _mixed_seen: bool = false

func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	root.size = Vector2i(540,1170)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_review = "--a2-o3-review-exit" in OS.get_cmdline_user_args()
	_capture = _review or "--a2-o3-portraits" in OS.get_cmdline_user_args()
	if _review and not _expect(not ("--a2-o3-portraits" in OS.get_cmdline_user_args()) and not ("--a2-o3-extremes" in OS.get_cmdline_user_args()),"explicit brief review mode is separate from original mechanics/portraits/extremes"): _finish(); return
	_extremes = "--a2-o3-extremes" in OS.get_cmdline_user_args()
	if _extremes and not _expect(not _capture and DisplayServer.get_name() == "headless","explicit headless two-loadout mechanics scope excludes portraits"): _finish(); return
	if _capture:
		if not _expect(DisplayServer.get_name() != "headless","actual native graphics required for portraits") or not _prepare_capture_root(): _finish(); return
	_probe = NativeTickProbe.new(); root.add_child(_probe)
	if _review:
		_scope_complete = await _review_exit_component()
		_expect(_scope_complete,"single completed-snapshot separated exit review finishes")
		await _release()
		_write_review_metadata()
		_probe.queue_free(); await process_frame; _finish(); return
	if _extremes:
		for definition: Dictionary in EXTREME_LOADOUTS:
			_loadout = definition.loadout.duplicate(true); _stats.clear()
			var okay: bool = await _mechanics_component()
			_expect(okay,"native ordinary Scout and Handler component for " + String(definition.id))
			var same: bool = not _actions.is_empty()
			for action: Dictionary in _actions: same = same and action.equipment_ids == _loadout and action.resolved_stats == _stats
			_expect(same,"all actual world actions retain selected complete legal gear/stats " + String(definition.id))
			_extreme_results.append({"id":definition.id,"complete":okay,"loadout":_loadout.duplicate(true),"stats":_stats.duplicate(true),"phases":_phases.duplicate(true),"actual_actions":_actions.size(),"hero_hp":_hero.hp if is_instance_valid(_hero) else null,"setups":_setup.duplicate(true)})
			await _release()
			if not okay or _failures > 0: break
		_scope_complete = _extreme_results.size() == EXTREME_LOADOUTS.size() and _failures == 0
		_expect(_scope_complete,"both existing extrema complete actual ordinary noammo responses/full cadence without pickups")
		print("O3 actual extrema: ",Exact.stringify(_extreme_results))
	else:
		_scope_complete = await _mechanics_component()
		_expect(_scope_complete,"focused actual Scout and Handler/Lane ordinary components complete")
		await _release()
		if _capture: _write_metadata()
	if is_instance_valid(_probe): _probe.queue_free()
	await process_frame
	_finish()

func _review_exit_component() -> bool:
	if not _expect(FileAccess.get_sha256(REVIEW_INPUT) == REVIEW_INPUT_SHA and FileAccess.get_sha256(REVIEW_SOURCE_METADATA) == REVIEW_SOURCE_METADATA_SHA,"actual complete tuple and original source metadata retain exact frozen input hashes"): return false
	var decoded: Dictionary = Exact.parse(FileAccess.get_file_as_string(REVIEW_INPUT))
	var source: Dictionary = Exact.parse(FileAccess.get_file_as_string(REVIEW_SOURCE_METADATA))
	if not _expect(decoded.get("accepted",false) and decoded.get("value") is Dictionary and source.get("accepted",false) and source.get("value") is Dictionary,"official Exact parser accepts both actual frozen packets"): return false
	var saved: Dictionary = decoded.value
	var source_pins: Dictionary = source.value.get("source_files",{})
	var current: Dictionary = _sources()
	var pins_match: bool = source_pins.size() == current.size()
	for path: String in current: pins_match = pins_match and source_pins.get(path) == current[path]
	if not _expect(pins_match,"original host/kit/Game/Player/consumer/scene pins match actual review recipient"): return false
	if not _expect(saved.get("level_id") == "A2-O3" and saved.get("scene_path") == O3_PATH and saved.get("paused") == true and saved.get("player") is Dictionary and saved.get("level") is Dictionary,"review authority is the actual full paused O3 tuple, never old diagnostic frame data"): return false
	var local: Dictionary = saved.level.local
	var closed: bool = local.stage_index == 4 and saved.level.progress.completed == true and saved.level.progress.completion_id == COMPLETE_ID and saved.level.progress.contact_exit_id == "" and not saved.player.resources.dead and saved.player.motion.grounded and local.scheduler.encounter_id == "" and local.scheduler.reservations.is_empty()
	for id: String in ["first_scout","second_handler","final_scout","final_handler"]: closed = closed and local.actors[id].hp == 0.0 and local.actors[id].phase == "defeated"
	if not _expect(closed,"actual completed stable tuple has all four native tombstones/ended Scheduler and no prior contact return"): return false
	paused = true
	_game = MainScene.instantiate(); _game.set_script(ProfileSeedGame)
	_game.set("test_profile_id",String(local.profile_id)); _game.set("level_scene_path",O3_PATH)
	root.add_child(_game); paused = true
	_level = _game.get("active_level") as CinderLevel; _hero = _game.get("player") as CinderPlayer
	if not _expect(_live() and _level.level_id == "A2-O3" and _level.contract_error().is_empty(),"fresh actual paused Main/shared Hero/level exists before public restore"): return false
	_review_connect_restore_observers()
	_review_watch = true
	var player_error: String = _hero.snapshot_error(saved.player)
	var level_error: String = _level.snapshot_error_with_player(saved.level,saved.player)
	if not _expect(player_error.is_empty() and level_error.is_empty(),"public staged Player/Level preflight accepts exact completed pair: "+player_error+level_error): _review_watch = false; return false
	var restored: bool = _hero.restore_state(saved.player) and _level.restore_state(saved.level)
	var exact: bool = restored and _same(_hero.snapshot_state(),saved.player) and _same(_level.snapshot_state(),saved.level)
	_review_watch = false
	if not _expect(exact and _review_restore_events.is_empty() and _hero.get_threat_response_state().stable and _level.is_completed(),"quiet public Player then Level restore is complete exact before any pose/tick/action"): return false
	_review_info = {"tuple_path":REVIEW_INPUT,"tuple_sha256":REVIEW_INPUT_SHA,"source_metadata_path":REVIEW_SOURCE_METADATA,"source_metadata_sha256":REVIEW_SOURCE_METADATA_SHA,"verified_source_files":source_pins,"fixture_sha256":FileAccess.get_sha256(get_script().resource_path),"public_pair_restore_exact":exact,"quiet_restore_events":_review_restore_events.duplicate(),"restored_scope":"complete Player/Level pair; Shell context excluded"}
	_hero.world_action_executed.connect(func(record: Dictionary) -> void: _actions.append(record.duplicate(true)))
	_level.contact_exit_requested.connect(func(_id: String,id: String) -> void: _exits.append(id))
	_setup.append({"kind":"initial-profile","scope":"TEST_ONLY existing public profile provider selects saved challenge before fresh tree entry; no runtime retune"})
	if not await _test_place(REVIEW_POSE,"TEST_ONLY supported separated exit review feet; no route/defeat/contact credit"): return false
	for _tick: int in range(60): await _step()
	var cue: CinderInteractionCue = _level.get_node_or_null("BleachedCanalContactExit") as CinderInteractionCue
	if not _expect(is_instance_valid(cue) and cue.is_visible_in_tree(),"actual original authored contact cue exists visibly for separated review"): return false
	var cue_state: Dictionary = cue.state()
	var feet: Vector2 = Vector2(_hero.global_position.x,_hero.global_position.z)
	if not _expect(_live() and _hero.is_on_floor() and _hero.get_threat_response_state().stable and not REVIEW_EXIT_REGION.has_point(feet) and _exits.is_empty() and _actions.is_empty() and cue_state.state == "available" and cue_state.trigger == "contact" and cue_state.required and cue_state.visible,"normal supported pose/follow shows real available contact cue without action or exit contact"): return false
	await _capture_view("opened-exit-separated","TEST_ONLY separated supported Hero review pose after exact real completed tuple restore; one actual exit-marker crop, no route/art/balance claim")
	if _frames.size() == 1: _frames[0]["contact_review"] = {"cue_state":cue.state(),"cue_position":_encode(cue.global_position),"feet_outside_exit_region":not REVIEW_EXIT_REGION.has_point(Vector2(_hero.global_position.x,_hero.global_position.z)),"exit_signal_ids":_exits.duplicate(),"input_observation":_encode(_game.get_input_observation_state()),"tuple_sha256":REVIEW_INPUT_SHA}
	return _live() and _failures == 0 and _frames.size() == 1
func _review_event(label: String) -> void:
	if _review_watch: _review_restore_events.append(label)
func _review_connect_restore_observers() -> void:
	_hero.fired.connect(func(_k: String) -> void: _review_event("fire")); _hero.died.connect(func() -> void: _review_event("death"))
	_hero.equipment_changed.connect(func(_id: String) -> void: _review_event("gear")); _hero.action_resolved.connect(func(_k: String,_n: int,_d: float) -> void: _review_event("action")); _hero.world_action_executed.connect(func(_r: Dictionary) -> void: _review_event("world-action"))
	_level.checkpoint_requested.connect(func(_l: String,_id: String,_k: String) -> void: _review_event("CP")); _level.completion_requested.connect(func(_l: String,_id: String) -> void: _review_event("complete")); _level.contact_exit_requested.connect(func(_l: String,_id: String) -> void: _review_event("exit"))
	var exchange: Node = _level.call("get_exchange")
	exchange.connect("state_changed",func(_id: String,_s: Dictionary) -> void: _review_event("ray-phase")); exchange.connect("scout_defeated",func(_id: String) -> void: _review_event("ray-defeat")); exchange.connect("hit_resolved",func(_id: String,_r: Dictionary) -> void: _review_event("ray-hit"))
	_level.call("get_scheduler").connect("reservation_invalidated",func(_id: String,_r: String) -> void: _review_event("cancel"))
	for id: String in ["first_scout","second_handler","final_scout","final_handler"]: _actor(id).connect("defeated",func(_id: String) -> void: _review_event("actor-defeat"))
	for id: String in ["second_handler","final_handler"]:
		var tool: Node = _level.call("get_tool",id)
		tool.connect("state_changed",func(_s: Dictionary) -> void: _review_event("lane-phase")); tool.connect("hit_resolved",func(_id: String,_c: int,_r: Dictionary) -> void: _review_event("lane-hit"))
	for cue: Node in get_nodes_in_group("required_cues"):
		if _level.is_ancestor_of(cue) and (cue is CinderInteractionCue or cue is CinderThreatCue): cue.connect("state_changed",func(_s: Dictionary) -> void: _review_event("cue"))
func _write_review_metadata() -> void:
	var labels: Array[String] = []
	for frame: Dictionary in _frames: labels.append(frame.label)
	_expect(labels == ["opened-exit-separated"],"one original separated exit review image only")
	var packet: Dictionary = {"api_revision":"act2-o3-brief-exit-review-1","scope":"actual completed pair quiet restore then labelled supported feet/normal follow; single directly affected exit crop, no new mechanics/route/Shell/art acceptance claim","checks":_checks,"failures":_failures,"scope_complete":_scope_complete,"review_input":_review_info,"frames":_frames,"source_files":_sources(),"capture_environment_resume_events":_capture_resume_events,"art_accepted":false}
	if not _expect(not Exact.stringify(packet).is_empty() and not FileAccess.file_exists(_capture_root+"metadata.exact.json"),"portable review metadata preserves all prior originals"): return
	var file: FileAccess = FileAccess.open(_capture_root+"metadata.exact.json",FileAccess.WRITE)
	if not _expect(file != null,"new review metadata file opens"): return
	packet.checks = _checks; packet.failures = _failures
	file.store_string(Exact.stringify(packet)+"\n"); file.close()

func _boot() -> bool:
	_abort = false; _actions.clear(); _phases.clear(); _setup.clear(); _checkpoints.clear(); _completions.clear(); _exits.clear(); _lock_captured.clear(); _invalidations.clear(); _mixed_follow = false; _mixed_seen = false
	_game = MainScene.instantiate()
	if not _loadout.is_empty():
		_game.set_script(ProfileSeedGame); _game.set("test_profile_id","standard")
	_game.set("level_scene_path",O3_PATH); root.add_child(_game)
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _expect(is_instance_valid(_level) and is_instance_valid(_hero) and _level.level_id == "A2-O3" and _level.contract_error().is_empty(),"actual Main installs O3 contract/shared Hero"): return false
	if not _expect(_level.has_method("get_actor") and _level.has_method("get_exchange") and _level.has_method("get_tool") and _level.has_method("get_tool_proof") and _level.has_method("get_scheduler"),"new host exposes public native leaf/proof getters"): return false
	if not _loadout.is_empty():
		paused = true
		if not _select_initial_gear(): return false
	_hero.world_action_executed.connect(func(record: Dictionary) -> void: _actions.append(record.duplicate(true)))
	var native_scheduler: Node = _level.call("get_scheduler")
	native_scheduler.connect("reservation_invalidated",func(id: String,reason: String) -> void: _invalidations.append({"reservation_id":id,"reason":reason,"clock_s":native_scheduler.call("get_clock")}))
	_level.checkpoint_requested.connect(func(_id: String,id: String,_kind: String) -> void: _checkpoints.append(id))
	_level.completion_requested.connect(func(_id: String,id: String) -> void: _completions.append(id))
	_level.contact_exit_requested.connect(func(_id: String,id: String) -> void: _exits.append(id))
	_game.call("resume_lab")
	for _tick: int in range(12): await _step()
	return _expect(_live() and _hero.presentation_id == "act2_survivor" and _hero.is_on_floor() and (_hero.equipment.snapshot() == _loadout if not _loadout.is_empty() else _hero.equipment.snapshot().weapon == "WEAPON-01"),"actual shared Act2 Hero settles on continuous native dry floor")

func _select_initial_gear() -> bool:
	if not _expect(paused and _clock() == 0.0 and _hero.get_world_action_records().is_empty() and float(_hero.get_threat_response_state().action_clock_s) == 0.0,"TEST_ONLY legal gear selection precedes every actual clock/action/admission"): return false
	var resolver: CinderEquipment = Equipment.new()
	if not _expect(resolver.restore(_loadout) and resolver.acceptance_errors().is_empty(),"canonical complete resolver accepts selected legal numerical fixture"): return false
	for slot: String in CinderEquipment.SLOTS:
		if not _expect(resolver.is_implemented(String(_loadout[slot])) and resolver.item(String(_loadout[slot])).slot == slot and resolver.item(String(_loadout[slot])).perk_id == null,"existing implemented static canonical slot/no ability introduction " + slot): return false
	_stats = resolver.resolved_stats()
	var hp: float = _hero.hp
	var ammo: int = _hero.shells
	var okay: bool = _hero.equipment.restore(_loadout) and _hero.equip_item(String(_loadout.weapon))
	return _expect(okay and _hero.equipment.snapshot() == _loadout and _hero.stats == _stats and _hero.hp == hp and _hero.shells == ammo and _clock() == 0.0,"public fresh weapon equip refreshes shared visuals/stats without HP/ammo/action seed")

func _mechanics_component() -> bool:
	if not await _boot(): return false
	if _capture: await _capture_view("entry","actual initial dry causeway/parent art; no approach, defeat or progress seed")
	var hp_before: float = _hero.hp
	if not await _dash(Vector3(-0.12,0,-1)): return false
	# A source-only TEST approach trial for the failed slow-dash/short-reach
	# cell: one more genuine routed diagonal dash, using unchanged native
	# readiness/completion/cooldown. The prior log did not identify the clipped
	# bound; this changes approach only and does not assert its unseen cause.
	if _extremes and _loadout == EXTREME_LOADOUTS[0].loadout:
		if not await _dash(Vector3(0.3826834324,0,-0.9238795325)): return false
	var scout: Dictionary = await _wait_plan("first_scout","lock")
	if scout.is_empty() or not await _follow(scout): return false
	_expect(_all_phases("first_scout") and _hero.hp == hp_before,"actual tracked warning/full armed lock/active/recovery and native escape-return preserve HP")
	_expect(float(_actor("first_scout").get("hp")) > 0.0 and float(_actor("first_scout").get("hp")) < 30.0,"real immediate ordinary primary hits low Scout housing while source remains living")
	if not await _test_gated_defeat("first_scout",false): return false
	if not await _wait_quiet("first_scout"): return false
	_expect(int(_state().stage_index) == 1,"actual labelled gated first defeat advances only arrangement1")
	if _capture:
		if not await _test_place(Vector3(0,0.1,-7),"quiet bleached/villa wall-base portrait before Handler approach"): return false
		await _capture_view("quiet-wall","actual quiet reused bleached scenery and visible wall base; TEST feet placement, no collider-bypass claim")
	if not await _test_place(Vector3(2.1,0.1,-9.5),"broad east approach to second Handler, before its original warning schedule"): return false
	var handler_hp: float = _hero.hp
	var handler: Dictionary = await _wait_plan("second_handler","warning")
	if handler.is_empty() or not await _follow(handler): return false
	_expect(_all_phases("second_handler") and _hero.hp == handler_hp,"actual Handler ordinary warning/full lock/active/recovery escape-return preserves HP")
	_expect(float(_actor("second_handler").get("hp")) > 0.0 and float(_actor("second_handler").get("hp")) < 30.0,"one real ordinary primary hits original low Handler mount with no victory or new role")
	if not await _test_gated_defeat("second_handler",false) or not await _wait_quiet("second_handler"): return false
	if not await _test_place(Vector3(0,0.1,-21.8),"final proximity before actual before-third checkpoint; no admission authority"): return false
	_expect(_state().stage_index == 2 and not _state().checkpoint_committed and int(_native("final_scout").cycle) == 0 and int(_native("final_handler").cycle) == 0,"actual final proximity leaves both native cycles zero before checkpoint commit")
	if not await _test_place(CP_AT,"native stable before-third contact"): return false
	_expect(_level.current_checkpoint().id == CP_ID and _state().checkpoint_committed,"real local preview checkpoint contact commits before third admission; durable Shell checkpoint covered separately")
	if not await _test_place(Vector3(0,0.1,-21.8),"representative final pair start; earlier defeats/late feet are TEST setup, subsequent response is native"): return false
	_mixed_follow = true
	var mixed_hp: float = _hero.hp
	var mixed: Dictionary = await _wait_mixed_plan()
	if mixed.is_empty() or not await _follow(mixed): return false
	_mixed_follow = false
	_expect(_mixed_seen and _all_phases(mixed.source) and _hero.hp == mixed_hp,"actual retained mixed Scout/Handler union permits original warning/lock/active/recovery, ordinary escape/return/full primary cadence with preserved HP")
	_expect(float(_actor(mixed.source).get("hp")) > 0.0 and float(_actor(mixed.source).get("hp")) < 30.0,"one real ordinary primary damages selected living final source in actual mixed arrangement")
	var primaries: int = 0
	for action: Dictionary in _actions:
		_expect(action.kind != "blast","no blast/pickup dependency in each natural response")
		if action.kind == "primary": primaries += 1
	_expect(primaries == 3,"one real routed primary per first Scout/second Handler/final mixed response")
	if _capture:
		for id: String in ["final_scout","final_handler"]:
			if not await _test_gated_defeat(id,true) or not await _wait_quiet(id): return false
		for _tick: int in range(MAX_TICKS):
			if not _live() or _level.is_completed(): break
			await _step()
		_expect(_level.is_completed() and _completions == [COMPLETE_ID] and _exits.is_empty(),"labelled genuine final clear opens exit separately from contact")
		if not await _test_place(Vector3(0,0.1,-25.1),"opened contact exit beside decorative sign, before actual exit contact"): return false
		await _capture_view("opened-exit","actual opened contact cue/sign separation; labelled boundary setup, no earned route/stamp credit")
	return _live() and _failures == 0

func _wait_mixed_plan() -> Dictionary:
	# Follow the first timely original armed response. Waiting for the other
	# source's lock must never consume this response's original escape deadline.
	for _tick: int in range(MAX_TICKS):
		if not _live(): break
		for source: String in ["final_handler","final_scout"]:
			var state: Dictionary = _native(source)
			if state.status != "running" or state.phase != ("lock" if SCOUTS.has(source) else "warning"): continue
			var proof: Dictionary = state.get("proof",{})
			var lease: Dictionary = _level.call("get_scheduler").call("reservation_state",state.reservation_id)
			if not proof.get("accepted",false) or not lease.get("armed",false): continue
			var timely: bool = false
			for segment: Dictionary in proof.path:
				if segment.kind in ["escape_dash","positioning_dash","ordinary_primary"]:
					timely = _clock() <= float(segment.start_s)+TICK_S+DERIVED_EPS
					break
			if not timely: continue
			if not _expect(float(lease.active_from_s)-float(lease.lock_from_s) >= 1.1-DERIVED_EPS and not proof.uses_blast and not proof.uses_invulnerability,"actual mixed native source retains original ordinary armed proof/full lock"): return {}
			return {"source":source,"target":source,"cycle":state.cycle,"reservation":lease.duplicate(true),"proof":proof.duplicate(true)}
		await _step()
	_expect(false,"bounded timely actual mixed-pair original response: " + str(_state()))
	return {}

func _wait_plan(source: String,phase: String) -> Dictionary:
	for _tick: int in range(MAX_TICKS):
		if not _live(): break
		var state: Dictionary = _native(source)
		if state.status == "running" and state.phase == phase:
			var proof: Dictionary = state.get("proof",{}) if SCOUTS.has(source) else _level.call("get_tool_proof",source)
			var lease: Dictionary = _level.call("get_scheduler").call("reservation_state",state.reservation_id)
			if not _expect(proof.get("accepted",false) and lease.get("armed",false) and float(lease.active_from_s)-float(lease.lock_from_s) >= 1.1-DERIVED_EPS and not proof.uses_blast and not proof.uses_invulnerability,"actual source retains armed original ordinary proof/full1.10 lock " + source): return {}
			return {"source":source,"target":source,"cycle":state.cycle,"reservation":lease.duplicate(true),"proof":proof.duplicate(true)}
		await _step()
	_expect(false,"bounded actual armed " + source + " " + phase + ": " + str(_state()))
	return {}

func _follow(plan: Dictionary) -> bool:
	# Follow the Scout's actual armed lock/reproof or the Handler's original
	# armed warning schedule; inspect portraits only during a later idle hold.
	var actor: Node3D = _actor(plan.target)
	for segment: Dictionary in plan.proof.path:
		if segment.kind not in ["escape_dash","positioning_dash","ordinary_primary"]: continue
		for _tick: int in range(MAX_TICKS):
			if not _live(): return false
			if _clock()+DERIVED_EPS >= float(segment.start_s): break
			if not await _capture_lock_during_wait(plan,float(segment.start_s)): return false
			if _clock()+DERIVED_EPS >= float(segment.start_s): break
			await _step()
		if not _expect(_clock()+DERIVED_EPS >= float(segment.start_s) and _clock() <= float(segment.start_s)+TICK_S+DERIVED_EPS,"native120 sampler reaches planned " + String(segment.kind) + " within one tick"): return false
		var same_plan: bool = _same_plan(plan)
		if not same_plan:
			var lost: Dictionary = _native(plan.source)
			var retained: Dictionary = _level.call("get_scheduler").call("reservation_state",plan.reservation.id)
			print("O3 passive plan loss: ",Exact.stringify(_encode({"clock_s":_clock(),"segment":segment,"consumer":lost,"original":plan.reservation,"retained":retained,"hero_position":_hero.global_position,"runtime_error":_state().runtime_error,"invalidations":_invalidations})))
		if not _expect(same_plan,"same admitted native source/cycle/deadlines still owns planned action"): return false
		var response: Dictionary = _hero.get_threat_response_state()
		if segment.kind == "ordinary_primary":
			if not _expect(response.stable and float(response.primary_cooldown_left_s) == 0.0 and float(response.commitment_remaining_s) == 0.0,"native primary readiness at actual response tick"): return false
			if not _expect(float(segment.start_s) == float(plan.proof.primary_time_s) and float(segment.end_s) == float(plan.proof.response_complete_s) and float(plan.proof.response_complete_s) == float(plan.proof.primary_time_s)+float(_hero.stats.primary_cooldown),"original proof retains exact complete canonical primary cadence"): return false
			var state: Dictionary = _native(plan.source)
			if not _expect(state.phase == "recovery" and _clock()+float(_hero.stats.primary_cooldown) <= float(plan.reservation.recovery_until_s)-CinderThreatScheduler.TIME_MARGIN,"real primary and full actual cooldown fit retained native recovery"): return false
			var direction: Vector3 = actor.global_position-_hero.global_position; direction.y = 0.0
			if not _expect(direction.length() <= float(_hero.stats.primary_range)+DERIVED_EPS,"actual completed native landing reaches low ordinary mount"): return false
			var hp: float = float(actor.get("hp"))
			var seq: int = _sequence()
			_hero.shells = 0 # TEST_ONLY actual empty resource conditioning; reload unchanged.
			_setup.append({"kind":"empty-ammo","source":plan.source,"clock_s":_clock(),"scope":"TEST_ONLY public ammo=0, no pickup/reload/stat suppression"})
			var hits: int = _routed_primary(direction.normalized())
			var expected_hits: bool = hits >= 1 if _mixed_follow else hits == 1
			if not _expect(expected_hits and float(actor.get("hp")) < hp and _sequence() == seq+1 and _actions.back().kind == "primary","public ordinary primary hits actual low mount with empty ammo " + String(plan.target)): return false
			var recovered: bool = false
			for _tick: int in range(MAX_TICKS):
				if not _live(): return false
				response = _hero.get_threat_response_state()
				if response.stable and float(response.primary_cooldown_left_s) == 0.0 and float(response.commitment_remaining_s) == 0.0: recovered = true; break
				await _step()
			if not _expect(recovered and _clock() <= float(plan.reservation.recovery_until_s),"full native ordinary primary cadence finishes inside original recovery"): return false
		else:
			if not _expect(response.stable and float(response.dash_cooldown_left_s) == 0.0 and float(response.commitment_remaining_s) == 0.0,"actual proof dash ready at sampled action tick"): return false
			var direction: Vector3 = segment.to-_hero.global_position; direction.y = 0.0
			if not await _dash(direction): return false
	await _wait_capture()
	if _capture and not _expect(_lock_captured.has(String(plan.source)),"actual original lock/mixed portrait exists without delaying its admitted proof: " + String(plan.source)): return false
	return _live()

func _capture_lock_during_wait(plan: Dictionary,next_action_s: float) -> bool:
	if not _capture or _lock_captured.has(String(plan.source)): return true
	var current: Dictionary = _native(plan.source)
	if current.status != "running" or current.phase != "lock": return true
	if _mixed_follow and not _pair_running(): return true
	var response: Dictionary = _hero.get_threat_response_state()
	# An imminent scheduled action or an unfinished native dash always takes
	# priority. No post-draw await occurs inside _dash or an action window.
	if _hero.action_in_progress() or not response.stable or float(response.commitment_remaining_s) != 0.0 or _clock()+TICK_S+DERIVED_EPS >= next_action_s: return true
	if not _expect(_same_plan(plan),"original admitted source/cycle/lease still owns idle lock capture"): return false
	var expected: Dictionary = plan.duplicate(true)
	expected["next_action_s"] = next_action_s
	var sequence: int = _sequence()
	var label: String = "mixed-pair" if _mixed_follow else ("scout-lock" if SCOUTS.has(plan.source) else "handler-lock")
	await _capture_view(label,"actual original native lock sampled during its proof's idle hold; accepted native response already follows its original schedule",expected)
	if not _expect(_live() and _same_plan(plan) and _clock()+DERIVED_EPS < next_action_s and _sequence() == sequence,"post-draw returns before the next original action with unchanged admitted lease and no extra controls"): return false
	var after: Dictionary = _native(plan.source)
	if not _expect(after.phase == "lock" and after.cycle == plan.cycle and after.reservation_id == plan.reservation.id,"post-draw still retains the captured original native lock"): return false
	_lock_captured[String(plan.source)] = true
	return true

func _same_plan(plan: Dictionary) -> bool:
	var state: Dictionary = _native(plan.source)
	var lease: Dictionary = _level.call("get_scheduler").call("reservation_state",state.get("reservation_id",""))
	if state.status != "running" or state.cycle != plan.cycle or state.reservation_id != plan.reservation.id or not lease.get("armed",false): return false
	for key: String in ["start_s","lock_from_s","active_from_s","active_until_s","recovery_until_s","geometry","opening_position"]:
		if lease.get(key) != plan.reservation.get(key): return false
	return true
func _test_gated_defeat(id: String,reposition: bool) -> bool:
	if not _live(): return false
	if reposition:
		var actor: Node3D = _actor(id)
		if not await _test_place(actor.global_position + Vector3.RIGHT*1.3 + Vector3.UP*0.1,"recovering source setup " + id): return false
	for _tick: int in range(MAX_TICKS):
		if not _live(): return false
		var actor: Node3D = _actor(id)
		if actor.get("phase") == "recovery" and _hero.get_threat_response_state().stable:
			var hp: float = float(actor.get("hp"))
			var result: Dictionary = actor.call("take_damage",10000.0,Vector3.ZERO)
			_setup.append({"kind":"gated-actor-injury","id":id,"clock_s":_clock(),"hp_before":hp,"hp_after":actor.get("hp"),"result":_encode(result),"scope":"TEST_ONLY public native recovery-gated damage, not primary/defeat route credit"})
			if not _expect(result.get("accepted",false) and float(result.get("hp_damage",0.0)) == hp and float(actor.get("hp")) == 0.0,"actual gate accepts labelled public TEST defeat " + id + ": " + str(result)): return false
			for _step_index: int in range(2): await _step()
			return _expect(_state().defeated_ids.has(id),"real callback transaction flushes earned setup defeat " + id)
		await _step()
	return _expect(false,"bounded real recovery before TEST injury " + id + str(_state()))
func _wait_quiet(id: String) -> bool:
	for _tick: int in range(MAX_TICKS):
		if not _live(): return false
		if _native(id).status != "running": return true
		await _step()
	return _expect(false,"bounded actual consumer cleanup after labelled defeat: " + id)
func _test_place(at: Vector3,purpose: String) -> bool:
	if not _live() or _hero.action_in_progress(): return _expect(false,"TEST placement requires native quiet living Hero")
	_hero.global_position = at
	_setup.append({"kind":"hero-placement","position":_encode(at),"purpose":purpose,"scope":"TEST_ONLY actual feet placement; no navigation/WorldAction claim"})
	for _tick: int in range(12): await _step()
	return _expect(_live() and _hero.is_on_floor() and _hero.get_threat_response_state().stable,"labelled representative placement settles on native supported floor: " + purpose)

func _dash(direction: Vector3) -> bool:
	var ready: bool = false
	for _tick: int in range(MAX_TICKS):
		if not _live(): return false
		var response: Dictionary = _hero.get_threat_response_state()
		if not paused and response.stable and float(response.dash_cooldown_left_s) == 0.0 and float(response.commitment_remaining_s) == 0.0 and not _hero.action_in_progress(): ready = true; break
		await _step()
	if not _expect(ready,"bounded actual native dash readiness"): return false
	var sequence: int = _sequence()
	if not _routed_swipe(direction.normalized()): return false
	for _tick: int in range(MAX_TICKS):
		await _step()
		if not _live(): return false
		if _sequence() > sequence:
			var action: Dictionary = _actions.back()
			return _expect(action.kind == "dash" and action.landing == _hero.global_position and not _hero.action_in_progress(),"actual completed dash/action record uses deliberate stopped world landing")
	return _expect(false,"bounded native completed dash")
func _step() -> void:
	if _capture and paused: _resume_capture_focus_pause()
	await _probe.tick_finished
	if not _live(): return
	if _mixed_follow and _pair_running(): _mixed_seen = true
	for source: String in ["first_scout","second_handler","final_scout","final_handler"]:
		var state: Dictionary = _native(source)
		if state.status == "running":
			if not _phases.has(source): _phases[source] = {}
			_phases[source][state.phase] = true
	var error: String = String(_state().get("runtime_error",""))
	if not error.is_empty(): _expect(false,"actual O3 runtime error: " + error); _abort = true
func _all_phases(source: String) -> bool: return _phases.get(source,{}).has_all(["warning","lock","active","recovery"])
func _state() -> Dictionary: return _level.call("encounter_state") if is_instance_valid(_level) else {}
func _clock() -> float: return float(_level.call("get_scheduler").call("get_clock")) if is_instance_valid(_level) else 0.0
func _pair_running() -> bool: return _native("final_scout").status == "running" and _native("final_handler").status == "running"
func _actor(id: String) -> Node3D: return _level.call("get_actor",id) as Node3D
func _native(id: String) -> Dictionary:
	if SCOUTS.has(id): return _level.call("get_exchange").call("state",id)
	var state: Dictionary = _level.call("get_tool",id).call("state")
	state["proof"] = _level.call("get_tool_proof",id)
	return state
func _sequence() -> int:
	var records: Array[Dictionary] = _hero.get_world_action_records()
	return int(records.back().sequence) if not records.is_empty() else 0
func _live() -> bool: return not _abort and is_instance_valid(_game) and is_instance_valid(_level) and is_instance_valid(_hero) and not _hero.dead
func _screen_delta(direction: Vector3) -> Vector2:
	var right: Vector3 = (_game.get("camera") as Camera3D).global_basis.x
	var down: Vector3 = (_game.get("camera") as Camera3D).global_basis.z
	right.y = 0.0
	down.y = 0.0
	return Vector2(direction.dot(right.normalized()), direction.dot(down.normalized())) * 120.0

func _routed_swipe(direction: Vector3) -> bool:
	var before: int = int(_game.get_input_observation_state().sequence)
	var start: Vector2 = Vector2(0.5, 0.60) * root.get_visible_rect().size
	var end: Vector2 = start + _screen_delta(direction)
	if not _expect(_game.screen_to_direction(end - start).is_equal_approx(direction.normalized()), "actual camera maps selected native dash to exact swipe direction"): return false
	var press := InputEventScreenTouch.new()
	press.index = 13; press.pressed = true; press.position = start
	root.push_input(press, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 13; drag.position = end; drag.relative = end - start
	root.push_input(drag, true)
	var release := InputEventScreenTouch.new()
	release.index = 13; release.position = end
	root.push_input(release, true)
	var input: Dictionary = _game.get_input_observation_state()
	var dash: Dictionary = _hero.get_committed_dash_state()
	return _expect(int(input.sequence) == before + 1 and input.last_observation.get("kind") == "swipe_release" and _game.get_aim_anchor_normalized().is_equal_approx(end / root.get_visible_rect().size) and dash.get("active", false) and dash.direction.is_equal_approx(direction.normalized()), "real routed swipe commits shared dash and exact final-release anchor")

func _routed_primary(direction: Vector3) -> int:
	var before: int = _actions.size()
	var input_before: int = int(_game.get_input_observation_state().sequence)
	var position: Vector2 = _game.get_aim_anchor() + _screen_delta(direction)
	if not _expect(_game.aim_direction(position).is_equal_approx(direction.normalized()), "actual first-tap aim derives from last swipe final release"): return 0
	var press := InputEventScreenTouch.new()
	press.index = 14; press.pressed = true; press.position = position
	root.push_input(press, true)
	var release := InputEventScreenTouch.new()
	release.index = 14; release.position = position
	root.push_input(release, true)
	var input: Dictionary = _game.get_input_observation_state()
	if not _expect(int(input.sequence) == input_before + 1 and input.last_observation.get("kind") == "primary_tap" and input.last_observation.get("accepted", false) and _actions.size() == before + 1 and _actions.back().kind == "primary", "real routed first tap immediately publishes one ordinary primary, no blast"): return 0
	return int(_actions.back().hits)


func _same(a: Variant,b: Variant) -> bool:
	var encoded: String = Exact.stringify(a)
	return not encoded.is_empty() and encoded == Exact.stringify(b)

func _prepare_capture_root() -> bool:
	var options: Array[String] = []
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--a2-o3-capture-root="): options.append(argument.trim_prefix("--a2-o3-capture-root="))
	if not _expect(options.size() == 1 and options[0].begins_with(OWNED_CAPTURE_PREFIX),"one explicit owned new O3 capture leaf/images root"): return false
	var tail: String = options[0].trim_prefix(OWNED_CAPTURE_PREFIX)
	var parts: PackedStringArray = tail.split("/",false)
	var regex: RegEx = RegEx.new(); regex.compile("^[A-Za-z0-9][A-Za-z0-9_-]*$")
	if not _expect(parts.size() == 2 and parts[1] == "images" and regex.search(parts[0]) != null and tail == parts[0]+"/images/","capture path is exactly one owned new packet/images child"): return false
	var parent: String = ProjectSettings.globalize_path(OWNED_CAPTURE_PREFIX+parts[0]+"/")
	var images: String = ProjectSettings.globalize_path(options[0])
	if not _expect(DirAccess.dir_exists_absolute(parent) and not DirAccess.dir_exists_absolute(images) and not FileAccess.file_exists(options[0]),"fresh capture never replaces any prior output"): return false
	if not _expect(DirAccess.make_dir_absolute(images) == OK,"create only fresh owned images directory"): return false
	_capture_root = options[0]; return true
func _resume_capture_focus_pause() -> void:
	if not _capture or not paused or not _live(): return
	var before: Dictionary = {"level_clock_s":_clock(),"player_clock_s":_hero.get_threat_response_state().action_clock_s,"hp":_hero.hp,"position":_hero.global_position,"actions":_hero.get_world_action_records()}
	_game.call("resume_lab")
	var after: Dictionary = {"level_clock_s":_clock(),"player_clock_s":_hero.get_threat_response_state().action_clock_s,"hp":_hero.hp,"position":_hero.global_position,"actions":_hero.get_world_action_records()}
	_expect(not paused and before == after,"public graphical Resume preserves actual clocks/HP/pose/action history")
	_capture_resume_events.append({"before":_encode(before),"after":_encode(after),"reason":"observed production pause during graphics automation"})
func _capture_view(label: String,scope: String,expected_plan: Dictionary = {}) -> void:
	_capture_pending = true
	var live_frame: bool = false
	for _frame: int in range(4):
		if paused: _resume_capture_focus_pause()
		await RenderingServer.frame_post_draw
		if not paused: live_frame = true; break
	if not _expect(live_frame and _live(),"bounded live post-draw native portrait " + label): _capture_pending = false; return
	if not expected_plan.is_empty():
		if not _expect(_same_plan(expected_plan) and _clock()+DERIVED_EPS < float(expected_plan.next_action_s),"original proof/cycle and future action deadline survive post-draw before pixels " + label): _capture_pending = false; return
	var points: Array[Vector3] = []
	points.assign(_game.call("player_camera_framing_points"))
	points.append_array(_level.camera_framing_points())
	var subject: Dictionary = {}
	if label in ["scout-lock","handler-lock"]:
		var id: String = "first_scout" if label == "scout-lock" else "second_handler"
		var current: Dictionary = _native(id)
		_expect(current.status == "running" and current.phase == "lock","postdraw retains original real native lock " + id)
	elif label == "mixed-pair":
		_expect(_pair_running(),"postdraw retains actual two-owner mixed native union")
	elif label == "quiet-wall":
		# Actual layer-1 Box transforms include support and the reused villa
		# wall even if floor_regions deliberately excludes the fixed blocker.
		_record_static_boxes(_level,subject)
	# Required gameplay union stays authoritative; scenic decoration does not
	# become a new required camera target. Owner separately inspects actual pixels.
	var framing: String = _game.call("camera_framing_error",points)
	_expect(framing.is_empty(),"actual required Hero/source/cue/landing/grace framing " + label + ": " + framing)
	var picture: Image = root.get_texture().get_image()
	var path: String = _capture_root+label+".png"
	if not _expect(not FileAccess.file_exists(path),"original new-job pixels never overwrite old image " + label): _capture_pending = false; return
	_expect(picture != null and picture.get_size() == Vector2i(540,1170) and picture.save_png(path) == OK,"actual540x1170 original portrait " + label)
	_frames.append({"label":label,"scope":scope,"hero_position":_encode(_hero.global_position),"hero_hp":_hero.hp,"hero_shells":_hero.shells,"hero_on_floor":_hero.is_on_floor(),"state":_encode(_state()),"checkpoint":_level.current_checkpoint(),"completed":_level.is_completed(),"actual_actions":_encode(_actions),"labelled_test_setups":_setup.duplicate(true),"portrait_subject":subject,"required_points":_encode(points),"camera_error":framing,"image_path":path,"image_sha256":FileAccess.get_sha256(path)})
	_capture_pending = false
func _wait_capture() -> void:
	for _frame: int in range(120):
		if not _capture_pending: return
		await process_frame
	_expect(false,"bounded outstanding portrait post-draw completion")
func _write_metadata() -> void:
	var labels: Array[String] = []
	for frame: Dictionary in _frames: labels.append(frame.label)
	_expect(labels == LABELS,"exact actual entry/Scout lock/quiet wall/Handler lock/mixed pair/opened exit portrait labels")
	var packet: Dictionary = {"api_revision":"act2-o3-focused-preview-1","scope":"actual ordinary first Scout/second Handler/final mixed proof responses plus disclosed public gated injury/contact/portrait setups; no Shell/earned route/all-kit/balance claim","checks":_checks,"failures":_failures,"scope_complete":_scope_complete,"frames":_frames,"capture_environment_resume_events":_capture_resume_events,"source_files":_sources(),"art_accepted":false}
	var encoded: String = Exact.stringify(packet)
	if not _expect(not encoded.is_empty() and not FileAccess.file_exists(_capture_root+"metadata.exact.json"),"finite native exact metadata fits shared budget and preserves every prior original"): return
	var file: FileAccess = FileAccess.open(_capture_root+"metadata.exact.json",FileAccess.WRITE)
	if not _expect(file != null,"new native portrait metadata output opens"): return
	packet.checks = _checks; packet.failures = _failures
	file.store_string(Exact.stringify(packet)+"\n"); file.close()
func _sources() -> Dictionary:
	var pins: Dictionary = {}
	for path: String in [O3_PATH,"res://scripts/acts/act2/bleached_canal.gd","res://scripts/acts/act2/bleached_canal_kit.gd","res://scripts/acts/act2/ray_scout_exchange.gd","res://scripts/acts/act2/salvage_handler_actor.gd","res://scripts/combat/lane_mechanism.gd","res://scripts/game.gd","res://scripts/player.gd"]: pins[path] = FileAccess.get_sha256(path)
	return pins
func _encode(value: Variant) -> Variant:
	if value is Vector3: return [value.x,value.y,value.z]
	if value is Vector2: return [value.x,value.y]
	if value is Rect2: return {"diagnostic_native_type":"Rect2","position":_encode(value.position),"size":_encode(value.size)}
	if value is Basis: return {"x":_encode(value.x),"y":_encode(value.y),"z":_encode(value.z)}
	if value is int and (value < -9007199254740991 or value > 9007199254740991): return {"diagnostic_native_integer_decimal":str(value)}
	if value is Dictionary:
		var dict: Dictionary = {}
		for key: Variant in value: dict[String(key)] = _encode(value[key])
		return dict
	if value is Array:
		var array: Array = []
		for item: Variant in value: array.append(_encode(item))
		return array
	return value
func _native_mesh_bounds(node: Node) -> Array[Vector3]:
	var native: Array[Vector3] = []
	_append_mesh_bounds(node,native)
	if native.is_empty(): return []
	var bounds: AABB = AABB(native[0],Vector3.ZERO)
	for point: Vector3 in native: bounds = bounds.expand(point)
	var result: Array[Vector3] = []
	for index: int in range(8): result.append(bounds.get_endpoint(index))
	return result
func _record_static_boxes(node: Node,into: Dictionary) -> void:
	if node is CollisionShape3D and node.shape is BoxShape3D and node.get_parent() is StaticBody3D:
		var body: StaticBody3D = node.get_parent() as StaticBody3D
		if (body.collision_layer & 1) != 0:
			var bounds: AABB = AABB(-node.shape.size*0.5,node.shape.size)
			var points: Array[Vector3] = []
			for index: int in range(8): points.append(node.global_transform*bounds.get_endpoint(index))
			into[String(_level.get_path_to(node))] = {"world_corners":_encode(points),"disabled":node.disabled,"collision_layer":body.collision_layer}
	for child: Node in node.get_children(): _record_static_boxes(child,into)
func _append_mesh_bounds(node: Node,into: Array[Vector3]) -> void:
	if node is MeshInstance3D and is_instance_valid(node.mesh) and node.is_visible_in_tree():
		for index: int in range(8): into.append(node.global_transform*node.mesh.get_aabb().get_endpoint(index))
	for child: Node in node.get_children(): _append_mesh_bounds(child,into)
func _refs(node: Node,into: Array[WeakRef]) -> void:
	into.append(weakref(node))
	for child: Node in node.get_children(): _refs(child,into)
func _release() -> void:
	await _wait_capture()
	var refs: Array[WeakRef] = []
	if is_instance_valid(_game):
		_refs(_game,refs)
		if is_instance_valid(_level): _level.exit_level()
		_game.queue_free()
	_game = null; _level = null; _hero = null; paused = false
	for _frame: int in range(4): await process_frame
	var freed: bool = true
	for ref: WeakRef in refs: freed = freed and ref.get_ref() == null
	_expect(freed and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(),"actual whole Main/Player/actors/Exchange/Lanes/Scenery/cues release")
func _expect(ok: bool,note: String) -> bool:
	_checks += 1
	if not ok: _failures += 1; push_error("FAIL A2-O3 focused: " + note)
	return ok
func _finish() -> void:
	if _review:
		print("A2-O3 focused smoke: %d checks, %d failures; scope_complete=%s; one completed pair exact quiet restore/separated available exit portrait, labelled supported feet/normal follow. No new mechanics/route/Shell/art/balance/mobile claim" % [_checks,_failures,str(_scope_complete)])
		quit(0 if _failures == 0 else 1); return
	print("A2-O3 focused smoke: %d checks, %d failures; scope_complete=%s; actual ordinary first Scout + second Handler + final mixed response/full cooldown/noammo/extremes, labelled recovery injuries/placements/brief portraits. No full route/Shell stamp/side-return/all-kit balance/mobile claim" % [_checks,_failures,str(_scope_complete)])
	quit(0 if _failures == 0 else 1)
