extends "res://tests/acts/act3/crystalman_parent_phase_smoke.gd"
## DRAFT / UNEXECUTED. One selected initial carried kit and genuine one-slot
## parent capture/whole proof/ordinary response/release. Earlier regular deaths
## remain DECLARED TEST history. No whole route, art, Save/Retry or all-kit claim.
## Separate --wall-heavy uses the retained EastBoundary, with no new geometry.
## Existing helper/runtime assertions are unchanged; this is a narrower case.

const CASES: Array[String] = ["--fast", "--long", "--heavy", "--wall-heavy"]
const CARRIED_KITS: Dictionary = {
	"fast": {"jacket":"CLOTH-J0", "pants":"CLOTH-P0", "shoes":"CLOTH-S1", "weapon":"WEAPON-02"},
	"long": {"jacket":"CLOTH-J1", "pants":"CLOTH-P1", "shoes":"CLOTH-S2", "weapon":"WEAPON-04"},
	"heavy": {"jacket":"CLOTH-J1", "pants":"CLOTH-P2", "shoes":"CLOTH-S2", "weapon":"WEAPON-03"},
}
var _selected_case: String = ""
var _selected_kit: Dictionary = {}
var _wall_outcome: String = "not_requested"
var _wall_recorded_gate: Dictionary = {}
var _wall_recorded_slot: Dictionary = {}
var _wall_recorded_wire: String = ""

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not _expect(args.size()==1 and args[0] in CASES, "Exactly one bounded carried-kit or wall case"): quit(1); return
	_selected_case=String(args[0])
	_selected_kit=CARRIED_KITS["heavy" if _selected_case=="--wall-heavy" else _selected_case.trim_prefix("--")].duplicate(true)
	_phase_capacity=1
	_clock_join_only=false
	root.size=Vector2i(340,736)
	root.content_scale_size=root.size
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if await _open():
		var completed: Variant
		if _selected_case=="--wall-heavy": completed=await _wall_case()
		else: completed=await _one_slot_case()
		_expect(completed is bool and completed,"Selected coroutine completes with explicit true",JSON.stringify({"case":_selected_case,"return_type":typeof(completed),"wall_outcome":_wall_outcome}))
		if _selected_case=="--wall-heavy":
			_expect(_wall_outcome in ["exact_native_admission","exact_visible_rejection_and_rearm"],"Wall case reaches an explicit terminal outcome",_wall_outcome)
	await _close_parent()
	print("Crystalman carried-kit/wall DRAFT: %s, %d checks/%d failures/%d native ticks; wall outcome %s. Declared earlier history, one-slot scope; no full route/art/Save/Retry acceptance." % [_selected_case,_checks,_failures,_ticks,_wall_outcome])
	quit(0 if _failures==0 else 1)

func _open() -> bool:
	paused=false
	_game=MainScene.instantiate()
	_game.set("level_scene_path",PARENT_ROOM)
	root.add_child(_game)
	_hero=_game.get("player") as CinderPlayer
	_outer=_game.get("active_level") as CinderLevel
	_bind_current()
	if not _expect(_outer!=null and _room!=null and _hero!=null and _gate!=null and String(_outer.get("last_configuration_error")).is_empty() and _outer.call("parent_owned_state").stage==2, "Declared phase1 parent keeps actual permanent floor and shared Player"): return false
	if not _expect(not _gate.state().capture.armed and _latest_sequence()==0, "Initial safe kit setup precedes any armed recording or executed action"): return false
	_game.call("open_bench")
	if not _expect(paused and get_nodes_in_group("enemies").is_empty(), "Initial declared safe boundary permits public carried clothing setup"): return false
	for slot: String in ["jacket","pants","shoes","weapon"]:
		if not _expect(_hero.equip_item(String(_selected_kit[slot])), "Existing public equip accepts initial canonical " + slot): return false
	if not _expect(_hero.equipment.snapshot()==_selected_kit, "Selected existing perk-free carried kit is exact"): return false
	_hero.shells=0 # Explicit initial TEST ONLY supply, before action/history; never rewritten later.
	_hp=_hero.hp
	_kit=_hero.equipment.snapshot()
	_hero.fired.connect(_on_fired)
	_barrier=Barrier.new()
	root.add_child(_barrier)
	var region: Dictionary=_room.call("floor_regions")[0]
	_floor_collision=region.collision
	_floor_transform=_floor_collision.global_transform
	_floor_size=(_floor_collision.shape as BoxShape3D).size
	_reset_phase_observers()
	await process_frame # Paused UI layout only; no Actor clock or physics advance.
	var resume: Button=_find_resume(_game.get("hud"))
	if not _expect(resume!=null and resume.is_visible_in_tree(), "Actual initial Resume is visible"): return false
	var before: int=_latest_sequence()
	_touch(resume.get_global_rect().get_center(),97)
	if not _expect(not paused and _latest_sequence()==before and _hero.hp==_hp and _hero.equipment.snapshot()==_kit, "Initial Resume consumes tap without gameplay publication or kit/HP rewrite"): return false
	return await _wait_phase("recording",180)

func _wait_phase(wanted: String,limit: int) -> bool:
	# Select mechanics only; do not run the parent's separate framing/Save audit.
	for _i: int in range(limit):
		if String(_room.call("state").phase)==wanted: return true
		if not await _tick(): return false
	return _expect(false,"Bounded selected current phase reaches " + wanted,str(_room.call("state")))

func _one_slot_case() -> bool:
	if not await _record_valid(Vector3.BACK): return false
	if not await _wait_phase("warning",240): return false
	return await _resolve_selected_one()

func _resolve_selected_one() -> bool:
	if not _check_join(1): return false # Exact completed path/primary shape/kit, whole lease and current view.
	var playback: CinderReplayPlayback=_room.get("playback") as CinderReplayPlayback
	playback.event_dispatched.connect(_on_replay_event)
	if not await _wait_locked(): return false
	var original: Dictionary=_room.call("state")
	if not _expect(original.proof.get("accepted",false) and original.proof.get("at_lock",false) and not original.proof.get("uses_blast",true) and not original.proof.get("uses_invulnerability",true), "Selected actual kit has a fresh whole ordinary escape/primary proof"): return false
	if not await _follow_proof(original.proof,false): return false
	return await _release_and_recover_one()

func _release_and_recover_one() -> bool:
	var original: Dictionary=_room.call("state")
	var deadline: float=float(original.lease.adapter.timeline_origin_s)+float(original.sequence.timeline.tether_until_s)-_scheduler.TIME_MARGIN
	var actor_deadline: float=_hero.get_world_action_clock()+(deadline-float(original.clock_s))
	var child: WeakRef=weakref(_room)
	var gate_ref: WeakRef=weakref(_gate)
	var owner_ref: WeakRef=weakref(_room.get("playback"))
	var tether: Node3D=_room.get("tether") as Node3D
	var direction: Vector3=tether.global_position-_hero.global_position
	direction.y=0.0
	var before: int=_latest_sequence()
	var error: String=_tap(direction.normalized() if not direction.is_zero_approx() else Vector3.RIGHT)
	var actions: Array[Dictionary]=_hero.get_world_action_records(before)
	if not _expect(error.is_empty() and actions.size()==1 and actions[0].kind=="primary" and actions[0].hits==0 and actions[0].equipment_ids==_kit and _room.call("state").tether_hits==1 and _room.call("state").cleared and not _blast_seen, "Selected kit ordinary primary releases the native low tether once without ammo or enemy-hit credit",error): return false
	var primary: Dictionary=actions[0]
	if not _expect(float(original.clock_s)+maxf(float(primary.cooldown_s),float(primary.commitment_duration_s))<=deadline, "Actual selected recovery fits the unchanged original ordinary opening"): return false
	var expected: Dictionary=original.sequence.timeline.slots[0].events[0]
	if not _expect(_events.size()==1 and _events[0].event_id==expected.event_id and _events[0].kind=="primary" and _events[0].record_sequence==_first_primary.sequence and _retirements.size()==1 and _retirements[0].slot_ids==[1], "One exact original primary event and FIFO retirement, without copied-action recursion"): return false
	for _i: int in range(30):
		if _outer.call("parent_owned_state").stage==3: break
		if not await _tick(): return false
	var route: Dictionary=_outer.call("parent_owned_state")
	if not _expect(route.stage==3 and route.phase_metadata.size()==1 and child.get_ref()==null and gate_ref.get_ref()==null and owner_ref.get_ref()==null, "Normal whole-unit disposal installs immediate successor; no recovery wait gate"): return false
	var receipt: Dictionary=route.phase_metadata[0]
	if not _expect(receipt.capacity==1 and receipt.delivered_attack_count==1 and receipt.tether_hits==1 and receipt.completed_at_unit_s<float(original.lease.recovery_until_s), "Original closed phase receipt is earned before finite recovery expiry"): return false
	for _i: int in range(120):
		var response: Dictionary=_hero.get_threat_response_state()
		if float(response.primary_cooldown_left_s)==0.0 and float(response.commitment_remaining_s)==0.0:
			return _expect(_hero.get_world_action_clock()<=actor_deadline and _latest_sequence()==int(primary.sequence) and _hero.hp==_hp and _hero.equipment.snapshot()==_kit, "Actual selected Player recovery settles by original deadline without extra action/resource repair")
		if not await _tick(): return false
	return _expect(false,"Bounded selected ordinary recovery completes")

func _wall_case() -> bool:
	var boundary: StaticBody3D=_outer.get_node_or_null("EastBoundary") as StaticBody3D
	var solid: CollisionShape3D=boundary.get_node_or_null("Solid") as CollisionShape3D if boundary!=null else null
	if not _expect(boundary!=null and solid!=null and solid.shape is BoxShape3D and boundary.position==Vector3(5.85,0.6,13) and (solid.shape as BoxShape3D).size==Vector3(0.3,1.2,54), "Use original visible permanent EastBoundary with no geometry addition"): return false
	var original_transform: Transform3D=boundary.global_transform
	# Longstep's actual 2.97m first move puts the second requested 2.97m route
	# beyond the existing inner edge. No actor pose or expected landing is set.
	var reposition_before: int=_latest_sequence()
	if not _expect(_swipe(Vector3.RIGHT).is_empty(), "Actual unpaired reposition starts toward existing side edge"): return false
	if not await _wait_capture_dash(reposition_before) or not await _wait_stable(): return false
	if not _expect(_gate.state().capture.allocated==0 and _gate.state().capture.sealed==0, "Unpaired reposition allocates no capture slot"): return false
	var before: int=_latest_sequence()
	if not _expect(_swipe(Vector3.RIGHT).is_empty(), "Actual routed capture dash requests travel into the retained edge"): return false
	if not await _wait_capture_dash(before) or not await _wait_stable(): return false
	var actions: Array[Dictionary]=_hero.get_world_action_records(before)
	if not _expect(actions.size()==1 and actions[0].kind=="dash" and actions[0].blocked and actions[0].collision_shortened and actions[0].distance>0.0 and float(actions[0].distance)+0.001<float(actions[0].resolved_stats.dash_distance) and not actions[0].movement_damage and actions[0].equipment_ids==_kit and actions[0].landing==_hero.global_position, "Real positive wall-shortened action publishes only at completed actual landing"): return false
	_first_dash=Player.encode_world_action_record(actions[0],_hero.get_world_action_clock())
	var release: Vector2=_game.call("get_aim_anchor_normalized")
	if not _expect(_tap(Vector3.RIGHT).is_empty(), "Actual ordinary primary pairs with the wall-shortened record"): return false
	actions=_hero.get_world_action_records(before)
	if not _expect(actions.size()==2 and actions[1].kind=="primary" and actions[1].world_origin==actions[0].landing and actions[1].equipment_ids==_kit and _game.call("get_aim_anchor_normalized")==release, "Executed original primary keeps actual shortened landing/shape/kit and retained aim"): return false
	_first_primary=Player.encode_world_action_record(actions[1],_hero.get_world_action_clock())
	# _tap returned after the actual publication callbacks. Observe the genuine
	# complete Gate NOW, before a tick may prepare/reject and cancel its samples.
	if not _observe_wall_pair(): return false
	for _i: int in range(240):
		var state: Dictionary=_room.call("state")
		if state.phase=="warning":
			_wall_outcome="exact_native_admission"
			return await _resolve_selected_one()
		if state.phase=="rejected":
			# Runtime last_rejected_capture documents failed preparation only. Use
			# the already authenticated original pending/slot observation instead.
			var marker: MeshInstance3D=_room.get_node_or_null("VisibleRejectedRecording") as MeshInstance3D
			var reason: Variant=state.get("last_rejection")
			if not _expect(reason is String and not reason.is_empty() and _wall_observation_unchanged() and marker!=null and marker.is_visible_in_tree() and _room.objective_text.contains("FADES SAFELY") and state.joins==0 and _scheduler.reservations().is_empty() and _gate.retirement_state().is_empty() and _events.is_empty(), "Actual supported rejection keeps authenticated original wall path/shape custody and visible safe rearm cue",JSON.stringify({"reason":reason,"last_rejected_capture_keys":state.get("last_rejected_capture",{}).keys(),"observed_slot_id":_wall_recorded_slot.get("slot_id")})): return false
			var rejection_generation: int=int(state.generation)
			if not await _wait_phase("recording",180): return false
			if not _expect(int(_room.call("state").generation)==rejection_generation+1 and _gate.state().capture.allocated==0 and _gate.state().capture.sealed==0 and boundary.global_transform==original_transform and _wall_observation_unchanged(), "Fresh empty generation rearms without wall/actor/proof rewrites or losing original test custody"): return false
			var escape_before: int=_latest_sequence()
			if not _expect(_swipe(Vector3.LEFT).is_empty(), "Untrapped actual Player can leave the same fixed edge by ordinary swipe"): return false
			if not await _wait_capture_dash(escape_before) or not await _wait_stable(): return false
			_wall_outcome="exact_visible_rejection_and_rearm"
			return _expect(_hero.hp==_hp and _hero.equipment.snapshot()==_kit and boundary.global_transform==original_transform and _gate.state().capture.allocated==0 and _gate.state().capture.sealed==0 and _outer.call("parent_owned_state").stage==2 and _wall_observation_unchanged(), "Safe ordinary departure preserves floor/kit/HP/original custody and produces no partial replay")
		if not await _tick(): return false
	return _expect(false,"Wall-shortened capture reaches ordinary admission or explicit supported rejection")


func _observe_wall_pair() -> bool:
	var previous_pause: bool=paused
	paused=true # TEST ONLY synchronous observation; no UI/input/await/tick.
	var actor_before: Dictionary=_hero.snapshot_state()
	var input_before: PackedByteArray=var_to_bytes(_game.call("get_input_observation_state"))
	var gate: Dictionary=_gate.snapshot_state() # Getter only; publication already synchronized the Gate.
	var error: String=_gate.last_snapshot_error
	if error.is_empty() and not gate.is_empty(): error=_gate.snapshot_error(gate,actor_before)
	var actor_same: bool=_wire_exact(actor_before,_hero.snapshot_state())
	var input_same: bool=input_before==var_to_bytes(_game.call("get_input_observation_state"))
	paused=previous_pause # Restore EXACT actual prior pause state before assertions.
	if not _expect(error.is_empty() and not gate.is_empty() and actor_same and input_same,"Public complete Gate/actual Player observation is valid and changes no Actor/input/tick",error): return false
	if not _expect(gate.get("api_revision")==_gate.API_REVISION and gate.get("schema_version") is int and gate.schema_version==1 and gate.get("capture") is Dictionary and gate.get("prepared_sequence") is Dictionary and gate.prepared_sequence.is_empty() and gate.get("consumed_sequence") is Dictionary and gate.consumed_sequence.is_empty() and gate.get("retirement") is Dictionary and gate.retirement.is_empty(),"Typed original unadmitted Gate envelope required",JSON.stringify({"gate_keys":gate.keys()})): return false
	var capture: Dictionary=gate.capture
	if not _expect(capture.get("slots") is Array and capture.get("pending") is Array and capture.slots.size()+capture.pending.size()==1 and capture.get("allocated")==1 and capture.get("max_slots")==1 and capture.get("armed")==true,"Exactly one actual pending or sealed original wall pair required",JSON.stringify({"capture_keys":capture.keys(),"slots_type":typeof(capture.get("slots")),"pending_type":typeof(capture.get("pending"))})): return false
	var observed: Variant=capture.pending[0] if capture.pending.size()==1 else capture.slots[0]
	if not _expect(observed is Dictionary and observed.get("slot_id")==1 and observed.get("dash") is Dictionary and observed.get("primary") is Dictionary and observed.get("blast") is Dictionary and observed.blast.is_empty() and _wire_exact(observed.dash,_first_dash) and _wire_exact(observed.primary,_first_primary),"Actual captured pending/slot dash+primary exactly match executed shortened geometry/gear/shape",JSON.stringify({"observed_type":typeof(observed),"slot_id":observed.get("slot_id") if observed is Dictionary else null})): return false
	_wall_recorded_gate=gate.duplicate(true)
	_wall_recorded_slot=observed.duplicate(true)
	_wall_recorded_wire=Exact.stringify(_wall_recorded_gate)
	return _expect(not _wall_recorded_wire.is_empty(),"Whole original wall observation has exact immutable test custody")

func _wall_observation_unchanged() -> bool:
	return not _wall_recorded_wire.is_empty() and Exact.stringify(_wall_recorded_gate)==_wall_recorded_wire and _wall_recorded_slot.get("dash") is Dictionary and _wall_recorded_slot.get("primary") is Dictionary and _wire_exact(_wall_recorded_slot.dash,_first_dash) and _wire_exact(_wall_recorded_slot.primary,_first_primary)
