class_name CinderThreatScheduler
extends Node3D
## Conservative supported-response witness, not a campaign fairness certificate.
## Root supplies exact live commitment/cooldown data and authored candidate swipes.
## We prove unobstructed full-distance dashes on immutable, unrotated box floors,
## then a stationary ordinary-primary opening. No blast, invulnerability tanking,
## dynamic floor or moving recovery target is assumed. Tracking warns unarmed
## until atomic reproof at lock; a straight real-body lunge reserves its entire
## collision-shortened swept lane and stationary endpoint recovery. Unsupported
## inputs reject. Candidate enumeration can false-reject ordinary valid play.
## Logical threat intersection is continuous in space/time; floor continuity is
## established analytically against actual solid floor boxes, not ray samples.
## Capsule casts still use the engine's numerical physics tolerances. Owners MUST
## cancel their attack on reservation_invalidated; world changes MUST invalidate
## the encounter before altering collision. Replay uses its own immutable complete
## sequence proof and exclusive lease; it never enters ordinary proxy geometry.
## Future unsupported adapters must supply proof rather than opt out of checks.

signal reservation_invalidated(reservation_id: String, reason: String)

const DifficultyScript = preload("res://scripts/combat/difficulty.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const BodySweep = preload("res://scripts/combat/body_sweep.gd")
const ReplaySequence = preload("res://scripts/combat/replay_sequence.gd")
const ReplayProgram = preload("res://scripts/combat/replay_program.gd")
const AuthoredSequence = preload("res://scripts/combat/authored_enemy_sequence.gd")
const ReplayWitness = preload("res://scripts/combat/replay_witness.gd")
const CycleReceipt = preload("res://scripts/combat/authored_echo_terminal_receipt.gd")
const CycleJournal = preload("res://scripts/combat/authored_echo_cycle_journal.gd")
const ReplayPlayer = preload("res://scripts/player.gd")
const PreviewExact = preload("res://scripts/campaign/exact_json.gd")
const API_REVISION: String = "threat-scheduler-4"
const LUNGE_PREVIEW_API_REVISION: String = "lunge-preview-1"
const STATIONARY_PREVIEW_API_REVISION: String = "stationary-preview-1"
const SNAPSHOT_API_REVISION: String = "scheduler-snapshot-1"
const SNAPSHOT_SCHEMA_VERSION: int = 1
const CAPSULE_RADIUS: float = 0.32
const CAPSULE_HEIGHT: float = 1.45
const CAPSULE_CENTER_Y: float = 0.73
const SKIN: float = 0.01
const FEET_TOLERANCE: float = 0.015
const EPSILON: float = 0.00001
const TIME_MARGIN: float = 0.001
const MAX_REPLAY_CANCELLATIONS: int = 32
const MANAGED_ORDINARY_ERROR: String = "Managed authored owners cannot bypass their journal with an ordinary attack"
const REPLAY_ADAPTER_KEYS: Array[String] = ["kind", "locked", "sequence", "source_epoch", "generation", "capture_collision_fingerprint", "timeline_origin_s", "max_dispatch_delay_s"]
const REPLAY_TOMBSTONE_KEYS: Array[String] = ["id", "source_id", "response_actor_id", "sequence_id", "source_epoch", "generation", "sequence", "capture_collision_fingerprint", "profile_id", "world_revision", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "timeline_origin_s", "locked", "max_dispatch_delay_s", "cancelled_at_s", "reason"]
const AUTHORED_ADAPTER_KEYS: Array[String] = ["kind", "locked", "sequence", "source_id", "source_epoch", "generation", "world_collision_fingerprint", "world_floor_signature", "timeline_origin_s", "max_dispatch_delay_s"]
const AUTHORED_TOMBSTONE_KEYS: Array[String] = ["kind", "id", "source_id", "response_actor_id", "sequence_id", "source_epoch", "generation", "sequence", "world_collision_fingerprint", "world_floor_signature", "profile_id", "world_revision", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "timeline_origin_s", "locked", "max_dispatch_delay_s", "cancelled_at_s", "reason"]

var last_error: String = ""
var last_snapshot_error: String = ""
var _difficulty = DifficultyScript.new()
var _profile: Dictionary = {}
var _encounter_id: String = ""
var _world_revision: int = 0
var _clock: float = 0.0
var _serial: int = 0
var _reservations: Dictionary = {}
var _cooldowns: Dictionary = {}
var _replay_cancellations: Dictionary = {}
var _boundary_busy: bool = false
var _snapshot_busy: bool = false
var _request_busy: bool = false
var _transaction_depth: int = 0
# Native-only custody/cache; wire contains only the pure six-key journal entries.
var _authored_cycles: Dictionary = {}
var _cycle_busy: bool = false
var _cycle_restore_capture_owner: WeakRef


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func begin_encounter(profile_id: String, encounter_id: String = "encounter", world_revision: int = 1) -> bool:
	last_error = ""
	if _snapshot_busy or _request_busy or _transaction_depth > 0 or _boundary_busy or _cycle_busy or not _authored_cycles.is_empty() or not _encounter_id.is_empty():
		last_error = "End the current encounter before applying another profile"
		return false
	var selected: Dictionary = _difficulty.profile(profile_id)
	if selected.is_empty() or encounter_id.is_empty() or world_revision < 1:
		last_error = "Known profile, stable encounter ID and positive world revision required"
		return false
	_profile = selected
	_encounter_id = encounter_id
	_world_revision = world_revision
	_clock = 0.0
	_reservations.clear()
	_cooldowns.clear()
	_replay_cancellations.clear()
	return true


func end_encounter(reason: String = "encounter_end") -> void:
	if _cycle_busy or not _authored_cycles.is_empty():
		last_error = "Managed authored history requires explicit whole-parent retirement/disposal; encounter reset is refused"
		return
	if _snapshot_busy or _request_busy or _transaction_depth > 0 or _boundary_busy:
		return
	_boundary_busy = true
	for reservation_id: String in _reservations.keys():
		cancel(reservation_id, reason)
	_cooldowns.clear()
	_replay_cancellations.clear()
	_profile.clear()
	_encounter_id = ""
	_boundary_busy = false


func encounter_profile() -> Dictionary:
	return _profile.duplicate(true)


func get_clock() -> float:
	return _clock


func request_attack(owner: Node3D, threat: Dictionary, response: Dictionary, preview: Dictionary = {}) -> Dictionary:
	if _snapshot_busy or _request_busy or _boundary_busy or _cycle_busy or _transaction_depth > 0:
		last_error = "Scheduler transaction is already in progress"
		return {"accepted": false, "reason": last_error}
	if not _cycle_for_owner(owner).is_empty(): return _rejected(MANAGED_ORDINARY_ERROR)
	if not preview.is_empty():
		# A framing preview grants no lease. Compare/reprove before cleanup so
		# stale copied data cannot cancel another source to manufacture admission.
		var current: Dictionary = _preview_stationary_current(owner, threat, response)
		if not current.get("accepted", false):
			return _rejected(current["reason"])
		if not _same_lunge_preview(preview, current):
			return _rejected("Stationary preview no longer matches exact current source/response/world/union")
		_request_busy = true
		_transaction_depth += 1
		_prune()
		current = _preview_stationary_current(owner, threat, response)
		var paired_result: Dictionary
		if not current.get("accepted", false):
			paired_result = _rejected(current["reason"])
		elif not _same_lunge_preview(preview, current):
			paired_result = _rejected("Stationary preview changed during ordinary reservation cleanup")
		else:
			paired_result = _commit_ordinary_attack(owner, current["candidate"], current["proof"], response)
		_transaction_depth -= 1
		_request_busy = false
		return paired_result
	_request_busy = true
	_transaction_depth += 1
	var result: Dictionary = _request_attack(owner, threat, response)
	_transaction_depth -= 1
	_request_busy = false
	return result


func _request_attack(owner: Node3D, threat: Dictionary, response: Dictionary, adapter: Dictionary = {}) -> Dictionary:
	if not _cycle_for_owner(owner).is_empty(): return _rejected(MANAGED_ORDINARY_ERROR)
	_prune()
	var prepared: Dictionary = _prepare_ordinary_attack(owner, threat, response, adapter)
	if not prepared.get("accepted", false):
		return _rejected(prepared["reason"])
	return _commit_ordinary_attack(owner, prepared["candidate"], prepared["proof"], response)


func _prepare_ordinary_attack(owner: Node3D, threat: Dictionary, response: Dictionary, adapter: Dictionary = {}) -> Dictionary:
	## Shared pure candidate/proof path. Cleanup and admission live outside it.
	if not _cycle_for_owner(owner).is_empty(): return {"accepted": false, "reason": MANAGED_ORDINARY_ERROR}
	var error: String = _request_error(owner, threat, response, "", adapter.get("kind") == "tracking")
	if not error.is_empty():
		return {"accepted": false, "reason": error}
	if adapter.get("kind") == "lunge" and (owner.global_position.distance_to(adapter["current_position"]) > EPSILON or not _lunge_source_valid(owner, adapter)):
		return {"accepted": false, "reason": "Lunge source plan changed during reservation cleanup"}
	if adapter.get("kind") == "tracking" and (not _tracking_geometry_valid(owner, threat["geometry"], adapter) or (threat["opening_position"] as Vector3).distance_to(owner.global_position) > EPSILON):
		return {"accepted": false, "reason": "Tracking source lane changed during reservation cleanup"}
	var role: Dictionary = threat["role"]
	var active_from: float = _clock + float(role["windup_s"])
	var active_until: float = active_from + float(role["active_s"])
	var recovery_until: float = active_until + float(role["recovery_s"])
	if not is_finite(recovery_until) or not is_finite(active_from + float(role["attack_interval_s"])):
		return {"accepted": false, "reason": "Committed deadlines must remain finite"}
	var budget: int = 0
	for existing: Dictionary in _reservations.values():
		if float(existing["active_until_s"]) >= _clock:
			budget += 1
			if absf(float(existing["active_from_s"]) - active_from) < float(_profile["commit_stagger_s"]) - EPSILON:
				return {"accepted": false, "reason": "Committed activations require a visible stagger"}
	if budget >= int(_profile["reserved_threat_budget"]):
		return {"accepted": false, "reason": "Preparing and active threat budget occupied"}
	var candidate: Dictionary = {
		"geometry": (threat["geometry"] as Dictionary).duplicate(true),
		"active_from_s": active_from, "active_until_s": active_until,
		"recovery_until_s": recovery_until,
		"opening_position": threat["opening_position"],
	}
	if not adapter.is_empty():
		candidate["adapter"] = adapter.duplicate(true)
	var proof: Dictionary = {"accepted": true, "proof_scope": "unarmed_tracking_warning"} if adapter.get("kind") == "tracking" else _prove(candidate, response)
	if not proof.get("accepted", false):
		return proof
	candidate["source_instance_id"] = owner.get_instance_id()
	candidate["source_position"] = owner.global_position
	candidate["start_s"] = _clock
	candidate["lock_from_s"] = active_from - float(role["lock_s"])
	candidate["cooldown_until_s"] = active_from + float(role["attack_interval_s"])
	candidate["profile_id"] = _profile["id"]
	candidate["world_revision"] = _world_revision
	return {"accepted": true, "candidate": candidate, "proof": proof}


func _commit_ordinary_attack(owner: Node3D, candidate: Dictionary, proof: Dictionary, response: Dictionary) -> Dictionary:
	if not _cycle_for_owner(owner).is_empty(): return _rejected(MANAGED_ORDINARY_ERROR)
	candidate = candidate.duplicate(true)
	_serial += 1
	var reservation_id: String = "threat-%d" % _serial
	candidate["id"] = reservation_id
	candidate["_owner"] = weakref(owner)
	candidate["_floor_guards"] = _floor_guards(response["floor_regions"])
	_reservations[reservation_id] = candidate
	_cooldowns[owner.get_instance_id()] = {"owner": weakref(owner), "ready_s": candidate["cooldown_until_s"]}
	last_error = ""
	return {"accepted": true, "reservation_id": reservation_id, "proof": proof.duplicate(true), "profile_id": _profile["id"], "armed": candidate.get("adapter", {}).get("kind") != "tracking", "reservation": _public_record(candidate)}


func request_authored_replay(owner: Node3D, sequence_snapshot: Dictionary, response: Dictionary, context: Dictionary) -> Dictionary:
	if _snapshot_busy or _request_busy or _boundary_busy or _cycle_busy or _transaction_depth > 0:
		return _rejected("Scheduler transaction is already in progress")
	_request_busy = true
	_transaction_depth += 1
	var result: Dictionary = _request_authored_replay(owner, sequence_snapshot, response, context)
	_transaction_depth -= 1
	_request_busy = false
	return result


func _request_authored_replay(owner: Node3D, sequence_snapshot: Dictionary, response: Dictionary, context: Dictionary) -> Dictionary:
	var cycle_error: String = _cycle_admission_error(owner, sequence_snapshot, response, context)
	if not cycle_error.is_empty(): return _rejected(cycle_error)
	if not response.get("floor_regions") is Array: return _rejected("Actual authored floor bindings required")
	var actor_value: Variant = response.get("actor")
	if typeof(actor_value) != TYPE_OBJECT or not is_instance_valid(actor_value) or not actor_value is CinderPlayer: return _rejected("Actual shared authored-response player required")
	var actor: CinderPlayer = actor_value
	var error: String = authored_replay_source_error(owner, sequence_snapshot, context, response.get("floor_regions", []))
	if error.is_empty(): error = _replay_context_error(owner, actor, _captured_context(context))
	if error.is_empty() and (not _reservations.is_empty() or _cooldowns.has(owner.get_instance_id())): error = "Authored replay requires an exclusive ready source"
	if error.is_empty() and _replay_cancellations.size() >= MAX_REPLAY_CANCELLATIONS: error = "Replay cancellation history is full"
	if not error.is_empty(): return _rejected(error)
	var proof: Dictionary = ReplayWitness.new().prove_authored(self, owner, sequence_snapshot, response, context)
	if not proof.get("accepted", false): return _rejected(proof.get("reason", "Authored replay preview was not proved"))
	var reader = ReplayProgram.new()
	if not reader.restore_state(sequence_snapshot, context.source_epoch, context.generation) or not reader.is_authored_enemy(): return _rejected("Distinct authored program required")
	var plan: Dictionary = reader.state()
	cycle_error = _cycle_admission_error(owner, sequence_snapshot, response, context)
	if not cycle_error.is_empty(): return _rejected(cycle_error)
	var adapter: Dictionary = {"kind": "authored_replay", "locked": false, "sequence": reader.snapshot_state(), "source_id": context.source_id, "source_epoch": context.source_epoch, "generation": context.generation, "world_collision_fingerprint": context.world_collision_fingerprint.duplicate(true), "world_floor_signature": context.world_floor_signature.duplicate(true), "timeline_origin_s": _clock, "max_dispatch_delay_s": ReplayWitness.MAX_DISPATCH_DELAY_S}
	var record: Dictionary = {"source_instance_id": owner.get_instance_id(), "response_actor_instance_id": actor.get_instance_id(), "source_position": owner.global_position, "opening_position": plan.authored.tether_position, "start_s": _clock, "profile_id": _profile.id, "world_revision": _world_revision, "adapter": adapter, "_owner": weakref(owner), "_floor_guards": _floor_guards(response.floor_regions), "_replay_world": weakref(context.world_root), "_replay_actor": weakref(actor), "_authored_source_script": owner.get_script()}
	_set_replay_deadlines(record, plan, _clock)
	_serial += 1
	record["id"] = "threat-%d" % _serial
	_reservations[record.id] = record
	_cooldowns[owner.get_instance_id()] = {"owner": weakref(owner), "ready_s": record.cooldown_until_s}
	_cycle_admitted(owner, record)
	last_error = ""
	return {"accepted": true, "reservation_id": record.id, "armed": false, "profile_id": _profile.id, "proof": proof, "reservation": _public_record(record)}


func commit_authored_replay(reservation_id: String, response: Dictionary) -> Dictionary:
	if _snapshot_busy or _request_busy or _boundary_busy or _cycle_busy or _transaction_depth > 0: return _rejected("Scheduler transaction is already in progress")
	_request_busy = true
	_transaction_depth += 1
	var record: Dictionary = _reservations.get(reservation_id, {})
	var result: Dictionary
	if not _is_authored_replay(record) or record.adapter.locked or not is_inside_tree() or get_tree().paused or _clock < float(record.lock_from_s):
		result = _rejected("Live due unarmed authored replay required")
	else:
		var error: String = replay_reservation_error(reservation_id)
		if error.is_empty() and response.get("actor") != replay_target(reservation_id): error = "Authored target changed"
		var proof: Dictionary = {}
		if error.is_empty():
			proof = ReplayWitness.new().prove_authored(self, (record._owner as WeakRef).get_ref(), record.adapter.sequence, response, _replay_context(record), true, reservation_id)
			if not proof.get("accepted", false): error = proof.get("reason", "Authored lock was not proved")
		if not error.is_empty():
			cancel(reservation_id, "authored_replay_lock_unproved")
			result = _rejected(error)
		else:
			var reader = ReplayProgram.new()
			reader.restore_state(record.adapter.sequence, record.adapter.source_epoch, record.adapter.generation)
			var plan: Dictionary = reader.state()
			var candidate: Dictionary = record.duplicate(true)
			candidate.adapter.locked = true
			candidate.adapter.timeline_origin_s = _clock - float(plan.authored.warning_s)
			_set_replay_deadlines(candidate, plan, candidate.adapter.timeline_origin_s)
			candidate.lock_from_s = _clock
			_reservations[reservation_id] = candidate
			_cycle_exchange_changed(candidate)
			_cooldowns[candidate.source_instance_id] = {"owner": candidate._owner, "ready_s": candidate.cooldown_until_s}
			last_error = ""
			result = {"accepted": true, "reservation_id": reservation_id, "armed": true, "profile_id": _profile.id, "proof": proof, "reservation": _public_record(candidate)}
	_transaction_depth -= 1
	_request_busy = false
	return result


func request_replay(owner: Node3D, sequence_snapshot: Dictionary, response: Dictionary, context: Dictionary) -> Dictionary:
	## Exclusive compound data; no ordinary circle/lane can stand in for a replay.
	## Request is pure until the complete proof succeeds. In particular no prune
	## callback can change another source while the witness is being evaluated.
	if _snapshot_busy or _request_busy or _boundary_busy or _cycle_busy or _transaction_depth > 0:
		return _rejected("Scheduler transaction is already in progress")
	_request_busy = true
	_transaction_depth += 1
	var result: Dictionary = _request_replay(owner, sequence_snapshot, response, context)
	_transaction_depth -= 1
	_request_busy = false
	return result


func _request_replay(owner: Node3D, sequence_snapshot: Dictionary, response: Dictionary, context: Dictionary) -> Dictionary:
	if not _cycle_for_owner(owner).is_empty(): return _rejected("Managed authored owners cannot bypass their journal with captured replay")
	var error: String = _replay_context_error(owner, response.get("actor") as CinderPlayer, context)
	if error.is_empty():
		error = replay_exchange_error(sequence_snapshot, context)
	if error.is_empty() and _cooldowns.has(owner.get_instance_id()):
		error = "Source attack cooldown is still occupied"
	if error.is_empty() and _replay_cancellations.size() >= MAX_REPLAY_CANCELLATIONS:
		error = "Replay cancellation history is full until simulation cooldowns expire"
	if not error.is_empty():
		return _rejected(error)
	var witness = ReplayWitness.new()
	var proof: Dictionary = witness.prove(self, sequence_snapshot, response, context)
	if not proof.get("accepted", false):
		return _rejected(proof.get("reason", "Replay preview was not proved"))
	var sequence = ReplaySequence.new()
	if not sequence.restore_state(sequence_snapshot, context.source_epoch, int(context.generation)):
		return _rejected(sequence.last_snapshot_error)
	var plan: Dictionary = sequence.state()
	if owner.global_position.distance_to(plan.authored.tether_position) > EPSILON:
		return _rejected("Actual stationary replay source must occupy its authored tether")
	var actor: CinderPlayer = response.actor
	var adapter := {"kind": "replay", "locked": false, "sequence": sequence.snapshot_state(), "source_epoch": context.source_epoch, "generation": int(context.generation), "capture_collision_fingerprint": context.capture_collision_fingerprint.duplicate(true), "timeline_origin_s": _clock, "max_dispatch_delay_s": ReplayWitness.MAX_DISPATCH_DELAY_S}
	var record := {"source_instance_id": owner.get_instance_id(), "response_actor_instance_id": actor.get_instance_id(), "source_position": owner.global_position, "opening_position": plan.authored.tether_position, "start_s": _clock, "profile_id": _profile.id, "world_revision": _world_revision, "adapter": adapter, "_owner": weakref(owner), "_floor_guards": _floor_guards(response.floor_regions), "_replay_world": weakref(context.world_root), "_replay_actor": weakref(actor)}
	_set_replay_deadlines(record, plan, _clock)
	_serial += 1
	var reservation_id: String = "threat-%d" % _serial
	record["id"] = reservation_id
	_reservations[reservation_id] = record
	_cooldowns[owner.get_instance_id()] = {"owner": weakref(owner), "ready_s": record.cooldown_until_s}
	last_error = ""
	return {"accepted": true, "reservation_id": reservation_id, "armed": false, "profile_id": _profile.id, "proof": proof, "reservation": _public_record(record)}


func commit_replay(reservation_id: String, response: Dictionary) -> Dictionary:
	if _snapshot_busy or _request_busy or _boundary_busy or _cycle_busy or _transaction_depth > 0:
		return _rejected("Scheduler transaction is already in progress")
	_request_busy = true
	_transaction_depth += 1
	var result: Dictionary = _commit_replay(reservation_id, response)
	_transaction_depth -= 1
	_request_busy = false
	return result


func _commit_replay(reservation_id: String, response: Dictionary) -> Dictionary:
	var record: Dictionary = _reservations.get(reservation_id, {})
	if not _is_replay(record) or _is_authored_replay(record) or record.adapter.locked:
		return _rejected("Live unarmed replay reservation required")
	if not is_inside_tree() or get_tree().paused or _clock < float(record.lock_from_s):
		return _rejected("Replay lock is not due in an unpaused encounter")
	var error: String = replay_reservation_error(reservation_id)
	if error.is_empty() and response.get("actor") != replay_target(reservation_id):
		error = "Replay response actor cannot change after preview"
	var proof: Dictionary = {}
	if error.is_empty():
		proof = ReplayWitness.new().prove(self, record.adapter.sequence, response, _replay_context(record), true, reservation_id)
		if not proof.get("accepted", false):
			error = proof.get("reason", "Replay lock was not proved")
	if not error.is_empty():
		cancel(reservation_id, "replay_lock_unproved")
		return _rejected(error)
	var sequence = ReplaySequence.new()
	sequence.restore_state(record.adapter.sequence, record.adapter.source_epoch, int(record.adapter.generation))
	var plan: Dictionary = sequence.state()
	# A delayed legal lock retains its FULL authored lead from this actual clock.
	var candidate: Dictionary = record.duplicate(true)
	candidate.adapter.locked = true
	candidate.adapter.timeline_origin_s = _clock - float(plan.authored.warning_s)
	_set_replay_deadlines(candidate, plan, candidate.adapter.timeline_origin_s)
	candidate["lock_from_s"] = _clock
	_reservations[reservation_id] = candidate
	_cooldowns[int(candidate.source_instance_id)] = {"owner": candidate._owner, "ready_s": candidate.cooldown_until_s}
	last_error = ""
	return {"accepted": true, "reservation_id": reservation_id, "armed": true, "profile_id": _profile.id, "proof": proof, "reservation": _public_record(candidate)}


func _set_replay_deadlines(record: Dictionary, plan: Dictionary, origin_s: float) -> void:
	var last_danger_s: float = float(plan.timeline.replay_until_s)
	for slot: Dictionary in plan.timeline.slots:
		for event: Dictionary in slot.events:
			last_danger_s = maxf(last_danger_s, float(event.at_s) + ReplayWitness.MAX_DISPATCH_DELAY_S + TIME_MARGIN)
	record["lock_from_s"] = origin_s + float(plan.authored.warning_s)
	record["active_from_s"] = origin_s + float(plan.timeline.playback_from_s)
	record["active_until_s"] = origin_s + last_danger_s
	record["recovery_until_s"] = origin_s + float(plan.timeline.tether_until_s)
	record["cooldown_until_s"] = origin_s + float(plan.timeline.source_ready_s) if _is_authored_replay(record) else record.recovery_until_s


func replay_exchange_error(sequence_snapshot: Dictionary, context: Dictionary, reservation_id: String = "") -> String:
	## Witness self-exclusion is exact, own, unarmed and alone; never a caller proof.
	if reservation_id.is_empty():
		return "Replay requires an exclusive exchange" if not _reservations.is_empty() else ""
	var record: Dictionary = _reservations.get(reservation_id, {})
	if _reservations.size() != 1 or not _is_replay(record) or record.adapter.locked:
		return "Only the exact own unarmed exclusive replay may be re-proved"
	if not _same_replay(record.adapter.sequence, sequence_snapshot) or not _same_replay_context(_replay_context(record), context):
		return "Replay self-exclusion sequence/context identity changed"
	return replay_reservation_error(reservation_id)


func replay_reservation_state(reservation_id: String) -> Dictionary:
	## Pure defensive accessor: no expiry/prune callbacks or clock advancement.
	return _public_record(_reservations[reservation_id]) if replay_reservation_error(reservation_id).is_empty() else {}


func replay_target(reservation_id: String) -> CinderPlayer:
	var record: Dictionary = _reservations.get(reservation_id, {})
	return (record.get("_replay_actor") as WeakRef).get_ref() as CinderPlayer if _is_replay(record) and record.get("_replay_actor") is WeakRef else null


func replay_world_root(reservation_id: String) -> Node3D:
	## Raw admitted world custody, including a lease whose pure guard now fails.
	var record: Dictionary = _reservations.get(reservation_id, {})
	return (record.get("_replay_world") as WeakRef).get_ref() as Node3D if _is_replay(record) and record.get("_replay_world") is WeakRef else null


func replay_reservation_error(reservation_id: String) -> String:
	var record: Dictionary = _reservations.get(reservation_id, {})
	if not _is_replay(record) or _encounter_id.is_empty() or record.profile_id != _profile.get("id") or record.world_revision != _world_revision or _reservations.size() != 1:
		return "Current exclusive replay lease required"
	if not is_finite(_clock) or _clock < 0.0 or _clock > ReplayWitness.MAX_CLOCK_S:
		return "Replay lease clock exceeds supported precision envelope"
	if _clock > float(record.recovery_until_s):
		return "Replay lease has expired"
	if not record.adapter.locked and _clock >= float(record.active_from_s):
		return "Replay locked lead was missed"
	var owner: Node3D = (record._owner as WeakRef).get_ref() as Node3D
	var actor: CinderPlayer = replay_target(reservation_id)
	var context: Dictionary = _replay_context(record)
	var error: String = _replay_context_error(owner, actor, _captured_context(context) if _is_authored_replay(record) else context)
	if error.is_empty() and _is_authored_replay(record):
		error = _cycle_live_lease_error(record)
		if not error.is_empty(): return error
		if owner.get_script() != record.get("_authored_source_script"): return "Authored source script changed"
		error = authored_replay_source_error(owner, record.adapter.sequence, context, _authored_regions(record))
	if not error.is_empty():
		return error
	if owner.global_position.distance_to(record.source_position) > EPSILON or not _guards_valid(record._floor_guards):
		return "Replay stationary source/floor contract changed"
	var collision: Dictionary = _collision_signature(context.world_root)
	if collision.has("error") or not (_authored_same(collision.get("signature", {}), record.adapter.world_collision_fingerprint) if _is_authored_replay(record) else _same_replay(collision.get("signature", {}), record.adapter.capture_collision_fingerprint)):
		return "Replay capture collision world changed"
	var cooldown: Dictionary = _cooldowns.get(int(record.source_instance_id), {})
	if cooldown.is_empty() or not (_authored_same(cooldown.get("ready_s"), record.cooldown_until_s) if _is_authored_replay(record) else _same_replay(cooldown.get("ready_s"), record.cooldown_until_s)):
		return "Replay retained cooldown no longer matches its lease"
	return ""


func _replay_context_error(owner: Node3D, actor: CinderPlayer, context: Dictionary) -> String:
	if not Codec.keys_error(context, ["world_root", "source_epoch", "generation", "capture_collision_fingerprint"]).is_empty():
		return "Exact replay world/epoch/generation/capture context required"
	var world_root: Node3D = context.get("world_root") as Node3D
	if not is_instance_valid(world_root) or not world_root.is_inside_tree() or world_root.is_queued_for_deletion() or world_root.get_world_3d() != get_world_3d() or not _under_root(self, world_root):
		return "Live same-world replay root containing scheduler required"
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion() or owner.get_world_3d() != get_world_3d() or not _under_root(owner, world_root) or not owner.global_position.is_finite():
		return "Live finite stationary replay owner under world root required"
	if owner is CharacterBody3D and (not (owner as CharacterBody3D).velocity.is_finite() or (owner as CharacterBody3D).velocity.length() > EPSILON):
		return "Replay owner must remain stationary"
	if not is_instance_valid(actor) or not actor.is_inside_tree() or actor.is_queued_for_deletion() or not _under_root(actor, world_root) or actor.get_world_3d() != get_world_3d():
		return "One actual shared replay player under world root required"
	if not actor.get_collision_exceptions().is_empty() or actor.get_platform_velocity().length() > EPSILON or actor.get_platform_angular_velocity().length() > EPSILON:
		return "Replay player must retain fixed-world collision without exceptions/carry"
	if not context.get("source_epoch") is String or not Codec.is_integer(context.get("generation"), 1) or not context.get("capture_collision_fingerprint") is Dictionary:
		return "Replay epoch/generation/capture fingerprint required"
	return ""


func _replay_context(record: Dictionary) -> Dictionary:
	if _is_authored_replay(record):
		return {"world_root": (record._replay_world as WeakRef).get_ref(), "source_id": record.adapter.source_id, "source_epoch": record.adapter.source_epoch, "generation": record.adapter.generation, "world_collision_fingerprint": record.adapter.world_collision_fingerprint.duplicate(true), "world_floor_signature": record.adapter.world_floor_signature.duplicate(true)}
	return {"world_root": (record._replay_world as WeakRef).get_ref(), "source_epoch": record.adapter.source_epoch, "generation": record.adapter.generation, "capture_collision_fingerprint": record.adapter.capture_collision_fingerprint.duplicate(true)}


func _same_replay_context(left: Dictionary, right: Dictionary) -> bool:
	if left.has("source_id"):
		return Codec.keys_error(right, ["world_root", "source_id", "source_epoch", "generation", "world_collision_fingerprint", "world_floor_signature"]).is_empty() and left.world_root == right.world_root and _authored_same(_closed_authored_context(left), _closed_authored_context(right))
	if not Codec.keys_error(right, ["world_root", "source_epoch", "generation", "capture_collision_fingerprint"]).is_empty():
		return false
	return left.world_root == right.world_root and left.source_epoch == right.source_epoch and _same_replay(left.generation, right.generation) and _same_replay(left.capture_collision_fingerprint, right.capture_collision_fingerprint)


func _is_replay(record: Dictionary) -> bool:
	return record.get("adapter") is Dictionary and record.adapter.get("kind") in ["replay", "authored_replay"]


func _is_authored_replay(record: Dictionary) -> bool:
	return record.get("adapter") is Dictionary and record.adapter.get("kind") == "authored_replay"


func _closed_authored_context(context: Dictionary) -> Dictionary:
	var value: Dictionary = context.duplicate()
	value.erase("world_root")
	return value


func _captured_context(context: Dictionary) -> Dictionary:
	# Internal reuse of the existing actual-owner/Hero/world guard only. This
	# never constructs a captured program or publishes captured provenance.
	return {"world_root": context.get("world_root"), "source_epoch": context.get("source_epoch"), "generation": context.get("generation"), "capture_collision_fingerprint": context.get("world_collision_fingerprint")}


func _authored_same(left: Variant, right: Variant) -> bool:
	var wire: String = PreviewExact.stringify(left)
	return not wire.is_empty() and wire == PreviewExact.stringify(right)


func _authored_regions(record: Dictionary) -> Array:
	var regions: Array = []
	for guard: Dictionary in record.get("_floor_guards", []):
		var collision: Variant = (guard.node as WeakRef).get_ref()
		if not is_instance_valid(collision) or not collision is CollisionShape3D: return []
		regions.append({"collision": collision, "safe_rect": guard.safe_rect})
	return regions


func _authored_owner_script(owner: Node3D) -> Script:
	# The actual lease owner is the shared Playback or its C52 subclass. Avoid
	# a cyclic Scheduler -> Playback preload while rejecting duck-typed Nodes.
	var actual: Script = owner.get_script() as Script
	var ancestor: Script = actual
	while ancestor != null:
		if ancestor.resource_path == "res://scripts/combat/replay_playback.gd": return actual
		ancestor = ancestor.get_base_script()
	return null


func authored_replay_source_error(owner: Node3D, sequence_snapshot: Dictionary, context: Dictionary, floor_regions: Array, expected_profile_id: String = "", expected_world_revision: int = 0, staged_binding: Dictionary = {}, allow_defeated: bool = false) -> String:
	## Pure retained source/world proof. Staged values are permitted only in
	## whole-unit paused prevalidation after the parent's complete actor proof;
	## actual immutable source definition is always queried and compared.
	if not Codec.keys_error(context, ["world_root", "source_id", "source_epoch", "generation", "world_collision_fingerprint", "world_floor_signature"]).is_empty() or PreviewExact.stringify(_closed_authored_context(context)).is_empty():
		return "Closed exact authored source/world context required"
	if not _stable_id(context.source_id) or not _stable_id(context.source_epoch) or not context.generation is int or not Codec.is_integer(context.generation, 1) or not context.world_collision_fingerprint is Dictionary or not context.world_floor_signature is Array: return "Typed authored source/world identity required"
	if not is_instance_valid(owner) or not owner.is_inside_tree() or not owner.is_node_ready() or owner.is_queued_for_deletion() or not owner.has_method("get_authored_echo_binding") or not owner.has_method("configure_authored"):
		return "Actual ready authored Playback/C52 lease owner required"
	var actual_script: Script = _authored_owner_script(owner)
	if actual_script == null: return "Actual authored source must inherit shared Playback"
	var root_value: Variant = context.world_root
	if typeof(root_value) != TYPE_OBJECT or not is_instance_valid(root_value) or not root_value is Node3D: return "Actual authored world root required"
	var world_root: Node3D = root_value
	if not world_root.is_inside_tree() or world_root.is_queued_for_deletion() or owner.get_world_3d() != get_world_3d() or world_root.get_world_3d() != get_world_3d() or not _under_root(owner, world_root) or not _under_root(self, world_root): return "Authored owner/Scheduler must share the complete actual world"
	if PreviewExact.stringify(sequence_snapshot).is_empty(): return "Bounded exact authored program required"
	var reader = ReplayProgram.new()
	if not reader._restore_authored_for_source_guard(sequence_snapshot, context.source_epoch, context.generation) or not reader.is_authored_enemy(): return "Distinct immutable authored enemy program required"
	var plan: Dictionary = reader.state()
	var native: Variant = owner.call("get_authored_echo_binding")
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion() or owner.get_script() != actual_script or not native is Dictionary or not Codec.keys_error(native, ["api_revision", "source_id", "source_epoch", "generation", "definition", "alive", "knot_position"]).is_empty() or native.api_revision != "authored-echo-source-1" or not native.source_id is String or not native.source_epoch is String or not native.generation is int or not Codec.is_integer(native.generation, 0) or not native.definition is Dictionary or not native.alive is bool or not native.knot_position is Vector3 or not native.knot_position.is_finite(): return "Actual pure authored source binding rejected"
	var selected: Dictionary = native
	if not staged_binding.is_empty():
		if not get_tree().paused or not Codec.keys_error(staged_binding, ["api_revision", "source_id", "source_epoch", "generation", "definition", "alive", "knot_position"]).is_empty() or staged_binding.api_revision != "authored-echo-source-1" or not staged_binding.definition is Dictionary or not staged_binding.alive is bool or not staged_binding.knot_position is Vector3 or not staged_binding.knot_position.is_finite(): return "Validated paused original actor binding required for staging"
		selected = staged_binding
	if (not selected.alive and not allow_defeated) or selected.source_id != context.source_id or native.source_id != context.source_id or selected.source_epoch != context.source_epoch or not _authored_same(selected.generation, context.generation) or plan.source_id != context.source_id: return "Actual/staged living source cycle identity differs"
	if not _authored_same(Codec.vector3(selected.knot_position), Codec.vector3(plan.authored.tether_position)): return "Fixed authored knot differs from the immutable endpoint"
	if staged_binding.is_empty() and (not _authored_same(Codec.vector3(owner.global_position), Codec.vector3(selected.knot_position)) or (owner is CharacterBody3D and (owner as CharacterBody3D).velocity != Vector3.ZERO)): return "Authored physical owner must remain stationary at its exact knot"
	var floor: Dictionary = authored_floor_signature(world_root, floor_regions)
	var collision: Dictionary = pure_collision_fingerprint(world_root)
	if not floor.get("accepted", false) or collision.is_empty() or not _authored_same(floor.signature, context.world_floor_signature) or not _authored_same(collision, context.world_collision_fingerprint): return "Actual authored floor/collision guards differ"
	var profile_id: String = _profile.get("id", "") if expected_profile_id.is_empty() else expected_profile_id
	var revision: int = _world_revision if expected_world_revision == 0 else expected_world_revision
	var world: Dictionary = {"world_revision": revision, "collision_fingerprint": collision, "floor_signature": floor.signature}
	# Reuse only this call's fresh private Program validation. The reader checks
	# its exact current wire/epoch/generation and freshly reads catalogue bytes
	# HERE, after every original native getter/resource/world guard above.
	# Any mismatch executes the old full binding validator at this same point.
	return reader._authored_binding_error_for_source_guard(sequence_snapshot, context.source_id, context.source_epoch, context.generation, profile_id, native.definition, world, staged_binding)


func authored_floor_signature(world_root: Node3D, floor_regions: Array) -> Dictionary:
	## Same bounded canonical descriptor as ReplayFootprint.floor_signature.
	## Kept here to avoid Scheduler -> Footprint -> Scheduler preload recursion.
	if not is_instance_valid(world_root) or not world_root.is_inside_tree() or world_root.is_queued_for_deletion() or floor_regions.is_empty() or floor_regions.size() > 32: return {"accepted": false, "reason": "One to 32 live authored floor boxes required"}
	var signatures: Array = []
	var top_y: float = INF
	for region: Variant in floor_regions:
		if not region is Dictionary or not region.get("safe_rect") is Rect2: return {"accepted": false, "reason": "Actual floor domain required"}
		var value: Variant = region.get("collision")
		if typeof(value) != TYPE_OBJECT or not is_instance_valid(value) or not value is CollisionShape3D: return {"accepted": false, "reason": "Actual floor collision required"}
		var collision: CollisionShape3D = value
		if not collision.is_inside_tree() or collision.is_queued_for_deletion() or collision.disabled or not collision.shape is BoxShape3D or collision.global_basis != Basis.IDENTITY or not collision.get_parent() is StaticBody3D or collision.get_parent() is AnimatableBody3D: return {"accepted": false, "reason": "Unscaled static floor Box required"}
		var body: StaticBody3D = collision.get_parent()
		if not body.is_inside_tree() or body.is_queued_for_deletion() or not _under_root(body, world_root) or body.get_world_3d() != world_root.get_world_3d() or (body.collision_layer & 1) == 0 or body.constant_linear_velocity != Vector3.ZERO or body.constant_angular_velocity != Vector3.ZERO: return {"accepted": false, "reason": "Immutable actual same-world scenery floor required"}
		var count: int = 0
		for owner_id: int in body.get_shape_owners():
			if not body.is_shape_owner_disabled(owner_id): count += body.shape_owner_get_shape_count(owner_id)
		if count != 1: return {"accepted": false, "reason": "One enabled actual floor shape required"}
		var size: Vector3 = (collision.shape as BoxShape3D).size
		var position: Vector3 = collision.global_position
		var rect: Rect2 = region.safe_rect
		if not size.is_finite() or not position.is_finite() or maxf(absf(position.x), maxf(absf(position.y), absf(position.z))) > 512.0 or maxf(size.x, maxf(size.y, size.z)) > 512.0 or size.x <= 0.0 or size.y <= 0.0 or size.z <= 0.0 or not rect.position.is_finite() or not rect.size.is_finite() or rect.size.x <= 0.0 or rect.size.y <= 0.0: return {"accepted": false, "reason": "Bounded positive floor dimensions required"}
		var actual := Rect2(Vector2(position.x - size.x * 0.5, position.z - size.z * 0.5), Vector2(size.x, size.z))
		if not actual.encloses(rect) or maxf(absf(rect.position.x), absf(rect.position.y)) > 512.0 or maxf(absf(rect.end.x), absf(rect.end.y)) > 512.0: return {"accepted": false, "reason": "Authored domain must fit actual floor Box"}
		var top: float = position.y + size.y * 0.5
		if is_finite(top_y) and top != top_y: return {"accepted": false, "reason": "Exactly coplanar authored floors required"}
		top_y = top
		var body_path: String = String(world_root.get_path_to(body))
		var shape_path: String = String(body.get_path_to(collision))
		if not _authored_floor_path(body_path) or not _authored_floor_path(shape_path): return {"accepted": false, "reason": "Stable floor paths required"}
		signatures.append({"body_path": body_path, "shape_path": shape_path, "safe_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "top_y": top})
	signatures.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return PreviewExact.stringify(a) < PreviewExact.stringify(b))
	return {"accepted": true, "signature": signatures}


func _authored_floor_path(path: String) -> bool:
	return not path.is_empty() and not path.contains("@") and not path.contains("\n") and not path.contains("\r")


func _same_replay(left: Variant, right: Variant) -> bool:
	# Full-precision JSON can change int representation, never transport identity.
	if Codec.is_number(left) and Codec.is_number(right):
		return float(left) == float(right)
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size():
			return false
		for key: String in left:
			if not right.has(key) or not _same_replay(left[key], right[key]):
				return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size():
			return false
		for index: int in range(left.size()):
			if not _same_replay(left[index], right[index]):
				return false
		return true
	return typeof(left) == typeof(right) and left == right


func replay_cancellation_state(reservation_id: String, bindings: Dictionary = {}) -> Dictionary:
	## Retained tombstone is inert history. Reads never age or emit callbacks.
	var value: Dictionary = _replay_cancellations.get(reservation_id, {})
	if value.is_empty() or _clock >= float(value.cooldown_until_s):
		return {}
	var result: Dictionary = value.duplicate(true)
	result.erase("_owner")
	result.erase("_replay_actor")
	result.erase("_authored_source_script")
	if bindings.is_empty():
		return result
	if not _snapshot_access_error().is_empty() or not _bindings_error(bindings).is_empty() or not _replay_actor_binding_error(_binding_id(bindings.get("actors", {}), (value._replay_actor as WeakRef).get_ref()), bindings).is_empty():
		return {}
	return _encode_replay_tombstone(value, bindings)


func _encode_replay_tombstone(value: Dictionary, bindings: Dictionary) -> Dictionary:
	if not bindings.get("owners") is Dictionary or not bindings.get("actors") is Dictionary:
		return {}
	var result: Dictionary = value.duplicate(true)
	result.erase("_owner")
	result.erase("_replay_actor")
	result.erase("_authored_source_script")
	var source_id: String = _binding_id(bindings.owners, (value._owner as WeakRef).get_ref())
	var actor_id: String = _binding_id(bindings.actors, (value._replay_actor as WeakRef).get_ref())
	if source_id.is_empty() or actor_id.is_empty():
		return {}
	if value.get("kind") == "authored_replay" and source_id != value.source_id:
		return {}
	result.erase("source_instance_id")
	result.erase("response_actor_instance_id")
	result["source_id"] = source_id
	result["response_actor_id"] = actor_id
	return result


func _retain_replay_cancellation(record: Dictionary, reason: String) -> void:
	var adapter: Dictionary = record.adapter
	var value := {"id": record.id, "source_instance_id": record.source_instance_id, "response_actor_instance_id": record.response_actor_instance_id, "sequence_id": adapter.sequence.sequence_id, "source_epoch": adapter.source_epoch, "generation": adapter.generation, "sequence": adapter.sequence.duplicate(true), "capture_collision_fingerprint": (adapter.world_collision_fingerprint if _is_authored_replay(record) else adapter.capture_collision_fingerprint).duplicate(true), "timeline_origin_s": adapter.timeline_origin_s, "locked": adapter.locked, "max_dispatch_delay_s": adapter.max_dispatch_delay_s, "cancelled_at_s": _clock, "reason": reason.left(512), "_owner": record._owner, "_replay_actor": record._replay_actor}
	if _is_authored_replay(record):
		value.erase("capture_collision_fingerprint")
		value["kind"] = "authored_replay"
		value["source_id"] = adapter.source_id
		value["world_collision_fingerprint"] = adapter.world_collision_fingerprint.duplicate(true)
		value["world_floor_signature"] = adapter.world_floor_signature.duplicate(true)
		value["_authored_source_script"] = record._authored_source_script
	for key: String in ["profile_id", "world_revision", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		value[key] = record[key]
	_replay_cancellations[record.id] = value


func _expire_replay_cancellations() -> void:
	# Called only after a real pausable simulation tick, never read/prune/snapshot.
	for reservation_id: String in _replay_cancellations.keys():
		if _clock >= float(_replay_cancellations[reservation_id].cooldown_until_s):
			_replay_cancellations.erase(reservation_id)


func request_tracking(owner: Node3D, threat: Dictionary, response: Dictionary) -> Dictionary:
	## source-anchored capsule lane rotates during warning, never activates itself.
	## Caller consumes returned scheduler deadlines, then supplies fresh live
	## player response at commit_tracking. A failed proof cancels the tell.
	if _snapshot_busy or _request_busy or _boundary_busy or _cycle_busy or _transaction_depth > 0:
		return _rejected("Scheduler transaction is already in progress")
	if not _cycle_for_owner(owner).is_empty(): return _rejected(MANAGED_ORDINARY_ERROR)
	if not threat.get("geometry") is Dictionary or not _tracking_geometry_valid(owner, threat["geometry"]) or not Geometry.finite_vector(threat.get("opening_position")) or (threat["opening_position"] as Vector3).distance_to(owner.global_position) > EPSILON:
		return _rejected("Tracking requires a finite source-anchored capsule lane")
	var role: Variant = threat.get("role")
	if not role is Dictionary:
		return _rejected("Resolved tracking role required")
	var geometry: Dictionary = threat["geometry"]
	var adapter := {"kind": "tracking", "locked": false, "reach": (geometry["to"] as Vector3).distance_to(geometry["from"]), "radius": geometry["radius"], "lock_s": role.get("lock_s"), "active_s": role.get("active_s"), "recovery_s": role.get("recovery_s"), "attack_interval_s": role.get("attack_interval_s")}
	_request_busy = true
	_transaction_depth += 1
	var result: Dictionary = _request_attack(owner, threat, response, adapter)
	_transaction_depth -= 1
	_request_busy = false
	return result


func update_tracking(reservation_id: String, geometry: Dictionary) -> Dictionary:
	if _snapshot_busy or _request_busy or _boundary_busy or _cycle_busy or _transaction_depth > 0 or not is_inside_tree() or get_tree().paused:
		return _rejected("Unpaused scheduler callback barrier required")
	_prune()
	var record: Dictionary = _reservations.get(reservation_id, {})
	if record.is_empty() or record.get("adapter", {}).get("kind") != "tracking" or record["adapter"]["locked"] or _clock >= float(record["lock_from_s"]):
		return _rejected("Tracking preview may change only before lock is due")
	var owner: Node3D = (record["_owner"] as WeakRef).get_ref() as Node3D
	if not _tracking_geometry_valid(owner, geometry, record["adapter"]):
		return _rejected("Tracking retarget may rotate its fixed source lane only")
	record["geometry"] = geometry.duplicate(true)
	return {"accepted": true, "armed": false, "reservation_id": reservation_id, "reservation": _public_record(record)}


func commit_tracking(reservation_id: String, geometry: Dictionary, response: Dictionary) -> Dictionary:
	if _snapshot_busy or _request_busy or _boundary_busy or _cycle_busy or _transaction_depth > 0:
		return _rejected("Scheduler transaction is already in progress")
	_request_busy = true
	_transaction_depth += 1
	var result: Dictionary = _commit_tracking(reservation_id, geometry, response)
	_transaction_depth -= 1
	_request_busy = false
	return result


func _commit_tracking(reservation_id: String, geometry: Dictionary, response: Dictionary) -> Dictionary:
	_prune()
	var record: Dictionary = _reservations.get(reservation_id, {})
	if record.is_empty() or record.get("adapter", {}).get("kind") != "tracking" or record["adapter"]["locked"]:
		return _rejected("Live unarmed tracking reservation required")
	if not is_inside_tree() or get_tree().paused or _clock < float(record["lock_from_s"]) - EPSILON:
		return _rejected("Tracking lock is not due in an unpaused encounter")
	var owner: Node3D = (record["_owner"] as WeakRef).get_ref() as Node3D
	var adapter: Dictionary = record["adapter"]
	if not _tracking_geometry_valid(owner, geometry, adapter):
		cancel(reservation_id, "tracking_lock_unproved")
		return _rejected("Tracking lock cannot change source, lane reach or radius")
	var role := {"difficulty_schema": 1, "difficulty_profile": _profile["id"], "windup_s": float(adapter["lock_s"]) + 1.0, "lock_s": adapter["lock_s"], "active_s": adapter["active_s"], "recovery_s": adapter["recovery_s"], "attack_interval_s": adapter["attack_interval_s"]}
	var threat := {"role": role, "geometry": geometry, "source_stationary": true, "opening_stationary": true, "opening_position": record["opening_position"], "cooldown_remaining_s": 0.0}
	last_error = _request_error(owner, threat, response, reservation_id)
	if not last_error.is_empty():
		cancel(reservation_id, "tracking_lock_unproved")
		return {"accepted": false, "reason": last_error}
	var candidate: Dictionary = record.duplicate(true)
	candidate["geometry"] = geometry.duplicate(true)
	candidate["lock_from_s"] = _clock
	candidate["active_from_s"] = _clock + float(adapter["lock_s"])
	candidate["active_until_s"] = float(candidate["active_from_s"]) + float(adapter["active_s"])
	candidate["recovery_until_s"] = float(candidate["active_until_s"]) + float(adapter["recovery_s"])
	candidate["cooldown_until_s"] = float(candidate["active_from_s"]) + float(adapter["attack_interval_s"])
	if not is_finite(candidate["recovery_until_s"]) or not is_finite(candidate["cooldown_until_s"]):
		cancel(reservation_id, "tracking_lock_unproved")
		return _rejected("Locked deadlines must remain finite")
	for other: Dictionary in _reservations.values():
		if other["id"] != reservation_id and float(other["active_until_s"]) >= _clock and absf(float(other["active_from_s"]) - float(candidate["active_from_s"])) < float(_profile["commit_stagger_s"]) - EPSILON:
			cancel(reservation_id, "tracking_lock_unproved")
			return _rejected("Retimed tracking lock lost its visible stagger")
	var proof: Dictionary = _prove(candidate, response, reservation_id)
	if not proof.get("accepted", false):
		cancel(reservation_id, "tracking_lock_unproved")
		last_error = proof["reason"]
		return proof
	candidate["adapter"]["locked"] = true
	candidate["_floor_guards"] = _floor_guards(response["floor_regions"])
	_reservations[reservation_id] = candidate
	_cooldowns[owner.get_instance_id()] = {"owner": weakref(owner), "ready_s": candidate["cooldown_until_s"]}
	return {"accepted": true, "armed": true, "reservation_id": reservation_id, "reservation": _public_record(candidate), "proof": proof, "profile_id": _profile["id"]}


func request_lunge(owner: CharacterBody3D, threat: Dictionary, response: Dictionary, preview: Dictionary = {}) -> Dictionary:
	## Scheduler leases real source motion until release/cancel. Its level script
	## must suspend approach/gravity/knockback and cancel(id) BEFORE any impulse.
	## Normal interruptions retain cooldown; cancel_owner is for death/removal.
	## Active damage is still level-owned and must consume reservation_state.
	if _snapshot_busy or _request_busy or _boundary_busy or _cycle_busy or _transaction_depth > 0:
		return _rejected("Scheduler transaction is already in progress")
	if not _cycle_for_owner(owner).is_empty(): return _rejected(MANAGED_ORDINARY_ERROR)
	if not preview.is_empty():
		# Preview grants no lease. Reprove against actual bodies/union/world and
		# compare all copied data exactly, both before and after ordinary cleanup.
		var current: Dictionary = _preview_lunge_current(owner, threat, response)
		if not current.get("accepted", false):
			return _rejected(current["reason"])
		if not _same_lunge_preview(preview, current):
			return _rejected("Lunge preview no longer matches exact current source/response/world/union")
		_request_busy = true
		_transaction_depth += 1
		_prune()
		current = _preview_lunge_current(owner, threat, response)
		var paired_result: Dictionary
		if not current.get("accepted", false):
			paired_result = _rejected(current["reason"])
		elif not _same_lunge_preview(preview, current):
			paired_result = _rejected("Lunge preview changed during ordinary reservation cleanup")
		else:
			paired_result = _commit_ordinary_attack(owner, current["candidate"], current["proof"], response)
		_transaction_depth -= 1
		_request_busy = false
		return paired_result
	var prepared: Dictionary = _prepare_lunge(owner, threat, response)
	if not prepared.get("accepted", false):
		return _rejected(prepared["reason"])
	_request_busy = true
	_transaction_depth += 1
	var result: Dictionary = _request_attack(owner, prepared["threat"], response, prepared["adapter"])
	_transaction_depth -= 1
	_request_busy = false
	return result


func _prepare_lunge(owner: CharacterBody3D, threat: Dictionary, response: Dictionary) -> Dictionary:
	## Pure measured plan shared by legacy admission and prospective preview.
	if threat.get("source_stationary") != false or threat.get("opening_stationary") != true or not threat.get("lunge") is Dictionary or not response.get("floor_regions") is Array:
		return {"accepted": false, "reason": "Explicit real-body lunge and authored floor proof required"}
	var plan: Dictionary = Motion.plan(owner, threat["lunge"], response["floor_regions"])
	if plan.has("error"):
		return {"accepted": false, "reason": plan["error"]}
	if not threat.get("role") is Dictionary or not Geometry.finite_number(threat["role"].get("active_s")) or float(threat["role"]["active_s"]) < float(plan["duration_s"]) - EPSILON:
		return {"accepted": false, "reason": "Active window must cover full resolved distance/speed even when collision shortens travel"}
	var adjusted_position: Vector3 = owner.global_position + Vector3.UP * (float(plan["foot_offset"]) - CAPSULE_CENTER_Y + CAPSULE_HEIGHT * 0.5)
	var floor_error: String = _floor_error(response["floor_regions"], adjusted_position)
	if not floor_error.is_empty() or not _floor_path_supported(plan["start"], plan["planned_endpoint"], response["floor_regions"], float(plan["source_radius"]) + SKIN):
		return {"accepted": false, "reason": "Actual lunge source lacks continuous supported floor: " + floor_error}
	var adapted: Dictionary = threat.duplicate(true)
	adapted["source_stationary"] = true # proof only: start fixed until active, recovery fixed at endpoint
	adapted["geometry"] = plan["geometry"]
	adapted["opening_position"] = plan["planned_endpoint"]
	var adapter: Dictionary = plan.duplicate(true)
	adapter.erase("geometry")
	adapter.erase("source_radius")
	adapter.erase("foot_offset")
	adapter["current_velocity"] = Vector3.ZERO
	return {"accepted": true, "plan": plan, "threat": adapted, "adapter": adapter}


func preview_lunge(owner: CharacterBody3D, threat: Dictionary, response: Dictionary) -> Dictionary:
	## Pure ephemeral framing data. No prune, flags, clocks, diagnostics, body
	## mutations, callbacks, serial allocation or cooldown/reservation admission.
	if _snapshot_busy or _request_busy or _boundary_busy or _cycle_busy or _transaction_depth > 0:
		return {"accepted": false, "reason": "Scheduler transaction is already in progress"}
	if not _cycle_for_owner(owner).is_empty(): return {"accepted": false, "reason": MANAGED_ORDINARY_ERROR}
	return _preview_lunge_current(owner, threat, response).duplicate(true)


func _preview_lunge_current(owner: CharacterBody3D, threat: Dictionary, response: Dictionary) -> Dictionary:
	var error: String = _preview_retained_error()
	if error.is_empty():
		error = _preview_response_error(owner, response)
	if not error.is_empty():
		return {"accepted": false, "reason": error}
	# Bound caller native values BEFORE any deep copy. Unsupported object data
	# or cyclic/oversized containers must fail without engine recursion errors.
	var authored_response: Dictionary = response.duplicate()
	for key: String in ["actor", "world_root", "floor_regions"]:
		authored_response.erase(key)
	if _lunge_preview_wire(threat).is_empty() or _lunge_preview_wire(authored_response).is_empty():
		return {"accepted": false, "reason": "Finite bounded native threat/response values required"}
	var lunge: Dictionary = _prepare_lunge(owner, threat, response)
	if not lunge.get("accepted", false):
		return {"accepted": false, "reason": lunge["reason"]}
	var prepared: Dictionary = _prepare_ordinary_attack(owner, lunge["threat"], response, lunge["adapter"])
	if not prepared.get("accepted", false):
		return prepared
	var guarded: Dictionary = _preview_guard(owner, threat, response, lunge["plan"]["body_collision_path"])
	if guarded.has("error"):
		return {"accepted": false, "reason": guarded["error"]}
	var result := {"accepted": true, "reason": "", "api_revision": LUNGE_PREVIEW_API_REVISION, "plan": lunge["plan"].duplicate(true), "candidate": prepared["candidate"].duplicate(true), "proof": prepared["proof"].duplicate(true), "guard": guarded["guard"]}
	if _lunge_preview_wire(result).is_empty():
		return {"accepted": false, "reason": "Preview exceeds bounded supported native data"}
	return result


func preview_stationary(owner: Node3D, threat: Dictionary, response: Dictionary) -> Dictionary:
	## Pure ephemeral actual stationary-source proof/framing data. No cleanup,
	## clocks, flags, diagnostics, callbacks, motion, serial or lease allocation.
	if _snapshot_busy or _request_busy or _boundary_busy or _cycle_busy or _transaction_depth > 0:
		return {"accepted": false, "reason": "Scheduler transaction is already in progress"}
	if not _cycle_for_owner(owner).is_empty(): return {"accepted": false, "reason": MANAGED_ORDINARY_ERROR}
	return _preview_stationary_current(owner, threat, response).duplicate(true)


func _preview_stationary_current(owner: Node3D, threat: Dictionary, response: Dictionary) -> Dictionary:
	var error: String = _preview_retained_error()
	if error.is_empty():
		error = _preview_response_error(owner, response)
	if not error.is_empty():
		return {"accepted": false, "reason": error}
	var authored_response: Dictionary = response.duplicate()
	for key: String in ["actor", "world_root", "floor_regions"]:
		authored_response.erase(key)
	# Bound native caller values before geometry/candidate copies, including
	# cyclic/object input that cannot enter an exact ephemeral identity.
	if _lunge_preview_wire(threat).is_empty() or _lunge_preview_wire(authored_response).is_empty():
		return {"accepted": false, "reason": "Finite bounded native threat/response values required"}
	error = _stationary_preview_source_error(owner, threat)
	if not error.is_empty():
		return {"accepted": false, "reason": error}
	var prepared: Dictionary = _prepare_ordinary_attack(owner, threat, response)
	if not prepared.get("accepted", false):
		return prepared
	var guarded: Dictionary = _preview_guard(owner, threat, response)
	if guarded.has("error"):
		return {"accepted": false, "reason": guarded["error"]}
	var result := {"accepted": true, "reason": "", "api_revision": STATIONARY_PREVIEW_API_REVISION, "candidate": prepared["candidate"].duplicate(true), "proof": prepared["proof"].duplicate(true), "guard": guarded["guard"]}
	if _lunge_preview_wire(result).is_empty():
		return {"accepted": false, "reason": "Preview exceeds bounded supported native data"}
	return result


func _stationary_preview_source_error(owner: Node3D, threat: Dictionary) -> String:
	if threat.get("source_stationary") != true or threat.get("opening_stationary") != true:
		return "Preview requires an actual stationary source and recovery opening"
	if not threat.get("geometry") is Dictionary or not Geometry.error(threat["geometry"]).is_empty():
		return "Authoritative supported stationary threat geometry required"
	var geometry: Dictionary = threat["geometry"]
	var origin: Vector3 = geometry["from"] if geometry["kind"] == "lane" else geometry["origin"]
	if origin.distance_to(owner.global_position) > EPSILON:
		return "Stationary geometry origin/from must use the actual source position"
	if owner is CharacterBody3D:
		if (owner as CharacterBody3D).velocity != Vector3.ZERO:
			return "Moving native source cannot obtain a stationary preview"
	elif owner is PhysicsBody3D:
		if not owner is StaticBody3D or owner is AnimatableBody3D or (owner as StaticBody3D).constant_linear_velocity != Vector3.ZERO or (owner as StaticBody3D).constant_angular_velocity != Vector3.ZERO:
			return "Unsupported moving physics source cannot obtain a stationary preview"
	return ""


func _preview_guard(owner: Node3D, threat: Dictionary, response: Dictionary, source_collision_path: String = "") -> Dictionary:
	## Common exact native custody/world/retained-union framing guard. Callers
	## have already bounded threat/authored-response before any deep copy.
	var world_root: Node3D = response["world_root"]
	var collision: Dictionary = _collision_signature(world_root)
	if collision.has("error"):
		return {"error": collision["error"]}
	var authored_response: Dictionary = response.duplicate()
	for key: String in ["actor", "world_root", "floor_regions"]:
		authored_response.erase(key)
	authored_response = authored_response.duplicate(true)
	var floors: Array[Dictionary] = []
	for region: Dictionary in response["floor_regions"]:
		var floor_collision: CollisionShape3D = region["collision"]
		if not _under_root(floor_collision, world_root):
			return {"error": "Every authored preview floor must belong to world_root"}
		floors.append({"node_instance_id": str(floor_collision.get_instance_id()), "shape_instance_id": str(floor_collision.shape.get_instance_id()), "body_instance_id": str(floor_collision.get_parent().get_instance_id()), "signature": _floor_signature(region, world_root)})
	var retained: Array[Dictionary] = []
	var source_paths: Dictionary = {}
	var ids: Array = _reservations.keys()
	ids.sort()
	for reservation_id: String in ids:
		var record: Dictionary = _reservations[reservation_id]
		var source: Node3D = (record["_owner"] as WeakRef).get_ref() as Node3D
		var collision_path: String = String(record.get("adapter", {}).get("body_collision_path", ""))
		source_paths[source.get_instance_id()] = collision_path
		var retained_source: Dictionary = _preview_body_state(source, collision_path)
		if retained_source.has("error"):
			return {"error": retained_source["error"]}
		retained.append({"record": _public_record(record), "actual_source": retained_source})
	var cooldowns: Array[Dictionary] = []
	ids = _cooldowns.keys()
	ids.sort()
	for instance_id: int in ids:
		var entry: Dictionary = _cooldowns[instance_id]
		var cooldown_source: Dictionary = _preview_body_state((entry["owner"] as WeakRef).get_ref() as Node3D, String(source_paths.get(instance_id, "")))
		if cooldown_source.has("error"):
			return {"error": cooldown_source["error"]}
		cooldowns.append({"instance_id": instance_id, "ready_s": entry["ready_s"], "actual_source": cooldown_source})
	var actor: CinderPlayer = response["actor"]
	var actual_source: Dictionary = _preview_body_state(owner, source_collision_path)
	var actual_actor: Dictionary = _preview_body_state(actor, "BodyCollision")
	if actual_source.has("error") or actual_actor.has("error"):
		return {"error": actual_source.get("error", actual_actor.get("error", "Unsupported actual preview body"))}
	var guard := {"scheduler_instance_id": get_instance_id(), "owner_instance_id": owner.get_instance_id(), "actor_instance_id": actor.get_instance_id(), "world_root_instance_id": world_root.get_instance_id(), "clock_s": _clock, "serial": _serial, "encounter_id": _encounter_id, "profile": _profile.duplicate(true), "world_revision": _world_revision, "source": actual_source, "actor": actual_actor, "threat": threat.duplicate(true), "response": authored_response, "floor_bindings": floors, "collision_fingerprint": collision["signature"], "retained_union": retained, "cooldowns": cooldowns}
	return {"guard": guard}


func _preview_response_error(owner: Node3D, response: Dictionary) -> String:
	var error: String = response_error(response)
	if not error.is_empty():
		return error
	var actor: CinderPlayer = response.get("actor") as CinderPlayer
	var world_root: Node3D = response.get("world_root") as Node3D
	if not is_instance_valid(actor) or actor.get_script() != ReplayPlayer or not is_instance_valid(world_root) or not world_root.is_inside_tree() or world_root.is_queued_for_deletion() or world_root.get_world_3d() != get_world_3d() or not _under_root(self, world_root) or not _under_root(actor, world_root) or not is_instance_valid(owner) or not _under_root(owner, world_root):
		return "Preview requires actual shared Player and explicit containing same-world world_root"
	var description: Dictionary = BodySweep.source_description(actor)
	if description.has("error"):
		return "Unsupported actual preview Hero body: " + String(description["error"])
	var live: Dictionary = actor.get_threat_response_state()
	for key: String in live:
		if key == "actor":
			if response.get(key) != actor:
				return "Preview must retain the actual response actor"
		elif not response.has(key) or not _same_lunge_preview(response[key], live[key]):
			return "Preview response differs from actual public actor state: " + key
	return ""


func _preview_retained_error() -> String:
	## Conservative read-only equivalent of cleanup conditions. Stale retained
	## state rejects instead of creating an opportunity by firing cancellation.
	for record: Dictionary in _reservations.values():
		var owner: Node3D = (record["_owner"] as WeakRef).get_ref() as Node3D
		if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion() or owner.global_position.distance_to(record["source_position"]) > EPSILON or not _guards_valid(record["_floor_guards"]) or _clock > float(record["recovery_until_s"]):
			return "Stale retained threat union requires ordinary cleanup before preview"
		if record.get("adapter", {}).get("kind") == "lunge" and not _lunge_source_valid(owner, record["adapter"]):
			return "Stale retained lunge source requires ordinary cleanup before preview"
		if _is_replay(record):
			return "Exclusive replay occupies preview through recovery"
		if record.get("adapter", {}).get("kind") == "tracking" and not record["adapter"]["locked"] and _clock >= float(record["active_from_s"]) - EPSILON:
			return "Stale uncommitted tracking warning requires ordinary cleanup before preview"
	for entry: Dictionary in _cooldowns.values():
		var owner: Node3D = (entry["owner"] as WeakRef).get_ref() as Node3D
		if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion() or _clock >= float(entry["ready_s"]):
			return "Stale retained cooldown requires ordinary cleanup before preview"
	return ""


func _preview_body_state(node: Node3D, collision_path: String = "") -> Dictionary:
	var state := {"instance_id": node.get_instance_id(), "transform": node.global_transform}
	if node is CharacterBody3D:
		var body: CharacterBody3D = node as CharacterBody3D
		var measured: Dictionary = BodySweep.source_description(body)
		if measured.has("error"):
			return {"error": "Unsupported actual preview source body: " + String(measured["error"])}
		var collision: CollisionShape3D = measured["collision"]
		var path: String = String(body.get_path_to(collision))
		if not collision_path.is_empty() and path != collision_path:
			return {"error": "Actual preview body must retain its required collision path"}
		var signature: Dictionary
		if collision.shape is CapsuleShape3D:
			var description: Dictionary = Motion.source_description(body, path)
			if description.has("error"):
				return {"error": description["error"]}
			signature = description["signature"]
		else:
			# A stationary ordinary union source may retain its genuine BOX.
			# No capsule proxy is substituted or leased for that source.
			signature = {"collision_path": path, "centre": Codec.vector3(collision.position), "shape": _shape_data(collision.shape), "layer": body.collision_layer, "mask": body.collision_mask}
		state.merge({"velocity": body.velocity, "layer": body.collision_layer, "mask": body.collision_mask, "priority": body.collision_priority, "safe_margin": body.safe_margin, "up_direction": body.up_direction, "floor_snap_length": body.floor_snap_length, "motion_mode": body.motion_mode, "platform_velocity": body.get_platform_velocity(), "platform_angular_velocity": body.get_platform_angular_velocity(), "body_signature": signature, "collision_instance_id": str(collision.get_instance_id()), "shape_instance_id": str(collision.shape.get_instance_id()), "collision_transform": collision.global_transform})
	return state


func _same_lunge_preview(left: Variant, right: Variant) -> bool:
	var wire: String = _lunge_preview_wire(left)
	return not wire.is_empty() and wire == _lunge_preview_wire(right)


func _lunge_preview_wire(value: Variant) -> String:
	var budget: Array[int] = [262144]
	var encoded: Dictionary = _encode_lunge_preview(value, 0, budget)
	return PreviewExact.stringify(encoded["value"]) if encoded.get("accepted", false) else ""


func _encode_lunge_preview(value: Variant, depth: int, budget: Array[int]) -> Dictionary:
	# Injective native encoding: a caller array cannot impersonate a Vector3.
	# Strict tagged scalar bits/types compare copied data; physical/contact
	# tolerances and shared14 represented-position allowances remain unchanged.
	budget[0] -= 1
	if depth > 32 or budget[0] < 0:
		return {"accepted": false}
	var encoded: Variant = value
	match typeof(value):
		TYPE_ARRAY, TYPE_DICTIONARY:
			if value.size() > 16384:
				return {"accepted": false}
			var children: Variant = [] if value is Array else {}
			for key: Variant in (range(value.size()) if value is Array else value.keys()):
				if value is Dictionary and not key is String:
					return {"accepted": false}
				var child: Dictionary = _encode_lunge_preview(value[key], depth + 1, budget)
				if not child.get("accepted", false):
					return child
				if value is Array: children.append(child["value"])
				else: children[key] = child["value"]
			encoded = ["Array" if value is Array else "Dictionary", children]
		TYPE_VECTOR3:
			encoded = ["Vector3", value.x, value.y, value.z]
		TYPE_VECTOR2:
			encoded = ["Vector2", value.x, value.y]
		TYPE_RECT2:
			encoded = ["Rect2", value.position.x, value.position.y, value.size.x, value.size.y]
		TYPE_BASIS:
			encoded = ["Basis", Codec.vector3(value.x), Codec.vector3(value.y), Codec.vector3(value.z)]
		TYPE_TRANSFORM3D:
			encoded = ["Transform3D", _transform_data(value)]
		TYPE_NIL, TYPE_BOOL, TYPE_STRING, TYPE_INT, TYPE_FLOAT:
			if not Codec.value_error(value).is_empty():
				return {"accepted": false}
		_:
			return {"accepted": false}
	return {"accepted": true, "value": encoded}


func _rejected(reason: String) -> Dictionary:
	last_error = reason
	return {"accepted": false, "reason": reason}


func _tracking_geometry_valid(owner: Node3D, geometry: Dictionary, adapter: Dictionary = {}) -> bool:
	if not is_instance_valid(owner) or geometry.get("kind") != "lane" or not Geometry.error(geometry).is_empty() or (geometry["from"] as Vector3).distance_to(owner.global_position) > EPSILON or absf((geometry["to"] as Vector3).y - owner.global_position.y) > EPSILON:
		return false
	var reach: float = (geometry["to"] as Vector3).distance_to(geometry["from"])
	return reach > EPSILON and (adapter.is_empty() or (is_equal_approx(reach, adapter["reach"]) and is_equal_approx(geometry["radius"], adapter["radius"])))


func cancel(reservation_id: String, reason: String = "cancelled") -> bool:
	if _cycle_busy or _snapshot_busy or not _reservations.has(reservation_id):
		return false
	var record: Dictionary = _reservations[reservation_id]
	# Stop only owned motion. A caller must cancel BEFORE applying knockback.
	if record.get("adapter", {}).get("kind") == "lunge":
		var source: CharacterBody3D = (record["_owner"] as WeakRef).get_ref() as CharacterBody3D
		if is_instance_valid(source):
			source.velocity = Vector3.ZERO
	if _is_replay(record):
		_cycle_exchange_changed(record)
		reason = reason.left(512) if not reason.is_empty() else "cancelled"
		_retain_replay_cancellation(record, reason)
	_reservations.erase(reservation_id)
	# Cancellation releases geometry/budget; cooldown remains conservative until
	# the scheduled role interval expires. Death/removal cancels owner cooldown too.
	_transaction_depth += 1
	_cycle_cancel_before_observers(record, reason)
	reservation_invalidated.emit(reservation_id, reason)
	_transaction_depth -= 1
	return true


func cancel_owner(owner: Node3D, reason: String = "source_defeated") -> void:
	if _cycle_busy or _snapshot_busy or _boundary_busy or not is_instance_valid(owner):
		return
	_boundary_busy = true
	var instance_id: int = owner.get_instance_id()
	for reservation_id: String in _reservations.keys():
		if not _reservations.has(reservation_id):
			continue
		if int(_reservations[reservation_id]["source_instance_id"]) == instance_id:
			cancel(reservation_id, reason)
	var retained_replay: bool = false
	for tombstone: Dictionary in _replay_cancellations.values():
		retained_replay = retained_replay or int(tombstone.source_instance_id) == instance_id
	if not retained_replay:
		_cooldowns.erase(instance_id)
	_boundary_busy = false


func invalidate_world(new_revision: int) -> void:
	if _cycle_busy or _snapshot_busy or _boundary_busy:
		return
	if new_revision <= _world_revision:
		last_error = "Collision world revision must increase"
		return
	_boundary_busy = true
	for reservation_id: String in _reservations.keys():
		cancel(reservation_id, "collision_world_changed")
	_world_revision = new_revision
	_boundary_busy = false


func has_committed_exchange() -> bool:
	## Pure diagnostic: stale entries still occupy a compound-proof barrier.
	## Cleanup and cancellation callbacks remain in ordinary scheduler updates.
	return not _reservations.is_empty()


func source_control_state(owner: Node3D) -> Dictionary:
	## Pure retained-state view. Never prune leases/cooldowns, advance motion,
	## write diagnostics or emit cancellation callbacks while an actor samples.
	if not is_inside_tree() or is_queued_for_deletion() or not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion():
		return {}
	if owner.get_world_3d() != get_world_3d():
		return {}
	var instance_id: int = owner.get_instance_id()
	var records: Array[Dictionary] = []
	for record: Dictionary in _reservations.values():
		var retained_owner: Variant = (record["_owner"] as WeakRef).get_ref()
		if int(record["source_instance_id"]) == instance_id and retained_owner == owner:
			records.append(_public_record(record))
	var cooldown: Variant = null
	if _cooldowns.has(instance_id):
		var entry: Dictionary = _cooldowns[instance_id]
		var retained_owner: Variant = (entry["owner"] as WeakRef).get_ref()
		if retained_owner == owner:
			cooldown = {"ready_s": float(entry["ready_s"])}
	return {"api_revision": "scheduler-source-control-1", "source_instance_id": instance_id, "encounter_id": _encounter_id, "world_revision": _world_revision, "clock_s": _clock, "outside_transaction": not _snapshot_busy and not _boundary_busy and not _request_busy and _transaction_depth == 0, "reservations": records, "cooldown": cooldown}


func reservations() -> Array[Dictionary]:
	if not _snapshot_busy:
		_prune()
	var result: Array[Dictionary] = []
	for record: Dictionary in _reservations.values():
		result.append(_public_record(record))
	return result


func reservation_state(reservation_id: String) -> Dictionary:
	if not _snapshot_busy:
		_prune()
	return _public_record(_reservations[reservation_id]) if _reservations.has(reservation_id) else {}


func _public_record(record: Dictionary) -> Dictionary:
	var copy: Dictionary = record.duplicate(true)
	copy.erase("_owner")
	copy.erase("_floor_guards")
	copy.erase("_replay_world")
	copy.erase("_replay_actor")
	copy.erase("_authored_source_script")
	var pending: bool = record.get("adapter", {}).get("kind") in ["tracking", "replay", "authored_replay"] and not record["adapter"]["locked"]
	copy["armed"] = not pending
	copy["state"] = "warning" if pending or _clock < float(record["lock_from_s"]) else ("lock" if _clock < float(record["active_from_s"]) else ("active" if _clock <= float(record["active_until_s"]) else "recovery"))
	return copy


func _physics_process(delta: float) -> void:
	if _encounter_id.is_empty():
		return
	_transaction_depth += 1
	_clock += delta
	_expire_replay_cancellations()
	_prune()
	_advance_lunges()
	_transaction_depth -= 1


func _prune() -> void:
	for reservation_id: String in _reservations.keys():
		if not _reservations.has(reservation_id):
			continue
		var record: Dictionary = _reservations[reservation_id]
		var owner: Node3D = (record["_owner"] as WeakRef).get_ref() as Node3D
		if not is_instance_valid(owner) or owner.is_queued_for_deletion() or not owner.is_inside_tree():
			cancel(reservation_id, "source_removed")
		elif owner.global_position.distance_to(record["source_position"]) > EPSILON:
			cancel(reservation_id, "stationary_source_moved")
		elif record.get("adapter", {}).get("kind") == "lunge" and not _lunge_source_valid(owner, record["adapter"]):
			cancel(reservation_id, "lunge_source_changed")
		elif not _guards_valid(record["_floor_guards"]):
			cancel(reservation_id, "floor_contract_changed")
		elif _is_replay(record) and _clock <= float(record.recovery_until_s) and not replay_reservation_error(reservation_id).is_empty():
			cancel(reservation_id, "replay_contract_changed")
		elif record.get("adapter", {}).get("kind") == "tracking" and not record["adapter"]["locked"] and _clock >= float(record["active_from_s"]) - EPSILON:
			cancel(reservation_id, "tracking_lock_missed")
		elif _clock > float(record["recovery_until_s"]):
			_cycle_exchange_changed(record)
			# Normal expiry is release, not a cancellation notification.
			if record.get("adapter", {}).get("kind") == "lunge":
				(owner as CharacterBody3D).velocity = Vector3.ZERO
			_reservations.erase(reservation_id)
	for instance_id: int in _cooldowns.keys():
		var entry: Dictionary = _cooldowns[instance_id]
		var owner: Node3D = (entry["owner"] as WeakRef).get_ref() as Node3D
		if not is_instance_valid(owner) or owner.is_queued_for_deletion() or not owner.is_inside_tree() or _clock >= float(entry["ready_s"]):
			_cooldowns.erase(instance_id)


func _lunge_source_valid(owner: Node3D, adapter: Dictionary) -> bool:
	if not owner is CharacterBody3D:
		return false
	var body: CharacterBody3D = owner as CharacterBody3D
	var description: Dictionary = Motion.source_description(body, adapter["body_collision_path"])
	return not description.has("error") and Codec.same_values(description["signature"], adapter["body_signature"]) and body.velocity.distance_to(adapter["current_velocity"]) <= EPSILON


func _advance_lunges() -> void:
	for reservation_id: String in _reservations.keys():
		if not _reservations.has(reservation_id):
			continue
		var record: Dictionary = _reservations[reservation_id]
		if record.get("adapter", {}).get("kind") != "lunge" or _clock < float(record["active_from_s"]):
			continue
		var owner: CharacterBody3D = (record["_owner"] as WeakRef).get_ref() as CharacterBody3D
		var floors: Array[Dictionary] = []
		for guard: Dictionary in record["_floor_guards"]:
			floors.append({"collision": (guard["node"] as WeakRef).get_ref(), "safe_rect": guard["safe_rect"]})
		var advanced: Dictionary = Motion.advance(owner, record["adapter"], minf(_clock - float(record["active_from_s"]), float(record["adapter"]["duration_s"])), floors)
		if advanced.has("error"):
			cancel(reservation_id, "lunge_motion_unproved")
			continue
		advanced["current_velocity"] = owner.velocity
		record["adapter"] = advanced
		record["source_position"] = owner.global_position
		if advanced["finished"]:
			# Physics endpoint variation is bounded below proof skin. Expose exact
			# actual landing once stopped; never manufacture a stationary proxy.
			record["opening_position"] = owner.global_position


func _request_error(owner: Node3D, threat: Dictionary, response: Dictionary, ignored_id: String = "", allow_unstable_warning: bool = false) -> String:
	if _boundary_busy or _encounter_id.is_empty() or not is_inside_tree() or get_tree().paused:
		return "An active, unpaused encounter is required"
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion() or owner.get_world_3d() != get_world_3d() or not Geometry.finite_vector(owner.global_position):
		return "Live source in the scheduler's world required"
	if ignored_id.is_empty() and _cooldowns.has(owner.get_instance_id()):
		return "Source attack cooldown is still occupied"
	for existing: Dictionary in _reservations.values():
		if _is_replay(existing):
			return "Exclusive replay occupies preview through recovery"
		if existing["id"] != ignored_id and int(existing["source_instance_id"]) == owner.get_instance_id():
			return "Source already owns a committed exchange"
	if response.get("world_revision") != _world_revision or not threat.get("role") is Dictionary:
		return "World revision and a resolved role are required"
	var role: Dictionary = threat["role"]
	if role.get("difficulty_schema") != 1 or role.get("difficulty_profile") != _profile["id"]:
		return "Role must be resolved for this fixed encounter profile"
	for key: String in ["windup_s", "lock_s", "active_s", "recovery_s", "attack_interval_s"]:
		if not Geometry.finite_number(role.get(key)) or float(role[key]) <= 0.0:
			return "Finite role timing required: " + key
	if float(role["lock_s"]) >= float(role["windup_s"]):
		return "Locked phase must follow a readable warning"
	if not threat.get("geometry") is Dictionary or not Geometry.error(threat["geometry"]).is_empty():
		return "Authoritative supported threat geometry required"
	if threat.get("source_stationary") != true or threat.get("opening_stationary") != true or not Geometry.finite_vector(threat.get("opening_position")):
		return "Stationary committed source and reachable recovery target required"
	if not Geometry.finite_number(threat.get("cooldown_remaining_s")) or float(threat["cooldown_remaining_s"]) > EPSILON or float(threat["cooldown_remaining_s"]) < 0.0:
		return "Source must be ready according to its live cooldown"
	return response_error(response, allow_unstable_warning)


func response_error(response: Dictionary, allow_unstable_warning: bool = false) -> String:
	## Shared live-response/floor preflight for conservative compound witnesses.
	## Pure: does not prune, allocate, move a body or reserve any timing.
	if _boundary_busy or _encounter_id.is_empty() or not is_inside_tree() or get_tree().paused:
		return "An active, unpaused encounter is required"
	if response.get("world_revision") != _world_revision:
		return "Current collision world revision required"
	var actor: CharacterBody3D = response.get("actor") as CharacterBody3D
	if not is_instance_valid(actor) or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.get_world_3d() != get_world_3d() or not Geometry.finite_vector(actor.global_position) or not Geometry.finite_vector(actor.velocity):
		return "Live finite shared actor required"
	if not allow_unstable_warning and (response.get("stable") != true or actor.velocity.length() > EPSILON):
		return "Stable live shared actor required; reject current dash/knockback/fall"
	var collision: CollisionShape3D = actor.get_node_or_null("BodyCollision") as CollisionShape3D
	if collision == null or collision.disabled or not collision.shape is CapsuleShape3D or not actor.global_basis.is_equal_approx(Basis.IDENTITY) or not collision.transform.basis.is_equal_approx(Basis.IDENTITY) or not collision.position.is_equal_approx(Vector3(0, CAPSULE_CENTER_Y, 0)):
		return "Shared fixed capsule/feet convention required"
	var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D
	if not is_equal_approx(capsule.radius, CAPSULE_RADIUS) or not is_equal_approx(capsule.height, CAPSULE_HEIGHT):
		return "Capsule dimensions differ from the shared actor"
	if not response.get("stats") is Dictionary:
		return "Resolved ordinary equipment stats required"
	var stats: Dictionary = response["stats"]
	for key: String in ["dash_speed", "dash_distance", "dash_duration", "dash_cooldown", "primary_range", "primary_cooldown"]:
		if not Geometry.finite_number(stats.get(key)) or float(stats[key]) <= 0.0:
			return "Missing resolved response stat: " + key
	if not is_equal_approx(float(stats["dash_duration"]), float(stats["dash_distance"]) / float(stats["dash_speed"])):
		return "Dash travel and duration must use the same action snapshot"
	for key: String in ["dash_cooldown_left_s", "primary_cooldown_left_s", "commitment_remaining_s", "recognition_s", "primary_commitment_s", "attack_input_margin_s"]:
		if not Geometry.finite_number(response.get(key)) or float(response[key]) < 0.0:
			return "Explicit live response timing required: " + key
	if float(response["recognition_s"]) <= 0.0 or float(response["primary_commitment_s"]) <= 0.0 or float(response["primary_commitment_s"]) > float(stats["primary_cooldown"]) or float(response["dash_cooldown_left_s"]) > float(stats["dash_cooldown"]) + EPSILON:
		return "Response recognition, commitment and remaining cooldown are inconsistent"
	for key: String in ["escape_directions", "return_directions"]:
		if not response.get(key) is Array or (response[key] as Array).size() > 16:
			return "Finite authored response candidates required: " + key
		for direction: Variant in response[key]:
			if not Geometry.finite_vector(direction) or absf(direction.y) > EPSILON or absf(direction.length() - 1.0) > EPSILON:
				return "Response candidates must be normalized ground swipes"
	if (response["escape_directions"] as Array).is_empty():
		return "At least one authored escape candidate is required"
	return _floor_error(response["floor_regions"] if response.has("floor_regions") else null, actor.global_position)


func _prove(candidate: Dictionary, response: Dictionary, ignored_id: String = "") -> Dictionary:
	if _is_replay(candidate):
		return {"accepted": false, "reason": "Compound replay has no ordinary proxy geometry"}
	for existing: Dictionary in _reservations.values():
		if _is_replay(existing):
			return {"accepted": false, "reason": "Compound replay cannot enter ordinary timed geometry proof"}
	var actor: CharacterBody3D = response["actor"]
	var stats: Dictionary = response["stats"]
	var origin: Vector3 = actor.global_position
	# Conservatively sum recognition, current stationary commitment and remaining
	# dash cooldown; no instantaneous ideal dash or immunity is credited.
	var dash_start: float = _clock + float(response["recognition_s"]) + float(response["commitment_remaining_s"]) + float(response["dash_cooldown_left_s"])
	var dash_end: float = dash_start + float(stats["dash_duration"])
	var primary_ready: float = _clock + float(response["primary_cooldown_left_s"])
	var all_threats: Array[Dictionary] = [candidate]
	for reservation: Dictionary in _reservations.values():
		if reservation["id"] != ignored_id:
			all_threats.append(reservation)
	for direction: Vector3 in response["escape_directions"]:
		var landing: Vector3 = origin + direction * float(stats["dash_distance"])
		if not Geometry.finite_vector(landing):
			continue
		var initial: Array[Dictionary] = [_segment(origin, origin, _clock, dash_start, "recognition_and_ready"), _segment(origin, landing, dash_start, dash_end, "escape_dash")]
		var opening_start: float = maxf(dash_end, float(candidate["active_until_s"]) + TIME_MARGIN)
		var return_choices: Array[Vector3] = [Vector3.ZERO]
		for returning: Vector3 in response["return_directions"]:
			return_choices.append(returning)
		for returning: Vector3 in return_choices:
			var path: Array[Dictionary] = initial.duplicate(true)
			var attack_position: Vector3 = landing
			var attack_start: float = maxf(opening_start, primary_ready) + float(response["attack_input_margin_s"])
			if returning != Vector3.ZERO:
				var return_start: float = maxf(opening_start, dash_start + float(stats["dash_cooldown"]))
				attack_position = landing + returning * float(stats["dash_distance"])
				if not Geometry.finite_vector(attack_position):
					continue
				path.append(_segment(landing, landing, dash_end, return_start, "recovery_wait"))
				var return_end: float = return_start + float(stats["dash_duration"])
				path.append(_segment(landing, attack_position, return_start, return_end, "positioning_dash"))
				attack_start = maxf(return_end, primary_ready) + float(response["attack_input_margin_s"])
				path.append(_segment(attack_position, attack_position, return_end, attack_start, "primary_ready"))
			else:
				path.append(_segment(landing, landing, dash_end, attack_start, "recovery_wait"))
			# Holding through full ordinary recovery is stricter than the immediate
			# hit/short logical phase; it covers the slowest selected weapon cadence.
			var finish: float = attack_start + maxf(float(stats["primary_cooldown"]), float(response["primary_commitment_s"]))
			if not is_finite(finish) or finish > float(candidate["recovery_until_s"]) - TIME_MARGIN:
				continue
			path.append(_segment(attack_position, attack_position, attack_start, finish, "ordinary_primary"))
			var opening_tolerance: float = Motion.ENDPOINT_TOLERANCE if candidate.get("adapter", {}).get("kind") == "lunge" else 0.0
			if not _opening_reachable(attack_position, candidate["opening_position"], float(stats["primary_range"]) - opening_tolerance):
				continue
			var safe: bool = true
			for segment: Dictionary in path:
				if not _floor_path_supported(segment["from"], segment["to"], response["floor_regions"]) or not _capsule_path_clear(segment["from"], segment["to"], actor, response["floor_regions"]):
					safe = false
					break
			if not safe:
				continue
			for existing: Dictionary in all_threats:
				if Geometry.timed_path_hits(existing["geometry"], path, float(existing["active_from_s"]), float(existing["active_until_s"]), CAPSULE_RADIUS + SKIN):
					safe = false
					break
			if safe:
				return {"accepted": true, "path": path, "landing": landing, "attack_position": attack_position, "primary_time_s": attack_start, "response_complete_s": finish, "uses_blast": false, "uses_invulnerability": false, "proof_scope": "static_box_floor_full_dash_stationary_primary"}
	return {"accepted": false, "reason": "No supported collision/floor-safe timed escape and ordinary-primary opening through the committed threat union"}


func _segment(start: Vector3, finish: Vector3, begin: float, end: float, kind: String) -> Dictionary:
	return {"from": start, "to": finish, "start_s": begin, "end_s": end, "kind": kind}


func _opening_reachable(position: Vector3, target: Vector3, reach: float) -> bool:
	if Geometry.planar(position).distance_to(Geometry.planar(target)) > reach - SKIN or absf(position.y - target.y) > 1.4:
		return false
	var query := PhysicsRayQueryParameters3D.create(position + Vector3.UP * 0.7, target + Vector3.UP * 0.7, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _floor_error(regions: Variant, position: Vector3) -> String:
	if not regions is Array or regions.is_empty() or regions.size() > 32:
		return "Authored supported floor regions are required"
	var floor_height: float = INF
	for region: Variant in regions:
		if not region is Dictionary or not region.get("safe_rect") is Rect2:
			return "Floor region needs a world X/Z safe_rect"
		var collision: CollisionShape3D = region.get("collision") as CollisionShape3D
		if not is_instance_valid(collision) or not collision.is_inside_tree() or collision.disabled or not collision.shape is BoxShape3D or not collision.get_parent() is StaticBody3D or not collision.global_basis.is_equal_approx(Basis.IDENTITY):
			return "Floor proof requires a live unrotated solid static box collider"
		var body: StaticBody3D = collision.get_parent() as StaticBody3D
		if body.is_queued_for_deletion() or body.get_world_3d() != get_world_3d() or (body.collision_layer & 1) == 0:
			return "Floor collider must participate in the shared scenery mask"
		var collision_count: int = 0
		for child: Node in body.get_children():
			if child is CollisionShape3D or child is CollisionPolygon3D:
				collision_count += 1
		if collision_count != 1:
			return "Supported floor body must own exactly one box shape"
		var box: BoxShape3D = collision.shape as BoxShape3D
		var rect: Rect2 = region["safe_rect"]
		var floor_rect := Rect2(Geometry.planar(collision.global_position) - Vector2(box.size.x, box.size.z) * 0.5, Vector2(box.size.x, box.size.z))
		var top: float = collision.global_position.y + box.size.y * 0.5
		if not Geometry.finite_vector(box.size) or not Geometry.finite_vector(collision.global_position) or not is_finite(top):
			return "Floor proof needs finite box dimensions and transform"
		if is_finite(floor_height) and absf(top - floor_height) > EPSILON:
			return "Supported floor boxes must share one ground height"
		floor_height = top
		var feet_y: float = position.y + CAPSULE_CENTER_Y - CAPSULE_HEIGHT * 0.5
		if not rect.position.is_finite() or not rect.size.is_finite() or rect.size.x <= 2.0 * (CAPSULE_RADIUS + SKIN) or rect.size.y <= 2.0 * (CAPSULE_RADIUS + SKIN) or not floor_rect.encloses(rect) or absf(feet_y - top) > FEET_TOLERANCE:
			return "Authored safe rectangle must fit a continuous box floor at actor feet height"
	return ""


func _floor_path_supported(start: Vector3, finish: Vector3, regions: Array, radius: float = CAPSULE_RADIUS + SKIN) -> bool:
	if absf(start.y - finish.y) > EPSILON:
		return false
	var intervals: Array[Vector2] = []
	var a: Vector2 = Geometry.planar(start)
	var b: Vector2 = Geometry.planar(finish)
	for region: Dictionary in regions:
		var rect: Rect2 = (region["safe_rect"] as Rect2).grow(-radius)
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		var interval := Vector2(0, 1)
		for axis: int in range(2):
			var movement: float = b[axis] - a[axis]
			if absf(movement) <= EPSILON:
				if a[axis] < rect.position[axis] - EPSILON or a[axis] > rect.end[axis] + EPSILON:
					interval = Vector2(1, 0)
					break
			else:
				var first: float = (rect.position[axis] - a[axis]) / movement
				var last: float = (rect.end[axis] - a[axis]) / movement
				interval.x = maxf(interval.x, minf(first, last))
				interval.y = minf(interval.y, maxf(first, last))
		if interval.x <= interval.y:
			intervals.append(interval)
	intervals.sort_custom(func(left: Vector2, right: Vector2) -> bool: return left.x < right.x)
	var covered: float = 0.0
	for interval: Vector2 in intervals:
		if interval.x > covered + EPSILON:
			return false
		covered = maxf(covered, interval.y)
	if covered < 1.0 - EPSILON:
		return false
	# Rays confirm current physics registration; analytic box coverage above is
	# the continuous support proof. Sparse probes alone never establish no holes.
	for point: Vector3 in [start, finish]:
		var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.2, point - Vector3.UP * 0.2, 1)
		var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			return false
		var matched: bool = false
		for region: Dictionary in regions:
			if hit["rid"] == ((region["collision"] as CollisionShape3D).get_parent() as StaticBody3D).get_rid():
				matched = true
		if not matched:
			return false
	return true


func _capsule_path_clear(start: Vector3, finish: Vector3, actor: CharacterBody3D, regions: Array) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = CAPSULE_RADIUS + SKIN
	# Cover the small allowed standing/settling tolerance too. Distinct floor
	# heights are rejected, so excluded floor bodies cannot hide a step collision.
	capsule.height = CAPSULE_HEIGHT + 2.0 * (SKIN + FEET_TOLERANCE)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.collide_with_areas = false
	var excluded: Array[RID] = [actor.get_rid()]
	for region: Dictionary in regions:
		excluded.append(((region["collision"] as CollisionShape3D).get_parent() as StaticBody3D).get_rid())
	query.exclude = excluded
	query.transform = Transform3D(Basis.IDENTITY, start + Vector3.UP * CAPSULE_CENTER_Y)
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if not space.intersect_shape(query, 1).is_empty():
		return false
	query.motion = finish - start
	var fractions: PackedFloat32Array = space.cast_motion(query)
	if fractions.size() != 2 or float(fractions[0]) < 1.0 - EPSILON:
		return false
	query.transform.origin = finish + Vector3.UP * CAPSULE_CENTER_Y
	query.motion = Vector3.ZERO
	return space.intersect_shape(query, 1).is_empty()


func _floor_guards(regions: Array) -> Array[Dictionary]:
	var guards: Array[Dictionary] = []
	for region: Dictionary in regions:
		var collision: CollisionShape3D = region["collision"]
		guards.append({"node": weakref(collision), "transform": collision.global_transform, "size": (collision.shape as BoxShape3D).size, "safe_rect": region["safe_rect"]})
	return guards


func _guards_valid(guards: Array) -> bool:
	for guard: Dictionary in guards:
		var collision: CollisionShape3D = (guard["node"] as WeakRef).get_ref() as CollisionShape3D
		if not is_instance_valid(collision) or not collision.is_inside_tree() or collision.disabled or not collision.shape is BoxShape3D or not collision.global_transform.is_equal_approx(guard["transform"]) or not (collision.shape as BoxShape3D).size.is_equal_approx(guard["size"]):
			return false
	return true


## Paused aggregate transport. bindings names stable authored owners/floors and
## supplies a world_root containing EVERY layer-1 blocker in this World3D.
## owner_positions/owner_velocities may prevalidate staged enemy motion; restore
## additionally checks actual positions/velocities at commit. Apply enemies first
## Optional owner_collision_states stages validated live lifecycle flags against
## retained actual capsules; commit still requires actual enabled collision.
## without yielding. Old stationary records retain scheduler-snapshot-1 schema;
## new records carry an optional, strictly validated adapter object.
## Capture never prunes/emits; stale bindings reject. Collision signatures derive
## from actual shape-owner data, not caller-supplied hashes or visual meshes.
func snapshot_state(bindings: Dictionary) -> Dictionary:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty():
		return {}
	_snapshot_busy = true
	last_snapshot_error = _bindings_error(bindings)
	var result: Dictionary = {}
	if last_snapshot_error.is_empty():
		result = _capture_snapshot(bindings)
		if not result.is_empty():
			last_snapshot_error = _snapshot_plan(result, bindings).get("error", "")
	_snapshot_busy = false
	return result.duplicate(true) if last_snapshot_error.is_empty() else {}


func snapshot_error(snapshot: Dictionary, bindings: Dictionary) -> String:
	var error: String = _snapshot_access_error()
	if not error.is_empty():
		return error
	_snapshot_busy = true
	var plan: Dictionary = _snapshot_plan(snapshot, bindings)
	_snapshot_busy = false
	return plan.get("error", "")


func restore_state(snapshot: Dictionary, bindings: Dictionary) -> bool:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty():
		return false
	_snapshot_busy = true
	var plan: Dictionary = _snapshot_plan(snapshot, bindings)
	last_snapshot_error = plan.get("error", "")
	if last_snapshot_error.is_empty():
		for record: Dictionary in plan["reservations"].values():
			var owner: Node3D = (record["_owner"] as WeakRef).get_ref() as Node3D
			if not is_instance_valid(owner) or owner.global_position.distance_to(record["source_position"]) > EPSILON:
				last_snapshot_error = "Apply validated enemy positions before scheduler commit"
				break
			if record.get("adapter", {}).get("kind") == "lunge" and not _lunge_source_valid(owner, record["adapter"]):
				last_snapshot_error = "Apply validated real source velocity/capsule before scheduler commit"
				break
			if _is_authored_replay(record):
				last_snapshot_error = authored_replay_source_error(owner, record.adapter.sequence, _replay_context(record), _authored_regions(record), plan.profile.id, plan.world_revision)
				if not last_snapshot_error.is_empty() or owner.get_script() != record._authored_source_script:
					if last_snapshot_error.is_empty(): last_snapshot_error = "Authored source script changed before commit"
					break
	if last_snapshot_error.is_empty():
		for value: Dictionary in plan.get("replay_cancellations", {}).values():
			if value.get("kind") != "authored_replay": continue
			var owner: Node3D = (value._owner as WeakRef).get_ref()
			last_snapshot_error = authored_replay_source_error(owner, value.sequence, _authored_tombstone_context(value, bindings.world_root), bindings.floors.values(), plan.profile.id, plan.world_revision, {}, true)
			if not last_snapshot_error.is_empty() or owner.get_script() != value._authored_source_script:
				if last_snapshot_error.is_empty(): last_snapshot_error = "Authored tombstone script changed before commit"
				break
	if last_snapshot_error.is_empty() and plan.has("authored_cycles"):
		for cycle: Dictionary in plan.authored_cycles.values():
			last_snapshot_error = _cycle_native_error(cycle, {}, plan.profile.id, plan.world_revision, cycle.entry.stage != "running")
			if not last_snapshot_error.is_empty(): break
	if last_snapshot_error.is_empty():
		# No callbacks, attack requests, damage, cancellation or retiming here.
		_encounter_id = plan["encounter_id"]
		_profile = plan["profile"].duplicate(true)
		_world_revision = plan["world_revision"]
		_clock = plan["clock_s"]
		_serial = plan["serial"]
		_reservations = plan["reservations"]
		_cooldowns = plan["cooldowns"]
		_replay_cancellations = plan["replay_cancellations"]
		_authored_cycles = plan.get("authored_cycles", {})
	_snapshot_busy = false
	return last_snapshot_error.is_empty()


func collision_fingerprint(world_root: Node3D) -> Dictionary:
	## Public diagnostic only. Empty + last_snapshot_error means unsupported.
	var result: Dictionary = _collision_signature(world_root)
	last_snapshot_error = result.get("error", "")
	return (result.get("signature", {}) as Dictionary).duplicate(true)


func pure_collision_fingerprint(world_root: Node3D) -> Dictionary:
	## Read-only native collision signature. Unsupported roots return empty;
	## no diagnostics, clocks, pruning, callbacks or scheduler fields change.
	var result: Dictionary = _collision_signature(world_root)
	return (result.get("signature", {}) as Dictionary).duplicate(true)


func _snapshot_access_error() -> String:
	if not is_inside_tree() or not get_tree().paused:
		return "Scheduler snapshots require a paused live tree"
	if _snapshot_busy or _boundary_busy or _request_busy or _cycle_busy or _transaction_depth > 0:
		return "Scheduler snapshots require a deferred callback/physics barrier"
	return ""


func _stable_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 128:
		return false
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9_./:-]+$")
	var matched: RegExMatch = pattern.search(value)
	return matched != null and matched.get_string() == value


func _under_root(node: Node, world_root: Node3D) -> bool:
	return node == world_root or world_root.is_ancestor_of(node)


func _bindings_error(bindings: Dictionary) -> String:
	var world_root: Node3D = bindings.get("world_root") as Node3D
	if not is_instance_valid(world_root) or not world_root.is_inside_tree() or world_root.is_queued_for_deletion() or world_root.get_world_3d() != get_world_3d():
		return "Live same-world authored world_root required"
	if not bindings.get("owners") is Dictionary or not bindings.get("floors") is Dictionary:
		return "Stable owner and floor mappings required"
	if bindings.has("owner_positions") and not bindings["owner_positions"] is Dictionary:
		return "Staged owner_positions must be a dictionary"
	if bindings.has("owner_velocities") and not bindings["owner_velocities"] is Dictionary:
		return "Staged owner_velocities must be a dictionary"
	if bindings.has("owner_collision_states") and not bindings["owner_collision_states"] is Dictionary:
		return "Staged owner_collision_states must be a dictionary"
	if bindings.has("authored_owner_bindings"):
		if not bindings.authored_owner_bindings is Dictionary: return "Paused authored actor bindings must be a stable map"
		for source_id: Variant in bindings.authored_owner_bindings:
			if not bindings.owners.has(source_id) or not bindings.authored_owner_bindings[source_id] is Dictionary: return "Staged authored source must map its actual owner"
	if bindings.has("actors"):
		if not bindings.actors is Dictionary:
			return "Replay actors must be a stable dictionary"
		for actor_id: Variant in bindings.actors:
			var actor: CinderPlayer = bindings.actors[actor_id] as CinderPlayer
			if not _stable_id(actor_id) or not is_instance_valid(actor) or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.get_world_3d() != get_world_3d() or not _under_root(actor, world_root):
				return "Replay actor IDs must resolve actual live shared players under world_root"
	var used: Dictionary = {}
	for owner_id: Variant in bindings["owners"]:
		var owner: Node3D = bindings["owners"][owner_id] as Node3D
		if not _stable_id(owner_id) or not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion() or owner.get_world_3d() != get_world_3d() or not _under_root(owner, world_root) or used.has(owner.get_instance_id()):
			return "Owner IDs must map uniquely to live nodes under world_root"
		used[owner.get_instance_id()] = true
	for owner_id: Variant in bindings.get("owner_positions", {}):
		if not bindings["owners"].has(owner_id) or not Geometry.finite_vector(bindings["owner_positions"][owner_id]):
			return "Staged positions require a mapped stable owner and finite vector"
	for owner_id: Variant in bindings.get("owner_velocities", {}):
		if not bindings["owners"].has(owner_id) or not bindings["owners"][owner_id] is CharacterBody3D or not Geometry.finite_vector(bindings["owner_velocities"][owner_id]):
			return "Staged velocities require a mapped real source body and finite vector"
	for owner_id: Variant in bindings.get("owner_collision_states", {}):
		var state: Variant = bindings["owner_collision_states"][owner_id]
		if not _stable_id(owner_id) or not bindings["owners"].has(owner_id) or not bindings["owners"][owner_id] is CharacterBody3D or not state is Dictionary:
			return "Staged collision states require a mapped actual source body and closed state"
		var description: Dictionary = Motion.staged_source_description(bindings["owners"][owner_id] as CharacterBody3D, state)
		if description.has("error"):
			return description["error"]
	used.clear()
	var regions: Array = []
	for floor_id: Variant in bindings["floors"]:
		var region: Variant = bindings["floors"][floor_id]
		if not _stable_id(floor_id) or not region is Dictionary:
			return "Stable authored floor IDs required"
		var collision: CollisionShape3D = region.get("collision") as CollisionShape3D
		if not is_instance_valid(collision) or not collision.is_inside_tree() or collision.is_queued_for_deletion() or not _under_root(collision, world_root) or used.has(collision.get_instance_id()):
			return "Floor IDs must map uniquely to live colliders under world_root"
		used[collision.get_instance_id()] = true
		regions.append(region)
	if not regions.is_empty():
		var first: CollisionShape3D = regions[0].get("collision") as CollisionShape3D
		if not first.shape is BoxShape3D:
			return "Snapshot floor bindings require supported box floors"
		var floor_y: float = first.global_position.y + (first.shape as BoxShape3D).size.y * 0.5
		return _floor_error(regions, Vector3(0, floor_y - CAPSULE_CENTER_Y + CAPSULE_HEIGHT * 0.5, 0))
	return ""


func _capture_snapshot(bindings: Dictionary) -> Dictionary:
	var collision: Dictionary = _collision_signature(bindings["world_root"])
	if collision.has("error"):
		last_snapshot_error = collision["error"]
		return {}
	var records: Array = []
	for reservation: Dictionary in _reservations.values():
		if float(reservation["recovery_until_s"]) < _clock:
			continue # Pure output filtering; no lifecycle signals.
		var owner: Node3D = (reservation["_owner"] as WeakRef).get_ref() as Node3D
		var owner_id: String = _binding_id(bindings["owners"], owner)
		if owner_id.is_empty() or owner.global_position.distance_to(reservation["source_position"]) > EPSILON or not _guards_valid(reservation["_floor_guards"]):
			last_snapshot_error = "Reservation has stale owner/floor bindings"
			return {}
		if reservation.get("adapter", {}).get("kind") == "lunge" and not _lunge_source_valid(owner, reservation["adapter"]):
			last_snapshot_error = "Reservation has changed real source velocity/capsule"
			return {}
		var floors: Array = []
		for guard: Dictionary in reservation["_floor_guards"]:
			var node: CollisionShape3D = (guard["node"] as WeakRef).get_ref() as CollisionShape3D
			var floor_id: String = ""
			for candidate_id: String in bindings["floors"]:
				if bindings["floors"][candidate_id]["collision"] == node:
					floor_id = candidate_id
			if floor_id.is_empty():
				last_snapshot_error = "Reserved floor has no stable binding"
				return {}
			if not ((guard["safe_rect"] == bindings["floors"][floor_id]["safe_rect"]) if _is_replay(reservation) else (guard["safe_rect"] as Rect2).is_equal_approx(bindings["floors"][floor_id]["safe_rect"])):
				last_snapshot_error = "Reserved authored safe rectangle changed"
				return {}
			floors.append({"floor_id": floor_id, "signature": _floor_signature(bindings["floors"][floor_id], bindings["world_root"])})
		var record: Dictionary = {"id": reservation["id"], "source_id": owner_id, "source_position": Codec.vector3(reservation["source_position"]), "opening_position": Codec.vector3(reservation["opening_position"]), "floors": floors}
		if _is_replay(reservation):
			var error: String = replay_reservation_error(reservation.id)
			var actor_id: String = _binding_id(bindings.get("actors", {}), replay_target(reservation.id))
			if not error.is_empty() or actor_id.is_empty():
				last_snapshot_error = error if not error.is_empty() else "Replay target has no stable actor binding"
				return {}
			record["response_actor_id"] = actor_id
		else:
			record["geometry"] = _encode_geometry(reservation.geometry)
		for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision"]:
			record[key] = reservation[key]
		if reservation.has("adapter"):
			record["adapter"] = _encode_adapter(reservation["adapter"])
		records.append(record)
	var cooldowns: Array = []
	for cooldown: Dictionary in _cooldowns.values():
		if float(cooldown["ready_s"]) <= _clock:
			continue
		var owner_id: String = _binding_id(bindings["owners"], (cooldown["owner"] as WeakRef).get_ref())
		if owner_id.is_empty():
			last_snapshot_error = "Cooldown has no stable live owner binding"
			return {}
		cooldowns.append({"source_id": owner_id, "ready_s": cooldown["ready_s"]})
	var result := {"api_revision": SNAPSHOT_API_REVISION, "schema_version": SNAPSHOT_SCHEMA_VERSION, "encounter_id": _encounter_id, "profile": _profile.duplicate(true), "world_revision": _world_revision, "clock_s": _clock, "serial": _serial, "collision": collision["signature"], "reservations": records, "cooldowns": cooldowns}
	var cancellations: Array = []
	for value: Dictionary in _replay_cancellations.values():
		if _clock >= float(value.cooldown_until_s):
			continue
		var encoded: Dictionary = _encode_replay_tombstone(value, bindings)
		if encoded.is_empty():
			last_snapshot_error = "Retained replay cancellation lacks stable live owner/player custody"
			return {}
		cancellations.append(encoded)
	if not cancellations.is_empty():
		result["replay_cancellations"] = cancellations
	for record: Dictionary in records:
		if _is_authored_replay(record): result.schema_version = 2
	for value: Dictionary in cancellations:
		if value.get("kind") == "authored_replay": result.schema_version = 2
	if not _authored_cycles.is_empty():
		var journal: Dictionary = _cycle_capture(bindings)
		if journal.is_empty(): return {}
		result["schema_version"] = 3
		result["authored_source_cycles"] = journal
	return result


func _binding_id(mapping: Dictionary, node: Object) -> String:
	if not is_instance_valid(node):
		return ""
	for stable_id: String in mapping:
		if mapping[stable_id] == node:
			return stable_id
	return ""


func _snapshot_plan(snapshot: Dictionary, bindings: Dictionary) -> Dictionary:
	if snapshot.has("authored_source_cycles") or snapshot.get("schema_version") == 3:
		return _cycle_snapshot_plan(snapshot, bindings)
	if not _authored_cycles.is_empty():
		return {"error": "Managed authored history cannot be stripped or downgraded"}
	return _snapshot_plan_ordinary(snapshot, bindings)


func _snapshot_plan_ordinary(snapshot: Dictionary, bindings: Dictionary) -> Dictionary:
	var error: String = Codec.value_error(snapshot)
	if error.is_empty():
		var envelope_keys: Array = ["api_revision", "schema_version", "encounter_id", "profile", "world_revision", "clock_s", "serial", "collision", "reservations", "cooldowns"]
		if snapshot.has("replay_cancellations"):
			envelope_keys.append("replay_cancellations")
		error = Codec.keys_error(snapshot, envelope_keys)
	if error.is_empty():
		error = _bindings_error(bindings)
	if not error.is_empty():
		return {"error": error}
	if snapshot["api_revision"] != SNAPSHOT_API_REVISION or not Codec.is_integer(snapshot["schema_version"], 1, 2) or not snapshot["encounter_id"] is String or not snapshot["profile"] is Dictionary or not Codec.is_integer(snapshot["world_revision"]) or not Codec.is_integer(snapshot["serial"]) or not Codec.is_number(snapshot["clock_s"]) or float(snapshot["clock_s"]) < 0.0 or not snapshot["reservations"] is Array or not snapshot["cooldowns"] is Array:
		return {"error": "Invalid scheduler snapshot envelope"}
	var authored_wire: bool = int(snapshot.schema_version) == 2
	var has_authored: bool = false
	if snapshot.has("replay_cancellations") and not snapshot.replay_cancellations is Array: return {"error": "Replay cancellation history must be an Array"}
	for value: Variant in snapshot.reservations:
		if value is Dictionary and _is_authored_replay(value): has_authored = true
	for value: Variant in snapshot.get("replay_cancellations", []):
		if value is Dictionary and value.get("kind") == "authored_replay": has_authored = true
	if authored_wire != has_authored or (authored_wire and (not snapshot.schema_version is int or not snapshot.world_revision is int or not snapshot.serial is int or not snapshot.clock_s is float or PreviewExact.stringify(snapshot).is_empty())): return {"error": "Authored exchanges require exact conditional scheduler schema2"}
	if snapshot.has("replay_cancellations") and (not snapshot.replay_cancellations is Array or snapshot.replay_cancellations.is_empty() or snapshot.replay_cancellations.size() > MAX_REPLAY_CANCELLATIONS):
		return {"error": "Replay cancellation history must be bounded and nonempty when present"}
	var profile: Dictionary = snapshot["profile"]
	if snapshot["encounter_id"].is_empty():
		if not profile.is_empty() or not snapshot["reservations"].is_empty() or not snapshot["cooldowns"].is_empty() or snapshot.has("replay_cancellations"):
			return {"error": "Idle scheduler cannot retain committed exchanges"}
	elif not _stable_id(snapshot["encounter_id"]) or int(snapshot["world_revision"]) < 1 or not profile.get("id") is String or not (_authored_same(profile, _difficulty.profile(profile["id"])) if authored_wire else Codec.same_values(profile, _difficulty.profile(profile["id"]))) or profile.is_empty():
		return {"error": "Encounter profile/revision no longer matches the catalogue"}
	var collision: Dictionary = _collision_signature(bindings["world_root"])
	if collision.has("error"):
		return collision
	if not (_authored_same(snapshot["collision"], collision["signature"]) if authored_wire else Codec.same_values(snapshot["collision"], collision["signature"])):
		return {"error": "Actual authored collision fingerprint changed"}
	var records: Dictionary = {}
	var owners: Dictionary = {}
	var cooldowns: Dictionary = {}
	var clock_s: float = snapshot["clock_s"]
	var budget: int = 0
	for value: Variant in snapshot["reservations"]:
		if not value is Dictionary:
			return {"error": "Reservation must be a dictionary"}
		var record: Dictionary = value
		var replay: bool = _is_replay(record)
		var record_keys: Array = ["id", "source_id", "source_position", "opening_position", "floors", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision"]
		record_keys.append("response_actor_id" if replay else "geometry")
		if record.has("adapter"):
			record_keys.append("adapter")
		error = Codec.keys_error(record, record_keys)
		if not error.is_empty() or not record["id"] is String or not record["id"].begins_with("threat-") or not record["id"].substr(7).is_valid_int() or not Codec.is_integer(int(record["id"].substr(7)), 1, int(snapshot["serial"])) or record["id"] != "threat-%d" % int(record["id"].substr(7)) or records.has(record["id"]) or not _stable_id(record["source_id"]) or not bindings["owners"].has(record["source_id"]) or owners.has(record["source_id"]) or not Codec.is_vector3(record["source_position"]) or not Codec.is_vector3(record["opening_position"]) or (not replay and not record["geometry"] is Dictionary) or not record["floors"] is Array or record["floors"].is_empty() or record["profile_id"] != profile.get("id") or record["world_revision"] != snapshot["world_revision"]:
			return {"error": "Invalid reservation identity/bindings"}
		for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
			if not Codec.is_number(record[key]) or float(record[key]) < 0.0:
				return {"error": "Reservation deadlines must be finite and nonnegative"}
		if not (record["start_s"] < record["lock_from_s"] and record["lock_from_s"] < record["active_from_s"] and record["active_from_s"] < record["active_until_s"] and record["active_until_s"] < record["recovery_until_s"] and record["active_from_s"] < record["cooldown_until_s"] and record["start_s"] <= clock_s + EPSILON and clock_s <= record["recovery_until_s"] + EPSILON):
			return {"error": "Reservation phase deadline order or clock is incoherent"}
		if _is_authored_replay(record) and (float(record.start_s) > clock_s or clock_s > float(record.recovery_until_s)): return {"error": "Authored clock cannot cross its exact live deadline"}
		var geometry: Dictionary = {} if replay else _decode_geometry(record["geometry"])
		if not replay and geometry.is_empty():
			return {"error": "Invalid serialized authoritative geometry"}
		var owner: Node3D = bindings["owners"][record["source_id"]]
		var source_position: Vector3 = Codec.read_vector3(record["source_position"])
		var staged: Vector3 = bindings.get("owner_positions", {}).get(record["source_id"], owner.global_position)
		if _is_authored_replay(record) and not _authored_same(Codec.vector3(staged), record.source_position): return {"error": "Exact staged authored knot position differs"}
		if staged.distance_to(source_position) > EPSILON:
			return {"error": "Bound/staged owner position differs from saved exchange"}
		var regions: Array = []
		var floor_ids: Dictionary = {}
		for floor_value: Variant in record["floors"]:
			if not floor_value is Dictionary or not Codec.keys_error(floor_value, ["floor_id", "signature"]).is_empty() or not _stable_id(floor_value["floor_id"]) or not bindings["floors"].has(floor_value["floor_id"]) or floor_ids.has(floor_value["floor_id"]):
				return {"error": "Reserved floor ID is missing or duplicated"}
			var region: Dictionary = bindings["floors"][floor_value["floor_id"]]
			var floor_matches: bool = _authored_same(floor_value["signature"], _floor_signature(region, bindings["world_root"])) if _is_authored_replay(record) else (_same_replay(floor_value["signature"], _floor_signature(region, bindings["world_root"])) if replay else Codec.same_values(floor_value["signature"], _floor_signature(region, bindings["world_root"])))
			if not floor_matches:
				return {"error": "Authored floor signature changed"}
			floor_ids[floor_value["floor_id"]] = true
			regions.append(region)
		var committed: Dictionary = record.duplicate(true)
		committed.erase("source_id")
		committed.erase("floors")
		committed["source_position"] = source_position
		committed["opening_position"] = Codec.read_vector3(record["opening_position"])
		if not replay:
			committed["geometry"] = geometry
		committed["source_instance_id"] = owner.get_instance_id()
		committed["_owner"] = weakref(owner)
		committed["_floor_guards"] = _floor_guards(regions)
		if record.has("adapter"):
			var adapter: Dictionary
			if replay:
				adapter = _decode_replay_adapter(record.adapter, record, owner, bindings, clock_s, collision.signature)
				if not adapter.has("error"):
					var actor: CinderPlayer = bindings.actors[record.response_actor_id]
					committed.erase("response_actor_id")
					committed["response_actor_instance_id"] = actor.get_instance_id()
					committed["_replay_actor"] = weakref(actor)
					committed["_replay_world"] = weakref(bindings.world_root)
					if _is_authored_replay(record): committed["_authored_source_script"] = owner.get_script()
			else:
				adapter = _decode_adapter(record["adapter"] if record["adapter"] is Dictionary else {}, committed, owner, regions, clock_s, bindings.get("owner_velocities", {}).get(record["source_id"], (owner as CharacterBody3D).velocity if owner is CharacterBody3D else Vector3.ZERO), bindings.get("owner_collision_states", {}).get(record["source_id"], {}))
			if adapter.has("error"):
				return adapter
			committed["adapter"] = adapter
		records[record["id"]] = committed
		owners[record["source_id"]] = record
		if float(record["active_until_s"]) >= clock_s:
			budget += 1
	if not profile.is_empty() and budget > int(profile["reserved_threat_budget"]):
		return {"error": "Snapshot exceeds its preparing/active threat budget"}
	for record: Dictionary in records.values():
		if _is_replay(record) and (records.size() != 1 or not _same_replay(snapshot.collision, collision.signature)):
			return {"error": "Replay snapshot requires an exclusive exact collision-world exchange"}
	var committed_records: Array = records.values()
	for first_index: int in range(committed_records.size()):
		for second_index: int in range(first_index + 1, committed_records.size()):
			var first: Dictionary = committed_records[first_index]
			var second: Dictionary = committed_records[second_index]
			if float(first["active_until_s"]) >= clock_s and float(second["active_until_s"]) >= clock_s and absf(float(first["active_from_s"]) - float(second["active_from_s"])) < float(profile["commit_stagger_s"]) - EPSILON:
				return {"error": "Snapshot committed activations lost their visible stagger"}
	for value: Variant in snapshot["cooldowns"]:
		if not value is Dictionary or not Codec.keys_error(value, ["source_id", "ready_s"]).is_empty() or not _stable_id(value["source_id"]) or not bindings["owners"].has(value["source_id"]) or not Codec.is_number(value["ready_s"]) or float(value["ready_s"]) <= clock_s:
			return {"error": "Invalid retained source cooldown"}
		if authored_wire and not value.ready_s is float: return {"error": "Exact authored cooldown scalar required"}
		var owner: Node3D = bindings["owners"][value["source_id"]]
		if cooldowns.has(owner.get_instance_id()):
			return {"error": "Duplicated source cooldown"}
		cooldowns[owner.get_instance_id()] = {"owner": weakref(owner), "ready_s": float(value["ready_s"])}
	for owner_id: String in owners:
		var record: Dictionary = owners[owner_id]
		var instance_id: int = (bindings["owners"][owner_id] as Node3D).get_instance_id()
		var cooldown_matches: bool = cooldowns.has(instance_id) and (_authored_same(cooldowns[instance_id]["ready_s"], record["cooldown_until_s"]) if _is_authored_replay(record) else (_same_replay(cooldowns[instance_id]["ready_s"], record["cooldown_until_s"]) if _is_replay(record) else is_equal_approx(float(cooldowns[instance_id]["ready_s"]), float(record["cooldown_until_s"]))))
		if float(record["cooldown_until_s"]) > clock_s and not cooldown_matches:
			return {"error": "Reservation and retained cooldown disagree"}
	var cancellations: Dictionary = {}
	for value: Variant in snapshot.get("replay_cancellations", []):
		var decoded: Dictionary = _decode_replay_tombstone(value, snapshot, bindings, cooldowns)
		if decoded.has("error"):
			return decoded
		if cancellations.has(decoded.id) or records.has(decoded.id):
			return {"error": "Replay cancellation identity duplicates a retained/live lease"}
		cancellations[decoded.id] = decoded
	return {"encounter_id": snapshot["encounter_id"], "profile": profile.duplicate(true), "world_revision": int(snapshot["world_revision"]), "clock_s": clock_s, "serial": int(snapshot["serial"]), "reservations": records, "cooldowns": cooldowns, "replay_cancellations": cancellations}



func _authored_adapter_error(value: Dictionary, record: Dictionary, clock_s: float, historical: bool = false) -> String:
	if PreviewExact.stringify(value).is_empty() or not Codec.keys_error(value, AUTHORED_ADAPTER_KEYS).is_empty() or not value.locked is bool or not _stable_id(value.source_id) or not _stable_id(value.source_epoch) or not value.generation is int or not Codec.is_integer(value.generation, 1) or not value.sequence is Dictionary or not value.world_collision_fingerprint is Dictionary or not value.world_floor_signature is Array or not value.timeline_origin_s is float or not Codec.in_range(value.timeline_origin_s, 0.0, ReplayWitness.MAX_CLOCK_S) or not _authored_same(value.max_dispatch_delay_s, ReplayWitness.MAX_DISPATCH_DELAY_S): return "Invalid exact authored adapter fields"
	var reader = ReplayProgram.new()
	if not reader.restore_state(value.sequence, value.source_epoch, value.generation) or not reader.is_authored_enemy(): return "Distinct immutable authored sequence required"
	var plan: Dictionary = reader.state()
	if plan.source_id != value.source_id or plan.profile_id != record.profile_id or not _authored_same(plan.world.world_revision, record.world_revision) or not _authored_same(plan.world.collision_fingerprint, value.world_collision_fingerprint) or not _authored_same(plan.world.floor_signature, value.world_floor_signature): return "Authored source/profile/world identity differs"
	var expected: Dictionary = {"adapter": value}
	_set_replay_deadlines(expected, plan, value.timeline_origin_s)
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not record.get(key) is float or not Codec.in_range(record[key], 0.0, ReplayWitness.MAX_CLOCK_S): return "Exact bounded authored deadlines required"
	for key: String in ["active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not _authored_same(record[key], expected[key]): return "Authored deadline differs from immutable timeline: " + key
	if float(record.start_s) > clock_s: return "Authored start exceeds actual clock"
	var warning_s: float = float(plan.authored.warning_s)
	if value.locked:
		if float(record.lock_from_s) < float(record.start_s) + warning_s or not _authored_same(value.timeline_origin_s, float(record.lock_from_s) - warning_s) or clock_s < float(record.lock_from_s): return "Authored full lock/origin custody differs"
	elif not _authored_same(value.timeline_origin_s, record.start_s) or not _authored_same(record.lock_from_s, float(record.start_s) + warning_s) or (not historical and clock_s >= float(record.active_from_s)): return "Unarmed authored original warning/lead differs"
	if not historical and clock_s > float(record.recovery_until_s): return "Authored lease expired"
	return ""


func _authored_tombstone_context(value: Dictionary, world_root: Node3D) -> Dictionary:
	return {"world_root": world_root, "source_id": value.source_id, "source_epoch": value.source_epoch, "generation": value.generation, "world_collision_fingerprint": value.world_collision_fingerprint, "world_floor_signature": value.world_floor_signature}


func _decode_authored_adapter(value: Dictionary, record: Dictionary, owner: Node3D, bindings: Dictionary, clock_s: float, collision: Dictionary) -> Dictionary:
	var error: String = _authored_adapter_error(value, record, clock_s)
	if error.is_empty(): error = _replay_actor_binding_error(record.get("response_actor_id"), bindings)
	if not error.is_empty(): return {"error": error}
	if record.source_id != value.source_id or not _authored_same(value.world_collision_fingerprint, collision): return {"error": "Actual authored source/world binding differs"}
	var regions: Array = []
	for floor_unit: Dictionary in record.floors: regions.append(bindings.floors[floor_unit.floor_id])
	var context: Dictionary = _authored_tombstone_context(value, bindings.world_root)
	var staged: Dictionary = bindings.get("authored_owner_bindings", {}).get(record.source_id, {})
	error = authored_replay_source_error(owner, value.sequence, context, regions, record.profile_id, record.world_revision, staged)
	if not error.is_empty(): return {"error": error}
	var reader = ReplayProgram.new()
	reader.restore_state(value.sequence, value.source_epoch, value.generation)
	var plan: Dictionary = reader.state()
	if not _authored_same(record.source_position, Codec.vector3(plan.authored.tether_position)) or not _authored_same(record.opening_position, Codec.vector3(plan.authored.tether_position)): return {"error": "Authored fixed source/opening differs from knot"}
	if owner is CharacterBody3D and bindings.get("owner_velocities", {}).get(record.source_id, (owner as CharacterBody3D).velocity) != Vector3.ZERO: return {"error": "Authored source must remain stationary"}
	return value.duplicate(true)


func _decode_authored_tombstone(value: Dictionary, snapshot: Dictionary, bindings: Dictionary, cooldowns: Dictionary) -> Dictionary:
	if PreviewExact.stringify(value).is_empty() or not Codec.keys_error(value, AUTHORED_TOMBSTONE_KEYS).is_empty(): return {"error": "Closed authored cancellation fields required"}
	if not value.id is String or not value.id.begins_with("threat-") or not value.id.substr(7).is_valid_int() or not Codec.is_integer(int(value.id.substr(7)), 1, int(snapshot.serial)) or value.id != "threat-%d" % int(value.id.substr(7)) or not _stable_id(value.source_id) or not bindings.owners.has(value.source_id) or not value.reason is String or value.reason.is_empty() or value.reason.length() > 512 or value.profile_id != snapshot.profile.get("id") or not _authored_same(value.world_revision, snapshot.world_revision) or not value.cancelled_at_s is float or not Codec.in_range(value.cancelled_at_s, 0.0, float(snapshot.clock_s)): return {"error": "Exact authored cancellation identity/clock differs"}
	var adapter: Dictionary = {}
	for key: String in AUTHORED_ADAPTER_KEYS: adapter[key] = value[key]
	var error: String = _authored_adapter_error(adapter, value, value.cancelled_at_s, true)
	if error.is_empty(): error = _replay_actor_binding_error(value.response_actor_id, bindings)
	if not error.is_empty(): return {"error": error}
	if value.sequence_id != adapter.sequence.sequence_id or float(value.cooldown_until_s) <= float(snapshot.clock_s): return {"error": "Unexpired original authored cancellation required"}
	var owner: Node3D = bindings.owners[value.source_id]
	var actor: CinderPlayer = bindings.actors[value.response_actor_id]
	var cooldown: Dictionary = cooldowns.get(owner.get_instance_id(), {})
	if cooldown.is_empty() or not _authored_same(cooldown.ready_s, value.cooldown_until_s): return {"error": "Authored canceled cooldown differs"}
	var staged: Dictionary = bindings.get("authored_owner_bindings", {}).get(value.source_id, {})
	error = authored_replay_source_error(owner, value.sequence, _authored_tombstone_context(value, bindings.world_root), bindings.floors.values(), snapshot.profile.id, snapshot.world_revision, staged, true)
	if not error.is_empty(): return {"error": error}
	var result: Dictionary = value.duplicate(true)
	result.erase("source_id")
	result.erase("response_actor_id")
	# Keep the authored stable source in its native tombstone as well as the
	# actual weak owner; serialization resolves and checks that same mapping.
	result["source_id"] = value.source_id
	result["source_instance_id"] = owner.get_instance_id()
	result["response_actor_instance_id"] = actor.get_instance_id()
	result["_owner"] = weakref(owner)
	result["_replay_actor"] = weakref(actor)
	result["_authored_source_script"] = owner.get_script()
	return result


func _replay_adapter_error(value: Dictionary, record: Dictionary, clock_s: float, historical: bool = false) -> String:
	if value.get("kind") == "authored_replay": return _authored_adapter_error(value, record, clock_s, historical)
	if not Codec.keys_error(value, REPLAY_ADAPTER_KEYS).is_empty() or not value.locked is bool or not value.source_epoch is String or not Codec.is_integer(value.generation, 1) or not value.sequence is Dictionary or not value.capture_collision_fingerprint is Dictionary or not Codec.is_number(value.timeline_origin_s) or not _same_replay(value.max_dispatch_delay_s, ReplayWitness.MAX_DISPATCH_DELAY_S):
		return "Invalid replay adapter identity/timing fields"
	if not Codec.keys_error(value.capture_collision_fingerprint, ["schema_version", "physics_engine", "physics_ticks_per_second", "colliders"]).is_empty() or not Codec.is_integer(value.capture_collision_fingerprint.schema_version, 1, 1) or not value.capture_collision_fingerprint.physics_engine is String or not Codec.is_integer(value.capture_collision_fingerprint.physics_ticks_per_second, 1) or not value.capture_collision_fingerprint.colliders is Array or value.capture_collision_fingerprint.colliders.is_empty() or value.capture_collision_fingerprint.colliders.size() > 256:
		return "Replay capture fingerprint envelope is invalid"
	var sequence = ReplaySequence.new()
	if not sequence.restore_state(value.sequence, value.source_epoch, int(value.generation)):
		return "Invalid immutable replay sequence: " + sequence.last_snapshot_error
	var plan: Dictionary = sequence.state()
	var expected: Dictionary = {}
	_set_replay_deadlines(expected, plan, float(value.timeline_origin_s))
	for key: String in ["active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not _same_replay(record.get(key), expected[key]):
			return "Replay deadline must exactly derive from its immutable timeline: " + key
	if not Codec.in_range(record.get("start_s"), 0.0, ReplayWitness.MAX_CLOCK_S) or float(record.start_s) > clock_s or not Codec.in_range(value.timeline_origin_s, 0.0, ReplayWitness.MAX_CLOCK_S):
		return "Replay request/origin clock is incoherent"
	var warning_s: float = float(plan.authored.warning_s)
	if value.locked:
		# Preserve ACTUAL lock scalar, using the same subtraction as commit.
		# Re-adding warning could round a bit; no timing epsilon licenses a lock.
		if float(record.lock_from_s) < float(record.start_s) + warning_s or not _same_replay(value.timeline_origin_s, float(record.lock_from_s) - warning_s) or clock_s < float(record.lock_from_s):
			return "Armed replay must retain exact actual lock/origin and full warning"
	elif not _same_replay(value.timeline_origin_s, record.start_s) or not _same_replay(record.lock_from_s, float(record.start_s) + warning_s) or (not historical and clock_s >= float(record.active_from_s)):
		return "Unarmed replay must retain its exact request origin and unused lead"
	if not historical and clock_s > float(record.recovery_until_s):
		return "Replay lease has expired"
	return ""


func _replay_actor_binding_error(actor_id: Variant, bindings: Dictionary) -> String:
	if not _stable_id(actor_id) or not bindings.get("actors") is Dictionary or bindings.actors.size() != 1 or not bindings.actors.has(actor_id):
		return "Replay requires one explicit stable shared-player actor binding"
	var actor: CinderPlayer = bindings.actors[actor_id] as CinderPlayer
	if not is_instance_valid(actor) or not actor.get_collision_exceptions().is_empty() or actor.get_platform_velocity().length() > EPSILON or actor.get_platform_angular_velocity().length() > EPSILON:
		return "Replay actor fixed-world collision/carry changed"
	return ""


func _decode_replay_adapter(value: Dictionary, record: Dictionary, owner: Node3D, bindings: Dictionary, clock_s: float, collision: Dictionary) -> Dictionary:
	if value.get("kind") == "authored_replay": return _decode_authored_adapter(value, record, owner, bindings, clock_s, collision)
	var error: String = _replay_adapter_error(value, record, clock_s)
	if error.is_empty():
		error = _replay_actor_binding_error(record.get("response_actor_id"), bindings)
	if not error.is_empty():
		return {"error": error}
	if not _same_replay(value.capture_collision_fingerprint, collision):
		return {"error": "Replay immutable capture collision fingerprint changed"}
	var sequence = ReplaySequence.new()
	sequence.restore_state(value.sequence, value.source_epoch, int(value.generation))
	var plan: Dictionary = sequence.state()
	if Codec.read_vector3(record.opening_position).distance_to(plan.authored.tether_position) > EPSILON or Codec.read_vector3(record.source_position).distance_to(plan.authored.tether_position) > EPSILON:
		return {"error": "Replay source/opening must remain the actual authored tether"}
	var staged_velocity: Vector3 = bindings.get("owner_velocities", {}).get(record.source_id, (owner as CharacterBody3D).velocity if owner is CharacterBody3D else Vector3.ZERO)
	if staged_velocity.length() > EPSILON:
		return {"error": "Replay restored source must be stationary"}
	return value.duplicate(true)


func _decode_replay_tombstone(value: Variant, snapshot: Dictionary, bindings: Dictionary, cooldowns: Dictionary) -> Dictionary:
	if value is Dictionary and value.get("kind") == "authored_replay": return _decode_authored_tombstone(value, snapshot, bindings, cooldowns)
	if not value is Dictionary or not Codec.keys_error(value, REPLAY_TOMBSTONE_KEYS).is_empty():
		return {"error": "Invalid replay cancellation fields"}
	if not value.id is String or not value.id.begins_with("threat-") or not value.id.substr(7).is_valid_int() or not Codec.is_integer(int(value.id.substr(7)), 1, int(snapshot.serial)) or value.id != "threat-%d" % int(value.id.substr(7)) or not _stable_id(value.source_id) or not bindings.owners.has(value.source_id) or not value.reason is String or value.reason.is_empty() or value.reason.length() > 512 or value.profile_id != snapshot.profile.get("id") or not Codec.is_integer(value.world_revision, 1, int(snapshot.world_revision)) or not Codec.in_range(value.cancelled_at_s, 0.0, float(snapshot.clock_s)):
		return {"error": "Replay cancellation identity/clock/profile is incoherent"}
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not Codec.is_number(value[key]) or float(value[key]) < 0.0:
			return {"error": "Invalid historical replay deadline"}
	var adapter: Dictionary = {}
	for key: String in REPLAY_ADAPTER_KEYS:
		adapter[key] = "replay" if key == "kind" else value[key]
	var error: String = _replay_adapter_error(adapter, value, float(value.cancelled_at_s), true)
	if error.is_empty():
		error = _replay_actor_binding_error(value.response_actor_id, bindings)
	if not error.is_empty():
		return {"error": error}
	if value.sequence_id != adapter.sequence.sequence_id or float(value.cooldown_until_s) <= float(snapshot.clock_s):
		return {"error": "Replay canceled restore requires exact sequence and unexpired retained cooldown"}
	var owner: Node3D = bindings.owners[value.source_id]
	var actor: CinderPlayer = bindings.actors[value.response_actor_id]
	var cooldown: Dictionary = cooldowns.get(owner.get_instance_id(), {})
	if cooldown.is_empty() or not _same_replay(cooldown.ready_s, value.cooldown_until_s):
		return {"error": "Replay tombstone and retained source cooldown disagree"}
	var result: Dictionary = value.duplicate(true)
	result.erase("source_id")
	result.erase("response_actor_id")
	result["source_instance_id"] = owner.get_instance_id()
	result["response_actor_instance_id"] = actor.get_instance_id()
	result["_owner"] = weakref(owner)
	result["_replay_actor"] = weakref(actor)
	return result


func _encode_adapter(adapter: Dictionary) -> Dictionary:
	var encoded: Dictionary = adapter.duplicate(true)
	if adapter.get("kind") == "lunge":
		for key: String in ["start", "planned_endpoint", "current_position", "current_velocity", "direction"]:
			encoded[key] = Codec.vector3(adapter[key])
	return encoded


func _decode_adapter(value: Dictionary, record: Dictionary, owner: Node3D, regions: Array, clock_s: float, staged_velocity: Vector3, staged_collision: Dictionary = {}) -> Dictionary:
	if value.get("kind") == "tracking":
		if not staged_collision.is_empty():
			return {"error": "Collision lifecycle staging supports only real-body lunge adapters"}
		if not Codec.keys_error(value, ["kind", "locked", "reach", "radius", "lock_s", "active_s", "recovery_s", "attack_interval_s"]).is_empty() or not value["locked"] is bool:
			return {"error": "Invalid tracking adapter fields"}
		for key: String in ["reach", "radius", "lock_s", "active_s", "recovery_s", "attack_interval_s"]:
			if not Codec.is_number(value[key]) or float(value[key]) <= 0.0:
				return {"error": "Tracking adapter needs finite positive geometry/timing"}
		var geometry: Dictionary = record["geometry"]
		if geometry["kind"] != "lane" or (geometry["from"] as Vector3).distance_to(record["source_position"]) > EPSILON or (record["opening_position"] as Vector3).distance_to(record["source_position"]) > EPSILON or not is_equal_approx((geometry["to"] as Vector3).distance_to(geometry["from"]), value["reach"]) or not is_equal_approx(geometry["radius"], value["radius"]):
			return {"error": "Tracking adapter no longer matches its fixed source lane"}
		if not is_equal_approx(float(record["active_from_s"]) - float(record["lock_from_s"]), value["lock_s"]) or not is_equal_approx(float(record["active_until_s"]) - float(record["active_from_s"]), value["active_s"]) or not is_equal_approx(float(record["recovery_until_s"]) - float(record["active_until_s"]), value["recovery_s"]) or not is_equal_approx(float(record["cooldown_until_s"]) - float(record["active_from_s"]), value["attack_interval_s"]) or (not value["locked"] and clock_s >= float(record["active_from_s"]) - EPSILON) or (value["locked"] and clock_s < float(record["lock_from_s"]) - EPSILON):
			return {"error": "Tracking adapter arming/deadlines are incoherent"}
		return value.duplicate(true)
	if value.get("kind") != "lunge" or not owner is CharacterBody3D:
		return {"error": "Unsupported source adapter"}
	var keys: Array = ["kind", "start", "planned_endpoint", "current_position", "current_velocity", "direction", "speed", "distance", "duration_s", "damage_radius", "body_signature", "body_collision_path", "collision_shortened", "actual_collided", "finished"]
	if not Codec.keys_error(value, keys).is_empty() or not value["body_signature"] is Dictionary or not value["body_collision_path"] is String or value["body_collision_path"].is_empty() or value["body_collision_path"].contains("\n") or value["body_collision_path"].contains("\r"):
		return {"error": "Invalid lunge adapter fields"}
	for key: String in ["collision_shortened", "actual_collided", "finished"]:
		if not value[key] is bool:
			return {"error": "Lunge collision/completion flags must be booleans"}
	var adapter: Dictionary = value.duplicate(true)
	for key: String in ["start", "planned_endpoint", "current_position", "current_velocity", "direction"]:
		if not Codec.is_vector3(value[key]):
			return {"error": "Lunge adapter needs finite serialized motion vectors"}
		adapter[key] = Codec.read_vector3(value[key])
	for key: String in ["start", "planned_endpoint", "current_position"]:
		var point: Vector3 = adapter[key]
		if not point.is_finite() or maxf(absf(point.x), maxf(absf(point.y), absf(point.z))) > BodySweep.MAX_COORDINATE:
			return {"error": "Saved lunge positions exceed supported actual body-query bounds"}
	for key: String in ["speed", "distance", "duration_s", "damage_radius"]:
		if not Codec.is_number(value[key]) or float(value[key]) <= 0.0:
			return {"error": "Lunge adapter needs finite positive motion data"}
	var description: Dictionary
	if staged_collision.is_empty():
		description = Motion.source_description(owner as CharacterBody3D, value["body_collision_path"])
	else:
		if staged_collision["collision_path"] != value["body_collision_path"]:
			return {"error": "Staged capsule path differs from the saved lunge body"}
		description = Motion.staged_source_description(owner as CharacterBody3D, staged_collision)
	var signature_matches: bool = _same_replay(description.get("signature", {}), value["body_signature"]) if not staged_collision.is_empty() else Codec.same_values(description.get("signature", {}), value["body_signature"])
	if description.has("error") or not signature_matches:
		return {"error": "Saved lunge physical source signature changed"}
	var direction: Vector3 = adapter["direction"]
	var route: Vector3 = adapter["planned_endpoint"] - adapter["start"]
	var travelled: Vector3 = adapter["current_position"] - adapter["start"]
	var length: float = route.dot(direction)
	var progress: float = travelled.dot(direction)
	var route_precision: float = BodySweep.position_rounding_bound(adapter["start"], adapter["planned_endpoint"])
	if absf(direction.y) > EPSILON or absf(direction.length() - 1.0) > EPSILON or absf(route.y) > EPSILON or (route - direction * length).length() > route_precision or length < -route_precision or length > float(value["distance"]) + route_precision or absf(travelled.y) > EPSILON or (travelled - direction * progress).length() > route_precision or progress < -route_precision or progress > length + Motion.ENDPOINT_TOLERANCE or float(value["distance"]) <= EPSILON or float(value["distance"]) > Motion.MAX_DISTANCE or not (direction * float(value["speed"])).is_finite():
		return {"error": "Saved lunge must stay on its bounded straight physical route"}
	if not is_equal_approx(float(value["duration_s"]), float(value["distance"]) / float(value["speed"])) or float(record["active_until_s"]) - float(record["active_from_s"]) < float(value["duration_s"]) - EPSILON or float(value["damage_radius"]) < float(description["radius"]) + Motion.ENDPOINT_TOLERANCE or value["collision_shortened"] != (length < float(value["distance"]) - route_precision):
		return {"error": "Saved lunge timing/footprint/shortening is incoherent"}
	var geometry: Dictionary = record["geometry"]
	if geometry["kind"] != "lane" or (geometry["from"] as Vector3).distance_to(adapter["start"]) > EPSILON or (geometry["to"] as Vector3).distance_to(adapter["planned_endpoint"]) > EPSILON or not is_equal_approx(geometry["radius"], value["damage_radius"]) or (adapter["current_position"] as Vector3).distance_to(record["source_position"]) > EPSILON or (adapter["current_velocity"] as Vector3).distance_to(staged_velocity) > EPSILON:
		return {"error": "Saved lunge geometry or staged real source motion differs"}
	var elapsed: float = maxf(0.0, clock_s - float(record["active_from_s"]))
	var expected: float = minf(float(value["distance"]), float(value["speed"]) * elapsed)
	var velocity: Vector3 = adapter["current_velocity"]
	if progress > expected + Motion.ENDPOINT_TOLERANCE:
		return {"error": "Saved physical source cannot arrive before resolved travel time"}
	if value["finished"]:
		if clock_s < float(record["active_from_s"]) - EPSILON or (adapter["current_position"] as Vector3).distance_to(adapter["planned_endpoint"]) > Motion.ENDPOINT_TOLERANCE or velocity.length() > EPSILON or (value["collision_shortened"] and not value["actual_collided"]) or (not value["actual_collided"] and expected < float(value["distance"]) - EPSILON) or (record["opening_position"] as Vector3).distance_to(adapter["current_position"]) > EPSILON:
			return {"error": "Saved finished lunge has no coherent physical landing"}
	else:
		var expected_velocity: Vector3 = direction * float(value["speed"]) if elapsed > EPSILON else Vector3.ZERO
		if value["actual_collided"] or elapsed >= float(value["duration_s"]) + EPSILON or absf(progress - expected) > Motion.ENDPOINT_TOLERANCE or velocity.distance_to(expected_velocity) > EPSILON or (record["opening_position"] as Vector3).distance_to(adapter["planned_endpoint"]) > EPSILON:
			return {"error": "Saved running lunge clock/velocity is incoherent"}
	var adjusted: Vector3 = adapter["start"] + Vector3.UP * (float(description["foot_offset"]) - CAPSULE_CENTER_Y + CAPSULE_HEIGHT * 0.5)
	if not _floor_error(regions, adjusted).is_empty() or not _floor_path_supported(adapter["start"], adapter["planned_endpoint"], regions, float(description["radius"]) + SKIN):
		return {"error": "Saved lunge source route lacks supported actual floor"}
	return adapter


func _encode_geometry(geometry: Dictionary) -> Dictionary:
	var result: Dictionary = geometry.duplicate(true)
	for key: String in result:
		if result[key] is Vector3:
			result[key] = Codec.vector3(result[key])
	return result


func _decode_geometry(value: Dictionary) -> Dictionary:
	var keys: Array = []
	var points: Array = []
	match value.get("kind"):
		"circle":
			keys = ["kind", "origin", "radius"]
			points = ["origin"]
		"cone":
			keys = ["kind", "origin", "direction", "reach", "min_dot", "origin_radius"]
			points = ["origin", "direction"]
		"crescent":
			keys = ["kind", "origin", "direction", "inner_radius", "outer_radius", "min_dot"]
			points = ["origin", "direction"]
		"lane":
			keys = ["kind", "from", "to", "radius"]
			points = ["from", "to"]
		_:
			return {}
	if not Codec.keys_error(value, keys).is_empty():
		return {}
	var result: Dictionary = value.duplicate(true)
	for key: String in points:
		if not Codec.is_vector3(result[key]):
			return {}
		result[key] = Codec.read_vector3(result[key])
	return result if Geometry.error(result).is_empty() else {}


func _transform_data(value: Transform3D) -> Array:
	return [Codec.vector3(value.basis.x), Codec.vector3(value.basis.y), Codec.vector3(value.basis.z), Codec.vector3(value.origin)]


func _floor_signature(region: Dictionary, world_root: Node3D) -> Dictionary:
	var collision: CollisionShape3D = region["collision"]
	var body: StaticBody3D = collision.get_parent() as StaticBody3D
	var rect: Rect2 = region["safe_rect"]
	return {"path": String(world_root.get_path_to(collision)), "transform": _transform_data(collision.global_transform), "size": Codec.vector3((collision.shape as BoxShape3D).size), "layer": body.collision_layer, "mask": body.collision_mask, "safe_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]}


func _collision_signature(world_root: Node3D) -> Dictionary:
	if not is_instance_valid(world_root) or not world_root.is_inside_tree() or world_root.get_world_3d() != get_world_3d():
		return {"error": "Live same-world collision root required"}
	var colliders: Array = []
	var pending: Array[Node] = [get_tree().root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		pending.append_array(node.get_children())
		if not node is Node3D or (node as Node3D).get_world_3d() != get_world_3d():
			continue
		if node is GridMap or (node is CSGShape3D and (node as CSGShape3D).use_collision):
			return {"error": "Generated GridMap/CSG collision has no supported stable fingerprint"}
		if not node is PhysicsBody3D or ((node as PhysicsBody3D).collision_layer & 1) == 0:
			continue
		if not node is StaticBody3D or node is AnimatableBody3D or not _under_root(node, world_root):
			return {"error": "All scenery blockers must be immutable static bodies under world_root"}
		var body: StaticBody3D = node as StaticBody3D
		if body.is_queued_for_deletion() or body.constant_linear_velocity != Vector3.ZERO or body.constant_angular_velocity != Vector3.ZERO:
			return {"error": "Moving static-body collision is unsupported"}
		var path: String = String(world_root.get_path_to(body))
		if path.contains("@") or path.contains("\n") or path.contains("\r"):
			return {"error": "Scenery collider paths require stable authored node names"}
		var shapes: Array = []
		for owner_id: int in body.get_shape_owners():
			if body.is_shape_owner_disabled(owner_id):
				continue
			var owner: Object = body.shape_owner_get_owner(owner_id)
			if not owner is Node or not body.is_ancestor_of(owner as Node):
				return {"error": "Collision shape owner requires a stable authored child path"}
			var owner_path: String = String(body.get_path_to(owner as Node))
			if owner_path.contains("@") or owner_path.contains("\n") or owner_path.contains("\r"):
				return {"error": "Collision shape paths require stable authored names"}
			for shape_index: int in range(body.shape_owner_get_shape_count(owner_id)):
				var shape: Shape3D = body.shape_owner_get_shape(owner_id, shape_index)
				var data: Dictionary = _shape_data(shape)
				if data.is_empty():
					return {"error": "Unsupported scenery collision shape: " + shape.get_class()}
				shapes.append({"path": owner_path, "index": shape_index, "transform": _transform_data(body.shape_owner_get_transform(owner_id)), "data": data})
		shapes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["path"] < b["path"] or (a["path"] == b["path"] and a["index"] < b["index"]))
		colliders.append({"path": path, "transform": _transform_data(body.global_transform), "layer": body.collision_layer, "mask": body.collision_mask, "priority": body.collision_priority, "shapes": shapes})
		if colliders.size() > 256:
			return {"error": "Supported collision fingerprint exceeds 256 bodies"}
	colliders.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["path"] < b["path"])
	var signature := {"schema_version": 1, "physics_engine": ProjectSettings.get_setting("physics/3d/physics_engine", "DEFAULT"), "physics_ticks_per_second": Engine.physics_ticks_per_second, "colliders": colliders}
	var error: String = Codec.value_error(signature)
	return {"signature": signature} if error.is_empty() else {"error": error}


func _shape_data(shape: Shape3D) -> Dictionary:
	var result := {"type": shape.get_class(), "margin": shape.margin, "custom_solver_bias": shape.custom_solver_bias}
	if shape is BoxShape3D:
		result["size"] = Codec.vector3((shape as BoxShape3D).size)
	elif shape is SphereShape3D:
		result["radius"] = (shape as SphereShape3D).radius
	elif shape is CapsuleShape3D or shape is CylinderShape3D:
		result["radius"] = (shape as CapsuleShape3D).radius if shape is CapsuleShape3D else (shape as CylinderShape3D).radius
		result["height"] = (shape as CapsuleShape3D).height if shape is CapsuleShape3D else (shape as CylinderShape3D).height
	elif shape is ConvexPolygonShape3D or shape is ConcavePolygonShape3D:
		var points: PackedVector3Array = (shape as ConvexPolygonShape3D).points if shape is ConvexPolygonShape3D else (shape as ConcavePolygonShape3D).get_faces()
		var encoded: Array = []
		for point: Vector3 in points:
			encoded.append(Codec.vector3(point))
		result["points"] = encoded
		if shape is ConcavePolygonShape3D:
			result["backface_collision"] = (shape as ConcavePolygonShape3D).backface_collision
	else:
		return {}
	return result


## Opt-in authored lifecycle. These methods call only pure retained native
## source/Playback getters. They never emit, present, request, damage or yield.
## Whole-parent disposal is the supported way to discard managed history;
## begin/end_encounter refuse to silently reset its clocks or generations.
func begin_authored_cycle_tracking(owner: Node3D, sequence: Dictionary, hero: CinderPlayer, hero_id: String) -> bool:
	var error: String = _cycle_boundary_error()
	if not error.is_empty(): return _cycle_reject(error)
	if not is_instance_valid(owner) or not is_instance_valid(hero) or not _stable_id(hero_id): return _cycle_reject("Actual authored owner, shared Hero and stable Hero identity required")
	if not _authored_cycles.is_empty() and _cycle_for_owner(owner).is_empty():
		if _authored_cycles.size() >= CycleJournal.MAX_SOURCES: return _cycle_reject("Authored source capacity reached")
	if not _cycle_for_owner(owner).is_empty(): return _cycle_reject("Actual source is already managed; history cannot be reset")
	var reader = ReplayProgram.new()
	if not reader.restore_state(sequence, sequence.get("source_epoch", ""), 1) or not reader.is_authored_enemy(): return _cycle_reject("First native authored generation must be exactly one")
	var program: Dictionary = reader.snapshot_state()
	if _authored_cycles.has(program.source_id): return _cycle_reject("Stable authored source identity is already retained")
	_cycle_busy = true
	var cycle: Dictionary = _cycle_runtime(owner, hero, program, "cycle_ready", [], {}, hero_id)
	error = cycle.get("error", "")
	if error.is_empty(): error = _cycle_native_error(cycle)
	if error.is_empty(): error = _cycle_fresh_owner_error(owner)
	if error.is_empty(): error = _cycle_tracking_compatibility_error(cycle)
	if error.is_empty(): error = _cycle_identity_error(program.sequence_id, cycle.playback_id)
	if error.is_empty(): error = _cycle_capacity_error(_cycle_journal_with(cycle.entry), _cycle_reserves_with(cycle))
	if error.is_empty():
		_authored_cycles[program.source_id] = cycle
		last_error = ""
	_cycle_busy = false
	return _cycle_reject(error) if not error.is_empty() else true


func authored_cycle_state(owner: Node3D) -> Dictionary:
	## Pure six-key journal entry. In particular the source's generation hook may
	## read this without recursively authenticating itself or changing errors.
	var cycle: Dictionary = _cycle_for_owner(owner)
	return cycle.get("entry", {}).duplicate(true)


func seal_authored_cycle(owner: Node3D, receipt: Dictionary) -> bool:
	# Cancellation seals inside the Scheduler -> Playback invalidation stack.
	# That is the one allowed internal transaction: an actual tombstone must
	# already exist, and no observers are called by this handshake itself.
	if _snapshot_busy or _cycle_busy or not is_inside_tree() or _encounter_id.is_empty(): return _cycle_reject("Native terminal sealing boundary required")
	var cycle: Dictionary = _cycle_for_owner(owner)
	if cycle.is_empty(): return _cycle_reject("Actual admitted managed source required")
	var error: String = CycleReceipt.snapshot_error(receipt)
	if not error.is_empty(): return _cycle_reject(error)
	if cycle.entry.stage == "terminal":
		_cycle_busy = true
		error = _cycle_native_error(cycle, {}, "", 0, true)
		if error.is_empty(): error = _cycle_terminal_native_error(cycle)
		if error.is_empty() and not _authored_same(cycle.entry.terminal_receipts[-1], receipt): error = "Original frozen terminal history cannot be replaced"
		_cycle_busy = false
		if not error.is_empty(): return _cycle_reject(error)
		last_error = ""
		return true
	if cycle.entry.stage != "running": return _cycle_reject("Only an actually admitted generation can earn a terminal receipt")
	_cycle_busy = true
	error = _cycle_native_error(cycle, {}, "", 0, true)
	if error.is_empty():
		var actual: Variant = owner.call("get_authored_cycle_terminal_receipt")
		if not is_instance_valid(owner) or owner.get_script() != cycle.script or not actual is Dictionary or not CycleReceipt.snapshot_error(actual).is_empty() or not _authored_same(actual, receipt): error = "Passed receipt differs from actual retained native Playback terminal"
	if error.is_empty(): error = _cycle_receipt_join_error(cycle, receipt)
	var proposed: Dictionary = cycle.entry.duplicate(true)
	if error.is_empty():
		proposed.stage = "terminal"
		proposed.terminal_receipts.append(receipt.duplicate(true))
		error = CycleJournal.snapshot_error(_cycle_journal_with(proposed), _clock)
	if error.is_empty():
		# The reserved worst-case receipt includes the complete cancelled suffix.
		# Thus capacity failure cannot occur after an accepted native admission.
		var next_reserves: Dictionary = _cycle_reserves_with({"entry": proposed, "reserve": {}})
		error = _cycle_capacity_error(_cycle_journal_with(proposed), next_reserves)
	if error.is_empty():
		cycle.entry = proposed
		if receipt.outcome == "complete": _reservations.erase(cycle.reservation_id)
		cycle.reserve = {}
		last_error = ""
	_cycle_busy = false
	return _cycle_reject(error) if not error.is_empty() else true


func prepare_authored_cycle(owner: Node3D, next_sequence: Dictionary, next_playback_id: String) -> bool:
	var error: String = _cycle_boundary_error()
	if not error.is_empty(): return _cycle_reject(error)
	var cycle: Dictionary = _cycle_for_owner(owner)
	if cycle.is_empty() or cycle.entry.stage != "terminal": return _cycle_reject("Retained earned terminal generation required before next preparation")
	_cycle_busy = true
	# This deliberately authenticates the OLD actual generation before commit.
	error = _cycle_native_error(cycle)
	if error.is_empty(): error = _cycle_terminal_native_error(cycle)
	var terminal: Dictionary = cycle.entry.terminal_receipts[-1]
	if error.is_empty() and (_clock < float(terminal.terminal_at_s) or _clock < float(terminal.exchange.recovery_until_s) or _clock < float(terminal.exchange.cooldown_until_s)): error = "Original retirement, expiry and actual scheduled cooldown must be earned"
	if error.is_empty() and (not _reservations.is_empty() or _cooldowns.has(owner.get_instance_id()) or _replay_cancellations.has(terminal.exchange.id)): error = "Prior native lease/cooldown/tombstone must really expire before next preparation"
	if error.is_empty() and cycle.entry.generation >= CycleJournal.MAX_TERMINAL_RECEIPTS: error = "Authored per-source cycle capacity reached"
	var reader = ReplayProgram.new()
	if error.is_empty() and (not reader.restore_state(next_sequence, cycle.entry.source_epoch, int(cycle.entry.generation) + 1) or not reader.is_authored_enemy()): error = "Next distinct canonical authored generation required"
	var program: Dictionary = {} if not error.is_empty() else reader.snapshot_state()
	if error.is_empty() and not _cycle_same_recipe(cycle.entry.sequence, program): error = "Next cycle cannot change actual source recipe/profile/world"
	if error.is_empty(): error = _cycle_identity_error(program.sequence_id, next_playback_id)
	var proposed: Dictionary = cycle.entry.duplicate(true)
	if error.is_empty():
		proposed.generation = program.generation
		proposed.sequence = program
		proposed.stage = "cycle_ready"
		error = CycleJournal.snapshot_error(_cycle_journal_with(proposed), _clock)
	var reserve: Dictionary = {} if not error.is_empty() else _cycle_receipt_reserve(program)
	if error.is_empty(): error = _cycle_capacity_error(_cycle_journal_with(proposed), _cycle_reserves_with({"entry": proposed, "reserve": reserve}))
	if error.is_empty():
		# Playback immediately applies its new immutable Program/Cursor/ID under
		# its own transaction, without callback/yield, after this returns true.
		cycle.entry = proposed
		cycle.playback_id = next_playback_id
		cycle.exchange = {}
		cycle.reservation_id = ""
		cycle.reserve = reserve
		last_error = ""
	_cycle_busy = false
	return _cycle_reject(error) if not error.is_empty() else true


func _cycle_boundary_error() -> String:
	if _cycle_busy or _snapshot_busy or _boundary_busy or _request_busy or _transaction_depth > 0 or not is_inside_tree() or is_queued_for_deletion() or _encounter_id.is_empty() or not CycleReceipt.clock_valid(_clock): return "Actual configured Scheduler outside native transactions required"
	return ""


func _cycle_reject(error: String) -> bool:
	last_error = error
	return false


func _cycle_for_owner(owner: Node3D) -> Dictionary:
	if not is_instance_valid(owner): return {}
	for value: Dictionary in _authored_cycles.values():
		if (value.owner as WeakRef).get_ref() == owner: return value
	return {}


func _cycle_environment(owner: Node3D) -> Dictionary:
	if not owner.has_method("get_authored_cycle_environment"): return {"error": "Native lifecycle environment getter required"}
	var value: Variant = owner.call("get_authored_cycle_environment")
	if not value is Dictionary or not Codec.keys_error(value, ["world_root", "floor_regions"]).is_empty() or not value.floor_regions is Array: return {"error": "Exact retained lifecycle world/floor binding required"}
	var root_value: Variant = value.world_root
	if typeof(root_value) != TYPE_OBJECT or not is_instance_valid(root_value) or not root_value is Node3D: return {"error": "Actual retained lifecycle root required"}
	var root: Node3D = root_value
	var floor: Dictionary = authored_floor_signature(root, value.floor_regions)
	if not floor.get("accepted", false): return {"error": floor.get("reason", "Actual supported lifecycle floors required")}
	var guards: Array = _floor_guards(value.floor_regions)
	for guard: Dictionary in guards:
		var node: CollisionShape3D = (guard.node as WeakRef).get_ref()
		guard["shape_resource"] = node.shape
		guard["parent"] = weakref(node.get_parent())
	return {"world": weakref(root), "floor_guards": guards}


func _cycle_runtime(owner: Node3D, hero: CinderPlayer, program: Dictionary, stage: String, receipts: Array, exchange: Dictionary, hero_id: String, playback_id: String = "") -> Dictionary:
	if not _stable_id(hero_id): return {"error": "Retained stable Hero identity required"}
	var script: Script = _authored_owner_script(owner)
	if script == null: return {"error": "Actual shared Playback/C52 Script required"}
	if not owner.has_method("get_authored_cycle_playback_id") or not owner.has_method("get_authored_cycle_terminal_receipt") or not owner.has_method("get_authored_cycle_program"): return {"error": "Shared native lifecycle Playback getters required"}
	var actual_id: Variant = owner.call("get_authored_cycle_playback_id")
	if not is_instance_valid(owner): return {"error": "Native owner was freed during pure identity getter"}
	if not _stable_id(playback_id if not playback_id.is_empty() else actual_id): return {"error": "Actual stable lifecycle Playback identity required"}
	var environment: Dictionary = _cycle_environment(owner)
	if environment.has("error"): return environment
	if not is_instance_valid(owner) or not is_instance_valid(hero) or owner.get_script() != script: return {"error": "Native source/Hero/Script custody changed during pure environment getter"}
	return {"entry": {"source_id": program.source_id, "source_epoch": program.source_epoch, "generation": program.generation, "stage": stage, "sequence": program.duplicate(true), "terminal_receipts": receipts.duplicate(true)}, "owner": weakref(owner), "hero": weakref(hero), "script": script, "world": environment.world, "floor_guards": environment.floor_guards, "playback_id": actual_id if playback_id.is_empty() else playback_id, "exchange": exchange.duplicate(true), "reservation_id": exchange.get("id", ""), "hero_id": hero_id, "reserve": _cycle_receipt_reserve(program) if stage != "terminal" else {}}


func _cycle_regions(cycle: Dictionary) -> Array:
	return _authored_regions({"_floor_guards": cycle.floor_guards})


func _cycle_context(cycle: Dictionary) -> Dictionary:
	var program: Dictionary = cycle.entry.sequence
	return {"world_root": (cycle.world as WeakRef).get_ref(), "source_id": cycle.entry.source_id, "source_epoch": cycle.entry.source_epoch, "generation": cycle.entry.generation, "world_collision_fingerprint": program.world.collision_fingerprint, "world_floor_signature": program.world.floor_signature}


func _cycle_native_error(cycle: Dictionary, staged: Dictionary = {}, profile_id: String = "", revision: int = 0, allow_defeated: bool = false, staged_playback_id: String = "") -> String:
	var owner_value: Variant = (cycle.owner as WeakRef).get_ref()
	var hero_value: Variant = (cycle.hero as WeakRef).get_ref()
	if not is_instance_valid(owner_value) or not owner_value is Node3D or not is_instance_valid(hero_value) or not hero_value is CinderPlayer: return "Retained actual authored source/Hero was freed"
	var owner: Node3D = owner_value
	var hero: CinderPlayer = hero_value
	if owner.get_script() != cycle.script or cycle.script == null: return "Retained authored native Script changed"
	var context: Dictionary = _cycle_context(cycle)
	var error: String = _replay_context_error(owner, hero, _captured_context(context))
	if not error.is_empty(): return error
	var environment: Dictionary = _cycle_environment(owner)
	if environment.has("error") or (environment.world as WeakRef).get_ref() != context.world_root: return "Retained lifecycle environment changed"
	if not _cycle_floor_identity_valid(cycle.floor_guards) or _cycle_regions(cycle).is_empty(): return "Retained lifecycle native floors changed"
	var actual_floor: Dictionary = authored_floor_signature(context.world_root, _authored_regions({"_floor_guards": environment.floor_guards}))
	if not actual_floor.get("accepted", false) or not _authored_same(actual_floor.signature, context.world_floor_signature): return "Native lifecycle floor bindings changed"
	error = authored_replay_source_error(owner, cycle.entry.sequence, context, _cycle_regions(cycle), profile_id, revision, staged, allow_defeated)
	if not error.is_empty(): return error
	if staged.is_empty():
		var actual_program: Variant = owner.call("get_authored_cycle_program")
		if not actual_program is Dictionary or not _authored_same(actual_program, cycle.entry.sequence): return "Actual immutable current Playback Program differs from managed entry"
	if not is_instance_valid(owner) or owner.get_script() != cycle.script or not is_instance_valid(hero): return "Native lifecycle custody changed during pure Program getter"
	var actual_id: Variant = owner.call("get_authored_cycle_playback_id")
	if not _stable_id(actual_id) or (staged_playback_id.is_empty() and actual_id != cycle.playback_id) or (not staged_playback_id.is_empty() and staged_playback_id != cycle.playback_id): return "Current native/staged lifecycle Playback identity changed"
	if not is_instance_valid(owner) or owner.get_script() != cycle.script or not is_instance_valid(hero): return "Native lifecycle custody changed during pure getters"
	return ""


func _cycle_same_recipe(left: Dictionary, right: Dictionary) -> bool:
	for key: String in ["source_id", "source_epoch", "profile_id", "definition", "resolved_role", "world", "authored"]:
		if not _authored_same(left.get(key), right.get(key)): return false
	return true


func _cycle_tracking_compatibility_error(candidate: Dictionary) -> String:
	# One complete native aggregate has one retained Hero, root and immutable
	# floor domain. Registration never creates separately saveable sub-worlds or
	# substitutes equivalent collider resources for an existing source's domain.
	var hero: Variant = (candidate.hero as WeakRef).get_ref()
	var world: Variant = (candidate.world as WeakRef).get_ref()
	for retained: Dictionary in _authored_cycles.values():
		if (retained.hero as WeakRef).get_ref() != hero or retained.hero_id != candidate.hero_id: return "Tracked authored sources require the same actual retained Hero and stable identity"
		if (retained.world as WeakRef).get_ref() != world: return "Tracked authored sources require the same exact actual world root"
		if not _authored_same(retained.entry.sequence.profile_id, candidate.entry.sequence.profile_id) or not _authored_same(retained.entry.sequence.world, candidate.entry.sequence.world): return "Tracked authored sources require the same fixed profile/world/full floor descriptor"
		if not _cycle_same_floor_custody(retained.floor_guards, candidate.floor_guards): return "Tracked authored sources require the same actual floor nodes/resources/parents and exact domain"
		var error: String = _cycle_native_error(retained, {}, "", 0, retained.entry.stage != "running")
		if not error.is_empty(): return "Existing tracked native custody is unavailable: " + error
		if retained.entry.stage == "running":
			var record: Dictionary = _reservations.get(retained.reservation_id, {})
			if record.is_empty(): return "Existing tracked running source lost its original actual lease"
			error = _cycle_live_lease_error(record)
		elif retained.entry.stage == "terminal":
			error = _cycle_terminal_native_error(retained)
		if not error.is_empty(): return "Existing tracked native history is unavailable: " + error
	# Prior pure native getters must not invalidate the proposed source before
	# its first history/identity/reserve commit. No callbacks or cleanup occur.
	return _cycle_native_error(candidate)


func _cycle_same_floor_custody(left: Array, right: Array) -> bool:
	if left.size() != right.size(): return false
	var used: Dictionary = {}
	for prior: Dictionary in left:
		var collision: Variant = (prior.node as WeakRef).get_ref()
		var parent: Variant = (prior.parent as WeakRef).get_ref()
		if not is_instance_valid(collision) or not collision is CollisionShape3D or not is_instance_valid(parent) or not is_instance_valid(prior.shape_resource): return false
		var matched: bool = false
		for index: int in range(right.size()):
			if used.has(index): continue
			var next: Dictionary = right[index]
			if (next.node as WeakRef).get_ref() != collision or (next.parent as WeakRef).get_ref() != parent or next.shape_resource != prior.shape_resource: continue
			var prior_rect: Rect2 = prior.safe_rect
			var next_rect: Rect2 = next.safe_rect
			if not _authored_same(_transform_data(prior.transform), _transform_data(next.transform)) or not _authored_same(Codec.vector3(prior.size), Codec.vector3(next.size)) or not _authored_same([prior_rect.position.x, prior_rect.position.y, prior_rect.size.x, prior_rect.size.y], [next_rect.position.x, next_rect.position.y, next_rect.size.x, next_rect.size.y]): return false
			used[index] = true
			matched = true
			break
		if not matched: return false
	return true


func _cycle_identity_error(sequence_id: String, playback_id: String, excluding_source: String = "") -> String:
	if not _stable_id(sequence_id) or not _stable_id(playback_id): return "Fresh stable authored sequence/Playback identities required"
	for cycle: Dictionary in _authored_cycles.values():
		if cycle.entry.source_id != excluding_source and (cycle.entry.sequence.sequence_id == sequence_id or cycle.playback_id == playback_id): return "Authored current identity is already retained"
		for receipt: Dictionary in cycle.entry.terminal_receipts:
			if receipt.sequence.sequence_id == sequence_id or receipt.playback_id == playback_id: return "Authored retired identity cannot be reused"
	return ""


func _cycle_admission_error(owner: Node3D, sequence: Dictionary, response: Dictionary, context: Dictionary) -> String:
	var cycle: Dictionary = _cycle_for_owner(owner)
	if cycle.is_empty():
		return "Managed source identity cannot be rebound" if _authored_cycles.has(context.get("source_id", "")) else ""
	if cycle.entry.stage != "cycle_ready" or not _authored_same(sequence, cycle.entry.sequence) or response.get("actor") != (cycle.hero as WeakRef).get_ref(): return "Admission must consume this actual managed ready Program and same Hero"
	var error: String = _cycle_native_error(cycle)
	if not error.is_empty(): return error
	if not _same_replay_context(_cycle_context(cycle), context): return "Managed authored admission world/cycle context differs"
	var floor: Dictionary = authored_floor_signature(context.world_root, response.get("floor_regions", []))
	if not floor.get("accepted", false) or not _authored_same(floor.signature, cycle.entry.sequence.world.floor_signature): return "Managed request floor bindings changed"
	if _serial >= Codec.MAX_SAFE_INTEGER: return "Authored reservation serial exhausted"
	if not cycle.entry.terminal_receipts.is_empty():
		var previous: Dictionary = cycle.entry.terminal_receipts[-1]
		if _clock < float(previous.terminal_at_s) or _clock < float(previous.exchange.cooldown_until_s) or _clock < float(previous.exchange.recovery_until_s): return "Managed source has not earned original terminal/cooldown expiry"
	return _cycle_capacity_error(_cycle_journal_with(), _cycle_reserves_with())


func _cycle_admitted(owner: Node3D, record: Dictionary) -> void:
	var cycle: Dictionary = _cycle_for_owner(owner)
	if cycle.is_empty(): return
	cycle.entry.stage = "running"
	cycle.exchange = _cycle_exchange(record)
	cycle.reservation_id = record.id


func _cycle_exchange_changed(record: Dictionary) -> void:
	if not _is_authored_replay(record): return
	var source_id: String = record.adapter.source_id
	if not _authored_cycles.has(source_id): return
	var cycle: Dictionary = _authored_cycles[source_id]
	if cycle.entry.stage == "running" and cycle.reservation_id == record.id and (cycle.owner as WeakRef).get_ref() == (record._owner as WeakRef).get_ref(): cycle.exchange = _cycle_exchange(record)


func _cycle_exchange(record: Dictionary) -> Dictionary:
	var value: Dictionary = {"id": record.id, "source_position": Codec.vector3(record.source_position), "opening_position": Codec.vector3(record.opening_position), "adapter": _encode_adapter(record.adapter)}
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision"]: value[key] = record[key]
	return value


func _cycle_closed_tombstone(value: Dictionary, hero_id: String) -> Dictionary:
	var result: Dictionary = value.duplicate(true)
	for key: String in ["_owner", "_replay_actor", "_authored_source_script", "source_instance_id", "response_actor_instance_id"]: result.erase(key)
	result["response_actor_id"] = hero_id
	return result


func _cycle_receipt_join_error(cycle: Dictionary, receipt: Dictionary) -> String:
	if not _authored_same(receipt.sequence, cycle.entry.sequence) or receipt.source_id != cycle.entry.source_id or receipt.source_epoch != cycle.entry.source_epoch or receipt.generation != cycle.entry.generation or receipt.playback_id != cycle.playback_id or receipt.exchange.id != cycle.reservation_id or not _authored_same(receipt.exchange, cycle.exchange) or not _authored_same(receipt.terminal_at_s, _clock): return "Terminal receipt differs from original actual admitted exchange/cycle/clock"
	if receipt.hero_id != cycle.hero_id: return "Terminal target stable identity changed"
	if receipt.outcome == "cancelled":
		var tombstone: Dictionary = _replay_cancellations.get(cycle.reservation_id, {})
		if tombstone.is_empty() or _clock >= float(tombstone.cooldown_until_s) or (tombstone._owner as WeakRef).get_ref() != (cycle.owner as WeakRef).get_ref() or (tombstone._replay_actor as WeakRef).get_ref() != (cycle.hero as WeakRef).get_ref() or not _authored_same(_cycle_closed_tombstone(tombstone, receipt.hero_id), receipt.cancellation): return "Cancellation sealing requires its actual original unexpired target tombstone"
	elif _clock < float(cycle.exchange.recovery_until_s) or _reservations.has(cycle.reservation_id):
		# Completion may occur at the exact recovery deadline before next prune.
		if _clock < float(cycle.exchange.recovery_until_s) or not _authored_same(_cycle_exchange(_reservations[cycle.reservation_id]), cycle.exchange): return "Completion must earn the original real recovery deadline"
	var owner: Node3D = (cycle.owner as WeakRef).get_ref()
	var cooldown: Dictionary = _cooldowns.get(owner.get_instance_id(), {})
	if _clock < float(cycle.exchange.cooldown_until_s):
		if cooldown.is_empty() or not _authored_same(cooldown.ready_s, cycle.exchange.cooldown_until_s): return "Original terminal source cooldown changed"
	elif not cooldown.is_empty(): return "Expired terminal source cooldown cannot be refreshed"
	return ""


func _cycle_journal_with(replacement: Dictionary = {}) -> Dictionary:
	var sources: Array = []
	var replaced: bool = false
	for cycle: Dictionary in _authored_cycles.values():
		if not replacement.is_empty() and cycle.entry.source_id == replacement.source_id:
			sources.append(replacement.duplicate(true)); replaced = true
		else: sources.append(cycle.entry.duplicate(true))
	if not replacement.is_empty() and not replaced: sources.append(replacement.duplicate(true))
	return {"api_revision": CycleJournal.API_REVISION, "schema_version": 1, "sources": sources}


func _cycle_reserves_with(replacement: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {}
	for source_id: String in _authored_cycles: result[source_id] = _authored_cycles[source_id].reserve.duplicate(true)
	if not replacement.is_empty(): result[replacement.entry.source_id] = replacement.reserve.duplicate(true)
	return result


func _cycle_measure(value: Variant, depth: int = 0) -> Dictionary:
	# Called only after Receipt.transport_error bounded the complete tree.
	var result: Dictionary = {"nodes": 1, "walk_bytes": 16, "depth": depth}
	if value is String: result.walk_bytes += value.to_utf8_buffer().size()
	elif value is Array or value is Dictionary:
		var children: Array = value if value is Array else []
		if value is Dictionary:
			for key: String in value: children.append(key); children.append(value[key])
		for child: Variant in children:
			var size: Dictionary = _cycle_measure(child, depth + 1)
			result.nodes += size.nodes; result.walk_bytes += size.walk_bytes; result.depth = maxi(result.depth, size.depth)
	return result


func _cycle_receipt_reserve(program: Dictionary) -> Dictionary:
	# Non-authoritative SIZE skeleton only; never validated/restored/admitted.
	# Every supported terminal may retain four whole programs (receipt, exchange,
	# cursor, cancellation). Exact floats always encode 16 hex digits. Closed
	# one-slash prefix/suffix and all stable IDs are conservatively maximal.
	var id: String = "x".repeat(128)
	var event_id: String = program.timeline.slots[0].events[0].event_id
	var reason: String = String.chr(1).repeat(512) # Worst JSON escaping per char.
	var clock_s: float = CycleReceipt.MAX_CLOCK_S
	var adapter: Dictionary = {"kind": "authored_replay", "locked": true, "sequence": program, "source_id": id, "source_epoch": id, "generation": 64, "world_collision_fingerprint": program.world.collision_fingerprint, "world_floor_signature": program.world.floor_signature, "timeline_origin_s": clock_s, "max_dispatch_delay_s": clock_s}
	var exchange: Dictionary = {"id": "threat-9007199254740991", "source_position": [clock_s, clock_s, clock_s], "opening_position": [clock_s, clock_s, clock_s], "adapter": adapter, "profile_id": id, "world_revision": Codec.MAX_SAFE_INTEGER}
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]: exchange[key] = clock_s
	var prefix: Array = [{"event_id": event_id, "scheduled_at_s": clock_s, "dispatch_clock_s": clock_s}]
	var cursor: Dictionary = {"api_revision": "authored-echo-cursor-1", "schema_version": 1, "sequence": program, "source_epoch": id, "generation": 64, "configured_at_s": clock_s, "armed": true, "armed_at_s": clock_s, "timeline_origin_s": clock_s, "last_advanced_clock_s": clock_s, "phase": "recovery", "next_event_index": 1, "executed_events": prefix}
	var cancellation: Dictionary = {"kind": "authored_replay", "id": exchange.id, "source_id": id, "response_actor_id": id, "sequence_id": id, "source_epoch": id, "generation": 64, "sequence": program, "world_collision_fingerprint": program.world.collision_fingerprint, "world_floor_signature": program.world.floor_signature, "profile_id": id, "world_revision": Codec.MAX_SAFE_INTEGER, "timeline_origin_s": clock_s, "locked": true, "max_dispatch_delay_s": clock_s, "cancelled_at_s": clock_s, "reason": reason}
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]: cancellation[key] = clock_s
	var terminal: Dictionary = {"api_revision": CycleReceipt.API_REVISION, "schema_version": 1, "playback_id": id, "source_id": id, "hero_id": id, "source_epoch": id, "generation": 64, "sequence": program, "exchange": exchange, "outcome": "cancelled", "reason": reason, "terminal_at_s": clock_s, "cursor_clock_s": clock_s, "cursor": cursor, "opportunities": [{"event_id": event_id, "hero_id": id, "scheduled_at_s": clock_s, "dispatch_clock_s": clock_s, "contact": true, "damage_attempted": true}], "pending_delivery": {"events": [{"event_index": 0, "stage": "present"}], "visual_next_cue": 0, "visuals_pending": false, "state_pending": false, "cue_phases": ["clear"]}, "cancellation": cancellation}
	var measure: Dictionary = _cycle_measure(terminal)
	var table_measure: Dictionary = _cycle_measure(cancellation)
	# Raw UTF8 walk allows 4 bytes/character even when control escaping maximizes
	# encoded wire bytes. Both reason copies reserve that independent maximum.
	var wire: String = PreviewExact.stringify(terminal)
	return {"bytes": CycleReceipt.MAX_BYTES + 1 if wire.is_empty() else wire.to_utf8_buffer().size() + PreviewExact.stringify(cancellation).to_utf8_buffer().size() + 512, "nodes": int(measure.nodes) + int(table_measure.nodes) + 16, "walk_bytes": int(measure.walk_bytes) + int(table_measure.walk_bytes) + 4608 + 256, "depth": int(measure.depth) + 4}


func _cycle_capacity_error(journal: Dictionary, reserves: Dictionary) -> String:
	var error: String = CycleReceipt.transport_error(journal)
	if not error.is_empty(): return error
	var measured: Dictionary = _cycle_measure(journal)
	var bytes: int = PreviewExact.stringify(journal).to_utf8_buffer().size()
	# Reserve additional fixed native world/profile/envelope overhead beyond the
	# Journal itself. The whole aggregate separately obeys ExactJson bounds;
	# this prototype makes no concurrent mixed-encounter capacity promise.
	if not journal.sources.is_empty():
		var outer: Dictionary = {"collision": journal.sources[0].sequence.world.collision_fingerprint, "profile": _difficulty.profile(journal.sources[0].sequence.profile_id)}
		var outer_size: Dictionary = _cycle_measure(outer)
		bytes += PreviewExact.stringify(outer).to_utf8_buffer().size() + 8192
		measured.nodes += int(outer_size.nodes) + 512
		measured.walk_bytes += int(outer_size.walk_bytes) + 8192
	# A currently cancelled terminal still needs its ordinary pre-expiry table
	# copy. Reserve it conservatively even after expiry; advancing the clock never
	# makes a previously accepted history exceed its capacity.
	for entry: Dictionary in journal.sources:
		if entry.stage == "terminal" and entry.terminal_receipts[-1].outcome == "cancelled":
			var cancellation: Dictionary = entry.terminal_receipts[-1].cancellation
			var cancellation_size: Dictionary = _cycle_measure(cancellation)
			bytes += PreviewExact.stringify(cancellation).to_utf8_buffer().size() + 128
			measured.nodes += int(cancellation_size.nodes) + 4
			measured.walk_bytes += int(cancellation_size.walk_bytes) + 64
	for reserve: Dictionary in reserves.values():
		if reserve.is_empty(): continue
		bytes += int(reserve.bytes)
		measured.nodes += int(reserve.nodes)
		measured.walk_bytes += int(reserve.walk_bytes)
		measured.depth = maxi(int(measured.depth), int(reserve.depth))
	if bytes > CycleReceipt.MAX_BYTES or int(measured.nodes) > CycleReceipt.MAX_NODES or int(measured.walk_bytes) > CycleReceipt.MAX_BYTES or int(measured.depth) + 1 > CycleReceipt.MAX_DEPTH: return "Authored journal cannot reserve worst terminal bytes/walk/depth before admission"
	return ""


func _cycle_capture(bindings: Dictionary) -> Dictionary:
	var journal: Dictionary = _cycle_journal_with()
	if not bindings.get("actors") is Dictionary or bindings.actors.size() != 1:
		last_snapshot_error = "Managed authored history requires exactly one actual stable Hero mapping"
		return {}
	for cycle: Dictionary in _authored_cycles.values():
		var owner: Node3D = (cycle.owner as WeakRef).get_ref()
		var hero: CinderPlayer = (cycle.hero as WeakRef).get_ref()
		var source_id: String = _binding_id(bindings.owners, owner)
		var hero_id: String = _binding_id(bindings.actors, hero)
		if source_id != cycle.entry.source_id or hero_id.is_empty() or hero_id != cycle.hero_id or bindings.world_root != (cycle.world as WeakRef).get_ref():
			last_snapshot_error = "Managed source/Hero/world bindings changed"
			return {}
		last_snapshot_error = _cycle_native_error(cycle, {}, "", 0, cycle.entry.stage != "running")
		if not last_snapshot_error.is_empty(): return {}
		if cycle.entry.stage == "terminal":
			last_snapshot_error = _cycle_terminal_native_error(cycle)
			if not last_snapshot_error.is_empty() and _cycle_restore_capture_owner != null:
				# During the explicit whole-packet restore check, every still-prepared
				# terminal recipient must supply its own exact native recipe. No
				# foreign receipt or caller map substitutes another source's getter.
				last_snapshot_error = _cycle_restore_recipe_error(cycle)
			if not last_snapshot_error.is_empty(): return {}
		for receipt: Dictionary in cycle.entry.terminal_receipts:
			if receipt.hero_id != hero_id:
				last_snapshot_error = "Historical target identity differs from actual retained Hero"
				return {}
	last_snapshot_error = CycleJournal.snapshot_error(journal, _clock)
	if last_snapshot_error.is_empty(): last_snapshot_error = _cycle_capacity_error(journal, _cycle_reserves_with())
	return journal if last_snapshot_error.is_empty() else {}


func _cycle_snapshot_plan(snapshot: Dictionary, bindings: Dictionary) -> Dictionary:
	# Bound the foreign journal before any deep copy or generic codec recursion.
	if not snapshot.get("schema_version") is int or snapshot.schema_version != 3 or not snapshot.get("authored_source_cycles") is Dictionary or not snapshot.get("clock_s") is float or not CycleReceipt.clock_valid(snapshot.clock_s): return {"error": "Exact conditional Scheduler schema3 and nonempty authored source journal required"}
	if PreviewExact.stringify(snapshot).is_empty(): return {"error": "Whole Scheduler3 packet exceeds exact aggregate depth/node/byte bounds"}
	var transport_error: String = Codec.value_error(snapshot)
	if not transport_error.is_empty(): return {"error": transport_error}
	var binding_error: String = _cycle_bindings_native_error(bindings)
	if not binding_error.is_empty(): return {"error": binding_error}
	var journal: Dictionary = snapshot.authored_source_cycles
	var error: String = CycleJournal.snapshot_error(journal, snapshot.clock_s)
	if not error.is_empty(): return {"error": error}
	if journal.sources.is_empty(): return {"error": "Empty journal cannot select Scheduler schema3"}
	var ordinary: Dictionary = snapshot.duplicate(true)
	ordinary.erase("authored_source_cycles")
	var has_authored: bool = false
	for value: Variant in ordinary.get("reservations", []):
		if value is Dictionary and _is_authored_replay(value): has_authored = true
	for value: Variant in ordinary.get("replay_cancellations", []):
		if value is Dictionary and value.get("kind") == "authored_replay": has_authored = true
	ordinary.schema_version = 2 if has_authored else 1
	# Old branches are delegated exactly as before. Schema3 additionally forces
	# exact scalar/profile/collision identity even after its tables have expired.
	var plan: Dictionary = _snapshot_plan_ordinary(ordinary, bindings)
	if plan.has("error"): return plan
	if snapshot.encounter_id.is_empty() or not snapshot.world_revision is int or not snapshot.serial is int or not _authored_same(snapshot.profile, _difficulty.profile(snapshot.profile.get("id", ""))) or not _authored_same(snapshot.collision, pure_collision_fingerprint(bindings.world_root)): return {"error": "Managed history retains its exact native encounter/profile/world/clock"}
	if not bindings.get("actors") is Dictionary or bindings.actors.size() != 1: return {"error": "Managed history requires one complete actual stable Hero mapping"}
	if bindings.has("authored_cycle_playback_ids"):
		if not bindings.authored_cycle_playback_ids is Dictionary: return {"error": "Validated staged lifecycle Playback IDs must be a stable map"}
		for source_id: Variant in bindings.authored_cycle_playback_ids:
			if not bindings.owners.has(source_id) or not _stable_id(bindings.authored_cycle_playback_ids[source_id]): return {"error": "Staged lifecycle Playback ID requires its actual mapped source"}
	for value: Variant in snapshot.cooldowns:
		if not value is Dictionary or not value.get("ready_s") is float: return {"error": "Managed Scheduler cooldown copies retain exact native float types"}
	var hero_id: String = bindings.actors.keys()[0]
	var hero: CinderPlayer = bindings.actors[hero_id]
	var cycles: Dictionary = {}
	var playback_ids: Dictionary = {}
	var max_serial: int = 0
	for entry: Dictionary in journal.sources:
		if not bindings.owners.has(entry.source_id): return {"error": "Journal source has no actual native owner binding"}
		var owner: Node3D = bindings.owners[entry.source_id]
		var staged: Dictionary = bindings.get("authored_owner_bindings", {}).get(entry.source_id, {})
		var staged_id: String = bindings.get("authored_cycle_playback_ids", {}).get(entry.source_id, "")
		var exchange: Dictionary = {}
		if entry.stage == "running":
			for record: Dictionary in plan.reservations.values():
				if _is_authored_replay(record) and record.adapter.source_id == entry.source_id:
					if not exchange.is_empty(): return {"error": "Running cycle has duplicated live authored leases"}
					exchange = _cycle_exchange(record)
					if (record._replay_actor as WeakRef).get_ref() != hero or not _authored_same(record.adapter.sequence, entry.sequence): return {"error": "Running live lease must match exact current journal/Hero"}
			if exchange.is_empty(): return {"error": "Running journal needs its actual unexpired current authored lease"}
		elif entry.stage == "terminal":
			exchange = entry.terminal_receipts[-1].exchange
		var cycle: Dictionary = _cycle_runtime(owner, hero, entry.sequence, entry.stage, entry.terminal_receipts, exchange, hero_id, staged_id)
		if cycle.has("error"): return cycle
		error = _cycle_native_error(cycle, staged, snapshot.profile.id, snapshot.world_revision, entry.stage != "running", staged_id)
		if not error.is_empty(): return {"error": error}
		if (cycle.world as WeakRef).get_ref() != bindings.world_root: return {"error": "Journal must retain the complete same actual world root"}
		var floor: Dictionary = authored_floor_signature(bindings.world_root, bindings.floors.values())
		if not floor.get("accepted", false) or not _authored_same(floor.signature, entry.sequence.world.floor_signature): return {"error": "Journal requires complete exact original floor map"}
		if playback_ids.has(cycle.playback_id): return {"error": "Current lifecycle Playback IDs must be globally fresh"}
		playback_ids[cycle.playback_id] = true
		for receipt: Dictionary in entry.terminal_receipts:
			if receipt.hero_id != hero_id: return {"error": "Every historical cycle retains the same actual mapped Hero"}
			if receipt.playback_id == cycle.playback_id and not (entry.stage == "terminal" and receipt.generation == entry.generation): return {"error": "Ready/running Playback cannot reuse any historical ID"}
			max_serial = maxi(max_serial, int(receipt.exchange.id.substr(7)))
		if entry.stage == "terminal":
			error = _cycle_terminal_tables_error(cycle, plan, hero_id)
			if not error.is_empty(): return {"error": error}
		elif entry.stage == "cycle_ready":
			if plan.cooldowns.has(owner.get_instance_id()): return {"error": "Prepared current generation cannot invent its own cooldown"}
			for value: Dictionary in plan.replay_cancellations.values():
				if value.source_id == entry.source_id: return {"error": "Prepared generation cannot retain prior unexpired cancellation"}
		for record: Dictionary in plan.reservations.values():
			if int(record.source_instance_id) == owner.get_instance_id() and (entry.stage != "running" or record.id != exchange.id): return {"error": "Only the exact running authored lease may belong to a managed source"}
		var current: Dictionary = _authored_cycles.get(entry.source_id, {})
		if not current.is_empty() and ((current.owner as WeakRef).get_ref() != owner or (current.hero as WeakRef).get_ref() != hero or current.script != cycle.script or current.hero_id != hero_id or not _authored_same(current.entry, entry) or current.playback_id != cycle.playback_id): return {"error": "Same-instance restore cannot replace native custody or rewind managed history"}
		cycles[entry.source_id] = cycle
	for cycle: Dictionary in cycles.values():
		for receipt: Dictionary in cycle.entry.terminal_receipts:
			if playback_ids.has(receipt.playback_id) and not (cycle.entry.stage == "terminal" and receipt.generation == cycle.entry.generation and receipt.playback_id == cycle.playback_id): return {"error": "Current source reused another source's retired Playback identity"}
	if not _authored_cycles.is_empty() and cycles.size() != _authored_cycles.size(): return {"error": "Same-instance restore cannot omit retained source history"}
	if max_serial > int(snapshot.serial): return {"error": "Scheduler serial cannot precede any retired threat identity"}
	# Every live/cancelled authored lease of a tracked owner must join the current
	# journal. Historical receipts are never inserted into live tables to validate.
	for value: Dictionary in plan.replay_cancellations.values():
		if value.get("kind") == "authored_replay" and cycles.has(value.source_id) and (cycles[value.source_id].entry.stage != "terminal" or cycles[value.source_id].reservation_id != value.id): return {"error": "Managed cancellation lacks its exact current terminal journal"}
	var reserves: Dictionary = {}
	for source_id: String in cycles: reserves[source_id] = cycles[source_id].reserve
	error = _cycle_capacity_error(journal, reserves)
	if not error.is_empty(): return {"error": error}
	plan["authored_cycles"] = cycles
	return plan


func _cycle_terminal_tables_error(cycle: Dictionary, plan: Dictionary, hero_id: String) -> String:
	var receipt: Dictionary = cycle.entry.terminal_receipts[-1]
	var instance_id: int = ((cycle.owner as WeakRef).get_ref() as Node3D).get_instance_id()
	var clock_s: float = plan.clock_s
	var cooldown: Dictionary = plan.cooldowns.get(instance_id, {})
	if clock_s < float(receipt.exchange.cooldown_until_s):
		if cooldown.is_empty() or not _authored_same(cooldown.ready_s, receipt.exchange.cooldown_until_s): return "Terminal journal lost its original unexpired source cooldown"
	elif not cooldown.is_empty(): return "Expired terminal history cannot refresh a cooldown"
	var cancellation: Dictionary = plan.replay_cancellations.get(receipt.exchange.id, {})
	if receipt.outcome == "cancelled" and clock_s < float(receipt.exchange.cooldown_until_s):
		if cancellation.is_empty() or not _authored_same(_cycle_closed_tombstone(cancellation, hero_id), receipt.cancellation): return "Terminal journal needs its exact original unexpired cancellation"
	elif not cancellation.is_empty(): return "Complete/expired history cannot invent a cancellation"
	return ""


func _cycle_live_lease_error(record: Dictionary) -> String:
	var cycle: Dictionary = _authored_cycles.get(record.adapter.source_id, {})
	if cycle.is_empty(): return ""
	if cycle.entry.stage != "running" or cycle.reservation_id != record.id or (cycle.owner as WeakRef).get_ref() != (record._owner as WeakRef).get_ref() or (cycle.hero as WeakRef).get_ref() != (record._replay_actor as WeakRef).get_ref() or not _authored_same(cycle.entry.sequence, record.adapter.sequence) or not _authored_same(cycle.exchange, _cycle_exchange(record)): return "Actual current authored lease differs from managed journal/custody"
	return _cycle_native_error(cycle)


func _cycle_floor_identity_valid(guards: Array) -> bool:
	if not _guards_valid(guards): return false
	for guard: Dictionary in guards:
		var value: Variant = (guard.node as WeakRef).get_ref()
		if not is_instance_valid(value) or not value is CollisionShape3D: return false
		var collision: CollisionShape3D = value
		if collision.shape != guard.get("shape_resource") or collision.get_parent() != (guard.parent as WeakRef).get_ref(): return false
	return true


func _cycle_terminal_native_error(cycle: Dictionary) -> String:
	var owner_value: Variant = (cycle.owner as WeakRef).get_ref()
	if not is_instance_valid(owner_value) or not owner_value is Node3D: return "Native terminal owner was freed"
	var actual: Variant = owner_value.call("get_authored_cycle_terminal_receipt")
	if not is_instance_valid(owner_value) or owner_value.get_script() != cycle.script or not actual is Dictionary or not CycleReceipt.snapshot_error(actual).is_empty() or not _authored_same(actual, cycle.entry.terminal_receipts[-1]): return "Actual retained original terminal/pending receipt changed"
	return ""


func _cycle_bindings_native_error(bindings: Dictionary) -> String:
	# Schema3 only: test Variant validity BEFORE native casts in legacy helpers.
	var root: Variant = bindings.get("world_root")
	if typeof(root) != TYPE_OBJECT or not is_instance_valid(root) or not root is Node3D: return "Actual complete lifecycle world root required"
	if not bindings.get("owners") is Dictionary or not bindings.get("actors") is Dictionary or bindings.actors.size() != 1 or not bindings.get("floors") is Dictionary or bindings.floors.is_empty() or bindings.floors.size() > 32: return "Complete actual owner/floor/single-Hero lifecycle maps required"
	for value: Variant in bindings.owners.values():
		if typeof(value) != TYPE_OBJECT or not is_instance_valid(value) or not value is Node3D: return "Lifecycle owner binding is freed or unsupported"
	for value: Variant in bindings.actors.values():
		if typeof(value) != TYPE_OBJECT or not is_instance_valid(value) or not value is CinderPlayer: return "Lifecycle Hero binding is freed or unsupported"
	for value: Variant in bindings.floors.values():
		if not value is Dictionary: return "Native lifecycle floor region required"
		var collision: Variant = value.get("collision")
		if typeof(collision) != TYPE_OBJECT or not is_instance_valid(collision) or not collision is CollisionShape3D: return "Lifecycle floor collider is freed or unsupported"
	return ""


func _cycle_fresh_owner_error(owner: Node3D) -> String:
	if _cooldowns.has(owner.get_instance_id()): return "Only a genuinely fresh source can register initial generation one"
	for record: Dictionary in _reservations.values():
		if int(record.source_instance_id) == owner.get_instance_id(): return "Initial tracking cannot adopt an already admitted native lease"
	for value: Dictionary in _replay_cancellations.values():
		if int(value.source_instance_id) == owner.get_instance_id(): return "Initial tracking cannot erase retained legacy admission history"
	var state: Variant = owner.call("state")
	if not is_instance_valid(owner): return "Initial native source was freed during its pure state getter"
	var terminal: Variant = owner.call("get_authored_cycle_terminal_receipt")
	if not is_instance_valid(owner) or not state is Dictionary or state.get("status") not in ["idle", "cycle_ready"] or (not state.get("reservation_id", "") is String or not state.get("reservation_id", "").is_empty()) or not terminal is Dictionary or not terminal.is_empty(): return "Actual initial Playback must be unadmitted and have no previous terminal receipt"
	return ""


func _cycle_cancel_before_observers(record: Dictionary, reason: String) -> void:
	if not _is_authored_replay(record) or not _authored_cycles.has(record.adapter.source_id): return
	var cycle: Dictionary = _authored_cycles[record.adapter.source_id]
	var owner_value: Variant = (cycle.owner as WeakRef).get_ref()
	if not is_instance_valid(owner_value) or not owner_value is Node3D or owner_value.get_script() != cycle.script or not owner_value.has_method("seal_authored_cycle_cancellation"):
		last_error = "Actual managed owner cannot silently seal cancellation before observers"
		return
	# New shared Playback hook freezes original inert terminal state and invokes
	# seal_authored_cycle, without signals, presentation or yield. The later
	# ordinary invalidation signal publishes once-only terminal observers.
	var sealed: Variant = owner_value.call("seal_authored_cycle_cancellation", record.id, reason)
	if not sealed is bool or not sealed or not is_instance_valid(owner_value) or owner_value.get_script() != cycle.script or cycle.entry.stage != "terminal":
		last_error = "Managed native cancellation sealing failed; history remains unusable for admission/capture"


func snapshot_state_for_authored_restore(owner: Node3D, bindings: Dictionary) -> Dictionary:
	## Explicit fresh-recipient packet check only. This does not make a staged
	## terminal getter into an earned receipt, admit/seal anything, or substitute
	## history for actual current tables. Source HP/generation must already have
	## been applied by the validated whole parent before this native packet read.
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty(): return {}
	if _cycle_restore_capture_owner != null:
		last_snapshot_error = "Authored restore packet capture cannot recurse"
		return {}
	var cycle: Dictionary = _cycle_for_owner(owner)
	if cycle.is_empty():
		last_snapshot_error = "Actual already-restored managed source required"
		return {}
	last_snapshot_error = _cycle_restore_recipe_error(cycle)
	if not last_snapshot_error.is_empty(): return {}
	_cycle_restore_capture_owner = weakref(owner)
	var result: Dictionary = snapshot_state(bindings)
	_cycle_restore_capture_owner = null
	return result


func _cycle_restore_recipe_error(cycle: Dictionary) -> String:
	var value: Variant = (cycle.owner as WeakRef).get_ref()
	if not is_instance_valid(value) or not value is Node3D or value.get_script() != cycle.script or not value.has_method("get_authored_cycle_restore_recipe"): return "Actual prepared native recipient and distinct restore recipe getter required"
	var recipe: Variant = value.call("get_authored_cycle_restore_recipe")
	if not is_instance_valid(value) or value.get_script() != cycle.script or not recipe is Dictionary or not Codec.keys_error(recipe, ["playback_id", "lifecycle", "terminal_receipt"]).is_empty() or not _authored_same(recipe.lifecycle, cycle.entry) or recipe.playback_id != cycle.playback_id or not recipe.terminal_receipt is Dictionary: return "Exact prepared source recipe must match its actual retained current journal/ID"
	if cycle.entry.stage == "terminal":
		if not CycleReceipt.snapshot_error(recipe.terminal_receipt).is_empty() or not _authored_same(recipe.terminal_receipt, cycle.entry.terminal_receipts[-1]): return "Prepared terminal recipe differs from the exact original frozen receipt"
	elif not recipe.terminal_receipt.is_empty(): return "A never-terminal current generation cannot invent a prepared terminal receipt"
	return ""
