extends "res://scripts/combat/replay_playback.gd"
## TEST ONLY genuine stationary C52 owner. Its visible child performs the
## harmless authored travel; the HP target stays at the reachable fixed knot.
const SourceCodec = preload("res://tests/fixtures/authored_echo_native_codec.gd")
const EnemyPlan = preload("res://scripts/combat/authored_enemy_sequence.gd")
const SourceValue = preload("res://scripts/campaign/snapshot_codec.gd")
const SOURCE_API: String = "authored-echo-source-1"

signal source_hit_resolved(result: Dictionary)
signal source_defeated(result: Dictionary)

class EnemyRenderer extends Node3D:
	signal pose_presented(value: Dictionary)
	var presentation: Dictionary = {}
	var visual: MeshInstance3D
	var pose: Dictionary = {}

	func _ready() -> void:
		visual = MeshInstance3D.new()
		visual.name = "RequiredEnemySilhouette"
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.30, 1.0, 0.30)
		visual.mesh = mesh
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.albedo_color = Color(0.64, 0.82, 0.90, 1.0)
		visual.material_override = material
		visual.position.y = 0.5
		add_child(visual)

	func get_authored_echo_render_bindings() -> Dictionary:
		return {"api_revision": "authored-echo-renderer-1", "presentation": presentation.duplicate(true), "required_visuals": [visual]}

	func present_authored_echo_pose(value: Dictionary, quiet: bool) -> bool:
		if not SourceValue.keys_error(value, ["position", "direction", "action", "progress"]).is_empty() or not value.position is Vector3 or not value.position.is_finite() or not value.direction is Vector3 or not value.direction.is_finite() or value.action not in ["idle", "dash", "enemy_slash"] or not value.progress is float or not SourceValue.in_range(value.progress, 0.0, 1.0):
			return false
		global_position = value.position
		global_basis = Basis(Vector3.UP, atan2(float(value.direction.x), float(value.direction.z)))
		pose = value.duplicate(true)
		if not quiet:
			pose_presented.emit(value.duplicate(true))
		return true

	func native_pose() -> Dictionary:
		return {"transform": global_transform, "pose": pose.duplicate(true), "visible": is_visible_in_tree(), "child_transform": visual.transform if is_instance_valid(visual) else null}

var hp: float = 0.0
var max_hp: float = 0.0
var dead: bool = false
var source_hits: int = 0
var defeated_at_s: Variant = null
var source_snapshot_error: String = ""
var _native_definition: Dictionary = {}
var _native_program: Dictionary = {}
var _source_id: String = ""
var _source_epoch: String = ""
var _source_generation: int = 0
var _knot: Vector3 = Vector3.ZERO
var _renderer: EnemyRenderer
var _source_scheduler: CinderThreatScheduler
var _source_busy: int = 0
var _native_receipt: Dictionary = {}
var _native_mesh: Mesh
var _native_material: Material
var _native_script: Script
var _renderer_script: Script
var _source_codec = SourceCodec.new()


func _ready() -> void:
	super._ready()
	_renderer = EnemyRenderer.new()
	_renderer.name = "SourceOwnedEnemyRenderer"
	add_child(_renderer)


func initialize_source(source_id: String, epoch: String, generation: int, definition: Dictionary, profile_id: String, world: Dictionary) -> bool:
	if not is_node_ready() or not _native_program.is_empty() or _source_busy != 0:
		return false
	var reader = EnemyPlan.new()
	if not reader.configure("test-only/own-echo-cycle", definition, source_id, epoch, generation, profile_id, world):
		source_snapshot_error = reader.last_error
		return false
	_native_program = reader.snapshot_state()
	_native_definition = reader.state().definition
	_source_id = source_id
	_source_epoch = epoch
	_source_generation = generation
	_knot = reader.state().authored.tether_position
	global_position = _knot
	global_basis = Basis.IDENTITY
	max_hp = float(reader.state().resolved_role.max_hp)
	hp = max_hp
	dead = false
	_renderer.presentation = _native_definition.presentation.duplicate(true)
	_renderer.present_authored_echo_pose({"position": _knot, "direction": _native_definition.slash.direction, "action": "idle", "progress": 0.0}, true)
	_native_mesh = _renderer.visual.mesh
	_native_material = _renderer.visual.material_override
	_native_script = get_script()
	_renderer_script = _renderer.get_script()
	_native_receipt = _resource_receipt()
	add_to_group("enemies")
	return true


func attach_source_scheduler(scheduler: CinderThreatScheduler) -> bool:
	if not is_instance_valid(scheduler) or not scheduler.is_inside_tree() or scheduler.get_world_3d() != get_world_3d() or (_source_scheduler != null and _source_scheduler != scheduler):
		return false
	_source_scheduler = scheduler
	return true


func get_authored_echo_binding() -> Dictionary:
	return {"api_revision": SOURCE_API, "source_id": _source_id, "source_epoch": _source_epoch, "generation": _source_generation, "definition": _native_definition.duplicate(true), "alive": not dead, "knot_position": _knot}


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


func source_native_error() -> String:
	if not is_node_ready() or is_queued_for_deletion() or _source_busy != 0 or _native_program.is_empty():
		return "Ready configured source outside its own callbacks required"
	if global_position != _knot or global_basis != Basis.IDENTITY or not is_visible_in_tree():
		return "Actual HP target must retain visible fixed knot and basis"
	if not is_instance_valid(_renderer) or _renderer.is_queued_for_deletion() or _renderer.get_parent() != self or not _renderer.is_visible_in_tree() or not is_instance_valid(_renderer.visual) or _renderer.visual.is_queued_for_deletion() or not _renderer.visual.is_visible_in_tree():
		return "Actual source renderer/required child was lost"
	if get_script() != _native_script or _renderer.get_script() != _renderer_script or _renderer.visual.mesh != _native_mesh or _renderer.visual.material_override != _native_material:
		return "Actual source scripts/native resource identities changed"
	var fresh: Dictionary = _resource_receipt()
	if fresh.is_empty() or not EnemyPlan.exact_equal(fresh, _native_receipt):
		return "Actual source script, renderer tree, primitive or material changed"
	return ""


func native_descriptor() -> Dictionary:
	return _native_receipt.duplicate(true)


func _resource_receipt() -> Dictionary:
	if not is_instance_valid(_renderer) or not is_instance_valid(_renderer.visual) or not _renderer.visual.mesh is BoxMesh or not _renderer.visual.material_override is StandardMaterial3D:
		return {}
	var visual: MeshInstance3D = _renderer.visual
	var mesh: BoxMesh = visual.mesh
	var material: StandardMaterial3D = visual.material_override
	return {"source_script": (get_script() as Script).resource_path, "renderer_script": (_renderer.get_script() as Script).resource_path, "renderer_path": String(get_path_to(_renderer)), "visual_path": String(_renderer.get_path_to(visual)), "child_count": _renderer.get_child_count(), "size": SourceValue.vector3(mesh.size), "visual_position": SourceValue.vector3(visual.position), "visual_basis": [SourceValue.vector3(visual.basis.x), SourceValue.vector3(visual.basis.y), SourceValue.vector3(visual.basis.z)], "layers": visual.layers, "visual_visible": visual.visible, "material": {"shading": material.shading_mode, "filter": material.texture_filter, "transparency": material.transparency, "color": [material.albedo_color.r, material.albedo_color.g, material.albedo_color.b, material.albedo_color.a], "depth_disabled": material.no_depth_test, "billboard": material.billboard_mode}, "presentation": _renderer.presentation.duplicate(true)}


func take_damage(amount: float, _impulse: Vector3) -> Dictionary:
	var result: Dictionary = {"accepted": false, "hp_damage": 0.0, "target_id": _source_id, "target_alive_before_hit": not dead}
	if get_tree().paused or _source_busy != 0 or dead or hp <= 0.0 or not is_finite(amount) or amount <= 0.0 or source_phase() != "recovery" or not source_native_error().is_empty():
		return result
	_source_busy += 1
	var damage: float = minf(hp, amount)
	hp -= damage
	source_hits += 1
	result.accepted = true
	result.hp_damage = damage
	if hp == 0.0:
		dead = true
		defeated_at_s = source_clock()
		# Commit lifecycle before actual Scheduler invalidation and observers.
		_source_scheduler.cancel_owner(self, "authored_source_defeated")
		remove_from_group("enemies")
	source_hit_resolved.emit(result.duplicate(true))
	if dead:
		source_defeated.emit(result.duplicate(true))
	_source_busy -= 1
	return result


func capture_source(player_snapshot: Dictionary, scheduler_snapshot: Dictionary, playback_snapshot: Dictionary) -> Dictionary:
	return _source_codec.capture(self, player_snapshot, scheduler_snapshot, playback_snapshot)


func source_record_error(snapshot: Dictionary, player_snapshot: Dictionary, scheduler_snapshot: Dictionary, playback_snapshot: Dictionary) -> String:
	return _source_codec.record_error(snapshot, self, player_snapshot, scheduler_snapshot, playback_snapshot)


func staged_source_binding(snapshot: Dictionary) -> Dictionary:
	return _source_codec.staged_binding(snapshot, self)


func restore_source_physical(snapshot: Dictionary, player_snapshot: Dictionary, scheduler_snapshot: Dictionary, playback_snapshot: Dictionary) -> bool:
	return _source_codec.restore_physical(snapshot, self, player_snapshot, scheduler_snapshot, playback_snapshot)


func verify_restored_source_phase(snapshot: Dictionary) -> bool:
	return _source_codec.verify_phase(snapshot, self)
