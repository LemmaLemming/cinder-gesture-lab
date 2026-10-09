extends SceneTree
## Actual MainScene shore scaffold: one familiar living Stalker, routed
## viewport gestures, exact quiet fresh reconstruction and no progression.
## Automated engine input is not native OS input, human balance, Echo/replay,
## full Mirror Sea completion, campaign registration or art acceptance.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const ExactJson: GDScript = preload("res://scripts/campaign/exact_json.gd")
const Codec: GDScript = preload("res://scripts/campaign/snapshot_codec.gd")
const Geometry: GDScript = preload("res://scripts/combat/threat_geometry.gd")
const ShorePath: String = "res://scenes/acts/act3/a3_l3_shore_preview.tscn"
const CapturePath: String = "res://.cinder/mirror-shore-preview-portraits"
const SourceId: String = "shore-stalker"
const EncounterId: String = "A3-L3/shore-preview"
const FloorRect: Rect2 = Rect2(-7.0, -11.0, 14.0, 22.0)
const PointTolerance: float = 0.005
const TimeEpsilon: float = 0.000001
const CaseBudgetS: float = 30.0
const WarningBudgetS: float = 4.0
const Deadlines: Array[String] = ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]


## TEST ONLY observation; never advances, resumes or retimes game actors.
class PostActorBarrier:
	extends Node
	signal observed
	var waiting: bool = false
	var _pause_wake_queued: bool = false
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 1000
	func _physics_process(_delta: float) -> void:
		_wake()
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PAUSED and waiting and not _pause_wake_queued:
			_pause_wake_queued = true
			_wake_paused.call_deferred()
	func _wake_paused() -> void:
		_pause_wake_queued = false
		if is_inside_tree() and not is_queued_for_deletion() and get_tree().paused:
			_wake()
	func _wake() -> void:
		if waiting:
			waiting = false
			observed.emit()

var _game: Node
var _hero: CinderPlayer
var _level: CinderLevel
var _source: CharacterBody3D
var _scheduler: CinderThreatScheduler
var _floor: StaticBody3D
var _barrier: PostActorBarrier
var _checks: int = 0
var _failures: int = 0
var _capture_portraits: bool = false
var _captured: Dictionary = {}
var _events: Dictionary = {}
var _actions: Array[Dictionary] = []
var _kit: Dictionary = {}
var _stats: Dictionary = {}
var _hp_before: float = 0.0
var _source_hp: float = 36.0
var _deadline: float = CaseBudgetS
var _record: Dictionary = {}
var _phases: Dictionary = {}
var _active_travel: float = 0.0
var _primary_count: int = 0
var _dash_count: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if not _expect(arguments.is_empty() or arguments == PackedStringArray(["--capture-portraits"]), "only the default or optional portrait selector is supported"):
		await _finish()
		return
	_capture_portraits = not arguments.is_empty()
	if not _expect(not _capture_portraits or DisplayServer.get_name() != "headless", "portrait capture requires a graphical native viewport") or not await _open(false):
		await _finish()
		return
	var error: String = ""
	for _i: int in range(8):
		error = await _tick()
		if not error.is_empty():
			break
	if not _expect(error.is_empty() and _hero.is_on_floor() and _source.is_on_floor() and _floor_hit(_hero.global_position) and _floor_hit(_source.global_position), "actual traveller and living capsule settle on the firm shore floor", error):
		await _finish()
		return
	if not _expect(_scheduler.reservations().is_empty() and int((_source.call("state") as Dictionary).cycle) == 0, "arrival capture precedes the first genuine source lease"):
		await _finish()
		return
	error = await _pause_and_restore_arrival()
	if not _expect(error.is_empty(), "exact paused arrival quietly reconstructs a fresh actual Hero/source/Scheduler unit", error):
		await _finish()
		return
	_game.call("resume_lab")
	_deadline = _scheduler.get_clock() + CaseBudgetS
	var previous_cycle: int = 0
	for _attempt: int in range(4):
		var warning: Dictionary = await _next_warning(previous_cycle)
		if warning.is_empty():
			error = "no next actual admitted warning within the four-second wait"
			break
		previous_cycle = int(warning.cycle)
		error = await _follow_proof(warning)
		if not _expect(error.is_empty(), "cycle %d follows its actual live proof through routed dash and one ordinary tap" % previous_cycle, error):
			break
		if bool((_source.call("state") as Dictionary).dead):
			break
	if error.is_empty():
		error = await _clear_error()
	if _failures == 0:
		_expect(error.is_empty(), "two real ordinary-primary hits clear the familiar source without blast, damage, reward or campaign progress", error)
	if _failures == 0 and _capture_portraits:
		_expect(_captured.size() == 6, "six portraits record actual quiet/warning/lock/moving-active/recovery/clear states")
	await _finish()


func _open(quiet: bool) -> bool:
	paused = false
	_game = MainScene.instantiate()
	_game.set("level_scene_path", ShorePath)
	root.add_child(_game)
	_barrier = PostActorBarrier.new()
	root.add_child(_barrier)
	_hero = _game.get("player") as CinderPlayer
	_level = _game.get("active_level") as CinderLevel
	_source = _level.get("stalker") as CharacterBody3D if _level != null else null
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler if _level != null else null
	var scenery: Node = _level.get("scenery") as Node if _level != null else null
	_floor = scenery.get("floor_body") as StaticBody3D if scenery != null else null
	if not _expect(_hero != null and _level != null and _source != null and _scheduler != null and _floor != null and _level.scene_file_path == ShorePath and _level.level_id == "A3-L3" and _level.contract_error().is_empty(), "real MainScene loads the owned shore preview and actual native bindings"):
		return false
	if not _expect(String(_level.get("last_configuration_error")).is_empty() and _hero.presentation_id == "act3_traveller" and _hero.global_position == _level.spawn_position() and _scheduler.get_clock() == 0.0 and _hero.get_world_action_clock() == 0.0, "fresh shore uses the shared Act 3 traveller at its real zero-tick spawn"):
		return false
	var response: Dictionary = _level.call("combat_response")
	var bindings: Dictionary = _level.call("scheduler_bindings")
	var solid: CollisionShape3D = _floor.get_node_or_null("Solid") as CollisionShape3D
	if not _expect(response.get("actor") == _hero and response.get("world_root") == _game.get("world") and bindings.get("owners", {}).get(SourceId) == _source and bindings.get("floors", {}).get("shore-floor", {}).get("collision") == solid and response.floor_regions.size() == 1 and response.floor_regions[0].safe_rect == FloorRect and solid != null and solid.shape is BoxShape3D and (solid.shape as BoxShape3D).size == Vector3(14.0, 1.0, 22.0), "accepted response binds actual Hero/World, real source and continuous 14-by-22 firm floor"):
		return false
	_game.call("open_bench")
	if not _expect(paused, "public MainScene pause establishes the quiet setup boundary"):
		return false
	if not quiet:
		_hero.shells = 0 # Disclosed public TEST ONLY initial resource condition.
		_kit = _hero.equipment.snapshot()
		_stats = _hero.equipment.resolved_stats()
		_hp_before = _hero.hp
		_source_hp = float((_source.call("state") as Dictionary).hp)
		if not _expect(_source_hp == 36.0 and float(_stats.primary_damage) == 20.0 and _hero.shells == 0, "current starter baseline begins with 36 source HP and zero blast ammo"):
			return false
	_connect_observers()
	if not quiet:
		_game.call("resume_lab")
	return true


func _connect_observers() -> void:
	_source.connect("state_changed", func(_state: Dictionary) -> void: _event("source_phase"))
	_source.connect("hit_resolved", func(_result: Dictionary) -> void: _event("source_hit"))
	_source.connect("died", func(_where: Vector3) -> void: _event("source_death"))
	var cue: CinderThreatCue = _source.call("get_cue") as CinderThreatCue
	cue.state_changed.connect(func(_state: Dictionary) -> void: _event("cue"))
	_scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _event("cancel"))
	_hero.world_action_executed.connect(func(record: Dictionary) -> void: _actions.append(record.duplicate(true)))
	_hero.fired.connect(func(kind: String) -> void: _event("fired_" + kind))
	_hero.died.connect(func() -> void: _event("hero_death"))
	_hero.equipment_changed.connect(func(_id: String) -> void: _event("equipment"))
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _event("completion"))
	_level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _boundary: String) -> void: _event("checkpoint"))
	_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _event("exit"))


func _pause_and_restore_arrival() -> String:
	_game.call("request_pause_deferred")
	await process_frame
	await process_frame
	var saved: Dictionary = _pair()
	if not paused or saved.hero.is_empty() or saved.level.is_empty():
		return "complete deferred arrival capture rejected: " + _hero.last_snapshot_error + "; " + _level.last_snapshot_error
	if saved.level.local_snapshot_version != 1 or saved.level.local.keys().size() != 2 or saved.level.local.stalker.api_revision != "act3-stalker-snapshot-3" or saved.level.local.stalker.schema_version != 3 or saved.level.local.scheduler.encounter_id != EncounterId or float(saved.hero.world_actions.clock_s) != float(saved.level.local.scheduler.clock_s):
		return "captured arrival does not preserve the actual source3/local1/preview encounter and same native clocks"
	var encoded: String = ExactJson.stringify(saved)
	var decoded: Dictionary = ExactJson.parse(encoded)
	if not _expect(not encoded.is_empty() and decoded.get("accepted", false) and decoded.get("value") is Dictionary and _exact(saved, decoded.value), "published ExactJson preserves native types and all binary64 source/player clocks", String(decoded.get("reason", ""))):
		return "exact transport rejected"
	saved = decoded.value
	var input: Dictionary = saved.duplicate(true)
	var before: Dictionary = _observation()
	if not _hero.snapshot_error(saved.hero).is_empty() or not _level.snapshot_error_with_player(saved.level, saved.hero).is_empty() or not _exact(before, _observation()) or not _exact(input, saved):
		return "complete paused prevalidation rejected or mutated input/runtime"
	var forged: Dictionary = saved.duplicate(true)
	forged.level.local_snapshot_version = 2
	if not _reject(forged, "wrong shore local version"):
		return "local version atomic rejection failed"
	forged = saved.duplicate(true)
	forged.level.local.stalker.schema_version = 2
	if not _reject(forged, "obsolete source schema"):
		return "source schema atomic rejection failed"
	forged = saved.duplicate(true)
	forged.level.local.stalker.clock_s = float(forged.level.local.stalker.clock_s) + 0.00000001
	if not _reject(forged, "source/Scheduler exact clock mismatch"):
		return "paired clock atomic rejection failed"
	forged = saved.duplicate(true)
	forged.level.local.stalker.previous.hero_position[0] = float(forged.level.local.stalker.previous.hero_position[0]) + 0.25
	if not _reject(forged, "same-clock copied contact sample crossed with another Hero point"):
		return "paired saved Hero sample atomic rejection failed"
	forged = saved.duplicate(true)
	forged.level.local["echo"] = {}
	if not _reject(forged, "extra unsupported local source"):
		return "closed unit atomic rejection failed"
	var error: String = await _capture("01-quiet-arrival")
	if not error.is_empty():
		return error
	var old_hero: WeakRef = weakref(_hero)
	var old_level: WeakRef = weakref(_level)
	if not await _close() or not _expect(old_hero.get_ref() == null and old_level.get_ref() == null, "original shore world retires before fresh quiet reconstruction"):
		return "original world retained"
	if not await _open(true):
		return "fresh shore failed to open"
	await process_frame
	await process_frame
	before = _observation()
	if not _hero.snapshot_error(saved.hero).is_empty() or not _level.snapshot_error_with_player(saved.level, saved.hero).is_empty() or not _exact(before, _observation()):
		return "fresh complete saved-Hero prevalidation rejected or changed the zero-tick unit"
	var events: Dictionary = _events.duplicate(true)
	# Exact ordered commit with no yield: actual Hero, owned source, Scheduler,
	# then quiet native cue/art and scenery alignment. No new proof/admission.
	if not _hero.restore_state(saved.hero) or not _level.restore_state(saved.level):
		return "ordered fresh apply rejected: " + _hero.last_snapshot_error + "; " + _level.last_snapshot_error
	if not _exact(saved, _pair()) or not _exact(events, _events) or not _actions.is_empty() or _hero.shells != 0:
		return "quiet fresh reconstruction changed exact pose/resources/clocks/history or emitted an event"
	before = _observation()
	await process_frame
	await process_frame
	if not _exact(before, _observation()) or not _scheduler.reservations().is_empty():
		return "paused reconstructed arrival advanced or manufactured a lease"
	_expect(true, "fresh paused source/player unit preserves exact arrival and zero ammo silently across deferred barriers")
	return ""


func _reject(forged: Dictionary, label: String) -> bool:
	var before: Dictionary = _observation()
	var input: Dictionary = forged.duplicate(true)
	var error: String = _level.snapshot_error_with_player(forged.level, forged.hero)
	var accepted: bool = _level.restore_state(forged.level)
	return _expect(not error.is_empty() and not accepted and _exact(input, forged) and _exact(before, _observation()), "pure and restore paths reject " + label + " atomically", error)


func _pair() -> Dictionary:
	return {"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}


func _observation() -> Dictionary:
	var body: CollisionShape3D = _source.get_node_or_null("BodyCollision") as CollisionShape3D
	var camera: Camera3D = _game.get("camera") as Camera3D
	return {"pair": _pair(), "hero_transform": _hero.global_transform, "hero_velocity": _hero.velocity, "source_transform": _source.global_transform, "position": _source.global_position, "velocity": _source.velocity, "layer": _source.collision_layer, "mask": _source.collision_mask, "body_disabled": body.disabled, "enemies": _source.is_in_group("enemies"), "cue": (_source.call("get_cue") as CinderThreatCue).state(), "reservations": _scheduler.reservations(), "camera": camera.global_transform, "anchor": _game.call("get_aim_anchor_normalized"), "events": _events.duplicate(true), "actions": _actions.duplicate(true)}


func _next_warning(previous_cycle: int) -> Dictionary:
	var deadline: float = minf(_deadline, _scheduler.get_clock() + WarningBudgetS)
	for _i: int in range(_frame_limit(WarningBudgetS)):
		var state: Dictionary = _source.call("state")
		if not String(state.reservation_id).is_empty():
			return state if state.phase == "warning" and int(state.cycle) == previous_cycle + 1 else {}
		if _scheduler.get_clock() > deadline or state.dead or state.phase not in ["idle", "approach"]:
			break
		var error: String = await _tick()
		if not error.is_empty():
			_expect(false, "safe bounded approach remains valid before its next warning", error)
			return {}
	return {}


func _follow_proof(state: Dictionary) -> String:
	var record: Dictionary = _scheduler.reservation_state(String(state.reservation_id))
	var proof: Dictionary = state.get("proof", {})
	if record.is_empty() or record.source_instance_id != _source.get_instance_id() or record.state != "warning" or record.get("armed") != true or record.get("adapter", {}).get("kind") != "lunge" or record.get("geometry", {}).get("kind") != "lane" or proof.get("accepted") != true or proof.get("uses_blast") != false or proof.get("uses_invulnerability") != false or not proof.get("path") is Array:
		return "actual native owner lacks its armed physical-lunge/no-ammo/no-immunity proof"
	var path: Array[Dictionary] = []
	var previous: Dictionary = {}
	var counts: Dictionary = {"escape_dash": 0, "ordinary_primary": 0, "positioning_dash": 0}
	for item: Variant in proof.path:
		if not item is Dictionary or item.get("kind") not in ["recognition_and_ready", "escape_dash", "recovery_wait", "positioning_dash", "primary_ready", "ordinary_primary"] or not Geometry.finite_vector(item.get("from")) or not Geometry.finite_vector(item.get("to")) or not Geometry.finite_number(item.get("start_s")) or not Geometry.finite_number(item.get("end_s")):
			return "actual selected response contains a malformed native path"
		if float(item.end_s) < float(item.start_s) or float(item.start_s) < float(record.start_s) - TimeEpsilon or float(item.end_s) > float(record.recovery_until_s) or (not previous.is_empty() and (absf(float(previous.end_s) - float(item.start_s)) > TimeEpsilon or (previous.to as Vector3).distance_to(item.from) > PointTolerance)):
			return "actual selected response is discontinuous or outside its held deadlines"
		if counts.has(item.kind):
			counts[item.kind] += 1
		path.append(item)
		previous = item
	if path.is_empty() or path.size() > 6 or counts.escape_dash != 1 or counts.ordinary_primary != 1 or counts.positioning_dash > 1 or (path[0].from as Vector3).distance_to(_hero.global_position) > PointTolerance or float(proof.primary_time_s) <= float(record.active_until_s) or float(proof.response_complete_s) > float(record.recovery_until_s) or Geometry.timed_path_hits(record.geometry, path, float(record.active_from_s), float(record.active_until_s), CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN):
		return "actual witness lacks its finite safe escape and reachable ordinary recovery opening"
	_record = record.duplicate(true)
	_phases = {"warning": true}
	_active_travel = 0.0
	var error: String = await _capture("02-warning")
	if not error.is_empty():
		return error
	print("ACCEPTED: cycle=%d source=%s actual_path=%s" % [state.cycle, _source.global_position, path])
	for segment: Dictionary in path:
		if segment.kind in ["escape_dash", "positioning_dash"]:
			error = await _dash(segment)
		elif segment.kind == "ordinary_primary":
			error = await _primary(segment, proof)
		else:
			error = await _hold(segment)
		if not error.is_empty():
			return String(segment.kind) + ": " + error
	return ""


func _hold(segment: Dictionary) -> String:
	if segment.from != segment.to or _hero.global_position.distance_to(segment.from) > PointTolerance:
		return "actual stationary response begins away from its published point"
	for _i: int in range(_frame_limit(CaseBudgetS)):
		if _scheduler.get_clock() >= float(segment.end_s):
			return ""
		var error: String = await _tick()
		if not error.is_empty():
			return error
		if _hero.global_position.distance_to(segment.from) > PointTolerance:
			return "actual traveller drifted during the held response"
	return "stationary segment exceeded its finite frame budget"


func _dash(segment: Dictionary) -> String:
	var error: String = await _at_time(float(segment.start_s))
	if not error.is_empty():
		return error
	var response: Dictionary = _hero.get_threat_response_state()
	if _hero.global_position.distance_to(segment.from) > PointTolerance or float(response.dash_cooldown_left_s) != 0.0 or float(response.motion.dash_left_s) != 0.0:
		return "displayed dash is not at its actual ready origin"
	var direction: Vector3 = segment.to - segment.from
	direction.y = 0.0
	var sequence: int = _last_sequence()
	var started: float = _scheduler.get_clock()
	error = _swipe(direction.normalized())
	if not error.is_empty():
		return error
	var actions: Array[Dictionary] = []
	for _i: int in range(_frame_limit(float(_stats.dash_duration) + 0.25)):
		actions = _hero.get_world_action_records(sequence)
		if not actions.is_empty():
			break
		error = await _tick()
		if not error.is_empty():
			return error
	if actions.size() != 1:
		return "routed swipe failed to publish exactly one completed world dash"
	var action: Dictionary = actions[0]
	if action.get("kind") != "dash" or action.get("blocked") != false or action.get("collision_shortened") != false or not _exact(action.equipment_ids, _kit) or not _exact(action.resolved_stats, _stats) or (action.world_origin as Vector3).distance_to(segment.from) > PointTolerance or (action.landing as Vector3).distance_to(segment.to) > PointTolerance or _hero.global_position.distance_to(segment.to) > PointTolerance or absf(float(action.distance) - float(_stats.dash_distance)) > PointTolerance:
		return "routed ordinary dash differs from its real kit/origin/landing/distance"
	if absf(float(action.started_at_s) - started) > TimeEpsilon or absf(float(action.completed_at_s) - started - float(_stats.dash_duration)) > _tick_s() + TimeEpsilon or float(action.completed_at_s) > float(segment.end_s) + 2.0 * _tick_s() + TimeEpsilon:
		return "routed dash missed its native fixed-step action/completion bounds"
	for sample: Dictionary in action.path:
		if not _floor_hit(sample.position):
			return "actual completed dash samples left the firm shore floor"
	_dash_count += 1
	return ""


func _primary(segment: Dictionary, proof: Dictionary) -> String:
	var error: String = await _at_time(float(proof.primary_time_s))
	if not error.is_empty():
		return error
	var state: Dictionary = _source.call("state")
	var response: Dictionary = _hero.get_threat_response_state()
	if state.phase != "recovery" or state.dead or _hero.global_position.distance_to(proof.attack_position) > PointTolerance or segment.from != segment.to or (segment.from as Vector3).distance_to(proof.attack_position) > PointTolerance or response.stable != true or float(response.primary_cooldown_left_s) != 0.0:
		return "actual primary lacks its stationary reachable recovery opening"
	for phase: String in ["warning", "lock", "active", "recovery"]:
		if not _phases.has(phase):
			return "actual source never displayed " + phase
	if _active_travel <= 0.1 or _source.global_position.distance_to(_record.adapter.planned_endpoint) > PointTolerance or not _source.velocity.is_zero_approx():
		return "actual lunge did not move then stop at its held physical endpoint"
	var sequence: int = _last_sequence()
	var before: float = float(state.hp)
	var started: float = _scheduler.get_clock()
	var toward: Vector3 = _source.global_position - _hero.global_position
	toward.y = 0.0
	error = _tap(toward.normalized())
	if not error.is_empty():
		return error
	var actions: Array[Dictionary] = _hero.get_world_action_records(sequence)
	var after: Dictionary = _source.call("state")
	if actions.size() != 1 or actions[0].get("kind") != "primary" or int(actions[0].get("hits", 0)) != 1 or float(actions[0].get("damage", 0.0)) != float(_stats.primary_damage) or not _exact(actions[0].equipment_ids, _kit) or float(after.hp) != maxf(before - float(_stats.primary_damage), 0.0) or absf(float(actions[0].started_at_s) - started) > TimeEpsilon:
		return "actual first routed tap did not apply precisely one ordinary-primary hit"
	if not String(after.reservation_id).is_empty() or not _scheduler.reservations().is_empty():
		return "real ordinary primary failed to cancel its actual source lease"
	_record.clear() # Bookkeeping only, after the actual shared primary cancels.
	_source_hp = float(after.hp)
	_primary_count += 1
	print("PRIMARY: cycle=%d actual=%.9f hp=%s->%s" % [state.cycle, started, before, after.hp])
	return await _hold(segment)


func _swipe(direction: Vector3) -> String:
	if direction.is_zero_approx():
		return "routed swipe has no actual planar direction"
	var size: Vector2 = root.get_visible_rect().size
	var start: Vector2 = size * Vector2(0.5, 0.60)
	var finish: Vector2 = start + _screen_direction(direction) * size.x * 0.22
	if not root.get_visible_rect().has_point(finish) or finish.y < 100.0:
		return "routed release cannot fit the actual viewport input region"
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = start
	root.push_input(press, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = finish
	drag.relative = finish - start
	root.push_input(drag, true)
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.position = finish
	root.push_input(release, true)
	var motion: Dictionary = _hero.get_threat_response_state().motion
	return "" if float(motion.dash_left_s) > 0.0 and (_game.call("get_aim_anchor_normalized") as Vector2).distance_to(finish / size) < 0.000001 else "shared router did not begin the real dash and retain its exact final release anchor"


func _tap(direction: Vector3) -> String:
	if direction.is_zero_approx():
		return "actual primary target cannot define a meaningful planar direction"
	# The shared game aims from the last swipe's final release point, not a
	# projected world point or a private player facing/aim substitute.
	var point: Vector2 = _game.call("get_aim_anchor") + _screen_direction(direction) * 60.0
	if not root.get_visible_rect().has_point(point) or point.y < 100.0:
		return "ordinary tap cannot fit the actual release-anchor input region"
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = point
	root.push_input(press, true)
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.position = point
	root.push_input(release, true)
	return ""


func _screen_direction(direction: Vector3) -> Vector2:
	var camera: Camera3D = _game.get("camera") as Camera3D
	var right: Vector3 = camera.global_basis.x
	var down: Vector3 = camera.global_basis.z
	right.y = 0.0
	down.y = 0.0
	return Vector2(direction.dot(right.normalized()), direction.dot(down.normalized())).normalized()


func _at_time(target: float) -> String:
	if not is_finite(target) or target > _deadline:
		return "actual published action deadline exceeds the finite case budget"
	for _i: int in range(_frame_limit(CaseBudgetS)):
		var now: float = _scheduler.get_clock()
		if now >= target:
			return "" if now - target <= _tick_s() + TimeEpsilon else "actual action missed its first available fixed tick"
		var error: String = await _tick()
		if not error.is_empty():
			return error
	return "actual action deadline exceeded its finite observation budget"


func _tick() -> String:
	if not is_instance_valid(_barrier) or _barrier.process_mode != Node.PROCESS_MODE_PAUSABLE or _barrier.process_physics_priority != 1000:
		return "TEST ONLY post-actor barrier is missing or incorrectly scheduled"
	for actor: Node in [_hero, _scheduler, _source, _level]:
		if not is_instance_valid(actor) or actor.process_physics_priority >= _barrier.process_physics_priority:
			return "actual actor binding is missing or does not precede observation"
	if paused:
		var clock: float = _scheduler.get_clock()
		var hero_clock: float = _hero.get_world_action_clock()
		await process_frame
		if clock != _scheduler.get_clock() or hero_clock != _hero.get_world_action_clock():
			return "paused observation advanced an actual actor clock"
	else:
		_barrier.waiting = true
		await _barrier.observed
	var error: String = _live_error()
	if not error.is_empty():
		return error
	if _capture_portraits and not _record.is_empty():
		var phase: String = String((_source.call("state") as Dictionary).phase)
		if phase in ["lock", "active", "recovery"] and (phase != "active" or _active_travel > 0.1):
			return await _capture({"lock": "03-lock", "active": "04-moving-active", "recovery": "05-recovery"}[phase])
	return ""


func _live_error() -> String:
	if _scheduler.get_clock() > _deadline or _hero.hp != _hp_before or _hero.dead or int(_events.get("source_hit", 0)) != 0 or int(_events.get("hero_death", 0)) != 0:
		return "actual fixture exceeded thirty seconds, consumed contact, took/healed damage or died"
	if not String(_level.get("last_configuration_error")).is_empty() or not _exact(_hero.equipment.snapshot(), _kit) or int(_events.get("equipment", 0)) != 0 or int(_events.get("fired_blast", 0)) != 0:
		return "native runtime, equipment or ordinary-only control contract changed"
	if int(_events.get("completion", 0)) != 0 or int(_events.get("checkpoint", 0)) != 0 or int(_events.get("exit", 0)) != 0 or _level.is_completed() or not String(_level.current_checkpoint().id).is_empty() or not String(_level.current_checkpoint().kind).is_empty() or int(_game.get("cores")) != 0 or int(_game.get("kills")) != 0 or not get_nodes_in_group("practice_targets").is_empty() or not get_nodes_in_group("lab_weapons").is_empty():
		return "shore preview granted completion/checkpoint/exit/reward or created a lab target/pickup"
	var state: Dictionary = _source.call("state")
	if float(state.hp) != _source_hp or state.effective_sun != 0:
		return "source HP changed outside a real ordinary tap or fixed scenic sun changed"
	if not _floor_hit(_hero.global_position):
		return "actual traveller left the firm shore floor"
	if not _record.is_empty():
		var current: Dictionary = _scheduler.reservation_state(String(_record.id))
		var cue: Dictionary = (_source.call("get_cue") as CinderThreatCue).state()
		if current.is_empty() or state.reservation_id != _record.id or state.phase not in ["warning", "lock", "active", "recovery"] or not _exact(current.geometry, _record.geometry) or current.adapter.planned_endpoint != _record.adapter.planned_endpoint or cue.phase != state.phase or not _exact(cue.geometry, _record.geometry) or cue.source_position != _source.global_position:
			return "actual source/common cue lost or altered the same locked native lane"
		for key: String in Deadlines:
			if float(current[key]) != float(_record[key]):
				return "actual held native deadline changed: " + key
		_phases[String(state.phase)] = true
		if state.phase == "active":
			_active_travel = maxf(_active_travel, _source.global_position.distance_to(_record.adapter.start))
		if state.phase == "recovery" and (_source.global_position.distance_to(_record.adapter.planned_endpoint) > PointTolerance or not _source.velocity.is_zero_approx()):
			return "real moving capsule failed its stopped physical recovery endpoint"
	return ""


func _clear_error() -> String:
	# Actual ordinary death defers its CollisionShape update. Observe the real
	# FIFO transaction boundary before requiring the registered tombstone.
	await process_frame
	await process_frame
	var state: Dictionary = _source.call("state")
	var body: CollisionShape3D = _source.get_node_or_null("BodyCollision") as CollisionShape3D
	if not state.dead or float(state.hp) != 0.0 or state.phase != "defeated" or not String(state.reservation_id).is_empty() or _source.visible or _source.is_in_group("enemies") or _source.collision_layer != 0 or _source.collision_mask != 0 or body == null or not body.disabled or not _source.velocity.is_zero_approx() or not _scheduler.reservations().is_empty():
		return "actual retained defeat/body/group/lease/cue lifecycle is incomplete"
	if _primary_count != 2 or int(_events.get("source_death", 0)) != 1 or int(_events.get("fired_slash", 0)) != 2 or int(_events.get("fired_dash", 0)) != _dash_count or not _exact(_actions, _hero.get_world_action_records()) or _actions.size() != _primary_count + _dash_count:
		return "actual action history lacks precisely two ordinary hits, completed dashes and one death"
	for record: Dictionary in _actions:
		if record.kind not in ["dash", "primary"]:
			return "actual clear used a blast or other unsupported action"
	var error: String = _live_error()
	if not error.is_empty():
		return error
	return await _capture("06-cleared-shore")


func _capture(label: String) -> String:
	if not _capture_portraits or _captured.has(label):
		return ""
	var previous_pause: bool = paused
	paused = true
	var before: Dictionary = _observation()
	var error: String = ""
	if before.pair.hero.is_empty() or before.pair.level.is_empty():
		error = "native complete-boundary capture rejected: " + _hero.last_snapshot_error + "; " + _level.last_snapshot_error
	if error.is_empty():
		await process_frame
		await RenderingServer.frame_post_draw
		var corners: Dictionary = _level.call("camera_framing_union", "", [], true)
		if not String(corners.get("error", "")).is_empty():
			error = "same rendered-frame native union rejected: " + String(corners.error)
		else:
			var view_error: String = _game.call("camera_framing_error", corners.points)
			if not view_error.is_empty():
				error = "same rendered-frame source/body/lane/mandatory traveller is clipped: " + view_error
		if error.is_empty() and not _exact(before, _observation()):
			error = "native render freeze changed the exact Hero/source/Scheduler unit, poses, resources, events, release anchor or camera"
		# The preserved first graphical result exposed an incorrect fixture
		# expectation: canvas_items uses a 540-by-1170 virtual input viewport.
		# Gestures stay in that space; only the drawn native Image must be 339x736.
		var actual: Image = root.get_texture().get_image() if error.is_empty() else null
		if error.is_empty() and (actual == null or actual.is_empty() or actual.get_size() != Vector2i(339, 736)):
			error = "actual native portrait image must be 339x736; observed " + str(actual.get_size() if actual != null else Vector2i.ZERO)
		if error.is_empty():
			var directory: String = ProjectSettings.globalize_path(CapturePath)
			if DirAccess.make_dir_recursive_absolute(directory) != OK or actual.save_png(directory.path_join(label + ".png")) != OK:
				error = "cannot save the unchanged native portrait: " + directory.path_join(label + ".png")
			else:
				_captured[label] = true
				print("PORTRAIT: " + directory.path_join(label + ".png") + "; native_size=" + str(actual.get_size()) + "; actual phase=" + String((_source.call("state") as Dictionary).phase))
	paused = previous_pause
	return error


func _floor_hit(point: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.25, point - Vector3.UP * 0.25, 1)
	var hit: Dictionary = _hero.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == _floor


func _last_sequence() -> int:
	var history: Array[Dictionary] = _hero.get_world_action_records()
	return int(history[-1].sequence) if not history.is_empty() else 0


func _event(kind: String) -> void:
	_events[kind] = int(_events.get(kind, 0)) + 1


func _tick_s() -> float:
	return 1.0 / float(Engine.physics_ticks_per_second)


func _frame_limit(seconds: float) -> int:
	return int(ceilf(seconds / _tick_s())) + 8


func _exact(left: Variant, right: Variant) -> bool:
	if typeof(left) != typeof(right):
		return false
	if left is float:
		var a := PackedByteArray()
		var b := PackedByteArray()
		a.resize(8)
		b.resize(8)
		a.encode_double(0, left)
		b.encode_double(0, right)
		return a == b
	if left is Dictionary:
		if left.size() != right.size():
			return false
		for key: Variant in left:
			if not right.has(key) or not _exact(left[key], right[key]):
				return false
		return true
	if left is Array:
		if left.size() != right.size():
			return false
		for index: int in range(left.size()):
			if not _exact(left[index], right[index]):
				return false
		return true
	return left == right


func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	if ok:
		print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label + ("; " + detail if not detail.is_empty() else ""))
		if is_instance_valid(_source):
			print("SHORE DIAGNOSTIC: source=", _source.call("state"), "; hero=", _hero.global_position, "; hp=", _hero.hp, "; scheduler=", _scheduler.get_clock(), "; events=", _events)
	return ok


func _close() -> bool:
	var game_ref: WeakRef = weakref(_game) if is_instance_valid(_game) else null
	var source_ref: WeakRef = weakref(_source) if is_instance_valid(_source) else null
	var barrier_ref: WeakRef = weakref(_barrier) if is_instance_valid(_barrier) else null
	if is_instance_valid(_level):
		_level.exit_level()
	var released: bool = not is_instance_valid(_scheduler) or _scheduler.reservations().is_empty()
	if is_instance_valid(_barrier):
		_barrier.waiting = false
		root.remove_child(_barrier)
		_barrier.queue_free()
	if is_instance_valid(_game):
		root.remove_child(_game)
		_game.queue_free()
	paused = false
	for _i: int in range(5):
		await process_frame
	var clean: bool = released and (game_ref == null or game_ref.get_ref() == null) and (source_ref == null or source_ref.get_ref() == null) and (barrier_ref == null or barrier_ref.get_ref() == null)
	for group: String in ["enemies", "practice_targets", "lab_weapons"]:
		clean = clean and get_nodes_in_group(group).is_empty()
	_game = null
	_hero = null
	_level = null
	_source = null
	_scheduler = null
	_floor = null
	_barrier = null
	return _expect(clean, "public level exit releases leases and finite retirement frees actual actors and group remnants")


func _finish() -> void:
	await _close()
	# Real short wall-time audio retirement, with no hidden physics correction.
	await create_timer(0.15, true, false, true).timeout
	print("Mirror shore preview: %d checks; failures: %d. Familiar-source scaffold only; no Echo/campaign/art acceptance." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
