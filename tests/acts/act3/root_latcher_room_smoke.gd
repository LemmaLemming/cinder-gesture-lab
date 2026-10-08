extends SceneTree
## Owned fixed-strip scaffold, not canonical crescent/full-level acceptance.
## Uses the real shared shell/Player/consumer, public mechanic calls and a
## post-actor fixed-tick barrier. No native gesture or human balance claim.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const RoomPath: String = "res://scenes/acts/act3/a3_l2_root_room.tscn"
const ForestRoomPath: String = "res://scenes/acts/act3/a3_l2_forest_root_room.tscn"
const ExactJson = preload("res://scripts/campaign/exact_json.gd")

class PostActorBarrier:
	extends Node
	signal completed
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 1000
	func _physics_process(_delta: float) -> void:
		completed.emit()
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PAUSED:
			completed.emit.call_deferred()

var _checks: int = 0
var _failures: int = 0
var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _source: StaticBody3D
var _scheduler: CinderThreatScheduler
var _barrier: PostActorBarrier
var _blasts: int = 0
var _deaths: int = 0
var _capture_portraits: bool = false
var _capture_index: int = 0
var _capture_warning_only: bool = false
var _room_path: String = RoomPath
var _capture_directory: String = "res://.cinder/root-strip-portraits-shared22"
var _blue_forest_sun: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--capture-portraits":
			_capture_portraits = true
		elif argument == "--capture-warning-only":
			_capture_portraits = true
			_capture_warning_only = true
		elif argument == "--forest-room":
			_room_path = ForestRoomPath
			_capture_directory = "res://.cinder/root-strip-forest-portraits-shared22"
		elif argument == "--blue-forest-sun":
			_blue_forest_sun = true
		else:
			_expect(false, "unknown owned selector: " + argument)
	if _blue_forest_sun:
		if not _expect(_room_path == ForestRoomPath, "blue forest presentation selector requires the actual forest scaffold"):
			await _finish()
			return
		_capture_directory += "-alppain"
	if _capture_portraits:
		if not _expect(DisplayServer.get_name() != "headless", "portrait capture requires an actual graphical renderer"):
			await _finish()
			return
		# Reuse the project's tested340x736 native window profile. Forcing both
		# macOS DisplayServer and Window sizes independently rounded this host
		# to338x736 and rendered339x734; that is not the requested capture.
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_directory))
	_game = MainScene.instantiate()
	_game.set("level_scene_path", _room_path)
	root.add_child(_game)
	_barrier = PostActorBarrier.new()
	_game.add_child(_barrier)
	await _ticks(12)
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _expect(_level != null and _hero != null and _level.scene_file_path == _room_path, "real shared shell opens the selected isolated Root strip scaffold"):
		await _finish()
		return
	_source = _level.get("root_latcher") as StaticBody3D
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	if not _expect(_source != null and _scheduler != null and _source.has_method("get_mechanism"), "actual fixed attackable bulb composes shared stationary consumer"):
		await _finish()
		return
	_expect(String(_level.get("last_configuration_error")).is_empty(), "authored live bindings configure without an error")
	if _room_path == ForestRoomPath:
		var scenery: Node3D = _level.get("forest_scenery") as Node3D
		if not _expect(scenery != null and String(scenery.call("runtime_error")).is_empty(), "actual forest floor, collision and native scenery dependencies remain intact"):
			await _finish()
			return
		if _blue_forest_sun:
			# TEST ONLY public scenery state selection; this strip room has no
			# campaign sun clock. No gameplay state or timings are modified.
			scenery.call("show_sun", 1, "hold")
	_expect(_hero.presentation_id == "act3_traveller" and _hero.is_on_floor(), "one actual traveller stands on continuous firm floor")
	_expect(_source.is_in_group("enemies") and _source.collision_layer == 2, "fixed live bulb participates in ordinary enemy primary targeting")
	var collision: CollisionShape3D = _source.get_node_or_null("BodyCollision") as CollisionShape3D
	var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D if collision != null else null
	_expect(capsule != null and is_equal_approx(capsule.radius, 0.32) and is_equal_approx(capsule.height, 0.64), "actual low capsule uses legal native .32 radius/.64 total height")
	_hero.fired.connect(func(kind: String) -> void: _blasts += int(kind == "blast"))
	_source.connect("died", func(_position: Vector3) -> void: _deaths += 1)
	_hero.shells = 0
	var hp: float = _hero.hp
	var root_position: Vector3 = _source.global_position
	var warning: Dictionary = await _wait_phase("warning", 5.0)
	if warning.is_empty():
		await _finish()
		return
	var reservation_id: String = String(warning.mechanism.reservation_id)
	var reservation: Dictionary = _scheduler.reservation_state(reservation_id)
	_expect(not reservation.is_empty() and reservation.geometry.kind == "lane", "real scheduler allocates supported strip, never claims a crescent")
	await _capture("warning", "warning")
	if _capture_warning_only:
		await _finish()
		return
	var source_hp: float = _source.hp
	_hero.slash(Vector3.FORWARD)
	_expect(_source.hp == source_hp and _hero.last_action.hits == 0, "ordinary immediate primary cannot damage the closed knot during warning")
	var locked: Dictionary = await _wait_phase("lock", 3.0)
	if locked.is_empty():
		await _finish()
		return
	_expect(_source.global_position == root_position and _scheduler.reservation_state(reservation_id).geometry == reservation.geometry, "fixed source/geometry do not track before lock")
	await _capture("lock", "lock")
	await _pause_check()
	_hero.request_dash(Vector3.RIGHT)
	await _wait_idle_dash(1.0)
	_expect(_hero.global_position.x > 2.5 and _source.global_position == root_position, "actual ordinary swipe mechanic escapes to a useful flank without moving the rooted source")
	_expect(_scheduler.reservation_state(reservation_id).geometry == reservation.geometry, "completed dash does not retarget locked strip")
	await _capture("flank-landing", "lock")
	var active: Dictionary = await _wait_phase("active", 2.0)
	if active.is_empty():
		await _finish()
		return
	await _capture("active", "active")
	var recovery: Dictionary = await _wait_phase("recovery", 2.0)
	if recovery.is_empty():
		await _finish()
		return
	_expect(_hero.hp == hp, "shared continuous-path damage consumer respects actual lateral escape")
	await _capture("recovery-opening", "recovery")
	var return_direction: Vector3 = root_position - _hero.global_position
	return_direction.y = 0
	_hero.request_dash(return_direction.normalized())
	await _wait_idle_dash(1.0)
	_expect(String((_source.call("state") as Dictionary).phase) == "recovery" and _hero.global_position.distance_to(root_position) < 1.8, "real return dash reaches the low ordinary-primary recovery opening")
	await _capture("ordinary-return", "recovery")
	_hero.shells = 0
	var attack_direction: Vector3 = root_position - _hero.global_position
	attack_direction.y = 0
	_hero.slash(attack_direction.normalized())
	_expect(_source.hp == 0 and bool((_source.call("state") as Dictionary).dead) and _hero.last_action.hits == 1, "one real starter primary severs the exposed20HP knot with no blast ammo")
	_expect(_deaths == 1 and not _source.is_in_group("enemies") and _source.collision_layer == 0, "defeat removes attackable/collision authority and emits exactly one death")
	_expect((_source.call("get_mechanism") as CinderLaneMechanism).state().phase == "clear" and _scheduler.reservation_state(reservation_id).is_empty(), "defeat cancels the exact stationary lease and clears shared danger cues")
	await _capture("spent", "defeated")
	await _ticks(30)
	_expect(_hero.hp == hp and _blasts == 0 and _deaths == 1, "spent source stays harmless without recurring damage, blast or duplicate death")
	await _finish()


func _pause_check() -> void:
	_game.call("open_bench")
	await process_frame
	var source: Dictionary = _source.call("state")
	var clock: float = _scheduler.get_clock()
	var player: Dictionary = _hero.get_threat_response_state()
	for _i: int in range(5):
		await process_frame
	_expect(paused and _scheduler.get_clock() == clock and _source.call("state") == source and _hero.get_threat_response_state() == player, "actual manual pause freezes scheduler/source/player clocks and states")
	_game.call("resume_lab")
	_expect(not paused, "shared public resume returns the existing paused exchange")


func _capture(label: String, expected_phase: String) -> void:
	if not _capture_portraits:
		return
	if not _expect(String((_source.call("state") as Dictionary).phase) == expected_phase, "actual captured " + label + " has its declared phase"):
		return
	var was_paused: bool = paused
	paused = true # TEST ONLY freeze, without adding a pause overlay to the image.
	var clock: float = _scheduler.get_clock()
	var player: Dictionary = _hero.get_threat_response_state()
	await process_frame
	await RenderingServer.frame_post_draw
	var viewport_image: Image = root.get_texture().get_image()
	_capture_index += 1
	var path: String = ProjectSettings.globalize_path(_capture_directory + "/%02d-%s.png" % [_capture_index, label])
	var save_error: Error = viewport_image.save_png(path) if viewport_image != null and not viewport_image.is_empty() else ERR_INVALID_DATA
	print("CAPTURE DIAGNOSTIC: image=%s window=%s root=%s save_error=%s" % [viewport_image.get_size() if viewport_image != null else Vector2i.ZERO, DisplayServer.window_get_size(), root.size, save_error])
	_expect(viewport_image != null and viewport_image.get_size() == Vector2i(339, 736) and save_error == OK, "save unchanged actual339x736 " + label + " viewport")
	_expect(_scheduler.get_clock() == clock and _hero.get_threat_response_state() == player and String((_source.call("state") as Dictionary).phase) == expected_phase, "capture freeze preserves actual simulation state for " + label)
	print("PORTRAIT: " + path)
	paused = was_paused


func _wait_phase(phase: String, seconds: float) -> Dictionary:
	for _i: int in range(int(ceil(seconds * Engine.physics_ticks_per_second)) + 2):
		var state: Dictionary = _source.call("state")
		if String(state.get("phase", "")) == phase:
			_expect(true, "real consumer reaches " + phase)
			return state
		await _ticks(1)
	_expect(false, "timed out waiting for " + phase + ": " + str(_source.call("state")))
	return {}


func _wait_idle_dash(seconds: float) -> void:
	for _i: int in range(int(ceil(seconds * Engine.physics_ticks_per_second)) + 2):
		await _ticks(1)
		if not _hero.get_committed_dash_state().get("active", false):
			return
	_expect(false, "actual dash failed to finish within supported bound")


func _ticks(count: int) -> void:
	for _i: int in range(count):
		if paused:
			await process_frame
		else:
			await _barrier.completed


func _expect(condition: bool, label: String) -> bool:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + label)
	else:
		print("PASS: " + label)
	return condition


func _finish() -> void:
	paused = false
	if is_instance_valid(_game):
		_game.queue_free()
	for _i: int in range(5):
		await process_frame
	print("Root strip scaffold checks: %d; failures: %d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
