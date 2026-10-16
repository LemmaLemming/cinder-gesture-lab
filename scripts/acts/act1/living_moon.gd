extends CinderLevel
## The Living Moon: authored return, one eye HP pool, native Blink/Sneeze,
## fixed hatch and a shared-clock cosmetic escape. All values remain provisional.

const Layout = preload("res://scripts/acts/act1/living_moon_layout.gd")
const Body = preload("res://scripts/acts/act1/living_moon_body.gd")
const Nose = preload("res://scripts/acts/act1/living_moon_nose.gd")
const MoonArt = preload("res://scripts/acts/act1/living_moon_art.gd")
const Capsule = preload("res://scripts/acts/act1/living_moon_capsule.gd")
const Rush = preload("res://scripts/acts/act1/rush_selenite.gd")
const Blink = preload("res://scripts/combat/native_sampled_circle.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const BodySweep = preload("res://scripts/combat/body_sweep.gd")
const Motion = preload("res://scripts/combat/lunge_motion.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const MoonCodec = preload("res://scripts/acts/act1/living_moon_codec.gd")
const Cue = preload("res://scripts/cues/interaction_cue.gd")
const WORLD_REVISION: int = 1
const ENCOUNTER_ID: String = "living-moon-encounter"
const COMPLETE_ID: String = "moon-escape-complete"
const EXIT_ID: String = "moon-capsule-hatch"
const LOOKAHEAD: float = 4.5

var scheduler: CinderThreatScheduler
var rusher: Act1RushSelenite
var impact: CinderLaneMechanism
var eye: CharacterBody3D
var nose: Node3D
var blink: CinderNativeSampledCircle
var stage: String = "return"
var impact_demonstrated: bool = false
var sneeze_demonstrated: bool = false
var next_attack: String = "blink"
var pending_phase: int = 0
var escape: Dictionary = {"started": false, "from_s": 0.0, "until_s": 0.0, "finished": false, "contact_position": Codec.vector3(Vector3.ZERO)}
var last_encounter_error: String = ""
var _running: bool = false
var _construction_error: String = ""
var _capture_error: String = ""
var _quiet_error: String = ""
var _quiet_commit: bool = false
var _publishing: bool = false
var _floor: CollisionShape3D
var _floor_shape: BoxShape3D
var _floor_frame: Transform3D
var _moon_art: Node3D
var _capsule: Node3D
var _hatch: Area3D
var _hatch_collision: CollisionShape3D
var _hatch_shape: BoxShape3D
var _hatch_cue: CinderInteractionCue
var _hatch_frame: Transform3D
var _frames: Dictionary = {}
var _forecast: Array = []
var _forecast_hero: Transform3D
var _pending_start: Dictionary = {}
var _capture_camera: Camera3D
var _capture_hud: GameHUD
var _retained: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 200
	_floor = get_node_or_null("Floor/CollisionShape3D") as CollisionShape3D
	_floor_shape = _floor.shape as BoxShape3D if is_instance_valid(_floor) else null
	_floor_frame = _floor.global_transform if is_instance_valid(_floor) else Transform3D.IDENTITY
	if not _floor_error().is_empty(): _construction_error = _floor_error(); return
	scheduler = CinderThreatScheduler.new(); scheduler.name = "MoonThreatScheduler"; add_child(scheduler)
	rusher = Rush.new(); rusher.name = Layout.RUSHER_ID; rusher.position = Layout.RUSHER_POSITION
	if not rusher.configure(Layout.RUSHER_ID): _construction_error = rusher.last_error; rusher.free(); return
	add_child(rusher)
	rusher.presentation_guard = Callable(self, "_rusher_presentation_error")
	impact = CinderLaneMechanism.new(); impact.name = Layout.IMPACT_ID; impact.position = Layout.IMPACT_POSITION
	if not impact.configure(Layout.IMPACT_ID, Geometry.circle(Layout.IMPACT_POSITION, Layout.IMPACT_RADIUS), Layout.IMPACT_POSITION + Vector3.BACK * 1.2):
		_construction_error = impact.last_error; impact.free(); return
	add_child(impact)
	eye = Body.new(); eye.name = Layout.EYE_ID; eye.position = Layout.EYE_POSITION
	if eye.call("configure", Layout.EYE_ID, Layout.BOSS_MAX_HP, Layout.BOSS_PHASE_THRESHOLDS) != true:
		_construction_error = String(eye.get("last_error")); eye.free(); return
	add_child(eye)
	if eye.call("configure_sampled_circle", "living-moon-eye-epoch-1", 1, Body.BLINK_DEFINITION) != true:
		_construction_error = String(eye.get("last_error")); return
	if eye.call("bind_opening_provider", Callable(self, "_eye_opening")) != true:
		_construction_error = String(eye.get("last_error")); return
	blink = Blink.new(); blink.name = "NativeBlink"; eye.add_child(blink)
	nose = Nose.new(); nose.name = Layout.NOSE_ID; nose.position = Layout.EYE_POSITION + Layout.NOSE_LOCAL_POSITION
	var cone: Dictionary = Geometry.cone(nose.position, Vector3.BACK, Layout.SNEEZE_REACH, Layout.SNEEZE_MIN_DOT, Layout.SNEEZE_ORIGIN_RADIUS)
	if nose.call("configure", Layout.NOSE_ID, cone, Layout.EYE_POSITION) != true:
		_construction_error = String(nose.get("last_error")); nose.free(); return
	add_child(nose)
	_moon_art = MoonArt.new(); _moon_art.name = "MoonPresentation"; eye.add_child(_moon_art)
	_capsule = Capsule.new(); _capsule.name = "EscapeCapsule"
	_capsule.position = Layout.HATCH_POSITION - Capsule.HATCH_CONTACT_ANCHOR; add_child(_capsule)
	_build_hatch()
	_retained = {"scheduler": scheduler, "rusher": rusher, "impact": impact, "eye": eye, "nose": nose, "blink": blink, "art": _moon_art, "capsule": _capsule, "hatch": _hatch, "cue": _hatch_cue}


func contract_error() -> String:
	return _construction_error if not _construction_error.is_empty() else super.contract_error()


func _bind_level() -> String:
	if not _construction_error.is_empty(): return _construction_error
	var root: Node3D = _world_root()
	if not rusher.bind(scheduler, hero): return rusher.last_error
	if not impact.bind(scheduler, {"hero": hero}) or not impact.set_presentation_guard(Callable(self, "_impact_presentation")): return impact.last_error
	if eye.call("bind", scheduler, hero, root) != true: return String(eye.get("last_error"))
	if not blink.bind(eye, scheduler, "hero", hero, root, [floor_region()]) or not blink.set_presentation_guard(Callable(self, "_blink_presentation")): return blink.last_error
	if nose.call("bind", scheduler, hero, root, eye) != true or nose.call("set_presentation_guard", Callable(self, "_nose_presentation")) != true: return String(nose.get("last_error"))
	for consumer: Node3D in [rusher, impact, blink, nose]: consumer.connect("state_changed", _on_source_state)
	eye.connect("phase_changed", _on_eye_phase)
	eye.connect("defeated", _on_eye_defeated)
	hero.died.connect(_on_hero_died)
	_running = true
	_sync_art()
	return _runtime_error()


func _on_enter_level() -> void:
	_construction_error = _bind_level()
	if not _construction_error.is_empty(): _running = false; return
	var profile: String = String(shared_shell.call("get_difficulty_preference")) if is_instance_valid(shared_shell) and shared_shell.has_method("get_difficulty_preference") else "standard"
	if not scheduler.begin_encounter(profile, ENCOUNTER_ID, WORLD_REVISION): _construction_error = scheduler.last_error; _running = false
	_refresh_objective()


func _on_enter_restore_candidate(_local: Dictionary, _saved_player: Dictionary) -> String:
	# All recipients have one immutable topology, including fresh cycle-zero Blink.
	# No preview, attack, checkpoint or encounter reset is run during construction.
	return _bind_level()


func restore_candidate_construction_required() -> bool:
	return true


func floor_region() -> Dictionary:
	return {"collision": _floor, "safe_rect": Layout.SAFE_RECT}


func scheduler_bindings() -> Dictionary:
	return {"world_root": _world_root(), "owners": {Layout.RUSHER_ID: rusher, Layout.IMPACT_ID: impact, Layout.EYE_ID: eye, Layout.NOSE_ID: nose}, "floors": {"moon-floor": floor_region()}, "actors": {"hero": hero}}


func response_context(sampled: bool = false) -> Dictionary:
	var directions: Array[Vector3] = []
	for index: int in 16: directions.append(Vector3(cos(float(index) * TAU / 16.0), 0, sin(float(index) * TAU / 16.0)))
	var result: Dictionary = {"encounter_id": ENCOUNTER_ID, "world_revision": WORLD_REVISION, "recognition_s": 0.18, "attack_input_margin_s": 0.08, "escape_directions": directions, "return_directions": directions, "floor_regions": [floor_region()]}
	if sampled: result["world_root"] = _world_root()
	return result


func _physics_process(_delta: float) -> void:
	if not _running or _quiet_commit or not is_instance_valid(hero): return
	_sync_art(); _prune_frames(); _refresh_objective()
	if hero.dead or not _runtime_error().is_empty(): return
	if pending_phase > 0: _settle_phase(); return
	match stage:
		"return": _return_tick()
		"capsule":
			if hero.global_position.z <= Layout.BOSS_THRESHOLD_POSITION.z and _framing_ready(_boss_points()): stage = "blink"; next_attack = "blink"
		"blink", "sneeze", "final": _boss_tick()
		"hatch":
			if _hatch.overlaps_body(hero): _hatch_contact(hero)
		"escape": _escape_tick()


func _return_tick() -> void:
	var circle: Dictionary = impact.state()
	if not impact_demonstrated:
		if circle.status == "running" and circle.phase == "recovery":
			impact_demonstrated = true; impact.cancel("return_impact_demonstrated"); _frames.erase(Layout.IMPACT_ID); _forecast.clear()
		elif circle.status != "running" and hero.get_threat_response_state().stable: _admit_impact()
		return
	if rusher.dead:
		if hero.global_position.z > Layout.CAPSULE_CHECKPOINT_POSITION.z or not _framing_ready(_capsule_preview_points()): return
		stage = "capsule"; _frames.clear(); _forecast.clear()
		_publishing = true; request_checkpoint("capsule-ready", "encounter"); _publishing = false
		return
	if _rusher_state().reservation_id.is_empty() and hero.get_threat_response_state().stable:
		var direction: Vector3 = hero.global_position - rusher.global_position; direction.y = 0
		if direction.length() >= 0.1 and direction.length() <= LOOKAHEAD: _admit_rusher(direction.normalized())


func _admit_impact() -> void:
	var preview: Dictionary = impact.preview_start("hero", response_context())
	if not _prepare_forecast(Layout.IMPACT_ID, preview): return
	var answer: Dictionary = impact.start("hero", response_context(), null, null, preview)
	_finish_admission(Layout.IMPACT_ID, answer)


func _admit_rusher(direction: Vector3) -> void:
	var preview: Dictionary = rusher.preview_lunge(response_context(), direction, _world_root())
	if not _prepare_forecast(Layout.RUSHER_ID, preview): return
	var answer: Dictionary = rusher.start(response_context(), direction, _world_root(), preview)
	_finish_admission(Layout.RUSHER_ID, answer)


func _boss_tick() -> void:
	var sneeze: Dictionary = nose.call("state")
	if sneeze.status == "running" and sneeze.phase == "recovery": sneeze_demonstrated = true
	if eye.get("dead"): return
	if not hero.get_threat_response_state().stable or hero.global_position.distance_to(eye.global_position) > LOOKAHEAD: return
	var eye_state: Dictionary = blink.state()
	var nose_state: Dictionary = nose.call("state")
	if stage == "blink":
		if eye_state.status != "running": _admit_blink()
		return
	if stage == "sneeze":
		if not sneeze_demonstrated:
			if nose_state.status != "running" and eye_state.status != "running": _admit_nose()
			return
		if eye_state.status == "running" or nose_state.status == "running": return
		if next_attack == "blink": _admit_blink()
		else: _admit_nose()
		return
	# Stagger the two already-taught shapes. The common Scheduler re-proves the
	# complete danger union and enforces Assisted's one-source budget.
	if eye_state.status != "running" and nose_state.status != "running":
		if next_attack == "blink": _admit_blink()
		else: _admit_nose()
	elif eye_state.status == "running" and eye_state.phase == "lock" and nose_state.status != "running": _admit_nose()
	elif nose_state.status == "running" and nose_state.phase == "lock" and eye_state.status != "running": _admit_blink()


func _admit_blink() -> void:
	var preview: Dictionary = blink.preview_start(response_context(true))
	if not _prepare_forecast(Layout.EYE_ID, preview): return
	var answer: Dictionary = blink.start(response_context(true), preview)
	_finish_admission(Layout.EYE_ID, answer)
	if answer.get("accepted", false): next_attack = "sneeze"


func _admit_nose() -> void:
	var preview: Dictionary = nose.call("preview_start", response_context())
	if not _prepare_forecast(Layout.NOSE_ID, preview): return
	var answer: Dictionary = nose.call("start", response_context(), null, null, preview)
	_finish_admission(Layout.NOSE_ID, answer)
	if answer.get("accepted", false): next_attack = "blink"


func _prepare_forecast(id: String, preview: Dictionary) -> bool:
	# Each prospective attempt replaces the previous unpublished proposal.
	# Invalid previews must not leave stale camera requirements behind.
	_forecast.clear(); _pending_start.clear()
	if not preview.get("accepted", false): last_encounter_error = String(preview.get("reason", "Prospective native attack refused")); return false
	var candidate: Dictionary = preview.get("candidate", {})
	var proof: Dictionary = preview.get("proof", {})
	if candidate.is_empty() or proof.is_empty(): last_encounter_error = "Actual native candidate/proof required"; return false
	if proof.primary_time_s < candidate.active_until_s or proof.response_complete_s > candidate.recovery_until_s:
		last_encounter_error = "Ordinary primary and its recovery must fit genuine source recovery"; return false
	_forecast = _source_points(id, candidate.opening_position)
	_forecast.append_array(_geometry_points(candidate.geometry)); _forecast.append_array(_response_points(proof.landing, proof.attack_position))
	_forecast_hero = hero.global_transform
	_pending_start = {"source_id": id, "proof": proof.duplicate(true)}
	var framing: Dictionary = _framing_status(_camera_framing_points())
	last_encounter_error = String(framing.error)
	if not framing.plan_accepted:
		_forecast.clear(); _pending_start.clear()
		return false
	if not last_encounter_error.is_empty():
		# A feasible plan may still need normal camera preframing. Keep only
		# those forecast points; current containment still gates admission.
		_pending_start.clear()
		return false
	return true


func _finish_admission(id: String, answer: Dictionary) -> void:
	if answer.get("accepted", false): _frames[id] = {"reservation_id": String(answer.reservation_id), "proof": answer.proof.duplicate(true)}
	else: last_encounter_error = String(answer.get("reason", "Native admission refused"))
	_pending_start.clear(); _forecast.clear()
	if answer.get("accepted", false) and not _framing_ready(_camera_framing_points()):
		_source(id).call("cancel", "complete_response_not_visible"); _frames.erase(id)


func _on_source_state(_state: Dictionary) -> void:
	if _running and not _quiet_commit:
		if _state.get("source_id") == Layout.NOSE_ID and _state.get("status") == "running" and _state.get("phase") == "recovery":
			var record: Dictionary = _record_for(Layout.NOSE_ID, String(_state.get("reservation_id", "")))
			if not record.is_empty() and scheduler.get_clock() >= record.active_until_s: sneeze_demonstrated = true
		_sync_art()


func _on_eye_phase(_source_id: String, phase: int) -> void:
	if _running and not _quiet_commit and not eye.get("dead"): pending_phase = phase


func _settle_phase() -> void:
	var target: int = pending_phase
	blink.cancel("moon_phase_boundary"); nose.call("cancel", "moon_phase_boundary")
	_frames.clear(); _forecast.clear(); _pending_start.clear()
	stage = "sneeze" if target == 2 else "final"; next_attack = "sneeze" if target == 2 else "blink"
	pending_phase = 0; _sync_art()
	_publishing = true; request_checkpoint("moon-phase-2" if target == 2 else "moon-phase-3", "boss_phase"); _publishing = false


func _on_eye_defeated(_source_id: String) -> void:
	if not _running or _quiet_commit: return
	stage = "hatch"; pending_phase = 0
	nose.call("cancel", "source_defeated"); impact.cancel("source_defeated")
	_frames.clear(); _forecast.clear(); _pending_start.clear(); _sync_art()


func _on_hero_died() -> void:
	if not _running: return
	for pair: Array in [[rusher, rusher], [impact, impact], [blink, eye], [nose, nose]]:
		if not scheduler.source_control_state(pair[1]).get("reservations", []).is_empty(): pair[0].call("cancel", "hero_defeated")
	_frames.clear(); _forecast.clear(); _pending_start.clear(); _sync_art()


func _eye_opening(id: String) -> Dictionary:
	var reason: String = _runtime_error()
	if not reason.is_empty() or id != Layout.EYE_ID or not _running or hero.dead or eye.get("dead") or stage not in ["blink", "sneeze", "final"]:
		return {"eligible": false, "reason": reason if not reason.is_empty() else "No live Moon recovery opening"}
	var support: Dictionary = BodySweep.sweep(hero, hero.global_transform, Vector3.ZERO, [floor_region()])
	if support.has("error") or support.get("collided", true): return {"eligible": false, "reason": "Current shared Hero lacks actual native floor/capsule support"}
	var recovered: bool = false
	for pair: Array in [[Layout.EYE_ID, blink], [Layout.NOSE_ID, nose]]:
		var state: Dictionary = pair[1].call("state")
		if state.status == "running" and state.phase == "recovery" and _source_guard(pair[0], state):
			var record: Dictionary = _record_for(pair[0], String(state.reservation_id))
			var cue: CinderThreatCue = pair[1].call("get_cue")
			var now: float = scheduler.get_clock()
			if not record.is_empty() and now >= record.active_until_s and now < record.recovery_until_s and record.opening_position == eye.global_position and is_instance_valid(cue) and cue.is_visible_in_tree() and cue.state().phase == "recovery": recovered = true
	if not recovered: return {"eligible": false, "reason": "Eye opens only in a genuine retained current recovery"}
	var expected: Dictionary = _expected_pose()
	if expected.eye_phase != "recovery" or not _same(_moon_art.call("pose_state"), expected): return {"eligible": false, "reason": "Actual low rim recovery must be visible"}
	return {"eligible": true, "reason": ""}


func _blink_presentation(id: String, state: Dictionary) -> bool:
	return id == Layout.EYE_ID and _source_guard(id, state)


func _nose_presentation(id: String, state: Dictionary) -> bool:
	return id == Layout.NOSE_ID and _source_guard(id, state)


func _impact_presentation(id: String, state: Dictionary) -> bool:
	return id == Layout.IMPACT_ID and _source_guard(id, state)


func _rusher_presentation_error() -> String:
	var state: Dictionary = _rusher_state()
	return "Actual rusher/complete response presentation required" if not _source_guard(Layout.RUSHER_ID, state) else ""


func _source_guard(id: String, state: Dictionary) -> bool:
	if not _running or _quiet_commit or not _runtime_error().is_empty() or hero.dead or get_tree().paused: return false
	if state.status == "running" or not String(state.get("reservation_id", "")).is_empty():
		var record: Dictionary = _record_for(id, String(state.reservation_id))
		var frame: Dictionary = _frames.get(id, {})
		if frame.is_empty() and _pending_start.get("source_id", "") == id: frame = _pending_start
		if record.is_empty() or record.source_id != id or frame.is_empty() or not frame.get("proof") is Dictionary: return false
		if frame.has("reservation_id") and frame.reservation_id != record.id: return false
		if frame.proof.response_complete_s > record.recovery_until_s or frame.proof.primary_time_s < record.active_until_s: return false
	if id in [Layout.EYE_ID, Layout.NOSE_ID] and (eye.get("dead") or not _same(_moon_art.call("pose_state"), _expected_pose())): return false
	return _framing_error(_camera_framing_points(false)).is_empty()


func _expected_pose() -> Dictionary:
	var eye_phase: String = String(blink.state().phase)
	var nose_phase: String = String(nose.call("state").phase)
	if eye.get("dead"): return {"eye_phase": "clear", "nose_phase": "clear", "expression": "flinch"}
	if nose_phase == "recovery": eye_phase = "recovery"
	return {"eye_phase": eye_phase, "nose_phase": nose_phase, "expression": "indignant" if stage in ["blink", "sneeze", "final"] else "neutral"}


func _sync_art() -> void:
	var camera: Camera3D = _actual_camera()
	if camera == null or not is_instance_valid(_moon_art): return
	var pose: Dictionary = _expected_pose()
	if _moon_art.call("set_pose", pose.eye_phase, pose.nose_phase, pose.expression, camera) != true: _construction_error = "Actual Moon presentation refused its camera"; return
	if _capsule.call("set_presentation_camera", camera) != true: _construction_error = "Actual capsule presentation refused its camera"; return
	_capsule.call("set_hatch_open", stage in ["hatch", "escape", "departed"])
	var alpha: float = 0.0
	if escape.started: alpha = clampf((scheduler.get_clock() - escape.from_s) / Layout.ESCAPE_DURATION_S, 0.0, 1.0)
	if _capsule.call("set_escape_progress", alpha) != true: _construction_error = "Actual cosmetic escape progress refused"; return
	var state: String = "clear"
	if stage == "hatch" and hero.global_position.distance_to(Layout.HATCH_POSITION) <= LOOKAHEAD: state = "available"
	elif stage == "escape": state = "spent" if escape.finished else "active"
	elif stage == "departed": state = "spent"
	if state == "clear": _hatch_cue.clear()
	else: _hatch_cue.present(state, "contact")


func _build_hatch() -> void:
	_hatch = Area3D.new(); _hatch.name = "CapsuleHatch"; _hatch.position = Layout.HATCH_POSITION
	_hatch.collision_layer = 0; _hatch.collision_mask = 4
	_hatch_collision = CollisionShape3D.new(); _hatch_collision.name = "CollisionShape3D"; _hatch_collision.position = Layout.HATCH_CONTACT_OFFSET
	_hatch_shape = BoxShape3D.new(); _hatch_shape.size = Layout.HATCH_CONTACT_SIZE; _hatch_collision.shape = _hatch_shape
	_hatch.add_child(_hatch_collision); add_child(_hatch); _hatch_frame = _hatch.global_transform
	_hatch.body_entered.connect(_hatch_contact)
	_hatch_cue = Cue.new(); _hatch_cue.name = "HatchContactCue"; _hatch_cue.position = Layout.HATCH_POSITION; add_child(_hatch_cue)


func _hatch_contains(feet: Vector3) -> bool:
	var collision := hero.get_node_or_null("BodyCollision") as CollisionShape3D
	if collision == null or not collision.shape is CapsuleShape3D or not feet.is_finite(): return false
	var capsule := collision.shape as CapsuleShape3D
	var box := AABB(_hatch_collision.global_position - Layout.HATCH_CONTACT_SIZE * 0.5, Layout.HATCH_CONTACT_SIZE)
	var centre: Vector3 = feet + collision.position
	var half_line: float = capsule.height * 0.5 - capsule.radius
	var nearest := Vector3(clampf(centre.x, box.position.x, box.end.x), clampf(centre.y, box.position.y - half_line, box.end.y + half_line), clampf(centre.z, box.position.z, box.end.z))
	return centre.distance_squared_to(nearest) <= capsule.radius * capsule.radius


func _hatch_contact(body: Node3D) -> void:
	if body != hero or not _running or stage != "hatch" or hero.dead or not _hatch.overlaps_body(hero) or not _runtime_error().is_empty() or not _framing_ready(_camera_framing_points()): return
	if _hatch_cue.state().state != "available": return
	var now: float = scheduler.get_clock()
	escape = {"started": true, "from_s": now, "until_s": now + Layout.ESCAPE_DURATION_S, "finished": false, "contact_position": Codec.vector3(hero.global_position)}
	stage = "escape"; _sync_art()


func _escape_tick() -> void:
	if not escape.started: return
	if scheduler.get_clock() >= escape.until_s: escape.finished = true
	_sync_art()
	if not escape.finished or not _hatch_contains(Codec.read_vector3(escape.contact_position)): return
	_publishing = true
	if not is_completed(): request_completion(COMPLETE_ID)
	if _running and is_instance_valid(hero) and not hero.dead and not get_tree().paused: request_contact_exit(EXIT_ID, hero)
	_publishing = false


func request_checkpoint(id: String, kind: String = "encounter") -> bool:
	if not _publishing or not _running or pending_phase != 0 or hero.dead: return false
	if id == "capsule-ready" and stage == "capsule" and impact_demonstrated and rusher.dead and kind == "encounter": return super.request_checkpoint(id, kind)
	if id == "moon-phase-2" and stage == "sneeze" and eye.get("phase") == 2 and kind == "boss_phase": return super.request_checkpoint(id, kind)
	if id == "moon-phase-3" and stage == "final" and eye.get("phase") == 3 and kind == "boss_phase": return super.request_checkpoint(id, kind)
	return false


func request_completion(id: String = "complete") -> bool:
	if not _publishing or not _running or id != COMPLETE_ID or stage != "escape" or not eye.get("dead") or not escape.started or not escape.finished or not _hatch_contains(Codec.read_vector3(escape.contact_position)): return false
	return super.request_completion(id)


func request_contact_exit(id: String, body: Node3D) -> bool:
	if not _publishing or not _running or body != hero or id != EXIT_ID or not escape.started or not escape.finished or not _hatch_contains(Codec.read_vector3(escape.contact_position)): return false
	stage = "departed"
	return super.request_contact_exit(id, body)


func _refresh_objective() -> void:
	if stage == "return" and impact_demonstrated and is_instance_valid(rusher) and rusher.dead:
		objective_text = "RETURN TO THE BLOCKED CAPSULE"; return
	objective_text = {"return": "RETURN: EVADE THE IMPACT AND ONE SELENITE", "capsule": "THE HATCH IS SHUT: APPROACH THE LOW EYE", "blink": "BLINK: EVADE THE LOCKED CIRCLE; RETURN TO THE EYE", "sneeze": "SNEEZE: LEAVE THE CONE; SLASH THE LOW RIM", "final": "TWO KNOWN SHAPES: CHOOSE A SAFE RETURN LANDING", "hatch": "THE MOON FLINCHES: ENTER THE OPEN HATCH", "escape": "THE CAPSULE BREAKS FREE", "departed": "LEAVING THE MOON"}.get(stage, "THE LIVING MOON")


func _source(id: String) -> Node3D:
	return {Layout.IMPACT_ID: impact, Layout.RUSHER_ID: rusher, Layout.EYE_ID: blink, Layout.NOSE_ID: nose}.get(id) as Node3D


func _world_root() -> Node3D:
	if not is_instance_valid(hero): return null
	var ancestor: Node = get_parent()
	while is_instance_valid(ancestor):
		if ancestor is Node3D and ancestor.is_ancestor_of(hero) and ancestor.is_ancestor_of(self): return ancestor as Node3D
		ancestor = ancestor.get_parent()
	return null


func _actual_camera() -> Camera3D:
	return get_viewport().get_camera_3d() if is_inside_tree() else null


func _floor_error() -> String:
	if not is_instance_valid(_floor) or _floor != get_node_or_null("Floor/CollisionShape3D") or not is_instance_valid(_floor_shape) or _floor.shape != _floor_shape or _floor_shape.size != Layout.FLOOR_SIZE or _floor.global_transform != _floor_frame or _floor.disabled: return "Retain the authored native Moon floor"
	var floor_body := _floor.get_parent() as StaticBody3D
	if floor_body == null or floor_body.position != Layout.FLOOR_CENTRE or floor_body.collision_layer != 1: return "Actual fixed authored floor body required"
	return ""


func _runtime_error() -> String:
	if not _construction_error.is_empty(): return _construction_error
	var error: String = _floor_error()
	if not error.is_empty(): return error
	for key: String in _retained:
		var node: Node = _retained[key]
		if not is_instance_valid(node) or node.is_queued_for_deletion() or not node.is_inside_tree(): return "Lost retained actual Moon node: " + key
	if scheduler != _retained.get("scheduler") or eye != _retained.get("eye") or nose != _retained.get("nose") or blink != _retained.get("blink") or blink.get_parent() != eye or _moon_art.get_parent() != eye: return "Actual native Moon source/consumer bindings changed"
	if eye.global_position != Layout.EYE_POSITION or (eye as CharacterBody3D).velocity != Vector3.ZERO or nose.global_position != Layout.EYE_POSITION + Layout.NOSE_LOCAL_POSITION or impact.global_position != Layout.IMPACT_POSITION: return "Retain fixed source/opening pivots"
	if _hatch.global_transform != _hatch_frame or _hatch_collision.get_parent() != _hatch or _hatch_collision.shape != _hatch_shape or _hatch_shape.size != Layout.HATCH_CONTACT_SIZE or _hatch_collision.position != Layout.HATCH_CONTACT_OFFSET or _hatch_collision.disabled or _hatch.collision_layer != 0 or _hatch.collision_mask != 4: return "Retain actual native hatch Area and contact box"
	if not _quiet_error.is_empty(): return _quiet_error
	return ""


func _hero_points() -> Array:
	return shared_shell.call("player_camera_framing_points_for", hero, _actual_camera()) if is_instance_valid(shared_shell) else []


func _source_points(id: String, opening: Vector3) -> Array:
	var points: Array = []
	if id in [Layout.EYE_ID, Layout.NOSE_ID]: return _boss_points()
	var actual: Node3D = rusher if id == Layout.RUSHER_ID else impact
	if id == Layout.RUSHER_ID:
		var collision := rusher.get_node_or_null("BodyCollision") as CollisionShape3D
		if collision == null or not collision.shape is CapsuleShape3D or not rusher.art_binding_error().is_empty(): return [Vector3.INF]
		points.append_array(_box_points(collision.shape.get_debug_mesh().get_aabb(), collision.global_transform))
		for node: Node in rusher.get_art().find_children("*", "Sprite3D", true, false):
			if node.is_visible_in_tree(): points.append_array(shared_shell.call("camera_billboard_points", node))
		var future: Array = points.duplicate()
		for point: Vector3 in future: points.append(point + opening - actual.global_position)
	else: points.append_array(_geometry_points(Geometry.circle(impact.global_position, Layout.IMPACT_RADIUS)))
	return _unique(points)


func _capsule_preview_points() -> Array:
	var points: Array = _boss_points()
	points.append_array(_bounds_points(_capsule.call("world_corners")))
	points.append_array(_box_points(AABB(-Layout.HATCH_CONTACT_SIZE * 0.5, Layout.HATCH_CONTACT_SIZE), _hatch_collision.global_transform))
	return _unique(points)


func _boss_points() -> Array:
	if not is_instance_valid(_moon_art) or _actual_camera() == null: return [Vector3.INF]
	return _moon_art.call("required_part_points", _actual_camera())


func _geometry_points(shape: Dictionary) -> Array:
	var points: Array = []
	if not Geometry.error(shape).is_empty(): return [Vector3.INF]
	if shape.kind == "lane":
		for origin: Vector3 in [shape.from, shape.to]: points.append_array(_box_points(AABB(Vector3(-shape.radius, 0, -shape.radius), Vector3(shape.radius * 2, 0.08, shape.radius * 2)), Transform3D(Basis.IDENTITY, origin)))
	elif shape.kind == "circle":
		points.append_array(_box_points(AABB(Vector3(-shape.radius, 0, -shape.radius), Vector3(shape.radius * 2, 0.08, shape.radius * 2)), Transform3D(Basis.IDENTITY, shape.origin)))
	elif shape.kind == "cone":
		# Include both exact edge rays and every cardinal extremum admitted by
		# the cone, plus the full origin disc. This conservatively encloses the
		# complete fixed footprint without inventing a rear-facing danger sector.
		var radius: float = float(shape.origin_radius)
		var bounds := AABB(shape.origin - Vector3(radius, 0, radius), Vector3(radius * 2, 0.08, radius * 2))
		var yaw: float = atan2(shape.direction.x, shape.direction.z)
		var half: float = acos(shape.min_dot)
		var directions: Array[Vector3] = [shape.direction]
		for delta: float in [-half, half]: directions.append(Vector3(sin(yaw + delta), 0, cos(yaw + delta)))
		for direction: Vector3 in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
			if direction.dot(shape.direction) >= shape.min_dot: directions.append(direction)
		for direction: Vector3 in directions:
			var edge: Vector3 = shape.origin + direction * shape.reach
			bounds = bounds.expand(edge); bounds = bounds.expand(edge + Vector3.UP * 0.08)
		points.append_array(_box_points(bounds, Transform3D.IDENTITY))
	else: return [Vector3.INF]
	return points


func _mesh_bounds(node: Node3D) -> Array:
	var all: Array = []
	for child: Node in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		if mesh.is_visible_in_tree() and mesh.mesh != null: all.append_array(_box_points(mesh.get_aabb(), mesh.global_transform))
	return _bounds_points(all)


func _bounds_points(points: Array) -> Array:
	if points.is_empty(): return []
	var bounds := AABB(points[0], Vector3.ZERO)
	for point: Vector3 in points:
		if not point.is_finite(): return [Vector3.INF]
		bounds = bounds.expand(point)
	return _box_points(bounds, Transform3D.IDENTITY)


func _response_points(landing: Vector3, attack: Vector3) -> Array:
	var result: Array = []
	for point: Vector3 in _hero_points(): result.append(point + landing - hero.global_position); result.append(point + attack - hero.global_position)
	return result


func _camera_framing_points(include_forecast: bool = true) -> Array:
	if not _running or not is_instance_valid(hero): return []
	var points: Array = _hero_points()
	if stage == "return" and not rusher.dead: points.append_array(_source_points(Layout.RUSHER_ID, _rusher_state().opening_position))
	if stage == "capsule" or (stage == "return" and rusher.dead and impact_demonstrated and hero.global_position.z <= Layout.CAPSULE_CHECKPOINT_POSITION.z + 3.0): points.append_array(_capsule_preview_points())
	if stage in ["blink", "sneeze", "final"] or (stage == "capsule" and hero.global_position.distance_to(eye.global_position) <= LOOKAHEAD): points.append_array(_boss_points())
	for record: Dictionary in _live_records():
		points.append_array(_source_points(record.source_id, record.opening_position))
		points.append_array(_geometry_points(record.geometry))
		var source: Node3D = _source(record.source_id)
		if is_instance_valid(source): points.append_array(_mesh_bounds(source.call("get_cue")))
		var frame: Dictionary = _frames.get(record.source_id, {})
		if frame.is_empty() and _pending_start.get("source_id", "") == record.source_id: frame = _pending_start
		if not frame.is_empty(): points.append_array(_response_points(frame.proof.landing, frame.proof.attack_position))
	if include_forecast and not _forecast.is_empty() and hero.global_transform == _forecast_hero: points.append_array(_forecast)
	if stage in ["hatch", "escape", "departed"] and (hero.global_position.distance_to(Layout.HATCH_POSITION) <= LOOKAHEAD or _hatch_cue.state().visible):
		points.append_array(_bounds_points(_capsule.call("world_corners")))
		points.append_array(_box_points(AABB(-Layout.HATCH_CONTACT_SIZE * 0.5, Layout.HATCH_CONTACT_SIZE), _hatch_collision.global_transform))
		points.append_array(_mesh_bounds(_hatch_cue))
	return _unique(points)


func _framing_status(points: Array) -> Dictionary:
	# One pure plan/current-view observation shared by preflight and guards.
	# Planner rejection differs from a feasible plan awaiting actual framing.
	if points.is_empty() or points.has(Vector3.INF) or points.size() > 224 or not is_instance_valid(shared_shell):
		return {"plan_accepted": false, "error": "Complete actual bounded framing points required"}
	var plan: Dictionary = shared_shell.call("camera_framing_plan", points, hero.global_position + Vector3.UP * 0.65)
	if not plan.get("accepted", false):
		return {"plan_accepted": false, "error": String(plan.get("reason", "Native framing plan refused"))}
	return {"plan_accepted": true, "error": String(shared_shell.call("camera_framing_error", points))}


func _framing_error(points: Array) -> String:
	return String(_framing_status(points).error)


func _framing_ready(points: Array) -> bool:
	last_encounter_error = _framing_error(points)
	return last_encounter_error.is_empty()


func _live_records() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for pair: Array in [[Layout.RUSHER_ID, rusher], [Layout.IMPACT_ID, impact], [Layout.EYE_ID, eye], [Layout.NOSE_ID, nose]]:
		for record: Dictionary in scheduler.source_control_state(pair[1]).get("reservations", []):
			var copy: Dictionary = record.duplicate(true); copy["source_id"] = pair[0]; result.append(copy)
	return result


func _record_for(id: String, lease: String) -> Dictionary:
	for record: Dictionary in _live_records():
		if record.source_id == id and record.id == lease: return record
	return {}


func _rusher_state() -> Dictionary:
	var control: Dictionary = scheduler.source_control_state(rusher)
	var records: Array = control.get("reservations", [])
	var record: Dictionary = {} if records.is_empty() else records[0]
	return {"status": "defeated" if rusher.dead else ("idle" if record.is_empty() else "running"), "phase": record.get("state", "clear"), "reservation_id": record.get("id", ""), "opening_position": record.get("opening_position", rusher.global_position)}


func _prune_frames() -> void:
	var ids: Array = []
	for record: Dictionary in _live_records(): ids.append(record.source_id)
	for id: String in _frames.keys():
		if not ids.has(id): _frames.erase(id)


func snapshot_state_for_presentation(camera: Camera3D, hud: GameHUD) -> Dictionary:
	if _capture_camera != null or _capture_hud != null: return {}
	_capture_camera = camera; _capture_hud = hud
	var result: Dictionary = snapshot_state()
	_capture_camera = null; _capture_hud = null
	return result


func _capture_local_state() -> Dictionary:
	_capture_error = _runtime_error()
	if not _capture_error.is_empty(): return {}
	var camera: Camera3D = _capture_camera if is_instance_valid(_capture_camera) else _actual_camera()
	var points: Array = _camera_framing_points()
	_capture_error = String(shared_shell.call("camera_framing_error_for_context", points, hero, camera, _capture_hud)) if is_instance_valid(_capture_hud) else String(shared_shell.call("camera_framing_error", points))
	if not _capture_error.is_empty(): return {}
	var player: Dictionary = hero.snapshot_state()
	var bindings: Dictionary = scheduler_bindings()
	var paired: Dictionary = scheduler.snapshot_state(bindings)
	if paired.is_empty(): _capture_error = scheduler.last_snapshot_error; return {}
	var eye_packet: Dictionary = eye.call("snapshot_state", paired, player)
	var rush_packet: Dictionary = rusher.snapshot_state(paired)
	var impact_packet: Dictionary = impact.snapshot_state(bindings)
	var nose_packet: Dictionary = nose.call("snapshot_state", bindings)
	var blink_packet: Dictionary = blink.snapshot_state(bindings)
	for packet: Dictionary in [eye_packet, rush_packet, impact_packet, nose_packet, blink_packet]:
		if packet.is_empty(): _capture_error = "Whole Moon capture cannot omit a native component"; return {}
	var frames: Dictionary = {}
	for record: Dictionary in paired.reservations:
		if not _frames.has(record.source_id) or _frames[record.source_id].reservation_id != record.id: _capture_error = "Live native lease lost original response witness"; return {}
		frames[record.source_id] = _encode(_frames[record.source_id])
	return {"api_revision": MoonCodec.API_REVISION, "schema_version": MoonCodec.SCHEMA_VERSION, "world_revision": WORLD_REVISION, "stage": stage, "impact_demonstrated": impact_demonstrated, "sneeze_demonstrated": sneeze_demonstrated, "next_attack": next_attack, "pending_phase": pending_phase, "escape": escape.duplicate(true), "actors": {Layout.RUSHER_ID: rush_packet}, "eye": eye_packet, "scheduler": paired, "impact": impact_packet, "nose": nose_packet, "blink": blink_packet, "framing": frames}


func _local_snapshot_error(state: Dictionary) -> String:
	if state.is_empty(): return _capture_error if not _capture_error.is_empty() else "Whole Moon local state is empty"
	return _local_snapshot_error_with_player(state, hero.snapshot_state())


func _local_snapshot_error_with_player(state: Dictionary, saved_player: Dictionary) -> String:
	var error: String = _runtime_error()
	if error.is_empty(): error = MoonCodec.metadata_error(state)
	if error.is_empty(): error = hero.snapshot_error(saved_player)
	if error.is_empty(): error = String(eye.call("snapshot_error", state.eye, state.scheduler, saved_player))
	if error.is_empty(): error = rusher.actor_snapshot_error(state.actors[Layout.RUSHER_ID], state.scheduler, saved_player)
	if not error.is_empty(): return error
	var bindings: Dictionary = _staged_bindings(state, saved_player)
	error = scheduler.snapshot_error(state.scheduler, bindings)
	if error.is_empty(): error = impact.snapshot_error(state.impact, bindings, state.scheduler)
	if error.is_empty(): error = String(nose.call("snapshot_error", state.nose, bindings, state.scheduler))
	if error.is_empty(): error = blink.snapshot_error(state.blink, bindings, state.scheduler)
	if error.is_empty(): error = _saved_response_error(state, saved_player)
	return error


func _saved_response_error(state: Dictionary, saved_player: Dictionary) -> String:
	if not _same(hero.equipment.snapshot(), saved_player.equipment): return "Actual candidate equipment must match saved complete Player"
	var stats: Dictionary = hero.equipment.resolved_stats()
	var threats: Array[Dictionary] = []
	for record: Dictionary in state.scheduler.reservations:
		var shape: Dictionary = _decode(record.geometry)
		var error: String = Geometry.error(shape)
		if not error.is_empty(): return error
		threats.append({"record": record, "shape": shape})
	for item: Dictionary in threats:
		var record: Dictionary = item.record
		var proof: Dictionary = state.framing[record.source_id].proof
		var path: Array[Dictionary] = []
		for segment: Dictionary in proof.path: path.append(_decode(segment))
		if path[0].end_s < record.start_s + 0.18: return "Saved response removes the original recognition margin"
		if path.size() == 6 and path[3].start_s < maxf(maxf(path[1].end_s, record.active_until_s + CinderThreatScheduler.TIME_MARGIN), path[1].start_s + float(stats.dash_cooldown)): return "Saved positioning dash skips the actual dash cooldown/recovery boundary"
		var input_ready: float = path[3].end_s if path.size() == 6 else maxf(path[1].end_s, record.active_until_s + CinderThreatScheduler.TIME_MARGIN)
		if proof.primary_time_s < input_ready + 0.08: return "Saved ordinary primary removes the original input margin"
		for segment: Dictionary in path:
			var move: Vector3 = segment.to - segment.from
			if segment.kind in ["escape_dash", "positioning_dash"]:
				if absf(move.y) > BodySweep.EPSILON or absf(move.length() - float(stats.dash_distance)) > BodySweep.position_rounding_bound(segment.from, segment.to) or segment.end_s != segment.start_s + float(stats.dash_duration): return "Retain actual full native response dash distance/duration"
			elif move != Vector3.ZERO: return "Stationary response cannot hide travel"
			var sweep: Dictionary = BodySweep.sweep(hero, Transform3D(Basis.IDENTITY, segment.from), move, scheduler_bindings().floors.values())
			if sweep.has("error") or sweep.get("collided", true) or not sweep.get("end") is Vector3 or sweep.end.distance_to(segment.to) > BodySweep.position_rounding_bound(segment.from, segment.to): return "Saved response lacks actual static floor/full capsule support"
		for threat: Dictionary in threats:
			if Geometry.timed_path_hits(threat.shape, path, threat.record.active_from_s, threat.record.active_until_s, CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN): return "Saved response crosses the committed danger union"
		var opening: Vector3 = Codec.read_vector3(record.opening_position)
		var attack: Vector3 = Codec.read_vector3(proof.attack_position)
		var reserve: float = Motion.ENDPOINT_TOLERANCE if record.get("adapter", {}).get("kind") == "lunge" and not record.adapter.get("finished", false) else 0.0
		if Vector2(opening.x - attack.x, opening.z - attack.z).length() > float(stats.primary_range) - reserve - CinderThreatScheduler.SKIN or absf(opening.y - attack.y) > 1.4: return "Saved ordinary primary cannot reach its actual native opening"
		var ray := PhysicsRayQueryParameters3D.create(attack + Vector3.UP * 0.7, opening + Vector3.UP * 0.7, 1)
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return "Static Moon scenery blocks the original primary"
		if proof.response_complete_s < proof.primary_time_s + float(stats.primary_cooldown): return "Saved response truncates ordinary primary recovery"
	return ""


func _staged_bindings(state: Dictionary, player: Dictionary) -> Dictionary:
	var result: Dictionary = scheduler_bindings()
	var rush_maps: Dictionary = rusher.staged_actor_bindings(state.actors[Layout.RUSHER_ID])
	var eye_maps: Dictionary = eye.call("staged_sampled_bindings", state.eye)
	for key: String in ["owner_positions", "owner_velocities", "owner_collision_states", "sampled_owner_bindings"]:
		result[key] = {}
		for maps: Dictionary in [rush_maps, eye_maps]:
			for id: String in maps.get(key, {}): result[key][id] = maps[key][id]
	result.owner_positions[Layout.NOSE_ID] = Layout.EYE_POSITION + Layout.NOSE_LOCAL_POSITION
	result.owner_positions[Layout.IMPACT_ID] = Layout.IMPACT_POSITION
	result["hero_positions"] = {"hero": Codec.read_vector3(player.motion.position)}
	result["hero_action_clocks"] = {"hero": player.world_actions.clock_s}
	return result


func snapshot_error_with_player(saved: Dictionary, player: Dictionary) -> String:
	var error: String = super.snapshot_error_with_player(saved, player)
	return _progress_error(saved, player) if error.is_empty() else error


func snapshot_error(saved: Dictionary) -> String:
	var error: String = super.snapshot_error(saved)
	return _progress_error(saved, hero.snapshot_state()) if error.is_empty() else error


func _progress_error(saved: Dictionary, _player: Dictionary) -> String:
	var local: Dictionary = saved.local; var progress: Dictionary = saved.progress
	var history: Dictionary = {}
	if local.stage != "return": history["capsule-ready"] = "encounter"
	if local.stage in ["sneeze", "final", "hatch", "escape", "departed"]: history["moon-phase-2"] = "boss_phase"
	if local.stage in ["final", "hatch", "escape", "departed"]: history["moon-phase-3"] = "boss_phase"
	if not _same(progress.checkpoint_ids, history): return "Moon checkpoints must retain the genuine ordered boundaries"
	var latest: String = "" if history.is_empty() else String(history.keys().back())
	if progress.checkpoint_id != latest or progress.checkpoint_kind != history.get(latest, ""): return "Latest Moon checkpoint/history differs"
	if local.escape.started and not _hatch_contains(Codec.read_vector3(local.escape.contact_position)): return "Escape requires the original genuine hatch contact position"
	if progress.completed:
		if local.stage not in ["escape", "departed"] or not local.escape.finished or not local.eye.dead or progress.completion_id != COMPLETE_ID: return "Moon completion needs actual finished contact escape"
	elif not String(progress.completion_id).is_empty() or local.stage == "departed": return "Uncompleted Moon cannot contain terminal progress"
	if not String(progress.contact_exit_id).is_empty() and (not progress.completed or progress.contact_exit_id != EXIT_ID or local.stage != "departed"): return "Exact completed capsule contact required"
	return ""


func restore_state(saved: Dictionary) -> bool:
	if not _quiet_error.is_empty(): last_snapshot_error = _quiet_error; return false
	if blink.state().status != "idle" or blink.state().cycle != 0:
		last_snapshot_error = "Whole Moon commit requires a fresh cycle-zero native Blink recipient"; return false
	last_snapshot_error = snapshot_error(saved)
	if not last_snapshot_error.is_empty(): return false
	var accepted: bool = super.restore_state(saved)
	if not _quiet_error.is_empty(): last_snapshot_error = _quiet_error; return false
	return accepted


func _restore_local_state(local: Dictionary) -> void:
	_quiet_commit = true
	var player: Dictionary = hero.snapshot_state()
	if eye.call("restore_physical_state", local.eye, local.scheduler, player) != true: _fail_quiet("Eye physical staging refused"); return
	if not rusher.restore_actor_state(local.actors[Layout.RUSHER_ID]): _fail_quiet(rusher.last_snapshot_error); return
	if not scheduler.restore_state(local.scheduler, scheduler_bindings()): _fail_quiet(scheduler.last_snapshot_error); return
	if eye.call("validate_restored_state", local.eye, local.scheduler, player) != "": _fail_quiet("Eye final paired native validation refused"); return
	if not rusher.restore_exchange_state(local.actors[Layout.RUSHER_ID]): _fail_quiet(rusher.last_snapshot_error); return
	if not impact.restore_state(local.impact, scheduler_bindings()): _fail_quiet(impact.last_snapshot_error); return
	if nose.call("restore_state", local.nose, scheduler_bindings()) != true: _fail_quiet(String(nose.get("last_snapshot_error"))); return
	if not blink.restore_state(local.blink, scheduler_bindings()): _fail_quiet(blink.last_snapshot_error); return
	stage = local.stage; impact_demonstrated = local.impact_demonstrated; sneeze_demonstrated = local.sneeze_demonstrated
	next_attack = local.next_attack; pending_phase = local.pending_phase; escape = local.escape.duplicate(true)
	_frames = _decode(local.framing); _forecast.clear(); _pending_start.clear()
	var blocked: bool = _hatch_cue.is_blocking_signals(); _hatch_cue.set_block_signals(true)
	_sync_art(); _hatch_cue.set_block_signals(blocked)
	_quiet_commit = false; _refresh_objective()


func _fail_quiet(reason: String) -> void:
	_quiet_error = reason if not reason.is_empty() else "Incomplete native Moon quiet commit"
	_quiet_commit = false; _running = false; set_physics_process(false)
	for node: Node in [rusher, scheduler, impact, nose, blink]: node.set_physics_process(false)


func _restore_candidate_presentation_error(camera: Camera3D, hud: GameHUD) -> String:
	var error: String = _runtime_error()
	return String(shared_shell.call("camera_framing_error_for_context", _camera_framing_points(), hero, camera, hud)) if error.is_empty() else error


func _on_exit_level() -> void:
	_running = false; _forecast.clear(); _frames.clear(); _pending_start.clear()
	if is_instance_valid(hero) and hero.died.is_connected(_on_hero_died): hero.died.disconnect(_on_hero_died)
	for source: Node3D in [rusher, impact, blink, nose]:
		if not is_instance_valid(source): continue
		if source.is_connected("state_changed", _on_source_state): source.disconnect("state_changed", _on_source_state)
		if source.is_inside_tree(): source.call("cancel", "moon_level_exit")
		source.set_physics_process(false)
	if is_instance_valid(eye):
		if eye.is_connected("phase_changed", _on_eye_phase): eye.disconnect("phase_changed", _on_eye_phase)
		if eye.is_connected("defeated", _on_eye_defeated): eye.disconnect("defeated", _on_eye_defeated)
		eye.remove_from_group("enemies")
	if is_instance_valid(rusher): rusher.remove_from_group("enemies")
	if is_instance_valid(scheduler): scheduler.set_physics_process(false)
	if is_instance_valid(_hatch_cue): _hatch_cue.clear()


static func _box_points(bounds: AABB, frame: Transform3D) -> Array:
	var result: Array = []
	for x: float in [bounds.position.x, bounds.end.x]:
		for y: float in [bounds.position.y, bounds.end.y]:
			for z: float in [bounds.position.z, bounds.end.z]: result.append(frame * Vector3(x, y, z))
	return result


static func _unique(points: Array) -> Array:
	var result: Array = []
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite(): return [Vector3.INF]
		if not result.has(point): result.append(point)
	return result


static func _encode(value: Variant) -> Variant:
	if value is Vector3: return Codec.vector3(value)
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_encode(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _encode(value[key])
		return result
	return value


static func _decode(value: Variant) -> Variant:
	# Only named coordinate fields decode; numeric histories/deadline arrays
	# keep their exact literal types and cannot become inferred positions.
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_decode(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key: String in value:
			result[key] = Codec.read_vector3(value[key]) if key in ["from", "to", "endpoint", "landing", "attack_position", "origin", "direction", "source_position", "opening_position"] and Codec.is_vector3(value[key]) else _decode(value[key])
		return result
	return value


static func _same(left: Variant, right: Variant) -> bool:
	var wire: String = Exact.stringify(left)
	return not wire.is_empty() and wire == Exact.stringify(right)
