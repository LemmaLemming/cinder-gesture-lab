extends SceneTree
## Finite first C52 actual MainScene consumer. No repeated cycle, production
## Shell/menu/input reconstruction, full Mirror Sea, native OS or human claim.
const MainScene = preload("res://scenes/main.tscn")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const RoomPath: String = "res://scenes/acts/act3/a3_l3_echo_rule_room.tscn"
const CapturePath: String = "res://.cinder/mirror-echo-rule-portraits"

class Barrier extends Node:
	signal observed
	var waiting: bool = false
	func _ready() -> void:
		process_physics_priority = 1000
	func _physics_process(_delta: float) -> void:
		if waiting:
			waiting = false
			observed.emit()

var _game: Node
var _hero: CinderPlayer
var _level: CinderLevel
var _source: Node3D
var _scheduler: CinderThreatScheduler
var _barrier: Barrier
var _checks: int = 0
var _failures: int = 0
var _hp: float = 0.0
var _kit: Dictionary = {}
var _capture: bool = false
var _captures: Dictionary = {}
var _events: Array[String] = []
var _phases: Dictionary = {}
var _knot: Transform3D
var _travel: float = 0.0
var _active_origin: Vector3 = Vector3.ZERO
var _active_seen: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_capture = "--capture-portraits" in OS.get_cmdline_user_args()
	if _capture and not _expect(DisplayServer.get_name() != "headless", "actual portraits require graphical native rendering"):
		quit(1)
		return
	for extreme: bool in [false, true]:
		if not await _case(extreme):
			break
		await _close()
	await _close()
	print("Mirror Echo owned rule room: %d checks; failures: %d. Finite actual C52 only; no full-level or lifecycle29 acceptance." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _open(extreme: bool, quiet: bool = false) -> bool:
	paused = quiet
	_game = MainScene.instantiate()
	if not extreme:
		_game.set("level_scene_path", RoomPath)
	root.add_child(_game)
	if extreme:
		# Use the actual enemy-free paused lab bench, then public carryover.
		# The entered Echo room correctly forbids clothing changes.
		var lab_hero: CinderPlayer = _game.get("player") as CinderPlayer
		if not _expect(lab_hero != null and _game.call("is_lab_level") and get_nodes_in_group("enemies").is_empty(), "actual initial lab provides enemy-free equipment boundary"):
			return false
		_game.call("open_bench")
		for id: String in ["CLOTH-J1", "CLOTH-P2", "CLOTH-S2", "WEAPON-04"]:
			if not _expect(lab_hero.equip_item(id), "legal initial slow/long/weak kit selects " + id):
				return false
		if not _expect(paused and _game.call("load_level_scene", RoomPath), "public paused scene transition carries selected legal kit"):
			return false
	_barrier = Barrier.new()
	root.add_child(_barrier)
	_hero = _game.get("player") as CinderPlayer
	_level = _game.get("active_level") as CinderLevel
	_source = _level.get("echo") as Node3D if _level != null else null
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler if _level != null else null
	if not _expect(_hero != null and _source != null and _scheduler != null and _level.scene_file_path == RoomPath and String(_level.get("last_configuration_error")).is_empty(), "actual MainScene binds owned finite C52 room", String(_level.get("last_configuration_error")) if _level != null else "level missing"):
		return false
	_game.call("open_bench")
	if not quiet:
		_hero.shells = 0 # Disclosed public TEST ONLY initial no-ammo condition.
		_hp = _hero.hp
		_kit = _hero.equipment.snapshot()
		_knot = _source.global_transform
		_events.clear()
		_phases.clear()
		_travel = 0.0
		_active_seen = false
	_source.connect("event_dispatched", func(_event: Dictionary, _receipt: Dictionary) -> void: _events.append("slash_opportunity"))
	_source.connect("source_hit_resolved", func(_result: Dictionary) -> void: _events.append("ordinary_hit"))
	_source.connect("source_defeated", func(_result: Dictionary) -> void: _events.append("defeat"))
	_source.connect("state_changed", func(_value: Dictionary) -> void: _events.append("state"))
	_hero.fired.connect(func(kind: String) -> void: _events.append("fired_" + kind))
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _events.append("completion"))
	_level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _boundary: String) -> void: _events.append("checkpoint"))
	if not quiet:
		_game.call("resume_lab")
	return true

func _case(extreme: bool) -> bool:
	if not await _open(extreme):
		return false
	for _i: int in range(120):
		if bool(_level.call("state").admitted):
			break
		if not await _tick():
			return false
	var original: Dictionary = _level.call("state")
	if not _expect(original.admitted and original.playback.status == "running" and original.lease.adapter.kind == "authored_replay" and not original.lease.adapter.locked and _source.call("get_apparition") == null and _source.call("get_enemy_apparition") != null and _source.call("preview_state").static_loadouts.is_empty() and float(_source.get("hp")) == 36.0 and _hero.shells == 0, "real stationary HP/lease/native-renderer owner admits one enemy-authored warning without Player art/capture/ammo", original.admission_reason + "; " + original.camera_error):
		return false
	if not extreme:
		if not await _warning_restore():
			return false
	if _capture:
		# Let the actual unpaused Game frame update HUD/camera after restore.
		# Freeze only after it draws; never fabricate UI or hide its overlays.
		await RenderingServer.frame_post_draw
		if not _expect(_source.call("source_phase") == "warning", "actual rendered HUD refresh still precedes due lock"):
			return false
	if not await _portrait(("slow-" if extreme else "default-") + "warning"):
		return false
	for _i: int in range(240):
		if bool(_level.call("state").locked):
			break
		if not await _tick():
			return false
	var held: Dictionary = _level.call("state")
	var proof: Dictionary = held.proof
	if not _expect(held.locked and held.playback.status == "running" and held.lease.adapter.locked and proof.get("accepted", false), "actual due lock reproves full warning/lead/escape/return with current Hero", held.admission_reason + "; " + held.camera_error):
		return false
	print("OWNED PROOF: ", proof)
	for segment: Dictionary in proof.path:
		if segment.kind not in ["first_escape_dash", "tether_positioning_dash"]:
			continue
		if not await _until(float(segment.start_s)):
			return false
		var error: String = _swipe((segment.to - segment.from).normalized())
		if not _expect(error.is_empty(), "shared viewport swipe starts actual " + String(segment.kind), error):
			return false
		for _i: int in range(80):
			if float(_hero.get_threat_response_state().motion.dash_left_s) == 0.0:
				break
			if not await _tick():
				return false
		if not _expect(_hero.global_position.distance_to(segment.to) < 0.005 and _source.global_transform == _knot, "real completed dash reaches proof landing while actual HP knot stays fixed"):
			return false
	if not await _until(float(proof.primary_time_s)):
		return false
	if not _expect(String(_source.call("source_phase")) == "recovery" and _hero.global_position.distance_to(proof.attack_position) < 0.005 and _travel > 0.1 and _phases.has("warning") and _phases.has("lock") and _phases.has("active") and _phases.has("recovery"), "harmless native apparition travelled; Hero returns to reachable ordinary recovery position"):
		return false
	if not await _hit("recovery"):
		return false
	if not _expect(not bool(_source.get("dead")) and float(_source.get("hp")) > 0.0 and _events.count("ordinary_hit") == 1, "36HP source genuinely survives first ordinary hit without lease reset"):
		return false
	for _i: int in range(240):
		if String(_source.call("source_phase")) == "complete":
			break
		if not await _tick():
			return false
	if not _expect(String(_source.call("source_phase")) == "complete" and not bool(_source.get("dead")) and _scheduler.reservations().is_empty(), "finite live source completes original recovery and remains the same reachable knot"):
		return false
	if not await _portrait(("slow-" if extreme else "default-") + "completed-alive"):
		return false
	var damage: float = float(_hero.equipment.resolved_stats().primary_damage)
	var expected_hits: int = int(ceil(36.0 / damage))
	if not _expect(expected_hits >= 2 and expected_hits <= 4, "bounded ordinary hit count derives from the actual carried kit"):
		return false
	for _i: int in range(expected_hits - 1):
		# Wait for the actual public primary readiness and beyond the existing
		# double-tap window; this never changes ammo or attack timing.
		var wait_s: float = maxf(0.30, float(_hero.get_threat_response_state().primary_cooldown_left_s))
		if not await _until(_scheduler.get_clock() + wait_s) or not await _hit("complete"):
			return false
	if not _expect(bool(_source.get("dead")) and float(_source.get("hp")) == 0.0 and int(_source.get("source_hits")) == expected_hits and _events.count("defeat") == 1 and not _source.is_in_group("enemies") and _source.global_transform == _knot and _hero.hp == _hp and _scheduler.reservations().is_empty(), "genuine post-complete ordinary hits defeat same stationary knot with no damage/reward/rearm"):
		return false
	var actions: Array[Dictionary] = _hero.get_world_action_records()
	var counts: Dictionary = {"dash": 0, "primary": 0}
	for action: Dictionary in actions:
		if not counts.has(action.kind):
			return _expect(false, "ordinary no-blast route has only executed dash/primary records")
		counts[action.kind] += 1
	if not _expect(counts.dash == 2 and counts.primary == expected_hits and _events.count("slash_opportunity") == 1 and not _events.has("fired_blast") and not _events.has("completion") and not _events.has("checkpoint") and int(_game.get("cores")) == 0 and int(_game.get("kills")) == 0, "exact native history has two dashes/kit-required ordinary hits/one own slash opportunity and no progression"):
		return false
	# Late dead snapshots belong to the separately requested lifecycle30 seam.
	print("LIMIT: late completed-dead production checkpoint not claimed by this finite shared28 route.")
	return true

func _warning_restore() -> bool:
	_game.call("request_pause_deferred")
	await process_frame
	await process_frame
	var pair: Dictionary = _pair()
	var wire: String = Exact.stringify(pair)
	var read: Dictionary = Exact.parse(wire)
	if not _expect(not pair.hero.is_empty() and not pair.level.is_empty() and not wire.is_empty() and read.get("accepted", false) and _exact(pair, read.value), "deferred warning captures exact complete native Hero/source/Scheduler/projected Playback unit", _hero.last_snapshot_error + "; " + _level.last_snapshot_error):
		return false
	for kind: String in ["clock", "generation", "hp", "native", "view", "unknown"]:
		var bad: Dictionary = pair.duplicate(true)
		match kind:
			"clock": bad.level.local.source.clock_s += 0.0001
			"generation": bad.level.local.source.generation = float(bad.level.local.source.generation)
			"hp": bad.level.local.source.hp = -0.1
			"native": bad.level.local.source.native["foreign"] = true
			"view": bad.level.local.view.positions[0][0] = 100.0
			"unknown": bad.level.local["foreign"] = {}
		var before: Dictionary = _observation()
		var error: String = _level.snapshot_error_with_player(bad.level, bad.hero)
		if not _expect(not error.is_empty() and not _level.restore_state(bad.level) and _exact(before, _observation()), "complete pure/restore rejects forged " + kind + " without native mutation", error):
			return false
	var events: Array[String] = _events.duplicate()
	await _close()
	if not await _open(false, true):
		return false
	var before: Dictionary = _observation(false)
	var error: String = _hero.snapshot_error(pair.hero)
	if error.is_empty():
		error = _level.snapshot_error_with_player(pair.level, pair.hero)
	if not _expect(error.is_empty() and _exact(before, _observation(false)), "fresh zero-tick actor fully prevalidates saved native warning pair purely", error):
		return false
	_events.clear()
	if not _expect(_hero.restore_state(pair.hero) and _level.restore_state(pair.level) and _events.is_empty() and _exact(pair, _pair()), "fresh quiet Hero→source→Scheduler→Playback reconstruction is exact/event-free", _level.last_snapshot_error):
		return false
	_events = events
	_game.call("resume_lab")
	return true

func _hit(phase: String) -> bool:
	var before: float = float(_source.get("hp"))
	var damage: float = float(_hero.equipment.resolved_stats().primary_damage)
	var previous: int = _hero.get_world_action_records().size()
	var error: String = _tap((_source.global_position - _hero.global_position).normalized())
	var records: Array[Dictionary] = _hero.get_world_action_records()
	return _expect(error.is_empty() and records.size() == previous + 1 and records.back().kind == "primary" and records.back().hits == 1 and float(_source.get("hp")) == maxf(0.0, before - damage), "actual final-release-aim first tap applies one ordinary primary at " + phase, error)

func _until(target: float) -> bool:
	for _i: int in range(1800):
		if _scheduler.get_clock() >= target:
			return _expect(_scheduler.get_clock() - target <= 1.0 / Engine.physics_ticks_per_second + 0.000001, "actual action uses first available native tick")
		if not await _tick():
			return false
	return _expect(false, "finite actual action deadline reached")

func _tick() -> bool:
	if paused:
		return _expect(false, "route observation never advances paused actors")
	_barrier.waiting = true
	await _barrier.observed
	var phase: String = _source.call("source_phase")
	_phases[phase] = true
	var render: Node3D = _source.call("get_enemy_apparition") as Node3D
	if render != null and phase == "active":
		if not _active_seen:
			_active_origin = render.global_position
			_active_seen = true
		_travel = maxf(_travel, render.global_position.distance_to(_active_origin))
	var error: String = String(_level.get("last_configuration_error"))
	if not error.is_empty() or _hero.hp != _hp or _hero.dead or _source.global_transform != _knot or not _exact(_kit, _hero.equipment.snapshot()) or _events.has("fired_blast") or _scheduler.get_clock() > 30.0 or String(_source.call("source_phase")) == "cancelled":
		return _expect(false, "finite own exchange preserves real actor/resources/custody", error + "; " + str(_level.call("state")))
	if _capture and phase in ["lock", "active", "recovery"]:
		return await _portrait(("slow-" if _kit.get("weapon") == "WEAPON-04" else "default-") + phase)
	return true

func _pair() -> Dictionary:
	return {"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}

func _observation(paired: bool = true) -> Dictionary:
	return {"pair": _pair() if paired else {}, "source": _source.call("get_source_state"), "playback": _source.call("state"), "renderer": (_source.call("get_enemy_apparition") as Node3D).global_transform, "hero": _hero.global_transform, "velocity": _hero.velocity, "leases": _scheduler.reservations(), "clock": _scheduler.get_clock(), "events": _events.duplicate(), "camera": (_game.get("camera") as Camera3D).global_transform, "anchor": _game.call("get_aim_anchor_normalized")}

func _portrait(label: String) -> bool:
	if not _capture or _captures.has(label):
		return true
	var previous: bool = paused
	paused = true # TEST ONLY render freeze; no pause panel is opened/hidden.
	var before: Dictionary = _observation()
	await process_frame
	await RenderingServer.frame_post_draw
	var view: String = _game.call("camera_framing_error", _level.call("camera_framing_points"))
	var image: Image = root.get_texture().get_image()
	var ok: bool = not before.pair.hero.is_empty() and not before.pair.level.is_empty() and view.is_empty() and _exact(before, _observation()) and image != null and image.get_size() == Vector2i(339, 736)
	if ok:
		var directory: String = ProjectSettings.globalize_path(CapturePath)
		ok = DirAccess.make_dir_recursive_absolute(directory) == OK and image.save_png(directory.path_join(label + ".png")) == OK
	paused = previous
	if ok:
		_captures[label] = true
		print("PORTRAIT: ", ProjectSettings.globalize_path(CapturePath).path_join(label + ".png"))
	return _expect(ok, "unchanged complete native portrait " + label, view + "; " + _level.last_snapshot_error)

func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	if ok:
		print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok

func _close() -> void:
	var old: WeakRef = weakref(_game) if is_instance_valid(_game) else null
	if is_instance_valid(_level):
		_level.exit_level()
	if is_instance_valid(_barrier):
		_barrier.waiting = false
		_barrier.queue_free()
	if is_instance_valid(_game):
		_game.queue_free()
	paused = false
	for _i: int in range(5):
		await process_frame
	if old != null:
		_expect(old.get_ref() == null and get_nodes_in_group("enemies").is_empty(), "actual source/world/leases/groups retire before replacement")
	_game = null
	_hero = null
	_level = null
	_source = null
	_scheduler = null
	_barrier = null

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
