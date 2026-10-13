extends "res://tests/acts/act1/a1_l3_actor_pair.gd"
## Actual C31/C32 consumer component, ordinary primary field activation and
## complete paused environmental units. Full campaign/progression is excluded.

const SporeGrovePath: String = "res://scenes/acts/act1/a1_l3_spore_grove_component.tscn"
const SporeGuardPath: String = "res://scenes/acts/act1/a1_l3_spore_guard_component.tscn"
const ClusterPixels: Dictionary = {
	"available": preload("res://assets/acts/act1/grotto/spore-clusters/cluster_available.png"),
	"active": preload("res://assets/acts/act1/grotto/spore-clusters/cluster_active.png"),
	"spent": preload("res://assets/acts/act1/grotto/spore-clusters/cluster_spent.png"),
}
const NativeInteractionCue = preload("res://scripts/cues/interaction_cue.gd")
const ApproachSweep = preload("res://scripts/combat/body_sweep.gd")
const ApproachWatchdogMs: int = 120000 # Six fresh native worlds; default retains70s.
var component_units: Array[Dictionary] = []
var observed_spore_phases: Dictionary = {}
var recoil_pause_requested: bool = false
var callback_capture_rejected: bool = false
var observed_cluster_states: Dictionary = {}
var cluster_events: int = 0
var cluster_negatives_done: bool = false
var approach_boundary_cases: Array[Dictionary] = []
var approach_case: String = ""
var approach_actor: Act1MushroomSelenite
var approach_field: CinderSporeField
var approach_capsule: CapsuleShape3D
var approach_radius: float
var approach_field_transform: Transform3D
var approach_original_guard: Callable
var approach_calls: Array[Dictionary] = []
var approach_before: Dictionary = {}
var approach_after: Dictionary = {}
var approach_damage: Dictionary = {}
var approach_armed: bool = false
var approach_observed: bool = false
var approach_parent_attempts: int = 0


func _run() -> void:
	if "--approach-proof-boundaries" in OS.get_cmdline_user_args():
		await _run_approach_boundaries()
		return
	portrait = "--portrait" in OS.get_cmdline_user_args()
	root.size = PortraitSize
	if portrait:
		if not _require(DisplayServer.get_name() != "headless", "spore portrait requires the actual native renderer"):
			await _finish(); return
		capture_dir = "res://.cinder/captures/l3-spores-%d" % Time.get_ticks_usec()
		if not _require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir)) == OK, "native spore capture directory is writable"):
			await _finish(); return
	if not await _open_spore_world(SporeGrovePath, "grove", Vector3(0, 0.1, 15)):
		await _finish(); return
	_watch_pair_events()
	if not await _wait(func() -> bool: return level.get("spores_ready"), "actual living grounded C31 binds the published native protocol before a hittable mushroom exists"):
		await _finish(); return
	var field: CinderSporeField = level.get("spore_field")
	field.state_changed.connect(func(_state: Dictionary) -> void: cluster_events += 1)
	for cluster_id: String in ["cluster-left", "cluster-right"]:
		var cue: Node3D = _actual_cluster_cue(field.get_node(cluster_id) as Node3D)
		if not _require(cue != null, "each native low anchor retains its original interaction cue"):
			await _finish(); return
		cue.connect("state_changed", func(_state: Dictionary) -> void: cluster_events += 1)
	var consumer: CinderSporeRepulsion = level.get("spore_consumer")
	var actor: Act1MushroomSelenite = sources["umbrella-1"]
	consumer.reaction_started.connect(func(id: String, _episode: String) -> void:
		observed_spore_phases[id + "/recoil"] = true
		callback_capture_rejected = (level.call("component_unit_state") as Dictionary).is_empty()
		recoil_pause_requested = game.call("request_pause_deferred"))
	if not await _swipe(Vector3.FORWARD, "native spore cluster approach"):
		await _finish(); return
	# Observe the real native turn-to-approach boundary instead of assuming the
	# Hero dash finishes in the same source-facing tick on every camera setup.
	if not await _wait(func() -> bool: return actor.hp == 16.0 and actor.get_spore_response_state().phase == "none" and actor.velocity != Vector3.ZERO and actor.pure_presentation_state().approach_driving and actor.pure_presentation_state().reservation_id.is_empty(), "genuine native C31 finishes its gradual turn and begins its unleased approach"):
		await _finish(); return
	var actual_before: Dictionary = actor.get_spore_response_state()
	print("L3 SPORE APPROACH DIAGNOSTIC response=", actual_before, " native=", actor.pure_presentation_state(), " actor_error=", actor.last_error, " parent_approach=", level.get("last_approach_error"), " parent_encounter=", level.get("last_encounter_error"), " camera=", game.call("get_camera_framing_state"), " camera_error=", game.call("camera_framing_error", level.camera_framing_points()))
	if not _require(actor.hp == 16.0 and actual_before.velocity != Vector3.ZERO and actual_before.phase == "none" and actor.state().approach_driving and actor.state().reservation_id.is_empty(), "genuine unharmed C31 approaches before repulsion without a fake lease or hurt flag"):
		await _finish(); return
	if not await _pause_pair("bound approaching native source") or not _quiet_component("bound approaching native source") or not await _capture("bound-approach") or not await _gui_resume_pair():
		await _finish(); return
	var hp_before: Dictionary = {}
	for id: String in level.call("current_source_ids"): hp_before[id] = sources[id].hp
	if not await _cluster_primary(field.get_node("cluster-right") as Node3D, "first finite spore release", true):
		await _finish(); return
	if not _require(field.state().generation == 1 and field.state().spent_ids == ["cluster-right"] and consumer.placement_accepted(), "real ordinary primary spends one actual cluster and preserves accepted native custody"):
		await _finish(); return
	if not _require(paused and recoil_pause_requested and callback_capture_rejected and observed_spore_phases.has("umbrella-1/recoil") and actor.get_spore_response_state().phase == "recoil", "actual reaction callback rejects capture and public deferred pause preserves genuine living recoil"):
		await _finish(); return
	if not _quiet_component("native recoil") or not _spore_framing("native recoil field/source/retreat") or not await _capture("recoil") or not await _gui_resume_pair():
		await _finish(); return
	# Coordinator publishes turn -> retreat after that tick's Route advance;
	# the first retreat stamp can truthfully still have zero velocity. Observe
	# actual moving retreat before applying the unchanged motion assertions.
	if not await _wait(func() -> bool:
		var response: Dictionary = actor.get_spore_response_state()
		return response.phase == "retreat" and response.velocity != Vector3.ZERO, "actual shared Route advances a living C31 away from the field"):
		await _finish(); return
	var retreat: Dictionary = actor.get_spore_response_state()
	print("L3 SPORE MOVING RETREAT DIAGNOSTIC response=", retreat, " native=", actor.pure_presentation_state(), " route=", consumer.source_state("umbrella-1"))
	if not _require(retreat.velocity != Vector3.ZERO and not actor.state().approach_driving and actor.state().reservation_id.is_empty() and actor.hp == hp_before["umbrella-1"], "actual Route owns retreat velocity while native approach/attack remain suppressed and HP unchanged"):
		await _finish(); return
	if not await _pause_pair("native moving retreat") or not _quiet_component("native moving retreat") or not await _capture("retreat") or not await _gui_resume_pair():
		await _finish(); return
	if not await _wait(func() -> bool: return actor.get_spore_response_state().phase == "hold", "living source reaches and holds its actual outside-union endpoint"):
		await _finish(); return
	var stopped: Vector3 = actor.global_position
	if not _require(_planar_distance(stopped, field.global_position) > 1.5 + float(actor.get_spore_response_state().support_radius) and actor.velocity == Vector3.ZERO, "native endpoint is outside the active field with its measured capsule support"):
		await _finish(); return
	if not await _pause_pair("native held field") or not _quiet_component("native held field") or not await _capture("hold") or not await _gui_resume_pair():
		await _finish(); return
	if not await _wait(func() -> bool: return actor.get_spore_response_state().phase == "regroup", "living source visibly regroups as the actual finite field fades"):
		await _finish(); return
	if not await _pause_pair("native regroup") or not _quiet_component("native regroup") or not await _capture("regroup") or not await _gui_resume_pair():
		await _finish(); return
	if not await _wait(func() -> bool: return actor.get_spore_response_state().phase == "none", "original native source finishes its real episode without re-granting mushroom supply"):
		await _finish(); return
	for id: String in hp_before:
		if not _require(sources[id].hp == hp_before[id] and not sources[id].dead, id + " remains alive at its original HP through the harmless environmental episode"):
			await _finish(); return
	_require(hero.hp == initial_hp and hit_events.is_empty() and field.state().generation == 1 and field.state().spent_ids == ["cluster-right"] and not level.is_completed(), "harmless component preserves Player HP and finite supply without granting campaign completion")
	_require(cluster_negatives_done and observed_cluster_states.has("available") and observed_cluster_states.has("active") and observed_cluster_states.has("spent"), "original ordinary episode observes all three honest cluster drawings and bounded binding negatives")
	await _finish()


func _run_approach_boundaries() -> void:
	# All stimuli occur inside the genuine actor physics transaction, after its
	# original actual parent has approved the complete native proposal. Each
	# case starts a fresh real world and performs one unchanged recognizer dash.
	root.size = PortraitSize
	for kind: String in ["success-damage-refused", "first-denied-braking", "braking-denied", "empty-pause", "empty-body-mutation", "empty-field-mutation"]:
		approach_case = kind; approach_armed = false; approach_observed = false
		if not await _open_spore_world(SporeGrovePath, "grove", Vector3(0, 0.1, 15)):
			await _finish(); return
		_watch_pair_events()
		if not await _wait(func() -> bool: return level.get("spores_ready"), "approach case installs the real native field/protocol/consumer") or not await _swipe(Vector3.FORWARD, "approach boundary " + kind):
			await _finish(); return
		approach_actor = sources["umbrella-1"]
		approach_field = level.get("spore_field")
		if not await _wait(func() -> bool:
			var state: Dictionary = approach_actor.pure_presentation_state()
			return state.approach_driving and state.velocity != Vector3.ZERO and state.reservation_id.is_empty() and state.hp == 16.0 and approach_actor.get_spore_response_state().phase == "none", "real already-driving unleased C31 is ready for " + kind):
			await _finish(); return
		approach_original_guard = approach_actor.approach_guard
		approach_capsule = approach_actor.get_node("BodyCollision").shape as CapsuleShape3D
		if not _require(approach_original_guard.is_valid() and approach_original_guard.get_object() == level and approach_capsule != null and approach_field != null and (level.get("spore_consumer") as CinderSporeRepulsion).placement_accepted(), "case retains its original parent guard and actual body/field/native custody"):
			await _finish(); return
		approach_radius = approach_capsule.radius
		approach_field_transform = approach_field.transform
		approach_case = kind
		approach_calls.clear(); approach_before.clear(); approach_after.clear(); approach_damage.clear()
		approach_armed = false; approach_observed = false; approach_parent_attempts = 0
		approach_actor.approach_guard = Callable(self, "_approach_guard_boundary")
		if not await _wait(func() -> bool: return approach_observed, "one real native approach transaction closes for " + kind, 8.0, true):
			_restore_approach_objects(); await _finish(); return
		# Restore only the original mutated resource fields, after observing the
		# genuine refusal. Never repair a source pose, velocity, clock or floor flag.
		_restore_approach_objects()
		if not _check_approach_boundary(kind): await _finish(); return
		var unit: Dictionary = level.call("component_unit_state")
		if not _require(not unit.is_empty() and String(level.call("component_unit_error", unit)).is_empty(), "original actual resources recover complete paused native custody after " + kind):
			await _finish(); return
		component_units.append({"label": "approach boundary " + kind, "unit": unit.duplicate(true)})
		approach_boundary_cases.append({"case": kind, "parent_attempts": approach_parent_attempts, "calls": _portable(approach_calls), "before": _portable(approach_before), "after": _portable(approach_after), "ordinary_damage_attempt": _portable(approach_damage), "scope": "One genuine native source physics transaction after one full recognizer swipe; no manually invoked step, spore release, injury, lease or clock setup"})
		if not await _close_approach_world(): await _finish(); return
	await _finish()


func _approach_guard_boundary(plan: Dictionary) -> String:
	# The original observer remains the actual body/art/floor/neighbor/camera
	# authority. A nonempty answer is returned unchanged, without injecting a case.
	var answer: Variant = approach_original_guard.call(plan.duplicate(true))
	approach_parent_attempts += 1
	if not answer is String: return "Original actual approach parent did not return a String"
	if not approach_armed:
		if not String(answer).is_empty() or plan.get("reason") == "disabled_braking" or plan.get("next_position") == approach_actor.global_position: return String(answer)
		approach_armed = true
		approach_before = _approach_live_boundary()
		_approach_tick_closed.call_deferred()
	approach_calls.append({"plan": plan.duplicate(true), "original_parent_answer": answer})
	if not String(answer).is_empty(): return String(answer)
	if approach_calls.size() == 1:
		match approach_case:
			"success-damage-refused":
				approach_damage = approach_actor.take_damage(1.0, Vector3.ZERO)
			"first-denied-braking", "braking-denied":
				return "TEST original drive approval is declined by its observer"
			"empty-pause":
				game.call("open_bench") # Supported direct pause; not deferred damage.
			"empty-body-mutation":
				approach_capsule.radius = approach_radius + 0.01
			"empty-field-mutation":
				approach_field.position += Vector3(0.01, 0, 0)
	elif approach_case == "braking-denied":
		return "TEST original braking approval is declined by its observer"
	return ""


func _approach_live_boundary() -> Dictionary:
	return {"transform": approach_actor.global_transform, "position": approach_actor.global_position, "velocity": approach_actor.velocity, "native": approach_actor.pure_presentation_state(), "last_error": approach_actor.last_error, "hero_transform": hero.global_transform, "hero_hp": hero.hp, "hero_records": hero.get_world_action_records().duplicate(true), "clock_s": scheduler.get_clock(), "control": scheduler.source_control_state(approach_actor), "field": approach_field.state(), "field_transform": approach_field.transform, "capsule_radius": approach_capsule.radius, "pair_events": pair_events, "paused": paused}


func _approach_tick_closed() -> void:
	if finishing or approach_observed or not is_instance_valid(approach_actor): return
	# Native physics has returned. Freeze through the existing public UI after
	# reading the actual result; callbacks never manufacture a completed step.
	approach_after = _approach_live_boundary()
	if not paused: game.call("open_bench")
	approach_observed = true


func _restore_approach_objects() -> void:
	if approach_armed and approach_case == "empty-body-mutation" and is_instance_valid(approach_capsule) and approach_capsule.radius != approach_radius: approach_capsule.radius = approach_radius
	if approach_armed and approach_case == "empty-field-mutation" and is_instance_valid(approach_field) and approach_field.transform != approach_field_transform: approach_field.transform = approach_field_transform
	if is_instance_valid(approach_actor) and approach_original_guard.is_valid(): approach_actor.approach_guard = approach_original_guard


func _check_approach_boundary(kind: String) -> bool:
	if not _require(approach_armed and not approach_calls.is_empty() and approach_calls[0].original_parent_answer == "" and approach_before.native.approach_driving and approach_before.velocity != Vector3.ZERO and approach_before.native.reservation_id == "", kind + " begins at the actual approved already-driving native boundary"): return false
	if not _require(approach_after.clock_s == approach_before.clock_s and approach_after.hero_transform == approach_before.hero_transform and approach_after.hero_hp == approach_before.hero_hp and approach_after.hero_records == approach_before.hero_records and approach_after.native.hp == approach_before.native.hp and approach_after.native.hurt_left_s == approach_before.native.hurt_left_s and approach_after.native.reservation_id == "", kind + " preserves same-tick native clock/Player/actions/HP and creates no lease or fake injury"): return false
	if kind in ["success-damage-refused", "first-denied-braking"]:
		var index: int = 1 if kind == "first-denied-braking" else 0
		if not _require(approach_calls.size() == index + 1 and approach_after.last_error == "", kind + " executes only its actual approved native motion"): return false
		var plan: Dictionary = approach_calls[index].plan
		var actual: Vector3 = approach_after.transform.origin
		if not _require(approach_after.transform != approach_before.transform and actual.distance_to(plan.next_position) <= ApproachSweep.position_rounding_bound(actual, plan.next_position) and approach_actor.body_binding_error().is_empty() and approach_actor.art_binding_error().is_empty(), kind + " performs real supported body motion matching the native proposal"): return false
		if kind == "success-damage-refused":
			return _require(approach_damage.get("accepted") == false and approach_damage.get("hp_damage") == 0.0 and approach_after.pair_events == approach_before.pair_events, "ordinary approach-transaction damage remains rejected, without injury or gameplay callbacks")
		return _require(plan.reason == "disabled_braking" and approach_calls[1].original_parent_answer == "" and approach_after.velocity.length() < approach_before.velocity.length(), "first-provider rejection uses a second actual parent-approved finite braking plan")
	if not _require(not String(approach_after.last_error).is_empty() and approach_after.transform == approach_before.transform and approach_after.velocity == approach_before.velocity and approach_after.native.facing == approach_before.native.facing and approach_after.native.approach_driving == approach_before.native.approach_driving, kind + " refuses before source motion without fabricating a stop"): return false
	match kind:
		"braking-denied":
			return _require(approach_calls.size() == 2 and approach_calls[1].plan.reason == "disabled_braking" and approach_calls[1].original_parent_answer == "", "rejected second observer leaves actual braking velocity/pose untouched and reports an error")
		"empty-pause":
			return _require(approach_calls.size() == 1 and approach_after.paused, "empty-return observer public pause is respected by immediate post-provider proof")
		"empty-body-mutation":
			return _require(approach_calls.size() == 1 and approach_after.capsule_radius != approach_before.capsule_radius, "empty-return actual capsule mutation is detected before motion")
		"empty-field-mutation":
			return _require(approach_calls.size() == 1 and approach_after.field_transform != approach_before.field_transform, "empty-return actual field mutation is detected before motion")
	return false


func _close_approach_world() -> bool:
	# Same public exit/effects/paused AudioServer drain as component cleanup;
	# this approach-only scope does not require a combat preparation or defeat.
	paused = true
	var refs: Array[WeakRef] = []
	refs.append(weakref(game)); refs.append(weakref(level)); refs.append(weakref(hero)); refs.append(weakref(scheduler))
	for source: Node in sources.values(): refs.append(weakref(source))
	level.exit_level()
	if not _require(not scheduler.is_physics_processing() and scheduler.reservations().is_empty(), "approach case normal exit retires its real Scheduler without a lease"): return false
	var effects: PixelEffects = game.get("fx") as PixelEffects
	if is_instance_valid(effects): effects.clear()
	await create_timer(0.5, true).timeout
	game.free()
	sources.clear(); game = null; level = null; hero = null; scheduler = null
	approach_actor = null; approach_field = null; approach_capsule = null; approach_original_guard = Callable()
	paused = false
	await process_frame
	var removed: bool = true
	for ref: WeakRef in refs: removed = removed and ref.get_ref() == null
	return _require(removed and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("environment_attack_targets").is_empty(), "fresh approach case cleanup frees real nodes and native groups")


func _watchdog() -> void:
	if "--approach-proof-boundaries" not in OS.get_cmdline_user_args():
		super._watchdog()
		return
	if not finishing and Time.get_ticks_msec() - started_ms > ApproachWatchdogMs:
		_require_unexpected(false, "six fresh approach boundary cases complete within120 seconds; native deadlines unchanged")
		_finish.call_deferred()


func _open_spore_world(path: String, scope: String, spawn: Vector3) -> bool:
	await process_frame
	current_scope = scope
	sources.clear(); admissions.clear(); phase_observations.clear()
	world_records.clear(); input_observations.clear(); hit_events.clear()
	events = 0; max_preparing = 0; preparing_violation = false
	game = MainScene.instantiate()
	game.set("level_scene_path", path)
	root.add_child(game)
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	scheduler = level.get("scheduler") as CinderThreatScheduler if level != null else null
	if not _require(level != null and hero != null and scheduler != null and level.contract_error().is_empty() and level.hero == hero and hero.global_position == spawn, scope + " isolated actual role enters through one shared Hero at its authored spawn"): return false
	sources = (level.get("sources") as Dictionary).duplicate()
	initial_hp = hero.hp
	var current_ids: Array = level.call("current_source_ids")
	if not _require(sources.size() == 4 and current_ids == (["umbrella-1"] if scope == "grove" else ["lone-guard"]), scope + " isolated spore witness retains all four sources but activates exactly its one actual role"): return false
	for id: String in sources:
		var actor: CharacterBody3D = sources[id]
		var state: Dictionary = actor.call("state")
		if not _require(state.source_id == id and state.dormant == (id not in current_ids) and not state.dead and state.hp == (24.0 if id == "lone-guard" else 16.0), id + " retains genuine role HP and actual isolated dormancy"): return false
		actor.connect("state_changed", Callable(self, "_notice_phase").bind(id))
		actor.connect("hit_resolved", Callable(self, "_notice_hit").bind(id))
	level.connect("native_admission_published", _notice_admission)
	hero.world_action_executed.connect(func(record: Dictionary) -> void: world_records.append(record.duplicate(true)); events += 1)
	game.connect("input_observed", func(observation: Dictionary) -> void: input_observations.append(observation.duplicate(true)))
	game.call("resume_lab")
	return _require(not paused, "isolated spore component uses one initial public resume and unchanged focus handling")


func _cluster_primary(cluster: Node3D, label: String, expect_pause: bool = false) -> bool:
	if not await _ready_input(label): return false
	while Time.get_ticks_msec() - last_primary_ms <= 300:
		if not _guard_input(): return false
		await process_frame
	var offset: Vector3 = cluster.global_position - hero.global_position
	offset.y = 0.0
	var direction: Vector3 = offset.normalized()
	var anchor: Vector2 = game.call("get_aim_anchor")
	var tap: Vector2 = anchor + _screen_delta(direction) * 160.0
	if not _require(cluster.is_in_group("environment_attack_targets") and offset.length() <= float(hero.equipment.resolved_stats().primary_range) and _input_safe(tap) and (game.call("aim_direction", tap) as Vector3).dot(direction) > 0.9999, label + " reaches the actual low attackable anchor with ordinary exact aim"):
		return false
	var sequence: int = _last_sequence()
	var press := InputEventScreenTouch.new()
	press.index = 7; press.pressed = true; press.position = tap
	Input.parse_input_event(press)
	await process_frame
	if not _guard_input(): return false
	var release := InputEventScreenTouch.new()
	release.index = 7; release.position = tap
	hero.shells = 0 # Release-only no-blast setup; normal passive reload remains.
	Input.parse_input_event(release)
	await process_frame
	if expect_pause:
		if not await _wait(func() -> bool: return paused, label + " reaches the requested public cancellation/reaction pause", 2.0, true): return false
	elif not _guard_input(): return false
	last_primary_ms = Time.get_ticks_msec()
	primaries += 1
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	return _require(records.size() == 1 and records[0].kind == "primary" and records[0].hits == 0 and records[0].direction.dot(direction) > 0.9999 and game.call("get_input_observation_state").last_observation.kind == "primary_tap" and game.call("get_aim_anchor") == anchor, label + " is one real immediate first-tap primary with no enemy hit/kill credit or blast")


func _quiet_component(label: String) -> bool:
	var unit: Dictionary = level.call("component_unit_state")
	if not _require(not unit.is_empty() and String(level.call("component_unit_error", unit)).is_empty(), label + " captures separately validated whole Player/all four actors/Scheduler/field/native coordinator units: " + String(level.get("last_component_error"))): return false
	var wire: String = Exact.stringify(unit)
	var decoded: Dictionary = Exact.parse(wire)
	var count: int = pair_events
	var cue_count: int = cluster_events
	if not _require(decoded.get("accepted", false) and Exact.stringify(decoded.value) == wire and level.call("restore_component_unit", decoded.value), label + " quiet complete native commit follows physical -> Scheduler -> exchange -> Route order"): return false
	if not _require(Exact.stringify(level.call("component_unit_state")) == wire and pair_events == count and cluster_events == cue_count, label + " exact quiet roundtrip preserves every original resource/clock/pose/supply without callbacks"): return false
	component_units.append({"label": label, "unit": unit.duplicate(true)})
	var id: String = level.call("current_source_ids")[0]
	var malformed: Array[Dictionary] = []
	var wrong: Dictionary = unit.duplicate(true)
	wrong.actors[id].repulsion.consumer_id += "-foreign"
	malformed.append(wrong)
	wrong = unit.duplicate(true)
	wrong.actors[id].repulsion.progress = 1
	malformed.append(wrong)
	wrong = unit.duplicate(true)
	wrong.actors[id].repulsion.direction = [0.0, 0.0, 0.0]
	malformed.append(wrong)
	wrong = unit.duplicate(true)
	wrong.actors[id].api_revision = "act1-mushroom-selenite-2"
	malformed.append(wrong)
	wrong = unit.duplicate(true)
	wrong.fields["component-mushroom"].clock_s += 0.000001
	malformed.append(wrong)
	wrong = unit.duplicate(true)
	wrong.coordinator.source_protocols[id].actor_sha256 = "forged"
	malformed.append(wrong)
	for candidate: Dictionary in malformed:
		if not _require(not String(level.call("component_unit_error", candidate)).is_empty() and not level.call("restore_component_unit", candidate) and Exact.stringify(level.call("component_unit_state")) == wire and pair_events == count, label + " rejects malformed native stamp/old API/clock/custody atomically"): return false
	var actor: Act1MushroomSelenite = sources[id]
	var phase: String = actor.get_spore_response_state().phase
	var pose: String = "standing"
	match phase:
		"recoil", "turn": pose = "recoil"
		"retreat": pose = "retreat"
		"hold", "regroup": pose = "regroup"
		"none":
			var native_phase: String = actor.pure_presentation_state().phase
			pose = "standing" if native_phase in ["clear", "idle"] else native_phase
	if not _require(actor.art_binding_error().is_empty() and actor.get_art().call("pose_name") == pose, label + " selects its actual native/environmental costume pose without a second clock"): return false
	if phase in ["recoil", "turn", "retreat", "hold", "regroup"]:
		var sprite: Sprite3D = actor.get_art().call("sprite")
		var original_texture: Texture2D = sprite.texture
		var art_script = preload("res://scripts/acts/act1/mushroom_selenite_art.gd")
		sprite.texture = art_script.TEXTURES[actor.pure_presentation_state().role_id].front.standing
		var rejected: bool = not actor.art_binding_error().is_empty() and (level.call("component_unit_state") as Dictionary).is_empty() and pair_events == count
		sprite.texture = original_texture
		if not _require(rejected and actor.art_binding_error().is_empty() and Exact.stringify(level.call("component_unit_state")) == wire and pair_events == count, label + " rejects a wrong known native pose then restores the exact real unit without gameplay events"): return false
	return _cluster_art_barrier(label, unit, wire, count, cue_count)


func _actual_cluster_cue(cluster: Node3D) -> Node3D:
	for child: Node in cluster.get_children():
		if child.get_script() == NativeInteractionCue: return child as Node3D
	return null


func _cluster_art_barrier(label: String, unit: Dictionary, wire: String, count: int, cue_count: int) -> bool:
	var field: CinderSporeField = level.get("spore_field")
	var points: Array = level.camera_framing_points()
	if not _require(paused and not points.is_empty() and points.size() <= 224 and level.last_camera_framing_error.is_empty(), label + " retains bounded complete actual presentation corners at the native quiet barrier"): return false
	for id: String in ["cluster-left", "cluster-right"]:
		var cluster := field.get_node(id) as Node3D
		var art := cluster.get_node_or_null("AuthoredLowCluster") as Node3D
		var cue: Node3D = _actual_cluster_cue(cluster)
		if not _require(art != null and cue != null and String(art.call("binding_error")).is_empty() and cluster.is_in_group("environment_attack_targets") and cue.is_in_group("required_cues"), label + " " + id + " preserves its actual native anchor/cue and retained art"): return false
		var state: Dictionary = cluster.call("get_cue_state")
		var sprite: Sprite3D = art.call("sprite")
		if not _require(ClusterPixels.has(state.state) and sprite.texture == ClusterPixels[state.state], label + " " + id + " selects original pixels from its honest native " + String(state.state) + " state"): return false
		observed_cluster_states[String(state.state)] = true
		# Independent actual renderer bounds; never ask the leaf for its result.
		var quad: Array = game.call("camera_billboard_points", sprite)
		var marker := cue.get_node("RequiredInteractionMarker") as MeshInstance3D
		var marker_bounds: AABB = marker.get_aabb()
		var corners: Array = quad.duplicate()
		for x: float in [marker_bounds.position.x, marker_bounds.end.x]:
			for y: float in [marker_bounds.position.y, marker_bounds.end.y]:
				for z: float in [marker_bounds.position.z, marker_bounds.end.z]: corners.append(marker.global_transform * Vector3(x, y, z))
		var complete: bool = not quad.is_empty()
		for point: Vector3 in corners: complete = complete and point.is_finite() and points.has(point)
		if not _require(complete, label + " " + id + " includes the whole real billboard and native cue extrema beyond the former cluster proxy"): return false
	if not cluster_negatives_done:
		if not _cluster_binding_negatives(label, unit, wire, count, cue_count): return false
		cluster_negatives_done = true
	return true


func _rejected_component_binding(unit: Dictionary, require_bad_frame: bool) -> bool:
	# Each public operation must reject before any field/Player/actor/clock write.
	var error: String = level.call("component_unit_error", unit)
	var capture: Dictionary = level.call("component_unit_state")
	var restored: bool = level.call("restore_component_unit", unit)
	var frame_rejected: bool = true
	if require_bad_frame:
		frame_rejected = level.camera_framing_points().is_empty() and not level.last_camera_framing_error.is_empty()
	return not error.is_empty() and capture.is_empty() and not restored and frame_rejected


func _binding_restored(rejected: bool, label: String, wire: String, count: int, cue_count: int, records: PackedByteArray) -> bool:
	return _require(rejected and Exact.stringify(level.call("component_unit_state")) == wire and pair_events == count and cluster_events == cue_count and var_to_bytes(hero.get_world_action_records()) == records, label + " rejects before mutation then restores the same resources, whole native unit, clocks, HP, supply and action records")


func _cluster_binding_negatives(label: String, unit: Dictionary, wire: String, count: int, cue_count: int) -> bool:
	var cluster := (level.get("spore_field") as Node3D).get_node("cluster-right") as Node3D
	var art := cluster.get_node("AuthoredLowCluster") as Node3D
	var sprite: Sprite3D = art.call("sprite")
	var records: PackedByteArray = var_to_bytes(hero.get_world_action_records())
	var original_texture: Texture2D = sprite.texture
	sprite.texture = ClusterPixels.spent if original_texture != ClusterPixels.spent else ClusterPixels.available
	var rejected: bool = _rejected_component_binding(unit, true)
	sprite.texture = original_texture
	if not _binding_restored(rejected, label + " wrong known cluster texture", wire, count, cue_count, records): return false
	var original_offset: Vector2 = sprite.offset
	sprite.offset = original_offset + Vector2(1, 0)
	rejected = _rejected_component_binding(unit, true)
	sprite.offset = original_offset
	if not _binding_restored(rejected, label + " altered cluster feet pivot", wire, count, cue_count, records): return false
	cluster.remove_child(art)
	rejected = _rejected_component_binding(unit, true)
	cluster.add_child(art) # Same retained leaf; no replacement or native mutation.
	if not _binding_restored(rejected, label + " detached retained cluster art", wire, count, cue_count, records): return false
	var cue: Node3D = _actual_cluster_cue(cluster)
	cue.remove_from_group("required_cues")
	rejected = _rejected_component_binding(unit, true)
	cue.add_to_group("required_cues")
	if not _binding_restored(rejected, label + " removed native cue membership", wire, count, cue_count, records): return false
	var actor: Act1MushroomSelenite = sources[level.call("current_source_ids")[0]]
	var guard: Callable = actor.spore_route_guard
	actor.spore_route_guard = Callable()
	rejected = _rejected_component_binding(unit, false)
	actor.spore_route_guard = guard
	if not _binding_restored(rejected, label + " removed mandatory source route guard", wire, count, cue_count, records): return false
	actor.spore_route_guard = Callable(self, "_foreign_route_guard")
	rejected = _rejected_component_binding(unit, false)
	actor.spore_route_guard = guard
	return _binding_restored(rejected, label + " substituted valid foreign source route guard", wire, count, cue_count, records)


func _foreign_route_guard(_proposal: Dictionary) -> String:
	return "" # Not invoked: pure boundary checks must reject its changed identity.


func _spore_framing(label: String) -> bool:
	var points: Array = level.camera_framing_points()
	var actual_error: String = game.call("camera_framing_error", points)
	if not actual_error.is_empty() or not level.last_camera_framing_error.is_empty():
		print("L3 SPORE FRAMING DIAGNOSTIC ", label, " points=", points.size(), " level_error=", level.last_camera_framing_error, " actual_error=", actual_error, " planned=", game.call("get_camera_framing_state"), " source=", sources["umbrella-1"].get_spore_response_state(), " route=", level.get("spore_consumer").source_state("umbrella-1"))
	return _framing(label)


func _capture(stage: String) -> bool:
	if not portrait: return not aborted and not finishing
	# Presentation-only evidence: keep the actual simulation barrier, HUD status
	# and camera intact while removing the modal that otherwise hides the poses.
	var unit: Dictionary = level.call("component_unit_state")
	var hud: GameHUD = game.get("hud") as GameHUD
	if not _require(paused and not unit.is_empty() and is_instance_valid(hud) and _resume_button(hud) != null, stage + " actual public Pause is ready before unobstructed paused capture"): return false
	var wire: String = Exact.stringify(unit)
	var count: int = pair_events
	hud.hide_overlay()
	var accepted: bool = await super._capture(stage)
	hud.show_pause()
	if not accepted: return false
	shots.back()["capture_overlay"] = "public HUD overlay hidden only for paused renderer; restored before GUI Resume"
	return _require(paused and Exact.stringify(level.call("component_unit_state")) == wire and pair_events == count and _resume_button(hud) != null, stage + " renderer changes no complete native unit/clock/event and restores the public Pause menu")


func _finish() -> void:
	if finishing: return
	if "--approach-proof-boundaries" in OS.get_cmdline_user_args(): _restore_approach_objects()
	finishing = true
	paused = true
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(game):
		var effects: PixelEffects = game.get("fx") as PixelEffects
		if is_instance_valid(effects): effects.clear()
	await create_timer(0.5, true).timeout
	if is_instance_valid(game): game.free()
	paused = false
	await process_frame
	_require(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("environment_attack_targets").is_empty(), "complete component teardown removes actual enemy and environmental attack groups")
	var evidence_path: String = capture_dir.path_join("evidence.json") if portrait else "res://.cinder/l3-spore-state-%d.json" % Time.get_ticks_usec()
	var evidence: FileAccess = FileAccess.open(evidence_path, FileAccess.WRITE)
	if evidence != null:
		evidence.store_string(JSON.stringify({"checks": checks, "failures": failures, "swipes": swipes, "primaries": primaries, "shots": shots, "units": component_units, "fixture_mode": "approach-proof-boundaries" if "--approach-proof-boundaries" in OS.get_cmdline_user_args() else "native-spore-component", "approach_cases": approach_boundary_cases, "approach_current": {"case": approach_case, "armed": approach_armed, "observed": approach_observed, "parent_attempts": approach_parent_attempts, "calls": _portable(approach_calls), "before": _portable(approach_before), "after": _portable(approach_after), "ordinary_damage_attempt": _portable(approach_damage)}}, "\t"))
		print("L3 SPORE STATE EVIDENCE ", ProjectSettings.globalize_path(evidence_path))
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L3 NATIVE SPORE COMPONENT: %d checks, %d failures; %d real swipes/%d ordinary primaries; full campaign/guard/callback injury/fresh-recipient tests pending" % [checks, failures, swipes, primaries])
	quit(1 if failures else 0)
