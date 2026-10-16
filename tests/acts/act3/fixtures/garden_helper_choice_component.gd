extends "res://tests/acts/act3/fixtures/garden_mixed_component.gd"
## TEST ONLY retained geometry/helper-choice adapter. No canonical route authority.
## The exact existing Core and autonomous C51 remain native production actors.
## Own declaration/IDs/profile/codec; one canonical cardinal-scan pump at130.

const ChoiceCodec = preload("res://tests/acts/act3/fixtures/garden_helper_choice_component_codec.gd")
const CHOICE_ENCOUNTER: String = "TEST/A3-L4/helper-choice"
const CHOICE_ECHO_ID: String = "test-helper-choice-idle-echo"
const CHOICE_ECHO_EPOCH: String = "TEST/A3-L4/helper-choice-idle-own-sequence"
const CHOICE_HELPER_ID: String = "test-helper-choice-latcher"
const CHOICE_POLICY: String = "canonical-next-kind-cardinal-scan-1"
var _choice_profile: String = ""
var _choice_pending_view: Dictionary = {}
var _choice_attempt_log: Array[Dictionary] = []
var _choice_admission_log: Array[Dictionary] = []
var _choice_refusal_log: Array[Dictionary] = []
var _choice_helper_log: Array[Dictionary] = []
var _choice_helper_seen: Dictionary = {}
var _choice_helper_last_refusal: String = ""

func _ready() -> void:
	_pair = ChoiceCodec.new()
	super._ready()

func _on_enter_level() -> void:
	# A plain Main has no preference API: this scene explicitly declares its
	# genuine initial Challenge factory. Actual Shell still supplies its real
	# preference; fresh non-Challenge Shell entry is rejected, never rewritten.
	var profile: String = String(shared_shell.call("get_difficulty_preference")) if shared_shell.has_method("get_difficulty_preference") else "challenge"
	configuration_error = _configure_native(profile, true, false)
	_live = configuration_error.is_empty()
	_core_enabled = true
	if _live and not root_network.call("set_active", true): configuration_error = "Declared initial native Core activation declined"
	_present()

func _configure_native(profile: String, tracked: bool, with_helper: bool) -> String:
	if _configured or not _choice_profile.is_empty() or declared_cell != "root" or test_production_transition or not configuration_error.is_empty(): return "Fresh declared helper-choice root component required"
	if profile != "challenge": return "Declared helper-choice requires actual saved/fresh Challenge before native construction"
	_choice_profile = profile # Once only, before Core/source native definition binding.
	if not threat_scheduler.begin_encounter(profile, CHOICE_ENCOUNTER, 1): return threat_scheduler.last_error
	if not root_network.call("configure", self, hero, effects, shared_shell, threat_scheduler, get_parent() as Node3D, {FLOOR_ID: _floor}, _response, _view_guard, CHOICE_ENCOUNTER, 1): return String(root_network.get("last_configuration_error"))
	root_network.connect("phase_boundary", _on_boundary)
	var ctx: Dictionary = _context(1)
	if ctx.is_empty(): return "Actual retained native floor context required"
	var prepared: Dictionary = {"world_revision": 1, "collision_fingerprint": ctx.world_collision_fingerprint, "floor_signature": ctx.world_floor_signature}
	# Idle managed source preserves the existing whole Scheduler3 TEST codec.
	# It is never admitted or advanced by this helper-choice adapter.
	if not echo.call("configure_source", CHOICE_ECHO_ID, CHOICE_ECHO_EPOCH, 1, native_definition(), profile, prepared, threat_scheduler) or not echo.call("retain_source_environment", get_parent() as Node3D, [_floor]): return String(echo.get("source_snapshot_error"))
	if tracked and not echo.call("enable_authored_cycle_tracking", threat_scheduler, {"hero": hero}, [_floor], ctx): return String(echo.get("last_error"))
	_configured = true
	if with_helper and not _install_helper(): return configuration_error
	if tracked:
		if not sun_art.call("configure", self, hero): return String(sun_art.get("last_error"))
		_sun_configured = true
	return ""

func _install_helper() -> bool:
	if is_instance_valid(helper):
		configuration_error = "Exactly one actual helper-choice C51 is entitled"
		return false
	helper = Root.new()
	helper.name = "ActualHelperChoiceLatcher"
	add_child(helper)
	helper.global_position = HELPER_POSITION
	if not helper.call("configure", CHOICE_HELPER_ID, hero, effects, threat_scheduler, _helper_response, _helper_guard):
		configuration_error = String(helper.get("last_error"))
		return false
	helper.connect("died", _on_helper_died)
	helper.connect("state_changed", _choice_note_helper_state)
	return true

func native_definition() -> Dictionary:
	var definition: Dictionary = super.native_definition()
	definition.definition_id = "TEST/A3-L4/helper-choice-idle-echo"
	return definition

func scheduler_bindings() -> Dictionary:
	var owners: Dictionary = root_network.call("scheduler_owners") if _configured else {}
	if _configured: owners[CHOICE_ECHO_ID] = echo
	if is_instance_valid(helper): owners[CHOICE_HELPER_ID + "/attack"] = helper.call("get_mechanism")
	return {"world_root": get_parent() as Node3D, "owners": owners, "actors": {"hero": hero}, "floors": {FLOOR_ID: _floor}}

func _context(generation: int) -> Dictionary:
	var signature: Dictionary = Footprint.floor_signature(get_parent() as Node3D, [_floor])
	if not signature.get("accepted", false): return {}
	return {"world_root": get_parent() as Node3D, "source_id": CHOICE_ECHO_ID, "source_epoch": CHOICE_ECHO_EPOCH, "generation": generation, "world_collision_fingerprint": threat_scheduler.pure_collision_fingerprint(get_parent() as Node3D), "world_floor_signature": signature.signature}

func _response(_kind: String, direction: Vector3) -> Dictionary:
	return {"encounter_id": CHOICE_ENCOUNTER, "world_revision": 1, "recognition_s": 0.25, "attack_input_margin_s": 0.06, "escape_directions": [direction], "return_directions": [-direction], "floor_regions": [_floor]}

func _helper_response() -> Dictionary:
	var response: Dictionary = hero.get_threat_response_state()
	var directions: Array[Vector3] = [Vector3.BACK, Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT]
	response.merge({"encounter_id": CHOICE_ENCOUNTER, "world_revision": 1, "world_root": get_parent() as Node3D, "recognition_s": 0.25, "attack_input_margin_s": 0.06, "escape_directions": directions, "return_directions": directions.duplicate(), "floor_regions": [_floor]}, true)
	return response

func try_core(_kind: String, _direction: Vector3) -> Dictionary:
	return {"accepted": false, "reason": "Helper-choice Core admission is automatic canonical policy; caller cannot select kind/direction"}

func admit_echo() -> Dictionary:
	return {"accepted": false, "reason": "Idle managed Echo is not an admitted helper-choice exercise"}

func prepare_next_echo_cycle() -> bool:
	return false

func _physics_process(_delta: float) -> void:
	if not _live or _busy or get_tree().paused or not is_instance_valid(hero) or hero.dead: return
	if _pending_release: _settle_release()
	_present()
	if not _live or _busy or not configuration_error.is_empty() or not is_instance_valid(hero) or hero.dead: return
	var error: String = runtime_error()
	if not error.is_empty():
		configuration_error = error
		return
	if not _released:
		# Same parent130 ordering: one fresh pending choice per ordinary tick.
		_choice_pending_view.clear()
		_choice_step_roots()
	_choice_observe_helper_refusal()
	_present()

func _choice_step_roots() -> void:
	if not is_instance_valid(root_network) or not _core_enabled or _released or _busy or hero.dead or not hero.get_threat_response_state().get("stable", false): return
	var current: Dictionary = root_network.call("state")
	if current.dead or threat_scheduler.get_clock() < float(current.retry_at_s): return
	var kind: String = current.next_kind
	for direction: Vector3 in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		var answer: Dictionary = root_network.call("try_start", kind, direction, int(_sun.effective_index))
		if not _live or not is_instance_valid(hero) or hero.dead or not configuration_error.is_empty(): return
		_choice_note_attempt(kind, direction, answer)
		if answer.get("accepted", false):
			admission_error = ""
			_choice_pending_view.clear()
			return
		admission_error = String(answer.get("reason", "Native garden response rejected"))
		# One measured candidate remains available to ordinary camera follow.
		# Never forecast four alternatives or wait for helper/Core quietness.
		if _choice_pending_view.get("kind") == "core": return

func _choice_note_attempt(kind: String, direction: Vector3, answer: Dictionary) -> void:
	var source: CinderLaneMechanism = (root_network.call("get_mechanisms") as Dictionary)[kind]
	var current: Dictionary = source.state()
	var row: Dictionary = {"owner": "core", "clock_s": threat_scheduler.get_clock(), "kind": kind, "direction": direction, "accepted": answer.get("accepted", false), "reason": answer.get("reason", ""), "cycle": current.cycle, "reservation_id": current.reservation_id}
	_choice_attempt_log.append(row.duplicate(true))
	if answer.get("accepted", false):
		row["native_answer"] = answer.duplicate(true)
		row["native_state"] = current.duplicate(true)
		_choice_admission_log.append(row)
	else: _choice_refusal_log.append(row)

func _choice_note_helper_state(packet: Dictionary) -> void:
	# Public actual native signal, observation only; never calls admission.
	var mechanism: Dictionary = packet.get("mechanism", {})
	var row: Dictionary = {"owner": "helper", "clock_s": packet.get("clock_s"), "phase": packet.get("phase"), "mechanism": mechanism.duplicate(true), "proof": (packet.get("proof", {}) as Dictionary).duplicate(true), "hp": packet.get("hp"), "dead": packet.get("dead")}
	_choice_helper_log.append(row.duplicate(true))
	var id: String = String(mechanism.get("reservation_id", ""))
	if not id.is_empty() and mechanism.get("status") == "running" and not _choice_helper_seen.has(id):
		_choice_helper_seen[id] = true
		row["accepted"] = true
		row["source_id"] = CHOICE_HELPER_ID
		_choice_admission_log.append(row)

func _choice_observe_helper_refusal() -> void:
	if not is_instance_valid(helper): return
	var current: Dictionary = helper.call("state")
	var reason: String = String(current.get("last_rejection", ""))
	if reason != _choice_helper_last_refusal:
		_choice_helper_last_refusal = reason
		if not reason.is_empty(): _choice_refusal_log.append({"owner": "helper", "observation": "changed native last_rejection; not a complete helper attempt census", "clock_s": threat_scheduler.get_clock(), "reason": reason})

func _view_guard(current: bool, prospective: Dictionary) -> String:
	if not prospective.is_empty(): _choice_pending_view = {"kind": "core", "core": prospective.duplicate(true)}
	return _choice_guard_union(_choice_framing_union(get_viewport().get_camera_3d(), prospective, {}, not prospective.is_empty()), current)

func _helper_guard(current: bool, preview: Dictionary) -> String:
	if not preview.is_empty():
		if not preview.get("proof") is Dictionary or not preview.get("candidate") is Dictionary or not preview.candidate.get("geometry") is Dictionary: return "Actual native helper preview geometry/proof required"
		_choice_pending_view = {"kind": "helper", "preview": preview.duplicate(true)}
	return _choice_guard_union(_choice_framing_union(get_viewport().get_camera_3d(), {}, preview, false), current)

func _choice_guard_union(bounds: Dictionary, current: bool) -> String:
	if not String(bounds.get("error", "Actual native helper-choice union required")).is_empty(): return String(bounds.get("error"))
	if bounds.points.is_empty(): return "Complete native helper-choice union cannot be empty"
	if current: return String(shared_shell.call("camera_framing_error", bounds.points))
	var plan: Dictionary = shared_shell.call("camera_framing_plan", bounds.points, hero.global_position + Vector3.UP * 0.75)
	return "" if plan.get("accepted", false) else String(plan.get("reason", "Complete prospective native portrait does not fit"))

func framing_union(camera: Camera3D, prospective: Dictionary = {}, helper_preview: Dictionary = {}) -> Dictionary:
	return _choice_framing_union(camera, prospective, helper_preview, true)

func choice_snapshot_framing_union(camera: Camera3D) -> Dictionary:
	# Same canonical save-view policy: exclude ONLY an unallocated pure preview.
	# Actual held native Core/helper geometry/proofs/history stay included. This
	# getter never clears the pending preview or mutates any native state.
	return _choice_framing_union(camera, {}, {}, false)

func _choice_framing_union(camera: Camera3D, prospective: Dictionary, helper_preview: Dictionary, include_pending: bool) -> Dictionary:
	if not _configured or not is_instance_valid(camera): return {"error": "Actual configured helper-choice Camera required", "points": []}
	var points: Array = shared_shell.call("player_camera_framing_points_for", hero, camera)
	if points.is_empty(): return {"error": "Actual native Hero corners required", "points": []}
	var core_candidate: Dictionary = prospective
	if core_candidate.is_empty() and include_pending and _choice_pending_view.get("kind") == "core": core_candidate = _choice_pending_view.core
	if _core_enabled:
		var core: Dictionary = root_network.call("framing_points_for_context", camera, core_candidate)
		if not core.get("accepted", false): return {"error": String(core.get("reason", "Complete native Core union refused")), "points": []}
		points.append_array(core.points)
		var roots: Dictionary = scenery.call("framing_points", camera, false)
		if not String(roots.get("error", "Actual scenic root geometry required")).is_empty(): return {"error": String(roots.get("error")), "points": []}
		points.append_array(roots.points)
	# Keep the actually rendered idle source; it gains no admitted replay.
	var echo_bounds: Dictionary = echo.call("framing_points")
	if not String(echo_bounds.get("error", "Actual idle source bounds required")).is_empty(): return {"error": String(echo_bounds.get("error")), "points": []}
	points.append_array(_enclose(echo_bounds.points))
	if is_instance_valid(helper):
		var selected_preview: Dictionary = helper_preview
		if selected_preview.is_empty() and include_pending and _choice_pending_view.get("kind") == "helper": selected_preview = _choice_pending_view.preview
		var held: bool = not threat_scheduler.source_control_state(helper.call("get_mechanism")).get("reservations", []).is_empty()
		var selected: Dictionary = selected_preview.get("proof", {}) if not selected_preview.is_empty() else (helper.call("get_selected_response") if held else {})
		var shape: Dictionary = selected_preview.get("candidate", {}).get("geometry", {}) if not selected_preview.is_empty() else {}
		var bounds: Dictionary = helper.call("framing_points_for_camera", camera, shape) if held or not selected_preview.is_empty() else helper.call("current_render_framing_points_for_camera", camera)
		if not String(bounds.get("error", "Actual helper bounds required")).is_empty(): return {"error": String(bounds.get("error")), "points": []}
		points.append_array(_enclose(bounds.points))
		for key: String in ["landing", "attack_position"]:
			if selected.get(key) is Vector3:
				for corner: Vector3 in shared_shell.call("player_camera_framing_points_for", hero, camera): points.append(corner + selected[key] - hero.global_position)
	return {"error": "" if points.size() <= 224 else "Complete native helper-choice groups exceed224", "points": points}

func runtime_error() -> String:
	var error: String = super.runtime_error()
	if not error.is_empty(): return error
	if declared_cell != "root" or test_production_transition or _pair.get_script() != ChoiceCodec or _choice_profile != "challenge" or threat_scheduler.encounter_profile().get("id") != _choice_profile: return "Immutable declared Challenge/root/helper-choice codec required"
	if not _lease.is_empty() or not _projection.is_empty() or not _positions.is_empty() or echo.call("get_authored_cycle_generation") != 1: return "Unadmitted original idle Echo may not become an unrelated exercise"
	var idle_source: Dictionary = echo.call("get_source_state")
	if idle_source.get("alive") != true or idle_source.get("source_hits") != 0 or idle_source.get("hp") != idle_source.get("max_hp") or not idle_source.get("hit_receipts") is Array or not (idle_source.hit_receipts as Array).is_empty(): return "Unrelated idle Echo must retain actual full HP/alive/zero hits/empty receipts"
	var phase: String = String(echo.call("source_phase"))
	if phase == "idle":
		# Existing native restore order prevalidates the genuine inert source
		# BEFORE public prepare_authored_restore changes it to managed ready.
		# This exception cannot authorize an idle live/prepared/delivered source.
		var playback: Dictionary = echo.call("state")
		var source: Dictionary = echo.call("get_source_state")
		if not is_restore_candidate() or not get_tree().paused or _live or _restore_started or _restore_finished or not _restore_expected.is_empty() or echo.call("source_cycles_managed") or playback.get("status") != "idle" or not String(playback.get("reservation_id", "")).is_empty() or not (playback.get("opportunities", []) as Array).is_empty() or not (echo.call("get_authored_cycle_terminal_receipt") as Dictionary).is_empty() or source.get("source_hits") != 0 or source.get("alive") != true or source.get("hp") != source.get("max_hp") or not _choice_attempt_log.is_empty() or not _choice_admission_log.is_empty(): return "Only the fresh paused untracked native generation1 pre-prepare recipient may be idle"
	elif phase != "cycle_ready" or not echo.call("source_cycles_managed"):
		return "Live/prepared helper-choice source must remain actual managed generation1 cycle_ready"
	return ""

func choice_state() -> Dictionary:
	return {"api_revision": "TEST-act3-garden-helper-choice-observation-1", "profile": _choice_profile, "policy": CHOICE_POLICY, "clock_s": threat_scheduler.get_clock() if _configured else 0.0, "core": root_network.call("state") if _configured else {}, "helper": helper.call("state") if is_instance_valid(helper) else {}, "component": component_state(), "pending_view": _choice_pending_view.duplicate(true), "core_attempt_count": _choice_attempt_log.size(), "admission_count": _choice_admission_log.size(), "refusal_observation_count": _choice_refusal_log.size(), "helper_state_observation_count": _choice_helper_log.size()}

func root_proof(kind: String) -> Dictionary:
	if not _configured or kind not in ["draw", "enclose"]: return {}
	var actual: Dictionary = root_network.call("state")
	return (actual.proofs.get(kind, {}) as Dictionary).duplicate(true)

func choice_attempts() -> Array[Dictionary]: return _choice_attempt_log.duplicate(true)
func choice_admissions() -> Array[Dictionary]: return _choice_admission_log.duplicate(true)
func choice_refusals() -> Array[Dictionary]: return _choice_refusal_log.duplicate(true)
func choice_helper_observations() -> Array[Dictionary]: return _choice_helper_log.duplicate(true)
