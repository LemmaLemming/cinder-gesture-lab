extends SceneTree
## SOURCE-ONLY / UNEXECUTED diagnostic of one ORIGINAL saved C50-warning pair.
## No schema, geometry, source pose, deadline or native validator is changed.
## Two constructors only: immediate, then one ordinary PAUSED process boundary.
## Optional --shell uses explicit TEST_ONLY campaign predecessor/camera metadata;
## the original pair contains no Shell optical packet and grants no optical claim.
const Main=preload("res://scenes/main.tscn")
const Exact=preload("res://scripts/campaign/exact_json.gd")
const Value=preload("res://scripts/campaign/snapshot_codec.gd")
const Shell=preload("res://scripts/campaign/shell.gd")
const Registry=preload("res://scripts/campaign/registry.gd")
const SAMPLE: String="res://.cinder/crystalman-parent-regular-scenery-stage-native/samples/priority-C50-warning-whole-journal.json"
var saved: Dictionary={}
var saved_raw_sha: String=""
var rigs: Array[Dictionary]=[]
var production: CinderCampaignShell

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if not (args.is_empty() or (args.size()==1 and args[0]=="--shell")):
		push_error("Diagnostic accepts no args or --shell only"); quit(1); return
	var raw: String=FileAccess.get_file_as_string(SAMPLE)
	saved_raw_sha=raw.sha256_text()
	var parsed: Dictionary=Exact.parse(raw)
	if not parsed.get("accepted",false) or not parsed.get("value") is Dictionary:
		push_error("Exact original pair required"); quit(1); return
	saved=parsed.value
	if saved_raw_sha!="85362582579692830579219b551c9ac52d11c9b65691a43a435181d2b99c36fd":
		push_error("Original saved sample hash differs; do not infer or repair it"); quit(1); return
	root.size=Vector2i(340,736)
	root.content_scale_size=root.size
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var immediate: Dictionary=_new_rig()
	var guard: String=_guard(immediate)
	_print_probe("immediate-before-entry",immediate)
	_attempt("immediate-entry",immediate)
	_print_probe("immediate-after-entry",immediate)
	await process_frame
	if not paused or _guard(immediate)!=guard:
		push_error("Paused boundary changed constructor Actor/floor/input"); await _close(); quit(1); return
	_print_probe("same-failed-or-ready-rig-after-one-paused-frame",immediate)
	var delayed: Dictionary=_new_rig()
	guard=_guard(delayed)
	_print_probe("second-rig-before-paused-frame",delayed)
	await process_frame
	if not paused or _guard(delayed)!=guard:
		push_error("Paused registration observation changed constructor state"); await _close(); quit(1); return
	_print_probe("second-rig-after-one-paused-frame",delayed)
	_attempt("one-paused-frame-before-entry",delayed)
	if args.size()==1: await _public_shell()
	var unchanged: bool=FileAccess.get_file_as_string(SAMPLE).sha256_text()==saved_raw_sha
	await _close()
	print("Crystalman saved-floor DIAGNOSTIC finished; original pair unchanged=%s. Native ray/registration observations only; no runtime/art/optical/acceptance qualification."%str(unchanged))
	quit(0 if unchanged else 1)

func _new_rig() -> Dictionary:
	var view:=SubViewport.new()
	view.size=root.size
	view.own_world_3d=true
	view.render_target_update_mode=SubViewport.UPDATE_DISABLED
	root.add_child(view)
	var main: Node=Main.instantiate()
	main.set("level_scene_path",String(saved.level.scene_path))
	view.add_child(main)
	paused=true # Main resumes synchronously on creation; no frame/input yields.
	var parent: CinderLevel=main.get("active_level") as CinderLevel
	parent.exit_level() # Same fresh nonplayable recipient lifecycle as original check.
	var rig: Dictionary={"view":view,"main":main,"parent":parent,"actor":main.get("player")}
	rigs.append(rig)
	return rig

func _guard(rig: Dictionary) -> String:
	var actor: CinderPlayer=rig.actor
	var floor: CollisionShape3D=rig.parent.get("floor_collision") as CollisionShape3D
	var body: StaticBody3D=floor.get_parent() as StaticBody3D
	return var_to_bytes([actor.global_transform,actor.velocity,actor.get_world_action_clock(),actor.get_world_action_records(),actor.hp,actor.shells,actor.equipment.snapshot(),rig.main.call("get_input_observation_state"),floor.global_transform,(floor.shape as BoxShape3D).size,floor.disabled,body.collision_layer,body.collision_mask]).hex_encode()

func _print_probe(label: String,rig: Dictionary) -> void:
	var parent: CinderLevel=rig.parent
	var binding: Dictionary=parent.call("crystalman_regular_floor_binding")
	var floor: CollisionShape3D=binding.collision
	var body: StaticBody3D=floor.get_parent() as StaticBody3D
	var unit: Dictionary=saved.level.local.current_unit.state
	var reservation: Dictionary=unit.scheduler.reservations[0]
	var adapter: Dictionary=reservation.adapter
	var rect: Rect2=binding.safe_rect
	var radius: float=float(adapter.body_signature.radius)+0.01 # Exact existing shared SKIN.
	var feet: float=float(adapter.start[1])+float(adapter.body_signature.centre[1])-float(adapter.body_signature.height)*0.5
	var box: BoxShape3D=floor.shape as BoxShape3D
	var floor_rect:=Rect2(Vector2(floor.global_position.x,floor.global_position.z)-Vector2(box.size.x,box.size.z)*0.5,Vector2(box.size.x,box.size.z))
	var top: float=floor.global_position.y+box.size.y*0.5
	var shape_children: int=0
	for child: Node in body.get_children():
		if child is CollisionShape3D or child is CollisionPolygon3D: shape_children+=1
	var structural: Dictionary={"collision_inside_tree":floor.is_inside_tree(),"static_box":body is StaticBody3D and box!=null,"unrotated":floor.global_basis.is_equal_approx(Basis.IDENTITY),"body_not_queued":not body.is_queued_for_deletion(),"one_shape":shape_children==1,"mask1_layer":(body.collision_layer&1)!=0,"enabled":not floor.disabled,"rect_enclosed":floor_rect.encloses(rect),"feet_within_existing_tolerance":absf(feet-top)<=0.015}
	var probes: Array=[]
	for field: String in ["start","planned_endpoint"]:
		var point: Vector3=Value.read_vector3(adapter[field])
		var query:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.2,point-Vector3.UP*0.2,1)
		var hit: Dictionary=parent.get_world_3d().direct_space_state.intersect_ray(query)
		probes.append({"field":field,"point":adapter[field],"inside_eroded_floor":rect.grow(-radius).has_point(Vector2(point.x,point.z)),"hit":not hit.is_empty(),"hit_rid":str(hit.get("rid",RID())),"matches_bound_floor_rid":not hit.is_empty() and hit.rid==body.get_rid(),"hit_position":Value.vector3(hit.position) if hit.has("position") else []})
	var current: CinderLevel=parent.get("current_unit") as CinderLevel
	var scheduler: CinderThreatScheduler=current.get("threat_scheduler") as CinderThreatScheduler if current!=null else null
	print("READONLY FLOOR REGISTRATION "+JSON.stringify({"label":label,"paused":paused,"snapshot_sha256":saved_raw_sha,"saved_scheduler_clock_s":unit.scheduler.clock_s,"floor_path":str(body.get_path()),"floor_rid":str(body.get_rid()),"floor_space":str(PhysicsServer3D.body_get_space(body.get_rid())),"world_space":str(parent.get_world_3d().space),"floor_world_matches_parent":floor.get_world_3d()==parent.get_world_3d(),"scheduler_world_matches_floor":scheduler.get_world_3d()==floor.get_world_3d() if scheduler!=null else null,"floor_top":top,"source_feet_y":feet,"structural_floor_checks":structural,"route_y_equal":adapter.start[1]==adapter.planned_endpoint[1],"rays":probes}))

func _attempt(label: String,rig: Dictionary) -> void:
	var parent: CinderLevel=rig.parent
	var ok: bool=parent.enter_restore_candidate(rig.actor,rig.main.get("fx"),rig.main,saved.level,saved.player)
	print("READONLY CONSTRUCTOR ENTRY "+JSON.stringify({"label":label,"accepted":ok,"error":parent.last_snapshot_error,"original_pair_unchanged":Exact.stringify(saved)==FileAccess.get_file_as_string(SAMPLE)}))

func _public_shell() -> void:
	# The original artifact is a pair, not a Shell packet. These fields are
	# explicitly TEST_ONLY context; this diagnostic claims no optical success.
	var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Registry.DATA_PATH))
	for row: Dictionary in raw.levels:
		if row.id=="A3-L5": row.scene_path=saved.level.scene_path; row.readiness="accepted"; row.accepted_commit="f".repeat(40); row.api_revision=Registry.API_REVISION
	var seed: Dictionary={"schema_version":1,"level_id":"A3-L5","scene_path":saved.level.scene_path,"paused":true,"equipment_ids":saved.player.equipment.duplicate(true),"player":saved.player.duplicate(true),"level":saved.level.duplicate(true),"shell":{"api_revision":Shell.SHELL_API,"anchor_normalized":[0.5,0.5],"input_sequence":0,"last_input_observation":{},"camera_focus":Value.vector3(Value.read_vector3(saved.player.motion.position)+Vector3.UP*0.75),"shake_left_s":0.0,"difficulty_at_entry":"standard"}}
	var prefix: String="user://diagnostic-crystalman-floor-%d-%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	production=Shell.new()
	if not production.configure_runtime(raw,prefix+"campaign.json",prefix+"settings.json",prefix+"preferences.json"):
		print("READONLY PUBLIC SHELL "+JSON.stringify({"TEST_ONLY_camera_and_predecessors":true,"stage":"configure","error":production.campaign_error})); return
	root.add_child(production)
	paused=true
	for _i: int in range(3): await process_frame
	var state: Dictionary=production.attempts.state()
	var route: Array=production.registry.main_route()
	state.completed_main=route.slice(0,route.find("A3-L5")) # Explicit TEST predecessors only.
	state.story={"kind":"story","level_id":"A3-L5","snapshot":seed.duplicate(true),"checkpoint":seed.duplicate(true)}
	var error: String=production.attempts.state_error(state)
	print("READONLY PUBLIC SHELL "+JSON.stringify({"TEST_ONLY_camera_and_predecessors":true,"stage":"public-session-prevalidation","error":error,"campaign_error":production.campaign_error,"no_optical_authority_from_pair":true}))
	if not error.is_empty(): return # Never bypass public seed validation to force Continue.
	if not production.attempts.restore_session(state):
		print("READONLY PUBLIC SHELL "+JSON.stringify({"stage":"public-session-restore","error":production.attempts.last_error})); return
	production.menu.continue_story_requested.emit()
	for _i: int in range(30):
		await process_frame
		if not production.campaign_error.is_empty() or is_instance_valid(production.active_level): break
	print("READONLY PUBLIC SHELL "+JSON.stringify({"TEST_ONLY_camera_and_predecessors":true,"stage":"actual-public-Continue","error":production.campaign_error,"active_level_present":is_instance_valid(production.active_level),"no_optical_acceptance_claim":true}))

func _close() -> void:
	paused=true
	if is_instance_valid(production):
		if is_instance_valid(production.active_level): production.active_level.exit_level()
		production.queue_free()
	for rig: Dictionary in rigs:
		if is_instance_valid(rig.parent): rig.parent.exit_level()
		if is_instance_valid(rig.view): rig.view.queue_free()
	for _i: int in range(3): await process_frame
	rigs.clear()
