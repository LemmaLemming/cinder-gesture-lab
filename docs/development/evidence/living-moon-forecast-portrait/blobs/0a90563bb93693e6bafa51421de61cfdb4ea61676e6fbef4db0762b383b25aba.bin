class_name Act1LivingMoonArt
extends Node3D
## Authored B02 human Moon, built from shallow stepped native triangles.
## A clockless presentation leaf. The parent supplies genuine native phases;
## meshes change pose while the eye and nose attachment pivots stay fixed.

const PIXEL_STEP: float = 0.022
const NOSE_ANCHOR: Vector3 = Vector3(2.0, 0.0, -1.0)
## Camera-facing shallow relief clears the large face behind this fixed source.
## This moves renderer vertices only; the actual nose floor pivot stays fixed.
const NOSE_RENDER_DEPTH: float = 0.7
const PHASES: Array[String] = ["idle", "warning", "lock", "active", "recovery", "clear"]
const EXPRESSIONS: Array[String] = ["neutral", "indignant", "flinch"]
const FACE_BOUNDS: AABB = AABB(Vector3(-2.464, 0.0, -0.055), Vector3(7.040, 6.952, 0.110))
const EYE_BOUNDS: AABB = AABB(Vector3(-1.210, 0.0, -0.055), Vector3(2.420, 2.200, 0.110))
const NOSE_BOUNDS: AABB = AABB(Vector3(-0.792, 0.0, 0.645), Vector3(1.584, 2.112, 0.110))
const INK: float = 20.0 / 255.0
const COAL: float = 39.0 / 255.0
const SHADE: float = 67.0 / 255.0
const MID: float = 105.0 / 255.0
const SILVER: float = 147.0 / 255.0
const LIGHT: float = 193.0 / 255.0
const WHITE: float = 231.0 / 255.0

var _face_carrier: Node3D
var _eye_carrier: Node3D
var _nose_carrier: Node3D
var _faces: Dictionary = {}
var _eyes: Dictionary = {}
var _noses: Dictionary = {}
var _camera: Camera3D
var _eye_phase: String = "idle"
var _nose_phase: String = "idle"
var _expression: String = "neutral"


func _init() -> void:
	name = "LivingMoonArt"
	process_mode = Node.PROCESS_MODE_DISABLED
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color.WHITE
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	material.no_depth_test = false
	material.render_priority = 0
	_face_carrier = _carrier("FaceCarrier", Vector3.ZERO)
	_eye_carrier = _carrier("EyeCarrier", Vector3.ZERO)
	_nose_carrier = _carrier("NoseCarrier", NOSE_ANCHOR)
	for expression: String in EXPRESSIONS:
		_faces[expression] = _mesh_node(_face_carrier, expression.capitalize(), _face_mesh(expression), material)
		for phase: String in PHASES:
			_eyes[expression + "/" + phase] = _mesh_node(_eye_carrier, expression.capitalize() + phase.capitalize(), _eye_mesh(phase, expression), material)
	for phase: String in PHASES:
		_noses[phase] = _mesh_node(_nose_carrier, phase.capitalize(), _nose_mesh(phase), material)
	_select_visible()


func set_pose(eye_phase: String, nose_phase: String, body_phase: String, camera: Camera3D) -> bool:
	# Explicit native phases only. Invalid input leaves the previous pose intact.
	if eye_phase not in PHASES or nose_phase not in PHASES or body_phase not in EXPRESSIONS:
		return false
	if not _actual_camera(camera):
		return false
	var camera_frame: Basis = global_basis.inverse() * camera.global_basis
	if not camera_frame.is_finite():
		return false
	_camera = camera
	_eye_phase = eye_phase
	_nose_phase = nose_phase
	_expression = body_phase
	# Only renderer children turn toward the actual fixed-angle camera.
	# No camera, parent, physics actor or source position is written here.
	_face_carrier.transform = Transform3D(camera_frame, Vector3.ZERO)
	_eye_carrier.transform = Transform3D(camera_frame, Vector3.ZERO)
	_nose_carrier.transform = Transform3D(camera_frame, NOSE_ANCHOR)
	_select_visible()
	return true


func pose_state() -> Dictionary:
	return {"eye_phase": _eye_phase, "nose_phase": _nose_phase, "expression": _expression}


static func local_bounds() -> Dictionary:
	# Reserves encompass every authored pose, including blank edge margins.
	# Nose bounds are in its own fixed attachment frame at NOSE_ANCHOR.
	return {"face": FACE_BOUNDS, "eye": EYE_BOUNDS, "nose": NOSE_BOUNDS, "nose_anchor": NOSE_ANCHOR, "pixel_step": PIXEL_STEP}


func part_points(camera: Camera3D) -> Dictionary:
	if not _actual_camera(camera) or camera != _camera:
		return {}
	return {
		"face": _box_points(FACE_BOUNDS, _face_carrier.global_transform),
		"eye": _box_points(EYE_BOUNDS, _eye_carrier.global_transform),
		"nose": _box_points(NOSE_BOUNDS, _nose_carrier.global_transform),
		"eye_floor_pivot": global_position,
		"nose_floor_pivot": to_global(NOSE_ANCHOR),
	}


func required_part_points(camera: Camera3D) -> Array[Vector3]:
	var parts: Dictionary = part_points(camera)
	if parts.is_empty():
		return [Vector3.INF]
	# The giant scenic face may crop. This is only the complete local art union;
	# the parent must separately include real source cues, footprints and landings.
	var points: Array[Vector3] = []
	points.append_array(parts.eye)
	points.append_array(parts.nose)
	points.append(parts.eye_floor_pivot)
	points.append(parts.nose_floor_pivot)
	return points


func world_corners(camera: Camera3D) -> Array[Vector3]:
	var parts: Dictionary = part_points(camera)
	if parts.is_empty():
		return [Vector3.INF]
	var points: Array[Vector3] = []
	points.append_array(parts.face)
	points.append_array(parts.eye)
	points.append_array(parts.nose)
	return points


func _actual_camera(camera: Camera3D) -> bool:
	return is_instance_valid(camera) and is_inside_tree() and camera.is_inside_tree() and not camera.is_queued_for_deletion() and camera.get_world_3d() == get_world_3d() and camera.get_viewport() == get_viewport() and get_viewport().get_camera_3d() == camera and camera.global_basis.is_finite()


func _carrier(label: String, anchor: Vector3) -> Node3D:
	var carrier := Node3D.new()
	carrier.name = label
	carrier.position = anchor
	carrier.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(carrier)
	return carrier


static func _mesh_node(carrier: Node3D, label: String, mesh: ArrayMesh, material: StandardMaterial3D) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.process_mode = Node.PROCESS_MODE_DISABLED
	carrier.add_child(node)
	return node


func _select_visible() -> void:
	for key: String in _faces:
		(_faces[key] as MeshInstance3D).visible = key == _expression
	for key: String in _eyes:
		(_eyes[key] as MeshInstance3D).visible = key == _expression + "/" + _eye_phase
	for key: String in _noses:
		(_noses[key] as MeshInstance3D).visible = key == _nose_phase


static func _face_mesh(expression: String) -> ArrayMesh:
	var v := PackedVector3Array()
	var c := PackedColorArray()
	# A hand-cut broad disc, with irregular edges and a cheek touching the floor.
	# The reachable left eye is a separate overlay; the upper right eye is scenery.
	_poly(v, c, [[-110,102],[-106,160],[-90,210],[-64,256],[-28,288],[20,308],[68,315],[116,310],[155,290],[184,256],[203,211],[206,160],[198,109],[174,65],[139,29],[91,8],[39,0],[-12,9],[-55,34],[-87,67]], COAL, -0.050)
	_poly(v, c, [[-106,102],[-101,159],[-84,207],[-59,251],[-24,284],[22,303],[68,310],[114,306],[151,285],[179,252],[198,209],[201,160],[194,111],[170,69],[136,33],[89,13],[38,5],[-10,14],[-52,39],[-82,70]], LIGHT, -0.046)
	_poly(v, c, [[-83,110],[-75,169],[-52,218],[-15,260],[31,284],[80,289],[119,271],[150,242],[162,197],[152,154],[116,128],[78,112],[42,82],[-1,67],[-41,76]], WHITE, -0.042)
	# Broad painted sweep and black cheek crease: no uniform speckle blanket.
	_poly(v, c, [[-94,132],[-91,173],[-72,216],[-49,242],[-58,211],[-69,176],[-70,142],[-60,107],[-75,91]], SILVER, -0.039)
	_poly(v, c, [[139,249],[171,229],[187,194],[191,157],[178,118],[159,92],[175,139],[169,185],[156,220]], SILVER, -0.039)
	_poly(v, c, [[90,77],[124,64],[147,42],[116,30],[71,23],[33,27],[12,37],[52,33],[89,37],[116,47]], MID, -0.037)
	_poly(v, c, [[124,84],[154,80],[175,100],[180,119],[171,108],[154,96],[127,95]], COAL, -0.035)
	_poly(v, c, [[-87,71],[-70,52],[-36,35],[-6,27],[12,31],[-13,38],[-45,48],[-70,67]], SILVER, -0.035)
	# Uneven porous craters: large grouped material marks, deliberately sparse.
	_crater(v, c, Vector2(-65,199), Vector2(15,22))
	_crater(v, c, Vector2(-39,245), Vector2(11,14))
	_crater(v, c, Vector2(7,281), Vector2(14,9))
	_crater(v, c, Vector2(68,275), Vector2(8,12))
	_crater(v, c, Vector2(119,284), Vector2(12,10))
	_crater(v, c, Vector2(168,219), Vector2(11,16))
	_crater(v, c, Vector2(186,145), Vector2(8,13))
	_crater(v, c, Vector2(160,51), Vector2(10,7))
	_crater(v, c, Vector2(37,26), Vector2(12,6))
	_crater(v, c, Vector2(-53,66), Vector2(8,12))
	_crater(v, c, Vector2(-90,137), Vector2(6,11))
	_crater(v, c, Vector2(103,232), Vector2(12,14))
	_crater(v, c, Vector2(8,154), Vector2(7,8))
	# Small clustered paint strokes vary in size and direction between craters.
	_poly(v, c, [[-45,175],[-40,183],[-32,185],[-30,181],[-36,176]], SILVER, -0.024)
	_poly(v, c, [[-5,238],[6,242],[11,247],[0,249],[-9,244]], SILVER, -0.024)
	_poly(v, c, [[39,258],[49,260],[53,265],[45,268],[36,263]], LIGHT, -0.024)
	_poly(v, c, [[87,300],[96,298],[102,304],[94,307]], SILVER, -0.024)
	_poly(v, c, [[144,178],[151,186],[157,187],[158,182],[153,176]], MID, -0.024)
	_poly(v, c, [[176,184],[178,193],[182,196],[185,190],[183,184]], LIGHT, -0.024)
	_poly(v, c, [[127,113],[135,111],[140,115],[133,120],[125,118]], SILVER, -0.024)
	_poly(v, c, [[84,47],[93,50],[97,56],[89,59],[80,53]], LIGHT, -0.024)
	_rect(v, c, -79, 98, 4, 6, MID, -0.024)
	_rect(v, c, -43, 119, 6, 3, SILVER, -0.024)
	_rect(v, c, 24, 205, 4, 5, SILVER, -0.024)
	_rect(v, c, 130, 265, 3, 5, MID, -0.024)
	# Scenic high eye and a strongly human eyebrow, without a bright target rim.
	var tense: bool = expression != "neutral"
	_poly(v, c, [[94,157],[101,177],[119,190],[141,190],[155,181],[166,162],[157,147],[143,138],[119,139],[105,146]], MID, -0.020)
	_poly(v, c, [[103,158],[113,170],[132,178],[151,173],[162,163],[151,155],[128,149],[111,152]], COAL, -0.017)
	if expression == "flinch":
		_ribbon(v, c, Vector2(103,163), Vector2(126,152), 5, INK, -0.014)
		_ribbon(v, c, Vector2(126,152), Vector2(158,163), 5, INK, -0.014)
	else:
		_poly(v, c, [[108,159],[120,167],[139,169],[151,163],[145,155],[129,152],[115,155]], LIGHT, -0.014)
		_poly(v, c, [[128,154],[136,154],[140,160],[138,167],[130,168],[125,162]], INK, -0.011)
		_rect(v, c, 130, 163, 3, 3, WHITE, -0.008)
	if tense:
		_poly(v, c, [[90,193],[109,199],[127,194],[153,211],[157,207],[132,186],[114,187],[95,185]], INK, -0.010)
	else:
		_poly(v, c, [[96,198],[113,207],[135,210],[154,201],[154,195],[135,202],[114,201],[99,193]], COAL, -0.010)
	# A compact theatrical mouth; no teeth, blood or monster mandible.
	if expression == "neutral":
		_poly(v, c, [[49,52],[68,43],[97,42],[119,51],[115,42],[94,34],[70,35],[52,44]], COAL, -0.015)
		_poly(v, c, [[65,40],[96,39],[105,43],[97,44],[72,44]], LIGHT, -0.012)
	elif expression == "indignant":
		_poly(v, c, [[51,43],[68,51],[91,55],[114,48],[122,39],[112,43],[91,49],[69,46]], INK, -0.015)
		_ribbon(v, c, Vector2(65,37), Vector2(99,35), 3, SILVER, -0.012)
	else:
		_poly(v, c, [[60,41],[69,54],[84,60],[101,56],[111,44],[100,40],[82,46],[69,40]], COAL, -0.015)
		_poly(v, c, [[73,51],[84,54],[97,51],[90,49],[82,50]], LIGHT, -0.012)
		_ribbon(v, c, Vector2(49,64), Vector2(40,73), 3, MID, -0.012)
		_ribbon(v, c, Vector2(119,60), Vector2(128,71), 3, MID, -0.012)
	return _finish(v, c)


static func _eye_mesh(phase: String, expression: String) -> ArrayMesh:
	var v := PackedVector3Array()
	var c := PackedColorArray()
	var closed: bool = phase in ["lock", "active"] or expression == "flinch"
	var recovery: bool = phase == "recovery" and expression != "flinch"
	var lid_top: int = 68 if recovery else (47 if phase == "warning" else 58)
	# Rounded low socket, with a curved fold above and separate lower contact lip.
	_poly(v, c, [[-54,31],[-49,59],[-37,77],[-19,87],[7,88],[30,78],[47,60],[54,35],[43,17],[24,6],[-8,2],[-31,8],[-47,18]], SILVER, 0.004)
	_poly(v, c, [[-48,34],[-40,62],[-20,78],[4,81],[26,72],[43,52],[48,34],[36,19],[18,10],[-7,7],[-29,15]], LIGHT, 0.008)
	_poly(v, c, [[-47,64],[-40,79],[-25,90],[1,94],[29,85],[46,70],[47,64],[24,77],[0,84],[-24,81]], MID, 0.012)
	if expression == "neutral":
		_poly(v, c, [[-48,88],[-32,96],[-10,99],[14,96],[34,88],[38,80],[16,88],[-9,91],[-31,90]], COAL, 0.016)
	else:
		_poly(v, c, [[-49,98],[-31,92],[-15,79],[1,78],[20,87],[41,99],[46,94],[23,79],[3,69],[-17,71],[-34,84]], INK, 0.016)
	if closed:
		_poly(v, c, [[-45,48],[-26,39],[-3,35],[21,39],[44,50],[41,57],[18,49],[-3,45],[-25,48],[-44,56]], LIGHT, 0.020)
		_poly(v, c, [[-46,39],[-25,29],[-2,25],[22,30],[47,41],[45,47],[22,36],[-2,31],[-25,35],[-44,45]], INK, 0.024)
		for index: int in 7:
			var x: int = -34 + index * 11
			var arc: float = float(absi(x)) / 5.0
			_ribbon(v, c, Vector2(x, 32.0 + arc), Vector2(x + 3, 22.0 + arc), 2, COAL, 0.027)
	else:
		_poly(v, c, [[-47,34],[-36,lid_top-4],[-15,lid_top+9],[9,lid_top+10],[31,lid_top],[46,36],[31,17],[9,10],[-16,13],[-34,21]], INK, 0.020)
		_poly(v, c, [[-40,34],[-32,lid_top-5],[-13,lid_top+3],[8,lid_top+3],[26,lid_top-3],[39,35],[25,22],[8,16],[-13,18],[-30,26]], WHITE if recovery else LIGHT, 0.024)
		# A round pupil placed above the same grounded lower rim in every open pose.
		_disc(v, c, Vector2(-7, 34), Vector2(12, 17), COAL, 0.028)
		_disc(v, c, Vector2(-7, 34), Vector2(8, 12), INK, 0.032)
		_rect(v, c, -12, 41, 4, 4, WHITE, 0.036)
		_poly(v, c, [[-47,36],[-38,lid_top+2],[-17,lid_top+14],[10,lid_top+14],[33,lid_top+3],[47,37],[43,43],[30,lid_top-1],[9,lid_top+8],[-14,lid_top+8],[-34,lid_top-3]], INK, 0.038)
	# Recovery's small bright lower lip visually reaches the genuine floor pivot.
	# This drawing never opens a damage gate; the parent supplies native phase.
	_poly(v, c, [[-40,18],[-25,7],[-7,3],[12,4],[30,10],[41,20],[38,25],[26,16],[10,11],[-7,10],[-24,14],[-36,23]], WHITE if recovery else MID, 0.040)
	if recovery:
		_poly(v, c, [[-25,7],[-8,3],[12,4],[28,11],[24,14],[10,10],[-7,9],[-22,12]], WHITE, 0.044)
		_rect(v, c, -9, 3, 19, 3, WHITE, 0.045)
	return _finish(v, c)


static func _nose_mesh(phase: String) -> ArrayMesh:
	var v := PackedVector3Array()
	var c := PackedColorArray()
	var raised: int = 10 if phase in ["warning", "lock"] else (6 if phase == "active" else 0)
	# Human bridge, cheek-side fold, round tip and two dark nostrils.
	# Raising is drawn within the fixed reserve; physical nose source never moves.
	_poly(v, c, [[-15,89],[-5,95],[6,87],[9,65],[14,48+raised],[25,30+raised],[34,20+raised],[33,10+raised],[23,5+raised],[8,8+raised],[-1,15+raised],[-10,10+raised],[-26,8+raised],[-34,15+raised],[-27,31+raised],[-17,53]], MID, 0.004)
	_poly(v, c, [[-11,85],[-4,91],[2,85],[5,63],[9,44+raised],[22,25+raised],[27,18+raised],[24,11+raised],[12,13+raised],[2,24+raised],[-9,18+raised],[-24,15+raised],[-27,22+raised],[-18,38+raised],[-13,58]], WHITE, 0.010)
	_poly(v, c, [[1,82],[6,68],[11,49+raised],[22,33+raised],[34,22+raised],[31,13+raised],[23,7+raised],[26,19+raised],[17,25+raised],[5,42+raised]], SILVER, 0.014)
	_poly(v, c, [[-29,24+raised],[-33,15+raised],[-23,8+raised],[-10,9+raised],[-3,16+raised],[-10,15+raised],[-18,17+raised],[-24,15+raised]], COAL, 0.018)
	_poly(v, c, [[10,14+raised],[17,7+raised],[28,8+raised],[34,15+raised],[29,21+raised],[24,15+raised],[17,14+raised]], INK, 0.018)
	_poly(v, c, [[-20,28+raised],[-12,34+raised],[-2,33+raised],[7,28+raised],[0,23+raised],[-11,23+raised]], LIGHT, 0.022)
	_ribbon(v, c, Vector2(-24, 45), Vector2(-32, 28), 3, SILVER, 0.024)
	_ribbon(v, c, Vector2(23, 47), Vector2(35, 31), 3, COAL, 0.024)
	if phase in ["warning", "lock"]:
		_poly(v, c, [[-25,67],[-15,71],[-6,69],[-12,65],[-22,64]], MID, 0.025)
		_poly(v, c, [[11,62],[21,64],[28,60],[21,59]], COAL, 0.025)
	elif phase == "active":
		# Restrained static breath accents, only while the real phase is active.
		# No cone, warning, collision, motion clock or independent effect lifetime.
		_rect(v, c, -22, 3, 4, 3, LIGHT, 0.030)
		_rect(v, c, -15, 0, 3, 3, WHITE, 0.030)
		_rect(v, c, 18, 2, 4, 4, LIGHT, 0.030)
		_rect(v, c, 26, 0, 3, 3, WHITE, 0.030)
	for index: int in v.size():
		v[index] += Vector3(0.0, 0.0, NOSE_RENDER_DEPTH)
	return _finish(v, c)


static func _crater(v: PackedVector3Array, c: PackedColorArray, center: Vector2, size: Vector2) -> void:
	_disc(v, c, center, size + Vector2(3, 3), LIGHT, -0.033)
	_disc(v, c, center + Vector2(1, 1), size, MID, -0.030)
	_poly(v, c, [center+Vector2(-size.x,0),center+Vector2(-size.x*0.5,size.y*0.75),center+Vector2(size.x*0.4,size.y),center+Vector2(size.x,size.y*0.2),center+Vector2(size.x*0.5,size.y*0.25),center+Vector2(-size.x*0.3,size.y*0.4)], SHADE, -0.027)
	_poly(v, c, [center+Vector2(-size.x*0.5,-size.y*0.6),center+Vector2(size.x*0.2,-size.y*0.8),center+Vector2(size.x*0.7,-size.y*0.35),center+Vector2(size.x*0.4,-size.y*0.1),center+Vector2(-size.x*0.3,-size.y*0.2)], SILVER, -0.024)


static func _disc(v: PackedVector3Array, c: PackedColorArray, center: Vector2, radius: Vector2, silver: float, z: float) -> void:
	var points: Array = []
	for index: int in 16:
		var angle: float = float(index) * TAU / 16.0
		points.append(center + Vector2(roundf(cos(angle) * radius.x), roundf(sin(angle) * radius.y)))
	_poly(v, c, points, silver, z)


static func _ribbon(v: PackedVector3Array, c: PackedColorArray, a: Vector2, b: Vector2, width: float, silver: float, z: float) -> void:
	var side: Vector2 = Vector2(-(b-a).y, (b-a).x).normalized() * width * 0.5
	_poly(v, c, [a-side, b-side, b+side, a+side], silver, z)


static func _rect(v: PackedVector3Array, c: PackedColorArray, x: float, y: float, width: float, height: float, silver: float, z: float) -> void:
	_poly(v, c, [[x,y],[x+width,y],[x+width,y+height],[x,y+height]], silver, z)


static func _poly(v: PackedVector3Array, c: PackedColorArray, points: Array, silver: float, z: float) -> void:
	var polygon := PackedVector2Array()
	for raw: Variant in points:
		var point: Vector2 = raw if raw is Vector2 else Vector2(float(raw[0]), float(raw[1]))
		# Authored polygons and decorative ribbons share deliberate texel steps.
		polygon.append(Vector2(roundf(point.x), roundf(point.y)))
	for index: int in Geometry2D.triangulate_polygon(polygon):
		var point: Vector2 = polygon[index]
		v.append(Vector3(point.x * PIXEL_STEP, point.y * PIXEL_STEP, z))
		c.append(Color(silver, silver, silver, 1.0))


static func _finish(vertices: PackedVector3Array, colors: PackedColorArray) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _box_points(bounds: AABB, frame: Transform3D) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]:
				points.append(frame * Vector3(x, y, z))
	return points
