class_name CinderSporeField
extends Node3D
## Finite environmental supply/field only. Enemy retreat is NOT implemented.
## Per-instance pausable simulation clock, no damage/HP/perk/RNG machinery.

signal activated(domain: Dictionary)
signal state_changed(field_state: Dictionary)

const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Cluster = preload("res://scripts/environment/spore_cluster.gd")
const Footprint = preload("res://scripts/attack_footprint.gd")
const API_REVISION: String = "spore-field-1"
const SNAPSHOT_KEYS: Array[String] = ["api_revision", "schema_version", "definition", "geometry", "clock_s", "generation", "spent_ids", "activation_s", "deadline_s", "phase"]
const DEFAULT_PARAMETERS: Dictionary = {"duration_s": 3.0, "thinning_s": 0.5, "radius": 2.025}
const MAX_CLOCK_S: float = 1000000000.0

var last_error: String = ""
var last_snapshot_error: String = ""
var _definition: Dictionary = {}
var _origin: Vector3 = Vector3.ZERO
var _clusters: Dictionary = {}
var _clock_s: float = 0.0
var _generation: int = 0
var _spent_ids: Array[String] = []
var _activation_s: Variant = null
var _deadline_s: Variant = null
var _bound: bool = false
var _busy: bool = false
var _last_phase: String = ""
var _boundary: MeshInstance3D
var _spores: Array[MeshInstance3D] = []
var _boundary_mesh: ArrayMesh
var _boundary_vertices: PackedVector3Array
var _spore_meshes: Array[BoxMesh] = []


## Authored offsets are world-axis offsets at immutable bind position.
## Exactly two clusters are the current provisional shared fixture policy.
func configure(instance_id: String, clusters: Array, parameters: Dictionary = {}) -> bool:
	if _bound or is_inside_tree() or not _definition.is_empty():
		return _reject("Configure the immutable mushroom definition before binding")
	if not _stable_id(instance_id) or clusters.size() != 2:
		return _reject("Stable environmental instance ID and exactly two clusters required")
	var resolved: Dictionary = DEFAULT_PARAMETERS.duplicate(true)
	for key: Variant in parameters:
		if not key is String or not resolved.has(key):
			return _reject("Unknown spore parameter")
		resolved[key] = parameters[key]
	if not Codec.in_range(resolved.duration_s, 0.1, 60.0) or not Codec.in_range(resolved.thinning_s, 0.0, float(resolved.duration_s) - 0.000001) or not Codec.in_range(resolved.radius, 0.1, 8.0):
		return _reject("Finite bounded duration/thinning/radius required")
	var records: Array[Dictionary] = []
	var used: Dictionary = {}
	for spec: Variant in clusters:
		if not spec is Dictionary or not Codec.keys_error(spec, ["id", "offset"]).is_empty() or not _stable_id(spec.id) or used.has(spec.id) or not spec.offset is Vector3 or not spec.offset.is_finite() or spec.offset.length() > 8.0:
			return _reject("Two distinct stable cluster IDs and bounded finite offsets required")
		used[spec.id] = true
		records.append({"id": spec.id, "offset": Codec.vector3(spec.offset)})
	if (clusters[0].offset as Vector3).distance_to(clusters[1].offset) < 0.1:
		return _reject("Clusters must have visibly separate anchors")
	_definition = {"id": instance_id, "parameters": resolved.duplicate(true), "clusters": records}
	last_error = ""
	return true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if _definition.is_empty() or not global_position.is_finite() or global_basis != Basis.IDENTITY:
		last_error = "Bind requires a configured finite unrotated/unscaled mushroom"
		return
	_origin = global_position
	for spec: Dictionary in _definition.clusters:
		var cluster: Node3D = Cluster.new()
		cluster.name = spec.id
		cluster.call("configure", self, spec.id)
		cluster.position = Codec.read_vector3(spec.offset)
		add_child(cluster)
		_clusters[spec.id] = cluster
	_build_field_cue()
	_bound = true
	_refresh_visual(false)


func activate_cluster(cluster_id: String) -> bool:
	if not _bound or _busy or get_tree().paused or not _binding_error().is_empty() or not _clusters.has(cluster_id) or cluster_id in _spent_ids or _field_active() or _generation >= 2 or _clock_s + float(_definition.parameters.duration_s) > MAX_CLOCK_S:
		return _reject("Spore cluster is unavailable or field already active")
	_busy = true
	_spent_ids.append(cluster_id)
	_generation += 1
	_activation_s = _clock_s
	_deadline_s = _clock_s + float(_definition.parameters.duration_s)
	# Commit supply and deadline before any callback can hit another anchor.
	_refresh_visual(true)
	activated.emit(active_domain())
	_busy = false
	last_error = ""
	return true


func _physics_process(delta: float) -> void:
	if not _bound or _busy or get_tree().paused or not is_finite(delta) or delta <= 0.0 or not _binding_error().is_empty():
		return
	_busy = true
	_clock_s = minf(MAX_CLOCK_S, _clock_s + delta)
	_refresh_visual(true)
	_busy = false


func _field_active() -> bool:
	return _deadline_s != null and _clock_s < float(_deadline_s)


func _phase(clock: float, activation: Variant, deadline: Variant, generation: int) -> String:
	if deadline == null or clock >= float(deadline):
		return "spent" if generation == 2 else "available"
	if clock == float(activation):
		return "releasing"
	return "thinning" if clock >= float(deadline) - float(_definition.parameters.thinning_s) else "active"


func state() -> Dictionary:
	return {"api_revision": API_REVISION, "instance_id": _definition.get("id", ""), "bound": _bound, "phase": _phase(_clock_s, _activation_s, _deadline_s, _generation), "clock_s": _clock_s, "generation": _generation, "spent_ids": _spent_ids.duplicate(), "remaining_clusters": 2 - _generation, "activation_s": _activation_s, "deadline_s": _deadline_s}


## Bounded geometry/state domain for a future actual living-enemy consumer.
## This is no damage reservation, retreat proof or implemented avoidance.
func active_domain() -> Dictionary:
	if not _bound or not _field_active() or not _binding_error().is_empty():
		return {}
	return {"api_revision": API_REVISION, "instance_id": _definition.id, "field_id": "%s/field-%d" % [_definition.id, _generation], "generation": _generation, "origin": _origin, "radius": float(_definition.parameters.radius), "phase": _phase(_clock_s, _activation_s, _deadline_s, _generation), "remaining_s": float(_deadline_s) - _clock_s, "clock_s": _clock_s, "deadline_s": _deadline_s, "causes_damage": false, "retreat_implemented": false}


func get_cue_state() -> Dictionary:
	var clusters: Array[Dictionary] = []
	for spec: Dictionary in _definition.get("clusters", []):
		if _clusters.has(spec.id):
			clusters.append(_clusters[spec.id].get_cue_state())
	return {"required": true, "broken_boundary": true, "danger_fill": false, "countdown": false, "visible": _bound and _field_active(), "phase": _phase(_clock_s, _activation_s, _deadline_s, _generation), "geometry": {"origin": Codec.vector3(_origin), "radius": _definition.get("parameters", DEFAULT_PARAMETERS).radius}, "clusters": clusters}


func snapshot_state() -> Dictionary:
	last_snapshot_error = _snapshot_boundary_error()
	if not last_snapshot_error.is_empty():
		return {}
	return {"api_revision": API_REVISION, "schema_version": 1, "definition": _definition.duplicate(true), "geometry": {"origin": Codec.vector3(_origin), "radius": _definition.parameters.radius}, "clock_s": _clock_s, "generation": _generation, "spent_ids": _spent_ids.duplicate(), "activation_s": _activation_s, "deadline_s": _deadline_s, "phase": _phase(_clock_s, _activation_s, _deadline_s, _generation)}


func snapshot_error(snapshot: Dictionary) -> String:
	var error: String = _snapshot_boundary_error()
	if not error.is_empty():
		return error
	error = Codec.value_error(snapshot)
	if error.is_empty():
		error = Codec.keys_error(snapshot, SNAPSHOT_KEYS)
	if not error.is_empty():
		return error
	if snapshot.api_revision != API_REVISION or not Codec.is_integer(snapshot.schema_version, 1, 1) or not _exact_values(snapshot.definition, _definition) or not _exact_values(snapshot.geometry, {"origin": Codec.vector3(_origin), "radius": _definition.parameters.radius}) or not Codec.in_range(snapshot.clock_s, 0.0, MAX_CLOCK_S) or not Codec.is_integer(snapshot.generation, 0, 2) or not snapshot.spent_ids is Array or snapshot.spent_ids.size() != int(snapshot.generation):
		return "Snapshot must match immutable field identity/geometry and bounded supply"
	var seen: Dictionary = {}
	for id: Variant in snapshot.spent_ids:
		if not id is String or not _clusters.has(id) or seen.has(id):
			return "Spent cluster IDs must be distinct authored supplies"
		seen[id] = true
	if int(snapshot.generation) == 0:
		if snapshot.activation_s != null or snapshot.deadline_s != null:
			return "Unused mushroom cannot retain a field activation"
	else:
		if not Codec.in_range(snapshot.activation_s, 0.0, float(snapshot.clock_s)) or not Codec.in_range(snapshot.deadline_s, 0.0, MAX_CLOCK_S) or float(snapshot.deadline_s) != float(snapshot.activation_s) + float(_definition.parameters.duration_s):
			return "Field deadline must preserve its actual activation and duration"
		if int(snapshot.generation) == 2 and float(snapshot.activation_s) < float(_definition.parameters.duration_s):
			return "Second supply cannot release before the first field expired"
	if snapshot.phase != _phase(float(snapshot.clock_s), snapshot.activation_s, snapshot.deadline_s, int(snapshot.generation)):
		return "Field phase must agree with saved simulation clock and deadline"
	return ""


func restore_state(snapshot: Dictionary) -> bool:
	last_snapshot_error = snapshot_error(snapshot)
	if not last_snapshot_error.is_empty():
		return false
	_busy = true
	_clock_s = float(snapshot.clock_s)
	_generation = int(snapshot.generation)
	_spent_ids.clear()
	for id: String in snapshot.spent_ids:
		_spent_ids.append(id)
	_activation_s = snapshot.activation_s
	_deadline_s = snapshot.deadline_s
	_refresh_visual(false)
	_busy = false
	return true


func _snapshot_boundary_error() -> String:
	if not _bound or not is_inside_tree() or not is_node_ready() or not get_tree().paused or _busy:
		return "Spore snapshots require the paused deferred boundary outside callbacks"
	return _binding_error()


## Pure live diagnostic, including inside normal activation callbacks after
## the committed state is visible. It never advances clocks/spends supply,
## reads snapshot state, emits feedback, or writes either last-error property.
func binding_error() -> String:
	if not _bound or not is_inside_tree() or not is_node_ready() or is_queued_for_deletion():
		return "Spore field requires its live ready immutable binding"
	return _binding_error()


func _binding_error() -> String:
	if global_position != _origin or global_basis != Basis.IDENTITY or not is_instance_valid(_boundary) or _boundary.is_queued_for_deletion() or _clusters.size() != 2 or _spores.size() != 4 or _spore_meshes.size() != 4:
		return "Immutable spore world origin/geometry/cue bindings changed"
	if _boundary.get_parent() != self or _boundary.position != Vector3(0, 0.025, 0) or _boundary.basis != Basis.IDENTITY or _boundary.mesh != _boundary_mesh or not is_instance_valid(_boundary_mesh) or _boundary_mesh.get_surface_count() != 1 or _boundary_mesh.surface_get_primitive_type(0) != Mesh.PRIMITIVE_TRIANGLES or _boundary_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] != _boundary_vertices or not _boundary.material_override is StandardMaterial3D:
		return "Required broken boundary parent/pose/actual mesh binding changed"
	for spec: Dictionary in _definition.clusters:
		if not is_instance_valid(_clusters.get(spec.id)):
			return "Stable reachable cluster binding disappeared"
		var cluster: Node3D = _clusters[spec.id]
		if cluster.is_queued_for_deletion() or cluster.get_parent() != self or cluster.global_position != _origin + Codec.read_vector3(spec.offset) or not cluster.is_in_group("environment_attack_targets") or not cluster.binding_error().is_empty():
			return "Stable reachable cluster bindings changed"
	for index: int in range(_spores.size()):
		if not is_instance_valid(_spores[index]):
			return "Required release feedback binding disappeared"
		var square: MeshInstance3D = _spores[index]
		if square.is_queued_for_deletion() or square.get_parent() != self or not square.position.is_finite() or Vector2(square.position.x, square.position.z) != Vector2(-0.22 + 0.15 * index, 0.12) or square.basis != Basis.IDENTITY or square.mesh != _spore_meshes[index] or not square.mesh is BoxMesh or (square.mesh as BoxMesh).size != Vector3(0.045, 0.045, 0.045) or not square.material_override is StandardMaterial3D:
			return "Required release feedback parent/XZ/basis/mesh-size binding changed"
	return ""


func _refresh_visual(notify: bool) -> void:
	var phase: String = _phase(_clock_s, _activation_s, _deadline_s, _generation)
	var active: bool = _field_active()
	for id: String in _clusters:
		_clusters[id].present_state("spent" if id in _spent_ids else ("active" if active else "available"), notify)
	_boundary.visible = active
	var fade: float = clampf((float(_deadline_s) - _clock_s) / maxf(0.000001, float(_definition.parameters.thinning_s)), 0.0, 1.0) if phase == "thinning" else 1.0
	(_boundary.material_override as StandardMaterial3D).albedo_color = Color(0.81, 0.87, 0.75, 0.45 + 0.45 * fade)
	for index: int in range(_spores.size()):
		_spores[index].visible = active
		if active:
			var age: float = _clock_s - float(_activation_s)
			_spores[index].position.y = 0.18 + 0.65 * (1.0 - fposmod(age + float(index) * 0.2, 0.8) / 0.8)
	var changed: bool = phase != _last_phase
	_last_phase = phase
	if changed and notify:
		state_changed.emit(state())


func _build_field_cue() -> void:
	add_to_group("required_cues")
	_boundary = MeshInstance3D.new()
	_boundary.name = "RequiredBrokenSporeBoundary"
	var vertices: Array[Vector3] = []
	for index: int in range(32):
		# A gap after each short arc prevents resemblance to a danger circle.
		var start: float = TAU * float(index) / 32.0
		var end: float = start + TAU / 32.0 * 0.55
		Footprint.append_edge(vertices, Footprint.radial_point(start, float(_definition.parameters.radius)), Footprint.radial_point(end, float(_definition.parameters.radius)))
	_boundary_mesh = Footprint.mesh_from_vertices(vertices)
	_boundary.mesh = _boundary_mesh
	_boundary_vertices = (_boundary_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).duplicate()
	_boundary.position.y = 0.025
	_boundary.material_override = _material(Color(0.81, 0.87, 0.75, 0.9))
	_boundary.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_boundary)
	for index: int in range(4):
		var square := MeshInstance3D.new()
		square.name = "RequiredReleaseSquare%d" % index
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.045, 0.045, 0.045)
		square.mesh = mesh
		square.material_override = _material(Color(0.87, 0.89, 0.79, 0.8))
		square.position = Vector3(-0.22 + 0.15 * index, 0.5, 0.12)
		square.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(square)
		_spores.append(square)
		_spore_meshes.append(mesh)


func _material(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.albedo_color = tint
	return material


func _stable_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 64:
		return false
	var expression := RegEx.new()
	expression.compile("^[A-Za-z0-9_-]+$")
	var matched: RegExMatch = expression.search(value)
	return matched != null and matched.get_string() == value


func _exact_values(left: Variant, right: Variant) -> bool:
	if Codec.is_number(left) and Codec.is_number(right):
		return float(left) == float(right)
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size(): return false
		for key: String in left:
			if not right.has(key) or not _exact_values(left[key], right[key]): return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size(): return false
		for index: int in range(left.size()):
			if not _exact_values(left[index], right[index]): return false
		return true
	return typeof(left) == typeof(right) and left == right


func _reject(reason: String) -> bool:
	last_error = reason
	return false
