@tool
class_name LabSprite
extends Sprite3D
## Shared pixel actor. Presentation changes artwork only; all action poses follow
## the same controller-owned progress and retain their equipment attachments.

const Presentations = preload("res://scripts/character/player_presentations.gd")
const PRESENTATION_IDS: Array[String] = Presentations.IDS

const WIDTH: int = 24
const HEIGHT: int = 32
const PLAYER_WIDTH: int = 48
const PLAYER_HEIGHT: int = 64
const DARK: Color = Color(0.055, 0.045, 0.065)
const DEEP_RED: Color = Color(0.25, 0.025, 0.045)
const CRIMSON: Color = Color(0.68, 0.035, 0.075)
const BRIGHT_RED: Color = Color(1.0, 0.13, 0.15)
const IVORY: Color = Color(0.92, 0.85, 0.81)
const COAL: Color = Color("17191e")
const SILVER: Color = Color("889097")
const MOON_WHITE: Color = Color("f4efe3")
const CLOTH: Color = Color("c6c8c0")
const SKIN: Color = Color("b8a895")
const PLAYER_STATES: Array[String] = ["idle", "dash", "landing", "primary", "blast", "hurt"]
const PLAYER_FRAME_COUNTS: Dictionary = {"idle": 8, "dash": 6, "landing": 6, "primary": 8, "blast": 8, "hurt": 6}
const IDLE_LOOP_S: float = 1.2
const SUIT_WHITE: Color = Color("f4f1e8")
const SUIT_LIGHT: Color = Color("cbd9dd")
const SUIT_SHADE: Color = Color("8498a8")
const SUIT_DARK: Color = Color("354354")
const VISOR: Color = Color("172447")
const VISOR_LIGHT: Color = Color("293b62")
const SUIT_TRIM: Color = Color("9c3d42")

@export var actor_kind: String = "player"
@export var weapon_visual_id: String = "WEAPON-01"
@export var jacket_visual_id: String = "CLOTH-J0"
@export var pants_visual_id: String = "CLOTH-P0"
@export var shoes_visual_id: String = "CLOTH-S0"

var _kind: String = "player"
var _direction: int = 0 # 0 front, 1 back, 2 left, 3 right.
var _frame: int = 0
var _animation_time: float = 0.0
var _textures: Array[Texture2D] = []
var _player_textures: Dictionary = {}
var _action: String = "idle"
var _action_frame: int = 0
var _explicit_action: bool = false
var _presentation_id: String = "helmeted_lab"
var presentation_id: String:
	get:
		return _presentation_id

## One native idle pose for menus, using the same draw path and carried gear.
## No scene actor, collider, animation clock or full atlas is created.
static func preview_texture(id: String, loadout: Dictionary) -> Texture2D:
	if not PRESENTATION_IDS.has(id):
		return null
	var equipment = preload("res://scripts/equipment.gd").new()
	if not equipment.restore(loadout):
		return null
	var renderer := LabSprite.new()
	renderer._presentation_id = id
	renderer.weapon_visual_id = loadout.weapon
	renderer.jacket_visual_id = loadout.jacket
	renderer.pants_visual_id = loadout.pants
	renderer.shoes_visual_id = loadout.shoes
	var result: Texture2D = ImageTexture.create_from_image(renderer._draw_player_image(0, "idle", 0))
	renderer.free()
	return result

func set_presentation(id: String) -> bool:
	if not PRESENTATION_IDS.has(id) or _kind != "player":
		return false
	if id == _presentation_id:
		return true
	_presentation_id = id
	_rebuild_player_textures()
	_show_frame()
	return true

static func presentation_for_act(act: int) -> String:
	return Presentations.for_act(act)


func _ready() -> void:
	if _textures.is_empty() and _player_textures.is_empty():
		setup(actor_kind)


func setup(kind: String = "player") -> void:
	_kind = kind
	actor_kind = kind
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	pixel_size = 0.0225 if kind == "player" else 0.045
	# Offset the quad itself so billboarding rotates around its feet.
	offset = Vector2(0, PLAYER_HEIGHT * 0.5) if kind == "player" else Vector2.ZERO
	position.y = 0.025 if kind == "player" else 0.8
	_textures.clear()
	if kind == "player":
		_rebuild_player_textures()
	else:
		for direction: int in range(4):
			for frame: int in range(2):
				_textures.append(_draw_sprite(direction, frame))
	_show_frame()


func set_loadout_visual(weapon_id: String, jacket_id: String, pants_id: String, shoes_id: String) -> void:
	if [weapon_visual_id, jacket_visual_id, pants_visual_id, shoes_visual_id] == [weapon_id, jacket_id, pants_id, shoes_id]:
		return
	weapon_visual_id = weapon_id
	jacket_visual_id = jacket_id
	pants_visual_id = pants_id
	shoes_visual_id = shoes_id
	if _kind == "player":
		_rebuild_player_textures()
		_show_frame()


func set_action(state: String, progress: float = 0.0) -> void:
	if _kind != "player":
		return
	_explicit_action = true
	var next_state: String = state if state in PLAYER_STATES else "idle"
	var count: int = PLAYER_FRAME_COUNTS[next_state]
	var next_frame: int = mini(int(clampf(progress, 0.0, 1.0) * count), count - 1)
	if next_state == "idle":
		next_frame = _action_frame if _action == "idle" else 0
	else:
		_animation_time = 0.0
	if next_state != _action or next_frame != _action_frame:
		_action = next_state
		_action_frame = next_frame
		_show_frame()


func face(direction: Vector3) -> void:
	if absf(direction.x) + absf(direction.z) < 0.01:
		return
	var next_direction: int
	if absf(direction.x) > absf(direction.z):
		next_direction = 3 if direction.x > 0.0 else 2
	else:
		next_direction = 0 if direction.z > 0.0 else 1
	if next_direction != _direction:
		_direction = next_direction
		_show_frame()


func animate(moving: bool, delta: float) -> void:
	if _kind == "player":
		if not _explicit_action:
			_action = "dash" if moving else "idle"
		# Only the quiet breathing loop owns a local simulation clock. Every
		# action pose follows the controller's visual progress and is never reset here.
		if _action == "idle":
			_animation_time = fmod(_animation_time + delta, IDLE_LOOP_S)
			var next_frame: int = int(_animation_time / IDLE_LOOP_S * PLAYER_FRAME_COUNTS["idle"])
			if next_frame != _action_frame:
				_action_frame = next_frame
				_show_frame()
		elif not _explicit_action:
			_action_frame = 0
			_show_frame()
		return
	if moving:
		_animation_time += delta
		var next_frame: int = int(_animation_time * 5.0) % 2
		if next_frame != _frame:
			_frame = next_frame
			_show_frame()
	else:
		_animation_time = 0.0
		if _frame != 0:
			_frame = 0
			_show_frame()
	position.y = 0.82 if moving and _frame == 1 else 0.8


func get_muzzle_pixel_position() -> Vector2i:
	# The same rounded centreline endpoint authored into the blast texture.
	# Quiet poses return the ready-to-fire attachment; during recoil this moves
	# with the current rendered hand and barrel instead of an arbitrary offset.
	var frame: int = clampi(_action_frame, 0, PLAYER_FRAME_COUNTS["blast"] - 1) if _action == "blast" else 0
	var crouch: int = [0, 0, 1, 1, 1, 1, 0, 0][frame]
	var pose: Dictionary = _weapon_pose(_direction, "blast", frame, 0, 25 + crouch)
	var angle: float = pose["angle"]
	return Vector2i((Vector2(pose["hand"]) + Vector2(cos(angle), sin(angle)) * 11.0).round())


func get_muzzle_world_position(camera: Camera3D) -> Vector3:
	if _kind != "player":
		return global_position
	var tip: Vector2 = Vector2(get_muzzle_pixel_position()) + Vector2.ONE * 0.5
	var x: float = (tip.x - float(PLAYER_WIDTH) * 0.5 + offset.x) * pixel_size
	var y: float = (float(PLAYER_HEIGHT) * 0.5 - tip.y + offset.y) * pixel_size
	var right: Vector3 = camera.global_basis.x.normalized() if camera != null else global_basis.x.normalized()
	var up: Vector3 = camera.global_basis.y.normalized() if camera != null else global_basis.y.normalized()
	return global_position + right * x * global_basis.x.length() + up * y * global_basis.y.length()


func _show_frame() -> void:
	if _kind == "player" and not _player_textures.is_empty():
		texture = _player_textures["%s_%d_%d" % [_action, _direction, _action_frame]]
	elif _textures.size() == 8:
		texture = _textures[_direction * 2 + _frame]


func _rebuild_player_textures() -> void:
	_player_textures.clear()
	for state: String in PLAYER_STATES:
		for direction: int in range(4):
			for frame: int in range(PLAYER_FRAME_COUNTS[state]):
				_player_textures["%s_%d_%d" % [state, direction, frame]] = ImageTexture.create_from_image(_draw_player_image(direction, state, frame))


func _draw_player_image(direction: int, state: String, frame: int) -> Image:
	var image := Image.create(PLAYER_WIDTH, PLAYER_HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var crouch: int = 0
	var lean: int = 0
	var breath: int = 0
	match state:
		"idle":
			breath = [0, 0, 1, 2, 2, 1, 1, 0][frame]
		"dash":
			crouch = [0, 1, 1, 1, 0, 0][frame]
			lean = [1, 2, 3, 3, 2, 1][frame]
		"landing":
			crouch = [3, 2, 2, 1, 1, 0][frame]
		"primary":
			crouch = [0, 1, 2, 2, 1, 1, 0, 0][frame]
		"blast":
			crouch = [0, 0, 1, 1, 1, 1, 0, 0][frame]
		"hurt":
			crouch = [2, 2, 1, 1, 0, 0][frame]
			lean = -[2, 2, 1, 1, 0, 0][frame]
	if direction == 2:
		lean = -lean
	elif direction == 0 or direction == 1:
		lean = 0
	var torso_y: int = 25 + crouch - breath
	if _presentation_id != "helmeted_lab":
		var pose: Dictionary = _weapon_pose(direction, state, frame, lean, torso_y)
		Presentations.draw_body(image, _presentation_id, direction, state, frame, lean, crouch, breath, torso_y, pose, {"jacket": jacket_visual_id, "pants": pants_visual_id, "shoes": shoes_visual_id})
		_draw_weapon(image, direction, state, frame, pose)
		Presentations.finish_palette(image, _presentation_id)
		return image
	var jacket: Color = SUIT_WHITE
	var pants: Color = SUIT_LIGHT
	var trim: Color = SUIT_TRIM
	if jacket_visual_id == "CLOTH-J1":
		jacket = SUIT_LIGHT
	elif jacket_visual_id == "CLOTH-J2":
		jacket = Color("eee7d4")
		trim = Color("8b6b45")
	elif jacket_visual_id == "CLOTH-J3":
		jacket = SUIT_LIGHT.darkened(0.18)
	if pants_visual_id == "CLOTH-P1":
		pants = SUIT_WHITE
	elif pants_visual_id == "CLOTH-P2":
		pants = Color("a9b9bd")

	# Separate reinforced trousers, cuffs and weighted boots. The floor pivot
	# remains (24,64), including every lean, crouch and stride frame.
	var legs: Array = [16, 27]
	var raised_leg: int = -1
	if state == "dash":
		legs = [[12, 29], [10, 31], [11, 30], [13, 29], [15, 28], [16, 27]][frame]
		raised_leg = 1 if frame < 3 else 0
	for index: int in range(2):
		var x: int = legs[index]
		var lift: int = 2 if index == raised_leg else 0
		_rounded_rect(image, x - 1, 43 + crouch, 10, 16 - crouch - lift, 2, COAL)
		_rounded_rect(image, x, 44 + crouch, 8, 13 - crouch - lift, 1, pants)
		_rect(image, x + 5, 45 + crouch, 2, 11 - crouch - lift, SUIT_SHADE)
		_rect(image, x, 47 + crouch, 8, 2, trim)
		_rounded_rect(image, x + 1, 50 + crouch, 6, 6 - crouch, 1, SUIT_DARK)
		_rect(image, x + 2, 51 + crouch, 4, 4 - crouch, SUIT_WHITE)
		if pants_visual_id == "CLOTH-P2":
			_rect(image, x - 1, 45 + crouch, 3, 4, SUIT_DARK)
			_rect(image, x, 46 + crouch, 2, 2, SUIT_LIGHT)
		elif pants_visual_id == "CLOTH-P1":
			_rect(image, x + 3, 44 + crouch, 1, 4, SUIT_DARK)
		_draw_boot(image, x - 2, 56 - lift, index)

	# The compact pack is a silhouette layer, with one family in all facings.
	if direction == 2 or direction == 3:
		var pack_x: int = 30 + lean if direction == 2 else 11 + lean
		_rounded_rect(image, pack_x, torso_y - 2, 8, 21 - crouch, 2, COAL)
		_rect(image, pack_x + 1, torso_y, 6, 17 - crouch, SUIT_SHADE)
		_rect(image, pack_x + 2, torso_y + 1, 4, 5, SUIT_LIGHT)
		_rect(image, pack_x + 1, torso_y + 8, 6, 2, SUIT_DARK)

	var body_x: int = (16 if direction > 1 else 13) + lean
	var body_width: int = 17 if direction > 1 else 23
	if jacket_visual_id == "CLOTH-J1":
		body_x -= 1
		body_width += 2
	_rounded_rect(image, body_x, torso_y, body_width, 22 - crouch, 3, COAL)
	_rounded_rect(image, body_x + 1, torso_y + 1, body_width - 2, 19 - crouch, 2, jacket)
	_rect(image, body_x + body_width - 5, torso_y + 3, 3, 14 - crouch, SUIT_SHADE)
	_rect(image, body_x + 2, torso_y + 3, 2, 13 - crouch, SUIT_LIGHT)
	_rect(image, body_x + 2, torso_y + 16 - crouch, body_width - 4, 3, SUIT_DARK)
	_rect(image, 21 + lean, torso_y + 16 - crouch, 8, 3, SUIT_LIGHT)
	_rect(image, 23 + lean, torso_y + 17 - crouch, 4, 1, SUIT_WHITE)
	if direction == 1:
		_rounded_rect(image, 17 + lean, torso_y + 2, 15, 15 - crouch, 2, SUIT_DARK)
		_rect(image, 19 + lean, torso_y + 3, 11, 12 - crouch, SUIT_SHADE)
		_rect(image, 20 + lean, torso_y + 4, 9, 3, SUIT_LIGHT)
		_rect(image, 22 + lean, torso_y + 8, 5, 1, COAL)
		_rect(image, 22 + lean, torso_y + 11, 5, 1, COAL)
		_rect(image, 19 + lean, torso_y + 14 - crouch, 3, 2, SUIT_DARK)
		_rect(image, 27 + lean, torso_y + 14 - crouch, 3, 2, SUIT_DARK)
	elif direction == 0:
		_draw_chest_unit(image, 20 + lean, torso_y + 5, trim)
		_line(image, Vector2i(16 + lean, torso_y + 7), Vector2i(16 + lean, torso_y + 12), SUIT_SHADE, 2)
		_line(image, Vector2i(16 + lean, torso_y + 12), Vector2i(20 + lean, torso_y + 15), SUIT_SHADE, 2)
		_rect(image, 32 + lean, torso_y + 8, 2, 6, SUIT_DARK)
	else:
		var chest_x: int = 16 + lean if direction == 2 else 30 + lean
		_rounded_rect(image, chest_x, torso_y + 5, 4, 9, 1, SUIT_DARK)
		_rect(image, chest_x + 1, torso_y + 6, 2, 3, SUIT_WHITE)
		_rect(image, chest_x + 1, torso_y + 6, 2, 2, trim)
		_rect(image, chest_x + 1, torso_y + 11, 2, 2, COAL)
	if jacket_visual_id == "CLOTH-J1":
		_rect(image, body_x + 2, torso_y + 3, 5, 2, SUIT_WHITE)
		_rect(image, body_x + body_width - 7, torso_y + 3, 5, 2, SUIT_WHITE)
		_rect(image, body_x + 2, torso_y + 10, 3, 2, SUIT_SHADE)
	elif jacket_visual_id == "CLOTH-J2":
		_rect(image, body_x + 4, torso_y + 3, 1, 12 - crouch, trim)
		_rect(image, body_x + body_width - 6, torso_y + 3, 1, 12 - crouch, trim)

	var active_pose: Dictionary = _weapon_pose(direction, state, frame, lean, torso_y)
	var active_hand: Vector2i = active_pose["hand"]
	var left_hand := Vector2i(11 + lean, torso_y + 18 - crouch)
	var right_hand := Vector2i(37 + lean, torso_y + 18 - crouch)
	if state == "idle":
		var breathing_arm: int = [0, 1, 1, 1, 0, -1, -1, 0][frame]
		left_hand.x += breathing_arm
		right_hand.x -= breathing_arm
	if state == "dash":
		left_hand.y -= [1, 3, 4, 3, 2, 0][frame]
	if state == "primary" or state == "blast":
		if direction == 2:
			left_hand = active_hand
		else:
			right_hand = active_hand
		if state == "blast":
			left_hand = active_hand + Vector2i(-3, 2) if direction != 2 else active_hand
	_draw_arm(image, Vector2i(16 + lean, torso_y + 4), left_hand, jacket, trim)
	_draw_arm(image, Vector2i(33 + lean, torso_y + 4), right_hand, jacket, trim)

	# This lab presentation uses a neck seal and helmet; campaign headwear is
	# selected from act art and does not alter shared collision or action clocks.
	_rounded_rect(image, 17 + lean, torso_y - 4, 15, 6, 2, COAL)
	_rect(image, 19 + lean, torso_y - 3, 11, 2, SUIT_WHITE)
	_rect(image, 20 + lean, torso_y - 1, 9, 1, SUIT_SHADE)
	_draw_helmet(image, direction, 24 + lean, 14 + crouch - breath)
	_draw_weapon(image, direction, state, frame, active_pose)
	return image


func _draw_helmet(image: Image, direction: int, cx: int, cy: int) -> void:
	_ellipse(image, cx, cy, 12, 12, COAL)
	_ellipse(image, cx, cy - 1, 11, 11, SUIT_SHADE)
	_ellipse(image, cx - 1, cy - 2, 10, 9, SUIT_WHITE)
	_rect(image, cx - 4, cy - 11, 8, 2, SUIT_WHITE)
	_rect(image, cx - 7, cy - 8, 3, 2, SUIT_LIGHT)
	_rect(image, cx + 8, cy - 4, 2, 9, SUIT_SHADE)
	_rect(image, cx - 5, cy + 9, 10, 2, SUIT_WHITE)
	if direction == 1:
		# Rear shell seam, connection plate and catches distinguish it from visor.
		_ellipse(image, cx, cy - 1, 8, 8, SUIT_LIGHT)
		_ellipse(image, cx - 1, cy - 2, 7, 7, SUIT_WHITE)
		_rect(image, cx - 5, cy - 8, 10, 1, SUIT_SHADE)
		_rect(image, cx - 5, cy + 5, 10, 3, SUIT_DARK)
		_rect(image, cx - 4, cy + 5, 8, 1, SUIT_LIGHT)
		_rect(image, cx - 12, cy - 2, 3, 7, COAL)
		_rect(image, cx - 11, cy - 1, 1, 4, SUIT_WHITE)
		_rect(image, cx + 10, cy - 2, 3, 7, COAL)
		_rect(image, cx + 11, cy - 1, 1, 4, SUIT_WHITE)
		return
	var visor_cx: int = cx if direction == 0 else cx + (-3 if direction == 2 else 3)
	var visor_rx: int = 9 if direction == 0 else 7
	_ellipse(image, visor_cx, cy + 1, visor_rx + 1, 9, SUIT_DARK)
	_ellipse(image, visor_cx, cy + 1, visor_rx, 8, COAL)
	_ellipse(image, visor_cx, cy, visor_rx - 1, 7, VISOR)
	_ellipse(image, visor_cx + 2, cy - 2, visor_rx - 3, 5, VISOR_LIGHT)
	# Two deliberate reflection clusters, rather than noisy surface pixels.
	_rect(image, visor_cx + 2, cy - 5, 3, 2, SUIT_WHITE)
	_rect(image, visor_cx + 4, cy - 3, 2, 3, SUIT_WHITE)
	_rect(image, visor_cx - visor_rx + 2, cy - 3, 1, 4, SUIT_SHADE)
	_rect(image, visor_cx - 4, cy + 6, 7, 1, VISOR_LIGHT)
	var latch_x: int = cx - 12 if direction != 2 else cx + 10
	_rect(image, latch_x, cy - 2, 3, 7, COAL)
	_rect(image, latch_x + 1, cy - 1, 1, 5, SUIT_WHITE)
	_rect(image, latch_x + 1, cy + 1, 1, 1, COAL)
	if direction == 0:
		_rect(image, cx + 10, cy - 2, 3, 7, COAL)
		_rect(image, cx + 11, cy - 1, 1, 5, SUIT_WHITE)
		_rect(image, cx + 11, cy + 1, 1, 1, COAL)


func _draw_chest_unit(image: Image, x: int, y: int, trim: Color) -> void:
	_rect(image, x - 1, y - 1, 11, 11, COAL)
	_rect(image, x, y, 9, 9, SUIT_LIGHT)
	_rect(image, x + 1, y + 1, 3, 3, trim)
	_rect(image, x + 5, y + 1, 2, 3, VISOR)
	_rect(image, x + 1, y + 5, 2, 2, SUIT_DARK)
	_rect(image, x + 4, y + 5, 3, 2, SUIT_DARK)
	_rect(image, x + 1, y + 8, 7, 1, SUIT_WHITE)


func _draw_boot(image: Image, x: int, y: int, index: int) -> void:
	var shoe_color: Color = SUIT_WHITE
	if shoes_visual_id == "CLOTH-S1":
		shoe_color = SUIT_LIGHT
	elif shoes_visual_id == "CLOTH-S2":
		shoe_color = SUIT_SHADE.lightened(0.15)
	var toe_x: int = x - 1 if index == 0 else x
	_rounded_rect(image, x, y - 1, 10, 8, 2, COAL)
	_rect(image, x + 1, y, 8, 2, SUIT_DARK)
	_rect(image, x + 2, y + 1, 6, 3, shoe_color)
	_rounded_rect(image, toe_x, y + 3, 11, 4, 1, COAL)
	_rect(image, toe_x + 1, y + 3, 9, 2, shoe_color)
	_rect(image, toe_x + 1, y + 6, 9, 1, SUIT_SHADE)
	_rect(image, toe_x + 1, y + 7, 9, 1, SUIT_DARK)
	_rect(image, x + 6, y + 1, 2, 4, SUIT_LIGHT)
	if shoes_visual_id == "CLOTH-S1":
		_rect(image, toe_x + 1, y + 4, 8, 1, Color("a7d4d8"))
	elif shoes_visual_id == "CLOTH-S2":
		_rect(image, toe_x + 1, y + 5, 9, 2, SUIT_DARK)


func _draw_arm(image: Image, shoulder: Vector2i, hand: Vector2i, jacket: Color, trim: Color) -> void:
	var elbow := Vector2i(int((shoulder.x + hand.x) * 0.5), int((shoulder.y + hand.y) * 0.5) - 1)
	_line(image, shoulder, elbow, COAL, 8)
	_line(image, elbow, hand, COAL, 7)
	_line(image, shoulder, elbow, jacket, 5)
	_line(image, elbow, hand, SUIT_LIGHT, 4)
	_rect(image, elbow.x - 3, elbow.y - 1, 6, 2, trim)
	_rect(image, elbow.x + 1, elbow.y + 2, 2, 3, SUIT_SHADE)
	_rounded_rect(image, hand.x - 3, hand.y - 1, 7, 7, 2, COAL)
	_rect(image, hand.x - 2, hand.y, 5, 3, SUIT_WHITE)
	_rect(image, hand.x - 1, hand.y + 3, 3, 2, SUIT_SHADE)
	_rect(image, hand.x + 1, hand.y + 2, 1, 2, SUIT_DARK)


func _weapon_pose(direction: int, state: String, frame: int, lean: int, torso_y: int) -> Dictionary:
	var hand := Vector2i(9 if direction == 2 else 38, torso_y + 19)
	var angle: float = -PI * 0.5
	if state == "dash":
		hand.y -= [3, 4, 5, 4, 2, 1][frame]
		angle += (-0.3 if direction == 2 else 0.3)
	elif state == "primary":
		var swing: float = [-0.45, -0.15, 0.15, 0.40, 0.65, 0.85, 0.5, 0.0][frame]
		match direction:
			0:
				hand = Vector2i(31 + lean, torso_y + 12)
				angle = PI * 0.5 + swing
			1:
				hand = Vector2i(38 + lean, torso_y + 7)
				angle = -PI * 0.5 + swing * 0.35
			2:
				hand = Vector2i(19 + lean, torso_y + 10)
				angle = PI - swing
			3:
				hand = Vector2i(29 + lean, torso_y + 10)
				angle = swing
		if frame >= 6:
			hand = Vector2i(Vector2(hand).lerp(Vector2(9 if direction == 2 else 38, torso_y + 18), 0.35 if frame == 6 else 0.7).round())
			angle = lerp_angle(angle, -PI * 0.5, 0.3 if frame == 6 else 0.65)
	elif state == "blast":
		var recoil: int = [0, 1, 2, 2, 1, 1, 0, 0][frame]
		match direction:
			0:
				hand = Vector2i(28 + lean, torso_y + 12 - recoil)
				angle = PI * 0.5 - 0.12
			1:
				hand = Vector2i(37 + lean, torso_y + 8 + recoil)
				angle = -PI * 0.5 + 0.12
			2:
				hand = Vector2i(19 + lean + recoil, torso_y + 10)
				angle = PI
			3:
				hand = Vector2i(29 + lean - recoil, torso_y + 10)
				angle = 0.0
		if frame >= 6:
			hand.y += frame - 5
			angle += -0.14 if direction == 2 else 0.14
	return {"hand": hand, "angle": angle}


func _draw_weapon(image: Image, _direction: int, state: String, _frame_index: int, pose: Dictionary) -> void:
	var hand: Vector2i = pose["hand"]
	var angle: float = pose["angle"]
	var blade_length: int = 16
	var blade_width: int = 2
	if weapon_visual_id == "WEAPON-02":
		blade_length = 13
	elif weapon_visual_id == "WEAPON-03":
		blade_length = 15
		blade_width = 4
	elif weapon_visual_id == "WEAPON-04":
		blade_length = 19
	var forward := Vector2(cos(angle), sin(angle))
	if state == "blast":
		var end := Vector2(hand) + forward * 11.0
		var stock := Vector2(hand) - forward * 4.0
		_line(image, Vector2i(stock.round()), Vector2i(end.round()), COAL, 5)
		_line(image, hand, Vector2i(end.round()), SUIT_SHADE, 3)
		_line(image, hand - Vector2i(0, 1), Vector2i((end - Vector2(0, 1)).round()), SUIT_LIGHT, 1)
		_rect(image, hand.x - 1, hand.y + 2, 3, 4, SUIT_DARK)
	else:
		var tip := Vector2(hand) + forward * blade_length
		tip.x = clampf(tip.x, 2.0, 45.0)
		tip.y = clampf(tip.y, 2.0, 61.0)
		_line(image, hand, Vector2i(tip.round()), COAL, blade_width + 2)
		_line(image, hand, Vector2i(tip.round()), SUIT_WHITE, blade_width)
		var side := Vector2(-forward.y, forward.x) * 3.0
		_line(image, Vector2i((Vector2(hand) - side).round()), Vector2i((Vector2(hand) + side).round()), SUIT_SHADE, 2)
		_line(image, hand, Vector2i((Vector2(hand) - forward * 4.0).round()), SUIT_DARK, 2)
		# The quiet attached housing makes the paired blast profile understandable.
		_rect(image, hand.x - 3, hand.y + 1, 3, 4, SUIT_DARK)


func _ellipse(image: Image, cx: int, cy: int, radius_x: int, radius_y: int, color: Color) -> void:
	for y: int in range(-radius_y, radius_y + 1):
		var normalized_y: float = float(y) / radius_y
		var extent: int = int(sqrt(maxf(0.0, 1.0 - normalized_y * normalized_y)) * radius_x)
		_rect(image, cx - extent, cy + y, extent * 2 + 1, 1, color)


func _rounded_rect(image: Image, x: int, y: int, width: int, height: int, corner: int, color: Color) -> void:
	_rect(image, x + corner, y, width - corner * 2, height, color)
	_rect(image, x, y + corner, width, height - corner * 2, color)
	if corner > 1:
		_rect(image, x + 1, y + 1, width - 2, height - 2, color)


func _line(image: Image, start: Vector2i, end: Vector2i, color: Color, thickness: int = 1) -> void:
	var steps: int = maxi(absi(end.x - start.x), absi(end.y - start.y))
	for step: int in range(steps + 1):
		var weight: float = float(step) / maxi(steps, 1)
		var point := Vector2(start).lerp(Vector2(end), weight).round()
		_rect(image, int(point.x) - thickness / 2, int(point.y) - thickness / 2, thickness, thickness, color)


func _draw_sprite(direction: int, frame: int) -> Texture2D:
	if _kind == "player":
		return ImageTexture.create_from_image(_draw_player_image(direction, "idle", 0))
	var image: Image = Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var player: bool = _kind == "player"
	var body: Color = IVORY if player else CRIMSON
	var accent: Color = BRIGHT_RED if player else IVORY
	var armor: bool = _kind == "armored"
	var hopper: bool = _kind == "hopper"

	# A dark stepped outline stays visible against red and charcoal arenas.
	_rect(image, 5, 10, 14, 14, DARK)
	_rect(image, 6, 11, 12, 11, body)
	_rect(image, 7, 2, 10, 10, DARK)
	_rect(image, 8, 3, 8, 8, DEEP_RED if not player else DARK)
	_rect(image, 3, 12, 3, 10, DARK)
	_rect(image, 18, 12, 3, 10, DARK)
	_rect(image, 4, 13, 2, 7, body)
	_rect(image, 18, 13, 2, 7, body)
	_rect(image, 7, 22, 4, 9, DARK)
	_rect(image, 13, 22, 4, 9, DARK)
	if frame == 1:
		_rect(image, 7, 27, 4, 4, body)
		_rect(image, 13, 23, 4, 5, body)
	else:
		_rect(image, 7, 23, 4, 7, body)
		_rect(image, 13, 23, 4, 7, body)
	_rect(image, 6, 29, 5, 2, DEEP_RED)
	_rect(image, 13, 29, 5, 2, DEEP_RED)

	match direction:
		0: # Front: two bright eyes above a small chest mark.
			_rect(image, 9, 6, 2, 2, accent)
			_rect(image, 13, 6, 2, 2, accent)
			_rect(image, 11, 15, 2, 5, DEEP_RED if player else DARK)
		1: # Back: broad red stripe, no eyes.
			_rect(image, 8, 4, 8, 2, accent)
			_rect(image, 11, 12, 2, 9, DEEP_RED if player else DARK)
		2: # Left profile.
			_rect(image, 8, 6, 3, 2, accent)
			_rect(image, 5, 16, 4, 3, DEEP_RED)
		3: # Right profile.
			_rect(image, 13, 6, 3, 2, accent)
			_rect(image, 15, 16, 4, 3, DEEP_RED)

	if player:
		_rect(image, 19, 8, 2, 13, IVORY)
		_rect(image, 17, 19, 5, 2, DEEP_RED)
	elif armor:
		_rect(image, 4, 11, 5, 5, DARK)
		_rect(image, 15, 11, 5, 5, DARK)
		_rect(image, 8, 14, 8, 6, DARK)
		_rect(image, 10, 15, 4, 4, CRIMSON)
	elif hopper:
		_rect(image, 10, 0, 4, 3, BRIGHT_RED)
		_rect(image, 5, 27, 3, 4, CRIMSON)
		_rect(image, 16, 27, 3, 4, CRIMSON)

	return ImageTexture.create_from_image(image)


func _rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for row: int in range(maxi(y, 0), mini(y + height, image.get_height())):
		for column: int in range(maxi(x, 0), mini(x + width, image.get_width())):
			image.set_pixel(column, row, color)
