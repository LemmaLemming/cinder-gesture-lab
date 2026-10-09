extends CinderLevel
## Living Forest scenery/sun envelope, shared traveller and stable floor.
## Full encounters/checkpoints live in the separate authored route consumer.

const Scenery = preload("res://scripts/acts/act3/living_forest_scenery.gd")
const Observer = preload("res://scripts/acts/act3/dreamsinter_observer.gd")
const SUN_STABLE_S: float = 10.0
const SUN_PREVIEW_S: float = 3.0
const SUN_LOCK_S: float = 1.0
const SUN_PERIOD_S: float = SUN_STABLE_S + SUN_PREVIEW_S + SUN_LOCK_S
const BEAT_LABELS: Array[String] = ["Vast trunks", "A root's promise", "Two living courts", "The watched clearing", "Canopy slit"]

var scenery: Node3D
var quiet_observer: Node3D
var sun_state: int = 0
var sun_elapsed_s: float = 0.0
var sun_stage: String = "stable"
var beat_index: int = 0
var _active: bool = false
var _last_sun_view: String = ""


func _ready() -> void:
	scenery = Scenery.new()
	scenery.name = "LivingForestScenery"
	add_child(scenery)
	scenery.call("build", false)
	quiet_observer = Observer.new()
	quiet_observer.name = "DreamsinterQuietGrove"
	add_child(quiet_observer)
	quiet_observer.position = Vector3(2.5, 0, -46.6)
	_update_sun_scenery()


func _on_enter_level() -> void:
	_active = true
	scenery.call("follow_landmarks", hero.global_position)
	quiet_observer.call("set_viewer", hero)


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


func _update_sun_scenery() -> void:
	var view: String = "%d:%s" % [sun_state, sun_stage]
	if view != _last_sun_view:
		scenery.call("show_sun", sun_state, sun_stage)
		_last_sun_view = view


func _capture_local_state() -> Dictionary:
	return {"sun_state": sun_state, "sun_elapsed_s": sun_elapsed_s, "beat_index": beat_index}


func _local_snapshot_error(state: Dictionary) -> String:
	if not is_instance_valid(scenery) or scenery.is_queued_for_deletion():
		return "Living Forest requires its live authored scenery"
	var error: String = String(scenery.call("runtime_error"))
	if not error.is_empty():
		return error
	if state.size() != 3 or not _integer_in_range(state.get("sun_state"), 0, 1) or not _integer_in_range(state.get("beat_index"), 0, 4):
		return "Living Forest requires its exact sun and five-beat envelope"
	var elapsed: Variant = state.get("sun_elapsed_s")
	if not (elapsed is float or elapsed is int) or not is_finite(float(elapsed)) or float(elapsed) < 0.0 or float(elapsed) >= SUN_PERIOD_S:
		return "Living Forest sun time must be finite within its current cycle"
	return ""


func _restore_local_state(state: Dictionary) -> void:
	sun_state = int(state.sun_state)
	sun_elapsed_s = float(state.sun_elapsed_s)
	beat_index = int(state.beat_index)
	sun_stage = "stable" if sun_elapsed_s < SUN_STABLE_S else ("preview" if sun_elapsed_s < SUN_STABLE_S + SUN_PREVIEW_S else "lock")
	_last_sun_view = ""
	_update_sun_scenery()
	if _active and is_instance_valid(hero):
		scenery.call("follow_landmarks", hero.global_position)
		quiet_observer.call("refresh_visibility")


func _integer_in_range(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= minimum and value <= maximum
