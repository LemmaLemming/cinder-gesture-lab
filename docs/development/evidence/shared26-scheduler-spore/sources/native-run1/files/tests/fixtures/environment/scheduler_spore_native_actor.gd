extends CharacterBody3D
## Real test-only capsule using the actual Scheduler's lane/lunge authorities.
## Own HP, hurt settling and native codec. No authored enemy, damage fairness,
## mushroom-room or campaign acceptance is claimed by this leaf actor.

const NativeCodec = preload("res://tests/fixtures/environment/scheduler_spore_native_codec.gd")
const Cue = preload("res://scripts/cues/threat_cue.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const API: String = "scheduler-spore-fixture-actor-1"

signal state_changed
signal hit_resolved(result: Dictionary)

var hp: float = 20.0
var dead: bool = false
var _scheduler: CinderThreatScheduler
var _hero: CinderPlayer
var _codec: RefCounted = NativeCodec.new()
var _configuration: Dictionary = {}
var _collision: CollisionShape3D
var _cue: CinderThreatCue
var _consumer: WeakRef
var _consumer_id: String = ""
var _episode: String = ""
var _spore_phase: String = "none"
var _direction: Vector3 = Vector3.RIGHT
var _progress: float = 0.0
var _facing: Vector3 = Vector3.RIGHT
var _hurt: float = 0.0
var _reservation_id: String = ""
var _role: Dictionary = {}
var _profile: String = ""
var _sample: Dictionary = {}
var _pending: Array = []
var _hit_ids: Array[String] = []
var _busy: int = 0
var _restored_grounded: int = -1
var _source_id: String = "native-source"
var _cancel_delivering: bool = false
var _nested_damage_used: bool = false


func configure_source_id(id: String) -> bool:
	if is_inside_tree() or id.is_empty(): return false
	_source_id = id
	return true


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	process_physics_priority = 10
	_collision = CollisionShape3D.new()
	_collision.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.45
	_collision.shape = capsule
	_collision.position.y = 0.73
	add_child(_collision)
	_cue = Cue.new()
	_cue.name = "NativeCue"
	add_child(_cue)
	_configuration = {"source_id": _source_id, "max_hp": 20.0, "body": {"radius": float(capsule.radius), "height": float(capsule.height), "centre": Value.vector3(_collision.position)}, "raw_role": {"raw_damage": 8.0, "windup_s": 0.8, "lock_s": 0.25, "active_s": 0.5, "recovery_s": 0.9, "attack_interval_s": 1.5, "max_hp": 20.0, "move_speed": 4.0}, "timing_floors": {"windup_s": 0.8, "lock_s": 0.25, "recovery_s": 0.9}}
	add_to_group("enemies")


func bind_native(scheduler: CinderThreatScheduler, hero: CinderPlayer) -> void:
	_scheduler = scheduler
	_hero = hero
	_scheduler.reservation_invalidated.connect(_invalidated)


func get_spore_native_bindings() -> Dictionary:
	return {"api_revision": "scheduler-spore-actor-1", "actor_revision": API, "source_id": _source_id, "scheduler": _scheduler, "player": _hero, "codec": _codec, "configuration": _configuration.duplicate(true)}


func get_spore_response_state() -> Dictionary:
	return {"api_revision": "scheduler-spore-actor-1", "source_id": _source_id, "consumer_id": _consumer_id, "alive": not dead, "grounded": _grounded(), "position": global_position, "velocity": velocity, "facing": _facing, "hurt_remaining_s": _hurt, "body_collision_path": "BodyCollision", "support_radius": float((_collision.shape as CapsuleShape3D).radius) + 0.01, "height": float((_collision.shape as CapsuleShape3D).height), "episode_id": _episode, "phase": _spore_phase, "direction": _direction, "progress": _progress, "outside_transaction": _busy == 0}


func spore_bind_error(consumer: Node, source_id: String) -> String:
	if _busy != 0 or source_id != _source_id or not is_instance_valid(consumer) or not _scheduler.has_method("source_control_state") or not bool(_scheduler.call("source_control_state", self).outside_transaction):
		return "Actual native bind boundary unavailable"
	if not _consumer_id.is_empty() and (_consumer.get_ref() != consumer or _consumer_id != consumer.call("consumer_id")):
		return "Native environmental binding immutable"
	return ""


func bind_spore_repulsion(consumer: Node, source_id: String) -> bool:
	if not spore_bind_error(consumer, source_id).is_empty():
		return false
	_consumer = weakref(consumer)
	_consumer_id = consumer.call("consumer_id")
	return true


func start(kind: String, response: Dictionary) -> Dictionary:
	if _busy != 0 or dead or _hurt > 0.0 or not _episode.is_empty() or not _reservation_id.is_empty() or get_tree().paused:
		return {"accepted": false, "reason": "Native fixture cannot start an occupied controller"}
	_profile = String(_scheduler.encounter_profile().get("id", ""))
	_role = Difficulty.new().resolve_role(_configuration.raw_role, _profile, _configuration.timing_floors)
	var result: Dictionary
	if kind == "lunge":
		result = _scheduler.request_lunge(self, {"role": _role, "source_stationary": false, "opening_stationary": true, "cooldown_remaining_s": 0.0, "lunge": {"direction": _facing, "speed": 4.0, "distance": 1.2, "damage_radius": 0.38, "body_collision_path": "BodyCollision"}}, response)
	else:
		result = _scheduler.request_attack(self, {"role": _role, "source_stationary": true, "opening_stationary": true, "cooldown_remaining_s": 0.0, "geometry": Geometry.lane(global_position, global_position + _facing * 1.8, 0.38)}, response)
	if result.get("accepted", false):
		_reservation_id = result.reservation_id
		_pending.clear()
		_hit_ids.clear()
		_sample_now()
		_busy += 1
		_present(result.reservation)
		_busy -= 1
	return result


func cancel_attack_for_spores(consumer: Node, episode_id: String, direction: Vector3) -> bool:
	if _busy != 0 or dead or _consumer == null or _consumer.get_ref() != consumer or not _episode.is_empty() or _hurt > 0.0 or get_tree().paused:
		return false
	_busy += 1
	_episode = episode_id
	_spore_phase = "recoil"
	_direction = direction
	_progress = 0.0
	_cancel_delivering = true
	_nested_damage_used = false
	_cancel_exchange("spore_repulsion")
	_cancel_delivering = false
	_busy -= 1
	return true


func present_spore_phase(consumer: Node, episode_id: String, phase: String, progress: float) -> bool:
	if _busy != 0 or _consumer == null or _consumer.get_ref() != consumer or episode_id != _episode:
		return false
	_spore_phase = phase
	_progress = progress
	if phase != "recoil": _facing = _direction
	return true


func resume_spore_retreat(consumer: Node, episode_id: String, direction: Vector3) -> bool:
	if _spore_phase != "interrupted" or _hurt > 0.0 or not _grounded() or velocity != Vector3.ZERO or _consumer == null or _consumer.get_ref() != consumer or episode_id != _episode:
		return false
	_direction = direction
	_spore_phase = "retreat"
	_progress = 0.0
	return true


func finish_spore_episode(consumer: Node, episode_id: String) -> bool:
	if _busy != 0 or _consumer == null or _consumer.get_ref() != consumer or episode_id != _episode:
		return false
	_episode = ""
	_spore_phase = "none"
	_progress = 0.0
	return true


func take_damage(amount: float, impulse: Vector3) -> Dictionary:
	var result: Dictionary = {"accepted": false, "hp_damage": 0.0, "target_id": get_instance_id(), "target_alive_before_hit": not dead}
	if (_busy != 0 and (not _cancel_delivering or _nested_damage_used or _busy != 1)) or dead or not is_finite(amount) or amount <= 0.0 or not impulse.is_finite(): return result
	if _busy != 0: _nested_damage_used = true
	_busy += 1
	_cancel_exchange("actual_player_damage")
	var before: float = hp
	hp = maxf(0.0, hp - amount)
	dead = hp == 0.0
	result.accepted = true
	result.hp_damage = before - hp
	if dead:
		velocity = Vector3.ZERO
		_hurt = 0.0
		_episode = ""
		_spore_phase = "none"
		_progress = 0.0
		_scheduler.cancel_owner(self, "source_defeated")
		collision_layer = 0
		collision_mask = 0
		_collision.disabled = true
		visible = false
		remove_from_group("enemies")
	else:
		velocity += impulse
		_hurt = 0.22
		if not _episode.is_empty():
			_spore_phase = "interrupted"
			_progress = 0.0
	var consumer: Node = _consumer.get_ref() as Node if _consumer != null else null
	if is_instance_valid(consumer):
		consumer.call("source_interrupted", self, "actual_death" if dead else "actual_damage")
	state_changed.emit()
	_busy -= 1
	return result


func spore_snapshot_state(scheduler: Dictionary, player: Dictionary) -> Dictionary:
	if not get_tree().paused or _busy != 0: return {}
	var shown: Dictionary = _cue.state()
	var geometry: Dictionary = shown.geometry.duplicate(true)
	for key: String in geometry:
		if geometry[key] is Vector3: geometry[key] = Value.vector3(geometry[key])
	var saved: Dictionary = {"api_revision": API, "schema_version": 1, "source_id": _source_id, "configuration": _configuration.duplicate(true), "hp": hp, "dead": dead, "motion": {"position": Value.vector3(global_position), "basis": [Value.vector3(global_basis.x), Value.vector3(global_basis.y), Value.vector3(global_basis.z)], "velocity": Value.vector3(velocity), "facing": Value.vector3(_facing), "grounded": _grounded()}, "hurt_left_s": _hurt, "resolved_role": _role.duplicate(true), "profile_id": _profile, "reservation_id": _reservation_id, "sample": _sample.duplicate(true), "hit_ids": _hit_ids.duplicate(), "cue": {"phase": shown.phase, "geometry": geometry, "source_position": null if shown.phase == "clear" else Value.vector3(shown.source_position)}, "repulsion": {"api_revision": "scheduler-spore-actor-1", "consumer_id": _consumer_id, "source_id": _source_id, "episode_id": _episode, "phase": _spore_phase, "direction": Value.vector3(_direction), "progress": _progress}}
	if not _pending.is_empty():
		saved.schema_version = 2
		saved["pending_segments"] = _pending.duplicate(true)
	if not _reservation_id.is_empty() and not _required_cue_available(): return {}
	return saved if _codec.record_error(saved, scheduler, player, {"source_id": _source_id, "actor_revision": API, "consumer_id": _consumer_id, "configuration": _configuration}).is_empty() else {}


func restore_physical(saved: Dictionary) -> void:
	global_position = Value.read_vector3(saved.motion.position)
	velocity = Value.read_vector3(saved.motion.velocity)
	_facing = Value.read_vector3(saved.motion.facing)
	hp = saved.hp
	dead = saved.dead
	_hurt = saved.hurt_left_s
	_restored_grounded = 1 if saved.motion.grounded else 0
	_collision.disabled = dead
	collision_layer = 0 if dead else 2
	collision_mask = 0 if dead else 1
	visible = not dead
	if dead: remove_from_group("enemies")
	else: add_to_group("enemies")


func restore_exchange(saved: Dictionary) -> void:
	_reservation_id = saved.reservation_id
	_sample = saved.sample.duplicate(true)
	_pending = saved.get("pending_segments", []).duplicate(true)
	_hit_ids.assign(saved.hit_ids)
	_role = saved.resolved_role.duplicate(true)
	_profile = saved.profile_id
	_episode = saved.repulsion.episode_id
	_spore_phase = saved.repulsion.phase
	_direction = Value.read_vector3(saved.repulsion.direction)
	_progress = saved.repulsion.progress
	var blocked: bool = _cue.is_blocking_signals()
	_cue.set_block_signals(true)
	if _reservation_id.is_empty():
		_cue.clear()
	else:
		var records: Array = _scheduler.call("source_control_state", self).reservations
		_present(records[0])
	_cue.set_block_signals(blocked)


func _physics_process(delta: float) -> void:
	if dead or _scheduler == null or _busy != 0: return
	# Genuine coordinator owns the environmental step before this actor enters
	# its ordinary transaction. A flag alone cannot stop Scheduler lunge motion.
	var consumer: Node = _consumer.get_ref() as Node if _consumer != null else null
	if is_instance_valid(consumer) and bool(consumer.call("step_source", self, delta)):
		return
	if get_tree().paused or dead: return
	_busy += 1
	if not _reservation_id.is_empty():
		var records: Array = _scheduler.call("source_control_state", self).reservations
		if records.is_empty():
			_cancel_exchange("native_exchange_expired")
		elif not _required_cue_available():
			_cancel_exchange("required_native_cue_lost")
		else:
			var now: float = _scheduler.get_clock()
			if not _hero.dead and not _hit_ids.has("hero"):
				if _pending.size() >= 32:
					_cancel_exchange("native_pending_budget")
				else:
					_pending.append({"from": _sample.hero_position.duplicate(), "to": Value.vector3(_hero.global_position), "source_from": _sample.source_position.duplicate(), "source_to": Value.vector3(global_position), "start_s": _sample.clock_s, "end_s": now})
			_sample_now()
			if not _reservation_id.is_empty():
				_present(records[0])
				_drain_pending()
	elif _episode.is_empty() or _spore_phase == "interrupted" or (_spore_phase == "failed" and (_hurt > 0.0 or not _grounded() or velocity != Vector3.ZERO)):
		_hurt = maxf(0.0, _hurt - delta)
		velocity.x = move_toward(velocity.x, 0.0, 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 5.0 * delta)
		if not _grounded(): velocity.y -= 24.0 * delta
		elif velocity.y < 0.0: velocity.y = 0.0
		move_and_slide()
		_restored_grounded = -1
	_busy -= 1


func _drain_pending() -> void:
	while not _pending.is_empty():
		if not _damage_ready(): return
		var records: Array = _scheduler.call("source_control_state", self).reservations
		var record: Dictionary = records[0]
		var encoded: Dictionary = _pending.pop_front()
		if _hero.dead or _hit_ids.has("hero"): continue
		var start: float = maxf(float(encoded.start_s), float(record.active_from_s))
		var finish: float = minf(float(encoded.end_s), float(record.active_until_s))
		if start > finish: continue
		var from: Vector3 = Value.read_vector3(encoded.from)
		var to: Vector3 = Value.read_vector3(encoded.to)
		var contact_geometry: Dictionary = record.geometry
		if record.get("adapter", {}).get("kind") == "lunge":
			from -= Value.read_vector3(encoded.source_from)
			to -= Value.read_vector3(encoded.source_to)
			contact_geometry = Geometry.circle(Vector3.ZERO, float(record.adapter.damage_radius))
		var path: Array[Dictionary] = [{"from": from, "to": to, "start_s": float(encoded.start_s), "end_s": float(encoded.end_s)}]
		if not Geometry.timed_path_hits(contact_geometry, path, float(record.active_from_s), float(record.active_until_s), CinderThreatScheduler.CAPSULE_RADIUS): continue
		# Actual shared Player opportunity is consumed before hurt/event callbacks.
		_hit_ids.append("hero")
		var before: float = _hero.hp
		_hero.take_damage(float(_role.damage), Vector3.ZERO)
		var ready_after_hurt: bool = _damage_ready()
		hit_resolved.emit({"opportunity_consumed": true, "accepted": _hero.hp < before, "hp_damage": maxf(0.0, before - _hero.hp), "raw_damage": float(_role.damage)})
		if not ready_after_hurt or not _damage_ready(): return


func _damage_ready() -> bool:
	if dead or _reservation_id.is_empty() or not is_visible_in_tree() or not _required_cue_available():
		_cancel_exchange("required_native_source_or_cue_lost")
		return false
	var control: Dictionary = _scheduler.call("source_control_state", self)
	if control.is_empty() or control.reservations.size() != 1 or control.reservations[0].id != _reservation_id:
		_cancel_exchange("native_lease_lost")
		return false
	if _cue.state().phase != control.reservations[0].state:
		_cancel_exchange("native_phase_lost")
		return false
	return not get_tree().paused


func _required_cue_available() -> bool:
	if not is_instance_valid(_cue) or _cue.is_queued_for_deletion() or not _cue.is_visible_in_tree(): return false
	var shown: Dictionary = _cue.state()
	if shown.phase == "clear": return _reservation_id.is_empty()
	var records: Array = _scheduler.call("source_control_state", self).reservations
	if records.size() != 1 or records[0].id != _reservation_id or shown.geometry != records[0].geometry or shown.source_position != Value.read_vector3(_sample.get("source_position", Value.vector3(global_position))): return false
	var parts: Array[String] = ["RequiredSourceMarker"]
	if shown.phase != "recovery": parts.append("RequiredFootprintOutline")
	if shown.phase == "active": parts.append("RequiredFootprintFill")
	for name: String in parts:
		var part: MeshInstance3D = _cue.get_node_or_null(name) as MeshInstance3D
		if not is_instance_valid(part) or part.is_queued_for_deletion() or not part.is_visible_in_tree() or part.mesh == null: return false
	return true


func _cancel_exchange(reason: String) -> void:
	var id: String = _reservation_id
	_reservation_id = ""
	_sample.clear()
	_pending.clear()
	if not id.is_empty(): _scheduler.cancel(id, reason)
	_cue.clear()


func _invalidated(id: String, _reason: String) -> void:
	if id == _reservation_id:
		_reservation_id = ""
		_sample.clear()
		_pending.clear()
		_cue.clear()


func _sample_now() -> void:
	_sample = {"clock_s": _scheduler.get_clock(), "source_position": Value.vector3(global_position), "hero_position": Value.vector3(_hero.global_position)}


func _present(record: Dictionary) -> void:
	var geometry: Dictionary = record.geometry.duplicate(true)
	geometry["source_position"] = global_position
	_cue.present(geometry, record.state)


func _grounded() -> bool:
	return _restored_grounded == 1 if _restored_grounded >= 0 else is_on_floor()
