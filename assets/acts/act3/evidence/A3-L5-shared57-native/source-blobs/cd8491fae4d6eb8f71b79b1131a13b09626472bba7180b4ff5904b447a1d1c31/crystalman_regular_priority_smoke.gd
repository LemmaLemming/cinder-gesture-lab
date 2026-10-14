extends "res://tests/acts/act3/crystalman_parent_transport_smoke.gd"
## Default focused mechanics ran1455/0 on Shared56; added transport mode awaits qualification. Initial scene position is
## explicitly representative TEST setup; no earlier enemy/journal death is fake.
## Actual offered C52 original cycles/ordinary public Player primaries produce
## its native death/history/held retirement. Three short ordinary dashes enter
## the unchanged compact C50+C52 priority. No defeat-all/exit/route-clear gate.
## Public Player.request_dash/slash are actual mechanics calls, not OS/gesture
## evidence. Exact current native whole journals/actors are never filtered.
const PRIORITY_ROOM: String="res://tests/acts/act3/fixtures/crystalman_priority_start.tscn"
const Witness=preload("res://scripts/combat/replay_witness.gd")
const OFFERED: String="l5-offered-echo"
const STALKER: String="l5-plain-stalker"
const PLAIN: String="l5-plain-echo"
const CASE_BUDGET_S: float=70.0
class PriorityBarrier:
	extends Node
	signal observed
	var waiting: bool=false
	var expired: bool=false
	var frames: int=0
	func _ready() -> void:
		process_mode=Node.PROCESS_MODE_ALWAYS
		process_physics_priority=3000
	func _physics_process(_delta: float) -> void:
		if waiting and not get_tree().paused:
			waiting=false
			_wake.call_deferred()
	func _process(_delta: float) -> void:
		if waiting:
			frames+=1
			if frames>=120: waiting=false; expired=true; _wake.call_deferred()
	func _wake() -> void: observed.emit()
var regular: CinderLevel
var scheduler: CinderThreatScheduler
var offered: Node3D
var stalker: Node3D
var plain: Node3D
var barrier: PriorityBarrier
var baseline_kit: Dictionary={}
var baseline_hp: float=0.0
var floor_collision: CollisionShape3D
var floor_transform: Transform3D
var floor_size: Vector3
var ticks: int=0
var samples: Array[String]=[]
var events: Array[Dictionary]=[]
var invalidations: Array[Dictionary]=[]
var offered_live_id: int=0
var offered_journal_after_death: Dictionary={}
var baseline_epoch: float=0.0
var observed_echo_leases: Dictionary={}
var _c50_transport_only: bool=false
var _c50_portraits: bool=false
var _c50_draw_seen: bool=false
var _c50_portrait_labels: Array[String]=[]
var _c50_receiver_events: Array[Dictionary]=[]
var _c50_watched: Dictionary={}
var _c50_registry_bytes: String=""
const C50Attempts=preload("res://scripts/campaign/attempts.gd")
var _c50_saved_archive: String=""
const C50_ARCHIVE_FILES: Array[String]=["session.native.json","seed.native.json","registry.native.json"]
const C50_ARCHIVE_SOURCE_PATHS: Array[String]=[
	"res://tests/acts/act3/crystalman_parent_transport_smoke.gd",
	"res://tests/acts/act3/fixtures/crystalman_priority_start.tscn",
	"res://scripts/acts/act3/crystalman_level.gd",
	"res://scripts/acts/act3/crystalman_parent_codec.gd",
	"res://scripts/acts/act3/crystalman_approach_unit.gd",
	"res://scripts/acts/act3/crystalman_approach_codec.gd",
	"res://scripts/acts/act3/sunbound_stalker.gd",
	"res://scripts/acts/act3/mirror_echo.gd",
	"res://scripts/acts/act3/mirror_echo_codec2.gd",
	"res://scripts/player.gd",
	"res://scripts/combat/threat_scheduler.gd",
	"res://scripts/campaign/shell.gd",
	"res://scripts/campaign/attempts.gd",
	"res://scripts/campaign/save_store.gd",
	"res://scripts/campaign/exact_json.gd",
	"res://data/campaign/registry.json",
	"res://data/campaign/act3/crystalman_layout.json",
 ]

func _run() -> void:
	room_path=PRIORITY_ROOM
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()==1 and args[0].begins_with("--c50-saved-portrait="):
		_c50_saved_archive=args[0].trim_prefix("--c50-saved-portrait=")
		if not expect(not _c50_saved_archive.is_empty() and DisplayServer.get_name()!="headless","Saved C50 portrait requires an explicit genuine archive and graphical renderer"): quit(1); return
		_c50_portraits=true
		root.size=Vector2i(340,736)
		root.content_scale_size=root.size
		root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		paused=true
		await _c50_saved_portrait_run()
		if is_instance_valid(production): await _c50_dispose_shell()
		if node_added.is_connected(_c50_watch_new_node): node_added.disconnect(_c50_watch_new_node)
		await close()
		expect(FileAccess.get_file_as_string(Registry.DATA_PATH)==_c50_registry_bytes,"Saved portrait cleanup preserves canonical registry bytes")
		print("Crystalman C50 saved portrait: %d checks/%d failures; actual paused public startup/Continue/native warning/one original image/cleanup only. No Main, live combat recreation, Resume, Save/Retry or new route credit."%[checks,failures])
		quit(0 if failures==0 else 1)
		return
	_c50_transport_only=args.size() in [1,2] and args[0]=="--c50-transport-only"
	_c50_portraits=_c50_transport_only and args.size()==2 and args[1]=="--portrait"
	if not expect(args.is_empty() or (_c50_transport_only and (args.size()==1 or _c50_portraits)),"One focused original regular priority case or explicit C50 transport selector"): quit(1); return
	if _c50_portraits and not expect(DisplayServer.get_name()!="headless","Optional C50 portraits require actual graphical rendering"): quit(1); return
	root.size=Vector2i(340,736)
	root.content_scale_size=root.size
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if await open_regular():
		if await genuine_offered_death():
			if await enter_priority():
				if await genuine_priority():
					if not _c50_transport_only:
						game.call("open_bench")
						await process_frame
						var saved: Dictionary=pair()
						if expect(not saved.level.is_empty(),"Complete actual priority packet before public campaign transport",level.last_snapshot_error): await campaign_transport(saved)
	await close_regular()
	if _c50_transport_only: print("Crystalman C50 transport: original Main/source/floor/barrier cleanup settled; failures="+str(failures))
	if _c50_transport_only:
		print("Crystalman C50 public warning transport SOURCE CANDIDATE: %d checks/%d failures/%d native ticks/samples%s. Genuine offered death/priority/warning; TEST prior-prefix/checkpoint context; public disk startup/Continue/Save/freshContinue/Retry/GUI cleanup. This mode skips prior independent-candidate repetitions, C50 active/recovery/primary and C52 combat; no gesture/full-route/exit/art acceptance."%[checks,failures,ticks,str(samples)])
	else:
		print("Crystalman regular priority source candidate: %d checks/%d failures/%d native ticks/samples%s. Representative initial position/prior story only; actual offered native death/journal and current priority actions. No gesture/full-route/exit/art acceptance."%[checks,failures,ticks,str(samples)])
	quit(0 if failures==0 else 1)

func open_regular() -> bool:
	paused=false
	game=MainScene.instantiate()
	game.set("level_scene_path",room_path)
	root.add_child(game)
	# Match the current base transport startup: reset_lab snaps before entry
	# installs source bounds. Let the ordinary shared camera/HUD pass settle
	# before requesting real Pause; no Player/source/camera pose is rewritten.
	var initial_view_error: String="Initial native view not observed"
	for frame: int in range(90):
		var initial_level: CinderLevel=game.get("active_level") as CinderLevel
		if initial_level!=null:
			initial_view_error=String(initial_level.call("candidate_presentation_error",game.get("camera"),game.get("hud")))
			if initial_view_error.is_empty(): break
		await process_frame
	if not expect(initial_view_error.is_empty(),"Ordinary shared initial camera/HUD contains the actual offered source and Hero",initial_view_error): return false
	game.call("open_bench")
	level=game.get("active_level") as CinderLevel
	hero=game.get("player") as CinderPlayer
	regular=level.get("current_unit") as CinderLevel if level!=null else null
	scheduler=regular.get("threat_scheduler") as CinderThreatScheduler if regular!=null else null
	if not expect(paused and level!=null and hero!=null and regular!=null and scheduler!=null and String(level.get("last_configuration_error")).is_empty() and String(regular.get("last_configuration_error")).is_empty(),"Actual production parent/regular source API enters representative TEST scene"):
		return false
	offered=regular.get("sources")[OFFERED]
	offered_live_id=offered.get_instance_id()
	baseline_kit=hero.equipment.snapshot()
	baseline_hp=hero.hp
	baseline_epoch=hero.get_world_action_clock()
	floor_collision=level.get("floor_collision") as CollisionShape3D
	floor_transform=floor_collision.global_transform
	floor_size=(floor_collision.shape as BoxShape3D).size
	barrier=PriorityBarrier.new()
	root.add_child(barrier)
	watch_live_source(offered,OFFERED)
	scheduler.reservation_invalidated.connect(func(id: String,reason: String) -> void: invalidations.append({"id":id,"reason":reason,"clock_s":scheduler.get_clock()}))
	hero.fired.connect(func(kind: String) -> void: events.append({"kind":"hero_fired","attack":kind,"clock_s":hero.get_world_action_clock()}))
	var snapshot: Dictionary=pair()
	if not expect(not snapshot.level.is_empty() and snapshot.level.local.route.stage==0 and snapshot.level.local.current_unit.state.sources.size()==1 and snapshot.level.local.current_unit.state.deaths.is_empty() and scheduler.get_clock()==baseline_epoch,"Pristine actual offered source/journal has no declared native history",level.last_snapshot_error): return false
	if _c50_portraits and not await _initial_graphical_focus(snapshot): return false
	game.call("resume_lab")
	return true

func _initial_graphical_focus(snapshot: Dictionary) -> bool:
	# One actual native-window request, only at the initial paused TEST setup.
	# Unexpected focus loss during play still fails the unchanged tick guard.
	var input_before: PackedByteArray=var_to_bytes(game.call("get_input_observation_state"))
	var camera: Camera3D=game.get("camera") as Camera3D
	var camera_before: Transform3D=camera.global_transform
	var event_count: int=events.size()
	if not expect(paused and root.visible,"Initial graphical focus is requested only while paused and visible"): return false
	root.grab_focus()
	for _frame: int in range(30):
		await process_frame
		if root.has_focus() and DisplayServer.window_is_focused(root.get_window_id()): break
	var unchanged: bool=paused and same(snapshot,pair()) and input_before==var_to_bytes(game.call("get_input_observation_state")) and camera.global_transform==camera_before and events.size()==event_count
	var observed: Dictionary={"paused":paused,"window_focus":root.has_focus(),"display_focused":DisplayServer.window_is_focused(root.get_window_id()),"whole_pair_input_camera_events_unchanged":unchanged}
	print("Crystalman C50 transport: initial paused native focus observation "+str(observed))
	return expect(unchanged and root.has_focus() and DisplayServer.window_is_focused(root.get_window_id()),"One native focus request preserves exact initial paused gameplay before ordinary Resume",str(observed))

func genuine_offered_death() -> bool:
	# The actual unmodified source has36 HP; use whatever canonical starter
	# primary damage resolves, and at most3 genuine source cycles. No HP write
	# or direct source take_damage injection is used to construct history.
	for _cycle: int in range(3):
		if regular.call("source_dead",OFFERED): break
		var locked: Dictionary=await next_echo_lock(OFFERED,600)
		if locked.is_empty(): return false
		if not await sample_parent("offered-lock-g%d"%int(offered.call("get_authored_cycle_generation"))): return false
		if not await follow_echo(offered,locked): return false
		if not ordinary_primary(offered,OFFERED): return false
		if not await recover_primary(): return false
	if not expect(regular.call("source_dead",OFFERED) and offered.get_instance_id()==offered_live_id and offered.get("hp")==0.0 and not offered.is_in_group("enemies") and scheduler.source_control_state(offered).reservations.is_empty(),"Actual native offered death retires held attacks without replacing/filtering source/journal"): return false
	if not await sample_parent("offered-real-death-retained-journal"): return false
	var saved: Dictionary=pair()
	offered_journal_after_death=journal_source(saved.level.local.current_unit.state.scheduler,OFFERED)
	return expect(not offered_journal_after_death.is_empty() and offered.call("source_hit_receipts").size()>=2 and events.filter(func(row: Dictionary) -> bool: return row.get("kind")=="source_died" and row.get("source")==OFFERED).size()==1,"Original completed/defeated offered managed journal and native hit/death receipts are genuine")

func enter_priority() -> bool:
	game.call("resume_lab")
	# Only the short supported route segment29→19 is traversed. The scene's
	# earlier34→28.7 approach is explicitly omitted by initial TEST spawn.
	for _i: int in range(4):
		if level.call("parent_owned_state").stage==1: break
		if not await ready_for_dash(): return false
		var start: Vector3=hero.global_position
		if not expect(hero.request_dash(Vector3.FORWARD),"Public voluntary ordinary dash approaches actual priority"): return false
		if not await completed_dash(start,Vector3.FORWARD): return false
	if not expect(level.call("parent_owned_state").stage==1 and regular.get("stage")==2 and regular.get("sources").size()==3 and offered.get_instance_id()==offered_live_id,"Real offered death plus actual supported contact installs compact original C50+C52; offered original native object retained"): return false
	stalker=regular.get("sources")[STALKER]
	plain=regular.get("sources")[PLAIN]
	watch_live_source(stalker,STALKER)
	watch_live_source(plain,PLAIN)
	if not await sample_parent("priority-entry-all-three-original-bindings"): return false
	var saved: Dictionary=pair()
	var unit: Dictionary=saved.level.local.current_unit.state
	return expect(unit.scheduler.schema_version==3 and unit.scheduler.authored_source_cycles.sources.size()==2 and same(journal_source(unit.scheduler,OFFERED),offered_journal_after_death) and unit.deaths.size()==1 and unit.deaths.has(OFFERED),"Whole Scheduler3 retains exact earlier offered journal alongside current authored Echo and original ordinary C50")

func genuine_priority() -> bool:
	game.call("resume_lab")
	var warning: Dictionary={}
	for _i: int in range(360):
		var state: Dictionary=stalker.call("state")
		if state.phase=="warning" and not String(state.reservation_id).is_empty(): warning=state; break
		if not await tick(): return false
	if not expect(not warning.is_empty() and warning.proof.get("accepted",false) and not warning.proof.get("uses_blast",true) and not warning.proof.get("uses_invulnerability",true),"Actual C50 native physical-lunge admission supplies original complete ordinary witness",str(warning)): return false
	if not await sample_parent("priority-C50-warning-whole-journal"): return false
	if _c50_transport_only: return await _c50_campaign_transport(pair(),warning)
	if not await follow_stalker(warning): return false
	var locked: Dictionary=await next_echo_lock(PLAIN,480)
	if locked.is_empty(): return false
	if not expect(scheduler.source_control_state(plain).reservations.size()==1 and plain.call("source_cycles_managed") and offered.get_instance_id()==offered_live_id,"Actual current C52 exclusive admission follows ordinary C50 recovery without retiring offered history"): return false
	if not await sample_parent("priority-C52-lock-whole-journal"): return false
	if not await follow_echo(plain,locked): return false
	if not ordinary_primary(plain,PLAIN) or not await recover_primary(): return false
	# Do not require either priority source's defeat or the final route/exit.
	if not await sample_parent("priority-ordinary-primary-current-native-suffix"): return false
	var saved: Dictionary=pair()
	var unit: Dictionary=saved.level.local.current_unit.state
	if not expect(unit.scheduler.schema_version==3 and unit.scheduler.authored_source_cycles.sources.size()==2 and same(journal_source(unit.scheduler,OFFERED),offered_journal_after_death) and unit.sources.size()==3 and level.call("parent_owned_state").stage==1,"Actual compact two-family priority keeps complete original current journal and earlier earned offered death"): return false
	priority_negatives(saved)
	return true

func next_echo_lock(id: String,limit: int) -> Dictionary:
	if paused: game.call("resume_lab")
	var source: Node3D=regular.get("sources")[id]
	var last_observed: PackedByteArray=PackedByteArray()
	var observation_count: int=0
	for _i: int in range(limit):
		if id==PLAIN:
			var observed: Dictionary=echo_lock_observation(source)
			var key: PackedByteArray=var_to_bytes([observed.phase,observed.status,observed.generation,observed.leases,observed.admission_reason,observed.camera_error])
			if key!=last_observed and observation_count<16:
				print("C52 admission observation: "+str(observed))
				observation_count+=1
			last_observed=key
		var control: Dictionary=scheduler.source_control_state(source)
		if control.reservations.size()==1:
			var lease: Dictionary=control.reservations[0]
			if lease.adapter.get("kind")=="authored_replay" and lease.adapter.get("locked")==true and not observed_echo_leases.has(String(lease.id)):
				var committed: Dictionary=regular.call("current_echo_commit",id)
				var proof: Dictionary=committed.get("proof",{})
				# Observe the actual retained commit result: armed exchanges cannot
				# legally be re-proved. Keep the original clock/lease/deadlines exact.
				if not expect(committed.get("locked",false) and var_to_bytes(committed.get("lease",{}))==var_to_bytes(lease) and scheduler.get_clock()==float(lease.lock_from_s) and proof.get("accepted",false) and proof.get("at_lock",false) and proof.timeline_origin_s==lease.adapter.timeline_origin_s and proof.evaluated_at_s==lease.lock_from_s,"Actual original retained lock witness matches current native lease without re-proving or retiming",str({"locked":committed.get("locked",false),"lease_native_exact":var_to_bytes(committed.get("lease",{}))==var_to_bytes(lease),"clock":scheduler.get_clock(),"lock":lease.lock_from_s,"proof_clock":proof.get("evaluated_at_s"),"proof_origin":proof.get("timeline_origin_s"),"lease_origin":lease.adapter.timeline_origin_s})): return {}
				observed_echo_leases[String(lease.id)]=true
				return {"proof":proof,"lease":lease.duplicate(true),"source_id":id}
		if not await tick(): return {}
	expect(false,"Finite actual source lock reaches "+id,str(echo_lock_observation(source)))
	return {}

func echo_lock_observation(source: Node3D) -> Dictionary:
	var leases: Array=[]
	for lease: Dictionary in scheduler.source_control_state(source).get("reservations",[]):
		leases.append({"id":lease.get("id"),"state":lease.get("state"),"locked":lease.get("adapter",{}).get("locked"),"lock_from_s":lease.get("lock_from_s")})
	var other: Dictionary=stalker.call("state") if is_instance_valid(stalker) else {}
	return {"clock_s":scheduler.get_clock(),"phase":source.call("source_phase"),"status":source.call("state").get("status"),"generation":source.call("get_authored_cycle_generation"),"leases":leases,"admission_reason":regular.get("last_admission_reason"),"camera_error":regular.get("last_camera_error"),"hero_position":hero.global_position,"grounded":hero.is_on_floor(),"stable":hero.get_threat_response_state().get("stable"),"stalker_phase":other.get("phase"),"stalker_lease":other.get("reservation_id"),"stalker_cancel":other.get("last_cancel_reason"),"recent_invalidations":invalidations.slice(maxi(0,invalidations.size()-8))}

func follow_echo(source: Node3D,locked: Dictionary) -> bool:
	if paused: game.call("resume_lab")
	var proof: Dictionary=locked.proof
	for segment: Dictionary in proof.path:
		if segment.kind not in ["first_escape_dash","tether_positioning_dash"]: continue
		if not await until(float(segment.start_s)): return false
		if not expect(hero.global_position.distance_to(segment.from)<0.02 and hero.request_dash((segment.to-segment.from).normalized()),"Actual public ordinary dash begins at proved original Echo response origin"): return false
		if not await completed_dash(segment.from,(segment.to-segment.from).normalized()): return false
		if not expect(hero.global_position.distance_to(segment.to)<0.02,"Actual Echo response reaches exact supported native landing"): return false
		if segment.kind=="first_escape_dash":
			if not await until(float(locked.lease.active_from_s)+0.03): return false
			if not await sample_parent("native-active-"+String(locked.source_id)): return false
			game.call("resume_lab")
	if not await until(float(proof.primary_time_s)): return false
	return expect(source.call("source_phase")=="recovery" and hero.global_position.distance_to(proof.attack_position)<0.02,"Actual ordinary Echo return reaches low knot inside original recovery; no pose/HP/clock writes")

func follow_stalker(warning: Dictionary) -> bool:
	if paused: game.call("resume_lab")
	var lease: Dictionary=scheduler.reservation_state(String(warning.reservation_id))
	for segment: Dictionary in warning.proof.path:
		if segment.kind not in ["escape_dash","positioning_dash"]: continue
		if not await until(float(segment.start_s)): return false
		if not expect(hero.global_position.distance_to(segment.from)<0.02 and hero.request_dash((segment.to-segment.from).normalized()),"Actual original C50 escape/return starts from native witness origin"): return false
		if not await completed_dash(segment.from,(segment.to-segment.from).normalized()): return false
		if not expect(hero.global_position.distance_to(segment.to)<0.02,"Actual original C50 native dash reaches proved supported landing"): return false
		if segment.kind=="escape_dash":
			if not await until(float(lease.active_from_s)+0.03): return false
			var active: Dictionary=stalker.call("state")
			var actual_lease: Dictionary=scheduler.reservation_state(String(lease.id))
			if not expect(active.phase=="active" and active.reservation_id==lease.id and actual_lease.get("state")=="active" and String(active.last_cancel_reason).is_empty(),"Actual original C50 lease is still active before whole-state sampling",str({"source":active,"lease":actual_lease,"invalidations":invalidations})): return false
			if not await sample_parent("priority-C50-active-physical-source-whole-journal"): return false
			game.call("resume_lab")
	if not await until(float(warning.proof.primary_time_s)): return false
	var recovery: Dictionary=stalker.call("state")
	if not expect(hero.global_position.distance_to(warning.proof.attack_position)<0.02 and recovery.phase=="recovery" and recovery.reservation_id==lease.id and String(recovery.last_cancel_reason).is_empty(),"Actual original C50 ordinary recovery opening remains reachable",str({"actual_position":hero.global_position,"attack_position":warning.proof.attack_position,"source":recovery,"invalidations":invalidations})): return false
	if not ordinary_primary(stalker,STALKER): return false
	return await recover_primary()

func ordinary_primary(source: Node3D,id: String) -> bool:
	var hp_before: float=float(source.get("hp"))
	var actions_before: int=hero.get_world_action_records().size()
	var direction: Vector3=source.global_position-hero.global_position
	direction.y=0.0
	var hits: int=hero.slash(direction.normalized()) # Public actual primary; generates its ordinary native record/hit/HP transaction.
	var records: Array[Dictionary]=hero.get_world_action_records()
	return expect(hits>=1 and (id!=OFFERED or hits==1) and records.size()==actions_before+1 and records.back().kind=="primary" and records.back().hits==hits and records.back().damage==hero.equipment.resolved_stats().primary_damage and float(source.get("hp"))==maxf(0.0,hp_before-float(hero.equipment.resolved_stats().primary_damage)),"Actual canonical ordinary primary transaction: "+id,str(records.back() if not records.is_empty() else {}))

func recover_primary() -> bool:
	for _i: int in range(120):
		var response: Dictionary=hero.get_threat_response_state()
		if response.stable and float(response.primary_cooldown_left_s)==0.0 and float(response.commitment_remaining_s)==0.0: return true
		if not await tick(): return false
	return expect(false,"Original ordinary primary fully recovers naturally")

func ready_for_dash() -> bool:
	for _i: int in range(120):
		var response: Dictionary=hero.get_threat_response_state()
		if response.stable and float(response.dash_cooldown_left_s)==0.0 and float(response.commitment_remaining_s)==0.0: return true
		if not await tick(): return false
	return expect(false,"Original shared dash readiness settles naturally")

func completed_dash(start: Vector3,direction: Vector3) -> bool:
	var size_before: int=hero.get_world_action_records().size()
	for _i: int in range(80):
		if float(hero.get_threat_response_state().motion.dash_left_s)==0.0:
			var records: Array[Dictionary]=hero.get_world_action_records()
			return expect(records.size()==size_before+1 and records.back().kind=="dash" and not records.back().collision_shortened and not records.back().movement_damage and hero.is_on_floor() and records.back().equipment_ids==baseline_kit and (hero.global_position-start).dot(direction)>0.0,"Actual full public dash publishes once at ordinary supported floor landing",str(records.back() if not records.is_empty() else {}))
		if not await tick(): return false
	return expect(false,"Finite ordinary native dash completion")

func until(clock: float) -> bool:
	for _i: int in range(900):
		if scheduler.get_clock()>=clock: return true
		if not await tick(): return false
	return expect(false,"Bounded original current native deadline observation")

func tick() -> bool:
	if paused or not is_instance_valid(barrier): return expect(false,"Live unpaused post-consumer native barrier required")
	barrier.waiting=true; barrier.expired=false; barrier.frames=0
	await barrier.observed
	ticks+=1
	var fixed: bool=floor_collision.global_transform==floor_transform and (floor_collision.shape as BoxShape3D).size==floor_size
	return expect(not paused and not barrier.expired and not hero.dead and hero.hp==baseline_hp and hero.equipment.snapshot()==baseline_kit and fixed and scheduler.get_clock()<=baseline_epoch+CASE_BUDGET_S and String(level.get("last_configuration_error")).is_empty() and String(regular.get("last_configuration_error")).is_empty() and not events.any(func(row: Dictionary) -> bool: return row.get("attack")=="blast"),"Native regular advance preserves original kit/HP/floor/bounded clocks",str({"paused":paused,"barrier_expired":barrier.expired,"barrier_frames":barrier.frames,"dead":hero.dead,"hp":hero.hp,"baseline_hp":baseline_hp,"kit_exact":hero.equipment.snapshot()==baseline_kit,"floor_exact":fixed,"clock_s":scheduler.get_clock(),"baseline_epoch":baseline_epoch,"parent_error":level.get("last_configuration_error"),"unit_error":regular.get("last_configuration_error"),"blast_seen":events.any(func(row: Dictionary) -> bool: return row.get("attack")=="blast"),"window_visible":root.visible,"window_focus":root.has_focus(),"display_focused":DisplayServer.window_is_focused(root.get_window_id()),"drawn_frames":Engine.get_frames_drawn()}))

func sample_parent(label: String) -> bool:
	game.call("open_bench")
	await process_frame
	var saved: Dictionary=pair()
	if not expect(paused and not saved.player.is_empty() and not saved.level.is_empty() and level.snapshot_error_with_player(saved.level,saved.player).is_empty(),"Complete current regular/parent native writer: "+label,level.last_snapshot_error): return false
	var parsed: Dictionary=Exact.parse(Exact.stringify(saved))
	if not expect(parsed.get("accepted",false) and same(parsed.value,saved),"Whole exact native JSON preserves all managed/ordinary branches: "+label): return false
	var sample_directory: String=ProjectSettings.globalize_path("res://captures/act3/crystalman-priority-c50-transport" if _c50_transport_only else "res://captures/act3/crystalman-priority")
	if not expect(DirAccess.make_dir_recursive_absolute(sample_directory)==OK,"Native priority sample directory available"): return false
	var sample_file: FileAccess=FileAccess.open(sample_directory.path_join(label+".json"),FileAccess.WRITE)
	if not expect(sample_file!=null,"Exact actual current parent sample opens"): return false
	sample_file.store_string(Exact.stringify(saved)); sample_file.close()
	print("Crystalman priority sample: "+label+" at native "+str(scheduler.get_clock())+"s")
	# Explicit transport selector relies on its public Shell fresh recipients;
	# default still performs every original independent candidate unchanged.
	if not _c50_transport_only and not await fresh_candidate(saved): return false
	samples.append(label)
	return true

func priority_negatives(saved: Dictionary) -> void:
	var before: Dictionary=pair()
	var bad: Dictionary=saved.duplicate(true)
	var journal: Array=bad.level.local.current_unit.state.scheduler.authored_source_cycles.sources
	for index: int in range(journal.size()):
		if journal[index].source_id==OFFERED: journal.remove_at(index); break
	reject(bad,before,"Earlier actual offered journal cannot be filtered away")
	bad=saved.duplicate(true); bad.level.local.current_unit.state.sources[OFFERED].actor.alive=true
	reject(bad,before,"Actual dead offered physical binding cannot revive without native history")
	bad=saved.duplicate(true); bad.level.local.current_unit.state.sources[PLAIN].actor.source_id=OFFERED
	reject(bad,before,"Current/retired authored source identities cannot be substituted")
	bad=saved.duplicate(true); bad.level.local.current_unit.state.scheduler.profile=true
	reject(bad,before,"Malformed current complete Scheduler profile")
	bad=saved.duplicate(true); bad.level.local.current_unit.state.sources[STALKER].actor.previous.clock_s=bad.level.local.current_unit.state.scheduler.clock_s; bad.level.local.current_unit.state.sources[STALKER].actor.previous.hero_position[0]+=0.5
	reject(bad,before,"Current C50 physical sample must agree with complete saved Hero")
	bad=saved.duplicate(true); bad.level.local.current_unit.state.sources[PLAIN].playback.generation+=1
	reject(bad,before,"Native current authored generation must match complete retained journal/physical source")
	expect(same(before,pair()) and offered.get_instance_id()==offered_live_id,"All malformed unit/cross-source copies preserve exact installed donor/native ownership")

func journal_source(schedule: Dictionary,id: String) -> Dictionary:
	for row: Dictionary in schedule.authored_source_cycles.sources:
		if row.source_id==id: return row.duplicate(true)
	return {}

func watch_live_source(source: Node3D,id: String) -> void:
	if source.has_signal("died"):
		if id==STALKER: source.connect("died",func(_where: Vector3) -> void: events.append({"kind":"source_died","source":id,"clock_s":scheduler.get_clock()}))
		else: source.connect("died",func() -> void: events.append({"kind":"source_died","source":id,"clock_s":scheduler.get_clock()}))
	if source.has_signal("event_dispatched"):
		source.connect("event_dispatched",func(event: Dictionary,receipt: Dictionary) -> void: events.append({"kind":"authored_event","source":id,"event":event.duplicate(true),"receipt":receipt.duplicate(true)}))

func watch(node: Node) -> void:
	for row: Dictionary in node.get_signal_list():
		if row.name in ["fired","died","action_resolved","world_action_executed","source_hit_resolved","source_defeated","reservation_invalidated","state_changed","event_dispatched","playback_failed","checkpoint_requested","completion_requested","contact_exit_requested"]:
			var callback: Callable=Callable(self,"quiet"+str(row.args.size()))
			if callback.is_valid(): node.connect(row.name,callback)
	for child: Node in node.get_children(): watch(child)

func close_regular() -> void:
	paused=true
	var refs: Array[WeakRef]=[]
	for node: Node in [regular,scheduler,offered,stalker,plain,floor_collision,level,hero,game,barrier]:
		if is_instance_valid(node): refs.append(weakref(node))
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(barrier): barrier.waiting=false; barrier.queue_free()
	await close()
	for _i: int in range(3): await process_frame
	expect(refs.all(func(ref: WeakRef) -> bool: return ref.get_ref()==null),"Normal paused whole parent/current regular/cues/managed-source/Player/floor cleanup frees every genuine native binding")


## INERT Shared57 consumer: select only after actual local registration adoption.
## No direct Shell Attempts native seeding/private registration/cache calls.
func _c50_campaign_transport(packet: Dictionary,warning: Dictionary) -> bool:
	if not expect(paused and level.has_method("restore_candidate_physics_registration_required") and level.call("restore_candidate_physics_registration_required"),"Published opted registration API is required before this future selector"): return false
	var live: Dictionary=stalker.call("state")
	var actual_lease: Dictionary=scheduler.reservation_state(String(warning.reservation_id))
	if not expect(live.phase=="warning" and live.reservation_id==warning.reservation_id and actual_lease.get("state")=="warning" and String(live.last_cancel_reason).is_empty(),"Genuine current C50 warning remains held at same paused seed moment",str({"source":live,"lease":actual_lease})): return false
	var camera: Camera3D=game.get("camera") as Camera3D
	var hud: GameHUD=game.get("hud") as GameHUD
	var optics: String=String(level.call("candidate_presentation_error",camera,hud))
	if not expect(optics.is_empty() and same(packet,pair()),"Actual same-moment Camera/HUD and whole warning donor are valid without refit",optics): return false
	var input: Dictionary=game.call("get_input_observation_state")
	var anchor: Vector2=input.anchor_normalized
	var observation: Dictionary=input.last_observation.duplicate(true)
	if not observation.is_empty():
		var screen: Vector2=observation.screen_position_normalized
		var observed_anchor: Vector2=observation.anchor_normalized
		observation.screen_position_normalized=[screen.x,screen.y]
		observation.anchor_normalized=[observed_anchor.x,observed_anchor.y]
		observation.direction=Value.vector3(observation.direction)
	var seed: Dictionary={"schema_version":1,"level_id":"A3-L5","scene_path":room_path,"paused":true,"equipment_ids":packet.player.equipment.duplicate(true),"player":packet.player.duplicate(true),"level":packet.level.duplicate(true),"shell":{"api_revision":ProductionShell.SHELL_API,"anchor_normalized":[anchor.x,anchor.y],"input_sequence":input.sequence,"last_input_observation":observation,"camera_focus":Value.vector3(camera.global_position-ProductionShell.CAMERA_OFFSET),"shake_left_s":0.0,"difficulty_at_entry":"standard"}}
	_c50_registry_bytes=FileAccess.get_file_as_string(Registry.DATA_PATH)
	var raw: Dictionary=JSON.parse_string(_c50_registry_bytes)
	for row: Dictionary in raw.levels:
		if row.id=="A3-L5":
			row.scene_path=room_path
			row.readiness="accepted" # TEST ONLY metadata, not campaign acceptance.
			row.accepted_commit="f".repeat(40)
			row.api_revision=Registry.API_REVISION
	var detached=C50Attempts.new(Registry.new(raw)) # No native Shell validator.
	var session: Dictionary=detached.state()
	session.completed_main=detached.registry.main_route().slice(0,14)
	session.story={"kind":"story","level_id":"A3-L5","snapshot":seed.duplicate(true),"checkpoint":seed.duplicate(true)}
	var structural: String=detached.state_error(session)
	if not expect(structural.is_empty() and level.snapshot_error_with_player(packet.level,packet.player).is_empty(),"Explicit TEST prefix14/warning checkpoint structure plus independent genuine donor validation",structural): return false
	if DisplayServer.get_name()=="headless" and not _c50_archive_warning_seed(raw,session,seed): return false
	isolated="user://test-crystalman-c50-%d-%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	var writer=Store.new(isolated+"campaign.json")
	if not expect(writer.write_payload(session),"Standalone exact Store writes disclosed structural TEST seed, not native certification",writer.last_error): return false
	if not _c50_disk(session): return false
	if not node_added.is_connected(_c50_watch_new_node): node_added.connect(_c50_watch_new_node)
	if not await _c50_new_shell(raw,session): return false
	print("Crystalman C50 transport: first public startup exact session loaded")
	production.menu.continue_story_requested.emit()
	if not await settle("resume"): return false
	if not _c50_installed(seed): return false
	print("Crystalman C50 transport: first Continue exact held warning installed at native "+str(production.player.get_world_action_clock())+"s")
	var first_ids: Dictionary=_c50_native_ids()
	if not _c50_quiet_selected(): return false
	if _c50_portraits and not await _c50_portrait("01-public-continued-warning"): return false
	# Production Save; checkpoint remains the explicit initial warning unit.
	production.request_pause()
	if not await settle("pause"): return false
	var saved: Dictionary=production.capture_campaign_snapshot()
	var saved_session: Dictionary=production.attempts.state()
	if not expect(not saved.is_empty() and same(saved,seed) and same(saved_session.story.checkpoint,seed),"Public Pause writes exact warning snapshot without replacing protected TEST checkpoint",production.campaign_error): return false
	if not _c50_disk(saved_session): return false
	print("Crystalman C50 transport: public Pause/Save exact warning durable")
	var donor: Dictionary=pair()
	var donor_input: PackedByteArray=var_to_bytes(game.call("get_input_observation_state"))
	if not await _c50_dispose_shell(): return false
	if not await _c50_new_shell(raw,saved_session): return false
	production.menu.continue_story_requested.emit()
	if not await settle("resume"): return false
	if not _c50_installed(saved) or not _c50_distinct(first_ids) or not _c50_quiet_selected(): return false
	print("Crystalman C50 transport: new disk Continue exact distinct warning recipient installed")
	if not expect(same(saved_session,production.attempts.state()),"Fresh disk startup/Continue preserve exact complete protected session"): return false
	if not _c50_disk(saved_session): return false
	if _c50_portraits and not await _c50_portrait("02-public-disk-restored-warning"): return false
	var refs: Array[WeakRef]=[]
	var container: Node=_c50_world_container()
	if not expect(container!=null,"Actual old native portrait container ownership required before Retry"): return false
	_c50_collect_refs(container,refs)
	var previous: Dictionary=_c50_native_ids()
	_c50_receiver_events.clear()
	production.request_retry()
	if not await settle("resume"): return false
	if not _c50_installed(seed) or not _c50_distinct(previous) or not _c50_quiet_selected(): return false
	if not await _c50_released(refs,"Retry retires the complete previous actual native World/source/floor subtree"): return false
	var retried: Dictionary=production.attempts.state()
	if not expect(same(retried.story.snapshot,seed) and same(retried.story.checkpoint,seed) and same(retried.completed_main,session.completed_main),"Public Retry restores protected warning and exact TEST story core"): return false
	if not _c50_disk(retried): return false
	print("Crystalman C50 transport: Retry exact protected warning restored and donor world freed")
	if not await _c50_resume_consumed(): return false
	production.request_pause()
	if not await settle("pause"): return false
	if not _c50_disk(production.attempts.state()): return false
	if not expect(same(donor,pair()) and donor_input==var_to_bytes(game.call("get_input_observation_state")),"All real Shell fresh operations preserve separate genuine Main donor/input"): return false
	if not expect(FileAccess.get_file_as_string(Registry.DATA_PATH)==_c50_registry_bytes,"Canonical registry bytes stay untouched"): return false
	if not await _c50_dispose_shell(): return false
	if node_added.is_connected(_c50_watch_new_node): node_added.disconnect(_c50_watch_new_node)
	print("Crystalman C50 transport: final public Shell whole-tree cleanup complete; original Main donor remains for normal fixture exit")
	if _c50_portraits: return expect(_c50_portrait_labels.size()==2,"Two original visible public C50 warning portraits observed without simulation")
	return true

func _c50_new_shell(raw: Dictionary,expected: Dictionary) -> bool:
	_c50_receiver_events.clear()
	_c50_watched.clear()
	production=ProductionShell.new()
	if not expect(production.configure_runtime(raw,isolated+"campaign.json",isolated+"settings.json",isolated+"preferences.json"),"Fresh actual public Shell uses isolated paths/in-memory TEST row",production.campaign_error): return false
	root.add_child(production)
	return await _await_seeded_startup(expected)

func _c50_installed(expected: Dictionary) -> bool:
	var parent: CinderLevel=production.active_level
	var actor: CinderPlayer=production.player
	var unit: CinderLevel=parent.get("current_unit") as CinderLevel
	var owners: Dictionary=unit.get("sources")
	var native: CinderThreatScheduler=unit.get("threat_scheduler") as CinderThreatScheduler
	var state: Dictionary=owners[STALKER].call("state")
	var control: Dictionary=native.source_control_state(owners[STALKER])
	var target: Dictionary=expected.level.local.current_unit.state
	var error: String=String(parent.call("candidate_presentation_error",production.camera,production.hud))
	if _c50_saved_archive.is_empty():
		var donor_owners: Dictionary=regular.get("sources")
		var distinct: bool=actor!=hero and parent!=level and unit!=regular and native!=scheduler and parent.get("floor_collision")!=floor_collision and production.camera!=game.get("camera") and production.world!=game.get("world") and actor.get_world_3d()!=hero.get_world_3d()
		for id: String in [OFFERED,STALKER,PLAIN]: distinct=distinct and owners[id]!=donor_owners[id]
		if not expect(distinct,"First installed recipient has distinct actual native World3D/Hero/parent/unit/Scheduler/floor/Camera/three sources from genuine Main donor"): return false
	elif not expect(not is_instance_valid(game) and not is_instance_valid(hero) and not is_instance_valid(level) and not is_instance_valid(regular) and not is_instance_valid(scheduler),"Explicit archived portrait creates no Main donor/live combat fixture"): return false
	return expect(paused and not parent.is_restore_candidate() and not unit.is_restore_candidate() and parent.hero==actor and parent.shared_shell==production and actor.get_parent()==production.world and production.camera.get_parent()==production.world and unit.get_parent()==parent and owners.size()==3 and native.get_parent()==unit and state.phase=="warning" and state.reservation_id==target.sources[STALKER].actor.reservation_id and control.reservations.size()==1 and control.reservations[0].id==state.reservation_id and control.reservations[0].state=="warning" and native.get_clock()==float(target.scheduler.clock_s) and same(production.capture_campaign_snapshot(),expected) and error.is_empty(),"Actual installed whole held C50/Scheduler3/two journals/physical sources and Camera/HUD match protected warning",error+"; "+production.campaign_error)

func _c50_native_ids() -> Dictionary:
	var parent: CinderLevel=production.active_level
	var unit: CinderLevel=parent.get("current_unit") as CinderLevel
	var result: Dictionary={"world":production.world.get_instance_id(),"hero":production.player.get_instance_id(),"level":parent.get_instance_id(),"unit":unit.get_instance_id(),"scheduler":(unit.get("threat_scheduler") as Node).get_instance_id(),"floor":(parent.get("floor_collision") as Node).get_instance_id(),"camera":production.camera.get_instance_id()}
	for id: String in [OFFERED,STALKER,PLAIN]: result[id]=(unit.get("sources")[id] as Node).get_instance_id()
	return result

func _c50_distinct(previous: Dictionary) -> bool:
	var current: Dictionary=_c50_native_ids()
	for key: String in previous:
		if not expect(int(current[key])>0 and current[key]!=previous[key],"Fresh genuine native recipient identity: "+key): return false
	return true

func _c50_disk(expected: Dictionary) -> bool:
	var reader=Store.new(isolated+"campaign.json")
	var payload: Dictionary=reader.read_payload()
	var envelope: Variant=JSON.parse_string(FileAccess.get_file_as_string(isolated+"campaign.json"))
	var wire: String=Exact.stringify(payload)
	var parsed: Dictionary=Exact.parse(wire)
	return expect(reader.last_error.is_empty() and not reader.loaded_backup and envelope is Dictionary and envelope.get("format_version")==2 and envelope.get("payload_json") is String and envelope.payload_json.sha256_text()==envelope.get("sha256") and same(payload,expected) and not wire.is_empty() and parsed.get("accepted",false) and same(parsed.get("value"),expected),"Independent Store format2/checksum/native ExactJson complete payload equals public session",reader.last_error)

func _c50_collect_refs(node: Node,refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child: Node in node.get_children(): _c50_collect_refs(child,refs)

func _c50_world_container() -> Node:
	var view: Node=production.world.get_parent()
	var container: Node=view.get_parent()
	return container if view is SubViewport and container is SubViewportContainer and container.get_parent()==production else null

func _c50_released(refs: Array[WeakRef],label: String) -> bool:
	for _i: int in range(8):
		if refs.all(func(ref: WeakRef) -> bool: return ref.get_ref()==null): return expect(true,label)
		await process_frame
	return expect(false,label)

func _c50_dispose_shell() -> bool:
	if not is_instance_valid(production): return true
	paused=true
	var refs: Array[WeakRef]=[]
	_c50_collect_refs(production,refs)
	if is_instance_valid(production.active_level): production.active_level.exit_level()
	production.queue_free()
	production=null
	return await _c50_released(refs,"Normal public Shell whole-tree retirement frees every observed native/UI binding")

func _c50_watch_new_node(node: Node) -> void:
	if not is_instance_valid(production) or not production.is_ancestor_of(node) or _c50_watched.has(node.get_instance_id()): return
	_c50_watched[node.get_instance_id()]=true
	for row: Dictionary in node.get_signal_list():
		if row.name in ["fired","died","action_resolved","world_action_executed","source_hit_resolved","source_defeated","event_dispatched","playback_failed","checkpoint_requested","completion_requested","contact_exit_requested"] and row.args.size()<=3:
			var callback: Callable=Callable(self,"_c50_event"+str(row.args.size())).bind(str(node.get_instance_id()),String(row.name))
			node.connect(row.name,callback)

func _c50_event0(owner: String,kind: String) -> void: _c50_receiver_events.append({"owner":owner,"kind":kind})
func _c50_event1(_a: Variant,owner: String,kind: String) -> void: _c50_event0(owner,kind)
func _c50_event2(_a: Variant,_b: Variant,owner: String,kind: String) -> void: _c50_event0(owner,kind)
func _c50_event3(_a: Variant,_b: Variant,_c: Variant,owner: String,kind: String) -> void: _c50_event0(owner,kind)

func _c50_quiet_selected() -> bool:
	var refs: Array[WeakRef]=[]
	_c50_collect_refs(production.active_level,refs)
	_c50_collect_refs(production.player,refs)
	var selected: Dictionary={}
	for ref: WeakRef in refs: selected[str((ref.get_ref() as Node).get_instance_id())]=true
	var bad: Array=[]
	for event: Dictionary in _c50_receiver_events:
		if selected.has(event.owner): bad.append(event)
	return expect(bad.is_empty(),"Selected quiet fresh recipient emits no observed gameplay/progression; donor/pool retirement kept separate",str(bad))

func _c50_resume_consumed() -> bool:
	# Let the real newly built menu finish its paused frame/layout before input.
	if not expect(paused,"GUI layout settles only while gameplay is paused"): return false
	await process_frame
	if not expect(paused and production.campaign_error.is_empty(),"Public GUI layout boundary preserves paused error-free state",production.campaign_error): return false
	var actor: CinderPlayer=production.player
	var button: Control=production.menu.find_child("ResumeButton",true,false) as Control
	if not expect(paused and production.menu.is_open() and button!=null and button.is_visible_in_tree(),"Actual visible GUI Resume exists"): return false
	var before: PackedByteArray=var_to_bytes([actor.get_world_action_records(),production.get_input_observation_state(),actor.get_world_action_clock(),actor.hp,actor.shells])
	var at: Vector2=button.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new(); motion.position=at; motion.global_position=at
	root.push_input(motion,true)
	var down:=InputEventMouseButton.new(); down.button_index=MOUSE_BUTTON_LEFT; down.position=at; down.global_position=at; down.pressed=true
	root.push_input(down,true)
	var handled: bool=root.is_input_handled()
	var up:=down.duplicate() as InputEventMouseButton; up.pressed=false
	root.push_input(up,true)
	return expect(handled and root.is_input_handled() and not paused and not production.menu.is_open() and before==var_to_bytes([actor.get_world_action_records(),production.get_input_observation_state(),actor.get_world_action_clock(),actor.hp,actor.shells]),"Real viewport GUI Resume is consumed without gameplay/input/resource/clock changes")


## Original pixels from the visible installed public Shell, never a pooled view.
## TEST-only CanvasLayer exclusion keeps the whole installed world paused.
## The independent public GUI Resume check remains in the transport sequence.
func _c50_portrait(label: String) -> bool:
	# Settle native UI layout while retaining the original paused world.
	if not expect(paused,"Portrait layout settles only while gameplay is paused"): return false
	await process_frame
	var container: Node=_c50_world_container()
	var view: SubViewport=production.world.get_parent() as SubViewport
	if not expect(paused and not production.is_pause_requested() and not _c50_portrait_labels.has(label) and container is SubViewportContainer and (container as SubViewportContainer).is_visible_in_tree() and view!=null and view.own_world_3d and not view.transparent_bg and view.render_target_update_mode==SubViewport.UPDATE_ALWAYS and production.active_level.is_visible_in_tree() and production.player.is_visible_in_tree() and production.camera.get_viewport()==view and view.get_camera_3d()==production.camera and production.hud.visible,"Actual installed visible Shell World/Camera/Hero/HUD is rendered once: "+label): return false
	if not expect(not (_c50_hud_record().labels as Array).is_empty(),"Actual native public HUD labels are observed before portrait: "+label): return false
	var before: Dictionary=production.capture_campaign_snapshot()
	var wire: String=Exact.stringify(before)
	var input: PackedByteArray=var_to_bytes(production.get_input_observation_state())
	var camera: PackedByteArray=var_to_bytes(_c50_camera_record())
	var hud: PackedByteArray=var_to_bytes(_c50_hud_record())
	var events_before: PackedByteArray=var_to_bytes(_c50_receiver_events)
	var observation: Dictionary={"before":_c50_draw_diagnostic()}
	var menu_visibility: bool=production.menu.visible
	if not expect(paused and menu_visibility,"Actual campaign menu is present before TEST-only portrait exclusion: "+label): return false
	# TEST ONLY exclude the independent donor's sibling CanvasLayer overlays.
	# They otherwise paint above the actual installed Shell world. No donor
	# Node3D source art/camera/world visibility, input or mechanics is changed.
	var donor_layers: Array[CanvasLayer]=[]
	var donor_visibility: Array[bool]=[]
	var donor_presentation: Array=[]
	if _c50_saved_archive.is_empty():
		for name: String in ["hud","bench"]:
			var layer: CanvasLayer=game.get(name) as CanvasLayer
			if not expect(layer!=null,"Actual donor HUD/bench CanvasLayer binding exists: "+name): return false
			donor_layers.append(layer)
			donor_visibility.append(layer.visible)
			donor_presentation.append({"field":name,"id":layer.get_instance_id(),"visible_before":layer.visible,"visible_during":false})
	elif not expect(not is_instance_valid(game),"Only explicit saved-portrait mode may omit independent donor overlays"): return false
	for layer: CanvasLayer in donor_layers: layer.visible=false
	production.menu.visible=false # TEST ONLY overlay exclusion; gameplay stays paused.
	_c50_draw_seen=false
	RenderingServer.frame_post_draw.connect(_c50_on_draw)
	for _i: int in range(32):
		await process_frame
		if _c50_draw_seen: break
	if RenderingServer.frame_post_draw.is_connected(_c50_on_draw): RenderingServer.frame_post_draw.disconnect(_c50_on_draw)
	var image: Image=root.get_texture().get_image() if _c50_draw_seen else null
	var after: Dictionary=production.capture_campaign_snapshot()
	var optics: String=String(production.active_level.call("candidate_presentation_error",production.camera,production.hud))
	var unchanged: bool=paused and not production.is_pause_requested() and not production.menu.is_open() and not wire.is_empty() and Exact.stringify(after)==wire and input==var_to_bytes(production.get_input_observation_state()) and camera==var_to_bytes(_c50_camera_record()) and hud==var_to_bytes(_c50_hud_record()) and events_before==var_to_bytes(_c50_receiver_events)
	# Restore campaign menu and every donor layer before any failure return.
	production.menu.visible=menu_visibility
	for index: int in range(donor_layers.size()): donor_layers[index].visible=donor_visibility[index]
	var donor_restored: bool=true
	for index: int in range(donor_layers.size()): donor_restored=donor_restored and donor_layers[index].visible==donor_visibility[index]
	unchanged=unchanged and donor_restored and production.menu.visible==menu_visibility
	observation.campaign_menu_test_only_exclusion={"visible_before":menu_visibility,"visible_during":false,"visible_restored":production.menu.visible}
	observation.donor_canvas_test_only_exclusion=donor_presentation
	observation.donor_canvas_original_visibility_restored=donor_restored
	observation.after=_c50_draw_diagnostic()
	observation.label=label
	observation.draw_seen=_c50_draw_seen
	observation.whole_pair_input_camera_hud_events_unchanged=unchanged
	observation.optical_error=optics
	observation.actual_size=str(image.get_size()) if image!=null else "no image"
	print("C50_PUBLIC_DRAW_DIAGNOSTIC "+JSON.stringify(observation))
	if not expect(_c50_draw_seen and image!=null and image.get_size().x in [339,340] and image.get_size().y==736 and unchanged and optics.is_empty(),"Observed native339-or340x736 visible Shell frame preserves full warning/input/Camera/HUD/events: "+label,JSON.stringify(observation)): return false
	var folder: String=ProjectSettings.globalize_path("res://captures/act3/crystalman-c50-public-%d"%OS.get_process_id())
	var destination: String=folder.path_join(label+".png")
	if not expect(DirAccess.make_dir_recursive_absolute(folder)==OK and image.save_png(destination)==OK,"Original native public warning pixels saved unchanged: "+label): return false
	var receipt: FileAccess=FileAccess.open(destination+".json",FileAccess.WRITE)
	if not expect(receipt!=null,"Original public warning receipt opens: "+label): return false
	receipt.store_string(JSON.stringify({"schema_version":1,"test_only":true,"label":label,"actual_size":[image.get_size().x,image.get_size().y],"png_sha256":FileAccess.get_sha256(destination),"whole_campaign_exact_wire_sha256":wire.sha256_text(),"actual_clock_s":production.player.get_world_action_clock(),"world_id":production.world.get_world_3d().get_instance_id(),"viewport_id":view.get_instance_id(),"container_id":container.get_instance_id(),"native_camera_id":production.camera.get_instance_id(),"native_hero_id":production.player.get_instance_id(),"render_freeze_without_tick":true,"actual_visible_installed_shell":true,"whole_pair_input_camera_hud_events_unchanged":unchanged,"native_draw_diagnostic":observation,"source_route_art_acceptance":false},"  ")+"\n")
	receipt.close()
	_c50_portrait_labels.append(label)
	print("C50_PUBLIC_PORTRAIT "+destination)
	return true

func _c50_camera_record() -> Dictionary:
	var camera: Camera3D=production.camera
	return {"transform":camera.global_transform,"projection":camera.projection,"keep_aspect":camera.keep_aspect,"size":camera.size,"near":camera.near,"far":camera.far,"h_offset":camera.h_offset,"v_offset":camera.v_offset}

func _c50_hud_record() -> Dictionary:
	var labels: Array=[]
	_c50_hud_labels(production.hud,labels)
	return {"visible":production.hud.visible,"safe_rect":production.hud.combat_safe_rect(),"labels":labels}

func _c50_hud_labels(node: Node,labels: Array) -> void:
	if node is Label:
		var label: Label=node as Label
		labels.append([str(production.hud.get_path_to(label)),label.text,label.is_visible_in_tree(),label.global_position,label.size,label.get_theme_font_size("font_size")])
	for child: Node in node.get_children(): _c50_hud_labels(child,labels)

func _c50_draw_diagnostic() -> Dictionary:
	return {"wall_ticks_ms":Time.get_ticks_msec(),"process_frames":Engine.get_process_frames(),"physics_frames":Engine.get_physics_frames(),"frames_drawn":Engine.get_frames_drawn(),"render_loop_enabled":RenderingServer.is_render_loop_enabled(),"render_server_has_changed":RenderingServer.has_changed(),"window_can_draw":DisplayServer.window_can_draw(root.get_window_id()),"window_visible":root.visible,"window_focus":root.has_focus(),"display_focused":DisplayServer.window_is_focused(root.get_window_id()),"window_size":str(root.size),"root_texture_size":str(root.get_texture().get_size()),"paused":paused}

func _c50_on_draw() -> void: _c50_draw_seen=true


## Authentic paused warning data, archived before the first Store/Shell step.
## Native public-flow success and clean closure come from the actual runner,
## never from this byte-custody manifest. Producer fixture SHA is provenance;
## the later saved-portrait reader must not match its edited fixture to it.
func _c50_archive_warning_seed(raw: Dictionary,session: Dictionary,seed: Dictionary) -> bool:
	if not expect(_c50_transport_only and DisplayServer.get_name()=="headless" and paused and same(session.story.snapshot,seed) and same(session.story.checkpoint,seed),"Archive only the genuine current warning seed and explicit TEST session"): return false
	var folder: String=ProjectSettings.globalize_path("res://captures/act3/crystalman-c50-session-%d-%d"%[OS.get_process_id(),Time.get_ticks_usec()])
	if not expect(DirAccess.make_dir_recursive_absolute(folder)==OK,"Authentic C50 warning archive directory opens"): return false
	var values: Dictionary={"session.native.json":session,"seed.native.json":seed,"registry.native.json":raw}
	var files: Dictionary={}
	for name: String in C50_ARCHIVE_FILES:
		var wire: String=Exact.stringify(values[name])
		var parsed: Dictionary=Exact.parse(wire)
		if not expect(not wire.is_empty() and parsed.get("accepted",false) and same(parsed.get("value"),values[name]),"Archive native ExactJson roundtrip: "+name): return false
		var archive_file: FileAccess=FileAccess.open(folder.path_join(name),FileAccess.WRITE)
		if not expect(archive_file!=null,"Archive file opens: "+name): return false
		archive_file.store_string(wire); archive_file.close()
		if not expect(FileAccess.get_file_as_string(folder.path_join(name))==wire,"Archive exact native bytes retained: "+name): return false
		files[name]={"bytes":wire.to_utf8_buffer().size(),"sha256":wire.sha256_text()}
	var pins: Dictionary={}
	for path: String in C50_ARCHIVE_SOURCE_PATHS:
		var digest: String=FileAccess.get_sha256(path)
		if not expect(digest.length()==64,"Current archive runtime/scene/source pin exists: "+path): return false
		pins[path]=digest
	var manifest: Dictionary={"schema_version":1,"kind":"c50-genuine-warning-seed-1","test_only":true,"producer_fixture_sha256":FileAccess.get_sha256("res://tests/acts/act3/crystalman_regular_priority_smoke.gd"),"clock_s":scheduler.get_clock(),"public_flow_validation":"pending; actual native runner closure is authoritative","test_context":"prefix14; accepted in-memory representative A3-L5 row; same genuine warning checkpoint; no canonical readiness/history write","files":files,"source_pins":pins}
	var manifest_file: FileAccess=FileAccess.open(folder.path_join("manifest.json"),FileAccess.WRITE)
	if not expect(manifest_file!=null,"Authentic warning archive manifest opens"): return false
	manifest_file.store_string(JSON.stringify(manifest,"  ")+"\n"); manifest_file.close()
	print("C50_PUBLIC_SESSION_ARCHIVE "+folder+" manifest_sha256="+FileAccess.get_sha256(folder.path_join("manifest.json")))
	return true


## Read the exact genuine producer archive; actual paused Shell/native floor,
## source/Scheduler3/whole pair/current Camera-HUD validators remain decisive.
## Plain manifest supplies byte custody only, never native certification.
func _c50_saved_portrait_run() -> bool:
	_c50_registry_bytes=FileAccess.get_file_as_string(Registry.DATA_PATH)
	var archive: Dictionary=_c50_read_archive(_c50_saved_archive)
	if archive.is_empty(): return false
	var raw: Dictionary=archive.registry
	var seed: Dictionary=archive.seed
	var session: Dictionary=archive.session
	isolated="user://test-crystalman-c50-saved-portrait-%d-%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	var writer=Store.new(isolated+"campaign.json")
	if not expect(paused and writer.write_payload(session),"Exact authentic archived session seeds isolated Store while gameplay remains paused",writer.last_error): return false
	if not _c50_disk(session): return false
	if not node_added.is_connected(_c50_watch_new_node): node_added.connect(_c50_watch_new_node)
	if not await _c50_new_shell(raw,session): return false
	if not expect(paused,"Saved portrait public startup never unpauses gameplay"): return false
	print("Crystalman C50 saved portrait: authentic archived public startup exact session loaded")
	production.menu.continue_story_requested.emit()
	if not await settle("resume"): return false
	if not _c50_installed(seed) or not _c50_quiet_selected(): return false
	if not expect(paused and not production.is_pause_requested() and same(production.attempts.state(),session),"Fresh paused Continue preserves complete authentic archived session"): return false
	print("Crystalman C50 saved portrait: actual paused whole warning and current Camera/HUD validated")
	if not await _c50_portrait("01-authentic-saved-C50-warning"): return false
	if not expect(paused and _c50_portrait_labels.size()==1 and same(production.capture_campaign_snapshot(),seed) and same(production.attempts.state(),session),"One original saved-warning image preserves complete paused gameplay/session"): return false
	return await _c50_dispose_shell()

func _c50_read_archive(folder: String) -> Dictionary:
	var manifest_path: String=folder.path_join("manifest.json")
	var file: FileAccess=FileAccess.open(manifest_path,FileAccess.READ)
	if not expect(file!=null,"Authentic archive manifest exists"): return {}
	if not expect(file.get_length()>0 and file.get_length()<=Exact.MAX_BYTES,"Archive manifest is bounded"): file.close(); return {}
	var manifest: Variant=JSON.parse_string(file.get_as_text()); file.close()
	if not expect(manifest is Dictionary and Value.keys_error(manifest,["schema_version","kind","test_only","producer_fixture_sha256","clock_s","public_flow_validation","test_context","files","source_pins"]).is_empty(),"Closed authentic archive manifest fields"): return {}
	if not expect(manifest.schema_version==1 and manifest.kind=="c50-genuine-warning-seed-1" and manifest.test_only==true and manifest.producer_fixture_sha256 is String and manifest.producer_fixture_sha256.length()==64 and manifest.public_flow_validation=="pending; actual native runner closure is authoritative" and Value.is_number(manifest.clock_s) and manifest.clock_s>=0.0 and manifest.files is Dictionary and manifest.source_pins is Dictionary and Value.keys_error(manifest.files,C50_ARCHIVE_FILES).is_empty() and Value.keys_error(manifest.source_pins,C50_ARCHIVE_SOURCE_PATHS).is_empty(),"Declared genuine warning archive context and complete file/source inventory; producer fixture SHA is provenance"): return {}
	for path: String in C50_ARCHIVE_SOURCE_PATHS:
		if not expect(manifest.source_pins[path] is String and manifest.source_pins[path].length()==64 and FileAccess.get_sha256(path)==manifest.source_pins[path],"Archived native source custody matches actual current source: "+path): return {}
	var values: Dictionary={}
	for name: String in C50_ARCHIVE_FILES:
		var receipt: Variant=manifest.files[name]
		if not expect(receipt is Dictionary and Value.keys_error(receipt,["bytes","sha256"]).is_empty(),"Closed authentic archive file receipt: "+name): return {}
		if not expect(Value.is_integer(receipt.bytes,1,Exact.MAX_BYTES) and receipt.sha256 is String and receipt.sha256.length()==64,"Bounded archive exact native data receipt: "+name): return {}
		file=FileAccess.open(folder.path_join(name),FileAccess.READ)
		if not expect(file!=null,"Authentic archive data exists: "+name): return {}
		if not expect(file.get_length()==int(receipt.bytes),"Authentic archive byte length: "+name): file.close(); return {}
		var wire: String=file.get_as_text(); file.close()
		var parsed: Dictionary=Exact.parse(wire)
		if not expect(wire.sha256_text()==receipt.sha256 and parsed.get("accepted",false) and parsed.get("value") is Dictionary,"Authentic archive checksum/native ExactJson: "+name): return {}
		values[name]=parsed.value
	var raw: Dictionary=values["registry.native.json"]
	var seed: Dictionary=values["seed.native.json"]
	var session: Dictionary=values["session.native.json"]
	var expected_registry: Variant=JSON.parse_string(_c50_registry_bytes)
	if not expect(expected_registry is Dictionary and expected_registry.get("levels") is Array,"Actual canonical registry supports disclosed TEST row"): return {}
	for row: Variant in expected_registry.levels:
		if not expect(row is Dictionary,"Canonical registry row type remains complete"): return {}
		if row.get("id")=="A3-L5":
			row.scene_path=PRIORITY_ROOM; row.readiness="accepted"; row.accepted_commit="f".repeat(40); row.api_revision=Registry.API_REVISION
	if not expect(same(raw,expected_registry),"Archived TEST registry differs only by original explicit A3-L5 representative readiness row"): return {}
	var detached=C50Attempts.new(Registry.new(raw))
	var problem: String=detached.state_error(session)
	if not expect(problem.is_empty() and session.completed_main==detached.registry.main_route().slice(0,14) and session.story.level_id=="A3-L5" and same(session.story.snapshot,seed) and same(session.story.checkpoint,seed),"Complete authentic TEST prefix/checkpoint structure remains exact; actual Shell still supplies native validation",problem): return {}
	if not expect(Value.keys_error(seed,["schema_version","level_id","scene_path","paused","equipment_ids","player","level","shell"]).is_empty() and seed.schema_version==1 and seed.level_id=="A3-L5" and seed.scene_path==PRIORITY_ROOM and seed.paused==true and seed.player is Dictionary and seed.level is Dictionary and seed.shell is Dictionary and seed.equipment_ids is Dictionary,"Archived complete warning seed/identity remains closed"): return {}
	return {"registry":raw,"session":session,"seed":seed}
