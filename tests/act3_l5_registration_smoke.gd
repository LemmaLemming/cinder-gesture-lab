extends "res://tests/acts/act3/crystalman_parent_transport_smoke.gd"
## Focused canonical row/prerequisite/native entry/terminal link.
## Reuses existing whole-parent helpers, without running their broad _run.
## First14 prefix is TEST history, never an earned route/checkpoint claim.
## Actual shared58 saved-warning99/0 and portrait85/0 remain reused evidence.
const ACCEPTED_CONTENT: String = "83a6efa2509b5c7f5e408f3ecb4324f53d1e496d"
const CanonicalParent = preload("res://scripts/acts/act3/crystalman_level.gd")
var _registration_finished: bool = false
var _canonical_registry_bytes: String = ""

func _initialize() -> void:
	create_timer(75.0,true).timeout.connect(func() -> void:
		if not _registration_finished:
			expect(false,"Focused canonical registration returning-loop bound")
			_finish_registration.call_deferred())
	_run.call_deferred()

func _run() -> void:
	root.size=Vector2i(340,736)
	root.content_scale_size=root.size
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	paused=true
	if not expect(OS.get_cmdline_user_args().is_empty(),"Canonical registration accepts no preview/scene/commit substitution"):
		await _finish_registration(); return
	_canonical_registry_bytes=FileAccess.get_file_as_string(Registry.DATA_PATH)
	var registry=Registry.new()
	var row: Dictionary=registry.entry("A3-L5")
	if not expect(registry.last_error.is_empty() and registry.ids().size()==24 and row.get("readiness")=="accepted" and row.get("accepted_commit")==ACCEPTED_CONTENT and row.get("api_revision")==Registry.API_REVISION and row.get("scene_path")==ROOM and registry.scene_error("A3-L5").is_empty(),"Actual canonical Crystalman row pins exact accepted content/scene/API",registry.last_error):
		await _finish_registration(); return
	if not expect(row.get("previous_main_id")=="A3-L4" and registry.entry("A3-L4").get("readiness")=="accepted" and row.get("next_main_id")==null and registry.next_main("A3-L5").is_empty() and registry.main_route()[-1]=="A3-L5","Accepted L4 prerequisite and terminal route link remain canonical"):
		await _finish_registration(); return
	isolated="user://test-act3-l5-canonical-%d-%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	production=ProductionShell.new()
	if not expect(production.configure_runtime({},isolated+"campaign.json",isolated+"settings.json",isolated+"preferences.json"),"Fresh Shell uses actual registry with isolated paths",production.campaign_error):
		await _finish_registration(); return
	root.add_child(production)
	if not await _wait_title(): await _finish_registration(); return
	var empty: Dictionary=production.attempts.state()
	if not expect(production.player==null and production.active_level==null and empty.completed_main.is_empty(),"Fresh canonical Title invents no Player, level or predecessor prefix"):
		await _finish_registration(); return
	production.menu.journey_requested.emit()
	for _i: int in range(4): await process_frame
	production.menu.select_level("A3-L5")
	var node: Button=production.menu.find_child("Node_A3_L5",true,false) as Button
	var action: Button=production.menu.find_child("LevelCardAction",true,false) as Button
	var body: Label=production.menu.find_child("LevelCardBody",true,false) as Label
	if not expect(paused and production.menu.page_name()=="journey" and node!=null and node.get_meta("campaign_state","")=="locked" and action!=null and action.disabled and body!=null and body.text.contains("A3-L4") and same(empty,production.attempts.state()) and production.active_level==null,"Accepted L5 Journey remains locked behind actual L4 without fabricating progress"):
		await _finish_registration(); return
	production.queue_free()
	for _i: int in range(3): await process_frame
	production=null
	# Existing preview/whole-parent seed technique, with ONLY canonical scene.
	# Ordinary native camera/floor callbacks run; no actor/source/pose write.
	paused=false
	game=MainScene.instantiate()
	game.set("level_scene_path",ROOM)
	root.add_child(game)
	var view_error: String="Initial canonical native view not observed"
	for _i: int in range(90):
		var installed: CinderLevel=game.get("active_level") as CinderLevel
		if installed!=null:
			view_error=String(installed.call("candidate_presentation_error",game.get("camera"),game.get("hud")))
			if view_error.is_empty(): break
		await process_frame
	if not expect(view_error.is_empty(),"Actual canonical initial parent/current Camera-HUD are ready",view_error):
		await _finish_registration(); return
	game.call("open_bench")
	level=game.get("active_level") as CinderLevel
	hero=game.get("player") as CinderPlayer
	if not expect(paused and level!=null and hero!=null and level.get_script()==CanonicalParent and level.level_id=="A3-L5" and level.scene_file_path==ROOM and level.contract_error().is_empty(),"Real canonical parent enters through shared Main services"):
		await _finish_registration(); return
	var original: Dictionary=pair()
	if not expect(not original.level.is_empty() and not original.player.is_empty() and level.snapshot_error_with_player(original.level,original.player).is_empty(),"Complete actual initial Player/parent packet validates",level.last_snapshot_error):
		await _finish_registration(); return
	var camera: Camera3D=game.get("camera") as Camera3D
	# Literal whole-envelope technique already used by parent transport helper.
	var seed: Dictionary={"schema_version":1,"level_id":"A3-L5","scene_path":ROOM,"paused":true,"equipment_ids":hero.equipment.snapshot(),"player":original.player.duplicate(true),"level":original.level.duplicate(true),"shell":{"api_revision":ProductionShell.SHELL_API,"anchor_normalized":[0.5,0.5],"input_sequence":0,"last_input_observation":{},"camera_focus":Value.vector3(camera.global_position-Vector3(0,18,13)),"shake_left_s":0.0,"difficulty_at_entry":"standard"}}
	var detached=TransportAttempts.new(registry)
	var state: Dictionary=detached.state()
	state.completed_main=registry.main_route().slice(0,14) # TEST ONLY history.
	state.story={"kind":"story","level_id":"A3-L5","snapshot":seed.duplicate(true),"checkpoint":seed.duplicate(true)}
	var problem: String=detached.state_error(state)
	if not expect(problem.is_empty(),"Explicit TEST first14 history carries one complete canonical entrance",problem):
		await _finish_registration(); return
	var writer=Store.new(isolated+"campaign.json")
	if not expect(writer.write_payload(state),"Native exact Store writes structural seed; real startup owns native validation",writer.last_error):
		await _finish_registration(); return
	production=ProductionShell.new()
	if not expect(production.configure_runtime({},isolated+"campaign.json",isolated+"settings.json",isolated+"preferences.json"),"Recipient Shell consumes actual canonical registry, without TEST readiness metadata",production.campaign_error):
		await _finish_registration(); return
	root.add_child(production)
	if not await _await_seeded_startup(state): await _finish_registration(); return
	production.menu.continue_story_requested.emit() # Existing public operation.
	if not await _wait_canonical_entry(): await _finish_registration(); return
	var restored: Dictionary=production.capture_campaign_snapshot()
	if not expect(same(production.registry.entry("A3-L5"),row) and production.active_level.get_script()==CanonicalParent and production.active_level.scene_file_path==ROOM and production.player.presentation_id=="act3_traveller" and production.player.get_world_3d()!=hero.get_world_3d() and same(restored,seed) and same(production.attempts.state(),state),"Public canonical Continue installs exact paused entrance in a distinct native world",production.campaign_error):
		await _finish_registration(); return
	var reader=Store.new(isolated+"campaign.json")
	if not expect(same(reader.read_payload(),state) and reader.last_error.is_empty(),"Canonical entry retains complete isolated disk/session packet",reader.last_error):
		await _finish_registration(); return
	expect(registry.next_main("A3-L5").is_empty() and production.registry.next_main("A3-L5").is_empty(),"Terminal canonical entry exposes no invented successor scene")
	await _finish_registration()

func _wait_title() -> bool:
	for _i: int in range(60):
		await process_frame
		if not production.campaign_error.is_empty(): return expect(false,"Fresh canonical startup error",production.campaign_error)
		if paused and not production.is_pause_requested() and production.menu!=null and production.menu.page_name()=="title": return true
	return expect(false,"Bounded fresh canonical Title settles")

func _wait_canonical_entry() -> bool:
	for _i: int in range(60):
		await process_frame
		if not production.campaign_error.is_empty(): return expect(false,"Canonical entry operation error",production.campaign_error)
		if paused and not production.is_pause_requested() and production.menu.page_name()=="resume" and is_instance_valid(production.active_level) and is_instance_valid(production.player): return true
	return expect(false,"Bounded actual canonical Level/Hero installation settles")

func _finish_registration() -> void:
	if _registration_finished: return
	_registration_finished=true
	var refs: Array[WeakRef]=[]
	if is_instance_valid(production):
		refs.append(weakref(production))
		if is_instance_valid(production.active_level): refs.append(weakref(production.active_level))
		if is_instance_valid(production.player): refs.append(weakref(production.player))
	if is_instance_valid(game):
		refs.append(weakref(game))
		if is_instance_valid(level): refs.append(weakref(level))
		if is_instance_valid(hero): refs.append(weakref(hero))
	await close()
	expect(refs.all(func(ref: WeakRef) -> bool: return ref.get_ref()==null),"Normal canonical entry/preview native owners are disposed")
	if not _canonical_registry_bytes.is_empty(): expect(FileAccess.get_file_as_string(Registry.DATA_PATH)==_canonical_registry_bytes,"Canonical registry bytes remain unchanged by focused registration")
	print("Act3 L5 canonical registration: %d checks/%d failures; canonical row/prerequisite/real initial entry/terminal link only. TEST first14 history; no earned route, repeated C50 save/Retry/portrait or final-contact execution credit."%[checks,failures])
	quit(0 if failures==0 else 1)
