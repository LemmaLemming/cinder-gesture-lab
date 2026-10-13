extends SceneTree
## TEST ONLY cosmetic reconstruction of the measured paired counter pose.
## No actor, scheduler, damage, route or fullfight acceptance is fabricated.

const Visual: Script = preload("res://scripts/acts/act2/ray_scout_visual.gd")
const SOURCE := Vector3(0.65, 0.0, -25.5)
const HERO := Vector3(0.3976888954639435, -0.004843761678785086, -25.58775520324707)
const ENTRY_HERO := Vector3(0.3976897895336151, 0.0, -21.769372940063477)
const CASE_PATH: String = "ThreeLegChassis/RivetedCameraCase/CameraCase"
const HOUSING_PATH: String = "ThreeLegChassis/FixedLowMirrorHousing/HousingBlock"
const MIRROR_PATH: String = "ThreeLegChassis/TrackingMirrorSwivel/FoldingMirrorHinge/SegmentedParabolicMirror/PolishedMirrorFacets"
var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 7.2
	world.add_child(camera)
	camera.global_position = HERO + Vector3.UP * 0.75 + Vector3(0, 18, 13)
	camera.look_at(HERO + Vector3.UP * 0.75)
	var rig: Node3D = Visual.new() as Node3D
	rig.position = SOURCE
	world.add_child(rig)
	var other: Node3D = Visual.new() as Node3D
	other.position = SOURCE
	world.add_child(other)
	var direction: Vector3 = (ENTRY_HERO - SOURCE).normalized()
	rig.call("pose", "warning", 0.0, direction)
	rig.call("pose", "recovery", 0.25, direction)
	other.call("pose", "warning", 0.0, direction)
	other.call("pose", "recovery", 0.25, direction)
	var nodes: Array[MeshInstance3D] = []
	_collect_meshes(rig, nodes)
	var transforms: Dictionary = _transforms(nodes)
	var material_ids: Dictionary = _material_ids(nodes)
	var owned_ids: Dictionary = _owned_copy_ids(rig)
	var other_owned_ids: Dictionary = _owned_copy_ids(other)
	_expect(owned_ids.size() == 32 and other_owned_ids.size() == 32 and _copy_ids_disjoint(owned_ids, other_owned_ids), "29 eligible meshes bind exactly 32 distinct per-Scout copies, including four independently owned facet surface overrides")
	var case_material: StandardMaterial3D = (rig.get_node(CASE_PATH) as MeshInstance3D).material_override as StandardMaterial3D
	var housing_material: StandardMaterial3D = (rig.get_node(HOUSING_PATH) as MeshInstance3D).material_override as StandardMaterial3D
	var other_material: StandardMaterial3D = (other.get_node(CASE_PATH) as MeshInstance3D).material_override as StandardMaterial3D
	var mirror: MeshInstance3D = rig.get_node(MIRROR_PATH) as MeshInstance3D
	var other_mirror: MeshInstance3D = other.get_node(MIRROR_PATH) as MeshInstance3D
	var palette: Array[Dictionary] = _mirror_palette(mirror)
	var points: Array[Vector3] = _hero_points(camera, HERO)
	_expect(bool(rig.call("apply_readability", camera, points)), "measured counter pose accepts actual camera-facing unordered nine-point bounds")
	var state: Dictionary = rig.call("readability_state")
	_expect(state.panel_count == 29 and state.context_available and state.faded_panels.has(CASE_PATH) and state.faded_panels.has(HOUSING_PATH) and state.faded_panels.has(MIRROR_PATH), "29 eligible meshes include the measured case, housing and polished mirror foreground occlusion")
	_expect(_near(case_material.albedo_color.a, 0.14) and case_material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and _near(housing_material.albedo_color.a, 0.14) and _residual_cutaway_materials(nodes, 1.0, 0.14), "measured foreground panels and front bracket fade; coupler/ribs below the actual foot edge stay opaque")
	_expect(_foreground_details(nodes, 0.14), "measured hood rim, all five cooling ribs, actuator, all six actuator ribs and all mirror facets receive supported cutaway opacity")
	_expect(_mirror_palette_preserved(mirror, palette, 0.14) and _mirror_isolated(mirror, other_mirror), "four independently owned facet materials preserve original palette RGB and textures while leaving mesh sources and the other Scout opaque")
	_expect(_protected_opaque(nodes), "all three supports, mirror rim/clips/fork/pins/hub/aperture and corner brackets/rivets retain opaque source outlines")
	if OS.get_cmdline_user_args().has("--occlusion-diagnostic"):
		_print_occlusion_diagnostic(rig, camera, points, nodes)
	_expect(_near(other_material.albedo_color.a, 1.0) and other_material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and (other.call("readability_state") as Dictionary).faded_panels.is_empty(), "one rig's derived fading cannot alter an independent Scout")
	_expect(_transforms(nodes) == transforms and rig.global_position == SOURCE and not rig.is_processing() and not rig.is_physics_processing(), "readability changes no mesh/root transform and introduces no autonomous processing")
	state.faded_panels.clear()
	_expect(not (rig.call("readability_state") as Dictionary).faded_panels.is_empty(), "readability diagnostic arrays are defensive")
	var before_invalid: Dictionary = rig.call("readability_state")
	var invalid: Array[Vector3] = points.duplicate()
	invalid[0] = Vector3(NAN, 0, 0)
	_expect(not bool(rig.call("apply_readability", camera, invalid)) and rig.call("readability_state") == before_invalid and _near(case_material.albedo_color.a, 0.14), "invalid bounds reject before changing the derived material state")
	var empty: Array[Vector3] = []
	_expect(not bool(rig.call("apply_readability", camera, empty)), "missing silhouette cannot claim valid readability")
	for phase: String in ["warning", "lock", "active", "recovery", "defeated"]:
		rig.call("pose", phase, 0.25, direction, true)
		_expect(case_material.emission_enabled and _mirror_flash(mirror, true) and bool(rig.call("apply_readability", camera, points)) and _protected_opaque(nodes), "parent %s posing keeps protected art and every facet receives panel hit-flash updates" % phase)
		var yaw: float = float(rig.call("get_body_yaw"))
		_expect(bool(rig.call("restore_pose", phase, 0.25, direction, yaw, false)) and not case_material.emission_enabled and _mirror_flash(mirror, false) and _material_ids(nodes) == material_ids and _owned_copy_ids(rig) == owned_ids, "restored %s recomputes derived fading without growing instance or surface material copies" % phase)
	rig.call("pose", "warning", 0.0, direction)
	rig.call("pose", "recovery", 0.25, direction)
	for repetition: int in range(4):
		rig.call("clear_readability")
		_expect(_near(case_material.albedo_color.a, 1.0) and case_material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and _near(housing_material.albedo_color.a, 1.0) and _residual_cutaway_materials(nodes, 1.0, 1.0), "explicit clear restores all panels and residual occluders to original opacity/depth mode")
		_expect(_foreground_details(nodes, 1.0) and _mirror_palette_preserved(mirror, palette, 1.0), "clear restores all newly eligible leaves and each original facet palette/texture without replacing materials")
		_expect(bool(rig.call("apply_readability", camera, points)) and _material_ids(nodes) == material_ids and _owned_copy_ids(rig) == owned_ids and _foreground_details(nodes, 0.14) and _mirror_palette_preserved(mirror, palette, 0.14), "repeated application reuses exactly the owned instance and surface copies")
	var foreground: Array[Vector3] = []
	for point: Vector3 in points:
		foreground.append(point + camera.global_basis.z * 10.0)
	_expect(bool(rig.call("apply_readability", camera, foreground)) and (rig.call("readability_state") as Dictionary).faded_panels.is_empty(), "projected overlap behind the hero does not fade the machine")
	var disjoint: Array[Vector3] = []
	for point: Vector3 in points:
		disjoint.append(point + camera.global_basis.x * 20.0)
	_expect(bool(rig.call("apply_readability", camera, disjoint)) and (rig.call("readability_state") as Dictionary).faded_panels.is_empty(), "screen-disjoint bounds restore every panel's opacity")
	# Nearby TEST ONLY quad: the same feet-pivot billboard .3 toward the camera
	# puts all coupler leaves above its foot edge. The native measured counter's
	# coupler sits just below that edge, so eligibility alone must not fade it.
	var coupler_points: Array[Vector3] = _hero_points(camera, HERO + Vector3.BACK * 0.3)
	var coupler_faded: bool = bool(rig.call("apply_readability", camera, coupler_points)) and _residual_cutaway_materials(nodes, 0.14, 0.14)
	var measured_restored: bool = bool(rig.call("apply_readability", camera, points)) and _residual_cutaway_materials(nodes, 1.0, 0.14)
	_expect(coupler_faded and measured_restored, "coupler and all four ribs fade on actual overlap, then measured bounds restore their non-overlap opacity")
	var fresh: Node3D = Visual.new() as Node3D
	fresh.position = SOURCE
	world.add_child(fresh)
	var fresh_nodes: Array[MeshInstance3D] = []
	_collect_meshes(fresh, fresh_nodes)
	var fresh_material_ids: Dictionary = _material_ids(fresh_nodes)
	var fresh_owned_ids: Dictionary = _owned_copy_ids(fresh)
	_expect(bool(fresh.call("restore_pose", "recovery", 0.25, direction, float(rig.call("get_body_yaw")))) and bool(fresh.call("apply_readability", camera, points)) and (fresh.call("readability_state") as Dictionary).panel_count == 29 and _surface_states(fresh_nodes) == _surface_states(nodes) and _material_ids(fresh_nodes) == fresh_material_ids and fresh_owned_ids.size() == 32 and _owned_copy_ids(fresh) == fresh_owned_ids and _copy_ids_disjoint(owned_ids, fresh_owned_ids), "fresh restored pose derives the same 29-mesh cutaway and stable surface copies without relying on generated sibling names or serialized fade state")
	camera.free()
	rig.call("pose", "recovery", 0.25, direction)
	_expect(not (rig.call("readability_state") as Dictionary).context_available and (rig.call("readability_state") as Dictionary).faded_panels.is_empty() and _near(case_material.albedo_color.a, 1.0) and _foreground_details(nodes, 1.0) and _mirror_palette_preserved(mirror, palette, 1.0), "freed camera expires weak context and clears all stale instance and surface fading safely")
	world.free()
	_expect(not is_instance_valid(rig) and not is_instance_valid(other) and not is_instance_valid(fresh), "fixture cleanup frees all owned rig and panel instances")
	print("Horsell Scout readability smoke: %d checks, %d failures; isolated measured cosmetic reconstruction, native fullfight review separate" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _print_occlusion_diagnostic(rig: Node3D, camera: Camera3D, points: Array[Vector3], nodes: Array[MeshInstance3D]) -> void:
	# TEST ONLY read-only probe of actual mesh surfaces at the measured pose.
	# Reuse the exact production projection/triangle predicate; material mode,
	# mesh transforms, poses and all assertions remain unchanged.
	var hero_hull: PackedVector2Array = rig.call("_projected_hull", camera, points)
	var hero_depth: float = -INF
	for point: Vector3 in points:
		hero_depth = maxf(hero_depth, -camera.to_local(point).z)
	var opaque_meshes: int = 0
	var occluders: Array[Dictionary] = []
	for node: MeshInstance3D in nodes:
		if node.mesh == null or not node.is_visible_in_tree():
			continue
		var vertices := PackedVector3Array()
		var indices := PackedInt32Array()
		var alphas: Array[float] = []
		var surfaces: Array[int] = []
		for surface: int in range(node.mesh.get_surface_count()):
			var material: Material = _effective_material(node, surface)
			if not _opaque_material(material):
				continue
			if node.mesh is ArrayMesh and (node.mesh as ArrayMesh).surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
				continue
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var surface_vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var surface_indices := PackedInt32Array()
			if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array:
				surface_indices = arrays[Mesh.ARRAY_INDEX]
			# The authored polished mirror has unindexed triangle surfaces.
			if surface_indices.is_empty():
				if surface_vertices.size() % 3 != 0:
					continue
				for index: int in range(surface_vertices.size()):
					surface_indices.append(index)
			var vertex_offset: int = vertices.size()
			vertices.append_array(surface_vertices)
			for index: int in surface_indices:
				indices.append(vertex_offset + index)
			alphas.append((material as StandardMaterial3D).albedo_color.a)
			surfaces.append(surface)
		if vertices.is_empty():
			continue
		opaque_meshes += 1
		var panel: Dictionary = {"part": node, "vertices": vertices, "indices": indices}
		if bool(rig.call("_panel_occludes", camera, panel, hero_hull, hero_depth)):
			occluders.append({"path": String(rig.get_path_to(node)), "surface_alphas": alphas, "opaque_surfaces": surfaces, "local_position": str(node.position), "mesh_type": node.mesh.get_class()})
	print("Scout opaque foreground diagnostic: ", JSON.stringify({"scope": "TEST ONLY measured B recovery cosmetic reconstruction; same production projected triangle predicate", "opaque_meshes_examined": opaque_meshes, "hero_depth": hero_depth, "occluders": occluders}, "", false, true))


func _hero_points(camera: Camera3D, feet: Vector3) -> Array[Vector3]:
	var points: Array[Vector3] = []
	# Same public48x64/pixel_size/feet-offset billboard as the shared actor;
	# natural point ordering deliberately differs from a perimeter polygon.
	for y: float in [0.0, 0.72, 1.44]:
		for x: float in [-0.54, 0.0, 0.54]:
			points.append(feet + Vector3.UP * 0.025 + camera.global_basis.x * x + camera.global_basis.y * y)
	return points


func _collect_meshes(node: Node, nodes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		nodes.append(node as MeshInstance3D)
	for child: Node in node.get_children():
		_collect_meshes(child, nodes)


func _transforms(nodes: Array[MeshInstance3D]) -> Dictionary:
	var result: Dictionary = {}
	for node: MeshInstance3D in nodes:
		result[node.get_instance_id()] = node.global_transform
	return result


func _material_ids(nodes: Array[MeshInstance3D]) -> Dictionary:
	var result: Dictionary = {}
	for node: MeshInstance3D in nodes:
		var surfaces: Array[int] = []
		for surface: int in range(node.mesh.get_surface_count()):
			var material: Material = _effective_material(node, surface)
			surfaces.append(material.get_instance_id() if material != null else 0)
		result[node.get_instance_id()] = {"override": node.material_override.get_instance_id() if node.material_override != null else 0, "surfaces": surfaces}
	return result


func _effective_material(node: MeshInstance3D, surface: int) -> Material:
	if node.material_override != null:
		return node.material_override
	var material: Material = node.get_surface_override_material(surface)
	return material if material != null else node.mesh.surface_get_material(surface)


func _owned_copy_ids(rig: Node3D) -> Dictionary:
	# TEST ONLY ownership probe; do not mutate the production records.
	var panels: Array = rig.get("_readability_panels")
	if panels.size() != 29:
		return {}
	var result: Dictionary = {}
	for panel: Dictionary in panels:
		var part: MeshInstance3D = panel["part"] as MeshInstance3D
		var entries: Array = panel["materials"]
		if entries.size() != (1 if part.material_override != null else part.mesh.get_surface_count()):
			return {}
		for index: int in range(entries.size()):
			var material: Material = entries[index]["material"] as Material
			if material == null or material != _effective_material(part, index) or result.has(material.get_instance_id()):
				return {}
			result[material.get_instance_id()] = true
	return result


func _copy_ids_disjoint(first: Dictionary, second: Dictionary) -> bool:
	for material_id: int in first:
		if second.has(material_id):
			return false
	return true


func _surface_states(nodes: Array[MeshInstance3D]) -> Array[Dictionary]:
	# Authored child order is stable; duplicate sibling names need not be.
	var result: Array[Dictionary] = []
	for node: MeshInstance3D in nodes:
		var surfaces: Array[Dictionary] = []
		for surface: int in range(node.mesh.get_surface_count()):
			var material: StandardMaterial3D = _effective_material(node, surface) as StandardMaterial3D
			surfaces.append({"color": material.albedo_color, "mode": material.transparency, "flash": material.emission_enabled} if material != null else {})
		result.append({"transform": node.global_transform, "visible": node.visible, "mesh": node.mesh.get_class(), "surfaces": surfaces})
	return result


func _mirror_palette(mirror: MeshInstance3D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for surface: int in range(mirror.mesh.get_surface_count()):
		var material: StandardMaterial3D = mirror.mesh.surface_get_material(surface) as StandardMaterial3D
		if material == null:
			return []
		result.append({"id": material.get_instance_id(), "color": material.albedo_color, "texture": material.albedo_texture.get_instance_id() if material.albedo_texture != null else 0})
	return result


func _mirror_palette_preserved(mirror: MeshInstance3D, palette: Array[Dictionary], alpha: float) -> bool:
	if palette.size() != 4 or mirror.mesh.get_surface_count() != 4 or mirror.material_override != null:
		return false
	for surface: int in range(4):
		var source: StandardMaterial3D = mirror.mesh.surface_get_material(surface) as StandardMaterial3D
		var owned: StandardMaterial3D = mirror.get_surface_override_material(surface) as StandardMaterial3D
		var record: Dictionary = palette[surface]
		if source == null or owned == null or source.get_instance_id() != int(record.id) or owned == source or not _opaque_material(source) or source.albedo_color != record.color:
			return false
		var texture_id: int = source.albedo_texture.get_instance_id() if source.albedo_texture != null else 0
		var owned_texture_id: int = owned.albedo_texture.get_instance_id() if owned.albedo_texture != null else 0
		var expected: Color = record.color
		expected.a = alpha
		var mode: int = BaseMaterial3D.TRANSPARENCY_ALPHA if alpha < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
		if not owned.albedo_color.is_equal_approx(expected) or owned.transparency != mode or texture_id != int(record.texture) or owned_texture_id != texture_id:
			return false
	return true


func _mirror_isolated(mirror: MeshInstance3D, other: MeshInstance3D) -> bool:
	if mirror.mesh.get_surface_count() != 4 or other.mesh.get_surface_count() != 4:
		return false
	var sources: Dictionary = {}
	for node: MeshInstance3D in [mirror, other]:
		for surface: int in range(4):
			var material: Material = node.mesh.surface_get_material(surface)
			if material == null:
				return false
			sources[material.get_instance_id()] = true
	var seen: Dictionary = {}
	for surface: int in range(4):
		var own: Material = mirror.get_surface_override_material(surface)
		var other_own: Material = other.get_surface_override_material(surface)
		var source: Material = mirror.mesh.surface_get_material(surface)
		var other_source: Material = other.mesh.surface_get_material(surface)
		if own == null or other_own == null or own == source or other_own == other_source or not _opaque_material(other_own) or not _opaque_material(source) or not _opaque_material(other_source):
			return false
		for material: Material in [own, other_own]:
			if seen.has(material.get_instance_id()) or sources.has(material.get_instance_id()):
				return false
			seen[material.get_instance_id()] = true
	return seen.size() == 8


func _mirror_flash(mirror: MeshInstance3D, enabled: bool) -> bool:
	if mirror.mesh.get_surface_count() != 4:
		return false
	for surface: int in range(4):
		var material: StandardMaterial3D = _effective_material(mirror, surface) as StandardMaterial3D
		if material == null or material.emission_enabled != enabled or (enabled and material.emission != Color(0.62, 0.52, 0.39)):
			return false
	return true


func _foreground_details(nodes: Array[MeshInstance3D], alpha: float) -> bool:
	var counts: Dictionary = {"hood": 0, "cooling": 0, "actuator": 0, "ribs": 0, "facets": 0}
	for node: MeshInstance3D in nodes:
		var part_name: String = String(node.name)
		var parent_name: String = String(node.get_parent().name)
		var kind: String = ""
		if part_name == "HoodRim":
			kind = "hood"
		elif part_name == "FlexibleHousingActuator":
			kind = "actuator"
		elif part_name == "PolishedMirrorFacets":
			kind = "facets"
		elif parent_name == "RivetedCameraCase" and node.mesh is BoxMesh and (node.mesh as BoxMesh).size.is_equal_approx(Vector3(0.045, 0.26, 0.08)):
			kind = "cooling"
		elif parent_name == "ThreeLegChassis" and node.mesh is CylinderMesh:
			var cylinder: CylinderMesh = node.mesh as CylinderMesh
			if _near(cylinder.height, 0.025) and _near(cylinder.bottom_radius, 0.086) and _near(cylinder.top_radius, 0.086):
				kind = "ribs"
		if kind.is_empty():
			continue
		counts[kind] = int(counts[kind]) + 1
		for surface: int in range(node.mesh.get_surface_count()):
			var material: StandardMaterial3D = _effective_material(node, surface) as StandardMaterial3D
			var mode: int = BaseMaterial3D.TRANSPARENCY_ALPHA if alpha < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
			if material == null or not _near(material.albedo_color.a, alpha) or material.transparency != mode:
				return false
	return counts == {"hood": 1, "cooling": 5, "actuator": 1, "ribs": 6, "facets": 1}


func _residual_cutaway_materials(nodes: Array[MeshInstance3D], coupler_alpha: float, bracket_alpha: float) -> bool:
	var count: int = 0
	for node: MeshInstance3D in nodes:
		var part_name: String = String(node.name)
		var parent_name: String = String(node.get_parent().name)
		# Repeated sibling names may be generated by Godot. Identify every rib
		# by its actual immediate housing parent and authored BoxMesh dimensions.
		var rib: bool = parent_name == "FixedLowMirrorHousing" and node.mesh is BoxMesh and (node.mesh as BoxMesh).size.is_equal_approx(Vector3(0.037, 0.15, 0.055))
		if not (part_name == "LowCouplerInterior" or part_name == "FrontBracket" or rib):
			continue
		count += 1
		var alpha: float = bracket_alpha if part_name == "FrontBracket" else coupler_alpha
		var mode: int = BaseMaterial3D.TRANSPARENCY_ALPHA if alpha < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
		var material: StandardMaterial3D = node.material_override as StandardMaterial3D
		if material == null or not _near(material.albedo_color.a, alpha) or material.transparency != mode:
			return false
	return count == 6


func _protected_opaque(nodes: Array[MeshInstance3D]) -> bool:
	var supports: Dictionary = {}
	var mirror_count: int = 0
	var corner_brackets: int = 0
	var corner_rivets: int = 0
	for node: MeshInstance3D in nodes:
		var path: String = String(node.get_path())
		var part_name: String = String(node.name)
		var parent_name: String = String(node.get_parent().name)
		var support: bool = false
		for family: String in ["LeftSupport", "RightSupport", "RearSupport"]:
			if path.contains("/%s/" % family):
				supports[family] = true
				support = true
		var mirror: bool = path.contains("TrackingMirrorSwivel/") and part_name != "PolishedMirrorFacets"
		if mirror:
			mirror_count += 1
		# Check each corner leaf, including generated duplicate names. Matching
		# the RivetedCameraCase ancestor would misclassify intentional cutaways.
		var corner: bool = false
		if parent_name == "RivetedCameraCase" and node.mesh is BoxMesh:
			var size: Vector3 = (node.mesh as BoxMesh).size
			if size.is_equal_approx(Vector3(0.055, 0.44, 0.065)):
				corner_brackets += 1
				corner = true
			elif size.is_equal_approx(Vector3(0.043, 0.043, 0.030)):
				corner_rivets += 1
				corner = true
		if not (support or mirror or corner or part_name.contains("Rivet")):
			continue
		for surface: int in range(node.mesh.get_surface_count()):
			if not _opaque_material(_effective_material(node, surface)):
				return false
	return supports.size() == 3 and mirror_count > 0 and corner_brackets == 2 and corner_rivets == 6


func _opaque_material(value: Material) -> bool:
	var material: StandardMaterial3D = value as StandardMaterial3D
	return material != null and _near(material.albedo_color.a, 1.0) and material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED


func _near(a: float, b: float) -> bool:
	return absf(a - b) < 0.00001


func _expect(condition: bool, message: String) -> bool:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
	return condition
