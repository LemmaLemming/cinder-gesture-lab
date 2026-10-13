class_name AshEnemy
extends CharacterBody3D

signal died(where: Vector3)

const SpriteScript = preload("res://scripts/pixel_sprite.gd")
const Footprint = preload("res://scripts/attack_footprint.gd")
const SnapshotCodec = preload("res://scripts/campaign/snapshot_codec.gd")
const SNAPSHOT_API_REVISION: String = "enemy-snapshot-1"
const SNAPSHOT_SCHEMA_VERSION: int = 1
const GRAVITY: float = 24.0
const AGGRO_RANGE: float = 11.0
const ATTACK_HEIGHT_TOLERANCE: float = 1.35
const ATTACK_DOT: float = 0.55
const ACTIVE_FEEDBACK_S: float = 0.12
# Arena tuning proposal: hold a readable, stationary opening after each strike.
# These are prototype roles, not authored campaign Selenite behaviours.
const RECOVERY_S: float = 0.60
const LOCK_LEAD_S: float = 0.20
const MAX_PREPARING_ATTACKERS: int = 2
const COLOR_CRIMSON: Color = Color(0.68, 0.035, 0.075)
const COLOR_WARNING: Color = Color(1.0, 0.13, 0.15)
const COLOR_HIT: Color = Color(2.0, 2.0, 2.0)

var hp: float = 32.0
var max_hp: float = 32.0
var dead: bool = false
var last_snapshot_error: String = ""

var _hero: Node3D
var _fx: Node
var _kind: int = 0
var _move_speed: float = 2.6
var _attack_damage: float = 10.0
var _attack_reach: float = 2.0
var _windup_duration: float = 0.55
var _attack_interval: float = 1.25
var _knockback_factor: float = 1.0
var _facing: Vector3 = Vector3.FORWARD
var _windup_left: float = 0.0
var _active_left: float = 0.0
var _recovery_left: float = 0.0
var _attack_facing: Vector3 = Vector3.FORWARD
var _cooldown_left: float = 0.0
var _stagger_left: float = 0.0
var _hit_flash_left: float = 0.0
var _hop_left: float = 0.0
var _sprite: LabSprite
var _warning: MeshInstance3D
var _active_footprint: MeshInstance3D
var _countdown: Node3D
var _countdown_pips: Array[MeshInstance3D] = []
var _recovery_marker: MeshInstance3D
var _attack_origin: Vector3 = Vector3.INF
var _death_emitted: bool = false
var _drop_spawned: bool = false
var _snapshot_busy: bool = false
var _actor_transaction_depth: int = 0
var _restored_floor_contact: int = -1
## Optional environmental owner; unbound actors retain the original arena loop
## and legacy snapshot shape. Spore reaction never uses take_damage/stagger.
var _spore_consumer: WeakRef
var _spore_source_id: String = ""
var _spore_consumer_id: String = ""
var _spore_episode_id: String = ""
var _spore_phase: String = "none"
var _spore_direction: Vector3 = Vector3.FORWARD
var _spore_progress: float = 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	add_to_group("enemies")
	_build_collision()
	_build_visual()


func configure(hero: Node3D, fx: Node, kind: int = 0) -> void:
	if not _spore_source_id.is_empty():
		# Bound retry uses paired snapshots; configure would refill resources.
		return
	_actor_transaction_depth += 1
	_hero = hero
	_fx = fx
	_kind = clampi(kind, 0, 2)
	_set_variant_stats()
	hp = max_hp
	dead = false
	_death_emitted = false
	_drop_spawned = false
	_attack_origin = Vector3.INF
	if is_inside_tree():
		_build_visual()
	_actor_transaction_depth -= 1


func take_damage(amount: float, impulse: Vector3) -> Dictionary:
	var was_alive: bool = hp > 0.0 and not dead and not is_queued_for_deletion()
	var result: Dictionary = {
		"accepted": false,
		"hp_damage": 0.0,
		"target_id": get_instance_id(),
		"target_alive_before_hit": was_alive,
	}
	if not was_alive or amount <= 0.0:
		return result
	_actor_transaction_depth += 1
	var old_hp: float = hp
	hp = maxf(0.0, hp - amount)
	result["accepted"] = true
	result["hp_damage"] = old_hp - hp
	if hp > 0.0 and _fx != null and is_instance_valid(_fx) and _fx.has_method("tiny_bleed"):
		_fx.call("tiny_bleed", global_position + Vector3(0.0, 0.8, 0.0), 3, impulse)
	if hp <= 0.0:
		_die(impulse)
		_actor_transaction_depth -= 1
		return result
	_hit_flash_left = 0.12
	_windup_left = 0.0
	_active_left = 0.0
	_recovery_left = 0.0
	_update_attack_feedback()
	var adjusted_impulse: Vector3 = impulse * _knockback_factor
	velocity += adjusted_impulse
	velocity.y = maxf(velocity.y, adjusted_impulse.y)
	_stagger_left = maxf(_stagger_left, 0.14 + minf(adjusted_impulse.length() * 0.035, 0.27))
	var spore_owner: Node = _spore_owner()
	if not _spore_episode_id.is_empty():
		_spore_phase = "interrupted"
		_spore_progress = 0.0
		_sprite.rotation.z = 0.0
		if spore_owner != null:
			spore_owner.call("source_interrupted", self, "actual_damage")
	_actor_transaction_depth -= 1
	return result


func _physics_process(delta: float) -> void:
	if hp <= 0.0 or dead:
		return
	var spore_owner: Node = _spore_owner()
	if not _spore_source_id.is_empty():
		# Environmental preflight/cancellation occurs before the old controller
		# can strike or move. It owns its own transaction/callback guard.
		var held: bool = _spore_phase != "interrupted" if spore_owner == null else bool(spore_owner.call("step_source", self, delta))
		if held:
			_actor_transaction_depth += 1
			_cooldown_left = maxf(0.0, _cooldown_left - delta)
			_hop_left = maxf(0.0, _hop_left - delta)
			_hit_flash_left = maxf(0.0, _hit_flash_left - delta)
			_stagger_left = maxf(0.0, _stagger_left - delta)
			if spore_owner == null:
				velocity = Vector3.ZERO
			_update_attack_feedback()
			if _sprite != null:
				_sprite.animate(_spore_phase == "retreat" and Vector2(velocity.x, velocity.z).length() > 0.25, delta)
			_actor_transaction_depth -= 1
			return
	_actor_transaction_depth += 1
	if not _snapshot_grounded():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	_hop_left = maxf(0.0, _hop_left - delta)
	_hit_flash_left = maxf(0.0, _hit_flash_left - delta)
	if _sprite != null:
		_sprite.modulate = COLOR_HIT if _hit_flash_left > 0.0 else (Color(0.70, 0.72, 0.76) if _recovery_left > 0.0 else Color.WHITE)
	if _stagger_left > 0.0:
		_stagger_left = maxf(0.0, _stagger_left - delta)
		_slow_planar(5.0 * delta)
	elif _windup_left > 0.0:
		_windup_left = maxf(_windup_left - delta, 0.0)
		velocity.x = 0.0
		velocity.z = 0.0
		if _windup_left <= 0.0:
			_strike()
	elif _active_left > 0.0:
		_active_left = maxf(_active_left - delta, 0.0)
		velocity.x = 0.0
		velocity.z = 0.0
		if _active_left <= 0.0:
			_recovery_left = RECOVERY_S
	elif _recovery_left > 0.0:
		_recovery_left = maxf(_recovery_left - delta, 0.0)
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		_follow_or_attack(delta)
	if spore_owner != null and not bool(spore_owner.call("allows_source_step", self, global_position, velocity * delta)):
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()
	_restored_floor_contact = -1
	_update_attack_feedback()
	if _sprite != null:
		_sprite.animate(Vector2(velocity.x, velocity.z).length() > 0.25 and is_on_floor(), delta)
	_actor_transaction_depth -= 1


func _follow_or_attack(delta: float) -> void:
	# Actual damage remains free to resolve hurt/gravity/knockback. Once its
	# stagger ends, stop approach without arming another attack while the same
	# spore episode waits for grounded, stationary continuation preflight.
	if not _spore_episode_id.is_empty():
		_slow_planar(9.0 * delta)
		return
	if not _hero_is_alive():
		_slow_planar(9.0 * delta)
		return
	var difference: Vector3 = _hero.global_position - global_position
	var planar: Vector3 = Vector3(difference.x, 0.0, difference.z)
	var distance: float = planar.length()
	if distance > AGGRO_RANGE:
		_slow_planar(9.0 * delta)
		return
	if distance > 0.1:
		_facing = planar / distance
		if _sprite != null:
			_sprite.face(_facing)
	if distance <= _attack_reach and absf(difference.y) <= ATTACK_HEIGHT_TOLERANCE:
		_slow_planar(10.0 * delta)
		if _cooldown_left <= 0.0 and _snapshot_grounded():
			_start_windup()
		return
	var current: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var target: Vector3 = _facing * _move_speed if distance > 0.9 else Vector3.ZERO
	current = current.move_toward(target, 12.0 * delta)
	velocity.x = current.x
	velocity.z = current.z
	if _kind == 2 and _snapshot_grounded() and _hop_left <= 0.0 and distance > 2.2:
		velocity.y = 7.8
		_hop_left = 1.45


func _slow_planar(step: float) -> void:
	var current: Vector3 = Vector3(velocity.x, 0.0, velocity.z).move_toward(Vector3.ZERO, step)
	velocity.x = current.x
	velocity.z = current.z


func _start_windup() -> bool:
	if not _can_prepare_attack():
		return false
	_actor_transaction_depth += 1
	_windup_left = _windup_duration
	_attack_facing = _facing
	_attack_origin = global_position
	velocity.x = 0.0
	velocity.z = 0.0
	# Snapshot the same scenery-aware ground footprint for warning and impact.
	# The source remains stationary until this committed exchange finishes.
	var world_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	_warning.mesh = Footprint.cone_mesh(_attack_reach, ATTACK_DOT, false, world_state, global_position, _attack_facing)
	_active_footprint.mesh = Footprint.cone_mesh(_attack_reach, ATTACK_DOT, true, world_state, global_position, _attack_facing)
	var angle: float = atan2(_attack_facing.x, _attack_facing.z)
	_warning.rotation.y = angle
	_active_footprint.rotation.y = angle
	_countdown.rotation.y = angle
	_update_attack_feedback()
	_actor_transaction_depth -= 1
	return true


func _strike() -> void:
	_actor_transaction_depth += 1
	_windup_left = 0.0
	_active_left = ACTIVE_FEEDBACK_S
	_cooldown_left = _attack_interval
	_update_attack_feedback()
	if _fx != null and is_instance_valid(_fx) and _fx.has_method("slash"):
		_fx.call("slash", global_position + _attack_facing * 0.8 + Vector3(0.0, 0.85, 0.0), _attack_facing, COLOR_WARNING)
	if not _hero_is_alive():
		_actor_transaction_depth -= 1
		return
	var difference: Vector3 = _hero.global_position - global_position
	var planar: Vector3 = Vector3(difference.x, 0.0, difference.z)
	var distance: float = planar.length()
	if distance > _attack_reach or absf(difference.y) > ATTACK_HEIGHT_TOLERANCE:
		_actor_transaction_depth -= 1
		return
	if distance > 0.1 and planar.normalized().dot(_attack_facing) < ATTACK_DOT:
		_actor_transaction_depth -= 1
		return
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.7, _hero.global_position + Vector3.UP * 0.7, 1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		_actor_transaction_depth -= 1
		return
	if _hero.has_method("take_damage"):
		_hero.call("take_damage", _attack_damage, _attack_facing * 4.0 + Vector3(0.0, 2.5, 0.0))
	_actor_transaction_depth -= 1


func get_attack_state() -> String:
	if hp <= 0.0 or dead:
		return "defeated"
	if not _spore_episode_id.is_empty() and _spore_phase != "interrupted":
		return "spore_" + _spore_phase
	if _stagger_left > 0.0:
		return "stagger"
	if _windup_left > 0.0:
		return "lock" if _windup_left <= minf(LOCK_LEAD_S, _windup_duration) else "warning"
	if _active_left > 0.0:
		return "active"
	if _recovery_left > 0.0:
		return "recovery"
	return "approach"


## Additive opt-in adapter. A coordinator binds actual stable sources before
## enabling its callbacks. It cannot replace a live binding or acquire inside
## an existing actor/snapshot transaction.
func bind_spore_repulsion(consumer: Node, source_id: String) -> bool:
	if not is_inside_tree() or not is_node_ready() or _snapshot_busy or _actor_transaction_depth > 0 or not is_instance_valid(consumer) or not consumer.is_inside_tree() or not consumer.has_method("consumer_id") or not consumer.has_method("source_binding_matches") or not consumer.has_method("step_source") or not consumer.has_method("allows_source_step") or not consumer.has_method("source_interrupted") or not consumer.has_method("snapshot_boundary_available") or not bool(consumer.call("source_binding_matches", self, source_id)):
		return false
	var consumer_id: String = String(consumer.call("consumer_id"))
	if not _spore_source_id.is_empty():
		return _spore_owner() == consumer and _spore_source_id == source_id and _spore_consumer_id == consumer_id
	_spore_consumer = weakref(consumer)
	_spore_source_id = source_id
	_spore_consumer_id = consumer_id
	return true


## Read-only live response for the owning environmental coordinator. Exposes
## required controller clocks without private-field inspection by that owner.
func get_spore_response_state() -> Dictionary:
	var collision: CollisionShape3D = get_node_or_null("BodyCollision") as CollisionShape3D
	var support_radius: float = -1.0
	var height: float = -1.0
	if collision != null and collision.shape is BoxShape3D:
		var size: Vector3 = (collision.shape as BoxShape3D).size
		support_radius = Vector2(size.x, size.z).length() * 0.5 + 0.01
		height = size.y
	return {"api_revision": "ash-spore-adapter-1", "source_id": _spore_source_id, "consumer_id": _spore_consumer_id, "alive": hp > 0.0 and not dead and not is_queued_for_deletion(), "grounded": _snapshot_grounded(), "position": global_position, "velocity": velocity, "facing": _facing, "cooldown_remaining_s": _cooldown_left, "hurt_remaining_s": maxf(_stagger_left, _hit_flash_left), "body_collision_path": "BodyCollision", "support_radius": support_radius, "height": height, "episode_id": _spore_episode_id, "phase": _spore_phase, "direction": _spore_direction, "progress": _spore_progress, "outside_transaction": not _snapshot_busy and _actor_transaction_depth == 0}


## Called only after pure full-route/union proof. Cancel actual attack state;
## retain HP, every cooldown, hurt/flash/hop clocks, collision and velocity.
## The separate measured route acquires/stops velocity after this barrier.
func cancel_attack_for_spores(consumer: Node, episode_id: String, direction: Vector3) -> bool:
	if _spore_owner() != consumer or _snapshot_busy or _actor_transaction_depth > 0 or not _spore_episode_id.is_empty() or hp <= 0.0 or dead or is_queued_for_deletion() or not direction.is_finite() or absf(direction.y) > 0.00001 or absf(direction.length() - 1.0) > 0.00001 or not _spore_identifier(episode_id):
		return false
	_actor_transaction_depth += 1
	_windup_left = 0.0
	_active_left = 0.0
	_recovery_left = 0.0
	_attack_origin = Vector3.INF
	_spore_episode_id = episode_id
	_spore_phase = "recoil"
	_spore_direction = direction
	_spore_progress = 0.0
	_update_attack_feedback()
	_actor_transaction_depth -= 1
	return true


## Recoil/turn feedback uses only the sprite and logical facing. The actual
## collider/global basis never tilt, move or acquire an impulse/stagger here.
func present_spore_phase(consumer: Node, episode_id: String, phase: String, progress: float) -> bool:
	if _spore_owner() != consumer or _snapshot_busy or _actor_transaction_depth > 0 or episode_id != _spore_episode_id or not ["recoil", "turn", "retreat", "hold", "regroup", "failed"].has(phase) or not is_finite(progress) or progress < 0.0 or progress > 1.0:
		return false
	_actor_transaction_depth += 1
	_spore_phase = phase
	_spore_progress = progress
	if phase != "recoil":
		_facing = _spore_direction
		_sprite.face(_facing)
	_sprite.rotation.z = sin(PI * progress) * 0.08 if phase == "recoil" else 0.0
	_update_attack_feedback()
	_actor_transaction_depth -= 1
	return true


func resume_spore_retreat(consumer: Node, episode_id: String, direction: Vector3) -> bool:
	if _spore_owner() != consumer or _snapshot_busy or _actor_transaction_depth > 0 or episode_id != _spore_episode_id or _spore_phase != "interrupted" or hp <= 0.0 or dead or _stagger_left > 0.0 or _hit_flash_left > 0.0 or not _snapshot_grounded() or velocity.length() > 0.00001 or not direction.is_finite() or absf(direction.y) > 0.00001 or absf(direction.length() - 1.0) > 0.00001:
		return false
	_actor_transaction_depth += 1
	_spore_direction = direction
	_spore_phase = "retreat"
	_spore_progress = 0.0
	_facing = direction
	_sprite.face(_facing)
	_actor_transaction_depth -= 1
	return true


func finish_spore_episode(consumer: Node, episode_id: String) -> bool:
	if _spore_owner() != consumer or _snapshot_busy or _actor_transaction_depth > 0 or episode_id.is_empty() or episode_id != _spore_episode_id:
		return false
	_actor_transaction_depth += 1
	_spore_episode_id = ""
	_spore_phase = "none"
	_spore_progress = 0.0
	_sprite.rotation.z = 0.0
	_actor_transaction_depth -= 1
	return true


func _spore_owner() -> Node:
	var owner: Node = _spore_consumer.get_ref() as Node if _spore_consumer != null else null
	return owner if is_instance_valid(owner) and owner.is_inside_tree() and not owner.is_queued_for_deletion() else null


static func _spore_identifier(value: String) -> bool:
	if value.is_empty() or value.length() > 128:
		return false
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9][A-Za-z0-9_./:-]*$")
	var found: RegExMatch = pattern.search(value)
	return found != null and found.get_string() == value


func _can_prepare_attack() -> bool:
	var preparing: int = 0
	for other: Node in get_tree().get_nodes_in_group("enemies"):
		if other == self or not other.has_method("get_attack_state"):
			continue
		var state: String = other.call("get_attack_state")
		if state == "warning" or state == "lock":
			preparing += 1
	return preparing < MAX_PREPARING_ATTACKERS


func _update_attack_feedback() -> void:
	if _warning == null:
		return
	var alive: bool = hp > 0.0 and not dead
	_warning.visible = alive and _windup_left > 0.0
	_active_footprint.visible = alive and _active_left > 0.0
	_countdown.visible = alive and _windup_left > 0.0
	_recovery_marker.visible = alive and _recovery_left > 0.0
	var remaining_pips: int = ceili(6.0 * _windup_left / _windup_duration)
	for index: int in range(_countdown_pips.size()):
		_countdown_pips[index].visible = index < remaining_pips
	var material: StandardMaterial3D = _warning.material_override as StandardMaterial3D
	material.albedo_color = Color(1.0, 0.88, 0.68) if get_attack_state() == "lock" else COLOR_WARNING


func _hero_is_alive() -> bool:
	return _hero != null and is_instance_valid(_hero) and _hero.get("dead") != true


func _die(impulse: Vector3) -> void:
	if dead or _death_emitted:
		return
	_actor_transaction_depth += 1
	dead = true
	_death_emitted = true
	var spore_owner: Node = _spore_owner()
	if not _spore_episode_id.is_empty():
		_spore_phase = "interrupted"
		_spore_progress = 0.0
		_sprite.rotation.z = 0.0
		if spore_owner != null:
			spore_owner.call("source_interrupted", self, "actual_death")
	if _fx != null and is_instance_valid(_fx) and _fx.has_method("tiny_bleed"):
		_fx.call("tiny_bleed", global_position + Vector3(0.0, 0.8, 0.0), 5, impulse)
	died.emit(global_position)
	queue_free()
	_actor_transaction_depth -= 1


## The drop consumer calls this only after committing its actual stable drop.
## A death signal alone cannot prove that an external reward was spawned.
func mark_drop_spawned() -> bool:
	if not dead or not _death_emitted or _drop_spawned:
		return false
	_drop_spawned = true
	return true


func _set_variant_stats() -> void:
	match _kind:
		1: # Armored: slower and harder to launch.
			max_hp = 56.0
			_move_speed = 1.75
			_attack_damage = 15.0
			_windup_duration = 0.8
			_attack_interval = 1.6
			_knockback_factor = 0.48
		2: # Hopper: fragile and quick, with a periodic leap.
			max_hp = 23.0
			_move_speed = 3.3
			_attack_damage = 8.0
			_windup_duration = 0.42
			_attack_interval = 1.1
			_knockback_factor = 1.25
		_: # Grunt.
			max_hp = 32.0
			_move_speed = 2.6
			_attack_damage = 10.0
			_windup_duration = 0.55
			_attack_interval = 1.25
			_knockback_factor = 1.0


func _build_collision() -> void:
	var collision: CollisionShape3D = get_node_or_null("BodyCollision") as CollisionShape3D
	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = "BodyCollision"
		add_child(collision)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.75, 1.45, 0.65)
	collision.shape = shape
	collision.position = Vector3(0.0, 0.725, 0.0)


func _build_visual() -> void:
	if _sprite != null and is_instance_valid(_sprite):
		_sprite.queue_free()
	_sprite = SpriteScript.new()
	_sprite.name = "EnemySprite"
	var sprite_kind: String = "grunt"
	if _kind == 1:
		sprite_kind = "armored"
	elif _kind == 2:
		sprite_kind = "hopper"
	_sprite.setup(sprite_kind)
	add_child(_sprite)
	_sprite.face(_facing)
	if _warning == null:
		_warning = _floor_visual("AttackWarning", Footprint.cone_mesh(_attack_reach, ATTACK_DOT), COLOR_WARNING)
		_active_footprint = _floor_visual("ActiveAttackFootprint", Footprint.cone_mesh(_attack_reach, ATTACK_DOT, true), Color(1.0, 0.13, 0.15, 0.30))
		_countdown = Node3D.new()
		_countdown.name = "AttackCountdown"
		add_child(_countdown)
		var half_angle: float = acos(ATTACK_DOT)
		for index: int in range(6):
			var pip: MeshInstance3D = MeshInstance3D.new()
			var pip_mesh: BoxMesh = BoxMesh.new()
			pip_mesh.size = Vector3(0.085, 0.025, 0.085)
			pip.mesh = pip_mesh
			pip.material_override = _floor_material(Color(1.0, 0.88, 0.68))
			var angle: float = lerpf(-half_angle * 0.82, half_angle * 0.82, float(index) / 5.0)
			pip.position = Footprint.radial_point(angle, _attack_reach - 0.16) + Vector3.UP * 0.04
			_countdown.add_child(pip)
			_countdown_pips.append(pip)
		_recovery_marker = _floor_visual("RecoveryOpening", Footprint.ring_mesh(0.53), Color(0.94, 0.91, 0.84))
	_update_attack_feedback()


func _floor_visual(node_name: String, mesh: Mesh, color: Color) -> MeshInstance3D:
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.name = node_name
	visual.mesh = mesh
	visual.material_override = _floor_material(color)
	visual.position.y = 0.03
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)
	return visual


func _floor_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


## Snapshot at a paused deferred shell boundary after attack/death callbacks.
## Level-owned stable enemy/drop IDs live outside this shared actor envelope.
## A just-defeated queued node may be captured before its end-of-frame free.
## Disk transport uses JSON.stringify(..., "", true, true), as save_store does;
## shortened float formatting can move a remaining-clock threshold by a tick.
func snapshot_state() -> Dictionary:
	last_snapshot_error = _snapshot_boundary_error(false)
	if not last_snapshot_error.is_empty():
		return {}
	_snapshot_busy = true
	var raw: Dictionary = _role_stats()
	var tint: Color = _sprite.modulate
	var snapshot: Dictionary = {
		"api_revision": SNAPSHOT_API_REVISION, "schema_version": SNAPSHOT_SCHEMA_VERSION,
		"actor_type": "AshEnemy", "kind": _kind,
		"resources": {"hp": hp, "max_hp": max_hp},
		"lifecycle": {"dead": dead or hp <= 0.0, "death_emitted": _death_emitted, "drop_spawned": _drop_spawned},
		# No difficulty profile has been applied by this prototype controller.
		# Immutable raw/resolved profile provenance requires a future migration.
		"role": {"raw_stats": raw.duplicate(true), "resolved_stats": raw.duplicate(true), "difficulty": {}},
		"motion": {
			"position": SnapshotCodec.vector3(global_position),
			"basis": [SnapshotCodec.vector3(global_basis.x), SnapshotCodec.vector3(global_basis.y), SnapshotCodec.vector3(global_basis.z)],
			"velocity": SnapshotCodec.vector3(velocity), "grounded": _snapshot_grounded(),
			"facing": SnapshotCodec.vector3(_facing), "attack_facing": SnapshotCodec.vector3(_attack_facing),
		},
		"clocks": {
			"windup_left_s": _windup_left, "active_left_s": _active_left, "recovery_left_s": _recovery_left,
			"cooldown_left_s": _cooldown_left, "stagger_left_s": _stagger_left,
			"hop_left_s": _hop_left, "hit_flash_left_s": _hit_flash_left,
		},
		"attack_geometry": {
			"world_origin": null if _attack_origin == Vector3.INF else SnapshotCodec.vector3(_attack_origin),
			"shape": "radial_cone", "reach": _attack_reach, "cone_min_dot": ATTACK_DOT,
			"origin_disk_radius": Footprint.SOURCE_RADIUS, "max_vertical_distance": ATTACK_HEIGHT_TOLERANCE,
			"los": {"policy": "scenery_ray_from_source_to_target", "collision_mask": 1, "height": Footprint.LOS_HEIGHT},
		},
		"presentation": {
			"sprite_kind": _sprite.get("_kind"), "frame": _sprite.get("_frame"),
			"animation_time_s": _sprite.get("_animation_time"), "modulate": [tint.r, tint.g, tint.b, tint.a],
		},
	}
	if not _spore_source_id.is_empty():
		snapshot["repulsion"] = {"api_revision": "ash-spore-adapter-1", "consumer_id": _spore_consumer_id, "source_id": _spore_source_id, "episode_id": _spore_episode_id, "phase": _spore_phase, "direction": SnapshotCodec.vector3(_spore_direction), "progress": _spore_progress}
	last_snapshot_error = _validate_snapshot(snapshot)
	_snapshot_busy = false
	return snapshot.duplicate(true) if last_snapshot_error.is_empty() else {}


func snapshot_error(snapshot: Dictionary) -> String:
	var error: String = _snapshot_boundary_error(true)
	if not error.is_empty():
		return error
	_snapshot_busy = true
	error = _validate_snapshot(snapshot)
	_snapshot_busy = false
	return error


## Environmental capture-context validation also accepts the just-defeated
## queued source before end-of-frame removal. It does not authorize restoring
## that queued node; ordinary restore_state still requires a ready replacement.
func spore_snapshot_error(snapshot: Dictionary) -> String:
	if _spore_source_id.is_empty():
		return "Spore validation requires the immutable opt-in binding"
	var error: String = _snapshot_boundary_error(false)
	if not error.is_empty():
		return error
	_snapshot_busy = true
	error = _validate_snapshot(snapshot)
	_snapshot_busy = false
	return error


## Direct commit after full validation. Never configure, start, strike, die,
## emit a drop/death signal, or run a hidden simulation tick during restore.
func restore_state(snapshot: Dictionary) -> bool:
	last_snapshot_error = _snapshot_boundary_error(true)
	if not last_snapshot_error.is_empty():
		return false
	_snapshot_busy = true
	last_snapshot_error = _validate_snapshot(snapshot)
	if not last_snapshot_error.is_empty():
		_snapshot_busy = false
		return false
	var accepted: Dictionary = snapshot.duplicate(true)
	var role: Dictionary = accepted.role.resolved_stats
	var motion: Dictionary = accepted.motion
	var clocks: Dictionary = accepted.clocks
	var lifecycle: Dictionary = accepted.lifecycle
	_kind = int(accepted.kind)
	max_hp = float(accepted.resources.max_hp)
	hp = float(accepted.resources.hp)
	dead = lifecycle.dead
	_death_emitted = lifecycle.death_emitted
	_drop_spawned = lifecycle.drop_spawned
	collision_layer = 0 if dead else 2
	collision_mask = 0 if dead else 1
	_move_speed = float(role.move_speed)
	_attack_damage = float(role.attack_damage)
	_attack_reach = float(role.attack_reach)
	_windup_duration = float(role.windup_s)
	_attack_interval = float(role.attack_interval_s)
	_knockback_factor = float(role.knockback_factor)
	var columns: Array = motion.basis
	global_transform = Transform3D(Basis(SnapshotCodec.read_vector3(columns[0]), SnapshotCodec.read_vector3(columns[1]), SnapshotCodec.read_vector3(columns[2])), SnapshotCodec.read_vector3(motion.position))
	if motion.grounded:
		var exact_transform: Transform3D = global_transform
		apply_floor_snap()
		global_transform = exact_transform
	velocity = SnapshotCodec.read_vector3(motion.velocity)
	_restored_floor_contact = 1 if motion.grounded else 0
	_facing = SnapshotCodec.read_vector3(motion.facing)
	_attack_facing = SnapshotCodec.read_vector3(motion.attack_facing)
	_windup_left = float(clocks.windup_left_s)
	_active_left = float(clocks.active_left_s)
	_recovery_left = float(clocks.recovery_left_s)
	_cooldown_left = float(clocks.cooldown_left_s)
	_stagger_left = float(clocks.stagger_left_s)
	_hop_left = float(clocks.hop_left_s)
	_hit_flash_left = float(clocks.hit_flash_left_s)
	_attack_origin = Vector3.INF if accepted.attack_geometry.world_origin == null else SnapshotCodec.read_vector3(accepted.attack_geometry.world_origin)
	# Restore geometry against the already restored static scenery. No hero
	# location, preparation count or new attack request participates in this.
	_rebuild_snapshot_geometry()
	_sprite.setup(_sprite_kind(_kind))
	_sprite.set("_animation_time", float(accepted.presentation.animation_time_s))
	_sprite.set("_frame", int(accepted.presentation.frame))
	_sprite.face(_facing)
	_sprite.call("_show_frame")
	var tint: Array = accepted.presentation.modulate
	_sprite.modulate = Color(float(tint[0]), float(tint[1]), float(tint[2]), float(tint[3]))
	if accepted.has("repulsion"):
		_spore_episode_id = accepted.repulsion.episode_id
		_spore_phase = accepted.repulsion.phase
		_spore_direction = SnapshotCodec.read_vector3(accepted.repulsion.direction)
		_spore_progress = float(accepted.repulsion.progress)
		_sprite.rotation.z = sin(PI * _spore_progress) * 0.08 if _spore_phase == "recoil" else 0.0
	_sprite.visible = not dead
	if dead:
		remove_from_group("enemies")
		collision_layer = 0
		collision_mask = 0
	else:
		add_to_group("enemies")
		collision_layer = 2
		collision_mask = 1
	_update_attack_feedback()
	_snapshot_busy = false
	last_snapshot_error = ""
	return true


func _snapshot_boundary_error(for_restore: bool) -> String:
	if not is_inside_tree() or not is_node_ready() or not is_instance_valid(_sprite) or not is_instance_valid(_warning) or not is_instance_valid(_active_footprint) or not is_instance_valid(_countdown) or not is_instance_valid(_recovery_marker) or _countdown_pips.size() != 6:
		return "Enemy snapshots require a ready actor with its shared feedback nodes"
	if not _warning.material_override is StandardMaterial3D:
		return "Enemy warning material is unavailable"
	for pip: MeshInstance3D in _countdown_pips:
		if not is_instance_valid(pip):
			return "Enemy snapshot countdown nodes are unavailable"
	if not get_tree().paused:
		return "Enemy snapshots require the paused deferred shell boundary"
	if _snapshot_busy or _actor_transaction_depth > 0:
		return "Enemy snapshots cannot run inside actor transactions or callbacks"
	if not _spore_source_id.is_empty() and (_spore_owner() == null or not bool(_spore_owner().call("snapshot_boundary_available"))):
		return "Bound spore actor requires its live coordinator outside callbacks"
	if for_restore and is_queued_for_deletion():
		return "Cannot restore an enemy already queued for deletion; create a ready replacement"
	if not get_platform_velocity().is_zero_approx() or not get_platform_angular_velocity().is_zero_approx():
		return "Enemy snapshot revision 1 requires static floor; moving-platform contact state is unsupported"
	return ""


func _snapshot_grounded() -> bool:
	return _restored_floor_contact == 1 if _restored_floor_contact >= 0 else is_on_floor()


func _role_stats() -> Dictionary:
	return {
		"max_hp": max_hp, "move_speed": _move_speed, "attack_damage": _attack_damage,
		"attack_reach": _attack_reach, "windup_s": _windup_duration,
		"attack_interval_s": _attack_interval, "knockback_factor": _knockback_factor,
		"lock_s": LOCK_LEAD_S, "active_s": ACTIVE_FEEDBACK_S, "recovery_s": RECOVERY_S,
		"hop_speed": 7.8, "hop_interval_s": 1.45,
	}


## Pure full external-record validation for a removed defeated opt-in actor.
## Level-owned tombstones contain its actual captured defeat, not fresh HP or
## invented drop state. This validates JSON, never constructs a replacement.
static func spore_record_error(snapshot: Dictionary, consumer_id: String, source_id: String) -> String:
	if not _spore_identifier(consumer_id) or not _spore_identifier(source_id):
		return "Immutable spore consumer/source identities required"
	return _record_error(snapshot, source_id, consumer_id)


func _validate_snapshot(snapshot: Dictionary) -> String:
	return _record_error(snapshot, _spore_source_id, _spore_consumer_id)


static func _record_error(snapshot: Dictionary, bound_source_id: String, bound_consumer_id: String) -> String:
	var error: String = SnapshotCodec.value_error(snapshot)
	if not error.is_empty():
		return error
	var required: Array = ["api_revision", "schema_version", "actor_type", "kind", "resources", "lifecycle", "role", "motion", "clocks", "attack_geometry", "presentation"]
	if not bound_source_id.is_empty():
		required.append("repulsion")
	error = SnapshotCodec.keys_error(snapshot, required)
	if not error.is_empty():
		return error
	if snapshot.api_revision != SNAPSHOT_API_REVISION or not SnapshotCodec.is_integer(snapshot.schema_version, SNAPSHOT_SCHEMA_VERSION, SNAPSHOT_SCHEMA_VERSION) or snapshot.actor_type != "AshEnemy" or not SnapshotCodec.is_integer(snapshot.kind, 0, 2):
		return "Unsupported enemy snapshot identity/API/schema/kind"
	for key: String in ["resources", "lifecycle", "role", "motion", "clocks", "attack_geometry", "presentation"]:
		if not snapshot[key] is Dictionary:
			return "Enemy snapshot requires a dictionary: " + key
	var resources: Dictionary = snapshot.resources
	error = SnapshotCodec.keys_error(resources, ["hp", "max_hp"])
	if not error.is_empty():
		return error
	if not SnapshotCodec.in_range(resources.max_hp, 0.001, 1000000.0) or not SnapshotCodec.in_range(resources.hp, 0.0, float(resources.max_hp)):
		return "Enemy HP must fit its raw role maximum"
	var lifecycle: Dictionary = snapshot.lifecycle
	error = SnapshotCodec.keys_error(lifecycle, ["dead", "death_emitted", "drop_spawned"])
	if not error.is_empty():
		return error
	for key: String in ["dead", "death_emitted", "drop_spawned"]:
		if not lifecycle[key] is bool:
			return "Enemy lifecycle flags must be boolean"
	if lifecycle.dead != (float(resources.hp) == 0.0) or (not lifecycle.dead and (lifecycle.death_emitted or lifecycle.drop_spawned)) or (lifecycle.drop_spawned and not lifecycle.death_emitted):
		return "Enemy defeat/death/drop lifecycle is inconsistent"
	var envelope: Dictionary = snapshot.role
	error = SnapshotCodec.keys_error(envelope, ["raw_stats", "resolved_stats", "difficulty"])
	if not error.is_empty():
		return error
	if not envelope.raw_stats is Dictionary or not envelope.resolved_stats is Dictionary or not envelope.difficulty is Dictionary or not envelope.difficulty.is_empty():
		return "Enemy snapshot revision 1 does not claim applied difficulty/scheduler state"
	if not SnapshotCodec.same_values(envelope.raw_stats, envelope.resolved_stats):
		return "Unprofiled enemy raw and resolved role data must match"
	var role: Dictionary = envelope.raw_stats
	error = SnapshotCodec.keys_error(role, ["max_hp", "move_speed", "attack_damage", "attack_reach", "windup_s", "attack_interval_s", "knockback_factor", "lock_s", "active_s", "recovery_s", "hop_speed", "hop_interval_s"])
	if not error.is_empty():
		return error
	for key: String in ["max_hp", "move_speed", "attack_damage", "attack_reach", "windup_s", "attack_interval_s", "knockback_factor"]:
		if not SnapshotCodec.in_range(role[key], 0.001, 1000000.0):
			return "Invalid positive enemy raw stat: " + key
	if not SnapshotCodec.same_values(role.max_hp, resources.max_hp) or not SnapshotCodec.same_values(role.lock_s, LOCK_LEAD_S) or not SnapshotCodec.same_values(role.active_s, ACTIVE_FEEDBACK_S) or not SnapshotCodec.same_values(role.recovery_s, RECOVERY_S) or not SnapshotCodec.same_values(role.hop_speed, 7.8) or not SnapshotCodec.same_values(role.hop_interval_s, 1.45):
		return "Enemy role HP/shared timing constants do not match this revision"
	var motion: Dictionary = snapshot.motion
	error = SnapshotCodec.keys_error(motion, ["position", "basis", "velocity", "grounded", "facing", "attack_facing"])
	if not error.is_empty():
		return error
	if not SnapshotCodec.is_vector3(motion.position) or not SnapshotCodec.is_vector3(motion.velocity) or not motion.grounded is bool or not _snapshot_direction_valid(motion.facing) or not _snapshot_direction_valid(motion.attack_facing):
		return "Enemy motion requires finite position/velocity and exact planar facing"
	if not motion.basis is Array or motion.basis.size() != 3:
		return "Enemy basis must contain three vectors"
	for column: Variant in motion.basis:
		if not SnapshotCodec.is_vector3(column):
			return "Invalid enemy basis vector"
	var columns: Array = motion.basis
	var restored_basis := Basis(SnapshotCodec.read_vector3(columns[0]), SnapshotCodec.read_vector3(columns[1]), SnapshotCodec.read_vector3(columns[2]))
	if not is_finite(restored_basis.determinant()) or absf(restored_basis.determinant()) < 0.000001:
		return "Enemy basis must be finite and invertible"
	var clocks: Dictionary = snapshot.clocks
	error = SnapshotCodec.keys_error(clocks, ["windup_left_s", "active_left_s", "recovery_left_s", "cooldown_left_s", "stagger_left_s", "hop_left_s", "hit_flash_left_s"])
	if not error.is_empty():
		return error
	var limits: Dictionary = {"windup_left_s": role.windup_s, "active_left_s": ACTIVE_FEEDBACK_S, "recovery_left_s": RECOVERY_S, "cooldown_left_s": role.attack_interval_s, "stagger_left_s": 0.410001, "hop_left_s": 1.45, "hit_flash_left_s": 0.12}
	for key: String in limits:
		if not SnapshotCodec.in_range(clocks[key], 0.0, float(limits[key])):
			return "Invalid remaining enemy clock: " + key
	var phases: int = int(float(clocks.windup_left_s) > 0.0) + int(float(clocks.active_left_s) > 0.0) + int(float(clocks.recovery_left_s) > 0.0)
	if phases > 1 or (float(clocks.stagger_left_s) > 0.0 and phases > 0):
		return "Enemy attack/stagger clocks cannot overlap"
	if snapshot.has("repulsion"):
		var stamp: Variant = snapshot.repulsion
		if not stamp is Dictionary or not SnapshotCodec.keys_error(stamp, ["api_revision", "consumer_id", "source_id", "episode_id", "phase", "direction", "progress"]).is_empty():
			return "Invalid opt-in spore adapter envelope"
		if stamp.api_revision != "ash-spore-adapter-1" or stamp.consumer_id != bound_consumer_id or stamp.source_id != bound_source_id or not stamp.episode_id is String or not stamp.phase is String or not _snapshot_direction_valid(stamp.direction) or not SnapshotCodec.in_range(stamp.progress, 0.0, 1.0):
			return "Spore adapter identity/pose must match its immutable binding"
		if stamp.phase == "none":
			if stamp.episode_id != "" or float(stamp.progress) != 0.0:
				return "Inactive spore adapter cannot carry an episode/progress"
		elif not _spore_identifier(stamp.episode_id) or not ["recoil", "turn", "retreat", "hold", "regroup", "failed", "interrupted"].has(stamp.phase) or phases > 0:
			return "Spore episode must suppress actual attack phases"
	var geometry: Dictionary = snapshot.attack_geometry
	var expected_geometry: Dictionary = {
		"world_origin": geometry.get("world_origin"), "shape": "radial_cone", "reach": role.attack_reach,
		"cone_min_dot": ATTACK_DOT, "origin_disk_radius": Footprint.SOURCE_RADIUS,
		"max_vertical_distance": ATTACK_HEIGHT_TOLERANCE,
		"los": {"policy": "scenery_ray_from_source_to_target", "collision_mask": 1, "height": Footprint.LOS_HEIGHT},
	}
	if not SnapshotCodec.same_values(geometry, expected_geometry):
		return "Enemy warning geometry must match the snapshotted role and LOS policy"
	if geometry.world_origin != null and not SnapshotCodec.is_vector3(geometry.world_origin):
		return "Committed enemy source must be a finite vector"
	if phases > 0 and geometry.world_origin == null:
		return "Committed enemy phases require the original geometry source"
	var presentation: Dictionary = snapshot.presentation
	error = SnapshotCodec.keys_error(presentation, ["sprite_kind", "frame", "animation_time_s", "modulate"])
	if not error.is_empty():
		return error
	if presentation.sprite_kind != _sprite_kind(int(snapshot.kind)) or not SnapshotCodec.is_integer(presentation.frame, 0, 1) or not SnapshotCodec.in_range(presentation.animation_time_s, 0.0, 1000000000000.0):
		return "Invalid enemy locomotion pose/clock"
	if int(presentation.frame) != int(float(presentation.animation_time_s) * 5.0) % 2:
		return "Enemy locomotion frame must match its simulation clock"
	if not presentation.modulate is Array or presentation.modulate.size() != 4:
		return "Enemy presentation tint requires four components"
	for component: Variant in presentation.modulate:
		if not SnapshotCodec.in_range(component, 0.0, 10.0):
			return "Invalid enemy presentation tint"
	return ""


static func _snapshot_direction_valid(value: Variant) -> bool:
	if not SnapshotCodec.is_vector3(value):
		return false
	var direction: Vector3 = SnapshotCodec.read_vector3(value)
	return absf(direction.y) < 0.000001 and is_equal_approx(direction.length_squared(), 1.0)


static func _sprite_kind(kind: int) -> String:
	return "armored" if kind == 1 else ("hopper" if kind == 2 else "grunt")


func _rebuild_snapshot_geometry() -> void:
	var origin: Vector3 = global_position if _attack_origin == Vector3.INF else _attack_origin
	var world_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	_warning.mesh = Footprint.cone_mesh(_attack_reach, ATTACK_DOT, false, world_state, origin, _attack_facing)
	_active_footprint.mesh = Footprint.cone_mesh(_attack_reach, ATTACK_DOT, true, world_state, origin, _attack_facing)
	var angle: float = atan2(_attack_facing.x, _attack_facing.z)
	_warning.rotation.y = angle
	_active_footprint.rotation.y = angle
	_countdown.rotation.y = angle
	var half_angle: float = acos(ATTACK_DOT)
	for index: int in range(_countdown_pips.size()):
		var pip_angle: float = lerpf(-half_angle * 0.82, half_angle * 0.82, float(index) / 5.0)
		_countdown_pips[index].position = Footprint.radial_point(pip_angle, _attack_reach - 0.16) + Vector3.UP * 0.04
