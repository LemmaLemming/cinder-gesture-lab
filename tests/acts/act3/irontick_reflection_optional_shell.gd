extends "res://tests/acts/act3/pillars_before_time_optional_shell.gd"
## Final O3 bounded public Optional jobs consume genuinely earned whole archives. Reuse only the unchanged
## accepted O1 generic Shell/ExactJson/GUI/quiet/identity/cleanup helpers.
## TEST ONLY O3 accepted metadata + prefix13; actual accepted A3-L3 Story packet.
## No Hero/resource/clock/history/death/lease/progress writes or packet transplant.
## Separate jobs cover held transport, earned CP1, earned CP2 and completion/return.
## Fresh Replay entry preserves the existing stamp; no repeated Replay clear claim.

const O3_STORY_ID: String = "A3-L3"
const O3_STORY_PATH: String = "res://scenes/acts/act3/a3_l3_mirror_sea.tscn"
const O3 = preload("res://scripts/acts/act3/irontick_reflection.gd")
const Focused = preload("res://tests/acts/act3/irontick_reflection_focused.gd")
const NativeObservers = preload("res://tests/acts/act3/pillars_before_time_focused.gd")
const O3_PATH: String = "res://scenes/acts/act3/a3_o3_irontick_reflection.tscn"
const O3_ECHO: String = "o3-first-echo"
const O3_PULSE: String = "o3-first-pulse"
const O3_ADOPTED: String = "d180506738ebaa9774d791593dab70eaed618d05"
const O3_PINS: Array[String] = [
	"res://tests/acts/act3/irontick_reflection_optional_shell.gd",
	"res://tests/acts/act3/irontick_reflection_portrait.gd",
	"res://tests/acts/act3/irontick_reflection_focused.gd",
	"res://tests/acts/act3/pillars_before_time_focused.gd",
	"res://tests/acts/act3/pillars_before_time_optional_shell.gd",
	"res://scripts/acts/act3/irontick_reflection.gd",
	"res://scripts/acts/act3/irontick_reflection_codec.gd",
	"res://scenes/acts/act3/a3_o3_irontick_reflection.tscn",
	"res://data/campaign/act3/a3_o3_encounters.json",
	"res://scripts/acts/act3/mirror_echo.gd",
	"res://scripts/acts/act3/mirror_echo_codec2.gd",
	"res://scripts/acts/act3/mirror_echo_codec.gd",
	"res://scripts/acts/act3/mirror_echo_spent_marker.gd",
	"res://scripts/acts/act3/mirror_sea_scenery.gd",
	"res://scripts/acts/act3/mirror_sea_level.gd",
	"res://scripts/acts/act3/mirror_sea_codec.gd",
	"res://scripts/acts/act3/mirror_sea_vignettes.gd",
	"res://scripts/acts/act3/mirror_shore_modules.gd",
	"res://scripts/acts/act3/mirror_shore_witnesses.gd",
	"res://scripts/acts/act3/mirror_irontick_scenery.gd",
	"res://scripts/acts/act3/sunbound_stalker.gd",
	"res://data/campaign/act3/mirror_sea_layout_candidate.json",
	"res://scenes/acts/act3/a3_l3_mirror_sea.tscn",
	"res://scripts/acts/act3/twin_suns_scenery.gd",
	"res://assets/acts/act3/mirror_shore.gdshader",
	"res://scripts/combat/replay_playback.gd",
	"res://scripts/combat/replay_footprint.gd",
	"res://scripts/combat/replay_witness.gd",
	"res://scripts/combat/authored_enemy_sequence.gd",
	"res://scripts/combat/authored_echo_terminal_receipt.gd",
	"res://scripts/combat/authored_echo_cycle_journal.gd",
	"res://scripts/combat/lane_mechanism.gd",
	"res://scripts/combat/threat_scheduler.gd",
	"res://scripts/combat/body_sweep.gd",
	"res://scripts/combat/threat_geometry.gd",
	"res://scripts/campaign/shell.gd",
	"res://scripts/campaign/level.gd",
	"res://scripts/campaign/registry.gd",
	"res://scripts/campaign/attempts.gd",
	"res://scripts/campaign/save_store.gd",
	"res://scripts/campaign/exact_json.gd",
	"res://scripts/campaign/snapshot_codec.gd",
	"res://scripts/player.gd",
	"res://scripts/game.gd",
	"res://scripts/hud.gd",
	"res://scripts/ui/campaign_menu.gd",
	"res://scripts/equipment.gd",
	"res://data/design/player_equipment.json",
]

var _selector: String = "held-transport"
var _entrance: Dictionary = {}
var _archive_provenance: Dictionary = {}
var _barrier: NativeObservers.PostActorBarrier
var _live_hero: CinderPlayer
var _live_level: CinderLevel
var _live_scheduler: CinderThreatScheduler
var _live_kit: Dictionary = {}
var _live_hp: float = 0.0
var _fired: Array[String] = []
var _native_ticks: int = 0

func _initialize() -> void:
	isolated = "user://test-a3-o3-optional-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	old_audio = AudioServer.generate_bus_layout()
	old_fps = Engine.max_fps
	_run.call_deferred()

func _run() -> void:
	create_timer(600.0,true,false,true).timeout.connect(func() -> void:
		if not finished:
			_expect(false,"bounded selected final O3 public job")
			_finish())
	root.size=Vector2i(340,736)
	root.content_scale_size=root.size
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	canonical_bytes=FileAccess.get_file_as_string(Registry.DATA_PATH)
	var args: PackedStringArray=OS.get_cmdline_user_args()
	var original: String=""
	if args==PackedStringArray(["--earn-cp1"]): _selector="earn-cp1"
	elif args.size()==1 and args[0].begins_with("--earn-cp2=res://captures/act3/irontick-reflection/"): _selector="earn-cp2"; original=args[0].trim_prefix("--earn-cp2=")
	elif args.size()==1 and args[0].begins_with("--completion-return=res://captures/act3/irontick-reflection/"): _selector="completion-return"; original=args[0].trim_prefix("--completion-return=")
	elif not args.is_empty(): _expect(false,"explicit bounded final O3 selector"); await _finish(); return
	if not _expect(DisplayServer.get_name()=="headless","selected transport jobs require native headless; no portrait credit"): await _finish(); return
	node_added.connect(_watch_node)
	if original.is_empty():
		if not await _fresh_optional(): await _finish(); return
	else:
		if not _load_original_archive(original,"cp1" if _selector=="earn-cp2" else "cp2") or not await _new_shell(expected_session): await _finish(); return
		production.menu.resume_requested.emit()
		if not await _wait_installed("A3-O3","resume",held) or not _installed(held) or not _quiet_selected() or not _disk(expected_session): await _finish(); return
		if not await _retry_original_checkpoint(): await _finish(); return
	print("O3 TEST ONLY prefix13/readiness; actual accepted L3 Story; selector=",_selector,"; original whole packets only, no source/journal/progress transplant")
	if _selector=="held-transport": scope_complete=await _held_transport()
	elif _selector=="earn-cp1": scope_complete=await _earn_checkpoint(0)
	elif _selector=="earn-cp2": scope_complete=await _earn_checkpoint(1)
	else: scope_complete=await _complete_return()
	await _finish()

func _seed_story(registry: CinderCampaignRegistry) -> bool:
	paused = true
	preview = MainScene.instantiate()
	preview.set("level_scene_path", O3_STORY_PATH)
	root.add_child(preview)
	preview.call("open_bench") # Main construction resumes; restore the actual public paused boundary before any frame.
	var actor: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var camera: Camera3D = preview.get("camera") as Camera3D
	if not _expect(actor != null and level != null and camera != null and level.level_id == O3_STORY_ID and String(preview.get("level_load_error")).is_empty(), "actual accepted L3 Main opening constructs the protected Story donor"):
		return false
	await process_frame # Native ready/layout only; gameplay remains paused.
	var actor_state: Dictionary = actor.snapshot_state()
	var local_state: Dictionary = level.snapshot_state()
	var input: Dictionary = preview.call("get_input_observation_state")
	if not _expect(paused and not actor_state.is_empty() and not local_state.is_empty() and actor.get_world_action_records().is_empty() and input.sequence == 0 and input.last_observation.is_empty(), "actual paused initial actor/local/input writers contain no fabricated gameplay", actor.last_snapshot_error + "; " + level.last_snapshot_error):
		return false
	var anchor: Vector2 = input.anchor_normalized
	var fresh_shell: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": input.sequence, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Game.CAMERA_OFFSET), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}
	protected = {"schema_version": 1, "level_id": O3_STORY_ID, "scene_path": O3_STORY_PATH, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": actor_state, "level": local_state, "shell": fresh_shell}
	var detached = Attempts.new(registry)
	expected_session = detached.state()
	expected_session.completed_main = registry.main_route().slice(0, 13) # TEST ONLY predecessor completions.
	expected_session.story = {"kind": "story", "level_id": O3_STORY_ID, "snapshot": protected.duplicate(true), "checkpoint": protected.duplicate(true)}
	var problem: String = detached.state_error(expected_session)
	var writer = Store.new(isolated + "campaign.json")
	writer.payload_validator = detached.saved_payload_error # Structural model, never a live Shell validator.
	if not _expect(problem.is_empty() and expected_session.completed_main[-1] == O3_STORY_ID and writer.write_payload(expected_session), "detached structural Attempts/format2 Store seed TEST prefix13 plus actual complete accepted L3 opening packet", problem + "; " + writer.last_error):
		return false
	var refs: Array[WeakRef] = []
	_collect_refs(preview, refs)
	level.exit_level()
	preview.queue_free()
	preview = null
	return await _released(refs, "seed donor normal whole-tree retirement") and _disk(expected_session)

func _wait_echo_warning() -> bool:
	for _frame: int in range(LIVE_FRAME_LIMIT):
		await process_frame
		if not _valid_shell() or production.player.dead: return _expect(false,"genuine initial Echo warning keeps actual Hero alive")
		if not paused and not _held_receipt().is_empty(): return true
	return _expect(false,"bounded genuine initial final-layout warning",str(production.active_level.call("state")))

func _held_receipt() -> Dictionary:
	var level: CinderLevel=production.active_level
	var sources: Dictionary=level.get("sources")
	var echo: Node3D=sources.get(O3_ECHO) as Node3D
	var pulse: CinderLaneMechanism=level.get("mechanism") as CinderLaneMechanism
	var scheduler: CinderThreatScheduler=level.get("threat_scheduler") as CinderThreatScheduler
	if not is_instance_valid(echo) or not is_instance_valid(pulse) or not is_instance_valid(scheduler): return {}
	var actor: Dictionary=echo.call("get_source_state")
	var playback: Dictionary=echo.call("state")
	var control: Dictionary=scheduler.source_control_state(echo)
	var bindings: Dictionary=level.call("scheduler_bindings")
	if actor.get("source_id")!=O3_ECHO or actor.get("phase")!="warning" or actor.get("alive")!=true or playback.get("status")!="running" or not playback.get("cursor") is Dictionary or playback.cursor.get("armed")!=false or control.get("reservations",[]).size()!=1: return {}
	var lease: Dictionary=control.reservations[0]
	if not lease.get("adapter") is Dictionary or lease.adapter.get("kind")!="authored_replay" or lease.adapter.get("locked")!=false or lease.id!=playback.reservation_id or lease.state!="warning" or scheduler.get_clock()>=float(lease.lock_from_s): return {}
	if bindings.owners.get(O3_ECHO)!=echo or bindings.owners.get(O3_PULSE)!=pulse or control.source_instance_id!=echo.get_instance_id() or int(lease.response_actor_instance_id)!=production.player.get_instance_id() or control.clock_s!=scheduler.get_clock() or actor.clock_s!=scheduler.get_clock() or actor.generation!=playback.generation or not echo.call("source_cycles_managed"): return {}
	var pulse_state: Dictionary=pulse.state()
	return {"source_id":O3_ECHO,"source_epoch":actor.source_epoch,"generation":actor.generation,"playback_id":playback.playback_id,"phase":"warning","reservation_id":playback.reservation_id,"armed":false,"clock_s":scheduler.get_clock(),"hp":actor.hp,"alive":actor.alive,"pulse_status":pulse_state.status,"pulse_phase":pulse_state.phase,"pulse_cycle":pulse_state.cycle}

func _native_ids() -> Dictionary:
	var result: Dictionary=_core_ids()
	var level: CinderLevel=production.active_level
	result.scheduler=(level.get("threat_scheduler") as Node).get_instance_id()
	var sources: Dictionary=level.get("sources")
	result.source=(sources[O3_ECHO] as Node).get_instance_id()
	for id: String in sources:
		result["source/"+id]=(sources[id] as Node).get_instance_id()
		if O3.ECHO_IDS.has(id): result["renderer/"+id]=(sources[id].call("get_authored_echo_renderer") as Node).get_instance_id()
	var pulse: CinderLaneMechanism=level.get("mechanism") as CinderLaneMechanism
	result.pulse=pulse.get_instance_id()
	result.pulse_cue=pulse.get_cue().get_instance_id()
	result.scenery=(level.get("scenery") as Node).get_instance_id()
	result.exit_cue=(level.get("exit_cue") as Node).get_instance_id()
	var reflected: Dictionary=level.get("reflections")
	for id: String in reflected: result["reflection/"+id]=(reflected[id] as Node).get_instance_id()
	var bindings: Dictionary=level.call("scheduler_bindings")
	for id: String in bindings.owners: result["owner/"+id]=(bindings.owners[id] as Node).get_instance_id()
	for id: String in bindings.floors:
		var collision: CollisionShape3D=bindings.floors[id].collision
		result["collision/"+id]=collision.get_instance_id()
		result["floor/"+id]=collision.get_parent().get_instance_id()
	return result

func _archive_held(entrance: Dictionary, receipt: Dictionary) -> bool:
	return _archive_state("held-warning",entrance,receipt)

func _watch_node(node: Node) -> void:
	if not is_instance_valid(production) or not production.is_ancestor_of(node) or watched.has(node.get_instance_id()): return
	watched[node.get_instance_id()] = true
	for row: Dictionary in node.get_signal_list():
		if row.name in ["fired", "died", "action_resolved", "world_action_executed", "hit_resolved", "source_hit_resolved", "source_defeated", "event_dispatched", "checkpoint_requested", "completion_requested", "contact_exit_requested"] and row.args.size() <= 3:
			node.connect(row.name, Callable(self, "_event" + str(row.args.size())).bind(str(node.get_instance_id()), String(row.name)))

func _expect(ok: bool, label: String, detail: String = "") -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL O3 optional Shell: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok

func _finish() -> void:
	if finished: return
	finished=true
	if is_instance_valid(_barrier):
		var ref: WeakRef=weakref(_barrier)
		if _barrier.waiting: _barrier._wake("normal_finish")
		if _barrier.presentation_waiting: _barrier._wake_presentation("normal_finish")
		_barrier.queue_free(); _barrier=null
		await _released([ref],"normal native observer cleanup")
	await _dispose_shell()
	if is_instance_valid(preview):
		var refs: Array[WeakRef]=[]
		_collect_refs(preview,refs)
		preview.queue_free(); preview=null
		await _released(refs,"remaining actual Story donor cleanup")
	if node_added.is_connected(_watch_node): node_added.disconnect(_watch_node)
	paused=false
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(),"normal final Optional whole owner/cue cleanup")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH)==canonical_bytes,"canonical registry unchanged")
	for filename: String in ["campaign.json","campaign.json.bak","settings.json","settings.json.bak","preferences.json","preferences.json.bak"]:
		if FileAccess.file_exists(isolated+filename): DirAccess.remove_absolute(ProjectSettings.globalize_path(isolated+filename))
	AudioServer.set_bus_layout(old_audio)
	Engine.max_fps=old_fps
	print("O3 final Optional Shell: %d checks/%d failures; scope_complete=%s; selector=%s; native ticks=%d; actual original packets/selected public flow/normal cleanup only; no second Replay clear, all-kit/full-route/human/pacing/portrait credit."%[checks,failures,str(scope_complete),_selector,_native_ticks])
	quit(0 if failures==0 and scope_complete else 1)


func _fresh_optional() -> bool:
	var parsed: Variant=JSON.parse_string(canonical_bytes)
	if not _expect(parsed is Dictionary,"canonical registry read-only"): return false
	raw=parsed.duplicate(true)
	for row: Dictionary in raw.levels:
		if row.id=="A3-O3": row.scene_path=O3_PATH; row.readiness="accepted"; row.accepted_commit="b".repeat(40); row.api_revision=Registry.API_REVISION
	var registry=Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A3-O3").is_empty() and registry.entry("A3-O3").parent_level_id==O3_STORY_ID,"TEST O3 metadata retains real accepted parent",registry.last_error): return false
	if not await _seed_story(registry) or not await _new_shell(expected_session): return false
	production.menu.continue_story_requested.emit()
	if not await _wait_installed(O3_STORY_ID,"resume",protected) or not _installed(protected) or not _quiet_selected(): return false
	var refs: Array[WeakRef]=[]
	_collect_refs(_world_container(),refs)
	var ids: Dictionary=_core_ids()
	production.menu.optional_requested.emit("A3-O3")
	if not await _wait_installed("A3-O3","resume",{},ids): return false
	_entrance=production.capture_campaign_snapshot()
	checkpoint=production.attempts.state().side_attempt.checkpoint.duplicate(true)
	if not _installed(_entrance) or not await _released(refs,"Optional entry retires actual L3 World"): return false
	var state: Dictionary=production.active_level.call("state")
	return _expect(_same(checkpoint,_entrance) and _same(production.attempts.state().story,expected_session.story) and _entrance.level.local_snapshot_version==2 and not _entrance.level.progress.completed and _entrance.level.progress.checkpoint_ids.is_empty() and state.route.active_stage==0 and state.route.clears.is_empty() and state.route.deaths.is_empty() and state.sources.size()==4 and _entrance.level.local.scheduler.authored_source_cycles.sources.size()==3 and production.player.get_world_action_records().is_empty(),"fresh final Optional retains all three native journals and pristine entrance")

func _held_transport() -> bool:
	if not await _resume_after_layout() or not await _wait_echo_warning(): return false
	production.request_pause()
	if not await _wait_pause(): return false
	held=production.capture_campaign_snapshot()
	var receipt: Dictionary=_held_receipt()
	if not _expect(not receipt.is_empty() and _same(production.attempts.active_snapshot(),held) and _same(production.attempts.state().side_attempt.checkpoint,checkpoint) and held.level.progress.checkpoint_ids.is_empty() and not _same(held,checkpoint),"actual held warning remains separate from pristine entrance"): return false
	if not _installed(held) or not _disk(production.attempts.state()) or not _archive_held(_entrance,receipt): return false
	var saved: Dictionary=production.attempts.state()
	var ids: Dictionary=_native_ids()
	if not await _dispose_shell() or not await _new_shell(saved): return false
	production.menu.resume_requested.emit()
	if not await _wait_installed("A3-O3","resume",held) or not _installed(held) or not _distinct(ids) or not _quiet_selected(): return false
	if not _expect(_same(_held_receipt(),receipt) and _same(production.attempts.state(),saved),"fresh disk Side Resume preserves original all-journal warning"): return false
	if not await _retry_original_checkpoint() or not await _leave_side(): return false
	return _expect(production.attempts.state().completed_optional.is_empty() and production.attempts.state().reward_ids.is_empty(),"early held return grants no stamp")

func _retry_original_checkpoint() -> bool:
	var refs: Array[WeakRef]=[]
	_collect_refs(_world_container(),refs)
	var ids: Dictionary=_native_ids()
	receiver_events.clear()
	production.menu.retry_requested.emit()
	if not await _wait_installed("A3-O3","resume",checkpoint,ids) or not _installed(checkpoint) or not _distinct(ids) or not _quiet_selected() or not await _released(refs,"public Retry retires complete original native World"): return false
	if not _expect(_same(production.attempts.active_snapshot(),checkpoint) and _same(production.attempts.state().side_attempt.checkpoint,checkpoint) and _same(production.attempts.state().story,expected_session.story),"Retry restores exact original checkpoint and protected Story"): return false
	if not _disk(production.attempts.state()): return false
	return await _gui_resume(checkpoint)

func _leave_side() -> bool:
	var refs: Array[WeakRef]=[]
	_collect_refs(_world_container(),refs)
	var ids: Dictionary=_core_ids()
	production.menu.leave_side_requested.emit()
	if not await _wait_installed(O3_STORY_ID,"journey",protected,ids) or not _installed(protected) or not await _released(refs,"Leave Side retires whole final Optional World"): return false
	return _expect(production.attempts.state().side_attempt==null and _same(production.attempts.state().story,expected_session.story) and production.attempts.state().completed_main==expected_session.completed_main,"Leave Side restores protected whole L3 Story/Journey") and _disk(production.attempts.state())

func _bind_live() -> bool:
	_live_hero=production.player
	_live_level=production.active_level
	_live_scheduler=_live_level.get("threat_scheduler") as CinderThreatScheduler
	_live_kit=_live_hero.equipment.snapshot()
	_live_hp=_live_hero.hp
	_fired.clear()
	_live_hero.fired.connect(func(kind: String) -> void: _fired.append(kind))
	if not is_instance_valid(_barrier):
		_barrier=NativeObservers.PostActorBarrier.new()
		root.add_child(_barrier)
	return _expect(paused and _live_level.local_snapshot_version==2 and _live_level.get("sources").size()==4 and _live_hp==_live_hero.max_hp,"actual final live recipient binds three Echoes/C50 with unchanged full kit")

func _driver(stage: int) -> RefCounted:
	var driver=Focused.EchoDriver.new()
	driver.configure(_live_hero,_live_level,_live_scheduler,O3.ECHO_IDS[stage],_live_kit,_driver_actions,_driver_fired,_tick_live,_presentation_live,_expect)
	return driver

func _driver_actions() -> Array:
	return _live_hero.get_world_action_records()
func _driver_fired() -> Array[String]:
	return _fired

func _tick_live() -> bool:
	for _frame: int in range(FRAME_LIMIT):
		if finished or not _valid_shell(): return false
		if paused: await process_frame; continue
		_barrier.waiting=true
		_barrier.expiration=Engine.get_process_frames()+FRAME_LIMIT
		var boundary: String=await _barrier.observed
		if finished: return false
		if boundary=="paused_notification": continue
		_native_ticks+=1
		return _expect(boundary=="post_actor_physics" and not paused and _native_ticks<=6000 and production.player==_live_hero and production.active_level==_live_level and not _live_hero.dead and _live_hero.hp==_live_hp and _live_hero.equipment.snapshot()==_live_kit and String((_live_level.call("state") as Dictionary).configuration_error).is_empty(),"real bounded post-actor production tick retains full HP/kit/recipient")
	return _expect(false,"bounded automatic native Shell transaction resumes")

func _presentation_live() -> bool:
	for _frame: int in range(FRAME_LIMIT):
		if finished or not _valid_shell(): return false
		if paused: await process_frame; continue
		_barrier.presentation_waiting=true
		_barrier.presentation_expiration=Engine.get_process_frames()+FRAME_LIMIT
		var boundary: String=await _barrier.presentation_observed
		if finished: return false
		if boundary=="unexpected_paused_process": continue
		return _expect(boundary=="post_presentation_process" and not paused and production.player==_live_hero and not _live_hero.dead and _live_hero.hp==_live_hp,"actual native Camera/HUD process precedes capture")
	return _expect(false,"bounded native presentation after Shell transaction")

func _earn_checkpoint(stage: int) -> bool:
	if not _bind_live() or not await _resume_after_layout(): return false
	var driver: RefCounted=_driver(stage)
	if not bool(await driver.call("clear_current_stage",stage==0)): return false
	var count: int=stage+1
	for _frame: int in range(FRAME_LIMIT):
		if not _valid_shell() or production.player.dead: return false
		var side: Variant=production.attempts.state().side_attempt
		if side!=null and side.checkpoint.level.progress.checkpoint_id==O3.CHECKPOINT_IDS[stage]:
			checkpoint=side.checkpoint.duplicate(true)
			break
		await process_frame
	if not _expect(checkpoint.level.progress.checkpoint_id==O3.CHECKPOINT_IDS[stage] and checkpoint.level.local.route.active_stage==count and checkpoint.level.local.route.clears.size()==count and checkpoint.level.local.route.deaths.size()==count and not checkpoint.level.progress.completed,"genuine durable CP follows coherent next-stage activation"): return false
	production.request_pause()
	if not await _wait_pause(): return false
	held=production.capture_campaign_snapshot()
	return _installed(held) and _disk(production.attempts.state()) and _archive_state("cp1" if count==1 else "cp2",_entrance)

func _archive_state(kind: String, entrance: Dictionary, receipt: Dictionary = {}) -> bool:
	var snapshot: Dictionary=production.capture_campaign_snapshot()
	if not _expect(paused and not snapshot.is_empty() and _same(production.attempts.active_snapshot(),snapshot),"archive only actual paused whole native session"): return false
	archive_path="res://captures/act3/irontick-reflection/optional-%s-%d-%d"%[kind,OS.get_process_id(),Time.get_ticks_usec()]
	if not _expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(archive_path)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(archive_path))==OK,"new whole original archive preserves previous bytes"): return false
	var values: Dictionary={"session.native.json":production.attempts.state(),"held.native.json":snapshot,"entrance.native.json":entrance,"checkpoint.native.json":production.attempts.state().side_attempt.checkpoint,"story.native.json":protected,"start-session.native.json":expected_session,"registry.native.json":raw}
	var files: Dictionary={}
	for name: String in values:
		var wire: String=Exact.stringify(values[name])
		var file: FileAccess=FileAccess.open(archive_path.path_join(name),FileAccess.WRITE)
		if not _expect(not wire.is_empty() and file!=null,"original finite full archive file opens: "+name): return false
		file.store_string(wire+"\n"); file.close()
		files[name]={"sha256":FileAccess.get_sha256(archive_path.path_join(name)),"exact_wire_sha256":wire.sha256_text()}
	var pins: Dictionary={}
	for path: String in O3_PINS:
		var digest: String=FileAccess.get_sha256(path)
		if not _expect(digest.length()==64,"actual selected final source pin exists: "+path): return false
		pins[path]=digest
	var manifest: Dictionary={"schema_version":2,"kind":"a3-o3-final-session-2","archive_kind":kind,"test_only":true,"adopted_baseline_commit":O3_ADOPTED,"shared_api":"campaign-shared-62","source_pins":pins,"files":files,"held_receipt":receipt,"source_scope":"actual listed final source pins plus runner exact HEAD/input manifest; no prototype packet transplant","test_context":"TEST O3 metadata/prefix13 around actual accepted L3 Story; all source/death/checkpoint/journal state genuinely earned","validation":"pending actual runner closure; archive creation alone earns no public-flow result"}
	var file: FileAccess=FileAccess.open(archive_path.path_join("manifest.json"),FileAccess.WRITE)
	var wire: String=Exact.stringify(manifest)
	if not _expect(file!=null and not wire.is_empty(),"complete finite original archive manifest opens"): return false
	file.store_string(wire+"\n");file.close()
	print("O3 final original archive: ",archive_path,"; kind=",kind,"; manifest_sha256=",FileAccess.get_sha256(archive_path.path_join("manifest.json")))
	return true

func _original_packet(name: String) -> Dictionary:
	var path: String=archive_path.path_join(name)
	if not _expect(_archive_provenance.files.has(name) and FileAccess.get_sha256(path)==_archive_provenance.files[name].sha256,"original whole packet checksum: "+name): return {}
	var parsed: Dictionary=Exact.parse(FileAccess.get_file_as_string(path))
	if not _expect(parsed.get("accepted",false) and parsed.get("value") is Dictionary,"native exact original packet: "+name): return {}
	var packet: Dictionary=parsed.value
	return packet if _expect(Exact.stringify(packet).sha256_text()==_archive_provenance.files[name].exact_wire_sha256,"original native wire checksum: "+name) else {}

func _load_original_archive(path: String, expected_kind: String) -> bool:
	archive_path=path
	var parsed: Dictionary=Exact.parse(FileAccess.get_file_as_string(path.path_join("manifest.json")))
	if not _expect(parsed.get("accepted",false) and parsed.get("value") is Dictionary,"original final archive manifest parses"): return false
	_archive_provenance=parsed.value
	if not _expect(_archive_provenance.get("kind")=="a3-o3-final-session-2" and _archive_provenance.get("archive_kind")==expected_kind and _archive_provenance.get("test_only")==true and _archive_provenance.get("source_pins") is Dictionary and _archive_provenance.get("files") is Dictionary,"exact final original archive kind; no prototype transplant"): return false
	for source_path: String in _archive_provenance.source_pins:
		if not _expect(FileAccess.get_sha256(source_path)==_archive_provenance.source_pins[source_path],"unchanged original final source authority: "+source_path): return false
	raw=_original_packet("registry.native.json")
	expected_session=_original_packet("session.native.json")
	held=_original_packet("held.native.json")
	checkpoint=_original_packet("checkpoint.native.json")
	protected=_original_packet("story.native.json")
	_entrance=_original_packet("entrance.native.json")
	var original_start: Dictionary=_original_packet("start-session.native.json")
	if failures>0: return false
	if not _expect(expected_session.side_attempt!=null and expected_session.side_attempt.kind=="optional" and expected_session.side_attempt.level_id=="A3-O3" and _same(expected_session.side_attempt.snapshot,held) and _same(expected_session.side_attempt.checkpoint,checkpoint) and _same(expected_session.story.snapshot,protected) and _same(expected_session.story,original_start.story) and protected.level_id==O3_STORY_ID and protected.scene_path==O3_STORY_PATH and held.level.local_snapshot_version==2 and checkpoint.level.local_snapshot_version==2,"strict original complete final session/checkpoint/Story authority"): return false
	var registry=Registry.new(raw)
	var model=Attempts.new(registry)
	var writer=Store.new(isolated+"campaign.json")
	writer.payload_validator=model.saved_payload_error
	paused=true
	return _expect(registry.last_error.is_empty() and model.state_error(expected_session).is_empty() and writer.write_payload(expected_session),"write exact original whole session into isolated Store",registry.last_error+"; "+writer.last_error)

func _complete_return() -> bool:
	var stats: PackedByteArray=var_to_bytes(production.player.stats)
	var unlocks: Array=production.attempts.state().unlocked_equipment.duplicate()
	var gear: Dictionary=production.player.equipment.snapshot()
	var latest: Dictionary=checkpoint.duplicate(true)
	if not _bind_live() or not await _resume_after_layout(): return false
	var driver: RefCounted=_driver(2)
	if not bool(await driver.call("clear_current_stage",false)): return false
	production.request_pause()
	if not await _wait_pause(): return false
	held=production.capture_campaign_snapshot()
	var before: Dictionary=production.attempts.state()
	var stalker: Node=production.active_level.get("sources")[O3.STALKER_ID]
	var stamp: String=production.registry.entry("A3-O3").reward_id
	if not _expect(held.level.progress.completed and held.level.progress.completion_id==O3.COMPLETION_ID and held.level.progress.contact_exit_id.is_empty() and held.level.local.route.active_stage==3 and held.level.local.route.clears.size()==3 and held.level.local.route.deaths.size()==3 and not stalker.get("dead") and float(stalker.get("hp"))>0 and _same(before.side_attempt.checkpoint,latest) and before.completed_optional==["A3-O3"] and before.reward_ids==[stamp] and _same(before.story,expected_session.story) and _same(before.unlocked_equipment,unlocks) and var_to_bytes(production.player.stats)==stats,"third actual Echo clear stamps once with no CP3 and living final Stalker"): return false
	var exact_before: String=Exact.stringify(held)
	var events: PackedByteArray=var_to_bytes(receiver_events)
	if not _expect(not production.active_level.request_completion(O3.COMPLETION_ID) and exact_before==Exact.stringify(production.capture_campaign_snapshot()) and _same(before,production.attempts.state()) and events==var_to_bytes(receiver_events),"duplicate completed public request refuses atomically"): return false
	if not _installed(held) or not _disk(before): return false
	var owner: WeakRef=weakref(production.active_level)
	production.active_level.contact_exit_requested.connect(_observe_contact.bind(owner))
	var refs: Array[WeakRef]=[]
	_collect_refs(_world_container(),refs)
	var ids: Dictionary=_core_ids()
	if not await _resume_after_layout() or not await _o3_exit_approach(): return false
	if not await _wait_installed(O3_STORY_ID,"journey",protected,ids) or not _installed(protected) or not await _released(refs,"actual contact retires whole final World"): return false
	if not _expect(not contact_receipts.is_empty() and production.attempts.active_kind()=="story" and production.attempts.state().side_attempt==null and _same(production.attempts.state().story,expected_session.story),"later grounded contact returns protected Story/Journey"): return false
	var completed: Dictionary=production.attempts.state()
	var story_refs: Array[WeakRef]=[]
	_collect_refs(_world_container(),story_refs)
	var story_ids: Dictionary=_core_ids()
	production.menu.replay_requested.emit("A3-O3",gear)
	if not await _wait_installed("A3-O3","resume",{},story_ids): return false
	var fresh: Dictionary=production.capture_campaign_snapshot()
	if not _installed(fresh) or not await _released(story_refs,"fresh public Replay retires Story recipient"): return false
	if not _expect(production.attempts.active_kind()=="replay" and not fresh.level.progress.completed and fresh.level.progress.checkpoint_ids.is_empty() and fresh.level.local.route.deaths.is_empty() and _same(production.attempts.state().completed_optional,completed.completed_optional) and _same(production.attempts.state().reward_ids,completed.reward_ids) and _same(production.attempts.state().story,expected_session.story) and production.player.equipment.snapshot()==gear,"fresh Replay entry preserves already-once stamp; no second completion claim"): return false
	return await _leave_side()

func _observe_contact(id: String, exit_id: String, owner: WeakRef) -> void:
	var level: CinderLevel=owner.get_ref() as CinderLevel
	if not _expect(level!=null and id=="A3-O3" and exit_id==O3.EXIT_ID,"real native final contact identity"): return
	var state: Dictionary=level.call("state")
	contact_receipts[str(level.get_instance_id())]=state.route.contact.duplicate(true)

func _o3_exit_approach() -> bool:
	# A small native geometry plan reaches the authored contact with unchanged
	# full-distance dashes. No Hero placement or controller tuning is performed.
	for _leg: int in range(6):
		if not _valid_shell(): return false
		if production.active_level.level_id == O3_STORY_ID: return true
		var actor: CinderPlayer = production.player
		var start: Vector3 = actor.global_position
		var target: Vector3 = Vector3(O3.EXIT_POSITION.x, start.y, O3.EXIT_POSITION.z)
		var delta: Vector3 = target - start
		var distance: float = float(actor.get_threat_response_state().stats.dash_distance)
		if O3.EXIT_RECT.has_point(Vector2(start.x, start.z)):
			for _frame: int in range(FRAME_LIMIT):
				await process_frame
				if not _valid_shell(): return false
				if production.active_level.level_id == O3_STORY_ID: return true
			return _expect(false, "bounded real grounded authored exit contact")
		var direction: Vector3 = delta.normalized()
		if delta.length() < 2.0 * distance and absf(delta.length() - distance) > 0.01:
			var middle: Vector3 = (start + target) * 0.5
			var sideways: Vector3 = Vector3.UP.cross(direction)
			var height: float = sqrt(maxf(0.0, distance * distance - delta.length_squared() * 0.25))
			var found: bool = false
			for sign_value: float in [1.0, -1.0]:
				var via: Vector3 = middle + sideways * height * sign_value
				var pose: Transform3D = actor.global_transform
				var floors: Array = (production.active_level.call("scheduler_bindings") as Dictionary).floors.values()
				var first: Dictionary = BodySweep.sweep(actor, pose, via - start, floors)
				pose.origin = via
				var second: Dictionary = BodySweep.sweep(actor, pose, target - via, floors)
				if first.has("error") or second.has("error") or first.get("collided", true) or second.get("collided", true): continue
				if (first.end as Vector3).distance_to(via) > 0.005 or (second.end as Vector3).distance_to(target) > 0.005: continue
				direction = (via - start).normalized()
				found = true
				break
			if not _expect(found, "actual body/floor supports a two-dash native approach to the north exit", str({"start": start, "target": target})): return false
		if not await _o3_contact_dash(direction): return false
	return _expect(false, "bounded six-dash genuine exit approach")


func _o3_contact_dash(direction: Vector3) -> bool:
	for _frame: int in range(LIVE_FRAME_LIMIT):
		await process_frame
		if not _valid_shell(): return false
		if production.active_level.level_id == O3_STORY_ID: return true
		if production.player.dead: return _expect(false, "real contact approach retains living Hero")
		if paused: continue
		var actor: CinderPlayer = production.player
		var response: Dictionary = actor.get_threat_response_state()
		if not response.get("stable", false) or float(response.dash_cooldown_left_s) != 0.0 or actor.action_in_progress(): continue
		var start: Vector3 = actor.global_position
		var motion: Vector3 = direction * float(actor.get_threat_response_state().stats.dash_distance)
		var swept: Dictionary = BodySweep.sweep(actor, actor.global_transform, motion, (production.active_level.call("scheduler_bindings") as Dictionary).floors.values())
		if not _expect(not swept.has("error") and not swept.get("collided", true) and (swept.end as Vector3).distance_to(start + motion) <= 0.005, "actual native exit dash retains full supported body sweep", str(swept)): return false
		var sequence: int = _sequence()
		if not _expect(actor.request_dash(direction), "public Hero accepts actual exit approach dash"): return false
		for _tick: int in range(FRAME_LIMIT):
			await process_frame
			if not _valid_shell(): return false
			if production.active_level.level_id == O3_STORY_ID:
				return _expect(not contact_receipts.is_empty(), "native contact may replace in-flight exit dash; no completed-dash credit")
			if production.player != actor or actor.dead: return _expect(false, "original living actual Hero remains until authored contact")
			var records: Array[Dictionary] = actor.get_world_action_records(sequence)
			if records.size() == 1 and not actor.action_in_progress():
				return _expect(records[0].kind == "dash" and not records[0].blocked and not records[0].collision_shortened and records[0].world_origin == start and records[0].landing == actor.global_position and (records[0].landing as Vector3).distance_to(start + motion) <= 0.005 and not CinderPlayer.encode_world_action_record(records[0], actor.get_world_action_clock()).is_empty(), "genuine completed exit approach dash retains native full-distance record")
		return _expect(false, "bounded real native exit dash/contact transaction")
	return _expect(false, "bounded actual exit dash readiness")



func _dispose_shell() -> bool:
	# Follow the public level lifecycle while the complete native world and its
	# held owners are still in the tree, as in the accepted focused Main fixture.
	# Queue-free alone exits children before Shell._exit_tree can call this hook.
	var retired: bool = true
	if is_instance_valid(production) and is_instance_valid(production.active_level) and production.active_level.is_inside_tree():
		var level: CinderLevel = production.active_level
		var scheduler: CinderThreatScheduler = level.get("threat_scheduler") as CinderThreatScheduler
		level.exit_level()
		if scheduler != null:
			retired = _expect(scheduler.reservations().is_empty(), "public level exit retires actual held owners before whole Shell disposal")
	var disposed: bool = await super._dispose_shell()
	return retired and disposed
