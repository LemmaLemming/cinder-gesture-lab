class_name CinderActionCapture
extends RefCounted
## Bounded direct-player recording only, not a replay/fairness/scheduler API.
## The level arms at a paused stable actor barrier (no active/buffered dash),
## names the actor/encounter/attempt epoch, consumes contiguous publications
## before advance(actor_clock), and freezes that source clock during pause.
## World records have no sub-physics-tick dash-start identity: that stable arm
## boundary is required to distinguish a same-tick pre-arm dash correctly.
## Blast association follows the latest actually executed primary and its
## inclusive window. Executed records cannot reveal rejected GUI tap chains.

const Player = preload("res://scripts/player.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const API_REVISION: String = "action-capture-1"
const COMBO_WINDOW_S: float = 0.28
const TIME_EPSILON_S: float = 0.000000001
const MAX_CLOCK_S: float = 1000000000000.0
const SLOT_KEYS: Array[String] = ["slot_id", "generation", "dash", "primary", "blast", "window_until_s", "sealed_at_s"]

var last_error: String = ""
var last_snapshot_error: String = ""
var _busy: bool = false
var _data: Dictionary = {"api_revision": API_REVISION, "schema_version": 1, "source_epoch": "", "generation": 0, "armed": false, "max_slots": 0, "arm_after_sequence": 0, "arm_clock_s": 0.0, "cursor": 0, "last_publication_clock_s": 0.0, "clock_s": 0.0, "last_primary_sequence": 0, "allocated": 0, "retired": [], "slots": [], "pending": [], "dash_candidate": {}}


func arm(source_epoch: String, max_slots: int, after_sequence: int, clock_s: float) -> bool:
	if _busy or not _stable_epoch(source_epoch) or max_slots not in [1, 2] or not Codec.is_integer(after_sequence) or not Codec.in_range(clock_s, 0.0, MAX_CLOCK_S) or int(_data.generation) >= Codec.MAX_SAFE_INTEGER:
		return _reject("Stable source epoch, one/two slots, finite cursor/clock and an idle transaction required")
	if _data.armed and (not _data.slots.is_empty() or not _data.pending.is_empty() or not _data.dash_candidate.is_empty() or int(_data.allocated) < int(_data.max_slots)):
		return _reject("Take/discard or cancel the current recording before re-arming")
	if source_epoch == _data.source_epoch and (after_sequence < int(_data.cursor) or clock_s < float(_data.clock_s)):
		return _reject("The same source epoch cannot rewind its publication cursor or clock")
	_data = {"api_revision": API_REVISION, "schema_version": 1, "source_epoch": source_epoch, "generation": int(_data.generation) + 1, "armed": true, "max_slots": max_slots, "arm_after_sequence": after_sequence, "arm_clock_s": clock_s, "cursor": after_sequence, "last_publication_clock_s": clock_s, "clock_s": clock_s, "last_primary_sequence": 0, "allocated": 0, "retired": [], "slots": [], "pending": [], "dash_candidate": {}}
	last_error = ""
	return true


func ingest(native_record: Dictionary, source_epoch: String) -> bool:
	if _busy or not _data.armed or source_epoch != _data.source_epoch:
		return _reject("Publication must belong to this armed direct-player source epoch")
	var completed: Variant = native_record.get("completed_at_s")
	if not Codec.in_range(completed, float(_data.clock_s), MAX_CLOCK_S):
		return _reject("Ingest publications before advancing beyond their simulation time")
	var record: Dictionary = Player.encode_world_action_record(native_record, float(completed))
	if record.is_empty():
		return _reject("Only canonical actually completed direct-player publications can be ingested")
	if int(record.sequence) != int(_data.cursor) + 1:
		return _reject("World-action publications must be contiguous; recover the missing history or cancel visibly")
	if float(record.completed_at_s) < float(_data.last_publication_clock_s):
		return _reject("World-action publication times must remain ordered")
	if record.kind == "primary" and not _data.dash_candidate.is_empty() and int(_data.allocated) < int(_data.max_slots) and float(completed) + COMBO_WINDOW_S > MAX_CLOCK_S:
		return _reject("The completed combo window must remain within the finite source clock")
	_busy = true
	_advance(float(completed))
	_data.cursor = int(record.sequence)
	_data.last_publication_clock_s = float(completed)
	match record.kind:
		"dash":
			# ANY later completed dash supersedes an unpaired candidate. A
			# zero-travel/pre-arm completion is consumed but never sampled.
			_data.dash_candidate = {}
			if int(_data.allocated) < int(_data.max_slots) and float(record.distance) > 0.0 and float(record.started_at_s) >= float(_data.arm_clock_s):
				_data.dash_candidate = record.duplicate(true)
		"primary":
			_data.last_primary_sequence = int(record.sequence)
			if not _data.dash_candidate.is_empty() and int(_data.allocated) < int(_data.max_slots):
				_data.allocated = int(_data.allocated) + 1
				_data.pending.append({"slot_id": _data.allocated, "generation": _data.generation, "dash": _data.dash_candidate.duplicate(true), "primary": record.duplicate(true), "blast": {}, "window_until_s": float(completed) + COMBO_WINDOW_S, "sealed_at_s": null})
				_data.dash_candidate = {}
		"blast":
			# A blast belongs to the latest actually executed primary, not an
			# older captured primary hidden behind an uncaptured new attack.
			for slot: Dictionary in _data.pending:
				if int(slot.primary.sequence) == int(_data.last_primary_sequence) and slot.blast.is_empty() and float(completed) <= float(slot.window_until_s) + TIME_EPSILON_S:
					slot.blast = record.duplicate(true)
					break
	_busy = false
	last_error = ""
	return true


func advance(clock_s: float) -> bool:
	if _busy or not Codec.in_range(clock_s, float(_data.clock_s), MAX_CLOCK_S) or (_data.source_epoch.is_empty() and clock_s != 0.0):
		return _reject("Capture advances only with its finite monotonic source simulation clock")
	_busy = true
	_advance(clock_s)
	_busy = false
	last_error = ""
	return true


func _advance(clock_s: float) -> void:
	_data.clock_s = clock_s
	# The inclusive deadline remains open for an actual same-time blast;
	# ingest that publication before advancing beyond this boundary.
	while not _data.pending.is_empty() and clock_s > float(_data.pending[0].window_until_s) + TIME_EPSILON_S:
		var slot: Dictionary = _data.pending.pop_front()
		slot.sealed_at_s = slot.window_until_s
		_data.slots.append(slot)


func slots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot: Dictionary in _data.slots:
		result.append(_native_slot(slot))
	return result


func take_next() -> Dictionary:
	if _busy or _data.slots.is_empty():
		last_error = "No sealed slot available for once-only ordered consumption"
		return {}
	var slot: Dictionary = _data.slots.pop_front()
	_data.retired.append(int(slot.slot_id))
	last_error = ""
	return _native_slot(slot)


func discard_slot(slot_id: int) -> bool:
	if _busy or _data.slots.is_empty() or int(_data.slots[0].slot_id) != slot_id:
		return _reject("Discard only the next sealed slot in displayed order")
	take_next()
	return true


func cancel() -> bool:
	if _busy:
		return _reject("Cannot cancel an unfinished capture transaction")
	_data.armed = false
	_data.slots.clear()
	_data.pending.clear()
	_data.dash_candidate = {}
	_data.retired.clear()
	for slot_id: int in range(1, int(_data.allocated) + 1):
		_data.retired.append(slot_id)
	last_error = ""
	return true


func state() -> Dictionary:
	return {"api_revision": API_REVISION, "source_epoch": _data.source_epoch, "generation": _data.generation, "armed": _data.armed, "max_slots": _data.max_slots, "allocated": _data.allocated, "sealed": _data.slots.size(), "pending": _data.pending.size(), "retired": _data.retired.duplicate(), "has_dash_candidate": not _data.dash_candidate.is_empty(), "cursor": _data.cursor, "clock_s": _data.clock_s}


func _native_slot(slot: Dictionary) -> Dictionary:
	var result: Dictionary = slot.duplicate(true)
	for key: String in ["dash", "primary", "blast"]:
		result[key] = {} if slot[key].is_empty() else Player.decode_world_action_record(slot[key], float(_data.clock_s))
	result["timetable"] = _timetable(slot)
	return result


func _timetable(slot: Dictionary) -> Dictionary:
	# Preserve intrinsic sampled dash timing and within-combo blast spacing;
	# omit only arbitrary idle time between dash completion and primary.
	# These are action points/recovery deadlines, NOT active damage intervals,
	# nor recognition/inter-echo escape gaps. The replay validator owns those.
	var dash_end: float = float(slot.dash.completed_at_s) - float(slot.dash.started_at_s)
	var blast_at: Variant = null
	var blast_commitment_until: Variant = null
	var blast_ready: Variant = null
	var duration: float = dash_end + float(slot.primary.cooldown_s)
	if not slot.blast.is_empty():
		blast_at = dash_end + float(slot.blast.completed_at_s) - float(slot.primary.completed_at_s)
		blast_commitment_until = float(blast_at) + float(slot.blast.commitment_duration_s)
		blast_ready = float(blast_at) + float(slot.blast.cooldown_s)
		duration = maxf(duration, float(blast_ready))
	return {"dash_start_s": 0.0, "dash_end_s": dash_end, "primary_at_s": dash_end, "primary_commitment_until_s": dash_end + float(slot.primary.commitment_duration_s), "primary_ready_s": dash_end + float(slot.primary.cooldown_s), "blast_at_s": blast_at, "blast_commitment_until_s": blast_commitment_until, "blast_ready_s": blast_ready, "duration_s": duration, "omitted_idle_s": float(slot.primary.completed_at_s) - float(slot.dash.completed_at_s)}


func snapshot_state() -> Dictionary:
	last_snapshot_error = "Capture snapshots require a completed transaction" if _busy else _snapshot_error(_data, String(_data.source_epoch), float(_data.clock_s))
	return _data.duplicate(true) if last_snapshot_error.is_empty() else {}


func snapshot_error(snapshot: Dictionary, source_epoch: String, source_clock_s: float) -> String:
	return "Capture validation requires a completed transaction" if _busy else _snapshot_error(snapshot, source_epoch, source_clock_s)


func restore_state(snapshot: Dictionary, source_epoch: String, source_clock_s: float) -> bool:
	last_snapshot_error = snapshot_error(snapshot, source_epoch, source_clock_s)
	if not last_snapshot_error.is_empty():
		return false
	_data = snapshot.duplicate(true)
	last_error = ""
	return true


func _snapshot_error(value: Dictionary, expected_epoch: String, expected_clock: float) -> String:
	var error: String = Codec.value_error(value)
	if error.is_empty():
		error = Codec.keys_error(value, _data.keys())
	if not error.is_empty():
		return error
	if value.api_revision != API_REVISION or not Codec.is_integer(value.schema_version, 1, 1) or not value.source_epoch is String or value.source_epoch != expected_epoch or not Codec.is_integer(value.generation) or not value.armed is bool or not Codec.is_integer(value.max_slots, 0, 2) or not Codec.is_integer(value.arm_after_sequence) or not Codec.is_integer(value.cursor, int(value.arm_after_sequence)) or not Codec.is_integer(value.last_primary_sequence) or not Codec.is_integer(value.allocated, 0, 2) or not value.retired is Array or not value.slots is Array or not value.pending is Array or not value.dash_candidate is Dictionary:
		return "Invalid capture source identity/schema/bounds"
	for key: String in ["arm_clock_s", "clock_s", "last_publication_clock_s"]:
		if not Codec.in_range(value[key], 0.0, MAX_CLOCK_S):
			return "Capture clocks must be finite source simulation times"
	if not Codec.in_range(expected_clock, 0.0, MAX_CLOCK_S) or float(value.clock_s) != expected_clock or float(value.arm_clock_s) > float(value.last_publication_clock_s) or float(value.last_publication_clock_s) > float(value.clock_s):
		return "Capture must restore with the same paused source epoch/clock generation (stored %.17f, source %.17f, difference %.17f; arm %.17f, publication %.17f)" % [float(value.clock_s), expected_clock, float(value.clock_s) - expected_clock, float(value.arm_clock_s), float(value.last_publication_clock_s)]
	if value.source_epoch.is_empty():
		return "Unbound capture can retain only its initial empty state" if value.generation != 0 or value.armed or value.max_slots != 0 or value.arm_after_sequence != 0 or value.cursor != 0 or value.last_primary_sequence != 0 or value.allocated != 0 or value.arm_clock_s != 0.0 or value.clock_s != 0.0 or value.last_publication_clock_s != 0.0 or not value.retired.is_empty() or not value.slots.is_empty() or not value.pending.is_empty() or not value.dash_candidate.is_empty() else ""
	# JSON parses integral numbers as floats. Validate their exact integer value
	# rather than Array.has(), which compares their Variant numeric types.
	if not _stable_epoch(value.source_epoch) or not Codec.is_integer(value.generation, 1) or not Codec.is_integer(value.max_slots, 1, 2) or int(value.allocated) > int(value.max_slots) or int(value.last_primary_sequence) > int(value.cursor) or (int(value.last_primary_sequence) != 0 and int(value.last_primary_sequence) <= int(value.arm_after_sequence)):
		return "Malformed armed source/generation/publication cursor"
	if int(value.cursor) == int(value.arm_after_sequence) and (value.allocated != 0 or value.last_primary_sequence != 0 or float(value.last_publication_clock_s) != float(value.arm_clock_s) or not value.dash_candidate.is_empty()):
		return "A capture without publications cannot contain sampled actions"
	if value.retired.size() + value.slots.size() + value.pending.size() != int(value.allocated):
		return "Each allocated slot must occur exactly once as retired, sealed or pending"
	var expected_slot: int = 1
	for id: Variant in value.retired:
		if not Codec.is_integer(id, expected_slot, expected_slot):
			return "Retired slot consumption must be once-only and ordered"
		expected_slot += 1
	var publications: Dictionary = {}
	var previous_primary: int = 0
	for collection: String in ["slots", "pending"]:
		for entry: Variant in value[collection]:
			if not entry is Dictionary:
				return "Slot must be a finite record dictionary"
			error = _slot_error(entry, value, expected_slot, collection == "pending")
			if not error.is_empty():
				return error
			if previous_primary > 0 and int(entry.dash.sequence) <= previous_primary:
				return "Combinations must follow actual sequential dash/primary publications"
			previous_primary = int(entry.primary.sequence)
			for key: String in ["dash", "primary", "blast"]:
				if not entry[key].is_empty():
					var sequence: int = int(entry[key].sequence)
					if publications.has(sequence):
						return "Each captured publication sequence must occur only once"
					publications[sequence] = entry[key]
			expected_slot += 1
	if not value.armed and (not value.slots.is_empty() or not value.pending.is_empty() or not value.dash_candidate.is_empty()):
		return "Cancelled capture cannot retain stale slots or movement"
	if not value.dash_candidate.is_empty():
		error = _record_error(value.dash_candidate, "dash", value)
		if not error.is_empty():
			return error
		if int(value.allocated) >= int(value.max_slots) or float(value.dash_candidate.distance) <= 0.0 or float(value.dash_candidate.started_at_s) < float(value.arm_clock_s) or int(value.dash_candidate.sequence) <= int(value.last_primary_sequence):
			return "Dash candidate must be the latest eligible positive post-arm completion"
		var sequence: int = int(value.dash_candidate.sequence)
		if publications.has(sequence):
			return "Dash candidate cannot reuse a captured publication sequence"
		publications[sequence] = value.dash_candidate
	# A later completed dash can publish between an earlier primary and its
	# blast while both slots are pending. Preserve that legal interleaving, but
	# ensure each actual sequence has one identity and monotonic completion time.
	var ordered_sequences: Array = publications.keys()
	ordered_sequences.sort()
	var previous_time: float = float(value.arm_clock_s)
	for sequence: int in ordered_sequences:
		var publication: Dictionary = publications[sequence]
		if float(publication.completed_at_s) < previous_time:
			return "Captured publication sequence and completion time must agree"
		previous_time = float(publication.completed_at_s)
	return ""


func _slot_error(slot: Dictionary, header: Dictionary, expected_slot: int, pending: bool) -> String:
	var error: String = Codec.keys_error(slot, SLOT_KEYS)
	if not error.is_empty():
		return error
	if not Codec.is_integer(slot.slot_id, expected_slot, expected_slot) or slot.generation != header.generation or not slot.dash is Dictionary or not slot.primary is Dictionary or not slot.blast is Dictionary:
		return "Slot identity/action fields must preserve this bounded capture generation"
	for key: String in ["dash", "primary"]:
		error = _record_error(slot[key], key, header)
		if not error.is_empty():
			return error
	if float(slot.dash.distance) <= 0.0 or float(slot.dash.started_at_s) < float(header.arm_clock_s) or int(slot.dash.sequence) >= int(slot.primary.sequence) or float(slot.dash.completed_at_s) > float(slot.primary.completed_at_s) or int(slot.primary.sequence) > int(header.last_primary_sequence):
		return "Slot requires an eligible completed dash then an actually executed primary"
	if not Codec.in_range(slot.window_until_s, 0.0, MAX_CLOCK_S) or absf(float(slot.window_until_s) - (float(slot.primary.completed_at_s) + COMBO_WINDOW_S)) > TIME_EPSILON_S:
		return "Capture window must retain the actual 0.28 simulation-second primary deadline"
	if pending:
		if slot.sealed_at_s != null or float(header.clock_s) > float(slot.window_until_s) + TIME_EPSILON_S:
			return "Pending combo cannot be already sealed or past its window"
	elif not Codec.is_number(slot.sealed_at_s) or float(slot.sealed_at_s) != float(slot.window_until_s) or float(header.clock_s) <= float(slot.window_until_s) + TIME_EPSILON_S:
		return "Sealed slot must have waited for its complete combo window"
	if not slot.blast.is_empty():
		error = _record_error(slot.blast, "blast", header)
		if not error.is_empty():
			return error
		if int(slot.blast.sequence) <= int(slot.primary.sequence) or float(slot.blast.completed_at_s) < float(slot.primary.completed_at_s) or float(slot.blast.completed_at_s) > float(slot.window_until_s) + TIME_EPSILON_S:
			return "Optional blast must actually follow this primary within its inclusive quick window"
		if int(header.last_primary_sequence) > int(slot.primary.sequence) and int(header.last_primary_sequence) < int(slot.blast.sequence):
			return "Optional blast cannot attach behind a newer actually executed primary"
		for collection: String in ["slots", "pending"]:
			for other: Variant in header[collection]:
				if other is Dictionary and other.get("primary") is Dictionary and Codec.is_integer(other.primary.get("sequence"), 1) and int(other.primary.sequence) > int(slot.primary.sequence) and int(other.primary.sequence) < int(slot.blast.sequence):
					return "Optional blast cannot cross another sequential combination's primary"
	return ""


func _record_error(record: Dictionary, kind: String, header: Dictionary) -> String:
	var error: String = Player.world_action_record_error(record, float(header.clock_s))
	if not error.is_empty():
		return error
	if record.kind != kind or int(record.sequence) <= int(header.arm_after_sequence) or int(record.sequence) > int(header.cursor) or float(record.completed_at_s) < float(header.arm_clock_s) or float(record.completed_at_s) > float(header.last_publication_clock_s):
		return "Captured action must belong to this contiguous post-arm direct-player stream"
	return ""


func _stable_epoch(value: String) -> bool:
	if value.is_empty() or value.length() > 192:
		return false
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9_./:-]+$")
	var matched: RegExMatch = pattern.search(value)
	return matched != null and matched.get_string() == value


func _reject(reason: String) -> bool:
	last_error = reason
	return false
