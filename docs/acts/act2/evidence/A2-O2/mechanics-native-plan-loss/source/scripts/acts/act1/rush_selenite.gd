class_name Act1RushSelenite
extends CharacterBody3D
## C30 / A1-E1 greybox consumer. The shared scheduler owns every attack deadline,
## cooldown and leased rush movement. Only HP, hurt settling, sampled damage and
## presentation are authored here. No approach loop or automatic attack cycle.

signal state_changed(actor_state: Dictionary)
signal defeated(source_id: String)
signal hit_resolved(hero_id: String, cycle: int, result: Dictionary)

const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const CueScript = preload("res://scripts/cues/threat_cue.gd")
const ArtScript = preload("res://scripts/acts/act1/rush_selenite_art.gd")
const API_REVISION: String = "act1-rush-selenite-1"
const SNAPSHOT_SCHEMA_VERSION: int = 2
const PENDING_SNAPSHOT_SCHEMA_VERSION: int = 3
const MAX_PENDING_SEGMENTS: int = 256
const HERO_ID: String = "hero"
const GRAVITY: float = 24.0
const HURT_BRAKING: float = 5.0
const HURT_S: float = 0.22
const DEFAULT_RAW_ROLE: Dictionary = {"raw_damage": 8.0, "windup_s": 1.85, "lock_s": 0.85, "active_s": 0.4, "recovery_s": 1.8, "attack_interval_s": 2.0, "max_hp": 20.0, "move_speed": 6.0}
const DEFAULT_TIMING_FLOORS: Dictionary = {"windup_s": 1.85, "lock_s": 0.85, "recovery_s": 1.8}
const DEFAULT_LUNGE: Dictionary = {"speed": 6.0, "distance": 2.4, "damage_radius": 0.38, "body_collision_path": "BodyCollision"}
const CONTEXT_KEYS: Array[String] = ["encounter_id", "world_revision", "recognition_s", "attack_input_margin_s", "escape_directions", "return_directions", "floor_regions"]
const SNAPSHOT_KEYS: Array[String] = ["api_revision", "schema_version", "source_id", "configuration", "hp", "dead", "dormant", "motion", "hurt_left_s", "role_encounter_id", "profile_id", "resolved_role", "reservation_id", "cycle", "sample", "hit_ids", "last_cancel_reason"]

var hp: float = 20.0
var max_hp: float = 20.0
var dead: bool = false
var dormant: bool = false
## Parent grants this source only immediately after successful fresh begin_encounter.
## The pure callable receives source_id and must return literal true. Parent clears
## entitlement after every activation attempt; same-tick cancellation never grants it.
var activation_guard: Callable
## Pure renderer-owned admission/sampling guard; a nonempty reason cancels.
var presentation_guard: Callable
var last_error: String = ""
var last_snapshot_error: String = ""
var _configuration: Dictionary = {}
var _scheduler: CinderThreatScheduler
var _hero: CinderPlayer
var _collision: CollisionShape3D
var _body_signature: Dictionary = {}
var _retained_capsule: CapsuleShape3D
var _native_body_properties: Dictionary = {}
var _cue: CinderThreatCue
var _visual: Node3D
var _body: MeshInstance3D
var _sprite_art: Node3D
var _facing: Vector3 = Vector3.FORWARD
var _hurt_left_s: float = 0.0
var _restored_floor_contact: int = -1
var _role_encounter_id: String = ""
var _profile_id: String = ""
var _resolved_role: Dictionary = {}
var _reservation_id: String = ""
var _cycle: int = 0
var _sample: Dictionary = {}
var _pending_segments: Array[Dictionary] = []
var _hit_ids: Array[String] = []
var _last_cancel_reason: String = ""
var _phase: String = "clear"
var _transaction_depth: int = 0
var _snapshot_busy: bool = false
var _cancelling: bool = false


func configure(source_id: String, raw_role: Dictionary = DEFAULT_RAW_ROLE, timing_floors: Dictionary = DEFAULT_TIMING_FLOORS, lunge: Dictionary = DEFAULT_LUNGE, initially_dormant: bool = false) -> bool:
	if is_instance_valid(_scheduler) or _transaction_depth > 0 or _snapshot_busy:
		return _reject("Configure immutable C30 data before binding")
	if not _stable_id(source_id) or not Codec.value_error(raw_role).is_empty() or not Codec.keys_error(raw_role, DEFAULT_RAW_ROLE.keys()).is_empty() or not Codec.keys_error(timing_floors, DEFAULT_TIMING_FLOORS.keys()).is_empty() or not Codec.value_error(timing_floors).is_empty() or not Codec.keys_error(lunge, DEFAULT_LUNGE.keys()).is_empty() or not Codec.value_error(lunge).is_empty():
		return _reject("Closed finite raw-role, timing-floor and lunge configuration required")
	var difficulty = Difficulty.new()
	for profile_id: String in ["assisted", "standard", "challenge"]:
		var role: Dictionary = difficulty.resolve_role(raw_role, profile_id, timing_floors)
		if role.is_empty():
			return _reject(difficulty.last_error)
		for key: String in ["speed", "distance", "damage_radius"]:
			if not Codec.is_number(lunge[key]) or float(lunge[key]) <= 0.0:
				return _reject("Finite positive lunge values required")
		if lunge.body_collision_path != "BodyCollision" or float(lunge.distance) <= Motion.EPSILON or float(lunge.distance) > Motion.MAX_DISTANCE or float(lunge.damage_radius) < 0.32 + Motion.ENDPOINT_TOLERANCE or float(lunge.distance) / float(lunge.speed) > float(role.active_s) + Motion.EPSILON:
			return _reject("Lunge must contain the actual capsule and fit the resolved active window")
	var canonical_lunge: Dictionary = {"speed": float(lunge.speed), "distance": float(lunge.distance), "damage_radius": float(lunge.damage_radius), "body_collision_path": "BodyCollision"}
	var next: Dictionary = {"source_id": source_id, "raw_role": raw_role.duplicate(true), "timing_floors": timing_floors.duplicate(true), "lunge": canonical_lunge, "initially_dormant": initially_dormant}
	if not _configuration.is_empty():
		if not _same(next, _configuration):
			return _reject("Configured C30 identity and tuning are immutable")
		last_error = ""
		return true
	_configuration = next
	max_hp = float(raw_role.max_hp)
	hp = max_hp
	dormant = initially_dormant
	if is_node_ready():
		_apply_lifecycle_flags()
	last_error = ""
	return true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 100
	collision_layer = 2
	collision_mask = 1
	_collision = CollisionShape3D.new()
	_collision.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.45
	_collision.shape = capsule
	_collision.position = Vector3(0.0, 0.73, 0.0)
	add_child(_collision)
	_body_signature = Motion.source_description(self).get("signature", {}).duplicate(true)
	_retained_capsule = capsule
	_native_body_properties = _read_native_body_properties()
	_cue = CueScript.new()
	_cue.name = "ThreatCue"
	add_child(_cue)
	_build_greybox()
	_apply_lifecycle_flags()


func activate() -> bool:
	if not _live_bindings() or _transaction_depth > 0 or _snapshot_busy or _cancelling or not activation_guard.is_valid():
		return _reject("Activation requires a parent fresh-boundary guard outside callbacks")
	var error: String = _activation_error()
	if not error.is_empty():
		return _reject(error)
	_transaction_depth += 1
	var entitled: Variant = activation_guard.call(String(_configuration.source_id))
	# Keep the barrier across the callback and recheck native/lifecycle/public state.
	error = _activation_error()
	if not entitled is bool or entitled != true or not error.is_empty():
		_transaction_depth -= 1
		return _reject(error if not error.is_empty() else "Parent did not grant this source at its actual fresh encounter boundary")
	dormant = false
	_apply_lifecycle_flags()
	last_error = ""
	state_changed.emit(state())
	_transaction_depth -= 1
	return true


func _activation_error() -> String:
	if not _live_bindings():
		return "Activation requires retained ready source, scheduler and Player bindings"
	if not _configuration.get("initially_dormant", false) or not dormant or dead or not _dormant_state_error().is_empty():
		return "Only a pristine initially dormant source can activate once"
	if _scheduler.encounter_profile().is_empty() or _scheduler.get_clock() != 0.0 or _scheduler.has_committed_exchange():
		return "Parent must establish a fresh nonempty encounter/profile before activation"
	var error: String = _retained_body_error()
	if error.is_empty():
		error = _lifecycle_error()
	if error.is_empty():
		error = art_binding_error()
	if error.is_empty() and get_parent() is Node3D and not (get_parent() as Node3D).is_visible_in_tree():
		error = "Activation cannot reveal a source under a hidden ancestor"
	return error


func bind(scheduler: CinderThreatScheduler, hero: CinderPlayer) -> bool:
	if _transaction_depth > 0 or _snapshot_busy or not is_inside_tree() or not is_node_ready() or _configuration.is_empty():
		return _reject("Bind a ready configured C30 outside callbacks")
	if not is_instance_valid(scheduler) or not scheduler.is_inside_tree() or scheduler.get_world_3d() != get_world_3d() or scheduler.process_physics_priority >= process_physics_priority or not is_instance_valid(hero) or not hero.is_inside_tree() or hero.is_queued_for_deletion() or hero.get_world_3d() != get_world_3d() or hero.process_physics_priority >= process_physics_priority:
		return _reject("Same-world earlier-physics scheduler and actual shared hero required")
	if is_instance_valid(_scheduler):
		return true if _scheduler == scheduler and _hero == hero else _reject("C30 scheduler and hero bindings are immutable")
	_scheduler = scheduler
	_hero = hero
	_scheduler.reservation_invalidated.connect(_on_invalidated)
	last_error = ""
	return true


func preview_lunge(response_context: Dictionary, direction: Vector3, world_root: Node3D) -> Dictionary:
	# Pure: do not store resolved role, diagnostics, cycle, activation or a lease.
	var prepared: Dictionary = _prepare_start(response_context, direction, world_root)
	if not prepared.get("accepted", false):
		return prepared
	return _scheduler.preview_lunge(self, prepared.threat, prepared.response)


func start(response_context: Dictionary, direction: Vector3, world_root: Node3D = null, preview: Dictionary = {}) -> Dictionary:
	if not preview.is_empty() and world_root == null:
		return _denied("A copied preview requires its explicit actual containing world root")
	var prepared: Dictionary = _prepare_start(response_context, direction, world_root)
	if not prepared.get("accepted", false):
		return _denied(String(prepared.reason))
	_transaction_depth += 1
	var answer: Dictionary = _scheduler.request_lunge(self, prepared.threat, prepared.response, preview)
	if answer.get("accepted", false):
		_reservation_id = String(answer.reservation_id)
		_role_encounter_id = response_context.encounter_id
		_profile_id = String(prepared.profile_id)
		_resolved_role = prepared.role.duplicate(true)
		_cycle += 1
		_facing = direction
		_hit_ids.clear()
		_pending_segments.clear()
		_sample_now()
		_last_cancel_reason = ""
		_present(_scheduler.reservation_state(_reservation_id))
	else:
		last_error = String(answer.get("reason", "Lunge rejected"))
	_transaction_depth -= 1
	return answer.duplicate(true)


func _prepare_start(response_context: Dictionary, direction: Vector3, world_root: Node3D) -> Dictionary:
	if not _live_bindings() or _transaction_depth > 0 or _snapshot_busy or _cancelling or dead or dormant or get_tree().paused or not _reservation_id.is_empty() or _hurt_left_s > 0.0 or velocity.length() > Motion.EPSILON or not is_visible_in_tree() or _cycle >= Codec.MAX_SAFE_INTEGER:
		return {"accepted": false, "reason": "Start requires an activated live stopped unpaused idle C30 outside callbacks"}
	if not Codec.keys_error(response_context, CONTEXT_KEYS).is_empty() or not _stable_id(response_context.get("encounter_id")) or not Geometry.finite_vector(direction) or absf(direction.y) > Motion.EPSILON or absf(direction.length() - 1.0) > Motion.EPSILON:
		return {"accepted": false, "reason": "Authored encounter context and fixed normalized world direction required"}
	if world_root != null and (not is_instance_valid(world_root) or not world_root.is_inside_tree() or world_root.is_queued_for_deletion() or world_root.get_world_3d() != get_world_3d() or not world_root.is_ancestor_of(self) or not world_root.is_ancestor_of(_hero) or not world_root.is_ancestor_of(_scheduler)):
		return {"accepted": false, "reason": "Actual containing same-world root must retain actor, hero and scheduler"}
	var guard_error: String = _retained_body_error()
	if guard_error.is_empty():
		guard_error = _lifecycle_error()
	if guard_error.is_empty():
		guard_error = art_binding_error()
	if guard_error.is_empty():
		guard_error = _presentation_error()
	if not guard_error.is_empty():
		return {"accepted": false, "reason": guard_error}
	var response: Dictionary = _hero.get_threat_response_state()
	if not String(response.get("pending_weapon_id", "")).is_empty():
		return {"accepted": false, "reason": "Wait for the actual pending weapon application"}
	for key: String in CONTEXT_KEYS:
		if key != "encounter_id":
			response[key] = response_context[key]
	if world_root != null:
		response.world_root = world_root
	var profile: Dictionary = _scheduler.encounter_profile()
	var profile_id: String = String(profile.get("id", ""))
	var difficulty = Difficulty.new()
	var role: Dictionary = _resolved_role.duplicate(true)
	if _role_encounter_id != response_context.encounter_id:
		role = difficulty.resolve_role(_configuration.raw_role, profile_id, _configuration.timing_floors)
	elif _profile_id != profile_id:
		return {"accepted": false, "reason": "Resolve the fixed encounter profile only once"}
	if role.is_empty():
		return {"accepted": false, "reason": difficulty.last_error}
	var lunge: Dictionary = _configuration.lunge.duplicate(true)
	# The native preview codec requires String keys; dictionary dot insertion
	# creates a StringName for this new field on Godot 4.7.
	lunge["direction"] = direction
	var threat: Dictionary = {"role": role, "source_stationary": false, "opening_stationary": true, "cooldown_remaining_s": 0.0, "lunge": lunge}
	return {"accepted": true, "threat": threat, "response": response, "role": role, "profile_id": profile_id}


func take_damage(amount: float, impulse: Vector3) -> Dictionary:
	var result: Dictionary = {"accepted": false, "hp_damage": 0.0, "target_id": get_instance_id(), "target_alive_before_hit": hp > 0.0 and not dead and not dormant and not is_queued_for_deletion()}
	if not _live_bindings() or _snapshot_busy or _transaction_depth > 0 or not result.target_alive_before_hit or not is_finite(amount) or amount <= 0.0 or not impulse.is_finite():
		return result
	_transaction_depth += 1
	# The scheduler stops its velocity first; hurt can then own the real impulse.
	cancel("actual_player_damage")
	var before: float = hp
	hp = maxf(0.0, hp - amount)
	result.accepted = true
	result.hp_damage = before - hp
	if hp == 0.0:
		dead = true
		_hurt_left_s = 0.0
		velocity = Vector3.ZERO
		_scheduler.cancel_owner(self, "source_defeated")
		collision_layer = 0
		collision_mask = 0
		_collision.set_deferred("disabled", true)
		remove_from_group("enemies")
		visible = false
		defeated.emit(String(_configuration.source_id))
	else:
		velocity += impulse
		_hurt_left_s = HURT_S
	state_changed.emit(state())
	_transaction_depth -= 1
	return result


func cancel(reason: String = "rusher_cancelled") -> bool:
	if _snapshot_busy or _cancelling:
		return false
	if dormant:
		return true
	_cancelling = true
	_transaction_depth += 1
	var id: String = _reservation_id
	_reservation_id = ""
	_sample.clear()
	_pending_segments.clear()
	_hit_ids.clear()
	_last_cancel_reason = reason
	if not id.is_empty() and is_instance_valid(_scheduler):
		_scheduler.cancel(id, reason)
	_present({}, true)
	_transaction_depth -= 1
	_cancelling = false
	return true


func state() -> Dictionary:
	var record: Dictionary = _scheduler.reservation_state(_reservation_id) if is_instance_valid(_scheduler) and not _reservation_id.is_empty() else {}
	var phase: String = String(record.get("state", "clear"))
	var status: String = "dormant" if dormant else ("defeated" if dead else ("running" if not record.is_empty() else ("hurt" if _hurt_left_s > 0.0 else "idle")))
	var result: Dictionary = {"api_revision": API_REVISION, "source_id": _configuration.get("source_id", ""), "hp": hp, "dead": dead, "dormant": dormant, "status": status, "phase": phase, "reservation_id": _reservation_id, "cycle": _cycle, "source_position": global_position, "opening_position": record.get("opening_position", global_position), "geometry": record.get("geometry", {}).duplicate(true), "resolved_role": _resolved_role.duplicate(true), "hit_ids": _hit_ids.duplicate(), "hurt_left_s": _hurt_left_s, "last_cancel_reason": _last_cancel_reason}
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "armed", "adapter"]:
		if record.has(key):
			result[key] = record[key].duplicate(true) if record[key] is Dictionary else record[key]
	return result


func get_cue() -> CinderThreatCue:
	return _cue


func get_art() -> Node3D:
	return _sprite_art


func art_binding_error() -> String:
	# The billboard must remain at this real actor's feet. An inherited hidden
	# parent cannot be excused by the sprite's own local visible flag.
	if not is_instance_valid(_visual) or not _visual.is_inside_tree() or _visual.is_queued_for_deletion() or _visual.get_parent() != self or _visual.is_set_as_top_level() or not _visual.visible:
		return "C30 requires its visible retained actor presentation parent"
	if _visual.position != Vector3.ZERO or _visual.scale != Vector3.ONE or _visual.rotation.x != 0.0 or _visual.rotation.z != 0.0 or not is_finite(_visual.rotation.y):
		return "C30 presentation must retain its unscaled foot origin and planar facing"
	if not is_instance_valid(_sprite_art) or not _sprite_art.is_inside_tree() or _sprite_art.is_queued_for_deletion() or _sprite_art.get_parent() != _visual or not _sprite_art.visible:
		return "C30 requires its retained pixel presentation"
	return String(_sprite_art.call("binding_error"))


func _physics_process(delta: float) -> void:
	if dead or dormant or not _live_bindings() or get_tree().paused or _transaction_depth > 0:
		return
	_transaction_depth += 1
	if not _reservation_id.is_empty():
		var record: Dictionary = _damage_boundary_record(false)
		if not record.is_empty() and _stage_sample():
			# The real actor physics interval is retained before cue/phase observers.
			# A synchronous held pause must neither deliver nor discard this path.
			_present(record)
			record = _damage_boundary_record(true)
			if not record.is_empty():
				_resolve_pending_segments()
	else:
		_hurt_left_s = maxf(0.0, _hurt_left_s - delta)
		# Explicit authored settling only; no approach, target tracking or attack.
		velocity.x = move_toward(velocity.x, 0.0, HURT_BRAKING * delta)
		velocity.z = move_toward(velocity.z, 0.0, HURT_BRAKING * delta)
		if not _grounded():
			velocity.y -= GRAVITY * delta
		elif velocity.y < 0.0:
			velocity.y = 0.0
		move_and_slide()
		_restored_floor_contact = -1
		_draw_greybox()
	_transaction_depth -= 1


func _stage_sample() -> bool:
	var previous: Dictionary = _sample.duplicate(true)
	_sample_now()
	if previous.is_empty():
		cancel("sampled_exchange_missing")
		return false
	if not _hero.dead and not _hit_ids.has(HERO_ID):
		if _pending_segments.size() >= MAX_PENDING_SEGMENTS:
			cancel("pending_path_budget_exceeded")
			return false
		_pending_segments.append({"from": previous.hero_position - previous.source_position, "to": _sample.hero_position - _sample.source_position, "start_s": previous.clock_s, "end_s": _sample.clock_s})
	return true


func _resolve_pending_segments() -> void:
	if _pending_segments.is_empty():
		return
	# Revalidate immediately before consuming the opportunity. Clear it before
	# Player hurt/death and hit observers, preserving exactly-once delivery.
	var current: Dictionary = _damage_boundary_record(true)
	if current.is_empty():
		return
	var path: Array[Dictionary] = _pending_segments.duplicate(true)
	_pending_segments.clear()
	if _hero.dead or _hit_ids.has(HERO_ID) or not current.get("armed", false):
		return
	var hit: bool = false
	for segment: Dictionary in path:
		# Geometry's spatial epsilon cannot advance an opportunity into lock.
		if maxf(float(segment.start_s), float(current.active_from_s)) > minf(float(segment.end_s), float(current.active_until_s)):
			continue
		if Geometry.timed_path_hits(Geometry.circle(Vector3.ZERO, float(current.adapter.damage_radius)), [segment], float(current.active_from_s), float(current.active_until_s), CinderThreatScheduler.CAPSULE_RADIUS):
			hit = true
			break
	if not hit:
		return
	_hit_ids.append(HERO_ID)
	var before: float = _hero.hp
	_hero.take_damage(float(_resolved_role.damage), Vector3.ZERO)
	var result: Dictionary = {"opportunity_consumed": true, "accepted": _hero.hp < before, "raw_damage": float(_resolved_role.damage), "hp_damage": maxf(before - _hero.hp, 0.0), "impulse": Vector3.ZERO}
	_damage_boundary_record(true)
	hit_resolved.emit(HERO_ID, _cycle, result)
	_damage_boundary_record(true)


func _damage_boundary_record(current_source_marker: bool) -> Dictionary:
	if _reservation_id.is_empty():
		return {}
	if dead or dormant or not _live_bindings() or is_queued_for_deletion() or not is_visible_in_tree():
		cancel("required_source_or_bindings_unavailable")
		return {}
	var record: Dictionary = _scheduler.reservation_state(_reservation_id)
	if _reservation_id.is_empty():
		return {}
	if record.is_empty():
		_reservation_id = ""
		_sample.clear()
		_pending_segments.clear()
		_hit_ids.clear()
		_present({})
		return {}
	var error: String = _retained_body_error()
	if error.is_empty(): error = _lifecycle_error()
	if error.is_empty(): error = art_binding_error()
	if error.is_empty(): error = _presentation_error()
	if not error.is_empty():
		cancel(error)
		return {}
	if not _required_cue_available(record, current_source_marker):
		cancel("required_source_or_cue_unavailable")
		return {}
	# A pure authored guard or scheduler cleanup may notify other observers.
	if _reservation_id.is_empty() or not _live_bindings() or dead or dormant or not is_visible_in_tree():
		return {}
	if get_tree().paused:
		return {}
	var latest: Dictionary = _scheduler.reservation_state(_reservation_id)
	if _reservation_id.is_empty(): return {}
	if latest != record or int(record.get("source_instance_id", 0)) != get_instance_id() or record.get("source_position") != global_position or record.get("adapter", {}).get("current_velocity") != velocity or not _required_cue_available(record, current_source_marker) or get_tree().paused:
		cancel("committed_source_or_exchange_changed")
		return {}
	return record


func _required_cue_available(record: Dictionary, current_source_marker: bool) -> bool:
	if not is_instance_valid(_cue) or _cue.is_queued_for_deletion() or not _cue.is_visible_in_tree():
		return false
	var shown: Dictionary = _cue.state()
	if shown.phase != _phase or shown.geometry != record.geometry or (current_source_marker and shown.source_position != global_position):
		return false
	var names: Array[String] = ["RequiredSourceMarker"]
	if _phase != "recovery": names.append("RequiredFootprintOutline")
	if _phase == "active": names.append("RequiredFootprintFill")
	for part_name: String in names:
		var part: MeshInstance3D = _cue.get_node_or_null(part_name) as MeshInstance3D
		if not is_instance_valid(part) or part.is_queued_for_deletion() or not part.is_visible_in_tree() or part.mesh == null:
			return false
	return true


func _sample_now() -> void:
	_sample = {"clock_s": _scheduler.get_clock(), "source_position": global_position, "hero_position": _hero.global_position}


func _present(record: Dictionary, notify: bool = true) -> void:
	var next: String = String(record.get("state", "clear"))
	var changed: bool = next != _phase
	_phase = next
	if next == "clear":
		_cue.clear()
	else:
		var geometry: Dictionary = record.geometry.duplicate(true)
		geometry.source_position = global_position
		_cue.present(geometry, next)
	# Required cue callbacks may synchronously cancel the source.
	if _reservation_id.is_empty():
		_phase = "clear"
		_cue.clear()
	_draw_greybox()
	if notify and changed:
		state_changed.emit(state())


func _on_invalidated(id: String, reason: String) -> void:
	if id == _reservation_id and not _cancelling:
		cancel(reason)


func _presentation_error() -> String:
	if not presentation_guard.is_valid():
		return ""
	var result: Variant = presentation_guard.call()
	return result if result is String else "C30 presentation guard must return a String"


func _live_bindings() -> bool:
	return not _configuration.is_empty() and is_inside_tree() and is_node_ready() and is_instance_valid(_scheduler) and _scheduler.is_inside_tree() and not _scheduler.is_queued_for_deletion() and _scheduler.get_world_3d() == get_world_3d() and _scheduler.process_physics_priority < process_physics_priority and is_instance_valid(_hero) and _hero.is_inside_tree() and not _hero.is_queued_for_deletion() and _hero.get_world_3d() == get_world_3d() and _hero.process_physics_priority < process_physics_priority and is_instance_valid(_collision) and _collision.is_inside_tree() and is_instance_valid(_cue) and _cue.is_inside_tree() and not _cue.is_queued_for_deletion() and is_instance_valid(_visual) and _visual.is_inside_tree() and is_instance_valid(_body) and _body.is_inside_tree()


func _grounded() -> bool:
	return _restored_floor_contact == 1 if _restored_floor_contact >= 0 else is_on_floor()


func _read_native_body_properties() -> Dictionary:
	var capsule := _collision.shape as CapsuleShape3D
	return {"collision_transform": _collision.transform, "radius": capsule.radius, "height": capsule.height, "margin": capsule.margin, "custom_solver_bias": capsule.custom_solver_bias, "safe_margin": safe_margin, "collision_priority": collision_priority, "up_direction": up_direction, "floor_snap_length": floor_snap_length, "motion_mode": motion_mode, "linear_axis_locks": [axis_lock_linear_x, axis_lock_linear_y, axis_lock_linear_z], "process_mode": process_mode, "physics_priority": process_physics_priority, "shape_owners": get_shape_owners()}


func _retained_body_error() -> String:
	# Owned node/resource/property validation works while disabled and unpaused.
	# It neither enables collision for measurement nor reproduces a shared solver.
	if not is_inside_tree() or not is_node_ready() or is_queued_for_deletion() or not is_instance_valid(_collision) or not _collision.is_inside_tree() or _collision.is_queued_for_deletion() or _collision.get_parent() != self or get_node_or_null("BodyCollision") != _collision or _collision.shape != _retained_capsule or not is_instance_valid(_retained_capsule) or _native_body_properties.is_empty() or _body_signature.is_empty():
		return "Retained actual C30 capsule node/resource identity changed"
	if global_basis != Basis.IDENTITY or not global_position.is_finite() or not velocity.is_finite() or not get_collision_exceptions().is_empty() or not get_platform_velocity().is_zero_approx() or not get_platform_angular_velocity().is_zero_approx():
		return "Retained C30 requires its upright finite fixed-world native body"
	var collider_count: int = 0
	for child: Node in get_children():
		if child is CollisionShape3D or child is CollisionPolygon3D:
			collider_count += 1
	var owners: PackedInt32Array = get_shape_owners()
	if collider_count != 1 or owners.size() != 1 or _read_native_body_properties() != _native_body_properties:
		return "Retained C30 native capsule/body properties or registrations changed"
	var shape_owner_id: int = owners[0]
	if shape_owner_get_owner(shape_owner_id) != _collision or shape_owner_get_shape_count(shape_owner_id) != 1 or shape_owner_get_shape(shape_owner_id, 0) != _retained_capsule or shape_owner_get_transform(shape_owner_id) != _collision.transform or is_shape_owner_disabled(shape_owner_id) != _collision.disabled:
		return "Retained C30 registered footprint differs from its actual capsule"
	return ""


func _lifecycle_error() -> String:
	var inactive: bool = dead or dormant
	if max_hp != float(_configuration.raw_role.max_hp) or not is_finite(hp) or hp < 0.0 or hp > max_hp or dead != (hp == 0.0):
		return "Actual C30 HP/death disagrees with immutable role"
	if _collision.disabled != inactive or collision_layer != (0 if inactive else 2) or collision_mask != (0 if inactive else 1) or is_in_group("enemies") == inactive or visible == inactive:
		return "Actual C30 lifecycle flags/group/visibility disagree with HP/dormancy"
	if not inactive and not is_visible_in_tree():
		return "Living C30 cannot remain under an inherited hidden parent"
	if dormant:
		return _dormant_state_error()
	return ""


func _dormant_state_error() -> String:
	if not _configuration.get("initially_dormant", false) or dead or hp != max_hp or velocity != Vector3.ZERO or _hurt_left_s != 0.0 or _cycle != 0 or _phase != "clear" or not _role_encounter_id.is_empty() or not _profile_id.is_empty() or not _resolved_role.is_empty() or not _reservation_id.is_empty() or not _sample.is_empty() or not _pending_segments.is_empty() or not _hit_ids.is_empty() or not _last_cancel_reason.is_empty():
		return "Dormant C30 must retain pristine HP and no motion/combat history"
	if is_instance_valid(_cue) and _cue.state().phase != "clear":
		return "Dormant C30 cannot hide a required hazard cue"
	return ""


func _apply_lifecycle_flags() -> void:
	var inactive: bool = dead or dormant
	collision_layer = 0 if inactive else 2
	collision_mask = 0 if inactive else 1
	_collision.disabled = inactive
	visible = not inactive
	if inactive:
		remove_from_group("enemies")
	else:
		add_to_group("enemies")


func _snapshot_access_error() -> String:
	var art_error: String = art_binding_error()
	if not art_error.is_empty():
		return art_error
	if not _live_bindings() or not get_tree().paused or is_queued_for_deletion():
		return "C30 snapshots require retained ready bindings at the paused deferred barrier"
	if _transaction_depth > 0 or _snapshot_busy or _cancelling:
		return "C30 snapshots cannot run inside actor/phase/hit/cancellation callbacks"
	var retained_error: String = _retained_body_error()
	if not retained_error.is_empty():
		return retained_error
	var description: Dictionary = Motion.staged_source_description(self, _live_collision_state())
	if description.has("error") or not _same(description.get("signature", {}), _body_signature):
		return "Actual retained C30 capsule/registration/transform no longer matches its immutable body"
	if global_basis != Basis.IDENTITY or not global_position.is_finite() or not velocity.is_finite():
		return "Actual C30 motion must retain its upright finite body frame"
	return ""


func snapshot_state(paired_scheduler: Dictionary) -> Dictionary:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty():
		return {}
	_snapshot_busy = true
	var saved: Dictionary = {"api_revision": API_REVISION, "schema_version": SNAPSHOT_SCHEMA_VERSION, "source_id": _configuration.source_id, "configuration": _configuration.duplicate(true), "hp": hp, "dead": dead, "dormant": dormant, "motion": {"position": Codec.vector3(global_position), "velocity": Codec.vector3(velocity), "facing": Codec.vector3(_facing), "grounded": _grounded()}, "hurt_left_s": _hurt_left_s, "role_encounter_id": _role_encounter_id, "profile_id": _profile_id, "resolved_role": _resolved_role.duplicate(true), "reservation_id": _reservation_id, "cycle": _cycle, "sample": _encode_sample(), "hit_ids": _hit_ids.duplicate(), "last_cancel_reason": _last_cancel_reason}
	if not _pending_segments.is_empty():
		saved["schema_version"] = PENDING_SNAPSHOT_SCHEMA_VERSION
		saved["pending_segments"] = []
		for segment: Dictionary in _pending_segments:
			saved.pending_segments.append({"from": Codec.vector3(segment.from), "to": Codec.vector3(segment.to), "start_s": segment.start_s, "end_s": segment.end_s})
	last_snapshot_error = _actor_error(saved, paired_scheduler, _hero.snapshot_state())
	if last_snapshot_error.is_empty():
		last_snapshot_error = _lifecycle_error()
	_snapshot_busy = false
	return saved if last_snapshot_error.is_empty() else {}


func actor_snapshot_error(saved: Dictionary, paired_scheduler: Dictionary, saved_player: Dictionary) -> String:
	var error: String = _snapshot_access_error()
	if not error.is_empty():
		return error
	_snapshot_busy = true
	error = _actor_error(saved, paired_scheduler, saved_player)
	_snapshot_busy = false
	return error


func staged_actor_bindings(saved: Dictionary) -> Dictionary:
	# Caller first validates the complete actor/player/scheduler aggregate. These
	# maps are native staging, never local transport or substitute geometry.
	if not _snapshot_access_error().is_empty() or not _schema_error(saved).is_empty():
		return {}
	var result: Dictionary = {"owner_positions": {String(saved.source_id): Codec.read_vector3(saved.motion.position)}, "owner_velocities": {String(saved.source_id): Codec.read_vector3(saved.motion.velocity)}, "owner_collision_states": {}}
	if not saved.reservation_id.is_empty():
		if saved.dead or saved.dormant:
			return {}
		result.owner_collision_states[String(saved.source_id)] = _live_collision_state()
	return result


func restore_actor_state(saved: Dictionary) -> bool:
	## First commit after ROOT whole-aggregate prevalidation. Do not run configure,
	## damage/death/cancel/request paths or yield. Exchange commit follows scheduler.
	last_snapshot_error = _snapshot_access_error()
	if last_snapshot_error.is_empty():
		last_snapshot_error = _schema_error(saved)
	if not last_snapshot_error.is_empty():
		return false
	_snapshot_busy = true
	global_position = Codec.read_vector3(saved.motion.position)
	velocity = Codec.read_vector3(saved.motion.velocity)
	_facing = Codec.read_vector3(saved.motion.facing)
	hp = float(saved.hp)
	dead = saved.dead
	dormant = saved.dormant
	_hurt_left_s = float(saved.hurt_left_s)
	_restored_floor_contact = 1 if saved.motion.grounded else 0
	_apply_lifecycle_flags()
	_snapshot_busy = false
	return true


func restore_exchange_state(saved: Dictionary) -> bool:
	## Second commit only after the actual source and shared scheduler commit.
	last_snapshot_error = _snapshot_access_error()
	if last_snapshot_error.is_empty():
		last_snapshot_error = _schema_error(saved)
	if not last_snapshot_error.is_empty():
		return false
	var inactive: bool = dead or dormant
	if hp != saved.hp or dead != saved.dead or dormant != saved.dormant or not _same(Codec.vector3(global_position), saved.motion.position) or not _same(Codec.vector3(velocity), saved.motion.velocity) or _collision.disabled != inactive or collision_layer != (0 if inactive else 2) or collision_mask != (0 if inactive else 1) or is_in_group("enemies") == inactive or visible == inactive:
		last_snapshot_error = "Apply the exact validated actual C30 lifecycle/motion before exchange commit"
		return false
	var record: Dictionary = _scheduler.reservation_state(saved.reservation_id) if not saved.reservation_id.is_empty() else {}
	if not saved.reservation_id.is_empty():
		if record.is_empty() or int(record.source_instance_id) != get_instance_id() or _scheduler.get_clock() != saved.sample.clock_s or not _same(Codec.vector3(record.source_position), saved.motion.position) or not _same(Codec.vector3(record.adapter.current_velocity), saved.motion.velocity) or not _same(Codec.vector3(_hero.global_position), saved.sample.hero_position):
			last_snapshot_error = "Actual restored scheduler/source/hero must match the validated sampled exchange"
			return false
		var current_pair: Dictionary = {"clock_s": _scheduler.get_clock(), "encounter_id": saved.role_encounter_id, "profile": _scheduler.encounter_profile(), "reservations": [_encode_public_record(record)], "cooldowns": []}
		last_snapshot_error = _actor_error(saved, current_pair, _hero.snapshot_state())
		if not last_snapshot_error.is_empty():
			return false
	else:
		for existing: Dictionary in _scheduler.reservations():
			if int(existing.source_instance_id) == get_instance_id():
				last_snapshot_error = "Inactive C30 cannot hide an actual retained reservation"
				return false
	_snapshot_busy = true
	_role_encounter_id = saved.role_encounter_id
	_profile_id = saved.profile_id
	_resolved_role = saved.resolved_role.duplicate(true)
	_reservation_id = saved.reservation_id
	_cycle = int(saved.cycle)
	_sample = {} if saved.sample.is_empty() else {"clock_s": saved.sample.clock_s, "source_position": Codec.read_vector3(saved.sample.source_position), "hero_position": Codec.read_vector3(saved.sample.hero_position)}
	_pending_segments.clear()
	for segment: Dictionary in saved.get("pending_segments", []):
		_pending_segments.append({"from": Codec.read_vector3(segment.from), "to": Codec.read_vector3(segment.to), "start_s": segment.start_s, "end_s": segment.end_s})
	_hit_ids.clear()
	for id: String in saved.hit_ids:
		_hit_ids.append(id)
	_last_cancel_reason = saved.last_cancel_reason
	var blocked: bool = _cue.is_blocking_signals()
	_cue.set_block_signals(true)
	_cue.clear()
	_present(record, false)
	_cue.set_block_signals(blocked)
	_snapshot_busy = false
	return true


func _schema_error(saved: Dictionary) -> String:
	var error: String = Codec.value_error(saved)
	if error.is_empty():
		var keys: Array[String] = SNAPSHOT_KEYS.duplicate()
		if saved.get("schema_version") == PENDING_SNAPSHOT_SCHEMA_VERSION: keys.append("pending_segments")
		error = Codec.keys_error(saved, keys)
	if not error.is_empty():
		return error
	if saved.api_revision != API_REVISION or not saved.schema_version is int or saved.schema_version not in [SNAPSHOT_SCHEMA_VERSION, PENDING_SNAPSHOT_SCHEMA_VERSION] or saved.source_id != _configuration.source_id or not saved.configuration is Dictionary or not _same(saved.configuration, _configuration) or not Codec.in_range(saved.hp, 0.0, max_hp) or not saved.dead is bool or saved.dead != (saved.hp == 0.0) or not saved.dormant is bool or not saved.motion is Dictionary or not Codec.keys_error(saved.motion, ["position", "velocity", "facing", "grounded"]).is_empty() or not saved.motion.grounded is bool:
		return "Invalid immutable C30 identity/configuration/HP/motion envelope"
	for key: String in ["position", "velocity", "facing"]:
		if not Codec.is_vector3(saved.motion[key]) or not _same(Codec.vector3(Codec.read_vector3(saved.motion[key])), saved.motion[key]):
			return "C30 motion requires finite serialized vectors"
	var facing: Vector3 = Codec.read_vector3(saved.motion.facing)
	if absf(facing.y) > Motion.EPSILON or absf(facing.length() - 1.0) > Motion.EPSILON or not saved.hurt_left_s is float or not Codec.in_range(saved.hurt_left_s, 0.0, HURT_S) or not saved.cycle is int or not Codec.is_integer(saved.cycle) or not saved.reservation_id is String or not saved.role_encounter_id is String or not saved.profile_id is String or not saved.resolved_role is Dictionary or not saved.sample is Dictionary or not saved.hit_ids is Array or not saved.last_cancel_reason is String:
		return "Invalid C30 facing, hurt clock or exchange field types"
	if saved.schema_version == PENDING_SNAPSHOT_SCHEMA_VERSION and (not saved.pending_segments is Array or saved.pending_segments.is_empty() or saved.pending_segments.size() > MAX_PENDING_SEGMENTS or saved.dead or saved.dormant or saved.reservation_id.is_empty() or saved.hurt_left_s != 0.0 or not saved.hit_ids.is_empty()):
		return "Pending C30 schema3 requires a bounded unconsumed path in its live unharmed exchange"
	if saved.dead and (not saved.reservation_id.is_empty() or saved.hurt_left_s != 0.0 or Codec.read_vector3(saved.motion.velocity) != Vector3.ZERO):
		return "Defeated C30 cannot retain motion, hurt or a live lease"
	if saved.dormant and (not _configuration.initially_dormant or saved.dead or saved.hp != max_hp or Codec.read_vector3(saved.motion.velocity) != Vector3.ZERO or saved.hurt_left_s != 0.0 or saved.cycle != 0 or not saved.role_encounter_id.is_empty() or not saved.profile_id.is_empty() or not saved.resolved_role.is_empty() or not saved.reservation_id.is_empty() or not saved.sample.is_empty() or not saved.hit_ids.is_empty() or not saved.last_cancel_reason.is_empty()):
		return "Dormant snapshot cannot invent injury, activation or combat history"
	if saved.cycle == 0:
		if not saved.role_encounter_id.is_empty() or not saved.profile_id.is_empty() or not saved.resolved_role.is_empty() or not saved.reservation_id.is_empty():
			return "Fresh C30 cannot invent prior exchanges"
	else:
		if not _stable_id(saved.role_encounter_id):
			return "Executed C30 requires its stable encounter epoch"
		var difficulty = Difficulty.new()
		var role: Dictionary = difficulty.resolve_role(_configuration.raw_role, saved.profile_id, _configuration.timing_floors)
		if role.is_empty() or not _same(role, saved.resolved_role):
			return "Saved C30 role must resolve exactly from immutable raw data"
	if saved.reservation_id.is_empty():
		return "Inactive C30 cannot retain sampled damage state" if not saved.sample.is_empty() or not saved.hit_ids.is_empty() else ""
	if saved.dead or saved.hurt_left_s != 0.0 or saved.cycle < 1 or not saved.reservation_id.begins_with("threat-") or not Codec.keys_error(saved.sample, ["clock_s", "source_position", "hero_position"]).is_empty() or not saved.sample.clock_s is float or not Codec.in_range(saved.sample.clock_s, 0.0, 1000000000.0) or not Codec.is_vector3(saved.sample.source_position) or not Codec.is_vector3(saved.sample.hero_position) or not _same(saved.sample.source_position, saved.motion.position):
		return "Live C30 requires a coherent finite source/hero sample and unharmed lease"
	if saved.hit_ids.size() > 1 or (saved.hit_ids.size() == 1 and saved.hit_ids[0] != HERO_ID):
		return "C30 hit dedupe must contain the unique actual bound hero ID"
	return ""


func _actor_error(saved: Dictionary, paired: Dictionary, saved_player: Dictionary) -> String:
	var error: String = _schema_error(saved)
	if not error.is_empty():
		return error
	if not paired.get("reservations") is Array or not paired.get("cooldowns") is Array or not paired.get("clock_s") is float or not paired.get("encounter_id") is String or not paired.get("profile") is Dictionary:
		return "Validated paired scheduler transport required"
	var owned: Dictionary = {}
	for value: Variant in paired.reservations:
		if not value is Dictionary:
			return "Malformed paired scheduler reservation"
		if value.get("source_id") == saved.source_id:
			if not owned.is_empty():
				return "C30 cannot own duplicate scheduler exchanges"
			owned = value
	if saved.dead or saved.dormant:
		for value: Variant in paired.cooldowns:
			if not value is Dictionary or value.get("source_id") == saved.source_id:
				return "Defeated/dormant C30 cannot retain its owner cooldown"
	if saved.reservation_id.is_empty():
		return "Inactive C30 cannot discard a scheduler lease" if not owned.is_empty() else ""
	if owned.is_empty() or owned.get("id") != saved.reservation_id or paired.encounter_id != saved.role_encounter_id or paired.profile.get("id") != saved.profile_id or not owned.get("adapter") is Dictionary or owned.adapter.get("kind") != "lunge":
		return "C30 requires the same paired encounter/profile/actual lunge reservation"
	var adapter: Dictionary = owned.adapter
	for key: String in ["current_position", "current_velocity", "direction"]:
		if not Codec.is_vector3(adapter.get(key)):
			return "Paired lunge requires actual finite motion vectors"
	if not _same(owned.get("source_position"), saved.motion.position) or not _same(adapter.current_position, saved.motion.position) or not _same(adapter.current_velocity, saved.motion.velocity) or not _same(adapter.direction, saved.motion.facing) or saved.sample.clock_s != paired.clock_s:
		return "Saved C30 motion/sample must match the exact paired source tick"
	if not saved_player.get("motion") is Dictionary or not Codec.is_vector3(saved_player.motion.get("position")) or not _same(saved.sample.hero_position, saved_player.motion.position):
		return "Saved C30 hero sample must match the separately validated saved player"
	for key: String in ["speed", "distance", "damage_radius", "body_collision_path"]:
		if not _same(adapter.get(key), _configuration.lunge[key]):
			return "Paired lunge parameters differ from immutable C30 tuning"
	var description: Dictionary = Motion.staged_source_description(self, _live_collision_state())
	if description.has("error") or not _same(adapter.get("body_signature"), description.get("signature", {})):
		return "Paired lunge must retain the actual unchanged capsule signature"
	var role: Dictionary = saved.resolved_role
	if not Codec.is_number(owned.get("start_s")):
		return "Paired C30 start time required"
	var start_s: float = float(owned.start_s)
	var active_s: float = start_s + float(role.windup_s)
	var expected: Dictionary = {"lock_from_s": active_s - float(role.lock_s), "active_from_s": active_s, "active_until_s": active_s + float(role.active_s), "recovery_until_s": active_s + float(role.active_s) + float(role.recovery_s), "cooldown_until_s": active_s + float(role.attack_interval_s)}
	for key: String in expected:
		if not _same(owned.get(key), expected[key]):
			return "Paired C30 deadlines must retain the exact resolved role arithmetic"
	if paired.clock_s < start_s or paired.clock_s > expected.recovery_until_s or (not saved.hit_ids.is_empty() and paired.clock_s < active_s):
		return "C30 damage sample/dedupe cannot precede admission/activation or outlive recovery"
	var previous: Dictionary = {}
	for segment: Variant in saved.get("pending_segments", []):
		if not segment is Dictionary or not Codec.keys_error(segment, ["from", "to", "start_s", "end_s"]).is_empty() or not Codec.is_vector3(segment.from) or not Codec.is_vector3(segment.to) or not segment.start_s is float or not segment.end_s is float or not Codec.in_range(segment.start_s, start_s, float(paired.clock_s)) or not Codec.in_range(segment.end_s, float(segment.start_s), float(paired.clock_s)) or float(segment.end_s) - float(segment.start_s) > 1.0 / float(Engine.physics_ticks_per_second) + Geometry.EPSILON:
			return "Pending C30 path requires finite actual single-physics-tick relative samples"
		for key: String in ["from", "to"]:
			if not _same(Codec.vector3(Codec.read_vector3(segment[key])), segment[key]):
				return "Pending C30 path must retain exact native relative vectors without restore rounding"
		if segment.start_s == segment.end_s and not _same(segment.from, segment.to):
			return "A zero-time native sample cannot contain a swept relative jump"
		if not previous.is_empty() and (segment.start_s != previous.end_s or not _same(segment.from, previous.to)):
			return "Pending C30 path must preserve exact contiguous relative samples"
		previous = segment
	if not previous.is_empty():
		var relative: Vector3 = Codec.read_vector3(saved.sample.hero_position) - Codec.read_vector3(saved.sample.source_position)
		if previous.end_s != paired.clock_s or not _same(previous.to, Codec.vector3(relative)):
			return "Pending C30 path must end at the exact paired current relative position and clock"
	return ""


func _encode_sample() -> Dictionary:
	return {} if _sample.is_empty() else {"clock_s": _sample.clock_s, "source_position": Codec.vector3(_sample.source_position), "hero_position": Codec.vector3(_sample.hero_position)}


func _encode_public_record(record: Dictionary) -> Dictionary:
	# Commit cross-check uses actual public scheduler data. The root already
	# validated encounter custody, complete cooldown tables and world bindings.
	var result: Dictionary = {"id": record.id, "source_id": _configuration.source_id, "source_position": Codec.vector3(record.source_position), "adapter": record.adapter.duplicate(true)}
	for key: String in ["start", "planned_endpoint", "current_position", "current_velocity", "direction"]:
		result.adapter[key] = Codec.vector3(record.adapter[key])
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		result[key] = record[key]
	return result


func _live_collision_state() -> Dictionary:
	return {"collision_path": "BodyCollision", "enabled": true, "layer": 2, "mask": 1}


func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = ExactJson.stringify(left)
	return not encoded.is_empty() and encoded == ExactJson.stringify(right)


func _stable_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 128:
		return false
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9_./:-]+$")
	var found: RegExMatch = pattern.search(value)
	return found != null and found.get_string() == value


func _denied(reason: String) -> Dictionary:
	last_error = reason
	return {"accepted": false, "reason": reason}


func _reject(reason: String) -> bool:
	last_error = reason
	return false


func _build_greybox() -> void:
	_visual = Node3D.new()
	_visual.name = "TemporaryC30Presentation"
	add_child(_visual)
	_body = MeshInstance3D.new()
	_body.name = "StandingCrouchingBody"
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.25
	mesh.height = 1.15
	_body.mesh = mesh
	_body.visible = false
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.76, 0.78, 0.80)
	_body.material_override = material
	_visual.add_child(_body)
	_sprite_art = ArtScript.new()
	_sprite_art.name = "CostumePixels"
	_visual.add_child(_sprite_art)
	_draw_greybox()


func _draw_greybox() -> void:
	if not is_instance_valid(_body):
		return
	_visual.rotation.y = atan2(_facing.x, _facing.z)
	var crouch: bool = _phase in ["warning", "lock"]
	_body.scale = Vector3(1.0, 0.68 if crouch else 1.0, 1.0)
	_body.position.y = 0.48 if crouch else 0.75
	_body.rotation.x = 0.24 if _phase == "active" else 0.0
	(_body.material_override as StandardMaterial3D).albedo_color = Color(0.94, 0.91, 0.78) if _phase == "recovery" else Color(0.76, 0.78, 0.80)
	if is_instance_valid(_sprite_art):
		_sprite_art.call("set_pose", _phase, _facing, get_viewport().get_camera_3d())


func _exit_tree() -> void:
	if is_instance_valid(_scheduler):
		if _scheduler.reservation_invalidated.is_connected(_on_invalidated):
			_scheduler.reservation_invalidated.disconnect(_on_invalidated)
		_scheduler.cancel_owner(self, "rusher_removed")
