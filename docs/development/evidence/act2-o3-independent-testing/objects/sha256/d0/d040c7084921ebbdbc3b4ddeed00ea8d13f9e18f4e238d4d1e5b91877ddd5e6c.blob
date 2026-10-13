extends "res://scripts/campaign/level.gd"
## TEST ONLY aggregate fixture, using the real shared actor/scheduler/loading arm.
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Arm = preload("res://scripts/combat/lane_mechanism.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")

var scheduler: CinderThreatScheduler
var arm: CinderLaneMechanism
var local_validations: int = 0
var context_validations: int = 0
var restores: int = 0
var restore_error: String = ""
var probe_context: bool = false
var guard_observations: Dictionary = {}


func _on_enter_level() -> void:
	scheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	add_child(scheduler)
	scheduler.begin_encounter("standard", "paired-arm", 1)
	arm = Arm.new()
	arm.name = "LoadingArm"
	arm.position = Vector3(-1, 0, 0)
	arm.configure("loading-arm", Geometry.lane(Vector3(-1, 0, 0), Vector3(1, 0, 0), 0.30), Vector3.ZERO)
	add_child(arm)
	arm.bind(scheduler, {"hero": hero})


func bindings() -> Dictionary:
	return {"world_root": self, "owners": {"loading-arm": arm}, "floors": {"main-floor": {"collision": $Floor/Collision, "safe_rect": Rect2(-10, -10, 20, 20)}}}


func start_arm() -> Dictionary:
	return arm.start("hero", {"encounter_id": "paired-arm", "world_revision": 1, "recognition_s": 0.12, "attack_input_margin_s": 0.02, "escape_directions": [Vector3.BACK, Vector3.FORWARD], "return_directions": [Vector3.BACK, Vector3.FORWARD], "floor_regions": bindings().floors.values()})


func _capture_local_state() -> Dictionary:
	return {"scheduler": scheduler.snapshot_state(bindings()), "arm": arm.snapshot_state(bindings())}


func _local_snapshot_error(state: Dictionary) -> String:
	local_validations += 1
	return _paired_error(state, bindings())


func _local_snapshot_error_with_player(state: Dictionary, saved_player: Dictionary) -> String:
	context_validations += 1
	var staged: Dictionary = bindings()
	# The shell already proved the entire actor snapshot. This fixture consumes
	# only its authoritative saved feet position; it never trusts its own sample.
	staged.hero_positions = {"hero": Codec.read_vector3(saved_player.motion.position)}
	var error: String = _paired_error(state, staged)
	if probe_context:
		guard_observations = {
			"context": not snapshot_error_with_player({}, saved_player).is_empty(),
			"live": not snapshot_error({}).is_empty(),
			"restore": not restore_state({}),
			"capture": snapshot_state().is_empty(),
			"completion": not request_completion("nested"),
			"checkpoint": not request_checkpoint("nested"),
			"exit": not request_contact_exit("nested", hero),
		}
		var actual: CinderPlayer = hero
		exit_level()
		enter_level(actual, effects, shared_shell)
		guard_observations.lifecycle = hero == actual
		# Deliberately corrupt the hook's copies after proof to verify isolation.
		state.arm.hero_samples.hero.position[0] = 999.0
		saved_player.motion.position[0] = -999.0
	return error


func _paired_error(state: Dictionary, staged: Dictionary) -> String:
	var error: String = Codec.keys_error(state, ["scheduler", "arm"])
	if not error.is_empty() or not state.scheduler is Dictionary or not state.arm is Dictionary:
		return "Paired scheduler and actual arm snapshots required"
	error = scheduler.snapshot_error(state.scheduler, staged)
	return arm.snapshot_error(state.arm, staged, state.scheduler) if error.is_empty() else error


func _restore_local_state(state: Dictionary) -> void:
	restore_error = ""
	if not scheduler.restore_state(state.scheduler, bindings()):
		restore_error = scheduler.last_snapshot_error
	elif not arm.restore_state(state.arm, bindings()):
		restore_error = arm.last_snapshot_error
	restores += 1


func _on_exit_level() -> void:
	# Child _exit_tree already cancels its owner before a parent teardown hook.
	if is_instance_valid(arm) and arm.is_inside_tree():
		arm.cancel("fixture_exit")
	if is_instance_valid(scheduler) and scheduler.is_inside_tree():
		scheduler.end_encounter("fixture_exit")
