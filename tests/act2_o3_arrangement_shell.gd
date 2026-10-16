extends SceneTree
## PRIVATE / UNPARSED / UNEXECUTED. Canonical new20 Optional persistence only.
## TEST prefix9 unlocks A2-L4; protected Story is a complete actual Main writer.
## Actual public Shell creates Canal20. One real public forward dash reaches its
## first Scout warning. No pose/HP/clock/history/stage/record/old-packet rewrite.

const MainScene = preload("res://scenes/main.tscn")
const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Attempts = preload("res://scripts/campaign/attempts.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Player = preload("res://scripts/player.gd")
const Parent = preload("res://scripts/acts/act2/bleached_canal.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const STORY_ID: String = "A2-L5"
const STORY_PATH: String = "res://scenes/acts/act2/dead_london.tscn"
const OPTIONAL_ID: String = "A2-O3"
const OPTIONAL_PATH: String = "res://scenes/acts/act2/a2_o3.tscn"
const SOURCE_ID: String = "first_scout"
const PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3", "A1-L4", "A1-L5", "A2-L1", "A2-L2", "A2-L3", "A2-L4"]
const FRAME_LIMIT: int = 1200
const WATCHDOG_S: float = 180.0 # Unmeasured host ceiling; native waits retain20s/2400ticks.

class EndTick extends Node:
	signal settled
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 300
	func _physics_process(_delta: float) -> void:
		settled.emit.call_deferred()

var production: CinderCampaignShell
var preview: Node
var barrier: EndTick
var isolated: String
var report_path: String
var rows: Array[Dictionary] = []
var receipts: Array[Dictionary] = []
var events: Array[Dictionary] = []
var watched: Dictionary = {}
var actual_actions: Array[Dictionary] = []
var action_wires: Array[String] = []
var failures: int = 0
var first_failure: Dictionary = {}
var complete: bool = false
var finishing: bool = false
var initial_session: Dictionary = {}
var protected_story: Dictionary = {}
var baseline_stats: Dictionary = {}
var entrance: Dictionary = {}
var canonical_bytes: String
var source_before: Dictionary
var old_audio: AudioBusLayout
var old_fps: int

func _initialize() -> void:
	isolated = "user://test-canal20-optional-shell-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	report_path = OS.get_environment("CINDER_A2_O3_ARRANGEMENT_SHELL_REPORT")
	old_audio = AudioServer.generate_bus_layout()
	old_fps = Engine.max_fps
	canonical_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	source_before = _sources()
	node_added.connect(_watch_node)
	_run.call_deferred()

func _run() -> void:
	create_timer(WATCHDOG_S, true, false, true).timeout.connect(func() -> void:
		if not finishing:
			_expect(false, "Finite180s unmeasured native host ceiling; no native mechanics deadline changed")
			_finish.call_deferred())
	root.size = Vector2i(540, 1170)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var registry = Registry.new()
	if not _expect(OS.get_cmdline_user_args().is_empty() and report_path.is_absolute_path() and registry.last_error.is_empty() and registry.is_playable(STORY_ID) and registry.entry(STORY_ID).scene_path == STORY_PATH and registry.is_playable(OPTIONAL_ID) and registry.entry(OPTIONAL_ID).scene_path == OPTIONAL_PATH and registry.entry(OPTIONAL_ID).parent_level_id == "A2-L4" and not registry.is_unlocked(OPTIONAL_ID, PREFIX.slice(0, 8)) and registry.is_unlocked(OPTIONAL_ID, PREFIX), "Explicit report-only scope, actual canonical Story/Optional rows and disclosed TEST prefix9 parent unlock", registry.last_error):
		await _finish(); return
	if not await _seed_story(registry) or not await _new_shell(initial_session): await _finish(); return
	var initial_disk: Dictionary = _disk_observation()
	production.menu.continue_story_requested.emit()
	if not await _wait_installed(initial_session.story.snapshot, "story") or not _expect(_same(production.attempts.state(), initial_session) and _disk_observation() == initial_disk, "Initial real Continue installs complete protected Story without rewriting campaign disk"): await _finish(); return
	protected_story = production.attempts.state().story.duplicate(true)
	baseline_stats = production.player.stats.duplicate(true)
	if not _quiet_selected() or not await _quiet_frames(initial_session.story.snapshot, "initial Story Continue"): await _finish(); return
	var story_ids: Dictionary = {"hero": production.player.get_instance_id(), "level": production.active_level.get_instance_id()}
	production.menu.difficulty_preference_requested.emit("challenge")
	if not _preference("challenge") or not _expect(_same(production.attempts.state().story, protected_story) and _same(production.capture_campaign_snapshot(), protected_story.snapshot) and _disk_observation().campaign == initial_disk.campaign, "Public fresh Challenge preference leaves complete protected Story/campaign unchanged"): await _finish(); return
	var before_optional: Dictionary = _disk_observation()
	production.menu.optional_requested.emit(OPTIONAL_ID)
	if not await _wait_optional_entry(story_ids): await _finish(); return
	entrance = production.capture_campaign_snapshot()
	if not _bindings(entrance) or not _expect(entrance.level.local.scheduler.reservations.is_empty() and entrance.level.local.exchange.records[SOURCE_ID].status == "idle" and production.player.get_world_action_records().is_empty(), "Actual public Optional creates pristine closed20 native entrance before any actions/leases; no settled-floor claim"): await _finish(); return
	# Expected copies below are assertions only, never installed or written.
	var optional_session: Dictionary = initial_session.duplicate(true)
	optional_session.side_attempt = {"kind": "optional", "level_id": OPTIONAL_ID, "snapshot": entrance.duplicate(true), "checkpoint": entrance.duplicate(true)}
	if not _expect(_same(production.attempts.state(), optional_session) and _same(production.attempts.state().story, protected_story) and _no_growth(entrance) and int(_disk_observation().generation) == int(before_optional.generation) + 2, "Public side operation records unchanged Story then commits one genuine Optional entrance; no progression/equipment growth") or not _disk(optional_session): await _finish(); return
	var entrance_ids: Dictionary = _native_ids()
	if not _expect(_identity_set_valid(entrance_ids), "Complete named actual Optional identity set is signed/nonzero/live/unique") or not _quiet_selected() or not await _quiet_frames(entrance, "ordinary Optional entrance"): await _finish(); return
	_record("public ordinary Optional new20 entrance", entrance)
	barrier = EndTick.new()
	production.add_child(barrier)
	production.player.world_action_executed.connect(_on_action)
	production.menu.resume_requested.emit()
	if not await _wait_tick(func() -> bool: return production.player.is_on_floor() and production.player.get_threat_response_state().stable, "actual original-spawn floor settles before one public forward dash"): await _finish(); return
	var start: Vector3 = production.player.global_position
	var stats: Dictionary = production.player.stats.duplicate(true)
	if not _expect(production.player.request_dash(Vector3.FORWARD), "One actual ordinary public forward dash enters unchanged first Scout range"): await _finish(); return
	if not await _wait_tick(func() -> bool: return actual_actions.size() == 1 and not production.player.action_in_progress() and production.player.is_on_floor() and production.player.get_threat_response_state().stable, "actual neutral forward dash completes before holding warning"): await _finish(); return
	var action: Dictionary = actual_actions[0]
	if not _expect(action.kind == "dash" and not action.blocked and action.world_origin == start and action.landing == production.player.global_position and (action.landing as Vector3).distance_to(start + Vector3.FORWARD * float(stats.dash_distance)) <= 0.005 and action.equipment_ids == production.player.equipment.snapshot() and Codec.same_values(action.resolved_stats, stats), "Real completed dash retains actual geometry/equipment/stats, without transform or record assignment"): await _finish(); return
	if not await _wait_tick(func() -> bool: return production.player.is_on_floor() and production.player.get_threat_response_state().stable and _warning(), "real first Scout owner-bound unarmed tracking warning"): await _finish(); return
	var before_pause: Dictionary = _disk_observation()
	production.request_pause()
	if not await _wait_pause(): await _finish(); return
	var warning: Dictionary = production.capture_campaign_snapshot()
	var warning_session: Dictionary = optional_session.duplicate(true)
	warning_session.side_attempt.snapshot = warning.duplicate(true)
	if not _bindings(warning) or not _expect(_warning() and actual_actions.size() == 1 and warning.level.local.scheduler.reservations.size() == 1 and warning.level.local.scheduler.reservations[0].adapter.locked == false and warning.player.world_actions.history.size() == 1 and warning.player.world_actions.history[0].kind == "dash" and warning.player.resources.hp == entrance.player.resources.hp and warning.player.resources.shells == entrance.player.resources.shells and not _same(warning, entrance) and _same(production.attempts.state(), warning_session) and _same(production.attempts.state().side_attempt.checkpoint, entrance) and _no_growth(warning), "Public Pause saves genuine first-warning whole20 unit, changes only side snapshot and preserves Story/entrance/checkpoint/equipment") or not _one_generation(before_pause, "Pause Save") or not _disk(warning_session): await _finish(); return
	_record("actual public first-warning Pause Save", warning)
	if not _atomic_recipe_negatives(warning): await _finish(); return
	var held_disk: Dictionary = _disk_observation()
	var held_ids: Dictionary = _native_ids()
	production.menu.difficulty_preference_requested.emit("assisted")
	if not _preference("assisted") or not _expect(_same(production.capture_campaign_snapshot(), warning) and _same(production.attempts.state(), warning_session) and _native_ids() == held_ids and _disk_observation().campaign == held_disk.campaign, "Opposite public preference persists separately; whole saved Challenge recipe/profile/session/campaign/native identities stay exact"): await _finish(); return
	var fresh_disk: Dictionary = _disk_observation()
	if not await _dispose_shell() or not await _new_shell(warning_session): await _finish(); return
	if not _expect(production.get_difficulty_preference() == "assisted" and _disk_observation() == fresh_disk, "Fresh Title independently reads newer Assisted preference and exact whole optional campaign disk without rewrite"): await _finish(); return
	production.menu.resume_requested.emit() # Public Resume Side retains the saved Optional attempt.
	if not await _wait_installed(warning, "optional") or not _bindings(warning) or not _distinct(held_ids, true) or not _quiet_selected() or not await _quiet_frames(warning, "fresh disk Optional Continue"): await _finish(); return
	if not _expect(_same(production.attempts.state(), warning_session) and _same(production.attempts.state().story, protected_story) and production.get_difficulty_preference() == "assisted" and _disk_observation() == fresh_disk and _no_growth(warning), "Independent real disk Continue retains saved Challenge recipe and every whole warning/Story/checkpoint/session field despite current Assisted") or not _disk(warning_session): await _finish(); return
	_record("fresh Title public disk Continue exact warning", warning)
	var before_retry: Dictionary = _disk_observation()
	var retired: Array[WeakRef] = []
	_collect(production.world.get_parent().get_parent(), retired)
	var prior: Dictionary = _native_ids()
	events.clear()
	production.menu.retry_requested.emit()
	if not await _wait_installed(entrance, "optional", prior) or not _bindings(entrance) or not _distinct(prior, false) or not _quiet_selected() or not await _quiet_frames(entrance, "same Shell entrance Retry"): await _finish(); return
	var retry_session: Dictionary = warning_session.duplicate(true)
	retry_session.side_attempt.snapshot = entrance.duplicate(true)
	if not _expect(_same(production.attempts.state(), retry_session) and _same(production.attempts.state().story, protected_story) and _same(production.attempts.state().side_attempt.checkpoint, entrance) and production.get_difficulty_preference() == "assisted" and production.active_level.current_checkpoint().id.is_empty() and _no_growth(entrance), "Same-Shell public Retry restores exact genuine entrance with saved Challenge recipe; protected Story and no-growth state stay exact") or not _one_generation(before_retry, "entrance Retry") or not _disk(retry_session) or not await _released(retired, "Retry retires complete prior warning native world"): await _finish(); return
	_record("same Shell public exact entrance Retry", entrance)
	var before_leave: Dictionary = _disk_observation()
	prior = _native_ids()
	retired.clear()
	_collect(production.world.get_parent().get_parent(), retired)
	events.clear()
	production.menu.leave_side_requested.emit()
	if not await _wait_installed(protected_story.snapshot, "story", prior, "journey"): await _finish(); return
	var left_session: Dictionary = retry_session.duplicate(true)
	left_session.side_attempt = null
	if not _expect(_same(production.attempts.state(), left_session) and _same(production.attempts.state().story, protected_story) and production.attempts.state().completed_optional.is_empty() and production.attempts.state().reward_ids.is_empty() and _same(production.player.equipment.snapshot(), protected_story.snapshot.equipment_ids), "Early Leave restores complete protected Story at Journey with no stamp/main progress/equipment growth") or not _quiet_selected() or not _one_generation(before_leave, "early Leave") or not _disk(left_session) or not await _released(retired, "early Leave retires entire optional world"): await _finish(); return
	if not await _dispose_shell(): await _finish(); return
	complete = true
	await _finish()

func _seed_story(registry: CinderCampaignRegistry) -> bool:
	paused = true
	preview = MainScene.instantiate()
	preview.set("level_scene_path", STORY_PATH)
	root.add_child(preview)
	preview.call("open_bench")
	await process_frame; await process_frame
	var hero: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	if not _expect(paused and hero != null and level != null and level.level_id == STORY_ID and level.scene_file_path == STORY_PATH and String(preview.get("level_load_error")).is_empty() and level.contract_error().is_empty(), "Actual unchanged Main provides complete native paused Story seed", String(preview.get("level_load_error"))): return false
	var actor: Dictionary = hero.snapshot_state()
	var local: Dictionary = level.snapshot_state()
	var input: Dictionary = preview.call("get_input_observation_state")
	if not _expect(not actor.is_empty() and not local.is_empty() and hero.get_world_action_records().is_empty() and input.sequence == 0 and input.last_observation.is_empty() and hero.snapshot_error(actor).is_empty() and level.snapshot_error_with_player(local, actor).is_empty(), "Whole real Story/Player writers and actual initial input validate before TEST outer context", hero.last_snapshot_error + "; " + level.last_snapshot_error): return false
	if not _expect(local.get("local") is Dictionary and local.local.get("profile_id") is String and local.local.profile_id == "standard" and local.local.get("scheduler") is Dictionary and local.local.scheduler.get("profile") is Dictionary and Exact.stringify(local.local.scheduler.profile) == Exact.stringify(Difficulty.new().profile(local.local.profile_id)), "Actual canonical Main fallback Story writer retains saved standard profile and complete canonical Scheduler profile"): return false
	var donor_profile: String = local.local.profile_id
	var anchor: Vector2 = input.anchor_normalized
	var focus: Vector3 = preview.get("_camera_focus")
	var shake: float = float(preview.get("_shake"))
	var snapshot: Dictionary = {"schema_version": 1, "level_id": STORY_ID, "scene_path": STORY_PATH, "paused": true, "equipment_ids": hero.equipment.snapshot(), "player": actor, "level": local, "shell": {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": input.sequence, "last_input_observation": input.last_observation.duplicate(true), "camera_focus": Codec.vector3(focus), "shake_left_s": shake, "difficulty_at_entry": donor_profile}}
	var model = Attempts.new(registry)
	initial_session = model.state()
	initial_session.completed_main = registry.main_route().slice(0, 9) # TEST prerequisite only, not played progress.
	initial_session.story = {"kind": "story", "level_id": STORY_ID, "snapshot": snapshot.duplicate(true), "checkpoint": snapshot.duplicate(true)}
	var writer = Store.new(isolated + "campaign.json")
	writer.payload_validator = model.saved_payload_error
	if not _expect(initial_session.completed_main == PREFIX and model.state_error(initial_session).is_empty() and writer.write_payload(initial_session), "Actual Attempts/format2 Store accept disclosed TEST prefix9 and unmodified whole Story writers; no fake Canal packet", model.last_error + "; " + writer.last_error): return false
	var refs: Array[WeakRef] = []
	_collect(preview, refs)
	level.exit_level()
	preview.get("fx").clear()
	preview.queue_free(); preview = null
	return await _released(refs, "normal complete native Story seed donor disposal") and _disk(initial_session)

func _new_shell(expected: Dictionary) -> bool:
	events.clear(); watched.clear()
	production = Shell.new()
	if not _expect(production.configure_runtime({}, isolated + "campaign.json", isolated + "settings.json", isolated + "preferences.json"), "Actual canonical production Shell uses isolated stores and no injected Registry", production.campaign_error): return false
	root.add_child(production)
	for _frame: int in range(FRAME_LIMIT):
		await process_frame
		if finishing or not _healthy(): return false
		if paused and _idle() and production.menu.page_name() == "title" and production.active_level == null and production.player == null and _same(production.attempts.state(), expected): return _disk(expected)
	return _expect(false, "Finite actual Title startup validates entire expected session", production.campaign_error)

func _wait_installed(expected: Dictionary, kind: String, previous: Dictionary = {}, page: String = "resume") -> bool:
	for _frame: int in range(FRAME_LIMIT):
		await process_frame
		if finishing or not _healthy(): return false
		if not paused or not _idle() or production.menu.page_name() != page or not is_instance_valid(production.active_level) or not is_instance_valid(production.player) or production.attempts.active_kind() != kind: continue
		if not previous.is_empty() and (not previous.has("hero") or not previous.has("level") or production.player.get_instance_id() == previous.hero or production.active_level.get_instance_id() == previous.level): continue
		if _same(production.capture_campaign_snapshot(), expected): return _expect(true, "Public idle install equals complete expected packet with requested new actual recipients")
	return _expect(false, "Finite full aggregate operation/new-recipient installation", production.campaign_error)

func _wait_optional_entry(previous: Dictionary) -> bool:
	for _frame: int in range(FRAME_LIMIT):
		await process_frame
		if finishing or not _healthy(): return false
		if not paused or not _idle() or production.menu.page_name() != "resume" or not is_instance_valid(production.active_level) or not is_instance_valid(production.player): continue
		if production.active_level.level_id == OPTIONAL_ID and production.attempts.active_kind() == "optional" and production.player.get_instance_id() != previous.hero and production.active_level.get_instance_id() != previous.level:
			return _expect(_closed20(production.capture_campaign_snapshot()), "Public idle Optional constructs actual fresh canonical new20 unit")
	return _expect(false, "Finite ordinary Optional new20 entry", production.campaign_error)

func _wait_pause() -> bool:
	for _frame: int in range(FRAME_LIMIT):
		await process_frame
		if finishing or not _healthy(): return false
		if paused and _idle() and production.menu.page_name() == "pause":
			var packet: Dictionary = production.capture_campaign_snapshot()
			if not packet.is_empty() and _same(production.attempts.active_snapshot(), packet): return true
	return _expect(false, "Finite public Pause Save commits complete native active snapshot", production.campaign_error)

func _wait_tick(predicate: Callable, label: String) -> bool:
	var deadline: int = Time.get_ticks_msec() + 20000
	for _tick: int in range(2400):
		await barrier.settled
		if finishing: return false
		if not _healthy() or production.player.dead: return _expect(false, "Healthy actual native tick: " + label)
		if predicate.call() == true: return _expect(true, label)
		if paused or Time.get_ticks_msec() > deadline: break
	return _expect(false, "Original bounded20-second/2400tick native wait: " + label)

func _closed20(packet: Dictionary) -> bool:
	if packet.is_empty() or packet.get("level_id") != OPTIONAL_ID or packet.get("scene_path") != OPTIONAL_PATH or not packet.get("level") is Dictionary or not packet.level.get("local") is Dictionary: return false
	var local: Dictionary = packet.level.local
	var keys: Array = Parent.LOCAL_KEYS.duplicate()
	keys.append_array(["api_revision", "schema_version", "arrangement"])
	return Codec.keys_error(local, keys).is_empty() and local.size() == 20 and packet.level.local_snapshot_version is int and packet.level.local_snapshot_version == 1 and local.world_revision == Parent.WORLD_REVISION and local.api_revision == Parent.ARRANGEMENT_API and local.schema_version is int and local.schema_version == 2 and local.arrangement.recipe_id == Parent.CHALLENGE_RECIPE and local.arrangement.profile == "challenge" and local.profile_id == "challenge" and Exact.stringify(local.scheduler.profile) == Exact.stringify(Difficulty.new().profile("challenge")) and local.stage_index is int and local.stage_index == 0 and local.defeated_ids.is_empty() and local.defeat_times.is_empty() and local.pending_defeats.is_empty() and not local.checkpoint_contact_seen and not local.checkpoint_requested and not local.pending_checkpoint and not local.completion_pending and not local.exit_requested and packet.level.progress.checkpoint_id.is_empty() and packet.level.progress.checkpoint_ids.is_empty() and not packet.level.progress.completed and packet.level.progress.contact_exit_id.is_empty()

func _bindings(packet: Dictionary) -> bool:
	var level: CinderLevel = production.active_level
	if not _expect(_closed20(packet) and level.level_id == OPTIONAL_ID and level.scene_file_path == OPTIONAL_PATH and level.get_script() == Parent and not level.is_restore_candidate() and level.hero == production.player and level.effects == production.fx and level.shared_shell == production and level.contract_error().is_empty() and String(level.get("runtime_error")).is_empty() and level.get("_legacy_capture") == false, "Actual installed canonical Level/Hero/FX/Shell retain closed20 no-history Challenge construction", level.last_snapshot_error): return false
	var selected: Dictionary = Parent.arrangement_layout(packet.level.local.arrangement, JSON.parse_string(FileAccess.get_file_as_string(Parent.ARRANGEMENT_PATH)))
	if not _expect(selected.error.is_empty() and selected.positions == level.get("_selected_positions"), "Saved immutable recipe exactly joins real constructed native positions"): return false
	var actors: Dictionary = level.get("_actors")
	var tools: Dictionary = level.get("_tools")
	var cues: Dictionary = level.get("_opening_cues")
	if not _expect(Codec.keys_error(actors, Parent.ACTOR_IDS).is_empty() and Codec.keys_error(tools, Parent.HANDLER_IDS).is_empty() and Codec.keys_error(cues, Parent.HANDLER_IDS).is_empty(), "All four actors/two tools/two low cues remain actual named recipients"): return false
	for id: String in Parent.ACTOR_IDS:
		if not _expect(is_instance_valid(actors[id]) and actors[id].global_position == selected.positions[id] and packet.level.local.actors[id].root_position == Codec.vector3(actors[id].global_position) and float(packet.level.local.actors[id].hp) == 30.0, "Native selected actual actor root and unchanged alive HP: " + id): return false
	for id: String in Parent.HANDLER_IDS:
		if not _expect(tools[id].global_position == actors[id].global_position and cues[id].position == selected.positions[id] and Codec.read_vector3(packet.level.local.tools[id].configuration.geometry.from) == actors[id].global_position and packet.level.local.tools[id].configuration.opening_position == packet.level.local.actors[id].root_position, "Actual Handler tool-relative geometry and cue follow selected root: " + id): return false
	return _expect(_same((level.get("_scheduler") as CinderThreatScheduler).encounter_profile(), packet.level.local.scheduler.profile), "Actual one Scheduler retains complete canonical saved Challenge profile")

func _warning() -> bool:
	if not is_instance_valid(production.active_level) or production.active_level.level_id != OPTIONAL_ID: return false
	var level: CinderLevel = production.active_level
	var source: Node3D = (level.get("_actors") as Dictionary).get(SOURCE_ID) as Node3D
	var state: Dictionary = level.get("_exchange").call("state", SOURCE_ID)
	if not is_instance_valid(source) or state.get("status") != "running" or state.get("phase") != "warning" or state.get("armed") != false or state.get("cycle") != 1: return false
	for lease: Dictionary in (level.get("_scheduler") as CinderThreatScheduler).source_control_state(source).get("reservations", []):
		if lease.id == state.reservation_id and lease.source_instance_id == source.get_instance_id() and lease.profile_id == "challenge" and lease.armed == false: return true
	return false

func _no_growth(packet: Dictionary) -> bool:
	var state: Dictionary = production.attempts.state()
	return _same(state.story, protected_story) and _same(state.completed_main, PREFIX) and state.completed_optional.is_empty() and state.reward_ids.is_empty() and _same(state.unlocked_equipment, initial_session.unlocked_equipment) and _same(state.last_replay_equipment, initial_session.last_replay_equipment) and _same(packet.equipment_ids, protected_story.snapshot.equipment_ids) and _same(production.player.stats, baseline_stats) and packet.player.resources.max_hp == protected_story.snapshot.player.resources.max_hp and packet.player.resources.max_shells == protected_story.snapshot.player.resources.max_shells

func _atomic_recipe_negatives(saved: Dictionary) -> bool:
	var before: String = Exact.stringify(production.capture_campaign_snapshot())
	var session: String = Exact.stringify(production.attempts.state())
	var disk: Dictionary = _disk_observation()
	var ids: Dictionary = _native_ids()
	var event_count: int = events.size()
	for kind: String in ["partial", "downgrade", "retained-other-recipe", "profile", "duplicate-source"]:
		var forged: Dictionary = saved.duplicate(true) # TEST refusal input only.
		var local: Dictionary = forged.level.local
		match kind:
			"partial": local.erase("arrangement")
			"downgrade":
				for key: String in ["api_revision", "schema_version", "arrangement"]: local.erase(key)
			"retained-other-recipe": local.arrangement = {"schema_version": 1, "profile": "challenge", "recipe_id": Parent.CANONICAL_RECIPES.challenge, "order": Parent.ACTOR_IDS.duplicate()}
			"profile": local.arrangement.profile = "assisted"
			"duplicate-source": local.arrangement.order[0] = local.arrangement.order[1]
		var error: String = production.active_level.snapshot_error_with_player(forged.level, forged.player)
		if not _expect(not error.is_empty() and not production.active_level.restore_state(forged.level) and not before.is_empty() and Exact.stringify(production.capture_campaign_snapshot()) == before and Exact.stringify(production.attempts.state()) == session and _disk_observation() == disk and _native_ids() == ids and events.size() == event_count, "Recipe refusal preserves complete native packet/session/Story/IDs/selected callbacks/raw stores/generation: " + kind, error): return false
	return true

func _idle() -> bool:
	if not is_instance_valid(production) or production.is_pause_requested(): return false
	var operations: Variant = production.get("_operations")
	var failed: Variant = production.get("_failed_operations")
	return operations is Array and failed is Array and operations.is_empty() and failed.is_empty() and production.get("_draining") == false and production.get("_drain_queued") == false and production.get("_registration_inflight") == false

func _healthy() -> bool:
	if not is_instance_valid(production): return _expect(false, "Actual production Shell remains valid")
	if not production.campaign_error.is_empty(): return _expect(false, "Actual production Shell has no refused operation", production.campaign_error)
	if is_instance_valid(production.active_level) and (not production.active_level.contract_error().is_empty() or not String(production.active_level.get("runtime_error")).is_empty()): return _expect(false, "Actual native Level remains healthy", production.active_level.contract_error() + "; " + String(production.active_level.get("runtime_error")))
	return true

func _preference(profile: String) -> bool:
	var reader = Store.new(isolated + "preferences.json")
	return _expect(production.get_difficulty_preference() == profile and _same(reader.read_payload(), {"schema_version": 1, "profile_id": profile}) and reader.last_error.is_empty() and not reader.loaded_backup, "Independent actual preference Store retains public selection: " + profile, reader.last_error)

func _disk(expected: Dictionary) -> bool:
	var reader = Store.new(isolated + "campaign.json")
	var value: Dictionary = reader.read_payload()
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(isolated + "campaign.json"))
	return _expect(reader.last_error.is_empty() and not reader.loaded_backup and envelope is Dictionary and envelope.get("format_version") == 2 and envelope.get("payload_json") is String and envelope.payload_json == Exact.stringify(expected) and envelope.sha256 == envelope.payload_json.sha256_text() and _same(value, expected), "Independent real format2 Store joins complete session/Exact payload/checksum", reader.last_error)

func _disk_observation() -> Dictionary:
	var reader = Store.new(isolated + "campaign.json")
	reader.read_payload()
	var campaign: Dictionary = {"generation": reader.generation, "error": reader.last_error, "loaded_backup": reader.loaded_backup}
	var other: Dictionary = {}
	for name: String in ["campaign.json", "campaign.json.bak", "preferences.json", "preferences.json.bak"]:
		var path: String = isolated + name
		var value: Variant = {"sha256": FileAccess.get_sha256(path), "bytes": FileAccess.get_file_as_bytes(path).size(), "raw": FileAccess.get_file_as_string(path)} if FileAccess.file_exists(path) else null
		if name.begins_with("campaign"): campaign[name] = value
		else: other[name] = value
	return {"generation": reader.generation, "campaign": campaign, "preferences": other}

func _one_generation(before: Dictionary, label: String) -> bool:
	var after: Dictionary = _disk_observation()
	return _expect(int(after.generation) == int(before.generation) + 1 and after.campaign["campaign.json.bak"] == before.campaign["campaign.json"], "One actual campaign generation and byte-exact prior-primary backup: " + label)

func _required_ids() -> Array[String]:
	var names: Array[String] = ["shell", "hud", "world", "world3d", "viewport", "container", "hero", "level", "camera", "fx", "scheduler", "exchange", "floor-body", "floor-collision", "exit-cue"]
	for id: String in Parent.ACTOR_IDS: names.append("actor/" + id)
	for id: String in Parent.HANDLER_IDS: names.append("tool/" + id); names.append("cue/" + id)
	return names

func _put_id(result: Dictionary, key: String, value: Variant) -> void:
	if is_instance_valid(value): result[key] = value.get_instance_id()

func _native_ids() -> Dictionary:
	var result: Dictionary = {}
	if not is_instance_valid(production) or not is_instance_valid(production.active_level) or not is_instance_valid(production.player): return result
	var level: CinderLevel = production.active_level
	for pair: Array in [["shell", production], ["hud", production.hud], ["world", production.world], ["world3d", production.world.get_world_3d()], ["viewport", production.world.get_parent()], ["container", production.world.get_parent().get_parent()], ["hero", production.player], ["level", level], ["camera", production.camera], ["fx", production.fx], ["scheduler", level.get("_scheduler")], ["exchange", level.get("_exchange")], ["exit-cue", level.get("_exit_cue")]]:
		_put_id(result, pair[0], pair[1])
	for id: String in Parent.ACTOR_IDS: _put_id(result, "actor/" + id, (level.get("_actors") as Dictionary).get(id))
	for id: String in Parent.HANDLER_IDS:
		_put_id(result, "tool/" + id, (level.get("_tools") as Dictionary).get(id))
		_put_id(result, "cue/" + id, (level.get("_opening_cues") as Dictionary).get(id))
	var floor: Dictionary = level.get("_floor")
	_put_id(result, "floor-body", floor.get("body")); _put_id(result, "floor-collision", floor.get("collision"))
	return result

func _identity_set_valid(ids: Dictionary, require_live: bool = true) -> bool:
	if not Codec.keys_error(ids, _required_ids()).is_empty() or ids.size() != 23: return false
	var unique: Dictionary = {}
	for value: Variant in ids.values():
		if not value is int or value == 0 or unique.has(value) or (require_live and not is_instance_id_valid(value)): return false
		unique[value] = true
	return true

func _distinct(previous: Dictionary, fresh_shell: bool) -> bool:
	var current: Dictionary = _native_ids()
	if not _expect(_identity_set_valid(previous, false) and _identity_set_valid(current), "Both complete23-key maps retain actual signed identities; current recipients are live"): return false
	for key: String in _required_ids():
		var same_identity: bool = current[key] == previous[key]
		if not _expect(same_identity == (not fresh_shell and key in ["shell", "hud"]), "Expected actual same-Shell/HUD or independent replacement: " + key): return false
	return true

func _record(stage: String, packet: Dictionary) -> void:
	var ids: Dictionary = _native_ids()
	var strings: Dictionary = {}
	for key: String in ids: strings[key] = str(ids[key])
	if not _expect(_identity_set_valid(ids), "Receipt includes all23 native IDs as decimal strings"): return
	receipts.append({"stage": stage, "whole_packet_exact": Exact.stringify(packet), "whole_session_exact": Exact.stringify(production.attempts.state()), "protected_story_exact": Exact.stringify(production.attempts.state().story), "entrance_checkpoint_exact": Exact.stringify(production.attempts.state().side_attempt.checkpoint), "raw_stores": _disk_observation(), "native_ids_decimal": strings, "current_preference": production.get_difficulty_preference(), "scope": "Actual canonical new20 first-warning Optional persistence; TEST prefix9/initial genuine Story outer context only. No earned route or final-pair opportunity claim."})

func _quiet_frames(packet: Dictionary, label: String) -> bool:
	var session: String = Exact.stringify(production.attempts.state())
	var wire: String = Exact.stringify(packet)
	var disk: Dictionary = _disk_observation()
	var counts: int = events.size()
	var ids: Dictionary = _quiet_ids()
	for _frame: int in range(2): await process_frame
	return _expect(paused and _idle() and not wire.is_empty() and Exact.stringify(production.capture_campaign_snapshot()) == wire and Exact.stringify(production.attempts.state()) == session and _disk_observation() == disk and _quiet_ids() == ids and events.size() == counts, "Two subsequent paused frames keep whole packet/session/raw stores/selected callbacks exact: " + label)

func _quiet_ids() -> Dictionary:
	if production.active_level.level_id == OPTIONAL_ID: return _native_ids()
	return {"shell": production.get_instance_id(), "hud": production.hud.get_instance_id(), "hero": production.player.get_instance_id(), "level": production.active_level.get_instance_id(), "world": production.world.get_instance_id(), "camera": production.camera.get_instance_id(), "fx": production.fx.get_instance_id()}

func _watch_node(node: Node) -> void:
	if not is_instance_valid(production) or not production.is_ancestor_of(node) or watched.has(node.get_instance_id()): return
	watched[node.get_instance_id()] = true
	# Same gameplay subset as the executed A2L2 Shell fixture. Initial cue-state
	# construction notifications are not claimed to be absent.
	for row: Dictionary in node.get_signal_list():
		if row.name in ["fired", "died", "world_action_executed", "hit_resolved", "defeated", "checkpoint_requested", "completion_requested", "contact_exit_requested"] and row.args.size() <= 3:
			node.connect(row.name, Callable(self, "_event" + str(row.args.size())).bind(str(node.get_instance_id()), String(row.name)))

func _event0(owner: String, kind: String) -> void: events.append({"owner_decimal": owner, "kind": kind})
func _event1(_a: Variant, owner: String, kind: String) -> void: _event0(owner, kind)
func _event2(_a: Variant, _b: Variant, owner: String, kind: String) -> void: _event0(owner, kind)
func _event3(_a: Variant, _b: Variant, _c: Variant, owner: String, kind: String) -> void: _event0(owner, kind)

func _on_action(record: Dictionary) -> void:
	actual_actions.append(record.duplicate(true))
	var encoded: Dictionary = Player.encode_world_action_record(record, float(record.completed_at_s))
	_expect(not encoded.is_empty(), "Actual completed public action observation encodes without replacing native history")
	action_wires.append(Exact.stringify(encoded))

func _quiet_selected() -> bool:
	var refs: Array[WeakRef] = []
	_collect(production.active_level, refs); _collect(production.player, refs)
	var selected: Dictionary = {}
	for ref: WeakRef in refs: selected[str((ref.get_ref() as Node).get_instance_id())] = true
	for event: Dictionary in events:
		if selected.has(event.owner_decimal): return _expect(false, "Installed recipient emitted a selected gameplay/restore callback", event.kind)
	return true

func _collect(node: Node, result: Array[WeakRef]) -> void:
	result.append(weakref(node))
	for child: Node in node.get_children(): _collect(child, result)

func _released(refs: Array[WeakRef], label: String) -> bool:
	for _frame: int in range(FRAME_LIMIT):
		if not refs.is_empty() and refs.all(func(ref: WeakRef) -> bool: return ref.get_ref() == null): return _expect(true, label)
		await process_frame
	return _expect(false, "Finite normal weak descendant cleanup: " + label)

func _dispose_shell() -> bool:
	if not is_instance_valid(production): return true
	paused = true
	var refs: Array[WeakRef] = []
	_collect(production, refs)
	if is_instance_valid(production.active_level): production.active_level.exit_level()
	production.queue_free(); production = null; barrier = null
	return await _released(refs, "normal Level exit then entire owned Shell/UI/world/native disposal") and _expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "Owned enemies/required-cues groups empty after normal cleanup")

func _same(left: Variant, right: Variant) -> bool:
	var wire: String = Exact.stringify(left)
	return not wire.is_empty() and wire == Exact.stringify(right)

func _sources() -> Dictionary:
	var result: Dictionary = {}
	for path: String in [get_script().resource_path, STORY_PATH, OPTIONAL_PATH, "res://scenes/main.tscn", "res://scenes/player.tscn", "res://scripts/game.gd", "res://scripts/player.gd", "res://scripts/campaign/shell.gd", "res://scripts/campaign/level.gd", "res://scripts/campaign/registry.gd", "res://scripts/campaign/attempts.gd", "res://scripts/campaign/save_store.gd", "res://scripts/campaign/exact_json.gd", "res://scripts/campaign/snapshot_codec.gd", "res://scripts/settings/game_settings.gd", "res://scripts/ui/campaign_menu.gd", "res://scripts/acts/act2/dead_london.gd", "res://scripts/acts/act2/dead_london_sentry_presented_encounter.gd", "res://scripts/acts/act2/bleached_canal.gd", "res://scripts/acts/act2/weybridge_scout_actor.gd", "res://scripts/acts/act2/ray_scout_exchange.gd", "res://scripts/acts/act2/salvage_handler_actor.gd", "res://scripts/combat/difficulty.gd", "res://scripts/combat/encounter_arrangement.gd", "res://scripts/combat/lane_mechanism.gd", "res://scripts/combat/threat_scheduler.gd", "res://data/campaign/act2/a2_o3_difficulty_arrangements.json", "res://data/design/difficulty_profiles.json", "res://data/design/player_equipment.json", "res://data/campaign/registry.json"]:
		result[path] = FileAccess.get_sha256(path)
	return result

func _expect(ok: bool, label: String, detail: String = "") -> bool:
	var row: Dictionary = {"check": rows.size() + 1, "ok": ok, "label": label, "detail": detail}
	rows.append(row)
	if not ok:
		failures += 1
		if first_failure.is_empty(): first_failure = row.duplicate(true)
		print("FAIL Canal20 Optional Shell: " + label + "; " + detail)
	return ok

func _finish() -> void:
	if finishing: return
	finishing = true
	await _dispose_shell()
	if is_instance_valid(preview):
		var refs: Array[WeakRef] = []
		_collect(preview, refs)
		var level: CinderLevel = preview.get("active_level") as CinderLevel
		if is_instance_valid(level): level.exit_level()
		preview.queue_free(); preview = null
		await _released(refs, "remaining genuine seed donor cleanup")
	if node_added.is_connected(_watch_node): node_added.disconnect(_watch_node)
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == canonical_bytes and _sources() == source_before, "Canonical Registry and explicit named sources stay unchanged")
	for name: String in ["campaign.json", "campaign.json.bak", "campaign.json.tmp", "preferences.json", "preferences.json.bak", "preferences.json.tmp", "settings.json", "settings.json.bak"]:
		var path: String = isolated + name
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var directory = DirAccess.open(isolated)
	_expect(directory == null or directory.get_files().is_empty(), "Unique isolated runtime store directory has no retained primary/backup/tmp files")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(isolated))
	AudioServer.set_bus_layout(old_audio); Engine.max_fps = old_fps
	paused = false
	var report: Dictionary = {"schema_version": 1, "kind": "a2-o3-arrangement-shell", "checks": rows.size(), "failures": failures, "rows": rows, "first_failure": first_failure, "complete": complete, "success": complete and failures == 0, "receipts": receipts, "selected_gameplay_events": events, "actual_action_exact_wires": action_wires, "source_before": source_before, "source_after": _sources(), "test_context": "Actual native whole Main Story donor plus TEST completed-main prefix9/observed outer metadata only. Actual canonical Shell creates new20 Optional, real public neutral forward dash/first unarmed warning/Pause Save/opposite preference/fresh Title disk Continue/same-Shell entrance Retry/early Leave. Expected session clones and recipe negatives are assertion/refusal inputs only, never installed or written.", "limits": "Unparsed/unexecuted draft until Root runs selected checks. No fabricated old packet/progress/HP/clock/pose/action, no final-pair admission/opportunities, earned checkpoint/route/clear/stamp, all-kit, routed GUI gestures, portrait, balance or FPS credit. Selected gameplay callbacks are watched from node addition; initial cue-state construction silence is not claimed. Host180s ceiling is unmeasured."}
	if not report_path.is_absolute_path(): print("Canal20 Optional Shell requires an explicit absolute report path"); quit(2); return
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
	var file = FileAccess.open(report_path, FileAccess.WRITE)
	if file == null: print("Canal20 Optional Shell report destination failed"); quit(2); return
	file.store_string(JSON.stringify(report, "\t") + "\n"); file.close()
	print("CINDER_A2_O3_ARRANGEMENT_SHELL_REPORT path=" + report_path + " sha256=" + FileAccess.get_sha256(report_path))
	print("Canal20 Optional Shell: %d checks/%d failures; complete=%s" % [rows.size(), failures, str(complete)])
	quit(0 if complete and failures == 0 else 1)
