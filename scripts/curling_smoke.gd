class_name CurlingSmoke
extends Node3D
## Decorative smoke only. One connected dash plume follows the actual dash
## path; legacy sweep clouds retain their authored curls. There is no blur.

signal finished(effect: Node3D)

const WIDTH: int = 40
const HEIGHT: int = 36
const DASH_WIDTH: int = 80
const DASH_HEIGHT: int = 32
const FRAME_COUNT: int = 16
const PIXEL_SIZE: float = 0.045
const DASH_LIFETIME: float = 0.80
const SWEEP_LIFETIME: float = 0.72
const SHADOW: Color = Color("68737e")
const BODY: Color = Color("929ea7")
const LIGHT: Color = Color("cbd1d5")

static var _shared_frames: Dictionary = {}

var style: String = "dash"
var lifetime: float = DASH_LIFETIME
var elapsed: float = 0.0
var frame_index: int = 0
var trail_length_world: float = 0.0
var projected_length_world: float = 0.0
var projected_axis: Vector3 = Vector3.LEFT
var head_world: Vector3 = Vector3.ZERO
var tail_world: Vector3 = Vector3.ZERO
var emitter_tracking: bool = false
var _delay: float = 0.0
var _age: float = 0.0
var _flow_direction: Vector3 = Vector3.LEFT
var _origin: Vector3
var _sprite: Sprite3D
var _frames: Array[Texture2D] = []
var _emitter: Node3D
var _emitter_offset: Vector3 = Vector3.ZERO
var _tracking_duration: float = 0.0
var _tracking_elapsed: float = 0.0
var _physics_driven_tracking: bool = false


func configure(kind: String, direction: Vector3, delay: float = 0.0) -> void:
	style = "sweep" if kind == "sweep" else "dash"
	lifetime = SWEEP_LIFETIME if style == "sweep" else DASH_LIFETIME
	_flow_direction = Vector3(direction.x, 0.0, direction.z).normalized()
	if _flow_direction.length_squared() < 0.001:
		_flow_direction = Vector3.LEFT
	_delay = maxf(delay, 0.0)


func track_emitter(source: Node3D, dash_duration: float, physics_driven: bool = false) -> void:
	if style != "dash" or source == null:
		return
	_emitter = source
	_emitter_offset = global_position - source.global_position
	_tracking_duration = maxf(dash_duration, 0.001)
	_tracking_elapsed = 0.0
	_physics_driven_tracking = physics_driven
	emitter_tracking = true
	head_world = source.global_position + _emitter_offset
	tail_world = head_world
	_update_dash_geometry()


func sample_emitter() -> void:
	if not emitter_tracking:
		return
	if _emitter != null and is_instance_valid(_emitter):
		head_world = _emitter.global_position + _emitter_offset
	_update_dash_geometry()


func finish_tracking() -> void:
	# The controller calls this after the last dash physics step. It latches
	# that actual landing even when a render frame spans more than one action.
	sample_emitter()
	emitter_tracking = false
	_update_dash_geometry()


func _ready() -> void:
	_origin = global_position
	_frames = frames_for(style)
	_sprite = Sprite3D.new()
	_sprite.name = "PixelSmoke"
	_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED if style == "dash" else BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.pixel_size = PIXEL_SIZE
	_sprite.shaded = false
	_sprite.no_depth_test = false
	_sprite.render_priority = -3
	if style == "dash":
		# Source texel (3,16) is at the tracked ground attachment. An explicit
		# camera-facing basis permits full screen-plane roll for any world dash.
		_sprite.offset = Vector2(float(DASH_WIDTH) * 0.5 - 3.5, 0.5)
		if not emitter_tracking:
			head_world = _origin
			tail_world = _origin + _flow_direction * 2.7
		add_to_group("decorative_dash_plume")
	else:
		var camera: Camera3D = get_viewport().get_camera_3d()
		var screen_right: Vector3 = camera.global_basis.x if camera != null else Vector3.RIGHT
		_sprite.flip_h = _flow_direction.dot(screen_right) < 0.0
		_sprite.offset = Vector2((float(WIDTH) * 0.5 - 5.0) * (-1.0 if _sprite.flip_h else 1.0), float(HEIGHT) * 0.5 - 2.0)
	_sprite.texture = _frames[0]
	_sprite.visible = _delay <= 0.0
	_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_sprite)
	add_to_group("decorative_smoke")
	if style == "dash":
		_update_dash_geometry()


func _process(delta: float) -> void:
	_age += delta
	if _age < _delay:
		return
	_sprite.visible = true
	elapsed = _age - _delay
	if elapsed >= lifetime:
		finished.emit(self)
		queue_free()
		return
	var progress: float = elapsed / lifetime
	frame_index = mini(int(progress * float(FRAME_COUNT)), FRAME_COUNT - 1)
	_sprite.texture = _frames[frame_index]
	if style == "dash":
		if emitter_tracking and not _physics_driven_tracking:
			# Standalone emitters use a bounded render clock. The player supplies
			# physics samples and the actual landing explicitly, so a slow render
			# frame cannot retire tracking before its final movement step.
			sample_emitter()
			_tracking_elapsed += delta
			if _tracking_elapsed >= _tracking_duration or not is_instance_valid(_emitter):
				emitter_tracking = false
		_update_dash_geometry()
		return
	# Buoyant drift supplements the internal rolling flow. The emitter never
	# follows the actor, alters a hit shape or pushes any physics body.
	global_position = _origin + _flow_direction * (0.40 * elapsed) + Vector3.UP * (0.20 * elapsed)


func _update_dash_geometry() -> void:
	if _sprite == null:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	var right: Vector3 = camera.global_basis.x.normalized() if camera != null else Vector3.RIGHT
	var up: Vector3 = camera.global_basis.y.normalized() if camera != null else Vector3.UP
	var normal: Vector3 = camera.global_basis.z.normalized() if camera != null else Vector3.BACK
	var path: Vector3 = tail_world - head_world
	trail_length_world = Vector2(path.x, path.z).length()
	var projected: Vector3 = right * path.dot(right) + up * path.dot(up)
	projected_length_world = projected.length()
	if projected_length_world > 0.001:
		projected_axis = projected / projected_length_world
	else:
		var flow_projected: Vector3 = right * _flow_direction.dot(right) + up * _flow_direction.dot(up)
		projected_axis = flow_projected.normalized() if flow_projected.length_squared() > 0.001 else -right
	var cross_axis: Vector3 = normal.cross(projected_axis).normalized()
	var span: float = maxf(projected_length_world, 0.16)
	var width_scale: float = span / (70.0 * PIXEL_SIZE)
	# Once the actual landing is latched, both endpoints share the same small
	# buoyant drift. Neither knockback nor another dash lengthens this old plume.
	var after_tracking: float = maxf(elapsed - _tracking_duration, 0.0) if not emitter_tracking else 0.0
	var drift: Vector3 = Vector3.UP * (0.18 * after_tracking) + _flow_direction * (0.10 * after_tracking)
	global_position = _origin + drift
	_sprite.global_transform = Transform3D(Basis(projected_axis * width_scale, cross_axis, normal), head_world + drift)


static func frames_for(kind: String) -> Array[Texture2D]:
	var key: String = "sweep" if kind == "sweep" else "dash"
	if not _shared_frames.has(key):
		var generated: Array[Texture2D] = []
		for index: int in range(FRAME_COUNT):
			generated.append(ImageTexture.create_from_image(draw_frame(float(index) / float(FRAME_COUNT - 1), key)))
		_shared_frames[key] = generated
	return _shared_frames[key]


static func draw_frame(progress: float, kind: String = "dash") -> Image:
	if kind == "dash":
		return draw_dash_frame(progress)
	var image: Image = Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var fade: float = 1.0 - smoothstep(0.50, 1.0, progress)
	# Each parcel is born near the source and rolls around a rising vortex.
	# Neighbouring birth times overlap so the flow remains continuous as the
	# plume stretches. Seeded channels move with their parent parcel.
	var parcels: Array[Dictionary] = []
	var seeds: Array[Vector4] = [
		Vector4(13.0, 29.0, 4.6, 0.0), Vector4(19.0, 26.0, 6.2, 0.0),
		Vector4(25.0, 23.0, 7.0, 0.0), Vector4(28.0, 18.0, 7.3, 0.04),
		Vector4(25.0, 14.0, 6.0, 0.08), Vector4(18.0, 22.0, 5.1, 0.02)
	]
	for index: int in range(seeds.size()):
		var seed: Vector4 = seeds[index]
		var age: float = maxf(progress - seed.w, 0.0)
		if progress < seed.w:
			continue
		var grown: float = clampf(0.55 + age * 2.4, 0.0, 1.0)
		var breakup: float = 1.0 - 0.55 * smoothstep(0.64, 1.0, progress)
		var vortex: Vector2 = Vector2(24.0, 23.0 - progress * 6.0)
		var relative: Vector2 = Vector2(seed.x, seed.y) - vortex
		var angle: float = age * (1.30 if index % 2 == 0 else 0.90)
		var rolled: Vector2 = relative.rotated(-angle)
		var centre: Vector2 = vortex + rolled + Vector2(age * 2.0, -age * 5.0)
		if kind == "sweep":
			centre.x += sin(progress * PI) * 2.0
			centre.y += 2.0
		var radius: Vector2 = Vector2(seed.z, seed.z * (0.68 if index < 2 else 0.95)) * grown * breakup
		parcels.append({"centre": centre, "radius": radius, "age": age, "index": index})
	for y: int in range(HEIGHT):
		for x: int in range(WIDTH):
			var point: Vector2 = Vector2(x, y) + Vector2.ONE * 0.5
			var selected: Color = Color.TRANSPARENT
			for parcel: Dictionary in parcels:
				var centre: Vector2 = parcel.centre
				var radius: Vector2 = parcel.radius
				var relative: Vector2 = (point - centre) / radius
				var distance: float = relative.length_squared()
				if distance > 1.0:
					continue
				# Hard palette bands make broad pixel clusters rather than blur.
				var shade: Color = SHADOW
				if distance < 0.78 and relative.x < 0.52:
					shade = BODY
				if distance < 0.55 and relative.x < 0.14:
					shade = LIGHT
				# A small off-centre flank crescent suggests the curl; the body
				# remains solid smoke volume, never an outlined ring or hole.
				var curl: Vector2 = relative - Vector2(0.52 + sin(float(parcel.age) * 4.0) * 0.08, 0.30)
				if curl.length_squared() < 0.07 and relative.y > 0.13:
					shade = SHADOW
				shade.a = (0.46 if shade == SHADOW else (0.72 if shade == LIGHT else 0.64)) * fade
				selected = shade
			if selected.a > 0.0:
				image.set_pixel(x, y, selected)
	# The low tongue tapers into the original emission point. It bends into the
	# body, then tears away as the billows detach, instead of scaling one blob.
	if progress < 0.72:
		for step: int in range(19):
			var t: float = float(step) / 18.0
			var cx: float = 4.0 + t * 17.0 + sin(t * PI) * progress * 3.0
			var cy: float = 33.0 - t * t * (7.0 + progress * 8.0) - sin(t * PI) * progress * 4.0
			var width: int = int(t * 1.8)
			var thickness: int = 0 if t < 0.5 else 1
			for dx: int in range(-width, width + 1):
				for dy: int in range(-thickness, thickness + 1):
					var px: int = int(cx) + dx
					var py: int = int(cy) + dy
					if px >= 0 and px < WIDTH and py >= 0 and py < HEIGHT:
						image.set_pixel(px, py, Color(BODY.r, BODY.g, BODY.b, 0.50 * fade * (1.0 - smoothstep(0.50, 0.72, progress))))
	# Detached, shrinking wisps are independent parcels during late breakup.
	if progress > 0.52:
		for index: int in range(5):
			var age: float = (progress - 0.52) / 0.48
			var centre: Vector2 = Vector2(12.0 + float(index) * 4.6 + sin(age * 3.0 + index) * 2.0, 22.0 - float(index % 3) * 4.0 - age * 11.0)
			var radius: float = (2.3 - age * 1.3) * (0.75 + float(index % 2) * 0.3)
			for y: int in range(maxi(0, int(centre.y - radius)), mini(HEIGHT, int(centre.y + radius) + 2)):
				for x: int in range(maxi(0, int(centre.x - radius)), mini(WIDTH, int(centre.x + radius) + 2)):
					if Vector2(x, y).distance_squared_to(centre) <= radius * radius:
						image.set_pixel(x, y, Color(BODY.r, BODY.g, BODY.b, 0.48 * fade))
	return image


static func draw_dash_frame(progress: float) -> Image:
	var image: Image = Image.create(DASH_WIDTH, DASH_HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var fade: float = 1.0 - smoothstep(0.50, 1.0, progress)
	var breakup: float = smoothstep(0.60, 1.0, progress)
	# One long volume, rather than overlapping circular emissions. The narrow
	# source grows into a rolling body and tapers along the last ten texels.
	# World geometry stretches this authored stream over the actual dash path.
	for x: int in range(3, 78):
		var u: float = clampf(float(x - 3) / 70.0, 0.0, 1.0)
		var wave: float = sin(u * TAU * 1.20 - progress * TAU * 1.10)
		var centre: float = 16.0 + wave * (0.8 + u * 2.3) - progress * u * 2.0
		var source_growth: float = smoothstep(0.0, 0.18, u)
		var taper: float = 1.0 - smoothstep(0.79, 1.06, u)
		var radius: float = (1.0 + source_growth * (4.8 + sin(u * TAU * 2.2 - progress * TAU) * 1.0)) * taper
		radius *= 1.0 - breakup * 0.34
		for y: int in range(DASH_HEIGHT):
			var relative: float = (float(y) - centre) / maxf(radius, 0.6)
			if absf(relative) > 1.0:
				continue
			# Late rifts travel with the flow instead of spawning new particles.
			var tear: float = sin(u * TAU * 4.0 - progress * TAU * 1.4)
			if breakup > 0.0 and u > 0.12 and tear > 1.0 - breakup * 0.62 and relative > -0.52:
				continue
			var shade: Color = SHADOW
			if relative < 0.55 and absf(relative) < 0.80:
				shade = BODY
			if relative < -0.08 and relative > -0.65:
				shade = LIGHT
			# Short nested palette crescents suggest circulation inside the
			# connected body. They do not cut transparent donut holes.
			var curl: float = sin(u * TAU * 3.0 - progress * TAU * 1.25 + relative * 1.8)
			if curl > 0.80 and absf(relative) < 0.48 and u > 0.15:
				shade = SHADOW
			shade.a = (0.40 if shade == SHADOW else (0.62 if shade == LIGHT else 0.54)) * fade
			image.set_pixel(x, y, shade)
	return image
