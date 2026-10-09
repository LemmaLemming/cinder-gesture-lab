extends RefCounted
## L2's finite earned order; no player, clock, attack, reward or callback.
const ACTORS: Dictionary = {
	"village_scout": Vector3(0, 0, -0.5),
	"yard_handler": Vector3(0.5, 0, -5.7),
	"apron_handler": Vector3(-0.45, 0, -15.2),
	"crossing_scout": Vector3(0.45, 0, -23.5),
	"shelter_scout": Vector3(-0.6, 0, -33.0),
	"shelter_handler": Vector3(0.65, 0, -35.2),
}
const HANDLERS: Array[String] = ["yard_handler", "apron_handler", "shelter_handler"]
const FEET: Dictionary = {
	"foot_demo": Vector3(-0.25, 0, -10.5),
	"foot_apron": Vector3(0.30, 0, -13.2),
	"foot_left": Vector3(-0.75, 0, -21.0),
	"foot_right": Vector3(0.75, 0, -24.6),
}
const STAGES: Array[String] = ["village", "yard", "yard_exit", "foot_demo", "apron_pair", "before_crossing", "crossing_left", "crossing_right", "far_apron", "before_shelter", "shelter_pair", "clear"]
const CONTACTS: Dictionary = {
	"yard_exit": {"region": Rect2(-2.8, -8.2, 5.6, 1.1), "checkpoint": "weybridge-yard-exit"},
	"before_crossing": {"region": Rect2(-2.8, -18.0, 5.6, 1.1), "checkpoint": "weybridge-before-crossing"},
	"far_apron": {"region": Rect2(-2.8, -29.3, 5.6, 1.1), "checkpoint": "weybridge-far-apron"},
	"before_shelter": {"region": Rect2(-2.8, -31.2, 5.6, 1.1), "checkpoint": "weybridge-before-shelter"},
}
var stage_index: int = 0
var defeated_ids: Array[String] = []
var completed_feet: Array[String] = []
var crossed_contacts: Array[String] = []
var last_snapshot_error: String = ""

func current_beat() -> String:
	return STAGES[stage_index]

func current_active_ids() -> Array[String]:
	var ids: Array[String] = []
	match current_beat():
		"village": ids = ["village_scout"]
		"yard": ids = ["yard_handler"]
		"apron_pair": ids = ["apron_handler"]
		"crossing_left", "crossing_right": ids = ["crossing_scout"]
		"shelter_pair": ids = ["shelter_scout", "shelter_handler"]
	for id: String in defeated_ids:
		ids.erase(id)
	return ids

func current_foot_id() -> String:
	match current_beat():
		"foot_demo": return "foot_demo"
		"apron_pair": return "" if completed_feet.has("foot_apron") else "foot_apron"
		"crossing_left": return "foot_left"
		"crossing_right": return "" if completed_feet.has("foot_right") else "foot_right"
	return ""

func exit_is_open() -> bool:
	return current_beat() == "clear"

func commit_defeat(id: String) -> bool:
	if not current_active_ids().has(id):
		return false
	defeated_ids.append(id)
	_advance_if_earned()
	return true

func commit_foot(id: String) -> bool:
	if id.is_empty() or current_foot_id() != id or completed_feet.has(id):
		return false
	completed_feet.append(id)
	_advance_if_earned()
	return true

func commit_contact(id: String) -> bool:
	if current_beat() != id or not CONTACTS.has(id) or crossed_contacts.has(id):
		return false
	crossed_contacts.append(id)
	stage_index += 1
	return true

func _advance_if_earned() -> void:
	match current_beat():
		"village", "yard": stage_index += 1
		"foot_demo": stage_index += 1
		"apron_pair":
			if defeated_ids.has("apron_handler") and completed_feet.has("foot_apron"):
				stage_index += 1
		"crossing_left":
			if completed_feet.has("foot_left"):
				stage_index += 1
		"crossing_right":
			if completed_feet.has("foot_right") and defeated_ids.has("crossing_scout"):
				stage_index += 1
		"shelter_pair":
			if defeated_ids.has("shelter_scout") and defeated_ids.has("shelter_handler"):
				stage_index += 1

func snapshot_state() -> Dictionary:
	return {"version": 1, "level_id": "A2-L2", "stage_index": stage_index, "defeated_ids": defeated_ids.duplicate(), "completed_feet": completed_feet.duplicate(), "crossed_contacts": crossed_contacts.duplicate(), "active_ids": current_active_ids(), "foot_id": current_foot_id()}

func snapshot_error(state: Dictionary) -> String:
	if state.size() != 8 or not state.has_all(["version", "level_id", "stage_index", "defeated_ids", "completed_feet", "crossed_contacts", "active_ids", "foot_id"]) or state.version != 1 or state.level_id != "A2-L2" or not state.stage_index is int or state.stage_index < 0 or state.stage_index >= STAGES.size():
		return "Invalid Weybridge finite sequence envelope"
	for key: String in ["defeated_ids", "completed_feet", "crossed_contacts", "active_ids"]:
		if not state[key] is Array:
			return "Weybridge sequence needs closed arrays"
	var seen: Dictionary = {}
	for id: Variant in state.defeated_ids:
		if not id is String or not ACTORS.has(id) or seen.has(id):
			return "Invalid Weybridge defeated actor"
		seen[id] = true
	var index: int = state.stage_index
	var required: Array[String] = []
	if index > 0: required.append("village_scout")
	if index > 1: required.append("yard_handler")
	if index > 4: required.append("apron_handler")
	if index > 7: required.append("crossing_scout")
	var allowed: Array[String] = required.duplicate()
	if index == 4: allowed.append("apron_handler")
	if index in [6, 7]: allowed.append("crossing_scout")
	if index >= 10: allowed.append_array(["shelter_scout", "shelter_handler"])
	for id: String in required:
		if not state.defeated_ids.has(id): return "Missing earned Weybridge defeat prefix"
	for id: String in state.defeated_ids:
		if not allowed.has(id): return "Future Weybridge actor defeated"
	if state.defeated_ids.slice(0, required.size()) != required:
		return "Weybridge ordered defeat prefix differs"
	if index == 11 and state.defeated_ids.size() != ACTORS.size():
		return "Weybridge clear requires exactly six authored defeats"
	var feet: Array[String] = []
	if index > 3: feet.append("foot_demo")
	if index > 4: feet.append("foot_apron")
	if index > 6: feet.append("foot_left")
	if index > 7: feet.append("foot_right")
	if index == 4 and state.completed_feet.has("foot_apron"): feet.append("foot_apron")
	if index == 7 and state.completed_feet.has("foot_right"): feet.append("foot_right")
	if state.completed_feet != feet:
		return "Weybridge foot cycles differ from their earned prefix"
	if (index == 4 and state.defeated_ids.has("apron_handler") and state.completed_feet.has("foot_apron")) or (index == 7 and state.defeated_ids.has("crossing_scout") and state.completed_feet.has("foot_right")) or (index == 10 and state.defeated_ids.has("shelter_scout") and state.defeated_ids.has("shelter_handler")):
		return "Already earned Weybridge conjunction must advance atomically"
	var contacts: Array[String] = []
	for boundary: int in [2, 5, 8, 9]:
		if index > boundary: contacts.append(STAGES[boundary])
	if state.crossed_contacts != contacts:
		return "Weybridge contacts differ from actual sequential boundaries"
	var probe = get_script().new()
	probe.stage_index = index
	probe.defeated_ids.assign(state.defeated_ids)
	probe.completed_feet.assign(state.completed_feet)
	probe.crossed_contacts.assign(state.crossed_contacts)
	if state.active_ids != probe.current_active_ids() or state.foot_id != probe.current_foot_id():
		return "Weybridge derived active cast differs"
	return ""

func restore_state(state: Dictionary) -> bool:
	last_snapshot_error = snapshot_error(state)
	if not last_snapshot_error.is_empty(): return false
	stage_index = state.stage_index
	defeated_ids.assign(state.defeated_ids)
	completed_feet.assign(state.completed_feet)
	crossed_contacts.assign(state.crossed_contacts)
	return true
