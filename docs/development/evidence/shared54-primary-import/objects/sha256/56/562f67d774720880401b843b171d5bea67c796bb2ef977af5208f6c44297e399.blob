extends "res://tests/acts/act3/garden_root_rule_room_smoke.gd"
## TEST ONLY component triple; published core API2, actual large authored floor.
## Reuses only Main/real gesture/post-actor/dash/cleanup helper patterns.
## No authored route, whole CinderLevel codec, disk, GUI or campaign acceptance.

const COMPONENT_ROOM: String = "res://tests/acts/act3/fixtures/garden_network_component.tscn"
const ComponentScript = preload("res://tests/acts/act3/fixtures/garden_network_component.gd")
const CoreScript = preload("res://scripts/acts/act3/garden_root_network.gd")
const LaneScript = preload("res://scripts/combat/lane_mechanism.gd")
const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const PairExact = preload("res://scripts/campaign/exact_json.gd")
const PairCodec = preload("res://scripts/campaign/snapshot_codec.gd")
const MAX_CLOCK_S: float = 20.0
var _core: Node3D


func _run() -> void:
	if not _expect(OS.get_cmdline_user_args().is_empty(), "component pair uses one actual starter/Standard without fabricated selectors"):
		await _finish()
		return
	if not await _open():
		await _finish()
		return
	var first: Dictionary = await _admit("draw", Vector3.LEFT)
	if first.is_empty() or not await _earned_return(first, "draw"):
		await _finish()
		return
	if not _ordinary_hit(60.0, 40.0, 1):
		await _finish()
		return
	var first_wall_ms: int = Time.get_ticks_msec()
	var native_before: Dictionary = _retained_exchange("draw")
	if not _expect(not native_before.is_empty(), "genuine public recovery lease exists before the crossing primary"):
		await _finish()
		return
	if not await _second_primary_ready(first_wall_ms, float(native_before.recovery_until_s)):
		await _finish()
		return
	_allow_cancelled = true
	# The real crossing tap runs only after actual recovery/cooldown readiness.
	native_before = _retained_exchange("draw")
	if not _ordinary_hit(40.0, 30.0, 2) or not _expect(_all_sources_clear(), "genuine phase crossing clears both actual leases/cues before capture"):
		await _finish()
		return
	if not await _completed_pause():
		await _finish()
		return
	var pair_a: Dictionary = _capture_checked("current earning exchange")
	if pair_a.is_empty() or not _expect(pair_a.core.tether.hp == 30.0 and pair_a.core.tether.phase == 2 and pair_a.core.control.boundaries.size() == 1 and pair_a.core.control.boundaries[0].cycle == 1 and pair_a.core.control.boundaries[0].recovery_receipt.sun_choice == 0 and _wire_exact(pair_a.core.control.boundaries[0].recovery_receipt.exchange, native_before), "API2 retains all twelve genuine recovery fields and held choice before cancellation"):
		await _finish()
		return
	if not _current_exchange_negative(pair_a):
		await _finish()
		return
	_game.call("resume_lab")
	var second: Dictionary = await _admit("draw", Vector3.LEFT)
	if second.is_empty() or not _expect(_source("draw").state().cycle == 2 and second.reservation_id != first.reservation_id and _tether.get("hp") == 30.0 and _tether.get("phase") == 2, "same actual Draw admits phase2 cycle2 after original cooldown without a replacement source or Scheduler"):
		await _finish()
		return
	if not await _earned_return(second, "draw") or not await _completed_pause():
		await _finish()
		return
	var pair_b: Dictionary = _capture_checked("replaced earning exchange")
	if pair_b.is_empty() or not _expect(pair_b.core.tether.hp == 30.0 and pair_b.core.tether.phase == 2 and pair_b.core.mechanisms.draw.cycle == 2 and pair_b.core.mechanisms.draw.phase == "recovery" and pair_b.scheduler.serial > pair_a.scheduler.serial and _wire_exact(pair_b.core.control.boundaries, pair_a.core.control.boundaries) and pair_b.core.control.boundaries[0].exchange_id != pair_b.core.mechanisms.draw.exchange.id, "actual later Draw replaces its latest exchange while original earned boundary receipt remains exact"):
		await _finish()
		return
	if not _replaced_negatives(pair_b) or not await _fresh_pair(pair_b):
		await _finish()
		return
	await _finish()


func _open() -> bool:
	_game = MainScene.instantiate()
	root.add_child(_game)
	_game.call("open_bench")
	if not _expect(paused and _game.call("is_lab_level") and get_nodes_in_group("enemies").is_empty(), "actual enemy-free paused Main lab precedes component loading"):
		return false
	if not _expect(_game.call("load_level_scene", COMPONENT_ROOM), "public Main loads the declared TEST ONLY component scene"):
		return false
	_game.call("open_bench")
	if not _bind_component():
		return false
	_barrier = PostActorBarrier.new()
	_game.add_child(_barrier)
	for _i: int in range(5):
		await process_frame
	_connect_events()
	return _expect(_one_player_scheduler() and _scheduler.get_clock() == 0.0 and _scheduler.encounter_profile().get("id") == "standard" and _scheduler.reservations().is_empty() and _tether.get("hp") == 60.0 and _tether.get("phase") == 1 and _source("draw").state().cycle == 0 and _source("enclose").state().cycle == 0 and _hero.stats.primary_damage == 20.0 and _hero.hp == _hero.max_hp and _hero.presentation_id == "act3_traveller" and _hero.global_position == Vector3(0, 0.1, 1.25), "fresh actual component keeps Standard clock0, original60/phase1, one starter Player and no admitted history")


func _bind_component() -> bool:
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _expect(_level != null and _hero != null and _level.get_script() == ComponentScript and _level.scene_file_path == COMPONENT_ROOM and paused, "actual Main binds the component recipient and one Player before physics"):
		return false
	_core = _level.get("root_network") as Node3D
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	if not _expect(_core != null and _scheduler != null and _core.get_script() == CoreScript and _scheduler.get_script() == SchedulerScript and String(_level.call("runtime_error")).is_empty(), "published API2 core and actual Scheduler configure against authored native floor", String(_level.call("runtime_error"))):
		return false
	_tether = _core.call("get_tether") as StaticBody3D
	_mechanisms = _core.call("get_mechanisms")
	_hero_hp = _hero.hp
	_kit = _hero.equipment.snapshot()
	_fixed_target = _tether.global_transform
	_fixed_sources.clear()
	for kind: String in ["draw", "enclose"]:
		_fixed_sources[kind] = _source(kind).global_transform
	var schedulers: Array[Node] = []
	_find_script(_level, SchedulerScript, schedulers)
	var bindings: Dictionary = _level.call("scheduler_bindings")
	var collision: CollisionShape3D = bindings.floors[ComponentScript.FLOOR_ID].collision as CollisionShape3D
	var body: StaticBody3D = collision.get_parent() as StaticBody3D
	return _expect(schedulers.size() == 1 and schedulers[0] == _scheduler and bindings.owners.size() == 2 and bindings.actors.size() == 1 and bindings.actors.hero == _hero and collision.name == "Solid" and not collision.disabled and collision.shape is BoxShape3D and (collision.shape as BoxShape3D).size == Vector3(14, 1, 78) and body.global_transform == Transform3D(Basis.IDENTITY, Vector3(0, -0.5, 25)) and body.collision_layer == 1 and body.collision_mask == 0 and bindings.floors[ComponentScript.FLOOR_ID].safe_rect == Rect2(-7, -14, 14, 78), "complete actual component bindings contain one Scheduler/two native owners/one Hero and exact authored14x78 floor")


func _connect_events() -> void:
	_events.clear()
	_hero.world_action_executed.connect(func(_record: Dictionary) -> void: _events.append("world_action"))
	_hero.fired.connect(func(kind: String) -> void: _events.append("fired_" + kind))
	_tether.connect("state_changed", func(_state: Dictionary) -> void: _events.append("target_state"))
	_core.connect("phase_boundary", func(_crossing: Dictionary) -> void: _events.append("boundary"))
	_scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _events.append("cancel"))
	for kind: String in ["draw", "enclose"]:
		_source(kind).hit_resolved.connect(func(_id: String, _cycle: int, _result: Dictionary) -> void: _events.append("enemy_hit"))
		_source(kind).state_changed.connect(func(_state: Dictionary) -> void: _events.append("source_state_" + kind))
		_source(kind).get_cue().state_changed.connect(func(_state: Dictionary) -> void: _events.append("cue_" + kind))


func _admit(kind: String, direction: Vector3) -> Dictionary:
	_active_kind = kind
	if paused:
		_game.call("resume_lab")
	for _i: int in range(300):
		if bool(_hero.get_threat_response_state().stable):
			var answer: Dictionary = _core.call("try_start", kind, direction, 0)
			if answer.get("accepted", false):
				var error: String = String(_game.call("camera_framing_error", _level.camera_framing_points()))
				if _expect(error.is_empty() and _source(kind).state().status == "running" and _source(kind).state().phase == "warning", "real public core admission retains current native camera visibility", error):
					return answer
				return {}
		if not await _tick():
			return {}
	_expect(false, "finite same-source original cooldown and actual optics allow a genuine admission", str(_core.call("state")))
	return {}


func _earned_return(answer: Dictionary, kind: String) -> bool:
	var source: CinderLaneMechanism = _source(kind)
	var proof: Dictionary = answer.get("proof", {})
	var lease: Dictionary = _retained_exchange(kind)
	if not _expect(answer.get("accepted", false) and not lease.is_empty() and lease.id == answer.get("reservation_id") and proof.get("accepted", false) and not proof.get("uses_blast", true) and not proof.get("uses_invulnerability", true), "actual native lease supplies the ordinary escape-return witness", str(answer)):
		return false
	var escaped: bool = false
	var returned: bool = false
	for segment: Dictionary in proof.path:
		if segment.kind not in ["escape_dash", "positioning_dash"]:
			continue
		if not await _until(float(segment.start_s)):
			return false
		var intended: Vector3 = (segment.to - segment.from).normalized()
		var error: String = _swipe(intended)
		var dash: Dictionary = _hero.get_committed_dash_state()
		if not _expect(error.is_empty() and dash.get("active", false) and dash.distance == _hero.stats.dash_distance and dash.duration_s == _hero.stats.dash_duration and (dash.direction as Vector3).distance_to(intended) < 0.000001, "routed component dash retains the genuine full shared action", error) or not await _complete_dash(segment):
			return false
		if segment.kind == "escape_dash":
			escaped = true
		else:
			returned = true
	if not await _until(float(proof.primary_time_s)):
		return false
	return _expect(escaped and returned and source.state().status == "running" and source.state().phase == "recovery" and _scheduler.get_clock() <= float(lease.recovery_until_s) and _hero.global_position.distance_to(proof.attack_position) < 0.02 and _hero.hp == _hero_hp, "actual ordinary return reaches the open low tether inside native Recovery without source or Hero pose/HP writes")


func _ordinary_hit(before_hp: float, after_hp: float, after_phase: int) -> bool:
	var actions: Array[Dictionary] = _hero.get_world_action_records()
	var count: int = actions.size()
	var actual_before: float = float(_tether.get("hp"))
	var error: String = _tap(_target_direction())
	actions = _hero.get_world_action_records()
	return _expect(error.is_empty() and actual_before == before_hp and _hero.stats.primary_damage == 20.0 and _tether.get("hp") == after_hp and _tether.get("phase") == after_phase and actions.size() == count + 1 and actions.back().kind == "primary" and actions.back().damage == 20.0 and actions.back().hits == 1 and _hero.hp == _hero_hp and not _events.has("fired_blast"), "genuine ordinary primary earns %.0f to %.0f with exact phase%d" % [before_hp, after_hp, after_phase], error)


func _retained_exchange(kind: String) -> Dictionary:
	var current: Dictionary = _source(kind).state()
	for lease: Dictionary in _scheduler.source_control_state(_source(kind)).get("reservations", []):
		if lease.id != current.reservation_id:
			continue
		var result: Dictionary = {}
		for key: String in LaneScript.EXCHANGE_KEYS:
			result[key] = lease[key]
		result = result.duplicate(true)
		result.source_position = PairCodec.vector3(lease.source_position)
		result.opening_position = PairCodec.vector3(lease.opening_position)
		var shape: Dictionary = lease.geometry.duplicate(true)
		if shape.kind == "lane":
			shape.from = PairCodec.vector3(lease.geometry.from)
			shape.to = PairCodec.vector3(lease.geometry.to)
		else:
			shape.origin = PairCodec.vector3(lease.geometry.origin)
			shape.direction = PairCodec.vector3(lease.geometry.direction)
		result.geometry = shape
		return result
	return {}


func _completed_pause() -> bool:
	if not paused and not _expect(_game.call("request_pause_deferred"), "public Main requests completed native pause"):
		return false
	for _i: int in range(4):
		await process_frame
	return _expect(paused and not _game.call("is_pause_requested"), "completed paused barrier is outside source/target callbacks")


func _component_pair() -> Dictionary:
	var bindings: Dictionary = _level.call("scheduler_bindings")
	var scheduler_packet: Dictionary = _scheduler.snapshot_state(bindings)
	return {"hero": _hero.snapshot_state(), "scheduler": scheduler_packet, "core": _core.call("capture", bindings, scheduler_packet) if not scheduler_packet.is_empty() else {}}


func _pair_error(pair: Dictionary) -> String:
	var error: String = PairCodec.keys_error(pair, ["hero", "scheduler", "core"])
	if not error.is_empty() or not pair.hero is Dictionary or not pair.scheduler is Dictionary or not pair.core is Dictionary:
		return "Closed actual Hero/full Scheduler/core component triple required"
	error = _hero.snapshot_error(pair.hero)
	return String(_core.call("snapshot_error", pair.core, pair.hero, _level.call("scheduler_bindings"), pair.scheduler)) if error.is_empty() else error


func _capture_checked(label: String) -> Dictionary:
	var pair: Dictionary = _component_pair()
	if not _expect(not pair.hero.is_empty() and not pair.scheduler.is_empty() and not pair.core.is_empty(), "nonempty actual paused component triple: " + label, str(_core.get("last_snapshot_error")) + "; " + _scheduler.last_snapshot_error):
		return {}
	var before: Dictionary = _observation()
	var decoded: Dictionary = PairExact.parse(PairExact.stringify(pair))
	if not _expect(pair.core.api_revision == "act3-garden-root-network-2" and pair.core.schema_version == 2 and pair.scheduler.clock_s == _scheduler.get_clock() and pair.core.tether.clock_s == pair.scheduler.clock_s and decoded.get("accepted", false) and decoded.get("value") is Dictionary and _wire_exact(pair, decoded.value) and _pair_error(decoded.value).is_empty() and before == _observation(), "exact native/JSON component triple validates purely: " + label, str(_core.get("last_snapshot_error"))):
		return {}
	return decoded.value


func _wire_exact(left: Variant, right: Variant) -> bool:
	var lhs: String = PairExact.stringify(left)
	var rhs: String = PairExact.stringify(right)
	return not lhs.is_empty() and not rhs.is_empty() and lhs == rhs


func _current_exchange_negative(pair: Dictionary) -> bool:
	var bad: Dictionary = pair.duplicate(true)
	var crossing: Dictionary = bad.core.control.boundaries[0]
	var exchange: Dictionary = crossing.recovery_receipt.exchange
	var role: Dictionary = bad.core.mechanisms.draw.resolved_role
	var delta: float = minf(0.01, (float(crossing.clock_s) - float(exchange.active_until_s)) * 0.5)
	if not _expect(delta > 0.0, "real crossing has positive recovery slack for a consistent receipt-only forgery"):
		return false
	exchange.start_s = float(exchange.start_s) + delta
	var active_from: float = float(exchange.start_s) + float(role.windup_s)
	exchange.lock_from_s = active_from - float(role.lock_s)
	exchange.active_from_s = active_from
	exchange.active_until_s = active_from + float(role.active_s)
	exchange.recovery_until_s = active_from + float(role.active_s) + float(role.recovery_s)
	exchange.cooldown_until_s = active_from + float(role.attack_interval_s)
	return _negative(pair, bad, "current earning exchange mismatch", "Latest boundary recovery receipt")


func _replaced_negatives(pair: Dictionary) -> bool:
	var bad_clock: Dictionary = pair.duplicate(true)
	bad_clock.core.control.boundaries[0].clock_s = bad_clock.core.control.boundaries[0].recovery_receipt.exchange.active_until_s
	bad_clock.core.control.retry_at_s = float(bad_clock.core.control.boundaries[0].clock_s) + 0.25
	if not _negative(pair, bad_clock, "replaced boundary shifted to Active plus matching retry", "retained native recovery interval"):
		return false
	var bad_deadline: Dictionary = pair.duplicate(true)
	bad_deadline.core.control.boundaries[0].recovery_receipt.exchange.recovery_until_s = float(bad_deadline.core.control.boundaries[0].recovery_receipt.exchange.recovery_until_s) + 0.125
	return _negative(pair, bad_deadline, "older receipt deadline drift", "derive exactly")


func _negative(original: Dictionary, bad: Dictionary, label: String, expected_error: String) -> bool:
	var before: Dictionary = _observation()
	var supplied: Dictionary = bad.duplicate(true)
	var error: String = _pair_error(bad)
	var staged: bool = _core.call("stage_quiet_restore", bad.core, bad.hero, _level.call("scheduler_bindings"), bad.scheduler)
	if staged:
		_core.call("abort_uncommitted_restore")
	var again: Dictionary = _component_pair()
	return _expect(error.contains(expected_error) and not staged and _wire_exact(bad, supplied) and before == _observation() and _pair_error(original).is_empty() and _wire_exact(again, original), "pure rejection/unstaged target is atomic: " + label, error)


func _fresh_pair(saved: Dictionary) -> bool:
	var donor: Array[WeakRef] = []
	_weakrefs(_level, donor)
	_weakrefs(_hero, donor)
	var old_cues: Dictionary = {}
	for kind: String in ["draw", "enclose"]:
		old_cues[kind] = _source(kind).get_cue().state()
	var old_palette: Color = ((_tether.get_node("TetherBand") as MeshInstance3D).material_override as StandardMaterial3D).albedo_color
	var supplied: Dictionary = saved.duplicate(true)
	if not _expect(_game.call("load_level_scene", COMPONENT_ROOM), "public Main constructs a genuine fresh component recipient"):
		return false
	_game.call("open_bench")
	if not _bind_component():
		return false
	for _i: int in range(5):
		await process_frame
	var released: bool = true
	for old: WeakRef in donor:
		released = released and old.get_ref() == null
	if not _expect(released and _one_player_scheduler() and paused and _scheduler.get_clock() == 0.0 and _source("draw").state().cycle == 0 and _tether.get("hp") == 60.0, "actual old donor releases before zero-tick recipient prevalidation"):
		return false
	_connect_events()
	var before: Dictionary = _observation()
	if not _expect(_pair_error(saved).is_empty() and before == _observation() and _wire_exact(saved, supplied), "full component prevalidation is pure on actual fresh aliases"):
		return false
	var input_before: Dictionary = _game.call("get_input_observation_state")
	var camera_before: Transform3D = (_game.get("camera") as Camera3D).global_transform
	var events_before: Array[String] = _events.duplicate()
	var bindings: Dictionary = _level.call("scheduler_bindings")
	# No await, source request, callback or fake parent codec between commits.
	var committed: bool = _core.call("stage_quiet_restore", saved.core, saved.hero, bindings, saved.scheduler)
	committed = committed and _hero.restore_state(saved.hero)
	committed = committed and bool(_core.call("apply_staged_target"))
	committed = committed and _scheduler.restore_state(saved.scheduler, bindings)
	committed = committed and bool(_core.call("restore_staged_mechanisms"))
	committed = committed and bool(_core.call("finish_staged_restore"))
	if not _expect(committed, "public ordered Hero/target/full Scheduler/native mechanisms quietly commit actual component pair", str(_core.get("last_snapshot_error")) + "; " + _scheduler.last_snapshot_error):
		return false
	var cues_match: bool = true
	for kind: String in ["draw", "enclose"]:
		cues_match = cues_match and old_cues[kind] == _source(kind).get_cue().state()
	var palette: Color = ((_tether.get_node("TetherBand") as MeshInstance3D).material_override as StandardMaterial3D).albedo_color
	if not _expect(_wire_exact(_component_pair(), saved) and _wire_exact(saved, supplied) and _pair_error(saved).is_empty() and cues_match and palette == old_palette and _tether.get("hp") == 30.0 and _tether.get("phase") == 2 and _source("draw").state().phase == "recovery" and _events == events_before and _game.call("get_input_observation_state") == input_before and (_game.get("camera") as Camera3D).global_transform == camera_before and String(_core.call("presentation_error")).is_empty(), "fresh pair recaptures exact original deadlines/receipt/resources/history/cues/palette without quiet events or input/camera changes"):
		return false
	var stable: Dictionary = _observation()
	for _i: int in range(2):
		await process_frame
	return _expect(stable == _observation() and _wire_exact(_component_pair(), saved), "actual fresh restored pair remains frozen through paused frames")


func _tick() -> bool:
	if paused:
		return _expect(false, "real component cannot tick while paused")
	_barrier.waiting = true
	await _barrier.observed
	var error: String = String(_level.call("runtime_error"))
	var fixed: bool = _tether.global_transform == _fixed_target
	for kind: String in ["draw", "enclose"]:
		fixed = fixed and _source(kind).global_transform == _fixed_sources[kind]
	if not error.is_empty() or not fixed or _hero.hp != _hero_hp or _hero.dead or _hero.equipment.snapshot() != _kit or _events.has("fired_blast") or _events.has("enemy_hit") or _scheduler.get_clock() > MAX_CLOCK_S:
		return _expect(false, "bounded native component ticks preserve actual floor/source/HP/ordinary controls", error + "; " + str(_core.call("state")))
	return true


func _find_script(node: Node, script: Script, result: Array[Node]) -> void:
	if node.get_script() == script:
		result.append(node)
	for child: Node in node.get_children():
		_find_script(child, script, result)


func _one_player_scheduler() -> bool:
	var schedulers: Array[Node] = []
	var players: Array[CinderPlayer] = []
	_find_script(_game, SchedulerScript, schedulers)
	_find_players(_game, players)
	return schedulers.size() == 1 and schedulers[0] == _scheduler and players.size() == 1 and players[0] == _hero


func _find_players(node: Node, result: Array[CinderPlayer]) -> void:
	if node is CinderPlayer:
		result.append(node as CinderPlayer)
	for child: Node in node.get_children():
		_find_players(child, result)


func _finish() -> void:
	await _close()
	await create_timer(0.15, true, false, true).timeout
	print("Garden network API2 component pair: %d checks; failures: %d. Genuine60 to30 and same-Draw cycle replacement; exact leaf triple only; no whole-L4 codec/disk/GUI/route/art or acceptance." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
