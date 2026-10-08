extends CinderLevel
## Twin Suns stage 1: stable shelves and scenery-only sun preview prototype.
## Combat, checkpoints and contact departure await supported shared adapters.

const SceneryScript = preload("res://scripts/acts/act3/twin_suns_scenery.gd")
const SUN_STABLE_S: float = 10.0
const SUN_PREVIEW_S: float = 3.0
const SUN_LOCK_S: float = 1.0
const SUN_PERIOD_S: float = SUN_STABLE_S + SUN_PREVIEW_S + SUN_LOCK_S
const BEAT_LABELS: Array[String] = ["A foreign noon", "The useful flank", "Two approaches", "Crossing the white shadow", "The pillars recede"]
const BEAT_Z: Array[float] = [43.0, 25.0, 8.0, -13.0, -35.0]

@export var prototype_room: bool = false
var sun_state: int = 0
var sun_elapsed_s: float = 0.0
var sun_stage: String = "stable"
var beat_index: int = 0
var scenery: Node3D
var _active: bool = false
var _last_sun_view: String = ""


func _ready() -> void:
	scenery = SceneryScript.new()
	scenery.name = "TwinSunsScenery"
	add_child(scenery)
	scenery.call("build", prototype_room)
	_update_sun_scenery()


func _on_enter_level() -> void:
	_active = true
	scenery.call("follow_landmarks", hero.global_position)


func _on_exit_level() -> void:
	_active = false


func _physics_process(delta: float) -> void:
	if not _active or not is_instance_valid(hero) or hero.dead:
		return
	sun_elapsed_s += delta
	while sun_elapsed_s >= SUN_PERIOD_S:
		sun_elapsed_s -= SUN_PERIOD_S
		sun_state = 1 - sun_state
	sun_stage = "stable" if sun_elapsed_s < SUN_STABLE_S else ("preview" if sun_elapsed_s < SUN_STABLE_S + SUN_PREVIEW_S else "lock")
	_update_sun_scenery()
	scenery.call("follow_landmarks", hero.global_position)
	if not prototype_room:
		# Spatial pacing only. Encounter completion gates will supersede these
		# scenery indices; the 8-minute concept budget never creates a wait.
		for index: int in range(BEAT_Z.size()):
			if hero.global_position.z <= BEAT_Z[index] + 4.0:
				beat_index = maxi(beat_index, index)


func _update_sun_scenery() -> void:
	var view: String = "%d:%s" % [sun_state, sun_stage]
	if view != _last_sun_view:
		scenery.call("show_sun", sun_state, sun_stage)
		_last_sun_view = view


func _capture_local_state() -> Dictionary:
	return {"sun_state": sun_state, "sun_elapsed_s": sun_elapsed_s, "beat_index": beat_index}


func _local_snapshot_error(state: Dictionary) -> String:
	if not is_instance_valid(scenery) or scenery.is_queued_for_deletion():
		return "Twin Suns requires its live authored scenery"
	var scenery_error: String = scenery.call("runtime_error")
	if not scenery_error.is_empty():
		return scenery_error
	if state.size() != 3 or not _integer_in_range(state.get("sun_state"), 0, 1) or not _integer_in_range(state.get("beat_index"), 0, 4):
		return "Twin Suns snapshot requires valid sun and beat state"
	var elapsed: Variant = state.get("sun_elapsed_s")
	if not (elapsed is float or elapsed is int) or not is_finite(float(elapsed)) or float(elapsed) < 0.0 or float(elapsed) >= SUN_PERIOD_S:
		return "Twin Suns sun time must be finite and within its current cycle"
	return ""


func _restore_local_state(state: Dictionary) -> void:
	sun_state = int(state["sun_state"])
	sun_elapsed_s = float(state["sun_elapsed_s"])
	beat_index = int(state["beat_index"])
	sun_stage = "stable" if sun_elapsed_s < SUN_STABLE_S else ("preview" if sun_elapsed_s < SUN_STABLE_S + SUN_PREVIEW_S else "lock")
	_last_sun_view = ""
	_update_sun_scenery()
	# The shared aggregate restores its actor before committing local state.
	# Align distant motifs now so a paused retry need not wait for motion.
	if _active and is_instance_valid(hero):
		scenery.call("follow_landmarks", hero.global_position)


func _integer_in_range(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= minimum and value <= maximum
