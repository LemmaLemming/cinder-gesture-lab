extends SceneTree
## Focused graphical fixture for the actual shared HUD at 540 x 1170.
## No campaign scene or gameplay acceptance is implied by these captures.

const HUD = preload("res://scripts/hud.gd")
const CAPTURE_ROOT: String = "res://captures/hud-objective/"
const TWO_LINES: String = "SWIPE UP TO THE BROAD FLOOR MARKER\nRELEASE UPPER-LEFT, THEN TAP CENTRE"
const THREE_LINES: String = "MOVE INTO THE BROAD WORKSHOP FLOOR\nRELEASE LOWER-RIGHT, THEN TAP LEFT\nBLAST IS OPTIONAL; ORDINARY SLASH WORKS"
const WRAPPED: String = "FOLLOW THE BROAD FLOOR MARKERS INTO THE WORKSHOP, KEEP THE LOADING ARM AND ITS WARNING FOOTPRINT IN VIEW, DASH TO THE CLEAR LANDING, THEN RETURN DURING RECOVERY AND USE AN ORDINARY CLOSE SLASH."

var _checks: int = 0
var _failures: int = 0
var _hud: GameHUD
var _objective: Label
var _telemetry: Label


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	create_timer(30.0, true).timeout.connect(func() -> void: quit(1))
	var background := ColorRect.new()
	background.color = Color(0.72, 0.72, 0.70)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud = HUD.new()
	root.add_child(_hud)
	_hud.hide_overlay()
	_objective = _hud.find_child("ObjectiveLabel", true, false) as Label
	_telemetry = _hud.find_child("TelemetryLabel", true, false) as Label
	await _settle()
	_expect(root.get_visible_rect().size == Vector2(540, 1170), "fixture uses the actual portrait HUD viewport")
	_expect(_objective != null and _telemetry != null, "shared objective and telemetry controls are available")
	if _objective == null or _telemetry == null:
		quit(1)
		return
	_telemetry.text = "DASH 2.70 UNITS  /  15.00 UNITS/S\nPRIMARY 24.0 DAMAGE  /  0 HITS"
	_hud.update_status(37.0, 100.0, 0, 2, 0, TWO_LINES)
	await _settle()
	_check_fit(2, "explicit two-line objective")
	var two_height: float = _objective.size.y
	await _capture("two-lines")
	_hud.update_status(37.0, 100.0, 0, 2, 0, THREE_LINES)
	await _settle()
	_check_fit(3, "explicit three-line objective")
	_expect(_objective.size.y > two_height, "three lines expand the protected backplate beyond the two-line height")
	await _capture("three-lines")
	_hud.update_status(37.0, 100.0, 0, 2, 0, WRAPPED)
	await _settle()
	_expect(_objective.get_line_count() >= 3, "long objective wraps to several actual shaped lines")
	_check_fit(_objective.get_line_count(), "wrapped objective")
	await _capture("wrapped")
	_hud.update_status(37.0, 100.0, 0, 2, 0, "RETURN TO THE SAFE MARKER")
	await _settle()
	var short_height: float = _objective.size.y
	_expect(is_equal_approx(short_height, 45.0), "short objective retains the existing portrait minimum height")
	_hud.flash_message(THREE_LINES)
	await _settle()
	_check_fit(3, "multiline temporary message")
	_expect(_objective.size.y > short_height, "flash_message expands immediately for its own content")
	await _capture("flash")
	await create_timer(1.9, false).timeout
	await _settle()
	_expect(_objective.text == "RETURN TO THE SAFE MARKER" and is_equal_approx(_objective.size.y, short_height), "timed objective restore shrinks the backplate to its fitted original height")
	_check_fit(1, "restored short objective")
	await _capture("restored")
	print("HUD objective capture: %d checks, %d failures; five focused 540x1170 shared-HUD images" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check_fit(expected_lines: int, description: String) -> void:
	var actual_lines: int = _objective.get_line_count()
	_expect(actual_lines == expected_lines, description + " preserves all intended shaped lines")
	_expect(_objective.get_visible_line_count() == actual_lines, description + " renders every shaped line without vertical clipping")
	_expect(_objective.size.y >= ceilf(_objective.get_minimum_size().y), description + " fits text plus actual backplate content margins")
	_expect(_telemetry.position.y >= _objective.position.y + _objective.size.y, description + " keeps telemetry below the expanded protected objective")


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var directory: String = ProjectSettings.globalize_path(CAPTURE_ROOT)
	_expect(DirAccess.make_dir_recursive_absolute(directory) == OK, "capture directory is available")
	var image: Image = root.get_texture().get_image()
	_expect(image.get_size() == Vector2i(540, 1170), "rendered capture keeps the full portrait resolution")
	var path: String = CAPTURE_ROOT + label + ".png"
	_expect(image.save_png(path) == OK, "rendered " + label + " capture saves successfully")
	print("Rendered ", ProjectSettings.globalize_path(path))


func _settle() -> void:
	for _index: int in range(4):
		await process_frame


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
