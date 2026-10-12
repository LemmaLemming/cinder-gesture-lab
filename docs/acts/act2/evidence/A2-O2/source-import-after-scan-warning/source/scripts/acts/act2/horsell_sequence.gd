class_name Act2HorsellSequence
extends RefCounted
## Authored A2-L1 sequence only. No actor, threat, player, clock or reward logic.
## Actor IDs are the level's SCOUT_POSITIONS keys; level_id scopes saved IDs.
## alive_ids means the current encounter's live logical participants, not the
## dormant/unselected cast. Actual admission, contacts and scenery clocks belong
## to the root. In particular its before-departure contact checkpoint is external.

const LEVEL_ID: String = "A2-L1"
const SNAPSHOT_VERSION: int = 1
const ACTOR_POSITIONS: Dictionary = {
	"arrival": Vector3(0.0, 0.0, -0.4),
	"road_east": Vector3(1.0, 0.0, -5.4),
	"road_west": Vector3(-1.0, 0.0, -9.0),
	"common_left": Vector3(-0.9, 0.0, -14.5),
	"common_right": Vector3(0.9, 0.0, -14.5),
	"departure_a": Vector3(-0.65, 0.0, -23.1),
	"departure_b": Vector3(0.65, 0.0, -25.5),
}
const BEATS: Array[String] = ["arrival", "road_east", "road_west", "fork", "common", "departure", "clear"]
const PREFIX: Array[String] = ["arrival", "road_east", "road_west"]
const DEPARTURE_IDS: Array[String] = ["departure_a", "departure_b"]

var last_snapshot_error: String = ""
var _beat: String = "arrival"
var _route: String = ""
var _defeated: Array[String] = []


func current_beat() -> String:
	return _beat


func current_active_ids() -> Array[String]:
	return _active_ids(_beat, _route, _defeated)


func selected_route() -> String:
	return _route


func exit_is_open() -> bool:
	return _beat == "clear"


func actor_positions() -> Dictionary:
	return ACTOR_POSITIONS.duplicate(true)


func choose_route(route: String) -> Dictionary:
	if _beat != "fork" or not _route.is_empty():
		return _result(false, "route_choice_unavailable")
	if route not in ["left", "right"]:
		return _result(false, "invalid_route")
	_route = route
	_beat = "common"
	return _result(true)


func commit_defeat(actor_id: String) -> Dictionary:
	if not ACTOR_POSITIONS.has(actor_id):
		return _result(false, "unknown_actor")
	if _defeated.has(actor_id):
		return _result(false, "already_defeated")
	if not current_active_ids().has(actor_id):
		return _result(false, "actor_not_active")
	var checkpoints: Array[Dictionary] = []
	var tableau: Array[Dictionary] = []
	var completion: Dictionary = {}
	_defeated.append(actor_id)
	match _beat:
		"arrival":
			_beat = "road_east"
			checkpoints.append({"id": "horsell-arrival-clear", "kind": "encounter"})
			tableau.append({"kind": "witnesses", "state": "retreat"})
		"road_east":
			_beat = "road_west"
		"road_west":
			_beat = "fork"
			checkpoints.append({"id": "horsell-road-clear", "kind": "encounter"})
			tableau.append({"kind": "witnesses", "state": "absent"})
		"common":
			_beat = "departure"
			checkpoints.append({"id": "horsell-reunion", "kind": "encounter"})
		"departure":
			if _defeated.has("departure_a") and _defeated.has("departure_b"):
				_beat = "clear"
				completion = {"id": "horsell-scouts-clear"}
				tableau.append({"kind": "eruption", "visible": true})
	# State commits before the caller can execute any of these intents. Copies
	# contain no callback/signals, and a duplicate defeat returns no new intent.
	var result: Dictionary = _result(true)
	result["checkpoint_intents"] = checkpoints
	result["completion_intent"] = completion
	result["tableau_intents"] = tableau
	return result


func snapshot_state() -> Dictionary:
	return {"schema_version": SNAPSHOT_VERSION, "level_id": LEVEL_ID, "beat": _beat, "route": _route, "alive_ids": current_active_ids(), "defeated_ids": _defeated.duplicate()}


func snapshot_error(state: Dictionary) -> String:
	if state.size() != 6 or not state.has_all(["schema_version", "level_id", "beat", "route", "alive_ids", "defeated_ids"]):
		return "Horsell sequence snapshot fields differ from version 1"
	var version: Variant = state["schema_version"]
	if not (version is int or version is float) or not is_finite(float(version)) or version != SNAPSHOT_VERSION or not state["level_id"] is String or state["level_id"] != LEVEL_ID:
		return "Unsupported Horsell sequence version/identity"
	if not state["beat"] is String or not BEATS.has(state["beat"]) or not state["route"] is String or state["route"] not in ["", "left", "right"]:
		return "Invalid Horsell beat/route"
	if not state["alive_ids"] is Array or not state["defeated_ids"] is Array:
		return "Horsell sequence requires alive/defeated arrays"
	var alive: Array = state["alive_ids"]
	var defeated_ids: Array = state["defeated_ids"]
	if alive.size() > 2 or defeated_ids.size() > 6:
		return "Horsell sequence actor counts exceed its authored encounters"
	for ids: Array in [alive, defeated_ids]:
		var seen: Dictionary = {}
		for id: Variant in ids:
			if not id is String or not ACTOR_POSITIONS.has(id) or seen.has(id):
				return "Noncanonical/duplicate Horsell actor identity"
			seen[id] = true
	var beat: String = state["beat"]
	var route: String = state["route"]
	if beat in ["arrival", "road_east", "road_west", "fork"]:
		if not route.is_empty():
			return "Route cannot be chosen before the fork"
		var count: int = ["arrival", "road_east", "road_west", "fork"].find(beat)
		if defeated_ids != PREFIX.slice(0, count):
			return "Earlier encounters must form the exact Horsell prefix"
	else:
		if route.is_empty():
			return "Common/departure/clear requires one selected route"
		var required: Array[String] = PREFIX.duplicate()
		if beat != "common":
			required.append("common_" + route)
		if defeated_ids.size() < required.size() or defeated_ids.slice(0, required.size()) != required:
			return "Required road/selected-common defeat prefix differs"
		var final_ids: Array = defeated_ids.slice(required.size())
		if beat == "common" and not final_ids.is_empty():
			return "Selected common target cannot be cleared before its encounter"
		if beat == "departure" and final_ids.size() > 1:
			return "Both departure defeats must commit the clear beat"
		if beat == "clear" and final_ids.size() != 2:
			return "Clear requires both departure targets"
		for id: String in final_ids:
			if not DEPARTURE_IDS.has(id):
				return "Only departure targets may follow the selected common"
	var expected_alive: Array[String] = _active_ids(beat, route, defeated_ids)
	if alive != expected_alive:
		return "Alive targets differ from the exact authored progression"
	return ""


func restore_state(state: Dictionary) -> bool:
	last_snapshot_error = snapshot_error(state)
	if not last_snapshot_error.is_empty():
		return false
	# Validate every field before committing. This is a silent component restore,
	# not player/resource restoration or a replacement for the campaign snapshot.
	var defeated_ids: Array[String] = []
	for id: String in state["defeated_ids"]:
		defeated_ids.append(id)
	_beat = state["beat"]
	_route = state["route"]
	_defeated = defeated_ids
	return true


func _active_ids(beat: String, route: String, defeated_ids: Array) -> Array[String]:
	var result: Array[String] = []
	match beat:
		"arrival", "road_east", "road_west":
			result.append(beat)
		"common":
			result.append("common_" + route)
		"departure":
			for id: String in DEPARTURE_IDS:
				if not defeated_ids.has(id):
					result.append(id)
	return result


func _result(accepted: bool, reason: String = "") -> Dictionary:
	return {"accepted": accepted, "reason": reason, "beat": _beat, "route": _route, "active_ids": current_active_ids(), "checkpoint_intents": [], "completion_intent": {}, "tableau_intents": [], "exit_open": exit_is_open()}
