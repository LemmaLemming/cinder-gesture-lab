extends "res://tests/acts/act3/crystalman_parent_transport_smoke.gd"
## UNEXECUTED TEST ONLY brief actual GPU parent portraits. No full route.
## Adds declared capture entry to inspect the actual landscape presence.
## Coda portrait fixture starts at authored TEST z=-9.5, before the contact;
## original transport fixture at z=-11 stays exact. No live actor pose write.
## Genuine offered production entry; existing DECLARED TEST coda prior history.
## Ordinary shared current camera, public Pause/consumed GUI Resume, followed
## synchronously by disclosed render-only freeze. No pose/camera/state injection.
const PORTRAIT_DIR: String = "res://captures/act3/crystalman-parent"
const REQUESTED_SIZE := Vector2i(340, 736)
const DRAW_LIMIT: int = 32
const PRODUCED_FROM_ACT3_PARENT_HEAD: String = "43ee893da25c9c8656966c0b828bfbbe1355afed"
const SOURCE_PINS: Dictionary = {
	"res://tests/acts/act3/crystalman_parent_transport_smoke.gd": "c2d396e74ece69c3436939e18ea8ccf1ef89906cbd9d324782a570fd81ed9ab7",
	"res://scripts/acts/act3/crystalman_level.gd": "8fc75cc68bdd073169648e972b71a2850d057bd144b5657c75354dff5a661608",
	"res://scripts/acts/act3/crystalman_parent_codec.gd": "bf105854b232edfac48f27b714e8d4dbeea40b9db7bc7871d75a3a70ba183efd",
	"res://scripts/acts/act3/crystalman_scenery.gd": "cdc14f7aa71cdb2a1daec81551ca3b9ec2086831c5e63cb29826bfe89fd462c5",
	"res://scripts/acts/act3/crystalman_landscape_scenery.gd": "77a2b1a0eabadf32d7a44e6f905a2309e28a6d5de6580fcf6225c9d1d562a62b",
	"res://scripts/acts/act3/crystalman_approach_unit.gd": "a3e9fd99f15231ca21ffabefb4ce65d146fb6f359b85bb6bfe0c4998fd5ff9f5",
	"res://scripts/acts/act3/crystalman_approach_codec.gd": "da4c4624fb5111d9b75667b7f3903cb9ad5b09a2b9322703292413e5f122186b",
	"res://data/campaign/act3/crystalman_layout.json": "26831d7447e217a57ed173090c82d88c3a437368c6abfda930de3e99fbc0d7c6",
	"res://scenes/acts/act3/a3_l5_crystalman.tscn": "887b4332fab4a506c0f697171cd4c40d0fe85a7ef35b1b948e4c6b89fee6a790",
	"res://tests/acts/act3/fixtures/crystalman_declared_4.tscn": "f465aadd9c4898d48a63db30279c5da7f8389461684dcc7b4607bf14ebe68532",
	"res://tests/acts/act3/fixtures/crystalman_declared_parent.gd": "83f0125fe68419e2e62724f8662f568bb249657ee9438f72222e2e7b1d67f133",
	"res://scripts/game.gd": "0b16d911409350a392f741a07bc163ad73c588d885ee7e1e64b951f97aa30d26",
	"res://scripts/campaign/level.gd": "1989a4170b68329afd6f49c5698b23aa96722883698ccacf32f905619539010d",
}

var _images: Dictionary = {}
var _draw_seen: bool = false
var _native_width: int = 0

func _run() -> void:
	if not expect(DisplayServer.get_name() != "headless" and DisplayServer.window_can_draw(root.get_window_id()) and OS.get_cmdline_user_args().is_empty(), "One graphical initial/coda portrait case; no capture/focus-bypass CLI flags"):
		quit(1); return
	for path: String in SOURCE_PINS:
		if not expect(FileAccess.get_sha256(path) == SOURCE_PINS[path], "Exact reviewed affected source pin", path): quit(1); return
	root.size = REQUESTED_SIZE
	root.content_scale_size = REQUESTED_SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	for case: Dictionary in [{"label":"offered-entry","room":ROOM,"stage":0,"declared_history":false},{"label":"declared-capture-entry","room":TEST_PREFIX+"2.tscn","stage":2,"declared_history":true},{"label":"declared-stripped-shore","room":"res://tests/acts/act3/fixtures/crystalman_portrait_coda.tscn","stage":4,"declared_history":true}]:
		if not await _open_for_portrait(case):
			await _close_portrait(); break
		if not await _capture(case):
			await _close_portrait(); break
		await _close_portrait()
	if failures == 0: expect(_images.size() == 3, "Initial, declared-capture and declared-coda portraits captured once")
	print("Crystalman parent GPU portraits: %d checks/%d failures/%d images. Declared coda prior history; no earned regular/tether route, active capture/framing transport or art acceptance." % [checks, failures, _images.size()])
	quit(0 if failures == 0 else 1)

func _open_for_portrait(case: Dictionary) -> bool:
	selected = int(case.stage); room_path = case.room
	paused = false
	game = MainScene.instantiate()
	game.set("level_scene_path", room_path)
	root.add_child(game)
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	if not expect(level != null and hero != null and level.level_id == "A3-L5" and String(level.get("last_configuration_error")).is_empty(), "Actual original native parent/scenery/Player enters", room_path): return false
	watch(level); watch(hero) # Existing public signal watcher; quiet count retained.
	# Two ordinary process boundaries ensure the shared level HUD has rendered
	# even when the initial camera already happens to satisfy geometric bounds.
	await process_frame
	await process_frame
	var error: String = "Native current entry view not yet observed"
	for _frame: int in range(90):
		if paused: return expect(false, "Unexpected real focus/UI Pause is preserved as failure before portrait")
		error = String(level.call("candidate_presentation_error", game.get("camera"), game.get("hud")))
		if error.is_empty(): break
		await process_frame # Ordinary current camera/HUD; no manual pose/focus fit.
	if not expect(error.is_empty(), "Ordinary fixed camera contains required actual source/Hero/current contact", error): return false
	game.call("open_bench")
	await process_frame # Public Pause UI callback/layout unwind.
	var saved: Dictionary = pair()
	if not expect(paused and not saved.player.is_empty() and not saved.level.is_empty() and level.snapshot_error_with_player(saved.level, saved.player).is_empty() and int(level.call("parent_owned_state").stage) == case.stage, "Complete actual paused parent/Player and requested native stage", level.last_snapshot_error): return false
	var resume: Button = _resume_button(game.get("hud") as Node)
	if not expect(resume != null and resume.is_visible_in_tree(), "Actual public Resume button visible"): return false
	var input_before: PackedByteArray = var_to_bytes(game.call("get_input_observation_state"))
	_gui_touch(resume.get_global_rect().get_center())
	var actually_resumed: bool = not paused
	paused = true # TEST ONLY render freeze; no await/physics after GUI Resume.
	if not expect(actually_resumed and not game.call("is_pause_requested") and same(saved, pair()) and input_before == var_to_bytes(game.call("get_input_observation_state")), "Consumed actual GUI Resume preserves complete parent/Player/input before synchronous render freeze"): return false
	return true

func _capture(case: Dictionary) -> bool:
	# The exact synchronous no-tick freeze began in _open_for_portrait.
	if not expect(paused, "Actual render-only frozen boundary remains paused"): return false
	var camera: Camera3D = game.get("camera") as Camera3D
	var hud: GameHUD = game.get("hud") as GameHUD
	var before: Dictionary = _observation(camera, hud)
	var raw_before: PackedByteArray = var_to_bytes(before)
	var wire: String = Exact.stringify(before.pair)
	if not expect(not before.pair.player.is_empty() and not before.pair.level.is_empty() and not wire.is_empty() and level.snapshot_error_with_player(before.pair.level, before.pair.player).is_empty() and not before.pause_requested and _resume_button(hud) != null and not _resume_button(hud).is_visible_in_tree(), "Render-only freeze holds valid whole native aggregate with real overlay already hidden", level.last_snapshot_error):
		paused = false; return false
	var optical: String = String(level.call("candidate_presentation_error", camera, hud))
	if not expect(camera == hero.get_viewport().get_camera_3d() and camera.get_world_3d() == hero.get_world_3d() and camera.get_viewport() == hero.get_viewport(), "Actual current same-world/viewport camera identity retained"): paused = false; return false
	_draw_seen = false
	RenderingServer.frame_post_draw.connect(_on_draw)
	for _frame: int in range(DRAW_LIMIT):
		await process_frame
		if _draw_seen: break
	if RenderingServer.frame_post_draw.is_connected(_on_draw): RenderingServer.frame_post_draw.disconnect(_on_draw)
	var pixels: Image = root.get_texture().get_image() if _draw_seen else null
	var unchanged: bool = paused and var_to_bytes(_observation(camera, hud)) == raw_before and Exact.stringify(pair()) == wire
	var size_ok: bool = pixels != null and not pixels.is_empty() and pixels.get_size().y == REQUESTED_SIZE.y and pixels.get_size().x in [339, 340] and root.size == REQUESTED_SIZE
	if size_ok and _native_width == 0: _native_width = pixels.get_size().x
	size_ok = size_ok and pixels.get_size().x == _native_width if pixels != null else false
	var folder: String = ProjectSettings.globalize_path(PORTRAIT_DIR)
	var destination: String = folder.path_join(case.label + ".png")
	var ok: bool = _draw_seen and unchanged and size_ok and DirAccess.make_dir_recursive_absolute(folder) == OK and pixels.save_png(destination) == OK
	if ok:
		var original: FileAccess = FileAccess.open(destination + ".native.bin", FileAccess.WRITE)
		var receipt: FileAccess = FileAccess.open(destination + ".json", FileAccess.WRITE)
		if original == null or receipt == null: paused = false; return expect(false, "Original native portrait/receipt files open")
		original.store_buffer(raw_before); original.close()
		var record: Dictionary = {"schema_version":1,"test_only":true,"label":case.label,"scene_path":room_path,"requested_size":[340,736],"actual_native_size":[pixels.get_size().x,pixels.get_size().y],"root_texture_metadata_size":str(root.get_texture().get_size()),"png_sha256":FileAccess.get_sha256(destination),"native_observation_sha256":FileAccess.get_sha256(destination+".native.bin"),"exact_whole_pair_sha256":wire.sha256_text(),"parent_route":before.pair.level.local.route,"declared_prior_history":case.declared_history,"whole_native_state_input_camera_scenery_floor_events_gear_unchanged":unchanged,"current_view_error":optical,"render_freeze_without_gameplay_tick":true,"consumed_public_GUI_Resume_before_freeze":true,"source_pins":SOURCE_PINS,"portrait_reference_scope":"selected environment/gameplay/revelation boards; prototype readiness","optional_landscape_visibility":_optional_art(camera),"full_route_or_art_acceptance":false}
		receipt.store_string(JSON.stringify(record,"  ")+"\n"); receipt.close()
		_images[case.label] = destination
		print("PORTRAIT: "+destination)
	paused = false
	if not expect(ok, "Actual native portrait keeps exact whole native state/camera/input/floor/scenery and native size", str(pixels.get_size()) if pixels != null else "bounded actual GPU draw unavailable"): return false
	return expect(optical.is_empty(), "Actual current native Hero/source/contact/cue protected view", optical)

func _observation(camera: Camera3D, hud: GameHUD) -> Dictionary:
	return {"pair":pair(),"input":game.call("get_input_observation_state"),"anchor":game.call("get_aim_anchor_normalized"),"actions":hero.get_world_action_records(),"camera":[camera.global_transform,camera.projection,camera.keep_aspect,camera.size,camera.near,camera.far,camera.h_offset,camera.v_offset,camera.cull_mask],"camera_framing":game.call("get_camera_framing_state"),"HUD_safe_rect":hud.combat_safe_rect(),"floor_transform":(level.get("floor_collision") as CollisionShape3D).global_transform,"floor_size":((level.get("floor_collision") as CollisionShape3D).shape as BoxShape3D).size,"scenery":_nodes(level.get("scenery") as Node),"Hero_presentation":_nodes(hero),"current_native_unit":_nodes(level.get("current_unit") as Node) if is_instance_valid(level.get("current_unit")) else {},"exit_cue":_nodes(level.get("exit_cue") as Node),"HUD":_nodes(hud),"quiet_signal_count":quiet,"pause_requested":game.call("is_pause_requested"),"HP":hero.hp,"gear":hero.equipment.snapshot(),"root_size":root.size}

func _nodes(node: Node) -> Dictionary:
	var state: Dictionary = {"name":String(node.name),"children":[]}
	if node is Node3D: state.pose = [node.transform,node.global_transform,node.visible]
	if node is CanvasItem: state.visible = node.visible
	if node is Control: state.rect = [node.position,node.size,node.get_global_rect()]
	if node is Sprite3D: state.sprite = [node.offset,node.pixel_size,node.frame,node.flip_h,node.flip_v,node.billboard,node.modulate,node.texture.get_instance_id() if node.texture != null else 0]
	if node is MeshInstance3D:
		state.mesh = node.mesh.get_instance_id() if node.mesh != null else 0
		state.material = node.material_override.get_instance_id() if node.material_override != null else 0
		if node.material_override is StandardMaterial3D: state.material_state = [node.material_override.albedo_color,node.material_override.transparency,node.material_override.no_depth_test]
	for child: Node in node.get_children(): state.children.append(_nodes(child))
	return state

func _optional_art(camera: Camera3D) -> Dictionary:
	var landscape: Node = (level.get("scenery") as Node).get("landscape")
	var result: Dictionary = {}
	var rect: Rect2 = camera.get_viewport().get_visible_rect()
	for family: String in ["presence","flora","spines","coda"]:
		var art: Dictionary = landscape.call("framing_points",family)
		var visible_corners: int = 0
		for point: Vector3 in art.get("points",[]):
			if not camera.is_position_behind(point) and rect.has_point(camera.unproject_position(point)): visible_corners += 1
		result[family] = {"displayed":art.get("displayed",false),"native_corner_count":art.get("points",[]).size(),"corners_in_actual_camera_rect":visible_corners,"native_camera_viewport_size":str(rect.size),"optional_scenery":true,"not_art_fidelity_or_occlusion_proof":true}
	return result

func _resume_button(node: Node) -> Button:
	if node is Button and node.text.contains("RESUME"): return node as Button
	for child: Node in node.get_children():
		var found: Button = _resume_button(child)
		if found != null: return found
	return null

func _gui_touch(where: Vector2) -> void:
	var down := InputEventScreenTouch.new(); down.index = 96; down.position = where; down.pressed = true
	root.push_input(down,true)
	var up := InputEventScreenTouch.new(); up.index = 96; up.position = where; up.pressed = false
	root.push_input(up,true)

func _on_draw() -> void: _draw_seen = true

func _close_portrait() -> void:
	var refs: Array[WeakRef] = []
	for node: Node in [game,level,hero]:
		if is_instance_valid(node): refs.append(weakref(node))
	await close() # Existing ordinary whole parent/native cleanup; no state repair.
	expect(refs.all(func(ref: WeakRef) -> bool: return ref.get_ref() == null), "Normal whole parent/Player/native art cleanup")
	game = null; level = null; hero = null
