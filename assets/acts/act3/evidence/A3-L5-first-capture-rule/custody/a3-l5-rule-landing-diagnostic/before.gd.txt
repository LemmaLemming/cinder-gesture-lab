extends SceneTree
## DRAFT, UNEXECUTED. First sole-Gate/projected physical captured-action join.
## Routed synthetic Godot input, actual physics and public snapshots only.
## No native OS/human, whole-parent Save/Retry, production art or phase2 claim.

const MainScene = preload("res://scenes/main.tscn")
const Player = preload("res://scripts/player.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const RoomPath: String = "res://scenes/acts/act3/a3_l5_crystalman_rule_room.tscn"
const LIMIT_S: float = 40.0

class Barrier extends Node:
	signal observed
	var waiting: bool = false
	var expired: bool = false
	var frames: int = 0
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 3000 # after Player, Playback and sole Gate
	func _physics_process(_delta: float) -> void:
		if waiting and not get_tree().paused:
			waiting = false
			_wake.call_deferred()
	func _process(_delta: float) -> void:
		if waiting:
			frames += 1
			if frames >= 120:
				waiting = false
				expired = true
				_wake.call_deferred()
	func _wake() -> void:
		observed.emit()

var _game: Node
var _room: CinderLevel
var _hero: CinderPlayer
var _scheduler: CinderThreatScheduler
var _gate: CinderReplayCaptureGate
var _barrier: Barrier
var _checks: int = 0
var _failures: int = 0
var _ticks: int = 0
var _hp: float = 0.0
var _kit: Dictionary = {}
var _floor_transform: Transform3D
var _floor_size: Vector3
var _floor_collision: CollisionShape3D
var _events: Array[Dictionary] = []
var _retirements: Array[Dictionary] = []
var _reentrant_rejected: bool = false
var _first_dash: Dictionary = {}
var _first_primary: Dictionary = {}
var _blast_seen: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if await _open():
		await _ordinary_case()
	await _close()
	if _failures == 0 and await _open():
		await _invalid_origin_and_rearm_case()
	await _close()
	print("Crystalman first one-slot rule room: %d checks; failures: %d; actual post-actor ticks: %d. No whole-parent transport/art/phase2 acceptance." % [_checks, _failures, _ticks])
	quit(0 if _failures == 0 else 1)


func _open() -> bool:
	paused = false
	_game = MainScene.instantiate()
	_game.set("level_scene_path", RoomPath)
	root.add_child(_game)
	_hero = _game.get("player") as CinderPlayer
	_room = _game.get("active_level") as CinderLevel
	_scheduler = _room.get("threat_scheduler") as CinderThreatScheduler if _room != null else null
	_gate = _room.get("capture_gate") as CinderReplayCaptureGate if _room != null else null
	if not _expect(_hero != null and _room != null and _scheduler != null and _gate != null and _room.scene_file_path == RoomPath and _room.level_id == "A3-L5" and String(_room.get("last_configuration_error")).is_empty(), "actual MainScene enters one owned CinderLevel with the shared Player/camera/HUD"):
		return false
	_hero.shells = 0 # Explicit initial TEST ONLY zero-ammo supply; reload stays real.
	_hp = _hero.hp
	_kit = _hero.equipment.snapshot()
	_events.clear()
	_retirements.clear()
	_reentrant_rejected = false
	_blast_seen = false
	_hero.fired.connect(_on_fired)
	_gate.sequence_retired.connect(_on_retired)
	_barrier = Barrier.new()
	root.add_child(_barrier)
	var region: Dictionary = _room.call("floor_regions")[0]
	_floor_collision = region.collision
	_floor_transform = _floor_collision.global_transform
	_floor_size = (_floor_collision.shape as BoxShape3D).size
	if not await _wait_phase("recording", 180): return false
	return _expect(_gate.state().capture.armed and _gate.state().capture.max_slots == 1 and _gate.state().capture.allocated == 0 and _room.call("snapshot_state").is_empty() and not _room.last_snapshot_error.is_empty(), "one actual stable Gate arms while unfinished whole-parent transport fails explicitly")


func _ordinary_case() -> bool:
	if not await _record_valid(Vector3.BACK): return false
	if not await _wait_phase("warning", 240): return false
	if not _check_join(1): return false
	if not await _pause_resume("warning"): return false
	var playback: CinderReplayPlayback = _room.get("playback") as CinderReplayPlayback
	playback.event_dispatched.connect(_on_replay_event)
	if not await _wait_locked(): return false
	var state: Dictionary = _room.call("state")
	if not _expect(state.proof.get("accepted", false) and not state.proof.get("uses_blast", true) and not state.proof.get("uses_invulnerability", true), "fresh actual lock proves the entire finite replay and ordinary-primary return"):
		return false
	if not await _follow_proof(state.proof, true): return false
	return await _sever_with_real_primary()


func _record_valid(direction: Vector3) -> bool:
	var sequence_before: int = _latest_sequence()
	var error: String = _swipe(direction)
	if not _expect(error.is_empty(), "shared routed swipe starts actual capture dash", error): return false
	if not await _wait_stable(): return false
	var records: Array[Dictionary] = _hero.get_world_action_records(sequence_before)
	if not _expect(records.size() == 1 and records[0].kind == "dash" and records[0].distance > 0.0 and not records[0].movement_damage, "only actually completed positive harmless dash publishes before capture primary"):
		return false
	_first_dash = Player.encode_world_action_record(records[0], _hero.get_world_action_clock())
	var release: Vector2 = _game.call("get_aim_anchor_normalized")
	error = _tap(Vector3.RIGHT)
	records = _hero.get_world_action_records(sequence_before)
	if not _expect(error.is_empty() and records.size() == 2 and records[1].kind == "primary" and _game.call("get_aim_anchor_normalized") == release and _room.call("state").tether_hits == 0, "actual first routed tap executes immediate primary from exact retained release anchor; closed tether rejects", error):
		return false
	_first_primary = Player.encode_world_action_record(records[1], _hero.get_world_action_clock())
	return true


func _check_join(expected_generation: int) -> bool:
	var state: Dictionary = _room.call("state")
	var sequence: Dictionary = state.sequence
	var receipt: Dictionary = state.join_receipt
	var slot: Dictionary = sequence.capture_snapshot.slots[0]
	var playback: CinderReplayPlayback = _room.get("playback") as CinderReplayPlayback
	var camera_error: String = _game.call("camera_framing_error", _room.call("camera_framing_points"))
	return _expect(state.generation == expected_generation and state.joins == 1 and _retirements.size() == 1 and _reentrant_rejected and receipt.actor_unchanged and receipt.bound_before_tick and receipt.prepared_actor_sha256 == receipt.after_admission_actor_sha256 and receipt.prepared_actor_sha256 == receipt.after_consumption_actor_sha256 and _gate.retirement_state().slot_ids == [1] and not _gate.state().capture.armed, "exact frozen actor survives admission/retirement/outside-callback binding before next tick; one irreversible FIFO receipt") and _expect(_wire_exact(slot.dash, _first_dash) and _wire_exact(slot.primary, _first_primary) and slot.blast.is_empty() and _scheduler.reservations().size() == 1 and state.lease.adapter.kind == "replay" and not state.lease.adapter.locked and playback.state().status == "running" and playback.get_apparition() != null and playback.get_enemy_apparition() == null and playback.get_footprint_projection().get("accepted", false) and camera_error.is_empty(), "original executed world geometry/gear stays exact; actual captured Traveller/projection and full current portrait containment", camera_error)


func _invalid_origin_and_rearm_case() -> bool:
	var before: int = _latest_sequence()
	if not _expect(_swipe(Vector3.BACK).is_empty(), "invalid fixture first executes a real completed dash"): return false
	if not await _wait_stable(): return false
	if not _expect(_swipe(Vector3.RIGHT).is_empty(), "invalid fixture starts a second real routed dash"): return false
	if not await _tick(): return false # Real movement before attack, no pose write.
	var during: Dictionary = _hero.get_threat_response_state()
	var error: String = _tap(Vector3.RIGHT)
	var native: Array[Dictionary] = _hero.get_world_action_records(before)
	if not _expect(error.is_empty() and float(during.motion.dash_left_s) > 0.0 and native.size() == 2 and native.back().kind == "primary" and native.back().world_origin.distance_to(native[0].landing) > 0.01, "actual mid-second-dash primary differs from prior completed landing; no manufactured record", error): return false
	if not await _wait_phase("rejected", 180): return false
	var rejected: Dictionary = _room.call("state")
	if not _expect(rejected.rejections == 1 and rejected.joins == 0 and rejected.last_rejection.contains("origin") and _gate.retirement_state().is_empty() and _scheduler.reservations().is_empty() and _events.is_empty() and _retirements.is_empty() and not _gate.state().capture.armed and _hero.hp == _hp, "invalid whole recording visibly cancels/rearms without a lease, replay, retirement authority or actor reset", rejected.last_rejection): return false
	var original: Dictionary = rejected.last_rejected_capture.slots[0]
	if not _expect(original.primary.world_origin != original.dash.landing, "rejected capture preserves actual differing original geometry rather than snapping it"): return false
	if not await _wait_phase("recording", 180): return false
	if not _expect(_gate.state().capture.generation == 2 and _gate.state().capture.allocated == 0 and _hero.global_position.x > 2.0, "fresh generation rearms at actual post-rejection position; no whole-unit or private pose rewind"): return false
	if not await _record_valid(Vector3.LEFT): return false
	if not await _wait_phase("warning", 240) or not _check_join(2): return false
	var playback: CinderReplayPlayback = _room.get("playback") as CinderReplayPlayback
	playback.event_dispatched.connect(_on_replay_event)
	if not await _wait_locked(): return false
	if not await _follow_proof(_room.call("state").proof, false): return false
	return await _sever_with_real_primary()


func _follow_proof(proof: Dictionary, pause_active: bool) -> bool:
	var moved: bool = false
	for segment: Dictionary in proof.path:
		if segment.kind not in ["first_escape_dash", "tether_positioning_dash"]: continue
		if not await _until(float(segment.start_s)): return false
		if not _expect(_hero.global_position.distance_to(segment.from) < 0.02, "real actor begins the proved ordinary dash at its actual source", str(_hero.global_position)): return false
		var error: String = _swipe((segment.to - segment.from).normalized())
		if not _expect(error.is_empty(), "real routed ordinary dash follows complete proved response", error): return false
		if not await _until(float(segment.end_s)): return false
		if not _expect(_hero.global_position.distance_to(segment.to) < 0.02 and _hero.hp == _hp, "actual completed response reaches clear landing without absorbing replay damage"): return false
		if not moved and pause_active:
			var active_from: float = float(_room.call("state").lease.active_from_s)
			if not await _until(active_from + 0.03): return false
			if not await _pause_resume("active"): return false
		moved = true
	if not await _until(float(proof.primary_time_s)): return false
	return _expect(moved and _hero.global_position.distance_to(proof.attack_position) < 0.02 and _hero.get_threat_response_state().primary_cooldown_left_s == 0.0 and _room.call("state").phase == "exposed", "complete ordinary response reaches low tether inside actual finite recovery")


func _sever_with_real_primary() -> bool:
	var before: int = _latest_sequence()
	var tether: Node3D = _room.get("tether") as Node3D
	var direction: Vector3 = tether.global_position - _hero.global_position
	direction.y = 0.0
	var error: String = _tap(direction.normalized() if not direction.is_zero_approx() else Vector3.RIGHT)
	var records: Array[Dictionary] = _hero.get_world_action_records(before)
	if not _expect(error.is_empty() and records.size() == 1 and records[0].kind == "primary" and records[0].hits == 0 and _room.call("state").tether_hits == 1 and _room.call("state").cleared and not _blast_seen, "actual ordinary primary severs low environment tether once without fake enemy hits/blast/resource credit", error): return false
	if not await _wait_phase("spent", 30): return false
	var state: Dictionary = _room.call("state")
	var original_event: Dictionary = state.sequence.capture_snapshot.slots[0].primary
	if not _expect(_events.size() == 1 and _events[0].kind == "primary" and _events[0].record_sequence == original_event.sequence and _retirements.size() == 1 and _scheduler.reservations().is_empty() and not tether.is_in_group("environment_attack_targets") and _hero.hp == _hp and _hero.equipment.snapshot() == _kit, "one finite exact replay event; spent target and live lease retire without capture recursion"): return false
	var history: int = _latest_sequence()
	for _i: int in range(30):
		if not await _tick(): return false
	return _expect(_events.size() == 1 and _retirements.size() == 1 and _latest_sequence() == history and _room.call("state").joins == 1 and _room.call("state").tether_hits == 1, "later native ticks cannot replay, recapture, hit or grant completion again")


func _pause_resume(label: String) -> bool:
	_game.call("open_bench")
	await process_frame
	var playback: CinderReplayPlayback = _room.get("playback") as CinderReplayPlayback
	var bindings: Dictionary = _room.call("scheduler_bindings")
	var schedule: Dictionary = _scheduler.snapshot_state(bindings)
	var before: Dictionary = {"player": _hero.snapshot_state(), "gate": _gate.snapshot_state(), "scheduler": schedule, "playback": playback.snapshot_state(schedule, bindings)}
	var input_before: PackedByteArray = var_to_bytes(_game.call("get_input_observation_state"))
	var camera: Camera3D = _game.get("camera") as Camera3D
	var camera_before: PackedByteArray = var_to_bytes(camera.global_transform)
	var event_count: int = _events.size()
	if not _expect(paused and not before.player.is_empty() and not before.gate.is_empty() and not before.scheduler.is_empty() and not before.playback.is_empty(), "public Pause freezes actual leaf aggregate during " + label): return false
	for _i: int in range(4): await process_frame
	schedule = _scheduler.snapshot_state(bindings)
	var after: Dictionary = {"player": _hero.snapshot_state(), "gate": _gate.snapshot_state(), "scheduler": schedule, "playback": playback.snapshot_state(schedule, bindings)}
	if not _expect(_wire_exact(before, after) and input_before == var_to_bytes(_game.call("get_input_observation_state")) and camera_before == var_to_bytes(camera.global_transform) and _events.size() == event_count, "real paused actor/capture/replay clocks, geometry, opportunities and input remain exact during " + label): return false
	var button: Button = _find_resume(_game.get("hud") as Node)
	if not _expect(button != null and button.is_visible_in_tree(), "actual Resume GUI control is visible"): return false
	var sequence_before: int = _latest_sequence()
	var actor_clock: float = _hero.get_world_action_clock()
	var point: Vector2 = button.get_global_rect().get_center()
	_touch(point, 91)
	return _expect(not paused and _latest_sequence() == sequence_before and _hero.get_world_action_clock() == actor_clock and input_before == var_to_bytes(_game.call("get_input_observation_state")) and _events.size() == event_count, "actual GUI Resume tap is consumed without attack/capture/tick during " + label)


func _find_resume(node: Node) -> Button:
	if node is Button and (node as Button).text.contains("RESUME"): return node as Button
	for child: Node in node.get_children():
		var found: Button = _find_resume(child)
		if found != null: return found
	return null


func _on_retired(sequence: Dictionary, retirement: Dictionary) -> void:
	_retirements.append(retirement.duplicate(true))
	var duplicate: Dictionary = _gate.consume_sequence(sequence)
	_reentrant_rejected = not duplicate.get("accepted", false) and _gate.prepare_sequence("callback-duplicate", {}).is_empty()


func _on_replay_event(event: Dictionary, _receipt: Dictionary) -> void:
	_events.append(event.duplicate(true))


func _on_fired(kind: String) -> void:
	if kind == "blast": _blast_seen = true


func _wait_phase(wanted: String, limit: int) -> bool:
	for _i: int in range(limit):
		if String(_room.call("state").phase) == wanted: return true
		if not await _tick(): return false
	return _expect(false, "bounded native phase reaches " + wanted, str(_room.call("state")))


func _wait_stable() -> bool:
	for _i: int in range(180):
		var response: Dictionary = _hero.get_threat_response_state()
		if response.stable and float(response.dash_cooldown_left_s) == 0.0: return true
		if not await _tick(): return false
	return _expect(false, "actual dash completes/cooldown settles without clock or pose writes")


func _wait_locked() -> bool:
	for _i: int in range(180):
		if _room.call("state").locked: return true
		if not await _tick(): return false
	return _expect(false, "actual due lock reproves before physical delivery", str(_room.call("state")))


func _until(target: float) -> bool:
	if target > LIMIT_S: return _expect(false, "proof deadline fits bounded native room", str(target))
	for _i: int in range(1200):
		if _scheduler.get_clock() >= target: return true
		if not await _tick(): return false
	return _expect(false, "actual Scheduler reaches proof deadline", str(target))


func _tick() -> bool:
	if paused or not is_instance_valid(_barrier): return _expect(false, "native tick has an actual live unpaused handle")
	_barrier.waiting = true
	_barrier.expired = false
	_barrier.frames = 0
	await _barrier.observed
	_ticks += 1
	var state: Dictionary = _room.call("state")
	var fixed: bool = _floor_collision.global_transform == _floor_transform and (_floor_collision.shape as BoxShape3D).size == _floor_size
	if _barrier.expired or paused or not String(state.configuration_error).is_empty() or _hero.dead or _hero.hp != _hp or _hero.equipment.snapshot() != _kit or not fixed or _blast_seen or _scheduler.get_clock() > LIMIT_S:
		return _expect(false, "actual post-actor room tick keeps Player/kit/permanent floor and bounded scope", str(state))
	return true


func _latest_sequence() -> int:
	var records: Array[Dictionary] = _hero.get_world_action_records()
	return int(records.back().sequence) if not records.is_empty() else 0


func _swipe(direction: Vector3) -> String:
	if direction.is_zero_approx(): return "No planar swipe direction"
	var size: Vector2 = root.get_visible_rect().size
	var start: Vector2 = size * Vector2(0.5, 0.60)
	var finish: Vector2 = start + _screen_direction(direction) * size.x * 0.22
	if not root.get_visible_rect().has_point(finish) or finish.y < 100.0: return "Release outside actual input region"
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = start
	down.pressed = true
	root.push_input(down, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = finish
	drag.relative = finish - start
	root.push_input(drag, true)
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = finish
	up.pressed = false
	root.push_input(up, true)
	return "" if float(_hero.get_threat_response_state().motion.dash_left_s) > 0.0 and (_game.call("get_aim_anchor_normalized") as Vector2).distance_to(finish / size) < 0.000001 else "Shared router did not start dash/store final release"


func _tap(direction: Vector3) -> String:
	var point: Vector2 = _game.call("get_aim_anchor") + _screen_direction(direction) * 60.0
	if not root.get_visible_rect().has_point(point) or point.y < 100.0: return "Tap outside actual input region"
	_touch(point, 0)
	return ""


func _touch(point: Vector2, index: int) -> void:
	var down := InputEventScreenTouch.new()
	down.index = index
	down.position = point
	down.pressed = true
	root.push_input(down, true)
	var up := InputEventScreenTouch.new()
	up.index = index
	up.position = point
	up.pressed = false
	root.push_input(up, true)


func _screen_direction(direction: Vector3) -> Vector2:
	var camera: Camera3D = _game.get("camera") as Camera3D
	var right: Vector3 = camera.global_basis.x
	var down: Vector3 = camera.global_basis.z
	right.y = 0.0
	down.y = 0.0
	return Vector2(direction.dot(right.normalized()), direction.dot(down.normalized())).normalized()


func _close() -> void:
	var refs: Array[WeakRef] = []
	for node: Node in [_game, _room, _hero, _scheduler, _gate, _barrier]:
		if is_instance_valid(node): refs.append(weakref(node))
	if is_instance_valid(_room):
		var owner: Node = _room.get("playback") as Node
		if is_instance_valid(owner):
			refs.append(weakref(owner))
			for cue: Node in owner.call("get_cues"): refs.append(weakref(cue))
		_room.exit_level()
	if is_instance_valid(_barrier):
		_barrier.waiting = false
		_barrier.queue_free()
	if is_instance_valid(_game): _game.queue_free()
	_game = null
	_room = null
	_hero = null
	_scheduler = null
	_gate = null
	_barrier = null
	_floor_collision = null
	paused = false
	for _i: int in range(5): await process_frame
	if not refs.is_empty():
		_expect(refs.all(func(ref: WeakRef) -> bool: return ref.get_ref() == null) and get_nodes_in_group("environment_attack_targets").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal CinderLevel/Main disposal retires actor, sole Gate callback, lease owner, cues and tether groups")


static func _wire_exact(left: Variant, right: Variant) -> bool:
	var wire: String = Exact.stringify(left)
	return not wire.is_empty() and wire == Exact.stringify(right)


func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	if ok: print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok
