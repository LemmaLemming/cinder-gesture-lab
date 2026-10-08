class_name CinderLaneMechanism
extends Node3D
## Nonenemy stationary consumer of shared finite-lane/circle geometry.
## Art belongs to the level and may attach here/read state_changed/get_cue().
## No hit group, HP, ammo requirement, living-enemy credit or autonomous cycles.

signal state_changed(mechanism_state: Dictionary)
signal hit_resolved(hero_id: String, cycle: int, result: Dictionary)

const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const CueScript = preload("res://scripts/cues/threat_cue.gd")
const API_REVISION: String = "lane-mechanism-1"
# Role transport requires positive max_hp; this compatibility field creates
# no health component. A genuine zero approach speed denotes this fixed source.
const DEFAULT_RAW_ROLE: Dictionary = {"raw_damage": 4.0, "windup_s": 2.2, "lock_s": 1.1, "active_s": 0.2, "recovery_s": 1.6, "attack_interval_s": 1.8, "max_hp": 1.0, "move_speed": 0.0}
const DEFAULT_TIMING_FLOORS: Dictionary = {"windup_s": 2.2, "lock_s": 1.1, "recovery_s": 1.6}
const EXCHANGE_KEYS: Array[String] = ["id", "source_position", "geometry", "opening_position", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision"]
const RESPONSE_KEYS: Array[String] = ["encounter_id", "world_revision", "recognition_s", "attack_input_margin_s", "escape_directions", "return_directions", "floor_regions"]
const MAX_PENDING_SEGMENTS: int = 256

var last_error: String = ""
var last_snapshot_error: String = ""
var _configured: bool = false
var _configuration: Dictionary = {}
var _scheduler: CinderThreatScheduler
var _heroes: Dictionary = {}
var _cue: CinderThreatCue
var _status: String = "idle"
var _phase: String = "clear"
var _cycle: int = 0
var _resolved_role: Dictionary = {}
var _exchange: Dictionary = {}
var _exchange_encounter_id: String = ""
var _samples: Dictionary = {}
var _hit_ids: Dictionary = {}
var _pending_segments: Dictionary = {}
var _last_cancel_reason: String = ""
var _transaction_depth: int = 0
var _snapshot_busy: bool = false
var _cancelling: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	# Scheduler/hero default priority is zero. Sample their completed physics
	# tick and its clock together, independent of authored tree ordering.
	process_physics_priority = 100
	_cue = CueScript.new()
	_cue.name = "ThreatCue"
	add_child(_cue)


func configure(mechanism_id: String, geometry: Dictionary, opening_position: Vector3, raw_role: Dictionary = DEFAULT_RAW_ROLE, timing_floors: Dictionary = DEFAULT_TIMING_FLOORS) -> bool:
	if _transaction_depth > 0 or _snapshot_busy or is_instance_valid(_scheduler):
		return _reject("Configure immutable mechanism data before binding")
	if not _stable_id(mechanism_id) or not Geometry.error(geometry).is_empty() or geometry.get("kind") not in ["lane", "circle"] or not Geometry.finite_vector(opening_position):
		return _reject("Stable mechanism ID, finite authoritative lane/circle and actual opening position required")
	if not Codec.keys_error(raw_role, DEFAULT_RAW_ROLE.keys()).is_empty() or not Codec.value_error(raw_role).is_empty() or not Codec.keys_error(timing_floors, DEFAULT_TIMING_FLOORS.keys()).is_empty():
		return _reject("Unsupported raw role or timing-floor schema")
	var difficulty = Difficulty.new()
	if difficulty.resolve_role(raw_role, "standard", timing_floors).is_empty():
		return _reject(difficulty.last_error)
	var next: Dictionary = {"mechanism_id": mechanism_id, "geometry": _copy_geometry(geometry), "opening_position": opening_position, "raw_role": raw_role.duplicate(true), "timing_floors": timing_floors.duplicate(true)}
	if _configured and next != _configuration:
		return _reject("Configured raw mechanism data is immutable")
	_configuration = next
	_configured = true
	last_error = ""
	return true


func bind(scheduler: CinderThreatScheduler, heroes: Dictionary) -> bool:
	if not is_inside_tree() or not is_node_ready() or not _configured or _transaction_depth > 0 or _snapshot_busy:
		return _reject("Bind a ready configured mechanism outside callbacks")
	if not is_instance_valid(scheduler) or not scheduler.is_inside_tree() or scheduler.get_world_3d() != get_world_3d() or scheduler.process_physics_priority >= process_physics_priority or heroes.is_empty():
		return _reject("Same-world earlier physics scheduler and stable shared heroes required")
	var used: Dictionary = {}
	for id: Variant in heroes:
		var hero: CinderPlayer = heroes[id] as CinderPlayer
		if not _stable_id(id) or not is_instance_valid(hero) or not hero.is_inside_tree() or hero.is_queued_for_deletion() or hero.get_world_3d() != get_world_3d() or hero.process_physics_priority >= process_physics_priority or used.has(hero.get_instance_id()):
			return _reject("Hero IDs must name distinct live earlier-physics shared actors")
		used[hero.get_instance_id()] = true
	if is_instance_valid(_scheduler):
		if _scheduler != scheduler or _heroes != heroes:
			return _reject("Stable scheduler/hero bindings are immutable")
		last_error = ""
		return true
	_scheduler = scheduler
	_heroes = heroes.duplicate()
	_scheduler.reservation_invalidated.connect(_on_invalidated)
	last_error = ""
	return true


func start(hero_id: String, response_context: Dictionary, opening_position: Variant = null) -> Dictionary:
	last_error = ""
	if _transaction_depth > 0 or _snapshot_busy or _cancelling or not _live_bindings() or _status == "running" or get_tree().paused or not is_visible_in_tree() or not _cue.is_visible_in_tree() or _cycle >= Codec.MAX_SAFE_INTEGER:
		return _denied("Start requires an idle live unpaused mechanism outside callbacks")
	if not _heroes.has(hero_id) or not Codec.keys_error(response_context, RESPONSE_KEYS).is_empty() or not _stable_id(response_context.get("encounter_id")):
		return _denied("Authored encounter epoch, floor and finite response candidates required")
	if not global_position.is_equal_approx(_geometry_source(_configuration.geometry)):
		return _denied("The actual mechanism source must remain at its committed lane start/circle origin")
	if opening_position != null and not Geometry.finite_vector(opening_position):
		return _denied("Per-cycle opening position must be an actual finite world Vector3")
	# A level may supply another actor's committed stopped endpoint. This is a
	# reachable-position seam; that actor's HP/recovery/custody is level-owned.
	var cycle_opening: Vector3 = _configuration.opening_position if opening_position == null else opening_position
	var difficulty = Difficulty.new()
	var profile: Dictionary = _scheduler.encounter_profile()
	var resolved: Dictionary = difficulty.resolve_role(_configuration.raw_role, String(profile.get("id", "")), _configuration.timing_floors)
	if resolved.is_empty():
		return _denied(difficulty.last_error)
	var hero: CinderPlayer = _heroes[hero_id]
	var response: Dictionary = hero.get_threat_response_state()
	for key: String in RESPONSE_KEYS:
		if key != "encounter_id":
			response[key] = response_context[key]
	var threat: Dictionary = {"role": resolved, "geometry": _configuration.geometry.duplicate(true), "source_stationary": true, "opening_stationary": true, "opening_position": cycle_opening, "cooldown_remaining_s": 0.0}
	_transaction_depth += 1
	var answer: Dictionary = _scheduler.request_attack(self, threat, response)
	if answer.get("accepted", false):
		var reservation: Dictionary = _live_reservation(String(answer.reservation_id))
		if reservation.is_empty():
			_scheduler.cancel(String(answer.reservation_id), "missing_accepted_reservation")
			answer = _denied("Accepted exchange lost its actual reservation")
		else:
			_exchange = _exchange_data(reservation)
			_exchange_encounter_id = response_context.encounter_id
			_resolved_role = resolved.duplicate(true)
			_cycle += 1
			_hit_ids.clear()
			_pending_segments.clear()
			_samples.clear()
			_sample_heroes(_scheduler.get_clock())
			_status = "running"
			_last_cancel_reason = ""
			_set_phase("warning")
	else:
		last_error = String(answer.get("reason", "Reservation rejected"))
	_transaction_depth -= 1
	return answer.duplicate(true)


func cancel(reason: String = "mechanism_cancelled") -> bool:
	if _snapshot_busy or _cancelling:
		return false
	_cancelling = true
	_transaction_depth += 1
	var id: String = String(_exchange.get("id", "")) if _status == "running" else ""
	_status = "cancelled" if _cycle > 0 else "idle"
	_pending_segments.clear()
	_last_cancel_reason = reason
	if not id.is_empty() and is_instance_valid(_scheduler):
		_scheduler.cancel(id, reason)
	_set_phase("clear")
	_transaction_depth -= 1
	_cancelling = false
	return true


func clear(reason: String = "mechanism_cleared") -> bool:
	return cancel(reason)


func get_cue() -> CinderThreatCue:
	return _cue


func state() -> Dictionary:
	var remaining: float = 0.0
	if _status == "running" and is_instance_valid(_scheduler):
		var key: String = {"warning": "lock_from_s", "lock": "active_from_s", "active": "active_until_s", "recovery": "recovery_until_s"}.get(_phase, "")
		if not key.is_empty():
			remaining = maxf(float(_exchange[key]) - _scheduler.get_clock(), 0.0)
	var hits: Array = _hit_ids.keys()
	hits.sort()
	return {"api_revision": API_REVISION, "mechanism_id": _configuration.get("mechanism_id", ""), "status": _status, "phase": _phase, "remaining_s": remaining, "cycle": _cycle, "reservation_id": _exchange.get("id", "") if _status == "running" else "", "geometry": _configuration.get("geometry", {}).duplicate(true), "source_position": global_position, "opening_position": _exchange.get("opening_position", _configuration.get("opening_position")), "resolved_role": _resolved_role.duplicate(true), "hit_ids": hits, "last_cancel_reason": _last_cancel_reason}


func _physics_process(_delta: float) -> void:
	if _status != "running" or not is_instance_valid(_scheduler) or get_tree().paused or _transaction_depth > 0:
		return
	_transaction_depth += 1
	if _damage_boundary_ready():
		var now: float = _scheduler.get_clock()
		# Sample completed actor physics before every observer. On resume append
		# the real new segment to an unresolved path; never collapse its turns.
		if _stage_hero_segments(now):
			_set_phase(_phase_at(now, _exchange))
			if _damage_boundary_ready():
				_resolve_pending_segments()
	_transaction_depth -= 1


func _stage_hero_segments(now: float) -> bool:
	var ids: Array = _heroes.keys()
	ids.sort()
	for id: String in ids:
		var hero: CinderPlayer = _heroes[id]
		var previous: Dictionary = _samples[id]
		if not hero.dead and not _hit_ids.has(id):
			var path: Array = _pending_segments.get(id, [])
			if path.size() >= MAX_PENDING_SEGMENTS:
				cancel("pending_path_budget_exceeded")
				return false
			path.append({"from": previous.position, "to": hero.global_position, "start_s": previous.clock_s, "end_s": now})
			_pending_segments[id] = path
		_samples[id] = {"position": hero.global_position, "clock_s": now}
	return true


func _resolve_pending_segments() -> void:
	for id: String in _pending_segments.keys():
		if not _damage_boundary_ready():
			return
		var hero: CinderPlayer = _heroes[id]
		var path: Array[Dictionary] = []
		for segment: Dictionary in _pending_segments[id]: path.append(segment)
		# Commit this entry before any synchronous actor/art callback. A pause
		# keeps only the unprocessed entries, never a second hit for this hero.
		_pending_segments.erase(id)
		if hero.dead or _hit_ids.has(id) or not _active_path_hits(path):
			continue
		# Consume the opportunity before entering the player's synchronous
		# hurt/death callbacks. Invulnerability may legitimately reject damage.
		_hit_ids[id] = true
		var hp_before: float = hero.hp
		hero.take_damage(float(_resolved_role.damage), Vector3.ZERO)
		var result: Dictionary = {"opportunity_consumed": true, "accepted": hero.hp < hp_before, "raw_damage": float(_resolved_role.damage), "hp_damage": maxf(hp_before - hero.hp, 0.0), "impulse": Vector3.ZERO}
		var hurt_boundary_ready: bool = _damage_boundary_ready()
		hit_resolved.emit(id, _cycle, result.duplicate(true))
		var hit_boundary_ready: bool = _damage_boundary_ready()
		if not hurt_boundary_ready or not hit_boundary_ready:
			return


func _active_path_hits(path: Array[Dictionary]) -> bool:
	for segment: Dictionary in path:
		# Spatial tolerances cannot advance a damage opportunity into the last
		# lock tick when binary64 clock accumulation falls just below active_from.
		if maxf(float(segment.start_s), float(_exchange.active_from_s)) > minf(float(segment.end_s), float(_exchange.active_until_s)):
			continue
		if Geometry.timed_path_hits(_configuration.geometry, [segment], float(_exchange.active_from_s), float(_exchange.active_until_s), CinderThreatScheduler.CAPSULE_RADIUS):
			return true
	return false


func _damage_boundary_ready() -> bool:
	if _status != "running":
		return false
	if not _live_bindings() or is_queued_for_deletion() or not is_visible_in_tree() or not _required_cue_available():
		cancel("required_source_or_bindings_unavailable")
		return false
	if get_tree().paused:
		return false
	var reservation: Dictionary = _live_reservation(String(_exchange.id))
	if _status != "running":
		return false
	if reservation.is_empty():
		if _scheduler.get_clock() > float(_exchange.recovery_until_s):
			_status = "complete"
			_pending_segments.clear()
			_set_phase("clear")
		else:
			cancel("reservation_missing")
		return false
	if _exchange_data(reservation) != _exchange:
		cancel("committed_exchange_changed")
		return false
	# Scheduler cleanup can itself notify authored observers.
	if not _live_bindings() or not is_visible_in_tree() or not _required_cue_available():
		cancel("required_source_or_bindings_unavailable")
		return false
	return not get_tree().paused


func _required_cue_available() -> bool:
	if not is_instance_valid(_cue) or not _cue.is_visible_in_tree():
		return false
	var current: Dictionary = _cue.state()
	if current.phase != _phase or current.geometry != _configuration.geometry or current.source_position != _geometry_source(_configuration.geometry):
		return false
	var required: Array[String] = ["RequiredSourceMarker"]
	if _phase != "recovery": required.append("RequiredFootprintOutline")
	if _phase == "active": required.append("RequiredFootprintFill")
	for part_name: String in required:
		var part: MeshInstance3D = _cue.get_node_or_null(part_name) as MeshInstance3D
		if not is_instance_valid(part) or part.is_queued_for_deletion() or not part.is_visible_in_tree() or part.mesh == null:
			return false
	return true


func _sample_heroes(now: float) -> void:
	for id: String in _heroes:
		_samples[id] = {"position": (_heroes[id] as CinderPlayer).global_position, "clock_s": now}


func _set_phase(phase: String, notify: bool = true) -> void:
	var changed: bool = _phase != phase
	_phase = phase
	if is_instance_valid(_cue):
		if phase == "clear":
			_cue.clear()
		else:
			_cue.present(_configuration.geometry, phase)
		# A cue callback may synchronously cancel this mechanism. Its cue
		# rejected nested clear, so clear again after that callback returns.
		if _phase == "clear":
			_cue.clear()
	if changed and notify and _phase == phase:
		state_changed.emit(state())


func _on_invalidated(id: String, reason: String) -> void:
	if _status == "running" and id == _exchange.get("id") and not _cancelling:
		cancel(reason)


func _exit_tree() -> void:
	if is_instance_valid(_scheduler):
		if _scheduler.reservation_invalidated.is_connected(_on_invalidated):
			_scheduler.reservation_invalidated.disconnect(_on_invalidated)
		_scheduler.cancel_owner(self, "mechanism_removed")


func _live_bindings() -> bool:
	if not _configured or not is_inside_tree() or not is_node_ready() or not is_instance_valid(_scheduler) or not _scheduler.is_inside_tree() or _scheduler.is_queued_for_deletion() or _scheduler.get_world_3d() != get_world_3d() or _scheduler.process_physics_priority >= process_physics_priority or not is_instance_valid(_cue) or not _cue.is_inside_tree() or _cue.is_queued_for_deletion():
		return false
	for hero: Variant in _heroes.values():
		if not is_instance_valid(hero) or not hero.is_inside_tree() or hero.is_queued_for_deletion() or hero.get_world_3d() != get_world_3d() or hero.process_physics_priority >= process_physics_priority or not Geometry.finite_vector(hero.global_position):
			return false
	return not _heroes.is_empty()


func _live_reservation(id: String) -> Dictionary:
	for record: Dictionary in _scheduler.reservations():
		if record.id == id and int(record.source_instance_id) == get_instance_id():
			return record
	return {}


func _exchange_data(record: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: String in EXCHANGE_KEYS:
		result[key] = record[key]
	return result.duplicate(true)


func _phase_at(now: float, exchange: Dictionary) -> String:
	return "warning" if now < float(exchange.lock_from_s) else ("lock" if now < float(exchange.active_from_s) else ("active" if now <= float(exchange.active_until_s) else "recovery"))


func _stable_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 128:
		return false
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9_./:-]+$")
	var matched: RegExMatch = pattern.search(value)
	return matched != null and matched.get_string() == value


func _reject(reason: String) -> bool:
	last_error = reason
	return false


func _denied(reason: String) -> Dictionary:
	last_error = reason
	return {"accepted": false, "reason": reason}


## Paired paused transport. Prevalidation may use a staged scheduler envelope
## and its owner_positions; commit ONLY accepts the actually restored scheduler.
## Rebuild cues silently; level artwork should re-read state after aggregate
## commit. No reservation request, damage, phase/hit/cue event or timing reset.
func snapshot_state(scheduler_bindings: Dictionary) -> Dictionary:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty():
		return {}
	_snapshot_busy = true
	var paired: Dictionary = _scheduler.snapshot_state(scheduler_bindings)
	var snapshot: Dictionary = {}
	if paired.is_empty():
		last_snapshot_error = _scheduler.last_snapshot_error
	else:
		var hits: Array = _hit_ids.keys()
		hits.sort()
		var samples: Dictionary = {}
		for id: String in _samples:
			samples[id] = {"position": Codec.vector3(_samples[id].position), "clock_s": _samples[id].clock_s}
		snapshot = {"api_revision": API_REVISION, "schema_version": 1, "mechanism_id": _configuration.mechanism_id, "configuration": _encode_configuration(), "status": _status, "phase": _phase, "cycle": _cycle, "clock_s": paired.clock_s, "resolved_role": _resolved_role.duplicate(true), "exchange_encounter_id": _exchange_encounter_id, "exchange": _encode_exchange(_exchange), "hero_samples": samples, "hit_ids": hits, "last_cancel_reason": _last_cancel_reason}
		if not _pending_segments.is_empty():
			snapshot.schema_version = 2
			snapshot["pending_segments"] = {}
			for id: String in _pending_segments:
				snapshot.pending_segments[id] = []
				for segment: Dictionary in _pending_segments[id]:
					snapshot.pending_segments[id].append({"from": Codec.vector3(segment.from), "to": Codec.vector3(segment.to), "start_s": segment.start_s, "end_s": segment.end_s})
		last_snapshot_error = _snapshot_plan_error(snapshot, scheduler_bindings, paired, true)
	_snapshot_busy = false
	return snapshot.duplicate(true) if last_snapshot_error.is_empty() else {}


func snapshot_error(snapshot: Dictionary, scheduler_bindings: Dictionary, staged_scheduler_snapshot: Dictionary = {}) -> String:
	var error: String = _snapshot_access_error()
	if not error.is_empty():
		return error
	_snapshot_busy = true
	var paired: Dictionary = staged_scheduler_snapshot.duplicate(true) if not staged_scheduler_snapshot.is_empty() else _scheduler.snapshot_state(scheduler_bindings)
	error = _scheduler.snapshot_error(paired, scheduler_bindings) if not paired.is_empty() else _scheduler.last_snapshot_error
	if error.is_empty():
		error = _snapshot_plan_error(snapshot, scheduler_bindings, paired)
	_snapshot_busy = false
	return error


func restore_state(snapshot: Dictionary, scheduler_bindings: Dictionary) -> bool:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty():
		return false
	_snapshot_busy = true
	var paired: Dictionary = _scheduler.snapshot_state(scheduler_bindings)
	last_snapshot_error = _scheduler.last_snapshot_error if paired.is_empty() else _snapshot_plan_error(snapshot, scheduler_bindings, paired, true)
	if last_snapshot_error.is_empty() and not global_position.is_equal_approx(_geometry_source(_configuration.geometry)):
		last_snapshot_error = "Apply validated actual mechanism position before scheduler/mechanism commit"
	if not last_snapshot_error.is_empty():
		_snapshot_busy = false
		return false
	var accepted: Dictionary = snapshot.duplicate(true)
	_status = accepted.status
	_phase = accepted.phase
	_cycle = int(accepted.cycle)
	_resolved_role = accepted.resolved_role
	_exchange_encounter_id = accepted.exchange_encounter_id
	_exchange = _decode_exchange(accepted.exchange)
	_samples.clear()
	for id: String in accepted.hero_samples:
		_samples[id] = {"position": Codec.read_vector3(accepted.hero_samples[id].position), "clock_s": float(accepted.hero_samples[id].clock_s)}
	_hit_ids.clear()
	for id: String in accepted.hit_ids:
		_hit_ids[id] = true
	_pending_segments.clear()
	for id: String in accepted.get("pending_segments", {}):
		_pending_segments[id] = []
		for segment: Dictionary in accepted.pending_segments[id]:
			_pending_segments[id].append({"from": Codec.read_vector3(segment.from), "to": Codec.read_vector3(segment.to), "start_s": float(segment.start_s), "end_s": float(segment.end_s)})
	_last_cancel_reason = accepted.last_cancel_reason
	var was_blocked: bool = _cue.is_blocking_signals()
	_cue.set_block_signals(true)
	_cue.clear()
	_set_phase(_phase, false)
	_cue.set_block_signals(was_blocked)
	_snapshot_busy = false
	return true


func _snapshot_access_error() -> String:
	if not _live_bindings() or not get_tree().paused:
		return "Mechanism snapshots require ready stable bindings at the paused shell barrier"
	if _snapshot_busy or _transaction_depth > 0 or _cancelling:
		return "Mechanism snapshots cannot run inside phase/hit/physics/cancellation callbacks"
	return ""


func _encode_configuration() -> Dictionary:
	return {"mechanism_id": _configuration.mechanism_id, "geometry": _encode_geometry(_configuration.geometry), "opening_position": Codec.vector3(_configuration.opening_position), "raw_role": _configuration.raw_role.duplicate(true), "timing_floors": _configuration.timing_floors.duplicate(true)}


func _encode_geometry(shape: Dictionary) -> Dictionary:
	if shape["kind"] == "circle":
		return {"kind": "circle", "origin": Codec.vector3(shape["origin"]), "radius": shape.radius}
	return {"kind": "lane", "from": Codec.vector3(shape["from"]), "to": Codec.vector3(shape["to"]), "radius": shape.radius}


func _copy_geometry(shape: Dictionary) -> Dictionary:
	return Geometry.circle(shape["origin"], float(shape["radius"])) if shape["kind"] == "circle" else Geometry.lane(shape["from"], shape["to"], float(shape["radius"]))


func _geometry_source(shape: Dictionary) -> Vector3:
	return shape["origin"] if shape["kind"] == "circle" else shape["from"]


func _encode_exchange(exchange: Dictionary) -> Dictionary:
	if exchange.is_empty():
		return {}
	var result: Dictionary = exchange.duplicate(true)
	result.geometry = _encode_geometry(exchange.geometry)
	result.source_position = Codec.vector3(exchange.source_position)
	result.opening_position = Codec.vector3(exchange.opening_position)
	return result


func _decode_exchange(exchange: Dictionary) -> Dictionary:
	if exchange.is_empty():
		return {}
	var result: Dictionary = exchange.duplicate(true)
	result.geometry = Geometry.circle(Codec.read_vector3(exchange.geometry["origin"]), float(exchange.geometry.radius)) if exchange.geometry["kind"] == "circle" else Geometry.lane(Codec.read_vector3(exchange.geometry["from"]), Codec.read_vector3(exchange.geometry["to"]), float(exchange.geometry.radius))
	result.source_position = Codec.read_vector3(exchange.source_position)
	result.opening_position = Codec.read_vector3(exchange.opening_position)
	return result


func _snapshot_plan_error(snapshot: Dictionary, bindings: Dictionary, paired: Dictionary, actual_heroes: bool = false) -> String:
	var error: String = Codec.value_error(snapshot)
	if error.is_empty():
		var keys: Array = ["api_revision", "schema_version", "mechanism_id", "configuration", "status", "phase", "cycle", "clock_s", "resolved_role", "exchange_encounter_id", "exchange", "hero_samples", "hit_ids", "last_cancel_reason"]
		if snapshot.get("schema_version") == 2: keys.append("pending_segments")
		error = Codec.keys_error(snapshot, keys)
	if not error.is_empty():
		return error
	if snapshot.api_revision != API_REVISION or not Codec.is_integer(snapshot.schema_version, 1, 2) or snapshot.mechanism_id != _configuration.mechanism_id or not snapshot.configuration is Dictionary or not _same_exact(snapshot.configuration, _encode_configuration()) or not Codec.is_integer(snapshot.cycle) or snapshot.status not in ["idle", "running", "cancelled", "complete"] or not snapshot.phase is String or not snapshot.resolved_role is Dictionary or not snapshot.exchange is Dictionary or not snapshot.hero_samples is Dictionary or not snapshot.hit_ids is Array or not snapshot.last_cancel_reason is String or not snapshot.exchange_encounter_id is String:
		return "Invalid immutable mechanism identity/configuration/schema"
	var pending: Variant = snapshot.get("pending_segments", {})
	if not pending is Dictionary or (snapshot.schema_version == 2 and (pending.is_empty() or snapshot.status != "running" or pending.size() > _heroes.size())):
		return "Pending schema2 requires a bounded unprocessed running hero batch"
	if not Codec.is_number(snapshot.clock_s) or float(snapshot.clock_s) != float(paired.clock_s) or not bindings.get("owners") is Dictionary or bindings.owners.get(_configuration.mechanism_id) != self:
		return "Mechanism must share the actual/staged scheduler clock and stable source binding"
	if bindings.has("hero_positions") and not bindings.hero_positions is Dictionary:
		return "Staged hero_positions must name finite actual actor positions"
	for id: Variant in bindings.get("hero_positions", {}):
		if not _heroes.has(id) or not Geometry.finite_vector(bindings.hero_positions[id]):
			return "Staged hero_positions require stable bound actor IDs"
	var owned: Dictionary = {}
	for record: Dictionary in paired.reservations:
		if record.source_id == _configuration.mechanism_id:
			owned = record
	if snapshot.status == "idle":
		for cooldown: Dictionary in paired.cooldowns:
			if cooldown.source_id == _configuration.mechanism_id:
				return "Idle mechanism cannot forget a consumed source cooldown/cycle"
		return "Idle mechanism cannot retain exchange/phase/hit state" if snapshot.cycle != 0 or snapshot.phase != "clear" or not snapshot.exchange.is_empty() or not snapshot.resolved_role.is_empty() or not snapshot.hero_samples.is_empty() or not snapshot.hit_ids.is_empty() or not snapshot.exchange_encounter_id.is_empty() or not owned.is_empty() else ""
	if not Codec.is_integer(snapshot.cycle, 1) or not _stable_id(snapshot.exchange_encounter_id) or not Codec.keys_error(snapshot.exchange, EXCHANGE_KEYS).is_empty():
		return "Executed mechanism requires its finite cycle and exact committed exchange"
	var exchange: Dictionary = snapshot.exchange
	if not exchange.id is String or not exchange.id.begins_with("threat-") or not Codec.is_vector3(exchange.source_position) or not Codec.is_vector3(exchange.opening_position) or not exchange.geometry is Dictionary or not _same_exact(exchange.geometry, _encode_geometry(_configuration.geometry)) or not Codec.read_vector3(exchange.source_position).is_equal_approx(_geometry_source(_configuration.geometry)) or not exchange.profile_id is String or not Codec.is_integer(exchange.world_revision, 1):
		return "Committed source/geometry/opening no longer matches actual mechanism configuration"
	if not exchange.id.substr(7).is_valid_int() or not Codec.is_integer(int(exchange.id.substr(7)), 1) or exchange.id != "threat-%d" % int(exchange.id.substr(7)):
		return "Committed reservation ID must preserve its exact finite scheduler serial"
	var difficulty = Difficulty.new()
	var resolved: Dictionary = difficulty.resolve_role(_configuration.raw_role, exchange.profile_id, _configuration.timing_floors)
	if resolved.is_empty() or not _same_exact(snapshot.resolved_role, resolved):
		return "Saved role must resolve once from immutable raw data and its catalogue profile"
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not Codec.in_range(exchange[key], 0.0, 1000000000.0):
			return "Committed mechanism deadlines must be finite and nonnegative"
	var active_from: float = float(exchange.start_s) + float(resolved.windup_s)
	var expected: Dictionary = {"lock_from_s": active_from - float(resolved.lock_s), "active_from_s": active_from, "active_until_s": active_from + float(resolved.active_s), "recovery_until_s": active_from + float(resolved.active_s) + float(resolved.recovery_s), "cooldown_until_s": active_from + float(resolved.attack_interval_s)}
	for key: String in expected:
		if float(exchange[key]) != float(expected[key]):
			return "Saved deadlines disagree with the original resolved cycle"
	if snapshot.status == "running":
		if owned.is_empty() or snapshot.exchange_encounter_id != paired.encounter_id or snapshot.phase != _phase_at(float(snapshot.clock_s), _decode_exchange(exchange)) or not snapshot.last_cancel_reason.is_empty():
			return "Running phase requires the same actually/staged reserved encounter"
		for key: String in EXCHANGE_KEYS:
			if not _same_exact(exchange[key], owned[key]):
				return "Running mechanism and scheduler reservation disagree"
	else:
		if snapshot.phase != "clear" or not owned.is_empty():
			return "Inactive mechanism cannot hide a retained danger reservation"
		if snapshot.status == "cancelled" and snapshot.last_cancel_reason.is_empty():
			return "Cancelled mechanism requires its explicit cancellation reason"
		if snapshot.status == "complete" and snapshot.exchange_encounter_id == paired.encounter_id and float(snapshot.clock_s) <= float(exchange.recovery_until_s):
			return "Completed cycle cannot discard remaining recovery"
	if snapshot.exchange_encounter_id == paired.encounter_id and float(exchange.cooldown_until_s) > float(snapshot.clock_s):
		var has_cooldown: bool = false
		for cooldown: Dictionary in paired.cooldowns:
			if cooldown.source_id == _configuration.mechanism_id and float(cooldown.ready_s) == float(exchange.cooldown_until_s):
				has_cooldown = true
		if not has_cooldown:
			return "Cancelled/live cycle cannot refresh its original source cooldown"
	if snapshot.hero_samples.size() != _heroes.size():
		return "Stable hero samples must retain every bound actor"
	for id: Variant in snapshot.hero_samples:
		var sample: Variant = snapshot.hero_samples[id]
		if not _heroes.has(id) or not sample is Dictionary or not Codec.keys_error(sample, ["position", "clock_s"]).is_empty() or not Codec.is_vector3(sample.position) or not Codec.in_range(sample.clock_s, float(exchange.start_s), float(exchange.recovery_until_s)):
			return "Malformed finite hero path sample"
		if snapshot.status == "running":
			var hero: CinderPlayer = _heroes[id]
			var position: Vector3 = hero.global_position if actual_heroes else bindings.get("hero_positions", {}).get(id, hero.global_position)
			if float(sample.clock_s) != float(snapshot.clock_s) or Codec.read_vector3(sample.position) != position:
				return "Running hero path sample must match the same actual/staged actor tick"
	var seen: Dictionary = {}
	for id: Variant in snapshot.hit_ids:
		if not id is String or not _heroes.has(id) or seen.has(id):
			return "Hit dedupe must use unique stable bound hero IDs"
		seen[id] = true
		if float(snapshot.hero_samples[id].clock_s) < float(exchange.active_from_s):
			return "A hero opportunity cannot be consumed before the active interval"
	var latest_batch_start: float = -1.0
	for id: Variant in pending:
		var path: Variant = pending[id]
		if not id is String or not _heroes.has(id) or seen.has(id) or not path is Array or path.is_empty() or path.size() > MAX_PENDING_SEGMENTS:
			return "Pending segments require unique unconsumed stable heroes and finite sampled paths"
		var previous: Dictionary = {}
		for segment: Variant in path:
			if not segment is Dictionary or not Codec.keys_error(segment, ["from", "to", "start_s", "end_s"]).is_empty() or not Codec.is_vector3(segment.from) or not Codec.is_vector3(segment.to) or not Codec.in_range(segment.start_s, float(exchange.start_s), float(snapshot.clock_s)) or not Codec.in_range(segment.end_s, float(segment.start_s), float(snapshot.clock_s)) or float(segment.end_s) - float(segment.start_s) > 1.0 / float(Engine.physics_ticks_per_second) + Geometry.EPSILON:
				return "Every pending segment must retain a finite actual single-physics-tick interval"
			if not previous.is_empty() and (float(segment.start_s) != float(previous.end_s) or not _same_exact(segment.from, previous.to)):
				return "Pending path must preserve exact contiguous piecewise samples"
			previous = segment
		if float(previous.end_s) != float(snapshot.clock_s) or not _same_exact(previous.to, snapshot.hero_samples[id].position):
			return "Pending path must retain the exact paired current endpoint and clock"
		if latest_batch_start >= 0.0 and float(previous.start_s) != latest_batch_start:
			return "Pending heroes must share the latest authoritative sampled batch"
		latest_batch_start = float(previous.start_s)
	return ""


func _same_exact(left: Variant, right: Variant) -> bool:
	# Legacy full-precision JSON may change int representation, never a copied
	# clock, immutable field or reservation identity. No epsilon for transport.
	if Codec.is_number(left) and Codec.is_number(right):
		return float(left) == float(right)
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size():
			return false
		for key: String in left:
			if not right.has(key) or not _same_exact(left[key], right[key]):
				return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size():
			return false
		for index: int in range(left.size()):
			if not _same_exact(left[index], right[index]):
				return false
		return true
	return typeof(left) == typeof(right) and left == right
