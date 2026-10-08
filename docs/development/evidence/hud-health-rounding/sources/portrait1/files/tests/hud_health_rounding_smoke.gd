extends SceneTree
## TEST ONLY actual HUD + canonical paused Cargo Player. Display-only checks;
## no authored level, gameplay route, native OS/human input or acceptance claim.

const HUD = preload("res://scripts/hud.gd")
const Player = preload("res://scripts/player.gd")
const Equipment = preload("res://scripts/equipment.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const PORTRAIT_SIZE: Vector2i = Vector2i(540, 1170)
const OBJECTIVE: String = "TEST ONLY HUD HEALTH DISPLAY"

var _checks: int = 0
var _failures: int = 0
var _arena: Node3D
var _actor: CinderPlayer
var _hud: GameHUD
var _background: ColorRect
var _label: Label
var _track: ColorRect
var _fill: ColorRect
var _label_rect: Rect2
var _safe_rect: Rect2


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = PORTRAIT_SIZE
	root.content_scale_size = PORTRAIT_SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var portrait: bool = "--portrait" in OS.get_cmdline_user_args()
	if portrait and not _expect(DisplayServer.get_name() != "headless", "optional portrait uses the actual native GUI renderer"):
		await _finish(); return
	_background = ColorRect.new()
	_background.color = Color(0.55, 0.55, 0.54)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_background)
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_arena = Node3D.new()
	root.add_child(_arena)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(12.0, 1.0, 12.0)
	floor_collision.shape = floor_shape
	floor_body.add_child(floor_collision)
	_arena.add_child(floor_body)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	_actor = Player.new()
	_actor.position = Vector3(0.0, 0.02, 0.0)
	_arena.add_child(_actor)
	_hud = HUD.new()
	root.add_child(_hud)
	_hud.hide_overlay()
	for _index: int in range(4): await physics_frame
	await process_frame
	paused = true
	var catalogue = Equipment.new()
	if not _expect(catalogue.item("CLOTH-P2").name == "Cargo Pants" and catalogue.equip("CLOTH-P2") and _actor.equip_item("CLOTH-P2"), "genuine canonical Cargo Pants equips through the paused shared Player bench"):
		await _finish(); return
	_expect(_actor.hp == 100.0 and _actor.max_hp == float(catalogue.resolved_stats().max_health), "Cargo increases actual capacity without healing current100 HP")
	_expect(_actor.max_hp > 110.0 and _actor.max_hp < 110.000001, "canonical Cargo110 capacity reproduces only tiny binary64 representation excess")
	var before: Dictionary = _actor.snapshot_state()
	if not _expect(not before.is_empty(), "actual ready grounded paused Player supplies its exact complete snapshot"):
		await _finish(); return
	_hud.update_status(_actor.hp, _actor.max_hp, _actor.shells, _actor.max_shells, 0, OBJECTIVE)
	for child: Node in _hud.find_children("*", "Label", true, false):
		if (child as Label).text.begins_with("HP  "): _label = child as Label
	if not _expect(is_instance_valid(_label), "actual shared health Label is read through its native node"):
		await _finish(); return
	var bars: Array[ColorRect] = []
	for child: Node in _label.get_parent().get_children():
		if child is ColorRect: bars.append(child)
	if not _expect(bars.size() == 2, "actual native HP track and fill are retained"):
		await _finish(); return
	_track = bars[0]
	_fill = bars[1]
	_label_rect = _label.get_rect()
	_safe_rect = _hud.combat_safe_rect()
	_expect(_safe_rect.has_area() and root.get_visible_rect().size == Vector2(PORTRAIT_SIZE), "shared HUD keeps an actual protected540x1170 combat rectangle")
	_check(_actor.hp, _actor.max_hp, "HP  100 / 110", "actual unhealed Cargo Player")
	_expect(_wire() == Exact.stringify(before), "HUD update leaves the exact complete Cargo Player snapshot unchanged")
	# Explicit initial TEST ONLY paused public seed; no live heal/gameplay claim.
	var full: Dictionary = before.duplicate(true)
	full.resources.hp = _actor.max_hp
	if not _expect(_actor.restore_state(full), "public paused Player restore seeds genuine full Cargo capacity for display only"):
		await _finish(); return
	var seeded_wire: String = _wire()
	_check(_actor.hp, _actor.max_hp, "HP  110 / 110", "actual full Cargo Player")
	for values: Array in [
		[110.25, 110.25, "HP  111 / 111"],
		[110.000001, 110.000001, "HP  111 / 111"],
		[109.25, 110.25, "HP  110 / 111"],
		[100.00000000000001, 110.00000000000001, "HP  100 / 110"],
		[0.25, 0.25, "HP  1 / 1"],
		[1.0e-300, 1.0e-300, "HP  1 / 1"],
		[0.0, 0.0, "HP  0 / 0"],
		[-2.0, -0.25, "HP  0 / 0"],
		[1.000001, 2.25, "HP  2 / 3"]
	]:
		_check(values[0], values[1], values[2], "display-only numeric control " + str(values[0]) + " / " + str(values[1]))
	_expect(paused and _wire() == seeded_wire, "all fractional/zero/tiny HUD controls preserve exact Player HP, gear, clocks, history and snapshot")
	_check(_actor.hp, _actor.max_hp, "HP  110 / 110", "restored actual Cargo display after controls")
	if portrait:
		await RenderingServer.frame_post_draw
		var path: String = "res://.cinder/hud-health-rounding-%d-%d.png" % [OS.get_process_id(), Time.get_ticks_usec()]
		var image: Image = root.get_texture().get_image()
		_expect(image.get_size() == PORTRAIT_SIZE and image.save_png(path) == OK, "one actual native540x1170 shared HUD GUI capture saves to isolated test path")
		print("HUD health capture: ", ProjectSettings.globalize_path(path))
		_expect(_wire() == seeded_wire, "native draw of the paused HUD changes no actual Player state")
	await _finish()


func _check(hp: float, maximum: float, expected: String, description: String) -> void:
	_hud.update_status(hp, maximum, _actor.shells, _actor.max_shells, 0, OBJECTIVE)
	_expect(_label.text == expected, description + " reads exact native label text " + expected)
	var width: float = Vector2(_track.size.x * clampf(hp / maxf(maximum, 1.0), 0.0, 1.0), 0.0).x
	_expect(_fill.size.x == width, description + " retains the raw unrounded health-bar fraction")
	_expect(_label.get_rect() == _label_rect and _hud.combat_safe_rect() == _safe_rect, description + " changes neither label layout nor protected combat geometry")


func _wire() -> String:
	return Exact.stringify(_actor.snapshot_state())


func _expect(condition: bool, description: String) -> bool:
	_checks += 1
	if condition: print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
	return condition


func _finish() -> void:
	if is_instance_valid(_hud): _hud.free()
	if is_instance_valid(_arena): _arena.free()
	if is_instance_valid(_background): _background.free()
	paused = false
	await process_frame
	print("HUD health rounding smoke: %d checks, %d failures; TEST ONLY GUI/paused Cargo actor, no gameplay route" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
