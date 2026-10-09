extends Node3D
## TMP strict parent codec derivative. Native transport remains untested.
## No whole-level, art or balance acceptance claim.
## Host owns Player/equipment/controller, actual dry floor, one already begun
## Scheduler epoch, bait world-action connection, camera/framing and Shell.
## This parent owns ONE real joint cue/gate and TWO persistent native owners.
## TMP strict codec derivative. Original mechanics552/d899 remains immutable.
## Full host Player/Scheduler are externally paired; no native acceptance claim.

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
const SNAPSHOT_API: String = "act2-b05-parent-snapshot-1"
const ExactJson: Script = preload("res://scripts/campaign/exact_json.gd")
const Difficulty: Script = preload("res://scripts/combat/difficulty.gd")
const EquipmentScript: Script = preload("res://scripts/equipment.gd")
const CueMesh: Script = preload("res://scripts/cues/cue_mesh.gd")
const PACK_KEYS: Array[String] = ["api_revision", "schema_version", "configuration", "clock_s", "bait", "actor", "joint", "ray", "foot", "parent"]
const CONFIG_KEYS: Array[String] = ["source_id", "foot_id", "joint_anchor", "foot_anchor", "profile_id", "encounter_id", "world_revision", "foot_role", "foot_floors", "foot_radius", "context", "owner_ids", "floor_ids", "actor_script_path"]
const PARENT_KEYS: Array[String] = ["stage", "foot_introduction_started", "checkpoint_notice_sent", "notifications", "ray_introduction", "foot_introduction", "threshold", "phase_commit", "defeat", "pair", "foot_tracking", "last_damage_gate", "foot_admission", "ray_admission"]
const PROOF_KEYS: Array[String] = ["accepted", "path", "landing", "attack_position", "primary_time_s", "response_complete_s", "uses_blast", "uses_invulnerability", "proof_scope"]
const ADMISSION_KEYS: Array[String] = ["cycle", "stage", "exchange", "proof", "equipment_ids", "bait_sample"]
const STAGES: Array[String] = ["dormant", "ray-introduction", "foot-introduction", "await-first-brace", "phase-two-checkpoint", "phase-two", "cleared", "cancelled"]
const POINT_EPSILON: float = CinderThreatScheduler.EPSILON

class CompositeJointCue:
	extends CinderInteractionCue
	# Expose inherited presentation transaction custody through an owned pure
	# API; no shared edit, replacement cue grammar or gameplay is introduced.
	func transport_access_error() -> String:
		return "Joint transport rejects inside native cue notification" if _notifying else ""
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
var last_snapshot_error: String = ""
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
var _clear_notice_sent: bool = false
var _restoring: bool = false
var _snapshotting: bool = false
var _validating: bool = false
var _transport_scope_bound: bool = false
var _foot_presentation_bound: bool = false
var _transport_owners: Dictionary = {}
var _configured_actor_script: Script
var _cue_publication_pending: int = 0
var _joint_anchor: Vector3 = Vector3.ZERO
var _foot_anchor: Vector3 = Vector3.ZERO
var _phase_commit: Dictionary = {}
var _foot_admission: Dictionary = {}
var _ray_admission: Dictionary = {}
var _restore_plan: Dictionary = {}
var _restore_bindings: Dictionary = {}
var _checkpoint_delivery_scheduled: bool = false
var _clear_delivery_scheduled: bool = false

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
	_joint_anchor = joint_at
	_foot_anchor = foot_at
	_profile = scheduler.encounter_profile()
	_host_presentation_guard = presentation_guard
	if _profile.is_empty(): return false
	_actor = _new_actor()
	if not is_instance_valid(_actor) or not _actor.get_script() is Script or not _actor_script_supported(_actor.get_script()): return _construction_failed("Authored actor factory must inherit the finite B05 Actor API")
	_configured_actor_script = _actor.get_script()
	_actor.name = "PersistentDyingSentryJoint"
	_actor.position = to_local(joint_at) # Authored before tree entry; never moved live.
	add_child(_actor)
	_joint = CompositeJointCue.new()
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
	# Published Shared41: actual late phase/query observers must still leave
	# the living source and required joint/art/frame intact at Foot damage.
	if not _foot.set_presentation_guard(_foot_presentation_guard): return _construction_failed("Foot parent presentation binding refused")
	_foot_presentation_bound = true
	_ray.call("get_cue").state_changed.connect(_on_required_cue_publication)
	_foot.get_cue().state_changed.connect(_on_required_cue_publication)
	if not bool(_actor.call("bind_damage_window", _joint_damage_window)) or not bool(_ray.call("set_presentation_guard", _ray_presentation_guard)): return _construction_failed("Single gate/presentation guard binding refused")
	_before = BeforeConsumerGuard.new()
	_before.name = "B05BeforeConsumerGuard"
	_before.callback = _guard_before_consumers
	add_child(_before)
	_sync_presentation()
	return true

func start() -> bool:
	if _restoring or _snapshotting or _validating: return false
	if not _live() or get_tree().paused or _stage != "dormant" or not _supported_stable(): return false
	var cached: Dictionary = _bait.call("state")
	if cached.boundary.is_empty():
		if not bool(_bait.call("begin_boundary", "sentry-entry")): return false
	elif cached.boundary != "sentry-entry": return false
	_stage = "ray-introduction"
	set_physics_process(true)
	return true

func resume_after_phase_checkpoint() -> bool:
	if _restoring or _snapshotting or _validating: return false
	# Host obligation: call only AFTER the real protected Shell checkpoint and
	# supported public resume. Host validates actual protected Attempts provenance.
	if not _live() or get_tree().paused or _stage != "phase-two-checkpoint" or not _checkpoint_notice_sent or not _supported_stable(): return false
	_stage = "phase-two"
	_pair.clear()
	return true

func _new_actor() -> Node3D: return ActorScript.new() as Node3D

# Owned visual subclass projects actual restored consumer/cue state here.
# It must not call Actor.present_phase or change any transport component.
func _restore_cosmetic_projection() -> void: pass

func _actor_script_supported(script: Script) -> bool:
	var current: Script = script
	for _depth: int in range(32):
		if current == ActorScript: return true
		if current == null: return false
		current = current.get_base_script()
	return false

func get_actor() -> Node3D: return _actor
func get_ray() -> Node3D: return _ray
func get_foot() -> CinderLaneMechanism: return _foot
func get_joint_cue() -> CinderInteractionCue: return _joint
func owners() -> Dictionary: return {SOURCE_ID: _actor, FOOT_ID: _foot} if _configured and not _retired else {}
func bindings() -> Dictionary: return {"world_root": _world_root, "owners": owners(), "floors": _floors.duplicate()}

func state() -> Dictionary:
	# NATIVE DIAGNOSTIC ONLY: vectors and native exchange receipts are not a
	# portable codec and must not be inserted into CinderLevel local_state yet.
	return {"api_revision": API_REVISION, "stage": _stage, "runtime_error": runtime_error, "actor_hp": float(_actor.get("hp")) if is_instance_valid(_actor) else null, "boss_phase": int(_actor.get("boss_phase")) if is_instance_valid(_actor) else null, "transition_pending": bool(_actor.get("transition_pending")) if is_instance_valid(_actor) else false, "joint_cue": _joint.state() if is_instance_valid(_joint) else {}, "foot_introduction_started": _foot_started_once, "checkpoint_notice_sent": _checkpoint_notice_sent, "clock_s": _scheduler.get_clock() if is_instance_valid(_scheduler) else 0.0, "ray": _ray.call("state") if is_instance_valid(_ray) else {}, "foot": _foot.state() if is_instance_valid(_foot) else {}, "ray_introduction": _ray_intro.duplicate(true), "foot_introduction": _foot_intro.duplicate(true), "threshold": _threshold.duplicate(true), "defeat": _defeat.duplicate(true), "pair": _pair.duplicate(true), "accepted_cycles": _accepted_cycles.duplicate(true), "codec_ready": _transport_scope_bound}

func snapshot_state(bindings: Dictionary = {}) -> Dictionary:
	last_snapshot_error = _transport_access_error(bindings)
	if not last_snapshot_error.is_empty(): return {}
	_snapshotting = true
	var player: Dictionary = _hero.snapshot_state()
	var scheduler: Dictionary = _scheduler.snapshot_state(bindings)
	var saved: Dictionary = {}
	if player.is_empty() or scheduler.is_empty():
		last_snapshot_error = "Complete actual Player/Scheduler capture refused"
	else:
		saved = {"api_revision": SNAPSHOT_API, "schema_version": 1, "configuration": _encode_configuration(bindings, String(_profile.id)), "clock_s": scheduler.clock_s, "bait": _bait.call("state"), "actor": _actor.call("snapshot_state"), "joint": _joint.state(), "ray": _ray.call("snapshot_state", bindings), "foot": _foot.snapshot_state(bindings), "parent": _encode_parent()}
		last_snapshot_error = _snapshot_plan_error(saved, bindings, player, scheduler, true)
	_snapshotting = false
	return saved.duplicate(true) if last_snapshot_error.is_empty() else {}

func snapshot_error(saved: Dictionary, bindings: Dictionary = {}, staged_player: Dictionary = {}, staged_scheduler: Dictionary = {}) -> String:
	var error: String = _transport_access_error(bindings)
	if not error.is_empty(): return error
	_validating = true
	error = _snapshot_plan_error(saved, bindings, staged_player, staged_scheduler)
	_validating = false
	return error

# Host must preflight its WHOLE packet first and restore the actual Player.
# This split then applies bait+actor+joint before the ONE shared Scheduler.
func restore_source_state(saved: Dictionary, bindings: Dictionary, staged_player: Dictionary, staged_scheduler: Dictionary) -> bool:
	last_snapshot_error = snapshot_error(saved, bindings, staged_player, staged_scheduler)
	if not last_snapshot_error.is_empty(): return false
	if not _same_exact(_hero.snapshot_state(), staged_player):
		last_snapshot_error = "Apply exact whole actual Player before B05 source commit"
		return false
	_restore_plan = {"saved": saved.duplicate(true), "player": staged_player.duplicate(true), "scheduler": staged_scheduler.duplicate(true)}
	_restore_bindings = bindings.duplicate()
	_restoring = true
	# All refusal predicates above run before first native mutation. These
	# public commits are deterministic, nonyielding and silent at this barrier.
	if not bool(_bait.call("restore_state", saved.bait, staged_player)) or not bool(_actor.call("restore_state", saved.actor)) or not _restore_joint(saved.joint):
		last_snapshot_error = "Unexpected B05 source commit invariant violation"
		_restore_plan.clear()
		_restore_bindings.clear()
		_restoring = false
		return false
	return true

# Host restores all other actors and its Scheduler between the two commits.
func restore_consumers_state(saved: Dictionary, bindings: Dictionary, staged_player: Dictionary, staged_scheduler: Dictionary) -> bool:
	if not _restoring or _restore_plan.is_empty() or not _same_exact(saved, _restore_plan.saved) or not _same_exact(staged_player, _restore_plan.player) or not _same_exact(staged_scheduler, _restore_plan.scheduler):
		last_snapshot_error = "B05 consumer commit requires its same validated source plan"
		return false
	last_snapshot_error = _binding_scope_error(bindings)
	if not last_snapshot_error.is_empty(): return false
	if _cue_publication_pending > 0 or not get_tree().paused or _busy or _callback_depth > 0 or _guard_busy:
		last_snapshot_error = "No native callback/yield between quiet split source and consumer commits"
		return false
	if not _same_bindings(bindings, _restore_bindings) or not _same_exact(_hero.snapshot_state(), staged_player) or not _same_exact(_scheduler.snapshot_state(bindings), staged_scheduler) or not _same_exact(_actor.call("snapshot_state"), saved.actor) or not _same_exact(_bait.call("state"), saved.bait) or not _same_exact(_joint.state(), saved.joint):
		last_snapshot_error = "Apply exact actual Player/source/Scheduler before B05 consumers"
		return false
	var staged: Dictionary = _staged_bindings(bindings, staged_player)
	# Rechecked predicates remain pure. No restore can discover a different
	# current Hero/sample/source or immutable native floor condition here.
	last_snapshot_error = String(_ray.call("snapshot_error", saved.ray, staged, staged_scheduler, staged_player, saved.bait))
	if last_snapshot_error.is_empty(): last_snapshot_error = _foot.snapshot_error(saved.foot, staged, staged_scheduler)
	if not last_snapshot_error.is_empty(): return false
	if not bool(_ray.call("restore_state", saved.ray, bindings, staged_player, saved.bait)) or not _foot.restore_state(saved.foot, bindings):
		last_snapshot_error = "Unexpected B05 consumer commit invariant violation"
		return false
	_profile = Difficulty.new().profile(saved.configuration.profile_id)
	_apply_parent(saved.parent)
	# Exact saved Actor yaw already restored. Only the separately clocked Foot
	# is posed here; joint state is applied again with all signals blocked.
	_foot_visual.call("pose", "idle" if _foot.state().phase == "clear" else _foot.state().phase, _foot_progress(_foot.state()), Vector3.BACK, false)
	if not _restore_joint(saved.joint):
		last_snapshot_error = "Unexpected quiet B05 joint reconstruction refusal"
		return false
	_restore_cosmetic_projection()
	_restore_plan.clear()
	_restore_bindings.clear()
	_restoring = false
	last_snapshot_error = ""
	return true

# Standalone convenience: actual Player must already be restored. Whole level
# uses split commits so every owner source is restored before ONE Scheduler.
func restore_state(saved: Dictionary, bindings: Dictionary = {}, staged_player: Dictionary = {}, staged_scheduler: Dictionary = {}) -> bool:
	if bindings.get("owners", {}).size() != 2:
		last_snapshot_error = "Whole host uses source/all-owners/Scheduler/consumers split, never standalone commit"
		return false
	if not restore_source_state(saved, bindings, staged_player, staged_scheduler): return false
	if not _scheduler.restore_state(staged_scheduler, bindings):
		last_snapshot_error = "Unexpected prevalidated Scheduler commit refusal"
		return false
	return restore_consumers_state(saved, bindings, staged_player, staged_scheduler)

func _physics_process(_delta: float) -> void:
	if _restoring or _snapshotting or _validating or not _live() or _busy or _callback_depth > 0 or get_tree().paused: return
	_resume_pending_notifications()
	if _stage in ["dormant", "cancelled", "cleared"]: return
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
		_remember_ray_admission()
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
	_foot_admission = {"cycle": current.cycle, "stage": _stage, "exchange": _foot_exchange.duplicate(true), "proof": answer.proof.duplicate(true), "equipment_ids": _hero.equipment.snapshot(), "bait_sample": {}}
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
	# Preserve the ORIGINAL real admission once, including after quiet Ray
	# restore drops its ephemeral proof. Never retag it with later equipment.
	if bool(_pair.validated):
		return _pair.ray_cycle == ray_state.cycle and _pair.foot_cycle == foot_state.cycle and _pair.ray_exchange == r and _pair.foot_exchange == f
	if proof.is_empty(): return false
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
	if not _configured or _retired or _restoring or _snapshotting or _validating: return
	_callback_depth += 1
	_track_actual_consumers()
	if _stage == "phase-two" and not _pair.is_empty() and _ray.call("state").armed: _validate_current_pair()
	_sync_presentation()
	_guard_before_consumers()
	_callback_depth -= 1

func _on_foot_state(_state: Dictionary) -> void:
	if not _configured or _retired or _restoring or _snapshotting or _validating: return
	_callback_depth += 1
	_remember_foot_exchange()
	_track_actual_consumers()
	_sync_presentation()
	_guard_before_consumers()
	_callback_depth -= 1

func _on_ray_hit(id: String, result: Dictionary) -> void:
	if not _restoring: hit_resolved.emit(id, result.duplicate(true))
func _on_foot_hit(_hero_id: String, cycle: int, result: Dictionary) -> void:
	if _restoring: return
	_sync_presentation()
	var actual: Dictionary = result.duplicate(true)
	actual["cycle"] = cycle
	hit_resolved.emit(FOOT_ID, actual)

func _on_threshold(_id: String) -> void:
	if not _configured or _retired or _restoring or _snapshotting or _validating: return
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
	if not _configured or _retired or _restoring or _snapshotting or _validating: return
	_callback_depth += 1
	_joint.present("spent", "attack")
	_defeat = {"clock_s": _scheduler.get_clock(), "hp_before": _last_damage_gate.get("hp_before"), "hp_after": float(_actor.get("hp")), "opening_receipt": _last_damage_gate.duplicate(true)}
	_ray.call("source_defeated")
	_foot.cancel("b05_real_sentry_defeated")
	_stage = "cleared"
	_clear_queued = true
	_clear_notice_sent = false
	_schedule_clear_delivery()
	_callback_depth -= 1

func _on_hero_died() -> void:
	if not _configured or _retired or _restoring: return
	_stage = "cancelled"
	_ray.call("cancel", "b05_shared_hero_dead")
	_foot.cancel("b05_shared_hero_dead")
	# Ordinary death must already preserve the closed spent source projection.
	# No capture-time repair: pending or defeated braces stay spent natively.
	if _actor.get("hp") <= 0.0 or bool(_actor.get("transition_pending")): _joint.present("spent", "attack")
	else: _joint.clear()

func _track_actual_consumers() -> void:
	if not _live() or _restoring: return
	_remember_ray_admission()
	_remember_foot_exchange()
	var ray_state: Dictionary = _ray.call("state")
	var now: float = _scheduler.get_clock()
	if ray_state.status == "running" and ray_state.armed and ray_state.phase == "recovery":
		var retained: Dictionary = _owned_record(_actor, String(ray_state.exchange.id))
		if not retained.is_empty() and retained.state == "recovery" and now > float(retained.active_until_s) and now <= float(retained.recovery_until_s) and _ray_intro.is_empty():
			_ray_intro = {"cycle": ray_state.cycle, "exchange": ray_state.exchange.duplicate(true), "observed_recovery_clock_s": now, "closing": "still-running", "admission": _ray_admission.duplicate(true)}
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
			if _stage == "foot-introduction":
				receipt["admission"] = _foot_admission.duplicate(true)
				_foot_intro = receipt

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
	if _restoring or _snapshotting or _validating: return false
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
	_last_damage_gate["equipment_ids"] = _hero.equipment.snapshot()
	_last_damage_gate["ray_cycle"] = int(_ray.call("state").cycle) if window.has("ray") else 0
	_last_damage_gate["foot_cycle"] = int(_foot.state().cycle) if window.has("foot") else 0
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
	# Portable transport is separately preflighted at a paused whole-unit barrier.
	if not bool(_actor.call("commit_phase_two")) or not bool(_bait.call("begin_boundary", "sentry-phase-2")):
		_fail("Actual actor/bait phase boundary commit refused; no checkpoint emitted")
		return
	_phase_commit = {"clock_s": now, "ray_cycle": current_ray.cycle, "ray_exchange": current_ray.exchange.duplicate(true), "floor": Codec.vector3(Vector3(_hero.global_position.x, 0, _hero.global_position.z)), "action_sequence": _bait.call("state").initial_sequence, "bait": _bait.call("state"), "ray_introduction_id": _ray_intro.exchange.id, "foot_introduction_id": _foot_intro.exchange.id, "threshold_clock_s": _threshold.clock_s}
	_stage = "phase-two-checkpoint"
	_joint.clear()
	_checkpoint_queued = true
	_schedule_checkpoint_delivery()

func _publish_checkpoint() -> void:
	_checkpoint_delivery_scheduled = false
	if _restoring or _snapshotting or _validating: return
	if not _checkpoint_queued or not _live() or _hero.dead or get_tree().paused: return
	if _callback_depth > 0 or _busy:
		_schedule_checkpoint_delivery()
		return
	_checkpoint_queued = false
	_checkpoint_notice_sent = true
	phase_checkpoint_eligible.emit({"ray_introduction": _ray_intro.duplicate(true), "foot_introduction": _foot_intro.duplicate(true), "threshold": _threshold.duplicate(true), "clock_s": _scheduler.get_clock(), "actor_phase": int(_actor.get("boss_phase")), "bait": _bait.call("state")})

func _publish_clear() -> void:
	_clear_delivery_scheduled = false
	if _restoring or _snapshotting or _validating: return
	if not _clear_queued or not _live() or _hero.dead or get_tree().paused: return
	if _callback_depth > 0 or _busy:
		_schedule_clear_delivery()
		return
	_clear_queued = false
	_clear_notice_sent = true
	sentry_cleared.emit({"threshold": _threshold.duplicate(true), "defeat": _defeat.duplicate(true), "pair": _pair.duplicate(true), "clock_s": _scheduler.get_clock(), "hp": float(_actor.get("hp"))})

func _ray_presentation_guard(_source_id: String, proposed_ray: Dictionary) -> bool: return _presentation_ok(proposed_ray)

func _foot_presentation_guard(source_id: String, _current: Dictionary) -> bool:
	# Held pause alone is valid. Shared Lane preserves measured pending paths
	# and performs the final pause/lease/cue native recheck after this callback.
	if source_id == FOOT_ID and _live() and _presentation_ok(): return true
	_fail("B05 required native bindings/presentation lost")
	_cancel_owned("b05_actual_source_cue_or_frame_lost")
	return false

func _presentation_ok(proposed_ray: Dictionary = {}, foot_preview: Dictionary = {}) -> bool:
	if not _live() or not _host_presentation_guard.is_valid(): return false
	var proposed: Dictionary = {"actor": _actor, "ray": _ray.call("state") if proposed_ray.is_empty() else proposed_ray.duplicate(true), "ray_cue": _ray.call("get_cue"), "foot": _foot.state(), "foot_preview": foot_preview.duplicate(true), "foot_cue": _foot.get_cue(), "foot_visual": _foot_visual, "joint": _joint, "hero": _hero, "stage": _stage, "pair": _pair.duplicate(true)}
	var result: Variant = _host_presentation_guard.call(proposed)
	return _live() and result is bool and result

func _guard_before_consumers() -> void:
	if _restoring or _snapshotting or _validating: return
	_resume_pending_notifications()
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
	if is_instance_valid(_ray):
		var cue: Variant = _ray.call("get_cue")
		if is_instance_valid(cue) and cue.state_changed.is_connected(_on_required_cue_publication): cue.state_changed.disconnect(_on_required_cue_publication)
		_ray.call("cleanup")
	if is_instance_valid(_foot):
		var cue: CinderThreatCue = _foot.get_cue()
		if is_instance_valid(cue) and cue.state_changed.is_connected(_on_required_cue_publication): cue.state_changed.disconnect(_on_required_cue_publication)
		_foot.clear("b05_parent_removed")
		_foot.set_physics_process(false)
		_foot.hide() # Permanent retired parent: public start must refuse this child.
	if is_instance_valid(_actor): _actor.call("cleanup")
	if is_instance_valid(_joint): _joint.clear()
	# Host ends its ONE Scheduler encounter and releases its bait/action callback
	# when disposing the whole level. Never reset either at a boss phase boundary.
	_configured = false
func _exit_tree() -> void: cleanup()

# CLOSED TRANSPORT: every host owner/floor participates in the ONE scheduler.
func bind_transport_scope(full_bindings: Dictionary) -> bool:
	if _transport_scope_bound or not _live() or _busy or _callback_depth > 0 or _restoring: return false
	var error: String = _native_scope_error(full_bindings)
	if not error.is_empty():
		last_snapshot_error = error
		return false
	_transport_owners = full_bindings.owners.duplicate()
	_transport_scope_bound = true
	return true

func _native_scope_error(value: Dictionary) -> String:
	if not _live() or value.get("world_root") != _world_root or not value.get("owners") is Dictionary or not value.get("floors") is Dictionary: return "Actual complete B05 host owner/floor/world map required"
	if value.owners.get(SOURCE_ID) != _actor or value.owners.get(FOOT_ID) != _foot or value.floors.size() != _floors.size(): return "Both distinct persistent B05 owners and every authored floor required"
	var seen: Dictionary = {}
	for id: Variant in value.owners:
		var node: Variant = value.owners[id]
		if not id is String or String(id).is_empty() or not node is Node3D or not is_instance_valid(node) or not node.is_inside_tree() or not node.is_node_ready() or node.is_queued_for_deletion() or not _world_root.is_ancestor_of(node) or node.get_world_3d() != get_world_3d(): return "Owner bindings require unique actual entered native sources"
		if seen.has(node.get_instance_id()): return "Owner aliases cannot create a second scheduler lease"
		seen[node.get_instance_id()] = true
	seen.clear()
	for id: Variant in value.floors:
		var region: Variant = value.floors[id]
		if not id is String or String(id).is_empty() or not _floors.has(id) or not region is Dictionary or not region.get("collision") is CollisionShape3D or not region.get("safe_rect") is Rect2 or region != _floors[id]: return "Exact complete authored floor map required"
		var collision: CollisionShape3D = region.collision
		if not is_instance_valid(collision) or not collision.is_inside_tree() or collision.is_queued_for_deletion() or collision.disabled or not collision.shape is BoxShape3D or not collision.get_parent() is StaticBody3D or not _world_root.is_ancestor_of(collision) or collision.get_world_3d() != get_world_3d(): return "Actual live static floor boxes required"
		if seen.has(collision.get_instance_id()): return "Floor IDs cannot alias one native shape"
		seen[collision.get_instance_id()] = true
	return ""

func _binding_scope_error(value: Dictionary) -> String:
	if not _transport_scope_bound: return "Bind complete host transport scope before capture/preflight/restore"
	var error: String = _native_scope_error(value)
	if not error.is_empty(): return error
	if value.owners.size() != _transport_owners.size(): return "Transport cannot narrow or extend the registered whole host owner map"
	for id: String in _transport_owners:
		if value.owners.get(id) != _transport_owners[id]: return "Transport owner identities cannot be replaced"
	for field: String in ["owner_positions", "owner_velocities", "owner_collision_states"]:
		if value.has(field):
			if not value[field] is Dictionary: return "Optional prospective owner data must be an ID map"
			for id: Variant in value[field]:
				if not value.owners.has(id): return "Prospective owner data cannot name an unmapped source"
	if value.get("owner_positions", {}).has(SOURCE_ID) and value.owner_positions[SOURCE_ID] != _joint_anchor: return "Persistent low joint cannot move prospectively"
	if value.get("owner_positions", {}).has(FOOT_ID) and value.owner_positions[FOOT_ID] != _foot_anchor: return "Persistent foot owner cannot move prospectively"
	if _actor.global_position != _joint_anchor or _foot.global_position != _foot_anchor or _joint.global_position != _joint_anchor: return "Actual immutable B05 source roots moved"
	if _actor.get_script() != _configured_actor_script or not _actor_script_supported(_configured_actor_script) or _ray.get_script() != RayScript or _foot.get_script() != FootScript or not _joint is CompositeJointCue or String(_joint.call("transport_access_error")) != "": return "Exact owned source/consumer/joint native scripts and idle cue transaction required"
	if not is_instance_valid(_before) or not _before.is_inside_tree() or _before.is_queued_for_deletion() or not _before.is_physics_processing() or _before.process_physics_priority != 99 or _before.process_mode != Node.PROCESS_MODE_PAUSABLE or _before.callback != Callable(self, "_guard_before_consumers"): return "Actual priority99 paused-mode custody guard required"
	for cue: CinderThreatCue in [_ray.call("get_cue"), _foot.get_cue()]:
		if not cue.state_changed.is_connected(_on_required_cue_publication): return "Required public cue transaction observer was removed"
	return ""

func _transport_access_error(value: Dictionary) -> String:
	if not _foot_presentation_bound: return "Bind the required original Foot parent presentation guard before transport"
	if not _live() or not get_tree().paused or not runtime_error.is_empty(): return "B05 transport requires healthy complete actual paused native unit"
	if _restoring or _snapshotting or _validating or _busy or _callback_depth > 0 or _guard_busy or _cue_publication_pending > 0: return "B05 transport rejects inside source/cue/damage/physics/restore transactions"
	return _binding_scope_error(value)

func _same_bindings(left: Dictionary, right: Dictionary) -> bool:
	return left.get("world_root") == right.get("world_root") and left.get("owners") == right.get("owners") and left.get("floors") == right.get("floors")

func _staged_bindings(value: Dictionary, player: Dictionary) -> Dictionary:
	var result: Dictionary = value.duplicate()
	result["hero_positions"] = {"hero": Codec.read_vector3(player.motion.position)}
	return result

func _ids(value: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for id: String in value: result.append(id)
	result.sort()
	return result

func _encode_context() -> Dictionary:
	var floor_ids: Array[String] = []
	for region: Dictionary in _context.floor_regions:
		for id: String in _floors:
			if region == _floors[id]: floor_ids.append(id)
	return {"recognition_s": _context.recognition_s, "attack_input_margin_s": _context.attack_input_margin_s, "escape_directions": _portable(_context.escape_directions), "return_directions": _portable(_context.return_directions), "floor_ids": floor_ids}

func _encode_configuration(value: Dictionary, profile_id: String) -> Dictionary:
	return {"source_id": SOURCE_ID, "foot_id": FOOT_ID, "joint_anchor": Codec.vector3(_joint_anchor), "foot_anchor": Codec.vector3(_foot_anchor), "profile_id": profile_id, "encounter_id": _context.encounter_id, "world_revision": _context.world_revision, "foot_role": FOOT_ROLE.duplicate(true), "foot_floors": FOOT_FLOORS.duplicate(true), "foot_radius": FOOT_RADIUS, "context": _encode_context(), "owner_ids": _ids(value.owners), "floor_ids": _ids(value.floors), "actor_script_path": _configured_actor_script.resource_path}

func _portable(value: Variant) -> Variant:
	if value is Vector3: return Codec.vector3(value)
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[key] = _portable(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_portable(item))
		return result
	# Unknown objects remain unknown and are rejected, never repaired to null.
	return value

func _encode_parent() -> Dictionary:
	return _portable({"stage": _stage, "foot_introduction_started": _foot_started_once, "checkpoint_notice_sent": _checkpoint_notice_sent, "notifications": {"checkpoint": "pending" if _checkpoint_queued else ("delivered" if _checkpoint_notice_sent else "none"), "clear": "pending" if _clear_queued else ("delivered" if _clear_notice_sent else "none")}, "ray_introduction": _ray_intro, "foot_introduction": _foot_intro, "threshold": _threshold, "phase_commit": _phase_commit, "defeat": _defeat, "pair": _pair, "foot_tracking": {"cycle": _foot_cycle, "exchange": _foot_exchange, "recovery_observed": _foot_recovery_observed}, "last_damage_gate": _last_damage_gate, "foot_admission": _foot_admission, "ray_admission": _ray_admission})

func _exchange_native(value: Dictionary) -> Dictionary:
	if value.is_empty(): return {}
	var result: Dictionary = value.duplicate(true)
	result.source_position = Codec.read_vector3(value.source_position)
	result.opening_position = Codec.read_vector3(value.opening_position)
	if value.geometry.kind == "circle": result.geometry = Geometry.circle(Codec.read_vector3(value.geometry.origin), float(value.geometry.radius))
	else: result.geometry = Geometry.lane(Codec.read_vector3(value.geometry["from"]), Codec.read_vector3(value.geometry["to"]), float(value.geometry.radius))
	return result

func _proof_native(value: Dictionary) -> Dictionary:
	if value.is_empty(): return {}
	var result: Dictionary = value.duplicate(true)
	result.landing = Codec.read_vector3(value.landing)
	result.attack_position = Codec.read_vector3(value.attack_position)
	for segment: Dictionary in result.path:
		segment["from"] = Codec.read_vector3(segment["from"])
		segment["to"] = Codec.read_vector3(segment["to"])
	return result

func _admission_native(value: Dictionary) -> Dictionary:
	if value.is_empty(): return {}
	var result: Dictionary = value.duplicate(true)
	result.exchange = _exchange_native(value.exchange)
	result.proof = _proof_native(value.proof)
	return result

func _opening_native(value: Dictionary) -> Dictionary:
	if value.is_empty(): return {}
	var result: Dictionary = value.duplicate(true)
	for field: String in ["ray", "foot"]:
		if value.has(field): result[field] = _exchange_native(value[field])
	if value.has("proof"): result.proof = _proof_native(value.proof)
	return result

func _intro_native(value: Dictionary) -> Dictionary:
	if value.is_empty(): return {}
	var result: Dictionary = value.duplicate(true)
	result.exchange = _exchange_native(value.exchange)
	if value.has("admission"): result.admission = _admission_native(value.admission)
	return result

func _apply_parent(value: Dictionary) -> void:
	_stage = value.stage
	_foot_started_once = value.foot_introduction_started
	_checkpoint_notice_sent = value.checkpoint_notice_sent
	_checkpoint_queued = value.notifications.checkpoint == "pending"
	_clear_queued = value.notifications.clear == "pending"
	_clear_notice_sent = value.notifications.clear == "delivered"
	_checkpoint_delivery_scheduled = false
	_clear_delivery_scheduled = false
	_ray_intro = _intro_native(value.ray_introduction)
	_foot_intro = _intro_native(value.foot_introduction)
	_threshold = value.threshold.duplicate(true)
	if not _threshold.is_empty(): _threshold.opening_receipt = _opening_native(value.threshold.opening_receipt)
	_defeat = value.defeat.duplicate(true)
	if not _defeat.is_empty(): _defeat.opening_receipt = _opening_native(value.defeat.opening_receipt)
	_phase_commit = value.phase_commit.duplicate(true)
	if not _phase_commit.is_empty(): _phase_commit.ray_exchange = _exchange_native(value.phase_commit.ray_exchange)
	_pair = value.pair.duplicate(true)
	if not _pair.is_empty():
		_pair.ray_exchange = _exchange_native(value.pair.ray_exchange)
		_pair.foot_exchange = _exchange_native(value.pair.foot_exchange)
		_pair.proof = _proof_native(value.pair.proof)
	_foot_cycle = int(value.foot_tracking.cycle)
	_foot_exchange = _exchange_native(value.foot_tracking.exchange)
	_foot_recovery_observed = _intro_native(value.foot_tracking.recovery_observed)
	_last_damage_gate = _opening_native(value.last_damage_gate)
	_foot_admission = _admission_native(value.foot_admission)
	_ray_admission = _admission_native(value.ray_admission)
	_completed_keys.clear()
	if not _foot_intro.is_empty(): _completed_keys["foot:%s" % _foot_intro.exchange.id] = true
	# Diagnostics are bounded reconstructed views, never portable authority.
	_accepted_cycles.clear()
	for admission: Dictionary in [_ray_admission, _foot_admission]:
		if not admission.is_empty(): _accepted_cycles.append({"kind": "ray" if admission.exchange.geometry.kind == "lane" else "foot", "stage": admission.stage, "cycle": admission.cycle, "admitted_exchange": admission.exchange.duplicate(true), "proof": admission.proof.duplicate(true)})
	set_physics_process(_stage != "dormant")

func _remember_ray_admission() -> void:
	if not is_instance_valid(_ray) or not is_instance_valid(_hero): return
	var current: Dictionary = _ray.call("state")
	if current.status != "running" or not current.armed or current.proof.is_empty(): return
	if not _ray_admission.is_empty() and _ray_admission.cycle == current.cycle: return
	_ray_admission = {"cycle": current.cycle, "stage": _stage, "exchange": current.exchange.duplicate(true), "proof": current.proof.duplicate(true), "equipment_ids": _hero.equipment.snapshot(), "bait_sample": current.bait_sample.duplicate(true)}

func _schedule_checkpoint_delivery() -> void:
	if _checkpoint_delivery_scheduled or not _checkpoint_queued or _restoring: return
	_checkpoint_delivery_scheduled = true
	_publish_checkpoint.call_deferred()

func _schedule_clear_delivery() -> void:
	if _clear_delivery_scheduled or not _clear_queued or _restoring: return
	_clear_delivery_scheduled = true
	_publish_clear.call_deferred()

func _resume_pending_notifications() -> void:
	if _restoring or _snapshotting or _validating or not _live() or get_tree().paused or _hero.dead: return
	_schedule_checkpoint_delivery()
	_schedule_clear_delivery()

func _restore_joint(value: Dictionary) -> bool:
	var blocked: bool = _joint.is_blocking_signals()
	_joint.set_block_signals(true)
	var accepted: bool = _joint.clear() if value.state == "clear" else _joint.present(value.state, value.trigger)
	_joint.set_block_signals(blocked)
	return accepted and _same_exact(_joint.state(), value)

static func _same_exact(left: Variant, right: Variant) -> bool:
	var encoded: String = ExactJson.stringify(left)
	return not encoded.is_empty() and encoded == ExactJson.stringify(right)

func _snapshot_plan_error(saved: Dictionary, bindings_value: Dictionary, player: Dictionary, scheduler: Dictionary, capture: bool = false) -> String:
	var error: String = Codec.value_error(saved)
	if error.is_empty(): error = Codec.keys_error(saved, PACK_KEYS)
	if not error.is_empty(): return error
	if saved.api_revision != SNAPSHOT_API or not Codec.is_integer(saved.schema_version, 1, 1) or not saved.clock_s is float: return "Closed exact B05 snapshot revision and copied float clock required"
	for key: String in ["configuration", "bait", "actor", "joint", "ray", "foot", "parent"]:
		if not saved[key] is Dictionary: return "B05 component must be a complete dictionary: " + key
	if player.is_empty() or scheduler.is_empty(): return "Full independently validated saved Player and whole Scheduler are mandatory"
	error = _hero.snapshot_error(player)
	if not error.is_empty(): return error
	var staged: Dictionary = _staged_bindings(bindings_value, player)
	error = _scheduler.snapshot_error(scheduler, staged)
	if not error.is_empty(): return error
	if saved.clock_s != scheduler.clock_s: return "Copied authoritative B05/Scheduler clock must be identical"
	var cfg: Dictionary = saved.configuration
	error = Codec.keys_error(cfg, CONFIG_KEYS)
	if not error.is_empty(): return error
	if not cfg.profile_id is String or Difficulty.new().profile(cfg.profile_id).is_empty(): return "Saved canonical profile must resolve independently of preference"
	if not _same_exact(cfg, _encode_configuration(bindings_value, cfg.profile_id)): return "Immutable whole host bindings/source/anchors/epoch/raw role/context differ"
	if not scheduler.encounter_id.is_empty() and (scheduler.encounter_id != cfg.encounter_id or scheduler.world_revision != cfg.world_revision or scheduler.profile.get("id") != cfg.profile_id): return "Same encounter epoch and saved fixed profile required"
	error = String(_bait.call("snapshot_error", saved.bait, player))
	if error.is_empty(): error = String(_actor.call("snapshot_error", saved.actor))
	if error.is_empty(): error = _joint_value_error(saved.joint)
	if not error.is_empty(): return error
	if not saved.actor.actor.hp is float or not saved.actor.actor.phase_progress is float or not saved.actor.actor.body_yaw is float or not _point(saved.actor.actor.root_position) or not _point(saved.actor.actor.direction): return "Exact native Actor scalar/vector representation required"
	var flat: Dictionary = {"api_revision": ActorScript.SOURCE_API, "source_id": SOURCE_ID, "root_position": saved.actor.actor.root_position, "armed": true, "phase_pending": saved.actor.transition_pending, "defeated": float(saved.actor.actor.hp) <= 0.0, "opening_state": saved.joint.state}
	error = String(_actor.call("source_snapshot_error", flat))
	if not error.is_empty(): return error
	if not _same_exact(saved.ray.get("source", {}), flat): return "Ray source is derived from complete saved Actor and actual composite cue policy"
	error = String(_ray.call("snapshot_error", saved.ray, staged, scheduler, player, saved.bait))
	if error.is_empty(): error = _foot.snapshot_error(saved.foot, staged, scheduler)
	if not error.is_empty(): return error
	var foot_role: Dictionary = Difficulty.new().resolve_role(FOOT_ROLE, cfg.profile_id, FOOT_FLOORS)
	if saved.foot.cycle > 0 and not _same_exact(saved.foot.resolved_role, foot_role): return "Foot resolved role must equal saved canonical profile exactly"
	if not scheduler.encounter_id.is_empty() and not _same_exact(scheduler.profile, Difficulty.new().profile(cfg.profile_id)): return "Saved full fixed profile must remain canonical"
	if saved.ray.clock_s != saved.clock_s or saved.foot.clock_s != saved.clock_s: return "All copied native clocks must remain exactly identical"
	if not _same_exact(saved.ray.configuration.context, cfg.context) or saved.ray.configuration.profile_id != cfg.profile_id or saved.ray.configuration.encounter_id != cfg.encounter_id or saved.ray.configuration.world_revision != cfg.world_revision: return "Native Ray configuration differs from whole parent"
	if saved.foot.configuration.mechanism_id != FOOT_ID or not _same_exact(saved.foot.configuration.raw_role, FOOT_ROLE) or not _same_exact(saved.foot.configuration.timing_floors, FOOT_FLOORS) or not _same_exact(saved.foot.configuration.geometry, {"kind": "circle", "origin": cfg.foot_anchor, "radius": FOOT_RADIUS}) or not _same_exact(saved.foot.configuration.opening_position, cfg.joint_anchor): return "Exact independently clocked Foot configuration required"
	error = _owned_scheduler_error(saved, scheduler, player)
	if not error.is_empty(): return error
	error = _parent_value_error(saved, player, scheduler, staged)
	if not error.is_empty(): return error
	# Validate the CURRENT native resources too, including on prospective fresh
	# recipients. A saved packet cannot silently repair a lost native cue mesh.
	error = _joint_native_error()
	if error.is_empty(): error = _threat_native_error(_ray.call("get_cue"))
	if error.is_empty(): error = _threat_native_error(_foot.get_cue())
	if not error.is_empty(): return error
	error = _current_consumer_cue_error()
	if not error.is_empty(): return error
	if capture:
		if not _same_exact(saved.actor, _actor.call("snapshot_state")) or not _same_exact(saved.joint, _joint.state()): return "Capture actual source and required composite cue before transport"
		if not _actor.visible or not _ray.visible or not _foot.visible or not _joint.visible: return "Explicitly hidden persistent source/cue cannot regain authority from capture"
	return ""

func _joint_value_error(value: Dictionary) -> String:
	var error: String = Codec.keys_error(value, ["api_revision", "state", "trigger", "required", "visible"])
	if not error.is_empty(): return error
	if value.api_revision != JointScript.API_REVISION or value.state not in ["clear", "available", "active", "spent"] or value.trigger != "attack" or value.required != true or not value.visible is bool or value.visible != (value.state != "clear"): return "Exact required attack-trigger composite cue state required"
	return ""

func _parent_value_error(saved: Dictionary, player: Dictionary, scheduler: Dictionary, staged: Dictionary) -> String:
	var value: Dictionary = saved.parent
	var error: String = Codec.keys_error(value, PARENT_KEYS)
	if not error.is_empty(): return error
	if value.stage not in STAGES or not value.foot_introduction_started is bool or not value.checkpoint_notice_sent is bool: return "Closed finite B05 parent stage/flags required"
	for field: String in ["notifications", "ray_introduction", "foot_introduction", "threshold", "phase_commit", "defeat", "pair", "foot_tracking", "last_damage_gate", "foot_admission", "ray_admission"]:
		if not value[field] is Dictionary: return "Finite B05 receipt dictionary required: " + field
	if not Codec.keys_error(value.notifications, ["checkpoint", "clear"]).is_empty() or value.notifications.checkpoint not in ["none", "pending", "delivered"] or value.notifications.clear not in ["none", "pending", "delivered"] or value.checkpoint_notice_sent != (value.notifications.checkpoint == "delivered"): return "Queued/delivered notification latches must be coherent"
	var now: float = saved.clock_s
	var ray: Dictionary = saved.ray.record
	var foot: Dictionary = saved.foot
	var body: Dictionary = saved.actor.actor
	var phase_two: bool = saved.actor.boss_phase == 2
	var pending: bool = saved.actor.transition_pending
	var dead: bool = player.resources.dead
	if dead and value.stage not in ["cancelled", "cleared"]: return "Dead Hero cannot retain an advancing encounter stage"
	if value.stage == "cancelled" and not dead: return "Healthy capture cannot legitimize a failed runtime cancellation"
	if dead and (ray.status == "running" or foot.status == "running"): return "Death closes both real native consumers before capture"
	if scheduler.encounter_id.is_empty() and (value.stage not in ["cleared", "cancelled"] or ray.status == "running" or foot.status == "running"): return "Ended epoch cannot retain active authority"
	if value.stage == "dormant":
		if body.hp != 30.0 or phase_two or pending or ray.cycle != 0 or foot.cycle != 0 or saved.bait.boundary not in ["", "sentry-entry"] or value.foot_introduction_started or value.notifications.checkpoint != "none" or value.notifications.clear != "none": return "Pristine dormant encounter cannot fabricate history"
		for key: String in ["ray_introduction", "foot_introduction", "threshold", "phase_commit", "defeat", "pair", "last_damage_gate", "foot_admission", "ray_admission"]:
			if not value[key].is_empty(): return "Pristine encounter cannot invent receipt: " + key
	elif saved.bait.boundary != ("sentry-phase-2" if phase_two else "sentry-entry"):
		# Host can die before its actual boss-entry contact seeds the untouched
		# first pool. Whole host separately binds empty versus seeded boundary
		# to earned contacts; this does not authorize a Ray or grant a phase.
		if not (dead and value.stage == "cancelled" and not phase_two and not pending and body.hp == 30.0 and ray.cycle == 0 and foot.cycle == 0 and saved.bait.boundary.is_empty()): return "Bait boundary must match the committed actor pool"
	if phase_two != (not value.phase_commit.is_empty()): return "Phase2 needs its actual drained boundary receipt"
	if (phase_two or pending) != (not value.threshold.is_empty()): return "Finite threshold receipt must match earned pending/phase2 pool"
	if not phase_two and value.stage in ["phase-two-checkpoint", "phase-two", "cleared"]: return "Second-phase stages need actual committed second pool"
	if phase_two and value.stage in ["ray-introduction", "foot-introduction", "await-first-brace"]: return "Committed second pool cannot return to first teaching stage"
	if (float(body.hp) <= 0.0) != (not value.defeat.is_empty()) or (value.stage == "cleared" and float(body.hp) != 0.0): return "Clear/defeat receipt must match actual finite actor death"
	if value.notifications.clear != "none" and value.defeat.is_empty(): return "No clear notification before actual second-pool defeat"
	if not value.defeat.is_empty() and value.notifications.clear == "none": return "Actual defeat retains a pending or delivered clear notification"
	if value.stage == "phase-two-checkpoint" and value.notifications.checkpoint == "none": return "Checkpoint stage retains its earned queued/delivered transaction"
	if value.notifications.checkpoint != "none" and value.phase_commit.is_empty(): return "No phase checkpoint notification before real phase commit"
	if not value.phase_commit.is_empty() and value.notifications.checkpoint == "none": return "Phase commit retains its one pending/delivered notification"
	if value.stage == "phase-two-checkpoint" and (ray.status == "running" or foot.status == "running" or body.hp != 15.0): return "Earned checkpoint boundary is drained and exactly15HP"
	if value.stage == "phase-two" and not value.checkpoint_notice_sent: return "Parent resumes phase2 only after delivery of earned boundary"
	if not value.ray_introduction.is_empty():
		error = _ray_intro_error(value.ray_introduction, saved, scheduler, staged, player)
		if not error.is_empty(): return error
	if not value.foot_introduction.is_empty():
		error = _foot_intro_error(value.foot_introduction, saved, scheduler, staged, player)
		if not error.is_empty(): return error
	if value.foot_introduction_started != (int(foot.cycle) > 0): return "One original Foot introduction flag must match actual adopted cycles"
	if value.foot_introduction_started and value.ray_introduction.is_empty(): return "Foot introduction follows real Ray recovery introduction"
	if not value.foot_introduction.is_empty() and not value.foot_introduction_started: return "Natural Foot receipt cannot predate its actual introduction"
	if (phase_two or pending) and value.ray_introduction.is_empty(): return "First threshold needs real recovery introduction"
	if phase_two and value.foot_introduction.is_empty(): return "First damage cannot skip the naturally complete Foot introduction"
	if value.stage == "foot-introduction" and value.ray_introduction.is_empty(): return "Teaching Foot stage needs its actual earlier Ray exposure"
	if value.stage == "await-first-brace" and value.foot_introduction.is_empty() and not value.foot_introduction_started: return "Awaiting first brace cannot skip actual Foot admission"
	if not value.threshold.is_empty():
		error = _damage_receipt_error(value.threshold, false, saved, scheduler, staged)
		if not error.is_empty(): return error
	if not value.phase_commit.is_empty():
		error = _phase_commit_error(value.phase_commit, saved, player, scheduler, staged)
		if not error.is_empty(): return error
	if not value.defeat.is_empty():
		error = _damage_receipt_error(value.defeat, true, saved, scheduler, staged)
		if not error.is_empty(): return error
	for field: String in ["foot_admission", "ray_admission"]:
		if not value[field].is_empty():
			error = _admission_error(value[field], "foot" if field == "foot_admission" else "ray", saved, scheduler, staged, player)
			if not error.is_empty(): return error
			if int(value[field].cycle) > int(foot.cycle if field == "foot_admission" else ray.cycle): return "Retained admission cannot exceed actual native cycle"
	if foot.cycle > 0 and (value.foot_admission.is_empty() or value.foot_admission.cycle != foot.cycle or not _same_exact(value.foot_admission.exchange, foot.exchange)): return "Current Foot retains original real proof/admission"
	if ray.status == "running" and ray.exchange.adapter.locked and not value.ray_admission.is_empty() and not _same_exact(ray.presentation_witness, {"landing": value.ray_admission.proof.landing, "attack_position": value.ray_admission.proof.attack_position}): return "Current armed Ray retains original accepted proof view"
	if ray.cycle > 0 and ray.exchange.adapter.locked and (value.ray_admission.is_empty() or value.ray_admission.cycle != ray.cycle or not _same_exact(value.ray_admission.exchange, ray.exchange)): return "Committed Ray retains original real proof/admission"
	error = _foot_tracking_error(value.foot_tracking, saved, scheduler)
	if not error.is_empty(): return error
	if not value.pair.is_empty():
		error = _pair_error(value.pair, saved, scheduler, staged)
		if not error.is_empty(): return error
	if value.stage not in ["phase-two", "cleared", "cancelled"] and not value.pair.is_empty(): return "Paired receipts belong only to phase2"
	if value.stage == "phase-two" and foot.status == "running" and value.pair.is_empty(): return "Actual paired Foot cannot lose its current parent cycle"
	if not value.last_damage_gate.is_empty():
		error = _opening_error(value.last_damage_gate, saved, scheduler, staged)
		if not error.is_empty(): return error
		if not value.last_damage_gate.has("hp_before") or not Codec.in_range(value.last_damage_gate.hp_before, 0.0000001, 30.0): return "Actual preceding gate retains positive finite source HP"
	var expected: String = _saved_joint_state(saved, player)
	if saved.joint.state != expected and not (expected == "available" and saved.joint.state == "clear"): return "Saved joint state must derive from exact native current windows, finite pool and full cadence"
	# Archived pair facts alone do not authorize a resumed source.
	if saved.joint.state == "available" and body.phase != "recovery": return "Actual ordinary-primary opening also needs saved recovery pose"
	return ""

func _exchange_error(value: Dictionary, kind: String, saved: Dictionary, scheduler: Dictionary) -> String:
	var keys: Array = RayScript.EXCHANGE_KEYS if kind == "ray" else FootScript.EXCHANGE_KEYS
	if not Codec.keys_error(value, keys).is_empty(): return "Closed copied native exchange fields required"
	if not value.id is String or not value.id.begins_with("threat-") or not value.id.substr(7).is_valid_int(): return "Native reservation serial required"
	var serial: int = int(value.id.substr(7))
	if not Codec.is_integer(serial, 1, int(scheduler.serial)) or value.id != "threat-%d" % serial or value.profile_id != saved.configuration.profile_id or value.world_revision != saved.configuration.world_revision: return "Historical exchange retains actual epoch/profile/serial"
	if not _point(value.source_position) or not _point(value.opening_position) or not _same_exact(value.opening_position, saved.configuration.joint_anchor): return "Finite original low-joint opening required"
	var shape: Variant = value.geometry
	if not shape is Dictionary: return "Original committed footprint required"
	if kind == "foot":
		if not _same_exact(value.source_position, saved.configuration.foot_anchor) or not _same_exact(shape, {"kind": "circle", "origin": saved.configuration.foot_anchor, "radius": FOOT_RADIUS}): return "Actual stationary Foot retains its immutable circle/source"
	else:
		if not Codec.keys_error(shape, ["kind", "from", "to", "radius"]).is_empty() or shape.kind != "lane" or shape.radius != RayScript.RADIUS or not _point(shape["from"]) or not _point(shape["to"]) or not _same_exact(shape["from"], saved.configuration.joint_anchor) or not _same_exact(value.source_position, shape["from"]): return "Actual Ray retains anchored full lane"
		var delta: Vector3 = Codec.read_vector3(shape["to"]) - Codec.read_vector3(shape["from"])
		if absf(delta.y) > POINT_EPSILON or absf(delta.length() - RayScript.REACH) > POINT_EPSILON: return "Native full3.8m Ray geometry required"
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not value[key] is float or not is_finite(value[key]) or value[key] < 0.0: return "Exact copied float deadlines required"
	if value.start_s > saved.clock_s: return "Executed exchange cannot begin in the future"
	var role: Dictionary = Difficulty.new().resolve_role(RayScript.RAW_ROLE if kind == "ray" else FOOT_ROLE, saved.configuration.profile_id, RayScript.TIMING_FLOORS if kind == "ray" else FOOT_FLOORS)
	var active: float = float(value.start_s) + float(role.windup_s)
	var lock_at: float = active - float(role.lock_s)
	if kind == "ray":
		if not value.adapter is Dictionary or not value.adapter.get("locked") is bool: return "Native tracking commitment marker required"
		var native_shape: Dictionary = _exchange_native(value).geometry
		var adapter: Dictionary = {"kind": "tracking", "locked": value.adapter.locked, "reach": (native_shape["to"] as Vector3).distance_to(native_shape["from"]), "radius": RayScript.RADIUS, "lock_s": role.lock_s, "active_s": role.active_s, "recovery_s": role.recovery_s, "attack_interval_s": role.attack_interval_s}
		if not _same_exact(adapter, value.adapter): return "Exact returned tracking adapter role required"
		if value.adapter.locked:
			if value.lock_from_s < lock_at - POINT_EPSILON or value.lock_from_s >= active - POINT_EPSILON: return "Returned full lock must retain genuine commit time"
			active = float(value.lock_from_s) + float(role.lock_s)
		elif value.lock_from_s != lock_at: return "Uncommitted Ray retains original provisional lock"
	elif value.lock_from_s != lock_at: return "Foot retains original fixed warning/lock timing"
	if value.active_from_s != active or value.active_until_s != active + float(role.active_s) or value.recovery_until_s != active + float(role.active_s) + float(role.recovery_s) or value.cooldown_until_s != active + float(role.attack_interval_s): return "Original complete native role deadlines cannot drift"
	return ""

func _point(value: Variant) -> bool:
	return Codec.is_vector3(value) and _same_exact(value, Codec.vector3(Codec.read_vector3(value)))

func _equipment_stats(value: Dictionary) -> Dictionary:
	if not Codec.keys_error(value, EquipmentScript.SLOTS).is_empty(): return {}
	var equipment: RefCounted = EquipmentScript.new()
	return equipment.call("resolved_stats") if equipment.call("restore", value) else {}

func _admission_error(value: Dictionary, kind: String, saved: Dictionary, scheduler: Dictionary, staged: Dictionary, player: Dictionary) -> String:
	if not Codec.keys_error(value, ADMISSION_KEYS).is_empty() or not Codec.is_integer(value.cycle, 1, int(scheduler.serial)) or value.stage not in ["ray-introduction", "foot-introduction", "await-first-brace", "phase-two"] or not value.exchange is Dictionary or not value.proof is Dictionary or not value.equipment_ids is Dictionary or not value.bait_sample is Dictionary: return "Closed real accepted cycle/proof/equipment receipt required"
	var error: String = _exchange_error(value.exchange, kind, saved, scheduler)
	if not error.is_empty(): return error
	if kind == "foot" and (not value.bait_sample.is_empty() or value.stage not in ["foot-introduction", "phase-two"]): return "Stationary Foot admission cannot invent Ray bait"
	if kind == "ray":
		if not value.exchange.adapter.locked: return "Ray admission proof follows actual armed lock commit"
		error = _admission_bait_error(value.bait_sample, value.exchange, saved, player)
		if not error.is_empty(): return error
	var threats: Array[Dictionary] = [value.exchange]
	return _proof_error(value.proof, value.equipment_ids, threats, value.exchange.lock_from_s if kind == "ray" else value.exchange.start_s, saved, staged)

func _admission_bait_error(value: Dictionary, exchange: Dictionary, saved: Dictionary, player: Dictionary) -> String:
	if not Codec.keys_error(value, RayScript.BAIT_KEYS).is_empty() or value.boundary not in ["sentry-entry", "sentry-phase-2"] or not _point(value.point) or not _point(value.initial_floor) or Codec.read_vector3(value.point).y != 0.0 or Codec.read_vector3(value.initial_floor).y != 0.0 or not Codec.is_integer(value.initial_sequence) or not Codec.is_integer(value.last_sequence, int(value.initial_sequence)) or not Codec.is_integer(value.dash_sequence, 0, int(value.last_sequence)) or not value.player_clock_s is float or value.player_clock_s < 0.0: return "Immutable complete real bait sample required"
	if value.last_sequence > player.world_actions.sequence or value.player_clock_s > player.world_actions.clock_s: return "Historical admission cannot consume future Player records or clock"
	for record: Dictionary in player.world_actions.history:
		if record.sequence == value.dash_sequence and not _same_exact(value.receipt, record): return "Historical bait must equal retained actual native dash identity"
		if record.sequence > value.initial_sequence and record.sequence <= value.last_sequence and record.kind == "dash" and record.sequence > value.dash_sequence: return "Historical sample cannot omit the latest consumed actual dash"
	var target: Vector3 = Codec.read_vector3(value.point)
	var origin: Vector3 = Codec.read_vector3(exchange.source_position)
	var delta: Vector3 = Vector3(target.x - origin.x, 0, target.z - origin.z)
	if delta.length_squared() <= POINT_EPSILON * POINT_EPSILON or delta.length() > RayScript.REACH + POINT_EPSILON: return "Actual sampled landing must direct a nonzero reachable full lane"
	var expected: Dictionary = Geometry.lane(origin, origin + delta.normalized() * RayScript.REACH, RayScript.RADIUS)
	if not _same_exact(exchange.geometry, _portable(expected)): return "Ray direction must derive from actual completed world-space bait landing"
	if value.receipt == null:
		if value.dash_sequence != 0 or not _same_exact(value.point, value.initial_floor): return "Initial bait cannot fabricate a dash"
	else:
		if not value.receipt is Dictionary: return "Completed bait receipt required"
		var error: String = CinderPlayer.world_action_record_error(value.receipt, value.player_clock_s)
		if not error.is_empty(): return error
		if value.receipt.kind != "dash" or value.receipt.sequence != value.dash_sequence or value.dash_sequence <= value.initial_sequence: return "Bait is one original completed native dash receipt"
		var landing: Vector3 = Codec.read_vector3(value.receipt.landing)
		if not _same_exact(value.point, Codec.vector3(Vector3(landing.x, 0, landing.z))): return "Bait cannot substitute projected swipe aim for native landing"
	if value.boundary == saved.bait.boundary:
		if not _same_exact(value.initial_floor, saved.bait.initial_floor) or value.initial_sequence != saved.bait.initial_sequence or value.last_sequence > saved.bait.last_sequence: return "Same boundary retains exact original seed/cursor"
	elif value.boundary != "sentry-entry" or saved.bait.boundary != "sentry-phase-2" or value.last_sequence > saved.bait.initial_sequence: return "Only original inactive entry bait may precede phase2 boundary"
	return ""

func _proof_error(value: Dictionary, gear: Dictionary, threats: Array[Dictionary], admitted_at: float, saved: Dictionary, staged: Dictionary) -> String:
	if not Codec.keys_error(value, PROOF_KEYS).is_empty() or value.accepted != true or value.uses_blast != false or value.uses_invulnerability != false or value.proof_scope != "static_box_floor_full_dash_stationary_primary" or not value.path is Array or value.path.size() not in [4, 6] or not _point(value.landing) or not _point(value.attack_position) or not value.primary_time_s is float or not value.response_complete_s is float: return "Original full ordinary-primary native proof required"
	var stats: Dictionary = _equipment_stats(gear)
	if stats.is_empty(): return "Proof equipment must resolve canonical implemented IDs"
	var kinds: Array[String] = ["recognition_and_ready", "escape_dash", "recovery_wait", "ordinary_primary"]
	if value.path.size() == 6: kinds = ["recognition_and_ready", "escape_dash", "recovery_wait", "positioning_dash", "primary_ready", "ordinary_primary"]
	var previous: Dictionary = {}
	for index: int in range(value.path.size()):
		var segment: Variant = value.path[index]
		if not segment is Dictionary or not Codec.keys_error(segment, ["from", "to", "start_s", "end_s", "kind"]).is_empty() or not _point(segment["from"]) or not _point(segment["to"]) or not segment.start_s is float or not segment.end_s is float or segment.start_s < admitted_at or segment.end_s < segment.start_s or segment.kind != kinds[index]: return "Full native proof requires finite ordered contiguous segments"
		if index == 0 and segment.start_s != admitted_at: return "Proof starts at original actual admission/commit clock"
		if not previous.is_empty() and (segment.start_s != previous.end_s or not _same_exact(segment["from"], previous["to"])): return "Proof cannot teleport or drift copied time boundaries"
		var a: Vector3 = Codec.read_vector3(segment["from"])
		var b: Vector3 = Codec.read_vector3(segment["to"])
		if segment.kind in ["escape_dash", "positioning_dash"]:
			if segment.end_s != float(segment.start_s) + float(stats.dash_duration) or absf(a.distance_to(b) - float(stats.dash_distance)) > POINT_EPSILON or absf(a.y - b.y) > POINT_EPSILON: return "Proof retains actual full fixed-distance dash and duration"
			var allowed: bool = false
			var field: String = "escape_directions" if segment.kind == "escape_dash" else "return_directions"
			for direction: Array in saved.configuration.context[field]:
				if (b - a).normalized().is_equal_approx(Codec.read_vector3(direction)): allowed = true
			if not allowed: return "Proof dash belongs to authored directions"
		else:
			if not _same_exact(segment["from"], segment["to"]): return "Stationary recognition/recovery/primary segments cannot move"
		if not _proof_floor_clear(a, b, staged): return "Original proof must retain supported native floor and collision-clear capsule"
		previous = segment
	if not _same_exact(value.landing, value.path[1]["to"]) or not _same_exact(value.attack_position, value.path[-1]["from"]) or value.primary_time_s != value.path[-1].start_s or value.response_complete_s != value.path[-1].end_s or value.response_complete_s != float(value.primary_time_s) + float(stats.primary_cooldown): return "Copied proof landing/primary/full cadence identity required"
	if value.path[1].start_s < admitted_at + float(saved.configuration.context.recognition_s): return "Recognition is part of the original response"
	if value.path.size() == 6 and value.path[3].start_s < float(value.path[1].start_s) + float(stats.dash_cooldown): return "Return dash retains full actual dash cooldown"
	var path: Array = _proof_native(value).path
	for threat: Dictionary in threats:
		if value.primary_time_s < float(threat.active_until_s) + CinderThreatScheduler.TIME_MARGIN or value.response_complete_s > float(threat.recovery_until_s) - CinderThreatScheduler.TIME_MARGIN: return "Full ordinary primary must fit every actual required recovery"
		if Geometry.timed_path_hits(_exchange_native(threat).geometry, path, threat.active_from_s, threat.active_until_s, CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN): return "Original full measured-shape timed response intersects committed threat union"
	var attack: Vector3 = Codec.read_vector3(value.attack_position)
	if Geometry.planar(attack).distance_to(Geometry.planar(_joint_anchor)) > float(stats.primary_range) - CinderThreatScheduler.SKIN or absf(attack.y - _joint_anchor.y) > 1.4: return "Actual low joint remains ordinary-primary reachable"
	var query := PhysicsRayQueryParameters3D.create(attack + Vector3.UP * 0.7, _joint_anchor + Vector3.UP * 0.7, 1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return "Original primary opening remains native unobstructed"
	return ""

func _ray_intro_error(value: Dictionary, saved: Dictionary, scheduler: Dictionary, staged: Dictionary, player: Dictionary) -> String:
	var keys: Array[String] = ["cycle", "exchange", "observed_recovery_clock_s", "closing", "admission"]
	if value.has("last_cancel_reason"): keys.append("last_cancel_reason")
	if not Codec.keys_error(value, keys).is_empty() or not Codec.is_integer(value.cycle, 1, int(saved.ray.record.cycle)) or not value.exchange is Dictionary or not value.admission is Dictionary or not value.observed_recovery_clock_s is float or value.closing not in ["still-running", "complete", "cancelled"]: return "Actual Ray introduction keeps bounded native cycle/recovery/closing facts"
	var error: String = _exchange_error(value.exchange, "ray", saved, scheduler)
	if error.is_empty(): error = _admission_error(value.admission, "ray", saved, scheduler, staged, player)
	if not error.is_empty(): return error
	if value.cycle != value.admission.cycle or not _same_exact(value.exchange, value.admission.exchange) or value.admission.stage != "ray-introduction" or value.observed_recovery_clock_s <= value.exchange.active_until_s or value.observed_recovery_clock_s > value.exchange.recovery_until_s or value.observed_recovery_clock_s > saved.clock_s: return "Genuine armed recovery exposure precedes first teaching receipt"
	if value.closing == "cancelled" and (not value.get("last_cancel_reason") is String or value.last_cancel_reason.is_empty()): return "Cancelled introduction retains cancellation reason, never manufactured completion"
	if value.closing == "complete" and (value.get("last_cancel_reason", "") != "" or saved.clock_s <= value.exchange.recovery_until_s): return "Complete introduction retains full original recovery"
	if value.closing == "still-running" and value.has("last_cancel_reason"): return "Running introduction cannot retain cancellation metadata"
	if value.cycle == saved.ray.record.cycle and (not _same_exact(value.exchange, saved.ray.record.exchange) or value.closing != ("still-running" if saved.ray.record.status == "running" else saved.ray.record.status)): return "Current introduction closing exactly matches native driver"
	return ""

func _foot_intro_error(value: Dictionary, saved: Dictionary, scheduler: Dictionary, staged: Dictionary, player: Dictionary) -> String:
	if not Codec.keys_error(value, ["cycle", "exchange", "observed_recovery_clock_s", "completed_clock_s", "closing", "admission"]).is_empty() or value.cycle != 1 or not value.exchange is Dictionary or not value.admission is Dictionary or not value.observed_recovery_clock_s is float or not value.completed_clock_s is float or value.closing != "complete": return "Exactly one naturally complete Foot introduction required"
	var error: String = _exchange_error(value.exchange, "foot", saved, scheduler)
	if error.is_empty(): error = _admission_error(value.admission, "foot", saved, scheduler, staged, player)
	if not error.is_empty(): return error
	if value.admission.cycle != 1 or value.admission.stage != "foot-introduction" or not _same_exact(value.exchange, value.admission.exchange) or value.observed_recovery_clock_s <= value.exchange.active_until_s or value.observed_recovery_clock_s > value.exchange.recovery_until_s or value.completed_clock_s <= value.exchange.recovery_until_s or value.completed_clock_s > saved.clock_s: return "Foot teaching retains actual recovery and natural end, not cancellation"
	if saved.foot.cycle == 1 and (saved.foot.status not in ["complete", "cancelled"] or not _same_exact(saved.foot.exchange, value.exchange)): return "Original Foot receipt matches actual retained native cycle"
	return ""

func _foot_tracking_error(value: Dictionary, saved: Dictionary, scheduler: Dictionary) -> String:
	if not Codec.keys_error(value, ["cycle", "exchange", "recovery_observed"]).is_empty() or not Codec.is_integer(value.cycle, 0, int(saved.foot.cycle)) or not value.exchange is Dictionary or not value.recovery_observed is Dictionary: return "Closed current Foot tracking receipt required"
	if saved.foot.cycle == 0: return "" if value.cycle == 0 and value.exchange.is_empty() and value.recovery_observed.is_empty() else "Unstarted Foot cannot invent history"
	if value.cycle != saved.foot.cycle or not _same_exact(value.exchange, saved.foot.exchange): return "Tracked Foot exchange/cycle must exactly equal native consumer"
	if not value.recovery_observed.is_empty():
		var observed: Dictionary = value.recovery_observed
		if not Codec.keys_error(observed, ["cycle", "exchange", "observed_recovery_clock_s"]).is_empty() or observed.cycle != value.cycle or not _same_exact(observed.exchange, value.exchange) or not observed.observed_recovery_clock_s is float or observed.observed_recovery_clock_s <= value.exchange.active_until_s or observed.observed_recovery_clock_s > value.exchange.recovery_until_s or observed.observed_recovery_clock_s > saved.clock_s: return "Current Foot recovery observation must retain genuine native window"
	return _exchange_error(value.exchange, "foot", saved, scheduler)

func _opening_error(value: Dictionary, saved: Dictionary, scheduler: Dictionary, staged: Dictionary) -> String:
	var keys: Array[String] = ["kind", "clock_s", "hp_before", "equipment_ids", "ray_cycle", "foot_cycle"]
	if value.get("kind") == "paired": keys.append_array(["ray", "foot", "proof"])
	elif value.get("kind") == "isolated-ray": keys.append("ray")
	elif value.get("kind") == "isolated-foot": keys.append("foot")
	else: return "Opening retains only actual isolated/paired known source kinds"
	if not Codec.keys_error(value, keys).is_empty() or not value.clock_s is float or not Codec.in_range(value.clock_s, 0.0, saved.clock_s) or not value.hp_before is float or not Codec.in_range(value.hp_before, 0.0000001, 30.0) or not value.equipment_ids is Dictionary or _equipment_stats(value.equipment_ids).is_empty() or not Codec.is_integer(value.ray_cycle, 0, int(saved.ray.record.cycle)) or not Codec.is_integer(value.foot_cycle, 0, int(saved.foot.cycle)): return "Actual accepted opening keeps clock/source HP/canonical equipment/cycles"
	var threats: Array[Dictionary] = []
	for field: String in ["ray", "foot"]:
		if value.has(field):
			if not value[field] is Dictionary or int(value[field + "_cycle"]) <= 0: return "Opening needs its actual native source cycle"
			var error: String = _exchange_error(value[field], field, saved, scheduler)
			if not error.is_empty(): return error
			if value.clock_s <= value[field].active_until_s or value.clock_s > value[field].recovery_until_s: return "Actual damage gate clock must lie in its original native recovery"
			threats.append(value[field])
		elif value[field + "_cycle"] != 0: return "Isolated gate cannot invent a second native source"
	if value.kind == "paired":
		if not value.proof is Dictionary: return "Paired gate retains original full response"
		var error: String = _proof_error(value.proof, value.equipment_ids, threats, value.ray.lock_from_s, saved, staged)
		if not error.is_empty(): return error
		var stats: Dictionary = _equipment_stats(value.equipment_ids)
		if float(value.clock_s) + float(stats.primary_cooldown) > minf(value.ray.recovery_until_s, value.foot.recovery_until_s) - CinderThreatScheduler.TIME_MARGIN: return "Actual late tap cannot exceed either full recovery cadence"
	return ""

func _damage_receipt_error(value: Dictionary, defeated: bool, saved: Dictionary, scheduler: Dictionary, staged: Dictionary) -> String:
	var keys: Array[String] = ["clock_s", "hp_before", "hp_after", "opening_receipt"]
	if not defeated: keys.append("actual_hp_loss")
	if not Codec.keys_error(value, keys).is_empty() or not value.clock_s is float or not Codec.in_range(value.clock_s, 0.0, saved.clock_s) or not value.hp_before is float or not Codec.in_range(value.hp_before, 0.0000001, 30.0) or value.hp_after != (0.0 if defeated else 15.0) or not value.opening_receipt is Dictionary: return "Actual finite pool receipt required"
	var error: String = _opening_error(value.opening_receipt, saved, scheduler, staged)
	if not error.is_empty(): return error
	if value.clock_s != value.opening_receipt.clock_s or value.hp_before != value.opening_receipt.hp_before or value.hp_before <= value.hp_after: return "Threshold/defeat is the actual preceding accepted native gate"
	if defeated:
		if value.hp_before > 15.0 or value.opening_receipt.kind != "paired" or value.clock_s < saved.parent.phase_commit.get("clock_s", INF): return "Second finite pool defeats only during its genuine paired return"
	else:
		if value.hp_before <= 15.0 or value.opening_receipt.kind == "paired" or value.actual_hp_loss != float(value.hp_before) - 15.0: return "First finite threshold retains actual isolated damage and cap"
	var stats: Dictionary = _equipment_stats(value.opening_receipt.equipment_ids)
	if float(value.hp_before) - float(value.hp_after) > float(stats.primary_damage): return "Accepted ordinary primary cannot invent excess finite pool damage"
	return ""

func _phase_commit_error(value: Dictionary, saved: Dictionary, player: Dictionary, scheduler: Dictionary, staged: Dictionary) -> String:
	if not Codec.keys_error(value, ["clock_s", "ray_cycle", "ray_exchange", "floor", "action_sequence", "bait", "ray_introduction_id", "foot_introduction_id", "threshold_clock_s"]).is_empty() or not value.clock_s is float or not Codec.in_range(value.clock_s, 0.0, saved.clock_s) or not Codec.is_integer(value.ray_cycle, 1, int(saved.ray.record.cycle)) or not value.ray_exchange is Dictionary or not _point(value.floor) or Codec.read_vector3(value.floor).y != 0.0 or not Codec.is_integer(value.action_sequence, 0, int(player.world_actions.sequence)) or not value.bait is Dictionary: return "Actual drained phase boundary receipt required"
	var error: String = _exchange_error(value.ray_exchange, "ray", saved, scheduler)
	if not error.is_empty(): return error
	if value.ray_introduction_id != saved.parent.ray_introduction.exchange.id or value.foot_introduction_id != saved.parent.foot_introduction.exchange.id or value.threshold_clock_s != saved.parent.threshold.clock_s or value.clock_s < value.threshold_clock_s or value.clock_s < saved.parent.foot_introduction.completed_clock_s: return "Phase commit follows exact original teaching and finite threshold receipts"
	for exchange: Dictionary in [value.ray_exchange, saved.parent.ray_introduction.exchange, saved.parent.foot_introduction.exchange]:
		if value.clock_s <= exchange.recovery_until_s or value.clock_s < exchange.cooldown_until_s: return "Phase boundary earns/drains original native recovery and cooldown"
	if saved.parent.threshold.opening_receipt.has("ray"):
		var threshold_ray: Dictionary = saved.parent.threshold.opening_receipt.ray
		if value.clock_s <= threshold_ray.recovery_until_s or value.clock_s < threshold_ray.cooldown_until_s or int(value.ray_exchange.id.substr(7)) < int(threshold_ray.id.substr(7)): return "Phase commit drains the latest actual threshold Ray"
	if not _same_exact(value.bait, {"version": 1, "boundary": "sentry-phase-2", "initial_floor": value.floor, "initial_sequence": value.action_sequence, "last_sequence": value.action_sequence, "landing": value.floor, "last_dash": null}): return "Committed phase2 bait is its actual new stable native boundary seed"
	if saved.bait.boundary != "sentry-phase-2" or saved.bait.initial_sequence != value.action_sequence or not _same_exact(saved.bait.initial_floor, value.floor): return "Current bait retains original phase2 boundary identity"
	if not _proof_floor_clear(Vector3(Codec.read_vector3(value.floor).x, Codec.read_vector3(player.motion.position).y, Codec.read_vector3(value.floor).z), Vector3(Codec.read_vector3(value.floor).x, Codec.read_vector3(player.motion.position).y, Codec.read_vector3(value.floor).z), staged): return "Committed boundary remains supported actual dry floor"
	return ""

func _pair_error(value: Dictionary, saved: Dictionary, scheduler: Dictionary, staged: Dictionary) -> String:
	if not Codec.keys_error(value, ["foot_cycle", "foot_exchange", "ray_cycle", "ray_exchange", "proof", "equipment", "validated"]).is_empty() or not Codec.is_integer(value.foot_cycle, 2, int(saved.foot.cycle)) or not Codec.is_integer(value.ray_cycle, 0, int(saved.ray.record.cycle)) or not value.foot_exchange is Dictionary or not value.ray_exchange is Dictionary or not value.proof is Dictionary or not value.equipment is Dictionary or not value.validated is bool: return "Exact current paired cycle receipt required"
	var error: String = _exchange_error(value.foot_exchange, "foot", saved, scheduler)
	if not error.is_empty(): return error
	if value.foot_cycle != saved.foot.cycle or not _same_exact(value.foot_exchange, saved.foot.exchange): return "Pair retains current actual Foot, never substitute an archived cycle"
	if not value.validated:
		if not value.ray_exchange.is_empty() or not value.proof.is_empty() or not value.equipment.is_empty(): return "Unvalidated pair cannot invent original response authority"
		if value.ray_cycle > 0 and (value.ray_cycle != saved.ray.record.cycle or saved.ray.record.exchange.get("adapter", {}).get("locked", false)): return "Unvalidated pair can retain only its current unarmed Ray warning"
		return ""
	if value.ray_cycle != saved.ray.record.cycle or not _same_exact(value.ray_exchange, saved.ray.record.exchange) or value.ray_cycle <= 0: return "Validated pair retains actual native Ray cycle/exchange"
	error = _exchange_error(value.ray_exchange, "ray", saved, scheduler)
	if not error.is_empty(): return error
	if not value.ray_exchange.adapter.locked or saved.parent.ray_admission.is_empty() or saved.parent.foot_admission.is_empty() or value.ray_cycle != saved.parent.ray_admission.cycle or value.foot_cycle != saved.parent.foot_admission.cycle or not _same_exact(value.proof, saved.parent.ray_admission.proof) or not _same_exact(value.equipment, saved.parent.ray_admission.equipment_ids): return "Paired witness is the original real accepted Ray response and canonical gear"
	error = _proof_error(value.proof, value.equipment, [value.ray_exchange, value.foot_exchange], value.ray_exchange.lock_from_s, saved, staged)
	if not error.is_empty(): return error
	if saved.ray.record.status == "running" and not _same_exact(saved.ray.record.presentation_witness, {"landing": value.proof.landing, "attack_position": value.proof.attack_position}): return "Original accepted pair witness matches current armed native Ray view"
	var due: bool = value.ray_exchange.start_s > value.foot_exchange.active_until_s if Difficulty.new().profile(saved.configuration.profile_id).reserved_threat_budget == 1 else value.ray_exchange.start_s >= value.foot_exchange.lock_from_s
	if not due: return "Real staggered admission respects saved profile budget and Foot lock/active release"
	return ""

func _saved_joint_state(saved: Dictionary, player: Dictionary) -> String:
	if saved.actor.transition_pending or saved.actor.actor.hp <= 0.0: return "spent"
	if player.resources.dead: return "clear"
	var p: Dictionary = saved.parent
	var r: Dictionary = saved.ray.record
	var f: Dictionary = saved.foot
	var now: float = saved.clock_s
	if p.stage == "phase-two":
		if p.pair.is_empty() or not p.pair.validated or not _same_exact(p.pair.equipment, player.equipment) or r.status != "running" or not r.exchange.adapter.locked or f.status != "running": return "clear"
		var stats: Dictionary = _equipment_stats(player.equipment)
		if now <= maxf(r.exchange.active_until_s, f.exchange.active_until_s) or now + float(stats.primary_cooldown) > minf(r.exchange.recovery_until_s, f.exchange.recovery_until_s) - CinderThreatScheduler.TIME_MARGIN: return "clear"
		return "available"
	if p.stage in ["ray-introduction", "await-first-brace"] and r.status == "running" and r.exchange.adapter.locked and r.phase == "recovery" and not p.ray_introduction.is_empty(): return "available"
	if p.stage == "foot-introduction" and f.status == "running" and f.phase == "recovery": return "available"
	return "clear"

func _proof_floor_clear(a: Vector3, b: Vector3, staged: Dictionary) -> bool:
	if not a.is_finite() or not b.is_finite() or absf(a.y - b.y) > POINT_EPSILON: return false
	var intervals: Array[Vector2] = []
	var start: Vector2 = Geometry.planar(a)
	var finish: Vector2 = Geometry.planar(b)
	var regions: Array[Dictionary] = []
	for id: String in _context_floor_ids():
		if not staged.floors.has(id): return false
		var region: Dictionary = staged.floors[id]
		regions.append(region)
		var rect: Rect2 = (region.safe_rect as Rect2).grow(-(CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN))
		var collision: CollisionShape3D = region.collision
		var top: float = collision.global_position.y + (collision.shape as BoxShape3D).size.y * 0.5
		if absf(a.y + CinderThreatScheduler.CAPSULE_CENTER_Y - CinderThreatScheduler.CAPSULE_HEIGHT * 0.5 - top) > CinderThreatScheduler.FEET_TOLERANCE: return false
		if rect.size.x <= 0.0 or rect.size.y <= 0.0: continue
		var interval := Vector2(0, 1)
		for axis: int in range(2):
			var movement: float = finish[axis] - start[axis]
			if absf(movement) <= POINT_EPSILON:
				if start[axis] < rect.position[axis] - POINT_EPSILON or start[axis] > rect.end[axis] + POINT_EPSILON:
					interval = Vector2(1, 0)
					break
			else:
				var first: float = (rect.position[axis] - start[axis]) / movement
				var last: float = (rect.end[axis] - start[axis]) / movement
				interval.x = maxf(interval.x, minf(first, last))
				interval.y = minf(interval.y, maxf(first, last))
		if interval.x <= interval.y: intervals.append(interval)
	intervals.sort_custom(func(left: Vector2, right: Vector2) -> bool: return left.x < right.x)
	var covered: float = 0.0
	for interval: Vector2 in intervals:
		if interval.x > covered + POINT_EPSILON: return false
		covered = maxf(covered, interval.y)
	if covered < 1.0 - POINT_EPSILON: return false
	var excluded: Array[RID] = [_hero.get_rid()]
	for region: Dictionary in regions: excluded.append((region.collision.get_parent() as StaticBody3D).get_rid())
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	for point: Vector3 in [a, b]:
		var probe := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.2, point - Vector3.UP * 0.2, 1)
		var hit: Dictionary = space.intersect_ray(probe)
		if hit.is_empty() or not excluded.has(hit.get("rid")) or hit.get("rid") == _hero.get_rid(): return false
	var capsule := CapsuleShape3D.new()
	capsule.radius = CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN
	capsule.height = CinderThreatScheduler.CAPSULE_HEIGHT + 2.0 * (CinderThreatScheduler.SKIN + CinderThreatScheduler.FEET_TOLERANCE)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.collide_with_areas = false
	query.exclude = excluded
	query.transform = Transform3D(Basis.IDENTITY, a + Vector3.UP * CinderThreatScheduler.CAPSULE_CENTER_Y)
	if not space.intersect_shape(query, 1).is_empty(): return false
	query.motion = b - a
	var fractions: PackedFloat32Array = space.cast_motion(query)
	if fractions.size() != 2 or float(fractions[0]) < 1.0 - POINT_EPSILON: return false
	query.transform.origin = b + Vector3.UP * CinderThreatScheduler.CAPSULE_CENTER_Y
	query.motion = Vector3.ZERO
	return space.intersect_shape(query, 1).is_empty()

func _context_floor_ids() -> Array[String]:
	var result: Array[String] = []
	for region: Dictionary in _context.floor_regions:
		for id: String in _floors:
			if region == _floors[id]: result.append(id)
	return result

func _material_error(node: MeshInstance3D, expected: Color, check_color: bool = true) -> String:
	if node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF or not node.material_override is StandardMaterial3D: return "Required cue mesh/material policy lost"
	var material: StandardMaterial3D = node.material_override
	if material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA or material.cull_mode != BaseMaterial3D.CULL_DISABLED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.no_depth_test or material.albedo_texture != null or material.render_priority != 0: return "Required cue retains original native alpha/depth/nearest policy"
	if check_color and material.albedo_color != expected: return "Required cue color/alpha changed outside original presentation"
	return ""

func _joint_native_error() -> String:
	if not _joint.visible: return "Actual composite cue cannot be explicitly hidden"
	var value: Dictionary = _joint.state()
	var error: String = _joint_value_error(value)
	if not error.is_empty(): return error
	var raw: Variant = _joint.get_node_or_null("RequiredInteractionMarker")
	if not raw is MeshInstance3D or not is_instance_valid(raw) or not raw.is_inside_tree() or raw.is_queued_for_deletion(): return "Actual required native joint marker missing"
	var marker: MeshInstance3D = raw
	if marker.transform != Transform3D(Basis.IDENTITY, Vector3.UP * 0.025) or marker.visible != value.visible: return "Joint marker native transform/visibility differs"
	var color := Color(0.88, 0.92, 0.82, 0.85)
	if value.state == "active": color = Color(1.0, 0.98, 0.87, 1.0)
	elif value.state == "spent": color = Color(0.64, 0.68, 0.65, 0.40)
	error = _material_error(marker, color, value.state != "clear")
	if not error.is_empty(): return error
	if value.state == "clear": return "" if marker.mesh == null else "Cleared joint cannot retain mesh authority"
	if marker.mesh == null or marker.mesh.get_faces() != CueMesh.interaction_mesh(value.state, value.trigger).get_faces(): return "Required joint geometry changed or cleared"
	return ""

func _threat_native_error(cue: Variant) -> String:
	if not cue is CinderThreatCue or not is_instance_valid(cue) or not cue.is_inside_tree() or cue.is_queued_for_deletion() or not cue.visible or cue.get_world_3d() != get_world_3d(): return "Actual required native threat cue missing/hidden"
	var value: Dictionary = cue.state()
	var clear: bool = value.phase == "clear"
	var color := Color(1.0, 0.90, 0.63, 0.95)
	if value.phase == "lock": color = Color(1.0, 0.76, 0.35, 1.0)
	elif value.phase == "active": color = Color(1.0, 0.43, 0.26, 1.0)
	elif value.phase == "recovery": color = Color(0.77, 0.88, 0.90, 0.70)
	if not clear and cue.global_transform != Transform3D(Basis.IDENTITY, CueMesh.anchor(value.geometry)): return "Native footprint anchor moved"
	for name: String in ["RequiredFootprintOutline", "RequiredFootprintFill", "RequiredSourceMarker"]:
		var raw: Variant = cue.get_node_or_null(name)
		if not raw is MeshInstance3D or not is_instance_valid(raw) or not raw.is_inside_tree() or raw.is_queued_for_deletion(): return "Required native threat mesh child missing"
		var mesh_node: MeshInstance3D = raw
		var expected_visible: bool = not clear and (value.source_visible if name == "RequiredSourceMarker" else (value.active_fill_visible if name == "RequiredFootprintFill" else value.footprint_visible))
		if mesh_node.visible != expected_visible: return "Required threat native visibility differs from actual state"
		var expected_color: Color = Color(color.r, color.g, color.b, 0.22) if name == "RequiredFootprintFill" else color
		var error: String = _material_error(mesh_node, expected_color, not clear)
		if not error.is_empty(): return error
		if clear:
			if mesh_node.mesh != null: return "Cleared threat cannot retain native geometry"
			continue
		var expected: Mesh = CueMesh.source_mesh(value.phase) if name == "RequiredSourceMarker" else CueMesh.geometry_mesh(value.geometry, name == "RequiredFootprintFill")
		if mesh_node.mesh == null or mesh_node.mesh.get_faces() != expected.get_faces(): return "Required threat geometry changed or cleared"
		var position: Vector3 = value.source_position - cue.global_position + Vector3.UP * 0.029 if name == "RequiredSourceMarker" else Vector3.UP * (0.021 if name == "RequiredFootprintFill" else 0.025)
		if mesh_node.transform != Transform3D(Basis.IDENTITY, position): return "Required threat mesh transform changed"
	return ""

# Signal custody is observed before host listeners receive the child handles.
# A direct required-cue callback cannot perform a source commit while the
# shared cue's public presentation transaction is still on its call stack.
func _on_required_cue_publication(_state: Dictionary) -> void:
	if _restoring: return
	_cue_publication_pending += 1
	_finish_required_cue_publication.call_deferred(_cue_publication_pending)

func _finish_required_cue_publication(token: int) -> void:
	if token == _cue_publication_pending: _cue_publication_pending = 0

func _current_consumer_cue_error() -> String:
	var current: Dictionary = _ray.call("state")
	var cue: Dictionary = _ray.call("get_cue").state()
	if current.status == "running":
		if cue.phase != current.phase or cue.geometry != current.geometry or cue.source_position != current.exchange.source_position or cue.source_visible != true or cue.footprint_visible != (current.phase != "recovery") or cue.active_fill_visible != (current.phase == "active"): return "Actual native Ray cue was cleared/replaced outside its consumer"
	elif cue.phase != "clear": return "Inactive actual Ray cannot retain presented danger"
	current = _foot.state()
	cue = _foot.get_cue().state()
	if current.status == "running":
		if cue.phase != current.phase or cue.geometry != current.geometry or cue.source_position != current.source_position or cue.source_visible != true or cue.footprint_visible != (current.phase != "recovery") or cue.active_fill_visible != (current.phase == "active"): return "Actual native Foot cue was cleared/replaced outside its consumer"
	elif cue.phase != "clear": return "Inactive actual Foot cannot retain presented danger"
	return ""

func _owned_scheduler_error(saved: Dictionary, scheduler: Dictionary, player: Dictionary) -> String:
	var foot: Dictionary = saved.foot
	var owned: Array[Dictionary] = []
	var cooldown: Dictionary = {}
	for reservation: Dictionary in scheduler.reservations:
		if reservation.source_id == FOOT_ID: owned.append(reservation)
	for entry: Dictionary in scheduler.cooldowns:
		if entry.source_id == FOOT_ID: cooldown = entry
	if foot.status == "running":
		if owned.size() != 1: return "Exactly one actual Foot owner lease required"
		for key: String in FootScript.EXCHANGE_KEYS:
			if not _same_exact(foot.exchange[key], owned[0][key]): return "Copied Foot lease/deadlines must exactly equal complete Scheduler"
		var sample: Dictionary = foot.hero_samples.hero
		if not sample.clock_s is float or sample.clock_s != saved.clock_s or not _same_exact(sample.position, player.motion.position): return "Copied Foot measured sample must equal complete saved Hero/clock"
	elif not owned.is_empty(): return "Inactive Foot cannot retain a scheduler lease"
	if foot.cycle > 0 and scheduler.encounter_id == saved.configuration.encounter_id and foot.exchange.cooldown_until_s > saved.clock_s and (cooldown.is_empty() or not _same_exact(cooldown.ready_s, foot.exchange.cooldown_until_s)): return "Copied Foot cancellation retains exact original future cooldown"
	if saved.ray.record.status == "running" and not _same_exact(saved.ray.record.sample.position, player.motion.position): return "Copied Ray measured sample must equal full saved Player feet exactly"
	return ""
