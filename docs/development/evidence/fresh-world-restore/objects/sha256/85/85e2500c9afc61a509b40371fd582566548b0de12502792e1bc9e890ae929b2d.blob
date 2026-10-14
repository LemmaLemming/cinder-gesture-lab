extends SceneTree
## Focused native floor registration and public Shell lifecycle checks.
## Actual tiny native Level + public Shell flows; no campaign level acceptance.
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Level = preload("res://scripts/campaign/level.gd")
const Fixture = preload("res://tests/fixtures/restore_candidate_physics_level.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const FIXTURE_PATH: String = "res://tests/fixtures/restore_candidate_physics_level.tscn"
const TEST_ROOT: String = "user://test-restore-candidate-physics/"

class ObservedShell extends Shell:
	# Passive callback receipts, except one explicit returning-empty mutation
	# negative. The production validator and its pure Level hook are unchanged.
	var validation_observations: Array[Dictionary] = []
	var invalidate_after_valid_wire: String = ""
	var invalidated: bool = false
	func _snapshot_problem(snapshot: Dictionary) -> String:
		var error: String = super._snapshot_problem(snapshot)
		var wire: String = Exact.stringify(snapshot)
		var entry: Dictionary = _registered_snapshots.get(wire, {})
		var row: Dictionary = entry.get("validation", {})
		var candidate: Dictionary = row.get("candidate", {})
		var level: Variant = candidate.get("level")
		validation_observations.append({"wire": wire, "error": error, "id": level.get_instance_id() if is_instance_valid(level) else 0, "commits": level.quiet_commits if is_instance_valid(level) else -1})
		if error.is_empty() and not invalidated and wire == invalidate_after_valid_wire and is_instance_valid(level):
			invalidated = true
			level.floor_collision.disabled = true
		return error

var checks: int = 0
var failures: int = 0
var game: ObservedShell
var raw: Dictionary = {}
var initial: Dictionary = {}
var later: Dictionary = {}
var cancellation_ids: Array[int] = []
var nested_checked: bool = false
var callback_ran: bool = false
var old_fps: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	old_fps = Engine.max_fps
	_cleanup()
	Fixture.reset_observers()
	var legacy := Level.new()
	_expect(not legacy.restore_candidate_physics_registration_required(), "additive Level capability defaults false off-tree; legacy suite remains separate")
	legacy.free()
	var probe := Fixture.new()
	_expect(probe.restore_candidate_physics_registration_required(), "opt-in query is pure and available before scene-tree construction")
	probe.free()
	raw = JSON.parse_string(FileAccess.get_file_as_string(Registry.DATA_PATH))
	for row: Dictionary in raw.levels:
		if row.id == "A1-L1":
			row.scene_path = FIXTURE_PATH
			row.readiness = "accepted"
			row.accepted_commit = "a".repeat(40)
			row.api_revision = Registry.API_REVISION
	_new_shell()
	await _settle()
	game.menu.begin_story_requested.emit()
	await _settle()
	if not _guard(game.campaign_error.is_empty() and is_instance_valid(game.active_level), "public Begin creates TEST ONLY ordinary recipient: " + game.campaign_error):
		_finish(); return
	var ordinary: Variant = game.active_level
	_expect(ordinary.normal_entries == 1 and ordinary.restore_entries == 0, "ordinary Begin is not silently replaced by a restore constructor")
	initial = game.attempts.active_snapshot()
	if not _guard(not initial.is_empty() and initial.level.local.marker == 0, "real fresh snapshot/checkpoint exists"):
		_finish(); return
	await _earn_later()
	if later.is_empty(): _finish(); return

	var donor: Variant = game.active_level
	var donor_ref: WeakRef = weakref(donor)
	Fixture.entry_observer = _nested_and_exact_key_probe
	game.menu.continue_story_requested.emit()
	await _settle()
	Fixture.entry_observer = Callable()
	if not _guard(game.campaign_error.is_empty() and is_instance_valid(game.active_level), "public Continue installs exact earned packet: " + game.campaign_error):
		_finish(); return
	_expect(nested_checked, "real constructor ran nested validator/packet-key refusal probe")
	_expect(donor_ref.get_ref() == null and _same(game.capture_campaign_snapshot(), later), "Continue retires donor and restores the complete earned Player/local/Shell packet")
	_expect_installed("Continue")
	var validation_ids: Array[int] = []
	for row: Dictionary in game.validation_observations:
		if row.wire == Exact.stringify(later) and row.id != 0: validation_ids.append(row.id)
	_expect(not validation_ids.is_empty() and game.active_level.get_instance_id() not in validation_ids, "quiet-commit/install instance is separate from pristine callback validation custody")
	_expect(_live_fixture_count() == 1, "operation cleanup leaves only the actual installed native world alive")
	donor_ref = weakref(game.active_level)
	game.menu.retry_requested.emit()
	await _settle()
	if not _guard(game.campaign_error.is_empty() and is_instance_valid(game.active_level), "public Retry accepts earlier same-ID checkpoint: " + game.campaign_error):
		_finish(); return
	_expect(donor_ref.get_ref() == null and _same(game.capture_campaign_snapshot(), initial), "Retry selects its exact earlier marker/clock/resources rather than the later same-ID packet")
	_expect_installed("Retry")
	await _earn_later()
	if later.is_empty(): _finish(); return

	# Retry first validates the exact checkpoint for candidate preparation, then
	# Attempts.retry_snapshot and Store validate that packet again before save.
	# Mutate the pristine validation floor after the first accepted callback.
	donor = game.active_level
	var before: Dictionary = _donor_receipt()
	game.invalidate_after_valid_wire = Exact.stringify(initial)
	game.menu.retry_requested.emit()
	await _settle()
	_expect(game.invalidated and not game.campaign_error.is_empty() and game.campaign_error.to_lower().contains("floor"), "Retry's repeated checkpoint callback refuses the changed native floor after its first accepted validation")
	_expect(game.active_level == donor and _same(before, _donor_receipt()), "returning-empty callback mutation cannot change donor/Attempts/disk")
	var saw_accept: bool = false
	var saw_later_refusal: bool = false
	for row: Dictionary in game.validation_observations:
		if row.wire != game.invalidate_after_valid_wire: continue
		if row.error.is_empty(): saw_accept = true
		elif saw_accept: saw_later_refusal = true
	_expect(saw_later_refusal, "repeated exact-packet callbacks do not consume an accepted-result cache")
	game.invalidate_after_valid_wire = ""
	game.menu.retry_requested.emit()
	await _settle()
	if not _guard(game.campaign_error.is_empty(), "explicit public Retry replaces failed native scope: " + game.campaign_error):
		_finish(); return

	before = _donor_receipt()
	donor = game.active_level
	var events_before: int = Fixture.entry_events.size()
	Fixture.reject_next_entry = true
	game.menu.retry_requested.emit()
	await _settle()
	_expect(not game.campaign_error.is_empty() and Fixture.entry_events.size() > events_before, "real registered constructor rejection retains its original failure")
	_expect(game.active_level == donor and _same(before, _donor_receipt()), "constructor failure preserves donor/Attempts/disk")
	var rejected_id: int = Fixture.entry_events[events_before].id if Fixture.entry_events.size() > events_before else 0
	_expect(rejected_id in Fixture.destroyed_ids, "rejected entered native candidate is actually disposed")
	game.menu.retry_failed_operation_requested.emit()
	await _settle()
	if not _guard(game.campaign_error.is_empty() and is_instance_valid(game.active_level), "public Retry Pending uses a fresh recipient after rejection: " + game.campaign_error):
		_finish(); return
	_expect(game.active_level.get_instance_id() != rejected_id, "failed candidate is never reentered or installed")
	_expect_installed("Retry Pending")
	await _earn_later()
	if later.is_empty(): _finish(); return

	# Keep the valid primary byte-exact while replacing only its unused backup
	# with a transport-valid but semantically malformed TEST ONLY packet.
	var primary_bytes: PackedByteArray = FileAccess.get_file_as_bytes(TEST_ROOT + "campaign.json")
	var bad_backup: Dictionary = game.attempts.state()
	bad_backup.story.snapshot.level.local.marker = 2
	var backup_store = Store.new(TEST_ROOT + "campaign.json.bak")
	if not _guard(backup_store.write_payload(bad_backup), "test Store writes semantically bad unused backup"):
		_finish(); return
	_expect(FileAccess.get_file_as_bytes(TEST_ROOT + "campaign.json") == primary_bytes, "unused-backup injection preserves actual valid primary bytes")

	# Startup load is a real disk read. The callback schedules ordinary Menu
	# input during the raw-world wait; it never sets a readiness/latch flag.
	game.free()
	callback_ran = false
	Fixture.raw_ready_observer = _startup_ready
	_new_shell()
	await _settle()
	Fixture.raw_ready_observer = Callable()
	_expect(callback_ran and game.campaign_error.is_empty(), "startup keeps valid primary despite bad unused backup and drains queued public Continue once")
	_expect(is_instance_valid(game.active_level) and _same(game.capture_campaign_snapshot(), later), "startup cannot execute queued Continue against default/unloaded Attempts state")
	_expect_installed("startup Continue")
	_expect(_live_fixture_count() == 1, "startup validation worlds are cleaned without deleting installed world")

	callback_ran = false
	Fixture.raw_ready_observer = _retry_ready
	game.menu.continue_story_requested.emit()
	await _settle()
	Fixture.raw_ready_observer = Callable()
	_expect(callback_ran and game.campaign_error.is_empty() and _same(game.capture_campaign_snapshot(), initial), "Retry arriving during native wait cancels stale Continue and restores checkpoint")
	for id: int in cancellation_ids:
		_expect(id in Fixture.destroyed_ids and not _has_entry(id) and id not in Fixture.commit_ids, "canceled raw recipient has no entry/commit and is disposed")
	_expect(_live_fixture_count() == 1, "cancellation leaves no hidden own-world recipient")

	# A malformed complete packet is untrusted disk input, written through a
	# separate test Store. Original Store validators/fallback still select it.
	var good_state: Dictionary = game.attempts.state()
	var good_snapshot: Dictionary = game.attempts.active_snapshot()
	game.free()
	var bad_state: Dictionary = good_state.duplicate(true)
	bad_state.story.snapshot.level.local.marker = 2
	var store = Store.new(TEST_ROOT + "campaign.json")
	if not _guard(store.write_payload(bad_state), "test Store publishes malformed primary with original good backup"):
		_finish(); return
	_new_shell()
	await _settle()
	_expect(game.attempts.state().story != null and _same(game.attempts.active_snapshot(), good_snapshot), "semantic malformed primary cannot borrow good packet readiness; actual backup remains authoritative")
	game.menu.continue_story_requested.emit()
	await _settle()
	if not _guard(is_instance_valid(game.active_level) and _same(game.capture_campaign_snapshot(), good_snapshot), "public Continue uses recovered exact packet"):
		_finish(); return

	callback_ran = false
	Fixture.raw_ready_observer = _delete_ready
	game.menu.continue_story_requested.emit()
	await _settle()
	Fixture.raw_ready_observer = Callable()
	_expect(callback_ran and not is_instance_valid(game) and _live_fixture_count() == 0, "Shell deletion during raw registration leaves no stale install or live native candidate")
	for event: Dictionary in Fixture.entry_events:
		var count: int = 0
		for other: Dictionary in Fixture.entry_events:
			if other.id == event.id: count += 1
		_expect(count == 1, "each actual opted instance has at most its sole constructor entry")
	_finish()

func _earn_later() -> void:
	later = {}
	game.menu.resume_requested.emit()
	await create_timer(0.08).timeout
	var level: Variant = game.active_level
	if not _guard(not paused and level.advance_marker(), "public Resume earns a real marker change in the native donor"): return
	game.player.take_damage(7.0, Vector3.ZERO)
	game.request_pause()
	await _settle()
	if not _guard(game.campaign_error.is_empty(), "public Pause saves earned packet: " + game.campaign_error): return
	later = game.attempts.active_snapshot()
	_expect(later.level.local.marker == 1 and later.level.local.clock_s > 0.0 and later.player.resources.hp < initial.player.resources.hp and _same(game.attempts.state().story.checkpoint, initial), "earned current snapshot differs from preserved checkpoint without a forged packet")

func _nested_and_exact_key_probe(_level: Variant) -> void:
	if nested_checked: return
	nested_checked = true
	var before: Dictionary = _donor_receipt()
	_expect(game._registered_snapshots.has(Exact.stringify(initial)) and game._registered_snapshots.has(Exact.stringify(later)), "same-ID checkpoint and current full packets have separate exact construction keys")
	var changed: Dictionary = later.duplicate(true)
	changed.shell.input_sequence += 1
	_expect(not game._registered_snapshots.has(Exact.stringify(changed)), "one Shell field change cannot alias the warmed exact full packet")
	_expect(not game.attempts.record_snapshot(later), "constructor-triggered public nested save refuses validation reentry")
	_expect(not game._snapshot_problem(changed).is_empty(), "changed packet cannot cold-build or consume the outer in-progress recipient")
	_expect(_same(before, _donor_receipt()), "nested refusal preserves donor/Attempts/disk and outer operation custody")

func _startup_ready(_level: Variant) -> void:
	Fixture.raw_ready_observer = Callable()
	_startup_during_wait.call_deferred()

func _startup_during_wait() -> void:
	callback_ran = true
	_expect(game._registration_pending and game.active_level == null and paused, "actual startup raw-world wait is latched before any active donor")
	game.menu.resume_requested.emit()
	_expect(paused and game.active_level == null, "always-mode Resume cannot unpause startup loading")
	game.menu.continue_story_requested.emit()
	_expect(game.active_level == null and paused, "queued Continue cannot install before startup validation returns")

func _retry_ready(_level: Variant) -> void:
	Fixture.raw_ready_observer = Callable()
	_retry_during_wait.call_deferred()

func _retry_during_wait() -> void:
	callback_ran = true
	var before: Dictionary = _donor_receipt()
	_expect(game._registration_pending and paused, "public cancellation occurs inside the actual paused raw-world wait")
	for ref: WeakRef in Fixture.created:
		var level: Variant = ref.get_ref()
		if is_instance_valid(level) and level != game.active_level: cancellation_ids.append(level.get_instance_id())
	game.menu.resume_requested.emit()
	_expect(paused and _same(before, _donor_receipt()), "Resume cannot drift live donor during registration")
	game.menu.retry_requested.emit()
	_expect(paused and _same(before, _donor_receipt()), "queued Retry invalidates raw scope before altering donor authority")

func _delete_ready(_level: Variant) -> void:
	Fixture.raw_ready_observer = Callable()
	_delete_during_wait.call_deferred()

func _delete_during_wait() -> void:
	callback_ran = true
	_expect(game._registration_pending and paused, "Shell disposal occurs during real raw registration wait")
	game.free()

func _new_shell() -> void:
	game = ObservedShell.new()
	game.configure_runtime(raw, TEST_ROOT + "campaign.json", TEST_ROOT + "settings.json", TEST_ROOT + "preferences.json")
	root.add_child(game)

func _settle() -> void:
	for _index: int in range(24): await process_frame

func _expect_installed(label: String) -> void:
	var level: Variant = game.active_level
	_expect(level.normal_entries == 0 and level.restore_entries == 1 and level.quiet_commits == 1 and not level.is_restore_candidate(), label + " has one entry/quiet commit/finish")
	_expect(level.constructor_floor_rid == level.floor_body.get_rid() and level.constructor_world == level.get_world_3d() and level._floor_error(true).is_empty(), label + " retains the exact constructor body RID/world and actual native floor hit")

func _donor_receipt() -> Dictionary:
	var donor: Variant = game.active_level
	var disk: Dictionary = {}
	for name: String in ["campaign.json", "campaign.json.bak"]:
		var path: String = TEST_ROOT + name
		disk[name] = FileAccess.get_file_as_bytes(path).hex_encode() if FileAccess.file_exists(path) else "ABSENT"
	return {"level_id": donor.get_instance_id() if is_instance_valid(donor) else 0, "player_id": game.player.get_instance_id() if is_instance_valid(game.player) else 0, "native": donor.authority_wire() if is_instance_valid(donor) else "", "input": Exact.stringify(game.get_input_observation_state()), "shell": Exact.stringify(game._shell_state()), "attempts": Exact.stringify(game.attempts.state()), "disk": disk}

func _has_entry(id: int) -> bool:
	for row: Dictionary in Fixture.entry_events:
		if row.id == id: return true
	return false

func _live_fixture_count() -> int:
	var result: int = 0
	for ref: WeakRef in Fixture.created:
		if is_instance_valid(ref.get_ref()): result += 1
	return result

func _same(left: Variant, right: Variant) -> bool:
	var wire: String = Exact.stringify(left)
	return not wire.is_empty() and wire == Exact.stringify(right)

func _guard(ok: bool, note: String) -> bool:
	_expect(ok, note)
	return ok

func _expect(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + note)

func _cleanup() -> void:
	for name: String in ["campaign.json", "campaign.json.bak", "campaign.json.bak.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROOT))

func _finish() -> void:
	Fixture.raw_ready_observer = Callable()
	Fixture.entry_observer = Callable()
	if is_instance_valid(game): game.free()
	paused = false
	Engine.max_fps = old_fps
	_cleanup()
	print("Restore candidate physics smoke: %d checks, %d failures (TEST ONLY core paused native floor)" % [checks, failures])
	quit(1 if failures else 0)
