extends Node3D
## Produced still consumer. Native rendering/placement is qualified by evidence.
## A3-L4 C34 is harmless scenery; B05's external low roots own all damage.
## Source: same-folder sullenbode-likeness-v1.png, unchanged 1254 RGBA still.
## SHA256 f45558d704cb00e0b2d751bc495bd24bdeb556e1c1259cbc72c121065bccb852.
## G03/G08/G10/G14/G17 and draft metadata/semantics-review.md are provenance.
## Reuses the owned RootLatcherArt native rectangle/mesh cross-check pattern,
## but accepts an actual Camera3D directly: no Shell donor/private helper.
## Parent supplies the original Texture2D after authorized publication/import,
## fixes this root's translation, and calls disengagement from its real state.
## This consumer never infers disengagement from HP, lease, sun or actions.
## Trial placement (-1.8,0,-3.4) is NOT assigned here or measured in a portrait.
## No HP, collider, target group, cue, interaction, reward or gameplay clock.
## Readiness: limited native cosmetic fixture31/0, original evidence7838.
## Native quad/camera/quiet paused fade/retirement and brief welcome/Draw/hidden
## views are checked; production/full-level/active/recovery art remain unfinished.
## Header updated after closure only; original source bytes stay in evidence.
## Official primary docs inspected 9 Oct 2026:
## https://docs.godotengine.org/en/stable/classes/class_spritebase3d.html
## https://docs.godotengine.org/en/stable/classes/class_sprite3d.html
## Discard is one-bit alpha. Linear modulation below is thresholded cosmetic
## disappearance, NOT promised smooth opacity; nearest/discard .5 stay fixed.

const Codec = preload("res://scripts/campaign/snapshot_codec.gd")

const SOURCE_FILE: String = "sullenbode-likeness-v1.png"
const SOURCE_SHA256: String = "f45558d704cb00e0b2d751bc495bd24bdeb556e1c1259cbc72c121065bccb852"
const NATIVE_SIZE := Vector2(1254, 1254)
const FEET_PIVOT := Vector2(627, 1204)
const SPRITE_OFFSET := Vector2(0, 577)
const TRIAL_PIXEL_SIZE: float = 1.5 / 1166.0
const TRIAL_PARENT_POSITION := Vector3(-1.8, 0, -3.4)
const FADE_DURATION_S: float = 0.8 # Cosmetic trial only; no attack timing.
const PRESENTATION_SCHEMA: int = 1

var _sprite: Sprite3D
var _texture: Texture2D
var _native_pixel_size: float = 0.0
var _native_modulate: Color = Color.WHITE
var _configured: bool = false
var _disengaged: bool = false
var _stage: String = "quiet"
var _fade_remaining_s: float = FADE_DURATION_S


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_physics_process(false)


## Bind once. Texture byte SHA belongs to the publishing parent/resource
## receipt; Texture2D size alone cannot attest original PNG byte identity.
func configure(texture: Texture2D) -> bool:
	if _configured or not is_inside_tree() or not is_node_ready() or texture == null or texture is AtlasTexture or texture.get_size() != NATIVE_SIZE or get_child_count() != 0 or not get_groups().is_empty() or basis != Basis.IDENTITY or global_basis != Basis.IDENTITY or not global_position.is_finite():
		return false
	_texture = texture
	_sprite = Sprite3D.new()
	_sprite.name = "QuietScenicLikeness"
	_sprite.texture = texture
	_sprite.offset = SPRITE_OFFSET
	_sprite.pixel_size = TRIAL_PIXEL_SIZE
	# Retain native real_t after assignment; do not compare with binary64 trial.
	_native_pixel_size = _sprite.pixel_size
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.axis = Vector3.AXIS_Z
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_sprite.alpha_scissor_threshold = 0.5
	_sprite.no_depth_test = false
	_sprite.shaded = false
	_sprite.transparent = true
	_sprite.double_sided = true
	_sprite.centered = true
	_sprite.fixed_size = false
	_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_sprite)
	_configured = true
	_apply_presentation()
	return runtime_error().is_empty()


## Parent supplies its independently established disengagement. A false value
## cannot rearm a latched fade; retry constructs/restores presentation instead.
## This call may latch while paused, but never consumes paused fade time.
func present_parent_disengagement(disengaged: bool) -> bool:
	if not runtime_error().is_empty() or (_disengaged and not disengaged):
		return false
	if disengaged and not _disengaged:
		_disengaged = true
		_stage = "fading"
		_fade_remaining_s = FADE_DURATION_S
		_apply_presentation()
		set_physics_process(true)
	return true


func _physics_process(delta: float) -> void:
	if get_tree().paused or not _configured or _stage != "fading":
		return
	if not is_finite(delta) or delta <= 0.0 or not runtime_error().is_empty():
		return
	_fade_remaining_s = maxf(0.0, _fade_remaining_s - delta)
	if _fade_remaining_s == 0.0:
		_stage = "hidden"
		set_physics_process(false)
	_apply_presentation()


## Closed cosmetic state for a FUTURE aggregate. The parent must include this
## in the same paused transaction as its own disengagement; no save API here.
## Remaining time is authoritative (no wall-clock timestamp or Tween clock).
## A quiet still holds .8s; fading has 0<remaining<=.8; hidden holds exactly0.
func presentation_state() -> Dictionary:
	return {"schema_version": PRESENTATION_SCHEMA, "source_sha256": SOURCE_SHA256, "disengaged": _disengaged, "stage": _stage, "fade_duration_s": FADE_DURATION_S, "fade_remaining_s": _fade_remaining_s}


func presentation_error(data: Dictionary, parent_disengaged: bool) -> String:
	var expected: Array = ["schema_version", "source_sha256", "disengaged", "stage", "fade_duration_s", "fade_remaining_s"]
	if data.size() != expected.size():
		return "Exact cosmetic likeness presentation fields required"
	for key: String in expected:
		if not data.has(key):
			return "Missing cosmetic likeness presentation field"
	if not Codec.is_integer(data.schema_version, PRESENTATION_SCHEMA, PRESENTATION_SCHEMA) or not data.source_sha256 is String or data.source_sha256 != SOURCE_SHA256 or not data.disengaged is bool or data.disengaged != parent_disengaged or not data.stage is String:
		return "Saved likeness must match the parent's actual disengagement"
	if (not data.fade_duration_s is float and not data.fade_duration_s is int) or (not data.fade_remaining_s is float and not data.fade_remaining_s is int):
		return "Finite numeric cosmetic fade fields required"
	var duration: float = float(data.fade_duration_s)
	var remaining: float = float(data.fade_remaining_s)
	if not is_finite(duration) or not is_finite(remaining) or duration != FADE_DURATION_S or remaining < 0.0 or remaining > duration:
		return "Cosmetic likeness fade interval changed"
	if data.stage == "quiet":
		return "Quiet likeness cannot already be disengaged" if data.disengaged or remaining != duration else ""
	if data.stage == "fading":
		return "Fading likeness requires actual disengagement and remaining time" if not data.disengaged or remaining <= 0.0 else ""
	if data.stage == "hidden":
		return "Hidden likeness requires completed disengagement fade" if not data.disengaged or remaining != 0.0 else ""
	return "Unsupported cosmetic likeness stage"


## Silent, no-yield, paused cosmetic restore only. Caller validates its real
## parent state first. This does not restore any source/cue/collision/clock.
func restore_presentation(data: Dictionary, parent_disengaged: bool) -> bool:
	if not _configured or not is_inside_tree() or not get_tree().paused or not runtime_error().is_empty() or not presentation_error(data, parent_disengaged).is_empty():
		return false
	_disengaged = data.disengaged
	_stage = data.stage
	_fade_remaining_s = float(data.fade_remaining_s)
	_apply_presentation()
	set_physics_process(_stage == "fading")
	return true


func state() -> Dictionary:
	return {"source_file": SOURCE_FILE, "source_sha256": SOURCE_SHA256, "native_size": NATIVE_SIZE, "feet_pivot": FEET_PIVOT, "offset": SPRITE_OFFSET, "trial_pixel_size": TRIAL_PIXEL_SIZE, "native_pixel_size": _native_pixel_size, "presentation": presentation_state(), "readiness": "produced_still_consumer_see_asset_record", "runtime_error": runtime_error()}


## Pure COMPLETE quad bounds, even while hidden, for conservative inspection.
## Parent may omit them only when its validated presentation is truly hidden.
## Camera3D is public input, not fetched from a Shell/Player/private property.
## Actual item rectangle and retained native pixel_size are render authority;
## generate_triangle_mesh provides only a snapped native shape cross-check.
func framing_points(camera: Camera3D) -> Dictionary:
	var error: String = runtime_error()
	if not error.is_empty():
		return {"error": error, "points": []}
	if not is_instance_valid(camera) or not camera.is_inside_tree() or camera.projection != Camera3D.PROJECTION_ORTHOGONAL or not camera.global_basis.is_finite() or (camera.cull_mask & _sprite.layers) == 0:
		return {"error": "Actual supported orthographic camera required", "points": []}
	var camera_basis: Basis = camera.global_basis
	if not camera_basis.is_equal_approx(camera_basis.orthonormalized()) or camera_basis.determinant() <= 0.0:
		return {"error": "Unscaled right-handed camera basis required", "points": []}
	var mesh: TriangleMesh = _sprite.generate_triangle_mesh()
	if mesh == null:
		return {"error": "Actual native likeness quad unavailable", "points": []}
	var faces: PackedVector3Array = mesh.get_faces()
	var snapped: Array[Vector3] = []
	for vertex: Vector3 in faces:
		if not vertex.is_finite() or vertex.z != 0.0:
			return {"error": "Unsupported native likeness triangle", "points": []}
		if not snapped.has(vertex):
			snapped.append(vertex)
	if faces.size() != 6 or snapped.size() != 4:
		return {"error": "Four complete native quad corners required", "points": []}
	var rect: Rect2 = _sprite.get_item_rect()
	var points: Array = []
	for x: float in [rect.position.x, rect.end.x]:
		for y: float in [rect.position.y, rect.end.y]:
			var corner := Vector3(x * _sprite.pixel_size, y * _sprite.pixel_size, 0)
			if not snapped.has(corner.snapped(Vector3.ONE * 0.0001)):
				return {"error": "Native triangles differ from full rendered rectangle", "points": []}
			points.append(_sprite.global_position + camera_basis.x * corner.x + camera_basis.y * corner.y)
	return {"error": "", "points": points, "full_quad": true, "displayed_stage": _stage != "hidden"}


## Pure native custody check; not a claim these calls have run in Godot.
func runtime_error() -> String:
	if not _configured or not is_inside_tree() or not is_node_ready() or is_queued_for_deletion() or not is_visible_in_tree() or basis != Basis.IDENTITY or global_basis != Basis.IDENTITY or not global_position.is_finite() or process_mode != Node.PROCESS_MODE_PAUSABLE or not get_groups().is_empty() or get_child_count() != 1:
		return "Ready translated-only harmless scenic root required"
	if not is_instance_valid(_sprite) or _sprite.is_queued_for_deletion() or _sprite.get_parent() != self or _sprite.transform != Transform3D.IDENTITY or _sprite.top_level or not _sprite.get_groups().is_empty():
		return "One native child still without physical or target nodes required"
	if _texture == null or _texture is AtlasTexture or _texture.get_size() != NATIVE_SIZE or _sprite.texture != _texture or _sprite.get_item_rect() != Rect2(Vector2(-FEET_PIVOT.x, FEET_PIVOT.y - NATIVE_SIZE.y), NATIVE_SIZE) or _sprite.offset != SPRITE_OFFSET or _sprite.pixel_size != _native_pixel_size or not is_finite(_native_pixel_size) or _native_pixel_size <= 0.0:
		return "Original full canvas and assigned native scale/pivot required"
	if _sprite.billboard != BaseMaterial3D.BILLBOARD_ENABLED or _sprite.axis != Vector3.AXIS_Z or _sprite.fixed_size or not _sprite.centered or _sprite.region_enabled or _sprite.hframes != 1 or _sprite.vframes != 1 or _sprite.frame != 0 or _sprite.flip_h or _sprite.flip_v:
		return "One fixed-size-in-world full billboard still required"
	if _sprite.material_override != null or _sprite.material_overlay != null or _sprite.no_depth_test or _sprite.shaded or not _sprite.transparent or not _sprite.double_sided or _sprite.alpha_cut != SpriteBase3D.ALPHA_CUT_DISCARD or _sprite.alpha_scissor_threshold != 0.5 or _sprite.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or _sprite.layers != 1 or _sprite.transparency != 0.0 or _sprite.render_priority != 0 or _sprite.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF or _sprite.modulate != _native_modulate or _sprite.visible != (_stage != "hidden"):
		return "Ordinary depth/nearest/discard cosmetic presentation changed"
	return presentation_error(presentation_state(), _disengaged)


func _apply_presentation() -> void:
	var opacity: float = 1.0 if _stage == "quiet" else (_fade_remaining_s / FADE_DURATION_S if _stage == "fading" else 0.0)
	_sprite.modulate = Color(1, 1, 1, opacity)
	_native_modulate = _sprite.modulate # Retain the actual native Color value.
	_sprite.visible = _stage != "hidden"
