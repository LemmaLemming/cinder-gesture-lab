class_name CinderPlayer
extends CharacterBody3D

signal fired(kind: String)
signal died
signal action_resolved(kind: String, hits: int, damage: float)
signal equipment_changed(item_id: String)
## Published after an attack executes or an accepted voluntary dash completes.
## The payload and accessor results are copies, never the retained records.
signal world_action_executed(record: Dictionary)

const SpriteScript = preload("res://scripts/pixel_sprite.gd")
const EquipmentScript = preload("res://scripts/equipment.gd")
const SnapshotCodec = preload("res://scripts/campaign/snapshot_codec.gd")
const SNAPSHOT_API_REVISION: String = "player-snapshot-1"
const SNAPSHOT_SCHEMA_VERSION: int = 1
const DASH_SPEED: float = 15.0
const DASH_DURATION: float = 0.18
const DASH_COOLDOWN: float = 0.34
const GRAVITY: float = 24.0
const IVORY: Color = Color(0.94, 0.86, 0.82)
const RED: Color = Color(0.94, 0.045, 0.09)
const DUST: Color = Color(0.66, 0.70, 0.74)
const LANDING_VISUAL_DURATION: float = 0.22
const WORLD_ACTION_SCHEMA_VERSION: int = 1
const MAX_WORLD_ACTION_RECORDS: int = 64
const ATTACK_ORIGIN_DISK_RADIUS: float = 0.1
const ATTACK_MAX_VERTICAL_DISTANCE: float = 1.4
const ATTACK_LOS_HEIGHT: float = 0.7
const ATTACK_SCENERY_MASK: int = 1

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
var _world_action_clock: float = 0.0
var _world_action_sequence: int = 0
var _world_action_records: Array[Dictionary] = []
var _world_dash_record: Dictionary = {}
var last_snapshot_error: String = ""
var _snapshot_busy: bool = false
var _actor_transaction_depth: int = 0
# CharacterBody3D's cached contacts are not writable. Preserve the first
# restored gravity decision without advancing a hidden simulation tick.
var _restored_floor_contact: int = -1
var _presentation_id: String = "helmeted_lab"
var presentation_id: String:
	get:
		return _sprite.presentation_id if is_instance_valid(_sprite) else _presentation_id

## Cosmetic act selection; no equipment slot, stat, timing or collision change.
func set_presentation(id: String) -> bool:
	if not SpriteScript.PRESENTATION_IDS.has(id) or _actor_transaction_depth > 0 or _snapshot_busy:
		return false
	_presentation_id = id
	return _sprite.set_presentation(id) if is_instance_valid(_sprite) else true

## Simulation seconds since this player instance entered active physics.
## Pausing the shared scene tree stops this clock and dash sampling together.
func get_world_action_clock() -> float:
	return _world_action_clock

## Ordered by publication sequence, retaining only the newest bounded history.
## A caller needing every event must consume the signal before history rolls off.
func get_world_action_records(after_sequence: int = 0) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for record: Dictionary in _world_action_records:
		if int(record.sequence) > after_sequence:
			records.append(record.duplicate(true))
	return records

## Discard capture of an unfinished dash without changing its movement/timing.
## Transitions/cancellation must not turn a partial path into a completed dash.
func cancel_world_action_capture() -> void:
	_world_dash_record.clear()


## Canonical JSON transport for direct executed records. This pure interface
## shares the actor snapshot validator; it creates no actor or action.
static func world_action_record_error(record: Dictionary, clock_s: float) -> String:
	var error: String = SnapshotCodec.value_error(record)
	if not error.is_empty():
		return error
	if not SnapshotCodec.in_range(clock_s, 0.0, 1000000000000.0):
		return "Finite world-action clock required"
	return _world_record_error(record, clock_s, false)


static func encode_world_action_record(record: Dictionary, clock_s: float) -> Dictionary:
	for key: String in ["world_origin", "direction"]:
		if not record.get(key) is Vector3 or not (record[key] as Vector3).is_finite():
			return {}
	if record.get("kind") == "dash":
		if not record.get("landing") is Vector3 or not (record["landing"] as Vector3).is_finite() or not record.get("path") is Array:
			return {}
		for sample: Variant in record["path"]:
			if not sample is Dictionary or not sample.get("position") is Vector3 or not (sample["position"] as Vector3).is_finite():
				return {}
	var encoded: Dictionary = _encode_world_record(record)
	return encoded if world_action_record_error(encoded, clock_s).is_empty() else {}


static func decode_world_action_record(record: Dictionary, clock_s: float) -> Dictionary:
	return _decode_world_record(record) if world_action_record_error(record, clock_s).is_empty() else {}

## Live authoritative response data. The level adds its actual floor regions,
## world revision, recognition budget and finite authored swipe candidates.
## No blast ammo or invulnerability is credited by the scheduler. A moving,
## falling or buffered actor is explicitly unsupported by the current witness.
func get_threat_response_state() -> Dictionary:
	var resolved: Dictionary = equipment.resolved_stats()
	return {
		"actor": self, "stats": resolved.duplicate(true),
		"stable": not dead and _snapshot_grounded() and velocity.is_zero_approx() and _dash_left <= 0.0 and _knockback_left <= 0.0 and _queued_dash.is_zero_approx(),
		"dash_cooldown_left_s": _dash_cooldown,
		"primary_cooldown_left_s": _slash_cd,
		"commitment_remaining_s": maxf(_phase_left, maxf(_dash_left, _knockback_left)),
		"primary_commitment_s": float(resolved.primary_cooldown) * (0.13 / 0.30),
		"motion": {"position": global_position, "velocity": velocity, "grounded": _snapshot_grounded(), "dash_left_s": _dash_left, "queued_dash": _queued_dash, "knockback_left_s": _knockback_left},
		"equipment_ids": equipment.snapshot(), "action_clock_s": _world_action_clock,
	}

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
	_sprite.set_presentation(_presentation_id)
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
	_actor_transaction_depth += 1
	var snapshot: Dictionary = equipment.resolved_stats()
	_world_dash_record = {
		"kind": "dash", "started_at_s": _world_action_clock,
		"origin": "player_direct", "world_origin": global_position, "direction": direction,
		"blocked": false,
		"equipment_ids": equipment.snapshot(), "resolved_stats": snapshot.duplicate(true),
		"path": [{"position": global_position, "time_s": _world_action_clock}]
	}
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
	_actor_transaction_depth -= 1

func _physics_process(delta: float) -> void:
	if dead:
		cancel_world_action_capture()
		return
	_actor_transaction_depth += 1
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
	if not _snapshot_grounded():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	move_and_slide()
	_restored_floor_contact = -1
	_world_action_clock += delta
	if not _world_dash_record.is_empty():
		(_world_dash_record.path as Array).append({"position": global_position, "time_s": _world_action_clock})
		for index: int in range(get_slide_collision_count()):
			var normal: Vector3 = get_slide_collision(index).get_normal()
			if Vector2(normal.x, normal.z).length_squared() > 0.001:
				_world_dash_record["blocked"] = true
	if _dash_origin != Vector3.INF and is_instance_valid(_dash_plume):
		_dash_plume.sample_emitter()
	if _dash_left == 0.0 and _dash_origin != Vector3.INF:
		if is_instance_valid(_dash_plume):
			_dash_plume.finish_tracking()
		_dash_plume = null
		last_dash_distance = Vector2(global_position.x - _dash_origin.x, global_position.z - _dash_origin.z).length()
		_complete_world_dash()
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
	_actor_transaction_depth -= 1

func slash(direction: Vector3 = Vector3.ZERO) -> int:
	if _slash_cd > 0.0 or dead:
		return 0
	_actor_transaction_depth += 1
	_face_attack(direction)
	var snapshot: Dictionary = equipment.resolved_stats()
	var world_record: Dictionary = _world_attack_record("primary", snapshot)
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
	world_record["hits"] = hits
	_publish_world_action(world_record)
	_record_action("slash", hits, snapshot.primary_damage, snapshot.primary_range)
	fired.emit("slash")
	_actor_transaction_depth -= 1
	return hits

func blast(direction: Vector3 = Vector3.ZERO) -> int:
	if _blast_cd > 0.0 or dead or shells <= 0:
		return 0
	_actor_transaction_depth += 1
	_face_attack(direction)
	shells -= 1
	_reload = 0.0
	var snapshot: Dictionary = equipment.resolved_stats()
	var world_record: Dictionary = _world_attack_record("blast", snapshot)
	_blast_cd = snapshot.followup_cooldown
	_begin_phase("blast", snapshot.followup_cooldown * (0.10 / 0.45), snapshot.followup_cooldown * (0.24 / 0.45))
	if fx:
		var muzzle_position: Vector3 = _sprite.get_muzzle_world_position(get_viewport().get_camera_3d())
		fx.muzzle(muzzle_position, facing, _sprite)
		fx.attack_footprint(global_position, facing, snapshot.followup_range, snapshot.followup_cone_min_dot, Color(0.76, 0.80, 0.83), _phase_total)
		fx.sound("blast")
	var hits: int = _hit_targets(snapshot.followup_range, snapshot.followup_cone_min_dot, snapshot.followup_damage, facing * 10.0 + Vector3.UP * 4.0)
	world_record["hits"] = hits
	_publish_world_action(world_record)
	_record_action("blast", hits, snapshot.followup_damage, snapshot.followup_range)
	fired.emit("blast")
	_actor_transaction_depth -= 1
	return hits

func take_damage(amount: float, impulse: Vector3) -> void:
	if _invulnerable > 0.0 or dead:
		return
	_actor_transaction_depth += 1
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
		cancel_world_action_capture()
		died.emit()
	_actor_transaction_depth -= 1

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
		if target.hp <= 0.0 or offset.length() > reach or vertical > ATTACK_MAX_VERTICAL_DISTANCE:
			continue
		if offset.length() > ATTACK_ORIGIN_DISK_RADIUS and offset.normalized().dot(facing) < cone:
			continue
		var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * ATTACK_LOS_HEIGHT, target.global_position + Vector3.UP * ATTACK_LOS_HEIGHT, ATTACK_SCENERY_MASK)
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
	_actor_transaction_depth += 1
	_refresh_equipment()
	equipment_changed.emit(item_id)
	_actor_transaction_depth -= 1
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

func _world_attack_record(kind: String, snapshot: Dictionary) -> Dictionary:
	var primary: bool = kind == "primary"
	var cooldown: float = snapshot.primary_cooldown if primary else snapshot.followup_cooldown
	return {
		"kind": kind, "started_at_s": _world_action_clock,
		"completed_at_s": _world_action_clock,
		"damage_timing": "instant_at_execution",
		"commitment_duration_s": cooldown * (0.13 / 0.30 if primary else 0.10 / 0.45),
		"cooldown_s": cooldown, "origin": "player_direct", "world_origin": global_position, "direction": facing,
		"damage": snapshot.primary_damage if primary else snapshot.followup_damage,
		"geometry": {
			"shape": "radial_cone",
			"reach": snapshot.primary_range if primary else snapshot.followup_range,
			"cone_min_dot": snapshot.primary_cone_min_dot if primary else snapshot.followup_cone_min_dot,
			"origin_disk_radius": ATTACK_ORIGIN_DISK_RADIUS,
			"max_vertical_distance": ATTACK_MAX_VERTICAL_DISTANCE,
			"los": {"policy": "scenery_ray_from_source_to_target", "collision_mask": ATTACK_SCENERY_MASK, "height": ATTACK_LOS_HEIGHT}
		},
		"equipment_ids": equipment.snapshot(), "resolved_stats": snapshot.duplicate(true)
	}

func _complete_world_dash() -> void:
	if _world_dash_record.is_empty():
		return
	var record: Dictionary = _world_dash_record
	_world_dash_record = {}
	record["landing"] = global_position
	record["completed_at_s"] = _world_action_clock
	record["distance"] = last_dash_distance
	record["collision_shortened"] = last_dash_distance + 0.001 < float(record.resolved_stats.dash_distance)
	record["movement_damage"] = false
	_publish_world_action(record)

func _publish_world_action(record: Dictionary) -> void:
	_world_action_sequence += 1
	record["schema_version"] = WORLD_ACTION_SCHEMA_VERSION
	record["sequence"] = _world_action_sequence
	_world_action_records.append(record.duplicate(true))
	if _world_action_records.size() > MAX_WORLD_ACTION_RECORDS:
		_world_action_records.pop_front()
	world_action_executed.emit(record.duplicate(true))


## Capture at the shell's paused, deferred barrier after originating callbacks.
## This envelope owns no level/attempt identity or screen-space aim anchor.
func snapshot_state() -> Dictionary:
	last_snapshot_error = _snapshot_boundary_error()
	if not last_snapshot_error.is_empty():
		return {}
	_snapshot_busy = true
	var history: Array = []
	for record: Dictionary in _world_action_records:
		history.append(_encode_world_record(record))
	var snapshot: Dictionary = {
		"api_revision": SNAPSHOT_API_REVISION,
		"schema_version": SNAPSHOT_SCHEMA_VERSION,
		"actor_type": "CinderPlayer",
		"equipment": equipment.snapshot(),
		"resources": {"hp": hp, "max_hp": max_hp, "shells": shells, "max_shells": max_shells, "dead": dead},
		"motion": {
			"position": SnapshotCodec.vector3(global_position),
			"basis": [SnapshotCodec.vector3(global_basis.x), SnapshotCodec.vector3(global_basis.y), SnapshotCodec.vector3(global_basis.z)],
			"velocity": SnapshotCodec.vector3(velocity), "facing": SnapshotCodec.vector3(facing),
			"grounded": _snapshot_grounded(),
			"dash_direction": SnapshotCodec.vector3(_dash_direction), "queued_dash": SnapshotCodec.vector3(_queued_dash),
			"dash_origin": null if _dash_origin == Vector3.INF else SnapshotCodec.vector3(_dash_origin),
			"dash_speed": _dash_speed, "dash_total_s": _dash_total,
		},
		"clocks": {
			"dash_left_s": _dash_left, "dash_cooldown_s": _dash_cooldown,
			"primary_cooldown_s": _slash_cd, "blast_cooldown_s": _blast_cd,
			"reload_s": _reload, "invulnerability_s": _invulnerable, "knockback_left_s": _knockback_left,
		},
		"phases": {
			"logical": _phase, "logical_left_s": _phase_left, "logical_total_s": _phase_total,
			"visual": _visual_phase, "visual_left_s": _visual_phase_left, "visual_total_s": _visual_phase_total,
			"landing_left_s": _landing_left,
		},
		"pending_weapon": _pending_weapon,
		"last_action": last_action.duplicate(true), "last_dash_distance": last_dash_distance,
		"world_actions": {
			"schema_version": WORLD_ACTION_SCHEMA_VERSION, "clock_s": _world_action_clock,
			"sequence": _world_action_sequence, "history": history,
			"pending_dash": _encode_world_record(_world_dash_record),
		},
		"presentation": {
			"id": presentation_id,
			"action": _sprite.get("_action"), "frame": _sprite.get("_action_frame"),
			"idle_time_s": _sprite.get("_animation_time"),
		},
	}
	last_snapshot_error = _validate_snapshot(snapshot)
	_snapshot_busy = false
	return snapshot.duplicate(true) if last_snapshot_error.is_empty() else {}


## Pure validation; the receiving actor must already be ready and paused.
func snapshot_error(snapshot: Dictionary) -> String:
	var error: String = _snapshot_boundary_error()
	if not error.is_empty():
		return error
	_snapshot_busy = true
	error = _validate_snapshot(snapshot)
	_snapshot_busy = false
	return error


## Apply only fully validated data. No damage/action/equipment/death signals,
## resource reset, hidden physics tick, or new accepted-action publication.
func restore_state(snapshot: Dictionary) -> bool:
	last_snapshot_error = _snapshot_boundary_error()
	if not last_snapshot_error.is_empty():
		return false
	_snapshot_busy = true
	last_snapshot_error = _validate_snapshot(snapshot)
	if not last_snapshot_error.is_empty():
		_snapshot_busy = false
		return false
	var accepted: Dictionary = snapshot.duplicate(true)
	var resources: Dictionary = accepted.resources
	var motion: Dictionary = accepted.motion
	var clocks: Dictionary = accepted.clocks
	var phases: Dictionary = accepted.phases
	var capture: Dictionary = accepted.world_actions
	# Re-resolve once from canonical IDs; never apply multipliers to old stats.
	equipment.restore(accepted.equipment)
	_refresh_equipment()
	hp = float(resources.hp)
	max_shells = int(resources.max_shells)
	shells = int(resources.shells)
	dead = resources.dead
	var basis_columns: Array = motion.basis
	global_transform = Transform3D(Basis(SnapshotCodec.read_vector3(basis_columns[0]), SnapshotCodec.read_vector3(basis_columns[1]), SnapshotCodec.read_vector3(basis_columns[2])), SnapshotCodec.read_vector3(motion.position))
	if motion.grounded:
		# Refresh a recreated body's static-floor contact without running physics
		# or adopting snap's positional correction as extra recorded movement.
		var exact_transform: Transform3D = global_transform
		apply_floor_snap()
		global_transform = exact_transform
	velocity = SnapshotCodec.read_vector3(motion.velocity)
	facing = SnapshotCodec.read_vector3(motion.facing)
	_restored_floor_contact = 1 if motion.grounded else 0
	_dash_direction = SnapshotCodec.read_vector3(motion.dash_direction)
	_queued_dash = SnapshotCodec.read_vector3(motion.queued_dash)
	_dash_origin = Vector3.INF if motion.dash_origin == null else SnapshotCodec.read_vector3(motion.dash_origin)
	_dash_speed = float(motion.dash_speed)
	_dash_total = float(motion.dash_total_s)
	_dash_left = float(clocks.dash_left_s)
	_dash_cooldown = float(clocks.dash_cooldown_s)
	_slash_cd = float(clocks.primary_cooldown_s)
	_blast_cd = float(clocks.blast_cooldown_s)
	_reload = float(clocks.reload_s)
	_invulnerable = float(clocks.invulnerability_s)
	_knockback_left = float(clocks.knockback_left_s)
	_phase = phases.logical
	_phase_left = float(phases.logical_left_s)
	_phase_total = float(phases.logical_total_s)
	_visual_phase = phases.visual
	_visual_phase_left = float(phases.visual_left_s)
	_visual_phase_total = float(phases.visual_total_s)
	_landing_left = float(phases.landing_left_s)
	_pending_weapon = accepted.pending_weapon
	last_action = (accepted.last_action as Dictionary).duplicate(true)
	if not last_action.is_empty():
		last_action["hits"] = int(last_action.hits)
	last_dash_distance = float(accepted.last_dash_distance)
	_accepted_enemy_hits = 0
	_world_action_clock = float(capture.clock_s)
	_world_action_sequence = int(capture.sequence)
	_world_action_records.clear()
	for record: Dictionary in capture.history:
		_world_action_records.append(_decode_world_record(record))
	_world_dash_record = _decode_world_record(capture.pending_dash)
	# Retire the old presentation and reconstruct the connected plume from the
	# actual restored dash origin, elapsed age and live emitter. No motion tick
	# or action publication is needed to rebuild this required feedback.
	if is_instance_valid(_dash_plume):
		if is_instance_valid(fx) and fx.has_method("retire_effect"):
			fx.retire_effect(_dash_plume)
		else:
			_dash_plume.hide()
			_dash_plume.queue_free()
	_dash_plume = null
	if not dead and _dash_left > 0.0 and is_instance_valid(fx) and fx.has_method("restore_dash_trail"):
		_dash_plume = fx.restore_dash_trail(self, _dash_origin, _dash_direction, _dash_total, _dash_left)
	_sprite.face(facing)
	var presentation: Dictionary = accepted.presentation
	_presentation_id = presentation.get("id", "helmeted_lab")
	_sprite.set_presentation(_presentation_id)
	var frame_count: int = SpriteScript.PLAYER_FRAME_COUNTS[presentation.action]
	_sprite.set_action(presentation.action, (float(presentation.frame) + 0.25) / frame_count)
	_sprite.set("_animation_time", float(presentation.idle_time_s))
	if presentation.action == "idle":
		_sprite.animate(false, 0.0)
	_sprite.modulate = RED if _invulnerable > 0.12 and int(_invulnerable * 25.0) % 2 == 0 else Color.WHITE
	_snapshot_busy = false
	last_snapshot_error = ""
	return true


func _snapshot_boundary_error() -> String:
	if not is_inside_tree() or not is_node_ready() or not is_instance_valid(_sprite):
		return "Player snapshots require a ready actor in the shared scene tree"
	if not get_tree().paused:
		return "Player snapshots require the paused deferred shell boundary"
	if _snapshot_busy or _actor_transaction_depth > 0:
		return "Player snapshots cannot run inside actor transactions or callbacks"
	if not get_platform_velocity().is_zero_approx() or not get_platform_angular_velocity().is_zero_approx():
		return "Player snapshot revision 1 requires static floor; moving-platform contact state is unsupported"
	return ""


func _snapshot_grounded() -> bool:
	return _restored_floor_contact == 1 if _restored_floor_contact >= 0 else is_on_floor()


func _validate_snapshot(snapshot: Dictionary) -> String:
	var error: String = SnapshotCodec.value_error(snapshot)
	if not error.is_empty():
		return error
	error = SnapshotCodec.keys_error(snapshot, ["api_revision", "schema_version", "actor_type", "equipment", "resources", "motion", "clocks", "phases", "pending_weapon", "last_action", "last_dash_distance", "world_actions", "presentation"])
	if not error.is_empty():
		return error
	if snapshot.api_revision != SNAPSHOT_API_REVISION or not SnapshotCodec.is_integer(snapshot.schema_version, SNAPSHOT_SCHEMA_VERSION, SNAPSHOT_SCHEMA_VERSION) or snapshot.actor_type != "CinderPlayer":
		return "Unsupported player snapshot identity/API/schema"
	for key: String in ["equipment", "resources", "motion", "clocks", "phases", "last_action", "world_actions", "presentation"]:
		if not snapshot[key] is Dictionary:
			return "Player snapshot requires a dictionary: " + key
	error = _loadout_error(snapshot.equipment)
	if not error.is_empty():
		return error
	var restored_gear = EquipmentScript.new()
	restored_gear.restore(snapshot.equipment)
	var resolved: Dictionary = restored_gear.resolved_stats()
	var resources: Dictionary = snapshot.resources
	error = SnapshotCodec.keys_error(resources, ["hp", "max_hp", "shells", "max_shells", "dead"])
	if not error.is_empty():
		return error
	if not SnapshotCodec.is_number(resources.max_hp) or not is_equal_approx(float(resources.max_hp), float(resolved.max_health)) or not SnapshotCodec.in_range(resources.hp, 0.0, float(resolved.max_health)):
		return "Player HP must fit the canonical equipped maximum"
	if not SnapshotCodec.is_integer(resources.max_shells, int(resolved.shell_capacity), int(resolved.shell_capacity)) or not SnapshotCodec.is_integer(resources.shells, 0, int(resolved.shell_capacity)):
		return "Player shells must fit the canonical capacity"
	if not resources.dead is bool or resources.dead != (float(resources.hp) == 0.0):
		return "Dead state must match zero HP"
	var motion: Dictionary = snapshot.motion
	error = SnapshotCodec.keys_error(motion, ["position", "basis", "velocity", "facing", "grounded", "dash_direction", "queued_dash", "dash_origin", "dash_speed", "dash_total_s"])
	if not error.is_empty():
		return error
	for key: String in ["position", "velocity"]:
		if not SnapshotCodec.is_vector3(motion[key]):
			return "Invalid motion vector: " + key
	if not motion.basis is Array or motion.basis.size() != 3:
		return "Player basis must contain three vectors"
	for column: Variant in motion.basis:
		if not SnapshotCodec.is_vector3(column):
			return "Invalid player basis vector"
	var basis_columns: Array = motion.basis
	var restored_basis := Basis(SnapshotCodec.read_vector3(basis_columns[0]), SnapshotCodec.read_vector3(basis_columns[1]), SnapshotCodec.read_vector3(basis_columns[2]))
	if not is_finite(restored_basis.determinant()) or absf(restored_basis.determinant()) < 0.000001:
		return "Player basis must be finite and invertible"
	if not motion.grounded is bool or not _direction_valid(motion.facing, false) or not _direction_valid(motion.dash_direction, true) or not _direction_valid(motion.queued_dash, true):
		return "Player facing/dash directions must be planar unit vectors"
	if not SnapshotCodec.in_range(motion.dash_speed, 0.001, 1000.0) or not SnapshotCodec.in_range(motion.dash_total_s, 0.001, 10.0):
		return "Invalid snapshotted dash speed/duration"
	if motion.dash_origin != null and not SnapshotCodec.is_vector3(motion.dash_origin):
		return "Dash origin must be a finite vector or null"
	var clocks: Dictionary = snapshot.clocks
	error = SnapshotCodec.keys_error(clocks, ["dash_left_s", "dash_cooldown_s", "primary_cooldown_s", "blast_cooldown_s", "reload_s", "invulnerability_s", "knockback_left_s"])
	if not error.is_empty():
		return error
	for key: String in ["dash_left_s", "dash_cooldown_s", "primary_cooldown_s", "blast_cooldown_s", "invulnerability_s"]:
		if not SnapshotCodec.in_range(clocks[key], 0.0, 10.0):
			return "Invalid remaining player clock: " + key
	# The existing knockback subtraction can finish slightly below zero.
	if not SnapshotCodec.in_range(clocks.knockback_left_s, -1.0, 0.160001) or not SnapshotCodec.in_range(clocks.reload_s, 0.0, float(resolved.shell_reload)):
		return "Invalid knockback/reload clock"
	if float(clocks.dash_left_s) > float(motion.dash_total_s) or (float(clocks.dash_left_s) > 0.0) != (motion.dash_origin != null):
		return "Active dash requires its original origin and bounded remaining time"
	if float(clocks.dash_left_s) > 0.0 and not _direction_valid(motion.dash_direction, false):
		return "Active dash requires an exact direction"
	if int(resources.shells) == int(resources.max_shells) and float(clocks.reload_s) != 0.0:
		return "Full shells cannot retain a partial reload"
	var phases: Dictionary = snapshot.phases
	error = SnapshotCodec.keys_error(phases, ["logical", "logical_left_s", "logical_total_s", "visual", "visual_left_s", "visual_total_s", "landing_left_s"])
	if not error.is_empty():
		return error
	for prefix: String in ["logical", "visual"]:
		if not phases[prefix] is String or not ["idle", "primary", "blast", "hurt"].has(phases[prefix]) or not SnapshotCodec.in_range(phases[prefix + "_total_s"], 0.0, 10.0) or not SnapshotCodec.in_range(phases[prefix + "_left_s"], 0.0, float(phases[prefix + "_total_s"])):
			return "Invalid player action phase: " + prefix
		if phases[prefix] == "idle" and (float(phases[prefix + "_left_s"]) != 0.0 or float(phases[prefix + "_total_s"]) != 0.0):
			return "Idle phase cannot contain an action deadline"
	if not SnapshotCodec.in_range(phases.landing_left_s, 0.0, LANDING_VISUAL_DURATION):
		return "Invalid landing presentation clock"
	if not snapshot.pending_weapon is String:
		return "Pending weapon must be a canonical ID or empty string"
	if not snapshot.pending_weapon.is_empty():
		var pending: Dictionary = restored_gear.item(snapshot.pending_weapon)
		if pending.is_empty() or not restored_gear.owns(snapshot.pending_weapon) or pending.slot != "weapon":
			return "Unsupported pending weapon"
		if float(clocks.dash_left_s) <= 0.0 and float(phases.logical_left_s) <= 0.0:
			return "Pending weapon requires an unfinished accepted action"
	if not SnapshotCodec.in_range(snapshot.last_dash_distance, 0.0, 1000000.0):
		return "Invalid last dash distance"
	error = _last_action_error(snapshot.last_action)
	if not error.is_empty():
		return error
	error = _capture_error(snapshot.world_actions, motion, clocks, resources.dead)
	if not error.is_empty():
		return error
	var presentation: Dictionary = snapshot.presentation
	var fields: Array = ["action", "frame", "idle_time_s"]
	if presentation.has("id"):
		fields.append("id")
		if not presentation.id is String or not SpriteScript.PRESENTATION_IDS.has(presentation.id):
			return "Unknown player presentation identity"
	error = SnapshotCodec.keys_error(presentation, fields)
	if not error.is_empty():
		return error
	if not presentation.action is String or not SpriteScript.PLAYER_STATES.has(presentation.action):
		return "Invalid player presentation action"
	if not SnapshotCodec.is_integer(presentation.frame, 0, int(SpriteScript.PLAYER_FRAME_COUNTS[presentation.action]) - 1) or not SnapshotCodec.in_range(presentation.idle_time_s, 0.0, SpriteScript.IDLE_LOOP_S):
		return "Invalid player presentation frame/clock"
	if presentation.action == "idle" and int(presentation.frame) != int(float(presentation.idle_time_s) / SpriteScript.IDLE_LOOP_S * int(SpriteScript.PLAYER_FRAME_COUNTS.idle)):
		return "Idle frame must match its simulation clock"
	return ""


static func _loadout_error(loadout: Dictionary) -> String:
	var error: String = SnapshotCodec.keys_error(loadout, EquipmentScript.SLOTS)
	if not error.is_empty():
		return error
	for slot: String in EquipmentScript.SLOTS:
		if not loadout[slot] is String:
			return "Equipment ID must be a string: " + slot
	var candidate = EquipmentScript.new()
	return "" if candidate.restore(loadout) else "Snapshot has an unsupported equipment ID/slot"


func _last_action_error(action: Dictionary) -> String:
	if action.is_empty():
		return ""
	var error: String = SnapshotCodec.keys_error(action, ["kind", "hits", "damage", "reach"])
	if not error.is_empty():
		return error
	if not ["slash", "blast"].has(action.kind) or not SnapshotCodec.is_integer(action.hits) or not SnapshotCodec.in_range(action.damage, 0.0, 1000000.0) or not SnapshotCodec.in_range(action.reach, 0.001, 1000.0):
		return "Invalid legacy action summary"
	return ""


static func _direction_valid(value: Variant, allow_zero: bool) -> bool:
	if not SnapshotCodec.is_vector3(value):
		return false
	var direction: Vector3 = SnapshotCodec.read_vector3(value)
	return absf(direction.y) < 0.000001 and ((allow_zero and direction.is_zero_approx()) or is_equal_approx(direction.length_squared(), 1.0))


func _capture_error(capture: Dictionary, motion: Dictionary, clocks: Dictionary, is_dead: bool) -> String:
	var error: String = SnapshotCodec.keys_error(capture, ["schema_version", "clock_s", "sequence", "history", "pending_dash"])
	if not error.is_empty():
		return error
	if not SnapshotCodec.is_integer(capture.schema_version, WORLD_ACTION_SCHEMA_VERSION, WORLD_ACTION_SCHEMA_VERSION) or not SnapshotCodec.in_range(capture.clock_s, 0.0, 1000000000000.0) or not SnapshotCodec.is_integer(capture.sequence) or not capture.history is Array or not capture.pending_dash is Dictionary:
		return "Invalid world-action capture header"
	var history: Array = capture.history
	if history.size() != mini(int(capture.sequence), MAX_WORLD_ACTION_RECORDS):
		return "World-action history must retain its bounded latest sequence"
	var previous_time: float = 0.0
	for index: int in range(history.size()):
		if not history[index] is Dictionary:
			return "World-action history requires records"
		var record: Dictionary = history[index]
		error = _world_record_error(record, float(capture.clock_s), false)
		if not error.is_empty():
			return error
		if int(record.sequence) != int(capture.sequence) - history.size() + index + 1 or float(record.completed_at_s) < previous_time:
			return "World-action history order is invalid"
		previous_time = float(record.completed_at_s)
	var pending: Dictionary = capture.pending_dash
	if pending.is_empty():
		# An explicitly cancelled capture may still have a real active dash.
		return ""
	if is_dead or float(clocks.dash_left_s) <= 0.0:
		return "Pending dash capture requires a living active dash"
	error = _world_record_error(pending, float(capture.clock_s), true)
	if not error.is_empty():
		return error
	if not SnapshotCodec.same_values(pending.world_origin, motion.dash_origin) or not SnapshotCodec.same_values(pending.direction, motion.dash_direction) or not SnapshotCodec.same_values(pending.path[-1].position, motion.position) or not is_equal_approx(float(pending.path[-1].time_s), float(capture.clock_s)):
		return "Pending dash capture must match actual motion and clock"
	if not is_equal_approx(float(pending.resolved_stats.dash_speed), float(motion.dash_speed)) or not is_equal_approx(float(pending.resolved_stats.dash_duration), float(motion.dash_total_s)) or not is_equal_approx(float(capture.clock_s) - float(pending.started_at_s), float(motion.dash_total_s) - float(clocks.dash_left_s)):
		return "Pending dash capture must retain its accepted movement timing"
	return ""


static func _world_record_error(record: Dictionary, clock: float, pending: bool) -> String:
	var common: Array = ["kind", "started_at_s", "origin", "world_origin", "direction", "equipment_ids", "resolved_stats"]
	if not pending:
		common.append_array(["schema_version", "sequence", "completed_at_s"])
	var is_dash: bool = record.get("kind") == "dash"
	if is_dash:
		common.append_array(["blocked", "path"])
		if not pending:
			common.append_array(["landing", "distance", "collision_shortened", "movement_damage"])
	else:
		if pending or not ["primary", "blast"].has(record.get("kind")):
			return "Invalid world-action kind"
		common.append_array(["damage_timing", "commitment_duration_s", "cooldown_s", "damage", "geometry", "hits"])
	var error: String = SnapshotCodec.keys_error(record, common)
	if not error.is_empty():
		return error
	if record.origin != "player_direct" or not SnapshotCodec.in_range(record.started_at_s, 0.0, clock) or not SnapshotCodec.is_vector3(record.world_origin) or not _direction_valid(record.direction, false) or not record.equipment_ids is Dictionary or not record.resolved_stats is Dictionary:
		return "Invalid direct-player world-action source"
	if not pending and (not SnapshotCodec.is_integer(record.schema_version, WORLD_ACTION_SCHEMA_VERSION, WORLD_ACTION_SCHEMA_VERSION) or not SnapshotCodec.is_integer(record.sequence, 1) or not SnapshotCodec.in_range(record.completed_at_s, float(record.started_at_s), clock)):
		return "Invalid completed world-action identity/clock"
	error = _loadout_error(record.equipment_ids)
	if not error.is_empty():
		return error
	var original_gear = EquipmentScript.new()
	original_gear.restore(record.equipment_ids)
	var original_stats: Dictionary = original_gear.resolved_stats()
	if not SnapshotCodec.same_values(record.resolved_stats, original_stats):
		return "World-action resolved stats no longer match canonical equipment"
	if is_dash:
		if not record.blocked is bool:
			return "Dash collision contact must be boolean"
		var landing: Variant = null if pending else record.landing
		var end_time: float = clock if pending else float(record.completed_at_s)
		error = _path_error(record.path, record.world_origin, float(record.started_at_s), landing, end_time)
		if not error.is_empty():
			return error
		if not pending:
			if not SnapshotCodec.is_vector3(record.landing) or not SnapshotCodec.in_range(record.distance, 0.0, 1000000.0) or not record.collision_shortened is bool or not record.movement_damage is bool or record.movement_damage:
				return "Invalid completed dash landing"
			var offset: Vector3 = SnapshotCodec.read_vector3(record.landing) - SnapshotCodec.read_vector3(record.world_origin)
			if not is_equal_approx(float(record.distance), Vector2(offset.x, offset.z).length()) or record.collision_shortened != (float(record.distance) + 0.001 < float(original_stats.dash_distance)):
				return "Dash distance must match its real landing"
		return ""
	var primary: bool = record.kind == "primary"
	var expected_cooldown: float = original_stats.primary_cooldown if primary else original_stats.followup_cooldown
	var expected_geometry: Dictionary = {
		"shape": "radial_cone", "reach": original_stats.primary_range if primary else original_stats.followup_range,
		"cone_min_dot": original_stats.primary_cone_min_dot if primary else original_stats.followup_cone_min_dot,
		"origin_disk_radius": ATTACK_ORIGIN_DISK_RADIUS, "max_vertical_distance": ATTACK_MAX_VERTICAL_DISTANCE,
		"los": {"policy": "scenery_ray_from_source_to_target", "collision_mask": ATTACK_SCENERY_MASK, "height": ATTACK_LOS_HEIGHT},
	}
	var expected_damage: float = original_stats.primary_damage if primary else original_stats.followup_damage
	if record.damage_timing != "instant_at_execution" or not SnapshotCodec.is_number(record.completed_at_s) or record.completed_at_s != record.started_at_s or not SnapshotCodec.same_values(record.geometry, expected_geometry) or not SnapshotCodec.same_values(record.damage, expected_damage) or not SnapshotCodec.same_values(record.cooldown_s, expected_cooldown) or not SnapshotCodec.same_values(record.commitment_duration_s, expected_cooldown * (0.13 / 0.30 if primary else 0.10 / 0.45)) or not SnapshotCodec.is_integer(record.hits):
		return "Attack record must retain its executed canonical geometry/timing"
	return ""


static func _path_error(path: Variant, origin: Array, start: float, landing: Variant, end: float) -> String:
	if not path is Array or path.is_empty() or path.size() > 4096:
		return "Dash path must contain a bounded sampled route"
	var previous: float = start
	for index: int in range(path.size()):
		if not path[index] is Dictionary:
			return "Dash path requires sample dictionaries"
		var sample: Dictionary = path[index]
		var error: String = SnapshotCodec.keys_error(sample, ["position", "time_s"])
		if not error.is_empty():
			return error
		if not SnapshotCodec.is_vector3(sample.position) or not SnapshotCodec.in_range(sample.time_s, start, end) or (index > 0 and float(sample.time_s) <= previous):
			return "Dash samples require finite positions and increasing clocks"
		previous = float(sample.time_s)
	if not SnapshotCodec.same_values(path[0].position, origin) or not is_equal_approx(float(path[0].time_s), start) or not is_equal_approx(float(path[-1].time_s), end):
		return "Dash sample times/endpoints must match its execution"
	if landing != null and (path.size() < 2 or not SnapshotCodec.same_values(path[-1].position, landing)):
		return "Completed dash path must end at its real landing"
	return ""


static func _encode_world_record(record: Dictionary) -> Dictionary:
	if record.is_empty():
		return {}
	var encoded: Dictionary = record.duplicate(true)
	for key: String in ["world_origin", "direction", "landing"]:
		if encoded.has(key):
			encoded[key] = SnapshotCodec.vector3(encoded[key])
	if encoded.has("path"):
		for sample: Dictionary in encoded.path:
			sample["position"] = SnapshotCodec.vector3(sample.position)
	return encoded


static func _decode_world_record(record: Dictionary) -> Dictionary:
	if record.is_empty():
		return {}
	var decoded: Dictionary = record.duplicate(true)
	for key: String in ["world_origin", "direction", "landing"]:
		if decoded.has(key):
			decoded[key] = SnapshotCodec.read_vector3(decoded[key])
	if decoded.has("path"):
		for sample: Dictionary in decoded.path:
			sample["position"] = SnapshotCodec.read_vector3(sample.position)
	if decoded.has("sequence"):
		decoded["sequence"] = int(decoded.sequence)
		decoded["schema_version"] = int(decoded.schema_version)
	if decoded.has("hits"):
		decoded["hits"] = int(decoded.hits)
		decoded.geometry.los["collision_mask"] = int(decoded.geometry.los.collision_mask)
	return decoded
