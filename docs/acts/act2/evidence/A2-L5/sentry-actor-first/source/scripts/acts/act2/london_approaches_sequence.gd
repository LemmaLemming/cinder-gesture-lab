extends RefCounted
## Finite L4 earned order only. No player, HP, clocks, geometry or damage.
## All nine ordinary actors are required; each paired group permits either
## actual defeat order. Villa1 advances directly to Villa2 without contact.
const ACTORS: Dictionary = {
	"garden_handler": Vector3(0.65, 0.0, -2.5),
	"flood_scout": Vector3(-0.65, 0.0, -11.4),
	"flood_tender": Vector3(0.70, 0.0, -13.7),
	"villa_scout": Vector3(0.75, 0.0, -21.4),
	"villa_ray_handler": Vector3(-0.70, 0.0, -23.7),
	"villa_tender": Vector3(0.80, 0.0, -31.0),
	"villa_smoke_handler": Vector3(-0.65, 0.0, -33.4),
	"putney_scout": Vector3(-0.65, 0.0, -41.2),
	"putney_handler": Vector3(0.65, 0.0, -43.5),
}
const CLOUDS: Dictionary = {
	"flood_bank": Vector3(-1.10, 0.0, -12.9),
	"villa_bank": Vector3(-1.15, 0.0, -31.6),
}
const RAYS: Array[String] = ["flood_scout", "villa_scout", "putney_scout"]
const TENDERS: Array[String] = ["flood_tender", "villa_tender"]
const HANDLERS: Array[String] = ["garden_handler", "villa_ray_handler", "villa_smoke_handler", "putney_handler"]
const STAGES: Array[String] = ["changed_garden", "road_entry", "flood_margin", "villa_entry", "villa_scout_priority", "villa_tender_priority", "putney_entry", "putney_mix", "clear"]
const COMPLETION_ID: String = "london-road-open"
const CONTACT_EXIT_ID: String = "putney-road"
const EXIT_REGION: Rect2 = Rect2(-2.7, -49.2, 5.4, 1.3)
const CONTACTS: Dictionary = {
	"road_entry": {"region": Rect2(-2.8, -8.2, 5.6, 1.1), "checkpoint": "changed-garden-clear"},
	"villa_entry": {"region": Rect2(-2.8, -18.2, 5.6, 1.1), "checkpoint": "flood-margin-clear"},
	"putney_entry": {"region": Rect2(-2.8, -37.8, 5.6, 1.1), "checkpoint": "villa-courtyards-clear"},
}
const DEFEAT_STAGE: Dictionary = {"garden_handler": 0, "flood_scout": 2, "flood_tender": 2, "villa_scout": 4, "villa_ray_handler": 4, "villa_tender": 5, "villa_smoke_handler": 5, "putney_scout": 7, "putney_handler": 7}
const STAGE_ACTORS: Dictionary = {
	"changed_garden": ["garden_handler"],
	"flood_margin": ["flood_scout", "flood_tender"],
	"villa_scout_priority": ["villa_scout", "villa_ray_handler"],
	"villa_tender_priority": ["villa_tender", "villa_smoke_handler"],
	"putney_mix": ["putney_scout", "putney_handler"],
}
var stage_index: int = 0
var defeated_ids: Array[String] = []
var crossed_contacts: Array[String] = []
var last_snapshot_error: String = ""

func current_beat() -> String:
	return STAGES[stage_index]

func current_active_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(STAGE_ACTORS.get(current_beat(), []))
	for id: String in defeated_ids: ids.erase(id)
	return ids

func exit_is_open() -> bool:
	return current_beat() == "clear"

func commit_defeat(id: String) -> bool:
	if not current_active_ids().has(id): return false
	defeated_ids.append(id)
	if current_active_ids().is_empty(): stage_index += 1
	return true

func commit_contact(id: String) -> bool:
	if id != current_beat() or not CONTACTS.has(id) or crossed_contacts.has(id): return false
	crossed_contacts.append(id)
	stage_index += 1
	return true

func snapshot_state() -> Dictionary:
	return {"version": 1, "level_id": "A2-L4", "stage_index": stage_index, "defeated_ids": defeated_ids.duplicate(), "crossed_contacts": crossed_contacts.duplicate(), "active_ids": current_active_ids(), "exit_open": exit_is_open()}

func snapshot_error(state: Dictionary) -> String:
	if state.size() != 7 or not state.has_all(["version", "level_id", "stage_index", "defeated_ids", "crossed_contacts", "active_ids", "exit_open"]) or not state.version is int or state.version != 1 or state.level_id != "A2-L4" or not state.stage_index is int or state.stage_index < 0 or state.stage_index >= STAGES.size():
		return "Invalid London-approaches finite sequence envelope"
	for key: String in ["defeated_ids", "crossed_contacts", "active_ids"]:
		if not state[key] is Array: return "London-approaches sequence needs closed arrays"
	var seen: Dictionary = {}
	var last_group: int = -1
	for id: Variant in state.defeated_ids:
		if not id is String or not DEFEAT_STAGE.has(id) or seen.has(id) or DEFEAT_STAGE[id] > state.stage_index or DEFEAT_STAGE[id] < last_group:
			return "Invalid, duplicate, future or out-of-order London-approaches defeat"
		seen[id] = true
		last_group = DEFEAT_STAGE[id]
	for id: String in ACTORS:
		if int(DEFEAT_STAGE[id]) < state.stage_index and not seen.has(id): return "Missing earned London-approaches defeat prefix"
	var group: Array = STAGE_ACTORS.get(STAGES[state.stage_index], [])
	if not group.is_empty():
		var complete: bool = true
		for id: String in group:
			if not seen.has(id): complete = false
		if complete: return "Completed London-approaches conjunction must advance atomically"
	var contacts: Array[String] = []
	for boundary: int in [1, 3, 6]:
		if state.stage_index > boundary: contacts.append(STAGES[boundary])
	if state.crossed_contacts != contacts: return "London-approaches contacts differ from the earned prefix"
	var probe = get_script().new()
	probe.stage_index = state.stage_index
	probe.defeated_ids.assign(state.defeated_ids)
	probe.crossed_contacts.assign(state.crossed_contacts)
	if not state.exit_open is bool or state.exit_open != probe.exit_is_open() or state.active_ids != probe.current_active_ids():
		return "Derived London-approaches cast/exit differs"
	return ""

func restore_state(state: Dictionary) -> bool:
	last_snapshot_error = snapshot_error(state)
	if not last_snapshot_error.is_empty(): return false
	stage_index = state.stage_index
	defeated_ids.assign(state.defeated_ids)
	crossed_contacts.assign(state.crossed_contacts)
	return true
