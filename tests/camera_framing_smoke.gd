extends SceneTree
## Pure geometry leaf and actual ready orthographic projection; no act acceptance.
const Framing = preload("res://scripts/presentation/camera_framing.gd")
var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_ensure_owned_uids()
	_signed_flanks()
	_hud_and_validation()
	await _native_projection()
	print("Camera framing smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _spec() -> Dictionary:
	var offset := Vector3(0, 18, 13)
	return {"basis": Basis.looking_at(-offset, Vector3.UP), "offset": offset, "width": 7.2, "viewport_size": Vector2(270, 585), "safe_rect": Rect2(Vector2(12.0 / 270.0, 108.0 / 585.0), Vector2(246.0 / 270.0, 414.0 / 585.0)), "max_shift": 2.0, "safety_margin": 0.055, "near": 0.05, "far": 4000.0}


func _signed_points(sun: int, landing_x: float) -> Array:
	var endpoint := Vector3(1.02606 * (1.0 if sun == 0 else -1.0), 0.0, 2.419079)
	var start := Vector3(0, 0, -0.4)
	var points: Array = []
	# Explicit conservative test-only art/body boxes at both ends bound the
	# full moving source. Full capsule endcaps retain their actual .42 radius.
	for centre: Vector3 in [start + Vector3.UP * 0.72, endpoint + Vector3.UP * 0.72]:
		points.append_array(_corners(centre, Vector3(0.78, 0.77, 0.12)))
	for centre: Vector3 in [start, endpoint]:
		for direction: Vector3 in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
			points.append(centre + direction * 0.42)
	# Hero and full supported landing bounds, including visible coat/feet.
	points.append_array(_corners(Vector3(0, 0.78, 1.6), Vector3(0.54, 0.80, 0.32)))
	points.append_array(_corners(Vector3(landing_x, 0.78, 1.6), Vector3(0.54, 0.80, 0.32)))
	return points


func _signed_flanks() -> void:
	var spec: Dictionary = _spec()
	for sun: int in [0, 1]:
		for side: float in [-1.0, 1.0]:
			var focus := Vector3(side * 2.7, 0.75, 1.6)
			var points: Array = _signed_points(sun, focus.x)
			var points_before: Array = points.duplicate(true)
			var spec_before: Dictionary = spec.duplicate(true)
			var result: Dictionary = Framing.plan(points, focus, spec)
			_expect(result.get("accepted", false), "both signed suns support both near/far actual landing bounds: sun%d side%s %s" % [sun, side, result.get("reason", "")])
			if not result.get("accepted", false):
				continue
			_expect(result.focus.y == focus.y and result.width == spec.width and result.basis == spec.basis and result.shift.y == 0.0, "framing preserves exact focus height, width and fixed basis")
			_expect(Framing.containment(points, result.focus, spec).is_empty(), "proposed focus strictly contains complete art/endcaps/hero/landing")
			_expect(points == points_before and spec == spec_before and focus == Vector3(side * 2.7, 0.75, 1.6), "pure planner leaves all native caller inputs unchanged")
			paused = true
			var paused_result: Dictionary = Framing.plan(points, focus, spec)
			paused = false
			_expect(paused_result == result, "pure projection is independent of tree pause and advances no clock")
			var mutable: Dictionary = result.duplicate(true)
			mutable.camera_plane_shift_intervals[0] = Vector2(99, 99)
			_expect(Framing.plan(points, focus, spec) == result, "returned diagnostics retain no shared mutable state")
			var anchor := Vector2(0.78, 0.56)
			var tap := Vector2(0.35, 0.72)
			_expect(_aim(spec.basis, tap - anchor) == _aim(result.basis, tap - anchor) and anchor == Vector2(0.78, 0.56), "translation retains held screen release and exact basis-derived aim")
	var far_points: Array = _signed_points(1, 2.7)
	var far_focus := Vector3(2.7, 0.75, 1.6)
	_expect(not Framing.containment(far_points, far_focus, spec).is_empty(), "current hero-centred far Sun1 view rejects even though a future correction fits")
	var fixed: Dictionary = Framing.plan(far_points, far_focus, spec)
	_expect(fixed.get("accepted", false) and fixed.focus.x < far_focus.x - 0.5, "far Sun1 requires a material left translation without zoom")
	var mirrored: Dictionary = Framing.plan(_signed_points(0, -2.7), Vector3(-2.7, 0.75, 1.6), spec)
	_expect(fixed.get("accepted", false) and mirrored.get("accepted", false) and is_equal_approx(fixed.focus.x, -mirrored.focus.x) and is_equal_approx(fixed.focus.z, mirrored.focus.z), "signed far-side correction mirrors across the two sun rules")
	var no_shift: Dictionary = spec.duplicate(true)
	no_shift.max_shift = 0.0
	var centred: Dictionary = Framing.plan(_corners(Vector3(0, 0.75, 1.6), Vector3(0.54, 0.75, 0.32)), Vector3(0, 0.75, 1.6), no_shift)
	_expect(centred.get("accepted", false) and centred.focus == Vector3(0, 0.75, 1.6), "already-contained ordinary follow is exact and permits zero shift")


func _hud_and_validation() -> void:
	var spec: Dictionary = _spec()
	var focus := Vector3(0, 0.75, 1.6)
	var upper: Array = [_plane_point(focus, spec, Vector2(0, 5.2), 22.0), _plane_point(focus, spec, Vector2(1, -2), 22.0)]
	_expect(not Framing.containment(upper, focus, spec).is_empty(), "HUD-covered point fails actual containment while inside the full viewport")
	var result: Dictionary = Framing.plan(upper, focus, spec)
	_expect(result.get("accepted", false) and absf(result.focus.z - focus.z) > 0.1 and result.focus.y == focus.y and Framing.containment(upper, result.focus, spec).is_empty(), "vertical HUD fit inverts camera up into planar Z without changing height")
	var wide: Array = [Vector3(-4, 0, 0), Vector3(4, 0, 0)]
	_expect(not Framing.plan(wide, focus, spec).accepted, "infeasible complete union cannot be repaired by centering or implicit zoom")
	var small: Dictionary = spec.duplicate(true)
	small.max_shift = 0.2
	_expect(not Framing.plan(_signed_points(1, 2.7), Vector3(2.7, 0.75, 1.6), small).accepted, "oversized required shift fails the root's explicit bound")
	var behind: Array = [_plane_point(focus, spec, Vector2.ZERO, -1.0)]
	_expect(not Framing.plan(behind, focus, spec).accepted and not Framing.containment(behind, focus, spec).is_empty(), "behind-camera point rejects in plan and actual depth guard")
	var far: Array = [_plane_point(focus, spec, Vector2.ZERO, 50.0)]
	var shallow: Dictionary = spec.duplicate(true)
	shallow.far = 30.0
	_expect(not Framing.plan(far, focus, shallow).accepted, "far-plane clipping cannot be hidden by planar framing")
	var too_many: Array = []
	too_many.resize(257)
	too_many.fill(Vector3.ZERO)
	_expect(not Framing.plan(too_many, focus, spec).accepted, "anchor count is bounded before projection")
	for points: Array in [[], [Vector3(INF, 0, 0)], [Vector3(1025, 0, 0)], [[0, 0, 0]], ["fake point"]]:
		_expect(not Framing.plan(points, focus, spec).accepted, "empty/nonfinite/out-of-range/nonnative corner rejects")
	_expect(not Framing.plan([Vector3.ZERO], Vector3(1025, 0, 0), spec).accepted, "desired focus also obeys native coordinate bounds")
	for mutation: Dictionary in [{"basis": Basis.IDENTITY.scaled(Vector3(2, 1, 1))}, {"basis": spec.basis.rotated(Vector3.FORWARD, 0.1)}, {"basis": Basis.IDENTITY}, {"basis": Basis(Vector3(-1, 0, 0), Vector3.UP, Vector3.BACK)}, {"width": NAN}, {"width": 0.0}, {"viewport_size": Vector2.ZERO}, {"safe_rect": Rect2(0, 0, 270, 585)}, {"safe_rect": Rect2(0.1, 0.1, 0, 0.2)}, {"safe_rect": Rect2(-0.1, 0, 1, 1)}, {"safety_margin": 4.0}, {"near": 0.0}, {"far": 0.01}, {"max_shift": -1.0}, {"unknown": true}]:
		var bad: Dictionary = spec.duplicate(true)
		bad.merge(mutation, true)
		_expect(not Framing.plan([Vector3.ZERO], focus, bad).accepted and not Framing.containment([Vector3.ZERO], focus, bad).is_empty(), "unsupported fixed projection spec rejects in both APIs: " + str(mutation.keys()))
	var missing: Dictionary = spec.duplicate(true)
	missing.erase("offset")
	_expect(not Framing.plan([Vector3.ZERO], focus, missing).accepted, "missing root projection input has no default camera fallback")
	# A yawed but unrolled camera exercises both off-diagonal inverse terms.
	var yawed: Dictionary = spec.duplicate(true)
	yawed.basis = (spec.basis as Basis).rotated(Vector3.UP, 0.43)
	var yaw_points: Array = [_plane_point(focus, yawed, Vector2(-4, 6.2), 22.0)]
	yawed.max_shift = 3.0
	var yaw_plan: Dictionary = Framing.plan(yaw_points, focus, yawed)
	var reconstructed := Vector2.INF
	if yaw_plan.get("accepted", false):
		var shift: Vector3 = yaw_plan.shift
		var basis: Basis = yawed.basis
		reconstructed = Vector2(shift.dot(basis.x), shift.dot(basis.y))
	_expect(yaw_plan.get("accepted", false) and absf(yaw_plan.shift.x) > 0.1 and absf(yaw_plan.shift.z) > 0.1 and reconstructed.distance_to(yaw_plan.camera_plane_correction) < 0.00001 and Framing.containment(yaw_points, yaw_plan.focus, yawed).is_empty(), "supported unrolled yaw uses the full nonsingular two-by-two inverse: " + str(yaw_plan))


func _native_projection() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(270, 585)
	viewport.own_world_3d = true
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 7.2
	camera.current = true
	world.add_child(camera)
	await process_frame
	var spec: Dictionary = _spec()
	var desired := Vector3(2.7, 0.75, 1.6)
	camera.global_transform = Transform3D(spec.basis, desired + spec.offset)
	var points: Array = _signed_points(1, desired.x)
	var before: Transform3D = camera.global_transform
	var native_width: float = camera.size
	# The root spec uses actual native camera getters, whose float32 width
	# differs from the source literal7.2. Retain that exact native width.
	spec.width = native_width
	spec.basis = before.basis
	var result: Dictionary = Framing.plan(points, desired, spec)
	_expect(camera.is_node_ready() and camera.get_viewport() == viewport and viewport.get_camera_3d() == camera, "native orthographic camera belongs to a ready portrait SubViewport")
	_expect(camera.global_transform == before and camera.size == spec.width and result.get("accepted", false), "pure planning leaves actual camera projection and transform untouched")
	if result.get("accepted", false):
		# The fixture applies the diagnostic plan explicitly; production callers
		# must separately guard current projection before allowing damage.
		camera.global_position = result.focus + spec.offset
		var bounds := Rect2()
		var first: bool = true
		var protected: bool = true
		var depth_ok: bool = true
		for point: Vector3 in points:
			var screen: Vector2 = camera.unproject_position(point) / Vector2(viewport.size)
			bounds = Rect2(screen, Vector2.ZERO) if first else bounds.expand(screen)
			first = false
			protected = protected and spec.safe_rect.has_point(screen)
			depth_ok = depth_ok and camera.is_position_in_frustum(point) and not camera.is_position_behind(point)
		_expect(protected and depth_ok, "actual native unproject/frustum agrees that corrected full bounds are visible")
		_expect(bounds.position.distance_to(result.screen_bounds.position) < 0.00001 and bounds.size.distance_to(result.screen_bounds.size) < 0.00001, "analytic full screen bounds align with native Camera3D.unproject_position")
		_expect(camera.global_basis == before.basis and camera.size == native_width and camera.projection == Camera3D.PROJECTION_ORTHOGONAL and camera.keep_aspect == Camera3D.KEEP_WIDTH, "explicit fixture translation preserves exact captured native angle/width and portrait aspect mode")
		var held_anchor := Vector2(210, 328)
		var tap := Vector2(104, 402)
		_expect(_aim(camera.global_basis, tap - held_anchor) == _aim(before.basis, tap - held_anchor), "held release-point gesture direction is identical after actual camera translation")
	viewport.queue_free()
	await process_frame


func _corners(centre: Vector3, half: Vector3) -> Array:
	var result: Array = []
	for x: float in [-1.0, 1.0]:
		for y: float in [-1.0, 1.0]:
			for z: float in [-1.0, 1.0]:
				result.append(centre + Vector3(x * half.x, y * half.y, z * half.z))
	return result


func _plane_point(focus: Vector3, spec: Dictionary, plane: Vector2, depth: float) -> Vector3:
	var basis: Basis = spec.basis
	return focus + spec.offset + basis.x * plane.x + basis.y * plane.y - basis.z * depth


func _aim(basis: Basis, delta: Vector2) -> Vector3:
	var right: Vector3 = basis.x
	var down: Vector3 = basis.z
	right.y = 0.0
	down.y = 0.0
	return (right.normalized() * delta.x + down.normalized() * delta.y).normalized()


func _ensure_owned_uids() -> void:
	# This targeted script job does not run an editor import. Generate only its
	# two authorized UID sidecars when absent; preserve them on later runs.
	for path: String in ["res://scripts/presentation/camera_framing.gd.uid", "res://tests/camera_framing_smoke.gd.uid"]:
		if not FileAccess.file_exists(path):
			var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_line(ResourceUID.id_to_text(ResourceUID.create_id()))


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + description)
