extends SceneTree
## Actual production CampaignShell override, native player/source/cue and HUD.
## Injected fixture metadata and isolated saves certify no authored act level.

const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const LEVEL_PATH: String = "res://tests/fixtures/campaign/shell_hud_framing_level.tscn"
const LONG_OBJECTIVE: String = "SHARED CAMPAIGN CAMERA FIXTURE: KEEP THE WHOLE COMMITTED SOURCE, ITS COMPLETE WARNING FOOTPRINT, SAFE LANDING AND THE PLAYER VISIBLE BELOW THIS WRAPPED OBJECTIVE IN THE SAME RENDERED FRAME."

var _game: CinderCampaignShell
var _checks: int = 0
var _failures: int = 0
var _finished: bool = false
var _graphical: bool = false
var _output: String
var _test_root: String
var _captures: Array[String] = []
var _old_fps: int
var _old_audio: AudioBusLayout
var _canonical_registry: String

func _initialize() -> void:
	_old_fps = Engine.max_fps
	_old_audio = AudioServer.generate_bus_layout()
	_test_root = "user://test-campaign-shell-hud-framing-%d/" % OS.get_process_id()
	_run.call_deferred()

func _run() -> void:
	create_timer(25.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "bounded fixture watchdog")
			_finish())
	_ensure_uids()
	_graphical = DisplayServer.get_name() != "headless"
	_output = "res://.cinder/campaign-shell-hud-framing-%s-%d" % ["graphical" if _graphical else "headless", OS.get_process_id()]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output))
	root.size = Vector2i(540, 1170)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_canonical_registry = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var injected: Dictionary = JSON.parse_string(_canonical_registry)
	for entry: Dictionary in injected.levels:
		if entry.id == "A1-L1":
			entry.scene_path = LEVEL_PATH
			entry.readiness = "accepted"
			entry.accepted_commit = "f".repeat(40)
			entry.api_revision = Registry.API_REVISION
	_game = Shell.new()
	_expect(_game.configure_runtime(injected, _test_root + "campaign.json", _test_root + "settings.json", _test_root + "preferences.json"), "only isolated TEST ONLY registry/save bindings configure the actual shell")
	root.add_child(_game)
	await _frames(3)
	_expect(paused and _game.menu.page_name() == "title" and _game.active_level == null, "production CampaignShell starts at paused Title without a fabricated campaign level")
	_game.menu.begin_story_requested.emit()
	await _frames(4)
	_expect(_game.campaign_error.is_empty() and is_instance_valid(_game.active_level) and _game.active_level.scene_file_path == LEVEL_PATH, "public Begin reaches actual native fixture through the shared preparation/save/install path: " + _game.campaign_error)
	if not is_instance_valid(_game.active_level):
		_finish()
		return
	_expect(paused and _game.menu.page_name() == "resume", "new actual attempt waits behind the consumed Resume overlay")
	# One public initial resume; all normal inherited native focus handlers stay
	# active. Immediately request the ordinary durable pause for exact probes.
	_game.resume_campaign()
	_expect(not paused and not _game.menu.is_open(), "public initial Resume consumes the overlay without a focus override")
	_game.request_pause()
	await _frames(3)
	_expect(paused and _game.menu.page_name() == "pause", "public campaign Pause reaches a coherent deferred barrier")
	_game.menu.hide_menu()
	_game.hud.hide_overlay()
	_expect(_game is CinderCampaignShell and _game.player.get_viewport().size == Vector2i(270, 585) and root.size == Vector2i(540, 1170), "fixture exercises the production Shell override in the native portrait raster")
	_expect((_game.player.get_viewport().get_parent() as SubViewportContainer).texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "installed portrait container retains nearest filtering")
	var level: CinderLevel = _game.active_level
	var required: Array = level.camera_framing_points()
	_expect(_game.player_camera_framing_points().size() == 22 and required.size() >= 36, "actual native hero quad/body, source quad, crest, complete cue and landing corners are retained")
	_expect(level.get("cue").state().phase == "warning", "actual shared required cue is visible; fixture invokes no attack or damage")
	_game._record_swipe_end(Vector2(root.size) * Vector2(0.78, 0.56))
	var anchor: Vector2 = _game.get_aim_anchor_normalized()
	var aim: Vector3 = _game.aim_direction(Vector2(189, 842.4))
	var actor_before: Dictionary = _game.player.snapshot_state()
	var story_before: Dictionary = _game.attempts.story_snapshot()
	var basis: Basis = _game.camera.global_basis
	var width: float = _game.camera.size
	_game._process(0.0)
	var short_rect: Rect2 = _game.hud.combat_safe_rect()
	_expect(_game.get_camera_framing_state().accepted and _game.get_camera_framing_state().safe_rect == short_rect and _contained(required), "actual short objective and whole native required union fit through CampaignShell._process")
	await _capture("01-short-objective")
	level.objective_text = LONG_OBJECTIVE
	# Exactly one actual override call: no preparatory HUD update or extra frame
	# may hide the historical HUD-after-camera ordering defect.
	_game._process(0.0)
	var wrapped: Rect2 = _game.hud.combat_safe_rect()
	var framed: Dictionary = _game.get_camera_framing_state()
	_expect(wrapped.position.y > short_rect.position.y, "real shaped multiline objective expands its current protected HUD rectangle")
	_expect(framed.enabled and framed.accepted and framed.safe_rect == wrapped, "same-frame production CampaignShell fits against newly wrapped HUD instead of the previous smaller rectangle")
	_expect(_game.camera_framing_error(required).is_empty() and _contained(required), "current complete native source/cue/landing/player corners are inside the newly rendered HUD-safe region")
	_expect(_game.camera.global_basis == basis and _game.camera.size == width, "same-frame correction retains exact camera orientation and orthographic width")
	_expect(_game.get_aim_anchor_normalized() == anchor and _game.aim_direction(Vector2(189, 842.4)) == aim, "same-frame HUD/framing changes preserve exact held release aim")
	_expect(_same(actor_before, _game.player.snapshot_state()) and _same(story_before, _game.attempts.story_snapshot()), "same-frame HUD/framing changes preserve exact actor resources/actions/timers and durable story")
	await _capture("02-wrapped-objective")
	# The reverse transition guards against permanently reserving an old larger
	# area or solving only expansion while ignoring real current HUD geometry.
	level.objective_text = "SHORT AGAIN"
	_game._process(0.0)
	_expect(_game.get_camera_framing_state().safe_rect == _game.hud.combat_safe_rect() and _game.hud.combat_safe_rect().position.y == short_rect.position.y, "one reverse Shell frame uses the current contracted HUD rectangle")
	_expect(_game.get_camera_framing_state().accepted and _contained(required) and _same(actor_before, _game.player.snapshot_state()), "reverse HUD update preserves native containment and exact actor state")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical_registry, "TEST ONLY fixture never changes real accepted campaign metadata")
	_finish()

func _contained(required: Array) -> bool:
	var corners: Array = required.duplicate()
	corners.append_array(_game.player_camera_framing_points())
	var safe: Rect2 = _game.hud.combat_safe_rect()
	var pixels: Vector2 = _game.camera.get_viewport().size
	for point: Vector3 in corners:
		if _game.camera.is_position_behind(point) or not _game.camera.is_position_in_frustum(point):
			return false
		var projected: Vector2 = _game.camera.unproject_position(point) / pixels
		if projected.x < safe.position.x or projected.y < safe.position.y or projected.x > safe.end.x or projected.y > safe.end.y:
			return false
	return not corners.is_empty()

func _capture(label: String) -> void:
	if not _graphical:
		return
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	_expect(not image.is_empty() and image.get_size() == Vector2i(540, 1170), "actual graphical " + label + " capture retains full portrait output")
	var path: String = _output + "/" + label + ".png"
	_expect(image.save_png(path) == OK, "actual graphical " + label + " pixels saved")
	_captures.append(ProjectSettings.globalize_path(path))

func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame

func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = ExactJson.stringify(left)
	return not encoded.is_empty() and encoded == ExactJson.stringify(right)

func _ensure_uids() -> void:
	for path: String in ["res://tests/campaign_shell_hud_framing_smoke.gd.uid", "res://tests/fixtures/campaign/shell_hud_framing_level.gd.uid"]:
		if not FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_line(ResourceUID.id_to_text(ResourceUID.create_id()))

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)

func _finish() -> void:
	if _finished:
		return
	_finished = true
	var evidence := {"checks": _checks, "failures": _failures, "graphical": _graphical, "engine": Engine.get_version_info(), "captures": _captures, "native_window_focused": root.has_focus(), "fixture": "TEST ONLY actual CampaignShell/native actor/source/cue/landing/HUD; no authored scene acceptance, attack, damage or native human input", "focus_policy": "Unchanged normal native notifications; one public initial Resume followed by public Pause; no focus grab/suppression"}
	var file := FileAccess.open(_output + "/evidence.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(evidence, "\t", true, true))
		file.close()
	if is_instance_valid(_game):
		_game.free()
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "preferences.json"]:
		if FileAccess.file_exists(_test_root + name):
			DirAccess.remove_absolute(_test_root + name)
	DirAccess.remove_absolute(_test_root)
	Engine.max_fps = _old_fps
	AudioServer.set_bus_layout(_old_audio)
	print("Campaign Shell HUD framing smoke: %d checks, %d failures; %s" % [_checks, _failures, ProjectSettings.globalize_path(_output)])
	quit(0 if _failures == 0 else 1)
