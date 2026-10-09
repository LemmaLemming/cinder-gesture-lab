extends "res://tests/fixtures/authored_echo_lifecycle_actor.gd"
## TEST ONLY instrumentation over the actual released native C52 Script.
## This Script is also attachable to a genuine CharacterBody3D, which remains
## stationary and never executes a lunge. No journal/clock/private flag seed.
var test_probe_once: bool = false
var test_probe_response: Dictionary = {}
var test_probe_threat: Dictionary = {}
var test_probe_preview: Dictionary = {}
var test_probe_lunge: Dictionary = {}
var test_probe_lunge_preview: Dictionary = {}
var test_probe_trace: Array[Dictionary] = []

func get_authored_cycle_environment() -> Dictionary:
	var actual: Dictionary = super.get_authored_cycle_environment()
	if not test_probe_once: return actual
	# enable's preflight does not call this getter; actual Scheduler.begin does,
	# inside its genuine transaction. The test never reads/sets _cycle_busy.
	test_probe_once = false
	_probe("preview_stationary", func() -> Dictionary: return _source_scheduler.preview_stationary(self, test_probe_threat, test_probe_response), true)
	_probe("request_attack", func() -> Dictionary: return _source_scheduler.request_attack(self, test_probe_threat, test_probe_response))
	_probe("request_attack_preview", func() -> Dictionary: return _source_scheduler.request_attack(self, test_probe_threat, test_probe_response, test_probe_preview))
	var tracking: Dictionary = test_probe_threat.duplicate(true)
	tracking["geometry"] = {"kind": "lane", "from": global_position, "to": global_position + Vector3.FORWARD * 1.5, "radius": 0.2}
	_probe("request_tracking", func() -> Dictionary: return _source_scheduler.request_tracking(self, tracking, test_probe_response))
	_probe("commit_tracking", func() -> Dictionary: return _source_scheduler.commit_tracking("test-only/no-tracking-lease", tracking.geometry, test_probe_response))
	_probe("update_tracking", func() -> Dictionary: return _source_scheduler.update_tracking("test-only/no-tracking-lease", tracking.geometry))
	var native_source: Node3D = self
	if native_source is CharacterBody3D:
		var body: CharacterBody3D = native_source as CharacterBody3D
		_probe("preview_lunge", func() -> Dictionary: return _source_scheduler.preview_lunge(body, test_probe_lunge, test_probe_response), true)
		_probe("request_lunge", func() -> Dictionary: return _source_scheduler.request_lunge(body, test_probe_lunge, test_probe_response))
		_probe("request_lunge_preview", func() -> Dictionary: return _source_scheduler.request_lunge(body, test_probe_lunge, test_probe_response, test_probe_lunge_preview))
	return actual

func _probe(method: String, operation: Callable, pure: bool = false) -> void:
	var diagnostic: String = _source_scheduler.last_error
	var snapshot_diagnostic: String = _source_scheduler.last_snapshot_error
	var clock: float = _source_scheduler.get_clock()
	var answer: Dictionary = operation.call()
	test_probe_trace.append({"method": method, "accepted": answer.get("accepted", false), "reason": answer.get("reason", ""), "pure": pure, "diagnostic_unchanged": _source_scheduler.last_error == diagnostic and _source_scheduler.last_snapshot_error == snapshot_diagnostic, "clock_unchanged": _source_scheduler.get_clock() == clock})
