class_name LabSprite
extends Sprite3D
## Small procedural pixel character shared by the top-down actors.

const WIDTH: int = 24
const HEIGHT: int = 32
const DARK: Color = Color(0.055, 0.045, 0.065)
const DEEP_RED: Color = Color(0.25, 0.025, 0.045)
const CRIMSON: Color = Color(0.68, 0.035, 0.075)
const BRIGHT_RED: Color = Color(1.0, 0.13, 0.15)
const IVORY: Color = Color(0.92, 0.85, 0.81)

var _kind: String = "player"
var _direction: int = 0 # 0 front, 1 back, 2 left, 3 right.
var _frame: int = 0
var _animation_time: float = 0.0
var _textures: Array[Texture2D] = []


func setup(kind: String = "player") -> void:
	_kind = kind
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	pixel_size = 0.045
	position.y = 0.8
	_textures.clear()
	for direction: int in range(4):
		for frame: int in range(2):
			_textures.append(_draw_sprite(direction, frame))
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


func _show_frame() -> void:
	if _textures.size() == 8:
		texture = _textures[_direction * 2 + _frame]


func _draw_sprite(direction: int, frame: int) -> Texture2D:
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
	for row: int in range(y, mini(y + height, HEIGHT)):
		for column: int in range(x, mini(x + width, WIDTH)):
			image.set_pixel(column, row, color)
