extends "res://scripts/acts/act2/ray_scout_actor.gd"
## L2-only cosmetic adapter. Gameplay/damage gates remain inherited and close
## on hero death; the actual consumer may still commit its final idle pose.

func present_phase(next_phase: String, normalized_progress: float, exact_direction: Vector3, hit_flash: bool = false) -> bool:
	# A dead shared hero closes inherited gameplay/damage gates but does not
	# freeze a living actor's final cosmetic state. Parent supplies
	# the actual consumer phase; paused restore uses the same exact committed pose.
	if _damage_busy or _snapshot_busy or not _bound_context_valid() or not _health_valid() or not PHASES.has(next_phase): return false
	if not is_finite(normalized_progress) or normalized_progress < 0.0 or normalized_progress > 1.0 or not exact_direction.is_finite(): return false
	var flat: Vector3 = Vector3(exact_direction.x, 0.0, exact_direction.z)
	if flat.length_squared() <= 0.000001 or (next_phase == "defeated") != (hp <= 0.0): return false
	phase = next_phase
	phase_progress = normalized_progress
	direction = flat.normalized()
	_render_pose(hit_flash)
	return true
