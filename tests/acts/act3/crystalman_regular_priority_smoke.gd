extends "res://tests/acts/act3/crystalman_parent_transport_smoke.gd"
## SOURCE-ONLY/UNEXECUTED focused regular parent test. Initial scene position is
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

func _run() -> void:
	room_path=PRIORITY_ROOM
	if not expect(OS.get_cmdline_user_args().is_empty(),"One focused original regular priority case"): quit(1); return
	root.size=Vector2i(340,736)
	root.content_scale_size=root.size
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if await open_regular():
		if await genuine_offered_death():
			if await enter_priority():
				if await genuine_priority():
					game.call("open_bench")
					await process_frame
					var saved: Dictionary=pair()
					if expect(not saved.level.is_empty(),"Complete actual priority packet before public campaign transport",level.last_snapshot_error): await campaign_transport(saved)
	await close_regular()
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
	game.call("resume_lab")
	return true

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
	return expect(not paused and not barrier.expired and not hero.dead and hero.hp==baseline_hp and hero.equipment.snapshot()==baseline_kit and fixed and scheduler.get_clock()<=baseline_epoch+CASE_BUDGET_S and String(level.get("last_configuration_error")).is_empty() and String(regular.get("last_configuration_error")).is_empty() and not events.any(func(row: Dictionary) -> bool: return row.get("attack")=="blast"),"Native regular advance preserves original kit/HP/floor/bounded clocks",String(regular.get("last_configuration_error")))

func sample_parent(label: String) -> bool:
	game.call("open_bench")
	await process_frame
	var saved: Dictionary=pair()
	if not expect(paused and not saved.player.is_empty() and not saved.level.is_empty() and level.snapshot_error_with_player(saved.level,saved.player).is_empty(),"Complete current regular/parent native writer: "+label,level.last_snapshot_error): return false
	var parsed: Dictionary=Exact.parse(Exact.stringify(saved))
	if not expect(parsed.get("accepted",false) and same(parsed.value,saved),"Whole exact native JSON preserves all managed/ordinary branches: "+label): return false
	var sample_directory: String=ProjectSettings.globalize_path("res://captures/act3/crystalman-priority")
	if not expect(DirAccess.make_dir_recursive_absolute(sample_directory)==OK,"Native priority sample directory available"): return false
	var sample_file: FileAccess=FileAccess.open(sample_directory.path_join(label+".json"),FileAccess.WRITE)
	if not expect(sample_file!=null,"Exact actual current parent sample opens"): return false
	sample_file.store_string(Exact.stringify(saved)); sample_file.close()
	print("Crystalman priority sample: "+label+" at native "+str(scheduler.get_clock())+"s")
	if not await fresh_candidate(saved): return false
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
