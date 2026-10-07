class_name AshEnemy
extends CharacterBody3D

signal died(where: Vector3)

const SpriteScript = preload("res://scripts/pixel_sprite.gd")
const GRAVITY: float = 24.0
const AGGRO_RANGE: float = 11.0
const ATTACK_HEIGHT_TOLERANCE: float = 1.35
const ATTACK_DOT: float = 0.55
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
var _cooldown_left: float = 0.0
var _stagger_left: float = 0.0
var _hit_flash_left: float = 0.0
var _hop_left: float = 0.0
var _sprite: LabSprite
var _warning: MeshInstance3D


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


func take_damage(amount: float, impulse: Vector3) -> void:
	if hp <= 0.0:
		return
	hp = maxf(0.0, hp - maxf(amount, 0.0))
	if _fx != null and is_instance_valid(_fx) and _fx.has_method("burst"):
		_fx.call("burst", global_position + Vector3(0.0, 0.8, 0.0), COLOR_CRIMSON, 9, 3.0)
	if hp <= 0.0:
		_die(impulse)
		return
	_hit_flash_left = 0.12
	_windup_left = 0.0
	if _warning != null:
		_warning.visible = false
	var adjusted_impulse: Vector3 = impulse * _knockback_factor
	velocity += adjusted_impulse
	velocity.y = maxf(velocity.y, adjusted_impulse.y)
	_stagger_left = maxf(_stagger_left, 0.14 + minf(adjusted_impulse.length() * 0.035, 0.27))


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
		_sprite.modulate = COLOR_HIT if _hit_flash_left > 0.0 else Color.WHITE
	if _stagger_left > 0.0:
		_stagger_left = maxf(0.0, _stagger_left - delta)
		_slow_planar(5.0 * delta)
	elif _windup_left > 0.0:
		_windup_left -= delta
		_slow_planar(12.0 * delta)
		if _windup_left <= 0.0:
			_strike()
	else:
		_follow_or_attack(delta)
	move_and_slide()
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


func _start_windup() -> void:
	_windup_left = _windup_duration
	velocity.x = 0.0
	velocity.z = 0.0
	if _warning != null:
		_warning.visible = true
		_warning.position = _facing * (_attack_reach * 0.5) + Vector3(0.0, 0.03, 0.0)
		_warning.rotation.y = atan2(_facing.x, _facing.z)
		_warning.scale.z = _attack_reach


func _strike() -> void:
	if _warning != null:
		_warning.visible = false
	_cooldown_left = _attack_interval
	if _fx != null and is_instance_valid(_fx) and _fx.has_method("slash"):
		_fx.call("slash", global_position + _facing * 0.8 + Vector3(0.0, 0.85, 0.0), _facing, COLOR_WARNING)
	if not _hero_is_alive():
		return
	var difference: Vector3 = _hero.global_position - global_position
	var planar: Vector3 = Vector3(difference.x, 0.0, difference.z)
	var distance: float = planar.length()
	if distance > _attack_reach or absf(difference.y) > ATTACK_HEIGHT_TOLERANCE:
		return
	if distance > 0.1 and planar.normalized().dot(_facing) < ATTACK_DOT:
		return
	if _hero.has_method("take_damage"):
		_hero.call("take_damage", _attack_damage, _facing * 4.0 + Vector3(0.0, 2.5, 0.0))


func _hero_is_alive() -> bool:
	return _hero != null and is_instance_valid(_hero) and _hero.get("dead") != true


func _die(impulse: Vector3) -> void:
	if _fx != null and is_instance_valid(_fx) and _fx.has_method("burst"):
		_fx.call("burst", global_position + Vector3(0.0, 0.8, 0.0), COLOR_CRIMSON, 24, 6.0 + impulse.length() * 0.25)
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
		_warning = MeshInstance3D.new()
		_warning.name = "AttackWarning"
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(0.9, 0.04, 1.0)
		_warning.mesh = mesh
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = COLOR_WARNING
		_warning.material_override = material
		add_child(_warning)
	_warning.visible = false
