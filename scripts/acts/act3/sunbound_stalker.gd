class_name CinderAct3SunboundStalker
extends CharacterBody3D
## Provisional A3-L1 living source. Shared scheduler owns every leased motion
## and deadline; this consumer owns contact opportunity, art and local state.

signal died(where: Vector3)
signal state_changed(source_state: Dictionary)
signal hit_resolved(result: Dictionary)

const Art = preload("res://scripts/acts/act3/stalker_art.gd")
const Cue = preload("res://scripts/cues/threat_cue.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const API_REVISION: String = "act3-stalker-snapshot-3"
const DEFAULT_ROLE: Dictionary = {"id": "A3-E1", "raw_damage": 12.0, "max_hp": 36.0, "windup_s": 1.35, "lock_s": 0.45, "active_s": 0.30, "recovery_s": 2.0, "attack_interval_s": 3.7, "move_speed": 2.8, "provisional_unplaytested": true}
const DEFAULT_FLOORS: Dictionary = {"windup_s": 1.35, "lock_s": 0.45, "recovery_s": 2.0}
const TUNING: Dictionary = {"capsule_radius": 0.32, "capsule_height": 1.45, "capsule_center_y": 0.73, "lunge_distance": 3.0, "lunge_speed": 12.0, "damage_radius": 0.42, "approach_acceleration": 8.0, "brace_min_distance": 1.8, "brace_max_distance": 2.0, "sun_bias_degrees": 20.0, "brace_facing_min_dot": 0.99999, "approach_turn_radians_s": 1.2, "gravity": 24.0, "request_retry_s": 0.25, "contact_height_tolerance": 1.35, "stagger_drag": 5.0}
const COMMIT_KEYS: Array[String] = ["sun_choice", "source_position", "hero_position", "facing"]
const COMMIT_VECTOR_KEYS: Array[String] = ["source_position", "hero_position", "facing"]
const EXCHANGE_KEYS: Array[String] = ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]
const SNAPSHOT_KEYS: Array[String] = ["api_revision", "schema_version", "stable_id", "raw_role", "timing_floors", "resolved_role", "tuning", "clock_s", "position", "velocity", "facing", "grounded", "hp", "max_hp", "dead", "death_emitted", "phase", "reservation_id", "cycle", "cooldown_until_s", "retry_at_s", "stagger_until_s", "hit_consumed", "previous", "exchange", "commit", "framing", "last_rejection", "last_cancel_reason"]

var hp: float = 36.0
var max_hp: float = 36.0
var dead: bool = false
var last_error: String = ""
var last_snapshot_error: String = ""

var _stable_id: String = ""
var _hero: CinderPlayer
var _effects: PixelEffects
var _scheduler: CinderThreatScheduler
var _response_provider: Callable
var _raw_role: Dictionary = {}
var _timing_floors: Dictionary = {}
var _role: Dictionary = {}
var _body: CollisionShape3D
var _art: CinderAct3StalkerArt
var _cue: CinderThreatCue
var _configured: bool = false
var _facing: Vector3 = Vector3.BACK
var _phase: String = "idle"
var _reservation_id: String = ""
var _record: Dictionary = {}
var _proof: Dictionary = {}
var _framing: Dictionary = {}
var _exchange: Dictionary = {}
var _commit: Dictionary = {}
var _cycle: int = 0
var _cooldown_until_s: float = 0.0
var _retry_at_s: float = 0.0
var _stagger_until_s: float = 0.0
var _hit_consumed: bool = false
var _death_emitted: bool = false
var _previous_clock_s: float = 0.0
var _previous_source: Vector3 = Vector3.ZERO
var _previous_hero: Vector3 = Vector3.ZERO
var _last_rejection: String = ""
var _last_cancel_reason: String = ""
var _transaction_depth: int = 0
var _restored_grounded: int = -1
var _sun_visual: int = 0


func _ready() -> void:
	process_physics_priority = 20
	collision_layer = 2
	collision_mask = 1
	safe_margin = 0.001
	floor_snap_length = 0.18
	_body = CollisionShape3D.new()
	_body.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = float(TUNING.capsule_radius)
	capsule.height = float(TUNING.capsule_height)
	_body.shape = capsule
	_body.position.y = float(TUNING.capsule_center_y)
	add_child(_body)
	_art = Art.new()
	_art.name = "StalkerArt"
	add_child(_art)
	_cue = Cue.new()
	_cue.name = "RequiredThreatCue"
	add_child(_cue)
	_art.present(_facing, "idle")


## response_provider takes no arguments and returns the complete current
## public hero response plus root-owned world/floor/candidate context.
func configure(stable_id: String, hero: CinderPlayer, effects: PixelEffects, scheduler: CinderThreatScheduler, response_provider: Callable, raw_role: Dictionary = {}, timing_floors: Dictionary = {}) -> bool:
	if _configured or stable_id.is_empty() or stable_id.length() > 128 or not is_inside_tree() or not is_node_ready() or not is_instance_valid(hero) or not is_instance_valid(scheduler) or not response_provider.is_valid():
		return _reject("Ready source, stable ID, live hero/scheduler and response provider required")
	if hero.get_world_3d() != get_world_3d() or scheduler.get_world_3d() != get_world_3d() or hero.process_physics_priority >= process_physics_priority or scheduler.process_physics_priority >= process_physics_priority:
		return _reject("Same-world hero and scheduler must sample before the Stalker")
	var profile: Dictionary = scheduler.encounter_profile()
	var selected_raw: Dictionary = DEFAULT_ROLE.duplicate(true) if raw_role.is_empty() else raw_role.duplicate(true)
	var selected_floors: Dictionary = DEFAULT_FLOORS.duplicate(true) if timing_floors.is_empty() else timing_floors.duplicate(true)
	var resolver := Difficulty.new()
	var resolved: Dictionary = resolver.resolve_role(selected_raw, String(profile.get("id", "")), selected_floors)
	if resolved.is_empty() or not Codec.value_error(selected_raw).is_empty() or not Codec.value_error(selected_floors).is_empty():
		return _reject("Immutable raw role/timing floors did not resolve: " + resolver.last_error)
	_stable_id = stable_id
	_hero = hero
	_effects = effects
	_scheduler = scheduler
	_response_provider = response_provider
	_raw_role = selected_raw
	_timing_floors = selected_floors
	_role = resolved
	_proof.clear()
	max_hp = float(_role.max_hp)
	hp = max_hp
	_configured = true
	add_to_group("enemies")
	_scheduler.reservation_invalidated.connect(_on_invalidated)
	_sample(_clock())
	last_error = ""
	return true


func _physics_process(delta: float) -> void:
	if not _configured or dead:
		return
	_transaction_depth += 1
	var now: float = _clock()
	if not _bindings_valid() or not _runtime_visible() or not _required_cue_valid():
		_cancel("source_binding_lost")
		_transaction_depth -= 1
		return
	if not _reservation_id.is_empty():
		var record: Dictionary = _scheduler.reservation_state(_reservation_id)
		if record.is_empty():
			_release_local("reservation_released")
		else:
			var previous_phase: String = _phase
			_record = record
			_phase = String(record.state)
			_cooldown_until_s = float(record.cooldown_until_s)
			# No approach, gravity, move_and_slide or forced motion while leased.
			_resolve_contact(now, record)
			if not dead and not _reservation_id.is_empty():
				if not _present(false):
					_cancel("required_presentation_failed")
			if previous_phase != _phase:
				state_changed.emit(state())
			_sample(now)
			_transaction_depth -= 1
			return
	_step_unreserved(delta, now)
	_sample(now)
	if not dead and now >= _retry_at_s and now >= _cooldown_until_s and now >= _stagger_until_s and _grounded() and velocity.is_zero_approx():
		_try_lunge(now)
	_transaction_depth -= 1


func _notification(what: int) -> void:
	# The shell pauses synchronously inside hero.died. A later source can lose
	# this tick's callback after the common scheduler already moved its body.
	# Pause propagation queues this before the shell's deferred save drain; leave
	# the fatal source's current damage transaction to finish before settlement.
	if what == NOTIFICATION_PAUSED and _configured and is_instance_valid(_hero) and _hero.dead:
		_settle_paused_hero_death.call_deferred()


func _settle_paused_hero_death() -> void:
	# Living/manual pauses retain their contact history. Only a genuinely dead
	# hero permits quiet settlement, never another contact or physical advance.
	if not _configured or dead or _transaction_depth > 0 or not is_inside_tree() or is_queued_for_deletion() or not get_tree().paused or not _bindings_valid() or not _hero.dead:
		return
	if not _reservation_id.is_empty():
		var record: Dictionary = _scheduler.reservation_state(_reservation_id)
		if record.is_empty():
			_release_local("reservation_released", true)
			return
		_record = record
		_phase = String(record.state)
		_cooldown_until_s = float(record.cooldown_until_s)
	_sample(_clock())
	_present(true)


func _step_unreserved(delta: float, now: float) -> void:
	var previous_phase: String = _phase
	if _grounded():
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y -= float(TUNING.gravity) * delta
	var offset: Vector3 = _hero.global_position - global_position
	offset.y = 0.0
	var gap: float = offset.length()
	if now < _stagger_until_s:
		velocity.x = move_toward(velocity.x, 0.0, float(TUNING.stagger_drag) * delta)
		velocity.z = move_toward(velocity.z, 0.0, float(TUNING.stagger_drag) * delta)
		_phase = "idle"
	elif not _hero.dead and (gap < float(TUNING.brace_min_distance) or gap > float(TUNING.brace_max_distance)):
		# Travel follows the real hero directly. A close entry backs away using
		# the same acceleration and move_and_slide; no position snap is allowed.
		var toward: Vector3 = offset.normalized() if gap > 0.0001 else _facing
		if gap > 0.0001:
			_turn_toward(toward, delta)
		var travel: Vector3 = -toward if gap < float(TUNING.brace_min_distance) else toward
		var desired: Vector3 = travel * float(_role.move_speed)
		var planar := Vector3(velocity.x, 0.0, velocity.z).move_toward(desired, float(TUNING.approach_acceleration) * delta)
		velocity.x = planar.x
		velocity.z = planar.z
		_phase = "approach"
	else:
		# Only a real bounded brace turns toward the selected sun's flank.
		velocity.x = 0.0
		velocity.z = 0.0
		if gap > 0.0001 and not _hero.dead:
			_turn_toward(_biased_goal(offset.normalized(), _sun_visual), delta)
		_phase = "idle"
	move_and_slide()
	_restored_grounded = -1
	_present(false)
	if previous_phase != _phase:
		state_changed.emit(state())


## Signed source-local rotation about world UP: with a +Z hero bearing,
## Sun 0's +20 degrees points toward +X; Sun 1's -20 points toward -X.
## This owned rule remains a candidate pending actual two-sun portrait/play.
func _biased_goal(toward: Vector3, sun: int) -> Vector3:
	var degrees: float = float(TUNING.sun_bias_degrees) * (1.0 if sun == 0 else -1.0)
	return toward.rotated(Vector3.UP, deg_to_rad(degrees)).normalized()


func _turn_toward(direction: Vector3, delta: float) -> void:
	var angle: float = _facing.signed_angle_to(direction, Vector3.UP)
	_facing = _facing.rotated(Vector3.UP, clampf(angle, -float(TUNING.approach_turn_radians_s) * delta, float(TUNING.approach_turn_radians_s) * delta)).normalized()


func _try_lunge(now: float) -> void:
	_retry_at_s = now + float(TUNING.request_retry_s)
	if _hero.dead or not _grounded() or not velocity.is_zero_approx() or not _hero.get_threat_response_state().get("stable", false):
		return
	# Recheck actual post-move separation, including any physical overshoot.
	var source_at_commit: Vector3 = global_position
	var hero_at_commit: Vector3 = _hero.global_position
	var offset: Vector3 = hero_at_commit - source_at_commit
	offset.y = 0.0
	var gap: float = offset.length()
	if gap < float(TUNING.brace_min_distance) or gap > float(TUNING.brace_max_distance):
		return
	var sun_choice: int = _sun_visual
	if _facing.dot(_biased_goal(offset.normalized(), sun_choice)) < float(TUNING.brace_facing_min_dot):
		return
	var response_value: Variant = _response_provider.call()
	if not response_value is Dictionary or response_value.get("actor") != _hero:
		_last_rejection = "Response provider must retain the actual public hero actor"
		return
	var threat: Dictionary = {"role": _role.duplicate(true), "source_stationary": false, "opening_stationary": true, "cooldown_remaining_s": 0.0, "lunge": {"direction": _facing, "speed": TUNING.lunge_speed, "distance": TUNING.lunge_distance, "damage_radius": TUNING.damage_radius, "body_collision_path": "BodyCollision"}}
	var result: Dictionary = _scheduler.request_lunge(self, threat, response_value as Dictionary)
	if not result.get("accepted", false):
		_last_rejection = String(result.get("reason", "Lunge rejected"))
		return
	_reservation_id = String(result.reservation_id)
	_record = (result.reservation as Dictionary).duplicate(true)
	_proof = (result.get("proof", {}) as Dictionary).duplicate(true)
	_framing = {"landing": _proof.landing, "attack_position": _proof.attack_position}
	# Retain this exact observed choice/origin/bearing after cancellation too.
	_commit = {"sun_choice": sun_choice, "source_position": source_at_commit, "hero_position": hero_at_commit, "facing": _facing}
	_exchange.clear()
	for key: String in EXCHANGE_KEYS:
		_exchange[key] = _record[key]
	_cooldown_until_s = float(_record.cooldown_until_s)
	_cycle += 1
	_hit_consumed = false
	_last_rejection = ""
	_last_cancel_reason = ""
	_phase = String(_record.state)
	_sample(now)
	if not _present(false):
		_cancel("required_presentation_failed")
	state_changed.emit(state())


func _resolve_contact(now: float, record: Dictionary) -> void:
	if _hit_consumed or _hero.dead or not record.get("armed", false) or _previous_clock_s >= now:
		return
	var start: float = maxf(_previous_clock_s, float(record.active_from_s))
	var finish: float = minf(now, float(record.active_until_s))
	if finish < start or finish < float(record.active_from_s) or start > float(record.active_until_s):
		return
	var duration: float = now - _previous_clock_s
	var from_fraction: float = clampf((start - _previous_clock_s) / duration, 0.0, 1.0)
	var to_fraction: float = clampf((finish - _previous_clock_s) / duration, 0.0, 1.0)
	var source_now: Vector3 = record.source_position
	var hero_now: Vector3 = _hero.global_position
	var relative_start: Vector3 = _previous_source.lerp(source_now, from_fraction) - _previous_hero.lerp(hero_now, from_fraction)
	var relative_finish: Vector3 = _previous_source.lerp(source_now, to_fraction) - _previous_hero.lerp(hero_now, to_fraction)
	if not _relative_disk_contact(relative_start, relative_finish, float(record.adapter.damage_radius) + CinderThreatScheduler.CAPSULE_RADIUS):
		return
	# Consume before synchronous hurt/death callbacks, even if invulnerability
	# rejects HP damage. Zero impulse is the explicit first-room tuning choice.
	_hit_consumed = true
	var hp_before: float = _hero.hp
	_hero.take_damage(float(_role.damage), Vector3.ZERO)
	var result: Dictionary = {"stable_id": _stable_id, "cycle": _cycle, "opportunity_consumed": true, "accepted": _hero.hp < hp_before, "hp_damage": maxf(hp_before - _hero.hp, 0.0), "raw_damage": float(_role.damage), "impulse": Vector3.ZERO, "source_from": _previous_source, "source_to": source_now, "active_from_s": start, "active_until_s": finish}
	hit_resolved.emit(result.duplicate(true))


func _relative_disk_contact(from: Vector3, to: Vector3, radius: float) -> bool:
	var lower: float = 0.0
	var upper: float = 1.0
	var vertical_delta: float = to.y - from.y
	var height: float = float(TUNING.contact_height_tolerance)
	if absf(vertical_delta) < 0.000001:
		if absf(from.y) > height:
			return false
	else:
		var first: float = (-height - from.y) / vertical_delta
		var second: float = (height - from.y) / vertical_delta
		lower = maxf(0.0, minf(first, second))
		upper = minf(1.0, maxf(first, second))
		if lower > upper:
			return false
	var planar_from := Vector3(from.x, 0.0, from.z)
	var planar_delta := Vector3(to.x - from.x, 0.0, to.z - from.z)
	var nearest: float = lower
	if planar_delta.length_squared() > 0.000001:
		nearest = clampf(-planar_from.dot(planar_delta) / planar_delta.length_squared(), lower, upper)
	return (planar_from + planar_delta * nearest).length_squared() <= radius * radius


func take_damage(amount: float, impulse: Vector3) -> Dictionary:
	var alive_before: bool = _configured and not dead and hp > 0.0 and not is_queued_for_deletion()
	var result: Dictionary = {"accepted": false, "hp_damage": 0.0, "target_id": get_instance_id(), "target_alive_before_hit": alive_before}
	if not alive_before or not is_finite(amount) or amount <= 0.0 or not impulse.is_finite():
		return result
	_transaction_depth += 1
	var old_hp: float = hp
	hp = maxf(0.0, hp - amount)
	result.accepted = true
	result.hp_damage = old_hp - hp
	if hp <= 0.0:
		dead = true
		_phase = "defeated"
		_scheduler.cancel_owner(self, "source_defeated")
		_reservation_id = ""
		_record.clear()
		_cooldown_until_s = 0.0
		_stagger_until_s = 0.0
		velocity = Vector3.ZERO
		_set_living_presentation()
		_present(false)
		if not _death_emitted:
			_death_emitted = true
			died.emit(global_position)
	else:
		# Cancellation must happen before any ordinary impulse/forced motion.
		_cancel("primary_stagger")
		velocity += impulse
		_stagger_until_s = _clock() + 0.14 + minf(impulse.length() * 0.035, 0.27)
		if is_instance_valid(_effects):
			_effects.tiny_bleed(global_position + Vector3.UP * 0.8, 3, impulse)
	_sample(_clock())
	state_changed.emit(state())
	_transaction_depth -= 1
	return result


func _cancel(reason: String) -> void:
	if not _reservation_id.is_empty() and is_instance_valid(_scheduler):
		_scheduler.cancel(_reservation_id, reason)
	if not _reservation_id.is_empty():
		_release_local(reason)


func _on_invalidated(reservation_id: String, reason: String) -> void:
	if reservation_id == _reservation_id:
		_release_local(reason)


func _release_local(reason: String, silent: bool = false) -> void:
	_reservation_id = ""
	_record.clear()
	_phase = "defeated" if dead else "idle"
	_last_cancel_reason = reason
	_retry_at_s = _clock() + float(TUNING.request_retry_s)
	_sample(_clock())
	_present(silent)


func _sample(now: float) -> void:
	_previous_clock_s = now
	_previous_source = global_position
	if is_instance_valid(_hero):
		_previous_hero = _hero.global_position


func _clock() -> float:
	return _scheduler.get_clock() if is_instance_valid(_scheduler) else 0.0


func _grounded() -> bool:
	return _restored_grounded == 1 if _restored_grounded >= 0 else is_on_floor()


func _bindings_valid() -> bool:
	return is_instance_valid(_hero) and is_instance_valid(_scheduler) and is_instance_valid(_cue) and is_instance_valid(_art) and _hero.is_inside_tree() and _scheduler.is_inside_tree() and _hero.get_world_3d() == get_world_3d() and _scheduler.get_world_3d() == get_world_3d() and not _hero.is_queued_for_deletion() and not _scheduler.is_queued_for_deletion() and _shape_error().is_empty()


func _runtime_visible() -> bool:
	return is_visible_in_tree() and _art.is_visible_in_tree() and _cue.is_visible_in_tree() and bool(_art.state().get("visible", false))


func _required_cue_valid() -> bool:
	if _reservation_id.is_empty():
		return true
	var cue_state: Dictionary = _cue.state()
	return not _record.is_empty() and cue_state.get("phase") == _phase and cue_state.get("geometry") == _record.get("geometry") and bool(cue_state.get("source_visible", false)) and cue_state.get("source_position") == _previous_source


func get_cue() -> CinderThreatCue:
	return _cue


## Scenery supplies the latest light state for the next unleased brace.
## An accepted physical lease retains its own sun choice/crest and heading;
## a later scenic change never retargets the held exchange or alters its floor.
func set_sun_visual(sun: int) -> bool:
	if sun not in [0, 1] or not is_instance_valid(_art):
		return false
	_sun_visual = sun
	return _art.present(_facing, _phase, _effective_sun())


func _effective_sun() -> int:
	return int(_commit.sun_choice) if not _reservation_id.is_empty() and not _commit.is_empty() else _sun_visual


func get_art_state() -> Dictionary:
	return _art.state() if is_instance_valid(_art) else {}


func _shape_error() -> String:
	if not is_instance_valid(_body) or not _body.shape is CapsuleShape3D or not is_instance_valid(_art) or not is_instance_valid(_cue) or _body.is_queued_for_deletion() or _art.is_queued_for_deletion() or _cue.is_queued_for_deletion():
		return "Required Stalker collision/art/cue unavailable"
	var capsule: CapsuleShape3D = _body.shape as CapsuleShape3D
	if not is_equal_approx(capsule.radius, float(TUNING.capsule_radius)) or not is_equal_approx(capsule.height, float(TUNING.capsule_height)) or not _body.position.is_equal_approx(Vector3(0.0, float(TUNING.capsule_center_y), 0.0)) or not _body.basis.is_equal_approx(Basis.IDENTITY) or not scale.is_equal_approx(Vector3.ONE):
		return "Immutable Stalker capsule changed"
	return ""


func _present(silent: bool) -> bool:
	if not is_instance_valid(_art) or not is_instance_valid(_cue):
		return false
	var blocked: bool = _cue.is_blocking_signals()
	if silent:
		_cue.set_block_signals(true)
	var accepted: bool = true
	if _reservation_id.is_empty() or dead:
		accepted = _cue.clear()
	else:
		var geometry: Dictionary = (_record.get("geometry", {}) as Dictionary).duplicate(true)
		geometry["source_position"] = global_position
		accepted = _cue.present(geometry, _phase)
	if silent:
		_cue.set_block_signals(blocked)
	return _art.present(_facing, _phase, _effective_sun()) and accepted


## Pure complete source/art/cue forecast. The level unions these corners with
## other held exchanges; the shell separately includes the actual live hero.
## A supplied prospective motion/proof is visibility input only, never a lease.
func camera_framing_points(shell: Node, motion: Dictionary = {}, chosen: Dictionary = {}) -> Dictionary:
	if dead:
		return {"error": "", "points": []}
	if not _configured or not _bindings_valid() or not is_instance_valid(shell) or not shell.has_method("player_camera_framing_points"):
		return {"error": "Ready actual source/art/shared render bounds required", "points": []}
	var geometry: Dictionary = {}
	if motion.is_empty():
		if _reservation_id.is_empty():
			return {"error": "", "points": []}
		if not _record.get("adapter") is Dictionary or not _record.get("geometry") is Dictionary:
			return {"error": "Complete actual held lunge render geometry required", "points": []}
		motion = (_record.adapter as Dictionary).duplicate(true)
		geometry = (_record.geometry as Dictionary).duplicate(true)
		chosen = _framing.duplicate(true)
	else:
		if not motion.get("geometry") is Dictionary:
			return {"error": "Complete native prospective lunge render geometry required", "points": []}
		geometry = (motion.geometry as Dictionary).duplicate(true)
	if motion.get("kind") != "lunge" or not motion.get("start") is Vector3 or not motion.get("planned_endpoint") is Vector3 or not motion.get("direction") is Vector3 or geometry.get("kind") != "lane" or not CinderThreatGeometry.error(geometry).is_empty() or not Codec.keys_error(chosen, ["landing", "attack_position"]).is_empty():
		return {"error": "Complete actual or prospective lunge/framing bounds required", "points": []}
	for key: String in ["start", "planned_endpoint", "direction"]:
		if not (motion[key] as Vector3).is_finite():
			return {"error": "Finite native source motion forecast required: " + key, "points": []}
	var positions: Array = [global_position, motion.start, motion.planned_endpoint]
	var art: Dictionary = _art.camera_framing_points(shell, positions, motion.direction, _effective_sun())
	if not String(art.get("error", "")).is_empty():
		return art
	var source_bounds: Array = art.points.duplicate()
	var capsule: CapsuleShape3D = _body.shape as CapsuleShape3D
	if capsule == null:
		return {"error": "Actual source capsule bounds unavailable", "points": []}
	for at: Vector3 in positions:
		var centre: Vector3 = at + _body.position
		source_bounds.append_array(_framing_box_corners(centre - Vector3(capsule.radius, capsule.height * 0.5, capsule.radius), centre + Vector3(capsule.radius, capsule.height * 0.5, capsule.radius)))
		# Largest shared source glyph/ticks plus the real outline edge width.
		var extent: float = 0.31 + AttackFootprint.EDGE_WIDTH * 0.5
		source_bounds.append_array(_framing_box_corners(at + Vector3(-extent, CinderThreatCue.FLOOR_OFFSET, -extent), at + Vector3(extent, CinderThreatCue.FLOOR_OFFSET + 0.008, extent)))
	var points: Array = _framing_enclosing_box(source_bounds)
	if points.is_empty():
		return {"error": "Finite actual and committed native source corners required", "points": []}
	# The full capsule lane includes both curved endcaps and rendered edge width.
	var a: Vector3 = geometry.from
	var b: Vector3 = geometry.to
	var radius: float = float(geometry.radius) + AttackFootprint.EDGE_WIDTH * 0.5
	points.append_array(_framing_box_corners(Vector3(minf(a.x, b.x) - radius, minf(a.y, b.y) + CinderThreatCue.FLOOR_OFFSET - 0.004, minf(a.z, b.z) - radius), Vector3(maxf(a.x, b.x) + radius, maxf(a.y, b.y) + CinderThreatCue.FLOOR_OFFSET, maxf(a.z, b.z) + radius)))
	var hero_points: Array = shell.call("player_camera_framing_points")
	if hero_points.is_empty():
		return {"error": "Actual shared player render bounds unavailable", "points": []}
	for key: String in ["landing", "attack_position"]:
		if not chosen[key] is Vector3 or not chosen[key].is_finite():
			return {"error": "Finite selected native response render position required", "points": []}
		var shifted: Array = []
		for corner: Vector3 in hero_points:
			shifted.append(corner + (chosen[key] as Vector3) - _hero.global_position)
		points.append_array(_framing_enclosing_box(shifted))
	return {"error": "", "points": points}


func _framing_enclosing_box(points: Array) -> Array:
	if points.is_empty() or not points[0] is Vector3:
		return []
	var low: Vector3 = points[0]
	var high: Vector3 = points[0]
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite():
			return []
		low = low.min(point)
		high = high.max(point)
	return _framing_box_corners(low, high)


func _framing_box_corners(low: Vector3, high: Vector3) -> Array:
	var points: Array = []
	for x: float in [low.x, high.x]:
		for y: float in [low.y, high.y]:
			for z: float in [low.z, high.z]:
				points.append(Vector3(x, y, z))
	return points


func _set_living_presentation() -> void:
	collision_layer = 0 if dead else 2
	collision_mask = 0 if dead else 1
	if _transaction_depth > 0 and not get_tree().paused:
		_body.set_deferred("disabled", dead)
	else:
		_body.disabled = dead
	visible = not dead
	if dead:
		remove_from_group("enemies")
	elif not is_in_group("enemies"):
		add_to_group("enemies")


## Call after root has restored actual source -> scheduler, without a yield.
## Silent reconstruction cannot create hits, requests, drops or phase signals.
func refresh_presentation() -> bool:
	if not _configured or not _bindings_valid():
		return _reject("Restored source bindings unavailable")
	_record = {} if _reservation_id.is_empty() else _scheduler.reservation_state(_reservation_id)
	if not _reservation_id.is_empty() and _record.is_empty():
		return _reject("Restored source lacks its paired reservation")
	if not _record.is_empty():
		_phase = String(_record.state)
	_set_living_presentation()
	# Clear the prior cue first so restoring an older valid lock cannot look
	# like runtime retargeting to the cue's immutable-geometry guard.
	var blocked: bool = _cue.is_blocking_signals()
	_cue.set_block_signals(true)
	_cue.clear()
	_cue.set_block_signals(blocked)
	return _present(true)


func state() -> Dictionary:
	return {"stable_id": _stable_id, "hp": hp, "max_hp": max_hp, "dead": dead, "phase": _phase, "reservation_id": _reservation_id, "cycle": _cycle, "position": global_position, "velocity": velocity, "facing": _facing, "clock_s": _clock(), "cooldown_until_s": _cooldown_until_s, "retry_at_s": _retry_at_s, "hit_consumed": _hit_consumed, "raw_role": _raw_role.duplicate(true), "resolved_role": _role.duplicate(true), "proof": _proof.duplicate(true), "sun_visual": _sun_visual, "effective_sun": _effective_sun(), "commit": _commit.duplicate(true), "framing": _framing.duplicate(true), "last_rejection": _last_rejection, "last_cancel_reason": _last_cancel_reason}


func snapshot_state() -> Dictionary:
	last_snapshot_error = _snapshot_boundary_error()
	if not last_snapshot_error.is_empty():
		return {}
	var snapshot: Dictionary = {"api_revision": API_REVISION, "schema_version": 3, "stable_id": _stable_id, "raw_role": _raw_role.duplicate(true), "timing_floors": _timing_floors.duplicate(true), "resolved_role": _role.duplicate(true), "tuning": TUNING.duplicate(true), "clock_s": _clock(), "position": Codec.vector3(global_position), "velocity": Codec.vector3(velocity), "facing": Codec.vector3(_facing), "grounded": _grounded(), "hp": hp, "max_hp": max_hp, "dead": dead, "death_emitted": _death_emitted, "phase": _phase, "reservation_id": _reservation_id, "cycle": _cycle, "cooldown_until_s": _cooldown_until_s, "retry_at_s": _retry_at_s, "stagger_until_s": _stagger_until_s, "hit_consumed": _hit_consumed, "previous": {"clock_s": _previous_clock_s, "source_position": Codec.vector3(_previous_source), "hero_position": Codec.vector3(_previous_hero)}, "exchange": _exchange.duplicate(true), "commit": _encoded_commit(), "framing": _encoded_framing(), "last_rejection": _last_rejection, "last_cancel_reason": _last_cancel_reason}
	last_snapshot_error = snapshot_error(snapshot)
	return snapshot.duplicate(true) if last_snapshot_error.is_empty() else {}


## Pure. The root validates the scheduler and staged hero independently; this
## checks the owned state against that scheduler's JSON position/velocity pair.
func snapshot_error(snapshot: Dictionary, staged_scheduler: Dictionary = {}) -> String:
	var error: String = _snapshot_boundary_error()
	if not error.is_empty():
		return error
	var paired: Dictionary = _cached_scheduler_pair() if staged_scheduler.is_empty() else staged_scheduler
	if not paired.get("profile") is Dictionary or not paired.profile.get("id") is String or not Codec.is_number(paired.get("clock_s")) or not paired.get("reservations") is Array or not paired.get("cooldowns") is Array:
		return "Paired scheduler schema unavailable"
	error = _fields_error(snapshot, String(paired.profile.id))
	if not error.is_empty():
		return error
	if float(snapshot.clock_s) != float(paired.clock_s):
		return "Source and scheduler clocks differ"
	var owned: Dictionary = {}
	for value: Variant in paired.reservations:
		if not value is Dictionary:
			return "Malformed paired reservation"
		if value.get("source_id") == _stable_id:
			if not owned.is_empty():
				return "Source has duplicate reservations"
			owned = value
	var cooldown: float = 0.0
	for value: Variant in paired.cooldowns:
		if not value is Dictionary:
			return "Malformed paired source cooldown"
		if value.get("source_id") == _stable_id:
			if not Codec.is_number(value.get("ready_s")) or cooldown > 0.0:
				return "Malformed/duplicate source cooldown"
			cooldown = float(value.ready_s)
	var expected_cooldown: float = float(snapshot.cooldown_until_s) if float(snapshot.cooldown_until_s) > float(snapshot.clock_s) else 0.0
	if cooldown != expected_cooldown:
		return "Source retained cooldown differs from scheduler"
	if String(snapshot.reservation_id).is_empty():
		return "Unleased source still owns a reservation" if not owned.is_empty() else ""
	if owned.is_empty() or owned.get("id") != snapshot.reservation_id or not owned.get("adapter") is Dictionary or owned.adapter.get("kind") != "lunge":
		return "Source lacks the matching physical lunge reservation"
	if not Codec.is_vector3(owned.adapter.get("start")) or not Codec.is_vector3(owned.adapter.get("direction")) or Codec.read_vector3(owned.adapter.start) != Codec.read_vector3(snapshot.commit.source_position) or Codec.read_vector3(owned.adapter.direction) != Codec.read_vector3(snapshot.commit.facing):
		return "Physical adapter start/direction differs from the held sun commit"
	if not Codec.is_vector3(owned.get("source_position")) or not Codec.is_vector3(owned.adapter.get("current_position")) or not Codec.is_vector3(owned.adapter.get("current_velocity")) or Codec.read_vector3(owned.source_position) != Codec.read_vector3(snapshot.position) or Codec.read_vector3(owned.adapter.current_position) != Codec.read_vector3(snapshot.position) or Codec.read_vector3(owned.adapter.current_velocity) != Codec.read_vector3(snapshot.velocity):
		return "Paired source position/velocity differs"
	for key: String in EXCHANGE_KEYS:
		if not Codec.is_number(owned.get(key)) or float(owned[key]) != float(snapshot.exchange[key]):
			return "Paired source deadline differs: " + key
	if _phase_at(float(snapshot.clock_s), snapshot.exchange) != snapshot.phase or float(snapshot.previous.clock_s) != float(snapshot.clock_s):
		return "Paired source phase/sample clock differs"
	return ""


func _fields_error(snapshot: Dictionary, profile_id: String) -> String:
	var error: String = Codec.value_error(snapshot)
	if not error.is_empty():
		return error
	error = Codec.keys_error(snapshot, SNAPSHOT_KEYS)
	if not error.is_empty():
		return error
	if snapshot.api_revision != API_REVISION or not Codec.is_integer(snapshot.schema_version, 3, 3) or snapshot.stable_id != _stable_id or not Codec.same_values(snapshot.raw_role, _raw_role) or not Codec.same_values(snapshot.timing_floors, _timing_floors) or not Codec.same_values(snapshot.tuning, TUNING):
		return "Source identity/configuration drift"
	var resolver := Difficulty.new()
	var expected: Dictionary = resolver.resolve_role(_raw_role, profile_id, _timing_floors)
	if expected.is_empty() or not Codec.same_values(snapshot.resolved_role, expected):
		return "Source resolved role differs from paired difficulty"
	for key: String in ["position", "velocity", "facing"]:
		if not Codec.is_vector3(snapshot[key]):
			return "Invalid source vector: " + key
	var facing: Vector3 = Codec.read_vector3(snapshot.facing)
	if absf(facing.y) > 0.00001 or absf(facing.length() - 1.0) > 0.00001:
		return "Source facing must be normalized and planar"
	for key: String in ["dead", "death_emitted", "grounded", "hit_consumed"]:
		if not snapshot[key] is bool:
			return "Invalid source flag: " + key
	if not Codec.is_number(snapshot.clock_s) or float(snapshot.clock_s) < 0.0 or not Codec.in_range(snapshot.hp, 0.0, float(expected.max_hp)) or not Codec.same_values(snapshot.max_hp, expected.max_hp) or snapshot.dead != (float(snapshot.hp) <= 0.0) or snapshot.death_emitted != snapshot.dead:
		return "Source resources/lifecycle differ"
	if not Codec.is_integer(snapshot.cycle) or not snapshot.phase is String or not snapshot.reservation_id is String or not snapshot.last_rejection is String or not snapshot.last_cancel_reason is String:
		return "Invalid source phase/history"
	if snapshot.phase not in ["idle", "approach", "warning", "lock", "active", "recovery", "defeated"] or (snapshot.phase in ["warning", "lock", "active", "recovery"]) != (not String(snapshot.reservation_id).is_empty()) or snapshot.dead != (snapshot.phase == "defeated"):
		return "Source lease/phase differs"
	for key: String in ["cooldown_until_s", "retry_at_s", "stagger_until_s"]:
		if not Codec.is_number(snapshot[key]) or float(snapshot[key]) < 0.0:
			return "Invalid source deadline: " + key
	if float(snapshot.retry_at_s) > float(snapshot.clock_s) + float(TUNING.request_retry_s) + 0.00001 or float(snapshot.stagger_until_s) > float(snapshot.clock_s) + 0.41 + 0.00001:
		return "Source retry/stagger exceeds authored limit"
	if snapshot.dead and (not Codec.read_vector3(snapshot.velocity).is_zero_approx() or float(snapshot.cooldown_until_s) != 0.0 or float(snapshot.stagger_until_s) != 0.0):
		return "Defeated source retains motion/cooldown"
	if not snapshot.previous is Dictionary or not Codec.keys_error(snapshot.previous, ["clock_s", "source_position", "hero_position"]).is_empty() or not Codec.in_range(snapshot.previous.get("clock_s"), 0.0, float(snapshot.clock_s)) or not Codec.is_vector3(snapshot.previous.get("source_position")) or not Codec.is_vector3(snapshot.previous.get("hero_position")):
		return "Invalid source contact sample"
	if float(snapshot.previous.clock_s) == float(snapshot.clock_s) and Codec.read_vector3(snapshot.previous.source_position) != Codec.read_vector3(snapshot.position):
		return "Current contact sample differs from source position"
	if not snapshot.commit is Dictionary:
		return "Invalid source sun commit"
	error = _commit_error(snapshot.commit, int(snapshot.cycle))
	if not error.is_empty():
		return error
	if not String(snapshot.reservation_id).is_empty() and facing != Codec.read_vector3(snapshot.commit.facing):
		return "Leased source facing differs from its held sun commit"
	if not snapshot.exchange is Dictionary:
		return "Invalid source exchange"
	if int(snapshot.cycle) == 0:
		if not snapshot.exchange.is_empty() or snapshot.hit_consumed or not String(snapshot.reservation_id).is_empty() or float(snapshot.cooldown_until_s) != 0.0:
			return "Unstarted source manufactured attack history"
	else:
		error = Codec.keys_error(snapshot.exchange, EXCHANGE_KEYS)
		if not error.is_empty():
			return error
		for key: String in EXCHANGE_KEYS:
			if not Codec.is_number(snapshot.exchange[key]) or float(snapshot.exchange[key]) < 0.0:
				return "Invalid source exchange deadline"
		var exchange: Dictionary = snapshot.exchange
		var active: float = float(exchange.start_s) + float(expected.windup_s)
		if float(exchange.start_s) > float(snapshot.clock_s) or not is_equal_approx(float(exchange.active_from_s), active) or not is_equal_approx(float(exchange.lock_from_s), active - float(expected.lock_s)) or not is_equal_approx(float(exchange.active_until_s), active + float(expected.active_s)) or not is_equal_approx(float(exchange.recovery_until_s), active + float(expected.active_s) + float(expected.recovery_s)) or not is_equal_approx(float(exchange.cooldown_until_s), active + float(expected.attack_interval_s)):
			return "Source exchange differs from resolved timing"
		if not snapshot.dead and float(snapshot.cooldown_until_s) != float(exchange.cooldown_until_s):
			return "Source cooldown history differs from exchange"
		if snapshot.hit_consumed and float(snapshot.clock_s) < active:
			return "Source hit opportunity predates activation"
	return _framing_payload_error(snapshot)


func _encoded_framing() -> Dictionary:
	var encoded: Dictionary = _framing.duplicate(true)
	for key: String in encoded:
		encoded[key] = Codec.vector3(encoded[key])
	return encoded


## Historical render points do not depend on a later hero pose or equipment.
## Finite stable-floor checks constrain visibility metadata; they never replace
## the scheduler's original union/ordinary-primary mechanical acceptance.
func _framing_payload_error(snapshot: Dictionary) -> String:
	if not snapshot.framing is Dictionary:
		return "Source framing requires its closed historical render payload"
	if int(snapshot.cycle) == 0:
		return "Unstarted source manufactured framing history" if not snapshot.framing.is_empty() else ""
	if not Codec.keys_error(snapshot.framing, ["landing", "attack_position"]).is_empty():
		return "Source framing requires exactly the selected landing and primary position"
	var response: Variant = _response_provider.call()
	if not response is Dictionary or not response.get("floor_regions") is Array:
		return "Source framing requires its actual immutable floor bindings"
	for key: String in ["landing", "attack_position"]:
		if not Codec.is_vector3(snapshot.framing[key]):
			return "Invalid historical framing vector: " + key
		var point: Vector3 = Codec.read_vector3(snapshot.framing[key])
		if maxf(absf(point.x), maxf(absf(point.y), absf(point.z))) > 1024.0:
			return "Historical framing point exceeds the bounded native camera envelope"
		var supported: bool = false
		for region: Variant in response.floor_regions:
			if not region is Dictionary or not region.get("safe_rect") is Rect2:
				return "Historical framing requires the original stable floor rectangle"
			var floor_collision: CollisionShape3D = region.get("collision") as CollisionShape3D
			if not is_instance_valid(floor_collision) or not floor_collision.shape is BoxShape3D:
				return "Historical framing requires the actual stable box floor"
			var top: float = floor_collision.global_position.y + (floor_collision.shape as BoxShape3D).size.y * 0.5
			var rect: Rect2 = region.safe_rect
			var half: float = CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN
			rect.position += Vector2.ONE * half
			rect.size -= Vector2.ONE * half * 2.0
			if rect.has_point(Vector2(point.x, point.z)) and absf(point.y - top) <= 0.2:
				supported = true
		if not supported:
			return "Historical framing point lacks its stable supported floor envelope"
	return ""


func _encoded_commit() -> Dictionary:
	var encoded: Dictionary = _commit.duplicate(true)
	if not encoded.is_empty():
		for key: String in COMMIT_VECTOR_KEYS:
			encoded[key] = Codec.vector3(encoded[key])
	return encoded


## Pure historical validation: only a live lease additionally binds this
## commit to its adapter start/direction. An idle source may move/turn later.
func _commit_error(commit: Dictionary, cycle: int) -> String:
	if cycle == 0:
		return "Unstarted source manufactured sun commit history" if not commit.is_empty() else ""
	var error: String = Codec.keys_error(commit, COMMIT_KEYS)
	if not error.is_empty():
		return "Sun commit schema: " + error
	if not Codec.is_integer(commit.sun_choice, 0, 1):
		return "Sun commit choice is not one of the two scenic suns"
	for key: String in COMMIT_VECTOR_KEYS:
		if not Codec.is_vector3(commit[key]):
			return "Invalid sun commit vector: " + key
	var offset: Vector3 = Codec.read_vector3(commit.hero_position) - Codec.read_vector3(commit.source_position)
	offset.y = 0.0
	var gap: float = offset.length()
	var held: Vector3 = Codec.read_vector3(commit.facing)
	if gap < float(TUNING.brace_min_distance) or gap > float(TUNING.brace_max_distance):
		return "Sun commit gap lies outside the actual authored brace"
	if absf(held.y) > 0.00001 or absf(held.length() - 1.0) > 0.00001 or held.dot(_biased_goal(offset.normalized(), int(commit.sun_choice))) < float(TUNING.brace_facing_min_dot):
		return "Sun commit facing differs from its signed biased hero bearing"
	return ""


func _cached_scheduler_pair() -> Dictionary:
	var records: Array = []
	if not _record.is_empty() and not _reservation_id.is_empty():
		var record: Dictionary = {"id": _reservation_id, "source_id": _stable_id, "source_position": Codec.vector3(_record.source_position), "adapter": {"kind": "lunge", "start": Codec.vector3(_record.adapter.start), "direction": Codec.vector3(_record.adapter.direction), "current_position": Codec.vector3(_record.adapter.current_position), "current_velocity": Codec.vector3(_record.adapter.current_velocity)}}
		for key: String in EXCHANGE_KEYS:
			record[key] = _record[key]
		records.append(record)
	var cooldowns: Array = []
	if _cooldown_until_s > _clock():
		cooldowns.append({"source_id": _stable_id, "ready_s": _cooldown_until_s})
	return {"profile": _scheduler.encounter_profile(), "clock_s": _clock(), "reservations": records, "cooldowns": cooldowns}


func _phase_at(now: float, exchange: Dictionary) -> String:
	return "warning" if now < float(exchange.lock_from_s) else ("lock" if now < float(exchange.active_from_s) else ("active" if now <= float(exchange.active_until_s) else "recovery"))


func _snapshot_boundary_error() -> String:
	if not _configured or not is_inside_tree() or not is_node_ready() or is_queued_for_deletion() or not get_tree().paused or _transaction_depth > 0 or not _bindings_valid():
		return "Ready paired source at a deferred paused barrier required"
	return ""


func restore_state(snapshot: Dictionary) -> bool:
	last_snapshot_error = snapshot_error(snapshot)
	if not last_snapshot_error.is_empty():
		return false
	return apply_validated_state(snapshot) and refresh_presentation()


## Root already prevalidated the entire actor/local/scheduler aggregate. This
## applies the source before scheduler commit, so no current reservation query
## or damage/cancel/request/event is allowed here.
func apply_validated_state(snapshot: Dictionary) -> bool:
	last_snapshot_error = _snapshot_boundary_error()
	if not last_snapshot_error.is_empty():
		return false
	var profile_id: String = String(snapshot.get("resolved_role", {}).get("difficulty_profile", "")) if snapshot.get("resolved_role") is Dictionary else ""
	last_snapshot_error = _fields_error(snapshot, profile_id)
	if not last_snapshot_error.is_empty():
		return false
	_transaction_depth += 1
	hp = float(snapshot.hp)
	max_hp = float(snapshot.max_hp)
	dead = snapshot.dead
	_death_emitted = snapshot.death_emitted
	_role = (snapshot.resolved_role as Dictionary).duplicate(true)
	global_position = Codec.read_vector3(snapshot.position)
	velocity = Codec.read_vector3(snapshot.velocity)
	_facing = Codec.read_vector3(snapshot.facing)
	_restored_grounded = 1 if snapshot.grounded else 0
	_phase = snapshot.phase
	_reservation_id = snapshot.reservation_id
	_record.clear()
	_proof.clear() # Diagnostic witness is not authoritative checkpoint payload.
	_cycle = int(snapshot.cycle)
	_cooldown_until_s = float(snapshot.cooldown_until_s)
	_retry_at_s = float(snapshot.retry_at_s)
	_stagger_until_s = float(snapshot.stagger_until_s)
	_hit_consumed = snapshot.hit_consumed
	_previous_clock_s = float(snapshot.previous.clock_s)
	_previous_source = Codec.read_vector3(snapshot.previous.source_position)
	_previous_hero = Codec.read_vector3(snapshot.previous.hero_position)
	_exchange = (snapshot.exchange as Dictionary).duplicate(true)
	_commit = (snapshot.commit as Dictionary).duplicate(true)
	if not _commit.is_empty():
		for key: String in COMMIT_VECTOR_KEYS:
			_commit[key] = Codec.read_vector3(snapshot.commit[key])
	_framing = (snapshot.framing as Dictionary).duplicate(true)
	for key: String in _framing:
		_framing[key] = Codec.read_vector3(snapshot.framing[key])
	_last_rejection = snapshot.last_rejection
	_last_cancel_reason = snapshot.last_cancel_reason
	_set_living_presentation()
	_transaction_depth -= 1
	return true


func _reject(reason: String) -> bool:
	last_error = reason
	return false


func _exit_tree() -> void:
	if is_instance_valid(_scheduler):
		if _scheduler.reservation_invalidated.is_connected(_on_invalidated):
			_scheduler.reservation_invalidated.disconnect(_on_invalidated)
		_scheduler.cancel_owner(self, "source_removed")
