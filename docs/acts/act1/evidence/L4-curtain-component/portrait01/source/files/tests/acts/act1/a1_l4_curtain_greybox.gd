extends SceneTree
## One actual C32 curtain component through shared Main preview. No campaign
## envelope, King's actor, roundel, completion, earned prefix or aggregate save.
## TEST ammo setup occurs immediately before the primary; reload stays native.

const MainScene = preload("res://scenes/main.tscn")
const ScenePath: String = "res://scenes/acts/act1/a1_l4_curtain_greybox.tscn"
const RuntimePath: String = "res://scripts/acts/act1/selenite_court_greybox.gd"
const SourceID: String = "court-curtain-guard"
const PortraitSize := Vector2i(540, 1170)
const PositionTolerance: float = 0.035
const WatchdogMs: int = 70000
const SafeRect := Rect2(-6.5, -7.5, 13, 15)
const Exact = preload("res://scripts/campaign/exact_json.gd")

var game: Node
var level: CinderLevel
var hero: CinderPlayer
var scheduler: CinderThreatScheduler
var sources: Dictionary = {}
var admissions: Dictionary = {}
var phase_observations: Dictionary = {}
var world_records: Array[Dictionary] = []
var input_observations: Array[Dictionary] = []
var hit_events: Array[Dictionary] = []
var worlds: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var quiet_units: Array[Dictionary] = []
var descendants: Array[Dictionary] = []
var descendant_ids: Dictionary = {}
var current_scope: String = "curtain"
var capture_dir: String = ""
var report_path: String = ""
var portrait: bool = false
var checks: int = 0
var failures: int = 0
var swipes: int = 0
var primaries: int = 0
var events: int = 0
var max_preparing: int = 0
var preparing_violation: bool = false
var initial_hp: float = 0.0
var last_primary_ms: int = -1000
var started_ms: int = 0
var aborted: bool = false
var finishing: bool = false
var completions: int = 0
var checkpoints: int = 0
var contacts: int = 0
var first_failure: Dictionary = {}
var attack_lease: String = ""
var primary_not_before_s: float = 0.0
var recovery_until_s: float = 0.0
var primary_release_clock_s: float = -1.0
var damage_cancel_clock_s: float = -1.0


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	process_frame.connect(_watchdog)
	_run.call_deferred()


func _run() -> void:
	portrait = "--portrait" in OS.get_cmdline_user_args()
	root.size = PortraitSize
	report_path = "res://.cinder/l4-curtain-greybox-%d.json" % Time.get_ticks_usec()
	if portrait:
		if not _require(DisplayServer.get_name() != "headless", "portrait mode requires the actual graphical renderer"):
			await _finish(); return
		capture_dir = "res://.cinder/captures/l4-curtain-%d" % Time.get_ticks_usec()
		if not _require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir)) == OK, "portrait evidence directory is writable"):
			await _finish(); return
		print("SCRIPTED L4 CURTAIN PORTRAIT: native_focus_observed=", DisplayServer.window_is_focused(), "; one initial public resume; normal FOCUS_OUT unchanged; ", capture_dir)
	print("L4 CURTAIN TEST SETUP: zero shells immediately before actual primary; native passive reload remains enabled")
	if not await _open_curtain(): await _finish(); return
	if not await _wait(func() -> bool: return _running_warning(SourceID), "actual retained C32 publishes its first native warning"):
		await _finish(); return
	var actor: Act1MushroomSelenite = sources[SourceID]
	var first: Dictionary = actor.pure_presentation_state()
	var lease: String = String(first.reservation_id)
	var answer: Dictionary = admissions.get(lease, {})
	if not _require(answer.get("accepted") == true and answer.get("armed") == true and answer.reservation.source_instance_id == actor.get_instance_id() and answer.reservation_id == lease and answer.proof.uses_blast == false and answer.proof.uses_invulnerability == false, "first warning has the real current owner lease and ordinary-only native proof"):
		await _finish(); return
	var proof: Dictionary = answer.proof.duplicate(true)
	var reservation: Dictionary = answer.reservation.duplicate(true)
	attack_lease = lease
	primary_not_before_s = float(proof.primary_time_s)
	recovery_until_s = float(reservation.recovery_until_s)
	if not _require(reservation.geometry.kind == "lane" and absf((reservation.geometry["to"] as Vector3).distance_to(reservation.geometry["from"]) - 2.0) <= PositionTolerance and float(reservation.geometry.radius) == 0.38 and float(proof.primary_time_s) >= float(reservation.active_until_s) and float(proof.response_complete_s) < float(reservation.recovery_until_s), "unchanged C32 short lane has a proved ordinary primary inside native recovery"):
		await _finish(); return
	if not _framing("first warning") or not await _pause_warning(lease) or not await _capture("warning"):
		await _finish(); return
	var source_start: Vector3 = actor.global_position
	var escape: Vector3 = proof.landing - hero.global_position
	if not _require(absf(Vector2(escape.x, escape.z).length() - float(hero.equipment.resolved_stats().dash_distance)) <= PositionTolerance, "published safe landing is one full legal ordinary dash"):
		await _finish(); return
	if not await _swipe(escape, "literal recognizer native escape") or not _framing("actual safe landing") or not await _capture("safe-landing"):
		await _finish(); return
	for phase: String in ["lock", "active", "recovery"]:
		var key: String = _phase_key(SourceID, int(first.cycle), lease, phase)
		if not await _wait(func() -> bool: return phase_observations.has(key), "same accepted C32 cycle publishes native " + phase):
			await _finish(); return
		var live: Dictionary = actor.pure_presentation_state()
		if not _require(live.reservation_id == lease and live.cycle == first.cycle and live.status == "running" and _planar_distance(actor.global_position, source_start) <= PositionTolerance and actor.velocity == Vector3.ZERO, "C32 " + phase + " retains the same stationary real source and lease"):
			await _finish(); return
		if live.phase == phase:
			if not _framing("actual " + phase): await _finish(); return
			if phase == "active" and not await _capture("active"): await _finish(); return
	# The proof is native admission authority. Actual gestures retain all-zero
	# input readiness; their clocks are reported, never claimed as exact replay.
	var return_start: float = float(proof.primary_time_s)
	for segment: Dictionary in proof.path:
		if segment.kind == "positioning_dash": return_start = float(segment.start_s)
	if not await _wait(func() -> bool: return scheduler.get_clock() >= return_start, "native response positioning boundary"):
		await _finish(); return
	var returning: Vector3 = proof.attack_position - hero.global_position
	returning.y = 0.0
	if returning.length() > PositionTolerance:
		if not _require(absf(returning.length() - float(hero.equipment.resolved_stats().dash_distance)) <= PositionTolerance, "native primary opening uses a full ordinary return dash") or not await _swipe(returning, "literal recognizer native return"):
			await _finish(); return
	if not await _wait(func() -> bool: return scheduler.get_clock() >= float(proof.primary_time_s), "actual native primary time"):
		await _finish(); return
	if not _framing("actual primary opening") or not await _capture("primary-opening"):
		await _finish(); return
	if not _require(actor.pure_presentation_state().phase == "recovery" and scheduler.get_clock() < float(reservation.recovery_until_s), "real ordinary primary starts during the same actual recovery") or not await _primary(actor, "curtain C32"):
		await _finish(); return
	var hurt: Dictionary = actor.pure_presentation_state()
	var control: Dictionary = scheduler.source_control_state(actor)
	if not _require(damage_cancel_clock_s >= float(reservation.active_until_s) and damage_cancel_clock_s < recovery_until_s, "actual damage cancellation callback occurs inside the original native recovery"):
		await _finish(); return
	if not _require(not hurt.dead and hurt.hp > 0.0 and hurt.hp < 24.0 and hurt.last_cancel_reason == "actual_player_damage" and hurt.reservation_id.is_empty() and control.reservations.is_empty() and control.cooldown != null and float(control.cooldown.ready_s) == float(reservation.cooldown_until_s), "genuine nonlethal primary cancels only its native lease and preserves the original cooldown"):
		await _finish(); return
	if not _require(hero.hp == initial_hp and hit_events.is_empty(), "actual escape and recovery attack incur no lane hit or Hero HP loss") or not await _capture("surviving-hit"):
		await _finish(); return
	if not await _wait(func() -> bool:
		var state: Dictionary = actor.pure_presentation_state()
		return _running_warning(SourceID) and int(state.cycle) > int(first.cycle), "surviving C32 naturally settles and earns a fresh complete warning"):
		await _finish(); return
	if not _require(not level.get("greybox_clear") and not level.is_completed() and completions == 0 and checkpoints == 0 and contacts == 0 and primaries == 1, "one surviving guard and fresh warning emit no campaign progress") or not _framing("fresh warning") or not await _capture("fresh-warning"):
		await _finish(); return
	await _close_curtain()
	await _finish()


func _open_curtain() -> bool:
	await process_frame
	game = MainScene.instantiate()
	game.set("level_scene_path", ScenePath)
	root.add_child(game)
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	scheduler = level.get("scheduler") as CinderThreatScheduler if level != null else null
	if not _require(level != null and hero != null and scheduler != null and level.scene_file_path == ScenePath and level.get_script().resource_path == RuntimePath and level.level_id == "A1-L4" and level.contract_error().is_empty() and level.hero == hero and level.shared_shell == game and hero.global_position == Vector3(0, 0.1, 0), "actual A1-L4 component loads through shared Main at the exact authored spawn"):
		return false
	sources = (level.get("sources") as Dictionary).duplicate()
	if not _require(sources.size() == 1 and sources.has(SourceID) and level.call("current_source_ids") == [SourceID], "court preview retains and activates only its one actual C32"):
		return false
	var actor: Act1MushroomSelenite = sources[SourceID]
	var state: Dictionary = actor.pure_presentation_state()
	if not _require(state.source_id == SourceID and state.role_id == "A1-E3" and state.hp == 24.0 and not state.dead and not state.dormant and actor.is_in_group("enemies") and actor.global_position == Vector3(0, 0, -2) and not state.approach_enabled and actor.body_binding_error().is_empty() and actor.art_binding_error().is_empty(), "source starts at its authored foot origin with unchanged real C32 body/art and no approach"):
		return false
	var floor: CollisionShape3D = level.get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
	if not _require(floor != null and floor.shape is BoxShape3D and (floor.shape as BoxShape3D).size == Vector3(14, 1, 16) and floor.global_position.y == -0.5 and not floor.disabled, "continuous actual supported floor retains its authored top0 footprint"):
		return false
	initial_hp = hero.hp
	actor.state_changed.connect(_notice_phase.bind(SourceID))
	actor.hit_resolved.connect(_notice_hit.bind(SourceID))
	actor.get_cue().state_changed.connect(func(_state: Dictionary) -> void: events += 1)
	level.connect("native_admission_published", _notice_admission)
	scheduler.reservation_invalidated.connect(func(id: String, reason: String) -> void:
		if id == attack_lease and reason == "actual_player_damage": damage_cancel_clock_s = scheduler.get_clock())
	level.completion_requested.connect(func(_id: String, _boundary: String) -> void: completions += 1)
	level.checkpoint_requested.connect(func(_id: String, _boundary: String, _kind: String) -> void: checkpoints += 1)
	level.contact_exit_requested.connect(func(_id: String, _boundary: String) -> void: contacts += 1)
	hero.world_action_executed.connect(func(record: Dictionary) -> void: world_records.append(record.duplicate(true)); events += 1)
	game.connect("input_observed", func(observation: Dictionary) -> void: input_observations.append(observation.duplicate(true)))
	_retain_descendants(game)
	game.call("resume_lab") # Initial public resume only; never repeated on focus loss.
	return _require(not paused, "one initial public preview resume preserves ordinary focus handling")


func _pause_warning(lease: String) -> bool:
	if not _require(game.call("request_pause_deferred"), "public deferred pause reaches a coherent native warning barrier"): return false
	if not await _wait(func() -> bool: return paused, "actual shared pause becomes visible", 2.0, true): return false
	var frozen: Dictionary = _paused_unit()
	if not _require(not frozen.player.is_empty() and not frozen.scheduler.is_empty() and not frozen.actor.is_empty() and frozen.actor.reservation_id == lease and not Exact.stringify(frozen.player).is_empty() and not Exact.stringify(frozen.scheduler).is_empty() and not Exact.stringify(frozen.actor).is_empty(), "paused native Player/Actor/Scheduler captures retain the warning and complete exact clocks/samples"):
		return false
	var envelope: Dictionary = {"api_revision": CinderLevel.API_REVISION, "schema_version": CinderLevel.SNAPSHOT_SCHEMA_VERSION, "level_id": level.level_id, "scene_path": level.scene_file_path, "local_snapshot_version": level.local_snapshot_version, "progress": {"completed": false, "completion_id": "", "contact_exit_id": "", "checkpoint_id": "", "checkpoint_kind": "", "checkpoint_ids": {}}, "local": {}}
	var captured: Dictionary = level.snapshot_state()
	var capture_error: String = level.last_snapshot_error
	var supplied: Dictionary = level.snapshot_state_for_presentation(game.get("camera") as Camera3D, game.get("hud") as GameHUD)
	var validation: String = level.snapshot_error(envelope)
	var contextual: String = level.snapshot_error_with_player(envelope, frozen.player)
	var restored: bool = level.restore_state(envelope)
	if not _require(captured.is_empty() and not capture_error.is_empty() and supplied.is_empty() and not validation.is_empty() and not contextual.is_empty() and not restored, "unfinished court aggregate explicitly refuses both writers, pure validation, saved-Player validation and restore"):
		return false
	var until: int = Time.get_ticks_msec() + 120
	while Time.get_ticks_msec() < until and not finishing: await process_frame
	if not _require(_paused_unit() == frozen, "pause and refused full envelope change no native HP/ammo/sample/clock/cue/action/progress/event"):
		return false
	quiet_units.append({"player_exact_json": Exact.stringify(frozen.player), "scheduler_exact_json": Exact.stringify(frozen.scheduler), "actor_exact_json": Exact.stringify(frozen.actor), "capture_refusal": capture_error, "validation_refusal": validation, "context_refusal": contextual})
	if not await _capture("paused-warning"): return false
	var input_before: Dictionary = game.call("get_input_observation_state")
	var records_before: Array[Dictionary] = hero.get_world_action_records()
	var button: Button = _resume_button(game.get("hud") as Node)
	if not _require(button != null, "actual shared pause GUI exposes Resume"): return false
	var point: Vector2 = button.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = point; press.global_position = point
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT; release.position = point; release.global_position = point
	Input.parse_input_event(release)
	await process_frame
	return _require(not paused and game.call("get_input_observation_state") == input_before and hero.get_world_action_records() == records_before, "genuine GUI press/frame/release/frame Resume is consumed without attack/dash/anchor change")


func _paused_unit() -> Dictionary:
	var actor: Act1MushroomSelenite = sources[SourceID]
	var bindings: Dictionary = {"world_root": game.get("world"), "owners": {SourceID: actor}, "floors": {"court-curtain-floor": {"collision": level.get_node("Floor/CollisionShape3D"), "safe_rect": SafeRect}}}
	var paired: Dictionary = scheduler.snapshot_state(bindings)
	return {"player": hero.snapshot_state(), "scheduler": paired, "actor": actor.capture_state(paired), "cue": actor.get_cue().state().duplicate(true), "art_pose": actor.get_art().call("pose_name"), "events": events, "world_actions": hero.get_world_action_records(), "input": game.call("get_input_observation_state"), "checkpoint": level.current_checkpoint(), "completed": level.is_completed(), "completions": completions, "checkpoints": checkpoints, "contacts": contacts}


func _retain_descendants(node: Node) -> void:
	if not descendant_ids.has(node.get_instance_id()):
		descendant_ids[node.get_instance_id()] = true
		descendants.append({"name": String(node.name), "ref": weakref(node)})
	for child: Node in node.get_children(): _retain_descendants(child)


func _close_curtain() -> bool:
	if not _require(hero.hp == initial_hp and hit_events.is_empty() and not preparing_violation and max_preparing == 1, "real native safe responses retain HP with one preparing source"): return false
	var records: Array[Dictionary] = hero.get_world_action_records()
	var encoded: Array[Dictionary] = []
	for record: Dictionary in records:
		var transported: Dictionary = CinderPlayer.encode_world_action_record(record, hero.get_world_action_clock())
		if not _require(not transported.is_empty() and record.kind in ["dash", "primary"], "actual world action retains public exact native transport"): return false
		encoded.append(transported)
	if not _require(input_observations.size() == records.size() and world_records.size() == records.size() and primaries == 1 and swipes >= 1, "one accepted recognizer receipt maps to each actual dash/ordinary primary"): return false
	worlds.append({"scope": current_scope, "initial_hp": initial_hp, "final_hp": hero.hp, "max_preparing": max_preparing, "phases": _portable(phase_observations), "admissions": _portable(admissions), "world_actions": encoded, "input_observations": _portable(input_observations), "source_states": _portable(_source_states()), "hit_events": _portable(hit_events)})
	var actor: Act1MushroomSelenite = sources[SourceID]
	var lease: String = String(actor.pure_presentation_state().reservation_id)
	if not _require(not lease.is_empty(), "explicit level exit starts with the real surviving fresh warning lease"): return false
	_retain_descendants(game) # Include native cue/effect nodes created after entry.
	level.exit_level()
	if not _require(not scheduler.is_physics_processing() and scheduler.source_control_state(actor).reservations.is_empty() and not actor.is_physics_processing() and not actor.is_in_group("enemies") and level.hero == null and level.shared_shell == null, "public level exit disarms actual source/lease/physics and releases shared aliases"): return false
	var fx: PixelEffects = game.get("fx") as PixelEffects
	if is_instance_valid(fx): fx.clear()
	game.queue_free()
	await process_frame
	for entry: Dictionary in descendants:
		if not _require((entry.ref as WeakRef).get_ref() == null, "actual descendant cleanup releases " + String(entry.name)): return false
	game = null; level = null; hero = null; scheduler = null; sources.clear()
	await process_frame
	return _require(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "disposed actual curtain world leaves no enemy or required-cue membership")


func _running_warning(id: String) -> bool:
	var state: Dictionary = sources[id].call("pure_presentation_state")
	return state.status == "running" and state.phase == "warning" and admissions.has(String(state.reservation_id))

func _swipe(direction: Vector3, label: String) -> bool:
	if not await _ready_input(label): return false
	var horizontal := Vector3(direction.x, 0, direction.z).normalized()
	var finish := Vector2(270, 650)
	var delta: Vector2 = _screen_delta(horizontal) * 180.0
	if not _require(_input_safe(finish - delta) and _input_safe(finish) and (game.call("screen_to_direction", delta) as Vector3).dot(horizontal) > 0.9999, label + " uses the actual camera basis and safe screen coordinates"):
		return false
	var sequence: int = _last_sequence()
	var before: Dictionary = game.call("get_input_observation_state")
	var origin: Vector3 = hero.global_position
	var press := InputEventScreenTouch.new()
	press.index = 7; press.pressed = true; press.position = finish - delta
	Input.parse_input_event(press)
	await process_frame
	if not _guard_input(): return false
	var drag := InputEventScreenDrag.new()
	drag.index = 7; drag.position = finish; drag.relative = delta
	Input.parse_input_event(drag)
	await process_frame
	if not _guard_input(): return false
	var release := InputEventScreenTouch.new()
	release.index = 7; release.position = finish
	Input.parse_input_event(release)
	await process_frame
	if not _guard_input(): return false
	swipes += 1
	if not await _ready_input(label + " stopped landing"): return false
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	var observed: Dictionary = game.call("get_input_observation_state")
	var normalized: Vector2 = finish / Vector2(PortraitSize)
	var distance: float = float(hero.equipment.resolved_stats().dash_distance)
	return _require(records.size() == 1 and records[0].kind == "dash" and not records[0].collision_shortened and absf(float(records[0].distance) - distance) <= PositionTolerance and records[0].direction.dot(horizontal) > 0.9999 and _planar_distance(origin, hero.global_position) > distance - PositionTolerance and records[0].landing.distance_to(hero.global_position) <= PositionTolerance and records[0].path.size() >= 2 and observed.sequence == before.sequence + 1 and observed.last_observation.kind == "swipe_release" and observed.anchor_normalized == normalized and game.call("get_aim_anchor_normalized") == normalized, label + " executes one full recorded recognizer dash with the literal release anchor")

func _primary(actor: CharacterBody3D, label: String) -> bool:
	if not await _ready_input(label + " primary readiness"): return false
	while Time.get_ticks_msec() - last_primary_ms <= 300:
		if not _guard_input(): return false
		await process_frame
	var offset: Vector3 = actor.global_position - hero.global_position
	offset.y = 0.0
	var direction: Vector3 = offset.normalized()
	var anchor: Vector2 = game.call("get_aim_anchor")
	var tap: Vector2 = anchor + _screen_delta(direction) * 160.0
	if not _require(actor.is_in_group("enemies") and offset.length() <= float(hero.equipment.resolved_stats().primary_range) and _input_safe(tap) and (game.call("aim_direction", tap) as Vector3).dot(direction) > 0.9999, label + " ordinary reach and exact aiming use the actual stopped body and last release"):
		return false
	var hp_before: float = float(actor.get("hp"))
	var sequence: int = _last_sequence()
	var press := InputEventScreenTouch.new()
	press.index = 7; press.pressed = true; press.position = tap
	Input.parse_input_event(press)
	await process_frame
	if not _guard_input(): return false
	var release := InputEventScreenTouch.new()
	release.index = 7; release.position = tap
	var actual: Dictionary = (actor as Act1MushroomSelenite).pure_presentation_state()
	if not _require(actual.reservation_id == attack_lease and actual.phase == "recovery" and scheduler.get_clock() >= primary_not_before_s and scheduler.get_clock() < recovery_until_s, "actual first-tap release retains the same native recovery after readiness awaits"):
		return false
	primary_release_clock_s = scheduler.get_clock()
	hero.shells = 0 # Immediate release-only ammo stage; passive reload stays live.
	Input.parse_input_event(release)
	await process_frame
	if not _guard_input(): return false
	last_primary_ms = Time.get_ticks_msec()
	primaries += 1
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	var observed: Dictionary = game.call("get_input_observation_state")
	return _require(records.size() == 1 and records[0].kind == "primary" and records[0].hits == 1 and float(actor.get("hp")) < hp_before and records[0].direction.dot(direction) > 0.9999 and observed.last_observation.kind == "primary_tap" and observed.last_observation.accepted and observed.last_observation.world_action_sequence == records[0].sequence and (game.call("get_aim_anchor") as Vector2).is_equal_approx(anchor), label + " immediate native first tap hits with zero starting shells and preserves aim")

func _ready_input(label: String) -> bool:
	return await _wait(func() -> bool:
		var state: Dictionary = hero.get_threat_response_state()
		return state.stable and float(state.dash_cooldown_left_s) == 0.0 and float(state.primary_cooldown_left_s) == 0.0 and float(state.commitment_remaining_s) == 0.0, label + " reaches actual native input readiness", 4.0)

func _guard_input() -> bool:
	if aborted or finishing: return false
	return _require_unexpected(not paused and is_instance_valid(hero) and not hero.dead, "unexpected focus/pause/death stops scripted input; fixture never forces resume")

func _framing(label: String) -> bool:
	var points: Array = level.camera_framing_points()
	return _require(not points.is_empty() and points.size() <= 224 and level.last_camera_framing_error.is_empty() and String(game.call("camera_framing_error", points)).is_empty(), label + " contains actual source/art/full lane and native response corners in the shared portrait camera")

func _notice_hit(hero_id: String, cycle: int, result: Dictionary, id: String) -> void:
	events += 1
	if result.get("accepted", false): hit_events.append({"source_id": id, "hero_id": hero_id, "cycle": cycle, "result": result.duplicate(true)})

func _screen_delta(direction: Vector3) -> Vector2:
	var camera: Camera3D = game.get("camera") as Camera3D
	var right: Vector3 = camera.global_basis.x
	var down: Vector3 = camera.global_basis.z
	right.y = 0.0; down.y = 0.0
	right = right.normalized(); down = down.normalized()
	var determinant: float = right.x * down.z - right.z * down.x
	return Vector2((direction.x * down.z - direction.z * down.x) / determinant, (right.x * direction.z - right.z * direction.x) / determinant).normalized()

func _resume_button(surface: Node) -> Button:
	if surface == null: return null
	if surface is Button and (surface as Button).is_visible_in_tree() and (surface as Button).text.begins_with("RESUME"): return surface as Button
	for child: Node in surface.get_children():
		var candidate: Button = _resume_button(child)
		if candidate != null: return candidate
	return null

func _phase_key(id: String, cycle: int, lease: String, phase: String) -> String:
	return "%s/%d/%s/%s" % [id, cycle, lease, phase]

func _last_sequence() -> int:
	var records: Array[Dictionary] = hero.get_world_action_records()
	return 0 if records.is_empty() else int(records.back().sequence)

func _input_safe(point: Vector2) -> bool:
	return point.is_finite() and Rect2(20, 300, 500, 670).has_point(point)

func _planar_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _portable(value: Variant) -> Variant:
	if value is Vector3: return [value.x, value.y, value.z]
	if value is Vector2: return [value.x, value.y]
	if value is Array:
		var array: Array = []
		for item: Variant in value: array.append(_portable(item))
		return array
	if value is Dictionary:
		var dictionary: Dictionary = {}
		for key: Variant in value: dictionary[String(key)] = _portable(value[key])
		return dictionary
	if value is Object: return "native object omitted: " + value.get_class()
	return value

func _require(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
		aborted = true
		if failures == 1:
			first_failure = {"label": label, "paused": paused, "native_focus": DisplayServer.window_is_focused(), "sources": _portable(_source_states()), "camera": _portable(game.call("get_camera_framing_state")) if is_instance_valid(game) else {}, "input": _portable(game.call("get_input_observation_state")) if is_instance_valid(game) else {}}
			print("FIRST L4 CURTAIN FAILURE: ", JSON.stringify(first_failure))
		push_error(label)
	return condition

func _require_unexpected(condition: bool, label: String) -> bool:
	if condition: return true
	if aborted: return false
	return _require(false, label)

func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > WatchdogMs:
		_require_unexpected(false, "whole component fixture completes within70 seconds")
		_finish.call_deferred()

func _wait(predicate: Callable, label: String, seconds: float = 8.0, allow_pause: bool = false) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while not aborted and not finishing and Time.get_ticks_msec() < deadline:
		if not allow_pause and not _guard_input(): return false
		if predicate.call(): return _require(true, label)
		_sample_preparing()
		await process_frame
	if aborted or finishing: return false
	print("L4 WAIT DIAGNOSTIC ", label, " source_states=", _source_states(), " last_admission=", level.get("last_admission") if is_instance_valid(level) else {}, " encounter_error=", level.get("last_encounter_error") if is_instance_valid(level) else "", " camera=", game.call("get_camera_framing_state") if is_instance_valid(game) else {}, " paused=", paused)
	return _require(false, label + " within the finite component window")


func _notice_admission(id: String, answer: Dictionary) -> void:
	if id != SourceID or answer.get("accepted") != true or not sources.has(id): return
	var actor: Act1MushroomSelenite = sources[id]
	var state: Dictionary = actor.pure_presentation_state()
	if answer.reservation.source_instance_id == actor.get_instance_id() and state.reservation_id == answer.reservation_id:
		admissions[String(answer.reservation_id)] = answer.duplicate(true)


func _notice_phase(state: Dictionary, id: String) -> void:
	events += 1
	var lease: String = String(state.get("reservation_id", ""))
	if not lease.is_empty() and state.get("status") == "running":
		var key: String = _phase_key(id, int(state.cycle), lease, String(state.phase))
		if not phase_observations.has(key):
			var cue: Dictionary = (sources[id].call("get_cue") as CinderThreatCue).state()
			phase_observations[key] = {"source_id": id, "cycle": state.cycle, "reservation_id": lease, "phase": state.phase, "clock_s": scheduler.get_clock(), "source_position": state.source_position, "cue": cue}
			_require(cue.phase == state.phase and cue.geometry == state.geometry and cue.source_position == state.source_position and cue.source_visible and (cue.footprint_visible == (state.phase != "recovery")) and (cue.active_fill_visible == (state.phase == "active")), "native " + String(state.phase) + " cue matches its real source and footprint before damage")
	_sample_preparing()


func _sample_preparing() -> void:
	if not is_instance_valid(level) or finishing: return
	var count: int = 0
	for id: String in level.call("current_source_ids"):
		if not is_instance_valid(sources.get(id)): continue
		if sources[id].call("pure_presentation_state").phase in ["warning", "lock"]: count += 1
	max_preparing = maxi(max_preparing, count)
	if count > 1: preparing_violation = true


func _source_states() -> Dictionary:
	var result: Dictionary = {}
	for id: String in sources:
		if is_instance_valid(sources[id]): result[id] = sources[id].call("pure_presentation_state").duplicate(true)
	return result


func _capture(stage: String) -> bool:
	if not portrait: return not aborted and not finishing
	await RenderingServer.frame_post_draw
	if aborted or finishing: return false
	var image: Image = root.get_texture().get_image()
	var path: String = capture_dir.path_join("%02d-curtain-%s.png" % [shots.size() + 1, stage])
	if not _require(image != null and image.get_size() == PortraitSize and image.save_png(path) == OK, "actual540x1170 renderer saves " + stage): return false
	shots.append({"stage": stage, "path": ProjectSettings.globalize_path(path), "hero_position": _portable(hero.global_position), "hp": hero.hp, "paused": paused, "native_focus": DisplayServer.window_is_focused(), "sources": _portable(_source_states()), "camera": _portable(game.call("get_camera_framing_state"))})
	return true


func _finish() -> void:
	if finishing: return
	finishing = true
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(game):
		var fx: PixelEffects = game.get("fx") as PixelEffects
		if is_instance_valid(fx): fx.clear()
		game.queue_free()
	paused = false
	await process_frame
	var report: Dictionary = {"scope": "actual-input neutral/Standard A1-L4 one-C32 curtain component through shared Main preview; no King's B01/roundel/fulllevel/campaign save/earned prefix/human/mobile/performance claim", "checks": checks, "failures": failures, "actual_swipes": swipes, "actual_primaries": primaries, "test_ammo_setup": "zero shells immediately before primary; native reload unchanged", "normal_focus_out_preserved": true, "primary_release_clock_s": primary_release_clock_s, "damage_cancel_clock_s": damage_cancel_clock_s, "first_failure": first_failure, "worlds": worlds, "quiet_native_units": quiet_units, "captures": shots}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t")); file.close()
	else:
		checks += 1; failures += 1; push_error("curtain diagnostic report failed to open")
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L4 CURTAIN COMPONENT: %d checks, %d failures; %d real swipes, %d ordinary primaries; report=%s; NO TELEPORTS / NO CAMPAIGN SAVE / NO FULL-LEVEL CLAIM" % [checks, failures, swipes, primaries, report_path])
	quit(0 if failures == 0 else 1)
