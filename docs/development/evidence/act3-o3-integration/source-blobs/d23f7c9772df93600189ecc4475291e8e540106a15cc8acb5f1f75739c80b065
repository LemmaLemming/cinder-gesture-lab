extends SceneTree
## Focused actual O1 Optional/first native collection checkpoint/held save transport.
## TEST ONLY accepted O1 metadata and canonical predecessor prefix11 protect an
## actual accepted A3-L2 opening packet. No preceding campaign clear is claimed.
## Direct public request_dash calls are native controller evidence, not gestures.
## No Hero placement, HP/ammo/history/collection/phase/lease/profile assignment.
## Default held mode does not test CP2/completion/contact return/replay.
## Explicit --completion-return drives those real production boundaries separately.
## Both modes make no portrait, human-input, balance or campaign-playthrough claim.

const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Attempts = preload("res://scripts/campaign/attempts.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Game = preload("res://scripts/game.gd")
const BodySweep = preload("res://scripts/combat/body_sweep.gd")
const MainScene: PackedScene = preload("res://scenes/main.tscn")
const O1 = preload("res://scripts/acts/act3/pillars_before_time.gd")
const STORY_ID: String = "A3-L2"
const STORY_PATH: String = "res://scenes/acts/act3/a3_l2_living_forest.tscn"
const OPTIONAL_PATH: String = "res://scenes/acts/act3/a3_o1_pillars_before_time.tscn"
const MARKER: String = "o1-southwest-marker"
const SOURCE: String = "o1-southwest-stalker"
const ADOPTED_BASELINE: String = "8d1d3112b03524bde99e426e41748e01698718c3"
const ARCHIVE_PINS: Array[String] = [
	"res://tests/acts/act3/pillars_before_time_optional_shell.gd",
	"res://scripts/acts/act3/pillars_before_time.gd", "res://scenes/acts/act3/a3_o1_pillars_before_time.tscn",
	"res://data/campaign/act3/a3_o1_encounters.json", "res://scripts/acts/act3/temporal_marker_prop.gd",
	"res://scripts/acts/act3/twin_suns.gd", "res://scripts/acts/act3/twin_suns_scenery.gd",
	"res://scripts/acts/act3/sunbound_stalker.gd", "res://scripts/combat/threat_scheduler.gd",
	"res://scripts/campaign/shell.gd", "res://scripts/campaign/level.gd", "res://scripts/campaign/registry.gd",
	"res://scripts/campaign/save_store.gd", "res://scripts/campaign/exact_json.gd", "res://scripts/campaign/snapshot_codec.gd",
	"res://scripts/player.gd", "res://scripts/game.gd", "res://scripts/hud.gd", "res://scripts/ui/campaign_menu.gd",
	"res://scripts/equipment.gd", "res://data/design/player_equipment.json",
]
const FRAME_LIMIT: int = 120
const LIVE_FRAME_LIMIT: int = 1800

var checks: int = 0
var failures: int = 0
var production: CinderCampaignShell
var preview: Node
var isolated: String
var raw: Dictionary
var canonical_bytes: String
var expected_session: Dictionary
var protected: Dictionary
var checkpoint: Dictionary
var held: Dictionary
var archive_path: String = ""
var completion_return: bool = false
var contact_receipts: Dictionary = {}
var receiver_events: Array[Dictionary] = []
var watched: Dictionary = {}
var first_collection: bool = false
var scope_complete: bool = false
var finished: bool = false
var old_audio: AudioBusLayout
var old_fps: int

func _initialize() -> void:
	isolated = "user://test-a3-o1-optional-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	old_audio = AudioServer.generate_bus_layout()
	old_fps = Engine.max_fps
	_run.call_deferred()

func _run() -> void:
	create_timer(180.0, true).timeout.connect(func() -> void:
		if not finished:
			_expect(false, "bounded isolated O1 Shell watchdog")
			_finish())
	root.size = Vector2i(340, 736)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if not _expect(DisplayServer.get_name() == "headless", "this lean transport fixture is explicit headless; no portrait claim"):
		await _finish(); return
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	completion_return = arguments == PackedStringArray(["--completion-return"])
	if not _expect(arguments.is_empty() or completion_return, "explicit default held transport or --completion-return selector only"):
		await _finish(); return
	node_added.connect(_watch_node)
	canonical_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var parsed: Variant = JSON.parse_string(canonical_bytes)
	if not _expect(parsed is Dictionary, "read canonical registry without changing it"):
		await _finish(); return
	raw = parsed.duplicate(true)
	for row: Dictionary in raw.levels:
		if row.id == "A3-O1":
			row.scene_path = OPTIONAL_PATH
			row.readiness = "accepted"
			row.accepted_commit = "a".repeat(40) # Explicit TEST ONLY provenance.
			row.api_revision = Registry.API_REVISION
	var registry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A3-O1").is_empty(), "isolated TEST O1 readiness retains canonical parent/reward/15+9 links", registry.last_error):
		await _finish(); return
	print("TEST ONLY prefix11/O1 readiness; native accepted A3-L2 opening protects Story. Direct controller dashes, actual first contact, native held Stalker, public disk/retry/GUI/abandon only; no collection/HP/history/lease seeds.")
	if not await _seed_story(registry): await _finish(); return
	if not await _new_shell(expected_session): await _finish(); return
	production.menu.continue_story_requested.emit()
	if not await _wait_installed(STORY_ID, "resume", protected): await _finish(); return
	if not _installed(protected) or not _quiet_selected(): await _finish(); return
	var old_story_refs: Array[WeakRef] = []
	_collect_refs(_world_container(), old_story_refs)
	var old_story_ids: Dictionary = _core_ids()
	production.menu.optional_requested.emit("A3-O1")
	if not await _wait_installed("A3-O1", "resume", {}, old_story_ids): await _finish(); return
	var entrance: Dictionary = production.capture_campaign_snapshot()
	if not _installed(entrance) or not await _released(old_story_refs, "Optional entry retires the old complete Story world"): await _finish(); return
	if not _expect(production.attempts.active_kind() == "optional" and _same(production.attempts.story_snapshot(), protected) and _same(production.attempts.state().side_attempt.checkpoint, entrance), "public Optional protects complete Story and actual pristine side entrance checkpoint"):
		await _finish(); return
	var entry_state: Dictionary = production.active_level.call("state")
	if not _expect(entry_state.collections.is_empty() and not production.active_level.is_completed() and production.player.get_world_action_records().is_empty(), "actual optional initial unit contains no invented collection/action/completion"):
		await _finish(); return
	if not _expect(not production.active_level.request_contact_exit(O1.EXIT_ID, production.player) and _same(production.capture_campaign_snapshot(), entrance), "premature exit refuses atomically before native collection"):
		await _finish(); return
	if completion_return:
		scope_complete = await _completion_return(entrance)
		await _finish()
		return
	if not await _resume_after_layout(): await _finish(); return
	if not await _collect_first_marker(): await _finish(); return
	if not await _wait_held_stalker(): await _finish(); return
	production.request_pause()
	if not await _wait_pause(): await _finish(); return
	held = production.capture_campaign_snapshot()
	var held_receipt: Dictionary = _held_receipt()
	if not _expect(not held_receipt.is_empty() and _same(production.attempts.state().side_attempt.snapshot, held) and _same(production.attempts.state().side_attempt.checkpoint, checkpoint), "public Pause saves actual held threat separately from earlier real marker checkpoint"):
		await _finish(); return
	if not _installed(held) or not _disk(production.attempts.state()) or not _archive_held(entrance, held_receipt): await _finish(); return
	if not _expect(not production.active_level.request_checkpoint(checkpoint.level.progress.checkpoint_id) and _same(production.capture_campaign_snapshot(), held), "duplicate real checkpoint request is rejected without altering held aggregate"):
		await _finish(); return
	var saved_session: Dictionary = production.attempts.state()
	var donor_ids: Dictionary = _native_ids()
	if not await _dispose_shell(): await _finish(); return
	if not await _new_shell(saved_session): await _finish(); return
	production.menu.resume_requested.emit() # Actual Title Resume Side, not Continue Story abandonment.
	if not await _wait_installed("A3-O1", "resume", held): await _finish(); return
	if not _installed(held) or not _distinct(donor_ids) or not _quiet_selected(): await _finish(); return
	if not _expect(_same(_held_receipt(), held_receipt) and _same(production.attempts.state(), saved_session), "fresh disk Side Resume retains original held phase/lease/cycle/clock and full session"):
		await _finish(); return
	var old_refs: Array[WeakRef] = []
	_collect_refs(_world_container(), old_refs)
	var before_retry: Dictionary = _native_ids()
	receiver_events.clear()
	production.menu.retry_requested.emit()
	if not await _wait_installed("A3-O1", "resume", checkpoint, before_retry): await _finish(); return
	if not _installed(checkpoint) or not _distinct(before_retry) or not _quiet_selected() or not await _released(old_refs, "Retry frees every original held World/source/floor/cue binding"):
		await _finish(); return
	if not _expect(_same(production.attempts.state().side_attempt.snapshot, checkpoint) and _same(production.attempts.state().side_attempt.checkpoint, checkpoint) and _same(production.attempts.story_snapshot(), protected), "Retry restores exact native collection checkpoint/resources/aim without refreshing Story"):
		await _finish(); return
	if not _disk(production.attempts.state()) or not await _gui_resume(checkpoint): await _finish(); return
	old_refs.clear()
	_collect_refs(_world_container(), old_refs)
	var before_leave: Dictionary = _core_ids()
	production.menu.leave_side_requested.emit()
	if not await _wait_installed(STORY_ID, "journey", protected, before_leave): await _finish(); return
	if not _installed(protected) or not await _released(old_refs, "Leave Side frees complete optional native World before protected Story return"):
		await _finish(); return
	var returned: Dictionary = production.attempts.state()
	if not _expect(returned.side_attempt == null and returned.completed_main == expected_session.completed_main and returned.completed_optional.is_empty() and returned.reward_ids.is_empty() and _same(returned.story, expected_session.story), "early Leave Side restores entire protected Story/checkpoint and Journey without reward or main progress"):
		await _finish(); return
	if not _disk(returned): await _finish(); return
	production.menu.continue_story_requested.emit()
	if not await _wait_installed(STORY_ID, "resume", protected): await _finish(); return
	if not _installed(protected): await _finish(); return
	scope_complete = true
	await _finish()

## Separate real production completion branch. It never replays the held-save
## setup and does not credit the default branch with CP2/completion/exit/replay.
func _completion_return(_entrance: Dictionary) -> bool:
	var stats: PackedByteArray = var_to_bytes(production.player.stats)
	var unlocks: Array = production.attempts.state().unlocked_equipment.duplicate()
	var gear: Dictionary = production.player.equipment.snapshot()
	if not _expect(is_equal_approx(float(production.player.stats.dash_distance), 2.7), "completion route uses actual unchanged neutral 2.7m static kit"): return false
	_bind_contact_observation()
	if not await _resume_after_layout(): return false
	# Qualified prototype cardinal route: east then southwest, no completion yet.
	if not await _route_commands("FFFFFFDBBBB") or not await _count_checkpoint(1, ["o1-east-marker"]): return false
	if not await _route_commands("LLB") or not await _count_checkpoint(2, ["o1-east-marker", MARKER]): return false
	var latest: Dictionary = production.attempts.state().side_attempt.checkpoint.duplicate(true)
	if not await _advance_native_time(): return false
	production.request_pause()
	if not await _wait_pause(): return false
	var changed: Dictionary = production.capture_campaign_snapshot()
	if not _expect(not _same(changed, latest) and _same(production.attempts.state().side_attempt.checkpoint, latest), "genuine later active time differs from protected CP2; Pause does not replace it"): return false
	if not _disk(production.attempts.state()): return false
	var retired: Array[WeakRef] = []
	_collect_refs(_world_container(), retired)
	var previous: Dictionary = _native_ids()
	receiver_events.clear()
	production.menu.retry_requested.emit()
	if not await _wait_installed("A3-O1", "resume", latest, previous): return false
	if not _installed(latest) or not _distinct(previous) or not _quiet_selected() or not await _released(retired, "CP2 Retry retires every old actual source/floor/world binding"): return false
	if not _expect(_same(production.attempts.state().side_attempt.snapshot, latest) and _same(production.attempts.state().side_attempt.checkpoint, latest) and _same(production.attempts.story_snapshot(), protected), "public latest Retry restores full CP2 exact unit and protected Story"): return false
	if not _disk(production.attempts.state()) or not await _gui_resume(latest): return false
	_bind_contact_observation() # Retry installed a genuinely new level recipient.
	if not await _resume_after_layout(): return false
	if not await _route_commands("FFF"): return false
	if not await _completed_optional(latest, stats, unlocks): return false
	if not await _real_contact_return("RFF", "optional", latest): return false
	var completed_session: Dictionary = production.attempts.state()
	var story_refs: Array[WeakRef] = []
	_collect_refs(_world_container(), story_refs)
	var old_story: Dictionary = _core_ids()
	production.menu.replay_requested.emit("A3-O1", gear.duplicate(true))
	if not await _wait_installed("A3-O1", "resume", {}, old_story): return false
	var replay_entrance: Dictionary = production.capture_campaign_snapshot()
	if not _installed(replay_entrance) or not await _released(story_refs, "public replay entry retires restored Story world"): return false
	if not _expect(production.attempts.active_kind() == "replay" and production.active_level.call("state").collections.is_empty() and not production.active_level.is_completed() and production.player.equipment.snapshot() == gear and _same(production.attempts.story_snapshot(), protected) and _same(production.attempts.state().completed_optional, completed_session.completed_optional) and _same(production.attempts.state().reward_ids, completed_session.reward_ids), "public replay starts actual fresh isolated optional unit with existing one-time stamp"): return false
	_bind_contact_observation()
	if not await _resume_after_layout(): return false
	# Replay is earned through the same finite real contacts; no progress seed.
	if not await _route_commands("FFFFFFDBBBB") or not await _count_checkpoint(1, ["o1-east-marker"]): return false
	if not await _route_commands("LLB") or not await _count_checkpoint(2, ["o1-east-marker", MARKER]): return false
	var replay_checkpoint: Dictionary = production.attempts.state().side_attempt.checkpoint.duplicate(true)
	if not await _route_commands("FFF"): return false
	if not await _completed_optional(replay_checkpoint, stats, unlocks): return false
	if not await _real_contact_return("RFF", "replay", replay_checkpoint): return false
	return _expect(_same(production.attempts.state().completed_main, expected_session.completed_main) and _same(production.attempts.state().completed_optional, completed_session.completed_optional) and _same(production.attempts.state().reward_ids, completed_session.reward_ids) and _same(production.attempts.state().unlocked_equipment, unlocks) and _same(production.attempts.state().story, expected_session.story), "real replay completion/contact return deduplicates stamp and preserves complete Story/main/static availability") and _disk(production.attempts.state())

func _resume_after_layout() -> bool:
	if not _expect(paused and _valid_shell(), "public live Resume starts at actual paused boundary"): return false
	var before: String = Exact.stringify(production.capture_campaign_snapshot())
	var actor: CinderPlayer = production.player
	var mechanical: PackedByteArray = var_to_bytes([actor.get_world_action_records(), production.get_input_observation_state(), actor.get_world_action_clock(), actor.hp, actor.shells])
	await process_frame # One paused layout/operation boundary; no gameplay tick.
	if not _expect(paused and before == Exact.stringify(production.capture_campaign_snapshot()), "paused public layout preserves complete native packet before Resume"): return false
	production.menu.resume_requested.emit()
	return _expect(not paused and not production.menu.is_open() and mechanical == var_to_bytes([actor.get_world_action_records(), production.get_input_observation_state(), actor.get_world_action_clock(), actor.hp, actor.shells]), "actual public Resume follows layout without new input/action/resource/clock")

func _count_checkpoint(count: int, expected_order: Array) -> bool:
	for _frame: int in range(FRAME_LIMIT):
		await process_frame
		if not _valid_shell() or production.player.dead: return false
		var side: Variant = production.attempts.state().side_attempt
		if side == null or side.checkpoint.level.progress.checkpoint_id != O1.CHECKPOINT_IDS[count - 1]: continue
		var receipts: Array = side.checkpoint.level.local.route.collections
		var actual: Array = []
		for receipt: Dictionary in receipts: actual.append(receipt.id)
		return _expect(actual == expected_order and receipts.size() == count and side.checkpoint.level.progress.checkpoint_ids.size() == count and not side.checkpoint.level.progress.completed and _same(production.attempts.story_snapshot(), protected), "real unique native contacts durably record checkpoint count " + str(count))
	return _expect(false, "bounded actual collection checkpoint count " + str(count))

func _advance_native_time() -> bool:
	var clock: float = production.player.get_world_action_clock()
	for _frame: int in range(FRAME_LIMIT):
		await process_frame
		if not _valid_shell() or production.player.dead: return false
		if not paused and production.player.get_world_action_clock() > clock + 0.02: return true
	return _expect(false, "bounded genuine post-checkpoint active time")

func _route_commands(path: String, contact_return: bool = false) -> bool:
	var directions: Dictionary = {"L": Vector3.LEFT, "R": Vector3.RIGHT, "F": Vector3.FORWARD, "B": Vector3.BACK, "D": Vector3(1, 0, -0.5).normalized()}
	for index: int in range(path.length()):
		if not await _route_dash(directions[path.substr(index, 1)], contact_return and index == path.length() - 1): return false
	return true

func _route_dash(direction: Vector3, may_return: bool) -> bool:
	for _frame: int in range(LIVE_FRAME_LIMIT):
		await process_frame
		if not _valid_shell() or production.player.dead: return false
		if paused: continue # Real successful checkpoint/completion automatic-resume drain.
		var ready: Dictionary = production.player.get_threat_response_state()
		if not ready.get("stable", false) or float(ready.dash_cooldown_left_s) != 0.0 or production.player.action_in_progress(): continue
		var actor: CinderPlayer = production.player
		var start: Vector3 = actor.global_position
		var motion: Vector3 = direction * float(actor.stats.dash_distance)
		var bindings: Dictionary = production.active_level.call("scheduler_bindings")
		var swept: Dictionary = BodySweep.sweep(actor, actor.global_transform, motion, bindings.floors.values())
		if not _expect(not swept.has("error") and not swept.get("collided", true) and (swept.end as Vector3).distance_to(start + motion) <= 0.005, "actual body/floor preflight supports production contact-route dash", str(swept)): return false
		var sequence: int = _sequence()
		if not _expect(actor.request_dash(direction), "ordinary public controller accepts production contact dash"): return false
		for _tick: int in range(FRAME_LIMIT):
			await process_frame
			if not _valid_shell(): return false
			if production.active_level.level_id != "A3-O1":
				return _expect(may_return and production.active_level.level_id == STORY_ID and not contact_receipts.is_empty(), "real contact transaction may replace in-flight exit dash; no completed-dash credit claimed")
			if production.player != actor or actor.dead: return _expect(false, "native contact route keeps original living Hero until authored exit")
			var records: Array[Dictionary] = actor.get_world_action_records(sequence)
			if records.size() == 1 and not actor.action_in_progress():
				return _expect(records[0].kind == "dash" and not records[0].blocked and records[0].world_origin == start and (records[0].landing as Vector3).distance_to(start + motion) <= 0.005 and records[0].landing == actor.global_position and not CinderPlayer.encode_world_action_record(records[0], actor.get_world_action_clock()).is_empty(), "genuine completed controller dash retains actual travel/landing/native action record")
		return _expect(false, "bounded production native dash/contact transition")
	return _expect(false, "bounded native production route readiness/auto-resume")

func _completed_optional(latest: Dictionary, stats: PackedByteArray, unlocks: Array) -> bool:
	production.request_pause()
	if not await _wait_pause(): return false
	var snapshot: Dictionary = production.capture_campaign_snapshot()
	var state: Dictionary = production.attempts.state()
	var stamp: String = production.registry.entry("A3-O1").reward_id
	var owner: String = str(production.active_level.get_instance_id())
	if not _expect(production.active_level.is_completed() and snapshot.level.local.route.collections.size() == O1.MARKERS.size() and snapshot.level.progress.contact_exit_id.is_empty() and _same(state.side_attempt.checkpoint, latest) and state.completed_optional == ["A3-O1"] and state.reward_ids == [stamp] and state.completed_main == expected_session.completed_main and _same(state.unlocked_equipment, unlocks) and var_to_bytes(production.player.stats) == stats and _same(state.story, expected_session.story) and _owner_events(owner, "completion_requested") == 1, "third genuine native contact records exactly one production clear/stamp with CP2/static stats/Story retained"): return false
	var before: String = Exact.stringify(snapshot)
	var events_before: PackedByteArray = var_to_bytes(receiver_events)
	if not _expect(not production.active_level.request_completion(O1.COMPLETION_ID) and before == Exact.stringify(production.capture_campaign_snapshot()) and _same(production.attempts.state(), state) and events_before == var_to_bytes(receiver_events), "duplicate real completion refuses without packet/model/event mutation"): return false
	return _installed(snapshot) and _disk(state)

func _bind_contact_observation() -> void:
	var level: CinderLevel = production.active_level
	level.contact_exit_requested.connect(_observe_contact.bind(weakref(level)))

func _observe_contact(id: String, exit_id: String, owner: WeakRef) -> void:
	var level: Node = owner.get_ref() as Node
	if not _expect(level != null and id == "A3-O1" and exit_id == O1.EXIT_ID, "actual production contact event carries canonical optional identity"): return
	var state: Dictionary = level.call("state")
	contact_receipts[str(level.get_instance_id())] = {"exit_id": exit_id, "contact": state.contact.duplicate(true), "collections": state.collections.duplicate(true)}

func _owner_events(owner: String, kind: String) -> int:
	var count: int = 0
	for event: Dictionary in receiver_events:
		if event.owner == owner and event.kind == kind: count += 1
	return count

func _real_contact_return(path: String, kind: String, latest: Dictionary) -> bool:
	var owner: String = str(production.active_level.get_instance_id())
	var old_refs: Array[WeakRef] = []
	_collect_refs(_world_container(), old_refs)
	var previous: Dictionary = _core_ids()
	if not await _resume_after_layout(): return false
	if not await _route_commands(path, true): return false
	if not await _wait_installed(STORY_ID, "journey", protected, previous): return false
	if not _installed(protected) or not await _released(old_refs, "real optional/replay contact return retires all original native sources/floor/cues"): return false
	if not _expect(contact_receipts.has(owner) and _owner_events(owner, "contact_exit_requested") == 1 and production.attempts.active_kind() == "story" and production.attempts.state().side_attempt == null and _same(production.attempts.state().story, expected_session.story), "one real grounded contact returns protected Story/Journey without duplicate exit"): return false
	# The real exit writes the complete latched side packet immediately before
	# leave_side writes returned Story. Inspect that original format2 backup.
	var reader = Store.new(isolated + "campaign.json.bak")
	var previous_session: Dictionary = reader.read_payload()
	var recorded: Dictionary = contact_receipts[owner]
	var side: Variant = previous_session.get("side_attempt")
	if not _expect(reader.last_error.is_empty() and not reader.loaded_backup and side != null and side.kind == kind and side.level_id == "A3-O1" and side.snapshot.level.progress.contact_exit_id == O1.EXIT_ID and side.snapshot.level.progress.completed and _same(side.snapshot.level.local.route.contact, recorded.contact) and _same(side.snapshot.level.local.route.collections, recorded.collections) and _same(side.checkpoint, latest) and _same(previous_session.story, expected_session.story), "independent original backup retains real native latched contact/clear/CP2 and whole protected Story", reader.last_error): return false
	return _disk(production.attempts.state())

func _seed_story(registry: CinderCampaignRegistry) -> bool:
	paused = true
	preview = MainScene.instantiate()
	preview.set("level_scene_path", STORY_PATH)
	root.add_child(preview)
	preview.call("open_bench") # Main construction resumes; restore the actual public paused boundary before any frame.
	var actor: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var camera: Camera3D = preview.get("camera") as Camera3D
	if not _expect(actor != null and level != null and camera != null and level.level_id == STORY_ID and String(preview.get("level_load_error")).is_empty(), "actual accepted Main opening constructs the protected Story donor"):
		return false
	await process_frame # Native ready/layout only; gameplay remains paused.
	var actor_state: Dictionary = actor.snapshot_state()
	var local_state: Dictionary = level.snapshot_state()
	var input: Dictionary = preview.call("get_input_observation_state")
	if not _expect(paused and not actor_state.is_empty() and not local_state.is_empty() and actor.get_world_action_records().is_empty() and input.sequence == 0 and input.last_observation.is_empty(), "actual paused initial actor/local/input writers contain no fabricated gameplay", actor.last_snapshot_error + "; " + level.last_snapshot_error):
		return false
	var anchor: Vector2 = input.anchor_normalized
	var fresh_shell: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": input.sequence, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Game.CAMERA_OFFSET), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}
	protected = {"schema_version": 1, "level_id": STORY_ID, "scene_path": STORY_PATH, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": actor_state, "level": local_state, "shell": fresh_shell}
	var detached = Attempts.new(registry)
	expected_session = detached.state()
	expected_session.completed_main = registry.main_route().slice(0, 11) # TEST ONLY predecessor completions.
	expected_session.story = {"kind": "story", "level_id": STORY_ID, "snapshot": protected.duplicate(true), "checkpoint": protected.duplicate(true)}
	var problem: String = detached.state_error(expected_session)
	var writer = Store.new(isolated + "campaign.json")
	writer.payload_validator = detached.saved_payload_error # Structural model, never a live Shell validator.
	if not _expect(problem.is_empty() and expected_session.completed_main[-1] == "A3-L1" and writer.write_payload(expected_session), "detached structural Attempts/format2 Store seed TEST predecessor prefix plus real complete native Story packet", problem + "; " + writer.last_error):
		return false
	var refs: Array[WeakRef] = []
	_collect_refs(preview, refs)
	level.exit_level()
	preview.queue_free()
	preview = null
	return await _released(refs, "seed donor normal whole-tree retirement") and _disk(expected_session)

func _new_shell(expected: Dictionary) -> bool:
	receiver_events.clear()
	watched.clear()
	production = Shell.new()
	if not _expect(production.configure_runtime(raw, isolated + "campaign.json", isolated + "settings.json", isolated + "preferences.json"), "new actual Shell uses isolated paths and TEST metadata before entry", production.campaign_error): return false
	root.add_child(production)
	for _frame: int in range(FRAME_LIMIT):
		await process_frame
		if not _valid_shell(): return false
		if paused and not production.is_pause_requested() and production.menu.page_name() == "title" and production.player == null and _same(production.attempts.state(), expected):
			return _expect(true, "exact complete async startup session settles at Title before public load")
	return _expect(false, "bounded public startup session; Title alone is insufficient", str(production.attempts.state()))

func _wait_installed(id: String, page: String, expected: Dictionary = {}, previous: Dictionary = {}) -> bool:
	for _frame: int in range(FRAME_LIMIT):
		await process_frame
		if not _valid_shell(): return false
		if not paused or production.is_pause_requested() or production.menu.page_name() != page or not is_instance_valid(production.active_level) or not is_instance_valid(production.player) or production.active_level.level_id != id: continue
		if not previous.is_empty():
			var now: Dictionary = _core_ids()
			if now.world == previous.world or now.level == previous.level or now.hero == previous.hero: continue
		if not expected.is_empty() and not _same(production.capture_campaign_snapshot(), expected): continue
		return true
	return _expect(false, "bounded public installed state: " + id + "/" + page, str(_core_ids()) + "; " + production.campaign_error)

func _wait_pause() -> bool:
	for _frame: int in range(FRAME_LIMIT):
		await process_frame
		if not _valid_shell(): return false
		if paused and not production.is_pause_requested() and production.menu.page_name() == "pause":
			var snapshot: Dictionary = production.capture_campaign_snapshot()
			if not snapshot.is_empty() and _same(production.attempts.active_snapshot(), snapshot): return true
	return _expect(false, "bounded public Pause saves exact current aggregate", production.campaign_error)

func _collect_first_marker() -> bool:
	var target: Vector3 = O1.MARKERS[MARKER].position
	for _dash_index: int in range(3):
		if not _valid_shell(): return false
		var state: Dictionary = production.active_level.call("state")
		if state.collections.size() == 1: break
		if not await _dash_toward(target): return false
	for _frame: int in range(LIVE_FRAME_LIMIT):
		await process_frame
		if not _valid_shell() or production.player.dead: return _expect(false, "native marker contact keeps actual Hero alive")
		var side: Variant = production.attempts.state().side_attempt
		if side != null and side.checkpoint.level.progress.checkpoint_id == O1.CHECKPOINT_IDS[0]:
			checkpoint = side.checkpoint.duplicate(true)
			var receipts: Array = checkpoint.level.local.route.collections
			first_collection = receipts.size() == 1 and receipts[0].id == MARKER
			return _expect(first_collection and checkpoint.level.progress.checkpoint_ids == {O1.CHECKPOINT_IDS[0]: "encounter"} and not checkpoint.level.progress.completed and checkpoint.player.world_actions.history.size() >= 1 and _same(production.attempts.story_snapshot(), protected), "actual dash-contact durably captures first marker receipt/checkpoint without completion or Story mutation")
	return _expect(false, "bounded real first marker/checkpoint consumer")

func _dash_toward(target: Vector3) -> bool:
	for _frame: int in range(LIVE_FRAME_LIMIT):
		await process_frame
		if not _valid_shell() or production.player.dead: return false
		if paused: continue # The previous checkpoint may be in its real async auto-resume drain.
		var response: Dictionary = production.player.get_threat_response_state()
		if not response.get("stable", false) or float(response.get("dash_cooldown_left_s", 1.0)) != 0.0 or production.player.action_in_progress(): continue
		var sequence: int = _sequence()
		var direction: Vector3 = target - production.player.global_position
		direction.y = 0.0
		if not _expect(direction.length_squared() > 0.0 and production.player.request_dash(direction), "ordinary public controller accepts native marker approach dash"): return false
		for _tick: int in range(FRAME_LIMIT):
			await process_frame
			if not _valid_shell() or production.player.dead: return false
			var records: Array[Dictionary] = production.player.get_world_action_records(sequence)
			if records.size() == 1 and not production.player.action_in_progress():
				return _expect(records[0].kind == "dash" and records[0].landing == production.player.global_position and not records[0].blocked, "genuine completed ordinary dash record ends at actual native landing")
		return _expect(false, "bounded real dash completion")
	return _expect(false, "bounded native stable/dash-ready marker approach")

func _wait_held_stalker() -> bool:
	for _frame: int in range(LIVE_FRAME_LIMIT):
		await process_frame
		if not _valid_shell() or production.player.dead: return _expect(false, "genuine held source wait keeps native Hero alive")
		if paused: continue
		if not _held_receipt().is_empty(): return _expect(true, "genuine unchanged Stalker warning carries actual scheduler reservation")
	return _expect(false, "bounded genuine held Stalker phase/lease", str(production.active_level.call("state")))

func _held_receipt() -> Dictionary:
	var level: CinderLevel = production.active_level
	var source: Node = level.get("sources")[SOURCE]
	var scheduler: CinderThreatScheduler = level.get("threat_scheduler") as CinderThreatScheduler
	var state: Dictionary = source.call("state")
	var control: Dictionary = scheduler.source_control_state(source)
	if state.phase != "warning" or String(state.reservation_id).is_empty() or control.reservations.size() != 1: return {}
	var lease: Dictionary = control.reservations[0]
	if lease.id != state.reservation_id or lease.state != state.phase: return {}
	return {"source_id": SOURCE, "phase": state.phase, "reservation_id": state.reservation_id, "cycle": state.cycle, "clock_s": scheduler.get_clock(), "hp": state.hp, "dead": state.dead}

func _installed(expected: Dictionary) -> bool:
	var view: SubViewport = production.world.get_parent() as SubViewport
	var container: SubViewportContainer = view.get_parent() as SubViewportContainer if view != null else null
	var optics: String = String(production.active_level.call("candidate_presentation_error", production.camera, production.hud)) if production.active_level.has_method("candidate_presentation_error") else production.camera_framing_error(production.player_camera_framing_points())
	return _expect(paused and not production.is_pause_requested() and not expected.is_empty() and view != null and container != null and container.get_parent() == production and container.is_visible_in_tree() and view.own_world_3d and view.get_camera_3d() == production.camera and production.camera.get_script() == null and production.camera.get_viewport() == view and production.player.get_world_3d() == production.world.get_world_3d() and production.active_level.get_world_3d() == production.world.get_world_3d() and not production.active_level.is_restore_candidate() and production.active_level.hero == production.player and production.active_level.shared_shell == production and _same(production.capture_campaign_snapshot(), expected) and optics.is_empty(), "actual installed native World/Hero/Level/Camera/HUD exact aggregate and current optics", optics + "; " + production.campaign_error)

func _gui_resume(expected: Dictionary) -> bool:
	if not _expect(paused, "actual GUI layout begins at paused native boundary"): return false
	var before: String = Exact.stringify(production.capture_campaign_snapshot())
	var events_before: PackedByteArray = var_to_bytes(receiver_events)
	await process_frame
	if not _expect(paused and _same(production.capture_campaign_snapshot(), expected) and before == Exact.stringify(production.capture_campaign_snapshot()) and events_before == var_to_bytes(receiver_events), "one paused native layout frame preserves entire gameplay packet/events"): return false
	var button: Control = production.menu.find_child("ResumeButton", true, false) as Control
	if not _expect(button != null and button.is_visible_in_tree() and button.get_global_rect().has_area(), "actual visible public Resume button has native layout"): return false
	var actor: CinderPlayer = production.player
	var mechanical: PackedByteArray = var_to_bytes([actor.get_world_action_records(), production.get_input_observation_state(), actor.get_world_action_clock(), actor.hp, actor.shells])
	var at: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new(); motion.position = at; motion.global_position = at
	root.push_input(motion, true)
	var down := InputEventMouseButton.new(); down.button_index = MOUSE_BUTTON_LEFT; down.position = at; down.global_position = at; down.pressed = true
	root.push_input(down, true)
	var handled: bool = root.is_input_handled()
	var up := down.duplicate() as InputEventMouseButton; up.pressed = false
	root.push_input(up, true)
	if not _expect(handled and root.is_input_handled() and not paused and not production.menu.is_open() and mechanical == var_to_bytes([actor.get_world_action_records(), production.get_input_observation_state(), actor.get_world_action_clock(), actor.hp, actor.shells]) and events_before == var_to_bytes(receiver_events), "actual routed GUI Resume consumed without new gameplay/input/resources/events"): return false
	production.request_pause() # No yield/native tick between consumed Resume and public Pause.
	if not await _wait_pause(): return false
	return _expect(_same(production.capture_campaign_snapshot(), expected), "immediate public Pause after GUI Resume preserves complete exact checkpoint without gameplay tick") and _disk(production.attempts.state())

func _archive_held(entrance: Dictionary, receipt: Dictionary) -> bool:
	if not _expect(paused and receipt.get("phase") == "warning" and _same(production.capture_campaign_snapshot(), held) and _same(production.attempts.active_snapshot(), held), "export only exact genuine paused warning/session with native packet authority"): return false
	archive_path = "res://captures/act3/pillars-before-time/optional-held-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	if not _expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(archive_path)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(archive_path)) == OK, "new held archive directory preserves all earlier evidence"): return false
	var values: Dictionary = {"session.native.json": production.attempts.state(), "held.native.json": held, "entrance.native.json": entrance, "checkpoint.native.json": checkpoint, "story.native.json": protected, "start-session.native.json": expected_session, "registry.native.json": raw}
	var files: Dictionary = {}
	for filename: String in values:
		var wire: String = Exact.stringify(values[filename])
		if not _expect(not wire.is_empty(), "archive complete finite native JSON packet: " + filename): return false
		var file: FileAccess = FileAccess.open(archive_path.path_join(filename), FileAccess.WRITE)
		if not _expect(file != null, "new original native archive file opens: " + filename): return false
		file.store_string(wire + "\n")
		file.close()
		files[filename] = {"sha256": FileAccess.get_sha256(archive_path.path_join(filename)), "exact_wire_sha256": wire.sha256_text()}
	var pins: Dictionary = {}
	for source_path: String in ARCHIVE_PINS:
		var digest: String = FileAccess.get_sha256(source_path)
		if not _expect(digest.length() == 64, "scoped original source pin exists: " + source_path): return false
		pins[source_path] = digest
	var manifest: Dictionary = {"schema_version": 1, "kind": "a3-o1-genuine-warning-session-1", "test_only": true, "adopted_baseline_commit": ADOPTED_BASELINE, "git_provenance": "Exact native runner HEAD/dirty/input manifest governs execution; listed source_pins freeze the actual bytes", "pins_scope": "listed authored/direct transport sources; native runner input manifest remains independent authority", "fixture_sha256": FileAccess.get_sha256(ARCHIVE_PINS[0]), "source_pins": pins, "files": files, "held_receipt": receipt, "test_context": "TEST prefix11/O1 readiness; actual accepted A3-L2 initial Story, first native dash-contact checkpoint, original held warning; no collection/HP/history/lease seeds", "public_flow_validation": "pending; actual native runner closure is authoritative", "portrait_validation": "unexecuted; archive creates no pixels"}
	var wire: String = Exact.stringify(manifest)
	var file: FileAccess = FileAccess.open(archive_path.path_join("manifest.json"), FileAccess.WRITE)
	if not _expect(not wire.is_empty() and file != null, "complete finite original warning provenance manifest opens"): return false
	file.store_string(wire + "\n")
	file.close()
	print("O1 genuine held-warning archive: ", archive_path, "; manifest_sha256=", FileAccess.get_sha256(archive_path.path_join("manifest.json")))
	return true

func _disk(expected: Dictionary) -> bool:
	var reader = Store.new(isolated + "campaign.json")
	var payload: Dictionary = reader.read_payload()
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(isolated + "campaign.json"))
	var wire: String = Exact.stringify(payload)
	var decoded: Dictionary = Exact.parse(wire)
	return _expect(reader.last_error.is_empty() and not reader.loaded_backup and envelope is Dictionary and envelope.get("format_version") == 2 and envelope.get("payload_json") is String and envelope.payload_json.sha256_text() == envelope.get("sha256") and _same(payload, expected) and decoded.get("accepted", false) and _same(decoded.get("value"), expected), "independent Store format2/checksum/full-precision complete session equals public model", reader.last_error)

func _core_ids() -> Dictionary:
	if not is_instance_valid(production) or not is_instance_valid(production.world) or not is_instance_valid(production.player) or not is_instance_valid(production.active_level): return {}
	var view: Node = production.world.get_parent()
	return {"world": production.world.get_instance_id(), "world3d": production.world.get_world_3d().get_instance_id(), "level": production.active_level.get_instance_id(), "hero": production.player.get_instance_id(), "camera": production.camera.get_instance_id(), "fx": production.fx.get_instance_id(), "viewport": view.get_instance_id(), "container": view.get_parent().get_instance_id()}

func _native_ids() -> Dictionary:
	var result: Dictionary = _core_ids()
	var level: CinderLevel = production.active_level
	result.scheduler = (level.get("threat_scheduler") as Node).get_instance_id()
	var sources: Dictionary = level.get("sources")
	result.source = (sources[SOURCE] as Node).get_instance_id() # Retained selected-source alias for portrait consumers.
	for id: String in sources:
		result["source/" + id] = (sources[id] as Node).get_instance_id()
	result.exit_cue = (level.get("exit_cue") as Node).get_instance_id()
	var floor: Dictionary = level.call("scheduler_bindings").floors["shelf-floor"]
	var collision: CollisionShape3D = floor.collision
	result.floor_collision = collision.get_instance_id()
	result.floor_body = collision.get_parent().get_instance_id()
	return result

func _distinct(previous: Dictionary) -> bool:
	var current: Dictionary = _native_ids()
	for key: String in previous:
		var detail: Dictionary = {"current": current.get(key), "previous": previous[key], "has_current": current.has(key), "current_zero": int(current.get(key, 0)) == 0, "previous_zero": int(previous[key]) == 0, "current_positive": int(current.get(key, 0)) > 0, "unequal": current.get(key) != previous[key], "current_instance_valid": is_instance_id_valid(int(current.get(key, 0)))}
		if not _expect(current.has(key) and int(current[key]) != 0 and is_instance_id_valid(int(current[key])) and current[key] != previous[key], "fresh independent actual native identity: " + key, str(detail)): return false
	return true

func _world_container() -> Node:
	return production.world.get_parent().get_parent()

func _collect_refs(node: Node, refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child: Node in node.get_children(): _collect_refs(child, refs)

func _released(refs: Array[WeakRef], label: String) -> bool:
	for _frame: int in range(FRAME_LIMIT):
		if not refs.is_empty() and refs.all(func(ref: WeakRef) -> bool: return ref.get_ref() == null): return _expect(true, label)
		await process_frame
	return _expect(false, label)

func _dispose_shell() -> bool:
	if not is_instance_valid(production): return true
	paused = true
	var refs: Array[WeakRef] = []
	_collect_refs(production, refs)
	production.queue_free()
	production = null
	return await _released(refs, "normal entire actual Shell/UI/World tree cleanup")

func _watch_node(node: Node) -> void:
	if not is_instance_valid(production) or not production.is_ancestor_of(node) or watched.has(node.get_instance_id()): return
	watched[node.get_instance_id()] = true
	for row: Dictionary in node.get_signal_list():
		if row.name in ["fired", "died", "action_resolved", "world_action_executed", "hit_resolved", "event_dispatched", "checkpoint_requested", "completion_requested", "contact_exit_requested"] and row.args.size() <= 3:
			node.connect(row.name, Callable(self, "_event" + str(row.args.size())).bind(str(node.get_instance_id()), String(row.name)))

func _event0(owner: String, kind: String) -> void: receiver_events.append({"owner": owner, "kind": kind})
func _event1(_a: Variant, owner: String, kind: String) -> void: _event0(owner, kind)
func _event2(_a: Variant, _b: Variant, owner: String, kind: String) -> void: _event0(owner, kind)
func _event3(_a: Variant, _b: Variant, _c: Variant, owner: String, kind: String) -> void: _event0(owner, kind)

func _quiet_selected() -> bool:
	var refs: Array[WeakRef] = []
	_collect_refs(production.active_level, refs)
	_collect_refs(production.player, refs)
	var selected: Dictionary = {}
	for ref: WeakRef in refs: selected[str((ref.get_ref() as Node).get_instance_id())] = true
	var unexpected: Array = []
	for event: Dictionary in receiver_events:
		if selected.has(event.owner): unexpected.append(event)
	return _expect(unexpected.is_empty(), "selected fresh recipient emits no gameplay/progression during quiet restore; pool/donor cleanup remains separate", str(unexpected))

func _sequence() -> int:
	var records: Array[Dictionary] = production.player.get_world_action_records()
	return int(records.back().sequence) if not records.is_empty() else 0

func _same(a: Variant, b: Variant) -> bool:
	var wire: String = Exact.stringify(a)
	return not wire.is_empty() and wire == Exact.stringify(b)

func _valid_shell() -> bool:
	if finished: return false
	if not is_instance_valid(production) or not production.campaign_error.is_empty():
		return _expect(false, "public Shell has no refused operation", production.campaign_error if is_instance_valid(production) else "no Shell")
	return true

func _expect(ok: bool, label: String, detail: String = "") -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL O1 optional Shell: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok

func _finish() -> void:
	if finished: return
	finished = true
	await _dispose_shell()
	if is_instance_valid(preview):
		var refs: Array[WeakRef] = []
		_collect_refs(preview, refs)
		preview.queue_free(); preview = null
		await _released(refs, "remaining seed donor cleanup")
	if node_added.is_connected(_watch_node): node_added.disconnect(_watch_node)
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == canonical_bytes, "canonical registry bytes unchanged")
	for filename: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		var path: String = isolated + filename
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	AudioServer.set_bus_layout(old_audio)
	Engine.max_fps = old_fps
	var scope: String = "real CP1/CP2 latest Retry, third completion/stamp once, native contact/protected Story Journey, public real replay/stamp dedup; no held-warning/disk-relaunch/portrait/fairness credit" if completion_return else "native first-marker checkpoint, authentic held Pause/format2 Save/new disk Side Resume/Retry/consumed GUI/early Journey protected Story; no CP2/completion/contact-return/replay/portrait/fairness credit"
	print("O1 optional Shell: %d checks/%d failures; scope_complete=%s; selector=%s; %s; TEST prefix11/readiness only, actual direct controller inputs, complete normal cleanup." % [checks, failures, str(scope_complete), "completion-return" if completion_return else "held-transport", scope])
	quit(0 if failures == 0 and scope_complete else 1)
