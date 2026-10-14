extends SceneTree
## SOURCE ONLY until the Act 1 owner promotes, imports and runs it.
## Production Shell/public menu signals with isolated TEST registry/save paths.
## Only the O1 registry row is TEST enabled. The explicit prior-main prefix and
## actual-floor Hero placements are not earned routes or GUI/input credit.
## Real contacts, native leases, clock, ordinary primary, checkpoint and hatch
## determine all O1 progress. No actor HP/phase/sample/history is assigned.

const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Attempts = preload("res://scripts/campaign/attempts.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Equipment = preload("res://scripts/equipment.gd")
const MainScene = preload("res://scenes/main.tscn")
const Layout = preload("res://scripts/acts/act1/salvage_circuit_layout.gd")
const O1Script = preload("res://scripts/acts/act1/salvage_circuit.gd")
const Rush = preload("res://scripts/acts/act1/rush_selenite.gd")
const Lane = preload("res://scripts/combat/lane_mechanism.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Threat = preload("res://scripts/cues/threat_cue.gd")
const Interaction = preload("res://scripts/cues/interaction_cue.gd")
const O1_PATH: String = "res://scenes/acts/act1/a1_o1.tscn"
const STORY_PATH: String = "res://scenes/acts/act1/a1_l2.tscn"
const PREFIX: Array[String] = ["A1-L1", "A1-L2"]
const REWARD_ID: String = "A1-O1-completion-stamp"
const WATCHDOG_MS: int = 120000
const LANDING_PHYSICAL_BOUND: float = 0.035

var game: CinderCampaignShell
var preview: Node
var raw: Dictionary = {}
var registry_bytes: PackedByteArray
var test_root: String
var report_path: String
var checks: int = 0
var failures: int = 0
var first_failure: Dictionary = {}
var started_ms: int = 0
var finishing: bool = false
var operation: String = "source setup"
var observations: Array[Dictionary] = []
var admissions: Dictionary = {}
var receipts: Array[Dictionary] = []
var setups: Array[Dictionary] = []
var protected_story: Dictionary = {}
var unlocked_before: Array = []
var old_fps: int
var old_audio: AudioBusLayout


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	test_root = "user://test-act1-o1-campaign-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	report_path = "res://.cinder/a1-o1-campaign-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	old_fps = Engine.max_fps
	old_audio = AudioServer.generate_bus_layout()
	process_frame.connect(_watchdog)
	node_added.connect(_observe_added)
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--level-scene") or argument in ["--capture", "--capture-polish"]:
			_expect(false, "campaign fixture requires production Shell rather than preview-mode arguments"); await _finish(); return
	registry_bytes = FileAccess.get_file_as_bytes(Registry.DATA_PATH)
	var parsed: Variant = JSON.parse_string(registry_bytes.get_string_from_utf8())
	if not _expect(parsed is Dictionary and parsed.get("levels") is Array, "canonical registry provides the isolated TEST clone"):
		await _finish(); return
	raw = parsed.duplicate(true)
	var changed: int = 0
	for row: Dictionary in raw.levels:
		if row.id == Layout.LEVEL_ID:
			setups.append({"kind": "TEST in-memory O1 row only", "before": row.duplicate(true), "scene_path": O1_PATH, "accepted_commit": "f".repeat(40)})
			row.scene_path = O1_PATH; row.readiness = "accepted"; row.accepted_commit = "f".repeat(40); row.api_revision = Registry.API_REVISION
			changed += 1
	var registry: CinderCampaignRegistry = Registry.new(raw)
	if not _expect(changed == 1 and registry.last_error.is_empty() and registry.scene_error(Layout.LEVEL_ID).is_empty() and registry.scene_error("A1-L2").is_empty(), "only O1 readiness is TEST enabled; accepted native L2 story stays unchanged"):
		await _finish(); return
	var entry: Dictionary = registry.entry(Layout.LEVEL_ID)
	if not _expect(entry.parent_level_id == "A1-L2" and not registry.is_unlocked(Layout.LEVEL_ID, ["A1-L1"]) and registry.is_unlocked(Layout.LEVEL_ID, PREFIX) and entry.reward_id == REWARD_ID and entry.reward_policy == "once_only_completion_stamp_no_stat_growth", "canonical L2 parent unlock and existing once-only stamp policy govern O1"):
		await _finish(); return
	if not await _seed_story(registry) or not await _new_shell(): await _finish(); return
	operation = "initial public Continue Story"
	game.menu.continue_story_requested.emit()
	if not await _await_operation(func() -> bool: return _live("A1-L2") and paused and game.menu.page_name() == "resume", "public Continue installs the actual protected L2 story", 8.0):
		await _finish(); return
	protected_story = game.attempts.state().story.duplicate(true)
	unlocked_before = game.attempts.state().unlocked_equipment.duplicate()
	var story_unit: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_closed(story_unit) and _same(story_unit, protected_story.snapshot) and game.attempts.state().completed_main == PREFIX and _durable(), "actual pristine whole L2 unit is the protected story under disclosed TEST completed prefix"):
		await _finish(); return
	operation = "public Optional entry"
	game.menu.optional_requested.emit(Layout.LEVEL_ID)
	if not await _await_operation(func() -> bool: return _live(Layout.LEVEL_ID) and paused and game.menu.page_name() == "resume" and game.attempts.active_kind() == "optional", "public Optional installs O1 as an independent side attempt", 8.0):
		await _finish(); return
	var entrance: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_closed(entrance) and _same(game.attempts.state().story, protected_story) and _same(game.attempts.state().side_attempt.checkpoint, entrance) and entrance.level.local.stage == "circuit" and entrance.level.local.collected_ids.is_empty() and entrance.level.local.sources[Layout.FINAL_SOURCE_ID].dormant and entrance.level.local.scheduler.clock_s == 0.0 and _bindings(), "actual side entrance protects the entire L2 story and starts pristine native O1 with its own checkpoint"):
		await _finish(); return
	receipts.append({"label": "actual optional entrance", "exact_snapshot": Exact.stringify(entrance), "protected_story": Exact.stringify(protected_story)})
	if not await _contact_part("nose-cap"): await _finish(); return
	if not await _wait_live(func() -> bool: return _source(Layout.CIRCUIT_SOURCE_ID).state().status == "running" and not _source(Layout.CIRCUIT_SOURCE_ID).state().reservation_id.is_empty() and _impact().state().status == "running" and _impact().state().phase in ["warning", "lock"], "natural live circuit C30 and companion impact", 10.0):
		await _finish(); return
	if not await _pause("partial contact and live native exchange Save"): await _finish(); return
	var partial: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_closed(partial) and partial.level.local.collected_ids == ["nose-cap"] and partial.level.local.stage == "circuit" and not partial.level.local.sources[Layout.CIRCUIT_SOURCE_ID].reservation_id.is_empty() and partial.level.local.impact.status == "running" and partial.level.local.scheduler.reservations.size() == 2 and partial.level.local.sources[Layout.FINAL_SOURCE_ID].dormant and partial.level.progress.checkpoint_ids.is_empty() and _same(game.attempts.state().side_attempt.checkpoint, entrance) and _same(game.attempts.state().story, protected_story) and _durable(), "public Pause stores the genuine partial-contact/live-two-source unit without replacing earlier checkpoint or story"):
		await _finish(); return
	receipts.append({"label": "actual partial contact live C30-impact Save", "exact_snapshot": Exact.stringify(partial), "exact_checkpoint": Exact.stringify(entrance)})
	if not await _reopen_side(partial, "partial-contact native packet"): await _finish(); return
	for id: String in ["hatch-disc", "rivet-band"]:
		if not await _contact_part(id): await _finish(); return
	if not await _await_operation(func() -> bool: return _stored_checkpoint_ready(), "actual three-part pre-final checkpoint commits", 10.0):
		await _finish(); return
	var checkpoint: Dictionary = game.attempts.state().side_attempt.checkpoint.duplicate(true)
	if not _expect(_closed(checkpoint) and checkpoint.level.local.collected_ids == ["nose-cap", "hatch-disc", "rivet-band"] and checkpoint.level.local.stage == "final" and checkpoint.level.local.checkpoint_published and not checkpoint.level.local.final_started and checkpoint.level.local.sources[Layout.FINAL_SOURCE_ID].dormant and checkpoint.level.local.sources[Layout.FINAL_SOURCE_ID].cycle == 0 and checkpoint.level.progress.checkpoint_ids == {Layout.CHECKPOINT_ID: "encounter"} and checkpoint.level.local.scheduler.reservations.is_empty() and _same(game.attempts.state().story, protected_story) and _durable(), "genuine stored three-contact checkpoint precedes final epoch and retains exact non-recipe order"):
		await _finish(); return
	receipts.append({"label": "actual pre-final checkpoint", "exact_snapshot": Exact.stringify(checkpoint)})
	# Auto-resume may already have activated the final after this earlier saved
	# checkpoint. The stored checkpoint above, never a late fallback, is evidence.
	if not paused and not await _pause("after actual checkpoint drain"): await _finish(); return
	if not await _resume("actual final warning observation"):
		await _finish(); return
	if not await _wait_live(func() -> bool: return _source(Layout.FINAL_SOURCE_ID).state().status == "running" and _source(Layout.FINAL_SOURCE_ID).state().phase == "warning", "natural final-rusher warning", 10.0):
		await _finish(); return
	if not await _pause("actual final warning Save"): await _finish(); return
	var final_warning: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_closed(final_warning) and final_warning.level.local.stage == "final" and final_warning.level.local.final_started and not final_warning.level.local.final_defeated and not final_warning.level.local.sources[Layout.FINAL_SOURCE_ID].dormant and not final_warning.level.local.sources[Layout.FINAL_SOURCE_ID].reservation_id.is_empty() and final_warning.level.local.scheduler.encounter_id == "salvage-final-encounter" and final_warning.level.local.sources[Layout.FINAL_SOURCE_ID].hp == 20.0 and _same(game.attempts.state().side_attempt.checkpoint, checkpoint) and _durable(), "later real final warning saves the new final epoch and complete old circuit history without replacing pre-final Retry"):
		await _finish(); return
	receipts.append({"label": "actual final warning Save", "exact_snapshot": Exact.stringify(final_warning), "exact_earlier_checkpoint": Exact.stringify(checkpoint)})
	if not await _reopen_side(final_warning, "final-warning native packet") or not await _retry_checkpoint(checkpoint):
		await _finish(); return
	if not await _resume("genuine final exchange after earlier Retry") or not await _wait_live(func() -> bool: return _final_admission().get("accepted", false) and _source(Layout.FINAL_SOURCE_ID).state().phase == "warning", "retried parent naturally publishes final warning and ordinary proof", 10.0):
		await _finish(); return
	var answer: Dictionary = _final_admission().duplicate(true)
	if not _expect(answer.reservation_id == _source(Layout.FINAL_SOURCE_ID).state().reservation_id and not answer.proof.uses_blast and not answer.proof.uses_invulnerability and game.player.equipment.snapshot() == Equipment.STARTER, "retried genuine final native reservation publishes a baseline ordinary response"):
		await _finish(); return
	if not await _final_primary(answer.proof): await _finish(); return
	if not await _wait_live(func() -> bool: return game.active_level.get("stage") == "hatch", "real final defeat settles repaired hatch", 8.0):
		await _finish(); return
	if not _expect(_source(Layout.FINAL_SOURCE_ID).dead and game.active_level.get("hatch_cue").state().state == "available" and game.active_level.get("hatch_cue").state().trigger == "contact" and game.active_level.get("scenery").call("presentation_state").repaired and not game.active_level.is_completed(), "real native final defeat enables the repaired contact hatch before completion"):
		await _finish(); return
	if not await _pause("before actual repaired-hatch contact"):
		await _finish(); return
	var hatch_unit: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_closed(hatch_unit) and hatch_unit.level.local.stage == "hatch" and hatch_unit.level.local.final_defeated and not hatch_unit.level.progress.completed and _same(game.attempts.state().story, protected_story), "actual pre-contact hatch unit remains incomplete and preserves story"):
		await _finish(); return
	receipts.append({"label": "actual repaired hatch before contact", "exact_snapshot": Exact.stringify(hatch_unit)})
	if not await _place(Layout.HATCH_POSITION + Vector3(0, -0.645, 0), "repaired hatch actual-floor contact"):
		await _finish(); return
	if not await _await_operation(func() -> bool: return _live("A1-L2") and paused and game.attempts.active_kind() == "story" and game.menu.page_name() == "journey", "real repaired-hatch contact completes O1 and restores protected story", 12.0):
		await _finish(); return
	var state: Dictionary = game.attempts.state()
	if not _expect(state.completed_main == PREFIX and state.completed_optional == [Layout.LEVEL_ID] and state.reward_ids == [REWARD_ID] and state.unlocked_equipment == unlocked_before and _same(state.story, protected_story) and _same(game.capture_campaign_snapshot(), protected_story.snapshot) and _durable(), "native optional completion records the one existing stamp with no main/stat/equipment growth and exact full story return"):
		await _finish(); return
	if not _expect(_observed_progress("completion") and _observed_progress("exit"), "real O1 completion and repaired-hatch exit requests were observed rather than seeded"):
		await _finish(); return
	receipts.append({"label": "actual completed optional protected-story return", "exact_attempts": Exact.stringify(state), "exact_story": Exact.stringify(game.capture_campaign_snapshot())})
	operation = "public completed-optional Replay entry"
	game.menu.replay_requested.emit(Layout.LEVEL_ID, Equipment.STARTER)
	if not await _await_operation(func() -> bool: return _live(Layout.LEVEL_ID) and paused and game.attempts.active_kind() == "replay" and game.menu.page_name() == "resume", "public Replay installs a fresh isolated O1", 8.0):
		await _finish(); return
	var replay: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_closed(replay) and replay.level.local.stage == "circuit" and replay.level.local.collected_ids.is_empty() and replay.level.local.sources[Layout.CIRCUIT_SOURCE_ID].hp == 20.0 and replay.level.local.sources[Layout.FINAL_SOURCE_ID].dormant and replay.level.local.scheduler.clock_s == 0.0 and game.player.hp == game.player.max_hp and game.player.shells == game.player.max_shells and game.attempts.state().reward_ids == [REWARD_ID] and game.attempts.state().completed_optional == [Layout.LEVEL_ID] and _same(game.attempts.state().story, protected_story), "optional Replay is pristine and retains exactly one existing stamp and full protected story"):
		await _finish(); return
	var replay_refs: Array[WeakRef] = _refs(game.world)
	operation = "public Replay Leave"
	game.menu.leave_side_requested.emit()
	if not await _await_operation(func() -> bool: return _live("A1-L2") and paused and game.attempts.active_kind() == "story" and game.menu.page_name() == "journey", "public replay Leave restores protected story", 8.0):
		await _finish(); return
	_expect(_freed(replay_refs) and game.attempts.state().reward_ids == [REWARD_ID] and game.attempts.state().completed_main == PREFIX and game.attempts.state().unlocked_equipment == unlocked_before and _same(game.attempts.state().story, protected_story) and _same(game.capture_campaign_snapshot(), protected_story.snapshot) and _durable(), "normal Replay Leave frees its native world and preserves exact story and once-only reward")
	await _finish()


func _seed_story(registry: CinderCampaignRegistry) -> bool:
	operation = "accepted L2 native Main story seed"
	paused = true
	preview = MainScene.instantiate(); preview.set("level_scene_path", STORY_PATH); root.add_child(preview)
	# Main.reset_lab releases pause during synchronous construction. Re-pause
	# immediately before any frame; keep exact native spawn/clock assertions.
	paused = true
	await process_frame; await process_frame
	var hero: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	if not _expect(hero != null and level != null and level.level_id == "A1-L2" and level.scene_file_path == STORY_PATH and level.contract_error().is_empty(), "unchanged accepted native L2 Main constructs the actual pristine protected unit"): return false
	var anchor: Vector2 = preview.call("get_aim_anchor_normalized")
	var camera: Camera3D = preview.get("camera") as Camera3D
	var snapshot: Dictionary = {"schema_version": 1, "level_id": "A1-L2", "scene_path": STORY_PATH, "paused": true, "equipment_ids": hero.equipment.snapshot(), "player": hero.snapshot_state(), "level": level.snapshot_state(), "shell": {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Vector3(0, 18, 13)), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}}
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var payload: Dictionary = model.state()
	payload.completed_main = PREFIX.duplicate()
	payload.story = {"kind": "story", "level_id": "A1-L2", "snapshot": snapshot.duplicate(true), "checkpoint": snapshot.duplicate(true)}
	var store: CinderSaveStore = Store.new(test_root + "campaign.json")
	store.payload_validator = model.saved_payload_error
	var pristine: bool = _closed(snapshot) and paused and hero.global_position == level.spawn_position() and snapshot.level.local.beat_index == 0 and snapshot.level.local.scheduler.clock_s == 0.0 and snapshot.level.progress.checkpoint_ids.is_empty() and not snapshot.level.progress.completed
	var accepted: bool = pristine and model.state_error(payload).is_empty() and store.write_payload(payload)
	setups.append({"kind": "TEST completed-main prefix, not earned route", "completed_main": PREFIX.duplicate(), "actual_story_scene": STORY_PATH, "local_progress_completed": snapshot.level.get("progress", {}).get("completed", false)})
	var note: String = model.state_error(payload) + store.last_error
	var refs: Array[WeakRef] = _refs(preview)
	level.exit_level(); preview.free(); preview = null
	return _expect(accepted and _freed(refs), "public validated Attempts/Store persists disclosed two-main TEST prefix plus actual pristine full L2 unit; normal Main disposal: " + note)


func _new_shell() -> bool:
	operation = "fresh actual disk Title"
	game = Shell.new() as CinderCampaignShell
	if not _expect(game.configure_runtime(raw, test_root + "campaign.json", test_root + "settings.json", test_root + "preferences.json"), "supported production Shell.configure_runtime uses only unique isolated stores"): return false
	root.add_child(game)
	if not await _await_operation(func() -> bool: return paused and game.player == null and game.active_level == null and game.menu.page_name() == "title" and not game.attempts.active_snapshot().is_empty(), "actual disk startup loads the saved model at Title without installed world", 8.0): return false
	return _expect(game.campaign_error.is_empty() and game.settings.storage_path() == test_root + "settings.json", "fresh Title validates the saved whole session using isolated settings")


func _reopen_side(saved: Dictionary, label: String) -> bool:
	var before: Dictionary = _ids()
	var disk: String = FileAccess.get_file_as_string(test_root + "campaign.json")
	var backup: String = FileAccess.get_file_as_string(test_root + "campaign.json.bak")
	var refs: Array[WeakRef] = _refs(game)
	operation = "normal donor Shell disposal: " + label
	game.free(); game = null
	await process_frame
	if not _expect(_freed(refs), "normal closed donor Shell frees its native descendants before independent disk recipient: " + label): return false
	if not await _new_shell(): return false
	operation = "Title public active-side Continue: " + label
	# Title Resume Side loads the saved active side. Continue Story would leave it.
	game.menu.resume_requested.emit()
	if not await _await_operation(func() -> bool: return _live(Layout.LEVEL_ID) and paused and game.menu.page_name() == "resume", "public active-side Continue installs saved O1", 8.0): return false
	var callbacks: Array[Dictionary] = _recipient_callbacks()
	var captured: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_same(captured, saved) and _all_new(before, _ids()) and callbacks.is_empty() and _bindings() and _same(game.attempts.state().story, protected_story) and FileAccess.get_file_as_string(test_root + "campaign.json") == disk and FileAccess.get_file_as_string(test_root + "campaign.json.bak") == backup and _durable(), "fresh disk active Continue restores an exact distinct installed native recipient with zero recipient callbacks and unchanged saved/protected unit: " + label): return false
	receipts.append({"label": "fresh public active-side disk Continue", "case": label, "exact_snapshot": Exact.stringify(captured), "new_installed_recipient_callbacks": callbacks, "new_identities": _ids()})
	return true


func _retry_checkpoint(expected: Dictionary) -> bool:
	var before: Dictionary = _ids()
	var refs: Array[WeakRef] = _refs(game.world)
	operation = "public earlier pre-final Retry"
	game.menu.retry_requested.emit()
	if not await _await_operation(func() -> bool: return _live(Layout.LEVEL_ID) and paused and game.menu.page_name() == "resume" and _ids() != before, "public Retry installs earlier real pre-final checkpoint", 8.0): return false
	var callbacks: Array[Dictionary] = _recipient_callbacks()
	if not _expect(_same(game.capture_campaign_snapshot(), expected) and _all_new(before, _ids()) and _freed(refs) and callbacks.is_empty() and _source(Layout.FINAL_SOURCE_ID).dormant and not game.active_level.get("final_started") and _same(game.attempts.state().story, protected_story) and _durable(), "actual Retry quietly restores exact earlier whole pre-final unit and frees later final-warning donor without new-recipient callbacks"): return false
	receipts.append({"label": "actual public earlier pre-final Retry", "exact_snapshot": Exact.stringify(expected), "new_installed_recipient_callbacks": callbacks})
	return true


func _contact_part(id: String) -> bool:
	if not _live(Layout.LEVEL_ID): return _expect(false, "actual O1 lost before contact placement")
	if not paused and not await _pause("before next TEST contact placement"): return false
	var prior: Array = (game.active_level.get("collected_ids") as Array).duplicate()
	if not await _place(Layout.PART_POSITIONS[id] + Vector3(0, 0.005, 0), "actual part contact " + id): return false
	if not await _wait_live(func() -> bool: return (game.active_level.get("collected_ids") as Array).has(id), "native Area collection: " + id, 8.0, true): return false
	var order: Array = prior.duplicate(); order.append(id)
	return _expect((game.active_level.get("collected_ids") as Array) == order, "production native contact appends one actual unique part in chosen order: " + id)


func _place(position: Vector3, label: String) -> bool:
	if not paused or not _live(Layout.LEVEL_ID): return _expect(false, "actual paused O1 barrier required for disclosed TEST placement")
	game.player.global_position = position; game.player.velocity = Vector3.ZERO
	setups.append({"kind": "TEST same-floor Hero placement, not earned route or GUI gesture", "label": label, "position": _encode(position)})
	return await _resume(label)


func _pause(label: String) -> bool:
	operation = "public Pause: " + label
	var generation_before: int = _save_generation()
	game.request_pause()
	if not await _await_operation(func() -> bool: return paused and game.menu.page_name() == "pause" and _save_generation() > generation_before, "deferred public Pause commits a new whole-unit Save generation", 8.0): return false
	return _expect(game.campaign_error.is_empty() and _durable(), "normal public Pause persists actual native unit: " + label)


func _resume(label: String) -> bool:
	operation = "public Resume: " + label
	game.menu.resume_requested.emit()
	return _expect(not paused and _live(Layout.LEVEL_ID) and not game.player.dead, "public Resume releases actual healthy optional simulation: " + label)


func _stored_checkpoint_ready() -> bool:
	if not _live(Layout.LEVEL_ID): return false
	var side: Variant = game.attempts.state().side_attempt
	return side is Dictionary and side.get("checkpoint") is Dictionary and side.checkpoint.get("level", {}).get("progress", {}).get("checkpoint_id", "") == Layout.CHECKPOINT_ID


func _final_primary(proof: Dictionary) -> bool:
	var paths: Array = proof.path
	if not _expect(paths.size() in [4, 6] and paths[1].kind == "escape_dash" and paths.back().kind == "ordinary_primary", "actual final admission supplies complete native ordinary-response path"): return false
	var hp_before: float = game.player.hp
	if not await _wait_live(func() -> bool: return _scheduler().get_clock() >= float(paths[0].end_s), "real final recognition/readiness", 4.0): return false
	if not await _dash_to(proof.landing, "final native proof escape"): return false
	if paths.size() == 6:
		if not await _wait_live(func() -> bool: return _scheduler().get_clock() >= float(paths[3].start_s), "real final positioning readiness", 8.0): return false
		if not await _dash_to(proof.attack_position, "final native proof positioning"): return false
	if not await _wait_live(func() -> bool: return _scheduler().get_clock() >= float(proof.primary_time_s) and _primary_ready(), "real final ordinary-primary opportunity", 8.0): return false
	var actor: Act1RushSelenite = _source(Layout.FINAL_SOURCE_ID)
	var state: Dictionary = actor.state()
	if not _expect(state.phase == "recovery" and state.get("adapter", {}).get("finished", false) and actor.velocity == Vector3.ZERO and game.player.hp == hp_before and actor.hp == 20.0 and not actor.dead, "actual final C30 finishes physical rush and offers an undamaged ordinary recovery opening"): return false
	var sequence: int = _last_sequence()
	var shells_before: int = game.player.shells
	var hits: int = game.player.slash((actor.global_position - game.player.global_position).normalized())
	var actions: Array[Dictionary] = game.player.get_world_action_records(sequence)
	if not _expect(hits == 1 and actor.dead and actor.hp == 0.0 and actions.size() == 1 and actions[0].kind == "primary" and actions[0].origin == "player_direct" and actions[0].hits == 1 and game.player.shells >= shells_before, "normal public ordinary20HP primary genuinely defeats final C30 once during recovery without blast"): return false
	receipts.append({"label": "actual ordinary final recovery primary", "clock_s": _scheduler().get_clock(), "source_before": _encode(state), "action": _encode(actions[0]), "hp_after": actor.hp})
	await process_frame
	return true


func _dash_to(landing: Vector3, label: String) -> bool:
	if not await _wait_live(_dash_ready, label + " readiness", 4.0): return false
	var direction := Vector3(landing.x - game.player.global_position.x, 0, landing.z - game.player.global_position.z).normalized()
	var sequence: int = _last_sequence()
	if not _expect(game.player.request_dash(direction), "ordinary public shared dash executes " + label): return false
	if not await _wait_live(_dash_ready, label + " deliberate stop", 4.0): return false
	var actions: Array[Dictionary] = game.player.get_world_action_records(sequence)
	var error: float = Vector2(game.player.global_position.x - landing.x, game.player.global_position.z - landing.z).length()
	receipts.append({"label": label, "native_landing": _encode(landing), "actual_endpoint": _encode(game.player.global_position), "physical_observation_error": error, "actions": _encode(actions)})
	return _expect(actions.size() == 1 and actions[0].kind == "dash" and actions[0].origin == "player_direct" and not actions[0].collision_shortened and error <= LANDING_PHYSICAL_BOUND, "actual unshortened shared dash finishes at proved final landing: " + label)


func _dash_ready() -> bool:
	if not _live(Layout.LEVEL_ID) or paused: return false
	var state: Dictionary = game.player.get_threat_response_state()
	return state.stable and not game.player.dead and float(state.commitment_remaining_s) == 0.0 and float(state.dash_cooldown_left_s) == 0.0


func _primary_ready() -> bool:
	return _dash_ready() and float(game.player.get_threat_response_state().primary_cooldown_left_s) == 0.0


func _last_sequence() -> int:
	var actions: Array[Dictionary] = game.player.get_world_action_records()
	return 0 if actions.is_empty() else int(actions.back().sequence)


func _live(id: String) -> bool:
	return is_instance_valid(game) and is_instance_valid(game.active_level) and is_instance_valid(game.player) and game.active_level.level_id == id and game.campaign_error.is_empty()


func _source(id: String) -> Act1RushSelenite:
	return (game.active_level.get("sources") as Dictionary).get(id) as Act1RushSelenite


func _impact() -> CinderLaneMechanism:
	return game.active_level.get("impact") as CinderLaneMechanism


func _scheduler() -> CinderThreatScheduler:
	return game.active_level.get("scheduler") as CinderThreatScheduler


func _final_admission() -> Dictionary:
	return admissions.get(str(game.active_level.get_instance_id()) + "/" + Layout.FINAL_SOURCE_ID, {})


func _bindings() -> bool:
	if not _live(Layout.LEVEL_ID) or game.active_level.hero != game.player or game.active_level.shared_shell != game or _count_players(game.world) != 1: return false
	var bindings: Dictionary = game.active_level.call("scheduler_bindings")
	if bindings.world_root != game.world or game.player.get_world_3d() != game.active_level.get_world_3d(): return false
	for actor: Node3D in [ _source(Layout.CIRCUIT_SOURCE_ID), _source(Layout.FINAL_SOURCE_ID), _impact(), _scheduler() ]:
		if actor.get_parent() != game.active_level or actor.get_world_3d() != game.player.get_world_3d(): return false
	return true


func _ids() -> Dictionary:
	if not _live(Layout.LEVEL_ID): return {}
	var value: Dictionary = {"world": str(game.world.get_instance_id()), "native_world": str(game.world.get_world_3d().get_instance_id()), "player": str(game.player.get_instance_id()), "level": str(game.active_level.get_instance_id()), "scheduler": str(_scheduler().get_instance_id())}
	for id: String in [Layout.CIRCUIT_SOURCE_ID, Layout.FINAL_SOURCE_ID]:
		value[id] = str(_source(id).get_instance_id()); value[id + "/cue"] = str(_source(id).get_cue().get_instance_id())
	value[Layout.IMPACT_ID] = str(_impact().get_instance_id()); value[Layout.IMPACT_ID + "/cue"] = str(_impact().get_cue().get_instance_id())
	return value


func _all_new(before: Dictionary, after: Dictionary) -> bool:
	if before.is_empty() or before.size() != after.size(): return false
	for key: String in before:
		if not after.has(key) or before[key] == after[key]: return false
	return true


func _durable() -> bool:
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(test_root + "campaign.json"))
	if not envelope is Dictionary or envelope.get("format_version") != 2: return false
	var parsed: Dictionary = Exact.parse(String(envelope.get("payload_json", "")))
	return parsed.get("accepted", false) and _same(parsed.value, game.attempts.state())


func _save_generation() -> int:
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(test_root + "campaign.json"))
	return int(envelope.get("generation", 0)) if envelope is Dictionary else 0


func _closed(unit: Dictionary) -> bool:
	return not unit.is_empty() and unit.get("player") is Dictionary and not unit.player.is_empty() and unit.get("level") is Dictionary and not unit.level.is_empty() and not Exact.stringify(unit).is_empty()


func _same(left: Variant, right: Variant) -> bool:
	var wire: String = Exact.stringify(left)
	return not wire.is_empty() and wire == Exact.stringify(right)


func _await_operation(predicate: Callable, label: String, seconds: float) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while not finishing and Time.get_ticks_msec() <= deadline:
		if not _operation_healthy(): return false
		if predicate.call() == true:
			# Observe a completed deferred frame; never call private Shell drain.
			await process_frame
			return _operation_healthy() and predicate.call() == true
		await process_frame
	return _expect(false, "bounded actual Shell operation failed: " + label)


func _wait_live(predicate: Callable, label: String, seconds: float, allow_authored_pause: bool = false) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while not finishing and Time.get_ticks_msec() <= deadline:
		if not _operation_healthy(): return false
		if predicate.call() == true: return true
		if not is_instance_valid(game.player) or game.player.dead: return _expect(false, "actual living shared Player lost: " + label)
		if paused and not allow_authored_pause: return _expect(false, "actual native pause interrupted live observation; no forced Resume/focus: " + label)
		await process_frame
	return _expect(false, "bounded actual native observation failed: " + label)


func _operation_healthy() -> bool:
	if finishing: return false
	if not is_instance_valid(game): return _expect(false, "actual Shell disappeared during operation")
	if not game.campaign_error.is_empty(): return _expect(false, "first actual Shell error during " + operation + ": " + game.campaign_error)
	if is_instance_valid(game.active_level) and not game.active_level.contract_error().is_empty(): return _expect(false, "first actual native level contract error: " + game.active_level.contract_error())
	return true


func _observe_added(node: Node) -> void:
	var ref: WeakRef = weakref(node)
	if node is CinderPlayer:
		node.fired.connect(func(kind: String) -> void: _record("fired", ref, {"kind": kind}))
		node.died.connect(func() -> void: _record("death", ref, {}))
		node.world_action_executed.connect(func(value: Dictionary) -> void: _record("world-action", ref, value))
		node.equipment_changed.connect(func(id: String) -> void: _record("equipment", ref, {"id": id}))
	if node is CinderLevel:
		node.checkpoint_requested.connect(func(id: String, checkpoint: String, kind: String) -> void: _record("checkpoint", ref, {"level_id": id, "id": checkpoint, "boundary": kind}))
		node.completion_requested.connect(func(id: String, complete: String) -> void: _record("completion", ref, {"level_id": id, "id": complete}))
		node.contact_exit_requested.connect(func(id: String, contact: String) -> void: _record("exit", ref, {"level_id": id, "id": contact}))
		if node.get_script() == O1Script:
			node.connect("part_collected", func(id: String, order: Array[String]) -> void: _record("part", ref, {"id": id, "order": order}))
			node.connect("native_admission_published", func(id: String, answer: Dictionary) -> void:
				var owner: Node = ref.get_ref() as Node
				if owner != null and answer.get("accepted", false): admissions[str(owner.get_instance_id()) + "/" + id] = answer.duplicate(true)
				_record("admission", ref, {"source_id": id, "answer": answer}))
	if node.get_script() in [Rush, Lane, Threat, Interaction]:
		node.connect("state_changed", func(value: Dictionary) -> void: _record("source-or-cue-state", ref, value))
	if node.get_script() == Rush:
		node.connect("defeated", func(id: String) -> void: _record("rusher-defeated", ref, {"source_id": id}))
	if node.get_script() == Scheduler:
		node.connect("reservation_invalidated", func(id: String, reason: String) -> void: _record("reservation-invalidated", ref, {"id": id, "reason": reason}))


func _record(kind: String, ref: WeakRef, value: Dictionary) -> void:
	var node: Node = ref.get_ref() as Node
	if node == null: return
	var level: CinderLevel = node as CinderLevel
	var ancestor: Node = node.get_parent()
	while level == null and ancestor != null:
		if ancestor is CinderLevel: level = ancestor
		ancestor = ancestor.get_parent()
	observations.append({"operation": operation, "kind": kind, "emitter_id": str(node.get_instance_id()), "level_instance_id": str(level.get_instance_id()) if level != null else "", "level_id": level.level_id if level != null else "", "inside_tree": node.is_inside_tree(), "value": _encode(value)})


func _recipient_callbacks() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var level_id: String = str(game.active_level.get_instance_id())
	var player_id: String = str(game.player.get_instance_id())
	for row: Dictionary in observations:
		if row.level_instance_id == level_id or row.emitter_id == player_id: result.append(row)
	# All validation-candidate/old-donor retirement callbacks remain separately
	# recorded in observations. Only this actual installed recipient gets credit.
	return result


func _observed_progress(kind: String) -> bool:
	for row: Dictionary in observations:
		if row.level_id == Layout.LEVEL_ID and row.kind == kind: return true
	return false


func _count_players(node: Node) -> int:
	var count: int = 1 if node is CinderPlayer else 0
	for child: Node in node.get_children(): count += _count_players(child)
	return count


func _refs(node: Node) -> Array[WeakRef]:
	var result: Array[WeakRef] = [weakref(node)]
	for child: Node in node.get_children(): result.append_array(_refs(child))
	return result


func _freed(refs: Array[WeakRef]) -> bool:
	if refs.is_empty(): return false
	for ref: WeakRef in refs:
		if ref.get_ref() != null: return false
	return true


func _encode(value: Variant) -> Variant:
	if value is Vector3: return Codec.vector3(value)
	if value is Vector2: return [value.x, value.y]
	if value is Color: return [value.r, value.g, value.b, value.a]
	if value is Basis: return {"x": _encode(value.x), "y": _encode(value.y), "z": _encode(value.z)}
	if value is Transform3D: return {"basis": _encode(value.basis), "origin": _encode(value.origin)}
	if value is StringName: return String(value)
	if value is int and (value < -9007199254740991 or value > 9007199254740991): return {"native_integer_decimal": str(value)}
	if value is Dictionary:
		var converted: Dictionary = {}
		for key: Variant in value: converted[String(key)] = _encode(value[key])
		return converted
	if value is Array:
		var converted: Array = []
		for child: Variant in value: converted.append(_encode(child))
		return converted
	return value


func _diagnostic() -> Dictionary:
	var value: Dictionary = {"operation": operation, "paused": paused, "elapsed_ms": Time.get_ticks_msec() - started_ms}
	if not is_instance_valid(game): return value
	value["campaign_error"] = game.campaign_error
	if game.menu != null: value["menu"] = game.menu.page_name()
	if game.attempts != null: value["active_kind"] = game.attempts.active_kind()
	if is_instance_valid(game.player): value["hero_position"] = _encode(game.player.global_position); value["hero_hp"] = game.player.hp
	if is_instance_valid(game.active_level):
		value["level_id"] = game.active_level.level_id; value["snapshot_error"] = game.active_level.last_snapshot_error; value["contract_error"] = game.active_level.contract_error()
		if game.active_level.level_id == Layout.LEVEL_ID:
			value["local_state"] = game.active_level.call("encounter_state"); value["capture_error"] = game.active_level.get("last_capture_error"); value["encounter_error"] = game.active_level.get("last_encounter_error")
			value["circuit"] = _encode(_source(Layout.CIRCUIT_SOURCE_ID).state()); value["final"] = _encode(_source(Layout.FINAL_SOURCE_ID).state()); value["impact"] = _encode(_impact().state()); value["clock_s"] = _scheduler().get_clock()
	return value


func _expect(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		if first_failure.is_empty(): first_failure = {"label": label, "diagnostic": _diagnostic()}
		push_error(label)
	return ok


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > WATCHDOG_MS:
		_expect(false, "actual O1 campaign watchdog reached120 seconds")
		_finish.call_deferred()


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true; operation = "normal final cleanup"
	var refs: Array[WeakRef] = []
	if is_instance_valid(preview):
		var level: CinderLevel = preview.get("active_level") as CinderLevel
		if level != null: level.exit_level()
		refs.append_array(_refs(preview)); preview.free(); preview = null
	if is_instance_valid(game): refs.append_array(_refs(game)); game.free(); game = null
	paused = false
	await create_timer(0.5, true).timeout
	await process_frame
	_expect((refs.is_empty() or _freed(refs)) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal final Shell/Main cleanup frees native descendants and source/cue groups")
	_expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH) == registry_bytes, "isolated TEST O1 override leaves every canonical registry byte unchanged")
	var report := FileAccess.open(report_path, FileAccess.WRITE)
	if report == null: _expect(false, "unique actual native campaign report is writable")
	else:
		report.store_string(JSON.stringify({"checks": checks, "failures": failures, "first_failure": first_failure, "elapsed_ms": Time.get_ticks_msec() - started_ms, "setups": setups, "receipts": receipts, "observations": observations, "scope": "Production Shell.configure_runtime with only O1 in-memory TEST scene/readiness override and isolated stores; actual accepted-L2 Main whole-unit Story plus disclosed TEST completed[L1,L2] prefix; public menu signals (no GUI clicks) for Optional/active-side Continue/Resume/Pause/Retry/Replay/Leave; three actual Area contacts arranged by truthful same-floor TEST placements; partial native C30-impact exact Save and normal donor disposal/fresh disk installed-recipient Continue; genuine three-contact pre-final checkpoint before final activation; later natural final warning exact disk Continue/earlier Retry; actual public shared dash/20HP primary during real final recovery; actual repaired-hatch contact, existing once-only completion stamp, exact protected Story return and pristine optional replay/Leave; all candidate/donor retirement callbacks retained separately, zero callbacks credited only to exact installed restore recipients; normal cleanup. No earned route, six permutations, other loadouts, GUI/recognizer actions, performance, art, mobile or release claim."}, "\t")); report.close()
	var directory := DirAccess.open(test_root)
	if directory != null:
		for name: String in directory.get_files(): DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-O1 CAMPAIGN: %d checks, %d failures; report=%s" % [checks, failures, report_path])
	quit(1 if failures > 0 else 0)
