class_name CinderAct3GardenRootTether
extends StaticBody3D
## B05 physical root network only. The distant likeness is separate scenery.
## The caller supplies actual native recovery custody; this target has no timer.

signal state_changed(current: Dictionary)

const MAX_HP: float = 60.0
const PHASE_BOUNDARY: float = 30.0
const BODY_SIZE: Vector3 = Vector3(0.34, 0.36, 0.34)
const FIXED_POSITION: Vector3 = Vector3(1, 0, 0)

const PersistenceCodec = preload("res://scripts/campaign/snapshot_codec.gd")
const SNAPSHOT_API_REVISION: String = "act3-garden-root-tether-1"
const SNAPSHOT_SCHEMA_VERSION: int = 1
const STABLE_ID: String = "l4-garden-tether"
const MAX_SNAPSHOT_CLOCK_S: float = 1000000000.0
const SNAPSHOT_KEYS: Array[String] = ["api_revision", "schema_version", "stable_id", "position", "clock_s", "hp", "max_hp", "phase", "dead", "collision"]
var hp: float = MAX_HP
var max_hp: float = MAX_HP
var phase: int = 1
var dead: bool = false
var _open_provider: Callable
var _boundary_provider: Callable
var _configured: bool = false
var _mutating: bool = false
var _body: CollisionShape3D
var _views: Array[MeshInstance3D] = []
var _materials: Array[StandardMaterial3D] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 2
	collision_mask = 1
	_body = CollisionShape3D.new()
	_body.name = "RootCollision"
	var shape := BoxShape3D.new()
	shape.size = BODY_SIZE
	_body.shape = shape
	_body.position.y = BODY_SIZE.y * 0.5
	add_child(_body)
	_make_box("RootBody", BODY_SIZE, Vector3(0, 0.18, 0), Color("46334e"))
	_make_box("TetherBand", Vector3(0.42, 0.08, 0.42), Vector3(0, 0.08, 0), Color("74616f"))


func configure(open_provider: Callable, boundary_provider: Callable) -> bool:
	if _configured or not is_inside_tree() or not is_node_ready() or global_position != FIXED_POSITION or not open_provider.is_valid() or open_provider.get_argument_count() != 0 or not boundary_provider.is_valid() or boundary_provider.get_argument_count() != 0:
		return false
	_open_provider = open_provider
	_boundary_provider = boundary_provider
	_configured = true
	add_to_group("enemies")
	return true


func take_damage(amount: float, impulse: Vector3) -> Dictionary:
	var alive_before: bool = _configured and not dead and hp > 0.0
	var result: Dictionary = {"accepted": false, "hp_damage": 0.0, "target_id": get_instance_id(), "target_alive_before_hit": alive_before}
	if not alive_before or _mutating or get_tree().paused or not is_finite(amount) or amount <= 0.0 or not impulse.is_finite() or not runtime_error().is_empty() or not _open_provider.is_valid():
		return result
	# Lock before the caller's native lease read can notify observers/reenter.
	_mutating = true
	var old_hp: float = hp
	var old_phase: int = phase
	var authorized: Variant = _open_provider.call()
	if not authorized is bool or not authorized or get_tree().paused or not _configured or dead or hp != old_hp or phase != old_phase or not runtime_error().is_empty():
		_mutating = false
		return result
	var lower: float = PHASE_BOUNDARY if phase == 1 else 0.0
	hp = maxf(lower, hp - amount)
	result.accepted = hp < old_hp
	result.hp_damage = old_hp - hp
	if hp == lower:
		# Commit closed phase/lifecycle before parent cancellation and observers.
		phase = 2 if lower > 0.0 else 3
		dead = hp == 0.0
		if dead:
			collision_layer = 0
			collision_mask = 0
			_body.set_deferred("disabled", true)
			remove_from_group("enemies")
		_boundary_provider.call()
	present()
	state_changed.emit(state())
	_mutating = false
	return result


func state() -> Dictionary:
	return {"hp": hp, "max_hp": max_hp, "phase": phase, "dead": dead, "position": global_position, "open": _configured and not dead and _open_provider.is_valid() and bool(_open_provider.call())}


func present() -> void:
	var open: bool = _configured and not dead and _open_provider.is_valid() and bool(_open_provider.call())
	_materials[0].albedo_color = Color("201d29") if dead else Color("46334e")
	_materials[1].albedo_color = Color("514650") if dead else (Color("e5dece") if open else Color("74616f"))


func framing_points() -> Array:
	var points: Array = []
	for view: MeshInstance3D in _views:
		if is_instance_valid(view) and view.mesh != null:
			var box: AABB = view.mesh.get_aabb()
			for index: int in range(8):
				points.append(view.global_transform * box.get_endpoint(index))
	return points


func runtime_error() -> String:
	if not _configured or not is_inside_tree() or is_queued_for_deletion() or not is_visible_in_tree() or global_transform != Transform3D(Basis.IDENTITY, FIXED_POSITION) or not is_instance_valid(_body) or _body.get_parent() != self or not _body.shape is BoxShape3D or (_body.shape as BoxShape3D).size != BODY_SIZE or _body.transform != Transform3D(Basis.IDENTITY, Vector3(0, 0.18, 0)):
		return "Actual fixed low tether body required"
	if not is_finite(hp) or dead != (hp == 0.0) or phase != (3 if dead else (1 if hp > PHASE_BOUNDARY else 2)) or hp < 0.0 or hp > MAX_HP or max_hp != MAX_HP:
		return "Monotonic tether HP and phase must agree"
	if not dead and (collision_layer != 2 or collision_mask != 1 or _body.disabled or not is_in_group("enemies")):
		return "Living tether must retain its physical ordinary target"
	for index: int in range(_views.size()):
		var view: MeshInstance3D = _views[index]
		var size: Vector3 = BODY_SIZE if index == 0 else Vector3(0.42, 0.08, 0.42)
		var at: Vector3 = Vector3(0, 0.18, 0) if index == 0 else Vector3(0, 0.08, 0)
		if not is_instance_valid(view) or view.get_parent() != self or not view.is_visible_in_tree() or not view.mesh is BoxMesh or (view.mesh as BoxMesh).size != size or view.transform != Transform3D(Basis.IDENTITY, at) or view.material_override != _materials[index] or view.layers != 1 or view.transparency != 0.0 or view.material_overlay != null or view.visibility_range_begin != 0.0 or view.visibility_range_end != 0.0 or view.top_level:
			return "Complete closed/exposed/spent low tether rendering required"
		var material: StandardMaterial3D = _materials[index]
		if material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.no_depth_test:
			return "Opaque nearest depth-tested low tether required"
	return ""


func _make_box(label: String, size: Vector3, at: Vector3, color: Color) -> void:
	var view := MeshInstance3D.new()
	view.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	view.mesh = mesh
	view.position = at
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.albedo_color = color
	view.material_override = material
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(view)
	_views.append(view)
	_materials.append(material)


func _exit_tree() -> void:
	_open_provider = Callable()
	_boundary_provider = Callable()


## Pure boundary diagnostic. The parent still owns the complete paired proof.
## In particular, an original deferred death-disable must have really settled.
func snapshot_access_error() -> String:
	if not _configured or not is_inside_tree() or not is_node_ready() or is_queued_for_deletion() or not get_tree().paused or _mutating:
		return "Tether snapshots require the completed paused barrier outside damage callbacks"
	if not _open_provider.is_valid() or not _boundary_provider.is_valid() or _open_provider.get_argument_count() != 0 or _boundary_provider.get_argument_count() != 0:
		return "Retained actual target providers required"
	if _views.size() != 2 or _materials.size() != 2:
		return "Exactly two retained native tether render parts required"
	if get_node_or_null("RootCollision") != _body or not is_instance_valid(_body) or not _body.is_inside_tree() or not _body.is_node_ready() or _body.is_queued_for_deletion() or _body.get_script() != null:
		return "Original ready native tether collision child required"
	for index: int in range(2):
		var view: MeshInstance3D = _views[index]
		var material: StandardMaterial3D = _materials[index]
		var label: String = "RootBody" if index == 0 else "TetherBand"
		if not is_instance_valid(view) or view.is_queued_for_deletion() or not view.is_inside_tree() or not view.is_node_ready() or get_node_or_null(label) != view or view.get_script() != null or not is_instance_valid(material) or material.get_script() != null:
			return "Retained native tether view and material required"
	var error: String = runtime_error()
	if not error.is_empty():
		return error
	if collision_layer != (0 if dead else 2) or collision_mask != (0 if dead else 1) or _body.disabled != dead or is_in_group("enemies") != (not dead):
		return "Actual settled tether collision and target group must match its lifecycle"
	for index: int in range(2):
		var view: MeshInstance3D = _views[index]
		var material: StandardMaterial3D = _materials[index]
		for surface: int in range(view.get_surface_override_material_count()):
			if view.get_surface_override_material(surface) != null:
				return "Native tether surface material override is unsupported"
		if view.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF or material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED or material.grow or material.get_flag(BaseMaterial3D.FLAG_FIXED_SIZE) or material.albedo_texture != null or material.next_pass != null:
			return "Fixed opaque native tether rendering required"
	var body_color: Color = Color("201d29") if dead else Color("46334e")
	if _materials[0].albedo_color != body_color:
		return "Native tether body must retain its derived living/spent palette"
	var band: Color = _materials[1].albedo_color
	if (dead and band != Color("514650")) or (not dead and band not in [Color("74616f"), Color("e5dece")]):
		return "Native tether band must retain a supported closed/exposed/spent palette"
	return ""


## Pure target writer. clock_s is the parent's actual independently paired
## Scheduler clock: this physical target has no second timer or lease ledger.
## No provider, state(), present(), diagnostic write or signal is invoked.
func snapshot_state(clock_s: float) -> Dictionary:
	if not snapshot_access_error().is_empty() or not PersistenceCodec.in_range(clock_s, 0.0, MAX_SNAPSHOT_CLOCK_S):
		return {}
	var packet: Dictionary = {
		"api_revision": SNAPSHOT_API_REVISION, "schema_version": SNAPSHOT_SCHEMA_VERSION,
		"stable_id": STABLE_ID, "position": PersistenceCodec.vector3(global_position),
		"clock_s": clock_s, "hp": hp, "max_hp": max_hp, "phase": phase, "dead": dead,
		"collision": {"enabled": not _body.disabled, "layer": collision_layer, "mask": collision_mask},
	}
	return packet.duplicate(true) if snapshot_error(packet, clock_s).is_empty() else {}


## Pure saved target proof against the caller's independently checked clock.
## Current native target state must be coherent; saved earlier HP need not equal
## current HP. The parent joins this packet to real mechanisms/phase history.
func snapshot_error(packet: Dictionary, paired_clock_s: float) -> String:
	var error: String = snapshot_access_error()
	if not error.is_empty():
		return error
	return _persistence_fields_error(packet, paired_clock_s)


func _persistence_fields_error(packet: Dictionary, paired_clock_s: float) -> String:
	var error: String = PersistenceCodec.value_error(packet)
	if error.is_empty():
		error = PersistenceCodec.keys_error(packet, SNAPSHOT_KEYS)
	if not error.is_empty():
		return error
	if packet.api_revision != SNAPSHOT_API_REVISION or not PersistenceCodec.is_integer(packet.schema_version, SNAPSHOT_SCHEMA_VERSION, SNAPSHOT_SCHEMA_VERSION) or packet.stable_id != STABLE_ID or not PersistenceCodec.is_vector3(packet.position):
		return "Closed fixed tether identity/schema/position required"
	# Compare encoded scalar components before Vector3 conversion, so a forged
	# small offset cannot disappear through native float32 reconstruction.
	var fixed: Array = PersistenceCodec.vector3(FIXED_POSITION)
	for index: int in range(3):
		if float(packet.position[index]) != float(fixed[index]):
			return "Saved tether must retain its exact immutable native position"
	if not PersistenceCodec.in_range(paired_clock_s, 0.0, MAX_SNAPSHOT_CLOCK_S) or not PersistenceCodec.in_range(packet.clock_s, 0.0, MAX_SNAPSHOT_CLOCK_S) or float(packet.clock_s) != paired_clock_s:
		return "Tether and independently paired Scheduler clocks differ"
	if not PersistenceCodec.in_range(packet.hp, 0.0, MAX_HP) or not PersistenceCodec.is_number(packet.max_hp) or float(packet.max_hp) != MAX_HP or not PersistenceCodec.is_integer(packet.phase, 1, 3) or not packet.dead is bool:
		return "Finite tether HP and immutable capacity required"
	var saved_hp: float = float(packet.hp)
	var saved_dead: bool = saved_hp == 0.0
	var saved_phase: int = 3 if saved_dead else (1 if saved_hp > PHASE_BOUNDARY else 2)
	if packet.dead != saved_dead or int(packet.phase) != saved_phase:
		return "Tether phase and death must derive exactly from saved HP"
	if not packet.collision is Dictionary or not PersistenceCodec.keys_error(packet.collision, ["enabled", "layer", "mask"]).is_empty() or not packet.collision.enabled is bool or not PersistenceCodec.is_integer(packet.collision.layer, 0, 2) or not PersistenceCodec.is_integer(packet.collision.mask, 0, 1):
		return "Closed native tether collision flags required"
	if packet.collision.enabled != (not saved_dead) or int(packet.collision.layer) != (0 if saved_dead else 2) or int(packet.collision.mask) != (0 if saved_dead else 1):
		return "Saved tether collision must match its actual living/dead lifecycle"
	return ""


## Whole parent already prevalidated its Hero/target/Scheduler/mechanisms.
## Apply this actual physical target BEFORE Scheduler/mechanism commit, without
## yield, providers, damage/boundary calls, admission, deferred flags or events.
## This method has no independent Scheduler: the paired clock was checked by
## snapshot_error(packet, actual_saved_scheduler_clock) in whole prevalidation.
func apply_validated_state(packet: Dictionary) -> bool:
	if not snapshot_access_error().is_empty() or not PersistenceCodec.is_number(packet.get("clock_s")):
		return false
	if not _persistence_fields_error(packet, float(packet.clock_s)).is_empty():
		return false
	_mutating = true
	hp = float(packet.hp)
	max_hp = float(packet.max_hp)
	phase = int(packet.phase)
	dead = packet.dead
	collision_layer = int(packet.collision.layer)
	collision_mask = int(packet.collision.mask)
	_body.disabled = not packet.collision.enabled
	if dead:
		remove_from_group("enemies")
	else:
		add_to_group("enemies")
	# Safe derived phase colors during the atomic commit. The parent's checked
	# actual recovery association supplies exposed color AFTER native restore.
	_persistence_palette(false)
	_mutating = false
	return true


## Paused quiet presentation only. The parent supplies a bool derived from the
## real restored native lease/recovery and accepted cycle/phase association.
## It is not a serialized open stamp, provider substitute or damage permission.
## Existing live present()/take_damage() remain byte-identical and authoritative.
func present_checked_exposure(logical_exposed: bool) -> bool:
	if not snapshot_access_error().is_empty() or (logical_exposed and dead):
		return false
	_persistence_palette(logical_exposed)
	return true


func _persistence_palette(logical_exposed: bool) -> void:
	_materials[0].albedo_color = Color("201d29") if dead else Color("46334e")
	_materials[1].albedo_color = Color("514650") if dead else (Color("e5dece") if logical_exposed else Color("74616f"))
