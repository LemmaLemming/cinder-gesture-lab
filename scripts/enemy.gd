class_name AshEnemy
extends CharacterBody3D

signal died(where: Vector3)

const SpriteScript = preload("res://scripts/pixel_sprite.gd")
const Footprint = preload("res://scripts/attack_footprint.gd")
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


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	add_to_group("enemies")
	_build_collision()
	_build_visual()


func configure(hero: Node3D, fx: Node, kind: int = 0) -> void:
	_hero = hero
	_fx = fx
	_kind = clampi(kind, 0, 2)
	_set_variant_stats()
	hp = max_hp
	if is_inside_tree():
		_build_visual()


func take_damage(amount: float, impulse: Vector3) -> Dictionary:
	var was_alive: bool = hp > 0.0 and not is_queued_for_deletion()
	var result: Dictionary = {
		"accepted": false,
		"hp_damage": 0.0,
		"target_id": get_instance_id(),
		"target_alive_before_hit": was_alive,
	}
	if not was_alive or amount <= 0.0:
		return result
	var old_hp: float = hp
	hp = maxf(0.0, hp - amount)
	result["accepted"] = true
	result["hp_damage"] = old_hp - hp
	if hp > 0.0 and _fx != null and is_instance_valid(_fx) and _fx.has_method("tiny_bleed"):
		_fx.call("tiny_bleed", global_position + Vector3(0.0, 0.8, 0.0), 3, impulse)
	if hp <= 0.0:
		_die(impulse)
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
	return result


func _physics_process(delta: float) -> void:
	if hp <= 0.0:
		return
	if not is_on_floor():
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
	move_and_slide()
	_update_attack_feedback()
	if _sprite != null:
		_sprite.animate(Vector2(velocity.x, velocity.z).length() > 0.25 and is_on_floor(), delta)


func _follow_or_attack(delta: float) -> void:
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
		if _cooldown_left <= 0.0 and is_on_floor():
			_start_windup()
		return
	var current: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var target: Vector3 = _facing * _move_speed if distance > 0.9 else Vector3.ZERO
	current = current.move_toward(target, 12.0 * delta)
	velocity.x = current.x
	velocity.z = current.z
	if _kind == 2 and is_on_floor() and _hop_left <= 0.0 and distance > 2.2:
		velocity.y = 7.8
		_hop_left = 1.45


func _slow_planar(step: float) -> void:
	var current: Vector3 = Vector3(velocity.x, 0.0, velocity.z).move_toward(Vector3.ZERO, step)
	velocity.x = current.x
	velocity.z = current.z


func _start_windup() -> bool:
	if not _can_prepare_attack():
		return false
	_windup_left = _windup_duration
	_attack_facing = _facing
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
	return true


func _strike() -> void:
	_windup_left = 0.0
	_active_left = ACTIVE_FEEDBACK_S
	_cooldown_left = _attack_interval
	_update_attack_feedback()
	if _fx != null and is_instance_valid(_fx) and _fx.has_method("slash"):
		_fx.call("slash", global_position + _attack_facing * 0.8 + Vector3(0.0, 0.85, 0.0), _attack_facing, COLOR_WARNING)
	if not _hero_is_alive():
		return
	var difference: Vector3 = _hero.global_position - global_position
	var planar: Vector3 = Vector3(difference.x, 0.0, difference.z)
	var distance: float = planar.length()
	if distance > _attack_reach or absf(difference.y) > ATTACK_HEIGHT_TOLERANCE:
		return
	if distance > 0.1 and planar.normalized().dot(_attack_facing) < ATTACK_DOT:
		return
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.7, _hero.global_position + Vector3.UP * 0.7, 1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return
	if _hero.has_method("take_damage"):
		_hero.call("take_damage", _attack_damage, _attack_facing * 4.0 + Vector3(0.0, 2.5, 0.0))


func get_attack_state() -> String:
	if hp <= 0.0:
		return "defeated"
	if _stagger_left > 0.0:
		return "stagger"
	if _windup_left > 0.0:
		return "lock" if _windup_left <= minf(LOCK_LEAD_S, _windup_duration) else "warning"
	if _active_left > 0.0:
		return "active"
	if _recovery_left > 0.0:
		return "recovery"
	return "approach"


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
	_warning.visible = _windup_left > 0.0
	_active_footprint.visible = _active_left > 0.0
	_countdown.visible = _windup_left > 0.0
	_recovery_marker.visible = _recovery_left > 0.0
	var remaining_pips: int = ceili(6.0 * _windup_left / _windup_duration)
	for index: int in range(_countdown_pips.size()):
		_countdown_pips[index].visible = index < remaining_pips
	var material: StandardMaterial3D = _warning.material_override as StandardMaterial3D
	material.albedo_color = Color(1.0, 0.88, 0.68) if get_attack_state() == "lock" else COLOR_WARNING


func _hero_is_alive() -> bool:
	return _hero != null and is_instance_valid(_hero) and _hero.get("dead") != true


func _die(impulse: Vector3) -> void:
	if _fx != null and is_instance_valid(_fx) and _fx.has_method("tiny_bleed"):
		_fx.call("tiny_bleed", global_position + Vector3(0.0, 0.8, 0.0), 5, impulse)
	died.emit(global_position)
	queue_free()


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
