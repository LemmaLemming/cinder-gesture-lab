class_name Act1SeleniteKingArt
extends Node3D
## Original B01 royal costume, drawn as shallow stepped native triangles.
## Native state/facing selects authored poses. No clocks, cues or combat authority.
## Actor-controlled inherited hiding is valid; local art visibility is retained.

const PIXEL_STEP: float = 0.022
const LOGICAL_SIZE: Vector2i = Vector2i(80, 96)
const FEET_PIVOT: Vector2i = Vector2i(40, 96)
const FULL_RESERVE: AABB = AABB(Vector3(-0.88, 0, -0.022), Vector3(1.76, 2.112, 0.044))
const PHASES: Array[String] = ["idle", "warning", "lock", "active", "recovery", "summon", "defeat", "step"]
const FACINGS: Array[String] = ["front", "side", "back"]
const SIDE_FLIP: Transform3D = Transform3D(Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)), Vector3.ZERO)
const NODE_MUTABLE: Array[String] = ["transform", "position", "rotation", "rotation_degrees", "quaternion", "scale", "visible"]
const INK: float = 20.0 / 255.0
const COAL: float = 39.0 / 255.0
const SHADE: float = 67.0 / 255.0
const MID: float = 105.0 / 255.0
const SILVER: float = 147.0 / 255.0
const LIGHT: float = 193.0 / 255.0
const WHITE: float = 231.0 / 255.0

var _carrier: Node3D
var _poses: Dictionary = {}
var _nodes: Array[Dictionary] = []
var _geometry: Array[Dictionary] = []
var _material: StandardMaterial3D
var _material_bytes: PackedByteArray
var _script: Script
var _parent: Node3D
var _actor: Node3D
var _actor_script: Script
var _world: World3D
var _owner_basis: Basis = Basis.IDENTITY
var _camera: Camera3D
var _camera_projection: PackedByteArray
var _camera_basis: Basis = Basis.IDENTITY
var _carrier_frame: Transform3D = Transform3D.IDENTITY
var _carrier_global_basis: Basis = Basis.IDENTITY
var _phase: String = "idle"
var _facing: String = "front"
var _mirror: bool = false
var _pose_input_error: String = ""
var _selecting: bool = false


func _init() -> void:
	name = "KingArt"
	process_mode = Node.PROCESS_MODE_DISABLED
	_script = get_script()
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true
	_material.albedo_color = Color.WHITE
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	_material.no_depth_test = false
	_material.render_priority = 0
	_carrier = Node3D.new()
	_carrier.name = "PoseCarrier"
	_carrier.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(_carrier)
	for facing: String in FACINGS:
		for phase: String in PHASES:
			var mesh := MeshInstance3D.new()
			mesh.name = facing.capitalize() + phase.capitalize()
			mesh.mesh = _build_pose(facing, phase)
			mesh.material_override = _material
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mesh.process_mode = Node.PROCESS_MODE_DISABLED
			mesh.visible = facing == "front" and phase == "idle"
			_carrier.add_child(mesh)
			_poses[facing + "/" + phase] = mesh
	# Retain exact authored nodes/resources BEFORE attachment callbacks.
	var nodes: Array[Node3D] = [self, _carrier]
	for raw: Node in _carrier.get_children(): nodes.append(raw as Node3D)
	for node: Node3D in nodes:
		_nodes.append({"node": node, "parent": node.get_parent(), "name": node.name, "script": node.get_script(), "children": node.get_children(), "properties": _properties(node, NODE_MUTABLE)})
		if node is MeshInstance3D:
			var mesh := node as MeshInstance3D
			_geometry.append({"node": mesh, "mesh": mesh.mesh, "bytes": _mesh_bytes(mesh.mesh)})
	_material_bytes = _properties(_material)


func _enter_tree() -> void:
	# First actual owner identity is retained once; reattachment cannot rebind it.
	# This latches no gameplay state and does not learn authored-resource changes.
	if _parent == null:
		_parent = get_parent() as Node3D
		_actor = _parent.get_parent() as Node3D if _parent != null else null
		_actor_script = _actor.get_script() as Script if _actor != null else null
		_world = get_world_3d()
		_owner_basis = _parent.global_basis if _parent != null else Basis.IDENTITY
		_carrier_global_basis = _owner_basis


func set_pose(phase: String, world_facing: Vector3, camera: Camera3D) -> void:
	var selected: String = "idle" if phase == "clear" else phase
	if selected not in PHASES or _selecting:
		_pose_input_error = "King pose requires one closed native phase outside a pose transaction"
		return
	# A newly installed dormant source can precede the viewport camera. Leave
	# its original idle untouched; world_corners still requires the actual camera.
	if camera == null and _camera == null and selected == "idle": return
	var error: String = _binding_error(false, false)
	if not error.is_empty():
		_pose_input_error = error
		return
	if not _actual_camera(camera):
		_pose_input_error = "King pose requires its actual live native viewport camera and world"
		return
	var facing := Vector3(world_facing.x, 0, world_facing.z)
	var toward := Vector3(camera.global_basis.z.x, 0, camera.global_basis.z.z)
	var right := Vector3(camera.global_basis.x.x, 0, camera.global_basis.x.z)
	if not world_facing.is_finite() or facing.is_zero_approx() or toward.is_zero_approx() or right.is_zero_approx() or not camera.global_basis.is_finite():
		_pose_input_error = "King pose requires finite nonzero planar facing and camera axes"
		return
	var projection: PackedByteArray = _projection_bytes(camera)
	if _camera != null and (camera != _camera or projection != _camera_projection):
		_pose_input_error = "Retain the actual King camera identity and native projection"
		return
	facing = facing.normalized()
	var forward_amount: float = facing.dot(toward.normalized())
	var side_amount: float = facing.dot(right.normalized())
	var artwork_facing: String = "front" if forward_amount >= 0 else "back"
	if absf(side_amount) > absf(forward_amount): artwork_facing = "side"
	var relative_basis: Basis = global_basis.inverse() * camera.global_basis
	if not relative_basis.is_finite():
		_pose_input_error = "King camera-facing art frame must remain finite"
		return
	_selecting = true
	if _camera == null:
		_camera = camera
		_camera_projection = projection
	_camera_basis = camera.global_basis
	_phase = selected
	_facing = artwork_facing
	_mirror = artwork_facing == "side" and side_amount < 0
	_carrier.transform = Transform3D(relative_basis, Vector3.ZERO)
	_carrier_frame = _carrier.transform
	_carrier_global_basis = _carrier.global_basis
	for key: String in _poses:
		var mesh: MeshInstance3D = _poses[key]
		if not is_instance_valid(mesh):
			_pose_input_error = "King pose lost a retained authored mesh"
			_selecting = false
			return
		mesh.transform = SIDE_FLIP if key == _facing + "/" + _phase and _mirror else Transform3D.IDENTITY
		mesh.visible = key == _facing + "/" + _phase
	_selecting = false
	_pose_input_error = ""
	# A visibility observer can invalidate a binding. Do not repair it.
	_pose_input_error = _binding_error(false, true)


func pose_name() -> String:
	return _phase


func facing_name() -> String:
	return _facing


func binding_error() -> String:
	return _binding_error(true, true)


func _binding_error(include_input_error: bool, check_camera_frame: bool) -> String:
	if _selecting: return "King art requires a completed supported pose transaction"
	if not is_inside_tree() or is_queued_for_deletion() or get_script() != _script or not is_instance_valid(_parent) or not is_instance_valid(_actor): return "King art requires its retained actual owner tree"
	if get_parent() != _parent or _parent.get_parent() != _actor or not _parent.is_inside_tree() or _parent.is_queued_for_deletion() or not _actor.is_inside_tree() or _actor.is_queued_for_deletion() or _parent.name != "KingPresentation" or _parent.get_script() != null or _actor.get_script() != _actor_script: return "King art owner identity or script binding changed"
	if get_world_3d() != _world or _parent.get_world_3d() != _world or _actor.get_world_3d() != _world or _parent.transform != Transform3D.IDENTITY or _parent.global_basis != _owner_basis or _parent.is_set_as_top_level() or transform != Transform3D.IDENTITY or is_set_as_top_level(): return "King art must retain its actor world and identity feet frame"
	if _phase not in PHASES or _facing not in FACINGS or (_mirror and _facing != "side") or _poses.size() != PHASES.size() * FACINGS.size(): return "Retain the closed original King pose/facing table"
	if not is_instance_valid(_carrier): return "Retained King camera-facing carrier is unavailable"
	for facing: String in FACINGS:
		for phase: String in PHASES:
			var mesh: Variant = _poses.get(facing + "/" + phase)
			if not is_instance_valid(mesh) or mesh != _carrier.get_node_or_null(facing.capitalize() + phase.capitalize()): return "King authored pose handle was substituted"
	if include_input_error and not _pose_input_error.is_empty(): return _pose_input_error
	if _camera != null:
		if not _actual_camera(_camera) or _projection_bytes(_camera) != _camera_projection: return "Retained King camera/world/projection changed"
		if check_camera_frame and _camera.global_basis != _camera_basis: return "King pose no longer matches the actual camera basis"
	elif _phase != "idle" or _facing != "front" or _mirror or _carrier_frame != Transform3D.IDENTITY:
		return "A camera-free King must retain its original front idle"
	if _carrier.global_basis != _carrier_global_basis: return "King camera-facing carrier world basis changed"
	for record: Dictionary in _nodes:
		if not is_instance_valid(record.node): return "Required King art node is unavailable"
		var node: Node3D = record.node
		var parent: Node = _parent if node == self else record.parent
		if not node.is_inside_tree() or node.is_queued_for_deletion() or node.get_parent() != parent or node.name != record.name or node.get_script() != record.script or node.get_children() != record.children or _properties(node, NODE_MUTABLE) != record.properties: return "Retained King art tree/renderer binding changed"
		if node.is_set_as_top_level() or node.process_mode != Node.PROCESS_MODE_DISABLED or node.is_processing() or node.is_physics_processing(): return "King art must remain a clockless local presentation leaf"
		var expected_frame: Transform3D = _carrier_frame if node == _carrier else Transform3D.IDENTITY
		var expected_visible: bool = true
		if node is MeshInstance3D:
			expected_visible = node == _poses[_facing + "/" + _phase]
			if expected_visible and _mirror: expected_frame = SIDE_FLIP
		if node.transform != expected_frame or node.visible != expected_visible: return "King local pose frame/visibility changed"
	# Inherited hiding is controlled by the native actor's dormant/dead flags;
	# require local visibility above, not is_visible_in_tree().
	if not is_instance_valid(_material) or _material.get_script() != null or _properties(_material) != _material_bytes: return "Retained King material/settings changed"
	for record: Dictionary in _geometry:
		var mesh: MeshInstance3D = record.node
		if not is_instance_valid(record.mesh) or mesh.mesh != record.mesh or mesh.material_override != _material or mesh.material_overlay != null or _mesh_bytes(record.mesh) != record.bytes: return "King authored mesh/material identity or complete geometry changed"
		if not FULL_RESERVE.encloses(mesh.get_aabb()): return "King geometry exceeds its complete reserved art frame"
		for index: int in mesh.get_surface_override_material_count():
			if mesh.get_surface_override_material(index) != null: return "King surface material overrides are unsupported"
	return ""


func world_corners(camera: Camera3D) -> Array:
	if not binding_error().is_empty() or _camera == null or camera != _camera or not _actual_camera(camera): return [Vector3.INF]
	var points: Array[Vector3] = []
	# Preserve the entire logical canvas/depth reserve, including blank margins.
	points.append_array(_box_points(FULL_RESERVE, _carrier.global_transform))
	for record: Dictionary in _geometry:
		var mesh: MeshInstance3D = record.node
		if mesh.visible: points.append_array(_box_points(mesh.get_aabb(), mesh.global_transform))
	for point: Vector3 in points:
		if not point.is_finite(): return [Vector3.INF]
	return points


func _actual_camera(camera: Camera3D) -> bool:
	return is_instance_valid(camera) and camera.is_inside_tree() and not camera.is_queued_for_deletion() and camera.get_script() == null and camera.get_world_3d() == _world and camera.get_viewport() == get_viewport() and get_viewport().get_camera_3d() == camera and camera.global_basis.is_finite()


static func _projection_bytes(camera: Camera3D) -> PackedByteArray:
	return var_to_bytes([camera.get_camera_projection(), camera.projection, camera.size, camera.fov, camera.keep_aspect, camera.near, camera.far, camera.frustum_offset, camera.h_offset, camera.v_offset, camera.get_viewport().get_instance_id()])


static func _properties(object: Object, excluded: Array[String] = []) -> PackedByteArray:
	var values: Array = []
	for info: Dictionary in object.get_property_list():
		var key: String = String(info.name)
		if (int(info.usage) & PROPERTY_USAGE_STORAGE) == 0 or (int(info.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 or key in excluded: continue
		var value: Variant = object.get(key)
		values.append([key, ["object", value.get_instance_id()] if value is Object and is_instance_valid(value) else value])
	return var_to_bytes(values)


static func _mesh_bytes(mesh: Mesh) -> PackedByteArray:
	if not is_instance_valid(mesh) or mesh.get_script() != null: return PackedByteArray()
	var surfaces: Array = []
	for index: int in mesh.get_surface_count():
		if mesh.surface_get_material(index) != null: return PackedByteArray()
		surfaces.append(mesh.surface_get_arrays(index))
	return var_to_bytes([_properties(mesh), mesh.get_aabb(), surfaces])


static func _box_points(bounds: AABB, frame: Transform3D) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]: points.append(frame * Vector3(x, y, z))
	return points


static func _build_pose(facing: String, phase: String) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var lowered: int = 5 if phase == "recovery" else (18 if phase == "defeat" else 0)
	var lean: int = 4 if phase == "active" else (2 if phase == "step" else 0)
	if facing == "side":
		_side_costume(vertices, colors, phase, lowered, lean)
	else:
		_broad_costume(vertices, colors, facing == "back", phase, lowered, lean)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _broad_costume(v: PackedVector3Array, c: PackedColorArray, back: bool, phase: String, low: int, lean: int) -> void:
	# Split robe surrounds a narrow ribbed actor core; no skirt covers the feet.
	_poly(v,c,[[31,34+low],[23,38+low],[19,66],[9,89],[25,87],[33,74],[35,51+low]],COAL,0)
	_poly(v,c,[[49,34+low],[57,38+low],[61,66],[71,89],[55,87],[47,74],[45,51+low]],COAL,0)
	_ribbon(v,c,Vector2(30,37+low),Vector2(15,87),2,LIGHT,0.004)
	_ribbon(v,c,Vector2(50,37+low),Vector2(65,87),2,LIGHT,0.004)
	for index: int in 3:
		_rect(v,c,17+index*4,72+index*3,2,8,SHADE,0.006)
		_rect(v,c,61-index*4,72+index*3,2,8,MID,0.006)
	if phase == "step":
		# One planted boot and one lifted boot signal the actual bounded body step.
		# The unchanged actor feet pivot and full royal art reserve carry motion.
		_poly(v,c,[[33,55],[39,58],[39,81],[36,93],[28,93],[30,80]],INK,0.004)
		_poly(v,c,[[41,58],[47,55],[54,78],[57,90],[49,91],[45,80]],INK,0.004)
		_poly(v,c,[[28,91],[37,91],[39,96],[25,96],[25,94]],LIGHT,0.008)
		_poly(v,c,[[49,88],[56,88],[60,92],[60,93],[47,93]],SILVER,0.008)
	else:
		_poly(v,c,[[33,55+low],[39,58+low],[37,82],[36,93],[28,93],[29,81]],INK,0.004)
		_poly(v,c,[[41,58+low],[47,55+low],[51,81],[53,93],[44,93],[43,83]],INK,0.004)
		_poly(v,c,[[28,91],[37,91],[39,96],[25,96],[25,94]],LIGHT,0.008)
		_poly(v,c,[[45,91],[52,91],[56,95],[56,96],[43,96]],SILVER,0.008)
	_poly(v,c,[[30+lean,35+low],[50+lean,35+low],[49,58+low],[40,67],[31,58+low]],SHADE,0.006)
	for index: int in 6:
		var y: int = 38+low+index*4
		_poly(v,c,[[31+lean,y],[40+lean,y+3],[49+lean,y],[48+lean,y+2],[40+lean,y+5],[32+lean,y+2]],SILVER if back else WHITE,0.010)
	if back:
		_rect(v,c,39+lean,35+low,2,27,LIGHT,0.014)
		_poly(v,c,[[31+lean,20+low],[47+lean,20+low],[48+lean,31+low],[40+lean,36+low],[32+lean,31+low]],COAL,0.012)
	else:
		_poly(v,c,[[32+lean,20+low],[47+lean,20+low],[49+lean,29+low],[43+lean,36+low],[37+lean,36+low],[31+lean,29+low]],LIGHT,0.012)
		_rect(v,c,32+lean,24+low,15,6,INK,0.014)
		_rect(v,c,34+lean,25+low,3,2,WHITE,0.016)
		_rect(v,c,43+lean,25+low,3,2,WHITE,0.016)
		_rect(v,c,38+lean,30+low,4,2,COAL,0.016)
	_crown(v,c,Vector2(40+lean,17+low),back)
	var lifted: bool = phase in ["warning","summon"]
	var hand := Vector2(10 if phase == "summon" else 16, 31+low if lifted else 57+low)
	if phase == "lock": hand = Vector2(22,44)
	if phase == "active": hand = Vector2(19,43)
	if phase == "step": hand = Vector2(19,61)
	_sleeve(v,c,Vector2(31+lean,38+low),hand)
	_hand(v,c,hand,lifted)
	var staff_x: int = 66 if phase == "summon" else 62
	var staff_top: int = 28 if lifted else (48 if phase == "recovery" else 38)
	if phase == "lock": staff_top = 32
	if phase == "defeat": staff_top = 62
	if phase == "step": staff_top = 42
	_sleeve(v,c,Vector2(49+lean,38+low),Vector2(staff_x-2,staff_top+17))
	_rect(v,c,staff_x,staff_top+5,2,87-(staff_top+5),SILVER,0.014)
	_hand(v,c,Vector2(staff_x-2,staff_top+17),false)
	_star(v,c,Vector2(staff_x+1,staff_top),6,2,LIGHT,0.018)
	_star(v,c,Vector2(21,75),4,1,SILVER,0.014)
	_crescent(v,c,Vector2(60,78),5,LIGHT,0.014)


static func _side_costume(v: PackedVector3Array, c: PackedColorArray, phase: String, low: int, lean: int) -> void:
	_poly(v,c,[[35+lean,35+low],[27,44+low],[18,87],[33,90],[41,67],[44,48+low]],COAL,0)
	_ribbon(v,c,Vector2(32+lean,38+low),Vector2(24,87),2,LIGHT,0.004)
	if phase == "step":
		_poly(v,c,[[36,60],[42,61],[40,80],[33,92],[25,92],[33,79]],INK,0.004)
		_poly(v,c,[[43,60],[48,58],[55,80],[61,94],[52,95],[46,82]],COAL,0.004)
		_poly(v,c,[[25,88],[32,88],[35,93],[35,94],[22,94]],LIGHT,0.008)
		_poly(v,c,[[52,92],[59,92],[64,95],[64,96],[50,96]],SILVER,0.008)
	else:
		_poly(v,c,[[36,60],[42,61],[42,83],[38,95],[30,95],[34,80]],INK,0.004)
		_poly(v,c,[[43,60],[48,58],[53,80],[58,94],[49,95],[44,82]],COAL,0.004)
		_poly(v,c,[[30,91],[37,91],[38,96],[26,96],[26,94]],LIGHT,0.008)
		_poly(v,c,[[49,92],[56,92],[61,95],[61,96],[47,96]],SILVER,0.008)
	_poly(v,c,[[35+lean,35+low],[48+lean,36+low],[47,59+low],[40,65],[34,57+low]],SHADE,0.006)
	for index: int in 6:
		var y: int = 38+low+index*4
		_poly(v,c,[[36+lean,y],[47+lean,y+2],[46+lean,y+4],[36+lean,y+2]],WHITE,0.010)
	_poly(v,c,[[36+lean,20+low],[47+lean,20+low],[49+lean,26+low],[54+lean,27+low],[48+lean,30+low],[44+lean,36+low],[37+lean,32+low]],LIGHT,0.012)
	_rect(v,c,45+lean,24+low,4,4,INK,0.014)
	_rect(v,c,46+lean,25+low,2,1,WHITE,0.016)
	_crown(v,c,Vector2(42+lean,17+low),false,true)
	var raised: bool = phase in ["warning","summon"]
	var hand := Vector2(65,33+low if raised else 55+low)
	if phase == "lock": hand = Vector2(61,43)
	if phase == "active": hand = Vector2(72,42)
	# Summon is a separate high open hand, not the side warning silhouette.
	if phase == "summon": hand = Vector2(72,24)
	if phase == "step": hand = Vector2(63,58)
	_sleeve(v,c,Vector2(45+lean,39+low),hand)
	_hand(v,c,hand,raised)
	var staff_x: int = 20 if phase == "summon" else (28 if phase == "step" else 25)
	var top: int = 32 if raised else (48 if phase == "recovery" else 40)
	if phase == "lock": top = 34
	if phase == "defeat": top = 63
	if phase == "summon": top = 24
	if phase == "step": top = 43
	_sleeve(v,c,Vector2(36+lean,38+low),Vector2(staff_x+3,top+17))
	_rect(v,c,staff_x,top+5,2,88-(top+5),SILVER,0.014)
	_hand(v,c,Vector2(staff_x+3,top+17),false)
	_star(v,c,Vector2(staff_x+1,top),6,2,LIGHT,0.018)
	_crescent(v,c,Vector2(27,76),5,LIGHT,0.014)
	_star(v,c,Vector2(30,60+low),3,1,SILVER,0.014)


static func _crown(v: PackedVector3Array, c: PackedColorArray, center: Vector2, back: bool, side: bool = false) -> void:
	var x: float = center.x
	var y: float = center.y
	var width: float = 10 if side else 14
	_poly(v,c,[[x,y-16],[x+3,y-6],[x+width,y-8],[x+7,y-1],[x+width,y+4],[x+4,y+4],[x,y+10],[x-4,y+4],[x-width,y+4],[x-7,y-1],[x-width,y-8],[x-3,y-6]],SILVER if back else WHITE,0.014)
	_rect(v,c,x-5,y+1,10,3,MID,0.016)


static func _sleeve(v: PackedVector3Array, c: PackedColorArray, shoulder: Vector2, hand: Vector2) -> void:
	var delta: Vector2 = hand-shoulder
	var side := Vector2(-delta.y,delta.x).normalized()
	_poly(v,c,[shoulder-side*6,hand-side*5,hand+side*5,shoulder+side*7],COAL,0.012)
	_ribbon(v,c,shoulder+side*5,hand+side*3,2,LIGHT,0.014)
	_ribbon(v,c,shoulder-side*2,hand-side*2,1,SILVER,0.016)


static func _hand(v: PackedVector3Array, c: PackedColorArray, center: Vector2, raised: bool) -> void:
	_rect(v,c,center.x-2,center.y-2,5,5,LIGHT,0.016)
	if raised:
		for index: int in 3: _rect(v,c,center.x-2+index*2,center.y-7+index%2,1,6,LIGHT,0.016)


static func _crescent(v: PackedVector3Array, c: PackedColorArray, center: Vector2, radius: float, silver: float, z: float) -> void:
	_poly(v,c,[[center.x+radius,center.y-radius],[center.x,center.y-radius+1],[center.x-radius,center.y],[center.x,center.y+radius],[center.x+radius,center.y+radius-1],[center.x,center.y+2],[center.x-2,center.y],[center.x,center.y-2]],silver,z)


static func _star(v: PackedVector3Array, c: PackedColorArray, center: Vector2, outer: float, inner: float, silver: float, z: float) -> void:
	var polygon: Array = []
	for index: int in 10:
		var angle: float = -PI*0.5+float(index)*PI/5.0
		var radius: float = outer if index%2 == 0 else inner
		# Snap decorative texel clusters; no subpixel rotation animation.
		polygon.append(center+Vector2(roundf(cos(angle)*radius),roundf(sin(angle)*radius)))
	_poly(v,c,polygon,silver,z)


static func _ribbon(v: PackedVector3Array, c: PackedColorArray, a: Vector2, b: Vector2, width: float, silver: float, z: float) -> void:
	var delta: Vector2 = b-a
	var side := Vector2(-delta.y,delta.x).normalized()*width*0.5
	_poly(v,c,[a-side,b-side,b+side,a+side],silver,z)


static func _rect(v: PackedVector3Array, c: PackedColorArray, x: float, y: float, width: float, height: float, silver: float, z: float) -> void:
	_poly(v,c,[[x,y],[x+width,y],[x+width,y+height],[x,y+height]],silver,z)


static func _poly(v: PackedVector3Array, c: PackedColorArray, points: Array, silver: float, z: float) -> void:
	var polygon := PackedVector2Array()
	for raw: Variant in points:
		var point: Vector2 = raw if raw is Vector2 else Vector2(float(raw[0]),float(raw[1]))
		polygon.append(point)
	for index: int in Geometry2D.triangulate_polygon(polygon):
		var point: Vector2 = polygon[index]
		v.append(Vector3((point.x-FEET_PIVOT.x)*PIXEL_STEP,(FEET_PIVOT.y-point.y)*PIXEL_STEP,z))
		c.append(Color(silver,silver,silver,1))
