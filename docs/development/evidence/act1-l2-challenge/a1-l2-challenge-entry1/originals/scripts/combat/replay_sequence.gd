class_name CinderReplaySequence
extends RefCounted
## Immutable captured-action data/timetable only. This neither reserves a
## scheduler exchange nor proves collision, floor, LOS, visibility or escape.
## Native state is diagnostic; snapshot_state is the canonical JSON transport.

const Capture = preload("res://scripts/combat/action_capture.gd")
const Player = preload("res://scripts/player.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const API_REVISION: String = "replay-sequence-1"
const ORIGIN_TOLERANCE_M: float = 0.00001
const TIME_EPSILON_S: float = 0.000000001
const MAX_AUTHORED_TIME_S: float = 3600.0
const HEADER_KEYS: Array[String] = ["api_revision", "schema_version", "sequence_id", "source_epoch", "generation", "capture_snapshot", "authored", "timeline"]
const AUTHORED_KEYS: Array[String] = ["recognition_s", "warning_s", "locked_lead_s", "inter_echo_gap_s", "final_recovery_s", "tether_position"]

var last_error: String = ""
var last_snapshot_error: String = ""
var _json: Dictionary = {}


func configure(sequence_id: String, capture_snapshot: Dictionary, authored: Dictionary, source_epoch: String, generation: int) -> bool:
	if not _json.is_empty():
		return _reject("A configured replay sequence is immutable; create a new plan explicitly")
	if not authored.get("tether_position") is Vector3 or not (authored.tether_position as Vector3).is_finite():
		return _reject("Authored tether requires a finite absolute native world position")
	var encoded: Dictionary = authored.duplicate(true)
	encoded.tether_position = Codec.vector3(authored.tether_position)
	var error: String = _input_error(sequence_id, capture_snapshot, encoded, source_epoch, generation)
	if not error.is_empty():
		return _reject(error)
	var timeline: Dictionary = _make_timeline(sequence_id, capture_snapshot, encoded)
	if not Codec.value_error(timeline).is_empty():
		return _reject("Derived compact timetable must remain finite JSON")
	_json = {"api_revision": API_REVISION, "schema_version": 1, "sequence_id": sequence_id, "source_epoch": source_epoch, "generation": generation, "capture_snapshot": capture_snapshot.duplicate(true), "authored": encoded, "timeline": timeline}
	last_error = ""
	return true


func state() -> Dictionary:
	if _json.is_empty():
		return {}
	var native: Dictionary = _json.duplicate(true)
	native.authored.tether_position = Codec.read_vector3(native.authored.tether_position)
	for slot: Dictionary in native.capture_snapshot.slots:
		for key: String in ["dash", "primary", "blast"]:
			slot[key] = {} if slot[key].is_empty() else Player.decode_world_action_record(slot[key], float(native.capture_snapshot.clock_s))
	for slot: Dictionary in native.timeline.slots:
		for sample: Dictionary in slot.route:
			sample.position = Codec.read_vector3(sample.position)
		for event: Dictionary in slot.events:
			event.record = Player.decode_world_action_record(event.record, float(native.capture_snapshot.clock_s))
	return native


func snapshot_state() -> Dictionary:
	return _json.duplicate(true)


func snapshot_error(snapshot: Dictionary, source_epoch: String, generation: int) -> String:
	var error: String = Codec.value_error(snapshot)
	if error.is_empty():
		error = Codec.keys_error(snapshot, HEADER_KEYS)
	if not error.is_empty():
		return error
	if snapshot.api_revision != API_REVISION or not Codec.is_integer(snapshot.schema_version, 1, 1) or snapshot.source_epoch != source_epoch or not Codec.is_integer(snapshot.generation, 1) or int(snapshot.generation) != generation or not snapshot.sequence_id is String or not snapshot.capture_snapshot is Dictionary or not snapshot.authored is Dictionary or not snapshot.timeline is Dictionary:
		return "Replay sequence identity/schema must match the intended source epoch/generation"
	error = _input_error(snapshot.sequence_id, snapshot.capture_snapshot, snapshot.authored, source_epoch, generation)
	if not error.is_empty():
		return error
	var expected: Dictionary = _make_timeline(snapshot.sequence_id, snapshot.capture_snapshot, snapshot.authored)
	if not _same_transport(expected, snapshot.timeline):
		return "Replay timetable must exactly derive from sealed records and authored timing"
	return ""


func restore_state(snapshot: Dictionary, source_epoch: String, generation: int) -> bool:
	last_snapshot_error = snapshot_error(snapshot, source_epoch, generation)
	if not last_snapshot_error.is_empty():
		return false
	if not _json.is_empty() and not _same_transport(_json, snapshot):
		last_snapshot_error = "An immutable plan cannot be replaced by another valid sequence"
		return false
	if _json.is_empty():
		_json = snapshot.duplicate(true)
	last_error = ""
	return true


func _input_error(sequence_id: String, capture_snapshot: Dictionary, authored: Dictionary, source_epoch: String, generation: int) -> String:
	if not _stable_id(sequence_id) or source_epoch.is_empty() or not Codec.is_integer(generation, 1):
		return "Stable sequence identity and explicit source epoch/generation required"
	var error: String = Codec.value_error(capture_snapshot)
	if not error.is_empty():
		return error
	if capture_snapshot.get("source_epoch") != source_epoch or not Codec.is_integer(capture_snapshot.get("generation"), generation, generation) or not Codec.in_range(capture_snapshot.get("clock_s"), 0.0, Capture.MAX_CLOCK_S):
		return "Capture must match the exact intended source epoch/generation"
	var reader = Capture.new()
	error = reader.snapshot_error(capture_snapshot, source_epoch, float(capture_snapshot.clock_s))
	if not error.is_empty():
		return error
	if not capture_snapshot.armed or capture_snapshot.slots.is_empty() or capture_snapshot.slots.size() > 2 or not capture_snapshot.pending.is_empty() or not capture_snapshot.dash_candidate.is_empty():
		return "Plan requires one/two sealed unretired slots with no pending combo or unpaired route"
	error = Codec.value_error(authored)
	if error.is_empty():
		error = Codec.keys_error(authored, AUTHORED_KEYS)
	if not error.is_empty():
		return error
	for key: String in ["recognition_s", "warning_s", "locked_lead_s", "final_recovery_s"]:
		if not Codec.in_range(authored[key], 0.0, MAX_AUTHORED_TIME_S) or float(authored[key]) <= 0.0:
			return "Explicit positive bounded authored time required: " + key
	if not Codec.in_range(authored.inter_echo_gap_s, 0.0, MAX_AUTHORED_TIME_S) or (capture_snapshot.slots.size() == 2 and float(authored.inter_echo_gap_s) <= 0.0) or not Codec.is_vector3(authored.tether_position):
		return "Two slots require an explicit positive gap and a finite absolute tether position"
	for slot: Dictionary in capture_snapshot.slots:
		var landing: Vector3 = Codec.read_vector3(slot.dash.landing)
		for key: String in ["primary", "blast"]:
			if slot[key].is_empty():
				continue
			var origin: Vector3 = Codec.read_vector3(slot[key].world_origin)
			if Vector2(origin.x - landing.x, origin.z - landing.z).length() > ORIGIN_TOLERANCE_M:
				return "Unsupported planar %s origin discontinuity; reject visibly without snapping or inventing motion" % key
	return ""


func _make_timeline(sequence_id: String, capture_snapshot: Dictionary, authored: Dictionary) -> Dictionary:
	# Reuse the capture's supported native timetable rather than reinterpret
	# attack commitment or ornamental animation as sustained damage windows.
	var reader = Capture.new()
	reader.restore_state(capture_snapshot, String(capture_snapshot.source_epoch), float(capture_snapshot.clock_s))
	var native_slots: Array[Dictionary] = reader.slots()
	var offset: float = float(authored.warning_s) + float(authored.locked_lead_s)
	var slots: Array[Dictionary] = []
	for index: int in range(native_slots.size()):
		var native: Dictionary = native_slots[index]
		var original: Dictionary = capture_snapshot.slots[index]
		var route: Array[Dictionary] = []
		for sample: Dictionary in original.dash.path:
			route.append({"position": sample.position.duplicate(), "at_s": offset + (float(sample.time_s) - float(original.dash.started_at_s))})
		var events: Array[Dictionary] = []
		for key: String in ["primary", "blast"]:
			if original[key].is_empty():
				continue
			var relative_time: float = float(native.timetable.primary_at_s if key == "primary" else native.timetable.blast_at_s)
			var at_s: float = offset + relative_time
			events.append({"event_id": "%s/slot-%d/%s" % [sequence_id, int(original.slot_id), key], "kind": key, "record_sequence": original[key].sequence, "at_s": at_s, "commitment_until_s": at_s + float(original[key].commitment_duration_s), "ready_s": at_s + float(original[key].cooldown_s), "damage_timing": "instant_at_execution", "record": original[key].duplicate(true)})
		var end_s: float = offset + float(native.timetable.duration_s)
		slots.append({"slot_id": original.slot_id, "generation": original.generation, "from_s": offset, "dash_until_s": offset + float(native.timetable.dash_end_s), "end_s": end_s, "omitted_idle_s": native.timetable.omitted_idle_s, "route": route, "events": events})
		offset = end_s
		if index + 1 < native_slots.size():
			offset += float(authored.inter_echo_gap_s)
	return {"warning_from_s": 0.0, "lock_from_s": authored.warning_s, "playback_from_s": float(authored.warning_s) + float(authored.locked_lead_s), "slots": slots, "replay_until_s": offset, "tether_from_s": offset, "tether_until_s": offset + float(authored.final_recovery_s)}


func _same_transport(left: Variant, right: Variant) -> bool:
	# Permit only tiny JSON decimal roundoff, never gameplay is_equal_approx.
	# Large identities stay exact; the public canonical codec checks all gear.
	if Codec.is_number(left) and Codec.is_number(right):
		if float(left) == floor(float(left)) and float(right) == floor(float(right)):
			return float(left) == float(right)
		return absf(float(left) - float(right)) <= TIME_EPSILON_S
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


func _stable_id(value: String) -> bool:
	if value.is_empty() or value.length() > 192:
		return false
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9_./:-]+$")
	var matched: RegExMatch = pattern.search(value)
	return matched != null and matched.get_string() == value


func _reject(reason: String) -> bool:
	last_error = reason
	return false
