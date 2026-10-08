extends SceneTree

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const FixturePath: String = "res://tests/fixtures/levels/contract_level.tscn"

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game: Node = MainScene.instantiate()
	root.add_child(game)
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	_expect(game.call("is_lab_level") and String(game.get("level_scene_path")).is_empty(), "default launch selects the existing character lab")
	_expect(hero.global_position.is_equal_approx(game.get("player_start")), "default lab retains its exact authored spawn")
	_expect(get_nodes_in_group("practice_targets").size() == 3 and get_nodes_in_group("lab_weapons").size() == 3, "default lab retains three targets and three weapon candidates")
	game.call("choose_exercise", "duel")
	_expect(get_nodes_in_group("enemies").size() == 1, "default lab still switches to its one-enemy exercise")
	game.call("choose_exercise", "targets")

	_expect(game.call("load_level_scene", FixturePath), "custom level passes the scene contract")
	var level: CinderLevel = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	var effects: PixelEffects = game.get("fx") as PixelEffects
	var camera: Camera3D = game.get("camera") as Camera3D
	var locked_basis: Basis = camera.global_basis
	var spawn_camera_offset: Vector3 = camera.global_position - hero.global_position
	_expect(not game.call("is_lab_level") and game.get("level_scene_path") == FixturePath, "custom scene replaces only the level selection")
	_expect(hero.global_position.is_equal_approx(Vector3(3.5, 0.1, -3.0)), "spawn uses the marker's world position, including the level transform")
	_expect(level.hero == hero and level.effects == effects and int(level.get("enter_count")) == 1, "entry receives the one shared player and effects exactly once")
	level.enter_level(hero, effects)
	_expect(int(level.get("enter_count")) == 1, "duplicate lifecycle entry does not duplicate content or callbacks")
	_expect(get_nodes_in_group("practice_targets").is_empty() and get_nodes_in_group("lab_weapons").is_empty(), "custom preview omits all lab targets and weapon stands")
	var enemy: AshEnemy = level.get_node("LevelEnemy") as AshEnemy
	_expect(get_nodes_in_group("enemies").size() == 1 and enemy.get("_hero") == hero and enemy.get("_fx") == effects, "level-owned enemy is configured against shared systems")
	game.call("choose_exercise", "arena")
	_expect(game.get("active_level") == level and get_nodes_in_group("enemies").size() == 1, "lab exercise requests cannot replace a custom level")
	_test_campaign_contract(level, hero)

	var screen_center: Vector2 = root.get_visible_rect().size * 0.5
	game.call("_record_swipe_end", screen_center - Vector2(30, 20))
	var expected_aim: Vector3 = game.call("aim_direction", screen_center)
	var actions: Array[String] = []
	hero.fired.connect(func(kind: String) -> void: actions.append(kind))
	game.call("handle_tap", screen_center)
	game.call("handle_tap", screen_center)
	_expect(actions == ["slash", "blast"] and hero.facing.dot(expected_aim) > 0.999, "custom preview preserves immediate slash, one second-tap blast and release-point aim")

	# An explicit preview reset restores supplies but carries existing gear.
	hero.equip_item("WEAPON-02")
	await create_timer(0.25).timeout
	hero.hp = 35.0
	hero.shells = 0
	effects.burst(hero.global_position + Vector3.UP, Color.WHITE, 2, 2.0)
	var old_hero: CinderPlayer = hero
	var old_level: CinderLevel = level
	var old_prop: Node = level.get_node("RuntimeProp")
	var observed_before_exit: int = int(level.get("observed_actions"))
	game.call("reset_lab")
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	_expect(level != old_level and hero != old_hero and int(level.get("enter_count")) == 1, "reset creates fresh level and player instances")
	_expect(int(old_level.get("exit_count")) == 1 and old_level.hero == null and old_level.effects == null, "reset exits once and releases shared references")
	_expect(bool(old_level.get("lifecycle_requests_blocked")) and not old_level.request_completion() and not old_level.request_checkpoint("after-exit") and old_level.snapshot_state().is_empty(), "exited level callbacks and later calls cannot allocate progression or capture stale state")
	old_hero.fired.emit("slash")
	_expect(int(old_level.get("observed_actions")) == observed_before_exit, "exit disconnects the level's shared-player callback")
	_expect(hero.hp == hero.max_hp and hero.shells == hero.max_shells and hero.equipment.snapshot()["weapon"] == "WEAPON-02", "reset restores HP/ammo and preserves carried static weapon")
	_expect(hero.global_position.is_equal_approx(Vector3(3.5, 0.1, -3.0)) and (game.call("get_aim_anchor") as Vector2).is_equal_approx(screen_center), "reset restores the selected spawn and center aim anchor")
	_expect(camera.global_basis.is_equal_approx(locked_basis) and camera.global_position.is_equal_approx(hero.global_position + spawn_camera_offset), "reset snaps the shared camera without changing its angle")
	_expect(effects.active_chunk_count() == 0 and get_nodes_in_group("enemies").size() == 1, "reset clears old effects and replaces level-owned enemies")
	await process_frame
	_expect(not is_instance_valid(old_level) and not is_instance_valid(old_prop) and not is_instance_valid(old_hero), "old level, runtime children and player are freed after reset")

	# Failures preserve the selected scene and carry an inspectable reason.
	for invalid_path: String in ["res://tests/fixtures/levels/absent.tscn", "res://tests/fixtures/levels/wrong_root.tscn", "res://tests/fixtures/levels/missing_spawn.tscn", "user://outside.tscn"]:
		_expect(not game.call("load_level_scene", invalid_path) and not String(game.get("level_load_error")).is_empty() and game.get("active_level") == level, "invalid scene is rejected explicitly without silently selecting the lab: " + invalid_path)

	game.call("open_bench")
	var hud: GameHUD = game.get("hud") as GameHUD
	_expect(paused and not (game.get("bench") as LabBench).visible and (hud.get("_card_button") as Button).text.begins_with("RESUME"), "custom pause offers resume without lab loadout/exercise controls")
	var resumed_actions: Array[String] = []
	hero.fired.connect(func(kind: String) -> void: resumed_actions.append(kind))
	await _click((hud.get("_card_button") as Button).get_global_rect().get_center())
	_expect(not paused and resumed_actions.is_empty(), "custom resume tap is consumed before combat input")
	await process_frame
	_expect(String(hud.get("_objective_text")) == "CONTRACT FIXTURE" and not (hud.get("_telemetry_label") as Label).visible, "preview HUD uses the level objective and suppresses lab telemetry")

	_expect(game.call("load_level_scene", "") and game.call("is_lab_level"), "explicit empty selection returns to the default lab")
	_expect(get_nodes_in_group("practice_targets").size() == 3 and get_nodes_in_group("lab_weapons").size() == 3 and get_nodes_in_group("enemies").is_empty(), "returning to lab restores its fixtures without retaining custom enemies")
	game.queue_free()
	paused = false
	await process_frame

	# A scene path set before startup uses the same interface as the CLI argument.
	game = MainScene.instantiate()
	game.set("level_scene_path", FixturePath)
	root.add_child(game)
	_expect(not game.call("is_lab_level") and get_nodes_in_group("lab_weapons").is_empty(), "startup scene injection bypasses lab fixtures")
	game.queue_free()
	await process_frame
	print("Level contract smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_campaign_contract(level: CinderLevel, hero: CinderPlayer) -> void:
	_expect(CinderLevel.API_REVISION == "campaign-level-1" and level.level_id.is_empty(), "additive campaign revision retains anonymous preview identity")
	_expect(bool(level.get("lifecycle_requests_blocked")) and int(level.get("enter_count")) == 1 and level.hero == hero, "entry guards recursive lifecycle calls and progression requests")
	var unentered: CinderLevel = load(FixturePath).instantiate() as CinderLevel
	unentered.level_id = "A2-O2"
	_expect(unentered.contract_error().is_empty(), "canonical optional ID is accepted without registering fixture campaign content")
	unentered.level_id = "A9-L1"
	_expect(not unentered.contract_error().is_empty(), "out-of-campaign level IDs fail the scene contract")
	unentered.level_id = "A1-L1\n"
	_expect(not unentered.contract_error().is_empty(), "canonical scene identity rejects a trailing newline instead of accepting a partial regex match")
	unentered.level_id = ""
	unentered.local_snapshot_version = 0
	_expect(not unentered.contract_error().is_empty(), "nonpositive local snapshot version fails the scene contract")
	unentered.local_snapshot_version = 1
	_expect(not unentered.request_completion() and not unentered.request_checkpoint("unentered") and unentered.snapshot_state().is_empty(), "unentered levels cannot allocate events or capture state")
	unentered.free()

	var initial: Dictionary = level.snapshot_state()
	_expect(not initial.is_empty() and level.snapshot_error(initial).is_empty(), "entered fixture captures a valid versioned local snapshot")
	_expect(initial["scene_path"] == FixturePath and initial["level_id"] == "" and initial["local_snapshot_version"] == 1, "snapshot preserves authored scene and anonymous identity separately")
	_test_snapshot_depth(level, initial)
	var edited: Dictionary = level.snapshot_state()
	edited["local"]["supply"]["charges"] = 0
	edited["local"]["collected_ids"].append("not-collected")
	_expect((level.get("local_state") as Dictionary)["supply"]["charges"] == 3 and (level.get("local_state") as Dictionary)["collected_ids"].size() == 1, "snapshot edits cannot spend live supplies or alter collected IDs")
	level.level_id = "A1-L1"
	_expect(level.snapshot_state().is_empty() and not level.request_checkpoint("identity-drift"), "active level identity cannot silently change after entry")
	level.level_id = ""
	level.local_snapshot_version = 2
	_expect(level.snapshot_state().is_empty(), "active local schema cannot silently change after entry")
	level.local_snapshot_version = 1

	var checkpoints: Array[Dictionary] = []
	var event_snapshots: Array[Dictionary] = []
	var rejected_reentrant: Array[bool] = []
	level.checkpoint_requested.connect(func(id: String, checkpoint: String, kind: String) -> void:
		checkpoints.append({"level": id, "id": checkpoint, "kind": kind})
		event_snapshots.append(level.snapshot_state())
		rejected_reentrant.append(not level.request_checkpoint("callback-leak")))
	_expect(not level.request_checkpoint("", "encounter") and not level.request_checkpoint("invalid kind", "boss_phase") and not level.request_checkpoint("bad-boundary", "timer"), "checkpoint requests reject unstable IDs and non-authored boundary kinds")
	_expect(not level.request_checkpoint("checkpoint\n") and not level.request_completion("complete\n") and not level.is_completed() and checkpoints.is_empty(), "newline-suffixed progression IDs allocate no checkpoint or completion state")
	_expect(level.request_checkpoint("encounter-1"), "encounter boundary emits a checkpoint request")
	_expect(checkpoints.size() == 1 and checkpoints[0] == {"level": "", "id": "encounter-1", "kind": "encounter"} and rejected_reentrant[0], "checkpoint event preserves identity and rejects callback reentrancy")
	_expect(event_snapshots[0]["progress"]["checkpoint_id"] == "encounter-1", "checkpoint state is committed before its consumer captures a coherent snapshot")
	_expect(not level.request_checkpoint("encounter-1") and not level.request_checkpoint("encounter-1", "boss_phase") and checkpoints.size() == 1, "checkpoint ID is idempotent across repeated or relabeled boundary requests")
	_expect(level.request_checkpoint("phase-2", "boss_phase") and level.current_checkpoint() == {"id": "phase-2", "kind": "boss_phase"}, "boss-phase boundary becomes the current checkpoint")
	var checkpoint_view: Dictionary = level.current_checkpoint()
	checkpoint_view["id"] = "altered"
	_expect(level.current_checkpoint()["id"] == "phase-2", "checkpoint view is independent of the live request history")
	var checkpoint_snapshot: Dictionary = level.snapshot_state()
	_expect(not level.is_completed() and checkpoint_snapshot["local"] == initial["local"], "checkpoint requests change no local supply or clock state and imply no healing")

	var completions: Array[String] = []
	level.completion_requested.connect(func(id: String, completion: String) -> void:
		completions.append(id + ":" + completion)
		event_snapshots.append(level.snapshot_state())
		rejected_reentrant.append(not level.request_completion("callback-complete")))
	var exits: Array[String] = []
	level.contact_exit_requested.connect(func(id: String, exit_id: String) -> void:
		exits.append(id + ":" + exit_id)
		rejected_reentrant.append(not level.request_contact_exit("other-exit", hero)))
	var other_body := Node3D.new()
	_expect(not level.request_contact_exit("exit", hero), "contact exit remains blocked until the authored completion condition is requested")
	_expect(level.request_completion("objective-clear") and level.is_completed() and completions == [":objective-clear"], "completion emits one request after marking the level completed")
	_expect(event_snapshots.back()["progress"]["completed"] and rejected_reentrant.back(), "completion consumers observe committed state and cannot recursively complete again")
	_expect(not level.request_completion("second-clear") and not level.request_checkpoint("after-completion"), "completion suppresses duplicate completion and later checkpoint allocations")
	_expect(not level.request_contact_exit("exit", other_body), "another actor or scenic body cannot cross the shared-player contact exit")
	_expect(not level.request_contact_exit("exit\n", hero) and exits.is_empty(), "newline-suffixed contact exit cannot consume the available transition")
	hero.dead = true
	_expect(not level.request_contact_exit("exit", hero), "a dead shared player cannot allocate a contact transition")
	hero.dead = false
	_expect(level.request_contact_exit("exit", hero) and exits == [":exit"] and rejected_reentrant.back(), "live shared-player contact emits one guarded exit request")
	_expect(not level.request_contact_exit("exit", hero) and not level.request_contact_exit("other-exit", hero), "a completed attempt cannot allocate more than one contact exit")
	other_body.free()
	var completed: Dictionary = level.snapshot_state()
	var before_rejections: Dictionary = level.snapshot_state()
	var restore_count: int = int(level.get("restore_count"))
	var malformed: Array[Dictionary] = []
	for key: String in ["api_revision", "schema_version", "level_id", "scene_path", "local_snapshot_version"]:
		var rejected: Dictionary = completed.duplicate(true)
		rejected[key] = 99 if key.ends_with("version") else "wrong-identity"
		malformed.append(rejected)
	var missing_local: Dictionary = completed.duplicate(true)
	missing_local.erase("local")
	malformed.append(missing_local)
	var inconsistent_completion: Dictionary = completed.duplicate(true)
	inconsistent_completion["progress"]["completed"] = false
	malformed.append(inconsistent_completion)
	var inconsistent_checkpoint: Dictionary = completed.duplicate(true)
	inconsistent_checkpoint["progress"]["checkpoint_ids"].erase("phase-2")
	malformed.append(inconsistent_checkpoint)
	var invalid_supply: Dictionary = completed.duplicate(true)
	invalid_supply["local"]["supply"]["charges"] = -1
	malformed.append(invalid_supply)
	var fractional_supply: Dictionary = completed.duplicate(true)
	fractional_supply["local"]["supply"]["charges"] = 1.5
	malformed.append(fractional_supply)
	var shared_reference: Dictionary = completed.duplicate(true)
	shared_reference["local"]["supply"]["charges"] = hero
	malformed.append(shared_reference)
	var invalid_number: Dictionary = completed.duplicate(true)
	invalid_number["local"]["clock_s"] = INF
	malformed.append(invalid_number)
	for key: String in ["completion_id", "contact_exit_id"]:
		var newline_id: Dictionary = completed.duplicate(true)
		newline_id["progress"][key] += "\n"
		malformed.append(newline_id)
	var newline_checkpoint: Dictionary = completed.duplicate(true)
	newline_checkpoint["progress"]["checkpoint_ids"]["checkpoint\n"] = "encounter"
	malformed.append(newline_checkpoint)
	for rejected: Dictionary in malformed:
		_expect(not level.snapshot_error(rejected).is_empty() and not level.restore_state(rejected) and level.snapshot_state() == before_rejections and int(level.get("restore_count")) == restore_count, "invalid identity/version/progress/local data rejects before any mutation")
	var event_count: int = checkpoints.size() + completions.size() + exits.size()
	level.set("probe_restore_guards", true)
	_expect(level.restore_state(checkpoint_snapshot) and not level.is_completed() and level.current_checkpoint()["id"] == "phase-2", "restoring an earlier coherent local checkpoint reopens completion and contact exit")
	_expect(bool(level.get("restore_requests_blocked")) and int(level.get("enter_count")) == 1 and level.hero == hero and level.last_snapshot_error.is_empty(), "restore hook blocks recursive capture/restore/lifecycle/progression and retains shared references")
	_expect(checkpoints.size() + completions.size() + exits.size() == event_count, "restoration does not re-emit checkpoint, completion or contact-exit requests")
	checkpoint_snapshot["local"]["supply"]["charges"] = 0
	_expect((level.get("local_state") as Dictionary)["supply"]["charges"] == 3, "caller edits after restoration cannot mutate retained local state")
	_expect(not level.request_checkpoint("phase-2", "boss_phase"), "restored checkpoint history retains event deduplication")
	_expect(level.request_completion("objective-clear") and level.request_contact_exit("exit", hero) and completions.size() == 2 and exits.size() == 2, "retry may request completion/contact again after restoring a prior boundary")
	var round_trip: Dictionary = JSON.parse_string(JSON.stringify(initial))
	_expect(level.restore_state(round_trip) and level.snapshot_state()["local"] == initial["local"], "JSON round-trip preserves local state and accepts integral version numbers")
	_expect((level.get("local_state") as Dictionary)["supply"]["charges"] is int, "validated JSON supply counts commit as canonical integers without permitting fractional charges")
	_expect(level.current_checkpoint()["id"].is_empty() and not level.is_completed() and level.request_checkpoint("encounter-1"), "restoring the initial state coherently removes later request history")
	_expect(level.restore_state(initial), "campaign contract tests leave the preview at its original local state")


func _test_snapshot_depth(level: CinderLevel, initial: Dictionary) -> void:
	# local root = depth 0; nested_payload begins at 1 and its leaf is at 32.
	var live_state: Dictionary = level.get("local_state")
	live_state["nested_payload"] = _nested_payload(31)
	var maximum: Dictionary = level.snapshot_state()
	_expect(not maximum.is_empty() and level.snapshot_error(maximum).is_empty(), "maximum-depth local capture remains valid inside its snapshot envelope")
	_expect(level.restore_state(maximum) and level.snapshot_state() == maximum, "32-level local payload round-trips without counting the transport envelope")
	var too_deep: Dictionary = maximum.duplicate(true)
	too_deep["local"]["nested_payload"] = _nested_payload(32)
	live_state = level.get("local_state")
	live_state["nested_payload"] = _nested_payload(32)
	_expect(level.snapshot_state().is_empty() and level.last_snapshot_error.contains("nesting"), "capture rejects local data one level beyond the permitted nesting boundary")
	_expect(level.restore_state(maximum) and not level.snapshot_error(too_deep).is_empty() and not level.restore_state(too_deep) and level.snapshot_state() == maximum, "over-depth restoration rejects before mutating the accepted boundary state")
	_expect(level.restore_state(initial), "nesting-boundary checks restore the fixture's original local supplies and fields")


func _nested_payload(leaf_depth: int) -> Dictionary:
	var nested: Variant = "fixture-leaf"
	for _index: int in range(leaf_depth):
		nested = {"next": nested}
	return nested as Dictionary


func _click(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	root.push_input(motion, true)
	await process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = at
	press.global_position = at
	root.push_input(press, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = at
	release.global_position = at
	root.push_input(release, true)
	await process_frame


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
