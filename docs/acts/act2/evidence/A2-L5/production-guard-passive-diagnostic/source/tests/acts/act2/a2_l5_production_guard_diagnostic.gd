extends "res://tests/acts/act2/a2_l5_production_portrait_smoke.gd"
## TMP TEST ONLY passive derivative of frozen 437/7fcd2192.
## Calls the original guard once and returns its unchanged answer. Records the
## first actual refusal before cancellation, then observes twelve ordinary
## render frames after that refusal. No retry, camera/pose/input/clock writes,
## added admission, tolerance changes or production/whole-level/art credit.
## Inherited four-view assertions and failed-scope attribution remain intact.
const DIAG_OUTPUT: String = "res://captures/act2/a2-l5-production-guard-diagnostic/first-refusal.exact.json"
var _diag_first: Dictionary = {}
var _diag_guard_calls: int = 0

func _art_guard(proposed: Dictionary) -> bool:
	_diag_guard_calls += 1
	var accepted: bool = super._art_guard(proposed)
	if not accepted and _diag_first.is_empty():
		_diag_first = _diag_measure(proposed)
		_diag_first["first_refusal"] = true
		_diag_first["guard_answer"] = accepted
		_diag_first["guard_call"] = _diag_guard_calls
	return accepted

func _art_until_phase(consumer: Node3D, phase: String) -> bool:
	var reached: bool = await super._art_until_phase(consumer, phase)
	if not reached and not _diag_first.is_empty():
		# Capture first-refusal custody was already completed inside the guard,
		# before the parent closes its stage and cancels sources. These later
		# rows only observe normal follow after the genuine refusal; no restart.
		var after: Array[Dictionary] = []
		for frame: int in range(13):
			if frame in [0, 1, 4, 12]:
				var row: Dictionary = _diag_measure({})
				row["render_frames_after_phase_refusal"] = frame
				after.append(row)
			if frame < 12: await process_frame
		var packet: Dictionary = {"api_revision": "act2-production-guard-diagnostic-1", "scope": "passive native first-refusal and ordinary follow observation; no Ray/Foot/coda acceptance", "original_fixture_sha256": FileAccess.get_sha256("res://tests/acts/act2/a2_l5_production_portrait_smoke.gd"), "requested_phase": phase, "first": _diag_first.duplicate(true), "after_cancel": after}
		var encoded: String = ArtJson.stringify(_diag_json_value(packet))
		var created: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAG_OUTPUT.get_base_dir()))
		var saved: bool = false
		if created == OK and not encoded.is_empty():
			var file: FileAccess = FileAccess.open(DIAG_OUTPUT, FileAccess.WRITE)
			if file != null:
				file.store_string(encoded)
				file.close()
				saved = true
		print("L5 passive guard diagnostic: saved=", saved, "; path=", DIAG_OUTPUT, "; first_current_error=", _diag_first.get("current_error", ""), "; first_settled_error=", _diag_first.get("settled_error", ""), "; first_points=", _diag_first.get("required_point_count", -1), "; no authority retry/art credit")
	return reached

func _diag_measure(proposed: Dictionary) -> Dictionary:
	var points: Array[Vector3] = _art_component_points(proposed)
	var hero_points: Array = _game.player_camera_framing_points()
	var delta: Vector3 = _game.player.global_position + Vector3.UP * .75 + Vector3(0, 18, 13) - _game.camera.global_position
	var shifted: Array[Vector3] = []
	for point: Vector3 in points: shifted.append(point - delta)
	var result: Dictionary = {"physics_frame": Engine.get_physics_frames(), "process_frame": Engine.get_process_frames(), "tree_paused": paused, "scheduler_clock_s": _art_scheduler.get_clock(), "hero_position": Codec.vector3(_game.player.global_position), "hero_hp": _game.player.hp, "hero_dead": _game.player.dead, "hero_response": _art_encode(_game.player.get_threat_response_state()), "completed_world_actions": _art_encode(_game.player.get_world_action_records()), "bait": _art_bait.call("state"), "camera_position": Codec.vector3(_game.camera.global_position), "camera_basis": _art_encode(_game.camera.global_basis), "camera_size": _game.camera.size, "camera_projection": _game.camera.projection, "camera_viewport_size": [_game.camera.get_viewport().get_visible_rect().size.x, _game.camera.get_viewport().get_visible_rect().size.y], "ordinary_settled_delta": Codec.vector3(delta), "required_point_count": points.size(), "mandatory_hero_point_count": hero_points.size(), "effective_guard_point_count": points.size() + hero_points.size(), "current_error": _game.camera_framing_error(points), "settled_error": _game.camera_framing_error(shifted), "required_points": _art_encode(points), "shifted_required_points": _art_encode(shifted), "parent_errors": _art_parent_errors.duplicate(), "nodes": [], "mesh_groups": [], "ray": {}, "foot": {}, "proposed_ray": _art_encode(proposed.get("ray", {})), "proposed_foot_preview": _art_encode(proposed.get("foot_preview", {}))}
	var safe: Rect2 = _game.hud.combat_safe_rect()
	result["hud_safe_rect"] = {"position": [safe.position.x, safe.position.y], "size": [safe.size.x, safe.size.y]}
	var actor: Variant = _art_parent.call("get_actor")
	var ray: Variant = _art_parent.call("get_ray")
	var foot: Variant = _art_parent.call("get_foot")
	var rig: Variant = actor.call("get_cosmetic_rig") if is_instance_valid(actor) else null
	var foot_visual: Variant = foot.get_node_or_null("InheritedGreyboxGiantFoot") if is_instance_valid(foot) else null
	var joint: Variant = _art_parent.call("get_joint_cue")
	var ray_cue: Variant = ray.call("get_cue") if is_instance_valid(ray) else null
	var foot_cue: Variant = foot.call("get_cue") if is_instance_valid(foot) else null
	var named: Dictionary = {"parent": _art_parent, "world": _game.world, "hero": _game.player, "effects": _game.fx, "scheduler": _art_scheduler, "actor": actor, "rig": rig, "foot": foot, "foot_visual": foot_visual, "joint_cue": joint, "ray": ray, "ray_cue": ray_cue, "foot_cue": foot_cue}
	for label: String in named:
		(result.nodes as Array).append(_diag_node(label, named[label]))
	if is_instance_valid(actor): result["source_projection"] = actor.call("source_snapshot_state")
	if is_instance_valid(ray): result.ray = _art_encode(ray.call("state"))
	if is_instance_valid(foot): result.foot = _art_encode(foot.call("state"))
	if is_instance_valid(rig):
		result["body_yaw"] = rig.call("get_body_yaw")
		for node: Node3D in rig.call("required_source_nodes"):
			(result.mesh_groups as Array).append(_diag_mesh_group(str(node.get_path()), node, delta))
	for label: String in ["foot_visual", "joint_cue", "ray_cue", "foot_cue"]:
		(result.mesh_groups as Array).append(_diag_mesh_group(label, named[label], delta))
	result["native_required_pixels"] = _diag_pixels(points)
	return result

func _diag_node(label: String, value: Variant) -> Dictionary:
	var row: Dictionary = {"label": label, "valid": is_instance_valid(value)}
	if not is_instance_valid(value) or not value is Node: return row
	row["path"] = str(value.get_path()) if value.is_inside_tree() else ""
	row["inside_tree"] = value.is_inside_tree()
	row["queued"] = value.is_queued_for_deletion()
	row["script"] = value.get_script().resource_path if value.get_script() is Script else ""
	if value is Node3D:
		row["visible"] = value.visible
		row["visible_in_tree"] = value.is_visible_in_tree()
		if value.is_inside_tree():
			row["same_world_as_hero"] = value.get_world_3d() == _game.player.get_world_3d()
			row["position"] = Codec.vector3(value.global_position)
			row["basis"] = _art_encode(value.global_basis)
	var ancestors: Array[Dictionary] = []
	var current: Node = value.get_parent()
	for _depth: int in range(32):
		if current == null: break
		if current is Node3D: ancestors.append({"path": str(current.get_path()), "visible": current.visible, "visible_in_tree": current.is_visible_in_tree(), "queued": current.is_queued_for_deletion()})
		current = current.get_parent()
	row["native_ancestors"] = ancestors
	return row

func _diag_mesh_group(label: String, value: Variant, delta: Vector3) -> Dictionary:
	var points: Array[Vector3] = []
	if is_instance_valid(value) and value is Node: points.assign(_art_mesh_bounds(value))
	var shifted: Array[Vector3] = []
	for point: Vector3 in points: shifted.append(point - delta)
	return {"label": label, "node": _diag_node(label, value), "point_count": points.size(), "points": _art_encode(points), "current_error": _game.camera_framing_error(points) if not points.is_empty() else "no visible native mesh bounds", "settled_error": _game.camera_framing_error(shifted) if not points.is_empty() else "no visible native mesh bounds", "native_viewport_pixels": _diag_pixels(points)}

func _diag_pixels(points: Array[Vector3]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for point: Vector3 in points:
		var pixel: Vector2 = _game.camera.unproject_position(point)
		result.append({"point": Codec.vector3(point), "native_viewport_pixel": [pixel.x, pixel.y], "behind_camera": _game.camera.is_position_behind(point)})
	return result

func _diag_json_value(value: Variant, depth: int = 0) -> Variant:
	## Diagnostic classification only. Native references never become restore,
	## floor, proof or damage authority. Original guard and codecs are untouched.
	if depth > 64: return {"diagnostic_depth_limit": true}
	if value is Object:
		var native: Dictionary = {"valid": is_instance_valid(value)}
		if is_instance_valid(value):
			native["class"] = value.get_class()
			if value is Node: native["node"] = _diag_node("diagnostic_native_reference", value)
		return {"diagnostic_native_object": native}
	if value is Vector3: return Codec.vector3(value)
	if value is Vector2: return [value.x, value.y]
	if value is Basis: return {"x": _diag_json_value(value.x, depth + 1), "y": _diag_json_value(value.y, depth + 1), "z": _diag_json_value(value.z, depth + 1)}
	if value is Transform3D: return {"diagnostic_native_transform": {"basis": _diag_json_value(value.basis, depth + 1), "origin": _diag_json_value(value.origin, depth + 1)}}
	if value is Rect2: return {"diagnostic_native_rect": {"position": _diag_json_value(value.position, depth + 1), "size": _diag_json_value(value.size, depth + 1)}}
	if value is AABB: return {"diagnostic_native_aabb": {"position": _diag_json_value(value.position, depth + 1), "size": _diag_json_value(value.size, depth + 1)}}
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[str(key)] = _diag_json_value(value[key], depth + 1)
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_diag_json_value(item, depth + 1))
		return result
	if value is int and abs(value) > 9007199254740991: return {"diagnostic_native_integer_decimal": str(value)}
	if value is float and not is_finite(value): return {"diagnostic_native_nonfinite_float": str(value)}
	if value == null or value is bool or value is int or value is float or value is String: return value
	return {"diagnostic_native_variant_type": type_string(typeof(value)), "native_text": str(value)}
