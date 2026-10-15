extends "res://tests/acts/act3/mirror_echo_lifecycle_smoke.gd"
## TEST ONLY terminal presentation with a genuine managed native Echo lease.
## Reuse the existing fixture's actual admission/lock and public pause helpers.
## Its disclosed initial zero-ammo seed precedes admission; no later HP, pose,
## history, clock, combat geometry or lease writes. No O3/whole-Shell flow credit.

var _detached_failure_marker: MeshInstance3D
var _teardown_rows: Array[Dictionary] = []
var _teardown_cases: Array[Dictionary] = []


func _run() -> void:
	_weak = false
	_portraits = false
	for detached: bool in [true, false]:
		var opened: bool = await _open()
		var exercised: bool = await _held_cancellation(detached) if opened else false
		_teardown_cases.append({"detached": detached, "opened": opened, "exercise_passed": exercised})
		if is_instance_valid(_detached_failure_marker):
			var marker_ref: WeakRef = weakref(_detached_failure_marker)
			_detached_failure_marker.free()
			_detached_failure_marker = null
			_expect(marker_ref.get_ref() == null, "removed failure marker is disposed without reattachment or repair")
		await _close()
		_expect(get_nodes_in_group("required_cues").is_empty(), "native teardown leaves no required cue or detached marker group")
	print("Replay terminal marker teardown: %d checks; failures: %d. Actual managed cancellation with detached-marker and live-marker control; no whole-Shell/WM quit or O3 acceptance." % [_checks, _failures])
	var report: Dictionary = {"checks": _checks, "failures": _failures, "rows": _teardown_rows, "cases": _teardown_cases, "complete": _teardown_cases.size() == 2 and _teardown_cases.all(func(cell: Dictionary) -> bool: return cell.opened and cell.exercise_passed), "scope": "Native managed Echo held cancellation with detached-marker and attached-marker control only. Existing fixture helpers; no prior diagnostic candidate acceptance implied. No wholeShell/WMquit/O3/fullroute credit."}
	var output: String = OS.get_environment("CINDER_ECHO_TEARDOWN_REPORT")
	if not output.is_empty():
		var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(report, "  ") + "\n"); file.close()
	quit(0 if _failures == 0 and report.complete else 1)


func _held_cancellation(detached: bool) -> bool:
	_game.call("resume_lab")
	if not await _admit_and_lock() or not await _pause():
		return false
	var control: Dictionary = _scheduler.source_control_state(_source)
	var current: Dictionary = _source.call("state")
	var clock: float = _scheduler.get_clock()
	if not _expect(not control.is_empty() and control.outside_transaction and control.reservations.size() == 1 and current.status == "running" and current.lifecycle.terminal_receipts.is_empty() and _source.call("get_authored_cycle_terminal_receipt").is_empty() and control.reservations[0].adapter.locked and clock < float(control.reservations[0].active_from_s) and _hero.get_world_action_records().is_empty() and _source.call("source_hit_receipts").is_empty(), "native cancellation cell holds one genuine locked lease before any action, hit or terminal history"):
		return false
	var reservation_id: String = String(control.reservations[0].id)
	var reason: String = "test-only/detached-failure-marker" if detached else "test-only/live-failure-marker"
	var marker: MeshInstance3D = _source.get_node_or_null("VisibleReplayFailure") as MeshInstance3D
	if not _expect(is_instance_valid(marker) and marker.is_inside_tree() and marker.top_level and not marker.visible and _source.is_inside_tree(), "actual running Playback owns its original attached top-level failure marker"):
		return false
	var hero_before: Dictionary = _hero.snapshot_state()
	var hp: float = float(_source.get("hp"))
	var source_transform: Transform3D = _source.global_transform
	var events_before: Array[String] = _events.duplicate()
	var observations: Array[Dictionary] = []
	var invalidated: Callable = func(id: String, observed_reason: String) -> void:
		if id == reservation_id:
			observations.append(_terminal_observation("invalidated", id, observed_reason, marker))
	var failed: Callable = func(observed_reason: String) -> void:
		observations.append(_terminal_observation("failed", reservation_id, observed_reason, marker))
	var changed: Callable = func(value: Dictionary) -> void:
		observations.append(_terminal_observation("state", reservation_id, String(value.get("reason", "")), marker))
	_scheduler.reservation_invalidated.connect(invalidated)
	_source.connect("playback_failed", failed)
	_source.connect("state_changed", changed)
	if detached:
		# Reproduce the concrete child-exited condition while retaining the real
		# source/Scheduler/lease. Never substitute an invalidation stub or pose.
		_detached_failure_marker = marker
		_source.remove_child(marker)
	var boundary: bool = _source.is_inside_tree() and _scheduler.is_inside_tree() and marker.is_inside_tree() != detached and _scheduler.get_clock() == clock
	var cancelled: bool = false
	if _expect(boundary, "actual marker removal leaves its live source, Scheduler and original clock intact"):
		cancelled = _scheduler.cancel(reservation_id, reason)
	_scheduler.reservation_invalidated.disconnect(invalidated)
	_source.disconnect("playback_failed", failed)
	_source.disconnect("state_changed", changed)
	if not _expect(cancelled, "real Scheduler cancellation retires the held managed lease"):
		return false
	var terminal: Dictionary = _source.call("get_authored_cycle_terminal_receipt")
	var tombstone: Dictionary = _scheduler.replay_cancellation_state(reservation_id)
	var after: Dictionary = _scheduler.source_control_state(_source)
	var counts: Dictionary = {"state": 0, "failed": 0, "invalidated": 0}
	var exact_callbacks: bool = true
	for entry: Dictionary in observations:
		counts[String(entry.kind)] += 1
		exact_callbacks = exact_callbacks and entry.reservation_id == reservation_id and entry.reason == reason and entry.clock_s == clock and entry.owner_inside_tree and entry.scheduler_inside_tree and entry.marker_inside_tree != detached and entry.status == "cancelled" and entry.outcome == "cancelled" and entry.lease_removed and _equal(entry.terminal, terminal)
	if not _expect(counts == {"state": 1, "failed": 1, "invalidated": 1} and exact_callbacks, "each native cancellation callback observes the original sealed terminal once after lease removal", str(observations)):
		return false
	if not _expect(not terminal.is_empty() and terminal.outcome == "cancelled" and terminal.reason == reason and terminal.terminal_at_s == clock and terminal.exchange.id == reservation_id and not tombstone.is_empty() and tombstone.id == reservation_id and tombstone.reason == reason and tombstone.cancelled_at_s == clock and not after.is_empty() and after.reservations.is_empty() and _equal(after.cooldown, control.cooldown) and _scheduler.get_clock() == clock, "detached presentation cannot replace cancellation provenance, timing or retained cooldown"):
		return false
	if detached:
		if not _expect(is_instance_valid(marker) and not marker.is_inside_tree() and marker.get_parent() == null and not marker.visible, "detached failure marker remains concealed without global-transform access or repair"):
			return false
	elif not _expect(marker.visible and marker.global_position == _source.global_position + Vector3.UP * 0.04 and marker.mesh != null, "ordinary live cancellation retains its visible original failure marker and placement"):
		return false
	var quiet_cues: bool = not _source.call("get_cues").is_empty()
	for cue: Node3D in _source.call("get_cues"):
		var cue_state: Dictionary = cue.call("state")
		quiet_cues = quiet_cues and cue_state.phase == "clear" and not cue_state.source_visible and not cue_state.footprint_visible and not cue_state.active_fill_visible
	if not _expect(quiet_cues and _equal(_hero.snapshot_state(), hero_before) and _source.global_transform == source_transform and float(_source.get("hp")) == hp and not bool(_source.get("dead")) and _source.call("source_hit_receipts").is_empty() and _events.size() == events_before.size() + 2 and _events.slice(0, events_before.size()) == events_before and _events.count("state") == events_before.count("state") + 1 and _events.count("invalidated") == events_before.count("invalidated") + 1, "quiet native cue clearing preserves Hero/source HP, pose and zero gameplay history"):
		return false
	var event_count: int = _events.size()
	for _frame: int in range(4):
		await process_frame
	return _expect(paused and _scheduler.get_clock() == clock and _events.size() == event_count and observations.size() == 3 and _equal(_source.call("get_authored_cycle_terminal_receipt"), terminal) and _equal(_hero.snapshot_state(), hero_before), "later paused frames cannot repeat terminal callbacks, advance clocks or emit actions")


func _terminal_observation(kind: String, reservation_id: String, reason: String, marker: MeshInstance3D) -> Dictionary:
	# No departed-node transform or whole-world snapshot is queried here.
	var current: Dictionary = _source.call("state")
	var terminal: Dictionary = _source.call("get_authored_cycle_terminal_receipt")
	var control: Dictionary = _scheduler.source_control_state(_source)
	return {"kind": kind, "reservation_id": reservation_id, "reason": reason, "clock_s": _scheduler.get_clock(), "owner_inside_tree": _source.is_inside_tree(), "scheduler_inside_tree": _scheduler.is_inside_tree(), "marker_inside_tree": marker.is_inside_tree(), "status": current.status, "outcome": terminal.get("outcome", ""), "terminal": terminal, "lease_removed": not control.is_empty() and control.reservations.is_empty()}


func _expect(ok: bool, label: String, detail: String = "") -> bool:
	var result: bool = super._expect(ok, label, detail)
	_teardown_rows.append({"n": _checks, "ok": ok, "label": label, "detail": detail})
	return result
