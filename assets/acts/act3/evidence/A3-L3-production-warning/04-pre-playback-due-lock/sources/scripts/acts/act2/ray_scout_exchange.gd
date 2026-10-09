class_name Act2RayScoutExchange
extends Node3D
## One fresh fixed-profile encounter over parent-owned stationary Scout roots.
## Parent owns scheduler begin/end, visibility/admission, sequence and progression.
## Configure once; activate explicitly. No controller, colliders or private timer.
## Paired restore order: shared player -> saved actors -> scheduler -> this driver.
## state().proof is defensive native diagnostic output, deliberately not saved;
## after restore proof_available is false until the next newly accepted lock.
## presentation_witness saves only accepted landing/opening framing positions;
## it never authorizes danger, movement, primary damage or a new reservation.
## Optional authored providers are ephemeral; cleanup releases both Callables.
## Pure staged preflight accepts bindings.hero_positions = {"hero": Vector3};
## capture/commit always compare the actual shared hero after player restoration.

signal state_changed(actor_id: String, exchange_state: Dictionary)
signal hit_resolved(actor_id: String, result: Dictionary)
signal scout_defeated(actor_id: String)

const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const CueScript = preload("res://scripts/cues/threat_cue.gd")
const OpeningCueScript = preload("res://scripts/cues/interaction_cue.gd")
const API_REVISION: String = "act2-ray-exchange-1"
const RAW_ROLE: Dictionary = {"raw_damage": 10.0, "windup_s": 1.55, "lock_s": 1.10, "active_s": 0.16, "recovery_s": 1.60, "attack_interval_s": 1.60, "max_hp": 30.0, "move_speed": 0.0}
const TIMING_FLOORS: Dictionary = {"windup_s": 1.55, "lock_s": 1.10, "recovery_s": 1.60}
const REACH: float = 3.8
const RADIUS: float = 0.31
const FLASH_S: float = 0.12
const EPSILON: float = 0.00001
const MAX_DEFERRED_PATHS: int = 256
const CONTEXT_KEYS: Array[String] = ["encounter_id", "world_revision", "recognition_s", "attack_input_margin_s", "escape_directions", "return_directions", "floor_regions"]
const EXCHANGE_KEYS: Array[String] = ["id", "source_position", "geometry", "opening_position", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision", "adapter"]
const RECORD_KEYS: Array[String] = ["status", "phase", "cycle", "direction", "exchange", "context", "sample", "hit_consumed", "observed_hp", "flash_until_s", "last_cancel_reason", "presentation_witness", "deferred_paths"]

var last_error: String = ""
var last_snapshot_error: String = ""
var _configured: bool = false
var _retired: bool = false
var _hero: CinderPlayer
var _effects: PixelEffects
var _scheduler: CinderThreatScheduler
var _actors: Dictionary = {}
var _anchors: Dictionary = {}
var _cues: Dictionary = {}
var _opening_cues: Dictionary = {}
var _records: Dictionary = {}
var _proofs: Dictionary = {}
var _context: Dictionary = {}
var _profile_id: String = ""
var _role: Dictionary = {}
var _transaction_depth: int = 0
var _snapshot_busy: bool = false
var _cancelling: bool = false
var _context_provider: Callable = Callable()
var _provider_required: bool = false
var _presentation_guard: Callable = Callable()
var _guard_required: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 100


func configure(shared_hero: CinderPlayer, shared_effects: PixelEffects, scheduler: CinderThreatScheduler, actors: Dictionary, profile_id: String, response_context: Dictionary) -> bool:
	if _configured or _retired or _transaction_depth > 0 or _snapshot_busy or not is_inside_tree() or not is_node_ready():
		return _reject("Configure a fresh ready exchange once outside transactions")
	if not is_instance_valid(shared_hero) or not is_instance_valid(shared_effects) or not is_instance_valid(scheduler) or not shared_hero.is_inside_tree() or not shared_effects.is_inside_tree() or not scheduler.is_inside_tree() or shared_hero.get_world_3d() != get_world_3d() or shared_effects.get_world_3d() != get_world_3d() or scheduler.get_world_3d() != get_world_3d() or shared_hero.process_physics_priority >= process_physics_priority or scheduler.process_physics_priority >= process_physics_priority or actors.is_empty():
		return _reject("Live same-world earlier-physics hero/effects/scheduler and Scout map required")
	var error: String = _context_error(response_context)
	if not error.is_empty():
		return _reject(error)
	var difficulty = Difficulty.new()
	var role: Dictionary = difficulty.resolve_role(RAW_ROLE, profile_id, TIMING_FLOORS)
	if role.is_empty() or scheduler.encounter_profile().get("id") != profile_id:
		return _reject("Resolve immutable raw Scout data for the parent's current fixed profile")
	var seen: Dictionary = {}
	for id: Variant in actors:
		var actor: Variant = actors[id]
		var gate: Callable = Callable(self, "damage_window_open").bind(id)
		if not _stable_id(id) or not is_instance_valid(actor) or not actor is Node3D or not actor.is_inside_tree() or not actor.is_node_ready() or actor.is_queued_for_deletion() or actor.get_world_3d() != get_world_3d() or not actor.has_method("damage_window_gate_error") or not bool(actor.call("is_armed")) or actor.get("actor_id") != id or not Geometry.finite_vector(actor.global_position) or not _near(actor.get("max_hp"), float(role.max_hp)) or not Codec.in_range(actor.get("hp"), 0.0, float(role.max_hp)) or seen.has(actor.get_instance_id()):
			return _reject("Distinct configured stable anchored Scout roots with canonical role HP required")
		var gate_error: String = actor.call("damage_window_gate_error", gate)
		if not gate_error.is_empty():
			return _reject(gate_error)
		seen[actor.get_instance_id()] = true
	_hero = shared_hero
	_effects = shared_effects
	_scheduler = scheduler
	_actors = actors.duplicate()
	_context = response_context.duplicate(true)
	_profile_id = profile_id
	_role = role.duplicate(true)
	for id: String in _actors:
		var actor: Node3D = _actors[id]
		_anchors[id] = actor.global_position
		_records[id] = {"status": "defeated" if float(actor.get("hp")) <= 0.0 else "idle", "phase": "defeated" if float(actor.get("hp")) <= 0.0 else "clear", "cycle": 0, "direction": actor.get("direction"), "exchange": {}, "context": {}, "sample": {}, "hit_consumed": false, "observed_hp": float(actor.get("hp")), "flash_until_s": 0.0, "last_cancel_reason": "", "presentation_witness": {}, "deferred_paths": []}
		var cue: CinderThreatCue = CueScript.new()
		cue.name = "RayCue_" + str(_cues.size())
		add_child(cue)
		_cues[id] = cue
		var opening: CinderInteractionCue = OpeningCueScript.new()
		opening.name = "HousingCue_" + str(_opening_cues.size())
		add_child(opening)
		opening.global_position = actor.global_position
		_opening_cues[id] = opening
		actor.call("bind_damage_window", Callable(self, "damage_window_open").bind(id))
		actor.connect("defeated", _on_defeated)
	_scheduler.reservation_invalidated.connect(_on_invalidated)
	_configured = true
	for id: String in _actors:
		_present(id, false)
	last_error = ""
	return true


func set_response_context_provider(provider: Callable) -> bool:
	if _retired or _transaction_depth > 0 or _snapshot_busy or _cancelling or not is_inside_tree() or not is_node_ready() or not provider.is_valid():
		return _reject("Set a valid ephemeral authored response provider outside transactions")
	_context_provider = provider
	_provider_required = true
	return true


func set_presentation_guard(provider: Callable) -> bool:
	if _retired or _transaction_depth > 0 or _snapshot_busy or _cancelling or not is_inside_tree() or not is_node_ready() or not provider.is_valid():
		return _reject("Set a valid ephemeral portrait guard outside transactions")
	_presentation_guard = provider
	_guard_required = true
	return true


func activate(actor_id: String, response_context: Dictionary = {}) -> Dictionary:
	if _transaction_depth > 0 or _snapshot_busy or _cancelling or not _live_bindings() or get_tree().paused or not _actors.has(actor_id):
		return _denied("Activate a live unpaused bound Scout outside callbacks")
	var actor: Node3D = _actors[actor_id]
	var record: Dictionary = _records[actor_id]
	if _hero.dead or float(actor.get("hp")) <= 0.0 or record.status == "running" or not actor.is_visible_in_tree() or not (_cues[actor_id] as Node3D).is_visible_in_tree() or not (_opening_cues[actor_id] as Node3D).is_visible_in_tree() or not actor.global_position.is_equal_approx(_anchors[actor_id]) or not Codec.is_integer(record.cycle, 0, Codec.MAX_SAFE_INTEGER - 1):
		return _denied("Scout must be visible, anchored, alive and free of its prior exchange")
	var direction: Vector3 = _aim(actor_id, record.direction)
	var shape: Dictionary = _lane(actor_id, direction)
	var context: Dictionary = _provided_context(actor_id, shape, _context if response_context.is_empty() else response_context)
	if context.is_empty():
		return _denied(last_error)
	var error: String = _context_error(context)
	if not error.is_empty() or context.encounter_id != _context.encounter_id or context.world_revision != _context.world_revision or not _floors_allowed(context.floor_regions):
		return _denied("Response override must retain the authored encounter epoch and actual floor bindings")
	if not _source_available(actor_id) or not _presentation_allowed(actor_id, shape) or not _source_available(actor_id) or get_tree().paused:
		return _denied("Required Scout source/footprint/landing presentation unavailable")
	var threat: Dictionary = {"role": _role.duplicate(true), "geometry": shape, "source_stationary": true, "opening_stationary": true, "opening_position": actor.global_position, "cooldown_remaining_s": 0.0}
	_transaction_depth += 1
	var answer: Dictionary = _scheduler.request_tracking(actor, threat, _response(context))
	if answer.get("accepted", false):
		var reservation: Dictionary = _scheduler.reservation_state(String(answer.reservation_id))
		if reservation.is_empty() or int(reservation.source_instance_id) != actor.get_instance_id() or reservation.armed:
			_scheduler.cancel(String(answer.reservation_id), "missing_unarmed_scout_warning")
			answer = _denied("Accepted tracking warning lost its actual unarmed source")
		else:
			record.status = "running"
			record.phase = "warning"
			record.cycle += 1
			record.direction = direction
			record.exchange = _exchange_data(reservation)
			record.context = context
			record.sample = {"position": _hero.global_position, "clock_s": _scheduler.get_clock()}
			record.hit_consumed = false
			record.observed_hp = float(actor.get("hp"))
			record.flash_until_s = 0.0
			record.last_cancel_reason = ""
			record.presentation_witness = {}
			record.deferred_paths = []
			_proofs[actor_id] = {}
			_present(actor_id)
			if record.status == "running":
				var ready: bool = _ready_to_resolve(actor_id)
				if get_tree().paused:
					_freeze_paused_tick(_scheduler.get_clock())
				elif not ready:
					cancel(actor_id, "required_scout_presentation_unavailable")
	else:
		last_error = String(answer.get("reason", "Tracking warning rejected"))
	_transaction_depth -= 1
	return answer.duplicate(true)


func tick() -> void:
	if _transaction_depth > 0 or _snapshot_busy or get_tree().paused:
		return
	if not _live_bindings():
		if _configured and not _retired:
			cancel_all("required_bindings_unavailable")
		return
	_transaction_depth += 1
	var now: float = _scheduler.get_clock()
	for id: String in _actors:
		var record: Dictionary = _records[id]
		var actor: Node3D = _actors[id]
		if float(actor.get("hp")) < float(record.observed_hp):
			record.flash_until_s = now + FLASH_S if float(actor.get("hp")) > 0.0 else 0.0
			record.observed_hp = float(actor.get("hp"))
		if record.status != "running":
			_present(id, false)
			continue
		if _hero.dead or not _source_available(id):
			cancel(id, "required_scout_or_hero_unavailable")
			continue
		var live: Dictionary = _scheduler.reservation_state(String(record.exchange.id))
		# Querying the public reservation can prune and synchronously cancel us.
		if record.status != "running":
			continue
		if live.is_empty():
			if record.exchange.adapter.locked and now > float(record.exchange.recovery_until_s):
				record.status = "complete"
				record.phase = "clear"
				record.presentation_witness = {}
				record.deferred_paths = []
				_proofs[id] = {}
				_present(id)
			else:
				cancel(id, "reservation_missing")
			continue
		if int(live.source_instance_id) != actor.get_instance_id() or not actor.global_position.is_equal_approx(_anchors[id]) or _exchange_data(live) != record.exchange:
			cancel(id, "scout_exchange_changed")
			continue
		if not live.armed:
			var shape: Dictionary = _lane(id, _aim(id, record.direction))
			var framed: bool = _presentation_allowed(id, shape)
			if get_tree().paused:
				_freeze_paused_tick(now)
				_transaction_depth -= 1
				return
			if not framed or record.status != "running" or not _source_available(id):
				cancel(id, "required_scout_presentation_unavailable")
				continue
			var answer: Dictionary
			if now < float(live.lock_from_s):
				answer = _scheduler.update_tracking(String(live.id), shape)
			else:
				var current_context: Dictionary = _provided_context(id, shape, record.context)
				if get_tree().paused:
					_freeze_paused_tick(now)
					_transaction_depth -= 1
					return
				if record.status != "running":
					continue
				if current_context.is_empty() or not _context_error(current_context).is_empty() or current_context.encounter_id != _context.encounter_id or current_context.world_revision != _context.world_revision or not _floors_allowed(current_context.floor_regions):
					cancel(id, "fresh_authored_response_unavailable")
					continue
				record.context = current_context
				framed = _source_available(id) and _presentation_allowed(id, shape)
				if get_tree().paused:
					_freeze_paused_tick(now)
					_transaction_depth -= 1
					return
				if not framed or record.status != "running" or not _source_available(id):
					cancel(id, "required_scout_presentation_unavailable")
					continue
				var response: Dictionary = _response(current_context)
				# A stationary primary may be physically stable while a queued
				# weapon is about to replace its current timing/range snapshot.
				# Warning admission is unarmed; future lock proof waits for gear.
				if not response.get("pending_weapon_id") is String or not String(response.pending_weapon_id).is_empty():
					cancel(id, "tracking_pending_weapon_change")
					continue
				answer = _scheduler.commit_tracking(String(live.id), shape, response)
			if record.status != "running":
				continue
			if not answer.get("accepted", false):
				cancel(id, "tracking_lock_unproved" if now >= float(live.lock_from_s) else "tracking_update_failed")
				continue
			live = _scheduler.reservation_state(String(live.id))
			if live.is_empty() or record.status != "running":
				continue
			record.exchange = _exchange_data(live)
			record.direction = _direction(live.geometry)
			if live.armed:
				_proofs[id] = answer.get("proof", {}).duplicate(true)
				if not Geometry.finite_vector(_proofs[id].get("landing")) or not Geometry.finite_vector(_proofs[id].get("attack_position")):
					cancel(id, "required_presentation_witness_unavailable")
					continue
				record.presentation_witness = {"landing": _proofs[id].landing, "attack_position": _proofs[id].attack_position}
		record.phase = String(live.state)
		_present(id)
		# A held pause cannot preserve danger after this same publication lost
		# its actual source/cue. Retire it before any paused-path retention.
		if record.status == "running" and not _required_presentation_valid(id):
			cancel(id, "required_scout_presentation_unavailable")
		if get_tree().paused:
			_freeze_paused_tick(now)
			_transaction_depth -= 1
			return
		if record.status == "running":
			# Required presentation and its observers can synchronously hide,
			# remove, clear or cancel a source. Recheck before outgoing damage.
			var ready: bool = _ready_to_resolve(id)
			if get_tree().paused:
				_freeze_paused_tick(now)
				_transaction_depth -= 1
				return
			if not ready:
				cancel(id, "required_scout_presentation_unavailable")
				continue
			_resolve_segment(id, now, bool(live.armed))
			if get_tree().paused:
				_freeze_paused_tick(now)
				_transaction_depth -= 1
				return
	_transaction_depth -= 1


func _physics_process(_delta: float) -> void:
	tick()


func damage_window_open(actor_id: String) -> bool:
	# Actual deadlines close stale cosmetics before this later-priority redraw.
	if not _live_bindings() or get_tree().paused or _hero.dead or not _records.has(actor_id):
		return false
	var record: Dictionary = _records[actor_id]
	if record.status != "running" or record.phase != "recovery" or record.exchange.is_empty() or not record.exchange.adapter.locked or not _required_presentation_valid(actor_id):
		return false
	var live: Dictionary = _scheduler.reservation_state(String(record.exchange.id))
	# Cleanup observers may invalidate native custody or the required portrait
	# guard. Evaluate that guard after the query, once, then recheck native state.
	if get_tree().paused or record.status != "running" or not _required_presentation_valid(actor_id) or live.is_empty():
		return false
	if not _presentation_allowed(actor_id):
		return false
	return not get_tree().paused and record.status == "running" and _required_presentation_valid(actor_id) and int(live.source_instance_id) == (_actors[actor_id] as Node3D).get_instance_id() and live.armed and live.state == "recovery" and _scheduler.get_clock() > float(live.active_until_s) and _scheduler.get_clock() <= float(live.recovery_until_s) and _exchange_data(live) == record.exchange


func cancel(actor_id: String, reason: String = "scout_cancelled") -> bool:
	if _snapshot_busy or _cancelling or not _records.has(actor_id) or reason.is_empty():
		return false
	if _records[actor_id].status in ["cancelled", "complete", "defeated"]:
		return false # Preserve the committed original end/cancellation history.
	_cancelling = true
	_transaction_depth += 1
	var record: Dictionary = _records[actor_id]
	var reservation_id: String = String(record.exchange.get("id", "")) if record.status == "running" else ""
	if record.status != "defeated":
		record.status = "cancelled" if record.cycle > 0 else "idle"
		record.phase = "clear"
		record.last_cancel_reason = reason if record.cycle > 0 else ""
	record.presentation_witness = {}
	record.deferred_paths = []
	_proofs[actor_id] = {}
	if not reservation_id.is_empty() and is_instance_valid(_scheduler):
		_scheduler.cancel(reservation_id, reason)
	_present(actor_id)
	_transaction_depth -= 1
	_cancelling = false
	return true


func cancel_all(reason: String = "scout_encounter_cancelled") -> void:
	for id: String in _actors:
		cancel(id, reason)


func state(actor_id: String = "") -> Dictionary:
	if actor_id.is_empty():
		var result: Dictionary = {}
		for id: String in _actors:
			result[id] = state(id)
		return result
	if not _records.has(actor_id):
		return {}
	var record: Dictionary = _records[actor_id]
	var exchange: Dictionary = record.exchange
	var remaining: float = 0.0
	if record.status == "running":
		var key: String = {"warning": "lock_from_s", "lock": "active_from_s", "active": "active_until_s", "recovery": "recovery_until_s"}.get(record.phase, "")
		if not key.is_empty():
			remaining = maxf(float(exchange[key]) - _scheduler.get_clock(), 0.0)
	return {"api_revision": API_REVISION, "actor_id": actor_id, "status": record.status, "phase": record.phase, "cycle": record.cycle, "remaining_s": remaining, "armed": record.status == "running" and exchange.adapter.locked, "reservation_id": exchange.get("id", "") if record.status == "running" else "", "geometry": exchange.get("geometry", {}).duplicate(true), "direction": record.direction, "source_position": _anchors[actor_id], "exchange": exchange.duplicate(true), "resolved_role": _role.duplicate(true), "hit_consumed": record.hit_consumed, "last_cancel_reason": record.last_cancel_reason, "proof": _proofs.get(actor_id, {}).duplicate(true), "proof_available": not _proofs.get(actor_id, {}).is_empty(), "presentation_witness": record.presentation_witness.duplicate(true)}


func get_cue(actor_id: String) -> CinderThreatCue:
	return _cues.get(actor_id) as CinderThreatCue


func get_opening_cue(actor_id: String) -> CinderInteractionCue:
	return _opening_cues.get(actor_id) as CinderInteractionCue


func _resolve_segment(id: String, now: float, armed: bool) -> void:
	if get_tree().paused:
		return
	var record: Dictionary = _records[id]
	var previous: Dictionary = record.sample
	var path: Array[Dictionary] = []
	for segment: Dictionary in record.deferred_paths:
		path.append(segment.duplicate(true))
	path.append({"from": previous.position, "to": _hero.global_position, "start_s": previous.clock_s, "end_s": now})
	record.sample = {"position": _hero.global_position, "clock_s": now}
	record.deferred_paths = []
	# Geometry's conservative epsilon may overlap a floating-point instant
	# just before activation. Required active presentation must happen first.
	if not armed or _hero.dead or record.hit_consumed or now < float(record.exchange.active_from_s) or not Geometry.timed_path_hits(record.exchange.geometry, path, float(record.exchange.active_from_s), float(record.exchange.active_until_s), CinderThreatScheduler.CAPSULE_RADIUS):
		return
	record.hit_consumed = true
	var before: float = _hero.hp
	_hero.take_damage(float(_role.damage), Vector3.ZERO)
	hit_resolved.emit(id, {"opportunity_consumed": true, "accepted": _hero.hp < before, "raw_damage": _role.damage, "hp_damage": maxf(before - _hero.hp, 0.0), "impulse": Vector3.ZERO})


func _freeze_paused_tick(now: float) -> void:
	# A synchronous pause retains valid measured overlap, never damage. Native
	# custody is checked against the existing synchronized cue/phase first;
	# redraw cannot recreate authority hidden/cleared by a same-tick observer.
	if not _live_bindings():
		return
	if _hero.dead:
		cancel_all("required_scout_or_hero_unavailable")
		return
	for id: String in _records:
		var record: Dictionary = _records[id]
		if record.status != "running":
			continue
		if not _required_presentation_valid(id):
			cancel(id, "required_scout_presentation_unavailable")
			continue
		var live: Dictionary = _scheduler.reservation_state(String(record.exchange.id))
		if record.status != "running":
			continue
		if live.is_empty() or not _required_presentation_valid(id) or int(live.source_instance_id) != (_actors[id] as Node3D).get_instance_id() or _exchange_data(live) != record.exchange:
			cancel(id, "required_scout_presentation_unavailable")
			continue
		# Another source can still carry its prior lock cue at this same paused
		# frame. Synchronize phase and complete redraw together before the guard.
		record.phase = String(live.state)
		_present(id, false)
		if record.status != "running":
			continue
		if not _required_presentation_valid(id) or not _presentation_allowed(id) or not _required_presentation_valid(id):
			cancel(id, "required_scout_presentation_unavailable")
			continue
		var previous: Dictionary = record.sample
		if live.armed and not record.hit_consumed and now >= float(live.active_from_s) and float(previous.clock_s) <= float(live.active_until_s) and now > float(previous.clock_s):
			if record.deferred_paths.size() >= MAX_DEFERRED_PATHS:
				cancel(id, "deferred_scout_path_limit")
				continue
			record.deferred_paths.append({"from": previous.position, "to": _hero.global_position, "start_s": previous.clock_s, "end_s": now})
		record.sample = {"position": _hero.global_position, "clock_s": now}


func _present(id: String, notify: bool = true) -> void:
	var record: Dictionary = _records[id]
	var cue: Variant = _cues[id]
	var opening: Variant = _opening_cues[id]
	if not is_instance_valid(cue) or not is_instance_valid(opening) or not is_instance_valid(_actors[id]):
		if is_instance_valid(cue):
			cue.clear()
		if is_instance_valid(opening):
			opening.clear()
		return
	if record.status == "running":
		if not cue.present(record.exchange.geometry, record.phase):
			cancel(id, "required_cue_rejected")
			return
	else:
		cue.clear()
	if not is_instance_valid(cue) or not is_instance_valid(opening) or not is_instance_valid(_actors[id]):
		cancel(id, "required_bindings_unavailable")
		return
	# Handle cancellation requested synchronously by a cue observer.
	if record.status != "running":
		cue.clear()
	if record.status == "defeated":
		opening.present("spent", "attack")
	elif record.status == "running" and record.phase == "recovery":
		opening.present("active" if _scheduler.get_clock() < float(record.flash_until_s) or float((_actors[id] as Node3D).get("hp")) < float(record.observed_hp) else "available", "attack")
	else:
		opening.clear()
	if not is_instance_valid(cue) or not is_instance_valid(opening) or not is_instance_valid(_actors[id]):
		cancel(id, "required_bindings_unavailable")
		return
	# Clear again after a synchronous opening observer's cancellation returns.
	if record.status != "running":
		cue.clear()
		if record.status == "defeated":
			opening.present("spent", "attack")
		else:
			opening.clear()
	var actor: Node3D = _actors[id]
	var pose: String = record.phase if record.status == "running" else ("defeated" if record.status == "defeated" else "idle")
	var progress: float = _progress(record, _scheduler.get_clock()) if record.status == "running" else (1.0 if pose == "defeated" else 0.0)
	actor.call("present_phase", pose, progress, record.direction, _scheduler.get_clock() < float(record.flash_until_s) or float(actor.get("hp")) < float(record.observed_hp))
	if notify:
		state_changed.emit(id, state(id))


func _on_invalidated(reservation_id: String, reason: String) -> void:
	if _cancelling or _snapshot_busy:
		return
	for id: String in _records:
		var record: Dictionary = _records[id]
		if record.status == "running" and record.exchange.get("id") == reservation_id:
			cancel(id, reason)
			break


func _on_defeated(actor_id: String) -> void:
	if not _records.has(actor_id) or _records[actor_id].status == "defeated":
		return
	_transaction_depth += 1
	_cancelling = true
	var record: Dictionary = _records[actor_id]
	record.status = "defeated"
	record.phase = "defeated"
	record.observed_hp = 0.0
	record.flash_until_s = 0.0
	record.last_cancel_reason = "source_defeated"
	record.presentation_witness = {}
	record.deferred_paths = []
	_proofs[actor_id] = {}
	_scheduler.cancel_owner(_actors[actor_id], "source_defeated")
	_cancelling = false
	_present(actor_id)
	# Source HP already committed. Parent queues progression until damage returns.
	scout_defeated.emit(actor_id)
	_transaction_depth -= 1


func _response(context: Dictionary) -> Dictionary:
	var result: Dictionary = _hero.get_threat_response_state()
	for key: String in CONTEXT_KEYS:
		if key != "encounter_id":
			result[key] = context[key]
	return result


func _provided_context(id: String, geometry: Dictionary, fallback: Dictionary) -> Dictionary:
	if not _provider_required:
		return fallback.duplicate(true)
	if not _context_provider.is_valid():
		last_error = "Registered authored response provider is unavailable"
		return {}
	_transaction_depth += 1
	var value: Variant = _context_provider.call(id, geometry.duplicate(true))
	_transaction_depth -= 1
	if not value is Dictionary:
		last_error = "Authored response provider must return a current context dictionary"
		return {}
	return value.duplicate(true)


func _presentation_allowed(id: String, geometry: Dictionary = {}) -> bool:
	if not _guard_required:
		return true
	if not _presentation_guard.is_valid():
		return false
	var proposed: Dictionary = state(id)
	if not geometry.is_empty():
		proposed.geometry = geometry.duplicate(true)
		proposed.direction = _direction(geometry)
		if proposed.exchange.is_empty():
			proposed.exchange = {"geometry": geometry.duplicate(true)}
		else:
			proposed.exchange.geometry = geometry.duplicate(true)
	_transaction_depth += 1
	var accepted: Variant = _presentation_guard.call(id, proposed.duplicate(true))
	_transaction_depth -= 1
	return accepted is bool and accepted


func _source_available(id: String) -> bool:
	if not _live_bindings() or not _actors.has(id) or _hero.dead or not is_visible_in_tree():
		return false
	var actor: Node3D = _actors[id]
	return float(actor.get("hp")) > 0.0 and actor.is_visible_in_tree() and actor.global_position.is_equal_approx(_anchors[id]) and (_cues[id] as Node3D).is_visible_in_tree() and (_opening_cues[id] as Node3D).is_visible_in_tree()


func _required_presentation_valid(id: String) -> bool:
	if not _source_available(id) or _records[id].status != "running":
		return false
	var record: Dictionary = _records[id]
	var cue_state: Dictionary = (_cues[id] as CinderThreatCue).state()
	var opening_state: Dictionary = (_opening_cues[id] as CinderInteractionCue).state()
	if cue_state.phase != record.phase or cue_state.geometry != record.exchange.geometry or not cue_state.source_visible or cue_state.footprint_visible != (record.phase != "recovery") or cue_state.active_fill_visible != (record.phase == "active"):
		return false
	if record.phase == "recovery":
		return opening_state.state in ["available", "active"] and opening_state.trigger == "attack" and opening_state.visible
	return opening_state.state == "clear"


func _ready_to_resolve(id: String) -> bool:
	if get_tree().paused or not _required_presentation_valid(id):
		return false
	var record: Dictionary = _records[id]
	var live: Dictionary = _scheduler.reservation_state(String(record.exchange.id))
	if get_tree().paused or record.status != "running" or not _required_presentation_valid(id) or live.is_empty():
		return false
	if not _presentation_allowed(id):
		return false
	return not get_tree().paused and record.status == "running" and _required_presentation_valid(id) and int(live.source_instance_id) == (_actors[id] as Node3D).get_instance_id() and _exchange_data(live) == record.exchange


func _aim(id: String, fallback: Vector3) -> Vector3:
	var flat: Vector3 = _hero.global_position - (_actors[id] as Node3D).global_position
	flat.y = 0.0
	return flat.normalized() if flat.length_squared() > EPSILON * EPSILON else fallback


func _lane(id: String, direction: Vector3) -> Dictionary:
	return Geometry.lane(_anchors[id], _anchors[id] + direction * REACH, RADIUS)


func _direction(shape: Dictionary) -> Vector3:
	return (shape["to"] - shape["from"]).normalized()


func _exchange_data(record: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: String in EXCHANGE_KEYS:
		result[key] = record[key]
	return result.duplicate(true)


func _progress(record: Dictionary, now: float) -> float:
	var keys: Array = {"warning": ["start_s", "lock_from_s"], "lock": ["lock_from_s", "active_from_s"], "active": ["active_from_s", "active_until_s"], "recovery": ["active_until_s", "recovery_until_s"]}.get(record.phase, [])
	if keys.is_empty():
		return 0.0
	return clampf((now - float(record.exchange[keys[0]])) / (float(record.exchange[keys[1]]) - float(record.exchange[keys[0]])), 0.0, 1.0)


func _context_error(context: Dictionary) -> String:
	var error: String = Codec.keys_error(context, CONTEXT_KEYS)
	if not error.is_empty() or not _stable_id(context.get("encounter_id")) or not Codec.is_integer(context.get("world_revision"), 1) or not Codec.is_number(context.get("recognition_s")) or float(context.recognition_s) <= 0.0 or not Codec.is_number(context.get("attack_input_margin_s")) or float(context.attack_input_margin_s) < 0.0 or not context.get("floor_regions") is Array or context.floor_regions.is_empty():
		return "Finite exact authored response context required"
	for key: String in ["escape_directions", "return_directions"]:
		if not context.get(key) is Array or context[key].size() > 16 or (key == "escape_directions" and context[key].is_empty()):
			return "At most16 finite authored escape/return directions required"
		for value: Variant in context[key]:
			if not Geometry.finite_vector(value) or absf(value.y) > EPSILON or absf(value.length_squared() - 1.0) > EPSILON:
				return "Authored candidate must be a normalized planar swipe"
	for region: Variant in context.floor_regions:
		if not region is Dictionary or not region.get("collision") is CollisionShape3D or not region.get("safe_rect") is Rect2:
			return "Actual floor collision and authored safe rectangle required"
	return ""


func _floors_allowed(regions: Array) -> bool:
	for region: Dictionary in regions:
		var found: bool = false
		for authored: Dictionary in _context.floor_regions:
			if region.collision == authored.collision and region.safe_rect == authored.safe_rect:
				found = true
		if not found:
			return false
	return true


func _live_bindings() -> bool:
	if not _configured or _retired or not is_inside_tree() or not is_node_ready() or is_queued_for_deletion() or not is_instance_valid(_hero) or not is_instance_valid(_effects) or not is_instance_valid(_scheduler) or not _hero.is_inside_tree() or not _effects.is_inside_tree() or not _scheduler.is_inside_tree() or _hero.is_queued_for_deletion() or _effects.is_queued_for_deletion() or _scheduler.is_queued_for_deletion() or _hero.get_world_3d() != get_world_3d() or _effects.get_world_3d() != get_world_3d() or _scheduler.get_world_3d() != get_world_3d():
		return false
	for id: String in _actors:
		var actor: Variant = _actors[id]
		if not is_instance_valid(actor) or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.get_world_3d() != get_world_3d() or not bool(actor.call("is_armed")) or not is_instance_valid(_cues[id]) or not is_instance_valid(_opening_cues[id]) or not (_cues[id] as Node3D).is_inside_tree() or not (_opening_cues[id] as Node3D).is_inside_tree() or (_cues[id] as Node3D).is_queued_for_deletion() or (_opening_cues[id] as Node3D).is_queued_for_deletion():
			return false
	return true


func cleanup() -> void:
	if _retired or _snapshot_busy or _transaction_depth > 0:
		return
	cancel_all("exchange_removed")
	_retired = true
	if is_instance_valid(_scheduler) and _scheduler.reservation_invalidated.is_connected(_on_invalidated):
		_scheduler.reservation_invalidated.disconnect(_on_invalidated)
	for id: String in _actors:
		var actor: Variant = _actors[id]
		if is_instance_valid(actor) and actor.is_connected("defeated", _on_defeated):
			actor.disconnect("defeated", _on_defeated)
		if is_instance_valid(actor):
			actor.call("release_damage_window", Callable(self, "damage_window_open").bind(id))
	for cue: Variant in _cues.values():
		if is_instance_valid(cue):
			cue.clear()
	for cue: Variant in _opening_cues.values():
		if is_instance_valid(cue):
			cue.clear()
	_configured = false
	_hero = null
	_effects = null
	_scheduler = null
	_actors.clear()
	_anchors.clear()
	_context.clear()
	_records.clear()
	_proofs.clear()
	_context_provider = Callable()
	_presentation_guard = Callable()


func disarm() -> void:
	cleanup()


func _exit_tree() -> void:
	cleanup()


func _stable_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 128:
		return false
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9][A-Za-z0-9_:/.-]*$")
	var found: RegExMatch = pattern.search(value)
	return found != null and found.get_string() == value


func _same_copied_scalar(value: Variant, expected: Variant) -> bool:
	# These fields are copied from one authoritative paused clock/reservation.
	# They are not independently reconstructed durations or cosmetic progress.
	return Codec.is_number(value) and Codec.is_number(expected) and float(value) == float(expected)


func _same_copied_exchange_value(key: String, value: Variant, expected: Variant) -> bool:
	if key in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		return _same_copied_scalar(value, expected)
	if key == "adapter":
		if not value is Dictionary or not expected is Dictionary or value.size() != expected.size():
			return false
		for adapter_key: String in value:
			if not expected.has(adapter_key):
				return false
			if Codec.is_number(value[adapter_key]) or Codec.is_number(expected[adapter_key]):
				if not _same_copied_scalar(value[adapter_key], expected[adapter_key]):
					return false
			elif typeof(value[adapter_key]) != typeof(expected[adapter_key]) or value[adapter_key] != expected[adapter_key]:
				return false
		return true
	# Native vector reconstruction and independently derived geometry retain
	# their existing codec policy; this helper only tightens copied scalars.
	return Codec.same_values(value, expected)


func _near(value: Variant, expected: float) -> bool:
	return Codec.is_number(value) and is_equal_approx(float(value), expected)


func _reject(reason: String) -> bool:
	last_error = reason
	return false


func _denied(reason: String) -> Dictionary:
	last_error = reason
	return {"accepted": false, "reason": reason}


## Local JSON includes actor state; scheduler is a separate paired envelope.
## Pure preflight validates saved samples internally, never against a fresh hero.
## Actual commit requires the restored player/actor/scheduler unit at this clock.
func snapshot_state(bindings: Dictionary) -> Dictionary:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty():
		return {}
	_snapshot_busy = true
	var paired: Dictionary = _scheduler.snapshot_state(bindings)
	var snapshot: Dictionary = {}
	if paired.is_empty():
		last_snapshot_error = _scheduler.last_snapshot_error
	else:
		var records: Dictionary = {}
		var actors: Dictionary = {}
		for id: String in _actors:
			records[id] = _encode_record(_records[id], bindings)
			actors[id] = (_actors[id] as Node3D).call("snapshot_state")
		snapshot = {"api_revision": API_REVISION, "schema_version": 1, "configuration": _encode_configuration(bindings), "clock_s": paired.clock_s, "records": records, "actors": actors}
		last_snapshot_error = _snapshot_plan_error(snapshot, bindings, paired, true, true)
	_snapshot_busy = false
	return snapshot.duplicate(true) if last_snapshot_error.is_empty() else {}


func snapshot_error(snapshot: Dictionary, bindings: Dictionary, staged_scheduler_snapshot: Dictionary = {}) -> String:
	var error: String = _snapshot_access_error()
	if not error.is_empty():
		return error
	_snapshot_busy = true
	var paired: Dictionary = staged_scheduler_snapshot.duplicate(true) if not staged_scheduler_snapshot.is_empty() else _scheduler.snapshot_state(bindings)
	error = _scheduler.last_snapshot_error if paired.is_empty() else _scheduler.snapshot_error(paired, bindings)
	if error.is_empty():
		error = _snapshot_plan_error(snapshot, bindings, paired)
	_snapshot_busy = false
	return error


func restore_state(snapshot: Dictionary, bindings: Dictionary) -> bool:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty():
		return false
	_snapshot_busy = true
	var paired: Dictionary = _scheduler.snapshot_state(bindings)
	last_snapshot_error = _scheduler.last_snapshot_error if paired.is_empty() else _snapshot_plan_error(snapshot, bindings, paired, true)
	if not last_snapshot_error.is_empty():
		_snapshot_busy = false
		return false
	_profile_id = snapshot.configuration.profile_id
	_role = snapshot.configuration.resolved_role.duplicate(true)
	_context.encounter_id = snapshot.configuration.encounter_id
	_context.world_revision = int(snapshot.configuration.world_revision)
	_context = _decode_context(snapshot.configuration.context, bindings)
	for id: String in _actors:
		_records[id] = _decode_record(snapshot.records[id], bindings)
		_proofs[id] = {} # Diagnostics never replace a saved scheduler authority.
		var cue: CinderThreatCue = _cues[id]
		var opening: CinderInteractionCue = _opening_cues[id]
		var cue_blocked: bool = cue.is_blocking_signals()
		var opening_blocked: bool = opening.is_blocking_signals()
		cue.set_block_signals(true)
		opening.set_block_signals(true)
		cue.clear()
		opening.clear()
		_present_saved(id, snapshot.actors[id])
		cue.set_block_signals(cue_blocked)
		opening.set_block_signals(opening_blocked)
	_snapshot_busy = false
	return true


func _present_saved(id: String, actor_state: Dictionary) -> void:
	var record: Dictionary = _records[id]
	if record.status == "running":
		(_cues[id] as CinderThreatCue).present(record.exchange.geometry, record.phase)
	if record.status == "defeated":
		(_opening_cues[id] as CinderInteractionCue).present("spent", "attack")
	elif record.status == "running" and record.phase == "recovery":
		(_opening_cues[id] as CinderInteractionCue).present("active" if _scheduler.get_clock() < float(record.flash_until_s) or float(actor_state.hp) < float(record.observed_hp) else "available", "attack")
	# The public owned visual API redraws saved cosmetics even for a dead shared
	# hero; live actor presentation/damage continue rejecting that hero.
	var visual: Node3D = (_actors[id] as Node3D).get_node("ScoutRig") as Node3D
	visual.call("restore_pose", actor_state.phase, float(actor_state.phase_progress), Codec.read_vector3(actor_state.direction), float(actor_state.body_yaw), _scheduler.get_clock() < float(record.flash_until_s) or float(actor_state.hp) < float(record.observed_hp))


func _snapshot_access_error() -> String:
	if not _live_bindings() or not get_tree().paused:
		return "Exchange snapshots require ready bound actors at the paused aggregate barrier"
	if _transaction_depth > 0 or _snapshot_busy or _cancelling:
		return "Exchange snapshots reject inside physics/damage/cue/cancellation transactions"
	return ""


func _encode_configuration(bindings: Dictionary) -> Dictionary:
	var anchors: Dictionary = {}
	for id: String in _anchors:
		anchors[id] = Codec.vector3(_anchors[id])
	return {"profile_id": _profile_id, "encounter_id": _context.encounter_id, "world_revision": _context.world_revision, "anchors": anchors, "raw_role": RAW_ROLE.duplicate(true), "timing_floors": TIMING_FLOORS.duplicate(true), "resolved_role": _role.duplicate(true), "context": _encode_context(_context, bindings)}


func _encode_context(context: Dictionary, bindings: Dictionary) -> Dictionary:
	if context.is_empty():
		return {}
	var escapes: Array = []
	var returns: Array = []
	var floors: Array[String] = []
	for direction: Vector3 in context.escape_directions:
		escapes.append(Codec.vector3(direction))
	for direction: Vector3 in context.return_directions:
		returns.append(Codec.vector3(direction))
	for region: Dictionary in context.floor_regions:
		var found: String = ""
		for id: String in bindings.get("floors", {}):
			if bindings.floors[id].collision == region.collision and bindings.floors[id].safe_rect == region.safe_rect:
				found = id
		floors.append(found)
	return {"recognition_s": context.recognition_s, "attack_input_margin_s": context.attack_input_margin_s, "escape_directions": escapes, "return_directions": returns, "floor_ids": floors}


func _decode_context(value: Dictionary, bindings: Dictionary) -> Dictionary:
	if value.is_empty():
		return {}
	var result: Dictionary = {"encounter_id": _context.encounter_id, "world_revision": _context.world_revision, "recognition_s": value.recognition_s, "attack_input_margin_s": value.attack_input_margin_s, "escape_directions": [], "return_directions": [], "floor_regions": []}
	for key: String in ["escape_directions", "return_directions"]:
		for direction: Array in value[key]:
			result[key].append(Codec.read_vector3(direction))
	for id: String in value.floor_ids:
		result.floor_regions.append(bindings.floors[id].duplicate())
	return result


func _encode_record(record: Dictionary, bindings: Dictionary) -> Dictionary:
	var result: Dictionary = record.duplicate(true)
	result.direction = Codec.vector3(record.direction)
	result.context = _encode_context(record.context, bindings)
	if not record.sample.is_empty():
		result.sample = {"position": Codec.vector3(record.sample.position), "clock_s": record.sample.clock_s}
	for key: String in record.presentation_witness:
		result.presentation_witness[key] = Codec.vector3(record.presentation_witness[key])
	for segment: Dictionary in result.deferred_paths:
		segment["from"] = Codec.vector3(segment["from"])
		segment["to"] = Codec.vector3(segment["to"])
	if not record.exchange.is_empty():
		result.exchange.geometry = {"kind": "lane", "from": Codec.vector3(record.exchange.geometry["from"]), "to": Codec.vector3(record.exchange.geometry["to"]), "radius": record.exchange.geometry.radius}
		result.exchange.source_position = Codec.vector3(record.exchange.source_position)
		result.exchange.opening_position = Codec.vector3(record.exchange.opening_position)
	return result


func _decode_record(value: Dictionary, bindings: Dictionary) -> Dictionary:
	var result: Dictionary = value.duplicate(true)
	result.direction = Codec.read_vector3(value.direction)
	result.context = _decode_context(value.context, bindings)
	if not value.sample.is_empty():
		result.sample.position = Codec.read_vector3(value.sample.position)
	for key: String in value.presentation_witness:
		result.presentation_witness[key] = Codec.read_vector3(value.presentation_witness[key])
	for segment: Dictionary in result.deferred_paths:
		segment["from"] = Codec.read_vector3(segment["from"])
		segment["to"] = Codec.read_vector3(segment["to"])
	if not value.exchange.is_empty():
		result.exchange.source_position = Codec.read_vector3(value.exchange.source_position)
		result.exchange.opening_position = Codec.read_vector3(value.exchange.opening_position)
		result.exchange.geometry = Geometry.lane(Codec.read_vector3(value.exchange.geometry["from"]), Codec.read_vector3(value.exchange.geometry["to"]), float(value.exchange.geometry.radius))
	return result


func _snapshot_plan_error(snapshot: Dictionary, bindings: Dictionary, paired: Dictionary, actual: bool = false, capture: bool = false) -> String:
	var error: String = Codec.value_error(snapshot)
	if error.is_empty():
		error = Codec.keys_error(snapshot, ["api_revision", "schema_version", "configuration", "clock_s", "records", "actors"])
	if not error.is_empty():
		return error
	if not actual:
		if bindings.has("hero_positions") and not bindings.hero_positions is Dictionary:
			return "Staged hero_positions must name the finite bound hero position"
		for id: Variant in bindings.get("hero_positions", {}):
			if id != "hero" or not Geometry.finite_vector(bindings.hero_positions[id]):
				return "Staged hero_positions require the stable hero binding"
	if snapshot.api_revision != API_REVISION or not Codec.is_integer(snapshot.schema_version, 1, 1) or not snapshot.configuration is Dictionary or not _same_copied_scalar(snapshot.clock_s, paired.clock_s) or not snapshot.records is Dictionary or not snapshot.actors is Dictionary or not Codec.keys_error(snapshot.records, _actors.keys()).is_empty() or not Codec.keys_error(snapshot.actors, _actors.keys()).is_empty():
		return "Invalid exchange identity/configuration/schema or paired clock"
	var configuration: Dictionary = snapshot.configuration
	if not Codec.keys_error(configuration, ["profile_id", "encounter_id", "world_revision", "anchors", "raw_role", "timing_floors", "resolved_role", "context"]).is_empty() or not configuration.profile_id is String or not _stable_id(configuration.encounter_id) or not Codec.is_integer(configuration.world_revision, 1) or not configuration.resolved_role is Dictionary:
		return "Invalid saved encounter configuration"
	var authored: Dictionary = _encode_configuration(bindings)
	for key: String in ["anchors", "raw_role", "timing_floors"]:
		if not Codec.same_values(configuration[key], authored[key]):
			return "Saved encounter must retain immutable authored roots/raw role/floors/candidates"
	if not configuration.context is Dictionary:
		return "Saved encounter requires its authored response context"
	for key: String in ["recognition_s", "attack_input_margin_s", "floor_ids"]:
		if not Codec.same_values(configuration.context.get(key), authored.context.get(key)):
			return "Saved encounter must retain authored recognition/input margin and actual floors"
	var resolved: Dictionary = Difficulty.new().resolve_role(RAW_ROLE, configuration.profile_id, TIMING_FLOORS)
	if resolved.is_empty() or not Codec.same_values(configuration.resolved_role, resolved):
		return "Resolve the saved fixed profile from authored raw data, independent of current preference"
	var ended: bool = paired.encounter_id.is_empty()
	if not ended and (paired.encounter_id != configuration.encounter_id or paired.world_revision != configuration.world_revision or paired.profile.get("id") != configuration.profile_id):
		return "Exchange must retain its parent's fixed encounter/profile/world epoch"
	error = _saved_context_error(snapshot.configuration.context, bindings)
	if not error.is_empty():
		return error
	for id: String in _actors:
		if bindings.get("owners", {}).get(id) != _actors[id]:
			return "Exchange requires actual stable Scout scheduler owner bindings"
		var record: Variant = snapshot.records[id]
		var actor_state: Variant = snapshot.actors[id]
		if not record is Dictionary or not actor_state is Dictionary:
			return "Scout record and actor must be JSON dictionaries"
		error = (_actors[id] as Node3D).call("snapshot_error", actor_state)
		if not error.is_empty() or not _near(actor_state.max_hp, float(resolved.max_hp)):
			return "Saved Scout actor must validate and retain resolved canonical maxHP"
		if actual and not Codec.same_values(actor_state, (_actors[id] as Node3D).call("snapshot_state")):
			return "Restore saved actors before committing the paired exchange"
		error = _record_error(id, record, actor_state, paired, bindings, actual, capture, configuration, resolved)
		if not error.is_empty():
			return error
	return ""


func _record_error(id: String, record: Dictionary, actor_state: Dictionary, paired: Dictionary, bindings: Dictionary, actual: bool, capture: bool, configuration: Dictionary, resolved: Dictionary) -> String:
	var error: String = Codec.keys_error(record, RECORD_KEYS)
	if not error.is_empty():
		return error
	if record.status not in ["idle", "running", "cancelled", "complete", "defeated"] or record.phase not in ["clear", "warning", "lock", "active", "recovery", "defeated"] or not Codec.is_integer(record.cycle) or not record.exchange is Dictionary or not record.context is Dictionary or not record.sample is Dictionary or not record.presentation_witness is Dictionary or not record.deferred_paths is Array or record.deferred_paths.size() > MAX_DEFERRED_PATHS or not record.hit_consumed is bool or not Codec.in_range(record.observed_hp, float(actor_state.hp), float(resolved.max_hp)) or not Codec.in_range(record.flash_until_s, 0.0, float(paired.clock_s) + FLASH_S + EPSILON) or not record.last_cancel_reason is String or not Codec.is_vector3(record.direction):
		return "Invalid finite Scout exchange record/latches"
	var direction: Vector3 = Codec.read_vector3(record.direction)
	if direction.y != 0.0 or absf(direction.length_squared() - 1.0) > EPSILON or not direction.is_equal_approx(Codec.read_vector3(actor_state.direction)):
		return "Saved Scout mirror direction must match its actor tuple"
	var owned: Dictionary = {}
	for reservation: Dictionary in paired.reservations:
		if reservation.source_id == id:
			owned = reservation
	var cooldown: Dictionary = {}
	for value: Dictionary in paired.cooldowns:
		if value.source_id == id:
			cooldown = value
	if (record.status == "defeated") != (float(actor_state.hp) <= 0.0):
		return "Driver defeat state must agree with the actor tombstone"
	if record.status != "running" and not record.presentation_witness.is_empty():
		return "Inactive Scout cannot retain an available view witness"
	if record.status != "running" and not record.deferred_paths.is_empty():
		return "Inactive Scout cannot retain a deferred ray path"
	if record.cycle == 0:
		return "Unstarted Scout cannot retain an exchange, sample, hit or cooldown" if record.status not in ["idle", "defeated"] or record.phase != ("defeated" if record.status == "defeated" else "clear") or not record.exchange.is_empty() or not record.context.is_empty() or not record.sample.is_empty() or record.hit_consumed or not owned.is_empty() or not cooldown.is_empty() else ""
	if not Codec.keys_error(record.exchange, EXCHANGE_KEYS).is_empty() or not Codec.keys_error(record.sample, ["position", "clock_s"]).is_empty():
		return "Executed Scout requires its finite exchange and previous shared-hero sample"
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not Codec.in_range(record.exchange[key], 0.0, float(paired.clock_s) + float(resolved.windup_s) + float(resolved.active_s) + float(resolved.recovery_s) + float(resolved.attack_interval_s)):
			return "Scout deadlines must be finite and within its bounded exchange"
	if not Codec.is_vector3(record.sample.position) or not Codec.in_range(record.sample.clock_s, float(record.exchange.start_s), float(paired.clock_s)):
		return "Executed Scout requires a finite previous shared-hero sample"
	error = _saved_context_error(record.context, bindings)
	if not error.is_empty():
		return error
	var exchange: Dictionary = record.exchange
	if not exchange.id is String or not exchange.id.begins_with("threat-") or not exchange.id.substr(7).is_valid_int() or not Codec.is_integer(int(exchange.id.substr(7)), 1, int(paired.serial)) or exchange.id != "threat-%d" % int(exchange.id.substr(7)) or exchange.profile_id != configuration.profile_id or exchange.world_revision != configuration.world_revision or not Codec.is_vector3(exchange.source_position) or not Codec.is_vector3(exchange.opening_position) or not Codec.read_vector3(exchange.source_position).is_equal_approx(_anchors[id]) or not Codec.read_vector3(exchange.opening_position).is_equal_approx(_anchors[id]) or not exchange.geometry is Dictionary or not Codec.keys_error(exchange.geometry, ["kind", "from", "to", "radius"]).is_empty() or exchange.geometry.kind != "lane" or not Codec.is_vector3(exchange.geometry["from"]) or not Codec.is_vector3(exchange.geometry["to"]) or not _near(exchange.geometry.radius, RADIUS):
		return "Saved Scout lane must retain its stable reservation and actual low housing"
	var shape: Dictionary = Geometry.lane(Codec.read_vector3(exchange.geometry["from"]), Codec.read_vector3(exchange.geometry["to"]), float(exchange.geometry.radius))
	if not shape["from"].is_equal_approx(_anchors[id]) or not shape["to"].is_equal_approx(_anchors[id] + direction * REACH) or not Geometry.error(shape).is_empty():
		return "Saved Scout capsule must retain exact direction/reach/radius including endcaps"
	var adapter: Dictionary = exchange.adapter if exchange.adapter is Dictionary else {}
	var expected_adapter: Dictionary = {"kind": "tracking", "locked": adapter.get("locked"), "reach": REACH, "radius": RADIUS, "lock_s": resolved.lock_s, "active_s": resolved.active_s, "recovery_s": resolved.recovery_s, "attack_interval_s": resolved.attack_interval_s}
	if not adapter.get("locked") is bool or not Codec.same_values(adapter, expected_adapter):
		return "Scout must retain the exact published tracking adapter"
	if record.status == "running" and adapter.locked:
		if not Codec.keys_error(record.presentation_witness, ["landing", "attack_position"]).is_empty():
			return "Armed Scout requires the two accepted presentation witness positions"
		for key: String in ["landing", "attack_position"]:
			if not Codec.is_vector3(record.presentation_witness[key]) or not _witness_supported(Codec.read_vector3(record.presentation_witness[key]), _decode_context(record.context, bindings)):
				return "Presentation witness must remain finite on the actual authored floor"
			# This preserves the accepted native view witness at capture. Once
			# transported it is only framing data, never scheduler/damage proof.
			if capture and not _proofs.get(id, {}).is_empty() and not Codec.read_vector3(record.presentation_witness[key]).is_equal_approx(_proofs[id][key]):
				return "Capture view witness must retain its originally accepted proof position"
	elif not record.presentation_witness.is_empty():
		return "Unarmed Scout cannot manufacture an accepted view witness"
	if not record.deferred_paths.is_empty():
		if not adapter.locked or record.hit_consumed:
			return "Only an unconsumed armed opportunity can retain a deferred path"
		var previous: Dictionary = {}
		for segment: Variant in record.deferred_paths:
			if not segment is Dictionary or not Codec.keys_error(segment, ["from", "to", "start_s", "end_s"]).is_empty() or not Codec.is_vector3(segment["from"]) or not Codec.is_vector3(segment["to"]) or not Codec.in_range(segment.start_s, float(exchange.start_s), float(paired.clock_s)) or not Codec.in_range(segment.end_s, float(segment.start_s), float(paired.clock_s)) or float(segment.end_s) < float(exchange.active_from_s) or float(segment.start_s) > float(exchange.active_until_s):
				return "Deferred ray segments must retain finite measured active intervals"
			if not previous.is_empty() and (not _same_copied_scalar(segment.start_s, previous.end_s) or not Codec.read_vector3(segment["from"]).is_equal_approx(Codec.read_vector3(previous["to"]))):
				return "Deferred measured ray path cannot teleport between paused samples"
			previous = segment
		if float(previous.end_s) > float(record.sample.clock_s) or (_same_copied_scalar(previous.end_s, record.sample.clock_s) and not Codec.read_vector3(previous["to"]).is_equal_approx(Codec.read_vector3(record.sample.position))):
			return "Deferred active path must precede or match the saved shared-player sample"
	var expected_active: float = float(exchange.lock_from_s) + float(resolved.lock_s) if adapter.locked else float(exchange.start_s) + float(resolved.windup_s)
	if float(exchange.start_s) > float(paired.clock_s) or float(exchange.lock_from_s) < float(exchange.start_s) + float(resolved.windup_s) - float(resolved.lock_s) - EPSILON or not _near(exchange.active_from_s, expected_active) or not _near(exchange.active_until_s, expected_active + float(resolved.active_s)) or not _near(exchange.recovery_until_s, expected_active + float(resolved.active_s) + float(resolved.recovery_s)) or not _near(exchange.cooldown_until_s, expected_active + float(resolved.attack_interval_s)):
		return "Scout deadlines must preserve full returned lock/active/recovery/cooldown durations"
	if not adapter.locked and not _near(exchange.lock_from_s, float(exchange.start_s) + float(resolved.windup_s) - float(resolved.lock_s)):
		return "Unarmed warning cannot retime its tentative lock"
	if adapter.locked and float(exchange.lock_from_s) >= float(exchange.start_s) + float(resolved.windup_s) - EPSILON:
		return "Tracking cannot manufacture a lock after its tentative activation deadline"
	if record.hit_consumed and (not adapter.locked or float(record.sample.clock_s) < expected_active - EPSILON):
		return "Hero opportunity cannot be consumed before an armed active interval"
	if record.status == "running":
		var phase: String = "warning" if not adapter.locked else ("lock" if float(paired.clock_s) < expected_active else ("active" if float(paired.clock_s) <= float(exchange.active_until_s) else "recovery"))
		if paired.encounter_id.is_empty() or owned.is_empty() or record.phase != phase or actor_state.phase != phase or not record.last_cancel_reason.is_empty() or not _near(actor_state.phase_progress, _progress(_decode_record(record, bindings), float(paired.clock_s))) or not _same_copied_scalar(record.sample.clock_s, paired.clock_s):
			return "Running Scout requires matching scheduler/actor phase, progress and sample clock"
		for key: String in EXCHANGE_KEYS:
			if not _same_copied_exchange_value(key, exchange[key], owned[key]):
				return "Scout driver and shared reservation disagree"
		if actual and not Codec.read_vector3(record.sample.position).is_equal_approx(_hero.global_position):
			return "Apply the saved shared player before committing its actual damage sample"
		if not actual and bindings.get("hero_positions", {}).has("hero") and not Codec.read_vector3(record.sample.position).is_equal_approx(bindings.hero_positions.hero):
			return "Running Scout sample must match the separately validated saved shared player"
	else:
		if not owned.is_empty() or record.phase != ("defeated" if record.status == "defeated" else "clear"):
			return "Inactive Scout cannot hide a retained danger reservation"
		if record.status == "cancelled" and record.last_cancel_reason.is_empty():
			return "Cancelled Scout requires its visible cancellation reason"
		if record.status == "complete" and float(paired.clock_s) <= float(exchange.recovery_until_s):
			return "Completed Scout cannot discard remaining recovery"
	if record.status == "defeated":
		if not cooldown.is_empty():
			return "Defeated Scout must release source cooldown before progression"
	elif paired.encounter_id == configuration.encounter_id and float(exchange.cooldown_until_s) > float(paired.clock_s) and (cooldown.is_empty() or not _same_copied_scalar(cooldown.ready_s, exchange.cooldown_until_s)):
		return "Cancellation/restoration cannot refresh the original Scout cooldown"
	return ""


func _witness_supported(position: Vector3, context: Dictionary) -> bool:
	var feet_y: float = position.y + CinderThreatScheduler.CAPSULE_CENTER_Y - CinderThreatScheduler.CAPSULE_HEIGHT * 0.5
	for region: Dictionary in context.floor_regions:
		var support: CollisionShape3D = region.collision
		var top: float = support.global_position.y + (support.shape as BoxShape3D).size.y * 0.5
		if (region.safe_rect as Rect2).has_point(Vector2(position.x, position.z)) and absf(feet_y - top) <= CinderThreatScheduler.FEET_TOLERANCE:
			return true
	return false


func _saved_context_error(value: Dictionary, bindings: Dictionary) -> String:
	if not Codec.keys_error(value, ["recognition_s", "attack_input_margin_s", "escape_directions", "return_directions", "floor_ids"]).is_empty() or not Codec.is_number(value.recognition_s) or float(value.recognition_s) <= 0.0 or not Codec.is_number(value.attack_input_margin_s) or float(value.attack_input_margin_s) < 0.0 or not value.floor_ids is Array or value.floor_ids.is_empty():
		return "Saved authored response context is incomplete"
	for key: String in ["escape_directions", "return_directions"]:
		if not value[key] is Array or value[key].size() > 16 or (key == "escape_directions" and value[key].is_empty()):
			return "Saved response candidates exceed the bounded shared contract"
		for direction: Variant in value[key]:
			if not Codec.is_vector3(direction) or Codec.read_vector3(direction).y != 0.0 or absf(Codec.read_vector3(direction).length_squared() - 1.0) > EPSILON:
				return "Saved response candidates must remain finite normalized planar swipes"
	var seen: Dictionary = {}
	for id: Variant in value.floor_ids:
		if not id is String or not bindings.get("floors", {}).has(id) or seen.has(id):
			return "Saved response floor IDs must name unique actual authored floors"
		seen[id] = true
	return "" if _floors_allowed(_decode_context(value, bindings).floor_regions) else "Saved response cannot introduce a different floor guard"
