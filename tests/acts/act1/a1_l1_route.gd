extends SceneTree
## One SceneTree owns both headless and graphical real gesture routes.
## The inherited async fixture produced contradictory predicates/type errors;
## consolidate its orchestration without changing gameplay or action checks.
## This records the observed fixture failure, not a general engine diagnosis.
## NO TELEPORTS, staged beats, direct actor actions or fabricated records.
## Graphical default requires actual focus; explicit --scripted-portrait records
## native focus without requiring it. Normal shared focus notifications remain.
## Headless hooks return immediately: no renders, extra inputs or added waits.
## Evidence excludes human balance, campaign save/retry and mobile/export.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const LevelPath: String = "res://scenes/acts/act1/a1_l1.tscn"
const Geometry: GDScript = preload("res://scripts/combat/threat_geometry.gd")
const PortraitSize: Vector2i = Vector2i(540, 1170)
const DefaultDashLength: float = 2.7
const ROUTE_KITS: Dictionary = {
	"neutral": ["CLOTH-J0", "CLOTH-P0", "CLOTH-S0", "WEAPON-01"],
	"slowest-longest-shortest": ["CLOTH-J1", "CLOTH-P2", "CLOTH-S2", "WEAPON-03"],
	"slowest-primary": ["CLOTH-J1", "CLOTH-P1", "CLOTH-S2", "WEAPON-03"],
	"fastest-short-dash": ["CLOTH-J0", "CLOTH-P0", "CLOTH-S1", "WEAPON-02"],
}
const PositionTolerance: float = 0.035
const MaxWaypointSwipes: int = 8
const MaxRouteSwipes: int = 28
const WaitPolls: int = 100
const ARM_IDS: Array[String] = ["a1_l1_roof_arm", "a1_l1_boarding_arm"]
const EXERCISES: Array[String] = ["first-dash", "release-point", "workshop-approach", "loading-arm", "boarding-rehearsal"]
const Codec: GDScript = preload("res://scripts/campaign/snapshot_codec.gd")
const CaptureRoot: String = "res://captures/act1/full-route"
const RequiredStages: Array[String] = [
	"spawn", "first-dash", "hall-primary", "workshop-useful-landing",
	"roof-warning", "roof-useful-landing", "boarding-warning",
	"boarding-useful-landing", "final-clear", "hatch-contact",
]
const ScriptedPhaseStages: Array[String] = ["roof-lock", "roof-active", "roof-recovery"]
const StageBeats: Dictionary = {
	"spawn": 0, "first-dash": 1, "hall-primary": 2,
	"workshop-useful-landing": 2, "roof-warning": 3,
	"roof-useful-landing": 3, "boarding-warning": 4,
	"boarding-useful-landing": 4, "final-clear": 5, "hatch-contact": 5,
	"roof-lock": 3, "roof-active": 3, "roof-recovery": 3,
}

var _checks: int = 0
var _failures: int = 0
var _finished: bool = false
var _aborted: bool = false
var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _camera: Camera3D
var _dash_count: int = 0
var _primary_count: int = 0
var _initial_hp: float = 0.0
var _route_kit: String = "neutral"
var _dash_length: float = DefaultDashLength
var _input_observations: Array[Dictionary] = []
var _progress_events: Array[String] = []
var _first_warning_positions: Dictionary = {}
var _arm_phases: Dictionary = {}
var _arm_hits: Array[Dictionary] = []
var _graphical_portrait: bool = false
var _scripted_portrait: bool = false
var _native_focus_at_pre_resume: bool = false
var _native_focus_samples: Array[Dictionary] = []
var _capture_directory: String = ""
var _shots: Array[Dictionary] = []
var _captured_stages: Dictionary = {}
var _pending_warnings: Array[String] = []
var _warning_pause_done: bool = false
var _pause_evidence: Dictionary = {}


func _initialize() -> void:
	# Always-process watchdog also bounds a mistakenly paused fixture.
	create_timer(55.0, true).timeout.connect(_watchdog)
	_run.call_deferred()


func _run() -> void:
	if not _renderer_check():
		return
	if not _select_route_kit():
		return
	root.size = PortraitSize
	_game = MainScene.instantiate()
	_game.set("level_scene_path", LevelPath)
	root.add_child(_game)
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	_camera = _game.get("camera") as Camera3D
	if not _require(_level != null and _hero != null and _camera != null, "shared MainScene builds the genuine production L1, hero and camera"):
		return
	if not _require(_level.scene_file_path == LevelPath and _beat() == 0 and _hero.global_position.distance_to(_level.spawn_position()) < 0.2, "route begins at genuine production spawn and first exercise"):
		return
	_game.connect("input_observed", _on_input_observed)
	_level.checkpoint_requested.connect(func(_id: String, checkpoint: String, _kind: String) -> void: _progress_events.append(checkpoint))
	_level.completion_requested.connect(func(_id: String, completion: String) -> void: _progress_events.append(completion))
	_level.contact_exit_requested.connect(func(_id: String, exit_id: String) -> void: _progress_events.append(exit_id))
	var arms: Dictionary = _level.get("arms")
	for id: String in ARM_IDS:
		var observed_id: String = id
		var arm: CinderLaneMechanism = arms[id] as CinderLaneMechanism
		arm.state_changed.connect(func(state: Dictionary) -> void: _on_arm_state(observed_id, state))
		arm.hit_resolved.connect(func(actor_id: String, cycle: int, result: Dictionary) -> void: _arm_hits.append({"arm": observed_id, "hero": actor_id, "cycle": cycle, "result": result.duplicate(true)}))
	# Static clothing uses the actual shared paused safe-boundary API. Equip
	# before physics/input begins; this changes no position, beat or action.
	paused = true
	var kit_ids: Array = ROUTE_KITS[_route_kit]
	var equipped: bool = true
	for id: String in kit_ids:
		equipped = _hero.equip_item(id) and equipped
	var expected_ids: Dictionary = {"jacket": kit_ids[0], "pants": kit_ids[1], "shoes": kit_ids[2], "weapon": kit_ids[3]}
	var equipment_errors: Array[String] = _hero.equipment.acceptance_errors()
	if not _require(paused and equipped and _hero.equipment.snapshot() == expected_ids and equipment_errors.is_empty(), "selected canonical route kit equips through the public paused safe boundary: " + _route_kit + "; " + str(equipment_errors)):
		return
	_initial_hp = _hero.hp
	var stats: Dictionary = _hero.equipment.resolved_stats()
	_dash_length = float(stats.dash_distance)
	print("ROUTE_KIT: name=", _route_kit, "; IDs=", _hero.equipment.snapshot(), "; resolved_stats=", stats)
	var distance_valid: bool = is_finite(_dash_length) and _dash_length > 0.0 and (_route_kit != "neutral" or is_equal_approx(_dash_length, DefaultDashLength))
	var stats_message: String = "default production kit supplies true2.7-unit dashes and workshop primary reach" if _route_kit == "neutral" else "selected production kit supplies its actual finite full dash and workshop primary reach"
	if not _require(distance_valid and float(stats.primary_range) >= 1.74, stats_message):
		return
	if not await _before_resume():
		return
	_game.call("resume_lab")
	if not await _wait_ready("genuine spawn settles through normal shared physics"):
		return
	if not _require(not paused and root.get_visible_rect().size.is_equal_approx(Vector2(PortraitSize)), "shared recognizer uses actual540x1170 viewport coordinates"):
		return

	if not await _capture_stage("spawn"):
		return
	var marker: Vector3 = _level.call("dash_marker_position")
	if not _require(absf(_planar_distance(_hero.global_position, marker) - DefaultDashLength) < PositionTolerance, "authored marker is one genuine default dash from actual spawn"):
		return
	# The fixed upper-left endpoint preserves the first release-point lesson.
	if not await _swipe_world(marker - _hero.global_position, "first dash from spawn", Vector2(140, 380), 320.0):
		return
	# The original exact-marker assertion stays strict for every true2.7 kit.
	# Longer legal gear executes its full dash into the real broad marker gate.
	var first_beat_now: int = _beat()
	var first_landing_error: float = _planar_distance(_hero.global_position, marker)
	var first_beat_ok: bool = first_beat_now == 1
	var first_landing_ok: bool = first_landing_error < PositionTolerance
	print("FIRST LANDING DIAGNOSTIC: beat=", first_beat_now, "; marker=", marker, "; actual_position=", _hero.global_position, "; planar_error=", first_landing_error, "; tolerance=", PositionTolerance, "; beat_ok=", first_beat_ok, "; landing_ok=", first_landing_ok, "; combined=", first_beat_ok and first_landing_ok, "; progress=", _progress_events)
	if is_equal_approx(_dash_length, DefaultDashLength):
		if not _require(first_beat_ok and first_landing_ok, "actual touch dash landing completes first-dash without staging"):
			return
	elif not _require(_beat() == 1 and _planar_distance(_hero.global_position, marker) <= 1.1, "actual full-length selected-kit touch dash completes the real broad first-dash marker without staging"):
		return
	var first_anchor: Vector2 = _game.call("get_aim_anchor")
	if not _require(first_anchor.is_equal_approx(Vector2(140, 380)), "literal final upper-left release is the exact persistent aim anchor"):
		return
	if not await _capture_stage("first-dash"):
		return
	if not await _primary_target("hall", 2):
		return
	if not _require((_game.call("get_aim_anchor") as Vector2).is_equal_approx(first_anchor), "camera-follow and hall primary preserve the actual release anchor"):
		return

	if not await _capture_stage("hall-primary"):
		return
	var targets: Dictionary = _level.get("targets")
	var workshop: PracticeTarget = targets.workshop as PracticeTarget
	var workshop_landing: Vector3 = workshop.global_position + Vector3(1.2, 0, 1.25)
	if not await _move_to(workshop_landing, "workshop useful approach"):
		return
	if not await _capture_stage("workshop-useful-landing"):
		return
	if not await _primary_target("workshop", 3):
		return
	if not _require((arms[ARM_IDS[0]] as CinderLaneMechanism).state().cycle == 0 and not (targets.roof as PracticeTarget).is_in_group("practice_targets"), "real workshop clear leaves roof target gated before a broad side cycle"):
		return

	if not await _arm_exercise(0, "roof", 4):
		return
	if not _require((arms[ARM_IDS[1]] as CinderLaneMechanism).state().cycle == 0 and not (targets.finale as PracticeTarget).is_in_group("practice_targets"), "actual roof primary leaves future boarding target gated"):
		return
	if not await _arm_exercise(1, "finale", 5):
		return
	if not _require(_level.is_completed() and (_level.get("completed_exercises") as Array) == EXERCISES, "five real exercises complete through gestures and accepted target hits"):
		return
	if not _require((_level.get("hatch_cue") as CinderInteractionCue).state().trigger == "contact" and (_level.get("hatch_cue") as CinderInteractionCue).state().state == "available", "completed rehearsal exposes the distinct shared contact hatch cue"):
		return
	if not await _capture_stage("final-clear"):
		return
	var hatch: Area3D = _level.get("hatch") as Area3D
	if not await _move_to(hatch.global_position, "open capsule contact approach"):
		return
	for _poll: int in range(WaitPolls):
		if _aborted or _finished:
			return
		if _progress_events.has("capsule-hatch"):
			break
		await create_timer(0.02, true).timeout
	if not _require(_progress_events.has("capsule-hatch") and hatch.overlaps_body(_hero), "executed swipe route physically overlaps hatch and emits actual contact exit"):
		return
	if not await _capture_stage("hatch-contact"):
		return
	# Mechanism transport requires the published paused actor barrier even
	# after source cancellation. Contact itself must have occurred beforehand.
	paused = true
	await process_frame
	var snapshot: Dictionary = _level.snapshot_state()
	if not _require(not snapshot.is_empty() and snapshot.progress.contact_exit_id == "capsule-hatch", "paused completed route captures the actual latched hatch exit: " + _level.last_snapshot_error):
		return
	_expect(_progress_events == ["first-dash", "release-point", "workshop-approach", "loading-arm", "launch-rehearsal-clear", "capsule-hatch"], "real checkpoint/completion/contact signals form exactly the authored route")
	var final_hp: float = _hero.hp
	var recorded_initial_hp: float = _initial_hp
	var lane_hits_absent: bool = _arm_hits.is_empty()
	print("FINAL SAFETY DIAGNOSTIC: hp=", final_hp, "; initial_hp=", recorded_initial_hp, "; hp_exactly_unchanged=", final_hp == recorded_initial_hp, "; lane_hits=", _arm_hits)
	_expect(final_hp == recorded_initial_hp, "safe-side route preserves exact initial HP without requiring blast or damage immunity")
	_expect(lane_hits_absent, "safe-side route has no actual source hit events")
	var records: Array[Dictionary] = _hero.get_world_action_records()
	var dash_records: int = 0
	var primary_records: int = 0
	for record: Dictionary in records:
		if record.kind == "dash": dash_records += 1
		elif record.kind == "primary": primary_records += 1
		else: _expect(false, "route has no unexpected blast or alternate world action")
	print("FINAL RECORD DIAGNOSTIC: dash_records=", dash_records, "; dispatched_swipes=", _dash_count, "; primary_records=", primary_records, "; dispatched_primaries=", _primary_count)
	_expect(dash_records == _dash_count, "every finite route swipe has exactly one genuinely executed dash record")
	_expect(primary_records == 4, "exactly four empty-shell primaries have genuinely executed records")
	_expect(_primary_count == 4, "exactly four first-tap primary gestures were dispatched")
	_expect(_input_observations.size() == _dash_count + _primary_count, "public recognizer observes exactly the dispatched swipe releases and primary taps")
	print("ROUTE: kit=", _route_kit, "; actual position=", _hero.global_position, "; dash_count=", _dash_count, "; primary_count=", _primary_count, "; observed_arm_phases=", _arm_phases)
	await _finish()


# Explicit renderer branches keep graphical work inside this SceneTree.
# Headless hooks return before rendering, focus checks or additional waits.


func _renderer_check() -> bool:
	_graphical_portrait = DisplayServer.get_name() != "headless"
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--scripted-portrait":
			_scripted_portrait = true
		elif argument.begins_with("--scripted-portrait="):
			return _require(false, "use explicit --scripted-portrait without a value")
		if argument.begins_with("--capture"):
			return _require(false, "route excludes auto-resume/static --capture modes")
	if not _graphical_portrait:
		if _scripted_portrait:
			return _require(false, "--scripted-portrait requires an actual graphical renderer")
		print("SCOPE: HEADLESS actual gesture-recognizer full A1-L1 route; NO TELEPORTS. No focused portrait/human/campaign-save acceptance.")
		return _require(DisplayServer.get_name() == "headless", "route fixture runs headless without forcing window focus")
	print("SCOPE: ", _route_mode(), " actual production gesture route; native_focus_observed=", _has_real_focus(), "; NO TELEPORTS or staged poses. No human balance/canonical acceptance.")
	return _require(_graphical_portrait, "selected portrait mode requires an actual graphical renderer: " + _route_mode())


func _before_resume() -> bool:
	if not _graphical_portrait:
		return true
	print("BINDING DIAGNOSTIC: contract_error=", _level.contract_error(), "; level.hero=", _level.hero, "; actual_actor=", _hero, "; level.effects=", _level.effects, "; shell=", _level.shared_shell, "; world_signal_connected=", _hero.world_action_executed.is_connected(Callable(_level, "_on_world_action")))
	if not _require(_level.hero == _hero and _level.shared_shell == _game and _level.effects == _game.get("fx") and _hero.world_action_executed.is_connected(Callable(_level, "_on_world_action")), "production level is actually entered and bound to this exact shared actor/effects/shell before any graphical input"):
		return false
	# Fresh directory per invocation; never replace historical image/evidence.
	var run_id: String = "%s-%d-%d-%s" % ["scripted-graphical" if _scripted_portrait else "focused", int(Time.get_unix_time_from_system()), Time.get_ticks_usec(), _route_kit]
	_capture_directory = CaptureRoot + "/" + run_id
	if not _require(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_capture_directory)), "selected graphical route output directory is unique"):
		return false
	var error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_directory))
	if not _require(error == OK, "selected graphical route creates its own ignored capture directory"):
		return false
	if _scripted_portrait:
		_native_focus_at_pre_resume = _has_real_focus()
		print("SCRIPTED GRAPHICAL: normal single initial public resume; native_focus_observed=", _native_focus_at_pre_resume, "; normal shared focus notifications unchanged. Output: ", ProjectSettings.globalize_path(_capture_directory))
		return _require(paused, "explicit scripted mode begins at the actual paused kit boundary before its single normal public resume")
	print("WAITING: Focus the actual game window; route resumes only after stable real focus for300ms. Output: ", ProjectSettings.globalize_path(_capture_directory))
	var deadline_ms: int = Time.get_ticks_msec() + 30000
	var focused_since_ms: int = -1
	while Time.get_ticks_msec() < deadline_ms:
		if _aborted or _finished: return false
		var now_ms: int = Time.get_ticks_msec()
		if _has_real_focus():
			if focused_since_ms < 0: focused_since_ms = now_ms
			if now_ms - focused_since_ms >= 300:
				_native_focus_at_pre_resume = _has_real_focus()
				return _require(paused and _has_real_focus(), "stable actual focus precedes the sole initial public resume")
		else:
			focused_since_ms = -1
		await create_timer(0.05, true).timeout
	return _require(false, "actual window did not gain stable focus within bounded30s; route stays unresumed")


func _before_input(phase: String) -> bool:
	if not _graphical_portrait:
		return true
	if not _guard_live("before " + phase):
		return false
	# Drain warning evidence before a fresh pointer press. Never interrupt an
	# in-flight touch with pause/UI, and never introduce an alternate gesture.
	if phase.ends_with("_press"):
		if not await _drain_warning_captures(): return false
	return _guard_live("at dispatch " + phase)


func _capture_stage(stage: String) -> bool:
	if not _graphical_portrait:
		return true
	if not await _drain_warning_captures(): return false
	return await _capture_one(stage)


func _notice_stage(stage: String) -> void:
	if not _graphical_portrait:
		return
	# Called only on the real shared first-cycle warning signal.
	# Rendering waits outside that physics callback and outside an active touch.
	if not _captured_stages.has(stage) and not _pending_warnings.has(stage):
		_pending_warnings.append(stage)


func _route_mode() -> String:
	if not _graphical_portrait:
		return "HEADLESS"
	return "SCRIPTED GRAPHICAL" if _scripted_portrait else "FOCUSED AUTOMATED PORTRAIT"


func _route_limits() -> String:
	if not _graphical_portrait:
		return "LIMITS: no focused portrait/human or broader gear-portrait acceptance, all-loadout fairness, campaign saves/retry/transition or mobile/export evidence."
	return "LIMITS: " + _route_mode() + " actual renderer/recognizer evidence; native focus is observed and " + ("not required by explicit scripted mode" if _scripted_portrait else "required by strict focused mode") + "; no shared focus notification override, human balance, canonical/final art acceptance, broader gear-portrait/all-loadout fairness, campaign saves/retry/transition or mobile/export claim."


func _select_route_kit() -> bool:
	var selected: bool = false
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--route-kit":
			return _require(false, "use --route-kit=NAME with neutral/default, slowest-longest-shortest, slowest-primary or fastest-short-dash")
		if not argument.begins_with("--route-kit="):
			continue
		if selected:
			return _require(false, "select exactly one finite supported --route-kit=NAME")
		selected = true
		var name: String = argument.trim_prefix("--route-kit=")
		_route_kit = "neutral" if name == "default" else name
		if not ROUTE_KITS.has(_route_kit):
			return _require(false, "unknown route kit: " + name + "; supported: neutral/default, slowest-longest-shortest, slowest-primary, fastest-short-dash")
	return true


func _arm_exercise(index: int, target_id: String, next_beat: int) -> bool:
	var arm: CinderLaneMechanism = (_level.get("arms") as Dictionary)[ARM_IDS[index]] as CinderLaneMechanism
	var target: PracticeTarget = (_level.get("targets") as Dictionary)[target_id] as PracticeTarget
	var initial: Dictionary = arm.state()
	if not _require(initial.cycle == 0 and not target.is_in_group("practice_targets"), target_id + " starts gated with no fabricated arm cycle"):
		return false
	# World waypoint is a destination for ordinary swipes, never a position write.
	var observer: Vector3 = initial.source_position + Vector3(1.2, 0, 1.6)
	if not await _move_to(observer, target_id + " broad safe side approach", true):
		return false
	for _poll: int in range(WaitPolls):
		if _aborted or _finished: return false
		if int(arm.state().cycle) > 0 and target.is_in_group("practice_targets"):
			break
		await create_timer(0.02, true).timeout
	var state: Dictionary = arm.state()
	if not _require(int(state.cycle) > 0 and target.hp == 1.0 and target.is_in_group("practice_targets") and _first_warning_positions.has(ARM_IDS[index]), target_id + " becomes available only after the genuine broad-side shared warning"):
		return false
	var warning_position: Vector3 = _first_warning_positions[ARM_IDS[index]]
	var padding: float = CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN
	if not _require(not Geometry.segment_hits(state.geometry, warning_position, warning_position, padding), target_id + " first warning began in empty lane space beside the actual actor"):
		return false
	_expect(arm.get_cue().state().geometry == state.geometry, target_id + " source uses the same public committed lane as its required cue")
	var diagonal := Vector3(0.6, 0, 0.8)
	var landing: Vector3 = _hero.global_position + diagonal * _dash_length
	if not _require(not Geometry.segment_hits(state.geometry, _hero.global_position, landing, padding), target_id + " ordinary diagonal stays beside the full inflated lane"):
		return false
	if not await _swipe_world(diagonal, target_id + " deliberate useful side landing"):
		return false
	if not _require(_planar_distance(_hero.global_position, target.global_position) < float(_hero.equipment.resolved_stats().primary_range), target_id + " actual dash leaves the cloth within ordinary primary reach"):
		return false
	if not await _capture_stage(("roof" if index == 0 else "boarding") + "-useful-landing"):
		return false
	if not await _primary_target(target_id, next_beat):
		return false
	return _require(arm.state().status == "cancelled" and arm.get_cue().state().phase == "clear", target_id + " accepted primary cancels its real source before advancing")


func _move_to(goal: Vector3, label: String, protect_lane: bool = false) -> bool:
	for step: int in range(MaxWaypointSwipes):
		if _aborted or _finished: return false
		var start: Vector3 = _hero.global_position
		var offset: Vector3 = goal - start
		offset.y = 0.0
		var distance: float = offset.length()
		if distance <= PositionTolerance:
			return true
		if distance > _dash_length * 2.0 - 0.001 or absf(distance - _dash_length) <= PositionTolerance:
			var finish: Vector3 = start + offset.normalized() * _dash_length
			if not _require(_segment_safe(start, finish, protect_lane), label + " finite direct swipe fits actual floor and protected lane"):
				return false
			if not await _swipe_world(offset, label + " direct step%d" % step): return false
			continue
		# Two equal resolved full-dash edges reach the waypoint without shortening a dash.
		var direction: Vector3 = offset.normalized()
		var perpendicular := Vector3(-direction.z, 0, direction.x)
		var height: float = sqrt(maxf(0.0, _dash_length * _dash_length - distance * distance * 0.25))
		var centre: Vector3 = start + offset * 0.5
		var candidates: Array[Vector3] = [centre + perpendicular * height, centre - perpendicular * height]
		var midpoint: Vector3 = Vector3.INF
		for candidate: Vector3 in candidates:
			if _segment_safe(start, candidate, protect_lane) and _segment_safe(candidate, goal, protect_lane):
				if not midpoint.is_finite() or absf(candidate.x) < absf(midpoint.x):
					midpoint = candidate
		if not _require(midpoint.is_finite(), label + " has a finite two-swipe waypoint route on the actual floor"):
			return false
		if not await _swipe_world(midpoint - _hero.global_position, label + " two-step outward"):
			return false
		if not _require(absf(_planar_distance(_hero.global_position, goal) - _dash_length) < PositionTolerance, label + " measured first landing leaves one full true dash"):
			return false
		if not await _swipe_world(goal - _hero.global_position, label + " two-step arrival"):
			return false
		return _require(_planar_distance(_hero.global_position, goal) <= PositionTolerance, label + " reaches its waypoint through two executed full dashes")
	return _require(false, label + " exceeds bounded waypoint swipe count")


func _segment_safe(start: Vector3, finish: Vector3, protect_lane: bool) -> bool:
	# Production launch floor is convex; this inset keeps the shared capsule clear
	# of the low perimeter. Threat geometry is read from the current public state.
	var floor_inset := Rect2(-5.5, -15.5, 11.0, 29.0)
	if not start.is_finite() or not finish.is_finite() or not floor_inset.has_point(Vector2(start.x, start.z)) or not floor_inset.has_point(Vector2(finish.x, finish.z)):
		return false
	if protect_lane and _beat() in [3, 4]:
		var id: String = ARM_IDS[_beat() - 3]
		var state: Dictionary = ((_level.get("arms") as Dictionary)[id] as CinderLaneMechanism).state()
		return not Geometry.segment_hits(state.geometry, start, finish, CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN)
	return true


func _swipe_world(direction: Vector3, label: String, finish: Vector2 = Vector2(270, 650), pixels: float = 180.0) -> bool:
	if not await _wait_ready(label + " waits for actual shared dash readiness"):
		return false
	if not _require(_dash_count < MaxRouteSwipes, "finite total route swipe count remains bounded"):
		return false
	var horizontal := Vector3(direction.x, 0, direction.z).normalized()
	var delta: Vector2 = _screen_delta(horizontal) * pixels
	var start: Vector2 = finish - delta
	if not _require(horizontal.is_finite() and delta.is_finite() and _input_point_safe(start) and _input_point_safe(finish) and (_game.call("screen_to_direction", delta) as Vector3).dot(horizontal) > 0.9999, label + " derives a finite gesture from actual camera basis/public projection"):
		return false
	var origin: Vector3 = _hero.global_position
	var sequence: int = _last_sequence()
	var observation_before: Dictionary = _game.call("get_input_observation_state")
	var press := InputEventScreenTouch.new()
	press.index = 7
	press.pressed = true
	press.position = start
	if not await _before_input("swipe_press"):
		return false
	Input.parse_input_event(press)
	await process_frame
	if _aborted or _finished: return false
	var drag := InputEventScreenDrag.new()
	drag.index = 7
	drag.position = finish
	drag.relative = delta
	if not await _before_input("swipe_drag"):
		return false
	Input.parse_input_event(drag)
	await process_frame
	if _aborted or _finished: return false
	var release := InputEventScreenTouch.new()
	release.index = 7
	release.position = finish
	if not await _before_input("swipe_release"):
		return false
	Input.parse_input_event(release)
	await process_frame
	if _aborted or _finished: return false
	_dash_count += 1
	var observation: Dictionary = _game.call("get_input_observation_state")
	if not _require(int(observation.sequence) == int(observation_before.sequence) + 1 and observation.last_observation.kind == "swipe_release" and (_game.call("get_aim_anchor") as Vector2).is_equal_approx(finish) and (observation.anchor_normalized as Vector2).is_equal_approx(finish / Vector2(PortraitSize)), label + " observes exactly the literal final screen release and anchor"):
		return false
	if not await _wait_ready(label + " reaches deliberate dash stop"):
		return false
	var records: Array[Dictionary] = _hero.get_world_action_records(sequence)
	if not _require(records.size() == 1 and records[0].kind == "dash", label + " has one genuinely executed world dash record"):
		return false
	var record: Dictionary = records[0]
	return _require(absf(float(record.distance) - _dash_length) < PositionTolerance and not record.collision_shortened and (record.direction as Vector3).dot(horizontal) > 0.9999 and _planar_distance(origin, _hero.global_position) > _dash_length - PositionTolerance and _planar_distance(record.landing, _hero.global_position) < PositionTolerance and (record.path as Array).size() >= 2, label + (" travels/stops the genuine%.3f units with real sampled path" % _dash_length))


func _primary_target(id: String, next_beat: int) -> bool:
	if not await _wait_ready(id + " waits for actual shared primary readiness"):
		return false
	var target: PracticeTarget = (_level.get("targets") as Dictionary)[id] as PracticeTarget
	var offset: Vector3 = target.global_position - _hero.global_position
	offset.y = 0.0
	var direction: Vector3 = offset.normalized()
	var anchor: Vector2 = _game.call("get_aim_anchor")
	var tap: Vector2 = anchor + _screen_delta(direction) * 160.0
	if not _require(target.is_in_group("practice_targets") and target.hp == 1.0 and offset.length() <= float(_hero.equipment.resolved_stats().primary_range) and _input_point_safe(tap) and (_game.call("aim_direction", tap) as Vector3).dot(direction) > 0.9999, id + " aims an ordinary reachable primary exactly from the last release"):
		return false
	var sequence: int = _last_sequence()
	var observation_before: Dictionary = _game.call("get_input_observation_state")
	var press := InputEventScreenTouch.new()
	press.index = 7
	press.pressed = true
	press.position = tap
	if not await _before_input("primary_press"):
		return false
	Input.parse_input_event(press)
	await process_frame
	if _aborted or _finished: return false
	var release := InputEventScreenTouch.new()
	release.index = 7
	release.position = tap
	# Reset only immediately before this primary executes on touch release.
	# Never modify the shared reload clock/rate or suppress passive reload.
	if not await _before_input("primary_release"):
		return false
	_hero.shells = 0
	_expect(_hero.shells == 0, id + " primary release begins with empty shells and passive reload enabled")
	Input.parse_input_event(release)
	await process_frame
	if _aborted or _finished: return false
	_primary_count += 1
	var records: Array[Dictionary] = _hero.get_world_action_records(sequence)
	if not _require(records.size() == 1 and records[0].kind == "primary" and int(records[0].hits) == 1 and target.hp == 0.0 and _beat() == next_beat, id + " actual first touch tap executes immediate primary and clears exactly its exercise"):
		return false
	var observation: Dictionary = _game.call("get_input_observation_state")
	return _require(int(observation.sequence) == int(observation_before.sequence) + 1 and observation.last_observation.kind == "primary_tap" and observation.last_observation.accepted == true and int(observation.last_observation.world_action_sequence) == int(records[0].sequence) and (records[0].direction as Vector3).dot(direction) > 0.9999 and (_game.call("get_aim_anchor") as Vector2).is_equal_approx(anchor), id + " public actual tap observation links the accepted world primary without resetting aim")


func _screen_delta(direction: Vector3) -> Vector2:
	var right: Vector3 = _camera.global_basis.x
	var down: Vector3 = _camera.global_basis.z
	right.y = 0.0
	down.y = 0.0
	right = right.normalized()
	down = down.normalized()
	var determinant: float = right.x * down.z - right.z * down.x
	if absf(determinant) < 0.001 or not direction.is_finite():
		return Vector2.INF
	return Vector2((direction.x * down.z - direction.z * down.x) / determinant, (right.x * direction.z - right.z * direction.x) / determinant).normalized()


func _wait_ready(label: String) -> bool:
	for _poll: int in range(WaitPolls):
		if _aborted or _finished or not is_instance_valid(_hero): return false
		var state: Dictionary = _hero.get_threat_response_state()
		if not paused and state.stable and float(state.dash_cooldown_left_s) <= 0.00001 and float(state.primary_cooldown_left_s) <= 0.00001 and float(state.commitment_remaining_s) <= 0.00001:
			return true
		await create_timer(0.02, true).timeout
	return _require(false, label + " exceeds bounded100-poll shared readiness wait")


func _input_point_safe(point: Vector2) -> bool:
	return point.is_finite() and Rect2(20, 300, 500, 670).has_point(point)


func _planar_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _beat() -> int:
	return int(_level.get("beat_index"))


func _last_sequence() -> int:
	var records: Array[Dictionary] = _hero.get_world_action_records()
	return 0 if records.is_empty() else int(records[-1].sequence)


func _on_input_observed(record: Dictionary) -> void:
	_input_observations.append(record.duplicate(true))


func _on_arm_state(id: String, state: Dictionary) -> void:
	var phases: Array = _arm_phases.get(id, [])
	phases.append(state.phase)
	_arm_phases[id] = phases
	if state.phase == "warning" and int(state.cycle) == 1 and not _first_warning_positions.has(id):
		_first_warning_positions[id] = _hero.global_position
		_notice_stage(("roof" if id == ARM_IDS[0] else "boarding") + "-warning")


func _expect(ok: bool, message: String) -> void:
	_checks += 1
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: _failures += 1


func _require(ok: bool, message: String) -> bool:
	_expect(ok, message)
	if not ok and not _aborted:
		_aborted = true
		print("ABORT: ", message, "; actual_position=", _hero.global_position if is_instance_valid(_hero) else Vector3.INF)
		_finish.call_deferred()
	return ok


func _finish() -> void:
	if _finished: return
	_finished = true
	if _graphical_portrait:
		if not _aborted and _failures == 0:
			_expect(_shots.size() == _required_stages().size(), "all%d required actual graphical sourcecap stages captured" % _required_stages().size())
			for stage: String in _required_stages():
				_expect(_captured_stages.has(stage), "actual route image exists for " + stage)
			_expect(_warning_pause_done, "one actual shared warning pause resumed through the real GUI")
		_expect(_write_evidence(), "final " + _route_mode() + " evidence preserves actual captures/native-focus observations and limits")
	# Dispose the actual world before normalizing pause for shutdown, so cleanup
	# cannot resume an unfocused actor or execute another route action.
	if is_instance_valid(_level): _level.exit_level()
	if is_instance_valid(_game): _game.free()
	paused = false
	await process_frame
	print("A1-L1 %s touch route: %d checks, %d failures; %d actual swipes, %d actual primaries; NO TELEPORTS" % [_route_mode(), _checks, _failures, _dash_count, _primary_count])
	print(_route_limits())
	quit(0 if _failures == 0 else 1)


func _watchdog() -> void:
	if not _finished:
		_expect(false, "always-process route watchdog55s")
		await _finish()


func _drain_warning_captures() -> bool:
	while not _pending_warnings.is_empty():
		if _aborted or _finished: return false
		var stage: String = _pending_warnings.pop_front()
		if not await _capture_one(stage): return false
		if stage == "roof-warning" and not _warning_pause_done:
			if not await _pause_actual_warning(): return false
			if _scripted_portrait:
				if not await _observe_roof_cycle(): return false
	return true


func _capture_one(stage: String) -> bool:
	if _captured_stages.has(stage): return true
	if not _require(_required_stages().has(stage) and _beat() == int(StageBeats[stage]), "named capture belongs to the actual route stage: " + stage):
		return false
	if not _guard_live("before capture " + stage): return false
	await RenderingServer.frame_post_draw
	if not _guard_live("at rendered capture " + stage): return false
	var arms: Dictionary = _level.get("arms")
	if stage.ends_with("-warning") or ScriptedPhaseStages.has(stage):
		var arm_id: String = ARM_IDS[1] if stage == "boarding-warning" else ARM_IDS[0]
		var expected_phase: String = stage.trim_prefix("roof-") if ScriptedPhaseStages.has(stage) else "warning"
		var arm: CinderLaneMechanism = arms[arm_id] as CinderLaneMechanism
		var cycle: int = int(arm.state().cycle)
		var first_cycle_required: bool = ScriptedPhaseStages.has(stage) or (_scripted_portrait and stage == "roof-warning")
		var cycle_valid: bool = cycle == 1 if first_cycle_required else cycle > 0
		if not _require(arm.state().phase == expected_phase and arm.get_cue().state().phase == expected_phase and cycle_valid, stage + " image contains the genuinely live shared phase and cue"):
			return false
	var image: Image = root.get_texture().get_image()
	if not _require(image != null and image.get_size() == PortraitSize and root.get_visible_rect().size.is_equal_approx(Vector2(PortraitSize)), stage + " is actual540x1170 renderer pixels"):
		return false
	var filename: String = "%02d-%s.png" % [_shots.size() + 1, stage]
	var path: String = _capture_directory + "/" + filename
	if not _require(not FileAccess.file_exists(path) and image.save_png(path) == OK, stage + " image saves without replacing any earlier artifact"):
		return false
	var arm_states: Dictionary = {}
	for id: String in ARM_IDS:
		var arm: CinderLaneMechanism = arms[id] as CinderLaneMechanism
		arm_states[id] = {"state": arm.state(), "cue": arm.get_cue().state()}
	var target_states: Dictionary = {}
	var targets: Dictionary = _level.get("targets")
	for id: String in targets:
		var target: PracticeTarget = targets[id] as PracticeTarget
		target_states[id] = {"position": target.global_position, "hp": target.hp, "active": target.is_in_group("practice_targets")}
	var input_state: Dictionary = _game.call("get_input_observation_state")
	_shots.append({
		"path": path, "absolute_path": ProjectSettings.globalize_path(path),
		"stage": stage, "staged": false, "scope": _route_mode() + " actual production-route portrait",
		"kit": _route_kit, "equipment_ids": _hero.equipment.snapshot(),
		"pixel_size": [image.get_width(), image.get_height()], "native_focus_observed": _has_real_focus(), "native_focus_required": not _scripted_portrait, "paused": paused,
		"beat_index": _beat(), "actor_position": _hero.global_position, "actor_facing": _hero.facing,
		"presentation_id": _hero.presentation_id, "action_clock_s": _hero.get_world_action_clock(),
		"aim_anchor_screen": _game.call("get_aim_anchor"), "input_observation": input_state,
		"world_action_sequence": _last_sequence(), "actual_world_actions": _hero.get_world_action_records(),
		"arms": arm_states, "targets": target_states,
		"hatch_cue": (_level.get("hatch_cue") as CinderInteractionCue).state(),
		"camera": {"position": _camera.global_position, "basis_right": _camera.global_basis.x, "basis_down": _camera.global_basis.z, "size": _camera.size},
	})
	_captured_stages[stage] = true
	print("CAPTURE: ", _route_mode(), "; native_focus_observed=", _has_real_focus(), "; ", stage, " -> ", ProjectSettings.globalize_path(path))
	return _require(_write_evidence(), stage + " actual public-state metadata saves")


func _pause_actual_warning() -> bool:
	if not _guard_live("before public warning pause"): return false
	var roof: CinderLaneMechanism = (_level.get("arms") as Dictionary)[ARM_IDS[0]] as CinderLaneMechanism
	if not _require(roof.state().phase == "warning", "pause exercise begins during the actual shared roof warning"):
		return false
	var native_focus_before_pause: bool = _has_real_focus()
	_game.call("open_bench")
	await process_frame
	if _aborted or _finished: return false
	if not _require(paused and _focus_policy_allows() and not _hero.dead, "public warning pause reaches the actual paused deferred boundary; native_focus_observed=" + str(_has_real_focus())):
		return false
	var actor_before: Dictionary = _hero.snapshot_state()
	var level_before: Dictionary = _level.snapshot_state()
	var input_before: Dictionary = _game.call("get_input_observation_state")
	var position_before: Vector3 = _hero.global_position
	var actions_before: Array[Dictionary] = _hero.get_world_action_records()
	var anchor_before: Vector2 = _game.call("get_aim_anchor")
	var clock_before: float = _hero.get_world_action_clock()
	if not _require(not actor_before.is_empty() and not level_before.is_empty() and _level.snapshot_error_with_player(level_before, actor_before).is_empty(), "actual warning pause captures a valid paired public actor/level clock snapshot"):
		return false
	await create_timer(0.12, true).timeout
	if _aborted or _finished: return false
	var frozen: bool = paused and _focus_policy_allows() and not _hero.dead and _hero.get_world_action_clock() == clock_before and _hero.snapshot_state() == actor_before and _level.snapshot_state() == level_before and _game.call("get_input_observation_state") == input_before
	if not _require(frozen, "actual warning pause freezes exact paired actor/level clocks and public input state"):
		return false
	var button: Button = _resume_button(_game.get("hud") as Node)
	if not _require(button != null and button.is_visible_in_tree(), "real paused shared GUI exposes a visible RESUME button"):
		return false
	var point: Vector2 = button.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = point
	press.global_position = point
	if not _require(paused and _focus_policy_allows() and not _hero.dead, "actual paused GUI Resume mouse press; native_focus_observed=" + str(_has_real_focus())):
		return false
	Input.parse_input_event(press)
	await process_frame
	if _aborted or _finished: return false
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = point
	release.global_position = point
	if not _require(paused and _focus_policy_allows() and not _hero.dead, "actual paused GUI Resume mouse release; native_focus_observed=" + str(_has_real_focus())):
		return false
	Input.parse_input_event(release)
	await process_frame
	if _aborted or _finished: return false
	var consumed: bool = not paused and _focus_policy_allows() and not _hero.dead and _hero.global_position.is_equal_approx(position_before) and Codec.same_values(_hero.get_world_action_records(), actions_before) and Codec.same_values(_game.call("get_input_observation_state"), input_before) and (_game.call("get_aim_anchor") as Vector2).is_equal_approx(anchor_before)
	if not _require(consumed, "real GUI Resume click is consumed without combat actions, movement or anchor changes"):
		return false
	_warning_pause_done = true
	_pause_evidence = {"scope": _route_mode() + " actual first roof warning; public pause and real GUI Resume", "native_focus_before_pause": native_focus_before_pause, "native_focus_after_resume": _has_real_focus(), "paired_actor_snapshot": actor_before, "paired_level_snapshot": level_before, "input_before": input_before, "position_before": position_before, "anchor_before": anchor_before, "clock_before_s": clock_before, "hold_s": 0.12, "paired_state_frozen": frozen, "resume_click_consumed": consumed}
	return _require(_write_evidence(), "actual warning pause/GUI resume metadata saves")


func _resume_button(node: Node) -> Button:
	if node is Button and (node as Button).is_visible_in_tree() and (node as Button).text.begins_with("RESUME"):
		return node as Button
	for child: Node in node.get_children():
		var found: Button = _resume_button(child)
		if found != null: return found
	return null


func _has_real_focus() -> bool:
	return root.has_focus() and DisplayServer.window_is_focused(root.get_window_id())


func _focus_policy_allows() -> bool:
	return _scripted_portrait or _has_real_focus()


func _required_stages() -> Array[String]:
	var stages: Array[String] = []
	for stage: String in RequiredStages:
		stages.append(stage)
		if _scripted_portrait and stage == "roof-warning": stages.append_array(ScriptedPhaseStages)
	return stages


func _observe_roof_cycle() -> bool:
	# Voluntary test observation at the actual safe side reached by real swipes.
	# Runtime still permits immediate primary; no phase/clock/actor is forced.
	var roof: CinderLaneMechanism = (_level.get("arms") as Dictionary)[ARM_IDS[0]] as CinderLaneMechanism
	var initial: Dictionary = roof.state()
	var padding: float = CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN
	if not _require(not Geometry.segment_hits(initial.geometry, _hero.global_position, _hero.global_position, padding), "voluntary phase observation remains at the actual safe side reached by production swipes"):
		return false
	var deadline_ms: int = Time.get_ticks_msec() + 6000
	for phase: String in ["lock", "active", "recovery"]:
		var observed: bool = false
		while Time.get_ticks_msec() < deadline_ms:
			if not _guard_live("voluntary first-cycle " + phase + " observation"): return false
			var state: Dictionary = roof.state()
			if not _require(int(state.cycle) == 1 and state.status == "running", "voluntary source observation retains the genuine shared first cycle"):
				return false
			if state.phase == phase:
				if not await _capture_one("roof-" + phase): return false
				observed = true
				break
			await create_timer(0.02, true).timeout
		if not _require(observed, "actual first-cycle " + phase + " pixels captured within bounded6s"):
			return false
	return true


func _guard_live(context: String) -> bool:
	if _aborted or _finished: return false
	var native_focus: bool = _has_real_focus()
	var actor_alive: bool = is_instance_valid(_hero) and not _hero.dead
	_native_focus_samples.append({"context": context, "native_focus_observed": native_focus, "paused": paused, "actor_alive": actor_alive})
	return _require(_focus_policy_allows() and not paused and is_instance_valid(_game) and actor_alive, _route_mode() + " active simulation " + context + "; native_focus_observed=" + str(native_focus) + "; unexpected pause/death aborts")


func _write_evidence() -> bool:
	if _capture_directory.is_empty(): return true
	var evidence: Dictionary = {
		"scope": _route_mode() + " full A1-L1 portrait route from genuine production spawn; NO TELEPORTS or staged beat/positions",
		"limits": "No human balance, canonical/final art acceptance, all-loadout fairness, campaign save/retry/transition or mobile/export claim",
		"kit": _route_kit, "required_actual_stages": _required_stages(),
		"scripted_portrait": _scripted_portrait, "native_focus_required": not _scripted_portrait, "native_focus_at_pre_resume": _native_focus_at_pre_resume, "native_focus_samples": _native_focus_samples,
		"voluntary_first_cycle_observation": _scripted_portrait, "runtime_compulsory_wait": false,
		"checks": _checks, "failures": _failures, "aborted": _aborted,
		"actual_swipes": _dash_count, "actual_primaries": _primary_count,
		"shots": _shots, "pause": _pause_evidence,
		"progress_events": _progress_events, "actual_input_observations": _input_observations,
		"observed_shared_arm_phases": _arm_phases,
		"actual_world_actions_at_write": _hero.get_world_action_records() if is_instance_valid(_hero) else [],
		"actual_level_beat_at_write": _beat() if is_instance_valid(_level) else -1,
		"actual_actor_hp_at_write": _hero.hp if is_instance_valid(_hero) else -1.0, "recorded_initial_hp": _initial_hp, "actual_arm_hit_events": _arm_hits,
		"actual_level_actor_bound_at_write": is_instance_valid(_level) and is_instance_valid(_hero) and _level.hero == _hero,
	}
	var output: FileAccess = FileAccess.open(_capture_directory + "/evidence.json", FileAccess.WRITE)
	if output == null: return false
	output.store_string(JSON.stringify(_encode(evidence), "  ") + "\n")
	output.close()
	return true


func _encode(value: Variant) -> Variant:
	if value is Vector2: return [value.x, value.y]
	if value is Vector3: return [value.x, value.y, value.z]
	if value is Dictionary:
		var encoded_map: Dictionary = {}
		for key: Variant in value: encoded_map[String(key)] = _encode(value[key])
		return encoded_map
	if value is Array:
		var encoded_items: Array = []
		for item: Variant in value: encoded_items.append(_encode(item))
		return encoded_items
	return value
