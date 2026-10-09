extends "res://tests/acts/act1/a1_l3_spore_guard.gd"
## Actual C32 first episode plus finite two-supply
## continuation in that same world/field. The original guard fixture is intact.
## No teleports, actor damage, lease/phase/clock seeds or direct source commands.

const FiniteBodySweep = preload("res://scripts/combat/body_sweep.gd")
const FiniteGeometry = preload("res://scripts/combat/threat_geometry.gd")

var finite_escape_plan: Dictionary = {}
var finite_escape_samples: Array[Dictionary] = []
var finite_escape_error: String = ""
var finite_escape_dash_start_s: float = -1.0
var finite_escape_dash_end_s: float = -1.0
var finite_escape_record: Dictionary = {}
var finite_escape_completion_pending: bool = false
var finite_activations: Array[Dictionary] = []
var finite_reactions: Array[Dictionary] = []
var finite_observations: Array[Dictionary] = []
var finite_observed_phase: Dictionary = {}
var finite_next_phase: String = ""
var finite_phase_pause_requested: bool = false


func _watchdog() -> void:
	# This distinct two-release trace adds two input approaches and six native
	# capture/transport barriers to the original one-release fixture. Keep every
	# native wait/timing assertion; bound this longer graphical work separately.
	if not finishing and Time.get_ticks_msec() - started_ms > 180000:
		_require_unexpected(false, "finite two-release fixture completes within180 seconds")
		_finish.call_deferred()


func _run() -> void:
	portrait = "--portrait" in OS.get_cmdline_user_args()
	root.size = PortraitSize
	if portrait:
		if not _require(DisplayServer.get_name() != "headless", "guard spore portrait requires the actual renderer"):
			await _finish(); return
		capture_dir = "res://.cinder/captures/l3-guard-finite-%d" % Time.get_ticks_usec()
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
	field.activated.connect(func(domain: Dictionary) -> void: finite_activations.append(domain.duplicate(true)))
	field.state_changed.connect(func(_state: Dictionary) -> void: cluster_events += 1)
	for cluster_id: String in ["cluster-left", "cluster-right"]:
		var cue: Node3D = _actual_cluster_cue(field.get_node(cluster_id) as Node3D)
		if not _require(cue != null, "finite continuation retains each actual native interaction cue"):
			await _finish(); return
		cue.connect("state_changed", func(_state: Dictionary) -> void: cluster_events += 1)
	consumer.reaction_started.connect(func(id: String, episode_id: String) -> void:
		if id != GuardSourceId: return
		guard_episode_id = episode_id
		finite_reactions.append({"source_id": id, "episode_id": episode_id})
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
	if not await _guard_phase_capture("recoil", "recoil", false, false) or not await _finite_resume_until_phase("turn"):
		await _finish(); return
	if not await _guard_phase_capture("turn", "recoil", false, false) or not await _guard_resume_into_short_retreat():
		await _finish(); return
	if not await _guard_phase_capture("retreat", "retreat", true):
		await _finish(); return
	if not await _guard_phase_capture("hold", "regroup"):
		await _finish(); return
	if not _require(_planar_distance(guard_source.global_position, guard_start_position) > 0.02 and _planar_distance(guard_source.global_position, field.global_position) > 1.5 + float(guard_source.get_spore_response_state().support_radius) + 0.08 and guard_source.velocity == Vector3.ZERO, "stationary native guard really moved under the shared environmental Route and now holds its supported outside-union landing"):
		_guard_diagnostic("held endpoint"); await _finish(); return
	if not await _refuse_active_anchor(field):
		_guard_diagnostic("active supply refusal"); await _finish(); return
	if not await _guard_phase_capture("regroup", "regroup", false, false) or not await _finite_resume_until_phase("none"):
		await _finish(); return
	if not await _guard_phase_capture("none", "", false, false):
		await _finish(); return
	var final: Dictionary = guard_source.pure_presentation_state()
	var records: Array[Dictionary] = hero.get_world_action_records()
	if not _require(records.size() == 3 and records[0].kind == "dash" and records[1].kind == "primary" and records[2].kind == "primary" and records[1].hits == 0 and records[2].hits == 0 and swipes == 1 and primaries == 2 and guard_source.hp == 24.0 and hero.hp == initial_hp and hit_events.is_empty() and field.state().generation == 1 and field.state().spent_ids == ["cluster-right"] and field.state().remaining_clusters == 1 and not level.is_completed(), "one real swipe and release/refusal primaries preserve the original harmless C32 episode and one remaining finite supply"):
		_guard_diagnostic("final resources"); await _finish(); return
	if not await _second_supply(field):
		_guard_diagnostic("second supply continuation"); await _finish(); return
	print("C32 FINITE DEPLETION first_original_lease=", guard_native_lease, " original_cooldown=", guard_native_cooldown, " first_final_native=", final, "; second episode is counted only if actually published")
	await _finish()


func _refuse_active_anchor(field: CinderSporeField) -> bool:
	if not paused and not await _pause_pair("actual held field before extra ordinary hit"): return false
	var before: Dictionary = field.state()
	var left := field.get_node("cluster-left") as Node3D
	var aim: Vector3 = _safe_cluster_aim(left)
	var response: Dictionary = guard_source.get_spore_response_state()
	if not _require(before.generation == 1 and before.spent_ids == ["cluster-right"] and before.phase in ["active", "thinning"] and float(before.deadline_s) - float(before.clock_s) > 0.45 and left.call("get_cue_state").state == "active" and response.phase == "hold" and aim != Vector3.ZERO, "one genuinely unspent active anchor is reachable with an actual aim that excludes the living held guard"): return false
	if not _guard_quiet_component("before active-anchor refusal") or not _guard_framing("before active-anchor refusal") or not await _capture("active-before-refusal") or not await _gui_resume_pair(): return false
	var reactions_before: int = finite_reactions.size()
	if not await _finite_primary(left, aim, "extra hit on the genuine unspent active anchor", false): return false
	if not await _pause_pair("actual field after refused extra primary"): return false
	var after: Dictionary = field.state()
	if not _require(after.generation == before.generation and after.spent_ids == before.spent_ids and after.activation_s == before.activation_s and after.deadline_s == before.deadline_s and float(after.clock_s) >= float(before.clock_s) and after.phase in ["active", "thinning"] and finite_activations.size() == 1 and finite_reactions.size() == reactions_before and left.call("get_cue_state").state == "active" and hero.hp == initial_hp and guard_source.hp == 24.0 and hit_events.is_empty(), "the real active-anchor primary refuses supply/deadline refresh and creates no new episode, damage or activation"): return false
	finite_observations.append({"kind": "active_refusal", "before": before, "after": after, "aim": aim})
	if not _guard_quiet_component("after active-anchor refusal") or not _guard_framing("after active-anchor refusal") or not await _capture("active-refused"): return false
	return await _finite_resume_until_phase("regroup")


func _finite_resume_until_phase(phase: String) -> bool:
	# Render polling can miss a short phase. Observe the real native state at
	# physics_frame and request the existing whole-tick barrier; never run a tick.
	finite_next_phase = phase
	finite_observed_phase.clear()
	finite_phase_pause_requested = false
	physics_frame.connect(_finite_observe_phase)
	var button: Button = _resume_button(game.get("hud") as Node)
	if not _require(button != null and paused, "finite phase observer uses the actual shared Resume button"):
		physics_frame.disconnect(_finite_observe_phase)
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
	var reached: bool = await _wait(func() -> bool: return paused, "finite actual " + phase + " reaches its observer-requested deferred barrier", 5.0, true)
	if physics_frame.is_connected(_finite_observe_phase): physics_frame.disconnect(_finite_observe_phase)
	if not reached: return false
	finite_observations.append({"kind": "physics_phase_barrier", "pre_tick": finite_observed_phase.duplicate(true), "actual_paused": guard_source.get_spore_response_state()})
	return _require(finite_phase_pause_requested and finite_observed_phase.get("phase") == phase and guard_source.get_spore_response_state().phase == phase and game.call("get_input_observation_state") == input_before and hero.get_world_action_records() == records_before, "finite native " + phase + " observer and GUI Resume preserve actual phase/input/action custody")


func _finite_observe_phase() -> void:
	if finishing or aborted or not is_instance_valid(guard_source) or not is_instance_valid(game):
		if physics_frame.is_connected(_finite_observe_phase): physics_frame.disconnect(_finite_observe_phase)
		return
	if paused: return
	var response: Dictionary = guard_source.get_spore_response_state()
	if response.get("phase") != finite_next_phase: return
	finite_observed_phase = response.duplicate(true)
	physics_frame.disconnect(_finite_observe_phase)
	finite_phase_pause_requested = game.call("request_pause_deferred")


func _second_supply(field: CinderSporeField) -> bool:
	var left := field.get_node("cluster-left") as Node3D
	var before: Dictionary = field.state()
	if not _require(paused and before.generation == 1 and before.spent_ids == ["cluster-right"] and before.phase == "available" and left.call("get_cue_state").state == "available" and guard_source.get_spore_response_state().phase == "none", "first genuine fade leaves exactly the previously unspent anchor available in this same field"): return false
	# The following are input proposals, not collision/safety certificates. Full
	# native dash records and actual warning deadlines must establish viability.
	var stats: Dictionary = hero.equipment.resolved_stats()
	var distance: float = float(stats.dash_distance)
	var first_landing: Vector3 = hero.global_position + Vector3.RIGHT * distance
	var finish_x: float = left.global_position.x + 0.04
	var delta_x: float = finish_x - first_landing.x
	if not _require(absf(delta_x) < distance, "actual dash distance permits a second full diagonal proposal toward the remaining anchor"): return false
	var delta_z: float = -sqrt(distance * distance - delta_x * delta_x)
	var second_direction := Vector3(delta_x, 0, delta_z).normalized()
	var proposed_landing: Vector3 = first_landing + second_direction * distance
	if not _require(_planar_distance(proposed_landing, left.global_position) <= float(stats.primary_range), "two actual-length input proposals finish in ordinary range of the remaining anchor"): return false
	finite_observations.append({"kind": "reapproach_proposal", "actual_hero": hero.global_position, "actual_guard": guard_source.global_position, "distance": distance, "first_landing": first_landing, "second_landing": proposed_landing})
	if not await _gui_resume_pair(): return false
	if not await _wait(func() -> bool:
		var native: Dictionary = guard_source.pure_presentation_state()
		return native.phase in ["warning", "lock"] and native.reservation_id != guard_native_lease and int(native.cycle) > guard_native_cycle, "reapproach starts only after a real fresh native C32 warning", 5.0): return false
	if not await _pause_pair("fresh native warning before two full reapproach swipes"): return false
	var context: Dictionary = level.call("response_context", "A1-E3")
	var input_pad: float = float(context.recognition_s) + float(context.attack_input_margin_s)
	var dash_cycle: float = maxf(float(stats.dash_duration), float(stats.dash_cooldown))
	if not _warning_lead(2.0 * dash_cycle + 3.0 * input_pad + float(stats.primary_cooldown), "genuine fresh warning covers the proposed reapproach and immediate primary"): return false
	if not _guard_read_component("fresh native reapproach warning") or not _guard_framing("fresh native reapproach warning") or not await _capture("fresh-reapproach-warning") or not await _gui_resume_pair(): return false
	if not await _swipe(Vector3.RIGHT, "first real full reapproach swipe"): return false
	# Recompute from the actual stopped first landing; never set Hero position.
	delta_x = finish_x - hero.global_position.x
	if not _require(absf(delta_x) < distance, "actual first landing still permits the proposed full diagonal"): return false
	delta_z = -sqrt(distance * distance - delta_x * delta_x)
	second_direction = Vector3(delta_x, 0, delta_z).normalized()
	if not await _swipe(second_direction, "second real full diagonal to the remaining anchor"): return false
	var aim: Vector3 = _safe_cluster_aim(left)
	if not _require(aim != Vector3.ZERO and field.state().generation == 1 and left.call("get_cue_state").state == "available", "actual second landing reaches the final available anchor with no living-enemy primary overlap"): return false
	# New primary cooldown starts at the immediate hit, not before it. The
	# inherited readiness helper has already observed zero current cooldowns.
	var before_primary: Dictionary = hero.get_threat_response_state()
	var before_cost: float = _finite_ready_wait(before_primary) + 2.0 * input_pad
	finite_observations.append({"kind": "before_second_release_cost", "response": before_primary, "required_s": before_cost, "control": scheduler.source_control_state(guard_source)})
	if not _warning_lead(before_cost, "actual reapproach retains native warning time for the immediate second release"): return false
	var previous_reactions: int = finite_reactions.size()
	if not await _finite_primary(left, aim, "second ordinary release consumes the final real anchor", true): return false
	if not paused and not await _pause_pair("complete second release boundary"): return false
	var released: Dictionary = field.state()
	if not _require(released.generation == 2 and released.remaining_clusters == 0 and released.spent_ids == ["cluster-right", "cluster-left"] and float(released.activation_s) >= float(before.deadline_s) and float(released.deadline_s) == float(released.activation_s) + 3.0 and finite_activations.size() == 2 and (level.get("spore_consumer") as CinderSporeRepulsion).placement_accepted() and hero.hp == initial_hp and guard_source.hp == 24.0 and hit_events.is_empty(), "same actual field consumes its second finite supply after expiry without hurting either living actor"): return false
	finite_observations.append({"kind": "second_release", "field": released, "second_episode_published": finite_reactions.size() > previous_reactions, "source": guard_source.get_spore_response_state()})
	# No new environmental episode is required if the actual guard is outside
	# the expanded domain. A surviving live native lease still needs real lead.
	var response: Dictionary = hero.get_threat_response_state()
	# Pay the actual new primary recovery before the next recognizer dash.
	# Travel takes dash_duration; its later cooldown is held at a proved-safe
	# landing through the actual native active interval, not erased.
	var escape_cost: float = _finite_ready_wait(response) + input_pad + float(stats.dash_duration)
	if not _warning_lead(escape_cost, "second release retains a real RIGHT escape before any surviving native danger", true): return false
	if not await _finite_barrier("second-release") or not await _finite_real_right_escape(input_pad): return false
	if not await _wait(func() -> bool: return field.state().phase == "spent" and guard_source.get_spore_response_state().phase == "none", "second real field expires and any genuinely acquired environmental episode ends", 6.0): return false
	if not await _pause_pair("two genuinely spent supplies"): return false
	var final: Dictionary = field.state()
	var records: Array[Dictionary] = hero.get_world_action_records()
	if not _require(final.generation == 2 and final.remaining_clusters == 0 and final.spent_ids == released.spent_ids and final.activation_s == released.activation_s and final.deadline_s == released.deadline_s and finite_activations.size() == 2 and (field.get_node("cluster-right") as Node3D).call("get_cue_state").state == "spent" and left.call("get_cue_state").state == "spent" and records.size() == 7 and swipes == 4 and primaries == 3 and world_records.size() == records.size() and input_observations.size() == records.size() and hero.hp == initial_hp and guard_source.hp == 24.0 and not guard_source.dead and hit_events.is_empty() and not level.is_completed(), "four genuine swipes and three ordinary primaries finish two permanently spent anchors with intact HP, exact records and no campaign completion"): return false
	var primaries_seen: int = 0
	for record: Dictionary in records:
		if record.kind == "primary":
			primaries_seen += 1
			if not _require(record.hits == 0, "every real finite-field primary has zero living-enemy hit credit"): return false
	if not _require(primaries_seen == 3 and cluster_negatives_done and observed_cluster_states.has("available") and observed_cluster_states.has("active") and observed_cluster_states.has("spent"), "exact primary trace and real quiet barriers include refusal and all honest native cluster drawings"): return false
	finite_observations.append({"kind": "depleted", "field": final, "source": guard_source.get_spore_response_state()})
	return await _finite_barrier("two-spent")


func _finite_ready_wait(response: Dictionary) -> float:
	# These three clocks advance concurrently. Preserve the inherited all-zero
	# readiness requirement, including the new post-primary cooldown.
	return maxf(float(response.primary_cooldown_left_s), maxf(float(response.dash_cooldown_left_s), float(response.commitment_remaining_s)))


func _finite_body_binding(body: CharacterBody3D) -> Dictionary:
	var measured: Dictionary = FiniteBodySweep.source_description(body)
	if measured.has("error"): return {}
	var collision: CollisionShape3D = measured.collision
	if collision != body.get_node_or_null("BodyCollision") or not collision.shape is CapsuleShape3D: return {}
	var capsule := collision.shape as CapsuleShape3D
	# Reuse the shared Scheduler's actual capsule/feet contract and tolerance.
	if not is_equal_approx(capsule.radius, CinderThreatScheduler.CAPSULE_RADIUS) or not is_equal_approx(capsule.height, CinderThreatScheduler.CAPSULE_HEIGHT) or not collision.position.is_equal_approx(Vector3(0, CinderThreatScheduler.CAPSULE_CENTER_Y, 0)): return {}
	return {"body": body, "collision": collision, "shape": capsule, "transform": collision.transform, "radius": capsule.radius, "height": capsule.height, "bias": capsule.custom_solver_bias, "safe_margin": body.safe_margin, "layer": body.collision_layer, "mask": body.collision_mask, "description": measured}


func _finite_escape_custody_error() -> String:
	for key: String in ["hero_body", "guard_body"]:
		var saved: Dictionary = finite_escape_plan[key]
		if not is_instance_valid(saved.body) or not is_instance_valid(saved.collision) or not is_instance_valid(saved.shape): return "Retained actual native capsule resources unavailable"
		var actual: Dictionary = _finite_body_binding(saved.body)
		if actual != saved: return "Retained native capsule identity/dimensions/transform/physics changed"
	var retained_floor: Variant = finite_escape_plan.floor
	if not is_instance_valid(retained_floor) or not is_instance_valid(finite_escape_plan.floor_body): return "Retained actual supported floor resources unavailable"
	var floor := retained_floor as CollisionShape3D
	if not is_instance_valid(floor) or not floor.is_inside_tree() or floor.is_queued_for_deletion() or floor.disabled or floor.shape != finite_escape_plan.floor_shape or floor.global_transform != finite_escape_plan.floor_transform or (floor.shape as BoxShape3D).size != finite_escape_plan.floor_size or floor.get_parent() != finite_escape_plan.floor_body or finite_escape_plan.floor_body.collision_layer != finite_escape_plan.floor_layer or finite_escape_plan.floor_body.collision_mask != finite_escape_plan.floor_mask or finite_escape_plan.floor_body.constant_linear_velocity != finite_escape_plan.floor_velocity or finite_escape_plan.floor_body.constant_angular_velocity != finite_escape_plan.floor_angular_velocity or (floor.shape as BoxShape3D).custom_solver_bias != finite_escape_plan.floor_bias: return "Actual supported floor binding changed"
	var context: Dictionary = level.call("response_context", "A1-E3")
	if context.floor_regions != finite_escape_plan.floor_regions or context.world_root != finite_escape_plan.world_root: return "Actual response floor/world references changed"
	if hero.equipment.resolved_stats() != finite_escape_plan.stats or hero.equipment.snapshot() != finite_escape_plan.equipment_ids: return "Actual RIGHT action equipment/stat snapshot changed"
	var control: Dictionary = scheduler.source_control_state(guard_source)
	if control.is_empty() or not control.outside_transaction or control.encounter_id != finite_escape_plan.encounter_id or control.world_revision != finite_escape_plan.world_revision or control.cooldown != finite_escape_plan.cooldown: return "Actual native source control/cooldown changed"
	var lease: Dictionary = finite_escape_plan.lease
	if lease.is_empty():
		if not control.reservations.is_empty(): return "A new native lease appeared during the genuinely lease-free escape"
	else:
		if control.reservations.size() != 1: return "The surviving fixed native lease disappeared or multiplied"
		var actual: Dictionary = control.reservations[0]
		if actual.size() != lease.size(): return "Surviving native lease record shape changed"
		for key: String in lease:
			if key != "state" and actual.get(key) != lease[key]: return "Surviving lease identity/geometry/time/source changed: " + key
		var native: Dictionary = guard_source.pure_presentation_state()
		if native.reservation_id != lease.id or native.geometry != lease.geometry or native.source_position != lease.source_position or native.opening_position != lease.opening_position or native.cycle != finite_escape_plan.cycle: return "Actual actor stopped owning the same fixed native lane/cycle"
	var support: Dictionary = guard_source.get_spore_response_state()
	if support.is_empty() or not support.alive or not support.grounded or (not lease.is_empty() and guard_source.velocity != Vector3.ZERO) or guard_source.hp != 24.0 or hero.hp != initial_hp or not hit_events.is_empty(): return "Living supported C32/Hero or harmless hit custody changed"
	return ""


func _finite_escape_plan_right(input_pad: float) -> bool:
	var control: Dictionary = scheduler.source_control_state(guard_source)
	var context: Dictionary = level.call("response_context", "A1-E3")
	var response: Dictionary = hero.get_threat_response_state()
	var hero_body: Dictionary = _finite_body_binding(hero)
	var guard_body: Dictionary = _finite_body_binding(guard_source)
	var bindings: Dictionary = level.call("scheduler_bindings")
	if not _require(paused and response.stable and not hero_body.is_empty() and not guard_body.is_empty() and game.get("player") == hero and bindings.owners.get(GuardSourceId) == guard_source and not control.is_empty() and control.outside_transaction and control.reservations.size() <= 1 and context.floor_regions.size() == 1, "RIGHT escape plan uses actual native Player/C32 capsules, complete barrier and one actual floor"): return false
	var floor: CollisionShape3D = context.floor_regions[0].collision
	if not _require(is_instance_valid(floor) and floor.shape is BoxShape3D and floor.get_parent() is StaticBody3D and bindings.floors["mushroom-floor"].collision == floor and bindings.floors["mushroom-floor"].safe_rect == context.floor_regions[0].safe_rect, "RIGHT escape uses the parent's actual supported floor references and safe rectangle"): return false
	var lease: Dictionary = {} if control.reservations.is_empty() else control.reservations[0].duplicate(true)
	var native: Dictionary = guard_source.pure_presentation_state()
	if not lease.is_empty() and not _require(lease.state in ["warning", "lock"] and not lease.has("adapter") and native.role_id == "A1-E3" and native.entity_id == "C32" and native.reservation_id == lease.id and native.geometry == lease.geometry and lease.geometry.kind == "lane" and lease.source_instance_id == guard_source.get_instance_id() and lease.source_position == guard_source.global_position and lease.opening_position == guard_source.global_position and absf((lease.geometry["to"] as Vector3).distance_to(lease.geometry["from"]) - 2.0) <= PositionTolerance and absf(float(lease.geometry.radius) - 0.38) <= 0.00001, "surviving danger is the same actual stationary C32 two-meter native lane, not a substituted proof"): return false
	var stats: Dictionary = response.stats
	var measured: Dictionary = FiniteBodySweep.sweep(hero, hero.global_transform, Vector3.RIGHT * float(stats.dash_distance), context.floor_regions)
	var source_support: Dictionary = FiniteBodySweep.sweep(guard_source, guard_source.global_transform, Vector3.ZERO, context.floor_regions)
	if not _require(not measured.has("error") and not measured.get("collided", true) and not source_support.has("error") and (measured.end as Vector3).distance_to(hero.global_position + Vector3.RIGHT * float(stats.dash_distance)) <= PositionTolerance, "native full RIGHT BodySweep and grounded C32 use actual scenery/capsule support without shortening"): return false
	var clock: float = float(control.clock_s)
	var dash_start: float = clock + _finite_ready_wait(response) + input_pad
	var dash_end: float = dash_start + float(stats.dash_duration)
	var held_until: float = maxf(dash_start + float(stats.dash_cooldown), float(lease.get("active_until_s", dash_end)))
	var padded_radius: float = float(hero_body.radius) + CinderThreatScheduler.SKIN
	var path: Array[Dictionary] = [
		{"from": hero.global_position, "to": hero.global_position, "start_s": clock, "end_s": dash_start},
		{"from": hero.global_position, "to": measured.end, "start_s": dash_start, "end_s": dash_end},
		{"from": measured.end, "to": measured.end, "start_s": dash_end, "end_s": held_until},
	]
	if not lease.is_empty() and not _require(dash_end < float(lease.active_from_s) and not FiniteGeometry.timed_path_hits(lease.geometry, path, float(lease.active_from_s), float(lease.active_until_s), padded_radius) and not FiniteGeometry.segment_hits(lease.geometry, measured.end, measured.end, padded_radius), "remaining primary recovery plus actual RIGHT travel and held full capsule clear the surviving native lane through active_until"): return false
	finite_escape_plan = {"hero_body": hero_body, "guard_body": guard_body, "floor": floor, "floor_shape": floor.shape, "floor_transform": floor.global_transform, "floor_size": (floor.shape as BoxShape3D).size, "floor_body": floor.get_parent(), "floor_layer": (floor.get_parent() as StaticBody3D).collision_layer, "floor_mask": (floor.get_parent() as StaticBody3D).collision_mask, "floor_velocity": (floor.get_parent() as StaticBody3D).constant_linear_velocity, "floor_angular_velocity": (floor.get_parent() as StaticBody3D).constant_angular_velocity, "floor_bias": (floor.shape as BoxShape3D).custom_solver_bias, "floor_regions": context.floor_regions, "world_root": context.world_root, "encounter_id": control.encounter_id, "world_revision": control.world_revision, "cooldown": control.cooldown, "lease": lease, "cycle": native.cycle, "stats": stats, "equipment_ids": response.equipment_ids, "input_pad": input_pad, "radius": padded_radius, "origin": hero.global_position, "landing": measured.end, "sequence": _last_sequence() + 1}
	finite_observations.append({"kind": "post_second_release_right_plan", "response": response, "control": control, "required_s": dash_end - clock, "native_sweep_end": measured.end, "padded_capsule_radius": padded_radius, "path": path})
	return _require(_finite_escape_custody_error().is_empty(), "RIGHT plan retains unchanged actual source/body/floor/control custody")


func _finite_escape_sample() -> void:
	if finishing or aborted or finite_escape_plan.is_empty() or not finite_escape_error.is_empty(): return
	finite_escape_error = _finite_escape_custody_error()
	if not finite_escape_error.is_empty(): return
	var clock: float = scheduler.get_clock()
	var position: Vector3 = hero.global_position
	if not finite_escape_samples.is_empty():
		var previous: Dictionary = finite_escape_samples.back()
		if clock < float(previous.clock_s) or (clock == float(previous.clock_s) and position != previous.position):
			finite_escape_error = "Actual physics-boundary position/clock lost monotonic whole-tick custody"; return
		if clock == float(previous.clock_s): return
		if clock - float(previous.clock_s) > 1.0 / float(Engine.physics_ticks_per_second) + FiniteGeometry.EPSILON:
			finite_escape_error = "An actual native physics path interval was not observed"; return
	finite_escape_samples.append({"clock_s": clock, "position": position})
	if finite_escape_completion_pending:
		# This SceneTree physics_frame observes the previous whole native tick.
		# Do not relabel Player's separate action clock as Scheduler time.
		finite_escape_completion_pending = false
		finite_escape_dash_end_s = clock


func _finite_escape_fired(kind: String) -> void:
	if kind != "dash" or finite_escape_dash_start_s >= 0.0:
		finite_escape_error = "RIGHT escape published an unexpected extra player action"; return
	finite_escape_error = _finite_escape_custody_error()
	if not finite_escape_error.is_empty(): return
	var dash: Dictionary = hero.get_committed_dash_state()
	finite_escape_dash_start_s = scheduler.get_clock()
	var lease: Dictionary = finite_escape_plan.lease
	if not dash.get("active", false) or (dash.direction as Vector3).dot(Vector3.RIGHT) <= 0.9999 or float(dash.distance) != float(finite_escape_plan.stats.dash_distance) or float(dash.speed) != float(finite_escape_plan.stats.dash_speed) or float(dash.duration_s) != float(finite_escape_plan.stats.dash_duration) or float(dash.remaining_s) != float(dash.duration_s) or (dash.origin as Vector3).distance_to(finite_escape_plan.origin) > PositionTolerance or (not lease.is_empty() and finite_escape_dash_start_s + float(dash.duration_s) >= float(lease.active_from_s)):
		finite_escape_error = "Actual accepted RIGHT dash does not retain full travel before native active"


func _finite_escape_completed(record: Dictionary) -> void:
	if record.kind != "dash" or record.sequence != finite_escape_plan.sequence or finite_escape_dash_start_s < 0.0 or not finite_escape_record.is_empty():
		finite_escape_error = "RIGHT escape completed an unexpected action sequence"; return
	finite_escape_record = record.duplicate(true)
	finite_escape_completion_pending = true


func _finite_escape_stop() -> void:
	if physics_frame.is_connected(_finite_escape_sample): physics_frame.disconnect(_finite_escape_sample)
	if is_instance_valid(hero):
		if hero.fired.is_connected(_finite_escape_fired): hero.fired.disconnect(_finite_escape_fired)
		if hero.world_action_executed.is_connected(_finite_escape_completed): hero.world_action_executed.disconnect(_finite_escape_completed)


func _finite_real_right_escape(input_pad: float) -> bool:
	if not _finite_escape_plan_right(input_pad): return false
	finite_escape_samples.clear(); finite_escape_error = ""
	finite_escape_dash_start_s = -1.0; finite_escape_dash_end_s = -1.0
	finite_escape_record.clear(); finite_escape_completion_pending = false
	_finite_escape_sample()
	physics_frame.connect(_finite_escape_sample)
	hero.fired.connect(_finite_escape_fired)
	hero.world_action_executed.connect(_finite_escape_completed)
	if not await _gui_resume_pair() or not await _ready_input("RIGHT escape actual post-primary readiness"):
		_finite_escape_stop(); return false
	var control: Dictionary = scheduler.source_control_state(guard_source)
	var lease: Dictionary = finite_escape_plan.lease
	if not _require(finite_escape_error.is_empty() and _finite_escape_custody_error().is_empty() and (lease.is_empty() or float(lease.active_from_s) - float(control.clock_s) > input_pad + float(finite_escape_plan.stats.dash_duration)), "after real GUI Resume and actual recovery, the same RIGHT escape still has native input/travel lead"):
		_finite_escape_stop(); return false
	if not await _swipe(Vector3.RIGHT, "real full RIGHT escape after second release"):
		_finite_escape_stop(); return false
	var held_until: float = maxf(finite_escape_dash_start_s + float(finite_escape_plan.stats.dash_cooldown), float(lease.get("active_until_s", scheduler.get_clock())))
	if not await _wait(func() -> bool: return not finite_escape_error.is_empty() or scheduler.get_clock() >= held_until, "actual RIGHT landing holds through native active and post-landing cooldown", 8.0):
		_finite_escape_stop(); return false
	_finite_escape_sample()
	_finite_escape_stop()
	finite_observations.append({"kind": "actual_right_escape", "samples": finite_escape_samples.duplicate(true), "dash_started_native_s": finite_escape_dash_start_s, "dash_completed_native_s": finite_escape_dash_end_s, "world_action": finite_escape_record.duplicate(true), "held_until_native_s": held_until, "error": finite_escape_error})
	if not _require(finite_escape_error.is_empty() and not finite_escape_record.is_empty() and finite_escape_dash_start_s >= 0.0 and finite_escape_dash_end_s >= finite_escape_dash_start_s + float(finite_escape_plan.stats.dash_duration) and finite_escape_record.resolved_stats == finite_escape_plan.stats and not finite_escape_completion_pending and finite_escape_samples.size() >= 2 and hero.get_world_action_records(finite_escape_plan.sequence - 1) == [finite_escape_record] and hero.hp == initial_hp and guard_source.hp == 24.0 and hit_events.is_empty(), "one actual full RIGHT action has complete native-time/position samples and unchanged HP/zero enemy hits: " + finite_escape_error): return false
	var path: Array[Dictionary] = []
	for index: int in range(1, finite_escape_samples.size()):
		var a: Dictionary = finite_escape_samples[index - 1]
		var b: Dictionary = finite_escape_samples[index]
		path.append({"from": a.position, "to": b.position, "start_s": a.clock_s, "end_s": b.clock_s})
		var from := Transform3D(hero.global_basis, a.position)
		var measured: Dictionary = FiniteBodySweep.sweep(hero, from, b.position - a.position, finite_escape_plan.floor_regions)
		if not _require(not measured.has("error") and not measured.get("collided", true) and (measured.end as Vector3).distance_to(b.position) <= PositionTolerance, "every actually observed RIGHT wait/motion/landing interval retains native scenery and capsule support"): return false
	# Every published real dash sample must have been observed at an actual
	# whole physics boundary; never assign it invented Scheduler timestamps.
	var cursor: int = 0
	for point: Dictionary in finite_escape_record.path:
		while cursor < finite_escape_samples.size() and finite_escape_samples[cursor].position != point.position: cursor += 1
		if not _require(cursor < finite_escape_samples.size(), "each real dash-record position appears in the ordered native physics trace"): return false
	if not lease.is_empty() and not _require(finite_escape_dash_end_s < float(lease.active_from_s) and float(finite_escape_samples.back().clock_s) >= float(lease.active_until_s) and not FiniteGeometry.timed_path_hits(lease.geometry, path, float(lease.active_from_s), float(lease.active_until_s), float(finite_escape_plan.radius)) and not FiniteGeometry.segment_hits(lease.geometry, hero.global_position, hero.global_position, float(finite_escape_plan.radius)), "the real full RIGHT path completes before active and its full held capsule remains outside the unchanged native lane through active_until"): return false
	return _guard_framing("actual second-release RIGHT landing")


func _warning_lead(required_s: float, label: String, allow_no_lease: bool = false) -> bool:
	var control: Dictionary = scheduler.source_control_state(guard_source)
	var records: Array = control.get("reservations", [])
	if records.is_empty(): return _require(allow_no_lease and not control.is_empty(), label + " has no actual native hazard lease")
	return _require(records.size() == 1 and records[0].state in ["warning", "lock"] and float(records[0].active_from_s) - float(control.clock_s) > required_s, label + " uses the actual native active deadline and current clock")


func _safe_cluster_aim(cluster: Node3D) -> Vector3:
	# Fixed direction candidates are fixture input proposals, never auto-aim.
	var directions: Array[Vector3] = [Vector3.RIGHT]
	for index: int in range(32):
		var angle: float = TAU * float(index) / 32.0
		directions.append(Vector3(cos(angle), 0, sin(angle)))
	for direction: Vector3 in directions:
		if _primary_geometry(cluster, direction): return direction
	return Vector3.ZERO


func _primary_geometry(cluster: Node3D, direction: Vector3) -> bool:
	var stats: Dictionary = hero.equipment.resolved_stats()
	var target: Vector3 = cluster.global_position - hero.global_position
	var vertical: float = absf(target.y)
	target.y = 0.0
	var cone: float = float(stats.primary_cone_min_dot)
	if not cluster.is_in_group("environment_attack_targets") or target.length() > float(stats.primary_range) or vertical > CinderPlayer.ATTACK_MAX_VERTICAL_DISTANCE or target.length() <= CinderPlayer.ATTACK_ORIGIN_DISK_RADIUS or target.normalized().dot(direction) < cone + 0.02: return false
	var ray := PhysicsRayQueryParameters3D.create(hero.global_position + Vector3.UP * CinderPlayer.ATTACK_LOS_HEIGHT, cluster.global_position + Vector3.UP * CinderPlayer.ATTACK_LOS_HEIGHT, CinderPlayer.ATTACK_SCENERY_MASK)
	if not hero.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return false
	for node: Node in get_nodes_in_group("enemies"):
		var enemy := node as Node3D
		var offset: Vector3 = enemy.global_position - hero.global_position
		offset.y = 0.0
		if offset.length() <= float(stats.primary_range) and (offset.length() <= CinderPlayer.ATTACK_ORIGIN_DISK_RADIUS or offset.normalized().dot(direction) >= cone - 0.02): return false
	return true


func _finite_primary(cluster: Node3D, direction: Vector3, label: String, allow_reaction_pause: bool) -> bool:
	if not await _ready_input(label): return false
	while Time.get_ticks_msec() - last_primary_ms <= 300:
		if not _guard_input(): return false
		await process_frame
	var anchor: Vector2 = game.call("get_aim_anchor")
	var tap: Vector2 = anchor + _screen_delta(direction) * 160.0
	if not _require(_primary_geometry(cluster, direction) and _input_safe(tap) and (game.call("aim_direction", tap) as Vector3).dot(direction) > 0.9999, label + " uses actual native target reach/LOS/cone and literal last-release aiming without enemy overlap"): return false
	var sequence: int = _last_sequence()
	var reaction_count: int = finite_reactions.size()
	var press := InputEventScreenTouch.new()
	press.index = 7; press.pressed = true; press.position = tap
	Input.parse_input_event(press)
	await process_frame
	if not _guard_input(): return false
	if not _require(_primary_geometry(cluster, direction), label + " retains actual harmless target geometry immediately before release"): return false
	var release := InputEventScreenTouch.new()
	release.index = 7; release.position = tap
	hero.shells = 0 # Release-only fixture setup; passive reload remains enabled.
	Input.parse_input_event(release)
	await process_frame
	if allow_reaction_pause and finite_reactions.size() == reaction_count + 1:
		if not await _wait(func() -> bool: return paused, label + " genuine native reaction reaches its public deferred barrier", 2.0, true): return false
		if not _require(guard_source.get_spore_response_state().phase == "recoil", label + " pause retains the genuinely published recoil"): return false
	elif not _guard_input(): return false
	last_primary_ms = Time.get_ticks_msec()
	primaries += 1
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	var observation: Dictionary = game.call("get_input_observation_state").last_observation
	return _require(records.size() == 1 and records[0].kind == "primary" and records[0].hits == 0 and records[0].direction.dot(direction) > 0.9999 and observation.kind == "primary_tap" and observation.accepted and observation.world_action_sequence == records[0].sequence and game.call("get_aim_anchor") == anchor, label + " publishes one actual immediate ordinary primary with zero hit credit and unchanged anchor")


func _finite_barrier(label: String) -> bool:
	var control: Dictionary = scheduler.source_control_state(guard_source)
	if not _require(paused and not control.is_empty(), label + " reaches the actual complete native pause barrier"): return false
	if control.reservations.is_empty():
		if not _guard_quiet_component(label): return false
	else:
		if not _guard_read_component(label): return false
	if not _guard_framing(label + " full bodies, native footprint, clusters and prospective landings"): return false
	return await _capture(label)


func _finish() -> void:
	if finishing: return
	_finite_escape_stop()
	if is_instance_valid(level) and is_instance_valid(level.get("spore_field")):
		var report: Dictionary = {"scope": "actual C32 same-field finite two-supply continuation; no full L3/campaign/profile/gear proof", "observations": _portable(finite_observations), "activations": _portable(finite_activations), "actual_reactions": _portable(finite_reactions), "final_field": level.get("spore_field").state(), "checks": checks, "failures": failures, "swipes": swipes, "primaries": primaries}
		print("C32 FINITE ACTUAL OBSERVATIONS ", JSON.stringify(report))
		if not capture_dir.is_empty():
			var file: FileAccess = FileAccess.open(capture_dir.path_join("finite-evidence.json"), FileAccess.WRITE)
			if file != null:
				file.store_string(JSON.stringify(report, "\t"))
				file.close()
			file = null
	await super._finish()
