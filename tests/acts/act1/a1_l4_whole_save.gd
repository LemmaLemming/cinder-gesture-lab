extends SceneTree
## Focused actual CampaignShell transport. TEST registry/predecessor handoffs,
## initial injured resources, public actor injuries and Hero placement are setup.
## No earned route, production registration, art/kit/balance/performance claim.
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Layout = preload("res://scripts/acts/act1/selenite_court_layout.gd")
const ScenePath: String = "res://scenes/acts/act1/a1_l4.tscn"
const ScriptPath: String = "res://scripts/acts/act1/selenite_court.gd"
const LocalKeys: Array[String] = ["api_revision", "schema_version", "world_revision", "room", "formation", "awaiting_room", "roundel_demonstrated", "helpers_once", "helper_stage", "entry_records", "entry_outcomes", "actors", "scheduler", "roundel", "framing", "king_intro"]
const SourceIds: Array[String] = ["court-curtain-guard", "court-formation-west", "court-formation-east", "court-approach-west", "court-approach-east", "court-king", "court-helper-west", "court-helper-east"]
const WatchdogMs: int = 120000
# Two extra real Shell reconstruction/disposal cases add bounded wall work,
# retaining all original8second observations and all native timing/guards.
const ContactObserverAllowanceMs: int = 60000
var game: CinderCampaignShell
var fresh: CinderCampaignShell
var candidate: Dictionary = {}
var raw: Dictionary = {}
var registry_text: String = ""
var test_root: String = ""
var checks: int = 0
var failures: int = 0
var events: int = 0
var quiet_events: int = 0
var started_ms: int = 0
var finishing: bool = false
var aborted: bool = false
var old_fps: int
var old_audio: AudioBusLayout
var setups: Array[Dictionary] = []
var receipts: Array[Dictionary] = []
var first_failure: Dictionary = {}


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	old_fps = Engine.max_fps
	old_audio = AudioServer.generate_bus_layout()
	test_root = "user://test-act1-court-save-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	process_frame.connect(_watchdog)
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	registry_text = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var parsed: Variant = JSON.parse_string(registry_text)
	if not _expect(parsed is Dictionary and parsed.get("levels") is Array, "actual registry supplies isolated TEST metadata"):
		await _finish(); return
	raw = parsed.duplicate(true)
	for entry: Dictionary in raw.levels:
		if entry.id in ["A1-L1", "A1-L2", "A1-L3", "A1-L4"]:
			entry.scene_path = ScenePath if entry.id == "A1-L4" else "res://tests/fixtures/campaign/live_%s.tscn" % String(entry.id).to_lower().replace("-", "_")
			entry.readiness = "accepted"; entry.accepted_commit = "f".repeat(40); entry.api_revision = Registry.API_REVISION
	game = _new_shell()
	if game == null or not await _settle(): await _finish(); return
	if not _expect(paused and game.active_level == null and game.player == null and game.menu.page_name() == "title", "real isolated Title starts without an installed world") or not _press(game, "JourneyButton") or not await _settle():
		await _finish(); return
	game.menu.select_level("A1-L1")
	if not _press(game, "LevelCardAction") or not await _settle(): await _finish(); return
	# Explicit first-fixture resource setup. Later native restores must retain
	# their actual saved resources; shared passive reload is never disabled.
	if not _expect(game.active_level.level_id == "A1-L1" and paused, "actual public Begin installs disclosed generic TEST predecessor"):
		await _finish(); return
	game.player.hp = 23.0; game.player.shells = 0
	setups.append({"kind": "TEST initial predecessor resources", "hp": 23.0, "shells": 0})
	for id: String in ["A1-L1", "A1-L2", "A1-L3"]:
		if not _expect(game.active_level.level_id == id and game.active_level.scene_file_path == "res://tests/fixtures/campaign/live_%s.tscn" % id.to_lower().replace("-", "_"), "only disclosed generic predecessor is installed: " + id): await _finish(); return
		if not _expect(game.active_level.request_completion("TEST-court-entry"), "TEST predecessor public completion is setup") or not await _settle(): await _finish(); return
		if not _expect(game.active_level.request_contact_exit("TEST-court-entry-contact", game.player), "TEST predecessor public same-Hero exit is setup") or not await _settle(): await _finish(); return
	if not _expect(paused and game.active_level.scene_file_path == ScenePath and game.active_level.get_script().resource_path == ScriptPath and game.active_level.restore_candidate_construction_required(), "real Shell installs actual whole court and opts into fresh construction") or not _bindings(game) or not _scenic_state_refusal(): await _finish(); return
	_watch(game.active_level, game.player, false)
	var pristine: Dictionary = game.capture_campaign_snapshot()
	if not _closed(pristine) or not _expect(pristine.level.local.room == 0 and pristine.level.local.actors["court-curtain-guard"].dormant == false and pristine.level.local.actors["court-king"].dormant == true and pristine.player.resources.hp == 23.0 and pristine.player.resources.shells == 0 and pristine.level.local.scheduler.clock_s == 0.0 and pristine.level.local.scheduler.reservations.is_empty(), "pristine actual entrance retains injured carryover/zeroammo and future dormant King/helpers"):
		await _finish(); return
	var protected_wire: String = Exact.stringify(game.attempts.state().story.checkpoint)
	receipts.append({"stage": "pristine entrance", "exact_snapshot": Exact.stringify(pristine)})
	if not _expect(protected_wire == Exact.stringify(pristine) and _durable(game), "real initial protected checkpoint and format2 disk contain the whole entrance unit") or not _direct_candidate(pristine): await _finish(); return
	if not await _resume(game): await _finish(); return
	if not await _wait(func() -> bool: return _warning("court-curtain-guard"), "real initial stationary warning", 8.0): await _finish(); return
	game.player.shells = 0
	setups.append({"kind": "TEST zero shells immediately before entrance pause", "clock_s": _scheduler().get_clock()})
	if not await _pause(): await _finish(); return
	var warning: Dictionary = game.capture_campaign_snapshot()
	if not _closed(warning) or not _expect(warning.player.resources.hp == 23.0 and warning.player.resources.shells == 0 and not warning.level.local.actors["court-curtain-guard"].reservation_id.is_empty() and Exact.stringify(game.attempts.state().story.checkpoint) == protected_wire and _durable(game), "public Pause saves exact warning/HP/zeroammo without replacing earlier pristine Retry"):
		await _finish(); return
	receipts.append({"stage": "actual entrance warning", "exact_snapshot": Exact.stringify(warning), "exact_earlier_checkpoint": protected_wire})
	var frozen: Dictionary = _donor()
	await create_timer(0.08, true).timeout
	if not _expect(_donor() == frozen, "paused source/Player/native clocks/attempt/UI/effects/disk freeze exactly") or not _malformed(warning) or not _direct_candidate(warning) or not await _fresh_continue(warning): await _finish(); return
	var old_ids: Dictionary = _identities(game.active_level, game.player)
	var old_refs: Array[WeakRef] = _descendant_refs(game.world)
	game.request_retry()
	if not await _settle(): await _finish(); return
	if not _expect(paused and game.menu.page_name() == "resume" and Exact.stringify(game.capture_campaign_snapshot()) == protected_wire and game.player.hp == 23.0 and game.player.shells == 0 and _identities(game.active_level, game.player) != old_ids and _all_freed(old_refs) and _durable(game), "public earlier Retry installs pristine native recipients with exact protected resources/no refill and disposes later warning world") or not _bindings(game): await _finish(); return
	if "--representative-helpers" in OS.get_cmdline_user_args() or "--moving-helper-save" in OS.get_cmdline_user_args() or "--moving-king-intro-save" in OS.get_cmdline_user_args() or "--terminal-save" in OS.get_cmdline_user_args():
		if not await _representative_helpers(): await _finish(); return
	await _finish()


func _scenic_state_refusal() -> bool:
	var art: Node3D = game.active_level.get("_whole_art")
	var original: Dictionary = art.call("presentation_state")
	var before: Dictionary = _probe(game.active_level, game.player)
	if not _expect(art.call("set_presentation", "king2", true, "open") == true, "TEST supported scenic-state mismatch is actually installed"): return false
	var rejected: Dictionary = game.capture_campaign_snapshot()
	if not _expect(rejected.is_empty() and game.active_level.last_snapshot_error.contains("scenic presentation") and _probe(game.active_level, game.player) == before, "supported wrong scenic stage cannot authorize capture or mutate native gameplay"): return false
	if not _expect(art.call("set_presentation", original.stage, original.helpers_open, original.exterior_state) == true and not game.capture_campaign_snapshot().is_empty() and _probe(game.active_level, game.player) == before, "restore original scenic state without changing native clocks/HP/progress"): return false
	return true


func _new_shell() -> CinderCampaignShell:
	var shell: CinderCampaignShell = Shell.new()
	if not _expect(shell.configure_runtime(raw, test_root + "campaign.json", test_root + "settings.json", test_root + "preferences.json"), "real Shell uses process-isolated canonical save/settings/preference stores"):
		shell.free(); return null
	root.add_child(shell)
	return shell


func _representative_helpers() -> bool:
	# Representative state uses real native lifecycle/progression. Public TEST
	# injuries/placement replace an earned route; no phase/history/clock is seeded.
	if not await _resume(game) or not _damage("court-curtain-guard", 24.0) or not await _checkpoint("court-after-curtain"): return false
	if not await _place(Vector3(0, 0.1, -7)) or not await _wait(func() -> bool: return int(game.active_level.get("room")) == 1, "actual formation activation", 8.0): return false
	for id: String in Layout.ROOM_SOURCE_IDS[1]:
		if not _damage(id, 24.0): return false
	if not await _checkpoint("court-after-formation") or not await _place(Vector3(0, 0.1, -17)): return false
	if not await _wait(func() -> bool: return int(game.active_level.get("room")) == 2 and game.active_level.get("roundel").state().status == "running", "actual quiet roundel begins", 8.0): return false
	if not _expect(_sources()["court-approach-west"].get("dormant") and _sources()["court-approach-east"].get("dormant"), "quiet demonstration retains future guards dormant"): return false
	if not await _wait(func() -> bool: return game.active_level.get("_roundel_demonstrated") == true and not _sources()["court-approach-west"].get("dormant") and not _sources()["court-approach-east"].get("dormant"), "native complete roundel exposes actual combination", 20.0): return false
	for id: String in Layout.ROOM_SOURCE_IDS[2]:
		if not _damage(id, 24.0): return false
	if not await _checkpoint("court-after-approach") or not await _place(Vector3(0, 0.1, -26)): return false
	if not await _wait(func() -> bool: return int(game.active_level.get("room")) == 3 and game.active_level.current_checkpoint().id == "court-boss-entry", "actual broad native Area enters King epoch", 8.0, true): return false
	if "--terminal-save" in OS.get_cmdline_user_args():
		return await _terminal_save()
	if "--moving-king-intro-save" in OS.get_cmdline_user_args():
		# Do not spend eight arbitrary draw frames inside the new half-second
		# observation window. Its actual durable checkpoint is checked after the
		# genuine moving boundary, without changing the native intro deadline.
		if paused and not await _resume(game): return false
		return await _unfinished_king_intro_transport()
	if not await _settle(): return false
	if paused and not await _resume(game): return false
	if not _damage("court-king", 40.0): return false
	if "--moving-helper-save" in OS.get_cmdline_user_args(): return await _unfinished_helper_transport()
	if not await _wait(func() -> bool: return int(game.active_level.get("room")) == 4 and game.active_level.get("helper_stage") == "done", "actual once-only native helper entry completes", 12.0) or not await _checkpoint("court-king-phase-two"): return false
	if not _damage("court-helper-west", 5.0): return false
	game.player.shells = 0
	setups.append({"kind": "TEST zero shells immediately before representative helper pause", "clock_s": _scheduler().get_clock()})
	if not await _pause(): return false
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _closed(saved) or not _expect(saved.level.local.room == 4 and saved.level.local.helpers_once and saved.level.local.helper_stage == "done" and saved.level.local.actors["court-king"].hp == 40.0 and saved.level.local.actors["court-helper-west"].hp == 19.0 and saved.level.local.actors["court-helper-east"].hp == 24.0 and saved.player.resources.shells == 0 and saved.level.local.scheduler.encounter_id == "court-king" and not saved.level.progress.completed and _durable(game), "representative later save retains real injured helper/King, original native epoch and spent earlier actors"): return false
	receipts.append({"stage": "TEST representative King/helpers", "exact_snapshot": Exact.stringify(saved)})
	if not _direct_candidate(saved) or not await _fresh_continue(saved): return false
	var earlier: Dictionary = game.attempts.state().story.checkpoint.duplicate(true)
	var earlier_wire: String = Exact.stringify(earlier)
	receipts.append({"stage": "actual protected earlier helper checkpoint", "exact_snapshot": earlier_wire})
	var ids: Dictionary = _identities(game.active_level, game.player)
	game.request_retry()
	if not await _settle(): return false
	return _expect(paused and Exact.stringify(game.capture_campaign_snapshot()) == earlier_wire and _identities(game.active_level, game.player) != ids and game.player.snapshot_state().resources == earlier.player.resources and _durable(game), "representative Retry restores the actual earlier phase checkpoint/resources; no claimed current-state heal or fabricated checkpoint") and _bindings(game)



func _terminal_save() -> bool:
	# Only this opt-in extends the representative native progression to terminal
	# Save/contact. The unchanged entrance still declares HP23/zero initial ammo;
	# passive reload stays enabled and every later resource is observed, not reset.
	if not _expect(game.registry.next_main("A1-L4") == "A1-L5" and game.registry.scene_error("A1-L5") == "Level is awaiting integration", "terminal opt-in discloses the actual unavailable next frontier without altering TEST metadata"): return false
	var original_ids: Dictionary = _identities(game.active_level, game.player)
	var completions: Array[Dictionary] = []
	var contacts: Array[Dictionary] = []
	_terminal_watch(game.active_level, completions, contacts)
	if paused and not await _resume(game): return false
	if not await _wait(func() -> bool: return game.active_level.get("king_intro").stage == "done", "actual room3 King intro completes before any terminal-mode King injury", 12.0): return false
	var intro: Dictionary = (game.active_level.get("king_intro") as Dictionary).duplicate(true)
	var record: Dictionary = intro.record
	var goal: Vector3 = record.get("to", Vector3.ZERO)
	var endpoint: Vector3 = intro.outcome.get("endpoint", Vector3.ZERO)
	var king: CharacterBody3D = _sources()["court-king"]
	if not _expect(Codec.keys_error(record, ["active", "from", "to", "start_s", "end_s", "speed"]).is_empty() and record.active and record.from is Vector3 and record.to is Vector3 and record.to == record.from + Vector3.BACK * 0.7 and record.speed == 1.4 and record.end_s == record.start_s + 0.7 / 1.4 and intro.outcome.outcome == "complete" and Vector2(endpoint.x, endpoint.z).distance_to(Vector2(goal.x, goal.z)) <= 0.005 and _scheduler().get_clock() >= record.end_s and king.get("hp") == 80.0 and not king.get("dead") and not game.active_level.get("_helpers_once"), "terminal setup retains the real completed .7-unit King step at1.4/.5 and untouched80HP before helper birth"): return false
	var intro_wire: String = Exact.stringify(_portable(intro))
	# The public Player snapshot is paused-only. This live receipt observes only
	# the actual public HP/ammo fields, without forcing a new pause or snapshot.
	receipts.append({"stage": "terminal opt-in actual room3 intro completed", "intro": _portable(intro), "initial_resources_declared": {"hp": 23.0, "shells": 0}, "actual_current_resources": {"hp": game.player.hp, "shells": game.player.shells}})
	if not await _place(Vector3(0, 0.1, -28.2)) or not _damage("court-king", 40.0): return false
	if not await _wait(func() -> bool: return _moving_helpers(), "actual once-born finite helpers move before terminal completion", 12.0): return false
	var entries: Dictionary = (game.active_level.get("_entry_records") as Dictionary).duplicate(true)
	for id: String in ["court-helper-west", "court-helper-east"]:
		var entry: Dictionary = entries[id]
		var actor: CharacterBody3D = _sources()[id]
		if not _expect(Codec.keys_error(entry, ["active", "from", "to", "start_s", "end_s", "speed"]).is_empty() and entry.active and entry.from is Vector3 and entry.to == entry.from + Vector3.BACK * 0.7 and entry.speed == 1.4 and entry.end_s == entry.start_s + 0.7 / 1.4 and actor.get("hp") == 24.0 and not actor.get("dead") and actor.velocity.z > 0.0, "terminal setup observes the original real half-second moving helper: " + id): return false
	var entries_wire: String = Exact.stringify(_portable(entries))
	if not await _wait(func() -> bool: return int(game.active_level.get("room")) == 4 and game.active_level.get("helper_stage") == "done", "actual terminal-mode helper pair stops at its original phase boundary", 12.0, true) or not await _checkpoint("court-king-phase-two"): return false
	var earlier: Dictionary = game.attempts.state().story.checkpoint.duplicate(true)
	var earlier_wire: String = Exact.stringify(earlier)
	if not _closed(earlier) or not _expect(earlier.level.progress.checkpoint_id == "court-king-phase-two" and not earlier.level.progress.completed and earlier.level.progress.contact_exit_id == "" and earlier.level.local.room == 4 and earlier.level.local.helpers_once and earlier.level.local.helper_stage == "done" and earlier.level.local.actors["court-king"].hp == 40.0 and earlier.player.resources.hp == 23.0 and _identities(game.active_level, game.player) == original_ids, "terminal mode protects the actual earlier incomplete phase checkpoint/resources and original native cast") or not _terminal_histories(earlier, intro_wire, entries_wire): return false
	for id: String in ["court-helper-west", "court-helper-east"]:
		var outcome: Dictionary = earlier.level.local.entry_outcomes[id]
		var actor: Dictionary = earlier.level.local.actors[id]
		var position: Vector3 = Codec.read_vector3(actor.motion.position)
		var entry_goal: Vector3 = Codec.read_vector3(earlier.level.local.entry_records[id].to)
		if not _expect(outcome.outcome == "complete" and actor.hp == 24.0 and not actor.dead and actor.motion.velocity == [0.0, 0.0, 0.0] and Vector2(position.x, position.z).distance_to(Vector2(entry_goal.x, entry_goal.z)) <= 0.005 and earlier.level.local.scheduler.clock_s >= earlier.level.local.entry_records[id].end_s, "actual protected checkpoint retains stopped original full-HP helper endpoint: " + id): return false
	receipts.append({"stage": "terminal opt-in protected actual earlier phase checkpoint", "exact_snapshot": earlier_wire})
	if not _damage("court-king", 40.0) or not await _wait(func() -> bool: return game.active_level.is_completed(), "actual public terminal King injury requests completion", 8.0, true) or not await _settle(): return false
	if paused:
		if not _expect(game.menu.page_name() == "resume", "only the actual completed Resume page may precede terminal Pause") or not await _resume(game): return false
	if not await _pause(): return false
	var available: Dictionary = game.capture_campaign_snapshot()
	if not _closed(available) or not _terminal_available(available) or not _terminal_histories(available, intro_wire, entries_wire) or not _expect(completions.size() == 1 and contacts.is_empty() and Exact.stringify(game.attempts.state().story.checkpoint) == earlier_wire and available.player.resources.hp == earlier.player.resources.hp and _durable(game), "public completed available-contact Save is exact/durable, completes once and preserves earlier Retry/resources"): return false
	var completed_main: Array = game.attempts.state().completed_main.duplicate(true)
	receipts.append({"stage": "actual completed available-contact Save", "exact_snapshot": Exact.stringify(available), "exact_earlier_checkpoint": earlier_wire, "completion_events": completions.duplicate(true), "completed_main": completed_main})
	if not _direct_candidate(available) or not await _terminal_replace_continue(available, earlier_wire, "completed available-contact"): return false
	_terminal_watch(game.active_level, completions, contacts)
	if not _terminal_available(game.capture_campaign_snapshot()) or not _expect(completions.size() == 1 and contacts.is_empty(), "quiet fresh completed Continue does not replay completion or fabricate contact") or not await _resume(game): return false
	if not await _place(Vector3(0, 0.1, -33.8)) or not await _wait(func() -> bool: return (game.active_level.get_node("ExitArea") as Area3D).monitoring and game.active_level.get("_exit_cue").state().state == "available", "local approach exposes the full actual available exterior contact", 8.0) or not await _pause(): return false
	var local_available: Dictionary = game.capture_campaign_snapshot()
	if not _closed(local_available) or not _terminal_available(local_available) or not _terminal_histories(local_available, intro_wire, entries_wire) or not _expect(completions.size() == 1 and contacts.is_empty() and _durable(game), "local available-contact Save is durable without another completion or premature contact"): return false
	receipts.append({"stage": "actual local available-contact Save", "exact_snapshot": Exact.stringify(local_available)})
	if "--contact-observer-boundaries" in OS.get_cmdline_user_args():
		if not await _terminal_contact_observer_boundaries(local_available, earlier_wire): return false
	if not _direct_candidate(local_available) or not await _terminal_replace_continue(local_available, earlier_wire, "local available-contact"): return false
	_terminal_watch(game.active_level, completions, contacts)
	if not _terminal_available(game.capture_campaign_snapshot()) or not await _resume(game): return false
	if not await _terminal_contact(contacts): return false
	# The canonical exit operation commits the contact snapshot before attempting
	# unavailable A1-L5. Preserve the actual failed operation and its exact error;
	# no private operation/error clearing and no new accepted successor is seeded.
	if not await _wait(func() -> bool: return not game.get("_draining") and not game.get("_drain_queued") and (game.get("_operations") as Array).is_empty(), "actual exterior contact drain closes", 8.0, true): return false
	var pending: Array = game.get("_failed_operations") as Array
	if not _expect(paused and game.menu.page_name() == "pause" and game.campaign_error == "Level is awaiting integration" and pending.size() == 1 and pending[0].operation == "exit" and pending[0].level_id == "A1-L4" and contacts.size() == 1 and completions.size() == 1, "actual once-only contact preserves the expected unavailable-next exit failure without a duplicate contact or completion"): return false
	var contacted: Dictionary = game.attempts.story_snapshot()
	var live_contact: Dictionary = game.capture_campaign_snapshot()
	if not _closed(contacted) or not _expect(Exact.stringify(live_contact) == Exact.stringify(contacted) and contacted.level.progress.completed and contacted.level.progress.completion_id == "court-clear" and contacted.level.progress.contact_exit_id == "court-exterior" and (game.active_level.get("_whole_art") as Node3D).call("presentation_state").exterior_state == "open" and Exact.stringify(game.attempts.state().story.checkpoint) == earlier_wire and game.attempts.state().completed_main == completed_main and _durable(game), "canonical contact operation saves the exact real overlapped terminal unit to format2 before unavailable successor construction") or not _terminal_histories(contacted, intro_wire, entries_wire): return false
	receipts.append({"stage": "actual exterior contact Save before unavailable-next failure", "exact_snapshot": Exact.stringify(contacted), "exact_earlier_checkpoint": earlier_wire, "contact_events": contacts.duplicate(true), "observed_expected_campaign_error": game.campaign_error, "preserved_failed_operations": _portable(pending), "scope": "actual contact persistence; no successor transition acceptance"})
	if not await _terminal_replace_continue(contacted, earlier_wire, "latched exterior contact"): return false
	_terminal_watch(game.active_level, completions, contacts)
	var restored_contact: Dictionary = game.capture_campaign_snapshot()
	if not _closed(restored_contact) or not _expect((game.active_level.get_node("ExitArea") as Area3D).monitoring == false and (game.active_level.get("_whole_art") as Node3D).call("presentation_state").exterior_state == "open" and restored_contact.level.progress.contact_exit_id == "court-exterior" and contacts.size() == 1 and completions.size() == 1 and (game.get("_failed_operations") as Array).is_empty(), "fresh Continue restores the spent latched contact without another event or an inherited pending operation"): return false
	var ids: Dictionary = _identities(game.active_level, game.player)
	var refs: Array[WeakRef] = _descendant_refs(game.world)
	game.request_retry()
	if not await _settle(): return false
	if not _expect(paused and game.menu.page_name() == "resume" and Exact.stringify(game.capture_campaign_snapshot()) == earlier_wire and _identities(game.active_level, game.player) != ids and _all_freed(refs) and game.player.snapshot_state().resources == earlier.player.resources and game.attempts.state().completed_main == completed_main and contacts.size() == 1 and completions.size() == 1 and _durable(game), "public earlier Retry restores exact incomplete phase state/resources with fresh recipients, retains recorded completion and disposes contacted world"): return false
	receipts.append({"stage": "actual earlier phase Retry after terminal contact Continue", "exact_snapshot": Exact.stringify(game.capture_campaign_snapshot()), "completion_events": completions.duplicate(true), "contact_events": contacts.duplicate(true), "completed_main": completed_main})
	return _bindings(game)


func _terminal_watch(target: CinderLevel, completions: Array[Dictionary], contacts: Array[Dictionary]) -> void:
	target.completion_requested.connect(func(id: String, complete_id: String) -> void: completions.append({"level_id": id, "completion_id": complete_id}))
	target.contact_exit_requested.connect(func(id: String, exit_id: String) -> void: contacts.append({"level_id": id, "exit_id": exit_id}))


func _terminal_histories(saved: Dictionary, intro_wire: String, entries_wire: String) -> bool:
	if not _expect(saved.level.local.king_intro.stage == "done" and saved.level.local.king_intro.outcome.outcome == "complete" and Exact.stringify(saved.level.local.king_intro) == intro_wire and saved.level.local.helpers_once and saved.level.local.helper_stage == "done" and Exact.stringify(saved.level.local.entry_records) == entries_wire and saved.level.local.entry_outcomes.size() == 2, "terminal transport preserves original completed intro and once-only finite helper history without rebase"): return false
	for id: String in ["court-helper-west", "court-helper-east"]:
		var outcome: Dictionary = saved.level.local.entry_outcomes[id]
		var endpoint: Vector3 = Codec.read_vector3(outcome.endpoint)
		var goal: Vector3 = Codec.read_vector3(saved.level.local.entry_records[id].to)
		if not _expect(outcome.outcome == "complete" and Vector2(endpoint.x, endpoint.z).distance_to(Vector2(goal.x, goal.z)) <= 0.005 and saved.level.local.actors[id].hp == 24.0 and not saved.level.local.actors[id].dead, "terminal history retains the actual original full entry retirement and full-HP helper: " + id): return false
	return true


func _terminal_available(saved: Dictionary) -> bool:
	var near: bool = game.active_level.call("_exit_contact_near") == true
	var cue: Dictionary = game.active_level.get("_exit_cue").state()
	return _expect(not saved.is_empty() and saved.level.local.room == 4 and saved.level.progress.completed and saved.level.progress.completion_id == "court-clear" and saved.level.progress.contact_exit_id == "" and saved.level.local.actors["court-king"].dead and saved.level.local.actors["court-king"].hp == 0.0 and saved.level.local.scheduler.encounter_id == "" and saved.level.local.scheduler.reservations.is_empty() and (game.active_level.get_node("ExitArea") as Area3D).monitoring == near and cue.state == ("available" if near else "clear") and cue.visible == near and (game.active_level.get("_whole_art") as Node3D).call("presentation_state") == {"stage": "exterior", "helpers_open": true, "exterior_state": "available"}, "actual completed saved unit retires danger, retaining exterior scenery and only a genuinely local available contact cue")


func _terminal_replace_continue(saved: Dictionary, earlier_wire: String, label: String) -> bool:
	var ids: Dictionary = _identities(game.active_level, game.player)
	var refs: Array[WeakRef] = _descendant_refs(game)
	if is_instance_valid(game.fx): game.fx.clear()
	game.free(); game = null
	if not _expect(_all_freed(refs), "normal close disposes the terminal donor before fresh " + label + " Continue"): return false
	game = _new_shell()
	if game == null or not await _settle(): return false
	if not _expect(paused and game.active_level == null and game.player == null and game.menu.page_name() == "title", "fresh real Title has no installed terminal world before " + label + " Continue") or not _press(game, "ContinueStoryButton") or not await _settle(): return false
	if not _expect(paused and game.menu.page_name() == "resume" and Exact.stringify(game.capture_campaign_snapshot()) == Exact.stringify(saved) and _identities(game.active_level, game.player) != ids and Exact.stringify(game.attempts.state().story.checkpoint) == earlier_wire and game.player.snapshot_state().resources == saved.player.resources and _durable(game), "fresh disk Continue exactly reconstructs " + label + " native state/resources/history and preserves earlier Retry"): return false
	_watch(game.active_level, game.player, false)
	receipts.append({"stage": "fresh Title Continue " + label, "exact_snapshot": Exact.stringify(game.capture_campaign_snapshot()), "exact_earlier_checkpoint": earlier_wire})
	return _bindings(game)


func _terminal_contact(contacts: Array[Dictionary]) -> bool:
	if not await _wait(func() -> bool: return game.player.get_threat_response_state().stable and game.player.velocity == Vector3.ZERO, "actual stopped Hero before terminal TEST contact placement", 8.0): return false
	var position := Vector3(0, 0.1, -35)
	if not _expect(Layout.SAFE_RECT.has_point(Vector2(position.x, position.z)), "terminal TEST contact placement remains on the authored supported floor"): return false
	var before: Vector3 = game.player.global_position
	game.player.global_position = position
	setups.append({"kind": "TEST supported Hero placement for actual exterior contact", "from": Codec.vector3(before), "to": Codec.vector3(position), "clock_s": _scheduler().get_clock()})
	# Native Area delivery/exit legitimately pauses the Shell before _place's
	# ordinary floor-ready return. The actual saved capsule/floor validation,
	# rather than an invented is_on_floor flag, proves this contact position.
	return await _wait(func() -> bool: return contacts.size() == 1 and game.active_level.get("_contact_exit_id") == "court-exterior", "actual supported native Area contact emits exactly one exterior exit", 8.0, true)


func _terminal_contact_observer_boundaries(saved: Dictionary, earlier_wire: String) -> bool:
	# Terminal-only regression: reuse the exact real local available-contact Save.
	# Copy its existing file bytes to isolated case stores; never rewrite saved
	# progress/contact bits or interrupt the ordinary Shell's signal handler.
	var original_files: Dictionary = _disk()
	if not _expect(original_files.has("campaign.json") and Exact.stringify(game.capture_campaign_snapshot()) == Exact.stringify(saved), "observer cases begin from the exact durable real local available-contact Save"): return false
	var donor_refs: Array[WeakRef] = _descendant_refs(game)
	if is_instance_valid(game.fx): game.fx.clear()
	game.free(); game = null
	if not _expect(_all_freed(donor_refs), "normal donor disposal precedes observer-case unpause; no second world advances"): return false
	for mode: String in ["exit_level", "queued_shell"]:
		var prefix: String = test_root + "contact-boundary-" + mode + "-"
		for name: String in original_files:
			var copy_file := FileAccess.open(prefix + name, FileAccess.WRITE)
			if not _expect(copy_file != null, "isolated observer-case copy is writable: " + mode + "/" + name): return false
			copy_file.store_buffer(original_files[name]); copy_file.close()
		var shell: CinderCampaignShell = Shell.new()
		if not _expect(shell.configure_runtime(raw, prefix + "campaign.json", prefix + "settings.json", prefix + "preferences.json"), "real observer-case Shell keeps canonical handlers and isolated copied stores: " + mode):
			shell.free(); return false
		game = shell; root.add_child(game)
		if not await _settle() or not _expect(paused and game.player == null and game.active_level == null and game.menu.page_name() == "title", "fresh real observer-case Title installs no world: " + mode) or not _press(game, "ContinueStoryButton") or not await _settle(): return false
		if not _expect(paused and game.menu.page_name() == "resume" and Exact.stringify(game.capture_campaign_snapshot()) == Exact.stringify(saved) and Exact.stringify(game.attempts.state().story.checkpoint) == earlier_wire, "fresh quiet public Continue reconstructs exact local terminal unit and earlier Retry: " + mode) or not _terminal_available(game.capture_campaign_snapshot()) or not _bindings(game): return false
		var target: CinderLevel = game.active_level
		var player: CinderPlayer = game.player
		var area := target.get_node("ExitArea") as Area3D
		var cue := target.get("_exit_cue") as CinderInteractionCue
		var art := target.get("_whole_art") as Node3D
		var refs: Array[WeakRef] = _descendant_refs(game)
		var completions: Array[Dictionary] = []
		var contacts: Array[Dictionary] = []
		var observers: Array[Dictionary] = []
		var returned: Dictionary = {}
		_terminal_watch(target, completions, contacts)
		# Connected after the real installed Shell handler. The admitted receipt
		# observes native overlap and the Shell's actual queued exit operation.
		target.contact_exit_requested.connect(func(id: String, exit_id: String) -> void:
			observers.append({"level_id": id, "exit_id": exit_id, "actual_overlap": area.overlaps_body(player), "monitoring": area.monitoring, "cue": cue.state(), "shell_operations": _portable(shell.get("_operations"))})
			if mode == "exit_level": target.exit_level()
			else: returned["clear_accepted"] = cue.clear() # Public observer-owned presentation cleanup before disposal.
			returned["observer_cue"] = cue.state()
			returned["observer_art"] = art.call("presentation_state")
			shell.queue_free()
			# Root owns this recorder. Deferred calls run after the production
			# callback returns and before queued deletion; no runtime hook is added.
			_terminal_contact_observer_return.call_deferred(returned, target, shell, cue, art)
		)
		if not await _resume(game) or not await _wait(func() -> bool: return player.get_threat_response_state().stable and player.velocity == Vector3.ZERO, "actual stopped original Hero before observer-case contact placement: " + mode, 8.0): return false
		var position := Vector3(0, 0.1, -35)
		if not _expect(Layout.SAFE_RECT.has_point(Vector2(position.x, position.z)) and area.monitoring and cue.state().state == "available" and not area.overlaps_body(player), "observer case approaches the original admitted native Area from supported nonoverlap: " + mode): return false
		var before: Vector3 = player.global_position
		player.global_position = position
		setups.append({"kind": "TEST supported Hero placement for actual exterior contact observer boundary", "observer": mode, "from": Codec.vector3(before), "to": Codec.vector3(position)})
		if not await _wait(func() -> bool: return returned.has("after_callback"), "root records the actual observer boundary after production contact returns: " + mode, 8.0, true): return false
		if not _expect(contacts == [{"level_id": "A1-L4", "exit_id": "court-exterior"}] and completions.is_empty() and observers.size() == 1, "actual native contact emits once and invokes one synchronous observer without replaying completion: " + mode): return false
		var admitted: Dictionary = observers[0]
		if not _expect(admitted.actual_overlap and admitted.monitoring and admitted.cue.state == "available" and admitted.cue.trigger == "contact" and admitted.cue.visible and admitted.shell_operations.size() == 1 and admitted.shell_operations[0].operation == "exit" and admitted.shell_operations[0].level_id == "A1-L4", "observer receives actual admitted overlap after the retained ordinary Shell exit handler: " + mode): return false
		var after: Dictionary = returned.after_callback
		receipts.append({"stage": "diagnostic actual contact observer returned boundary", "observer": mode, "admitted": admitted, "returned": returned.duplicate(true), "contact_events": contacts.duplicate(true), "completion_events": completions.duplicate(true)})
		if not _expect(after.get("objects_live") == true and after.shell_queued and after.contact_exit_id == "court-exterior" and after.cue == returned.observer_cue and after.cue.state == "clear" and not after.cue.visible and after.art == returned.observer_art and after.art.exterior_state == "available", "contact return preserves observer cleanup and does not reopen its cue or exterior artwork: " + mode): return false
		if mode == "exit_level":
			if not _expect(after.aliases_released and not after.owner_physics and not after.scheduler_physics and not after.roundel_physics and not after.monitoring, "synchronous public exit retains released aliases and stopped native owner/contact processing"): return false
		elif not _expect(returned.get("clear_accepted") == true and not after.aliases_released, "queued Shell disposal independently preserves public cue cleanup before lifecycle alias release"): return false
		receipts.append({"stage": "actual synchronous exterior contact observer " + mode, "admitted": admitted, "returned": returned, "contact_events": contacts, "completion_events": completions, "scope": "actual callback/lifecycle boundary and normal queued disposal; isolated store, no successor qualification"})
		await process_frame
		if not _expect(_all_freed(refs) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "queued observer-owned Shell disposal releases all real descendants/groups: " + mode): return false
		game = null
	for name: String in original_files:
		if not _expect(FileAccess.get_file_as_bytes(test_root + name) == original_files[name], "observer cases leave the original terminal store bytes unchanged: " + name): return false
	game = _new_shell()
	if game == null or not await _settle() or not _press(game, "ContinueStoryButton") or not await _settle(): return false
	return _expect(paused and game.menu.page_name() == "resume" and Exact.stringify(game.capture_campaign_snapshot()) == Exact.stringify(saved) and Exact.stringify(game.attempts.state().story.checkpoint) == earlier_wire and _durable(game), "fresh original-store Continue restores the unchanged ordinary terminal-save path after observer cases") and _bindings(game)


func _terminal_contact_observer_return(record: Dictionary, target: CinderLevel, shell: CinderCampaignShell, cue: CinderInteractionCue, art: Node3D) -> void:
	var after: Dictionary = {"objects_live": is_instance_valid(target) and is_instance_valid(shell) and is_instance_valid(cue) and is_instance_valid(art)}
	record["after_callback"] = after
	if not after.objects_live: return
	after["shell_queued"] = shell.is_queued_for_deletion()
	after["contact_exit_id"] = target.get("_contact_exit_id")
	after["cue"] = cue.state()
	after["art"] = art.call("presentation_state")
	after["aliases_released"] = target.hero == null and target.shared_shell == null
	after["owner_physics"] = target.is_physics_processing()
	after["scheduler_physics"] = target.get("scheduler").is_physics_processing()
	after["roundel_physics"] = target.get("roundel").is_physics_processing()
	after["monitoring"] = (target.get_node("ExitArea") as Area3D).monitoring


func _unfinished_king_intro_transport() -> bool:
	# Observe the parent's genuine finite entrance before any King injury.
	# No source position, phase, clock, floor flag or entry record is assigned.
	if not await _wait(func() -> bool: return _moving_king_intro(), "real unfinished moving King intro boundary", 12.0): return false
	var earlier: Dictionary = game.attempts.state().story.checkpoint.duplicate(true)
	var earlier_wire: String = Exact.stringify(earlier)
	if not _closed(earlier) or not _expect(earlier.level.progress.checkpoint_id == "court-boss-entry" and earlier.level.local.room == 3, "earlier actual boss-entry checkpoint protects the native intro origin"): return false
	game.request_pause_deferred()
	if not await _settle() or not _expect(paused and game.menu.page_name() == "pause", "public deferred pause captures the complete moving King tick"): return false
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _closed(saved): return false
	var intro: Dictionary = saved.level.local.king_intro
	if not _expect(saved.level.local.room == 3 and not saved.level.local.helpers_once and intro.stage == "entering" and Codec.keys_error(intro.record, ["active", "from", "to", "start_s", "end_s", "speed"]).is_empty() and intro.outcome.is_empty(), "actual King save owns a closed unfinished intro without exposing helpers"): return false
	var actor: Dictionary = saved.level.local.actors["court-king"]
	var record: Dictionary = intro.record
	var position: Vector3 = Codec.read_vector3(actor.motion.position)
	var origin: Vector3 = Codec.read_vector3(record.from)
	var goal: Vector3 = Codec.read_vector3(record.to)
	if not _expect(record.active and record.speed == 1.4 and goal == origin + Vector3.BACK * 0.7 and record.end_s == record.start_s + 0.7 / 1.4 and saved.level.local.scheduler.clock_s > record.start_s and saved.level.local.scheduler.clock_s < record.end_s and actor.motion.grounded and actor.motion.velocity[0] == 0.0 and actor.motion.velocity[1] == 0.0 and actor.motion.velocity[2] > 0.0 and actor.hp == 80.0 and actor.cycle == 0 and actor.reservation_id == "" and position.z > origin.z and position.z < goal.z, "saved native King owns the original supported .7-unit entrance at 1.4 units/s before its first attack"): return false
	var original_record: String = Exact.stringify(record)
	var action_history: Array = game.player.get_world_action_records().duplicate(true)
	var donor_ids: Dictionary = _identities(game.active_level, game.player)
	if not _expect(Exact.stringify(game.attempts.state().story.checkpoint) == earlier_wire and _durable(game), "moving intro Save preserves the earlier real boss-entry Retry and format2 disk"): return false
	receipts.append({"stage": "actual unfinished King intro Save", "exact_snapshot": Exact.stringify(saved), "exact_earlier_checkpoint": earlier_wire, "actions": _portable(action_history)})
	if not _direct_candidate(saved): return false
	# Dispose the donor before unpausing; only the fresh restored world may run.
	var donor_refs: Array[WeakRef] = _descendant_refs(game)
	if is_instance_valid(game.fx): game.fx.clear()
	game.free(); game = null
	if not _expect(_all_freed(donor_refs), "normal close disposes King intro donor before fresh Continue"): return false
	game = _new_shell()
	if game == null or not await _settle(): return false
	if not _expect(paused and game.active_level == null and game.player == null and game.menu.page_name() == "title", "fresh real Title has no installed world before King intro Continue") or not _press(game, "ContinueStoryButton") or not await _settle(): return false
	if not _expect(paused and game.menu.page_name() == "resume" and Exact.stringify(game.capture_campaign_snapshot()) == Exact.stringify(saved) and _identities(game.active_level, game.player) != donor_ids and Exact.stringify(game.attempts.state().story.checkpoint) == earlier_wire and game.player.get_world_action_records() == action_history and _durable(game), "fresh disk Continue reconstructs exact moving King, original clocks/history and protected earlier checkpoint"): return false
	_watch(game.active_level, game.player, false)
	var king: CharacterBody3D = _sources()["court-king"]
	var restored: Dictionary = game.capture_campaign_snapshot()
	if not _closed(restored) or not _expect(not king.is_on_floor() and restored.level.local.actors["court-king"].motion.grounded and king.velocity.z > 0.0, "fresh King has no engine slide history; genuine restored support accompanies its finite intro"): return false
	if not _bindings(game) or not await _resume(game): return false
	if not await _wait(func() -> bool: return game.active_level.get("king_intro").stage == "done", "fresh resumed King intro reaches its original terminal boundary", 12.0) or not await _pause(): return false
	var finished: Dictionary = game.capture_campaign_snapshot()
	if not _closed(finished): return false
	var final_intro: Dictionary = finished.level.local.king_intro
	var final_actor: Dictionary = finished.level.local.actors["court-king"]
	var final_position: Vector3 = Codec.read_vector3(final_actor.motion.position)
	if not _expect(final_intro.stage == "done" and Exact.stringify(final_intro.record) == original_record and Codec.keys_error(final_intro.outcome, ["outcome", "endpoint"]).is_empty() and final_intro.outcome.outcome == "complete" and Vector2(final_position.x, final_position.z).distance_to(Vector2(goal.x, goal.z)) <= 0.005 and Vector2(Codec.read_vector3(final_intro.outcome.endpoint).x, Codec.read_vector3(final_intro.outcome.endpoint).z).distance_to(Vector2(goal.x, goal.z)) <= 0.005 and final_actor.motion.velocity == [0.0, 0.0, 0.0] and final_actor.hp == 80.0 and String(king.get("last_error")).is_empty() and finished.level.local.scheduler.clock_s >= record.end_s, "fresh King completes its exact original endpoint/record/deadline without rebase, injury or fabricated engine support"): return false
	if not _expect(not finished.level.local.helpers_once and finished.level.local.actors["court-helper-west"].dormant and finished.level.local.actors["court-helper-east"].dormant and game.player.get_world_action_records() == action_history and finished.player.resources.hp == saved.player.resources.hp and Exact.stringify(game.attempts.state().story.checkpoint) == earlier_wire, "intro completion preserves the genuine action history/HP and unexposed helper pair without a replacement checkpoint"): return false
	receipts.append({"stage": "fresh unfinished King intro Resume completed", "exact_snapshot": Exact.stringify(finished), "actions": _portable(game.player.get_world_action_records())})
	var ids: Dictionary = _identities(game.active_level, game.player)
	var refs: Array[WeakRef] = _descendant_refs(game.world)
	game.request_retry()
	if not await _settle(): return false
	if not _expect(paused and game.menu.page_name() == "resume" and Exact.stringify(game.capture_campaign_snapshot()) == earlier_wire and _identities(game.active_level, game.player) != ids and _all_freed(refs) and game.player.snapshot_state().resources == earlier.player.resources and _durable(game), "public earlier boss-entry Retry restores the exact protected intro state/resources with fresh native identities"): return false
	receipts.append({"stage": "actual earlier boss-entry Retry after moving intro", "exact_snapshot": Exact.stringify(game.capture_campaign_snapshot())})
	return _bindings(game)


func _moving_king_intro() -> bool:
	if int(game.active_level.get("room")) != 3: return false
	var value: Variant = game.active_level.get("king_intro")
	if not value is Dictionary or value.get("stage") != "entering" or not value.get("record") is Dictionary or value.record.is_empty(): return false
	var record: Dictionary = value.record
	if not record.get("from") is Vector3 or not record.get("to") is Vector3: return false
	var king: CharacterBody3D = _sources()["court-king"]
	return king.velocity.z > 0.0 and king.global_position.z > record.from.z and king.global_position.z < record.to.z


func _unfinished_helper_transport() -> bool:
	# Observe genuine native entry. No authored phase, start, end, floor flag,
	# position or lease is assigned to a source to manufacture a save window.
	if not await _wait(func() -> bool: return _moving_helpers(), "real unfinished moving helper boundary", 12.0): return false
	game.player.shells = 0
	setups.append({"kind": "TEST zero shells immediately before moving-entry pause", "clock_s": _scheduler().get_clock()})
	game.request_pause_deferred()
	if not await _settle() or not _expect(paused and game.menu.page_name() == "pause", "public deferred pause captures the complete current native tick"): return false
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _closed(saved) or not _expect(saved.level.local.room == 4 and saved.level.local.helper_stage == "entering" and saved.level.local.entry_records.size() == 2 and saved.level.local.entry_outcomes.is_empty() and saved.player.resources.shells == 0, "actual moving save retains original entry rather than a fabricated settled or terminal state"): return false
	for id: String in ["court-helper-west", "court-helper-east"]:
		var actor: Dictionary = saved.level.local.actors[id]
		var entry: Dictionary = saved.level.local.entry_records[id]
		var position: Vector3 = Codec.read_vector3(actor.motion.position)
		var from: Vector3 = Codec.read_vector3(entry.from)
		var goal: Vector3 = Codec.read_vector3(entry.to)
		if not _expect(actor.motion.grounded and actor.motion.velocity[2] > 0.0 and actor.motion.velocity[0] == 0.0 and actor.motion.velocity[1] == 0.0 and actor.hp == 24.0 and actor.cycle == 0 and actor.reservation_id == "" and position.z > from.z and position.z < goal.z and entry.end_s == entry.start_s + 0.7 / 1.4 and saved.level.local.scheduler.clock_s < entry.end_s, "saved actual helper owns unfinished grounded finite entry: " + id): return false
	var original_entry: String = Exact.stringify(saved.level.local.entry_records)
	receipts.append({"stage": "TEST actual unfinished helper Save", "exact_snapshot": Exact.stringify(saved)})
	if not _direct_candidate(saved): return false
	# Close the real donor before unpausing a fresh world. Unpausing while both
	# worlds survive would advance both, making a fresh-resume observation false.
	var old_refs: Array[WeakRef] = _descendant_refs(game)
	if is_instance_valid(game.fx): game.fx.clear()
	game.free(); game = null
	if not _expect(_all_freed(old_refs), "normal close disposes donor before fresh moving Continue"): return false
	game = _new_shell()
	if game == null or not await _settle() or not _press(game, "ContinueStoryButton") or not await _settle(): return false
	if not _expect(paused and game.menu.page_name() == "resume" and Exact.stringify(game.capture_campaign_snapshot()) == Exact.stringify(saved) and _durable(game), "fresh real Title Continue reconstructs exact unfinished native entry and clocks"): return false
	_watch(game.active_level, game.player, false)
	for id: String in ["court-helper-west", "court-helper-east"]:
		var actor: CharacterBody3D = _sources()[id]
		if not _expect(not actor.is_on_floor() and saved.level.local.actors[id].motion.grounded and actor.velocity.z > 0.0, "fresh native body has no prior slide contact; genuine restored transport supplies floor support: " + id): return false
	if not _bindings(game) or not await _resume(game): return false
	if not await _wait(func() -> bool: return game.active_level.get("helper_stage") == "done", "fresh resumed entry reaches its original finite terminal boundary", 12.0, true) or not await _checkpoint("court-king-phase-two") or not await _pause(): return false
	var finished: Dictionary = game.capture_campaign_snapshot()
	if not _closed(finished) or not _expect(Exact.stringify(finished.level.local.entry_records) == original_entry, "fresh resume preserves exact original from/to/start/end/speed records without rebase"): return false
	for id: String in ["court-helper-west", "court-helper-east"]:
		var actual: Dictionary = finished.level.local.actors[id]
		var endpoint: Vector3 = Codec.read_vector3(finished.level.local.entry_records[id].to)
		var position: Vector3 = Codec.read_vector3(actual.motion.position)
		if not _expect(finished.level.local.entry_outcomes[id].outcome == "complete" and Vector2(position.x, position.z).distance_to(Vector2(endpoint.x, endpoint.z)) <= 0.005 and actual.motion.velocity == [0.0, 0.0, 0.0] and actual.hp == 24.0 and actual.cycle == 0 and actual.reservation_id == "" and String(_sources()[id].get("last_error")).is_empty(), "fresh restored native helper completes original entry without unsupported groundedness or a replacement attack: " + id): return false
	receipts.append({"stage": "fresh unfinished helper Resume completed", "exact_snapshot": Exact.stringify(finished)})
	return true


func _moving_helpers() -> bool:
	if int(game.active_level.get("room")) != 4 or game.active_level.get("helper_stage") != "entering": return false
	for id: String in ["court-helper-west", "court-helper-east"]:
		var actor: CharacterBody3D = _sources()[id]
		var record: Dictionary = (game.active_level.get("_entry_records") as Dictionary).get(id, {})
		if record.is_empty() or actor.velocity.z <= 0.0 or actor.global_position.z <= record.from.z or actor.global_position.z >= record.to.z - 0.1: return false
	return true


func _direct_candidate(saved: Dictionary) -> bool:
	var donor: Dictionary = _donor()
	candidate = game._prepare("A1-L4", saved.equipment_ids, {}, saved)
	if not _expect(not candidate.is_empty(), "canonical Shell constructs actual fresh court saved-prefix recipients"): return false
	var target: CinderLevel = candidate.level
	var player: CinderPlayer = candidate.player
	var map: Dictionary = target.get("sources")
	var before: Dictionary = _probe(target, player)
	if not _expect(target.is_restore_candidate() and not target.finish_restore_candidate() and player.global_position == Layout.SPAWN_POSITION and not target.request_checkpoint("TEST-forbidden") and not target.request_completion("TEST-forbidden"), "fresh constructor is paused/nonplayable and cannot publish progress"): return false
	for id: String in SourceIds:
		var state: Dictionary = map[id].call("pure_presentation_state")
		var native: Dictionary = _native(map[id], id)
		if not _expect(state.hp == (80.0 if id == "court-king" else 24.0) and not state.dead and state.dormant == saved.level.local.actors[id].dormant and state.cycle == 0 and state.reservation_id == "" and state.hurt_left_s == 0.0 and map[id].velocity == Vector3.ZERO and native.player == player and native.scheduler == target.get("scheduler"), "native constructor exposes only pristine entitled recipient: " + id): return false
	_watch(target, player, true)
	var quiet_before: int = quiet_events
	for id: String in ["court-curtain-guard", "court-king"]:
		var native: Dictionary = _native(map[id], id)
		var descriptor: Dictionary = {"api_revision": "act1-king-restore-recipient-construction-1" if id == "court-king" else "act1-restore-recipient-construction-1", "source_id": id, "room_id": Layout.ROOM_IDS[Layout.SOURCES[id].room], "installed_rooms": Layout.ROOM_IDS.slice(0, int(saved.level.local.room) + 1), "installed_fields": [], "configuration_sha256": Exact.stringify(native.configuration).sha256_text(), "authored_position": Codec.vector3(Layout.SOURCES[id].position)}
		if not _expect(map[id].call("construct_restore_recipient", target, descriptor) == false and _probe(target, player) == before and quiet_events == quiet_before, "duplicate or unentitled actual constructor refuses atomically: " + id): return false
		var malformed_descriptor: Dictionary = descriptor.duplicate(true)
		malformed_descriptor["unknown_entitlement"] = true
		if not _expect(map[id].call("construct_restore_recipient", target, malformed_descriptor) == false and _probe(target, player) == before and quiet_events == quiet_before, "closed actual constructor rejects extra descriptor key without native mutation: " + id): return false
	if not _expect(target.snapshot_error_with_player(saved.level, saved.player).is_empty() and _probe(target, player) == before and _donor() == donor, "complete candidate prevalidation is pure for actual recipient and donor"): return false
	if not _expect(player.restore_state(saved.player) and target.restore_state(saved.level), "quiet actual Player then whole native local commit succeeds"): return false
	var optical: String = game._candidate_presentation_error(candidate, saved.shell)
	var local: Dictionary = target.call("_capture_local_state")
	if "--terminal-save" in OS.get_cmdline_user_args() and saved.level.progress.completed:
		# A nonplayable restore candidate cannot publish a live snapshot. Inspect
		# its actual pure progress fields alongside the existing exact local,
		# Player, optical and zero-callback checks instead.
		var progress: Dictionary = saved.level.progress
		if not _expect(target.is_completed() == progress.completed and target.current_checkpoint() == {"id": progress.checkpoint_id, "kind": progress.checkpoint_kind} and target.get("_completion_id") == progress.completion_id and target.get("_contact_exit_id") == progress.contact_exit_id and Exact.stringify(target.get("_checkpoint_ids")) == Exact.stringify(progress.checkpoint_ids) and quiet_events == quiet_before and _donor() == donor, "terminal-only quiet direct candidate preserves exact completed/contact/checkpoint progress with zero callbacks"): return false
	if not _expect(optical.is_empty() and Exact.stringify(player.snapshot_state()) == Exact.stringify(saved.player) and Exact.stringify(local) == Exact.stringify(saved.level.local) and quiet_events == quiet_before and target.is_restore_candidate() and _donor() == donor, "quiet native unit preserves exact HP/clocks/cues/proof/history with zero callbacks and actual candidate optics"): return false
	receipts.append({"stage": "direct actual candidate quiet restore", "room": saved.level.local.room, "exact_local": Exact.stringify(local), "quiet_callback_delta": quiet_events - quiet_before})
	var refs: Array[WeakRef] = _descendant_refs(candidate.container)
	game._dispose(candidate); candidate = {}
	return _expect(_all_freed(refs) and _donor() == donor, "canonical candidate disposal frees descendants without donor/disk changes")


func _malformed(saved: Dictionary) -> bool:
	var cases: Dictionary = {}
	var bad: Dictionary = saved.duplicate(true); bad.level.local["unknown_local"] = true; cases["unknown local root"] = bad
	bad = saved.duplicate(true); bad.level.local.actors["court-curtain-guard"].source_id = "court-king"; cases["cross-source identity"] = bad
	bad = saved.duplicate(true); bad.level.local.actors["court-king"].configuration.source_id = "foreign-king"; cases["immutable fresh King descriptor configuration"] = bad
	bad = saved.duplicate(true); bad.level.local.scheduler.clock_s += 0.125; cases["paired native clock"] = bad
	bad = saved.duplicate(true); bad.level.progress.completed = true; bad.level.progress.completion_id = "court-clear"; cases["premature court completion"] = bad
	for label: String in cases:
		var before: Dictionary = _donor()
		bad = cases[label]
		if not _expect(not game.active_level.snapshot_error_with_player(bad.level, bad.player).is_empty() and not game.active_level.restore_state(bad.level) and not game.attempts.record_snapshot(bad), label + " rejects public context/restore/durable validation"): return false
		if not _expect(_donor() == before, label + " changes no live native state/resources/UI/identity/events or disk generation"): return false
	# Use the actual canonical valid reader to clear its own rejection diagnostic,
	# never patch error/operation fields. This distinct candidate is not installed.
	candidate = game._prepare_snapshot(saved)
	if not _expect(not candidate.is_empty(), "canonical valid whole reader remains usable after malformed attempts"): return false
	game._dispose(candidate); candidate = {}
	return true


func _fresh_continue(saved: Dictionary) -> bool:
	var donor: Dictionary = _donor()
	fresh = _new_shell()
	if fresh == null: return false
	for index: int in range(8): await process_frame
	if not _expect(paused and fresh.player == null and fresh.active_level == null and fresh.menu.page_name() == "title" and fresh.campaign_error.is_empty(), "second real Shell reads format2 disk at Title with no installed Player") or not _press(fresh, "ContinueStoryButton"): return false
	for index: int in range(8): await process_frame
	if not _expect(fresh.campaign_error.is_empty() and fresh.active_level != null and paused and Exact.stringify(fresh.capture_campaign_snapshot()) == Exact.stringify(saved) and _identities(fresh.active_level, fresh.player) != _identities(game.active_level, game.player) and _durable(fresh) and _donor() == donor, "fresh disk Continue restores exact independent native unit without donor/checkpoint mutation") or not _bindings(fresh): return false
	var refs: Array[WeakRef] = _descendant_refs(fresh)
	if is_instance_valid(fresh.fx): fresh.fx.clear()
	fresh.free(); fresh = null
	return _expect(_all_freed(refs) and _donor() == donor, "fresh Continue disposal leaves no duplicate recipient or donor changes")


func _closed(saved: Dictionary) -> bool:
	if saved.is_empty() or not saved.get("level") is Dictionary or not saved.level.get("local") is Dictionary:
		return _expect(false, "whole court/Player/Shell unit exists")
	var local: Dictionary = saved.level.local
	var keys: Array = LocalKeys.duplicate()
	if local.get("schema_version") == 3: keys.append("approach_arrangement")
	var version: bool = local.get("schema_version") is int and (local.schema_version == 2 and local.get("api_revision") == "act1-court-aggregate-2" or local.schema_version == 3 and local.get("api_revision") == "act1-court-aggregate-3" and local.get("approach_arrangement") is Dictionary)
	return _expect(version and Codec.keys_error(local, keys).is_empty() and Codec.keys_error(local.actors, SourceIds).is_empty() and Codec.keys_error(local.king_intro, ["stage", "record", "outcome"]).is_empty() and local.world_revision == 2 and not Exact.stringify(saved).is_empty(), "capture is exact current3 or retained legacy2 whole court/Player/Shell transport")


func _native(actor: CharacterBody3D, id: String) -> Dictionary:
	return actor.call("get_court_native_bindings") if id == "court-king" else actor.call("get_spore_native_bindings")


func _bindings(shell: CinderCampaignShell) -> bool:
	if not _expect(is_instance_valid(shell.active_level) and is_instance_valid(shell.player) and shell.active_level.hero == shell.player and shell.active_level.shared_shell == shell and _count_players(shell.world) == 1, "installed world retains exactly one actual shared Player and Shell aliases"): return false
	var map: Dictionary = shell.active_level.get("sources")
	if not _expect(Codec.keys_error(map, SourceIds).is_empty(), "whole court retains exactly the original eight source identities"): return false
	for id: String in SourceIds:
		var actor: CharacterBody3D = map[id]
		var native: Dictionary = _native(actor, id)
		if not _expect(native.get("player") == shell.player and native.get("scheduler") == shell.active_level.get("scheduler") and actor.get_parent() == shell.active_level and actor.get_world_3d() == shell.player.get_world_3d() and String(actor.call("art_binding_error")).is_empty(), "actual source aliases/world/art: " + id): return false
	return true


func _probe(target: CinderLevel, player: CinderPlayer) -> Dictionary:
	var actors: Dictionary = {}
	for id: String in SourceIds:
		var actor: CharacterBody3D = target.get("sources")[id]
		actors[id] = {"state": _portable(actor.call("pure_presentation_state")), "cue": _portable(actor.call("get_cue").state()), "transform": actor.global_transform, "velocity": actor.velocity, "visible": actor.visible, "layer": actor.collision_layer, "mask": actor.collision_mask, "disabled": actor.get_node("BodyCollision").disabled}
	var sched: CinderThreatScheduler = target.get("scheduler")
	return {"player": Exact.stringify(player.snapshot_state()), "scheduler": Exact.stringify(sched.snapshot_state(target.call("scheduler_bindings"))), "actors": actors, "roundel": _portable(target.get("roundel").state()), "ids": _identities(target, player)}


func _identities(target: CinderLevel, player: CinderPlayer) -> Dictionary:
	var result: Dictionary = {"level": target.get_instance_id(), "player": player.get_instance_id(), "scheduler": target.get("scheduler").get_instance_id(), "roundel": target.get("roundel").get_instance_id(), "actors": {}}
	for id: String in SourceIds:
		var actor: CharacterBody3D = target.get("sources")[id]
		result.actors[id] = [actor.get_instance_id(), actor.get_node("BodyCollision").get_instance_id(), actor.get_node("BodyCollision").shape.get_instance_id(), actor.call("get_art").get_instance_id(), actor.call("get_cue").get_instance_id()]
	return result


func _donor() -> Dictionary:
	var ui: Dictionary = {}
	for surface: Node in [game.menu, game.hud]:
		for node: Node in surface.find_children("*", "Control", true, false):
			var control := node as Control
			var row: Array = [control.visible, control.is_visible_in_tree()]
			if control is Label: row.append((control as Label).text)
			if control is Button: row.append((control as Button).disabled)
			ui[String(control.get_path())] = row
	return {"native": _probe(game.active_level, game.player), "snapshot": Exact.stringify(game.capture_campaign_snapshot()), "attempts": Exact.stringify(game.attempts.state()), "disk": _disk(), "ui": ui, "hud_safe_rect": game.hud.combat_safe_rect(), "camera": game.camera.global_transform, "input": game.get_input_observation_state(), "effects": _effects(game.fx), "events": events, "actions": _portable(game.player.get_world_action_records()), "paused": paused}


func _effects(fx: PixelEffects) -> Array:
	var result: Array = []
	for node: Node in fx.find_children("*", "", true, false):
		var row: Dictionary = {"id": node.get_instance_id(), "parent": node.get_parent().get_instance_id(), "class": node.get_class(), "queued": node.is_queued_for_deletion()}
		if node is Node3D: row["transform"] = (node as Node3D).transform; row["visible"] = (node as Node3D).visible
		if node is AudioStreamPlayer: row["playing"] = (node as AudioStreamPlayer).playing; row["paused"] = (node as AudioStreamPlayer).stream_paused
		result.append(row)
	return result


func _disk() -> Dictionary:
	var result: Dictionary = {}
	var dir := DirAccess.open(test_root)
	if dir != null:
		for name: String in dir.get_files(): result[name] = FileAccess.get_file_as_bytes(test_root + name)
	return result


func _durable(shell: CinderCampaignShell) -> bool:
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(test_root + "campaign.json"))
	if not envelope is Dictionary or envelope.get("format_version") != 2: return false
	var decoded: Dictionary = Exact.parse(String(envelope.get("payload_json", "")))
	return decoded.get("accepted") == true and Exact.stringify(decoded.value) == Exact.stringify(shell.attempts.state())


func _watch(target: CinderLevel, player: CinderPlayer, quiet: bool) -> void:
	var one: Callable = Callable(self, "_quiet1" if quiet else "_event1")
	var two: Callable = Callable(self, "_quiet2" if quiet else "_event2")
	var three: Callable = Callable(self, "_quiet3" if quiet else "_event3")
	target.checkpoint_requested.connect(three); target.completion_requested.connect(two); target.contact_exit_requested.connect(two)
	player.world_action_executed.connect(one); player.fired.connect(one); player.action_resolved.connect(three)
	for actor: CharacterBody3D in (target.get("sources") as Dictionary).values():
		actor.connect("state_changed", one); actor.connect("defeated", one); actor.connect("hit_resolved", three)
		actor.call("get_cue").state_changed.connect(one)
	for name: String in ["BossContactCue", "ExteriorContactCue"]:
		var cue := target.get_node_or_null(name) as CinderInteractionCue
		if is_instance_valid(cue): cue.state_changed.connect(one)
	target.get("roundel").state_changed.connect(one); target.get("roundel").get_cue().state_changed.connect(one)
	target.get("scheduler").reservation_invalidated.connect(two)


func _event1(_a: Variant) -> void: events += 1
func _event2(_a: Variant, _b: Variant) -> void: events += 1
func _event3(_a: Variant, _b: Variant, _c: Variant) -> void: events += 1
func _quiet1(_a: Variant) -> void: quiet_events += 1
func _quiet2(_a: Variant, _b: Variant) -> void: quiet_events += 1
func _quiet3(_a: Variant, _b: Variant, _c: Variant) -> void: quiet_events += 1


func _resume(shell: CinderCampaignShell) -> bool:
	if not _expect(paused and shell.menu.page_name() in ["resume", "pause"], "real CampaignMenu exposes permitted Resume"): return false
	var button := shell.menu.find_child("ResumeButton", true, false) as Button
	if not _expect(is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled, "native Resume button is visible and enabled"): return false
	var input: Dictionary = shell.get_input_observation_state()
	var history: Array = shell.player.get_world_action_records()
	var point: Vector2 = button.get_global_rect().get_center()
	var press := InputEventMouseButton.new(); press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = point; press.global_position = point
	Input.parse_input_event(press); await process_frame
	var release := InputEventMouseButton.new(); release.button_index = MOUSE_BUTTON_LEFT; release.position = point; release.global_position = point
	Input.parse_input_event(release); await process_frame
	return _expect(not paused and shell.get_input_observation_state() == input and shell.player.get_world_action_records() == history, "actual press/frame/release/frame Resume consumes input without action or anchor changes")


func _pause() -> bool:
	game.request_pause()
	if not await _settle(): return false
	return _expect(paused and game.menu.page_name() == "pause" and game.menu.is_open(), "public Pause drains actual native save barrier and CampaignMenu")


func _press(shell: CinderCampaignShell, name: String) -> bool:
	var button := shell.menu.find_child(name, true, false) as Button
	if not _expect(is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled, "real public menu exposes " + name): return false
	button.pressed.emit() # Menu setup only; never a gameplay input action.
	return true


func _checkpoint(id: String) -> bool:
	if not await _wait(func() -> bool: return game.active_level.current_checkpoint().id == id, "actual checkpoint " + id, 8.0, true) or not await _settle(): return false
	if not _expect(game.attempts.state().story.checkpoint.level.progress.checkpoint_id == id and _durable(game), "native checkpoint drains through actual format2 store: " + id): return false
	# Shell may legitimately auto-resume an unpaused checkpoint; only resume a
	# remaining observed checkpoint Resume page, never an unexpected focus Pause.
	if paused:
		if not _expect(game.menu.page_name() == "resume", "only actual checkpoint Resume may be consumed"): return false
		return await _resume(game)
	return true


func _damage(id: String, amount: float) -> bool:
	if not _guard(): return false
	var actor: CharacterBody3D = _sources()[id]
	var before: float = actor.get("hp")
	var result: Dictionary = actor.call("take_damage", amount, Vector3.ZERO)
	setups.append({"kind": "TEST public actor injury", "id": id, "amount": amount, "before_hp": before, "after_hp": actor.get("hp"), "clock_s": _scheduler().get_clock()})
	return _expect(result.get("accepted") == true and actor.get("hp") == maxf(0.0, before - amount), "representative setup uses actual public native injury: " + id)


func _place(position: Vector3) -> bool:
	if not await _wait(func() -> bool: return game.player.get_threat_response_state().stable and game.player.velocity == Vector3.ZERO, "actual stopped Hero before TEST placement", 8.0): return false
	var before: Vector3 = game.player.global_position
	game.player.global_position = position
	setups.append({"kind": "TEST Hero placement", "from": Codec.vector3(before), "to": Codec.vector3(position), "clock_s": _scheduler().get_clock()})
	return await _wait(func() -> bool: return game.player.get_threat_response_state().stable, "actual floor settlement after TEST placement", 8.0)


func _warning(id: String) -> bool:
	var state: Dictionary = _sources()[id].call("pure_presentation_state")
	return state.phase == "warning" and not String(state.reservation_id).is_empty()


func _sources() -> Dictionary: return game.active_level.get("sources")
func _scheduler() -> CinderThreatScheduler: return game.active_level.get("scheduler")


func _settle() -> bool:
	for index: int in range(8):
		if finishing or aborted: return false
		await process_frame
	return _expect(is_instance_valid(game) and game.campaign_error.is_empty(), "canonical campaign operations settle without error: " + (game.campaign_error if is_instance_valid(game) else "Shell absent"))


func _wait(predicate: Callable, label: String, seconds: float, allow_checkpoint_pause: bool = false) -> bool:
	var end: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while not finishing and not aborted and Time.get_ticks_msec() <= end:
		if predicate.call() == true: return true
		if not is_instance_valid(game) or not is_instance_valid(game.player) or game.player.dead: return _expect(false, label + " lost actual living Player")
		if paused and not allow_checkpoint_pause: return _expect(false, label + " encountered unexpected native pause; no forced Resume")
		await process_frame
	return _expect(false, "bounded observation: " + label)


func _guard() -> bool:
	return _expect(not finishing and not aborted and not paused and is_instance_valid(game.player) and not game.player.dead, "representative setup requires actual living unpaused Player")


func _count_players(node: Node) -> int:
	var count: int = 1 if node is CinderPlayer else 0
	for child: Node in node.get_children(): count += _count_players(child)
	return count


func _descendant_refs(node: Node) -> Array[WeakRef]:
	var refs: Array[WeakRef] = [weakref(node)]
	for child: Node in node.get_children(): refs.append_array(_descendant_refs(child))
	return refs


func _all_freed(refs: Array[WeakRef]) -> bool:
	for ref: WeakRef in refs:
		if ref.get_ref() != null: return false
	return true


func _portable(value: Variant) -> Variant:
	if value is Vector3: return Codec.vector3(value)
	if value is StringName: return String(value)
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _portable(value[key])
		return result
	if value is Array:
		var result: Array = []
		for child: Variant in value: result.append(_portable(child))
		return result
	return value


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > WatchdogMs + (ContactObserverAllowanceMs if "--contact-observer-boundaries" in OS.get_cmdline_user_args() else 0):
		_expect(false, "bounded focused whole-court Save fixture"); aborted = true; _finish.call_deferred()


func _expect(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
		if first_failure.is_empty():
			first_failure = {"label": label, "paused": paused, "campaign_error": game.campaign_error if is_instance_valid(game) else "Shell absent"}
			if is_instance_valid(game) and is_instance_valid(game.active_level):
				# Preserve the first underlying refusal before later diagnostic
				# snapshot queries can replace a component's last-error field.
				first_failure["level_snapshot_error"] = game.active_level.last_snapshot_error
				first_failure["level_capture_error"] = game.active_level.get("_capture_error")
				first_failure["player_snapshot_error"] = game.player.get("last_snapshot_error")
				first_failure["failed_operations"] = _portable(game.get("_failed_operations"))
				first_failure["court_room"] = game.active_level.get("room")
				first_failure["awaiting_room"] = game.active_level.get("_awaiting_room")
				first_failure["helper_stage"] = game.active_level.get("helper_stage")
				first_failure["king_intro"] = _portable(game.active_level.get("king_intro"))
				first_failure["construction_error"] = game.active_level.get("_construction_error")
				first_failure["native_source_errors"] = {}
				for id: String in SourceIds:
					var actor: CharacterBody3D = _sources()[id]
					first_failure.native_source_errors[id] = {"last_error": actor.get("last_error"), "position": Codec.vector3(actor.global_position), "velocity": Codec.vector3(actor.velocity), "native_on_floor": actor.is_on_floor(), "state": _portable(actor.call("pure_presentation_state"))}
				first_failure["player_position"] = Codec.vector3(game.player.global_position)
				first_failure["framing"] = game.get_camera_framing_state()
				first_failure["native_local"] = game.active_level.call("_capture_local_state") if paused else {}
				first_failure["entry_stop_diagnostics"] = _portable(game.active_level.get("entry_stop_diagnostics"))
	return ok


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true
	if is_instance_valid(game) and not candidate.is_empty(): game._dispose(candidate); candidate = {}
	if is_instance_valid(fresh):
		if is_instance_valid(fresh.fx): fresh.fx.clear()
		fresh.free(); fresh = null
	var refs: Array[WeakRef] = []
	if is_instance_valid(game):
		refs = _descendant_refs(game)
		if is_instance_valid(game.fx): game.fx.clear()
		game.free(); game = null
	paused = false
	await create_timer(0.5, true).timeout
	await process_frame
	_expect(_all_freed(refs) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "all actual Shell/native descendants/groups retire through normal cleanup")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == registry_text, "TEST metadata never changes the production registry")
	var report: String = "res://.cinder/a1-l4-whole-save-%d.json" % Time.get_ticks_usec()
	var file := FileAccess.open(report, FileAccess.WRITE)
	if file == null: _expect(false, "focused native report is writable")
	else:
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "first_failure": first_failure, "setups": setups, "receipts": receipts, "fixture_mode": "terminal-save" if "--terminal-save" in OS.get_cmdline_user_args() else ("moving-king-intro-save" if "--moving-king-intro-save" in OS.get_cmdline_user_args() else ("moving-helper-save" if "--moving-helper-save" in OS.get_cmdline_user_args() else ("representative-helpers" if "--representative-helpers" in OS.get_cmdline_user_args() else "entrance-only"))), "wall_ms": Time.get_ticks_msec() - started_ms, "scope": "TEST metadata/generic predecessors/injured carryover; default is actual entrance Warning Save/format2/pristine constructors/fresh Continue/earlier Retry/quiet cleanup only. Opt-in King intro/helper transport reuses labelled public injuries/placement; the intro selector leaves the King uninjured and observes actual finite movement/fresh Resume/earlier boss-entry Retry. The terminal selector observes real completed intro/stopped helpers, public King defeat, completed/contact format2 transport, exact fresh Title Continue and earlier phase Retry; its actual unavailable A1-L5 exit failure is preserved and is not a successor acceptance. No earned route, production registration, art/kit/balance/performance/mobile acceptance"}, "\t")); file.close()
	var dir := DirAccess.open(test_root)
	if dir != null:
		for name: String in dir.get_files(): DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L4 WHOLE SAVE: %d checks/%d failures; report=%s; TEST REPRESENTATIVE TRANSPORT ONLY" % [checks, failures, report])
	quit(1 if failures > 0 else 0)
