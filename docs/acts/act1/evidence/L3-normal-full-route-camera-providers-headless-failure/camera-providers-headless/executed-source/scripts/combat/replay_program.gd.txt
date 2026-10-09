class_name CinderReplayProgram
extends RefCounted
## Strict typed replay reader; captured Sequence/CaptureGate remain unchanged.
## Parsing transport never authenticates actual source/cycle/world custody.

const Captured = preload("res://scripts/combat/replay_sequence.gd")
const Authored = preload("res://scripts/combat/authored_enemy_sequence.gd")
const TIME_EPSILON_S: float = Captured.TIME_EPSILON_S

var last_error: String = ""
var last_snapshot_error: String = ""
var _reader
var _kind: String = ""


func snapshot_error(snapshot: Dictionary, source_epoch: String, generation: int) -> String:
	var candidate = _new_reader(snapshot.get("api_revision"))
	if candidate == null:
		return "Unknown replay program provenance/API"
	return candidate.snapshot_error(snapshot, source_epoch, generation)


func restore_state(snapshot: Dictionary, source_epoch: String, generation: int) -> bool:
	# Authored restore already performs the complete pure validation once.
	var api: Variant = snapshot.get("api_revision")
	if api is String and api == Authored.API_REVISION:
		var candidate = _reader if _reader != null and _kind == api else Authored.new()
		if not candidate.restore_state(snapshot, source_epoch, generation):
			last_snapshot_error = candidate.last_snapshot_error
			return false
		if _reader != null and _kind != api:
			last_snapshot_error = "An immutable replay program cannot change provenance"
			return false
		_reader = candidate
		_kind = api
		last_snapshot_error = ""
		last_error = ""
		return true
	last_snapshot_error = snapshot_error(snapshot, source_epoch, generation)
	if not last_snapshot_error.is_empty():
		return false
	var kind: String = snapshot.api_revision
	if _reader != null:
		if kind != _kind:
			last_snapshot_error = "An immutable replay program cannot change provenance"
			return false
		if not _reader.restore_state(snapshot, source_epoch, generation):
			last_snapshot_error = _reader.last_snapshot_error
			return false
	else:
		var candidate = _new_reader(kind)
		if not candidate.restore_state(snapshot, source_epoch, generation):
			last_snapshot_error = candidate.last_snapshot_error
			return false
		_reader = candidate
		_kind = kind
	last_error = ""
	return true


func state() -> Dictionary:
	return {} if _reader == null else _reader.state()


func snapshot_state() -> Dictionary:
	return {} if _reader == null else _reader.snapshot_state()


func is_authored_enemy() -> bool:
	return _kind == Authored.API_REVISION


func _new_reader(kind: Variant):
	if not kind is String:
		return null
	if kind == Captured.API_REVISION:
		return Captured.new()
	if kind == Authored.API_REVISION:
		return Authored.new()
	return null
