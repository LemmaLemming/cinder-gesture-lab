class_name CinderAct3MirrorEcho
extends "res://scripts/combat/replay_playback.gd"
## C52's stationary, ordinary-primary knot owns one canonical authored cycle.
## Only its porcelain child travels. Admission/lock/camera belong to the level.

const SourceCodec = preload("res://scripts/acts/act3/mirror_echo_codec.gd")
const EnemyPlan = preload("res://scripts/combat/authored_enemy_sequence.gd")
const SourceValue = preload("res://scripts/campaign/snapshot_codec.gd")
const SOURCE_API: String = "authored-echo-source-1"
const OWNED_API: String = "act3-mirror-echo-source-1"
const MAX_SOURCE_HITS: int = 4096

signal source_hit_resolved(result: Dictionary)
signal source_defeated(result: Dictionary)
signal died


class PorcelainRenderer extends Node3D:
	var presentation: Dictionary = {}
	var required_visuals: Array[MeshInstance3D] = []
	var pose: Dictionary = {}

	func _ready() -> void:
		# Original filled porcelain body with a distinct fixed recovery knot.
		# Its harmless outlined reflection belongs to the level's scenery.
		var porcelain := Color(0.86, 0.86, 0.91, 1.0)
		var shade := Color(0.68, 0.67, 0.77, 1.0)
		_box("LeftFoot", Vector3(0.16, 0.10, 0.24), Vector3(-0.25, 0.05, -0.19), shade)
		_box("RightFoot", Vector3(0.16, 0.10, 0.24), Vector3(0.25, 0.05, -0.19), shade)
		_box("LeftFrame", Vector3(0.11, 0.47, 0.14), Vector3(-0.23, 0.295, -0.16), porcelain, 20.0)
		_box("RightFrame", Vector3(0.11, 0.47, 0.14), Vector3(0.23, 0.295, -0.16), porcelain, 20.0)
		_box("LowFrame", Vector3(0.48, 0.16, 0.20), Vector3(0, 0.47, -0.10), shade)
		_box("ShoulderFrame", Vector3(0.60, 0.13, 0.21), Vector3(0, 0.80, 0.15), porcelain, 15.0)
		_box("LeftHeadFrame", Vector3(0.065, 0.22, 0.23), Vector3(-0.17, 0.98, 0.235), porcelain, 12.0)
		_box("RightHeadFrame", Vector3(0.065, 0.22, 0.23), Vector3(0.17, 0.98, 0.235), porcelain, 12.0)
		_box("HeadCrown", Vector3(0.34, 0.075, 0.23), Vector3(0, 1.09, 0.235), porcelain, 12.0)
		_box("HeadSill", Vector3(0.34, 0.075, 0.23), Vector3(0, 0.875, 0.27), shade, 12.0)
		_box("LeftCuff", Vector3(0.11, 0.72, 0.16), Vector3(-0.34, 0.42, 0.245), porcelain, -15.0)
		_box("RightCuff", Vector3(0.11, 0.72, 0.16), Vector3(0.34, 0.42, 0.245), porcelain, -15.0)
		_box("LeftHand", Vector3(0.13, 0.13, 0.18), Vector3(-0.34, 0.065, 0.36), shade)
		_box("RightHand", Vector3(0.13, 0.13, 0.18), Vector3(0.34, 0.065, 0.36), shade)
		_box("FilledTorso", Vector3(0.34, 0.46, 0.22), Vector3(0, 0.64, 0.015), porcelain, 25.0)
		_box("FilledHead", Vector3(0.30, 0.22, 0.22), Vector3(0, 0.98, 0.235), porcelain, 12.0)

	func _box(label: String, size: Vector3, offset: Vector3, color: Color, pitch_degrees: float = 0.0) -> void:
		var visual := MeshInstance3D.new()
		visual.name = label
		var primitive := BoxMesh.new()
		primitive.size = size
		visual.mesh = primitive
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		material.albedo_color = color
		visual.material_override = material
		visual.position = offset
		visual.rotation.x = deg_to_rad(pitch_degrees)
		add_child(visual)
		required_visuals.append(visual)

	func get_authored_echo_render_bindings() -> Dictionary:
		return {"api_revision": "authored-echo-renderer-1", "presentation": presentation.duplicate(true), "required_visuals": required_visuals.duplicate()}

	func present_authored_echo_pose(value: Dictionary, _quiet: bool) -> bool:
		if not SourceValue.keys_error(value, ["position", "direction", "action", "progress"]).is_empty() or not value.position is Vector3 or not value.position.is_finite() or not value.direction is Vector3 or not value.direction.is_finite() or value.direction.y != 0.0 or absf(value.direction.length() - 1.0) > 0.000001 or value.action not in ["idle", "dash", "enemy_slash"] or not value.progress is float or not SourceValue.in_range(value.progress, 0.0, 1.0):
			return false
		global_position = value.position
		global_basis = Basis(Vector3.UP, atan2(float(value.direction.x), float(value.direction.z)))
		pose = value.duplicate(true)
		# No signals or child/resource mutations, including ordinary presents.
		return true

	func native_pose() -> Dictionary:
		return {"transform": global_transform, "pose": pose.duplicate(true), "visible": is_visible_in_tree()}


var hp: float = 0.0
var max_hp: float = 0.0
var dead: bool = false
var source_hits: int = 0
var defeated_at_s: Variant = null
var source_snapshot_error: String = ""
var _hit_receipts: Array[Dictionary] = []
var _native_definition: Dictionary = {}
var _native_program: Dictionary = {}
var _owned_source_id: String = ""
var _source_epoch: String = ""
var _source_generation: int = 0
var _knot: Vector3 = Vector3.ZERO
var _renderer: PorcelainRenderer
var _fixed_knot: MeshInstance3D
var _source_scheduler: CinderThreatScheduler
var _source_busy: int = 0
var _native_receipt: Dictionary = {}
var _native_handles: Array[Dictionary] = []
var _native_source_script: Script
var _native_renderer_script: Script
var _native_source_parent: Node
var _native_world: World3D
var _native_fault: String = ""
var _source_codec = SourceCodec.new()


func _ready() -> void:
	super._ready()
	_renderer = PorcelainRenderer.new()
	_renderer.name = "PorcelainOwnSequence"
	add_child(_renderer)
	_fixed_knot = MeshInstance3D.new()
	_fixed_knot.name = "FixedLowRecoveryKnot"
	var primitive := BoxMesh.new()
	primitive.size = Vector3(0.27, 0.24, 0.24)
	_fixed_knot.mesh = primitive
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.albedo_color = Color(0.16, 0.09, 0.25, 1.0)
	_fixed_knot.material_override = material
	_fixed_knot.position = Vector3(0, 0.12, 0.0)
	add_child(_fixed_knot)


func configure_source(source_id: String, source_epoch: String, generation: int, definition: Dictionary, profile_id: String, prepared_world: Dictionary, scheduler: CinderThreatScheduler) -> bool:
	if not is_node_ready() or not _native_program.is_empty() or _source_busy != 0 or not is_instance_valid(scheduler) or not scheduler.is_inside_tree() or scheduler.is_queued_for_deletion() or scheduler.get_world_3d() != get_world_3d() or scheduler.process_physics_priority >= process_physics_priority:
		source_snapshot_error = "Configure one ready same-world stationary source with its earlier Scheduler"
		return false
	var reader = EnemyPlan.new()
	if not reader.configure(source_id + "/own-sequence", definition, source_id, source_epoch, generation, profile_id, prepared_world):
		source_snapshot_error = reader.last_error
		return false
	_native_program = reader.snapshot_state()
	var native: Dictionary = reader.state()
	_native_definition = native.definition.duplicate(true)
	_owned_source_id = source_id
	_source_epoch = source_epoch
	_source_generation = generation
	_source_scheduler = scheduler
	_knot = native.authored.tether_position
	global_position = _knot
	global_basis = Basis.IDENTITY
	max_hp = float(native.resolved_role.max_hp)
	hp = max_hp
	dead = false
	source_hits = 0
	defeated_at_s = null
	_hit_receipts.clear()
	_renderer.presentation = _native_definition.presentation.duplicate(true)
	if not _renderer.present_authored_echo_pose({"position": _knot, "direction": _native_definition.slash.direction, "action": "idle", "progress": 0.0}, true):
		source_snapshot_error = "Native porcelain renderer declined its immutable initial pose"
		return false
	_native_source_script = get_script()
	_native_renderer_script = _renderer.get_script()
	_native_source_parent = get_parent()
	_native_world = get_world_3d()
	_native_handles.clear()
	for visual: MeshInstance3D in _visuals():
		_native_handles.append({"node": visual, "mesh": visual.mesh, "material": visual.material_override})
	_native_receipt = _resource_receipt()
	if _native_receipt.is_empty():
		source_snapshot_error = "Complete native porcelain and fixed-knot resources required"
		return false
	add_to_group("enemies")
	if not configure_authored(source_id + "/playback", _native_program, source_epoch, generation):
		remove_from_group("enemies")
		source_snapshot_error = last_error
		return false
	source_snapshot_error = ""
	return true


func get_authored_echo_binding() -> Dictionary:
	return {"api_revision": SOURCE_API, "source_id": _owned_source_id, "source_epoch": _source_epoch, "generation": _source_generation, "definition": _native_definition.duplicate(true), "alive": not dead, "knot_position": _knot}


func get_authored_echo_renderer() -> Node3D:
	return _renderer


func source_program() -> Dictionary:
	return _native_program.duplicate(true)


func source_clock() -> float:
	return _source_scheduler.get_clock() if is_instance_valid(_source_scheduler) else -1.0


func source_phase() -> String:
	if dead:
		return "defeated"
	var playback: Dictionary = state()
	if playback.is_empty() or playback.status == "idle":
		return "idle"
	return String(playback.cursor.get("phase", "warning")) if playback.status == "running" else String(playback.status)


func get_source_state() -> Dictionary:
	return {"api_revision": OWNED_API, "source_id": _owned_source_id, "source_epoch": _source_epoch, "generation": _source_generation, "hp": hp, "max_hp": max_hp, "alive": not dead, "source_hits": source_hits, "defeated_at_s": defeated_at_s, "phase": source_phase(), "clock_s": source_clock(), "knot_position": _knot, "hit_receipts": source_hit_receipts(), "native_error": source_native_error(), "snapshot_error": source_snapshot_error}


func source_hit_receipts() -> Array:
	return _hit_receipts.duplicate(true)


func source_native_error() -> String:
	if not _native_fault.is_empty():
		return _native_fault
	var error: String = _current_native_error()
	# Inspection remains pure. A failure is not healed by snapshot restoration;
	# runtime presentation observes and latches it before canonical advance.
	return error


func _current_native_error() -> String:
	if not is_node_ready() or is_queued_for_deletion() or _source_busy != 0 or _native_program.is_empty():
		return "Ready configured source outside its own target callbacks required"
	if not is_instance_valid(_source_scheduler) or _source_scheduler.is_queued_for_deletion() or not _source_scheduler.is_inside_tree() or _source_scheduler.get_world_3d() != _native_world or get_parent() != _native_source_parent or get_world_3d() != _native_world:
		return "Retained actual source parent/world/Scheduler required"
	if global_position != _knot or global_basis != Basis.IDENTITY or not is_visible_in_tree() or get_script() != _native_source_script:
		return "Actual HP target must retain visible fixed knot, basis and script"
	if not is_instance_valid(_renderer) or _renderer.is_queued_for_deletion() or _renderer.get_parent() != self or not _renderer.is_visible_in_tree() or _renderer.get_script() != _native_renderer_script or not is_instance_valid(_fixed_knot) or _fixed_knot.is_queued_for_deletion() or _fixed_knot.get_parent() != self or not _fixed_knot.is_visible_in_tree():
		return "Actual porcelain renderer or fixed low knot was lost"
	var visuals: Array[MeshInstance3D] = _visuals()
	if visuals.size() != _native_handles.size():
		return "Required native visual set differs"
	for index: int in range(visuals.size()):
		var visual: MeshInstance3D = visuals[index]
		var retained: Dictionary = _native_handles[index]
		if not is_instance_valid(visual) or visual != retained.node or visual.mesh != retained.mesh or visual.material_override != retained.material:
			return "Required native visual/resource identity changed"
	var fresh: Dictionary = _resource_receipt()
	if fresh.is_empty() or not EnemyPlan.exact_equal(fresh, _native_receipt):
		return "Native porcelain/fixed-knot tree, transform, primitive or material changed"
	if not is_finite(hp) or max_hp != float(_native_program.resolved_role.max_hp) or hp < 0.0 or hp > max_hp or dead != (hp == 0.0) or is_in_group("enemies") == dead:
		return "Actual HP/lifecycle/ordinary-target group differs"
	return ""


func native_descriptor() -> Dictionary:
	return _native_receipt.duplicate(true)


func _visuals() -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if is_instance_valid(_renderer):
		result.assign(_renderer.required_visuals)
	if is_instance_valid(_fixed_knot):
		result.append(_fixed_knot)
	return result


func _resource_receipt() -> Dictionary:
	if not is_instance_valid(_renderer) or not is_instance_valid(_fixed_knot) or _renderer.get_child_count() != 16 or _renderer.required_visuals.size() != 16:
		return {}
	var visuals: Array = []
	for visual: MeshInstance3D in _visuals():
		if not is_instance_valid(visual) or visual.is_queued_for_deletion() or not visual.mesh is BoxMesh or not visual.material_override is StandardMaterial3D or visual.get_script() != null or visual.mesh.get_script() != null or visual.material_override.get_script() != null or not visual.is_visible_in_tree() or visual.get_child_count() != 0 or visual.get_parent() not in [self, _renderer]:
			return {}
		var mesh: BoxMesh = visual.mesh
		var material: StandardMaterial3D = visual.material_override
		var arrays: Array = []
		for surface: int in range(mesh.get_surface_count()):
			if mesh.surface_get_material(surface) != null or visual.get_surface_override_material(surface) != null:
				return {}
			arrays.append(mesh.surface_get_arrays(surface))
		var node_hash: String = _storage_hash(visual, ["transform", "position", "rotation", "rotation_degrees", "quaternion", "basis", "scale", "mesh", "material_override", "name", "owner", "unique_name_in_owner", "process_mode", "process_priority", "process_physics_priority"])
		var mesh_hash: String = _storage_hash(mesh, [])
		var material_hash: String = _storage_hash(material, [])
		if node_hash.is_empty() or mesh_hash.is_empty() or material_hash.is_empty():
			return {}
		visuals.append({"path": String(get_path_to(visual)), "position": SourceValue.vector3(visual.position), "basis": _source_basis(visual.basis), "node": node_hash, "mesh": mesh_hash, "arrays": _hash_bytes(var_to_bytes(arrays)), "material": material_hash})
	return {"source_script": (get_script() as Script).resource_path, "renderer_script": (_renderer.get_script() as Script).resource_path, "renderer_path": String(get_path_to(_renderer)), "presentation": _renderer.presentation.duplicate(true), "visuals": visuals}


static func _storage_hash(object: Object, excluded: Array[String]) -> String:
	var values: Array = []
	for info: Dictionary in object.get_property_list():
		var key: String = String(info.name)
		if (int(info.usage) & PROPERTY_USAGE_STORAGE) == 0 or (int(info.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 or key.begins_with("metadata/") or key in excluded or key in ["resource_name", "resource_path", "resource_local_to_scene", "script"]:
			continue
		var value: Variant = object.get(key)
		# A native descriptor never transports handles or fresh instance IDs.
		# Supported primitives/materials have no non-null resource dependencies.
		if value is Object and is_instance_valid(value):
			return ""
		values.append([key, value])
	return _hash_bytes(var_to_bytes(values))


static func _hash_bytes(bytes: PackedByteArray) -> String:
	var digest := HashingContext.new()
	if digest.start(HashingContext.HASH_SHA256) != OK or digest.update(bytes) != OK:
		return ""
	return digest.finish().hex_encode()


static func _source_basis(value: Basis) -> Array:
	return [SourceValue.vector3(value.x), SourceValue.vector3(value.y), SourceValue.vector3(value.z)]


func framing_points() -> Dictionary:
	var error: String = source_native_error()
	if not error.is_empty():
		return {"error": error, "points": []}
	var points: Array = []
	_append_native_box(points, _fixed_knot.mesh.get_aabb(), _fixed_knot.global_transform)
	var direction: Vector3 = (_native_definition.route[1].position - _native_definition.route[0].position).normalized()
	var poses: Array[Transform3D] = [_renderer.global_transform, Transform3D(Basis(Vector3.UP, atan2(float(direction.x), float(direction.z))), _native_definition.route[0].position), Transform3D(Basis(Vector3.UP, atan2(float(direction.x), float(direction.z))), _native_definition.route[1].position)]
	for transform: Transform3D in poses:
		var corners: Array = []
		for visual: MeshInstance3D in _renderer.required_visuals:
			_append_native_box(corners, visual.mesh.get_aabb(), transform * visual.transform)
		_append_complete_bounds(points, corners)
	return {"error": "", "points": points}


static func _append_native_box(points: Array, bounds: AABB, transform: Transform3D) -> void:
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]:
				points.append(transform * Vector3(x, y, z))


static func _append_complete_bounds(points: Array, corners: Array) -> void:
	var low: Vector3 = corners[0]
	var high: Vector3 = corners[0]
	for point: Vector3 in corners:
		low = low.min(point)
		high = high.max(point)
	_append_native_box(points, AABB(low, high - low), Transform3D.IDENTITY)


func take_damage(amount: float, _impulse: Vector3) -> Dictionary:
	var result: Dictionary = {"accepted": false, "hp_damage": 0.0, "target_id": _owned_source_id, "target_alive_before_hit": not dead}
	var phase: String = source_phase()
	if get_tree().paused or _source_busy != 0 or dead or hp <= 0.0 or source_hits >= MAX_SOURCE_HITS or not is_finite(amount) or amount <= 0.0 or phase not in ["recovery", "complete"] or not source_native_error().is_empty():
		return result
	_source_busy += 1
	var before: float = hp
	var damage: float = minf(hp, amount)
	hp -= damage
	source_hits += 1
	_hit_receipts.append({"clock_s": source_clock(), "hp_before": before, "hp_damage": damage, "hp_after": hp, "phase": phase})
	result.accepted = true
	result.hp_damage = damage
	if hp == 0.0:
		dead = true
		defeated_at_s = source_clock()
		remove_from_group("enemies")
		# HP/history/target retirement precede invalidation and all observers.
		# An already complete owner remains complete; no tombstone is invented.
		_source_scheduler.cancel_owner(self, "authored_source_defeated")
	source_hit_resolved.emit(result.duplicate(true))
	if dead:
		source_defeated.emit(result.duplicate(true))
		died.emit()
	_source_busy -= 1
	return result


func _physics_process(delta: float) -> void:
	if not _native_program.is_empty():
		var error: String = source_native_error()
		if not error.is_empty():
			_native_fault = error
			cancel("act3_source_native_custody_lost")
			return
	super._physics_process(delta)


func _exit_tree() -> void:
	if is_instance_valid(_source_scheduler) and _source_scheduler.is_inside_tree():
		_source_scheduler.cancel_owner(self, "act3_source_removed")


func capture_source(player_snapshot: Dictionary, scheduler_snapshot: Dictionary, playback_snapshot: Dictionary) -> Dictionary:
	return _source_codec.capture(self, player_snapshot, scheduler_snapshot, playback_snapshot)


func source_record_error(snapshot: Dictionary, player_snapshot: Dictionary, scheduler_snapshot: Dictionary, playback_snapshot: Dictionary) -> String:
	return _source_codec.record_error(snapshot, self, player_snapshot, scheduler_snapshot, playback_snapshot)


func staged_source_binding(snapshot: Dictionary, player_snapshot: Dictionary, scheduler_snapshot: Dictionary, playback_snapshot: Dictionary) -> Dictionary:
	return _source_codec.staged_binding(snapshot, self, player_snapshot, scheduler_snapshot, playback_snapshot)


func restore_source_physical(snapshot: Dictionary, player_snapshot: Dictionary, scheduler_snapshot: Dictionary, playback_snapshot: Dictionary) -> bool:
	return _source_codec.restore_physical(snapshot, self, player_snapshot, scheduler_snapshot, playback_snapshot)


func _apply_source_lifecycle(snapshot: Dictionary) -> void:
	# Codec invokes this only after complete pure prevalidation. No renderer,
	# Scheduler, Playback, Hero, signal, clock or target callback runs here.
	hp = snapshot.hp
	dead = not snapshot.alive
	source_hits = snapshot.source_hits
	defeated_at_s = snapshot.defeated_at_s
	_hit_receipts.clear()
	for receipt: Dictionary in snapshot.hit_receipts:
		_hit_receipts.append(receipt.duplicate(true))
	if dead:
		remove_from_group("enemies")
	else:
		add_to_group("enemies")


func verify_restored_source_phase(snapshot: Dictionary) -> bool:
	return _source_codec.verify_phase(snapshot, self)
