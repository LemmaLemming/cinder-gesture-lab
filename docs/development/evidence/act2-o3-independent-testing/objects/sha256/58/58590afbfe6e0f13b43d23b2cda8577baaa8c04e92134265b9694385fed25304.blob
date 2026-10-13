extends SceneTree
## TEST ONLY real shared arm fixture; no authored-level/encounter acceptance.
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const LegacyLevel = preload("res://tests/fixtures/campaign/legacy_context_level.gd")
const TEST_ROOT: String = "user://test-level-player-context/"
var checks: int = 0
var failures: int = 0
var raw: Dictionary
var game: CinderCampaignShell
var fresh: CinderCampaignShell


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_cleanup()
	raw = JSON.parse_string(FileAccess.get_file_as_string(Registry.DATA_PATH))
	for info: Dictionary in raw.levels:
		if info.id == "A1-L1":
			info.scene_path = "res://tests/fixtures/campaign/paired_arm_level.tscn"
			info.readiness = "accepted"
			info.accepted_commit = "b".repeat(40)
			info.api_revision = Registry.API_REVISION
	game = _new_shell("live")
	await _settle()
	game.menu.begin_story_requested.emit()
	await _settle()
	_expect(game.active_level != null and game.campaign_error.is_empty(), "actual campaign shell starts test-only paired arm fixture: " + game.campaign_error)
	if game.active_level == null:
		_finish()
		return
	game.player.hp = 37.0
	game.player.shells = 0
	game.resume_campaign()
	await _ticks(6)
	var answer: Dictionary = game.active_level.start_arm()
	_expect(answer.get("accepted", false), "actual floor/collision/response proof starts the nonenemy loading arm: " + String(answer.get("reason", "")))
	if not answer.get("accepted", false):
		_finish()
		return
	_expect(game.player.request_dash(Vector3.BACK), "real shared actor executes a dash while the arm warns")
	await _ticks(2)
	paused = true
	await process_frame
	var saved: Dictionary = _json(game.capture_campaign_snapshot())
	_expect(not saved.is_empty() and saved.player.clocks.dash_left_s > 0.0 and saved.level.local.arm.status == "running" and Codec.same_values(saved.player.motion.position, saved.level.local.arm.hero_samples.hero.position), "paused mid-dash capture pairs the actual actor motion and arm path sample")
	if saved.is_empty():
		_finish()
		return
	_expect(game.player.snapshot_error(saved.player).is_empty() and game.active_level.snapshot_error(saved.level).is_empty(), "legacy validation still accepts the same actual current player")
	paused = false
	await _ticks(13)
	paused = true
	await process_frame
	var live_before: Dictionary = _json(game.capture_campaign_snapshot())
	_expect(not live_before.is_empty() and not Codec.same_values(saved.player.motion.position, live_before.player.motion.position), "live actor actually travels beyond the saved mid-dash feet position")
	if live_before.is_empty():
		_finish()
		return
	_expect(not game.active_level.snapshot_error(saved.level).is_empty(), "legacy local proof correctly rejects a saved arm sample against the later live actor")
	var old_calls: int = game.active_level.local_validations
	var context_calls: int = game.active_level.context_validations
	var error: String = game._snapshot_problem(saved)
	_expect(error.is_empty(), "shell aggregate proof uses validated saved player without restoring live actor: " + error)
	_expect(game.active_level.local_validations == old_calls and game.active_level.context_validations == context_calls + 1, "aggregate proof selects one context hook and does not pre-call the incompatible live hook")
	_expect(Codec.same_values(game.capture_campaign_snapshot(), live_before) and game.active_level.restores == 0, "accepted aggregate prevalidation leaves live actor, arm, scheduler, clocks and resources unchanged")
	var forged: Dictionary = saved.duplicate(true)
	forged.player = live_before.player.duplicate(true)
	_expect(game.player.snapshot_error(forged.player).is_empty(), "cross-forged later actor component is individually valid")
	_expect(not game._snapshot_problem(forged).is_empty(), "whole aggregate rejects a valid later player paired with an earlier arm sample")
	forged = saved.duplicate(true)
	forged.level.local.arm.hero_samples.hero.position = live_before.player.motion.position.duplicate(true)
	_expect(game.active_level.snapshot_error(forged.level).is_empty(), "cross-forged arm component can individually match the current live player")
	_expect(not game._snapshot_problem(forged).is_empty(), "saved player controls pair proof; local arm cannot self-authorize its own forged sample")
	_expect(Codec.same_values(game.capture_campaign_snapshot(), live_before), "rejected cross-component pairs preserve all live state")
	context_calls = game.active_level.context_validations
	forged = saved.duplicate(true)
	forged.player.resources.hp = 200.0
	_expect(not game._snapshot_problem(forged).is_empty() and game.active_level.context_validations == context_calls, "shell rejects invalid actor before invoking local context hook")
	forged = saved.duplicate(true)
	forged.level.progress.completion_id = "unearned"
	_expect(not game._snapshot_problem(forged).is_empty() and game.active_level.context_validations == context_calls, "full progression envelope rejects before invoking context hook")
	forged = saved.duplicate(true)
	forged.level.local_snapshot_version = 999
	_expect(not game._snapshot_problem(forged).is_empty() and game.active_level.context_validations == context_calls, "local schema identity rejects before invoking context hook")
	var transport: Dictionary = saved.player.duplicate(true)
	transport.unexpected_node = game.player
	_expect(not game.active_level.snapshot_error_with_player(saved.level, transport).is_empty() and game.active_level.context_validations == context_calls, "public context boundary rejects non-JSON shared references before defensive copying/hook dispatch")
	var caller_before: Dictionary = saved.duplicate(true)
	game.active_level.probe_context = true
	_expect(game.active_level.snapshot_error_with_player(saved.level, saved.player).is_empty(), "context guard fixture runs after complete real paired proof")
	game.active_level.probe_context = false
	for key: String in ["context", "live", "restore", "capture", "completion", "checkpoint", "exit", "lifecycle"]:
		_expect(game.active_level.guard_observations.get(key, false), "context callback guards " + key)
	_expect(Codec.same_values(saved, caller_before), "nested local and saved-player dictionaries are defensive copies")
	_expect(Codec.same_values(game.capture_campaign_snapshot(), live_before), "guard probes and deliberate copy mutation leave actual aggregate unchanged")
	_test_legacy(saved.player)
	# A fresh shell has no live matching level. Its hidden candidate starts at
	# spawn with an idle arm, and must prove the saved running pair without ticks.
	fresh = _new_shell("fresh")
	await _settle()
	error = fresh._snapshot_problem(saved)
	_expect(error.is_empty(), "fresh candidate prevalidates saved player/arm pair at a different spawn pose: " + error)
	if not error.is_empty():
		_finish()
		return
	var candidate: Dictionary = fresh._validation_candidates["A1-L1"]
	_expect(candidate.level.context_validations == 1 and candidate.level.local_validations == 0 and candidate.level.restores == 0, "fresh candidate invokes context exactly once before any local commit")
	_expect(not candidate.player.global_position.is_equal_approx(Codec.read_vector3(saved.player.motion.position)) and candidate.level.arm.state().status == "idle" and candidate.level.scheduler.get_clock() == 0.0 and candidate.level.scheduler.reservations().is_empty(), "fresh prevalidation preserves spawn actor, idle arm, empty scheduler and zero clock")
	var events: Array[String] = []
	candidate.player.world_action_executed.connect(func(_record: Dictionary) -> void: events.append("action"))
	candidate.level.arm.state_changed.connect(func(_state: Dictionary) -> void: events.append("arm"))
	candidate.level.arm.hit_resolved.connect(func(_hero: String, _cycle: int, _hit: Dictionary) -> void: events.append("hit"))
	candidate.level.scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: events.append("cancel"))
	_expect(candidate.player.restore_state(saved.player) and candidate.level.restore_state(saved.level) and candidate.level.restore_error.is_empty(), "existing ordered actor then level restore commits the validated real pair: " + candidate.level.restore_error)
	_expect(Codec.same_values(candidate.player.snapshot_state(), saved.player) and Codec.same_values(candidate.level.snapshot_state(), saved.level), "fresh ordered restore retains exact actor path/resources and running arm/scheduler deadlines")
	_expect(events.is_empty(), "paired restore emits no action, attack, damage, phase or cancellation callbacks")
	var prepared: Dictionary = fresh._prepare_snapshot(saved)
	_expect(not prepared.is_empty() and prepared.level.restore_error.is_empty() and Codec.same_values(prepared.player.snapshot_state(), saved.player) and Codec.same_values(prepared.level.snapshot_state(), saved.level), "actual shell prepare_snapshot performs full proof before actor/local commit")
	if not prepared.is_empty():
		fresh._dispose(prepared)
	_finish()


func _test_legacy(saved_player: Dictionary) -> void:
	var legacy = LegacyLevel.new()
	var marker := Marker3D.new()
	marker.name = "PlayerSpawn"
	legacy.add_child(marker)
	game.world.add_child(legacy)
	legacy.enter_level(game.player, game.fx)
	var saved: Dictionary = legacy.snapshot_state()
	var before: int = legacy.calls
	_expect(legacy.snapshot_error_with_player(saved, saved_player).is_empty() and legacy.calls == before + 1, "new default context hook delegates legacy local validator exactly once")
	saved.local = {"undeclared": true}
	_expect(not legacy.snapshot_error_with_player(saved, saved_player).is_empty(), "legacy local rejection remains effective through new context hook")
	legacy.free()


func _new_shell(prefix: String) -> CinderCampaignShell:
	var result: CinderCampaignShell = Shell.new()
	result.configure_runtime(raw, TEST_ROOT + prefix + "-campaign.json", TEST_ROOT + prefix + "-settings.json", TEST_ROOT + prefix + "-preferences.json")
	root.add_child(result)
	return result


func _json(value: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(value, "", true, true))


func _settle() -> void:
	for index: int in range(4):
		await process_frame


func _ticks(count: int) -> void:
	for index: int in range(count):
		await physics_frame
	await process_frame


func _expect(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + note)


func _finish() -> void:
	if is_instance_valid(fresh):
		fresh.free()
	if is_instance_valid(game):
		game.free()
	paused = false
	_cleanup()
	print("Level/player context smoke: %d checks, %d failures (TEST ONLY real arm fixture)" % [checks, failures])
	quit(1 if failures else 0)


func _cleanup() -> void:
	for prefix: String in ["live", "fresh"]:
		for kind: String in ["campaign", "settings", "preferences"]:
			for suffix: String in [".json", ".json.bak"]:
				DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT + prefix + "-" + kind + suffix))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT))
