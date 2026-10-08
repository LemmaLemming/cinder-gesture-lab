extends SceneTree
## TEST ONLY: actual authored A3-L1 entry checkpoint and production shell/store.
## Canonical registry bytes never change. Accepted A3-L1 metadata and the ten
## predecessor completions exist only in memory to stage this unfinished level.
## Routed viewport events are automated engine input, not native/human evidence.
## Default: first checkpoint, format-2 disk save, rejection and exact fresh retry.
## --first-checkpoint-only: stop after the actual first checkpoint/disk checks.
## Run only through dev.py; --level-scene/--capture would select shell preview.

const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Stalker = preload("res://scripts/acts/act3/sunbound_stalker.gd")
const MainScene: PackedScene = preload("res://scenes/main.tscn")
const FullPath: String = "res://scenes/acts/act3/a3_l1.tscn"
const FirstCheckpoint: String = "useful-flank-entry"
const FirstPocket: String = "useful-flank"
const EntryZ: float = 30.0
const CheckpointHP: float = 31.25
const SourceIDs: Array[String] = ["l1-flank-stalker", "l1-approach-stalker", "l1-crossing-west", "l1-crossing-east", "l1-departure-stalker"]

var _checks: int = 0
var _failures: int = 0
var _test_root: String = ""
var _game: CinderCampaignShell
var _checkpoint_events: Array[Dictionary] = []
var _restore_events: Array[String] = []
var _watching_restore: bool = false
var _checkpoint_only: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_root = "user://test-act3-authored-shell-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	_checkpoint_only = OS.get_cmdline_user_args().has("--first-checkpoint-only")
	var canonical: String = FileAccess.get_file_as_string(Registry.DATA_PATH)
	var raw: Variant = JSON.parse_string(canonical)
	if _expect(raw is Dictionary, "read canonical registry bytes without editing them"):
		await _exercise(raw)
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == canonical, "canonical registry bytes remain unchanged")
	await _close_case()
	print("Twin Suns authored shell %s: %d checks, %d failures (TEST ONLY; no level/registry/native/human acceptance)" % ["first-checkpoint-only" if _checkpoint_only else "first-checkpoint/save/retry", _checks, _failures])
	quit(1 if _failures else 0)


func _exercise(canonical: Dictionary) -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--level-scene") or argument in ["--capture", "--capture-polish"]:
			_expect(false, "run authored-shell fixture without preview-selecting arguments")
			return
	var initial: Dictionary = await _initial_snapshot()
	if initial.is_empty():
		return
	var raw: Dictionary = canonical.duplicate(true)
	for info: Dictionary in raw.levels:
		if info.id == "A3-L1":
			info.scene_path = FullPath
			info.readiness = "accepted" # TEST ONLY, in-memory metadata.
			info.accepted_commit = "a".repeat(40) # TEST ONLY fixture marker.
			info.api_revision = Registry.API_REVISION
	_game = Shell.new()
	if not _expect(_game.configure_runtime(raw, _test_root + "campaign.json", _test_root + "settings.json", _test_root + "preferences.json"), "configure actual shell with isolated user paths"):
		_game.free()
		_game = null
		return
	root.add_child(_game)
	await _settle()
	var prefix: Array[String] = []
	for id: String in _game.registry.main_route():
		if id == "A3-L1":
			break
		prefix.append(id)
	var session: Dictionary = _game.attempts.state()
	session.completed_main = prefix.duplicate() # TEST ONLY predecessor seed.
	session.story = {"kind": "story", "level_id": "A3-L1", "snapshot": initial.duplicate(true), "checkpoint": initial.duplicate(true)}
	if not _expect(prefix.size() == 10 and _game.attempts.restore_session(session), "public restore_session validates actual fresh preview seed and ten-predecessor fixture: " + _game.attempts.last_error):
		return
	_game.resume_campaign() # Public load-active operation; leaves a resume menu.
	await _settle()
	if not _expect(_game.campaign_error.is_empty() and is_instance_valid(_game.active_level) and is_instance_valid(_game.player), "actual shell prepares the authored scene: " + _game.campaign_error):
		return
	if not _expect(paused and _game.menu.page_name() == "resume" and _game.active_level.scene_file_path == FullPath and _game.active_level.shared_shell == _game, "fresh staged authored world retains its entered shared lifecycle and waits paused"):
		return
	if not _expect(_level_state().get("configuration_error", "missing") == "" and _source_bindings_valid(), "actual authored root binds five live stable sources and one common scheduler"):
		return
	_expect(_game.player.presentation_id == "act3_traveller", "actual shared player uses the selected Act 3 presentation")
	_game.active_level.checkpoint_requested.connect(func(id: String, checkpoint: String, boundary: String) -> void:
		_checkpoint_events.append({"level_id": id, "checkpoint_id": checkpoint, "boundary": boundary, "paused": paused, "hero_position": _game.player.global_position, "hero_clock_s": _game.player.get_world_action_clock()}))
	if not _resume_button_consumed("initial entry") or not await _wait_clock(_game.player, 0.12, false):
		return
	if not _expect(_game.player.get_threat_response_state().motion.grounded, "real staged hero settles on the continuous authored floor"):
		return
	# Real routed touches move into the broad left corridor, then toward the
	# entry. No transform/clock/route/death/scheduler mutation stages admission.
	if not await _swipe(Vector2(0.56, 0.62), Vector2(0.28, 0.62), false):
		return
	var dash_distance: float = float(_game.player.equipment.resolved_stats().dash_distance)
	for _step: int in range(8):
		if _game.player.global_position.z <= EntryZ + dash_distance + 0.1:
			break
		if not await _swipe(Vector2(0.56, 0.68), Vector2(0.56, 0.38), false):
			return
	if not _expect(_game.player.global_position.z > EntryZ and _game.player.global_position.z <= EntryZ + dash_distance + 0.1 and _checkpoint_events.is_empty(), "bounded real route reaches just before the first spatial checkpoint without fake entry"):
		return
	# Public depleted-resource fixture immediately before the real crossing.
	# Natural fractional reload/action clocks are neither reset nor rewritten.
	_game.player.hp = CheckpointHP
	_game.player.shells = 0
	if not await _swipe(Vector2(0.56, 0.68), Vector2(0.56, 0.38), true):
		return
	if not await _wait_checkpoint():
		return
	var checkpoint: Dictionary = _game.attempts.state().story.checkpoint
	if not _assert_checkpoint(checkpoint):
		return
	if not _assert_disk_checkpoint(checkpoint):
		return
	if _checkpoint_only:
		_expect(_no_progress_awarded(prefix), "first-entry selector stops without a death, completion, exit, reward or later-level transition")
		return
	# A later real dash changes pose/actor history, source approach and scenery
	# time. Keep this bounded before the first lunge; no encounter clear is faked.
	if not await _swipe(Vector2(0.56, 0.62), Vector2(0.28, 0.62), false):
		return
	_game.player.hp = 7.5
	_game.player.shells = 1
	_game.request_pause()
	await _settle()
	var changed: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(paused and not changed.is_empty() and changed.player.resources.hp == 7.5 and changed.player.resources.shells == 1 and not _same_exact(changed.player.motion.position, checkpoint.player.motion.position) and not _same_exact(changed.level.local, checkpoint.level.local), "later actual pose/history/source/scenery and public resources differ from checkpoint without changing checkpoint history"):
		return
	if not _expect(_same_exact(_game.attempts.state().story.checkpoint, checkpoint), "later public pause persists the changed attempt without replacing its earlier checkpoint"):
		return
	await create_timer(0.08, true).timeout
	if not _expect_exact(_game.capture_campaign_snapshot(), changed, "explicit pause freezes the entire later actor/five-source/scheduler/sun/input/camera unit"):
		return
	var before_load: Dictionary = _game.attempts.state()
	if not _expect(_game.attempts.load_saved(), "public production attempts reopens its real format-2 checkpoint generation: " + _game.attempts.last_error):
		return
	if not _expect(_same_exact(_game.attempts.state(), before_load) and _same_exact(_game.capture_campaign_snapshot(), changed), "reopened exact SaveStore payload preserves protected attempt data and leaves the paused live world unchanged"):
		return
	if not _assert_rejections(checkpoint):
		return
	var old_level: CinderLevel = _game.active_level
	var old_actor: CinderPlayer = _game.player
	var old_world: Node3D = _game.world
	_restore_events.clear()
	_watching_restore = true
	node_added.connect(_observe_restore_node)
	_game.request_retry()
	await _settle()
	_watching_restore = false
	node_added.disconnect(_observe_restore_node)
	var retried: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(_game.campaign_error.is_empty() and paused and _game.menu.page_name() == "resume" and not retried.is_empty(), "public retry installs a fresh paused authored world: " + _game.campaign_error):
		return
	if not _expect_exact(retried, checkpoint, "actual fresh-world retry restores every saved actor/local/input/camera scalar and history exactly"):
		return
	if not _expect(_restore_events.is_empty(), "candidate creation and actor-before-local restore emit no action, equipment, damage, death or progression event: " + str(_restore_events)):
		return
	var entry: Dictionary = checkpoint.level.local.route.entries[0]
	_expect(float(entry.clock_s) == float(checkpoint.level.local.scheduler.clock_s) and _same_exact(entry.hero_position, checkpoint.player.motion.position) and Codec.read_vector3(entry.hero_position) != _game.active_level.spawn_position(), "current-clock spatial entry binds the saved hero away from fresh spawn, requiring actual actor-before-local restore")
	if not _assert_restored_live_unit(checkpoint):
		return
	_expect(not is_instance_valid(old_level) and not is_instance_valid(old_actor) and not is_instance_valid(old_world) and _count_levels(root) == 1 and _game.active_level.shared_shell == _game, "retry retires the old world and preserves exactly one entered authored level")
	await create_timer(0.08, true).timeout
	if not _expect_exact(_game.capture_campaign_snapshot(), checkpoint, "restored clocks/resources/history/suns/input/camera remain frozen until explicit resume"):
		return
	if not _resume_button_consumed("checkpoint retry"):
		return
	if not await _wait_clock(_game.player, 0.12, false):
		return
	_expect(_game.player.hp == CheckpointHP and _game.player.hp < _game.player.max_hp and _game.player.shells == 0, "legitimate resumed clocks preserve depleted HP and zero ammo without healing/refill")
	var after: Array[Dictionary] = _game.player.get_world_action_records(int(checkpoint.player.world_actions.sequence))
	var pending: Dictionary = checkpoint.player.world_actions.pending_dash
	_expect(after.size() == 1 and not pending.is_empty() and after[0].kind == "dash" and float(after[0].started_at_s) == float(pending.started_at_s), "resume finishes only the saved in-flight dash, not a menu-induced extra dash/primary/blast")
	_expect(_checkpoint_events.size() == 1 and _no_progress_awarded(prefix), "retry/resume neither reemits the entry checkpoint nor manufactures death, clear, exit or campaign reward")


func _initial_snapshot() -> Dictionary:
	paused = false
	var preview: Node = MainScene.instantiate()
	preview.set("level_scene_path", FullPath)
	root.add_child(preview)
	preview.call("resume_lab")
	await _ticks(12)
	preview.call("open_bench")
	await _settle()
	var actor: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var result: Dictionary = {}
	if _expect(is_instance_valid(actor) and is_instance_valid(level) and level.has_method("state"), "fresh seed uses actual MainScene hero and authored runtime"):
		var state: Dictionary = level.call("state")
		if _expect(state.get("configuration_error", "missing") == "" and state.get("entered", []).is_empty(), "fresh seed remains before every authored source entry: " + str(state)):
			var player_state: Dictionary = actor.snapshot_state()
			var level_state: Dictionary = level.snapshot_state()
			if _expect(not player_state.is_empty() and not level_state.is_empty() and level_state.local_snapshot_version == 5, "real paused initial snapshots provide the full version-5 unit: " + actor.last_snapshot_error + "; " + level.last_snapshot_error):
				# Only fresh shell metadata is fixture-declared. Subsequent input and
				# camera records come from the actual shell and routed gestures.
				var shell_state: Dictionary = {"api_revision": Shell.SHELL_API, "anchor_normalized": [0.5, 0.5], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(actor.global_position + Vector3.UP * 0.75), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}
				result = {"schema_version": 1, "level_id": "A3-L1", "scene_path": FullPath, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": player_state, "level": level_state, "shell": shell_state}
	preview.free()
	paused = false
	await _settle()
	return result


func _assert_checkpoint(checkpoint: Dictionary) -> bool:
	if not _expect(_checkpoint_events.size() == 1 and _checkpoint_events[0].checkpoint_id == FirstCheckpoint and _checkpoint_events[0].boundary == "encounter" and _checkpoint_events[0].paused, "one actual spatial entry requests its authored checkpoint at the shell's paused barrier"):
		return false
	if not _expect(not checkpoint.is_empty() and checkpoint.player.resources.hp == CheckpointHP and checkpoint.player.resources.shells == 0 and checkpoint.level.progress.checkpoint_id == FirstCheckpoint, "actual checkpoint records depleted HP/zero ammo and the real entry without healing"):
		return false
	var local: Dictionary = checkpoint.level.local
	if not _expect(checkpoint.level.local_snapshot_version == 5 and local.api_revision == "act3-twin-suns-level-1" and local.schema_version == 1 and _keys_match(local.sources, SourceIDs), "checkpoint contains version-5 route/scenery/scheduler and all five stable real actors"):
		return false
	if not _expect(local.route.entries.size() == 1 and local.route.entries[0].id == FirstPocket and local.route.deaths.is_empty() and local.route.exit_state == "clear" and not checkpoint.level.progress.completed, "entry history distinguishes the entered pocket from five living sources and unavailable contact exit"):
		return false
	for id: String in SourceIDs:
		var source: Dictionary = local.sources[id]
		if not _expect(source.stable_id == id and not source.dead and source.hp == source.max_hp and source.phase == "idle" and source.reservation_id == "" and int(source.cycle) == 0 and float(source.clock_s) == float(local.scheduler.clock_s), "checkpoint binds living source before its first enabled warning: " + id):
			return false
	var observed: Dictionary = checkpoint.shell.last_input_observation
	if not _expect(not observed.is_empty() and observed.kind == "swipe_release" and _same_exact(observed.anchor_normalized, checkpoint.shell.anchor_normalized) and float(checkpoint.player.world_actions.clock_s) == float(_checkpoint_events[0].hero_clock_s) and _same_exact(checkpoint.player.motion.position, Codec.vector3(_checkpoint_events[0].hero_position)), "one entry barrier captures actual dash pose/clock and final routed release anchor together"):
		return false
	return _expect(float(checkpoint.player.clocks.reload_s) > 0.0 and not checkpoint.player.world_actions.pending_dash.is_empty(), "checkpoint retains natural fractional reload and the real in-flight crossing dash, with no private clock staging")


func _assert_disk_checkpoint(checkpoint: Dictionary) -> bool:
	var path: String = _test_root + "campaign.json"
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not _expect(envelope is Dictionary and envelope.get("format_version") == 2 and envelope.get("generation", 0) >= 1 and envelope.get("payload_json") is String and envelope.get("sha256") is String, "production shell writes an actual format-2 SaveStore generation to isolated disk"):
		return false
	if not _expect(envelope.payload_json.sha256_text() == envelope.sha256, "actual disk envelope checksum covers its exact payload"):
		return false
	var decoded: Dictionary = ExactJson.parse(envelope.payload_json)
	if not _expect(decoded.accepted and decoded.value is Dictionary, "actual disk generation contains the published exact-json-1 transport"):
		return false
	var reader = Store.new(path)
	var stored: Dictionary = reader.read_payload()
	if not _expect(not stored.is_empty() and not reader.loaded_backup and reader.last_error.is_empty(), "a separate public SaveStore reopens the actual primary generation: " + reader.last_error):
		return false
	if not _expect_exact(stored, decoded.value, "public store and exact disk envelope decode to identical native types and finite scalar bits"):
		return false
	return _expect_exact(stored.story.checkpoint, checkpoint, "real format-2 save preserves exact player/five-source/scheduler/sun/route/input/camera checkpoint")


func _assert_rejections(checkpoint: Dictionary) -> bool:
	var manufactured: Dictionary = checkpoint.duplicate(true)
	manufactured.level.progress.completed = true
	manufactured.level.progress.completion_id = "twin-suns-clear"
	if not _reject_unit(manufactured, "manufactured completion with all five sources alive"):
		return false
	var missing_entry: Dictionary = checkpoint.duplicate(true)
	missing_entry.level.local.route.entries.clear()
	if not _reject_unit(missing_entry, "omitted entered pocket inconsistent with checkpoint/presentation"):
		return false
	var omitted_source: Dictionary = checkpoint.duplicate(true)
	omitted_source.level.local.sources.erase(SourceIDs[-1])
	return _reject_unit(omitted_source, "omitted actual source breaks the complete five-source unit")


func _reject_unit(forged: Dictionary, note: String) -> bool:
	var before: Dictionary = _game.capture_campaign_snapshot()
	var session: Dictionary = _game.attempts.state()
	var disk: String = FileAccess.get_file_as_string(_test_root + "campaign.json")
	var candidate: Dictionary = session.duplicate(true)
	candidate.story.snapshot = forged.duplicate(true)
	var candidate_before: Dictionary = candidate.duplicate(true)
	var error: String = _game.attempts.state_error(candidate)
	if not _expect(not error.is_empty(), "public whole-session prevalidation rejects " + note + ": " + error):
		return false
	if not _expect(not _game.attempts.restore_session(candidate) and not _game.attempts.last_error.is_empty(), "public restore_session rejects malformed copied unit before commit: " + note):
		return false
	return _expect(_same_exact(candidate, candidate_before) and _same_exact(_game.attempts.state(), session) and _same_exact(_game.capture_campaign_snapshot(), before) and FileAccess.get_file_as_string(_test_root + "campaign.json") == disk, "rejected copied unit leaves actual memory/world/disk unchanged: " + note)


func _assert_restored_live_unit(checkpoint: Dictionary) -> bool:
	var level: CinderLevel = _game.active_level
	if not _expect(_source_bindings_valid(), "fresh retry retains five actual bodies under the authored level and their common scheduler"):
		return false
	var live_sources: Dictionary = level.get("sources")
	for id: String in SourceIDs:
		if not _expect_exact(live_sources[id].snapshot_state(), checkpoint.level.local.sources[id], "fresh actual source matches exact saved state: " + id):
			return false
	var scheduler = level.get("threat_scheduler")
	if not _expect_exact(scheduler.snapshot_state(level.call("scheduler_bindings")), checkpoint.level.local.scheduler, "fresh actual scheduler matches every saved scalar/binding/history"):
		return false
	var motifs: Node3D = level.find_child("ScenicSuns", true, false) as Node3D
	return _expect(is_instance_valid(motifs) and motifs.global_position.x == _game.player.global_position.x and motifs.global_position.z == _game.player.global_position.z and _game.camera.global_position == Codec.read_vector3(checkpoint.shell.camera_focus) + Shell.CAMERA_OFFSET and _game.player.hp == CheckpointHP and _game.player.shells == 0, "paused fresh retry aligns actual scenic suns and physical camera to the restored hero/focus without a physics tick or resource reset")


func _source_bindings_valid() -> bool:
	var level: CinderLevel = _game.active_level
	var sources: Variant = level.get("sources")
	var scheduler: Node = level.get("threat_scheduler") as Node
	if not sources is Dictionary or not _keys_match(sources, SourceIDs) or not is_instance_valid(scheduler) or not level.is_ancestor_of(scheduler):
		return false
	for id: String in SourceIDs:
		var source: Node = sources[id] as Node
		if not is_instance_valid(source) or not source is CharacterBody3D or not level.is_ancestor_of(source) or source.call("state").get("stable_id") != id:
			return false
	var bindings: Dictionary = level.call("scheduler_bindings")
	if bindings.get("world_root") != level or not bindings.get("owners") is Dictionary or not _keys_match(bindings.owners, SourceIDs):
		return false
	for id: String in SourceIDs:
		if bindings.owners[id] != sources[id]:
			return false
	return true


func _observe_restore_node(node: Node) -> void:
	if not _watching_restore:
		return
	if node is CinderPlayer:
		var actor: CinderPlayer = node as CinderPlayer
		actor.fired.connect(func(_kind: String) -> void: _restore_events.append("player.fired"))
		actor.died.connect(func() -> void: _restore_events.append("player.died"))
		actor.equipment_changed.connect(func(_id: String) -> void: _restore_events.append("player.equipment_changed"))
		actor.action_resolved.connect(func(_kind: String, _hits: int, _damage: float) -> void: _restore_events.append("player.action_resolved"))
		actor.world_action_executed.connect(func(_record: Dictionary) -> void: _restore_events.append("player.world_action_executed"))
	if node is CinderLevel:
		var level: CinderLevel = node as CinderLevel
		level.checkpoint_requested.connect(func(id: String, checkpoint: String, boundary: String) -> void:
			_restore_events.append("level.checkpoint_requested")
			_checkpoint_events.append({"level_id": id, "checkpoint_id": checkpoint, "boundary": boundary, "paused": paused, "restored_candidate": true}))
		level.completion_requested.connect(func(_id: String, _completion: String) -> void: _restore_events.append("level.completion_requested"))
		level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _restore_events.append("level.contact_exit_requested"))
	if node.get_script() == Stalker:
		node.connect("died", func(_where: Vector3) -> void: _restore_events.append("source.died"))
		node.connect("hit_resolved", func(_result: Dictionary) -> void: _restore_events.append("source.hit_resolved"))


func _resume_button_consumed(note: String) -> bool:
	if not _expect(paused and _game.menu.is_open(), note + ": actual resume overlay is paused and open"):
		return false
	var button: Control = _game.menu.find_child("ResumeButton", true, false) as Control
	if not _expect(is_instance_valid(button) and button.is_visible_in_tree(), note + ": actual ResumeButton is available"):
		return false
	var history: Array[Dictionary] = _game.player.get_world_action_records()
	var observer: Dictionary = _game.get_input_observation_state()
	var clock: float = _game.player.get_world_action_clock()
	var hp: float = _game.player.hp
	var shells: int = _game.player.shells
	var position: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	root.push_input(motion, true)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = position
	down.global_position = position
	down.pressed = true
	root.push_input(down, true)
	var down_handled: bool = root.is_input_handled()
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	root.push_input(up, true)
	# No await/physics tick intervenes: a saved pending dash may legitimately
	# finish after resume, but the menu event itself must publish no action.
	return _expect(down_handled and root.is_input_handled() and not paused and not _game.menu.is_open() and _same_exact(_game.get_input_observation_state(), observer) and _same_exact(_game.player.get_world_action_records(), history) and _game.player.get_world_action_clock() == clock and _game.player.hp == hp and _game.player.shells == shells, note + ": routed ResumeButton press/release is consumed without an attack, new dash, observer change or refill")


func _swipe(start_normalized: Vector2, release_normalized: Vector2, checkpoint_expected: bool) -> bool:
	var actor: CinderPlayer = _game.player
	var before: Array[Dictionary] = actor.get_world_action_records()
	var sequence: int = 0 if before.is_empty() else int(before.back().sequence)
	var size: Vector2 = root.get_visible_rect().size
	var start: Vector2 = size * start_normalized
	var finish: Vector2 = size * release_normalized
	var expected_anchor: Vector2 = finish / size
	var down := InputEventScreenTouch.new()
	down.index = 7
	down.position = start
	down.pressed = true
	root.push_input(down, true)
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.index = 7
	drag.position = finish
	drag.relative = finish - start
	root.push_input(drag, true)
	await process_frame
	var up := InputEventScreenTouch.new()
	up.index = 7
	up.position = finish
	up.pressed = false
	root.push_input(up, true)
	await process_frame
	if not await _wait_clock(actor, float(actor.equipment.resolved_stats().dash_cooldown) + 0.04, checkpoint_expected):
		return false
	var records: Array[Dictionary] = actor.get_world_action_records(sequence)
	var observation: Dictionary = _game.get_input_observation_state()
	print("AUTHORED SWIPE actual routed input: ", {"root_rect": root.get_visible_rect(), "start": start, "finish": finish, "anchor": _game.get_aim_anchor_normalized(), "position": actor.global_position, "clock_s": actor.get_world_action_clock(), "checkpoints": _checkpoint_events, "records": records})
	return _expect(_game.get_aim_anchor_normalized() == expected_anchor and observation.last_observation.get("kind") == "swipe_release" and records.size() == 1 and records[0].kind == "dash" and not records[0].get("blocked", true) and not records[0].get("collision_shortened", true), "routed touch release supplies exact public anchor and one actual unobstructed completed dash")


func _wait_checkpoint() -> bool:
	for _frame: int in range(120):
		var state: Dictionary = _game.attempts.state()
		if state.get("story") is Dictionary and state.story.checkpoint.level.progress.get("checkpoint_id") == FirstCheckpoint:
			return _expect(_game.campaign_error.is_empty(), "actual spatial checkpoint deferred save commits: " + _game.campaign_error)
		if not _game.campaign_error.is_empty():
			return _expect(false, "first checkpoint operation failed: " + _game.campaign_error)
		await process_frame
	return _expect(false, "actual first checkpoint did not commit within 120 process frames")


func _wait_clock(actor: CinderPlayer, duration: float, checkpoint_expected: bool) -> bool:
	var deadline: float = actor.get_world_action_clock() + duration
	for _tick: int in range(int(ceilf(duration * Engine.physics_ticks_per_second)) + 120):
		if not is_instance_valid(actor) or actor.dead:
			return _expect(false, "actual hero retired or died before bounded clock wait")
		if actor.get_world_action_clock() >= deadline:
			return true
		if paused and not checkpoint_expected:
			return _expect(false, "unexpected pause during actual route/clock wait: " + _game.campaign_error)
		if is_instance_valid(_game) and not _game.campaign_error.is_empty():
			return _expect(false, "deferred shell operation failed during route: " + _game.campaign_error)
		await _ticks(1)
	return _expect(false, "actual hero clock did not advance within the bounded route wait")


func _level_state() -> Dictionary:
	return _game.active_level.call("state") if is_instance_valid(_game) and is_instance_valid(_game.active_level) and _game.active_level.has_method("state") else {}


func _no_progress_awarded(prefix: Array[String]) -> bool:
	var state: Dictionary = _game.attempts.state()
	var level: Dictionary = _level_state()
	return state.completed_main == prefix and state.completed_optional.is_empty() and state.reward_ids.is_empty() and state.side_attempt == null and not _game.active_level.is_completed() and level.get("cleared", []).is_empty() and level.get("exit_state") == "clear"


func _keys_match(value: Dictionary, expected: Array[String]) -> bool:
	if value.size() != expected.size():
		return false
	for key: String in expected:
		if not value.has(key):
			return false
	return true


func _same_exact(left: Variant, right: Variant) -> bool:
	return _difference(left, right).is_empty()


func _difference(left: Variant, right: Variant, path: String = "$") -> String:
	if typeof(left) != typeof(right):
		return path + ": native type differs (%s / %s)" % [type_string(typeof(left)), type_string(typeof(right))]
	if left is Dictionary:
		if left.size() != right.size():
			return path + ": dictionary size differs"
		for key: Variant in left:
			if not right.has(key):
				return path + "." + str(key) + ": missing key"
			var difference: String = _difference(left[key], right[key], path + "." + str(key))
			if not difference.is_empty():
				return difference
		return ""
	if left is Array:
		if left.size() != right.size():
			return path + ": array size differs"
		for index: int in range(left.size()):
			var difference: String = _difference(left[index], right[index], path + "[%d]" % index)
			if not difference.is_empty():
				return difference
		return ""
	if left is float:
		var a := PackedByteArray()
		var b := PackedByteArray()
		a.resize(8)
		b.resize(8)
		a.encode_double(0, left)
		b.encode_double(0, right)
		return "" if a == b else path + ": finite binary64 bits differ (%s / %s)" % [str(left), str(right)]
	return "" if left == right else path + ": value differs (%s / %s)" % [str(left), str(right)]


func _expect_exact(actual: Variant, expected: Variant, note: String) -> bool:
	var difference: String = _difference(actual, expected)
	return _expect(difference.is_empty(), note + ("; first difference " + difference if not difference.is_empty() else ""))


func _expect(ok: bool, note: String) -> bool:
	_checks += 1
	if ok:
		print("PASS: TEST ONLY authored shell: " + note)
	else:
		_failures += 1
		push_error("FAIL: TEST ONLY authored shell: " + note)
		if _failures == 1:
			print("FIRST FAILURE PUBLIC DIAGNOSTIC: ", {"paused": paused, "campaign_error": _game.campaign_error if is_instance_valid(_game) else "no shell", "level": _level_state(), "player": _game.player.get_threat_response_state() if is_instance_valid(_game) and is_instance_valid(_game.player) else {}, "checkpoint_events": _checkpoint_events})
	return ok


func _ticks(count: int) -> void:
	for _tick: int in range(count):
		await physics_frame
		await process_frame


func _settle() -> void:
	for _frame: int in range(6):
		await process_frame


func _count_levels(node: Node) -> int:
	var count: int = 1 if node is CinderLevel else 0
	for child: Node in node.get_children():
		count += _count_levels(child)
	return count


func _count_actors(node: Node) -> int:
	var count: int = 1 if node is CinderPlayer or node.get_script() == Stalker else 0
	for child: Node in node.get_children():
		count += _count_actors(child)
	return count


func _close_case() -> void:
	_watching_restore = false
	if node_added.is_connected(_observe_restore_node):
		node_added.disconnect(_observe_restore_node)
	if is_instance_valid(_game):
		_game.free()
	_game = null
	paused = false
	await _settle()
	await create_timer(0.25, true).timeout
	_expect(_count_levels(root) == 0 and _count_actors(root) == 0 and get_nodes_in_group("enemies").is_empty(), "bounded cleanup frees every authored/prepared world and actor group, with retired audio drained")
	_cleanup_owned_path(_test_root)


func _cleanup_owned_path(path: String) -> void:
	if _test_root.is_empty() or path.is_empty() or not path.begins_with(_test_root):
		return
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
		return
	for directory: String in DirAccess.get_directories_at(path):
		_cleanup_owned_path(path.path_join(directory))
	for filename: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path.path_join(filename)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
