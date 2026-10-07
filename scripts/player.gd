class_name CinderPlayer
extends CharacterBody3D

signal fired(kind: String)
signal died

const SpriteScript = preload("res://scripts/pixel_sprite.gd")
const DASH_SPEED: float = 15.0
const DASH_DURATION: float = 0.18
const DASH_COOLDOWN: float = 0.34
const GRAVITY: float = 24.0
const IVORY: Color = Color(0.94, 0.86, 0.82)
const RED: Color = Color(0.94, 0.045, 0.09)

var hp: float = 100.0
var max_hp: float = 100.0
var shells: int = 2
var max_shells: int = 2
var dead: bool = false
var facing: Vector3 = Vector3(0, 0, -1)
var slash_damage: float = 20.0
var blast_damage: float = 42.0
var fx: Node
var _sprite: LabSprite
var _dash_direction: Vector3 = Vector3.ZERO
var _queued_dash: Vector3 = Vector3.ZERO
var _dash_left: float = 0.0
var _dash_cooldown: float = 0.0
var _slash_cd: float = 0.0
var _blast_cd: float = 0.0
var _reload: float = 0.0
var _invulnerable: float = 0.0
var _knockback_left: float = 0.0
var _trail_left: float = 0.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 0.18
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.45
	collision.shape = shape
	collision.position.y = 0.73
	add_child(collision)
	_sprite = SpriteScript.new()
	_sprite.setup("player")
	add_child(_sprite)
	_sprite.face(facing)
	# A floor marker anchors the billboard sprite to its collision position.
	var shadow := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.38
	mesh.bottom_radius = 0.38
	mesh.height = 0.012
	mesh.radial_segments = 8
	shadow.mesh = mesh
	shadow.position.y = 0.015
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.02, 0.01, 0.025)
	shadow.material_override = material
	add_child(shadow)

func request_dash(direction: Vector3) -> bool:
	if dead:
		return false
	var horizontal := Vector3(direction.x, 0, direction.z)
	if horizontal.length_squared() < 0.001:
		return false
	horizontal = horizontal.normalized()
	if _dash_cooldown > 0.0:
		_queued_dash = horizontal
		return false
	_start_dash(horizontal)
	return true

func _start_dash(direction: Vector3) -> void:
	_dash_direction = direction
	facing = direction
	_sprite.face(facing)
	_dash_left = DASH_DURATION
	_dash_cooldown = DASH_COOLDOWN
	_invulnerable = maxf(_invulnerable, 0.12)
	_trail_left = 0.0
	_queued_dash = Vector3.ZERO
	if fx:
		fx.dash_trail(global_position + Vector3.UP * 0.08, direction, RED)
	fired.emit("dash")

func _physics_process(delta: float) -> void:
	if dead:
		return
	_dash_cooldown = maxf(_dash_cooldown - delta, 0.0)
	_slash_cd = maxf(_slash_cd - delta, 0.0)
	_blast_cd = maxf(_blast_cd - delta, 0.0)
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	if _dash_cooldown <= 0.0 and _queued_dash.length_squared() > 0.0:
		_start_dash(_queued_dash)
	if _dash_left > 0.0:
		# Scale the last tick so each swipe travels the same distance.
		var fraction: float = minf(_dash_left / delta, 1.0)
		velocity.x = _dash_direction.x * DASH_SPEED * fraction
		velocity.z = _dash_direction.z * DASH_SPEED * fraction
		_dash_left = maxf(_dash_left - delta, 0.0)
		_trail_left -= delta
		if _trail_left <= 0.0 and fx:
			fx.dash_trail(global_position + Vector3.UP * 0.08, _dash_direction, RED)
			_trail_left = 0.055
	elif _knockback_left > 0.0:
		_knockback_left -= delta
		velocity.x = move_toward(velocity.x, 0.0, delta * 25.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 25.0)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	move_and_slide()
	_sprite.animate(_dash_left > 0.0, delta)
	_sprite.modulate = RED if _invulnerable > 0.12 and int(_invulnerable * 25.0) % 2 == 0 else Color.WHITE
	if shells < max_shells:
		_reload += delta
		if _reload >= 1.15:
			shells += 1
			_reload = 0.0

func slash(direction: Vector3 = Vector3.ZERO) -> int:
	if _slash_cd > 0.0 or dead:
		return 0
	_face_attack(direction)
	_slash_cd = 0.30
	if fx:
		fx.slash(global_position + Vector3.UP * 0.65, facing, IVORY)
		fx.sound("slash")
	var hits: int = _hit_targets(2.0, 0.05, slash_damage, facing * 3.5 + Vector3.UP * 2.0)
	if hits > 0:
		_reload += 0.45
	fired.emit("slash")
	return hits

func blast(direction: Vector3 = Vector3.ZERO) -> int:
	if _blast_cd > 0.0 or dead or shells <= 0:
		return 0
	_face_attack(direction)
	shells -= 1
	_reload = 0.0
	_blast_cd = 0.45
	if fx:
		fx.muzzle(global_position + facing * 0.65 + Vector3.UP * 0.65, facing)
		fx.sound("blast")
	var hits: int = _hit_targets(3.1, 0.50, blast_damage, facing * 10.0 + Vector3.UP * 4.0)
	fired.emit("blast")
	return hits

func take_damage(amount: float, impulse: Vector3) -> void:
	if _invulnerable > 0.0 or dead:
		return
	hp = maxf(hp - amount, 0.0)
	velocity += impulse
	_knockback_left = 0.16
	_invulnerable = 0.8
	if fx:
		fx.burst(global_position + Vector3.UP * 0.75, RED, 10, 4.0)
		fx.sound("hit")
	fired.emit("hurt")
	if hp <= 0.0:
		dead = true
		died.emit()

func _face_attack(direction: Vector3) -> void:
	var horizontal := Vector3(direction.x, 0, direction.z)
	if horizontal.length_squared() > 0.001:
		facing = horizontal.normalized()
	_sprite.face(facing)

func _hit_targets(reach: float, cone: float, damage: float, impulse: Vector3) -> int:
	var hits: int = 0
	for target in get_tree().get_nodes_in_group("enemies"):
		var offset: Vector3 = target.global_position - global_position
		var vertical: float = absf(offset.y)
		offset.y = 0.0
		if target.hp <= 0.0 or offset.length() > reach or vertical > 1.4:
			continue
		if offset.length() > 0.1 and offset.normalized().dot(facing) < cone:
			continue
		var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.7, target.global_position + Vector3.UP * 0.7, 1)
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			continue
		target.take_damage(damage, impulse)
		hits += 1
	return hits
