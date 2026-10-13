extends SceneTree
## Actual native constructor/Shell restore-path fixture only. Synthetic registry
## metadata never accepts campaign content. No spore/controller protocol claim.
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Fixture = preload("res://tests/fixtures/restore_candidate_level.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const FIXTURE_PATH: String = "res://tests/fixtures/restore_candidate_level.tscn"
const TEST_ROOT: String = "user://test-restore-candidate/"

class LegacyDefaultLevel extends CinderLevel:
	var normal_entries: int = 0
	var entry_progress_refused: bool = false
	func _on_enter_level() -> void:
		normal_entries += 1
		entry_progress_refused = not request_completion("legacy-entry") and not request_checkpoint("legacy-entry-checkpoint")

var checks: int = 0
var failures: int = 0
var game: CinderCampaignShell
var raw: Dictionary = {}
var initial: Dictionary = {}
var later: Dictionary = {}
var old_fps: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	old_fps = Engine.max_fps
	_cleanup()
	raw = JSON.parse_string(FileAccess.get_file_as_string(Registry.DATA_PATH))
	for entry: Dictionary in raw.levels:
		if entry.id == "A1-L1":
			entry.scene_path = FIXTURE_PATH
			entry.readiness = "accepted"
			entry.accepted_commit = "a".repeat(40)
			entry.api_revision = Registry.API_REVISION
	game = _new_shell()
	await _settle()
	if not _guard(paused and game.active_level == null and game.menu.page_name() == "title", "actual Shell starts paused with no active test content"):
		_finish(); return
	game.menu.begin_story_requested.emit()
	await _settle()
	if not _guard(game.campaign_error.is_empty() and is_instance_valid(game.active_level), "actual fresh story enters TEST ONLY scene: " + game.campaign_error):
		_finish(); return
	var donor: Variant = game.active_level
	_expect(donor.normal_entries == 1 and donor.restore_entries == 0 and donor.room_index == 1 and donor.future_resource == null, "ordinary entry creates pristine dormant room; future resource is genuinely absent")
	_expect(donor.recipient.is_node_ready() and donor.recipient.hp == 8.0 and donor.recipient.field_id.is_empty(), "normal entry contains an actual ready native Box recipient bound to the shared Player")
	initial = game.attempts.active_snapshot()
	if not _guard(not initial.is_empty(), "initial whole native aggregate is stored"):
		_finish(); return
	game.resume_campaign()
	await create_timer(0.12).timeout
	if not _guard(not paused and game.player.get_threat_response_state().motion.grounded, "public Resume allows the real shared Player to settle on actual Box floor"):
		_finish(); return
	_expect(donor.open_future_room() and donor.activation_notifications == 1, "one genuine TEST ONLY room transition installs its future native resource")
	game.player.take_damage(83.0, Vector3.ZERO)
	_expect(donor.recipient.take_damage(8.0) and donor.recipient.hp == 0.0 and donor.recipient.dead, "real native recipient damage commits dead HP without deleting its dormant saved owner")
	_expect(not donor.recipient.take_damage(1.0) and donor.recipient.hit_count == 1, "native defeat remains once-only")
	game.request_pause()
	await _settle()
	later = game.attempts.active_snapshot()
	if not _guard(game.campaign_error.is_empty() and not later.is_empty() and later.level.local.room_index == 2 and later.player.resources.hp == 17.0, "paused actual Shell stores earned later-room native unit: " + game.campaign_error):
		_finish(); return
	_expect(later.level.local.recipient.dead and later.level.local.recipient.hp == 0.0 and later.level.local.future_resource.resource_id == Fixture.FIELD_ID and later.level.local.clock_s > 0.0, "later aggregate preserves original clocks/dead HP/installed resource identity")
	_expect(_same(game.attempts.state().story.checkpoint, initial), "ordinary pause retains the earlier dormant Retry checkpoint")

	await _direct_candidate_and_purity(donor)
	await _cache_and_rejection(donor)
	if not is_instance_valid(game): return

	# The active room2 donor's validator deliberately refuses room1. Retry must
	# construct the earlier topology, rather than reusing or mutating that donor.
	_expect(not donor.snapshot_error_with_player(initial.level, initial.player).is_empty(), "active later-room validator honestly cannot validate an earlier installed topology")
	var donor_ref: WeakRef = weakref(donor)
	game.request_retry()
	await _settle()
	if not _guard(game.campaign_error.is_empty() and is_instance_valid(game.active_level), "actual Shell Retry constructs saved earlier topology: " + game.campaign_error):
		_finish(); return
	var earlier: Variant = game.active_level
	_expect(donor_ref.get_ref() == null and earlier.room_index == 1 and earlier.future_resource == null, "earlier Retry retires the donor and leaves future resources absent")
	_expect(earlier.normal_entries == 0 and earlier.restore_entries == 1 and earlier.quiet_commits == 1 and not earlier.is_restore_candidate(), "Retry uses restore entry exactly once then finishes only after quiet commit/install")
	_expect(_same(game.capture_campaign_snapshot(), initial), "Retry restores the exact earlier checkpoint resources, topology, native recipient and clocks")

	# Reuse the previously earned native later snapshot as an explicit test-only
	# stored attempt. This is neither a fabricated recipient nor a new campaign
	# acceptance; it exercises saved topology against an earlier active donor.
	if not _guard(game.attempts.record_snapshot(later, true), "previously earned later whole unit validates/persists against earlier donor: " + game.attempts.last_error):
		_finish(); return
	var earlier_ref: WeakRef = weakref(earlier)
	game.menu.continue_story_requested.emit()
	await _settle()
	if not _guard(game.campaign_error.is_empty() and is_instance_valid(game.active_level), "actual same-process Continue uses saved later constructor: " + game.campaign_error):
		_finish(); return
	_expect(earlier_ref.get_ref() == null, "successful candidate installation retires the earlier donor")
	_expect_restored_later("same-process Continue")
	var first_restored: WeakRef = weakref(game.active_level)
	game.free()
	game = _new_shell()
	await _settle()
	if not _guard(game.campaign_error.is_empty() and game.active_level == null and game.menu.page_name() == "title", "fresh Shell loads exact disk data without activating the level: " + game.campaign_error):
		_finish(); return
	game.menu.continue_story_requested.emit()
	await _settle()
	if not _guard(game.campaign_error.is_empty() and is_instance_valid(game.active_level), "fresh disk Continue reconstructs actual later recipient/resource: " + game.campaign_error):
		_finish(); return
	_expect(first_restored.get_ref() == null, "fresh Continue owns distinct native instances after the previous entire Shell is disposed")
	_expect_restored_later("fresh disk Continue")
	_expect(not Fixture.destroyed_ids.is_empty(), "candidate and donor disposal are observed from actual native deletion")
	_finish()


func _direct_candidate_and_purity(donor: Variant) -> void:
	var before: Dictionary = donor.authority_state()
	var candidate: Dictionary = game._prepare("A1-L1", later.equipment_ids, {}, later)
	if not _guard(not candidate.is_empty(), "public level restore entry constructs saved later topology before validation: " + game.campaign_error):
		return
	var level: Variant = candidate.level
	var candidate_ref: WeakRef = weakref(level)
	_expect(level.normal_entries == 0 and level.restore_entries == 1 and level.constructor_pristine, "candidate builds immutable bindings without normal entry or applying saved HP/death/clocks")
	_expect(level.future_resource != null and level.recipient.field_owner == level.future_resource and level.recipient.actual_hero.get_ref() == candidate.player, "constructor binds genuine same-world resource, native body and actual candidate Player")
	_expect(level.constructor_progress_refused and level.activation_notifications == 0, "constructor refuses progression and emits no replayed room activation")
	_expect(level.is_restore_candidate() and not level.finish_restore_candidate(), "unrestored candidate cannot finish/become playable")
	var immutable: Dictionary = level.authority_state()
	_expect(level.snapshot_error_with_player(later.level, later.player).is_empty(), "later installed native topology passes pure staged-Player validation")
	_expect(_same_authority(immutable, level.authority_state()), "valid validator changes no actor/resource/progress/counter state")
	var malformed: Dictionary = later.level.duplicate(true)
	malformed.local.recipient.body_size[0] = 0.7
	_expect(not level.snapshot_error_with_player(malformed, later.player).is_empty(), "foreign immutable body dimensions fail pure validation")
	_expect(_same_authority(immutable, level.authority_state()), "rejected validator also changes no actor/resource/progress/counter state")
	_expect(not level.request_checkpoint("pre-commit") and not level.request_completion("pre-commit"), "ready bound candidate still refuses progression before quiet restore")
	var installed_resource: MeshInstance3D = level.future_resource
	_expect(candidate.player.restore_state(later.player) and level.restore_state(later.level), "actual Player commits before actual level quiet restore")
	_expect(level.quiet_commits == 1 and level.commits_saw_candidate and level.player_hp_at_commit == 17.0 and level.expected_saved_player_hp == 17.0, "local commit sees actual saved Player resources and pending candidate guard")
	_expect(level.future_resource == installed_resource and level.recipient.hp == 0.0 and level.recipient.dead and level.recipient.damage_notifications == 0 and level.recipient.defeat_notifications == 0, "quiet restore retains actual constructor resource and emits no restored hurt/death")
	_expect(level.is_restore_candidate() and not level.request_checkpoint("post-commit") and not level.request_completion("post-commit"), "successful restore alone cannot enable hidden candidate progression")
	_expect(level.finish_restore_candidate() and not level.is_restore_candidate(), "paused committed candidate can explicitly finish")
	var signals: Array[String] = []
	level.checkpoint_requested.connect(func(_id: String, checkpoint: String, _kind: String) -> void: signals.append(checkpoint))
	_expect(level.request_checkpoint("finished-boundary") and signals == ["finished-boundary"], "finished candidate can issue a genuine once-only progression request")
	_expect(not level.request_checkpoint("finished-boundary"), "finish does not remove ordinary duplicate checkpoint protection")
	_test_legacy_default(candidate)
	game._dispose(candidate)
	_expect(candidate_ref.get_ref() == null and _same_authority(before, donor.authority_state()), "disposing direct candidate leaves the entire live donor untouched")
	await process_frame


func _test_legacy_default(candidate: Dictionary) -> void:
	var normal := LegacyDefaultLevel.new()
	var spawn := Marker3D.new()
	spawn.name = "PlayerSpawn"
	normal.add_child(spawn)
	candidate.stage.add_child(normal)
	normal.enter_level(candidate.player, candidate.fx)
	var saved: Dictionary = normal.snapshot_state()
	_expect(normal.normal_entries == 1 and normal.entry_progress_refused and not normal.restore_candidate_construction_required(), "legacy ordinary entry remains compatible and does not require topology construction")
	var legacy := LegacyDefaultLevel.new()
	var legacy_spawn := Marker3D.new()
	legacy_spawn.name = "PlayerSpawn"
	legacy.add_child(legacy_spawn)
	candidate.stage.add_child(legacy)
	_expect(legacy.enter_restore_candidate(candidate.player, candidate.fx, null, saved, candidate.player.snapshot_state()), "default restore-constructor delegates to the legacy normal entry hook")
	_expect(legacy.normal_entries == 1 and legacy.entry_progress_refused and legacy.is_restore_candidate(), "legacy default construction runs once under real pending candidate guard")
	_expect(not legacy.finish_restore_candidate() and legacy.restore_state(saved) and legacy.finish_restore_candidate(), "legacy default also requires an actual quiet restore before finish")
	legacy.free()
	normal.free()


func _cache_and_rejection(donor: Variant) -> void:
	var before: Dictionary = donor.authority_state()
	_expect(game._snapshot_problem(later).is_empty(), "whole-snapshot validation constructs a fresh room2 candidate")
	if not game._validation_candidates.has("A1-L1"):
		_expect(false, "fresh validation candidate exists for comparison")
		return
	var old_candidate: WeakRef = weakref(game._validation_candidates["A1-L1"].level)
	_expect(game._snapshot_problem(initial).is_empty(), "next full snapshot validates different saved room1 topology")
	_expect(old_candidate.get_ref() == null and game._validation_candidates["A1-L1"].level.room_index == 1 and game._validation_candidates["A1-L1"].level.future_resource == null, "ID-only validation cache cannot reuse room2 bindings for room1")
	for kind: String in ["prefix", "resource_identity"]:
		var bad: Dictionary = later.duplicate(true)
		if kind == "prefix": bad.level.local.prefix = ["room-2"]
		else: bad.level.local.future_resource.resource_id = "test-only/foreign-resource"
		var disposals_before: int = Fixture.destroyed_ids.size()
		var result: Dictionary = game._prepare_snapshot(bad)
		_expect(result.is_empty() and not game.campaign_error.is_empty(), "malformed " + kind + " refuses native candidate preparation")
		_expect(Fixture.destroyed_ids.size() > disposals_before and not game._validation_candidates.has("A1-L1"), "rejected " + kind + " disposes partial native construction/cache")
		_expect(_same_authority(before, donor.authority_state()), "rejected " + kind + " cannot mutate the live donor")
	game.campaign_error = ""
	_expect(game._snapshot_problem(later).is_empty(), "fresh valid constructor can follow a rejected candidate")
	var identity_cache: WeakRef = weakref(game._validation_candidates["A1-L1"].level)
	var foreign_scene: Dictionary = later.duplicate(true)
	foreign_scene.scene_path = "res://tests/fixtures/foreign-restore-candidate.tscn"
	_expect(not game._snapshot_problem(foreign_scene).is_empty(), "foreign whole-snapshot scene identity fails before construction")
	_expect(identity_cache.get_ref() == null and game._validation_candidates.is_empty(), "early identity rejection also disposes previous hidden validation candidates")
	game._dispose_validation_candidates()
	_expect(_same_authority(before, donor.authority_state()), "all pure full-snapshot construction/validation leaves donor authority unchanged")
	await process_frame


func _expect_restored_later(label: String) -> void:
	var level: Variant = game.active_level
	_expect(level.normal_entries == 0 and level.restore_entries == 1 and level.quiet_commits == 1 and not level.is_restore_candidate(), label + " uses one restore constructor and one quiet commit/finish")
	_expect(level.constructor_pristine and level.constructor_progress_refused and level.activation_notifications == 0, label + " never replays normal entry, room activation or saved HP during construction")
	_expect(level.room_index == 2 and level.future_resource != null and level.recipient.field_owner == level.future_resource and level.recipient.actual_hero.get_ref() == game.player, label + " retains actual installed topology/Player/recipient bindings")
	_expect(game.player.hp == 17.0 and level.recipient.hp == 0.0 and level.recipient.dead and level.recipient.hit_count == 1 and level.player_hp_at_commit == 17.0, label + " restores actual dead and worn resources without healing")
	_expect(level.recipient.damage_notifications == 0 and level.recipient.defeat_notifications == 0 and level.activation_notifications == 0, label + " reconstruction is quiet")
	_expect(_same(game.capture_campaign_snapshot(), later), label + " equals complete original earned snapshot bit/type exactly")


func _new_shell() -> CinderCampaignShell:
	var result: CinderCampaignShell = Shell.new()
	result.configure_runtime(raw, TEST_ROOT + "campaign.json", TEST_ROOT + "settings.json", TEST_ROOT + "preferences.json")
	root.add_child(result)
	return result


func _settle() -> void:
	for _index: int in range(7): await process_frame


func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = Exact.stringify(left)
	return not encoded.is_empty() and encoded == Exact.stringify(right)


func _same_authority(left: Dictionary, right: Dictionary) -> bool:
	if not _same(left.local, right.local) or not _same(left.hero, right.hero): return false
	for key: String in left:
		if key not in ["local", "hero"] and left[key] != right.get(key): return false
	return true


func _guard(ok: bool, note: String) -> bool:
	_expect(ok, note)
	return ok


func _expect(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + note)


func _cleanup() -> void:
	for filename: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT + filename))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT))


func _finish() -> void:
	if is_instance_valid(game): game.free()
	paused = false
	Engine.max_fps = old_fps
	_cleanup()
	print("Restore candidate smoke: %d checks, %d failures (TEST ONLY native constructor/Shell paths)" % [checks, failures])
	quit(1 if failures else 0)
