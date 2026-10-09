extends CinderLevel
## First A1-L3 functional component greybox. The five-room floor is present;
## only the initial three C31s and isolated C32 are exercised here. Full crowd
## approach, mushrooms, spore custody, progression and final art remain pending.

signal native_admission_published(source_id: String, answer: Dictionary)

const Layout = preload("res://scripts/acts/act1/mushroom_caverns_layout.gd")
const GrottoArt = preload("res://scripts/acts/act1/mushroom_grotto_art.gd")
const ActorScript = preload("res://scripts/acts/act1/mushroom_selenite.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const BodySweep = preload("res://scripts/combat/body_sweep.gd")
const WORLD_REVISION: int = 1
const SOURCE_IDS: Array[String] = ["umbrella-1", "umbrella-2", "umbrella-3", "lone-guard"]

@export_enum("Umbrella grove:0", "Lone guard:3") var initial_greybox_room: int = 0
@export var enable_swarm_approach: bool = false

var scheduler: CinderThreatScheduler
var sources: Dictionary = {}
var last_admission: Dictionary = {}
var last_encounter_error: String = ""
var greybox_clear: bool = false
var _running: bool = false
var _changing: bool = false
var _callback_depth: int = 0
var _activation_entitlement: String = ""
var _construction_error: String = ""
var _render_sources: Dictionary = {}
var _framing: Dictionary = {}
var _forecast_points: Array = []
var _forecast_owner: String = ""
var _forecast_premise: Dictionary = {} # Optional actual-pose hint, never a lease/proof/world cache.
var _retained_sources: Dictionary = {}
var _retained_collisions: Dictionary = {}
var _retained_capsules: Dictionary = {}
var _retained_cues: Dictionary = {}
var _source_callbacks: Dictionary = {}
var _floor_collision: CollisionShape3D
var _floor_shape: BoxShape3D
var _floor_transform: Transform3D
var _scenery_art: Node3D
var _approach_enabled: bool = false
var _approach_forecasts: Dictionary = {}
var _approach_camera_requests: Dictionary = {}
var last_approach_error: String = ""
var _stalk_specs: Array = []
var _stalk_specs_bytes: PackedByteArray


func _ready() -> void:
	process_physics_priority = 200
	_approach_enabled = enable_swarm_approach
	_construction_error = _component_configuration_error()
	if not _construction_error.is_empty(): return
	_stalk_specs = _authored_stalk_specs().duplicate(true)
	_construction_error = Layout.stalk_specs_error(_stalk_specs)
	if not _construction_error.is_empty(): return
	_stalk_specs_bytes = var_to_bytes(_stalk_specs)
	var built: bool = Layout.build_geometry(self, _stalk_specs)
	if not built:
		_construction_error = "Validated whole mushroom geometry could not be built"
		return
	_scenery_art = GrottoArt.build_geometry_art(self, _stalk_specs)
	if not is_instance_valid(_scenery_art):
		_construction_error = "Authored grotto scenery could not bind the actual layout"
		return
	_floor_collision = get_node("Floor/CollisionShape3D") as CollisionShape3D
	_floor_shape = _floor_collision.shape as BoxShape3D
	_floor_transform = _floor_collision.global_transform
	scheduler = CinderThreatScheduler.new()
	scheduler.name = "MushroomThreatScheduler"
	add_child(scheduler)
	for id: String in _all_source_ids():
		var spec: Dictionary = _source_spec(id)
		var actor: Act1MushroomSelenite = ActorScript.new()
		actor.name = id.replace("-", "_")
		actor.position = spec.position
		if not actor.configure(spec.role_id, id, true, spec.approach):
			_construction_error = actor.last_error
			actor.free()
			return
		add_child(actor)
		actor.activation_guard = Callable(self, "_activation_permitted")
		actor.presentation_guard = Callable(self, "_source_presentation_error").bind(id)
		actor.approach_guard = Callable(self, "_source_approach_error").bind(id)
		sources[id] = actor
		_retained_sources[id] = actor
		var collision := actor.get_node("BodyCollision") as CollisionShape3D
		_retained_collisions[id] = collision
		_retained_capsules[id] = collision.shape
		_retained_cues[id] = actor.get_cue()
	objective_text = _initial_objective_text()


func _authored_stalk_specs() -> Array:
	return Layout.STALK_SPECS.duplicate(true) # Original component/default world.


## Defaults deliberately retain the four-source isolated component contract.
## A normal-route subclass supplies authored membership, never another runtime.
func _all_source_ids() -> Array[String]:
	return SOURCE_IDS.duplicate()


func _source_spec(id: String) -> Dictionary:
	var index: int = SOURCE_IDS.find(id)
	return {"role_id": "C31" if index < 3 else "C32", "position": Layout.SOURCE_POINTS["umbrella"][index] if index < 3 else Layout.SOURCE_POINTS["lone-guard"][0], "approach": _approach_enabled and index < 3}


func _component_configuration_error() -> String:
	if initial_greybox_room not in [0, 3]: return "Only the first grove and isolated guard component previews exist"
	if _approach_enabled and initial_greybox_room != 0: return "Only the three-swarmer grove opts into authored approach"
	return ""


func _initial_objective_text() -> String:
	return "GREYBOX · THREE SWARMERS\nONE PREPARED STRIKE · ORDINARY PRIMARY" if initial_greybox_room == 0 else "GREYBOX · LONE SPEAR GUARD\nREAD ITS LANE · FLANK WITH AN ORDINARY PRIMARY"


func contract_error() -> String:
	return _construction_error if not _construction_error.is_empty() else super.contract_error()


func _on_enter_level() -> void:
	_running = true
	for id: String in _all_source_ids():
		var actor: Act1MushroomSelenite = sources[id]
		if not actor.bind(scheduler, hero):
			_entry_failed(actor.last_error)
			return
		var callback: Callable = Callable(self, "_on_source_state").bind(id)
		actor.state_changed.connect(callback)
		_source_callbacks[id] = callback
	hero.died.connect(_on_hero_died)
	if not hero.fired.is_connected(_on_hero_fired): hero.fired.connect(_on_hero_fired)
	_refresh_render_state()
	if not _running: return
	_start_initial_encounter()


func _start_initial_encounter() -> void:
	var profile: String = String(shared_shell.call("get_difficulty_preference")) if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference") else "standard"
	_changing = true
	if not scheduler.begin_encounter(profile, _encounter_id(), WORLD_REVISION):
		_changing = false
		_entry_failed(scheduler.last_error)
		return
	for id: String in current_source_ids():
		_activation_entitlement = id
		var accepted: bool = (sources[id] as Act1MushroomSelenite).activate()
		_activation_entitlement = ""
		if not accepted:
			_changing = false
			_entry_failed((sources[id] as Act1MushroomSelenite).last_error)
			return
	_changing = false
	_refresh_render_state()


func _entry_failed(reason: String) -> void:
	_clear_forecast_hint()
	_construction_error = reason
	last_encounter_error = reason
	_running = false
	push_error(reason)


func current_source_ids() -> Array[String]:
	return ["umbrella-1", "umbrella-2", "umbrella-3"] if initial_greybox_room == 0 else ["lone-guard"]


func _activation_permitted(id: String) -> bool:
	return _running and _changing and _activation_entitlement == id and id in current_source_ids()


func _encounter_id() -> String:
	return "a1_l3_umbrella_greybox" if initial_greybox_room == 0 else "a1_l3_guard_greybox"


func _physics_process(delta: float) -> void:
	_cleanup_forecast_hint() # Storage cleanup belongs to owned physics, not pure queries.
	if not _running or _changing or not is_instance_valid(hero): return
	# Presentation settles at priority200 after real consumers, including death.
	_refresh_render_state()
	if not _running: return
	for id: String in _approach_forecasts.keys():
		if not _render_sources[id].get("approach_driving", false): _approach_forecasts.erase(id)
	for id: String in _approach_camera_requests.keys():
		var state: Dictionary = _render_sources[id]
		if state.dead or state.dormant or not state.reservation_id.is_empty() or float(state.hurt_left_s) > 0.0: _approach_camera_requests.erase(id)
	for id: String in _framing.keys():
		if _render_sources[id].reservation_id != _framing[id].reservation_id: _framing.erase(id)
	if hero.dead: return
	greybox_clear = true
	var preparing: int = 0
	for id: String in current_source_ids():
		var state: Dictionary = _render_sources[id]
		if not state.dead: greybox_clear = false
		if state.phase in ["warning", "lock"]: preparing += 1
	if greybox_clear:
		objective_text = "COMPONENT GREYBOX CLEAR\nFULL SPORE CHAMBERS AND COURT ROUTE IN PRODUCTION"
		return
	# Authored first-room policy limits preparing sources; the shared Scheduler
	# still owns profile budgets, overlap proofs, cooldown and all phase clocks.
	if preparing > 0 or not hero.get_threat_response_state().stable: return
	for id: String in current_source_ids():
		var actor: Act1MushroomSelenite = sources[id]
		var state: Dictionary = _render_sources[id]
		if state.dead or state.dormant or not state.reservation_id.is_empty() or float(state.hurt_left_s) > 0.0: continue
		var distance: float = Vector2(actor.global_position.x - hero.global_position.x, actor.global_position.z - hero.global_position.z).length()
		if distance < 0.1 or distance > 4.5: continue
		_admit(id, delta)
		if not _render_sources[id].reservation_id.is_empty(): break


func _admit(id: String, delta: float) -> void:
	_cleanup_forecast_hint()
	# One feasible stopped proposal waits for the real camera update. A different
	# source's rejected preview must not erase that selected owner's lookahead.
	if not _forecast_owner.is_empty() and _forecast_owner != id: return
	var actor: Act1MushroomSelenite = sources[id]
	var context: Dictionary = response_context(String(_render_sources[id].role_id))
	var target: Vector3 = hero.global_position
	var preview: Dictionary = actor.preview_start(target, context)
	if not preview.get("accepted", false):
		_clear_forecast_hint(id)
		last_encounter_error = String(preview.get("reason", "Native preview rejected"))
		return
	if _approach_enabled:
		var gap_error: String = _source_path_gap_error(id, actor.global_position, preview.candidate.opening_position, delta)
		if not gap_error.is_empty():
			_clear_forecast_hint(id)
			last_encounter_error = gap_error
			return
	if not _proof_window(preview.proof, preview.candidate):
		_clear_forecast_hint(id)
		last_encounter_error = "Ordinary primary must fit the actual stopped source recovery"
		return
	var proposed: Array = _actor_points(id, preview.candidate.opening_position)
	proposed.append_array(_lane_points(preview.candidate.geometry))
	proposed.append_array(_response_points(preview.proof.landing, preview.proof.attack_position))
	_forecast_owner = id
	_forecast_premise = {"source": actor, "source_instance_id": actor.get_instance_id(), "source_transform": actor.global_transform, "source_facing": actor.pure_presentation_state().facing, "hero": hero, "hero_instance_id": hero.get_instance_id(), "hero_transform": hero.global_transform, "hero_facing": hero.facing}
	_forecast_points = proposed
	if not _forecast_hint_current():
		_clear_forecast_hint(id)
		last_encounter_error = "Optional lookahead requires the actual stopped source/Hero premise"
		return
	# The native whole plan may fit while CURRENT projection is still waiting.
	# Only a rejected plan discards this optional proposal; no fit grants a lease.
	if not _framing_ready(_camera_framing_points(), id): return
	# start() may notify an observer before returning its original native answer.
	# Keep that returned value independent from the writable diagnostic/cache.
	var answer: Dictionary = actor.start(target, context, preview)
	last_admission = answer.duplicate(true)
	if answer.get("accepted") != true:
		_clear_forecast_hint(id)
		last_encounter_error = String(answer.get("reason", "Native admission rejected"))
		return
	var custody_error: String = _admission_custody_error(id, answer)
	if not custody_error.is_empty():
		_reject_corresponding_admission(id, answer, custody_error)
		return
	_framing[id] = {"reservation_id": String(answer.reservation_id), "landing": answer.proof.landing, "attack_position": answer.proof.attack_position}
	_clear_forecast_hint(id)
	_refresh_render_state()
	custody_error = _admission_custody_error(id, answer)
	if not custody_error.is_empty():
		_reject_corresponding_admission(id, answer, custody_error)
		return
	if not _framing_ready(_camera_framing_points()):
		_reject_corresponding_admission(id, answer, "greybox_response_not_visible", "greybox_response_not_visible")
		return
	# The presentation read is pure; nevertheless do not publish a changed owner
	# or lease if an authored callback fault crossed this final boundary.
	custody_error = _admission_custody_error(id, answer)
	if not custody_error.is_empty():
		_reject_corresponding_admission(id, answer, custody_error)
		return
	last_encounter_error = ""
	_callback_depth += 1
	native_admission_published.emit(id, answer.duplicate(true))
	_callback_depth -= 1


## Pure post-start custody: never prune a lease, move a body, or emit a callback.
## A recorder runs inside the parent's publication callback, so the parent's
## _callback_depth is intentionally not an Actor/Scheduler readiness condition.
func _admission_custody_error(id: String, answer: Dictionary) -> String:
	if not is_inside_tree() or is_queued_for_deletion() or not _running or _changing or get_tree().paused or is_restore_candidate():
		return "Native admission requires the live unpaused playable parent"
	var correspondence: Dictionary = _corresponding_admission(id, answer)
	if correspondence.is_empty(): return "Returned admission no longer names the same retained actual owner/Player/Scheduler lease"
	var actual: Act1MushroomSelenite = correspondence.actor
	if id not in current_source_ids() or actual.dead or actual.dormant or hero.dead:
		return "Native admission source and Hero must remain living in the same current room"
	var response: Dictionary = actual.get_spore_response_state()
	if response.get("source_id") != id or response.get("alive") != true or response.get("outside_transaction") != true or correspondence.control.get("outside_transaction") != true:
		return "Native admission must finish the actual Actor and Scheduler callback barriers"
	if not answer.get("reservation") is Dictionary or var_to_bytes(correspondence.record) != var_to_bytes(answer.reservation):
		return "Returned native reservation differs from the actual current admitted exchange"
	return ""


## Return only a freshly corroborated retained owner with the SAME returned ID.
## No use of state(), reservations(), or reservation_state(): those may prune.
## This narrower ownership read also works after a direct pause or Hero death;
## it grants no playable admission, response proof, or cancellation receipt.
func _corresponding_admission(id: String, answer: Dictionary) -> Dictionary:
	if answer.get("accepted") != true or not answer.get("reservation_id") is String or String(answer.reservation_id).is_empty() or not is_inside_tree(): return {}
	var raw: Variant = sources.get(id)
	if not is_instance_valid(raw) or not raw is Act1MushroomSelenite: return {}
	var actual: Act1MushroomSelenite = raw
	if actual != _retained_sources.get(id) or actual.get_script() != ActorScript or not actual.is_inside_tree() or actual.is_queued_for_deletion() or actual.get_parent() != self: return {}
	if not is_instance_valid(hero) or not hero.is_inside_tree() or hero.is_queued_for_deletion() or not is_instance_valid(scheduler) or not scheduler.is_inside_tree() or scheduler.is_queued_for_deletion() or scheduler.get_parent() != self: return {}
	if actual.get_tree() != get_tree() or hero.get_tree() != get_tree() or scheduler.get_tree() != get_tree() or actual.get_world_3d() != get_world_3d() or hero.get_world_3d() != get_world_3d() or scheduler.get_world_3d() != get_world_3d() or not is_instance_valid(_world_root()): return {}
	var native: Dictionary = actual.get_spore_native_bindings()
	if native.get("api_revision") != ActorScript.SPORE_ACTOR_REVISION or native.get("actor_revision") != ActorScript.API_REVISION or native.get("source_id") != id or native.get("scheduler") != scheduler or native.get("player") != hero: return {}
	var control: Dictionary = scheduler.source_control_state(actual)
	if control.get("api_revision") != "scheduler-source-control-1" or control.get("source_instance_id") != actual.get_instance_id() or control.get("encounter_id") != _encounter_id() or control.get("world_revision") != WORLD_REVISION or not control.get("reservations") is Array or control.reservations.size() != 1: return {}
	var record: Variant = control.reservations[0]
	if not record is Dictionary or record.get("id") != answer.reservation_id or record.get("source_instance_id") != actual.get_instance_id() or record.get("response_actor_instance_id") != hero.get_instance_id(): return {}
	var presentation: Dictionary = actual.pure_presentation_state()
	if presentation.get("source_id") != id or presentation.get("reservation_id") != answer.reservation_id: return {}
	return {"actor": actual, "control": control, "record": record}


## Mutation is separate from the pure guard. Re-read custody after rejection;
## never cancel a replacement/new lease or repair accepted history/resources.
## Native actor.cancel preserves the original real Scheduler cooldown.
func _reject_corresponding_admission(id: String, answer: Dictionary, reason: String, cancel_reason: String = "owned_admission_custody_rejected") -> void:
	var correspondence: Dictionary = _corresponding_admission(id, answer)
	if not correspondence.is_empty():
		var actual: Act1MushroomSelenite = correspondence.actor
		var response: Dictionary = actual.get_spore_response_state()
		if response.get("outside_transaction") == true and correspondence.control.get("outside_transaction") == true:
			actual.cancel(cancel_reason)
	# Discard only this provisional response if it still names our rejected ID.
	# A different response/history is an honest fault, not ours to repin or erase.
	var frame: Variant = _framing.get(id)
	if frame is Dictionary and frame.get("reservation_id") == answer.get("reservation_id"): _framing.erase(id)
	_clear_forecast_hint(id)
	last_encounter_error = reason


## Optional presentation lifetime only. Fresh native preview/admission and all
## live body/world/resource checks still run; this stamp grants no permission.
func _forecast_hint_current() -> bool:
	if _forecast_points.is_empty() or _forecast_owner.is_empty() or _forecast_premise.is_empty() or not _running or _changing or not is_inside_tree() or is_queued_for_deletion() or _forecast_owner not in current_source_ids(): return false
	var raw: Variant = sources.get(_forecast_owner)
	if not is_instance_valid(raw) or not raw is Act1MushroomSelenite: return false
	var actor: Act1MushroomSelenite = raw
	if actor != _retained_sources.get(_forecast_owner) or actor != _forecast_premise.get("source") or actor.get_instance_id() != _forecast_premise.get("source_instance_id") or actor.get_script() != ActorScript or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.get_parent() != self: return false
	if not is_instance_valid(hero) or hero != _forecast_premise.get("hero") or hero.get_instance_id() != _forecast_premise.get("hero_instance_id") or not hero.is_inside_tree() or hero.is_queued_for_deletion() or hero.dead or not is_instance_valid(scheduler) or not scheduler.is_inside_tree() or scheduler.is_queued_for_deletion() or scheduler.get_parent() != self: return false
	if actor.get_tree() != get_tree() or hero.get_tree() != get_tree() or scheduler.get_tree() != get_tree() or actor.get_world_3d() != get_world_3d() or hero.get_world_3d() != get_world_3d() or scheduler.get_world_3d() != get_world_3d() or not is_instance_valid(_world_root()): return false
	if actor.global_transform != _forecast_premise.get("source_transform") or hero.global_transform != _forecast_premise.get("hero_transform") or hero.facing != _forecast_premise.get("hero_facing"): return false
	var native: Dictionary = actor.get_spore_native_bindings()
	if native.get("source_id") != _forecast_owner or native.get("scheduler") != scheduler or native.get("player") != hero: return false
	var state: Dictionary = actor.pure_presentation_state()
	if state.get("source_id") != _forecast_owner or state.get("dead") != false or state.get("dormant") != false or state.get("reservation_id") != "" or state.get("hurt_left_s") != 0.0 or state.get("approach_driving") != false or state.get("velocity") != Vector3.ZERO or state.get("facing") != _forecast_premise.get("source_facing"): return false
	var response: Dictionary = actor.get_spore_response_state()
	var control: Dictionary = scheduler.source_control_state(actor)
	if response.get("alive") != true or response.get("grounded") != true or response.get("outside_transaction") != true or control.get("source_instance_id") != actor.get_instance_id() or control.get("encounter_id") != _encounter_id() or control.get("world_revision") != WORLD_REVISION or control.get("outside_transaction") != true or not control.get("reservations") is Array or not control.reservations.is_empty(): return false
	var player_response: Dictionary = hero.get_threat_response_state()
	var dash: Dictionary = hero.get_committed_dash_state()
	return player_response.get("actor") == hero and player_response.get("stable") == true and player_response.get("motion", {}).get("velocity") == Vector3.ZERO and player_response.get("motion", {}).get("queued_dash") == Vector3.ZERO and dash.get("active") == false


func _clear_forecast_hint(owner: String = "") -> void:
	if not owner.is_empty() and _forecast_owner != owner: return
	_forecast_points.clear()
	_forecast_owner = ""
	_forecast_premise.clear()


func _cleanup_forecast_hint() -> void:
	if not _forecast_hint_current(): _clear_forecast_hint()


func _on_hero_fired(_kind: String) -> void:
	# Genuine accepted dash/slash/blast/hurt publication invalidates an unadmitted
	# response premise promptly. Actual leases/frames/approach maps are untouched.
	_clear_forecast_hint()


func _proof_window(proof: Dictionary, candidate: Dictionary) -> bool:
	return proof.get("uses_blast") == false and proof.get("uses_invulnerability") == false and Codec.is_number(proof.get("primary_time_s")) and Codec.is_number(proof.get("response_complete_s")) and float(proof.primary_time_s) >= float(candidate.active_until_s) and float(proof.response_complete_s) < float(candidate.recovery_until_s)


func response_context(role_id: String = "") -> Dictionary:
	var directions: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]: directions.append(Vector3(x, 0, z).normalized())
	for x: float in [-0.6, 0.6, -0.8, 0.8]:
		var z: float = sqrt(1.0 - x * x)
		directions.append(Vector3(x, 0, z))
		directions.append(Vector3(x, 0, -z))
	# Prefer a visible offset approach to an almost coincident guard/Hero pose
	# seen in first portrait07. These are authored fixed direction choices only;
	# the native solver still selects and proves the real safe return and range.
	var returns: Array[Vector3] = []
	if role_id == "A1-E3" or (role_id.is_empty() and initial_greybox_room == 3):
		for x: float in [0.98, -0.98]:
			var z: float = sqrt(1.0 - x * x)
			returns.append(Vector3(x, 0, -z))
			returns.append(Vector3(x, 0, z))
	# Native response lists are bounded to16. Replace four redundant return
	# angles for the guard rather than extending that public contract.
	returns.append_array(directions.slice(0, 12) if not returns.is_empty() else directions)
	return {"encounter_id": _encounter_id(), "world_revision": WORLD_REVISION, "recognition_s": 0.18, "attack_input_margin_s": 0.08, "escape_directions": directions, "return_directions": returns, "floor_regions": [{"collision": _floor_collision, "safe_rect": Layout.SAFE_RECT}], "world_root": _world_root()}


func _world_root() -> Node3D:
	if not is_instance_valid(hero) or not is_instance_valid(scheduler) or not is_inside_tree(): return null
	var ancestor: Node = get_parent()
	while is_instance_valid(ancestor):
		if ancestor is Node3D and ancestor.is_ancestor_of(hero) and ancestor.is_ancestor_of(scheduler) and (ancestor as Node3D).get_world_3d() == get_world_3d(): return ancestor as Node3D
		ancestor = ancestor.get_parent()
	return null


func scheduler_bindings() -> Dictionary:
	return {"world_root": _world_root(), "owners": sources.duplicate(), "floors": {"mushroom-floor": {"collision": _floor_collision, "safe_rect": Layout.SAFE_RECT}}}


func _refresh_render_state() -> void:
	for id: String in _all_source_ids():
		var actor := sources.get(id) as Act1MushroomSelenite
		if not is_instance_valid(actor) or actor != _retained_sources.get(id) or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.get_parent() != self:
			_render_sources[id] = {}
			last_encounter_error = "Retained actual source is unavailable: " + id
			_running = false
			continue
		_render_sources[id] = actor.state()


func _on_source_state(state: Dictionary, id: String) -> void:
	_render_sources[id] = state.duplicate(true)
	if state.dead or state.dormant or not state.reservation_id.is_empty() or float(state.hurt_left_s) > 0.0: _clear_forecast_hint(id)
	if state.reservation_id.is_empty() or state.dead: _framing.erase(id)


func _source_presentation_error(id: String) -> String:
	var actor := sources.get(id) as Act1MushroomSelenite
	if not is_instance_valid(actor) or actor != _retained_sources.get(id): return "Retained source presentation is unavailable"
	var error: String = _scenery_error()
	if error.is_empty(): error = actor.art_binding_error()
	return error if not error.is_empty() else _containment_error(_camera_framing_points())


## Movement-only actual-world guard called by the owning idle actor. No physical
## state, clock, lease or input changes. It publishes prospective presentation
## corners for the shared camera; never use this callback as a snapshot validator.
func _source_approach_error(plan: Dictionary, id: String) -> String:
	var actor := sources.get(id) as Act1MushroomSelenite
	if not _running or _changing or not is_instance_valid(hero) or hero.dead or enable_swarm_approach != _approach_enabled or not _approach_enabled or id not in current_source_ids() or not is_instance_valid(actor) or actor != _retained_sources.get(id) or actor.get_parent() != self:
		return "Retained opt-in grove source and entered parent required"
	var braking_only: bool = plan.get("reason") == "disabled_braking"
	if not braking_only:
		# A fresh drive replaces its presentation request, including when native
		# world/spacing validation rejects. No rejected geometry becomes lookahead.
		_approach_camera_requests.erase(id)
		_approach_forecasts.erase(id)
	var error: String = _floor_error()
	if error.is_empty(): error = _scenery_error()
	if error.is_empty(): error = actor.art_binding_error()
	if not error.is_empty():
		last_approach_error = error
		return error
	if not plan.get("accepted", false) or not plan.get("next_position") is Vector3 or not plan.get("braking_position") is Vector3 or not plan.get("velocity") is Vector3 or not plan.get("delta_s") is float or not Codec.in_range(plan.delta_s, 0.000001, 0.25):
		return "Complete actor-owned approach proposal required"
	# Reading actor.state() would call the legacy pruning Scheduler accessor.
	# Parent settles this conservative cache after native physics and every
	# admission; stale ended leases may delay a drive, never authorize one.
	var own_state: Dictionary = _render_sources.get(id, {})
	if own_state.is_empty(): return "Settled parent source state required"
	if own_state.dead or own_state.dormant or not own_state.reservation_id.is_empty() or float(own_state.hurt_left_s) > 0.0:
		return "Approach cannot own native combat or hurt motion"
	for other_id: String in current_source_ids():
		if other_id == id: continue
		var other := sources.get(other_id) as Act1MushroomSelenite
		if not is_instance_valid(other) or other != _retained_sources.get(other_id): return "Retained neighboring capsule required"
		var other_state: Dictionary = _render_sources.get(other_id, {})
		if other_state.is_empty(): return "Settled neighboring source state required"
		if not braking_only and not other_state.reservation_id.is_empty():
			return "Brake authored approach while another source retains its native exchange"
	var start: Vector3 = actor.global_position
	var next: Vector3 = plan.next_position
	var finish: Vector3 = plan.braking_position
	if absf(next.y - start.y) > BodySweep.EPSILON or absf(finish.y - start.y) > BodySweep.EPSILON:
		return "Approach forecast must retain the actual grounded height"
	var floors: Array = [{"collision": _floor_collision, "safe_rect": Layout.SAFE_RECT}]
	# Two actual native queries retain the bent proposal rather than assuming
	# that checking endpoints proves support or collision along its path.
	for segment: Array in [[start, next], [next, finish]]:
		var measured: Dictionary = BodySweep.sweep(actor, Transform3D(Basis.IDENTITY, segment[0]), segment[1] - segment[0], floors)
		if measured.has("error") or measured.get("collided", true):
			last_approach_error = String(measured.get("error", "Actual scenery obstructs the complete approach/braking path"))
			return last_approach_error
		if (measured.end as Vector3).distance_to(segment[1]) > BodySweep.position_rounding_bound(segment[0], segment[1]):
			return "Actual approach sweep shortened its proposed stopping path"
	var own_capsule := _retained_capsules.get(id) as CapsuleShape3D
	var hero_collision := hero.get_node_or_null("BodyCollision") as CollisionShape3D
	if not is_instance_valid(own_capsule) or not is_instance_valid(hero_collision) or not hero_collision.shape is CapsuleShape3D:
		return "Actual retained source and shared Player capsules required"
	var hero_endpoint: Vector3 = hero.global_position
	var dash: Dictionary = hero.get_committed_dash_state()
	if dash.get("active", false): hero_endpoint = dash.origin + dash.direction * float(dash.distance)
	var obstacles: Array[Dictionary] = [{"from": hero.global_position, "to": hero_endpoint, "radius": (hero_collision.shape as CapsuleShape3D).radius}]
	var neighbors: Dictionary = _neighbor_paths(id, float(plan.delta_s))
	if not neighbors.get("accepted", false): return String(neighbors.reason)
	obstacles.append_array(neighbors.paths)
	for obstacle: Dictionary in obstacles:
		var minimum: float = own_capsule.radius + float(obstacle.radius) + 0.12
		for segment: Array in [[start, next], [next, finish]]:
			if _planar_segment_distance(segment[0], segment[1], obstacle["from"], obstacle["to"]) < minimum:
				last_approach_error = "Actual approach/braking capsule needs a clear neighboring body gap"
				return last_approach_error
	# Every verified C31 pose/facing has the same full 48x80 native frame and
	# foot-pivot billboard settings. Thus these full quads also enclose the next
	# front/side/back texture chosen after a gradual turn; opaque pixels need not
	# have identical bounds. Art binding guards retain all native frame dimensions.
	var points: Array = _unique_points(_actor_points(id, next) + _actor_points(id, finish))
	error = _containment_error(_unique_points(_camera_framing_points() + points))
	if error.is_empty():
		_approach_forecasts[id] = points
		if not braking_only: _approach_camera_requests.erase(id)
	elif not braking_only:
		# Geometry has passed. Publish only a camera request, not accepted motion;
		# a stopped source's zero-speed fallback must not erase that request.
		_approach_camera_requests[id] = points
	last_approach_error = error
	return error


func _neighbor_paths(id: String, delta: float) -> Dictionary:
	var paths: Array[Dictionary] = []
	for other_id: String in current_source_ids():
		if other_id == id: continue
		var other := sources.get(other_id) as Act1MushroomSelenite
		if not is_instance_valid(other) or other != _retained_sources.get(other_id) or other.get_parent() != self or not other.is_inside_tree() or other.is_queued_for_deletion():
			return {"accepted": false, "reason": "Retained neighboring native source required"}
		var state: Dictionary = _render_sources.get(other_id, {})
		if state.is_empty(): return {"accepted": false, "reason": "Settled neighboring native source state required"}
		if state.dead or state.dormant: continue
		var body_error: String = other.body_binding_error()
		if not body_error.is_empty(): return {"accepted": false, "reason": body_error}
		var measured: Dictionary = BodySweep.source_description(other)
		var collision := _retained_collisions.get(other_id) as CollisionShape3D
		var capsule := _retained_capsules.get(other_id) as CapsuleShape3D
		if measured.has("error") or measured.get("collision") != collision or not is_instance_valid(collision) or collision.shape != capsule:
			return {"accepted": false, "reason": String(measured.get("error", "Neighbor must retain its actual centered capsule"))}
		var stopped: Vector3 = other.global_position
		if not state.reservation_id.is_empty():
			stopped = state.opening_position
		else:
			var horizontal := Vector3(other.velocity.x, 0, other.velocity.z)
			var speed: float = horizontal.length()
			if speed > 0.0: stopped += horizontal / speed * (speed * speed / 10.0 + speed * 2.0 * delta)
		paths.append({"from": other.global_position, "to": stopped, "radius": capsule.radius})
	return {"accepted": true, "paths": paths}


func _source_path_gap_error(id: String, start: Vector3, finish: Vector3, delta: float) -> String:
	var neighbors: Dictionary = _neighbor_paths(id, delta)
	if not neighbors.get("accepted", false): return String(neighbors.reason)
	var capsule := _retained_capsules[id] as CapsuleShape3D
	for path: Dictionary in neighbors.paths:
		if _planar_segment_distance(start, finish, path["from"], path["to"]) < capsule.radius + float(path.radius) + 0.12:
			return "Native source path/opening needs a clear neighboring capsule gap"
	return ""


func _planar_segment_distance(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> float:
	# Geometry only for authored capsule spacing. Native BodySweep above owns
	# actual scenery/floor measurement; this does not prove threat fairness.
	var p := Vector2(a.x, a.z)
	var q := Vector2(b.x, b.z)
	var r := Vector2(c.x, c.z)
	var s := Vector2(d.x, d.z)
	if Geometry2D.segment_intersects_segment(p, q, r, s) != null: return 0.0
	return minf(p.distance_to(Geometry2D.get_closest_point_to_segment(p, r, s)), minf(q.distance_to(Geometry2D.get_closest_point_to_segment(q, r, s)), minf(r.distance_to(Geometry2D.get_closest_point_to_segment(r, p, q)), s.distance_to(Geometry2D.get_closest_point_to_segment(s, p, q)))))


func _scenery_error() -> String:
	if var_to_bytes(_stalk_specs) != _stalk_specs_bytes:
		return "Retain the same validated whole physical/art stalk table"
	if not is_instance_valid(_scenery_art) or not _scenery_art.is_inside_tree() or _scenery_art.is_queued_for_deletion() or _scenery_art.get_parent() != self or get_node_or_null("FungalArt") != _scenery_art:
		return "Retained authored grotto scenery is unavailable"
	return String(_scenery_art.call("binding_error"))


func _floor_error() -> String:
	if not is_instance_valid(_floor_collision) or not _floor_collision.is_inside_tree() or _floor_collision.is_queued_for_deletion() or get_node_or_null("Floor/CollisionShape3D") != _floor_collision: return "Retained mushroom floor binding is unavailable"
	if _floor_collision.shape != _floor_shape or _floor_shape.size != Layout.FLOOR_SIZE or _floor_collision.global_transform != _floor_transform or _floor_collision.disabled: return "Retained mushroom floor geometry changed"
	return ""


func _containment_error(points: Array) -> String:
	if not is_instance_valid(shared_shell): return "Actual shared camera is required"
	if points.is_empty() or points.size() > 224: return "Complete native corners must be bounded to224"
	return String(shared_shell.call("camera_framing_error", points))


func _framing_ready(points: Array, optional_owner: String = "") -> bool:
	if points.is_empty() or points.size() > 224 or not is_instance_valid(shared_shell):
		if not optional_owner.is_empty(): _clear_forecast_hint(optional_owner)
		return false
	var plan: Dictionary = shared_shell.call("camera_framing_plan", points, hero.global_position + Vector3(0, 0.65, 0))
	if plan.get("accepted") != true and not optional_owner.is_empty(): _clear_forecast_hint(optional_owner)
	last_encounter_error = String(plan.get("reason", "")) if not plan.get("accepted", false) else _containment_error(points)
	return plan.get("accepted", false) and last_encounter_error.is_empty()


func _camera_framing_points() -> Array:
	# exit_level releases the actual shell before the queued world is freed.
	# A stopped component has no remaining authored camera requirements.
	if not _running: return []
	if not _floor_error().is_empty() or not _scenery_error().is_empty(): return [Vector3.INF]
	# Pure selection only: invalid unadmitted hints cannot poison the full union.
	# Storage is cleared by owned callbacks/physics; current native corners stay.
	var points: Array = _forecast_points.duplicate() if _forecast_hint_current() else []
	for forecast: Array in _approach_forecasts.values(): points.append_array(forecast)
	for request: Array in _approach_camera_requests.values(): points.append_array(request)
	for id: String in current_source_ids():
		var actor := sources.get(id) as Act1MushroomSelenite
		if not is_instance_valid(actor) or actor != _retained_sources.get(id) or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.get_parent() != self: return [Vector3.INF]
		var state: Dictionary = _render_sources.get(id, {})
		if state.is_empty() or state.dead or state.dormant: continue
		if not actor.is_visible_in_tree(): return [Vector3.INF]
		# This bounded room has only three active swarmers or one guard. Retain
		# every living source's complete silhouette; a distance filter had let the
		# far third swarmer's head slip beneath the actual HUD in first portraits.
		points.append_array(_actor_points(id, state.opening_position))
		if state.geometry.get("kind") == "lane": points.append_array(_lane_points(state.geometry))
		points.append_array(_cue_points(id, state))
	for frame: Dictionary in _framing.values(): points.append_array(_response_points(frame.landing, frame.attack_position))
	if not points.is_empty() and is_instance_valid(hero):
		var dash: Dictionary = hero.get_committed_dash_state()
		if dash.get("active", false):
			var endpoint: Vector3 = dash.origin + dash.direction * float(dash.distance)
			var actual: Array = shared_shell.call("player_camera_framing_points")
			for point: Vector3 in actual: points.append(point + endpoint - hero.global_position)
	return _unique_points(points)


func _actor_points(id: String, endpoint: Vector3) -> Array:
	var actor := sources.get(id) as Act1MushroomSelenite
	if not is_instance_valid(actor) or actor != _retained_sources.get(id) or actor.get_parent() != self or actor.is_queued_for_deletion() or not actor.is_inside_tree(): return [Vector3.INF]
	var collision := actor.get_node_or_null("BodyCollision") as CollisionShape3D
	if not is_instance_valid(collision) or collision != _retained_collisions.get(id) or collision.get_parent() != actor or not collision.is_inside_tree() or collision.is_queued_for_deletion(): return [Vector3.INF]
	var capsule := collision.shape as CapsuleShape3D
	if not is_instance_valid(capsule) or capsule != _retained_capsules.get(id) or not actor.art_binding_error().is_empty(): return [Vector3.INF]
	var points: Array = _box_points(AABB(Vector3(-capsule.radius, -capsule.height * 0.5, -capsule.radius), Vector3(capsule.radius * 2, capsule.height, capsule.radius * 2)), collision.global_transform)
	var art: Node3D = actor.get_art()
	if not is_instance_valid(art): return [Vector3.INF]
	for node: Node in art.find_children("*", "Sprite3D", true, false):
		var sprite := node as Sprite3D
		if sprite.is_visible_in_tree():
			var quad: Array = shared_shell.call("camera_billboard_points", sprite)
			if quad.is_empty(): return [Vector3.INF]
			points.append_array(quad)
	for node: Node in art.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh != null and mesh.is_visible_in_tree(): points.append_array(_box_points(mesh.get_aabb(), mesh.global_transform))
	var current: Array = points.duplicate()
	for point: Vector3 in current: points.append(point + endpoint - actor.global_position)
	return _unique_points(points)


func _lane_points(shape: Dictionary) -> Array:
	if shape.get("kind") != "lane": return [Vector3.INF]
	var points: Array = []
	for centre: Vector3 in [shape["from"], shape["to"]]: points.append_array(_box_points(AABB(Vector3(-shape.radius, 0, -shape.radius), Vector3(shape.radius * 2, 0.08, shape.radius * 2)), Transform3D(Basis.IDENTITY, centre)))
	return points


func _cue_points(id: String, state: Dictionary) -> Array:
	var actor := sources.get(id) as Act1MushroomSelenite
	var cue: CinderThreatCue = actor.get_cue()
	if not is_instance_valid(cue) or cue != _retained_cues.get(id) or cue.get_parent() != actor or not cue.is_inside_tree() or cue.is_queued_for_deletion(): return [Vector3.INF]
	if not state.reservation_id.is_empty():
		var presented: Dictionary = cue.state()
		# Native actor owns source-marker correspondence before/after its physics
		# presentation update. Observe complete actual meshes here without requiring
		# the previous render cache to anticipate that actor's current motion.
		if not cue.is_visible_in_tree() or presented.phase != state.phase or presented.geometry != state.geometry: return [Vector3.INF]
		var required: Array[String] = ["RequiredSourceMarker"]
		if state.phase != "recovery": required.append("RequiredFootprintOutline")
		if state.phase == "active": required.append("RequiredFootprintFill")
		for node_name: String in required:
			var mesh := cue.get_node_or_null(node_name) as MeshInstance3D
			if not is_instance_valid(mesh) or not mesh.is_inside_tree() or mesh.is_queued_for_deletion() or mesh.get_parent() != cue or mesh.mesh == null or not mesh.is_visible_in_tree(): return [Vector3.INF]
	var points: Array = []
	for node: Node in cue.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh != null and mesh.is_visible_in_tree(): points.append_array(_box_points(mesh.get_aabb(), mesh.global_transform))
	return points


func _response_points(landing: Vector3, attack: Vector3) -> Array:
	if not is_instance_valid(hero) or not is_instance_valid(shared_shell): return [Vector3.INF]
	var actual: Array = shared_shell.call("player_camera_framing_points")
	if actual.is_empty(): return [Vector3.INF]
	var points: Array = []
	for point: Vector3 in actual:
		points.append(point + landing - hero.global_position)
		points.append(point + attack - hero.global_position)
	return _unique_points(points)


func _box_points(bounds: AABB, transform: Transform3D) -> Array:
	var points: Array = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]: points.append(transform * Vector3(x, y, z))
	return points


func _unique_points(points: Array) -> Array:
	var result: Array = []
	for point: Vector3 in points:
		if not result.has(point): result.append(point)
	return result


func _on_hero_died() -> void:
	for id: String in _all_source_ids(): (sources[id] as Act1MushroomSelenite).cancel("actual_player_death")
	_framing.clear()
	_clear_forecast_hint()
	_approach_forecasts.clear()
	_approach_camera_requests.clear()


func _native_route_snapshot_enabled() -> bool:
	return false # Separate full subclass opts in; component stays unsupported.


func snapshot_state() -> Dictionary:
	if _native_route_snapshot_enabled(): return super.snapshot_state()
	last_snapshot_error = "L3 component greybox has no full campaign/spore aggregate yet"
	return {}


func _local_snapshot_error(_state: Dictionary) -> String:
	# Capture, pure candidate validation and restore all deny the unsupported
	# aggregate. A fabricated empty local envelope cannot mutate progress.
	return "L3 component greybox has no full campaign/spore aggregate yet"


func _on_exit_level() -> void:
	_running = false
	_activation_entitlement = ""
	if is_instance_valid(hero):
		if hero.died.is_connected(_on_hero_died): hero.died.disconnect(_on_hero_died)
		if hero.fired.is_connected(_on_hero_fired): hero.fired.disconnect(_on_hero_fired)
	for id: String in _all_source_ids():
		# A genuinely defeated source can be removed after retained tombstone
		# validation. Check its actual handle before attempting a typed cast.
		if not is_instance_valid(sources.get(id)): continue
		var actor := sources.get(id) as Act1MushroomSelenite
		if not is_instance_valid(actor): continue
		if actor.state_changed.is_connected(_source_callbacks.get(id, Callable())): actor.state_changed.disconnect(_source_callbacks[id])
		if actor.is_inside_tree(): actor.cancel("mushroom_greybox_exit")
		actor.remove_from_group("enemies")
		actor.set_physics_process(false)
	if is_instance_valid(scheduler):
		if scheduler.is_inside_tree(): scheduler.end_encounter("mushroom_greybox_exit")
		scheduler.set_physics_process(false)
	_framing.clear()
	_clear_forecast_hint()
	_approach_forecasts.clear()
	_approach_camera_requests.clear()
	set_physics_process(false)
