extends SceneTree
## Bounded C30 greybox: actual shell/input, one leased rush, ordinary primary,
## exact paused pair and retained-source restore. No full L2 acceptance claim.

const MainScene = preload("res://scenes/main.tscn")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const LevelPath: String = "res://scenes/acts/act1/a1_l2_rusher_greybox.tscn"
var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _source: CharacterBody3D
var _checks: int = 0
var _failures: int = 0
var _events: int = 0
var _portrait: bool = false
var _capture_dir: String = ""
var _captures: Array = []
var _finishing: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(50.0, true).timeout.connect(func() -> void:
		if not _finishing:
			_expect(false, "whole greybox fixture completes within 50 seconds")
			_finish())
	_portrait = "--portrait" in OS.get_cmdline_user_args()
	root.size = Vector2i(540, 1170)
	_game = MainScene.instantiate()
	_game.set("level_scene_path", LevelPath)
	root.add_child(_game)
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _expect(_level != null and _hero != null, "greybox enters through the actual shared shell"):
		_finish(); return
	_source = _level.get("rusher") as CharacterBody3D
	_expect(_source != null and _level.hero == _hero and _level.level_id == "A1-L2" and _level.contract_error().is_empty(), "one shared hero and one authored C30 bind the level interface")
	_expect(not _level.is_completed() and not _game.call("is_lab_level"), "prototype is an explicit custom preview, not a campaign completion or lab")
	_source.connect("state_changed", func(_s: Dictionary) -> void: _events += 1)
	_source.connect("defeated", func(_id: String) -> void: _events += 1)
	_hero.world_action_executed.connect(func(_r: Dictionary) -> void: _events += 1)
	_hero.fired.connect(func(_kind: String) -> void: _events += 1)
	(_source.call("get_cue") as CinderThreatCue).state_changed.connect(func(_s: Dictionary) -> void: _events += 1)
	(_level.get("scheduler") as CinderThreatScheduler).reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _events += 1)
	if _portrait:
		if not _expect(DisplayServer.get_name() != "headless", "portrait mode requires the actual graphical renderer"):
			_finish(); return
		_capture_dir = "res://.cinder/captures/l2-rusher-greybox-%d" % Time.get_ticks_usec()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_dir))
		print("SCRIPTED PORTRAIT: native_focus_observed=", DisplayServer.window_is_focused(), "; normal focus guards unchanged; no human/final-art claim; ", _capture_dir)
	_game.call("resume_lab")
	if not await _wait_phase("warning"):
		_finish(); return
	var answer: Dictionary = _level.get("last_admission")
	if not _expect(answer.get("accepted", false) and answer.get("armed", false) and answer.get("proof", {}).get("uses_blast", true) == false and answer.get("proof", {}).get("uses_invulnerability", true) == false, "actual scheduler admits one ordinary-primary/no-ammo escape proof"):
		_finish(); return
	var reservation: Dictionary = answer.reservation
	var art: Node3D = _source.call("get_art")
	_expect(art != null and String(art.call("binding_error")).is_empty() and art.call("pose_name") == "crouch", "actual C30 costume pixels bind the warning without changing physical source")
	var proof: Dictionary = answer.proof
	var origin: Vector3 = _hero.global_position
	var warning: Dictionary = await _pair()
	if not _expect(not warning.is_empty(), "real warning captures a paused actor/level pair"):
		_finish(); return
	var presentation: Node3D = art.get_parent()
	presentation.position.x = 0.5
	_expect(not String(_source.call("art_binding_error")).is_empty(), "displaced costume parent cannot impersonate the real capsule's feet")
	presentation.position = Vector3.ZERO
	presentation.visible = false
	_expect(not String(_source.call("art_binding_error")).is_empty(), "hidden presentation parent cannot leave an apparently visible attack source")
	presentation.visible = true
	art.visible = false
	_expect(not String(_source.call("art_binding_error")).is_empty(), "hidden costume leaf is rejected even when its child sprite is locally visible")
	art.visible = true
	_expect(String(_source.call("art_binding_error")).is_empty() and _level.snapshot_error_with_player(warning.level, warning.hero).is_empty(), "repairing original presentation restores the same pure paused pair")
	_expect(_level.snapshot_error_with_player(warning.level, warning.hero).is_empty(), "whole warning pair prevalidates without mutation")
	var frozen: String = Exact.stringify(warning)
	var malformed: Dictionary = warning.level.duplicate(true)
	malformed.local.framing_witness.clear()
	_expect(not _level.snapshot_error_with_player(malformed, warning.hero).is_empty() and not _level.restore_state(malformed), "live exchange rejects a missing landing/opening witness atomically")
	malformed = warning.level.duplicate(true)
	malformed.progress.completed = true
	malformed.progress.completion_id = "forged-greybox-clear"
	_expect(not _level.snapshot_error_with_player(malformed, warning.hero).is_empty() and not _level.restore_state(malformed), "temporary room rejects forged campaign completion atomically")
	malformed = warning.level.duplicate(true)
	malformed.progress.checkpoint_id = "forged-greybox-checkpoint"
	malformed.progress.checkpoint_kind = "encounter"
	malformed.progress.checkpoint_ids = {"forged-greybox-checkpoint": "encounter"}
	_expect(not _level.snapshot_error_with_player(malformed, warning.hero).is_empty() and not _level.restore_state(malformed), "temporary room rejects forged checkpoint history atomically")
	_expect(Exact.stringify({"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}) == frozen, "malformed pair checks change no live actor/progression/framing bit")
	var framing_before: Array = _level.call("_camera_framing_points")
	await create_timer(0.08, true).timeout
	_expect(Exact.stringify({"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}) == frozen, "pause freezes the exact actor/source/scheduler samples and clocks")
	var decoded: Dictionary = Exact.parse(frozen)
	_expect(decoded.get("accepted", false) and Exact.stringify(decoded.value) == frozen, "tagged JSON retains the entire genuine warning pair exactly")
	var event_count: int = _events
	_expect(_hero.restore_state(decoded.value.hero) and _level.restore_state(decoded.value.level), "ordered warning restore applies actor then actual C30/scheduler silently")
	_expect(_events == event_count and Exact.stringify({"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}) == frozen, "warning restore emits no action/state callback and changes no serialized bit")
	_expect((_level.call("_camera_framing_points") as Array) == framing_before, "warning restore retains full current/future poses, lane and landing/opening framing")
	await _capture("warning")
	_game.call("resume_lab")
	if not await _wait_phase("lock"):
		_finish(); return
	await _capture("lock")
	var escape: Vector3 = proof.landing - origin
	escape.y = 0.0
	if not await _swipe(escape.normalized(), "ordinary escape beside the committed lane"):
		_finish(); return
	_expect(_hero.hp == 100.0, "ordinary escape reaches a safe stopped landing without taking damage")
	if not await _wait_phase("active"):
		_finish(); return
	var active: Dictionary = await _pair()
	if not _expect(not active.is_empty() and _level.snapshot_error_with_player(active.level, active.hero).is_empty(), "actual unfinished leased rush captures and prevalidates its exact pair"):
		_finish(); return
	var active_source: Dictionary = _source.call("state")
	_expect(art.call("pose_name") == "rush" and String(art.call("binding_error")).is_empty(), "actual leased active motion selects its committed costume pose")
	if not _expect(active_source.phase == "active" and not active_source.adapter.finished and _source.velocity.length() > 0.0, "saved active pair is genuinely unfinished moving capsule motion"):
		_finish(); return
	await _capture("active")
	_game.call("resume_lab")
	if not await _wait_phase("recovery"):
		_finish(); return
	await _capture("recovery")
	_expect(art.call("pose_name") == "recovery" and String(art.call("binding_error")).is_empty(), "actual stopped recovery selects the planted costume pose")
	_expect(_source.global_position.distance_to(reservation.opening_position) <= Motion.ENDPOINT_TOLERANCE, "actual scheduler-driven capsule reaches its proved stopped-body opening")
	var positioning: Vector3 = proof.attack_position - _hero.global_position
	positioning.y = 0.0
	if positioning.length() > 0.1 and not await _swipe(positioning.normalized(), "ordinary return to stopped-body primary range"):
		_finish(); return
	await _capture("primary-opening")
	if not await _primary():
		_finish(); return
	await process_frame
	_expect(_source.get("dead") and _source.get("hp") == 0.0 and not _source.is_in_group("enemies"), "real immediate primary defeats the retained C30 and removes it from live targets")
	_expect(_hero.hp == 100.0 and not _level.is_completed(), "primary-only greybox completion claims no full Crater Gardens progression")
	await _capture("defeated")
	paused = true
	await process_frame
	var defeated: String = Exact.stringify({"hero": _hero.snapshot_state(), "level": _level.snapshot_state()})
	_expect(_level.snapshot_error_with_player(active.level, active.hero).is_empty(), "earlier-live pair prevalidates against the genuinely defeated retained capsule")
	_expect(Exact.stringify({"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}) == defeated, "retained-source prevalidation enables/moves/heals nothing")
	event_count = _events
	_expect(_hero.restore_state(active.hero) and _level.restore_state(active.level), "quiet actual actor collision/pose restore precedes scheduler lease restoration")
	_expect(_events == event_count and Exact.stringify({"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}) == Exact.stringify(active), "whole retained-source pair restores all original bits without callbacks")
	_expect(not _level.objective_text.contains("GREYBOX CLEAR"), "restored living source restores its active objective presentation")
	_expect(art.call("pose_name") == "rush" and String(art.call("binding_error")).is_empty(), "retained-source active restore quietly reconstructs the correct costume pose")
	_game.call("resume_lab")
	if not await _wait_phase("recovery"):
		_finish(); return
	_expect(_source.global_position.distance_to(reservation.opening_position) <= Motion.ENDPOINT_TOLERANCE and _hero.hp == 100.0, "resumed unfinished rush reaches the same endpoint without redamage")
	var old_source: CharacterBody3D = _source
	var old_scheduler: Node = _level.get("scheduler")
	var old_level: CinderLevel = _level
	_game.call("reset_lab")
	_expect(_game.get("active_level") != old_level and _game.get("player") != _hero and not old_source.is_physics_processing() and not old_source.is_in_group("enemies") and (old_scheduler.call("reservations") as Array).is_empty(), "preview reset retires source/group/lease and creates a fresh shared pair")
	_finish()


func _pair() -> Dictionary:
	paused = true
	await process_frame
	var actor: Dictionary = _hero.snapshot_state()
	var local: Dictionary = _level.snapshot_state()
	if actor.is_empty() or local.is_empty():
		print("PAIR DIAGNOSTIC hero=", _hero.last_snapshot_error, " level=", _level.last_snapshot_error, " source=", _source.get("last_snapshot_error"))
	return {"hero": actor, "level": local} if not actor.is_empty() and not local.is_empty() else {}


func _wait_phase(phase: String) -> bool:
	for _attempt: int in 500:
		if (_source.call("state") as Dictionary).phase == phase:
			return _expect(true, "observed actual " + phase + " phase")
		await create_timer(0.01, true).timeout
	var state: Dictionary = _source.call("state")
	print("PHASE DIAGNOSTIC ", state, " admission=", _level.get("last_admission"), " source_error=", _source.get("last_error"), " framing=", _game.get("last_camera_framing_error"), " paused=", paused)
	return _expect(false, "actual " + phase + " phase appears within the bounded encounter window")


func _swipe(direction: Vector3, label: String) -> bool:
	var finish := Vector2(270, 650)
	var delta: Vector2 = _screen_delta(direction) * 180.0
	var sequence: int = _hero.get_world_action_records()[-1].sequence if not _hero.get_world_action_records().is_empty() else 0
	var observation_before: Dictionary = _game.call("get_input_observation_state")
	var press := InputEventScreenTouch.new()
	press.index = 7; press.pressed = true; press.position = finish - delta
	Input.parse_input_event(press)
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.index = 7; drag.position = finish; drag.relative = delta
	Input.parse_input_event(drag)
	await process_frame
	var release := InputEventScreenTouch.new()
	release.index = 7; release.position = finish
	Input.parse_input_event(release)
	await process_frame
	for _attempt: int in 100:
		if _hero.get_threat_response_state().stable and not _hero.get_world_action_records(sequence).is_empty(): break
		await create_timer(0.01, true).timeout
	var records: Array[Dictionary] = _hero.get_world_action_records(sequence)
	var observation: Dictionary = _game.call("get_input_observation_state")
	var release_normalized: Vector2 = finish / root.get_visible_rect().size
	# Public storage is normalized Vector2. Its inverse may round 650 to650.0001;
	# compare the stored release exactly, rather than demand a lossless inverse.
	var exact_release: bool = observation.sequence == observation_before.sequence + 1 and observation.last_observation.kind == "swipe_release" and observation.anchor_normalized == release_normalized and observation.last_observation.screen_position_normalized == release_normalized and (_game.call("get_aim_anchor_normalized") as Vector2) == release_normalized
	var valid: bool = records.size() == 1 and records[0].kind == "dash" and records[0].direction.dot(direction) > 0.9999 and records[0].distance > 2.65 and exact_release
	if not valid:
		print("SWIPE DIAGNOSTIC records=", records, " requested=", direction, " anchor=", _game.call("get_aim_anchor"), " viewport=", root.get_visible_rect(), " observation=", _game.call("get_input_observation_state"), " response=", _hero.get_threat_response_state(), " paused=", paused)
	return _expect(valid, label + " uses the real recognizer, full dash and literal release anchor")


func _primary() -> bool:
	var direction: Vector3 = _source.global_position - _hero.global_position
	direction.y = 0.0
	direction = direction.normalized()
	var anchor: Vector2 = _game.call("get_aim_anchor")
	var tap: Vector2 = anchor + _screen_delta(direction) * 160.0
	var sequence: int = _hero.get_world_action_records()[-1].sequence
	_expect((_game.call("aim_direction", tap) as Vector3).dot(direction) > 0.9999 and _hero.global_position.distance_to(_source.global_position) < _hero.equipment.resolved_stats().primary_range, "tap direction and ordinary reach derive from the actual last release")
	var press := InputEventScreenTouch.new()
	press.index = 7; press.pressed = true; press.position = tap
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventScreenTouch.new()
	release.index = 7; release.position = tap
	_hero.shells = 0
	Input.parse_input_event(release)
	await process_frame
	var records: Array[Dictionary] = _hero.get_world_action_records(sequence)
	return _expect(records.size() == 1 and records[0].kind == "primary" and records[0].hits == 1 and records[0].direction.dot(direction) > 0.9999 and (_game.call("get_aim_anchor") as Vector2) == anchor, "real first tap immediately hits C30 with zero starting shells and preserves aim")


func _screen_delta(direction: Vector3) -> Vector2:
	var camera: Camera3D = _game.get("camera")
	var right: Vector3 = camera.global_basis.x
	var down: Vector3 = camera.global_basis.z
	right.y = 0.0; down.y = 0.0
	right = right.normalized(); down = down.normalized()
	var determinant: float = right.x * down.z - right.z * down.x
	return Vector2((direction.x * down.z - direction.z * down.x) / determinant, (right.x * direction.z - right.z * direction.x) / determinant).normalized()


func _capture(stage: String) -> void:
	if not _portrait: return
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	var path: String = _capture_dir.path_join(stage + ".png")
	_expect(picture != null and picture.get_size() == Vector2i(540, 1170) and picture.save_png(path) == OK, "actual 540x1170 " + stage + " portrait saved")
	_captures.append({"stage": stage, "path": path, "source": str(_source.call("state")), "hero": str(_hero.global_position), "native_focus": DisplayServer.window_is_focused(), "paused": paused})


func _expect(condition: bool, label: String) -> bool:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)
	return condition


func _finish() -> void:
	if _finishing: return
	_finishing = true
	if is_instance_valid(_game): _game.queue_free()
	await process_frame
	_expect(not is_instance_valid(_game), "final deferred shell cleanup completes before fixture exit")
	if _portrait and not _capture_dir.is_empty():
		var file: FileAccess = FileAccess.open(_capture_dir.path_join("evidence.json"), FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify({"scope": "scripted actual neutral rusher greybox; not final art/full A1-L2/human/native-focused/balance/performance", "checks": _checks, "failures": _failures, "captures": _captures}, "\t"))
	print("A1-L2 RUSHER GREYBOX: ", _checks, " checks, ", _failures, " failures")
	quit(0 if _failures == 0 else 1)
