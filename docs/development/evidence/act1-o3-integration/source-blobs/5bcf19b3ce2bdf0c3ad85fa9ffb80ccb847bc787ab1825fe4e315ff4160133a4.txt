extends RefCounted
## O3-owned authored placement/recipe data. No native safety or timing authority.
const LEVEL_ID: String = "A1-O3"
const WORLD_REVISION: int = 1
const FLOOR_SIZE: Vector3 = Vector3(14, 1, 16)
const FLOOR_CENTRE: Vector3 = Vector3(0, -0.5, 0)
const SAFE_RECT: Rect2 = Rect2(-6.5, -7.5, 13, 15)
const SPAWN: Vector3 = Vector3(0, 0.1, 0)
const BELL_POSITION: Vector3 = Vector3(-2.4, 0, 0)
const EXIT_POSITION: Vector3 = Vector3(0, 0, -4.6)
const BELL_BOX_SIZE: Vector3 = Vector3(1.1, 1.6, 1.1)
const EXIT_BOX_SIZE: Vector3 = Vector3(2.4, 1.6, 1.2)
const CONTACT_OFFSET: Vector3 = Vector3(0, 0.8, 0)
const CHECKPOINT_ID: String = "rehearsal-before-final"
const COMPLETION_ID: String = "royal-rehearsal-clear"
const EXIT_ID: String = "rehearsal-exit"
const EXERCISE_IDS: Array[String] = ["parallel", "inward", "staggered"]
const SOURCE_IDS: Array[String] = ["rehearsal-parallel-west", "rehearsal-parallel-east", "rehearsal-inward-west", "rehearsal-inward-east", "rehearsal-final-rear", "rehearsal-final-front"]
const EXERCISE_SOURCE_IDS: Array = [
	["rehearsal-parallel-west", "rehearsal-parallel-east"],
	["rehearsal-inward-west", "rehearsal-inward-east"],
	["rehearsal-final-rear", "rehearsal-final-front"],
]
const SOURCES: Dictionary = {
	"rehearsal-parallel-west": {"exercise": 0, "position": Vector3(-1.2, 0, -2), "target": Vector3(-1.2, 0, 0)},
	"rehearsal-parallel-east": {"exercise": 0, "position": Vector3(1.2, 0, -2), "target": Vector3(1.2, 0, 0)},
	"rehearsal-inward-west": {"exercise": 1, "position": Vector3(-1.6, 0, -2), "target": Vector3(0, 0, -0.4)},
	"rehearsal-inward-east": {"exercise": 1, "position": Vector3(1.6, 0, -2), "target": Vector3(0, 0, -0.4)},
	"rehearsal-final-rear": {"exercise": 2, "position": Vector3(-1.2, 0, -3.2), "target": Vector3(-1.2, 0, -1.2)},
	"rehearsal-final-front": {"exercise": 2, "position": Vector3(1.2, 0, -1.6), "target": Vector3(1.2, 0, 0.4)},
}
const FINAL_CHALLENGE_RECIPE: String = "rehearsal-staggered-challenge-rear-lock@v1"

static func group_ids(index: int) -> Array[String]:
	var result: Array[String] = []
	if index < 0 or index >= EXERCISE_SOURCE_IDS.size(): return result
	for id: String in EXERCISE_SOURCE_IDS[index]: result.append(id)
	return result

static func encounter_id(index: int) -> String:
	return "rehearsal-" + EXERCISE_IDS[index] if index >= 0 and index < EXERCISE_IDS.size() else ""

static func target_for(id: String, current_position: Vector3 = Vector3.INF) -> Vector3:
	if not SOURCES.has(id): return Vector3.INF
	var source: Vector3 = SOURCES[id].position if not current_position.is_finite() else current_position
	# Preserve fixed +Z parallels, and the familiar inward centre-line proposal
	# after genuine knockback. The native preview still chooses whether it fits.
	return Vector3(0, source.y, source.z + 1.6) if int(SOURCES[id].exercise) == 1 else source + Vector3(0, 0, 2)

static func recipe_id(index: int, profile: String) -> String:
	if index < 0 or index >= EXERCISE_IDS.size() or profile not in ["assisted", "standard", "challenge"]: return ""
	if index == 2 and profile == "challenge": return FINAL_CHALLENGE_RECIPE
	return "rehearsal-" + EXERCISE_IDS[index] + "-" + profile + ("-front-recovery@v1" if index == 2 else "-recovery@v1")

static func arrangement_definition(index: int) -> Dictionary:
	var ids: Array[String] = group_ids(index)
	if ids.size() != 2: return {}
	var rows: Array[Dictionary] = []
	var current: Dictionary = {}
	for profile: String in ["assisted", "standard", "challenge"]:
		var order: Array[String] = ids.duplicate()
		if index == 2 and profile != "challenge": order.reverse()
		var identity: String = recipe_id(index, profile)
		rows.append({"recipe_id": identity, "profile": profile, "order": order})
		current[profile] = identity
	return {"schema_version": 1, "unit_ids": ids, "recipes": rows, "current": current}

static func release_phase(index: int, descriptor: Dictionary, admitted_id: String) -> String:
	# Retained executable semantics dispatch on a versioned recipe identity.
	if index == 2 and descriptor.get("recipe_id") == FINAL_CHALLENGE_RECIPE and descriptor.get("order", []).size() == 2 and admitted_id == descriptor.order[0]: return "lock"
	return "recovery"
