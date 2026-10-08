extends SceneTree
## Actual owned room/shared player/native-camera guard fixture.
## Native Camera3D size/h_offset mutations are intentional negative inputs only.
## No player/source teleport, saved-state fabrication, private camera update,
## guard disabling or direct damage call. This establishes scoped guard fairness,
## not portrait art acceptance, gesture/human play or full-level acceptance.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const RoomPath: String = "res://scenes/acts/act3/a3_l1_stalker_room.tscn"
const SourcePath: String = "res://scripts/acts/act3/sunbound_stalker.gd"
const Geometry: GDScript = preload("res://scripts/combat/threat_geometry.gd")
const WarningWaitS: float = 4.0
const TinyWidth: float = 0.5
const UnsupportedOffset: float = 24.0

var _checks: int = 0
var _failures: int = 0
var _case: String = ""
var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _source: CharacterBody3D
var _scheduler: CinderThreatScheduler
var _camera: Camera3D
var _normal_width: float = 0.0
var _hp_before: float = 0.0
var _source_hp_before: float = 0.0
var _hit_results: Array[Dictionary] = []
var _invalidations: Array[Dictionary] = []
var _warning_events: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var selected: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument not in ["--admission-only", "--cancel-only"] or not selected.is_empty():
			_expect(false, "one supported focused selector: --admission-only or --cancel-only")
			_finish()
			return
		selected = argument
	if selected.is_empty() or selected == "--admission-only":
		await _admission_case()
	# Stop at the first meaningful failure; the preceding case always disposes.
	if _failures == 0 and (selected.is_empty() or selected == "--cancel-only"):
		await _cancel_case()
	_finish()


func _open_case(label: String, bad_width: bool) -> bool:
	_case = label
	print("CASE: " + label)
	_hit_results.clear()
	_invalidations.clear()
	_warning_events = 0
	_game = MainScene.instantiate()
	_game.set("level_scene_path", RoomPath)
	root.add_child(_game)
	# The actual shared shell constructs all bindings synchronously; set the
	# negative native camera property before the first source physics tick.
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	_camera = _game.get("camera") as Camera3D
	if not _expect(_level != null and _hero != null and _camera != null and _level.scene_file_path == RoomPath and _level.contract_error().is_empty(), "actual MainScene enters the owned isolated room"):
		return false
	_source = _level.get("stalker") as CharacterBody3D
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	if not _expect(_source != null and _scheduler != null and _source.get_script().resource_path == SourcePath and _source.has_method("state") and _source.has_method("get_cue") and _source.has_method("get_art_state") and _level.has_method("scheduler_bindings") and _level.has_method("camera_framing_union"), "actual source/scheduler expose public diagnostics and live bindings"):
		return false
	var body: CollisionShape3D = _source.get_node_or_null("BodyCollision") as CollisionShape3D
	var capsule: CapsuleShape3D = body.shape as CapsuleShape3D if body != null else null
	if not _expect(capsule != null and is_equal_approx(capsule.radius, 0.32) and is_equal_approx(capsule.height, 1.45) and _source.get_world_3d() == _hero.get_world_3d() and _hero.presentation_id == "act3_traveller", "real authored capsule and shared traveller inhabit the same physical world"):
		return false
	_normal_width = _camera.size
	_hp_before = _hero.hp
	_source_hp_before = float(_source.call("state").get("hp", -1.0))
	_hero.shells = 0 # Public depletion fixture; natural reload remains enabled.
	_source.connect("hit_resolved", _on_hit)
	_source.connect("state_changed", _on_source_state)
	_scheduler.reservation_invalidated.connect(_on_invalidated)
	if not _expect(_camera.projection == Camera3D.PROJECTION_ORTHOGONAL and _camera.keep_aspect == Camera3D.KEEP_WIDTH and _camera.h_offset == 0.0 and _normal_width > TinyWidth, "normal native fixed-width camera is available before mutation"):
		return false
	if bad_width:
		_camera.size = TinyWidth
	return true


func _admission_case() -> void:
	if not await _open_case("infeasible native width rejects before allocation", true):
		await _close_case()
		return
	var initial: Dictionary = await _scheduler_capture("initial unleased scheduler")
	if initial.is_empty():
		await _close_case()
		return
	var rejected: Dictionary = await _wait_rejection()
	if rejected.is_empty():
		await _close_case()
		return
	var art: Dictionary = _source.call("get_art_state")
	var cue: CinderThreatCue = _source.call("get_cue") as CinderThreatCue
	if not _expect(_source.is_on_floor() and _hero.is_on_floor() and _source.velocity.is_zero_approx() and rejected.phase == "idle" and _source.is_visible_in_tree() and art.get("visible", false) and cue != null and cue.state().get("phase") == "clear" and not String(rejected.get("framing_error", "")).is_empty() and String(rejected.get("last_rejection", "")).begins_with("Required view unavailable:"), "actual stable visible brace reports unavailable view without displaying a false warning"):
		await _close_case()
		return
	var first: Dictionary = await _scheduler_capture("first camera rejection")
	if first.is_empty():
		await _close_case()
		return
	if not _expect(_unallocated(first, initial) and int(rejected.cycle) == 0 and float(rejected.cooldown_until_s) == 0.0 and _warning_events == 0 and _untouched(), "infeasible admission creates no lease, serial, source cooldown, warning, contact or damage"):
		await _close_case()
		return
	# More than two actual request retry intervals, with live clocks advancing.
	var rejected_at: float = _scheduler.get_clock()
	var remained_unallocated: bool = true
	for _index: int in range(_frame_limit(0.7)):
		if _scheduler.get_clock() >= rejected_at + 0.6:
			break
		await _tick()
		var state: Dictionary = _source.call("state")
		remained_unallocated = remained_unallocated and String(state.get("reservation_id", "")).is_empty() and int(state.get("cycle", -1)) == 0 and float(state.get("cooldown_until_s", -1.0)) == 0.0 and _scheduler.reservations().is_empty() and _untouched()
	var later: Dictionary = await _scheduler_capture("repeated rejected requests")
	if not _expect(not later.is_empty() and _scheduler.get_clock() >= rejected_at + 0.6 and remained_unallocated and _unallocated(later, initial) and _warning_events == 0 and _invalidations.is_empty(), "bounded repeated pure rejections advance time without allocation or manufactured cancellation"):
		await _close_case()
		return
	var restored_at: float = _scheduler.get_clock()
	_camera.size = _normal_width
	var warning: Dictionary = await _wait_warning()
	if warning.is_empty():
		await _close_case()
		return
	var record: Dictionary = _scheduler.reservation_state(String(warning.reservation_id))
	var accepted: Dictionary = await _scheduler_capture("fresh warning after native-width restoration")
	_expect(_real_warning(warning, record) and not accepted.is_empty() and int(accepted.get("serial", -1)) == int(initial.serial) + 1 and int(warning.cycle) == 1 and float(record.get("start_s", -1.0)) > restored_at and String(warning.get("last_rejection", "")).is_empty() and _untouched(), "restoring only native camera width permits a fresh real armed warning with the next serial")
	await _close_case()


func _cancel_case() -> void:
	if not await _open_case("clipped unsupported current view cancels before contact", false):
		await _close_case()
		return
	var warning: Dictionary = await _wait_warning()
	if warning.is_empty():
		await _close_case()
		return
	var record: Dictionary = _scheduler.reservation_state(String(warning.reservation_id))
	if not _expect(_real_warning(warning, record), "genuine armed lunge is admitted with its actual capsule and fixed lane"):
		await _close_case()
		return
	var body: CollisionShape3D = _hero.get_node_or_null("BodyCollision") as CollisionShape3D
	var capsule: CapsuleShape3D = body.shape as CapsuleShape3D if body != null else null
	if not _expect(capsule != null and Geometry.segment_hits(record.geometry, _hero.global_position, _hero.global_position, capsule.radius) and _untouched(), "the untouched idle hero occupies the actual damage lane, so cancellation tests a real contact opportunity"):
		await _close_case()
		return
	var before: Dictionary = await _scheduler_capture("real accepted warning before clipping")
	if before.is_empty():
		await _close_case()
		return
	var union: Dictionary = _level.call("camera_framing_union", "", [], true)
	if not _expect(String(union.get("error", "")).is_empty() and not (union.get("points", []) as Array).is_empty() and String(_game.call("camera_framing_error", union.points)).is_empty(), "normal actual camera contains the current source, complete lane and shared hero before negative mutation"):
		await _close_case()
		return
	var source_at_warning: Vector3 = _source.global_position
	_camera.h_offset = UnsupportedOffset
	var viewport_rect: Rect2 = _camera.get_viewport().get_visible_rect()
	var clipped: bool = false
	for point: Vector3 in union.points:
		clipped = clipped or not viewport_rect.has_point(_camera.unproject_position(point))
	if not _expect(clipped and not String(_game.call("camera_framing_error", union.points)).is_empty(), "intentional native horizontal offset really clips required world corners and is unsupported"):
		await _close_case()
		return
	var cancelled: Dictionary = await _wait_cancellation(record)
	if cancelled.is_empty():
		await _close_case()
		return
	var cue: CinderThreatCue = _source.call("get_cue") as CinderThreatCue
	var after: Dictionary = await _scheduler_capture("cancelled current-view lease")
	if not _expect(not after.is_empty() and int(after.get("serial", -1)) == int(before.serial) and after.reservations.is_empty() and after.cooldowns == before.cooldowns and float(cancelled.cooldown_until_s) == float(record.cooldown_until_s) and int(cancelled.cycle) == int(warning.cycle) and _source.global_position == source_at_warning and _source.velocity.is_zero_approx() and _scheduler.get_clock() < float(record.active_from_s) and _untouched() and cue != null and cue.state().get("phase") == "clear", "current-view failure releases the real lease before motion/contact, clears its cue and preserves exact original cooldown without damage"):
		await _close_case()
		return
	if not _expect(_invalidations.size() == 1 and _invalidations[0].id == record.id and String(_invalidations[0].reason).begins_with("required_view_unsafe:"), "actual scheduler emits one identified unsafe-view cancellation, without a fake hit"):
		await _close_case()
		return
	# Restore the native property immediately. Observe past the cancelled attack's
	# complete active/recovery window; the original cooldown must still hold.
	_camera.h_offset = 0.0
	var endpoint: float = float(record.recovery_until_s) + 0.05
	if not _expect(endpoint < float(record.cooldown_until_s), "original role retains a cooldown interval beyond recovery for this cancellation probe"):
		await _close_case()
		return
	var preserved: bool = true
	for _index: int in range(_frame_limit(endpoint - _scheduler.get_clock() + 0.2)):
		if _scheduler.get_clock() >= endpoint:
			break
		await _tick()
		var state: Dictionary = _source.call("state")
		preserved = preserved and _untouched() and String(state.get("reservation_id", "")).is_empty() and int(state.get("cycle", -1)) == int(warning.cycle) and float(state.get("cooldown_until_s", -1.0)) == float(record.cooldown_until_s) and not bool(state.get("hit_consumed", true)) and _scheduler.reservations().is_empty()
	var final: Dictionary = await _scheduler_capture("original recovery deadline after cancellation")
	_expect(not final.is_empty() and _scheduler.get_clock() >= endpoint and preserved and int(final.get("serial", -1)) == int(before.serial) and final.cooldowns == before.cooldowns and _invalidations.size() == 1 and _warning_events == 1, "normal frames through the original active/recovery window retain cooldown and cause no delayed contact, HP loss or fresh premature warning")
	await _close_case()


func _unallocated(snapshot: Dictionary, initial: Dictionary) -> bool:
	return not snapshot.is_empty() and int(snapshot.get("serial", -1)) == int(initial.get("serial", -2)) and snapshot.get("reservations", [null]).is_empty() and snapshot.get("cooldowns", [null]).is_empty() and initial.get("reservations", [null]).is_empty() and initial.get("cooldowns", [null]).is_empty()


func _real_warning(state: Dictionary, record: Dictionary) -> bool:
	if record.is_empty() or not record.get("adapter") is Dictionary or not record.get("geometry") is Dictionary:
		return false
	var body: CollisionShape3D = _source.get_node_or_null("BodyCollision") as CollisionShape3D
	return record.get("id") == state.get("reservation_id") and record.get("source_instance_id") == _source.get_instance_id() and state.get("phase") == "warning" and record.get("state") == "warning" and record.get("armed", false) and record.adapter.get("kind") == "lunge" and record.adapter.get("body_collision_path") == "BodyCollision" and body != null and not body.disabled and record.geometry.get("kind") == "lane" and Geometry.error(record.geometry).is_empty() and float(record.get("active_from_s", 0.0)) > _scheduler.get_clock()


func _untouched() -> bool:
	return _hero.hp == _hp_before and not _hero.dead and float(_source.call("state").get("hp", -1.0)) == _source_hp_before and _hit_results.is_empty() and _hero.get_world_action_records().is_empty()


func _wait_rejection() -> Dictionary:
	var deadline: float = _scheduler.get_clock() + WarningWaitS
	for _index: int in range(_frame_limit(WarningWaitS)):
		var state: Dictionary = _source.call("state")
		if String(state.get("last_rejection", "")).begins_with("Required view unavailable:"):
			return state
		if not _untouched() or not String(state.get("reservation_id", "")).is_empty() or _scheduler.get_clock() > deadline:
			break
		await _tick()
	_expect(false, "bounded actual source reaches camera admission rejection without attacks")
	return {}


func _wait_warning() -> Dictionary:
	var deadline: float = _scheduler.get_clock() + WarningWaitS
	for _index: int in range(_frame_limit(WarningWaitS)):
		var state: Dictionary = _source.call("state")
		if state.get("phase") == "warning" and not String(state.get("reservation_id", "")).is_empty():
			return state
		if not _untouched() or _scheduler.get_clock() > deadline:
			break
		await _tick()
	_expect(false, "bounded actual source reaches a fresh accepted warning")
	return {}


func _wait_cancellation(record: Dictionary) -> Dictionary:
	var deadline: float = float(record.active_from_s)
	for _index: int in range(_frame_limit(deadline - _scheduler.get_clock() + 0.1)):
		var state: Dictionary = _source.call("state")
		if String(state.get("reservation_id", "")).is_empty() and String(state.get("last_cancel_reason", "")).begins_with("required_view_unsafe:"):
			return state
		if not _untouched() or state.get("phase") in ["active", "recovery"] or _scheduler.get_clock() >= deadline:
			break
		await _tick()
	_expect(false, "bounded unsafe-view cancellation precedes the actual active/contact boundary")
	return {}


func _scheduler_capture(label: String) -> Dictionary:
	_game.call("open_bench")
	await process_frame
	var snapshot: Dictionary = _scheduler.snapshot_state(_level.call("scheduler_bindings"))
	_expect(paused and not snapshot.is_empty(), label + ": public paused scheduler capture succeeds")
	_game.call("resume_lab")
	return snapshot


func _frame_limit(seconds: float) -> int:
	return int(ceilf(maxf(seconds, 0.0) * float(Engine.physics_ticks_per_second))) + 10


func _tick() -> void:
	await physics_frame
	await process_frame


func _close_case() -> void:
	if is_instance_valid(_camera):
		_camera.size = _normal_width if _normal_width > 0.0 else 7.2
		_camera.h_offset = 0.0
	if is_instance_valid(_level):
		_level.exit_level()
	if is_instance_valid(_scheduler):
		_expect(_scheduler.reservations().is_empty(), "public room exit releases the actual reservations")
	if is_instance_valid(_game):
		_game.queue_free()
	paused = false
	await process_frame
	await create_timer(0.15, true).timeout
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("practice_targets").is_empty() and get_nodes_in_group("required_cues").is_empty(), "owned world cleanup leaves no enemy/proxy/required-cue remnants")
	_game = null
	_level = null
	_hero = null
	_source = null
	_scheduler = null
	_camera = null


func _on_hit(result: Dictionary) -> void:
	_hit_results.append(result.duplicate(true))


func _on_source_state(state: Dictionary) -> void:
	if state.get("phase") == "warning":
		_warning_events += 1


func _on_invalidated(reservation_id: String, reason: String) -> void:
	_invalidations.append({"id": reservation_id, "reason": reason})


func _diagnostic() -> String:
	if not is_instance_valid(_source) or not is_instance_valid(_scheduler):
		return "case=" + _case + "; live bindings unavailable"
	var state: Dictionary = _source.call("state")
	return "case=%s; clock=%s; phase=%s; lease=%s; cycle=%s; cooldown=%s; framing=%s; rejection=%s; cancel=%s; camera_size=%s; h_offset=%s; HP=%s; contact_events=%d; scheduler=%s; snapshot=%s" % [_case, _scheduler.get_clock(), state.get("phase", ""), state.get("reservation_id", ""), state.get("cycle", -1), state.get("cooldown_until_s", -1), state.get("framing_error", ""), state.get("last_rejection", ""), state.get("last_cancel_reason", ""), _camera.size, _camera.h_offset, _hero.hp, _hit_results.size(), _scheduler.last_error, _scheduler.last_snapshot_error]


func _expect(ok: bool, label: String) -> bool:
	_checks += 1
	if ok:
		print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label + "; " + _diagnostic())
	return ok


func _finish() -> void:
	print("Act 3 actual framing guard smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
