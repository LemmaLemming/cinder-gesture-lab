class_name CinderAuthoredEnemySequence
extends RefCounted
## Pure authored-enemy definition transport, separate from Player capture.
## One stationary-owner C52 cycle: harmless straight render travel, then one
## instant enemy slash. This codec cannot authenticate an actual world/actor,
## reserve an exchange, retire a cycle, move anything or apply damage.

const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const API_REVISION: String = "authored-enemy-sequence-1"
const ACTION_API_REVISION: String = "authored-enemy-action-1"
const MAX_COORDINATE: float = 512.0
const MAX_TIME_S: float = 3600.0
const MAX_ROLE_VALUE: float = 1000000.0
const MAX_INPUT_DEPTH: int = 32
const MAX_INPUT_NODES: int = 65536
const MAX_INPUT_ENTRIES: int = 16384
const MAX_INPUT_BYTES: int = 1024 * 1024
const HEADER_KEYS: Array[String] = ["api_revision", "schema_version", "provenance", "sequence_id", "source_id", "source_epoch", "generation", "profile_id", "definition", "resolved_role", "world", "authored", "timeline"]
const DEFINITION_KEYS: Array[String] = ["definition_id", "definition_revision", "role_id", "raw_role", "timing_floors", "recognition_s", "route", "travel_clearance", "slash", "presentation"]
const RAW_ROLE_KEYS: Array[String] = ["raw_damage", "windup_s", "lock_s", "active_s", "recovery_s", "attack_interval_s", "max_hp", "move_speed"]
const SLASH_KEYS: Array[String] = ["world_origin", "direction", "reach", "cone_min_dot", "origin_disk_radius", "max_vertical_distance", "los_height", "commitment_duration_s", "visual_duration_s"]
const ACTION_KEYS: Array[String] = ["api_revision", "schema_version", "provenance", "sequence_id", "source_id", "source_epoch", "generation", "role_id", "profile_id", "kind", "world_origin", "direction", "damage", "commitment_duration_s", "source_attack_interval_s", "visual_duration_s", "geometry"]

var last_error: String = ""
var last_snapshot_error: String = ""
var _json: Dictionary = {}


func configure(sequence_id: String, native_definition: Dictionary, source_id: String, source_epoch: String, generation: int, profile_id: String, prepared_world: Dictionary) -> bool:
	if not _json.is_empty():
		return _reject("Immutable authored sequence already configured")
	var error: String = _native_definition_error(native_definition)
	if error.is_empty():
		error = _world_error(prepared_world)
	if not error.is_empty():
		return _reject(error)
	var encoded: Dictionary = _encode_definition(native_definition)
	if encoded.is_empty():
		return _reject("Definition requires its exact native-vector constructor shape")
	error = _input_error(sequence_id, encoded, source_id, source_epoch, generation, profile_id, prepared_world)
	if not error.is_empty():
		return _reject(error)
	var resolved: Dictionary = _resolve(encoded, profile_id)
	var authored: Dictionary = _authored(encoded, resolved)
	var candidate: Dictionary = {"api_revision": API_REVISION, "schema_version": 1, "provenance": "enemy_authored", "sequence_id": sequence_id, "source_id": source_id, "source_epoch": source_epoch, "generation": generation, "profile_id": profile_id, "definition": encoded, "resolved_role": resolved, "world": prepared_world.duplicate(true), "authored": authored, "timeline": _timeline(sequence_id, source_id, source_epoch, generation, profile_id, encoded, resolved, authored)}
	error = snapshot_error(candidate, source_epoch, generation)
	if not error.is_empty():
		return _reject(error)
	_json = candidate
	last_error = ""
	return true


func state() -> Dictionary:
	if _json.is_empty():
		return {}
	var native: Dictionary = _json.duplicate(true)
	native.authored.tether_position = Codec.read_vector3(native.authored.tether_position)
	for point: Dictionary in native.definition.route:
		point.position = Codec.read_vector3(point.position)
	native.definition.slash.world_origin = Codec.read_vector3(native.definition.slash.world_origin)
	native.definition.slash.direction = Codec.read_vector3(native.definition.slash.direction)
	for slot: Dictionary in native.timeline.slots:
		for point: Dictionary in slot.route:
			point.position = Codec.read_vector3(point.position)
		for event: Dictionary in slot.events:
			event.record.world_origin = Codec.read_vector3(event.record.world_origin)
			event.record.direction = Codec.read_vector3(event.record.direction)
	return native


func snapshot_state() -> Dictionary:
	return _json.duplicate(true)


static func action_record_error(record: Dictionary) -> String:
	# Finite standalone transport/geometry validation only. Full Sequence
	# derivation + live binding_error authenticate resolved damage/provenance.
	var error: String = _safe_json_error(record)
	if error.is_empty():
		error = Codec.keys_error(record, ACTION_KEYS)
	if not error.is_empty():
		return error
	if not record.api_revision is String or not record.provenance is String or not record.kind is String or not record.role_id is String or record.api_revision != ACTION_API_REVISION or typeof(record.schema_version) != TYPE_INT or record.schema_version != 1 or record.provenance != "enemy_authored" or record.kind != "enemy_slash" or record.role_id != "C52" or typeof(record.generation) != TYPE_INT or not Codec.is_integer(record.generation, 1):
		return "Typed one-cycle enemy slash identity required"
	for key: String in ["sequence_id", "source_id", "source_epoch", "profile_id"]:
		if not _id(record[key]):
			return "Bounded enemy source/cycle/profile identity required"
	if not _vector_error(record.world_origin).is_empty() or not _vector_error(record.direction).is_empty() or not record.geometry is Dictionary:
		return "Canonical native enemy action points/geometry required"
	if not Codec.in_range(record.damage, 0.0, MAX_ROLE_VALUE) or float(record.damage) <= 0.0:
		return "Positive finite resolved enemy damage required"
	for key: String in ["commitment_duration_s", "source_attack_interval_s", "visual_duration_s"]:
		if not Codec.in_range(record[key], 0.0, MAX_TIME_S) or float(record[key]) <= 0.0:
			return "Positive bounded enemy action duration required"
	var geometry: Dictionary = record.geometry
	if not Codec.keys_error(geometry, ["shape", "reach", "cone_min_dot", "origin_disk_radius", "max_vertical_distance", "los"]).is_empty() or not geometry.shape is String or geometry.shape != "radial_cone" or not geometry.los is Dictionary or not Codec.keys_error(geometry.los, ["policy", "height", "collision_mask"]).is_empty() or not geometry.los.policy is String or geometry.los.policy != "scenery_ray_from_source_to_target" or typeof(geometry.los.collision_mask) != TYPE_INT or geometry.los.collision_mask != 1:
		return "Exact existing scenery-ray radial-cone policy required"
	if not Codec.in_range(geometry.reach, 0.001, 32.0) or not Codec.in_range(geometry.max_vertical_distance, 0.001, 4.0) or not Codec.in_range(geometry.los.height, 0.001, 4.0) or not Codec.is_number(geometry.cone_min_dot) or not Codec.is_number(geometry.origin_disk_radius):
		return "Enemy slash exceeds the supported projection envelope"
	return Geometry.error(Geometry.cone(Codec.read_vector3(record.world_origin), Codec.read_vector3(record.direction), float(geometry.reach), float(geometry.cone_min_dot), float(geometry.origin_disk_radius)))


static func decode_action_record(record: Dictionary) -> Dictionary:
	if not action_record_error(record).is_empty():
		return {}
	var native: Dictionary = record.duplicate(true)
	native.world_origin = Codec.read_vector3(native.world_origin)
	native.direction = Codec.read_vector3(native.direction)
	return native


func snapshot_error(snapshot: Dictionary, source_epoch: String, generation: int) -> String:
	# Syntax and deterministic derivation only. An internally valid definition
	# is NOT proof it belongs to the actual owner; binding_error is mandatory.
	var error: String = _safe_json_error(snapshot)
	if error.is_empty():
		error = Codec.keys_error(snapshot, HEADER_KEYS)
	if not error.is_empty():
		return error
	if not snapshot.api_revision is String or not snapshot.provenance is String or not snapshot.source_epoch is String or snapshot.api_revision != API_REVISION or typeof(snapshot.schema_version) != TYPE_INT or snapshot.schema_version != 1 or snapshot.provenance != "enemy_authored" or snapshot.source_epoch != source_epoch or typeof(snapshot.generation) != TYPE_INT or snapshot.generation != generation:
		return "Authored enemy API/provenance/epoch/generation differs"
	if not snapshot.definition is Dictionary or not snapshot.resolved_role is Dictionary or not snapshot.world is Dictionary or not snapshot.authored is Dictionary or not snapshot.timeline is Dictionary:
		return "Closed authored enemy definition/role/world/timetable required"
	error = _input_error(snapshot.sequence_id, snapshot.definition, snapshot.source_id, source_epoch, generation, snapshot.profile_id, snapshot.world)
	if not error.is_empty():
		return error
	var resolved: Dictionary = _resolve(snapshot.definition, snapshot.profile_id)
	var authored: Dictionary = _authored(snapshot.definition, resolved)
	if not exact_equal(snapshot.resolved_role, resolved) or not exact_equal(snapshot.authored, authored) or not exact_equal(snapshot.timeline, _timeline(snapshot.sequence_id, snapshot.source_id, source_epoch, generation, snapshot.profile_id, snapshot.definition, resolved, authored)):
		return "Role, compact timeline and every enemy action must derive exactly from the immutable definition"
	return ""


func binding_error(snapshot: Dictionary, expected_source_id: String, source_epoch: String, generation: int, profile_id: String, expected_native_definition: Dictionary, actual_world: Dictionary) -> String:
	# The parent supplies the ACTUAL retained source's immutable definition,
	# actual Scheduler profile and freshly measured native world/domain guards.
	# Caller ID equality alone does not authenticate Node/object custody.
	var error: String = snapshot_error(snapshot, source_epoch, generation)
	if not error.is_empty():
		return error
	var encoded: Dictionary = _encode_definition(expected_native_definition)
	if encoded.is_empty() or snapshot.source_id != expected_source_id or snapshot.profile_id != profile_id or not exact_equal(snapshot.definition, encoded) or not exact_equal(snapshot.world, actual_world):
		return "Actual source/definition/cycle/profile/world binding differs"
	return ""


func restore_state(snapshot: Dictionary, source_epoch: String, generation: int) -> bool:
	last_snapshot_error = snapshot_error(snapshot, source_epoch, generation)
	if not last_snapshot_error.is_empty():
		return false
	if not _json.is_empty() and not exact_equal(_json, snapshot):
		last_snapshot_error = "Immutable authored enemy plan cannot be replaced"
		return false
	if _json.is_empty():
		_json = snapshot.duplicate(true)
	last_error = ""
	return true


static func exact_equal(left: Variant, right: Variant) -> bool:
	if not _safe_json_error(left).is_empty() or not _safe_json_error(right).is_empty():
		return false
	var encoded: String = Exact.stringify(left)
	return not encoded.is_empty() and encoded == Exact.stringify(right)


func _encode_definition(native: Dictionary) -> Dictionary:
	# No deepcopy until all branches are closed primitives, except the four
	# explicitly allowed native vectors. Cycles/objects reject without descent.
	if not _native_definition_error(native).is_empty():
		return {}
	var encoded: Dictionary = native.duplicate(true)
	for point: Variant in encoded.route:
		if not point is Dictionary or not Codec.keys_error(point, ["position", "at_s"]).is_empty() or not point.get("position") is Vector3 or not point.position.is_finite():
			return {}
		point["position"] = Codec.vector3(point.position)
	for key: String in ["world_origin", "direction"]:
		if not encoded.slash.get(key) is Vector3 or not encoded.slash[key].is_finite():
			return {}
		encoded.slash[key] = Codec.vector3(encoded.slash[key])
	return encoded


static func _native_definition_error(native: Dictionary) -> String:
	var error: String = _closed_error(native, DEFINITION_KEYS)
	if not error.is_empty():
		return error
	if not _id(native.definition_id) or typeof(native.definition_revision) != TYPE_INT or not Codec.is_integer(native.definition_revision, 1) or not native.role_id is String or native.role_id != "C52" or not Codec.is_number(native.recognition_s):
		return "Closed primitive definition identity/recognition required"
	for branch: String in ["raw_role", "timing_floors", "travel_clearance", "slash", "presentation"]:
		if not native[branch] is Dictionary:
			return "Closed native definition branch required: " + branch
	error = _closed_error(native.raw_role, RAW_ROLE_KEYS)
	if error.is_empty():
		error = _closed_error(native.timing_floors, ["windup_s", "lock_s", "recovery_s"])
	if error.is_empty():
		error = _closed_error(native.travel_clearance, ["radius_m", "height_m"])
	if error.is_empty():
		error = _closed_error(native.slash, SLASH_KEYS)
	if error.is_empty():
		error = _closed_error(native.presentation, ["presentation_id", "presentation_revision"])
	if not error.is_empty():
		return error
	for branch: String in ["raw_role", "timing_floors", "travel_clearance"]:
		for value: Variant in native[branch].values():
			if not Codec.is_number(value):
				return "Finite primitive definition number required: " + branch
	for key: String in SLASH_KEYS:
		if key in ["world_origin", "direction"]:
			if not native.slash[key] is Vector3 or not native.slash[key].is_finite():
				return "Only explicit finite slash vectors are allowed"
		elif not Codec.is_number(native.slash[key]):
			return "Finite primitive slash number required: " + key
	if not _id(native.presentation.presentation_id) or typeof(native.presentation.presentation_revision) != TYPE_INT or not Codec.is_integer(native.presentation.presentation_revision, 1):
		return "Closed primitive source presentation identity required"
	if not native.route is Array or native.route.size() != 2:
		return "Exactly two native route endpoints required"
	for point: Variant in native.route:
		if not point is Dictionary or not _closed_error(point, ["position", "at_s"]).is_empty() or not point.position is Vector3 or not point.position.is_finite() or not Codec.is_number(point.at_s):
			return "Only explicit route vectors and finite primitive times are allowed"
	return ""


static func _closed_error(value: Dictionary, keys: Array) -> String:
	if value.size() != keys.size():
		return "Closed definition has missing or unsupported fields"
	for key: Variant in value:
		if not key is String:
			return "Definition keys must be native Strings"
	return Codec.keys_error(value, keys)


static func _safe_json_error(value: Variant) -> String:
	# Unlike a per-container bound, one global traversal budget also bounds
	# aliased expanding trees. Cycles terminate at the depth/node boundary.
	var budget: Array[int] = [MAX_INPUT_NODES, MAX_INPUT_BYTES]
	return _walk_json(value, 0, budget)


static func _walk_json(value: Variant, depth: int, budget: Array[int]) -> String:
	budget[0] -= 1
	budget[1] -= 16
	if depth > MAX_INPUT_DEPTH or budget[0] < 0 or budget[1] < 0:
		return "Authored transport exceeds bounded depth/node/byte budget"
	match typeof(value):
		TYPE_NIL, TYPE_BOOL:
			return ""
		TYPE_INT:
			return "" if value >= -Codec.MAX_SAFE_INTEGER and value <= Codec.MAX_SAFE_INTEGER else "Integer exceeds exact safe range"
		TYPE_FLOAT:
			return "" if is_finite(value) else "Finite transport scalars required"
		TYPE_STRING:
			if value.length() > MAX_INPUT_BYTES:
				return "Authored transport string exceeds byte budget"
			budget[1] -= value.to_utf8_buffer().size()
			return "" if budget[1] >= 0 else "Authored transport exceeds byte budget"
		TYPE_ARRAY:
			if value.size() > MAX_INPUT_ENTRIES:
				return "Authored transport array exceeds entry budget"
			for entry: Variant in value:
				var error: String = _walk_json(entry, depth + 1, budget)
				if not error.is_empty():
					return error
		TYPE_DICTIONARY:
			if value.size() > MAX_INPUT_ENTRIES:
				return "Authored transport dictionary exceeds entry budget"
			for key: Variant in value:
				if not key is String:
					return "Authored transport dictionary keys must be Strings"
				var error: String = _walk_json(key, depth + 1, budget)
				if error.is_empty():
					error = _walk_json(value[key], depth + 1, budget)
				if not error.is_empty():
					return error
		_:
			return "Foreign object/native type is not authored JSON transport"
	return ""


func _input_error(sequence_id: Variant, definition: Dictionary, source_id: Variant, source_epoch: String, generation: int, profile_id: Variant, world: Dictionary) -> String:
	if not _id(sequence_id) or not _id(source_id) or not _id(source_epoch) or generation < 1 or generation > Codec.MAX_SAFE_INTEGER or not _id(profile_id):
		return "Stable bounded source/sequence/epoch/cycle/profile identity required"
	var error: String = _safe_json_error(definition)
	if error.is_empty():
		error = Codec.keys_error(definition, DEFINITION_KEYS)
	if not error.is_empty():
		return error
	if not _id(definition.definition_id) or typeof(definition.definition_revision) != TYPE_INT or not Codec.is_integer(definition.definition_revision, 1) or not definition.role_id is String or definition.role_id != "C52":
		return "This candidate supports only explicit C52 definition identity"
	if not definition.raw_role is Dictionary or not definition.timing_floors is Dictionary or not Codec.keys_error(definition.raw_role, RAW_ROLE_KEYS).is_empty() or not Codec.keys_error(definition.timing_floors, ["windup_s", "lock_s", "recovery_s"]).is_empty():
		return "Exact immutable raw role and timing floors required"
	for key: String in RAW_ROLE_KEYS:
		if key == "move_speed":
			if not Codec.is_number(definition.raw_role[key]) or float(definition.raw_role[key]) != 0.0:
				return "Physical source must be stationary; render travel is separate"
		elif not Codec.in_range(definition.raw_role[key], 0.0, MAX_ROLE_VALUE) or float(definition.raw_role[key]) <= 0.0:
			return "Positive bounded raw role value required: " + key
	for key: String in ["windup_s", "lock_s", "active_s", "recovery_s", "attack_interval_s"]:
		if float(definition.raw_role[key]) > MAX_TIME_S:
			return "Role timing exceeds supported clock envelope"
	for key: String in ["windup_s", "lock_s", "recovery_s"]:
		if not Codec.in_range(definition.timing_floors[key], 0.0, MAX_TIME_S) or float(definition.timing_floors[key]) <= 0.0:
			return "Positive bounded timing floor required"
	if not Codec.in_range(definition.recognition_s, 0.0, MAX_TIME_S) or float(definition.recognition_s) <= 0.0:
		return "Positive recognition budget required"
	if not definition.route is Array or definition.route.size() != 2:
		return "First support is one straight two-endpoint harmless render route"
	for point: Variant in definition.route:
		if not point is Dictionary or not Codec.keys_error(point, ["position", "at_s"]).is_empty() or not _vector_error(point.get("position")).is_empty() or not Codec.in_range(point.get("at_s"), 0.0, MAX_TIME_S):
			return "Finite canonical route endpoints/times required"
	var start: Vector3 = Codec.read_vector3(definition.route[0].position)
	var finish: Vector3 = Codec.read_vector3(definition.route[1].position)
	var duration_s: float = float(definition.route[1].at_s)
	if float(definition.route[0].at_s) != 0.0 or duration_s <= 0.0 or start.y != finish.y or start == finish:
		return "One positive same-height route, beginning at local zero, required"
	if not definition.travel_clearance is Dictionary or not Codec.keys_error(definition.travel_clearance, ["radius_m", "height_m"]).is_empty() or not Codec.in_range(definition.travel_clearance.get("radius_m"), 0.001, 4.0) or not Codec.in_range(definition.travel_clearance.get("height_m"), 0.001, 8.0) or float(definition.travel_clearance.height_m) < 2.0 * float(definition.travel_clearance.radius_m):
		return "Explicit bounded upright capsule for render-path scenery proof required"
	if not definition.slash is Dictionary or not Codec.keys_error(definition.slash, SLASH_KEYS).is_empty():
		return "One separately typed source-owned slash required"
	var slash: Dictionary = definition.slash
	if not _vector_error(slash.world_origin).is_empty() or not _vector_error(slash.direction).is_empty() or not exact_equal(slash.world_origin, definition.route[1].position):
		return "Slash origin must be the exact authored route endpoint, without snapping"
	for key: String in ["commitment_duration_s", "visual_duration_s"]:
		if not Codec.in_range(slash[key], 0.0, MAX_TIME_S) or float(slash[key]) <= 0.0:
			return "Explicit positive bounded source-owned slash duration required"
	if not Codec.in_range(slash.reach, 0.001, 32.0) or not Codec.in_range(slash.max_vertical_distance, 0.001, 4.0) or not Codec.in_range(slash.los_height, 0.001, 4.0) or not Codec.is_number(slash.origin_disk_radius) or not Codec.is_number(slash.cone_min_dot):
		return "Slash must fit existing radial-cone/projected LOS envelope"
	error = Geometry.error(Geometry.cone(Codec.read_vector3(slash.world_origin), Codec.read_vector3(slash.direction), float(slash.reach), float(slash.cone_min_dot), float(slash.origin_disk_radius)))
	if not error.is_empty():
		return error
	var resolved: Dictionary = _resolve(definition, profile_id)
	if resolved.is_empty():
		return "Raw role cannot freshly resolve against the actual selected profile"
	for key: String in ["windup_s", "lock_s", "active_s", "recovery_s", "attack_interval_s"]:
		if not Codec.in_range(resolved.get(key), 0.0, MAX_TIME_S):
			return "Resolved role timing exceeds supported envelope"
	if float(resolved.active_s) != duration_s + float(slash.commitment_duration_s):
		return "Active budget must exactly equal travel plus slash commitment; no arbitrary idle padding"
	if float(slash.visual_duration_s) > float(resolved.active_s) + float(resolved.recovery_s):
		return "Ornament cannot continue beyond complete source cycle"
	if not Codec.in_range(resolved.get("damage"), 0.0, MAX_ROLE_VALUE) or float(resolved.damage) <= 0.0:
		return "Resolved finite enemy damage exceeds the supported role envelope"
	if not definition.presentation is Dictionary or not Codec.keys_error(definition.presentation, ["presentation_id", "presentation_revision"]).is_empty() or not _id(definition.presentation.get("presentation_id")) or typeof(definition.presentation.get("presentation_revision")) != TYPE_INT or not Codec.is_integer(definition.presentation.presentation_revision, 1):
		return "Source-owned stable presentation identity required; no Player gear schema"
	return _world_error(world)


func _world_error(world: Dictionary) -> String:
	var error: String = _safe_json_error(world)
	if error.is_empty():
		error = Codec.keys_error(world, ["world_revision", "collision_fingerprint", "floor_signature"])
	if not error.is_empty():
		return error
	if typeof(world.world_revision) != TYPE_INT or not Codec.is_integer(world.world_revision, 1) or not world.collision_fingerprint is Dictionary or not world.floor_signature is Array or world.floor_signature.is_empty() or world.floor_signature.size() > 32:
		return "Prepared actual world revision/collision/domain guards required"
	var collision: Dictionary = world.collision_fingerprint
	if not Codec.keys_error(collision, ["schema_version", "physics_engine", "physics_ticks_per_second", "colliders"]).is_empty() or typeof(collision.schema_version) != TYPE_INT or collision.schema_version != 1 or not collision.physics_engine is String or typeof(collision.physics_ticks_per_second) != TYPE_INT or not Codec.is_integer(collision.physics_ticks_per_second, 1) or not collision.colliders is Array or collision.colliders.is_empty() or collision.colliders.size() > 256:
		return "Supported native collision fingerprint descriptor required"
	for floor_unit: Variant in world.floor_signature:
		if not floor_unit is Dictionary or not Codec.keys_error(floor_unit, ["body_path", "shape_path", "safe_rect", "top_y"]).is_empty() or not _id(floor_unit.get("body_path")) or not _id(floor_unit.get("shape_path")) or not floor_unit.safe_rect is Array or floor_unit.safe_rect.size() != 4 or not Codec.in_range(floor_unit.top_y, -MAX_COORDINATE, MAX_COORDINATE):
			return "Canonical native floor signature entries required"
		for scalar: Variant in floor_unit.safe_rect:
			if not Codec.in_range(scalar, -MAX_COORDINATE, MAX_COORDINATE):
				return "Authored floor domain exceeds supported coordinates"
		if float(floor_unit.safe_rect[2]) <= 0.0 or float(floor_unit.safe_rect[3]) <= 0.0:
			return "Positive actual authored floor domain required"
	# Nested collider descriptors remain the existing native Scheduler schema;
	# mandatory exact actual-world comparison authenticates their full contents.
	return ""


func _resolve(definition: Dictionary, profile_id: String) -> Dictionary:
	return Difficulty.new().resolve_role(definition.raw_role, profile_id, definition.timing_floors)


func _authored(definition: Dictionary, resolved: Dictionary) -> Dictionary:
	return {"recognition_s": definition.recognition_s, "warning_s": float(resolved.windup_s) - float(resolved.lock_s), "locked_lead_s": resolved.lock_s, "inter_echo_gap_s": 0.0, "final_recovery_s": resolved.recovery_s, "tether_position": definition.route[1].position.duplicate()}


func _timeline(sequence_id: String, source_id: String, source_epoch: String, generation: int, profile_id: String, definition: Dictionary, resolved: Dictionary, authored: Dictionary) -> Dictionary:
	var slash: Dictionary = definition.slash
	var start_s: float = float(authored.warning_s) + float(authored.locked_lead_s)
	var slash_at_s: float = start_s + float(definition.route[1].at_s)
	# Keep the event's commitment endpoint and slot endpoint the identical
	# computed scalar; do not rely on reassociating floating-point additions.
	var end_s: float = slash_at_s + float(slash.commitment_duration_s)
	var tether_until_s: float = end_s + float(resolved.recovery_s)
	# Match the ordinary Scheduler policy: attack interval begins at active,
	# not at warning origin or slash dispatch. Recovery may hold it longer.
	var source_ready_s: float = maxf(tether_until_s, start_s + float(resolved.attack_interval_s))
	var record: Dictionary = {"api_revision": ACTION_API_REVISION, "schema_version": 1, "provenance": "enemy_authored", "sequence_id": sequence_id, "source_id": source_id, "source_epoch": source_epoch, "generation": generation, "role_id": definition.role_id, "profile_id": profile_id, "kind": "enemy_slash", "world_origin": slash.world_origin.duplicate(), "direction": slash.direction.duplicate(), "damage": resolved.damage, "commitment_duration_s": slash.commitment_duration_s, "source_attack_interval_s": resolved.attack_interval_s, "visual_duration_s": slash.visual_duration_s, "geometry": {"shape": "radial_cone", "reach": slash.reach, "cone_min_dot": slash.cone_min_dot, "origin_disk_radius": slash.origin_disk_radius, "max_vertical_distance": slash.max_vertical_distance, "los": {"policy": "scenery_ray_from_source_to_target", "height": slash.los_height, "collision_mask": 1}}}
	var event: Dictionary = {"event_id": "%s/cycle-%d/slash" % [sequence_id, generation], "kind": "enemy_slash", "event_ordinal": 1, "at_s": slash_at_s, "commitment_until_s": end_s, "ready_s": source_ready_s, "damage_timing": "instant_at_execution", "record": record}
	var route: Array = []
	for point: Dictionary in definition.route:
		route.append({"position": point.position.duplicate(), "at_s": start_s + float(point.at_s)})
	var slot: Dictionary = {"slot_id": 1, "generation": generation, "from_s": start_s, "dash_until_s": slash_at_s, "end_s": end_s, "omitted_idle_s": 0.0, "route": route, "events": [event]}
	return {"warning_from_s": 0.0, "lock_from_s": authored.warning_s, "playback_from_s": start_s, "slots": [slot], "replay_until_s": end_s, "tether_from_s": end_s, "tether_until_s": tether_until_s, "source_ready_s": source_ready_s}


static func _vector_error(value: Variant) -> String:
	if not Codec.is_vector3(value):
		return "Finite encoded native Vector3 required"
	var point: Vector3 = Codec.read_vector3(value)
	if absf(point.x) > MAX_COORDINATE or absf(point.y) > MAX_COORDINATE or absf(point.z) > MAX_COORDINATE or not exact_equal(Codec.vector3(point), value):
		return "Canonical native Vector3 components within 512m required"
	return ""


static func _id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 192:
		return false
	var regex := RegEx.new()
	regex.compile("^[A-Za-z0-9_./:-]+$")
	var found: RegExMatch = regex.search(value)
	return found != null and found.get_string() == value


func _reject(reason: String) -> bool:
	last_error = reason
	return false
