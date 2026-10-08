extends "res://tests/acts/act1/a1_l3_spore_component.gd"
## Actual one-role C32 environmental composition only.
## Install only after Root's paused native helpers and clockless art patch.
## No pose/phase/clock/HP/position seed: one real forward dash, one ordinary
## low-cluster primary, original native lease cancellation and finite episode.

const GuardSourceId: String = "lone-guard"
var guard_source: Act1MushroomSelenite
var guard_native_lease: String = ""
var guard_native_cycle: int = 0
var guard_native_cooldown: Dictionary = {}
var guard_native_encounter: String = ""
var guard_native_world_revision: int = 0
var guard_start_position: Vector3
var guard_episode_id: String = ""
var guard_cancel_events: Array[Dictionary] = []
var guard_retreat_pause_requested: bool = false
var guard_retreat_observed: Dictionary = {}


func _run() -> void:
	portrait = "--portrait" in OS.get_cmdline_user_args()
	root.size = PortraitSize
	if portrait:
		if not _require(DisplayServer.get_name() != "headless", "guard spore portrait requires the actual renderer"):
			await _finish(); return
		capture_dir = "res://.cinder/captures/l3-guard-spores-%d" % Time.get_ticks_usec()
		if not _require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir)) == OK, "guard spore portrait directory is writable"):
			await _finish(); return
		print("SCRIPTED C32 SPORE PORTRAIT native_focus=", DisplayServer.window_is_focused(), "; one initial public resume; normal FOCUS_OUT unchanged")
	if not await _open_spore_world(SporeGuardPath, "guard", Vector3(0, 0.1, -26)):
		await _finish(); return
	guard_source = sources[GuardSourceId] as Act1MushroomSelenite
	_watch_pair_events()
	if not await _wait(func() -> bool: return level.get("spores_ready"), "actual grounded C32 binds its one-role protocol before clusters are hittable"):
		await _finish(); return
	var field: CinderSporeField = level.get("spore_field")
	var consumer: CinderSporeRepulsion = level.get("spore_consumer")
	consumer.reaction_started.connect(func(id: String, episode_id: String) -> void:
		if id != GuardSourceId: return
		guard_episode_id = episode_id
		observed_spore_phases[id + "/recoil"] = true
		callback_capture_rejected = (level.call("component_unit_state") as Dictionary).is_empty()
		recoil_pause_requested = game.call("request_pause_deferred"))
	scheduler.reservation_invalidated.connect(func(id: String, reason: String) -> void:
		if id == guard_native_lease: guard_cancel_events.append({"id": id, "reason": reason}))
	if not await _swipe(Vector3.FORWARD, "guard low-cluster real forward approach"):
		await _finish(); return
	if not _require(_planar_distance(hero.global_position, Vector3(0, 0, -28.7)) <= PositionTolerance and guard_source.hp == 24.0 and _planar_distance(guard_source.global_position, Vector3(0, 0, -30)) <= PositionTolerance, "actual neutral full dash lands near28.7 while the untouched native C32 stays at30"):
		_guard_diagnostic("first landing"); await _finish(); return
	if not await _wait(func() -> bool:
		var current: Dictionary = guard_source.pure_presentation_state()
		return not String(current.get("reservation_id", "")).is_empty() and current.get("phase", "") in ["warning", "lock"], "C32 publishes its genuine brace warning/lock before any spore primary", 3.0):
		_guard_diagnostic("native admission"); await _finish(); return
	if not await _pause_pair("guard actual native warning/lock"):
		await _finish(); return
	var before: Dictionary = guard_source.pure_presentation_state()
	var control: Dictionary = scheduler.source_control_state(guard_source)
	if not _require(not before.is_empty() and not control.is_empty(), "C32 warning barrier has its actual pure actor and native controller views"):
		_guard_diagnostic("native boundary view"); await _finish(); return
	guard_native_lease = before.reservation_id
	guard_native_cycle = int(before.cycle)
	guard_start_position = guard_source.global_position
	guard_native_encounter = String(control.encounter_id)
	guard_native_world_revision = int(control.world_revision)
	if not _require(before.role_id == "A1-E3" and before.phase in ["warning", "lock"] and before.geometry.kind == "lane" and guard_source.velocity == Vector3.ZERO and not before.approach_driving and control.reservations.size() == 1 and control.reservations[0].id == guard_native_lease and not control.reservations[0].has("adapter") and control.cooldown is Dictionary, "actual C32 has one stationary native lane lease and original cooldown, with no lunge/approach substitution"):
		_guard_diagnostic("native lease"); await _finish(); return
	guard_native_cooldown = control.cooldown.duplicate(true)
	# The component restore intentionally clears parent framing. A live native
	# lease must retain its actual authored proof witness through the resume.
	if not _guard_read_component("guard native warning/lock") or not _guard_art(before.phase, "native brace") or not _guard_framing("native brace plus low cluster") or not await _capture("native-brace") or not await _gui_resume_pair():
		await _finish(); return
	var cluster := field.get_node("cluster-right") as Node3D
	var offset: Vector3 = cluster.global_position - hero.global_position
	offset.y = 0.0
	var enemy_offset: Vector3 = guard_source.global_position - hero.global_position
	enemy_offset.y = 0.0
	var other_offset: Vector3 = (field.get_node("cluster-left") as Node3D).global_position - hero.global_position
	other_offset.y = 0.0
	var resolved: Dictionary = hero.equipment.resolved_stats()
	var cone_dot: float = offset.normalized().dot(enemy_offset.normalized())
	var other_dot: float = offset.normalized().dot(other_offset.normalized())
	print("C32 PRIMARY GEOMETRY hero=", hero.global_position, " cluster=", cluster.global_position, " enemy=", guard_source.global_position, " reach=", offset.length(), " enemy_cone_dot=", cone_dot, " other_anchor_dot=", other_dot, " other_anchor_distance=", other_offset.length(), " actual_min_dot=", resolved.primary_cone_min_dot)
	if not _require(offset.length() <= float(resolved.primary_range) and cone_dot < float(resolved.primary_cone_min_dot) and guard_source.pure_presentation_state().phase in ["warning", "lock"], "actual low right cluster is ordinary-reachable while the live guard is outside the same primary cone before its active window"):
		_guard_diagnostic("cluster geometry"); await _finish(); return
	if not _require(other_offset.length() > CinderPlayer.ATTACK_ORIGIN_DISK_RADIUS and other_dot < float(resolved.primary_cone_min_dot), "the unspent left anchor is outside the actual aimed right cone and attack-origin disk, so one primary selects its intended finite supply"):
		_guard_diagnostic("other anchor geometry"); await _finish(); return
	if not await _cluster_primary(cluster, "C32 harmless first finite release", true):
		_guard_diagnostic("cluster primary"); await _finish(); return
	if not _require(paused and recoil_pause_requested and callback_capture_rejected and not guard_episode_id.is_empty() and guard_cancel_events == [{"id": guard_native_lease, "reason": "spore_repulsion"}], "one genuine native lease cancellation precedes recoil, callback capture denies and the public deferred pause reaches the complete barrier"):
		_guard_diagnostic("recoil callback"); await _finish(); return
	if not _require(guard_source.hp == 24.0 and hero.hp == initial_hp and hit_events.is_empty() and field.state().generation == 1 and field.state().spent_ids == ["cluster-right"] and field.state().remaining_clusters == 1 and consumer.placement_accepted(), "real zero-shell cluster primary preserves all living HP and spends exactly one finite supply without enemy hit/kill credit"):
		_guard_diagnostic("harmless release"); await _finish(); return
	if not await _guard_phase_capture("recoil", "recoil", false, true):
		await _finish(); return
	if not await _guard_phase_capture("turn", "recoil"):
		await _finish(); return
	if not await _guard_phase_capture("retreat", "retreat", true):
		await _finish(); return
	if not await _guard_phase_capture("hold", "regroup"):
		await _finish(); return
	if not _require(_planar_distance(guard_source.global_position, guard_start_position) > 0.02 and _planar_distance(guard_source.global_position, field.global_position) > 1.5 + float(guard_source.get_spore_response_state().support_radius) + 0.08 and guard_source.velocity == Vector3.ZERO, "stationary native guard really moved under the shared environmental Route and now holds its supported outside-union landing"):
		_guard_diagnostic("held endpoint"); await _finish(); return
	if not await _guard_phase_capture("regroup", "regroup"):
		await _finish(); return
	if not await _guard_phase_capture("none", "", false, false):
		await _finish(); return
	var final: Dictionary = guard_source.pure_presentation_state()
	var records: Array[Dictionary] = hero.get_world_action_records()
	if not _require(records.size() == 2 and records[0].kind == "dash" and records[1].kind == "primary" and records[1].hits == 0 and swipes == 1 and primaries == 1 and guard_source.hp == 24.0 and hero.hp == initial_hp and hit_events.is_empty() and field.state().generation == 1 and field.state().spent_ids == ["cluster-right"] and field.state().remaining_clusters == 1 and not level.is_completed(), "one actual swipe/ordinary no-ammo primary completes only this harmless C32 episode, with intact HP/supplies and no campaign clear"):
		_guard_diagnostic("final resources"); await _finish(); return
	print("C32 SPORE COMPONENT SCOPE original_lease=", guard_native_lease, " original_cooldown=", guard_native_cooldown, " final_native=", final, "; full campaign/crowd/injury/fresh-recipient scope excluded")
	await _finish()


func _guard_phase_capture(phase: String, expected_art: String, moving: bool = false, resume_after: bool = true) -> bool:
	if not paused:
		if not await _wait(func() -> bool:
			var response: Dictionary = guard_source.get_spore_response_state()
			return response.get("phase", "") == phase and (not moving or response.get("velocity", Vector3.ZERO) != Vector3.ZERO) and (phase not in ["turn", "retreat"] or float(response.get("progress", 1.0)) < 0.5), "C32 actual shared phase " + phase + " is observed before its late-tick pause", 5.0):
			_guard_diagnostic("phase wait " + phase); return false
		if not await _pause_pair("C32 " + phase): return false
	var response: Dictionary = guard_source.get_spore_response_state()
	var control: Dictionary = scheduler.source_control_state(guard_source)
	var native: Dictionary = guard_source.pure_presentation_state()
	if not _require(not response.is_empty() and not control.is_empty() and not native.is_empty(), "C32 " + phase + " exposes the actual complete source/controller views at its deferred boundary"):
		_guard_diagnostic("phase boundary view " + phase); return false
	if not _require(response.phase == phase and response.alive and response.hurt_remaining_s == 0.0 and guard_source.hp == 24.0 and hero.hp == initial_hp and not native.approach_driving and (response.velocity != Vector3.ZERO if moving else response.velocity == Vector3.ZERO), "C32 deferred " + phase + " barrier contains its genuine intact phase/motion without a private seed"):
		_guard_diagnostic("phase barrier " + phase); return false
	var has_old_lease: bool = false
	for record: Dictionary in control.reservations:
		if record.id == guard_native_lease: has_old_lease = true
	if not _require(not has_old_lease and control.encounter_id == guard_native_encounter and control.world_revision == guard_native_world_revision and (phase == "none" or (native.reservation_id.is_empty() and native.cycle == guard_native_cycle and control.reservations.is_empty() and response.episode_id == guard_episode_id)), "C32 " + phase + " keeps the original native attack cancelled while environmental custody owns the episode"):
		_guard_diagnostic("lease suppression " + phase); return false
	if phase != "none":
		if not _require((control.cooldown is Dictionary and Exact.stringify(control.cooldown) == Exact.stringify(guard_native_cooldown)) or (control.cooldown == null and float(control.clock_s) >= float(guard_native_cooldown.ready_s)), "C32 " + phase + " preserves the exact original cooldown until its natural native expiry"):
			_guard_diagnostic("cooldown " + phase); return false
	else:
		if not _require(response.episode_id.is_empty() and (native.reservation_id.is_empty() or (native.reservation_id != guard_native_lease and native.cycle > guard_native_cycle and native.phase in ["warning", "lock"])), "after regroup C32 has no old episode/lease; any new admission pays a genuinely fresh native warning"):
			_guard_diagnostic("fresh boundary"); return false
		expected_art = "standing" if native.phase in ["clear", "idle"] else String(native.phase)
	# A fresh native admission can follow the real final none boundary in the
	# same late parent tick. Preserve that live witness by read-only capture.
	if control.reservations.is_empty():
		if not _guard_quiet_component("guard " + phase):
			_guard_diagnostic("complete quiet unit " + phase); return false
	else:
		if not _require(phase == "none", "only the genuine final none boundary may already contain a fresh native lease"): return false
		if not _guard_read_component("guard none with fresh native warning"):
			_guard_diagnostic("fresh live capture"); return false
	if not _guard_art(expected_art, phase) or not _guard_framing(phase + " whole source/field/Player/landing") or not await _capture(phase): return false
	if resume_after:
		if phase == "turn": return await _guard_resume_into_short_retreat()
		return await _gui_resume_pair()
	return true


func _guard_read_component(label: String) -> bool:
	var points: Array = level.camera_framing_points().duplicate(true)
	var count: int = pair_events
	var unit: Dictionary = level.call("component_unit_state")
	if not _require(not unit.is_empty() and String(level.call("component_unit_error", unit)).is_empty(), label + " read-only captures and prevalidates its genuine complete native unit: " + String(level.get("last_component_error"))): return false
	var wire: String = Exact.stringify(unit)
	var decoded: Dictionary = Exact.parse(wire)
	if not _require(decoded.get("accepted", false) and Exact.stringify(decoded.value) == wire and String(level.call("component_unit_error", decoded.value)).is_empty(), label + " strictly transports and purely validates every original source/Player/controller/field/coordinator value without commit"): return false
	if not _require(Exact.stringify(level.call("component_unit_state")) == wire and level.camera_framing_points() == points and pair_events == count, label + " read-only inspection preserves native clocks/resources/events and actual parent safe-response framing"): return false
	component_units.append({"label": label, "mode": "read_only_live_native", "unit": unit.duplicate(true), "exact_json": wire, "camera_points": _portable(points)})
	return true


func _guard_quiet_component(label: String) -> bool:
	var candidate: Dictionary = level.call("component_unit_state")
	if not _require(not candidate.is_empty() and candidate.scheduler.reservations.is_empty(), label + " quiet restore is limited to a genuine complete unit with no native leases"): return false
	if not _quiet_component(label): return false
	# Preserve the exact native wire alongside portable diagnostic evidence.
	# The base writer/reader remains the authority for all validation/commits.
	var recorded: Dictionary = component_units.back()
	recorded["exact_json"] = Exact.stringify(recorded.unit)
	recorded["mode"] = "quiet_no_native_lease"
	return true


func _guard_resume_into_short_retreat() -> bool:
	# Observe the real published phase at the next physics-frame boundary.
	# Deferred pause still permits the native first retreat move and late parent
	# presentation tick; no native physics, samples or phase are run by this test.
	guard_retreat_pause_requested = false
	guard_retreat_observed.clear()
	physics_frame.connect(_guard_observe_retreat)
	var button: Button = _resume_button(game.get("hud") as Node)
	if not _require(button != null and paused, "short retreat observer uses the actual visible shared Resume button"):
		physics_frame.disconnect(_guard_observe_retreat)
		return false
	var input_before: Dictionary = game.call("get_input_observation_state")
	var records_before: Array[Dictionary] = hero.get_world_action_records()
	var point: Vector2 = button.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = point; press.global_position = point
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT; release.position = point; release.global_position = point
	Input.parse_input_event(release)
	await process_frame
	var reached: bool = await _wait(func() -> bool: return paused, "actual C32 first retreat tick reaches its public observer-requested deferred barrier", 2.0, true)
	if physics_frame.is_connected(_guard_observe_retreat): physics_frame.disconnect(_guard_observe_retreat)
	if not reached: return false
	print("C32 SHORT PHASE OBSERVER actual_pre_tick=", guard_retreat_observed, " actual_paused=", guard_source.get_spore_response_state())
	return _require(guard_retreat_pause_requested and not guard_retreat_observed.is_empty() and guard_retreat_observed.phase == "retreat" and game.call("get_input_observation_state") == input_before and hero.get_world_action_records() == records_before, "real GUI Resume and first-phase observer produce only the requested deferred pause, preserving exact input/world records")


func _guard_observe_retreat() -> void:
	if finishing or aborted or not is_instance_valid(guard_source) or not is_instance_valid(game):
		if physics_frame.is_connected(_guard_observe_retreat): physics_frame.disconnect(_guard_observe_retreat)
		return
	if paused: return
	var response: Dictionary = guard_source.get_spore_response_state()
	if response.get("phase", "") != "retreat": return
	guard_retreat_observed = response.duplicate(true)
	physics_frame.disconnect(_guard_observe_retreat)
	guard_retreat_pause_requested = game.call("request_pause_deferred")


func _guard_art(expected_pose: String, label: String) -> bool:
	var art: Node3D = guard_source.get_art()
	return _require(art != null and String(art.call("role_id")) == "A1-E3" and String(art.call("pose_name")) == expected_pose and guard_source.art_binding_error().is_empty(), "C32 " + label + " uses the actual stamp-selected known clockless pose with its retained body/feet/sprite settings")


func _guard_framing(label: String) -> bool:
	var points: Array = level.camera_framing_points()
	var actual_error: String = game.call("camera_framing_error", points)
	if not actual_error.is_empty() or not level.last_camera_framing_error.is_empty(): _guard_diagnostic("framing " + label)
	return _framing("C32 " + label)


func _guard_diagnostic(label: String) -> void:
	if not is_instance_valid(guard_source): return
	if is_instance_valid(level.get("spore_field")):
		print("C32 ACTUAL FIELD DIAGNOSTIC ", label, " field=", level.get("spore_field").state(), " Player_records=", hero.get_world_action_records(), " Player_HP=", hero.hp, " enemy_hit_events=", hit_events)
	var points: Array = level.camera_framing_points()
	points.append_array(game.call("player_camera_framing_points"))
	var camera: Camera3D = game.get("camera") as Camera3D
	var projected: Array = []
	for point: Vector3 in points: projected.append(camera.global_basis.inverse() * point)
	var bounds := AABB(projected[0], Vector3.ZERO) if not projected.is_empty() else AABB()
	for point: Vector3 in projected: bounds = bounds.expand(point)
	print("C32 COMPLETE CAMERA UNION DIAGNOSTIC ", label, " count=", points.size(), " camera_axes_bounds=", bounds, " width=", camera.size, " viewport=", camera.get_viewport().size, " safe_rect=", (game.get("hud") as GameHUD).combat_safe_rect(), " actual_native_forecast=", level.get("_forecast_points"), " field_origin=", (level.get("spore_field") as Node3D).global_position)
	print("C32 SPORE DIAGNOSTIC ", label, " response=", guard_source.get_spore_response_state(), " native=", guard_source.pure_presentation_state(), " control=", scheduler.source_control_state(guard_source), " consumer=", level.get("spore_consumer").source_state(GuardSourceId) if is_instance_valid(level.get("spore_consumer")) else {}, " component_error=", level.get("last_component_error"), " camera=", game.call("get_camera_framing_state"), " paused=", paused)
