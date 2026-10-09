class_name CinderAct3StalkerArt
extends Node3D
## Owned noncombat still-art component. Caller supplies world facing and phase.
## Generated facing/phase stills have scoped A3-L1 portrait review; they are not
## frame-animation sheets. See levels/A3-L1.md for production evidence and limits.
## No timers, movement, collision, damage, death inference or shared actor access.
## Rear crest/anatomy and modest recovery lowering retain documented limits.
## Shared phase cues and ordinary whole-body vulnerability remain authoritative.

const PIXEL_SIZE: float = 1.35 / 807.0
const PHASES: Array[String] = ["idle", "approach", "warning", "lock", "active", "recovery", "defeated"]
const SOURCES: Dictionary = {
	"front_braced": {
		"path": "res://assets/acts/act3/sunbound-stalker-branchspell.png",
		"texture": preload("res://assets/acts/act3/sunbound-stalker-branchspell.png"),
		"offset": Vector2(-8, 424),
	},
	"front_recovery": {
		"path": "res://assets/acts/act3/sunbound-stalker-recovery.png",
		"texture": preload("res://assets/acts/act3/sunbound-stalker-recovery.png"),
		"offset": Vector2(-8, 433),
	},
	"front_alppain": {
		"path": "res://assets/acts/act3/sunbound-stalker-alppain-readable.png",
		"texture": preload("res://assets/acts/act3/sunbound-stalker-alppain-readable.png"),
		"offset": Vector2(-8, 424),
	},
	"front_alppain_recovery": {
		"path": "res://assets/acts/act3/sunbound-stalker-alppain-recovery.png",
		"texture": preload("res://assets/acts/act3/sunbound-stalker-alppain-recovery.png"),
		"offset": Vector2(-8, 435),
	},
	"back_braced": {
		"path": "res://assets/acts/act3/sunbound-stalker-branchspell-back.png",
		"texture": preload("res://assets/acts/act3/sunbound-stalker-branchspell-back.png"),
		"offset": Vector2(-86, 455),
	},
	"back_recovery": {
		"path": "res://assets/acts/act3/sunbound-stalker-recovery-back.png",
		"texture": preload("res://assets/acts/act3/sunbound-stalker-recovery-back.png"),
		"offset": Vector2(-8, 424),
	},
	"back_alppain": {
		"path": "res://assets/acts/act3/sunbound-stalker-alppain-back.png",
		"texture": preload("res://assets/acts/act3/sunbound-stalker-alppain-back.png"),
		"offset": Vector2(-87, 456),
	},
	"back_alppain_recovery": {
		"path": "res://assets/acts/act3/sunbound-stalker-alppain-recovery-back.png",
		"texture": preload("res://assets/acts/act3/sunbound-stalker-alppain-recovery-back.png"),
		"offset": Vector2(-8, 424),
	},
}

var _sprite: Sprite3D
var _shadow: MeshInstance3D
var _framing_stills: Dictionary = {}
var _facing: Vector3 = Vector3.BACK
var _phase: String = "idle"
var _sun_state: int = 0
var _facing_bin: String = "front"
var _source_key: String = "front_braced"
var _mirrored: bool = false
var _offset: Vector2 = Vector2(-8, 424)
var _last_error: String = ""


func _ready() -> void:
	present(_facing, _phase)


## +Z faces the fixed portrait camera; +X is screen right. Cardinal bins match
## LabSprite.face. Side bins use the sign of Z to choose the nearest supplied
## front/back still; exactly lateral (Z == 0) uses front. Negative X mirrors it.
## Warning/lock/active deliberately share one braced STILL, without a fake clock.
## Only an explicit defeated phase hides these visual children; it frees nothing.
func present(facing: Vector3, phase: String, sun: int = 0) -> bool:
	if not facing.is_finite() or not PHASES.has(phase) or sun not in [0, 1]:
		_last_error = "Stalker art requires finite facing and a supported visual phase"
		return false
	var planar := Vector3(facing.x, 0.0, facing.z)
	# Like the shared actor, a near-zero facing retains the last readable direction.
	if absf(planar.x) + absf(planar.z) >= 0.01:
		_facing = planar.normalized()
	if absf(_facing.x) > absf(_facing.z):
		_facing_bin = "right" if _facing.x > 0.0 else "left"
	else:
		_facing_bin = "front" if _facing.z > 0.0 else "back"
	_phase = phase
	_sun_state = sun
	_mirrored = _facing.x < 0.0
	var view: String = "back" if _facing.z < 0.0 else "front"
	# The caller retains its committed crest through the complete exchange.
	# Matching front/rear fork recoveries remain portrait-review candidates.
	_source_key = view + ("_recovery" if phase == "recovery" else ("_alppain" if sun == 1 else "_braced"))
	if phase == "recovery" and sun == 1:
		_source_key = view + "_alppain_recovery"
	var source: Dictionary = SOURCES[_source_key]
	_offset = source["offset"]
	if _mirrored:
		_offset.x = -_offset.x
	_ensure_visuals()
	_sprite.texture = source["texture"] as Texture2D
	_sprite.offset = _offset
	_sprite.flip_h = _mirrored
	_sprite.visible = phase != "defeated"
	_shadow.visible = phase != "defeated"
	_last_error = ""
	return true


## Defensive diagnostics contain no gameplay authority or animation progress.
func state() -> Dictionary:
	return {
		"source_path": SOURCES[_source_key]["path"],
		"facing": _facing,
		"facing_bin": _facing_bin,
		"source_view": "back" if _facing.z < 0.0 else "front",
		"phase": _phase,
		"sun_state": _sun_state,
		"mirrored": _mirrored,
		"offset": _offset,
		"pixel_size": PIXEL_SIZE,
		"readiness": "candidate_stills_only",
		"visible": is_instance_valid(_sprite) and _sprite.visible,
		"last_error": _last_error,
	}


## Pure native render bounds. Forecast stills use the same existing textures,
## pixel scale, mirrored offsets and ready standard billboard renderer as the
## actual visible still; they render nothing and have no collider or clock.
## The shared shell projects their native quads. Future source positions only
## translate those quads; this method never changes a sprite or real body.
func camera_framing_points(shell: Node, source_positions: Array, facing: Vector3, sun: int) -> Dictionary:
	if not is_inside_tree() or not is_node_ready() or not is_instance_valid(shell) or not shell.has_method("camera_billboard_points") or not is_instance_valid(_sprite) or not is_instance_valid(_shadow) or _shadow.mesh == null or not facing.is_finite() or sun not in [0, 1] or source_positions.is_empty() or source_positions.size() > 3 or not get_parent() is Node3D:
		return {"error": "Ready actual Stalker art and bounded native forecast required", "points": []}
	# SpriteBase3D stores its pixel_size as native real_t. Compare the actual
	# configured native value, rather than the higher precision authored ratio.
	var native_pixel_size: float = PackedFloat32Array([PIXEL_SIZE])[0]
	if _sprite.pixel_size != native_pixel_size or _sprite.position != Vector3(0, 0.025, 0):
		return {"error": "Actual Stalker still changed its native scale or feet offset", "points": []}
	var current: Array = shell.call("camera_billboard_points", _sprite)
	if current.is_empty():
		return {"error": "Actual Stalker billboard bounds unavailable", "points": []}
	var result: Array = current.duplicate()
	var mirrored: bool = facing.x < 0.0
	var view: String = "back" if facing.z < 0.0 else "front"
	var keys: Array[String] = [view + ("_alppain" if sun == 1 else "_braced"), view + ("_alppain_recovery" if sun == 1 else "_recovery")]
	var origin: Vector3 = (get_parent() as Node3D).global_position
	var shadow: Array = _box_points(_shadow.get_aabb(), _shadow.global_transform)
	result.append_array(shadow)
	for point: Variant in source_positions:
		if not point is Vector3 or not point.is_finite():
			return {"error": "Finite native source forecast positions required", "points": []}
		var shift: Vector3 = point - origin
		for key: String in keys:
			var native: Sprite3D = _framing_stills.get(key + ("_mirrored" if mirrored else "_normal")) as Sprite3D
			var expected_offset: Vector2 = SOURCES[key].offset
			if mirrored:
				expected_offset.x = -expected_offset.x
			if not is_instance_valid(native) or native.texture != SOURCES[key].texture or native.offset != expected_offset or native.flip_h != mirrored or native.pixel_size != native_pixel_size or native.position != _sprite.position:
				return {"error": "Native Stalker forecast still differs from its actual family metadata", "points": []}
			var quad: Array = shell.call("camera_billboard_points", native)
			if quad.is_empty():
				return {"error": "Native committed Stalker billboard bounds unavailable", "points": []}
			for vertex: Vector3 in quad:
				result.append(vertex + shift)
		for vertex: Vector3 in shadow:
			result.append(vertex + shift)
	return {"error": "", "points": result}


func _box_points(bounds: AABB, transform: Transform3D) -> Array:
	var result: Array = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]:
				result.append(transform * Vector3(x, y, z))
	return result


func _ensure_visuals() -> void:
	if not is_instance_valid(_sprite):
		_sprite = Sprite3D.new()
		_sprite.name = "CandidateStill"
		_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_sprite.pixel_size = PIXEL_SIZE
		_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		_sprite.alpha_scissor_threshold = 0.5
		_sprite.no_depth_test = false
		_sprite.shaded = false
		_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_sprite.position.y = 0.025
		add_child(_sprite)
	if not is_instance_valid(_shadow):
		_shadow = MeshInstance3D.new()
		_shadow.name = "FilledContactShadow"
		var disk := CylinderMesh.new()
		disk.top_radius = 0.34
		disk.bottom_radius = 0.34
		disk.height = 0.006
		disk.radial_segments = 12
		_shadow.mesh = disk
		_shadow.position.y = 0.009
		_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color("17131f")
		_shadow.material_override = material
		add_child(_shadow)

	if _framing_stills.is_empty():
		for key: String in SOURCES:
			for mirrored: bool in [false, true]:
				var native := Sprite3D.new()
				var id: String = key + ("_mirrored" if mirrored else "_normal")
				native.name = "FramingNative_" + id
				native.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				native.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				native.pixel_size = PIXEL_SIZE
				native.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
				native.alpha_scissor_threshold = 0.5
				native.no_depth_test = false
				native.shaded = false
				native.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				native.position.y = 0.025
				native.texture = SOURCES[key].texture as Texture2D
				var offset: Vector2 = SOURCES[key].offset
				if mirrored:
					offset.x = -offset.x
				native.offset = offset
				native.flip_h = mirrored
				native.visible = false
				add_child(native)
				_framing_stills[id] = native
