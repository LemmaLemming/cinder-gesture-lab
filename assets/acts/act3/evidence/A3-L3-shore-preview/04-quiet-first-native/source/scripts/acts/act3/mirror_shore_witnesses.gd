extends Node3D
## Static nonhostile C27/C28 stills, using unchanged native generated pixels.
## Independent atlas crops ground their different foremost soles correctly.
## No collider, target group, HP, collection, interaction cue or local clock.

const IMAGE_PATH: String = "res://assets/acts/act3/mirror-shore-witnesses-v1.png"
const PIXEL_SIZE: float = 1.0 / 600.0
const PIVOT_GAP: float = 557.0 / 600.0
const CROPS: Array[Rect2] = [Rect2(117, 347, 652, 864), Rect2(773, 0, 339, 1248)]
const OFFSETS: Array[Vector2] = [Vector2(-22, 424), Vector2(-79.5, 616)]

var _figures: Array[Sprite3D] = []
var _texture: Texture2D
var _error: String = ""


func _ready() -> void:
	_texture = load(IMAGE_PATH) as Texture2D
	if _texture == null or _texture.get_size() != Vector2(1254, 1254):
		_error = "Shore witnesses require their original native1254 transparent cutout"
		return
	for index: int in range(2):
		var atlas := AtlasTexture.new()
		atlas.atlas = _texture
		atlas.region = CROPS[index]
		atlas.margin = Rect2()
		atlas.filter_clip = true
		var figure := Sprite3D.new()
		figure.name = "PolecrabNetMending" if index == 0 else "GleameilListening"
		figure.texture = atlas
		figure.pixel_size = PIXEL_SIZE
		figure.offset = OFFSETS[index]
		figure.position = Vector3((-0.5 if index == 0 else 0.5) * PIVOT_GAP, 0.02, 0)
		figure.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		figure.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		figure.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		figure.alpha_scissor_threshold = 0.5
		figure.no_depth_test = false
		figure.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(figure)
		_figures.append(figure)


func runtime_error() -> String:
	if not _error.is_empty():
		return _error
	if not is_inside_tree() or is_queued_for_deletion() or _figures.size() != 2 or not is_instance_valid(_texture):
		return "Shore witnesses require their two live static native figures"
	for index: int in range(2):
		if not is_instance_valid(_figures[index]):
			return "Shore witness figure was removed"
		var figure: Sprite3D = _figures[index]
		if figure.get_parent() != self or not figure.is_inside_tree() or figure.is_queued_for_deletion() or not figure.texture is AtlasTexture:
			return "Shore witness figure must retain its original atlas and ancestry"
		var atlas: AtlasTexture = figure.texture as AtlasTexture
		if atlas.atlas != _texture or atlas.region != CROPS[index] or atlas.margin != Rect2() or not atlas.filter_clip:
			return "Shore witness original-pixel crop changed"
		if figure.offset != OFFSETS[index] or figure.pixel_size != PIXEL_SIZE or figure.position != Vector3((-0.5 if index == 0 else 0.5) * PIVOT_GAP, 0.02, 0):
			return "Shore witness native scale or foremost-sole pivot changed"
		if figure.no_depth_test or figure.alpha_cut != SpriteBase3D.ALPHA_CUT_DISCARD or figure.alpha_scissor_threshold != 0.5 or figure.billboard != BaseMaterial3D.BILLBOARD_ENABLED or figure.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST:
			return "Shore witnesses require ordinary-depth clipped nearest billboard pixels"
	return ""
