extends SceneTree
## TEST ONLY native540x1170 shared Game/camera and actual new resource assembly.
## Fixture placement/cosmetic phases only; no accepted attack, route or smoke.
const Main: PackedScene = preload("res://scenes/main.tscn")
const PreviewPath: String = "res://tests/acts/act2/fixtures/a2_l3_asset_preview.tscn"
const CAPTURE_ROOT: String = "res://captures/act2/a2-l3-assets/"
const VIEWS: Array[Dictionary] = [
	{"id": "boss", "label": "boss-idle", "phase": "idle", "p": 0.0, "action": "reach", "hero": Vector3(0.0, 0.1, -32.2)},
	{"id": "boss", "label": "boss-reach-lock", "phase": "lock", "p": 0.5, "action": "reach", "hero": Vector3(-1.8, 0.1, -32.2)},
	{"id": "boss", "label": "boss-reach-active", "phase": "active", "p": 0.5, "action": "reach", "hero": Vector3(-1.8, 0.1, -32.2)},
	{"id": "boss", "label": "boss-reach-recovery", "phase": "recovery", "p": 0.5, "action": "reach", "hero": Vector3(-0.8, 0.1, -33.8)},
	{"id": "boss", "label": "boss-place-active", "phase": "active", "p": 0.5, "action": "place", "hero": Vector3(-1.8, 0.1, -33.0)},
	{"id": "boss", "label": "boss-place-recovery", "phase": "recovery", "p": 0.5, "action": "place", "hero": Vector3(-0.8, 0.1, -33.8)},
	{"id": "boss", "label": "boss-local-arm-disengaged", "phase": "defeated", "p": 1.0, "action": "place", "hero": Vector3(0.0, 0.1, -32.2)},
	{"id": "road_tender", "label": "tender-warning", "phase": "warning", "p": 0.6, "action": "reach", "hero": Vector3(-0.9, 0.1, -0.6)},
	{"id": "road_tender", "label": "tender-reload", "phase": "recovery", "p": 0.5, "action": "reach", "hero": Vector3(-0.8, 0.1, -1.3)},
	{"id": "house_tender", "label": "exposed-house", "phase": "idle", "p": 0.0, "action": "reach", "hero": Vector3(-1.8, 0.1, -10.0)},
]
var _checks: int = 0
var _failures: int = 0
var _game: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(540, 1170)
	_expect(DisplayServer.get_name() != "headless", "native asset inspection requires a graphical surface")
	_expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_ROOT)) == OK, "separate L3 asset capture directory")
	_game = Main.instantiate()
	_game.set("level_scene_path", PreviewPath)
	root.add_child(_game)
	await _settle(12)
	var level: CinderLevel = _game.get("active_level") as CinderLevel
	var hero: CinderPlayer = _game.get("player") as CinderPlayer
	_expect(is_instance_valid(level) and level.scene_file_path == PreviewPath and level.hero == hero, "actual shared Game installs the TEST ONLY native asset fixture")
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("practice_targets").is_empty(), "cosmetic preview has no targets or combat authority")
	_expect(level.get("floors").size() == 4 and hero.presentation_id == "act2_survivor", "actual broad floor and Act2 shared protagonist presentation")
	var records: Array[Dictionary] = []
	for view: Dictionary in VIEWS:
		# TEST ONLY stage placement for art inspection; no movement/progress/save
		# is credited. Shared native following camera settles without alteration.
		hero.global_position = view.hero
		_expect(level.call("select_view", view.id, view.phase, view.p, view.action), "parent selects deterministic cosmetic pose " + view.label)
		await _settle(40)
		var camera: Camera3D = _game.get("camera") as Camera3D
		var hero_bounds: Array[Vector3] = []
		hero_bounds.assign(_game.call("camera_billboard_points", hero.get_node("ActorSprite")))
		var rig: Node3D = level.get("rigs")[view.id]
		_expect(rig.call("apply_readability", camera, hero_bounds), "actual shared billboard bounds drive isolated art cutaway " + view.label)
		await RenderingServer.frame_post_draw
		var picture: Image = root.get_texture().get_image()
		var image_path: String = CAPTURE_ROOT + view.label + ".png"
		_expect(picture != null and picture.get_size() == Vector2i(540, 1170) and picture.save_png(image_path) == OK, "native540x1170 asset image saved " + view.label)
		var points: Array = level.camera_framing_points()
		var framing: String = _game.call("camera_framing_error", points)
		records.append({"label": view.label, "id": view.id, "phase": view.phase, "progress": view.p, "action": view.action, "hero_fixture_position": [hero.global_position.x, hero.global_position.y, hero.global_position.z], "hero_hp": hero.hp, "camera_framing_error": framing, "image": image_path, "image_sha256": FileAccess.get_sha256(image_path), "scope": "TEST ONLY native cosmetic asset pose/assembly; no accepted attack, smoke, route, input or aggregate claim"})
		_expect(framing.is_empty(), "actual camera contains conservative selected asset bounds " + view.label + ": " + framing)
	var file := FileAccess.open(CAPTURE_ROOT + "metadata.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope": "TEST ONLY cosmetic previews with stage placed Hero; actual shared Game/camera/Act2 skin and production floor/kit/visual resources", "fixture": PreviewPath, "frames": records}, "  ") + "\n")
	file.close()
	_game.call("request_pause")
	level.exit_level()
	_game.get("fx").clear()
	paused = false
	await create_timer(0.15).timeout
	_game.queue_free()
	await _settle(3)
	_expect(get_nodes_in_group("enemies").is_empty(), "preview releases its actual native subtree")
	print("A2-L3 native asset capture: %d checks, %d failures;10 cosmetic frames, no authored gameplay/smoke/canonical acceptance" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _settle(count: int) -> void:
	for ignored: int in range(count): await physics_frame
	await process_frame

func _expect(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("FAIL: " + label)
