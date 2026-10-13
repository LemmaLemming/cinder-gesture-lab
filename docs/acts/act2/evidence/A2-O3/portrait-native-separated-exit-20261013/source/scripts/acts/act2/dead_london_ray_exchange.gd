class_name Act2DeadLondonRayExchange
extends Node3D
## DRAFT greybox B05 adapter. No native/parser/combat/art acceptance.
## One persistent native low-joint owner and one shared ThreatCue for all cycles.
## Parent owns encounter begin/end, two HP pools, Foot, progression, source pose,
## and its SINGLE composite InteractionCue + bind_damage_window gate. This driver
## never binds an actor gate and never writes that composite opening cue.
## Reuses owned Scout custody/sweep/paused-path patterns; no shared system copy.
##
## Required OWNED interfaces (not new shared APIs):
##   bait.is_bound_to(hero:CinderPlayer)->bool [implemented; focused native binding15/0 at Shared38],
##   bait.state/sample_for_ray/snapshot_error as dead_london_bait.gd.
##   owner.source_snapshot_state()->Dictionary, pure live/paused projection:
##     api_revision="act2-sentry-source-1",source_id,root_position(encoded Vector3),
##     armed,phase_pending,defeated,
##     opening_state in clear/available/active/spent, read from actual parent cue.
##   owner.source_snapshot_error(flat:Dictionary)->String, pure prospective
##     authored/structural validation; MUST NOT compare current dynamic phase.
## Parent validates flat against its FULL staged actor/phase/HP/pending tuple and
## quietly restores that actor and composite cue before this adapter commit.
## Parent synchronizes its composite pose/cue on publication before external
## pause observers; its gate combines this ray recovery with real Foot recovery.
##
## Configure once. activate samples actual bait ONCE; no live-Hero tracking and
## no update_tracking. Source/opening remain at the same low native anchor for
## the whole lease. Cosmetics cannot move the native owner. Role below is only
## proposed greybox reuse of Scout timing, not a demonstrated B05 balance tune.
## Paired restore: native Player -> bait/whole actor + parent cue -> Scheduler ->
## this driver. Prospective reader receives COMPLETE staged Player/bait packets.
## Diagnostic proof is not serialized and never grants replay/combat authority.

signal state_changed(source_id: String, exchange_state: Dictionary)
signal hit_resolved(source_id: String, result: Dictionary)

const Geometry: GDScript = preload("res://scripts/combat/threat_geometry.gd")
const Difficulty: GDScript = preload("res://scripts/combat/difficulty.gd")
const Codec: GDScript = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson: GDScript = preload("res://scripts/campaign/exact_json.gd")
const PlayerScript: GDScript = preload("res://scripts/player.gd")
const BaitScript: GDScript = preload("res://scripts/acts/act2/dead_london_bait.gd")
const CueScript: GDScript = preload("res://scripts/cues/threat_cue.gd")
const API_REVISION: String = "act2-b05-ray-exchange-1"
const RAW_ROLE: Dictionary = {"raw_damage": 10.0, "windup_s": 1.55, "lock_s": 1.10, "active_s": 0.16, "recovery_s": 1.60, "attack_interval_s": 1.60, "max_hp": 15.0, "move_speed": 0.0}
const TIMING_FLOORS: Dictionary = {"windup_s": 1.55, "lock_s": 1.10, "recovery_s": 1.60}
const REACH: float = 3.8
const RADIUS: float = 0.31
const EPSILON: float = 0.00001
const MAX_DEFERRED_PATHS: int = 256
const CONTEXT_KEYS: Array[String] = ["encounter_id", "world_revision", "recognition_s", "attack_input_margin_s", "escape_directions", "return_directions", "floor_regions"]
const SOURCE_API: String = "act2-sentry-source-1"
const SOURCE_KEYS: Array[String] = ["api_revision", "source_id", "root_position", "armed", "phase_pending", "defeated", "opening_state"]
const EXCHANGE_KEYS: Array[String] = ["id", "source_position", "geometry", "opening_position", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision", "adapter"]
const RECORD_KEYS: Array[String] = ["status", "phase", "cycle", "direction", "bait_sample", "exchange", "context", "sample", "hit_consumed", "last_cancel_reason", "presentation_witness", "deferred_paths"]
const BAIT_KEYS: Array[String] = ["boundary", "point", "last_sequence", "dash_sequence", "initial_floor", "initial_sequence", "receipt", "player_clock_s"]
const RESPONSE_NATIVE_KEYS: Array[String] = ["actor", "stats", "stable", "dash_cooldown_left_s", "primary_cooldown_left_s", "commitment_remaining_s", "primary_commitment_s", "motion", "equipment_ids", "action_clock_s", "pending_weapon_id"]

var last_error: String = ""
var last_snapshot_error: String = ""
var _configured: bool = false
var _retired: bool = false
var _hero: CinderPlayer
var _scheduler: CinderThreatScheduler
var _owner: Node3D
var _owner_script: Script
var _hero_script: Script
var _bait: RefCounted
var _cue: CinderThreatCue
var _opening: CinderInteractionCue
var _source_id: String = ""
var _anchor: Vector3 = Vector3.ZERO
var _profile_id: String = ""
var _role: Dictionary = {}
var _context: Dictionary = {}
var _record: Dictionary = {}
var _proof: Dictionary = {}
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

func configure(hero: CinderPlayer, scheduler: CinderThreatScheduler, owner: Node3D, bait: RefCounted, parent_opening: CinderInteractionCue, profile_id: String, response_context: Dictionary) -> bool:
	if _configured or _retired or _transaction_depth > 0 or _snapshot_busy or not is_inside_tree() or not is_node_ready():
		return _reject("Configure a fresh ready persistent B05 ray outside callbacks")
	for node: Variant in [hero, scheduler, owner, parent_opening]:
		if not is_instance_valid(node) or not node.is_inside_tree() or not node.is_node_ready() or node.is_queued_for_deletion() or node.get_world_3d() != get_world_3d():
			return _reject("Actual ready same-world Hero/Scheduler/low joint/composite cue required")
	if hero.process_physics_priority >= process_physics_priority or scheduler.process_physics_priority >= process_physics_priority or not owner.has_method("source_snapshot_state") or not owner.has_method("source_snapshot_error") or not owner.global_position.is_finite() or owner.global_position.y != 0.0:
		return _reject("Earlier native physics and explicit floor-plane source projection required")
	if not is_instance_valid(bait) or bait.get_script() != BaitScript or not bait.has_method("is_bound_to") or not bool(bait.call("is_bound_to", hero)):
		return _reject("Owned bait needs public exact-Hero is_bound_to custody (no private field access)")
	var error: String = _context_error(response_context)
	if not error.is_empty(): return _reject(error)
	var role: Dictionary = Difficulty.new().resolve_role(RAW_ROLE, profile_id, TIMING_FLOORS)
	if role.is_empty() or scheduler.encounter_profile().get("id") != profile_id:
		return _reject("Resolve authored raw stationary role once for parent's active fixed profile")
	var flat: Variant = owner.call("source_snapshot_state")
	if not flat is Dictionary or not Codec.keys_error(flat, SOURCE_KEYS).is_empty() or not _stable_id(flat.get("source_id")) or not String(owner.call("source_snapshot_error", flat)).is_empty() or flat.get("armed") != true or flat.get("phase_pending") != false or flat.get("defeated") != false:
		return _reject("Actual configured available source and complete public flat projection required")
	_hero = hero
	_hero_script = hero.get_script()
	_scheduler = scheduler
	_owner = owner
	_owner_script = owner.get_script()
	_bait = bait
	_opening = parent_opening
	_source_id = flat.source_id
	_anchor = owner.global_position
	_context = response_context.duplicate(true)
	_profile_id = profile_id
	_role = role.duplicate(true)
	_record = {"status": "idle", "phase": "clear", "cycle": 0, "direction": Vector3.BACK, "bait_sample": {}, "exchange": {}, "context": {}, "sample": {}, "hit_consumed": false, "last_cancel_reason": "", "presentation_witness": {}, "deferred_paths": []}
	_cue = CueScript.new()
	_cue.name = "PersistentB05RayCue"
	add_child(_cue)
	_configured = true
	if not _source_flat_error(flat).is_empty() or not _opening_matches(flat):
		cleanup()
		return _reject("Composite opening must already truthfully match actual source policy")
	_scheduler.reservation_invalidated.connect(_on_invalidated)
	last_error = ""
	return true

func set_response_context_provider(provider: Callable) -> bool:
	if _retired or _transaction_depth > 0 or _snapshot_busy or _cancelling or not is_inside_tree() or not is_node_ready() or not provider.is_valid():
		return _reject("Set valid ephemeral authored provider outside callbacks")
	_context_provider = provider
	_provider_required = true
	return true

func set_presentation_guard(provider: Callable) -> bool:
	if _retired or _transaction_depth > 0 or _snapshot_busy or _cancelling or not is_inside_tree() or not is_node_ready() or not provider.is_valid():
		return _reject("Set valid ephemeral portrait guard outside callbacks")
	_presentation_guard = provider
	_guard_required = true
	return true

func activate(response_context: Dictionary = {}) -> Dictionary:
	if _transaction_depth > 0 or _snapshot_busy or _cancelling or not _native_bound() or get_tree().paused or not _source_available() or _record.status == "running" or not Codec.is_integer(_record.cycle, 0, Codec.MAX_SAFE_INTEGER - 1):
		return _denied("Admit actual living available low joint outside callbacks")
	var sampled: Dictionary = _sample_bait()
	if sampled.is_empty(): return _denied(last_error)
	var shape: Dictionary = _lane(sampled.point)
	if shape.is_empty(): return _denied("Actual bait needs a distinct in-reach floor point; never substitute live Hero")
	var context: Dictionary = _provided_context(shape, _context if response_context.is_empty() else response_context)
	if not _current_context_valid(context) or not _source_available() or not _presentation_allowed(shape) or not _source_available() or get_tree().paused:
		return _denied("Authored response/source/full capsule portrait unavailable")
	var response: Dictionary = _response(context)
	var threat: Dictionary = {"role": _role.duplicate(true), "geometry": shape, "source_stationary": true, "opening_stationary": true, "opening_position": _anchor, "cooldown_remaining_s": 0.0}
	# Captured references cancel a just-admitted lease even if a prune callback
	# retires this driver before its reservation ID can enter the local record.
	var scheduler: Variant = _scheduler
	var owner: Variant = _owner
	_transaction_depth += 1
	var answer: Dictionary = scheduler.request_tracking(owner, threat, response)
	if answer.get("accepted", false):
		var id: String = String(answer.reservation_id)
		if not _native_bound():
			if is_instance_valid(scheduler): scheduler.cancel(id, "b05_unarmed_admission_retired")
			answer = _denied("Accepted unarmed warning retired during native cleanup")
		else:
			# Adopt the copied native lease BEFORE any callback-producing query.
			# Even a later admission refusal needs a coherent cancelled cycle and
			# original cooldown, rather than an idle record with an unexplained lease.
			var now: float = scheduler.get_clock()
			_record.status = "running"
			_record.phase = "warning"
			_record.cycle += 1
			_record.direction = _direction(shape)
			_record.bait_sample = sampled.duplicate(true)
			_record.exchange = _exchange_data(answer.reservation)
			_record.context = context
			_record.sample = {"position": _hero.global_position, "clock_s": now}
			_record.hit_consumed = false
			_record.last_cancel_reason = ""
			_record.presentation_witness = {}
			_record.deferred_paths = []
			_proof = {}
			var live: Dictionary = scheduler.reservation_state(id)
			if not _source_available() or _record.status != "running" or live.is_empty() or get_tree().paused or int(live.source_instance_id) != owner.get_instance_id() or live.armed or _exchange_data(live) != _record.exchange:
				cancel("b05_unarmed_admission_lost")
				if is_instance_valid(scheduler): scheduler.cancel(id, "b05_unarmed_admission_lost")
				answer = _denied("Accepted unarmed warning lost actual custody")
			else:
				_present()
				_post_presentation(now)
	else:
		last_error = String(answer.get("reason", "Unarmed B05 warning refused"))
	_transaction_depth -= 1
	return answer.duplicate(true)

func tick() -> void:
	if _transaction_depth > 0 or _snapshot_busy or not is_inside_tree() or get_tree().paused: return
	if not _native_bound():
		if _configured and not _retired: cancel("required_bindings_unavailable")
		return
	if _record.status != "running": return
	_transaction_depth += 1
	var now: float = _scheduler.get_clock()
	var committed_response: Dictionary = {}
	if not _source_available():
		cancel("b05_source_or_hero_unavailable")
		_transaction_depth -= 1
		return
	var live: Dictionary = _scheduler.reservation_state(String(_record.exchange.id))
	if not _native_bound() or _record.status != "running":
		_transaction_depth -= 1
		return
	if live.is_empty():
		if _record.exchange.adapter.locked and now > float(_record.exchange.recovery_until_s):
			_record.status = "complete"
			_record.phase = "clear"
			_record.presentation_witness = {}
			_record.deferred_paths = []
			_proof = {}
			_present()
		else:
			cancel("b05_reservation_missing")
		_transaction_depth -= 1
		return
	if not _source_available() or int(live.source_instance_id) != _owner.get_instance_id() or _exchange_data(live) != _record.exchange:
		cancel("b05_exchange_or_source_changed")
		_transaction_depth -= 1
		return
	if not live.armed and now >= float(live.lock_from_s):
		var shape: Dictionary = _record.exchange.geometry
		var context: Dictionary = _provided_context(shape, _record.context)
		if not _native_bound():
			_transaction_depth -= 1
			return
		if get_tree().paused:
			_freeze_paused_tick(now)
			_transaction_depth -= 1
			return
		if not _current_context_valid(context) or not _source_available() or not _presentation_allowed() or not _source_available():
			cancel("b05_fresh_response_or_portrait_unavailable")
			_transaction_depth -= 1
			return
		if get_tree().paused:
			_freeze_paused_tick(now)
			_transaction_depth -= 1
			return
		_record.context = context
		var response: Dictionary = _response(context)
		if not response.get("pending_weapon_id") is String or not String(response.pending_weapon_id).is_empty():
			cancel("b05_tracking_pending_weapon_change")
			_transaction_depth -= 1
			return
		var scheduler: Variant = _scheduler
		var answer: Dictionary = scheduler.commit_tracking(String(live.id), shape, response)
		if answer.get("accepted", false):
			# Return deadlines are authoritative even if a later query/callback
			# revokes the proof. Preserve the retimed cooldown before cancellation.
			_record.exchange = _exchange_data(answer.reservation)
		if not _native_bound() or _record.status != "running":
			if answer.get("accepted", false) and is_instance_valid(scheduler): scheduler.cancel(String(answer.reservation_id), "b05_commit_retired")
			_transaction_depth -= 1
			return
		if not answer.get("accepted", false):
			cancel("b05_tracking_lock_unproved")
			_transaction_depth -= 1
			return
		live = scheduler.reservation_state(String(answer.reservation_id))
		if not _native_bound() or live.is_empty() or _record.status != "running":
			_transaction_depth -= 1
			return
		if not _source_available() or not _same_response(response, _hero.get_threat_response_state()) or int(live.source_instance_id) != _owner.get_instance_id() or not live.armed or live.geometry != shape:
			cancel("b05_commit_native_response_changed")
			_transaction_depth -= 1
			return
		_record.exchange = _exchange_data(live)
		committed_response = response.duplicate(true)
		_proof = answer.get("proof", {}).duplicate(true)
		if not Geometry.finite_vector(_proof.get("landing")) or not Geometry.finite_vector(_proof.get("attack_position")):
			cancel("b05_accepted_view_witness_missing")
			_transaction_depth -= 1
			return
		_record.presentation_witness = {"landing": _proof.landing, "attack_position": _proof.attack_position}
		# Do not resample bait or update direction here: windup geometry is fixed.
	_record.phase = String(live.state)
	_present()
	if _post_presentation(now, committed_response):
		_resolve_segment(now, bool(live.armed))
		_post_presentation(now)
	_transaction_depth -= 1

func _physics_process(_delta: float) -> void:
	tick()

func recovery_window_open() -> bool:
	# Deadline/custody predicate only: parent derives the ONE opening cue from
	# this and real Foot recovery, then separately checks available/spent policy.
	# Never require the cue to already be available to calculate availability.
	if not _native_bound() or get_tree().paused or not _required_presentation_valid() or _record.phase != "recovery": return false
	var live: Dictionary = _scheduler.reservation_state(String(_record.exchange.id))
	if not _native_bound() or get_tree().paused or not _required_presentation_valid() or live.is_empty(): return false
	if not _presentation_allowed(): return false
	return _native_bound() and not get_tree().paused and _required_presentation_valid() and live.armed and live.state == "recovery" and int(live.source_instance_id) == _owner.get_instance_id() and _exchange_data(live) == _record.exchange and _scheduler.get_clock() > float(live.active_until_s) and _scheduler.get_clock() <= float(live.recovery_until_s)

func cancel(reason: String = "b05_ray_cancelled") -> bool:
	if _snapshot_busy or _cancelling or not _configured or reason.is_empty() or _record.status in ["cancelled", "complete"]: return false
	_cancelling = true
	_transaction_depth += 1
	var id: String = String(_record.exchange.get("id", "")) if _record.status == "running" else ""
	_record.status = "cancelled" if _record.cycle > 0 else "idle"
	_record.phase = "clear"
	_record.last_cancel_reason = reason if _record.cycle > 0 else ""
	_record.presentation_witness = {}
	_record.deferred_paths = []
	_proof = {}
	if not id.is_empty() and is_instance_valid(_scheduler): _scheduler.cancel(id, reason)
	_present()
	_transaction_depth -= 1
	_cancelling = false
	return true

func source_defeated() -> bool:
	var flat: Dictionary = _source_flat()
	if flat.is_empty() or not flat.defeated: return false
	cancel("b05_source_defeated")
	if is_instance_valid(_scheduler) and is_instance_valid(_owner): _scheduler.cancel_owner(_owner, "source_defeated")
	return true

func state() -> Dictionary:
	if not _configured: return {}
	return {"api_revision": API_REVISION, "source_id": _source_id, "status": _record.status, "phase": _record.phase, "phase_progress": _progress(_record, _scheduler.get_clock()) if _record.status == "running" and is_instance_valid(_scheduler) else 0.0, "cycle": _record.cycle, "direction": _record.direction, "armed": _record.status == "running" and _record.exchange.adapter.locked, "geometry": _record.exchange.get("geometry", {}).duplicate(true), "exchange": _record.exchange.duplicate(true), "bait_sample": _record.bait_sample.duplicate(true), "hit_consumed": _record.hit_consumed, "last_cancel_reason": _record.last_cancel_reason, "proof": _proof.duplicate(true), "proof_available": not _proof.is_empty(), "presentation_witness": _record.presentation_witness.duplicate(true)}

func get_cue() -> CinderThreatCue:
	return _cue if is_instance_valid(_cue) else null

func get_opening_cue() -> CinderInteractionCue:
	return _opening if is_instance_valid(_opening) else null # Parent's single real composite cue; this adapter never writes it.

func _resolve_segment(now: float, armed: bool) -> void:
	if not _native_bound() or _record.status != "running" or get_tree().paused: return
	var previous: Dictionary = _record.sample
	var path: Array[Dictionary] = []
	for segment: Dictionary in _record.deferred_paths: path.append(segment.duplicate(true))
	path.append({"from": previous.position, "to": _hero.global_position, "start_s": previous.clock_s, "end_s": now})
	_record.sample = {"position": _hero.global_position, "clock_s": now}
	_record.deferred_paths = []
	if not armed or _hero.dead or _record.hit_consumed or now < float(_record.exchange.active_from_s) or not Geometry.timed_path_hits(_record.exchange.geometry, path, float(_record.exchange.active_from_s), float(_record.exchange.active_until_s), CinderThreatScheduler.CAPSULE_RADIUS): return
	_record.hit_consumed = true # Consume before callbacks/invulnerability/death.
	var hero: Variant = _hero
	var damage: float = float(_role.damage)
	var source_id: String = _source_id
	var before: float = hero.hp
	hero.take_damage(damage, Vector3.ZERO)
	# Callbacks may retire/null all bindings. Captured valid Hero supplies the
	# actual loss; disappearance cannot cause another opportunity or dereference.
	if not is_instance_valid(hero): return
	var loss: float = maxf(before - float(hero.hp), 0.0)
	if hero.dead and _configured and not _retired: cancel("b05_shared_hero_dead")
	if not _retired: hit_resolved.emit(source_id, {"opportunity_consumed": true, "accepted": loss > 0.0, "raw_damage": damage, "hp_damage": loss, "impulse": Vector3.ZERO})

func _post_presentation(now: float, committed_response: Dictionary = {}) -> bool:
	# Check loss FIRST, including held pause; valid pause retains measured paths.
	if not _native_bound():
		if _configured and not _retired: cancel("b05_required_bindings_lost")
		return false
	if _record.status == "running" and not _required_presentation_valid(): cancel("b05_required_source_or_cue_lost")
	if _record.status != "running" or not _native_bound(): return false
	if not committed_response.is_empty() and not _same_response(committed_response, _hero.get_threat_response_state()):
		cancel("b05_commit_publication_response_changed")
		return false
	if get_tree().paused:
		_freeze_paused_tick(now, committed_response)
		return false
	var ready: bool = _ready_to_resolve()
	if not _native_bound() or _record.status != "running": return false
	if not committed_response.is_empty() and not _same_response(committed_response, _hero.get_threat_response_state()):
		cancel("b05_commit_guard_response_changed")
		return false
	if get_tree().paused:
		_freeze_paused_tick(now, committed_response)
		return false
	if not ready:
		cancel("b05_required_portrait_or_custody_lost")
		return false
	return true

func _freeze_paused_tick(now: float, committed_response: Dictionary = {}) -> void:
	if not _native_bound() or _record.status != "running": return
	if not _required_presentation_valid():
		cancel("b05_paused_source_or_cue_lost")
		return
	var live: Dictionary = _scheduler.reservation_state(String(_record.exchange.id))
	if live.is_empty() or not _required_presentation_valid() or int(live.source_instance_id) != _owner.get_instance_id() or _exchange_data(live) != _record.exchange:
		cancel("b05_paused_reservation_custody_lost")
		return
	_record.phase = String(live.state)
	_present(false)
	if not _native_bound() or not _required_presentation_valid() or not _presentation_allowed() or not _required_presentation_valid():
		cancel("b05_paused_required_presentation_lost")
		return
	if not committed_response.is_empty() and not _same_response(committed_response, _hero.get_threat_response_state()):
		cancel("b05_paused_commit_response_changed")
		return
	var previous: Dictionary = _record.sample
	if live.armed and not _record.hit_consumed and now >= float(live.active_from_s) and float(previous.clock_s) <= float(live.active_until_s) and now > float(previous.clock_s):
		if _record.deferred_paths.size() >= MAX_DEFERRED_PATHS:
			cancel("b05_deferred_path_limit")
			return
		_record.deferred_paths.append({"from": previous.position, "to": _hero.global_position, "start_s": previous.clock_s, "end_s": now})
	_record.sample = {"position": _hero.global_position, "clock_s": now}

func _present(notify: bool = true) -> void:
	if not is_instance_valid(_cue): return
	var cue: Variant = _cue
	var blocked: bool = cue.is_blocking_signals()
	if not notify: cue.set_block_signals(true)
	var accepted: bool = true
	if _record.status == "running" and not _retired:
		accepted = cue.present(_record.exchange.geometry, _record.phase)
	else:
		cue.clear()
	if is_instance_valid(cue):
		# Clear after a synchronous retirement observer returns from present;
		# shared cue.clear may refuse while its own notification is on-stack.
		if _retired or _record.status != "running": cue.clear()
		if not notify: cue.set_block_signals(blocked)
	if not accepted and not _retired:
		cancel("b05_required_threat_cue_refused")
		return
	# Parent already owns composite opening availability/spent policy and pose.
	if notify and not _retired: state_changed.emit(_source_id, state())

func _on_invalidated(id: String, reason: String) -> void:
	if not _retired and not _cancelling and not _snapshot_busy and _record.status == "running" and _record.exchange.get("id") == id:
		cancel(reason)

func _ready_to_resolve() -> bool:
	if get_tree().paused or not _required_presentation_valid(): return false
	var live: Dictionary = _scheduler.reservation_state(String(_record.exchange.id))
	if not _native_bound() or get_tree().paused or not _required_presentation_valid() or live.is_empty(): return false
	if not _presentation_allowed(): return false
	return _native_bound() and not get_tree().paused and _required_presentation_valid() and int(live.source_instance_id) == _owner.get_instance_id() and _exchange_data(live) == _record.exchange

func _required_presentation_valid() -> bool:
	if not _source_available() or _record.status != "running": return false
	var cue: Dictionary = _cue.state()
	return cue.phase == _record.phase and cue.geometry == _record.exchange.geometry and cue.source_visible and cue.footprint_visible == (_record.phase != "recovery") and cue.active_fill_visible == (_record.phase == "active") and _opening_matches(_source_flat())

func _source_available() -> bool:
	if not _native_bound() or _hero.dead or not is_visible_in_tree() or not _owner.is_visible_in_tree() or not _cue.is_visible_in_tree() or not _opening.is_visible_in_tree(): return false
	var flat: Dictionary = _source_flat()
	return not flat.is_empty() and flat.armed and not flat.phase_pending and not flat.defeated and _opening_matches(flat)

func _native_bound() -> bool:
	if not _configured or _retired or not is_inside_tree() or not is_node_ready() or is_queued_for_deletion(): return false
	for node: Variant in [_hero, _scheduler, _owner, _cue, _opening]:
		if not is_instance_valid(node) or not node.is_inside_tree() or not node.is_node_ready() or node.is_queued_for_deletion() or node.get_world_3d() != get_world_3d(): return false
	return _hero.get_script() == _hero_script and _owner.get_script() == _owner_script and _owner.global_position == _anchor and is_instance_valid(_bait) and _bait.get_script() == BaitScript and bool(_bait.call("is_bound_to", _hero))

func _source_flat() -> Dictionary:
	if not _native_bound(): return {}
	var value: Variant = _owner.call("source_snapshot_state")
	return value.duplicate(true) if _native_bound() and value is Dictionary and _source_flat_error(value).is_empty() else {}

func _source_flat_error(value: Dictionary) -> String:
	if not is_instance_valid(_owner): return "Actual native source projection reader unavailable"
	var error: String = Codec.value_error(value)
	if error.is_empty(): error = Codec.keys_error(value, SOURCE_KEYS)
	if not error.is_empty(): return error
	if value.api_revision != SOURCE_API or value.source_id != _source_id or not Codec.is_vector3(value.root_position) or Codec.read_vector3(value.root_position) != _anchor or not value.armed is bool or not value.phase_pending is bool or not value.defeated is bool or value.opening_state not in ["clear", "available", "active", "spent"]:
		return "Source projection must preserve authored native identity/root and closed policy"
	if (value.phase_pending or value.defeated or not value.armed) and value.opening_state in ["available", "active"]:
		return "Pending/spent/retired source cannot advertise an available opening"
	return String(_owner.call("source_snapshot_error", value))

func _opening_matches(flat: Dictionary) -> bool:
	if flat.is_empty() or not is_instance_valid(_opening) or _opening.global_position != _anchor: return false
	var current: Dictionary = _opening.state()
	return current.state == flat.opening_state and (current.state == "clear" or (current.trigger == "attack" and current.visible))

func _provided_context(shape: Dictionary, fallback: Dictionary) -> Dictionary:
	if not _provider_required: return fallback.duplicate(true)
	if not _context_provider.is_valid() or not _native_bound(): return {}
	_transaction_depth += 1
	var value: Variant = _context_provider.call(_source_id, shape.duplicate(true))
	_transaction_depth -= 1
	return value.duplicate(true) if _native_bound() and value is Dictionary else {}

func _presentation_allowed(shape: Dictionary = {}) -> bool:
	if not _native_bound(): return false
	if not _guard_required: return true
	if not _presentation_guard.is_valid(): return false
	var proposed: Dictionary = state()
	if not shape.is_empty():
		proposed.geometry = shape.duplicate(true)
		proposed.exchange = {"geometry": shape.duplicate(true)} if proposed.exchange.is_empty() else proposed.exchange
		proposed.exchange.geometry = shape.duplicate(true)
	_transaction_depth += 1
	var result: Variant = _presentation_guard.call(_source_id, proposed.duplicate(true))
	_transaction_depth -= 1
	return _native_bound() and result is bool and result

func _response(context: Dictionary) -> Dictionary:
	var response: Dictionary = _hero.get_threat_response_state()
	for key: String in CONTEXT_KEYS:
		if key != "encounter_id": response[key] = context[key]
	return response

func _same_response(before: Dictionary, after: Dictionary) -> bool:
	for key: String in RESPONSE_NATIVE_KEYS:
		if not before.has(key) or not after.has(key) or before[key] != after[key]: return false
	return true

func _current_context_valid(context: Dictionary) -> bool:
	return not context.is_empty() and _context_error(context).is_empty() and context.encounter_id == _context.encounter_id and context.world_revision == _context.world_revision and context.recognition_s == _context.recognition_s and context.attack_input_margin_s == _context.attack_input_margin_s and _floors_allowed(context.floor_regions)

func _sample_bait() -> Dictionary:
	var sample: Dictionary = _bait.call("sample_for_ray")
	var cached: Dictionary = _bait.call("state")
	if not Codec.keys_error(sample, ["boundary", "point", "last_sequence", "dash_sequence"]).is_empty() or not Geometry.finite_vector(sample.get("point")) or cached.is_empty() or sample.boundary != cached.boundary or sample.last_sequence != cached.last_sequence or sample.point != Codec.read_vector3(cached.landing):
		_reject("Sample only exact actual bound completed bait, not projected aim")
		return {}
	return {"boundary": sample.boundary, "point": sample.point, "last_sequence": sample.last_sequence, "dash_sequence": sample.dash_sequence, "initial_floor": Codec.read_vector3(cached.initial_floor), "initial_sequence": cached.initial_sequence, "receipt": null if cached.last_dash == null else cached.last_dash.duplicate(true), "player_clock_s": _hero.get_world_action_clock()}

func _lane(point: Vector3) -> Dictionary:
	var delta: Vector3 = point - _anchor
	delta.y = 0.0
	if not point.is_finite() or point.y != 0.0 or delta.length_squared() <= EPSILON * EPSILON or delta.length() > REACH + EPSILON: return {}
	var shape: Dictionary = Geometry.lane(_anchor, _anchor + delta.normalized() * REACH, RADIUS)
	return shape if Geometry.error(shape).is_empty() else {}

func _direction(shape: Dictionary) -> Vector3:
	return (shape["to"] - shape["from"]).normalized()

func _exchange_data(value: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: String in EXCHANGE_KEYS: result[key] = value[key]
	return result.duplicate(true)

func _progress(record: Dictionary, now: float) -> float:
	var keys: Array = {"warning": ["start_s", "lock_from_s"], "lock": ["lock_from_s", "active_from_s"], "active": ["active_from_s", "active_until_s"], "recovery": ["active_until_s", "recovery_until_s"]}.get(record.phase, [])
	return 0.0 if keys.is_empty() else clampf((now - float(record.exchange[keys[0]])) / (float(record.exchange[keys[1]]) - float(record.exchange[keys[0]])), 0.0, 1.0)

func cleanup() -> void:
	if _retired: return
	# Retirement may originate in any synchronous callback. Mark it first to
	# reject reentry; cancel authority before releasing references. Keep the
	# finite local tombstone until all currently executing calls return.
	_retired = true
	cancel("b05_ray_driver_removed")
	if is_instance_valid(_scheduler) and _scheduler.reservation_invalidated.is_connected(_on_invalidated): _scheduler.reservation_invalidated.disconnect(_on_invalidated)
	if is_instance_valid(_cue): _cue.clear()
	_configured = false
	_hero = null
	_scheduler = null
	_owner = null
	_bait = null
	_opening = null
	_owner_script = null
	_hero_script = null
	_context_provider = Callable()
	_presentation_guard = Callable()
	_proof = {}

func disarm() -> void:
	cleanup()

func _exit_tree() -> void:
	cleanup()

## No embedded Player/bait/whole actor copy: caller supplies complete native
## staged Player/bait and validates the full actor -> flat projection separately.
func snapshot_state(bindings: Dictionary) -> Dictionary:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty(): return {}
	_snapshot_busy = true
	var paired: Dictionary = _scheduler.snapshot_state(bindings)
	var player: Dictionary = _hero.snapshot_state()
	var bait: Dictionary = _bait.call("state")
	var flat: Dictionary = _source_flat()
	var saved: Dictionary = {"api_revision": API_REVISION, "schema_version": 1, "configuration": _encode_configuration(bindings), "clock_s": paired.get("clock_s"), "record": _encode_record(_record, bindings), "source": flat}
	last_snapshot_error = _scheduler.last_snapshot_error if paired.is_empty() else _plan_error(saved, bindings, paired, player, bait, true, true)
	_snapshot_busy = false
	return saved.duplicate(true) if last_snapshot_error.is_empty() else {}

func snapshot_error(saved: Dictionary, bindings: Dictionary, staged_scheduler: Dictionary, staged_player: Dictionary, staged_bait: Dictionary) -> String:
	var error: String = _snapshot_access_error()
	if not error.is_empty(): return error
	_snapshot_busy = true
	error = _scheduler.snapshot_error(staged_scheduler, bindings)
	if error.is_empty(): error = _plan_error(saved, bindings, staged_scheduler, staged_player, staged_bait)
	_snapshot_busy = false
	return error

func restore_state(saved: Dictionary, bindings: Dictionary, staged_player: Dictionary, staged_bait: Dictionary) -> bool:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty(): return false
	_snapshot_busy = true
	var paired: Dictionary = _scheduler.snapshot_state(bindings)
	last_snapshot_error = _scheduler.last_snapshot_error if paired.is_empty() else _plan_error(saved, bindings, paired, staged_player, staged_bait, true)
	if not last_snapshot_error.is_empty():
		_snapshot_busy = false
		return false
	_profile_id = saved.configuration.profile_id
	_role = saved.configuration.resolved_role.duplicate(true)
	_context.encounter_id = saved.configuration.encounter_id
	_context.world_revision = int(saved.configuration.world_revision)
	_context = _decode_context(saved.configuration.context, bindings)
	_record = _decode_record(saved.record, bindings)
	_proof = {} # Never reprove, resample, refresh cooldown or emit on restore.
	var blocked: bool = _cue.is_blocking_signals()
	_cue.set_block_signals(true)
	_cue.clear()
	if _record.status == "running": _cue.present(_record.exchange.geometry, _record.phase)
	_cue.set_block_signals(blocked)
	_snapshot_busy = false
	return true

func _snapshot_access_error() -> String:
	if not _native_bound() or not get_tree().paused: return "B05 ray snapshots require actual bound paused aggregate"
	if _transaction_depth > 0 or _snapshot_busy or _cancelling: return "Snapshot outside ray physics/cue/damage/cancel callbacks"
	return ""

func _encode_configuration(bindings: Dictionary) -> Dictionary:
	return {"source_id": _source_id, "anchor": Codec.vector3(_anchor), "profile_id": _profile_id, "encounter_id": _context.encounter_id, "world_revision": _context.world_revision, "raw_role": RAW_ROLE.duplicate(true), "timing_floors": TIMING_FLOORS.duplicate(true), "resolved_role": _role.duplicate(true), "reach": REACH, "radius": RADIUS, "context": _encode_context(_context, bindings)}

func _encode_record(record: Dictionary, bindings: Dictionary) -> Dictionary:
	var result: Dictionary = record.duplicate(true)
	result.direction = Codec.vector3(record.direction)
	result.context = {} if record.context.is_empty() else _encode_context(record.context, bindings)
	if not record.bait_sample.is_empty():
		result.bait_sample.point = Codec.vector3(record.bait_sample.point)
		result.bait_sample.initial_floor = Codec.vector3(record.bait_sample.initial_floor)
	if not record.sample.is_empty(): result.sample = {"position": Codec.vector3(record.sample.position), "clock_s": record.sample.clock_s}
	for key: String in record.presentation_witness: result.presentation_witness[key] = Codec.vector3(record.presentation_witness[key])
	for segment: Dictionary in result.deferred_paths:
		segment["from"] = Codec.vector3(segment["from"])
		segment["to"] = Codec.vector3(segment["to"])
	if not record.exchange.is_empty():
		result.exchange.source_position = Codec.vector3(record.exchange.source_position)
		result.exchange.opening_position = Codec.vector3(record.exchange.opening_position)
		result.exchange.geometry = {"kind": "lane", "from": Codec.vector3(record.exchange.geometry["from"]), "to": Codec.vector3(record.exchange.geometry["to"]), "radius": record.exchange.geometry.radius}
	return result

func _decode_record(value: Dictionary, bindings: Dictionary) -> Dictionary:
	var result: Dictionary = value.duplicate(true)
	result.direction = Codec.read_vector3(value.direction)
	result.context = {} if value.context.is_empty() else _decode_context(value.context, bindings)
	if not value.bait_sample.is_empty():
		result.bait_sample.point = Codec.read_vector3(value.bait_sample.point)
		result.bait_sample.initial_floor = Codec.read_vector3(value.bait_sample.initial_floor)
	if not value.sample.is_empty(): result.sample = {"position": Codec.read_vector3(value.sample.position), "clock_s": float(value.sample.clock_s)}
	for key: String in value.presentation_witness: result.presentation_witness[key] = Codec.read_vector3(value.presentation_witness[key])
	for segment: Dictionary in result.deferred_paths:
		segment["from"] = Codec.read_vector3(segment["from"])
		segment["to"] = Codec.read_vector3(segment["to"])
	if not value.exchange.is_empty():
		result.exchange.source_position = Codec.read_vector3(value.exchange.source_position)
		result.exchange.opening_position = Codec.read_vector3(value.exchange.opening_position)
		result.exchange.geometry = Geometry.lane(Codec.read_vector3(value.exchange.geometry["from"]), Codec.read_vector3(value.exchange.geometry["to"]), float(value.exchange.geometry.radius))
	return result

func _plan_error(saved: Dictionary, bindings: Dictionary, paired: Dictionary, player: Dictionary, bait: Dictionary, actual: bool = false, capture: bool = false) -> String:
	var error: String = Codec.value_error(saved)
	if error.is_empty(): error = Codec.keys_error(saved, ["api_revision", "schema_version", "configuration", "clock_s", "record", "source"])
	if not error.is_empty(): return error
	if saved.api_revision != API_REVISION or not Codec.is_integer(saved.schema_version, 1, 1) or not saved.clock_s is float or saved.clock_s != paired.get("clock_s") or not saved.configuration is Dictionary or not saved.record is Dictionary or not saved.source is Dictionary:
		return "Exact ray identity/configuration/clock/closed record required"
	if bindings.get("owners", {}).get(_source_id) != _owner or not bindings.get("world_root") is Node3D:
		return "Actual stable low-joint owner and shared world bindings required"
	error = _hero.snapshot_error(player)
	if error.is_empty(): error = String(_bait.call("snapshot_error", bait, player))
	if error.is_empty(): error = _source_flat_error(saved.source)
	if not error.is_empty(): return error
	if actual and (not _same_exact(_hero.snapshot_state(), player) or not _same_exact(_bait.call("state"), bait) or not _same_exact(_source_flat(), saved.source) or not _opening_matches(saved.source)):
		return "Restore actual Player/bait/whole source/composite cue before ray commit"
	if capture:
		# A hidden restore candidate may have a hidden ancestor. Require the
		# actual owned nodes/logical cue state, rather than granting a lost cue
		# authority merely by redrawing it on the next quiet restoration.
		if not visible or not _owner.visible or not _cue.visible or not _opening.visible: return "Captured source/required cues cannot be explicitly hidden"
		var cue: Dictionary = _cue.state()
		if saved.record.status == "running":
			if cue.phase != saved.record.phase or cue.geometry != _record.exchange.geometry or not cue.source_visible or cue.footprint_visible != (saved.record.phase != "recovery") or cue.active_fill_visible != (saved.record.phase == "active"): return "Capture the actual required ray cue before restoring any authority"
		elif cue.phase != "clear": return "Inactive ray cannot retain a presented danger cue"
	var cfg: Dictionary = saved.configuration
	if not Codec.keys_error(cfg, ["source_id", "anchor", "profile_id", "encounter_id", "world_revision", "raw_role", "timing_floors", "resolved_role", "reach", "radius", "context"]).is_empty() or cfg.source_id != _source_id or not Codec.is_vector3(cfg.anchor) or Codec.read_vector3(cfg.anchor) != _anchor or not cfg.profile_id is String or not _stable_id(cfg.encounter_id) or not Codec.is_integer(cfg.world_revision, 1) or not _same_exact(cfg.raw_role, RAW_ROLE) or not _same_exact(cfg.timing_floors, TIMING_FLOORS) or cfg.reach != REACH or cfg.radius != RADIUS or not cfg.context is Dictionary:
		return "Immutable authored low joint/geometry/raw role/epoch required"
	var resolved: Dictionary = Difficulty.new().resolve_role(RAW_ROLE, cfg.profile_id, TIMING_FLOORS)
	if resolved.is_empty() or not _same_exact(cfg.resolved_role, resolved): return "Resolve saved canonical profile independently of current preference"
	if not paired.encounter_id.is_empty() and (paired.encounter_id != cfg.encounter_id or paired.world_revision != cfg.world_revision or paired.profile.get("id") != cfg.profile_id): return "Paired scheduler epoch/profile differs"
	error = _saved_context_error(cfg.context, bindings)
	if not error.is_empty(): return error
	var authored: Dictionary = _encode_context(_context, bindings)
	for key: String in ["recognition_s", "attack_input_margin_s", "floor_ids"]:
		if not _same_exact(cfg.context[key], authored[key]): return "Recognition/margin/floor bindings must remain authored"
	error = _record_error(saved.record, saved.source, cfg, resolved, paired, bindings, player, bait, actual)
	if error.is_empty() and capture and not _proof.is_empty():
		for key: String in saved.record.presentation_witness:
			if not Geometry.finite_vector(_proof.get(key)) or not _same_exact(saved.record.presentation_witness[key], Codec.vector3(_proof[key])): return "Captured presentation witness differs from the accepted native proof"
	return error

func _record_error(record: Dictionary, source: Dictionary, cfg: Dictionary, role: Dictionary, paired: Dictionary, bindings: Dictionary, player: Dictionary, bait: Dictionary, actual: bool) -> String:
	var error: String = Codec.keys_error(record, RECORD_KEYS)
	if not error.is_empty(): return error
	if record.status not in ["idle", "running", "cancelled", "complete"] or record.phase not in ["clear", "warning", "lock", "active", "recovery"] or not Codec.is_integer(record.cycle, 0, int(paired.serial)) or not Codec.is_vector3(record.direction) or not record.bait_sample is Dictionary or not record.exchange is Dictionary or not record.context is Dictionary or not record.sample is Dictionary or not record.hit_consumed is bool or not record.last_cancel_reason is String or not record.presentation_witness is Dictionary or not record.deferred_paths is Array or record.deferred_paths.size() > MAX_DEFERRED_PATHS:
		return "Finite exact ray record/latches required"
	var owned: Dictionary = {}
	var cooldown: Dictionary = {}
	for reservation: Dictionary in paired.reservations:
		if reservation.source_id == _source_id:
			if not owned.is_empty(): return "One persistent owner cannot carry multiple ray reservations"
			owned = reservation
	for value: Dictionary in paired.cooldowns:
		if value.source_id == _source_id: cooldown = value
	if record.cycle == 0:
		return "" if record.status == "idle" and record.phase == "clear" and record.bait_sample.is_empty() and record.exchange.is_empty() and record.context.is_empty() and record.sample.is_empty() and not record.hit_consumed and record.last_cancel_reason.is_empty() and record.presentation_witness.is_empty() and record.deferred_paths.is_empty() and _same_exact(record.direction, Codec.vector3(Vector3.BACK)) and owned.is_empty() and cooldown.is_empty() else "Unstarted ray cannot invent authority/history"
	if record.status == "idle": return "Idle is the pristine zero-cycle state only"
	if not Codec.keys_error(record.exchange, EXCHANGE_KEYS).is_empty() or not Codec.keys_error(record.sample, ["position", "clock_s"]).is_empty(): return "Executed ray requires copied exchange and measured native sample"
	error = _saved_context_error(record.context, bindings)
	if error.is_empty(): error = _saved_bait_error(record.bait_sample, player, bait, record.status == "running")
	if not error.is_empty(): return error
	if record.context.recognition_s != cfg.context.recognition_s or record.context.attack_input_margin_s != cfg.context.attack_input_margin_s: return "Live cycle must retain authored recognition/input margin"
	var exchange: Dictionary = record.exchange
	if not exchange.id is String or not exchange.id.begins_with("threat-") or not exchange.id.substr(7).is_valid_int() or not Codec.is_integer(int(exchange.id.substr(7)), 1, int(paired.serial)) or exchange.id != "threat-%d" % int(exchange.id.substr(7)) or exchange.profile_id != cfg.profile_id or exchange.world_revision != cfg.world_revision or not Codec.is_vector3(exchange.source_position) or Codec.read_vector3(exchange.source_position) != _anchor or not _same_exact(exchange.source_position, exchange.opening_position) or not exchange.geometry is Dictionary or not Codec.keys_error(exchange.geometry, ["kind", "from", "to", "radius"]).is_empty() or exchange.geometry.kind != "lane" or exchange.geometry.radius != RADIUS or not Codec.is_vector3(exchange.geometry["from"]) or not Codec.is_vector3(exchange.geometry["to"]): return "Exact persistent low-joint capsule/opening/reservation identity required"
	var shape: Dictionary = Geometry.lane(Codec.read_vector3(exchange.geometry["from"]), Codec.read_vector3(exchange.geometry["to"]), float(exchange.geometry.radius))
	var expected: Dictionary = _lane(Codec.read_vector3(record.bait_sample.point))
	if expected.is_empty() or shape != expected or Codec.read_vector3(record.direction) != _direction(shape): return "Ray must remain the immutable full windup capsule through its sampled bait"
	var adapter: Variant = exchange.adapter
	if not adapter is Dictionary or not adapter.get("locked") is bool: return "Published tracking adapter required"
	var expected_adapter: Dictionary = {"kind": "tracking", "locked": adapter.locked, "reach": (shape["to"] as Vector3).distance_to(shape["from"]), "radius": RADIUS, "lock_s": role.lock_s, "active_s": role.active_s, "recovery_s": role.recovery_s, "attack_interval_s": role.attack_interval_s}
	if not _same_exact(adapter, expected_adapter): return "Adapter timing/reach/radius differs from native lease"
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not exchange[key] is float or not Codec.in_range(exchange[key], 0.0, float(paired.clock_s) + float(role.windup_s) + float(role.active_s) + float(role.recovery_s) + float(role.attack_interval_s)): return "Finite copied native deadlines required"
	var provisional_active: float = float(exchange.start_s) + float(role.windup_s)
	var provisional_lock: float = provisional_active - float(role.lock_s)
	var active: float = float(exchange.lock_from_s) + float(role.lock_s) if adapter.locked else provisional_active
	if exchange.active_from_s != active or exchange.active_until_s != active + float(role.active_s) or exchange.recovery_until_s != active + float(role.active_s) + float(role.recovery_s) or exchange.cooldown_until_s != active + float(role.attack_interval_s) or float(exchange.start_s) > float(paired.clock_s) or float(exchange.lock_from_s) < provisional_lock - EPSILON: return "Preserve complete returned full-lock/active/recovery/cooldown deadlines"
	if not adapter.locked and exchange.lock_from_s != provisional_lock: return "Unarmed warning cannot retime tentative lock"
	if adapter.locked and float(exchange.lock_from_s) >= provisional_active - EPSILON: return "Commit must precede original provisional activation"
	if not Codec.is_vector3(record.sample.position) or not record.sample.clock_s is float or not Codec.in_range(record.sample.clock_s, float(exchange.start_s), float(paired.clock_s)): return "Measured Hero sample required"
	if record.hit_consumed and (not adapter.locked or float(record.sample.clock_s) < active): return "No hit authority before actual armed active interval"
	if record.status == "running":
		var phase: String = "warning" if not adapter.locked else ("lock" if float(paired.clock_s) < active else ("active" if float(paired.clock_s) <= float(exchange.active_until_s) else "recovery"))
		if paired.encounter_id.is_empty() or owned.is_empty() or record.phase != phase or record.sample.clock_s != paired.clock_s or not record.last_cancel_reason.is_empty() or player.resources.dead or not source.armed or source.phase_pending or source.defeated: return "Running ray requires living actual staged native unit and complete paired lease"
		if not owned.get("adapter") is Dictionary or owned.adapter.get("kind") != "tracking": return "Ray requires a paired native tracking reservation"
		for key: String in EXCHANGE_KEYS:
			if not owned.has(key) or not _same_exact(exchange[key], owned[key]): return "Copied ray exchange must exactly equal paired native reservation"
		if Codec.read_vector3(record.sample.position) != Codec.read_vector3(player.motion.position): return "Running sample must equal complete staged Player position"
		if actual and Codec.read_vector3(record.sample.position) != _hero.global_position: return "Restore actual Player before measured ray commit"
	else:
		if not owned.is_empty() or record.phase != "clear" or not record.presentation_witness.is_empty() or not record.deferred_paths.is_empty(): return "Inactive ray cannot retain a danger reservation/view/path"
		if record.status == "cancelled" and record.last_cancel_reason.is_empty(): return "Visible cancellation requires reason"
		if record.status == "complete" and (not record.last_cancel_reason.is_empty() or float(paired.clock_s) <= float(exchange.recovery_until_s)): return "Completion retains full recovery and no cancellation reason"
	if source.defeated:
		if not cooldown.is_empty(): return "Actually defeated source releases native cooldown"
	elif paired.encounter_id == cfg.encounter_id and float(exchange.cooldown_until_s) > float(paired.clock_s) and (cooldown.is_empty() or cooldown.ready_s != exchange.cooldown_until_s): return "Cancellation/restore retains original source cooldown"
	if record.status == "running" and adapter.locked:
		if not Codec.keys_error(record.presentation_witness, ["landing", "attack_position"]).is_empty(): return "Armed ray needs accepted view witness only"
		for key: String in record.presentation_witness:
			if not Codec.is_vector3(record.presentation_witness[key]) or not _witness_supported(Codec.read_vector3(record.presentation_witness[key]), _decode_context(record.context, bindings)): return "Retained presentation witness must remain on authored supported floor"
	elif not record.presentation_witness.is_empty(): return "Unarmed/inactive ray cannot invent accepted presentation witness"
	var previous: Dictionary = {}
	for segment: Variant in record.deferred_paths:
		if not adapter.locked or record.hit_consumed or not segment is Dictionary or not Codec.keys_error(segment, ["from", "to", "start_s", "end_s"]).is_empty() or not Codec.is_vector3(segment["from"]) or not Codec.is_vector3(segment["to"]) or not segment.start_s is float or not segment.end_s is float or not Codec.in_range(segment.start_s, float(exchange.start_s), float(paired.clock_s)) or not Codec.in_range(segment.end_s, float(segment.start_s), float(paired.clock_s)) or float(segment.end_s) < active or float(segment.start_s) > float(exchange.active_until_s): return "Deferred paths must be measured, bounded, unconsumed active overlap"
		if not previous.is_empty() and (segment.start_s != previous.end_s or not _same_exact(segment["from"], previous["to"])): return "Deferred path cannot teleport or refresh time"
		previous = segment
	if not previous.is_empty() and (previous.end_s > record.sample.clock_s or (previous.end_s == record.sample.clock_s and not _same_exact(previous["to"], record.sample.position))): return "Pending path must precede/match actual saved sample"
	return ""

func _saved_bait_error(value: Dictionary, player: Dictionary, bait: Dictionary, running: bool) -> String:
	var error: String = Codec.keys_error(value, BAIT_KEYS)
	if not error.is_empty(): return error
	if value.boundary not in ["sentry-entry", "sentry-phase-2"] or not Codec.is_vector3(value.point) or Codec.read_vector3(value.point).y != 0.0 or not Codec.is_vector3(value.initial_floor) or Codec.read_vector3(value.initial_floor).y != 0.0 or not Codec.is_integer(value.initial_sequence, 0, int(player.world_actions.sequence)) or not Codec.is_integer(value.last_sequence, int(value.initial_sequence), int(player.world_actions.sequence)) or not Codec.is_integer(value.dash_sequence, 0, int(value.last_sequence)) or not value.player_clock_s is float or not Codec.in_range(value.player_clock_s, 0.0, float(player.world_actions.clock_s)):
		return "Immutable sampled bait must retain its own native boundary/cursor/clock"
	var same_boundary: bool = value.boundary == bait.boundary
	if same_boundary:
		if not _same_exact(value.initial_floor, bait.initial_floor) or value.initial_sequence != bait.initial_sequence or int(value.last_sequence) > int(bait.last_sequence): return "Same-boundary sample must preserve native boundary seed and consumed cursor"
	elif running or value.boundary != "sentry-entry" or bait.boundary != "sentry-phase-2" or int(value.last_sequence) > int(bait.initial_sequence):
		return "Only inactive earlier authored boundary history may precede the current bait"
	# Inspect every retained publication consumed at the sampled cursor before
	# the null branch. A fabricated null receipt cannot hide a known real dash.
	var first: int = int(player.world_actions.sequence) + 1
	var found: bool = false
	for receipt: Dictionary in player.world_actions.history:
		var sequence: int = int(receipt.sequence)
		first = mini(first, sequence)
		if sequence <= int(value.last_sequence) and float(receipt.completed_at_s) > float(value.player_clock_s): return "Sample cursor cannot consume publications later than its captured Player clock"
		if sequence > int(value.initial_sequence) and sequence <= int(value.last_sequence) and receipt.kind == "dash":
			if value.receipt == null or sequence > int(value.dash_sequence): return "Sample must retain the latest known completed dash at its windup cursor"
		if sequence == int(value.dash_sequence):
			found = true
			if value.receipt == null or not _same_exact(receipt, value.receipt): return "Sampled receipt differs from retained actual native Player history"
	if value.receipt == null:
		if value.dash_sequence != 0 or not _same_exact(value.point, value.initial_floor): return "Initial sampled bait cannot invent completed movement"
	else:
		if not value.receipt is Dictionary: return "Sampled bait needs exact canonical completed dash or null"
		error = PlayerScript.world_action_record_error(value.receipt, float(value.player_clock_s))
		if not error.is_empty(): return error
		if value.receipt.kind != "dash" or value.receipt.sequence != value.dash_sequence or int(value.dash_sequence) <= int(value.initial_sequence): return "Sampled bait requires its own boundary completed dash identity"
		var landing: Vector3 = Codec.read_vector3(value.receipt.landing)
		if not _same_exact(value.point, Codec.vector3(Vector3(landing.x, 0.0, landing.z))): return "Sampled point must equal its own completed physical landing"
		if int(value.dash_sequence) >= first and not found: return "Sampled receipt is missing inside retained native history"
	# History may roll off, but a current cache carrying this same dash identity
	# must still carry the exact same completed receipt. Later bait is allowed.
	if same_boundary:
		if bait.last_dash == null:
			if value.receipt != null: return "Same-boundary cache cannot lose an already sampled completed dash"
		elif int(bait.last_dash.sequence) <= int(value.last_sequence):
			if value.dash_sequence != bait.last_dash.sequence or not _same_exact(value.receipt, bait.last_dash) or not _same_exact(value.point, bait.landing): return "Same consumed dash identity must retain exact cached native receipt/landing"
	return ""

func _same_exact(left: Variant, right: Variant) -> bool:
	var encoded: String = ExactJson.stringify(left)
	return not encoded.is_empty() and encoded == ExactJson.stringify(right)

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

func _stable_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 128:
		return false
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9][A-Za-z0-9_:/.-]*$")
	var found: RegExMatch = pattern.search(value)
	return found != null and found.get_string() == value

func _reject(reason: String) -> bool:
	last_error = reason
	return false

func _denied(reason: String) -> Dictionary:
	last_error = reason
	return {"accepted": false, "reason": reason}


## Local JSON includes only the flat source projection; full actor and native
## scheduler are separately paired complete envelopes.
## Pure preflight validates saved samples internally, never against a fresh hero.
## Actual commit requires the restored player/actor/scheduler unit at this clock.

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

func _witness_supported(position: Vector3, context: Dictionary) -> bool:
	var feet_y: float = position.y + CinderThreatScheduler.CAPSULE_CENTER_Y - CinderThreatScheduler.CAPSULE_HEIGHT * 0.5
	for region: Dictionary in context.floor_regions:
		var support: CollisionShape3D = region.collision
		var top: float = support.global_position.y + (support.shape as BoxShape3D).size.y * 0.5
		if (region.safe_rect as Rect2).has_point(Vector2(position.x, position.z)) and absf(feet_y - top) <= CinderThreatScheduler.FEET_TOLERANCE:
			return true
	return false
