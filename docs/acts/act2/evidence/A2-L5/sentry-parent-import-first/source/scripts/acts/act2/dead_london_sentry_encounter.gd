extends Node3D
## TMP MECHANICS DRAFT ONLY. No whole-level, portable save, art or balance claim.
## Host owns Player/equipment/controller, actual dry floor, one already begun
## Scheduler epoch, bait world-action connection, camera/framing and Shell.
## This parent owns ONE real joint cue/gate and TWO persistent native owners.
## Full strict parent codec deliberately rejects until implemented by the owner.

signal phase_checkpoint_eligible(receipts: Dictionary)
signal sentry_cleared(receipts: Dictionary)
signal hit_resolved(source_id: String, result: Dictionary)
signal runtime_failed(reason: String)

const ActorScript: Script = preload("res://scripts/acts/act2/dead_london_sentry_actor.gd")
const RayScript: Script = preload("res://scripts/acts/act2/dead_london_ray_exchange.gd")
const BaitScript: Script = preload("res://scripts/acts/act2/dead_london_bait.gd")
const FootScript: Script = preload("res://scripts/combat/lane_mechanism.gd")
const FootVisualScript: Script = preload("res://scripts/acts/act2/giant_foot_visual.gd")
const JointScript: Script = preload("res://scripts/cues/interaction_cue.gd")
const Geometry: Script = preload("res://scripts/combat/threat_geometry.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const SOURCE_ID: String = "A2-L5:dying-sentry"
const FOOT_ID: String = "A2-L5:near-foot"
const API_REVISION: String = "act2-b05-parent-draft-1"
const CODEC_PENDING: String = "B05 whole parent codec/provenance is unimplemented; no portable authority"
# PROPOSED OWNED TUNE ONLY: attack identity/geometry/damage/windup/lock/active
# are unchanged. Recovery is longer to preserve BOTH genuine return windows.
const FOOT_ROLE: Dictionary = {"raw_damage": 4.0, "windup_s": 2.2, "lock_s": 1.1, "active_s": 0.2, "recovery_s": 2.4, "attack_interval_s": 1.8, "max_hp": 1.0, "move_speed": 0.0}
const FOOT_FLOORS: Dictionary = {"windup_s": 2.2, "lock_s": 1.1, "recovery_s": 2.4}
const FOOT_RADIUS: float = 1.10

class BeforeConsumerGuard:
	extends Node
	var callback: Callable
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 99
	func _physics_process(_delta: float) -> void:
		if callback.is_valid(): callback.call()

var runtime_error: String = ""
var last_snapshot_error: String = CODEC_PENDING
var _hero: CinderPlayer
var _effects: PixelEffects
var _scheduler: CinderThreatScheduler
var _bait: RefCounted
var _world_root: Node3D
var _floors: Dictionary = {}
var _context: Dictionary = {}
var _profile: Dictionary = {}
var _host_presentation_guard: Callable
var _actor: Node3D
var _ray: Node3D
var _foot: CinderLaneMechanism
var _foot_visual: Node3D
var _joint: CinderInteractionCue
var _before: BeforeConsumerGuard
var _configured: bool = false
var _retired: bool = false
var _busy: bool = false
var _callback_depth: int = 0
var _guard_busy: bool = false
var _stage: String = "dormant"
var _ray_intro: Dictionary = {}
var _foot_intro: Dictionary = {}
var _threshold: Dictionary = {}
var _defeat: Dictionary = {}
var _last_damage_gate: Dictionary = {}
var _foot_exchange: Dictionary = {}
var _foot_cycle: int = 0
var _foot_recovery_observed: Dictionary = {}
var _foot_started_once: bool = false
var _pair: Dictionary = {}
var _accepted_cycles: Array[Dictionary] = []
var _completed_keys: Dictionary = {}
var _checkpoint_queued: bool = false
var _checkpoint_notice_sent: bool = false
var _clear_queued: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 110
	set_physics_process(false)

func configure(hero: CinderPlayer, effects: PixelEffects, scheduler: CinderThreatScheduler, bait: RefCounted, world_root: Node3D, floor_bindings: Dictionary, response_context: Dictionary, joint_at: Vector3, foot_at: Vector3, presentation_guard: Callable) -> bool:
	if _configured or _retired or not is_inside_tree() or not is_node_ready(): return false
	for node: Variant in [hero, effects, scheduler, world_root]:
		if not is_instance_valid(node) or not node.is_inside_tree() or not node.is_node_ready() or node.is_queued_for_deletion() or node.get_world_3d() != get_world_3d(): return false
	if hero.dead or hero.process_physics_priority >= 99 or scheduler.process_physics_priority >= 99 or not world_root.is_ancestor_of(self) or not world_root.is_ancestor_of(hero) or not world_root.is_ancestor_of(scheduler): return false
	if not joint_at.is_finite() or joint_at.y != 0.0 or not foot_at.is_finite() or foot_at.y != 0.0 or not presentation_guard.is_valid(): return false
	if not is_instance_valid(bait) or bait.get_script() != BaitScript or not bool(bait.call("is_bound_to", hero)) or floor_bindings.is_empty(): return false
	if not Codec.keys_error(response_context, RayScript.CONTEXT_KEYS).is_empty() or not response_context.floor_regions is Array: return false
	for region: Variant in response_context.floor_regions:
		if not region is Dictionary or not floor_bindings.values().has(region): return false
	_hero = hero
	_effects = effects
	_scheduler = scheduler
	_bait = bait
	_world_root = world_root
	_floors = floor_bindings.duplicate()
	_context = response_context.duplicate(true)
	_profile = scheduler.encounter_profile()
	_host_presentation_guard = presentation_guard
	if _profile.is_empty(): return false
	_actor = ActorScript.new() as Node3D
	_actor.name = "PersistentDyingSentryJoint"
	_actor.position = to_local(joint_at) # Authored before tree entry; never moved live.
	add_child(_actor)
	_joint = JointScript.new()
	_joint.name = "SingleCompositeJointCue"
	_joint.position = to_local(joint_at)
	add_child(_joint)
	if not bool(_actor.call("configure", _hero, _effects, SOURCE_ID)) or not bool(_actor.call("bind_joint_cue", _joint)): return _construction_failed("Actual Sentry/joint binding refused")
	var epoch: Dictionary = _scheduler.source_control_state(_actor)
	if epoch.get("encounter_id") != _context.encounter_id or epoch.get("world_revision") != _context.world_revision: return _construction_failed("Host must begin the ONE actual authored encounter before configuring B05")
	_ray = RayScript.new() as Node3D
	_ray.name = "PersistentBaitedRay"
	add_child(_ray)
	_foot = FootScript.new()
	_foot.name = "PersistentNearFootCircle"
	_foot.position = to_local(foot_at)
	add_child(_foot)
	if not _foot.configure(FOOT_ID, Geometry.circle(foot_at, FOOT_RADIUS), joint_at, FOOT_ROLE, FOOT_FLOORS) or not _foot.bind(_scheduler, {"hero": _hero}): return _construction_failed("Actual immutable circle foot binding refused")
	_foot_visual = FootVisualScript.new() as Node3D
	_foot_visual.name = "InheritedGreyboxGiantFoot"
	_foot.add_child(_foot_visual)
	if not bool(_ray.call("configure", _hero, _scheduler, _actor, _bait, _joint, String(_profile.id), _context)): return _construction_failed("Persistent ray binding refused")
	_ray.connect("state_changed", _on_ray_state)
	_ray.connect("hit_resolved", _on_ray_hit)
	_foot.state_changed.connect(_on_foot_state)
	_foot.hit_resolved.connect(_on_foot_hit)
	# Threshold observer is connected before host observers: spend first brace
	# while the actual damage transaction is still active, capture only pure data.
	_actor.connect("phase_boundary_reached", _on_threshold)
	_actor.connect("defeated", _on_sentry_defeated)
	_hero.died.connect(_on_hero_died)
	_configured = true
	if not bool(_actor.call("bind_damage_window", _joint_damage_window)) or not bool(_ray.call("set_presentation_guard", _ray_presentation_guard)): return _construction_failed("Single gate/presentation guard binding refused")
	_before = BeforeConsumerGuard.new()
	_before.name = "B05BeforeConsumerGuard"
	_before.callback = _guard_before_consumers
	add_child(_before)
	_sync_presentation()
	return true

func start() -> bool:
	if not _live() or get_tree().paused or _stage != "dormant" or not _supported_stable(): return false
	var cached: Dictionary = _bait.call("state")
	if cached.boundary.is_empty():
		if not bool(_bait.call("begin_boundary", "sentry-entry")): return false
	elif cached.boundary != "sentry-entry": return false
	_stage = "ray-introduction"
	set_physics_process(true)
	return true

func resume_after_phase_checkpoint() -> bool:
	# Host obligation: call only AFTER the real protected Shell checkpoint and
	# supported public resume. This skeleton cannot verify Attempts provenance.
	if not _live() or get_tree().paused or _stage != "phase-two-checkpoint" or not _checkpoint_notice_sent or not _supported_stable(): return false
	_stage = "phase-two"
	_pair.clear()
	return true

func get_actor() -> Node3D: return _actor
func get_ray() -> Node3D: return _ray
func get_foot() -> CinderLaneMechanism: return _foot
func get_joint_cue() -> CinderInteractionCue: return _joint
func owners() -> Dictionary: return {SOURCE_ID: _actor, FOOT_ID: _foot} if _configured and not _retired else {}
func bindings() -> Dictionary: return {"world_root": _world_root, "owners": owners(), "floors": _floors.duplicate()}

func state() -> Dictionary:
	# NATIVE DIAGNOSTIC ONLY: vectors and native exchange receipts are not a
	# portable codec and must not be inserted into CinderLevel local_state yet.
	return {"api_revision": API_REVISION, "stage": _stage, "runtime_error": runtime_error, "actor_hp": float(_actor.get("hp")) if is_instance_valid(_actor) else null, "boss_phase": int(_actor.get("boss_phase")) if is_instance_valid(_actor) else null, "transition_pending": bool(_actor.get("transition_pending")) if is_instance_valid(_actor) else false, "joint_cue": _joint.state() if is_instance_valid(_joint) else {}, "foot_introduction_started": _foot_started_once, "checkpoint_notice_sent": _checkpoint_notice_sent, "clock_s": _scheduler.get_clock() if is_instance_valid(_scheduler) else 0.0, "ray": _ray.call("state") if is_instance_valid(_ray) else {}, "foot": _foot.state() if is_instance_valid(_foot) else {}, "ray_introduction": _ray_intro.duplicate(true), "foot_introduction": _foot_intro.duplicate(true), "threshold": _threshold.duplicate(true), "defeat": _defeat.duplicate(true), "pair": _pair.duplicate(true), "accepted_cycles": _accepted_cycles.duplicate(true), "codec_ready": false}

func snapshot_state(_bindings: Dictionary = {}) -> Dictionary:
	last_snapshot_error = CODEC_PENDING
	return {}
func snapshot_error(_saved: Dictionary, _bindings: Dictionary = {}, _staged_player: Dictionary = {}, _staged_scheduler: Dictionary = {}) -> String: return CODEC_PENDING
func restore_state(_saved: Dictionary, _bindings: Dictionary = {}, _staged_player: Dictionary = {}) -> bool:
	last_snapshot_error = CODEC_PENDING
	return false

func _physics_process(_delta: float) -> void:
	if not _live() or _busy or _callback_depth > 0 or get_tree().paused or _stage in ["dormant", "cancelled", "cleared"]: return
	_busy = true
	_guard_before_consumers()
	if not runtime_error.is_empty() or _stage == "cancelled":
		_busy = false
		return
	_track_actual_consumers()
	_sync_presentation()
	if _stage == "ray-introduction":
		if not _ray_intro.is_empty() and String(_ray.call("state").status) != "running":
			_stage = "foot-introduction" if not _foot_started_once else "await-first-brace"
		elif String(_ray.call("state").status) != "running" and _supported_stable(): _try_ray()
	elif _stage == "foot-introduction":
		if not _foot_started_once and _supported_stable(): _try_foot(false)
		if not _foot_intro.is_empty(): _stage = "await-first-brace"
	elif _stage == "await-first-brace":
		if not _threshold.is_empty(): _commit_phase_two_if_earned()
		elif String(_ray.call("state").status) != "running" and _supported_stable(): _try_ray()
	elif _stage == "phase-two": _advance_pair()
	_busy = false

func _try_ray() -> void:
	var answer: Dictionary = _ray.call("activate", _context)
	if answer.get("accepted", false) and String(_ray.call("state").status) == "running":
		_accepted_cycles.append({"kind": "ray", "stage": _stage, "cycle": _ray.call("state").cycle, "admitted_exchange": _ray.call("state").exchange.duplicate(true)})

func _try_foot(paired: bool) -> void:
	if not _live() or get_tree().paused or _foot.state().status == "running": return
	# Actual same-tick stationary preview, immutable circle, joint anchor opening.
	var preview: Dictionary = _foot.preview_start("hero", _context, _actor.global_position)
	if not preview.get("accepted", false): return
	if not _presentation_ok({}, preview): return
	var old_cycle: int = int(_foot.state().cycle)
	var answer: Dictionary = _foot.start("hero", _context, _actor.global_position, null, preview)
	if not _live() or not answer.get("accepted", false): return
	var current: Dictionary = _foot.state()
	if int(current.cycle) <= old_cycle: return
	# A legitimate observer may hold pause before start returns. Record the
	# actually adopted cycle now; pause is not grounds for another intro cycle.
	_remember_foot_exchange()
	_accepted_cycles.append({"kind": "foot", "stage": _stage, "cycle": current.cycle, "admitted_exchange": _foot_exchange.duplicate(true), "proof": answer.proof.duplicate(true)})
	if paired:
		_pair = {"foot_cycle": _foot.state().cycle, "foot_exchange": _foot_exchange.duplicate(true), "ray_cycle": 0, "ray_exchange": {}, "proof": {}, "equipment": {}, "validated": false}
	else: _foot_started_once = true

func _advance_pair() -> void:
	var ray_state: Dictionary = _ray.call("state")
	var foot_state: Dictionary = _foot.state()
	if _pair.is_empty():
		if ray_state.status != "running" and foot_state.status != "running" and _supported_stable(): _try_foot(true)
		return
	if ray_state.status != "running" and int(_pair.ray_cycle) == 0 and foot_state.status == "running" and _supported_stable():
		# Assisted budget1 needs actual active release. Standard/Challenge wait
		# for Foot lock, so the two known activations remain visibly staggered.
		var due: bool = _scheduler.get_clock() > float(_foot_exchange.active_until_s) if int(_profile.reserved_threat_budget) == 1 else foot_state.phase in ["lock", "active", "recovery"]
		if due:
			_try_ray()
			var current: Dictionary = _ray.call("state")
			if current.status == "running": _pair.ray_cycle = int(current.cycle)
		return
	if ray_state.status == "running" and ray_state.armed: _validate_current_pair()
	# No source rollover while either accepted member remains live. Completion
	# of an earlier member closes the joint; it never substitutes for recovery.
	if ray_state.status != "running" and foot_state.status != "running": _pair.clear()

func _validate_current_pair() -> bool:
	if _pair.is_empty() or not _live(): return false
	var ray_state: Dictionary = _ray.call("state")
	var foot_state: Dictionary = _foot.state()
	if ray_state.status != "running" or not ray_state.armed or foot_state.status != "running": return false
	if int(foot_state.cycle) != int(_pair.foot_cycle) or (int(_pair.ray_cycle) > 0 and int(ray_state.cycle) != int(_pair.ray_cycle)):
		_cancel_owned("b05_unexpected_native_pair_cycle_rollover")
		_pair.clear()
		return false
	var r: Dictionary = ray_state.exchange
	var f: Dictionary = _foot_exchange
	var proof: Dictionary = ray_state.proof
	if proof.is_empty(): return bool(_pair.validated) # Quiet restore must restore a validated receipt; TODO codec currently rejects.
	var lower: float = maxf(float(r.active_until_s), float(f.active_until_s)) + CinderThreatScheduler.TIME_MARGIN
	var upper: float = minf(float(r.recovery_until_s), float(f.recovery_until_s)) - CinderThreatScheduler.TIME_MARGIN
	var stats: Dictionary = _hero.get_threat_response_state().stats
	if not proof.get("accepted", false) or proof.get("uses_blast") != false or proof.get("uses_invulnerability") != false or float(proof.primary_time_s) < lower or float(proof.response_complete_s) > upper or float(proof.response_complete_s) != float(proof.primary_time_s) + float(stats.primary_cooldown):
		_ray.call("cancel", "b05_pair_full_primary_does_not_fit_both_recoveries")
		_foot.cancel("b05_pair_full_primary_does_not_fit_both_recoveries")
		_pair.clear()
		return false
	_pair.ray_cycle = int(ray_state.cycle)
	_pair.ray_exchange = r.duplicate(true)
	_pair.foot_exchange = f.duplicate(true)
	_pair.proof = proof.duplicate(true)
	_pair.equipment = _hero.equipment.snapshot()
	_pair.validated = true
	return true

func _on_ray_state(_id: String, _state: Dictionary) -> void:
	if not _configured or _retired: return
	_callback_depth += 1
	_track_actual_consumers()
	if _stage == "phase-two" and not _pair.is_empty() and _ray.call("state").armed: _validate_current_pair()
	_sync_presentation()
	_guard_before_consumers()
	_callback_depth -= 1

func _on_foot_state(_state: Dictionary) -> void:
	if not _configured or _retired: return
	_callback_depth += 1
	_remember_foot_exchange()
	_track_actual_consumers()
	_sync_presentation()
	_guard_before_consumers()
	_callback_depth -= 1

func _on_ray_hit(id: String, result: Dictionary) -> void: hit_resolved.emit(id, result.duplicate(true))
func _on_foot_hit(_hero_id: String, cycle: int, result: Dictionary) -> void:
	_sync_presentation()
	var actual: Dictionary = result.duplicate(true)
	actual["cycle"] = cycle
	hit_resolved.emit(FOOT_ID, actual)

func _on_threshold(_id: String) -> void:
	if not _configured or _retired: return
	_callback_depth += 1
	# First observer spends real cue before any later observer can advertise it.
	_joint.present("spent", "attack")
	if _last_damage_gate.is_empty() or _actor.get("hp") != 15.0 or not bool(_actor.get("transition_pending")):
		_fail("Earned threshold lacks its actual preceding gate/finite actor receipt")
	else:
		_threshold = {"clock_s": _scheduler.get_clock(), "hp_before": _last_damage_gate.hp_before, "hp_after": float(_actor.get("hp")), "actual_hp_loss": float(_last_damage_gate.hp_before) - float(_actor.get("hp")), "opening_receipt": _last_damage_gate.duplicate(true)}
		# This is a real cancellation after recovery introduction, NEVER complete.
		_ray.call("cancel", "b05_first_brace_spent")
	_callback_depth -= 1

func _on_sentry_defeated(_id: String) -> void:
	if not _configured or _retired: return
	_callback_depth += 1
	_joint.present("spent", "attack")
	_defeat = {"clock_s": _scheduler.get_clock(), "hp_before": _last_damage_gate.get("hp_before"), "hp_after": float(_actor.get("hp")), "opening_receipt": _last_damage_gate.duplicate(true)}
	_ray.call("source_defeated")
	_foot.cancel("b05_real_sentry_defeated")
	_stage = "cleared"
	_clear_queued = true
	_publish_clear.call_deferred()
	_callback_depth -= 1

func _on_hero_died() -> void:
	if not _configured or _retired: return
	_stage = "cancelled"
	_ray.call("cancel", "b05_shared_hero_dead")
	_foot.cancel("b05_shared_hero_dead")
	_joint.clear()

func _track_actual_consumers() -> void:
	if not _live(): return
	_remember_foot_exchange()
	var ray_state: Dictionary = _ray.call("state")
	var now: float = _scheduler.get_clock()
	if ray_state.status == "running" and ray_state.armed and ray_state.phase == "recovery":
		var retained: Dictionary = _owned_record(_actor, String(ray_state.exchange.id))
		if not retained.is_empty() and retained.state == "recovery" and now > float(retained.active_until_s) and now <= float(retained.recovery_until_s) and _ray_intro.is_empty():
			_ray_intro = {"cycle": ray_state.cycle, "exchange": ray_state.exchange.duplicate(true), "observed_recovery_clock_s": now, "closing": "still-running"}
	if ray_state.status in ["complete", "cancelled"] and not _ray_intro.is_empty() and ray_state.exchange.get("id") == _ray_intro.exchange.id:
		_ray_intro.closing = ray_state.status
		_ray_intro.last_cancel_reason = ray_state.last_cancel_reason
	var foot_state: Dictionary = _foot.state()
	if foot_state.status == "running" and foot_state.phase == "recovery" and not _foot_exchange.is_empty():
		var retained: Dictionary = _owned_record(_foot, String(foot_state.reservation_id))
		if not retained.is_empty() and now > float(retained.active_until_s) and now <= float(retained.recovery_until_s):
			_foot_recovery_observed = {"cycle": foot_state.cycle, "exchange": _foot_exchange.duplicate(true), "observed_recovery_clock_s": now}
	if foot_state.status == "complete" and not _foot_exchange.is_empty() and not _foot_recovery_observed.is_empty() and int(_foot_recovery_observed.cycle) == int(foot_state.cycle) and now > float(_foot_exchange.recovery_until_s):
		var key: String = "foot:%s" % _foot_exchange.id
		if not _completed_keys.has(key):
			_completed_keys[key] = true
			var receipt: Dictionary = _foot_recovery_observed.duplicate(true)
			receipt["completed_clock_s"] = now
			receipt["closing"] = "complete"
			if _stage == "foot-introduction": _foot_intro = receipt

func _remember_foot_exchange() -> void:
	if not is_instance_valid(_foot) or not is_instance_valid(_scheduler): return
	var current: Dictionary = _foot.state()
	if current.status != "running": return
	var retained: Dictionary = _owned_record(_foot, String(current.reservation_id))
	if retained.is_empty(): return
	if int(current.cycle) != _foot_cycle:
		_foot_cycle = int(current.cycle)
		_foot_recovery_observed.clear()
	_foot_exchange.clear()
	for key: String in FootScript.EXCHANGE_KEYS: _foot_exchange[key] = retained[key]

func _owned_record(owner: Node3D, reservation_id: String) -> Dictionary:
	if not is_instance_valid(owner) or not is_instance_valid(_scheduler): return {}
	# Pure retained read; no callback-producing reservation prune here.
	var control: Dictionary = _scheduler.source_control_state(owner)
	for record: Dictionary in control.get("reservations", []):
		if record.id == reservation_id and int(record.source_instance_id) == owner.get_instance_id(): return record
	return {}

func _window_sources() -> Dictionary:
	if not _live() or get_tree().paused or _hero.dead or _actor.get("hp") <= 0.0 or bool(_actor.get("transition_pending")): return {}
	var now: float = _scheduler.get_clock()
	var r: Dictionary = _ray.call("state")
	var f: Dictionary = _foot.state()
	if _stage == "phase-two":
		if _pair.is_empty() or not bool(_pair.validated) or _pair.equipment != _hero.equipment.snapshot() or r.status != "running" or not r.armed or f.status != "running": return {}
		if int(r.cycle) != int(_pair.ray_cycle) or int(f.cycle) != int(_pair.foot_cycle) or r.exchange != _pair.ray_exchange or _foot_exchange != _pair.foot_exchange or f.reservation_id != _pair.foot_exchange.id: return {}
		var rr: Dictionary = _owned_record(_actor, String(r.exchange.id))
		var ff: Dictionary = _owned_record(_foot, String(f.reservation_id))
		if rr.is_empty() or ff.is_empty() or rr.state != "recovery" or ff.state != "recovery" or now <= maxf(float(rr.active_until_s), float(ff.active_until_s)) or now > minf(float(rr.recovery_until_s), float(ff.recovery_until_s)): return {}
		# Accepted proof is not permission for a later tap. The actual current
		# ordinary primary must retain its FULL current native cooldown within
		# BOTH recovery deadlines. This public stats read also works during the
		# real Player/actor damage transaction; no full snapshot is taken here.
		var actual_stats: Dictionary = _hero.get_threat_response_state().stats
		var cadence: Variant = actual_stats.get("primary_cooldown")
		if not Geometry.finite_number(cadence) or float(cadence) <= 0.0 or now + float(cadence) > minf(float(rr.recovery_until_s), float(ff.recovery_until_s)) - CinderThreatScheduler.TIME_MARGIN: return {}
		return {"kind": "paired", "ray": r.exchange.duplicate(true), "foot": _foot_exchange.duplicate(true), "proof": _pair.proof.duplicate(true), "clock_s": now}
	if _stage in ["ray-introduction", "await-first-brace"] and r.status == "running" and r.armed and r.phase == "recovery" and not _ray_intro.is_empty():
		var rr: Dictionary = _owned_record(_actor, String(r.exchange.id))
		if not rr.is_empty() and rr.state == "recovery" and now > float(rr.active_until_s) and now <= float(rr.recovery_until_s): return {"kind": "isolated-ray", "ray": r.exchange.duplicate(true), "clock_s": now}
	if _stage == "foot-introduction" and f.status == "running" and f.phase == "recovery":
		var ff: Dictionary = _owned_record(_foot, String(f.reservation_id))
		if not ff.is_empty() and ff.state == "recovery" and now > float(ff.active_until_s) and now <= float(ff.recovery_until_s): return {"kind": "isolated-foot", "foot": _foot_exchange.duplicate(true), "clock_s": now}
	return {}

func _joint_damage_window() -> bool:
	if not _live() or get_tree().paused or _hero.dead or not _presentation_ok(): return false
	var source: Dictionary = _actor.call("source_snapshot_state")
	if source.is_empty() or not source.armed or source.phase_pending or source.defeated or _joint.state().state not in ["available", "active"]: return false
	var window: Dictionary = _window_sources()
	if window.is_empty() or not _live() or get_tree().paused or not _presentation_ok(): return false
	# Host framing callbacks may clear a cue or retire a target. Recheck the
	# actual flat policy and pure native lease windows after the final callback.
	source = _actor.call("source_snapshot_state")
	if source.is_empty() or not source.armed or source.phase_pending or source.defeated or _joint.state().state not in ["available", "active"] or _window_sources() != window: return false
	_last_damage_gate = window.duplicate(true)
	_last_damage_gate["hp_before"] = float(_actor.get("hp"))
	return true

func _sync_presentation() -> void:
	if not _live(): return
	var r: Dictionary = _ray.call("state")
	var f: Dictionary = _foot.state()
	_foot_visual.call("pose", "idle" if f.phase == "clear" else f.phase, _foot_progress(f), Vector3.BACK, false)
	if _actor.get("hp") <= 0.0 or bool(_actor.get("transition_pending")):
		_joint.present("spent", "attack")
		return
	if not _hero.dead:
		# The inherited actor itself requires recovery before its gate. An
		# isolated Foot opening therefore poses the same low joint from actual
		# Foot phase/progress, not the already clear Ray's idle cosmetics.
		if _stage == "foot-introduction" and f.status == "running":
			_actor.call("present_phase", f.phase, _foot_progress(f), Vector3.BACK, false)
		else:
			_actor.call("present_phase", "idle" if r.phase == "clear" else r.phase, float(r.phase_progress), r.direction, false)
	if _window_sources().is_empty(): _joint.clear()
	else: _joint.present("available", "attack")

func _foot_progress(current: Dictionary) -> float:
	if current.status != "running": return 0.0
	var duration: float = 0.0
	if current.phase == "warning": duration = float(current.resolved_role.windup_s) - float(current.resolved_role.lock_s)
	elif current.phase == "lock": duration = float(current.resolved_role.lock_s)
	elif current.phase == "active": duration = float(current.resolved_role.active_s)
	elif current.phase == "recovery": duration = float(current.resolved_role.recovery_s)
	return clampf(1.0 - float(current.remaining_s) / duration, 0.0, 1.0) if duration > 0.0 else 0.0

func _commit_phase_two_if_earned() -> void:
	if _threshold.is_empty() or _ray_intro.is_empty() or _foot_intro.is_empty() or not _supported_stable(): return
	var current_ray: Dictionary = _ray.call("state")
	if current_ray.status == "running" or _foot.state().status == "running": return
	var now: float = _scheduler.get_clock()
	if now <= float(_ray_intro.exchange.recovery_until_s) or now < float(_ray_intro.exchange.cooldown_until_s) or now <= float(_foot_intro.exchange.recovery_until_s): return
	# A player may skip both initial openings, then earn the threshold from a
	# later real ray. Drain THAT retained cancelled cycle too, not just intro.
	if not current_ray.exchange.is_empty() and (now <= float(current_ray.exchange.recovery_until_s) or now < float(current_ray.exchange.cooldown_until_s)): return
	if _actor.get("hp") != 15.0 or not bool(_actor.get("transition_pending")) or _bait.call("state").boundary != "sentry-entry": return
	# Both public operations are nonyielding and emit no progression signals.
	# Full portable preflight/atomic codec is still TODO and must reject above.
	if not bool(_actor.call("commit_phase_two")) or not bool(_bait.call("begin_boundary", "sentry-phase-2")):
		_fail("Actual actor/bait phase boundary commit refused; no checkpoint emitted")
		return
	_stage = "phase-two-checkpoint"
	_joint.clear()
	_checkpoint_queued = true
	_publish_checkpoint.call_deferred()

func _publish_checkpoint() -> void:
	if not _checkpoint_queued or not _live() or _callback_depth > 0 or _busy:
		if _checkpoint_queued and _live(): _publish_checkpoint.call_deferred()
		return
	_checkpoint_queued = false
	_checkpoint_notice_sent = true
	phase_checkpoint_eligible.emit({"ray_introduction": _ray_intro.duplicate(true), "foot_introduction": _foot_intro.duplicate(true), "threshold": _threshold.duplicate(true), "clock_s": _scheduler.get_clock(), "actor_phase": int(_actor.get("boss_phase")), "bait": _bait.call("state")})

func _publish_clear() -> void:
	if not _clear_queued or not _live() or _callback_depth > 0 or _busy:
		if _clear_queued and _live(): _publish_clear.call_deferred()
		return
	_clear_queued = false
	sentry_cleared.emit({"threshold": _threshold.duplicate(true), "defeat": _defeat.duplicate(true), "pair": _pair.duplicate(true), "clock_s": _scheduler.get_clock(), "hp": float(_actor.get("hp"))})

func _ray_presentation_guard(_source_id: String, proposed_ray: Dictionary) -> bool: return _presentation_ok(proposed_ray)

func _presentation_ok(proposed_ray: Dictionary = {}, foot_preview: Dictionary = {}) -> bool:
	if not _live() or not _host_presentation_guard.is_valid(): return false
	var proposed: Dictionary = {"actor": _actor, "ray": _ray.call("state") if proposed_ray.is_empty() else proposed_ray.duplicate(true), "ray_cue": _ray.call("get_cue"), "foot": _foot.state(), "foot_preview": foot_preview.duplicate(true), "foot_cue": _foot.get_cue(), "foot_visual": _foot_visual, "joint": _joint, "hero": _hero, "stage": _stage, "pair": _pair.duplicate(true)}
	var result: Variant = _host_presentation_guard.call(proposed)
	return _live() and result is bool and result

func _guard_before_consumers() -> void:
	if not _configured or _retired or _guard_busy or _stage in ["dormant", "cancelled", "cleared", "phase-two-checkpoint"]: return
	_guard_busy = true
	if not _live() or not _presentation_ok():
		# Mark closed first: cancellation emits nested ordinary cue callbacks.
		_fail("B05 required native bindings/presentation lost")
		_cancel_owned("b05_actual_source_cue_or_frame_lost")
	_guard_busy = false

func _cancel_owned(reason: String) -> void:
	# Presentation callbacks may free/queue a child before returning. Do not
	# cast a freed map value or rely on the previous compound _live result.
	var ray: Variant = _ray
	var foot: Variant = _foot
	var joint: Variant = _joint
	if is_instance_valid(ray): ray.call("cancel", reason)
	if is_instance_valid(foot): foot.call("cancel", reason)
	if is_instance_valid(joint): joint.call("clear")

func _supported_stable() -> bool:
	if not _live() or _hero.dead: return false
	var response: Dictionary = _hero.get_threat_response_state()
	return response.get("stable", false) and response.motion.get("grounded", false) and not _hero.action_in_progress()

func _live() -> bool:
	if not _configured or _retired or not is_inside_tree() or is_queued_for_deletion(): return false
	for node: Variant in [_hero, _effects, _scheduler, _actor, _ray, _foot, _foot_visual, _joint, _world_root]:
		if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion() or node.get_world_3d() != get_world_3d(): return false
	return is_instance_valid(_bait) and bool(_bait.call("is_bound_to", _hero))

func _construction_failed(reason: String) -> bool:
	runtime_error = reason
	cleanup()
	return false

func _fail(reason: String) -> void:
	if not runtime_error.is_empty(): return
	runtime_error = reason
	_stage = "cancelled"
	_emit_failure.call_deferred(reason)
func _emit_failure(reason: String) -> void:
	if not _retired: runtime_failed.emit(reason)

func cleanup() -> void:
	if _retired: return
	_retired = true
	set_physics_process(false)
	if is_instance_valid(_before): _before.set_physics_process(false)
	if is_instance_valid(_hero) and _hero.died.is_connected(_on_hero_died): _hero.died.disconnect(_on_hero_died)
	if is_instance_valid(_ray): _ray.call("cleanup")
	if is_instance_valid(_foot):
		_foot.clear("b05_parent_removed")
		_foot.set_physics_process(false)
		_foot.hide() # Permanent retired parent: public start must refuse this child.
	if is_instance_valid(_actor): _actor.call("cleanup")
	if is_instance_valid(_joint): _joint.clear()
	# Host ends its ONE Scheduler encounter and releases its bait/action callback
	# when disposing the whole level. Never reset either at a boss phase boundary.
	_configured = false
func _exit_tree() -> void: cleanup()
