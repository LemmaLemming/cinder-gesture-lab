extends "res://scripts/campaign/level.gd"
## TEST ONLY installed-topology constructor fixture. The future resource is
## not a spore field, controller, scheduler lease or authored campaign content.
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const LOCAL_API: String = "test-only-restore-candidate-local-1"
const RECIPIENT_ID: String = "test-only/dormant-recipient"
const FIELD_ID: String = "test-only/future-room-resource"
const RECIPIENT_POSITION: Vector3 = Vector3(2.0, 0.0, 2.0)
const BODY_SIZE: Vector3 = Vector3(0.6, 1.2, 0.5)
const RESOURCE_POSITION: Vector3 = Vector3(2.0, 0.03, 2.0)
const RESOURCE_SIZE: Vector3 = Vector3(0.4, 0.06, 0.4)

signal room_installed(room: int)

static var constructed_ids: Array[int] = []
static var destroyed_ids: Array[int] = []
static var restore_entry_ids: Array[int] = []
static var normal_entry_ids: Array[int] = []

class Recipient extends CharacterBody3D:
	signal damaged(amount: float)
	signal defeated()
	var hp: float = 8.0
	var dead: bool = false
	var hit_count: int = 0
	var clock_s: float = 0.0
	var damaged_at_s: Variant = null
	var field_id: String = ""
	var field_owner: MeshInstance3D
	var actual_hero: WeakRef
	var body_collision: CollisionShape3D
	var body_shape: BoxShape3D
	var damage_notifications: int = 0
	var defeat_notifications: int = 0

	func _ready() -> void:
		collision_layer = 2
		collision_mask = 1
		body_collision = CollisionShape3D.new()
		body_collision.name = "ImmutableBodyCollision"
		body_shape = BoxShape3D.new()
		body_shape.size = Vector3(0.6, 1.2, 0.5)
		body_collision.shape = body_shape
		body_collision.position = Vector3(0.0, 0.6, 0.0)
		add_child(body_collision)

	func bind_actual_player(value: CinderPlayer) -> bool:
		if actual_hero != null or not is_node_ready() or not is_instance_valid(value) or value.get_world_3d() != get_world_3d():
			return false
		actual_hero = weakref(value)
		return true

	func bind_future_resource(value: MeshInstance3D) -> bool:
		if field_owner != null or not is_instance_valid(value) or not value.is_node_ready() or value.get_world_3d() != get_world_3d():
			return false
		field_owner = value
		field_id = "test-only/future-room-resource"
		return true

	func take_damage(amount: float) -> bool:
		if get_tree().paused or dead or not is_finite(amount) or amount <= 0.0:
			return false
		var actual_damage: float = minf(hp, amount)
		hp -= actual_damage
		hit_count += 1
		damaged_at_s = clock_s
		dead = hp == 0.0
		damage_notifications += 1
		damaged.emit(actual_damage)
		if dead:
			defeat_notifications += 1
			defeated.emit()
		return true

	func native_error() -> String:
		if not is_inside_tree() or not is_node_ready() or is_queued_for_deletion() or actual_hero == null:
			return "Real ready recipient and bound shared Player required"
		var player: Variant = actual_hero.get_ref()
		if not is_instance_valid(player) or not player is CinderPlayer or not player.is_inside_tree() or player.get_world_3d() != get_world_3d():
			return "Actual recipient Player binding changed"
		if not is_instance_valid(body_collision) or body_collision.get_parent() != self or body_collision.shape != body_shape or body_shape.size != Vector3(0.6, 1.2, 0.5) or body_collision.position != Vector3(0.0, 0.6, 0.0) or body_collision.disabled or collision_layer != 2 or collision_mask != 1 or basis != Basis.IDENTITY:
			return "Immutable native Box body changed"
		if field_id.is_empty():
			return "" if field_owner == null else "Dormant recipient acquired an undeclared future resource"
		return "" if is_instance_valid(field_owner) and field_owner.is_inside_tree() and field_owner.get_world_3d() == get_world_3d() and field_id == "test-only/future-room-resource" else "Actual future resource binding was lost"

	func capture() -> Dictionary:
		return {"api_revision": "test-only-native-recipient-1", "source_id": "test-only/dormant-recipient", "body_size": [0.6, 1.2, 0.5], "position": Codec.vector3(global_position), "velocity": Codec.vector3(velocity), "hp": hp, "dead": dead, "hit_count": hit_count, "clock_s": clock_s, "damaged_at_s": damaged_at_s, "field_id": field_id}

	func snapshot_error(state: Dictionary) -> String:
		var error: String = Codec.keys_error(state, ["api_revision", "source_id", "body_size", "position", "velocity", "hp", "dead", "hit_count", "clock_s", "damaged_at_s", "field_id"])
		if not error.is_empty(): return error
		if state.api_revision != "test-only-native-recipient-1" or state.source_id != "test-only/dormant-recipient" or Exact.stringify(state.body_size) != Exact.stringify([0.6, 1.2, 0.5]) or not Codec.is_vector3(state.position) or Codec.read_vector3(state.position) != Vector3(2.0, 0.0, 2.0) or not Codec.is_vector3(state.velocity) or Codec.read_vector3(state.velocity) != Vector3.ZERO or not state.hp is float or not Codec.in_range(state.hp, 0.0, 8.0) or not state.dead is bool or state.dead != (state.hp == 0.0) or not state.hit_count is int or state.hit_count < 0 or state.hit_count > 1 or not state.clock_s is float or not Codec.in_range(state.clock_s, 0.0, 1000.0) or not state.field_id is String or state.field_id != field_id:
			return "Closed exact native recipient identity/body/lifecycle required"
		if state.hit_count == 0:
			if state.hp != 8.0 or state.dead or state.damaged_at_s != null: return "Pristine dormant recipient cannot invent damage"
		elif not state.damaged_at_s is float or not Codec.in_range(state.damaged_at_s, 0.0, state.clock_s) or state.hp >= 8.0:
			return "Actual hit retains original damage clock and resource change"
		return native_error()

	func restore_quiet(state: Dictionary) -> bool:
		if not get_tree().paused or not snapshot_error(state).is_empty(): return false
		global_position = Codec.read_vector3(state.position)
		velocity = Codec.read_vector3(state.velocity)
		hp = state.hp
		dead = state.dead
		hit_count = state.hit_count
		clock_s = state.clock_s
		damaged_at_s = state.damaged_at_s
		return true

var recipient: Recipient
var future_resource: MeshInstance3D
var future_mesh: BoxMesh
var room_index: int = 1
var prefix: Array = ["room-1"]
var clock_s: float = 0.0
var normal_entries: int = 0
var restore_entries: int = 0
var quiet_commits: int = 0
var activation_notifications: int = 0
var expected_saved_player_hp: float = -1.0
var player_hp_at_commit: float = -1.0
var constructor_pristine: bool = false
var constructor_progress_refused: bool = false
var commits_saw_candidate: bool = false


func _ready() -> void:
	constructed_ids.append(get_instance_id())
	process_physics_priority = 120


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		destroyed_ids.append(get_instance_id())


func restore_candidate_construction_required() -> bool:
	return true


func _on_enter_level() -> void:
	normal_entries += 1
	normal_entry_ids.append(get_instance_id())
	_build_recipient()


func _on_enter_restore_candidate(local: Dictionary, saved_player: Dictionary) -> String:
	restore_entries += 1
	restore_entry_ids.append(get_instance_id())
	if not is_restore_candidate() or recipient != null or normal_entries != 0:
		return "One fresh paused restore construction required"
	var error: String = _closed_topology_error(local)
	if not error.is_empty(): return error
	room_index = local.room_index
	prefix = local.prefix.duplicate()
	_build_recipient()
	if room_index == 2: _build_future_resource()
	expected_saved_player_hp = float(saved_player.resources.hp)
	constructor_pristine = recipient.hp == 8.0 and not recipient.dead and recipient.clock_s == 0.0 and clock_s == 0.0 and hero.hp == hero.max_hp
	constructor_progress_refused = not request_completion("constructor-complete") and not request_checkpoint("constructor-checkpoint") and not request_contact_exit("constructor-exit", hero)
	return _native_topology_error()


func _build_recipient() -> void:
	recipient = Recipient.new()
	recipient.name = "ActualReadyDormantRecipient"
	add_child(recipient)
	recipient.global_position = to_global(RECIPIENT_POSITION)
	recipient.bind_actual_player(hero)


func _build_future_resource() -> void:
	future_resource = MeshInstance3D.new()
	future_resource.name = "InstalledFutureRoomResource"
	future_mesh = BoxMesh.new()
	future_mesh.size = RESOURCE_SIZE
	future_resource.mesh = future_mesh
	add_child(future_resource)
	future_resource.position = RESOURCE_POSITION
	recipient.bind_future_resource(future_resource)


func open_future_room() -> bool:
	if is_restore_candidate() or get_tree().paused or recipient == null or room_index != 1:
		return false
	room_index = 2
	prefix.append("room-2")
	_build_future_resource()
	activation_notifications += 1
	room_installed.emit(room_index)
	return true


func _physics_process(delta: float) -> void:
	if recipient == null: return
	clock_s += delta
	recipient.clock_s += delta


func _capture_local_state() -> Dictionary:
	return {"api_revision": LOCAL_API, "schema_version": 1, "room_index": room_index, "prefix": prefix.duplicate(), "clock_s": clock_s, "recipient": recipient.capture(), "future_resource": _resource_state()}


func _resource_state() -> Variant:
	return null if room_index == 1 else {"resource_id": FIELD_ID, "recipient_id": RECIPIENT_ID, "position": Codec.vector3(RESOURCE_POSITION), "mesh_size": Codec.vector3(RESOURCE_SIZE)}


func _closed_topology_error(state: Dictionary) -> String:
	var error: String = Codec.keys_error(state, ["api_revision", "schema_version", "room_index", "prefix", "clock_s", "recipient", "future_resource"])
	if not error.is_empty(): return error
	if state.api_revision != LOCAL_API or not state.schema_version is int or state.schema_version != 1 or not state.room_index is int or state.room_index not in [1, 2] or not state.prefix is Array or not state.recipient is Dictionary or not state.clock_s is float or not Codec.in_range(state.clock_s, 0.0, 1000.0):
		return "Closed constructor topology/prefix/clock required"
	var expected_prefix: Array = ["room-1"] if state.room_index == 1 else ["room-1", "room-2"]
	if Exact.stringify(state.prefix) != Exact.stringify(expected_prefix): return "Installed room must retain the exact earned prefix"
	if state.room_index == 1:
		if state.future_resource != null: return "Dormant future resource must remain absent"
	else:
		var expected: Dictionary = {"resource_id": FIELD_ID, "recipient_id": RECIPIENT_ID, "position": Codec.vector3(RESOURCE_POSITION), "mesh_size": Codec.vector3(RESOURCE_SIZE)}
		if not state.future_resource is Dictionary or Exact.stringify(state.future_resource) != Exact.stringify(expected): return "Immutable future resource identity/definition differs"
	return ""


func _native_topology_error() -> String:
	if recipient == null or not is_instance_valid(recipient) or not recipient.is_node_ready() or recipient.get_parent() != self: return "Actual ready native recipient required"
	var error: String = recipient.native_error()
	if not error.is_empty(): return error
	if room_index == 1:
		return "" if future_resource == null and recipient.field_id.is_empty() else "Future resource exists in a dormant room"
	if not is_instance_valid(future_resource) or future_resource.get_parent() != self or future_resource.mesh != future_mesh or future_mesh.size != RESOURCE_SIZE or future_resource.position != RESOURCE_POSITION or future_resource.basis != Basis.IDENTITY or recipient.field_owner != future_resource:
		return "Installed immutable resource and actual recipient binding required"
	return ""


func _local_snapshot_error(state: Dictionary) -> String:
	# LITERALLY PURE: no counters, diagnostics, node writes or construction.
	var error: String = _closed_topology_error(state)
	if not error.is_empty(): return error
	if state.room_index != room_index: return "Construct saved topology before pure local validation"
	error = _native_topology_error()
	if error.is_empty(): error = recipient.snapshot_error(state.recipient)
	if error.is_empty() and Exact.stringify(state.clock_s) != Exact.stringify(state.recipient.clock_s): error = "Whole native unit keeps the exact same clock"
	return error


func _local_snapshot_error_with_player(state: Dictionary, _saved_player: Dictionary) -> String:
	return _local_snapshot_error(state)


func _restore_local_state(state: Dictionary) -> void:
	commits_saw_candidate = is_restore_candidate()
	player_hp_at_commit = hero.hp
	recipient.restore_quiet(state.recipient)
	clock_s = state.clock_s
	prefix = state.prefix.duplicate()
	quiet_commits += 1


func authority_state() -> Dictionary:
	return {"local": _capture_local_state(), "progress": {"completed": is_completed(), "checkpoint": current_checkpoint()}, "hero": hero.snapshot_state(), "recipient_instance": recipient.get_instance_id(), "shape_instance": recipient.body_shape.get_instance_id(), "body_transform": recipient.global_transform, "resource_instance": future_resource.get_instance_id() if is_instance_valid(future_resource) else 0, "mesh_instance": future_mesh.get_instance_id() if is_instance_valid(future_mesh) else 0, "normal_entries": normal_entries, "restore_entries": restore_entries, "quiet_commits": quiet_commits, "activation_notifications": activation_notifications, "damage_notifications": recipient.damage_notifications, "defeat_notifications": recipient.defeat_notifications}
