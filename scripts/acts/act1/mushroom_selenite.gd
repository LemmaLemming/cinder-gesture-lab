class_name Act1MushroomSelenite
extends CharacterBody3D
## C31 / A1-E2 and C32 / A1-E3 bounded greybox consumers. The shared scheduler
## owns attack deadlines, cooldowns, proof and C31 ground-lunge motion. Actor HP,
## hurt settling, sampled damage and presentation remain authored. C31 approach
## is explicitly opt-in. Genuine shared26 environmental motion is optional and
## belongs to the bound consumer/Route; there is no auto-cycle or second clock.
## Costume poses are clockless; new spore-specific pixels remain separate work.
## Capture/restore uses one exact Player+actor+Scheduler aggregate; an actor
## record is never converted into an AshEnemy envelope.

signal state_changed(actor_state: Dictionary)
signal defeated(source_id: String)
signal hit_resolved(hero_id: String, cycle: int, result: Dictionary)

const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const CueScript = preload("res://scripts/cues/threat_cue.gd")
const ArtScript = preload("res://scripts/acts/act1/mushroom_selenite_art.gd")
const NativeCodec = preload("res://scripts/acts/act1/mushroom_selenite_codec.gd")
const Approach = preload("res://scripts/acts/act1/mushroom_selenite_approach.gd")
const API_REVISION: String = "act1-mushroom-selenite-3"
const SNAPSHOT_SCHEMA_VERSION: int = 1
const PENDING_SNAPSHOT_SCHEMA_VERSION: int = 2
const BOUND_SNAPSHOT_SCHEMA_VERSION: int = 3
const BOUND_PENDING_SNAPSHOT_SCHEMA_VERSION: int = 4
const SPORE_ACTOR_REVISION: String = "scheduler-spore-actor-1"
const RepulsionRoute = preload("res://scripts/combat/repulsion_route.gd")
const SPORE_PHASES: Array[String] = ["none", "recoil", "turn", "retreat", "hold", "regroup", "interrupted", "failed"]
const MAX_PENDING_SEGMENTS: int = 256
const HERO_ID: String = "hero"
const GRAVITY: float = 24.0
const HURT_BRAKING: float = 5.0
const HURT_S: float = 0.22
const ROLE_SWARM: String = "A1-E2"
const ROLE_GUARD: String = "A1-E3"
const SWARM_RAW_ROLE: Dictionary = {"raw_damage": 6.0, "windup_s": 1.85, "lock_s": 0.85, "active_s": 0.4, "recovery_s": 1.8, "attack_interval_s": 2.0, "max_hp": 16.0, "move_speed": 4.0}
const GUARD_RAW_ROLE: Dictionary = {"raw_damage": 8.0, "windup_s": 1.85, "lock_s": 0.85, "active_s": 0.2, "recovery_s": 2.4, "attack_interval_s": 2.0, "max_hp": 24.0, "move_speed": 0.0}
const SWARM_LUNGE: Dictionary = {"speed": 4.0, "distance": 1.0, "damage_radius": 0.38, "body_collision_path": "BodyCollision"}
const GUARD_LANE: Dictionary = {"length": 2.0, "radius": 0.38}
const CONTEXT_KEYS: Array[String] = ["encounter_id", "world_revision", "recognition_s", "attack_input_margin_s", "escape_directions", "return_directions", "floor_regions", "world_root"]
const SNAPSHOT_KEYS: Array[String] = ["api_revision", "schema_version", "role_id", "source_id", "configuration", "hp", "dead", "dormant", "motion", "hurt_left_s", "approach_driving", "role_encounter_id", "profile_id", "resolved_role", "reservation_id", "cycle", "sample", "hit_ids", "last_cancel_reason"]

var hp: float = 16.0
var max_hp: float = 16.0
var dead: bool = false
var dormant: bool = false
## Parent grants this source only immediately after successful fresh begin_encounter.
## The pure callable receives source_id and must return literal true. Parent clears
## entitlement after every activation attempt; same-tick cancellation never grants it.
var activation_guard: Callable
## Pure renderer-owned admission/sampling guard; a nonempty reason cancels.
var presentation_guard: Callable
## Required for opt-in C31 movement. Pure callback receives a native proposal and
## returns a literal String. Parent guards full next/braking body/art/world/spacing
## from retained actual bindings and cached state, without pruning Scheduler calls.
## No environmental/source-control protocol is implied by this ordinary guard.
var approach_guard: Callable
var last_error: String = ""
var last_snapshot_error: String = ""
var _configuration: Dictionary = {}
var _native_codec: RefCounted = NativeCodec.new()
var _approach: RefCounted = Approach.new()
var _approach_driving: bool = false
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
# Only the actual bound consumer owns episode generation, progress and Route.
# Weak identity survives quiet reconstruction; never serialize object handles.
var _spore_consumer_ref: WeakRef
var _spore_consumer_id: String = ""
var _spore_episode_id: String = ""
var _spore_phase: String = "none"
var _spore_direction: Vector3 = Vector3.FORWARD
var _spore_progress: float = 0.0
var _spore_cancel_delivering: bool = false
var _spore_nested_damage_used: bool = false


func configure(role_id: String, source_id: String, initially_dormant: bool = true, approach_enabled: bool = false) -> bool:
	if is_instance_valid(_scheduler) or _transaction_depth > 0 or _snapshot_busy:
		return _reject("Configure immutable Mushroom Selenite data before binding")
	var selected: String = ROLE_SWARM if role_id in ["C31", ROLE_SWARM] else (ROLE_GUARD if role_id in ["C32", ROLE_GUARD] else "")
	if selected.is_empty() or not _stable_id(source_id):
		return _reject("Only canonical C31/A1-E2 or C32/A1-E3 and a stable source ID are supported")
	if approach_enabled and selected != ROLE_SWARM:
		return _reject("Only C31 can opt in to authored approach; C32 stays stationary")
	var approach: Dictionary = Approach.PROVISIONAL_TUNING.duplicate(true)
	approach.enabled = approach_enabled
	var raw: Dictionary = (SWARM_RAW_ROLE if selected == ROLE_SWARM else GUARD_RAW_ROLE).duplicate(true)
	var floors: Dictionary = {"windup_s": raw.windup_s, "lock_s": raw.lock_s, "recovery_s": raw.recovery_s}
	var difficulty = Difficulty.new()
	for profile_id: String in ["assisted", "standard", "challenge"]:
		var role: Dictionary = difficulty.resolve_role(raw, profile_id, floors)
		if role.is_empty(): return _reject(difficulty.last_error)
		if selected == ROLE_SWARM and float(SWARM_LUNGE.distance) / float(SWARM_LUNGE.speed) > float(role.active_s):
			return _reject("Canonical grounded hop must fit its complete native active window")
	var next: Dictionary = {"role_id": selected, "entity_id": "C31" if selected == ROLE_SWARM else "C32", "source_id": source_id, "raw_role": raw, "timing_floors": floors, "lunge": SWARM_LUNGE.duplicate(true) if selected == ROLE_SWARM else {}, "lane": GUARD_LANE.duplicate(true) if selected == ROLE_GUARD else {}, "initially_dormant": initially_dormant, "approach": approach}
	if not _configuration.is_empty():
		if not _same(next, _configuration): return _reject("Configured role identity and provisional tuning are immutable")
		last_error = ""
		return true
	_configuration = next
	max_hp = float(raw.max_hp)
	hp = max_hp
	dormant = initially_dormant
	_approach_driving = false
	if is_node_ready(): _apply_lifecycle_flags()
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
		return _reject("Bind a ready configured C31/C32 outside callbacks")
	if not is_instance_valid(scheduler) or not scheduler.is_inside_tree() or scheduler.get_world_3d() != get_world_3d() or scheduler.process_physics_priority >= process_physics_priority or not is_instance_valid(hero) or not hero.is_inside_tree() or hero.is_queued_for_deletion() or hero.get_world_3d() != get_world_3d() or hero.process_physics_priority >= process_physics_priority:
		return _reject("Same-world earlier-physics scheduler and actual shared hero required")
	if is_instance_valid(_scheduler):
		return true if _scheduler == scheduler and _hero == hero else _reject("C31/C32 scheduler and hero bindings are immutable")
	_scheduler = scheduler
	_hero = hero
	_scheduler.reservation_invalidated.connect(_on_invalidated)
	last_error = ""
	return true


## context has exactly CONTEXT_KEYS, including the actual common world_root.
## Target selects a continuous planar direction; distance is canonical role data.
## This pure preview grants no lease, cycle, role/profile assignment or movement.
func preview_start(target: Vector3, context: Dictionary) -> Dictionary:
	var direction: Vector3 = _target_direction(target)
	var prepared: Dictionary = _prepare_start(context, direction, context.get("world_root") as Node3D)
	if not prepared.get("accepted", false): return prepared
	return _scheduler.preview_lunge(self, prepared.threat, prepared.response) if _configuration.role_id == ROLE_SWARM else _scheduler.preview_stationary(self, prepared.threat, prepared.response)


func start(target: Vector3, context: Dictionary, preview: Dictionary = {}) -> Dictionary:
	var direction: Vector3 = _target_direction(target)
	var prepared: Dictionary = _prepare_start(context, direction, context.get("world_root") as Node3D)
	if not prepared.get("accepted", false): return _denied(String(prepared.reason))
	# Require a complete fresh native correspondence even when the caller has
	# no copied preview. The explicit root supports actual custody/framing data.
	var selected: Dictionary = preview
	if selected.is_empty():
		selected = _scheduler.preview_lunge(self, prepared.threat, prepared.response) if _configuration.role_id == ROLE_SWARM else _scheduler.preview_stationary(self, prepared.threat, prepared.response)
	if not selected.get("accepted", false): return _denied(String(selected.get("reason", "Native admission preview rejected")))
	_transaction_depth += 1
	var answer: Dictionary = _scheduler.request_lunge(self, prepared.threat, prepared.response, selected) if _configuration.role_id == ROLE_SWARM else _scheduler.request_attack(self, prepared.threat, prepared.response, selected)
	if answer.get("accepted", false):
		_reservation_id = String(answer.reservation_id)
		_role_encounter_id = context.encounter_id
		_profile_id = String(prepared.profile_id)
		_resolved_role = prepared.role.duplicate(true)
		_cycle += 1
		# Opt-in direction is already the stopped aligned native facing. The
		# default component path retains its original target-facing behavior.
		_facing = direction
		_approach_driving = false
		_hit_ids.clear()
		_pending_segments.clear()
		_sample_now()
		_last_cancel_reason = ""
		_present(_scheduler.reservation_state(_reservation_id))
	else:
		last_error = String(answer.get("reason", "Native attack rejected"))
	_transaction_depth -= 1
	return answer.duplicate(true)


func _target_direction(target: Vector3) -> Vector3:
	if not target.is_finite(): return Vector3.ZERO
	var delta: Vector3 = target - global_position
	var planar := Vector3(delta.x, 0.0, delta.z)
	if not planar.is_finite() or planar.length() <= Motion.EPSILON: return Vector3.ZERO
	var direction: Vector3 = planar.normalized()
	if _configuration.get("approach", {}).get("enabled", false):
		# Reuse the actual gradual heading; admission cannot snap it to a target.
		return _facing if direction.distance_to(_facing) <= Motion.EPSILON else Vector3.ZERO
	return direction


func _prepare_start(response_context: Dictionary, direction: Vector3, world_root: Node3D) -> Dictionary:
	if not _live_bindings() or _transaction_depth > 0 or _snapshot_busy or _cancelling or dead or dormant or get_tree().paused or not _reservation_id.is_empty() or _hurt_left_s > 0.0 or velocity != Vector3.ZERO or _approach_driving or not is_visible_in_tree() or _cycle >= Codec.MAX_SAFE_INTEGER:
		return {"accepted": false, "reason": "Start requires an activated live stopped unpaused idle C31/C32 outside callbacks"}
	if not Codec.keys_error(response_context, CONTEXT_KEYS).is_empty() or not _stable_id(response_context.get("encounter_id")) or not Geometry.finite_vector(direction) or absf(direction.y) > Motion.EPSILON or absf(direction.length() - 1.0) > Motion.EPSILON:
		return {"accepted": false, "reason": "Authored encounter context and fixed normalized world direction required"}
	if not is_instance_valid(world_root) or not world_root.is_inside_tree() or world_root.is_queued_for_deletion() or world_root.get_world_3d() != get_world_3d() or not world_root.is_ancestor_of(self) or not world_root.is_ancestor_of(_hero) or not world_root.is_ancestor_of(_scheduler):
		return {"accepted": false, "reason": "Actual containing same-world root must retain actor, hero and scheduler"}
	var guard_error: String = _spore_fresh_error()
	if guard_error.is_empty():
		guard_error = _retained_body_error()
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
		if key not in ["encounter_id", "world_root"]:
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
	var threat: Dictionary
	if _configuration.role_id == ROLE_SWARM:
		var lunge: Dictionary = _configuration.lunge.duplicate(true)
		lunge["direction"] = direction
		threat = {"role": role, "source_stationary": false, "opening_stationary": true, "cooldown_remaining_s": 0.0, "lunge": lunge}
	else:
		var lane: Dictionary = Geometry.lane(global_position, global_position + direction * float(_configuration.lane.length), float(_configuration.lane.radius))
		threat = {"role": role, "source_stationary": true, "opening_stationary": true, "cooldown_remaining_s": 0.0, "geometry": lane, "opening_position": global_position}
	return {"accepted": true, "threat": threat, "response": response, "role": role, "profile_id": profile_id}


func take_damage(amount: float, impulse: Vector3) -> Dictionary:
	var result: Dictionary = {"accepted": false, "hp_damage": 0.0, "target_id": get_instance_id(), "target_alive_before_hit": hp > 0.0 and not dead and not dormant and not is_queued_for_deletion()}
	# Exactly ONE real injury may arrive from the native spore-cancel delivery.
	# No phase/hit/snapshot/general recursive damage boundary is relaxed.
	var nested: bool = _transaction_depth == 1 and _cancelling and _spore_cancel_delivering and not _spore_nested_damage_used
	if not _live_bindings() or _snapshot_busy or (_transaction_depth > 0 and not nested) or not result.target_alive_before_hit or not is_finite(amount) or amount <= 0.0 or not impulse.is_finite():
		return result
	if nested: _spore_nested_damage_used = true
	_transaction_depth += 1
	# Outer native cancellation already cleared this exchange before observers.
	# Recursively cancelling it would destroy the bounded injury delivery order.
	if nested:
		_last_cancel_reason = "actual_player_damage"
	else:
		cancel("actual_player_damage")
	_approach_driving = false
	var before: float = hp
	hp = maxf(0.0, hp - amount)
	result.accepted = true
	result.hp_damage = before - hp
	if hp == 0.0:
		dead = true
		_hurt_left_s = 0.0
		velocity = Vector3.ZERO
		_spore_episode_id = ""
		_spore_phase = "none"
		_spore_progress = 0.0
		_scheduler.cancel_owner(self, "source_defeated")
		collision_layer = 0
		collision_mask = 0
		# Immediate genuine death state is needed by the synchronous native
		# protocol post-callback lifecycle proof, before defeat observers.
		_collision.disabled = true
		remove_from_group("enemies")
		visible = false
	else:
		velocity += impulse
		_hurt_left_s = HURT_S
		if not _spore_episode_id.is_empty():
			_spore_phase = "interrupted"
			_spore_progress = 0.0
	# Real HP/impulse/hurt and the stamp precede Route release and all defeat/
	# state observers. Native release never overwrites an external impulse.
	var consumer: CinderSporeRepulsion = _spore_consumer()
	if consumer != null:
		consumer.source_interrupted(self, "actual_death" if dead else "actual_damage")
	if dead:
		defeated.emit(String(_configuration.source_id))
	state_changed.emit(state())
	_transaction_depth -= 1
	return result


func cancel(reason: String = "mushroom_selenite_cancelled") -> bool:
	if _snapshot_busy or _cancelling:
		return false
	_approach_driving = false
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
	var result: Dictionary = {"api_revision": API_REVISION, "role_id": _configuration.get("role_id", ""), "entity_id": _configuration.get("entity_id", ""), "spore_support": not _spore_consumer_id.is_empty(), "presentation_status": "authored_C31_C32_pose_pixels", "source_id": _configuration.get("source_id", ""), "hp": hp, "dead": dead, "dormant": dormant, "status": status, "phase": phase, "reservation_id": _reservation_id, "cycle": _cycle, "source_position": global_position, "opening_position": record.get("opening_position", global_position), "geometry": record.get("geometry", {}).duplicate(true), "resolved_role": _resolved_role.duplicate(true), "hit_ids": _hit_ids.duplicate(), "hurt_left_s": _hurt_left_s, "approach_enabled": _configuration.get("approach", {}).get("enabled", false), "approach_driving": _approach_driving, "velocity": velocity, "facing": _facing, "last_cancel_reason": _last_cancel_reason}
	if not _spore_consumer_id.is_empty():
		result["repulsion"] = _encode_repulsion()
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "armed", "adapter"]:
		if record.has(key):
			result[key] = record[key].duplicate(true) if record[key] is Dictionary else record[key]
	return result


## Pure retained native binding, deliberately distinct from state() which prunes.
func get_spore_native_bindings() -> Dictionary:
	if not _live_bindings() or not _retained_body_error().is_empty(): return {}
	return {"api_revision": SPORE_ACTOR_REVISION, "actor_revision": API_REVISION, "source_id": _configuration.source_id, "scheduler": _scheduler, "player": _hero, "codec": _native_codec, "configuration": _configuration.duplicate(true)}


## Common live response has no Scheduler reservation/cooldown query or callback.
## Dead retained bodies stay available for genuine defeat/tombstone validation.
func get_spore_response_state() -> Dictionary:
	if not _live_bindings() or not _retained_body_error().is_empty() or not _lifecycle_error().is_empty(): return {}
	var direction: Vector3 = _facing if _spore_consumer_id.is_empty() else _spore_direction
	return {"api_revision": SPORE_ACTOR_REVISION, "source_id": _configuration.source_id, "consumer_id": _spore_consumer_id, "alive": not dead and not dormant, "grounded": _grounded(), "position": global_position, "velocity": velocity, "facing": _facing, "hurt_remaining_s": _hurt_left_s, "body_collision_path": "BodyCollision", "support_radius": float(_retained_capsule.radius) + RepulsionRoute.FLOOR_SKIN, "height": float(_retained_capsule.height), "episode_id": _spore_episode_id, "phase": _spore_phase, "direction": direction, "progress": _spore_progress, "outside_transaction": _transaction_depth == 0 and not _snapshot_busy and not _cancelling}


func spore_bind_error(consumer: Node, source_id: String) -> String:
	if not _live_bindings() or dead or dormant or _transaction_depth > 0 or _snapshot_busy or _cancelling or source_id != _configuration.source_id:
		return "Bind a living actual C31/C32 outside actor callbacks"
	var actual: CinderSporeRepulsion = consumer as CinderSporeRepulsion
	if not is_instance_valid(actual) or not actual.is_inside_tree() or actual.is_queued_for_deletion() or actual.get_world_3d() != get_world_3d() or not _stable_id(actual.consumer_id()) or not actual.source_binding_matches(self, source_id):
		return "Actual same-world consumer must already stage this permanent source"
	var error: String = _retained_body_error()
	if error.is_empty(): error = _lifecycle_error()
	if not error.is_empty(): return error
	var control: Dictionary = _scheduler.source_control_state(self)
	if control.is_empty() or not control.get("outside_transaction", false):
		return "Bind outside the actual Scheduler transaction"
	if not _spore_consumer_id.is_empty():
		return "" if _spore_consumer() == consumer and _spore_consumer_id == actual.consumer_id() else "Environmental consumer identity is immutable"
	if not _spore_episode_id.is_empty() or _spore_phase != "none":
		return "Fresh unbound source cannot carry an environmental episode"
	return ""


## Silent one-shot commit after parent/protocol pairwise prevalidation.
func bind_spore_repulsion(consumer: Node, source_id: String) -> bool:
	var error: String = spore_bind_error(consumer, source_id)
	if not error.is_empty(): return _reject(error)
	if not _spore_consumer_id.is_empty(): return true
	_spore_consumer_ref = weakref(consumer)
	_spore_consumer_id = (consumer as CinderSporeRepulsion).consumer_id()
	_spore_direction = _facing
	return true


func cancel_attack_for_spores(consumer: Node, episode_id: String, direction: Vector3) -> bool:
	var error: String = _spore_hook_error(consumer, episode_id)
	if not error.is_empty() or get_tree().paused or not _spore_episode_id.is_empty() or _hurt_left_s != 0.0 or not _grounded() or absf(velocity.y) > Motion.EPSILON or not _unit_direction(direction):
		return _reject(error if not error.is_empty() else "Environmental cancellation requires an unharmed grounded fresh source")
	var record: Dictionary = (consumer as CinderSporeRepulsion).source_state(String(_configuration.source_id))
	var control: Dictionary = _scheduler.source_control_state(self)
	if record.get("episode_id") != episode_id or record.get("phase") != "recoil" or not record.get("direction") is Vector3 or not _same(Codec.vector3(record.direction), Codec.vector3(direction)) or record.get("progress") != 0.0 or control.is_empty() or not control.get("outside_transaction", false):
		return _reject("Actual consumer must publish its exact prepared recoil before native cancellation")
	# Stamp and suppression precede every synchronous native cancellation/cue
	# observer. Leave original approach velocity until real Route.acquire; only
	# the Scheduler may stop an owned lunge while cancelling its exact lease.
	_spore_episode_id = episode_id
	_spore_phase = "recoil"
	_spore_direction = direction
	_spore_progress = 0.0
	_approach_driving = false
	_spore_cancel_delivering = true
	_spore_nested_damage_used = false
	var accepted: bool = cancel("spore_repulsion")
	_spore_cancel_delivering = false
	return accepted


func present_spore_phase(consumer: Node, episode_id: String, phase: String, progress: float) -> bool:
	var error: String = _spore_hook_error(consumer, episode_id)
	if not error.is_empty() or episode_id != _spore_episode_id or phase == "none" or phase not in SPORE_PHASES or not is_finite(progress) or progress < 0.0 or progress > 1.0:
		return false
	var record: Dictionary = (consumer as CinderSporeRepulsion).source_state(String(_configuration.source_id))
	if record.get("episode_id") != episode_id or record.get("phase") != phase or not _same(record.get("progress"), progress) or not record.get("direction") is Vector3 or not _same(Codec.vector3(record.direction), Codec.vector3(_spore_direction)):
		return false
	# Existing facing follows authoritative turn progress without a turn timer
	# or serialized origin. It changes only the art/facing vector, never basis.
	if phase == "turn":
		var prior: float = _spore_progress if _spore_phase == "turn" else 0.0
		if progress < prior: return false
		var fraction: float = (progress - prior) / (1.0 - prior) if prior < 1.0 else 0.0
		_facing = _facing.rotated(Vector3.UP, _facing.signed_angle_to(_spore_direction, Vector3.UP) * fraction).normalized()
	elif phase in ["retreat", "hold", "regroup"]:
		_facing = _spore_direction
	_spore_phase = phase
	_spore_progress = progress
	_draw_greybox()
	return true


func resume_spore_retreat(consumer: Node, episode_id: String, direction: Vector3) -> bool:
	var error: String = _spore_hook_error(consumer, episode_id)
	if not error.is_empty() or get_tree().paused or episode_id != _spore_episode_id or _spore_phase != "interrupted" or _hurt_left_s != 0.0 or not _grounded() or velocity != Vector3.ZERO or not _reservation_id.is_empty() or not _unit_direction(direction): return false
	var record: Dictionary = (consumer as CinderSporeRepulsion).source_state(String(_configuration.source_id))
	var control: Dictionary = _scheduler.source_control_state(self)
	if record.get("episode_id") != episode_id or record.get("phase") != "interrupted" or control.is_empty() or not control.get("outside_transaction", false) or not control.reservations.is_empty(): return false
	# Shared consumer assigns the continued direction AFTER actual acquisition.
	# Do not compare this new prepared direction with its previous record value.
	_spore_direction = direction
	_spore_phase = "retreat"
	_spore_progress = 0.0
	_approach_driving = false
	return true


func finish_spore_episode(consumer: Node, episode_id: String) -> bool:
	var error: String = _spore_hook_error(consumer, episode_id)
	if not error.is_empty() or episode_id != _spore_episode_id or _spore_phase != "regroup" or _hurt_left_s != 0.0 or velocity != Vector3.ZERO or not _reservation_id.is_empty(): return false
	var record: Dictionary = (consumer as CinderSporeRepulsion).source_state(String(_configuration.source_id))
	if record.get("episode_id") != episode_id or record.get("phase") != "regroup": return false
	_spore_episode_id = ""
	_spore_phase = "none"
	_spore_progress = 0.0
	# Retain consumer, HP/profile/cooldown and unit direction. No fresh admission.
	return true


func get_cue() -> CinderThreatCue:
	return _cue


func get_art() -> Node3D:
	return _sprite_art


## Pure actual body/resource/lifecycle check for the parent's neighbor queries.
## No Scheduler accessor, callbacks, pose changes or motion permission.
func body_binding_error() -> String:
	var error: String = _retained_body_error()
	return _lifecycle_error() if error.is_empty() else error


func art_binding_error() -> String:
	# The billboard must remain at this real actor's feet. An inherited hidden
	# parent cannot be excused by the sprite's own local visible flag.
	if not is_instance_valid(_visual) or not _visual.is_inside_tree() or _visual.is_queued_for_deletion() or _visual.get_parent() != self or _visual.is_set_as_top_level() or not _visual.visible:
		return "C31/C32 requires its visible retained actor presentation parent"
	if _visual.position != Vector3.ZERO or _visual.scale != Vector3.ONE or _visual.rotation.x != 0.0 or _visual.rotation.z != 0.0 or not is_finite(_visual.rotation.y):
		return "C31/C32 presentation must retain its unscaled foot origin and planar facing"
	if not is_instance_valid(_sprite_art) or not _sprite_art.is_inside_tree() or _sprite_art.is_queued_for_deletion() or _sprite_art.get_parent() != _visual or not _sprite_art.visible:
		return "C31/C32 requires its retained pixel presentation"
	var error: String = String(_sprite_art.call("binding_error"))
	if not error.is_empty(): return error
	var pose: String = "standing" if _phase in ["clear", "idle"] else _phase
	if String(_sprite_art.call("role_id")) != String(_configuration.role_id) or String(_sprite_art.call("pose_name")) != pose:
		return "C31/C32 costume must match its actual immutable role and presented native phase"
	return ""


func _physics_process(delta: float) -> void:
	if dead or dormant or not _live_bindings() or get_tree().paused or _transaction_depth > 0:
		return
	# Genuine coordinator step MUST precede this actor's ordinary transaction.
	# Route owns held motion; false permits only native hurt/airborne settlement
	# during an episode, never a second pursuit or new attack controller.
	var consumer: CinderSporeRepulsion = _spore_consumer()
	if not _spore_consumer_id.is_empty():
		if consumer == null:
			last_error = "Retained environmental consumer disappeared; fresh motion is suppressed"
			if _hurt_left_s <= 0.0 and _grounded() and velocity == Vector3.ZERO: return
		elif consumer.step_source(self, delta):
			return
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
		var was_hurt: bool = _hurt_left_s > 0.0
		_hurt_left_s = maxf(0.0, _hurt_left_s - delta)
		var horizontal := Vector3(velocity.x, 0.0, velocity.z)
		# A native impulse can outlive its .22s hurt clock. Never reinterpret that
		# residual velocity as approach-owned: settle to exact zero first.
		if _configuration.approach.enabled and _spore_fresh_error().is_empty() and not was_hurt and (_approach_driving or horizontal == Vector3.ZERO) and _grounded() and velocity.y == 0.0:
			_step_approach(delta)
			_transaction_depth -= 1
			return
		_approach_driving = false
		# Original authored hurt/gravity settling, including default components.
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


## Pure forecast only. No guard callback, motion, state/event or Scheduler query.
## Root must separately guard the actual complete body/art/world/neighbor unit.
func propose_approach(target: Vector3, delta: float) -> Dictionary:
	var error: String = _approach_idle_error(false)
	if not error.is_empty(): return {"accepted": false, "error": error, "reason": "actor_not_ready"}
	return _approach.plan(global_position, velocity, _facing, target, delta, _configuration.approach)


func _approach_idle_error(inside_physics: bool) -> String:
	if not _live_bindings() or _snapshot_busy or _cancelling or (not inside_physics and _transaction_depth > 0) or dead or dormant or _hero.dead or get_tree().paused:
		return "Approach requires its live unpaused activated source/Player outside callbacks"
	var environmental_error: String = _spore_fresh_error()
	if not environmental_error.is_empty(): return environmental_error
	if _configuration.role_id != ROLE_SWARM or not _configuration.approach.enabled or not _reservation_id.is_empty() or not _sample.is_empty() or not _pending_segments.is_empty() or not _hit_ids.is_empty() or _hurt_left_s != 0.0:
		return "Only opt-in idle C31 without a native lease/sample/held delivery can approach"
	if not _grounded() or velocity.y != 0.0 or (not _approach_driving and Vector3(velocity.x, 0.0, velocity.z) != Vector3.ZERO):
		return "Approach cannot own airborne motion or residual native hurt/impulse"
	var error: String = _retained_body_error()
	if error.is_empty(): error = _lifecycle_error()
	if error.is_empty(): error = art_binding_error()
	return error


func _movement_error(plan: Dictionary) -> String:
	var consumer: CinderSporeRepulsion = _spore_consumer()
	if not _spore_consumer_id.is_empty():
		if consumer == null: return "Actual environmental consumer binding is unavailable"
		var motion: Vector3 = plan.next_position - global_position
		if not consumer.allows_source_step(self, global_position, motion):
			return "Actual active field forbids this source's approach reentry"
	if not approach_guard.is_valid(): return "Opt-in approach requires its parent's actual motion/framing guard"
	var result: Variant = approach_guard.call(plan.duplicate(true))
	return result if result is String else "Approach movement guard must return a literal String"


func _step_approach(delta: float) -> void:
	var error: String = _approach_idle_error(true)
	if not error.is_empty():
		last_error = error
		return
	var origin: Vector3 = global_position
	var original_velocity: Vector3 = velocity
	var original_facing: Vector3 = _facing
	var target: Vector3 = _hero.global_position
	var hp_before: float = hp
	var driving_before: bool = _approach_driving
	var plan: Dictionary = _approach.plan(origin, original_velocity, original_facing, target, delta, _configuration.approach)
	if not plan.get("accepted", false):
		last_error = String(plan.get("error", "Approach proposal rejected"))
		return
	plan["delta_s"] = delta
	error = _movement_error(plan)
	var boundary_error: String = _approach_idle_error(true)
	if not boundary_error.is_empty():
		last_error = boundary_error
		return
	if not error.is_empty():
		# A guard may suppress pursuit. Braking remains finite owned motion and
		# must receive its own complete native world/body/art/spacing approval.
		var disabled: Dictionary = _configuration.approach.duplicate(true)
		disabled.enabled = false
		plan = _approach.plan(origin, original_velocity, original_facing, target, delta, disabled)
		if plan.get("accepted", false):
			plan["delta_s"] = delta
			error = _movement_error(plan)
		else: error = String(plan.get("error", "Approach braking rejected"))
	var current_error: String = _approach_idle_error(true)
	if not current_error.is_empty(): error = current_error
	if global_position != origin or velocity != original_velocity or _facing != original_facing or _hero.global_position != target or hp != hp_before or _approach_driving != driving_before:
		error = "Pure movement guard changed the actual source/Player boundary"
	if not error.is_empty():
		# Reject unsafe motion without manufacturing a stop or discarding actual
		# velocity. Parent owns persistent unavailable-world cancellation/teardown.
		last_error = error
		return
	velocity = plan.velocity
	_facing = plan.facing
	_approach_driving = plan.driving
	move_and_slide()
	_restored_floor_contact = -1
	# Native collision can shorten/stop a proposal; retain actual ownership only.
	_approach_driving = Vector3(velocity.x, 0.0, velocity.z) != Vector3.ZERO and _grounded() and velocity.y == 0.0
	_draw_greybox()
	last_error = ""


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
		var shape: Dictionary = Geometry.circle(Vector3.ZERO, float(current.adapter.damage_radius)) if _configuration.role_id == ROLE_SWARM else Geometry.lane(Vector3.ZERO, _facing * float(_configuration.lane.length), float(_configuration.lane.radius))
		if Geometry.timed_path_hits(shape, [segment], float(current.active_from_s), float(current.active_until_s), CinderThreatScheduler.CAPSULE_RADIUS):
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
	if latest != record or int(record.get("source_instance_id", 0)) != get_instance_id() or record.get("source_position") != global_position or (record.get("adapter", {}).get("current_velocity") != velocity if _configuration.role_id == ROLE_SWARM else velocity != Vector3.ZERO) or not _required_cue_available(record, current_source_marker) or get_tree().paused:
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
	return result if result is String else "C31/C32 presentation guard must return a String"


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
		return "Retained actual C31/C32 capsule node/resource identity changed"
	if global_basis != Basis.IDENTITY or not global_position.is_finite() or not velocity.is_finite() or not get_collision_exceptions().is_empty() or not get_platform_velocity().is_zero_approx() or not get_platform_angular_velocity().is_zero_approx():
		return "Retained C31/C32 requires its upright finite fixed-world native body"
	var collider_count: int = 0
	for child: Node in get_children():
		if child is CollisionShape3D or child is CollisionPolygon3D:
			collider_count += 1
	var owners: PackedInt32Array = get_shape_owners()
	if collider_count != 1 or owners.size() != 1 or _read_native_body_properties() != _native_body_properties:
		return "Retained C31/C32 native capsule/body properties or registrations changed"
	var shape_owner_id: int = owners[0]
	if shape_owner_get_owner(shape_owner_id) != _collision or shape_owner_get_shape_count(shape_owner_id) != 1 or shape_owner_get_shape(shape_owner_id, 0) != _retained_capsule or shape_owner_get_transform(shape_owner_id) != _collision.transform or is_shape_owner_disabled(shape_owner_id) != _collision.disabled:
		return "Retained C31/C32 registered footprint differs from its actual capsule"
	return ""


func _lifecycle_error() -> String:
	var inactive: bool = dead or dormant
	if max_hp != float(_configuration.raw_role.max_hp) or not is_finite(hp) or hp < 0.0 or hp > max_hp or dead != (hp == 0.0):
		return "Actual C31/C32 HP/death disagrees with immutable role"
	if _collision.disabled != inactive or collision_layer != (0 if inactive else 2) or collision_mask != (0 if inactive else 1) or is_in_group("enemies") == inactive or visible == inactive:
		return "Actual C31/C32 lifecycle flags/group/visibility disagree with HP/dormancy"
	if not inactive and not is_visible_in_tree():
		return "Living C31/C32 cannot remain under an inherited hidden parent"
	if dormant:
		return _dormant_state_error()
	return ""


func _dormant_state_error() -> String:
	if not _configuration.get("initially_dormant", false) or dead or hp != max_hp or velocity != Vector3.ZERO or _hurt_left_s != 0.0 or _approach_driving or _cycle != 0 or _phase != "clear" or not _role_encounter_id.is_empty() or not _profile_id.is_empty() or not _resolved_role.is_empty() or not _reservation_id.is_empty() or not _sample.is_empty() or not _pending_segments.is_empty() or not _hit_ids.is_empty() or not _last_cancel_reason.is_empty():
		return "Dormant C31/C32 must retain pristine HP and no motion/combat history"
	if is_instance_valid(_cue) and _cue.state().phase != "clear":
		return "Dormant C31/C32 cannot hide a required hazard cue"
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


func _spore_consumer() -> CinderSporeRepulsion:
	var value: Variant = _spore_consumer_ref.get_ref() if _spore_consumer_ref != null else null
	if not is_instance_valid(value) or not value is CinderSporeRepulsion or not value.is_inside_tree() or value.is_queued_for_deletion() or value.get_world_3d() != get_world_3d(): return null
	return value as CinderSporeRepulsion


func _spore_binding_error() -> String:
	if _spore_consumer_id.is_empty(): return ""
	var consumer: CinderSporeRepulsion = _spore_consumer()
	if consumer == null or consumer.consumer_id() != _spore_consumer_id or not consumer.source_binding_matches(self, String(_configuration.source_id)):
		return "Retain the actual immutable environmental consumer/source binding"
	return ""


func _spore_fresh_error() -> String:
	if not _spore_episode_id.is_empty(): return "Actual environmental episode suppresses fresh attack/approach"
	var error: String = _spore_binding_error()
	if not error.is_empty(): return error
	if not _spore_consumer_id.is_empty() and not _spore_consumer().placement_accepted():
		return "Actual environmental custody rejection suppresses fresh attack/approach"
	return ""


func _spore_hook_error(consumer: Node, episode_id: String) -> String:
	if not _live_bindings() or dead or dormant or _transaction_depth > 0 or _snapshot_busy or _cancelling:
		return "Environmental hook requires a living actual source outside actor callbacks"
	var error: String = _spore_binding_error()
	if not error.is_empty(): return error
	if _spore_consumer_id.is_empty() or _spore_consumer() != consumer or not _stable_id(episode_id) or not episode_id.begins_with(_spore_consumer_id + "/episode-"):
		return "Environmental hook must name the retained consumer's genuine episode"
	return ""


func _unit_direction(value: Vector3) -> bool:
	return value.is_finite() and absf(value.y) <= Motion.EPSILON and absf(value.length() - 1.0) <= Motion.EPSILON


func _encode_repulsion() -> Dictionary:
	return {"api_revision": SPORE_ACTOR_REVISION, "consumer_id": _spore_consumer_id, "source_id": _configuration.source_id, "episode_id": _spore_episode_id, "phase": _spore_phase, "direction": Codec.vector3(_spore_direction), "progress": _spore_progress}


func _snapshot_access_error() -> String:
	var art_error: String = art_binding_error()
	if not art_error.is_empty():
		return art_error
	if not _live_bindings() or not get_tree().paused or is_queued_for_deletion():
		return "C31/C32 snapshots require retained ready bindings at the paused deferred barrier"
	if _transaction_depth > 0 or _snapshot_busy or _cancelling:
		return "C31/C32 snapshots cannot run inside actor/phase/hit/cancellation callbacks"
	# Pure identity only: querying the coordinator's snapshot validator here
	# would recurse while it is validating this same complete native actor unit.
	var environmental_error: String = _spore_binding_error()
	if not environmental_error.is_empty(): return environmental_error
	var retained_error: String = _retained_body_error()
	if not retained_error.is_empty():
		return retained_error
	var description: Dictionary = Motion.staged_source_description(self, _live_collision_state())
	if description.has("error") or not _same(description.get("signature", {}), _body_signature):
		return "Actual retained C31/C32 capsule/registration/transform no longer matches its immutable body"
	if global_basis != Basis.IDENTITY or not global_position.is_finite() or not velocity.is_finite():
		return "Actual C31/C32 motion must retain its upright finite body frame"
	return ""


func capture_state(paired_scheduler: Dictionary) -> Dictionary:
	return _capture_state(paired_scheduler, {})


## Complete paired writer; helper never reconstructs a native actor envelope.
func spore_snapshot_state(paired_scheduler: Dictionary, saved_player: Dictionary) -> Dictionary:
	if saved_player.is_empty():
		last_snapshot_error = "Complete actual paired Player required by environmental native capture"
		return {}
	return _capture_state(paired_scheduler, saved_player)


func _capture_state(paired_scheduler: Dictionary, supplied_player: Dictionary) -> Dictionary:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty():
		return {}
	var current_player: Dictionary = _hero.snapshot_state()
	if current_player.is_empty() or (not supplied_player.is_empty() and not _same(current_player, supplied_player)):
		last_snapshot_error = "Captured actor must use the exact actual paused Player unit"
		return {}
	_snapshot_busy = true
	var saved: Dictionary = {"api_revision": API_REVISION, "schema_version": SNAPSHOT_SCHEMA_VERSION, "role_id": _configuration.role_id, "source_id": _configuration.source_id, "configuration": _configuration.duplicate(true), "hp": hp, "dead": dead, "dormant": dormant, "motion": {"position": Codec.vector3(global_position), "velocity": Codec.vector3(velocity), "facing": Codec.vector3(_facing), "grounded": _grounded()}, "hurt_left_s": _hurt_left_s, "approach_driving": _approach_driving, "role_encounter_id": _role_encounter_id, "profile_id": _profile_id, "resolved_role": _resolved_role.duplicate(true), "reservation_id": _reservation_id, "cycle": _cycle, "sample": _encode_sample(), "hit_ids": _hit_ids.duplicate(), "last_cancel_reason": _last_cancel_reason}
	if not _pending_segments.is_empty():
		saved["schema_version"] = PENDING_SNAPSHOT_SCHEMA_VERSION
		saved["pending_segments"] = []
		for segment: Dictionary in _pending_segments:
			saved.pending_segments.append({"from": Codec.vector3(segment.from), "to": Codec.vector3(segment.to), "start_s": segment.start_s, "end_s": segment.end_s})
	if not _spore_consumer_id.is_empty():
		saved["schema_version"] = BOUND_PENDING_SNAPSHOT_SCHEMA_VERSION if not _pending_segments.is_empty() else BOUND_SNAPSHOT_SCHEMA_VERSION
		saved["repulsion"] = _encode_repulsion()
	last_snapshot_error = _actor_error(saved, paired_scheduler, current_player)
	if last_snapshot_error.is_empty():
		last_snapshot_error = _lifecycle_error()
	_snapshot_busy = false
	return saved if last_snapshot_error.is_empty() else {}


func snapshot_error(saved: Dictionary, paired_scheduler: Dictionary, saved_player: Dictionary) -> String:
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
	_approach_driving = saved.approach_driving
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
	if hp != saved.hp or dead != saved.dead or dormant != saved.dormant or _hurt_left_s != saved.hurt_left_s or _approach_driving != saved.approach_driving or not _same(Codec.vector3(_facing), saved.motion.facing) or not _same(Codec.vector3(global_position), saved.motion.position) or not _same(Codec.vector3(velocity), saved.motion.velocity) or _collision.disabled != inactive or collision_layer != (0 if inactive else 2) or collision_mask != (0 if inactive else 1) or is_in_group("enemies") == inactive or visible == inactive:
		last_snapshot_error = "Apply the exact validated actual C31/C32 lifecycle/motion before exchange commit"
		return false
	# Quiet actual source-control read: no pruning, cancellation, clocks or cue
	# callbacks are permitted between the aggregate's physical/native commits.
	var control: Dictionary = _scheduler.source_control_state(self)
	if control.is_empty() or not control.get("outside_transaction", false):
		last_snapshot_error = "Actual restored Scheduler must be outside its native transaction"
		return false
	if inactive and control.cooldown != null:
		last_snapshot_error = "Actual inactive C31/C32 cannot retain its native owner cooldown"
		return false
	var records: Array = control.reservations
	var record: Dictionary = records[0] if records.size() == 1 else {}
	if not saved.reservation_id.is_empty():
		if record.is_empty() or record.get("id") != saved.reservation_id or int(record.source_instance_id) != get_instance_id() or control.clock_s != saved.sample.clock_s or not _same(Codec.vector3(record.source_position), saved.motion.position) or not _same(Codec.vector3(record.get("adapter", {}).get("current_velocity", Vector3.ZERO)), saved.motion.velocity) or not _same(Codec.vector3(_hero.global_position), saved.sample.hero_position):
			last_snapshot_error = "Actual restored scheduler/source/hero must match the validated sampled exchange"
			return false
		var current_pair: Dictionary = {"clock_s": control.clock_s, "encounter_id": control.encounter_id, "profile": _scheduler.encounter_profile(), "reservations": [_encode_public_record(record)], "cooldowns": []}
		last_snapshot_error = _actor_error(saved, current_pair, _hero.snapshot_state())
		if not last_snapshot_error.is_empty():
			return false
	elif not records.is_empty():
		last_snapshot_error = "Inactive C31/C32 cannot hide an actual retained reservation"
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
	# Stamp is the final quiet actor exchange commit, after actual physical
	# actors/Player and native Scheduler. Coordinator Route restore comes last.
	if saved.has("repulsion"):
		_spore_episode_id = saved.repulsion.episode_id
		_spore_phase = saved.repulsion.phase
		_spore_direction = Codec.read_vector3(saved.repulsion.direction)
		_spore_progress = saved.repulsion.progress
	var blocked: bool = _cue.is_blocking_signals()
	_cue.set_block_signals(true)
	_cue.clear()
	_present(record, false)
	_cue.set_block_signals(blocked)
	_snapshot_busy = false
	return true


## Alias for callers using the existing paired actor naming convention.
func snapshot_state(paired_scheduler: Dictionary) -> Dictionary:
	return capture_state(paired_scheduler)


func actor_snapshot_error(saved: Dictionary, paired_scheduler: Dictionary, saved_player: Dictionary) -> String:
	return snapshot_error(saved, paired_scheduler, saved_player)


## Final quiet exchange commit only. Whole-aggregate validation and physical
## restore_actor_state -> shared Scheduler restore MUST already have succeeded.
## This alias does not move or restore the Scheduler and cannot replace that order.
func restore_state(saved: Dictionary) -> bool:
	return restore_exchange_state(saved)


func _schema_error(saved: Dictionary) -> String:
	var error: String = String(_native_codec.call("schema_error", saved, _configuration))
	if not error.is_empty(): return error
	var bound: bool = not _spore_consumer_id.is_empty()
	if bound != saved.has("repulsion"):
		return "Saved native conditional stamp must agree with actual environmental binding"
	if bound:
		return String(_native_codec.call("repulsion_error", saved.repulsion, String(_configuration.source_id), _spore_consumer_id))
	return ""


func _actor_error(saved: Dictionary, paired: Dictionary, saved_player: Dictionary) -> String:
	# Keep native physical/resource validation here. The independent codec only
	# compares the complete copied actor/controller/Player unit and measured
	# immutable signature; it cannot authorize a changed actual body or world.
	var error: String = _schema_error(saved)
	if not error.is_empty(): return error
	if not saved.reservation_id.is_empty() and _configuration.role_id == ROLE_SWARM:
		var description: Dictionary = Motion.staged_source_description(self, _live_collision_state())
		if description.has("error") or not _same(description.get("signature", {}), _body_signature):
			return "Native lunge must retain the actual unchanged capsule"
	return String(_native_codec.call("context_error", saved, paired, saved_player, _configuration, _body_signature))


func _encode_sample() -> Dictionary:
	return {} if _sample.is_empty() else {"clock_s": _sample.clock_s, "source_position": Codec.vector3(_sample.source_position), "hero_position": Codec.vector3(_sample.hero_position)}


func _encode_public_record(record: Dictionary) -> Dictionary:
	# Root has prevalidated the complete native Scheduler envelope/bindings.
	var result: Dictionary = {"id": record.id, "source_id": _configuration.source_id, "source_position": Codec.vector3(record.source_position), "opening_position": Codec.vector3(record.opening_position), "geometry": _encode_geometry(record.geometry)}
	if record.get("adapter", {}).get("kind") == "lunge":
		result["adapter"] = record.adapter.duplicate(true)
		for key: String in ["start", "planned_endpoint", "current_position", "current_velocity", "direction"]:
			result.adapter[key] = Codec.vector3(record.adapter[key])
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		result[key] = record[key]
	return result


func _encode_geometry(shape: Dictionary) -> Dictionary:
	var encoded: Dictionary = shape.duplicate(true)
	for key: String in encoded:
		if encoded[key] is Vector3: encoded[key] = Codec.vector3(encoded[key])
	return encoded


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
	_visual.name = "MushroomSelenitePresentation"
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
	if not _sprite_art.call("configure", String(_configuration.role_id)):
		last_error = "Configure the actual immutable C31/C32 costume role before adding its art"
		_sprite_art.free()
		_sprite_art = null
		return
	_visual.add_child(_sprite_art)
	_draw_greybox()


func _draw_greybox() -> void:
	if not is_instance_valid(_visual): return
	_visual.rotation.y = atan2(_facing.x, _facing.z)
	# The invisible initial capsule mesh is not a runtime pose dependency. The
	# native role's fixed pixels alone present its phase, without a second clock.
	if is_instance_valid(_sprite_art):
		_sprite_art.call("set_pose", _phase, _facing, get_viewport().get_camera_3d())


func _exit_tree() -> void:
	# Parent retires its complete field/coordinator unit. This narrow source
	# hook releases only genuine retained Route custody; never fakes HP/death.
	var consumer: CinderSporeRepulsion = _spore_consumer()
	if consumer != null:
		consumer.source_interrupted(self, "actual_death" if dead else "source_removed")
	if is_instance_valid(_scheduler):
		if _scheduler.reservation_invalidated.is_connected(_on_invalidated):
			_scheduler.reservation_invalidated.disconnect(_on_invalidated)
		_scheduler.cancel_owner(self, "mushroom_selenite_removed")
