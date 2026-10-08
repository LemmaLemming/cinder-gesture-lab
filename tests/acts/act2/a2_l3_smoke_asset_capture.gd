extends SceneTree
## TEST ONLY five native smoke/cue poses. Direct Hero stage placement credits
## no input, route, Scheduler admission, exposure, damage, save or fairness.
const Main: PackedScene = preload("res://scenes/main.tscn")
const Geometry: Script = preload("res://scripts/combat/threat_geometry.gd")
const SmokeVisual: Script = preload("res://scripts/acts/act2/smoke_bank_visual.gd")
const PreviewPath: String = "res://tests/acts/act2/fixtures/a2_l3_smoke_preview.tscn"
var _capture_root: String = "res://captures/act2/a2-l3-smoke-assets/"
const VIEWS: Array[Dictionary] = [
	{"label": "smoke-warning", "phase": "warning", "p": 0.65, "hero": Vector3(1.2, 0.1, -3.5), "overlap": false},
	{"label": "smoke-lock", "phase": "lock", "p": 0.5, "hero": Vector3(1.2, 0.1, -3.5), "overlap": false},
	{"label": "smoke-active", "phase": "active", "p": 0.65, "hero": Vector3(1.2, 0.1, -3.5), "overlap": false},
	{"label": "smoke-recovery", "phase": "recovery", "p": 0.55, "hero": Vector3(1.2, 0.1, -3.5), "overlap": false},
	{"label": "smoke-active-hero-overlap", "phase": "active", "p": 0.65, "hero": Vector3(-0.9, 0.1, -3.5), "overlap": true},
]
var _checks: int = 0
var _failures: int = 0
var _game: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if "--revision3" in OS.get_cmdline_user_args():
		_capture_root = "res://captures/act2/a2-l3-smoke-revision3/"
	elif "--corrected" in OS.get_cmdline_user_args():
		_capture_root = "res://captures/act2/a2-l3-smoke-corrected/"
	root.size = Vector2i(540, 1170)
	_expect(DisplayServer.get_name() != "headless", "smoke portrait fixture requires a native graphical surface")
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	_expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_root)) == OK, "dedicated five-frame smoke art directory")
	_game = Main.instantiate()
	_game.set("level_scene_path", PreviewPath)
	root.add_child(_game)
	await _settle(12)
	var level := _game.get("active_level") as CinderLevel
	var hero := _game.get("player") as CinderPlayer
	var ready: bool = is_instance_valid(level) and is_instance_valid(hero) and level.scene_file_path == PreviewPath and level.hero == hero
	_expect(ready, "actual shared Game installs TEST ONLY smoke preview and actual Hero")
	if not ready:
		_game.queue_free()
		await process_frame
		quit(1)
		return
	var smoke := level.get("smoke") as Node3D
	var tender := level.get("tender") as Node3D
	var source := level.get("bank_source") as Node3D
	var cue := level.get("cue") as Node3D
	var kit: Dictionary = level.get("kit")
	var kit_root := kit.get("root") as Node3D
	_expect(level.get("assembly_error").is_empty() and level.get("floors").size() == 4 and hero.presentation_id == "act2_survivor", "production four-floor/kit/smoke assembly and shared Act2 skin")
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("practice_targets").is_empty() and get_nodes_in_group("required_cues").size() == 1, "one actual shared cue without targets, Scheduler or damage authority")
	var body := hero.get_node("BodyCollision") as CollisionShape3D
	_expect(body.shape is CapsuleShape3D, "stage occupancy uses the actual shared Hero capsule radius")
	var actor_radius: float = (body.shape as CapsuleShape3D).radius
	var source_home: Transform3D = source.global_transform
	var tender_home: Transform3D = tender.global_transform
	var hp_before: float = hero.hp
	# Compare the renderer's actual Color encoding, not a double against its
	# float32 material representation; this changes no clock or authority.
	var native_max_alpha: float = Color(1.0, 1.0, 1.0, SmokeVisual.ACTIVE_ALPHA).a
	var records: Array[Dictionary] = []
	for view: Dictionary in VIEWS:
		# Authorized TEST ONLY pose placement, not a completed dash or landing.
		hero.global_position = view["hero"]
		hero.velocity = Vector3.ZERO
		_expect(level.call("select_view", view["phase"], view["p"]), "supported actual shared cue and quiet vapour pose: " + view["label"])
		await _settle(40)
		var camera := _game.get("camera") as Camera3D
		var hero_bounds: Array[Vector3] = []
		hero_bounds.assign(_game.call("camera_billboard_points", hero.get_node("ActorSprite")))
		_expect(hero_bounds.size() >= 3 and tender.call("apply_readability", camera, hero_bounds), "actual shared billboard points drive Tender-only material cutaway: " + view["label"])
		var stats: Dictionary = smoke.call("geometry_stats")
		_expect(stats.get("constructed", false) and stats.get("part_count", 0) == 9 and stats.get("distinct_materials", 0) == 9 and stats.get("native_vertex_count", 0) > 0, "native nine-part isolated mesh/material query: " + view["label"])
		_expect(float(stats["max_planar_radius_m"]) <= 1.05 and float(stats["max_planar_radius_m"]) <= float(stats["authored_radius_ceiling_m"]) and float(stats["min_height_m"]) >= 0.0 and float(stats["max_height_m"]) <= 0.20, "actual smoke vertices remain inside the fixed circle and low height: " + view["label"])
		var geometry: Dictionary = level.call("bank_geometry")
		var intersects: bool = Geometry.segment_hits(geometry, hero.global_position, hero.global_position, actor_radius)
		_expect(intersects == view["overlap"] and hero.is_on_floor(), "actual supported stage position has the declared static circle occupancy: " + view["label"])
		var state: Dictionary = cue.call("state")
		_expect(state["phase"] == view["phase"] and state["geometry"]["kind"] == "circle" and float(state["geometry"]["radius"]) == 1.05 and state["source_position"] == source.global_position and state["source_visible"] and state["footprint_visible"] == (view["phase"] != "recovery") and state["active_fill_visible"] == (view["phase"] == "active"), "shared cue owns its unchanged circle/source/phase glyphs: " + view["label"])
		_expect(source.global_transform == source_home and tender.global_transform == tender_home and not smoke.is_processing() and not smoke.is_physics_processing(), "cosmetic poses keep native origins fixed and have no autonomous processing: " + view["label"])
		var before: Array[Dictionary] = _parcel_pose(smoke)
		_expect(smoke.call("pose", view["phase"], view["p"]) and _parcel_pose(smoke) == before, "quiet same-pose reconstruction retains exact transforms and alpha: " + view["label"])
		var policies: Array[Dictionary] = _material_policy(smoke)
		var policies_ok: bool = policies.size() == 9
		for policy: Dictionary in policies:
			policies_ok = policies_ok and policy["alpha"] <= native_max_alpha and policy["priority"] < 0 and not policy["no_depth_test"] and policy["depth_draw_mode"] == BaseMaterial3D.DEPTH_DRAW_DISABLED and policy["transparency"] == BaseMaterial3D.TRANSPARENCY_ALPHA
		_expect(policies_ok, "native smoke alpha stays isolated below cues with depth tests and no depth writes: " + view["label"])
		_expect(hero.hp == hp_before and hero.get_world_action_records().is_empty() and not level.is_completed() and level.current_checkpoint()["id"].is_empty(), "cosmetic view credits no action, damage or progression: " + view["label"])
		var framing: String = _game.call("camera_framing_error", level.camera_framing_points())
		_expect(framing.is_empty(), "actual camera contains full circle, source, Tender and Hero bounds: " + view["label"] + ": " + framing)
		await RenderingServer.frame_post_draw
		var picture: Image = root.get_texture().get_image()
		var image_path: String = _capture_root + view["label"] + ".png"
		_expect(picture != null and picture.get_size() == Vector2i(540, 1170) and picture.save_png(image_path) == OK, "native540x1170 smoke frame saved: " + view["label"])
		var world_quad: Array = []
		var screen_quad: Array = []
		for point: Vector3 in hero_bounds:
			world_quad.append(_vector(point))
			var screen: Vector2 = camera.unproject_position(point)
			screen_quad.append([screen.x, screen.y])
		records.append({"label": view["label"], "phase": view["phase"], "normalized_progress": view["p"], "hero_fixture_position": _vector(hero.global_position), "hero_hp": hero.hp, "hero_on_floor": hero.is_on_floor(), "hero_capsule_radius": actor_radius, "static_circle_occupancy": intersects, "requested_overlap_fixture": view["overlap"], "bank_origin": _vector(source.global_position), "tender_origin": _vector(tender.global_position), "native_geometry_stats": stats, "materials": policies, "native_material_alpha_ceiling": native_max_alpha, "shared_cue": _cue_json(state), "hero_billboard_world": world_quad, "hero_billboard_viewport_pixels": screen_quad, "tender_readability": tender.call("readability_state"), "scenery_cutaway_applied": false, "scenery_cutaway_available_paths": kit_root.get_meta("optional_cutaway_paths", []).size(), "smoke_readability_fade_applied": false, "camera_position": _vector(camera.global_position), "camera_width": camera.size, "camera_viewport_size": [camera.get_viewport().size.x, camera.get_viewport().size.y], "camera_framing_error": framing, "image": image_path, "image_sha256": FileAccess.get_sha256(image_path), "scope": "TEST ONLY stage placed Hero and cosmetic fixed-circle shared cue; no Scheduler admission/damage/grace/ticks/route/input/save/fairness claim"})
		print("L3 smoke cosmetic capture: " + view["label"])
	_expect(records.size() == 5, "exact five requested cosmetic image records")
	_expect(smoke.call("pose", "recovery", 1.0) and _visible_parcels(smoke) == 0, "supplied recovery completion hides the finite vapour without any timer")
	_expect(cue.call("clear") and smoke.call("pose", "spent", 1.0) and _visible_parcels(smoke) == 0, "shared clear and cosmetic spent are quiet and collisionless")
	var old_nodes: Array[WeakRef] = [weakref(level), weakref(source), weakref(smoke), weakref(tender), weakref(cue), weakref(kit_root)]
	_expect(_game.call("request_pause_deferred"), "actual supported deferred pause request before subtree cleanup")
	for ignored: int in range(3):
		await process_frame
	_expect(paused and not _game.call("is_pause_requested"), "full native deferred pause barrier settles before level exit")
	level.exit_level()
	_game.get("fx").clear()
	paused = false
	await create_timer(0.15).timeout
	_game.queue_free()
	await _settle(3)
	var freed: bool = true
	for reference: WeakRef in old_nodes:
		freed = freed and reference.get_ref() == null
	_expect(freed and get_nodes_in_group("required_cues").is_empty() and get_nodes_in_group("enemies").is_empty(), "actual Hero/cue/scenery source subtree releases with no dangling required cue")
	var file := FileAccess.open(_capture_root + "metadata.json", FileAccess.WRITE)
	_expect(file != null, "five-frame metadata and final check counts opened")
	if file != null:
		file.store_string(JSON.stringify({"scope": "TEST ONLY cosmetic smoke/cue previews with actual shared Game/Hero/camera/Act2 skin and production floor/kit; no actual bank consumer/reservation/damage/route/transport acceptance", "fixture": PreviewPath, "frame_count": records.size(), "checks": _checks, "failures": _failures, "frames": records}, "  ") + "\n")
		file.close()
	print("A2-L3 native smoke asset capture: %d checks, %d failures;5 cosmetic frames, no consumer/gameplay/fairness claim" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _vector(value: Vector3) -> Array:
	return [value.x, value.y, value.z]


func _cue_json(state: Dictionary) -> Dictionary:
	var shape: Dictionary = state["geometry"]
	return {"api_revision": state["api_revision"], "phase": state["phase"], "geometry": {"kind": shape["kind"], "origin": _vector(shape["origin"]), "radius": shape["radius"]}, "source_position": _vector(state["source_position"]), "required": state["required"], "source_visible": state["source_visible"], "footprint_visible": state["footprint_visible"], "active_fill_visible": state["active_fill_visible"], "no_reservation_or_damage_authority": true}


func _parcel_pose(smoke: Node3D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for child: Node in smoke.get_children():
		var part := child as MeshInstance3D
		if part != null:
			result.append({"name": str(part.name), "transform": part.transform, "visible": part.visible, "tint": (part.material_override as StandardMaterial3D).albedo_color})
	return result


func _material_policy(smoke: Node3D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for child: Node in smoke.get_children():
		var part := child as MeshInstance3D
		if part == null:
			continue
		var material := part.material_override as StandardMaterial3D
		result.append({"parcel": str(part.name), "alpha": material.albedo_color.a, "priority": material.render_priority, "no_depth_test": material.no_depth_test, "depth_draw_mode": material.depth_draw_mode, "transparency": material.transparency})
	return result


func _visible_parcels(smoke: Node3D) -> int:
	var result: int = 0
	for child: Node in smoke.get_children():
		if child is MeshInstance3D and child.visible:
			result += 1
	return result


func _settle(count: int) -> void:
	for ignored: int in range(count):
		await physics_frame
	await process_frame


func _expect(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("FAIL: " + label)
