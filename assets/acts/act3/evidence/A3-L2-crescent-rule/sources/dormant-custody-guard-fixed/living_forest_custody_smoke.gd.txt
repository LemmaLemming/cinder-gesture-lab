extends "res://tests/acts/act3/living_forest_route_smoke.gd"
## Narrow negative custody regressions on actual paused authored Forest units.
## Only copied snapshot dictionaries are forged. No forged unit is restored,
## and no Hero/source pose, HP, phase, clock, physics or runtime flag is written.
## --dormant-only (default): fresh arrival, future Stalker death/partial HP.
## --chronology-route: inherited genuine full route and its real history units.

const DormantId: String = "l2-priority-stalker"

var _custody_selector: String = "--dormant-only"
var _chronology_seen: Dictionary = {}
var _last_probe_unsafe: bool = false
var _first_custody_failure: String = ""


func _options() -> String:
	var selected: bool = false
	for argument: String in OS.get_cmdline_user_args():
		if argument not in ["--dormant-only", "--chronology-route"] or selected:
			return "unsupported or repeated custody selector: " + argument
		_custody_selector = argument
		selected = true
	return ""


func _run() -> void:
	var error: String = _options()
	if error.is_empty() and _custody_selector == "--chronology-route":
		await super._run()
		return
	if error.is_empty(): error = _select_kit()
	if error.is_empty(): error = await _prepare()
	if _expect(error.is_empty(), "actual fresh paused nine-source arrival exists before any entry", error):
		error = _dormant_cases()
	if not error.is_empty():
		if _failures == 0: _expect(false, "custody fixture stops at its first meaningful setup failure", error)
		print("FIRST MEANINGFUL CUSTODY FAILURE: ", error)
	await _dispose()
	_finish()


func _dormant_cases() -> String:
	var original: Dictionary = _custody_unit()
	var error: String = _original_pair_error(original)
	if not _expect(error.is_empty(), "original actual arrival pair validates without mutation", error): return error
	var actor: Dictionary = original.level.local.sources[DormantId].actor
	var route: Dictionary = original.level.local.route
	if not paused or float(original.level.local.scheduler.clock_s) != 0.0 or not route.entries.is_empty() or not route.deaths.is_empty() or actor.dead or actor.phase != "idle" or int(actor.cycle) != 0 or not String(actor.reservation_id).is_empty() or float(actor.hp) != float(actor.max_hp):
		return "future actual Stalker is not the untouched full-HP dormant arrival source"

	# Match the typed tombstone and route record completely; rejection must be
	# the missing entry custody, rather than an intentionally inconsistent flag.
	var forged: Dictionary = original.level.duplicate(true)
	var tombstone: Dictionary = forged.local.sources[DormantId].actor
	tombstone.hp = 0.0
	tombstone.dead = true
	tombstone.death_emitted = true
	tombstone.phase = "defeated"
	tombstone.velocity = Codec.vector3(Vector3.ZERO)
	tombstone.cooldown_until_s = 0.0
	tombstone.stagger_until_s = 0.0
	forged.local.route.deaths[DormantId] = {"clock_s": forged.local.scheduler.clock_s, "source_position": tombstone.position.duplicate()}
	var first_error: String = _require_rejection("unentered future Stalker matching cycle-zero tombstone/death record", original, forged)
	if _last_probe_unsafe: return first_error

	# A separate pristine copy retains all living flags and no death record.
	# Even one HP of damage cannot predate the future court's actual entry.
	forged = original.level.duplicate(true)
	forged.local.sources[DormantId].actor.hp = float(actor.max_hp) - 1.0
	error = _require_rejection("unentered future Stalker partial HP with otherwise untouched live state", original, forged)
	return first_error if not first_error.is_empty() else error


func _checkpoint_pair(index: int, after_clear: bool) -> String:
	var error: String = await super._checkpoint_pair(index, after_clear)
	if not error.is_empty() or _custody_selector != "--chronology-route" or index != 1 or after_clear:
		return error
	_game.call("open_bench")
	await process_frame
	await process_frame
	var original: Dictionary = _custody_unit()
	error = _original_pair_error(original)
	if not _expect(error.is_empty(), "genuine second-entry whole unit validates before equal-clock forgery", error): return error
	var entries: Array = original.level.local.route.entries
	if not paused or entries.size() != 2 or float(entries[1].clock_s) <= float(entries[0].clock_s):
		return "genuine second entry did not retain two distinct increasing native entry clocks"
	var forged: Dictionary = original.level.duplicate(true)
	forged.local.route.entries[1].clock_s = entries[0].clock_s
	_chronology_seen["equal_adjacent_entry_clock"] = true
	error = _require_rejection("equal adjacent entry clocks in a real two-entry checkpoint unit", original, forged)
	_game.call("resume_lab")
	# Independent negative assertions may fail before the fix, but the actual
	# unchanged route still supplies later genuine death/contact units. A pure
	# validator that mutates anything stops the inherited driver immediately.
	return error if _last_probe_unsafe else ""


func _contact_exit() -> String:
	var error: String = await super._contact_exit()
	if not error.is_empty() or _custody_selector != "--chronology-route": return error
	_game.call("open_bench")
	await process_frame
	await process_frame
	var original: Dictionary = _custody_unit()
	error = _original_pair_error(original)
	if not _expect(error.is_empty(), "genuine nine-death spent-contact whole unit validates before chronology forgeries", error): return error
	var route: Dictionary = original.level.local.route
	var entry_index: int = SourceEntries[SourceIds.find(DormantId)]
	if not paused or route.entries.size() != EntryIds.size() or route.deaths.size() != SourceIds.size() or route.exit_state != "spent" or route.contact.is_empty() or not route.deaths.has(DormantId):
		return "genuine full route did not supply all nine deaths and its actual spent contact"
	var entry_clock: float = float(route.entries[entry_index].clock_s)
	var death_clock: float = float(route.deaths[DormantId].clock_s)
	if entry_clock <= 0.0 or death_clock < entry_clock:
		return "genuine priority Stalker death does not follow its positive actual entry clock"
	var forged: Dictionary = original.level.duplicate(true)
	forged.local.route.deaths[DormantId].clock_s = entry_clock * 0.5
	_chronology_seen["death_before_entry"] = true
	error = _require_rejection("real priority Stalker death record predating its actual entry", original, forged)
	if _last_probe_unsafe: return error

	var last_death_clock: float = 0.0
	for id: String in SourceIds:
		last_death_clock = maxf(last_death_clock, float(route.deaths[id].clock_s))
	if last_death_clock <= 0.0 or float(route.contact.clock_s) < last_death_clock:
		return "genuine exit contact does not follow the actual final source death"
	forged = original.level.duplicate(true)
	forged.local.route.contact.clock_s = maxf(0.0, last_death_clock - _tick_s())
	_chronology_seen["contact_before_final_death"] = true
	error = _require_rejection("real spent contact record predating the actual final source death", original, forged)
	_game.call("resume_lab")
	return error if _last_probe_unsafe else ""


func _final_error(count: int) -> String:
	var error: String = super._final_error(count)
	if not error.is_empty() or _custody_selector != "--chronology-route": return error
	return "" if _chronology_seen.size() == 3 else "real full route did not exercise all three narrow chronology negatives: " + str(_chronology_seen.keys())


func _require_rejection(label: String, original: Dictionary, forged_level: Dictionary) -> String:
	_last_probe_unsafe = false
	var supplied: Dictionary = forged_level.duplicate(true)
	var paired_error: String = _level.snapshot_error_with_player(forged_level, original.hero)
	var live_error: String = _level.snapshot_error(forged_level)
	var after: Dictionary = _custody_unit()
	var original_error: String = _original_pair_error(after)
	var unchanged: bool = _exact(original, after) and _exact(supplied, forged_level)
	var diagnostic: String = "paired=" + paired_error + "; live=" + live_error + "; unchanged=" + str(unchanged) + "; original=" + original_error
	_expect(unchanged and original_error.is_empty(), label + " pure validation preserves original whole unit and copied input", diagnostic)
	if not unchanged or not original_error.is_empty():
		_last_probe_unsafe = true
		return label + ": pure validation changed or invalidated the original: " + diagnostic
	var rejected: bool = not paired_error.is_empty() and not live_error.is_empty()
	_expect(rejected, label + " is rejected by saved-Hero and actual-Hero pure validation", diagnostic)
	if not rejected and _first_custody_failure.is_empty(): _first_custody_failure = label + ": invalid custody was accepted; " + diagnostic
	return "" if rejected else label + ": invalid custody was accepted; " + diagnostic


func _original_pair_error(unit: Dictionary) -> String:
	if not unit.get("hero") is Dictionary or not unit.get("level") is Dictionary or unit.hero.is_empty() or unit.level.is_empty():
		return "actual paused unit capture rejected: " + _hero.last_snapshot_error + "; " + _level.last_snapshot_error
	var error: String = _hero.snapshot_error(unit.hero)
	if error.is_empty(): error = _level.snapshot_error_with_player(unit.level, unit.hero)
	if error.is_empty(): error = _level.snapshot_error(unit.level)
	return error


func _custody_unit() -> Dictionary:
	var native: Dictionary = {}
	for id: String in SourceIds:
		var source: Node3D = _sources[id] as Node3D
		var body: CollisionShape3D = source.get_node("BodyCollision") as CollisionShape3D
		native[id] = {"transform": source.global_transform, "physics_enabled": source.is_physics_processing(), "visible": source.visible, "enemy_group": source.is_in_group("enemies"), "body_disabled": body.disabled, "layer": source.get("collision_layer"), "mask": source.get("collision_mask"), "cue": _cue(id).state()}
	var camera: Camera3D = _game.get("camera") as Camera3D
	return {"hero": _hero.snapshot_state(), "level": _level.snapshot_state(), "hero_transform": _hero.global_transform, "hero_velocity": _hero.velocity, "native_sources": native, "scheduler": _scheduler.snapshot_state(_level.call("scheduler_bindings")), "route_state": _level.call("state"), "events": _events.duplicate(true), "death_events": _death_events.duplicate(true), "actions": _actions.duplicate(true), "checkpoints": _checkpoints.duplicate(), "exit_cue": _exit_cue.state(), "camera_transform": camera.global_transform if camera != null else Transform3D.IDENTITY, "viewport_size": root.size}


func _finish() -> void:
	print("Living Forest custody: selector=", _custody_selector, " checks=", _checks, " failures=", _failures, "; copied snapshots only; no forged restore")
	if not _first_custody_failure.is_empty(): print("FIRST NEGATIVE CUSTODY FAILURE: ", _first_custody_failure)
	super._finish()
