class_name CinderReplayPlayback
extends Node3D
## Physical consumer of one exclusive replay lease. Only its renderer moves.
## Captured slots must be retired by the parent's atomic custody transfer.

signal state_changed(playback_state: Dictionary)
signal event_dispatched(event: Dictionary, opportunity: Dictionary)
signal playback_failed(reason: String)

const Sequence = preload("res://scripts/combat/replay_sequence.gd")
const Cursor = preload("res://scripts/combat/replay_cursor.gd")
const Witness = preload("res://scripts/combat/replay_witness.gd")
const Player = preload("res://scripts/player.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Cue = preload("res://scripts/cues/threat_cue.gd")
const CueMesh = preload("res://scripts/cues/cue_mesh.gd")
const Footprint = preload("res://scripts/attack_footprint.gd")
const Sprite = preload("res://scripts/pixel_sprite.gd")
const API_REVISION: String = "replay-playback-1"
const TIME_EPSILON_S: float = Sequence.TIME_EPSILON_S
const MAX_DISPATCH_DELAY_S: float = Witness.MAX_DISPATCH_DELAY_S
const EXCHANGE_KEYS: Array[String] = ["id", "source_position", "opening_position", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision", "adapter"]
const SNAPSHOT_KEYS: Array[String] = ["api_revision", "schema_version", "playback_id", "presentation_id", "sequence", "source_epoch", "generation", "source_id", "hero_id", "reservation_id", "exchange", "status", "reason", "cancelled_at_s", "cancellation", "clock_s", "cursor", "opportunities"]
const OPPORTUNITY_KEYS: Array[String] = ["event_id", "hero_id", "scheduled_at_s", "dispatch_clock_s", "contact", "damage_attempted"]

var last_error: String = ""
var last_snapshot_error: String = ""
var _configuration: Dictionary = {}
var _plan: Dictionary = {}
var _scheduler: Node3D
var _world_root: Node3D
var _hero: CinderPlayer
var _hero_id: String = ""
var _reservation_id: String = ""
var _exchange: Dictionary = {}
var _cursor = Cursor.new()
var _opportunities: Array[Dictionary] = []
var _status: String = "idle"
var _reason: String = ""
var _cancelled_at: Variant = null
var _transaction_depth: int = 0
var _snapshot_busy: bool = false
var _apparition_root: Node3D
var _apparition: LabSprite
var _route_mesh: MeshInstance3D
var _failure_marker: MeshInstance3D
var _cues: Array[Node3D] = []
var _cue_phases: Array[String] = []
var _pending_delivery: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 110
	_apparition_root = Node3D.new()
	_apparition_root.name = "NonblockingApparition"
	_apparition_root.top_level = true
	add_child(_apparition_root)
	_apparition = Sprite.new()
	_apparition.name = "ActorSprite"
	_apparition_root.add_child(_apparition)
	_apparition.modulate = Color(0.83, 0.93, 1.0, 0.70)
	_apparition.visible = false
	_route_mesh = _mesh_node("ExactHarmlessRoutes", Color(0.70, 0.83, 0.90, 0.65))
	_failure_marker = _mesh_node("VisibleReplayFailure", Color(1.0, 0.30, 0.22, 1.0))
	_failure_marker.visible = false
	if not _configuration.is_empty():
		_build_preview()


func configure(playback_id: String, sequence_snapshot: Dictionary, source_epoch: String, generation: int, presentation_id: String = "act3_traveller") -> bool:
	if not _configuration.is_empty() or _transaction_depth > 0 or not _stable_id(playback_id) or not Sprite.PRESENTATION_IDS.has(presentation_id):
		return _reject("Configure a fresh playback with stable identity and supported cosmetic presentation")
	var reader = Sequence.new()
	if not reader.restore_state(sequence_snapshot, source_epoch, generation):
		return _reject("Invalid frozen sequence: " + reader.last_snapshot_error)
	_configuration = {"playback_id": playback_id, "sequence": reader.snapshot_state(), "source_epoch": source_epoch, "generation": generation, "presentation_id": presentation_id}
	_plan = reader.state()
	if is_node_ready():
		_build_preview()
	last_error = ""
	return true


func bind(scheduler: Node3D, reservation_id: String, heroes: Dictionary) -> bool:
	if _status != "idle" or _transaction_depth > 0 or _snapshot_busy or not _ready_boundary() or get_tree().paused:
		return _reject("Bind one fresh ready unpaused playback outside callbacks")
	var error: String = _bindings_error(scheduler, heroes)
	if not error.is_empty():
		return _reject(error)
	var lease: Dictionary = scheduler.replay_reservation_state(reservation_id)
	error = _lease_error(lease, heroes.values()[0], scheduler)
	if not error.is_empty() or lease.get("adapter", {}).get("locked", true):
		return _reject(error if not error.is_empty() else "Bind the unarmed preview before actual lock")
	var admitted_world: Node3D = scheduler.replay_world_root(reservation_id)
	if not is_instance_valid(admitted_world):
		return _reject("Exact admitted collision root required")
	var candidate = Cursor.new()
	if not candidate.configure(_configuration.sequence, _configuration.source_epoch, int(_configuration.generation), float(lease.start_s)):
		return _reject(candidate.last_error)
	_scheduler = scheduler
	_world_root = admitted_world
	_hero_id = String(heroes.keys()[0])
	_hero = heroes.values()[0]
	_reservation_id = reservation_id
	_exchange = _exchange_data(lease)
	_cursor = candidate
	_status = "running"
	_scheduler.reservation_invalidated.connect(_on_invalidated)
	_transaction_depth += 1
	_pending_delivery = _new_pending()
	_drain_pending()
	_transaction_depth -= 1
	last_error = "" if _status == "running" else _reason
	return _status == "running"


func advance() -> Dictionary:
	if _transaction_depth > 0 or _snapshot_busy:
		return {"accepted": false, "reason": "Playback cannot advance recursively inside delivery or presentation callbacks", "events": []}
	if not _ready_boundary() or not is_instance_valid(_scheduler) or get_tree().paused or _status not in ["running", "complete"]:
		return {"accepted": false, "reason": "Running live unpaused playback required", "events": []}
	var clock_s: float = _scheduler.get_clock()
	var previous: Dictionary = _cursor.snapshot_state()
	if not Codec.in_range(clock_s, 0.0, Witness.MAX_CLOCK_S) or clock_s < float(previous.last_advanced_clock_s):
		return _fail("invalid_simulation_clock")
	if _status == "complete":
		# A retained terminal owner still shares the aggregate simulation clock,
		# without delivering, proving, presenting or emitting past events again.
		_cursor.advance(clock_s)
		return {"accepted": true, "events": [], "phase": "complete"}
	if not is_instance_valid(_world_root) or not _world_root.is_inside_tree() or not _same_transport(_scheduler.collision_fingerprint(_world_root), _exchange.adapter.capture_collision_fingerprint):
		return _fail("replay_collision_world_changed")
	# Normal expiry is harmless only after every required event was consumed.
	if clock_s >= float(_exchange.recovery_until_s) and int(previous.next_event_index) == _events().size() and _pending_delivery.is_empty():
		if not is_instance_valid(_world_root) or not _world_root.is_inside_tree() or global_position.distance_to(_exchange.source_position) > _scheduler.EPSILON or not _same_transport(_scheduler.collision_fingerprint(_world_root), _exchange.adapter.capture_collision_fingerprint):
			return _fail("completed_replay_world_or_source_changed")
		_cursor.advance(clock_s)
		_status = "complete"
		_transaction_depth += 1
		_refresh_visuals()
		state_changed.emit(state())
		_transaction_depth -= 1
		return {"accepted": true, "events": [], "phase": "complete"}
	var guard: String = _scheduler.replay_reservation_error(_reservation_id)
	if not guard.is_empty():
		return _fail("invalid_replay_lease: " + guard)
	var lease: Dictionary = _scheduler.replay_reservation_state(_reservation_id)
	var error: String = _lease_error(lease, _hero, _scheduler)
	if not error.is_empty():
		return _fail(error)
	# An accepted contact survives a real resume tick even near admission grace.
	# Its callback drain is bounded separately from ORIGINAL dispatch, with no
	# new contact sample or extension of original scheduled admission.
	for entry: Dictionary in _pending_delivery.get("events", []):
		if clock_s - float(_opportunities[int(entry.event_index)].dispatch_clock_s) > MAX_DISPATCH_DELAY_S + TIME_EPSILON_S:
			return _fail("missed_pending_dispatch_grace")
	# Never re-present a missing/hidden required cue to regain damage authority.
	if not _delivery_guard():
		return {"accepted": false, "reason": _reason, "events": []}
	var candidate = Cursor.new()
	if not candidate.restore_state(previous, _configuration.sequence, _configuration.source_epoch, int(_configuration.generation), float(previous.last_advanced_clock_s)):
		return _fail("invalid_internal_cursor")
	if lease.adapter.locked:
		if not previous.armed:
			if not candidate.arm(float(lease.adapter.timeline_origin_s), float(lease.lock_from_s)):
				return _fail("invalid_actual_lock: " + candidate.last_error)
		elif not _same_exchange(_exchange, _exchange_data(lease)):
			return _fail("armed_replay_exchange_changed")
	elif previous.armed or not _same_exchange(_exchange, _exchange_data(lease)):
		return _fail("unarmed_replay_exchange_changed")
	var staged: Dictionary = candidate.advance(clock_s)
	if not staged.accepted:
		return _fail(candidate.last_error)
	# Check the ENTIRE batch before committing even its first prefix entry.
	for event: Dictionary in staged.events:
		if clock_s - float(event.scheduled_at_s) > MAX_DISPATCH_DELAY_S + TIME_EPSILON_S:
			return _fail("missed_dispatch_grace")
	if not is_instance_valid(_hero) or _hero.is_queued_for_deletion() or not _hero.is_inside_tree() or _hero.get_world_3d() != get_world_3d() or _scheduler.replay_target(_reservation_id) != _hero:
		return _fail("proved_player_binding_changed")
	var due_opportunities: Array[Dictionary] = []
	for event: Dictionary in staged.events:
		var contact: bool = not _hero.dead and _hero.hp > 0.0 and _contact(event.record, _hero)
		due_opportunities.append({"event_id": event.event_id, "hero_id": _hero_id, "scheduled_at_s": event.scheduled_at_s, "dispatch_clock_s": clock_s, "contact": contact, "damage_attempted": false})
	# Commit the complete canonical receipt prefix before ALL callbacks. A held
	# callback preserves its suffix; contact/time are never sampled again.
	_cursor = candidate
	_exchange = _exchange_data(lease)
	if _pending_delivery.is_empty():
		_pending_delivery = _new_pending()
	for opportunity: Dictionary in due_opportunities:
		_pending_delivery.events.append({"event_index": _opportunities.size(), "stage": "present"})
		_opportunities.append(opportunity)
	if not due_opportunities.is_empty():
		_pending_delivery.visual_next_cue = 0
	_pending_delivery.visuals_pending = true
	_pending_delivery.state_pending = true
	_transaction_depth += 1
	_drain_pending()
	_transaction_depth -= 1
	if _status == "cancelled":
		_refresh_visuals(true)
		return {"accepted": false, "reason": _reason, "events": staged.events.duplicate(true), "phase": "cancelled", "prefix_consumed": true}
	last_error = ""
	var answer: Dictionary = {"accepted": true, "events": staged.events.duplicate(true), "phase": staged.phase}
	if not _pending_delivery.is_empty():
		answer["delivery_pending"] = true
	return answer


func _new_pending() -> Dictionary:
	return {"events": [], "visual_next_cue": 0, "visuals_pending": true, "state_pending": true, "cue_phases": _cue_phases.duplicate()}


func _drain_pending() -> void:
	while not _pending_delivery.is_empty() and not _pending_delivery.events.is_empty() and _status == "running":
		if not _delivery_guard() or get_tree().paused:
			return
		var entry: Dictionary = _pending_delivery.events[0]
		var index: int = int(entry.event_index)
		var event: Dictionary = _delivery_event(index)
		if entry.stage == "present":
			entry.stage = "damage" # Commit BEFORE active cue observers.
			_present_event(event)
			if not _delivery_guard() or get_tree().paused:
				return
		if entry.stage == "damage":
			entry.stage = "notify" # Actual attempt is committed BEFORE hurt/death.
			if _opportunities[index].contact:
				_opportunities[index].damage_attempted = true
				_hero.take_damage(float(event.record.damage), Vector3.ZERO)
			if not _delivery_guard() or get_tree().paused:
				return
		if entry.stage == "notify":
			_pending_delivery.events.pop_front() # Emit exactly once, including pause.
			event_dispatched.emit(event.duplicate(true), _opportunities[index].duplicate(true))
			if not _delivery_guard() or get_tree().paused:
				return
	if _status != "running" or _pending_delivery.is_empty():
		return
	if _pending_delivery.visuals_pending and not _refresh_visuals():
		return
	if _pending_delivery.state_pending:
		_pending_delivery.state_pending = false
		_pending_delivery = {} # All callbacks/presentation now have been spent.
		state_changed.emit(state())
		_delivery_guard()


func _delivery_event(index: int) -> Dictionary:
	var event: Dictionary = _events()[index].duplicate(true)
	for slot: Dictionary in _plan.timeline.slots:
		for candidate: Dictionary in slot.events:
			if candidate.event_id == event.event_id:
				event["slot_id"] = slot.slot_id
				event["generation"] = slot.generation
	var receipt: Dictionary = _opportunities[index]
	event["scheduled_at_s"] = receipt.scheduled_at_s
	event["dispatch_clock_s"] = receipt.dispatch_clock_s
	event["commitment_until_s"] = float(_exchange.adapter.timeline_origin_s) + float(event.commitment_until_s)
	event["ready_s"] = float(_exchange.adapter.timeline_origin_s) + float(event.ready_s)
	return event


func _delivery_guard() -> bool:
	if _status != "running":
		return false
	if not _ready_boundary() or not is_instance_valid(_scheduler) or _scheduler.is_queued_for_deletion():
		_fail("replay_owner_or_scheduler_lost")
		return false
	var error: String = _scheduler.replay_reservation_error(_reservation_id)
	if error.is_empty() and (not is_instance_valid(_hero) or _hero.is_queued_for_deletion() or not _hero.is_inside_tree() or _hero.get_world_3d() != get_world_3d() or _scheduler.replay_target(_reservation_id) != _hero):
		error = "proved_player_binding_changed"
	if error.is_empty() and (_hero.dead or _hero.hp <= 0.0):
		error = "proved_player_dead"
	if error.is_empty():
		error = _required_cue_error()
	if not error.is_empty():
		_fail(error)
		return false
	return true


func _required_cue_error() -> String:
	if _cues.size() != _events().size() or _cue_phases.size() != _cues.size():
		return "required_replay_cue_count_changed"
	for index: int in range(_cues.size()):
		var cue: Node3D = _cues[index]
		if not is_instance_valid(cue) or cue.is_queued_for_deletion() or not cue.is_inside_tree() or cue.get_world_3d() != get_world_3d() or not is_ancestor_of(cue):
			return "required_replay_cue_lost"
		var phase: String = _cue_phases[index]
		var observed: Dictionary = cue.state()
		if observed.phase != phase:
			return "required_replay_cue_cleared_or_changed"
		if not cue.is_visible_in_tree():
			return "required_replay_cue_hidden"
		if not _cue_children_error(cue).is_empty():
			return "required_replay_source_or_footprint_lost"
		if phase == "clear":
			continue
		var record: Dictionary = _events()[index].record
		var geometry: Dictionary = Geometry.cone(record.world_origin, record.direction, float(record.geometry.reach), float(record.geometry.cone_min_dot), float(record.geometry.origin_disk_radius))
		if observed.geometry != CueMesh.canonical_geometry(geometry) or observed.source_position != record.world_origin or not cue.is_visible_in_tree():
			return "required_replay_cue_geometry_or_visibility_changed"
		for name: String in ["RequiredSourceMarker", "RequiredFootprintOutline", "RequiredFootprintFill"]:
			var mesh: MeshInstance3D = cue.get_node_or_null(name) as MeshInstance3D
			var required: bool = name == "RequiredSourceMarker" or (name == "RequiredFootprintOutline" and phase != "recovery") or (name == "RequiredFootprintFill" and phase == "active")
			if not is_instance_valid(mesh) or mesh.is_queued_for_deletion() or (required and (not mesh.is_visible_in_tree() or mesh.mesh == null)):
				return "required_replay_source_or_footprint_lost"
	return ""


func _cue_children_error(cue: Node3D) -> String:
	for name: String in ["RequiredSourceMarker", "RequiredFootprintOutline", "RequiredFootprintFill"]:
		var mesh: MeshInstance3D = cue.get_node_or_null(name) as MeshInstance3D
		if not is_instance_valid(mesh) or mesh.is_queued_for_deletion():
			return "required_replay_renderer_child_lost"
	return ""


func cancel(reason: String = "owner_cancelled") -> bool:
	if _status != "running" or _transaction_depth > 0 or _snapshot_busy or reason.is_empty():
		return _reject("Cancel an active owner outside callbacks with an explicit reason")
	_fail(reason)
	return true


func state() -> Dictionary:
	if _configuration.is_empty():
		return {}
	var result: Dictionary = {"api_revision": API_REVISION, "playback_id": _configuration.playback_id, "source_epoch": _configuration.source_epoch, "generation": _configuration.generation, "presentation_id": _configuration.presentation_id, "status": _status, "reason": _reason, "reservation_id": _reservation_id, "cursor": _cursor.state(), "visual_pose": _presentation_pose(), "opportunities": _opportunities.duplicate(true), "movement_damage": false, "blocking": false}
	if not _pending_delivery.is_empty():
		result["pending_delivery"] = _pending_delivery.duplicate(true)
	return result


func preview_state() -> Dictionary:
	if _plan.is_empty():
		return {}
	return {"api_revision": API_REVISION, "sequence_id": _plan.sequence_id, "source_epoch": _plan.source_epoch, "generation": _plan.generation, "presentation_id": _configuration.presentation_id, "slots": _plan.timeline.slots.duplicate(true), "static_loadouts": _loadouts(), "authored": _plan.authored.duplicate(true), "tether_from_s": _plan.timeline.tether_from_s, "tether_until_s": _plan.timeline.tether_until_s, "damage_timing": "instant_at_execution", "movement_damage": false, "route_translation": Vector3.ZERO, "los_clipped_preview": false, "portrait_visibility_proved": false}


func get_apparition() -> LabSprite:
	return _apparition


func get_apparition_root() -> Node3D:
	return _apparition_root


func get_cues() -> Array[Node3D]:
	return _cues.duplicate()


func snapshot_state(scheduler_snapshot: Dictionary, bindings: Dictionary) -> Dictionary:
	last_snapshot_error = _snapshot_boundary_error()
	if not last_snapshot_error.is_empty() or not is_instance_valid(_scheduler):
		return {}
	var source_id: String = _source_id(bindings)
	var tombstone: Dictionary = {}
	if _status == "cancelled" and _scheduler.has_method("replay_cancellation_state"):
		tombstone = _scheduler.replay_cancellation_state(_reservation_id, bindings)
	var candidate: Dictionary = {"api_revision": API_REVISION, "schema_version": 1, "playback_id": _configuration.playback_id, "presentation_id": _configuration.presentation_id, "sequence": _configuration.sequence.duplicate(true), "source_epoch": _configuration.source_epoch, "generation": _configuration.generation, "source_id": source_id, "hero_id": _hero_id, "reservation_id": _reservation_id, "exchange": _encode_exchange(_exchange), "status": _status, "reason": _reason, "cancelled_at_s": _cancelled_at, "cancellation": tombstone, "clock_s": _scheduler.get_clock(), "cursor": _cursor.snapshot_state(), "opportunities": _opportunities.duplicate(true)}
	if not _pending_delivery.is_empty():
		candidate["schema_version"] = 2
		candidate["pending_delivery"] = _pending_delivery.duplicate(true)
	last_snapshot_error = snapshot_error(candidate, _scheduler, scheduler_snapshot, bindings, {_hero_id: _hero})
	return candidate.duplicate(true) if last_snapshot_error.is_empty() else {}


func snapshot_error(snapshot: Dictionary, scheduler: Node3D, scheduler_snapshot: Dictionary, bindings: Dictionary, heroes: Dictionary) -> String:
	var error: String = _snapshot_boundary_error()
	if not error.is_empty():
		return error
	error = Codec.value_error(snapshot)
	if error.is_empty():
		var keys: Array[String] = SNAPSHOT_KEYS.duplicate()
		if snapshot.get("schema_version") == 2:
			keys.append("pending_delivery")
		error = Codec.keys_error(snapshot, keys)
	if not error.is_empty():
		return error
	error = _bindings_error(scheduler, heroes)
	if not error.is_empty():
		return error
	if snapshot.get("status") == "running":
		for cue: Node3D in _cues:
			if not is_instance_valid(cue) or cue.is_queued_for_deletion() or not _cue_children_error(cue).is_empty():
				return "Running restore requires intact required cue renderer nodes"
		if _status == "running" and not _required_cue_error().is_empty():
			return "Running capture/restore cannot repair externally lost damaging cue authority"
	if snapshot.api_revision != API_REVISION or not Codec.is_integer(snapshot.schema_version, 1, 2) or snapshot.playback_id != _configuration.playback_id or snapshot.presentation_id != _configuration.presentation_id or snapshot.source_epoch != _configuration.source_epoch or not Codec.is_integer(snapshot.generation, int(_configuration.generation), int(_configuration.generation)) or not _same_transport(snapshot.sequence, _configuration.sequence) or not _stable_id(snapshot.source_id) or snapshot.source_id != _source_id(bindings) or snapshot.hero_id != heroes.keys()[0] or not _stable_id(snapshot.reservation_id) or not snapshot.exchange is Dictionary or not snapshot.cursor is Dictionary or not snapshot.opportunities is Array or snapshot.status not in ["running", "cancelled", "complete"] or not snapshot.reason is String or not snapshot.cancellation is Dictionary:
		return "Playback identity/configuration/one-player custody schema differs"
	error = scheduler.snapshot_error(scheduler_snapshot, bindings)
	if not error.is_empty():
		return "Invalid paired scheduler state: " + error
	if not Codec.in_range(snapshot.clock_s, 0.0, Witness.MAX_CLOCK_S) or not _same_transport(snapshot.clock_s, scheduler_snapshot.clock_s):
		return "Playback aggregate clock must equal the saved scheduler clock"
	var exchange: Dictionary = snapshot.exchange
	error = Codec.keys_error(exchange, EXCHANGE_KEYS)
	if not error.is_empty() or exchange.id != snapshot.reservation_id or not Codec.is_vector3(exchange.source_position) or not Codec.is_vector3(exchange.opening_position) or not exchange.adapter is Dictionary or exchange.adapter.get("kind") != "replay" or not _same_transport(exchange.adapter.get("sequence"), _configuration.sequence) or exchange.adapter.get("source_epoch") != _configuration.source_epoch or exchange.adapter.get("generation") != _configuration.generation or exchange.adapter.get("max_dispatch_delay_s") != MAX_DISPATCH_DELAY_S or not exchange.adapter.get("locked") is bool:
		return "Saved exact replay exchange cannot be replaced by ordinary geometry"
	if not Codec.keys_error(exchange.adapter, ["kind", "locked", "sequence", "source_epoch", "generation", "capture_collision_fingerprint", "timeline_origin_s", "max_dispatch_delay_s"]).is_empty() or not Codec.in_range(exchange.adapter.get("timeline_origin_s"), 0.0, Witness.MAX_CLOCK_S) or exchange.profile_id != scheduler_snapshot.profile.get("id") or not Codec.is_integer(exchange.world_revision, 1, int(scheduler_snapshot.world_revision)):
		return "Exact replay adapter clocks/profile/world revision required"
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not Codec.in_range(exchange.get(key), 0.0, Witness.MAX_CLOCK_S):
			return "Finite supported replay deadlines required"
	if not (float(exchange.start_s) < float(exchange.lock_from_s) and float(exchange.lock_from_s) < float(exchange.active_from_s) and float(exchange.active_from_s) < float(exchange.active_until_s) and float(exchange.active_until_s) < float(exchange.recovery_until_s)):
		return "Saved replay deadlines lost phase order"
	if not exchange.adapter.get("capture_collision_fingerprint") is Dictionary or (snapshot.status != "cancelled" and not _same_transport(exchange.adapter.capture_collision_fingerprint, scheduler.collision_fingerprint(bindings.get("world_root")))):
		return "Saved replay collision world no longer matches its capture"
	var paired: Dictionary = {}
	for record: Dictionary in scheduler_snapshot.reservations:
		if record.id == snapshot.reservation_id:
			paired = record
	if not Codec.is_number(snapshot.cursor.get("last_advanced_clock_s")):
		return "Finite saved cursor clock required"
	var cursor_clock: float = float(snapshot.cursor.last_advanced_clock_s)
	var reader = Cursor.new()
	error = reader.snapshot_error(snapshot.cursor, _configuration.sequence, _configuration.source_epoch, int(_configuration.generation), cursor_clock)
	if not error.is_empty():
		return "Invalid exact cursor: " + error
	if not _same_transport(snapshot.cursor.configured_at_s, exchange.start_s) or snapshot.cursor.armed != exchange.adapter.locked:
		return "Cursor must bind the real preview start and actual arming state"
	if snapshot.cursor.armed and (not _same_transport(snapshot.cursor.armed_at_s, exchange.lock_from_s) or not _same_transport(snapshot.cursor.timeline_origin_s, exchange.adapter.timeline_origin_s)):
		return "Cursor cannot rearm/retime the actual scheduler lock"
	if snapshot.status == "running":
		if paired.is_empty() or paired.source_id != snapshot.source_id or paired.get("response_actor_id") != snapshot.hero_id or bindings.get("actors", {}).get(snapshot.hero_id) != heroes.values()[0] or not _same_exchange(exchange, _exchange_data(paired)) or not _same_transport(cursor_clock, snapshot.clock_s) or not snapshot.reason.is_empty() or snapshot.cancelled_at_s != null or not snapshot.cancellation.is_empty():
			return "Running playback requires its exact paired reservation and complete current cursor"
	elif snapshot.status == "complete":
		if not paired.is_empty() or not snapshot.cursor.armed or int(snapshot.cursor.next_event_index) != _events().size() or snapshot.cursor.phase != "complete" or not _same_transport(cursor_clock, snapshot.clock_s) or float(snapshot.clock_s) < float(exchange.recovery_until_s) - TIME_EPSILON_S or not snapshot.reason.is_empty() or snapshot.cancelled_at_s != null or not snapshot.cancellation.is_empty():
			return "Terminal completion requires the entire prefix and exact finished aggregate clock"
	else:
		if not paired.is_empty() or not Codec.is_number(snapshot.cancelled_at_s) or not _same_transport(snapshot.cancelled_at_s, snapshot.clock_s) or cursor_clock > float(snapshot.cancelled_at_s) + TIME_EPSILON_S or snapshot.reason.is_empty():
			return "Canceled owner must retain a frozen prefix at its exact cancellation checkpoint"
		error = _cancellation_error(snapshot, scheduler_snapshot)
		if not error.is_empty():
			return error
	if snapshot.opportunities.size() != snapshot.cursor.executed_events.size():
		return "Every consumed event must retain its once-only target opportunity"
	for index: int in range(snapshot.opportunities.size()):
		var value: Variant = snapshot.opportunities[index]
		var prefix: Dictionary = snapshot.cursor.executed_events[index]
		if not value is Dictionary or not Codec.keys_error(value, OPPORTUNITY_KEYS).is_empty() or value.event_id != prefix.event_id or value.hero_id != snapshot.hero_id or not Codec.is_number(value.scheduled_at_s) or not Codec.is_number(value.dispatch_clock_s) or not _same_transport(value.scheduled_at_s, prefix.scheduled_at_s) or not _same_transport(value.dispatch_clock_s, prefix.dispatch_clock_s) or float(value.dispatch_clock_s) - float(value.scheduled_at_s) > MAX_DISPATCH_DELAY_S + TIME_EPSILON_S or not value.contact is bool or not value.damage_attempted is bool or (value.damage_attempted and not value.contact):
			return "Opportunity prefix must match every canonical consumed event, target and bounded dispatch"
	error = _pending_error(snapshot)
	if not error.is_empty():
		return error
	if _status != "idle":
		if _reservation_id != snapshot.reservation_id or _hero_id != snapshot.hero_id or _scheduler != scheduler or _hero != heroes.values()[0] or snapshot.opportunities.size() < _opportunities.size() or (_status in ["cancelled", "complete"] and snapshot.status != _status):
			return "Existing owner cannot rebind or revive once-only state"
		for index: int in range(_opportunities.size()):
			if not _same_transport(snapshot.opportunities[index], _opportunities[index]) and not (_opportunities[index].contact and not _opportunities[index].damage_attempted and snapshot.opportunities[index].damage_attempted and _same_transport(_receipt_without_attempt(snapshot.opportunities[index]), _receipt_without_attempt(_opportunities[index]))):
				return "Past target opportunity cannot be rewritten"
		var existing_reader = Cursor.new()
		var current: Dictionary = _cursor.snapshot_state()
		existing_reader.restore_state(current, _configuration.sequence, _configuration.source_epoch, int(_configuration.generation), float(current.last_advanced_clock_s))
		if not existing_reader.restore_state(snapshot.cursor, _configuration.sequence, _configuration.source_epoch, int(_configuration.generation), cursor_clock):
			return existing_reader.last_snapshot_error
	return ""


func restore_state(snapshot: Dictionary, scheduler: Node3D, scheduler_snapshot: Dictionary, bindings: Dictionary, heroes: Dictionary) -> bool:
	last_snapshot_error = snapshot_error(snapshot, scheduler, scheduler_snapshot, bindings, heroes)
	if not last_snapshot_error.is_empty():
		return false
	# Staged validation never substitutes for ACTUAL actor->scheduler commit.
	var actual: Dictionary = scheduler.snapshot_state(bindings)
	if actual.is_empty() or not _same_transport(actual, scheduler_snapshot) or not _same_transport(scheduler.get_clock(), snapshot.clock_s) or global_position.distance_to(Codec.read_vector3(snapshot.exchange.source_position)) > scheduler.EPSILON:
		last_snapshot_error = "Apply the validated real source/actor and scheduler before playback commit"
		return false
	if snapshot.status == "running" and (scheduler.replay_reservation_state(snapshot.reservation_id).is_empty() or scheduler.replay_target(snapshot.reservation_id) != heroes.values()[0]):
		last_snapshot_error = "Actual restored lease must name this source and its bound proved player"
		return false
	var candidate = Cursor.new()
	candidate.restore_state(snapshot.cursor, _configuration.sequence, _configuration.source_epoch, int(_configuration.generation), float(snapshot.cursor.last_advanced_clock_s))
	_snapshot_busy = true
	if is_instance_valid(_scheduler) and _scheduler.reservation_invalidated.is_connected(_on_invalidated):
		_scheduler.reservation_invalidated.disconnect(_on_invalidated)
	_scheduler = scheduler
	_world_root = bindings.world_root
	_hero_id = snapshot.hero_id
	_hero = heroes.values()[0]
	_reservation_id = snapshot.reservation_id
	_exchange = snapshot.exchange.duplicate(true)
	_exchange.source_position = Codec.read_vector3(_exchange.source_position)
	_exchange.opening_position = Codec.read_vector3(_exchange.opening_position)
	_cursor = candidate
	_opportunities.clear()
	for value: Dictionary in snapshot.opportunities:
		_opportunities.append(value.duplicate(true))
	_pending_delivery = snapshot.get("pending_delivery", {}).duplicate(true)
	_status = snapshot.status
	_reason = snapshot.reason
	_cancelled_at = snapshot.cancelled_at_s
	_scheduler.reservation_invalidated.connect(_on_invalidated)
	_refresh_visuals(true)
	_snapshot_busy = false
	last_error = ""
	return true


func _cancellation_error(snapshot: Dictionary, scheduler_snapshot: Dictionary) -> String:
	# The scheduler owner supplies a replay-only persisted tombstone. Cooldown
	# alone cannot authenticate which required exchange was canceled.
	var matched: bool = false
	for record: Dictionary in scheduler_snapshot.get("replay_cancellations", []):
		if _same_transport(record, snapshot.cancellation):
			matched = true
	if not matched or snapshot.cancellation.is_empty():
		return "Canceled restore requires its exact retained replay cancellation identity; expired/missing provenance is unsupported"
	var tombstone: Dictionary = snapshot.cancellation
	var exchange: Dictionary = snapshot.exchange
	if tombstone.get("id") != snapshot.reservation_id or tombstone.get("source_id") != snapshot.source_id or tombstone.get("response_actor_id") != snapshot.hero_id or tombstone.get("source_epoch") != snapshot.source_epoch or tombstone.get("generation") != snapshot.generation or tombstone.get("sequence_id") != _plan.sequence_id or not _same_transport(tombstone.get("sequence"), snapshot.sequence) or not _same_transport(tombstone.get("capture_collision_fingerprint"), exchange.adapter.capture_collision_fingerprint) or tombstone.get("locked") != exchange.adapter.locked or tombstone.get("max_dispatch_delay_s") != MAX_DISPATCH_DELAY_S or tombstone.get("reason") != snapshot.reason or not Codec.is_number(tombstone.get("cancelled_at_s")) or not _same_transport(tombstone.cancelled_at_s, snapshot.cancelled_at_s) or not Codec.is_number(tombstone.get("timeline_origin_s")) or not _same_transport(tombstone.timeline_origin_s, exchange.adapter.timeline_origin_s):
		return "Cancellation must retain this exact exchange, proved player, reason and actual clock"
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision"]:
		if not _same_transport(tombstone.get(key), exchange.get(key)):
			return "Cancellation changed retained exchange deadline/profile identity"
	return ""


func _snapshot_boundary_error() -> String:
	if not _ready_boundary() or not get_tree().paused:
		return "Playback snapshots require a configured ready paused aggregate boundary"
	if _transaction_depth > 0 or _snapshot_busy:
		return "Playback snapshots require the deferred barrier outside damage/cue/state callbacks"
	return ""


func _receipt_without_attempt(value: Dictionary) -> Dictionary:
	var receipt: Dictionary = value.duplicate(true)
	receipt.erase("damage_attempted")
	return receipt


func _pending_error(snapshot: Dictionary) -> String:
	var pending: Dictionary = {}
	if int(snapshot.schema_version) == 2:
		if not snapshot.pending_delivery is Dictionary:
			return "Pending delivery requires a closed object"
		pending = snapshot.pending_delivery
		if not Codec.keys_error(pending, ["events", "visual_next_cue", "visuals_pending", "state_pending", "cue_phases"]).is_empty() or not pending.events is Array or not pending.cue_phases is Array or not pending.visuals_pending is bool or not pending.state_pending is bool or not Codec.is_integer(pending.visual_next_cue, 0, _cues.size()):
			return "Malformed bounded pending delivery/cue phase state"
		if pending.events.size() > snapshot.opportunities.size() or pending.cue_phases.size() != _cues.size() or (pending.events.is_empty() and not pending.visuals_pending and not pending.state_pending):
			return "Schema2 must retain a genuine finite delivery remainder"
		if not pending.visuals_pending and int(pending.visual_next_cue) != 0:
			return "A finished presentation cannot retain a cue cursor"
		if snapshot.status == "complete" or (snapshot.status == "cancelled" and (pending.visuals_pending or pending.state_pending)):
			return "Terminal state cannot license pending observers/presentation"
		if snapshot.status == "running" and (not pending.visuals_pending or not pending.state_pending or (not pending.events.is_empty() and int(pending.visual_next_cue) != 0)):
			return "Running remainder must retain its final presentation/state callback"
	var entries: Array = pending.get("events", [])
	var first: int = snapshot.opportunities.size() - entries.size()
	for index: int in range(entries.size()):
		var entry: Variant = entries[index]
		if not entry is Dictionary or not Codec.keys_error(entry, ["event_index", "stage"]).is_empty() or not Codec.is_integer(entry.event_index, first + index, first + index) or entry.stage not in ["present", "damage", "notify"] or (index > 0 and entry.stage != "present"):
			return "Pending entries must be the exact canonical contiguous suffix"
	if snapshot.status == "running" and not entries.is_empty() and first == 0 and entries[0].stage == "present":
		return "First attack cannot retain an unpresented receipt at a supported callback boundary"
	for index: int in range(snapshot.opportunities.size()):
		var receipt: Dictionary = snapshot.opportunities[index]
		var before_damage: bool = index >= first and entries[index - first].stage in ["present", "damage"]
		if receipt.damage_attempted != (receipt.contact and not before_damage):
			return "Pending stage must truthfully match consumed damage attempt"
	if not pending.is_empty():
		for index: int in range(pending.cue_phases.size()):
			var phase: Variant = pending.cue_phases[index]
			if not phase is String or phase not in ["clear", "warning", "lock", "active", "recovery"]:
				return "Pending cue phases must use the closed shared grammar"
			if snapshot.status == "cancelled":
				if phase != "clear":
					return "Canceled remainder must discard all damaging presentation"
				continue
			if not snapshot.cursor.armed:
				# A held bind observer may interrupt the first warning refresh.
				# Only the exact unpresented suffix can still be clear.
				var expected: String = "warning" if index < int(pending.visual_next_cue) else "clear"
				if not entries.is_empty() or not snapshot.opportunities.is_empty() or phase != expected:
					return "Unarmed pending cues must retain their exact warning/clear presentation prefix"
				continue
			if index >= first and index < snapshot.opportunities.size():
				var stage: String = entries[index - first].stage
				if phase != ("lock" if stage == "present" else "active"):
					return "Pending attack phase must match its once-only delivery stage"
			elif index < snapshot.opportunities.size():
				if phase not in ["active", "recovery"] or (entries.is_empty() and index < int(pending.visual_next_cue) and phase != "recovery"):
					return "Delivered cue phase lost active/recovery presentation order"
			elif snapshot.opportunities.is_empty():
				var expected: String = "lock" if index < int(pending.visual_next_cue) else "warning"
				if phase != expected:
					return "First armed refresh must retain its exact lock/warning presentation prefix"
			elif phase != "lock":
				return "Future pending cue cannot skip its lock grammar"
	if _status != "idle":
		var current_first: int = _opportunities.size() - _pending_delivery.get("events", []).size()
		if first < current_first:
			return "Existing owner cannot re-notify a delivered event prefix"
		if not entries.is_empty() and not _pending_delivery.get("events", []).is_empty() and first == current_first:
			var stages: Array[String] = ["present", "damage", "notify"]
			if stages.find(entries[0].stage) < stages.find(_pending_delivery.events[0].stage):
				return "Existing owner cannot rewind an interrupted delivery stage"
	return ""


func _source_id(bindings: Dictionary) -> String:
	for id: String in bindings.get("owners", {}):
		if bindings.owners[id] == self:
			return id
	return ""


func _near(left: float, right: float) -> bool:
	return absf(left - right) <= TIME_EPSILON_S


func _physics_process(_delta: float) -> void:
	if _status in ["running", "complete"]:
		advance()


func _contact(record: Dictionary, target: Node3D) -> bool:
	var offset: Vector3 = target.global_position - record.world_origin
	var vertical: float = absf(offset.y)
	offset.y = 0.0
	var geometry: Dictionary = record.geometry
	if offset.length() > float(geometry.reach) or vertical > float(geometry.max_vertical_distance):
		return false
	if offset.length() > float(geometry.origin_disk_radius) and offset.normalized().dot(record.direction) < float(geometry.cone_min_dot):
		return false
	var query := PhysicsRayQueryParameters3D.create(record.world_origin + Vector3.UP * float(geometry.los.height), target.global_position + Vector3.UP * float(geometry.los.height), int(geometry.los.collision_mask))
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _lease_error(lease: Dictionary, hero: CinderPlayer, scheduler: Node3D) -> String:
	if lease.is_empty() or lease.get("source_instance_id") != get_instance_id() or lease.get("adapter", {}).get("kind") != "replay":
		return "Exact stationary replay source lease required"
	var adapter: Dictionary = lease.adapter
	if not _same_transport(adapter.get("sequence"), _configuration.sequence) or adapter.get("source_epoch") != _configuration.source_epoch or adapter.get("generation") != _configuration.generation or adapter.get("max_dispatch_delay_s") != MAX_DISPATCH_DELAY_S:
		return "Replay lease cannot substitute frozen sequence, epoch, generation or grace"
	if not is_instance_valid(hero) or scheduler.replay_target(lease.id) != hero:
		return "Playback target must be the actual player used in the whole witness"
	return ""


func _bindings_error(scheduler: Node3D, heroes: Dictionary) -> String:
	if not is_instance_valid(scheduler) or not scheduler.is_inside_tree() or scheduler.is_queued_for_deletion() or scheduler.get_world_3d() != get_world_3d() or scheduler.process_physics_priority >= process_physics_priority:
		return "Same-world earlier-physics scheduler required"
	for method: String in ["get_clock", "replay_reservation_state", "replay_reservation_error", "replay_target", "replay_world_root", "snapshot_error", "snapshot_state"]:
		if not scheduler.has_method(method):
			return "Missing public replay scheduler API: " + method
	if heroes.size() != 1 or not _stable_id(heroes.keys()[0]):
		return "Exactly one stable shared-player target required"
	var hero: CinderPlayer = heroes.values()[0] as CinderPlayer
	if not is_instance_valid(hero) or not hero.is_inside_tree() or hero.is_queued_for_deletion() or hero.get_world_3d() != get_world_3d() or hero.process_physics_priority >= process_physics_priority:
		return "Target must be a real same-world earlier-physics shared player"
	return ""


func _ready_boundary() -> bool:
	return is_inside_tree() and is_node_ready() and not is_queued_for_deletion() and not _configuration.is_empty()


func _exchange_data(lease: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: String in EXCHANGE_KEYS:
		result[key] = lease[key]
	return result.duplicate(true)


func _same_exchange(left: Dictionary, right: Dictionary) -> bool:
	var lhs: Dictionary = _encode_exchange(left)
	var rhs: Dictionary = _encode_exchange(right)
	return _same_transport(lhs, rhs)


func _same_transport(left: Variant, right: Variant) -> bool:
	# Exact persistence preserves scalar types/bits; the explicit timing epsilon
	# is reserved for derived due/arming arithmetic, never transport identity.
	if typeof(left) != typeof(right):
		return false
	if left is float:
		var lhs := PackedByteArray()
		var rhs := PackedByteArray()
		lhs.resize(8)
		rhs.resize(8)
		lhs.encode_double(0, left)
		rhs.encode_double(0, right)
		return lhs == rhs
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
	return left == right


func _encode_exchange(value: Dictionary) -> Dictionary:
	var result: Dictionary = value.duplicate(true)
	for key: String in ["source_position", "opening_position"]:
		if result.get(key) is Vector3:
			result[key] = Codec.vector3(result[key])
	return result


func _events() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot: Dictionary in _plan.timeline.slots:
		result.append_array(slot.events)
	return result


func _loadouts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot: Dictionary in _plan.capture_snapshot.slots:
		result.append({"dash": slot.dash.equipment_ids.duplicate(true), "primary": slot.primary.equipment_ids.duplicate(true), "blast": slot.blast.get("equipment_ids", {}).duplicate(true)})
	return result


func _build_preview() -> void:
	_apparition.set_presentation(_configuration.presentation_id)
	var vertices: Array[Vector3] = []
	for slot: Dictionary in _plan.timeline.slots:
		for index: int in range(1, slot.route.size()):
			Footprint.append_edge(vertices, slot.route[index - 1].position + Vector3.UP * 0.026, slot.route[index].position + Vector3.UP * 0.026)
	_route_mesh.mesh = Footprint.mesh_from_vertices(vertices)
	for event: Dictionary in _events():
		var cue := Cue.new()
		cue.name = "ExactAttackCue%d" % _cues.size()
		add_child(cue)
		_cues.append(cue)
		_cue_phases.append("clear")
	_refresh_visuals()


func _refresh_visuals(quiet: bool = false) -> bool:
	var cursor_state: Dictionary = _cursor.state()
	var pose: Dictionary = _presentation_pose() if quiet else _visual_pose()
	_apparition.visible = _status == "running" and not pose.is_empty()
	_apparition_root.visible = _apparition.visible
	if _apparition.visible:
		_apparition_root.global_position = pose.position
		_apparition.face(pose.direction)
		_apparition.set_loadout_visual(pose.equipment_ids.weapon, pose.equipment_ids.jacket, pose.equipment_ids.pants, pose.equipment_ids.shoes)
		_apparition.set_action(pose.action, float(pose.progress))
	_route_mesh.visible = _status == "running" # Optional harmless route ornament.
	_failure_marker.visible = _status == "cancelled"
	if _failure_marker.visible:
		_failure_marker.global_position = global_position + Vector3.UP * 0.04
		_failure_marker.mesh = CueMesh.source_mesh("active")
	var events: Array[Dictionary] = _events()
	var start: int = 0 if quiet or _pending_delivery.is_empty() else int(_pending_delivery.visual_next_cue)
	for index: int in range(start, _cues.size()):
		var cue: Node3D = _cues[index]
		if not is_instance_valid(cue) or cue.is_queued_for_deletion():
			if not quiet and _status == "running":
				_fail("required_replay_cue_lost")
			return false
		if not _cue_children_error(cue).is_empty():
			if quiet:
				# Broken renderer children cannot be dereferenced by Cue.clear().
				# Hide the container; cancellation receipt and failure marker remain.
				cue.hide()
				continue
			_fail("required_replay_renderer_child_lost")
			return false
		var was_blocked: bool = cue.is_blocking_signals()
		if quiet:
			cue.set_block_signals(true)
		var phase: String = "clear"
		if _status == "running":
			phase = "warning" if not cursor_state.get("armed", false) else "lock"
			if index < _opportunities.size():
				phase = "recovery"
			if quiet and not _pending_delivery.is_empty():
				phase = _pending_delivery.cue_phases[index]
		_cue_phases[index] = phase
		if not quiet and not _pending_delivery.is_empty():
			_pending_delivery.visual_next_cue = index + 1
			_pending_delivery.cue_phases = _cue_phases.duplicate()
		var presented: bool
		if phase == "clear":
			presented = cue.clear()
			if _status == "cancelled":
				cue.hide() # A current notifying cue may reject clear; fail closed now.
		else:
			var record: Dictionary = events[index].record
			var geometry: Dictionary = Geometry.cone(record.world_origin, record.direction, float(record.geometry.reach), float(record.geometry.cone_min_dot), float(record.geometry.origin_disk_radius))
			presented = cue.present(geometry, phase)
		cue.set_block_signals(was_blocked)
		if not quiet and _status == "running":
			if not presented:
				_fail("required_replay_cue_presentation_failed")
				return false
			if not _delivery_guard() or get_tree().paused:
				return false
	if not quiet and not _pending_delivery.is_empty():
		_pending_delivery.visuals_pending = false
		_pending_delivery.visual_next_cue = 0
	return true


func _presentation_pose() -> Dictionary:
	if _status != "running":
		return {}
	var presented: int = -1
	if not _pending_delivery.is_empty():
		if not _pending_delivery.events.is_empty():
			var first: Dictionary = _pending_delivery.events[0]
			# Cursor consumption precedes callbacks; it is not presentation order.
			# Remaining present means its preceding event is still shown.
			presented = int(first.event_index) - (1 if first.stage == "present" else 0)
		elif _pending_delivery.visuals_pending and int(_pending_delivery.visual_next_cue) == 0:
			# A final event observer can pause after popping its entry but before
			# the later cursor-based visual refresh starts.
			presented = _opportunities.size() - 1
	if presented >= 0:
		var event: Dictionary = _delivery_event(presented)
		return {"position": event.record.world_origin, "direction": event.record.direction, "equipment_ids": event.record.equipment_ids.duplicate(true), "action": event.kind, "progress": 0.0}
	return _visual_pose()


func _visual_pose() -> Dictionary:
	var cursor_state: Dictionary = _cursor.state()
	var poses: Array = cursor_state.get("poses", [])
	if _status != "running" or poses.is_empty():
		return {}
	var pose: Dictionary = poses[0]
	var result: Dictionary = {"position": pose.position, "direction": pose.direction, "equipment_ids": pose.equipment_ids.duplicate(true), "action": pose.action, "progress": pose.action_progress, "visual_duration_s": 0.0}
	if pose.stage == "travel":
		return result
	var local_s: float = float(cursor_state.last_advanced_clock_s) - float(cursor_state.timeline_origin_s)
	for slot: Dictionary in _plan.timeline.slots:
		if slot.slot_id != pose.slot_id:
			continue
		for event: Dictionary in slot.events:
			if local_s + TIME_EPSILON_S < float(event.at_s):
				continue
			var record: Dictionary = event.record
			# Player's existing cosmetic slash/blast durations are longer than
			# logical commitment. Derive them from the same static cooldown and
			# external cursor clock; presentation changes no damage/deadline.
			var duration: float = float(record.cooldown_s) * (0.28 / 0.30 if event.kind == "primary" else 0.24 / 0.45)
			var elapsed: float = maxf(local_s - float(event.at_s), 0.0)
			result.position = record.world_origin
			result.direction = record.direction
			result.equipment_ids = record.equipment_ids.duplicate(true)
			result.action = event.kind if elapsed < duration else "idle"
			result.progress = clampf(elapsed / duration, 0.0, 1.0) if elapsed < duration else 0.0
			result.visual_duration_s = duration
	return result


func _present_event(event: Dictionary) -> void:
	var record: Dictionary = event.record
	_apparition.visible = true
	_apparition_root.visible = true
	_apparition_root.global_position = record.world_origin
	_apparition.face(record.direction)
	_apparition.set_loadout_visual(record.equipment_ids.weapon, record.equipment_ids.jacket, record.equipment_ids.pants, record.equipment_ids.shoes)
	_apparition.set_action(event.kind, 0.0)
	var events: Array[Dictionary] = _events()
	for index: int in range(events.size()):
		if events[index].event_id == event.event_id:
			var geometry: Dictionary = Geometry.cone(record.world_origin, record.direction, float(record.geometry.reach), float(record.geometry.cone_min_dot), float(record.geometry.origin_disk_radius))
			_cue_phases[index] = "active"
			_pending_delivery.cue_phases = _cue_phases.duplicate()
			if not _cues[index].present(geometry, "active"):
				_fail("required_replay_cue_presentation_failed")


func _on_invalidated(id: String, reason: String) -> void:
	if id == _reservation_id and _status == "running":
		_fail(reason)


func _fail(reason: String) -> Dictionary:
	if _status == "cancelled":
		return {"accepted": false, "reason": _reason, "events": []}
	_status = "cancelled"
	_reason = reason.left(512)
	_cancelled_at = _scheduler.get_clock() if is_instance_valid(_scheduler) else null
	last_error = _reason
	_transaction_depth += 1
	if is_instance_valid(_scheduler):
		_scheduler.cancel(_reservation_id, _reason)
		_sync_cancelled_exchange()
	if not _pending_delivery.is_empty():
		_pending_delivery.visuals_pending = false
		_pending_delivery.visual_next_cue = 0
		_pending_delivery.state_pending = false
		_pending_delivery.cue_phases = []
		for _cue: Node3D in _cues:
			_pending_delivery.cue_phases.append("clear")
		if _pending_delivery.events.is_empty():
			_pending_delivery = {}
	_refresh_visuals(true)
	playback_failed.emit(_reason)
	state_changed.emit(state())
	_transaction_depth -= 1
	return {"accepted": false, "reason": _reason, "events": []}


func _sync_cancelled_exchange() -> void:
	# A cancellation can arrive immediately after scheduler lock but before our
	# first advance. Retain that REAL arming/timing without consuming due events.
	var tombstone: Dictionary = _scheduler.replay_cancellation_state(_reservation_id)
	if tombstone.is_empty() or not is_instance_valid(_hero) or tombstone.source_instance_id != get_instance_id() or tombstone.response_actor_instance_id != _hero.get_instance_id() or not _same_transport(tombstone.sequence, _configuration.sequence) or tombstone.source_epoch != _configuration.source_epoch or tombstone.generation != _configuration.generation:
		return
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision"]:
		_exchange[key] = tombstone[key]
	_exchange.adapter.locked = tombstone.locked
	_exchange.adapter.timeline_origin_s = tombstone.timeline_origin_s
	var saved: Dictionary = _cursor.snapshot_state()
	if tombstone.locked and not saved.armed:
		var candidate = Cursor.new()
		if candidate.restore_state(saved, _configuration.sequence, _configuration.source_epoch, int(_configuration.generation), float(saved.last_advanced_clock_s)) and candidate.arm(float(tombstone.timeline_origin_s), float(tombstone.lock_from_s)):
			_cursor = candidate


func _stable_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 128:
		return false
	for character: String in value:
		if not character.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789_./:-":
			return false
	return true


func _reject(reason: String) -> bool:
	last_error = reason
	return false


func _mesh_node(node_name: String, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	node.add_to_group("required_cues")
	node.top_level = true
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.albedo_color = color
	node.material_override = material
	add_child(node)
	return node
