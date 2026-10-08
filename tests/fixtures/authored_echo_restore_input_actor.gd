extends "res://tests/fixtures/authored_echo_lifecycle_actor.gd"
## TEST ONLY: genuine native fixture subclass for hostile restore-input
## controls. No production hook, native definition, HP or codec is changed.
## Build the clean binding first, then assign the hostile branch by reference;
## the getter itself must never recursively copy an untrusted/cyclic value.

var _test_restore_input_enabled: bool = false
var _test_restore_input_definition: Variant = null
var _test_reentrant_environment_once: bool = false
var _test_reentrant_trace: Array[Dictionary] = []


func get_authored_echo_binding() -> Dictionary:
	var result: Dictionary = super.get_authored_echo_binding()
	if _test_restore_input_enabled:
		result["definition"] = _test_restore_input_definition
	return result


func get_authored_cycle_environment() -> Dictionary:
	var result: Dictionary = super.get_authored_cycle_environment()
	if _test_reentrant_environment_once:
		# TEST ONLY native handshake control: enable's preflight never calls this
		# getter; Scheduler.begin's actual runtime construction does, after it
		# enters its real managed transaction. Never read/seed a private flag.
		_test_reentrant_environment_once = false
		var commit: Dictionary = _source_scheduler.commit_authored_replay("test-only/nonexistent-commit", {})
		var tracking: Dictionary = _source_scheduler.update_tracking("test-only/nonexistent-tracking", {})
		_test_reentrant_trace.append({"method": "commit_authored_replay", "accepted": commit.get("accepted", false), "reason": commit.get("reason", "")})
		_test_reentrant_trace.append({"method": "update_tracking", "accepted": tracking.get("accepted", false), "reason": tracking.get("reason", "")})
	return result
