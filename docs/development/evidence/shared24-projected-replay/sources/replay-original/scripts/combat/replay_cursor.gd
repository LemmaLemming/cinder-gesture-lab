class_name CinderReplayCursor
extends RefCounted
## Frozen sequence clock/pose/event delivery only. No physical consumer, damage,
## scheduler lease, callbacks or safety proof. Caller owns the simulation clock.

const Sequence = preload("res://scripts/combat/replay_sequence.gd")
const Capture = preload("res://scripts/combat/action_capture.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const API_REVISION: String = "replay-cursor-1"
# Only derived timeline deadline/phase comparisons use this tolerance. Saved
# clocks, immutable identity, lock eligibility and no-rewind checks stay exact.
const TIME_EPSILON_S: float = Sequence.TIME_EPSILON_S
const MAX_CLOCK_S: float = Capture.MAX_CLOCK_S
const KEYS: Array[String] = ["api_revision", "schema_version", "sequence", "source_epoch", "generation", "configured_at_s", "armed", "armed_at_s", "timeline_origin_s", "last_advanced_clock_s", "phase", "next_event_index", "executed_events"]
const PREFIX_KEYS: Array[String] = ["event_id", "scheduled_at_s", "dispatch_clock_s"]

var last_error: String = ""
var last_snapshot_error: String = ""
var _data: Dictionary = {}
var _plan: Dictionary = {}


func configure(sequence_snapshot: Dictionary, source_epoch: String, generation: int, clock_s: float) -> bool:
	if not _data.is_empty():
		return _reject("A cursor binds one immutable sequence; create a new owner explicitly")
	var reader = Sequence.new()
	if not reader.restore_state(sequence_snapshot, source_epoch, generation):
		return _reject("Invalid frozen sequence: " + reader.last_snapshot_error)
	var plan: Dictionary = reader.state()
	if not _valid_clock(clock_s) or clock_s + float(plan.timeline.tether_until_s) > MAX_CLOCK_S:
		return _reject("Preview and complete finite timeline must fit the supported clock range")
	_data = {"api_revision": API_REVISION, "schema_version": 1, "sequence": reader.snapshot_state(), "source_epoch": source_epoch, "generation": generation, "configured_at_s": clock_s, "armed": false, "armed_at_s": null, "timeline_origin_s": null, "last_advanced_clock_s": clock_s, "phase": "warning", "next_event_index": 0, "executed_events": []}
	_plan = plan
	last_error = ""
	return true


func arm(timeline_origin_s: float, clock_s: float) -> bool:
	if _data.is_empty() or _data.armed:
		return _reject("A configured unarmed cursor may arm once only")
	if not _valid_clock(clock_s) or not _valid_clock(timeline_origin_s) or clock_s < float(_data.last_advanced_clock_s) or clock_s < float(_data.configured_at_s) + float(_plan.authored.warning_s) or timeline_origin_s != clock_s - float(_plan.authored.warning_s) or timeline_origin_s + float(_plan.timeline.tether_until_s) > MAX_CLOCK_S:
		return _reject("Actual lock requires monotonic time, full warning and canonical timeline origin")
	var candidate: Dictionary = _data.duplicate(true)
	candidate.armed = true
	candidate.armed_at_s = clock_s
	candidate.timeline_origin_s = timeline_origin_s
	candidate.last_advanced_clock_s = clock_s
	candidate.phase = _phase(candidate, _plan)
	_data = candidate
	last_error = ""
	return true


func advance(clock_s: float) -> Dictionary:
	if _data.is_empty() or not _valid_clock(clock_s) or clock_s < float(_data.last_advanced_clock_s):
		last_error = "Configured cursor requires a finite monotonic simulation clock"
		return {"accepted": false, "reason": last_error, "events": []}
	var candidate: Dictionary = _data.duplicate(true)
	var due: Array[Dictionary] = []
	if candidate.armed:
		var events: Array[Dictionary] = _events(_plan)
		while int(candidate.next_event_index) < events.size():
			var event: Dictionary = events[int(candidate.next_event_index)]
			var scheduled: float = float(candidate.timeline_origin_s) + float(event.at_s)
			if not _at_or_after(clock_s, scheduled):
				break
			candidate.executed_events.append({"event_id": event.event_id, "scheduled_at_s": scheduled, "dispatch_clock_s": clock_s})
			candidate.next_event_index = int(candidate.next_event_index) + 1
			var output: Dictionary = event.duplicate(true)
			output.scheduled_at_s = scheduled
			output.dispatch_clock_s = clock_s
			output.commitment_until_s = float(candidate.timeline_origin_s) + float(event.commitment_until_s)
			output.ready_s = float(candidate.timeline_origin_s) + float(event.ready_s)
			due.append(output)
	candidate.last_advanced_clock_s = clock_s
	candidate.phase = _phase(candidate, _plan)
	# No caller callback runs here. Commit the WHOLE due prefix before publishing
	# its copy, so even nested caller advance at this clock cannot deliver twice.
	_data = candidate
	last_error = ""
	return {"accepted": true, "events": due, "phase": _data.phase, "poses": _poses(_data, _plan)}


func state() -> Dictionary:
	if _data.is_empty():
		return {}
	return {"api_revision": API_REVISION, "sequence_id": _plan.sequence_id, "source_epoch": _data.source_epoch, "generation": _data.generation, "configured_at_s": _data.configured_at_s, "armed": _data.armed, "armed_at_s": _data.armed_at_s, "timeline_origin_s": _data.timeline_origin_s, "last_advanced_clock_s": _data.last_advanced_clock_s, "phase": _data.phase, "next_event_index": _data.next_event_index, "executed_events": _data.executed_events.duplicate(true), "poses": _poses(_data, _plan)}


func snapshot_state() -> Dictionary:
	return _data.duplicate(true)


func snapshot_error(snapshot: Dictionary, expected_sequence_snapshot: Dictionary, source_epoch: String, generation: int, expected_scheduler_clock_s: float) -> String:
	var error: String = Codec.value_error(snapshot)
	if error.is_empty():
		error = Codec.keys_error(snapshot, KEYS)
	if not error.is_empty():
		return error
	if snapshot.api_revision != API_REVISION or not Codec.is_integer(snapshot.schema_version, 1, 1) or snapshot.source_epoch != source_epoch or not Codec.is_integer(snapshot.generation, generation, generation) or not snapshot.sequence is Dictionary or not snapshot.armed is bool or not snapshot.phase is String or not snapshot.executed_events is Array:
		return "Cursor identity/schema must match its intended frozen sequence owner"
	var reader = Sequence.new()
	if not reader.restore_state(expected_sequence_snapshot, source_epoch, generation):
		return "Invalid expected immutable sequence: " + reader.last_snapshot_error
	if not _same_transport(snapshot.sequence, reader.snapshot_state()):
		return "Saved cursor cannot substitute another immutable sequence"
	var plan: Dictionary = reader.state()
	if not _valid_clock(expected_scheduler_clock_s) or not Codec.in_range(snapshot.configured_at_s, 0.0, MAX_CLOCK_S) or not Codec.in_range(snapshot.last_advanced_clock_s, float(snapshot.configured_at_s), MAX_CLOCK_S) or float(snapshot.last_advanced_clock_s) != expected_scheduler_clock_s or float(snapshot.configured_at_s) + float(plan.timeline.tether_until_s) > MAX_CLOCK_S:
		return "Cursor must match the external saved scheduler clock and bounded preview clock"
	var events: Array[Dictionary] = _events(plan)
	if not Codec.is_integer(snapshot.next_event_index, 0, events.size()) or snapshot.executed_events.size() != int(snapshot.next_event_index):
		return "Cursor delivery history must be the exact bounded event prefix"
	if not snapshot.armed:
		if snapshot.armed_at_s != null or snapshot.timeline_origin_s != null or int(snapshot.next_event_index) != 0 or snapshot.phase != "warning":
			return "Unarmed preview cannot contain delivered attacks or an armed timeline"
		return ""
	if not Codec.in_range(snapshot.armed_at_s, float(snapshot.configured_at_s), float(snapshot.last_advanced_clock_s)) or not Codec.in_range(snapshot.timeline_origin_s, 0.0, MAX_CLOCK_S) or float(snapshot.armed_at_s) < float(snapshot.configured_at_s) + float(plan.authored.warning_s) or float(snapshot.timeline_origin_s) != float(snapshot.armed_at_s) - float(plan.authored.warning_s) or float(snapshot.timeline_origin_s) + float(plan.timeline.tether_until_s) > MAX_CLOCK_S:
		return "Armed cursor must retain the actual canonical lock and complete finite timeline"
	if snapshot.phase != _phase(snapshot, plan):
		return "Cursor phase must derive exactly from arming and the external clock"
	var due_count: int = 0
	for event: Dictionary in events:
		if _at_or_after(float(snapshot.last_advanced_clock_s), float(snapshot.timeline_origin_s) + float(event.at_s)):
			due_count += 1
	if int(snapshot.next_event_index) != due_count:
		return "Saved cursor cannot omit a due event or deliver a future event"
	var previous_dispatch: float = float(snapshot.armed_at_s)
	for index: int in range(snapshot.executed_events.size()):
		var entry: Variant = snapshot.executed_events[index]
		var scheduled: float = float(snapshot.timeline_origin_s) + float(events[index].at_s)
		if not entry is Dictionary or not Codec.keys_error(entry, PREFIX_KEYS).is_empty() or entry.event_id != events[index].event_id or not Codec.is_number(entry.scheduled_at_s) or float(entry.scheduled_at_s) != scheduled or not Codec.in_range(entry.dispatch_clock_s, previous_dispatch, float(snapshot.last_advanced_clock_s)) or not _at_or_after(float(entry.dispatch_clock_s), scheduled):
			return "Delivered history must preserve exact event identity, deadlines and dispatch order"
		previous_dispatch = float(entry.dispatch_clock_s)
	return ""


func restore_state(snapshot: Dictionary, expected_sequence_snapshot: Dictionary, source_epoch: String, generation: int, expected_scheduler_clock_s: float) -> bool:
	last_snapshot_error = snapshot_error(snapshot, expected_sequence_snapshot, source_epoch, generation, expected_scheduler_clock_s)
	if not last_snapshot_error.is_empty():
		return false
	if not _data.is_empty():
		if not _same_transport(_data.sequence, snapshot.sequence) or float(_data.configured_at_s) != float(snapshot.configured_at_s) or float(snapshot.last_advanced_clock_s) < float(_data.last_advanced_clock_s) or int(snapshot.next_event_index) < int(_data.next_event_index) or (_data.armed and (not snapshot.armed or float(_data.armed_at_s) != float(snapshot.armed_at_s) or float(_data.timeline_origin_s) != float(snapshot.timeline_origin_s))):
			last_snapshot_error = "Existing cursor cannot rebind, unarm or rewind once-only progress"
			return false
		for index: int in range(_data.executed_events.size()):
			if not _same_transport(_data.executed_events[index], snapshot.executed_events[index]):
				last_snapshot_error = "Existing delivered prefix cannot be rewritten"
				return false
	var reader = Sequence.new()
	reader.restore_state(expected_sequence_snapshot, source_epoch, generation)
	var plan: Dictionary = reader.state()
	_data = snapshot.duplicate(true)
	_plan = plan
	last_error = ""
	return true


func _events(plan: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot: Dictionary in plan.timeline.slots:
		for event: Dictionary in slot.events:
			var copied: Dictionary = event.duplicate(true)
			copied.slot_id = slot.slot_id
			copied.generation = slot.generation
			result.append(copied)
	return result


func _phase(data: Dictionary, plan: Dictionary) -> String:
	if not data.armed:
		return "warning"
	var local: float = float(data.last_advanced_clock_s) - float(data.timeline_origin_s)
	if not _at_or_after(local, float(plan.timeline.playback_from_s)):
		return "lock"
	for slot: Dictionary in plan.timeline.slots:
		if _at_or_after(local, float(slot.from_s)) and not _at_or_after(local, float(slot.end_s)):
			return "active"
	if not _at_or_after(local, float(plan.timeline.replay_until_s)):
		return "gap"
	return "complete" if _at_or_after(local, float(plan.timeline.tether_until_s)) else "recovery"


func _poses(data: Dictionary, plan: Dictionary) -> Array[Dictionary]:
	var poses: Array[Dictionary] = []
	if not data.armed or data.phase != "active":
		return poses
	var local: float = float(data.last_advanced_clock_s) - float(data.timeline_origin_s)
	for index: int in range(plan.timeline.slots.size()):
		var slot: Dictionary = plan.timeline.slots[index]
		if not _at_or_after(local, float(slot.from_s)) or _at_or_after(local, float(slot.end_s)):
			continue
		var record: Dictionary = plan.capture_snapshot.slots[index].dash
		var action: String = "dash"
		var progress: float = clampf((local - float(slot.from_s)) / (float(slot.dash_until_s) - float(slot.from_s)), 0.0, 1.0)
		var stage: String = "travel"
		if _at_or_after(local, float(slot.dash_until_s)):
			stage = "settling"
			for event: Dictionary in slot.events:
				if _at_or_after(local, float(event.at_s)):
					record = event.record
					action = event.kind if not _at_or_after(local, float(event.commitment_until_s)) else "idle"
					progress = clampf((local - float(event.at_s)) / float(event.record.commitment_duration_s), 0.0, 1.0)
		poses.append({"slot_id": slot.slot_id, "generation": slot.generation, "position": _route_position(slot.route, local), "direction": record.direction, "stage": stage, "action": action, "action_progress": progress, "equipment_ids": record.equipment_ids.duplicate(true), "movement_damage": false})
	return poses


func _route_position(route: Array, local_s: float) -> Vector3:
	for index: int in range(route.size()):
		var sample: Dictionary = route[index]
		if local_s == float(sample.at_s):
			return sample.position
		if local_s < float(sample.at_s):
			if index == 0:
				return sample.position
			var previous: Dictionary = route[index - 1]
			var fraction: float = clampf((local_s - float(previous.at_s)) / (float(sample.at_s) - float(previous.at_s)), 0.0, 1.0)
			# Scalar floats preserve finite interpolation when native Vector3's
			# float32 subtraction would overflow between finite opposite extremes.
			var start: Vector3 = previous.position
			var finish: Vector3 = sample.position
			return Vector3(lerpf(float(start.x), float(finish.x), fraction), lerpf(float(start.y), float(finish.y), fraction), lerpf(float(start.z), float(finish.z), fraction))
	return route[-1].position


func _valid_clock(value: float) -> bool:
	return is_finite(value) and value >= 0.0 and value <= MAX_CLOCK_S


func _at_or_after(clock_s: float, deadline_s: float) -> bool:
	return clock_s >= deadline_s - TIME_EPSILON_S


func _same_transport(left: Variant, right: Variant) -> bool:
	if Codec.is_number(left) and Codec.is_number(right):
		return float(left) == float(right)
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size():
			return false
		for key: String in left:
			if not right.has(key) or not _same_transport(left[key], right[key]):
				return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size():
			return false
		for index: int in range(left.size()):
			if not _same_transport(left[index], right[index]):
				return false
		return true
	return typeof(left) == typeof(right) and left == right


func _reject(reason: String) -> bool:
	last_error = reason
	return false
