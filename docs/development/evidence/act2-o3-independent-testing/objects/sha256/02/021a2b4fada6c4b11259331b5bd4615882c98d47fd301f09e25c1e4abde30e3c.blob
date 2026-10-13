extends SceneTree
## Narrow actual C30 callback-custody regression. Fixture-only Hero placement
## during warning creates a native grazing rush; no gesture route, portrait,
## main progression, tuning acceptance or production save claim follows.

const MainScene = preload("res://scenes/main.tscn")
const ActorScript = preload("res://scripts/acts/act1/rush_selenite.gd")
const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const LEVEL_PATH: String = "res://scenes/acts/act1/a1_l2_layout_greybox.tscn"
const SOURCE_ID: String = "a1_l2_callback_rusher"
const ENCOUNTER_ID: String = "a1-l2-c30-callback"
const SOURCE_POSITION: Vector3 = Vector3(0, 0.005, 10)

var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _world: Node3D
var _scheduler: CinderThreatScheduler
var _source: Act1RushSelenite
var _case: String = ""
var _intercepted: bool = false
var _inside_capture_rejected: bool = false
var _clear_accepted: bool = false
var _previous: Dictionary = {}
var _current: Dictionary = {}
var _published: Dictionary = {}
var _hits: Array[Dictionary] = []
var _events: int = 0
var _checks: int = 0
var _failures: int = 0
var _finishing: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(35.0, true).timeout.connect(func() -> void:
		if not _finishing:
			_expect(false, "bounded C30 callback fixture finishes within 35 seconds")
			_finish())
	root.size = Vector2i(540, 1170)
	await _test_pause_restore()
	if _finishing: return
	for mutation: String in ["cue-hide", "cue-clear", "source-marker-hide", "outline-hide", "fill-hide"]:
		await _test_unavailable(mutation)
		if _finishing: return
	_finish()


func _install() -> bool:
	paused = true
	_game = MainScene.instantiate()
	_game.set("level_scene_path", LEVEL_PATH)
	root.add_child(_game)
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	_world = _game.get("world") as Node3D
	if not _expect(_level != null and _hero != null and _world != null and get_nodes_in_group("enemies").is_empty(), "real shared Game supplies one actual Player and a noncombat layout"):
		return false
	_scheduler = SchedulerScript.new()
	_scheduler.name = "CallbackFixtureScheduler"
	_level.add_child(_scheduler)
	_source = ActorScript.new()
	_source.name = "CallbackFixtureC30"
	_source.position = SOURCE_POSITION
	var raw: Dictionary = ActorScript.DEFAULT_RAW_ROLE.duplicate(true)
	# Avoid a phase deadline exactly on the native physics grid. This is fixture
	# data only; every observed interval is independently checked below.
	raw.windup_s += 0.005
	if not _expect(_source.configure(SOURCE_ID, raw), "immutable fixture C30 uses default native capsule/lunge with a 5ms windup offset"):
		_source.free(); return false
	_level.add_child(_source)
	if not _expect(_source.bind(_scheduler, _hero), "retained C30 binds the actual earlier-physics shared Player/Scheduler"):
		return false
	_source.state_changed.connect(_source_observer)
	_source.get_cue().state_changed.connect(_cue_observer)
	_source.hit_resolved.connect(_hit_observer)
	_hero.fired.connect(func(_kind: String) -> void: _events += 1)
	_scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _events += 1)
	_case = ""
	_intercepted = false
	_inside_capture_rejected = false
	_clear_accepted = false
	_hits.clear()
	_previous.clear(); _current.clear(); _published.clear()
	# Setup position, not player input or an authored route. Real physics settles
	# both original capsules on the same native floor before the public request.
	_hero.global_position = SOURCE_POSITION + Vector3(0, 0.1, 3)
	_game.call("resume_lab")
	await _ticks(6)
	_events = 0
	return true


func _start_graze(mode: String) -> bool:
	if not _expect(_scheduler.begin_encounter("standard", ENCOUNTER_ID, 1), mode + " starts an actual fresh fixed encounter"):
		return false
	var answer: Dictionary = _source.start(_context(), Vector3.BACK, _world)
	if not _expect(answer.get("accepted", false), mode + " admits a real native lunge and ordinary-primary response: " + String(answer.get("reason", ""))):
		return false
	var record: Dictionary = answer.reservation
	var step: float = 1.0 / float(Engine.physics_ticks_per_second)
	var first_clock: float = _scheduler.get_clock()
	while first_clock < float(record.active_from_s):
		first_clock += step
	var elapsed: float = first_clock - float(record.active_from_s)
	var travel: float = elapsed * float(record.adapter.speed)
	var clipped_start: float = travel * (1.0 - elapsed / step)
	var span: float = travel - clipped_start
	var radius: float = float(record.adapter.damage_radius) + SchedulerScript.CAPSULE_RADIUS
	if not _expect(elapsed > 0.001 and elapsed < step - 0.001 and span > 0.02, mode + " fixture deadline has a nonzero native active slice"):
		return false
	# Tangent to the actual damage halo, clear of the two physical capsules.
	# Both active-clipped endpoints are outside, but their interior intersects.
	var lateral: float = sqrt(radius * radius - pow(span * 0.25, 2.0))
	_hero.global_position = Vector3(_source.global_position.x + lateral, _hero.global_position.y, _source.global_position.z + (travel + clipped_start) * 0.5)
	_case = mode
	await _ticks(2)
	for _attempt: int in range(240):
		if _intercepted: break
		_previous = _native_sample()
		await _ticks(1)
	if not _expect(_intercepted, mode + " observes an actual native active publication within four seconds"):
		print("CALLBACK SETUP DIAGNOSTIC ", _source.state(), " source_error=", _source.last_error, " paused=", paused)
		return false
	var path: Array[Dictionary] = [{"from": _previous.hero_position - _previous.source_position, "to": _current.hero_position - _current.source_position, "start_s": _previous.clock_s, "end_s": _current.clock_s}]
	var shape: Dictionary = Geometry.circle(Vector3.ZERO, float(_published.adapter.damage_radius))
	_expect(_current.source_position.distance_to(_previous.source_position) > 0.02 and _current.clock_s > _previous.clock_s and _current.clock_s >= float(_published.active_from_s), mode + " witnesses a genuinely moved retained source over an actual active interval")
	_expect(Geometry.timed_path_hits(shape, path, float(_published.active_from_s), float(_published.active_until_s), SchedulerScript.CAPSULE_RADIUS), mode + " actual relative source/Hero sweep intersects during activation")
	_expect(not Geometry.segment_hits(shape, path[0].from, path[0].from, SchedulerScript.CAPSULE_RADIUS) and not Geometry.segment_hits(shape, path[0].to, path[0].to, SchedulerScript.CAPSULE_RADIUS), mode + " both sampled endpoints are outside, so dropping the crossed interval cannot pass")
	print("CALLBACK NATIVE INTERVAL ", mode, " ", path, " active=", _published.active_from_s, "..", _published.active_until_s)
	return true


func _test_pause_restore() -> void:
	if not await _install():
		_dispose(); return
	if not await _start_graze("pause"):
		_dispose(); return
	await process_frame
	_expect(paused and _inside_capture_rejected, "active cue holds a genuine tree pause and cannot capture inside the originating actor callback")
	_expect(_hero.hp == _hero.max_hp and _hits.is_empty() and _source.state().hit_ids.is_empty(), "deferred held pause causes no HP damage, hit callback or consumed hero opportunity")
	var pair: Dictionary = _capture()
	if not _expect(not pair.is_empty(), "deferred paused whole Player/C30/Scheduler unit is capturable"):
		_dispose(); return
	_expect(pair.source.sample.clock_s == pair.scheduler.clock_s and pair.source.sample.hero_position == pair.player.motion.position and pair.source.sample.source_position == pair.source.motion.position, "current paused sample matches the actual saved native endpoints and clock")
	if not _expect(pair.source.schema_version == 3 and pair.source.get("pending_segments") is Array and not pair.source.pending_segments.is_empty(), "held active publication captures explicit conditional schema3 with a nonempty retained path"):
		_dispose(); return
	var pending: Array = pair.source.pending_segments
	_expect(pending[0].from == Codec.vector3(_previous.hero_position - _previous.source_position) and pending[0].start_s == _previous.clock_s and pending[-1].to == Codec.vector3(_current.hero_position - _current.source_position) and pending[-1].end_s == pair.scheduler.clock_s, "pending transport retains the exact observed previous/current relative native endpoints and clocks")
	_test_pending_malformed(pair)
	var frozen: String = Exact.stringify(pair)
	await create_timer(0.06, true).timeout
	_expect(Exact.stringify(_capture()) == frozen, "held tree pause freezes the complete exact actor/resources/lease unit")
	var decoded: Dictionary = Exact.parse(frozen)
	if not _expect(decoded.get("accepted", false) and decoded.get("value") is Dictionary and Exact.stringify(decoded.value) == frozen, "exact transport retains the complete conditional pending envelope without filtering fields"):
		_dispose(); return
	pair = decoded.value
	_dispose()
	if not await _install():
		_dispose(); return
	paused = true
	await process_frame
	var event_count: int = _events
	var restored: bool = _restore(pair)
	if not _expect(restored and _events == event_count and _hits.is_empty(), "fresh actual Player/retained C30/Scheduler prevalidate then quietly commit the whole paused unit"):
		print("CALLBACK RESTORE DIAGNOSTIC ", _unit_error(pair), " source=", _source.last_snapshot_error, " scheduler=", _scheduler.last_snapshot_error)
		_dispose(); return
	_expect(Exact.stringify(_capture()) == frozen and _hero.hp == _hero.max_hp, "fresh exact paired restore retains undamaged resources and the original pending opportunity")
	var expected_hp: float = _hero.max_hp - _hero.equipment.damage_received(float(pair.source.resolved_role.damage))
	_game.call("resume_lab")
	await _ticks(3)
	_expect(_hits.size() == 1 and _hero.hp == expected_hp and _source.state().hit_ids == ["hero"], "public resume delivers the saved swept opportunity once although the actual source has moved past the Hero")
	if _hits.size() == 1:
		_expect(_hits[0].hero_id == "hero" and _hits[0].cycle == pair.source.cycle and _hits[0].result.opportunity_consumed and _hits[0].result.accepted, "resumed delivery belongs to the original source cycle and actual damage result")
	await _ticks(24)
	_expect(_hits.size() == 1 and _hero.hp == expected_hp, "remaining real activation/recovery cannot duplicate the restored hit")
	paused = true
	await process_frame
	var drained: Dictionary = _capture()
	_expect(not drained.is_empty() and drained.source.schema_version == 2 and not drained.source.has("pending_segments"), "draining the retained opportunity restores ordinary closed schema2 transport")
	_dispose()


func _test_pending_malformed(pair: Dictionary) -> void:
	for mutation: String in ["downgrade2", "strip-key", "empty3", "endpoint", "clock", "join-position", "join-clock", "per-tick-span", "consumed-hit", "dead", "dormant", "inactive-lease", "hurt", "non-native-vector", "zero-time-jump"]:
		var bad: Dictionary = pair.duplicate(true)
		match mutation:
			"downgrade2": bad.source.schema_version = 2
			"strip-key": bad.source.erase("pending_segments")
			"empty3": bad.source.pending_segments.clear()
			"endpoint":
				bad.source.pending_segments[-1].to = Codec.vector3(Codec.read_vector3(bad.source.pending_segments[-1].to) + Vector3(0.01, 0, 0))
			"clock": bad.source.pending_segments[-1].end_s -= 1e-12
			"join-position", "join-clock":
				# Split only the copied transport. No native actor/sample is forced.
				# Each piece is finite/native and within one actual physics tick;
				# the final actual endpoint/clock is retained while one join breaks.
				var original: Dictionary = bad.source.pending_segments[0]
				var middle: Array = Codec.vector3(Codec.read_vector3(original.from).lerp(Codec.read_vector3(original.to), 0.5))
				var middle_clock: float = (float(original.start_s) + float(original.end_s)) * 0.5
				var first: Dictionary = {"from": original.from.duplicate(), "to": middle.duplicate(), "start_s": original.start_s, "end_s": middle_clock}
				var second: Dictionary = {"from": middle.duplicate(), "to": original.to.duplicate(), "start_s": middle_clock, "end_s": original.end_s}
				if mutation == "join-position":
					first.to = Codec.vector3(Codec.read_vector3(first.to) + Vector3(0.01, 0, 0))
				else:
					second.start_s += 1e-12
				bad.source.pending_segments = [first, second]
			"per-tick-span":
				bad.source.pending_segments[0].start_s = float(bad.source.pending_segments[0].end_s) - 2.0 / float(Engine.physics_ticks_per_second)
			"consumed-hit": bad.source.hit_ids.append("hero")
			"dead":
				bad.source.dead = true
				bad.source.hp = 0.0
				bad.source.motion.velocity = Codec.vector3(Vector3.ZERO)
			"dormant": bad.source.dormant = true
			"inactive-lease": bad.source.reservation_id = ""
			"hurt": bad.source.hurt_left_s = 0.01
			"non-native-vector":
				bad.source.pending_segments[0].from[0] += 1e-12
				_expect(Codec.is_vector3(bad.source.pending_segments[0].from) and bad.source.pending_segments[0].from != Codec.vector3(Codec.read_vector3(bad.source.pending_segments[0].from)), "tiny pending-vector mutation stays finite but cannot roundtrip through native Vector3 exactly")
			"zero-time-jump":
				bad.source.pending_segments[0].start_s = bad.source.pending_segments[0].end_s
		_expect(_reject_unchanged(bad), "pending " + mutation + " rejects purely before whole-unit commit without changing actual actor/Player/Scheduler or events")
	_expect(_unit_error(pair).is_empty() and Exact.stringify(_capture()) == Exact.stringify(pair), "all malformed checks retain the original valid pending aggregate unchanged")


func _reject_unchanged(bad: Dictionary) -> bool:
	var frozen: String = Exact.stringify(_capture())
	var bad_before: String = Exact.stringify(bad)
	var event_count: int = _events
	var hit_count: int = _hits.size()
	var error: String = _unit_error(bad)
	# An unexpected validator acceptance is already a failure. Do not commit
	# malformed data merely to find out whether it can corrupt the actual actors.
	var rejected: bool = not error.is_empty() and not _restore(bad)
	return rejected and Exact.stringify(_capture()) == frozen and Exact.stringify(bad) == bad_before and _events == event_count and _hits.size() == hit_count


func _test_unavailable(mode: String) -> void:
	if not await _install():
		_dispose(); return
	if not await _start_graze(mode):
		_dispose(); return
	await _ticks(2)
	_expect(mode != "cue-clear" or _clear_accepted, "cue clear runs from actor state publication after native cue notification returns")
	_expect(_hero.hp == _hero.max_hp and _hits.is_empty() and _source.state().hit_ids.is_empty(), mode + " active observer prevents same-tick HP damage and consumed opportunity")
	_expect(_source.state().reservation_id.is_empty() and _scheduler.reservations().is_empty() and _source.get_cue().state().phase == "clear", mode + " required presentation loss cancels its actual lease and clears danger")
	paused = true
	await process_frame
	var saved: Dictionary = _scheduler.snapshot_state(_bindings())
	_expect(not saved.is_empty() and saved.cooldowns.size() == 1 and saved.cooldowns[0].ready_s == _published.cooldown_until_s, mode + " cancellation preserves the exact original source cooldown")
	_dispose()


func _cue_observer(value: Dictionary) -> void:
	_events += 1
	if value.phase != "active" or _intercepted or _case not in ["pause", "cue-hide", "source-marker-hide", "outline-hide", "fill-hide"]: return
	_intercepted = true
	_current = _native_sample()
	_published = _source.state()
	if _case == "pause":
		paused = true
		_inside_capture_rejected = _source.snapshot_state(_scheduler.snapshot_state(_bindings())).is_empty()
	else:
		match _case:
			"cue-hide": _source.get_cue().hide()
			"source-marker-hide": (_source.get_cue().get_node("RequiredSourceMarker") as MeshInstance3D).hide()
			"outline-hide": (_source.get_cue().get_node("RequiredFootprintOutline") as MeshInstance3D).hide()
			"fill-hide": (_source.get_cue().get_node("RequiredFootprintFill") as MeshInstance3D).hide()


func _source_observer(value: Dictionary) -> void:
	_events += 1
	if value.phase != "active" or _intercepted or _case != "cue-clear": return
	_intercepted = true
	_current = _native_sample()
	_published = value.duplicate(true)
	# Cue.clear explicitly rejects during its own state_changed publication.
	_clear_accepted = _source.get_cue().clear()


func _hit_observer(hero_id: String, cycle: int, result: Dictionary) -> void:
	_events += 1
	_hits.append({"hero_id": hero_id, "cycle": cycle, "result": result.duplicate(true)})


func _native_sample() -> Dictionary:
	return {"clock_s": _scheduler.get_clock(), "source_position": _source.global_position, "hero_position": _hero.global_position}


func _context() -> Dictionary:
	var directions: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3(1, 0, 1).normalized(), Vector3(-1, 0, 1).normalized(), Vector3(1, 0, -1).normalized(), Vector3(-1, 0, -1).normalized()]
	return {"encounter_id": ENCOUNTER_ID, "world_revision": 1, "recognition_s": 0.18, "attack_input_margin_s": 0.08, "escape_directions": directions, "return_directions": directions.duplicate(), "floor_regions": [_bindings().floors.floor]}


func _bindings() -> Dictionary:
	return {"world_root": _world, "owners": {SOURCE_ID: _source}, "floors": {"floor": {"collision": _level.get_node("Floor/CollisionShape3D"), "safe_rect": Rect2(-7, -24, 14, 44)}}}


func _capture() -> Dictionary:
	var scheduler: Dictionary = _scheduler.snapshot_state(_bindings())
	var player: Dictionary = _hero.snapshot_state()
	if scheduler.is_empty() or player.is_empty(): return {}
	var source: Dictionary = _source.snapshot_state(scheduler)
	if source.is_empty():
		print("CALLBACK CAPTURE DIAGNOSTIC ", _source.last_snapshot_error)
		return {}
	return {"player": player, "scheduler": scheduler, "source": source}


func _unit_error(pair: Dictionary) -> String:
	var error: String = _hero.snapshot_error(pair.player)
	if error.is_empty(): error = _source.actor_snapshot_error(pair.source, pair.scheduler, pair.player)
	if not error.is_empty(): return error
	var bindings: Dictionary = _bindings()
	var staged: Dictionary = _source.staged_actor_bindings(pair.source)
	if staged.is_empty(): return "Actual retained native actor staging failed"
	for key: String in ["owner_positions", "owner_velocities", "owner_collision_states"]:
		bindings[key] = staged[key]
	bindings.hero_positions = {"hero": Codec.read_vector3(pair.player.motion.position)}
	return _scheduler.snapshot_error(pair.scheduler, bindings)


func _restore(pair: Dictionary) -> bool:
	if not _unit_error(pair).is_empty(): return false
	return _hero.restore_state(pair.player) and _source.restore_actor_state(pair.source) and _scheduler.restore_state(pair.scheduler, _bindings()) and _source.restore_exchange_state(pair.source)


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame


func _dispose() -> void:
	_case = ""
	paused = true
	if is_instance_valid(_game): _game.free()


func _expect(condition: bool, label: String) -> bool:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)
	return condition


func _finish() -> void:
	if _finishing: return
	_finishing = true
	_dispose()
	print("Act1 L2 C30 callback fixture: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
