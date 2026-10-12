class_name Act1MushroomSeleniteArt
extends Node3D
## C31/C32 original costume pixels only. Configure the literal canonical role
## before add. Actual native/environmental phase and facing select static pixels; the parent owns
## visibility, motion, damage, cue and snapshot authority. No animation clock.

const ASSET_DIR: String = "res://assets/acts/act1/grotto/selenites/"
const REPULSION_ASSET_DIR: String = ASSET_DIR + "repulsion/"
const REPULSION_POSES: Array[String] = ["recoil", "retreat", "regroup"]
const PIXEL_SIZE: float = 0.022
const SPRITE_OFFSET: Vector2 = Vector2(0, 40)
const NATIVE_SIZES: Dictionary = {"A1-E2": Vector2i(48, 80), "A1-E3": Vector2i(80, 80)}
const ASSET_NAMES: Dictionary = {"A1-E2": "swarm", "A1-E3": "guard"}
const PHASES: Array[String] = ["clear", "idle", "warning", "lock", "active", "recovery", "recoil", "retreat", "regroup"]
const TEXTURES: Dictionary = {
	"A1-E2": {
		"front": {
			"standing": preload("res://assets/acts/act1/grotto/selenites/swarm_front_standing.png"),
			"warning": preload("res://assets/acts/act1/grotto/selenites/swarm_front_warning.png"),
			"lock": preload("res://assets/acts/act1/grotto/selenites/swarm_front_lock.png"),
			"active": preload("res://assets/acts/act1/grotto/selenites/swarm_front_active.png"),
			"recovery": preload("res://assets/acts/act1/grotto/selenites/swarm_front_recovery.png"),
			"recoil": preload("res://assets/acts/act1/grotto/selenites/repulsion/swarm_front_recoil.png"),
			"retreat": preload("res://assets/acts/act1/grotto/selenites/repulsion/swarm_front_retreat.png"),
			"regroup": preload("res://assets/acts/act1/grotto/selenites/repulsion/swarm_front_regroup.png"),
		},
		"side": {
			"standing": preload("res://assets/acts/act1/grotto/selenites/swarm_side_standing.png"),
			"warning": preload("res://assets/acts/act1/grotto/selenites/swarm_side_warning.png"),
			"lock": preload("res://assets/acts/act1/grotto/selenites/swarm_side_lock.png"),
			"active": preload("res://assets/acts/act1/grotto/selenites/swarm_side_active.png"),
			"recovery": preload("res://assets/acts/act1/grotto/selenites/swarm_side_recovery.png"),
			"recoil": preload("res://assets/acts/act1/grotto/selenites/repulsion/swarm_side_recoil.png"),
			"retreat": preload("res://assets/acts/act1/grotto/selenites/repulsion/swarm_side_retreat.png"),
			"regroup": preload("res://assets/acts/act1/grotto/selenites/repulsion/swarm_side_regroup.png"),
		},
		"back": {
			"standing": preload("res://assets/acts/act1/grotto/selenites/swarm_back_standing.png"),
			"warning": preload("res://assets/acts/act1/grotto/selenites/swarm_back_warning.png"),
			"lock": preload("res://assets/acts/act1/grotto/selenites/swarm_back_lock.png"),
			"active": preload("res://assets/acts/act1/grotto/selenites/swarm_back_active.png"),
			"recovery": preload("res://assets/acts/act1/grotto/selenites/swarm_back_recovery.png"),
			"recoil": preload("res://assets/acts/act1/grotto/selenites/repulsion/swarm_back_recoil.png"),
			"retreat": preload("res://assets/acts/act1/grotto/selenites/repulsion/swarm_back_retreat.png"),
			"regroup": preload("res://assets/acts/act1/grotto/selenites/repulsion/swarm_back_regroup.png"),
		},
	},
	"A1-E3": {
		"front": {
			"standing": preload("res://assets/acts/act1/grotto/selenites/guard_front_standing.png"),
			"warning": preload("res://assets/acts/act1/grotto/selenites/guard_front_warning.png"),
			"lock": preload("res://assets/acts/act1/grotto/selenites/guard_front_lock.png"),
			"active": preload("res://assets/acts/act1/grotto/selenites/guard_front_active.png"),
			"recovery": preload("res://assets/acts/act1/grotto/selenites/guard_front_recovery.png"),
			"recoil": preload("res://assets/acts/act1/grotto/selenites/repulsion/guard_front_recoil.png"),
			"retreat": preload("res://assets/acts/act1/grotto/selenites/repulsion/guard_front_retreat.png"),
			"regroup": preload("res://assets/acts/act1/grotto/selenites/repulsion/guard_front_regroup.png"),
		},
		"side": {
			"standing": preload("res://assets/acts/act1/grotto/selenites/guard_side_standing.png"),
			"warning": preload("res://assets/acts/act1/grotto/selenites/guard_side_warning.png"),
			"lock": preload("res://assets/acts/act1/grotto/selenites/guard_side_lock.png"),
			"active": preload("res://assets/acts/act1/grotto/selenites/guard_side_active.png"),
			"recovery": preload("res://assets/acts/act1/grotto/selenites/guard_side_recovery.png"),
			"recoil": preload("res://assets/acts/act1/grotto/selenites/repulsion/guard_side_recoil.png"),
			"retreat": preload("res://assets/acts/act1/grotto/selenites/repulsion/guard_side_retreat.png"),
			"regroup": preload("res://assets/acts/act1/grotto/selenites/repulsion/guard_side_regroup.png"),
		},
		"back": {
			"standing": preload("res://assets/acts/act1/grotto/selenites/guard_back_standing.png"),
			"warning": preload("res://assets/acts/act1/grotto/selenites/guard_back_warning.png"),
			"lock": preload("res://assets/acts/act1/grotto/selenites/guard_back_lock.png"),
			"active": preload("res://assets/acts/act1/grotto/selenites/guard_back_active.png"),
			"recovery": preload("res://assets/acts/act1/grotto/selenites/guard_back_recovery.png"),
			"recoil": preload("res://assets/acts/act1/grotto/selenites/repulsion/guard_back_recoil.png"),
			"retreat": preload("res://assets/acts/act1/grotto/selenites/repulsion/guard_back_retreat.png"),
			"regroup": preload("res://assets/acts/act1/grotto/selenites/repulsion/guard_back_regroup.png"),
		},
	},
}

var _role_id: String = "A1-E2"
var _configured: bool = false
var last_error: String = ""
var _sprite: Sprite3D
var _canonical_pixel_size: float
var _pose_input_error: String = ""


func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	_sprite = Sprite3D.new()
	_sprite.name = "MushroomSeleniteSprite"
	_sprite.texture = TEXTURES[_role_id].front.standing
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


## Immutable presentation identity. This does not configure any gameplay role.
func configure(role_id: String) -> bool:
	var selected: String = "A1-E2" if role_id in ["C31", "A1-E2"] else ("A1-E3" if role_id in ["C32", "A1-E3"] else "")
	if is_inside_tree() or selected.is_empty() or (_configured and selected != _role_id):
		last_error = "Configure canonical C31/A1-E2 or C32/A1-E3 once before adding the art leaf"
		return false
	_role_id = selected
	_configured = true
	_sprite.texture = TEXTURES[_role_id].front.standing
	_sprite.flip_h = false
	last_error = ""
	return true


func role_id() -> String:
	return _role_id if _configured else ""


func set_pose(phase: String, world_facing: Vector3, camera: Camera3D) -> void:
	if not _configured or phase not in PHASES:
		_pose_input_error = "C31/C32 pose requires its configured canonical role and closed native/environmental presentation phase"
		return
	if not is_instance_valid(_sprite) or _sprite.is_queued_for_deletion():
		_pose_input_error = "C31/C32 art requires its retained sprite"
		return
	if not is_instance_valid(camera) or not camera.is_inside_tree() or camera.is_queued_for_deletion() or not camera.global_basis.is_finite():
		_pose_input_error = "C31/C32 pose requires the actual finite live camera"
		return
	if is_inside_tree() and camera.get_world_3d() != get_world_3d():
		_pose_input_error = "C31/C32 pose camera must share the actor world"
		return
	var facing := Vector3(world_facing.x, 0.0, world_facing.z)
	var toward := Vector3(camera.global_basis.z.x, 0.0, camera.global_basis.z.z)
	var right := Vector3(camera.global_basis.x.x, 0.0, camera.global_basis.x.z)
	if not world_facing.is_finite() or not facing.is_finite() or facing.is_zero_approx() or toward.is_zero_approx() or right.is_zero_approx():
		_pose_input_error = "C31/C32 pose requires nonzero planar facing and camera axes"
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
		"warning":
			pose = "warning"
		"lock":
			pose = "lock"
		"active":
			pose = "active"
		"recovery":
			pose = "recovery"
		"recoil", "retreat", "regroup":
			pose = phase
	_sprite.texture = TEXTURES[_role_id][artwork_facing][pose]
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
	if not _configured or not TEXTURES.has(_role_id):
		return "C31/C32 art requires its explicit immutable canonical role"
	if not is_inside_tree() or is_queued_for_deletion() or not get_parent() is Node3D or get_parent().is_queued_for_deletion():
		return "C31/C32 art requires a retained live actor presentation parent"
	if transform != Transform3D.IDENTITY or is_set_as_top_level() or process_mode != Node.PROCESS_MODE_DISABLED or is_processing() or is_physics_processing():
		return "C31/C32 art must retain its identity local frame and clockless leaf mode"
	if not is_instance_valid(_sprite) or not _sprite.is_inside_tree() or _sprite.is_queued_for_deletion() or _sprite.get_parent() != self or get_child_count() != 1 or _sprite.get_child_count() != 0:
		return "C31/C32 art requires exactly its retained direct sprite child"
	if _sprite.get_world_3d() != get_world_3d() or (get_parent() as Node3D).get_world_3d() != get_world_3d() or _sprite.transform != Transform3D.IDENTITY or _sprite.is_set_as_top_level():
		return "C31/C32 sprite must retain the actor world and unshifted foot frame"
	if not _pose_input_error.is_empty():
		return _pose_input_error
	if not _sprite.centered or _sprite.pixel_size != _canonical_pixel_size or _sprite.offset != SPRITE_OFFSET or _sprite.axis != Vector3.AXIS_Z or _sprite.billboard != BaseMaterial3D.BILLBOARD_ENABLED or _sprite.fixed_size:
		return "C31/C32 sprite must retain the native feet-pivot billboard settings"
	if _sprite.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or _sprite.shaded or not _sprite.double_sided or _sprite.alpha_cut != SpriteBase3D.ALPHA_CUT_DISCARD or _sprite.alpha_scissor_threshold != 0.5:
		return "C31/C32 sprite must retain nearest unshaded hard-alpha pixels"
	if _sprite.no_depth_test or _sprite.render_priority != 0 or _sprite.sorting_offset != 0.0 or _sprite.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF or _sprite.modulate != Color.WHITE or _sprite.transparency != 0.0 or _sprite.layers != 1 or _sprite.material_override != null or _sprite.material_overlay != null:
		return "C31/C32 sprite must retain ordinary untinted actor depth without overrides"
	if not _sprite.visible or _sprite.get_script() != null:
		return "C31/C32 sprite visibility belongs to its actor parent; child stays a native sprite"
	if _sprite.region_enabled or _sprite.hframes != 1 or _sprite.vframes != 1 or _sprite.frame != 0 or _sprite.flip_v:
		return "C31/C32 sprite must retain its whole standalone native frame"
	var key: String = _texture_key()
	if key.is_empty() or _sprite.texture is AtlasTexture or _sprite.texture.get_size() != Vector2(NATIVE_SIZES[_role_id]):
		return "C31/C32 sprite must use a known role-specific native standalone Texture2D handle"
	var directory: String = REPULSION_ASSET_DIR if key.get_slice("/", 1) in REPULSION_POSES else ASSET_DIR
	var expected_path: String = directory + "%s_%s_%s.png" % [ASSET_NAMES[_role_id], key.get_slice("/", 0), key.get_slice("/", 1)]
	if _sprite.texture.resource_path != expected_path or (_sprite.flip_h and facing_name() != "side"):
		return "C31/C32 texture path or side-only reflection no longer matches its frame"
	return ""


func _texture_key() -> String:
	if not is_instance_valid(_sprite) or not _sprite.texture is Texture2D:
		return ""
	for facing: String in TEXTURES[_role_id]:
		for pose: String in TEXTURES[_role_id][facing]:
			if _sprite.texture == TEXTURES[_role_id][facing][pose]:
				return facing + "/" + pose
	return ""
