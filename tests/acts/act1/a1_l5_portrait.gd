extends SceneTree
## Focused actual Main/L5 renderer and first native Blink response.
## TEST setup: public return-rusher injury and one stopped Hero placement.
## Sources, Floor, camera, input recognizer, cues and clocks stay production.
## No Shell Save/Continue/Retry, Nose/final/escape, earned-route or art claim.

const MainScene = preload("res://scenes/main.tscn")
const LevelScript = preload("res://scripts/acts/act1/living_moon.gd")
const Layout = preload("res://scripts/acts/act1/living_moon_layout.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const PortraitSize := Vector2i(540, 1170)
const PositionTolerance: float = 0.035

class FocusObserver:
	extends Node
	var receive: Callable
	func _notification(what: int) -> void:
		if not receive.is_valid(): return
		if what == NOTIFICATION_APPLICATION_FOCUS_IN: receive.call("application-focus-in")
		elif what == NOTIFICATION_APPLICATION_FOCUS_OUT: receive.call("application-focus-out")
		elif what == NOTIFICATION_APPLICATION_PAUSED: receive.call("application-paused")
		elif what == NOTIFICATION_APPLICATION_RESUMED: receive.call("application-resumed")

var game: Node
var level: CinderLevel
var hero: CinderPlayer
var camera: Camera3D
var hud: GameHUD
var scheduler: CinderThreatScheduler
var blink: CinderNativeSampledCircle
var eye: CharacterBody3D
var art: Node3D
var capsule: Node3D
var focus_observer: Node
var expected_pause: bool = false
var focus_armed: bool = false
var finishing: bool = false
var aborted: bool = false
var started_ms: int = 0
var checks: int = 0
var failures: int = 0
var swipes: int = 0
var primaries: int = 0
var report_path: String = ""
var capture_dir: String = ""
var first_failure: Dictionary = {}
var shots: Array[Dictionary] = []
var setups: Array[Dictionary] = []
var pauses: Array[Dictionary] = []
var gestures: Array[Dictionary] = []
var checkpoints: Array[Dictionary] = []
var focus_receipts: Array[Dictionary] = []
var closed_bounds: Dictionary = {}
var hud_configuration: Dictionary = {}
var closed_checkpoint_plan: Dictionary = {}
var closed_preview_points: Array = []
var blink_original: Dictionary = {}
var proof: Dictionary = {}
var initial_hp: float = 0.0


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	process_frame.connect(_watchdog)
	_run.call_deferred()


func _run() -> void:
	root.size = PortraitSize
	report_path = "res://.cinder/a1-l5-portrait-%d.json" % Time.get_ticks_usec()
	if not _require(DisplayServer.get_name() != "headless" and "--capture" not in OS.get_cmdline_user_args() and "--capture-polish" not in OS.get_cmdline_user_args(), "actual graphical renderer with ordinary focus handling required"):
		await _finish(); return
	var observer := FocusObserver.new()
	observer.process_mode = Node.PROCESS_MODE_ALWAYS
	observer.receive = Callable(self, "_record_focus")
	focus_observer = observer; root.add_child(observer)
	root.focus_entered.connect(_record_focus.bind("window-focus-entered"))
	root.focus_exited.connect(_record_focus.bind("window-focus-exited"))
	if not await _startup_focus(): await _finish(); return
	focus_armed = true
	capture_dir = "res://.cinder/captures/l5-first-blink-%d" % Time.get_ticks_usec()
	if not _require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir)) == OK, "capture directory is writable"):
		await _finish(); return
	game = MainScene.instantiate()
	game.set("level_scene_path", "res://scenes/acts/act1/a1_l5.tscn")
	root.add_child(game)
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	camera = game.get("camera") as Camera3D
	hud = game.get("hud") as GameHUD
	if not _require(is_instance_valid(level) and level.get_script() == LevelScript and level.contract_error().is_empty() and level.hero == hero and is_instance_valid(camera) and is_instance_valid(hud), "actual production L5 enters through one shared Main/Hero/camera"):
		await _finish(); return
	scheduler = level.get("scheduler") as CinderThreatScheduler
	blink = level.get("blink") as CinderNativeSampledCircle
	eye = level.get("eye") as CharacterBody3D
	art = level.get("_moon_art") as Node3D
	capsule = level.get("_capsule") as Node3D
	level.checkpoint_requested.connect(_record_checkpoint)
	if not _require(is_instance_valid(scheduler) and is_instance_valid(blink) and is_instance_valid(eye) and is_instance_valid(art) and is_instance_valid(capsule) and not paused and level.get("stage") == "return" and blink.get_parent() == eye, "fresh real entry retains the original native source topology without forced resume"):
		await _finish(); return
	hud.set_campaign_mode() # Supported public campaign presentation, not Shell retry.
	var telemetry: Label = hud.get("_telemetry_label") as Label
	hud_configuration = {"public_api": "GameHUD.set_campaign_mode", "safe_rect": _portable(hud.combat_safe_rect()), "telemetry_visible": telemetry.visible if is_instance_valid(telemetry) else true, "Retry_exercised": false, "scope": "actual campaign HUD presentation in shared Main preview; Shell flow is separate"}
	if not _require(is_instance_valid(telemetry) and not telemetry.visible and _find_button(hud, "RETRY") != null and _find_button(hud, "PAUSE") != null, "actual supported campaign HUD exposes Retry/Pause and hides lab telemetry"):
		await _finish(); return
	closed_bounds = _closed_capsule_bounds()
	if not _require(not closed_bounds.is_empty(), "complete closed capsule native mesh/Area/nose bounds are finite"):
		await _finish(); return
	initial_hp = hero.hp
	print("L5 PORTRAIT TEST SETUP: public rusher injury and one stopped Hero placement only; original native impact/Blink, real GUI pause, real recognizer swipe/primary; no earned route or fidelity claim")
	if not await _wait(func() -> bool: return level.get("impact_demonstrated") == true, "original finite native return impact reaches its actual recovery", 9.0):
		await _finish(); return
	var rusher: CharacterBody3D = level.get("rusher") as CharacterBody3D
	var before_hp: float = float(rusher.get("hp"))
	var injury: Dictionary = rusher.call("take_damage", before_hp, Vector3.ZERO)
	setups.append({"kind": "TEST public rusher injury", "amount": before_hp, "result": _portable(injury), "clock_s": scheduler.get_clock(), "earned_kill": false})
	if not _require(injury.get("accepted") == true and rusher.get("dead") == true, "TEST public injury retires the actual return rusher without source/history writes") or not await _test_position(Vector3(0, 0, -6.3), "TEST stopped approach before the boss threshold"):
		await _finish(); return
	if not await _wait(func() -> bool: return paused and level.get("stage") == "capsule" and level.current_checkpoint().get("id", "") == "capsule-ready", "real capsule checkpoint reaches its deferred complete pause barrier", 3.0) or not await _pause_capture("TEST-real-capsule-checkpoint-paused", true):
		await _finish(); return
	if not await _wait(func() -> bool: return _framing_error().is_empty(), "actual shared camera retains the blocked capsule beat", 2.0) or not await _capture("TEST-real-closed-capsule-checkpoint"):
		await _finish(); return
	if not await _swipe(Vector3(-1, 0, -1), "actual diagonal swipe from capsule checkpoint toward low eye") or not await _wait(func() -> bool: return _blink_phase("warning") and _framing_error().is_empty(), "first genuine sampled Blink warning is visible", 5.0):
		await _finish(); return
	var frames: Dictionary = level.get("_frames") as Dictionary
	proof = frames.get(Layout.EYE_ID, {}).get("proof", {}).duplicate(true)
	var state: Dictionary = blink.state()
	var reservation: Dictionary = scheduler.sampled_circle_reservation_state(String(state.reservation_id))
	var eye_control: Dictionary = scheduler.source_control_state(eye)
	blink_original = {"reservation_id": state.reservation_id, "cycle": state.cycle, "sample": state.sample.duplicate(true), "geometry": state.geometry.duplicate(true), "reservation": reservation.duplicate(true)}
	if not _require(not proof.is_empty() and proof.get("accepted") == true and not reservation.is_empty() and eye_control.get("api_revision") == "scheduler-source-control-1" and eye_control.get("outside_transaction") == true and eye_control.get("source_instance_id", -1) == eye.get_instance_id() and eye_control.get("reservations", []).size() == 1 and eye_control.reservations[0].id == state.reservation_id and state.cycle == 1 and proof.get("uses_blast") == false and proof.get("uses_invulnerability") == false, "original native eye lease/sample and ordinary full response witness are real") or not await _capture("native-Blink-warning", "warning") or not await _pause_capture("native-Blink-warning-paused"):
		await _finish(); return
	if not _require(_same_blink(), "real GUI pause retains the original Blink lease/sample/cycle/geometry") or not await _wait(func() -> bool: return _blink_phase("lock"), "original Blink enters its native lock", 4.0) or not await _capture("native-Blink-lock", "lock"):
		await _finish(); return
	if not await _swipe((proof.landing as Vector3) - hero.global_position, "ordinary real lock escape to native witness landing") or not _require(_planar_distance(hero.global_position, proof.landing) <= PositionTolerance and _same_blink(), "full actual dash reaches the original native safe landing without resampling") or not await _wait(func() -> bool: return _blink_phase("active"), "original locked circle enters its actual active interval", 2.0):
		await _finish(); return
	if not _require(hero.hp == initial_hp and not Geometry.segment_hits(blink.state().geometry, hero.global_position, hero.global_position, CinderThreatScheduler.CAPSULE_RADIUS) and hero.get_threat_response_state().stable, "actual stopped active landing is outside danger without damage or invulnerability credit") or not await _capture("native-Blink-active-safe-landing", "active") or not await _wait(func() -> bool: return _blink_phase("recovery"), "same native cycle exposes the genuine low eye recovery", 2.0):
		await _finish(); return
	if _planar_distance(hero.global_position, proof.attack_position) > PositionTolerance:
		if not await _swipe((proof.attack_position as Vector3) - hero.global_position, "ordinary real recovery return to the native primary opening"):
			await _finish(); return
	if not _require(_planar_distance(hero.global_position, proof.attack_position) <= PositionTolerance and _same_blink(), "original response returns to its ordinary primary opening") or not await _capture("native-Blink-recovery-low-rim", "recovery") or not await _primary():
		await _finish(); return
	await _finish()


func _test_position(position: Vector3, label: String) -> bool:
	if not await _ready_input(label): return false
	var empty: bool = true
	for key: String in ["rusher", "impact", "eye", "nose"]:
		empty = empty and scheduler.source_control_state(level.get(key)).get("reservations", []).is_empty()
	if not _require(empty and Layout.SAFE_RECT.has_point(Vector2(position.x, position.z)), label + " starts without any live lease and remains on the real native floor"): return false
	var origin: Vector3 = hero.global_position
	position.y = origin.y # Keep actual stopped feet height on this same flat floor.
	hero.global_position = position # Explicit focused TEST placement, never earned travel.
	setups.append({"kind": "TEST stopped Hero placement", "label": label, "from": _portable(origin), "to": _portable(position), "hp": hero.hp, "clock_s": scheduler.get_clock()})
	await physics_frame
	await process_frame
	return await _wait(func() -> bool: return hero.get_threat_response_state().stable, label + " settles on actual native floor", 2.0)


func _pause_capture(label: String, checkpoint_barrier: bool = false) -> bool:
	expected_pause = true
	if checkpoint_barrier:
		if not _require(paused, "real checkpoint deferred barrier is already paused outside callbacks"): return false
	elif not await _gui_button("PAUSE") or not await _wait(func() -> bool: return paused, "real Pause UI closes outside callbacks", 1.0): return false
	var player: Dictionary = hero.snapshot_state()
	var parent: Dictionary = level.snapshot_state()
	if not _require(not player.is_empty() and not parent.is_empty() and level.snapshot_error_with_player(parent, player).is_empty(), "real paused complete Player/parent/native packet passes paired validators: " + level.last_snapshot_error): return false
	var original: String = Exact.stringify({"player": player, "level": parent})
	if not _require(not original.is_empty() and Exact.stringify(Exact.parse(original).value) == original, "complete typed pause unit survives exact transport without stripping native fields"): return false
	var input_before: Dictionary = game.call("get_input_observation_state")
	var until: int = Time.get_ticks_msec() + 120
	while Time.get_ticks_msec() < until:
		if not _guard(): return false
		await process_frame
	if not _require(Exact.stringify({"player": hero.snapshot_state(), "level": level.snapshot_state()}) == original and game.call("get_input_observation_state") == input_before, "real pause freezes the same complete native unit, Player and gesture anchor") or not await _capture(label): return false
	pauses.append({"label": label, "whole_packet": Exact.parse(original).value, "no_restore_or_refresh": true})
	if not await _gui_button("RESUME"): return false
	expected_pause = false
	return _require(not paused, "actual Resume UI resumes the original unit without forced focus") and _guard()


func _gui_button(prefix: String) -> bool:
	if not _guard(): return false
	var button: Button = _find_button(game.get("hud"), prefix)
	if not _require(is_instance_valid(button), "actual shared UI exposes " + prefix): return false
	var before: Dictionary = game.call("get_input_observation_state")
	var actions: Array[Dictionary] = hero.get_world_action_records()
	var point: Vector2 = button.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = point; press.global_position = point
	Input.parse_input_event(press); await process_frame
	if not _guard(): return false
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT; release.position = point; release.global_position = point
	Input.parse_input_event(release); await process_frame
	return _guard() and _require(game.call("get_input_observation_state") == before and hero.get_world_action_records() == actions, "actual GUI press/frame/release/frame creates no gameplay gesture or anchor change")


func _find_button(node: Node, prefix: String) -> Button:
	if node is Button and node.is_visible_in_tree() and (node as Button).text.begins_with(prefix): return node as Button
	for child: Node in node.get_children():
		var found: Button = _find_button(child, prefix)
		if found != null: return found
	return null


func _swipe(direction: Vector3, label: String) -> bool:
	if not await _ready_input(label): return false
	var ground := Vector3(direction.x, 0, direction.z).normalized()
	var finish := Vector2(270, 650)
	var delta: Vector2 = _screen_delta(ground) * 180.0
	if not _require(_input_safe(finish - delta) and _input_safe(finish) and (game.call("screen_to_direction", delta) as Vector3).dot(ground) > 0.9999, "literal swipe uses the actual fixed camera projection"): return false
	var sequence: int = _last_sequence()
	var observation: Dictionary = game.call("get_input_observation_state")
	var origin: Vector3 = hero.global_position
	var press := InputEventScreenTouch.new()
	press.index = 7; press.pressed = true; press.position = finish - delta
	Input.parse_input_event(press); await process_frame
	if not _guard(): return false
	var drag := InputEventScreenDrag.new()
	drag.index = 7; drag.position = finish; drag.relative = delta
	Input.parse_input_event(drag); await process_frame
	if not _guard(): return false
	var release := InputEventScreenTouch.new()
	release.index = 7; release.position = finish
	Input.parse_input_event(release); await process_frame
	if not _guard(): return false
	swipes += 1
	if not await _ready_input(label + " stopped landing"): return false
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	var actual: Dictionary = game.call("get_input_observation_state")
	var distance: float = float(hero.equipment.resolved_stats().dash_distance)
	var normalized: Vector2 = finish / Vector2(PortraitSize)
	gestures.append({"label": label, "kind": "swipe", "from": _portable(origin), "to": _portable(hero.global_position), "records": _portable(records), "input": _portable(actual), "clock_s": scheduler.get_clock()})
	return _require(records.size() == 1 and records[0].kind == "dash" and not records[0].collision_shortened and absf(float(records[0].distance) - distance) <= PositionTolerance and records[0].direction.dot(ground) > 0.9999 and _planar_distance(origin, hero.global_position) > distance - PositionTolerance and _planar_distance(records[0].landing, hero.global_position) <= PositionTolerance and actual.sequence == observation.sequence + 1 and actual.last_observation.kind == "swipe_release" and actual.anchor_normalized == normalized and game.call("get_aim_anchor_normalized") == normalized, label + " uses one complete ordinary native dash and exact final release anchor")


func _primary() -> bool:
	if not await _ready_input("ordinary recovery primary"): return false
	var ground: Vector3 = eye.global_position - hero.global_position; ground.y = 0
	var direction: Vector3 = ground.normalized()
	var anchor: Vector2 = game.call("get_aim_anchor")
	var normalized: Vector2 = game.call("get_aim_anchor_normalized")
	var tap: Vector2 = anchor + _screen_delta(direction) * 160.0
	if not _require(_blink_phase("recovery") and _same_blink() and ground.length() <= float(hero.equipment.resolved_stats().primary_range) and _input_safe(tap) and (game.call("aim_direction", tap) as Vector3).dot(direction) > 0.9999, "real native low eye recovery lies within ordinary primary range and release-anchor aim"): return false
	var hp_before: float = float(eye.get("hp"))
	var sequence: int = _last_sequence()
	var press := InputEventScreenTouch.new()
	press.index = 7; press.pressed = true; press.position = tap
	Input.parse_input_event(press); await process_frame
	if not _guard() or not _require(_blink_phase("recovery") and _same_blink(), "first tap release stays inside the original genuine recovery"): return false
	var release := InputEventScreenTouch.new()
	release.index = 7; release.position = tap
	Input.parse_input_event(release); await process_frame
	if not _guard(): return false
	primaries += 1
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	var observed: Dictionary = game.call("get_input_observation_state")
	gestures.append({"label": "ordinary native recovery primary", "kind": "primary", "records": _portable(records), "input": _portable(observed), "hp_before": hp_before, "hp_after": eye.get("hp"), "clock_s": scheduler.get_clock()})
	return _require(records.size() == 1 and records[0].kind == "primary" and records[0].hits == 1 and records[0].direction.dot(direction) > 0.9999 and float(eye.get("hp")) == hp_before - float(records[0].resolved_stats.primary_damage) and observed.last_observation.kind == "primary_tap" and observed.last_observation.accepted and game.call("get_aim_anchor_normalized") == normalized and hero.hp == initial_hp, "one real immediate ordinary first tap hits the low eye through shared input without blast/pickup or damage")


func _same_blink() -> bool:
	var state: Dictionary = blink.state()
	return state.reservation_id == blink_original.reservation_id and state.cycle == blink_original.cycle and state.sample == blink_original.sample and state.geometry == blink_original.geometry


func _blink_phase(phase: String) -> bool:
	var state: Dictionary = blink.state()
	return state.status == "running" and state.phase == phase


func _closed_capsule_bounds() -> Dictionary:
	var points: Array = capsule.call("world_corners")
	var parts: Dictionary = art.call("part_points", camera)
	var collision := level.get_node("CapsuleHatch/CollisionShape3D") as CollisionShape3D
	if points.is_empty() or parts.is_empty() or collision == null or not collision.shape is BoxShape3D: return {}
	var contact: Array = _box_points((collision.shape as BoxShape3D).get_debug_mesh().get_aabb(), collision.global_transform)
	var union: Array = points.duplicate(); union.append_array(contact); union.append_array(parts.eye); union.append_array(parts.nose)
	var native: Dictionary = _bounds(points)
	var all: Dictionary = _bounds(union)
	if native.is_empty() or all.is_empty(): return {}
	# Match the production parent's conservative AABB collapse. Passing every
	# raw mesh corner (>500) would exceed the shared 256-point framing API.
	closed_preview_points = _box_points(AABB(native.minimum, native.maximum - native.minimum), Transform3D.IDENTITY)
	closed_preview_points.append_array(contact); closed_preview_points.append_array(parts.eye); closed_preview_points.append_array(parts.nose)
	closed_preview_points.append(parts.eye_floor_pivot); closed_preview_points.append(parts.nose_floor_pivot)
	var width: float = float(all.maximum.x) - float(all.minimum.x)
	var safe: Rect2 = (game.get("hud") as GameHUD).combat_safe_rect()
	return {"native_visible_capsule_aabb": _portable(native), "native_closed_mesh_corner_count": points.size(), "collapsed_preview_point_count": closed_preview_points.size(), "native_hatch_Area_aabb": _portable(_bounds(contact)), "actual_required_eye_aabb": _portable(_bounds(parts.eye)), "actual_required_nose_aabb": _portable(_bounds(parts.nose)), "capsule_Area_eye_nose_union": _portable(all), "horizontal_width": width, "actual_safe_rect": _portable(safe), "camera_width": camera.size, "plan_margin_each": 0.055, "headroom_each": CinderCameraFraming.NUMERICAL_HEADROOM, "horizontal_plan_budget": camera.size * safe.size.x - 0.11 - 2.0 * CinderCameraFraming.NUMERICAL_HEADROOM, "vertical_plan_budget": camera.size * float(camera.get_viewport().size.y) / float(camera.get_viewport().size.x) * safe.size.y - 0.11 - 2.0 * CinderCameraFraming.NUMERICAL_HEADROOM, "authored_hatch_position": _portable(Layout.HATCH_POSITION), "root_position": _portable(capsule.global_position), "pose": capsule.call("presentation_state"), "scope": "exact native world_corners and actual Area/part reserves; width does not establish current camera fit"}


func _bounds(points: Array) -> Dictionary:
	if points.is_empty(): return {}
	var low := Vector3(INF, INF, INF)
	var high := Vector3(-INF, -INF, -INF)
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite(): return {}
		low = low.min(point); high = high.max(point)
	return {"minimum": low, "maximum": high}


func _capture(label: String, required_phase: String = "") -> bool:
	if not _guard(): return false
	await RenderingServer.frame_post_draw
	if not _guard() or not _require(_framing_error().is_empty() and (required_phase.is_empty() or _blink_phase(required_phase)), "actual full production source/footprint/Hero/landing view and labelled native phase at " + label): return false
	if not _require(eye.global_position == Layout.EYE_POSITION and level.get("nose").global_position == Layout.EYE_POSITION + Layout.NOSE_LOCAL_POSITION and art.call("part_points", camera).eye_floor_pivot == Layout.EYE_POSITION and art.call("part_points", camera).nose_floor_pivot == Layout.EYE_POSITION + Layout.NOSE_LOCAL_POSITION, "actual source and low rim pivots remain authored"): return false
	if label == "TEST-real-closed-capsule-checkpoint":
		closed_checkpoint_plan = game.call("camera_framing_plan", closed_preview_points, hero.global_position + Vector3.UP * 0.65)
		if not _require(closed_checkpoint_plan.get("accepted") == true and String(game.call("camera_framing_error", closed_preview_points)).is_empty() and capsule.call("presentation_state") == {"hatch_open": false, "escape_progress": 0.0, "clinger_visible": false, "cord_visible": false}, "unpaused blocked capsule retains complete native bounds under both current containment and the actual .055 plan/3.6 shift limit"): return false
	var picture: Image = root.get_texture().get_image()
	var path: String = capture_dir.path_join("%02d-%s.png" % [shots.size() + 1, label])
	if not _require(picture != null and picture.get_size() == PortraitSize and picture.save_png(path) == OK, "actual540x1170 renderer saves " + label): return false
	shots.append({"label": label, "path": ProjectSettings.globalize_path(path), "paused": paused, "stage": level.get("stage"), "checkpoint": level.current_checkpoint(), "clock_s": scheduler.get_clock(), "hero_position": _portable(hero.global_position), "hero_hp": hero.hp, "eye_hp": eye.get("hp"), "Blink": _portable(blink.state()), "Moon_pose": art.call("pose_state"), "capsule_pose": capsule.call("presentation_state"), "capsule_actual_visible_bounds": _portable(_bounds(capsule.call("world_corners"))), "required_native_points": _portable(level.camera_framing_points()), "camera": _portable(game.call("get_camera_framing_state")), "optical_review": "pending personal image inspection; native containment is not art/occlusion acceptance"})
	return true


func _framing_error() -> String:
	var points: Array = level.camera_framing_points()
	if points.is_empty() or not level.last_camera_framing_error.is_empty(): return "Actual complete finite required points unavailable: " + level.last_camera_framing_error
	return String(game.call("camera_framing_error", points))


func _ready_input(label: String) -> bool:
	return await _wait(func() -> bool:
		var state: Dictionary = hero.get_threat_response_state()
		return state.stable and state.dash_cooldown_left_s == 0.0 and state.primary_cooldown_left_s == 0.0 and state.commitment_remaining_s == 0.0, label + " reaches native stopped input readiness", 3.0)


func _wait(predicate: Callable, label: String, seconds: float) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline and not finishing and not aborted:
		if not _guard(): return false
		if predicate.call(): return true
		if paused: await process_frame
		else: await physics_frame
		await process_frame
	return _require(false, label + "; actual diagnostic=" + String(level.get("last_encounter_error")))


func _guard() -> bool:
	if aborted or finishing: return false
	return true if root.has_focus() and DisplayServer.window_is_focused(root.get_window_id()) and is_instance_valid(level) and is_instance_valid(hero) and not hero.dead and (not paused or expected_pause) and level.contract_error().is_empty() else _require(false, "genuine focus loss/unexpected pause/death/contract failure cancels; no forced resume")


func _startup_focus() -> bool:
	var deadline: int = Time.get_ticks_msec() + 4000
	var stable_ms: int = -1
	while Time.get_ticks_msec() < deadline:
		if root.has_focus() and DisplayServer.window_is_focused(root.get_window_id()):
			if stable_ms < 0: stable_ms = Time.get_ticks_msec()
			if Time.get_ticks_msec() - stable_ms >= 200: return true
		else: stable_ms = -1
		await process_frame
	return _require(false, "genuine startup focus must be stable200ms; no OS foreground request")


func _record_focus(label: String) -> void:
	if focus_receipts.size() < 128: focus_receipts.append({"label": label, "wall_usec": Time.get_ticks_usec(), "native_focus": DisplayServer.window_is_focused(root.get_window_id()), "paused": paused})
	if focus_armed and not finishing and label in ["application-focus-out", "application-paused", "window-focus-exited"] and not aborted:
		_require(false, "actual native focus loss cancels the portrait fixture")
		_finish.call_deferred()


func _record_checkpoint(id: String, checkpoint_id: String, kind: String) -> void:
	checkpoints.append({"level_id": id, "id": checkpoint_id, "kind": kind, "clock_s": scheduler.get_clock()})
	if checkpoint_id == "capsule-ready":
		# Supported deferred barrier, never a snapshot or direct pause inside the
		# native checkpoint callback. GUI Resume follows the exact paused pair.
		expected_pause = true
		if not game.call("request_pause_deferred"):
			_require(false, "real capsule checkpoint deferred pause request must be accepted")


func _screen_delta(direction: Vector3) -> Vector2:
	var right := Vector3(camera.global_basis.x.x, 0, camera.global_basis.x.z).normalized()
	var down := Vector3(camera.global_basis.z.x, 0, camera.global_basis.z.z).normalized()
	var determinant: float = right.x * down.z - right.z * down.x
	return Vector2((direction.x * down.z - direction.z * down.x) / determinant, (right.x * direction.z - right.z * direction.x) / determinant).normalized()


func _input_safe(point: Vector2) -> bool:
	return point.is_finite() and Rect2(20, 300, 500, 670).has_point(point)


func _last_sequence() -> int:
	var records: Array[Dictionary] = hero.get_world_action_records()
	return 0 if records.is_empty() else int(records.back().sequence)


static func _planar_distance(left: Vector3, right: Vector3) -> float:
	return Vector2(left.x - right.x, left.z - right.z).length()


static func _box_points(bounds: AABB, frame: Transform3D) -> Array:
	var result: Array = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]: result.append(frame * Vector3(x, y, z))
	return result


static func _portable(value: Variant) -> Variant:
	if value is Vector3: return [value.x, value.y, value.z]
	if value is Vector2: return [value.x, value.y]
	if value is Rect2: return {"position": _portable(value.position), "size": _portable(value.size)}
	if value is Transform3D: return {"origin": _portable(value.origin), "basis": [_portable(value.basis.x), _portable(value.basis.y), _portable(value.basis.z)]}
	if value is Array:
		var items: Array = []
		for item: Variant in value: items.append(_portable(item))
		return items
	if value is Dictionary:
		var items: Dictionary = {}
		for key: Variant in value: items[String(key)] = _portable(value[key])
		return items
	if value is Object: return "native object omitted: " + value.get_class()
	return value


func _require(condition: bool, label: String) -> bool:
	checks += 1
	if condition: return true
	failures += 1; aborted = true
	if first_failure.is_empty():
		first_failure = {"label": label, "paused": paused, "stage": level.get("stage") if is_instance_valid(level) else "unopened", "clock_s": scheduler.get_clock() if is_instance_valid(scheduler) else null, "native_focus": DisplayServer.window_is_focused(root.get_window_id()), "diagnostic": level.get("last_encounter_error") if is_instance_valid(level) else "unopened"}
	push_error("L5 focused portrait: " + label)
	return false


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > 45000:
		if not aborted: _require(false, "focused first-Blink portrait watchdog45s expired")
		_finish.call_deferred()


func _finish() -> void:
	if finishing: return
	finishing = true; focus_armed = false
	var refs: Array[WeakRef] = []
	if is_instance_valid(game):
		for node: Node in game.find_children("*", "", true, false): refs.append(weakref(node))
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(game): game.queue_free()
	if is_instance_valid(focus_observer): focus_observer.queue_free()
	paused = false
	for index: int in 4: await process_frame
	_require(refs.all(func(reference: WeakRef) -> bool: return reference.get_ref() == null), "normal Main/level disposal removes every actual descendant")
	var report: Dictionary = {"scope": "actual Main540x1170 L5: full closed capsule native bounds, genuine return impact, TEST public rusher injury/one stopped Hero placement, actual capsule checkpoint and exact paused pairs, first native Blink warning/lock/active safe landing/recovery plus real recognizer dash/ordinary first-tap primary; no earned route", "checks": checks, "failures": failures, "first_failure": first_failure, "closed_native_bounds": closed_bounds, "public_campaign_HUD": hud_configuration, "closed_checkpoint_strict_plan": _portable(closed_checkpoint_plan), "TEST_setups": setups, "whole_pause_receipts": pauses, "original_Blink": _portable(blink_original), "original_response_witness": _portable(proof), "captures": shots, "gestures": gestures, "checkpoints": checkpoints, "focus": focus_receipts, "actual_swipes": swipes, "actual_primaries": primaries, "wall_elapsed_ms": Time.get_ticks_msec() - started_ms, "no_claims": ["Nose/final/escape mechanics", "earned kills/travel", "natural full playthrough", "campaign Shell Save/Continue/Retry/transition", "art fidelity or occlusion before personal PNG inspection", "all-kit balance", "mobile/performance"]}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(report, "\t")); file.close()
	else: failures += 1; push_error("L5 portrait report could not be written")
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("L5 FIRST-BLINK PORTRAIT: %d checks, %d failures; %d captures; report=%s" % [checks, failures, shots.size(), report_path])
	quit(0 if failures == 0 else 1)
