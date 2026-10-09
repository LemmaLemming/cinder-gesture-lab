extends "res://tests/acts/act1/a1_l3_normal_opening.gd"
## Owner-reviewed full-route fixture; execution evidence is recorded separately.
## One genuine neutral/Standard normal-route world: all five rooms, ordinary
## first-tap primaries, actual nineteen defeats, four checkpoints, one completion
## and actual contact exit. No actor/Player/body/clock/phase/activation/ammo seed.
## No positive synthetic progress request, pair restore, pickup or blast input.
## Full native aggregate/candidate/save support remains explicitly DENIED.

const FullBodySweep = preload("res://scripts/combat/body_sweep.gd")
const FullGapGeometry = preload("res://scripts/combat/threat_geometry.gd")
const FullLayout = preload("res://scripts/acts/act1/mushroom_caverns_layout.gd")
const FullRoomNames: Array[String] = ["umbrella", "breathing", "crossed", "lone-guard", "court"]
const FullBeats: Array[String] = ["umbrella-grove", "breathing-chamber", "crossed-grotto", "spear-pocket", "court-approach"]
const FullWallWatchdogMs: int = 900000 # Fifteen minutes for FIVE rooms; not a native timing change.
const FullRoundLimit: int = 32 # Per-room finite number of real primary opportunities.

var full_spec: Dictionary = {}
var full_world_ids: Dictionary = {}
var full_defeats: Dictionary = {}
var full_defeat_receipts: Array[Dictionary] = []
var full_room_receipts: Array[Dictionary] = []
var full_checkpoint_guards: Array[Dictionary] = []
var full_completion_receipts: Array[Dictionary] = []
var full_contact_receipts: Array[Dictionary] = []
var full_field_refs: Dictionary = {}
var full_consumer_refs: Dictionary = {}
var full_room_cycle_seen: Dictionary = {}
var full_phase_barriers: Array[Dictionary] = []
var full_pause_target: Dictionary = {}
var full_pause_requested: bool = false
var full_teardown: bool = false
var full_evidence_history: Array[Dictionary] = []
var full_diagnostics: Array[Dictionary] = []
var full_response_timing_receipts: Array[Dictionary] = []
# Optional renderer coverage only. Every use below is gated by portrait.
var full_floor_court_attempted: bool = false
var full_floor_field_attempted: bool = false
var full_floor_capture_request: Dictionary = {}
var full_floor_coverage: Dictionary = {"court": {"status": "not_observed", "reason": "no_closed_court_C32_primary_observed"}, "field": {"status": "not_observed", "reason": "no_current_room_natural_increment_observed"}}


func _run() -> void:
	portrait = "--portrait" in OS.get_cmdline_user_args()
	root.size = PortraitSize
	if portrait:
		if not _require(DisplayServer.get_name() != "headless", "full normal-route portrait uses the actual renderer"):
			await _finish(); return
		capture_dir = "res://.cinder/captures/l3-normal-full-route-%d" % Time.get_ticks_usec()
		if not _require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir)) == OK, "full route capture directory is writable"):
			await _finish(); return
		print("SCRIPTED NORMAL FULL L3 native_focus_observed=", DisplayServer.window_is_focused(), "; default focus guards; one initial public resume")
	if not await _open_world(NormalOpeningPath, "normal-five-room-route", FullLayout.SPAWN):
		await _finish(); return
	full_spec = level.call("normal_route_spec")
	full_world_ids = {"game": game.get_instance_id(), "level": level.get_instance_id(), "player": hero.get_instance_id(), "scheduler": scheduler.get_instance_id()}
	if not _require(full_spec.sources == NormalIds and full_spec.room_sources.size() == 5 and full_spec.room_fields.size() == 5 and full_spec.thresholds == FullLayout.BEAT_THRESHOLDS and full_spec.checkpoint_ids == FullBeats.slice(0, 4) and full_spec.completion_id == "mushroom-caverns-clear" and full_spec.exit_id == "open-court" and initial_hp == 100.0 and hero.equipment.snapshot() == {"jacket": "CLOTH-J0", "pants": "CLOTH-P0", "shoes": "CLOTH-S0", "weapon": "WEAPON-01"}, "fresh normal route has the authored nineteen, five thresholds and actual neutral starter without resource staging"):
		await _finish(); return
	for id: String in NormalIds:
		full_defeats[id] = 0
		sources[id].connect("defeated", _full_notice_defeat)
	level.completion_requested.connect(_full_notice_completion)
	level.contact_exit_requested.connect(_full_notice_contact)
	process_frame.connect(_sample_opening)
	process_frame.connect(_sample_crowd)
	physics_frame.connect(_full_phase_observer)
	if not await _full_quiet_capture("actual-pristine-nineteen"):
		await _finish(); return
	for room: int in range(5):
		if not await _full_enter_room(room) or not await _full_clear_room(room) or not await _full_room_boundary(room):
			_full_diagnostic("room %d failed" % room); await _finish(); return
	if not _full_final_progress() or not await _full_physical_exit() or not _full_action_history():
		_full_diagnostic("final progress/contact/history"); await _finish(); return
	if not await _unsupported_save_barrier():
		await _finish(); return
	if not _require(game.get_instance_id() == full_world_ids.game and level.get_instance_id() == full_world_ids.level and hero.get_instance_id() == full_world_ids.player and scheduler.get_instance_id() == full_world_ids.scheduler, "all five rooms and actual contact used one original native world/Hero/Scheduler"):
		await _finish(); return
	_full_diagnostic("actual five-room ordinary-only contact completed; full save still denied")
	_full_disconnect_observers()
	if not await _full_pause("whole-route cleanup"):
		await _finish(); return
	var effects: PixelEffects = game.get("fx") as PixelEffects
	if is_instance_valid(effects): effects.clear()
	# Native AudioServer drains retired paused voices before freeing the world.
	# This is cleanup wall time; it advances no gameplay clock or cooldown.
	var drain_until: int = Time.get_ticks_msec() + 500
	while Time.get_ticks_msec() < drain_until and not finishing: await process_frame
	if not await _close_world(false):
		await _finish(); return
	for raw: Variant in full_field_refs.values():
		if not _require(not is_instance_valid(raw), "normal cleanup frees every actually installed native field"):
			await _finish(); return
	for raw: Variant in full_consumer_refs.values():
		if not _require(not is_instance_valid(raw), "normal cleanup frees every actually installed native consumer"):
			await _finish(); return
	await _finish()


func _full_ids(room: int = -1) -> Array[String]:
	var result: Array[String] = []
	if room < 0:
		if not is_instance_valid(level): return result
		room = int(level.call("route_state").beat_index)
	if room < 5:
		for id: String in full_spec.room_sources[room]: result.append(id)
	return result


func _full_allowed(room: int) -> Array[String]:
	var result: Array[String] = []
	for index: int in range(room + 1): result.append_array(_full_ids(index))
	return result


func _future_pristine(allowed: Array, label: String) -> bool:
	# This override also runs from the inherited exact fresh-world constructor.
	# Role truth comes from each actual immutable native configuration, including
	# future court-guard; a source's string name never selects its behavior here.
	for id: String in NormalIds:
		if id in allowed: continue
		var actor: CharacterBody3D = sources[id]
		var native: Dictionary = actor.call("get_spore_native_bindings")
		var entity: String = String(native.configuration.entity_id)
		var guard: bool = entity == "C32"
		var state: Dictionary = actor.call("pure_presentation_state")
		var response: Dictionary = actor.call("get_spore_response_state")
		var control: Dictionary = scheduler.source_control_state(actor)
		var body: CollisionShape3D = opening_references[id].body
		if not _require(entity in ["C31", "C32"] and state.source_id == id and state.entity_id == entity and state.role_id == native.configuration.role_id and state.hp == (24.0 if guard else 16.0) and not state.dead and state.dormant and state.status == "dormant" and state.phase == "clear" and state.cycle == 0 and state.reservation_id == "" and state.geometry.is_empty() and state.velocity == Vector3.ZERO and not state.approach_driving and state.approach_enabled == (not guard) and state.hurt_left_s == 0.0 and state.last_cancel_reason == "" and not response.is_empty() and not response.alive and response.consumer_id == "" and response.episode_id == "" and response.phase == "none" and control.reservations.is_empty() and control.cooldown == null and actor.get_parent() == level and not actor.is_in_group("enemies") and not actor.visible and body.disabled and actor.collision_layer == 0 and actor.collision_mask == 0 and opening_activation_counts[id] == 0, label + " preserves actual native future role/body/HP/history: " + id):
			return false
	return true


func _full_enter_room(room: int) -> bool:
	var route: Dictionary = level.call("route_state")
	if not _require(int(route.beat_index) == room and route.room_stage == "approach" and route.completed_beats == FullBeats.slice(0, room) and not route.encounter_started, "only actual preceding required defeats entitle room %d" % room): return false
	var advances: int = 0
	while not aborted and int(level.call("route_state").beat_index) == room and level.call("route_state").room_stage == "approach" and advances < 16:
		if not await _full_route_step(Vector3.FORWARD, "whole forward native entrance %s/%d" % [FullRoomNames[room], advances + 1]): return false
		advances += 1
	if not await _wait(func() -> bool:
		var actual: Dictionary = level.call("route_state")
		return actual.beat_index == room and actual.room_stage == "active" and actual.encounter_started and _full_room_framing_ready(), "actual room %d begins at its native threshold with complete current framing" % room, 2.0): return false
	_sample_opening()
	var ids: Array[String] = _full_ids(room)
	var control: Dictionary = scheduler.source_control_state(sources[ids[0]])
	if not _require(level.call("current_source_ids") == ids and scheduler.encounter_profile().get("id") == "standard" and control.encounter_id == "a1_l3_" + FullRoomNames[room] and control.world_revision == 1 and opening_epochs == _full_expected_epochs(room), "actual current room has its own observed Standard native epoch and exact entitled cast"):
		return false
	for id: String in ids:
		var state: Dictionary = sources[id].call("pure_presentation_state")
		var native: Dictionary = sources[id].call("get_spore_native_bindings")
		var entity: String = String(native.configuration.entity_id)
		if not _require(entity in ["C31", "C32"] and state.entity_id == entity and state.role_id == native.configuration.role_id and opening_activation_counts[id] == 1 and not state.dormant and not state.dead and float(state.hp) == (24.0 if entity == "C32" else 16.0) and full_defeats[id] == 0 and sources[id].is_in_group("enemies"), id + " activates once under its actual native role at full original HP"):
			return false
	full_room_cycle_seen[room] = false
	if not _retained_truth("native room entrance") or not _future_pristine(_full_allowed(room), "actual room future pristine") or not _full_environment(room, true) or not _framing("complete actual room source/art/field union"):
		return false
	return await _full_quiet_capture("%s-actual-whole-cast-entrance" % FullRoomNames[room])


func _full_room_framing_ready() -> bool:
	# Same original entrance wait: actual activation alone is not a rendered view.
	# Observe CURRENT complete containment; no proposed focus grants readiness.
	if not is_instance_valid(level) or not is_instance_valid(game): return false
	var points: Array = level.camera_framing_points()
	return not points.is_empty() and points.size() <= 224 and level.last_camera_framing_error.is_empty() and String(game.call("camera_framing_error", points)).is_empty()


func _full_expected_epochs(room: int) -> Array[String]:
	var result: Array[String] = []
	for index: int in range(room + 1): result.append("a1_l3_" + FullRoomNames[index])
	return result


func _full_clear_room(room: int) -> bool:
	var rounds: int = 0
	while not _full_room_dead(room) and rounds < FullRoundLimit and not aborted:
		if not await _full_opportunity(room): return false
		var id: String = _fresh_warning()
		if not id.is_empty():
			if not await _fight_cycle(id, false): return false
			full_room_cycle_seen[room] = true
		else:
			id = _reachable_source()
			if not _require(full_room_cycle_seen.get(room, false) and not id.is_empty(), "reachable multi-hit opening follows an actual complete native cycle in this room"): return false
			if not await _primary(sources[id], id + " actual ordinary room opening"): return false
		rounds += 1
	if not _require(_full_room_dead(room) and full_room_cycle_seen.get(room, false), "room %d genuinely clears its full required cast after a complete native cycle" % room): return false
	return await _wait(func() -> bool:
		var route: Dictionary = level.call("route_state")
		return route.beat_index == room + 1 and route.completed_beats == FullBeats.slice(0, room + 1) and route.room_stage == ("complete" if room == 4 else "approach"), "native parent publishes real room %d boundary" % room, 2.0)


func _full_room_dead(room: int) -> bool:
	for id: String in _full_ids(room):
		if not is_instance_valid(sources.get(id)) or not sources[id].get("dead") or float(sources[id].get("hp")) != 0.0: return false
	return true


func _full_opportunity(room: int) -> bool:
	# An isolated stationary source may be farther than native4.5m admission.
	# Walk there only by full actual recognizer dashes before any retained lease;
	# native preview/admission remains the parent's authority.
	var remaining_wait_s: float = 12.0 # Original passive window, shared across lease waits.
	for step: int in range(8):
		if _fresh_warning() != "" or (full_room_cycle_seen.get(room, false) and _reachable_source() != ""): return true
		var nearest: String = ""
		var distance: float = INF
		for id: String in _full_ids(room):
			var state: Dictionary = sources[id].call("pure_presentation_state")
			if state.dead: continue
			var actual: float = _planar_distance(sources[id].global_position, hero.global_position)
			if actual < distance: distance = actual; nearest = id
		if not scheduler.reservations().is_empty():
			# A different real lease can still be in flight after the chosen source
			# dies. Observe its original expiry; then revisit actual input choice.
			# Never spend another12s per iteration or wait passively at the3m stop.
			_full_diagnostic("retained actual native lease before ordinary opportunity")
			var wait_start_s: float = hero.get_world_action_clock()
			if not await _wait(func() -> bool: return _fresh_warning() != "" or (full_room_cycle_seen.get(room, false) and (_reachable_source() != "" or _full_gap_ready(room))), "actual native lease reaches a fresh response or genuine stopped ordinary approach", remaining_wait_s): return false
			remaining_wait_s = maxf(0.0, remaining_wait_s - (hero.get_world_action_clock() - wait_start_s))
			continue
		if distance <= 4.4:
			if not full_room_cycle_seen.get(room, false): break
			# Finish the existing Hero readiness await BEFORE observing source eligibility.
			# It may let other living sources approach or a genuine lease begin. This is
			# the original gap-step readiness window, moved before the stopped predicate.
			if not await _ready_input(nearest + " real full ordinary-gap step readiness"): return false
			if _fresh_warning() != "" or _reachable_source() != "": return true
			if not _full_gap_ready(room):
				# An empty Scheduler alone does not stop approach-owned native bodies.
				# Use the SAME original passive budget; never grant a fresh12s window.
				var wait_start_s: float = hero.get_world_action_clock()
				if not await _wait(func() -> bool: return _fresh_warning() != "" or (full_room_cycle_seen.get(room, false) and (_reachable_source() != "" or _full_gap_ready(room))), "actual current-room bodies reach a fresh response or genuine stopped ordinary approach", remaining_wait_s): return false
				remaining_wait_s = maxf(0.0, remaining_wait_s - (hero.get_world_action_clock() - wait_start_s))
				continue # Reenter with real current bodies and reselect after every wait.
			# Readiness can change positions. Reselect the living target from actual
			# stopped bodies now, with no further await before the strict gap query.
			nearest = ""
			distance = INF
			for id: String in _full_ids(room):
				var state: Dictionary = sources[id].call("pure_presentation_state")
				if state.dead: continue
				var actual: float = _planar_distance(sources[id].global_position, hero.global_position)
				if actual < distance: distance = actual; nearest = id
			if not _require(not nearest.is_empty(), "actual stopped room retains a living ordinary approach target"): return false
			# Native admission distance is not ordinary-primary reach. After a genuine
			# cycle, a C31 can settle at its authored3m approach stop outside2m reach.
			if not await _full_gap_step(room, nearest): return false
			continue
		if not _require(not nearest.is_empty(), "actual room retains a living approach target"): return false
		var direction: Vector3 = sources[nearest].global_position - hero.global_position
		direction.y = 0.0
		if not await _full_route_step(direction.normalized(), "whole actual approach towards " + nearest): return false
	return await _wait(func() -> bool: return _fresh_warning() != "" or (full_room_cycle_seen.get(room, false) and _reachable_source() != ""), "room-local actual native admission/ordinary opportunity", remaining_wait_s)


func _full_gap_ready(room: int) -> bool:
	if not scheduler.reservations().is_empty(): return false
	for id: String in _full_ids(room):
		var actual: Variant = sources.get(id)
		if not is_instance_valid(actual) or not actual is CharacterBody3D: return false
		var state: Dictionary = actual.call("pure_presentation_state")
		if state.dead: continue
		var control: Dictionary = scheduler.source_control_state(actual)
		var response: Dictionary = actual.call("get_spore_response_state")
		if control.is_empty() or control.get("source_instance_id") != actual.get_instance_id() or control.get("outside_transaction") != true or not control.reservations.is_empty(): return false
		if response.is_empty() or not response.alive or not response.grounded or response.get("outside_transaction") != true or response.phase != "none" or response.velocity != Vector3.ZERO: return false
		if state.dormant or state.status != "idle" or not state.reservation_id.is_empty() or state.velocity != Vector3.ZERO or state.approach_driving or float(state.hurt_left_s) > 0.0: return false
	return true


func _full_gap_step(room: int, id: String) -> bool:
	# The sole caller completed real Hero readiness before observing stopped
	# source eligibility. Do not yield between that barrier and the strict query.
	if _fresh_warning() != "" or _reachable_source() != "": return true
	if not _require(_full_gap_ready(room), "ordinary-gap query retains genuine stopped unleased current-room bodies"): return false
	var actor: CharacterBody3D = sources[id]
	var length: float = float(hero.equipment.resolved_stats().dash_distance)
	var reach: float = float(hero.equipment.resolved_stats().primary_range) - 0.08
	if not _require(_planar_distance(actor.global_position, hero.global_position) > reach, id + " still needs a real full step into unchanged ordinary reach"): return false
	var hero_body: Dictionary = FullBodySweep.source_description(hero)
	if not _require(not hero_body.has("error") and hero_body.collision.shape is CapsuleShape3D, "ordinary-gap query uses the actual retained shared Hero capsule"): return false
	var radius: float = (hero_body.collision.shape as CapsuleShape3D).radius
	var floors: Array = level.call("scheduler_bindings").floors.values()
	var candidates: Array[Dictionary] = []
	# Finite canonical cardinal/diagonal inputs. This is fixture input choice,
	# not an attack/path solver or a changed movement/controller definition.
	for heading: Vector3 in [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT, Vector3(1, 0, -1), Vector3(1, 0, 1), Vector3(-1, 0, -1), Vector3(-1, 0, 1)]:
		var direction: Vector3 = heading.normalized()
		var motion: Vector3 = direction * length
		var finish: Vector3 = hero.global_position + motion
		var predicted_gap: float = _planar_distance(actor.global_position, finish)
		var measured: Dictionary = {}
		var clear: bool = false
		if predicted_gap <= reach:
			measured = FullBodySweep.sweep(hero, hero.global_transform, motion, floors)
			clear = not measured.has("error") and not measured.get("collided", true) and measured.get("end") is Vector3 and measured.end.distance_to(finish) <= FullBodySweep.position_rounding_bound(hero.global_position, finish)
			for other_id: String in _full_ids(room):
				var other: CharacterBody3D = sources[other_id]
				if other.get("dead"): continue
				var body: Dictionary = FullBodySweep.source_description(other)
				if body.has("error") or not body.collision.shape is CapsuleShape3D: clear = false; break
				var shape: Dictionary = {"kind": "circle", "origin": other.global_position, "radius": (body.collision.shape as CapsuleShape3D).radius + 0.12}
				if FullGapGeometry.segment_hits(shape, hero.global_position, finish, radius): clear = false; break
		# Empty measurement means this direction was outside ordinary reach; no
		# scenery/native query or pass is invented for that excluded candidate.
		candidates.append({"direction": direction, "finish": finish, "clear": clear, "measured": measured, "predicted_primary_gap": predicted_gap})
	_full_diagnostic("real unleased ordinary-gap candidates " + id + " " + str(_portable(candidates)))
	for candidate: Dictionary in candidates:
		if not candidate.clear or float(candidate.predicted_primary_gap) > reach: continue
		# Static sweep/spacing supplies no threat/fairness or future-motion grant.
		# Parent still owns fresh admission; actual native action/HP/phase/body and
		# whole camera observers retain authority throughout the real recognizer.
		if not await _full_route_step(candidate.direction, id + " measured full oblique ordinary approach"): return false
		return _framing(id + " actual ordinary-gap stopped landing whole native union")
	return _require(false, id + " has a clear whole native body path to an ordinary opening")


func _full_route_step(direction: Vector3, label: String) -> bool:
	if not await _ready_input(label + " pure scenery query readiness"): return false
	var motion: Vector3 = Vector3(direction.x, 0, direction.z).normalized() * float(hero.equipment.resolved_stats().dash_distance)
	var floor_bindings: Array = level.call("scheduler_bindings").floors.values()
	var measured: Dictionary = FullBodySweep.sweep(hero, hero.global_transform, motion, floor_bindings)
	if not _require(not measured.has("error") and not measured.get("collided", true) and measured.get("end") is Vector3 and measured.end.distance_to(hero.global_position + motion) <= FullBodySweep.position_rounding_bound(hero.global_position, hero.global_position + motion), label + " whole actual native scenery sweep has original support and no shortened body path"):
		return false
	# This measured scenery path grants no combat permission. The recognizer and
	# actual body record below must still execute one full dash and preserve HP.
	return await _swipe(direction, label)


func _fresh_warning() -> String:
	var selected: String = ""
	var nearest: float = INF
	for id: String in _full_ids():
		if not _running_warning(id): continue
		var state: Dictionary = sources[id].call("pure_presentation_state")
		var answer: Dictionary = admissions.get(String(state.reservation_id), {})
		var path: Array = answer.get("proof", {}).get("path", [])
		if path.is_empty() or not path[0].get("from") is Vector3 or _planar_distance(path[0]["from"], hero.global_position) > PositionTolerance: continue
		var escape_start: float = -1.0
		for segment: Dictionary in path:
			if segment.get("kind") == "escape_dash": escape_start = float(segment.start_s)
		if escape_start < scheduler.get_clock(): continue
		var distance: float = _planar_distance(sources[id].global_position, hero.global_position)
		if distance < nearest: nearest = distance; selected = id
	return selected


func _reachable_source() -> String:
	var selected: String = ""
	var nearest: float = float(hero.equipment.resolved_stats().primary_range) - 0.08
	for id: String in _full_ids():
		var state: Dictionary = sources[id].call("pure_presentation_state")
		var distance: float = _planar_distance(sources[id].global_position, hero.global_position)
		if not state.dead and not state.dormant and state.phase != "active" and distance <= nearest:
			nearest = distance; selected = id
	return selected


func _fight_cycle(id: String, _unused_pair_pause: bool) -> bool:
	var actor: CharacterBody3D = sources[id]
	var state: Dictionary = actor.call("pure_presentation_state")
	var room: int = int(level.call("route_state").beat_index)
	var lease: String = String(state.reservation_id)
	var cycle: int = int(state.cycle)
	var answer: Dictionary = admissions.get(lease, {})
	var native: Dictionary = actor.call("get_spore_native_bindings")
	var is_guard: bool = native.configuration.entity_id == "C32"
	if not _require(id in _full_ids(room) and state.phase == "warning" and state.role_id == native.configuration.role_id and answer.get("accepted", false) and answer.get("armed", false) and answer.reservation.source_instance_id == actor.get_instance_id() and not answer.proof.uses_blast and not answer.proof.uses_invulnerability, id + " actual native current-room role/source owns this unchanged ordinary accepted response"):
		return false
	var proof: Dictionary = answer.proof.duplicate(true)
	var reservation: Dictionary = answer.reservation.duplicate(true)
	var length: float = (reservation.geometry["to"] as Vector3).distance_to(reservation.geometry["from"])
	if not _require(float(proof.primary_time_s) >= float(reservation.active_until_s) and float(proof.response_complete_s) < float(reservation.recovery_until_s) and reservation.geometry.kind == "lane" and absf(length - (2.0 if is_guard else 1.0)) <= PositionTolerance and absf(float(reservation.geometry.radius) - 0.38) <= CrowdEpsilon, id + " retains exact native C31/C32 lane and original ordinary timing proof"):
		return false
	# First cycle per room captures the still-living whole room at every actual
	# warning/active/recovery barrier; Crossed includes all eight plus both fields.
	var detailed: bool = not bool(full_room_cycle_seen.get(room, false))
	if detailed and not await _full_phase_barrier(id, lease, cycle, "warning"): return false
	var source_start: Vector3 = actor.global_position
	var escape: Vector3 = proof.landing - hero.global_position
	escape.y = 0.0
	if not _require(absf(escape.length() - float(hero.equipment.resolved_stats().dash_distance)) <= PositionTolerance, id + " native safe landing remains one full legal dash"): return false
	if not await _swipe(escape, id + " full native safe escape"): return false
	if detailed:
		if not await _full_phase_barrier(id, lease, cycle, "active") or not await _full_phase_barrier(id, lease, cycle, "recovery"): return false
	else:
		for phase: String in ["lock", "active", "recovery"]:
			var key: String = _phase_key(id, cycle, lease, phase)
			if not await _wait(func() -> bool: return phase_observations.has(key), id + " actual retained native " + phase): return false
	state = actor.call("pure_presentation_state")
	if not _require(state.reservation_id == lease and state.cycle == cycle and state.status == "running", id + " completed native observation retains the same source cycle"): return false
	if is_guard:
		if not _require(_planar_distance(actor.global_position, source_start) <= PositionTolerance and actor.velocity.is_zero_approx(), id + " actual C32 role retains its stationary physical lane source"): return false
	else:
		if not _require(_planar_distance(actor.global_position, source_start) > .9 and actor.global_position.distance_to(reservation.opening_position) <= PositionTolerance and state.adapter.finished, id + " actual C31 lunge reaches its genuine finished ordinary opening"): return false
	var timing: Dictionary = {"source_id": id, "room": room, "lease": lease, "cycle": cycle, "original_proof": proof.duplicate(true), "return_input_begin_s": null, "return_publication": {}, "return_ready_s": null, "primary_publication": {}}
	full_response_timing_receipts.append(timing)
	var returning: Vector3 = proof.attack_position - hero.global_position
	returning.y = 0.0
	var positioning: Array[Dictionary] = []
	for segment: Dictionary in proof.path:
		if segment.get("kind") == "positioning_dash": positioning.append(segment)
	if returning.length() > PositionTolerance:
		if not _require(absf(returning.length() - float(hero.equipment.resolved_stats().dash_distance)) <= PositionTolerance, id + " actual native return remains one full ordinary dash"): return false
		if not _require(positioning.size() == 1, id + " original accepted path owns exactly one actual full positioning segment"): return false
		var planned: Dictionary = positioning[0]
		if not _require(Codec.keys_error(planned, ["from", "to", "start_s", "end_s", "kind"]).is_empty() and planned["from"] == proof.landing and planned["to"] == proof.attack_position and planned.start_s is float and planned.end_s is float and is_finite(planned.start_s) and is_finite(planned.end_s) and planned.start_s >= float(reservation.active_until_s) + CinderThreatScheduler.TIME_MARGIN and planned.end_s == float(planned.start_s) + float(hero.equipment.resolved_stats().dash_duration) and planned.end_s <= float(proof.primary_time_s), id + " retains the genuine native positioning endpoints/start/end without a second recognition charge"): return false
		# Native _prove already reserves recognition for the first escape. Its later
		# positioning segment starts at its own retained start_s, not primary_time_s.
		# The real recognizer/all-zero readiness remains unchanged and is measured;
		# this fixture does not claim it exactly reproduces the certified timed path.
		if not await _wait(func() -> bool: return scheduler.get_clock() >= float(planned.start_s), id + " actual retained positioning start"): return false
		timing["return_input_begin_s"] = scheduler.get_clock()
		var return_observer: Callable = func(record: Dictionary) -> void:
			if record.kind == "dash": timing["return_publication"] = {"scheduler_clock_s": scheduler.get_clock(), "completion_delta_s": scheduler.get_clock() - float(planned.end_s), "record": record.duplicate(true)}
		hero.world_action_executed.connect(return_observer)
		var returned: bool = await _swipe(returning, id + " full native ordinary return")
		if is_instance_valid(hero) and hero.world_action_executed.is_connected(return_observer): hero.world_action_executed.disconnect(return_observer)
		if not returned: return false
		timing["return_ready_s"] = scheduler.get_clock()
		if not _require(not timing.return_publication.is_empty(), id + " records the actual completed return before unchanged all-zero input readiness"): return false
	else:
		if not _require(positioning.is_empty(), id + " original stationary primary opening has no fabricated positioning segment"): return false
	if not await _wait(func() -> bool: return scheduler.get_clock() >= float(proof.primary_time_s), id + " actual original native primary time"): return false
	if not _framing(id + " actual primary opening"): return false
	if detailed and not await _full_quiet_capture(id + "-actual-ordinary-opening"): return false
	var primary_observer: Callable = func(record: Dictionary) -> void:
		if record.kind == "primary": timing["primary_publication"] = {"scheduler_clock_s": scheduler.get_clock(), "primary_delta_s": scheduler.get_clock() - float(proof.primary_time_s), "record": record.duplicate(true)}
	hero.world_action_executed.connect(primary_observer)
	var attacked: bool = await _primary(actor, id + " actual role ordinary hit")
	if is_instance_valid(hero) and hero.world_action_executed.is_connected(primary_observer): hero.world_action_executed.disconnect(primary_observer)
	return attacked and _require(not timing.primary_publication.is_empty(), id + " records genuine immediate primary timing without manufacturing clock alignment")


func _full_phase_barrier(id: String, lease: String, cycle: int, phase: String) -> bool:
	full_pause_target = {"id": id, "lease": lease, "cycle": cycle, "phase": phase}
	full_pause_requested = false
	_full_phase_observer()
	if not await _wait(func() -> bool: return _full_phase_pause_reached(id, phase), id + " actual deferred " + phase + " capture", 8.0, true): return false
	var state: Dictionary = sources[id].call("pure_presentation_state")
	var now: float = scheduler.get_clock()
	var native: Dictionary = scheduler.reservation_state(lease)
	if not _require(state.reservation_id == lease and state.cycle == cycle and state.phase == phase and state.status == "running" and not native.is_empty() and (phase != "active" or (now >= float(native.active_from_s) and now <= float(native.active_until_s))), id + " capture records the ACTUAL requested native phase and active interval at the whole-tick barrier"):
		return false
	var frozen: Dictionary = _opening_observation()
	if not _framing(id + " actual " + phase + " full source/field union") or not await _capture(id + "-actual-" + phase): return false
	full_phase_barriers.append(_portable({"id": id, "lease": lease, "cycle": cycle, "phase": phase, "native_clock_s": now, "all_room_ids": _full_ids(), "living_room_ids": _full_living_ids(), "sources": _source_states(), "route": level.call("route_state"), "complete_points": level.camera_framing_points()}))
	if not _require(_opening_observation() == frozen, "phase renderer/camera readers do not change complete observed native state or event counts"): return false
	full_pause_target.clear()
	full_pause_requested = false
	return await _gui_resume_pair()


func _full_phase_pause_reached(id: String, phase: String) -> bool:
	if paused and not full_pause_requested:
		_require_unexpected(false, id + " unexpected focus/pause before requested " + phase + " stops phase observation")
		return false
	return paused and full_pause_requested


func _full_phase_observer() -> void:
	if full_pause_target.is_empty() or full_pause_requested or full_teardown or finishing or aborted or paused: return
	var raw: Variant = sources.get(full_pause_target.id)
	if not is_instance_valid(raw): return
	var state: Dictionary = raw.call("pure_presentation_state")
	if state.reservation_id == full_pause_target.lease and state.cycle == full_pause_target.cycle and state.phase == full_pause_target.phase:
		# Real native active can be published at last-lock epsilon. The strict
		# active clock guard must hold before requesting the public deferred pause.
		if state.phase == "active" and (scheduler.get_clock() < float(state.active_from_s) or scheduler.get_clock() > float(state.active_until_s)): return
		full_pause_requested = bool(game.call("request_pause_deferred"))
		_require_unexpected(full_pause_requested, "actual native phase requests one public deferred pause")


func _notice_phase(state: Dictionary, id: String) -> void:
	if full_teardown or finishing: return
	super._notice_phase(state, id)
	_full_phase_observer()


func _full_living_ids() -> Array[String]:
	var result: Array[String] = []
	for id: String in _full_ids():
		if not sources[id].get("dead"): result.append(id)
	return result


func _primary(actor: CharacterBody3D, label: String) -> bool:
	# Resume happens BEFORE the original readiness/aim/reach/input calculation.
	if portrait and not await _full_floor_court_before_primary(actor): return false
	if not await _ready_input(label + " primary readiness"): return false
	while Time.get_ticks_msec() - last_primary_ms <= 300:
		if not _guard_input(): return false
		await process_frame
	var offset: Vector3 = actor.global_position - hero.global_position
	offset.y = 0.0
	var direction: Vector3 = offset.normalized()
	var anchor: Vector2 = game.call("get_aim_anchor")
	var tap: Vector2 = anchor + _screen_delta(direction) * 160.0
	if not _require(actor.is_in_group("enemies") and offset.length() <= float(hero.equipment.resolved_stats().primary_range) and _input_safe(tap) and (game.call("aim_direction", tap) as Vector3).dot(direction) > .9999, label + " real ordinary reach and literal last-release aim"): return false
	var before_hp: Dictionary = {}
	for id: String in NormalIds: before_hp[id] = float(sources[id].get("hp"))
	var actual_ids: Array[String] = _full_ids()
	var floor_room_before: int = -1
	var floor_generations_before: Dictionary = {}
	if portrait and not full_floor_field_attempted:
		floor_room_before = int(level.call("route_state").beat_index)
		floor_generations_before = _full_floor_generations()
	var target_id: String = String(actor.call("pure_presentation_state").source_id)
	var sequence: int = _last_sequence()
	var press := InputEventScreenTouch.new()
	press.index = 7; press.pressed = true; press.position = tap
	Input.parse_input_event(press)
	await process_frame
	if not _guard_input(): return false
	var release := InputEventScreenTouch.new()
	release.index = 7; release.position = tap
	var actual_shells: int = hero.shells # Read only. Default reload remains live.
	Input.parse_input_event(release)
	await process_frame
	if not _guard_input(): return false
	last_primary_ms = Time.get_ticks_msec()
	primaries += 1
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	var observed: Dictionary = game.call("get_input_observation_state")
	if not _require(records.size() == 1 and records[0].kind == "primary" and records[0].direction.dot(direction) > .9999 and observed.last_observation.kind == "primary_tap" and observed.last_observation.accepted and observed.last_observation.world_action_sequence == records[0].sequence and (game.call("get_aim_anchor") as Vector2).is_equal_approx(anchor), label + " publishes exactly one immediate first-tap ordinary action without ammo staging or blast input"):
		return false
	var hit_count: int = 0
	var losses: Dictionary = {}
	for id: String in NormalIds:
		var loss: float = float(before_hp[id]) - float(sources[id].get("hp"))
		if not _require(loss >= 0.0 and (loss == 0.0 or id in actual_ids), id + " HP cannot heal or damage future/prior cast through a room opening"): return false
		if loss > 0.0:
			hit_count += 1; losses[id] = loss
			if not _require(absf(loss - minf(float(before_hp[id]), float(records[0].damage))) <= CrowdEpsilon, id + " genuine actual HP loss matches this ordinary damage receipt"): return false
	if not _require(hit_count > 0 and hit_count == int(records[0].hits) and float(actor.get("hp")) < float(before_hp[target_id]) and hero.hp == initial_hp and hit_events.is_empty(), label + " credits all actual hit recipients and preserves Hero HP/no enemy hits"):
		return false
	crowd_primary_receipts.append({"sequence": records[0].sequence, "shells_at_release": actual_shells, "shells_staged": false, "actual_hp_losses": losses, "record": _portable(records[0])})
	if portrait and not await _full_floor_after_primary(floor_room_before, floor_generations_before, int(records[0].sequence)): return false
	return true


func _full_floor_court_before_primary(actor: CharacterBody3D) -> bool:
	if not portrait or full_floor_court_attempted: return true
	var route: Dictionary = level.call("route_state")
	if int(route.beat_index) != 4: return true
	var native: Dictionary = actor.call("get_spore_native_bindings")
	var art: Node = level.get_node_or_null("FungalArt")
	if native.is_empty() or native.configuration.entity_id != "C32" or not is_instance_valid(art) or art.get("court_open") != false: return true
	full_floor_court_attempted = true
	full_floor_capture_request = {"kind": "court_before_primary", "source_id": native.source_id, "entity_id": native.configuration.entity_id, "role_id": native.configuration.role_id, "requested_route": route.duplicate(true)}
	var result: bool = await _full_quiet_capture("court-actual-C32-before-primary")
	full_floor_capture_request = {}
	if not result: return false
	var observed: Dictionary = shots.back().floor_view_native
	var court: Dictionary = observed.court
	var blocked: bool = court.get("court_open") == false and court.get("blocked_visible_in_tree") == true and court.get("open_visible_in_tree") == false
	full_floor_coverage.court = {"status": "captured_blocked_native_state" if blocked else "missing_blocked_state_at_capture", "path": shots.back().path, "actual_paused": observed}
	return true


func _full_floor_generations() -> Dictionary:
	var generations: Dictionary = {}
	if not portrait: return generations
	for child: Node in level.get_children():
		if child is CinderSporeField:
			var state: Dictionary = (child as CinderSporeField).state()
			generations[String(state.instance_id)] = int(state.generation)
	return generations


func _full_floor_after_primary(before_room: int, before: Dictionary, sequence: int) -> bool:
	if not portrait or full_floor_field_attempted: return true
	var route: Dictionary = level.call("route_state")
	if int(route.beat_index) != before_room or route.room_stage != "active":
		full_floor_coverage.field = {"status": "missing", "reason": "room_changed_after_actual_primary", "primary_sequence": sequence, "before_room": before_room, "actual_route": route.duplicate(true)}
		return true
	for child: Node in level.get_children():
		if not child is CinderSporeField: continue
		var field: CinderSporeField = child as CinderSporeField
		var state: Dictionary = field.state()
		var id: String = String(state.instance_id)
		if id not in full_spec.room_fields[before_room] or not before.has(id) or int(state.generation) != int(before[id]) + 1: continue
		if field.active_domain().is_empty():
			full_floor_coverage.field = {"status": "missing", "reason": "natural_increment_already_expired_before_capture_request", "primary_sequence": sequence, "actual_field": state.duplicate(true)}
			return true
		full_floor_field_attempted = true
		full_floor_capture_request = {"kind": "post_primary_field_observation", "field_id": id, "generation_before": before[id], "primary_sequence": sequence, "requested_room": before_room, "actual_field_at_request": state.duplicate(true)}
		# Neutral label: this real field can expire during the unchanged view wait.
		var result: bool = await _full_quiet_capture("actual-ordinary-primary-field-observation")
		full_floor_capture_request = {}
		if not result: return false
		var observed: Dictionary = shots.back().floor_view_native
		var actual: Dictionary = observed.fields.get(id, {})
		var same_room: bool = int(observed.route.beat_index) == before_room and observed.route.room_stage == "active"
		var live: bool = same_room and not actual.get("native_domain", {}).is_empty() and actual.get("state", {}).get("generation") == state.generation and actual.get("state", {}).get("deadline_s") == state.deadline_s and actual.get("state", {}).get("spent_ids") == state.spent_ids
		var active_cluster: bool = false
		var spent_cluster: bool = false
		for cue: Dictionary in actual.get("cluster_cues", []):
			active_cluster = active_cluster or cue.get("state") == "active"
			spent_cluster = spent_cluster or cue.get("state") == "spent"
		var covered: bool = live and active_cluster and spent_cluster
		var missing_reason: String = "" if covered else ("room_changed_during_view_settlement" if not same_room else ("field_expired_during_view_settlement" if actual.get("native_domain", {}).is_empty() else "actual_active_and_spent_pair_not_observed"))
		full_floor_coverage.field = {"status": "captured_actual_active_and_spent_cluster_states" if covered else "missing_active_and_spent_at_capture", "reason": missing_reason, "path": shots.back().path, "actual_paused": observed}
		return true
	full_floor_coverage.field = {"status": "missing", "reason": "no_natural_current_room_generation_increment", "primary_sequence": sequence, "room": before_room}
	return true


func _full_floor_paused_view() -> Dictionary:
	var view: Dictionary = {}
	if not portrait or full_floor_capture_request.is_empty(): return view
	view = {"route": level.call("route_state"), "court": {}, "fields": {}, "required_frame_points": level.camera_framing_points()}
	var art: Node = level.get_node_or_null("FungalArt")
	var blocked: Node3D = level.get_node_or_null("FungalArt/CourtCurtainO56/BlockedDrapery") as Node3D
	var opened: Node3D = level.get_node_or_null("FungalArt/CourtCurtainO56/OpenGatheredDrapery") as Node3D
	if is_instance_valid(art) and is_instance_valid(blocked) and is_instance_valid(opened):
		view.court = {"court_open": art.get("court_open"), "blocked_visible": blocked.visible, "blocked_visible_in_tree": blocked.is_visible_in_tree(), "open_visible": opened.visible, "open_visible_in_tree": opened.is_visible_in_tree()}
	for child: Node in level.get_children():
		if child is CinderSporeField:
			var field: CinderSporeField = child as CinderSporeField
			var state: Dictionary = field.state()
			view.fields[String(state.instance_id)] = {"state": state, "native_domain": field.active_domain(), "cluster_cues": field.get_cue_state().clusters, "origin": field.global_position}
	return view


func _full_environment(room: int, fresh: bool) -> bool:
	var fields: Dictionary = {}
	var consumers: Dictionary = {}
	for child: Node in level.get_children():
		if child is CinderSporeField: fields[child.state().instance_id] = child
		if child is CinderSporeRepulsion: consumers[child.consumer_id()] = child
	var expected_fields: Array[String] = []
	var expected_consumers: Array[String] = []
	var expected_room_keys: Array[String] = []
	for index: int in range(room + 1):
		for id: String in full_spec.room_fields[index]: expected_fields.append(id)
		if not full_spec.room_fields[index].is_empty():
			expected_room_keys.append(FullRoomNames[index])
			expected_consumers.append("a1_l3_" + FullRoomNames[index] + "_spores")
	var route: Dictionary = level.call("route_state")
	if not _require(Codec.keys_error(fields, expected_fields).is_empty() and Codec.keys_error(consumers, expected_consumers).is_empty() and route.installed_fields == expected_fields and route.installed_consumers == expected_room_keys, "only actually entered rooms install the exact retained native field/consumer set"):
		return false
	for id: String in expected_fields:
		var field: CinderSporeField = fields[id]
		var actual: Dictionary = field.state()
		if full_field_refs.has(id):
			if not _require(field == full_field_refs[id], "previously installed actual field identity persists: " + id): return false
		else: full_field_refs[id] = field
		if not _require(field.global_position == full_spec.field_points[id] and actual.bound and String(field.binding_error()).is_empty() and int(actual.remaining_clusters) + int(actual.generation) == 2 and actual.spent_ids.size() == int(actual.generation), "native finite field retains actual placement/supply custody: " + id): return false
		if fresh and id in full_spec.room_fields[room]:
			if not _require(actual.phase == "available" and actual.generation == 0 and actual.remaining_clusters == 2 and actual.spent_ids.is_empty() and actual.activation_s == null and actual.deadline_s == null, "new native field begins with true available finite supplies: " + id): return false
		for cluster_id: String in ["cluster-left", "cluster-right"]:
			var cluster: Node = field.get_node_or_null(cluster_id)
			var art: Node = cluster.get_node_or_null("AuthoredLowCluster") if is_instance_valid(cluster) else null
			if not _require(is_instance_valid(cluster) and is_instance_valid(art) and cluster.is_in_group("environment_attack_targets") and String(art.call("binding_error")).is_empty(), "real native cluster retains its own actual art/target binding"): return false
	for index: int in range(room + 1):
		if full_spec.room_fields[index].is_empty(): continue
		var name: String = "a1_l3_" + FullRoomNames[index] + "_spores"
		var consumer: CinderSporeRepulsion = consumers[name]
		if full_consumer_refs.has(name):
			if not _require(consumer == full_consumer_refs[name], "previous actual consumer identity remains retained"): return false
		else: full_consumer_refs[name] = consumer
		if not _require(consumer.placement_accepted() and consumer.snapshot_boundary_available(), "actual room consumer remains natively bound and outside its callback transaction"): return false
		var matched: Array[String] = []
		for id: String in NormalIds:
			if consumer.source_binding_matches(sources[id], id): matched.append(id)
		if not _require(matched == _full_ids(index), "each retained actual consumer keeps exactly its room source/Protocol recipients"): return false
		if index == room:
			for id: String in _full_ids(room):
				var response: Dictionary = sources[id].call("get_spore_response_state")
				var guard: Callable = sources[id].get("spore_route_guard")
				if not _require(response.consumer_id == name and sources[id].get("spore_route_guard_required") and guard.is_valid(), "actual living room source uses its retained native Protocol and required actual route guard"): return false
	return true


func _sample_opening() -> void:
	if full_teardown or finishing or aborted or paused or not is_instance_valid(scheduler): return
	var old_epoch: String = opening_last_epoch
	super._sample_opening()
	if old_epoch != opening_last_epoch: crowd_previous.clear() # Actual room clock can reset ONLY on epoch change.


func _sample_crowd() -> void:
	if full_teardown or finishing or aborted or paused or not is_instance_valid(scheduler): return
	_sample_opening()
	var now: float = scheduler.get_clock()
	var ids: Array[String] = _full_ids()
	for id: String in ids:
		var actor: CharacterBody3D = sources[id]
		var state: Dictionary = actor.call("pure_presentation_state")
		var response: Dictionary = actor.call("get_spore_response_state")
		var previous: Dictionary = crowd_previous.get(id, {})
		var current: Dictionary = {"clock_s": now, "position": actor.global_position, "velocity": actor.velocity, "facing": state.facing, "phase": state.phase, "lease": state.reservation_id, "cycle": state.cycle, "hurt_left_s": state.hurt_left_s, "dead": state.dead, "driving": state.approach_driving, "environment_phase": response.get("phase", "none")}
		if not previous.is_empty() and now > float(previous.clock_s) and not state.dead and not previous.dead:
			var elapsed: float = now - float(previous.clock_s)
			var step: float = _planar_distance(actor.global_position, previous.position)
			if state.reservation_id.is_empty() and previous.lease.is_empty() and state.cycle == previous.cycle and state.hurt_left_s == 0.0 and previous.hurt_left_s == 0.0 and current.environment_phase == "none" and previous.environment_phase == "none":
				var angle: float = acos(clampf(state.facing.normalized().dot((previous.facing as Vector3).normalized()), -1.0, 1.0))
				if not _require_unexpected(angle <= 3.0 * elapsed + MotionTolerance, id + " ordinary idle native turn keeps its original gradual rate"): return
				maximum_turn_rate = maxf(maximum_turn_rate, angle / elapsed)
				if state.approach_driving or previous.driving:
					var speed: float = Vector2(actor.velocity.x, actor.velocity.z).length()
					if not _require_unexpected(speed <= 1.2 + MotionTolerance and step <= 1.2 * elapsed + MotionTolerance, id + " actual ordinary approach uses original slow native motion"): return
					maximum_speed = maxf(maximum_speed, speed)
					approach_frames += 1; approach_displacement[id] = float(approach_displacement[id]) + step
			if not state.reservation_id.is_empty() and state.reservation_id == previous.lease:
				if not _require_unexpected(not state.approach_driving, id + " leased native attack retains motion ownership"): return
				if state.phase == previous.phase and state.phase in ["warning", "lock", "recovery"]:
					if not _require_unexpected(step <= CrowdEpsilon and actor.velocity == Vector3.ZERO, id + " native planted warning/lock/recovery cannot pursue"): return
		crowd_previous[id] = current
		if crowd_motion_samples.size() < 2048: crowd_motion_samples.append(_portable({"source_id": id, "sample": current}))
	for a: int in range(ids.size()):
		for b: int in range(a + 1, ids.size()):
			if sources[ids[a]].get("dead") or sources[ids[b]].get("dead"): continue
			var first: CollisionShape3D = opening_references[ids[a]].body
			var second: CollisionShape3D = opening_references[ids[b]].body
			if not _require_unexpected(_planar_distance(first.global_position, second.global_position) + CrowdEpsilon >= (first.shape as CapsuleShape3D).radius + (second.shape as CapsuleShape3D).radius, "every actual living room pair retains nonoverlapping native capsules"): return


func _full_notice_defeat(id: String) -> void:
	if full_teardown or finishing: return
	var state: Dictionary = sources[id].call("pure_presentation_state")
	full_defeats[id] = int(full_defeats.get(id, 0)) + 1
	full_defeat_receipts.append(_portable({"source_id": id, "state": state, "room": level.call("route_state"), "body_disabled": opening_references[id].body.disabled, "native_clock_s": scheduler.get_clock()}))
	_require_unexpected(full_defeats[id] == 1 and id in _full_ids() and state.dead and state.hp == 0.0 and opening_references[id].body.disabled and not sources[id].is_in_group("enemies"), "only one genuine current-room actual native defeat retires " + id)


func _notice_checkpoint(id: String, checkpoint: String, kind: String) -> void:
	var index: int = opening_checkpoint_events.size()
	opening_checkpoint_events.append({"level_id": id, "checkpoint_id": checkpoint, "kind": kind})
	var correct: bool = index < 4 and id == "A1-L3" and checkpoint == full_spec.checkpoint_ids[index] and kind == "encounter"
	var route: Dictionary = level.call("route_state")
	correct = correct and route.beat_index == index + 1 and route.completed_beats == FullBeats.slice(0, index + 1) and route.room_stage == "approach" and _full_room_dead(index)
	var duplicate: bool = level.request_checkpoint(checkpoint, kind)
	var future_id: String = full_spec.checkpoint_ids[index + 1] if index + 1 < 4 else "court-approach"
	var future: bool = level.request_checkpoint(future_id, "encounter")
	var completion: bool = level.request_completion(full_spec.completion_id)
	var contact: bool = level.request_contact_exit(full_spec.exit_id, hero)
	var guards: bool = not duplicate and not future and not completion and not contact
	opening_nested_rejected = guards if index == 0 else opening_nested_rejected and guards
	full_checkpoint_guards.append({"index": index, "actual": opening_checkpoint_events.back(), "route": _portable(route), "nested_duplicate": duplicate, "nested_future": future, "nested_completion": completion, "nested_contact": contact})
	_require_unexpected(correct and guards, "only actual required completed prefix publishes checkpoint and rejects nested current/future/completion/contact requests")


func _full_notice_completion(id: String, completion: String) -> void:
	var route: Dictionary = level.call("route_state")
	var rejected: bool = not level.request_completion(completion) and not level.request_checkpoint("court-approach", "encounter") and not level.request_contact_exit(full_spec.exit_id, hero)
	full_completion_receipts.append({"level_id": id, "completion_id": completion, "route": _portable(route), "nested_rejected": rejected})
	_require_unexpected(id == "A1-L3" and completion == full_spec.completion_id and route.beat_index == 5 and route.completed_beats == FullBeats and _full_all_dead() and opening_checkpoint_events.size() == 4 and rejected, "one native completion follows all nineteen real defeats/four checkpoints and rejects nested progress/contact")


func _full_notice_contact(id: String, exit_id: String) -> void:
	var area: Area3D = level.get_node_or_null("ActualOpenCourtContact") as Area3D
	var actual_overlap: bool = is_instance_valid(area) and area.overlaps_body(hero)
	var duplicate: bool = level.request_contact_exit(exit_id, hero)
	full_contact_receipts.append({"level_id": id, "exit_id": exit_id, "actual_overlap": actual_overlap, "hero_position": _portable(hero.global_position), "world_action_sequence": _last_sequence(), "nested_duplicate": duplicate})
	_require_unexpected(id == "A1-L3" and exit_id == full_spec.exit_id and actual_overlap and level.is_completed() and _full_all_dead() and not duplicate, "actual shared Hero/body Area overlap emits one completed contact exit without destination fabrication")


func _full_all_dead() -> bool:
	for id: String in NormalIds:
		if not sources[id].get("dead") or float(sources[id].get("hp")) != 0.0 or full_defeats.get(id, 0) != 1: return false
	return true


func _full_room_boundary(room: int) -> bool:
	_sample_opening()
	if not _require(_full_room_dead(room) and scheduler.encounter_profile().is_empty() and scheduler.reservations().is_empty() and hero.hp == initial_hp and hit_events.is_empty() and not preparing_violation and max_preparing == 1 and opening_completion_events == (1 if room == 4 else 0) and opening_contact_events == 0 and opening_checkpoint_events.size() == mini(room + 1, 4), "genuine room boundary retires native epoch/leases and grants exactly authored progress without injury"):
		return false
	for id: String in _full_allowed(room):
		var control: Dictionary = scheduler.source_control_state(sources[id])
		if not _require(full_defeats[id] == 1 and sources[id].get("dead") and control.reservations.is_empty() and control.cooldown == null, "every truly cleared source retains defeat and quiet native boundary truth"): return false
	if not _retained_truth("true room boundary") or not _future_pristine(_full_allowed(room), "completed room future pristine") or not _full_environment(room, false): return false
	full_room_receipts.append(_portable({"room": room, "route": level.call("route_state"), "epochs": opening_epochs, "checkpoint": level.current_checkpoint(), "completed": level.is_completed(), "defeat_counts": full_defeats, "actual_fields": _opening_observation().fields}))
	return await _full_quiet_capture("%s-actual-native-clear-boundary" % FullRoomNames[room])


func _full_final_progress() -> bool:
	var expected: Array[Dictionary] = []
	for id: String in full_spec.checkpoint_ids: expected.append({"level_id": "A1-L3", "checkpoint_id": id, "kind": "encounter"})
	return _require(_full_all_dead() and full_defeat_receipts.size() == 19 and opening_checkpoint_events == expected and full_checkpoint_guards.size() == 4 and opening_nested_rejected and level.current_checkpoint() == {"id": "spear-pocket", "kind": "encounter"} and level.is_completed() and opening_completion_events == 1 and full_completion_receipts.size() == 1 and opening_epochs == _full_expected_epochs(4) and full_room_receipts.size() == 5, "all nineteen genuine defeats publish exactly four ordered checkpoints and one completion in five observed native epochs")


func _full_physical_exit() -> bool:
	var area: Area3D = level.get_node_or_null("ActualOpenCourtContact") as Area3D
	if not _require(is_instance_valid(area) and area.monitoring and opening_contact_events == 0, "actual completed court retains its native physical contact Area"): return false
	if not area.overlaps_body(hero):
		if not _require(not level.request_contact_exit(full_spec.exit_id, hero), "public exit rejects the real Hero before actual contact overlap"): return false
	if not _require(not level.request_contact_exit(full_spec.exit_id, sources["umbrella-1"]), "contact rejects an actual non-Hero retained source body"): return false
	for step: int in range(20):
		if opening_contact_events == 1: break
		var direction: Vector3 = Vector3.FORWARD
		if absf(hero.global_position.x - area.global_position.x) > 1.35:
			direction = Vector3.LEFT if hero.global_position.x > area.global_position.x else Vector3.RIGHT
		elif hero.global_position.z < area.global_position.z:
			direction = Vector3.BACK
		if not await _full_route_step(direction, "whole actual open-court contact approach %d" % [step + 1]): return false
	if not await _wait(func() -> bool: return opening_contact_events == 1 and full_contact_receipts.size() == 1, "actual continuous native Hero dash contacts completed open court exactly once", 2.0): return false
	if not _require(not level.request_contact_exit(full_spec.exit_id, hero) and hero.hp == initial_hp and hit_events.is_empty(), "completed actual contact is once-only and preserves Hero resources/no enemy hits"): return false
	return await _full_quiet_capture("actual-contact-exit")


func _full_action_history() -> bool:
	if not _require(world_records.size() == input_observations.size() and world_records.size() == swipes + primaries and not world_records.is_empty(), "full native world signal trace retains every real dash/ordinary action and recognizer receipt beyond Player history capacity"): return false
	var tail: Array[Dictionary] = []
	for index: int in range(maxi(0, world_records.size() - CinderPlayer.MAX_WORLD_ACTION_RECORDS), world_records.size()): tail.append(world_records[index])
	if not _require(hero.get_world_action_records() == tail and tail.size() <= 64, "Player preserves the unchanged exact newest64 tail without growing the shared cache"): return false
	full_evidence_history.clear()
	for index: int in range(world_records.size()):
		var record: Dictionary = world_records[index]
		var input: Dictionary = input_observations[index]
		var encoded: Dictionary = CinderPlayer.encode_world_action_record(record, hero.get_world_action_clock())
		# Shared swipe_release deliberately reports accepted=false: it records
		# the literal anchor, not the completed dash. That dash's world record is
		# the actual movement authority. A slow rendered frame can finish a
		# drag-started dash BEFORE release; preserve the real publication order.
		var valid_input: bool = input.kind == "primary_tap" and input.accepted and input.world_action_sequence == record.sequence
		if record.kind == "dash":
			var prior_at_release: bool = input.world_action_sequence == int(record.sequence) - 1 and float(input.action_clock_s) <= float(record.completed_at_s)
			var done_at_release: bool = input.world_action_sequence == record.sequence and float(input.action_clock_s) >= float(record.completed_at_s)
			valid_input = input.kind == "swipe_release" and not input.accepted and (prior_at_release or done_at_release)
		if not _require(record.sequence == index + 1 and record.kind in ["dash", "primary"] and not encoded.is_empty() and input.sequence == index + 1 and valid_input, "full world signal record matches actual primary/dash publication, unchanged release-observation semantics and one recognizer sequence"): return false
		full_evidence_history.append(encoded)
	return _require(crowd_primary_receipts.size() == primaries, "every ordinary primary has its all-nineteen actual HP-loss receipt; no blast action occurred")


func _unsupported_save_barrier() -> bool:
	if not await _full_pause("normal full route unsupported aggregate"): return false
	var before: Dictionary = _opening_observation()
	var player: Dictionary = hero.snapshot_state()
	var checkpoint_ids: Dictionary = {}
	for receipt: Dictionary in opening_checkpoint_events: checkpoint_ids[receipt.checkpoint_id] = receipt.kind
	var current: Dictionary = level.current_checkpoint()
	var completed: bool = level.is_completed()
	var envelope: Dictionary = {"api_revision": CinderLevel.API_REVISION, "schema_version": CinderLevel.SNAPSHOT_SCHEMA_VERSION, "level_id": "A1-L3", "scene_path": level.scene_file_path, "local_snapshot_version": level.local_snapshot_version, "progress": {"completed": completed, "completion_id": full_spec.completion_id if completed else "", "contact_exit_id": full_spec.exit_id if opening_contact_events == 1 else "", "checkpoint_id": current.id, "checkpoint_kind": current.kind, "checkpoint_ids": checkpoint_ids}, "local": {}}
	var saved: Dictionary = level.snapshot_state()
	var capture_error: String = level.last_snapshot_error
	var pure_error: String = level.snapshot_error(envelope)
	var context_error: String = level.snapshot_error_with_player(envelope, player)
	var restored: bool = level.restore_state(envelope)
	if not _require(not player.is_empty() and saved.is_empty() and not capture_error.is_empty() and not pure_error.is_empty() and not context_error.is_empty() and not restored and _opening_observation() == before, "actual observed full-route progress does not grant unsupported aggregate capture/candidate validation/restore or mutate native state"):
		return false
	if not _framing("actual unsupported-save boundary") or not await _capture("actual-full-save-still-denied"): return false
	return await _gui_resume_pair()


func _framing(label: String) -> bool:
	if not _require(is_instance_valid(level) and is_instance_valid(game) and is_instance_valid(hero) and is_instance_valid(scheduler) and level.hero == hero and game.get("player") == hero and game.get("active_level") == level, label + " retains the actual entered level/shared Hero/Scheduler before framing"):
		return false
	var points: Array = level.camera_framing_points()
	# Every nonempty set, including native INF/error sentinels, keeps the
	# inherited STRICT full-source/field/cue/response containment guard.
	if not points.is_empty(): return super._framing(label)
	if not _require(level.last_camera_framing_error.is_empty(), label + " cannot reinterpret a native invalid-point error as an empty approach requirement"):
		return false
	# Read the actual native definition locally: this helper is safe before the
	# caller assigns full_spec after inherited _open_world() returns.
	var route: Dictionary = level.call("route_state")
	var spec: Dictionary = level.call("normal_route_spec")
	var raw_beat: Variant = route.get("beat_index")
	var room_sources: Variant = spec.get("room_sources")
	var room_fields: Variant = spec.get("room_fields")
	if not _require(typeof(raw_beat) == TYPE_INT and raw_beat >= 0 and raw_beat < 5 and route.get("room_stage") == "approach" and route.get("encounter_started") == false and not level.is_completed() and room_sources is Array and room_sources.size() == 5 and room_fields is Array and room_fields.size() == 5 and spec.get("sources") == NormalIds and Codec.keys_error(sources, NormalIds).is_empty() and scheduler.encounter_profile().is_empty(), label + " empty authored points belong only to the genuine unbegun native approach stage"):
		return false
	var beat: int = int(raw_beat)
	var expected: Array = room_sources[beat]
	var actual: Array = level.call("current_source_ids")
	if not _require(not expected.is_empty() and actual == expected and route.get("installed_fields") is Array and route.get("installed_consumers") is Array and FullRoomNames[beat] not in route.installed_consumers, label + " actual next-room recipients are exact and its environmental consumer is not installed"):
		return false
	for field_id: String in room_fields[beat]:
		if not _require(field_id not in route.installed_fields, label + " empty approach requirements cannot omit an installed current-room field"):
			return false
	for id: String in NormalIds:
		var raw: Variant = sources.get(id)
		if not _require(is_instance_valid(raw) and raw is CharacterBody3D and raw == level.get("sources").get(id) and raw.get_parent() == level and raw.is_inside_tree() and not raw.is_queued_for_deletion(), label + " retains each actual normal-route source before allowing empty requirements"):
			return false
		var actor: CharacterBody3D = raw
		var state: Dictionary = actor.call("pure_presentation_state")
		var control: Dictionary = scheduler.source_control_state(actor)
		if not _require(not state.is_empty() and (state.get("dormant") == true or state.get("dead") == true) and not control.is_empty() and control.get("outside_transaction") == true and control.get("encounter_id") == "" and control.get("reservations", [null]).is_empty() and control.get("cooldown") == null, label + " empty approach points omit no living active source or retained native exchange"):
			return false
		if id not in actual: continue
		var native: Dictionary = actor.call("get_spore_native_bindings")
		var body: CollisionShape3D = actor.get_node_or_null("BodyCollision") as CollisionShape3D
		var response: Dictionary = actor.call("get_spore_response_state")
		if not _require(not native.is_empty() and native.get("source_id") == id and native.get("player") == hero and native.get("scheduler") == scheduler and native.get("configuration") is Dictionary and body != null and body.shape is CapsuleShape3D and body.disabled and not actor.visible and not actor.is_visible_in_tree() and not actor.is_in_group("enemies") and actor.collision_layer == 0 and actor.collision_mask == 0 and String(actor.call("body_binding_error")).is_empty() and String(actor.call("art_binding_error")).is_empty(), label + " actual approach recipient remains its native hidden disabled body/art/configuration"):
			return false
		var configuration: Dictionary = native.configuration
		var guard: bool = configuration.get("entity_id") == "C32"
		if not _require(configuration.get("entity_id") in ["C31", "C32"] and configuration.get("source_id") == id and state.get("source_id") == id and state.get("entity_id") == configuration.entity_id and state.get("role_id") == configuration.role_id and state.get("hp") == (24.0 if guard else 16.0) and state.get("dead") == false and state.get("dormant") == true and state.get("status") == "dormant" and state.get("phase") == "clear" and state.get("cycle") == 0 and state.get("reservation_id") == "" and state.get("geometry", {"invalid": true}).is_empty() and state.get("velocity") == Vector3.ZERO and state.get("approach_driving") == false and state.get("approach_enabled") == (not guard) and state.get("hurt_left_s") == 0.0 and state.get("last_cancel_reason") == "" and not response.is_empty() and response.get("alive") == false and response.get("consumer_id") == "" and response.get("episode_id") == "" and response.get("phase") == "none", label + " current recipient is genuinely pristine dormant under its actual native role"):
			return false
	# Pure control views above already reject every actual normal source lease;
	# the pure native global committed-exchange view must also be empty. Never reset
	# Scheduler time/profile here; end_encounter retains the old clock value.
	if not _require(not scheduler.has_committed_exchange() and String(game.get("last_camera_framing_error")).is_empty(), label + " unbegun native Scheduler and current shared camera retain no pending exchange/error"):
		return false
	var hero_points: Array = game.call("player_camera_framing_points")
	if not _require(not hero_points.is_empty(), label + " legitimate empty-source approach still requires the actual complete Hero body/art/shadow bounds"):
		return false
	for point: Variant in hero_points:
		if not _require(point is Vector3 and point.is_finite(), label + " actual Hero requirement corners remain finite"):
			return false
	return _require(level.last_camera_framing_error.is_empty() and String(game.get("last_camera_framing_error")).is_empty() and String(game.call("camera_framing_error", hero_points)).is_empty(), label + " genuine source-empty approach contains the complete actual Hero in the unchanged native portrait camera")


func _full_pause(label: String) -> bool:
	if paused: return _require(_resume_button(game.get("hud") as Node) != null, label + " retains the real public Pause menu")
	if not _require(game.call("request_pause_deferred"), label + " requests actual deferred whole-tick pause"): return false
	return await _wait(func() -> bool: return paused, label + " reaches actual pause barrier", 2.0, true)


func _full_quiet_capture(stage: String) -> bool:
	# The original SINGLE2 native pause window now includes current view readiness.
	# A physics-complete deferred pause does not settle the pausable Game camera.
	# Dictionary capture is shared by reference; do not capture a mutable bool.
	var observation: Dictionary = {"requested": false}
	if not await _wait(func() -> bool:
		if not _require_unexpected(is_instance_valid(hero) and not hero.dead, stage + " retains the actual living Hero during capture observation"): return false
		if paused:
			if not _require_unexpected(observation.requested, stage + " unexpected focus/pause before the requested capture stops observation"): return false
			return _resume_button(game.get("hud") as Node) != null
		if not _guard_input(): return false
		if observation.requested or not _full_capture_view_ready(): return false
		observation.requested = bool(game.call("request_pause_deferred"))
		_require_unexpected(observation.requested, stage + " requests one actual deferred pause after complete current view readiness")
		return false, stage + " reaches complete current framing and the actual pause barrier", 2.0, true): return false
	if not _framing(stage) or not await _capture(stage): return false
	return await _gui_resume_pair()


func _full_capture_view_ready() -> bool:
	# Pure CURRENT containment only. Original strict _framing remains after pause.
	if not is_instance_valid(level) or not is_instance_valid(game) or not is_instance_valid(hero): return false
	var points: Array = level.camera_framing_points()
	if not level.last_camera_framing_error.is_empty(): return false
	if points.is_empty():
		# The genuine unbegun intermediate approach has no live source requirement.
		# Read every actual shared Hero corner; later strict approach guards retain
		# their complete source/epoch/body/configuration checks without duplication.
		var route: Dictionary = level.call("route_state")
		if route.get("room_stage") != "approach" or route.get("encounter_started") != false or not route.get("beat_index") is int or route.beat_index < 0 or route.beat_index >= 5 or level.is_completed(): return false
		if not String(game.get("last_camera_framing_error")).is_empty(): return false
		points = game.call("player_camera_framing_points")
	if points.is_empty() or points.size() > 224: return false
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite(): return false
	return String(game.call("camera_framing_error", points)).is_empty()


func _capture(stage: String) -> bool:
	if not portrait: return not aborted and not finishing
	var hud: GameHUD = game.get("hud") as GameHUD
	if not _require(paused and is_instance_valid(hud) and _resume_button(hud) != null, "native full-route capture requires real paused HUD/clock before removing its modal"): return false
	var before: Dictionary = _opening_observation()
	var floor_view: Dictionary = _full_floor_paused_view()
	hud.hide_overlay()
	var result: bool = await super._capture(stage)
	hud.show_pause()
	if not result: return false
	shots.back()["capture_overlay"] = "public HUD hide_overlay only while whole native world paused; public show_pause before real GUI Resume"
	shots.back()["room_ids"] = _full_ids()
	shots.back()["fields"] = _portable(before.fields)
	if not full_floor_capture_request.is_empty():
		shots.back()["floor_view_request"] = _portable(full_floor_capture_request)
		shots.back()["floor_view_native"] = _portable(floor_view)
	return _require(paused and _opening_observation() == before and _resume_button(hud) != null, "unobstructed native renderer/camera capture changes no observed source/field/Player/clock/event and restores public Pause")


func _wait(predicate: Callable, label: String, seconds: float = 8.0, allow_pause: bool = false) -> bool:
	# Semantic waits use this ONE actual Hero's monotone public action clock.
	# Scheduler room epochs reset clock; wall-frame slowness grants no native
	# readiness. The separate finite full-route wall watchdog remains mandatory.
	var initial_clock: float = hero.get_world_action_clock() if is_instance_valid(hero) else 0.0
	while not aborted and not finishing:
		if predicate.call(): return _require(true, label)
		if not allow_pause and not _guard_input(): return false
		if not is_instance_valid(hero) or hero.get_world_action_clock() - initial_clock >= seconds: break
		_sample_preparing()
		await process_frame
	if aborted or finishing: return false
	_full_diagnostic(label + " native wait expired")
	return _require(false, label + " within original finite simulation window")


func _full_disconnect_observers() -> void:
	full_teardown = true
	full_pause_target.clear()
	if process_frame.is_connected(_sample_opening): process_frame.disconnect(_sample_opening)
	if process_frame.is_connected(_sample_crowd): process_frame.disconnect(_sample_crowd)
	if physics_frame.is_connected(_full_phase_observer): physics_frame.disconnect(_full_phase_observer)


func _full_diagnostic(label: String) -> void:
	var record: Dictionary = {"label": label, "route": level.call("route_state") if is_instance_valid(level) else {}, "hero_response": hero.get_threat_response_state() if is_instance_valid(hero) else {}, "committed_dash": hero.get_committed_dash_state() if is_instance_valid(hero) else {}, "sources": _source_states(), "camera": game.call("get_camera_framing_state") if is_instance_valid(game) else {}, "swipes": swipes, "primaries": primaries, "defeats": full_defeats.duplicate(), "checkpoint_events": opening_checkpoint_events, "completion_receipts": full_completion_receipts, "contact_receipts": full_contact_receipts, "paused": paused}
	record["camera_provider_diagnostic"] = _full_camera_provider_diagnostic()
	full_diagnostics.append(_portable(record))
	print("NORMAL FULL L3 DIAGNOSTIC ", label, " ", _portable(record))


func _full_camera_provider_diagnostic() -> Dictionary:
	# Read-only attribution of the failed current union. Comparative pure plans
	# never replace required runtime corners, authorize movement or grant damage.
	if not is_instance_valid(level) or not is_instance_valid(game) or not is_instance_valid(hero): return {}
	var providers: Dictionary = {"unadmitted_forecast": level.get("_forecast_points").duplicate(true), "approach_forecasts": [], "approach_camera_requests": [], "current_sources_cues": [], "accepted_responses": []}
	var approach_forecasts: Dictionary = level.get("_approach_forecasts").duplicate(true)
	var approach_requests: Dictionary = level.get("_approach_camera_requests").duplicate(true)
	var accepted_frames: Dictionary = level.get("_framing").duplicate(true)
	for points: Array in approach_forecasts.values(): providers.approach_forecasts.append_array(points)
	for points: Array in approach_requests.values(): providers.approach_camera_requests.append_array(points)
	var actual_states: Dictionary = _source_states()
	for id: String in _full_ids():
		var state: Dictionary = actual_states.get(id, {})
		if state.is_empty() or state.get("dead", false) or state.get("dormant", false): continue
		providers.current_sources_cues.append_array(level.call("_actor_points", id, state.opening_position))
		if state.get("geometry", {}).get("kind") == "lane": providers.current_sources_cues.append_array(level.call("_lane_points", state.geometry))
		providers.current_sources_cues.append_array(level.call("_cue_points", id, state))
	for frame: Dictionary in accepted_frames.values(): providers.accepted_responses.append_array(level.call("_response_points", frame.landing, frame.attack_position))
	var required: Array = level.call("_camera_framing_points")
	var desired: Vector3 = hero.global_position + Vector3(0, 0.65, 0)
	var component: Array = []
	for points: Array in providers.values(): component.append_array(points)
	var comparative: Dictionary = {}
	for excluded: String in providers:
		var comparison: Array = []
		for key: String in providers:
			if key != excluded: comparison.append_array(providers[key])
		comparative[excluded] = game.call("camera_framing_plan", level.call("_bounded_union", comparison), desired)
	return {"scope": "pure diagnostic provider comparison only; unchanged actual whole union remains authoritative", "providers": providers, "approach_forecasts_by_source": approach_forecasts, "approach_requests_by_source": approach_requests, "accepted_frames": accepted_frames, "actual_hero_points": game.call("player_camera_framing_points"), "actual_required_points": required, "actual_whole_plan": game.call("camera_framing_plan", required, desired), "native_camera_context": _full_native_camera_context(required), "actual_whole_containment_error": game.call("camera_framing_error", required), "component_plan": game.call("camera_framing_plan", level.call("_bounded_union", component), desired), "diagnostic_plans_excluding_one_component_provider": comparative}


func _full_native_camera_context(required: Array) -> Dictionary:
	# Diagnostic reads only. Never update/follow/fit the camera, HUD or world here.
	# The existing Hero+.65 comparison remains separate and unchanged above.
	var raw_camera: Variant = game.get("camera") if is_instance_valid(game) else null
	var raw_hud: Variant = game.get("hud") if is_instance_valid(game) else null
	var focus: Variant = game.get("_camera_focus") if is_instance_valid(game) else null
	if not is_instance_valid(raw_camera) or not raw_camera is Camera3D or not is_instance_valid(raw_hud) or not raw_hud is GameHUD or not focus is Vector3 or not focus.is_finite() or not is_instance_valid(hero): return {"available": false, "reason": "Actual native camera/HUD/follow focus/Player unavailable"}
	var native_camera: Camera3D = raw_camera
	var native_hud: GameHUD = raw_hud
	if not native_camera.is_inside_tree() or not native_hud.is_inside_tree(): return {"available": false, "reason": "Actual native camera/HUD must remain in their tree"}
	var viewport: Viewport = native_camera.get_viewport()
	var hud_viewport: Viewport = native_hud.get_viewport()
	var current_camera: Camera3D = viewport.get_camera_3d()
	var actual_world: World3D = native_camera.get_world_3d()
	var safe: Rect2 = native_hud.combat_safe_rect()
	var screen: Vector2 = hud_viewport.get_visible_rect().size
	var hero_focus: Vector3 = hero.global_position + Vector3.UP * 0.75
	return {"available": true, "camera_instance_id": native_camera.get_instance_id(), "global_position": native_camera.global_position, "global_basis_columns": [native_camera.global_basis.x, native_camera.global_basis.y, native_camera.global_basis.z], "width": native_camera.size, "viewport_instance_id": viewport.get_instance_id(), "viewport_size": Vector2(viewport.size), "current_camera_instance_id": current_camera.get_instance_id() if is_instance_valid(current_camera) else 0, "world_instance_id": actual_world.get_instance_id() if is_instance_valid(actual_world) else 0, "same_player_viewport": hero.get_viewport() == viewport, "same_player_world": hero.get_world_3d() == actual_world, "hud_instance_id": native_hud.get_instance_id(), "hud_viewport_instance_id": hud_viewport.get_instance_id(), "hud_visible_size": screen, "hud_safe_rect_normalized": [safe.position.x, safe.position.y, safe.size.x, safe.size.y], "hud_safe_rect_pixels": [safe.position.x * screen.x, safe.position.y * screen.y, safe.size.x * screen.x, safe.size.y * screen.y], "actual_follow_focus": focus, "hero_plus_075_focus": hero_focus, "whole_plan_at_actual_follow_focus": game.call("camera_framing_plan", required, focus), "whole_plan_at_hero_plus_075": game.call("camera_framing_plan", required, hero_focus)}


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > FullWallWatchdogMs:
		_require_unexpected(false, "actual five-room full-route fixture completes within its explicit finite fifteen-minute wall budget")
		_finish.call_deferred()


func _finish() -> void:
	if finishing: return
	_full_disconnect_observers()
	finishing = true
	paused = true
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(game):
		var effects: PixelEffects = game.get("fx") as PixelEffects
		if is_instance_valid(effects): effects.clear()
		var drain_until: int = Time.get_ticks_msec() + 500
		while Time.get_ticks_msec() < drain_until: await process_frame
		game.queue_free()
	paused = false
	await process_frame
	var path: String = capture_dir.path_join("evidence.json") if portrait else "res://.cinder/l3-normal-full-route-%d.json" % Time.get_ticks_usec()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		var report: Dictionary = {"scope": "actual one-world neutral/Standard five-room ordinary-only traversal attempt; assertions target19 real defeats/4CPs/1completion/physicalcontact; full native save remainsDENIED; no campaign transition/profile-kit/spent-all/human/performance or optical acceptance inference", "checks": checks, "failures": failures, "actual_swipes": swipes, "actual_primaries": primaries, "native_focus": DisplayServer.window_is_focused(), "normal_focus_out_preserved": true, "world_ids": full_world_ids, "observed_epochs": opening_epochs, "activation_counts": opening_activation_counts, "defeat_receipts": full_defeat_receipts, "room_receipts": full_room_receipts, "checkpoint_guards": full_checkpoint_guards, "completion_receipts": full_completion_receipts, "contact_receipts": full_contact_receipts, "complete_action_signal_trace": _portable(world_records), "accepted_input_signal_trace": _portable(input_observations), "validated_encoded_history": full_evidence_history, "primary_receipts": crowd_primary_receipts, "native_phase_barriers": full_phase_barriers, "response_timing_receipts": _portable(full_response_timing_receipts), "diagnostics": full_diagnostics, "worlds": worlds, "captures": shots}
		if portrait: report["floor_portrait_coverage"] = _portable(full_floor_coverage)
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	else:
		checks += 1; failures += 1; push_error("normal full-route evidence file could not open")
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L3 NORMAL FIVE-ROOM ROUTE ATTEMPT: %d checks, %d failures; %d real swipes, %d ordinary primaries; FULL SAVE DENIED / NO CAMPAIGN HANDOFF CLAIM" % [checks, failures, swipes, primaries])
	quit(1 if failures else 0)
