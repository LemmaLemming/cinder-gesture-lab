class_name Act2RayScoutActor
extends Node3D
## Stationary A2-L1 target adapter; the level owns all phase clocks and threats.
## The root is the reachable low housing. The cosmetic rig has no target group.
## No collider, body cage, autonomous process, player damage or reload award.

signal defeated(actor_id: String)

const VisualScript: Script = preload("res://scripts/acts/act2/ray_scout_visual.gd")
const Codec: GDScript = preload("res://scripts/campaign/snapshot_codec.gd")
const PHASES: Array[String] = ["idle", "warning", "lock", "active", "recovery", "defeated"]
const SNAPSHOT_API_REVISION: String = "act2-ray-scout-snapshot-2"
const SNAPSHOT_SCHEMA_VERSION: int = 2
const DIRECTION_TOLERANCE: float = 0.00001

var hp: float = 30.0
var max_hp: float = 30.0
var actor_id: String = ""
var phase: String = "idle"
var phase_progress: float = 0.0
var direction: Vector3 = Vector3.BACK
var last_snapshot_error: String = ""
# Explicit anchored response for this initial stationary role. Accepted impulses
# neither move the housing nor silently add momentum/stagger/invulnerability.
var knockback_scale: float:
	get:
		return 0.0

var _hero: CinderPlayer
var _effects: PixelEffects
var _visual: Node3D
var _configured: bool = false
var _retired: bool = false
var _damage_busy: bool = false
var _defeat_emitted: bool = false
var _snapshot_busy: bool = false
var _authored_actor_id: String = ""
var _authored_root_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	add_to_group("enemies")
	_visual = VisualScript.new() as Node3D
	_visual.name = "ScoutRig"
	add_child(_visual)
	_render_pose(false)
	set_process(false)
	set_physics_process(false)


func configure(shared_hero: CinderPlayer, shared_effects: PixelEffects, stable_actor_id: String) -> bool:
	# Configure is entry, not a heal/reset. Disarmed instances cannot be revived.
	if _configured or _retired or _damage_busy or _snapshot_busy or not is_inside_tree() or not is_node_ready() or is_queued_for_deletion():
		return false
	if not is_instance_valid(shared_hero) or not shared_hero.is_inside_tree() or shared_hero.dead:
		return false
	if not is_instance_valid(shared_effects) or not shared_effects.is_inside_tree() or not _valid_actor_id(stable_actor_id) or not _health_valid() or not global_position.is_finite():
		return false
	if shared_hero.get_world_3d() != get_world_3d() or shared_effects.get_world_3d() != get_world_3d():
		return false
	_hero = shared_hero
	_effects = shared_effects
	actor_id = stable_actor_id
	_authored_actor_id = stable_actor_id
	_authored_root_position = global_position
	_configured = true
	_render_pose(false)
	return true


func present_phase(next_phase: String, normalized_progress: float, exact_direction: Vector3, hit_flash: bool = false) -> bool:
	# The level may pose a paused candidate during coherent restoration. Damage
	# still rejects while paused. This live setter requires a living hero;
	# snapshot restoration separately redraws a paused dead-hero aggregate.
	if _damage_busy or _snapshot_busy or not _context_valid() or not PHASES.has(next_phase):
		return false
	if not is_finite(normalized_progress) or normalized_progress < 0.0 or normalized_progress > 1.0 or not exact_direction.is_finite():
		return false
	var flat: Vector3 = Vector3(exact_direction.x, 0.0, exact_direction.z)
	if flat.length_squared() <= 0.000001 or (next_phase == "defeated") != (hp <= 0.0):
		return false
	phase = next_phase
	phase_progress = normalized_progress
	direction = flat.normalized()
	_render_pose(hit_flash)
	return true


func take_damage(amount: float, impulse: Vector3) -> Dictionary:
	var was_alive: bool = _health_valid() and hp > 0.0 and not is_queued_for_deletion()
	# target_id preserves the shared accepted-result contract. actor_id is the
	# authored save identity; runtime instance IDs must never enter level saves.
	var result: Dictionary = {"accepted": false, "hp_damage": 0.0, "target_id": get_instance_id(), "target_alive_before_hit": was_alive}
	if _damage_busy or _snapshot_busy or not was_alive or not _context_valid() or get_tree().paused or phase != "recovery":
		return result
	if not is_finite(amount) or amount <= 0.0 or not impulse.is_finite():
		return result
	_damage_busy = true
	var loss: float = minf(hp, amount)
	hp -= loss
	result["accepted"] = loss > 0.0
	result["hp_damage"] = loss
	if hp <= 0.0:
		phase = "defeated"
		phase_progress = 1.0
		_render_pose(false)
		if not _defeat_emitted:
			_defeat_emitted = true
			defeated.emit(actor_id)
	else:
		# The level supplies the next flash/pose update; there is no private timer.
		_render_pose(true)
	_damage_busy = false
	return result


func snapshot_state() -> Dictionary:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty():
		return {}
	_snapshot_busy = true
	var state: Dictionary = {
		"api_revision": SNAPSHOT_API_REVISION, "schema_version": SNAPSHOT_SCHEMA_VERSION,
		"actor_id": actor_id, "max_hp": max_hp, "hp": hp,
		"phase": phase, "phase_progress": phase_progress,
		"direction": Codec.vector3(direction), "root_position": Codec.vector3(global_position),
		"body_yaw": _visual.call("get_body_yaw"),
	}
	last_snapshot_error = _snapshot_value_error(state)
	_snapshot_busy = false
	return state.duplicate(true) if last_snapshot_error.is_empty() else {}


func snapshot_error(snapshot: Dictionary) -> String:
	var error: String = _snapshot_access_error()
	return error if not error.is_empty() else _snapshot_value_error(snapshot)


func restore_state(snapshot: Dictionary) -> bool:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty():
		return false
	_snapshot_busy = true
	last_snapshot_error = _snapshot_value_error(snapshot)
	if last_snapshot_error.is_empty():
		# Validate before copying/mutating. The exact small schema excludes cycles,
		# objects and shared clocks; callers cannot alias accepted direction data.
		var state: Dictionary = snapshot.duplicate(true)
		actor_id = state["actor_id"]
		max_hp = float(state["max_hp"])
		hp = float(state["hp"])
		phase = state["phase"]
		phase_progress = float(state["phase_progress"])
		direction = Codec.read_vector3(state["direction"])
		global_position = _authored_root_position
		# Defeat belongs to the restored timeline. Rebuilding a spent tombstone
		# emits nothing; restoring an earlier live actor permits its later defeat.
		_defeat_emitted = hp <= 0.0
		_visual.call("restore_pose", phase, phase_progress, direction, float(state["body_yaw"]), false)
	_snapshot_busy = false
	return last_snapshot_error.is_empty()


func _snapshot_access_error() -> String:
	if not _bound_context_valid() or not is_node_ready():
		return "Scout snapshots require a configured live actor and bound shared context"
	if not get_tree().paused:
		return "Scout snapshots require a paused aggregate barrier"
	if _damage_busy or _snapshot_busy:
		return "Scout snapshots reject inside actor transactions"
	if not _valid_actor_id(_authored_actor_id) or not _authored_root_position.is_finite():
		return "Scout snapshot authored identity/root is unavailable"
	return ""


func _snapshot_value_error(state: Dictionary) -> String:
	var error: String = Codec.value_error(state)
	if error.is_empty():
		error = Codec.keys_error(state, ["api_revision", "schema_version", "actor_id", "max_hp", "hp", "phase", "phase_progress", "direction", "root_position", "body_yaw"])
	if not error.is_empty():
		return error
	if not state["api_revision"] is String or state["api_revision"] != SNAPSHOT_API_REVISION or not Codec.is_integer(state["schema_version"], SNAPSHOT_SCHEMA_VERSION, SNAPSHOT_SCHEMA_VERSION):
		return "Unsupported Scout snapshot API/schema"
	if not state["actor_id"] is String or state["actor_id"] != _authored_actor_id:
		return "Scout snapshot must match the configured authored actor ID"
	if not Codec.is_number(state["max_hp"]) or float(state["max_hp"]) <= 0.0 or not Codec.in_range(state["hp"], 0.0, float(state["max_hp"])):
		return "Invalid Scout snapshot HP tuple"
	if not state["phase"] is String or not PHASES.has(state["phase"]) or not Codec.in_range(state["phase_progress"], 0.0, 1.0):
		return "Invalid Scout snapshot phase/progress"
	if (state["phase"] == "defeated") != (float(state["hp"]) <= 0.0):
		return "Scout snapshot defeated phase must agree with HP"
	if not Codec.is_vector3(state["direction"]):
		return "Scout snapshot requires a finite JSON direction triple"
	var restored_direction: Vector3 = Codec.read_vector3(state["direction"])
	if restored_direction.y != 0.0 or absf(restored_direction.length_squared() - 1.0) > DIRECTION_TOLERANCE:
		return "Scout snapshot direction must be normalized and planar"
	if not Codec.is_vector3(state["root_position"]) or Codec.read_vector3(state["root_position"]) != _authored_root_position:
		return "Scout snapshot root must match the fixed authored housing"
	if not Codec.is_number(state["body_yaw"]):
		return "Scout snapshot body yaw must be a finite number"
	var pose_error: String = _visual.call("restore_pose_error", state["phase"], float(state["phase_progress"]), restored_direction, float(state["body_yaw"]))
	if not pose_error.is_empty():
		return pose_error
	return ""


func is_armed() -> bool:
	return _configured and not _retired


func disarm() -> void:
	_configured = false
	_retired = true
	_hero = null
	_effects = null
	# Keep the single group until tree exit so a lethal accepted result can still
	# receive the shared player's once-per-action credit after its callback.
	# The owner frees this subtree; there are no external signal connections.


func cleanup() -> void:
	disarm()


func _context_valid() -> bool:
	return _bound_context_valid() and _health_valid() and not _hero.dead


func _bound_context_valid() -> bool:
	# Paused shell restoration applies the shared player first, including death.
	# A dead bound hero prevents gameplay but does not invalidate actor transport.
	return _configured and not _retired and is_inside_tree() and not is_queued_for_deletion() and is_instance_valid(_hero) and _hero.is_inside_tree() and not _hero.is_queued_for_deletion() and _hero.get_world_3d() == get_world_3d() and is_instance_valid(_effects) and _effects.is_inside_tree() and not _effects.is_queued_for_deletion() and _effects.get_world_3d() == get_world_3d() and is_instance_valid(_visual) and _visual.is_inside_tree() and not _visual.is_queued_for_deletion()


func _health_valid() -> bool:
	return is_finite(max_hp) and max_hp > 0.0 and is_finite(hp) and hp >= 0.0 and hp <= max_hp


func _valid_actor_id(candidate: String) -> bool:
	if candidate.is_empty() or candidate.length() > 128:
		return false
	var identifier := RegEx.new()
	identifier.compile("^[A-Za-z0-9][A-Za-z0-9_:/.-]*$")
	var matched: RegExMatch = identifier.search(candidate)
	return matched != null and matched.get_string() == candidate


func _render_pose(hit_flash: bool) -> void:
	if is_instance_valid(_visual):
		_visual.call("pose", phase, phase_progress, direction, hit_flash)


func _exit_tree() -> void:
	disarm()
	remove_from_group("enemies")
