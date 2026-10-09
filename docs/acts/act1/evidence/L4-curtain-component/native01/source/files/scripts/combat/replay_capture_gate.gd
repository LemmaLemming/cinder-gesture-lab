class_name CinderReplayCaptureGate
extends Node3D
## Sole bounded capture custodian for one actual shared actor/parent epoch.
## Historical JSON is never an input to preparation. This gate retires data;
## it does not prove/reserve/execute playback or authorize a second consumer.
signal sequence_retired(sequence_snapshot: Dictionary, retirement: Dictionary)
signal gate_failed(reason: String)

const Player = preload("res://scripts/player.gd")
const Capture = preload("res://scripts/combat/action_capture.gd")
const Sequence = preload("res://scripts/combat/replay_sequence.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const API_REVISION: String = "replay-capture-gate-1"
const KEYS: Array[String] = ["api_revision", "schema_version", "owner_id", "actor_id", "source_epoch", "clock_s", "actor_sha256", "capture", "prepared_sequence", "prepared_actor_sha256", "consumed_sequence", "retirement", "retired_generation", "cancel_reason"]
const RECEIPT_KEYS: Array[String] = ["sequence_id", "generation", "slot_ids", "clock_s", "actor_sha256"]

var last_error: String = ""
var last_snapshot_error: String = ""
var _actor: WeakRef
var _owner_id: String = ""
var _actor_id: String = ""
var _epoch: String = ""
var _capture = Capture.new()
var _prepared: Dictionary = {}
var _prepared_actor_sha256: String = ""
var _consumed: Dictionary = {}
var _retirement: Dictionary = {}
var _retired_generation: int = 0
var _cancel_reason: String = ""
var _fault: String = ""
var _busy: bool = false


func _ready() -> void:
	process_physics_priority = 2000


func configure(owner_id: String, actor_id: String, actor: CinderPlayer, source_epoch: String) -> bool:
	if _busy or not _epoch.is_empty() or not _id(owner_id) or not _id(actor_id) or not _id(source_epoch) or not is_inside_tree() or not is_node_ready() or not get_tree().paused:
		return _reject("Configure one immutable parent/actor/epoch at a paused ready barrier")
	if not is_instance_valid(actor) or actor.get_script() != Player or not actor.is_inside_tree() or not actor.is_node_ready() or actor.is_queued_for_deletion() or actor.get_world_3d() != get_world_3d():
		return _reject("Exact ready same-world shared Player required")
	var actual: Dictionary = actor.snapshot_state()
	if actual.is_empty():
		return _reject("Deferred actual actor barrier required: " + actor.last_snapshot_error)
	_owner_id = owner_id
	_actor_id = actor_id
	_epoch = source_epoch
	_actor = weakref(actor)
	actor.world_action_executed.connect(_on_actual_publication)
	last_error = ""
	return true


func arm(max_slots: int) -> bool:
	var actual: Dictionary = _barrier(true)
	if actual.is_empty():
		return false
	_busy = true
	var staged = _capture_copy()
	var ok: bool = staged != null and staged.arm(_epoch, max_slots, int(actual.world_actions.sequence), float(actual.world_actions.clock_s))
	if ok:
		_capture = staged
		_prepared.clear()
		_prepared_actor_sha256 = ""
		_cancel_reason = ""
		_fault = ""
		last_error = ""
	else:
		last_error = "Current capture must be retired/cancelled before rearming" if staged == null else staged.last_error
	_busy = false
	return ok


func synchronize() -> bool:
	if _busy or not _live():
		return _reject("Synchronization requires the bound live actor outside callbacks")
	if not _fault.is_empty():
		return _reject(_fault)
	_busy = true
	var error: String = _synchronize()
	if not error.is_empty():
		_fault = error
		last_error = error
		gate_failed.emit(error)
	else:
		last_error = ""
	_busy = false
	return error.is_empty()


func _physics_process(_delta: float) -> void:
	if _live() and _fault.is_empty() and not get_tree().paused:
		synchronize()


func _on_actual_publication(_untrusted_signal_record: Dictionary) -> void:
	# Drain the bound actor's authoritative defensive history, not the signal
	# argument. Nested real publications may precede this listener's callback.
	if not _live():
		return
	if _busy:
		if not _player().get_world_action_records(int(_capture.state().cursor)).is_empty():
			_fault = "Actual actor published inside a gate transaction; cancel visibly at a deferred barrier"
		return
	if _fault.is_empty():
		synchronize()


func _synchronize() -> String:
	var before: Dictionary = _capture.snapshot_state()
	if before.is_empty():
		return "Private capture is invalid"
	if int(before.generation) == 0:
		return ""
	var actor: CinderPlayer = _player()
	var clock: float = actor.get_world_action_clock()
	if not Codec.in_range(clock, float(before.clock_s), Capture.MAX_CLOCK_S):
		return "Actual actor clock rewound/drifted; rebuild the whole epoch instead of replaying history"
	var staged = _capture_copy()
	if staged == null:
		return "Cannot stage the private capture"
	if before.armed:
		var records: Array[Dictionary] = actor.get_world_action_records(int(before.cursor))
		for record: Dictionary in records:
			if not staged.ingest(record, _epoch):
				return "Actual publication stream lost continuity: " + staged.last_error
	if not staged.advance(clock):
		return "Actual-clock advance failed: " + staged.last_error
	_capture = staged
	if not _prepared.is_empty() and not _same(_prepared.capture_snapshot, staged.snapshot_state()):
		_prepared.clear()
		_prepared_actor_sha256 = ""
	return ""


func prepare_sequence(sequence_id: String, authored: Dictionary) -> Dictionary:
	var actual: Dictionary = _barrier(true)
	if actual.is_empty() or not _fault.is_empty():
		if not _fault.is_empty():
			last_error = _fault
		return {}
	_busy = true
	var current: Dictionary = _capture.snapshot_state()
	var error: String = _capture_pair_error(current, actual)
	if error.is_empty():
		error = _complete_error(current)
	var plan = Sequence.new()
	if error.is_empty() and not plan.configure(sequence_id, current, authored, _epoch, int(current.generation)):
		error = plan.last_error
	var proposed: Dictionary = plan.snapshot_state() if error.is_empty() else {}
	var actor_sha256: String = _digest(actual)
	if error.is_empty() and not _prepared.is_empty() and (not _same(_prepared, proposed) or _prepared_actor_sha256 != actor_sha256):
		error = "Prepared proposal is immutable; discard it explicitly before a different preparation"
	if error.is_empty():
		_prepared = proposed.duplicate(true)
		_prepared_actor_sha256 = actor_sha256
		last_error = ""
	else:
		last_error = error
	_busy = false
	return proposed.duplicate(true) if error.is_empty() else {}


func discard_preparation() -> bool:
	if _barrier(false).is_empty():
		return false
	_prepared.clear()
	_prepared_actor_sha256 = ""
	last_error = ""
	return true


func consume_sequence(sequence_snapshot: Dictionary) -> Dictionary:
	var actual: Dictionary = _barrier(true)
	if actual.is_empty() or not _fault.is_empty():
		return {"accepted": false, "reason": last_error if _fault.is_empty() else _fault}
	_busy = true
	var current: Dictionary = _capture.snapshot_state()
	var error: String = _capture_pair_error(current, actual)
	if error.is_empty():
		error = _complete_error(current)
	if error.is_empty() and (_prepared.is_empty() or not _same(sequence_snapshot, _prepared) or not _same(_prepared.capture_snapshot, current) or _prepared_actor_sha256 != _digest(actual)):
		error = "Only the exact private current proposal and actual frozen actor may consume this capture"
	var staged = _capture_copy()
	var ids: Array[int] = []
	if error.is_empty():
		for slot: Dictionary in current.slots:
			var retired: Dictionary = staged.take_next()
			if retired.is_empty() or int(retired.slot_id) != int(slot.slot_id):
				error = "Staged FIFO retirement did not match the whole sealed capture"
				break
			ids.append(int(slot.slot_id))
	if error.is_empty() and (not staged.slots().is_empty() or staged.state().retired != ids):
		error = "Complete once-only FIFO retirement required"
	if not error.is_empty():
		last_error = error
		_busy = false
		return {"accepted": false, "reason": error}
	# Commit every selected slot before emitting/binding any external consumer.
	_capture = staged
	_consumed = _prepared.duplicate(true)
	_retired_generation = int(current.generation)
	_retirement = {"sequence_id": _consumed.sequence_id, "generation": _retired_generation, "slot_ids": ids, "clock_s": actual.world_actions.clock_s, "actor_sha256": _prepared_actor_sha256}
	_prepared.clear()
	_prepared_actor_sha256 = ""
	var answer := {"accepted": true, "reason": "", "sequence": _consumed.duplicate(true), "retirement": retirement_state()}
	sequence_retired.emit(_consumed.duplicate(true), retirement_state())
	var callback_error: String = _callback_boundary_error(actual)
	if _fault.is_empty() and not callback_error.is_empty():
		_fault = callback_error
	if not _fault.is_empty():
		# Damage, gear and queued/started dashes need not publish an action yet.
		# Retirement is irreversible; report the invalid frozen boundary so
		# its parent cancels visibly instead of silently binding playback.
		answer.reason = _fault
		gate_failed.emit(_fault)
	last_error = _fault
	_busy = false
	return answer


func _callback_boundary_error(before: Dictionary) -> String:
	# Keep the gate transaction guard held through this check and gate_failed.
	# A completed-action listener alone cannot guard the entire frozen actor.
	if not _live() or not get_tree().paused:
		return "Consumer changed the bound live/paused actor boundary; cancel visibly at a deferred barrier"
	var actor: CinderPlayer = _player()
	var after: Dictionary = actor.snapshot_state()
	if after.is_empty():
		return "Consumer left the deferred actor snapshot boundary: " + actor.last_snapshot_error
	if not _same(before, after):
		return "Consumer changed the exact frozen player state; cancel visibly at a deferred barrier"
	return ""


func cancel(reason: String) -> bool:
	var actual: Dictionary = _barrier(false)
	if actual.is_empty() or reason.is_empty() or reason.length() > 512:
		return _reject("Cancellation requires a deferred paused actor and a bounded visible reason")
	var staged = _capture_copy()
	if staged == null or not staged.cancel() or (int(staged.state().generation) > 0 and not staged.advance(float(actual.world_actions.clock_s))):
		return _reject("Cannot stage capture cancellation at the actual clock")
	_capture = staged
	_retired_generation = maxi(_retired_generation, int(staged.state().generation))
	_prepared.clear()
	_prepared_actor_sha256 = ""
	_cancel_reason = reason
	_fault = ""
	last_error = ""
	return true


func state() -> Dictionary:
	return {"api_revision": API_REVISION, "owner_id": _owner_id, "actor_id": _actor_id, "source_epoch": _epoch, "capture": _capture.state(), "prepared": not _prepared.is_empty(), "retired_generation": _retired_generation, "retirement": retirement_state(), "cancel_reason": _cancel_reason, "fault": _fault}


func retirement_state() -> Dictionary:
	var copy: Dictionary = _retirement.duplicate(true)
	if not copy.is_empty():
		copy.merge({"owner_id": _owner_id, "actor_id": _actor_id, "source_epoch": _epoch})
	return copy


func snapshot_state() -> Dictionary:
	var actual: Dictionary = _barrier(false)
	if actual.is_empty() or not _fault.is_empty():
		last_snapshot_error = last_error if _fault.is_empty() else _fault
		return {}
	_busy = true
	var value: Dictionary = _snapshot(actual)
	last_snapshot_error = _snapshot_error(value, actual)
	_busy = false
	return value if last_snapshot_error.is_empty() else {}


func snapshot_error(snapshot: Dictionary, saved_player: Dictionary) -> String:
	var error: String = _access_error()
	if not error.is_empty():
		return error
	_busy = true
	error = _snapshot_error(snapshot, saved_player)
	_busy = false
	return error


func restore_state(snapshot: Dictionary, saved_player: Dictionary) -> bool:
	last_snapshot_error = _access_error()
	if not last_snapshot_error.is_empty():
		return false
	_busy = true
	last_snapshot_error = _snapshot_error(snapshot, saved_player)
	var actual: Dictionary = _player().snapshot_state() if last_snapshot_error.is_empty() else {}
	if last_snapshot_error.is_empty() and (actual.is_empty() or not _same(actual, saved_player)):
		last_snapshot_error = "Restore the independently validated actual player before the gate commit"
	if last_snapshot_error.is_empty() and int(_capture.state().generation) > 0 and not _same(_snapshot(actual), snapshot):
		last_snapshot_error = "Existing capture owners cannot rewind/replace retirement; rebuild the whole saved unit"
	var staged = Capture.new()
	if last_snapshot_error.is_empty() and not staged.restore_state(snapshot.capture, String(snapshot.capture.source_epoch), float(snapshot.capture.clock_s)):
		last_snapshot_error = staged.last_snapshot_error
	if last_snapshot_error.is_empty():
		_capture = staged
		_prepared = snapshot.prepared_sequence.duplicate(true)
		_prepared_actor_sha256 = snapshot.prepared_actor_sha256
		_consumed = snapshot.consumed_sequence.duplicate(true)
		_retirement = snapshot.retirement.duplicate(true)
		_retired_generation = int(snapshot.retired_generation)
		_cancel_reason = snapshot.cancel_reason
		_fault = ""
		last_error = ""
	_busy = false
	return last_snapshot_error.is_empty()


func _snapshot(actual: Dictionary) -> Dictionary:
	return {"api_revision": API_REVISION, "schema_version": 1, "owner_id": _owner_id, "actor_id": _actor_id, "source_epoch": _epoch, "clock_s": actual.world_actions.clock_s, "actor_sha256": _digest(actual), "capture": _capture.snapshot_state(), "prepared_sequence": _prepared.duplicate(true), "prepared_actor_sha256": _prepared_actor_sha256, "consumed_sequence": _consumed.duplicate(true), "retirement": _retirement.duplicate(true), "retired_generation": _retired_generation, "cancel_reason": _cancel_reason}


func _snapshot_error(value: Dictionary, saved_player: Dictionary) -> String:
	var error: String = _player().snapshot_error(saved_player)
	if not error.is_empty():
		return "Complete validated saved-player context required: " + error
	error = Codec.value_error(value)
	if error.is_empty():
		error = Codec.keys_error(value, KEYS)
	if not error.is_empty():
		return error
	if value.api_revision != API_REVISION or not Codec.is_integer(value.schema_version, 1, 1) or value.owner_id != _owner_id or value.actor_id != _actor_id or value.source_epoch != _epoch or not Codec.is_number(value.clock_s) or float(value.clock_s) != float(saved_player.world_actions.clock_s) or value.actor_sha256 != _digest(saved_player):
		return "Exact immutable gate/actor/epoch and whole saved-player identity required"
	if not value.capture is Dictionary or not value.prepared_sequence is Dictionary or not value.consumed_sequence is Dictionary or not value.retirement is Dictionary or not value.prepared_actor_sha256 is String or not Codec.is_integer(value.retired_generation) or not value.cancel_reason is String or value.cancel_reason.length() > 512:
		return "Malformed bounded gate state"
	error = _capture_pair_error(value.capture, saved_player)
	if not error.is_empty():
		return error
	var generation: int = int(value.capture.generation)
	if int(value.retired_generation) > generation:
		return "Retirement cannot refer to an unobserved generation"
	if value.capture.armed and generation <= int(value.retired_generation) and (not value.capture.slots.is_empty() or not value.capture.pending.is_empty() or not value.capture.dash_candidate.is_empty() or int(value.capture.allocated) != int(value.capture.max_slots)):
		return "Retired generations cannot reopen capacity or retain reusable samples"
	if not value.prepared_sequence.is_empty():
		if value.prepared_actor_sha256 != value.actor_sha256 or generation <= int(value.retired_generation) or not _same(value.prepared_sequence.get("capture_snapshot"), value.capture):
			return "Prepared proposal must bind this exact unretired capture and saved actor"
		error = _complete_error(value.capture, int(value.retired_generation))
		if error.is_empty():
			error = _sequence_error(value.prepared_sequence)
		if not error.is_empty():
			return error
	elif not value.prepared_actor_sha256.is_empty():
		return "Absent preparation cannot retain actor authority"
	if value.retirement.is_empty() != value.consumed_sequence.is_empty():
		return "Retirement and original consumed sequence must be retained together"
	if not value.retirement.is_empty():
		error = Codec.keys_error(value.retirement, RECEIPT_KEYS)
		if not error.is_empty():
			return error
		error = _sequence_error(value.consumed_sequence)
		if error.is_empty():
			error = _complete_error(value.consumed_sequence.capture_snapshot, int(value.consumed_sequence.generation) - 1)
		if not error.is_empty():
			return error
		var receipt: Dictionary = value.retirement
		var consumed: Dictionary = value.consumed_sequence
		if receipt.sequence_id != consumed.sequence_id or not Codec.is_integer(receipt.generation, int(consumed.generation), int(consumed.generation)) or int(receipt.generation) > int(value.retired_generation) or not receipt.slot_ids is Array or receipt.slot_ids.size() != consumed.capture_snapshot.slots.size() or not Codec.is_number(receipt.clock_s) or float(receipt.clock_s) != float(consumed.capture_snapshot.clock_s) or float(receipt.clock_s) > float(value.clock_s) or not _sha256(receipt.actor_sha256):
			return "Retirement must retain exact complete original sequence/clock/actor identity"
		for index: int in range(receipt.slot_ids.size()):
			if not Codec.is_integer(receipt.slot_ids[index], index + 1, index + 1):
				return "All original FIFO slots must be retired once in displayed order"
		if generation == int(receipt.generation) and (not value.capture.slots.is_empty() or not value.capture.pending.is_empty() or not value.capture.dash_candidate.is_empty() or not _same(value.capture.retired, receipt.slot_ids) or value.capture.allocated != consumed.capture_snapshot.allocated or int(value.capture.cursor) < int(consumed.capture_snapshot.cursor)):
			return "Current consumed generation must retain whole retirement with no resurrected sample"
	return ""


func _capture_pair_error(value: Dictionary, actor: Dictionary) -> String:
	var reader = Capture.new()
	var epoch: String = "" if value.get("generation") == 0 else _epoch
	var clock: float = 0.0 if epoch.is_empty() else float(actor.world_actions.clock_s)
	var error: String = reader.snapshot_error(value, epoch, clock)
	if not error.is_empty():
		return error
	if int(value.generation) == 0:
		return ""
	if int(value.cursor) > int(actor.world_actions.sequence) or (value.armed and int(value.cursor) != int(actor.world_actions.sequence)):
		return "Capture cursor must match the same actual source publication stream"
	var history: Dictionary = {}
	for record: Dictionary in actor.world_actions.history:
		history[int(record.sequence)] = record
	var records: Array = []
	for collection: String in ["slots", "pending"]:
		for slot: Dictionary in value[collection]:
			for key: String in ["dash", "primary", "blast"]:
				if not slot[key].is_empty():
					records.append(slot[key])
	if not value.dash_candidate.is_empty():
		records.append(value.dash_candidate)
	for record: Dictionary in records:
		if not history.has(int(record.sequence)) or not _same(record, history[int(record.sequence)]):
			return "Unretired samples require exact authoritative saved-player history; rolled-off/reconstructed records reject"
	return ""


func _complete_error(value: Dictionary, retired: int = -1) -> String:
	var watermark: int = _retired_generation if retired < 0 else retired
	if value.is_empty() or int(value.generation) <= watermark or not value.armed or not Codec.is_integer(value.max_slots, 1, 2) or int(value.allocated) != int(value.max_slots) or value.slots.size() != int(value.max_slots) or not value.retired.is_empty() or not value.pending.is_empty() or not value.dash_candidate.is_empty():
		return "Complete current one/two-slot sealed unretired generation required; no FIFO subset"
	return ""


func _sequence_error(value: Dictionary) -> String:
	if not Codec.is_integer(value.get("generation"), 1):
		return "Malformed consumed/prepared sequence generation"
	var reader = Sequence.new()
	var error: String = reader.snapshot_error(value, _epoch, int(value.generation))
	if not error.is_empty():
		return error
	var authored: Dictionary = value.authored.duplicate(true)
	authored.tether_position = Codec.read_vector3(authored.tether_position)
	var canonical = Sequence.new()
	if not canonical.configure(value.sequence_id, value.capture_snapshot, authored, _epoch, int(value.generation)) or not _same(canonical.snapshot_state(), value):
		return "Sequence must derive exactly from unchanged original captured records"
	return ""


func _capture_copy():
	var value: Dictionary = _capture.snapshot_state()
	if value.is_empty():
		return null
	var staged = Capture.new()
	return staged if staged.restore_state(value, String(value.source_epoch), float(value.clock_s)) else null


func _barrier(stable: bool) -> Dictionary:
	last_error = _access_error()
	if not last_error.is_empty():
		return {}
	var actor: CinderPlayer = _player()
	var actual: Dictionary = actor.snapshot_state()
	if actual.is_empty():
		last_error = "Deferred actor barrier required: " + actor.last_snapshot_error
		return {}
	if stable:
		var response: Dictionary = actor.get_threat_response_state()
		if not response.stable or float(response.commitment_remaining_s) != 0.0 or not String(response.pending_weapon_id).is_empty():
			last_error = "Living grounded stopped actor with no pending motion/commitment/gear required"
			return {}
	return actual


func _access_error() -> String:
	if _busy or not _live() or not get_tree().paused:
		return "Gate operations require a bound paused deferred barrier outside callbacks"
	return ""


func _player() -> CinderPlayer:
	return _actor.get_ref() as CinderPlayer if _actor != null else null


func _live() -> bool:
	var actor: CinderPlayer = _player()
	return not _epoch.is_empty() and is_inside_tree() and is_node_ready() and not is_queued_for_deletion() and is_instance_valid(actor) and actor.get_script() == Player and actor.is_inside_tree() and actor.is_node_ready() and not actor.is_queued_for_deletion() and actor.get_world_3d() == get_world_3d()


static func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = Exact.stringify(left)
	return not encoded.is_empty() and encoded == Exact.stringify(right)


static func _digest(value: Dictionary) -> String:
	var encoded: String = Exact.stringify(value)
	return encoded.sha256_text() if not encoded.is_empty() else ""


static func _sha256(value: Variant) -> bool:
	if not value is String or value.length() != 64:
		return false
	for character: String in value:
		if not "0123456789abcdef".contains(character):
			return false
	return true


static func _id(value: String) -> bool:
	if value.is_empty() or value.length() > 192:
		return false
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9_./:-]+$")
	var match: RegExMatch = pattern.search(value)
	return match != null and match.get_string() == value


func _reject(reason: String) -> bool:
	last_error = reason
	return false


func _exit_tree() -> void:
	var actor: CinderPlayer = _player()
	if is_instance_valid(actor) and actor.world_action_executed.is_connected(_on_actual_publication):
		actor.world_action_executed.disconnect(_on_actual_publication)
