class_name CinderAct3RecordedFrameArt
extends Node3D
## SOURCE-ONLY static original-record artwork, not a Playback/NPC/cue/controller.
## No collision, attack groups, clock, Cursor, listener, input or health is owned.
const Sprite = preload("res://scripts/pixel_sprite.gd")
const Equipment = preload("res://scripts/equipment.gd")
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Sequence = preload("res://scripts/combat/replay_sequence.gd")
const API: String = "act3-crystalman-recorded-frame-art-1"
const PRESENTATION: String = "act3_traveller"
const RECIPE_KEYS: Array[String] = ["api_revision", "schema_version", "source_epoch", "generation", "sequence_id", "sequence_sha256", "slots"]
const SLOT_KEYS: Array[String] = ["slot_id", "record_sequence", "position", "direction", "equipment_ids", "action", "progress"]
var last_error: String = ""
var _recipe: Dictionary = {}
var _roots: Array[Node3D] = []
var _sprites: Array[LabSprite] = []
var _original_native: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	set_process(false)
	set_physics_process(false)

## Caller MUST first pass public Gate.snapshot_error(gate, saved_player).
## This verifies only immutable original records; it never prepares a Sequence.
static func recipe_from_complete_gate(gate: Dictionary, sequence: Dictionary) -> Dictionary:
	if not gate.get("capture") is Dictionary or not gate.get("prepared_sequence") is Dictionary or not gate.prepared_sequence.is_empty() or not gate.get("consumed_sequence") is Dictionary or not gate.consumed_sequence.is_empty() or not gate.get("retirement") is Dictionary or not gate.retirement.is_empty(): return {}
	var c: Dictionary = gate.capture
	if not c.get("generation") is int or not c.get("max_slots") is int or c.max_slots not in [1, 2] or c.get("armed") != true or not c.get("slots") is Array or c.slots.size() != c.max_slots or c.get("allocated") != c.max_slots or not c.get("pending") is Array or not c.pending.is_empty() or not c.get("dash_candidate") is Dictionary or not c.dash_candidate.is_empty() or not c.get("retired") is Array or not c.retired.is_empty() or not gate.get("retired_generation") is int or gate.retired_generation >= c.generation: return {}
	var reader = Sequence.new()
	if not reader.snapshot_error(sequence, gate.get("source_epoch", ""), c.generation).is_empty(): return {}
	if not same(sequence.capture_snapshot.slots, c.slots) or sequence.generation != c.generation or sequence.source_epoch != gate.source_epoch: return {}
	var slots: Array = []
	for slot: Dictionary in c.slots:
		var dash: Dictionary = slot.dash
		if not dash.get("path") is Array or dash.path.is_empty() or not dash.path[0] is Dictionary or not Value.is_vector3(dash.path[0].get("position")) or not Value.is_vector3(dash.get("direction")) or not dash.get("equipment_ids") is Dictionary: return {}
		slots.append({"slot_id": slot.slot_id, "record_sequence": dash.sequence, "position": dash.path[0].position.duplicate(), "direction": dash.direction.duplicate(), "equipment_ids": dash.equipment_ids.duplicate(true), "action": "dash", "progress": 0.0})
	return {"api_revision": API, "schema_version": 1, "source_epoch": gate.source_epoch, "generation": c.generation, "sequence_id": sequence.sequence_id, "sequence_sha256": Exact.stringify(sequence).sha256_text(), "slots": slots}

static func recipe_error(recipe: Dictionary) -> String:
	var error: String = Value.value_error(recipe)
	if not error.is_empty(): return error
	if not Value.keys_error(recipe, RECIPE_KEYS).is_empty() or recipe.get("api_revision") != API or not recipe.get("schema_version") is int or recipe.schema_version != 1 or not recipe.get("source_epoch") is String or recipe.source_epoch.is_empty() or not recipe.get("generation") is int or recipe.generation < 1 or not recipe.get("sequence_id") is String or recipe.sequence_id.is_empty() or not sha256_valid(recipe.get("sequence_sha256")) or not recipe.get("slots") is Array or recipe.slots.size() not in [1, 2]: return "Closed immutable recorded-art recipe required"
	for index: int in range(recipe.slots.size()):
		var slot: Variant = recipe.slots[index]
		if not slot is Dictionary or not Value.keys_error(slot, SLOT_KEYS).is_empty() or not slot.get("slot_id") is int or slot.slot_id != index + 1 or not slot.get("record_sequence") is int or slot.record_sequence < 1 or not Value.is_vector3(slot.get("position")) or not Value.is_vector3(slot.get("direction")) or not slot.get("equipment_ids") is Dictionary or not Value.keys_error(slot.equipment_ids, Equipment.SLOTS).is_empty() or slot.get("action") != "dash" or not slot.get("progress") is float or slot.progress != 0.0: return "Each original FIFO dash requires exact position/facing/gear/static-frame identity"
		for key: String in Equipment.SLOTS:
			if not slot.equipment_ids[key] is String: return "Typed original recorded equipment ID required"
		if not Equipment.new().restore(slot.equipment_ids): return "Original canonical recorded equipment IDs required"
	return ""

static func packet_error(packet: Dictionary, gate: Dictionary, sequence: Dictionary) -> String:
	var error: String = Value.value_error(packet)
	if not error.is_empty(): return error
	if not Value.keys_error(packet, ["recipe", "native"]).is_empty() or not packet.get("recipe") is Dictionary or not packet.get("native") is Dictionary: return "Closed whole inert native artwork packet required"
	error = recipe_error(packet.recipe)
	if not error.is_empty(): return error
	var original: Dictionary = recipe_from_complete_gate(gate, sequence)
	if original.is_empty() or not same(original, packet.recipe): return "Framing artwork must bind every original complete unretired Gate slot and historical Sequence"
	if not Value.keys_error(packet.native, ["api_revision", "slots"]).is_empty() or packet.native.get("api_revision") != API or not packet.native.get("slots") is Array or packet.native.slots.size() != original.slots.size(): return "Complete original native art geometry/image packet required"
	for index: int in range(packet.native.slots.size()):
		var n: Variant = packet.native.slots[index]
		if not n is Dictionary or not Value.keys_error(n, ["slot_id", "position", "sprite_position", "pixel_size", "offset", "dimensions", "texture_sha256", "modulate", "layers"]).is_empty() or not n.get("slot_id") is int or n.slot_id != index + 1 or not same(n.get("position"), original.slots[index].position) or not Value.is_vector3(n.get("sprite_position")) or not n.get("pixel_size") is float or not n.get("offset") is Array or not n.get("dimensions") is Array or not sha256_valid(n.get("texture_sha256")) or not n.get("modulate") is Array or not n.get("layers") is int or n.layers != 1: return "Typed immutable native original artwork slot required"
		if not Value.in_range(n.pixel_size, 0.001, 0.1) or not same(n.dimensions, [Sprite.PLAYER_WIDTH, Sprite.PLAYER_HEIGHT]) or n.offset.size() != 2 or n.modulate.size() != 4: return "Original finite native shared quad/image shape required"
		for component: Variant in n.offset:
			if not component is float or not Value.in_range(component, -128.0, 128.0): return "Finite native quad offset required"
		for component: Variant in n.modulate:
			if not component is float or not Value.in_range(component, 0.0, 1.0): return "Finite native recorded-art RGBA required"
	return ""

## Fresh constructor only; no restore/tick/pose sampling or live actor is read.
func configure(recipe: Dictionary) -> bool:
	last_error = recipe_error(recipe)
	if not last_error.is_empty(): return false
	if not is_inside_tree() or not is_node_ready() or not get_tree().paused or not _recipe.is_empty():
		last_error = "Construct only one fresh paused inert recorded-art recipient"
		return false
	_recipe = recipe.duplicate(true)
	for slot: Dictionary in _recipe.slots:
		var root := Node3D.new()
		root.name = "OriginalRecordedSlot" + str(slot.slot_id)
		root.top_level = true
		root.process_mode = Node.PROCESS_MODE_DISABLED
		root.set_process(false)
		root.set_physics_process(false)
		add_child(root)
		root.global_position = Value.read_vector3(slot.position)
		var sprite := Sprite.new()
		sprite.name = "RecordedTraveller"
		sprite.process_mode = Node.PROCESS_MODE_DISABLED
		root.add_child(sprite)
		sprite.set_process(false)
		sprite.set_physics_process(false)
		if not sprite.set_presentation(PRESENTATION):
			last_error = "Original shared Traveller presentation unavailable"; return false
		sprite.set_loadout_visual(slot.equipment_ids.weapon, slot.equipment_ids.jacket, slot.equipment_ids.pants, slot.equipment_ids.shoes)
		sprite.face(Value.read_vector3(slot.direction))
		sprite.set_action("dash", 0.0)
		sprite.modulate = Color(0.83, 0.93, 1.0, 0.70)
		sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sprite.layers = 1
		_roots.append(root); _sprites.append(sprite)
	_original_native = _native_descriptor()
	if _original_native.is_empty():
		last_error = "Actual original shared native image descriptor unavailable"
		return false
	last_error = native_error()
	return last_error.is_empty()

func native_error() -> String:
	if not is_inside_tree() or is_queued_for_deletion() or _recipe.is_empty() or _roots.size() != _recipe.slots.size() or _sprites.size() != _roots.size() or get_child_count() != _roots.size() or process_mode != Node.PROCESS_MODE_DISABLED or is_processing() or is_physics_processing(): return "Actual original inert artwork recipients required"
	for index: int in range(_roots.size()):
		var root: Node3D = _roots[index]
		var sprite: LabSprite = _sprites[index]
		if not is_instance_valid(root) or root.get_parent() != self or root.global_transform != Transform3D(Basis.IDENTITY, Value.read_vector3(_recipe.slots[index].position)) or root.get_child_count() != 1 or root.process_mode != Node.PROCESS_MODE_DISABLED or root.is_processing() or root.is_physics_processing() or not root.visible: return "Original static world-feet art pivot changed"
		if not is_instance_valid(sprite) or sprite.get_parent() != root or sprite.get_script() != Sprite or not sprite.visible or not sprite.is_visible_in_tree() or sprite.process_mode != Node.PROCESS_MODE_DISABLED or sprite.is_processing() or sprite.is_physics_processing() or sprite.presentation_id != PRESENTATION or sprite.texture == null or sprite.texture is AtlasTexture or sprite.billboard != BaseMaterial3D.BILLBOARD_ENABLED or sprite.axis != Vector3.AXIS_Z or sprite.fixed_size or sprite.region_enabled or sprite.hframes != 1 or sprite.vframes != 1 or sprite.frame != 0 or sprite.flip_h or sprite.flip_v or sprite.shaded or sprite.no_depth_test or sprite.material_override != null or sprite.material_overlay != null or sprite.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or sprite.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF or sprite.layers != 1 or sprite.transparency != 0.0 or sprite.modulate != Color(0.83, 0.93, 1.0, 0.70): return "Original shared static recorded-art renderer/material/visibility changed"
		if sprite.global_basis != Basis.IDENTITY or sprite.position != Vector3(0, 0.025, 0) or not Value.in_range(sprite.pixel_size, 0.001, 0.1) or sprite.offset != Vector2(0, Sprite.PLAYER_HEIGHT * 0.5): return "Original native pixel scale/quad feet pivot changed"
		if sprite.weapon_visual_id != _recipe.slots[index].equipment_ids.weapon or sprite.jacket_visual_id != _recipe.slots[index].equipment_ids.jacket or sprite.pants_visual_id != _recipe.slots[index].equipment_ids.pants or sprite.shoes_visual_id != _recipe.slots[index].equipment_ids.shoes: return "Original recorded gear artwork changed"
	if not _original_native.is_empty() and not same(_native_descriptor(), _original_native): return "Actual original image/frame/geometry bytes changed"
	return ""

func capture_packet() -> Dictionary:
	last_error = native_error()
	return {"recipe": _recipe.duplicate(true), "native": _native_descriptor()} if last_error.is_empty() else {}

func native_packet_error(packet: Dictionary, gate: Dictionary, sequence: Dictionary) -> String:
	var error: String = packet_error(packet, gate, sequence)
	if error.is_empty(): error = native_error()
	if error.is_empty() and not same(capture_packet(), packet): error = "Fresh actual native original recorded-art packet differs"
	return error

func _native_descriptor() -> Dictionary:
	var slots: Array = []
	for index: int in range(_sprites.size()):
		var sprite: LabSprite = _sprites[index]
		if not is_instance_valid(sprite) or sprite.texture == null: return {}
		var image: Image = sprite.texture.get_image()
		if image == null or image.get_width() != Sprite.PLAYER_WIDTH or image.get_height() != Sprite.PLAYER_HEIGHT: return {}
		var texture_hash: String = _texture_digest(image)
		if texture_hash.is_empty(): return {}
		slots.append({"slot_id": _recipe.slots[index].slot_id, "position": Value.vector3(_roots[index].global_position), "sprite_position": Value.vector3(sprite.position), "pixel_size": sprite.pixel_size, "offset": [float(sprite.offset.x), float(sprite.offset.y)], "dimensions": [image.get_width(), image.get_height()], "texture_sha256": texture_hash, "modulate": [float(sprite.modulate.r), float(sprite.modulate.g), float(sprite.modulate.b), float(sprite.modulate.a)], "layers": sprite.layers})
	return {"api_revision": API, "slots": slots}

func framing_points(camera: Camera3D) -> Array:
	last_error = native_error()
	if not last_error.is_empty(): return []
	if not is_instance_valid(camera) or not camera.is_inside_tree() or camera.get_world_3d() != get_world_3d() or camera.get_viewport() != get_viewport():
		last_error = "Actual same-world current framing camera required"; return []
	var points: Array = []
	for sprite: LabSprite in _sprites:
		if (camera.cull_mask & sprite.layers) == 0:
			last_error = "Actual current camera excludes recorded artwork layer"; return []
		var mesh: TriangleMesh = sprite.generate_triangle_mesh()
		if mesh == null:
			last_error = "Actual original recorded artwork native quad unavailable"; return []
		for vertex: Vector3 in mesh.get_faces(): points.append(sprite.global_position + camera.global_basis.x * vertex.x + camera.global_basis.y * vertex.y)
	return points

## Optical-only bounds of the ORIGINAL validated historical route. No pose is
## installed, no path is sampled/recomputed, and no Replay cursor is constructed.
func route_framing_points(camera: Camera3D, sequence: Dictionary) -> Array:
	var points: Array = framing_points(camera)
	if points.is_empty(): return []
	if Exact.stringify(sequence).sha256_text() != _recipe.sequence_sha256:
		last_error = "Route optics require the exact original immutable Sequence"; return []
	var reader = Sequence.new()
	if not reader.restore_state(sequence, _recipe.source_epoch, _recipe.generation):
		last_error = reader.last_snapshot_error; return []
	var original: Dictionary = reader.state()
	for index: int in range(_sprites.size()):
		var sprite: LabSprite = _sprites[index]
		var mesh: TriangleMesh = sprite.generate_triangle_mesh()
		var minimum: Vector3 = Vector3.INF
		var maximum: Vector3 = -Vector3.INF
		for sample: Dictionary in original.timeline.slots[index].route:
			for vertex: Vector3 in mesh.get_faces():
				var point: Vector3 = sample.position + sprite.position + camera.global_basis.x * vertex.x + camera.global_basis.y * vertex.y
				minimum = minimum.min(point); maximum = maximum.max(point)
		for x: float in [minimum.x, maximum.x]:
			for y: float in [minimum.y, maximum.y]:
				for z: float in [minimum.z, maximum.z]: points.append(Vector3(x, y, z))
	return points

static func _texture_digest(image: Image) -> String:
	if image == null or image.is_empty(): return ""
	var hash := HashingContext.new()
	var bytes: PackedByteArray = var_to_bytes([image.get_width(), image.get_height(), image.get_format(), image.has_mipmaps(), image.get_data()])
	if hash.start(HashingContext.HASH_SHA256) != OK or hash.update(bytes) != OK: return ""
	return hash.finish().hex_encode()

static func sha256_valid(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for character: String in value:
		if not "0123456789abcdef".contains(character): return false
	return true

static func same(left: Variant, right: Variant) -> bool:
	var wire: String = Exact.stringify(left)
	return not wire.is_empty() and wire == Exact.stringify(right)
