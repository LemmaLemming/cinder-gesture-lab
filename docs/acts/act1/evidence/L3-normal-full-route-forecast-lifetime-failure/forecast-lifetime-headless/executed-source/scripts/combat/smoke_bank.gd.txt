class_name CinderSmokeBank
extends Node3D
## Finite stationary environmental circle; no HP, enemy identity or emitter link.
## Contact earns grace only from complete supported native ticks, never a swept
## crossing estimate. The level owns current portrait containment and source art.

signal state_changed(bank_state: Dictionary)
signal tick_resolved(hero_id: String, cycle: int, result: Dictionary)

const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const BodySweep = preload("res://scripts/combat/body_sweep.gd")
const CueScript = preload("res://scripts/cues/threat_cue.gd")
const CueMesh = preload("res://scripts/cues/cue_mesh.gd")
const PlayerScript = preload("res://scripts/player.gd")
const API_REVISION: String = "smoke-bank-1"
const DEFAULT_RAW_ROLE: Dictionary = {"raw_damage": 2.0, "windup_s": 2.2, "lock_s": 1.1, "active_s": 3.0, "recovery_s": 1.9, "attack_interval_s": 2.0, "max_hp": 1.0, "move_speed": 0.0}
const DEFAULT_TIMING_FLOORS: Dictionary = {"windup_s": 2.2, "lock_s": 1.1, "recovery_s": 1.9}
const DEFAULT_CONTACT: Dictionary = {"grace_s": 0.4, "tick_s": 0.5, "max_opportunities": 5}
const RESPONSE_KEYS: Array[String] = ["encounter_id", "world_revision", "recognition_s", "attack_input_margin_s", "escape_directions", "return_directions", "floor_regions"]
const EXCHANGE_KEYS: Array[String] = ["id", "source_position", "geometry", "opening_position", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision"]
const MAX_TRACE: int = 1024
const SKIN: float = 0.005
const BAR_SIZE: Vector3 = Vector3(0.64, 0.06, 0.025)
const BAR_HEIGHT: float = 2.75
const OWNED_RENDERER_FIELDS: Array[String] = ["visible", "transform", "position", "rotation", "rotation_degrees", "quaternion", "basis", "scale", "global_transform", "global_position", "global_basis", "global_rotation", "global_rotation_degrees", "global_scale"]

var last_error: String = ""
var last_snapshot_error: String = ""
var _configuration: Dictionary = {}
var _scheduler: CinderThreatScheduler
var _hero: CinderPlayer
var _hero_id: String = ""
var _hero_guard: Dictionary = {}
var _cue: CinderThreatCue
var _indicator: Node3D
var _background: MeshInstance3D
var _progress: MeshInstance3D
var _bar_resources: Dictionary = {}
var _cue_guard: Dictionary = {}
var _world_root: Node3D
var _regions: Array = []
var _domain: Dictionary = {}
var _status: String = "idle"
var _phase: String = "clear"
var _cycle: int = 0
var _exchange: Dictionary = {}
var _encounter_id: String = ""
var _resolved: Dictionary = {}
var _sample: Dictionary = {}
var _trace: Array[Dictionary] = []
var _processed: int = 0
var _pending_stage: String = ""
var _contact_since: float = -1.0
var _processed_clock: float = -1.0
var _receipts: Array[Dictionary] = []
var _cancel_reason: String = ""
var _busy: bool = false
var _snapshot_busy: bool = false
var _cancelling: bool = false
var _publishing_cue: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 100
	_cue = CueScript.new()
	_cue.name = "ThreatCue"
	add_child(_cue)
	# First observer captures the actual newly published native resources before
	# any level observer runs. Those observers cannot replace them unnoticed.
	_cue.state_changed.connect(_remember_published_cue)
	_publishing_cue = true
	_remember_published_cue(_cue.state())
	_publishing_cue = false
	_indicator = Node3D.new()
	_indicator.name = "RequiredContactGrace"
	_indicator.top_level = true
	add_child(_indicator)
	_indicator.add_to_group("required_cues")
	_background = _bar("GraceBackground", Color(0.10, 0.09, 0.12, 1.0))
	_progress = _bar("GraceProgress", Color(1.0, 0.76, 0.35, 1.0))
	_progress.position.z = 0.017
	_bar_resources = {"background_node": _background, "progress_node": _progress, "background_mesh": _background.mesh, "progress_mesh": _progress.mesh, "background_material": _background.material_override, "progress_material": _progress.material_override}
	for key: String in ["background", "progress"]:
		var part: MeshInstance3D = _bar_resources[key + "_node"]
		_bar_resources[key + "_renderer_bytes"] = _property_bytes(part, OWNED_RENDERER_FIELDS)
		_bar_resources[key + "_material_bytes"] = _property_bytes(part.material_override, [])
		_bar_resources[key + "_mesh_bytes"] = _property_bytes(part.mesh, [])
	_update_indicator()


func configure(bank_id: String, circle: Dictionary, opening_position: Vector3, raw_role: Dictionary = DEFAULT_RAW_ROLE, timing_floors: Dictionary = DEFAULT_TIMING_FLOORS, contact: Dictionary = DEFAULT_CONTACT) -> bool:
	if _busy or _snapshot_busy or is_instance_valid(_scheduler): return _reject("Configure immutable smoke data before binding")
	if not _stable_id(bank_id) or not Geometry.error(circle).is_empty() or circle.get("kind") != "circle" or not Geometry.finite_vector(opening_position): return _reject("Stable bank ID, finite circle and actual stationary opening required")
	if not Codec.keys_error(raw_role, DEFAULT_RAW_ROLE.keys()).is_empty() or not Codec.keys_error(timing_floors, DEFAULT_TIMING_FLOORS.keys()).is_empty() or not Codec.keys_error(contact, DEFAULT_CONTACT.keys()).is_empty() or not Codec.value_error([raw_role, timing_floors, contact]).is_empty(): return _reject("Unsupported closed smoke configuration")
	if float(raw_role.get("move_speed", -1)) != 0.0 or not Codec.in_range(raw_role.active_s, 0.05, 4.0) or not Codec.in_range(contact.grace_s, 0.1, 2.0) or not Codec.in_range(contact.tick_s, 0.1, 2.0) or not Codec.is_integer(contact.max_opportunities, 1, 5): return _reject("Stationary smoke requires bounded active duration, grace, tick spacing and at most five opportunities")
	var difficulty = Difficulty.new()
	if difficulty.resolve_role(raw_role, "standard", timing_floors).is_empty(): return _reject(difficulty.last_error)
	var next := {"bank_id": bank_id, "geometry": Geometry.circle(circle.origin, float(circle.radius)), "opening_position": opening_position, "raw_role": raw_role.duplicate(true), "timing_floors": timing_floors.duplicate(true), "contact": contact.duplicate(true)}
	if not _configuration.is_empty() and not _same_exact(next, _configuration): return _reject("Configured smoke data is immutable")
	_configuration = next
	last_error = ""
	return true


func bind(scheduler: CinderThreatScheduler, heroes: Dictionary) -> bool:
	if _busy or _snapshot_busy or _configuration.is_empty() or not is_inside_tree() or not is_node_ready() or heroes.size() != 1: return _reject("Bind a ready configured bank to exactly one stable shared Hero outside callbacks")
	var id: Variant = heroes.keys()[0]
	var candidate: Variant = heroes[id]
	if not is_instance_valid(candidate): return _reject("Actual live shared Hero required")
	var hero: CinderPlayer = candidate as CinderPlayer
	if not _stable_id(id) or not is_instance_valid(scheduler) or not scheduler.is_inside_tree() or scheduler.is_queued_for_deletion() or scheduler.get_world_3d() != get_world_3d() or scheduler.process_physics_priority >= process_physics_priority or not is_instance_valid(hero) or hero.get_script() != PlayerScript or not hero.is_inside_tree() or hero.is_queued_for_deletion() or hero.get_world_3d() != get_world_3d() or hero.process_physics_priority >= process_physics_priority: return _reject("Actual same-world earlier-physics Scheduler and Hero required")
	var body: Dictionary = BodySweep.source_description(hero)
	if body.has("error") or not (body.collision as CollisionShape3D).shape is CapsuleShape3D or (body.collision as CollisionShape3D).position != Vector3(0, CinderThreatScheduler.CAPSULE_CENTER_Y, 0) or not is_equal_approx(float(body.height), CinderThreatScheduler.CAPSULE_HEIGHT) or body.footprint_half != Vector2.ONE * CinderThreatScheduler.CAPSULE_RADIUS: return _reject("Actual fixed shared Hero capsule required")
	if is_instance_valid(_scheduler):
		return _reject("Stable bindings cannot be replaced") if _scheduler != scheduler or _hero != hero or _hero_id != id else true
	_scheduler = scheduler
	_hero = hero
	_hero_id = id
	_hero_guard = {"collision": body.collision, "shape": (body.collision as CollisionShape3D).shape, "transform": (body.collision as CollisionShape3D).transform, "height": ((body.collision as CollisionShape3D).shape as CapsuleShape3D).height, "radius": ((body.collision as CollisionShape3D).shape as CapsuleShape3D).radius, "layer": hero.collision_layer, "mask": hero.collision_mask}
	_scheduler.reservation_invalidated.connect(_on_invalidated)
	last_error = ""
	return true


func preview_start(hero_id: String, response_context: Dictionary, opening_position: Variant = null) -> Dictionary:
	var plan: Dictionary = _preparation(hero_id, response_context, opening_position)
	if not plan.get("error", "").is_empty(): return {"accepted": false, "reason": plan.error}
	return _prospective(plan, response_context)


func start(hero_id: String, response_context: Dictionary, opening_position: Variant = null, preview: Dictionary = {}) -> Dictionary:
	last_error = ""
	var plan: Dictionary = _preparation(hero_id, response_context, opening_position)
	if not plan.get("error", "").is_empty(): return _denied(plan.error)
	var current: Dictionary = _prospective(plan, response_context)
	if not current.get("accepted", false): return _denied(String(current.get("reason", "Fresh stationary proof rejected")))
	_busy = true
	var answer: Dictionary = _scheduler.request_attack(self, plan.threat, plan.response, current if preview.is_empty() else preview)
	if answer.get("accepted", false):
		var reservation: Dictionary = _live_reservation(String(answer.reservation_id))
		if reservation.is_empty():
			_scheduler.cancel(String(answer.reservation_id), "smoke_missing_lease")
			answer = _denied("Accepted smoke lost its real reservation")
		else:
			_world_root = plan.world_root
			_regions = response_context.floor_regions.duplicate()
			_domain = plan.domain.duplicate(true)
			_resolved = plan.threat.role.duplicate(true)
			_exchange = _exchange_data(reservation)
			_encounter_id = response_context.encounter_id
			_cycle += 1
			_sample = _actual_sample()
			_trace.clear()
			_processed = 0
			_pending_stage = ""
			_contact_since = -1.0
			_processed_clock = -1.0
			_receipts.clear()
			_cancel_reason = ""
			_status = "running"
			_set_phase("warning")
			if _status == "running" and not _boundary_ready(false): answer = _denied("Smoke callback invalidated its new source/cue lease")
	else: last_error = String(answer.get("reason", "Admission rejected"))
	_busy = false
	return answer.duplicate(true)


func _prospective(plan: Dictionary, context: Dictionary) -> Dictionary:
	var result: Dictionary = _scheduler.preview_stationary(self, plan.threat, plan.response)
	if result.get("accepted", false) and result.guard.encounter_id != context.encounter_id: return {"accepted": false, "reason": "Authored smoke epoch differs from actual Scheduler encounter"}
	return result


func _preparation(hero_id: String, context: Dictionary, opening_position: Variant) -> Dictionary:
	if _busy or _snapshot_busy or _cancelling or not _live_bindings() or _status == "running" or get_tree().paused or not is_visible_in_tree() or not _cue.is_visible_in_tree() or _cycle >= Codec.MAX_SAFE_INTEGER: return {"error": "Idle live unpaused smoke outside callbacks required"}
	if hero_id != _hero_id or _hero.dead or not Codec.keys_error(context, RESPONSE_KEYS).is_empty() or not _stable_id(context.get("encounter_id")) or not context.get("floor_regions") is Array: return {"error": "Actual living Hero and authored epoch/floor/response candidates required"}
	if global_position != _configuration.geometry.origin or not global_basis.is_equal_approx(Basis.IDENTITY) or (opening_position != null and not Geometry.finite_vector(opening_position)): return {"error": "Actual fixed upright source and finite opening required"}
	var native_error: String = _native_error()
	if not native_error.is_empty(): return {"error": native_error}
	var world: Node3D = _common_root(context.floor_regions)
	var domain: Dictionary = _domain_plan(world, context.floor_regions)
	if domain.has("error"): return domain
	var difficulty = Difficulty.new()
	var role: Dictionary = difficulty.resolve_role(_configuration.raw_role, String(_scheduler.encounter_profile().get("id", "")), _configuration.timing_floors)
	if role.is_empty(): return {"error": difficulty.last_error}
	if ceili(float(role.active_s) * Engine.physics_ticks_per_second) + 2 > MAX_TRACE: return {"error": "Resolved smoke exceeds its finite native trace budget"}
	var response: Dictionary = _hero.get_threat_response_state()
	for key: String in RESPONSE_KEYS:
		if key != "encounter_id": response[key] = context[key]
	response["world_root"] = world
	var opening: Vector3 = _configuration.opening_position if opening_position == null else opening_position
	return {"error": "", "world_root": world, "domain": domain, "response": response, "threat": {"role": role, "geometry": _configuration.geometry.duplicate(true), "source_stationary": true, "opening_stationary": true, "opening_position": opening, "cooldown_remaining_s": 0.0}}


func _physics_process(delta: float) -> void:
	if _status != "running" or _busy or get_tree().paused: return
	_busy = true
	if _boundary_ready():
		var current: Dictionary = _actual_sample()
		var error: String = _sample_error(_sample, current, delta)
		if not error.is_empty(): cancel(error)
		else:
			var segment := {"from": _sample.position, "to": current.position, "start_s": _sample.clock_s, "end_s": current.clock_s, "actor_from_s": _sample.actor_clock_s, "actor_to_s": current.actor_clock_s, "from_grounded": _sample.grounded, "to_grounded": current.grounded, "alive": _sample.alive and current.alive, "horizontal_collision": _horizontal_collision(), "processed_at_s": null}
			_sample = current
			if float(segment.end_s) >= float(_exchange.active_from_s) and float(segment.start_s) <= float(_exchange.active_until_s):
				if _trace.size() >= MAX_TRACE: cancel("smoke_trace_budget_exceeded")
				else: _trace.append(segment)
			if _status == "running":
				if current.clock_s > float(_exchange.active_until_s) or not current.alive: _contact_since = -1.0
				var previous_phase: String = _phase
				_set_phase(_phase_at(current.clock_s))
				if get_tree().paused and _phase != previous_phase and _trace.size() - _processed == 1: _pending_stage = "phase"
				if _boundary_ready():
					_deliver_pending_notification()
					if _boundary_ready():
						while _processed < _trace.size():
							_trace[_processed].processed_at_s = current.clock_s
							_apply_segment(_trace[_processed])
							_processed += 1
							_update_indicator()
							# No notifying/pruning call separates earned exposure from
							# this tick's mandatory opportunity commitment.
							_consume_due()
							if not _boundary_ready(): break
						if _processed == _trace.size(): _pending_stage = ""
						if current.clock_s > float(_exchange.active_until_s) or not current.alive: _contact_since = -1.0
						_update_indicator()
	_busy = false


func _actual_sample() -> Dictionary:
	var response: Dictionary = _hero.get_threat_response_state()
	return {"position": _hero.global_position, "clock_s": _scheduler.get_clock(), "actor_clock_s": _hero.get_world_action_clock(), "grounded": response.motion.grounded, "alive": not _hero.dead}


func _sample_error(previous: Dictionary, current: Dictionary, delta: float) -> String:
	if not is_finite(delta) or delta <= 0.0 or delta > 0.05 or Engine.physics_ticks_per_second < 20 or Engine.physics_ticks_per_second > 240 or float(previous.clock_s) + delta != float(current.clock_s): return "smoke_noncontiguous_native_tick"
	if current.alive and float(previous.actor_clock_s) + delta != float(current.actor_clock_s): return "smoke_actor_clock_discontinuity"
	if not current.alive and float(current.actor_clock_s) < float(previous.actor_clock_s): return "smoke_dead_actor_clock_reversal"
	if not current.position.is_finite() or absf(current.position.x) > 512.0 or absf(current.position.z) > 512.0: return "smoke_unsupported_actor_position"
	var descriptor: Dictionary = BodySweep.source_description(_hero)
	if descriptor.has("error") or not is_equal_approx(float(descriptor.height), CinderThreatScheduler.CAPSULE_HEIGHT) or descriptor.footprint_half != Vector2.ONE * CinderThreatScheduler.CAPSULE_RADIUS: return "smoke_unsupported_hero_body"
	# In the supported clean contact domain a native tick cannot teleport. Actual
	# dash/knockback velocity is public; outside motion gets the same conservative
	# finite displacement bound without pretending to reconstruct curved slides.
	var response: Dictionary = _hero.get_threat_response_state()
	var maximum: float = maxf(float(response.stats.dash_speed), Vector2(_hero.velocity.x, _hero.velocity.z).length()) * delta + BodySweep.position_rounding_bound(previous.position, current.position) + 0.01
	if Vector2(current.position.x - previous.position.x, current.position.z - previous.position.z).length() > maximum: return "smoke_discontinuous_actor_position"
	return ""


func _horizontal_collision() -> bool:
	for index: int in range(_hero.get_slide_collision_count()):
		var normal: Vector3 = _hero.get_slide_collision(index).get_normal()
		if Vector2(normal.x, normal.z).length_squared() > 0.000001: return true
	return false


func _full_contact(segment: Dictionary) -> bool:
	return segment.alive and segment.from_grounded and segment.to_grounded and not segment.horizontal_collision and float(segment.start_s) >= float(_exchange.active_from_s) and float(segment.end_s) <= float(_exchange.active_until_s) and _inside(segment.from) and _inside(segment.to)


func _inside(point: Vector3) -> bool:
	var origin: Vector3 = _configuration.geometry.origin
	var radius: float = float(_configuration.geometry.radius) + CinderThreatScheduler.CAPSULE_RADIUS
	return Vector2(point.x - origin.x, point.z - origin.z).length_squared() < radius * radius and absf(point.y - origin.y) <= 0.02


func _apply_segment(segment: Dictionary) -> void:
	if _full_contact(segment):
		if _contact_since < 0.0 or _processed_clock != float(segment.start_s): _contact_since = float(segment.start_s)
	else: _contact_since = -1.0
	_processed_clock = float(segment.end_s)


func _eligible_clock() -> float:
	if _contact_since < 0.0 or _receipts.size() >= int(_configuration.contact.max_opportunities): return INF
	var eligible: float = _contact_since + float(_configuration.contact.grace_s)
	if not _receipts.is_empty(): eligible = maxf(eligible, float(_receipts[-1].consumed_s) + float(_configuration.contact.tick_s))
	return eligible


func _consume_due() -> void:
	var now: float = _scheduler.get_clock()
	var eligible: float = _eligible_clock()
	if now > float(_exchange.active_until_s) or _processed == 0 or not _full_contact(_trace[_processed - 1]) or float(_trace[_processed - 1].end_s) < eligible or (not _receipts.is_empty() and float(_receipts[-1].consumed_s) == now): return
	var native_error: String = _native_error()
	if not native_error.is_empty():
		cancel(native_error)
		return
	# Commit the opportunity and original eligibility before entering the actor.
	# Never iterate overdue opportunities: one actual native tick can consume one.
	var receipt := {"index": _receipts.size() + 1, "trace_index": _processed - 1, "eligible_s": eligible, "consumed_s": now, "stage": "damage", "result": {}}
	_receipts.append(receipt)
	var before: float = _hero.hp
	var contact: bool = not _hero.dead and _sample.alive and _sample.grounded and _hero.global_position == _sample.position and _inside(_hero.global_position)
	if contact: _hero.take_damage(float(_resolved.damage), Vector3.ZERO)
	receipt.result = {"opportunity_consumed": true, "contact": contact, "damage_attempted": contact, "accepted": _hero.hp < before, "raw_damage": float(_resolved.damage), "hp_damage": maxf(before - _hero.hp, 0.0), "impulse": [0.0, 0.0, 0.0]}
	receipt.stage = "notify"
	# Verify the existing native presentation immediately after actor callbacks,
	# before updating any legitimately changed death/progress pose.
	if _status == "running":
		native_error = _native_error()
		if not native_error.is_empty(): cancel(native_error)
	_sample.alive = not _hero.dead
	if _hero.dead: _contact_since = -1.0
	_update_indicator()
	if _status != "running": receipt.stage = "abandoned"
	elif get_tree().paused and _trace.size() - _processed == 1: _pending_stage = "notify"
	elif _boundary_ready(): _deliver_pending_notification()


func _deliver_pending_notification() -> void:
	if _receipts.is_empty() or _receipts[-1].stage != "notify" or not _boundary_ready(): return
	var receipt: Dictionary = _receipts[-1]
	receipt.stage = "done"
	var result: Dictionary = receipt.result.duplicate(true)
	result["index"] = receipt.index
	result["eligible_s"] = receipt.eligible_s
	result["consumed_s"] = receipt.consumed_s
	tick_resolved.emit(_hero_id, _cycle, result)
	if get_tree().paused and _trace.size() - _processed == 1: _pending_stage = "notification"
	if _settle_actor_callback(): _boundary_ready()


func cancel(reason: String = "smoke_cancelled") -> bool:
	if _snapshot_busy or _cancelling: return false
	_cancelling = true
	_status = "cancelled" if _cycle > 0 else "idle"
	_contact_since = -1.0
	# Cancellation cannot leave a resumable, unearned contact suffix behind.
	_trace.resize(_processed)
	_pending_stage = ""
	_cancel_reason = reason
	if not _receipts.is_empty() and _receipts[-1].stage == "notify": _receipts[-1].stage = "abandoned"
	if not _exchange.is_empty() and is_instance_valid(_scheduler): _scheduler.cancel(String(_exchange.id), reason)
	_set_phase("clear")
	_update_indicator()
	_cancelling = false
	return true


func _boundary_ready(check_pause: bool = true) -> bool:
	if _status != "running": return false
	if not _live_bindings() or not is_visible_in_tree() or global_position != _configuration.geometry.origin or not global_basis.is_equal_approx(Basis.IDENTITY):
		cancel("smoke_required_source_unavailable")
		return false
	var error: String = _native_error()
	if not error.is_empty():
		cancel(error)
		return false
	var domain: Dictionary = _domain_plan(_world_root, _regions)
	if domain.has("error") or not _same_exact(domain, _domain):
		cancel("smoke_collision_or_floor_changed")
		return false
	if check_pause and get_tree().paused: return false
	var reservation: Dictionary = _live_reservation(String(_exchange.id))
	if reservation.is_empty():
		if _scheduler.get_clock() > float(_exchange.recovery_until_s):
			_status = "complete"
			_contact_since = -1.0
			_set_phase("clear")
			_update_indicator()
		else: cancel("smoke_reservation_missing")
		return false
	if not _same_exact(_exchange_data(reservation), _exchange):
		cancel("smoke_committed_exchange_changed")
		return false
	return not get_tree().paused if check_pause else true


func _set_phase(next: String, notify: bool = true) -> void:
	var changed: bool = _phase != next
	var original_indicator: Dictionary = _indicator_owned_pose()
	_phase = next
	_publishing_cue = true
	if not _cue_parts_ready():
		if is_instance_valid(_cue): _cue.visible = false
	elif next == "clear": _cue.clear()
	else: _cue.present(_configuration.geometry, next)
	_publishing_cue = false
	# Cue rejects nested clear while notifying. An actual cancel observer can
	# therefore leave this final owner clear until the outer present returns.
	if _phase == "clear" and _cue_parts_ready():
		_publishing_cue = true
		_cue.clear()
		_publishing_cue = false
	if _status == "running":
		var error: String = _native_error(false)
		if error.is_empty() and _indicator_owned_pose() != original_indicator: error = "smoke_required_grace_callback_pose_changed"
		if not error.is_empty():
			cancel(error)
			return
		if not _settle_actor_sample(): return
	_update_indicator()
	if changed and notify and _phase == next:
		state_changed.emit(state())
		if _status == "running" and _settle_actor_callback(): _boundary_ready(false)


func _settle_actor_callback() -> bool:
	if _status != "running": return false
	if not _live_bindings():
		cancel("smoke_required_source_or_hero_unavailable_after_callback")
		return false
	# Required native parts must survive unchanged before any legitimate actor
	# death can hide/refresh the owned indicator. This cannot heal a hidden bar.
	var error: String = _native_error()
	if not error.is_empty():
		cancel(error)
		return false
	if not _settle_actor_sample(): return false
	_update_indicator()
	return true


func _settle_actor_sample() -> bool:
	if _sample.is_empty() or not is_instance_valid(_hero) or _hero.is_queued_for_deletion() or _hero.global_position != _sample.position or _hero.get_world_action_clock() != float(_sample.actor_clock_s) or _hero.get_threat_response_state().motion.grounded != _sample.grounded:
		cancel("smoke_callback_changed_actual_native_sample")
		return false
	_sample.alive = not _hero.dead
	if not _sample.alive: _contact_since = -1.0
	return true


func _remember_published_cue(_value: Dictionary) -> void:
	if not _publishing_cue: return
	_cue_guard.clear()
	for name: String in ["RequiredFootprintOutline", "RequiredFootprintFill", "RequiredSourceMarker"]:
		var part: MeshInstance3D = _cue.get_node_or_null(name) as MeshInstance3D
		if is_instance_valid(part):
			var expected: ArrayMesh = null if _phase == "clear" else (CueMesh.source_mesh(_phase) if name == "RequiredSourceMarker" else CueMesh.geometry_mesh(_configuration.geometry, name == "RequiredFootprintFill"))
			_cue_guard[name] = {"node": part, "mesh": part.mesh, "material": part.material_override, "mesh_bytes": _mesh_bytes(part.mesh), "material_bytes": _property_bytes(part.material_override, ["albedo_color"]), "renderer_bytes": _property_bytes(part, ["mesh", "material_override", "visible", "transform", "position", "rotation", "rotation_degrees", "quaternion", "basis", "scale", "global_transform", "global_position", "global_basis", "global_rotation", "global_rotation_degrees", "global_scale", "name", "owner", "unique_name_in_owner", "process_mode", "process_priority", "process_physics_priority"]), "canonical": part.mesh == null if _phase == "clear" else _same_mesh(part.mesh, expected)}


func get_cue() -> CinderThreatCue: return _cue


func get_grace_indicator() -> Node3D: return _indicator


func get_required_camera_points() -> Array:
	var points: Array = []
	if not _configuration.is_empty() and _status == "running":
		var origin: Vector3 = _configuration.geometry.origin
		var radius: float = _configuration.geometry.radius
		for x: float in [-radius, radius]:
			for z: float in [-radius, radius]: points.append(origin + Vector3(x, 0.025, z))
		points.append(global_position + Vector3.UP * 0.10)
		if _indicator_visible():
			for x: float in [-BAR_SIZE.x * 0.5, BAR_SIZE.x * 0.5]:
				for y: float in [-BAR_SIZE.y * 0.5, BAR_SIZE.y * 0.5]: points.append(_indicator.global_position + Vector3(x, y, 0.03))
	return points


func state() -> Dictionary:
	var eligible: float = _eligible_clock() if not _configuration.is_empty() else INF
	return {"api_revision": API_REVISION, "bank_id": _configuration.get("bank_id", ""), "status": _status, "phase": _phase, "cycle": _cycle, "reservation_id": _exchange.get("id", "") if _status == "running" else "", "geometry": _configuration.get("geometry", {}).duplicate(true), "exchange": _exchange.duplicate(true), "resolved_role": _resolved.duplicate(true), "contact_since_s": null if _contact_since < 0.0 else _contact_since, "grace_progress": _grace_progress(), "next_eligible_s": eligible if is_finite(eligible) else null, "opportunities_consumed": _receipts.size(), "receipts": _receipts.duplicate(true), "pending_samples": _trace.size() - _processed, "last_cancel_reason": _cancel_reason}


func _indicator_visible() -> bool:
	return _status == "running" and _phase == "active" and _contact_since >= 0.0 and _sample.get("alive", false)


func _grace_progress() -> float:
	return clampf((_processed_clock - _contact_since) / float(_configuration.contact.grace_s), 0.0, 1.0) if _indicator_visible() else 0.0


func _update_indicator() -> void:
	if not is_instance_valid(_indicator): return
	# Parent exit can cancel after native children have already left the tree.
	# Retire display visibility without reading a removed global transform.
	if not is_inside_tree() or not _indicator.is_inside_tree():
		_indicator.visible = false
		return
	if not is_instance_valid(_background) or not is_instance_valid(_progress):
		_indicator.visible = false
		return
	_indicator.global_transform = Transform3D(Basis.IDENTITY, (_sample.get("position", global_position) as Vector3) + Vector3.UP * BAR_HEIGHT)
	var progress: float = _grace_progress()
	_background.visible = _indicator_visible()
	_progress.visible = _indicator_visible() and progress > 0.0
	_progress.scale = Vector3(maxf(progress, 0.001), 1.0, 1.0)
	_progress.position = Vector3(-BAR_SIZE.x * (1.0 - maxf(progress, 0.001)) * 0.5, 0.0, 0.017)


func _bar(part_name: String, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = BAR_SIZE
	part.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	part.material_override = material
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_indicator.add_child(part)
	return part


func _indicator_owned_pose() -> Dictionary:
	if not is_instance_valid(_indicator) or not is_instance_valid(_background) or not is_instance_valid(_progress): return {}
	if not _indicator.is_inside_tree(): return {}
	return {"root": _indicator.global_transform, "background": _background.transform, "background_visible": _background.visible, "progress": _progress.transform, "progress_visible": _progress.visible}


func _indicator_error(check_pose: bool = true) -> String:
	if not is_instance_valid(_indicator) or _indicator.is_queued_for_deletion() or _indicator.get_parent() != self or not _indicator.top_level or not _indicator.is_visible_in_tree(): return "smoke_required_grace_indicator_unavailable"
	for key: String in ["background", "progress"]:
		var cached: Variant = _bar_resources.get(key + "_node")
		if not is_instance_valid(cached): return "smoke_required_grace_part_changed"
		var part: MeshInstance3D = cached as MeshInstance3D
		if not is_instance_valid(part) or part.is_queued_for_deletion() or part.get_parent() != _indicator or part.mesh != _bar_resources.get(key + "_mesh") or part.material_override != _bar_resources.get(key + "_material") or not part.mesh is BoxMesh or (part.mesh as BoxMesh).size != BAR_SIZE: return "smoke_required_grace_part_changed"
		if _property_bytes(part, OWNED_RENDERER_FIELDS) != _bar_resources[key + "_renderer_bytes"] or _property_bytes(part.material_override, []) != _bar_resources[key + "_material_bytes"] or _property_bytes(part.mesh, []) != _bar_resources[key + "_mesh_bytes"]: return "smoke_required_grace_native_policy_changed"
		var material: StandardMaterial3D = part.material_override as StandardMaterial3D
		var color: Color = Color(0.10, 0.09, 0.12, 1.0) if key == "background" else Color(1.0, 0.76, 0.35, 1.0)
		if material == null or material.albedo_color != color or material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.no_depth_test or material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED or part.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: return "smoke_required_grace_material_changed"
	if not check_pose: return ""
	var progress: float = maxf(_grace_progress(), 0.001)
	var expected: Vector3 = (_sample.get("position", global_position) as Vector3) + Vector3.UP * BAR_HEIGHT
	if _indicator.global_transform != Transform3D(Basis.IDENTITY, expected) or _background.transform != Transform3D.IDENTITY or _background.visible != _indicator_visible() or _progress.visible != (_indicator_visible() and _grace_progress() > 0.0) or _progress.transform != Transform3D(Basis.IDENTITY.scaled(Vector3(progress, 1, 1)), Vector3(-BAR_SIZE.x * (1 - progress) * 0.5, 0, 0.017)): return "smoke_required_grace_pose_changed"
	return ""


func _native_error(check_indicator_pose: bool = true) -> String:
	var body_error: String = _hero_body_error()
	if not body_error.is_empty(): return body_error
	var error: String = _indicator_error(check_indicator_pose)
	if not error.is_empty(): return error
	if not is_instance_valid(_cue) or not _cue.is_visible_in_tree() or _cue.is_queued_for_deletion() or _cue.get_parent() != self: return "smoke_required_cue_unavailable"
	var value: Dictionary = _cue.state()
	if value.phase != _phase: return "smoke_required_cue_phase_changed"
	if _phase != "clear" and (value.geometry != _configuration.geometry or value.source_position != global_position or _cue.global_transform != Transform3D(Basis.IDENTITY, global_position)): return "smoke_required_cue_geometry_changed"
	for name: String in ["RequiredFootprintOutline", "RequiredFootprintFill", "RequiredSourceMarker"]:
		var guard: Dictionary = _cue_guard.get(name, {})
		var part: MeshInstance3D = _cue.get_node_or_null(name) as MeshInstance3D
		if guard.is_empty() or not is_instance_valid(part) or part.is_queued_for_deletion() or part != guard.node or part.get_parent() != _cue or part.mesh != guard.mesh or part.material_override != guard.material: return "smoke_required_cue_resource_changed"
		if not guard.canonical or _mesh_bytes(part.mesh) != guard.mesh_bytes or _property_bytes(part.material_override, ["albedo_color"]) != guard.material_bytes or _property_bytes(part, ["mesh", "material_override", "visible", "transform", "position", "rotation", "rotation_degrees", "quaternion", "basis", "scale", "global_transform", "global_position", "global_basis", "global_rotation", "global_rotation_degrees", "global_scale", "name", "owner", "unique_name_in_owner", "process_mode", "process_priority", "process_physics_priority"]) != guard.renderer_bytes: return "smoke_required_cue_buffers_or_policy_changed"
		if _phase == "clear":
			if part.visible or part.mesh != null: return "smoke_clear_cue_changed"
			continue
		var height: float = 0.029 if name == "RequiredSourceMarker" else (0.021 if name == "RequiredFootprintFill" else 0.025)
		var visible_part: bool = name == "RequiredSourceMarker" or (_phase != "recovery" and (name != "RequiredFootprintFill" or _phase == "active"))
		if part.transform != Transform3D(Basis.IDENTITY, Vector3.UP * height) or part.visible != visible_part or (visible_part and not part.is_visible_in_tree()): return "smoke_required_cue_pose_changed"
		var material: StandardMaterial3D = part.material_override as StandardMaterial3D
		var color: Color = {"warning": Color(1.0, 0.90, 0.63, 0.95), "lock": Color(1.0, 0.76, 0.35, 1.0), "active": Color(1.0, 0.43, 0.26, 1.0), "recovery": Color(0.77, 0.88, 0.90, 0.70)}[_phase]
		if name == "RequiredFootprintFill": color.a = 0.22
		if material == null or material.albedo_color != color or material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA or material.cull_mode != BaseMaterial3D.CULL_DISABLED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.no_depth_test or part.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: return "smoke_required_cue_material_changed"
	return ""


func _hero_body_error() -> String:
	if not is_instance_valid(_hero): return "smoke_actual_hero_unavailable"
	var description: Dictionary = BodySweep.source_description(_hero)
	if description.has("error"): return "smoke_unsupported_actual_hero_body"
	var collision: CollisionShape3D = description.collision
	if collision != _hero_guard.get("collision") or collision.shape != _hero_guard.get("shape") or collision.transform != _hero_guard.get("transform") or _hero.collision_layer != _hero_guard.get("layer") or _hero.collision_mask != _hero_guard.get("mask") or not collision.shape is CapsuleShape3D or not is_equal_approx(float(description.height), CinderThreatScheduler.CAPSULE_HEIGHT) or description.footprint_half != Vector2.ONE * CinderThreatScheduler.CAPSULE_RADIUS: return "smoke_actual_hero_collision_binding_changed"
	var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D
	if capsule.height != _hero_guard.height or capsule.radius != _hero_guard.radius: return "smoke_actual_bound_hero_dimensions_changed"
	return ""


func _cue_parts_ready() -> bool:
	if not is_instance_valid(_cue): return false
	for name: String in ["RequiredFootprintOutline", "RequiredFootprintFill", "RequiredSourceMarker"]:
		var part: MeshInstance3D = _cue.get_node_or_null(name) as MeshInstance3D
		if not is_instance_valid(part) or part.is_queued_for_deletion() or part.get_parent() != _cue: return false
	return true


func _same_mesh(actual: Mesh, expected: ArrayMesh) -> bool:
	if not actual is ArrayMesh or actual.get_surface_count() != expected.get_surface_count(): return false
	var mesh: ArrayMesh = actual as ArrayMesh
	if mesh.shadow_mesh != null or mesh.get_blend_shape_count() != 0: return false
	for index: int in range(mesh.get_surface_count()):
		if mesh.surface_get_material(index) != null: return false
	# The installed native _surfaces getter reads actual RenderingServer buffers,
	# including LOD/index/attribute edits, rather than trusting cached arrays.
	return var_to_bytes([mesh.custom_aabb, mesh.blend_shape_mode, mesh.get("_surfaces")]) == var_to_bytes([expected.custom_aabb, expected.blend_shape_mode, expected.get("_surfaces")])


func _mesh_bytes(mesh: Mesh) -> PackedByteArray:
	if mesh == null: return var_to_bytes(null)
	if not mesh is ArrayMesh: return PackedByteArray()
	var array: ArrayMesh = mesh as ArrayMesh
	return var_to_bytes([array.get_surface_count(), array.custom_aabb, array.blend_shape_mode, array.get("_surfaces"), array.shadow_mesh.get_instance_id() if array.shadow_mesh != null else 0, array.get_blend_shape_count()])


func _property_bytes(object: Object, excluded: Array) -> PackedByteArray:
	if object == null: return PackedByteArray()
	var values: Array = []
	for info: Dictionary in object.get_property_list():
		var key: String = String(info.name)
		if (int(info.usage) & PROPERTY_USAGE_STORAGE) == 0 or key in excluded: continue
		var value: Variant = object.get(key)
		values.append([key, ["object", value.get_instance_id()] if value is Object else value])
	return var_to_bytes(values)


func _common_root(regions: Array) -> Node3D:
	var nodes: Array[Node] = [_scheduler, _hero]
	for value: Variant in regions:
		if not value is Dictionary or not is_instance_valid(value.get("collision")): return null
		nodes.append(value.collision)
	var candidate: Node = self
	while is_instance_valid(candidate):
		if candidate is Node3D:
			var contains: bool = true
			for node: Node in nodes:
				if candidate != node and not candidate.is_ancestor_of(node): contains = false
			if contains: return candidate as Node3D
		candidate = candidate.get_parent()
	return null


func _domain_plan(world: Node3D, regions: Array) -> Dictionary:
	if not is_instance_valid(world) or not world.is_inside_tree() or world.get_world_3d() != get_world_3d() or regions.is_empty() or regions.size() > 32 or Engine.physics_ticks_per_second < 20 or Engine.physics_ticks_per_second > 240: return {"error": "Smoke requires a bounded actual common world and 20–240Hz native physics"}
	var fingerprint: Dictionary = _scheduler.pure_collision_fingerprint(world)
	if fingerprint.is_empty(): return {"error": "Smoke world has unsupported or unbound static collision"}
	var floors: Array = []
	var floor_paths: Dictionary = {}
	var supported: bool = false
	var source: Vector3 = _configuration.geometry.origin
	var radius: float = float(_configuration.geometry.radius) + CinderThreatScheduler.CAPSULE_RADIUS + SKIN
	for value: Variant in regions:
		if not value is Dictionary or not Codec.keys_error(value, ["collision", "safe_rect"]).is_empty() or not value.get("safe_rect") is Rect2: return {"error": "Smoke requires actual floor collision and fixed safe_rect only"}
		var bound: Variant = value.get("collision")
		if not is_instance_valid(bound): return {"error": "Smoke contact floor binding is no longer live"}
		var collision: CollisionShape3D = bound as CollisionShape3D
		if not is_instance_valid(collision) or not collision.is_inside_tree() or collision.is_queued_for_deletion() or collision.disabled or not collision.shape is BoxShape3D or not collision.get_parent() is StaticBody3D or collision.get_parent() is AnimatableBody3D or not collision.global_basis.is_equal_approx(Basis.IDENTITY) or not world.is_ancestor_of(collision): return {"error": "Smoke contact floor must be a live upright static Box"}
		var body: StaticBody3D = collision.get_parent() as StaticBody3D
		var size: Vector3 = (collision.shape as BoxShape3D).size
		var top: float = collision.global_position.y + size.y * 0.5
		var safe: Rect2 = value.safe_rect
		var physical := Rect2(Vector2(collision.global_position.x - size.x * 0.5, collision.global_position.z - size.z * 0.5), Vector2(size.x, size.z))
		if body.constant_linear_velocity != Vector3.ZERO or body.constant_angular_velocity != Vector3.ZERO or not size.is_finite() or size.x <= 0 or size.y <= 0 or size.z <= 0 or not safe.position.is_finite() or not safe.size.is_finite() or safe.size.x <= 0 or safe.size.y <= 0 or not physical.encloses(safe) or absf(top - source.y) > 0.00001: return {"error": "Smoke floors must be fixed coplanar supported boxes with contained finite rectangles"}
		var path: String = String(world.get_path_to(collision))
		if floor_paths.has(path): return {"error": "Smoke floor binding duplicated"}
		floor_paths[path] = true
		floors.append({"path": path, "position": Codec.vector3(collision.global_position), "size": Codec.vector3(size), "safe_rect": [safe.position.x, safe.position.y, safe.size.x, safe.size.y]})
		if safe.encloses(Rect2(Vector2(source.x - radius, source.z - radius), Vector2.ONE * radius * 2.0)): supported = true
	if not supported: return {"error": "One clean authored floor Box must contain the entire expanded contact disc and skin"}
	for body: Dictionary in fingerprint.colliders:
		if not _identity_transform(body.transform): return {"error": "Smoke's bounded world supports upright Box scenery only"}
		for shape: Dictionary in body.shapes:
			if shape.data.type != "BoxShape3D" or not _identity_transform(shape.transform): return {"error": "Smoke's bounded world supports upright Box scenery only"}
			var path: String = String(body.path) + "/" + String(shape.path)
			if floor_paths.has(path): continue
			var center: Vector3 = Codec.read_vector3(body.transform[3]) + Codec.read_vector3(shape.transform[3])
			var half: Vector3 = Codec.read_vector3(shape.data.size) * 0.5
			if center.y + half.y <= source.y + 0.02 or center.y - half.y >= source.y + CinderThreatScheduler.CAPSULE_HEIGHT + 0.02: continue
			var closest := Vector2(clampf(source.x, center.x - half.x, center.x + half.x), clampf(source.z, center.z - half.z, center.z + half.z))
			if closest.distance_squared_to(Vector2(source.x, source.z)) <= radius * radius: return {"error": "Smoke contact disc may not straddle blocking scenery"}
	floors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.path < b.path)
	return {"collision": fingerprint, "floors": floors}


func _identity_transform(value: Variant) -> bool:
	return value is Array and value.size() == 4 and value.slice(0, 3) == [Codec.vector3(Vector3.RIGHT), Codec.vector3(Vector3.UP), Codec.vector3(Vector3.BACK)]


func _live_bindings() -> bool:
	return not _configuration.is_empty() and is_inside_tree() and is_node_ready() and is_instance_valid(_scheduler) and _scheduler.is_inside_tree() and not _scheduler.is_queued_for_deletion() and _scheduler.get_world_3d() == get_world_3d() and _scheduler.process_physics_priority < process_physics_priority and is_instance_valid(_hero) and _hero.is_inside_tree() and not _hero.is_queued_for_deletion() and _hero.get_world_3d() == get_world_3d() and _hero.process_physics_priority < process_physics_priority and is_instance_valid(_cue)


func _live_reservation(id: String) -> Dictionary:
	for record: Dictionary in _scheduler.reservations():
		if record.id == id and int(record.source_instance_id) == get_instance_id(): return record
	return {}


func _exchange_data(record: Dictionary) -> Dictionary:
	var value: Dictionary = {}
	for key: String in EXCHANGE_KEYS: value[key] = record[key]
	return value.duplicate(true)


func _phase_at(clock: float) -> String:
	return "warning" if clock < float(_exchange.lock_from_s) else ("lock" if clock < float(_exchange.active_from_s) else ("active" if clock <= float(_exchange.active_until_s) else "recovery"))


func _on_invalidated(id: String, reason: String) -> void:
	if _status == "running" and id == _exchange.get("id") and not _cancelling: cancel(reason)


func _exit_tree() -> void:
	if is_instance_valid(_scheduler):
		if _scheduler.reservation_invalidated.is_connected(_on_invalidated): _scheduler.reservation_invalidated.disconnect(_on_invalidated)
		_scheduler.cancel_owner(self, "smoke_bank_removed")


func _stable_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 128: return false
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


func _same_exact(left: Variant, right: Variant) -> bool:
	if Codec.is_number(left) and Codec.is_number(right): return float(left) == float(right)
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size(): return false
		for key: Variant in left:
			if not right.has(key) or not _same_exact(left[key], right[key]): return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size(): return false
		for index: int in range(left.size()):
			if not _same_exact(left[index], right[index]): return false
		return true
	return typeof(left) == typeof(right) and left == right


## Parent validates the complete saved Player first, then prevalidates all
## children without mutation. Commit actual Player -> Scheduler -> bank without
## yielding, at the complete-native-tick paused Shell barrier. No nested actor
## snapshot is retained in this transport and no timer/resource is regranted.
func snapshot_state(scheduler_bindings: Dictionary) -> Dictionary:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty(): return {}
	_snapshot_busy = true
	var paired: Dictionary = _scheduler.snapshot_state(scheduler_bindings)
	var player: Dictionary = _hero.snapshot_state()
	var value: Dictionary = {}
	if paired.is_empty() or player.is_empty(): last_snapshot_error = _scheduler.last_snapshot_error if paired.is_empty() else _hero.last_snapshot_error
	else:
		value = _capture(float(paired.clock_s))
		last_snapshot_error = _snapshot_plan_error(value, scheduler_bindings, paired, player, true)
	_snapshot_busy = false
	return value.duplicate(true) if last_snapshot_error.is_empty() else {}


func snapshot_error(snapshot: Dictionary, scheduler_bindings: Dictionary, staged_scheduler_snapshot: Dictionary = {}, saved_player: Dictionary = {}) -> String:
	var error: String = _snapshot_access_error()
	if not error.is_empty(): return error
	# Reject nonclosed/cyclic/budgeted transport before any deep copy.
	error = Codec.value_error(snapshot)
	if not error.is_empty(): return error
	_snapshot_busy = true
	var paired: Dictionary = staged_scheduler_snapshot if not staged_scheduler_snapshot.is_empty() else _scheduler.snapshot_state(scheduler_bindings)
	var actor: Dictionary = saved_player if not saved_player.is_empty() else _hero.snapshot_state()
	if paired.is_empty() or actor.is_empty(): error = "Actual/staged paused Scheduler and validated saved Player required"
	else:
		error = _scheduler.snapshot_error(paired, scheduler_bindings)
		if error.is_empty(): error = _hero.snapshot_error(actor)
		if error.is_empty(): error = _snapshot_plan_error(snapshot, scheduler_bindings, paired, actor)
	_snapshot_busy = false
	return error


func restore_state(snapshot: Dictionary, scheduler_bindings: Dictionary) -> bool:
	last_snapshot_error = _snapshot_access_error()
	if not last_snapshot_error.is_empty(): return false
	last_snapshot_error = Codec.value_error(snapshot)
	if not last_snapshot_error.is_empty(): return false
	_snapshot_busy = true
	var paired: Dictionary = _scheduler.snapshot_state(scheduler_bindings)
	var actor: Dictionary = _hero.snapshot_state()
	last_snapshot_error = "Commit actual Player and Scheduler first" if paired.is_empty() or actor.is_empty() else _snapshot_plan_error(snapshot, scheduler_bindings, paired, actor, true)
	if not last_snapshot_error.is_empty():
		_snapshot_busy = false
		return false
	var accepted: Dictionary = snapshot.duplicate(true)
	_status = accepted.status
	_phase = accepted.phase
	_cycle = int(accepted.cycle)
	_exchange = _decode_exchange(accepted.exchange)
	_encounter_id = accepted.encounter_id
	_resolved = accepted.resolved_role
	_domain = accepted.domain
	_sample = _decode_sample(accepted.sample)
	_trace.clear()
	for segment: Dictionary in accepted.trace: _trace.append(_decode_segment(segment))
	_processed = int(accepted.processed_count)
	_pending_stage = accepted.pending_stage
	_contact_since = float(accepted.contact_since_s)
	_processed_clock = float(accepted.processed_clock_s)
	_receipts.clear()
	for receipt: Dictionary in accepted.receipts: _receipts.append(receipt)
	_cancel_reason = accepted.last_cancel_reason
	_world_root = scheduler_bindings.world_root
	_regions = scheduler_bindings.floors.values()
	# The validated fresh resources are reconstructed quietly; a live damaged
	# native binding failed _snapshot_access_error before any of these writes.
	var blocked: bool = _cue.is_blocking_signals()
	_cue.set_block_signals(true)
	_cue.clear()
	_cue_guard.clear()
	if _phase != "clear": _cue.present(_configuration.geometry, _phase)
	_publishing_cue = true
	_remember_published_cue(_cue.state())
	_publishing_cue = false
	_cue.set_block_signals(blocked)
	_update_indicator()
	_snapshot_busy = false
	return true


func _snapshot_access_error() -> String:
	if not _live_bindings() or not get_tree().paused: return "Smoke transport requires stable actual bindings at the paused complete-tick Shell barrier"
	if _busy or _snapshot_busy or _cancelling: return "Smoke transport cannot run inside physics/cue/damage/tick callbacks"
	var description: Dictionary = BodySweep.source_description(_hero)
	if description.has("error"): return "Smoke transport requires the actual supported shared Hero body"
	return _native_error()


func _capture(clock: float) -> Dictionary:
	var trace: Array = []
	for segment: Dictionary in _trace: trace.append(_encode_segment(segment))
	return {"api_revision": API_REVISION, "schema_version": 1, "bank_id": _configuration.bank_id, "configuration": _encode_configuration(), "hero_id": _hero_id, "status": _status, "phase": _phase, "cycle": _cycle, "clock_s": clock, "encounter_id": _encounter_id, "resolved_role": _resolved.duplicate(true), "exchange": _encode_exchange(_exchange), "domain": _domain.duplicate(true), "sample": _encode_sample(_sample), "trace": trace, "processed_count": _processed, "pending_stage": _pending_stage, "contact_since_s": _contact_since, "processed_clock_s": _processed_clock, "receipts": _receipts.duplicate(true), "last_cancel_reason": _cancel_reason}


func _encode_configuration() -> Dictionary:
	var value: Dictionary = _configuration.duplicate(true)
	value.geometry = {"kind": "circle", "origin": Codec.vector3(_configuration.geometry.origin), "radius": _configuration.geometry.radius}
	value.opening_position = Codec.vector3(_configuration.opening_position)
	return value


func _encode_exchange(exchange: Dictionary) -> Dictionary:
	if exchange.is_empty(): return {}
	var value: Dictionary = exchange.duplicate(true)
	value.geometry = _encode_configuration().geometry
	value.source_position = Codec.vector3(exchange.source_position)
	value.opening_position = Codec.vector3(exchange.opening_position)
	return value


func _decode_exchange(exchange: Dictionary) -> Dictionary:
	if exchange.is_empty(): return {}
	var value: Dictionary = exchange.duplicate(true)
	value.geometry = Geometry.circle(Codec.read_vector3(exchange.geometry.origin), float(exchange.geometry.radius))
	value.source_position = Codec.read_vector3(exchange.source_position)
	value.opening_position = Codec.read_vector3(exchange.opening_position)
	return value


func _encode_sample(sample: Dictionary) -> Dictionary:
	if sample.is_empty(): return {}
	var value: Dictionary = sample.duplicate(true)
	value.position = Codec.vector3(sample.position)
	return value


func _decode_sample(sample: Dictionary) -> Dictionary:
	if sample.is_empty(): return {}
	var value: Dictionary = sample.duplicate(true)
	value.position = Codec.read_vector3(sample.position)
	return value


func _encode_segment(segment: Dictionary) -> Dictionary:
	var value: Dictionary = segment.duplicate(true)
	value.from = Codec.vector3(segment.from)
	value.to = Codec.vector3(segment.to)
	return value


func _decode_segment(segment: Dictionary) -> Dictionary:
	var value: Dictionary = segment.duplicate(true)
	value.from = Codec.read_vector3(segment.from)
	value.to = Codec.read_vector3(segment.to)
	return value


func _snapshot_plan_error(snapshot: Dictionary, bindings: Dictionary, paired: Dictionary, actor: Dictionary, actual: bool = false) -> String:
	var error: String = Codec.value_error(snapshot)
	if not error.is_empty(): return error
	error = Codec.keys_error(snapshot, ["api_revision", "schema_version", "bank_id", "configuration", "hero_id", "status", "phase", "cycle", "clock_s", "encounter_id", "resolved_role", "exchange", "domain", "sample", "trace", "processed_count", "pending_stage", "contact_since_s", "processed_clock_s", "receipts", "last_cancel_reason"])
	if not error.is_empty(): return error
	if snapshot.api_revision != API_REVISION or snapshot.schema_version != 1 or snapshot.bank_id != _configuration.bank_id or snapshot.hero_id != _hero_id or not snapshot.configuration is Dictionary or not _same_exact(snapshot.configuration, _encode_configuration()) or not Codec.is_integer(snapshot.cycle) or snapshot.status not in ["idle", "running", "cancelled", "complete"] or not snapshot.encounter_id is String or not snapshot.last_cancel_reason is String or snapshot.last_cancel_reason.length() > 512 or not snapshot.resolved_role is Dictionary or not snapshot.exchange is Dictionary or not snapshot.domain is Dictionary or not snapshot.sample is Dictionary or not snapshot.trace is Array or not snapshot.receipts is Array: return "Invalid closed immutable smoke identity/configuration/transport"
	if not Codec.in_range(snapshot.clock_s, 0, 1000000000) or float(snapshot.clock_s) != float(paired.clock_s) or not bindings.get("owners") is Dictionary or bindings.owners.get(_configuration.bank_id) != self or not bindings.get("floors") is Dictionary: return "Smoke must share the exact actual/staged Scheduler clock and bound source"
	var owned: Dictionary = {}
	for reservation: Dictionary in paired.reservations:
		if reservation.source_id == _configuration.bank_id: owned = reservation
	if snapshot.status == "idle":
		for cooldown: Dictionary in paired.cooldowns:
			if cooldown.source_id == _configuration.bank_id: return "Idle smoke cannot forget an executed cooldown"
		if snapshot.cycle != 0 or snapshot.phase != "clear" or not snapshot.encounter_id.is_empty() or not snapshot.resolved_role.is_empty() or not snapshot.exchange.is_empty() or not snapshot.domain.is_empty() or not snapshot.sample.is_empty() or not snapshot.trace.is_empty() or snapshot.processed_count != 0 or snapshot.pending_stage != "" or snapshot.contact_since_s != -1.0 or snapshot.processed_clock_s != -1.0 or not snapshot.receipts.is_empty() or not owned.is_empty(): return "Idle smoke cannot retain executed contact/exchange state"
		return ""
	if not Codec.is_integer(snapshot.cycle, 1) or not _stable_id(snapshot.encounter_id) or not Codec.keys_error(snapshot.exchange, EXCHANGE_KEYS).is_empty() or not _same_exact(snapshot.exchange.geometry, _encode_configuration().geometry) or not Codec.is_vector3(snapshot.exchange.source_position) or Codec.read_vector3(snapshot.exchange.source_position) != _configuration.geometry.origin or not Codec.is_vector3(snapshot.exchange.opening_position): return "Executed smoke requires its original finite source/geometry/exchange"
	var exchange: Dictionary = snapshot.exchange
	if not exchange.id is String or not exchange.id.begins_with("threat-") or not exchange.id.substr(7).is_valid_int() or not Codec.is_integer(int(exchange.id.substr(7)), 1, int(paired.serial)) or exchange.id != "threat-%d" % int(exchange.id.substr(7)) or not exchange.profile_id is String or not Codec.is_integer(exchange.world_revision, 1): return "Smoke must preserve exact Scheduler reservation identity"
	var difficulty = Difficulty.new()
	var resolved: Dictionary = difficulty.resolve_role(_configuration.raw_role, exchange.profile_id, _configuration.timing_floors)
	if resolved.is_empty() or not _same_exact(snapshot.resolved_role, resolved): return "Smoke role must resolve once from immutable raw data and original profile"
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not Codec.in_range(exchange[key], 0, 1000000000): return "Smoke deadlines must remain finite nonnegative originals"
	var active: float = float(exchange.start_s) + float(resolved.windup_s)
	var deadlines := {"lock_from_s": active - float(resolved.lock_s), "active_from_s": active, "active_until_s": active + float(resolved.active_s), "recovery_until_s": active + float(resolved.active_s) + float(resolved.recovery_s), "cooldown_until_s": active + float(resolved.attack_interval_s)}
	for key: String in deadlines:
		if float(exchange[key]) != float(deadlines[key]): return "Smoke cannot refresh an original deadline or source cooldown"
	var candidate_domain: Dictionary = _domain_plan(bindings.world_root, bindings.floors.values())
	if candidate_domain.has("error") or not _same_exact(candidate_domain, snapshot.domain) or not _same_exact(snapshot.domain.get("collision", {}), paired.collision): return "Saved smoke world/floor domain must match actual immutable native bindings"
	if global_position != _configuration.geometry.origin or not global_basis.is_equal_approx(Basis.IDENTITY): return "Apply the original actual stationary smoke source before validation/commit"
	if snapshot.status == "running":
		if owned.is_empty() or snapshot.encounter_id != paired.encounter_id or not snapshot.last_cancel_reason.is_empty() or snapshot.phase != _phase_at_exchange(float(snapshot.clock_s), exchange): return "Running smoke requires same reserved epoch and exact current phase"
		for key: String in EXCHANGE_KEYS:
			if not _same_exact(exchange[key], owned[key]): return "Smoke and staged/actual reservation disagree"
	else:
		if snapshot.phase != "clear" or not owned.is_empty(): return "Inactive smoke cannot hide a retained danger lease"
		if snapshot.status == "cancelled" and snapshot.last_cancel_reason.is_empty(): return "Cancelled smoke requires an explicit reason"
		if snapshot.status == "complete" and snapshot.encounter_id == paired.encounter_id and float(snapshot.clock_s) <= float(exchange.recovery_until_s): return "Smoke cannot discard remaining recovery"
	if snapshot.encounter_id == paired.encounter_id and float(exchange.cooldown_until_s) > float(snapshot.clock_s):
		var retained: bool = false
		for cooldown: Dictionary in paired.cooldowns:
			if cooldown.source_id == _configuration.bank_id and float(cooldown.ready_s) == float(exchange.cooldown_until_s): retained = true
		if not retained: return "Smoke cannot lose its original admitted source cooldown"
	if not Codec.keys_error(snapshot.sample, ["position", "clock_s", "actor_clock_s", "grounded", "alive"]).is_empty() or not Codec.is_vector3(snapshot.sample.get("position")) or not Codec.in_range(snapshot.sample.get("clock_s"), float(exchange.start_s), float(snapshot.clock_s)) or not Codec.in_range(snapshot.sample.get("actor_clock_s"), 0, 1000000000000) or not snapshot.sample.get("grounded") is bool or not snapshot.sample.get("alive") is bool: return "Finite exact current Hero sample required"
	if snapshot.status == "running":
		if float(snapshot.sample.clock_s) != float(snapshot.clock_s) or not _same_exact(snapshot.sample.position, actor.motion.position) or float(snapshot.sample.actor_clock_s) != float(actor.world_actions.clock_s) or snapshot.sample.grounded != actor.motion.grounded or snapshot.sample.alive != (not actor.resources.dead): return "Running smoke sample must match the complete saved Player/Scheduler tick"
		if actual and (Codec.read_vector3(snapshot.sample.position) != _hero.global_position or float(snapshot.sample.actor_clock_s) != _hero.get_world_action_clock() or snapshot.sample.alive != (not _hero.dead)): return "Commit the exact actual saved Hero before smoke"
	return _history_error(snapshot, exchange)


func _history_error(snapshot: Dictionary, exchange: Dictionary) -> String:
	if snapshot.trace.size() > MAX_TRACE or not Codec.is_integer(snapshot.processed_count, 0, snapshot.trace.size()) or not Codec.in_range(snapshot.contact_since_s, -1.0, float(snapshot.clock_s)) or not Codec.in_range(snapshot.processed_clock_s, -1.0, float(snapshot.clock_s)) or snapshot.receipts.size() > int(_configuration.contact.max_opportunities): return "Smoke history exceeds its bounded native trace/opportunity schema"
	if snapshot.pending_stage not in ["", "phase", "notify", "notification"]: return "Unsupported smoke callback continuation"
	var dt: float = 1.0 / float(Engine.physics_ticks_per_second)
	var pending: int = snapshot.trace.size() - int(snapshot.processed_count)
	if pending > 1 or (pending == 0 and snapshot.pending_stage != "") or (pending == 1 and (snapshot.pending_stage == "" or snapshot.status != "running")): return "Only one original current native tick may remain held at a real callback boundary"
	if pending == 1:
		var held: Variant = snapshot.trace[-1]
		if not held is Dictionary or not Codec.is_number(held.get("start_s")) or not Codec.is_number(held.get("end_s")) or float(held.end_s) != float(snapshot.clock_s): return "Held smoke sample must be the actual current native tick"
		if snapshot.pending_stage == "phase":
			if not ((float(held.start_s) < float(exchange.active_from_s) and float(held.end_s) >= float(exchange.active_from_s)) or (float(held.start_s) <= float(exchange.active_until_s) and float(held.end_s) > float(exchange.active_until_s))): return "A phase-held sample must cross the original active/recovery boundary"
		else:
			if snapshot.receipts.is_empty() or not snapshot.receipts[-1] is Dictionary or not Codec.is_number(snapshot.receipts[-1].get("consumed_s")): return "Held notification must retain its already consumed original receipt"
			var final: Dictionary = snapshot.receipts[-1]
			if snapshot.pending_stage == "notify" and (final.get("stage") != "notify" or float(final.consumed_s) != float(snapshot.clock_s)): return "Pending damage notification must retain its current consumed receipt"
			if snapshot.pending_stage == "notification" and (final.get("stage") != "done" or (float(final.consumed_s) != float(snapshot.clock_s) and float(final.consumed_s) + dt != float(snapshot.clock_s))): return "Held delivered notification must retain its current or preceding native receipt"
	var previous: Dictionary = {}
	var last_processing_clock: float = -1.0
	for trace_index: int in range(snapshot.trace.size()):
		var encoded: Variant = snapshot.trace[trace_index]
		if not encoded is Dictionary or not Codec.keys_error(encoded, ["from", "to", "start_s", "end_s", "actor_from_s", "actor_to_s", "from_grounded", "to_grounded", "alive", "horizontal_collision", "processed_at_s"]).is_empty() or not Codec.is_vector3(encoded.from) or not Codec.is_vector3(encoded.to) or not Codec.in_range(encoded.start_s, float(exchange.start_s), float(snapshot.clock_s)) or not Codec.in_range(encoded.end_s, float(encoded.start_s), float(snapshot.clock_s)) or float(encoded.start_s) + dt != float(encoded.end_s) or not Codec.in_range(encoded.actor_from_s, 0, 1000000000000) or not Codec.in_range(encoded.actor_to_s, float(encoded.actor_from_s), float(encoded.actor_from_s) + dt) or not encoded.from_grounded is bool or not encoded.to_grounded is bool or not encoded.alive is bool or not encoded.horizontal_collision is bool: return "Each retained smoke sample must be a finite exact native tick"
		if trace_index < int(snapshot.processed_count):
			if not Codec.in_range(encoded.processed_at_s, float(encoded.end_s), float(snapshot.clock_s)) or float(encoded.processed_at_s) < last_processing_clock or (float(encoded.processed_at_s) != float(encoded.end_s) and float(encoded.processed_at_s) != float(encoded.end_s) + dt): return "Processed smoke ticks require exact ordered actual native clocks with at most one held-tick delay"
			last_processing_clock = float(encoded.processed_at_s)
		elif encoded.processed_at_s != null: return "Held smoke suffix must remain explicitly unprocessed"
		if encoded.alive and float(encoded.actor_from_s) + dt != float(encoded.actor_to_s): return "Living smoke samples retain actual contiguous Player clocks"
		if float(encoded.end_s) < float(exchange.active_from_s) or float(encoded.start_s) > float(exchange.active_until_s): return "Smoke trace may retain only original active-adjacent native ticks"
		if previous.is_empty():
			if float(encoded.start_s) > float(exchange.active_from_s) or float(encoded.end_s) < float(exchange.active_from_s): return "Smoke history must begin at its original activation boundary"
		elif float(previous.end_s) != float(encoded.start_s) or not _same_exact(previous.to, encoded.from) or float(previous.actor_to_s) != float(encoded.actor_from_s) or previous.to_grounded != encoded.from_grounded: return "Smoke history cannot reorder, omit or reconstruct sampled native ticks"
		previous = encoded
	if not previous.is_empty() and float(previous.end_s) == float(snapshot.sample.clock_s) and (not _same_exact(previous.to, snapshot.sample.position) or float(previous.actor_to_s) != float(snapshot.sample.actor_clock_s) or previous.to_grounded != snapshot.sample.grounded): return "Latest active trace must match exact current saved Hero endpoint"
	if snapshot.status == "running" and float(snapshot.clock_s) >= float(exchange.active_from_s) and float(snapshot.clock_s) <= float(exchange.active_until_s) and (previous.is_empty() or float(previous.end_s) != float(snapshot.clock_s)): return "Active smoke cannot omit the actual current motion sample"
	var contact: float = -1.0
	var processed_clock: float = -1.0
	var receipt_index: int = 0
	var last_consumed: float = -1.0
	for index: int in range(int(snapshot.processed_count)):
		var segment: Dictionary = _decode_segment(snapshot.trace[index])
		var qualifies: bool = segment.alive and segment.from_grounded and segment.to_grounded and not segment.horizontal_collision and float(segment.start_s) >= float(exchange.active_from_s) and float(segment.end_s) <= float(exchange.active_until_s) and _inside(segment.from) and _inside(segment.to)
		if qualifies:
			if contact < 0.0 or processed_clock != float(segment.start_s): contact = float(segment.start_s)
		else: contact = -1.0
		processed_clock = float(segment.end_s)
		var eligible: float = maxf(contact + float(_configuration.contact.grace_s), last_consumed + float(_configuration.contact.tick_s)) if last_consumed >= 0.0 else contact + float(_configuration.contact.grace_s)
		var processing_clock: float = float(segment.processed_at_s)
		var due: bool = qualifies and contact >= 0.0 and processed_clock >= eligible and processing_clock <= float(exchange.active_until_s) and last_consumed != processing_clock and receipt_index < int(_configuration.contact.max_opportunities)
		if due:
			if receipt_index >= snapshot.receipts.size(): return "Every earned processed smoke opportunity requires its consumed receipt"
			var receipt: Variant = snapshot.receipts[receipt_index]
			if not receipt is Dictionary or not Codec.keys_error(receipt, ["index", "trace_index", "eligible_s", "consumed_s", "stage", "result"]).is_empty() or not Codec.is_integer(receipt.index, 1, int(_configuration.contact.max_opportunities)) or receipt.index != receipt_index + 1 or not Codec.is_integer(receipt.trace_index, 0, int(snapshot.processed_count) - 1) or not Codec.in_range(receipt.eligible_s, float(exchange.active_from_s), float(exchange.active_until_s)) or not Codec.in_range(receipt.consumed_s, float(receipt.eligible_s), float(exchange.active_until_s)) or receipt.stage not in ["done", "notify", "abandoned"] or not receipt.result is Dictionary: return "Malformed closed consumed opportunity receipt"
			if int(receipt.trace_index) != index or float(receipt.eligible_s) != eligible or float(receipt.consumed_s) != processing_clock: return "Consumed smoke opportunity changed its exact original trigger/eligibility/native clock"
			var result: Dictionary = receipt.result
			if not Codec.keys_error(result, ["opportunity_consumed", "contact", "damage_attempted", "accepted", "raw_damage", "hp_damage", "impulse"]).is_empty() or not result.opportunity_consumed is bool or result.opportunity_consumed != true or not result.contact is bool or not result.damage_attempted is bool or result.damage_attempted != result.contact or not result.accepted is bool or not Codec.is_number(result.raw_damage) or float(result.raw_damage) != float(snapshot.resolved_role.damage) or not Codec.in_range(result.hp_damage, 0, float(snapshot.resolved_role.damage) * 100.0) or result.accepted != (float(result.hp_damage) > 0.0) or (not result.contact and result.accepted) or not _same_exact(result.impulse, [0.0, 0.0, 0.0]): return "Smoke cannot alter a consumed real damage result"
			if receipt.stage == "notify" and (receipt_index != snapshot.receipts.size() - 1 or snapshot.status != "running" or index != int(snapshot.processed_count) - 1): return "Only the final processed current opportunity may retain unfinished notification"
			if receipt.stage == "abandoned" and snapshot.status != "cancelled": return "Abandoned notification requires actual source cancellation"
			last_consumed = float(receipt.consumed_s)
			receipt_index += 1
	if receipt_index != snapshot.receipts.size(): return "Consumed smoke receipt has no processed native tick"
	if snapshot.status != "running" or not snapshot.sample.alive or float(snapshot.clock_s) > float(exchange.active_until_s): contact = -1.0
	if float(snapshot.contact_since_s) != contact or float(snapshot.processed_clock_s) != processed_clock: return "Saved grace must recompute from retained full native contact ticks"
	return ""


func _phase_at_exchange(clock: float, exchange: Dictionary) -> String:
	return "warning" if clock < float(exchange.lock_from_s) else ("lock" if clock < float(exchange.active_from_s) else ("active" if clock <= float(exchange.active_until_s) else "recovery"))
