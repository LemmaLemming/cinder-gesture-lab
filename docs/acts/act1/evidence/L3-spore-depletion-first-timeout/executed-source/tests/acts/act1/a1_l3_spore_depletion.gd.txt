extends "res://tests/acts/act1/a1_l3_spore_guard.gd"
## Actual C32 first episode plus finite two-supply
## continuation in that same world/field. The original guard fixture is intact.
## No teleports, actor damage, lease/phase/clock seeds or direct source commands.

var finite_activations: Array[Dictionary] = []
var finite_reactions: Array[Dictionary] = []
var finite_observations: Array[Dictionary] = []


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
	if not await _refuse_active_anchor(field):
		_guard_diagnostic("active supply refusal"); await _finish(); return
	if not await _guard_phase_capture("regroup", "regroup"):
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
	if not await _pause_pair("actual held field before extra ordinary hit"): return false
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
	return await _gui_resume_pair()


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
	if not _warning_lead(2.0 * input_pad + float(stats.primary_cooldown), "actual reapproach retains native warning time for the second release"): return false
	var previous_reactions: int = finite_reactions.size()
	if not await _finite_primary(left, aim, "second ordinary release consumes the final real anchor", true): return false
	if not paused and not await _pause_pair("complete second release boundary"): return false
	var released: Dictionary = field.state()
	if not _require(released.generation == 2 and released.remaining_clusters == 0 and released.spent_ids == ["cluster-right", "cluster-left"] and float(released.activation_s) >= float(before.deadline_s) and float(released.deadline_s) == float(released.activation_s) + 3.0 and finite_activations.size() == 2 and (level.get("spore_consumer") as CinderSporeRepulsion).placement_accepted() and hero.hp == initial_hp and guard_source.hp == 24.0 and hit_events.is_empty(), "same actual field consumes its second finite supply after expiry without hurting either living actor"): return false
	finite_observations.append({"kind": "second_release", "field": released, "second_episode_published": finite_reactions.size() > previous_reactions, "source": guard_source.get_spore_response_state()})
	# No new environmental episode is required if the actual guard is outside
	# the expanded domain. A surviving live native lease still needs real lead.
	var response: Dictionary = hero.get_threat_response_state()
	var escape_cost: float = maxf(float(response.primary_cooldown_left_s), float(response.commitment_remaining_s)) + dash_cycle + input_pad
	if not _warning_lead(escape_cost, "second release retains a real RIGHT escape before any surviving native danger", true): return false
	if not await _finite_barrier("second-release") or not await _gui_resume_pair() or not await _swipe(Vector3.RIGHT, "real full RIGHT escape after second release"): return false
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
