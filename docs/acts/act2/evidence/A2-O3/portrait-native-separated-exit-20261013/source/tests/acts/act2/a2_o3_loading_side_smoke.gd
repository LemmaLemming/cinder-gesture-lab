extends SceneTree
## TMP DRAFT: O3 exact optional/replay/Story and latest before-third checkpoint.
## TEST_ONLY prior prefix/readiness, native Hero placements and public gated
## Actor injuries arrange progression. No phase/proof/HP/clock/gate/pending seed.
## Complete native mixed pair and one-member-defeated units restore from disk
## quietly in both legal orders; naturally absent pending paths stay unexecuted.
const Shell: Script = preload("res://scripts/campaign/shell.gd")
const Registry: Script = preload("res://scripts/campaign/registry.gd")
const Attempts: Script = preload("res://scripts/campaign/attempts.gd")
const Store: Script = preload("res://scripts/campaign/save_store.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact: Script = preload("res://scripts/campaign/exact_json.gd")
const Lane: Script = preload("res://scripts/combat/lane_mechanism.gd")
const Ray: Script = preload("res://scripts/acts/act2/ray_scout_exchange.gd")
const Scheduler: Script = preload("res://scripts/combat/threat_scheduler.gd")
const Interaction: Script = preload("res://scripts/cues/interaction_cue.gd")
const Threat: Script = preload("res://scripts/cues/threat_cue.gd")
const MainScene: PackedScene = preload("res://scenes/main.tscn")
const STORY_PATH: String = "res://scenes/acts/act2/dead_london.tscn"
const O3_PATH: String = "res://scenes/acts/act2/a2_o3.tscn"
const CP_ID: String = "bleached-canal-before-final-pocket"
const COMPLETE_ID: String = "bleached-canal-complete"
const EXIT_ID: String = "bleached-canal-return"
const CP_AT: Vector3 = Vector3(0,0.04,-18.3)
const EXIT_AT: Vector3 = Vector3(0,0.04,-26)
const SCOUTS: Array[String] = ["first_scout","final_scout"]
const LOCAL_KEYS: Array[String] = ["scenic_clock","profile_id","world_revision","stage_index","defeated_ids","defeat_times","pending_defeats","checkpoint_contact_seen","checkpoint_requested","pending_checkpoint","completion_pending","exit_requested","scheduler","actors","exchange","tools","views"]
const PREFIX: Array[String] = ["A1-L1","A1-L2","A1-L3","A1-L4","A1-L5","A2-L1","A2-L2","A2-L3","A2-L4"]
const ORDERS: Array[Array] = [["final_scout","final_handler"],["final_handler","final_scout"]]
const MAX_TICKS: int = 900
class NativeTickProbe extends Node:
	signal tick_finished
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 120
	func _physics_process(_delta: float) -> void: tick_finished.emit()
var _checks: int = 0
var _failures: int = 0
var _finished: bool = false
var _test_root: String
var _raw: Dictionary
var _registry_bytes: String
var _shell: CinderCampaignShell
var _preview: Node
var _probe: NativeTickProbe
var _events: Array[String] = []
var _disposal_observations: Array[Dictionary] = []
var _expected_retry_donor: WeakRef
var _watch: bool = false
var _old_audio: AudioBusLayout
var _old_fps: int
var _setups: Array[Dictionary] = []
var _later_actions: Array[Dictionary] = []
func _initialize() -> void:
	_test_root = "user://test-a2-o3-loading-%d/" % OS.get_process_id()
	_old_audio = AudioServer.generate_bus_layout(); _old_fps = Engine.max_fps
	_run.call_deferred()
func _run() -> void:
	root.size = Vector2i(540,1170); root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_probe = NativeTickProbe.new(); root.add_child(_probe); node_added.connect(_observe_added)
	_registry_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH); _raw = JSON.parse_string(_registry_bytes)
	for row: Dictionary in _raw.levels:
		if row.id == "A2-O3": row.scene_path = O3_PATH; row.readiness = "accepted"; row.accepted_commit = "e".repeat(40); row.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(_raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A2-O3").is_empty(),"TEST readiness retains actual O3 contract/parent/reward"): _finish(); return
	_expect(not registry.is_unlocked("A2-O3",PREFIX.slice(0,PREFIX.size()-1)) and registry.is_unlocked("A2-O3",PREFIX),"actual parent-clear unlock rule; TEST history is disclosed")
	if not await _seed_story(registry) or not await _new_shell(): _finish(); return
	_shell.menu.continue_story_requested.emit(); await _settle()
	var story: Dictionary = _shell.capture_campaign_snapshot()
	_shell.menu.optional_requested.emit("A2-O3"); await _settle()
	if not _expect(_live() and paused and _shell.attempts.active_kind() == "optional","public initial Optional installs native O3 paused: " + _shell.campaign_error): _finish(); return
	var entrance: Dictionary = _shell.capture_campaign_snapshot()
	var protected: Dictionary = _shell.attempts.story_snapshot()
	_expect(_same(protected,story) and _same(_shell.attempts.state().side_attempt.checkpoint,entrance),"complete actual A2-L5 Story and pristine optional entrance protected")
	_expect(entrance.level.local.size() == LOCAL_KEYS.size() and entrance.level.local.has_all(LOCAL_KEYS) and entrance.level.local.actors.size() == 4 and entrance.level.local.tools.size() == 2 and entrance.level.local.exchange.actors.size() == 2 and entrance.level.local.stage_index == 0 and entrance.level.local.defeated_ids.is_empty(),"initial exact17/four actors/two rays/two tools finite empty prefix")
	var input: Dictionary = _shell.get_input_observation_state(); _shell.handle_tap(root.get_visible_rect().size*0.5)
	_expect(_shell.get_input_observation_state() == input and _same(_shell.capture_campaign_snapshot(),entrance),"paused Resume overlay consumes tap without action/aim/motion mutation")
	_expect(not _shell.active_level.request_contact_exit(EXIT_ID,_shell.player),"uncleared exit refuses")
	_shell.menu.resume_requested.emit()
	for _tick: int in range(8): await _probe.tick_finished
	_shell.request_pause(); await _settle()
	var quiet: Dictionary = _shell.capture_campaign_snapshot()
	if not _expect(paused and not quiet.is_empty() and quiet.level.local.scheduler.clock_s > 0.0,"real simulation reaches complete public pause"): _finish(); return
	if not await _disk_restore(quiet,"initial native quiet unit"): _finish(); return
	_shell.menu.leave_side_requested.emit(); await _settle()
	_expect(paused and _shell.menu.page_name() == "journey" and _same(_shell.capture_campaign_snapshot(),protected) and _shell.attempts.state().reward_ids.is_empty(),"early Leave restores exact Story and awards nothing")
	_shell.menu.difficulty_preference_requested.emit("challenge")
	for order: Array in ORDERS:
		var selected: Dictionary = {"jacket":"CLOTH-J0","pants":"CLOTH-P0","shoes":"CLOTH-S0","weapon":"WEAPON-03"}
		var replay: bool = _shell.attempts.state().completed_optional.has("A2-O3")
		if replay: _shell.menu.replay_requested.emit("A2-O3",selected)
		else: _shell.menu.optional_requested.emit("A2-O3")
		await _settle()
		if not _expect(_live() and paused and _shell.attempts.active_kind() == ("replay" if replay else "optional"),"supported fresh optional or completed Replay namespace"): _finish(); return
		_expect(_shell.capture_campaign_snapshot().level.local.profile_id == "challenge" and (_shell.player.equipment.snapshot() == selected if replay else true),"fresh Challenge/replay selected canonical weapon without replacing protected Story gear")
		protected = _shell.attempts.story_snapshot()
		for id: String in ["first_scout","second_handler"]:
			if not await _test_defeat(id): _finish(); return
			if not await _wait_quiet(id): _finish(); return
		_expect(_state().stage_index == 2 and _state().defeated_ids == ["first_scout","second_handler"] and int(_native("final_scout").cycle) == 0 and int(_native("final_handler").cycle) == 0,"two actual setup defeats reach before-final with zero future cycles")
		if not await _test_contact(Vector3(0,0.04,-21.8)): _finish(); return
		_expect(_state().stage_index == 2 and not _state().checkpoint_committed and int(_native("final_scout").cycle) == 0 and int(_native("final_handler").cycle) == 0,"actual final proximity cannot admit either source before durable before-third checkpoint")
		if not await _test_contact(CP_AT): _finish(); return
		_shell.request_pause(); await _settle()
		var checkpoint: Dictionary = _shell.attempts.state().side_attempt.checkpoint
		if not _expect(paused and _shell.active_level.current_checkpoint().id == CP_ID and checkpoint.level.progress.checkpoint_id == CP_ID and checkpoint.level.local.stage_index == 3 and int(checkpoint.level.local.exchange.records.final_scout.cycle) == 0 and int(checkpoint.level.local.tools.final_handler.cycle) == 0 and checkpoint.level.local.actors.final_scout.hp == 30.0 and checkpoint.level.local.actors.final_handler.hp == 30.0,"actual durable latest before-third checkpoint precedes both final admissions"): _finish(); return
		if not await _mixed_transport(): _finish(); return
		if not await _test_defeat(String(order[0])): _finish(); return
		var survivor: String = String(order[1])
		for _tick: int in range(MAX_TICKS):
			if not _live() or _shell.player.dead: break
			if _native(survivor).status == "running": break
			await _probe.tick_finished
		_shell.request_pause(); await _settle()
		var one: Dictionary = _shell.capture_campaign_snapshot()
		if not _expect(paused and not one.is_empty() and one.level.local.actors[order[0]].hp == 0.0 and one.level.local.actors[survivor].hp == 30.0 and _native(survivor).status == "running","actual one-member-dead/survivor-running unit in legal order " + str(order)): _finish(); return
		if not await _disk_restore(one,"one-member-defeated " + str(order)): _finish(); return
		_shell.menu.resume_requested.emit()
		for _tick: int in range(2): await _probe.tick_finished
		if not await _later_primary_before_retry(order): _finish(); return
		_shell.player.take_damage(_shell.player.max_hp*4.0,Vector3.ZERO); await _settle()
		if not _expect(paused and _shell.player.dead and _shell.campaign_error.is_empty(),"public TEST lethal injury freezes later pair state"): _finish(); return
		var dead: Dictionary = _shell.capture_campaign_snapshot()
		if not await _click("ResumeButton"): _finish(); return
		_expect(paused and _same(dead,_shell.capture_campaign_snapshot()),"actual dead Resume GUI cannot replace frozen unit")
		_events.clear(); _watch = true
		var disposal_start: int = _disposal_observations.size()
		_expected_retry_donor = weakref(_shell.active_level)
		var retry_clicked: bool = await _click("RetryButton")
		_expected_retry_donor = null
		_watch = false
		if not retry_clicked: _finish(); return
		var retried: Dictionary = _shell.capture_campaign_snapshot()
		var differences: Array[Dictionary] = []
		_exact_snapshot_differences(checkpoint,retried,"$",differences)
		print("O3 passive exact Retry comparison: ",Exact.stringify(_encode({"live":_live(),"paused":paused,"same":_same(retried,checkpoint),"events_empty":_events.is_empty(),"events":_events.duplicate(),"campaign_error":_shell.campaign_error,"differences":differences,"difference_limit":20})))
		if not _expect(_live() and paused and _same(retried,checkpoint) and _events.is_empty(),"real latest before-third GUI Retry restores exact living Player/resources/profile/aim/clocks/two final sources and protected namespace"): _finish(); return
		var donor_disposals: int = 0
		var donor_flags: bool = true
		for record: Dictionary in _disposal_observations.slice(disposal_start):
			if not record.get("donor_match",false): continue
			donor_disposals += 1
			donor_flags = donor_flags and record.boundary == "expected_retry_donor" and record.emitter_inside_tree == true and record.nearest_level_entered == false and record.nearest_level_lifecycle_busy == true and record.nearest_level_restore_candidate == false
		_expect(donor_disposals > 0 and donor_flags,"actual expected Retry donor emits only observed in-tree retirement notifications after entered=false/lifecycle_busy=true/candidate=false")
		_expect(_same(_shell.attempts.story_snapshot(),protected),"latest checkpoint Retry retains the whole protected Story")
		# Earn the finite objective through disclosed real recovery-gated setup.
		for id: String in order:
			if not await _test_defeat(id) or not await _wait_quiet(id): _finish(); return
		for _tick: int in range(MAX_TICKS):
			if not _live() or _shell.active_level.is_completed(): break
			await _probe.tick_finished
		_shell.request_pause(); await _settle()
		var completed: Dictionary = _shell.capture_campaign_snapshot()
		if not _expect(paused and not completed.is_empty() and _shell.active_level.is_completed() and completed.level.local.stage_index == 4 and completed.level.local.defeated_ids == ["first_scout","second_handler"]+order,"third actual arrangement clears through finite supported progression: " + _shell.campaign_error): _finish(); return
		if not _completed_epoch_rejection(completed): _finish(); return
		print("O3 actual completed snapshot export: ",Exact.stringify(completed))
		_expect(_shell.attempts.state().completed_optional == ["A2-O3"] and _shell.attempts.state().reward_ids == ["A2-O3-completion-stamp"] and _shell.attempts.state().completed_main == PREFIX,"once-only cosmetic stamp with no main progression/farming")
		_expect(not _shell.active_level.request_completion(COMPLETE_ID),"duplicate completion refuses")
		if not await _test_contact(EXIT_AT,true): _finish(); return
		await _settle()
		_expect(paused and _shell.menu.page_name() == "journey" and _shell.attempts.active_kind() == "story" and _same(_shell.capture_campaign_snapshot(),protected),"separate actual contact exit returns exact Story to Journey")
	_shell.menu.continue_story_requested.emit(); await _settle()
	_expect(paused and _shell.menu.page_name() == "resume" and _same(_shell.capture_campaign_snapshot(),protected),"explicit Continue Story remains paused Resume after side return")
	# Remove the complete Shell without pre-calling level.exit_level: the actual
	# native tree-exit fallback must not query removed-world transforms.
	var retired: Array = _refs(_shell); root.remove_child(_shell); _shell.free(); _shell = null
	_expect(_refs_freed(retired),"direct detached whole-Shell fallback frees all original descendants")
	_finish()
func _completed_epoch_rejection(completed: Dictionary) -> bool:
	# Retained Ray receipts are internally consistent at world2, while this
	# actual completed Scheduler/tools/local world remain the authored world1.
	# Corrupt only a duplicate: no live actor/phase/proof/clock/HP mutation.
	var bad: Dictionary = completed.duplicate(true)
	var exchange: Dictionary = bad.level.local.exchange
	var schema: bool = exchange.configuration.get("world_revision") == 1 and exchange.records.size() == SCOUTS.size() and exchange.records.has_all(SCOUTS)
	for id: String in SCOUTS:
		schema = schema and exchange.records[id].exchange.has("world_revision") and exchange.records[id].exchange.world_revision == 1
	if not _expect(schema,"actual completed Ray configuration and both retained exchange receipts expose existing world1 fields"): return false
	exchange.configuration.world_revision = 2
	for id: String in SCOUTS: exchange.records[id].exchange.world_revision = 2
	var preserved: bool = bad.level.local.world_revision == 1 and bad.level.local.scheduler.world_revision == 1 and _same(bad.level.local.scheduler,completed.level.local.scheduler) and _same(bad.level.local.tools,completed.level.local.tools)
	var error: String = _shell.active_level.snapshot_error_with_player(bad.level,completed.player)
	var preflight_unchanged: bool = _same(_shell.capture_campaign_snapshot(),completed)
	var refused: bool = not _shell.active_level.restore_state(bad.level)
	print("O3 completed Ray epoch refusal: ",error)
	return _expect(preserved and error.contains("Canal fixed original Scout encounter/world/profile differs") and preflight_unchanged and refused and _same(_shell.capture_campaign_snapshot(),completed),"completed internally consistent Ray world2 copy refuses at actual authored binding with full world1 unit unchanged")
func _later_primary_before_retry(order: Array) -> bool:
	# A real first tap advances this later attempt before the lethal TEST injury.
	# Wait only for native readiness; no actor/phase/proof/clock/resource seed.
	var ready: bool = false
	for _tick: int in range(MAX_TICKS):
		if not _live() or _shell.player.dead: break
		var response: Dictionary = _shell.player.get_threat_response_state()
		if not paused and response.stable and float(response.primary_cooldown_left_s) == 0.0 and float(response.commitment_remaining_s) == 0.0 and not _shell.player.action_in_progress(): ready = true; break
		await _probe.tick_finished
	if not _expect(ready,"bounded actual stable primary readiness after fresh one-member Continue"): return false
	var hero: CinderPlayer = _shell.player
	var before: Dictionary = _shell.get_input_observation_state()
	var records: Array[Dictionary] = hero.get_world_action_records()
	var sequence: int = int(records.back().sequence) if not records.is_empty() else 0
	var at: Vector2 = _shell.get_aim_anchor()+Vector2(0,-120)
	if not _expect(root.get_visible_rect().has_point(at) and at.y >= 100.0,"actual later first-tap point is inside gameplay viewport"): return false
	var direction: Vector3 = _shell.aim_direction(at)
	var resolved: Array[Dictionary] = []
	var observer: Callable = func(kind: String,hits: int,damage: float) -> void: resolved.append({"kind":kind,"hits":hits,"damage":damage})
	hero.action_resolved.connect(observer)
	var press := InputEventScreenTouch.new(); press.index = 17; press.pressed = true; press.position = at
	root.push_input(press,true)
	var release := InputEventScreenTouch.new(); release.index = 17; release.position = at
	root.push_input(release,true)
	hero.action_resolved.disconnect(observer)
	var after: Dictionary = _shell.get_input_observation_state()
	records = hero.get_world_action_records()
	_later_actions.append({"order":order.duplicate(),"input_before":_encode(before),"input_after":_encode(after),"world_action":_encode(records.back()) if not records.is_empty() else {},"resolved":resolved.duplicate(true),"scope":"actual routed later ordinary first tap before TEST death; no target damage or earned-route requirement"})
	return _expect(_live() and not hero.dead and int(after.sequence) == int(before.sequence)+1 and after.last_observation.get("kind") == "primary_tap" and after.last_observation.get("accepted",false) and after.anchor_normalized == before.anchor_normalized and after.last_observation.screen_position_normalized == at/root.get_visible_rect().size and after.last_observation.direction.is_equal_approx(direction) and not records.is_empty() and int(records.back().sequence) == sequence+1 and records.back().kind == "primary" and after.last_observation.world_action_sequence == records.back().sequence and resolved.size() == 1 and resolved[0].kind == "slash" and resolved[0].hits == records.back().hits,"actual later routed first tap advances observation and resolves one completed ordinary world action before lethal injury")
func _mixed_transport() -> bool:
	if not await _test_contact(Vector3(0,0.04,-21.8)): return false
	var reached: bool = false
	for _tick: int in range(MAX_TICKS):
		if not _live() or _shell.player.dead: break
		if _native("final_scout").status == "running" and _native("final_scout").armed and _native("final_handler").status == "running": reached = true; _shell.request_pause(); break
		await _probe.tick_finished
	await _settle()
	var saved: Dictionary = _shell.capture_campaign_snapshot()
	if not _expect(reached and paused and not saved.is_empty(),"representative actual tracked-armed Ray plus native Handler running pair pauses coherently"): return false
	for variant: Dictionary in _corruptions(saved):
		_expect(not _shell.active_level.snapshot_error_with_player(variant.state,saved.player).is_empty() and not _shell.active_level.restore_state(variant.state) and _same(_shell.capture_campaign_snapshot(),saved),"malformed " + variant.label + " refuses atomically")
	_check_pending(saved.level.local)
	var old_profile: String = saved.level.local.profile_id
	_shell.menu.difficulty_preference_requested.emit("assisted")
	if not await _disk_restore(saved,"running final mixed-pair"): return false
	_expect(_shell.capture_campaign_snapshot().level.local.profile_id == old_profile and old_profile == "challenge","new preference does not retune restored native profile")
	_shell.menu.difficulty_preference_requested.emit("challenge")
	return true
func _check_pending(local: Dictionary) -> void:
	var count: int = 0
	for record: Dictionary in local.exchange.records.values():
		for path: Variant in record.get("deferred_paths",[]):
			count += 1
	for tool: Dictionary in local.tools.values():
		if tool.has("pending_segments"):
			var n: int = 0
			for segments: Array in tool.pending_segments.values(): n += segments.size()
			_expect(tool.schema_version == 2 and n > 0,"naturally present Lane schema2 remains full and nonempty")
			count += n
	print("O3 actual naturally retained pending-path pieces: ",count,"; absent paths are unexecuted scope, never manufactured")
func _corruptions(saved: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var bad: Dictionary = saved.level.duplicate(true); bad.local.defeated_ids.append("invented"); out.append({"label":"unknown prefix","state":bad})
	bad = saved.level.duplicate(true); bad.local.defeated_ids.append("first_scout"); out.append({"label":"duplicate prefix","state":bad})
	bad = saved.level.duplicate(true); bad.local.pending_defeats.append({"id":"final_scout","at_s":float(bad.local.scenic_clock)+1.0}); out.append({"label":"future pending defeat","state":bad})
	bad = saved.level.duplicate(true); bad.local.stage_index = 0; out.append({"label":"stage/history mismatch","state":bad})
	bad = saved.level.duplicate(true); bad.local.checkpoint_contact_seen = false; out.append({"label":"unearned CP history","state":bad})
	bad = saved.level.duplicate(true); bad.local.actors.final_handler.root_position[0] += 0.01; out.append({"label":"moved source root","state":bad})
	bad = saved.level.duplicate(true); bad.local.scheduler.reservations[0].source_id = "invented-owner"; out.append({"label":"unbound Scheduler owner reference","state":bad})
	bad = saved.level.duplicate(true); bad.local.scheduler.reservations[0].floors[0].floor_id = "invented-floor"; out.append({"label":"unbound Scheduler floor reference","state":bad})
	bad = saved.level.duplicate(true); bad.local.tools.final_handler.clock_s += 0.000000001; out.append({"label":"exact Lane/Scheduler drift","state":bad})
	bad = saved.level.duplicate(true); bad.local.views.erase("final_handler"); out.append({"label":"missing original running view","state":bad})
	return out
func _test_defeat(id: String) -> bool:
	if not _live(): return false
	paused = true
	var actor: Node3D = _shell.active_level.call("get_actor",id) as Node3D
	_shell.player.global_position = actor.global_position + Vector3.RIGHT*1.3 + Vector3.UP*0.04
	_shell.player.velocity = Vector3.ZERO
	_setups.append({"kind":"TEST feet","id":id,"position":Codec.vector3(_shell.player.global_position)})
	_shell.menu.resume_requested.emit()
	for _tick: int in range(MAX_TICKS):
		await _probe.tick_finished
		if not _live() or _shell.player.dead: return _expect(false,"supported TEST recovery setup remains living "+id)
		if actor.get("phase") != "recovery" or not _shell.player.get_threat_response_state().stable: continue
		var before: float = float(actor.get("hp")); var result: Dictionary = actor.call("take_damage",10000.0,Vector3.ZERO)
		_setups.append({"kind":"TEST public gated injury","id":id,"before":before,"after":actor.get("hp"),"result":_encode(result)})
		if not _expect(result.get("accepted",false) and float(result.hp_damage) == before and actor.get("hp") == 0.0,"actual native recovery gate accepts labelled injury "+id+str(result)): return false
		for _settle_tick: int in range(2): await _probe.tick_finished
		return _expect(_state().defeated_ids.has(id),"actual defeat callback transaction commits "+id)
	return _expect(false,"bounded real recovery before TEST injury "+id+str(_state()))
func _wait_quiet(id: String) -> bool:
	for _tick: int in range(MAX_TICKS):
		if not _live() or _shell.player.dead: return false
		if _native(id).status != "running": return true
		await _probe.tick_finished
	return _expect(false,"bounded real post-defeat consumer quiet "+id)
func _test_contact(at: Vector3,allow_story_return: bool = false) -> bool:
	if not _live(): return false
	paused = true; _shell.player.global_position = at; _shell.player.velocity = Vector3.ZERO
	_setups.append({"kind":"TEST feet","position":Codec.vector3(at)})
	_shell.menu.resume_requested.emit()
	for _tick: int in range(8):
		await _probe.tick_finished
		if paused: break
	if allow_story_return:
		return _expect(is_instance_valid(_shell) and is_instance_valid(_shell.player) and not _shell.player.dead and _shell.attempts.active_kind() == "story" and _shell.campaign_error.is_empty(),"actual exit contact retires O3 and restores living protected Story: "+_shell.campaign_error)
	return _expect(_live() and not _shell.player.dead,"native stable contact/placement remains healthy: "+_shell.campaign_error)
func _disk_restore(expected: Dictionary,label: String) -> bool:
	var refs: Array = _refs(_shell); _shell.free(); _shell = null
	_expect(_refs_freed(refs),"old full native world frees before "+label)
	if not await _new_shell(): return false
	_events.clear(); _watch = true
	_shell.menu.resume_requested.emit(); await _settle(); _watch = false
	return _expect(_live() and paused and _same(_shell.capture_campaign_snapshot(),expected) and _events.is_empty(),"fresh exact quiet disk Continue "+label+": "+_shell.campaign_error+str(_events))
func _seed_story(registry: CinderCampaignRegistry) -> bool:
	paused = true; _preview = MainScene.instantiate(); _preview.set("level_scene_path",STORY_PATH); root.add_child(_preview); paused = true
	await _settle()
	var hero: CinderPlayer = _preview.get("player") as CinderPlayer; var level: CinderLevel = _preview.get("active_level") as CinderLevel
	if not _expect(is_instance_valid(hero) and is_instance_valid(level) and level.level_id == "A2-L5","actual accepted pristine A2-L5 Story fixture"): return false
	var anchor: Vector2 = _preview.call("get_aim_anchor_normalized"); var camera: Camera3D = _preview.get("camera") as Camera3D
	var snapshot: Dictionary = {"schema_version":1,"level_id":"A2-L5","scene_path":STORY_PATH,"paused":true,"equipment_ids":hero.equipment.snapshot(),"player":hero.snapshot_state(),"level":level.snapshot_state(),"shell":{"api_revision":Shell.SHELL_API,"anchor_normalized":[anchor.x,anchor.y],"input_sequence":0,"last_input_observation":{},"camera_focus":Codec.vector3(camera.global_position-Vector3(0,18,13)),"shake_left_s":0.0,"difficulty_at_entry":"standard"}}
	var model: CinderCampaignAttempts = Attempts.new(registry); var payload: Dictionary = model.state(); payload.completed_main = PREFIX.duplicate()
	payload.story = {"kind":"story","level_id":"A2-L5","snapshot":snapshot.duplicate(true),"checkpoint":snapshot.duplicate(true)}
	var store: CinderSaveStore = Store.new(_test_root+"campaign.json"); store.payload_validator = model.saved_payload_error
	var okay: bool = not snapshot.player.is_empty() and not snapshot.level.is_empty() and model.state_error(payload).is_empty() and store.write_payload(payload)
	_expect(okay,"public validated TEST prefix plus actual full Story store: "+model.state_error(payload)+store.last_error)
	level.exit_level(); _preview.free(); _preview = null
	return okay
func _new_shell() -> bool:
	_events.clear(); _watch = true; _shell = Shell.new() as CinderCampaignShell
	if not _expect(_shell.configure_runtime(_raw,_test_root+"campaign.json",_test_root+"settings.json",_test_root+"preferences.json"),"supported isolated Shell before tree entry"): return false
	root.add_child(_shell); await _settle(); _watch = false
	return _expect(paused and _shell.player == null and _shell.menu.page_name() == "title" and _shell.campaign_error.is_empty() and _events.is_empty(),"fresh disk validates at Title quietly: "+_shell.campaign_error+str(_events))
func _click(name: String) -> bool:
	await _settle(); var button: Button = _shell.menu.find_child(name,true,false) as Button
	if not _expect(is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled,"actual enabled GUI "+name): return false
	var presses: Array[String] = []; button.pressed.connect(func() -> void: presses.append(name))
	var at: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new(); motion.position = at; motion.global_position = at; root.push_input(motion,true)
	var press := InputEventMouseButton.new(); press.button_index = MOUSE_BUTTON_LEFT; press.position = at; press.global_position = at; press.pressed = true; root.push_input(press,true)
	var release := press.duplicate() as InputEventMouseButton; release.pressed = false; root.push_input(release,true)
	await _settle()
	return _expect(presses == [name] and _shell.campaign_error.is_empty(),"single actual GUI click settles "+name+": "+_shell.campaign_error)
func _observe_added(node: Node) -> void:
	if not _watch: return
	if node is CinderPlayer:
		node.fired.connect(func(_kind: String) -> void: _events.append("fired")); node.died.connect(func() -> void: _events.append("death"))
		node.world_action_executed.connect(func(_r: Dictionary) -> void: _events.append("action")); node.equipment_changed.connect(func(_id: String) -> void: _events.append("gear"))
		node.action_resolved.connect(func(_kind: String,_hits: int,_damage: float) -> void: _events.append("action-resolved"))
	if node is Act2RayScoutActor: node.connect("defeated",func(_id: String) -> void: _events.append("actor-defeat"))
	if node is CinderLevel:
		node.checkpoint_requested.connect(func(_l: String,_id: String,_k: String) -> void: _events.append("CP")); node.completion_requested.connect(func(_l: String,_id: String) -> void: _events.append("complete")); node.contact_exit_requested.connect(func(_l: String,_id: String) -> void: _events.append("exit"))
	if node.get_script() == Ray:
		node.connect("state_changed",func(_id: String,_s: Dictionary) -> void: _observe_phase_or_cancel("ray-phase",node,_s,_id)); node.connect("scout_defeated",func(_id: String) -> void: _events.append("ray-defeat")); node.connect("hit_resolved",func(_id: String,_r: Dictionary) -> void: _events.append("ray-hit"))
	if node.get_script() == Lane:
		node.connect("state_changed",func(_s: Dictionary) -> void: _observe_phase_or_cancel("lane-phase",node,_s)); node.connect("hit_resolved",func(_id: String,_c: int,_r: Dictionary) -> void: _events.append("lane-hit"))
	if node.get_script() == Scheduler: node.connect("reservation_invalidated",func(_id: String,_r: String) -> void: _observe_phase_or_cancel("cancel",node,{"reservation_id":_id,"reason":_r}))
	if node.get_script() in [Interaction,Threat]: node.connect("state_changed",func(_s: Dictionary) -> void: _observe_phase_or_cancel("cue",node,_s))
	if node is CinderCampaignShell: node.connect("input_observed",func(_r: Dictionary) -> void: _events.append("input"))
func _candidate_disposal_level(node: Node) -> CinderLevel:
	# Exact nearest-level lifecycle boundary observed in retained native Title
	# and Retry failures. Declared flags/expected weak identity are read-only.
	if not is_instance_valid(node) or not node.is_inside_tree(): return null
	var ancestor: Node = node.get_parent()
	while is_instance_valid(ancestor):
		if ancestor is CinderLevel:
			var level: CinderLevel = ancestor as CinderLevel
			if not level.is_inside_tree(): return null
			var entered: Variant = level.get("_entered")
			var busy: Variant = level.get("_lifecycle_busy")
			if not (entered is bool and entered == false and busy is bool and busy == true): return null
			var donor_match: bool = is_instance_valid(_expected_retry_donor) and _expected_retry_donor.get_ref() == level
			return level if level.is_restore_candidate() or donor_match else null
		ancestor = ancestor.get_parent()
	return null
func _observe_phase_or_cancel(kind: String,node: Node,supplied: Dictionary,signal_id: String = "") -> void:
	# Only these presentation/retirement notifications can belong to disposal.
	# Entered/restoring recipients and every gameplay notification stay strict.
	var level: CinderLevel = _candidate_disposal_level(node) if kind in ["ray-phase","lane-phase","cue","cancel"] else null
	if not is_instance_valid(level): _events.append(kind); return
	var scalars: Dictionary = {}
	for key: Variant in supplied:
		var value: Variant = supplied[key]
		if value == null or value is String or value is bool or value is int or value is float: scalars[String(key)] = value
	var donor_match: bool = is_instance_valid(_expected_retry_donor) and _expected_retry_donor.get_ref() == level
	_disposal_observations.append({"kind":kind,"signal_id":signal_id,"supplied_scalars":scalars,"boundary":"expected_retry_donor" if donor_match else "validation_candidate","donor_match":donor_match,"emitter_inside_tree":true,"emitter_instance_id_decimal":str(node.get_instance_id()),"nearest_level_id":level.level_id,"nearest_level_restore_candidate":level.is_restore_candidate(),"nearest_level_entered":level.get("_entered"),"nearest_level_lifecycle_busy":level.get("_lifecycle_busy")})
func _exact_snapshot_differences(old_value: Variant,new_value: Variant,path: String,found: Array[Dictionary]) -> void:
	# Portable copied snapshots only. The original Exact comparison is the
	# authority; no approximate float comparison or repair is introduced.
	if found.size() >= 20 or _same(old_value,new_value): return
	if old_value is Dictionary and new_value is Dictionary:
		var keys: Array = old_value.keys()
		for key: Variant in new_value:
			if not keys.has(key): keys.append(key)
		keys.sort()
		for key: Variant in keys:
			if found.size() >= 20: return
			var at: String = path+"."+String(key)
			if not old_value.has(key) or not new_value.has(key):
				found.append({"path":at,"old_present":old_value.has(key),"new_present":new_value.has(key),"old":_difference_value(old_value.get(key)),"new":_difference_value(new_value.get(key))})
			else: _exact_snapshot_differences(old_value[key],new_value[key],at,found)
		return
	if old_value is Array and new_value is Array:
		for index: int in range(maxi(old_value.size(),new_value.size())):
			if found.size() >= 20: return
			var at: String = path+"[%d]"%index
			if index >= old_value.size() or index >= new_value.size():
				found.append({"path":at,"old_present":index < old_value.size(),"new_present":index < new_value.size(),"old":_difference_value(old_value[index]) if index < old_value.size() else null,"new":_difference_value(new_value[index]) if index < new_value.size() else null})
			else: _exact_snapshot_differences(old_value[index],new_value[index],at,found)
		return
	found.append({"path":path,"old_type":type_string(typeof(old_value)),"new_type":type_string(typeof(new_value)),"old":_difference_value(old_value),"new":_difference_value(new_value)})
func _difference_value(value: Variant) -> Variant:
	# Missing/type-changed containers get a labelled size summary; ordinary
	# differing leaves retain their exact original old/new scalar values.
	return {"diagnostic_container_type":type_string(typeof(value)),"size":value.size()} if value is Dictionary or value is Array else value
func _native(id: String) -> Dictionary:
	if SCOUTS.has(id): return _shell.active_level.call("get_exchange").call("state",id)
	return _shell.active_level.call("get_tool",id).call("state")
func _state() -> Dictionary: return _shell.active_level.call("encounter_state") if _live() else {}
func _live() -> bool: return is_instance_valid(_shell) and is_instance_valid(_shell.active_level) and _shell.active_level.level_id == "A2-O3" and _shell.campaign_error.is_empty()
func _settle() -> void:
	for _frame: int in range(8): await process_frame
func _same(a: Variant,b: Variant) -> bool:
	var s: String = Exact.stringify(a); return not s.is_empty() and s == Exact.stringify(b)
func _refs(node: Node) -> Array:
	var out: Array = [weakref(node)]
	for child: Node in node.get_children(): out.append_array(_refs(child))
	return out
func _refs_freed(refs: Array) -> bool:
	for ref: WeakRef in refs:
		if ref.get_ref() != null: return false
	return not refs.is_empty()
func _encode(v: Variant) -> Variant:
	if v is Vector3: return [v.x,v.y,v.z]
	if v is Vector2: return [v.x,v.y]
	if v is Rect2: return {"diagnostic_native_type":"Rect2","position":_encode(v.position),"size":_encode(v.size)}
	if v is Basis: return {"x":_encode(v.x),"y":_encode(v.y),"z":_encode(v.z)}
	if v is int and (v < -9007199254740991 or v > 9007199254740991): return {"diagnostic_native_integer_decimal":str(v)}
	if v is Dictionary:
		var d: Dictionary = {}
		for k: Variant in v: d[String(k)] = _encode(v[k])
		return d
	if v is Array:
		var a: Array = []
		for x: Variant in v: a.append(_encode(x))
		return a
	return v
func _expect(ok: bool,note: String) -> bool:
	_checks += 1
	if not ok: _failures += 1; push_error("FAIL A2-O3 loading: "+note)
	return ok
func _finish() -> void:
	if _finished: return
	_finished = true; _watch = false; _expected_retry_donor = null
	if is_instance_valid(_preview): _preview.free()
	if is_instance_valid(_shell):
		var refs: Array = _refs(_shell); _shell.free(); _expect(_refs_freed(refs),"complete final Shell descendants freed")
	if is_instance_valid(_probe): _probe.free()
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_bytes,"TEST metadata leaves canonical Registry bytes unchanged")
	for name: String in ["campaign.json","campaign.json.bak","settings.json","settings.json.bak","preferences.json","preferences.json.bak"]:
		var p: String = ProjectSettings.globalize_path(_test_root+name)
		if FileAccess.file_exists(p): DirAccess.remove_absolute(p)
	AudioServer.set_bus_layout(_old_audio); Engine.max_fps = _old_fps
	print("O3 nonplayable disposal observations: ",Exact.stringify(_encode(_disposal_observations)))
	print("O3 labelled public setup: ",Exact.stringify(_setups))
	print("O3 actual later retry input: ",Exact.stringify(_later_actions))
	print("A2-O3 loading smoke: %d checks, %d failures; exact17 optional/replay/protected Story/mixed each-order fresh Continue/later routed ordinary input/latest before-third GUI Retry/completed epoch atomic refusal/stamp/contact/Leave/cleanup. TEST prefix/readiness/public injuries/feet; no earned route/ordinary combat/art/balance claim" % [_checks,_failures])
	quit(0 if _failures == 0 else 1)
