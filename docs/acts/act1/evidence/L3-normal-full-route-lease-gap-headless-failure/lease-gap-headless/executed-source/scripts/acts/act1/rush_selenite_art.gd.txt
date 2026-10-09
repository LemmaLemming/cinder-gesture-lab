class_name Act1RushSeleniteArt
extends Node3D
## C30 pixels only. The actor supplies public phase/facing, manages visibility,
## and retains all motion, hit, collision, cue and snapshot authority.

const ASSET_DIR: String = "res://assets/acts/act1/lunar/"
const NATIVE_SIZE: Vector2i = Vector2i(48, 80)
const PIXEL_SIZE: float = 0.022
const FEET_PIVOT: Vector2i = Vector2i(24, 80)
const SPRITE_OFFSET: Vector2 = Vector2(0, 40)
const TEXTURES: Dictionary = {
	"front": {
		"standing": preload("res://assets/acts/act1/lunar/rusher_front_standing.png"),
		"crouch": preload("res://assets/acts/act1/lunar/rusher_front_crouch.png"),
		"rush": preload("res://assets/acts/act1/lunar/rusher_front_rush.png"),
		"recovery": preload("res://assets/acts/act1/lunar/rusher_front_recovery.png"),
	},
	"side": {
		"standing": preload("res://assets/acts/act1/lunar/rusher_side_standing.png"),
		"crouch": preload("res://assets/acts/act1/lunar/rusher_side_crouch.png"),
		"rush": preload("res://assets/acts/act1/lunar/rusher_side_rush.png"),
		"recovery": preload("res://assets/acts/act1/lunar/rusher_side_recovery.png"),
	},
	"back": {
		"standing": preload("res://assets/acts/act1/lunar/rusher_back_standing.png"),
		"crouch": preload("res://assets/acts/act1/lunar/rusher_back_crouch.png"),
		"rush": preload("res://assets/acts/act1/lunar/rusher_back_rush.png"),
		"recovery": preload("res://assets/acts/act1/lunar/rusher_back_recovery.png"),
	},
}

var _sprite: Sprite3D
var _canonical_pixel_size: float
var _pose_input_error: String = ""


func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	_sprite = Sprite3D.new()
	_sprite.name = "RusherSprite"
	_sprite.texture = TEXTURES.front.standing
	_sprite.centered = true
	_sprite.pixel_size = PIXEL_SIZE
	# Compare future settings to the engine's exact native readback, not a
	# tolerance or an assumed float64 representation of a native property.
	_canonical_pixel_size = _sprite.pixel_size
	_sprite.offset = SPRITE_OFFSET
	_sprite.axis = Vector3.AXIS_Z
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.shaded = false
	_sprite.double_sided = true
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_sprite.alpha_scissor_threshold = 0.5
	_sprite.no_depth_test = false
	_sprite.fixed_size = false
	_sprite.render_priority = 0
	_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sprite.modulate = Color.WHITE
	_sprite.transparency = 0.0
	_sprite.layers = 1
	_sprite.sorting_offset = 0.0
	_sprite.visible = true
	_sprite.hframes = 1
	_sprite.vframes = 1
	_sprite.frame = 0
	_sprite.region_enabled = false
	_sprite.flip_h = false
	_sprite.flip_v = false
	add_child(_sprite)


func set_pose(phase: String, world_facing: Vector3, camera: Camera3D) -> void:
	if not is_instance_valid(_sprite) or _sprite.is_queued_for_deletion():
		_pose_input_error = "C30 art requires its retained sprite"
		return
	if not is_instance_valid(camera) or not camera.is_inside_tree() or camera.is_queued_for_deletion() or not camera.global_basis.is_finite():
		_pose_input_error = "C30 pose requires the actual finite live camera"
		return
	if is_inside_tree() and camera.get_world_3d() != get_world_3d():
		_pose_input_error = "C30 pose camera must share the actor world"
		return
	var facing := Vector3(world_facing.x, 0.0, world_facing.z)
	var toward := Vector3(camera.global_basis.z.x, 0.0, camera.global_basis.z.z)
	var right := Vector3(camera.global_basis.x.x, 0.0, camera.global_basis.x.z)
	if not facing.is_finite() or facing.is_zero_approx() or toward.is_zero_approx() or right.is_zero_approx():
		_pose_input_error = "C30 pose requires nonzero planar facing and camera axes"
		return
	facing = facing.normalized()
	toward = toward.normalized()
	right = right.normalized()
	var forward_amount: float = facing.dot(toward)
	var side_amount: float = facing.dot(right)
	var artwork_facing: String = "front" if forward_amount >= 0.0 else "back"
	if absf(side_amount) > absf(forward_amount):
		artwork_facing = "side"
	var pose: String = "standing"
	match phase:
		"warning", "lock":
			pose = "crouch"
		"active":
			pose = "rush"
		"recovery":
			pose = "recovery"
	_sprite.texture = TEXTURES[artwork_facing][pose]
	_sprite.flip_h = artwork_facing == "side" and side_amount < 0.0
	_pose_input_error = ""
	# Selection changes pixels only. No body rotation, clock or visibility change.


func sprite() -> Sprite3D:
	return _sprite


func pose_name() -> String:
	var key: String = _texture_key()
	return key.get_slice("/", 1) if not key.is_empty() else ""


func facing_name() -> String:
	var key: String = _texture_key()
	return key.get_slice("/", 0) if not key.is_empty() else ""


func binding_error() -> String:
	if not is_inside_tree() or is_queued_for_deletion() or not get_parent() is Node3D or get_parent().is_queued_for_deletion():
		return "C30 art requires a retained live actor presentation parent"
	if transform != Transform3D.IDENTITY or is_set_as_top_level() or process_mode != Node.PROCESS_MODE_DISABLED or is_processing() or is_physics_processing():
		return "C30 art must retain its identity local frame and clockless leaf mode"
	if not is_instance_valid(_sprite) or not _sprite.is_inside_tree() or _sprite.is_queued_for_deletion() or _sprite.get_parent() != self or get_child_count() != 1:
		return "C30 art requires exactly its retained direct sprite child"
	if _sprite.get_world_3d() != get_world_3d() or (get_parent() as Node3D).get_world_3d() != get_world_3d() or _sprite.transform != Transform3D.IDENTITY or _sprite.is_set_as_top_level():
		return "C30 sprite must retain the actor world and unshifted foot frame"
	if not _pose_input_error.is_empty():
		return _pose_input_error
	if not _sprite.centered or _sprite.pixel_size != _canonical_pixel_size or _sprite.offset != SPRITE_OFFSET or _sprite.axis != Vector3.AXIS_Z or _sprite.billboard != BaseMaterial3D.BILLBOARD_ENABLED or _sprite.fixed_size:
		return "C30 sprite must retain the native feet-pivot billboard settings"
	if _sprite.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or _sprite.shaded or not _sprite.double_sided or _sprite.alpha_cut != SpriteBase3D.ALPHA_CUT_DISCARD or _sprite.alpha_scissor_threshold != 0.5:
		return "C30 sprite must retain nearest unshaded hard-alpha pixels"
	if _sprite.no_depth_test or _sprite.render_priority != 0 or _sprite.sorting_offset != 0.0 or _sprite.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF or _sprite.modulate != Color.WHITE or _sprite.transparency != 0.0 or _sprite.layers != 1 or _sprite.material_override != null or _sprite.material_overlay != null:
		return "C30 sprite must retain ordinary untinted actor depth without overrides"
	if not _sprite.visible or _sprite.get_script() != null:
		return "C30 sprite visibility belongs to its actor parent; child stays a native sprite"
	if _sprite.region_enabled or _sprite.hframes != 1 or _sprite.vframes != 1 or _sprite.frame != 0 or _sprite.flip_v:
		return "C30 sprite must retain its whole standalone native frame"
	var key: String = _texture_key()
	if key.is_empty() or _sprite.texture is AtlasTexture or _sprite.texture.get_size() != Vector2(NATIVE_SIZE):
		return "C30 sprite must use one of its twelve known 48x80 Texture2D handles"
	var expected_path: String = ASSET_DIR + "rusher_%s_%s.png" % [key.get_slice("/", 0), key.get_slice("/", 1)]
	if _sprite.texture.resource_path != expected_path or (_sprite.flip_h and facing_name() != "side"):
		return "C30 texture path or side-only reflection no longer matches its frame"
	return ""


func _texture_key() -> String:
	if not is_instance_valid(_sprite) or not _sprite.texture is Texture2D:
		return ""
	for facing: String in TEXTURES:
		for pose: String in TEXTURES[facing]:
			if _sprite.texture == TEXTURES[facing][pose]:
				return facing + "/" + pose
	return ""
