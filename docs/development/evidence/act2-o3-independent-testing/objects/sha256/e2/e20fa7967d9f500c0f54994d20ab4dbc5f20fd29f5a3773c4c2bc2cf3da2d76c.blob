extends "res://tests/acts/act2/a2_l3_retry_level_smoke.gd"
## Focused GUI lifecycle from an immutable checkpoint earned by the real route.
## The original complete Attempts payload is validated and written untouched.
## No initial/phase HP, motion, gear, progression, clocks or checkpoint is seeded.
## Earlier campaign prefix/registry acceptance/L4 destination remain TEST ONLY.
## First-checkpoint375 covers genuine death; this tests exact B02 clock rollback.

const BOSS_TEST_ROOT: String = "user://test-a2-l3-earned-boss-checkpoint/"
const BOSS_CHECKPOINT_ID: String = "handling-machine-phase-two"
const BOSS_RUNTIME_SOURCES: Array[String] = [
	"scripts/acts/act2/ruined_house.gd", "scripts/acts/act2/ruined_house_smoke_rules.gd",
	"scripts/acts/act2/ruined_house_bank_guard.gd", "scripts/acts/act2/handling_machine_boss_actor.gd",
	"scripts/combat/smoke_bank.gd", "scripts/combat/threat_scheduler.gd",
	"scripts/player.gd", "scripts/campaign/shell.gd",
]
var _bc_source_path: String = ""
var _bc_source_sha256: String = ""
var _bc_original: Dictionary = {}
var _bc_pristine_ray_retirements: Array[Dictionary] = []
var _bc_old_level: WeakRef
var _bc_old_snapshot: Dictionary = {}
var _bc_old_retirement_expected: Dictionary = {}
var _bc_old_retirement_seen: Dictionary = {}
var _bc_old_retirement_events: Array[Dictionary] = []

func _run() -> void:
	if not _bc_read_source(): quit(1); return
	_loadout_name = _bc_original.loadout
	_profile_id = _bc_original.profile
	if not _read_options() or not _expect(_loadout_name == _bc_original.loadout and _profile_id == _bc_original.profile and not _capture_live and not _road_only, "fixture selectors match the untouched earned source and request no art/full route"):
		quit(1); return
	root.size = Vector2i(540, 1170)
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	_l2_fixture_bytes = FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l2_transition_destination.tscn")
	_bc_cleanup()
	_native_probe = NativeTickProbe.new()
	root.add_child(_native_probe)
	_lc_auto_resume = false
	node_added.connect(_bc_observe_added)
	print("Earned B02 source: ", _bc_source_path, " SHA256=", _bc_source_sha256)
	var failures_before: int = _failures
	if not await _bc_restore_route() and _failures == failures_before: _expect(false, "earned B02 GUI lifecycle aborted")
	await process_frame
	_lc_watching_restore = false
	if is_instance_valid(_game): _release_fixture_shell(_game)
	_game = null
	if is_instance_valid(_native_probe): _native_probe.free()
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical and FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l2_transition_destination.tscn") == _l2_fixture_bytes and FileAccess.get_sha256(_bc_source_path) == _bc_source_sha256, "isolated lifecycle preserves canonical registry/frozen L2/original earned artifact bytes")
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "all restored actor/required-cue units are released")
	_bc_cleanup()
	print("A2-L3 earned B02 checkpoint smoke: %d checks, %d failures; original actual HP15 checkpoint/fresh GUI Continue/eight real ticks/GUI Retry, no route/fatal/extrema claim" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _bc_read_source() -> bool:
	var selectors: Dictionary = {"source": 0, "sha256": 0}
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--checkpoint-source="):
			selectors.source += 1; _bc_source_path = argument.trim_prefix("--checkpoint-source=")
		elif argument.begins_with("--checkpoint-sha256="):
			selectors.sha256 += 1; _bc_source_sha256 = argument.trim_prefix("--checkpoint-sha256=")
	if not _expect(selectors.source == 1 and selectors.sha256 == 1 and _bc_source_path.begins_with("res://") and _bc_valid_hash(_bc_source_sha256), "explicit unique res:// checkpoint source and exact SHA256 are required"): return false
	if not _expect(FileAccess.file_exists(_bc_source_path) and FileAccess.get_sha256(_bc_source_path) == _bc_source_sha256, "original earned artifact matches the supplied immutable byte hash"): return false
	var decoded: Dictionary = LifecycleJson.parse(FileAccess.get_file_as_string(_bc_source_path))
	if not _expect(decoded.get("accepted", false) and decoded.get("value") is Dictionary, "original artifact uses the published ExactJson codec"): return false
	_bc_original = decoded.value
	if not _expect(_bc_original.has_all(["api_revision", "level_id", "loadout", "profile", "source_sha256", "boundary_records", "boss_hits", "checkpoint", "attempts_payload"]) and _bc_original.api_revision == "act2-earned-boss-checkpoint-1" and _bc_original.level_id == "A2-L3" and _bc_original.loadout == "heavy" and _bc_original.profile == "standard" and _bc_original.source_sha256 is Dictionary and _bc_original.boundary_records is Array and _bc_original.boss_hits is Array and _bc_original.checkpoint is Dictionary and _bc_original.attempts_payload is Dictionary, "actual Heavy/Standard earned-checkpoint provenance envelope is complete"): return false
	for path: String in BOSS_RUNTIME_SOURCES:
		var recorded: Variant = _bc_original.source_sha256.get(path)
		if not _expect(recorded is String and _bc_valid_hash(recorded) and FileAccess.get_sha256("res://" + path) == recorded, "consumed gameplay runtime matches the original earned source: " + path): return false
	# Original test-bot hashes remain in the artifact as provenance. They are
	# deliberately not compared to current test-only navigation corrections.
	if not _expect(_bc_original.boundary_records.size() == 1 and _bc_original.boundary_records[0] is Dictionary and not _bc_original.boss_hits.is_empty() and _bc_original.boss_hits[0] is Dictionary, "original real boundary and primary-hit records are retained"): return false
	var boundary: Dictionary = _bc_original.boundary_records[0]
	var hit: Dictionary = _bc_original.boss_hits[0]
	if not _expect(boundary.get("hp") == 15.0 and boundary.get("max_hp") == 30.0 and boundary.get("boss_phase") == 1 and boundary.get("transition_pending") == true and boundary.get("beat") == "boss_phase_one" and hit.get("before") == 30.0 and hit.get("after") == 15.0 and hit.get("phase") == 1 and hit.get("source_id") == "boss_place" and float(hit.get("damage", 0.0)) > 15.0, "actual phase1 overkill record earned the closed HP15 threshold before phase2 commit"): return false
	var payload: Dictionary = _bc_original.attempts_payload
	if not _expect(payload.get("story") is Dictionary and payload.story.get("checkpoint") is Dictionary and payload.story.get("snapshot") is Dictionary and payload.get("side_attempt") == null and LifecycleJson.stringify(payload.story.checkpoint) == LifecycleJson.stringify(_bc_original.checkpoint), "exported checkpoint is exactly the protected unit in the original complete story payload"): return false
	return _bc_checkpoint_criteria(_bc_original.checkpoint)

func _bc_valid_hash(value: String) -> bool:
	if value.length() != 64: return false
	for index: int in range(value.length()):
		if not value.substr(index, 1) in "0123456789abcdef": return false
	return true

func _bc_checkpoint_criteria(checkpoint: Dictionary) -> bool:
	if not _expect(checkpoint.get("level_id") == "A2-L3" and checkpoint.get("scene_path") == HOUSE_SCENE and checkpoint.get("paused") == true and checkpoint.get("player") is Dictionary and checkpoint.get("level") is Dictionary and checkpoint.level.get("local") is Dictionary and checkpoint.level.get("progress") is Dictionary, "earned checkpoint retains its complete original paused Shell/Player/level identity"): return false
	var local: Dictionary = checkpoint.level.local
	if not _expect(local.get("targets") is Dictionary and local.targets.get("handling_machine") is Dictionary and local.targets.handling_machine.get("actor") is Dictionary and local.get("sequence") is Dictionary and checkpoint.player.get("resources") is Dictionary, "original B02/sequence/Player fields are present without reconstructing them"): return false
	var boss: Dictionary = local.targets.handling_machine
	var sequence: Dictionary = local.sequence
	var progress: Dictionary = checkpoint.level.progress
	return _expect(local.size() == 19 and boss.actor.get("hp") == 15.0 and boss.actor.get("max_hp") == 30.0 and boss.get("boss_phase") == 2 and boss.get("transition_pending") == false and local.get("boss_phase_pending") == false and sequence.get("stage_index") == 7 and sequence.get("boss_phase") == 2 and sequence.get("crossed_contacts") == HOUSE_CONTACT_ORDER and sequence.get("defeated_ids") is Array and sequence.defeated_ids.size() == 5 and sequence.defeated_ids.has("road_tender") and sequence.defeated_ids.has("house_tender") and sequence.defeated_ids.has("house_handler") and sequence.defeated_ids.has("apron_scout") and sequence.defeated_ids.has("apron_handler") and progress.get("checkpoint_id") == BOSS_CHECKPOINT_ID and progress.get("checkpoint_kind") == "boss_phase" and progress.get("completed") == false and progress.get("completion_id") == "" and progress.get("contact_exit_id") == "" and checkpoint.player.resources.get("dead") == false, "actual living15HP/stage7 checkpoint retains three earned contacts/five defeats and no completion/exit")

func _bc_restore_route() -> bool:
	_lc_raw = JSON.parse_string(_canonical)
	for info: Dictionary in _lc_raw.levels:
		if info.id in ["A2-L3", "A2-L4"]:
			info.scene_path = HOUSE_SCENE if info.id == "A2-L3" else HOUSE_DESTINATION
			info.readiness = "accepted"
			info.accepted_commit = "b".repeat(40)
			info.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(_lc_raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A2-L4").is_empty(), "known TEST ONLY registry/destination retains the original canonical route"): return false
	var payload: Dictionary = _bc_original.attempts_payload
	var original_encoded: String = LifecycleJson.stringify(payload)
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var store: CinderSaveStore = Store.new(BOSS_TEST_ROOT + "campaign.json")
	store.payload_validator = model.saved_payload_error
	if not _expect(not original_encoded.is_empty() and model.state_error(payload).is_empty() and store.write_payload(payload) and LifecycleJson.stringify(payload) == original_encoded, "public Store validates/writes the untouched complete original Attempts payload; no seed or field replacement"): return false
	_lc_restore_events.clear(); _lc_watching_restore = true
	if not await _lc_new_shell() or not await _lc_click("ContinueStoryButton"): return false
	_lc_watching_restore = false
	var original_current: Dictionary = payload.story.snapshot
	var checkpoint: Dictionary = _bc_original.checkpoint
	if not _bc_unit_exact(original_current, "fresh GUI Continue") or not _expect(_lc_restore_events.is_empty() and paused and _game.menu.page_name() == "resume" and LifecycleJson.stringify(_game.attempts.state()) == original_encoded and LifecycleJson.stringify(_game.attempts.state().story.checkpoint) == LifecycleJson.stringify(checkpoint), "fresh Continue quietly restores exact original story snapshot while preserving its protected B02 checkpoint"): return false
	if not _expect(_bc_pristine_ray_retirements.size() == 2 and _bc_pristine_ray_retirements[0].node_id != _bc_pristine_ray_retirements[1].node_id, "both distinct pristine validation candidates retire separately from the quiet restored epoch"): return false
	if not await _bc_resume_eight_ticks(): return false
	if not _expect(_game.request_pause_deferred(), "public native pause requested after eight real post-root ticks"): return false
	await _lc_settle()
	var advanced: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(paused and not _game.is_pause_requested() and _game.menu.page_name() == "pause" and _game.campaign_error.is_empty() and not advanced.is_empty() and not _game.player.dead and float(advanced.player.world_actions.clock_s) > float(original_current.player.world_actions.clock_s) and float(advanced.level.local.scheduler.clock_s) > float(checkpoint.level.local.scheduler.clock_s), "actual resumed simulation advances clocks before the complete public pause/menu barrier"): return false
	if not _lc_valid_snapshot(advanced) or not _expect(advanced.player.world_actions.sequence == original_current.player.world_actions.sequence and advanced.level.local.sequence == original_current.level.local.sequence and not advanced.level.progress.completed and advanced.level.progress.contact_exit_id.is_empty() and LifecycleJson.stringify(_game.attempts.state().story.checkpoint) == LifecycleJson.stringify(checkpoint), "real no-input ticks invent no action/defeat/contact/completion/exit or checkpoint replacement"): return false
	var retired: Array[Dictionary] = _lc_old_refs()
	_bc_record_old_retirement(advanced)
	if not _expect(not _bc_old_retirement_expected.is_empty(), "the actual advanced old epoch has specifically measured cancel/clear cleanup notifications"): return false
	_lc_restore_events.clear(); _lc_watching_restore = true
	if not await _lc_click("RetryButton"): return false
	_lc_watching_restore = false
	if not _bc_unit_exact(checkpoint, "actual GUI Retry") or not _expect(paused and _game.menu.page_name() == "resume" and _lc_restore_events.is_empty() and float(_game.player.get_world_action_clock()) == float(checkpoint.player.world_actions.clock_s) and float(_game.active_level.get("_scheduler").get_clock()) == float(checkpoint.level.local.scheduler.clock_s), "GUI Retry quietly restores the original exact HP15 checkpoint and rolls back actual advanced clocks"): return false
	_lc_refs_freed(retired, "B02 GUI Retry")
	print("B02 old epoch retirement diagnostic: ", {"expected_count": _bc_old_retirement_expected.size(), "observed_count": _bc_old_retirement_seen.size(), "events": _bc_old_retirement_events})
	if not _expect(_bc_old_retirement_seen.size() == _bc_old_retirement_expected.size(), "every measured old-epoch cancel/clear notification retires once, independently of quiet new restoration"): return false
	if not _bc_checkpoint_criteria(_game.capture_campaign_snapshot()): return false
	_lc_restore_events.clear(); _lc_watching_restore = true
	await _lc_settle()
	_lc_watching_restore = false
	return _bc_unit_exact(checkpoint, "held paused B02 Retry") and _expect(_lc_restore_events.is_empty() and _game.attempts.state().completed_main == HOUSE_PREFIX and _game.attempts.state().reward_ids.is_empty(), "held restored B02 unit earns no danger/progression/reward or resource reset")

func _lc_new_shell() -> bool:
	_game = Shell.new() as CinderCampaignShell
	if not _expect(_game.configure_runtime(_lc_raw, BOSS_TEST_ROOT + "campaign.json", BOSS_TEST_ROOT + "settings.json", BOSS_TEST_ROOT + "preferences.json"), "fresh actual Shell uses the independent earned-artifact test save paths"): return false
	root.add_child(_game)
	await _lc_settle()
	return _expect(paused and _game.campaign_error.is_empty() and _game.menu.page_name() == "title", "fresh actual Shell loads untouched earned payload at Title")

func _bc_resume_eight_ticks() -> bool:
	# Same proven real GUI event sequence; sample physics instead of awaiting
	# render frames after Resume, so exactly eight authoritative ticks are seen.
	await _lc_settle()
	var button: Button = _game.menu.find_child("ResumeButton", true, false) as Button
	if not _expect(is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled, "actual enabled Resume button is available"): return false
	var presses: Array[String] = []
	button.pressed.connect(func() -> void: presses.append("ResumeButton"))
	var at: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = at; motion.global_position = at
	root.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = at; press.global_position = at; press.pressed = true
	root.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release, true)
	if not _expect(presses == ["ResumeButton"] and not paused and _game.campaign_error.is_empty(), "one actual Resume click consumes the gesture and unpauses the real saved unit"): return false
	for tick: int in range(8):
		await _native_probe.tick_finished
		if not _expect(not paused and not _game.player.dead and String(_game.active_level.get("runtime_error")).is_empty(), "real authoritative resumed tick %d/8 remains a living healthy unit" % (tick + 1)): return false
	return true

func _bc_unit_exact(expected: Dictionary, label: String) -> bool:
	var before: int = _failures
	if not _expect(is_instance_valid(_game.player) and is_instance_valid(_game.active_level) and _game.active_level.level_id == "A2-L3" and String(_game.active_level.get("runtime_error")).is_empty(), label + " retains the actual healthy native L3/Hero binding"): return false
	var actual: Dictionary = _game.capture_campaign_snapshot()
	if not _lc_valid_snapshot(actual): return false
	_expect(LifecycleJson.stringify(actual) == LifecycleJson.stringify(expected), label + " retains the entire exact original aggregate including input/camera/gear/resources/phase/cooldowns")
	var level: CinderLevel = _game.active_level
	var local: Dictionary = expected.level.local
	var actors: Dictionary = level.get("_actors")
	var tools: Dictionary = level.get("_mechanisms")
	var banks: Dictionary = level.get("_clouds")
	var bindings: Dictionary = level.call("_scheduler_bindings")
	_expect(actors.size() == 7 and tools.size() == 4 and banks.size() == 3, label + " restores all seven actual actors/four tools/three banks")
	var ids: Dictionary = {}
	for id: String in actors:
		var actor: Node = actors[id]
		ids[actor.get_instance_id()] = true
		var saved: Dictionary = local.rays.actors.apron_scout if id == "apron_scout" else local.targets[id]
		_expect(LifecycleJson.stringify(actor.call("snapshot_state")) == LifecycleJson.stringify(saved), label + " independent native actor is exact: " + id)
	_expect(ids.size() == 7 and LifecycleJson.stringify(_game.player.snapshot_state()) == LifecycleJson.stringify(expected.player), label + " has seven distinct actors and the exact complete saved Player")
	_expect(LifecycleJson.stringify(level.get("_scheduler").snapshot_state(bindings)) == LifecycleJson.stringify(local.scheduler) and LifecycleJson.stringify(level.get("_exchange").call("snapshot_state", bindings)) == LifecycleJson.stringify(local.rays) and LifecycleJson.stringify(level.get("_crossing").call("snapshot_state")) == LifecycleJson.stringify(local.sequence), label + " independent Scheduler/Ray/earned sequence are exact")
	for components: Dictionary in [tools, banks]:
		for id: String in components:
			var saved: Dictionary = local.mechanisms[id] if tools.has(id) else local.banks[id]
			_expect(LifecycleJson.stringify(components[id].call("snapshot_state", bindings)) == LifecycleJson.stringify(saved), label + " independent native consumer is exact: " + id)
			var cue: CinderThreatCue = components[id].call("get_cue") as CinderThreatCue
			_expect(is_instance_valid(cue) and cue.state().phase == saved.phase, label + " quietly reconstructed required consumer cue matches the saved phase: " + id)
	var required: int = 0
	for cue: Node in get_nodes_in_group("required_cues"):
		if level.is_ancestor_of(cue):
			required += 1
			_expect(cue.is_inside_tree() and not cue.is_queued_for_deletion(), label + " retains its required native cue subtree")
	_expect(required > 0 and level.get("_bank_guard").call("binding_matches", Callable(level, "_guard_banks_before_contact")), label + " retains required cues and the actual guarded bank contact binding")
	if label == "fresh GUI Continue": _bc_continue_diagnostic()
	return _failures == before

func _bc_observe_added(node: Node) -> void:
	_lc_observe_added(node)
	if not _lc_watching_restore: return
	if node is CinderThreatScheduler:
		node.connect("reservation_invalidated", func(id: String, reason: String) -> void:
			if not _bc_old_retirement(node, "scheduler-cancel", {"id": id, "reason": reason}): _lc_restore_events.append("scheduler-cancel"))
	if node is CinderThreatCue or node is CinderInteractionCue or node is CinderLaneMechanism or node.get_script() == SmokeBank:
		node.connect("state_changed", func(state: Dictionary) -> void:
			if not _bc_old_retirement(node, "cue-or-consumer-phase", state): _lc_restore_events.append("cue-or-consumer-phase"))
	elif node.get_script() == RayExchange:
		node.connect("state_changed", func(id: String, state: Dictionary) -> void:
			if _bc_pristine_ray_retirement(node, id, state):
				_bc_pristine_ray_retirements.append({"node_id": node.get_instance_id(), "path": str(node.get_path()), "state": state.duplicate(true), "entered": node.get_parent().get("_entered"), "lifecycle_busy": node.get_parent().get("_lifecycle_busy"), "scheduler_clock_s": node.get("_scheduler").get_clock()})
			else: _lc_restore_events.append("ray-phase"))

func _bc_record_old_retirement(snapshot: Dictionary) -> void:
	# TEST ONLY expectations derive from the actual paused old unit, before the
	# public Retry. Original artifact, snapshot and native resources stay intact.
	var level: CinderLevel = _game.active_level
	_bc_old_level = weakref(level)
	_bc_old_snapshot = snapshot.duplicate(true)
	_bc_old_retirement_expected.clear()
	_bc_old_retirement_seen.clear()
	_bc_old_retirement_events.clear()
	var scheduler: Node = level.get("_scheduler")
	for node: Node in level.find_children("*", "", true, false):
		var before: Dictionary = {}
		var expected: Dictionary = {}
		if node is CinderThreatCue:
			before = node.call("state")
			if before.phase == "clear": continue
			expected = {"api_revision": before.api_revision, "phase": "clear", "geometry": {}, "source_position": null, "required": true, "source_visible": false, "footprint_visible": false, "active_fill_visible": false}
		elif node is CinderInteractionCue:
			# Exit explicitly clears the exit marker and Ray housing marker.
			# Other low-mount markers are freed with the old subtree, without
			# a clear publication, so they are not expected notifications.
			if node != level.get("_exit_cue") and node.get_parent().get_script() != RayExchange: continue
			before = node.call("state")
			if before.state == "clear": continue
			expected = {"api_revision": before.api_revision, "state": "clear", "trigger": before.trigger, "required": true, "visible": false}
		elif node is CinderLaneMechanism or node.get_script() == SmokeBank:
			before = node.call("state")
			if before.phase == "clear": continue
			expected = before.duplicate(true)
			expected.status = "cancelled" if int(before.cycle) > 0 else "idle"
			expected.phase = "clear"
			expected.reservation_id = ""
			var reason: String = "l3_exit" if node.get_script() == SmokeBank else "l2_exit"
			expected.last_cancel_reason = reason
			if node.get_script() == SmokeBank:
				expected.contact_since_s = null
				expected.grace_progress = 0.0
				expected.next_eligible_s = null
				expected.pending_samples = 0
				if not expected.receipts.is_empty() and expected.receipts[-1].stage == "notify": expected.receipts[-1].stage = "abandoned"
			else: expected.remaining_s = 0.0
			if before.status == "running" and not String(before.reservation_id).is_empty():
				var cancellation: Dictionary = {"id": before.reservation_id, "reason": reason}
				_bc_old_retirement_expected[_bc_retirement_key(scheduler, "scheduler-cancel", cancellation)] = {"node": weakref(scheduler), "state": cancellation}
		else: continue
		_bc_old_retirement_expected[_bc_retirement_key(node, "cue-or-consumer-phase", expected)] = {"node": weakref(node), "state": expected}

func _bc_retirement_key(node: Node, kind: String, state: Dictionary) -> String:
	return str(node.get_instance_id()) + ":" + kind + (":" + String(state.id) if kind == "scheduler-cancel" else "")

func _bc_old_retirement(node: Node, kind: String, state: Dictionary) -> bool:
	# Shell restores the fresh candidate first, then exits this recorded OLD
	# installed root before active_level reassignment. Only its exact measured
	# cancel/clear outcomes are cleanup; every new/live/restoring event fails.
	if _bc_old_level == null or not is_instance_valid(node) or not is_instance_valid(_game): return false
	var level: CinderLevel = _bc_old_level.get_ref() as CinderLevel
	if not is_instance_valid(level) or level != _game.active_level or not level.is_ancestor_of(node) or level.get("_entered") != false or level.get("_lifecycle_busy") != true: return false
	for flag: String in ["_restoring", "_snapshotting", "_validating"]:
		if level.get(flag) != false: return false
	var key: String = _bc_retirement_key(node, kind, state)
	if not _bc_old_retirement_expected.has(key) or _bc_old_retirement_seen.has(key): return false
	var expected: Dictionary = _bc_old_retirement_expected[key]
	if expected.node.get_ref() != node or state != expected.state or not paused: return false
	var local: Dictionary = _bc_old_snapshot.level.local
	if level.get("_scheduler").get_clock() != local.scheduler.clock_s or level.hero.get_world_action_clock() != _bc_old_snapshot.player.world_actions.clock_s or level.hero.hp != _bc_old_snapshot.player.resources.hp or level.hero.shells != _bc_old_snapshot.player.resources.shells: return false
	if level.get("_crossing").call("snapshot_state") != local.sequence or level.get("_last_action_sequence") != local.last_action_sequence or level.get("_completed") != _bc_old_snapshot.level.progress.completed or level.get("_contact_exit_id") != _bc_old_snapshot.level.progress.contact_exit_id: return false
	_bc_old_retirement_seen[key] = true
	_bc_old_retirement_events.append({"node_id": node.get_instance_id(), "path": str(node.get_path()), "kind": kind, "state": state.duplicate(true), "scheduler_clock_s": local.scheduler.clock_s})
	return true

func _bc_pristine_ray_retirement(driver: Node, id: String, state: Dictionary) -> bool:
	# Configure presents with notify=false; quiet restore never emits Ray state.
	# Cleanup publishes cancel even for the pristine validation-only cycle0.
	# Recognize only that initial candidate's actual exit transaction. Saved,
	# running, installed and restoring epochs remain prohibited observations.
	if id != "apron_scout" or not is_instance_valid(driver) or driver.get_script() != RayExchange or not is_instance_valid(_game): return false
	var level: CinderLevel = driver.get_parent() as CinderLevel
	if not is_instance_valid(level) or level == _game.active_level or level.level_id != "A2-L3" or level.scene_file_path != HOUSE_SCENE or level.get("_entered") != false or level.get("_lifecycle_busy") != true: return false
	for flag: String in ["_restoring", "_snapshotting", "_validating"]:
		if level.get(flag) != false: return false
	if driver.get("_configured") != true or driver.get("_retired") != false or driver.get("_snapshot_busy") != false or driver.get("_cancelling") != true or driver.get("_transaction_depth") != 1: return false
	if state.get("status") != "idle" or state.get("phase") != "clear" or state.get("cycle") != 0 or state.get("armed") != false or state.get("remaining_s") != 0.0 or state.get("reservation_id") != "" or state.get("hit_consumed") != false or state.get("last_cancel_reason") != "" or state.get("proof_available") != false: return false
	for key: String in ["exchange", "geometry", "proof", "presentation_witness"]:
		if not state.get(key) is Dictionary or not state[key].is_empty(): return false
	var records: Variant = driver.get("_records")
	var actors: Variant = driver.get("_actors")
	if not records is Dictionary or records.size() != 1 or not records.get(id) is Dictionary or not actors is Dictionary or actors.size() != 1: return false
	var record: Dictionary = records[id]
	for key: String in ["exchange", "context", "sample", "presentation_witness"]:
		if not record.get(key) is Dictionary or not record[key].is_empty(): return false
	if record.get("deferred_paths") != [] or record.get("observed_hp") != 30.0 or record.get("flash_until_s") != 0.0 or record.get("direction") != Vector3.BACK or state.get("direction") != Vector3.BACK: return false
	var actor: Variant = actors.get(id)
	var actor_origin: Vector3 = Vector3(-0.65, 0.0, -23.1)
	if not is_instance_valid(actor) or not actor is Node3D or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.get("actor_id") != id or actor.get("hp") != 30.0 or actor.get("max_hp") != 30.0 or actor.get("phase") != "idle" or actor.get("phase_progress") != 0.0 or actor.global_position != actor_origin or state.get("source_position") != actor_origin: return false
	var shared_hero: Variant = driver.get("_hero")
	var scheduler: Variant = driver.get("_scheduler")
	if not is_instance_valid(shared_hero) or shared_hero != level.hero or shared_hero.dead or shared_hero.get_world_action_clock() != 0.0 or not shared_hero.get_world_action_records().is_empty() or shared_hero.global_position != level.spawn_position(): return false
	if not is_instance_valid(scheduler) or scheduler != level.get("_scheduler") or scheduler.get_clock() != 0.0: return false
	var sequence: Variant = level.get("_crossing")
	if not is_instance_valid(sequence) or sequence.get("stage_index") != 0 or sequence.get("defeated_ids") != [] or sequence.get("crossed_contacts") != []: return false
	return level.get("_last_action_sequence") == 0 and level.get("_scenic_clock") == 0.0 and level.get("_exit_requested") == false and level.get("_boss_phase_pending") == false and level.get("_completed") == false and level.get("_contact_exit_id") == "" and level.current_checkpoint() == {"id": "", "kind": ""}

func _bc_continue_diagnostic() -> void:
	# Read-only TEST ONLY breakdown for the unchanged combined assertion.
	var actual: Dictionary = _game.attempts.state()
	var expected: Dictionary = _bc_original.attempts_payload
	var differences: Array[Dictionary] = []
	_bc_exact_differences(expected, actual, "attempts", differences)
	print("B02 Continue diagnostic: ", {"restore_events": _lc_restore_events.duplicate(), "pristine_ray_retirement_count": _bc_pristine_ray_retirements.size(), "pristine_ray_retirements": _bc_pristine_ray_retirements.duplicate(true), "paused": paused, "menu": _game.menu.page_name(), "payload_equal": LifecycleJson.stringify(actual) == LifecycleJson.stringify(expected), "checkpoint_equal": LifecycleJson.stringify(actual.story.checkpoint) == LifecycleJson.stringify(_bc_original.checkpoint), "story_snapshot_equal": LifecycleJson.stringify(actual.story.snapshot) == LifecycleJson.stringify(expected.story.snapshot), "campaign_error": _game.campaign_error, "attempt_warning": _game.attempts.last_warning, "first_exact_payload_differences": differences})

func _bc_exact_differences(expected: Variant, actual: Variant, path: String, output: Array[Dictionary]) -> void:
	if output.size() >= 8 or LifecycleJson.stringify(expected) == LifecycleJson.stringify(actual): return
	if expected is Dictionary and actual is Dictionary:
		var keys: Array = expected.keys()
		for key: Variant in actual.keys():
			if not keys.has(key): keys.append(key)
		keys.sort()
		for key: Variant in keys:
			if output.size() >= 8: return
			if not expected.has(key) or not actual.has(key): output.append({"path": path + "." + str(key), "expected_present": expected.has(key), "actual_present": actual.has(key)})
			else: _bc_exact_differences(expected[key], actual[key], path + "." + str(key), output)
	elif expected is Array and actual is Array:
		if expected.size() != actual.size(): output.append({"path": path + ".size", "expected": expected.size(), "actual": actual.size()})
		for index: int in range(mini(expected.size(), actual.size())):
			if output.size() >= 8: return
			_bc_exact_differences(expected[index], actual[index], path + "[" + str(index) + "]", output)
	else:
		output.append({"path": path, "expected_type": typeof(expected), "actual_type": typeof(actual), "expected_exact": LifecycleJson.stringify(expected), "actual_exact": LifecycleJson.stringify(actual)})

func _bc_cleanup() -> void:
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BOSS_TEST_ROOT + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOSS_TEST_ROOT))
