class_name ShotgunFlare
extends Node3D
## A short barrel-attached flash and outward pellet streaks. This artwork has
## no projectile, collider or damage timing; the accepted blast is immediate.

signal finished(effect: Node3D)

const WIDTH: int = 36
const HEIGHT: int = 24
const FRAME_COUNT: int = 10
const LIFETIME: float = 0.24
const PIXEL_SIZE: float = 0.03
const SOURCE_PIXEL: Vector2 = Vector2(2.0, 12.0)
const WHITE: Color = Color("fffef1")
const YELLOW: Color = Color("fff09b")
const GOLD: Color = Color("ffd14b")
const ORANGE: Color = Color("f4892d")

static var _shared_frames: Array[Texture2D] = []

var origin: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.FORWARD
var screen_direction: Vector2 = Vector2.UP
var elapsed: float = 0.0
var lifetime: float = LIFETIME
var frame_index: int = 0
var _source: Node3D
var _camera: Camera3D
var _sprite: Sprite3D


func configure(shot_direction: Vector3, source: Node3D = null) -> void:
	direction = Vector3(shot_direction.x, 0.0, shot_direction.z).normalized()
	if direction.length_squared() < 0.001:
		direction = Vector3.FORWARD
	_source = source


func _ready() -> void:
	origin = global_position
	_camera = get_viewport().get_camera_3d()
	_sprite = Sprite3D.new()
	_sprite.name = "FlareSprite"
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.pixel_size = PIXEL_SIZE
	_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_sprite.shaded = false
	_sprite.no_depth_test = false
	_sprite.render_priority = 5
	# Align the centre of the first lit texel to the authored barrel tip.
	_sprite.offset = Vector2(float(WIDTH) * 0.5 - SOURCE_PIXEL.x - 0.5, SOURCE_PIXEL.y + 0.5 - float(HEIGHT) * 0.5)
	_sprite.texture = frames()[0]
	_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_sprite)
	add_to_group("shotgun_flares")
	_align_to_camera()


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		finished.emit(self)
		queue_free()
		return
	# Briefly follow recoil at the actual sprite barrel. Afterwards the accepted
	# shot's source stays where it was released, even if another action turns.
	if elapsed <= 0.04 and is_instance_valid(_source):
		var actor: Node = _source if _source.has_method("get_muzzle_world_position") else _source.get_node_or_null("ActorSprite")
		if actor != null and actor.has_method("get_muzzle_world_position") and String(actor.get("_action")) == "blast":
			origin = actor.call("get_muzzle_world_position", _camera)
			global_position = origin
	frame_index = mini(int(elapsed / lifetime * float(FRAME_COUNT)), FRAME_COUNT - 1)
	_sprite.texture = frames()[frame_index]
	_align_to_camera()


func _align_to_camera() -> void:
	var camera_basis: Basis = _camera.global_basis if is_instance_valid(_camera) else Basis.IDENTITY
	var projected: Vector2 = Vector2(direction.dot(camera_basis.x), direction.dot(camera_basis.y))
	if projected.length_squared() < 0.001:
		projected = Vector2(direction.x, -direction.z)
	screen_direction = projected.normalized()
	var x_axis: Vector3 = camera_basis.x * screen_direction.x + camera_basis.y * screen_direction.y
	var y_axis: Vector3 = -camera_basis.x * screen_direction.y + camera_basis.y * screen_direction.x
	_sprite.global_basis = Basis(x_axis, y_axis, camera_basis.z)
	# A tiny displacement towards the viewer avoids coplanar sprite flicker,
	# while depth testing still prevents the flash drawing through scenery.
	_sprite.global_position = origin + camera_basis.z * 0.006


static func frames() -> Array[Texture2D]:
	if _shared_frames.is_empty():
		for index: int in range(FRAME_COUNT):
			_shared_frames.append(ImageTexture.create_from_image(draw_frame(index)))
	return _shared_frames


static func draw_frame(index: int) -> Image:
	var image: Image = Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var frame: int = clampi(index, 0, FRAME_COUNT - 1)
	var strength: float = [1.0, 1.0, 0.96, 0.84, 0.69, 0.53, 0.36, 0.22, 0.10, 0.0][frame]
	if strength == 0.0:
		return image
	var progress: float = float(frame) / float(FRAME_COUNT - 1)
	var flame_length: float = [10.0, 15.0, 19.0, 21.0, 22.0, 21.0, 18.0, 14.0, 8.0, 0.0][frame]
	var source_x: int = int(SOURCE_PIXEL.x)
	var source_y: int = int(SOURCE_PIXEL.y)
	# The first two frames hold a brilliant attached core. Stepped fan edges
	# then grow outward, with alternating tongues rather than a scaled rectangle.
	for x: int in range(source_x, mini(WIDTH, source_x + int(flame_length) + 1)):
		var u: float = float(x - source_x) / flame_length
		var wing: float = 2.8 + sin(progress * PI) * 3.0
		var radius: float = 1.3 + u * wing
		if u > 0.72:
			radius *= (1.0 - u) / 0.28
		if (x + frame) % 5 == 0 and u > 0.25:
			radius += 1.0
		for y: int in range(HEIGHT):
			var height: float = absf(float(y - source_y))
			if height > radius:
				continue
			var color: Color = ORANGE
			if height < radius * 0.78:
				color = GOLD
			if height < radius * 0.50:
				color = YELLOW
			if height <= maxf(0.8, radius * 0.23) and u < 0.72:
				color = WHITE
			color.a = strength
			image.set_pixel(x, y, color)
	# Short five-way streaks fan from the same muzzle direction and separate
	# from the flare. Their finite visual travel never creates ranged damage.
	var streak_start: float = 6.0 + progress * 24.0
	var streak_length: int = 4 if frame < 6 else 3
	for spread: float in [-0.46, -0.23, 0.0, 0.23, 0.46]:
		for step: int in range(streak_length):
			var x: int = int(streak_start) + step
			var y: int = source_y + int(round(spread * float(x - source_x)))
			if x >= 0 and x < WIDTH and y >= 0 and y < HEIGHT:
				var color: Color = WHITE if step == 0 else GOLD
				color.a = strength
				image.set_pixel(x, y, color)
	return image
