extends SceneTree
## Four quiet native portraits, with real shared Hero and routed viewport input.
## Direct tree pause is a TEST ONLY capture freeze: no pause panel is requested
## or hidden. No actor pose/clock/resource writes, save, combat or reward.
## Automated viewport gestures are not native OS/human input or L3 acceptance.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const ArtPath: String = "res://scenes/acts/act3/a3_l3_irontick_art_preview.tscn"
const CapturePath: String = "res://.cinder/mirror-irontick-art-portraits"
const NativeSize: Vector2i = Vector2i(339, 736)
const PointTolerance: float = 0.005

class PostActorBarrier:
	extends Node
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
var _hero: CinderPlayer
var _level: CinderLevel
var _scenery: Node3D
var _witnesses: Node3D
var _floor: StaticBody3D
var _barrier: PostActorBarrier
var _events: Dictionary = {}
var _checks: int = 0
var _failures: int = 0
var _captures: int = 0
var _kit: Dictionary = {}
var _hp: float = 0.0
var _shells: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not _expect(OS.get_cmdline_user_args().is_empty() and DisplayServer.get_name() != "headless", "quiet portraits require the graphical native viewport and no unsupported selectors"):
		await _finish()
		return
	paused = false
	_game = MainScene.instantiate()
	_game.set("level_scene_path", ArtPath)
	root.add_child(_game)
	_hero = _game.get("player") as CinderPlayer
	_level = _game.get("active_level") as CinderLevel
	if not _expect(_hero != null and _level != null and _level.level_id == "A3-L3" and _level.scene_file_path == ArtPath and _level.contract_error().is_empty(), "actual MainScene loads the independent A3-L3 quiet art preview"):
		await _finish()
		return
	_scenery = _level.get("scenery") as Node3D
	_witnesses = _level.get("witnesses") as Node3D
	_floor = _scenery.get("floor_body") as StaticBody3D if _scenery != null else null
	_barrier = PostActorBarrier.new()
	root.add_child(_barrier)
	_kit = _hero.equipment.snapshot()
	_hp = _hero.hp
	_shells = _hero.shells
	var solid: CollisionShape3D = _floor.get_node_or_null("Solid") as CollisionShape3D if _floor != null else null
	if not _expect(solid != null and solid.shape is BoxShape3D and (solid.shape as BoxShape3D).size == Vector3(14, 1, 22), "quiet art uses the actual room-mode continuous14-by22 firm shore collider"):
		await _finish()
		return
	_hero.fired.connect(func(kind: String) -> void: _event("fired_" + kind))
	_hero.died.connect(func() -> void: _event("hero_death"))
	_hero.equipment_changed.connect(func(_id: String) -> void: _event("equipment"))
	_level.completion_requested.connect(func(_a: String, _b: String) -> void: _event("completion"))
	_level.checkpoint_requested.connect(func(_a: String, _b: String, _c: String) -> void: _event("checkpoint"))
	_level.contact_exit_requested.connect(func(_a: String, _b: String) -> void: _event("exit"))
	if not _expect(_hero.presentation_id == "act3_traveller" and _hero.global_position == _level.spawn_position() and _hero.get_world_action_records().is_empty(), "shared traveller starts at the actual authored spawn without fabricated history"):
		await _finish()
		return
	var error: String = await _settle(1.0)
	if not _expect(error.is_empty() and _cast_error().is_empty(), "actual traveller settles on firm shore beside one static lake/figure vignette", error + _cast_error()):
		await _finish()
		return
	for sun: int in [0, 1]:
		error = await _capture("%02d-centred-sun%d" % [sun + 1, sun], sun)
		if not _expect(error.is_empty(), "centred actual sun%d native portrait freezes the complete public unit" % sun, error):
			await _finish()
			return
	error = await _swipe_left()
	if not _expect(error.is_empty(), "one routed public LEFT swipe completes its actual ordinary dash and retains release anchor", error):
		await _finish()
		return
	error = await _settle(1.0)
	if not _expect(error.is_empty(), "ordinary lateral dash and following camera settle without resource or progression changes", error):
		await _finish()
		return
	for sun: int in [0, 1]:
		error = await _capture("%02d-lateral-left-sun%d" % [sun + 3, sun], sun)
		if not _expect(error.is_empty(), "lateral actual sun%d native portrait freezes the complete public unit" % sun, error):
			await _finish()
			return
	_expect(_captures == 4 and _hero.get_world_action_records().size() == 1 and _events.get("fired_dash", 0) == 1, "four native lake views contain only the genuine routed dash; no fabricated combat or interaction")
	await _finish()


func _tick() -> String:
	if paused or not is_instance_valid(_barrier):
		return "Quiet simulation observation requires its running post-actor boundary"
	_barrier.waiting = true
	await _barrier.observed
	return _live_error()


func _settle(seconds: float) -> String:
	var target: float = _hero.get_world_action_clock() + seconds
	for _i: int in range(int(ceilf(seconds * float(Engine.physics_ticks_per_second))) + 8):
		if _hero.get_world_action_clock() >= target and _hero.get_threat_response_state().stable:
			await process_frame # Actual HUD/camera frame follows the settled Hero.
			return _live_error()
		var error: String = await _tick()
		if not error.is_empty():
			return error
	return "Quiet traveller did not settle within the explicit finite simulation bound"


func _swipe_left() -> String:
	var before: Vector3 = _hero.global_position
	var history: Array[Dictionary] = _hero.get_world_action_records()
	var sequence: int = 0 if history.is_empty() else int(history.back().sequence)
	var size: Vector2 = root.get_visible_rect().size
	var start: Vector2 = size * Vector2(0.5, 0.60)
	var finish: Vector2 = size * Vector2(0.28, 0.60)
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
	release.pressed = false
	release.position = finish
	root.push_input(release, true)
	var stats: Dictionary = _hero.equipment.resolved_stats()
	var records: Array[Dictionary] = []
	for _i: int in range(int(ceilf((float(stats.dash_duration) + 0.3) * float(Engine.physics_ticks_per_second))) + 8):
		records = _hero.get_world_action_records(sequence)
		if not records.is_empty():
			break
		var error: String = await _tick()
		if not error.is_empty():
			return error
	if records.size() != 1:
		return "Routed left swipe failed to publish exactly one completed action"
	var action: Dictionary = records[0]
	var camera: Camera3D = _game.get("camera") as Camera3D
	var direction: Vector3 = -camera.global_basis.x
	direction.y = 0.0
	direction = direction.normalized()
	var expected: Vector3 = before + direction * float(stats.dash_distance)
	if action.kind != "dash" or action.get("blocked") != false or action.get("collision_shortened") != false or not _exact(action.equipment_ids, _kit) or (action.world_origin as Vector3).distance_to(before) > PointTolerance or (action.landing as Vector3).distance_to(expected) > PointTolerance or _hero.global_position.distance_to(expected) > PointTolerance:
		return "Actual routed dash origin, direction, distance or unshortened landing differs"
	var observer: Dictionary = _game.call("get_input_observation_state")
	if _game.call("get_aim_anchor_normalized") != finish / size or observer.last_observation.get("kind") != "swipe_release" or observer.last_observation.anchor_normalized != finish / size:
		return "Routed left swipe did not preserve its exact final viewport release anchor"
	print("QUIET ACTUAL SWIPE: ", {"input_rect": root.get_visible_rect(), "start": start, "release": finish, "action": action, "hero": _hero.global_position})
	return ""


func _capture(label: String, sun: int) -> String:
	var was_paused: bool = paused
	paused = true # TEST ONLY direct complete-boundary freeze; no UI method.
	var error: String = ""
	if not _level.call("set_sun_presentation", sun):
		error = "Actual quiet scenery rejected its public stable sun presentation"
	var before: Dictionary = _observation()
	if error.is_empty() and (before.pair.hero.is_empty() or before.pair.level.is_empty()):
		error = "Quiet paired capture rejected: " + _hero.last_snapshot_error + "; " + _level.last_snapshot_error
	if error.is_empty():
		await process_frame
		await RenderingServer.frame_post_draw
		var bounds: Dictionary = _level.call("art_framing_points")
		error = String(bounds.error)
		if error.is_empty():
			error = String(_game.call("camera_framing_error", bounds.points))
		if error.is_empty() and not _exact(before, _observation()):
			error = "Native render freeze changed paired Hero/local state, clocks/resources, input/anchor, camera, scenery/cast poses or UI visibility"
		if error.is_empty():
			error = _live_error()
		var actual: Image = root.get_texture().get_image() if error.is_empty() else null
		if error.is_empty() and (actual == null or actual.is_empty() or actual.get_size() != NativeSize):
			error = "Unchanged native portrait must be339x736; actual=" + str(actual.get_size() if actual != null else Vector2i.ZERO)
		if error.is_empty():
			var directory: String = ProjectSettings.globalize_path(CapturePath)
			if DirAccess.make_dir_recursive_absolute(directory) != OK or actual.save_png(directory.path_join(label + ".png")) != OK:
				error = "Cannot save unchanged quiet native portrait"
			else:
				_captures += 1
				print("QUIET IRONTICK PORTRAIT: ", directory.path_join(label + ".png"), "; native=", actual.get_size(), "; sun=", _level.call("state"), "; hero=", _hero.global_position, "; anchor=", _game.call("get_aim_anchor_normalized"), "; required complete native lake/figure enclosure corners=", bounds.points.size(), "; TEST_ONLY direct pause/no panel request")
	paused = was_paused
	return error


func _observation() -> Dictionary:
	var camera: Camera3D = _game.get("camera") as Camera3D
	return {"pair": {"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}, "camera_transform": camera.global_transform, "camera_projection": [camera.projection, camera.keep_aspect, camera.size, camera.h_offset, camera.v_offset], "input": _game.call("get_input_observation_state"), "anchor": _game.call("get_aim_anchor_normalized"), "resources": [_hero.hp, _hero.shells], "actions": _hero.get_world_action_records(), "scenery": _node_observation(_scenery), "cast": _node_observation(_witnesses), "ui": _node_observation(_game.get("hud") as Node), "events": _events.duplicate(true), "viewport_size": root.size}


func _node_observation(node: Node) -> Dictionary:
	var result: Dictionary = {"name": String(node.name), "children": []}
	if node is Node3D:
		result.transform = (node as Node3D).transform
		result.global_transform = (node as Node3D).global_transform
		result.visible = (node as Node3D).visible
	if node is CanvasItem:
		result.visible = (node as CanvasItem).visible
	if node is Sprite3D:
		var sprite: Sprite3D = node as Sprite3D
		result.sprite = [sprite.offset, sprite.pixel_size, sprite.frame, sprite.flip_h, sprite.flip_v, sprite.alpha_cut, sprite.alpha_scissor_threshold, sprite.billboard, sprite.modulate, sprite.texture.get_instance_id()]
		var atlas: AtlasTexture = sprite.texture as AtlasTexture
		if atlas != null:
			result.atlas = [atlas.region, atlas.margin, atlas.filter_clip, atlas.atlas.get_instance_id()]
	if node is MeshInstance3D:
		var mesh: MeshInstance3D = node as MeshInstance3D
		result.mesh = mesh.mesh.get_instance_id() if mesh.mesh != null else 0
		result.material = mesh.material_override.get_instance_id() if mesh.material_override != null else 0
		if mesh.material_override is StandardMaterial3D:
			var material: StandardMaterial3D = mesh.material_override as StandardMaterial3D
			result.material_pose = [material.albedo_color, material.transparency, material.no_depth_test, material.billboard_mode]
	for child: Node in node.get_children():
		result.children.append(_node_observation(child))
	return result


func _cast_error() -> String:
	if not is_instance_valid(_witnesses) or _witnesses.get_child_count() != 31:
		return "Quiet lake/figure must retain exactly31 native mesh children"
	var nodes: Array[Node] = [_witnesses]
	for child: Node in _witnesses.find_children("*", "", true, false):
		nodes.append(child)
	for node: Node in nodes:
		if node is CollisionObject3D or node is CollisionShape3D or not node.get_groups().is_empty() or node.has_method("take_damage") or node.has_method("collect") or node.has_method("interact"):
			return "Quiet lake/figure acquired collision, target membership or interaction"
		for property: Dictionary in node.get_property_list():
			if property.name == "hp":
				return "Quiet lake/figure acquired an HP target property"
	for child: Node in _witnesses.get_children():
		if not child is MeshInstance3D:
			return "Quiet vignette acquired a non-mesh child"
	var geometry: Dictionary = _witnesses.call("native_geometry_state")
	if not String(geometry.get("error", "")).is_empty() or not _floor_hit(geometry.earthrid_sole):
		return "Actual Earthrid sole is not above the original dry floor"
	var water: AABB = geometry.water_bounds
	var rim: AABB = geometry.rim_bounds
	if water.end.z >= -11.0 or rim.end.z >= -11.0:
		return "Actual scenic lake/rim entered the permanent dry floor"
	return String(_witnesses.call("runtime_error"))


func _floor_hit(point: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.25, point - Vector3.UP * 0.25, 1)
	var hit: Dictionary = _hero.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == _floor


func _live_error() -> String:
	if not is_instance_valid(_hero) or not is_instance_valid(_level) or not is_instance_valid(_floor):
		return "Quiet fixture requires actual live Hero/level/floor"
	var error: String = String(_level.call("runtime_error"))
	if not error.is_empty():
		return error
	if _hero.dead or _hero.hp != _hp or _hero.shells != _shells or not _exact(_hero.equipment.snapshot(), _kit):
		return "Quiet art fixture changed actual health/ammo/equipment"
	if not _floor_hit(_hero.global_position):
		return "Actual quiet traveller left the authored dry floor"
	if _level.is_completed() or _level.current_checkpoint() != {"id": "", "kind": ""} or int(_game.get("cores")) != 0 or int(_game.get("kills")) != 0:
		return "Quiet fixture generated progression, checkpoint or reward"
	for key: String in ["hero_death", "equipment", "completion", "checkpoint", "exit", "fired_slash", "fired_blast"]:
		if int(_events.get(key, 0)) != 0:
			return "Quiet fixture emitted gameplay event " + key
	for group: String in ["enemies", "practice_targets", "lab_weapons"]:
		if not get_nodes_in_group(group).is_empty():
			return "Quiet art preview contains combat/lab group " + group
	if _visible_pause_label(_game.get("hud") as Node):
		return "Quiet capture unexpectedly shows the actual public pause panel"
	return _cast_error()


func _visible_pause_label(node: Node) -> bool:
	if node is Label and (node as Label).text == "PAUSED" and (node as Label).is_visible_in_tree():
		return true
	for child: Node in node.get_children():
		if _visible_pause_label(child):
			return true
	return false


func _event(kind: String) -> void:
	_events[kind] = int(_events.get(kind, 0)) + 1


func _exact(left: Variant, right: Variant) -> bool:
	if typeof(left) != typeof(right):
		return false
	if left is float:
		var a := PackedByteArray()
		var b := PackedByteArray()
		a.resize(8)
		b.resize(8)
		a.encode_double(0, left)
		b.encode_double(0, right)
		return a == b
	if left is Dictionary:
		if left.size() != right.size():
			return false
		for key: Variant in left:
			if not right.has(key) or not _exact(left[key], right[key]):
				return false
		return true
	if left is Array:
		if left.size() != right.size():
			return false
		for index: int in range(left.size()):
			if not _exact(left[index], right[index]):
				return false
		return true
	return left == right


func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	if ok:
		print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok


func _finish() -> void:
	var game_ref: WeakRef = weakref(_game) if is_instance_valid(_game) else null
	var cast_ref: WeakRef = weakref(_witnesses) if is_instance_valid(_witnesses) else null
	if is_instance_valid(_level):
		_level.exit_level()
	if is_instance_valid(_barrier):
		_barrier.waiting = false
		root.remove_child(_barrier)
		_barrier.queue_free()
	if is_instance_valid(_game):
		root.remove_child(_game)
		_game.queue_free()
	paused = false
	for _i: int in range(5):
		await process_frame
	_expect((game_ref == null or game_ref.get_ref() == null) and (cast_ref == null or cast_ref.get_ref() == null) and get_nodes_in_group("enemies").is_empty(), "quiet preview retirement frees actual scenery/cast without target remnants")
	await create_timer(0.15, true, false, true).timeout
	print("Irontick art portraits: %d checks; failures: %d; captures: %d. Quiet automated fixture only; no combat, native OS input or L3 acceptance." % [_checks, _failures, _captures])
	quit(0 if _failures == 0 else 1)
