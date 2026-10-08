extends Node3D
## Clockless original pixels supplement the actual native spore cluster.
## No native node, cue, target group, field/supply/clock or hit rule is mutated.

const ClusterNative = preload("res://scripts/environment/spore_cluster.gd")
const FieldNative = preload("res://scripts/environment/spore_field.gd")
const InteractionCue = preload("res://scripts/cues/interaction_cue.gd")
const ASSET_DIR: String = "res://assets/acts/act1/grotto/spore-clusters/"
const STATES: Array[String] = ["available", "active", "spent"]
const TEXTURES: Dictionary = {
	"available": preload("res://assets/acts/act1/grotto/spore-clusters/cluster_available.png"),
	"active": preload("res://assets/acts/act1/grotto/spore-clusters/cluster_active.png"),
	"spent": preload("res://assets/acts/act1/grotto/spore-clusters/cluster_spent.png"),
}

var last_error: String = ""
var _cluster: Node3D
var _field: Node3D
var _cluster_id: String = ""
var _full: MeshInstance3D
var _patch: MeshInstance3D
var _cue: Node3D
var _marker: MeshInstance3D
var _native_meshes: Array[Mesh] = []
var _native_materials: Array[Material] = []
var _native_settings: PackedByteArray
var _sprite: Sprite3D
var _sprite_settings: PackedByteArray
var _presented_state: String = "available"


func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	_sprite = Sprite3D.new()
	_sprite.name = "LowClusterSprite"
	_sprite.texture = TEXTURES.available
	_sprite.centered = true
	_sprite.pixel_size = 0.016
	_sprite.offset = Vector2(0, 10) #24x20 canvas, feet pivot(12,20).
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
	# Exact native readbacks include properties stored as native float32.
	_sprite_settings = _sprite_bytes()


func configure(cluster: Node3D, field: Node3D) -> bool:
	if is_inside_tree() or _cluster != null or not _live(cluster) or not _live(field) or cluster.get_script() != ClusterNative or field.get_script() != FieldNative or cluster.get_parent() != field:
		last_error = "Configure once from the actual ready native cluster and field"
		return false
	if not String(field.call("binding_error")).is_empty() or not String(cluster.call("binding_error")).is_empty():
		last_error = "Actual native cluster/field binding must already validate"
		return false
	var cue: Node3D
	for child: Node in cluster.get_children():
		if child.get_script() == InteractionCue:
			if cue != null:
				last_error = "Exactly one actual native interaction cue is required"
				return false
			cue = child as Node3D
	var full := cluster.get_node_or_null("FullCluster") as MeshInstance3D
	var patch := cluster.get_node_or_null("EmptyClusterPatch") as MeshInstance3D
	var marker: MeshInstance3D = cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D if cue != null else null
	if not _live(full) or not _live(patch) or not _live(cue) or not _live(marker) or full.mesh == null or patch.mesh == null or full.material_override == null or patch.material_override == null or marker.material_override == null:
		last_error = "Keep the actual full, patch and cue renderer handles"
		return false
	_cluster = cluster
	_field = field
	_full = full
	_patch = patch
	_cue = cue
	_marker = marker
	_native_meshes.assign([full.mesh, patch.mesh])
	_native_materials.assign([full.material_override, patch.material_override, marker.material_override])
	_native_settings = _native_bytes()
	var state: Dictionary = cluster.call("get_cue_state")
	_cluster_id = String(state.get("id", ""))
	last_error = _native_state_error(state)
	if not last_error.is_empty(): return false
	_presented_state = state.state
	_sprite.texture = TEXTURES[_presented_state]
	return true


## Owner calls after native binding/update, and explicitly after quiet restore.
## Selection reads the actual cluster, never a caller-supplied field phase/clock.
func sync_from_native() -> String:
	var error: String = _structure_error()
	if not error.is_empty(): return error
	var state: Dictionary = _cluster.call("get_cue_state")
	error = _native_state_error(state)
	if not error.is_empty(): return error
	_presented_state = state.state
	_sprite.texture = TEXTURES[_presented_state]
	return ""


## Pure guard; intentionally does not repair drift by assigning settings/state.
func binding_error() -> String:
	var error: String = _structure_error()
	if not error.is_empty(): return error
	var state: Dictionary = _cluster.call("get_cue_state")
	error = _native_state_error(state)
	if not error.is_empty(): return error
	return "Cluster pixels must match its current native state" if _presented_state != state.state else ""


func sprite() -> Sprite3D:
	return _sprite


func state_name() -> String:
	return _presented_state


func framing_points(shell: Node) -> Array:
	if not binding_error().is_empty() or not _live(shell) or not shell.has_method("camera_billboard_points"): return []
	var points: Variant = shell.call("camera_billboard_points", _sprite)
	if not points is Array or points.is_empty(): return []
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite(): return []
	# Native interaction tick extrema also exceed the old +/-0.2 proxy. Keep
	# their actual current mesh bounds; no cue geometry replacement is added.
	var bounds: AABB = _marker.get_aabb()
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]: points.append(_marker.global_transform * Vector3(x, y, z))
	return points


func _structure_error() -> String:
	if not _live(_cluster) or not _live(_field) or _cluster.get_script() != ClusterNative or _field.get_script() != FieldNative or _cluster.get_parent() != _field or not _cluster.is_in_group("environment_attack_targets") or not _field.is_in_group("required_cues"):
		return "Retain actual native field/cluster identity and target membership"
	var native_error: String = String(_field.call("binding_error"))
	if not native_error.is_empty(): return native_error
	if not _live(self) or get_parent() != _cluster or transform != Transform3D.IDENTITY or is_set_as_top_level() or process_mode != Node.PROCESS_MODE_DISABLED or is_processing() or is_physics_processing() or not visible or not is_visible_in_tree() or _cluster.global_basis != Basis.IDENTITY:
		return "Cluster art must retain its live identity anchor and clockless mode"
	if not _live(_full) or not _live(_patch) or not _live(_cue) or not _live(_marker) or _cluster.get_node_or_null("FullCluster") != _full or _cluster.get_node_or_null("EmptyClusterPatch") != _patch or _cue.get_parent() != _cluster or _marker.get_parent() != _cue or _cue.get_script() != InteractionCue or not _cue.is_in_group("required_cues") or _cue.get_node_or_null("RequiredInteractionMarker") != _marker or _full.mesh != _native_meshes[0] or _patch.mesh != _native_meshes[1] or _full.material_override != _native_materials[0] or _patch.material_override != _native_materials[1] or _marker.material_override != _native_materials[2] or _native_bytes() != _native_settings:
		return "Preserve the native full/patch/cue handles, geometry and renderer settings"
	if not _live(_sprite) or _sprite.get_parent() != self or get_child_count() != 1 or _sprite.get_child_count() != 0 or _sprite.get_script() != null or not _sprite.visible or _sprite.get_world_3d() != get_world_3d() or _sprite.is_set_as_top_level() or _sprite_bytes() != _sprite_settings:
		return "Retain exactly the native whole-quad sprite and its canonical settings"
	for kind: String in STATES:
		var texture: Texture2D = TEXTURES[kind]
		if not is_instance_valid(texture) or texture.get_script() != null or texture is AtlasTexture or texture.get_size() != Vector2(24, 20) or texture.resource_path != ASSET_DIR + "cluster_" + kind + ".png": return "Retain all three standalone original Texture2D resources"
	if _presented_state not in STATES or _sprite.texture != TEXTURES[_presented_state]: return "Cluster texture substitution cannot be repaired by presentation sync"
	return ""


func _native_state_error(state: Dictionary) -> String:
	if not _keys(state, ["id", "state", "full", "cue"]) or _cluster_id.is_empty() or not state.id is String or state.id != _cluster_id or not state.state is String or state.state not in STATES or not state.full is bool or state.full != (state.state != "spent") or not state.cue is Dictionary:
		return "Closed native cluster identity/state required"
	var cue: Dictionary = state.cue
	if not _keys(cue, ["api_revision", "state", "trigger", "required", "visible"]) or not cue.api_revision is String or cue.api_revision != "interaction-cue-1" or not cue.state is String or cue.state != state.state or not cue.trigger is String or cue.trigger != "attack" or not cue.required is bool or cue.required != true or not cue.visible is bool or cue.visible != true:
		return "Native attack cue remains the sole state/ring authority"
	if _full.visible != state.full or _patch.visible == state.full or not _cue.visible or not _cue.is_visible_in_tree() or not _marker.visible or not _marker.is_visible_in_tree() or _marker.mesh == null:
		return "Native full/patch and required cue must remain honestly visible"
	return ""


func _sprite_bytes() -> PackedByteArray:
	return var_to_bytes([_sprite.transform, _sprite.process_mode, _sprite.is_processing(), _sprite.is_physics_processing(), _sprite.pixel_size, _sprite.offset, _sprite.centered, _sprite.axis, _sprite.billboard, _sprite.texture_filter, _sprite.shaded, _sprite.double_sided, _sprite.alpha_cut, _sprite.alpha_scissor_threshold, _sprite.no_depth_test, _sprite.fixed_size, _sprite.render_priority, _sprite.cast_shadow, _sprite.modulate, _sprite.transparency, _sprite.layers, _sprite.sorting_offset, _sprite.hframes, _sprite.vframes, _sprite.frame, _sprite.region_enabled, _sprite.flip_h, _sprite.flip_v, _sprite.material_override, _sprite.material_overlay])


func _native_bytes() -> PackedByteArray:
	return var_to_bytes([_full.transform, _patch.transform, _cue.transform, _marker.transform, _full.mesh.get_aabb(), _patch.mesh.get_aabb(), _full.cast_shadow, _patch.cast_shadow, _marker.cast_shadow, _full.layers, _patch.layers, _marker.layers, _full.material_overlay, _patch.material_overlay, _marker.material_overlay, _full.get_surface_override_material_count(), _patch.get_surface_override_material_count(), _marker.get_surface_override_material_count()])


static func _live(node: Node) -> bool:
	return is_instance_valid(node) and node.is_inside_tree() and not node.is_queued_for_deletion()


static func _keys(value: Dictionary, expected: Array) -> bool:
	if value.size() != expected.size(): return false
	for key: Variant in value:
		if not key is String or key not in expected: return false
	return true
