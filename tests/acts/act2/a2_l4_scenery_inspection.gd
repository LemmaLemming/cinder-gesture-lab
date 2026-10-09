extends "res://tests/acts/act2/a2_l4_live_level_smoke.gd"
## TEST ONLY child: the unchanged actual nine-source route precedes four
## ordinary post-clear verge views. No live pose, HP, clock or camera seeds.
## Native pixels and recorded subject bounds still need visual review.

const SCENERY_CAPTURE_ROOT: String = "res://captures/act2/a2-l4-scenery/"
const EXIT_FRONT_Z: float = -47.9
const GOAL_RADIUS: float = 0.65
const SCENERY_VIEWS: Array[Dictionary] = [
	{"label": "scenery-field-gun", "goal": Vector3(-2.8, 0.0, -44.0), "paths": ["BroadPutneyApproach/QuietAbandonedFieldGun"]},
	{"label": "scenery-artilleryman", "goal": Vector3(2.8, 0.0, -44.0), "paths": ["NonhostileArtilleryman/FeetAnchoredCostume"]},
	{"label": "scenery-bleached-right", "goal": Vector3(2.8, 0.0, -26.2), "paths": ["TwoVillaArrangements/BleachedQuietView_1_0", "TwoVillaArrangements/BleachedQuietView_1_1"]},
	{"label": "scenery-bleached-left", "goal": Vector3(-2.8, 0.0, -26.2), "paths": ["TwoVillaArrangements/BleachedQuietView_-1_0", "TwoVillaArrangements/BleachedQuietView_-1_1"]},
]

var _scenery_label: String = ""
var _scenery_view: Dictionary = {}
var _scenery_navigation: bool = false
var _scenery_paths: Array[Dictionary] = []
var _scenery_metadata: Dictionary = {}
var _scenery_path_start: int = 0


func _read_options() -> bool:
	if not super._read_options(): return false
	_capture_live = true
	_capture_scope = "scenery"
	_capture_root = SCENERY_CAPTURE_ROOT
	return _expect(DisplayServer.get_name() != "headless", "scenery inspection requires actual graphical full-route capture")


func _required_capture_labels() -> Array[String]:
	var labels: Array[String] = ["scenery-field-gun", "scenery-artilleryman", "scenery-bleached-right", "scenery-bleached-left"]
	return labels


func _capture_labels(state: Dictionary) -> Array[String]:
	var labels: Array[String] = []
	if not _scenery_label.is_empty() and not _captured.has(_scenery_label) and not paused and _live() and _stable() and _scenery_clear(state):
		labels.append(_scenery_label)
	return labels


func _scenery_clear(state: Dictionary) -> bool:
	if state.get("beat") != "clear" or not state.get("exit_open", false) or not _game.active_level.is_completed(): return false
	if not _tail_pending.is_empty() or _tail_completed.size() != 2 or _actors.size() != 9: return false
	for actor: Node in _actors.values():
		if not is_instance_valid(actor) or float(actor.get("hp")) != 0.0: return false
	for bank: Node in _banks.values():
		if not is_instance_valid(bank) or bank.call("state").get("status") == "running": return false
	return true


func _prepare_additional_captures() -> bool:
	if not _expect(_live() and not paused and _scenery_clear(_state()), "four scenic views begin only after all nine earned defeats and both quiet finite tails"): return false
	_scenery_navigation = true
	for view: Dictionary in SCENERY_VIEWS:
		_scenery_view = view
		_scenery_path_start = _scenery_paths.size()
		var goal: Vector3 = view.goal
		goal.y = _game.player.global_position.y
		var reached: bool = false
		for attempt: int in range(24):
			if not await _wait_scenery_ready(): return false
			var at: Vector3 = _game.player.global_position
			if Vector2(at.x - goal.x, at.z - goal.z).length() <= GOAL_RADIUS:
				reached = true
				break
			if not await _navigate_dash(goal): return false
		# The final permitted dash also gets a real settled-landing check.
		if not reached and await _wait_scenery_ready():
			var at: Vector3 = _game.player.global_position
			reached = Vector2(at.x - goal.x, at.z - goal.z).length() <= GOAL_RADIUS
		if not _expect(reached, "at most 24 real supported swipes reach " + String(view.label)): return false
		if not await _settle_scenery_camera(): return false
		_scenery_label = String(view.label)
		var finished: bool = false
		for frame: int in range(120):
			if not _live() or paused or not _scenery_clear(_state()): return false
			await _step()
			await process_frame
			if _captured.has(_scenery_label) and _scenery_metadata.has(_scenery_label) and not _capture_pending:
				finished = true
				break
		if not _expect(finished, "actual post-draw scenic pixels and separate native metadata saved: " + _scenery_label): return false
		_scenery_label = ""
	_scenery_navigation = false
	return _expect(_scenery_metadata.size() == 4 and _game.active_level.is_completed() and _state().exit_open, "four quiet navigation views preserve earned completion before actual breakout contact")


func _wait_scenery_ready() -> bool:
	for frame: int in range(180):
		if not _live() or paused or not _scenery_clear(_state()): return false
		var response: Dictionary = _game.player.get_threat_response_state()
		if _stable() and float(response.dash_cooldown_left_s) <= 0.00001: return true
		await _step()
	return _expect(false, "scenic navigation waits actual stable grounded Hero and native dash cooldown")


func _settle_scenery_camera() -> bool:
	if not await _wait_scenery_ready(): return false
	for frame: int in range(120):
		if not _live() or paused or not _stable() or not _scenery_clear(_state()): return false
		# Observe ordinary follow; do not write focus, camera or Hero.
		var follow_position: Vector3 = _game.player.global_position + Vector3(0.0, 18.75, 13.0)
		if _game.camera.global_position.distance_to(follow_position) <= 0.03: return true
		await _step()
		await process_frame
	return _expect(false, "ordinary following camera settles naturally for quiet scenery")


func _dash(direction: Vector3, allow_exit_transition: bool = false, proof_plan: Dictionary = {}, proof_segment: Dictionary = {}) -> bool:
	if not _scenery_navigation:
		return await super._dash(direction, allow_exit_transition, proof_plan, proof_segment)
	if not await _wait_scenery_ready(): return false
	var hero: CinderPlayer = _game.player
	var full_end: Vector3 = hero.global_position + direction.normalized() * float(hero.stats.dash_distance)
	if not _expect(direction.is_finite() and direction.length_squared() > 0.0 and minf(hero.global_position.z, full_end.z) > EXIT_FRONT_Z, "planned quiet swipe stays strictly before the real exit region even without collision shortening"): return false
	var before: int = _actions.size()
	if not await super._dash(direction, false, proof_plan, proof_segment): return false
	var found: bool = false
	for action: Dictionary in _actions.slice(before):
		if action.kind != "dash": continue
		found = true
		for sample: Dictionary in action.path:
			var point: Vector3 = sample.position
			if not _expect(point.is_finite() and point.z > EXIT_FRONT_Z and point.y > -0.05 and point.y < 0.2 and _scenery_floor_contains(point), "every actual quiet dash sample remains on dry ground before breakout contact"): return false
		var encoded: Dictionary = CinderPlayer.encode_world_action_record(action, float(hero.get_threat_response_state().action_clock_s))
		if not _expect(not encoded.is_empty(), "actual quiet dash retains the public complete world-action encoding"): return false
		_scenery_paths.append(encoded)
	return _expect(found, "quiet scenery navigation publishes its genuine completed dash")


func _scenery_floor_contains(point: Vector3) -> bool:
	for specification: Dictionary in LondonFloor.SPECS:
		var rect: Rect2 = specification.rect
		if rect.has_point(Vector2(point.x, point.z)): return true
	return false


func _capture_state() -> void:
	var label: String = _scenery_label
	await super._capture_state()
	# Parent's post-draw save has no yield between pixels and these readings.
	if label.is_empty() or label != _scenery_label or not _captured.has(label) or _scenery_metadata.has(label): return
	if not _expect(_live() and not paused and _stable() and _scenery_clear(_state()), "saved scenic pixels retain the actual earned quiet unit"): return
	var kit := _game.active_level.get_node_or_null("LondonApproachesKit") as Node3D
	if not _expect(is_instance_valid(kit), "actual current London kit exists for scenery metadata"): return
	var subjects: Array[Dictionary] = []
	var combined: Array[Vector3] = []
	for path: String in _scenery_view.paths:
		var subject := kit.get_node_or_null(NodePath(path)) as Node3D
		if not _expect(is_instance_valid(subject) and subject.is_inside_tree() and subject.is_visible_in_tree(), "requested actual scenic subject is visible: " + path): return
		var points: Array[Vector3] = _scenery_subject_points(subject)
		if not _expect(not points.is_empty(), "requested subject has inspectable native bounds: " + path): return
		combined.append_array(points)
		var encoded_points: Array = []
		for point: Vector3 in points: encoded_points.append(Codec.vector3(point))
		subjects.append({"path": path, "class": subject.get_class(), "visible": subject.is_visible_in_tree(), "global_position": Codec.vector3(subject.global_position), "global_scale": Codec.vector3(subject.global_basis.get_scale()), "native_node_id_decimal": str(subject.get_instance_id()), "native_bounds_points": encoded_points, "camera_error_informational": _raw_camera_error(points)})
	var goal: Vector3 = _scenery_view.goal
	var frame: Dictionary = _captured[label].duplicate(true)
	frame["requested_subjects"] = subjects
	frame["subject_union_camera_error_informational"] = _raw_camera_error(combined)
	frame["navigation_goal_xz"] = [goal.x, goal.z]
	frame["actual_navigation_dash_records"] = _scenery_paths.slice(_scenery_path_start).duplicate(true)
	frame["kit_root_position"] = Codec.vector3(kit.global_position)
	frame["kit_art_revision"] = kit.get_meta("art_revision", "")
	frame["departure_tableau_active"] = kit.get_meta("departure_tableau_active", false)
	frame["departure_tableau_progress"] = kit.get_meta("departure_tableau_progress", 0.0)
	_scenery_metadata[label] = frame
	var payload: Dictionary = {"scope": "TEST ONLY actual unchanged full L4 route followed by four real supported post-clear swipes/viewpoints. Actual subject bounds/framing errors are informational; native pixel review judges occlusion and fidelity. No camera/pose/HP/clock seed or art-acceptance claim.", "frames": _scenery_metadata}
	var encoded: String = TailExact.stringify(payload)
	if not _expect(not encoded.is_empty(), "separate scenic metadata has finite exact JSON values"): return
	var file: FileAccess = FileAccess.open(_capture_root + "a2-l4-" + _profile_id + "-" + _loadout_name + "-scenery-metadata.json", FileAccess.WRITE)
	if _expect(file != null, "open separate native subject/path metadata"):
		file.store_string(encoded)


func _scenery_subject_points(subject: Node3D) -> Array[Vector3]:
	var points: Array[Vector3] = []
	if subject is Sprite3D:
		var sprite := subject as Sprite3D
		if not is_instance_valid(sprite.texture): return points
		# Actual native billboard rectangle; transparency pixels may occupy less.
		var size: Vector2 = Vector2(sprite.texture.get_size())
		var rect := Rect2(sprite.offset, size)
		if sprite.centered: rect.position -= size * 0.5
		for pixel: Vector2 in [rect.position, rect.position + Vector2(size.x, 0.0), rect.end, rect.position + Vector2(0.0, size.y)]:
			points.append(sprite.global_position + (_game.camera.global_basis.x * pixel.x + _game.camera.global_basis.y * pixel.y) * sprite.pixel_size)
	else:
		points.assign(_game.active_level.call("_required_source_points", subject))
	return points
