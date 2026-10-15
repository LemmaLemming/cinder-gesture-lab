extends "res://tests/acts/act1/a1_l4_whole_save.gd"
## Focused new court policy. Public TEST predecessor completions, actor injuries
## and stationary Hero placement are representative setup, never earned play.
## Existing native clocks, geometry, source proofs and durations stay live.

const CourtCodec = preload("res://scripts/acts/act1/selenite_court_codec.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const LEGACY_PACKETS: String = "res://tests/acts/act1/fixtures/a1_l4_difficulty_legacy_packets.json"
var selected_profile: String = "challenge"
var report_path: String = ""
var rows: Array[Dictionary] = []
var complete: bool = false
var _admissions: Array[Dictionary] = []
var _seen_leases: Dictionary = {}
var _pair: Dictionary = {}
var _prelock_observed: bool = false
var _source_before: Dictionary = {}
var _admission_diagnostics: Dictionary = {}


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	old_fps = Engine.max_fps
	old_audio = AudioServer.generate_bus_layout()
	test_root = "user://test-court-arrangement-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	report_path = OS.get_environment("CINDER_COURT_ARRANGEMENT_REPORT")
	if report_path.is_empty(): report_path = ProjectSettings.globalize_path("res://.cinder/court-arrangement-%d.json" % Time.get_ticks_usec())
	_source_before = _source_observation()
	process_frame.connect(_watchdog)
	physics_frame.connect(_observe_admissions)
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	registry_text = FileAccess.get_file_as_string(Registry.DATA_PATH)
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--profile="): selected_profile = argument.trim_prefix("--profile=")
	if not _expect(selected_profile in ["pure", "legacy", "assisted", "standard", "challenge"], "one explicit focused preset, legacy transport or pure mode"):
		await _finish(); return
	if not _policy_data(): await _finish(); return
	if selected_profile == "pure": complete = true; await _finish(); return
	var parsed: Variant = JSON.parse_string(registry_text)
	if not _expect(parsed is Dictionary and parsed.get("levels") is Array, "canonical registry supplies disclosed TEST predecessor metadata"):
		await _finish(); return
	raw = parsed.duplicate(true)
	for entry: Dictionary in raw.levels:
		if entry.id in ["A1-L1", "A1-L2", "A1-L3", "A1-L4"]:
			entry.scene_path = ScenePath if entry.id == "A1-L4" else "res://tests/fixtures/campaign/live_%s.tscn" % String(entry.id).to_lower().replace("-", "_")
			entry.readiness = "accepted"; entry.accepted_commit = "f".repeat(40); entry.api_revision = Registry.API_REVISION
	game = _new_shell()
	if game == null or not await _settle(): await _finish(); return
	var fresh_profile: String = "challenge" if selected_profile == "legacy" else selected_profile
	game.menu.difficulty_preference_requested.emit(fresh_profile)
	if not _expect(game.get_difficulty_preference() == fresh_profile, "public preference changes before the fresh native epoch") or not _press(game, "JourneyButton") or not await _settle():
		await _finish(); return
	game.menu.select_level("A1-L1")
	if not _press(game, "LevelCardAction") or not await _settle(): await _finish(); return
	game.player.hp = 100.0; game.player.shells = 0
	for id: String in ["A1-L1", "A1-L2", "A1-L3"]:
		if not _expect(game.active_level.level_id == id and game.active_level.request_completion("TEST-court-arrangement-prefix"), "public TEST predecessor completion: " + id) or not await _settle(): await _finish(); return
		if not _expect(game.active_level.request_contact_exit("TEST-court-arrangement-prefix-exit", game.player), "public TEST predecessor contact: " + id) or not await _settle(): await _finish(); return
	if not _expect(game.active_level.level_id == "A1-L4" and _scheduler().encounter_profile().id == fresh_profile, "actual fresh court consumes the selected fixed profile") or not _closed(game.capture_campaign_snapshot()):
		await _finish(); return
	if selected_profile == "legacy":
		complete = await _legacy_transport()
		await _finish(); return
	if not await _resume(game) or not _damage("court-curtain-guard", 24.0) or not await _checkpoint("court-after-curtain") or not await _place(Vector3(0, 0.1, -7)):
		await _finish(); return
	if not await _wait(func() -> bool: return int(game.active_level.get("room")) == 1, "actual formation threshold", 8.0): await _finish(); return
	for id: String in Layout.ROOM_SOURCE_IDS[1]:
		if not _damage(id, 24.0): await _finish(); return
	if not await _checkpoint("court-after-formation"): await _finish(); return
	var earlier: Dictionary = game.attempts.state().story.checkpoint.duplicate(true)
	if not _expect(earlier.level.local.approach_arrangement.is_empty(), "real earlier checkpoint predates any combined recipe") or not await _place(Vector3(0, 0.1, -17)):
		await _finish(); return
	if not await _wait(func() -> bool: return game.active_level.get("_roundel_demonstrated") == true, "actual quiet demonstration finishes before combined selection", 20.0): await _finish(); return
	if not _expect(game.active_level.get("_approach_arrangement") == Layout.fresh_approach_arrangement(selected_profile), "fresh combined boundary selects the complete versioned authored descriptor"):
		await _finish(); return
	if not await _wait(func() -> bool: return not _pair.is_empty() if selected_profile == "challenge" else not _admissions.is_empty(), "real changed-policy admission, not construction order", 20.0):
		await _finish(); return
	if selected_profile == "challenge":
		if not _expect(_prelock_observed and _admissions[0].source_id == Layout.ROUND_EL_ID and float(_pair.guard.start_s) >= float(_pair.circle.lock_from_s) and float(_pair.guard.start_s) <= float(_pair.circle.recovery_until_s), "actual circle warning blocks new guards, then a real guard joins the same committed circle through its original recovery while preserving all original responses"):
			await _finish(); return
	else:
		if _admissions[0].source_id != "court-approach-west": _record_admission_diagnostics()
		if not _expect(_admissions[0].source_id == "court-approach-west", "reference and Assisted preserve actual west-first admission priority"):
			await _finish(); return
	if not await _pause(): await _finish(); return
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _closed(saved) or not _expect(saved.level.local.approach_arrangement == Layout.fresh_approach_arrangement(selected_profile) and saved.level.local.scheduler.profile.id == selected_profile and Exact.stringify(game.attempts.state().story.checkpoint) == Exact.stringify(earlier), "whole active unit retains its recipe/profile and real earlier checkpoint"):
		await _finish(); return
	if not await _brief_portrait(): await _finish(); return
	receipts.append({"stage": "real combined policy Save", "exact_snapshot": Exact.stringify(saved), "exact_checkpoint": Exact.stringify(earlier)})
	var descriptor: Dictionary = saved.level.local.approach_arrangement.duplicate(true)
	game.menu.difficulty_preference_requested.emit("standard" if selected_profile != "standard" else "challenge")
	if not _expect(game.active_level.get("_approach_arrangement") == descriptor and _scheduler().encounter_profile().id == selected_profile, "changed preference does not remap an active recipe or native profile") or not await _fresh_continue(saved):
		await _finish(); return
	var malformed: Dictionary = saved.duplicate(true)
	malformed.level.local.approach_arrangement.order.reverse()
	var donor: Dictionary = _donor()
	candidate = game._prepare_snapshot(malformed)
	var rejected: bool = candidate.is_empty()
	if not candidate.is_empty(): game._dispose(candidate); candidate = {}
	if not _expect(not CourtCodec.metadata_error(malformed.level.local).is_empty() and rejected and _donor() == donor, "tampered retained recipe refuses before donor or disk mutation"):
		await _finish(); return
	game.request_retry()
	if not await _settle() or not _expect(Exact.stringify(game.capture_campaign_snapshot()) == Exact.stringify(earlier) and game.active_level.get("_approach_arrangement").is_empty(), "public earlier Retry restores its own pre-combination unit without a later receipt"):
		await _finish(); return
	complete = true
	await _finish()


func _policy_data() -> bool:
	for profile: String in ["assisted", "standard", "challenge"]:
		var selected: Dictionary = Layout.fresh_approach_arrangement(profile)
		if not _expect(not selected.is_empty() and selected.profile == profile and Layout.approach_arrangement_error(selected).is_empty(), "complete trusted authored recipe: " + profile): return false
	var standard: Dictionary = Layout.fresh_approach_arrangement("standard")
	var challenge: Dictionary = Layout.fresh_approach_arrangement("challenge")
	return _expect(standard.order == ["court-approach-west", "court-approach-east", "court-roundel"] and challenge.recipe_id == Layout.APPROACH_CHALLENGE_RECIPE and challenge.order == ["court-roundel", "court-approach-west", "court-approach-east"] and Layout.fresh_approach_arrangement("unknown").is_empty(), "explicit fixed inventory/reference order/committed-circle policy ID and unknown-profile refusal")


func _fresh_continue(saved: Dictionary) -> bool:
	var donor: Dictionary = _donor()
	fresh = _new_shell()
	if fresh == null: return false
	for index: int in range(8): await process_frame
	if not _expect(paused and fresh.player == null and fresh.active_level == null and fresh.menu.page_name() == "title" and fresh.campaign_error.is_empty(), "independent real Shell reads disk at Title without an installed Player") or not _press(fresh, "ContinueStoryButton"): return false
	for index: int in range(8): await process_frame
	if not _expect(fresh.campaign_error.is_empty() and fresh.active_level != null and paused and Exact.stringify(fresh.capture_campaign_snapshot()) == Exact.stringify(saved) and _identities(fresh.active_level, fresh.player) != _identities(game.active_level, game.player) and _durable(fresh) and _donor() == donor, "fresh disk Continue restores exact independent recipe/native unit without donor/checkpoint mutation") or not _bindings(fresh): return false
	if selected_profile == "challenge":
		var before: Dictionary = _probe(fresh.active_level, fresh.player)
		if not _expect(fresh.active_level.call("_retained_responses_avoid", _pair.guard) == true and _probe(fresh.active_level, fresh.player) == before, "decoded original response arrays support the actual admitted candidate without mutation or a typed-Array mismatch"): return false
		# Install the independently continued world as the live test subject.
		# Dispose the donor before unpausing, so only one world simulates.
		var donor_refs: Array[WeakRef] = _descendant_refs(game)
		if is_instance_valid(game.fx): game.fx.clear()
		game.free(); game = fresh; fresh = null
		if not _expect(_all_freed(donor_refs), "old donor disposed before independently continued gameplay resumes") or not await _resume(game): return false
		var original_cycle: int = int(saved.level.local.roundel.cycle)
		if not await _wait(func() -> bool: return int(game.active_level.get("roundel").state().cycle) > original_cycle and game.active_level.get("roundel").state().status == "running", "real continued next circle cycle retains reciprocal safety", 20.0) or not await _pause(): return false
		var continued: Dictionary = game.capture_campaign_snapshot()
		if not _closed(continued) or not _expect(continued.level.local.approach_arrangement == saved.level.local.approach_arrangement and continued.level.local.scheduler.profile.id == "challenge" and _durable(game), "resumed next-cycle whole Save retains the original recipe/profile and valid original danger-union responses"): return false
		receipts.append({"stage": "real independent Continue resumed next-cycle Save", "exact_snapshot": Exact.stringify(continued)})
		return true
	var refs: Array[WeakRef] = _descendant_refs(fresh)
	if is_instance_valid(fresh.fx): fresh.fx.clear()
	fresh.free(); fresh = null
	return _expect(_all_freed(refs) and _donor() == donor, "fresh Continue disposal leaves no duplicate recipient or donor changes")


func _brief_portrait() -> bool:
	var output: String = OS.get_environment("CINDER_COURT_PORTRAIT_DIR")
	if output.is_empty(): return true
	if not _expect(DisplayServer.get_name() != "headless" and paused, "brief changed-policy capture uses actual paused portrait renderer"): return false
	game.menu.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = output.path_join("challenge-committed-circle-guard.png")
	var okay: bool = image != null and image.get_size() == Vector2i(540, 1170) and image.save_png(path) == OK
	game.menu.show()
	if not _expect(okay, "actual 540x1170 committed-circle/guard view saved for human inspection"): return false
	receipts.append({"stage": "brief actual changed-policy portrait", "path": path, "sha256": FileAccess.get_sha256(path), "setup": "Same disclosed focused state, native simulation paused after real pair, menu hidden only for capture; no gameplay/geometry/cue writes."})
	return true


func _legacy_transport() -> bool:
	var packet: Variant = JSON.parse_string(FileAccess.get_file_as_string(LEGACY_PACKETS))
	if not _expect(packet is Dictionary and packet.get("original_native_report_sha256") == "cdb00092764599060d63997eba15101dbec2a884f9b3a6806897777905f7cd05" and packet.get("records") is Array and packet.records.size() == 3, "three exact original373 producer packets are retained with provenance"):
		return false
	var entrance: Dictionary = {}
	for original: Dictionary in packet.records:
		if not _expect(String(original.exact_snapshot).sha256_text() == original.exact_snapshot_sha256, "original opaque native packet bytes: " + String(original.stage)): return false
		var decoded: Dictionary = Exact.parse(original.exact_snapshot)
		if not _expect(decoded.get("accepted") == true and decoded.value is Dictionary, "exact original typed native packet decodes without rewriting"): return false
		var unit: Dictionary = decoded.value
		if not _expect(unit.level.local.schema_version == 2 and not unit.level.local.has("approach_arrangement") and CourtCodec.metadata_error(unit.level.local).is_empty(), "literal aggregate2 retains no new receipt") or not _direct_candidate(unit): return false
		if original.receipt_index == 0: entrance = unit
	if not _expect(not entrance.is_empty(), "genuine original entrance selected"): return false
	# Deliberate TEST session metadata embeds the unchanged original native unit.
	# It is not presented as the original producer's entire campaign session.
	var session: Dictionary = game.attempts.state().duplicate(true)
	session.story.snapshot = entrance.duplicate(true)
	session.story.checkpoint = entrance.duplicate(true)
	var store = Store.new(test_root + "campaign.json")
	if not _expect(game.attempts.state_error(session).is_empty() and store.write_payload(session), "public format2 Store accepts coherent TEST history with original legacy native entrance"):
		return false
	fresh = _new_shell()
	if fresh == null: return false
	for index: int in range(8): await process_frame
	if not _expect(fresh.player == null and fresh.active_level == null and fresh.menu.page_name() == "title" and fresh.get_difficulty_preference() == "challenge", "independent legacy disk Title reads the deliberately different current preference") or not _press(fresh, "ContinueStoryButton"):
		return false
	for index: int in range(8): await process_frame
	if not _expect(fresh.campaign_error.is_empty() and Exact.stringify(fresh.capture_campaign_snapshot()) == Exact.stringify(entrance) and fresh.active_level.get("_uses_arrangement_receipt") == false and fresh.active_level.get("_approach_arrangement").is_empty() and fresh.active_level.get("scheduler").encounter_profile().id == "standard" and _durable(fresh), "real disk Continue retains original legacy2 native unit and saved Standard profile without adding a recipe"):
		return false
	var before: Dictionary = _identities(fresh.active_level, fresh.player)
	fresh.request_retry()
	for index: int in range(8): await process_frame
	if not _expect(fresh.campaign_error.is_empty() and Exact.stringify(fresh.capture_campaign_snapshot()) == Exact.stringify(entrance) and _identities(fresh.active_level, fresh.player) != before and _durable(fresh), "real legacy earlier Retry creates fresh recipients and recaptures literal original2"):
		return false
	receipts.append({"stage": "original373 legacy entrance disk Continue/Retry", "exact_snapshot": Exact.stringify(entrance), "producer_report_sha256": packet.original_native_report_sha256, "campaign_metadata_is_TEST_setup": true})
	return true


func _observe_admissions() -> void:
	if finishing or aborted or not is_instance_valid(game) or not is_instance_valid(game.active_level) or game.active_level.level_id != "A1-L4" or int(game.active_level.get("room")) != 2 or game.active_level.get("_roundel_demonstrated") != true: return
	var scheduler: CinderThreatScheduler = _scheduler()
	var circle: CinderLaneMechanism = game.active_level.get("roundel")
	var circle_control: Dictionary = scheduler.source_control_state(circle)
	if circle_control.get("encounter_id") != "court-approach": return
	var circle_lease: Dictionary = {}
	for lease: Dictionary in circle_control.get("reservations", []): circle_lease = lease
	if selected_profile == "challenge" and not _prelock_observed and not circle_lease.is_empty() and scheduler.get_clock() < float(circle_lease.lock_from_s):
		_prelock_observed = true
		_expect(_sources()["court-approach-west"].call("pure_presentation_state").cycle == 0 and _sources()["court-approach-east"].call("pure_presentation_state").cycle == 0, "actual first combined circle warning retains both guards without attack admission")
	var owners: Dictionary = {Layout.ROUND_EL_ID: circle, "court-approach-west": _sources()["court-approach-west"], "court-approach-east": _sources()["court-approach-east"]}
	var actual: Array[Dictionary] = []
	for source_id: String in owners:
		for lease: Dictionary in scheduler.source_control_state(owners[source_id]).get("reservations", []):
			if not _seen_leases.has(lease.id): actual.append({"source_id": source_id, "native": lease})
	# Scheduler increments its threat-N serial on each successful admission.
	# Distinct records can have the same start_s in one physics frame; owner
	# enumeration is not execution order. Retain the native IDs as evidence.
	actual.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if float(a.native.start_s) != float(b.native.start_s): return float(a.native.start_s) < float(b.native.start_s)
		return String(a.native.id).trim_prefix("threat-").to_int() < String(b.native.id).trim_prefix("threat-").to_int())
	for observed: Dictionary in actual:
		var lease: Dictionary = observed.native
		_seen_leases[lease.id] = true
		_admissions.append({"source_id": observed.source_id, "reservation_id": lease.id, "start_s": lease.start_s, "lock_from_s": lease.lock_from_s, "active_until_s": lease.active_until_s, "observed_clock_s": scheduler.get_clock()})
		if selected_profile == "challenge" and observed.source_id != Layout.ROUND_EL_ID and _pair.is_empty() and not circle_lease.is_empty():
			_pair = {"circle": circle_lease.duplicate(true), "guard": lease.duplicate(true), "guard_source_id": observed.source_id}


func _closed(saved: Dictionary) -> bool:
	return _expect(not saved.is_empty() and saved.get("level") is Dictionary and saved.level.get("local") is Dictionary and CourtCodec.metadata_error(saved.level.local).is_empty() and saved.level.local.world_revision == 2 and not Exact.stringify(saved).is_empty(), "closed whole court format3 or exact retained legacy2 transport")


func _record_admission_diagnostics() -> void:
	# One post-failure preview explains refusal; this does not manufacture a
	# candidate lease, source admission, framing success or gameplay result.
	for id: String in Layout.ROUND_EL_GUARD_SOURCE_IDS:
		var actor: CharacterBody3D = _sources()[id]
		var context: Dictionary = game.active_level.call("response_context")
		context["world_root"] = game.active_level.call("_world_root")
		var preview: Dictionary = actor.call("preview_start", game.player.global_position, context)
		var state: Dictionary = actor.call("pure_presentation_state")
		_admission_diagnostics[id] = {"preview_accepted": preview.get("accepted"), "preview_reason": preview.get("reason", ""), "actor_error": actor.get("last_error"), "dormant": state.get("dormant"), "phase": state.get("phase"), "cycle": state.get("cycle"), "distance": actor.global_position.distance_to(game.player.global_position), "hero": Codec.vector3(game.player.global_position), "source": Codec.vector3(actor.global_position)}


func _expect(ok: bool, label: String) -> bool:
	checks += 1
	var row: Dictionary = {"check": checks, "ok": ok, "label": label}
	rows.append(row)
	if not ok:
		failures += 1
		if first_failure.is_empty(): first_failure = row.duplicate(true)
		print("FAIL Court arrangement: " + label)
	return ok


func _source_observation() -> Dictionary:
	var result: Dictionary = {}
	for path: String in [get_script().resource_path, "res://scripts/acts/act1/selenite_court.gd", "res://scripts/acts/act1/selenite_court_layout.gd", "res://scripts/acts/act1/selenite_court_codec.gd", "res://tests/acts/act1/a1_l4_whole_save.gd", "res://scripts/combat/encounter_arrangement.gd", LEGACY_PACKETS]:
		result[path] = FileAccess.get_sha256(path)
	return result


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true
	if not candidate.is_empty() and is_instance_valid(game): game._dispose(candidate); candidate = {}
	if is_instance_valid(fresh):
		if is_instance_valid(fresh.fx): fresh.fx.clear()
		fresh.free(); fresh = null
	var refs: Array[WeakRef] = []
	if is_instance_valid(game):
		refs = _descendant_refs(game)
		if is_instance_valid(game.fx): game.fx.clear()
		game.free(); game = null
	paused = false
	await create_timer(0.5, true).timeout; await process_frame
	_expect(_all_freed(refs) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal actual court/source/cue cleanup")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == registry_text, "production registry unchanged")
	var dir := DirAccess.open(test_root)
	if dir != null:
		for name: String in dir.get_files(): DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	if physics_frame.is_connected(_observe_admissions): physics_frame.disconnect(_observe_admissions)
	var report: Dictionary = {"checks": checks, "failures": failures, "rows": rows, "first_failure": first_failure, "complete": complete, "success": complete and failures == 0, "profile": selected_profile, "wall_ms": Time.get_ticks_msec() - started_ms, "source_before": _source_before, "source_after": _source_observation(), "admissions": _admissions, "admission_diagnostics": _admission_diagnostics, "exact_pair": Exact.stringify(_pair), "receipts": receipts, "setups": setups, "scope": "Focused authored eligibility/whole active Save/fresh disk Continue/preference retention/earlier Retry/cleanup. Public TEST predecessors/injuries/placement; no earned route, optical, all-kit/balance/performance or newly executed historical producer credit. Legacy mode reuses actual original373 packets with explicit TEST session metadata."}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null: print("Court arrangement report write failed"); quit(2); return
	file.store_string(JSON.stringify(report, "\t") + "\n"); file.close()
	print("CINDER_COURT_ARRANGEMENT_REPORT path=" + report_path + " sha256=" + FileAccess.get_sha256(report_path))
	print("Court arrangement: %d checks/%d failures; complete=%s; profile=%s" % [checks, failures, str(complete), selected_profile])
	quit(0 if complete and failures == 0 else 1)
