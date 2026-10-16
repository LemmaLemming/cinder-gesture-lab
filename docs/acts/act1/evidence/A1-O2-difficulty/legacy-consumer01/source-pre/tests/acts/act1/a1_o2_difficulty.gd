extends "res://tests/acts/act1/a1_o2_terminal.gd"
## SOURCE ONLY. Bounded independent cases consume genuine hashed whole Attempts.
## No packet upgrade, source/clock/HP/field/recipe seed, contact or replay rerun.
const BaseScript = preload("res://scripts/acts/act1/mushroom_caverns.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const PROBE_IDS: Array[String] = ["bloom-final-west", "bloom-final-guard"]
const RUNTIME_PINS: Array[String] = [
	"scenes/acts/act1/a1_o2.tscn", "scripts/acts/act1/spore_bloom.gd", "scripts/acts/act1/spore_bloom_layout.gd", "scripts/acts/act1/spore_bloom_codec.gd",
	"scripts/acts/act1/mushroom_caverns.gd", "scripts/acts/act1/mushroom_selenite.gd", "scripts/acts/act1/mushroom_selenite_codec.gd",
	"scripts/combat/encounter_arrangement.gd", "scripts/combat/threat_scheduler.gd", "scripts/combat/repulsion_route.gd",
	"scripts/environment/spore_field.gd", "scripts/environment/spore_repulsion.gd", "scripts/environment/spore_cluster.gd",
	"scripts/campaign/shell.gd", "scripts/campaign/level.gd", "scripts/campaign/attempts.gd", "scripts/campaign/save_store.gd",
	"data/campaign/act1/a1_o2_difficulty_arrangements.json", "data/design/difficulty_profiles.json", "data/design/player_equipment.json"
]
const CASE_LIMITS: Dictionary = {"source-default":30000, "new-prefix":180000, "admission":120000, "finite":180000, "continue-retry":150000, "legacy-consumer":150000, "portrait":90000}
class AdmissionProbe extends Node:
	var inspect: Callable
	func _physics_process(delta: float) -> void:
		if inspect.is_valid(): inspect.call(delta)
var options: Dictionary = {}
var difficulty_case: String = ""
var requested_profile: String = "standard"
var producer_sources: Dictionary = {}
var latest_probe: Dictionary = {}
var eligibility_rows: Array[Dictionary] = []
var first_admission: Dictionary = {}
var probe_node: AdmissionProbe
var assertions: Array[Dictionary] = []
var scope_complete: bool = false
var input_receipt: Dictionary = {}
var input_snapshot: Dictionary = {}
var input_session: Dictionary = {}
var pending_attack: Dictionary = {}
var checkpoint_seen: bool = false
var action_rows: Array[Dictionary] = []
var shots: Array[Dictionary] = []

func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	test_root = "user://test-act1-o2-difficulty-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	report_path = "res://.cinder/a1-o2-difficulty-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	old_fps = Engine.max_fps; old_audio = AudioServer.generate_bus_layout()
	for path: String in RUNTIME_PINS: producer_sources[path] = FileAccess.get_sha256("res://" + path)
	producer_sources["tests/acts/act1/a1_o2_difficulty.gd"] = FileAccess.get_sha256("res://tests/acts/act1/a1_o2_difficulty.gd")
	process_frame.connect(_watchdog); node_added.connect(_observe_added); _run.call_deferred()

func _run() -> void:
	root.size = Vector2i(540,1170)
	for argument: String in OS.get_cmdline_user_args():
		var key: String = argument.get_slice("=",0)
		if key not in ["--case", "--profile", "--source-report", "--source-sha256", "--source-label"] or options.has(key) or argument.find("=") < 0:
			_expect(false,"unique named case/profile/source report arguments required"); await _finish(); return
		options[key] = argument.substr(argument.find("=")+1)
	difficulty_case = String(options.get("--case","")); requested_profile = String(options.get("--profile","standard"))
	if not _expect(CASE_LIMITS.has(difficulty_case) and requested_profile in ["standard","challenge"],"explicit bounded case and native profile required"): await _finish(); return
	if difficulty_case == "source-default": scope_complete = _source_default(); await _finish(); return
	if not _configure_test_registry(): await _finish(); return
	if difficulty_case == "new-prefix": scope_complete = await _fresh_prefix(); await _finish(); return
	if not _read_input() or not _write_original_session(): await _finish(); return
	match difficulty_case:
		"admission": scope_complete = await _admission_case()
		"finite": scope_complete = await _finite_case()
		"continue-retry", "legacy-consumer": scope_complete = await _transport_case()
		"portrait": scope_complete = await _portrait_case()
	await _finish()

func _source_default() -> bool:
	var base = BaseScript.new()
	var same: bool = base.admission_source_ids() == base.current_source_ids()
	base.initial_greybox_room = 3
	same = same and base.admission_source_ids() == base.current_source_ids()
	base.free()
	return _expect(same and BloomCodec.arrangement_configuration_error().is_empty(),"Base default returns exact current membership for existing first-room and guard components; authored final recipes validate")

func _read_input() -> bool:
	if not _expect(options.has_all(["--source-report","--source-sha256","--source-label"]),"genuine source report, SHA256 and exact unique receipt label required"): return false
	var path: String = options["--source-report"]; var expected: String = options["--source-sha256"]
	if not _expect(expected.length()==64 and FileAccess.get_sha256(path)==expected,"literal input report matches explicit SHA256"): return false
	var report: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var legacy: bool = difficulty_case == "legacy-consumer"
	if not _expect(report is Dictionary and report.get("failures",-1)==0 and report.get("first_failure") == {} and report.get("receipts") is Array and (legacy or report.get("scope_complete")==true and report.get("success")==true),"producer has actual successful complete scope; legacy additionally requires its concrete original receipt below"): return false
	input_receipt = _unique_receipt(report.receipts, options["--source-label"])
	input_snapshot = _read_exact_dictionary(input_receipt.get("exact_snapshot"),"genuine producer whole snapshot")
	input_session = _read_exact_dictionary(input_receipt.get("exact_attempts"),"genuine producer complete Attempts")
	if input_snapshot.is_empty() or input_session.is_empty(): return false
	prefinal = input_session.get("side_attempt",{}).get("checkpoint",{}).duplicate(true)
	protected_story = input_session.get("story",{}).duplicate(true)
	if not _expect(_same(input_session.get("side_attempt",{}).get("snapshot"),input_snapshot) and not prefinal.is_empty() and not protected_story.is_empty() and input_snapshot.paused and input_snapshot.level_id==Bloom.LEVEL_ID and input_session.completed_main==PREFIX and input_session.completed_optional.is_empty() and input_session.reward_ids.is_empty(),"whole exact optional Session retains original checkpoint/protected Story without terminal grants"): return false
	if legacy:
		if not _expect(input_snapshot.level.local.api_revision=="act1-spore-bloom-1" and input_snapshot.level.local.schema_version==1 and not input_snapshot.level.local.has("final_arrangement") and input_snapshot.level.local.room_stage=="active" and input_snapshot.level.local.scheduler.profile.id=="challenge" and report.get("case")=="legacy-producer" and report.get("first_admission",{}).get("source_id")=="bloom-final-west" and report.first_admission.get("both_eligible_same_tick")==true,"original producer actually saved API1 Challenge final after west-first both-eligible native admission"): return false
	else:
		if not _expect(input_snapshot.level.local.api_revision=="act1-spore-bloom-2" and input_snapshot.level.local.schema_version==2 and report.get("source_sha256") is Dictionary,"new input is a genuine API2 unit with source pins"): return false
		for path_name: String in RUNTIME_PINS:
			if not _expect(report.source_sha256.get(path_name)==producer_sources[path_name],"consumer uses exact producer runtime input: "+path_name): return false
	source_reports.append({"path":path,"sha256":expected,"receipt_label":options["--source-label"],"snapshot_sha256":Exact.stringify(input_snapshot).sha256_text(),"attempts_sha256":Exact.stringify(input_session).sha256_text(),"source_sha256":report.get("source_sha256",{})})
	return true

func _write_original_session() -> bool:
	var model := Attempts.new(Registry.new(raw))
	var store := Store.new(test_root+"campaign.json"); store.payload_validator=model.saved_payload_error
	return _expect(model.restore_session(input_session) and _same(model.state(),input_session) and model.state_error(input_session).is_empty() and store.write_payload(input_session),"public Attempts/isolated Store transports original whole Session without any packet rewrite")

func _load_original(preference: String) -> bool:
	if not await _new_shell(): return false
	game.menu.difficulty_preference_requested.emit(preference)
	if not _expect(game.get_difficulty_preference()==preference,"public future difficulty stored before actual Title active-side Continue"): return false
	game.menu.resume_requested.emit()
	if not await _await_operation(func()->bool:return _live(Bloom.LEVEL_ID) and paused and game.menu.page_name()=="resume","fresh Title installs genuine active optional unit",12.0): return false
	return _expect(_same(game.capture_campaign_snapshot(),input_snapshot) and _same(game.attempts.state(),input_session) and _recipient_callbacks().is_empty() and _bindings() and _durable(),"fresh installed native recipient exactly retains input whole unit/Session with zero recipient callbacks")

func _record_unit(label: String) -> bool:
	var unit: Dictionary = game.capture_campaign_snapshot()
	if not _expect(paused and not unit.is_empty() and _durable() and _same(game.attempts.state().side_attempt.snapshot,unit) and _same(game.attempts.state().story,protected_story),"actual paused whole-unit Save and protected Story agree: "+label): return false
	receipts.append({"label":label,"exact_snapshot":Exact.stringify(unit),"snapshot_sha256":Exact.stringify(unit).sha256_text(),"exact_player":Exact.stringify(unit.player),"exact_level":Exact.stringify(unit.level),"exact_attempts":Exact.stringify(game.attempts.state()),"saved_envelope_json":FileAccess.get_file_as_string(test_root+"campaign.json"),"native_identities":_ids(),"first_admission":first_admission.duplicate(true)})
	return true

func _arm_probe() -> void:
	latest_probe.clear(); first_admission.clear(); eligibility_rows.clear()
	if not game.active_level.is_connected("native_admission_published",_admission_observed): game.active_level.connect("native_admission_published",_admission_observed)
	if is_instance_valid(probe_node): probe_node.free()
	probe_node=AdmissionProbe.new(); probe_node.process_mode=Node.PROCESS_MODE_PAUSABLE; probe_node.process_physics_priority=199; probe_node.inspect=Callable(self,"_probe_final"); root.add_child(probe_node)

func _admission_case() -> bool:
	if not _expect(input_snapshot.level.local.beat_index==2 and input_snapshot.level.local.room_stage=="approach" and input_snapshot.level.local.final_arrangement=={},"admission consumes genuine API2 pre-final checkpoint with unselected final policy"): return false
	if not await _load_original(requested_profile) or not _place_final_probe(): return false
	return await _run_first_admission(requested_profile,false,"actual "+requested_profile+" final admission Save")

func _run_first_admission(profile: String, legacy: bool, label: String) -> bool:
	_arm_probe()
	if not await _resume("genuine fresh final profile boundary") or not await _wait_live(func()->bool:return not first_admission.is_empty(),"first real final native admission",16.0): return false
	var expected: String = "bloom-final-guard" if profile=="challenge" and not legacy else "bloom-final-west"
	if not _expect(first_admission.source_id==expected and first_admission.profile.id==profile and first_admission.both_eligible_same_tick,"actual first native source follows retained policy with same-tick west+guard native/current-view eligibility"): return false
	if not await _pause(label): return false
	var local: Dictionary = game.capture_campaign_snapshot().level.local
	if legacy:
		if not _expect(local.api_revision=="act1-spore-bloom-1" and local.schema_version==1 and not local.has("final_arrangement"),"legacy attempt remains literal API1 through a newly begun Challenge final"): return false
	else:
		if not _expect(local.api_revision=="act1-spore-bloom-2" and _same(local.final_arrangement,BloomCodec.fresh_final_arrangement(profile)) and game.active_level.call("admission_source_ids")==local.final_arrangement.order,"new Save retains actual final receipt and active native admission priority"): return false
	return _record_unit(label)

func _place_final_probe() -> bool:
	var before: Vector3 = game.player.global_position
	var proposed := Vector3(-2.2, before.y, -3.0)
	var measured: Dictionary = TerminalSweep.sweep(game.player, Transform3D(game.player.global_basis, proposed), Vector3.ZERO, game.active_level.call("scheduler_bindings").floors.values())
	if not _expect(paused and game.player.velocity == Vector3.ZERO and not measured.has("error") and not measured.get("collided", true), "only same-floor TEST Hero pose has real capsule support before final activation"): return false
	game.player.global_position = proposed
	setups.append({"kind": "TEST Hero position only; no source, phase, velocity, clock, camera or save-packet edit", "before": _encode(before), "after": _encode(proposed), "earned_traversal": false})
	return true


func _probe_final(delta: float) -> void:
	if finishing or paused or not first_admission.is_empty() or not _live(Bloom.LEVEL_ID): return
	var host: CinderLevel = game.active_level
	var state: Dictionary = host.call("bloom_state")
	if state.beat_index != 2 or state.room_stage != "active" or not game.player.get_threat_response_state().stable: return
	var row: Dictionary = {"clock_s": _scheduler().get_clock(), "physics_frame": Engine.get_physics_frames(), "hero_position": _encode(game.player.global_position), "sources": {}, "both_eligible": true}
	for id: String in PROBE_IDS:
		var actor: Act1MushroomSelenite = _source(id)
		var actual: Dictionary = actor.pure_presentation_state()
		var control: Dictionary = _scheduler().source_control_state(actor)
		var distance: float = _distance(actor.global_position, game.player.global_position)
		var candidate: Dictionary = actor.preview_start(game.player.global_position, host.call("response_context", actual.role_id))
		var basic: bool = not actor.dead and not actor.dormant and actual.reservation_id.is_empty() and float(actual.hurt_left_s) == 0.0 and distance >= .1 and distance <= 4.5 and candidate.get("accepted", false)
		var gap: String = "native preview unavailable"
		var window: bool = false
		var optics: String = "native preview unavailable"
		if basic:
			gap = String(host.call("_source_path_gap_error", id, actor.global_position, candidate.candidate.opening_position, delta))
			window = host.call("_proof_window", candidate.proof, candidate.candidate) == true
			var points: Array = host.camera_framing_points()
			points.append_array(host.call("_actor_points", id, candidate.candidate.opening_position))
			points.append_array(host.call("_lane_points", candidate.candidate.geometry))
			points.append_array(host.call("_response_points", candidate.proof.landing, candidate.proof.attack_position))
			# Conservative union of the real current union and this genuine proposed
			# source/footprint/response. Pure read only; does not move the camera.
			optics = game.camera_framing_error(host.call("_bounded_union", points))
		var eligible: bool = basic and gap.is_empty() and window and optics.is_empty()
		row.sources[id] = {"eligible": eligible, "distance": distance, "presentation": _encode(actual), "control": _encode(control), "preview": _encode(candidate), "gap_error": gap, "ordinary_window": window, "current_view_error": optics}
		row.both_eligible = row.both_eligible and eligible
	latest_probe = row
	if eligibility_rows.size() < 180: eligibility_rows.append(row.duplicate(true))


func _admission_observed(id: String, answer: Dictionary) -> void:
	if not first_admission.is_empty() or game.active_level.call("bloom_state").beat_index != 2: return
	var same_tick: bool = not latest_probe.is_empty() and latest_probe.clock_s == _scheduler().get_clock() and latest_probe.physics_frame == Engine.get_physics_frames()
	first_admission = {"source_id": id, "answer": _encode(answer), "profile": _scheduler().encounter_profile(), "clock_s": _scheduler().get_clock(), "both_eligible_same_tick": same_tick and latest_probe.get("both_eligible", false), "pre_admission": latest_probe.duplicate(true), "control": _encode(_scheduler().source_control_state(_source(id)))}


func _fresh_prefix() -> bool:
	if not await _seed_story(Registry.new(raw)) or not await _new_shell(): return false
	game.menu.continue_story_requested.emit()
	if not await _await_operation(func()->bool:return _live("A1-L3") and paused and game.menu.page_name()=="resume","actual original Story before fresh Optional",12.0): return false
	protected_story=game.attempts.state().story.duplicate(true); unlocked_before=game.attempts.state().unlocked_equipment.duplicate()
	game.menu.difficulty_preference_requested.emit("standard"); game.menu.optional_requested.emit(Bloom.LEVEL_ID)
	if not await _await_operation(func()->bool:return _live(Bloom.LEVEL_ID) and paused and game.menu.page_name()=="resume","actual fresh API2 optional entry",12.0): return false
	var entry: Dictionary=game.capture_campaign_snapshot()
	if not _expect(entry.level.local.api_revision=="act1-spore-bloom-2" and entry.level.local.final_arrangement=={} and _same(entry,game.attempts.state().side_attempt.checkpoint),"fresh constructor supplies genuine API2 entrance; no upgraded old unit"): return false
	game.active_level.checkpoint_requested.connect(_prefix_checkpoint)
	if not _expect(_pose_supported(TEST_POSITION),"initial TEST approach has actual supported capsule/scenery clearance"): return false
	game.player.global_position=TEST_POSITION
	setups.append({"kind":"TEST initial Hero-only supported approach position","position":_encode(TEST_POSITION),"earned_traversal":false})
	if not await _resume("fresh native first group"): return false
	for group: int in range(2):
		if not await _wait_live(func()->bool:return game.active_level.call("bloom_state").beat_index==group and game.active_level.call("bloom_state").room_stage=="active","actual required prefix group "+str(group),14.0): return false
		var tries: int=0
		while not _living_id(group).is_empty() and tries<10:
			tries+=1
			if not await _public_attack(_source(_living_id(group)),false): return false
		if not _expect(_living_id(group).is_empty() and _all_supplies_pristine(),"actual public primaries defeat required prefix group while retaining every installed finite anchor"): return false
	if not await _await_operation(func()->bool:return checkpoint_seen and paused and game.menu.page_name()=="pause" and game.active_level.call("bloom_state").room_stage=="approach","actual Shell commits sole pre-final CP and requested Pause",16.0): return false
	var unit: Dictionary=game.capture_campaign_snapshot(); prefinal=game.attempts.state().side_attempt.checkpoint.duplicate(true)
	if not _expect(_same(unit,prefinal) and unit.level.local.beat_index==2 and unit.level.local.final_arrangement=={} and Bloom.group_ids(2).all(func(id:String)->bool:return _source(id).dormant) and _all_supplies_pristine() and (game.active_level.get("_fields") as Dictionary).size()==2,"genuine API2 CP retains five dead/final four dormant, original both supplies and unselected policy"): return false
	return _record_unit("actual API2 conserving pre-final checkpoint")

func _prefix_checkpoint(id: String, checkpoint: String, kind: String) -> void:
	if id==Bloom.LEVEL_ID and checkpoint==Bloom.CHECKPOINT_ID and kind=="encounter":
		checkpoint_seen=true; game.request_pause() # Public request only; capture after dispatch/drain.

func _living_id(group: int) -> String:
	for id: String in Bloom.group_ids(group):
		if not _source(id).dead: return id
	return ""

func _supplies() -> Dictionary:
	var result: Dictionary={}
	for id: String in game.active_level.get("_fields"):
		var field: CinderSporeField=game.active_level.get("_fields")[id]
		var state: Dictionary=field.state()
		result[id]={"identity":str(field.get_instance_id()),"generation":state.generation,"spent_ids":state.spent_ids.duplicate(),"activation_s":state.activation_s,"deadline_s":state.deadline_s,"remaining_clusters":state.remaining_clusters}
	return result

func _all_supplies_pristine() -> bool:
	for value: Dictionary in _supplies().values():
		if value.generation!=0 or value.remaining_clusters!=2 or not value.spent_ids.is_empty(): return false
	return true

func _ready_primary() -> bool:
	if paused or not _live(Bloom.LEVEL_ID) or game.player.dead: return false
	var state: Dictionary=game.player.get_threat_response_state()
	return state.stable and float(state.commitment_remaining_s)==0.0 and float(state.primary_cooldown_left_s)==0.0

func _clusters() -> Array[Node3D]:
	var result: Array[Node3D]=[]
	for field: CinderSporeField in (game.active_level.get("_fields") as Dictionary).values():
		for id: String in Bloom.CLUSTER_IDS: result.append(field.get_node(id) as Node3D)
	return result

func _reaches_from(target: Node3D, position: Vector3, aim: Vector3) -> bool:
	var offset: Vector3=target.global_position-position
	if absf(offset.y)>CinderPlayer.ATTACK_MAX_VERTICAL_DISTANCE: return false
	offset.y=0.0; var stats: Dictionary=game.player.equipment.resolved_stats()
	if offset.length()>float(stats.primary_range) or offset.length()>CinderPlayer.ATTACK_ORIGIN_DISK_RADIUS and offset.normalized().dot(aim)<float(stats.primary_cone_min_dot): return false
	var ray:=PhysicsRayQueryParameters3D.create(position+Vector3.UP*CinderPlayer.ATTACK_LOS_HEIGHT,target.global_position+Vector3.UP*CinderPlayer.ATTACK_LOS_HEIGHT,CinderPlayer.ATTACK_SCENERY_MASK)
	return game.player.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _aim_clear(target: Node3D, position: Vector3, aim: Vector3, cluster: bool) -> bool:
	if not _reaches_from(target,position,aim): return false
	for other: Node3D in _clusters():
		if other!=target and _reaches_from(other,position,aim): return false
	if cluster:
		for id: String in Bloom.SOURCE_IDS:
			var actor: Act1MushroomSelenite=_source(id)
			if not actor.dead and not actor.dormant and _reaches_from(actor,position,aim): return false
	return true

func _pose_supported(position: Vector3) -> bool:
	var body: Dictionary=TerminalSweep.source_description(game.player)
	if body.has("error"): return false
	var radius: float=body.footprint_half.x
	var until: float=_scheduler().get_clock()+float(game.player.equipment.resolved_stats().primary_cooldown)+.1
	for id: String in Bloom.SOURCE_IDS:
		var actor: Act1MushroomSelenite=_source(id)
		if not actor.dead and not actor.dormant and _distance(position,actor.global_position)<radius+(actor.get_node("BodyCollision").shape as CapsuleShape3D).radius+.12: return false
		for lease: Dictionary in _scheduler().source_control_state(actor).reservations:
			if lease.active_until_s>=_scheduler().get_clock() and lease.active_from_s<=until and Geometry.segment_hits(lease.geometry,game.player.global_position,position,radius): return false
	var actual: Dictionary=TerminalSweep.sweep(game.player,Transform3D(game.player.global_basis,position),Vector3.ZERO,game.active_level.call("scheduler_bindings").floors.values())
	return not actual.has("error") and not actual.get("collided",true)

func _find_attack(target: Node3D, cluster: bool) -> Dictionary:
	for radius: float in [1.0,1.4]:
		for angle: int in range(16):
			var position: Vector3=target.global_position+Vector3(sin(TAU*angle/16.0),0,cos(TAU*angle/16.0))*radius
			position.y=game.player.global_position.y
			if not _pose_supported(position): continue
			for step: int in range(72):
				var aim:=Vector3(cos(TAU*step/72.0),0,sin(TAU*step/72.0)).normalized()
				if _aim_clear(target,position,aim,cluster): return {"target":target,"position":position,"aim":aim,"cluster":cluster}
	return {}

func _place_attack(target: Node3D, cluster: bool) -> bool:
	pending_attack.clear()
	if not await _wait_live(func()->bool:return _ready_primary() and (cluster or (target as Act1MushroomSelenite).get_spore_response_state().grounded),"actual primary/target readiness",8.0): return false
	if not await _wait_live(func()->bool:return not _find_attack(target,cluster).is_empty(),"supported TEST pose and isolated actual primary cone",10.0): return false
	if not await _wait_live(func()->bool:return game.camera_framing_error(game.active_level.camera_framing_points()).is_empty(),"actual complete optical union before public Pause Save",8.0): return false
	if not await _pause("isolated TEST primary setup"): return false
	pending_attack=_find_attack(target,cluster)
	if not _expect(not pending_attack.is_empty() and game.player.velocity==Vector3.ZERO,"paused setup retains actual zero velocity and measured floor/threat/body support"): return false
	var before: Vector3=game.player.global_position
	game.player.global_position=pending_attack.position
	setups.append({"kind":"TEST Hero-only ordinary attack pose; no source/clock/field/camera/state seed","before":_encode(before),"after":_encode(pending_attack.position),"target":String(target.name),"cluster":cluster})
	return await _resume("actual ordinary primary after supported setup")

func _public_attack(target: Node3D, cluster: bool) -> bool:
	if pending_attack.get("target")!=target or pending_attack.get("cluster")!=cluster:
		if not await _place_attack(target,cluster): return false
	if not _expect(_ready_primary() and _aim_clear(target,game.player.global_position,pending_attack.aim,cluster),"actual current ready primary reaches requested target and excludes every other installed cluster and, for release, all living actors"): return false
	var before: Dictionary=_supplies(); var hp: Dictionary={}
	for id: String in Bloom.SOURCE_IDS: hp[id]=_source(id).hp
	var sequence: int=_last_sequence(); var ammo: int=game.player.shells; var hero_hp: float=game.player.hp
	var result: int=game.player.slash(pending_attack.aim)
	var records: Array[Dictionary]=game.player.get_world_action_records(sequence)
	var after: Dictionary=_supplies(); var losses: Dictionary={}; var valid: bool=true
	for id: String in Bloom.SOURCE_IDS:
		var loss: float=float(hp[id])-_source(id).hp
		if loss>0.0:
			losses[id]=loss
			valid=valid and loss==minf(float(hp[id]),float(game.player.equipment.resolved_stats().primary_damage))
	for id: String in before:
		if not cluster or (target.get_parent() as CinderSporeField)!=(game.active_level.get("_fields") as Dictionary)[id]: valid=valid and _same(before[id],after[id])
	valid=valid and records.size()==1 and records[0].kind=="primary" and records[0].origin=="player_direct" and records[0].hits==result and result==losses.size() and game.player.hp==hero_hp and game.player.shells>=ammo
	if records.size()==1:
		valid=valid and (records[0].direction as Vector3).is_equal_approx((pending_attack.aim as Vector3).normalized()) and game.player.get_threat_response_state().primary_cooldown_left_s==records[0].cooldown_s
	if cluster: valid=valid and result==0 and losses.is_empty()
	else: valid=valid and losses.has(String((target as Act1MushroomSelenite).pure_presentation_state().source_id))
	action_rows.append({"target":String(target.name),"cluster":cluster,"before_fields":before,"after_fields":after,"hp_before":hp,"losses":losses,"actions":_encode(records),"returned_hits":result,"shells_before":ammo,"shells_after":game.player.shells})
	pending_attack.clear()
	return _expect(valid,"actual one public primary records all native HP losses, preserves unrelated finite supplies and uses no blast or resource reset")

func _transport_case() -> bool:
	var legacy: bool=difficulty_case=="legacy-consumer"
	if not _expect(input_snapshot.level.local.beat_index==2 and input_snapshot.level.local.room_stage=="active" and prefinal.level.local.room_stage=="approach","transport input is distinct genuine active final plus earlier pre-final checkpoint"): return false
	var saved_profile: String=input_snapshot.level.local.scheduler.profile.id
	var opposite: String="standard" if saved_profile=="challenge" else "challenge"
	if not await _load_original(opposite): return false
	if not _expect(game.get_difficulty_preference()==opposite and _same(game.capture_campaign_snapshot(),input_snapshot),"opposite future preference preserves exact saved native profile/policy/remaining supply"): return false
	if not legacy and not _malformed_receipt(): return false
	if not await _pause("public Save before exact earlier Retry"): return false
	game.menu.difficulty_preference_requested.emit("challenge")
	var button:=game.menu.find_child("RetryButton",true,false) as Button
	if not _expect(button!=null and button.is_visible_in_tree() and not button.disabled,"real production pause RetryButton is available"): return false
	var identities: Dictionary=_ids(); var refs: Array[WeakRef]=_refs(game.world)
	button.pressed.emit()
	if not await _await_operation(func()->bool:return _live(Bloom.LEVEL_ID) and paused and game.menu.page_name()=="resume" and _ids()!=identities,"actual public Retry restores earlier genuine checkpoint",16.0): return false
	if not _expect(_same(game.capture_campaign_snapshot(),prefinal) and _all_new(identities,_ids()) and _freed(refs) and _recipient_callbacks().is_empty() and _bindings() and _same(game.attempts.state().story,protected_story) and _durable(),"Retry quietly restores exact earlier CP with distinct native recipients, preserved Story/supply and donor cleanup"): return false
	if legacy:
		if not _expect(prefinal.level.local.api_revision=="act1-spore-bloom-1" and not prefinal.level.local.has("final_arrangement"),"literal old CP remains metadata-free"): return false
	else:
		if not _expect(prefinal.level.local.final_arrangement=={},"new CP is genuinely pre-selection rather than carrying a future recipe"): return false
	if not _place_final_probe(): return false
	return await _run_first_admission("challenge",legacy,"actual post-Retry Challenge final Save")

func _malformed_receipt() -> bool:
	var saved: Dictionary=game.capture_campaign_snapshot()
	var wire: String=Exact.stringify(saved); var disk: String=FileAccess.get_file_as_string(test_root+"campaign.json"); var ids: Dictionary=_ids()
	for kind: String in ["missing","order","profile"]:
		var bad: Dictionary=saved.duplicate(true)
		match kind:
			"missing": bad.level.local.erase("final_arrangement")
			"order": bad.level.local.final_arrangement.order.reverse()
			"profile": bad.level.local.final_arrangement.profile="standard" if saved.level.local.final_arrangement.profile=="challenge" else "challenge"
		var reason: String=game.active_level.snapshot_error_with_player(bad.level,bad.player)
		if not _expect(not reason.is_empty() and Exact.stringify(game.capture_campaign_snapshot())==wire and _ids()==ids and FileAccess.get_file_as_string(test_root+"campaign.json")==disk,"malformed final descriptor refused before native/disk mutation: "+kind): return false
	return true

func _finite_case() -> bool:
	if not _expect(input_snapshot.level.local.room_stage=="active" and input_snapshot.level.local.final_arrangement.profile=="challenge" and input_receipt.get("first_admission",{}).get("source_id")=="bloom-final-guard" and input_receipt.first_admission.get("both_eligible_same_tick")==true,"finite case consumes genuine new Challenge guard-first final admission"): return false
	if not await _load_original("standard") or not await _resume("genuine final finite supplies"): return false
	if not await _finite_final_case(): return false
	if not await _pause("actual both-fields-spent ordinary opportunity Save"): return false
	return _record_unit("actual Challenge final both fields exhausted ordinary opportunity")

func _portrait_case() -> bool:
	if not _expect(DisplayServer.get_name()!="headless" and input_snapshot.level.local.room_stage=="active" and input_snapshot.level.local.final_arrangement.profile=="challenge","graphical case consumes actual API2 Challenge final unit"): return false
	if not await _load_original("standard"): return false
	await process_frame; await process_frame
	var label: Label=game.hud.find_child("ObjectiveLabel",true,false) as Label
	var points: Array=game.active_level.camera_framing_points()
	if not _expect(label!=null and label.text==game.active_level.objective_text and not points.is_empty() and game.camera_framing_error(points).is_empty(),"actual current HUD and camera contain genuine final source/footprint/response union"): return false
	var before: String=_portrait_wire(); var visible_before: bool=game.menu.visible
	game.menu.visible=false
	await RenderingServer.frame_post_draw
	var stable: bool=_expect(paused and _portrait_wire()==before,"menu-only hiding retains exact native/Attempts/camera/input/HUD across actual draw")
	var picture: Image=root.get_texture().get_image() if stable else null
	var path: String="res://.cinder/a1-o2-difficulty-final-%d-%d.png" % [OS.get_process_id(),Time.get_ticks_usec()]
	var written: bool=picture!=null and picture.get_size()==Vector2i(540,1170) and picture.save_png(path)==OK
	game.menu.visible=visible_before
	if not _expect(written and _portrait_wire()==before and game.menu.visible==visible_before,"actual540x1170 final PNG preserves saved native state and restores menu"): return false
	shots.append({"path":ProjectSettings.globalize_path(path),"sha256":FileAccess.get_sha256(path),"source_snapshot_sha256":Exact.stringify(input_snapshot).sha256_text(),"before_after_exact":before,"personal_review":"pending; native containment alone is not visual acceptance"})
	return true

func _portrait_wire() -> String:
	var actor_states: Dictionary={}
	for id: String in Bloom.SOURCE_IDS: actor_states[id]={"body":_source(id).pure_presentation_state(),"cue":_source(id).get_cue().state(),"environment":_source(id).get_spore_response_state()}
	var objective: Label=game.hud.find_child("ObjectiveLabel",true,false) as Label
	return Exact.stringify(_encode({"snapshot":game.capture_campaign_snapshot(),"attempts":game.attempts.state(),"native":actor_states,"camera":game.camera.global_transform,"camera_size":game.camera.size,"framing":game.get_camera_framing_state(),"input":game.get_input_observation_state(),"hud":objective.text if objective!=null else ""}))

func _expect(ok: bool, label: String) -> bool:
	var result: bool=super._expect(ok,label)
	assertions.append({"index":checks,"passed":ok,"label":label,"case":difficulty_case,"operation":operation,"elapsed_ms":Time.get_ticks_msec()-started_ms})
	return result

func _watchdog() -> void:
	var limit: int=int(CASE_LIMITS.get(difficulty_case,120000))
	if not finishing and Time.get_ticks_msec()-started_ms>limit:
		_expect(false,"bounded case wall watchdog expired at "+str(limit)+"ms"); _finish.call_deferred()

func _finish() -> void:
	if finishing: return
	finishing=true; paused=true; operation="normal bounded difficulty cleanup"
	if is_instance_valid(probe_node): probe_node.free(); probe_node=null
	var refs: Array[WeakRef]=[]
	if is_instance_valid(preview):
		var level: CinderLevel=preview.get("active_level") as CinderLevel
		if level!=null: level.exit_level()
		refs.append_array(_refs(preview)); preview.free(); preview=null
	if is_instance_valid(game):
		if is_instance_valid(game.active_level): game.active_level.exit_level()
		refs.append_array(_refs(game)); game.free(); game=null
	paused=false; await create_timer(.5,true).timeout; await process_frame
	_expect((refs.is_empty() or _freed(refs)) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("environment_attack_targets").is_empty() and get_nodes_in_group("required_cues").is_empty(),"normal public exit/Shell cleanup frees native descendants and groups")
	if not registry_bytes.is_empty(): _expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH)==registry_bytes,"canonical Registry bytes unchanged")
	for path: String in producer_sources: _expect(FileAccess.get_sha256("res://"+path)==producer_sources[path],"actual source stayed frozen: "+path)
	Engine.max_fps=old_fps; AudioServer.set_bus_layout(old_audio)
	var output:=FileAccess.open(report_path,FileAccess.WRITE)
	if output==null: _expect(false,"unique report is writable")
	else:
		var success: bool=scope_complete and failures==0 and first_failure.is_empty()
		output.store_string(JSON.stringify({"checks":checks,"failures":failures,"first_failure":first_failure,"assertions":assertions,"scope_complete":scope_complete,"success":success,"elapsed_ms":Time.get_ticks_msec()-started_ms,"watchdog_ms":CASE_LIMITS.get(difficulty_case,120000),"case":difficulty_case,"requested_profile":requested_profile,"report_path":ProjectSettings.globalize_path(report_path),"source_sha256":producer_sources,"source_reports":source_reports,"receipts":receipts,"setups":setups,"actions":action_rows,"first_admission":first_admission,"eligibility_rows":eligibility_rows,"observations":observations,"synchronous_observation_overruns":observation_overruns,"pause_registration_barriers":pause_registration_barriers,"shots":shots,"scope":"Only the explicitly selected bounded case. Actual public Shell operations and genuine complete source units; TEST prefix/Hero-only poses disclosed. No source/HP/field/clock/recipe/camera/packet fabrication, contact/reward/replay rerun, full route, all-kit, OS gesture, balance or performance claim. Portrait pixels require personal inspection."},"\t")); output.close()
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-O2 DIFFICULTY: %d checks, %d failures; complete=%s; report=%s" % [checks,failures,str(scope_complete),report_path])
	quit(0 if scope_complete and failures==0 else 1)
# Fragment only: caller has genuinely reached API2 Challenge final and proved guard-first.
# Requires _place_attack/_public_attack contracts agreed with test owner. The latter
# accepts an actual zero-hit primary whose cluster interaction is refused; it checks
# unrelated fields and HP itself. Caller owns report completion, cleanup and watchdog.
func _finite_final_case() -> bool:
	var fields: Dictionary = game.active_level.get("_fields")
	var far := fields.get("bloom-far") as CinderSporeField
	var near := fields.get("bloom-near") as CinderSporeField
	var consumer := (game.active_level.get("_consumers") as Dictionary).get(Bloom.consumer_id(2)) as CinderSporeRepulsion
	if not _expect(far != null and near != null and consumer != null and _scheduler().encounter_profile().id == "challenge" and game.active_level.call("bloom_state").beat_index == 2, "actual Challenge final retains original fields and consumer"): return false
	for original: CinderSporeField in [near, far]:
		if not _expect(original.state().generation == 0 and original.state().remaining_clusters == 2 and original.state().spent_ids.is_empty(), "fresh prefix conserved both original supplies"): return false
	var right := far.get_node("cluster-right") as Node3D
	var left := far.get_node("cluster-left") as Node3D
	if not await _place_attack(right, true): return false
	var before: Dictionary = far.state()
	if not await _public_attack(right, true): return false
	var released: Dictionary = far.state()
	if not _expect(released.generation == 1 and released.spent_ids == ["cluster-right"] and released.remaining_clusters == 1 and released.deadline_s == released.activation_s + Bloom.FIELD_DURATION_S, "actual isolated primary releases exactly one finite original far anchor"): return false
	receipts.append({"label": "fresh final first far release", "before": before, "after": released, "near": near.state()})
	# Do this before waiting for the whole retreat, which may consume the live deadline.
	var observed_retreat: Dictionary = {}
	if not await _wait_live(func() -> bool:
		if observed_retreat.is_empty(): observed_retreat.merge(_finite_retreat_row(consumer, far))
		return _ready_primary(), "actual primary cooldown before active refresh attempt", 1.5): return false
	if not await _place_attack(left, true): return false
	var live: Dictionary = far.state()
	if not _expect(live.phase in ["releasing", "active", "thinning"] and live.clock_s < live.deadline_s and live.spent_ids == ["cluster-right"], "unspent sibling attempt occurs within original actual deadline"): return false
	if not await _public_attack(left, true): return false
	var refused: Dictionary = far.state()
	if not _expect(_finite_markers_equal(live, refused), "actual primary on unspent sibling cannot refresh live field or spend another supply"): return false
	receipts.append({"label": "actual active-field refresh refusal", "before": live, "after": refused})
	# A pure source/consumer observation must witness actual outward motion, not pixels.
	if observed_retreat.is_empty():
		if not await _wait_live(func() -> bool:
			observed_retreat.merge(_finite_retreat_row(consumer, far))
			return not observed_retreat.is_empty(), "actual final native outward retreat with original route", 3.0): return false
	receipts.append({"label": "actual outward native final retreat with no source reservation", "observation": observed_retreat})
	for original: CinderSporeField in [far, near]:
		for cluster_id: String in Bloom.CLUSTER_IDS:
			if cluster_id in original.state().spent_ids: continue
			if not await _wait_live(func() -> bool: return original.state().phase == "available" and _ready_primary() and _finite_reactions_idle(), "actual original field expiry and native recovery", 8.0): return false
			var cluster := original.get_node(cluster_id) as Node3D
			if not await _place_attack(cluster, true): return false
			var prior: Dictionary = original.state()
			if not await _public_attack(cluster, true): return false
			var after: Dictionary = original.state()
			if not _expect(after.generation == prior.generation + 1 and after.spent_ids.back() == cluster_id and after.deadline_s == after.activation_s + Bloom.FIELD_DURATION_S and (prior.deadline_s == null or after.activation_s >= prior.deadline_s), "ordinary primary spends next original anchor only after real expiry"): return false
			receipts.append({"label": "remaining original finite supply", "field_id": after.instance_id, "before": prior, "after": after})
		if not await _wait_live(func() -> bool: return original.state().phase == "spent" and _finite_reactions_idle(), "actual final original lifetime and native reactions finish", 8.0): return false
	if not _expect((game.active_level.get("_fields") as Dictionary).get("bloom-far") == far and (game.active_level.get("_fields") as Dictionary).get("bloom-near") == near and far.state().generation == 2 and near.state().generation == 2 and far.state().remaining_clusters == 0 and near.state().remaining_clusters == 0, "both original fields are genuinely exhausted with unchanged custody"): return false
	var target: Act1MushroomSelenite = _source("bloom-final-guard")
	if target.dead:
		for id: String in Bloom.group_ids(2):
			if not _source(id).dead: target = _source(id); break
	if not _expect(not target.dead and not target.dormant, "one living actual final recipient remains for ordinary opportunity"): return false
	if not await _wait_live(_ready_primary, "actual ordinary readiness after full depletion", 5.0): return false
	var far_spent: Dictionary = far.state()
	var near_spent: Dictionary = near.state()
	if not await _place_attack(target, false) or not await _public_attack(target, false): return false
	return _expect(_finite_markers_equal(far_spent, far.state()) and _finite_markers_equal(near_spent, near.state()), "actual ordinary hit after both supplies spent leaves original supply/deadlines unchanged")


func _finite_markers_equal(a: Dictionary, b: Dictionary) -> bool:
	for key: String in ["generation", "spent_ids", "activation_s", "deadline_s"]:
		if not _same(a[key], b[key]): return false
	return float(b.clock_s) >= float(a.clock_s)


func _finite_reactions_idle() -> bool:
	for id: String in Bloom.group_ids(2):
		var actor: Act1MushroomSelenite = _source(id)
		if not actor.dead and actor.get_spore_response_state().phase != "none": return false
	return true


func _finite_retreat_row(consumer: CinderSporeRepulsion, field: CinderSporeField) -> Dictionary:
	for id: String in Bloom.group_ids(2):
		var actor: Act1MushroomSelenite = _source(id)
		var response: Dictionary = actor.get_spore_response_state()
		var record: Dictionary = consumer.source_state(id)
		var control: Dictionary = _scheduler().source_control_state(actor)
		var outward: Vector3 = actor.global_position - field.global_position
		outward.y = 0.0
		if response.alive and response.phase == "retreat" and response.velocity != Vector3.ZERO and response.velocity.dot(outward) > 0.0 and not record.get("route", {}).is_empty() and record.route.elapsed_s > 0.0 and control.get("outside_transaction", false) and control.get("reservations") == []:
			return _encode({"source_id": id, "response": response, "consumer": record, "field": field.state(), "native": actor.pure_presentation_state(), "control": control})
	return {}
