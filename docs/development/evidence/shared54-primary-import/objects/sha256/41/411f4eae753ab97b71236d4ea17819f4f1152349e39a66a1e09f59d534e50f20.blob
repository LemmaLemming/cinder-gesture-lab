extends "res://tests/lane_mechanism_smoke.gd"
## Focused shared Lane lifetime edge only. Root executes via dev.py.
## Real configured/bound native World/Player/Scheduler, admitted warning cycles.
## No clock/phase/cue/HP/pose writes and no detached Lane.state() calls.
## Detached phase/status reads are diagnostics; state() remains a live observer.


func _run() -> void:
	create_timer(60.0, true).timeout.connect(func() -> void:
		push_error("Lane detached clear watchdog expired")
		quit(1)
	)
	await _normal_living_clear()
	await _removed_child_clear()
	await _whole_parent_exit_clear()
	paused = false
	_expect(get_nodes_in_group("required_cues").is_empty(), "focused native worlds leave no required cues")
	print("Lane detached clear smoke: %d checks, %d failures; live clear, detached child clear, parent exit hook, paused native resources and idempotent cleanup only" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _admitted_warning(arena: Dictionary, id: String) -> bool:
	await _ticks(5)
	var mechanism: CinderLaneMechanism = arena.mechanism
	var scheduler: CinderThreatScheduler = arena.scheduler
	var hero: CinderPlayer = arena.hero
	var began: bool = scheduler.begin_encounter("standard", id)
	_expect(began and hero.is_on_floor() and not hero.dead, id + " actual supported Hero and fresh fixed encounter")
	if not began: return false
	var answer: Dictionary = mechanism.start("hero", World.context(arena, id))
	var accepted: bool = answer.get("accepted", false)
	_expect(accepted, id + " genuine native ordinary proof admits warning: " + mechanism.last_error)
	if not accepted: return false
	var live: Dictionary = mechanism.state()
	_expect(live.status == "running" and live.phase == "warning" and live.cycle == 1 and scheduler.reservations().size() == 1 and mechanism.get_cue().state().phase == "warning", id + " original warning lease and required cue are real")
	paused = true
	await process_frame
	return true


func _paused_native(arena: Dictionary) -> Dictionary:
	var hero: CinderPlayer = arena.hero
	var scheduler: CinderThreatScheduler = arena.scheduler
	# Local transform is valid both before and after physical whole-parent removal.
	return {"hp": hero.hp, "pose": hero.transform, "velocity": hero.velocity, "shells": hero.shells, "action_clock_s": hero.get_world_action_clock(), "scheduler_clock_s": scheduler.get_clock()}


func _detached_diagnostics(mechanism: CinderLaneMechanism) -> Dictionary:
	# Do not turn public live-world state() into a detached-position API.
	return {"phase": mechanism.get("_phase"), "status": mechanism.get("_status"), "cycle": mechanism.get("_cycle"), "last_cancel_reason": mechanism.get("_last_cancel_reason"), "cue": mechanism.get_cue().state()}


func _normal_living_clear() -> void:
	paused = false
	var arena: Dictionary = World.create(self)
	if not await _admitted_warning(arena, "detached-live-clear"):
		await _dispose(arena)
		return
	var mechanism: CinderLaneMechanism = arena.mechanism
	var scheduler: CinderThreatScheduler = arena.scheduler
	var before: Dictionary = _paused_native(arena)
	var source: Vector3 = mechanism.global_position
	var events: Array[Dictionary] = []
	mechanism.state_changed.connect(func(value: Dictionary) -> void: events.append(value.duplicate(true)))
	_expect(mechanism.clear("live_exit"), "public living clear succeeds under actual pause")
	_expect(events.size() == 1 and events[0].phase == "clear" and events[0].status == "cancelled" and events[0].source_position == source, "living clear preserves exactly one correct native world-state notification")
	_expect(mechanism.state().phase == "clear" and mechanism.get_cue().state().phase == "clear" and scheduler.reservations().is_empty(), "living clear removes its lease and required cue")
	await process_frame
	_expect(paused and _paused_native(arena) == before, "living clear preserves actual paused Hero HP/pose/resources and Scheduler clock")
	_expect(mechanism.clear("live_exit") and events.size() == 1, "repeated living clear has no duplicate phase notification")
	await _dispose(arena)


func _removed_child_clear() -> void:
	paused = false
	var arena: Dictionary = World.create(self)
	if not await _admitted_warning(arena, "detached-child-clear"):
		await _dispose(arena)
		return
	var mechanism: CinderLaneMechanism = arena.mechanism
	var scheduler: CinderThreatScheduler = arena.scheduler
	var before: Dictionary = _paused_native(arena)
	var events: Array[Dictionary] = []
	mechanism.state_changed.connect(func(value: Dictionary) -> void: events.append(value.duplicate(true)))
	arena.root.remove_child(mechanism)
	_expect(not mechanism.is_inside_tree() and not mechanism.get_cue().is_inside_tree() and scheduler.reservations().is_empty(), "physical child removal retires the actual warning lease")
	_expect(mechanism.clear("detached_exit"), "public clear accepts removed child cleanup")
	var cleared: Dictionary = _detached_diagnostics(mechanism)
	_expect(cleared.phase == "clear" and cleared.status == "cancelled" and cleared.cue.phase == "clear" and scheduler.reservations().is_empty(), "removed child clear retires phase/cue without detached world-state getter")
	_expect(events.is_empty(), "removed child clear emits no detached world-state notification")
	await process_frame
	_expect(paused and _paused_native(arena) == before, "removed child clear preserves actual paused Hero HP/pose/resources and Scheduler clock")
	_expect(mechanism.clear("detached_exit") and _detached_diagnostics(mechanism) == cleared and events.is_empty(), "repeated removed child clear is idempotent and notification-free")
	var mechanism_ref: WeakRef = weakref(mechanism)
	var cue_ref: WeakRef = weakref(mechanism.get_cue())
	mechanism.free()
	_expect(mechanism_ref.get_ref() == null and cue_ref.get_ref() == null, "detached native mechanism and cue free completely")
	await _dispose(arena)


func _whole_parent_exit_clear() -> void:
	paused = false
	var arena: Dictionary = World.create(self)
	if not await _admitted_warning(arena, "detached-parent-clear"):
		await _dispose(arena)
		return
	var mechanism: CinderLaneMechanism = arena.mechanism
	var scheduler: CinderThreatScheduler = arena.scheduler
	var before: Dictionary = _paused_native(arena)
	var events: Array[Dictionary] = []
	var hook: Array[Dictionary] = []
	mechanism.state_changed.connect(func(value: Dictionary) -> void: events.append(value.duplicate(true)))
	# The actual parent's exit signal runs after its child has left the tree,
	# matching a CinderLevel parent cleanup hook following child _exit_tree.
	arena.root.tree_exiting.connect(func() -> void:
		hook.append({"child_detached": not mechanism.is_inside_tree(), "accepted": mechanism.clear("parent_exit")})
	)
	root.remove_child(arena.root)
	_expect(hook.size() == 1 and hook[0].child_detached and hook[0].accepted, "whole-parent exit invokes public clear after actual child tree exit")
	var cleared: Dictionary = _detached_diagnostics(mechanism)
	_expect(cleared.phase == "clear" and cleared.cue.phase == "clear" and scheduler.reservations().is_empty() and events.is_empty(), "parent exit clears actual phase/cue/lease without detached world-state publication")
	await process_frame
	_expect(paused and _paused_native(arena) == before, "whole-parent exit preserves actual paused Hero HP/local pose/resources and Scheduler clock")
	_expect(mechanism.clear("parent_exit") and _detached_diagnostics(mechanism) == cleared and events.is_empty(), "parent hook cleanup remains idempotent")
	var world_ref: WeakRef = weakref(arena.root)
	var hero_ref: WeakRef = weakref(arena.hero)
	var scheduler_ref: WeakRef = weakref(scheduler)
	var mechanism_ref: WeakRef = weakref(mechanism)
	var cue_ref: WeakRef = weakref(mechanism.get_cue())
	arena.root.free()
	_expect(world_ref.get_ref() == null and hero_ref.get_ref() == null and scheduler_ref.get_ref() == null and mechanism_ref.get_ref() == null and cue_ref.get_ref() == null, "removed whole native parent/Player/Scheduler/Lane/cue free completely")
