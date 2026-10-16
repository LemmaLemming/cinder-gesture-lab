class_name CinderAct1LivingMoonBody
extends CharacterBody3D
## B02's one actual ordinary-primary receiver: the low, stationary eye rim.
## The real eye owns HP/phase and its published sampled Blink lease; its child
## shared consumer owns warning/lock/active/recovery and actual contact samples.
## The nose retains its separate supported stationary cone lease.
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
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const SampledCircle = preload("res://scripts/combat/native_sampled_circle.gd")
const API_REVISION: String = "act1-living-moon-body-1"
const SNAPSHOT_SCHEMA_VERSION: int = 1
const SAMPLED_SNAPSHOT_SCHEMA_VERSION: int = 2
const AUTHORED_POSITION: Vector3 = Vector3(0.0, 0.0, -9.0)
const EYE_SIZE: Vector3 = Vector3(0.9, 0.7, 0.9)
const EYE_COLLISION_POSITION: Vector3 = Vector3(0.0, 0.35, 0.0)
const LEGAL_SINGLE_HIT_MAX: float = 73.5
const SNAPSHOT_KEYS: Array[String] = ["api_revision", "schema_version", "source_id", "configuration", "hp", "dead", "phase", "position", "clock_s", "encounter_id", "world_revision", "profile_id"]
## Provisional Root-selected B02 screening values. No human balance claim.
const BLINK_RAW_ROLE: Dictionary = {"raw_damage": 8.0, "windup_s": 2.2, "lock_s": 1.1, "active_s": 0.2, "recovery_s": 2.6, "attack_interval_s": 2.8, "max_hp": 240.0, "move_speed": 0.0}
const BLINK_TIMING_FLOORS: Dictionary = {"windup_s": 2.2, "lock_s": 1.1, "recovery_s": 2.6}
const BLINK_DEFINITION: Dictionary = {"radius": 0.8, "raw_role": BLINK_RAW_ROLE, "timing_floors": BLINK_TIMING_FLOORS}
const DEFAULT_SOURCE_EPOCH: String = "living-moon-eye-incarnation-1"

var hp: float = 240.0
var max_hp: float = 240.0
var dead: bool = false
var phase: int = 1
var last_error: String = ""
var last_snapshot_error: String = ""
var _configuration: Dictionary = {}
var _sampled_configuration: Dictionary = {}
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
var _native_body_properties: Dictionary = {}
var _floor_guards: Array[Dictionary] = []
var _opening_provider: Callable = Callable()
var _opening_provider_bound: bool = false
var _transaction_depth: int = 0
var _snapshot_busy: bool = false
var _retiring: bool = false
var _physical_restore_staged: bool = false


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
	# CharacterBody3D has no automatic gravity or movement. This receiver has
	# no physics loop, move_and_slide, teleport, knockback or position repair.
	velocity = Vector3.ZERO
	_native_body_properties = _read_native_body_properties()
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


func configure_sampled_circle(source_epoch: String = DEFAULT_SOURCE_EPOCH, generation: int = 1, definition: Dictionary = BLINK_DEFINITION) -> bool:
	## Optional genuine Shared56 composition. Keep the original unsampled body
	## packet/schema1 when omitted; configure before native Hero/Scheduler bind.
	if _configuration.is_empty() or is_instance_valid(_scheduler) or _transaction_depth > 0 or _snapshot_busy or _retiring or not _stable_id(source_epoch) or not Codec.is_integer(generation, 1) or ExactJson.stringify(definition).is_empty() or not Codec.keys_error(definition, ["radius", "raw_role", "timing_floors"]).is_empty():
		return _reject("Configure a closed immutable sampled eye incarnation before binding")
	if not definition.radius is float or not Codec.in_range(definition.radius, 0.0, 16.0) or definition.radius <= 0.0 or not definition.raw_role is Dictionary or not definition.timing_floors is Dictionary or not Codec.keys_error(definition.raw_role, BLINK_RAW_ROLE.keys()).is_empty() or not Codec.keys_error(definition.timing_floors, BLINK_TIMING_FLOORS.keys()).is_empty() or not definition.raw_role.move_speed is float or definition.raw_role.move_speed != 0.0 or not definition.raw_role.max_hp is float or definition.raw_role.max_hp != max_hp:
		return _reject("Native stationary Blink recipe must retain the one actual eye HP maximum")
	for values: Dictionary in [definition.raw_role, definition.timing_floors]:
		for key: String in values:
			if not values[key] is float or not is_finite(values[key]): return _reject("Blink role/timing data retain their finite float types")
	var difficulty = Difficulty.new()
	for profile_id: String in ["assisted", "standard", "challenge"]:
		if difficulty.resolve_role(definition.raw_role, profile_id, definition.timing_floors).is_empty(): return _reject(difficulty.last_error)
	var next: Dictionary = {"source_epoch": source_epoch, "generation": generation, "definition": definition.duplicate(true)}
	if not _sampled_configuration.is_empty() and not _exact_same(next, _sampled_configuration): return _reject("Sampled eye incarnation/recipe is immutable across cycles")
	_sampled_configuration = next
	last_error = ""
	return true


func get_sampled_circle_binding() -> Dictionary:
	## The exact nine-key published native hook. Hero is this actual retained
	## Player, never an Object supplied by serialized transport or another source.
	if _sampled_configuration.is_empty() or not _native_binding_error().is_empty(): return {}
	return {"api_revision": SampledCircle.SOURCE_API, "source_id": _configuration.source_id, "source_epoch": _sampled_configuration.source_epoch, "generation": _sampled_configuration.generation, "definition": _sampled_configuration.definition.duplicate(true), "alive": hp > 0.0 and not dead, "opening_position": global_position, "hero_id": "hero", "hero": _hero}


func _source_wire_for_alive(alive: bool) -> Dictionary:
	return {"api_revision": SampledCircle.SOURCE_API, "source_id": _configuration.source_id, "source_epoch": _sampled_configuration.source_epoch, "generation": _sampled_configuration.generation, "definition": _sampled_configuration.definition.duplicate(true), "alive": alive, "opening_position": Codec.vector3(AUTHORED_POSITION), "hero_id": "hero"}


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
	if global_position != AUTHORED_POSITION or global_basis != Basis.IDENTITY or velocity != Vector3.ZERO:
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
	# Shared56 requires the true eye to retire its own sampled lease/cooldown
	# with this exact genuine-death reason before any parent phase/death observer.
	if dead and not _sampled_configuration.is_empty(): _scheduler.cancel_owner(self, "source_defeated")
	# Commit the entire health/phase/death result before any observer can pause,
	# retire the level, queue a deletion, or attempt nested damage/Save.
	if not _observer_boundary_live(): _transaction_depth -= 1; return result
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
	if actual_player.is_empty() or (not saved_player.is_empty() and not (_same(saved_player, actual_player) if _sampled_configuration.is_empty() else _exact_same(saved_player, actual_player))):
		last_snapshot_error = "Eye capture requires the exact complete paused shared Player"; return {}
	var control: Dictionary = _scheduler.source_control_state(self)
	last_snapshot_error = _pair_error(paired_scheduler, actual_player, {} if _sampled_configuration.is_empty() else _source_wire_for_alive(not dead))
	if last_snapshot_error.is_empty() and not _live_pair_matches(paired_scheduler, control): last_snapshot_error = "Eye capture requires the actual paired Scheduler clock/profile/world"
	if not last_snapshot_error.is_empty(): return {}
	_snapshot_busy = true
	var saved: Dictionary = {"api_revision": API_REVISION, "schema_version": SNAPSHOT_SCHEMA_VERSION, "source_id": _configuration.source_id, "configuration": _configuration.duplicate(true), "hp": hp, "dead": dead, "phase": phase, "position": Codec.vector3(global_position), "clock_s": paired_scheduler.clock_s, "encounter_id": paired_scheduler.encounter_id, "world_revision": paired_scheduler.world_revision, "profile_id": String(paired_scheduler.profile.get("id", ""))}
	if not _sampled_configuration.is_empty():
		saved["schema_version"] = SAMPLED_SNAPSHOT_SCHEMA_VERSION
		saved["velocity"] = Codec.vector3(velocity)
		saved["source_binding"] = _source_wire_for_alive(not dead)
	last_snapshot_error = _saved_error(saved, paired_scheduler, actual_player)
	_snapshot_busy = false
	return saved if last_snapshot_error.is_empty() else {}


func snapshot_error(saved: Dictionary, paired_scheduler: Dictionary, saved_player: Dictionary) -> String:
	var error: String = _snapshot_access_error()
	return _saved_error(saved, paired_scheduler, saved_player) if error.is_empty() else error


func actor_snapshot_error(saved: Dictionary, paired_scheduler: Dictionary, saved_player: Dictionary) -> String:
	return snapshot_error(saved, paired_scheduler, saved_player)


func restore_state(saved: Dictionary, paired_scheduler: Dictionary, saved_player: Dictionary) -> bool:
	## Original unsampled compatibility path: Player/Scheduler are already quiet.
	## Sampled parents use restore_physical_state BEFORE Scheduler, then this
	## method or validate_restored_state AFTER Scheduler (no repeated HP write).
	if not _sampled_configuration.is_empty():
		last_snapshot_error = validate_restored_state(saved, paired_scheduler, saved_player)
		return last_snapshot_error.is_empty()
	last_snapshot_error = snapshot_error(saved, paired_scheduler, saved_player)
	if not last_snapshot_error.is_empty(): return false
	var actual_player: Dictionary = _hero.snapshot_state()
	if actual_player.is_empty() or not _same(actual_player, saved_player) or not _live_pair_matches(paired_scheduler, _scheduler.source_control_state(self)):
		last_snapshot_error = "Commit exact actual Player/Scheduler before quiet eye HP restoration"; return false
	if not restore_physical_state(saved, paired_scheduler, saved_player): return false
	last_snapshot_error = validate_restored_state(saved, paired_scheduler, saved_player)
	return last_snapshot_error.is_empty()


func restore_physical_state(saved: Dictionary, paired_scheduler: Dictionary, saved_player: Dictionary) -> bool:
	## After whole-parent prevalidation, actual Player -> physical eye ->
	## Scheduler -> fresh sampled consumer. Never request/cancel/resample/emit.
	last_snapshot_error = snapshot_error(saved, paired_scheduler, saved_player)
	if not last_snapshot_error.is_empty(): return false
	var actual_player: Dictionary = _hero.snapshot_state()
	var control: Dictionary = _scheduler.source_control_state(self)
	if actual_player.is_empty() or not _exact_same(actual_player, saved_player) or control.get("outside_transaction") != true or not control.get("reservations") is Array or not control.reservations.is_empty() or control.get("cooldown") != null:
		last_snapshot_error = "Physical eye staging needs the restored actual Player and an unleased native recipient"; return false
	if not _sampled_configuration.is_empty() and _physical_restore_staged:
		last_snapshot_error = "Sampled physical eye staging is one-shot for the fresh parent recipient"; return false
	_snapshot_busy = true
	hp = float(saved.hp)
	dead = saved.dead
	phase = int(saved.phase)
	# The saved sampled velocity is independently constrained to exact ZERO.
	# The fixed authored transform is checked, never repaired or teleported.
	velocity = Vector3.ZERO
	if dead: remove_from_group("enemies")
	else: add_to_group("enemies")
	if not _sampled_configuration.is_empty(): _physical_restore_staged = true
	_snapshot_busy = false
	last_snapshot_error = _native_binding_error()
	return last_snapshot_error.is_empty()


func validate_restored_state(saved: Dictionary, paired_scheduler: Dictionary, saved_player: Dictionary) -> String:
	## Pure final correspondence after genuine Scheduler commit. No repair,
	## transient entitlement, received Hero Object, request or source activation.
	var error: String = snapshot_error(saved, paired_scheduler, saved_player)
	if not error.is_empty(): return error
	var actual_player: Dictionary = _hero.snapshot_state()
	if actual_player.is_empty() or not _exact_same(actual_player, saved_player) or hp != float(saved.hp) or dead != saved.dead or phase != saved.phase or velocity != Vector3.ZERO or not _live_pair_matches(paired_scheduler, _scheduler.source_control_state(self)):
		return "Actual restored eye/Player/Scheduler must match the complete validated pair"
	if not _sampled_configuration.is_empty() and not _physical_restore_staged: return "Commit the fresh sampled eye physical packet before Scheduler validation"
	return ""


func staged_sampled_bindings(saved: Dictionary) -> Dictionary:
	## Pure extraction, with no accepted-packet cache or received Hero Object.
	## Mandatory parent precondition: snapshot_error(saved, paired, player)==""
	## on the complete saved Player/Scheduler pair immediately before this call.
	## This one-argument helper independently rechecks native custody and every
	## eye field; absent paired inputs cannot be validated by this helper itself.
	if _sampled_configuration.is_empty() or not _snapshot_access_error().is_empty() or not _eye_envelope_error(saved).is_empty(): return {}
	return {"owner_positions": {String(_configuration.source_id): Codec.read_vector3(saved.position)}, "owner_velocities": {String(_configuration.source_id): Vector3.ZERO}, "sampled_owner_bindings": {String(_configuration.source_id): saved.source_binding.duplicate(true)}}


func _saved_error(saved: Dictionary, paired_scheduler: Dictionary, saved_player: Dictionary) -> String:
	var error: String = _eye_envelope_error(saved)
	if not error.is_empty(): return error
	var saved_binding: Dictionary = {} if _sampled_configuration.is_empty() else saved.source_binding
	error = _pair_error(paired_scheduler, saved_player, saved_binding)
	if not error.is_empty(): return error
	if not (_same(saved.clock_s, paired_scheduler.clock_s) if _sampled_configuration.is_empty() else _exact_same(saved.clock_s, paired_scheduler.clock_s)) or saved.encounter_id != paired_scheduler.encounter_id or saved.world_revision != paired_scheduler.world_revision or saved.profile_id != String(paired_scheduler.profile.get("id", "")):
		return "Eye transport must retain exact paired Scheduler clock/encounter/world/profile"
	return ""


func _eye_envelope_error(saved: Dictionary) -> String:
	var error: String = Codec.value_error(saved)
	var keys: Array[String] = SNAPSHOT_KEYS.duplicate()
	if not _sampled_configuration.is_empty(): keys.append_array(["velocity", "source_binding"])
	if error.is_empty(): error = Codec.keys_error(saved, keys)
	if not error.is_empty(): return error
	var expected_schema: int = SNAPSHOT_SCHEMA_VERSION if _sampled_configuration.is_empty() else SAMPLED_SNAPSHOT_SCHEMA_VERSION
	if saved.api_revision != API_REVISION or not saved.schema_version is int or saved.schema_version != expected_schema or not saved.source_id is String or saved.source_id != _configuration.source_id or not saved.configuration is Dictionary or not _same(saved.configuration, _configuration) or not Codec.in_range(saved.hp, 0.0, max_hp) or not saved.dead is bool or saved.dead != (float(saved.hp) == 0.0) or not saved.phase is int or saved.phase != _phase_for_hp(float(saved.hp)) or not Codec.is_vector3(saved.position) or not _same(saved.position, Codec.vector3(AUTHORED_POSITION)):
		return "Invalid immutable eye identity/configuration/HP/phase/fixed position"
	if not _sampled_configuration.is_empty():
		if ExactJson.stringify(saved).is_empty() or not saved.hp is float or not _exact_same(saved.configuration, _configuration) or not _exact_same(saved.position, Codec.vector3(AUTHORED_POSITION)) or not Codec.is_vector3(saved.velocity) or not _exact_same(saved.velocity, Codec.vector3(Vector3.ZERO)) or not saved.source_binding is Dictionary or not _exact_same(saved.source_binding, _source_wire_for_alive(not saved.dead)):
			return "Sampled eye retains exact true HP/death, stationary velocity and trusted source incarnation wire"
	if not saved.clock_s is float or not Codec.in_range(saved.clock_s, 0.0, 1000000000.0) or not saved.encounter_id is String or (not saved.encounter_id.is_empty() and not _stable_id(saved.encounter_id)) or not saved.world_revision is int or not Codec.is_integer(saved.world_revision) or not saved.profile_id is String or saved.profile_id not in ["", "assisted", "standard", "challenge"]:
		return "Eye transport retains bounded literal Scheduler clock/encounter/world/profile fields"
	return ""


func _pair_error(paired_scheduler: Dictionary, saved_player: Dictionary, saved_binding: Dictionary) -> String:
	var error: String = Codec.value_error(paired_scheduler)
	if not error.is_empty(): return error
	var sampled: bool = not _sampled_configuration.is_empty()
	var keys: Array = ["api_revision", "schema_version", "encounter_id", "profile", "world_revision", "clock_s", "serial", "collision", "reservations", "cooldowns"]
	if paired_scheduler.has("replay_cancellations"): keys.append("replay_cancellations")
	if sampled:
		keys.append("sampled_circle_sources")
		if paired_scheduler.has("authored_source_cycles"): keys.append("authored_source_cycles")
	error = Codec.keys_error(paired_scheduler, keys)
	if not error.is_empty(): return error
	if paired_scheduler.api_revision != "scheduler-snapshot-1" or not paired_scheduler.schema_version is int or paired_scheduler.schema_version != (4 if sampled else 1) or not paired_scheduler.clock_s is float or not Codec.in_range(paired_scheduler.clock_s, 0.0, 1000000000.0) or not paired_scheduler.encounter_id is String or not paired_scheduler.world_revision is int or not Codec.is_integer(paired_scheduler.world_revision) or not paired_scheduler.profile is Dictionary or not paired_scheduler.reservations is Array or not paired_scheduler.cooldowns is Array:
		return "Complete paired canonical Scheduler transport required"
	if not paired_scheduler.serial is int or not Codec.is_integer(paired_scheduler.serial) or not paired_scheduler.collision is Dictionary or (not paired_scheduler.profile.is_empty() and (not paired_scheduler.profile.get("id") is String or paired_scheduler.profile.id not in ["assisted", "standard", "challenge"])) or (paired_scheduler.has("replay_cancellations") and not paired_scheduler.replay_cancellations is Array) or (paired_scheduler.has("authored_source_cycles") and not paired_scheduler.authored_source_cycles is Dictionary):
		return "Canonical Scheduler serial/collision and literal known profile identity required"
	if paired_scheduler.encounter_id.is_empty():
		if not paired_scheduler.profile.is_empty() or not paired_scheduler.reservations.is_empty() or not paired_scheduler.cooldowns.is_empty(): return "Idle Scheduler cannot retain attacks/profile/cooldowns"
	elif not _stable_id(paired_scheduler.encounter_id) or paired_scheduler.world_revision < 1 or paired_scheduler.profile.is_empty():
		return "Actual stable encounter epoch/profile/world revision required"
	error = _hero.snapshot_error(saved_player)
	if not error.is_empty(): return error
	if sampled:
		if ExactJson.stringify(paired_scheduler).is_empty() or ExactJson.stringify(saved_player).is_empty() or not saved_player.world_actions.clock_s is float or not paired_scheduler.sampled_circle_sources is Dictionary or paired_scheduler.sampled_circle_sources.is_empty() or paired_scheduler.sampled_circle_sources.size() > 64 or not _exact_same(paired_scheduler.sampled_circle_sources.get(_configuration.source_id), saved_binding): return "Paired schema4 must retain the complete exact Player and true eye source wire"
		var difficulty = Difficulty.new()
		if not _exact_same(paired_scheduler.profile, difficulty.profile(String(paired_scheduler.profile.get("id", "")))): return "Exact paired sampled encounter profile differs from the catalogue"
		for source_id: Variant in paired_scheduler.sampled_circle_sources:
			var wire: Variant = paired_scheduler.sampled_circle_sources[source_id]
			if not source_id is String or not _stable_id(source_id) or not wire is Dictionary or not Codec.keys_error(wire, SampledCircle.SOURCE_WIRE_KEYS).is_empty() or wire.get("source_id") != source_id: return "Complete closed sampled source map required"
	var own_records: int = 0
	var own_lease: Dictionary = {}
	for record: Variant in paired_scheduler.reservations:
		if not record is Dictionary: return "Native paired reservation dictionaries required"
		if record.get("source_id") != _configuration.source_id: continue
		if not sampled: return "Unsampled eye HP receiver cannot own an attack reservation"
		own_records += 1
		if own_records != 1 or saved_binding.alive != true: return "One living true sampled eye lease required"
		var record_keys: Array = ["id", "source_id", "source_position", "opening_position", "geometry", "floors", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision", "adapter"]
		if not Codec.keys_error(record, record_keys).is_empty() or not record.adapter is Dictionary or record.adapter.get("kind") != "sampled_circle" or not record.floors is Array or record.floors.is_empty() or record.profile_id != paired_scheduler.profile.get("id") or record.world_revision != paired_scheduler.world_revision or not record.start_s is float or not record.recovery_until_s is float or record.start_s > paired_scheduler.clock_s or paired_scheduler.clock_s > record.recovery_until_s:
			return "Eye lease must be the exact published live sampled adapter"
		var exchange: Dictionary = record.duplicate(true)
		exchange.erase("source_id")
		exchange.erase("floors")
		exchange.erase("adapter")
		error = _scheduler.sampled_circle_exchange_error(self, exchange, record.adapter, paired_scheduler.clock_s, saved_player.world_actions.clock_s)
		if not error.is_empty(): return error
		if int(record.id.substr(7)) > paired_scheduler.serial: return "Sampled eye lease must retain its original paired Scheduler serial"
		own_lease = record
	var own_cooldowns: int = 0
	var own_ready_s: Variant = null
	for record: Variant in paired_scheduler.cooldowns:
		if not record is Dictionary: return "Native paired cooldown dictionaries required"
		if record.get("source_id") != _configuration.source_id: continue
		if not sampled: return "Unsampled eye HP receiver cannot own an attack cooldown"
		own_cooldowns += 1
		if own_cooldowns != 1 or saved_binding.alive != true or not Codec.keys_error(record, ["source_id", "ready_s"]).is_empty() or not record.ready_s is float or not Codec.in_range(record.ready_s, paired_scheduler.clock_s, 1000000000.0) or record.ready_s <= paired_scheduler.clock_s: return "One living true original sampled eye cooldown required"
		own_ready_s = record.ready_s
	if not own_lease.is_empty() and own_lease.cooldown_until_s > paired_scheduler.clock_s and not _exact_same(own_ready_s, own_lease.cooldown_until_s): return "Sampled eye lease and cooldown retain the same original deadline"
	# The actual whole Scheduler validator still joins every source, collider,
	# floor/proof and cooldown. Body validation grants no Scheduler authority.
	return ""


func _live_pair_matches(paired: Dictionary, control: Dictionary) -> bool:
	if not _own_control_error(control).is_empty() or control.clock_s != paired.clock_s or control.encounter_id != paired.encounter_id or control.world_revision != paired.world_revision or not (_exact_same(_scheduler.encounter_profile(), paired.profile) if not _sampled_configuration.is_empty() else _same(_scheduler.encounter_profile(), paired.profile)): return false
	if _sampled_configuration.is_empty(): return true
	if not _exact_same(paired.sampled_circle_sources.get(_configuration.source_id), _source_wire_for_alive(not dead)): return false
	var own: Array[Dictionary] = []
	for value: Dictionary in paired.reservations:
		if value.get("source_id") == _configuration.source_id: own.append(value)
	if own.size() != control.reservations.size(): return false
	if not own.is_empty():
		var wire: Dictionary = own[0]
		var actual: Dictionary = control.reservations[0]
		for key: String in ["id", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision", "adapter"]:
			if not _exact_same(wire[key], actual.get(key)): return false
		if not _exact_same(wire.source_position, Codec.vector3(actual.source_position)) or not _exact_same(wire.opening_position, Codec.vector3(actual.opening_position)) or not _exact_same(wire.geometry, _geometry_wire(actual.geometry)): return false
	var saved_cooldown: Variant = null
	for value: Dictionary in paired.cooldowns:
		if value.get("source_id") == _configuration.source_id: saved_cooldown = {"ready_s": value.ready_s}
	return _exact_same(control.cooldown, saved_cooldown)


func _own_control_error(control: Dictionary) -> String:
	if control.get("api_revision") != "scheduler-source-control-1" or control.get("source_instance_id") != get_instance_id() or control.get("outside_transaction") != true or not control.get("reservations") is Array: return "Actual pure native eye Scheduler custody required"
	if _sampled_configuration.is_empty():
		return "" if control.reservations.is_empty() and control.get("cooldown") == null else "Unsampled receiver cannot own an attack"
	if control.reservations.size() > 1 or (dead and (not control.reservations.is_empty() or control.get("cooldown") != null)): return "True eye death must retire its own sampled lease/cooldown"
	for value: Variant in control.reservations:
		if not value is Dictionary or value.get("source_instance_id") != get_instance_id() or not value.get("id") is String or not value.get("adapter") is Dictionary or value.adapter.get("kind") != "sampled_circle": return "Eye may own only its actual native sampled lease"
		var actual: Dictionary = _scheduler.sampled_circle_reservation_state(value.id)
		if actual.is_empty() or actual != value: return "Actual sampled eye lease lost native source/floor/recipe custody"
	if control.get("cooldown") != null and (not control.cooldown is Dictionary or not Codec.keys_error(control.cooldown, ["ready_s"]).is_empty() or not control.cooldown.ready_s is float or not Codec.in_range(control.cooldown.ready_s, 0.0, 1000000000.0)): return "Actual sampled cooldown must retain its original finite clock"
	return ""


func _geometry_wire(geometry: Dictionary) -> Dictionary:
	var wire: Dictionary = geometry.duplicate(true)
	for key: String in wire:
		if wire[key] is Vector3: wire[key] = Codec.vector3(wire[key])
	return wire


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
	if not _own_control_error(control).is_empty(): return {}
	var collision: Dictionary = _scheduler.pure_collision_fingerprint(_world_root)
	var custody: Dictionary = _scheduler_custody_views()
	if collision.is_empty() or custody.is_empty(): return {}
	return {"body_state": state(), "configuration": _configuration.duplicate(true), "sampled_configuration": _sampled_configuration.duplicate(true), "provider": _opening_provider, "control": control, "source_controls": custody, "profile": _scheduler.encounter_profile(), "world_collision": collision, "hero_transform": _hero.global_transform, "hero_hp": _hero.hp, "hero_max_hp": _hero.max_hp, "hero_shells": _hero.shells, "hero_max_shells": _hero.max_shells, "hero_dead": _hero.dead, "hero_facing": _hero.facing, "hero_response": _hero.get_threat_response_state(), "hero_dash": _hero.get_committed_dash_state(), "hero_records": _hero.get_world_action_records(), "hero_last_action": _hero.last_action.duplicate(true), "hero_last_dash_distance": _hero.last_dash_distance, "paused": get_tree().paused}


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
	if global_transform != _body_transform or global_position != AUTHORED_POSITION or global_basis != Basis.IDENTITY or collision_layer != 2 or collision_mask != 1 or velocity != Vector3.ZERO or not get_collision_exceptions().is_empty() or get_platform_velocity() != Vector3.ZERO or get_platform_angular_velocity() != Vector3.ZERO or axis_lock_linear_x or axis_lock_linear_y or axis_lock_linear_z or not _exact_same(_read_native_body_properties(), _native_body_properties):
		return "Retain stationary upright non-scenery eye body registration/frame"
	if not _ready_live(_collision) or not is_instance_valid(_box) or get_node_or_null("BodyCollision") != _collision or _collision.get_parent() != self or _collision.get_script() != null or _box.get_script() != null or _collision.shape != _box or _collision.disabled or _collision.transform != Transform3D(Basis.IDENTITY, EYE_COLLISION_POSITION) or _box.size != EYE_SIZE:
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


func _read_native_body_properties() -> Dictionary:
	# Retain native CharacterBody properties even though this actor never calls
	# move_and_slide. Changing physical registration cannot alter the source's
	# admitted stationary definition or silently introduce platform carry.
	if not is_instance_valid(_box): return {}
	return {"priority": collision_priority, "safe_margin": safe_margin, "up": Codec.vector3(up_direction), "floor_snap": floor_snap_length, "motion_mode": motion_mode, "floor_max_angle": floor_max_angle, "floor_stop_on_slope": floor_stop_on_slope, "floor_constant_speed": floor_constant_speed, "floor_block_on_wall": floor_block_on_wall, "slide_on_ceiling": slide_on_ceiling, "max_slides": max_slides, "wall_min_slide_angle": wall_min_slide_angle, "platform_floor_layers": platform_floor_layers, "platform_wall_layers": platform_wall_layers, "platform_on_leave": platform_on_leave, "locks": [axis_lock_linear_x, axis_lock_linear_y, axis_lock_linear_z, axis_lock_angular_x, axis_lock_angular_y, axis_lock_angular_z], "process_mode": process_mode, "process_priority": process_priority, "process_physics_priority": process_physics_priority, "shape_margin": _box.margin, "shape_bias": _box.custom_solver_bias}


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


func _exact_same(left: Variant, right: Variant) -> bool:
	# Shared56 packets retain scalar types and original float64 representations.
	# ExactJson also rejects Objects, StringName keys and nonfinite transport.
	var left_wire: String = ExactJson.stringify(left)
	return not left_wire.is_empty() and left_wire == ExactJson.stringify(right)


func _reject(reason: String) -> bool:
	last_error = reason
	return false


func _exit_tree() -> void:
	_retiring = true
	_opening_provider = Callable()
