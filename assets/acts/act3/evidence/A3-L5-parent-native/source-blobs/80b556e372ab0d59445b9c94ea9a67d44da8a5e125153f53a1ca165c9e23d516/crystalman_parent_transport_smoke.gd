extends SceneTree
## UNEXECUTED focused native whole-parent initial/representative entry transport.
## Later-stage selectors use explicit DECLARED TEST prior history, not an earned
## route clear. Current Player/Gate/Scheduler/Playback/art/floor are genuine.
## Real independent worlds, whole Player commit, actual camera/HUD and isolated
## public ProductionShell SaveStore/Continue/Retry. No full-playthrough gate.
const MainScene=preload("res://scenes/main.tscn")
const ProductionShell=preload("res://scripts/campaign/shell.gd")
const Registry=preload("res://scripts/campaign/registry.gd")
const Exact=preload("res://scripts/campaign/exact_json.gd")
const Value=preload("res://scripts/campaign/snapshot_codec.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const ROOM: String="res://scenes/acts/act3/a3_l5_crystalman.tscn"
const TEST_PREFIX: String="res://tests/acts/act3/fixtures/crystalman_declared_"
var game: Node
var level: CinderLevel
var hero: CinderPlayer
var production: CinderCampaignShell
var checks: int=0
var failures: int=0
var selected: int=0
var room_path: String=ROOM
var isolated: String=""
var quiet: int=0
var completion_count: int=0
var contact_count: int=0
var supported_contact: bool=false

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()==1 and args[0] in ["--declared-phase1","--declared-phase2","--declared-coda"]:
		selected=["--declared-phase1","--declared-phase2","--declared-coda"].find(args[0])+2
		room_path=TEST_PREFIX+str(selected)+".tscn"
	elif not args.is_empty(): expect(false,"Exact declared selector required"); quit(1); return
	root.size=Vector2i(340,736)
	root.content_scale_size=root.size
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	paused=false
	game=MainScene.instantiate()
	game.set("level_scene_path",room_path)
	root.add_child(game)
	game.call("open_bench")
	level=game.get("active_level") as CinderLevel
	hero=game.get("player") as CinderPlayer
	var entry_receipt: Dictionary={"level_present":level!=null,"hero_present":hero!=null,"tree_paused":paused,"level_id":level.level_id if level!=null else "","configuration_error":String(level.get("last_configuration_error")) if level!=null else "No parent"}
	if expect(level!=null and hero!=null and paused and level.level_id=="A3-L5" and String(level.get("last_configuration_error")).is_empty(),"Actual shared portrait Main enters authored production/declared parent",JSON.stringify(entry_receipt)):
		var packet: Dictionary=pair()
		if expect(not packet.player.is_empty() and not packet.level.is_empty() and level.snapshot_error_with_player(packet.level,packet.player).is_empty(),"Whole current native parent writes/validates",level.last_snapshot_error):
			var parsed: Dictionary=Exact.parse(Exact.stringify(packet))
			if expect(parsed.get("accepted",false) and same(parsed.value,packet),"Complete exact JSON retains native branches/progress/history"):
				await fresh_candidate(packet)
				negatives(packet)
				await campaign_transport(packet)
	await close()
	print("Crystalman full-parent focused source candidate: stage%d %d checks/%d failures. Later selectors declare prior history; no route-clear/art acceptance."%[selected,checks,failures])
	quit(0 if failures==0 else 1)

func pair() -> Dictionary:
	return {"player":hero.snapshot_state(),"level":level.snapshot_state_for_presentation(game.get("camera"),game.get("hud"))}

func fresh_candidate(saved: Dictionary) -> bool:
	var donor: Dictionary=pair()
	var input: String=var_to_bytes(game.call("get_input_observation_state")).hex_encode()
	var view := SubViewport.new()
	view.size=Vector2i(root.get_visible_rect().size)
	view.own_world_3d=true
	view.render_target_update_mode=SubViewport.UPDATE_DISABLED
	root.add_child(view)
	var receiver: Node=MainScene.instantiate()
	receiver.set("level_scene_path",room_path)
	view.add_child(receiver)
	paused=true # Main fresh preview resumes synchronously; no physics yield yet.
	var candidate: CinderLevel=receiver.get("active_level") as CinderLevel
	var actor: CinderPlayer=receiver.get("player") as CinderPlayer
	var camera: Camera3D=receiver.get("camera") as Camera3D
	var hud: GameHUD=receiver.get("hud") as GameHUD
	candidate.exit_level()
	var ok: bool=candidate.enter_restore_candidate(actor,receiver.get("fx"),receiver,saved.level,saved.player)
	watch(candidate); watch(actor)
	var observed: int=quiet
	ok=expect(ok and candidate.is_restore_candidate() and actor.get_world_3d()!=hero.get_world_3d(),"Fresh native candidate construction has distinct world/Player/floor",candidate.last_snapshot_error) and ok
	if ok: ok=expect(candidate.snapshot_error_with_player(saved.level,saved.player).is_empty() and actor.restore_state(saved.player) and candidate.restore_state(saved.level),"Outer Player once then actual complete current native unit and route quiet commit",candidate.last_snapshot_error)
	if ok:
		camera.global_transform=(game.get("camera") as Camera3D).global_transform # Explicit TEST saved camera context; no actor/source pose writes.
		hud.update_status(actor.hp,actor.max_hp,actor.shells,actor.max_shells,0,candidate.objective_text)
		await process_frame
		var optical: String=candidate.restore_candidate_presentation_error(camera,hud)
		ok=expect(optical.is_empty() and quiet==observed and same(actor.snapshot_state(),saved.player),"Actual current native Camera/HUD and complete Hero remain quiet",optical)
		if ok:
			ok=expect(candidate.finish_restore_candidate() and same(candidate.snapshot_state_for_presentation(camera,hud),saved.level),"Complete parent recapture remains exact after optically validated installation",candidate.last_snapshot_error)
		var camera_before: Transform3D=camera.global_transform
		camera.global_position+=Vector3(100,0,0) # TEST ONLY real view fault; exact restoration below.
		var error: String=String(candidate.call("candidate_presentation_error",camera,hud))
		camera.global_transform=camera_before
		expect(not error.is_empty() and quiet==observed,"Clipped actual current camera refuses quietly",error)
	expect(same(donor,pair()) and input==var_to_bytes(game.call("get_input_observation_state")).hex_encode(),"Independent candidate/optical faults preserve donor whole native/input state")
	candidate.exit_level()
	var refs: Array[WeakRef]=[weakref(candidate),weakref(actor),weakref(view)]
	view.queue_free()
	for _i: int in range(3): await process_frame
	expect(refs.all(func(ref: WeakRef) -> bool: return ref.get_ref()==null),"Normal independent parent/current-unit/floor/Player cleanup")
	return ok

func negatives(saved: Dictionary) -> void:
	var before: Dictionary=pair()
	var bad: Dictionary=saved.duplicate(true)
	bad.level.local.current_unit.state=true
	reject(bad,before,"Malformed current native state")
	bad=saved.duplicate(true); bad.level.local.route.phase_observed=true
	reject(bad,before,"Unearned pending spent observation")
	bad=saved.duplicate(true); bad.level.local.world.permanent_box[2]=16.0
	reject(bad,before,"Prototype-sized floor replacing permanent54m parent")
	bad=saved.duplicate(true); bad.level.local.route.entries[0].actor_clock_s=1000.0
	reject(bad,before,"Entry clock later than complete saved actor")
	if selected==0:
		bad=saved.duplicate(true); bad.level.local.current_unit.state.scheduler.profile=true
		reject(bad,before,"Malformed whole regular Scheduler profile")
		bad=saved.duplicate(true); bad.level.local.current_unit.state.sources["l5-offered-echo"].actor.physical=true
		reject(bad,before,"Malformed original Echo physical branch")
	var floor: CollisionShape3D=level.get("floor_collision") as CollisionShape3D
	var box: BoxShape3D=floor.shape as BoxShape3D
	var size_before: Vector3=box.size
	box.size.z=16.0 # TEST ONLY actual collision fault; original restored before yield.
	var refused: Dictionary=level.snapshot_state()
	var reason: String=level.last_snapshot_error
	box.size=size_before
	expect(refused.is_empty() and not reason.is_empty() and same(before,pair()),"Actual floor mutation refuses; exact original donor geometry restored",reason)

func reject(bad: Dictionary,before: Dictionary,label: String) -> void:
	var error: String=level.snapshot_error_with_player(bad.level,bad.player)
	expect(not error.is_empty() and same(before,pair()),label+" rejects atomically",error)

func campaign_transport(packet: Dictionary) -> bool:
	var camera: Camera3D=game.get("camera") as Camera3D
	var seed: Dictionary={"schema_version":1,"level_id":"A3-L5","scene_path":room_path,"paused":true,"equipment_ids":hero.equipment.snapshot(),"player":packet.player.duplicate(true),"level":packet.level.duplicate(true),"shell":{"api_revision":ProductionShell.SHELL_API,"anchor_normalized":[0.5,0.5],"input_sequence":0,"last_input_observation":{},"camera_focus":Value.vector3(camera.global_position-Vector3(0,18,13)),"shake_left_s":0.0,"difficulty_at_entry":"standard"}}
	var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Registry.DATA_PATH))
	for row: Dictionary in raw.levels:
		if row.id=="A3-L5":
			row.scene_path=room_path
			row.readiness="accepted" # TEST ONLY registry metadata; never production publication.
			row.accepted_commit="f".repeat(40)
			row.api_revision=Registry.API_REVISION
	isolated="user://test-crystalman-parent-%d-%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	production=ProductionShell.new()
	if not expect(production.configure_runtime(raw,isolated+"campaign.json",isolated+"settings.json",isolated+"preferences.json"),"Public Shell uses in-memory TEST row and isolated disk",production.campaign_error): return false
	root.add_child(production)
	paused=true
	for _i: int in range(3): await process_frame
	var state: Dictionary=production.attempts.state()
	state.completed_main=production.registry.main_route().slice(0,14)
	state.story={"kind":"story","level_id":"A3-L5","snapshot":seed.duplicate(true),"checkpoint":seed.duplicate(true)}
	if not expect(production.attempts.state_error(state).is_empty() and production.attempts.restore_session(state),"Explicit TEST predecessor/representative whole checkpoint seed validates",production.attempts.last_error): return false
	production.menu.continue_story_requested.emit()
	if not await settle("resume"): return false
	if not expect(same(production.capture_campaign_snapshot(),seed),"Public fresh Continue restores exact complete authored parent/native unit",production.campaign_error): return false
	var old_level: WeakRef=weakref(production.active_level)
	production.request_retry()
	if not await settle("resume"): return false
	if not expect(old_level.get_ref()==null and same(production.capture_campaign_snapshot(),seed),"Public Retry reconstructs exact current checkpoint and normally disposes old parent/floor"): return false
	production.request_pause()
	if not await settle("pause"): return false
	var reader=Store.new(isolated+"campaign.json")
	var disk: Dictionary=reader.read_payload()
	if not expect(reader.last_error.is_empty() and same(disk,production.attempts.state()) and same(production.attempts.state().story.checkpoint,seed),"Public Pause/SaveStore retains exact checkpoint on isolated disk",reader.last_error): return false
	if selected==4: return await coda_contact()
	return true

func coda_contact() -> bool:
	# Representative initial native coda spawn from the declared TEST scene.
	# Contact/completion are real production callbacks after actual physics;
	# the two prior phase receipts in this selector remain declared test data.
	production.active_level.completion_requested.connect(on_complete)
	production.active_level.contact_exit_requested.connect(on_contact)
	for _i: int in range(180):
		if paused and not production.is_pause_requested() and production.campaign_error.is_empty(): production.resume_campaign()
		await process_frame
		if not production.campaign_error.is_empty(): return expect(false,"Real coda/contact production operation",production.campaign_error)
		var state: Dictionary=production.attempts.state()
		if contact_count==1 and state.completed_main.size()==15 and not state.story.snapshot.level.progress.contact_exit_id.is_empty():
			return expect(completion_count==1 and supported_contact and state.story.snapshot.level.progress.completion_id=="crystalman-local-tethers-released" and state.story.snapshot.level.progress.contact_exit_id=="crystalman-local-escape" and state.story.snapshot.level.local.route.exit_state=="spent","Actual supported Hero contact forwards exact once-only final production callbacks over declared prior setup")
	return expect(false,"Finite actual coda physics/contact operation settles")

func on_complete(_level_id: String,_completion_id: String) -> void: completion_count+=1
func on_contact(_level_id: String,_exit_id: String) -> void:
	contact_count+=1
	supported_contact=production.player.is_on_floor() and production.player.global_position.z>=-14.0 and production.player.global_position.z<=40.0

func settle(page: String) -> bool:
	for _i: int in range(60):
		await process_frame
		if not production.campaign_error.is_empty(): return expect(false,"Focused public Shell operation",production.campaign_error)
		if paused and not production.is_pause_requested() and production.menu.page_name()==page and is_instance_valid(production.active_level): return true
	return expect(false,"Finite focused operation settles to "+page)

func watch(node: Node) -> void:
	for row: Dictionary in node.get_signal_list():
		if row.name in ["fired","died","action_resolved","world_action_executed","checkpoint_requested","completion_requested","contact_exit_requested"]:
			var callback: Callable=Callable(self,"quiet"+str(row.args.size()))
			if callback.is_valid(): node.connect(row.name,callback)
	for child: Node in node.get_children(): watch(child)
func quiet0() -> void: quiet+=1
func quiet1(_a: Variant) -> void: quiet+=1
func quiet2(_a: Variant,_b: Variant) -> void: quiet+=1
func quiet3(_a: Variant,_b: Variant,_c: Variant) -> void: quiet+=1

func close() -> void:
	paused=true
	if is_instance_valid(production): production.queue_free()
	if is_instance_valid(game):
		if is_instance_valid(level): level.exit_level()
		game.queue_free()
	for _i: int in range(3): await process_frame
	if not isolated.is_empty():
		for filename: String in ["campaign.json","campaign.json.bak","campaign.json.tmp","settings.json","preferences.json"]:
			var path: String=ProjectSettings.globalize_path(isolated+filename)
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(isolated))

func expect(ok: bool,label: String,detail: String="") -> bool:
	checks+=1
	if not ok: failures+=1; push_error(label+": "+detail)
	return ok
static func same(a: Variant,b: Variant) -> bool:
	var wire: String=Exact.stringify(a)
	return not wire.is_empty() and wire==Exact.stringify(b)
