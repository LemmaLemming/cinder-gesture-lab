extends RefCounted
## Finite L3 earned order only. No player, HP, clock, geometry or damage.
const ACTORS: Dictionary = {
	"road_tender": Vector3(0.40, 0.0, -2.5),
	"house_tender": Vector3(0.85, 0.0, -12.2),
	"house_handler": Vector3(-0.80, 0.0, -15.5),
	"apron_scout": Vector3(-0.65, 0.0, -23.1),
	"apron_handler": Vector3(0.65, 0.0, -25.4),
	"handling_machine": Vector3(0.0, 0.0, -35.0),
	"side_tender": Vector3(1.60, 0.0, -34.9),
}
const CLOUDS: Dictionary = {
	"road_bank": Vector3(-0.9, 0.0, -3.5),
	"house_bank": Vector3(-1.10, 0.0, -10.9),
	"boss_bank": Vector3(-1.30, 0.0, -33.9),
}
const TENDERS: Array[String] = ["road_tender", "house_tender", "side_tender"]
const HANDLERS: Array[String] = ["house_handler", "apron_handler"]
const STAGES: Array[String] = ["smoke_edge", "clear_ground", "ruined_house", "wall_opening", "work_apron", "boss_entry", "boss_phase_one", "boss_phase_two", "clear"]
const CONTACTS: Dictionary = {
	"clear_ground": {"region": Rect2(-2.8, -8.2, 5.6, 1.1), "checkpoint": "smoke-edge-clear"},
	"wall_opening": {"region": Rect2(-2.8, -18.4, 5.6, 1.1), "checkpoint": "ruined-house-opening"},
	"boss_entry": {"region": Rect2(-2.8, -29.3, 5.6, 1.1), "checkpoint": "work-apron-open"},
}
const DEFEAT_STAGE: Dictionary = {"road_tender": 0, "house_tender": 2, "house_handler": 2, "apron_scout": 4, "apron_handler": 4, "handling_machine": 7, "side_tender": 7}
var stage_index: int = 0
var defeated_ids: Array[String] = []
var crossed_contacts: Array[String] = []
var last_snapshot_error: String = ""

func current_beat() -> String:
	return STAGES[stage_index]

func current_active_ids() -> Array[String]:
	var ids: Array[String] = []
	match current_beat():
		"smoke_edge": ids = ["road_tender"]
		"ruined_house": ids = ["house_tender", "house_handler"]
		"work_apron": ids = ["apron_scout", "apron_handler"]
		"boss_phase_one": ids = ["handling_machine"]
		"boss_phase_two": ids = ["handling_machine", "side_tender"]
	for id: String in defeated_ids: ids.erase(id)
	return ids

func current_boss_phase() -> int:
	return 0 if stage_index < 6 else (1 if stage_index == 6 else 2)

func exit_is_open() -> bool:
	return current_beat() == "clear"

func commit_defeat(id: String) -> bool:
	if not current_active_ids().has(id) or id == "handling_machine" and stage_index != 7:
		return false
	defeated_ids.append(id)
	match current_beat():
		"smoke_edge": stage_index += 1
		"ruined_house":
			if defeated_ids.has("house_tender") and defeated_ids.has("house_handler"): stage_index += 1
		"work_apron":
			if defeated_ids.has("apron_scout") and defeated_ids.has("apron_handler"): stage_index += 1
		"boss_phase_two":
			if id == "handling_machine": stage_index += 1
	return true

func commit_contact(id: String) -> bool:
	if id != current_beat() or not CONTACTS.has(id) or crossed_contacts.has(id): return false
	crossed_contacts.append(id)
	stage_index += 1
	return true

func commit_boss_phase_two() -> bool:
	# Caller must validate the real B02 actor's earned HP threshold/transaction.
	if current_beat() != "boss_phase_one": return false
	stage_index += 1
	return true

func snapshot_state() -> Dictionary:
	return {"version": 1, "level_id": "A2-L3", "stage_index": stage_index, "defeated_ids": defeated_ids.duplicate(), "crossed_contacts": crossed_contacts.duplicate(), "active_ids": current_active_ids(), "boss_phase": current_boss_phase(), "exit_open": exit_is_open()}

func snapshot_error(state: Dictionary) -> String:
	if state.size() != 8 or not state.has_all(["version", "level_id", "stage_index", "defeated_ids", "crossed_contacts", "active_ids", "boss_phase", "exit_open"]) or not state.version is int or state.version != 1 or state.level_id != "A2-L3" or not state.stage_index is int or state.stage_index < 0 or state.stage_index >= STAGES.size():
		return "Invalid ruined-house finite sequence envelope"
	for key: String in ["defeated_ids", "crossed_contacts", "active_ids"]:
		if not state[key] is Array: return "Ruined-house sequence needs closed arrays"
	var seen: Dictionary = {}
	var last_group: int = -1
	for id: Variant in state.defeated_ids:
		if not id is String or not DEFEAT_STAGE.has(id) or seen.has(id) or DEFEAT_STAGE[id] > state.stage_index or DEFEAT_STAGE[id] < last_group:
			return "Invalid, duplicate, future or out-of-order ruined-house defeat"
		seen[id] = true
		last_group = DEFEAT_STAGE[id]
	var required: Array[String] = []
	if state.stage_index > 0: required.append("road_tender")
	if state.stage_index > 2: required.append_array(["house_tender", "house_handler"])
	if state.stage_index > 4: required.append_array(["apron_scout", "apron_handler"])
	if state.stage_index > 7: required.append("handling_machine")
	for id: String in required:
		if not seen.has(id): return "Missing earned ruined-house defeat prefix"
	if state.stage_index == 0 and seen.has("road_tender") or state.stage_index == 2 and seen.has("house_tender") and seen.has("house_handler") or state.stage_index == 4 and seen.has("apron_scout") and seen.has("apron_handler") or state.stage_index == 7 and seen.has("handling_machine"):
		return "Completed ruined-house conjunction must advance atomically"
	if state.stage_index == 8 and (state.defeated_ids.is_empty() or state.defeated_ids[-1] != "handling_machine"):
		return "Local arm disengagement must be the final required defeat"
	var contacts: Array[String] = []
	for boundary: int in [1, 3, 5]:
		if state.stage_index > boundary: contacts.append(STAGES[boundary])
	if state.crossed_contacts != contacts: return "Ruined-house contacts differ from the earned prefix"
	var probe = get_script().new()
	probe.stage_index = state.stage_index
	probe.defeated_ids.assign(state.defeated_ids)
	probe.crossed_contacts.assign(state.crossed_contacts)
	if not state.boss_phase is int or not state.exit_open is bool or state.boss_phase != probe.current_boss_phase() or state.exit_open != probe.exit_is_open() or state.active_ids != probe.current_active_ids():
		return "Derived ruined-house cast/phase/exit differs"
	return ""

func restore_state(state: Dictionary) -> bool:
	last_snapshot_error = snapshot_error(state)
	if not last_snapshot_error.is_empty(): return false
	stage_index = state.stage_index
	defeated_ids.assign(state.defeated_ids)
	crossed_contacts.assign(state.crossed_contacts)
	return true
