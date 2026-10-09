extends "res://tests/acts/act3/mirror_echo_lifecycle_smoke.gd"
## TEST ONLY live managed fixture retirement. One genuine default generation
## reaches its due locked lease, then public deferred pause and whole exit.
## No hit, fabricated lease, history reset, OS focus or portrait acceptance.


func _run() -> void:
	_weak = false
	_portraits = false
	if _expect(not ("--weak-primary" in OS.get_cmdline_user_args()) and not ("--portraits" in OS.get_cmdline_user_args()), "focused exit cell uses the genuine default native fixture only"):
		await _live_exit()
	await _close()
	print("Owned Echo live fixture exit: %d checks; failures: %d. One actual locked generation; cleanup callbacks are separately observed, no full lifecycle/parent/portrait acceptance." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _live_exit() -> bool:
	if not await _open():
		return false
	var ready: Dictionary = _pair()
	if not _expect(_valid_pair(ready) and ready.level.local.playback.status == "cycle_ready" and ready.level.local.playback.lifecycle.terminal_receipts.is_empty() and _source.call("get_authored_cycle_terminal_receipt").is_empty() and _hero.get_world_action_records().is_empty(), "live-exit cell begins with real ready generation one and no earned exchange/history/actions"):
		return false
	_game.call("resume_lab")
	if not await _admit_and_lock() or not await _pause():
		return false
	var pair: Dictionary = _pair()
	var control: Dictionary = _scheduler.source_control_state(_source)
	var clock: float = _scheduler.get_clock()
	var native: Dictionary = _source.call("get_source_state")
	if not _expect(_valid_pair(pair) and not control.is_empty() and control.outside_transaction and control.reservations.size() == 1 and pair.level.local.playback.status == "running" and pair.level.local.playback.lifecycle.stage == "running" and pair.level.local.playback.lifecycle.terminal_receipts.is_empty() and pair.level.local.playback.exchange.adapter.locked and clock < float(pair.level.local.playback.exchange.active_from_s) and pair.level.local.source.generation == 1 and float(_source.get("hp")) == 36.0 and not bool(_source.get("dead")) and _source.call("source_hit_receipts").is_empty() and _source.call("get_authored_cycle_terminal_receipt").is_empty() and _hero.hp == _hero_hp and _hero.get_world_action_records().is_empty() and not _events.has("slash") and not _events.has("hit") and not _events.has("contact") and not _events.has("fired_blast"), "public pause retains the actual locked live lease/HP36/original zero-hit history before danger", str(native)):
		return false
	var held: Dictionary = control.reservations[0]
	var reservation_id: String = String(held.id)
	var bindings: Dictionary = _level.call("scheduler_bindings")
	var hero_before: Dictionary = _hero.snapshot_state()
	var source_transform: Transform3D = _source.global_transform
	var resources: Dictionary = _resources()
	var events_before: Array[String] = _events.duplicate()
	var callbacks: Array[Dictionary] = []
	var state_observer: Callable = func(_value: Dictionary) -> void: callbacks.append(_exit_callback("state", reservation_id))
	var failure_observer: Callable = func(reason: String) -> void: callbacks.append(_exit_callback("failed", reservation_id, reason))
	var invalidation_observer: Callable = func(id: String, reason: String) -> void:
		if id == reservation_id:
			callbacks.append(_exit_callback("invalidated", id, reason))
	_source.connect("state_changed", state_observer)
	_source.connect("playback_failed", failure_observer)
	_scheduler.reservation_invalidated.connect(invalidation_observer)
	var refs: Array[WeakRef] = []
	for node: Node in [_game, _hero, _level, _source, _scheduler, _barrier, _marker(), _source.call("get_enemy_apparition")]:
		refs.append(weakref(node))
	for cue: Node3D in _source.call("get_cues"):
		refs.append(weakref(cue))
	_level.exit_level()
	_source.disconnect("state_changed", state_observer)
	_source.disconnect("playback_failed", failure_observer)
	_scheduler.reservation_invalidated.disconnect(invalidation_observer)
	var after: Dictionary = _scheduler.source_control_state(_source)
	var terminal: Dictionary = _source.call("get_authored_cycle_terminal_receipt")
	var tombstone: Dictionary = _scheduler.replay_cancellation_state(reservation_id)
	var source_state: Dictionary = _source.call("state")
	var observed: Dictionary = {"state": 0, "failed": 0, "invalidated": 0}
	var callbacks_live: bool = true
	for entry: Dictionary in callbacks:
		observed[String(entry.kind)] += 1
		callbacks_live = callbacks_live and entry.owner_inside_tree and entry.scheduler_inside_tree and entry.hero_inside_tree and entry.renderer_inside_tree and entry.status == "cancelled" and entry.outcome == "cancelled" and entry.clock_s == clock and (entry.kind == "state" or entry.reason == "test_fixture_whole_parent_exit")
	print("LIVE FIXTURE EXIT CALLBACKS: ", callbacks, "; gameplay_events_before=", events_before, "; actual_events_after=", _events)
	if not _expect(observed == {"state": 1, "failed": 1, "invalidated": 1} and callbacks_live and _events.size() == events_before.size() + 2 and _events.slice(0, events_before.size()) == events_before and _events.count("state") == events_before.count("state") + 1 and _events.count("invalidated") == events_before.count("invalidated") + 1, "whole exit emits each genuine cleanup callback once while native resources remain inside the tree, separately from gameplay"):
		return false
	if not _expect(not after.is_empty() and after.reservations.is_empty() and _equal(after.cooldown, control.cooldown) and _scheduler.get_clock() == clock and source_state.status == "cancelled" and not terminal.is_empty() and terminal.outcome == "cancelled" and terminal.reason == "test_fixture_whole_parent_exit" and terminal.exchange.id == reservation_id and _equal(terminal, source_state.lifecycle.terminal_receipts[-1]) and not tombstone.is_empty() and tombstone.id == reservation_id and tombstone.cancelled_at_s == clock and tombstone.reason == terminal.reason and tombstone.source_instance_id == _source.get_instance_id(), "original held lease becomes its genuine cancelled terminal/tombstone with unchanged clock and retained cooldown"):
		return false
	var actual_scheduler: Dictionary = _scheduler.snapshot_state(bindings)
	var actual_playback: Dictionary = _source.call("snapshot_state", actual_scheduler, bindings)
	var actual_source: Dictionary = _source.call("capture_source", _hero.snapshot_state(), actual_scheduler, actual_playback)
	if not _expect(not actual_scheduler.is_empty() and not actual_playback.is_empty() and not actual_source.is_empty() and actual_scheduler.schema_version == 3 and _equal(actual_source.lifecycle, actual_playback.lifecycle) and _equal(actual_playback.lifecycle, actual_scheduler.authored_source_cycles.sources[0]) and actual_playback.status == "cancelled" and actual_source.hit_receipts.is_empty() and _equal(_hero.snapshot_state(), hero_before) and _source.global_transform == source_transform and float(_source.get("hp")) == 36.0 and not bool(_source.get("dead")) and _equal(_resources(), resources) and _marker_error().is_empty() and not _marker().visible and _source.is_in_group("enemies") and not _events.has("slash") and not _events.has("hit") and not _events.has("contact") and not _events.has("action"), "independent native source/Playback/Scheduler capture keeps earned cancellation history and unchanged Hero/HP/body before disposal", _scheduler.last_snapshot_error + "; " + String(_source.get("last_snapshot_error")) + "; " + String(_source.get("source_snapshot_error"))):
		return false
	var cleanup_events: Array[String] = _events.duplicate()
	await _close()
	var freed: bool = true
	for ref: WeakRef in refs:
		freed = freed and ref.get_ref() == null
	return _expect(freed and get_nodes_in_group("enemies").is_empty() and _events == cleanup_events, "whole native world/cues/renderer/Hero/Scheduler retire without another callback or surviving enemy group")


func _exit_callback(kind: String, reservation_id: String, reason: String = "") -> Dictionary:
	var renderer: Node3D = _source.call("get_enemy_apparition") as Node3D
	var current: Dictionary = _source.call("state")
	var terminal: Dictionary = _source.call("get_authored_cycle_terminal_receipt")
	return {"kind": kind, "reservation_id": reservation_id, "reason": reason, "owner_inside_tree": _source.is_inside_tree(), "scheduler_inside_tree": _scheduler.is_inside_tree(), "hero_inside_tree": _hero.is_inside_tree(), "renderer_inside_tree": renderer != null and renderer.is_inside_tree(), "status": String(current.get("status", "")), "outcome": String(terminal.get("outcome", "")), "clock_s": _scheduler.get_clock()}
