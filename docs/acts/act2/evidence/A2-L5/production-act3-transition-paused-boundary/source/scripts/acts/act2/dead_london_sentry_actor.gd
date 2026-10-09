extends "res://scripts/acts/act2/weybridge_scout_actor.gd"
## B05 GREYBOX ONLY: one anchored ordinary-primary low joint, finite30 HP.
## The inherited Scout rig is a temporary functional placeholder, not selected
## tripod art. Parent owns actual ray/foot clocks, one damage-window gate,
## InteractionCue, isolated attack receipts and earned checkpoint progression.
## No new Controller, private Player write, body movement or timing is added.
const ExactJson: Script = preload("res://scripts/campaign/exact_json.gd")
const PHASE_BOUNDARY_HP: float = 15.0
const SOURCE_API: String = "act2-sentry-source-1"
signal phase_boundary_reached(actor_id: String)
var boss_phase: int = 1
var transition_pending: bool = false
var _phase_damage_busy: bool = false
var _joint_cue: CinderInteractionCue
var _joint_cue_bound: bool = false

func bind_joint_cue(cue: CinderInteractionCue) -> bool:
	if _joint_cue_bound or _phase_damage_busy or _damage_busy or _snapshot_busy or not _bound_context_valid() or not is_instance_valid(cue) or not cue.is_inside_tree() or not cue.is_node_ready() or cue.is_queued_for_deletion() or cue.get_world_3d() != get_world_3d():
		return false
	_joint_cue = cue
	_joint_cue_bound = true
	return true

func present_phase(next_phase: String, normalized_progress: float, exact_direction: Vector3, hit_flash: bool = false) -> bool:
	if _phase_damage_busy: return false
	return super.present_phase(next_phase, normalized_progress, exact_direction, hit_flash)

func _snapshot_access_error() -> String:
	return "B05 snapshots reject inside the complete phase-damage transaction" if _phase_damage_busy else super._snapshot_access_error()

func take_damage(amount: float, impulse: Vector3) -> Dictionary:
	if _phase_damage_busy or transition_pending or not is_finite(amount) or amount <= 0.0:
		return {"accepted": false, "hp_damage": 0.0, "target_id": get_instance_id(), "target_alive_before_hit": hp > 0.0}
	var bounded_amount: float = minf(amount, maxf(hp - PHASE_BOUNDARY_HP, 0.0)) if boss_phase == 1 else amount
	_phase_damage_busy = true
	var result: Dictionary = super.take_damage(bounded_amount, impulse)
	if result.get("accepted", false) and boss_phase == 1 and hp == PHASE_BOUNDARY_HP:
		# Close before observers. Parent spends the actual cue and records the
		# real damage. Exactly the authored solo foot introduction may remain
		# before phase2; no extra HP, wave or hidden live opening is created.
		transition_pending = true
		phase_boundary_reached.emit(actor_id)
	_phase_damage_busy = false
	return result

func commit_phase_two() -> bool:
	# Parent has already verified/drained the actual isolated ray+foot receipts
	# and consumers. This actor validates its own finite earned pool only.
	if _phase_damage_busy or _damage_busy or _snapshot_busy or not _context_valid() or boss_phase != 1 or not transition_pending or hp != PHASE_BOUNDARY_HP:
		return false
	var response: Dictionary = _hero.get_threat_response_state()
	if not response.get("stable", false) or not response.motion.get("grounded", false) or _hero.action_in_progress(): return false
	boss_phase = 2
	transition_pending = false
	phase = "idle"
	phase_progress = 0.0
	_render_pose(false)
	return true

func snapshot_state() -> Dictionary:
	var base: Dictionary = super.snapshot_state()
	if base.is_empty(): return {}
	var state: Dictionary = {"version": 1, "actor": base, "boss_phase": boss_phase, "transition_pending": transition_pending}
	last_snapshot_error = _boss_value_error(state)
	return state if last_snapshot_error.is_empty() else {}

func snapshot_error(state: Dictionary) -> String:
	if _phase_damage_busy: return "B05 snapshots reject inside the complete phase-damage transaction"
	var error: String = _boss_value_error(state)
	return error if not error.is_empty() else super.snapshot_error(state.actor)

func restore_state(state: Dictionary) -> bool:
	last_snapshot_error = snapshot_error(state)
	if not last_snapshot_error.is_empty(): return false
	if not super.restore_state(state.actor): return false
	boss_phase = int(state.boss_phase)
	transition_pending = state.transition_pending
	# Base restore already committed the exact saved body yaw and pose.
	return true

func source_snapshot_state() -> Dictionary:
	# Pure live/paused metadata view, not native actor capture. Actual actor
	# snapshot_state remains paused and transactional. Native cue state is
	# read directly; no independent opening-state variable or clock exists.
	# Damage gates read this pure custody view inside native damage; only the
	# full paused actor capture rejects those transactions.
	if _snapshot_busy or not _bound_context_valid() or not _health_valid() or not _cue_live(): return {}
	var cue: Dictionary = _joint_cue.state()
	var result: Dictionary = {"api_revision": SOURCE_API, "source_id": actor_id, "root_position": Codec.vector3(global_position), "armed": is_armed(), "phase_pending": transition_pending, "defeated": hp <= 0.0, "opening_state": cue.get("state", "")}
	return result if source_snapshot_error(result).is_empty() else {}

func source_snapshot_error(state: Dictionary) -> String:
	# Prospective shape/identity only. Parent independently validates full
	# saved actor HP/phase, both consumers and native cue, then derives this
	# view. Driver commit separately compares the actual restored projection.
	if not _bound_context_valid() or not _cue_live(): return "B05 source needs its actual configured recipient and parent-owned cue"
	var error: String = Codec.value_error(state)
	if error.is_empty(): error = Codec.keys_error(state, ["api_revision", "source_id", "root_position", "armed", "phase_pending", "defeated", "opening_state"])
	if not error.is_empty(): return error
	if state.api_revision != SOURCE_API or not state.source_id is String or state.source_id != _authored_actor_id or not Codec.is_vector3(state.root_position) or not _same_exact(state.root_position, Codec.vector3(_authored_root_position)):
		return "B05 source projection retains exact configured identity/root"
	if not state.armed is bool or not state.armed or not state.phase_pending is bool or not state.defeated is bool or not state.opening_state is String or state.opening_state not in ["clear", "available", "active", "spent"]:
		return "Invalid B05 source projection flags/cue state"
	if (state.phase_pending and state.defeated) or ((state.phase_pending or state.defeated) and state.opening_state != "spent"):
		return "Pending/spent B05 brace cannot advertise a fresh available opening"
	return ""

func _boss_value_error(state: Dictionary) -> String:
	var error: String = Codec.value_error(state)
	if error.is_empty(): error = Codec.keys_error(state, ["version", "actor", "boss_phase", "transition_pending"])
	if not error.is_empty(): return error
	if not Codec.is_integer(state.version, 1, 1) or not state.actor is Dictionary or not Codec.is_integer(state.boss_phase, 1, 2) or not state.transition_pending is bool or not Codec.is_number(state.actor.get("hp")) or state.actor.get("max_hp") != 30.0:
		return "Invalid B05 finite pool envelope"
	var remaining: float = float(state.actor.hp)
	if state.boss_phase == 1 and (remaining < PHASE_BOUNDARY_HP or state.transition_pending != (remaining == PHASE_BOUNDARY_HP)):
		return "B05 first pool retains its exact closed threshold"
	if state.boss_phase == 2 and (remaining > PHASE_BOUNDARY_HP or state.transition_pending):
		return "B05 second pool cannot refill health or retain first-pool pending state"
	return ""

func _cue_live() -> bool:
	return _joint_cue_bound and is_instance_valid(_joint_cue) and _joint_cue.is_inside_tree() and _joint_cue.is_node_ready() and not _joint_cue.is_queued_for_deletion() and _joint_cue.get_world_3d() == get_world_3d()

func disarm() -> void:
	_joint_cue = null
	super.disarm()

static func _same_exact(left: Variant, right: Variant) -> bool:
	var encoded: String = ExactJson.stringify(left)
	return not encoded.is_empty() and encoded == ExactJson.stringify(right)
