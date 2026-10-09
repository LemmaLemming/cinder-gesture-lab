extends CinderLevel
## Friendly launch rehearsal. Shared actors, lane scheduler, cues and saves own
## simulation; this level supplies finite floor candidates and authored art.

const TargetScript: GDScript = preload("res://scripts/acts/act1/rehearsal_target.gd")
const SceneryScript: GDScript = preload("res://scripts/acts/act1/launch_scenery.gd")
const ArmVisualScript: GDScript = preload("res://scripts/acts/act1/loading_arm_visual.gd")
const Geometry: GDScript = preload("res://scripts/combat/threat_geometry.gd")
const Codec: GDScript = preload("res://scripts/campaign/snapshot_codec.gd")
const EXERCISES: Array[String] = ["first-dash", "release-point", "workshop-approach", "loading-arm", "boarding-rehearsal"]
const TARGET_IDS: Array[String] = ["hall", "workshop", "roof", "finale"]
# Keep arm targets beside useful landings so standing cloth does not hide the
# shared player's body. These same centres define actual primary/proof reach.
const TARGET_POSITIONS: Array[Vector3] = [Vector3(1, 0, 8.8), Vector3(0, 0, 0), Vector3(3.6, 0, -3.6), Vector3(3.6, 0, -9.6)]
const ARM_IDS: Array[String] = ["a1_l1_roof_arm", "a1_l1_boarding_arm"]
const ARM_ORIGINS: Array[Vector3] = [Vector3(0, 0, -7.6), Vector3(0, 0, -13.6)]
const ARM_ENDS: Array[Vector3] = [Vector3(0, 0, -4.4), Vector3(0, 0, -10.4)]
const ENCOUNTER_IDS: Array[String] = ["a1_l1_roof", "a1_l1_boarding"]
const COMPLETION_ID: String = "launch-rehearsal-clear"
const EXIT_ID: String = "capsule-hatch"
const OBJECTIVES: Array[String] = [
	"SWIPE UP TO THE BROAD FLOOR MARKER\nRELEASE UPPER-LEFT",
	"RELEASE UPPER-LEFT · TAP NEAR CENTRE\nTHE SLASH POINTS DOWN-RIGHT",
	"WORKSHOP · SWIPE TO A USEFUL POSITION\nAIM FROM THAT RELEASE · SECOND TAP: OPTIONAL BLAST",
	"ROOF · SWIPE BESIDE THE LOADING ARM\nWATCH THE LANE · STRIKE THE CLOTH",
	"ALL ABOARD · READ THE FAMILIAR LANE\nLAND BESIDE IT · STRIKE THE CLOTH",
	"REHEARSAL CLEAR · THE HATCH IS OPEN\nSWIPE TO THE CAPSULE TO BOARD",
]

var beat_index: int = 0
var targets: Dictionary = {}
var completed_exercises: Array[String] = []
var scenery: Node3D
var scheduler: CinderThreatScheduler
var arms: Dictionary = {}
var arm_visuals: Dictionary = {}
var hatch: Area3D
var hatch_cue: CinderInteractionCue
var _advancing: bool = false
var _pending_target_check: bool = false


func _ready() -> void:
	# Read complete hero/scheduler/lane ticks. Art does not accumulate a clock.
	process_physics_priority = 200
	scenery = SceneryScript.new()
	scenery.build(self)
	for index: int in TARGET_IDS.size():
		var target: PracticeTarget = TargetScript.new() as PracticeTarget
		target.name = TARGET_IDS[index].capitalize() + "Target"
		target.position = TARGET_POSITIONS[index]
		target.configure(1.0, 1.0, 0.0, false)
		add_child(target)
		targets[TARGET_IDS[index]] = target
	scheduler = CinderThreatScheduler.new()
	scheduler.name = "RehearsalThreatScheduler"
	add_child(scheduler)
	for index: int in ARM_IDS.size():
		var arm := CinderLaneMechanism.new()
		arm.name = "RoofLoadingArm" if index == 0 else "BoardingLoadingArm"
		arm.position = ARM_ORIGINS[index]
		arm.configure(ARM_IDS[index], Geometry.lane(ARM_ORIGINS[index], ARM_ENDS[index], 0.6), TARGET_POSITIONS[index + 2])
		add_child(arm)
		arms[ARM_IDS[index]] = arm
		var visual: Node3D = ArmVisualScript.new() as Node3D
		visual.call("build", arm, Vector3.ZERO)
		arm_visuals[ARM_IDS[index]] = visual
	_build_hatch_contact()
	_apply_beat()


func _build_hatch_contact() -> void:
	hatch = Area3D.new()
	hatch.name = "CapsuleHatchContact"
	hatch.position = Vector3(0, 0.8, -13.7)
	hatch.collision_layer = 0
	hatch.collision_mask = 4
	var shape := CollisionShape3D.new()
	shape.name = "BroadBoardingContact"
	var box := BoxShape3D.new()
	box.size = Vector3(2.8, 1.6, 1.6)
	shape.shape = box
	hatch.add_child(shape)
	add_child(hatch)
	hatch.body_entered.connect(_on_hatch_contact)
	hatch_cue = CinderInteractionCue.new()
	hatch_cue.name = "HatchContactCue"
	hatch_cue.position = Vector3(0, 0, -12.8)
	add_child(hatch_cue)


func dash_marker_position() -> Vector3:
	return ($DashMarker as Marker3D).global_position


func scheduler_bindings() -> Dictionary:
	return {"world_root": self, "owners": arms.duplicate(), "floors": {"launch_floor": {"collision": get_node_or_null("Floor/CollisionShape3D"), "safe_rect": Rect2(-6, -16, 12, 30)}}}


func arm_response_context() -> Dictionary:
	if beat_index not in [3, 4]:
		return {}
	var directions: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			directions.append(Vector3(x, 0, z).normalized())
	# Extra authored diagonals keep a useful ordinary-primary landing at the
	# close camera scale for both baseline and longest legal static dashes.
	for x: float in [-0.6, 0.6, -0.8, 0.8]:
		var z: float = sqrt(1.0 - x * x)
		directions.append(Vector3(x, 0, z))
		directions.append(Vector3(x, 0, -z))
	return {"encounter_id": ENCOUNTER_IDS[beat_index - 3], "world_revision": 1, "recognition_s": 0.18, "attack_input_margin_s": 0.08, "escape_directions": directions, "return_directions": directions.duplicate(), "floor_regions": [scheduler_bindings().floors.launch_floor]}


func _on_enter_level() -> void:
	hero.world_action_executed.connect(_on_world_action)
	for id: String in TARGET_IDS:
		(targets[id] as PracticeTarget).set_process(true)
	for id: String in ARM_IDS:
		(arms[id] as CinderLaneMechanism).bind(scheduler, {"hero": hero})
	_apply_beat()


func _on_exit_level() -> void:
	_pending_target_check = false
	if is_instance_valid(hero) and hero.world_action_executed.is_connected(_on_world_action):
		hero.world_action_executed.disconnect(_on_world_action)
	for id: String in ARM_IDS:
		var arm: CinderLaneMechanism = arms.get(id) as CinderLaneMechanism
		if is_instance_valid(arm):
			# Parent _exit_tree may follow children already leaving. Their own
			# shared cleanup has run; only cancel a still-live binding.
			if arm.is_inside_tree():
				arm.cancel("rehearsal_exit")
			arm.set_physics_process(false)
	if is_instance_valid(scheduler):
		if scheduler.is_inside_tree():
			scheduler.end_encounter("rehearsal_exit")
		scheduler.set_physics_process(false)
	if is_instance_valid(hatch_cue):
		hatch_cue.cancel()
	for id: String in targets:
		var target: PracticeTarget = targets[id]
		if is_instance_valid(target):
			target.remove_from_group("practice_targets")
			target.set_process(false)
			var cue: CinderInteractionCue = target.get("interaction_cue") as CinderInteractionCue
			if is_instance_valid(cue):
				cue.cancel()
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(hero) or hero.dead or _advancing:
		return
	if beat_index in [3, 4]:
		var arm: CinderLaneMechanism = arms[ARM_IDS[beat_index - 3]]
		var state: Dictionary = arm.state()
		var position_2d := Vector2(hero.global_position.x, hero.global_position.z)
		var approach := Rect2(-2.9, ARM_ORIGINS[beat_index - 3].z - 0.2, 5.8, 5.3)
		if state.status != "running" and approach.has_point(position_2d) and hero.get_threat_response_state().stable:
			# First demonstration starts in empty space. A broad side approach is
			# enough; no exact marker, wait timer or invulnerability is credited.
			var first_cycle_clear: bool = int(state.cycle) > 0 or not Geometry.segment_hits(state.geometry, hero.global_position, hero.global_position, CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN)
			if first_cycle_clear:
				var answer: Dictionary = arm.start("hero", arm_response_context())
				if answer.get("accepted", false):
					_apply_beat()
	for id: String in ARM_IDS:
		_present_arm(id)
	if beat_index == EXERCISES.size() and hatch.overlaps_body(hero):
		_on_hatch_contact(hero)


func _present_arm(id: String) -> void:
	var state: Dictionary = (arms[id] as CinderLaneMechanism).state()
	var role: Dictionary = state.resolved_role
	var duration: float = 0.0
	match state.phase:
		"warning": duration = float(role.get("windup_s", 0.0)) - float(role.get("lock_s", 0.0))
		"lock": duration = float(role.get("lock_s", 0.0))
		"active": duration = float(role.get("active_s", 0.0))
		"recovery": duration = float(role.get("recovery_s", 0.0))
	var progress: float = clampf(1.0 - float(state.remaining_s) / duration, 0.0, 1.0) if duration > 0.0 else 0.0
	(arm_visuals[id] as Node3D).call("set_parked", beat_index > ARM_IDS.find(id) + 3)
	(arm_visuals[id] as Node3D).call("set_phase", state.phase, progress)


func _on_world_action(record: Dictionary) -> void:
	if not is_instance_valid(hero) or hero.dead:
		return
	if _advancing:
		if record.get("kind") in ["primary", "blast"]:
			_pending_target_check = true
		return
	if beat_index == 0 and record.get("kind") == "dash":
		var landing: Vector3 = record.get("landing", Vector3.INF)
		var marker: Vector3 = dash_marker_position()
		landing.y = marker.y
		if float(record.get("distance", 0.0)) > 1.0 and landing.distance_to(marker) <= 1.1:
			_advance_exercise()
	elif beat_index in [1, 2, 3, 4] and record.get("kind") in ["primary", "blast"]:
		if (targets[TARGET_IDS[beat_index - 1]] as PracticeTarget).hp <= 0.0:
			_advance_exercise()


func _advance_exercise() -> void:
	_advancing = true
	# Cancel before any checkpoint callback can pause the tree. No stale live
	# reservation/sample or arm clock travels into the next exercise boundary.
	if beat_index in [3, 4]:
		(arms[ARM_IDS[beat_index - 3]] as CinderLaneMechanism).cancel("target_cleared")
		scheduler.end_encounter("target_cleared")
	completed_exercises.append(EXERCISES[beat_index])
	beat_index += 1
	if beat_index in [3, 4]:
		var profile: String = "standard"
		if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference"):
			profile = String(shared_shell.call("get_difficulty_preference"))
		scheduler.begin_encounter(profile, ENCOUNTER_IDS[beat_index - 3], 1)
	_apply_beat()
	if beat_index < EXERCISES.size():
		request_checkpoint(EXERCISES[beat_index - 1], "encounter")
	else:
		# Completion atomically publishes local state and durable main progress.
		# A preceding checkpoint would try to save completion before its record.
		request_completion(COMPLETION_ID)
	_advancing = false
	if _pending_target_check and is_instance_valid(hero):
		_pending_target_check = false
		if beat_index in [1, 2, 3, 4] and (targets[TARGET_IDS[beat_index - 1]] as PracticeTarget).hp <= 0.0:
			_advance_exercise()


func _target_active(id: String, beat: int, states: Dictionary = {}) -> bool:
	if id == "hall": return beat == 1
	if id == "workshop": return beat == 2
	var index: int = TARGET_IDS.find(id) - 2
	if index < 0 or beat != index + 3:
		return false
	var state: Dictionary = states.get(ARM_IDS[index], {}) if not states.is_empty() else (arms[ARM_IDS[index]] as CinderLaneMechanism).state()
	return int(state.get("cycle", 0)) > 0


func _apply_beat() -> void:
	objective_text = OBJECTIVES[beat_index]
	($DashMarker/Visual as Node3D).visible = beat_index == 0
	for index: int in TARGET_IDS.size():
		var id: String = TARGET_IDS[index]
		var target: PracticeTarget = targets[id]
		target.call("set_exercise_active", _target_active(id, beat_index))
		target.visible = index < beat_index
	if is_instance_valid(scenery):
		scenery.call("set_hatch_open", beat_index == EXERCISES.size())
	if is_instance_valid(hatch_cue):
		if beat_index == EXERCISES.size():
			hatch_cue.present("available", "contact")
		else:
			hatch_cue.clear()
	for id: String in ARM_IDS:
		_present_arm(id)


func _on_hatch_contact(body: Node3D) -> void:
	request_contact_exit(EXIT_ID, body)


func request_contact_exit(exit_id: String, body: Node3D) -> bool:
	if exit_id != EXIT_ID or not is_instance_valid(hero) or body != hero or not is_instance_valid(hatch) or not hatch.overlaps_body(body):
		return false
	return super.request_contact_exit(exit_id, body)


func snapshot_state() -> Dictionary:
	if _advancing:
		last_snapshot_error = "Capture the rehearsal at the deferred shared-actor barrier"
		return {}
	var snapshot: Dictionary = super.snapshot_state()
	if snapshot.is_empty():
		if is_instance_valid(scheduler) and not scheduler.last_snapshot_error.is_empty():
			last_snapshot_error = scheduler.last_snapshot_error
		for id: String in ARM_IDS:
			if not (arms[id] as CinderLaneMechanism).last_snapshot_error.is_empty():
				last_snapshot_error = (arms[id] as CinderLaneMechanism).last_snapshot_error
		return {}
	last_snapshot_error = snapshot_error(snapshot)
	return snapshot if last_snapshot_error.is_empty() else {}


func snapshot_error(snapshot: Dictionary) -> String:
	var error: String = super.snapshot_error(snapshot)
	return _progress_snapshot_error(snapshot) if error.is_empty() else error


func snapshot_error_with_player(snapshot: Dictionary, saved_player: Dictionary) -> String:
	var error: String = super.snapshot_error_with_player(snapshot, saved_player)
	# Both public entry points retain this level's authored progress invariant.
	return _progress_snapshot_error(snapshot) if error.is_empty() else error


func _progress_snapshot_error(snapshot: Dictionary) -> String:
	var progress: Dictionary = snapshot["progress"]
	var beat: int = int(snapshot["local"]["beat_index"])
	if progress["completed"] != (beat == EXERCISES.size()) or progress["completion_id"] != (COMPLETION_ID if beat == EXERCISES.size() else ""):
		return "Completion must match all five genuinely completed exercises"
	if progress["contact_exit_id"] not in (["", EXIT_ID] if beat == EXERCISES.size() else [""]):
		return "Only the completed capsule hatch may carry a contact exit"
	var history: Dictionary = progress["checkpoint_ids"]
	var checkpoint_count: int = mini(beat, EXERCISES.size() - 1)
	if history.size() != checkpoint_count:
		return "Checkpoint history must match the pre-completion exercises"
	for index: int in checkpoint_count:
		if history.get(EXERCISES[index]) != "encounter":
			return "Checkpoint history contains an unknown or out-of-order boundary"
	var expected_checkpoint: String = "" if checkpoint_count == 0 else EXERCISES[checkpoint_count - 1]
	if progress["checkpoint_id"] != expected_checkpoint:
		return "Current checkpoint must match the current exercise boundary"
	return ""


func restore_state(snapshot: Dictionary) -> bool:
	last_snapshot_error = snapshot_error(snapshot)
	if not last_snapshot_error.is_empty():
		return false
	return super.restore_state(snapshot)


func _capture_local_state() -> Dictionary:
	var target_states: Dictionary = {}
	for id: String in TARGET_IDS:
		var target: PracticeTarget = targets[id]
		if not is_instance_valid(target):
			return {}
		target_states[id] = {"hp": target.hp, "active": target.is_in_group("practice_targets"), "hit_feedback_left_s": target.hit_feedback_left()}
	var bindings: Dictionary = scheduler_bindings()
	var scheduled: Dictionary = scheduler.snapshot_state(bindings)
	if scheduled.is_empty():
		return {}
	var arm_states: Dictionary = {}
	for id: String in ARM_IDS:
		var captured: Dictionary = (arms[id] as CinderLaneMechanism).snapshot_state(bindings)
		if captured.is_empty():
			return {}
		arm_states[id] = captured
	return {"beat_index": beat_index, "completed_exercises": completed_exercises.duplicate(), "targets": target_states, "scheduler": scheduled, "arms": arm_states}


func _local_snapshot_error(state: Dictionary) -> String:
	return _validate_local_state(state, scheduler_bindings())


func _local_snapshot_error_with_player(state: Dictionary, saved_player: Dictionary) -> String:
	# Shared shell has already validated the complete saved actor. Its saved
	# feet position is the authority for pure paired geometry prevalidation.
	# Retain no actor copy and never move the fresh/live candidate during proof.
	if not saved_player.get("motion") is Dictionary or not Codec.is_vector3(saved_player.motion.get("position")):
		return "Paired rehearsal validation requires the validated saved actor position"
	var staged: Dictionary = scheduler_bindings()
	staged.hero_positions = {"hero": Codec.read_vector3(saved_player.motion.position)}
	return _validate_local_state(state, staged)


func _validate_local_state(state: Dictionary, bindings: Dictionary) -> String:
	if state.size() != 5 or not state.has_all(["beat_index", "completed_exercises", "targets", "scheduler", "arms"]):
		return "Rehearsal snapshot requires exactly five declared local fields"
	var beat: Variant = state["beat_index"]
	if not Codec.is_integer(beat, 0, EXERCISES.size()):
		return "Rehearsal beat must be an integral supported value from 0 to 5"
	var completed: Variant = state["completed_exercises"]
	if not completed is Array or completed.size() != int(beat):
		return "Completed exercises must be the exact beat prefix"
	for index: int in completed.size():
		if completed[index] != EXERCISES[index]:
			return "Completed exercises are duplicated, reordered or unknown"
	if not is_instance_valid(scheduler) or not scheduler.is_inside_tree() or not is_ancestor_of(scheduler) or not state.scheduler is Dictionary or not state.arms is Dictionary or state.arms.size() != 2 or not state.arms.has_all(ARM_IDS):
		return "Required scheduler and exactly two stable arm states must exist"
	var runtime_error: String = _local_runtime_error()
	if not runtime_error.is_empty():
		return runtime_error
	var scheduled_error: String = scheduler.snapshot_error(state.scheduler, bindings)
	if not scheduled_error.is_empty():
		return scheduled_error
	var expected_encounter: String = ENCOUNTER_IDS[int(beat) - 3] if int(beat) in [3, 4] else ""
	if state.scheduler.encounter_id != expected_encounter or int(state.scheduler.world_revision) != (1 if int(beat) in [3, 4] else (0 if int(beat) < 3 else 1)):
		return "Scheduler encounter must match the current rehearsal exercise"
	for index: int in ARM_IDS.size():
		var id: String = ARM_IDS[index]
		var arm: CinderLaneMechanism = arms.get(id) as CinderLaneMechanism
		if not is_instance_valid(arm) or not arm.is_inside_tree() or not is_ancestor_of(arm) or not state.arms[id] is Dictionary:
			return "Required runtime arm is missing: " + id
		var arm_error: String = arm.snapshot_error(state.arms[id], bindings, state.scheduler)
		if not arm_error.is_empty():
			return arm_error
		if int(beat) < index + 3 and state.arms[id].status != "idle":
			return "A future rehearsal cannot carry an already-used arm"
		if int(beat) != index + 3 and state.arms[id].status == "running":
			return "Only the current rehearsal may retain a live arm reservation"
		if int(beat) > index + 3 and state.arms[id].status != "cancelled":
			return "A completed arm exercise must retain its explicit cancellation"
	var states: Variant = state["targets"]
	if not states is Dictionary or states.size() != TARGET_IDS.size() or not states.has_all(TARGET_IDS):
		return "Snapshot requires exactly four stable targets"
	for index: int in TARGET_IDS.size():
		var id: String = TARGET_IDS[index]
		var target: PracticeTarget = targets.get(id) as PracticeTarget
		if not is_instance_valid(target) or not target.is_inside_tree() or not is_ancestor_of(target):
			return "Required runtime target is missing: " + id
		if not target.global_position.is_equal_approx(TARGET_POSITIONS[index]) or not target.global_basis.is_equal_approx(Basis.IDENTITY):
			return "The actual stationary rehearsal target must retain its authored placement: " + id
		var entry: Variant = states[id]
		if not entry is Dictionary or entry.size() != 3 or not entry.has_all(["hp", "active", "hit_feedback_left_s"]):
			return "Target state requires exactly HP, active and hit-feedback clock fields"
		var expected_hp: float = 0.0 if int(beat) >= index + 2 else 1.0
		if not Codec.is_number(entry["hp"]) or entry["hp"] != expected_hp:
			return "Target HP does not match the completed exercise prefix"
		if not entry["active"] is bool or entry["active"] != _target_active(id, int(beat), state.arms):
			return "Target availability does not match the current exercise/cycle"
		if not Codec.in_range(entry["hit_feedback_left_s"], 0.0, PracticeTarget.HIT_FEEDBACK_S):
			return "Target feedback must be a finite supported shared clock"
		if expected_hp == 1.0 and entry["hit_feedback_left_s"] != 0.0:
			return "An untouched rehearsal target cannot carry a hit-feedback clock"
	return ""


func _local_runtime_error() -> String:
	if not is_instance_valid(scenery) or not scenery.is_inside_tree() or not is_ancestor_of(scenery) or not is_instance_valid(hatch) or not hatch.is_inside_tree() or not is_ancestor_of(hatch) or not is_instance_valid(hatch_cue) or not hatch_cue.is_inside_tree() or not is_ancestor_of(hatch_cue):
		return "Required scenic hatch and contact cue must remain in this level"
	var shape: CollisionShape3D = hatch.get_node_or_null("BroadBoardingContact") as CollisionShape3D
	if not is_instance_valid(shape) or shape.disabled or not shape.shape is BoxShape3D or not shape.position.is_zero_approx() or not shape.basis.is_equal_approx(Basis.IDENTITY) or not (shape.shape as BoxShape3D).size.is_equal_approx(Vector3(2.8, 1.6, 1.6)) or not hatch.position.is_equal_approx(Vector3(0, 0.8, -13.7)) or not hatch.basis.is_equal_approx(Basis.IDENTITY) or hatch.collision_layer != 0 or hatch.collision_mask != 4 or not hatch.monitoring:
		return "The actual broad hatch contact must retain its authored geometry"
	for index: int in ARM_IDS.size():
		var id: String = ARM_IDS[index]
		var arm: CinderLaneMechanism = arms.get(id) as CinderLaneMechanism
		# Idle/cancelled sources have no live reservation to compare. Reject
		# a moved source before scheduler or mechanism restoration can commit.
		if not is_instance_valid(arm) or not arm.is_inside_tree() or arm.get_parent() != self or not arm.global_position.is_equal_approx(ARM_ORIGINS[index]) or not arm.global_basis.is_equal_approx(Basis.IDENTITY):
			return "The actual loading-arm source must retain its authored lane binding: " + id
		var visual: Node3D = arm_visuals.get(id) as Node3D
		if not is_instance_valid(visual) or not visual.is_inside_tree() or visual.get_parent() != arms.get(id) or not visual.position.is_zero_approx():
			return "Required physical loading-arm source art is missing: " + id
	return ""


func _restore_local_state(state: Dictionary) -> void:
	# Actor has already restored through the shared aggregate. Commit the
	# prevalidated scheduler before mechanism samples/cues, without yielding.
	var bindings: Dictionary = scheduler_bindings()
	var restored: bool = scheduler.restore_state(state.scheduler, bindings)
	assert(restored, "Validated rehearsal scheduler must restore")
	for id: String in ARM_IDS:
		restored = (arms[id] as CinderLaneMechanism).restore_state(state.arms[id], bindings)
		assert(restored, "Validated rehearsal mechanism must restore")
	beat_index = int(state["beat_index"])
	completed_exercises.assign(state["completed_exercises"])
	for id: String in TARGET_IDS:
		var entry: Dictionary = state["targets"][id]
		(targets[id] as PracticeTarget).configure(1.0, float(entry["hp"]), float(entry["hit_feedback_left_s"]), false)
	_apply_beat()
