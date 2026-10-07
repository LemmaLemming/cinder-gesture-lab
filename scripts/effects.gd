class_name PixelEffects
extends Node3D
## Short, asset-free combat effects. Gameplay debris collides only with the world.

const MAX_CHUNKS: int = 96
const MAX_TRANSIENTS: int = 48
const AUDIO_VOICES: int = 6
const SAMPLE_RATE: int = 22050

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _chunks: Array[RigidBody3D] = []
var _transients: Array[Node3D] = []
var _voices: Array[AudioStreamPlayer] = []
var _sounds: Dictionary = {}
var _voice_cursor: int = 0
var _debris_material: PhysicsMaterial = PhysicsMaterial.new()


func _ready() -> void:
	_rng.randomize()
	_debris_material.bounce = 0.38
	_debris_material.friction = 0.72
	for kind: String in ["slash", "blast", "hit"]:
		_sounds[kind] = _synthesize(kind)
	for index: int in range(AUDIO_VOICES):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.name = "CombatVoice%d" % index
		voice.max_polyphony = 1
		add_child(voice)
		_voices.append(voice)


func burst(pos: Vector3, color: Color, count: int = 16, force: float = 5.0) -> void:
	var amount: int = clampi(count, 0, MAX_CHUNKS)
	var speed: float = clampf(force, 0.1, 18.0)
	var material: StandardMaterial3D = _material(color)
	for index: int in range(amount):
		while _chunks.size() >= MAX_CHUNKS:
			var oldest: RigidBody3D = _chunks.pop_front() as RigidBody3D
			if is_instance_valid(oldest):
				oldest.queue_free()
		var chunk: RigidBody3D = RigidBody3D.new()
		var width: float = _rng.randf_range(0.08, 0.19)
		chunk.mass = _rng.randf_range(0.05, 0.14)
		chunk.collision_layer = 0
		chunk.collision_mask = 1
		chunk.physics_material_override = _debris_material
		chunk.linear_damp = 0.2
		chunk.angular_damp = 0.8
		chunk.continuous_cd = true
		var collider: CollisionShape3D = CollisionShape3D.new()
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = Vector3.ONE * width
		collider.shape = shape
		chunk.add_child(collider)
		var visual: MeshInstance3D = _box(Vector3.ONE * width, material)
		chunk.add_child(visual)
		add_child(chunk)
		chunk.global_position = pos + Vector3(
			_rng.randf_range(-0.08, 0.08),
			_rng.randf_range(-0.04, 0.08),
			_rng.randf_range(-0.08, 0.08)
		)
		chunk.rotation = Vector3(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU)
		var direction: Vector3 = Vector3(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(0.3, 1.2),
			_rng.randf_range(-1.0, 1.0)
		).normalized()
		# Explicit velocity gives freshly created bodies their intended launch
		# speed before their first physics tick.
		chunk.linear_velocity = direction * speed * _rng.randf_range(0.5, 1.0)
		chunk.angular_velocity = Vector3(
			_rng.randf_range(-12.0, 12.0),
			_rng.randf_range(-12.0, 12.0),
			_rng.randf_range(-12.0, 12.0)
		)
		_chunks.append(chunk)
		var lifetime: Tween = chunk.create_tween()
		lifetime.tween_interval(_rng.randf_range(1.1, 2.0))
		lifetime.tween_property(visual, "scale", Vector3.ONE * 0.025, 0.25)
		lifetime.tween_callback(_retire_chunk.bind(chunk))
	if amount > 0:
		var flash: Node3D = Node3D.new()
		add_child(flash)
		flash.global_position = pos
		flash.add_child(_box(Vector3(0.36, 0.12, 0.36), _material(color.lightened(0.45))))
		_register_transient(flash)
		var flash_tween: Tween = flash.create_tween()
		flash_tween.tween_property(flash, "scale", Vector3.ONE * 0.01, 0.11)
		flash_tween.tween_callback(_retire_transient.bind(flash))


func slash(pos: Vector3, direction: Vector3, color: Color) -> void:
	var forward: Vector3 = _floor_direction(direction)
	var facing_angle: float = atan2(-forward.z, forward.x)
	var arc: Node3D = Node3D.new()
	add_child(arc)
	arc.global_position = pos
	arc.rotation.y = facing_angle
	var material: StandardMaterial3D = _material(color)
	for index: int in range(8):
		var angle: float = lerpf(-1.1, 1.1, float(index) / 7.0)
		var segment: MeshInstance3D = _box(Vector3(0.28, 0.07, 0.10), material)
		segment.position = Vector3(cos(angle) * 0.78, 0.04, sin(angle) * 0.78)
		segment.rotation.y = -angle - PI * 0.5
		arc.add_child(segment)
	_register_transient(arc)
	var sweep: Tween = arc.create_tween().set_parallel(true)
	sweep.tween_property(arc, "rotation:y", facing_angle + 0.32, 0.13)
	sweep.tween_property(arc, "scale", Vector3.ONE * 1.16, 0.06)
	sweep.chain().tween_property(arc, "scale", Vector3.ONE * 0.01, 0.07)
	sweep.chain().tween_callback(_retire_transient.bind(arc))


func muzzle(pos: Vector3, direction: Vector3) -> void:
	var forward: Vector3 = _floor_direction(direction)
	var flash: Node3D = Node3D.new()
	add_child(flash)
	flash.global_position = pos
	flash.rotation.y = atan2(-forward.z, forward.x)
	var white: StandardMaterial3D = _material(Color(1.0, 0.83, 0.75))
	var red: StandardMaterial3D = _material(Color(1.0, 0.16, 0.12))
	var core: MeshInstance3D = _box(Vector3(0.44, 0.13, 0.22), white)
	core.position.x = 0.2
	flash.add_child(core)
	for index: int in range(5):
		var streak: MeshInstance3D = _box(Vector3(0.45, 0.055, 0.055), red)
		var spread: float = float(index - 2) * 0.16
		streak.position = Vector3(0.57, 0.03, spread)
		streak.rotation.y = -spread
		flash.add_child(streak)
	_register_transient(flash)
	var flicker: Tween = flash.create_tween()
	flicker.tween_property(flash, "scale", Vector3(1.35, 1.0, 0.9), 0.035)
	flicker.tween_property(flash, "scale", Vector3.ONE * 0.01, 0.08)
	flicker.tween_callback(_retire_transient.bind(flash))


func ring(pos: Vector3, color: Color, radius: float = 1.0) -> void:
	var pulse: Node3D = Node3D.new()
	add_child(pulse)
	pulse.global_position = pos + Vector3.UP * 0.03
	pulse.scale = Vector3.ONE * 0.65
	var material: StandardMaterial3D = _material(color, true)
	var size: float = maxf(radius, 0.05)
	for index: int in range(20):
		var angle: float = TAU * float(index) / 20.0
		var segment: MeshInstance3D = _box(Vector3(size * 0.28, 0.055, 0.06), material)
		segment.position = Vector3(cos(angle) * size, 0.0, sin(angle) * size)
		segment.rotation.y = -angle - PI * 0.5
		pulse.add_child(segment)
	_register_transient(pulse)
	var expansion: Tween = pulse.create_tween().set_parallel(true)
	expansion.tween_property(pulse, "scale", Vector3.ONE * 1.35, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	expansion.tween_property(material, "albedo_color:a", 0.0, 0.24)
	expansion.chain().tween_callback(_retire_transient.bind(pulse))


func dash_trail(pos: Vector3, direction: Vector3, color: Color = Color(1.0, 0.18, 0.2)) -> void:
	var forward: Vector3 = _floor_direction(direction)
	var trail: Node3D = Node3D.new()
	add_child(trail)
	trail.global_position = pos
	trail.rotation.y = atan2(-forward.z, forward.x)
	var material: StandardMaterial3D = _material(color, true)
	for index: int in range(5):
		var width: float = lerpf(0.2, 0.06, float(index) / 4.0)
		var fragment: MeshInstance3D = _box(Vector3(width, 0.08, width), material)
		fragment.position.x = -0.18 - float(index) * 0.2
		trail.add_child(fragment)
	_register_transient(trail)
	var fade: Tween = trail.create_tween()
	fade.tween_property(material, "albedo_color:a", 0.0, 0.18)
	fade.tween_callback(_retire_transient.bind(trail))


func floating_text(pos: Vector3, text: String, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font_size = 42
	label.pixel_size = 0.006
	label.outline_size = 7
	label.outline_modulate = Color(0.02, 0.02, 0.025, 1.0)
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)
	label.global_position = pos + Vector3(0.0, 0.35, 0.0)
	_register_transient(label)
	var float_up: Tween = label.create_tween().set_parallel(true)
	float_up.tween_property(label, "global_position", label.global_position + Vector3(0.0, 1.0, 0.0), 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	float_up.tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.45)
	float_up.chain().tween_callback(_retire_transient.bind(label))


func sound(kind: String) -> void:
	if _voices.is_empty():
		return
	var stream: AudioStreamWAV = _sounds.get(kind) as AudioStreamWAV
	if stream == null:
		stream = _sounds.get("hit") as AudioStreamWAV
	var voice: AudioStreamPlayer = _voices[_voice_cursor]
	_voice_cursor = (_voice_cursor + 1) % AUDIO_VOICES
	voice.stop()
	voice.stream = stream
	voice.pitch_scale = _rng.randf_range(0.92, 1.08)
	voice.volume_db = -9.0 if kind == "blast" else -14.0
	voice.play()


func active_chunk_count() -> int:
	return _chunks.size()


func _floor_direction(direction: Vector3) -> Vector3:
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	return flat.normalized() if flat.length_squared() > 0.0001 else Vector3.RIGHT


func _material(color: Color, transparent: bool = false) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _box(size: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


func _register_transient(effect: Node3D) -> void:
	while _transients.size() >= MAX_TRANSIENTS:
		var oldest: Node3D = _transients.pop_front() as Node3D
		if is_instance_valid(oldest):
			oldest.queue_free()
	_transients.append(effect)


func _retire_transient(effect: Node3D) -> void:
	_transients.erase(effect)
	if is_instance_valid(effect):
		effect.queue_free()


func _retire_chunk(chunk: RigidBody3D) -> void:
	_chunks.erase(chunk)
	if is_instance_valid(chunk):
		chunk.queue_free()


func _synthesize(kind: String) -> AudioStreamWAV:
	var duration: float = 0.22 if kind == "blast" else 0.09
	var frames: int = int(float(SAMPLE_RATE) * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(frames * 2)
	var previous_noise: float = 0.0
	var phase: float = 0.0
	for index: int in range(frames):
		var time: float = float(index) / float(SAMPLE_RATE)
		var progress: float = time / duration
		var noise: float = _rng.randf_range(-1.0, 1.0)
		var sample: float = 0.0
		match kind:
			"blast":
				phase += TAU * lerpf(150.0, 52.0, progress) / float(SAMPLE_RATE)
				sample = (sin(phase) * 0.45 + noise * 0.55) * exp(-progress * 6.0)
			"slash":
				var high_noise: float = (noise - previous_noise) * 0.5
				sample = high_noise * sin(progress * PI) * exp(-progress * 2.0) * 0.65
			_:
				phase += TAU * lerpf(240.0, 85.0, progress) / float(SAMPLE_RATE)
				sample = (sin(phase) * 0.6 + noise * 0.4) * exp(-progress * 7.0)
		previous_noise = noise
		# A short fade at both ends prevents discontinuity clicks.
		var fade: float = minf(1.0, time / 0.0015) * minf(1.0, (duration - time) / 0.005)
		var value: int = int(clampf(sample * fade, -1.0, 1.0) * 32767.0)
		data[index * 2] = value & 0xff
		data[index * 2 + 1] = (value >> 8) & 0xff
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
