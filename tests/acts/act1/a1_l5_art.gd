extends SceneTree
## Renderer COMPONENT check in the actual shared Main lab/world/Hero/camera.
## TEST stationary scenic anchor and supplied cosmetic poses are disclosed.
## No B02 body/attack, geometry/framing/landing proof, fairness, level/save,
## route, art fidelity before personal pixel review, performance or mobile claim.

const MainScene = preload("res://scenes/main.tscn")
const MoonArt = preload("res://scripts/acts/act1/living_moon_art.gd")
const PortraitSize := Vector2i(540, 1170)
const LabAnchor := Vector3(-1.0, 0.0, -1.4)
const WatchdogMs: int = 30000

class FocusObserver extends Node:
	var receive: Callable
	func _notification(what: int) -> void:
		if what == NOTIFICATION_APPLICATION_FOCUS_OUT and receive.is_valid():
			receive.call("application-focus-out")

var game: Node
var hero: CinderPlayer
var camera: Camera3D
var anchor: Node3D
var art: Node3D
var focus_observer: Node
var portrait: bool = false
var focus_armed: bool = false
var aborted: bool = false
var finishing: bool = false
var checks: int = 0
var failures: int = 0
var first_failure: String = ""
var started_ms: int = 0
var capture_dir: String = ""
var report_path: String = ""
var captures: Array[Dictionary] = []
var focus_events: Array[Dictionary] = []


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	process_frame.connect(_watchdog)
	_run.call_deferred()


func _run() -> void:
	portrait = "--portrait" in OS.get_cmdline_user_args()
	root.size = PortraitSize
	report_path = "res://.cinder/l5-art-component-%d.json" % Time.get_ticks_usec()
	if portrait:
		if not _expect(DisplayServer.get_name() != "headless", "portrait mode requires the actual graphical renderer"):
			await _finish(); return
		root.focus_exited.connect(_focus_lost.bind("window-focus-out"))
		var observer := FocusObserver.new()
		observer.receive = _focus_lost
		focus_observer = observer
		root.add_child(observer)
		if not await _startup_focus():
			await _finish(); return
		capture_dir = "res://.cinder/captures/l5-art-component-%d" % Time.get_ticks_usec()
		if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir)) == OK, "portrait output directory is writable"):
			await _finish(); return
	game = MainScene.instantiate()
	root.add_child(game)
	hero = game.get("player") as CinderPlayer
	camera = game.get("camera") as Camera3D
	if not _expect(hero != null and camera != null and game.get("world") is Node3D and game.call("is_lab_level"), "actual shared Main supplies its existing lab/world/Hero/camera"):
		await _finish(); return
	game.call("resume_lab") # One initial public lab start; no later forced resume.
	focus_armed = portrait
	if not await _settled():
		await _finish(); return
	if not _expect(_floor_anchors(), "both disclosed stationary scenic pivots lie on the actual native box-floor top"):
		await _finish(); return
	anchor = Node3D.new()
	anchor.name = "TESTStationaryMoonSceneryAnchor"
	anchor.process_mode = Node.PROCESS_MODE_DISABLED
	(game.get("world") as Node3D).add_child(anchor)
	anchor.global_position = LabAnchor
	art = MoonArt.new()
	anchor.add_child(art)
	if not _expect(art.transform == Transform3D.IDENTITY and anchor.global_position == LabAnchor and _presentation_only(art), "new subtree is clockless Node3D/MeshInstance presentation with no physics/cue/camera/group authority") or not _expect(_all_mesh_bounds(), "every authored native mesh is finite and enclosed by its complete declared attachment reserve"):
		await _finish(); return
	var expected_points: Dictionary = {}
	for expression: String in MoonArt.EXPRESSIONS:
		for eye_phase: String in MoonArt.PHASES:
			for nose_phase: String in MoonArt.PHASES:
				var before: Dictionary = _native_unit()
				if not _expect(art.call("set_pose", eye_phase, nose_phase, expression, camera), "supported cosmetic pose " + expression + "/" + eye_phase + "/" + nose_phase):
					await _finish(); return
				if not _expect(_native_unit() == before, "pose selection writes no Hero/camera/scenic-anchor/art-parent transform or native input/HP/action state") or not _expect(_selected_pose(eye_phase, nose_phase, expression), "exactly one actual face, eye and nose mesh has the supplied local visibility"):
					await _finish(); return
				var points: Dictionary = art.call("part_points", camera)
				if not _expect(_complete_parts(points), "complete actual part reserves include both retained floor pivots"):
					await _finish(); return
				if expected_points.is_empty(): expected_points = points.duplicate(true)
				if not _expect(points == expected_points, "all cosmetic poses retain exactly the same eye/nose floor anchors and complete renderer reserves"):
					await _finish(); return
	var visibility: Dictionary = _mesh_visibility()
	anchor.hide()
	if not _expect(not art.is_visible_in_tree() and _mesh_visibility() == visibility, "ordinary inherited parent hiding retains supported local pose visibility"):
		await _finish(); return
	anchor.show()
	if not _expect(art.is_visible_in_tree() and _mesh_visibility() == visibility and _presentation_only(art), "ordinary parent showing restores presentation without a new authority node or pose mutation"):
		await _finish(); return
	if portrait:
		for specimen: Dictionary in [
			{"stage":"TEST-indignant", "eye":"idle", "nose":"idle", "body":"indignant"},
			{"stage":"TEST-blink-lock", "eye":"lock", "nose":"idle", "body":"indignant"},
			{"stage":"TEST-sneeze-warning", "eye":"idle", "nose":"warning", "body":"indignant"},
			{"stage":"TEST-recovery", "eye":"recovery", "nose":"recovery", "body":"indignant"},
			{"stage":"TEST-flinch", "eye":"clear", "nose":"clear", "body":"flinch"},
		]:
			if not _guard() or not _expect(art.call("set_pose", specimen.eye, specimen.nose, specimen.body, camera), "representative cosmetic capture pose is supported") or not await _capture(specimen.stage):
				await _finish(); return
	await _finish()


func _native_unit() -> Dictionary:
	return {"hero_transform": hero.global_transform, "hp": hero.hp, "shells": hero.shells, "world_records": hero.get_world_action_records(), "input": game.call("get_input_observation_state"), "camera_transform": camera.global_transform, "projection": camera.get_camera_projection(), "anchor_transform": anchor.global_transform, "art_transform": art.transform, "paused": paused}


func _floor_anchors() -> bool:
	var floor: StaticBody3D = (game.get("world") as Node3D).find_child("Floor", true, false) as StaticBody3D
	var collision: CollisionShape3D = floor.get_node_or_null("Collision") as CollisionShape3D if floor != null else null
	if collision == null or not collision.shape is BoxShape3D or collision.global_basis != Basis.IDENTITY: return false
	var size: Vector3 = (collision.shape as BoxShape3D).size
	var top: float = collision.global_position.y + size.y * 0.5
	var floor_rect := Rect2(Vector2(collision.global_position.x, collision.global_position.z) - Vector2(size.x, size.z) * 0.5, Vector2(size.x, size.z))
	for point: Vector3 in [LabAnchor, LabAnchor + MoonArt.NOSE_ANCHOR]:
		if point.y != top or not floor_rect.has_point(Vector2(point.x, point.z)): return false
	return true


func _presentation_only(node: Node) -> bool:
	if not node is Node3D or node is CollisionObject3D or node is CollisionShape3D or node is Camera3D or not node.get_groups().is_empty() or node.process_mode != Node.PROCESS_MODE_DISABLED or node.is_processing() or node.is_physics_processing():
		return false
	if node != art and not node is MeshInstance3D and node.get_script() != null:
		return false
	for child: Node in node.get_children():
		if not _presentation_only(child): return false
	return true


func _all_mesh_bounds() -> bool:
	var reserves: Dictionary = MoonArt.local_bounds()
	var count: int = 0
	for key: String in ["face", "eye", "nose"]:
		var carrier: Node3D = art.get_node_or_null(key.capitalize() + "Carrier") as Node3D
		if carrier == null: return false
		for child: Node in carrier.get_children():
			if not child is MeshInstance3D: return false
			var mesh: MeshInstance3D = child
			if not mesh.mesh is ArrayMesh or not reserves[key].encloses(mesh.get_aabb()): return false
			for surface: int in mesh.mesh.get_surface_count():
				var arrays: Array = mesh.mesh.surface_get_arrays(surface)
				for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
					if not vertex.is_finite(): return false
			count += 1
	return count == 27


func _selected_pose(eye_phase: String, nose_phase: String, expression: String) -> bool:
	if art.call("pose_state") != {"eye_phase":eye_phase, "nose_phase":nose_phase, "expression":expression}: return false
	var expected: Dictionary = {"FaceCarrier":expression.capitalize(), "EyeCarrier":expression.capitalize()+eye_phase.capitalize(), "NoseCarrier":nose_phase.capitalize()}
	for carrier_name: String in expected:
		var selected: int = 0
		for mesh: Node3D in art.get_node(carrier_name).get_children():
			if mesh.visible:
				selected += 1
				if mesh.name != expected[carrier_name]: return false
		if selected != 1: return false
	return true


func _complete_parts(parts: Dictionary) -> bool:
	if parts.size() != 5 or parts.get("eye_floor_pivot") != LabAnchor or parts.get("nose_floor_pivot") != LabAnchor + MoonArt.NOSE_ANCHOR: return false
	for key: String in ["face", "eye", "nose"]:
		if not parts.get(key) is Array or parts[key].size() != 8: return false
		var unique: Dictionary = {}
		for point: Variant in parts[key]:
			if not point is Vector3 or not point.is_finite(): return false
			unique[point] = true
		if unique.size() != 8: return false
	var required: Array = art.call("required_part_points", camera)
	var full: Array = art.call("world_corners", camera)
	return required.size() == 18 and full.size() == 24 and required.slice(0,8) == parts.eye and required.slice(8,16) == parts.nose and full.slice(0,8) == parts.face and full.slice(8,16) == parts.eye and full.slice(16,24) == parts.nose


func _mesh_visibility() -> Dictionary:
	var result: Dictionary = {}
	for carrier: Node in art.get_children():
		for mesh: Node3D in carrier.get_children():
			result[String(carrier.name) + "/" + String(mesh.name)] = mesh.visible
	return result


func _startup_focus() -> bool:
	var deadline: int = Time.get_ticks_msec() + 4000
	var stable_since: int = -1
	while Time.get_ticks_msec() < deadline and not finishing:
		if root.has_focus() and DisplayServer.window_is_focused(root.get_window_id()):
			if stable_since < 0: stable_since = Time.get_ticks_msec()
			if Time.get_ticks_msec() - stable_since >= 200: return _expect(true, "portrait observes genuine stable initial focus; no OS foreground request")
		else: stable_since = -1
		await process_frame
	return _expect(false, "portrait startup lacks genuine native focus; no forced OS focus")


func _settled() -> bool:
	var deadline: int = Time.get_ticks_msec() + 4000
	while Time.get_ticks_msec() < deadline and not finishing:
		if not _guard(): return false
		if hero.get_threat_response_state().stable: return _expect(true, "actual shared Hero settles on the native lab floor")
		await process_frame
	return _expect(false, "actual shared Hero did not settle within the bounded component setup")


func _guard() -> bool:
	if finishing or aborted: return false
	if portrait and (paused or not root.has_focus() or not DisplayServer.window_is_focused(root.get_window_id())):
		aborted = true
		return _expect(false, "genuine focus loss or normal pause cancels portrait; no forced resume")
	return true


func _focus_lost(label: String) -> void:
	focus_events.append({"label":label, "wall_usec":Time.get_ticks_usec(), "armed":focus_armed, "paused":paused})
	if focus_armed and not finishing and not aborted:
		aborted = true
		_expect(false, "genuine native " + label + " cancels the portrait fixture")
		_finish.call_deferred()


func _capture(stage: String) -> bool:
	if not _guard(): return false
	await RenderingServer.frame_post_draw
	if not _guard(): return false
	var image: Image = root.get_texture().get_image()
	var path: String = capture_dir.path_join("%02d-%s.png" % [captures.size()+1, stage])
	if not _expect(image != null and image.get_size() == PortraitSize and image.save_png(path) == OK, "actual 540x1170 renderer saves " + stage): return false
	captures.append({"stage":stage, "path":ProjectSettings.globalize_path(path), "pose":art.call("pose_state"), "TEST_floor_anchor":[LabAnchor.x,LabAnchor.y,LabAnchor.z], "camera_transform":str(camera.global_transform), "native_focus":DisplayServer.window_is_focused(root.get_window_id()), "optical_review":"pending personal image inspection; lab component pose is not L5 gameplay or art acceptance"})
	return true


func _expect(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		if first_failure.is_empty(): first_failure = message
		push_error("L5 art component: " + message)
	return ok


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > WatchdogMs:
		_expect(false, "bounded renderer component watchdog expired")
		_finish.call_deferred()


func _retain(node: Node, refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child: Node in node.get_children(): _retain(child, refs)


func _finish() -> void:
	if finishing: return
	finishing = true
	focus_armed = false
	var refs: Array[WeakRef] = []
	if is_instance_valid(game):
		_retain(game, refs)
		game.queue_free()
	if is_instance_valid(focus_observer):
		refs.append(weakref(focus_observer))
		focus_observer.queue_free()
	await process_frame
	await process_frame
	_expect(refs.all(func(ref: WeakRef) -> bool: return ref.get_ref() == null), "normal Main/world/Hero/camera/scenery disposal releases every retained native node")
	var report: Dictionary = {"scope":"actual Main lab renderer component, TEST cosmetic poses and stationary scenic anchor only", "checks":checks, "failures":failures, "first_failure":first_failure, "portrait":portrait, "captures":captures, "focus_events":focus_events, "TEST_floor_anchor":[LabAnchor.x,LabAnchor.y,LabAnchor.z], "source_pivots":"no gameplay body or attack source exists in this fixture", "normal_focus_out_preserved":true, "no_claims":["B02 attack or body behavior", "camera framing or landing/fairness", "level or campaign save/route", "pixel fidelity before personal image review", "performance", "mobile"]}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null: _expect(false, "component report is writable")
	else: file.store_string(JSON.stringify(report, "\t")); file.close()
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("L5 art native component: %d checks, %d failures; report=%s; no gameplay or art-fidelity claim" % [checks, failures, ProjectSettings.globalize_path(report_path)])
	quit(0 if failures == 0 else 1)
