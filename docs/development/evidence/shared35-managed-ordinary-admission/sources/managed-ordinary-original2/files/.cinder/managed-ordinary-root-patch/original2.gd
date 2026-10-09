extends "res://tests/authored_echo_lifecycle_smoke.gd"
## ORIGINAL security regression reproduction. Run ONLY against the retained
## original Scheduler, before its fix. The native released lifecycle arena
## genuinely registers HP32 source/actual Hero stable ID/floor/renderer.
## No engine/job has been run by this author; all observations are emitted by
## the eventual native job. A vulnerable source must EXIT1, never count as pass.
const OrdinaryGeometry = preload("res://scripts/combat/threat_geometry.gd")
const OrdinaryDifficulty = preload("res://scripts/combat/difficulty.gd")

func _run() -> void:
	root.size = Vector2i(540, 1170)
	print("ORIGINAL managed ordinary-admission regression; expected exit1 on vulnerable Scheduler. No capture/history/body/clock seeds; no campaign claim.")
	var arena: Dictionary = await _arena()
	var before: Dictionary = _original_unit(arena)
	_expect(not before.scheduler.is_empty() and not before.playback.is_empty() and before.journal.stage == "cycle_ready" and before.journal.generation == 1 and before.journal.terminal_receipts.is_empty() and before.scheduler.reservations.is_empty() and before.scheduler.cooldowns.is_empty(), "genuine current native first-ready managed owner has a valid whole-unit snapshot and no ordinary lease/cooldown")
	var response: Dictionary = _response(arena)
	response["world_root"] = arena.world
	var role: Dictionary = OrdinaryDifficulty.new().resolve_role({"raw_damage": 4.0, "windup_s": 0.7, "lock_s": 0.2, "active_s": 0.16, "recovery_s": 2.0, "attack_interval_s": 2.0, "max_hp": 32.0, "move_speed": 0.0}, "standard", {"windup_s": 0.7, "lock_s": 0.2, "recovery_s": 2.0})
	var threat: Dictionary = {"role": role, "geometry": OrdinaryGeometry.circle(arena.actor.global_position, 0.3), "source_stationary": true, "opening_stationary": true, "opening_position": arena.actor.global_position, "cooldown_remaining_s": 0.0}
	paused = false
	var diagnostic: String = arena.scheduler.last_error
	var preview: Dictionary = arena.scheduler.preview_stationary(arena.actor, threat, response)
	_expect(arena.scheduler.last_error == diagnostic, "public prospective stationary query remains diagnostic-pure")
	_expect(not preview.get("accepted", false), "SECURITY: genuinely managed cycle-ready owner must not obtain an ordinary stationary preview")
	var request: Dictionary = arena.scheduler.request_attack(arena.actor, threat, response, preview)
	_expect(not request.get("accepted", false), "SECURITY: paired ordinary request must not admit an out-of-journal lease for the managed owner")
	var after: Dictionary = _original_unit(arena)
	var observation: String = Exact.stringify(_original_wire({"before": before, "preview": preview, "request": request, "after": after}))
	_expect(not observation.is_empty(), "original native diagnostic payload has complete closed exact encoding")
	print("ORIGINAL_MANAGED_ORDINARY_OBSERVATION " + observation)
	_expect(not after.scheduler.is_empty() and EnemySequence.exact_equal(before, after), "SECURITY: ordinary refusal retains original valid journal/snapshot/clock/serial/cooldown/resources")
	await _dispose(arena)
	print("Managed ordinary ORIGINAL regression: %d checks, %d failures; a vulnerable original is expected to fail, no repaired scope claimed" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _original_unit(arena: Dictionary) -> Dictionary:
	var prior: bool = paused
	paused = true
	var bindings: Dictionary = _bindings(arena)
	var scheduler: Dictionary = arena.scheduler.snapshot_state(bindings)
	var scheduler_error: String = arena.scheduler.last_snapshot_error
	var playback: Dictionary = arena.actor.snapshot_state(scheduler, bindings) if not scheduler.is_empty() else {}
	var result: Dictionary = {"clock_s": arena.scheduler.get_clock(), "player": arena.player.snapshot_state(), "scheduler": scheduler, "scheduler_snapshot_error": scheduler_error, "playback": playback, "journal": arena.scheduler.authored_cycle_state(arena.actor), "control": _original_wire(arena.scheduler.source_control_state(arena.actor)), "resources": _original_wire(_resources(arena)), "renderer": _original_wire(arena.actor.get_enemy_apparition().native_pose()), "hp": arena.actor.hp, "dead": arena.actor.dead}
	paused = prior
	return result

func _original_wire(value: Variant) -> Variant:
	# Known bounded native diagnostics, never caller input/authentication data.
	if value is Vector3: return [value.x, value.y, value.z]
	if value is Vector2: return [value.x, value.y]
	if value is Rect2: return [value.position.x, value.position.y, value.size.x, value.size.y]
	if value is Transform3D: return {"origin": _original_wire(value.origin), "x": _original_wire(value.basis.x), "y": _original_wire(value.basis.y), "z": _original_wire(value.basis.z)}
	if value is Basis: return {"x": _original_wire(value.x), "y": _original_wire(value.y), "z": _original_wire(value.z)}
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _original_wire(value[key])
		return result
	if value is Array:
		var result: Array = []
		for entry: Variant in value: result.append(_original_wire(entry))
		return result
	return value
