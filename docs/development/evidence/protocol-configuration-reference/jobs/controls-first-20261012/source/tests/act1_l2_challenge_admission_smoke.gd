extends "res://tests/act1_l2_challenge_smoke.gd"
## Focused native component test; actual execution scope is recorded separately.
## TEST ONLY Hero floor approaches and zero shells before two ordinary taps.
## Actual Main alone resolves landing, activates/defeats solo and open, enters
## camp, selects the next fresh profile and admits the finale/first companion.
## No source/beat/lease/phase/sample/clock/progress assignment; no finale defeat,
## exit, full route, all kits, balance, native focus or portrait claim.

const Layout = preload("res://scripts/acts/act1/crater_gardens_layout.gd")
var _native_admissions: Array[Dictionary] = []
var _placements: Array[Dictionary] = []
var _zero_ammo_taps: Array[Dictionary] = []
var _first_finale_id: String = ""
var _pause_accepted: bool = false
var _component_results: Array[Dictionary] = []


func _initialize() -> void:
	var identity: String = "%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_test_root = "user://test-act1-l2-challenge-admission-%s/" % identity
	_capture_root = "user://test-act1-l2-challenge-admission-captures-%s/" % identity
	for argument: String in OS.get_cmdline_user_args(): _option_error = "Unsupported selector: " + argument
	node_added.connect(_observe_restore_node)
	create_timer(150.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "focused native admission test finishes within150wall seconds")
			quit(1))
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if not _expect(_option_error.is_empty(), "component test has no inherited route/portrait/fatal selectors: " + _option_error): _finish(); return
	_registry_text = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var registry := Registry.new()
	if not _expect(registry.last_error.is_empty() and registry.is_playable("A1-L2") and registry.entry("A1-L2").scene_path == LEVEL_PATH, "same production A1-L2 registry supplies real component geometry"): _finish(); return
	for specification: Dictionary in INITIAL_CASES:
		_cleanup_saves()
		if not await _component_case(registry, specification): _finish(); return
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_text and get_nodes_in_group("required_cues").is_empty() and get_nodes_in_group("enemies").is_empty(), "component cleanup leaves canonical registry and native groups unchanged")
	print("ACTUAL CHALLENGE COMPONENT RESULTS ", Exact.stringify(_component_results))
	_finish()


func _component_case(registry: CinderCampaignRegistry, specification: Dictionary) -> bool:
	var profile: String = specification.profile
	var fresh: Dictionary = await _seed_fresh_profile(registry, profile, specification.gear)
	if fresh.is_empty() or not await _fresh_continue(Exact.stringify(fresh), "focused component initial " + profile): return false
	_native_admissions.clear(); _placements.clear(); _zero_ammo_taps.clear()
	_first_finale_id = ""; _pause_accepted = false
	game.active_level.connect("native_admission_published", _observe_native_admission)
	var player_signature: String = Exact.stringify(_player_and_configuration_signature(fresh))
	if not _resume_consumed("native landing start"): return false
	var landing: CinderLaneMechanism = (game.active_level.get("circles") as Dictionary)["landing-impact"]
	if not await _wait_native(func() -> bool: return landing.state().status == "running", "actual admitted landing warning", 450): return false
	var landing_answer: Dictionary = game.active_level.get("last_circle_admission")
	if not _expect(landing_answer.get("accepted", false) and landing_answer.proof.uses_blast == false and landing_answer.proof.uses_invulnerability == false, "real landing uses native ordinary escape proof, independent of ammo"): return false
	var landing_pose: Vector3 = landing_answer.proof.landing
	if not await _stage_floor_approach(Vector3(landing_pose.x, 0.005, landing_pose.z), "TEST landing escape side"): return false
	if not await _wait_native(func() -> bool: return int(game.active_level.get("beat_index")) == 1, "actual landing danger resolves and publishes its native first checkpoint", 500): return false
	var solo: Act1RushSelenite = (game.active_level.get("sources") as Dictionary)["solo"]
	if not await _stage_floor_approach(Layout.SOLO_SOURCE + Vector3.BACK, "TEST solo primary approach"): return false
	if not await _wait_native(func() -> bool: return not solo.dormant, "native solo activation at its genuine fresh boundary", 180) or not await _ordinary_zero_ammo_primary(solo, "solo"): return false
	if not await _wait_native(func() -> bool: return solo.dead and int(game.active_level.get("beat_index")) == 2, "one native primary defeat establishes the real fork checkpoint", 240): return false
	var open: Act1RushSelenite = (game.active_level.get("sources") as Dictionary)["open"]
	if not await _stage_floor_approach(Layout.OPEN_SOURCE + Vector3.BACK, "TEST open fork/primary approach"): return false
	if not await _wait_native(func() -> bool: return game.active_level.get("chosen_route") == "open" and not open.dormant, "native open-side choice establishes its real fresh activation", 180) or not await _ordinary_zero_ammo_primary(open, "open"): return false
	if not await _wait_native(func() -> bool: return open.dead and int(game.active_level.get("beat_index")) == 3, "second native primary defeat establishes the camp beat", 240): return false
	if not await _stage_floor_approach(Vector3(Layout.CAMP_CENTRE.x, 0.005, Layout.CAMP_CENTRE.z), "TEST actual camp contact"): return false
	if not await _wait_native(func() -> bool: return int(game.active_level.get("beat_index")) == 4, "actual native camp contact earns the finale checkpoint", 180): return false
	if not await _pause_component("camp native checkpoint"): return false
	var checkpoint: Dictionary = game.attempts.state().story.checkpoint
	if not _expect(not checkpoint.is_empty() and checkpoint.level.local.beat_index == 4 and checkpoint.level.local.sources.finale.dormant and checkpoint.level.local.sources.solo.dead and checkpoint.level.local.sources.open.dead and checkpoint.level.progress.checkpoint_id == "celestial-camp" and _valid_pair(checkpoint), "protected Retry is the actual earlier camp unit with two real defeats and dormant finale"): return false
	var checkpoint_wire: String = Exact.stringify(checkpoint)
	if not await _stage_floor_approach(Layout.FINAL_SOURCE + Vector3.BACK * 3.0, "TEST finale activation approach"): return false
	if not await _wait_native(func() -> bool: return not _first_finale_id.is_empty() and paused and game.menu.page_name() == "pause", "native finale first companion reaches the supported whole paused save barrier", 700, true): return false
	await _settle()
	var saved: Dictionary = game.capture_campaign_snapshot()
	var first: String = "finale-impact-b" if profile == "challenge" else "finale-impact-a"
	var second: String = "finale-impact-a" if profile == "challenge" else "finale-impact-b"
	if not _expect(_pause_accepted and _first_finale_id == first and not saved.is_empty() and _valid_pair(saved) and game.campaign_error.is_empty(), "observable native " + profile + " order starts " + first + " with coherent full union: " + game.campaign_error): return false
	var local: Dictionary = saved.level.local
	if not _expect(local.arrangement == {"version": 1, "id": REVERSED_ORDER if profile == "challenge" else ORIGINAL_ORDER} and local.scheduler.profile.id == profile and local.sequence.next_index == 1 and local.circles[first].status == "running" and local.circles[second].cycle == 0 and local.custody[first].supported and local.sequence.host_reservation_id == local.sources.finale.reservation_id and local.sources.finale.hp == 20.0 and not local.sources.finale.dead, "actual first-prefix and unchanged living finale HP are admitted, rather than fabricated cursors or source damage"): return false
	var lease_ids: Array[String] = []
	for record: Dictionary in local.scheduler.reservations: lease_ids.append(record.source_id)
	if not _expect(lease_ids.size() == 2 and lease_ids.has("finale") and lease_ids.has(first) and game.camera_framing_error(game.active_level.camera_framing_points()).is_empty(), "native scheduled host+circle union and current source/cue/landing framing are valid together"): return false
	if not _expect(Exact.stringify(_player_and_configuration_signature(saved)) == player_signature and _zero_ammo_taps.size() == 2 and game.player.get_world_action_records().size() == 2 and game.player.get_world_action_records()[0].kind == "primary" and game.player.get_world_action_records()[1].kind == "primary" and not game.active_level.is_completed() and game.attempts.state().completed_main == FIXTURE_PREFIX, "component keeps shared Player/capsule/gear/geometry intact and uses two real ordinary primaries, no blast or fabricated level clear"): return false
	if not _reject_prefix_packets(saved): return false
	var wire: String = Exact.stringify(saved)
	if not _expect(not wire.is_empty() and Exact.stringify(game.attempts.active_snapshot()) == wire and _disk_state_matches(), "actual deferred admission pause commits the exact full native prefix to checked format2"): return false
	if not await _inspect_first_prefix(saved): return false
	var opposite: String = "standard" if profile == "challenge" else "challenge"
	if not _change_preference(opposite, wire): return false
	var retired: Array[Dictionary] = _old_refs(); _close_shell(); _expect_refs_freed(retired, "native first-prefix donor")
	if not await _fresh_continue(wire, "actual admitted " + first + " despite opposite preference"): return false
	if profile == "standard":
		if not await _active_legacy_roundtrip(saved): return false
	else:
		var stripped: Dictionary = saved.duplicate(true); stripped.level.local.erase("arrangement")
		if not _reject_packet_atomic(stripped, "missing key cannot reinterpret a genuine B-first active Challenge prefix as historical A-first"): return false
	# Real cancellation, not a manufactured inactive source/sample. It preserves
	# HP and cooldown while the parent retires companions and its active cursor.
	var finale: Act1RushSelenite = (game.active_level.get("sources") as Dictionary)["finale"]
	var hp_before: float = finale.hp
	if not _expect(finale.cancel("test_native_order_history") and finale.hp == hp_before, "actual host cancellation clears danger without source HP edits"): return false
	var inactive: Dictionary = game.capture_campaign_snapshot()
	if not _expect(not inactive.is_empty() and _valid_pair(inactive) and inactive.level.local.sequence.is_empty() and inactive.level.local.sources.finale.reservation_id.is_empty() and inactive.level.local.circles[first].status == "cancelled" and inactive.level.local.custody[first].supported, "genuine cancelled first-impact history survives the cleared live cursor"): return false
	if profile == "challenge":
		var bad_history: Dictionary = inactive.duplicate(true); bad_history.level.local.erase("arrangement")
		if not _reject_packet_atomic(bad_history, "inactive retained B-first history still rejects an invented legacy A-first recipe"): return false
	retired = _old_refs()
	if not await _quiet_retry(checkpoint_wire, "genuine earlier camp checkpoint"): return false
	_expect_refs_freed(retired, "native finale-prefix GUI Retry")
	if not _expect(_disk_state_matches() and game.capture_campaign_snapshot().level.local.sources.finale.dormant and game.capture_campaign_snapshot().player.resources == checkpoint.player.resources, "actual earlier Retry preserves original camp HP/ammo/gear/actions without refresh or replay"): return false
	_component_results.append({"profile": profile, "kit": specification.kit, "first_native_companion": first, "placements": _placements.duplicate(true), "zero_ammo_primary_controls": _zero_ammo_taps.duplicate(true), "admissions": _native_admissions.duplicate(true), "prefix_clock_s": local.scheduler.clock_s, "active_legacy_scope": "actual Standard A-first only" if profile == "standard" else "Challenge B-first stripped-key refusal", "inactive_history_checked": profile == "challenge", "retry_checkpoint": "celestial-camp", "finale_defeated": false})
	retired = _old_refs(); _close_shell(); _expect_refs_freed(retired, "component case recipient cleanup")
	return true


func _inspect_first_prefix(_saved: Dictionary) -> bool:
	# Optional TEST portrait hook after the exact paused native-prefix checks.
	return true


func _observe_native_admission(id: String, answer: Dictionary) -> void:
	if not answer.get("accepted", false): return
	var proof: Dictionary = answer.get("proof", {})
	_native_admissions.append({"source_id": id, "reservation_id": String(answer.get("reservation_id", "")), "uses_blast": proof.get("uses_blast"), "uses_invulnerability": proof.get("uses_invulnerability"), "landing": Codec.vector3(proof.landing), "attack_position": Codec.vector3(proof.attack_position), "primary_time_s": proof.get("primary_time_s"), "response_complete_s": proof.get("response_complete_s")})
	if id.begins_with("finale-impact-") and _first_finale_id.is_empty():
		_first_finale_id = id
		_pause_accepted = game.request_pause_deferred()


func _pause_component(label: String) -> bool:
	game.request_pause()
	await _settle()
	return _expect(paused and game.menu.page_name() == "pause" and game.campaign_error.is_empty(), label + " reaches actual paused whole-aggregate barrier: " + game.campaign_error)


func _stage_floor_approach(position: Vector3, label: String) -> bool:
	if not await _pause_component(label): return false
	var actor: CinderPlayer = game.player
	var before: Vector3 = actor.global_position
	actor.global_position = position
	actor.velocity = Vector3.ZERO
	_placements.append({"label": label, "from": Codec.vector3(before), "to": Codec.vector3(position), "scope": "TEST floor approach; next real physics produces native samples"})
	return _resume_consumed(label)


func _ordinary_zero_ammo_primary(target: Act1RushSelenite, label: String) -> bool:
	if not await _wait_native(func() -> bool: return game.player.get_threat_response_state().stable and float(game.player.get_threat_response_state().primary_cooldown_left_s) == 0.0, label + " actual primary readiness", 180): return false
	var offset: Vector3 = target.global_position - game.player.global_position
	offset.y = 0.0
	var direction: Vector3 = offset.normalized()
	var right: Vector3 = game.camera.global_basis.x; right.y = 0.0; right = right.normalized()
	var down: Vector3 = game.camera.global_basis.z; down.y = 0.0; down = down.normalized()
	var determinant: float = right.x * down.z - right.z * down.x
	if not _expect(absf(determinant) > 0.001 and offset.length() > 0.64 and offset.length() <= float(game.player.equipment.resolved_stats().primary_range) and target.is_in_group("enemies"), label + " reaches the actual living body on native clear floor with this kit"): return false
	var delta: Vector2 = Vector2((direction.x * down.z - direction.z * down.x) / determinant, (right.x * direction.z - right.z * direction.x) / determinant).normalized()
	var anchor: Vector2 = game.get_aim_anchor()
	var tap: Vector2 = anchor + delta * 150.0
	if not _expect(game.hud.combat_safe_rect().has_point(tap / root.get_visible_rect().size) and game.aim_direction(tap).dot(direction) > 0.9999, label + " first tap uses current HUD-safe native camera direction/release anchor"): return false
	var sequence: int = game.player.get_world_action_records().size()
	var input_before: int = int(game.get_input_observation_state().sequence)
	var hp_before: float = target.hp
	var clock: float = game.player.get_world_action_clock()
	# Explicit TEST resource control, like the existing focused route fixture.
	# No physics yield/reload-clock refresh between zeroing and native first tap.
	game.player.shells = 0
	var press := InputEventScreenTouch.new(); press.index = 7; press.position = tap; press.pressed = true
	root.push_input(press, true)
	var release := press.duplicate() as InputEventScreenTouch; release.pressed = false
	root.push_input(release, true)
	var actions: Array[Dictionary] = game.player.get_world_action_records()
	var observation: Dictionary = game.get_input_observation_state().last_observation
	if not _expect(actions.size() == sequence + 1 and actions.back().kind == "primary" and actions.back().origin == "player_direct" and actions.back().hits == 1 and actions.back().completed_at_s == clock and game.player.shells == 0 and target.hp < hp_before and target.dead and game.get_aim_anchor() == anchor and int(game.get_input_observation_state().sequence) == input_before + 1 and observation.kind == "primary_tap" and observation.accepted, label + " one genuine immediate zero-ammo primary defeats its actual20HP body without blast or fake damage"): return false
	_zero_ammo_taps.append({"source_id": label, "hp_before": hp_before, "hp_after": target.hp, "shells_before": 0, "shells_after": game.player.shells, "kind": actions.back().kind, "hits": actions.back().hits, "clock_s": clock, "input_sequence": input_before + 1})
	return true


func _wait_native(predicate: Callable, label: String, attempts: int, allow_paused: bool = false) -> bool:
	for attempt: int in range(attempts):
		if _finished or not is_instance_valid(game) or not is_instance_valid(game.player): return false
		if predicate.call() == true: return true
		if game.player.dead or not game.campaign_error.is_empty() or (paused and not allow_paused):
			return _expect(false, label + " lost normal live processing: " + game.campaign_error)
		await create_timer(0.01, true).timeout
	print("CHALLENGE COMPONENT WAIT CONTEXT ", label, " ", game.active_level.call("encounter_state"), " camera=", game.get_camera_framing_state(), " response=", game.player.get_threat_response_state())
	return _expect(false, label + " exceeded its bounded actual native observation window")


func _reject_prefix_packets(unit: Dictionary) -> bool:
	for mutation: String in ["cursor-zero", "cursor-two", "foreign-host", "wrong-present-recipe"]:
		var bad: Dictionary = unit.duplicate(true)
		match mutation:
			"cursor-zero": bad.level.local.sequence.next_index = 0
			"cursor-two": bad.level.local.sequence.next_index = 2
			"foreign-host": bad.level.local.sequence.host_reservation_id = "threat-foreign"
			"wrong-present-recipe": bad.level.local.arrangement.id = ORIGINAL_ORDER if unit.level.local.arrangement.id == REVERSED_ORDER else REVERSED_ORDER
		if not _reject_packet_atomic(bad, mutation + " cannot manufacture or reorder the actual admitted prefix"): return false
	return true


func _reject_packet_atomic(bad: Dictionary, label: String) -> bool:
	var before: String = Exact.stringify(game.capture_campaign_snapshot())
	var model_before: String = Exact.stringify(game.attempts.state())
	var disk_before: String = FileAccess.get_file_as_string(_test_root + "campaign.json")
	_restore_events.clear(); _watching_restore = true
	var reason: String = game.active_level.snapshot_error_with_player(bad.level, bad.player)
	var refused: bool = not game.active_level.restore_state(bad.level)
	_watching_restore = false
	return _expect(not before.is_empty() and not reason.is_empty() and refused and _restore_events.is_empty() and Exact.stringify(game.capture_campaign_snapshot()) == before and Exact.stringify(game.attempts.state()) == model_before and FileAccess.get_file_as_string(_test_root + "campaign.json") == disk_before, label + " refuses purely/atomically before altering native unit/model/disk: " + reason)


func _active_legacy_roundtrip(unit: Dictionary) -> bool:
	var legacy: Dictionary = unit.duplicate(true); legacy.level.local.erase("arrangement")
	var wire: String = Exact.stringify(legacy)
	if not _expect(not wire.is_empty() and game.active_level.snapshot_error_with_player(legacy.level, legacy.player).is_empty(), "actual A-first active Standard prefix remains readable as legacy omission"): return false
	_restore_events.clear(); _watching_restore = true
	var restored: bool = game.active_level.restore_state(legacy.level)
	_watching_restore = false
	if not _expect(restored and _restore_events.is_empty() and Exact.stringify(game.capture_campaign_snapshot()) == wire and game.attempts.record_snapshot(legacy, false) and _disk_state_matches(), "quiet actual active legacy unit recaptures omission and saves without rewriting resources/clocks"): return false
	var retired: Array[Dictionary] = _old_refs(); _close_shell(); _expect_refs_freed(retired, "active legacy donor")
	return await _fresh_continue(wire, "actual active A-first missing key against Challenge preference")


func _finish() -> void:
	if _finished: return
	_finished = true
	_close_shell(); paused = false; _cleanup_saves()
	print("Act1 L2 Challenge native component: %d checks, %d failures; TEST Hero approaches/zeroammo; actual landing+2primaries+camp+first finale admission; no exit/full-route/finale-defeat/portrait/balance claim" % [checks, failures])
	quit(0 if failures == 0 else 1)
