extends SceneTree
## Quiet native art views; real viewport-routed swipes, no native-OS claim.
## TEST ONLY whole-tree draw freeze preserves the ordinary HUD and camera.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const ROOM: String = "res://scenes/acts/act3/a3_l3_shore_modules_preview.tscn"
const OUTPUT: String = "res://.cinder/mirror-shore-modules-portraits"

class Barrier extends Node:
	signal observed
	var waiting: bool = false
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 1000
	func _physics_process(_delta: float) -> void:
		if waiting:
			waiting = false
			observed.emit()

var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _scenery: Node3D
var _modules: Node3D
var _floor: StaticBody3D
var _barrier: Barrier
var _metadata: Dictionary = {}
var _native_modules: Dictionary = {}
var _kit: Dictionary = {}
var _resources: Array = []
var _events: Array[String] = []
var _checks: int = 0
var _failures: int = 0
var _captures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not _expect(DisplayServer.get_name() != "headless" and OS.get_cmdline_user_args().is_empty(), "quiet module portraits require native graphical rendering and no unsupported selector"):
		await _finish()
		return
	if not _open() or not await _settle(0.8):
		await _finish()
		return
	if not await _capture("01-centre") or not await _swipe(Vector3.LEFT) or not await _settle(0.8) or not await _capture("02-left"):
		await _finish()
		return
	# Actual flank landings expose the raised off-floor pieces in the close camera.
	if not await _swipe(Vector3.LEFT) or not await _settle(0.8) or not await _capture("03-left-flank"):
		await _finish()
		return
	# Three genuine right dashes pass through centre to the near right view.
	for _i: int in range(3):
		if not await _swipe(Vector3.RIGHT) or not await _settle(0.8):
			await _finish()
			return
	if not await _capture("04-right") or not await _swipe(Vector3.RIGHT) or not await _settle(0.8) or not await _capture("05-right-flank"):
		await _finish()
		return
	_expect(_captures == 5 and _hero.get_world_action_records().size() == 6 and _events.count("fired_dash") == 6 and _live_error().is_empty(), "five actual native views use exactly six ordinary dashes with unchanged native module identities and resources")
	await _finish()


func _open() -> bool:
	paused = false
	_game = MainScene.instantiate()
	_game.set("level_scene_path", ROOM)
	root.add_child(_game)
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _expect(_level != null and _hero != null and _level.scene_file_path == ROOM and _level.contract_error().is_empty(), "actual Main installs the independent quiet module court"):
		return false
	_scenery = _level.get("scenery") as Node3D
	_modules = _level.get("modules") as Node3D
	_floor = _scenery.get("floor_body") as StaticBody3D if _scenery != null else null
	_barrier = Barrier.new()
	root.add_child(_barrier)
	if not _expect(_modules != null and _floor != null and String(_level.call("runtime_error")).is_empty(), "actual unchanged shore and newly authored module builder are present"):
		return false
	_metadata = _modules.call("state")
	_native_modules = _node_state(_modules)
	_kit = _hero.equipment.snapshot()
	_resources = [_hero.hp, _hero.shells]
	_hero.fired.connect(func(kind: String) -> void: _events.append("fired_" + kind))
	_hero.died.connect(func() -> void: _events.append("hero_death"))
	_hero.equipment_changed.connect(func(_id: String) -> void: _events.append("equipment"))
	_level.completion_requested.connect(func(_a: String, _b: String) -> void: _events.append("completion"))
	_level.checkpoint_requested.connect(func(_a: String, _b: String, _c: String) -> void: _events.append("checkpoint"))
	_level.contact_exit_requested.connect(func(_a: String, _b: String) -> void: _events.append("exit"))
	var solid: CollisionShape3D = _floor.get_node_or_null("Solid") as CollisionShape3D
	return _expect(_hero.presentation_id == "act3_traveller" and _hero.global_position == _level.spawn_position() and _hero.get_world_action_records().is_empty() and solid != null and solid.shape is BoxShape3D and (solid.shape as BoxShape3D).size == Vector3(14, 1, 22) and _module_error().is_empty(), "shared default traveller enters the actual14-by22 floor beside32 render-only native pieces", _module_error())


func _tick() -> bool:
	if paused:
		return _expect(false, "quiet route cannot advance a paused unit")
	_barrier.waiting = true
	await _barrier.observed
	var error: String = _live_error()
	return true if error.is_empty() else _expect(false, "actual quiet route preserves the native unit", error)


func _settle(seconds: float) -> bool:
	var deadline: float = _hero.get_world_action_clock() + seconds
	for _i: int in range(int(ceilf(seconds * float(Engine.physics_ticks_per_second))) + 90):
		var response: Dictionary = _hero.get_threat_response_state()
		if _hero.get_world_action_clock() >= deadline and response.stable and float(response.dash_cooldown_left_s) == 0.0:
			await process_frame # Ordinary public HUD/camera update follows actor.
			return _expect(_live_error().is_empty(), "real shared Hero/camera settle without resource changes", _live_error())
		if not await _tick():
			return false
	return _expect(false, "bounded real quiet settling deadline")


func _swipe(direction: Vector3) -> bool:
	var before: Vector3 = _hero.global_position
	var prior: Array[Dictionary] = _hero.get_world_action_records()
	var sequence: int = 0 if prior.is_empty() else int(prior.back().sequence)
	var size: Vector2 = root.get_visible_rect().size
	var start: Vector2 = size * Vector2(0.5, 0.6)
	var finish: Vector2 = start + Vector2(direction.x, 0) * size.x * 0.22
	var press := InputEventScreenTouch.new()
	press.index = 7
	press.pressed = true
	press.position = start
	root.push_input(press, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 7
	drag.position = finish
	drag.relative = finish - start
	root.push_input(drag, true)
	var release := InputEventScreenTouch.new()
	release.index = 7
	release.position = finish
	release.pressed = false
	root.push_input(release, true)
	var records: Array[Dictionary] = []
	for _i: int in range(90):
		records = _hero.get_world_action_records(sequence)
		if not records.is_empty():
			break
		if not await _tick():
			return false
	var expected: Vector3 = before + direction * float(_hero.equipment.resolved_stats().dash_distance)
	var input: Dictionary = _game.call("get_input_observation_state")
	if not _expect(records.size() == 1 and records[0].kind == "dash" and not records[0].blocked and not records[0].collision_shortened and (records[0].world_origin as Vector3).distance_to(before) < 0.005 and (records[0].landing as Vector3).distance_to(expected) < 0.005 and _hero.global_position.distance_to(expected) < 0.005 and _exact(records[0].equipment_ids, _kit), "one real unshortened ordinary viewport dash reaches its actual carried-kit landing", str(records)):
		return false
	return _expect(_game.call("get_aim_anchor_normalized") == finish / size and input.last_observation.kind == "swipe_release" and input.last_observation.anchor_normalized == finish / size, "actual final release point remains the shared exact aim anchor")


func _capture(label: String) -> bool:
	var previous: bool = paused
	paused = true # TEST ONLY complete postactor draw freeze; normal HUD retained.
	var before: Dictionary = _observation()
	var error: String = ""
	if before.pair.hero.is_empty() or before.pair.level.is_empty():
		error = "Quiet paired snapshot unavailable: " + _hero.last_snapshot_error + "; " + _level.last_snapshot_error
	if error.is_empty():
		await process_frame
		await RenderingServer.frame_post_draw
		error = String(_game.call("camera_framing_error", _level.camera_framing_points()))
		if error.is_empty() and not _exact(before, _observation()):
			error = "Whole paused native Hero/local/input/camera/HUD/scenery/modules changed during draw"
		if error.is_empty():
			error = _live_error()
		var image: Image = root.get_texture().get_image() if error.is_empty() else null
		if error.is_empty() and (image == null or image.is_empty() or image.get_size() != Vector2i(339, 736)):
			error = "Actual image must be339x736; got " + str(image.get_size() if image != null else Vector2i.ZERO)
		if error.is_empty():
			var directory: String = ProjectSettings.globalize_path(OUTPUT)
			if DirAccess.make_dir_recursive_absolute(directory) != OK or image.save_png(directory.path_join(label + ".png")) != OK:
				error = "Could not save unchanged native quiet portrait"
			else:
				_captures += 1
				print("QUIET MODULE PORTRAIT: ", directory.path_join(label + ".png"), "; actualHero=", _hero.global_position, "; anchor=", _game.call("get_aim_anchor_normalized"))
	paused = previous
	return _expect(error.is_empty(), "actual native339x736 " + label + " portrait freezes the complete public unit", error)


func _observation() -> Dictionary:
	var camera: Camera3D = _game.get("camera") as Camera3D
	return {"pair": {"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}, "actions": _hero.get_world_action_records(), "resources": [_hero.hp, _hero.shells], "kit": _hero.equipment.snapshot(), "input": _game.call("get_input_observation_state"), "anchor": _game.call("get_aim_anchor_normalized"), "camera": [camera.global_transform, camera.projection, camera.size, camera.keep_aspect, camera.h_offset, camera.v_offset], "scenery": _node_state(_scenery), "modules": _node_state(_modules), "metadata": _modules.call("state"), "hud": _node_state(_game.get("hud") as Node), "events": _events.duplicate(), "viewport": root.size}


func _node_state(node: Node) -> Dictionary:
	var result: Dictionary = {"name": String(node.name), "instance_id": node.get_instance_id(), "children": []}
	if node is Node3D:
		result.pose = [(node as Node3D).transform, (node as Node3D).global_transform, (node as Node3D).visible]
	if node is CanvasItem:
		result.visible = (node as CanvasItem).visible
	if node is Control:
		result.rect = (node as Control).get_global_rect()
	if node is Label:
		result.text = (node as Label).text
	if node is Button:
		result.text = (node as Button).text
	if node is MeshInstance3D:
		var mesh: MeshInstance3D = node as MeshInstance3D
		result.resources = [mesh.mesh.get_instance_id() if mesh.mesh != null else 0, mesh.material_override.get_instance_id() if mesh.material_override != null else 0]
		result.mesh_bounds = mesh.mesh.get_aabb() if mesh.mesh != null else AABB()
		if mesh.material_override is StandardMaterial3D:
			var material: StandardMaterial3D = mesh.material_override as StandardMaterial3D
			result.material = [material.albedo_color, material.shading_mode, material.vertex_color_use_as_albedo, material.texture_filter, material.transparency, material.depth_draw_mode, material.no_depth_test, material.emission_enabled, material.billboard_mode, material.cull_mode, material.render_priority]
		if mesh.mesh is ArrayMesh:
			result.native_arrays = (mesh.mesh as ArrayMesh).surface_get_arrays(0)
	for child: Node in node.get_children():
		result.children.append(_node_state(child))
	return result


func _module_error() -> String:
	if not is_instance_valid(_modules) or _modules.get_child_count() != 32 or not _exact(_metadata, _modules.call("state")) or not _exact(_native_modules, _node_state(_modules)) or _modules.global_transform != Transform3D.IDENTITY or _modules.is_processing() or _modules.is_physics_processing() or not _modules.get_groups().is_empty():
		return "Quiet modules must retain their32 immutable nonprocessing court pieces"
	for child: Node in _modules.get_children():
		var view: MeshInstance3D = child as MeshInstance3D
		if view == null or view.get_child_count() != 0 or not view.get_groups().is_empty() or view.has_method("take_damage") or not view.mesh is ArrayMesh or (view.mesh as ArrayMesh).get_surface_count() != 1 or not view.is_visible_in_tree() or view.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			return "Module piece acquired unsupported mesh/group/collision/gameplay state"
		var material: StandardMaterial3D = view.material_override as StandardMaterial3D
		if material == null or material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or not material.vertex_color_use_as_albedo or material.albedo_color != Color.WHITE or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.no_depth_test or material.depth_draw_mode != BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY or material.emission_enabled or material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED or material.cull_mode != BaseMaterial3D.CULL_DISABLED or material.render_priority != 0 or view.material_overlay != null:
			return "Native module material must remain opaque nearest/unshaded with ordinary depth/no emission"
		var described: bool = false
		for piece: Dictionary in _metadata.pieces:
			if piece.id == String(view.name):
				described = true
				var arrays: Array = (view.mesh as ArrayMesh).surface_get_arrays(0)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
				if vertices.is_empty() or vertices.size() % 3 != 0 or vertices.size() != piece.vertex_count or colors.size() != vertices.size() or (view.mesh as ArrayMesh).surface_get_primitive_type(0) != Mesh.PRIMITIVE_TRIANGLES:
					return "Native surface requires positive complete triangles/equal color count and exact authored vertex count"
				for vertex: Vector3 in vertices:
					var point: Vector3 = view.global_transform * vertex
					if not point.is_finite() or point.y < 0.0:
						return "Native module surface lost finite grounded authored geometry"
					if piece.raised and absf(point.x) <= 7.3:
						return "Actual raised native vertex entered the protected safe-floor width"
					if not piece.raised and (absf(point.x) >= 7.0 or absf(point.z) >= 11.0 or point.y > Vector3(0, 0.014, 0).y):
						return "Actual flat native dressing left the floor or exceeded its14mm top"
				for color: Color in colors:
					if color.a != 1.0:
						return "Native module vertex colors must stay opaque"
				break
		if not described:
			return "Native module piece has no stable authored metadata"
	return ""


func _live_error() -> String:
	if not is_instance_valid(_hero) or not is_instance_valid(_level) or not is_instance_valid(_floor):
		return "Quiet preview lost actual Hero/level/floor"
	var error: String = _level.call("runtime_error")
	if not error.is_empty():
		return error
	if _hero.dead or not _exact(_resources, [_hero.hp, _hero.shells]) or not _exact(_kit, _hero.equipment.snapshot()):
		return "Quiet preview changed actual HP/ammo/default equipment"
	var ray := PhysicsRayQueryParameters3D.create(_hero.global_position + Vector3.UP * 0.25, _hero.global_position - Vector3.UP * 0.25, 1)
	if _hero.get_world_3d().direct_space_state.intersect_ray(ray).get("collider") != _floor:
		return "Actual Hero no longer stands over the unchanged continuous floor"
	if _level.is_completed() or _level.current_checkpoint() != {"id": "", "kind": ""} or int(_game.get("cores")) != 0 or int(_game.get("kills")) != 0:
		return "Quiet preview acquired progress/reward"
	for event: String in _events:
		if event != "fired_dash":
			return "Quiet preview emitted a combat/resource/progression event: " + event
	for group: String in ["enemies", "practice_targets", "lab_weapons", "required_cues"]:
		if not get_nodes_in_group(group).is_empty():
			return "Quiet preview contains combat/interaction/cue group " + group
	return _module_error()


func _exact(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	if a is Dictionary:
		if a.size() != b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _exact(a[key], b[key]): return false
		return true
	if a is Array:
		if a.size() != b.size(): return false
		for i: int in range(a.size()):
			if not _exact(a[i], b[i]): return false
		return true
	if typeof(a) not in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_VECTOR3, TYPE_VECTOR3I, TYPE_RECT2, TYPE_RECT2I, TYPE_COLOR, TYPE_BASIS, TYPE_TRANSFORM3D, TYPE_AABB, TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_COLOR_ARRAY]:
		return false
	return var_to_bytes(a) == var_to_bytes(b) # Native type/float bits, fail closed.


func _finish() -> void:
	var old: WeakRef = weakref(_game) if is_instance_valid(_game) else null
	if is_instance_valid(_level): _level.exit_level()
	if is_instance_valid(_game): _game.queue_free()
	if is_instance_valid(_barrier): _barrier.queue_free()
	paused = false
	for _i: int in range(5): await process_frame
	if old != null:
		_expect(old.get_ref() == null and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "quiet actual world retires cleanly")
	await create_timer(0.15, true, false, true).timeout
	print("Quiet shore module portraits: %d checks; %d failures; %d images. Art/occlusion remain manual review, no L3 acceptance." % [_checks, _failures, _captures])
	quit(0 if _failures == 0 else 1)


func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	if ok: print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok
