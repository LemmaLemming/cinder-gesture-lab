extends "res://tests/acts/act1/a1_l2_route_campaign.gd"
## Observation only. Inherits the same real campaign setup, recognizer route,
## assertions and shutdown; no new admission, cancellation or controller call.
## Phase callbacks run after Main's callback, which may already have removed a
## cancelled source's framing witness. Keep that distinction explicit in logs.
var diagnostic_previous: Dictionary = {}
var diagnostic_cancellations: Dictionary = {}
var diagnostic_admissions: Dictionary = {}
var diagnostic_finishing: bool = false


func _extra_completion_checks() -> bool:
	print("L2 READONLY BEFORE EXTRA ", JSON.stringify(_end_observation()))
	var accepted: bool = await super._extra_completion_checks()
	var after: Dictionary = _end_observation()
	after["extra_returned"] = accepted
	print("L2 READONLY AFTER EXTRA ", JSON.stringify(after))
	return accepted


func _finish() -> void:
	if finished or diagnostic_finishing: return
	diagnostic_finishing = true
	print("L2 READONLY BEFORE FINISH ", JSON.stringify(_end_observation()))
	await super._finish()
	print("L2 READONLY AFTER FINISH ", JSON.stringify(_end_observation()))


func _end_observation() -> Dictionary:
	# At most60 swipes and bounded route hit/observation histories are retained.
	# Read exact public state; never manufacture a missing observer record.
	var result: Dictionary = {"checks": checks, "failures": failures, "finished": finished, "aborted": aborted, "paused": paused, "actual_events": events.duplicate(), "expected_progress": Progress.duplicate() if _route_has_contact() else Progress.slice(0, 5), "route_has_contact": _route_has_contact(), "expected_contact": "open-grotto" if _route_has_contact() else "", "initial_hp": initial_hp, "swipes": swipes, "primaries": primaries, "hit_count": hits.size(), "hit_events": hits.duplicate(true), "subscribed_record_count": world_records.size(), "observation_count": observations.size(), "actual_observations": str(observations), "boundary_ids": boundary_ids.duplicate(), "saved_boundary_count": boundary_evidence.size(), "pending_boundary_count": pending_boundaries.size()}
	var counts: Dictionary = {"dash": 0, "primary": 0, "other": 0}
	var record_ids: Array[Dictionary] = []
	for record: Dictionary in world_records:
		var kind: String = String(record.get("kind", ""))
		counts[kind if kind in ["dash", "primary"] else "other"] += 1
		record_ids.append({"kind": kind, "sequence": record.get("sequence", -1), "hits": record.get("hits", -1)})
	result["subscribed_counts"] = counts
	result["subscribed_record_ids"] = record_ids
	result["events_match_expected"] = events == (Progress if _route_has_contact() else Progress.slice(0, 5))
	result["hits_empty"] = hits.is_empty()
	result["record_mapping_matches"] = counts.dash == swipes and counts.primary == primaries and observations.size() == swipes + primaries
	if is_instance_valid(hero):
		result["fixture_player_id"] = hero.get_instance_id()
		result["actual_hp"] = hero.hp
		result["hp_matches_initial"] = hero.hp == initial_hp
		result["player_position"] = Codec.vector3(hero.global_position)
		result["public_player_record_count"] = hero.get_world_action_records().size()
		result["public_player_record_ids"] = str(hero.get_world_action_records())
	if is_instance_valid(level):
		result["fixture_level_id"] = level.get_instance_id()
		result["level_scene_path"] = level.scene_file_path
		result["level_player_id"] = level.hero.get_instance_id() if is_instance_valid(level.hero) else 0
		result["actual_beat_index"] = level.get("beat_index")
		if paused and not finished:
			var snapshot: Dictionary = level.snapshot_state()
			result["actual_progress"] = snapshot.get("progress", {})
			result["native_snapshot_nonempty"] = not snapshot.is_empty()
			result["native_contact_matches"] = snapshot.get("progress", {}).get("contact_exit_id", "MISSING") == ("open-grotto" if _route_has_contact() else "")
			result["level_snapshot_error"] = level.last_snapshot_error
	if is_instance_valid(game):
		result["game_id"] = game.get_instance_id()
		result["shell_player_id"] = _shell().player.get_instance_id() if is_instance_valid(_shell().player) else 0
		result["shell_level_id"] = _shell().active_level.get_instance_id() if is_instance_valid(_shell().active_level) else 0
		result["actual_menu_page"] = _shell().menu.page_name() if is_instance_valid(_shell().menu) else ""
		result["actual_menu_open"] = _shell().menu.is_open() if is_instance_valid(_shell().menu) else false
		result["campaign_error"] = _shell().campaign_error
		var state: Dictionary = _shell().attempts.state()
		result["completed_main"] = state.get("completed_main", [])
		if state.get("story") is Dictionary:
			result["saved_progress"] = state.story.snapshot.level.progress
			result["saved_hp"] = state.story.snapshot.player.resources.hp
	return result


func _notice_phase(id: String, state: Dictionary) -> void:
	super._notice_phase(id, state)
	if finished or not is_instance_valid(level) or not is_instance_valid(hero) or not is_instance_valid(camera): return
	var previous: Dictionary = diagnostic_previous.get(id, {})
	var reason: String = String(state.get("last_cancel_reason", ""))
	var key: String = "%s/%d" % [id, int(state.get("cycle", 0))]
	var current: Dictionary = {"state": _state_wire(state), "frame": _frame_observation()}
	if not reason.is_empty() and state.get("status") != "running" and int(state.get("cycle", 0)) > 0 and not diagnostic_cancellations.has(key):
		diagnostic_cancellations[key] = true
		print("L2 READONLY FIRST CANCEL ", JSON.stringify({"source": id, "cycle": state.cycle, "reason": reason, "clock_s": (level.get("scheduler") as CinderThreatScheduler).get_clock(), "hero_position": Codec.vector3(hero.global_position), "hp": hero.hp, "paused": paused, "current_after_main_callback": current, "previous_phase_observation": previous, "observed_admission_ids": diagnostic_admissions.keys()}))
	diagnostic_previous[id] = current


func _notice_native_admission(id: String, answer: Dictionary) -> void:
	super._notice_native_admission(id, answer)
	var reservation_id: String = String(answer.get("reservation_id", ""))
	if finished or reservation_id.is_empty() or not answer.get("accepted", false) or diagnostic_admissions.has(reservation_id): return
	var retained: Node3D = (level.get("sources") as Dictionary).get(id, (level.get("circles") as Dictionary).get(id)) as Node3D
	if not is_instance_valid(retained): return
	var state: Dictionary = retained.call("state")
	var record: Dictionary = answer.reservation
	var observed: Dictionary = {"source": id, "cycle": state.cycle, "reservation_id": reservation_id, "clock_s": (level.get("scheduler") as CinderThreatScheduler).get_clock(), "state": _state_wire(state), "start_s": record.start_s, "lock_from_s": record.lock_from_s, "active_from_s": record.active_from_s, "active_until_s": record.active_until_s, "recovery_until_s": record.recovery_until_s, "landing": Codec.vector3(answer.proof.landing), "attack_position": Codec.vector3(answer.proof.attack_position), "primary_time_s": answer.proof.primary_time_s, "response_complete_s": answer.proof.response_complete_s, "frame": _frame_observation()}
	diagnostic_admissions[reservation_id] = observed
	print("L2 READONLY NATIVE ADMISSION ", JSON.stringify(observed))


func _state_wire(state: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for field: String in ["source_id", "mechanism_id", "status", "phase", "cycle", "reservation_id", "hp", "dead", "dormant", "last_cancel_reason", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if state.has(field): result[field] = state[field]
	for field: String in ["source_position", "opening_position"]:
		if state.get(field) is Vector3: result[field] = Codec.vector3(state[field])
	if state.get("geometry") is Dictionary:
		var geometry: Dictionary = state.geometry
		result["geometry"] = {"kind": geometry.get("kind", ""), "radius": geometry.get("radius", 0.0)}
		for field: String in ["origin", "from", "to"]:
			if geometry.get(field) is Vector3: result.geometry[field] = Codec.vector3(geometry[field])
	if state.get("adapter") is Dictionary:
		var adapter: Dictionary = state.adapter
		result["adapter_finished"] = adapter.get("finished", false)
		for field: String in ["planned_endpoint", "current_position", "current_velocity"]:
			if adapter.get(field) is Vector3: result["adapter_" + field] = Codec.vector3(adapter[field])
	return result


func _frame_observation() -> Dictionary:
	# These are the public pure framing views and actual native projection. No
	# private Main witness/cache/guard is read or replaced. Current containment
	# after cancellation can pass because the failed requirement was removed.
	var points: Array = level.camera_framing_points()
	var plan: Dictionary = game.call("camera_framing_plan", points, hero.global_position + Vector3(0, 0.65, 0))
	var safe: Rect2 = (game.get("hud") as Node).call("combat_safe_rect")
	var viewport_size := Vector2(camera.get_viewport().size)
	var height: float = camera.size * viewport_size.y / viewport_size.x
	var inset := Vector2(0.02 / camera.size, 0.02 / height)
	var protected := Rect2(safe.position + inset, safe.size - inset * 2.0)
	var projected: Array[Dictionary] = []
	var world_points: Array = []
	for index: int in range(points.size()):
		var point: Vector3 = points[index]
		world_points.append(Codec.vector3(point))
		var normalized: Vector2 = camera.unproject_position(point) / viewport_size
		if not protected.has_point(normalized):
			projected.append({"index": index, "world": Codec.vector3(point), "normalized_native_projection": [normalized.x, normalized.y]})
	return {"camera_position": Codec.vector3(camera.global_position), "camera_viewport_size": [viewport_size.x, viewport_size.y], "required_point_count": points.size(), "required_world_points": world_points, "public_level_points_error": level.last_camera_framing_error, "public_current_containment_error": String(game.call("camera_framing_error", points)), "public_prospective_plan_accepted": plan.get("accepted", false), "public_prospective_plan_reason": plan.get("reason", ""), "public_camera_state": str(game.call("get_camera_framing_state")), "protected_normalized_min": [protected.position.x, protected.position.y], "protected_normalized_max": [protected.end.x, protected.end.y], "outside_points_native_projection_approximate": projected}
