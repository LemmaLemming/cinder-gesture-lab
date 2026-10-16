extends "res://tests/acts/act1/a1_o2_terminal.gd"
## Focused old-writer producer; native results are recorded separately.
## Literal original whole CP2 Attempts; one supported TEST Hero-only placement.
## Public Shell owns Continue, preference, Resume and Pause/Save. No old-format
## reconstruction, injury, clock/phase/heading/field/progress or source edits.

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

func _initialize() -> void:
	started_ms=Time.get_ticks_msec()
	test_root="user://test-act1-l3-difficulty-%d-%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	report_path="res://.cinder/a1-l3-difficulty-%d-%d.json" % [OS.get_process_id(),Time.get_ticks_usec()]
	old_fps=Engine.max_fps; old_audio=AudioServer.generate_bus_layout()
	for path: String in SELECTED_SOURCES: source_hashes[path]=FileAccess.get_sha256("res://"+path)
	var self_path: String=get_script().resource_path
	source_hashes[self_path]=FileAccess.get_sha256(self_path)
	source_hashes[Registry.DATA_PATH]=FileAccess.get_sha256(Registry.DATA_PATH)
	process_frame.connect(_watchdog); node_added.connect(_observe_added); _run.call_deferred()

func _run() -> void:
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
	var proposed:=Vector3(-3.2,before.y,-12.4)
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
	for id: String in PROBE_IDS:
		var actor: Act1MushroomSelenite=_source(id)
		var actual: Dictionary=actor.pure_presentation_state()
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
		row.sources[id]={"eligible":eligible,"distance":distance,"presentation":_encode(actual),"control":_encode(control),"preview":_encode(candidate),"inside_source_room":inside,"gap_error":gap,"ordinary_window":window,"current_view_error":optics}
		row.both_eligible=row.both_eligible and eligible
	latest_probe=row
	if eligibility_rows.size()<240: eligibility_rows.append(row.duplicate(true))
	else: probe_rows_omitted+=1

func _admission_observed(id: String, answer: Dictionary) -> void:
	if not first_admission.is_empty() or game.active_level.call("route_state").beat_index!=2: return
	var same_tick: bool=not latest_probe.is_empty() and latest_probe.clock_s==_scheduler().get_clock() and latest_probe.physics_frame==Engine.get_physics_frames()
	first_admission={"source_id":id,"answer":_encode(answer),"profile":_scheduler().encounter_profile(),"clock_s":_scheduler().get_clock(),"both_eligible_same_tick":same_tick and latest_probe.get("both_eligible",false),"no_prior_forecast":same_tick and latest_probe.get("no_prior_forecast",false),"forecast_scope":"selected admission owner/proposal only; other motion forecast IDs are retained diagnostically","pre_admission":latest_probe.duplicate(true),"control":_encode(_scheduler().source_control_state(_source(id)))}

func _resume(label: String) -> bool:
	operation="public Resume: "+label
	game.menu.resume_requested.emit()
	return _expect(not paused and _live("A1-L3") and not game.player.dead,"public Resume releases actual healthy L3 simulation: "+label)

func _record_l3_unit(label: String) -> bool:
	var unit: Dictionary=game.capture_campaign_snapshot()
	var session: Dictionary=game.attempts.state()
	if not _expect(_closed(unit) and _same(unit,session.story.snapshot) and _same(session.story.checkpoint,original_unit) and _durable(),"whole native L3 capture matches durable public Attempts: "+label): return false
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
		value["route"]=game.active_level.call("route_state"); value["snapshot_error"]=game.active_level.last_snapshot_error; value["capture_error"]=game.active_level.get("_capture_error"); value["encounter_error"]=game.active_level.get("last_encounter_error")
	return value

func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec()-started_ms>LEGACY_LIMIT_MS:
		_expect(false,"bounded old-producer watchdog reached180 wall seconds"); _finish.call_deferred()

func _finish() -> void:
	if finishing: return
	finishing=true; paused=true; operation="normal L3 producer cleanup"
	if is_instance_valid(probe_node): probe_node.inspect=Callable(); probe_node.free()
	var refs: Array[WeakRef]=[]
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
		output.store_string(JSON.stringify({"case":"legacy-producer","checks":checks,"failures":failures,"first_failure":first_failure,"assertions":assertions,"scope_complete":scope_complete,"success":success,"elapsed_ms":Time.get_ticks_msec()-started_ms,"watchdog_ms":LEGACY_LIMIT_MS,"report_path":ProjectSettings.globalize_path(report_path),"source_store":source_store_path,"source_store_sha256":ORIGINAL_SHA,"source_sha256":source_hashes,"setups":setups,"receipts":receipts,"first_admission":first_admission,"eligibility_rows":eligibility_rows,"probe_rows_omitted":probe_rows_omitted,"observations":observations,"operation_wait_overruns":operation_wait_overruns,"synchronous_observation_overruns":observation_overruns,"pause_registration_barriers":pause_registration_barriers,"scope":"Actual old-writer whole CP2 Continue/future Challenge/native Crossed admission/public Pause Save; one disclosed supported Hero-only TEST pose. Original complete Attempts and checkpoint retained; supported availability migration recorded. No packet/source/HP/heading/clock/progress edits, earned prefix, full route, ordinary attack execution, portrait/OS input, balance or performance claim."},"\t")); output.close()
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L3 DIFFICULTY: %d checks, %d failures; complete=%s; report=%s" % [checks,failures,str(scope_complete),report_path])
	quit(0 if success else 1)
