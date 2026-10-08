extends "res://scripts/campaign/level.gd"
## TEST ONLY legacy local validator; intentionally does not override new hook.
var calls: int = 0
func _local_snapshot_error(state: Dictionary) -> String:
	calls += 1
	return "" if state.is_empty() else "Legacy level requires empty local state"
