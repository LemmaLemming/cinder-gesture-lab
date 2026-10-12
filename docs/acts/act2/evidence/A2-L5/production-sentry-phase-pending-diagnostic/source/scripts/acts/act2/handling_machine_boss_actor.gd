extends "res://scripts/acts/act2/weybridge_scout_actor.gd"
## B02 has the same total HP30 as a regular source. Two finite phase pools
## share that remaining health; a committed phase boundary consumes overkill.
## The actor never refills health or directly changes player/consumer clocks.
const BossVisual: Script = preload("res://scripts/acts/act2/handling_machine_boss_visual.gd")
const PHASE_BOUNDARY_HP: float = 15.0
signal phase_boundary_reached(actor_id: String)
var boss_phase: int = 1
var transition_pending: bool = false
var tool_action: String = "reach"
var _phase_damage_busy: bool = false

func _ready() -> void:
	add_to_group("enemies")
	_visual = BossVisual.new() as Node3D
	_visual.name = "BossRig"
	add_child(_visual)
	_visual.call("set_action", tool_action)
	_render_pose(false)
	set_process(false)
	set_physics_process(false)

func set_tool_action(action: String) -> bool:
	if _phase_damage_busy or _damage_busy or _snapshot_busy or action not in ["reach", "place"]:
		return false
	if not is_instance_valid(_visual) or not _visual.call("set_action", action):
		return false
	tool_action = action
	_render_pose(false)
	return true

func present_phase(next_phase: String, normalized_progress: float, exact_direction: Vector3, hit_flash: bool = false) -> bool:
	if exact_direction != Vector3.BACK or _phase_damage_busy: return false
	return super.present_phase(next_phase, normalized_progress, exact_direction, hit_flash)

func _snapshot_access_error() -> String:
	return "B02 snapshots reject inside the complete phase-damage transaction" if _phase_damage_busy else super._snapshot_access_error()

func take_damage(amount: float, impulse: Vector3) -> Dictionary:
	if _phase_damage_busy or transition_pending or not is_finite(amount) or amount <= 0.0:
		return {"accepted": false, "hp_damage": 0.0, "target_id": get_instance_id(), "target_alive_before_hit": hp > 0.0}
	var bounded_amount: float = minf(amount, maxf(hp - PHASE_BOUNDARY_HP, 0.0)) if boss_phase == 1 else amount
	_phase_damage_busy = true
	var result: Dictionary = super.take_damage(bounded_amount, impulse)
	if result.get("accepted", false) and boss_phase == 1 and hp == PHASE_BOUNDARY_HP:
		# Close before observers: the same input's second action cannot silently
		# skip the earned phase checkpoint or add damage during its transaction.
		transition_pending = true
		phase_boundary_reached.emit(actor_id)
	_phase_damage_busy = false
	return result

func commit_phase_two() -> bool:
	if _phase_damage_busy or _damage_busy or _snapshot_busy or not _context_valid() or boss_phase != 1 or not transition_pending or hp != PHASE_BOUNDARY_HP:
		return false
	boss_phase = 2
	transition_pending = false
	return true

func snapshot_state() -> Dictionary:
	var base: Dictionary = super.snapshot_state()
	if base.is_empty(): return {}
	var state: Dictionary = {"version": 1, "actor": base, "boss_phase": boss_phase, "transition_pending": transition_pending, "tool_action": tool_action}
	last_snapshot_error = _boss_value_error(state)
	return state if last_snapshot_error.is_empty() else {}

func snapshot_error(state: Dictionary) -> String:
	if _phase_damage_busy: return "B02 snapshots reject inside the complete phase-damage transaction"
	var error: String = _boss_value_error(state)
	return error if not error.is_empty() else super.snapshot_error(state.actor)

func restore_state(state: Dictionary) -> bool:
	last_snapshot_error = snapshot_error(state)
	if not last_snapshot_error.is_empty(): return false
	# Parent has already pure-preflighted the whole aggregate. Cosmetic action
	# is selected before its exact base pose, with no signal or simulation tick.
	if not _visual.call("set_action", state.tool_action): return false
	if not super.restore_state(state.actor): return false
	boss_phase = state.boss_phase
	transition_pending = state.transition_pending
	tool_action = state.tool_action
	return true

func _boss_value_error(state: Dictionary) -> String:
	var error: String = Codec.value_error(state)
	if not error.is_empty(): return error
	error = Codec.keys_error(state, ["version", "actor", "boss_phase", "transition_pending", "tool_action"])
	if not error.is_empty(): return error
	if not state.version is int or state.version != 1 or not state.actor is Dictionary or not state.boss_phase is int or state.boss_phase not in [1, 2] or not state.transition_pending is bool or not state.tool_action is String or state.tool_action not in ["reach", "place"]:
		return "Invalid B02 phase/action envelope"
	if not Codec.is_number(state.actor.get("hp")) or state.actor.get("max_hp") != 30.0:
		return "B02 retains authored total HP30"
	var remaining: float = state.actor.hp
	if state.boss_phase == 1 and (remaining < PHASE_BOUNDARY_HP or state.transition_pending != (remaining == PHASE_BOUNDARY_HP)):
		return "B02 first phase must retain its exact closed threshold"
	if state.boss_phase == 2 and (remaining > PHASE_BOUNDARY_HP or state.transition_pending):
		return "B02 second phase cannot refill HP or retain a first-phase transaction"
	return ""
