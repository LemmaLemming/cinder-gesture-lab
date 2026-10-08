class_name Act2RayScoutActor
extends Node3D
## Stationary A2-L1 target adapter; the level owns all phase clocks and threats.
## The root is the reachable low housing. The cosmetic rig has no target group.
## No collider, body cage, autonomous process, player damage or reload award.

signal defeated(actor_id: String)

const VisualScript: Script = preload("res://scripts/acts/act2/ray_scout_visual.gd")
const PHASES: Array[String] = ["idle", "warning", "lock", "active", "recovery", "defeated"]

var hp: float = 30.0
var max_hp: float = 30.0
var actor_id: String = ""
var phase: String = "idle"
var phase_progress: float = 0.0
var direction: Vector3 = Vector3.BACK
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
	if _configured or _retired or _damage_busy or not is_inside_tree() or is_queued_for_deletion():
		return false
	if not is_instance_valid(shared_hero) or not shared_hero.is_inside_tree() or shared_hero.dead:
		return false
	if not is_instance_valid(shared_effects) or not shared_effects.is_inside_tree() or not _valid_actor_id(stable_actor_id) or not _health_valid():
		return false
	_hero = shared_hero
	_effects = shared_effects
	actor_id = stable_actor_id
	_configured = true
	_render_pose(false)
	return true


func present_phase(next_phase: String, normalized_progress: float, exact_direction: Vector3, hit_flash: bool = false) -> bool:
	# The level may pose a paused candidate during coherent restoration. Damage
	# still rejects while paused; this method never advances a clock or emits.
	if _damage_busy or not _context_valid() or not PHASES.has(next_phase):
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
	if _damage_busy or not was_alive or not _context_valid() or get_tree().paused or phase != "recovery":
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
	return _configured and not _retired and is_inside_tree() and not is_queued_for_deletion() and _health_valid() and is_instance_valid(_hero) and _hero.is_inside_tree() and not _hero.dead and is_instance_valid(_effects) and _effects.is_inside_tree() and is_instance_valid(_visual) and not _visual.is_queued_for_deletion()


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
