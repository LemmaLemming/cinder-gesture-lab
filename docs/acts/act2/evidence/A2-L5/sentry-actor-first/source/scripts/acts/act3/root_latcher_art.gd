class_name CinderAct3RootLatcherArt
extends Node3D
## Owned fixed-bulb art only: no collision, target groups, clocks or damage.
## Four generated stills are candidates; warning/lock/active share raised art.
## One frontal presentation does not establish complete directional animation.
## Native bounds/renderer/scaffold tests are recorded in levels/A3-L2.md.

const SOURCE_PATH: String = "res://assets/acts/act3/root-latcher-atlas.png"
const ATLAS: Texture2D = preload("res://assets/acts/act3/root-latcher-atlas.png")
const PIXEL_SIZE: float = 1.35 / 807.0
const CELL_SIZE := Vector2(627, 627)
const SPRITE_POSITION := Vector3(0, 0.025, 0)
const POSE_ORDER: Array[String] = ["closed", "raised", "exposed", "spent"]
const POSES: Dictionary = {
	"closed": {"region": Rect2(0, 0, 627, 627), "pivot": Vector2(333, 584)},
	"raised": {"region": Rect2(627, 0, 627, 627), "pivot": Vector2(310, 584)},
	"exposed": {"region": Rect2(0, 627, 627, 627), "pivot": Vector2(338, 501)},
	"spent": {"region": Rect2(627, 627, 627, 627), "pivot": Vector2(310, 504)},
}
const PHASE_POSES: Dictionary = {
	"clear": "closed", "idle": "closed",
	"warning": "raised", "lock": "raised", "active": "raised",
	"recovery": "exposed", "defeated": "spent", "spent": "spent",
}

var _stills: Dictionary = {}
var _textures: Dictionary = {}
var _shadow: MeshInstance3D
var _shadow_mesh: CylinderMesh
var _shadow_material: StandardMaterial3D
var _native_pixel_size: float = 0.0
var _phase: String = "clear"
var _pose: String = "closed"
var _last_error: String = ""


func _ready() -> void:
	present(_phase)


## The actor supplies its public phase; art never infers death or vulnerability.
## Explicit defeat retains the quiet spent still. It does not remove an actor.
func present(phase: String) -> bool:
	if not PHASE_POSES.has(phase):
		_last_error = "Unsupported Root Latcher art phase"
		return false
	_ensure_visuals()
	_phase = phase
	_pose = PHASE_POSES[phase]
	for key: String in POSE_ORDER:
		(_stills[key] as Sprite3D).visible = key == _pose
	_shadow.visible = true
	_last_error = ""
	return true


func state() -> Dictionary:
	var pivot: Vector2 = POSES[_pose].pivot
	return {
		"source_path": SOURCE_PATH,
		"phase": _phase,
		"pose_key": _pose,
		"native_size": Vector2(1254, 1254),
		"atlas_region": POSES[_pose].region,
		"pivot": pivot,
		"offset": _offset(pivot),
		"pixel_size": _native_pixel_size,
		"proposed_pixel_size": PIXEL_SIZE,
		"readiness": "verified_native_bounds_four_stills_only",
		"visible": is_instance_valid(_stills.get(_pose)) and (_stills[_pose] as Sprite3D).is_visible_in_tree(),
		"last_error": _last_error,
	}


## Pure complete render bounds for all four possible stills plus actual shadow.
## Shared Game's standard helper rejects AtlasTexture. This narrow owned adapter
## reads actual native item rectangles and pixel size with actual camera axes;
## it uses no guessed opaque contours, culling AABB or physical-body proxy.
## Only zero-margin AtlasTextures and identity world transforms are supported.
## This returns geometry, never camera admission or permission to deal damage.
func framing_points(shell: Node) -> Dictionary:
	if not is_inside_tree() or not is_node_ready() or not is_instance_valid(shell) or not shell.has_method("camera_framing_plan"):
		return _bounds_error("Ready native art and shared camera shell required")
	var camera: Camera3D = shell.get("camera") as Camera3D
	if not is_instance_valid(camera) or camera.projection != Camera3D.PROJECTION_ORTHOGONAL or not camera.global_basis.is_finite():
		return _bounds_error("Actual orthographic camera basis unavailable")
	var camera_basis: Basis = camera.global_basis
	if not camera_basis.is_equal_approx(camera_basis.orthonormalized()) or camera_basis.determinant() <= 0.0:
		return _bounds_error("Camera basis must be unscaled and right-handed")
	if basis != Basis.IDENTITY or global_basis != Basis.IDENTITY or not is_visible_in_tree() or _stills.size() != 4 or _textures.size() != 4 or ATLAS.get_size() != Vector2(1254, 1254):
		return _bounds_error("Root Latcher art transform or native atlas changed")
	var points: Array = []
	for key: String in POSE_ORDER:
		var sprite: Sprite3D = _stills.get(key) as Sprite3D
		var error: String = _settings_error(sprite, key)
		if not error.is_empty():
			return _bounds_error(error)
		var mesh: TriangleMesh = sprite.generate_triangle_mesh()
		if mesh == null:
			return _bounds_error("Native atlas quad unavailable")
		var snapped_corners: Array[Vector3] = []
		for vertex: Vector3 in mesh.get_faces():
			if not vertex.is_finite() or vertex.z != 0.0:
				return _bounds_error("Unsupported native atlas quad")
			if not snapped_corners.has(vertex):
				snapped_corners.append(vertex)
		if snapped_corners.size() != 4 or mesh.get_faces().size() != 6:
			return _bounds_error("Native atlas must provide four complete quad corners")
		# TriangleMesh::create snaps its vertices to 0.0001m. Sprite3D renders
		# the unsnapped item-rectangle corners, so that mesh is a native shape
		# check rather than the authority for complete rendered bounds.
		var rect: Rect2 = sprite.get_item_rect()
		var corners: Array[Vector3] = []
		for x: float in [rect.position.x, rect.end.x]:
			for y: float in [rect.position.y, rect.end.y]:
				var corner := Vector3(x * sprite.pixel_size, y * sprite.pixel_size, 0)
				if not snapped_corners.has(corner.snapped(Vector3.ONE * 0.0001)):
					return _bounds_error("Native atlas mesh differs from its rendered rectangle")
				corners.append(corner)
		for corner: Vector3 in corners:
			points.append(sprite.global_position + camera_basis.x * corner.x + camera_basis.y * corner.y)
	if not is_instance_valid(_shadow) or _shadow.get_parent() != self or _shadow.transform != Transform3D(Basis.IDENTITY, Vector3(0, 0.009, 0)) or not _shadow.visible or _shadow.mesh != _shadow_mesh or _shadow.material_override != _shadow_material or _shadow.material_overlay != null:
		return _bounds_error("Actual rooted contact shadow unavailable")
	var disk: CylinderMesh = _shadow.mesh as CylinderMesh
	if disk == null or Vector3(disk.top_radius, disk.bottom_radius, disk.height) != Vector3(0.32, 0.32, 0.006) or disk.radial_segments != 12:
		return _bounds_error("Contact shadow geometry changed")
	if _shadow_material == null or _shadow_material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or _shadow_material.albedo_color != Color("17131f") or _shadow_material.grow or _shadow_material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
		return _bounds_error("Contact shadow material changed")
	var bounds: AABB = _shadow.get_aabb()
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]:
				points.append(_shadow.global_transform * Vector3(x, y, z))
	return {"error": "", "points": points}


func _settings_error(sprite: Sprite3D, key: String) -> String:
	if not is_instance_valid(sprite) or sprite.get_parent() != self or sprite.transform != Transform3D(Basis.IDENTITY, SPRITE_POSITION):
		return "Root Latcher native still transform changed"
	var texture: AtlasTexture = _textures.get(key) as AtlasTexture
	if texture == null or sprite.texture != texture or texture.atlas != ATLAS or texture.region != POSES[key].region or texture.margin != Rect2() or not texture.filter_clip or texture.get_size() != CELL_SIZE:
		return "Root Latcher native AtlasTexture binding changed"
	var pivot: Vector2 = POSES[key].pivot
	if sprite.get_item_rect() != Rect2(Vector2(-pivot.x, pivot.y - CELL_SIZE.y), CELL_SIZE) or sprite.offset != _offset(pivot) or sprite.pixel_size != _native_pixel_size:
		return "Root Latcher native scale, pivot or item rectangle changed"
	if sprite.billboard != BaseMaterial3D.BILLBOARD_ENABLED or sprite.axis != Vector3.AXIS_Z or sprite.fixed_size or sprite.region_enabled or sprite.hframes != 1 or sprite.vframes != 1 or sprite.frame != 0 or sprite.flip_h or sprite.flip_v or not sprite.centered:
		return "Unsupported Root Latcher billboard mode"
	if sprite.material_override != null or sprite.material_overlay != null or sprite.no_depth_test or sprite.shaded or not sprite.transparent or not sprite.double_sided or sprite.alpha_cut != SpriteBase3D.ALPHA_CUT_DISCARD or sprite.alpha_scissor_threshold != 0.5 or sprite.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or sprite.modulate != Color.WHITE:
		return "Root Latcher material or depth settings changed"
	if sprite.visible != (key == _pose):
		return "Root Latcher presented pose visibility changed"
	return ""


func _offset(pivot: Vector2) -> Vector2:
	# X points right; native Sprite3D image Y maps upward in world rendering.
	return Vector2(CELL_SIZE.x * 0.5 - pivot.x, pivot.y - CELL_SIZE.y * 0.5)


func _bounds_error(error: String) -> Dictionary:
	return {"error": error, "points": []}


func _ensure_visuals() -> void:
	if _stills.is_empty():
		for key: String in POSE_ORDER:
			var texture := AtlasTexture.new()
			texture.atlas = ATLAS
			texture.region = POSES[key].region
			texture.margin = Rect2()
			texture.filter_clip = true
			var sprite := Sprite3D.new()
			sprite.name = "NativeStill_" + key
			sprite.texture = texture
			sprite.offset = _offset(POSES[key].pivot)
			sprite.pixel_size = PIXEL_SIZE
			if _native_pixel_size == 0.0:
				# Retain the exact native real_t value; no scalar tolerance.
				_native_pixel_size = sprite.pixel_size
			sprite.position = SPRITE_POSITION
			sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
			sprite.alpha_scissor_threshold = 0.5
			sprite.no_depth_test = false
			sprite.shaded = false
			sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			sprite.visible = false
			add_child(sprite)
			_textures[key] = texture
			_stills[key] = sprite
	if not is_instance_valid(_shadow):
		_shadow = MeshInstance3D.new()
		_shadow.name = "FilledRootContact"
		var disk := CylinderMesh.new()
		disk.top_radius = 0.32
		disk.bottom_radius = 0.32
		disk.height = 0.006
		disk.radial_segments = 12
		_shadow.mesh = disk
		_shadow_mesh = disk
		_shadow.position.y = 0.009
		_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color("17131f")
		_shadow.material_override = material
		_shadow_material = material
		add_child(_shadow)
