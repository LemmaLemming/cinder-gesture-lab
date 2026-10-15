extends RefCounted
## A1-O2 authored membership/data only, from data/campaign/act1/levels/A1-O2.md.
## The host extends the accepted Mushroom Caverns Base and retains its exact
## 14x72 floor/five-stalk world. This module builds no duplicate geometry and
## creates no actors, fields, cues, Scheduler, clock or progression entitlement.
## Positions remain hypotheses until actual native body/route/portrait checks.

const LEVEL_ID: String = "A1-O2"
const BEAT_IDS: Array[String] = ["first-breathing", "paired-mushrooms", "final-mixed"]
const GROUP_IDS: Array[String] = ["first-breathing", "paired-mushrooms", "final-mixed"]
const EPOCH_IDS: Array[String] = ["a1_o2_first", "a1_o2_paired", "a1_o2_final"]
const CONSUMER_IDS: Array[String] = ["bloom-first-spores", "bloom-paired-spores", "bloom-final-spores"]
const CONTROLLER_ID: String = "spore-bloom-scheduler"
const PLAYER_ID: String = "hero"
const CHECKPOINT_ID: String = "spore-bloom-ready"
const COMPLETION_ID: String = "spore-bloom-clear"
const EXIT_ID: String = "bloom-exit"
const SPAWN: Vector3 = Vector3(0, 0.1, 5)
const EXIT: Vector3 = Vector3(0, 0.65, 3.8)
const FIRST_APPROACH_Z: float = 2.0

const SOURCE_IDS: Array[String] = [
	"bloom-first-west", "bloom-first-east",
	"bloom-pair-west", "bloom-pair-east", "bloom-pair-rear",
	"bloom-final-west", "bloom-final-east", "bloom-final-rear", "bloom-final-guard",
]
const GROUP_SOURCES: Array = [
	["bloom-first-west", "bloom-first-east"],
	["bloom-pair-west", "bloom-pair-east", "bloom-pair-rear"],
	["bloom-final-west", "bloom-final-east", "bloom-final-rear", "bloom-final-guard"],
]
const SOURCE_POINTS: Dictionary = {
	"bloom-first-west": Vector3(-2, 0.005, 0.2),
	"bloom-first-east": Vector3(2, 0.005, 0.2),
	"bloom-pair-west": Vector3(-2.4, 0.005, -1.8),
	"bloom-pair-east": Vector3(2.4, 0.005, -1.8),
	"bloom-pair-rear": Vector3(0, 0.005, -3.8),
	"bloom-final-west": Vector3(-2.2, 0.005, -0.7),
	"bloom-final-east": Vector3(2.2, 0.005, -0.7),
	"bloom-final-rear": Vector3(0, 0.005, -3.6),
	"bloom-final-guard": Vector3(0, 0.005, -1.8),
}
const FIELD_IDS: Array[String] = ["bloom-near", "bloom-far"]
const GROUP_FIELDS: Array = [["bloom-near"], ["bloom-near", "bloom-far"], ["bloom-near", "bloom-far"]]
const FIELD_POINTS: Dictionary = {"bloom-near": Vector3(-0.4, 0, 1.4), "bloom-far": Vector3(0.4, 0, -1.4)}
const FIELD_RADIUS: float = 1.5
const FIELD_DURATION_S: float = 3.0
const FIELD_THINNING_S: float = 0.5
const CLUSTER_IDS: Array[String] = ["cluster-left", "cluster-right"]
const CLUSTER_OFFSETS: Array[Vector3] = [Vector3(-0.35, 0.8, -0.25), Vector3(0.35, 0.8, 0.25)]
const DEFINITION_KEYS: Array[String] = ["level_id", "beat_ids", "group_ids", "epoch_ids", "consumer_ids", "controller_id", "player_id", "checkpoint_id", "completion_id", "exit_id", "spawn", "exit", "first_approach_z", "source_ids", "group_sources", "sources", "field_ids", "group_fields", "fields", "repulsion_directions"]


static func all_source_ids() -> Array[String]:
	return SOURCE_IDS.duplicate()


static func group_id(index: int) -> String:
	return GROUP_IDS[index] if index >= 0 and index < GROUP_IDS.size() else ""


static func group_ids(index: int) -> Array[String]:
	var result: Array[String] = []
	if index >= 0 and index < GROUP_SOURCES.size(): result.assign(GROUP_SOURCES[index])
	return result


static func group_field_ids(index: int) -> Array[String]:
	var result: Array[String] = []
	if index >= 0 and index < GROUP_FIELDS.size(): result.assign(GROUP_FIELDS[index])
	return result


static func source_group(id: String) -> int:
	for index: int in range(GROUP_SOURCES.size()):
		if id in GROUP_SOURCES[index]: return index
	return -1


static func source_spec(id: String, approach_enabled: bool = false) -> Dictionary:
	if not SOURCE_POINTS.has(id): return {}
	var swarm: bool = id != "bloom-final-guard"
	# Base._ready consumes these exact keys. The O2 host explicitly enables
	# familiar C31 approach; the grounded C32 guard remains stationary.
	return {"role_id": "C31" if swarm else "C32", "position": SOURCE_POINTS[id], "approach": approach_enabled and swarm}


static func field_spec(id: String) -> Dictionary:
	if not FIELD_POINTS.has(id): return {}
	var clusters: Array[Dictionary] = []
	for index: int in range(CLUSTER_IDS.size()):
		clusters.append({"id": CLUSTER_IDS[index], "offset": CLUSTER_OFFSETS[index]})
	return {"id": id, "position": FIELD_POINTS[id], "clusters": clusters, "parameters": {"radius": FIELD_RADIUS, "duration_s": FIELD_DURATION_S, "thinning_s": FIELD_THINNING_S}}


static func epoch_id(index: int) -> String:
	return EPOCH_IDS[index] if index >= 0 and index < EPOCH_IDS.size() else ""


static func consumer_id(index: int) -> String:
	return CONSUMER_IDS[index] if index >= 0 and index < CONSUMER_IDS.size() else ""


static func repulsion_directions() -> Array[Vector3]:
	# Exact original accepted L3 native direction order, not a new solver.
	var result: Array[Vector3] = [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]: result.append(Vector3(x, 0, z).normalized())
	return result


static func definition() -> Dictionary:
	var actors: Dictionary = {}
	for id: String in SOURCE_IDS: actors[id] = source_spec(id, true)
	var fields: Dictionary = {}
	for id: String in FIELD_IDS: fields[id] = field_spec(id)
	return {"level_id": LEVEL_ID, "beat_ids": BEAT_IDS.duplicate(), "group_ids": GROUP_IDS.duplicate(), "epoch_ids": EPOCH_IDS.duplicate(), "consumer_ids": CONSUMER_IDS.duplicate(), "controller_id": CONTROLLER_ID, "player_id": PLAYER_ID, "checkpoint_id": CHECKPOINT_ID, "completion_id": COMPLETION_ID, "exit_id": EXIT_ID, "spawn": SPAWN, "exit": EXIT, "first_approach_z": FIRST_APPROACH_Z, "source_ids": SOURCE_IDS.duplicate(), "group_sources": GROUP_SOURCES.duplicate(true), "sources": actors, "field_ids": FIELD_IDS.duplicate(), "group_fields": GROUP_FIELDS.duplicate(true), "fields": fields, "repulsion_directions": repulsion_directions()}


## Closed authored data only. This checks no physical support, placement,
## current camera, source/field admission, runtime clock or native save packet.
static func definition_error(supplied: Variant = null) -> String:
	var value: Variant = definition() if supplied == null else supplied
	if not value is Dictionary or not _closed(value, DEFINITION_KEYS): return "Closed complete O2 authored definition required"
	var expected: Dictionary = definition()
	for key: String in ["level_id", "controller_id", "player_id", "checkpoint_id", "completion_id", "exit_id"]:
		if not value[key] is String or value[key] != expected[key]: return "Original O2 stable identity required: " + key
	for key: String in ["beat_ids", "group_ids", "epoch_ids", "consumer_ids", "source_ids", "field_ids"]:
		if not _string_array_equal(value[key], expected[key]): return "Original ordered O2 identity list required: " + key
	for key: String in ["group_sources", "group_fields"]:
		if not value[key] is Array or value[key].size() != GROUP_IDS.size(): return "Exactly three disjoint O2 group definitions required"
		for index: int in range(GROUP_IDS.size()):
			if not _string_array_equal(value[key][index], expected[key][index]): return "Original O2 source membership/shared field union required: " + key
	for key: String in ["spawn", "exit"]:
		if not value[key] is Vector3 or not value[key].is_finite() or value[key] != expected[key]: return "Original finite O2 authored vector required: " + key
	if not value.first_approach_z is float or not is_finite(value.first_approach_z) or value.first_approach_z != FIRST_APPROACH_Z: return "Original first approach threshold required"
	if not value.sources is Dictionary or not _closed(value.sources, SOURCE_IDS): return "All nine original O2 source definitions required"
	for id: String in SOURCE_IDS:
		var actor: Variant = value.sources[id]
		var authored: Dictionary = source_spec(id, true)
		if not actor is Dictionary or not _closed(actor, ["role_id", "position", "approach"]): return "Closed Base-compatible O2 source specification required: " + id
		if not actor.role_id is String or actor.role_id != authored.role_id or not actor.approach is bool or actor.approach != authored.approach or not actor.position is Vector3 or not actor.position.is_finite() or actor.position != authored.position: return "Original O2 role/approach/position required: " + id
	if not value.fields is Dictionary or not _closed(value.fields, FIELD_IDS): return "Both original finite O2 field assemblies required"
	for id: String in FIELD_IDS:
		var field: Variant = value.fields[id]
		var authored: Dictionary = field_spec(id)
		if not field is Dictionary or not _closed(field, ["id", "position", "clusters", "parameters"]): return "Closed original native Field configuration inputs required: " + id
		if not field.id is String or field.id != id or not field.position is Vector3 or not field.position.is_finite() or field.position != authored.position: return "Original O2 field identity/origin required: " + id
		if not field.parameters is Dictionary or not _closed(field.parameters, ["radius", "duration_s", "thinning_s"]): return "Original native Field parameters required: " + id
		for key: String in ["radius", "duration_s", "thinning_s"]:
			if not field.parameters[key] is float or not is_finite(field.parameters[key]) or field.parameters[key] != authored.parameters[key]: return "Retain original native Field parameter: " + key
		if not field.clusters is Array or field.clusters.size() != CLUSTER_IDS.size(): return "Both real original native cluster anchors required"
		for index: int in range(CLUSTER_IDS.size()):
			var cluster: Variant = field.clusters[index]
			if not cluster is Dictionary or not _closed(cluster, ["id", "offset"]): return "Closed original native cluster input required"
			if not cluster.id is String or cluster.id != CLUSTER_IDS[index] or not cluster.offset is Vector3 or not cluster.offset.is_finite() or cluster.offset != CLUSTER_OFFSETS[index]: return "Original native cluster identity/offset required"
	if not value.repulsion_directions is Array or value.repulsion_directions.size() != 8: return "Original eight native repulsion directions required"
	var directions: Array[Vector3] = repulsion_directions()
	for index: int in range(directions.size()):
		if not value.repulsion_directions[index] is Vector3 or not value.repulsion_directions[index].is_finite() or value.repulsion_directions[index] != directions[index]: return "Original ordered native repulsion direction required"
	return ""


static func _string_array_equal(value: Variant, expected: Array) -> bool:
	if not value is Array or value.size() != expected.size(): return false
	for index: int in range(expected.size()):
		if not value[index] is String or value[index] != expected[index]: return false
	return true


static func _closed(value: Dictionary, keys: Array) -> bool:
	if value.size() != keys.size(): return false
	for key: Variant in value:
		if not key is String or key not in keys: return false
	return true
