extends SceneTree
## Pure authored data/sequence checks. No actors, attacks, clocks or scenery are
## instantiated; these results do not certify a real fight or level completion.

const SequenceScript: Script = preload("res://scripts/acts/act2/horsell_sequence.gd")
var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for route: String in ["left", "right"]:
		for first_final: String in ["departure_a", "departure_b"]:
			_check_path(route, first_final)
	_check_malformed()
	print("Horsell authored sequence smoke: %d checks, %d failures; data scope only" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check_path(route: String, first_final: String) -> void:
	var sequence: RefCounted = SequenceScript.new() as RefCounted
	_expect(sequence.call("current_beat") == "arrival" and sequence.call("current_active_ids") == ["arrival"] and not bool(sequence.call("exit_is_open")), "initial authored beat has one arrival Scout and a closed exit")
	var positions: Dictionary = sequence.call("actor_positions")
	_expect(positions.size() == 7 and positions["common_right"] == Vector3(0.9, 0.0, -14.5), "logical right alternative shares the canonical common depth without creating a node")
	positions["arrival"] = Vector3(999.0, 0.0, 0.0)
	_expect(sequence.call("actor_positions")["arrival"] == Vector3(0.0, 0.0, -0.4), "position accessor cannot mutate authored geometry")
	_reject_event(sequence, "choose_route", "left", "route cannot be selected before the fork")
	_reject_event(sequence, "commit_defeat", "road_east", "out-of-order road defeat cannot skip arrival")
	_reject_event(sequence, "commit_defeat", "new-wave", "unknown actor cannot introduce a wave")
	_roundtrip(sequence, "arrival")
	var result: Dictionary = sequence.call("commit_defeat", "arrival")
	_expect(result["accepted"] and result["active_ids"] == ["road_east"] and result["checkpoint_intents"] == [{"id": "horsell-arrival-clear", "kind": "encounter"}] and result["tableau_intents"] == [{"kind": "witnesses", "state": "retreat"}], "arrival defeat commits the first road target, checkpoint and retreat intent")
	_expect(sequence.call("current_beat") == result["beat"] and sequence.call("snapshot_state")["defeated_ids"] == ["arrival"], "returned intents describe already committed state")
	_reject_event(sequence, "commit_defeat", "arrival", "duplicate arrival emits no extra intent or mutation")
	_roundtrip(sequence, "road east")
	result = sequence.call("commit_defeat", "road_east")
	_expect(result["accepted"] and result["active_ids"] == ["road_west"] and _intents_empty(result), "east road defeat activates only west without padding a checkpoint/wave")
	_reject_event(sequence, "commit_defeat", "common_" + route, "common defeat is unavailable until both road targets clear")
	_roundtrip(sequence, "road west")
	result = sequence.call("commit_defeat", "road_west")
	_expect(result["accepted"] and result["beat"] == "fork" and result["active_ids"].is_empty() and result["checkpoint_intents"] == [{"id": "horsell-road-clear", "kind": "encounter"}], "both road defeats are required before the idle fork and road checkpoint")
	_reject_event(sequence, "commit_defeat", "common_" + route, "no missing signal or idle fork automatically selects an encounter")
	_reject_event(sequence, "choose_route", "centre", "fork rejects an unauthored route")
	_roundtrip(sequence, "fork")
	result = sequence.call("choose_route", route)
	_expect(result["accepted"] and result["beat"] == "common" and result["active_ids"] == ["common_" + route] and _intents_empty(result), "one explicit landed-side choice activates only its common target")
	_reject_event(sequence, "choose_route", route, "repeated route choice is idempotent")
	var unchosen: String = "right" if route == "left" else "left"
	_reject_event(sequence, "choose_route", unchosen, "selected route cannot switch during its encounter")
	_reject_event(sequence, "commit_defeat", "common_" + unchosen, "unchosen common actor is not required or accepted")
	_roundtrip(sequence, "selected common")
	result = sequence.call("commit_defeat", "common_" + route)
	_expect(result["accepted"] and result["active_ids"] == ["departure_a", "departure_b"] and result["checkpoint_intents"] == [{"id": "horsell-reunion", "kind": "encounter"}], "selected common clear rejoins the route with exactly the authored departure pair")
	_roundtrip(sequence, "departure pair")
	result = sequence.call("commit_defeat", first_final)
	var second_final: String = "departure_b" if first_final == "departure_a" else "departure_a"
	_expect(result["accepted"] and result["beat"] == "departure" and result["active_ids"] == [second_final] and not result["exit_open"] and _intents_empty(result), "one final defeat leaves the other required target and keeps exit closed")
	_reject_event(sequence, "commit_defeat", first_final, "duplicate final defeat cannot replace the remaining target")
	_roundtrip(sequence, "one final remaining")
	result = sequence.call("commit_defeat", second_final)
	_expect(result["accepted"] and result["beat"] == "clear" and result["active_ids"].is_empty() and result["exit_open"] and result["completion_intent"] == {"id": "horsell-scouts-clear"} and result["tableau_intents"] == [{"kind": "eruption", "visible": true}], "both final defeats in either order commit one completion and harmless eruption intent")
	_expect(sequence.call("snapshot_state")["defeated_ids"].size() == 6 and sequence.call("selected_route") == route, "complete history contains six required defeats, never the unchosen Scout")
	_reject_event(sequence, "commit_defeat", second_final, "completion duplicate emits no repeat checkpoint/tableau/completion")
	_reject_event(sequence, "choose_route", unchosen, "completed route remains fixed")
	_roundtrip(sequence, "clear")
	var view: Dictionary = sequence.call("snapshot_state")
	view["defeated_ids"].clear()
	_expect(sequence.call("snapshot_state")["defeated_ids"].size() == 6, "snapshot access protects live defeat history from consumer edits")


func _check_malformed() -> void:
	var sequence: RefCounted = SequenceScript.new() as RefCounted
	var initial: Dictionary = sequence.call("snapshot_state")
	for version: Variant in [0, 1.5, NAN, INF, true, "1"]:
		var invalid: Dictionary = initial.duplicate(true)
		invalid["schema_version"] = version
		_reject_restore(sequence, invalid, "unsupported/nonfinite schema rejects atomically")
	var cases: Array[Dictionary] = [
		{"level_id": "A2-L2"}, {"level_id": StringName("A2-L1")}, {"beat": "unknown"}, {"beat": 2}, {"route": "centre"}, {"route": "left"},
		{"alive_ids": []}, {"alive_ids": true}, {"alive_ids": ["arrival", "arrival"]},
		{"alive_ids": ["road_east"]}, {"alive_ids": [NAN]}, {"alive_ids": [RefCounted.new()]},
		{"defeated_ids": ["arrival"]}, {"defeated_ids": ["arrival", "arrival"]}, {"defeated_ids": ["unknown"]},
		{"defeated_ids": {}}, {"beat": "departure", "route": "left", "alive_ids": ["departure_a", "departure_b"]},
	]
	for changes: Dictionary in cases:
		var invalid: Dictionary = initial.duplicate(true)
		invalid.merge(changes, true)
		_reject_restore(sequence, invalid, "malformed identities/types/illegal advancement reject before mutation")
	var extra: Dictionary = initial.duplicate(true)
	extra["hidden_clock"] = NAN
	_reject_restore(sequence, extra, "extra/nonfinite payload fields cannot smuggle an autonomous clock")
	var missing: Dictionary = initial.duplicate(true)
	missing.erase("route")
	_reject_restore(sequence, missing, "missing required state field rejects atomically")
	for id: String in ["arrival", "road_east", "road_west"]:
		sequence.call("commit_defeat", id)
	sequence.call("choose_route", "left")
	sequence.call("commit_defeat", "common_left")
	sequence.call("commit_defeat", "departure_b")
	var late: Dictionary = sequence.call("snapshot_state")
	var wrong_alive: Dictionary = late.duplicate(true)
	wrong_alive["alive_ids"] = ["departure_a", "departure_b"]
	_reject_restore(sequence, wrong_alive, "defeated final cannot remain in alive IDs")
	var switched: Dictionary = late.duplicate(true)
	switched["route"] = "right"
	_reject_restore(sequence, switched, "route history must match the actually cleared common actor")
	var premature: Dictionary = late.duplicate(true)
	premature["beat"] = "clear"
	premature["alive_ids"] = []
	_reject_restore(sequence, premature, "one departure defeat cannot restore a clear exit")
	var skipped: Dictionary = late.duplicate(true)
	skipped["defeated_ids"] = ["arrival", "road_west", "road_east", "common_left", "departure_b"]
	_reject_restore(sequence, skipped, "road history preserves its required order")
	_expect(sequence.call("restore_state", initial) and sequence.call("snapshot_state") == initial, "valid earlier component restore is silent and restores its exact declared state")


func _roundtrip(sequence: RefCounted, label: String) -> void:
	var before: Dictionary = sequence.call("snapshot_state")
	var transport: Dictionary = JSON.parse_string(JSON.stringify(before, "", true, true))
	var restored: RefCounted = SequenceScript.new() as RefCounted
	_expect(String(sequence.call("snapshot_error", before)).is_empty() and bool(restored.call("restore_state", transport)) and restored.call("snapshot_state") == before, "every legal %s state survives finite JSON and a silent fresh component restore" % label)
	var defeated_ids: Array = before["defeated_ids"]
	if not defeated_ids.is_empty():
		_reject_event(restored, "commit_defeat", defeated_ids[-1], "restored history suppresses re-emission of already committed intents")


func _reject_event(sequence: RefCounted, method: String, argument: String, label: String) -> void:
	var before: Dictionary = sequence.call("snapshot_state")
	var result: Dictionary = sequence.call(method, argument)
	_expect(not result["accepted"] and _intents_empty(result) and sequence.call("snapshot_state") == before, label)


func _reject_restore(sequence: RefCounted, invalid: Dictionary, label: String) -> void:
	var before: Dictionary = sequence.call("snapshot_state")
	_expect(not bool(sequence.call("restore_state", invalid)) and not String(sequence.get("last_snapshot_error")).is_empty() and sequence.call("snapshot_state") == before, label)


func _intents_empty(result: Dictionary) -> bool:
	return result["checkpoint_intents"].is_empty() and result["completion_intent"].is_empty() and result["tableau_intents"].is_empty()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
