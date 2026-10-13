class_name CinderAct1LivingMoonBody
extends StaticBody3D
## B02's one actual ordinary-primary receiver: the low, stationary eye rim.
## Nose/Blink sources own Scheduler exchanges; this body owns only HP/phase.
## The parent supplies genuine live recovery/current-view eligibility through
## a required pure one-shot binding. No serialized/synthetic eye-open latch.
## 240/160/80 are provisional greybox screening values, not balance evidence.

signal phase_changed(source_id: String, phase: int)
signal defeated(source_id: String)
signal state_changed(body_state: Dictionary)

const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const BodySweep = preload("res://scripts/combat/body_sweep.gd")
const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const PlayerScript = preload("res://scripts/player.gd")
const API_REVISION: String = "act1-living-moon-body-1"
const SNAPSHOT_SCHEMA_VERSION: int = 1
const AUTHORED_POSITION: Vector3 = Vector3(0.0, 0.0, -9.0)
const EYE_SIZE: Vector3 = Vector3(0.9, 0.7, 0.9)
const EYE_COLLISION_POSITION: Vector3 = Vector3(0.0, 0.35, 0.0)
const LEGAL_SINGLE_HIT_MAX: float = 73.5
const SNAPSHOT_KEYS: Array[String] = ["api_revision", "schema_version", "source_id", "configuration", "hp", "dead", "phase", "position", "clock_s", "encounter_id", "world_revision", "profile_id"]

var hp: float = 240.0
var max_hp: float = 240.0
var dead: bool = false
var phase: int = 1
var last_error: String = ""
var last_snapshot_error: String = ""
var _configuration: Dictionary = {}
var _scheduler: CinderThreatScheduler
var _hero: CinderPlayer
var _world_root: Node3D
var _level: CinderLevel
var _collision: CollisionShape3D
var _box: BoxShape3D
var _hero_collision: CollisionShape3D
var _hero_capsule: CapsuleShape3D
var _hero_signature: Dictionary = {}
var _native_parents: Dictionary = {}
var _native_scripts: Dictionary = {}
var _body_transform: Transform3D
var _floor_guards: Array[Dictionary] = []
var _opening_provider: Callable = Callable()
var _opening_provider_bound: bool = false
var _transaction_depth: int = 0
var _snapshot_busy: bool = false
var _retiring: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 2
	collision_mask = 1
	_collision = CollisionShape3D.new()
	_collision.name = "BodyCollision"
	_box = BoxShape3D.new()
	_box.size = EYE_SIZE
	_collision.shape = _box
	_collision.position = EYE_COLLISION_POSITION
	add_child(_collision)
	# Native collider/visibility remain unchanged when HP reaches zero. Only the
	# target group retires; the parent retains the final flinch/spent artwork.
	add_to_group("enemies")


func configure(source_id: String, maximum_hp: float = 240.0, phase_thresholds: Array = [160.0, 80.0]) -> bool:
	if is_instance_valid(_scheduler) or _transaction_depth > 0 or _snapshot_busy or _retiring:
		return _reject("Configure immutable B02 eye data before binding")
	if not _stable_id(source_id) or not is_finite(maximum_hp) or maximum_hp <= 0.0 or phase_thresholds.size() != 2:
		return _reject("Stable source ID, positive finite HP and two thresholds required")
	for value: Variant in phase_thresholds:
		if not Codec.is_number(value): return _reject("Finite numeric phase thresholds required")
	var thresholds: Array = [float(phase_thresholds[0]), float(phase_thresholds[1])]
	if maximum_hp - thresholds[0] <= LEGAL_SINGLE_HIT_MAX or thresholds[0] - thresholds[1] <= LEGAL_SINGLE_HIT_MAX or thresholds[1] <= LEGAL_SINGLE_HIT_MAX:
		return _reject("Ordered positive HP intervals must exceed the supported legal single-hit maximum")
	var next: Dictionary = {"role_id": "B02", "source_id": source_id, "max_hp": maximum_hp, "phase_thresholds": thresholds, "authored_position": Codec.vector3(AUTHORED_POSITION), "eye_size": Codec.vector3(EYE_SIZE), "eye_collision_position": Codec.vector3(EYE_COLLISION_POSITION)}
	if not _configuration.is_empty():
		if not _same(next, _configuration): return _reject("Configured eye identity/HP intervals are immutable")
		last_error = ""
		return true
	_configuration = next
	max_hp = maximum_hp
	hp = maximum_hp
	last_error = ""
	return true


func bind_opening_provider(provider: Callable) -> bool:
	## provider(source_id: String) -> exact {eligible: bool, reason: String}.
	## The actual owning CinderLevel must provide it before native bind. Eligibility
	## is recomputed at each hit; paused codecs never invoke this gameplay callback.
	if _opening_provider_bound or is_instance_valid(_scheduler) or _transaction_depth > 0 or _snapshot_busy or _retiring or not provider.is_valid() or provider.get_argument_count() != 1:
		return _reject("Bind one valid pure parent recovery provider before native binding")
	var owner: CinderLevel = _owning_level()
	if owner == null or provider.get_object() != owner:
		return _reject("Recovery provider must belong to this actual owning CinderLevel")
	_opening_provider = provider
	_opening_provider_bound = true
	last_error = ""
	return true


func bind(scheduler: CinderThreatScheduler, hero: CinderPlayer, world_root: Node3D) -> bool:
	if not is_inside_tree() or not is_node_ready() or _configuration.is_empty() or not _opening_provider_bound or not _opening_provider.is_valid() or _transaction_depth > 0 or _snapshot_busy or _retiring:
		return _reject("Ready configured eye and mandatory parent recovery provider required")
	var owner: CinderLevel = _owning_level()
	for node: Node3D in [scheduler, hero, world_root, owner]:
		if not _ready_live(node) or node.get_world_3d() != get_world_3d() or (node != world_root and not world_root.is_ancestor_of(node)):
			return _reject("Actual ready contained same-world level/Scheduler/Hero required")
	if not world_root.is_ancestor_of(self) or owner.hero != hero or owner.get("scheduler") != scheduler or _opening_provider.get_object() != owner or scheduler.get_script() != SchedulerScript or hero.get_script() != PlayerScript:
		return _reject("Retain the actual owning level's shared Hero/Scheduler and canonical scripts")
	if global_position != AUTHORED_POSITION or global_basis != Basis.IDENTITY or constant_linear_velocity != Vector3.ZERO or constant_angular_velocity != Vector3.ZERO:
		return _reject("Eye receiver must remain at the authored upright fixed floor pivot")
	if is_instance_valid(_scheduler):
		if _scheduler != scheduler or _hero != hero or _world_root != world_root or _level != owner or not _native_binding_error().is_empty(): return _reject("Eye native bindings are immutable")
		last_error = ""
		return true
	var description: Dictionary = Motion.source_description(hero)
	if description.has("error") or BodySweep.source_description(hero).has("error"):
		return _reject("Actual canonical retained Hero body required")
	var floors: Array[Dictionary] = _find_actual_support(world_root)
	if floors.is_empty(): return _reject("Eye footprint requires an actual contained stationary box floor at Y0")
	_scheduler = scheduler
	_hero = hero
	_world_root = world_root
	_level = owner
	_body_transform = global_transform
	_floor_guards = floors
	_hero_collision = description.collision
	_hero_capsule = _hero_collision.shape as CapsuleShape3D
	_hero_signature = description.signature.duplicate(true)
	var nodes: Dictionary = {"body": self, "scheduler": scheduler, "hero": hero, "world": world_root, "level": owner}
	for key: String in nodes:
		var node: Node3D = nodes[key]
		_native_parents[key] = weakref(node.get_parent())
		_native_scripts[key] = node.get_script()
	last_error = _native_binding_error()
	return last_error.is_empty()


func state() -> Dictionary:
	return {"api_revision": API_REVISION, "source_id": String(_configuration.get("source_id", "")), "hp": hp, "max_hp": max_hp, "dead": dead, "phase": phase, "position": global_position if is_inside_tree() else position}


func get_native_bindings() -> Dictionary:
	## Pure actual references for the whole parent aggregate; no eligibility grant.
	if not _native_binding_error().is_empty(): return {}
	return {"source_id": _configuration.source_id, "configuration": _configuration.duplicate(true), "scheduler": _scheduler, "player": _hero, "world_root": _world_root, "body": self, "collision": _collision, "shape": _box}


func get_collision() -> CollisionShape3D:
	return _collision if _native_binding_error().is_empty() else null


func take_damage(amount: float, impulse: Vector3) -> Dictionary:
	var result: Dictionary = {"accepted": false, "hp_damage": 0.0, "target_id": get_instance_id(), "target_alive_before_hit": hp > 0.0 and not dead and not _retiring and not is_queued_for_deletion()}
	last_error = _damage_access_error()
	if not last_error.is_empty(): return result
	if not result.target_alive_before_hit or not is_finite(amount) or amount <= 0.0 or not impulse.is_finite():
		last_error = "Living eye and positive finite damage/impulse required"; return result
	var before: Dictionary = _callback_boundary()
	if before.is_empty(): last_error = "Actual Scheduler native callback barrier required"; return result
	_transaction_depth += 1
	var answer: Variant = _opening_provider.call(String(_configuration.source_id))
	last_error = _native_binding_error()
	if last_error.is_empty() and (get_tree().paused or _level.is_restore_candidate() or _callback_boundary() != before):
		last_error = "Pure recovery provider changed actual native body/Player/Scheduler custody"
	if last_error.is_empty() and (not answer is Dictionary or not Codec.keys_error(answer, ["eligible", "reason"]).is_empty() or not answer.get("eligible") is bool or not answer.get("reason") is String):
		last_error = "Recovery provider must return its exact literal eligibility/reason envelope"
	if last_error.is_empty() and (answer.eligible != true or not answer.reason.is_empty()):
		last_error = answer.reason if not answer.reason.is_empty() else "Actual eye recovery is closed"
	if not last_error.is_empty(): _transaction_depth -= 1; return result
	var hp_before: float = hp
	var old_phase: int = phase
	hp = maxf(0.0, hp - amount)
	dead = hp == 0.0
	phase = _phase_for_hp(hp)
	result.accepted = true
	result.hp_damage = hp_before - hp
	if dead: remove_from_group("enemies")
	# Commit the entire health/phase/death result before any observer can pause,
	# retire the level, queue a deletion, or attempt nested damage/Save.
	if phase != old_phase: phase_changed.emit(String(_configuration.source_id), phase)
	if not _observer_boundary_live(): _transaction_depth -= 1; return result
	if dead: defeated.emit(String(_configuration.source_id))
	if not _observer_boundary_live(): _transaction_depth -= 1; return result
	state_changed.emit(state())
	_transaction_depth -= 1
	return result


func snapshot_state(paired_scheduler: Dictionary, saved_player: Dictionary = {}) -> Dictionary:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty(): return {}
	var actual_player: Dictionary = _hero.snapshot_state()
	if actual_player.is_empty() or (not saved_player.is_empty() and not _same(saved_player, actual_player)):
		last_snapshot_error = "Eye capture requires the exact complete paused shared Player"; return {}
	var control: Dictionary = _scheduler.source_control_state(self)
	last_snapshot_error = _pair_error(paired_scheduler, actual_player)
	if last_snapshot_error.is_empty() and not _live_pair_matches(paired_scheduler, control): last_snapshot_error = "Eye capture requires the actual paired Scheduler clock/profile/world"
	if not last_snapshot_error.is_empty(): return {}
	_snapshot_busy = true
	var saved: Dictionary = {"api_revision": API_REVISION, "schema_version": SNAPSHOT_SCHEMA_VERSION, "source_id": _configuration.source_id, "configuration": _configuration.duplicate(true), "hp": hp, "dead": dead, "phase": phase, "position": Codec.vector3(global_position), "clock_s": paired_scheduler.clock_s, "encounter_id": paired_scheduler.encounter_id, "world_revision": paired_scheduler.world_revision, "profile_id": String(paired_scheduler.profile.get("id", ""))}
	last_snapshot_error = _saved_error(saved, paired_scheduler, actual_player)
	_snapshot_busy = false
	return saved if last_snapshot_error.is_empty() else {}


func snapshot_error(saved: Dictionary, paired_scheduler: Dictionary, saved_player: Dictionary) -> String:
	var error: String = _snapshot_access_error()
	return _saved_error(saved, paired_scheduler, saved_player) if error.is_empty() else error


func actor_snapshot_error(saved: Dictionary, paired_scheduler: Dictionary, saved_player: Dictionary) -> String:
	return snapshot_error(saved, paired_scheduler, saved_player)


func restore_state(saved: Dictionary, paired_scheduler: Dictionary, saved_player: Dictionary) -> bool:
	## Quiet commit after the parent prevalidates its entire aggregate and commits
	## actual Player/Scheduler. This never calls damage, recovery, signals or art.
	last_snapshot_error = snapshot_error(saved, paired_scheduler, saved_player)
	if not last_snapshot_error.is_empty(): return false
	var actual_player: Dictionary = _hero.snapshot_state()
	if actual_player.is_empty() or not _same(actual_player, saved_player) or not _live_pair_matches(paired_scheduler, _scheduler.source_control_state(self)):
		last_snapshot_error = "Commit exact actual Player/Scheduler before quiet eye HP restoration"; return false
	_snapshot_busy = true
	hp = float(saved.hp)
	dead = saved.dead
	phase = int(saved.phase)
	if dead: remove_from_group("enemies")
	else: add_to_group("enemies")
	_snapshot_busy = false
	last_snapshot_error = _native_binding_error()
	return last_snapshot_error.is_empty()


func _saved_error(saved: Dictionary, paired_scheduler: Dictionary, saved_player: Dictionary) -> String:
	var error: String = Codec.value_error(saved)
	if error.is_empty(): error = Codec.keys_error(saved, SNAPSHOT_KEYS)
	if not error.is_empty(): return error
	if saved.api_revision != API_REVISION or not saved.schema_version is int or saved.schema_version != SNAPSHOT_SCHEMA_VERSION or not saved.source_id is String or saved.source_id != _configuration.source_id or not saved.configuration is Dictionary or not _same(saved.configuration, _configuration) or not Codec.in_range(saved.hp, 0.0, max_hp) or not saved.dead is bool or saved.dead != (float(saved.hp) == 0.0) or not saved.phase is int or saved.phase != _phase_for_hp(float(saved.hp)) or not Codec.is_vector3(saved.position) or not _same(saved.position, Codec.vector3(AUTHORED_POSITION)):
		return "Invalid immutable eye identity/configuration/HP/phase/fixed position"
	error = _pair_error(paired_scheduler, saved_player)
	if not error.is_empty(): return error
	if not saved.clock_s is float or saved.clock_s != paired_scheduler.clock_s or not saved.encounter_id is String or saved.encounter_id != paired_scheduler.encounter_id or not saved.world_revision is int or saved.world_revision != paired_scheduler.world_revision or not saved.profile_id is String or saved.profile_id != String(paired_scheduler.profile.get("id", "")):
		return "Eye transport must retain exact paired Scheduler clock/encounter/world/profile"
	return ""


func _pair_error(paired_scheduler: Dictionary, saved_player: Dictionary) -> String:
	var error: String = Codec.value_error(paired_scheduler)
	if not error.is_empty(): return error
	if paired_scheduler.get("api_revision") != "scheduler-snapshot-1" or not paired_scheduler.get("schema_version") is int or paired_scheduler.schema_version != 1 or not paired_scheduler.get("clock_s") is float or not Codec.in_range(paired_scheduler.clock_s, 0.0, 1000000000.0) or not paired_scheduler.get("encounter_id") is String or not paired_scheduler.get("world_revision") is int or not paired_scheduler.get("profile") is Dictionary or not paired_scheduler.get("reservations") is Array or not paired_scheduler.get("cooldowns") is Array:
		return "Complete paired canonical Scheduler transport required"
	if not paired_scheduler.get("serial") is int or not paired_scheduler.get("collision") is Dictionary or (not paired_scheduler.profile.is_empty() and (not paired_scheduler.profile.get("id") is String or paired_scheduler.profile.id not in ["assisted", "standard", "challenge"])):
		return "Canonical Scheduler serial/collision and literal known profile identity required"
	for record: Variant in paired_scheduler.reservations:
		if not record is Dictionary: return "Native paired reservation dictionaries required"
		if record.get("source_id") == _configuration.source_id: return "Eye HP receiver cannot own a private attack reservation"
	for record: Variant in paired_scheduler.cooldowns:
		if not record is Dictionary: return "Native paired cooldown dictionaries required"
		if record.get("source_id") == _configuration.source_id: return "Eye HP receiver cannot own a private attack cooldown"
	return _hero.snapshot_error(saved_player)


func _live_pair_matches(paired: Dictionary, control: Dictionary) -> bool:
	return control.get("outside_transaction") == true and control.get("reservations") is Array and control.reservations.is_empty() and control.get("cooldown") == null and control.get("clock_s") == paired.clock_s and control.get("encounter_id") == paired.encounter_id and control.get("world_revision") == paired.world_revision and _same(_scheduler.encounter_profile(), paired.profile)


func _snapshot_access_error() -> String:
	var error: String = _native_binding_error()
	if not error.is_empty(): return error
	if not get_tree().paused or _transaction_depth > 0 or _snapshot_busy:
		return "Eye snapshots require the paused deferred parent barrier outside callbacks"
	return ""


func _damage_access_error() -> String:
	var error: String = _native_binding_error()
	if not error.is_empty(): return error
	if get_tree().paused or _level.is_restore_candidate() or _hero.dead or _transaction_depth > 0 or _snapshot_busy:
		return "Eye damage requires live unpaused gameplay outside damage/restore callbacks"
	return ""


func _observer_boundary_live() -> bool:
	# Pausing after a genuine hit is allowed. Queued/retired native custody is not.
	return _native_binding_error().is_empty()


func _callback_boundary() -> Dictionary:
	var control: Dictionary = _scheduler.source_control_state(self)
	if control.get("outside_transaction") != true or not control.get("reservations") is Array or not control.reservations.is_empty() or control.get("cooldown") != null: return {}
	var collision: Dictionary = _scheduler.pure_collision_fingerprint(_world_root)
	var custody: Dictionary = _scheduler_custody_views()
	if collision.is_empty() or custody.is_empty(): return {}
	return {"body_state": state(), "configuration": _configuration.duplicate(true), "provider": _opening_provider, "control": control, "source_controls": custody, "profile": _scheduler.encounter_profile(), "world_collision": collision, "hero_transform": _hero.global_transform, "hero_hp": _hero.hp, "hero_max_hp": _hero.max_hp, "hero_shells": _hero.shells, "hero_max_shells": _hero.max_shells, "hero_dead": _hero.dead, "hero_facing": _hero.facing, "hero_response": _hero.get_threat_response_state(), "hero_dash": _hero.get_committed_dash_state(), "hero_records": _hero.get_world_action_records(), "hero_last_action": _hero.last_action.duplicate(true), "hero_last_dash_distance": _hero.last_dash_distance, "paused": get_tree().paused}


func _scheduler_custody_views() -> Dictionary:
	# source_control_state is pure; reservations() can prune/cancel and is not
	# suitable inside a pure callback boundary. Cover every contained scripted
	# native Node3D, including newly added sources, without reading private leases.
	var result: Dictionary = {}
	var queue: Array[Node] = [_world_root]
	var visited: int = 0
	while not queue.is_empty() and visited < 4096:
		var node: Node = queue.pop_back()
		visited += 1
		queue.append_array(node.get_children())
		if node is Node3D and node.get_script() != null:
			var control: Dictionary = _scheduler.source_control_state(node as Node3D)
			if control.get("outside_transaction") != true: return {}
			result[node.get_instance_id()] = control
	return result if queue.is_empty() else {}


func _native_binding_error() -> String:
	if _retiring or _configuration.is_empty() or not _ready_live(self) or not _opening_provider_bound or not _opening_provider.is_valid(): return "Retained configured live eye/provider required"
	var nodes: Dictionary = {"body": self, "scheduler": _scheduler, "hero": _hero, "world": _world_root, "level": _level}
	for key: String in nodes:
		var node: Node3D = nodes[key] as Node3D
		if not _ready_live(node) or node.get_world_3d() != get_world_3d() or not _native_parents.has(key) or not _native_scripts.has(key) or node.get_parent() != (_native_parents[key] as WeakRef).get_ref() or node.get_script() != _native_scripts[key] or (node != _world_root and not _world_root.is_ancestor_of(node)):
			return "Actual eye native parent/script/world binding changed: " + key
	if _owning_level() != _level or _level.hero != _hero or _level.get("scheduler") != _scheduler or _opening_provider.get_object() != _level or _scheduler.get_script() != SchedulerScript or _hero.get_script() != PlayerScript:
		return "Actual owning eye level/shared Hero/Scheduler/provider changed or retired"
	if global_transform != _body_transform or global_position != AUTHORED_POSITION or global_basis != Basis.IDENTITY or collision_layer != 2 or collision_mask != 1 or constant_linear_velocity != Vector3.ZERO or constant_angular_velocity != Vector3.ZERO or not get_collision_exceptions().is_empty():
		return "Retain stationary upright non-scenery eye body registration/frame"
	if not _ready_live(_collision) or not is_instance_valid(_box) or get_node_or_null("BodyCollision") != _collision or _collision.get_parent() != self or _collision.shape != _box or _collision.disabled or _collision.transform != Transform3D(Basis.IDENTITY, EYE_COLLISION_POSITION) or _box.size != EYE_SIZE:
		return "Retain actual eye collision node/shape/size/pose and enabled native registration"
	var count: int = 0
	for owner_id: int in get_shape_owners():
		if is_shape_owner_disabled(owner_id): return "No added disabled eye shape owner is permitted"
		if shape_owner_get_owner(owner_id) != _collision: return "One retained eye collision owner required"
		if shape_owner_get_transform(owner_id) != _collision.transform or shape_owner_get_shape_count(owner_id) != 1 or shape_owner_get_shape(owner_id, 0) != _box:
			return "Actual registered eye shape/transform must match its retained collision node/resource"
		count += shape_owner_get_shape_count(owner_id)
	if count != 1: return "One actual eye collision shape required"
	if not Codec.in_range(hp, 0.0, max_hp) or max_hp != _configuration.max_hp or dead != (hp == 0.0) or phase != _phase_for_hp(hp) or is_in_group("enemies") == dead or is_in_group("practice_targets") or is_in_group("environment_attack_targets") or not visible or (not is_visible_in_tree() and not _level.is_restore_candidate()):
		return "Actual eye HP/phase/death/target membership/visibility is incoherent"
	if not _ready_live(_hero_collision) or not is_instance_valid(_hero_capsule) or _hero.get_node_or_null("BodyCollision") != _hero_collision or _hero_collision.get_parent() != _hero or _hero_collision.shape != _hero_capsule:
		return "Retain actual canonical Hero collision node/resource"
	var description: Dictionary = Motion.source_description(_hero)
	if description.has("error") or BodySweep.source_description(_hero).has("error") or not _same(description.get("signature", {}), _hero_signature): return "Actual retained Hero collision signature changed"
	return _support_error()


func _find_actual_support(world_root: Node3D) -> Array[Dictionary]:
	# Retain real solid floor nodes/resources, rather than an asserted safe_rect.
	var found: Array[Dictionary] = []
	var queue: Array[Node] = [world_root]
	var visited: int = 0
	while not queue.is_empty() and visited < 4096:
		var node: Node = queue.pop_back()
		visited += 1
		queue.append_array(node.get_children())
		if not node is StaticBody3D or node is AnimatableBody3D or node == self: continue
		var body: StaticBody3D = node as StaticBody3D
		if not _ready_live(body) or (body.collision_layer & 1) == 0 or body.global_basis != Basis.IDENTITY or body.constant_linear_velocity != Vector3.ZERO or body.constant_angular_velocity != Vector3.ZERO: continue
		for child: Node in body.get_children():
			if not child is CollisionShape3D: continue
			var collision: CollisionShape3D = child as CollisionShape3D
			if not _ready_live(collision) or collision.disabled or not collision.shape is BoxShape3D or collision.global_basis != Basis.IDENTITY: continue
			var box: BoxShape3D = collision.shape as BoxShape3D
			if not box.size.is_finite() or box.size.x <= 0.0 or box.size.y <= 0.0 or box.size.z <= 0.0 or absf(collision.global_position.y + box.size.y * 0.5) > BodySweep.EPSILON: continue
			var rect := Rect2(Vector2(collision.global_position.x - box.size.x * 0.5, collision.global_position.z - box.size.z * 0.5), Vector2(box.size.x, box.size.z))
			var eye_rect := Rect2(Vector2(AUTHORED_POSITION.x - EYE_SIZE.x * 0.5 - BodySweep.SAFE_MARGIN, AUTHORED_POSITION.z - EYE_SIZE.z * 0.5 - BodySweep.SAFE_MARGIN), Vector2(EYE_SIZE.x, EYE_SIZE.z) + Vector2.ONE * BodySweep.SAFE_MARGIN * 2.0)
			if not rect.encloses(eye_rect): continue
			found.append({"body": weakref(body), "parent": weakref(body.get_parent()), "script": body.get_script(), "transform": body.global_transform, "layer": body.collision_layer, "mask": body.collision_mask, "collision": weakref(collision), "collision_transform": collision.transform, "shape": box, "size": box.size})
			return found
	return found


func _support_error() -> String:
	if _floor_guards.size() != 1: return "Retained actual eye support floor required"
	var guard: Dictionary = _floor_guards[0]
	var body: StaticBody3D = (guard.body as WeakRef).get_ref() as StaticBody3D
	var collision: CollisionShape3D = (guard.collision as WeakRef).get_ref() as CollisionShape3D
	if not _ready_live(body) or body is AnimatableBody3D or not _ready_live(collision) or not is_instance_valid(guard.shape) or body.get_parent() != (guard.parent as WeakRef).get_ref() or body.get_script() != guard.script or body.get_world_3d() != get_world_3d() or not _world_root.is_ancestor_of(body) or body.global_transform != guard.transform or body.collision_layer != guard.layer or body.collision_mask != guard.mask or body.constant_linear_velocity != Vector3.ZERO or body.constant_angular_velocity != Vector3.ZERO or collision.get_parent() != body or collision.shape != guard.shape or collision.disabled or collision.transform != guard.collision_transform or (guard.shape as BoxShape3D).size != guard.size:
		return "Actual retained eye support floor/node/resource/frame changed"
	var count: int = 0
	for owner_id: int in body.get_shape_owners():
		if body.is_shape_owner_disabled(owner_id): return "No added disabled eye support shape owner is permitted"
		if body.shape_owner_get_owner(owner_id) != collision or body.shape_owner_get_transform(owner_id) != collision.transform or body.shape_owner_get_shape_count(owner_id) != 1 or body.shape_owner_get_shape(owner_id, 0) != guard.shape:
			return "Actual registered eye support shape/transform must match its retained floor node/resource"
		count += body.shape_owner_get_shape_count(owner_id)
	if count != 1: return "Eye support floor requires one actual enabled box"
	return ""


func _phase_for_hp(value: float) -> int:
	if _configuration.is_empty(): return 1
	return 1 if value > float(_configuration.phase_thresholds[0]) else (2 if value > float(_configuration.phase_thresholds[1]) else 3)


func _owning_level() -> CinderLevel:
	var node: Node = get_parent()
	while node != null:
		if node is CinderLevel: return node as CinderLevel
		node = node.get_parent()
	return null


func _ready_live(node: Node) -> bool:
	if not is_instance_valid(node) or not node.is_inside_tree() or not node.is_node_ready() or node.is_queued_for_deletion(): return false
	var ancestor: Node = node.get_parent()
	while ancestor != null:
		if ancestor.is_queued_for_deletion(): return false
		ancestor = ancestor.get_parent()
	return true


func _stable_id(value: String) -> bool:
	if value.is_empty() or value.length() > 128: return false
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9_./:-]+$")
	var matched: RegExMatch = pattern.search(value)
	return matched != null and matched.get_string() == value


func _same(left: Variant, right: Variant) -> bool:
	if Codec.is_number(left) and Codec.is_number(right): return float(left) == float(right)
	if typeof(left) != typeof(right): return false
	if left is Dictionary:
		if left.size() != right.size(): return false
		for key: Variant in left:
			if not right.has(key) or not _same(left[key], right[key]): return false
		return true
	if left is Array:
		if left.size() != right.size(): return false
		for index: int in range(left.size()):
			if not _same(left[index], right[index]): return false
		return true
	return left == right


func _reject(reason: String) -> bool:
	last_error = reason
	return false


func _exit_tree() -> void:
	_retiring = true
	_opening_provider = Callable()
