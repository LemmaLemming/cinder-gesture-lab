class_name CinderPlayer
extends CharacterBody3D

signal fired(kind: String)
signal died
signal action_resolved(kind: String, hits: int, damage: float)
signal equipment_changed(item_id: String)

const SpriteScript = preload("res://scripts/pixel_sprite.gd")
const EquipmentScript = preload("res://scripts/equipment.gd")
const DASH_SPEED: float = 15.0
const DASH_DURATION: float = 0.18
const DASH_COOLDOWN: float = 0.34
const GRAVITY: float = 24.0
const IVORY: Color = Color(0.94, 0.86, 0.82)
const RED: Color = Color(0.94, 0.045, 0.09)
const DUST: Color = Color(0.66, 0.70, 0.74)
const LANDING_VISUAL_DURATION: float = 0.22

var hp: float = 100.0
var max_hp: float = 100.0
var shells: int = 2
var max_shells: int = 2
var dead: bool = false
var facing: Vector3 = Vector3(0, 0, -1)
var slash_damage: float = 20.0
var blast_damage: float = 42.0
var equipment = EquipmentScript.new()
var stats: Dictionary = {}
var last_action: Dictionary = {}
var last_dash_distance: float = 0.0
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
var _dash_speed: float = DASH_SPEED
var _dash_total: float = DASH_DURATION
var _dash_origin: Vector3 = Vector3.INF
var _dash_plume: Node3D
var _phase_left: float = 0.0
var _phase_total: float = 0.0
var _phase: String = "idle"
var _visual_phase: String = "idle"
var _visual_phase_left: float = 0.0
var _visual_phase_total: float = 0.0
var _landing_left: float = 0.0
var _pending_weapon: String = ""
var _accepted_enemy_hits: int = 0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 0.18
	var collision := get_node_or_null("BodyCollision") as CollisionShape3D
	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = "BodyCollision"
		add_child(collision)
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.45
	collision.shape = shape
	collision.position.y = 0.73
	_sprite = get_node_or_null("ActorSprite") as LabSprite
	if _sprite == null:
		_sprite = SpriteScript.new()
		_sprite.name = "ActorSprite"
		add_child(_sprite)
	_sprite.setup("player")
	_sprite.face(facing)
	_refresh_equipment()
	# A floor marker anchors the billboard sprite to its collision position.
	if get_node_or_null("ContactShadow") != null:
		return
	var shadow := MeshInstance3D.new()
	shadow.name = "ContactShadow"
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
	var snapshot: Dictionary = equipment.resolved_stats()
	_dash_speed = snapshot.dash_speed
	_dash_total = snapshot.dash_duration
	_dash_origin = global_position
	_dash_direction = direction
	facing = direction
	_sprite.face(facing)
	_dash_left = _dash_total
	_dash_cooldown = snapshot.dash_cooldown
	_invulnerable = maxf(_invulnerable, snapshot.dash_invulnerability)
	_queued_dash = Vector3.ZERO
	_visual_phase_left = 0.0
	_dash_plume = null
	_sprite.set_action("dash")
	if fx:
		_dash_plume = fx.dash_trail(global_position + Vector3.UP * 0.08, direction, DUST)
		if is_instance_valid(_dash_plume):
			_dash_plume.track_emitter(self, _dash_total, true)
	fired.emit("dash")

func _physics_process(delta: float) -> void:
	if dead:
		return
	_dash_cooldown = maxf(_dash_cooldown - delta, 0.0)
	_slash_cd = maxf(_slash_cd - delta, 0.0)
	_blast_cd = maxf(_blast_cd - delta, 0.0)
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	_phase_left = maxf(_phase_left - delta, 0.0)
	_visual_phase_left = maxf(_visual_phase_left - delta, 0.0)
	_landing_left = maxf(_landing_left - delta, 0.0)
	if _dash_cooldown <= 0.0 and _queued_dash.length_squared() > 0.0:
		_start_dash(_queued_dash)
	if _dash_left > 0.0:
		# Scale the last tick so each swipe travels the same distance.
		var fraction: float = minf(_dash_left / delta, 1.0)
		velocity.x = _dash_direction.x * _dash_speed * fraction
		velocity.z = _dash_direction.z * _dash_speed * fraction
		_dash_left = maxf(_dash_left - delta, 0.0)
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
	if _dash_origin != Vector3.INF and is_instance_valid(_dash_plume):
		_dash_plume.sample_emitter()
	if _dash_left == 0.0 and _dash_origin != Vector3.INF:
		if is_instance_valid(_dash_plume):
			_dash_plume.finish_tracking()
		_dash_plume = null
		last_dash_distance = Vector2(global_position.x - _dash_origin.x, global_position.z - _dash_origin.z).length()
		_dash_origin = Vector3.INF
		_landing_left = LANDING_VISUAL_DURATION
	if _dash_left > 0.0:
		_sprite.set_action("dash", 1.0 - _dash_left / _dash_total)
	elif _visual_phase_left > 0.0:
		_sprite.set_action(_visual_phase, 1.0 - _visual_phase_left / _visual_phase_total)
	elif _landing_left > 0.0:
		_sprite.set_action("landing", 1.0 - _landing_left / LANDING_VISUAL_DURATION)
	else:
		_sprite.set_action("idle")
	_sprite.animate(_dash_left > 0.0, delta)
	if _pending_weapon != "" and not action_in_progress():
		var pending := _pending_weapon
		_pending_weapon = ""
		_equip_now(pending)
	_sprite.modulate = RED if _invulnerable > 0.12 and int(_invulnerable * 25.0) % 2 == 0 else Color.WHITE
	if shells < max_shells:
		_reload += delta
		if _reload >= stats.shell_reload:
			shells += 1
			_reload = 0.0
	else:
		_reload = 0.0

func slash(direction: Vector3 = Vector3.ZERO) -> int:
	if _slash_cd > 0.0 or dead:
		return 0
	_face_attack(direction)
	var snapshot: Dictionary = equipment.resolved_stats()
	_slash_cd = snapshot.primary_cooldown
	_begin_phase("primary", snapshot.primary_cooldown * (0.13 / 0.30), snapshot.primary_cooldown * (0.28 / 0.30))
	if fx:
		fx.slash(global_position + Vector3.UP * 0.65, facing, IVORY)
		fx.attack_footprint(global_position, facing, snapshot.primary_range, snapshot.primary_cone_min_dot, IVORY, _phase_total)
		fx.sound("slash")
	var hits: int = _hit_targets(snapshot.primary_range, snapshot.primary_cone_min_dot, snapshot.primary_damage, facing * 3.5 + Vector3.UP * 2.0)
	if _accepted_enemy_hits > 0 and shells < max_shells:
		_reload += stats.primary_hit_reload_credit
		if _reload >= stats.shell_reload:
			shells += 1
			_reload = 0.0
	_record_action("slash", hits, snapshot.primary_damage, snapshot.primary_range)
	fired.emit("slash")
	return hits

func blast(direction: Vector3 = Vector3.ZERO) -> int:
	if _blast_cd > 0.0 or dead or shells <= 0:
		return 0
	_face_attack(direction)
	shells -= 1
	_reload = 0.0
	var snapshot: Dictionary = equipment.resolved_stats()
	_blast_cd = snapshot.followup_cooldown
	_begin_phase("blast", snapshot.followup_cooldown * (0.10 / 0.45), snapshot.followup_cooldown * (0.24 / 0.45))
	if fx:
		var muzzle_position: Vector3 = _sprite.get_muzzle_world_position(get_viewport().get_camera_3d())
		fx.muzzle(muzzle_position, facing, _sprite)
		fx.attack_footprint(global_position, facing, snapshot.followup_range, snapshot.followup_cone_min_dot, Color(0.76, 0.80, 0.83), _phase_total)
		fx.sound("blast")
	var hits: int = _hit_targets(snapshot.followup_range, snapshot.followup_cone_min_dot, snapshot.followup_damage, facing * 10.0 + Vector3.UP * 4.0)
	_record_action("blast", hits, snapshot.followup_damage, snapshot.followup_range)
	fired.emit("blast")
	return hits

func take_damage(amount: float, impulse: Vector3) -> void:
	if _invulnerable > 0.0 or dead:
		return
	hp = maxf(hp - equipment.damage_received(amount), 0.0)
	velocity += impulse
	_knockback_left = 0.16
	_invulnerable = stats.hurt_invulnerability
	_begin_phase("hurt", 0.16, 0.28)
	if fx:
		fx.tiny_bleed(global_position + Vector3.UP * 0.75, 5 if hp <= 0.0 else 3, impulse * 0.04)
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
	_accepted_enemy_hits = 0
	var targets: Array[Node] = get_tree().get_nodes_in_group("enemies")
	targets.append_array(get_tree().get_nodes_in_group("practice_targets"))
	for target in targets:
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
		var result: Dictionary = target.take_damage(damage, impulse)
		if result.get("accepted", false) and float(result.get("hp_damage", 0.0)) > 0.0:
			hits += 1
			if target.is_in_group("enemies"):
				_accepted_enemy_hits += 1
	return hits

func action_in_progress() -> bool:
	return _dash_left > 0.0 or _phase_left > 0.0

func equip_item(item_id: String) -> bool:
	var item: Dictionary = equipment.item(item_id)
	if item.is_empty() or not equipment.owns(item_id) or dead:
		return false
	if item.slot == "weapon":
		if action_in_progress():
			_pending_weapon = item_id
			return true
	else:
		# Clothing changes are only legal in the paused safe-boundary bench.
		if not get_tree().paused or not get_tree().get_nodes_in_group("enemies").is_empty():
			return false
	return _equip_now(item_id)

func _equip_now(item_id: String) -> bool:
	if not equipment.equip(item_id):
		return false
	_refresh_equipment()
	equipment_changed.emit(item_id)
	return true

func _refresh_equipment() -> void:
	stats = equipment.resolved_stats()
	max_hp = stats.max_health
	hp = minf(hp, max_hp)
	slash_damage = stats.primary_damage
	blast_damage = stats.followup_damage
	_sprite.set_loadout_visual(equipment.equipped.weapon, equipment.equipped.jacket, equipment.equipped.pants, equipment.equipped.shoes)

func _begin_phase(kind: String, duration: float, visual_duration: float = -1.0) -> void:
	_phase = kind
	# Gameplay deadlines retain their existing clock. The longer cosmetic settle
	# is interruptible by the next accepted action and never gates input or swaps.
	_phase_total = duration
	_phase_left = duration
	_visual_phase = kind
	_visual_phase_total = duration if visual_duration < 0.0 else visual_duration
	_visual_phase_left = _visual_phase_total
	_sprite.set_action(kind)

func _record_action(kind: String, hits: int, damage: float, reach: float) -> void:
	last_action = {"kind": kind, "hits": hits, "damage": damage, "reach": reach}
	action_resolved.emit(kind, hits, damage)
