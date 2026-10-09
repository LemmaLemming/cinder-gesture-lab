extends SceneTree
## Actual shared Main, one continuous Scheduler, two genuine pulses and one C52.
## Engine-routed input is automated fixture evidence, not native OS gestures.

const MainScene = preload("res://scenes/main.tscn")
const ROOM: String = "res://scenes/acts/act3/a3_l3_echo_resonance_room.tscn"
const CAPTURES: String = "res://.cinder/mirror-echo-resonance-room-portraits"

class Barrier extends Node:
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
var _level: CinderLevel
var _hero: CinderPlayer
var _scheduler: CinderThreatScheduler
var _pulse: CinderLaneMechanism
var _echo: Node3D
var _barrier: Barrier
var _checks: int = 0
var _failures: int = 0
var _events: Array[String] = []
var _phases: Dictionary = {}
var _leases: Dictionary = {}
var _last_clock: float = 0.0
var _kit: Dictionary = {}
var _hp: float = 0.0
var _echo_origin: Transform3D
var _pulse_origin: Transform3D
var _scheduler_id: int = 0
var _pulse_id: int = 0
var _echo_id: int = 0
var _capture: bool = false
var _first_only: bool = false
var _captures: Dictionary = {}
var _renderer_start: Vector3
var _renderer_travel: float = 0.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_capture = "--capture-portraits" in OS.get_cmdline_user_args()
	_first_only = "--first-pulse-only" in OS.get_cmdline_user_args()
	if _capture and not _expect(DisplayServer.get_name() != "headless", "native portrait selector requires graphical rendering"):
		await _finish()
		return
	await _case()
	await _finish()


func _case() -> void:
	if not _open():
		return
	_hero.shells = 0 # Disclosed TEST ONLY initial depletion before any real tick.
	_hp = _hero.hp
	_kit = _hero.equipment.snapshot()
	_echo_origin = _echo.global_transform
	_pulse_origin = _pulse.global_transform
	_scheduler_id = _scheduler.get_instance_id()
	_pulse_id = _pulse.get_instance_id()
	_echo_id = _echo.get_instance_id()
	if not _expect(_scheduler.get_clock() == 0.0 and _pulse.state().cycle == 0 and _pulse.state().status == "idle" and _echo.call("source_phase") == "idle" and float(_echo.get("hp")) == 36.0 and _hero.shells == 0 and _scheduler.reservations().is_empty(), "fresh real world has one configured idle Echo and one unadmitted pulse at native clock0") or not await _refuse_save("arrival"):
		return
	_game.call("resume_lab")
	if not await _await_stage("pulse1"):
		return
	var first: Dictionary = _level.call("state")
	if not _expect(first.pulse.phase == "warning" and first.pulse.cycle == 1 and first.pulse.geometry.kind == "circle" and first.pulse.geometry.origin == Vector3(2.6, 0, 0) and first.pulse.geometry.radius == 1.15 and first.pulse_exchanges["1"].source_instance_id == _pulse_id and _echo.call("source_phase") == "idle" and _hero.shells == 0, "actual pulse1 precedes Echo and uses the real fixed circle source without ammo"):
		return
	if not await _pause_and_refusal("pulse1-warning"):
		return
	if not await _path(first.pulse_proofs["1"], false):
		return
	if not await _await_stage("echo_wait"):
		return
	if not _expect(_pulse.state().status == "complete" and _pulse.state().cycle == 1 and _pulse.get_cue().state().phase == "clear" and _scheduler.reservations().is_empty(), "first native cycle completes and releases its actual lease before Echo admission"):
		return
	if _first_only:
		print("SCOPE: first-pulse-only stops before the mixed Echo/cycle2 behavior.")
		return
	if not await _await_stage("echo"):
		return
	var admitted: Dictionary = _level.call("state")
	if not _expect(admitted.playback.status == "running" and admitted.echo_lease.source_instance_id == _echo_id and admitted.echo_lease.adapter.kind == "authored_replay" and not admitted.echo_lease.adapter.locked and _pulse.state().cycle == 1 and _pulse.state().status == "complete" and _echo.call("get_apparition") == null and _echo.call("get_enemy_apparition") != null, "same continuous Scheduler admits one genuine unarmed own-Echo after pulse1"):
		return
	for _i: int in range(300):
		if bool(_level.call("state").echo_locked):
			break
		if not await _tick():
			return
	var locked: Dictionary = _level.call("state")
	if not _expect(locked.echo_locked and locked.echo_lease.adapter.locked and locked.echo_proof.get("accepted", false), "actual due lock freshly commits the exclusive authored route and slash"):
		return
	_renderer_start = (_echo.call("get_enemy_apparition") as Node3D).global_position
	if not await _path(locked.echo_proof, true):
		return
	if not _expect(_echo.call("source_phase") == "recovery" and _renderer_travel > 0.1 and _pulse.state().cycle == 1, "real porcelain renderer travelled and recovery remains between the pulses") or not _hit("genuine Echo recovery"):
		return
	if not _expect(not bool(_echo.get("dead")) and float(_echo.get("hp")) > 0.0 and int(_echo.get("source_hits")) == 1, "actual36HP source survives the first ordinary primary without rearming"):
		return
	if not await _await_stage("pulse2_wait"):
		return
	if not _expect(_echo.call("source_phase") == "complete" and not bool(_echo.get("dead")) and _scheduler.reservations().is_empty() and _pulse.state().cycle == 1, "finite Echo genuinely completes and releases its lease before the second pulse"):
		return
	if not await _await_stage("pulse2"):
		return
	var second: Dictionary = _level.call("state")
	if not _expect(second.pulse.cycle == 2 and second.pulse.phase == "warning" and second.pulse_exchanges["2"].source_instance_id == _pulse_id and second.pulse_exchanges["2"].opening_position == _echo.global_position and second.pulse_exchanges["2"].start_s > first.pulse_exchanges["1"].cooldown_until_s and _echo.call("source_phase") == "complete", "the SAME actual mechanism admits native cycle2 with expired original cooldown and the completed living knot opening"):
		return
	if not await _path(second.pulse_proofs["2"], false):
		return
	if not _expect(_echo.call("source_phase") == "complete" and not bool(_echo.get("dead")), "second pulse's proved ordinary-primary position names the actual still-hittable completed knot"):
		return
	if not await _await_stage("complete"):
		return
	var expected_hits: int = int(ceil(36.0 / float(_hero.equipment.resolved_stats().primary_damage)))
	if not _expect(expected_hits >= 2 and expected_hits <= 4, "required ordinary hit count derives from the actual carried core kit"):
		return
	for _i: int in range(expected_hits - 1):
		var wait_s: float = maxf(0.30, float(_hero.get_threat_response_state().primary_cooldown_left_s))
		if not await _until(_scheduler.get_clock() + wait_s) or not _hit("post-pulse completed knot"):
			return
	if not await _portrait("completed-dead-knot") or not await _pause_and_refusal("late-completed-dead"):
		return
	var final: Dictionary = _level.call("state")
	var checkpoints: Dictionary = _level.current_checkpoint()
	var counts: Dictionary = {"dash": 0, "primary": 0}
	for record: Dictionary in _hero.get_world_action_records():
		if not counts.has(record.kind):
			_expect(false, "only real ordinary dash/primary actions occur")
			return
		counts[record.kind] += 1
	var ordered: Array[String] = []
	var previous: float = -1.0
	for entry: Dictionary in final.stage_history:
		ordered.append(entry.id)
		if float(entry.clock_s) < previous:
			_expect(false, "native stage clock never resets")
			return
		previous = float(entry.clock_s)
	if not _expect(ordered == ["pulse1_wait", "pulse1", "echo_wait", "echo", "pulse2_wait", "pulse2", "complete"] and _leases.size() == 3 and counts.dash >= 3 and counts.dash <= 6 and counts.primary == expected_hits and int(_echo.get("source_hits")) == expected_hits and bool(_echo.get("dead")) and _events.count("own_slash") == 1 and _events.count("defeat") == 1 and _events.count("died") == 1 and _pulse.state().cycle == 2 and _pulse.state().status == "complete" and _scheduler.reservations().is_empty() and not _echo.is_in_group("enemies") and _hero.hp == _hp and not _events.has("fired_hurt") and not _events.has("echo_contact") and not _events.has("pulse_hit") and not _events.has("fired_blast") and not _events.has("completion") and not _events.has("checkpoint") and not _events.has("exit") and not _level.is_completed() and checkpoints.id.is_empty() and checkpoints.kind.is_empty() and int(_game.get("cores")) == 0 and int(_game.get("kills")) == 0, "actual pulse1 -> one own Echo -> same-source pulse2 -> real ordinary clear retains continuous history/fullHP/no blast or campaign grant", str(final)):
		return
	for name: String in ["pulse1-warning", "pulse1-lock", "pulse1-active", "pulse1-recovery", "echo-warning", "echo-lock", "echo-active", "echo-recovery", "pulse2-warning", "pulse2-lock", "pulse2-active", "pulse2-recovery"]:
		if not _expect(_phases.has(name), "actual native phase observed: " + name):
			return


func _open() -> bool:
	_game = MainScene.instantiate()
	_game.set("level_scene_path", ROOM)
	root.add_child(_game)
	_game.call("open_bench")
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler if _level != null else null
	_pulse = _level.get("mechanism") as CinderLaneMechanism if _level != null else null
	_echo = _level.get("echo") as Node3D if _level != null else null
	_barrier = Barrier.new()
	_game.add_child(_barrier)
	if not _expect(_level != null and _hero != null and _scheduler != null and _pulse != null and _echo != null and paused and _level.scene_file_path == ROOM and String(_level.get("last_configuration_error")).is_empty(), "actual MainScene installs the bounded mixed room", String(_level.get("last_configuration_error")) if _level != null else "missing level"):
		return false
	_pulse.state_changed.connect(func(value: Dictionary) -> void: _phases["pulse%d-%s" % [value.cycle, value.phase]] = true)
	_pulse.hit_resolved.connect(func(_id: String, _cycle: int, _receipt: Dictionary) -> void: _events.append("pulse_hit"))
	_echo.connect("event_dispatched", func(_event: Dictionary, receipt: Dictionary) -> void:
		_events.append("own_slash")
		if receipt.contact:
			_events.append("echo_contact")
	)
	_echo.connect("source_hit_resolved", func(_receipt: Dictionary) -> void: _events.append("ordinary_hit"))
	_echo.connect("source_defeated", func(_receipt: Dictionary) -> void: _events.append("defeat"))
	_echo.connect("died", func() -> void: _events.append("died"))
	_hero.fired.connect(func(kind: String) -> void: _events.append("fired_" + kind))
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _events.append("completion"))
	_level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: _events.append("checkpoint"))
	_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _events.append("exit"))
	return _expect(_hero.presentation_id == "act3_traveller" and _level.process_physics_priority < _pulse.process_physics_priority and _pulse.process_physics_priority < _echo.process_physics_priority and _barrier.process_physics_priority > _echo.process_physics_priority and not _pulse.has_method("take_damage") and _pulse.get_parent() == _level and _echo.get_parent() == _level, "shared traveller and actual HP-free/source priority90/100/110/postactor1000 contract")


func _await_stage(stage: String) -> bool:
	for _i: int in range(600):
		if _level.call("state").stage == stage:
			return true
		if not await _tick():
			return false
	return _expect(false, "bounded genuine stage reached: " + stage, str(_level.call("state")))


func _path(proof: Dictionary, authored: bool) -> bool:
	if not _expect(proof.get("accepted", false) and not proof.uses_blast and not proof.uses_invulnerability, "complete shared witness uses ordinary escape/primary without blast or invulnerability credit"):
		return false
	var dashes: int = 0
	for segment: Dictionary in proof.path:
		if segment.kind not in ["escape_dash", "positioning_dash", "first_escape_dash", "tether_positioning_dash"]:
			continue
		if not await _until(float(segment.start_s)):
			return false
		var error: String = _swipe((segment.to - segment.from).normalized())
		if not _expect(error.is_empty(), "actual shared viewport swipe starts " + String(segment.kind), error):
			return false
		dashes += 1
		for _i: int in range(80):
			if float(_hero.get_threat_response_state().motion.dash_left_s) == 0.0:
				break
			if not await _tick():
				return false
		if not _expect(float(_hero.get_threat_response_state().motion.dash_left_s) == 0.0 and _hero.global_position.distance_to(segment.to) < 0.005 and _hero.is_on_floor(), "genuine completed dash reaches the native proved floor position"):
			return false
	if not await _until(float(proof.primary_time_s)):
		return false
	return _expect(dashes >= 1 and dashes <= 2 and _hero.global_position.distance_to(proof.attack_position) < 0.005 and (_echo.call("source_phase") == "recovery" if authored else _pulse.state().phase == "recovery"), "actual useful landing/ordinary return reaches its unchanged recovery budget")


func _hit(label: String) -> bool:
	var before: float = float(_echo.get("hp"))
	var previous: int = _hero.get_world_action_records().size()
	var damage: float = float(_hero.equipment.resolved_stats().primary_damage)
	var error: String = _tap((_echo.global_position - _hero.global_position).normalized())
	var records: Array[Dictionary] = _hero.get_world_action_records()
	return _expect(error.is_empty() and records.size() == previous + 1 and records.back().kind == "primary" and records.back().hits == 1 and float(_echo.get("hp")) == maxf(0.0, before - damage), "actual first-tap ordinary hit at " + label, error)


func _until(target: float) -> bool:
	for _i: int in range(1800):
		if _scheduler.get_clock() >= target:
			return _expect(_scheduler.get_clock() <= target + 1.0 / float(Engine.physics_ticks_per_second) + 0.000000001, "input uses the first actual postactor physics tick")
		if not await _tick():
			return false
	return _expect(false, "bounded actual deadline reached")


func _tick() -> bool:
	if paused:
		return _expect(false, "ordinary route never advances a paused unit")
	_barrier.waiting = true
	await _barrier.observed
	var state: Dictionary = _level.call("state")
	var clock: float = _scheduler.get_clock()
	if clock <= _last_clock or clock > 30.0 or _scheduler.get_instance_id() != _scheduler_id or _pulse.get_instance_id() != _pulse_id or _echo.get_instance_id() != _echo_id or _pulse.global_transform != _pulse_origin or _echo.global_transform != _echo_origin or _hero.hp != _hp or _hero.dead or not _exact(_kit, _hero.equipment.snapshot()) or not String(state.configuration_error).is_empty() or _events.has("pulse_hit") or _events.has("echo_contact") or _events.has("fired_blast"):
		return _expect(false, "actual actors/resources/clock remain continuous and harmless", str(state))
	_last_clock = clock
	var held: Array[Dictionary] = _scheduler.reservations()
	if held.size() > 1:
		return _expect(false, "finite mixed stages never overlap committed source leases")
	for record: Dictionary in held:
		_leases[record.id] = {"source_instance_id": record.source_instance_id, "start_s": record.start_s}
	var phase: String = _echo.call("source_phase")
	if state.stage == "echo" and phase in ["warning", "lock", "active", "recovery"]:
		_phases["echo-" + phase] = true
		if phase == "active":
			_renderer_travel = maxf(_renderer_travel, (_echo.call("get_enemy_apparition") as Node3D).global_position.distance_to(_renderer_start))
	var label: String = ""
	if state.stage in ["pulse1", "pulse2"]:
		label = String(state.stage) + "-" + String(state.pulse.phase)
	elif state.stage == "echo" and phase in ["warning", "lock", "active", "recovery"]:
		label = "echo-" + phase
	if not label.is_empty():
		var error: String = _game.call("camera_framing_error", _level.camera_framing_points())
		if not error.is_empty():
			return _expect(false, "actual held source/whole footprint/Hero/landing remain in native view", error)
		if _capture and not await _portrait(label):
			return false
	return true


func _observation() -> Dictionary:
	var cues: Array = [_pulse.get_cue().state()]
	for cue: Node3D in _echo.call("get_cues"):
		cues.append(cue.call("state"))
	var renderer: Node3D = _echo.call("get_enemy_apparition") as Node3D
	return {"hero": _hero.snapshot_state(), "hero_transform": _hero.global_transform, "velocity": _hero.velocity, "dash": _hero.get_committed_dash_state(), "kit": _hero.equipment.snapshot(), "state": _level.call("state"), "renderer": renderer.global_transform, "source": _echo.global_transform, "pulse": _pulse.global_transform, "cues": cues, "leases": _scheduler.reservations(), "events": _events.duplicate(), "camera": (_game.get("camera") as Camera3D).global_transform, "anchor": _game.call("get_aim_anchor_normalized"), "hud": _hud_observation(_game.get("hud") as Node)}


func _hud_observation(node: Node) -> Dictionary:
	var result: Dictionary = {"instance_id": node.get_instance_id(), "children": []}
	if node is CanvasItem:
		result.visible = (node as CanvasItem).is_visible_in_tree()
	if node is Control:
		result.rect = (node as Control).get_global_rect()
	if node is Label:
		result.text = (node as Label).text
	for child: Node in node.get_children():
		result.children.append(_hud_observation(child))
	return result


func _visible_labels(node: Node) -> Array[String]:
	var result: Array[String] = []
	if node is Label and (node as Label).is_visible_in_tree():
		result.append((node as Label).text)
	for child: Node in node.get_children():
		result.append_array(_visible_labels(child))
	return result


func _hud_truth_error() -> String:
	var labels: Array[String] = _visible_labels(_game.get("hud") as Node)
	if not labels.has("HP  %d / %d" % [int(roundf(_hero.hp)), int(roundf(_hero.max_hp))]) or not labels.has("SHELLS  %d / %d" % [_hero.shells, _hero.max_shells]) or not labels.has(_level.objective_text.to_upper()):
		return "Ordinary current HUD must show actual HP/ammo and this real level objective: " + str(labels)
	return ""


func _refuse_save(label: String) -> bool:
	var before: Dictionary = _observation()
	var saved_hero: Dictionary = _hero.snapshot_state()
	var empty: Dictionary = _level.snapshot_state()
	return _expect(paused and not saved_hero.is_empty() and _hero.snapshot_error(saved_hero).is_empty() and empty.is_empty() and _level.last_snapshot_error.contains("whole-unit") and not _level.snapshot_error({}).is_empty() and not _level.snapshot_error_with_player({}, saved_hero).is_empty() and not _level.restore_state({}) and _exact(before, _observation()), "explicit unsupported whole-unit save/restore refusal leaves real " + label + " untouched")


func _pause_and_refusal(label: String) -> bool:
	if not _expect(_game.call("request_pause_deferred"), "public Game requests a complete-tick pause at " + label):
		return false
	for _i: int in range(4):
		await process_frame
	if not _expect(paused and not _game.call("is_pause_requested"), "actual deferred pause settles outside actor transactions") or not await _refuse_save(label):
		return false
	var before: Dictionary = _observation()
	await process_frame
	await process_frame
	if not _expect(_exact(before, _observation()), "ordinary pause freezes the whole mixed native unit without claiming persistence"):
		return false
	_game.call("resume_lab")
	return true


func _portrait(label: String) -> bool:
	if not _capture or _captures.has(label):
		return true
	# Let this real frame's ordinary Game HUD/camera update finish before the
	# TEST ONLY freeze. Do not call private HUD updates or manufacture its text.
	if not paused:
		await RenderingServer.frame_post_draw
	var previous: bool = paused
	paused = true # TEST ONLY draw freeze; no input/camera/menu/runtime alteration.
	var before: Dictionary = _observation()
	await process_frame
	await RenderingServer.frame_post_draw
	var error: String = _game.call("camera_framing_error", _level.camera_framing_points())
	if error.is_empty():
		error = _hud_truth_error()
	var image: Image = root.get_texture().get_image()
	var ok: bool = not before.hero.is_empty() and error.is_empty() and _exact(before, _observation()) and image != null and image.get_size() == Vector2i(339, 736)
	if ok:
		var directory: String = ProjectSettings.globalize_path(CAPTURES)
		ok = DirAccess.make_dir_recursive_absolute(directory) == OK and image.save_png(directory.path_join(label + ".png")) == OK
	paused = previous
	if ok:
		_captures[label] = true
		print("PORTRAIT: ", ProjectSettings.globalize_path(CAPTURES).path_join(label + ".png"))
	return _expect(ok, "unchanged actual native339x736 portrait " + label, error)


func _swipe(direction: Vector3) -> String:
	var size: Vector2 = root.get_visible_rect().size
	var start: Vector2 = size * Vector2(0.5, 0.60)
	var finish: Vector2 = start + _screen_direction(direction) * size.x * 0.22
	if direction.is_zero_approx() or not root.get_visible_rect().has_point(finish) or finish.y < 100.0:
		return "Actual shared release cannot fit viewport gesture region"
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
	return "" if float(_hero.get_threat_response_state().motion.dash_left_s) > 0.0 and (_game.call("get_aim_anchor_normalized") as Vector2).distance_to(finish / size) < 0.000001 else "Actual router did not start dash and retain final release anchor"


func _tap(direction: Vector3) -> String:
	var point: Vector2 = _game.call("get_aim_anchor") + _screen_direction(direction) * 60.0
	if direction.is_zero_approx() or not root.get_visible_rect().has_point(point) or point.y < 100.0:
		return "Actual ordinary tap cannot fit final-release aim region"
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


func _exact(left: Variant, right: Variant) -> bool:
	if typeof(left) != typeof(right):
		return false
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
		for i: int in range(left.size()):
			if not _exact(left[i], right[i]):
				return false
		return true
	if typeof(left) not in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_VECTOR2, TYPE_VECTOR3, TYPE_BASIS, TYPE_TRANSFORM3D, TYPE_COLOR, TYPE_AABB]:
		return false
	return var_to_bytes(left) == var_to_bytes(right) # Native type/scalar bits; no empty-JSON equality.


func _close() -> void:
	var old: WeakRef = weakref(_game) if is_instance_valid(_game) else null
	var source: WeakRef = weakref(_echo) if is_instance_valid(_echo) else null
	var pulse: WeakRef = weakref(_pulse) if is_instance_valid(_pulse) else null
	if is_instance_valid(_level):
		_level.exit_level()
		if is_instance_valid(_scheduler):
			_expect(_scheduler.reservations().is_empty(), "public exit clears the actual shared Scheduler leases")
	if is_instance_valid(_barrier):
		_barrier.waiting = false
	if is_instance_valid(_game):
		_game.queue_free()
	paused = false
	for _i: int in range(5):
		await process_frame
	if old != null:
		_expect(old.get_ref() == null and (source == null or source.get_ref() == null) and (pulse == null or pulse.get_ref() == null) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "actual world/owners/cues/groups retire cleanly")
	_game = null
	_level = null
	_hero = null
	_scheduler = null
	_pulse = null
	_echo = null
	_barrier = null


func _finish() -> void:
	await _close()
	await create_timer(0.15, true, false, true).timeout
	print("Mirror mixed finite room: %d checks; failures: %d. %s; no ring/whole-save/full-L3 acceptance." % [_checks, _failures, "first pulse only" if _first_only else "pulse1/one actual Echo/pulse2"])
	quit(0 if _failures == 0 else 1)


func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	if ok:
		print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok
