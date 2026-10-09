class_name CinderCampaignRegistry
extends RefCounted
## Authored routes and accepted scene identity; no catalogue proposal becomes
## playable merely because it has a node on Journey.

const DATA_PATH: String = "res://data/campaign/registry.json"
const API_REVISION: String = "campaign-level-1"
const PARENTS: Dictionary = {
	"A1-O1": "A1-L2", "A1-O2": "A1-L3", "A1-O3": "A1-L4",
	"A2-O1": "A2-L1", "A2-O2": "A2-L3", "A2-O3": "A2-L4",
	"A3-O1": "A3-L1", "A3-O2": "A3-L2", "A3-O3": "A3-L3",
}
var last_error: String = ""
var _levels: Dictionary = {}
var _route: Array[String] = []

func _init(raw: Dictionary = {}) -> void:
	if raw.is_empty():
		var file: FileAccess = FileAccess.open(DATA_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary:
				raw = parsed
	configure(raw)

func configure(raw: Dictionary) -> bool:
	last_error = validation_error(raw)
	if not last_error.is_empty():
		return false
	var levels: Dictionary = {}
	var route: Array[String] = []
	for entry: Dictionary in raw["levels"]:
		levels[entry["id"]] = entry.duplicate(true)
	for id: String in raw["main_route"]:
		route.append(id)
	_levels = levels
	_route = route
	return true

func validation_error(raw: Dictionary) -> String:
	if raw.get("schema_version") != 1 or raw.get("first_main_level_id") != "A1-L1" or not raw.get("main_route") is Array or not raw.get("levels") is Array:
		return "Unsupported campaign registry"
	var expected: Array[String] = []
	for act: int in range(1, 4):
		for number: int in range(1, 6):
			expected.append("A%d-L%d" % [act, number])
	if raw["main_route"] != expected or raw["levels"].size() != 24:
		return "Campaign requires the canonical 15-main/9-optional route"
	var seen: Dictionary = {}
	var rewards: Dictionary = {}
	for value: Variant in raw["levels"]:
		if not value is Dictionary:
			return "Level entry must be an object"
		var entry: Dictionary = value
		var id: Variant = entry.get("id")
		if not id is String or (not expected.has(id) and not PARENTS.has(id)) or seen.has(id):
			return "Noncanonical or duplicate level identity"
		seen[id] = true
		if entry.get("act") != int(id.substr(1, 1)) or not entry.get("name") is String or entry["name"].is_empty():
			return "Level metadata does not match identity"
		if expected.has(id):
			var index: int = expected.find(id)
			var previous: Variant = null if index == 0 else expected[index - 1]
			var next: Variant = null if index == 14 else expected[index + 1]
			if entry.get("kind") != "main" or entry.get("parent_level_id") != null or entry.get("previous_main_id") != previous or entry.get("next_main_id") != next:
				return "Main route links differ from canonical sequence"
		else:
			var reward: Variant = entry.get("reward_id")
			if entry.get("kind") != "optional" or entry.get("parent_level_id") != PARENTS[id] or not reward is String or reward != id + "-completion-stamp" or rewards.has(reward):
				return "Optional parent/reward identity differs or duplicates"
			if entry.get("reward_policy") != "once_only_completion_stamp_no_stat_growth":
				return "Unsupported optional reward policy"
			rewards[reward] = true
		if entry.get("readiness") == "unimplemented":
			if entry.get("scene_path") != null or entry.get("accepted_commit") != null or entry.get("api_revision") != null:
				return "Unimplemented entries cannot claim accepted scenes"
		elif entry.get("readiness") == "accepted":
			if not entry.get("scene_path") is String or not entry["scene_path"].begins_with("res://") or not entry["scene_path"].ends_with(".tscn") or entry.get("api_revision") != API_REVISION:
				return "Accepted scene requires project path and supported API"
			var commit: Variant = entry.get("accepted_commit")
			if not commit is String or commit.length() != 40 or not commit.is_valid_hex_number(false):
				return "Accepted scene requires exact commit provenance"
		else:
			return "Unknown scene readiness"
	return ""

func ids() -> Array[String]:
	var result: Array[String] = _route.duplicate()
	for id: String in PARENTS:
		result.append(id)
	return result

func main_route() -> Array[String]:
	return _route.duplicate()

func entry(id: String) -> Dictionary:
	return (_levels.get(id, {}) as Dictionary).duplicate(true)

func scene_error(id: String) -> String:
	var info: Dictionary = entry(id)
	if info.is_empty() or info.get("readiness") != "accepted":
		return "Level is awaiting integration"
	var path: String = info["scene_path"]
	if not ResourceLoader.exists(path, "PackedScene"):
		return "Accepted scene is missing"
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return "Accepted scene cannot load"
	var candidate: Node = packed.instantiate()
	var error: String = ""
	if not candidate is CinderLevel:
		error = "Accepted scene requires the shared level root"
	elif candidate.level_id != id:
		error = "Accepted scene identity differs from registry"
	else:
		error = candidate.contract_error()
	candidate.free()
	return error

func is_playable(id: String) -> bool:
	return scene_error(id).is_empty()

func is_unlocked(id: String, completed_main: Array) -> bool:
	var info: Dictionary = entry(id)
	if info.is_empty():
		return false
	var parent: Variant = info["previous_main_id"] if info["kind"] == "main" else info["parent_level_id"]
	return parent == null or completed_main.has(parent)

func next_main(id: String) -> String:
	var info: Dictionary = entry(id)
	return String(info.get("next_main_id", "")) if info.get("next_main_id") != null else ""

func node_state(id: String, completed_main: Array, completed_optional: Array, story_id: String) -> String:
	var info: Dictionary = entry(id)
	if info.is_empty():
		return "unknown"
	if not is_unlocked(id, completed_main):
		return "locked"
	if not is_playable(id):
		return "unimplemented"
	if completed_main.has(id) or completed_optional.has(id):
		return "completed"
	if id == story_id and info["kind"] == "main":
		return "current"
	return "available"
