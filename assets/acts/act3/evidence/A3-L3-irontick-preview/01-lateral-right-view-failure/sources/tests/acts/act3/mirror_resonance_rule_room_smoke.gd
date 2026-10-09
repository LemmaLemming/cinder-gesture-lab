extends SceneTree
## Actual shared Main/Player and one HP-free finite circle mechanism.
## Engine-routed gestures are automated fixture evidence, not native OS input.

const MainScene = preload("res://scenes/main.tscn")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const ROOM: String = "res://scenes/acts/act3/a3_l3_resonance_rule_room.tscn"
const CAPTURES: String = "res://.cinder/mirror-resonance-rule-portraits"

class PostActorBarrier extends Node:
	signal observed
	var waiting: bool = false
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 1000
	func _physics_process(_delta: float) -> void:
		if waiting:
			waiting = false
			observed.emit()
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PAUSED and waiting:
			_wake.call_deferred()
	func _wake() -> void:
		if waiting:
			waiting = false
			observed.emit()

var _game: Node
var _hero: CinderPlayer
var _level: CinderLevel
var _mechanism: CinderLaneMechanism
var _scheduler: CinderThreatScheduler
var _barrier: PostActorBarrier
var _checks: int = 0
var _failures: int = 0
var _events: Array[String] = []
var _phases: Dictionary = {}
var _kit: Dictionary = {}
var _hp: float = 0.0
var _capture: bool = false
var _captured: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_capture = "--capture-portraits" in OS.get_cmdline_user_args()
	if _capture and not _expect(DisplayServer.get_name() != "headless", "portrait selector requires actual native graphical rendering"):
		await _finish()
		return
	await _case()
	await _finish()


func _case() -> void:
	if not await _open():
		return
	_hero.shells = 0 # Disclosed TEST ONLY initial no-ammo condition, before ticks.
	_hp = _hero.hp
	_kit = _hero.equipment.snapshot()
	if not _expect(_scheduler.get_clock() == 0.0 and _mechanism.state().status == "idle" and _mechanism.state().cycle == 0 and _scheduler.reservations().is_empty(), "fresh actual world is configured at clock0 without an admitted cycle"):
		return
	_game.call("resume_lab")
	for _i: int in range(120):
		if _mechanism.state().status == "running":
			break
		if not await _tick():
			return
	var source: Dictionary = _mechanism.state()
	var actual: Dictionary = _level.call("state")
	var proof: Dictionary = actual.proof
	var record: Dictionary = _scheduler.reservation_state(String(source.reservation_id))
	var bindings: Dictionary = _level.call("scheduler_bindings")
	if not _expect(source.status == "running" and source.phase == "warning" and source.cycle == 1 and source.geometry.kind == "circle" and source.geometry.radius == 1.15 and record.get("source_instance_id") == _mechanism.get_instance_id() and bindings.owners.get("mirror-resonance/pulse") == _mechanism and proof.get("accepted", false) and not proof.uses_blast and not proof.uses_invulnerability and _hero.shells == 0, "actual native preview/start admits one zero-ammo disk with complete escape and ordinary-return witness", str(actual)):
		return
	if not await _portrait("warning") or not await _pause_native() or not await _transport_and_forgeries():
		return
	if not await _fresh_restore(_pair(), "warning"):
		return
	_game.call("resume_lab")
	var escaped: bool = false
	var returned: bool = false
	for segment: Dictionary in proof.path:
		if segment.kind not in ["escape_dash", "positioning_dash"]:
			continue
		if not await _until(float(segment.start_s)):
			return
		var error: String = _swipe((segment.to - segment.from).normalized())
		if not _expect(error.is_empty(), "actual routed viewport swipe starts " + String(segment.kind), error):
			return
		if segment.kind == "escape_dash":
			if not await _tick() or not await _pause_native():
				return
			if not _expect(_hero.get_committed_dash_state().active and float(_hero.get_threat_response_state().motion.dash_left_s) > 0.0, "paused unit contains a genuinely unfinished shared dash"):
				return
			if not await _transport_and_forgeries() or not await _fresh_restore(_pair(), "unfinished escape dash"):
				return
			_game.call("resume_lab")
		for _i: int in range(60):
			if float(_hero.get_threat_response_state().motion.dash_left_s) == 0.0:
				break
			if not await _tick():
				return
		var planar_error: float = Vector2(_hero.global_position.x, _hero.global_position.z).distance_to(Vector2(segment.to.x, segment.to.z))
		if not _expect(float(_hero.get_threat_response_state().motion.dash_left_s) == 0.0 and planar_error < 0.005 and _hero.is_on_floor() and _mechanism.global_transform == Transform3D.IDENTITY, "actual completed dash reaches the proved landing on permanent floor without moving the source"):
			return
		if segment.kind == "escape_dash":
			escaped = true
		else:
			returned = true
			if not await _portrait("returned"):
				return
	if not await _until(float(proof.primary_time_s)):
		return
	if not _expect(escaped and returned and _mechanism.state().phase == "recovery" and _hero.global_position.distance_to(proof.attack_position) < 0.02 and float(proof.response_complete_s) < float(record.recovery_until_s), "genuine escape and return retain a reachable full ordinary-primary recovery budget"):
		return
	# There is no attackable HP target. The real primary still keeps its meaning.
	var before_primary: int = _events.count("fired_slash")
	var error: String = _tap(Vector3.FORWARD)
	if not _expect(error.is_empty() and _events.count("fired_slash") == before_primary + 1 and not _mechanism.has_method("take_damage") and not _mechanism.is_in_group("enemies") and not _mechanism.is_in_group("targets"), "ordinary first tap remains usable; the accessible environmental opening is not enemy HP", error):
		return
	for _i: int in range(180):
		if _mechanism.state().status == "complete":
			break
		if not await _tick():
			return
	if not await _portrait("complete"):
		return
	var dashes: int = 0
	for action: Dictionary in _hero.get_world_action_records():
		if action.kind == "dash":
			dashes += 1
	var checkpoint: Dictionary = _level.current_checkpoint()
	if not _expect(_mechanism.state().status == "complete" and _mechanism.state().cycle == 1 and _mechanism.get_cue().state().phase == "clear" and _scheduler.reservations().is_empty() and _phases.has("warning") and _phases.has("lock") and _phases.has("active") and _phases.has("recovery") and dashes == 2 and _hero.hp == _hp and not _hero.dead and not _events.has("hit") and not _events.has("fired_blast") and not _events.has("completion") and not _events.has("checkpoint") and not _events.has("exit") and not _level.is_completed() and checkpoint.id.is_empty() and checkpoint.kind.is_empty(), "one real disk cycle ends harmlessly with two ordinary dashes, no reward/progression and cleared cue/lease"):
		return
	for _i: int in range(24):
		if not await _tick():
			return
	_expect(_mechanism.state().cycle == 1 and _scheduler.reservations().is_empty(), "later real ticks do not independently schedule another pulse")


func _open() -> bool:
	_game = MainScene.instantiate()
	_game.set("level_scene_path", ROOM)
	root.add_child(_game)
	_game.call("open_bench") # Pause in the construction call stack before yielding.
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	_mechanism = _level.get("mechanism") as CinderLaneMechanism if _level != null else null
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler if _level != null else null
	_barrier = PostActorBarrier.new()
	_game.add_child(_barrier)
	_events.clear()
	if not _expect(_level != null and _hero != null and _mechanism != null and _scheduler != null and _level.scene_file_path == ROOM and String(_level.get("last_configuration_error")).is_empty() and paused, "actual MainScene binds the owned HP-free resonance room", String(_level.get("last_configuration_error")) if _level != null else "missing level"):
		return false
	_mechanism.state_changed.connect(func(current: Dictionary) -> void: _events.append("phase_" + String(current.phase)))
	_mechanism.hit_resolved.connect(func(_id: String, _cycle: int, _result: Dictionary) -> void: _events.append("hit"))
	_mechanism.get_cue().state_changed.connect(func(_state: Dictionary) -> void: _events.append("cue"))
	_scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _events.append("cancel"))
	_hero.fired.connect(func(kind: String) -> void: _events.append("fired_" + kind))
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _events.append("completion"))
	_level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _boundary: String) -> void: _events.append("checkpoint"))
	_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _events.append("exit"))
	var scenery: Node3D = _level.get("scenery") as Node3D
	var floor_body: StaticBody3D = scenery.get("floor_body") as StaticBody3D
	var collision: CollisionShape3D = floor_body.get_node_or_null("Solid") as CollisionShape3D
	return _expect(collision != null and collision.shape is BoxShape3D and (collision.shape as BoxShape3D).size == Vector3(14, 1, 22) and collision.global_position.y == -0.5 and _hero.presentation_id == "act3_traveller" and get_nodes_in_group("enemies").is_empty() and _level.process_physics_priority < _mechanism.process_physics_priority and _barrier.process_physics_priority > _mechanism.process_physics_priority, "actual firm14×22 floor, shared Act3 traveller and source-before-contact observation priorities")


func _pause_native() -> bool:
	if not _expect(_game.call("request_pause_deferred"), "public Game requests a completed native paused tick"):
		return false
	for _i: int in range(4):
		await process_frame
	return _expect(paused and not _game.call("is_pause_requested"), "deferred pause settled outside actor/cue/contact transactions")


func _pair() -> Dictionary:
	return {"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}


func _observation() -> Dictionary:
	return {"pair": _pair(), "hero_transform": _hero.global_transform, "velocity": _hero.velocity, "dash": _hero.get_committed_dash_state(), "source": _mechanism.state(), "source_transform": _mechanism.global_transform, "cue": _mechanism.get_cue().state(), "leases": _scheduler.reservations(), "events": _events.duplicate(), "camera": (_game.get("camera") as Camera3D).global_transform, "anchor": _game.call("get_aim_anchor_normalized")}


func _pair_error(pair: Dictionary) -> String:
	var error: String = _hero.snapshot_error(pair.hero)
	return _level.snapshot_error_with_player(pair.level, pair.hero) if error.is_empty() else error


func _transport_and_forgeries() -> bool:
	var pair: Dictionary = _pair()
	var text: String = Exact.stringify(pair)
	var decoded: Dictionary = Exact.parse(text)
	var before: Dictionary = _observation()
	if not _expect(not pair.hero.is_empty() and not pair.level.is_empty() and not text.is_empty() and decoded.get("accepted", false) and _exact(decoded.value, pair) and _pair_error(decoded.value).is_empty() and _exact(before, _observation()), "raw ExactJson preserves and purely validates the complete actual paused native unit", _level.last_snapshot_error):
		return false
	var bad_units: Array[Dictionary] = []
	var labels: Array[String] = []
	var bad: Dictionary = pair.duplicate(true)
	bad.level.local.scheduler.clock_s = float(bad.level.local.scheduler.clock_s) + 0.00000001
	bad_units.append(bad)
	labels.append("exact paired clock")
	bad = pair.duplicate(true)
	bad.level.local.mechanism.configuration.geometry.origin[0] = 0.125
	bad_units.append(bad)
	labels.append("fixed source geometry")
	bad = pair.duplicate(true)
	bad.level.local.mechanism.hero_samples.hero.position[0] = float(bad.level.local.mechanism.hero_samples.hero.position[0]) + 0.125
	bad_units.append(bad)
	labels.append("actual sampled path endpoint")
	bad = pair.duplicate(true)
	bad.level.local.mechanism["pending_segments"] = {"hero": []}
	bad_units.append(bad)
	labels.append("invented pending-path controls")
	bad = pair.duplicate(true)
	bad.level.local.view["extra"] = true
	bad_units.append(bad)
	labels.append("closed view-only fields")
	bad = pair.duplicate(true)
	bad.level.progress.completed = true
	bad.level.progress.completion_id = "forged-resonance-clear"
	bad_units.append(bad)
	labels.append("campaign completion grant")
	for index: int in range(bad_units.size()):
		var input: Dictionary = bad_units[index].duplicate(true)
		if not _expect(not _pair_error(bad_units[index]).is_empty() and not _level.restore_state(bad_units[index].level) and _exact(input, bad_units[index]) and _exact(before, _observation()), "pure and live restore atomically reject " + labels[index]):
			return false
	await process_frame
	await process_frame
	return _expect(_exact(before, _observation()), "pause freezes native poses/clocks/resources/history/cue/events without retiming")


func _fresh_restore(pair: Dictionary, label: String) -> bool:
	var saved: Dictionary = Exact.parse(Exact.stringify(pair)).value
	var cue: Dictionary = _mechanism.get_cue().state()
	await _close()
	if not await _open():
		return false
	var before: Dictionary = _observation()
	if not _expect(_scheduler.get_clock() == 0.0 and _mechanism.state().cycle == 0 and _pair_error(saved).is_empty() and _exact(before, _observation()), "fresh zero-tick world purely validates saved " + label):
		return false
	var events: Array[String] = _events.duplicate()
	if not _expect(_hero.restore_state(saved.hero) and _level.restore_state(saved.level), "public ordered Hero→Scheduler→mechanism quiet reconstruction preserves " + label, _hero.last_snapshot_error + "; " + _level.last_snapshot_error):
		return false
	return _expect(_exact(_pair(), saved) and _exact(cue, _mechanism.get_cue().state()) and _exact(events, _events) and _hero.hp == _hp and _exact(_kit, _hero.equipment.snapshot()), "fresh unit exactly retains pending motion/resources/phase/deadlines/history and emits no restoration events")


func _tick() -> bool:
	if paused:
		return _expect(false, "ordinary route cannot advance a paused unit")
	_barrier.waiting = true
	await _barrier.observed
	var current: Dictionary = _mechanism.state()
	_phases[current.phase] = true
	var error: String = String(_level.get("last_configuration_error"))
	if not error.is_empty() or current.status == "cancelled" or _hero.hp != _hp or _hero.dead or not _exact(_kit, _hero.equipment.snapshot()) or _events.has("fired_blast") or _events.has("hit") or _scheduler.get_clock() > 10.0:
		return _expect(false, "finite actual pulse preserves harmless proven route and native resources", error + "; " + str(_level.call("state")))
	if _capture and current.phase in ["lock", "active", "recovery"]:
		return await _portrait(String(current.phase))
	return true


func _until(target: float) -> bool:
	for _i: int in range(360):
		if _scheduler.get_clock() >= target:
			return _expect(_scheduler.get_clock() <= target + 1.0 / float(Engine.physics_ticks_per_second) + 0.000000001, "action uses the first available actual post-actor physics tick", "target=" + str(target) + "; actual=" + str(_scheduler.get_clock()))
		if not await _tick():
			return false
	return _expect(false, "finite actual deadline is reachable")


func _portrait(label: String) -> bool:
	if not _capture or _captured.has(label):
		return true
	var prior: bool = paused
	paused = true # TEST ONLY whole-unit render freeze, no UI/camera alteration.
	var before: Dictionary = _observation()
	await process_frame
	await RenderingServer.frame_post_draw
	var error: String = _game.call("camera_framing_error", _level.camera_framing_points())
	var image: Image = root.get_texture().get_image()
	var ok: bool = not before.pair.hero.is_empty() and not before.pair.level.is_empty() and error.is_empty() and _exact(before, _observation()) and image != null and image.get_size() == Vector2i(339, 736)
	if ok:
		var directory: String = ProjectSettings.globalize_path(CAPTURES)
		ok = DirAccess.make_dir_recursive_absolute(directory) == OK and image.save_png(directory.path_join(label + ".png")) == OK
	paused = prior
	if ok:
		_captured[label] = true
		print("PORTRAIT: ", ProjectSettings.globalize_path(CAPTURES).path_join(label + ".png"))
	return _expect(ok, "actual unchanged native339×736 portrait " + label, error + "; " + _level.last_snapshot_error)


func _swipe(direction: Vector3) -> String:
	var size: Vector2 = root.get_visible_rect().size
	var start: Vector2 = size * Vector2(0.5, 0.60)
	var finish: Vector2 = start + _screen_direction(direction) * size.x * 0.22
	if not root.get_visible_rect().has_point(finish) or finish.y < 100.0:
		return "Actual routed release is outside the viewport input region"
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
	return "" if float(_hero.get_threat_response_state().motion.dash_left_s) > 0.0 and (_game.call("get_aim_anchor_normalized") as Vector2).distance_to(finish / size) < 0.000001 else "Shared router did not begin the real dash and retain its final release anchor"


func _tap(direction: Vector3) -> String:
	var point: Vector2 = _game.call("get_aim_anchor") + _screen_direction(direction) * 60.0
	if not root.get_visible_rect().has_point(point) or point.y < 100.0:
		return "Actual primary tap is outside the viewport input region"
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


func _close() -> void:
	var old: WeakRef = weakref(_game) if is_instance_valid(_game) else null
	var old_hero: WeakRef = weakref(_hero) if is_instance_valid(_hero) else null
	var old_source: WeakRef = weakref(_mechanism) if is_instance_valid(_mechanism) else null
	if is_instance_valid(_level):
		_level.exit_level()
		_expect(_scheduler.reservations().is_empty() and not _scheduler.source_control_state(_mechanism).is_empty(), "public level exit clears actual owned leases")
	if is_instance_valid(_barrier):
		_barrier.waiting = false
	if is_instance_valid(_game):
		_game.queue_free()
	paused = false
	for _i: int in range(5):
		await process_frame
	if old != null:
		_expect(old.get_ref() == null and old_hero.get_ref() == null and old_source.get_ref() == null and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "real old world/Hero/source/cues are released before replacement")
	_game = null
	_hero = null
	_level = null
	_mechanism = null
	_scheduler = null
	_barrier = null


func _finish() -> void:
	await _close()
	await create_timer(0.15, true, false, true).timeout # Finite actual audio drain.
	print("Mirror resonance rule: %d checks; failures: %d. Filled-disk finite scaffold only; no annulus/full-L3/production-Shell acceptance." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _exact(left: Variant, right: Variant) -> bool:
	return Exact.stringify(left) == Exact.stringify(right)


func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	if ok:
		print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok
