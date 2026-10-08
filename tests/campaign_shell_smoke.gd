extends SceneTree
## Actual shared actor/enemy/floor/save/menu fixture. No real campaign acceptance.
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const TEST_ROOT: String = "user://test-campaign-shell/"
var checks: int = 0
var failures: int = 0
var raw: Dictionary
var game: CinderCampaignShell
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	_cleanup()
	raw = JSON.parse_string(FileAccess.get_file_as_string(Registry.DATA_PATH))
	for info: Dictionary in raw.levels:
		if ["A1-L1", "A1-L2", "A1-O1"].has(info.id):
			info.scene_path = "res://tests/fixtures/campaign/live_" + String(info.id).to_lower().replace("-", "_") + ".tscn"
			info.readiness = "accepted"
			info.accepted_commit = "a".repeat(40)
			info.api_revision = Registry.API_REVISION
	game = _new_shell()
	await _settle()
	_expect(paused and game.menu.page_name() == "title" and game.active_level == null, "desktop title starts paused with no fabricated lab campaign content")
	_expect((game.hud.find_child("ResetButton", true, false) as Button).text == "RETRY", "campaign HUD names its coherent checkpoint action accurately")
	game.menu.begin_story_requested.emit()
	await _settle()
	_expect(game.campaign_error.is_empty() and game.active_level != null, "accepted test fixture begins through actual shell: " + game.campaign_error)
	if game.active_level == null:
		_finish()
		return
	_expect(paused and game.menu.page_name() == "resume" and game.player.hp == 100.0 and game.player.shells == 2, "fresh story defines full initial resources and waits for consumed resume gesture")
	game.resume_campaign()
	await create_timer(0.2).timeout
	_expect(not paused and not game.menu.is_open() and game.player.get_threat_response_state().motion.grounded, "shared actor settles on the candidate floor after World3D installation")
	game.request_pause()
	await _settle()
	game.player.hp = 22.0
	game.player.shells = 0
	game.active_level.charges = 0
	game.active_level.collected = ["supply-1"]
	game.active_level.guard.hp = 7.0
	game._record_swipe_end(root.get_visible_rect().size * Vector2(0.38,0.36))
	_expect(game.active_level.request_checkpoint("roof", "encounter"), "authored checkpoint reaches the shared shell consumer")
	await _settle()
	var checkpoint: Dictionary = game.attempts.active_snapshot()
	_expect(checkpoint.player.resources.hp == 22.0 and checkpoint.player.resources.shells == 0 and checkpoint.level.local.charges == 0 and checkpoint.level.local.guard.resources.hp == 7.0, "checkpoint stores actor, enemy and spent supply as one durable aggregate without healing")
	_expect(checkpoint.level.local.rng_state == "9223372036854775701" and Codec.same_values(checkpoint.shell.anchor_normalized, [0.38,0.36]), "large encounter RNG and exact screen aim remain distinct serialized state")
	var input_before: int = game.get_input_observation_state().sequence
	game.handle_tap(root.get_visible_rect().size * 0.5)
	_expect(game.get_input_observation_state().sequence == input_before and game.player.get_world_action_records().is_empty(), "menu taps cannot fire or alter input observations")
	game.player.hp = 3.0
	game.player.shells = 1
	game.active_level.guard.hp = 2.0
	game.active_level.charges = 1
	game.active_level.collected.clear()
	game.request_retry()
	await _settle()
	_expect(game.campaign_error.is_empty() and Codec.same_values(game.capture_campaign_snapshot(), checkpoint), "retry restores exact resources/enemy clocks/supply/aim/camera as the same paused aggregate: " + game.campaign_error)
	_expect(not game.active_level.request_contact_exit("hatch", game.player), "uncleared contact cannot transition")
	_expect(game.active_level.request_completion("launch") and not game.active_level.request_completion("launch"), "authored completion is once-only before shell persistence")
	await _settle()
	_expect(game.attempts.state().completed_main == ["A1-L1"] and game.attempts.active_snapshot().level.progress.completed, "completion and the completed local aggregate commit together")
	_expect(game.active_level.request_contact_exit("hatch", game.player), "cleared hero contact requests canonical next story level")
	await _settle()
	_expect(game.active_level.level_id == "A1-L2" and game.player.hp == 22.0 and game.player.shells == 0 and game.get_aim_anchor_normalized().is_equal_approx(Vector2(0.38,0.36)), "story transition carries health/ammo/gear/reload and exact anchor without optional gating")
	game.active_level.request_completion("clear")
	await _settle()
	_expect(game.attempts.state().completed_main == ["A1-L1", "A1-L2"], "next main completion follows a sequential route prefix")
	_expect(game.attempts.grant_equipment(["WEAPON-02"]), "explicit test-only authored equipment reward unlocks a replay option")
	var protected: Dictionary = game.attempts.story_snapshot()
	var replay_gear: Dictionary = game.player.equipment.snapshot()
	replay_gear.weapon = "WEAPON-02"
	game.menu.replay_requested.emit("A1-L1", replay_gear)
	await _settle()
	_expect(game.attempts.active_kind() == "replay" and game.player.equipment.snapshot().weapon == "WEAPON-02" and game.player.hp == 100 and game.player.shells == 2, "completed-level replay starts a separately equipped full-resource attempt")
	_expect(Codec.same_values(game.attempts.story_snapshot(), protected), "starting replay preserves the complete story aggregate")
	game.player.hp = 1.0
	game.player.shells = 0
	game.active_level.charges = 0
	game.active_level.collected = ["supply-1"]
	game.request_pause()
	await _settle()
	_expect(game.attempts.active_snapshot().player.resources.hp == 1.0 and Codec.same_values(game.attempts.story_snapshot(), protected), "side damage/spent supplies save independently of protected story")
	game.free()
	game = _new_shell()
	await _settle()
	_expect(paused and game.menu.page_name() == "title" and game.attempts.active_kind() == "replay" and game.active_level == null, "interrupted side session reloads into title with coherent protected story and no running actors")
	game.resume_campaign()
	await _settle()
	_expect(paused and game.menu.page_name() == "resume" and game.player.hp == 1.0 and game.player.shells == 0 and game.player.equipment.snapshot().weapon == "WEAPON-02", "interrupted replay restores its exact worn gear/resources paused")
	game.request_retry()
	await _settle()
	_expect(game.player.hp == 100 and game.player.shells == 2 and Codec.same_values(game.attempts.story_snapshot(), protected), "replay retry uses its own initial checkpoint and leaves story untouched")
	game.active_level.request_completion("replay-clear")
	await _settle()
	game.active_level.request_contact_exit("return", game.player)
	await _settle()
	_expect(game.attempts.active_kind() == "story" and Codec.same_values(game.capture_campaign_snapshot(), protected), "finishing replay automatically restores entire story equipment, resources, enemies and aim")
	game.menu.optional_requested.emit("A1-O1")
	await _settle()
	_expect(game.attempts.active_kind() == "optional" and game.active_level.level_id == "A1-O1", "parent-clear optional branch launches through isolated side flow")
	game.active_level.request_completion("optional-clear")
	await _settle()
	_expect(game.attempts.state().reward_ids == ["A1-O1-completion-stamp"], "actual optional completion records its once-only stamp")
	game.active_level.request_contact_exit("return",game.player)
	await _settle()
	_expect(game.attempts.active_kind() == "story" and Codec.same_values(game.capture_campaign_snapshot(),protected), "optional exit restores coherent story automatically")
	game.menu.replay_requested.emit("A1-O1",protected.equipment_ids)
	await _settle()
	game.active_level.request_completion("optional-replay-clear")
	await _settle()
	game.active_level.request_contact_exit("return",game.player)
	await _settle()
	_expect(game.attempts.state().reward_ids.size() == 1 and game.attempts.state().completed_main.size() == 2, "optional replay cannot repeat rewards or advance the main route")
	var before: Dictionary = game.capture_campaign_snapshot()
	var malformed: Dictionary = before.duplicate(true)
	malformed.player.resources.hp = 200.0
	_expect(not game.attempts.record_snapshot(malformed) and Codec.same_values(game.capture_campaign_snapshot(), before), "invalid actor snapshot rejects before changing live level or durable model")
	malformed = before.duplicate(true)
	malformed.level.local.charges = 0 if int(malformed.level.local.charges) == 1 else 1
	_expect(not game.attempts.record_snapshot(malformed), "invalid local supply/collection identity fails aggregate semantic validation")
	malformed = before.duplicate(true)
	malformed.shell.anchor_normalized = [0.1,0.1]
	# Transition clears the observer, so create a record before testing mismatch.
	game._record_swipe_end(root.get_visible_rect().size * Vector2(0.38,0.36))
	malformed = game.capture_campaign_snapshot()
	malformed.shell.anchor_normalized = [0.1,0.1]
	_expect(not game.attempts.record_snapshot(malformed), "teaching observation cannot disagree with authoritative saved release anchor")
	game.menu.settings_changed_request.emit({"quality":"Low","reduced_motion":true})
	_expect(paused and game.settings.snapshot().quality == "Low" and game.fx.camera_shake_scale() == 0.0, "actual shell applies persistent cosmetic settings without unpausing or removing combat feedback")
	game.menu.difficulty_preference_requested.emit("assisted")
	_expect(game.get_difficulty_preference() == "assisted", "persistent difficulty preference acknowledges a future fresh boundary")
	# Fail a completion write after local latching. Preserve/retry the operation,
	# then simulate a missing next scene; Continue retries its durable exit later.
	game.attempts._store.path = TEST_ROOT + "blocked-save"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(game.attempts._store.path))
	game.menu.replay_requested.emit("A1-L1",protected.equipment_ids)
	await _settle()
	_expect(not game._failed_operations.is_empty() and game.active_level.level_id == "A1-L2" and paused, "failed side-save keeps old live world paused and exposes pending operation retry")
	game.attempts._store.path = TEST_ROOT + "campaign.json"
	game.retry_pending_operations()
	await _settle()
	_expect(game.attempts.active_kind() == "replay" and game._failed_operations.is_empty(), "retry publishes side transaction before replacing old world")
	game.attempts._store.path = TEST_ROOT + "blocked-save"
	game.active_level.request_completion("retry-save-clear")
	await _settle()
	_expect(not game._failed_operations.is_empty() and not game.attempts.active_snapshot().level.progress.completed, "failed completion leaves prior aggregate/progress intact while preserving latched live operation")
	game.attempts._store.path = TEST_ROOT + "campaign.json"
	game.retry_pending_operations()
	await _settle()
	_expect(game.attempts.active_snapshot().level.progress.completed and game._failed_operations.is_empty(), "pending completion retries without requiring another suppressed level signal")
	game.menu.leave_side_requested.emit()
	await _settle()
	_expect(game.attempts.active_kind() == "story" and game.player.hp == 22 and game.player.shells == 0, "abandoning completed replay restores protected story explicitly")
	game.active_level.request_contact_exit("pending-next", game.player)
	await _settle()
	_expect(not game._failed_operations.is_empty() and game.active_level.level_id == "A1-L2" and not String(game.attempts.story_snapshot().level.progress.contact_exit_id).is_empty(), "missing accepted next scene preserves a durable latched exit and current resources")
	game.free()
	for info: Dictionary in raw.levels:
		if info.id == "A1-L3":
			info.scene_path = "res://tests/fixtures/campaign/live_a1_l3.tscn"
			info.readiness = "accepted"
			info.accepted_commit = "a".repeat(40)
			info.api_revision = Registry.API_REVISION
	game = _new_shell()
	await _settle()
	game.menu.continue_story_requested.emit()
	await _settle()
	_expect(game.campaign_error.is_empty() and game.active_level.level_id == "A1-L3" and game.player.hp == 22 and game.player.shells == 0 and game.get_difficulty_preference() == "assisted", "Continue consumes a saved pending exit after next scene integration, carrying resources and future difficulty preference")
	_finish()
func _new_shell() -> CinderCampaignShell:
	var result: CinderCampaignShell = Shell.new()
	result.configure_runtime(raw, TEST_ROOT+"campaign.json",TEST_ROOT+"settings.json",TEST_ROOT+"preferences.json")
	root.add_child(result)
	return result
func _settle() -> void:
	for index: int in range(4):
		await process_frame
func _finish() -> void:
	if is_instance_valid(game):
		game.free()
	paused = false
	_cleanup()
	print("Campaign shell smoke: %d checks, %d failures (TEST ONLY live fixtures)" % [checks,failures])
	quit(1 if failures else 0)
func _cleanup() -> void:
	for name: String in ["campaign.json","campaign.json.bak","settings.json","settings.json.bak","preferences.json","preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT+name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT+"blocked-save"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT))
func _expect(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + note)
