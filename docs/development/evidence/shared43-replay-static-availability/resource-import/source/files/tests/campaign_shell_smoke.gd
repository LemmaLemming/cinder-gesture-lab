extends SceneTree
## Actual shared actor/enemy/floor/save/menu fixture. No real campaign acceptance.
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const FocusExact = preload("res://scripts/campaign/exact_json.gd")
const FocusStore = preload("res://scripts/campaign/save_store.gd")
const TEST_ROOT: String = "user://test-campaign-shell/"
class ReturnFailStore extends CinderSaveStore:
	func write_payload(payload: Dictionary) -> bool:
		if payload.get("side_attempt") == null:
			last_error = "Injected failure on side-return publication"
			return false
		return super.write_payload(payload)
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
	if "--focus-notifications-only" in OS.get_cmdline_user_args():
		await _test_focus_notifications()
		_finish()
		return
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
	game.menu.continue_story_requested.emit()
	await _settle()
	_expect(paused and game.menu.page_name() == "resume" and game.attempts.active_kind() == "story" and Codec.same_values(game.capture_campaign_snapshot(), protected), "explicit Continue Story leaves replay at paused Resume with the complete protected story restored")
	var continued_input: Dictionary = game.get_input_observation_state()
	game.handle_tap(root.get_visible_rect().size * 0.5)
	_expect(game.get_input_observation_state() == continued_input and Codec.same_values(game.capture_campaign_snapshot(), protected), "Continue Story's paused menu consumes taps without changing story actions, resources or aim")
	game.menu.replay_requested.emit("A1-L1", replay_gear)
	await _settle()
	game.player.hp = 8.0
	game.player.shells = 0
	game.active_level.charges = 0
	game.active_level.collected = ["supply-1"]
	game.attempts._store.path = TEST_ROOT + "blocked-save"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(game.attempts._store.path))
	var original_player: CinderPlayer = game.player
	game.menu.restart_replay_requested.emit("A1-L1", protected.equipment_ids)
	await _settle()
	_expect(game.player == original_player and game.player.hp == 8 and game.player.shells == 0 and game.active_level.charges == 0 and game.player.equipment.snapshot().weapon == "WEAPON-02", "failed replay restart preserves actual old actor/equipment/spent encounter until new isolated state commits")
	game.attempts._store.path = TEST_ROOT + "campaign.json"
	game.retry_pending_operations()
	await _settle()
	_expect(game.player.hp == 100 and game.player.shells == 2 and game.active_level.charges == 1 and game.player.equipment.snapshot() == protected.equipment_ids and Codec.same_values(game.attempts.story_snapshot(), protected), "new replay equipment restarts a complete fresh isolated encounter without mixing spent enemies/resources or story state")
	game.active_level.request_completion("replay-clear")
	await _settle()
	game.active_level.request_contact_exit("return", game.player)
	await _settle()
	_expect(paused and game.menu.page_name() == "journey" and game.attempts.active_kind() == "story" and Codec.same_values(game.capture_campaign_snapshot(), protected), "finishing replay returns to Journey with entire story equipment, resources, enemies and aim restored")
	game.menu.optional_requested.emit("A1-O1")
	await _settle()
	_expect(game.attempts.active_kind() == "optional" and game.active_level.level_id == "A1-O1", "parent-clear optional branch launches through isolated side flow")
	game.attempts._store.path = TEST_ROOT + "blocked-save"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(game.attempts._store.path))
	game.active_level.request_completion("optional-clear")
	await _settle()
	_expect(not game._failed_operations.is_empty() and game.attempts.state().completed_optional.is_empty(), "failed optional completion cannot grant its stamp or publish local completion alone")
	game.attempts._store.path = TEST_ROOT + "campaign.json"
	var pending_optional: Array = game._failed_operations.duplicate(true)
	game.menu.journey_requested.emit()
	game.request_pause()
	game.menu.settings_changed_request.emit({"audio":{"effects":0.4}})
	await _settle()
	_expect(game._failed_operations == pending_optional and not game.attempts.record_snapshot(game.capture_campaign_snapshot()) and game.attempts.state().completed_optional.is_empty(), "Journey/focus/settings preserve pending optional completion and model rejects an unstamped completed side snapshot")
	game.retry_pending_operations()
	await _settle()
	_expect(game.attempts.state().reward_ids == ["A1-O1-completion-stamp"], "actual optional completion records its once-only stamp")
	var return_store := ReturnFailStore.new(TEST_ROOT + "campaign.json")
	return_store.generation = game.attempts._store.generation
	return_store.payload_validator = game.attempts._store.payload_validator
	game.attempts._store = return_store
	game.active_level.request_contact_exit("return",game.player)
	await _settle()
	_expect(game.attempts.active_kind() == "optional" and not game.attempts.active_snapshot().level.progress.contact_exit_id.is_empty() and not game._failed_operations.is_empty(), "failed second side-return write retains a durable latched side exit and protected story")
	game.free()
	game = _new_shell()
	await _settle()
	game.resume_campaign()
	await _settle()
	_expect(paused and game.menu.page_name() == "journey" and game.attempts.active_kind() == "story" and Codec.same_values(game.capture_campaign_snapshot(),protected), "interrupted optional exit returns to Journey with coherent story restored automatically")
	_expect(game.attempts.state().reward_ids.size() == 1 and (game.menu.find_child("MenuStatus",true,false) as Label).text == "Story equipment restored.", "interrupted automatic side return deduplicates reward and reports exact story equipment restoration")
	game.menu.replay_requested.emit("A1-O1",protected.equipment_ids)
	await _settle()
	game.active_level.request_completion("optional-replay-clear")
	await _settle()
	game.active_level.request_contact_exit("return",game.player)
	await _settle()
	_expect(paused and game.menu.page_name() == "journey" and game.attempts.state().reward_ids.size() == 1 and game.attempts.state().completed_main.size() == 2, "optional replay returns to Journey without repeating rewards or advancing the main route")
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
	# This side attempt protects the current story, including the actual new swipe observation.
	var abandonment_protected: Dictionary = game.capture_campaign_snapshot()
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
	_expect(game.attempts.active_kind() == "replay" and game._failed_operations.is_empty() and not abandonment_protected.is_empty() and Codec.same_values(game.attempts.story_snapshot(), abandonment_protected), "retry publishes side transaction with the complete current story protected before replacing old world")
	game.attempts._store.path = TEST_ROOT + "blocked-save"
	game.active_level.request_completion("retry-save-clear")
	await _settle()
	_expect(not game._failed_operations.is_empty() and not game.attempts.active_snapshot().level.progress.completed, "failed completion leaves prior aggregate/progress intact while preserving latched live operation")
	game.attempts._store.path = TEST_ROOT + "campaign.json"
	var pending_completion: Array = game._failed_operations.duplicate(true)
	game.menu.journey_requested.emit()
	game.request_pause()
	await _settle()
	_expect(game._failed_operations == pending_completion and game._failed_operations[0].operation == "complete", "ordinary navigation cannot replace a pending latched completion with an unrecoverable save operation")
	game.retry_pending_operations()
	await _settle()
	_expect(game.attempts.active_snapshot().level.progress.completed and game._failed_operations.is_empty(), "pending completion retries without requiring another suppressed level signal")
	game.menu.leave_side_requested.emit()
	await _settle()
	_expect(paused and game.menu.page_name() == "journey" and game.attempts.active_kind() == "story" and Codec.same_values(game.capture_campaign_snapshot(), abandonment_protected), "abandoning completed replay returns to Journey with the complete protected story restored")
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
	await _test_final_exit()
	_finish()

func _test_final_exit() -> void:
	game.free()
	_cleanup()
	for info: Dictionary in raw.levels:
		if info.id == "A3-L5":
			info.scene_path = "res://tests/fixtures/campaign/live_a3_l5.tscn"
			info.readiness = "accepted"
			info.accepted_commit = "a".repeat(40)
			info.api_revision = Registry.API_REVISION
	game = _new_shell()
	await _settle()
	# Explicit TEST ONLY route-prefix seed isolates the terminal boundary; it
	# neither registers nor claims playing any of the real preceding14 scenes.
	var candidate: Dictionary = game._prepare("A3-L5", CinderEquipment.STARTER)
	var snapshot: Dictionary = game._capture(candidate.player,candidate.level,game._fresh_shell_state())
	var state: Dictionary = game.attempts.state()
	state.completed_main = game.registry.main_route().slice(0,14)
	state.story = {"kind":"story","level_id":"A3-L5","snapshot":snapshot,"checkpoint":snapshot.duplicate(true)}
	_expect(game.attempts.restore_session(state) and game.attempts.record_snapshot(snapshot), "terminal TEST ONLY fixture seeds a valid first14 prefix and final unfinished story")
	game._dispose(candidate)
	game.menu.continue_story_requested.emit()
	await _settle()
	game.active_level.request_completion("final-tether")
	await _settle()
	game.menu.show_title()
	_expect(game.attempts.state().completed_main.size() == 15 and game.menu.find_child("ContinueStoryButton",true,false) != null, "all main clears retain Continue Story until the authored final exit/coda is committed")
	game.menu.continue_story_requested.emit()
	await _settle()
	_expect(game.active_level.level_id == "A3-L5" and game.menu.page_name() == "resume" and game.active_level.is_completed(), "final completed story can resume its remaining authored exit")
	game.active_level.request_contact_exit("beyond-image",game.player)
	await _settle()
	game.menu.show_title()
	_expect(game.menu.find_child("ContinueStoryButton",true,false) == null and game.attempts.story_snapshot().level.progress.contact_exit_id == "beyond-image", "committed terminal exit leaves Journey/replay as completed-campaign navigation")
	var finished: Dictionary = game.attempts.story_snapshot()
	game.menu.replay_requested.emit("A3-L5",finished.equipment_ids)
	await _settle()
	game.menu.leave_side_requested.emit()
	await _settle()
	_expect(game.attempts.active_kind() == "story" and Codec.same_values(game.attempts.story_snapshot(),finished) and game.menu.page_name() == "journey", "leaving final-level replay restores completed protected story without reopening the latched ending")
	game.menu.replay_requested.emit("A3-L5", finished.equipment_ids)
	await _settle()
	game.menu.continue_story_requested.emit()
	await _settle()
	_expect(paused and game.attempts.active_kind() == "story" and Codec.same_values(game.capture_campaign_snapshot(), finished) and game.menu.page_name() == "journey", "explicit Continue Story from final replay retains Journey once the protected ending is complete")
# TEST ONLY native Node.notification dispatch, never an operating-system focus
# claim. Only the selected new branch runs these helpers; original route intact.
class FocusWriteStore extends CinderSaveStore:
	var writes: int = 0
	func write_payload(payload: Dictionary) -> bool:
		writes += 1
		return super.write_payload(payload)

func _focus_track_store() -> FocusWriteStore:
	var original: CinderSaveStore = game.attempts._store
	var tracked := FocusWriteStore.new(original.path)
	tracked.generation = original.generation
	tracked.payload_validator = original.payload_validator
	game.attempts._store = tracked
	return tracked

func _focus_disk_receipt() -> Dictionary:
	var files: Dictionary = {}
	var directory: DirAccess = DirAccess.open(TEST_ROOT)
	if directory != null:
		for name: String in directory.get_files():
			var bytes: PackedByteArray = FileAccess.get_file_as_bytes(TEST_ROOT + name)
			files[name] = {"bytes": bytes.size(), "hex": bytes.hex_encode()}
	return {"directory_exists": directory != null, "files": files}

func _focus_idle_receipt() -> Dictionary:
	return {"page": game.menu.page_name(), "attempts": FocusExact.stringify(game.attempts.state()), "shell": FocusExact.stringify(game._shell_state()), "settings": FocusExact.stringify(game.settings.snapshot()), "save_generation": game.attempts._store.generation, "preferences_generation": game._preferences_store.generation, "campaign_error": game.campaign_error, "disk": _focus_disk_receipt()}

func _test_focus_notifications() -> void:
	game = _new_shell()
	await _settle()
	var tracked: FocusWriteStore = _focus_track_store()
	var events: Array[String] = []
	game.input_observed.connect(func(_record: Dictionary) -> void: events.append("input"))
	game.aim_anchor_changed.connect(func(_anchor: Vector2) -> void: events.append("aim"))
	_expect(paused and game.active_level == null and game.player == null and game.menu.page_name() == "title", "notification fixture starts actual idle Title without actor")
	for page: String in ["title", "journey", "settings"]:
		if page == "journey":
			game.menu.journey_requested.emit()
			await _settle()
		elif page == "settings":
			game.menu.show_settings()
		for notification: int in [Node.NOTIFICATION_APPLICATION_FOCUS_OUT, Node.NOTIFICATION_APPLICATION_PAUSED]:
			var before: Dictionary = _focus_idle_receipt()
			_expect(not before.attempts.is_empty() and not before.shell.is_empty() and not before.settings.is_empty() and before.page == page, page + " starts with nonempty exact idle receipts")
			game.notification(notification)
			_expect(game._operations.is_empty() and not game._drain_queued and not game._draining and game._failed_operations.is_empty(), page + " notification enqueues no operation or deferred save")
			await _settle()
			_expect(paused and game.active_level == null and game.player == null and game.menu.is_open() and game.menu.page_name() == page, page + " remains the same idle page after native notification/deferred frames")
			_expect(_focus_idle_receipt() == before and tracked.writes == 0 and events.is_empty(), page + " preserves Attempts/store generation/all disk bytes/input and publishes no gesture observation")
	await _focus_dispose_shell()
	for notification: int in [Node.NOTIFICATION_APPLICATION_FOCUS_OUT, Node.NOTIFICATION_APPLICATION_PAUSED]:
		await _focus_live_notification(notification)
	await _focus_fatal_notifications()

func _focus_begin_live(hp: float) -> bool:
	_cleanup()
	game = _new_shell()
	await _settle()
	game.menu.begin_story_requested.emit()
	await _settle()
	_expect(paused and game.active_level != null and game.player != null and game.campaign_error.is_empty(), "notification case begins accepted actual paused TEST ONLY level: " + game.campaign_error)
	if game.active_level == null or game.player == null:
		return false
	# Initial injury/resources only. Source attacks, clocks and all physical
	# motion follow native controllers; no dead flag/contact is fabricated.
	game.player.hp = hp
	game.player.shells = 0
	game.active_level.guard.hp = 7.0
	game.active_level.charges = 0
	game.active_level.collected = ["supply-1"]
	return true

func _focus_live_notification(notification: int) -> void:
	if not await _focus_begin_live(37.0):
		await _focus_dispose_shell()
		return
	var checkpoint: String = FocusExact.stringify(game.attempts.state().story.checkpoint)
	var tracked: FocusWriteStore = _focus_track_store()
	game.resume_campaign()
	await _focus_ticks(6)
	_expect(not paused and not game.menu.is_open() and not game.player.dead and game.player.get_threat_response_state().motion.grounded, "living notification observes actual grounded running actor")
	var actor: CinderPlayer = game.player
	var hp: float = actor.hp
	var shells: int = actor.shells
	var enemy_hp: float = game.active_level.guard.hp
	var observation: Dictionary = game.get_input_observation_state().duplicate(true)
	var records: Array = actor.get_world_action_records()
	var events: Array[String] = []
	game.input_observed.connect(func(_record: Dictionary) -> void: events.append("input"))
	game.aim_anchor_changed.connect(func(_anchor: Vector2) -> void: events.append("aim"))
	var press := InputEventScreenTouch.new()
	press.index = 73
	press.position = root.get_visible_rect().size * Vector2(0.45, 0.55)
	press.pressed = true
	game.get_viewport().push_input(press)
	_expect(game._pointers.has(73) and events.is_empty(), "native routed touch press arms actual recognizer without attack")
	game.notification(notification)
	_expect(paused and game._pointers.is_empty() and game._last_tap_time == -1000 and game._operations.size() == 1 and game._operations[0].operation == "pause", "real active notification consumes gesture and retains deferred Pause transaction")
	# Called outside physics after a complete native tick. Notification pauses
	# immediately; capture the actual stopped unit before deferred persistence.
	var stopped: Dictionary = game.capture_campaign_snapshot()
	var wire: String = FocusExact.stringify(stopped)
	_expect(not stopped.is_empty() and not wire.is_empty(), "stopped actual actor/enemy/supply snapshot is nonempty")
	await _settle()
	var saved: Dictionary = game.attempts.active_snapshot()
	_expect(paused and game.menu.page_name() == "pause" and game.campaign_error.is_empty() and tracked.writes == 1 and game._operations.is_empty() and game._failed_operations.is_empty(), "active notification publishes exactly one successful Pause save")
	_expect(not saved.is_empty() and FocusExact.stringify(saved) == wire and FocusExact.stringify(game.capture_campaign_snapshot()) == wire, "actual complete stopped aggregate equals durable and retained live unit exactly")
	_expect(saved.player.resources.hp == hp and saved.player.resources.shells == shells and saved.level.local.guard.resources.hp == enemy_hp and saved.level.local.charges == 0 and saved.level.local.collected == ["supply-1"] and saved.equipment_ids == actor.equipment.snapshot(), "pause keeps injured Hero/enemy, empty ammo, gear and spent supply without refill")
	var disk: Dictionary = FocusStore.new(TEST_ROOT + "campaign.json").read_payload()
	_expect(not disk.is_empty() and FocusExact.stringify(disk) == FocusExact.stringify(game.attempts.state()) and FocusExact.stringify(game.attempts.state().story.checkpoint) == checkpoint, "format2 disk matches Attempts while original Retry checkpoint stays protected")
	var release := InputEventScreenTouch.new()
	release.index = 73
	release.position = press.position
	release.pressed = false
	game.get_viewport().push_input(release)
	game.resume_campaign()
	game.get_viewport().push_input(release)
	_expect(not paused and game.get_input_observation_state() == observation and actor.get_world_action_records() == records and events.is_empty(), "consumed pointer cannot fire primary/blast or alter aim after legitimate living Resume")
	game.request_pause()
	await _settle()
	await _focus_dispose_shell()

func _focus_fatal_notifications() -> void:
	if not await _focus_begin_live(0.1):
		await _focus_dispose_shell()
		return
	game.resume_campaign()
	for tick: int in range(180):
		if game.player.dead:
			break
		await _focus_ticks(1)
	await _settle()
	_expect(game.player.dead and game.player.hp == 0.0 and paused and game.menu.page_name() == "pause", "real enemy controller contact reaches death and existing automatic paused barrier")
	if not game.player.dead:
		await _focus_dispose_shell()
		return
	var fatal: Dictionary = game.capture_campaign_snapshot()
	var wire: String = FocusExact.stringify(fatal)
	_expect(not fatal.is_empty() and not wire.is_empty() and fatal.player.resources.dead and game.attempts.active_snapshot().player.resources.dead and fatal.level.local.guard.clocks.active_left_s > 0.0, "actual fatal strike/dead resource/native active receipt is retained without fake lethal assignment")
	var tracked: FocusWriteStore = _focus_track_store()
	for notification: int in [Node.NOTIFICATION_APPLICATION_FOCUS_OUT, Node.NOTIFICATION_APPLICATION_PAUSED]:
		game.notification(notification)
		await _settle()
		_expect(paused and game.player.dead and game.menu.page_name() == "pause" and FocusExact.stringify(game.capture_campaign_snapshot()) == wire and FocusExact.stringify(game.attempts.active_snapshot()) == wire, "fatal notification preserves exact native dead aggregate with no resume/heal")
	_expect(tracked.writes == 2, "actual fatal level preserves both existing notification Pause saves")
	var disk: Dictionary = _focus_disk_receipt()
	var attempts_before: String = FocusExact.stringify(game.attempts.state())
	game.resume_campaign()
	await _settle()
	_expect(paused and game.player.dead and game.player.hp == 0.0 and (game.menu.find_child("MenuStatus", true, false) as Label).text == "Retry your saved checkpoint.", "dead Resume remains consumed with existing Retry explanation")
	_expect(tracked.writes == 2 and _focus_disk_receipt() == disk and FocusExact.stringify(game.attempts.state()) == attempts_before and FocusExact.stringify(game.capture_campaign_snapshot()) == wire, "dead Resume preserves resources/history, Attempts and disk")
	await _focus_dispose_shell()

func _focus_ticks(count: int) -> void:
	for tick: int in range(count):
		await physics_frame
		await process_frame

func _focus_dispose_shell() -> void:
	paused = true
	if is_instance_valid(game):
		if is_instance_valid(game.fx):
			game.fx.clear_lab()
		# Stop/flush native audio and effects only after all case assertions.
		await create_timer(0.1, true).timeout
		game.free()
		game = null
		await _settle()
	_cleanup()

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
