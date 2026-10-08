extends "res://scripts/campaign/level.gd"
## TEST ONLY actor/supply fixture. Never registered in real campaign metadata.
const Enemy = preload("res://scripts/enemy.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
var guard: AshEnemy
var charges: int = 1
var collected: Array = []
var rng_state: String = "9223372036854775701"
func _on_enter_level() -> void:
	guard = Enemy.new()
	guard.name = "StableGuard"
	guard.configure(hero, effects, 0)
	add_child(guard)
	guard.global_position = Vector3(0, 0, -1.5)
func _capture_local_state() -> Dictionary:
	return {"guard": guard.snapshot_state(), "charges": charges, "collected": collected.duplicate(), "rng_state": rng_state}
func _local_snapshot_error(state: Dictionary) -> String:
	var error: String = Codec.keys_error(state, ["guard", "charges", "collected", "rng_state"])
	if not error.is_empty() or not state.guard is Dictionary or not Codec.is_integer(state.charges, 0, 1) or not state.collected is Array or state.collected.size() > 1 or not state.rng_state is String or state.rng_state != "9223372036854775701":
		return "Malformed test encounter/supply state"
	for id: Variant in state.collected:
		if id != "supply-1":
			return "Unknown supply ID"
	if (int(state.charges) == 0) != (state.collected.size() == 1):
		return "Spent supply and collection identity disagree"
	return guard.snapshot_error(state.guard)
func _restore_local_state(state: Dictionary) -> void:
	guard.restore_state(state.guard)
	charges = int(state.charges)
	collected.clear()
	for id: String in state.collected:
		collected.append(id)
	rng_state = state.rng_state
