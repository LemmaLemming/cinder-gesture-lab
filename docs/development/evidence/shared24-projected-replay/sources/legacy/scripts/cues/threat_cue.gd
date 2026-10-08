class_name CinderThreatCue
extends Node3D
## Required, externally clocked presentation of committed threat geometry.
## Owners advance phases and cancel attacks; this node has no damage/timers.
## Act art may subscribe to state_changed, leaving the required meshes intact.

signal state_changed(cue_state: Dictionary)

const Geometry: GDScript = preload("res://scripts/combat/threat_geometry.gd")
const CueMesh: GDScript = preload("res://scripts/cues/cue_mesh.gd")
const Codec: GDScript = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson: GDScript = preload("res://scripts/campaign/exact_json.gd")
const PlayerRecord: GDScript = preload("res://scripts/player.gd")
const Footprint: GDScript = preload("res://scripts/attack_footprint.gd")
const PROJECTION_KEYS: Array[String] = ["event_id", "kind", "slot_id", "record_sequence", "at_s", "record", "floor_y", "triangle_vertices", "boundary_contours", "bounds"]
const MAX_PROJECTED_VERTICES: int = 16384
const MAX_PROJECTED_COORD: float = 512.0
const MAX_OUTLINE_PAIR_TESTS: int = 1048576
const MAX_OUTLINE_VERTICES: int = 131072
const API_REVISION: String = "threat-cue-1"
const PHASES: Array[String] = ["warning", "lock", "active", "recovery"]
const FLOOR_OFFSET: float = 0.025

var last_error: String = ""
var _cue_state: Dictionary = {"api_revision": API_REVISION, "phase": "clear", "geometry": {}, "source_position": null, "required": true, "source_visible": false, "footprint_visible": false, "active_fill_visible": false}
var _outline: MeshInstance3D
var _fill: MeshInstance3D
var _source: MeshInstance3D
var _notifying: bool = false
# This event is already authenticated by the caller's whole Footprint plan.
# A cue validates its closed shape/native custody; it grants no damage or LOS.
var _projection: Dictionary = {}
var _projection_wire: String = ""
var _projection_shape: Dictionary = {}
var _projection_meshes: Dictionary = {}
var _projection_mesh_bytes: Dictionary = {}
var _projection_nodes: Array[MeshInstance3D] = []
var _projection_materials: Array[StandardMaterial3D] = []
var _projection_material_bytes: Array[PackedByteArray] = []
var _projection_renderer_bytes: Array[PackedByteArray] = []
var _projection_parent: WeakRef
var _projection_world: WeakRef
var _projection_source_phase: String = "clear"
var _projection_fault: String = ""


func _ready() -> void:
	# The footprint is world geometry even under transformed act scenery.
	top_level = true
	add_to_group("required_cues")
	_outline = _mesh_node("RequiredFootprintOutline", FLOOR_OFFSET)
	_fill = _mesh_node("RequiredFootprintFill", FLOOR_OFFSET - 0.004)
	_source = _mesh_node("RequiredSourceMarker", FLOOR_OFFSET + 0.004)
	_outline.visible = false
	_fill.visible = false
	_source.visible = false


func present(geometry: Dictionary, phase: String) -> bool:
	if not is_inside_tree() or not is_node_ready():
		return _reject("Threat cue must be ready before presentation")
	if _notifying:
		return _reject("Threat cue cannot change inside its state callback")
	if phase not in PHASES:
		return _reject("Unsupported threat cue phase")
	var geometry_error: String = Geometry.error(geometry)
	if not geometry_error.is_empty():
		return _reject(geometry_error)
	var source: Variant = geometry.get("source_position", CueMesh.anchor(geometry))
	if not Geometry.finite_vector(source):
		return _reject("Threat source marker requires a finite world position")
	var shape: Dictionary = CueMesh.canonical_geometry(geometry)
	if not _projection.is_empty():
		return _present_projected(shape, source as Vector3, phase)
	if _cue_state["phase"] in ["lock", "active"] and phase in ["lock", "active", "recovery"] and shape != _cue_state["geometry"]:
		return _reject("Locked danger geometry must remain committed; cancel before replacing it")
	var next: Dictionary = {"api_revision": API_REVISION, "phase": phase, "geometry": shape, "source_position": source, "required": true, "source_visible": true, "footprint_visible": phase != "recovery", "active_fill_visible": phase == "active"}
	last_error = ""
	if next == _cue_state:
		return true
	_cue_state = next
	global_transform = Transform3D(Basis.IDENTITY, CueMesh.anchor(shape))
	_outline.mesh = CueMesh.geometry_mesh(shape, false)
	_fill.mesh = CueMesh.geometry_mesh(shape, true)
	_source.mesh = CueMesh.source_mesh(phase)
	_source.position = (source as Vector3) - global_position + Vector3.UP * (FLOOR_OFFSET + 0.004)
	_outline.visible = next["footprint_visible"]
	_fill.visible = next["active_fill_visible"]
	_source.visible = true
	var color: Color = _phase_color(phase)
	(_outline.material_override as StandardMaterial3D).albedo_color = color
	(_fill.material_override as StandardMaterial3D).albedo_color = Color(color.r, color.g, color.b, 0.22)
	(_source.material_override as StandardMaterial3D).albedo_color = color
	_notify()
	return true


func clear() -> bool:
	if _notifying:
		return _reject("Threat cue cannot clear inside its state callback")
	last_error = ""
	if not _projection.is_empty():
		return _clear_projected()
	if _cue_state["phase"] == "clear":
		return true
	_cue_state = {"api_revision": API_REVISION, "phase": "clear", "geometry": {}, "source_position": null, "required": true, "source_visible": false, "footprint_visible": false, "active_fill_visible": false}
	_outline.visible = false
	_fill.visible = false
	_source.visible = false
	_outline.mesh = null
	_fill.mesh = null
	_source.mesh = null
	_notify()
	return true


func cancel() -> bool:
	return clear()


func state() -> Dictionary:
	return _cue_state.duplicate(true)


func _notify() -> void:
	_notifying = true
	state_changed.emit(state())
	_notifying = false


func _reject(reason: String) -> bool:
	last_error = reason
	return false


func _mesh_node(node_name: String, height: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	node.position.y = height
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	# Depth testing stays enabled: required logical geometry is not a
	# permission to make hidden scenery transparent or draw through walls.
	node.material_override = material
	add_child(node)
	return node


func _phase_color(phase: String) -> Color:
	match phase:
		"warning": return Color(1.0, 0.90, 0.63, 0.95)
		"lock": return Color(1.0, 0.76, 0.35, 1.0)
		"active": return Color(1.0, 0.43, 0.26, 1.0)
		"recovery": return Color(0.77, 0.88, 0.90, 0.70)
	return Color.WHITE


## Pure transaction preflight. The parent must first authenticate this exact
## event through ReplayFootprint.projection_error against its sealed Sequence.
func projection_binding_error(event_projection: Dictionary) -> String:
	if not is_inside_tree() or not is_node_ready() or is_queued_for_deletion():
		return "Projected cue must be live and ready before binding"
	if _notifying or _cue_state.phase != "clear":
		return "Projection binding requires a fresh or explicitly cleared cue"
	var error: String = _projection_input_error(event_projection)
	if not error.is_empty():
		return error
	if not _projection.is_empty():
		return projection_error(_projection)
	return _required_native_error()


func bind_projection(event_projection: Dictionary) -> bool:
	var error: String = projection_binding_error(event_projection)
	if not error.is_empty():
		return _reject(error)
	# All rejection precedes mutation; no signal/callback/yield occurs here.
	var event: Dictionary = event_projection.duplicate(true)
	var shape: Dictionary = _event_shape(event)
	var anchor: Vector3 = CueMesh.anchor(shape)
	var fill_vertices: Array[Vector3] = []
	for point: Array in event.triangle_vertices:
		fill_vertices.append(_local_point(point, anchor))
	var outline_plan: Dictionary = _outline_plan(event)
	if not outline_plan.accepted:
		return _reject(outline_plan.reason)
	var outline_vertices: Array[Vector3] = outline_plan.vertices
	var meshes: Dictionary = {"outline": Footprint.mesh_from_vertices(outline_vertices), "fill": Footprint.mesh_from_vertices(fill_vertices), "clear": ArrayMesh.new()}
	for phase: String in PHASES:
		meshes[phase] = CueMesh.source_mesh(phase)
	var mesh_bytes: Dictionary = {}
	for key: String in meshes:
		mesh_bytes[key] = _mesh_bytes(meshes[key])
	_projection = event
	_projection_wire = ExactJson.stringify(event)
	_projection_shape = shape
	_projection_meshes = meshes
	_projection_mesh_bytes = mesh_bytes
	_projection_nodes = [_outline, _fill, _source]
	_projection_materials.clear()
	_projection_material_bytes.clear()
	_projection_renderer_bytes.clear()
	for node: MeshInstance3D in _projection_nodes:
		var material: StandardMaterial3D = node.material_override
		_projection_materials.append(material)
		_projection_material_bytes.append(_material_bytes(material))
	_projection_parent = weakref(get_parent())
	_projection_world = weakref(get_world_3d())
	_projection_source_phase = "clear"
	_projection_fault = ""
	global_transform = Transform3D(Basis.IDENTITY, anchor)
	_outline.transform = Transform3D(Basis.IDENTITY, Vector3.UP * FLOOR_OFFSET)
	_fill.transform = Transform3D(Basis.IDENTITY, Vector3.UP * (FLOOR_OFFSET - 0.004))
	_source.transform = Transform3D(Basis.IDENTITY, Vector3.UP * (FLOOR_OFFSET + 0.004))
	_outline.mesh = meshes.outline
	_fill.mesh = meshes.fill
	_source.mesh = meshes["clear"]
	_outline.visible = false
	_fill.visible = false
	_source.visible = false
	_set_projection_colors("warning")
	for node: MeshInstance3D in _projection_nodes:
		_projection_renderer_bytes.append(_renderer_bytes(node))
	last_error = ""
	return true


func projection_state() -> Dictionary:
	return _projection.duplicate(true)


## Pure native custody guard: no pruning, callback, diagnostic or healing.
func projection_error(expected_event: Dictionary) -> String:
	if _projection.is_empty():
		return "Cue has no explicit projection binding"
	var wire: String = ExactJson.stringify(expected_event)
	if wire.is_empty() or wire != _projection_wire:
		return "Expected event differs from the exact bound projection"
	if not _projection_fault.is_empty():
		return _projection_fault
	if not is_inside_tree() or not is_node_ready() or is_queued_for_deletion() or _projection_parent.get_ref() != get_parent() or _projection_world.get_ref() != get_world_3d():
		return "Projected cue readiness, parent or native world changed"
	if ExactJson.stringify(_projection) != _projection_wire:
		return "Bound projection event storage changed"
	if not is_in_group("required_cues") or is_in_group("cosmetic_effects"):
		return "Projected cue required classification changed"
	if not top_level or not visible or var_to_bytes(global_transform) != var_to_bytes(Transform3D(Basis.IDENTITY, CueMesh.anchor(_projection_shape))):
		return "Projected cue anchor/basis/visibility changed"
	var phase: String = _cue_state.phase
	if phase not in PHASES and phase != "clear":
		return "Projected cue phase is unavailable"
	if _cue_state.required != true or _cue_state.source_visible != (phase != "clear") or _cue_state.footprint_visible != (phase != "clear" and phase != "recovery") or _cue_state.active_fill_visible != (phase == "active"):
		return "Projected required phase state changed"
	if phase != "clear" and (not is_visible_in_tree() or _shape_wire(_cue_state.geometry) != _shape_wire(_projection_shape) or _vector_wire(_cue_state.source_position) != _vector_wire(_projection_shape.origin)):
		return "Projected raw geometry/source or inherited visibility changed"
	var error: String = _required_native_error()
	if not error.is_empty():
		return error
	var expected_visible: Array[bool] = [phase != "clear" and phase != "recovery", phase == "active", phase != "clear"]
	var heights: Array[float] = [FLOOR_OFFSET, FLOOR_OFFSET - 0.004, FLOOR_OFFSET + 0.004]
	var mesh_keys: Array[String] = ["outline", "fill", _projection_source_phase]
	for index: int in range(3):
		var node: MeshInstance3D = _projection_nodes[index]
		if node != [_outline, _fill, _source][index] or node.visible != expected_visible[index] or var_to_bytes(node.transform) != var_to_bytes(Transform3D(Basis.IDENTITY, Vector3.UP * heights[index])):
			return "Required projected child identity/visibility/transform changed"
		if node.mesh != _projection_meshes[mesh_keys[index]] or node.material_override != _projection_materials[index]:
			return "Required projected mesh/material resource was replaced"
		if _renderer_bytes(node) != _projection_renderer_bytes[index]:
			return "Required projected native renderer properties changed"
		if _material_bytes(_projection_materials[index]) != _projection_material_bytes[index]:
			return "Required projected material policy changed"
	var color: Color = _phase_color("warning" if phase == "clear" else phase)
	for index: int in range(3):
		var expected: Color = Color(color.r, color.g, color.b, 0.22) if index == 1 else color
		if var_to_bytes(_projection_materials[index].albedo_color) != var_to_bytes(expected):
			return "Required projected phase material changed"
	# Guard every staged phase receipt, not only the currently selected one.
	# A later present therefore cannot heal a mutated future source marker.
	for key: String in _projection_meshes:
		var mesh: ArrayMesh = _projection_meshes[key]
		if mesh == null or _mesh_bytes(mesh) != _projection_mesh_bytes[key]:
			return "Required projected native mesh arrays/indices changed"
	return ""


func _present_projected(shape: Dictionary, source: Vector3, phase: String) -> bool:
	var error: String = projection_error(_projection)
	if not error.is_empty():
		return _reject(error)
	if not is_visible_in_tree():
		return _reject("Required projected cue is hidden by its parent")
	if _shape_wire(shape) != _shape_wire(_projection_shape) or _vector_wire(source) != _vector_wire(_projection_shape.origin):
		return _reject("Projected presentation must retain its exact original cone/source")
	var next: Dictionary = {"api_revision": API_REVISION, "phase": phase, "geometry": shape, "source_position": source, "required": true, "source_visible": true, "footprint_visible": phase != "recovery", "active_fill_visible": phase == "active"}
	last_error = ""
	if next == _cue_state:
		return true
	_cue_state = next
	_projection_source_phase = phase
	_source.mesh = _projection_meshes[phase]
	_outline.visible = next.footprint_visible
	_fill.visible = next.active_fill_visible
	_source.visible = true
	_set_projection_colors(phase)
	_notify()
	return true


func _clear_projected() -> bool:
	# Cancellation may still hide a broken child, but cannot repair its receipt
	# or allow later present/rebind to silently resume lost required authority.
	var error: String = projection_error(_projection)
	if not error.is_empty():
		_projection_fault = error
	if _cue_state.phase == "clear":
		return true
	_cue_state = {"api_revision": API_REVISION, "phase": "clear", "geometry": {}, "source_position": null, "required": true, "source_visible": false, "footprint_visible": false, "active_fill_visible": false}
	for node: Variant in [_outline, _fill, _source]:
		if is_instance_valid(node):
			node.visible = false
	if _projection_fault.is_empty():
		_projection_source_phase = "clear"
		_source.mesh = _projection_meshes["clear"]
		_set_projection_colors("warning")
	_notify()
	return true


func _required_native_error() -> String:
	if not is_instance_valid(_outline) or not is_instance_valid(_fill) or not is_instance_valid(_source):
		return "Required projected native child was freed"
	var names: Array[String] = ["RequiredFootprintOutline", "RequiredFootprintFill", "RequiredSourceMarker"]
	var nodes: Array[MeshInstance3D] = [_outline, _fill, _source]
	for index: int in range(3):
		var node: MeshInstance3D = nodes[index]
		if not is_instance_valid(node) or not node.is_inside_tree() or not node.is_node_ready() or node.is_queued_for_deletion() or node.get_parent() != self or get_node_or_null(names[index]) != node or node.get_world_3d() != get_world_3d() or node.get_script() != null or node.top_level:
			return "Required projected native child is unavailable or replaced"
		if node.material_overlay != null or node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF or node.layers != 1 or node.transparency != 0.0 or node.visibility_range_begin != 0.0 or node.visibility_range_end != 0.0:
			return "Required projected renderer policy changed"
		for surface: int in range(node.get_surface_override_material_count()):
			if node.get_surface_override_material(surface) != null:
				return "Required projected surface override material changed"
		var material: StandardMaterial3D = node.material_override as StandardMaterial3D
		if material == null or material.get_script() != null or material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA or material.cull_mode != BaseMaterial3D.CULL_DISABLED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.no_depth_test or material.next_pass != null or material.albedo_texture != null:
			return "Required projected material must retain depth-tested nearest phase grammar"
	return ""


static func _projection_input_error(event: Dictionary) -> String:
	# ExactJson has a total node/byte/depth budget before duplicate traversal.
	if ExactJson.stringify(event).is_empty():
		return "Projection event must be bounded closed finite exact JSON"
	var error: String = Codec.keys_error(event, PROJECTION_KEYS)
	if not error.is_empty():
		return error
	if not event.event_id is String or event.event_id.is_empty() or event.event_id.length() > 512 or event.kind not in ["primary", "blast"] or not Codec.is_integer(event.slot_id, 1, 2) or not Codec.is_integer(event.record_sequence, 1) or not Codec.in_range(event.at_s, 0.0, 1000000000000.0) or not event.record is Dictionary or not Codec.in_range(event.floor_y, -MAX_PROJECTED_COORD, MAX_PROJECTED_COORD):
		return "Unsupported original projected event identity/clock/floor"
	var record: Dictionary = event.record
	if not Codec.is_number(record.get("completed_at_s")):
		return "Original completed attack record required"
	error = PlayerRecord.world_action_record_error(record, float(record.completed_at_s))
	if not error.is_empty() or record.kind != event.kind or record.sequence != event.record_sequence:
		return "Projection must retain its original valid primary/blast record"
	var shape: Dictionary = _event_shape(event)
	if not Geometry.error(shape).is_empty() or not _bounded_point(record.world_origin) or absf(float(record.world_origin[1]) - float(event.floor_y)) > 0.02 or not Codec.in_range(record.geometry.reach, 0.000000001, 32.0):
		return "Original projection cone exceeds supported native geometry"
	if not event.triangle_vertices is Array or event.triangle_vertices.size() % 3 != 0 or not event.boundary_contours is Array or not event.bounds is Array:
		return "Projection requires consecutive fill triangles and closed contours"
	var count: int = event.triangle_vertices.size()
	var points: Array = event.triangle_vertices.duplicate()
	for point: Variant in event.triangle_vertices:
		if not _floor_point(point, float(event.floor_y)):
			return "Projected vertices must retain the exact encoded floor plane"
	for index: int in range(0, event.triangle_vertices.size(), 3):
		var a: Array = event.triangle_vertices[index]
		var b: Array = event.triangle_vertices[index + 1]
		var c: Array = event.triangle_vertices[index + 2]
		if (float(b[0]) - float(a[0])) * (float(c[2]) - float(a[2])) - (float(b[2]) - float(a[2])) * (float(c[0]) - float(a[0])) == 0.0:
			return "Projected triangle is degenerate"
	for contour: Variant in event.boundary_contours:
		if not contour is Dictionary or not Codec.keys_error(contour, ["hole", "vertices"]).is_empty() or not contour.hole is bool or not contour.vertices is Array or contour.vertices.size() < 4 or ExactJson.stringify(contour.vertices.front()) != ExactJson.stringify(contour.vertices.back()):
			return "Every projected boundary must be an explicitly closed contour"
		count += contour.vertices.size()
		if count > MAX_PROJECTED_VERTICES:
			return "Projected event exceeds its finite combined vertex budget"
		var area: float = 0.0
		for index: int in range(contour.vertices.size() - 1):
			var a: Variant = contour.vertices[index]
			var b: Variant = contour.vertices[index + 1]
			if not _floor_point(a, float(event.floor_y)) or not _floor_point(b, float(event.floor_y)) or (a[0] == b[0] and a[2] == b[2]):
				return "Projected contour must retain finite nonzero closed edges"
			area += float(a[0]) * float(b[2]) - float(b[0]) * float(a[2])
		if area == 0.0 or (area < 0.0) != contour.hole:
			return "Projected outer/hole contour winding changed"
		points.append_array(contour.vertices)
	if count > MAX_PROJECTED_VERTICES or (event.triangle_vertices.is_empty() != event.boundary_contours.is_empty()):
		return "Empty projected fill and contours must agree within the vertex budget"
	if points.is_empty():
		return "" if event.bounds.is_empty() else "Empty projection must retain empty bounds"
	var bounds: Array = [float(points[0][0]), float(points[0][2]), float(points[0][0]), float(points[0][2])]
	for point: Array in points:
		bounds[0] = minf(bounds[0], float(point[0]))
		bounds[1] = minf(bounds[1], float(point[2]))
		bounds[2] = maxf(bounds[2], float(point[0]))
		bounds[3] = maxf(bounds[3], float(point[2]))
	if ExactJson.stringify(event.bounds) != ExactJson.stringify(bounds):
		return "Projected bounds must exactly enclose the encoded fill/contours"
	var outline: Dictionary = _outline_plan(event)
	return "" if outline.accepted else outline.reason


static func _event_shape(event: Dictionary) -> Dictionary:
	var record: Dictionary = event.record
	var raw: Dictionary = record.geometry
	return Geometry.cone(Codec.read_vector3(record.world_origin), Codec.read_vector3(record.direction), float(raw.reach), float(raw.cone_min_dot), float(raw.origin_disk_radius))


static func _bounded_point(point: Variant) -> bool:
	return Codec.is_vector3(point) and absf(float(point[0])) <= MAX_PROJECTED_COORD and absf(float(point[1])) <= MAX_PROJECTED_COORD and absf(float(point[2])) <= MAX_PROJECTED_COORD


static func _floor_point(point: Variant, floor_y: float) -> bool:
	return _bounded_point(point) and float(point[1]) == floor_y


static func _local_point(point: Array, anchor: Vector3) -> Vector3:
	return Vector3(float(point[0]) - float(anchor.x), float(point[1]) - float(anchor.y), float(point[2]) - float(anchor.z))


static func _outline_plan(event: Dictionary) -> Dictionary:
	# Clip only real outer/hole boundary ribbons to the authenticated inward
	# filled cells. Cell seams never become new outlines; no contour is filled.
	var edges: int = 0
	for contour: Dictionary in event.boundary_contours:
		edges += contour.vertices.size() - 1
	if edges * (event.triangle_vertices.size() / 3) > MAX_OUTLINE_PAIR_TESTS:
		return {"accepted": false, "reason": "Projected outline exceeds bounded clipping work"}
	var vertices: Array[Vector3] = []
	var cells: Array = []
	for index: int in range(0, event.triangle_vertices.size(), 3):
		var triangle: Array = []
		for point: Array in event.triangle_vertices.slice(index, index + 3):
			triangle.append([float(point[0]), float(point[2])])
		cells.append({"triangle": triangle, "bounds": [minf(triangle[0][0], minf(triangle[1][0], triangle[2][0])), minf(triangle[0][1], minf(triangle[1][1], triangle[2][1])), maxf(triangle[0][0], maxf(triangle[1][0], triangle[2][0])), maxf(triangle[0][1], maxf(triangle[1][1], triangle[2][1]))]})
	var anchor: Vector3 = CueMesh.anchor(_event_shape(event))
	for contour: Dictionary in event.boundary_contours:
		for edge: int in range(contour.vertices.size() - 1):
			var a: Array = contour.vertices[edge]
			var b: Array = contour.vertices[edge + 1]
			var dx: float = float(b[0]) - float(a[0])
			var dz: float = float(b[2]) - float(a[2])
			var length: float = sqrt(dx * dx + dz * dz)
			if not is_finite(length) or length <= 0.0:
				return {"accepted": false, "reason": "Required projected contour edge exceeds native outline precision"}
			var sx: float = -dz / length * Footprint.EDGE_WIDTH * 0.5
			var sz: float = dx / length * Footprint.EDGE_WIDTH * 0.5
			var ribbon: Array = [[float(a[0]) + sx, float(a[2]) + sz], [float(b[0]) + sx, float(b[2]) + sz], [float(b[0]) - sx, float(b[2]) - sz], [float(a[0]) - sx, float(a[2]) - sz]]
			var before: int = vertices.size()
			var bounds: Array = [minf(float(a[0]), float(b[0])) - absf(sx), minf(float(a[2]), float(b[2])) - absf(sz), maxf(float(a[0]), float(b[0])) + absf(sx), maxf(float(a[2]), float(b[2])) + absf(sz)]
			for cell: Dictionary in cells:
				if bounds[2] < cell.bounds[0] or bounds[0] > cell.bounds[2] or bounds[3] < cell.bounds[1] or bounds[1] > cell.bounds[3]:
					continue
				var polygon: Array = _clip_triangle(ribbon, cell.triangle)
				for fan: int in range(1, polygon.size() - 1):
					# Fan triangulation is safe here: intersection of a convex
					# ribbon with one convex accepted triangle has no hole.
					var va: Vector3 = _local_point([polygon[0][0], event.floor_y, polygon[0][1]], anchor)
					var vb: Vector3 = _local_point([polygon[fan][0], event.floor_y, polygon[fan][1]], anchor)
					var vc: Vector3 = _local_point([polygon[fan + 1][0], event.floor_y, polygon[fan + 1][1]], anchor)
					if (float(vb.x) - float(va.x)) * (float(vc.z) - float(va.z)) - (float(vb.z) - float(va.z)) * (float(vc.x) - float(va.x)) == 0.0:
						continue
					vertices.append_array([va, vb, vc])
					if vertices.size() > MAX_OUTLINE_VERTICES:
						return {"accepted": false, "reason": "Projected native outline exceeds bounded vertex output"}
			if vertices.size() == before:
				return {"accepted": false, "reason": "Required projected contour edge has no native safe interior"}
	return {"accepted": true, "vertices": vertices}


static func _clip_triangle(ribbon: Array, triangle: Array) -> Array:
	var polygon: Array = ribbon.duplicate(true)
	var winding: float = _cross2(triangle[0], triangle[1], triangle[2])
	for edge: int in range(3):
		if polygon.is_empty():
			break
		var a: Array = triangle[edge]
		var b: Array = triangle[(edge + 1) % 3]
		var clipped: Array = []
		var previous: Array = polygon.back()
		var previous_side: float = _cross2(a, b, previous) * signf(winding)
		for current: Array in polygon:
			var side: float = _cross2(a, b, current) * signf(winding)
			if (side >= 0.0) != (previous_side >= 0.0):
				var ratio: float = previous_side / (previous_side - side)
				clipped.append([float(previous[0]) + (float(current[0]) - float(previous[0])) * ratio, float(previous[1]) + (float(current[1]) - float(previous[1])) * ratio])
			if side >= 0.0:
				clipped.append(current)
			previous = current
			previous_side = side
		polygon = clipped
	return polygon


static func _cross2(a: Array, b: Array, point: Array) -> float:
	return (float(b[0]) - float(a[0])) * (float(point[1]) - float(a[1])) - (float(b[1]) - float(a[1])) * (float(point[0]) - float(a[0]))


static func _mesh_bytes(mesh: ArrayMesh) -> PackedByteArray:
	if mesh.shadow_mesh != null or mesh.get_blend_shape_count() != 0:
		return PackedByteArray()
	for index: int in range(mesh.get_surface_count()):
		if mesh.surface_get_material(index) != null:
			return PackedByteArray()
	# Installed ed1daf0bf mesh.cpp _get_surfaces queries the RenderingServer's
	# actual vertex/attribute/index/LOD buffers. Array caches alone are weaker.
	return var_to_bytes([mesh.get_surface_count(), mesh.custom_aabb, mesh.blend_shape_mode, mesh.get("_surfaces")])


static func _material_bytes(material: StandardMaterial3D) -> PackedByteArray:
	# Phase albedo alone changes. All other stored native material properties,
	# including texture/pass resources, retain their exact values/identities.
	return _property_bytes(material, ["albedo_color", "resource_name", "resource_path", "resource_local_to_scene"])


static func _renderer_bytes(node: MeshInstance3D) -> PackedByteArray:
	return _property_bytes(node, ["mesh", "material_override", "visible", "transform", "position", "rotation", "rotation_degrees", "quaternion", "basis", "scale", "global_transform", "global_position", "global_basis", "global_rotation", "global_rotation_degrees", "global_scale", "name", "owner", "unique_name_in_owner", "process_mode", "process_priority", "process_physics_priority"])


static func _property_bytes(object: Object, excluded: Array[String]) -> PackedByteArray:
	var values: Array = []
	for info: Dictionary in object.get_property_list():
		var key: String = String(info.name)
		if (int(info.usage) & PROPERTY_USAGE_STORAGE) == 0 or key in excluded or key.begins_with("surface_material_override/"):
			continue
		var value: Variant = object.get(key)
		# Never serialize an object. Resource custody is native instance ID.
		values.append([key, ["object", value.get_instance_id()] if value is Object else value])
	return var_to_bytes(values)


func _set_projection_colors(phase: String) -> void:
	var color: Color = _phase_color(phase)
	(_outline.material_override as StandardMaterial3D).albedo_color = color
	(_fill.material_override as StandardMaterial3D).albedo_color = Color(color.r, color.g, color.b, 0.22)
	(_source.material_override as StandardMaterial3D).albedo_color = color


static func _shape_wire(shape: Dictionary) -> String:
	if shape.get("kind") != "cone":
		return ""
	return ExactJson.stringify({"kind": "cone", "origin": Codec.vector3(shape.origin), "direction": Codec.vector3(shape.direction), "reach": shape.reach, "min_dot": shape.min_dot, "origin_radius": shape.origin_radius})


static func _vector_wire(value: Variant) -> String:
	return ExactJson.stringify(Codec.vector3(value)) if value is Vector3 else ""
