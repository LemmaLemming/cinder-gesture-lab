extends CinderLevel
## INERT SOURCE DRAFT: actual Shell Hero + retained native ordinary-lunge owner.
## Planned TEST path: tests/acts/act2/shared_support/fresh_world_lunge_level.gd.
## In-memory A1-L1 row only; no canonical registration or Act 1 content changes.
## Shared56 has no raw readiness phase. The documented opt-in is not published.
## No parser, native, performance, art or original 803/804 repair credit.

const PlayerScript = preload("res://scripts/player.gd")
const SchedulerScript = preload("res://scripts/combat/threat_scheduler.gd")
const DifficultyScript = preload("res://scripts/combat/difficulty.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const ENCOUNTER_ID: String = "fresh-world-native-lunge-shell-test"
const WORLD_REVISION: int = 1
const SOURCE_ID: String = "retained-lunger"
const HERO_ID: String = "hero"
const FLOOR_ID: String = "main-floor"
const CHECKPOINT_ID: String = "fresh-world-idle-native-checkpoint"
const LOCAL_API: String = "fresh-world-lunge-shell-local-1"
const SOURCE_API: String = "fresh-world-retained-lunger-1"
const FLOOR_RECT: Rect2 = Rect2(-10.0, -10.0, 20.0, 20.0)
const SOURCE_POSITION: Vector3 = Vector3(-3.0, 0.0, 0.0)
const LOCAL_KEYS: Array[String] = ["api_revision", "schema_version", "encounter_id", "world_revision", "profile_id", "checkpoint_requested", "source", "scheduler"]
const SOURCE_KEYS: Array[String] = ["api_revision", "source_id", "hp", "dead", "damage_calls", "death_count", "accepted_lunges", "native_clock_s", "position", "velocity", "visible", "collision"]
const COLLISION_KEYS: Array[String] = ["collision_path", "enabled", "layer", "mask"]

class RetainedLunger:
	extends CharacterBody3D
	signal defeated
	var hp: float = 12.0
	var dead: bool = false
	var damage_calls: int = 0
	var death_count: int = 0
	var accepted_lunges: int = 0
	var scheduler: CinderThreatScheduler

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		add_to_group("enemies")

	func take_damage(amount: float, _impulse: Vector3) -> Dictionary:
		# Same test-source policy as staged_lunge_collision: true HP, no knockback
		# motion. The Scheduler alone leases source movement; death retires it.
		damage_calls += 1
		var was_alive: bool = not dead and hp > 0.0
		var result := {"accepted": false, "hp_damage": 0.0, "target_id": get_instance_id(), "target_alive_before_hit": was_alive}
		if not was_alive or not is_finite(amount) or amount <= 0.0: return result
		var before: float = hp
		hp = maxf(0.0, hp - amount)
		result["accepted"] = true
		result["hp_damage"] = before - hp
		if hp == 0.0:
			dead = true
			death_count += 1
			scheduler.cancel_owner(self, "source_defeated")
			velocity = Vector3.ZERO
			collision_layer = 0
			collision_mask = 0
			(get_node("BodyCollision") as CollisionShape3D).set_deferred("disabled", true)
			remove_from_group("enemies")
			visible = false
			defeated.emit()
		return result

var runtime_error: String = ""
var normal_entries: int = 0
var restore_entries: int = 0
var quiet_commits: int = 0
var constructor_pristine: bool = false
var saved_player_checked_before_binding: bool = false
var player_committed_before_local: bool = false
var _profile_id: String = "standard"
var _checkpoint_requested: bool = false
var _bound: bool = false
var _world_ref: WeakRef
var _expected_player_text: String = ""
var _floor: StaticBody3D
var _support: CollisionShape3D
var _floor_shape: BoxShape3D
var _wall: StaticBody3D
var _wall_collision: CollisionShape3D
var _wall_shape: BoxShape3D
var _scheduler: CinderThreatScheduler
var _source: RetainedLunger
var _source_collision: CollisionShape3D
var _source_shape: CapsuleShape3D
var _source_radius: float
var _source_height: float
var _source_safe_margin: float
var _source_shape_margin: float
var _source_solver_bias: float

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	# Permanent native floor is present BEFORE Shell raw-world preparation and
	# the sole synchronous restore entry. No floor is installed in that hook.
	_floor = StaticBody3D.new()
	_floor.name = "Floor"
	_floor.collision_layer = 1
	_floor.collision_mask = 0
	_floor.position = Vector3(0.0, -0.5, 0.0)
	_support = CollisionShape3D.new()
	_support.name = "Support"
	_floor_shape = BoxShape3D.new()
	_floor_shape.size = Vector3(20.0, 1.0, 20.0)
	_support.shape = _floor_shape
	_floor.add_child(_support)
	add_child(_floor)
	# Original staged-lunge wall recipe makes the real native sweep shorten.
	_wall = StaticBody3D.new()
	_wall.name = "Wall"
	_wall.collision_layer = 1
	_wall.collision_mask = 0
	_wall.position = Vector3(-0.5, 1.0, 0.0)
	_wall_collision = CollisionShape3D.new()
	_wall_collision.name = "Solid"
	_wall_shape = BoxShape3D.new()
	_wall_shape.size = Vector3(0.2, 2.0, 5.0)
	_wall_collision.shape = _wall_shape
	_wall.add_child(_wall_collision)
	add_child(_wall)
	_scheduler = SchedulerScript.new() as CinderThreatScheduler
	_scheduler.name = "NativeLungeScheduler"
	add_child(_scheduler)
	_source = RetainedLunger.new()
	_source.name = "RetainedLunger"
	_source.collision_layer = 2
	_source.collision_mask = 1
	_source.position = SOURCE_POSITION
	_source.scheduler = _scheduler
	_source_collision = CollisionShape3D.new()
	_source_collision.name = "BodyCollision"
	_source_shape = CapsuleShape3D.new()
	_source_shape.radius = 0.27
	_source_shape.height = 1.1
	_source_collision.shape = _source_shape
	_source_collision.position.y = 0.555
	_source.add_child(_source_collision)
	add_child(_source)
	# Retain actual native property values, including engine scalar precision.
	_source_radius = _source_shape.radius
	_source_height = _source_shape.height
	_source_safe_margin = _source.safe_margin
	_source_shape_margin = _source_shape.margin
	_source_solver_bias = _source_shape.custom_solver_bias

func restore_candidate_construction_required() -> bool:
	return true

func restore_candidate_physics_registration_required() -> bool:
	# Additive pure opt-in documented at FRESH_WORLD_RESTORE.md. Root owns the
	# paused raw preparation and exact complete-packet custody implementation.
	return true

func _on_enter_level() -> void:
	normal_entries += 1
	var selected: String = "standard"
	if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference"):
		selected = String(shared_shell.call("get_difficulty_preference"))
	runtime_error = _bind_runtime(selected)

func _on_enter_restore_candidate(local: Dictionary, saved_player: Dictionary) -> String:
	restore_entries += 1
	if restore_entries != 1 or normal_entries != 0 or quiet_commits != 0 or _bound or not is_restore_candidate(): return "One fresh synchronous restore entry required"
	# Complete actual shared Player schema precedes the Scheduler constructor
	# check. No saved Player/source/HP/pose/clock is applied in construction.
	var error: String = hero.snapshot_error(saved_player)
	if not error.is_empty(): return error
	saved_player_checked_before_binding = true
	error = _header_error(local)
	if error.is_empty(): error = _source_packet_error(local.source)
	if not error.is_empty(): return error
	constructor_pristine = _source.hp == 12.0 and not _source.dead and _source.damage_calls == 0 and _source.death_count == 0 and _source.accepted_lunges == 0 and _source.global_position == SOURCE_POSITION and _source.velocity == Vector3.ZERO and _scheduler.get_clock() == 0.0
	if not constructor_pristine: return "Retained raw native source/Scheduler must remain pristine before sole entry"
	_expected_player_text = Exact.stringify(saved_player)
	error = _bind_runtime(String(local.profile_id))
	if not error.is_empty(): return error
	# Native analytic inset plus actual endpoint ray/RID validation remains in
	# Scheduler.snapshot_error. Never await, retry entry or relax those guards.
	return _whole_local_error(local, saved_player)

func _bind_runtime(profile_id: String) -> String:
	if _bound or profile_id not in ["assisted", "standard", "challenge"] or not _node_live(hero) or hero.get_script() != PlayerScript: return "Fresh actual supplied Shell Hero/profile required"
	var world: Node3D = _find_common_world(hero)
	if not _node_live(world): return "Actual common candidate stage must contain Hero, floor, source and Scheduler"
	_world_ref = weakref(world)
	_profile_id = profile_id
	if not _scheduler.begin_encounter(profile_id, ENCOUNTER_ID, WORLD_REVISION): return _scheduler.last_error
	_bound = true
	if not hero.died.is_connected(_on_hero_died): hero.died.connect(_on_hero_died)
	return _runtime_binding_error()

func _find_common_world(player: CinderPlayer) -> Node3D:
	var at: Node = self
	while is_instance_valid(at):
		if at is Node3D and _node_live(player) and _node_live(_scheduler) and _node_live(_source) and _node_live(_floor) and at.is_ancestor_of(player) and at.is_ancestor_of(_scheduler) and at.is_ancestor_of(_source) and at.is_ancestor_of(_floor): return at as Node3D
		at = at.get_parent()
	return null

func _world_node() -> Node3D:
	var value: Variant = _world_ref.get_ref() if _world_ref != null else null
	return value if _node_live(value) and value is Node3D else null

func _region() -> Dictionary:
	return {"collision": _support, "safe_rect": FLOOR_RECT}

func _bindings() -> Dictionary:
	return {"world_root": _world_node(), "owners": {SOURCE_ID: _source}, "floors": {FLOOR_ID: _region()}, "actors": {HERO_ID: hero}}

func get_source() -> CharacterBody3D:
	return _source if _node_live(_source) else null

func get_scheduler() -> CinderThreatScheduler:
	return _scheduler if _node_live(_scheduler) else null

func get_floor() -> StaticBody3D:
	return _floor if _node_live(_floor) else null

func get_support() -> CollisionShape3D:
	return _support if _node_live(_support) else null

func get_floor_shape() -> CollisionShape3D:
	return get_support()

func test_arena_for_player(player: CinderPlayer) -> Dictionary:
	var world: Node3D = _find_common_world(player)
	return {"root": world, "world_root": world, "hero": player, "source": get_source(), "scheduler": get_scheduler(), "floor": get_floor(), "support": get_support(), "wall": _wall, "region": _region(), "floor_region": _region(), "bound": _bound}

func test_arena() -> Dictionary:
	return test_arena_for_player(hero)

func test_start() -> Dictionary:
	if not _test_action_ready() or _source.dead or _source.accepted_lunges != 0: return {"accepted": false, "reason": "Living installed idle TEST native source required"}
	var role: Dictionary = DifficultyScript.new().resolve_role({"raw_damage": 10.0, "windup_s": 0.6, "lock_s": 0.2, "active_s": 0.5, "recovery_s": 1.2, "attack_interval_s": 1.6, "max_hp": 30.0, "move_speed": 2.6}, _profile_id, {"windup_s": 0.6, "lock_s": 0.2, "recovery_s": 1.2})
	var threat := {"role": role, "geometry": Geometry.circle(Vector3.ZERO, 0.8), "source_stationary": false, "opening_stationary": true, "opening_position": Vector3.ZERO, "cooldown_remaining_s": 0.0, "lunge": {"direction": Vector3.RIGHT, "speed": 8.0, "distance": 3.8, "damage_radius": 0.31}}
	# Keep the actual Shell Hero's grounded/motion/stats/action/cooldown values.
	# Add only authored environment and response directions; no stable=true.
	var response: Dictionary = hero.get_threat_response_state()
	response["world_revision"] = WORLD_REVISION
	response["recognition_s"] = 0.1
	response["attack_input_margin_s"] = 0.02
	response["escape_directions"] = [Vector3.FORWARD, Vector3.BACK]
	response["return_directions"] = [Vector3.FORWARD, Vector3.BACK]
	response["floor_regions"] = [_region()]
	response["world_root"] = _world_node()
	var result: Dictionary = _scheduler.request_lunge(_source, threat, response)
	if result.get("accepted", false): _source.accepted_lunges += 1
	return result

func test_checkpoint() -> bool:
	if not _test_action_ready(true) or _checkpoint_requested or _source.dead or _source.accepted_lunges != 0: return false
	var control: Dictionary = _scheduler.source_control_state(_source)
	if not control.get("reservations", []).is_empty() or control.get("cooldown") != null: return false
	_checkpoint_requested = true
	if request_checkpoint(CHECKPOINT_ID): return true
	_checkpoint_requested = false
	return false

func test_lunge_state() -> Dictionary:
	# The legacy reservation_state/reservations getters prune. This one is pure.
	return _scheduler.source_control_state(_source) if _node_live(_scheduler) and _node_live(_source) else {}

func transport_diagnostics() -> Dictionary:
	return {"normal_entries": normal_entries, "restore_entries": restore_entries, "quiet_commits": quiet_commits, "constructor_pristine": constructor_pristine, "saved_player_checked_before_binding": saved_player_checked_before_binding, "player_committed_before_local": player_committed_before_local, "source_clock_s": _scheduler.get_clock() if _node_live(_scheduler) else -1.0, "damage_calls": _source.damage_calls if _node_live(_source) else -1, "death_count": _source.death_count if _node_live(_source) else -1, "accepted_lunges": _source.accepted_lunges if _node_live(_source) else -1, "source_instance_id": str(_source.get_instance_id()) if _node_live(_source) else "", "scheduler_instance_id": str(_scheduler.get_instance_id()) if _node_live(_scheduler) else "", "floor_instance_id": str(_floor.get_instance_id()) if _node_live(_floor) else "", "floor_shape_instance_id": str(_floor_shape.get_instance_id()) if is_instance_valid(_floor_shape) else "", "world_instance_id": str(get_world_3d().get_instance_id()) if is_inside_tree() else ""}

func get_floor_diagnostics(packet: Dictionary = {}) -> Dictionary:
	# Read-only observations for Root's raw phase. Native guards remain the
	# authority: this is neither a readiness stamp nor continuous support proof.
	if not is_inside_tree() or not _node_live(_source) or not _node_live(_floor): return {"error": "Actual raw native nodes required"}
	if not packet.is_empty() and Exact.stringify(packet).is_empty(): return {"error": "Bounded plain diagnostic packet required"}
	var scheduler_packet: Dictionary = {}
	if not packet.is_empty():
		if packet.get("level") is Dictionary and packet.level.get("local") is Dictionary and packet.level.local.get("scheduler") is Dictionary: scheduler_packet = packet.level.local.scheduler
		elif packet.get("local") is Dictionary and packet.local.get("scheduler") is Dictionary: scheduler_packet = packet.local.scheduler
		elif packet.get("scheduler") is Dictionary: scheduler_packet = packet.scheduler
		elif packet.get("reservations") is Array and packet.get("schema_version") == 1: scheduler_packet = packet
		else: return {"error": "Complete Shell unit, Level, local or native Scheduler diagnostic packet required"}
	var observation_scope: String = "current-source-only"
	var points: Array[Vector3] = [_source.global_position]
	var records: Variant = scheduler_packet.get("reservations", [])
	if not records is Array or records.size() > 1: return {"error": "At most one native fixture lunge required"}
	if not records.is_empty():
		var record: Variant = records[0]
		if not record is Dictionary or not record.get("adapter") is Dictionary or record.adapter.get("kind") != "lunge" or not Codec.is_vector3(record.adapter.get("start")) or not Codec.is_vector3(record.adapter.get("planned_endpoint")): return {"error": "Exact saved native lunge endpoints required"}
		points = [Codec.read_vector3(record.adapter.start), Codec.read_vector3(record.adapter.planned_endpoint)]
		observation_scope = "saved-lunge-endpoints"
	var rays: Array[Dictionary] = []
	for point: Vector3 in points:
		var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.2, point - Vector3.UP * 0.2, 1)
		var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		rays.append({"point": Codec.vector3(point), "empty": hit.is_empty(), "hit_rid": str(hit.get("rid", RID())), "matches_floor_rid": not hit.is_empty() and hit.get("rid") == _floor.get_rid()})
	return {"api_revision": "fresh-world-floor-observation-1", "observation_scope": observation_scope, "paused": get_tree().paused, "entered": _entered, "restore_entries": restore_entries, "world_instance_id": str(get_world_3d().get_instance_id()), "space_rid": str(get_world_3d().space), "floor_rid": str(_floor.get_rid()), "source_rid": str(_source.get_rid()), "source_position": Codec.vector3(_source.global_position), "source_velocity": Codec.vector3(_source.velocity), "source_clock_s": _scheduler.get_clock(), "rays": rays}

func _test_action_ready(allow_paused: bool = false) -> bool:
	return _bound and runtime_error.is_empty() and _entered and not _lifecycle_busy and not _state_hook_busy() and not _dispatching and not is_restore_candidate() and (allow_paused or not get_tree().paused) and _node_live(hero) and not hero.dead and _runtime_binding_error().is_empty()

func _runtime_binding_error() -> String:
	if not _bound or not _node_live(hero) or hero.get_script() != PlayerScript or not _node_live(_world_node()) or _find_common_world(hero) != _world_node() or transform != Transform3D.IDENTITY: return "Actual Shell Hero/common native stage changed"
	if not _node_live(_scheduler) or _scheduler.get_script() != SchedulerScript or _scheduler.get_parent() != self or _scheduler.transform != Transform3D.IDENTITY: return "Original native Scheduler recipient changed"
	if not _node_live(_source) or not _source is RetainedLunger or _source.get_parent() != self or _source.scheduler != _scheduler or _source.global_basis != Basis.IDENTITY or _source.safe_margin != _source_safe_margin or _source.axis_lock_linear_x or _source.axis_lock_linear_y or _source.axis_lock_linear_z or not _source.get_collision_exceptions().is_empty(): return "Original native source body/custody changed"
	if not _node_live(_source_collision) or _source.get_node_or_null("BodyCollision") != _source_collision or _source_collision.get_parent() != _source or _source_collision.position != Vector3(0.0, 0.555, 0.0) or _source_collision.basis != Basis.IDENTITY or _source_collision.shape != _source_shape or _source_shape.radius != _source_radius or _source_shape.height != _source_height or _source_shape.margin != _source_shape_margin or _source_shape.custom_solver_bias != _source_solver_bias: return "Original upright capsule resource changed"
	if _source.get_children().size() != 1 or _source.get_shape_owners().size() != 1: return "Original source owns exactly one registered capsule"
	var shape_owner: int = _source.get_shape_owners()[0]
	if _source.shape_owner_get_owner(shape_owner) != _source_collision or _source.shape_owner_get_shape_count(shape_owner) != 1 or _source.shape_owner_get_shape(shape_owner, 0) != _source_shape or _source.shape_owner_get_transform(shape_owner) != _source_collision.transform or _source.is_shape_owner_disabled(shape_owner) != _source_collision.disabled: return "Source registered shape and node lifecycle disagree"
	if _source_collision.disabled != _source.dead or _source.collision_layer != (0 if _source.dead else 2) or _source.collision_mask != (0 if _source.dead else 1) or _source.visible != (not _source.dead) or _source.is_in_group("enemies") != (not _source.dead): return "Actual retained source HP/body/visibility lifecycle differs"
	if not _node_live(_floor) or _floor.get_parent() != self or _floor.position != Vector3(0.0, -0.5, 0.0) or _floor.basis != Basis.IDENTITY or _floor.collision_layer != 1 or _floor.collision_mask != 0 or _floor.get_children().size() != 1: return "Original immutable native floor changed"
	if not _node_live(_support) or _support.get_parent() != _floor or _support.disabled or _support.transform != Transform3D.IDENTITY or _support.shape != _floor_shape or _floor_shape.size != Vector3(20.0, 1.0, 20.0): return "Original immutable floor box resource changed"
	if not _node_live(_wall) or _wall.get_parent() != self or _wall.position != Vector3(-0.5, 1.0, 0.0) or _wall.basis != Basis.IDENTITY or _wall.collision_layer != 1 or _wall.collision_mask != 0 or _wall.get_children().size() != 1: return "Original native shortening wall changed"
	if not _node_live(_wall_collision) or _wall_collision.get_parent() != _wall or _wall_collision.disabled or _wall_collision.transform != Transform3D.IDENTITY or _wall_collision.shape != _wall_shape or _wall_shape.size != Vector3(0.2, 2.0, 5.0): return "Original wall collision resource changed"
	for node: Node3D in [hero, _source, _scheduler, _floor, _wall]:
		if node.get_world_3d() != get_world_3d() or node.get_viewport() != get_viewport(): return "Retained nodes belong to the actual current candidate world/viewport"
	return ""

func _source_packet() -> Dictionary:
	return {"api_revision": SOURCE_API, "source_id": SOURCE_ID, "hp": _source.hp, "dead": _source.dead, "damage_calls": _source.damage_calls, "death_count": _source.death_count, "accepted_lunges": _source.accepted_lunges, "native_clock_s": _scheduler.get_clock(), "position": Codec.vector3(_source.global_position), "velocity": Codec.vector3(_source.velocity), "visible": _source.visible, "collision": {"collision_path": "BodyCollision", "enabled": not _source_collision.disabled, "layer": _source.collision_layer, "mask": _source.collision_mask}}

func _source_packet_error(state: Dictionary) -> String:
	if Exact.stringify(state).is_empty() or not Codec.keys_error(state, SOURCE_KEYS).is_empty() or state.get("api_revision") != SOURCE_API or state.get("source_id") != SOURCE_ID: return "Closed tagged original TEST source required"
	if not state.hp is float or not Codec.in_range(state.hp, 0.0, 12.0) or not state.dead is bool or state.dead != (state.hp == 0.0) or not state.visible is bool or state.visible != (not state.dead): return "True source HP/dead/visibility lifecycle required"
	if not state.damage_calls is int or not Codec.is_integer(state.damage_calls, 0, 1000000) or not state.death_count is int or state.death_count != (1 if state.dead else 0) or state.damage_calls < state.death_count or not state.accepted_lunges is int or not Codec.is_integer(state.accepted_lunges, 0, 1): return "Original bounded source action counters required"
	if not state.native_clock_s is float or not Codec.in_range(state.native_clock_s, 0.0, 1000000000.0) or not Codec.is_vector3(state.position) or not Codec.is_vector3(state.velocity): return "Exact native clock and finite source pose/velocity required"
	if Codec.read_vector3(state.position).length() > 1000.0 or Codec.read_vector3(state.velocity).length() > 100.0 or (state.dead and Codec.read_vector3(state.velocity) != Vector3.ZERO): return "Bounded source motion/death velocity required"
	if not state.collision is Dictionary or not Codec.keys_error(state.collision, COLLISION_KEYS).is_empty() or state.collision.collision_path != "BodyCollision" or not state.collision.enabled is bool or state.collision.enabled != (not state.dead) or not state.collision.layer is int or state.collision.layer != (0 if state.dead else 2) or not state.collision.mask is int or state.collision.mask != (0 if state.dead else 1): return "Actor-derived closed actual collision lifecycle required"
	return ""

func _header_error(state: Dictionary) -> String:
	if Exact.stringify(state).is_empty() or not Codec.keys_error(state, LOCAL_KEYS).is_empty(): return "Complete bounded Player-free closed TEST local required"
	if state.api_revision != LOCAL_API or not state.schema_version is int or state.schema_version != 1 or state.encounter_id != ENCOUNTER_ID or not state.world_revision is int or state.world_revision != WORLD_REVISION or state.profile_id not in ["assisted", "standard", "challenge"] or not state.checkpoint_requested is bool: return "Fixed TEST encounter/profile/world descriptor required"
	if not state.source is Dictionary or state.source.is_empty() or not state.scheduler is Dictionary or state.scheduler.is_empty(): return "Complete native source and Scheduler packets required"
	return ""

func _capture_local_state() -> Dictionary:
	if not get_tree().paused or not runtime_error.is_empty() or not _runtime_binding_error().is_empty(): return {}
	var scheduler_packet: Dictionary = _scheduler.snapshot_state(_bindings())
	if scheduler_packet.is_empty(): return {}
	return {"api_revision": LOCAL_API, "schema_version": 1, "encounter_id": ENCOUNTER_ID, "world_revision": WORLD_REVISION, "profile_id": _profile_id, "checkpoint_requested": _checkpoint_requested, "source": _source_packet(), "scheduler": scheduler_packet}

func _local_snapshot_error(state: Dictionary) -> String:
	return _whole_local_error(state, hero.snapshot_state() if _node_live(hero) else {})

func _local_snapshot_error_with_player(state: Dictionary, saved_player: Dictionary) -> String:
	return _whole_local_error(state, saved_player)

func _whole_local_error(state: Dictionary, saved_player: Dictionary) -> String:
	if not get_tree().paused or not runtime_error.is_empty(): return "Paused quiet whole native fixture required"
	var error: String = _runtime_binding_error()
	if not error.is_empty(): return error
	if Exact.stringify(saved_player).is_empty(): return "Complete bounded exact shared Player required"
	error = hero.snapshot_error(saved_player)
	if error.is_empty(): error = _header_error(state)
	if error.is_empty(): error = _source_packet_error(state.source)
	if not error.is_empty(): return error
	if state.profile_id != _profile_id: return "Saved profile must match freshly constructed native recipient"
	# Staged fields come solely from the independently validated Player/source,
	# never from the native Scheduler adapter or an invented floor signature.
	var staged: Dictionary = _bindings()
	staged["hero_positions"] = {HERO_ID: Codec.read_vector3(saved_player.motion.position)}
	staged["hero_action_clocks"] = {HERO_ID: saved_player.world_actions.clock_s}
	staged["owner_positions"] = {SOURCE_ID: Codec.read_vector3(state.source.position)}
	staged["owner_velocities"] = {SOURCE_ID: Codec.read_vector3(state.source.velocity)}
	if not state.source.dead: staged["owner_collision_states"] = {SOURCE_ID: state.source.collision.duplicate(true)}
	error = _scheduler.snapshot_error(state.scheduler, staged)
	if not error.is_empty(): return error
	if state.scheduler.get("schema_version") != 1 or state.scheduler.get("encounter_id") != ENCOUNTER_ID or state.scheduler.get("world_revision") != WORLD_REVISION or state.scheduler.get("profile", {}).get("id") != state.profile_id or state.source.native_clock_s != state.scheduler.get("clock_s") or state.source.accepted_lunges != state.scheduler.get("serial"): return "Exact original source/native clock/actions/epoch/profile required"
	if state.scheduler.reservations.size() > 1 or state.scheduler.cooldowns.size() > 1 or state.scheduler.has("replay_cancellations"): return "Closed single ordinary-lunge namespace required"
	for record: Dictionary in state.scheduler.reservations:
		if state.source.dead or record.get("source_id") != SOURCE_ID or record.get("adapter", {}).get("kind") != "lunge": return "Living genuine native lunge/source only"
	for cooldown: Dictionary in state.scheduler.cooldowns:
		if state.source.dead or cooldown.get("source_id") != SOURCE_ID: return "Original living source cooldown only"
	return ""

func _progress_error(snapshot: Dictionary) -> String:
	var state: Dictionary = snapshot.local
	var progress: Dictionary = snapshot.progress
	if progress.completed or progress.completion_id != "" or progress.contact_exit_id != "": return "This TEST does not complete or exit campaign content"
	var expected: Dictionary = {}
	if state.checkpoint_requested: expected[CHECKPOINT_ID] = "encounter"
	if progress.checkpoint_ids != expected or progress.checkpoint_id != (CHECKPOINT_ID if state.checkpoint_requested else "") or progress.checkpoint_kind != ("encounter" if state.checkpoint_requested else ""): return "Actual idle checkpoint metadata must join local latch"
	return ""

func snapshot_error(snapshot: Dictionary) -> String:
	var error: String = super.snapshot_error(snapshot)
	return _progress_error(snapshot) if error.is_empty() else error

func snapshot_error_with_player(snapshot: Dictionary, saved_player: Dictionary) -> String:
	var error: String = super.snapshot_error_with_player(snapshot, saved_player)
	return _progress_error(snapshot) if error.is_empty() else error

func restore_state(snapshot: Dictionary) -> bool:
	last_snapshot_error = snapshot_error(snapshot)
	if not last_snapshot_error.is_empty(): return false
	if not is_restore_candidate() or restore_entries != 1 or normal_entries != 0 or quiet_commits != 0:
		last_snapshot_error = "One pristine fresh candidate quiet commit required"; return false
	if _expected_player_text.is_empty() or Exact.stringify(hero.snapshot_state()) != _expected_player_text:
		last_snapshot_error = "Actual Shell Player must be committed before the local source"; return false
	var control: Dictionary = _scheduler.source_control_state(_source)
	if _source.accepted_lunges != 0 or not control.get("reservations", []).is_empty() or control.get("cooldown") != null or _scheduler.get_clock() != 0.0:
		last_snapshot_error = "Fresh native recipient cannot adopt an installed donor/history"; return false
	player_committed_before_local = true
	if not super.restore_state(snapshot): return false
	if not runtime_error.is_empty(): last_snapshot_error = runtime_error; return false
	var actual: Dictionary = _capture_local_state()
	if actual.is_empty() or Exact.stringify(actual) != Exact.stringify(snapshot.local):
		last_snapshot_error = "Quiet committed whole native local differs from validated exact packet"; return false
	return true

func _restore_local_state(state: Dictionary) -> void:
	# All Player/source/Scheduler fields and immutable bindings were preflighted.
	# Quiet source first, then ordinary Scheduler against actual committed body.
	_source.global_position = Codec.read_vector3(state.source.position)
	_source.velocity = Codec.read_vector3(state.source.velocity)
	_source.hp = state.source.hp
	_source.dead = state.source.dead
	_source.damage_calls = state.source.damage_calls
	_source.death_count = state.source.death_count
	_source.accepted_lunges = state.source.accepted_lunges
	_source.collision_layer = state.source.collision.layer
	_source.collision_mask = state.source.collision.mask
	_source_collision.disabled = not state.source.collision.enabled
	_source.visible = state.source.visible
	if _source.dead: _source.remove_from_group("enemies")
	else: _source.add_to_group("enemies")
	if not _scheduler.restore_state(state.scheduler, _bindings()):
		runtime_error = "Unexpected prevalidated native Scheduler commit refusal: " + _scheduler.last_snapshot_error; return
	_checkpoint_requested = state.checkpoint_requested
	quiet_commits += 1

func _on_hero_died() -> void:
	if _entered and not _state_hook_busy() and _node_live(_scheduler) and _node_live(_source): _scheduler.cancel_owner(_source, "hero_defeated")

func _on_exit_level() -> void:
	if is_instance_valid(hero) and hero.died.is_connected(_on_hero_died): hero.died.disconnect(_on_hero_died)
	if _node_live(_scheduler) and _node_live(_source): _scheduler.cancel_owner(_source, "test_level_exit")
	_bound = false
	_world_ref = null
	_expected_player_text = ""

static func _node_live(value: Variant) -> bool:
	return is_instance_valid(value) and value is Node and value.is_inside_tree() and value.is_node_ready() and not value.is_queued_for_deletion()
