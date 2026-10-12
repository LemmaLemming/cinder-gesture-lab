extends "res://tests/act1_l2_registration_smoke.gd"
## Focused receipt/transport leaf; actual execution scope is recorded separately.
## Actual production Shell fresh constructors select the profile at entry.
## Only the A1-L1 completion prefix is TEST setup. No local source, clock,
## phase, lease, HP or position is manufactured. Legacy controls remove only
## the new optional receipt from otherwise actual pristine native units.
## No movement/finale admission/visual/balance/full-route claim in this leaf.

const ORIGINAL_ORDER: String = "crater-original-1"
const REVERSED_ORDER: String = "crater-finale-reversed-1"
const INITIAL_CASES: Array[Dictionary] = [
	{"profile": "standard", "kit": "starter", "gear": {"jacket": "CLOTH-J0", "pants": "CLOTH-P0", "shoes": "CLOTH-S0", "weapon": "WEAPON-01"}},
	{"profile": "challenge", "kit": "starter", "gear": {"jacket": "CLOTH-J0", "pants": "CLOTH-P0", "shoes": "CLOTH-S0", "weapon": "WEAPON-01"}},
	{"profile": "challenge", "kit": "slow-long-short", "gear": {"jacket": "CLOTH-J1", "pants": "CLOTH-P2", "shoes": "CLOTH-S2", "weapon": "WEAPON-03"}},
]
var _initial_signatures: Dictionary = {}
var _initial_records: Array[Dictionary] = []
var _option_error: String = ""


func _initialize() -> void:
	var identity: String = "%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_test_root = "user://test-act1-l2-challenge-%s/" % identity
	_capture_root = "user://test-act1-l2-challenge-captures-%s/" % identity
	for argument: String in OS.get_cmdline_user_args():
		_option_error = "Unsupported selector: " + argument
	node_added.connect(_observe_restore_node)
	create_timer(75.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "bounded focused entry transport completes within75wall seconds")
			quit(1))
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if not _expect(_option_error.is_empty(), "entry leaf has no inherited route/fatal/portrait selectors: " + _option_error): _finish(); return
	_registry_text = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var registry := Registry.new()
	if not _expect(registry.last_error.is_empty() and registry.is_playable("A1-L2") and registry.entry("A1-L2").scene_path == LEVEL_PATH, "canonical accepted A1-L2 scene supplies the actual production constructor"): _finish(); return
	for specification: Dictionary in INITIAL_CASES:
		_cleanup_saves()
		if not await _initial_case(registry, specification): _finish(); return
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_text, "native transport fixture does not rewrite registry/content authority")
	_expect(get_nodes_in_group("required_cues").is_empty() and get_nodes_in_group("enemies").is_empty(), "every retired recipient releases native cue/enemy groups")
	print("ACTUAL CHALLENGE ENTRY RECEIPTS ", Exact.stringify(_initial_records))
	_finish()


func _initial_case(registry: CinderCampaignRegistry, specification: Dictionary) -> bool:
	var profile: String = specification.profile
	var kit: String = specification.kit
	var fresh: Dictionary = await _seed_fresh_profile(registry, profile, specification.gear)
	if fresh.is_empty(): return false
	var fresh_wire: String = Exact.stringify(fresh)
	if not _expect(not fresh_wire.is_empty(), profile + "/" + kit + " native aggregate has nonempty exact transport"): return false
	if not await _fresh_continue(fresh_wire, profile + "/" + kit + " new receipt entry"): return false
	if not _check_initial_receipt(fresh, profile): return false
	if not _expect(_disk_state_matches() and game.player.equipment.snapshot() == specification.gear and game.player.hp == game.player.max_hp and game.player.get_world_action_records().is_empty(), "fresh GUI Continue retains actual initial resources/four-slot gear and no executed action"): return false
	var signature: Dictionary = _player_and_configuration_signature(fresh)
	if not _expect(not Exact.stringify(signature).is_empty(), "actual shared Player/body/immutable mechanism signature is closed and nonempty"): return false
	if kit == "starter" and profile == "standard": _initial_signatures[kit] = signature.duplicate(true)
	elif kit == "starter":
		if not _expect(Exact.stringify(signature) == Exact.stringify(_initial_signatures[kit]), "Standard/Challenge starter differ only in saved profile/order, preserving actual Player stats/body and immutable source/impact configurations"): return false
	var opposite: String = "standard" if profile == "challenge" else "challenge"
	if not _change_preference(opposite, fresh_wire): return false
	if not _reject_bad_receipts(fresh): return false
	var retired: Array[Dictionary] = _old_refs()
	_close_shell()
	_expect_refs_freed(retired, "new recipe donor closure")
	if not await _fresh_continue(fresh_wire, "saved " + profile + " despite opposite current preference"): return false
	if not _expect(game.get_difficulty_preference() == opposite and _check_initial_receipt(game.capture_campaign_snapshot(), profile), "saved-only recipe restores against a recipient constructed with the opposite current preference"): return false
	retired = _old_refs()
	if not await _quiet_retry(fresh_wire, "new receipt entry checkpoint"): return false
	_expect_refs_freed(retired, "new recipe GUI Retry")
	if not _expect(_disk_state_matches() and game.player.equipment.snapshot() == specification.gear, "Retry retains exact actual new receipt/four-slot kit on disk"): return false
	# Supported historical format: only the added receipt is absent. This is a
	# TEST compatibility packet; old Challenge means original A then B.
	var legacy: Dictionary = fresh.duplicate(true)
	legacy.level.local.erase("arrangement")
	var legacy_wire: String = Exact.stringify(legacy)
	if not _expect(not legacy_wire.is_empty() and game.active_level.snapshot_error_with_player(legacy.level, legacy.player).is_empty(), "missing receipt is accepted as old original order, including saved " + profile): return false
	var before_player: String = Exact.stringify(game.player.snapshot_state())
	_restore_events.clear(); _watching_restore = true
	var restored: bool = game.active_level.restore_state(legacy.level)
	_watching_restore = false
	if not _expect(restored and _restore_events.is_empty() and Exact.stringify(game.player.snapshot_state()) == before_player and Exact.stringify(game.capture_campaign_snapshot()) == legacy_wire, "legacy quiet commit preserves omission, Player and every saved native clock without replaying gameplay deliveries"): return false
	if not _expect(game.attempts.record_snapshot(legacy, true) and _disk_state_matches(), "actual checked SaveStore persists the accepted legacy-format checkpoint without adding a receipt"): return false
	retired = _old_refs(); _close_shell(); _expect_refs_freed(retired, "legacy donor closure")
	if not await _fresh_continue(legacy_wire, "legacy missing receipt " + profile): return false
	if not _expect(not game.capture_campaign_snapshot().level.local.has("arrangement") and game.capture_campaign_snapshot().level.local.scheduler.profile.id == profile and game.get_difficulty_preference() == opposite, "fresh legacy reader uses saved profile and recaptures the historical missing key"): return false
	retired = _old_refs()
	if not await _quiet_retry(legacy_wire, "legacy omission checkpoint"): return false
	_expect_refs_freed(retired, "legacy GUI Retry")
	if not _expect(_disk_state_matches() and not game.capture_campaign_snapshot().level.local.has("arrangement"), "legacy Retry retains exact omission rather than migrating an old Challenge encounter"): return false
	_initial_records.append({"profile": profile, "kit": kit, "new_arrangement": fresh.level.local.arrangement.duplicate(true), "legacy_writer_omits": not game.capture_campaign_snapshot().level.local.has("arrangement"), "legacy_profile": game.capture_campaign_snapshot().level.local.scheduler.profile.id, "resources": game.player.snapshot_state().resources, "action_count": game.player.get_world_action_records().size()})
	retired = _old_refs(); _close_shell(); _expect_refs_freed(retired, "completed focused case cleanup")
	return true


func _seed_fresh_profile(registry: CinderCampaignRegistry, profile: String, gear: Dictionary) -> Dictionary:
	game = _new_shell()
	await _settle()
	if not _title_valid("fresh native Challenge constructor"): return {}
	game.menu.difficulty_preference_requested.emit(profile)
	if not _expect(game.get_difficulty_preference() == profile and game.campaign_error.is_empty(), "real public preference selects only the next actual fresh boundary"): return {}
	# Same native constructor/capture used by production begin/next/side. We do
	# not install a fake level, override registry, or edit saved local recipes.
	var candidate: Dictionary = game.call("_prepare", "A1-L2", gear)
	if not _expect(not candidate.is_empty(), "actual fresh A1-L2 native constructor: " + game.campaign_error): return {}
	var actor: CinderPlayer = candidate.player
	var level: CinderLevel = candidate.level
	var unit: Dictionary = game.call("_capture_fresh_candidate", candidate, game.call("_fresh_shell_state"))
	var refs: Array[Dictionary] = [{"label": "fresh source Player", "ref": weakref(actor)}, {"label": "fresh source Level", "ref": weakref(level)}]
	_collect_refs(level, refs)
	var accepted: bool = not unit.is_empty() and actor.snapshot_error(unit.get("player", {})).is_empty() and level.snapshot_error_with_player(unit.get("level", {}), unit.get("player", {})).is_empty()
	accepted = _expect(accepted and _initial_local(unit.get("level", {})) and _check_initial_receipt(unit, profile), "genuine entry boundary selects closed recipe before any native attack/clock/action: " + game.campaign_error)
	if accepted:
		var seed: Dictionary = game.attempts.state()
		seed.completed_main = FIXTURE_PREFIX.duplicate()
		seed.story = {"kind": "story", "level_id": "A1-L2", "snapshot": unit.duplicate(true), "checkpoint": unit.duplicate(true)}
		var store: CinderSaveStore = Store.new(_test_root + "campaign.json")
		accepted = _expect(game.attempts.state_error(seed).is_empty() and game.attempts.restore_session(seed) and store.write_payload(game.attempts.state()), "TEST ONLY predecessor prefix writes the untouched actual fresh source recipe through Attempts/SaveStore: " + game.attempts.last_error + "; " + store.last_error)
	game.call("_dispose", candidate)
	_close_shell()
	_expect_refs_freed(refs, "fresh test seed disposal")
	return unit if accepted else {}


func _check_initial_receipt(unit: Dictionary, profile: String) -> bool:
	if unit.is_empty() or not unit.get("level") is Dictionary: return _expect(false, "complete actual entry required")
	var local: Dictionary = unit.level.get("local", {})
	var id: String = REVERSED_ORDER if profile == "challenge" else ORIGINAL_ORDER
	return _expect(local.get("arrangement") == {"version": 1, "id": id} and local.get("scheduler", {}).get("profile", {}).get("id") == profile and local.get("scheduler", {}).get("clock_s") == 0.0 and unit.player.world_actions.clock_s == 0.0 and _initial_local(unit.level), "actual pristine " + profile + " receipt joins its saved encounter profile, dormant actor/impact set and zero clocks")


func _change_preference(profile: String, expected_wire: String) -> bool:
	game.menu.difficulty_preference_requested.emit(profile)
	return _expect(paused and game.get_difficulty_preference() == profile and game.campaign_error.is_empty() and Exact.stringify(game.capture_campaign_snapshot()) == expected_wire and _disk_state_matches(), "current preference changes atomically without retuning or rewriting an already saved native recipe")


func _reject_bad_receipts(unit: Dictionary) -> bool:
	for mutation: String in ["unknown-id", "wrong-profile", "float-version", "future-version", "extra-key", "missing-id", "array", "native-stringname"]:
		var bad: Dictionary = unit.duplicate(true)
		match mutation:
			"unknown-id": bad.level.local.arrangement.id = "crater-other-1"
			"wrong-profile": bad.level.local.arrangement.id = ORIGINAL_ORDER if unit.level.local.arrangement.id == REVERSED_ORDER else REVERSED_ORDER
			"float-version": bad.level.local.arrangement.version = 1.0
			"future-version": bad.level.local.arrangement.version = 2
			"extra-key": bad.level.local.arrangement["order"] = ["finale-impact-b", "finale-impact-a"]
			"missing-id": bad.level.local.arrangement.erase("id")
			"array": bad.level.local.arrangement = []
			"native-stringname": bad.level.local.arrangement.id = StringName(bad.level.local.arrangement.id)
		var before: String = Exact.stringify(game.capture_campaign_snapshot())
		var model_before: String = Exact.stringify(game.attempts.state())
		var disk_before: String = FileAccess.get_file_as_string(_test_root + "campaign.json")
		_restore_events.clear(); _watching_restore = true
		var reason: String = game.active_level.snapshot_error_with_player(bad.level, bad.player)
		var refused: bool = not game.active_level.restore_state(bad.level)
		_watching_restore = false
		if not _expect(not before.is_empty() and not reason.is_empty() and refused and _restore_events.is_empty() and Exact.stringify(game.capture_campaign_snapshot()) == before and Exact.stringify(game.attempts.state()) == model_before and FileAccess.get_file_as_string(_test_root + "campaign.json") == disk_before, mutation + " pure/full local reader refuses before Player/actor/clock/model/disk mutation: " + reason): return false
	return true


func _player_and_configuration_signature(unit: Dictionary) -> Dictionary:
	var collision: CollisionShape3D = game.player.get_node("BodyCollision") as CollisionShape3D
	var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D
	var immutable_circles: Dictionary = {}
	for id: String in CIRCLE_IDS:
		immutable_circles[id] = unit.level.local.circles[id].configuration.duplicate(true)
	return {"player_script": game.player.get_script().resource_path, "presentation": game.player.presentation_id, "gear": game.player.equipment.snapshot(), "stats": game.player.equipment.resolved_stats(), "capsule": {"radius": capsule.radius, "height": capsule.height, "position": Codec.vector3(collision.position), "layer": game.player.collision_layer, "mask": game.player.collision_mask}, "circle_configurations": immutable_circles}


func _finish() -> void:
	if _finished: return
	_finished = true
	_close_shell()
	paused = false
	_cleanup_saves()
	print("Act1 L2 Challenge entry/transport: %d checks, %d failures; source=%s; TEST ONLY predecessor prefix; no movement/finale/visual/balance/full-route claim" % [checks, failures, RUNTIME_PATH])
	quit(0 if failures == 0 else 1)
