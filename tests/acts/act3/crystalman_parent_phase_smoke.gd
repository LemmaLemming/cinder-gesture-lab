extends "res://tests/acts/act3/crystalman_two_slot_rule_room_smoke.gd"
## UNEXECUTED TEST ONLY two genuine capture phases under the production parent.
## Starts at explicitly DECLARED TEST phase1 entry; regular deaths are not earned
## by this fixture. Both current captures/escapes/primary releases and normal
## spent successor boundaries below are genuine routed input/native physics.
## Reuses exact accepted mechanics helper, never rewrites Hero pose/resources,
## extends a deadline, waits original recovery for progression, or filters owner.
const PARENT_ROOM: String="res://tests/acts/act3/fixtures/crystalman_declared_2.tscn"
var _outer: CinderLevel
var _phase_capacity: int=1
var _phase_ids: Array[int]=[]
var _cold_candidate: SubViewport
var _quiet_count: int=0
var _phase_actor_origin: float=0.0

func _room_path() -> String: return PARENT_ROOM
func _expected_capture_slots() -> int: return _phase_capacity

func _run() -> void:
	_clock_join_only=true
	if not _expect(OS.get_cmdline_user_args().is_empty(),"One declared phase-entry focused native case"): quit(1); return
	root.size=Vector2i(340,736)
	root.content_scale_size=root.size
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if await _open():
		if await _ordinary_case():
			if _expect(_outer.call("parent_owned_state").stage==3,"Actual phase1 release installs phase2 immediately"):
				_phase_capacity=2
				_bind_current()
				_reset_phase_observers()
				if await _wait_phase("recording",180): await _two_slot_ordinary_case()
		if _failures==0:
			_game.call("open_bench")
			await process_frame
			var route: Dictionary=_outer.call("parent_owned_state")
			_expect(route.stage==4 and route.phase_metadata.size()==2 and route.phase_metadata[0].capacity==1 and route.phase_metadata[1].capacity==2 and not is_instance_valid(_outer.get("current_unit")) and route.exit_state=="available","Both genuine local releases retain only exact closed phase receipts and expose plain contact")
			await _sample_parent("bare-after-two-genuine-releases")
	await _close_parent()
	print("Crystalman full-parent phase candidate: %d checks/%d failures/%d native ticks. Three earlier regular deaths were DECLARED TEST setup; no full-route/art acceptance."%[_checks,_failures,_ticks])
	quit(0 if _failures==0 else 1)

func _open() -> bool:
	paused=false
	_game=MainScene.instantiate()
	_game.set("level_scene_path",PARENT_ROOM)
	root.add_child(_game)
	_hero=_game.get("player") as CinderPlayer
	_outer=_game.get("active_level") as CinderLevel
	_bind_current()
	if not _expect(_outer!=null and _room!=null and _hero!=null and String(_outer.get("last_configuration_error")).is_empty() and _outer.call("parent_owned_state").stage==2,"Declared phase1 native parent uses actual external54m collision and shared Player"): return false
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
	return await _wait_phase("recording",180)

func _bind_current() -> void:
	_room=_outer.get("current_unit") as CinderLevel
	var route: Dictionary=_outer.call("parent_owned_state")
	if route.stage in [2,3]: _phase_actor_origin=float(route.entries[route.stage].actor_clock_s)
	if is_instance_valid(_room):
		_scheduler=_room.get("threat_scheduler") as CinderThreatScheduler
		_gate=_room.get("capture_gate") as CinderReplayCaptureGate
		if not _phase_ids.has(_room.get_instance_id()):
			_phase_ids.append(_room.get_instance_id())
			_gate.sequence_retired.connect(_on_retired)
	else: _scheduler=null; _gate=null

func _reset_phase_observers() -> void:
	_events.clear(); _retirements.clear(); _expected_slots.clear()
	_opportunities.clear(); _completed_prefix.clear()
	_reentrant_rejected=false; _blast_seen=false

func _tick() -> bool:
	if paused or not is_instance_valid(_barrier): return _expect(false,"Actual unpaused native post-consumer barrier required")
	_barrier.waiting=true; _barrier.expired=false; _barrier.frames=0
	await _barrier.observed
	_ticks+=1
	if not is_instance_valid(_room) or _outer.get("current_unit")!=_room: _bind_current()
	var fixed: bool=_floor_collision.global_transform==_floor_transform and (_floor_collision.shape as BoxShape3D).size==_floor_size
	return _expect(not _barrier.expired and not paused and not _hero.dead and _hero.hp==_hp and _hero.equipment.snapshot()==_kit and fixed and not _blast_seen and String(_outer.get("last_configuration_error")).is_empty(),"Actual current native unit advances without hidden parent waiting/pose/resource/floor rewrite",String(_outer.get("last_configuration_error")))

func _pause_resume(label: String) -> bool:
	if not await _sample_parent(label): return false
	var button: Button=_find_resume(_game.get("hud"))
	if not _expect(button!=null and button.is_visible_in_tree(),"Actual current Resume visible"): return false
	var before: Dictionary=_hero.snapshot_state()
	var input: String=var_to_bytes(_game.call("get_input_observation_state")).hex_encode()
	_touch(button.get_global_rect().get_center(),91)
	return _expect(not paused and _wire_exact(before,_hero.snapshot_state()) and input==var_to_bytes(_game.call("get_input_observation_state")).hex_encode(),"Actual Resume is consumed without native gameplay action/clock")

func _complete_response_dash(sequence_before: int,deadline: float) -> bool:
	# Only this fixture comparison changes: production clocks/timelines remain
	# independent. An outer Hero is never reset at a fresh child epoch.
	for _i: int in range(60):
		if float(_hero.get_threat_response_state().motion.dash_left_s)==0.0:
			var actions: Array[Dictionary]=_hero.get_world_action_records(sequence_before)
			return _expect(actions.size()==1 and actions[0].kind=="dash" and not actions[0].collision_shortened and not actions[0].movement_damage and actions[0].equipment_ids==_kit and _scheduler.get_clock()<=deadline and _hero.is_on_floor(),"Actual completed ordinary dash precedes original current-unit deadline; outer actor stamp remains in its own epoch",str(actions))
		if not await _tick(): return false
	return _expect(false,"Bounded actual current-unit response dash completes")

func _sever_two_with_actual_recovery() -> bool: return await _sever_with_real_primary()

func _sever_with_real_primary() -> bool:
	var original: Dictionary=_room.call("state")
	var old: WeakRef=weakref(_room)
	var old_gate: WeakRef=weakref(_gate)
	var old_owner: WeakRef=weakref(_room.get("playback"))
	var deadline: float=float(original.lease.adapter.timeline_origin_s)+float(original.sequence.timeline.tether_until_s)-_scheduler.TIME_MARGIN
	var tether: Node3D=_room.get("tether") as Node3D
	var direction: Vector3=tether.global_position-_hero.global_position
	direction.y=0.0
	var before: int=_latest_sequence()
	var error: String=_tap(direction.normalized() if not direction.is_zero_approx() else Vector3.RIGHT)
	var actions: Array[Dictionary]=_hero.get_world_action_records(before)
	if not _expect(error.is_empty() and actions.size()==1 and actions[0].kind=="primary" and actions[0].hits==0 and _room.call("state").tether_hits==1 and _room.call("state").cleared,"Actual ordinary primary releases current native tether once",error): return false
	var primary: Dictionary=actions[0]
	if not _expect(float(original.clock_s)+maxf(float(primary.cooldown_s),float(primary.commitment_duration_s))<=deadline,"Unchanged original opening permits full ordinary primary recovery"): return false
	var actor_deadline: float=_hero.get_world_action_clock()+(deadline-float(original.clock_s))
	var wanted: int=3 if _phase_capacity==1 else 4
	for _i: int in range(30):
		if _outer.call("parent_owned_state").stage==wanted: break
		if not await _tick(): return false
	var route: Dictionary=_outer.call("parent_owned_state")
	if not _expect(route.stage==wanted and route.phase_metadata.size()==_phase_capacity and old.get_ref()==null and old_gate.get_ref()==null and old_owner.get_ref()==null,"Ordinary whole spent-unit disposal installs immediate successor/bare stage; no retained canceled codec"): return false
	var receipt: Dictionary=route.phase_metadata.back()
	if not _expect(receipt.capacity==_phase_capacity and receipt.delivered_attack_count==_phase_capacity and receipt.tether_hits==1 and receipt.completed_at_unit_s<float(original.lease.recovery_until_s) and _hero.hp==_hp and _hero.equipment.snapshot()==_kit,"Actual closed earned receipt precedes old finite recovery expiry; permanent floor and ordinary Player persist"): return false
	# Snapshot immediately while the genuine original Player commitment can
	# remain live. Fresh current phase2 Gate may be configured generation0,
	# never forced armed/rewound or coupled to old recovery expiry.
	if not await _sample_parent("immediate-successor-%d"%wanted): return false
	var resume: Button=_find_resume(_game.get("hud"))
	if not _expect(resume!=null,"Actual immediate successor Resume exists"): return false
	_touch(resume.get_global_rect().get_center(),91)
	for _i: int in range(120):
		var response: Dictionary=_hero.get_threat_response_state()
		if float(response.primary_cooldown_left_s)==0.0 and float(response.commitment_remaining_s)==0.0:
			return _expect(_hero.get_world_action_clock()<=actor_deadline and _latest_sequence()==int(primary.sequence),"Actual original Player recovery completes before its unchanged deadline under fresh successor controls")
		if not await _tick(): return false
	return _expect(false,"Bounded original Player recovery completes normally")

func _sample_parent(label: String) -> bool:
	_game.call("open_bench")
	await process_frame
	var saved: Dictionary={"player":_hero.snapshot_state(),"level":_outer.snapshot_state_for_presentation(_game.get("camera"),_game.get("hud"))}
	if not _expect(paused and not saved.player.is_empty() and not saved.level.is_empty() and _outer.snapshot_error_with_player(saved.level,saved.player).is_empty(),"Actual complete outer/current native unit snapshot: "+label,_outer.last_snapshot_error): return false
	var parsed: Dictionary=Exact.parse(Exact.stringify(saved))
	if not _expect(parsed.get("accepted",false) and _wire_exact(parsed.value,saved),"Exact complete parent transport: "+label): return false
	_cold_candidate=SubViewport.new()
	_cold_candidate.size=Vector2i(root.get_visible_rect().size)
	_cold_candidate.own_world_3d=true
	_cold_candidate.render_target_update_mode=SubViewport.UPDATE_DISABLED
	root.add_child(_cold_candidate)
	var receiver: Node=MainScene.instantiate()
	receiver.set("level_scene_path",PARENT_ROOM)
	_cold_candidate.add_child(receiver)
	paused=true
	var parent: CinderLevel=receiver.get("active_level") as CinderLevel
	var actor: CinderPlayer=receiver.get("player") as CinderPlayer
	parent.exit_level()
	var ok: bool=parent.enter_restore_candidate(actor,receiver.get("fx"),receiver,saved.level,saved.player)
	_watch_quiet(parent)
	_watch_quiet(actor)
	var quiet_before: int=_quiet_count
	if not _expect(ok and parent.snapshot_error_with_player(saved.level,saved.player).is_empty() and actor.restore_state(saved.player) and parent.restore_state(saved.level),"Independent native parent/Player/current-unit quiet commit: "+label,parent.last_snapshot_error):
		parent.exit_level(); _cold_candidate.queue_free(); _cold_candidate=null; return false
	var camera: Camera3D=receiver.get("camera") as Camera3D
	camera.global_transform=(_game.get("camera") as Camera3D).global_transform # TEST saved-view context only.
	var hud: GameHUD=receiver.get("hud") as GameHUD
	hud.update_status(actor.hp,actor.max_hp,actor.shells,actor.max_shells,0,parent.objective_text)
	await process_frame
	var optical: String=parent.restore_candidate_presentation_error(camera,hud)
	ok=_expect(optical.is_empty() and _quiet_count==quiet_before and parent.finish_restore_candidate() and _wire_exact(parent.snapshot_state_for_presentation(camera,hud),saved.level) and _wire_exact(actor.snapshot_state(),saved.player),"Whole independently restored original native optics/recapture: "+label,optical)
	parent.exit_level()
	_cold_candidate.queue_free(); _cold_candidate=null
	for _i: int in range(3): await process_frame
	return ok

func _close_parent() -> void:
	paused=true
	if is_instance_valid(_cold_candidate): _cold_candidate.queue_free()
	if is_instance_valid(_outer): _outer.exit_level()
	await super._close()
	_outer=null

func _watch_quiet(node: Node) -> void:
	for row: Dictionary in node.get_signal_list():
		if row.name in ["fired","died","action_resolved","world_action_executed","sequence_retired","gate_failed","reservation_invalidated","state_changed","event_dispatched","playback_failed","recording_rejected","recording_joined","tether_severed","checkpoint_requested","completion_requested","contact_exit_requested"]:
			var callback: Callable=Callable(self,"_quiet"+str(row.args.size()))
			if callback.is_valid(): node.connect(row.name,callback)
	for child: Node in node.get_children(): _watch_quiet(child)
func _quiet0() -> void: _quiet_count+=1
func _quiet1(_a: Variant) -> void: _quiet_count+=1
func _quiet2(_a: Variant,_b: Variant) -> void: _quiet_count+=1
func _quiet3(_a: Variant,_b: Variant,_c: Variant) -> void: _quiet_count+=1
