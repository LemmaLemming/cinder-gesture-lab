extends CinderLevel
## Test fixture only; this is not an act encounter or campaign asset.

const EnemyScript = preload("res://scripts/enemy.gd")

var enter_count: int = 0
var exit_count: int = 0
var observed_actions: int = 0
var restore_count: int = 0
var local_state: Dictionary = {"supply": {"charges": 3}, "collected_ids": ["fixture-token"], "clock_s": 1.25}
var lifecycle_requests_blocked: bool = true
var restore_requests_blocked: bool = true
var probe_restore_guards: bool = false


func _on_enter_level() -> void:
	enter_count += 1
	# Lifecycle callbacks may wire actors, but cannot allocate progression.
	lifecycle_requests_blocked = lifecycle_requests_blocked and not request_checkpoint("enter-leak") and not request_completion("enter-leak")
	enter_level(hero, effects)
	exit_level()
	hero.fired.connect(_observe_action)
	var runtime_prop := Node3D.new()
	runtime_prop.name = "RuntimeProp"
	add_child(runtime_prop)
	var enemy := EnemyScript.new() as AshEnemy
	enemy.name = "LevelEnemy"
	enemy.configure(hero, effects)
	add_child(enemy)
	enemy.global_position = spawn_position() + Vector3(4.0, 0.0, 0.0)
	enemy.set_physics_process(false)


func _on_exit_level() -> void:
	exit_count += 1
	lifecycle_requests_blocked = lifecycle_requests_blocked and not request_checkpoint("exit-leak") and not request_completion("exit-leak")
	exit_level()
	if is_instance_valid(hero) and hero.fired.is_connected(_observe_action):
		hero.fired.disconnect(_observe_action)


func _observe_action(_kind: String) -> void:
	observed_actions += 1


func _capture_local_state() -> Dictionary:
	# Intentionally return the live dictionary: the contract supplies the copy.
	return local_state


func _local_snapshot_error(state: Dictionary) -> String:
	# Optional nested transport data exercises the base contract's depth boundary.
	var expected_fields: int = 4 if state.has("nested_payload") else 3
	if state.size() != expected_fields or not state.get("supply") is Dictionary or not state.get("collected_ids") is Array:
		return "Fixture snapshot requires supply, collected IDs and clock"
	if state.has("nested_payload") and not state["nested_payload"] is Dictionary:
		return "Fixture nested payload must be a dictionary"
	var supply: Dictionary = state["supply"]
	var charges: Variant = supply.get("charges")
	var clock: Variant = state.get("clock_s")
	if supply.size() != 1 or not (charges is int or charges is float) or charges != floor(charges) or charges < 0 or charges > 3:
		return "Fixture charges must be an integral remaining supply"
	if not (clock is int or clock is float) or clock < 0:
		return "Fixture clock must be nonnegative"
	for collected_id: Variant in state["collected_ids"]:
		if not collected_id is String or collected_id.is_empty():
			return "Fixture collected IDs must be nonempty strings"
	return ""


func _restore_local_state(state: Dictionary) -> void:
	restore_count += 1
	if probe_restore_guards:
		restore_requests_blocked = not request_checkpoint("restore-leak") and not request_completion("restore-leak") and not request_contact_exit("restore-leak", hero) and snapshot_state().is_empty() and not restore_state({})
		exit_level()
		enter_level(hero, effects)
	# Intentionally retain the supplied dictionary: caller snapshots still cannot
	# mutate it because the base passed a defensive copy after full validation.
	# JSON parses numbers as floats. The validated local schema declares an
	# integral supply count, so normalize its committed representation explicitly.
	state["supply"]["charges"] = int(state["supply"]["charges"])
	state["clock_s"] = float(state["clock_s"])
	local_state = state
