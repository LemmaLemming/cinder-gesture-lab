extends Node3D
## SOURCE-ONLY full authored scenery candidate; native/portrait checks pending.
## Permanent floor mesh belongs to actual parent floor body; all other scenery
## is opaque/nonphysical. G09/G11/G15/G20; no concept painting loaded at runtime.
const Landscape = preload("res://scripts/acts/act3/crystalman_landscape_scenery.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Kit = preload("res://scripts/acts/act3/twin_suns_scenery.gd")
const MINERAL_SHADER_CODE: String = """
shader_type spatial;
render_mode unshaded, depth_draw_opaque, cull_back;
uniform vec4 mineral_a : source_color;
uniform vec4 mineral_b : source_color;
uniform vec4 side_color : source_color;
uniform vec2 pitch_world;
varying vec2 world_xz;
varying float top_face;
float mineral_hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}
void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	top_face = step(0.5, NORMAL.y);
}
void fragment() {
	float row = floor(world_xz.y / pitch_world.y);
	vec2 tile = floor(vec2(world_xz.x / pitch_world.x + mod(row, 2.0) * 0.36,
		world_xz.y / pitch_world.y));
	float broad = floor(mineral_hash(tile) * 4.0) / 3.0;
	vec3 stone = mix(mineral_a.rgb, mineral_b.rgb, 0.15 + broad * 0.65);
	float coarse = floor(mineral_hash(floor(world_xz * 18.0)) * 3.0) / 2.0;
	stone *= 0.97 + coarse * 0.03;
	ALBEDO = mix(side_color.rgb, stone, top_face);
}
"""
var landscape: Node3D
var floor_visual: MeshInstance3D
var _floor_body: StaticBody3D
var _floor_mesh: BoxMesh
var _floor_material: ShaderMaterial
var _kit: Node3D
var _shore: Array[Dictionary] = []
var _stage: int = 0
var _built: bool = false
var _floor_shader: Shader

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_process(false)
	set_physics_process(false)

func build(body: StaticBody3D) -> bool:
	if _built or not is_instance_valid(body) or body.get_parent() != get_parent() or body.global_transform != Transform3D(Basis.IDENTITY,Vector3(0,-0.5,13)): return false
	_floor_body = body
	floor_visual = MeshInstance3D.new()
	floor_visual.name = "OpaqueSteppedPermanentMineralFloor"
	_floor_mesh = BoxMesh.new()
	_floor_mesh.size = Vector3(12,1,54)
	floor_visual.mesh = _floor_mesh
	_floor_shader = Shader.new()
	_floor_shader.code = MINERAL_SHADER_CODE
	_floor_material = ShaderMaterial.new()
	_floor_material.shader = _floor_shader
	_floor_material.set_shader_parameter("mineral_a",Color("25262f"))
	_floor_material.set_shader_parameter("mineral_b",Color("3a343e"))
	_floor_material.set_shader_parameter("side_color",Color("211f28"))
	_floor_material.set_shader_parameter("pitch_world",Vector2(1.60,2.35))
	floor_visual.material_override = _floor_material
	floor_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(floor_visual)
	landscape = Landscape.new()
	landscape.name = "CalmLandscapeBodyAndCrystalVeils"
	add_child(landscape)
	if not landscape.call("build"): return false
	_kit = Kit.new()
	_kit.name = "ShoreGeometryHelpersOnly"
	add_child(_kit) # Never calls Kit.build(), so no extra floor/wall/controller.
	for side: float in [-1.0,1.0]:
		for z: float in [33.0,29.0,24.0,19.0,14.0]:
			var before: int = _kit.get_child_count()
			_kit.call("_rock_spine",Vector3(side*6.7,0,z),0.7,side,_kit)
			_retain(_kit.get_child(before) as MeshInstance3D)
			var contour := PackedVector2Array([Vector2(-0.8,-1.0),Vector2(0.5,-0.8),Vector2(0.8,0.55),Vector2(-0.45,1.1)])
			var scarlet: MeshInstance3D = _kit.call("_floor_polygon",contour,Vector3(side*4.9,0.008,z),Color("523742"))
			_retain(scarlet)
		var sea: MeshInstance3D = _kit.call("_box",Vector3(3.0,0.018,24.0),Vector3(side*8.0,-0.15,25.0),Color("30343d"))
		_retain(sea)
	_built = true
	return runtime_error().is_empty()

func _retain(part: MeshInstance3D) -> void:
	if part == null: return
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shore.append({"node":part,"mesh":part.mesh,"material":part.material_override,"transform":part.transform,"arrays":var_to_bytes(part.mesh.surface_get_arrays(0)) if part.mesh.get_surface_count()>0 else PackedByteArray()})

func present_stage(stage: int,quiet: bool = false) -> bool:
	if not _built or stage not in [0,1,2,3,4] or (not quiet and stage < _stage): return false
	var strip: int = 0 if stage <= 2 else (1 if stage == 3 else 2)
	var ok: bool = landscape.call("restore_parent_state",strip,stage==4) if quiet else landscape.call("present_parent_state",strip,stage==4)
	if ok: _stage = stage
	return ok and runtime_error().is_empty()

func presentation_state() -> Dictionary:
	return {"api_revision":"act3-crystalman-scenery-1","stage":_stage,"landscape":landscape.call("state") if is_instance_valid(landscape) else {}}

func presentation_error(state: Dictionary,stage: int) -> String:
	var strip: int = 0 if stage<=2 else (1 if stage==3 else 2)
	var expected: Dictionary = {"api_revision":"act3-crystalman-scenery-1","stage":stage,"landscape":{"strip_stage":strip,"coda_displayed":stage==4,"optional_scenery":true}}
	return "" if Exact.stringify(state)==Exact.stringify(expected) else "Scenery must derive from exact current stage"

func restore_presentation(state: Dictionary,stage: int) -> bool:
	return presentation_error(state,stage).is_empty() and get_tree().paused and present_stage(stage,true)

func runtime_error() -> String:
	if not _built or not is_instance_valid(_floor_body) or not is_instance_valid(floor_visual) or floor_visual.get_parent()!=_floor_body or floor_visual.transform!=Transform3D.IDENTITY or floor_visual.mesh!=_floor_mesh or _floor_mesh.size!=Vector3(12,1,54) or floor_visual.material_override!=_floor_material or _floor_material.shader!=_floor_shader or _floor_shader.code!=MINERAL_SHADER_CODE or not floor_visual.visible: return "Actual retained immutable readable mineral floor art required"
	if _floor_material.get_shader_parameter("mineral_a")!=Color("25262f") or _floor_material.get_shader_parameter("mineral_b")!=Color("3a343e") or _floor_material.get_shader_parameter("side_color")!=Color("211f28") or _floor_material.get_shader_parameter("pitch_world")!=Vector2(1.60,2.35): return "Original coarse mineral material fields required"
	if not is_instance_valid(landscape) or not String(landscape.call("runtime_error")).is_empty(): return "Actual original calm landscape/crystal strip kit required"
	for row: Dictionary in _shore:
		if not is_instance_valid(row.node) or row.node.get_parent()!=_kit or row.node.mesh!=row.mesh or row.node.material_override!=row.material or row.node.transform!=row.transform or not row.node.visible: return "Actual retained nonphysical scarlet-black shore pieces required"
		if row.mesh.get_surface_count()>0 and var_to_bytes(row.mesh.surface_get_arrays(0))!=row.arrays: return "Original shore native mesh arrays required"
	return ""
