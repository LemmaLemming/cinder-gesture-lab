extends "res://tests/acts/act1/a1_o2_terminal.gd"
## Focused versioned L3 producers and transport; native results recorded separately.
## Literal original whole CP2 Attempts; one supported TEST Hero-only placement.
## Public Shell owns Continue, preference, Resume and Pause/Save. No old-format
## reconstruction or native state edits. Fresh prefix setup alone uses six
## explicitly disclosed public TEST injuries; no ordinary-prefix credit.

const L3_GAME = preload("res://scripts/game.gd")
const FRESH_INPUTS: Array[String] = ["data/campaign/act1/a1_l3_difficulty_arrangements.json", "scripts/combat/encounter_arrangement.gd"]
const L3_SCENE: String = "res://scenes/acts/act1/a1_l3.tscn"
const L3_FULL = preload("res://scripts/acts/act1/mushroom_caverns_full.gd")
const L3_CODEC = preload("res://scripts/acts/act1/mushroom_caverns_route_codec.gd")
const ORIGINAL_SHA: String = "c1f4eb2333f61248998844dd7a13ecdb4cf2505448f7ab787cf984a78083c4ef"
const ORIGINAL_BYTES: int = 271077
const LEGACY_LIMIT_MS: int = 180000
const PROBE_IDS: Array[String] = ["crossed-1", "crossed-3"]
const OLD_PINS: Dictionary = {
	"scenes/acts/act1/a1_l3.tscn":"2c53526ff33cfb8b61bfcd6205a565bff2e37f75e24976e15351407cccfff556",
	"scripts/acts/act1/mushroom_caverns_full.gd":"e6669c37647542b6225dbcfabd4e2ec99a4085bf77e3d8ef1b757fdf176956d5",
	"scripts/acts/act1/mushroom_caverns_route.gd":"3784a019bfd5dec6e49b18e64e73ca00b7fd21dc6497258b9f948154762b18bb",
	"scripts/acts/act1/mushroom_caverns_route_codec.gd":"4a3c7071a91aa0a0d441396b4b34c6141b0df005fe3f3b729a0e6668b2ea2fa0"
}
const SELECTED_SOURCES: Array[String] = [
	"scenes/main.tscn", "scenes/acts/act1/a1_l3.tscn",
	"tests/acts/act1/a1_o2_terminal.gd", "tests/acts/act1/a1_o2_campaign.gd",
	"scripts/acts/act1/mushroom_caverns_full.gd", "scripts/acts/act1/mushroom_caverns_route.gd", "scripts/acts/act1/mushroom_caverns_route_codec.gd", "scripts/acts/act1/mushroom_caverns_layout.gd", "scripts/acts/act1/mushroom_caverns.gd",
	"scripts/acts/act1/mushroom_selenite.gd", "scripts/acts/act1/mushroom_selenite_codec.gd", "scripts/acts/act1/mushroom_selenite_approach.gd",
	"scripts/campaign/shell.gd", "scripts/campaign/registry.gd", "scripts/campaign/attempts.gd", "scripts/campaign/save_store.gd", "scripts/campaign/snapshot_codec.gd", "scripts/campaign/exact_json.gd", "scripts/campaign/level.gd",
	"scripts/player.gd", "scripts/game.gd", "scripts/equipment.gd", "scripts/combat/difficulty.gd", "scripts/combat/threat_scheduler.gd", "scripts/combat/lunge_motion.gd", "scripts/combat/body_sweep.gd", "scripts/combat/threat_geometry.gd", "scripts/combat/repulsion_route.gd",
	"scripts/environment/spore_field.gd", "scripts/environment/spore_repulsion.gd", "scripts/environment/spore_cluster.gd", "scripts/environment/scheduler_spore_source_protocol.gd", "scripts/cues/threat_cue.gd", "scripts/cues/interaction_cue.gd",
	"data/design/difficulty_profiles.json", "data/design/player_equipment.json"
]
class LegacyAdmissionProbe extends Node:
	var inspect: Callable
	func _physics_process(delta: float) -> void:
		if inspect.is_valid(): inspect.call(delta)

var options: Dictionary = {}
var source_hashes: Dictionary = {}
var original_envelope: String = ""
var original_payload_wire: String = ""
var original_unit: Dictionary = {}
var loaded_session: Dictionary = {}
var source_store_path: String = ""
var latest_probe: Dictionary = {}
var eligibility_rows: Array[Dictionary] = []
var first_admission: Dictionary = {}
var probe_node: LegacyAdmissionProbe
var assertions: Array[Dictionary] = []
var scope_complete: bool = false
var probe_rows_omitted: int = 0
var retained_checkpoint: Dictionary = {}
var fresh_entrance: Dictionary = {}
var fresh_injuries: Array[Dictionary] = []
var fresh_checkpoint_events: Array[Dictionary] = []

func _initialize() -> void:
	started_ms=Time.get_ticks_msec()
	test_root="user://test-act1-l3-difficulty-%d-%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	report_path="res://.cinder/a1-l3-difficulty-%d-%d.json" % [OS.get_process_id(),Time.get_ticks_usec()]
	old_fps=Engine.max_fps; old_audio=AudioServer.generate_bus_layout()
	for path: String in SELECTED_SOURCES: source_hashes[path]=FileAccess.get_sha256("res://"+path)
	if "--case=legacy-producer" not in OS.get_cmdline_user_args():
		for path: String in FRESH_INPUTS: source_hashes[path]=FileAccess.get_sha256("res://"+path)
	var self_path: String=get_script().resource_path
	source_hashes[self_path]=FileAccess.get_sha256(self_path)
	source_hashes[Registry.DATA_PATH]=FileAccess.get_sha256(Registry.DATA_PATH)
	process_frame.connect(_watchdog); node_added.connect(_observe_added); _run.call_deferred()

func _run() -> void:
	if "--case=ordinary" in OS.get_cmdline_user_args():
		scope_complete=await _run_ordinary_from_report(); await _finish(); return
	if "--case=portrait" in OS.get_cmdline_user_args():
		scope_complete=await _run_portrait_from_report(); await _finish(); return
	if "--case=transport" in OS.get_cmdline_user_args():
		# Parent appends its separate transport chunk and parser before promotion.
		await _run_transport_from_report(); await _finish(); return
	if "--case=fresh-producer" in OS.get_cmdline_user_args():
		scope_complete=await _run_fresh_contrast(); await _finish(); return
	root.size=Vector2i(540,1170)
	for argument: String in OS.get_cmdline_user_args():
		var key: String=argument.get_slice("=",0)
		if key not in ["--case","--source-store","--source-sha256","--report"] or options.has(key) or argument.find("=")<0:
			_expect(false,"unique named legacy case/source-store/hash/report selectors required"); await _finish(); return
		options[key]=argument.substr(argument.find("=")+1)
	if options.has("--report"): report_path=options["--report"]
	if not _expect(options.get("--case")=="legacy-producer" and options.get("--source-sha256")==ORIGINAL_SHA and options.has("--source-store") and report_path.begins_with("res://.cinder/") and not FileAccess.file_exists(report_path),"one explicit old-writer producer uses genuine donor SHA and new report path"): await _finish(); return
	registry_bytes=FileAccess.get_file_as_bytes(Registry.DATA_PATH)
	raw={}
	var registry:=Registry.new()
	if not _expect(registry.last_error.is_empty() and registry.entry("A1-L3").get("readiness")=="accepted" and registry.entry("A1-L3").get("scene_path")==L3_SCENE and registry.scene_error("A1-L3").is_empty(),"unchanged canonical registry exposes accepted production L3"): await _finish(); return
	for path: String in OLD_PINS:
		if not _expect(source_hashes.get(path)==OLD_PINS[path],"literal old writer remains frozen before producer: "+path): await _finish(); return
	for path: String in source_hashes:
		if not _expect(String(source_hashes[path]).length()==64,"selected actual input exists: "+path): await _finish(); return
	if not _seed_literal() or not await _new_shell(): await _finish(); return
	loaded_session=game.attempts.state()
	var expected_session: Dictionary=original_attempts.duplicate(true)
	for id: String in Equipment.IMPLEMENTED_IDS:
		if not expected_session.unlocked_equipment.has(id): expected_session.unlocked_equipment.append(id)
	if not _expect(_same(loaded_session,expected_session) and _durable(),"public startup preserves complete original Attempts except its supported availability migration"): await _finish(); return
	operation="public Title Continue original L3 CP2"
	game.menu.continue_story_requested.emit()
	if not await _await_operation(func()->bool:return _live("A1-L3") and paused and game.menu.page_name()=="resume","quiet current production CP2 Continue",16.0): await _finish(); return
	if not _expect(game.active_level.get_script()==L3_FULL and game.active_level.scene_file_path==L3_SCENE and _count_players(game.world)==1 and _same(game.capture_campaign_snapshot(),original_unit) and _same(game.attempts.state(),loaded_session) and _recipient_callbacks().is_empty(),"fresh public Continue exactly reconstructs original nineteen-source CP2 with zero installed-recipient callbacks"): await _finish(); return
	if not _record_l3_unit("actual old-format CP2 quiet Continue"): await _finish(); return
	game.menu.difficulty_preference_requested.emit("challenge")
	if not _expect(game.get_difficulty_preference()=="challenge" and _same(game.capture_campaign_snapshot(),original_unit) and _same(game.attempts.state(),loaded_session),"future Challenge preference preserves complete retained old CP2 unit and Attempts"): await _finish(); return
	if not _place_probe(): await _finish(); return
	_arm_probe()
	if not await _resume("genuine old-format Crossed Challenge boundary") or not await _wait_live(func()->bool:return not first_admission.is_empty(),"first genuine Crossed native admission",24.0): await _finish(); return
	if not _expect(first_admission.source_id=="crossed-1" and first_admission.profile.get("id")=="challenge" and first_admission.both_eligible_same_tick and first_admission.no_prior_forecast,"original order actually selects crossed-1 while crossed-1 and crossed-3 both qualify without a selected admission forecast"): await _finish(); return
	if not await _pause("actual old-format Challenge Crossed first admission Save"): await _finish(); return
	var unit: Dictionary=game.capture_campaign_snapshot()
	if not _expect(_old_shape(unit,2,"active") and unit.level.local.scheduler.profile.get("id")=="challenge" and _same(game.attempts.state().story.checkpoint,original_unit) and _same(unit,game.attempts.state().story.snapshot),"actual old writer saves native active Challenge while preserving original CP2 exactly"): await _finish(); return
	scope_complete=_record_l3_unit("actual old-format Challenge Crossed first admission Save")
	await _finish()

func _seed_literal() -> bool:
	source_store_path=String(options["--source-store"])
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(source_store_path)
	if not _expect(bytes.size()==ORIGINAL_BYTES and FileAccess.get_sha256(source_store_path)==ORIGINAL_SHA,"literal original format2 CP2 envelope has exact original bytes and SHA"): return false
	original_envelope=bytes.get_string_from_utf8()
	var envelope: Variant=JSON.parse_string(original_envelope)
	if not _expect(envelope is Dictionary and envelope.get("format_version")==2 and envelope.get("generation")==8 and envelope.get("payload_json") is String,"original native donor retains format2 generation8"): return false
	original_payload_wire=envelope.payload_json
	if not _expect(original_payload_wire.sha256_text()==envelope.sha256,"original literal payload matches its native Store hash"): return false
	var decoded: Dictionary=Exact.parse(original_payload_wire)
	if not _expect(decoded.get("accepted",false) and decoded.get("value") is Dictionary,"original whole Attempts exact wire parses without reconstruction"): return false
	original_attempts=decoded.value
	original_unit=original_attempts.get("story",{}).get("snapshot",{}).duplicate(true)
	if not _expect(original_attempts.get("completed_main")==["A1-L1","A1-L2"] and original_attempts.get("side_attempt")==null and _old_shape(original_unit,2,"approach") and _same(original_unit,original_attempts.story.checkpoint) and original_unit.level.local.scheduler.profile.is_empty(),"genuine production CP2 retains entire nine-key original authored1 history and nineteen actors"): return false
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_root))==OK and DirAccess.copy_absolute(ProjectSettings.globalize_path(source_store_path),ProjectSettings.globalize_path(test_root+"campaign.json"))==OK and FileAccess.get_sha256(test_root+"campaign.json")==ORIGINAL_SHA,"only unique isolated user Store receives byte-exact original envelope"): return false
	var store:=Store.new(test_root+"campaign.json")
	var loaded: Dictionary=store.read_payload()
	if not _expect(store.last_error.is_empty() and not store.loaded_backup and store.generation==8 and _same(loaded,original_attempts),"native checked Store reads genuine original whole Attempts"): return false
	setups.append({"kind":"TEST exact original whole CP2 Store copied into isolated path; no history splice or earned-prefix claim","source":source_store_path,"sha256":ORIGINAL_SHA,"bytes":ORIGINAL_BYTES,"exact_original_attempts":original_payload_wire,"original_envelope_json":original_envelope})
	return true

func _old_shape(unit: Dictionary, beat: int, stage: String) -> bool:
	if not _closed(unit) or unit.get("level_id")!="A1-L3" or unit.get("scene_path")!=L3_SCENE: return false
	var local: Dictionary=unit.level.local
	return Codec.keys_error(local,L3_CODEC.LOCAL_KEYS).is_empty() and local.get("authored_snapshot_version")==1 and not local.has("crossed_arrangement") and not local.has("api_revision") and local.get("beat_index")==beat and local.get("room_stage")==stage and local.get("completed_beats")==["umbrella-grove","breathing-chamber"] and local.get("actors",{}).size()==19

func _place_probe() -> bool:
	var before: Vector3=game.player.global_position
	var proposed:=Vector3(-1.4,before.y,-14.8)
	var measured: Dictionary=TerminalSweep.sweep(game.player,Transform3D(game.player.global_basis,proposed),Vector3.ZERO,game.active_level.call("scheduler_bindings").floors.values())
	if not _expect(paused and game.player.velocity==Vector3.ZERO and not measured.has("error") and not measured.get("collided",true) and measured.get("end") is Vector3 and measured.end.distance_to(proposed)<=TerminalSweep.position_rounding_bound(proposed,proposed),"disclosed TEST Hero-only Crossed probe pose has actual supported capsule and scenery clearance"): return false
	game.player.global_position=proposed
	setups.append({"kind":"TEST Hero position only; same actual Y, no source/heading/velocity/clock/camera/packet edits","before":_encode(before),"after":_encode(proposed),"earned_traversal":false,"support":_encode(measured)})
	return true

func _arm_probe() -> void:
	probe_node=LegacyAdmissionProbe.new()
	probe_node.process_physics_priority=199
	probe_node.inspect=_probe_crossed
	root.add_child(probe_node)
	game.active_level.connect("native_admission_published",_admission_observed)

func _probe_crossed(delta: float) -> void:
	if finishing or paused or not first_admission.is_empty() or not _live("A1-L3"): return
	var host: CinderLevel=game.active_level
	var state: Dictionary=host.call("route_state")
	if state.beat_index!=2 or state.room_stage!="active" or not game.player.get_threat_response_state().stable: return
	var owner: String=String(host.get("_forecast_owner"))
	var row: Dictionary={"clock_s":_scheduler().get_clock(),"physics_frame":Engine.get_physics_frames(),"hero_position":_encode(game.player.global_position),"sources":{},"both_eligible":true,"forecast_owner":owner,"forecast_current":host.call("_forecast_hint_current"),"forecast_points_count":(host.get("_forecast_points") as Array).size(),"approach_forecast_ids":(host.get("_approach_forecasts") as Dictionary).keys()}
	# Base._admit gates only its selected admission owner/proposal (lines225–226).
	# Other actors' motion bounds remain diagnostic; Base prunes those at200.
	row["no_prior_forecast"]=owner.is_empty() and row.forecast_points_count==0
	row["host_last_approach_error_before_probe"]=host.get("last_approach_error")
	row["approach_camera_request_ids"]=(host.get("_approach_camera_requests") as Dictionary).keys()
	var framing: Dictionary=game.get_camera_framing_state()
	row["actual_camera_plan_before_probe"]={"enabled":framing.get("enabled"),"accepted":framing.get("accepted"),"reason":framing.get("reason"),"point_count":framing.get("point_count"),"width":framing.get("width")}
	for id: String in PROBE_IDS:
		var actor: Act1MushroomSelenite=_source(id)
		var actual_last_error: String=actor.last_error
		var actual: Dictionary=actor.pure_presentation_state()
		var pure_approach: Dictionary=actor.propose_approach(game.player.global_position,delta)
		var control: Dictionary=_scheduler().source_control_state(actor)
		var distance: float=_distance(actor.global_position,game.player.global_position)
		var candidate: Dictionary=actor.preview_start(game.player.global_position,host.call("response_context",actual.role_id))
		var basic: bool=not actor.dead and not actor.dormant and actual.reservation_id.is_empty() and float(actual.hurt_left_s)==0.0 and distance>=.1 and distance<=4.5 and candidate.get("accepted",false)
		var gap: String="native preview unavailable"
		var window: bool=false
		var inside: bool=false
		var optics: String="native preview unavailable"
		if basic:
			var capsule: CapsuleShape3D=(host.get("_retained_capsules") as Dictionary)[id]
			inside=host.call("_inside_source_room",candidate.candidate.opening_position,capsule.radius)==true
			gap=String(host.call("_source_path_gap_error",id,actor.global_position,candidate.candidate.opening_position,delta))
			window=host.call("_proof_window",candidate.proof,candidate.candidate)==true
			var points: Array=host.camera_framing_points()
			points.append_array(host.call("_actor_points",id,candidate.candidate.opening_position))
			points.append_array(host.call("_lane_points",candidate.candidate.geometry))
			points.append_array(host.call("_response_points",candidate.proof.landing,candidate.proof.attack_position))
			optics=game.camera_framing_error(host.call("_bounded_union",points))
		var eligible: bool=basic and inside and gap.is_empty() and window and optics.is_empty()
		row.sources[id]={"actual_last_error_before_probe":actual_last_error,"pure_approach_proposal":_encode(pure_approach),"eligible":eligible,"distance":distance,"presentation":_encode(actual),"control":_encode(control),"preview":_encode(candidate),"inside_source_room":inside,"gap_error":gap,"ordinary_window":window,"current_view_error":optics}
		row.both_eligible=row.both_eligible and eligible
	latest_probe=row
	if eligibility_rows.size()<240: eligibility_rows.append(row.duplicate(true))
	else: probe_rows_omitted+=1

func _admission_observed(id: String, answer: Dictionary) -> void:
	if not first_admission.is_empty() or game.active_level.call("route_state").beat_index!=2: return
	var same_tick: bool=not latest_probe.is_empty() and latest_probe.clock_s==_scheduler().get_clock() and latest_probe.physics_frame==Engine.get_physics_frames()
	first_admission={"source_id":id,"exact_encoded_answer":Exact.stringify(_encode(answer)),"answer":_encode(answer),"profile":_scheduler().encounter_profile(),"clock_s":_scheduler().get_clock(),"both_eligible_same_tick":same_tick and latest_probe.get("both_eligible",false),"no_prior_forecast":same_tick and latest_probe.get("no_prior_forecast",false),"forecast_scope":"selected admission owner/proposal only; other motion forecast IDs are retained diagnostically","pre_admission":latest_probe.duplicate(true),"control":_encode(_scheduler().source_control_state(_source(id)))}

func _resume(label: String) -> bool:
	operation="public Resume: "+label
	game.menu.resume_requested.emit()
	return _expect(not paused and _live("A1-L3") and not game.player.dead,"public Resume releases actual healthy L3 simulation: "+label)

func _record_l3_unit(label: String) -> bool:
	var unit: Dictionary=game.capture_campaign_snapshot()
	var session: Dictionary=game.attempts.state()
	if not _expect(_closed(unit) and _same(unit,session.story.snapshot) and _same(session.story.checkpoint,retained_checkpoint if not retained_checkpoint.is_empty() else original_unit) and _durable(),"whole native L3 capture matches durable public Attempts: "+label): return false
	var ids: Dictionary={"world":str(game.world.get_instance_id()),"level":str(game.active_level.get_instance_id()),"player":str(game.player.get_instance_id()),"scheduler":str(_scheduler().get_instance_id()),"sources":{}}
	var positions: Dictionary={}
	for id: String in (game.active_level.get("sources") as Dictionary):
		ids.sources[id]=str(_source(id).get_instance_id()); positions[id]=_encode(_source(id).global_position)
	receipts.append({"label":label,"exact_snapshot":Exact.stringify(unit),"snapshot_sha256":Exact.stringify(unit).sha256_text(),"exact_player":Exact.stringify(unit.player),"exact_level":Exact.stringify(unit.level),"exact_attempts":Exact.stringify(session),"exact_earlier_checkpoint":Exact.stringify(session.story.checkpoint),"saved_envelope_json":FileAccess.get_file_as_string(test_root+"campaign.json"),"native_identities":ids,"source_positions":positions,"first_admission":first_admission.duplicate(true)})
	return true

func _expect(ok: bool, label: String) -> bool:
	var accepted: bool=super._expect(ok,label)
	assertions.append({"index":checks,"passed":ok,"label":label,"operation":operation,"elapsed_ms":Time.get_ticks_msec()-started_ms})
	return accepted

func _diagnostic() -> Dictionary:
	var value: Dictionary={"operation":operation,"paused":paused,"elapsed_ms":Time.get_ticks_msec()-started_ms,"latest_probe":latest_probe.duplicate(true)}
	if not is_instance_valid(game): return value
	value["campaign_error"]=game.campaign_error
	if is_instance_valid(game.menu): value["menu"]=game.menu.page_name()
	if is_instance_valid(game.player): value["player_response"]=_encode(game.player.get_threat_response_state()); value["hero_position"]=_encode(game.player.global_position); value["hero_hp"]=game.player.hp
	if is_instance_valid(game.active_level):
		value["host_last_approach_error"]=game.active_level.get("last_approach_error")
		value["actor_last_errors"]={}
		for id: String in PROBE_IDS: value.actor_last_errors[id]=_source(id).last_error
		value["scheduler_clock_s"]=_scheduler().get_clock()
		value["route"]=game.active_level.call("route_state"); value["snapshot_error"]=game.active_level.last_snapshot_error; value["capture_error"]=game.active_level.get("_capture_error"); value["encounter_error"]=game.active_level.get("last_encounter_error")
	return value

func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec()-started_ms>LEGACY_LIMIT_MS:
		_expect(false,"bounded "+String(options.get("--case","legacy-producer"))+" watchdog reached180 wall seconds"); _finish.call_deferred()

func _finish() -> void:
	if finishing: return
	finishing=true; paused=true; operation="normal L3 producer cleanup"
	if is_instance_valid(probe_node): probe_node.inspect=Callable(); probe_node.free()
	var refs: Array[WeakRef]=[]
	if is_instance_valid(preview):
		var preview_level: CinderLevel=preview.get("active_level") as CinderLevel
		if is_instance_valid(preview_level): preview_level.exit_level()
		refs.append_array(_refs(preview)); preview.free(); preview=null
	if is_instance_valid(game):
		if is_instance_valid(game.active_level): game.active_level.exit_level()
		refs.append_array(_refs(game)); game.free(); game=null
	paused=false
	await create_timer(.5,true).timeout
	await process_frame
	_expect((refs.is_empty() or _freed(refs)) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty() and get_nodes_in_group("environment_attack_targets").is_empty(),"normal native exit/Shell disposal frees descendants and source/field/cue groups")
	if not registry_bytes.is_empty(): _expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH)==registry_bytes,"canonical registry bytes remain unchanged")
	for path: String in source_hashes:
		_expect(FileAccess.get_sha256(path if path.begins_with("res://") else "res://"+path)==source_hashes[path],"selected source remains frozen: "+path)
	Engine.max_fps=old_fps; AudioServer.set_bus_layout(old_audio)
	var success: bool=scope_complete and failures==0
	var output:=FileAccess.open(report_path,FileAccess.WRITE)
	if output==null: _expect(false,"actual unique L3 producer report is writable"); success=false
	else:
		output.store_string(JSON.stringify({"case":options.get("--case","legacy-producer"),"checks":checks,"failures":failures,"first_failure":first_failure,"assertions":assertions,"scope_complete":scope_complete,"success":success,"elapsed_ms":Time.get_ticks_msec()-started_ms,"watchdog_ms":LEGACY_LIMIT_MS,"report_path":ProjectSettings.globalize_path(report_path),"source_input":source_store_path,"source_input_sha256":String(options.get("--source-sha256","")),"source_store_sha256":original_envelope.sha256_text() if not original_envelope.is_empty() else "","source_sha256":source_hashes,"setups":setups,"receipts":receipts,"first_admission":first_admission,"eligibility_rows":eligibility_rows,"probe_rows_omitted":probe_rows_omitted,"observations":observations,"operation_wait_overruns":operation_wait_overruns,"synchronous_observation_overruns":observation_overruns,"pause_registration_barriers":pause_registration_barriers,"fresh_checkpoint_events":fresh_checkpoint_events,"fresh_test_injuries":fresh_injuries,"shots":shots,"focus_observations":focus_rows,"scope":_view_scope() if options.get("--case") in ["ordinary","portrait"] else _transport_scope() if options.get("--case")=="transport" else _producer_scope() if options.get("--case")=="fresh-producer" else "Actual old-writer whole CP2 Continue/future Challenge/native Crossed admission/public Pause Save; one disclosed supported Hero-only TEST pose. Original complete Attempts and checkpoint retained; supported availability migration recorded. No packet/source/HP/heading/clock/progress edits, earned prefix, full route, ordinary attack execution, portrait/OS input, balance or performance claim."},"\t")); output.close()
	if root.focus_entered.is_connected(_view_focus.bind("window-focus-entered")): root.focus_entered.disconnect(_view_focus.bind("window-focus-entered"))
	if root.focus_exited.is_connected(_view_focus.bind("window-focus-exited")): root.focus_exited.disconnect(_view_focus.bind("window-focus-exited"))
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L3 DIFFICULTY: %d checks, %d failures; complete=%s; report=%s" % [checks,failures,str(scope_complete),report_path])
	quit(0 if success else 1)


# Fresh-v2 contrast only. No literal old packet is used to seed this case.
func _run_fresh_contrast() -> bool:
	root.size=Vector2i(540,1170)
	for argument: String in OS.get_cmdline_user_args():
		var key: String=argument.get_slice("=",0)
		if key not in ["--case","--report"] or options.has(key) or argument.find("=")<0:
			return _expect(false,"fresh producer accepts unique case/report selectors only")
		options[key]=argument.substr(argument.find("=")+1)
	if options.has("--report"): report_path=options["--report"]
	if not _expect(options.get("--case")=="fresh-producer" and report_path.begins_with("res://.cinder/") and not FileAccess.file_exists(report_path),"explicit fresh-v2 producer uses a unique report without a historical donor"): return false
	registry_bytes=FileAccess.get_file_as_bytes(Registry.DATA_PATH)
	raw={}
	var registry:=Registry.new()
	if not _expect(registry.last_error.is_empty() and registry.entry("A1-L3").get("readiness")=="accepted" and registry.entry("A1-L3").get("scene_path")==L3_SCENE and registry.scene_error("A1-L3").is_empty(),"canonical production L3 remains accepted and unchanged for fresh construction"): return false
	for path: String in source_hashes:
		if not _expect(String(source_hashes[path]).length()==64,"selected fresh producer input exists: "+path): return false
	if not _expect(L3_CODEC.AUTHORED_VERSION==2 and L3_CODEC.arrangement_configuration_error().is_empty(),"promoted new writer and closed authored recipes are required for fresh case"): return false
	if not check_recipes(_expect): return false
	if not await _seed_fresh_l3(registry) or not await _new_shell(): return false
	loaded_session=game.attempts.state()
	if not _expect(_same(loaded_session.story.snapshot,fresh_entrance) and _same(loaded_session.story.checkpoint,fresh_entrance) and loaded_session.completed_main==["A1-L1","A1-L2"] and loaded_session.side_attempt==null and _durable(),"actual fresh Title retains complete native entrance plus disclosed TEST predecessor unlock"): return false
	game.menu.continue_story_requested.emit()
	if not await _await_operation(func()->bool:return _live("A1-L3") and paused and game.menu.page_name()=="resume","public Continue installs genuine freshly written v2 entrance",16.0): return false
	if not _expect(game.active_level.get_script()==L3_FULL and _count_players(game.world)==1 and _same(game.capture_campaign_snapshot(),fresh_entrance) and _recipient_callbacks().is_empty(),"fresh distinct public recipient restores exact new entrance with zero installed-recipient callbacks"): return false
	retained_checkpoint=fresh_entrance.duplicate(true)
	if not _record_l3_unit("actual fresh-v2 source-pristine entrance Continue"): return false
	initial_hp=game.player.hp
	game.menu.difficulty_preference_requested.emit("standard")
	if not _expect(game.get_difficulty_preference()=="standard","original first two rooms use prospectively selected Standard"): return false
	game.active_level.checkpoint_requested.connect(_fresh_checkpoint_requested)
	# The source-pristine entrance is intentionally captured before physics.
	# Publicly resume at original spawn (z15, ahead of threshold13) so actual
	# gravity establishes ground contact before any supported TEST placement.
	var spawn: Vector3=game.player.global_position
	if not await _resume("fresh entrance natural floor settling") or not await _wait_live(func()->bool:return game.player.get_threat_response_state().stable,"actual original entrance settles on native floor",4.0): return false
	if not await _pause("fresh naturally settled entrance"): return false
	if not _expect(game.player.global_position.x==spawn.x and game.player.global_position.z==spawn.z and game.active_level.call("route_state").beat_index==0 and game.active_level.call("route_state").room_stage=="approach" and _scheduler().encounter_profile().is_empty(),"natural public entrance settling moves only actual vertical physics and starts no encounter"): return false
	setups.append({"kind":"actual public Resume natural gravity then Pause; no body/clock write","before":_encode(spawn),"after":_encode(game.player.global_position),"response":_encode(game.player.get_threat_response_state())})
	if not _record_l3_unit("actual fresh-v2 naturally settled entrance Save"): return false
	for room: int in range(2):
		if not await _fresh_setup_room(room): return false
	var cp2: Dictionary=game.capture_campaign_snapshot()
	if not _expect(_fresh_shape(cp2,2,"approach") and cp2.level.local.crossed_arrangement.is_empty() and cp2.level.local.scheduler.profile.is_empty() and cp2.level.local.scheduler.reservations.is_empty() and _same(cp2,retained_checkpoint) and fresh_injuries.size()==6 and fresh_checkpoint_events.size()==2 and game.player.hp==initial_hp,"six disclosed public TEST injuries produce actual native CP2, retained empty new receipt and unchanged Hero HP"): return false
	# Critical producer receipt precedes the prospective Crossed preference and pose.
	if not _record_l3_unit("actual fresh-v2 CP2 before Crossed") or not check_captured_unit(cp2,2,_expect): return false
	game.menu.difficulty_preference_requested.emit("challenge")
	if not _expect(game.get_difficulty_preference()=="challenge" and _same(game.capture_campaign_snapshot(),cp2) and _same(game.attempts.state().story.checkpoint,cp2),"prospective Challenge does not relabel or rewrite genuine earlier CP2"): return false
	if not _place_probe(): return false
	_arm_probe()
	if not await _resume("genuine fresh-v2 Crossed Challenge boundary") or not await _wait_live(func()->bool:return not first_admission.is_empty(),"first genuine fresh-v2 Crossed native admission",24.0): return false
	if not _expect(first_admission.source_id=="crossed-3" and first_admission.profile.get("id")=="challenge" and first_admission.both_eligible_same_tick and first_admission.no_prior_forecast,"fresh Challenge selects crossed-3 while crossed-1 and crossed-3 both qualify without a selected admission forecast"): return false
	if not await _pause("actual fresh-v2 Challenge Crossed first admission Save"): return false
	var unit: Dictionary=game.capture_campaign_snapshot()
	var recipe: Dictionary=L3_CODEC.fresh_crossed_arrangement("challenge")
	if not _expect(_fresh_shape(unit,2,"active") and _same(unit.level.local.crossed_arrangement,recipe) and unit.level.local.scheduler.profile.get("id")=="challenge" and game.active_level.call("admission_source_ids")==recipe.order and _same(game.attempts.state().story.checkpoint,cp2) and _same(unit,game.attempts.state().story.snapshot),"actual new whole Save retains selected inner-first receipt and original empty-receipt CP2"): return false
	return _record_l3_unit("actual fresh-v2 Challenge Crossed first admission Save") and check_captured_unit(unit,2,_expect)

func _seed_fresh_l3(registry: CinderCampaignRegistry) -> bool:
	operation="fresh native Main source-pristine L3 constructor"
	paused=true
	preview=MainScene.instantiate(); preview.set("level_scene_path",L3_SCENE); root.add_child(preview)
	# Main.reset_lab releases pause synchronously; repause before any frame.
	paused=true
	await process_frame; await process_frame
	var hero: CinderPlayer=preview.get("player") as CinderPlayer
	var level: CinderLevel=preview.get("active_level") as CinderLevel
	var camera: Camera3D=preview.get("camera") as Camera3D
	if not _expect(hero!=null and level!=null and camera!=null and level.get_script()==L3_FULL and level.scene_file_path==L3_SCENE and level.contract_error().is_empty(),"actual production Main constructs one new-format L3 native source unit"): return false
	var player_state: Dictionary=hero.snapshot_state()
	var level_state: Dictionary=level.snapshot_state()
	var anchor: Vector2=preview.call("get_aim_anchor_normalized")
	var shell_state: Dictionary={"api_revision":Shell.SHELL_API,"anchor_normalized":[anchor.x,anchor.y],"input_sequence":0,"last_input_observation":{},"camera_focus":Codec.vector3(camera.global_position-L3_GAME.CAMERA_OFFSET),"shake_left_s":0.0,"difficulty_at_entry":"standard"}
	fresh_entrance={"schema_version":1,"level_id":"A1-L3","scene_path":L3_SCENE,"paused":true,"equipment_ids":hero.equipment.snapshot(),"player":player_state,"level":level_state,"shell":shell_state}
	var error: String=level.snapshot_error_with_player(level_state,player_state) if not level_state.is_empty() and not player_state.is_empty() else level.last_snapshot_error
	var source_pristine: bool=_fresh_shape(fresh_entrance,0,"approach") and hero.global_position==level.spawn_position() and fresh_entrance.level.local.scheduler.clock_s==0.0 and fresh_entrance.level.local.scheduler.profile.is_empty() and fresh_entrance.level.local.scheduler.reservations.is_empty() and fresh_entrance.level.local.crossed_arrangement.is_empty() and fresh_entrance.level.progress.checkpoint_ids.is_empty() and not fresh_entrance.level.progress.completed
	if source_pristine:
		for id: String in fresh_entrance.level.local.actors:
			var actor: Dictionary=fresh_entrance.level.local.actors[id]
			source_pristine=source_pristine and actor.dormant and not actor.dead
	if not _expect(source_pristine and error.is_empty(),"new writer captures actual dormant19/clock0/empty-receipt entrance without a historical packet: "+error): return false
	var model:=Attempts.new(registry)
	var payload: Dictionary=model.state()
	payload.completed_main=["A1-L1","A1-L2"]
	payload.story={"kind":"story","level_id":"A1-L3","snapshot":fresh_entrance.duplicate(true),"checkpoint":fresh_entrance.duplicate(true)}
	var store:=Store.new(test_root+"campaign.json"); store.payload_validator=model.saved_payload_error
	if not _expect(model.state_error(payload).is_empty() and model.restore_session(payload) and store.write_payload(model.state()),"validated public Attempts/Store persist only TEST predecessor unlock plus actual fresh native entrance: "+model.last_error+store.last_error): return false
	setups.append({"kind":"TEST completed-main predecessor unlock only; no earned prior route or local history fabrication","completed_main":["A1-L1","A1-L2"],"actual_story_scene":L3_SCENE,"exact_native_entrance":Exact.stringify(fresh_entrance),"exact_attempts":Exact.stringify(model.state()),"saved_envelope_json":FileAccess.get_file_as_string(test_root+"campaign.json")})
	var refs: Array[WeakRef]=_refs(preview)
	level.exit_level(); preview.free(); preview=null
	return _expect(_freed(refs),"normal Main disposal frees fresh donor native descendants")

func _fresh_shape(unit: Dictionary, beat: int, stage: String) -> bool:
	if not _closed(unit) or unit.get("level_id")!="A1-L3" or unit.get("scene_path")!=L3_SCENE: return false
	var local: Dictionary=unit.level.local
	var keys: Array=L3_CODEC.LOCAL_KEYS.duplicate(); keys.append("crossed_arrangement")
	return Codec.keys_error(local,keys).is_empty() and local.get("authored_snapshot_version")==2 and local.get("crossed_arrangement") is Dictionary and not local.has("api_revision") and local.get("beat_index")==beat and local.get("room_stage")==stage and local.get("completed_beats")==L3_CODEC.BEAT_IDS.slice(0,beat) and local.get("actors",{}).size()==19

func _fresh_setup_room(room: int) -> bool:
	var host: CinderLevel=game.active_level
	var state: Dictionary=host.call("route_state")
	var spec: Dictionary=host.call("normal_route_spec")
	if not _expect(paused and room in [0,1] and state.beat_index==room and state.room_stage=="approach" and state.completed_beats==L3_CODEC.BEAT_IDS.slice(0,room),"focused constructor begins only genuinely entitled room "+str(room)): return false
	var before: Vector3=game.player.global_position
	var proposed:=Vector3(0,before.y,float(spec.thresholds[room])-.4)
	var support: Dictionary=TerminalSweep.sweep(game.player,Transform3D(game.player.global_basis,proposed),Vector3.ZERO,host.call("scheduler_bindings").floors.values())
	setups.append({"kind":"pure TEST prefix placement query before any assignment","room":room,"from":_encode(before),"proposed":_encode(proposed),"support":_encode(support)})
	if not _expect(game.player.velocity==Vector3.ZERO and not support.has("error") and not support.get("collided",true) and support.get("end") is Vector3 and support.end.distance_to(proposed)<=TerminalSweep.position_rounding_bound(proposed,proposed),"focused room-entry Hero pose has actual capsule support and scenery clearance"): return false
	game.player.global_position=proposed
	setups.append({"kind":"TEST Hero-only supported prefix placement; native parent retains activation/history authority","room":room,"before":_encode(before),"after":_encode(proposed),"support":_encode(support),"earned_traversal":false})
	if not await _resume("focused public TEST setup of room "+str(room)) or not await _wait_live(func()->bool:
		var current: Dictionary=host.call("route_state")
		var points: Array=host.camera_framing_points()
		return current.beat_index==room and current.room_stage=="active" and current.encounter_started and game.player.get_threat_response_state().stable and not points.is_empty() and game.camera_framing_error(points).is_empty(),"native room activation and current full framing before TEST injuries",16.0): return false
	var ids: Array=spec.room_sources[room]
	if not _expect(host.call("current_source_ids")==ids and _scheduler().encounter_profile().get("id")=="standard" and game.player.hp==initial_hp,"actual Standard epoch activates only entitled original sources at unchanged Hero HP"): return false
	var generation_before: int=_save_generation()
	for id: String in ids:
		var actor: Act1MushroomSelenite=_source(id)
		var before_hp: float=actor.hp
		var before_state: Dictionary=actor.pure_presentation_state()
		if not _expect(not actor.dormant and not actor.dead and before_hp>0.0,"public TEST injury targets only actual living entitled source: "+id): return false
		var damage: Dictionary=actor.take_damage(before_hp,Vector3.ZERO)
		var row: Dictionary={"source_id":id,"room":room,"before":_encode(before_state),"result":_encode(damage),"after":_encode(actor.pure_presentation_state()),"ordinary_primary":false,"kind":"disclosed public TEST source.take_damage"}
		fresh_injuries.append(row); setups.append(row.duplicate(true))
		if not _expect(damage.get("accepted",false) and damage.get("hp_damage")==before_hp and actor.dead,"actual public TEST injury lifecycle defeats one original source: "+id): return false
	if not await _wait_live(func()->bool:return fresh_checkpoint_events.size()==room+1 and paused,"actual native checkpoint followed by requested public Pause",16.0,true): return false
	# Shell's native checkpoint registration and our public Pause each need at
	# most two process signals. Observe both before the completion wait.
	var barrier_started_ms: int=Time.get_ticks_msec()
	for signal_index: int in range(4):
		await process_frame
		if not _operation_healthy(): return false
		if not _expect(paused,"native checkpoint and public Pause retain custody at signal "+str(signal_index+1)): return false
	pause_registration_barriers.append({"label":"fresh room "+str(room)+" checkpoint then public Pause","actual_process_signals":4,"barrier_wall_ms":Time.get_ticks_msec()-barrier_started_ms,"scope":"two actual queued registration operations; no native timeout/guard change or performance claim"})
	if not await _await_operation(func()->bool:return _fresh_boundary_ready(room+1,generation_before),"actual durable checkpoint and visible public Pause for room "+str(room),16.0): return false
	var captured: Dictionary=game.capture_campaign_snapshot()
	var checkpoint: Dictionary=game.attempts.state().story.checkpoint
	if not _expect(_fresh_shape(captured,room+1,"approach") and _same(captured,checkpoint) and captured.level.local.crossed_arrangement.is_empty() and captured.level.local.scheduler.profile.is_empty() and captured.level.local.scheduler.reservations.is_empty() and _durable() and game.player.hp==initial_hp,"real native clear publishes exact whole new checkpoint without starting future room"): return false
	retained_checkpoint=checkpoint.duplicate(true)
	return _record_l3_unit("actual fresh-v2 native checkpoint after room "+str(room))

func _fresh_checkpoint_requested(level_id: String, checkpoint_id: String, kind: String) -> void:
	fresh_checkpoint_events.append({"level_id":level_id,"checkpoint_id":checkpoint_id,"kind":kind,"physics_frame":Engine.get_physics_frames(),"scheduler_clock_s":_scheduler().get_clock(),"requested_at_ms":Time.get_ticks_msec()-started_ms})
	# Shell connected its checkpoint handler during installation. This public
	# Pause therefore queues after it and prevents automatic resume at CP1/CP2.
	game.request_pause()

func _fresh_boundary_ready(beat: int, generation_before: int) -> bool:
	if not _live("A1-L3") or not paused or not game.menu.is_open() or game.menu.page_name()!="pause" or _save_generation()<=generation_before: return false
	var session: Dictionary=game.attempts.state()
	return session.story.snapshot.level.local.beat_index==beat and session.story.checkpoint.level.local.beat_index==beat and session.story.snapshot.level.local.room_stage=="approach" and session.story.checkpoint.level.progress.checkpoint_id==L3_CODEC.CHECKPOINT_IDS[beat-1] and fresh_checkpoint_events.size()==beat and fresh_checkpoint_events[beat-1].level_id=="A1-L3" and fresh_checkpoint_events[beat-1].checkpoint_id==L3_CODEC.CHECKPOINT_IDS[beat-1] and fresh_checkpoint_events[beat-1].kind=="encounter"

func _producer_scope() -> String:
	return "Fresh new-writer Main entrance and public Shell Continue under disclosed TEST predecessor unlock; two real native rooms/checkpoints via six public source.take_damage TEST injuries and supported Hero-only poses. Actual empty-receipt CP2 saved before prospective Challenge; first crossed-3 admission requires same-tick native eligibility of1/3 with no selected admission forecast, then actual public Pause whole Save. No old packet upgrade, direct HP/phase/heading/clock/progress mutation, earned prefix, ordinary attack execution, portrait/OS input, full-route, balance or performance claim."


# Fold into the authorized fixture; consumes only a successful actual producer report.
func _seed_transport_report() -> bool:
	source_store_path=String(options.get("--source-report",""))
	var digest: String=String(options.get("--source-sha256",""))
	if not _expect(source_store_path.begins_with("res://") and digest.length()==64 and FileAccess.get_sha256(source_store_path)==digest,"transport consumes one exact frozen native producer report"): return false
	var report: Variant=JSON.parse_string(FileAccess.get_file_as_string(source_store_path))
	if not _expect(report is Dictionary and report.get("success")==true and report.get("scope_complete")==true and report.get("failures")==0 and report.get("receipts") is Array and not report.receipts.is_empty(),"transport donor is a completed actual successful producer, not a fabricated packet"): return false
	for row: Dictionary in report.get("assertions",[]):
		if not _expect(row.get("passed")==true,"native source producer assertion passed: "+String(row.get("label",""))): return false
	var receipt: Dictionary=report.receipts.back()
	original_envelope=String(receipt.get("saved_envelope_json",""))
	var envelope: Variant=JSON.parse_string(original_envelope)
	if not _expect(envelope is Dictionary and envelope.get("format_version")==2 and envelope.get("payload_json") is String and envelope.get("generation",0)>0 and String(envelope.payload_json).sha256_text()==envelope.get("sha256"),"actual producer's complete native Store envelope retains its literal checked payload"): return false
	original_payload_wire=envelope.payload_json
	var parsed: Dictionary=Exact.parse(original_payload_wire)
	if not _expect(parsed.get("accepted")==true and parsed.get("value") is Dictionary,"actual producer whole Attempts exact wire decodes without reconstruction"): return false
	original_attempts=parsed.value
	original_unit=original_attempts.get("story",{}).get("snapshot",{}).duplicate(true)
	retained_checkpoint=original_attempts.get("story",{}).get("checkpoint",{}).duplicate(true)
	var codec:=L3_CODEC.new()
	if not _expect(_closed(original_unit) and _closed(retained_checkpoint) and original_unit.level_id=="A1-L3" and original_unit.scene_path==L3_SCENE and original_unit.level.local.beat_index==2 and original_unit.level.local.room_stage=="active" and retained_checkpoint.level.local.beat_index==2 and retained_checkpoint.level.local.room_stage=="approach" and original_unit.level.local.authored_snapshot_version==retained_checkpoint.level.local.authored_snapshot_version and codec.metadata_error(original_unit.level.local).is_empty() and codec.metadata_error(retained_checkpoint.level.local).is_empty() and Exact.stringify(original_unit)==receipt.get("exact_snapshot") and Exact.stringify(original_attempts)==receipt.get("exact_attempts"),"source receipt is the genuine active Crossed whole Session with its own earlier CP2 and retained format"): return false
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_root))==OK,"transport isolated unique Store directory exists"): return false
	var file:=FileAccess.open(test_root+"campaign.json",FileAccess.WRITE)
	if file==null: return _expect(false,"actual envelope copy is writable")
	file.store_string(original_envelope); file.close()
	if not _expect(FileAccess.get_file_as_string(test_root+"campaign.json")==original_envelope,"isolated Store receives only byte-exact genuine producer envelope"): return false
	setups.append({"kind":"TEST exact complete actual producer Store copy; no history splice or earned prefix","source_report":source_store_path,"source_report_sha256":digest,"source_case":report.get("case"),"source_receipt_label":receipt.get("label"),"source_store_sha256":original_envelope.sha256_text(),"source_snapshot_sha256":Exact.stringify(original_unit).sha256_text(),"source_attempts_sha256":original_payload_wire.sha256_text()})
	return true

func _run_transport_from_report() -> void:
	root.size=Vector2i(540,1170)
	for argument: String in OS.get_cmdline_user_args():
		var key: String=argument.get_slice("=",0)
		if key not in ["--case","--report","--source-report","--source-sha256","--retry-profile"] or options.has(key) or argument.find("=")<0:
			_expect(false,"transport accepts unique case/report/source/hash/retry-profile selectors"); return
		options[key]=argument.substr(argument.find("=")+1)
	if options.has("--report"): report_path=options["--report"]
	if not _expect(options.get("--case")=="transport" and report_path.begins_with("res://.cinder/") and not FileAccess.file_exists(report_path),"transport uses one explicit case and new native report path"): return
	registry_bytes=FileAccess.get_file_as_bytes(Registry.DATA_PATH); raw={}
	for path: String in source_hashes:
		if not _expect(String(source_hashes[path]).length()==64,"selected transport input exists: "+path): return
	source_hashes[String(options.get("--source-report",""))]=FileAccess.get_sha256(String(options.get("--source-report","")))
	var retry_profile: String=String(options.get("--retry-profile","standard"))
	if not _expect(retry_profile in ["assisted","standard","challenge"],"one explicit native profile for the earlier Retry boundary"): return
	if not _seed_transport_report() or not await _new_shell(): return
	loaded_session=game.attempts.state()
	var expected: Dictionary=original_attempts.duplicate(true)
	for id: String in Equipment.IMPLEMENTED_IDS:
		if not expected.unlocked_equipment.has(id): expected.unlocked_equipment.append(id)
	if not _expect(_same(loaded_session,expected) and _durable(),"fresh independent current-reader Shell retains whole actual donor Attempts with only supported availability migration"): return
	operation="public fresh disk Title Continue actual active Crossed Save"
	game.menu.continue_story_requested.emit()
	if not await _await_operation(func()->bool:return _live("A1-L3") and paused and game.menu.page_name()=="resume","current-reader quiet actual active Crossed Continue",16.0): return
	if not _expect(_same(game.capture_campaign_snapshot(),original_unit) and _same(game.attempts.state(),loaded_session) and _recipient_callbacks().is_empty() and _count_players(game.world)==1,"independent fresh Continue quietly restores exact whole active Save/Player/Scheduler/proofs/fields/receipt with zero installed recipient callbacks"): return
	var native_profile: String=String(original_unit.level.local.scheduler.profile.id)
	var opposite: String="assisted" if native_profile=="challenge" else "challenge"
	game.menu.difficulty_preference_requested.emit(opposite)
	if not _expect(game.get_difficulty_preference()==opposite and _same(game.capture_campaign_snapshot(),original_unit) and _same(game.attempts.state(),loaded_session),"opposite future preference cannot relabel retained actual native profile, priority receipt or whole Attempts"): return
	if not _record_l3_unit("actual independent current-reader active Crossed Continue with opposite preference"): return
	if not check_captured_unit(original_unit,int(original_unit.level.local.authored_snapshot_version),_expect) or not await _metadata_constructor_negative(original_unit): return
	if not await _pause("current-reader exact retained active Crossed Save"): return
	if not _expect(_same(game.capture_campaign_snapshot(),original_unit) and _same(game.attempts.state().story.checkpoint,retained_checkpoint),"public paused Save retains exact genuine whole active packet and its original earlier CP2"): return
	if not _record_l3_unit("actual current-reader exact retained active Crossed Save"): return
	var button:=game.menu.find_child("RetryButton",true,false) as Button
	if not _expect(button!=null and button.is_visible_in_tree() and not button.disabled,"production Pause exposes enabled Retry Checkpoint button"): return
	var before: Dictionary=_transport_ids()
	var refs: Array[WeakRef]=_refs(game.world)
	operation="actual RetryButton restores actual earlier CP2"
	button.pressed.emit()
	if not await _await_operation(func()->bool:return _live("A1-L3") and paused and game.menu.page_name()=="resume" and _transport_ids()!=before,"actual RetryButton quietly installs genuine earlier CP2",16.0): return
	if not _expect(_same(game.capture_campaign_snapshot(),retained_checkpoint) and _same(game.attempts.state().story.snapshot,retained_checkpoint) and _same(game.attempts.state().story.checkpoint,retained_checkpoint) and _freed(refs) and _transport_all_new(before,_transport_ids()) and _recipient_callbacks().is_empty() and _durable(),"Retry frees active donor and exactly restores original native earlier checkpoint with no callbacks or receipt leakage"): return
	receipts.append({"label":"actual RetryButton exact earlier CP2","exact_snapshot":Exact.stringify(game.capture_campaign_snapshot()),"exact_attempts":Exact.stringify(game.attempts.state()),"saved_envelope_json":FileAccess.get_file_as_string(test_root+"campaign.json"),"before_identities":before,"native_identities":_transport_ids(),"same_process_all_new":true,"scope":"actual production Button pressed signal; no OS click or earned prefix"})
	var version: int=int(retained_checkpoint.level.local.authored_snapshot_version)
	if not _expect((not retained_checkpoint.level.local.has("crossed_arrangement")) if version==1 else retained_checkpoint.level.local.crossed_arrangement.is_empty(),"earlier CP2 retains literal legacy omission or fresh-v2 empty receipt"): return
	game.menu.difficulty_preference_requested.emit(retry_profile)
	if not _expect(game.get_difficulty_preference()==retry_profile and _same(game.capture_campaign_snapshot(),retained_checkpoint),"Retry changes only future preference before a genuine new native Crossed begin"): return
	if not _place_probe(): return
	_arm_probe()
	if not await _resume("actual earlier Retry native Crossed boundary") or not await _wait_live(func()->bool:return not first_admission.is_empty(),"actual first Retry Crossed admission",24.0): return
	var selected: String="crossed-3" if version==2 and retry_profile=="challenge" else "crossed-1"
	if not _expect(first_admission.source_id==selected and first_admission.profile.get("id")==retry_profile and first_admission.both_eligible_same_tick and first_admission.no_prior_forecast,"genuine earlier Retry selects correct retained-format order while both native candidates qualify without prior selected forecast"): return
	if not await _pause("actual Retry Crossed first admission Save"): return
	var unit: Dictionary=game.capture_campaign_snapshot()
	if not _expect(unit.level.local.authored_snapshot_version==version and _same(game.attempts.state().story.checkpoint,retained_checkpoint) and (not unit.level.local.has("crossed_arrangement") if version==1 else _same(unit.level.local.crossed_arrangement,L3_CODEC.fresh_crossed_arrangement(retry_profile))),"post-Retry public Save retains literal original format, actual selected profile/order and genuine CP2"): return
	scope_complete=_record_l3_unit("actual current-reader Retry Crossed first admission Save")

func _transport_ids() -> Dictionary:
	var ids: Dictionary={"world":str(game.world.get_instance_id()),"level":str(game.active_level.get_instance_id()),"player":str(game.player.get_instance_id()),"scheduler":str(_scheduler().get_instance_id())}
	for id: String in game.active_level.get("sources"): ids[id]=str(_source(id).get_instance_id())
	return ids

func _transport_all_new(before: Dictionary, after: Dictionary) -> bool:
	if before.size()!=after.size(): return false
	for key: String in before:
		if not after.has(key) or before[key]==after[key]: return false
	return true

func _metadata_constructor_negative(unit: Dictionary) -> bool:
	var bad: Dictionary=unit.duplicate(true)
	if bad.level.local.authored_snapshot_version==2: bad.level.local.erase("crossed_arrangement")
	else: bad.level.local["crossed_arrangement"]=L3_CODEC.fresh_crossed_arrangement("challenge")
	if not _expect(Codec.value_error(bad.level).is_empty() and not L3_CODEC.new().metadata_error(bad.level.local).is_empty(),"negative is legal JSON with exactly the intended malformed closed metadata"): return false
	var before: Dictionary=game.capture_campaign_snapshot()
	var attempts_before: Dictionary=game.attempts.state()
	var disk_before: String=FileAccess.get_file_as_string(test_root+"campaign.json")
	# Actual shared raw candidate construction only. Missing/extra closed metadata
	# must fail at Full's entry hook before binding or recipient construction;
	# no native physics/world-positive validation is claimed by this negative.
	var candidate: Dictionary=game.call("_prepare","A1-L3",unit.equipment_ids,{},bad,true)
	if not _expect(not candidate.is_empty(),"actual raw native nineteen-source candidate exists for early closed-metadata negative"): return false
	var host: CinderLevel=candidate.level
	# Respect the same paused native registration boundary as public restore.
	# This negative must reach the intended metadata hook, not an earlier
	# unregistered Player/floor preflight refusal.
	await process_frame; await process_frame
	var registration_error: String=host.restore_candidate_registration_error(candidate.player,candidate.fx,game,false)
	var player_error: String=candidate.player.snapshot_error(bad.player)
	var expected_error: String=L3_CODEC.new().metadata_error(bad.level.local)
	var before_events: int=observations.size()
	var accepted: bool=host.enter_restore_candidate(candidate.player,candidate.fx,game,bad.level,bad.player)
	var refusal: String=host.last_snapshot_error
	var pristine: bool=not accepted and not refusal.is_empty() and refusal==expected_error and player_error.is_empty() and registration_error.is_empty() and (host.get("_candidate_plan") as Dictionary).is_empty() and (host.get("_fields") as Dictionary).is_empty() and (host.get("_consumers") as Dictionary).is_empty() and (host.get("_protocols") as Dictionary).is_empty() and (host.get("_source_callbacks") as Dictionary).is_empty() and not host.get("_constructor_open") and observations.size()==before_events
	for id: String in host.get("sources"):
		var actor: Act1MushroomSelenite=(host.get("sources") as Dictionary)[id]
		var state: Dictionary=actor.pure_presentation_state()
		var expected_callback: Callable=Callable(host,"_on_source_state").bind(id)
		pristine=pristine and state.dormant and not state.dead and state.cycle==0 and state.reservation_id.is_empty() and actor.get_spore_native_bindings().is_empty() and expected_callback.is_valid() and not actor.state_changed.is_connected(expected_callback)
	receipts.append({"label":"actual early metadata negative before disposal diagnostic","format":unit.level.local.authored_snapshot_version,"accepted":accepted,"actual_refusal":refusal,"expected_metadata_error":expected_error,"native_player_preflight_error":player_error,"registration_error":registration_error,"callbacks_count":(host.get("_source_callbacks") as Dictionary).size(),"callback_events_during_entry":observations.size()-before_events,"pristine":pristine,"actual_process_registration_signals":2})
	var refs: Array[WeakRef]=_refs(candidate.container)
	game.call("_dispose",candidate)
	if not _expect(pristine and _freed(refs) and _same(game.capture_campaign_snapshot(),before) and _same(game.attempts.state(),attempts_before) and FileAccess.get_file_as_string(test_root+"campaign.json")==disk_before,"actual malformed format fails before native binding/recipient/field construction or callbacks; normal disposal preserves installed donor and disk"): return false
	receipts.append({"label":"actual closed metadata pre-recipient rejection","format":unit.level.local.authored_snapshot_version,"error":refusal,"candidate_kept_pristine":true,"source_packet_sha256":Exact.stringify(unit).sha256_text(),"malformed_packet_sha256":Exact.stringify(bad).sha256_text(),"native_positive_world_validation_claim":false})
	return true

func _transport_scope() -> String:
	return "Independent current-reader Shell from exact complete actual producer Store; active Crossed exact Continue/opposite future preference/Save; actual early malformed-metadata candidate fails before binding or recipient construction; actual RetryButton restores earlier genuine CP2, fresh native profile/order admission and whole Save. Supported Hero-only TEST probe pose; zero installed recipient callbacks and exact original checkpoint/format retained. No history splice, native state/source changes, ordinary attack, full route, OS-input/portrait/balance/performance claim."


## PRIVATE function fragment for the existing a1_l3_difficulty.gd fixture.
## Uses its existing L3_CODEC, Codec and Exact constants. No extra test resource.
## Positive units must be genuine native captures supplied by the caller.
## Malformed copies are pure metadata negatives, never valid native evidence.

static func check_recipes(expect: Callable) -> bool:
	var ok: bool = _l3_meta_check(L3_CODEC.arrangement_configuration_error().is_empty(), "closed authored recipe data", expect)
	if not ok: return false
	var canonical: Array = ["crossed-1", "crossed-2", "crossed-3", "crossed-4", "crossed-5", "crossed-6", "crossed-7", "crossed-8"]
	var inner_first: Array = ["crossed-3", "crossed-4", "crossed-1", "crossed-2", "crossed-5", "crossed-6", "crossed-7", "crossed-8"]
	for profile: String in ["assisted", "standard", "challenge"]:
		var selected: Dictionary = L3_CODEC.fresh_crossed_arrangement(profile)
		var expected_order: Array = inner_first if profile == "challenge" else canonical
		var expected_recipe: String = "a1-l3-crossed-" + profile + ("-inner-first@v1" if profile == "challenge" else "-canonical@v1")
		ok = _l3_meta_check(Codec.keys_error(selected, ["schema_version", "profile", "recipe_id", "order"]).is_empty() and selected.get("schema_version") is int and selected.schema_version == 1 and selected.get("profile") == profile and selected.get("recipe_id") == expected_recipe and selected.get("order") == expected_order and L3_CODEC.crossed_arrangement_error(selected).is_empty(), "exact " + profile + " priority descriptor; no native admission claim", expect) and ok
	if not ok: return false
	var valid: Dictionary = L3_CODEC.fresh_crossed_arrangement("challenge")
	for row: Dictionary in _l3_meta_bad_receipts(valid):
		ok = _l3_meta_check(not L3_CODEC.crossed_arrangement_error(row.value).is_empty(), "descriptor rejects " + row.label, expect) and ok
	return ok


## Call separately for the real legacy fixture, genuine fresh v2 capture and
## genuine active v2 Save as available; never upgrade a legacy input for setup.
static func check_captured_unit(unit: Dictionary, expected_version: int, expect: Callable) -> bool:
	if not _l3_meta_check(expected_version in [1, 2] and unit.get("level") is Dictionary and unit.level.get("local") is Dictionary, "genuine captured unit exposes its explicit expected format", expect): return false
	var original: String = Exact.stringify(unit)
	var local: Dictionary = unit.level.local
	var keys: Array = L3_CODEC.LOCAL_KEYS.duplicate()
	if expected_version == 2: keys.append("crossed_arrangement")
	var codec: RefCounted = L3_CODEC.new()
	var error: String = codec.call("metadata_error", local)
	if not _l3_meta_check(not original.is_empty() and local.get("authored_snapshot_version") is int and local.authored_snapshot_version == expected_version and Codec.keys_error(local, keys).is_empty() and not local.has("api_revision") and not local.has("schema_version") and error.is_empty(), "actual writer output has exactly " + str(keys.size()) + " local keys and valid authored metadata", expect): return false
	var ok: bool = true
	if expected_version == 1:
		ok = _l3_meta_check(not local.has("crossed_arrangement"), "actual legacy writer omits the new receipt", expect) and ok
	else:
		var started: bool = local.beat_index > 2 or (local.beat_index == 2 and local.room_stage == "active")
		ok = _l3_meta_check(local.crossed_arrangement.is_empty() != started, "actual v2 writer has an empty receipt exactly before Crossed begins", expect) and ok
		if started:
			for id: String in L3_CODEC.ROOM_SOURCES[2]:
				var actor: Dictionary = local.actors[id]
				if actor.get("cycle") == 0:
					ok = _l3_meta_check(actor.get("profile_id") == "", "actual cycle-zero source retains empty historical profile: " + id, expect) and ok
	for row: Dictionary in _l3_meta_bad_locals(local):
		var rejected_error: String = codec.call("metadata_error", row.value)
		ok = _l3_meta_check(not rejected_error.is_empty(), "local metadata rejects " + row.label, expect) and ok
	ok = _l3_meta_check(Exact.stringify(unit) == original, "pure metadata queries preserve the original whole input exactly", expect) and ok
	return ok


## Optional stronger pure boundary check. Pass the actual host's authored
## definitions and trusted native configurations with the genuine whole unit.
## Baseline acceptance is mandatory; rejected copies must return the SAME
## metadata error and no descriptor plan. This never constructs a recipient.
static func check_construction_rejections(unit: Dictionary, authored: Dictionary, actual_configurations: Dictionary, expect: Callable) -> bool:
	if not _l3_meta_check(unit.get("level") is Dictionary and unit.level.get("local") is Dictionary and unit.get("player") is Dictionary, "pure plan receives an actual paired whole unit", expect): return false
	var original: String = Exact.stringify([unit, authored, actual_configurations])
	var codec: RefCounted = L3_CODEC.new()
	var local: Dictionary = unit.level.local
	var baseline: Dictionary = codec.call("construction_plan", local, unit.player, authored, actual_configurations)
	if not _l3_meta_check(not original.is_empty() and baseline.get("accepted") == true and baseline.get("descriptors") is Dictionary, "genuine baseline passes original pure construction preflight", expect): return false
	var ok: bool = true
	for row: Dictionary in _l3_meta_bad_locals(local):
		var metadata_error: String = codec.call("metadata_error", row.value)
		var rejected: Dictionary = codec.call("construction_plan", row.value, unit.player, authored, actual_configurations)
		ok = _l3_meta_check(not metadata_error.is_empty() and Codec.keys_error(rejected, ["accepted", "error"]).is_empty() and rejected.get("accepted") == false and rejected.get("error") == metadata_error, "pure plan rejects " + row.label + " at metadata boundary before any recipient descriptor", expect) and ok
	ok = _l3_meta_check(Exact.stringify([unit, authored, actual_configurations]) == original, "pure construction queries preserve all supplied original packets", expect) and ok
	return ok


static func _l3_meta_check(ok: bool, label: String, expect: Callable) -> bool:
	if not expect.is_valid(): return false
	var result: Variant = expect.call(ok, "PURE L3 metadata: " + label)
	return result is bool and result


static func _l3_meta_bad_receipts(valid: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var bad: Dictionary = valid.duplicate(true)
	bad.erase("order"); rows.append({"label": "missing order", "value": bad})
	bad = valid.duplicate(true); bad["extra"] = true; rows.append({"label": "extra descriptor key", "value": bad})
	bad = valid.duplicate(true); bad.recipe_id += "-unknown"; rows.append({"label": "unknown retained recipe", "value": bad})
	bad = valid.duplicate(true); bad.schema_version = 1.0; rows.append({"label": "float descriptor version", "value": bad})
	bad = valid.duplicate(true); bad.profile = "standard" if valid.profile != "standard" else "challenge"; rows.append({"label": "recipe/profile mismatch", "value": bad})
	bad = valid.duplicate(true); bad.order[1] = bad.order[0]; rows.append({"label": "duplicate source in order", "value": bad})
	bad = valid.duplicate(true); bad.order[0] = "lone-guard"; rows.append({"label": "foreign room source in order", "value": bad})
	bad = valid.duplicate(true); bad.order.reverse(); rows.append({"label": "permutation differs from retained recipe", "value": bad})
	return rows


## Every case changes only a disposable copy, used solely for expected refusal.
static func _l3_meta_bad_locals(local: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var bad: Dictionary = local.duplicate(true)
	bad.erase("framing"); rows.append({"label": "missing original local key", "value": bad})
	bad = local.duplicate(true); bad["extra"] = true; rows.append({"label": "extra local key", "value": bad})
	bad = local.duplicate(true); bad.authored_snapshot_version = 3; rows.append({"label": "unknown authored version", "value": bad})
	bad = local.duplicate(true); bad.authored_snapshot_version = float(local.authored_snapshot_version); rows.append({"label": "float authored version", "value": bad})
	bad = local.duplicate(true); bad["api_revision"] = "forbidden-local-api"; rows.append({"label": "invented local API key", "value": bad})
	bad = local.duplicate(true); bad["schema_version"] = 1; rows.append({"label": "invented local schema key", "value": bad})
	bad = local.duplicate(true); bad["api_revision"] = "forbidden-local-api"; bad["schema_version"] = 1; rows.append({"label": "invented local API and schema keys together", "value": bad})
	if local.authored_snapshot_version == 1:
		bad = local.duplicate(true); bad["crossed_arrangement"] = {}; rows.append({"label": "receipt added to literal authored1", "value": bad})
		return rows
	bad = local.duplicate(true); bad.erase("crossed_arrangement"); rows.append({"label": "missing required authored2 receipt key", "value": bad})
	bad = local.duplicate(true); bad.crossed_arrangement = null; rows.append({"label": "null authored2 receipt", "value": bad})
	var started: bool = local.beat_index > 2 or (local.beat_index == 2 and local.room_stage == "active")
	if not started:
		bad = local.duplicate(true); bad.crossed_arrangement = L3_CODEC.fresh_crossed_arrangement("challenge"); rows.append({"label": "receipt selected before actual Crossed begin", "value": bad})
		return rows
	bad = local.duplicate(true); bad.crossed_arrangement = {}; rows.append({"label": "receipt erased after actual Crossed begin", "value": bad})
	for row: Dictionary in _l3_meta_bad_receipts(local.crossed_arrangement):
		bad = local.duplicate(true); bad.crossed_arrangement = row.value; rows.append({"label": row.label, "value": bad})
	var opposite: String = "standard" if local.crossed_arrangement.profile != "standard" else "challenge"
	if local.beat_index == 2 and local.room_stage == "active":
		bad = local.duplicate(true); bad.scheduler.profile.id = opposite; rows.append({"label": "active native profile differs from retained receipt", "value": bad})
	for id: String in L3_CODEC.ROOM_SOURCES[2]:
		if local.actors[id].get("profile_id", "") != "":
			bad = local.duplicate(true); bad.actors[id].profile_id = opposite; rows.append({"label": "executed Crossed source profile differs from receipt: " + id, "value": bad})
			break
	return rows


var shots: Array[Dictionary]=[]
var focus_rows: Array[Dictionary]=[]
var ordinary_source_report: Dictionary={}

func _read_view_options(selected_case: String) -> bool:
	root.size=Vector2i(540,1170)
	for argument: String in OS.get_cmdline_user_args():
		var key: String=argument.get_slice("=",0)
		if key not in ["--case","--report","--source-report","--source-sha256"] or options.has(key) or argument.find("=")<0:
			return _expect(false,"focused view/mechanics case accepts unique named selectors")
		options[key]=argument.substr(argument.find("=")+1)
	if options.has("--report"): report_path=options["--report"]
	if not _expect(options.get("--case")==selected_case and report_path.begins_with("res://.cinder/") and not FileAccess.file_exists(report_path),"explicit focused case has one unique native report"): return false
	registry_bytes=FileAccess.get_file_as_bytes(Registry.DATA_PATH); raw={}
	source_hashes[String(options.get("--source-report",""))]=FileAccess.get_sha256(String(options.get("--source-report","")))
	for path: String in source_hashes:
		if not _expect(String(source_hashes[path]).length()==64,"selected focused-case input exists: "+path): return false
	return true

func _load_view_donor() -> bool:
	if not _seed_transport_report() or not await _new_shell(): return false
	ordinary_source_report=JSON.parse_string(FileAccess.get_file_as_string(source_store_path))
	loaded_session=game.attempts.state()
	game.menu.continue_story_requested.emit()
	if not await _await_operation(func()->bool:
		var page_ok: bool=game.menu.page_name() in ["resume","pause"] if options.get("--case")=="portrait" else game.menu.page_name()=="resume"
		return _live("A1-L3") and paused and page_ok and not game.get("_draining") and not game.get("_drain_queued") and (game.get("_operations") as Array).is_empty(),"fresh independent actual inner-first saved Crossed Continue with completed operation queue",16.0): return false
	if not _expect(_same(game.capture_campaign_snapshot(),original_unit) and _same(game.attempts.state(),loaded_session) and _recipient_callbacks().is_empty() and _count_players(game.world)==1 and original_unit.level.local.authored_snapshot_version==2 and original_unit.level.local.crossed_arrangement.profile=="challenge","actual focused case quietly restores exact genuine Challenge whole unit with zero installed-recipient callbacks"): return false
	game.menu.difficulty_preference_requested.emit("standard")
	if not _expect(game.get_difficulty_preference()=="standard" and _same(game.capture_campaign_snapshot(),original_unit) and _same(game.attempts.state(),loaded_session),"opposite future Standard preference preserves captured Challenge recipe/native unit"): return false
	return _record_l3_unit("actual independent inner-first Challenge Continue with future Standard")

func _run_portrait_from_report() -> bool:
	if not _read_view_options("portrait") or not _expect(DisplayServer.get_name()!="headless","brief native portrait uses actual graphical renderer"): return false
	root.focus_entered.connect(_view_focus.bind("window-focus-entered"))
	root.focus_exited.connect(_view_focus.bind("window-focus-exited"))
	_view_focus("portrait-start")
	if not await _load_view_donor(): return false
	_view_focus("exact restored paused portrait boundary")
	await process_frame; await process_frame
	var objective:=game.hud.find_child("ObjectiveLabel",true,false) as Label
	var points: Array=game.active_level.camera_framing_points()
	if not _expect(objective!=null and objective.text==game.active_level.objective_text and not points.is_empty() and game.camera_framing_error(points).is_empty(),"actual native saved inner-warning source/footprint/response union is contained with canonical portrait HUD"): return false
	var before: String=_l3_portrait_wire()
	var visible_before: bool=game.menu.visible
	if not _expect(_l3_portrait_valid(before),"complete actual portrait witness is nonempty and exact-decodes before draw"): return false
	game.menu.visible=false
	await RenderingServer.frame_post_draw
	var after: String=_l3_portrait_wire()
	var stable: bool=_expect(paused and _l3_portrait_valid(after) and after==before,"temporary menu hiding preserves exact whole unit/Attempts/native/camera/input/HUD across actual draw")
	var picture: Image=root.get_texture().get_image() if stable else null
	var path: String="res://.cinder/a1-l3-difficulty-inner-warning-%d-%d.png" % [OS.get_process_id(),Time.get_ticks_usec()]
	var written: bool=picture!=null and picture.get_size()==Vector2i(540,1170) and picture.save_png(path)==OK
	game.menu.visible=visible_before
	var restored: String=_l3_portrait_wire()
	if not _expect(written and _l3_portrait_valid(restored) and restored==before and game.menu.visible==visible_before and _same(game.capture_campaign_snapshot(),original_unit),"actual540x1170 PNG restores menu and preserves nonempty exact native witness and source Save"): return false
	var decoded:=Image.load_from_file(path)
	if not _expect(decoded!=null and not decoded.is_empty() and decoded.get_size()==Vector2i(540,1170),"actual written portrait PNG decodes at native requested dimensions"): return false
	shots.append({"path":ProjectSettings.globalize_path(path),"sha256":FileAccess.get_sha256(path),"source_snapshot_sha256":Exact.stringify(original_unit).sha256_text(),"pictured_snapshot_sha256":Exact.stringify(game.capture_campaign_snapshot()).sha256_text(),"before_after_exact":before,"after_draw_exact":after,"after_menu_restore_exact":restored,"exact_witness_sha256":before.sha256_text(),"personal_review":"pending; native containment alone grants no optical acceptance","scope":"actual saved inner-warning paused portrait; only Menu temporarily hidden, no Hero/source/camera move, live step or OS-input claim"})
	return true

func _l3_portrait_values() -> Dictionary:
	var states: Dictionary={}
	for id: String in game.active_level.get("sources"):
		states[id]={"body":_source(id).pure_presentation_state(),"cue":_source(id).get_cue().state(),"environment":_source(id).get_spore_response_state()}
	var objective:=game.hud.find_child("ObjectiveLabel",true,false) as Label
	return {"snapshot":game.capture_campaign_snapshot(),"attempts":game.attempts.state(),"native":states,"camera":game.camera.global_transform,"camera_size":game.camera.size,"framing":game.get_camera_framing_state(),"input":game.get_input_observation_state(),"hud":objective.text if objective!=null else ""}

func _l3_portrait_wire() -> String:
	return Exact.stringify(_l3_portrait_encode(_l3_portrait_values()))

func _l3_portrait_valid(wire: String) -> bool:
	if wire.is_empty(): return false
	var parsed: Dictionary=Exact.parse(wire)
	return parsed.get("accepted")==true and parsed.get("value") is Dictionary and parsed.value.size()==8 and Exact.stringify(parsed.value)==wire

func _l3_portrait_encode(value: Variant) -> Variant:
	if value is Rect2: return {"native_type":"Rect2","position":_encode(value.position),"size":_encode(value.size)}
	if value is AABB: return {"native_type":"AABB","position":_encode(value.position),"size":_encode(value.size)}
	if value is Dictionary:
		var result: Dictionary={}
		for key: Variant in value: result[String(key)]=_l3_portrait_encode(value[key])
		return result
	if value is Array:
		var result: Array=[]
		for child: Variant in value: result.append(_l3_portrait_encode(child))
		return result
	return _encode(value)


# Fold into a1_l3_difficulty.gd; source-only draft, not an independent resource.
# Caller has verified a successful fresh-producer report SHA, copied its exact
# envelope, and quietly Continued original_unit in a fresh current-reader Shell.
# Required global: ordinary_source_report: Dictionary. Existing aliases/helpers:
# Exact, Codec, L3_CODEC, game, receipts, options, _expect/_resume/_wait_live/_source/_scheduler.
# This performs public Player methods, not recognizer or OS input. No TEST writes.

func _ordinary_changed_crossed_exchange() -> bool:
	var unit: Dictionary=game.capture_campaign_snapshot()
	var first: Dictionary=ordinary_source_report.get("first_admission",{})
	var decoded: Dictionary=Exact.parse(String(first.get("exact_encoded_answer","")))
	if not _expect(paused and _closed(unit) and _same(unit,original_unit) and ordinary_source_report.get("case")=="fresh-producer" and ordinary_source_report.get("success")==true and ordinary_source_report.get("scope_complete")==true and first.get("source_id")=="crossed-3" and decoded.get("accepted")==true and decoded.get("value") is Dictionary,"ordinary exchange starts from exact fresh-reader new Challenge Save and its actual exact encoded first admission"): return false
	var local: Dictionary=unit.level.local
	var id: String="crossed-3"
	var answer: Dictionary=decoded.value
	var frame: Dictionary=local.get("framing",{}).get(id,{})
	if not _expect(local.get("authored_snapshot_version")==2 and local.get("beat_index")==2 and local.get("room_stage")=="active" and _same(local.get("crossed_arrangement",{}),L3_CODEC.fresh_crossed_arrangement("challenge")) and local.scheduler.profile.get("id")=="challenge" and answer.get("accepted")==true and answer.get("armed")==true and answer.get("profile_id")=="challenge" and answer.get("proof") is Dictionary and answer.get("reservation") is Dictionary and frame.get("action_escape") is Dictionary and _same(frame.action_escape,answer.proof),"current native saved action_escape exactly matches original actual Challenge proof; no reconstructed witness"): return false
	var proof: Dictionary=frame.action_escape
	var original: Dictionary=answer.reservation
	var actor: Act1MushroomSelenite=_source(id)
	var state: Dictionary=actor.pure_presentation_state()
	var lease: String=String(frame.get("reservation_id",""))
	var current: Dictionary=_scheduler().source_control_state(actor)
	var records: Array=current.get("reservations",[])
	if not _expect(records.size()==1 and state.entity_id=="C31" and state.status=="running" and state.phase=="warning" and state.reservation_id==lease and state.cycle==local.actors[id].cycle and lease==answer.get("reservation_id") and records[0].get("source_instance_id")==actor.get_instance_id() and records[0].get("id")==lease and records[0].get("profile_id")=="challenge","restored changed C31 owns the same saved cycle/lease through its actual NEW recipient identity"): return false
	for key: String in ["start_s","lock_from_s","active_from_s","active_until_s","recovery_until_s","cooldown_until_s"]:
		if not _expect(records[0].get(key)==original.get(key),"current native lease retains original actual "+key): return false
	if not _expect(proof.get("accepted")==true and proof.get("uses_blast")==false and proof.get("uses_invulnerability")==false and proof.get("proof_scope")=="static_box_floor_full_dash_stationary_primary" and proof.get("path") is Array and Codec.is_vector3(proof.get("landing")) and Codec.is_vector3(proof.get("attack_position")) and float(proof.primary_time_s)>=float(original.active_until_s) and float(proof.response_complete_s)<float(original.recovery_until_s),"retained ordinary proof uses neither blast nor invulnerability and ends inside original native recovery"): return false
	var escape: Array[Dictionary]=[]
	var positioning: Array[Dictionary]=[]
	var primary: Array[Dictionary]=[]
	for segment: Dictionary in proof.path:
		if not _expect(Codec.keys_error(segment,["from","to","start_s","end_s","kind"]).is_empty() and Codec.is_vector3(segment["from"]) and Codec.is_vector3(segment["to"]) and Codec.is_number(segment.start_s) and Codec.is_number(segment.end_s),"original proof segment has exact native encoded endpoints and timings"): return false
		if segment.kind=="escape_dash": escape.append(segment)
		elif segment.kind=="positioning_dash": positioning.append(segment)
		elif segment.kind=="ordinary_primary": primary.append(segment)
	if not _expect(escape.size()==1 and positioning.size()<=1 and primary.size()==1 and _same(escape[0]["to"],proof.landing) and _same(primary[0]["from"],proof.attack_position) and _same(primary[0]["to"],proof.attack_position) and primary[0].start_s==proof.primary_time_s and primary[0].end_s==proof.response_complete_s and _scheduler().get_clock()<=float(escape[0].start_s),"actual fresh Continue retains an unexpired original escape and ordinary-primary path"): return false
	var timing: Dictionary={"label":"actual changed Crossed C31 ordinary exchange after fresh Continue","scope":"public Player request_dash/slash along retained spatial route within original native recovery; measured timing offsets, no exact nominal certified timeline, recognizer/OS, full route or balance claim","source_report":options.get("--source-report"),"source_report_sha256":options.get("--source-sha256"),"source_snapshot_sha256":Exact.stringify(unit).sha256_text(),"source_id":id,"cycle":int(state.cycle),"reservation_id":lease,"current_actor_instance_id":str(actor.get_instance_id()),"exact_original_answer":first.exact_encoded_answer,"exact_saved_frame":Exact.stringify(frame),"original_proof":proof.duplicate(true),"original_deadlines":{},"start_source_position":_encode(actor.global_position),"initial_hp":game.player.hp,"initial_shells":game.player.shells,"equipment_ids":game.player.equipment.snapshot(),"native_dash_invulnerability_s":game.player.equipment.resolved_stats().dash_invulnerability,"actions":[],"hit_events":[],"phases":{},"steps":[],"guard_error":"","complete":false}
	for key: String in ["start_s","lock_from_s","active_from_s","active_until_s","recovery_until_s","cooldown_until_s"]: timing.original_deadlines[key]=original[key]
	receipts.append(timing)
	var listeners: Array[Dictionary]=[]
	for index: int in range(1,9):
		var observed_id: String="crossed-%d" % index
		var observed: Act1MushroomSelenite=_source(observed_id)
		var callback: Callable=_ordinary_hit_observed.bind(observed_id,timing)
		observed.hit_resolved.connect(callback)
		listeners.append({"actor":observed,"callback":callback})
	var phase_callback: Callable=_ordinary_phase_observed.bind(timing)
	var action_callback: Callable=_ordinary_action_observed.bind(timing)
	actor.state_changed.connect(phase_callback)
	game.player.world_action_executed.connect(action_callback)
	_ordinary_phase_observed(state,timing)
	var passed: bool=await _ordinary_execute_original_path(timing,proof,escape[0],positioning)
	# These are harness signal listeners only; disconnect after any latched failure.
	for item: Dictionary in listeners:
		if is_instance_valid(item.actor) and item.actor.hit_resolved.is_connected(item.callback): item.actor.hit_resolved.disconnect(item.callback)
	if is_instance_valid(actor) and actor.state_changed.is_connected(phase_callback): actor.state_changed.disconnect(phase_callback)
	if is_instance_valid(game) and is_instance_valid(game.player) and game.player.world_action_executed.is_connected(action_callback): game.player.world_action_executed.disconnect(action_callback)
	timing.complete=passed
	return passed

func _ordinary_execute_original_path(timing: Dictionary, proof: Dictionary, escape: Dictionary, positioning: Array[Dictionary]) -> bool:
	if not await _resume("actual changed Crossed ordinary exchange"): return false
	if not await _ordinary_dash_segment(timing,escape,float(timing.original_deadlines.active_from_s),"escape"): return false
	for phase: String in ["lock","active","recovery"]:
		if not await _ordinary_wait(timing,func()->bool:return timing.phases.has(phase),"same actual C31 cycle "+phase,true): return false
	var actor: Act1MushroomSelenite=_source(timing.source_id)
	var state: Dictionary=actor.pure_presentation_state()
	var records: Array=_scheduler().source_control_state(actor).get("reservations",[])
	if not _expect(records.size()==1 and state.phase=="recovery" and state.adapter.get("finished")==true and actor.global_position.distance_to(records[0].opening_position)<=0.035 and actor.global_position.distance_to(Codec.read_vector3(timing.start_source_position))>.9,"actual unchanged C31 completed its one-unit lunge to the original reachable ordinary opening"): return false
	if not positioning.is_empty():
		var planned: Dictionary=positioning[0]
		if not _expect(_same(planned["from"],proof.landing) and _same(planned["to"],proof.attack_position) and float(planned.start_s)>=float(timing.original_deadlines.active_until_s)+CinderThreatScheduler.TIME_MARGIN and float(planned.end_s)<=float(proof.primary_time_s),"original return uses its own native positioning start before primary time"): return false
		# Observe a legal actual opening within the ORIGINAL native recovery.
		# Process-frame observations need not replay the nominal certified path
		# exactly; preserve its times and publish measured deltas separately.
		var current_response: Dictionary=game.player.get_threat_response_state()
		var primary_budget: float=maxf(float(current_response.stats.primary_cooldown),float(current_response.primary_commitment_s))
		var positioning_latest: float=float(timing.original_deadlines.recovery_until_s)-primary_budget
		timing["actual_positioning_budget"]={"nominal_primary_time_s":proof.primary_time_s,"native_recovery_until_s":timing.original_deadlines.recovery_until_s,"actual_primary_budget_s":primary_budget,"latest_positioning_completion_s":positioning_latest,"claim":"actual legal opening, not exact nominal certified timeline"}
		if not await _ordinary_dash_segment(timing,planned,positioning_latest,"positioning"): return false
	elif not _expect(game.player.global_position.distance_to(Codec.read_vector3(proof.attack_position))<=0.035,"original non-returning proof leaves Hero at its actual stationary primary opening"): return false
	if not await _ordinary_wait(timing,func()->bool:return _scheduler().get_clock()>=float(proof.primary_time_s),"original native primary time",true): return false
	var response: Dictionary=game.player.get_threat_response_state()
	var current_clock: float=_scheduler().get_clock()
	var duration: float=maxf(float(response.stats.primary_cooldown),float(response.primary_commitment_s))
	if not _expect(_ordinary_guard(timing,true) and response.stable and response.primary_cooldown_left_s==0.0 and response.commitment_remaining_s==0.0 and game.player.global_position.distance_to(Codec.read_vector3(proof.attack_position))<=0.035 and current_clock+duration<float(timing.original_deadlines.recovery_until_s) and game.camera_framing_error(game.active_level.camera_framing_points()).is_empty(),"actual ordinary primary is ready at original position/time with its complete current optical union and full recovery budget"): return false
	var before_hp: float=actor.hp
	var before_actions: int=timing.actions.size()
	var before_fields: Dictionary=_ordinary_field_supply()
	# Deliberate ordinary aim across the enemy lane leaves both nearby caps
	# available. The previous direct-at-enemy aim also hit cluster-right.
	# This is an explicit public test input, never shared auto-aim logic.
	var aim: Vector3=Vector3.BACK
	var target_offset: Vector3=actor.global_position-game.player.global_position
	var target_vertical: float=absf(target_offset.y); target_offset.y=0.0
	var cone: float=float(response.stats.primary_cone_min_dot)
	var reach: float=float(response.stats.primary_range)
	var target_dot: float=target_offset.normalized().dot(aim)
	var no_environment_hit: bool=true
	var environment_checks: Array[Dictionary]=[]
	for node: Node in get_nodes_in_group("environment_attack_targets"):
		if not node is Node3D or node.get_world_3d()!=game.player.get_world_3d(): continue
		var offset: Vector3=(node as Node3D).global_position-game.player.global_position
		var vertical: float=absf(offset.y); offset.y=0.0
		var distance: float=offset.length()
		var dot: float=offset.normalized().dot(aim)
		var excluded: bool=distance>reach or vertical>CinderPlayer.ATTACK_MAX_VERTICAL_DISTANCE or (distance>CinderPlayer.ATTACK_ORIGIN_DISK_RADIUS and dot<cone-.01)
		environment_checks.append({"path":String(node.get_path()),"position":_encode((node as Node3D).global_position),"distance_m":distance,"vertical_m":vertical,"aim_dot":dot,"excluded_without_relying_on_scenery":excluded})
		no_environment_hit=no_environment_hit and excluded
	timing["deliberate_primary_aim"]={"direction":_encode(aim),"target_direction":_encode(target_offset.normalized()),"target_dot":target_dot,"cone_min_dot":cone,"target_distance_m":target_offset.length(),"environment_checks":environment_checks,"shared_input_or_aim_logic_changed":false}
	if not _expect(target_offset.length()>.1 and target_offset.length()<=reach and target_vertical<=CinderPlayer.ATTACK_MAX_VERTICAL_DISTANCE and target_dot>cone+.01 and no_environment_hit,"deliberate ordinary aim contains actual C31 but geometrically excludes every available environment target without moving anything"): return false
	var hits: int=game.player.slash(aim)
	if not _expect(timing.actions.size()==before_actions+1 and timing.actions.back().record.kind=="primary","one public slash immediately publishes exactly one genuine primary action"): return false
	var record: Dictionary=timing.actions.back().record
	var damage: float=before_hp-actor.hp
	timing["primary"]={"scheduler_clock_s":current_clock,"primary_delta_s":current_clock-float(proof.primary_time_s),"before_target_hp":before_hp,"after_target_hp":actor.hp,"hp_damage":damage,"returned_hits":hits,"record":record.duplicate(true),"field_supply_before":before_fields,"field_supply_after":_ordinary_field_supply(),"source_state_after":_encode(actor.pure_presentation_state())}
	if not _expect(record.origin=="player_direct" and record.damage_timing=="instant_at_execution" and Codec.read_vector3(record.direction).distance_to(aim)<=0.00001 and hits==record.hits and hits>0 and damage>0.0 and absf(damage-minf(before_hp,float(record.damage)))<=0.00001 and _same(before_fields,timing.primary.field_supply_after) and _ordinary_guard(timing,false),"actual requested C31 loses native primary HP immediately; ammo/HP/supply are unchanged and no native hit event consumed invulnerability"): return false
	# Native hurt/knockback may cancel the struck lease here; this is legitimate.
	if not await _ordinary_wait(timing,func()->bool:
		var ready: Dictionary=game.player.get_threat_response_state()
		return ready.stable and ready.primary_cooldown_left_s==0.0 and ready.commitment_remaining_s==0.0,
		"actual primary cooldown and commitment finish inside original recovery",false): return false
	timing["completed_at_s"]=_scheduler().get_clock()
	timing["response_completion_delta_s"]=float(timing.completed_at_s)-float(proof.response_complete_s)
	timing["final_hp"]=game.player.hp
	timing["final_shells"]=game.player.shells
	var dash_count: int=0
	var primary_count: int=0
	for item: Dictionary in timing.actions:
		if item.record.kind=="dash": dash_count+=1
		elif item.record.kind=="primary": primary_count+=1
		else: return _expect(false,"ordinary exchange contains no blast or additional action kind")
	return _expect(_ordinary_guard(timing,false) and dash_count==1+positioning.size() and primary_count==1 and timing.hit_events.is_empty() and float(timing.completed_at_s)<float(timing.original_deadlines.recovery_until_s),"one original ordinary exchange completes before native recovery ends with full legal dashes, one actual hit, zero Hero damage, unchanged ammo and zero resolved enemy contact")

func _ordinary_dash_segment(timing: Dictionary, segment: Dictionary, complete_before: float, label: String) -> bool:
	if not await _ordinary_wait(timing,func()->bool:return _scheduler().get_clock()>=float(segment.start_s),"original "+label+" dash start",true): return false
	var response: Dictionary=game.player.get_threat_response_state()
	var from: Vector3=Codec.read_vector3(segment["from"])
	var destination: Vector3=Codec.read_vector3(segment["to"])
	var direction: Vector3=destination-game.player.global_position
	direction.y=0.0
	var operands: Dictionary={"kind":label,"actual_scheduler_clock_s":_scheduler().get_clock(),"stable":response.stable,"dash_cooldown_left_s":response.dash_cooldown_left_s,"commitment_remaining_s":response.commitment_remaining_s,"actual_position":_encode(game.player.global_position),"original_from":segment["from"],"from_error_m":game.player.global_position.distance_to(from),"requested_distance_m":direction.length(),"legal_dash_distance_m":response.stats.dash_distance,"native_dash_duration_s":response.stats.dash_duration,"complete_before_s":complete_before,"nominal_segment_start_s":segment.start_s,"nominal_segment_end_s":segment.end_s,"remaining_after_full_dash_s":complete_before-_scheduler().get_clock()-float(response.stats.dash_duration)}
	var prior_checks: Array=timing.get("dash_preconditions",[])
	prior_checks.append(operands); timing["dash_preconditions"]=prior_checks
	if not _expect(response.stable and response.dash_cooldown_left_s==0.0 and response.commitment_remaining_s==0.0 and game.player.global_position.distance_to(from)<=0.035 and absf(direction.length()-float(response.stats.dash_distance))<=0.035 and _scheduler().get_clock()+float(response.stats.dash_duration)<complete_before,"actual "+label+" input is a ready full native dash on the original proof segment"): return false
	var count: int=timing.actions.size()
	var step: Dictionary={"kind":label,"original_segment":segment.duplicate(true),"input_scheduler_clock_s":_scheduler().get_clock(),"input_delta_s":_scheduler().get_clock()-float(segment.start_s),"input_player_clock_s":game.player.get_world_action_clock(),"actual_origin":_encode(game.player.global_position)}
	timing.steps.append(step)
	if not _expect(game.player.request_dash(direction.normalized()),"public Player accepts one actual "+label+" dash without queued input"): return false
	if not await _ordinary_wait(timing,func()->bool:return timing.actions.size()>count and game.player.get_threat_response_state().stable,"actual full "+label+" dash completion",true): return false
	step["ready_scheduler_clock_s"]=_scheduler().get_clock()
	step["completion_delta_s"]=_scheduler().get_clock()-float(segment.end_s)
	if not _expect(timing.actions.size()==count+1,"exactly one actual completed "+label+" action was published"): return false
	var record: Dictionary=timing.actions.back().record
	step["record"]=record.duplicate(true)
	return _expect(record.kind=="dash" and record.origin=="player_direct" and record.get("blocked")==false and record.get("collision_shortened")==false and record.get("movement_damage")==false and absf(float(record.distance)-float(response.stats.dash_distance))<=0.035 and Codec.read_vector3(record.landing).distance_to(destination)<=0.035 and game.player.global_position.distance_to(destination)<=0.035 and _scheduler().get_clock()<complete_before,"real "+label+" dash reaches retained landing without shortening or movement damage before original native deadline")

func _ordinary_wait(timing: Dictionary, predicate: Callable, label: String, require_lease: bool) -> bool:
	# Native deadlines determine success. Wall time only bounds the invocation;
	# there is no implicit FPS requirement or world-clock/phase adjustment.
	var observed: bool=await _wait_live(func()->bool:return not _ordinary_guard(timing,require_lease) or predicate.call()==true,label,60.0)
	return observed and _expect(_ordinary_guard(timing,require_lease) and predicate.call()==true,label+" with unchanged actual native guards")

func _ordinary_guard(timing: Dictionary, require_lease: bool) -> bool:
	var reason: String=""
	if not is_instance_valid(game) or not is_instance_valid(game.player) or not _live("A1-L3"): reason="original live Shell/Player lost"
	elif game.player.hp!=timing.initial_hp or game.player.shells!=timing.initial_shells: reason="Hero HP or ammo changed"
	elif not timing.hit_events.is_empty(): reason="actual native enemy contact resolved (including rejected invulnerable contacts)"
	elif _scheduler().get_clock()>=float(timing.original_deadlines.recovery_until_s): reason="original native recovery deadline reached"
	elif not _same(game.player.equipment.snapshot(),timing.equipment_ids): reason="actual equipment changed"
	elif require_lease:
		var state: Dictionary=_source(timing.source_id).pure_presentation_state()
		if state.dead or state.cycle!=timing.cycle or state.reservation_id!=timing.reservation_id or state.status!="running": reason="original actual source cycle/lease ended before ordinary hit"
	if not reason.is_empty() and timing.guard_error.is_empty(): timing.guard_error=reason
	return reason.is_empty()

func _ordinary_hit_observed(hero_id: String, cycle: int, result: Dictionary, id: String, timing: Dictionary) -> void:
	timing.hit_events.append({"source_id":id,"hero_id":hero_id,"cycle":cycle,"scheduler_clock_s":_scheduler().get_clock(),"result":_encode(result)})

func _ordinary_phase_observed(state: Dictionary, timing: Dictionary) -> void:
	if state.get("source_id")!=timing.source_id or state.get("cycle")!=timing.cycle or state.get("reservation_id")!=timing.reservation_id: return
	var phase: String=String(state.get("phase",""))
	if not timing.phases.has(phase): timing.phases[phase]={"scheduler_clock_s":_scheduler().get_clock(),"state":_encode(state)}

func _ordinary_action_observed(record: Dictionary, timing: Dictionary) -> void:
	timing.actions.append({"scheduler_clock_s":_scheduler().get_clock(),"record":_encode(record)})

func _ordinary_field_supply() -> Dictionary:
	var result: Dictionary={}
	for id: String in (game.active_level.get("_fields") as Dictionary):
		var field: CinderSporeField=(game.active_level.get("_fields") as Dictionary)[id]
		var state: Dictionary=field.state()
		result[id]={"instance_id":str(field.get_instance_id()),"generation":state.generation,"spent_ids":state.spent_ids.duplicate(),"activation_s":state.activation_s,"deadline_s":state.deadline_s}
	return result

func _run_ordinary_from_report() -> bool:
	if not _read_view_options("ordinary") or not await _load_view_donor(): return false
	return await _ordinary_changed_crossed_exchange()

func _view_scope() -> String:
	if options.get("--case")=="portrait":
		return "Brief actual540x1170 portrait from exact current-reader quiet Continue of genuine fresh Challenge inner-warning Save; opposite future preference retained. Actual native containment plus nonempty exact complete saved/native/camera/input/HUD witness across draw and menu restore. Menu alone temporarily hidden. Personal visual review separately recorded. No live physics step, repositioning, ordinary action, OS-input, full route, balance/performance/mobile claim."
	return "One real changed Crossed C31 ordinary exchange after independent exact current-reader Continue/opposite preference from genuine whole new Challenge Save. Exact original accepted action_escape retained; real public Player request_dash/slash follows its spatial route within unchanged native recovery, with actual timing offsets and eight-source hit observations; no exact nominal certified timeline claim; no body/HP/clock/invulnerability/native guard writes. No recognizer/OS-input, earned prefix, full route, balance/performance/mobile claim."

func _view_focus(label: String) -> void:
	if focus_rows.size()<128:
		focus_rows.append({"label":label,"elapsed_ms":Time.get_ticks_msec()-started_ms,"native_focused":DisplayServer.window_is_focused(root.get_window_id()),"paused":paused,"page":game.menu.page_name() if is_instance_valid(game) and is_instance_valid(game.menu) else "none","forcing_focus":false})
