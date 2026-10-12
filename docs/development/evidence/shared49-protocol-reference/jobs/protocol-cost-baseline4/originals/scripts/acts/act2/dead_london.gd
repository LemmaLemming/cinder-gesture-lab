extends CinderLevel
## TMP ONLY concrete A2-L5 production-presentation derivative, not an accepted scene.
## Read ACT2_CONCEPT A2-L5, canonical research/levels.json and current level notes.
## One actual shared Hero, Effects, Scheduler, camera/input/HUD/Shell. No pickups,
## perks, ammo grant, gear allocation, new controls or artificial two-minute waits.
## Known prefix: TWO familiar Scouts and ONE rehearsed native circle footfall.
## A five-legged wreck is scenery. Parent B05 owns its actual actor, ray, foot,
## composite joint cue/gate, finite 15+15 HP, intro receipts and phase2 cadence.
##
## TMP strict whole local codec derivative. Parent codec V2 is required for
## legitimate seeded-before-start and pre-entry-death boundaries. Full native
## loading/save/Continue/Retry/cleanup and portrait checks remain PENDING. Never
## accept a partial packet or turn a diagnostic/view into admission authority.
## Geometry/positions/gates/source dressing are provisional; no engine, portrait,
## legal-kit/profile, physical-apron, balance or whole-level validation is claimed.
##
## Parent API (frozen codec V1 e66d5cf9; act2_source_review owns host codec):
## configure(hero,effects,scheduler,bait,world_root,floors,context,joint_at,foot_at,guard)
## start()->bool; state()->Dictionary; owners()->Dictionary; get_actor/get_ray/
## get_foot/get_joint_cue; resume_after_phase_checkpoint()->bool; cleanup()->void.
## Signals phase_checkpoint_eligible(receipts), sentry_cleared(receipts),
## runtime_failed(reason), hit_resolved(source_id,result). The eligible signal is
## AFTER actual phase2+supported-floor bait commit; host protects the checkpoint
## and resumes through public Shell, then admits phase2 via parent resume method.
## Host _sentry_required_points(proposal={}) reads existing parent native getters
## and actual Ray/Foot/cue state. It includes current AND explicit next full
## geometry/endcaps and genuine accepted landing/opening native Hero bounds.
## No extra parent/shared point API is required. Missing/hidden/queued required
## native nodes or malformed geometry/witnesses fail closed, without repairs.
## An ephemeral native-owner Foot preview view bridges its synchronous first
## warning before parent accepted_cycles publication; it is framing only. The
## future whole codec must rebind/validate this view, never serialize its Node.
## Full remote decorative supports must not dictate low-joint combat framing.
##
## Proposed closed local transport: stage, defeated_scouts, contacts, contact_seen,
## rehearsal_complete, sentry_started, phase2_checkpoint, passage_open, profile_id,
## world_revision, last_action_sequence, pending_checkpoints, completion_pending,
## exit_requested, pending_defeats/pending_phase2/pending_clear,
## phase2_admitted_after_checkpoint, gate_states, scheduler, familiar, rehearsal, rehearsal_view,
## sentry_foot_view (strict native owner rebind; not the ephemeral Node),
## bait, sentry. Player/input/focus/effects remain in the actual Shell packet.
## Native candidate construction must validate authored gate topology before
## building it; full Player -> actors/bait+cue -> Scheduler -> consumers -> quiet
## poses follows complete prospective preflight. Preserve pending native paths,
## all clocks/leases/cooldowns/hit latches/receipts/HP and earned corpse intents.
const ScoutActor: Script = preload("res://scripts/acts/act2/weybridge_scout_actor.gd")
const FamiliarExchange: Script = preload("res://scripts/acts/act2/ray_scout_exchange.gd")
const SchedulerScript: Script = preload("res://scripts/combat/threat_scheduler.gd")
const Mechanism: Script = preload("res://scripts/combat/lane_mechanism.gd")
const BaitScript: Script = preload("res://scripts/acts/act2/dead_london_bait.gd")
const FootVisual: Script = preload("res://scripts/acts/act2/giant_foot_visual.gd")
const DeadLondonKit: Script = preload("res://scripts/acts/act2/dead_london_kit.gd")
const SharedGame: Script = preload("res://scripts/game.gd")
const Heath: Script = preload("res://scripts/acts/act2/heath_kit.gd")
const PreContactGuard: Script = preload("res://scripts/acts/act2/ruined_house_bank_guard.gd")
const InteractionCue: Script = preload("res://scripts/cues/interaction_cue.gd")
const Geometry: Script = preload("res://scripts/combat/threat_geometry.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const PlayerScript: Script = preload("res://scripts/player.gd")
const ExactJson: Script = preload("res://scripts/campaign/exact_json.gd")
const Difficulty: Script = preload("res://scripts/combat/difficulty.gd")
const AdmissionEquipment: Script = preload("res://scripts/equipment.gd")
const CueMesh: Script = preload("res://scripts/cues/cue_mesh.gd")
const LOCAL_KEYS: Array[String] = ["stage", "defeated_scouts", "contacts", "contact_seen", "rehearsal_complete", "sentry_started", "phase2_checkpoint", "passage_open", "profile_id", "world_revision", "last_action_sequence", "pending_checkpoints", "completion_pending", "exit_requested", "pending_defeats", "pending_phase2", "pending_clear", "phase2_admitted_after_checkpoint", "gate_states", "scheduler", "familiar", "rehearsal", "rehearsal_view", "sentry_foot_view", "bait", "sentry"]
const CHECKPOINT_ORDER: Array[String] = ["dead-london-park-approach", "dead-london-before-sentry", "dead-london-sentry-phase-2", "dead-london-local-route-open"]
const OWN_CHECKPOINT_KINDS: Dictionary = {"dead-london-park-approach": "encounter", "dead-london-before-sentry": "encounter", "dead-london-sentry-phase-2": "boss_phase", "dead-london-local-route-open": "encounter"}
const SCOUT_ORDER: Array[String] = ["A2-L5:square-scout", "A2-L5:park-scout"]
const CONTACT_ORDER: Array[String] = ["second-square", "park-approach", "sentry-entry", "dead-martians", "inert-machines", "survivor-signal"]
const EPOCH: String = "A2-L5-dead-london"
const WORLD_REVISION: int = 1
const REHEARSAL_ID: String = "A2-L5:approach-foot"
const SENTRY_AT: Vector3 = Vector3(0, 0, -28.4)
const B05_FOOT_AT: Vector3 = Vector3(0.65, 0, -29.35)
const REHEARSAL_AT: Vector3 = Vector3(0.55, 0, -18.1)
const APRON_HERO_BOUNDS: Rect2 = Rect2(-2.2, -31.2, 4.4, 5.6)
const EXIT_REGION: Rect2 = Rect2(-2.7, -45.8, 5.4, 1.3)
const STAGES: Array[String] = ["empty-square-1", "empty-square-2", "park-checkpoint", "rehearsed-foot", "park-scout", "boss-entry", "sentry", "redoubt-piles", "redoubt-machines", "redoubt-dawn", "clear"]
const SCOUTS: Dictionary = {"A2-L5:square-scout": Vector3(-0.65, 0, -10.1), "A2-L5:park-scout": Vector3(-0.65, 0, -21.4)}
const FLOORS: Array[Dictionary] = [
	{"id": "square-1", "rect": Rect2(-3.4, -7.8, 6.8, 11.4)},
	{"id": "square-2", "rect": Rect2(-3.4, -15.5, 6.8, 8.5)},
	{"id": "park", "rect": Rect2(-3.4, -25.0, 6.8, 10.3)},
	{"id": "sentry-apron", "rect": Rect2(-3.4, -34.0, 6.8, 9.8)},
	{"id": "redoubt", "rect": Rect2(-3.4, -44.6, 6.8, 11.4)},
	{"id": "departure", "rect": Rect2(-3.4, -47.0, 6.8, 3.2)},
]
const CONTACTS: Dictionary = {
	"empty-square-1": {"id": "second-square", "region": Rect2(-2.8, -6.2, 5.6, 1.1)},
	"park-checkpoint": {"id": "park-approach", "region": Rect2(-2.8, -14.8, 5.6, 1.1), "checkpoint": "dead-london-park-approach"},
	"boss-entry": {"id": "sentry-entry", "region": Rect2(-2.1, -26.4, 4.2, 0.7), "checkpoint": "dead-london-before-sentry"},
	"redoubt-piles": {"id": "dead-martians", "region": Rect2(-2.8, -35.0, 5.6, 1.1)},
	"redoubt-machines": {"id": "inert-machines", "region": Rect2(-2.8, -39.0, 5.6, 1.1)},
	"redoubt-dawn": {"id": "survivor-signal", "region": Rect2(-2.8, -42.8, 5.6, 1.1)},
}
## Exact reused Weybridge rehearsal values, no invisible retune/new attack.
const REHEARSAL_ROLE: Dictionary = {"raw_damage": 4.0, "windup_s": 1.75, "lock_s": 1.1, "active_s": 0.2, "recovery_s": 1.6, "attack_interval_s": 1.8, "max_hp": 1.0, "move_speed": 0.0}
const REHEARSAL_FLOORS: Dictionary = {"windup_s": 1.75, "lock_s": 1.1, "recovery_s": 1.6}
@export var sentry_parent_script: Script
var runtime_error: String = ""
var _scheduler: CinderThreatScheduler
var _familiar: Node3D
var _rehearsal: CinderLaneMechanism
var _rehearsal_art: Node3D
var _approach_guard: Node
var _sentry: Node3D
var _bait: RefCounted
var _actors: Dictionary = {}
var _kit: Dictionary = {}
var _optional_meshes: Array[MeshInstance3D] = []
var _floor_records: Array[Dictionary] = []
var _gates: Dictionary = {}
var _contact_cues: Dictionary = {}
var _exit_cue: CinderInteractionCue
var _stage: int = 0
var _profile: String = "standard"
var _defeated: Array[String] = []
var _contacts: Array[String] = []
var _contact_seen: String = ""
var _rehearsal_complete: bool = false
var _rehearsal_view: Dictionary = {}
var _sentry_foot_view: Dictionary = {} # Ephemeral actual-preview view; no combat authority.
var _sentry_started: bool = false
var _phase2_checkpoint: bool = false
var _phase2_admitted_after_checkpoint: bool = false
var _passage_open: bool = false
var _last_action_sequence: int = 0
var _pending_defeats: Array[String] = []
var _pending_phase2: bool = false
var _pending_clear: bool = false
var _pending_checkpoints: Array[Dictionary] = []
var _completion_pending: bool = false
var _exit_requested: bool = false
var _construction_profile: String = ""
var _quiet_projection: bool = false
var _local_cue_publications: int = 0
var _local_cue_token: int = 0

func _ready() -> void:
	process_physics_priority = 110
	_build_ground_and_props()
	set_physics_process(false)

func _on_enter_level() -> void:
	if not _construction_profile.is_empty(): _profile = _construction_profile
	elif is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference"): _profile = String(shared_shell.call("get_difficulty_preference"))
	_scheduler = SchedulerScript.new()
	_scheduler.name = "OneDeadLondonScheduler"
	add_child(_scheduler)
	if not _scheduler.begin_encounter(_profile, EPOCH, WORLD_REVISION): _fault(_scheduler.last_error); return
	for id: String in SCOUTS:
		var actor: Node3D = ScoutActor.new() as Node3D
		actor.name = "Familiar_" + id.replace(":", "_")
		actor.position = SCOUTS[id]
		add_child(actor)
		if not bool(actor.call("configure", hero, effects, id)): _fault("Cannot bind familiar actual Scout " + id); return
		_actors[id] = actor
	_familiar = FamiliarExchange.new() as Node3D
	_familiar.name = "TwoKnownScouts"
	add_child(_familiar)
	if not bool(_familiar.call("configure", hero, effects, _scheduler, _actors, _profile, _response_context())): _fault(String(_familiar.get("last_error"))); return
	if not bool(_familiar.call("set_response_context_provider", _response_context)) or not bool(_familiar.call("set_presentation_guard", _scout_guard)): _fault("Cannot retain familiar public context/presentation providers"); return
	_familiar.connect("scout_defeated", _on_scout_defeated)
	_rehearsal = Mechanism.new()
	_rehearsal.name = "OneApproachFootConsumer"
	_rehearsal.position = REHEARSAL_AT
	add_child(_rehearsal)
	if not _rehearsal.configure(REHEARSAL_ID, Geometry.circle(REHEARSAL_AT, 0.85), REHEARSAL_AT, REHEARSAL_ROLE, REHEARSAL_FLOORS) or not _rehearsal.bind(_scheduler, {"hero": hero}): _fault(_rehearsal.last_error); return
	_rehearsal_art = FootVisual.new() as Node3D
	_rehearsal_art.name = "KnownApproachFoot"
	_rehearsal_art.position = REHEARSAL_AT
	add_child(_rehearsal_art)
	_rehearsal.state_changed.connect(_on_rehearsal_state)
	_rehearsal.hit_resolved.connect(_on_rehearsal_hit)
	_rehearsal_art.call("pose", "idle", 0.0, Vector3.BACK, false)
	_rehearsal_art.visible = false
	_approach_guard = PreContactGuard.new()
	_approach_guard.name = "ApproachPresentationBeforeContact99"
	_approach_guard.call("configure", Callable(self, "_guard_approach"))
	add_child(_approach_guard)
	_bait = BaitScript.new()
	if not bool(_bait.call("bind", hero)): _fault("Cannot bind actual completed-dash cache"); return
	if sentry_parent_script != null:
		_sentry = sentry_parent_script.new() as Node3D
		if _sentry == null: _fault("B05 parent must be one Node3D"); return
		_sentry.name = "OnePersistentB05Parent"
		add_child(_sentry)
		if not _parent_api_present(): _fault("TODO agreed B05 parent/optical API is incomplete"); return
		if not bool(_sentry.call("configure", hero, effects, _scheduler, _bait, actual_world_root(), floor_bindings(), _response_context(), SENTRY_AT, B05_FOOT_AT, Callable(self, "_sentry_guard"))): _fault("Cannot bind the actual B05 parent"); return
		var parent_owners: Dictionary = _sentry.call("owners")
		for id: String in parent_owners:
			if _actors.has(id) or id == REHEARSAL_ID: _fault("B05 native owner identity conflicts with the actual prefix"); return
		if not bool(_sentry.call("bind_transport_scope", scheduler_bindings())): _fault("Cannot bind complete actual host owner/floor scope"); return
		var ray: Node3D = _sentry.call("get_ray")
		if not bool(ray.call("set_response_context_provider", _response_context)): _fault("Cannot retain actual bait-ray view context"); return
		_sentry.connect("phase_checkpoint_eligible", _on_phase2_eligible)
		_sentry.connect("sentry_cleared", _on_sentry_cleared)
		_sentry.connect("runtime_failed", _fault)
	var existing: Array[Dictionary] = hero.get_world_action_records()
	_last_action_sequence = int(existing.back().sequence) if not existing.is_empty() else 0
	hero.world_action_executed.connect(_on_world_action)
	hero.died.connect(_on_hero_died)
	_derive_presentation()
	set_physics_process(true)

func _parent_api_present() -> bool:
	for method: String in ["configure", "start", "state", "owners", "get_actor", "get_ray", "get_foot", "get_joint_cue", "resume_after_phase_checkpoint", "bind_transport_scope", "snapshot_state", "snapshot_error", "restore_source_state", "restore_consumers_state", "project_native_cosmetics", "cleanup"]:
		if not _sentry.has_method(method): return false
	for name: String in ["phase_checkpoint_eligible", "sentry_cleared", "runtime_failed"]:
		if not _sentry.has_signal(name): return false
	return true

func _physics_process(_delta: float) -> void:
	if not _entered or get_tree().paused or _restoring or _validating or _snapshotting or not runtime_error.is_empty(): return
	if not _native_prefix_valid(): _fault("Required L5 native binding/source/floor was lost"); return
	_pose_rehearsal(_rehearsal.state())
	if hero.dead: return
	_flush_native_intents()
	_flush_progress_requests()
	if not _entered or not runtime_error.is_empty() or _pause_pending(): return
	_derive_presentation()
	var beat: String = STAGES[_stage]
	if beat == "clear":
		if is_completed() and not _exit_requested and _hero_contacts(EXIT_REGION):
			_exit_requested = true
			_exit_cue.present("active", "contact")
			request_contact_exit("dead-london-to-act3", hero) # TODO integration registers actual A3-L1 destination.
		return
	if CONTACTS.has(beat):
		if _hero_contacts(CONTACTS[beat].region): _contact_seen = beat
		if _contact_seen == beat and _supported_stable(): _commit_contact(beat)
		return
	if beat in ["empty-square-2", "park-scout"]:
		var id: String = "A2-L5:square-scout" if beat == "empty-square-2" else "A2-L5:park-scout"
		var actor: Node3D = _actors[id]
		if hero.global_position.distance_to(actor.global_position) <= 3.8 and String(_familiar.call("state", id).status) != "running": _familiar.call("activate", id)
	elif beat == "rehearsed-foot":
		_activate_rehearsal()
		if _rehearsal.state().status == "complete":
			_rehearsal_complete = true
			_rehearsal_view.clear()
			_stage = 4
	elif beat == "sentry":
		if not is_instance_valid(_sentry): _fault("TODO inject the finite B05 parent before boss-entry promotion"); return
		if not _sentry_started and _gate_closed("entry") and _supported_stable() and APRON_HERO_BOUNDS.has_point(Vector2(hero.global_position.x, hero.global_position.z)):
			if bool(_sentry.call("start")): _sentry_started = true
		if _phase2_checkpoint and not _phase2_admitted_after_checkpoint:
			# Pausable level physics cannot observe the paused interval itself.
			# Read only public Attempts.state to verify the actual protected
			# checkpoint, after the Shell's ordinary resume. No timer/private ops.
			if _phase2_checkpoint_protected() and _supported_stable():
				_phase2_admitted_after_checkpoint = bool(_sentry.call("resume_after_phase_checkpoint"))

func _commit_contact(beat: String) -> void:
	if beat == "boss-entry":
		if not _rehearsal_complete or _defeated.size() != 2 or not _scheduler.reservations().is_empty() or not is_instance_valid(_sentry): _fault("Boss entry requires genuine prefix recovery/defeats and complete B05 binding"); return
		if not APRON_HERO_BOUNDS.has_point(Vector2(hero.global_position.x, hero.global_position.z)): return
		if not _gate_closed("entry"):
			_set_gate("entry", true)
			return # One actual native topology barrier, not an authored idle wait.
		if not bool(_bait.call("begin_boundary", "sentry-entry")): _fault("Cannot seed bait at actual stable supported boss entry"); return
	_contacts.append(CONTACTS[beat].id)
	_contact_seen = ""
	_stage += 1
	if CONTACTS[beat].has("checkpoint"): _pending_checkpoints.append({"id": CONTACTS[beat].checkpoint, "kind": "encounter"})
	if beat == "redoubt-dawn": _completion_pending = true
	_derive_presentation()

func _on_scout_defeated(id: String) -> void:
	if _entered and not _restoring and not _defeated.has(id) and not _pending_defeats.has(id): _pending_defeats.append(id)

func _on_phase2_eligible(_receipts: Dictionary) -> void:
	# Parent has ALREADY committed real phase2/bait after actual isolated
	# recoveries and first-pool damage. No fake introduction/HP/phase seed here.
	if _entered and not _restoring: _pending_phase2 = true

func _on_sentry_cleared(_receipts: Dictionary) -> void:
	if _entered and not _restoring: _pending_clear = true

func _flush_native_intents() -> void:
	# Native damage/reload/publication callbacks have returned before root110.
	# If a second source killed Hero, retain intents for dead aggregate TODO;
	# never grant new corpse progression or overwrite the protected checkpoint.
	for id: String in _pending_defeats:
		var expected: String = "A2-L5:square-scout" if _stage == 1 else ("A2-L5:park-scout" if _stage == 4 else "")
		if id != expected or not _actors.has(id) or float(_actors[id].get("hp")) != 0.0: _fault("Unexpected real Scout defeat for authored L5 prefix"); return
		_defeated.append(id)
		_stage += 1
	_pending_defeats.clear()
	if _pending_phase2:
		if _stage != 6 or _phase2_checkpoint or not _sentry_started: _fault("Unexpected B05 phase checkpoint intent"); return
		_pending_phase2 = false
		_phase2_checkpoint = true
		_pending_checkpoints.append({"id": "dead-london-sentry-phase-2", "kind": "boss_phase"})
	if _pending_clear:
		if _stage != 6 or not _phase2_checkpoint or not _scheduler.reservations().is_empty(): _fault("Passage requires actual finite B05 clear and drained native threats"); return
		_pending_clear = false
		_set_gate("departure", false)
		if _gate_closed("departure"): _pending_clear = true; return
		_passage_open = true
		_stage = 7
		_pending_checkpoints.append({"id": "dead-london-local-route-open", "kind": "encounter"})

func _flush_progress_requests() -> void:
	if hero.dead or _restoring or _validating or _snapshotting or not _entered: return
	while not _pending_checkpoints.is_empty():
		var request: Dictionary = _pending_checkpoints.pop_front()
		if not request_checkpoint(request.id, request.kind): _fault("Cannot request earned checkpoint " + request.id); return
		if _pause_pending(): return
	if _completion_pending:
		if _stage != 10 or not _passage_open or _contacts.size() != CONTACTS.size() or not _scheduler.reservations().is_empty(): _fault("Act clear needs all quiet discovery contacts and harmless native state"); return
		_scheduler.end_encounter("dead-london-discovery-complete")
		_completion_pending = false
		request_completion("dead-london-discovery")

func _on_world_action(notification: Dictionary) -> void:
	if not _entered or _restoring or _validating or _snapshotting: return
	# Bait's owned real-history drain handles nested delivery; host connects
	# once and never substitutes attack aim/finger coordinates for a landing.
	if not _bait.call("sample_for_ray").is_empty() and not bool(_bait.call("observe_record", notification)): _fault("Actual bait refused a published native event"); return
	var clock: float = hero.get_world_action_clock()
	var records: Array[Dictionary] = hero.get_world_action_records(_last_action_sequence)
	var genuine: bool = false
	var encoded: Dictionary = PlayerScript.encode_world_action_record(notification, clock)
	for record: Dictionary in records:
		if record.sequence == notification.get("sequence") and PlayerScript.encode_world_action_record(record, clock) == encoded: genuine = true
	if not genuine: return
	for record: Dictionary in records:
		if int(record.sequence) != _last_action_sequence + 1: _fault("Actual native prefix history is not contiguous"); return
		_last_action_sequence = int(record.sequence)
		var beat: String = STAGES[_stage]
		if record.kind == "dash" and CONTACTS.has(beat):
			var path: Array = record.path
			for index: int in range(1, path.size()):
				if _segment_contacts(Geometry.planar(path[index - 1].position), Geometry.planar(path[index].position), CONTACTS[beat].region): _contact_seen = beat

func _activate_rehearsal() -> void:
	if _rehearsal.state().status == "running" or hero.global_position.distance_to(REHEARSAL_AT) > 3.8: return
	var preview: Dictionary = _rehearsal.preview_start("hero", _response_context())
	if not preview.get("accepted", false): return
	var points: Array[Vector3] = _mesh_points(_rehearsal_art)
	points.append_array(_shape_points(Geometry.circle(REHEARSAL_AT, 0.85)))
	for key: String in ["landing", "attack_position"]: points.append_array(_landing_points(preview.proof[key]))
	_rehearsal_view = {"landing": preview.proof.landing, "attack_position": preview.proof.attack_position}
	if not _framed(points): _rehearsal_view.clear(); return
	var answer: Dictionary = _rehearsal.start("hero", _response_context(), null, null, preview)
	if not answer.get("accepted", false) or _rehearsal.state().status != "running": _rehearsal_view.clear()
	else: _rehearsal_view = {"cycle": _rehearsal.state().cycle, "reservation_id": answer.reservation_id, "landing": answer.proof.landing, "attack_position": answer.proof.attack_position, "primary_time_s": answer.proof.primary_time_s, "response_complete_s": answer.proof.response_complete_s, "equipment_ids": hero.equipment.snapshot()}

func _on_rehearsal_state(state: Dictionary) -> void:
	if state.status != "running": _rehearsal_view.clear()
	if _entered: _pose_rehearsal(state)
	if _entered and state.status == "running" and not _rehearsal_framed(state): _rehearsal.cancel("approach_required_presentation_lost")

func _on_rehearsal_hit(_hero_id: String, _cycle: int, _result: Dictionary) -> void:
	if _entered: _pose_rehearsal(_rehearsal.state())

func _pose_rehearsal(state: Dictionary) -> void:
	if not is_instance_valid(_rehearsal_art): return
	_rehearsal_art.visible = _stage == 3 and state.status in ["idle", "running", "cancelled"]
	var phase: String = "idle" if state.phase == "clear" else String(state.phase)
	var progress: float = 0.0
	if state.status == "running":
		var interval: float = float(state.resolved_role.get({"warning": "windup_s", "lock": "lock_s", "active": "active_s", "recovery": "recovery_s"}.get(state.phase, ""), 0.0))
		if state.phase == "warning": interval -= float(state.resolved_role.lock_s)
		if interval > 0.0: progress = clampf(1.0 - float(state.remaining_s) / interval, 0.0, 1.0)
	_rehearsal_art.call("pose", phase, progress, Vector3.BACK, false)

func _guard_approach() -> void:
	if not _entered or get_tree().paused or _restoring or _validating or _snapshotting or not is_instance_valid(_rehearsal): return
	var state: Dictionary = _rehearsal.state()
	if state.status == "running" and not _rehearsal_framed(state): _rehearsal.cancel("approach_required_presentation_before_contact")

func _rehearsal_framed(state: Dictionary) -> bool:
	var points: Array[Vector3] = _mesh_points(_rehearsal_art)
	points.append_array(_mesh_points(_rehearsal.get_cue()))
	for key: String in ["landing", "attack_position"]:
		if _rehearsal_view.get(key) is Vector3: points.append_array(_landing_points(_rehearsal_view[key]))
	return state.status != "running" or _framed(points)

func _scout_guard(id: String, state: Dictionary) -> bool:
	if not _entered or not _actors.has(id): return false
	return _framed(_familiar_required_points(id, state))

func _familiar_required_points(id: String, state: Dictionary) -> Array[Vector3]:
	# Same actual set feeds the shared follow plan and current custody guard.
	var points: Array[Vector3] = _mesh_points(_actors[id])
	points.append_array(_mesh_points(_familiar.call("get_cue", id)))
	points.append_array(_mesh_points(_familiar.call("get_opening_cue", id)))
	if state.get("phase") != "recovery": points.append_array(_shape_points(state.get("geometry", state.get("exchange", {}).get("geometry", {}))))
	var witness: Dictionary = state.get("proof", {}) if state.get("proof_available", false) else state.get("presentation_witness", {})
	for key: String in ["landing", "attack_position"]:
		if witness.get(key) is Vector3: points.append_array(_landing_points(witness[key]))
	return points

func _sentry_guard(proposed: Dictionary) -> bool:
	var points: Array[Vector3] = _sentry_required_points(proposed)
	if points.is_empty() or not _sentry_points_framed(points, proposed) or _sentry_framing_handles().is_empty():
		_sentry_foot_view.clear()
		return false
	var preview: Dictionary = proposed.get("foot_preview", {})
	if not preview.is_empty():
		# Start publishes warning before parent records answer.proof. Retain the
		# actual accepted preview solely as a view witness for that callback.
		var foot: CinderLaneMechanism = _sentry.call("get_foot")
		_sentry_foot_view = {"owner": foot, "cycle": int(foot.state().cycle) + 1, "geometry": preview.candidate.geometry.duplicate(true), "source_position": preview.candidate.source_position, "opening_position": preview.candidate.opening_position, "landing": preview.proof.landing, "attack_position": preview.proof.attack_position}
	elif _sentry.call("get_foot").state().status != "running": _sentry_foot_view.clear()
	return true

func _sentry_required_points(proposal: Dictionary = {}) -> Array[Vector3]:
	# Pure actual-world framing only: no lease query, event, pose/camera repair,
	# input mutation or combat authority. Candidate-only hidden ancestors outside
	# this native world root are allowed; owned local visibility is still required.
	var native: Dictionary = _sentry_framing_handles()
	if native.is_empty(): return []
	if not proposal.is_empty():
		if not Codec.keys_error(proposal, ["actor", "ray", "ray_cue", "foot", "foot_preview", "foot_cue", "foot_visual", "joint", "hero", "stage", "pair"]).is_empty(): return []
		for key: String in ["actor", "ray_cue", "foot_cue", "foot_visual", "joint", "hero"]:
			if proposal[key] != native[key]: return []
		if not proposal.ray is Dictionary or not proposal.foot is Dictionary or not proposal.foot_preview is Dictionary or proposal.foot != native.foot_state: return []
	var points: Array[Vector3] = []
	# Pure native useful-source containers of the actual authored three-legged
	# rig: hood, generator/mirror and reachable brace. Remote legs are scenic.
	if not native.actor.has_method("get_cosmetic_rig"): return []
	var rig: Variant = native.actor.call("get_cosmetic_rig")
	if not _sentry_native_visible(rig) or not rig.has_method("required_source_nodes"): return []
	var parts: Variant = rig.call("required_source_nodes")
	if not parts is Array or parts.size() != 3: return []
	for part: Variant in parts:
		if not _sentry_native_visible(part) or not rig.is_ancestor_of(part): return []
		var source: Array[Vector3] = _mesh_points(part)
		if source.is_empty(): return []
		points.append_array(source)
	var foot_source: Array[Vector3] = _mesh_points(native.foot_visual)
	if foot_source.is_empty(): return []
	points.append_array(foot_source)
	var hero_points: Array[Vector3] = _sentry_actual_hero_points()
	if hero_points.is_empty(): return []
	points.append_array(hero_points)
	if not _sentry_threat_points(native.ray_state, native.ray_cue, native.actor.global_position, "lane", points): return []
	if not _sentry_threat_points(native.foot_state, native.foot_cue, native.foot_owner.global_position, "circle", points): return []
	var joint_state: Dictionary = native.joint.state()
	if joint_state.get("state") not in ["clear", "available", "active", "spent"] or joint_state.get("required") != true or joint_state.get("trigger") != "attack" or joint_state.get("visible") != (joint_state.state != "clear"): return []
	var joint_mesh: Variant = native.joint.get_node_or_null("RequiredInteractionMarker")
	if not _sentry_expected_mesh(joint_mesh, joint_state.state != "clear"): return []
	points.append_array(_mesh_points(native.joint))
	if native.ray_state.status == "running" and not _sentry_ray_witness_points(native.ray_state, hero_points, points): return []
	if native.foot_state.status == "running":
		var view: Dictionary = _sentry_current_foot_view(native)
		if not _sentry_view_points(view, hero_points, points): return []
	if not proposal.is_empty():
		# Ray replaces only its proposed geometry. Always retain the actual current
		# capsule above too; an earlier cycle cannot approve a next direction.
		var incoming: Dictionary = proposal.ray
		if not incoming.get("geometry", {}) is Dictionary or not incoming.get("exchange", {}) is Dictionary: return []
		var shape: Dictionary = incoming.get("geometry", {})
		if incoming.get("status") == "running" or not shape.is_empty():
			if not _sentry_shape_points(shape, native.actor.global_position, "lane", points): return []
			if incoming.exchange.has("geometry") and incoming.exchange.geometry != shape: return []
			if not _sentry_ray_witness_points(incoming, hero_points, points): return []
		var preview: Dictionary = proposal.foot_preview
		if not preview.is_empty():
			if preview.get("accepted") != true or not preview.get("candidate") is Dictionary or not preview.get("proof") is Dictionary: return []
			var candidate: Dictionary = preview.candidate
			if candidate.get("source_instance_id") != native.foot_owner.get_instance_id() or candidate.get("source_position") != native.foot_owner.global_position or candidate.get("opening_position") != native.actor.global_position or candidate.get("profile_id") != _profile or candidate.get("world_revision") != WORLD_REVISION: return []
			if not candidate.get("geometry") is Dictionary or not _sentry_shape_points(candidate.geometry, native.foot_owner.global_position, "circle", points): return []
			if preview.proof.get("accepted") != true or not _sentry_view_points(preview.proof, hero_points, points): return []
	var unique: Array[Vector3] = []
	for point: Vector3 in points:
		if not point.is_finite() or maxf(absf(point.x), maxf(absf(point.y), absf(point.z))) > 1024.0: return []
		if not unique.has(point): unique.append(point)
	return unique if not unique.is_empty() and unique.size() <= 224 else []

func _sentry_framing_handles() -> Dictionary:
	if not _entered or not _sentry_native_visible(_sentry) or not _sentry_native_visible(hero): return {}
	var actor: Variant = _sentry.call("get_actor")
	var ray: Variant = _sentry.call("get_ray")
	var foot: Variant = _sentry.call("get_foot")
	var joint: Variant = _sentry.call("get_joint_cue")
	for node: Variant in [actor, ray, foot, joint]:
		if not _sentry_native_visible(node) or node.get_parent() != _sentry: return {}
	if not ray.has_method("state") or not ray.has_method("get_cue") or not foot is CinderLaneMechanism or not joint is CinderInteractionCue: return {}
	var ray_cue: Variant = ray.call("get_cue")
	var foot_cue: Variant = foot.get_cue()
	var foot_visual: Variant = foot.get_node_or_null("InheritedGreyboxGiantFoot")
	for node: Variant in [ray_cue, foot_cue, foot_visual]:
		if not _sentry_native_visible(node): return {}
	if ray_cue.get_parent() != ray or foot_cue.get_parent() != foot or foot_visual.get_parent() != foot or not ray_cue is CinderThreatCue or not foot_cue is CinderThreatCue: return {}
	var ray_state: Variant = ray.call("state")
	var foot_state: Variant = foot.state()
	var parent_state: Variant = _sentry.call("state")
	if not ray_state is Dictionary or not foot_state is Dictionary or not parent_state is Dictionary: return {}
	return {"actor": actor, "ray_owner": ray, "foot_owner": foot, "ray_cue": ray_cue, "foot_cue": foot_cue, "foot_visual": foot_visual, "joint": joint, "hero": hero, "ray_state": ray_state, "foot_state": foot_state, "parent_state": parent_state}

func _sentry_native_visible(value: Variant) -> bool:
	if not is_instance_valid(value) or not value is Node3D or not value.is_inside_tree() or not value.is_node_ready() or value.is_queued_for_deletion() or value.get_world_3d() != get_world_3d() or not value.global_transform.basis.is_finite() or not value.global_position.is_finite(): return false
	var root: Node3D = actual_world_root()
	if not is_instance_valid(root) or not root.is_ancestor_of(value): return false
	var cursor: Node = value
	while cursor != root:
		if cursor is Node3D and not cursor.visible: return false
		cursor = cursor.get_parent()
		if cursor == null: return false
	return value.is_visible_in_tree() or is_restore_candidate()

func _sentry_expected_mesh(value: Variant, expected_visible: bool) -> bool:
	if not is_instance_valid(value) or not value is MeshInstance3D or not value.is_inside_tree() or not value.is_node_ready() or value.is_queued_for_deletion() or value.get_world_3d() != get_world_3d() or value.visible != expected_visible: return false
	if expected_visible: return _sentry_native_visible(value) and is_instance_valid(value.mesh)
	return value.mesh == null or is_instance_valid(value.mesh)

func _sentry_threat_points(current: Dictionary, cue: CinderThreatCue, source: Vector3, kind: String, points: Array[Vector3]) -> bool:
	if current.get("status") not in ["idle", "running", "cancelled", "complete"] or current.get("phase") not in ["clear", "warning", "lock", "active", "recovery"]: return false
	var phase: String = String(current.phase) if current.status == "running" else "clear"
	var cue_state: Dictionary = cue.state()
	if cue_state.get("phase") != phase or cue_state.get("required") != true or cue_state.get("source_visible") != (phase != "clear") or cue_state.get("footprint_visible") != (phase != "clear" and phase != "recovery") or cue_state.get("active_fill_visible") != (phase == "active"): return false
	for row: Array in [["RequiredSourceMarker", phase != "clear"], ["RequiredFootprintOutline", phase != "clear" and phase != "recovery"], ["RequiredFootprintFill", phase == "active"]]:
		if not _sentry_expected_mesh(cue.get_node_or_null(row[0]), row[1]): return false
	if phase != "clear":
		if not current.get("geometry") is Dictionary or cue_state.geometry != current.geometry or cue_state.source_position != source or not _sentry_shape_points(current.geometry, source, kind, points): return false
	elif not cue_state.get("geometry", {}).is_empty(): return false
	points.append_array(_mesh_points(cue))
	return true

func _sentry_shape_points(shape: Dictionary, source: Vector3, kind: String, points: Array[Vector3]) -> bool:
	if not Geometry.error(shape).is_empty() or shape.kind != kind: return false
	if (shape["from"] if kind == "lane" else shape.origin) != source: return false
	var corners: Array[Vector3] = _shape_points(shape) # Full radius at both lane endcaps.
	if corners.is_empty(): return false
	points.append_array(corners)
	return true

func _sentry_actual_hero_points() -> Array[Vector3]:
	if not _sentry_native_visible(hero) or not is_instance_valid(shared_shell) or not shared_shell.has_method("player_camera_framing_points_for"): return []
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(camera): return []
	for path: String in ["ActorSprite", "ContactShadow", "BodyCollision"]:
		if not _sentry_native_visible(hero.get_node_or_null(path)): return []
	var native: Variant = shared_shell.call("player_camera_framing_points_for", hero, camera)
	if not native is Array or native.is_empty(): return []
	var corners: Array[Vector3] = []
	var bounds := AABB(hero.global_position, Vector3.ZERO)
	for value: Variant in native:
		if not value is Vector3 or not value.is_finite(): return []
		bounds = bounds.expand(value)
	for index: int in range(8): corners.append(bounds.get_endpoint(index))
	return corners

func _sentry_view_points(view: Dictionary, hero_points: Array[Vector3], points: Array[Vector3]) -> bool:
	for key: String in ["landing", "attack_position"]:
		if not Geometry.finite_vector(view.get(key)): return false
		# Translate actual native capsule, billboard and shadow bounds. No made-up
		# Hero box, guessed body dimensions or predicted pose/camera assignment.
		var delta: Vector3 = view[key] - hero.global_position
		for point: Vector3 in hero_points: points.append(point + delta)
	return true

func _sentry_ray_witness_points(current: Dictionary, hero_points: Array[Vector3], points: Array[Vector3]) -> bool:
	var proof: Variant = current.get("proof", {}) if current.get("proof_available", false) else current.get("presentation_witness", {})
	if not proof is Dictionary: return false
	if proof.is_empty(): return current.get("armed", false) == false
	if current.get("proof_available", false) and proof.get("accepted") != true: return false
	return _sentry_view_points(proof, hero_points, points)

func _sentry_current_foot_view(native: Dictionary) -> Dictionary:
	var current: Dictionary = native.foot_state
	if current.get("status") != "running": return {}
	var accepted: Variant = native.parent_state.get("accepted_cycles", [])
	if not accepted is Array: return {}
	for index: int in range(accepted.size() - 1, -1, -1):
		var row: Variant = accepted[index]
		if not row is Dictionary: return {}
		if row.get("kind") != "foot" or row.get("cycle") != current.cycle: continue
		if not row.get("admitted_exchange") is Dictionary or not row.get("proof") is Dictionary: return {}
		var exchange: Dictionary = row.admitted_exchange
		if exchange.get("id") != current.reservation_id or exchange.get("geometry") != current.geometry or exchange.get("source_position") != native.foot_owner.global_position or exchange.get("opening_position") != native.actor.global_position or row.proof.get("accepted") != true: return {}
		return row.proof.duplicate(true) # View witness only; never admission authority.
	if _sentry_foot_view.get("owner") != native.foot_owner or _sentry_foot_view.get("cycle") != current.cycle or _sentry_foot_view.get("geometry") != current.geometry or _sentry_foot_view.get("source_position") != native.foot_owner.global_position or _sentry_foot_view.get("opening_position") != native.actor.global_position: return {}
	return _sentry_foot_view.duplicate(true)

func _response_context(id: String = "", geometry: Dictionary = {}) -> Dictionary:
	var authored: Array[Vector3] = []
	for index: int in range(16): authored.append(Vector3(sin(TAU * float(index) / 16.0), 0, cos(TAU * float(index) / 16.0)).normalized())
	var escapes: Array[Vector3] = authored.duplicate()
	var returns: Array[Vector3] = authored.duplicate()
	if not id.is_empty() and not geometry.is_empty():
		escapes.clear()
		returns.clear()
		var source: Node3D
		var protected: Array[Vector3] = []
		if _actors.has(id):
			source = _actors[id]
			protected = _familiar_required_points(id, _familiar.call("state", id))
		elif is_instance_valid(_sentry):
			source = _sentry.call("get_actor")
			protected = _sentry_required_points()
		if is_instance_valid(source) and not protected.is_empty() and Geometry.error(geometry).is_empty() and _sentry_native_visible(hero):
			protected.append_array(_shape_points(geometry))
			var response: Dictionary = hero.get_threat_response_state()
			var distance: Variant = response.get("stats", {}).get("dash_distance")
			var reach: Variant = response.get("stats", {}).get("primary_range")
			if Codec.is_number(distance) and float(distance) > 0.0 and Codec.is_number(reach) and float(reach) > 0.0:
				var body: Array[Vector3] = _sentry_actual_hero_points()
				for direction: Vector3 in authored:
					var landing: Vector3 = hero.global_position + direction * float(distance)
					var points: Array[Vector3] = protected.duplicate()
					for point: Vector3 in body: points.append(point + landing - hero.global_position)
					if _framed(points) and _framed_at_follow(points, landing): escapes.append(direction)
				# Shared proof cross-products the two authored arrays. Every return
				# pairing that can reach this actual ordinary low joint must fit.
				for direction: Vector3 in authored:
					var reachable: bool = false
					var all_visible: bool = true
					for escape: Vector3 in escapes:
						var landing: Vector3 = hero.global_position + (escape + direction) * float(distance)
						if Geometry.planar(landing - source.global_position).length() > float(reach) + 0.00001: continue
						reachable = true
						var points: Array[Vector3] = protected.duplicate()
						for point: Vector3 in body: points.append(point + landing - hero.global_position)
						if not _framed(points) or not _framed_at_follow(points, landing): all_visible = false; break
					if reachable and all_visible: returns.append(direction)
	return {"encounter_id": EPOCH, "world_revision": WORLD_REVISION, "recognition_s": 0.30, "attack_input_margin_s": 0.03, "escape_directions": escapes, "return_directions": returns, "floor_regions": floor_bindings().values()}

func floor_bindings() -> Dictionary:
	var result: Dictionary = {}
	for floor: Dictionary in _floor_records: result[floor.id] = {"collision": floor.collision, "safe_rect": floor.safe_rect}
	return result

func scheduler_bindings() -> Dictionary:
	var owners: Dictionary = _actors.duplicate()
	if is_instance_valid(_rehearsal): owners[REHEARSAL_ID] = _rehearsal
	if is_instance_valid(_sentry): owners.merge(_sentry.call("owners"), false)
	return {"world_root": actual_world_root(), "owners": owners, "floors": floor_bindings()}

func actual_world_root() -> Node3D:
	# Actual CinderGame.world holds Hero+all sources. Standalone fixtures must
	# supply the same concrete world parent, never a diagnostic/fake root.
	return get_parent() as Node3D

func _camera_framing_points() -> Array:
	var points: Array[Vector3] = []
	if not _entered or not is_instance_valid(_familiar): return points
	for id: String in _actors:
		var state: Dictionary = _familiar.call("state", id)
		if state.status == "running": points.append_array(_familiar_required_points(id, state))
	if is_instance_valid(_rehearsal) and _rehearsal.state().status == "running":
		points.append_array(_mesh_points(_rehearsal_art))
		points.append_array(_mesh_points(_rehearsal.get_cue()))
		for key: String in ["landing", "attack_position"]:
			if _rehearsal_view.get(key) is Vector3: points.append_array(_landing_points(_rehearsal_view[key]))
	if _sentry_started and _stage == 6: points.append_array(_sentry_required_points())
	return points

func _framed(points: Array) -> bool:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if points.is_empty() or not is_instance_valid(shared_shell) or not shared_shell.has_method("camera_framing_error_for_player") or not _sentry_native_visible(hero) or not is_instance_valid(camera): return false
	for point: Variant in points:
		if not Geometry.finite_vector(point): return false
	return String(shared_shell.call("camera_framing_error_for_player", points, hero, camera)).is_empty() and _framed_at_follow(points, hero.global_position)

func _framed_at_follow(points: Array, landing: Vector3) -> bool:
	## Predict only the shared fully settled ordinary follow position. Shift
	## points into the current camera's relative frame; no camera/focus writes,
	## copied projection/HUD rules or permission from a possible future fit.
	var camera: Camera3D = get_viewport().get_camera_3d()
	if points.is_empty() or not landing.is_finite() or not is_instance_valid(camera) or not is_instance_valid(shared_shell) or not shared_shell.has_method("camera_framing_error_for_player"): return false
	var delta: Vector3 = landing + Vector3.UP * 0.75 + SharedGame.CAMERA_OFFSET - camera.global_position
	var shifted: Array[Vector3] = []
	for point: Variant in points:
		if not Geometry.finite_vector(point): return false
		shifted.append(point - delta)
	# Public method appends the actual current Hero too. This is intentionally
	# conservative; the translated complete saved/current body is in points.
	return String(shared_shell.call("camera_framing_error_for_player", shifted, hero, camera)).is_empty()

func _sentry_points_framed(points: Array[Vector3], proposed: Dictionary = {}) -> bool:
	if not _framed(points): return false
	var native: Dictionary = _sentry_framing_handles()
	if native.is_empty(): return false
	var views: Array[Dictionary] = []
	var ray: Dictionary = proposed.get("ray", native.ray_state)
	var ray_view: Variant = ray.get("proof", {}) if ray.get("proof_available", false) else ray.get("presentation_witness", {})
	if ray_view is Dictionary and not ray_view.is_empty(): views.append(ray_view)
	if native.foot_state.status == "running": views.append(_sentry_current_foot_view(native))
	var preview: Dictionary = proposed.get("foot_preview", {})
	if not preview.is_empty(): views.append(preview.get("proof", {}))
	for view: Dictionary in views:
		for key: String in ["landing", "attack_position"]:
			if not Geometry.finite_vector(view.get(key)) or not _framed_at_follow(points, view[key]): return false
	return true

func _project_restored_presentation() -> bool:
	## Host codec calls only after actual Player, all sources, one Scheduler,
	## Foot/Ray and exact Joint commit. No Actor present_phase/yaw relatch,
	## fresh proof/request, bait sample, cue event or deadline refresh.
	_sentry_foot_view.clear()
	if is_instance_valid(_sentry):
		if not bool(_sentry.call("project_native_cosmetics")): return false
		var native: Dictionary = _sentry_framing_handles()
		if native.is_empty(): return false
		if native.foot_state.status == "running":
			# This view is rebuilt only from strict restored native parent receipt;
			# actual current cycle/reservation/source/shape matches are mandatory.
			if _sentry_current_foot_view(native).is_empty(): return false
	DeadLondonKit.project_stage(_kit, _stage)
	_refresh_cosmetic_readability()
	return true

func _refresh_cosmetic_readability() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(camera) or not _sentry_native_visible(hero): return
	var body: Array[Vector3] = _sentry_actual_hero_points()
	if body.is_empty(): return
	var protected: Array[Vector3] = body.duplicate()
	var rigs: Array[Node3D] = []
	for actor: Variant in _actors.values():
		if not is_instance_valid(actor): continue
		var rig: Node3D = actor.get_node_or_null("ScoutRig") as Node3D
		if is_instance_valid(rig):
			if actor.visible: rigs.append(rig)
			else: rig.call("clear_readability")
	if is_instance_valid(_sentry):
		var actor: Variant = _sentry.call("get_actor")
		if is_instance_valid(actor) and actor.has_method("get_cosmetic_rig"):
			var rig: Node3D = actor.call("get_cosmetic_rig")
			if is_instance_valid(rig): rigs.append(rig)
		var foot: Variant = _sentry.call("get_foot")
		if is_instance_valid(foot):
			var rig: Node3D = foot.get_node_or_null("InheritedGreyboxGiantFoot") as Node3D
			if is_instance_valid(rig): rigs.append(rig)
	if is_instance_valid(_rehearsal_art) and _rehearsal_art.visible: rigs.append(_rehearsal_art)
	for rig: Node3D in rigs: rig.call("apply_readability", camera, body)
	var required: Array = _camera_framing_points()
	for point: Variant in required:
		if Geometry.finite_vector(point): protected.append(point)
	# Optional architecture alone may fade. Native sources/cues/Hero/ground
	# retain their own required visibility and rig-specific panel cutaway logic.
	for value: Variant in _optional_meshes:
		if not is_instance_valid(value) or not value.is_inside_tree() or value.is_queued_for_deletion(): continue
		var mesh: MeshInstance3D = value as MeshInstance3D
		if not mesh.visible or not is_instance_valid(mesh.mesh) or not mesh.material_override is StandardMaterial3D: continue
		var obscures: bool = false
		var inverse: Transform3D = mesh.global_transform.affine_inverse()
		for point: Vector3 in protected:
			var origin: Vector3 = camera.project_ray_origin(camera.unproject_position(point))
			if mesh.mesh.get_aabb().intersects_segment(inverse * origin, inverse * point): obscures = true; break
		var material: StandardMaterial3D = mesh.material_override as StandardMaterial3D
		var tint: Color = material.albedo_color
		tint.a = 0.12 if obscures else 1.0
		material.albedo_color = tint
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if obscures else BaseMaterial3D.TRANSPARENCY_DISABLED

func _mesh_points(node: Node3D) -> Array[Vector3]:
	var all: Array[Vector3] = []
	if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion(): return all
	_append_mesh_points(node, all)
	if all.is_empty(): return all
	var bounds := AABB(all[0], Vector3.ZERO)
	for point: Vector3 in all: bounds = bounds.expand(point)
	var corners: Array[Vector3] = []
	for index: int in range(8): corners.append(bounds.get_endpoint(index))
	return corners

func _append_mesh_points(node: Node, points: Array[Vector3]) -> void:
	if node is MeshInstance3D and node.visible and is_instance_valid(node.mesh):
		var bounds: AABB = node.mesh.get_aabb()
		for index: int in range(8): points.append(node.global_transform * bounds.get_endpoint(index))
	for child: Node in node.get_children(): _append_mesh_points(child, points)

func _shape_points(shape: Dictionary) -> Array[Vector3]:
	var points: Array[Vector3] = []
	if not Geometry.error(shape).is_empty(): return points
	var radius: float = float(shape.radius)
	var centers: Array[Vector3] = []
	if shape.kind == "circle": centers.append(shape.origin)
	elif shape.kind == "lane": centers.assign([shape["from"], shape["to"]])
	else: return points
	for center: Vector3 in centers:
		for x: float in [-radius, radius]:
			for z: float in [-radius, radius]: points.append(center + Vector3(x, 0.03, z))
	return points

func _landing_points(at: Vector3) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for x: float in [-0.32, 0.32]:
		for z: float in [-0.32, 0.32]:
			for y: float in [0.03, 1.46]: points.append(at + Vector3(x, y, z))
	return points

func _supported_stable() -> bool:
	if not is_instance_valid(hero) or hero.dead or hero.action_in_progress(): return false
	var response: Dictionary = hero.get_threat_response_state()
	return response.get("stable", false) and response.motion.get("grounded", false) and String(response.get("pending_weapon_id", "")).is_empty()

func _hero_contacts(region: Rect2) -> bool:
	return not hero.dead and hero.global_position.y >= -0.05 and hero.global_position.y <= 0.2 and region.has_point(Geometry.planar(hero.global_position))

func _pause_pending() -> bool:
	return get_tree().paused or (is_instance_valid(shared_shell) and shared_shell.has_method("is_pause_requested") and bool(shared_shell.call("is_pause_requested")))

func _segment_contacts(a: Vector2, b: Vector2, rectangle: Rect2) -> bool:
	# Geometry observation only, from a genuine completed native record.
	if rectangle.has_point(a) or rectangle.has_point(b): return true
	var delta: Vector2 = b - a
	var near: float = 0.0
	var far: float = 1.0
	for axis: int in range(2):
		if absf(delta[axis]) <= 0.000001:
			if a[axis] < rectangle.position[axis] or a[axis] > rectangle.end[axis]: return false
		else:
			var first: float = (rectangle.position[axis] - a[axis]) / delta[axis]
			var second: float = (rectangle.end[axis] - a[axis]) / delta[axis]
			near = maxf(near, minf(first, second))
			far = minf(far, maxf(first, second))
			if near > far: return false
	return near <= 1.0 and far >= 0.0

func _derive_presentation() -> void:
	var cue_blocks: Dictionary = {}
	if _quiet_projection:
		for beat: String in _contact_cues:
			cue_blocks[beat] = _contact_cues[beat].is_blocking_signals()
			_contact_cues[beat].set_block_signals(true)
		cue_blocks["exit"] = _exit_cue.is_blocking_signals()
		_exit_cue.set_block_signals(true)
	for id: String in _actors: _actors[id].visible = _defeated.has(id) or (_stage == 1 and id == "A2-L5:square-scout") or (_stage == 4 and id == "A2-L5:park-scout")
	for beat: String in _contact_cues:
		if STAGES[_stage] == beat: _contact_cues[beat].present("available", "contact")
		else: _contact_cues[beat].clear()
	if is_completed(): _exit_cue.present("active" if _exit_requested else "available", "contact")
	else: _exit_cue.clear()
	if _quiet_projection:
		for beat: String in _contact_cues: _contact_cues[beat].set_block_signals(cue_blocks[beat])
		_exit_cue.set_block_signals(cue_blocks["exit"])
	DeadLondonKit.project_stage(_kit, _stage)
	_refresh_cosmetic_readability()
	_update_objective()

func _update_objective() -> void:
	match STAGES[_stage]:
		"empty-square-1": objective_text = "CROSS THE EMPTY SQUARE\nTHE CRY COMES FROM THE PARK."
		"empty-square-2": objective_text = "PASS THE LAST STREET SCOUT\nREAD THE MIRROR; STRIKE ITS LOW HOUSING."
		"park-checkpoint": objective_text = "REACH REGENT'S APPROACH\nCROSS THE DRY PARK GATE."
		"rehearsed-foot": objective_text = "LEAVE THE PLANTED FOOT\nKEEP A CLEAR LANDING IN VIEW."
		"park-scout": objective_text = "PASS THE PARK SCOUT\nTHE FIVE-LEGGED WRECK IS STILL."
		"boss-entry": objective_text = "REACH THE SENTRY APRON\nKEEP AN ORDINARY RETURN TO THE NEAR JOINT."
		"sentry": objective_text = "OPEN THE LOCAL PASSAGE\nBAIT YOUR COMPLETED LANDING; RETURN AFTER COMMITMENT."
		"redoubt-piles": objective_text = "THE CRY HAS STOPPED\nREACH THE DEAD MARTIANS BEYOND THE SENTRY."
		"redoubt-machines": objective_text = "CROSS THE STILL REDOUBT\nTHE OTHER MACHINES ARE INERT TOO."
		"redoubt-dawn": objective_text = "MICROBES ENDED THE INVASION\nREACH THE DAWN AND SURVIVOR SIGNAL."
		"clear": objective_text = "THE INVASION HAS ENDED\nFOLLOW THE OPEN ROAD ONWARD."

func _build_ground_and_props() -> void:
	var ground := Node3D.new()
	ground.name = "ContinuousDeadLondonDryGround"
	add_child(ground)
	for spec: Dictionary in FLOORS:
		var rect: Rect2 = spec.rect
		var body: StaticBody3D = _box_body(ground, spec.id, Vector3(rect.get_center().x, -0.25, rect.get_center().y), Vector3(rect.size.x, 0.5, rect.size.y))
		_floor_records.append({"id": spec.id, "collision": body.get_node("AuthoredShape"), "safe_rect": rect.grow(-0.002)})
	for side: int in [-1, 1]: _box_body(ground, "StreetBoundary_%d" % side, Vector3(float(side) * 3.65, 0.5, -21.6), Vector3(0.5, 1.0, 52.0))
	_box_body(ground, "ArrivalEnd", Vector3(0, 0.5, 3.9), Vector3(7.8, 1.0, 0.6))
	_box_body(ground, "DepartureEnd", Vector3(0, 0.5, -47.3), Vector3(7.8, 1.0, 0.6))
	# Visible ordinary props bound the duel, while dry ground stays continuous.
	# Shape faces at +/-2.52 X and +/-3.12 Z bound native Hero center by itsR.32.
	# Full 3.8 lane extends beyond these props; TODO real source/LOS/cue/portrait
	# review must establish its truthful extent, all kits and collision-shortening.
	for side: int in [-1, 1]: _box_body(ground, "ApronFrame_%d" % side, SENTRY_AT + Vector3(float(side) * 2.67, 0.4, 0), Vector3(0.3, 0.8, 6.6), true)
	for id: String in ["entry", "departure"]:
		var z: float = 3.18 if id == "entry" else -3.18
		var body: StaticBody3D = _box_body(ground, "ApronGate_" + id, SENTRY_AT + Vector3(0, 0.4, z), Vector3(5.34, 0.8, 0.12), true)
		var shape: CollisionShape3D = body.get_node("AuthoredShape") as CollisionShape3D
		shape.disabled = id == "entry"
		body.get_node("VisibleGroundedProp").visible = id != "entry"
		_gates[id] = {"shape": shape, "mesh": body.get_node("VisibleGroundedProp")}
	var base := StaticBody3D.new()
	base.name = "VisibleLowBraceBase"
	base.position = SENTRY_AT + Vector3(0, 0.1, 0)
	base.collision_layer = 1
	base.collision_mask = 0
	ground.add_child(base)
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.36
	cylinder.height = 0.2
	var shape := CollisionShape3D.new()
	shape.name = "BelowOrdinaryPrimaryLOS"
	shape.shape = cylinder
	base.add_child(shape)
	Heath._cylinder(base, "VisibleBracePlinth", Vector3.ZERO, 0.36, 0.36, 0.2, Heath._material("metal"), 12)
	_kit = DeadLondonKit.build(self)
	var art: Node3D = _kit.root
	for path: Variant in art.get_meta("optional_cutaway_paths", []):
		var mesh: MeshInstance3D = art.get_node_or_null(NodePath(path)) as MeshInstance3D
		if is_instance_valid(mesh): _optional_meshes.append(mesh)
	for beat: String in CONTACTS:
		var cue: CinderInteractionCue = InteractionCue.new()
		cue.name = "Contact_" + CONTACTS[beat].id
		cue.position = Vector3(0, 0.025, CONTACTS[beat].region.get_center().y)
		add_child(cue)
		cue.clear()
		cue.state_changed.connect(_on_local_cue_publication)
		_contact_cues[beat] = cue
	_exit_cue = InteractionCue.new()
	_exit_cue.name = "Act3RoadContact"
	_exit_cue.position = Vector3(0, 0.025, EXIT_REGION.get_center().y)
	add_child(_exit_cue)
	_exit_cue.clear()
	_exit_cue.state_changed.connect(_on_local_cue_publication)

func _box_body(parent: Node3D, id: String, at: Vector3, size: Vector3, visible_prop: bool = false) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = id
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.name = "AuthoredShape"
	shape.shape = box
	body.add_child(shape)
	if visible_prop: Heath._box(body, "VisibleGroundedProp", Vector3.ZERO, size, Heath._material("metal"))
	return body

func _set_gate(id: String, closed: bool) -> void:
	_gates[id].shape.set_deferred("disabled", not closed)
	_gates[id].mesh.visible = closed

func _gate_closed(id: String) -> bool:
	return not bool(_gates[id].shape.disabled)

func _native_prefix_valid() -> bool:
	for node: Variant in [hero, effects, _scheduler, _familiar, _rehearsal, _rehearsal_art, _exit_cue]:
		if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion() or node.get_world_3d() != get_world_3d(): return false
	for id: String in _actors:
		var actor: Variant = _actors[id]
		if not is_instance_valid(actor) or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.position != SCOUTS[id]: return false
	if not is_instance_valid(_approach_guard) or not _approach_guard.is_inside_tree() or _approach_guard.is_queued_for_deletion() or not bool(_approach_guard.call("binding_matches", Callable(self, "_guard_approach"))): return false
	for floor: Dictionary in _floor_records:
		var shape: Variant = floor.collision
		if not is_instance_valid(shape) or not shape.is_inside_tree() or shape.is_queued_for_deletion(): return false
	for id: String in _gates:
		for part: String in ["shape", "mesh"]:
			var node: Variant = _gates[id][part]
			if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion(): return false
	return _floor_records.size() == FLOORS.size()

func _phase2_checkpoint_protected() -> bool:
	if not is_instance_valid(shared_shell): return false
	var attempts: Variant = shared_shell.get("attempts")
	if not is_instance_valid(attempts) or not attempts.has_method("state"): return false
	var model: Dictionary = attempts.call("state")
	var attempt: Variant = model.get("side_attempt")
	if attempt == null: attempt = model.get("story")
	if not attempt is Dictionary: return false
	var checkpoint: Dictionary = attempt.get("checkpoint", {})
	var level: Dictionary = checkpoint.get("level", {})
	var progress: Dictionary = level.get("progress", {})
	return checkpoint.get("level_id") == "A2-L5" and level.get("level_id") == "A2-L5" and progress.get("checkpoint_id") == "dead-london-sentry-phase-2" and progress.get("checkpoint_kind") == "boss_phase"

func encounter_state() -> Dictionary:
	# Defensive native diagnostics only; no mutator/transport/phase authority.
	var native: Dictionary = {}
	for id: String in _actors:
		if is_instance_valid(_actors[id]): native[id] = {"hp": _actors[id].get("hp"), "phase": _actors[id].get("phase"), "root": _actors[id].global_position, "exchange": _familiar.call("state", id) if is_instance_valid(_familiar) else {}}
	return {"stage": STAGES[_stage], "stage_index": _stage, "profile_id": _profile, "world_revision": WORLD_REVISION, "clock_s": _scheduler.get_clock() if is_instance_valid(_scheduler) else 0.0, "defeated_scouts": _defeated.duplicate(), "contacts": _contacts.duplicate(), "sources": native, "rehearsal": _rehearsal.state() if is_instance_valid(_rehearsal) else {}, "sentry": _sentry.call("state") if is_instance_valid(_sentry) else {}, "passage_open": _passage_open, "exit_open": is_completed(), "runtime_error": runtime_error}

func restore_candidate_construction_required() -> bool:
	return true # Gate/source topology is authored-stage dependent.

# CLOSED whole-local packet. Native diagnostics are never serialized.
func _capture_local_state() -> Dictionary:
	var error: String = _transport_native_error()
	if not error.is_empty(): return {"error": error}
	var bindings: Dictionary = scheduler_bindings()
	var scheduler: Dictionary = _scheduler.snapshot_state(bindings)
	var familiar: Dictionary = _familiar.call("snapshot_state", bindings)
	var rehearsal: Dictionary = _rehearsal.snapshot_state(bindings)
	var sentry: Dictionary = _sentry.call("snapshot_state", bindings)
	if scheduler.is_empty() or familiar.is_empty() or rehearsal.is_empty() or sentry.is_empty(): return {"error": "Whole L5 native component capture refused: " + _component_errors()}
	return {"stage": _stage, "defeated_scouts": _defeated.duplicate(), "contacts": _contacts.duplicate(), "contact_seen": _contact_seen, "rehearsal_complete": _rehearsal_complete, "sentry_started": _sentry_started, "phase2_checkpoint": _phase2_checkpoint, "passage_open": _passage_open, "profile_id": _profile, "world_revision": WORLD_REVISION, "last_action_sequence": _last_action_sequence, "pending_checkpoints": _pending_checkpoints.duplicate(true), "completion_pending": _completion_pending, "exit_requested": _exit_requested, "pending_defeats": _pending_defeats.duplicate(), "pending_phase2": _pending_phase2, "pending_clear": _pending_clear, "phase2_admitted_after_checkpoint": _phase2_admitted_after_checkpoint, "gate_states": _native_gate_states(), "scheduler": scheduler, "familiar": familiar, "rehearsal": rehearsal, "rehearsal_view": _portable_view(_rehearsal_view), "sentry_foot_view": _saved_sentry_foot_view(sentry), "bait": _bait.call("state"), "sentry": sentry}

func _component_errors() -> String:
	return String(_scheduler.last_snapshot_error) + " / " + String(_familiar.get("last_snapshot_error")) + " / " + String(_rehearsal.last_snapshot_error) + " / " + String(_sentry.get("last_snapshot_error"))

func _portable_view(value: Dictionary) -> Dictionary:
	var result: Dictionary = value.duplicate(true)
	for key: String in ["landing", "attack_position"]:
		if value.get(key) is Vector3: result[key] = Codec.vector3(value[key])
	return result

func _saved_sentry_foot_view(sentry: Dictionary) -> Dictionary:
	if sentry.foot.status != "running": return {}
	var row: Dictionary = sentry.parent.foot_admission
	if row.is_empty(): return {}
	return {"cycle": row.cycle, "reservation_id": row.exchange.id, "geometry": row.exchange.geometry.duplicate(true), "source_position": row.exchange.source_position.duplicate(), "opening_position": row.exchange.opening_position.duplicate(), "landing": row.proof.landing.duplicate(), "attack_position": row.proof.attack_position.duplicate()}

func _native_gate_states() -> Dictionary:
	return {"entry": _gate_closed("entry"), "departure": _gate_closed("departure")}

func _same_exact(left: Variant, right: Variant) -> bool:
	var text: String = ExactJson.stringify(left)
	return not text.is_empty() and text == ExactJson.stringify(right)

func _local_snapshot_error(state: Dictionary) -> String:
	if not is_instance_valid(hero): return "L5 requires its actual native Player"
	var player: Dictionary = hero.snapshot_state()
	return "L5 requires the complete paused Player" if player.is_empty() else _whole_local_error(state, player)

func _local_snapshot_error_with_player(state: Dictionary, saved_player: Dictionary) -> String:
	return _whole_local_error(state, saved_player)

# This first pass uses no native bindings. A candidate constructs only the
# exact authored topology after the complete envelope/Player are validated.
func _local_shape_error(state: Dictionary, player: Dictionary) -> String:
	var error: String = Codec.value_error(state)
	if error.is_empty(): error = Codec.keys_error(state, LOCAL_KEYS)
	if not error.is_empty(): return error
	if not Codec.is_integer(state.stage, 0, STAGES.size() - 1) or not state.stage is int or not state.profile_id is String or Difficulty.new().profile(state.profile_id).is_empty() or not Codec.is_integer(state.world_revision, WORLD_REVISION, WORLD_REVISION): return "Closed L5 stage/fixed canonical profile/world revision required"
	if not Codec.is_integer(state.last_action_sequence) or not player.get("world_actions") is Dictionary or not Codec.is_integer(player.world_actions.get("sequence")) or int(state.last_action_sequence) > int(player.world_actions.sequence): return "L5 cursor cannot precede a fabricated future Player publication"
	for key: String in ["rehearsal_complete", "sentry_started", "phase2_checkpoint", "passage_open", "completion_pending", "exit_requested", "pending_phase2", "pending_clear", "phase2_admitted_after_checkpoint"]:
		if not state[key] is bool: return "Boolean L5 latch required: " + key
	for key: String in ["defeated_scouts", "contacts", "pending_checkpoints", "pending_defeats"]:
		if not state[key] is Array: return "Bounded exact L5 ordered history required: " + key
	for key: String in ["gate_states", "scheduler", "familiar", "rehearsal", "rehearsal_view", "sentry_foot_view", "bait", "sentry"]:
		if not state[key] is Dictionary: return "Full L5 component required: " + key
	if not state.contact_seen is String or (not state.contact_seen.is_empty() and (not CONTACTS.has(state.contact_seen) or STAGES[state.stage] != state.contact_seen)): return "Contact witness belongs only to the current authored contact"
	if not Codec.keys_error(state.gate_states, ["entry", "departure"]).is_empty() or not state.gate_states.entry is bool or not state.gate_states.departure is bool: return "Exact two grounded gate states required"
	var contact_count: int = 0
	for minimum: int in [1, 3, 6, 8, 9, 10]:
		if state.stage >= minimum: contact_count += 1
	if not _exact_prefix(state.contacts, CONTACT_ORDER, contact_count): return "L5 contacts must equal the earned authored prefix"
	var defeat_count: int = 2 if state.stage >= 5 else (1 if state.stage >= 2 else 0)
	if not _exact_prefix(state.defeated_scouts, SCOUT_ORDER, defeat_count): return "L5 Scout defeats must equal the earned authored prefix"
	if state.pending_defeats.size() > 1: return "Only one current familiar defeat can be queued"
	if not state.pending_defeats.is_empty():
		var expected: String = SCOUT_ORDER[0] if state.stage == 1 else (SCOUT_ORDER[1] if state.stage == 4 else "")
		if expected.is_empty() or state.pending_defeats != [expected]: return "Pending real Scout defeat belongs only to the current source"
	if state.rehearsal_complete != (state.stage >= 4): return "Rehearsal completion precedes the second Scout and boss contact"
	if state.sentry_started and state.stage < 6: return "B05 cannot start before actual boss entry"
	if (state.phase2_checkpoint or state.phase2_admitted_after_checkpoint or state.pending_phase2 or state.pending_clear or state.passage_open) and (state.stage < 6 or not state.sentry_started): return "B05 latches require the actual started apron encounter"
	if state.phase2_admitted_after_checkpoint and not state.phase2_checkpoint: return "Phase2 admission requires the earned protected phase boundary"
	if state.pending_phase2 and (state.stage != 6 or state.phase2_checkpoint): return "Queued B05 phase intent cannot duplicate the processed boundary"
	if state.pending_clear and (state.stage != 6 or not state.phase2_checkpoint): return "Queued passage intent cannot skip phase2 boundary"
	if state.passage_open != (state.stage >= 7): return "Local route opens only after actual finite sentry clear"
	if state.stage >= 7 and (not state.phase2_checkpoint or not state.phase2_admitted_after_checkpoint): return "Coda follows both actual sentry pools"
	if state.completion_pending and state.stage != 10: return "Pending Act clear requires all authored quiet discoveries"
	if state.exit_requested and (state.stage != 10 or state.completion_pending): return "Exit follows committed quiet discovery completion"
	if state.stage < 5 and state.gate_states.entry: return "Early squares/park must retain open boss entry"
	if state.stage == 5 and state.gate_states.entry and state.contact_seen != "boss-entry": return "Closing apron entry requires actual supported entry contact"
	if state.stage >= 6 and not state.gate_states.entry: return "Entered B05 apron retains its actual grounded entry barrier"
	if state.stage < 6 and not state.gate_states.departure: return "No early local departure opening"
	if state.stage == 6 and not state.gate_states.departure and not state.pending_clear: return "Native gate-open boundary retains its pending finite-clear intent"
	if state.stage >= 7 and state.gate_states.departure: return "Earned coda requires actual open departure collider"
	var earned: Array[String] = _earned_checkpoint_ids(state)
	if state.pending_checkpoints.size() > earned.size(): return "Checkpoint queue exceeds earned boundaries"
	var previous: int = -1
	for request: Variant in state.pending_checkpoints:
		if not request is Dictionary or not Codec.keys_error(request, ["id", "kind"]).is_empty() or not request.get("id") is String or not earned.has(request.id) or request.get("kind") != OWN_CHECKPOINT_KINDS[request.id]: return "Only exact earned checkpoint requests may be queued"
		var index: int = earned.find(request.id)
		if index <= previous: return "Checkpoint pending tail cannot reorder or duplicate boundaries"
		previous = index
	return ""

func _exact_prefix(value: Array, ordered: Array, count: int) -> bool:
	if value.size() != count: return false
	for index: int in range(count):
		if not value[index] is String or value[index] != ordered[index]: return false
	return true

func _earned_checkpoint_ids(state: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if state.stage >= 3: result.append(CHECKPOINT_ORDER[0])
	if state.stage >= 6: result.append(CHECKPOINT_ORDER[1])
	if state.phase2_checkpoint: result.append(CHECKPOINT_ORDER[2])
	if state.passage_open: result.append(CHECKPOINT_ORDER[3])
	return result

func _whole_local_error(state: Dictionary, player: Dictionary) -> String:
	var error: String = _transport_native_error()
	if not error.is_empty(): return error
	error = hero.snapshot_error(player)
	if error.is_empty(): error = _local_shape_error(state, player)
	if not error.is_empty(): return error
	if state.gate_states != _native_gate_states(): return "Restore requires already constructed exact authored gate topology; never repair a live collider during commit"
	var bindings: Dictionary = scheduler_bindings()
	bindings["hero_positions"] = {"hero": Codec.read_vector3(player.motion.position)}
	error = _scheduler.snapshot_error(state.scheduler, bindings)
	if not error.is_empty(): return error
	var ended: bool = state.stage == 10 and not state.completion_pending
	if state.scheduler.world_revision != WORLD_REVISION: return "Copied Scheduler world revision must remain exact"
	if ended:
		if not state.scheduler.encounter_id.is_empty() or not state.scheduler.profile.is_empty() or not state.scheduler.reservations.is_empty() or not state.scheduler.cooldowns.is_empty(): return "Completed discovery ends the one actual encounter"
	elif state.scheduler.encounter_id != EPOCH or not _same_exact(state.scheduler.profile, Difficulty.new().profile(state.profile_id)): return "One fixed saved canonical encounter profile spans both bait boundaries"
	error = String(_familiar.call("snapshot_error", state.familiar, bindings, state.scheduler))
	if error.is_empty(): error = _rehearsal.snapshot_error(state.rehearsal, bindings, state.scheduler)
	if error.is_empty(): error = String(_bait.call("snapshot_error", state.bait, player))
	if error.is_empty(): error = String(_sentry.call("snapshot_error", state.sentry, bindings, player, state.scheduler))
	if not error.is_empty(): return error
	if state.familiar.clock_s != state.scheduler.clock_s or state.rehearsal.clock_s != state.scheduler.clock_s or state.sentry.clock_s != state.scheduler.clock_s: return "Copied whole native component clocks must be exactly equal"
	if state.familiar.configuration.profile_id != state.profile_id or state.sentry.configuration.profile_id != state.profile_id or not _same_exact(state.bait, state.sentry.bait): return "Whole native profile/bait copies cannot diverge"
	error = _stage_component_error(state, player)
	if error.is_empty(): error = _rehearsal_view_error(state)
	if error.is_empty() and not _same_exact(state.sentry_foot_view, _saved_sentry_foot_view(state.sentry)): error = "Portable B05 Foot view derives only from its actual validated current admission"
	return error

func _stage_component_error(state: Dictionary, player: Dictionary) -> String:
	var dead: bool = player.resources.dead
	var now: float = state.scheduler.clock_s
	var stage: int = state.stage
	for id: String in SCOUT_ORDER:
		var body: Dictionary = state.familiar.actors[id]
		var record: Dictionary = state.familiar.records[id]
		var expected_dead: bool = state.defeated_scouts.has(id) or state.pending_defeats.has(id)
		if (body.hp == 0.0) != expected_dead: return "Actual familiar source HP must equal accepted or queued authored defeat"
		var current: bool = (stage == 1 and id == SCOUT_ORDER[0]) or (stage == 4 and id == SCOUT_ORDER[1])
		if not current and not expected_dead and (body.hp != 30.0 or body.phase != "idle" or record.cycle != 0 or record.status != "idle"): return "Future familiar sources remain pristine dormant originals"
		if record.status == "running":
			if dead or not current: return "Only the current living-prefix Scout may retain a native lease"
			if record.sample.clock_s != now or not _same_exact(record.sample.position, player.motion.position): return "Copied measured Scout sample must exactly match saved Player/clock"
	var foot: Dictionary = state.rehearsal
	if stage < 3 and (foot.cycle != 0 or foot.status != "idle"): return "Approach Foot cannot precede the real park contact"
	if stage >= 4:
		if foot.cycle < 1 or foot.exchange.is_empty() or now < foot.exchange.recovery_until_s or (foot.status != "complete" and not (dead and foot.status == "cancelled")): return "Rehearsal flag requires actual naturally completed native recovery"
	if foot.status == "running":
		if stage != 3 or dead: return "Approach Foot runs only in its real living rehearsal beat"
		if foot.hero_samples.hero.clock_s != now or not _same_exact(foot.hero_samples.hero.position, player.motion.position): return "Copied approach sample must exactly match complete saved Player/clock"
	if foot.cycle > 0:
		var resolved: Dictionary = Difficulty.new().resolve_role(REHEARSAL_ROLE, state.profile_id, REHEARSAL_FLOORS)
		if not _same_exact(foot.resolved_role, resolved): return "Actual approach Foot keeps its immutable canonical role"
	var sentry: Dictionary = state.sentry
	var finite: Dictionary = sentry.actor
	var parent: Dictionary = sentry.parent
	if stage < 6:
		if not sentry.bait.boundary.is_empty() or finite.actor.hp != 30.0 or finite.boss_phase != 1 or finite.transition_pending or sentry.ray.record.cycle != 0 or sentry.foot.cycle != 0 or parent.stage != ("cancelled" if dead else "dormant"): return "Future B05 stays untouched, with no seeded bait before earned apron entry"
	elif state.sentry_started:
		if parent.stage == "dormant": return "Started B05 cannot restore a dormant parent"
	elif finite.actor.hp != 30.0 or finite.boss_phase != 1 or finite.transition_pending or sentry.ray.record.cycle != 0 or sentry.foot.cycle != 0 or parent.stage != ("cancelled" if dead else "dormant"): return "Entered but unstarted B05 remains the original untouched first pool"
	if stage >= 6 and sentry.bait.boundary != ("sentry-phase-2" if finite.boss_phase == 2 else "sentry-entry"): return "Actual completed-dash bait boundary matches earned entry and committed pool"
	var phase_notification: String = parent.notifications.checkpoint
	if state.phase2_checkpoint:
		if finite.boss_phase != 2 or parent.phase_commit.is_empty() or phase_notification != "delivered": return "Host phase checkpoint follows only actual committed and published parent receipt"
	elif phase_notification == "delivered" and not state.pending_phase2: return "Delivered phase notification retains its actual pending host intent"
	if state.pending_phase2 and (phase_notification != "delivered" or finite.boss_phase != 2): return "Queued host phase intent requires genuine delivered phase2"
	if state.phase2_admitted_after_checkpoint and parent.stage not in ["phase-two", "cleared", "cancelled"]: return "Resume latch requires actual native phase2 admission"
	if not state.phase2_admitted_after_checkpoint and parent.stage == "phase-two": return "Actual parent resumed phase2 must retain the host acknowledgement"
	var clear_notification: String = parent.notifications.clear
	if state.passage_open:
		if finite.actor.hp != 0.0 or parent.defeat.is_empty() or clear_notification != "delivered" or (parent.stage != "cleared" and not (dead and parent.stage == "cancelled")): return "Local passage follows actual finite second-pool defeat and delivery"
	elif clear_notification == "delivered" and not state.pending_clear: return "Delivered clear notification retains its host intent until native gate opens"
	if state.pending_clear and (clear_notification != "delivered" or finite.actor.hp != 0.0): return "Queued passage intent requires actual delivered defeat"
	if dead:
		if not state.scheduler.reservations.is_empty() or foot.status == "running": return "Native fatal barrier closes all five owner leases before capture"
	return ""

func _rehearsal_view_error(state: Dictionary) -> String:
	var view: Dictionary = state.rehearsal_view
	var foot: Dictionary = state.rehearsal
	if foot.status != "running": return "" if view.is_empty() else "Inactive approach Foot must not retain a live view promise"
	if not Codec.keys_error(view, ["cycle", "reservation_id", "landing", "attack_position", "primary_time_s", "response_complete_s", "equipment_ids"]).is_empty() or view.cycle != foot.cycle or view.reservation_id != foot.exchange.id or not Codec.is_vector3(view.landing) or not Codec.is_vector3(view.attack_position) or not view.equipment_ids is Dictionary or not Codec.in_range(view.primary_time_s, foot.exchange.active_until_s, foot.exchange.recovery_until_s) or not Codec.in_range(view.response_complete_s, view.primary_time_s, foot.exchange.recovery_until_s): return "Exact finite original approach-foot view receipt required"
	var gear: CinderEquipment = AdmissionEquipment.new()
	if not gear.restore(view.equipment_ids): return "Original approach response gear must remain canonical"
	var stats: Dictionary = gear.resolved_stats()
	if view.response_complete_s != float(view.primary_time_s) + float(stats.primary_cooldown): return "Approach response retains the full original ordinary-primary cadence"
	var landing: Vector3 = Codec.read_vector3(view.landing)
	var attack: Vector3 = Codec.read_vector3(view.attack_position)
	if not _saved_point_supported(landing) or not _saved_point_supported(attack): return "Approach view promises real dry supported positions"
	if Geometry.planar(attack - REHEARSAL_AT).length() > float(stats.primary_range) - CinderThreatScheduler.SKIN + 0.00001: return "Approach view retains the ordinary reachable low opening"
	return ""

func _saved_point_supported(point: Vector3) -> bool:
	if not point.is_finite(): return false
	var radius: float = CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN
	for floor: Dictionary in _floor_records:
		var rect: Rect2 = floor.safe_rect.grow(-radius)
		var shape: CollisionShape3D = floor.collision
		var top: float = shape.global_position.y + (shape.shape as BoxShape3D).size.y * 0.5
		if point.x >= rect.position.x - 0.00001 and point.x <= rect.end.x + 0.00001 and point.z >= rect.position.y - 0.00001 and point.z <= rect.end.y + 0.00001 and absf(point.y + CinderThreatScheduler.CAPSULE_CENTER_Y - CinderThreatScheduler.CAPSULE_HEIGHT * 0.5 - top) <= CinderThreatScheduler.FEET_TOLERANCE: return true
	return false

func _transport_native_error() -> String:
	if not get_tree().paused or not runtime_error.is_empty() or not _native_prefix_valid() or not is_instance_valid(_sentry) or not _parent_api_present() or not bool(_bait.call("is_bound_to", hero)): return "L5 requires its intact paused native whole unit"
	if _local_cue_publications > 0: return "L5 cannot capture or restore inside native contact cue publication"
	if _scheduler.get_script() != SchedulerScript or _familiar.get_script() != FamiliarExchange or _rehearsal.get_script() != Mechanism or _bait.get_script() != BaitScript or _sentry.get_script() != sentry_parent_script or _sentry.get_parent() != self: return "Original exact whole native script bindings required"
	var bindings: Dictionary = scheduler_bindings()
	if not Codec.keys_error(bindings.owners, [SCOUT_ORDER[0], SCOUT_ORDER[1], REHEARSAL_ID, "A2-L5:dying-sentry", "A2-L5:near-foot"]).is_empty(): return "Complete exact five persistent owner bijection required"
	var ids: Dictionary = {}
	for node: Variant in bindings.owners.values():
		if not node is Node3D or not is_instance_valid(node) or not node.is_inside_tree() or not node.is_node_ready() or node.is_queued_for_deletion() or not actual_world_root().is_ancestor_of(node) or node.get_world_3d() != get_world_3d() or ids.has(node.get_instance_id()): return "Five actual owners cannot be replaced, lost or aliased"
		ids[node.get_instance_id()] = true
	for id: String in SCOUT_ORDER:
		if _actors[id].get_script() != ScoutActor or _actors[id].get_parent() != self or _actors[id].position != SCOUTS[id] or _actors[id].basis != Basis.IDENTITY: return "Original anchored familiar actors required"
	if _rehearsal.position != REHEARSAL_AT or _rehearsal.basis != Basis.IDENTITY or _rehearsal.get_parent() != self or _rehearsal_art.position != REHEARSAL_AT or _rehearsal_art.get_script() != FootVisual: return "Original separate approach owner and cosmetic feet required"
	if global_transform != Transform3D.IDENTITY: return "Authored root/world anchors cannot shift during transport"
	for index: int in range(FLOORS.size()):
		var record: Dictionary = _floor_records[index]
		var spec: Dictionary = FLOORS[index]
		var shape: CollisionShape3D = record.collision
		var rect: Rect2 = spec.rect
		if record.id != spec.id or record.safe_rect != rect.grow(-0.002) or shape.disabled or not shape.shape is BoxShape3D or shape.transform != Transform3D.IDENTITY or shape.get_parent().global_transform != Transform3D(Basis.IDENTITY, Vector3(rect.get_center().x, -0.25, rect.get_center().y)) or (shape.shape as BoxShape3D).size != Vector3(rect.size.x, 0.5, rect.size.y): return "All six native authored floor boxes remain exact"
	for id: String in ["entry", "departure"]:
		var gate: Dictionary = _gates[id]
		var z: float = 3.18 if id == "entry" else -3.18
		if not gate.shape.shape is BoxShape3D or gate.shape.transform != Transform3D.IDENTITY or gate.shape.get_parent().global_transform != Transform3D(Basis.IDENTITY, SENTRY_AT + Vector3(0, 0.4, z)) or (gate.shape.shape as BoxShape3D).size != Vector3(5.34, 0.8, 0.12) or gate.mesh.visible != not gate.shape.disabled: return "Gate capture requires the settled actual authored collider/visible prop barrier"
	for beat: String in _contact_cues:
		var error: String = _contact_native_error(_contact_cues[beat], "available" if STAGES[_stage] == beat else "clear", Vector3(0, 0.025, CONTACTS[beat].region.get_center().y))
		if not error.is_empty(): return error
	return _contact_native_error(_exit_cue, "active" if _exit_requested else ("available" if is_completed() else "clear"), Vector3(0, 0.025, EXIT_REGION.get_center().y))

func _contact_native_error(cue: Variant, expected: String, at: Vector3) -> String:
	if not cue is CinderInteractionCue or not is_instance_valid(cue) or not cue.is_inside_tree() or not cue.is_node_ready() or cue.is_queued_for_deletion() or not cue.visible or cue.get_script() != InteractionCue or cue.position != at or cue.basis != Basis.IDENTITY: return "Required native contact/exit cue binding cannot be replaced or hidden"
	var value: Dictionary = cue.state()
	# An earned checkpoint can hold pause before root110 derives the newly
	# available contact; clear remains honest and grants no interaction. A
	# visible available marker may only identify the actual current contact.
	if value.state not in ["clear", expected] or value.required != true or value.trigger not in (["attack", "contact"] if value.state == "clear" else ["contact"]) or value.visible != (value.state != "clear"): return "Current contact marker cannot advertise a different authored action"
	var raw: Variant = cue.get_node_or_null("RequiredInteractionMarker")
	if not raw is MeshInstance3D or not is_instance_valid(raw) or not raw.is_inside_tree() or raw.is_queued_for_deletion() or raw.transform != Transform3D(Basis.IDENTITY, Vector3.UP * 0.025) or raw.visible != value.visible or raw.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF or not raw.material_override is StandardMaterial3D: return "Required contact marker mesh/native policy lost"
	var material: StandardMaterial3D = raw.material_override
	if material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED or material.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA or material.cull_mode != BaseMaterial3D.CULL_DISABLED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST or material.no_depth_test or material.albedo_texture != null or material.render_priority != 0: return "Required ordinary contact alpha/depth/material policy changed"
	if value.state == "clear": return "" if raw.mesh == null else "Cleared contact cannot retain marker geometry"
	var color: Color = Color(1.0, 0.98, 0.87, 1.0) if value.state == "active" else Color(0.88, 0.92, 0.82, 0.85)
	if material.albedo_color != color or raw.mesh == null or raw.mesh.get_faces() != CueMesh.interaction_mesh(value.state, "contact").get_faces(): return "Required native available/contact geometry was altered"
	return ""

func _on_local_cue_publication(_state: Dictionary) -> void:
	_local_cue_publications += 1
	_local_cue_token += 1
	_finish_local_cue_publication.call_deferred(_local_cue_token)

func _finish_local_cue_publication(_token: int) -> void:
	_local_cue_publications = maxi(_local_cue_publications - 1, 0)

func _on_enter_restore_candidate(local: Dictionary, saved_player: Dictionary) -> String:
	var error: String = _local_shape_error(local, saved_player)
	if not error.is_empty(): return error
	if not _actors.is_empty() or is_instance_valid(_scheduler) or is_instance_valid(_sentry): return "L5 restore construction requires an unentered actual source topology"
	# Only a fresh paused nonplayable candidate may construct saved gate
	# topology. These are authored booleans already tied to earned stage; no
	# live Hero, source HP, phase, clock or proof is written here.
	for id: String in ["entry", "departure"]:
		_gates[id].shape.disabled = not local.gate_states[id]
		_gates[id].mesh.visible = local.gate_states[id]
	_construction_profile = local.profile_id
	_quiet_projection = true
	_on_enter_level()
	_quiet_projection = false
	_construction_profile = ""
	if not runtime_error.is_empty(): return runtime_error
	return _whole_local_error(local, saved_player)

func snapshot_state() -> Dictionary:
	var result: Dictionary = super.snapshot_state()
	if not result.is_empty():
		last_snapshot_error = _progress_error(result)
		if not last_snapshot_error.is_empty(): return {}
	return result

func snapshot_error(saved: Dictionary) -> String:
	var error: String = super.snapshot_error(saved)
	return error if not error.is_empty() else _progress_error(saved)

func snapshot_error_with_player(saved: Dictionary, saved_player: Dictionary) -> String:
	var error: String = super.snapshot_error_with_player(saved, saved_player)
	return error if not error.is_empty() else _progress_error(saved)

func restore_state(saved: Dictionary) -> bool:
	if not is_instance_valid(hero): last_snapshot_error = "Restore requires bound actual native Player"; return false
	var player: Dictionary = hero.snapshot_state()
	last_snapshot_error = "Restore requires complete paused actual Player" if player.is_empty() else snapshot_error_with_player(saved, player)
	if not last_snapshot_error.is_empty(): return false
	var accepted: bool = super.restore_state(saved)
	if accepted and not runtime_error.is_empty(): last_snapshot_error = runtime_error; return false
	return accepted

func _progress_error(outer: Dictionary) -> String:
	var progress: Dictionary = outer.progress
	var local: Dictionary = outer.local
	var completed: bool = local.stage == 10 and not local.completion_pending
	if progress.completed != completed or progress.completion_id != ("dead-london-discovery" if completed else "") or progress.contact_exit_id != ("dead-london-to-act3" if local.exit_requested else ""): return "Whole L5 completion/exit must equal real quiet coda progress"
	var earned: Array[String] = _earned_checkpoint_ids(local)
	var processed: Array[String] = earned.duplicate()
	if local.pending_checkpoints.size() > earned.size(): return "Checkpoint pending tail exceeds earned progress"
	for index: int in range(local.pending_checkpoints.size()):
		var expected: String = earned[earned.size() - local.pending_checkpoints.size() + index]
		if local.pending_checkpoints[index].id != expected: return "Pending checkpoints must be the exact unprocessed earned suffix"
	processed.resize(earned.size() - local.pending_checkpoints.size())
	if progress.checkpoint_ids.size() != processed.size(): return "Outer checkpoint history must equal processed earned prefix"
	for id: String in processed:
		if progress.checkpoint_ids.get(id) != OWN_CHECKPOINT_KINDS[id]: return "Outer checkpoint ID/kind cannot fabricate or omit earned request"
	var latest: String = "" if processed.is_empty() else processed.back()
	if progress.checkpoint_id != latest or progress.checkpoint_kind != ("" if latest.is_empty() else OWN_CHECKPOINT_KINDS[latest]): return "Current protected request must equal latest processed earned boundary"
	return ""

func _restore_local_state(state: Dictionary) -> void:
	# Full prospective preflight has succeeded; actual complete Player has
	# already been quietly restored by Shell. Commit is synchronous: every
	# source first, ONE Scheduler next, all consumers last. No fresh proof or
	# public gameplay request, signals, clocks, damage/refill or topology repair.
	var player: Dictionary = hero.snapshot_state()
	var bindings: Dictionary = scheduler_bindings()
	if not _sentry.call("restore_source_state", state.sentry, bindings, player, state.scheduler): runtime_error = "Unexpected prevalidated B05 source commit refusal"; return
	for id: String in SCOUT_ORDER:
		if not _actors[id].call("restore_state", state.familiar.actors[id]): runtime_error = "Unexpected prevalidated familiar Actor commit refusal"; return
	if not _scheduler.restore_state(state.scheduler, bindings): runtime_error = "Unexpected prevalidated ONE Scheduler commit refusal"; return
	if not _familiar.call("restore_state", state.familiar, bindings): runtime_error = "Unexpected prevalidated familiar consumer commit refusal"; return
	if not _rehearsal.restore_state(state.rehearsal, bindings): runtime_error = "Unexpected prevalidated rehearsal consumer commit refusal"; return
	if not _sentry.call("restore_consumers_state", state.sentry, bindings, player, state.scheduler): runtime_error = "Unexpected prevalidated B05 consumer commit refusal"; return
	_stage = state.stage
	_profile = state.profile_id
	_defeated.assign(state.defeated_scouts)
	_contacts.assign(state.contacts)
	_contact_seen = state.contact_seen
	_rehearsal_complete = state.rehearsal_complete
	_sentry_started = state.sentry_started
	_phase2_checkpoint = state.phase2_checkpoint
	_phase2_admitted_after_checkpoint = state.phase2_admitted_after_checkpoint
	_passage_open = state.passage_open
	_last_action_sequence = state.last_action_sequence
	_pending_defeats.assign(state.pending_defeats)
	_pending_phase2 = state.pending_phase2
	_pending_clear = state.pending_clear
	_pending_checkpoints.assign(state.pending_checkpoints)
	_completion_pending = state.completion_pending
	_exit_requested = state.exit_requested
	_rehearsal_view = state.rehearsal_view.duplicate(true)
	for key: String in ["landing", "attack_position"]:
		if _rehearsal_view.has(key): _rehearsal_view[key] = Codec.read_vector3(_rehearsal_view[key])
	_sentry_foot_view.clear()
	_pose_rehearsal(_rehearsal.state())
	_quiet_projection = true
	# Base copies outer progress AFTER this hook. Reconstruct exit marker from
	# the validated local completion tuple rather than stale receiver progress.
	var blocks: Dictionary = {}
	for beat: String in _contact_cues:
		blocks[beat] = _contact_cues[beat].is_blocking_signals()
		_contact_cues[beat].set_block_signals(true)
		if STAGES[_stage] == beat: _contact_cues[beat].present("available", "contact")
		else: _contact_cues[beat].clear()
	for beat: String in _contact_cues: _contact_cues[beat].set_block_signals(blocks[beat])
	var exit_blocked: bool = _exit_cue.is_blocking_signals()
	_exit_cue.set_block_signals(true)
	if _stage == 10 and not _completion_pending: _exit_cue.present("active" if _exit_requested else "available", "contact")
	else: _exit_cue.clear()
	_exit_cue.set_block_signals(exit_blocked)
	for id: String in _actors: _actors[id].visible = _defeated.has(id) or (_stage == 1 and id == SCOUT_ORDER[0]) or (_stage == 4 and id == SCOUT_ORDER[1])
	if not _project_restored_presentation(): runtime_error = "Unexpected quiet restored native art/view reconstruction refusal"
	_update_objective()
	_quiet_projection = false

func _on_hero_died() -> void:
	if is_instance_valid(_familiar): _familiar.call("cancel_all", "hero_defeated")
	if is_instance_valid(_rehearsal): _rehearsal.cancel("hero_defeated")
	# Parent owns its actual native death barrier; do not cleanup/erase pending
	# earned receipts or disarm full actor capture while the dead unit is retained.
	_rehearsal_view.clear()

func _on_exit_level() -> void:
	set_physics_process(false)
	if is_instance_valid(hero):
		if hero.world_action_executed.is_connected(_on_world_action): hero.world_action_executed.disconnect(_on_world_action)
		if hero.died.is_connected(_on_hero_died): hero.died.disconnect(_on_hero_died)
	if is_instance_valid(_approach_guard): _approach_guard.set_physics_process(false)
	if is_instance_valid(_sentry):
		for row: Array in [["phase_checkpoint_eligible", _on_phase2_eligible], ["sentry_cleared", _on_sentry_cleared], ["runtime_failed", _fault]]:
			if _sentry.is_connected(row[0], row[1]): _sentry.disconnect(row[0], row[1])
		_sentry.call("cleanup")
	if is_instance_valid(_familiar):
		if _familiar.is_connected("scout_defeated", _on_scout_defeated): _familiar.disconnect("scout_defeated", _on_scout_defeated)
		_familiar.call("cleanup")
	if is_instance_valid(_rehearsal):
		_rehearsal.set_physics_process(false)
		if _rehearsal.state_changed.is_connected(_on_rehearsal_state): _rehearsal.state_changed.disconnect(_on_rehearsal_state)
		if _rehearsal.hit_resolved.is_connected(_on_rehearsal_hit): _rehearsal.hit_resolved.disconnect(_on_rehearsal_hit)
		_rehearsal.cancel("dead_london_exit")
		_rehearsal.queue_free() # Native public _exit_tree disconnects/releases owner.
	if is_instance_valid(_bait): _bait.call("release")
	for id: String in _actors:
		if is_instance_valid(_actors[id]): _actors[id].call("cleanup")
	if is_instance_valid(_scheduler): _scheduler.end_encounter("dead_london_exit")
	_rehearsal_view.clear()
	_sentry_foot_view.clear()
	_optional_meshes.clear()
	_kit.clear()
	_pending_defeats.clear()
	_pending_checkpoints.clear()

func _fault(reason: String) -> void:
	runtime_error = reason
	set_physics_process(false)
	if is_instance_valid(_familiar): _familiar.call("cancel_all", "l5_runtime_fault")
	if is_instance_valid(_rehearsal): _rehearsal.cancel("l5_runtime_fault")
	# TODO parent add idempotent public cancel(reason) for aggregate faults;
	# until then cleanup disarms its sources and preserves no running authority.
	if is_instance_valid(_sentry) and _sentry.has_method("cleanup"): _sentry.call("cleanup")
