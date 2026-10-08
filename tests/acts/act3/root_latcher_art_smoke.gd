extends SceneTree
## Native art-leaf test only. This camera adapter is not CampaignShell and its
## geometry results establish neither camera admission nor combat permission.
## Root runs through dev.py. Optional --render-poses needs a graphical job and
## saves only genuine, unchanged transparent SubViewport images.

const Art = preload("res://scripts/acts/act3/root_latcher_art.gd")
const AtlasPath: String = "res://assets/acts/act3/root-latcher-atlas.png"
const ArtPath: String = "res://scripts/acts/act3/root_latcher_art.gd"
const AtlasHash: String = "05bac37c0e5d03a0238651179e32106bd562ff5999bde36dcb83d3207a0bf810"
const CaptureDirectory: String = "res://captures/act3/root-latcher-art/native-atlas"
const PoseKeys: Array[String] = ["closed", "raised", "exposed", "spent"]
const Regions: Array[Rect2] = [Rect2(0, 0, 627, 627), Rect2(627, 0, 627, 627), Rect2(0, 627, 627, 627), Rect2(627, 627, 627, 627)]
const Pivots: Array[Vector2] = [Vector2(333, 584), Vector2(310, 584), Vector2(338, 501), Vector2(310, 504)]
const OpaqueBounds: Array[Rect2i] = [Rect2i(82, 262, 510, 322), Rect2i(57, 163, 487, 421), Rect2i(82, 198, 524, 303), Rect2i(59, 207, 492, 297)]
const SpriteProperties: Array[String] = ["transform", "visible", "texture", "offset", "pixel_size", "billboard", "axis", "fixed_size", "region_enabled", "region_rect", "hframes", "vframes", "frame", "flip_h", "flip_v", "centered", "material_override", "material_overlay", "no_depth_test", "shaded", "transparent", "double_sided", "alpha_cut", "alpha_scissor_threshold", "texture_filter", "modulate"]
const WorldEpsilon: float = 0.00001
const ScreenEpsilon: float = 0.001

class NativeCameraAdapter:
	extends Node
	var camera: Camera3D
	var planner_calls: int = 0
	func camera_framing_plan(_points: Array, _focus: Vector3) -> Dictionary:
		planner_calls += 1
		return {"accepted": false, "reason": "Test-only native art adapter supplies no admission"}

var _checks: int = 0
var _failures: int = 0
var _render: bool = false
var _viewport: SubViewport
var _world: Node3D
var _parent: Node3D
var _camera: Camera3D
var _shell: NativeCameraAdapter
var _art: Node3D
var _sprites: Array[Sprite3D] = []
var _shadow: MeshInstance3D
var _atlas: Texture2D
var _source_hashes: Dictionary = {}


func _initialize() -> void:
	_render = OS.get_cmdline_user_args().has("--render-poses")
	_run.call_deferred()


func _run() -> void:
	if _render and DisplayServer.get_name() == "headless":
		_expect(false, "--render-poses requires a queued graphical renderer")
		await _finish()
		return
	_source_hashes = _file_hashes()
	_expect(_source_hashes.atlas == AtlasHash and not String(_source_hashes.art).is_empty(), "native atlas bytes match the frozen original; art source hash is recorded")
	var native := Image.new()
	var image_error: Error = native.load_png_from_buffer(FileAccess.get_file_as_bytes(AtlasPath))
	if not _expect(image_error == OK and not native.is_empty() and native.get_size() == Vector2i(1254, 1254), "native PNG remains an untouched 1254-square two-by-two atlas"):
		await _finish()
		return
	for index: int in range(4):
		_expect(_opaque_bounds(native, Vector2i(Regions[index].position)) == OpaqueBounds[index], PoseKeys[index] + ": native alpha-scissor silhouette bounds match source inspection")
	await _prepare()
	if not _expect(_sprites.size() == 4 and _shadow != null, "actual art creates exactly four Sprite3D stills and its native contact shadow"):
		await _finish()
		return
	var camera_probe := Camera3D.new()
	camera_probe.size = 7.2
	_expect(_viewport.get_camera_3d() == _camera and _camera.get_viewport() == _viewport and _camera.projection == Camera3D.PROJECTION_ORTHOGONAL and _camera.keep_aspect == Camera3D.KEEP_WIDTH and _camera.size == camera_probe.size and _camera.position == Vector3(0, 18, 13) and _viewport.size == Vector2i(339, 736), "ready portrait native Camera3D retains the shared orthographic width/offset/angle configuration")
	camera_probe.free()
	var common_scale: float = _sprites[0].pixel_size
	var scale_probe := Sprite3D.new()
	scale_probe.pixel_size = 1.35 / 807.0
	_expect(common_scale == scale_probe.pixel_size, "all poses use the exact native getter value of the one proposed 1.35/807 scale")
	scale_probe.free()
	for phase: String in ["clear", "idle", "warning", "lock", "active", "recovery", "defeated", "spent"]:
		_test_phase(phase, common_scale)
	_test_failures()
	if _render and _failures == 0:
		await _render_poses()
	_expect(_file_hashes() == _source_hashes and _shell.planner_calls == 0, "bounds and renderer tests preserve atlas/source bytes and never request camera admission")
	print("Native Root Latcher art source hashes: " + str(_source_hashes))
	await _finish()


func _prepare() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(339, 736)
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _render else SubViewport.UPDATE_DISABLED
	root.add_child(_viewport)
	_world = Node3D.new()
	_viewport.add_child(_world)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.keep_aspect = Camera3D.KEEP_WIDTH
	_camera.size = 7.2
	_world.add_child(_camera)
	_camera.position = Vector3(0, 18, 13)
	_camera.look_at(Vector3.ZERO)
	_camera.current = true
	_shell = NativeCameraAdapter.new()
	_shell.camera = _camera
	root.add_child(_shell)
	_parent = Node3D.new()
	_world.add_child(_parent)
	# The actual isolated room's rooted source is translated here; its world
	# basis stays identity. This leaf adds no actor or mechanical authority.
	_parent.position = Vector3(0, 0, -0.4)
	_art = Art.new()
	var not_ready: Dictionary = _art.call("framing_points", _shell)
	_expect(_rejected(not_ready), "detached art rejects without substitute bounds")
	_parent.add_child(_art)
	await process_frame
	for key: String in PoseKeys:
		var sprite: Sprite3D = _art.get_node_or_null("NativeStill_" + key) as Sprite3D
		if sprite != null:
			_sprites.append(sprite)
	_shadow = _art.get_node_or_null("FilledRootContact") as MeshInstance3D
	if not _sprites.is_empty():
		_atlas = (_sprites[0].texture as AtlasTexture).atlas
	_expect(_art.get_children().size() == 5 and _art.get_groups().is_empty() and _art.find_children("*", "CollisionObject3D", true, false).is_empty(), "owned art leaf adds no physical body, target group or extra consumer")


func _test_phase(phase: String, common_scale: float) -> void:
	if not _expect(_art.call("present", phase) == true, "actual art accepts its explicit phase: " + phase):
		return
	var pose: String = "raised" if phase in ["warning", "lock", "active"] else ("exposed" if phase == "recovery" else ("spent" if phase in ["defeated", "spent"] else "closed"))
	var state: Dictionary = _art.call("state")
	var before: Dictionary = _capture()
	var result: Dictionary = _art.call("framing_points", _shell)
	var repeated: Dictionary = _art.call("framing_points", _shell)
	if not _expect(String(result.get("error", "unsupported response")).is_empty() and result.get("points", []).size() == 24 and result == repeated and _capture() == before, phase + ": pure repeated native adapter returns 16 still corners plus 8 shadow corners without mutation"):
		return
	_expect(state.pose_key == pose and state.phase == phase, phase + ": warning/lock/active share only the raised still; recovery and explicit defeat retain their own pose")
	var exact_settings: bool = true
	var mesh_matches: bool = true
	var complete_points: Array[Vector3] = []
	var projection_matches: bool = true
	var pivot_matches: bool = true
	for index: int in range(4):
		var sprite: Sprite3D = _sprites[index]
		var texture: AtlasTexture = sprite.texture as AtlasTexture
		var pivot: Vector2 = Pivots[index]
		var rect: Rect2 = sprite.get_item_rect()
		exact_settings = exact_settings and texture != null and texture.atlas == _atlas and texture.region == Regions[index] and texture.margin == Rect2() and texture.filter_clip and texture.get_size() == Vector2(627, 627) and rect == Rect2(Vector2(-pivot.x, pivot.y - 627), Vector2(627, 627)) and sprite.pixel_size == common_scale and sprite.visible == (PoseKeys[index] == pose)
		var expected_local: Array[Vector3] = []
		for x: float in [rect.position.x, rect.end.x]:
			for y: float in [rect.position.y, rect.end.y]:
				expected_local.append(Vector3(x * common_scale, y * common_scale, 0))
		var mesh: TriangleMesh = sprite.generate_triangle_mesh()
		var unique: Array[Vector3] = []
		if mesh != null:
			for point: Vector3 in mesh.get_faces():
				if not unique.has(point):
					unique.append(point)
		# Godot4.7.2 TriangleMesh::create welds vertices snapped to0.0001m.
		# The real rendered Sprite3D vertices remain unsnapped; these two
		# expectations must stay distinct. Neither comparison widens epsilon.
		# https://github.com/godotengine/godot/blob/4.7.2-stable/core/math/triangle_mesh.cpp#L125-L133
		var expected_mesh: Array[Vector3] = []
		for corner: Vector3 in expected_local:
			expected_mesh.append(corner.snappedf(0.0001))
		mesh_matches = mesh_matches and mesh != null and mesh.get_faces().size() == 6 and _same_points(unique, expected_mesh, WorldEpsilon)
		for corner: Vector3 in expected_local:
			# Test independently with native Transform3D, rather than copying the
			# adapter's per-axis summation or using a culling AABB for the quad.
			var billboard := Transform3D(_camera.global_basis, sprite.global_position)
			var world_corner: Vector3 = billboard * corner
			complete_points.append(world_corner)
			projection_matches = projection_matches and _projection_matches(world_corner)
		# An image pixel at the cell's authored ground pivot maps to local(0,0)
		# under the actual native item rectangle, at one common feet anchor.
		var local_pivot := Vector3((rect.position.x + pivot.x) * common_scale, (rect.end.y - pivot.y) * common_scale, 0)
		pivot_matches = pivot_matches and local_pivot == Vector3.ZERO and sprite.global_position == _art.global_position + Vector3(0, 0.025, 0)
	complete_points.append_array(_shadow_points())
	for point: Vector3 in _shadow_points():
		projection_matches = projection_matches and _projection_matches(point)
	_expect(exact_settings and pivot_matches, phase + ": all four zero-margin cells keep exact regions, one scale and the common planted pivot")
	_expect(mesh_matches and _same_points(result.points, complete_points, WorldEpsilon), phase + ": adapter corners match independently derived unsnapped native item quads and actual shadow bounds; native_mesh_matches=" + str(mesh_matches))
	_expect(projection_matches, phase + ": native projection/unprojection and screen reprojection agree for all 24 complete corners")
	var mutable: Dictionary = result.duplicate(true)
	mutable.points[0] = Vector3(999, 999, 999)
	_expect(_art.call("framing_points", _shell) == repeated and _capture() == before, phase + ": returned points retain no mutable art state")


func _projection_matches(point: Vector3) -> bool:
	var screen: Vector2 = _camera.unproject_position(point)
	var local: Vector3 = _camera.to_local(point)
	var depth: float = -local.z
	var viewport_size := Vector2(_viewport.size)
	var camera_height: float = _camera.size * viewport_size.y / viewport_size.x
	var independent_screen := Vector2(viewport_size.x * (0.5 + local.x / _camera.size), viewport_size.y * (0.5 - local.y / camera_height))
	var returned: Vector3 = _camera.project_position(screen, depth)
	return screen.is_finite() and depth > _camera.near and depth < _camera.far and Rect2(Vector2.ZERO, viewport_size).has_point(screen) and _camera.is_position_in_frustum(point) and not _camera.is_position_behind(point) and screen.distance_to(independent_screen) <= ScreenEpsilon and returned.distance_to(point) <= WorldEpsilon and _camera.unproject_position(returned).distance_to(screen) <= ScreenEpsilon


func _test_failures() -> void:
	_art.call("present", "clear")
	var before: Dictionary = _capture()
	_expect(_art.call("present", "invented_pose") == false and _art.call("state").pose_key == "closed", "unsupported presentation keeps the actual selected still")
	_art.call("present", "clear")
	_expect(_capture() == before, "explicit valid presentation clears the error and restores exact state")
	var no_method := Node.new()
	_expect(_rejected(_art.call("framing_points", no_method)) and _rejected(_art.call("framing_points", null)), "absent camera adapter rejects without points")
	no_method.free()
	var sprite: Sprite3D = _sprites[0]
	var texture: AtlasTexture = sprite.texture as AtlasTexture
	_reject_property(texture, "region", Rect2(1, 0, 627, 627), "atlas region")
	_reject_property(texture, "margin", Rect2(1, 1, 1, 1), "atlas margin")
	_reject_property(texture, "atlas", _atlas.duplicate(), "atlas identity")
	_reject_property(texture, "filter_clip", false, "atlas clipping")
	_reject_property(sprite, "texture", texture.duplicate(), "native AtlasTexture identity")
	_reject_property(sprite, "pixel_size", sprite.pixel_size * 1.01, "native pixel scale")
	_reject_property(sprite, "offset", sprite.offset + Vector2(1, 0), "feet offset")
	_reject_property(sprite, "axis", Vector3.AXIS_Y, "sprite axis")
	_reject_property(sprite, "flip_h", true, "horizontal flip")
	_reject_property(sprite, "flip_v", true, "vertical flip")
	_reject_property(sprite, "centered", false, "centred quad")
	_reject_property(sprite, "billboard", BaseMaterial3D.BILLBOARD_FIXED_Y, "fixed-Y billboard")
	_reject_property(sprite, "fixed_size", true, "fixed screen size")
	_reject_property(sprite, "region_enabled", true, "alternate sprite region mode")
	_reject_property(sprite, "hframes", 2, "alternate frame grid")
	_reject_property(sprite, "transform", Transform3D(Basis.IDENTITY, Vector3(0, 0.026, 0)), "still transform")
	_reject_property(sprite, "material_override", ShaderMaterial.new(), "custom override shader")
	_reject_property(sprite, "material_overlay", StandardMaterial3D.new(), "material overlay")
	_reject_property(sprite, "no_depth_test", true, "depth bypass")
	_reject_property(sprite, "shaded", true, "shaded sprite")
	_reject_property(sprite, "transparent", false, "sprite transparency")
	_reject_property(sprite, "double_sided", false, "sprite sidedness")
	_reject_property(sprite, "alpha_cut", SpriteBase3D.ALPHA_CUT_DISABLED, "alpha discard")
	_reject_property(sprite, "alpha_scissor_threshold", 0.4, "alpha threshold")
	_reject_property(sprite, "texture_filter", BaseMaterial3D.TEXTURE_FILTER_LINEAR, "nearest sampling")
	_reject_property(sprite, "modulate", Color(0.9, 1, 1, 1), "sprite colour")
	_reject_property(sprite, "visible", false, "selected still visibility")
	_reject_property(_sprites[2], "flip_h", true, "inactive future-pose drift")
	_reject_property(_art, "basis", Basis.IDENTITY.scaled(Vector3(1.1, 1, 1)), "art local basis")
	_reject_property(_parent, "basis", Basis.IDENTITY.rotated(Vector3.UP, 0.1), "inherited art world basis")
	_reject_property(_art, "visible", false, "art tree visibility")
	_reject_property(_camera, "projection", Camera3D.PROJECTION_PERSPECTIVE, "nonorthographic camera")
	_reject_scaled_camera()
	_reject_property(_camera, "basis", _camera.basis.scaled(Vector3(-1, 1, 1)), "left-handed camera basis")
	_reject_property(_shadow, "visible", false, "actual shadow visibility")
	_reject_property(_shadow, "transform", Transform3D(Basis.IDENTITY, Vector3(0, 0.01, 0)), "shadow transform")
	_reject_property(_shadow, "mesh", CylinderMesh.new(), "actual shadow mesh identity")
	_reject_property(_shadow.mesh, "top_radius", 0.33, "shadow radius")
	_reject_property(_shadow.mesh, "height", 0.007, "shadow height")
	_reject_property(_shadow.mesh, "radial_segments", 16, "shadow topology")
	_reject_property(_shadow, "material_override", StandardMaterial3D.new(), "actual shadow material identity")
	_reject_property(_shadow, "material_overlay", StandardMaterial3D.new(), "shadow material overlay")
	_reject_property(_shadow.material_override, "grow", true, "actual BaseMaterial3D grow property")
	_reject_property(_shadow.material_override, "shading_mode", BaseMaterial3D.SHADING_MODE_PER_PIXEL, "shadow shading")
	_reject_property(_shadow.material_override, "albedo_color", Color.RED, "shadow colour")
	_reject_property(_shadow.material_override, "billboard_mode", BaseMaterial3D.BILLBOARD_ENABLED, "shadow billboard")


func _reject_scaled_camera() -> void:
	var before: Dictionary = _capture()
	var scale_disabled: bool = _camera.is_scale_disabled()
	# Camera3D's constructor suppresses scale in its public global transform.
	# Exercise a genuinely scaled actual global basis instead of assuming that
	# an ordinary Camera3D local-scale attempt reaches the adapter unchanged.
	# https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/camera_3d.cpp#L816-L824
	_camera.set_disable_scale(false)
	_camera.transform = _camera.transform
	_reject_property(_camera, "basis", _camera.basis.scaled(Vector3(1.1, 1, 1)), "scaled actual camera basis")
	_camera.set_disable_scale(scale_disabled)
	# set_disable_scale alone does not invalidate Node3D's cached transform.
	_camera.transform = _camera.transform
	_expect(_capture() == before, "native camera scale suppression and all exact settings are restored")


func _reject_property(object: Object, property: String, replacement: Variant, label: String) -> void:
	var baseline: Dictionary = _capture()
	var baseline_result: Dictionary = _art.call("framing_points", _shell)
	if not String(baseline_result.get("error", "missing native baseline")).is_empty() or baseline_result.get("points", []).size() != 24:
		_expect(false, label + ": rejection test requires a supported native baseline")
		return
	var original: Variant = object.get(property)
	object.set(property, replacement)
	var altered: Dictionary = _capture()
	var answer: Dictionary = _art.call("framing_points", _shell)
	var repeated: Dictionary = _art.call("framing_points", _shell)
	var quiet: bool = _capture() == altered
	object.set(property, original)
	_expect(_rejected(answer) and answer == repeated and quiet and _capture() == baseline and _art.call("framing_points", _shell) == baseline_result, "rejects " + label + " with no points/mutation; exact native setting restored: " + String(answer.get("error", "missing response")))


func _capture() -> Dictionary:
	var stills: Array = []
	for sprite: Sprite3D in _sprites:
		var entry: Dictionary = {"instance": sprite.get_instance_id(), "parent": sprite.get_parent().get_instance_id(), "global_transform": sprite.global_transform, "item_rect": sprite.get_item_rect()}
		for property: String in SpriteProperties:
			entry[property] = sprite.get(property)
		if sprite.texture is AtlasTexture:
			var texture: AtlasTexture = sprite.texture as AtlasTexture
			entry.atlas = {"atlas": texture.atlas, "region": texture.region, "margin": texture.margin, "filter_clip": texture.filter_clip, "size": texture.get_size()}
		stills.append(entry)
	var shadow: Dictionary = {}
	if _shadow != null:
		shadow = {"transform": _shadow.transform, "visible": _shadow.visible, "mesh": _shadow.mesh, "material_override": _shadow.material_override, "material_overlay": _shadow.material_overlay, "bounds": _shadow.get_aabb()}
		if _shadow.mesh is CylinderMesh:
			var disk: CylinderMesh = _shadow.mesh as CylinderMesh
			shadow.disk = [disk.top_radius, disk.bottom_radius, disk.height, disk.radial_segments]
		if _shadow.material_override is StandardMaterial3D:
			var material: StandardMaterial3D = _shadow.material_override as StandardMaterial3D
			shadow.material = [material.shading_mode, material.albedo_color, material.grow, material.billboard_mode]
	return {"art": _art.call("state"), "transform": _art.transform, "global_transform": _art.global_transform, "visible": _art.visible, "parent_transform": _parent.transform, "camera": [_camera.transform, _camera.global_transform, _camera.is_scale_disabled(), _camera.projection, _camera.keep_aspect, _camera.size, _camera.near, _camera.far, _camera.h_offset, _camera.v_offset], "stills": stills, "shadow": shadow, "planner_calls": _shell.planner_calls}


func _shadow_points() -> Array[Vector3]:
	var result: Array[Vector3] = []
	var bounds: AABB = _shadow.get_aabb()
	for index: int in range(8):
		result.append(_shadow.global_transform * bounds.get_endpoint(index))
	return result


func _same_points(actual: Array, expected: Array, epsilon: float) -> bool:
	if actual.size() != expected.size():
		return false
	var remaining: Array = expected.duplicate()
	for point: Variant in actual:
		if not point is Vector3 or not point.is_finite():
			return false
		var match_index: int = -1
		for index: int in range(remaining.size()):
			if point.distance_to(remaining[index]) <= epsilon:
				match_index = index
				break
		if match_index < 0:
			return false
		remaining.remove_at(match_index)
	return remaining.is_empty()


func _opaque_bounds(image: Image, origin: Vector2i) -> Rect2i:
	var low := Vector2i(627, 627)
	var high := Vector2i(-1, -1)
	for y: int in range(627):
		for x: int in range(627):
			if image.get_pixel(origin.x + x, origin.y + y).a >= 0.5:
				low.x = mini(low.x, x)
				low.y = mini(low.y, y)
				high.x = maxi(high.x, x)
				high.y = maxi(high.y, y)
	return Rect2i(low, high - low + Vector2i.ONE) if high.x >= 0 else Rect2i()


func _render_poses() -> void:
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CaptureDirectory))
	if not _expect(directory_error == OK, "native renderer capture directory is available"):
		return
	for index: int in range(4):
		var phase: String = ["clear", "warning", "recovery", "defeated"][index]
		_art.call("present", phase)
		var before: Dictionary = _capture()
		await process_frame
		await RenderingServer.frame_post_draw
		await process_frame
		await RenderingServer.frame_post_draw
		var image: Image = _viewport.get_texture().get_image()
		if not _expect(image != null and not image.is_empty() and image.get_size() == _viewport.size, PoseKeys[index] + ": genuine transparent 339x736 native viewport pixels are available"):
			continue
		var full_quad: Rect2 = _quad_screen_rect(_sprites[index])
		var shadow_bounds: Rect2 = _screen_rect(_shadow_points())
		var complete_bounds: Rect2 = full_quad.merge(shadow_bounds)
		var count: int = 0
		var escaped: int = 0
		for y: int in range(image.get_height()):
			for x: int in range(image.get_width()):
				if image.get_pixel(x, y).a > 0.01:
					count += 1
					var centre := Vector2(float(x) + 0.5, float(y) + 0.5)
					# One output-pixel raster guard, not a geometric admission
					# tolerance; alpha comes from the actual still plus shadow.
					if not full_quad.grow(1.0).has_point(centre) and not shadow_bounds.grow(1.0).has_point(centre):
						escaped += 1
		var used: Rect2i = image.get_used_rect()
		_expect(count > 50 and escaped == 0 and complete_bounds.grow(1.0).encloses(Rect2(used)) and image.get_pixel(0, 0).a == 0.0 and image.get_pixel(image.get_width() - 1, image.get_height() - 1).a == 0.0 and _capture() == before, PoseKeys[index] + ": actual renderer alpha stays inside projected full native quad/contact-shadow bounds with transparent exterior")
		var path: String = CaptureDirectory.path_join(PoseKeys[index] + ".png")
		_expect(image.save_png(ProjectSettings.globalize_path(path)) == OK, PoseKeys[index] + ": unedited native viewport capture saved")
		print("Native renderer pose=%s alpha_pixels=%d escaped=%d alpha_bounds=%s quad=%s shadow=%s path=%s" % [PoseKeys[index], count, escaped, used, full_quad, shadow_bounds, ProjectSettings.globalize_path(path)])


func _quad_screen_rect(sprite: Sprite3D) -> Rect2:
	var points: Array[Vector3] = []
	var rect: Rect2 = sprite.get_item_rect()
	var billboard := Transform3D(_camera.global_basis, sprite.global_position)
	for x: float in [rect.position.x, rect.end.x]:
		for y: float in [rect.position.y, rect.end.y]:
			points.append(billboard * Vector3(x * sprite.pixel_size, y * sprite.pixel_size, 0))
	return _screen_rect(points)


func _screen_rect(points: Array[Vector3]) -> Rect2:
	var first: bool = true
	var result := Rect2()
	for point: Vector3 in points:
		var screen: Vector2 = _camera.unproject_position(point)
		result = Rect2(screen, Vector2.ZERO) if first else result.expand(screen)
		first = false
	return result


func _rejected(result: Dictionary) -> bool:
	return result.get("error") is String and not String(result.error).is_empty() and result.get("points") is Array and result.points.is_empty()


func _file_hashes() -> Dictionary:
	return {"atlas": FileAccess.get_sha256(AtlasPath), "art": FileAccess.get_sha256(ArtPath)}


func _expect(condition: bool, label: String) -> bool:
	_checks += 1
	if condition:
		print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label)
	return condition


func _finish() -> void:
	if is_instance_valid(_viewport):
		_viewport.queue_free()
	if is_instance_valid(_shell):
		_shell.queue_free()
	await process_frame
	_expect(not is_instance_valid(_viewport) and not is_instance_valid(_shell), "native art/camera leaf cleanup frees the isolated world and adapter")
	print("Root Latcher native art adapter smoke: %d checks, %d failures; renderer=%s; no combat/admission acceptance" % [_checks, _failures, _render])
	quit(0 if _failures == 0 else 1)
