extends Node3D
## Original static nonhostile Dreamsinter-inspired scenery still.
## No physical body, target, threat cue, control, clock, drop or reward.

const TEXTURE: Texture2D = preload("res://assets/acts/act3/dreamsinter-observer.png")
const NATIVE_SIZE := Vector2(1024, 1536)
const FEET_PIVOT := Vector2(554, 1516)
const PIXEL_SIZE: float = 2.05 / 1502.0

var portrait: Sprite3D
var _viewer: Node3D


func _ready() -> void:
	process_physics_priority = 140
	portrait = Sprite3D.new()
	portrait.name = "QuietForestObserver"
	portrait.texture = TEXTURE
	portrait.pixel_size = PIXEL_SIZE
	portrait.offset = Vector2(NATIVE_SIZE.x * 0.5 - FEET_PIVOT.x, FEET_PIVOT.y - NATIVE_SIZE.y * 0.5)
	portrait.position.y = 0.025
	portrait.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	portrait.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	portrait.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	portrait.alpha_scissor_threshold = 0.5
	portrait.no_depth_test = false
	portrait.shaded = false
	portrait.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(portrait)
	refresh_visibility()


## Cosmetic brief projection. This conservative near-view rectangle prevents
## its complete native still hiding the traveller in the fixed portrait.
## It supplies no collision, interaction, effect or gameplay response.
func set_viewer(viewer: Node3D) -> void:
	_viewer = viewer
	refresh_visibility()


func refresh_visibility() -> void:
	if not is_instance_valid(portrait):
		return
	if not is_instance_valid(_viewer):
		portrait.visible = true
		return
	var difference: Vector3 = _viewer.global_position - global_position
	portrait.visible = not (absf(difference.x) < 1.8 and absf(difference.z) < 4.4)


func _physics_process(_delta: float) -> void:
	refresh_visibility()
