class_name PixelEffects
extends Node3D
## Short, asset-free combat effects. Gameplay debris collides only with the world.

const MAX_CHUNKS: int = 96
const MAX_TRANSIENTS: int = 48
const AUDIO_VOICES: int = 6
const SAMPLE_RATE: int = 22050
const Footprint = preload("res://scripts/attack_footprint.gd")
const SmokeScript = preload("res://scripts/curling_smoke.gd")
const FlareScript = preload("res://scripts/shotgun_flare.gd")
const MAX_BLOOD_PARTICLES: int = 24
const EFFECTS_BUS: String = "Effects"
const PROTECTED_FEEDBACK: Array[String] = ["warning", "lock", "active_footprint", "recovery", "source", "target", "safe_landing", "interaction_state", "hit_confirmation", "dash_path", "slash_arc", "blast_release"]

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _chunks: Array[RigidBody3D] = []
var _transients: Array[Node3D] = []
var _blood_particles: Array[Node3D] = []
var _voices: Array[AudioStreamPlayer] = []
var _sounds: Dictionary = {}
var _voice_cursor: int = 0
var _debris_material: PhysicsMaterial = PhysicsMaterial.new()
var _optional_transients: Array[Node3D] = []
var _effect_tweens: Dictionary = {}
var _decoration_accumulator: float = 0.0
var last_policy_error: String = ""
# An unconfigured mechanics lab retains its original full cosmetics. A campaign
# shell explicitly supplies a defensive snapshot of GameSettings.cosmetic_policy.
var _policy: Dictionary = {
	"quality": "High", "optional_particle_density": 1.0,
	"optional_debris_limit": MAX_CHUNKS, "optional_impact_fleck_limit": MAX_BLOOD_PARTICLES,
	"decoration_density": 1.0, "camera_shake_scale": 1.0,
	"decoration_motion_scale": 1.0, "menu_motion_enabled": true,
	"authoritative_feedback_scale": 1.0, "action_feedback_scale": 1.0,
	"protected_feedback": PROTECTED_FEEDBACK.duplicate(), "nearest_filtering": true,
	"portrait_camera_unchanged": true, "simulation_unchanged": true,
}

func configure_policy(candidate: Dictionary) -> bool:
	last_policy_error = _policy_error(candidate)
	if not last_policy_error.is_empty():
		return false
	_policy = candidate.duplicate(true)
	_decoration_accumulator = 0.0
	_prune_retired()
	var debris_limit: int = _optional_limit("optional_debris_limit")
	while _chunks.size() > debris_limit:
		_retire_chunk(_chunks[0])
	var fleck_limit: int = _optional_limit("optional_impact_fleck_limit")
	while _blood_particles.size() > fleck_limit:
		_retire_transient(_blood_particles[0])
	if decoration_density() <= 0.0:
		for effect: Node3D in _optional_transients.duplicate():
			_retire_transient(effect)
	return true

func policy_snapshot() -> Dictionary:
	return _policy.duplicate(true)

func camera_shake_scale() -> float:
	return float(_policy["camera_shake_scale"])

func decoration_density() -> float:
	return float(_policy["decoration_density"]) * float(_policy["decoration_motion_scale"])

func clear() -> void:
	# Stop callbacks before queue_free's deferred deletion. New scene effects can
	# be created in the same paused barrier without old tweens touching them.
	_prune_retired()
	for voice: AudioStreamPlayer in _voices:
		if is_instance_valid(voice):
			voice.stop()
	_voice_cursor = 0
	for chunk: RigidBody3D in _chunks.duplicate():
		_retire_chunk(chunk)
	for effect: Node3D in _transients.duplicate():
		_retire_transient(effect)
	_chunks.clear()
	_transients.clear()
	_optional_transients.clear()
	_blood_particles.clear()
	_effect_tweens.clear()
	_decoration_accumulator = 0.0

func clear_lab() -> void:
	clear()

func retire_effect(effect: Node3D) -> void:
	# Actor restore can retire its old plume without leaving a stale registry
	# entry. This is presentation cleanup, never an actor action or clock update.
	_retire_transient(effect)


func _ready() -> void:
	_rng.randomize()
	_debris_material.bounce = 0.38
	_debris_material.friction = 0.72
	_ensure_effects_bus()
	for kind: String in ["slash", "blast", "hit"]:
		_sounds[kind] = _synthesize(kind)
	for index: int in range(AUDIO_VOICES):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.name = "CombatVoice%d" % index
		voice.max_polyphony = 1
		voice.bus = EFFECTS_BUS
		add_child(voice)
		_voices.append(voice)


func burst(pos: Vector3, color: Color, count: int = 16, force: float = 5.0) -> void:
	_prune_retired()
	var limit: int = _optional_limit("optional_debris_limit")
	var amount: int = mini(_optional_amount(clampi(count, 0, MAX_CHUNKS)), limit)
	var speed: float = clampf(force, 0.1, 18.0)
	var material: StandardMaterial3D = _material(color)
	for index: int in range(amount):
		while _chunks.size() >= limit:
			_retire_chunk(_chunks[0])
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
		var lifetime: Tween = _tween_for(chunk)
		lifetime.tween_interval(_rng.randf_range(1.1, 2.0))
		lifetime.tween_property(visual, "scale", Vector3.ONE * 0.025, 0.25)
		lifetime.tween_callback(_retire_chunk.bind(chunk))
	if count > 0:
		var flash: Node3D = Node3D.new()
		flash.name = "ImpactConfirmation"
		add_child(flash)
		flash.global_position = pos
		flash.add_child(_box(Vector3(0.36, 0.12, 0.36), _material(color.lightened(0.45))))
		_register_transient(flash)
		var flash_tween: Tween = _tween_for(flash)
		flash_tween.tween_property(flash, "scale", Vector3.ONE * 0.01, 0.11)
		flash_tween.tween_callback(_retire_transient.bind(flash))


func slash(pos: Vector3, direction: Vector3, color: Color) -> void:
	var forward: Vector3 = _floor_direction(direction)
	var facing_angle: float = atan2(-forward.z, forward.x)
	var arc: Node3D = Node3D.new()
	arc.name = "SlashArc"
	add_child(arc)
	arc.global_position = pos
	arc.rotation.y = facing_angle
	arc.add_to_group("cosmetic_slash_arcs")
	arc.set_meta("lifetime", 0.28)
	var material: StandardMaterial3D = _material(color)
	for index: int in range(8):
		var angle: float = lerpf(-1.1, 1.1, float(index) / 7.0)
		var segment: MeshInstance3D = _box(Vector3(0.28, 0.07, 0.10), material)
		segment.position = Vector3(cos(angle) * 0.78, 0.04, sin(angle) * 0.78)
		segment.rotation.y = -angle - PI * 0.5
		arc.add_child(segment)
	_register_transient(arc)
	var sweep: Tween = _tween_for(arc)
	sweep.tween_property(arc, "rotation:y", facing_angle + 0.32, 0.28)
	var settling: Tween = _tween_for(arc)
	settling.tween_property(arc, "scale", Vector3.ONE * 1.16, 0.14)
	settling.tween_property(arc, "scale", Vector3.ONE * 0.01, 0.14)
	settling.tween_callback(_retire_transient.bind(arc))


func _emit_smoke(pos: Vector3, flow: Vector3, kind: String, delay: float = 0.0, size: float = 1.0, optional: bool = false) -> Node3D:
	var smoke: Node3D = SmokeScript.new() as Node3D
	smoke.configure(kind, flow, delay)
	smoke.position = to_local(pos)
	smoke.scale = Vector3.ONE * size
	add_child(smoke)
	if not _register_transient(smoke, optional):
		return null
	smoke.finished.connect(_retire_transient)
	return smoke

func optional_decoration_smoke(pos: Vector3, flow: Vector3, size: float = 1.0) -> Node3D:
	# Deterministic density thinning cannot consume gameplay RNG or cue budgets.
	_decoration_accumulator += decoration_density()
	if _decoration_accumulator < 1.0:
		return null
	_decoration_accumulator -= 1.0
	return _emit_smoke(pos, flow, "sweep", 0.0, clampf(size, 0.1, 3.0), true)


func tiny_bleed(pos: Vector3, count: int = 3, impulse: Vector3 = Vector3.ZERO) -> void:
	# A few one-pixel-scale flecks, never a flash or a rigid-body explosion.
	_prune_retired()
	var limit: int = _optional_limit("optional_impact_fleck_limit")
	var amount: int = mini(_optional_amount(clampi(count, 0, 5)), limit)
	var direction: Vector3 = _floor_direction(impulse)
	for index: int in range(amount):
		while _blood_particles.size() >= limit:
			_retire_transient(_blood_particles[0])
		var mote: Node3D = Node3D.new()
		mote.name = "TinyBloodParticle"
		var width: float = _rng.randf_range(0.025, 0.045)
		mote.add_child(_box(Vector3.ONE * width, _material(Color(0.46, 0.09, 0.10))))
		add_child(mote)
		mote.global_position = pos + Vector3(_rng.randf_range(-0.05, 0.05), _rng.randf_range(-0.04, 0.04), _rng.randf_range(-0.05, 0.05))
		mote.add_to_group("tiny_blood_particles")
		_blood_particles.append(mote)
		if not _register_transient(mote, true):
			continue
		var drift: Vector3 = direction * _rng.randf_range(0.03, 0.10) + Vector3(_rng.randf_range(-0.04, 0.04), 0.0, _rng.randf_range(-0.04, 0.04))
		var tumble: Tween = _tween_for(mote)
		tumble.tween_property(mote, "global_position", mote.global_position + drift + Vector3.UP * 0.05, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tumble.tween_property(mote, "global_position", mote.global_position + drift * 1.5 - Vector3.UP * 0.10, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tumble.tween_property(mote, "scale", Vector3.ZERO, 0.08)
		tumble.tween_callback(_retire_transient.bind(mote))


func attack_footprint(pos: Vector3, direction: Vector3, reach: float, cone_min_dot: float, color: Color, duration: float = 0.13) -> void:
	# Snapshot the same reach, cone and scenery LOS used by the accepted action.
	# Do not scale or rotate this outline after creation: the hit already resolved.
	var forward: Vector3 = _floor_direction(direction)
	var outline := MeshInstance3D.new()
	outline.name = "ResolvedAttackFootprint"
	outline.mesh = Footprint.cone_mesh(reach, cone_min_dot, false, get_world_3d().direct_space_state, pos, forward)
	var material: StandardMaterial3D = _material(color, true)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	outline.material_override = material
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(outline)
	outline.global_position = pos + Vector3.UP * 0.035
	outline.rotation.y = atan2(forward.x, forward.z)
	_register_transient(outline)
	var fade: Tween = _tween_for(outline)
	fade.tween_property(material, "albedo_color:a", 0.0, maxf(duration, 0.02))
	fade.tween_callback(_retire_transient.bind(outline))


func muzzle(pos: Vector3, direction: Vector3, source: Node3D = null) -> void:
	var flare: Node3D = FlareScript.new() as Node3D
	flare.configure(_floor_direction(direction), source)
	flare.position = to_local(pos)
	add_child(flare)
	_register_transient(flare)
	flare.finished.connect(_retire_transient)


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
	var expansion: Tween = _tween_for(pulse).set_parallel(true)
	expansion.tween_property(pulse, "scale", Vector3.ONE * 1.35, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	expansion.tween_property(material, "albedo_color:a", 0.0, 0.24)
	expansion.chain().tween_callback(_retire_transient.bind(pulse))


func dash_trail(pos: Vector3, direction: Vector3, _color: Color = Color.WHITE) -> Node3D:
	var forward: Vector3 = _floor_direction(direction)
	return _emit_smoke(pos - forward * 0.12, -forward, "dash", 0.0, 0.78)

func restore_dash_trail(source: Node3D, origin: Vector3, direction: Vector3, total_s: float, remaining_s: float) -> Node3D:
	# Restore visual age and actual already-travelled endpoints, never request a
	# new action, predict an unobstructed landing or advance a simulation clock.
	if not is_instance_valid(source) or not source.is_inside_tree() or not source.global_position.is_finite() or not origin.is_finite() or not direction.is_finite() or absf(direction.y) > 0.000001 or not is_equal_approx(direction.length_squared(), 1.0) or not is_finite(total_s) or not is_finite(remaining_s) or total_s <= 0.0 or remaining_s <= 0.0 or remaining_s > total_s:
		return null
	var forward: Vector3 = _floor_direction(direction)
	var plume: Node3D = dash_trail(source.global_position + Vector3.UP * 0.08, forward)
	plume.restore_tracking(source, origin + Vector3.UP * 0.08 - forward * 0.12, total_s, total_s - remaining_s)
	return plume


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
	var float_up: Tween = _tween_for(label).set_parallel(true)
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
	_prune_retired()
	return _chunks.size()


func active_transient_count() -> int:
	_prune_retired()
	return _transients.size()


func active_blood_count() -> int:
	_prune_retired()
	return _blood_particles.size()


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


func _register_transient(effect: Node3D, optional: bool = false) -> bool:
	_prune_retired()
	while _transients.size() >= MAX_TRANSIENTS:
		if not _optional_transients.is_empty():
			_retire_transient(_optional_transients[0])
		elif optional:
			_retire_transient(effect)
			return false
		else:
			_retire_transient(_transients[0])
	_transients.append(effect)
	if optional:
		_optional_transients.append(effect)
	return true


func _retire_transient(effect: Node3D) -> void:
	_transients.erase(effect)
	_optional_transients.erase(effect)
	_blood_particles.erase(effect)
	if is_instance_valid(effect):
		_stop_effect(effect)
		effect.queue_free()


func _retire_chunk(chunk: RigidBody3D) -> void:
	_chunks.erase(chunk)
	if is_instance_valid(chunk):
		_stop_effect(chunk)
		chunk.freeze = true
		chunk.queue_free()

func _tween_for(owner: Node3D) -> Tween:
	var tween: Tween = owner.create_tween()
	var id: int = owner.get_instance_id()
	if not _effect_tweens.has(id):
		_effect_tweens[id] = []
	(_effect_tweens[id] as Array).append(tween)
	return tween

func _stop_effect(effect: Node3D) -> void:
	var id: int = effect.get_instance_id()
	for tween: Tween in _effect_tweens.get(id, []):
		if tween != null and tween.is_valid():
			tween.kill()
	_effect_tweens.erase(id)
	if effect.has_signal("finished") and effect.is_connected("finished", _retire_transient):
		effect.disconnect("finished", _retire_transient)
	if effect.has_method("release_source"):
		effect.call("release_source")
	effect.hide()
	effect.set_process(false)
	effect.set_physics_process(false)

func _optional_limit(key: String) -> int:
	return int(_policy[key]) if float(_policy["decoration_motion_scale"]) > 0.0 else 0

func _prune_retired() -> void:
	# Actor teardown may free a presentation helper independently of this owner.
	for list: Array in [_chunks, _transients, _optional_transients, _blood_particles]:
		for effect: Variant in list.duplicate():
			if not is_instance_valid(effect):
				list.erase(effect)
	var live_ids: Dictionary = {}
	for effect: Node3D in _transients:
		live_ids[effect.get_instance_id()] = true
	for chunk: RigidBody3D in _chunks:
		live_ids[chunk.get_instance_id()] = true
	for id: int in _effect_tweens.keys():
		if not live_ids.has(id):
			for tween: Tween in _effect_tweens[id]:
				if tween != null and tween.is_valid(): tween.kill()
			_effect_tweens.erase(id)

func _optional_amount(count: int) -> int:
	return roundi(float(count) * float(_policy["optional_particle_density"])) if float(_policy["decoration_motion_scale"]) > 0.0 else 0

func _ensure_effects_bus() -> void:
	if AudioServer.get_bus_index(EFFECTS_BUS) >= 0:
		return
	AudioServer.add_bus()
	var index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, EFFECTS_BUS)
	AudioServer.set_bus_send(index, "Master")

func _policy_error(candidate: Dictionary) -> String:
	if candidate.size() != _policy.size():
		return "Cosmetic policy must use the complete settings policy schema"
	for key: Variant in _policy:
		if not candidate.has(key):
			return "Missing cosmetic policy field: " + str(key)
	if not candidate["quality"] is String or not ["Low", "Standard", "High"].has(candidate["quality"]):
		return "Unknown cosmetic quality"
	for key: String in ["optional_particle_density", "decoration_density", "camera_shake_scale", "decoration_motion_scale"]:
		if not _finite_range(candidate[key], 0.0, 1.0):
			return "Invalid optional cosmetic scale: " + key
	for key: String in ["optional_debris_limit", "optional_impact_fleck_limit"]:
		var maximum: int = MAX_CHUNKS if key == "optional_debris_limit" else MAX_BLOOD_PARTICLES
		if not _finite_range(candidate[key], 0, maximum) or floorf(float(candidate[key])) != float(candidate[key]):
			return "Invalid optional cosmetic limit: " + key
	for key: String in ["authoritative_feedback_scale", "action_feedback_scale"]:
		if not _finite_range(candidate[key], 1.0, 1.0):
			return "Protected feedback cannot be reduced"
	for key: String in ["nearest_filtering", "portrait_camera_unchanged", "simulation_unchanged"]:
		if not candidate[key] is bool or not candidate[key]:
			return "Cosmetic policy cannot change " + key
	if not candidate["menu_motion_enabled"] is bool or not candidate["protected_feedback"] is Array:
		return "Invalid cosmetic policy flags"
	if candidate["protected_feedback"] != PROTECTED_FEEDBACK:
		return "Protected feedback contract differs from shared settings"
	return ""

func _finite_range(value: Variant, minimum: float, maximum: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= minimum and float(value) <= maximum


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
