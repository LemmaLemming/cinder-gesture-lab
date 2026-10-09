extends "res://tests/acts/act1/a1_l3_normal_opening.gd"
## PRIVATE INERT CANDIDATE. Not imported, parsed, executed or accepted.
## One targeted first-room admission boundary per invocation; any subsequent
## real other-source publication is also recorded. The five modes are separate
## jobs, not a whole-parent Save/restore or later publication-listener fixture.
## Promote only with the exact reviewed composed base770; all clocks, profile
## budgets, native geometry, actor configuration and recognizer remain real.

const CustodyCases: Array[String] = ["valid", "source-cancel", "cue-cancel", "source-pause", "cue-pause"]
const ExpectedSources: Dictionary = {
	"res://scripts/acts/act1/mushroom_caverns.gd": "55b30d6d639bf4a468e27189ef4703039b630e4c96fcc88564b1f7e5d912ecd4",
	"res://scripts/acts/act1/mushroom_caverns_route.gd": "04f0655d4996bef6a9e25ff144ab701a98b3ae333c6faffa8236f3140d4d91f6",
	"res://scripts/acts/act1/mushroom_selenite.gd": "24749ae5a7dd4334aac643fffac603570040098a3970929561e53a4f86e51576",
	"res://tests/acts/act1/a1_l3_normal_opening.gd": "6938db3d34ac3b70ed24641b345f1f8f1e80a9e54acf81ad0d477eb573d41a91",
	"res://tests/acts/act1/a1_l3_crowd.gd": "d3e15e72118ac27f3725f7513090d44647792b643ac04dae46c8f223146e2c80",
	"res://tests/acts/act1/a1_l3_actor_pair.gd": "8a66ac90a8fe4b968a2066cc6614a262c1dfc2711ef5f3c1a727b91c08feb9a9",
	"res://tests/acts/act1/a1_l3_greybox.gd": "e98a81e75a775c07faf34b7c6b1beb691fd0f154e25eb84132e32de5176feefb",
	"res://scripts/game.gd": "0b16d911409350a392f741a07bc163ad73c588d885ee7e1e64b951f97aa30d26",
	"res://scripts/player.gd": "8e4dfeb2c285f1d786ec3268bdaf5efbc70b3b0f4b2473b2870e0566a88e4743",
	"res://scripts/combat/threat_scheduler.gd": "9b11730b4041dfb73a20e97bda0c72854a89af1ab79809fb3d8449fec624ae79",
	"res://scripts/cues/threat_cue.gd": "c8a7abbbd4c021ec92c45e1e57fc966873110231b781dba00bd1ff3d63f5cc5a",
	"res://scenes/main.tscn": "c0c169890eed0afb26b1a09a017d45c90a64aa8ba874a683deb141c4190ee06b",
	"res://scenes/acts/act1/a1_l3_route_greybox.tscn": "57f48e099659d6d5458f9780c97d7cc3754b5b74b30df8186e46ca89443d7327"
}

var custody_case: String = "valid"
var selected: Dictionary = {}
var warning_receipts: Array[Dictionary] = []
var publication_receipts: Array[Dictionary] = []
var observer_action: Dictionary = {}
var custody_result: Dictionary = {}
var action_taken: bool = false


func _run() -> void:
	root.size = PortraitSize
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--case="): custody_case = argument.trim_prefix("--case=")
	if not _require(custody_case in CustodyCases, "one explicit supported initial-admission custody case"):
		await _finish(); return
	for path: String in ExpectedSources:
		if not _require(FileAccess.get_sha256(path) == ExpectedSources[path], "exact reviewed expected dependency: " + path):
			await _finish(); return
	if not await _open_world(NormalOpeningPath, "initial-admission-" + custody_case, Vector3(0, 0.1, 15)):
		await _finish(); return
	if not _require(game.get("player") == hero and hero.equipment.snapshot() == {"jacket": "CLOTH-J0", "pants": "CLOTH-P0", "shoes": "CLOTH-S0", "weapon": "WEAPON-01"}, "actual shared Hero retains the unseeded neutral starter kit"):
		await _finish(); return
	# The genuine normal spawn is still an unbegun approach. Connect both real
	# initial publishers before the first recognizer gesture or any physics wait.
	for id: String in CrowdIds:
		var actor: Act1MushroomSelenite = sources[id]
		actor.state_changed.connect(Callable(self, "_warning_observer").bind(id, "source"))
		(actor.get_cue() as CinderThreatCue).state_changed.connect(Callable(self, "_warning_observer").bind(id, "cue"))
	if not await _entry_and_initial_warning():
		await _finish(); return
	if not _check_returned_custody():
		await _finish(); return
	# Invalid pause modes already stopped synchronously inside unfinished start.
	# Other modes stop here only AFTER the initial call and parent publication
	# have returned. This is a public pause, not a forced mutation or resume.
	if not paused: game.call("open_bench")
	if not _require(paused, "post-return observation uses the actual public pause menu"):
		await _finish(); return
	var frozen: Dictionary = _custody_observation()
	for _frame: int in range(4): await process_frame
	if not _require(var_to_bytes(_custody_observation()) == var_to_bytes(frozen), "actual paused source/lease/cooldown/cue/body/Player/action bits remain exact without a repair"):
		await _finish(); return
	if not _future_pristine(CrowdIds, "narrow first admission") or not _retained_truth("initial admission custody"):
		await _finish(); return
	if not _require(hero.hp == initial_hp and not hero.dead and hit_events.is_empty() and primaries == 0 and opening_checkpoint_events.is_empty() and opening_completion_events == 0 and opening_contact_events == 0 and level.current_checkpoint().id == "" and not level.is_completed() and not preparing_violation, "one genuine initial admission grants no damage, primary, checkpoint, completion or contact"):
		await _finish(); return
	custody_result["paused_observation"] = _portable(frozen)
	custody_result["future_sources_pristine"] = true
	await _finish()


## The raw recognizer sequence is the existing full-swipe helper's sequence.
## Its final readiness wait is deliberately not inherited: an expected direct
## pause cannot advance the real cooldown. Instead inspect the actual completed
## dash receipt, native landing and stopped body. Do not credit an incomplete
## dash, waive a collision/endpoint check, or force resume to finish one.
func _entry_and_initial_warning() -> bool:
	if not await _ready_input("genuine initial admission entrance"): return false
	var direction: Vector3 = Vector3.FORWARD
	var finish := Vector2(270, 650)
	var delta: Vector2 = _screen_delta(direction) * 180.0
	if not _require(_input_safe(finish - delta) and _input_safe(finish) and (game.call("screen_to_direction", delta) as Vector3).dot(direction) > 0.9999, "initial entrance uses the actual camera basis and safe recognizer coordinates"): return false
	var sequence: int = _last_sequence()
	var before: Dictionary = game.call("get_input_observation_state")
	var origin: Vector3 = hero.global_position
	var press := InputEventScreenTouch.new()
	press.index = 7; press.pressed = true; press.position = finish - delta
	Input.parse_input_event(press)
	await process_frame
	if not _guard_input(): return false
	var drag := InputEventScreenDrag.new()
	drag.index = 7; drag.position = finish; drag.relative = delta
	Input.parse_input_event(drag)
	await process_frame
	if not _guard_input(): return false
	var release := InputEventScreenTouch.new()
	release.index = 7; release.position = finish
	Input.parse_input_event(release)
	await process_frame
	# Keep NormalOpening's four-simulation-second stopped-readiness window.
	# Only an actual observed direct pause exits that wait without claiming
	# cooldown readiness; the completed native dash is still checked below.
	var input_deadline: float = float(hero.get_threat_response_state().action_clock_s) + 4.0
	var ready_after: bool = false
	while not aborted and not finishing:
		if paused:
			if not _require(action_taken and custody_case.ends_with("-pause") and observer_action.get("paused_after") == true, "post-release pause came from the selected real unfinished-start observer"): return false
			break
		if not _guard_input(): return false
		var input_state: Dictionary = hero.get_threat_response_state()
		if input_state.stable and float(input_state.dash_cooldown_left_s) == 0.0 and float(input_state.primary_cooldown_left_s) == 0.0 and float(input_state.commitment_remaining_s) == 0.0:
			ready_after = true
			break
		if not _require_unexpected(float(input_state.action_clock_s) < input_deadline, "post-release stopped readiness remains within the original four simulation seconds"): return false
		_sample_preparing()
		await process_frame
	var deadline: int = Time.get_ticks_msec() + 8000 # Existing 8s component window.
	while not aborted and not finishing and Time.get_ticks_msec() < deadline:
		if paused and not (action_taken and custody_case.ends_with("-pause") and observer_action.get("paused_after") == true):
			return _require(false, "only the explicitly observed synchronous public-pause fault may stop entrance input")
		if not is_instance_valid(hero) or hero.dead: return _require(false, "real living Hero remains available during initial admission")
		if not selected.is_empty():
			var actor: Act1MushroomSelenite = sources[selected.id]
			if actor.get_spore_response_state().get("outside_transaction") == true: break
		await process_frame
	if aborted or finishing: return false
	if not _require(not selected.is_empty() and sources[selected.id].get_spore_response_state().get("outside_transaction") == true, "genuine initial Warning observer runs and original actor.start returns within the unchanged component window"): return false
	var records: Array[Dictionary] = hero.get_world_action_records(sequence)
	var observed: Dictionary = game.call("get_input_observation_state")
	var normalized: Vector2 = finish / Vector2(PortraitSize)
	var distance: float = float(hero.equipment.resolved_stats().dash_distance)
	var motion: Dictionary = hero.get_committed_dash_state()
	if not _require(records.size() == 1 and records[0].kind == "dash" and not records[0].collision_shortened and absf(float(records[0].distance) - distance) <= PositionTolerance and records[0].direction.dot(direction) > 0.9999 and _planar_distance(origin, hero.global_position) > distance - PositionTolerance and records[0].landing.distance_to(hero.global_position) <= PositionTolerance and records[0].path.size() >= 2 and motion.get("active") == false and observed.sequence == before.sequence + 1 and observed.last_observation.kind == "swipe_release" and observed.anchor_normalized == normalized and game.call("get_aim_anchor_normalized") == normalized, "real press/drag/release executes the full original dash with its literal anchor and actual completed landing"): return false
	swipes += 1 # Credit only after the complete actual receipt passed above.
	custody_result["entrance"] = _portable({"origin": origin, "native_action": records[0], "input_before": before, "input_after": observed, "actual_landing": hero.global_position, "committed_dash": motion, "actual_post_release_readiness": ready_after, "expected_callback_pause_stopped_wait": paused and not ready_after})
	return true


func _warning_observer(published: Dictionary, id: String, origin: String) -> void:
	if finishing or aborted or published.get("phase") != "warning": return
	var actor: Act1MushroomSelenite = sources[id]
	var state: Dictionary = actor.pure_presentation_state()
	var control: Dictionary = scheduler.source_control_state(actor)
	var response: Dictionary = actor.get_spore_response_state()
	var native: Dictionary = actor.get_spore_native_bindings()
	var route: Dictionary = level.call("route_state")
	var cue: Dictionary = (actor.get_cue() as CinderThreatCue).state()
	if state.get("cycle") != 1: return # This fixture targets only genuine initial publication.
	var frames: Dictionary = level.get("_framing")
	var packet: Dictionary = {"origin": origin, "source_id": id, "published": published.duplicate(true), "actor": state, "control": control, "response": response, "parent_frame_present": frames.has(id), "parent_publications_before": publication_receipts.size(), "paused_before": paused}
	warning_receipts.append(packet)
	var wanted: String = "cue" if custody_case.begins_with("cue-") else "source"
	if origin != wanted or not selected.is_empty(): return
	if not _require(scheduler.encounter_profile().get("id") == "standard" and cue.get("phase") == "warning" and cue.get("geometry") == state.get("geometry") and cue.get("source_position") == actor.global_position and cue.get("source_visible") == true and cue.get("footprint_visible") == true and cue.get("active_fill_visible") == false, "actual Standard initial Warning presents its matching required native source marker and complete footprint before the observer action"): return
	if not _require(route.get("beat_index") == 0 and route.get("room_stage") == "active" and route.get("encounter_started") == true and id in level.call("current_source_ids") and actor.get_parent() == level and state.get("entity_id") == "C31" and state.get("phase") == "warning" and state.get("status") == "running" and state.get("dead") == false and not state.get("dormant", true) and response.get("alive") == true and response.get("outside_transaction") == false and control.get("outside_transaction") == true and control.get("encounter_id") == "a1_l3_umbrella" and control.get("world_revision") == 1 and control.get("source_instance_id") == actor.get_instance_id() and control.get("reservations") is Array and control.reservations.size() == 1 and control.reservations[0].get("id") == state.get("reservation_id") and control.reservations[0].get("source_instance_id") == actor.get_instance_id() and native.get("player") == hero and native.get("scheduler") == scheduler and control.reservations[0].get("start_s") == control.get("clock_s") and control.get("cooldown") is Dictionary and not frames.has(id) and publication_receipts.is_empty() and not paused, "real initial " + origin + " Warning occurs inside unfinished actor.start with its exact native owner/Player lease and cooldown, before parent response publication"): return
	selected = {"id": id, "lease_id": state.reservation_id, "record": control.reservations[0].duplicate(true), "cooldown": control.cooldown.duplicate(true), "clock_s": control.clock_s, "origin": origin, "source_instance_id": actor.get_instance_id(), "hero_instance_id": hero.get_instance_id()}
	if custody_case == "valid": return
	action_taken = true # Set before nested clear observers can re-enter this test.
	observer_action = {"origin": origin, "before": packet, "kind": custody_case}
	if custody_case.ends_with("-cancel"):
		observer_action["cancel_return"] = actor.cancel("fixture_initial_" + custody_case)
	else:
		game.call("open_bench") # Real synchronous public pause, before start returns.
	observer_action["after"] = {"actor": actor.pure_presentation_state(), "control": scheduler.source_control_state(actor), "response": actor.get_spore_response_state()}
	observer_action["paused_after"] = paused
	# Do not call Cue.clear, free a source, mutate phase/body/HP/clock, or attempt
	# a snapshot inside these callbacks. Cue.clear's own notifier rejects such
	# nested clears; Actor._present retries naturally after Cue.present returns.


## Capture EVERY signal before any validation; never inherit the stale-lease
## filter in _notice_admission. A bad signal must remain an actionable receipt.
func _notice_admission(id: String, answer: Dictionary) -> void:
	var raw: Variant = sources.get(id)
	var actor: Act1MushroomSelenite = raw if is_instance_valid(raw) and raw is Act1MushroomSelenite else null
	var control: Dictionary = scheduler.source_control_state(actor) if actor != null else {}
	var state: Dictionary = actor.pure_presentation_state() if actor != null else {}
	var response: Dictionary = actor.get_spore_response_state() if actor != null else {}
	var frames: Dictionary = level.get("_framing")
	publication_receipts.append({"source_id": id, "answer": answer.duplicate(true), "actor": state, "control": control, "response": response, "frame": frames.get(id, {}).duplicate(true), "paused": paused})
	if not _require(actor != null and answer.get("accepted") == true and answer.get("reservation") is Dictionary and control.get("reservations") is Array and control.reservations.size() == 1 and control.get("outside_transaction") == true and response.get("outside_transaction") == true and response.get("alive") == true and not paused and control.reservations[0].get("id") == answer.get("reservation_id") and state.get("reservation_id") == answer.get("reservation_id") and var_to_bytes(control.reservations[0]) == var_to_bytes(answer.reservation) and frames.get(id, {}).get("reservation_id") == answer.get("reservation_id"), "every actual parent publication names the exact same live native exchange after Actor/Scheduler callbacks return"): return
	if not selected.is_empty() and id == selected.id:
		_require(custody_case == "valid" and answer.reservation_id == selected.lease_id and var_to_bytes(answer.reservation) == var_to_bytes(selected.record), "only valid initial control publishes its original native lease once; invalidated Warning cannot publish stale response")


## Keep activation/event observation, without inherited state() calls that can
## prune a lease during these synchronous actor callbacks.
func _notice_phase(state: Dictionary, id: String) -> void:
	events += 1
	if opening_dormancy.get(id, true) and not state.get("dormant", true):
		opening_activation_counts[id] = int(opening_activation_counts.get(id, 0)) + 1
	opening_dormancy[id] = state.get("dormant", true)
	_sample_preparing() # NormalOpening uses only pure_presentation_state here.


func _check_returned_custody() -> bool:
	var id: String = selected.id
	var actor: Act1MushroomSelenite = sources[id]
	var control: Dictionary = scheduler.source_control_state(actor)
	var state: Dictionary = actor.pure_presentation_state()
	var response: Dictionary = actor.get_spore_response_state()
	var cue: Dictionary = (actor.get_cue() as CinderThreatCue).state()
	var frames: Dictionary = level.get("_framing")
	var target_publications: int = 0
	for packet: Dictionary in publication_receipts:
		if packet.source_id == id: target_publications += 1
	if not _require(control.get("outside_transaction") == true and response.get("outside_transaction") == true and response.get("alive") == true and actor.get_instance_id() == selected.source_instance_id and hero.get_instance_id() == selected.hero_instance_id and control.get("cooldown") is Dictionary and var_to_bytes(control.cooldown) == var_to_bytes(selected.cooldown) and float(control.cooldown.ready_s) == float(selected.record.cooldown_until_s) and float(control.clock_s) < float(control.cooldown.ready_s), "completed start retains the real same-owner cooldown deadline and living native identities"): return false
	if custody_case == "valid":
		if not _require(target_publications == 1 and control.reservations.size() == 1 and control.reservations[0].id == selected.lease_id and state.reservation_id == selected.lease_id and state.cycle == 1 and frames.get(id, {}).get("reservation_id") == selected.lease_id and not action_taken, "valid initial admission publishes exactly once and retains the same original native lease and parent response"): return false
		var points: Array = level.camera_framing_points()
		if not _require(not points.is_empty() and level.last_camera_framing_error.is_empty() and String(game.call("camera_framing_error", points)).is_empty(), "valid actual whole-source/lane/response provider passes the unchanged native camera guard"): return false
	else:
		if not _require(action_taken and target_publications == 0 and control.reservations.is_empty() and state.reservation_id == "" and state.cycle == 1 and state.phase == "clear" and cue.phase == "clear" and not cue.source_visible and not cue.footprint_visible and not frames.has(id) and String(level.get("_forecast_owner")) != id and (level.get("_render_sources") as Dictionary).get(id, {}).get("reservation_id") == "", "invalidated initial Warning retains cooldown but leaves no native lease, stale parent frame/lookahead, cue or target publication"): return false
		if custody_case.ends_with("-cancel"):
			var after: Dictionary = observer_action.after
			if not _require(observer_action.cancel_return == true and after.control.reservations.is_empty() and var_to_bytes(after.control.cooldown) == var_to_bytes(selected.cooldown) and float(after.control.clock_s) == float(selected.clock_s) and after.response.get("outside_transaction") == false and state.last_cancel_reason == "fixture_initial_" + custody_case and observer_action.paused_after == false, "public actor.cancel ran synchronously inside original start, kept its exact clock/cooldown and required no fixture repair"): return false
		else:
			var after: Dictionary = observer_action.after
			if not _require(observer_action.paused_after == true and paused and after.control.reservations.size() == 1 and after.control.reservations[0].id == selected.lease_id and var_to_bytes(after.control.cooldown) == var_to_bytes(selected.cooldown) and after.response.get("outside_transaction") == false and float(control.clock_s) == float(selected.clock_s) and state.last_cancel_reason == "owned_admission_custody_rejected", "direct public pause retained the real unfinished lease in its callback; returned parent custody rejects only that corroborated lease without advancing native time"): return false
	custody_result["returned"] = _portable({"source_id": id, "target_publications": target_publications, "actor": state, "control": control, "response": response, "cue": cue, "frames": frames, "last_admission_diagnostic": level.get("last_admission"), "last_encounter_error": level.get("last_encounter_error")})
	return true


func _custody_observation() -> Dictionary:
	var actor: Act1MushroomSelenite = sources[selected.id]
	return {"actor": actor.pure_presentation_state(), "source_transform": actor.global_transform, "body_transform": (actor.get_node("BodyCollision") as CollisionShape3D).global_transform, "control": scheduler.source_control_state(actor), "cue": (actor.get_cue() as CinderThreatCue).state(), "player": hero.get_threat_response_state(), "hero_transform": hero.global_transform, "dash": hero.get_committed_dash_state(), "input": game.call("get_input_observation_state"), "world_actions": hero.get_world_action_records(), "frames": (level.get("_framing") as Dictionary).duplicate(true), "forecast_owner": level.get("_forecast_owner"), "publication_count": publication_receipts.size(), "warning_count": warning_receipts.size(), "event_count": events}


## Run only after original callbacks have unwound. This is ordinary explicit
## level exit and public effects cleanup, not unsupported free during start.
func _retire_custody_world() -> void:
	if not is_instance_valid(game): return
	paused = true # Cleanup barrier only; callback stimulus above is open_bench.
	var old_game: Node = game
	var old_level: Node = level
	var old_hero: Node = hero
	var old_scheduler: Node = scheduler
	var old_sources: Array = sources.values().duplicate()
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(scheduler):
		var empty: bool = not scheduler.is_physics_processing()
		for raw: Variant in old_sources:
			if is_instance_valid(raw): empty = empty and scheduler.source_control_state(raw).get("reservations", []).is_empty() and not raw.is_physics_processing() and not raw.is_in_group("enemies")
		_require(empty, "explicit entered level exit retires actual native leases, source physics and target membership")
	var effects: PixelEffects = game.get("fx") as PixelEffects
	if is_instance_valid(effects): effects.clear()
	await create_timer(0.5, true).timeout # Existing paused AudioServer retirement.
	game.queue_free()
	await process_frame
	var removed: bool = not is_instance_valid(old_game) and not is_instance_valid(old_level) and not is_instance_valid(old_hero) and not is_instance_valid(old_scheduler)
	for raw: Variant in old_sources: removed = removed and not is_instance_valid(raw)
	sources.clear(); opening_references.clear(); game = null; level = null; hero = null; scheduler = null
	paused = false
	await process_frame
	_require(removed and get_nodes_in_group("enemies").is_empty(), "deferred post-callback cleanup removes actual entered world and leaves no enemy target nodes")


func _finish() -> void:
	if finishing: return
	finishing = true
	# No callback invokes finish directly: both ordinary return and watchdog's
	# inherited call_deferred reach this after unfinished actor.start unwinds.
	# Convert diagnostic Object references while their real world still exists;
	# this redacted JSON report is not native transport or a capture authority.
	var report: Dictionary = {"scope": "one targeted initial admission boundary in the actual neutral/Standard first room; all raw subsequent other-source publications retained; initial Source/Cue Warning observer only; no whole-parent Save/restore, later parent-listener cancellation, route completion, portrait, performance or acceptance claim", "case": custody_case, "actual_swipes": swipes, "actual_primaries": primaries, "expected_sources": ExpectedSources, "selected": _portable(selected), "warning_receipts": _portable(warning_receipts), "all_raw_parent_publications": _portable(publication_receipts), "observer_action": _portable(observer_action), "result": custody_result, "world_actions": _portable(world_records), "input_observations": _portable(input_observations)}
	await _retire_custody_world()
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	var path: String = "res://.cinder/l3-initial-admission-custody-%d.json" % Time.get_ticks_usec()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_require(false, "narrow native custody recorder opens its distinct report")
	else:
		report["checks"] = checks
		report["failures"] = failures
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print("A1-L3 INITIAL ADMISSION CUSTODY [%s]: %d checks, %d failures; %d real swipes, %d primaries; report=%s; NO WHOLE-PARENT SAVE/ROUTE/PORTRAIT CLAIM" % [custody_case, checks, failures, swipes, primaries, path])
	quit(1 if failures else 0)
