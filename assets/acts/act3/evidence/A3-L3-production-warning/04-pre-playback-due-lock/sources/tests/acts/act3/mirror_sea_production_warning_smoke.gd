extends "res://tests/acts/act3/mirror_sea_frontier_smoke.gd"
## TEST ONLY production warning/Continue consumer candidate.
## Actual clock0 seed, checked in-memory prefix12/scene metadata, native route,
## real unarmed Echo warning save, disk fresh Continue and one due commit.
## Ordinary-primary-only, unchanged actual resources; no literal zero-ammo,
## full route/exit/art/native-OS/canonical registration claim.

const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const ProductionShell = preload("res://scripts/campaign/shell.gd")
const ProductionRegistry = preload("res://scripts/campaign/registry.gd")
const ProductionStore = preload("res://scripts/campaign/save_store.gd")
const ProductionValue = preload("res://scripts/campaign/snapshot_codec.gd")

var _quiet_events: Array[String] = []
var _quiet_targets: Array[Object] = []
var _quiet_connections: Array[Dictionary] = []
var _restored_warning: Dictionary = {}
var _commit_observation_enabled: bool = false
var _last_lock: bool = false
var _commit_transitions: int = 0
var _commit_clock: float = -1.0
var _shell: CinderCampaignShell
var _raw_registry: Dictionary = {}
var _canonical_registry_bytes: String = ""
var _test_root: String = ""
var _protected_checkpoint: Dictionary = {}
var _watch_restore: bool = false
var _watched_restore_nodes: Dictionary = {}
var _bound_nodes: Dictionary = {}


func _run() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var arrival_only: bool = arguments.size() == 1 and arguments[0] == "--arrival-only"
	var reason: String = "" if arguments.is_empty() or arrival_only else "unsupported selector: " + str(arguments)
	if reason.is_empty(): reason = await _open()
	if _expect(reason.is_empty(), "checked prefix12/actual clock0 seed installs the native paused production A3-L3", reason):
		reason = _arrival_pair()
		if _expect(reason.is_empty(), "production arrival whole pair and atomic malformed controls preserve actual world/disk", reason) and not arrival_only:
			if not _resume_consumed("initial production arrival"): reason = "actual initial GUI Resume was not consumed"
			if reason.is_empty(): reason = await _travel_entry(0)
			if reason.is_empty(): reason = _first_source()
			if reason.is_empty(): reason = await _clear_stalker()
			if _expect(reason.is_empty(), "real ordinary routed primaries clear the production first Stalker", reason):
				reason = await _travel_entry(1)
				if reason.is_empty(): reason = _first_echo_ready()
				if reason.is_empty(): reason = await _unarmed_warning()
				if _expect(reason.is_empty(), "actual second entry earns its unarmed managed generation1 warning", reason):
					reason = await _warning_reconstruction()
					if _expect(reason.is_empty(), "disk fresh Continue installs the exact quiet warning with actual saved receiver optics", reason):
						reason = await _one_real_commit_and_terminal()
						if _expect(reason.is_empty(), "normal saved Shell follow earns one due commit/path/20-primary/contact-free terminal", reason):
							reason = await _checkpoint_retry()
							_expect(reason.is_empty(), "public Retry quietly installs the actual protected entry checkpoint exactly", reason)
	if not reason.is_empty():
		print("FIRST MEANINGFUL PRODUCTION WARNING FAILURE; later actions unattempted: ", reason, "; ", _diagnostic())
	await _dispose_host(_failures == 0)
	if node_added.is_connected(_watch_new_node): node_added.disconnect(_watch_new_node)
	_expect(_canonical_registry_bytes.is_empty() or FileAccess.get_file_as_string(ProductionRegistry.DATA_PATH) == _canonical_registry_bytes, "canonical registry bytes remain unchanged")
	_cleanup_owned_path(_test_root)
	print("TEST ONLY Mirror Sea production warning: %d checks; failures: %d. Checked prefix12; actual first2 entries, Save/disk Continue/Retry and generation1 only; ordinary-primary-only, no encounter blasts; no literal zero-ammo/full-route/exit/art/native-OS/canonical acceptance." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _open() -> String:
	# The unchanged public Main arrival creates the real source-free clock0
	# mechanical seed. No HP/ammo/pose/stat/action/clock is edited here.
	var error: String = await super._open()
	if not error.is_empty(): return error
	if float(_stats.primary_damage) != 20.0: return "actual starter primary must be20 for the requested36→16 frontier"
	var actual_pair: Dictionary = _pair()
	error = _pair_error(actual_pair)
	if not error.is_empty(): return "actual zero-tick seed: " + error
	if _hero.get_world_action_clock() != 0.0 or _scheduler.get_clock() != 0.0 or not actual_pair.level.local.sources.is_empty() or not _hero.get_world_action_records().is_empty():
		return "source-free actual seed advanced or contains earned history"
	var focus: Vector3 = (_game.get("camera") as Camera3D).global_position - Vector3(0,18,13)
	var seed: Dictionary = {"schema_version": 1, "level_id": "A3-L3", "scene_path": LEVEL_PATH, "paused": true, "equipment_ids": _kit.duplicate(true), "player": actual_pair.hero.duplicate(true), "level": actual_pair.level.duplicate(true), "shell": {"api_revision": ProductionShell.SHELL_API, "anchor_normalized": [0.5,0.5], "input_sequence": 0, "last_input_observation": {}, "camera_focus": ProductionValue.vector3(focus), "shake_left_s": 0.0, "difficulty_at_entry": actual_pair.level.local.world.profile_id}}
	# Explicit TEST ONLY metadata is not a production capture until the public
	# full Attempts/Shell validators below accept it. Later packets come only
	# from capture_campaign_snapshot; no manual shell/focus reconstruction.
	_canonical_registry_bytes = FileAccess.get_file_as_string(ProductionRegistry.DATA_PATH)
	var parsed: Variant = JSON.parse_string(_canonical_registry_bytes)
	if not parsed is Dictionary: return "canonical registry read failed"
	_raw_registry = parsed.duplicate(true)
	for info: Dictionary in _raw_registry.levels:
		if info.id == "A3-L3":
			info.scene_path = LEVEL_PATH
			info.readiness = "accepted" # TEST ONLY in-memory metadata.
			info.accepted_commit = "a".repeat(40)
			info.api_revision = ProductionRegistry.API_REVISION
	_test_root = "user://test-act3-mirror-warning-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	await _dispose_host(false)
	if not node_added.is_connected(_watch_new_node): node_added.connect(_watch_new_node)
	error = await _new_shell()
	if not error.is_empty(): return error
	var prefix: Array[String] = []
	prefix.assign(_shell.registry.main_route().slice(0,12))
	if prefix.size() != 12 or prefix[11] != "A3-L2" or not _shell.registry.scene_error("A3-L3").is_empty(): return "TEST ONLY prefix12/actual registered scene fails public identity"
	var session: Dictionary = _shell.attempts.state()
	session.completed_main = prefix.duplicate() # TEST ONLY predecessor metadata.
	session.story = {"kind": "story", "level_id": "A3-L3", "snapshot": seed.duplicate(true), "checkpoint": seed.duplicate(true)}
	error = _shell.attempts.state_error(session)
	if not error.is_empty() or not _shell.attempts.restore_session(session): return "public complete seed validation refused: " + error + "; " + _shell.attempts.last_error
	_shell.menu.continue_story_requested.emit()
	error = await _settle_shell("resume")
	if error.is_empty(): error = _bind_runtime()
	if not error.is_empty(): return error
	var captured: Dictionary = _shell.capture_campaign_snapshot()
	if captured.is_empty() or not _exact(captured, seed): return "public initial Continue differs from the independently validated actual clock0 seed: " + _shell.campaign_error
	# restore_session and Continue install in-memory state; neither promises a
	# disk generation. The actual public paused operation records this real
	# clock0 live unit through Shell/Attempts/SaveStore before any route input.
	_shell.request_pause()
	error = await _settle_shell("pause")
	if not error.is_empty(): return error
	if not _exact(_shell.capture_campaign_snapshot(), seed): return "actual clock0 production pause changed the seed before persistence"
	return _disk_error(_shell.attempts.state())


func _new_shell() -> String:
	_shell = ProductionShell.new()
	_game = _shell
	if not _shell.configure_runtime(_raw_registry, _test_root + "campaign.json", _test_root + "settings.json", _test_root + "preferences.json"):
		return "public Shell fixture configuration refused: " + _shell.campaign_error
	root.add_child(_shell)
	for _i: int in range(4): await process_frame
	return "" if paused and _shell.campaign_error.is_empty() and _shell.menu != null and _shell.menu.page_name() == "title" else "fresh production Shell title/load refused: " + _shell.campaign_error


func _settle_shell(page: String) -> String:
	# Public lifecycle settling only. Paused actors do not advance; no missing
	# checkpoint, resume or camera operation is injected by this observation.
	for _i: int in range(32):
		await process_frame
		if not _shell.campaign_error.is_empty(): return _shell.campaign_error
		if paused and not _shell.is_pause_requested() and _shell.menu.page_name() == page and is_instance_valid(_shell.active_level): return ""
	return "public deferred Shell operation did not settle to actual paused " + page


func _bind_runtime() -> String:
	_hero = _shell.player
	_level = _shell.active_level
	_game = _shell
	if not is_instance_valid(_hero) or not is_instance_valid(_level) or _level.scene_file_path != LEVEL_PATH or _level.get_script().resource_path != RUNTIME_PATH or _level.is_restore_candidate():
		return "production actual parent/Hero/lifecycle binding differs: " + _shell.campaign_error
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	if _scheduler == null or _hero.presentation_id != "act3_traveller" or not _exact(_kit, _hero.equipment.snapshot()) or not _exact(_stats, _hero.equipment.resolved_stats()) or _hero.hp != _hero_hp or _hero.shells != _shells:
		return "quiet production recipient changed real presentation/kit/resources"
	var actual: Dictionary = _level.get("sources")
	_stalker = actual.get(STALKER_ID) as CharacterBody3D
	_echo = actual.get(ECHO_ID) as Node3D
	_barrier = PostActorBarrier.new()
	_barrier.name = "TestOnlyMirrorSeaProductionPostConsumerBarrier"
	_shell.add_child(_barrier)
	if not _bound_nodes.has(_hero.get_instance_id()):
		_bound_nodes[_hero.get_instance_id()] = true
		_hero.world_action_executed.connect(_on_action)
		_hero.fired.connect(func(kind: String) -> void: _event("fired_" + kind))
		_hero.died.connect(func() -> void: _event("hero_death"))
		_hero.equipment_changed.connect(func(_id: String) -> void: _event("equipment"))
	if not _bound_nodes.has(_level.get_instance_id()):
		_bound_nodes[_level.get_instance_id()] = true
		_level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: _event("checkpoint"))
		_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _event("completion"))
		_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _event("exit"))
	if is_instance_valid(_echo):
		_echo_identity = {"instance_id": _echo.get_instance_id(), "transform": _echo.global_transform, "definition": _echo.call("source_definition"), "profile": _echo.call("source_profile"), "world": _echo.call("prepared_world"), "epoch": (_echo.call("get_source_state") as Dictionary).source_epoch, "initial_program": _echo.call("get_authored_cycle_program"), "initial_playback_id": (_echo.call("state") as Dictionary).playback_id}
		_echo.connect("source_hit_resolved", func(_result: Dictionary) -> void: _event("echo_hit"))
		_echo.connect("died", func() -> void: _event("echo_death"))
		_echo.connect("event_dispatched", func(_event_data: Dictionary, receipt: Dictionary) -> void:
			_event("echo_dispatch")
			if receipt.get("contact", false): _event("echo_contact")
		)
	_observe_quiet_bindings()
	return _host_bindings_error()


func _warning_reconstruction() -> String:
	if not _shell.request_pause_deferred(): return "actual Shell refused the public complete-tick pause request"
	var error: String = await _settle_shell("pause")
	if not error.is_empty(): return error
	var packet: Dictionary = _shell.capture_campaign_snapshot()
	if packet.is_empty(): return "whole native campaign warning unavailable: " + _shell.campaign_error
	var pair: Dictionary = {"hero": packet.player, "level": packet.level}
	error = _pair_error(pair)
	if not error.is_empty(): return error
	var saved: Dictionary = pair.level.local.sources[ECHO_ID]
	var record: Dictionary = _scheduler.replay_reservation_state(String(saved.playback.reservation_id))
	if saved.playback.status != "running" or saved.actor.generation != 1 or saved.playback.cursor.armed or record.is_empty() or record.adapter.locked or pair.level.local.scheduler.clock_s >= float(record.lock_from_s) or not saved.actor.lifecycle.terminal_receipts.is_empty(): return "actual durable capture crossed the unarmed native warning"
	var session: Dictionary = _shell.attempts.state()
	_protected_checkpoint = session.story.checkpoint.duplicate(true)
	if not _exact(session.story.snapshot, packet): return "saved active warning differs from actual current campaign packet"
	if _protected_checkpoint.is_empty(): return "actual protected checkpoint is empty"
	# Public CinderLevel progress records a closed ID->boundary-kind map.
	# Compare the exact two earned IDs/kinds, rather than an unlike ID array.
	var canonical_ids: Array[String] = _level.call("mirror_sea_codec_checkpoint_ids")
	if canonical_ids.size() != 6: return "canonical checkpoint catalogue changed"
	var expected_ids: Dictionary = {}
	for id: String in canonical_ids.slice(0,2): expected_ids[id] = "encounter"
	var progress: Dictionary = _protected_checkpoint.level.progress
	if not _exact(progress.checkpoint_ids, expected_ids) or progress.checkpoint_id != canonical_ids[1] or progress.checkpoint_kind != "encounter" or _protected_checkpoint.level.local.route.entries.size() != 2:
		return "protected second-entry checkpoint differs: " + str({"actual_ids": progress.checkpoint_ids, "expected_ids": expected_ids, "current_id": progress.checkpoint_id, "kind": progress.checkpoint_kind, "entries": _protected_checkpoint.level.local.route.entries.size()})
	_restored_warning = {"pair": pair.duplicate(true), "campaign": packet.duplicate(true), "lease": record.duplicate(true), "serial": pair.level.local.scheduler.serial, "program": _echo.call("get_authored_cycle_program"), "playback_id": saved.playback.playback_id, "camera": _camera_packet()}
	for label: String in ["source_clock", "scheduler_clock", "framing", "unknown"]:
		var bad: Dictionary = pair.duplicate(true)
		match label:
			"source_clock": bad.level.local.sources[ECHO_ID].actor.clock_s -= 0.00000001
			"scheduler_clock": bad.level.local.scheduler.clock_s -= 0.00000001
			"framing": bad.level.local.view.echoes[ECHO_ID][0][0] = 100.0
			"unknown": bad.level.local["foreign"] = true
		error = _atomic_rejection(bad, pair, "warning " + label)
		if not error.is_empty(): return error
	error = _disk_error(session)
	if not error.is_empty(): return error
	var wire: String = ExactJson.stringify(packet)
	var read: Dictionary = ExactJson.parse(wire)
	if wire.is_empty() or not read.get("accepted", false) or not String(read.get("error", "")).is_empty() or not _exact(packet, read.get("value")): return "complete native campaign transport lost exact values/bits"
	var old_ids: Dictionary = {"hero": _hero.get_instance_id(), "level": _level.get_instance_id(), "scheduler": _scheduler.get_instance_id(), "echo": _echo.get_instance_id(), "stalker": _stalker.get_instance_id()}
	var events: Dictionary = _events.duplicate(true)
	var actions: Array[Dictionary] = _actions.duplicate(true)
	# Dispose only the actual held donor while inside its real native world.
	# Public parent retirement seals that donor's true cancellation; its saved
	# warning is not rewritten or pretended to have expired.
	await _dispose_host(false)
	_quiet_events.clear()
	_watch_restore = true
	error = await _new_shell()
	if error.is_empty():
		_shell.menu.continue_story_requested.emit()
		error = await _settle_shell("resume")
	_watch_restore = false
	if not error.is_empty(): return error
	if not _quiet_events.is_empty() or not _exact(events, _events) or not _exact(actions, _actions): return "production fresh construction/quiet Continue emitted gameplay/prefix/action observers: " + str(_quiet_events)
	error = _bind_runtime()
	if not error.is_empty(): return error
	var actual: Dictionary = _shell.capture_campaign_snapshot()
	if actual.is_empty() or not _exact(actual, packet) or not _exact(_camera_packet(), _restored_warning.camera): return "fresh public Continue changed complete Hero/local/input/focus/current native Camera: " + _shell.campaign_error
	if _hero.get_instance_id() == old_ids.hero or _level.get_instance_id() == old_ids.level or _scheduler.get_instance_id() == old_ids.scheduler or _echo.get_instance_id() == old_ids.echo or _stalker.get_instance_id() == old_ids.stalker: return "Continue reused a donor native recipient instead of fresh construction"
	var playback: Dictionary = _echo.call("state")
	var lease: Dictionary = _scheduler.replay_reservation_state(String(playback.reservation_id))
	if (_level.call("state") as Dictionary).echo_records[ECHO_ID].locked or lease.is_empty() or lease.adapter.locked or playback.cursor.armed or playback.status != "running" or _echo.call("source_phase") != "warning" or not _exact(lease.id, record.id) or not _exact(_echo.call("get_authored_cycle_program"), _restored_warning.program): return "fresh native warning was armed/lost/re-authored during public Continue"
	var before: Dictionary = _native_observation()
	var flags: Array[String] = _quiet_events.duplicate()
	# Shell already certified its own real candidate Camera/HUD before public
	# installation. The installed receiver is now checked through the ordinary
	# complete current-view guard; no candidate-only call or camera copy is used.
	var view: Dictionary = _level.call("camera_framing_union", "", [], true, false)
	error = String(view.get("error", "Actual held native union unavailable"))
	if error.is_empty(): error = _shell.camera_framing_error(view.points)
	if not error.is_empty() or not _exact(before, _native_observation()) or not _exact(actual, _shell.capture_campaign_snapshot()) or not _exact(flags, _quiet_events): return "installed actual native Camera/HUD guard failed or mutated restored unit: " + error
	error = _disk_error(session)
	if not error.is_empty(): return error
	_commit_observation_enabled = true
	_last_lock = false
	_commit_transitions = 0
	_commit_clock = -1.0
	return "" if _resume_consumed("saved unarmed warning") else "saved warning GUI Resume leaked actual recognizer/actions"


func _checkpoint_retry() -> String:
	if _protected_checkpoint.is_empty(): return "actual protected second-entry checkpoint missing"
	_shell.request_pause()
	var error: String = await _settle_shell("pause")
	if not error.is_empty(): return error
	var terminal: Dictionary = _shell.capture_campaign_snapshot()
	if terminal.is_empty() or terminal.level.local.sources[ECHO_ID].actor.hp != 16.0 or terminal.level.local.sources[ECHO_ID].playback.status != "complete" or not _scheduler.reservations().is_empty(): return "postterminal production pause is not genuine surviving HP16/empty lease"
	var old_hero: int = _hero.get_instance_id()
	var old_level: int = _level.get_instance_id()
	var old_echo: int = _echo.get_instance_id()
	var events: Dictionary = _events.duplicate(true)
	var actions: Array[Dictionary] = _actions.duplicate(true)
	_detach_quiet_observers()
	_quiet_events.clear()
	_watch_restore = true
	_shell.request_retry()
	error = await _settle_shell("resume")
	_watch_restore = false
	if not error.is_empty(): return error
	if not _quiet_events.is_empty() or not _exact(events, _events) or not _exact(actions, _actions): return "real checkpoint Retry emitted gameplay/prefix/action observers: " + str(_quiet_events)
	if is_instance_valid(_barrier): _barrier.queue_free()
	error = _bind_runtime()
	if not error.is_empty(): return error
	var retried: Dictionary = _shell.capture_campaign_snapshot()
	if retried.is_empty() or not _exact(retried, _protected_checkpoint) or _hero.get_instance_id() == old_hero or _level.get_instance_id() == old_level or _echo.get_instance_id() == old_echo: return "actual protected Retry changed unit or reused native recipients: " + _shell.campaign_error
	if not _exact(retried.player.resources, _protected_checkpoint.player.resources) or not _exact(retried.player.clocks, _protected_checkpoint.player.clocks) or not _exact(retried.player.world_actions, _protected_checkpoint.player.world_actions): return "checkpoint resources/clocks/pending and completed actual actions were repaired rather than restored"
	return _disk_error(_shell.attempts.state())


func _pair() -> Dictionary:
	if not is_instance_valid(_shell): return {"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}
	var packet: Dictionary = _shell.capture_campaign_snapshot()
	return {"hero": packet.get("player", {}), "level": packet.get("level", {})}


func _disk_error(expected: Dictionary) -> String:
	var reader: CinderSaveStore = ProductionStore.new(_test_root + "campaign.json")
	var payload: Dictionary = reader.read_payload()
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(_test_root + "campaign.json"))
	if not reader.last_error.is_empty() or reader.loaded_backup or reader.generation < 1 or not envelope is Dictionary or envelope.get("format_version") != 2 or not envelope.get("payload_json") is String or envelope.payload_json.sha256_text() != envelope.get("sha256") or not _exact(payload, expected): return "independent exact production SaveStore primary differs: " + reader.last_error
	var wire: String = ExactJson.stringify(payload)
	var read: Dictionary = ExactJson.parse(wire)
	return "" if not wire.is_empty() and read.get("accepted", false) and String(read.get("error", "")).is_empty() and _exact(read.get("value"), expected) else "independent durable payload exact transport failed"


func _watch_new_node(node: Node) -> void:
	# Public construction observation catches action/hit/death/progression
	# emissions even before the production receiver is installed. Immutable
	# constructor cue/state setup is not mislabeled as quiet commit signals.
	if not _watch_restore or not is_instance_valid(_shell) or not _shell.is_ancestor_of(node) or _watched_restore_nodes.has(node.get_instance_id()): return
	_watched_restore_nodes[node.get_instance_id()] = true
	if node is CinderPlayer:
		node.world_action_executed.connect(func(_record: Dictionary) -> void: _quiet_events.append("restore_action"))
		node.fired.connect(func(_kind: String) -> void: _quiet_events.append("restore_fire"))
		node.died.connect(func() -> void: _quiet_events.append("restore_hero_death"))
		node.equipment_changed.connect(func(_id: String) -> void: _quiet_events.append("restore_equipment"))
	if node is CinderLevel:
		node.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: _quiet_events.append("restore_checkpoint"))
		node.completion_requested.connect(func(_id: String, _completion: String) -> void: _quiet_events.append("restore_completion"))
		node.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _quiet_events.append("restore_exit"))
	if node.has_signal("source_hit_resolved"):
		node.connect("source_hit_resolved", func(_result: Dictionary) -> void: _quiet_events.append("restore_source_hit"))
		node.connect("died", func() -> void: _quiet_events.append("restore_source_death"))
		node.connect("event_dispatched", func(_event_data: Dictionary, _receipt: Dictionary) -> void: _quiet_events.append("restore_source_dispatch"))


func _resume_consumed(label: String) -> bool:
	var button: Control = _shell.menu.find_child("ResumeButton", true, false) as Control
	if not paused or not _shell.menu.is_open() or button == null or not button.is_visible_in_tree(): return _expect(false, label + ": actual GUI Resume unavailable")
	var before: Dictionary = {"history": _hero.get_world_action_records(), "input": _shell.get_input_observation_state(), "clock": _hero.get_world_action_clock(), "hp": _hero.hp, "shells": _hero.shells}
	var at: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	root.push_input(motion, true)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = at
	down.global_position = at
	down.pressed = true
	root.push_input(down, true)
	var handled: bool = root.is_input_handled()
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	root.push_input(up, true)
	return _expect(handled and root.is_input_handled() and not paused and not _shell.menu.is_open() and _exact(_hero.get_world_action_records(), before.history) and _exact(_shell.get_input_observation_state(), before.input) and _hero.get_world_action_clock() == before.clock and _hero.hp == before.hp and _hero.shells == before.shells, label + ": actual GUI input is consumed without actions/resources")


func _settle_checkpoint_pause() -> String:
	if not paused: return ""
	var actor_clock: float = _hero.get_world_action_clock()
	var scheduler_clock: float = _scheduler.get_clock()
	for _i: int in range(16):
		await process_frame
		if not _shell.campaign_error.is_empty(): return _shell.campaign_error
		if not paused: return ""
		if _hero.get_world_action_clock() != actor_clock or _scheduler.get_clock() != scheduler_clock: return "paused production operation advanced real actor/Scheduler clocks"
	return "actual checkpoint operation did not auto-resume; no synthetic resume is injected"


func _dispose_host(require_released: bool) -> void:
	_commit_observation_enabled = false
	_watch_restore = false
	var refs: Array[WeakRef] = []
	for node: Node in [_hero, _stalker, _echo, _scheduler, _level, _barrier, _game]:
		if is_instance_valid(node): refs.append(weakref(node))
	if require_released and is_instance_valid(_scheduler): _expect(_scheduler.reservations().is_empty(), "successful native case already retired its real held lease")
	_detach_quiet_observers()
	if is_instance_valid(_level): _level.exit_level()
	if is_instance_valid(_barrier): _barrier.waiting = false
	if is_instance_valid(_game):
		if _game.get_parent() == root: root.remove_child(_game)
		_game.queue_free()
	paused = false
	for _i: int in range(5): await process_frame
	await create_timer(0.15,true,false,true).timeout
	var freed: bool = true
	for ref: WeakRef in refs: freed = freed and ref.get_ref() == null
	if not refs.is_empty(): _expect(freed and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "whole native host/Hero/owners retire inside their original world without group residue")
	_shell = null
	_game = null
	_hero = null
	_level = null
	_scheduler = null
	_barrier = null
	_stalker = null
	_echo = null
	_quiet_targets.clear()


func _cleanup_owned_path(path: String) -> void:
	if _test_root.is_empty() or not path.begins_with(_test_root) or not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)): return
	for directory: String in DirAccess.get_directories_at(path): _cleanup_owned_path(path.path_join(directory))
	for filename: String in DirAccess.get_files_at(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path.path_join(filename)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _arrival_pair() -> String:
	if not paused or _scheduler.get_clock() != 0.0 or _hero.get_world_action_clock() != 0.0:
		return "actual arrival advanced before complete native capture"
	var pair: Dictionary = _pair()
	var error: String = _pair_error(pair)
	if not error.is_empty(): return error
	if pair.level.local.api_revision != "act3-mirror-sea-snapshot-1" or pair.level.local.schema_version != 1 or not pair.level.local.sources.is_empty() or pair.level.local.ring.stage != "uninstalled" or not pair.level.local.ring.mechanism.is_empty() or not pair.level.local.route.entries.is_empty() or not pair.level.progress.checkpoint_ids.is_empty():
		return "arrival is a partial codec packet or contains future earned topology/history"
	for label: String in ["schema", "epoch", "clock", "future_source", "progress"]:
		var bad: Dictionary = pair.duplicate(true)
		match label:
			"schema": bad.level.local.schema_version = 0
			"epoch": bad.level.local.scheduler.encounter_id = ""
			"clock": bad.level.local.scheduler.clock_s = 0.00000001
			"future_source": bad.level.local.sources[ECHO_ID] = {"kind": "echo", "actor": {}, "playback": {}}
			"progress": bad.level.progress.checkpoint_id = "one-real-body-entry"
		error = _atomic_rejection(bad, pair, "arrival " + label)
		if not error.is_empty(): return error
	return ""


func _unarmed_warning() -> String:
	var deadline: float = _scheduler.get_clock() + WAIT_BUDGET_S
	for _i: int in range(_frames(WAIT_BUDGET_S)):
		var playback: Dictionary = _echo.call("state")
		if playback.status == "running":
			var record: Dictionary = _scheduler.replay_reservation_state(String(playback.reservation_id))
			return "" if not record.is_empty() and not record.adapter.locked and _echo.call("source_phase") == "warning" and _scheduler.get_clock() < float(record.lock_from_s) else "first actual admission was not observed before due lock"
		if playback.status != "cycle_ready": return "initial Echo left ready without a genuine running admission"
		if _scheduler.get_clock() >= deadline: break
		var error: String = await _tick()
		if not error.is_empty(): return error
		playback = _echo.call("state")
		if playback.status == "running": continue
		if _hero.get_threat_response_state().stable and float(_hero.get_threat_response_state().dash_cooldown_left_s) == 0.0 and _hero.global_position.z > 22.5:
			error = await _dash(Vector3.FORWARD, {}, "unleased native Echo approach")
			if not error.is_empty(): return error
	return "first native warning was not admitted within its bounded approach: " + _diagnostic()


func _one_real_commit_and_terminal() -> String:
	var before_records: Array[Dictionary] = _hero.get_world_action_records()
	var error: String = await _echo_lock()
	if not error.is_empty(): return error
	var state: Dictionary = _level.call("state")
	var data: Dictionary = state.echo_records[ECHO_ID]
	var playback: Dictionary = _echo.call("state")
	var lease: Dictionary = _scheduler.replay_reservation_state(String(playback.reservation_id))
	if _commit_transitions != 1 or lease.is_empty() or not lease.adapter.locked or not playback.cursor.armed or lease.id != _restored_warning.lease.id or playback.playback_id != _restored_warning.playback_id or _echo.call("get_authored_cycle_generation") != 1 or not _exact(_echo.call("get_authored_cycle_program"), _restored_warning.program) or not _exact(before_records, _hero.get_world_action_records()) or not playback.lifecycle.terminal_receipts.is_empty():
		return "resumed warning did not earn exactly one real commit on its original lease/program without actions/history"
	# Published commit_authored_replay preserves the original admission but
	# derives armed deadlines from its ACTUAL due commit tick. Warning and armed
	# deadlines are therefore not asserted equal across that genuine transition.
	# The complete locked pair below independently validates every native sum;
	# inherited held checks keep all armed deadlines exact for the later path.
	var lock_gap: float = float(lease.lock_from_s) - float(_restored_warning.lease.lock_from_s)
	if not _exact(lease.start_s, _restored_warning.lease.start_s) or lease.lock_from_s != _commit_clock or lock_gap < 0.0 or lock_gap > _tick_s() + TIME_EPSILON:
		return "original admission did not commit at its first available actual due tick"
	# Serial is read through a coherent native pause, never an invented public
	# property or a raw clock rewrite; resume still uses the actual held proof.
	if not _game.call("request_pause_deferred"): return "actual lock pause request refused"
	var pause_error: String = await _settle_shell("pause")
	if not pause_error.is_empty(): return pause_error
	var locked_pair: Dictionary = _pair()
	if not paused or locked_pair.level.is_empty() or locked_pair.level.local.scheduler.serial != _restored_warning.serial or locked_pair.level.local.scheduler.reservations.size() != 1 or not locked_pair.level.local.scheduler.reservations[0].adapter.locked or not _exact(before_records, _hero.get_world_action_records()):
		return "due commit allocated a second reservation/history or lock capture was not coherent"
	error = _pair_error(locked_pair)
	if not error.is_empty(): return "actual armed deadline/cursor/journal pair invalid: " + error
	if not _resume_consumed("actual due lock"): return "due-lock GUI Resume leaked actual input/action"
	_held_source = ECHO_ID
	_held_record = lease.duplicate(true)
	_observed_phases = {"warning": true, "lock": true}
	error = await _follow(data.proof, ECHO_ID)
	if not error.is_empty(): return error
	_held_source = ""
	_held_record = {}
	if not _observed_phases.has("active") or not _observed_phases.has("recovery") or _commit_transitions != 1 or _echo.get("dead") or float(_echo.get("hp")) != 36.0 - float(_stats.primary_damage) or _events.get("echo_hit", 0) != 1 or _events.get("echo_death", 0) != 0:
		return "one real restored proof/recovery primary did not preserve surviving HP/phase/commit custody"
	var deadline: float = _scheduler.get_clock() + WAIT_BUDGET_S
	for _i: int in range(_frames(WAIT_BUDGET_S)):
		if _echo.call("source_phase") == "complete" and _scheduler.reservations().is_empty():
			var terminal: Dictionary = _echo.call("get_authored_cycle_terminal_receipt")
			if terminal.is_empty() or terminal.exchange.id != _restored_warning.lease.id or terminal.generation != 1 or terminal.opportunities.size() != 1 or (_echo.call("state") as Dictionary).lifecycle.terminal_receipts.size() != 1 or _events.get("echo_dispatch", 0) != 1 or _events.get("echo_contact", 0) != 0 or _commit_transitions != 1:
				return "original resumed exchange did not seal exactly one genuine contact-free terminal"
			for opportunity: Dictionary in terminal.opportunities:
				if opportunity.contact or opportunity.damage_attempted: return "restored proof consumed contact hidden by dash immunity"
			_commit_observation_enabled = false
			return _entry_error(1)
		if _scheduler.get_clock() >= deadline: break
		error = await _tick()
		if not error.is_empty(): return error
	return "original restored exchange did not genuinely retire within its bounded terminal wait"


func _pair_error(pair: Dictionary) -> String:
	if not paused or pair.hero.is_empty() or pair.level.is_empty(): return "complete paused native pair unavailable: " + _hero.last_snapshot_error + "; " + _level.last_snapshot_error
	var error: String = _hero.snapshot_error(pair.hero)
	if error.is_empty(): error = _level.snapshot_error_with_player(pair.level, pair.hero)
	if not error.is_empty(): return error
	var before: Dictionary = _native_observation()
	var wire: String = ExactJson.stringify(pair)
	var read: Dictionary = ExactJson.parse(wire)
	if wire.is_empty() or not read.get("accepted", false) or not String(read.get("error", "")).is_empty() or not read.get("value") is Dictionary or not _exact(pair, read.value):
		return "published exact full-pair transport rejected or changed native type/binary64 bits: " + str(read.get("error", ""))
	error = _level.snapshot_error_with_player(read.value.level, read.value.hero)
	return "" if error.is_empty() and _exact(before, _native_observation()) else "decoded complete pair validation changed native state: " + error


func _atomic_rejection(bad: Dictionary, original: Dictionary, label: String) -> String:
	var before: Dictionary = _native_observation()
	var error: String = _level.snapshot_error_with_player(bad.level, bad.hero)
	if error.is_empty() or _level.restore_state(bad.level) or not _exact(before, _native_observation()) or not _exact(original, _pair()):
		return "forged " + label + " was accepted or changed actual whole unit/observers: " + error
	print("ATOMIC REJECT: ", label, "; ", error)
	return ""


func _entry_error(index: int) -> String:
	var state: Dictionary = _level.call("state")
	if state.route.entries.size() != index + 1: return "entry prefix differs from the actual two-court frontier"
	var error: String = _checkpoint_error(state)
	if not error.is_empty(): return error
	for ordinal: int in range(index + 1):
		var receipt: Dictionary = state.route.entries[ordinal]
		if receipt.id != ENTRY_IDS[ordinal] or receipt.beat != ordinal + 1 or float(receipt.clock_s) <= 0.0 or float(receipt.hero_position[2]) + float(receipt.capsule_radius) > ENTRY_Z[ordinal] or not _entry_observations.has(ordinal) or not _exact(receipt, _entry_observations[ordinal].receipt):
			return "entry receipt lacks its independently observed actual capsule/clock crossing"
	var expected: Array[String] = []
	expected.assign([STALKER_ID] if index == 0 else [STALKER_ID, ECHO_ID])
	var actual: Dictionary = _level.get("sources")
	if actual.size() != expected.size() or state.ring.installed or is_instance_valid(_level.get("mechanism")):
		return "future court/pulse installed before its real spatial entitlement"
	for id: String in state.sources:
		if bool(state.sources[id].installed) != expected.has(id) or actual.has(id) != expected.has(id): return "future/native source entitlement differs: " + id
	return "" if not state.completed and state.exit_state == "clear" and state.contact.is_empty() and _events.get("completion", 0) == 0 and _events.get("exit", 0) == 0 else "partial frontier granted completion/contact"


func _checkpoint_error(state: Dictionary) -> String:
	var entries: Array = state.route.entries
	var pending: Array = state.route.pending_checkpoint_boundaries
	var ids: Array = _level.call("mirror_sea_codec_checkpoint_ids")
	var acknowledged: int = entries.size() - pending.size()
	if acknowledged < 0 or ids.size() != 6 or not _exact(pending, entries.slice(acknowledged)) or _events.get("checkpoint", 0) != acknowledged:
		return "actual dispatched checkpoint count/pending suffix differs from its earned entry prefix"
	var checkpoint: Dictionary = _level.current_checkpoint()
	var latest: String = String(ids[acknowledged - 1]) if acknowledged > 0 else ""
	return "" if checkpoint.id == latest and checkpoint.kind == ("encounter" if acknowledged > 0 else "") else "actual current checkpoint differs from the acknowledged prefix"


func _tick() -> String:
	# Same post-consumer/input/HP/floor/source observer as the inherited frontier.
	# Only its old checkpoint==0/pending-only policy is replaced by the actual
	# codec's acknowledged-prefix contract; no simulation deadline is relaxed.
	var boundary_error: String = await _settle_checkpoint_pause()
	if not boundary_error.is_empty(): return boundary_error
	_barrier.waiting = true
	await _barrier.observed
	boundary_error = await _settle_checkpoint_pause()
	if not boundary_error.is_empty(): return boundary_error
	var error: String = String(_level.call("runtime_error"))
	if not error.is_empty(): return error
	if _hero.dead or _hero.hp != _hero_hp or _hero.shells != _shells or not _exact(_kit, _hero.equipment.snapshot()) or not _exact(_stats, _hero.equipment.resolved_stats()) or _events.get("fired_blast", 0) != 0 or _events.get("echo_contact", 0) != 0 or _events.get("equipment", 0) != 0 or _events.get("completion", 0) != 0 or _events.get("exit", 0) != 0:
		return "actual Hero HP/ammo/kit or ordinary-only/no-completion frontier invariant changed"
	if _scheduler.get_clock() > TOTAL_BUDGET_S: return "finite native90s frontier budget exceeded"
	var parent_state: Dictionary = _level.call("state")
	error = _checkpoint_error(parent_state)
	if not error.is_empty(): return error
	for index: int in range(parent_state.route.entries.size()):
		if _entry_observations.has(index): continue
		var receipt: Dictionary = parent_state.route.entries[index]
		var body: CollisionShape3D = _hero.get_node_or_null("BodyCollision") as CollisionShape3D
		if index > 1 or body == null or not body.shape is CapsuleShape3D or receipt.clock_s != _scheduler.get_clock() or receipt.hero_position != [_hero.global_position.x, _hero.global_position.y, _hero.global_position.z] or receipt.capsule_radius != (body.shape as CapsuleShape3D).radius or body.global_position.z + (body.shape as CapsuleShape3D).radius > ENTRY_Z[index]:
			return "entry did not bind exact actual Hero/capsule/current clock"
		_entry_observations[index] = {"receipt": receipt.duplicate(true), "hero": _hero.global_position}
		if index == 1:
			var source: Node3D = (_level.get("sources") as Dictionary).get(ECHO_ID) as Node3D
			if source == null: return "genuine second entry lacks actual native recipient"
			_initial_echo_ready = {"instance_id": source.get_instance_id(), "source": source.call("get_source_state"), "playback": source.call("state"), "admissions": parent_state.echo_records[ECHO_ID].admissions.duplicate(true), "terminal": source.call("get_authored_cycle_terminal_receipt"), "reservations": _scheduler.reservations()}
	if not _held_source.is_empty():
		var phase: String = String((_stalker.call("state") as Dictionary).phase) if _held_source == STALKER_ID else String(_echo.call("source_phase"))
		_observed_phases[phase] = true
		var record: Dictionary = _scheduler.reservation_state(String(_held_record.id)) if _held_source == STALKER_ID else _scheduler.replay_reservation_state(String(_held_record.id))
		if record.is_empty() or record.source_instance_id != _held_record.source_instance_id: return "held native exchange disappeared/changed before real primary"
		for key: String in FIXED_DEADLINES:
			if not _exact(record[key], _held_record[key]): return "held actual scalar deadline changed: " + key
		if _held_source == STALKER_ID:
			if (_stalker.call("state") as Dictionary).hit_consumed: return "physical contact consumed despite ordinary no-immunity witness"
			if not _exact(record.geometry, _held_record.geometry) or record.adapter.planned_endpoint != _held_record.adapter.planned_endpoint: return "actual lunge committed footprint/endpoint changed while held"
			if phase == "active": _active_travel = maxf(_active_travel, _stalker.global_position.distance_to(_held_record.adapter.start))
			if phase == "recovery" and (_stalker.global_position.distance_to(_held_record.adapter.planned_endpoint) > POINT_TOLERANCE or _stalker.velocity != Vector3.ZERO): return "real physical lunge failed stopped0.005WU recovery endpoint"
	if is_instance_valid(_echo) and (_echo.global_transform != _echo_identity.transform or not String(_echo.call("source_native_error")).is_empty()): return "actual fixed Echo source/native renderer custody changed"
	if _commit_observation_enabled:
		if not _scheduler.reservations().is_empty():
			# Observe the same complete ACTUAL held groups as the parent guard.
			# Do not include an unadmitted pending preview or move the camera to
			# make the result pass. Shared error also includes the actual Hero.
			var view: Dictionary = _level.call("camera_framing_union", "", [], true, false)
			if not String(view.get("error", "Actual native held union unavailable")).is_empty() or view.get("points", []).is_empty(): return "resumed actual held union is incomplete: " + str(view.get("error", ""))
			var view_error: String = String(_game.call("camera_framing_error", view.points))
			if not view_error.is_empty(): return "resumed actual Camera/HUD clips a held source/footprint/Hero/response: " + view_error
		var locked: bool = bool(parent_state.echo_records[ECHO_ID].locked)
		if locked and not _last_lock:
			_commit_transitions += 1
			_commit_clock = _scheduler.get_clock()
		if _last_lock and not locked: return "restored original commit flag reset before its genuine terminal"
		_last_lock = locked
		if _commit_transitions > 1: return "restored original warning committed more than once"
	return ""


func _observe_quiet_bindings() -> void:
	_detach_quiet_observers()
	_quiet_targets = [_hero, _level, _scheduler]
	_connect_quiet(_hero, "action_resolved", func(_kind: String, _hits: int, _damage: float) -> void: _quiet_events.append("hero_action"))
	_connect_quiet(_scheduler, "reservation_invalidated", func(_id: String, _reason: String) -> void: _quiet_events.append("scheduler_invalidation"))
	for source: Node in (_level.get("sources") as Dictionary).values():
		_quiet_targets.append(source)
		if source.has_signal("state_changed"):
			_connect_quiet(source, "state_changed", func(_state: Dictionary) -> void: _quiet_events.append("source_state"))
		if source.has_method("get_cues"):
			for cue: Node in source.call("get_cues"):
				_quiet_targets.append(cue)
				_connect_quiet(cue, "state_changed", func(_state: Dictionary) -> void: _quiet_events.append("source_cue"))
	var exit_cue: Node3D = _level.get("exit_cue") as Node3D
	if exit_cue != null:
		_quiet_targets.append(exit_cue)
		_connect_quiet(exit_cue, "state_changed", func(_state: Dictionary) -> void: _quiet_events.append("exit_cue"))
		for child: Node in exit_cue.get_children():
			_quiet_targets.append(child)
			if child.has_signal("visibility_changed"):
				_connect_quiet(child, "visibility_changed", func() -> void: _quiet_events.append("exit_child"))
			if child is MeshInstance3D and child.material_override != null:
				_quiet_targets.append(child.material_override)
				_connect_quiet(child.material_override, "changed", func() -> void: _quiet_events.append("exit_material"))


func _connect_quiet(target: Object, signal_name: String, observer: Callable) -> void:
	target.connect(signal_name, observer)
	_quiet_connections.append({"target": target, "signal": signal_name, "observer": observer})


func _detach_quiet_observers() -> void:
	# Detach only this fixture's explicitly retained callbacks, never native
	# actor/level/cue observers. Donor retirement is real cleanup, not the quiet
	# receiver's restoration. Public node_added observes new gameplay signals.
	for connection: Dictionary in _quiet_connections:
		var target: Object = connection.target
		if is_instance_valid(target) and target.is_connected(connection.signal, connection.observer):
			target.disconnect(connection.signal, connection.observer)
	_quiet_connections.clear()
	_quiet_targets.clear()



func _quiet_signal_flags() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for target: Object in _quiet_targets:
		result.append({"instance_id": target.get_instance_id(), "blocked": target.is_blocking_signals()} if is_instance_valid(target) else {"missing": true})
	return result


func _camera_packet() -> Dictionary:
	var camera: Camera3D = _game.get("camera") as Camera3D
	return {"transform": camera.global_transform, "projection": camera.projection, "keep_aspect": camera.keep_aspect, "size": camera.size, "near": camera.near, "far": camera.far, "h_offset": camera.h_offset, "v_offset": camera.v_offset}


func _host_bindings_error() -> String:
	var world: Node3D = _game.get("world") as Node3D
	var camera: Camera3D = _game.get("camera") as Camera3D
	if _game.get("active_level") != _level or _game.get("player") != _hero or _level.hero != _hero or _level.shared_shell != _game or _level.effects != _game.get("fx") or _level.get_parent() != world or _hero.get_parent() != world or camera.get_parent() != world or _level.get_viewport() != camera.get_viewport() or _level.get_world_3d() != camera.get_world_3d() or camera.get_viewport().get_camera_3d() != camera:
		return "test host does not retain the actual candidate/Player/effects/current Camera in one real World"
	return ""


func _native_observation() -> Dictionary:
	return {"hero": _hero.snapshot_state(), "level": _level.call("state"), "scheduler": _scheduler.snapshot_state(_level.call("scheduler_bindings")), "events": _events.duplicate(true), "actions": _actions.duplicate(true), "quiet_events": _quiet_events.duplicate(), "attempts": _shell.attempts.state() if is_instance_valid(_shell) else {}, "disk": FileAccess.get_file_as_string(_test_root + "campaign.json") if not _test_root.is_empty() else "", "camera": _camera_packet(), "tree": _node_stamp(_level), "actor": _node_stamp(_hero)}


func _diagnostic() -> String:
	if not is_instance_valid(_level): return "actual parent unavailable"
	var error: String = String(_level.call("runtime_error"))
	if not error.is_empty():
		return str({"configuration_error": error, "scene": _level.scene_file_path, "clock_s": _scheduler.get_clock() if is_instance_valid(_scheduler) else -1.0, "hero_position": _hero.global_position if is_instance_valid(_hero) else null, "quiet_events": _quiet_events})
	return super._diagnostic()


func _node_stamp(node: Node) -> Dictionary:
	var result: Dictionary = {"instance_id": node.get_instance_id(), "name": String(node.name), "signals_blocked": node.is_blocking_signals(), "children": []}
	if node is Node3D:
		result["transform"] = node.transform
		result["visible"] = node.visible
	if node is CollisionObject3D:
		result["layer"] = node.collision_layer
		result["mask"] = node.collision_mask
	if node is CollisionShape3D:
		var collision: CollisionShape3D = node as CollisionShape3D
		result["disabled"] = collision.disabled
		result["shape_id"] = collision.shape.get_instance_id() if collision.shape != null else 0
		result["shape_class"] = collision.shape.get_class() if collision.shape != null else ""
		if collision.shape is CapsuleShape3D:
			var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D
			result["shape"] = {"radius": capsule.radius, "height": capsule.height}
		elif collision.shape is BoxShape3D:
			result["shape"] = {"size": (collision.shape as BoxShape3D).size}
	if node is MeshInstance3D:
		result["mesh_id"] = node.mesh.get_instance_id() if node.mesh != null else 0
		result["bounds"] = node.mesh.get_aabb() if node.mesh != null else AABB()
		result["material_id"] = node.material_override.get_instance_id() if node.material_override != null else 0
		result["material_signals_blocked"] = node.material_override.is_blocking_signals() if node.material_override != null else false
		if node.material_override is StandardMaterial3D:
			var material: StandardMaterial3D = node.material_override as StandardMaterial3D
			result["material"] = {"color": material.albedo_color, "transparency": material.transparency, "depth": material.depth_draw_mode, "shading": material.shading_mode, "cull": material.cull_mode, "filter": material.texture_filter}
	for child: Node in node.get_children(): result.children.append(_node_stamp(child))
	return result

